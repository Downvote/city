--!strict
-- Pieces that show a picture the player picks from the Roblox library (the user: "allow the
-- player to use custom decal in the roblox library"): posters, frames, a photo frame for a
-- table, a standing sign, a billboard, and decals for a wall or a floor. In Build mode the player
-- pastes a decal's or an image's id when placing one or after picking it (Plan: Pictures).
--
-- Each has `picture = true` and one part the picture shows on, carrying attrs.Picture (the face,
-- a NormalId name: "Back" is a box's +Z, the front of a piece; "Top" its top). Until a picture is
-- chosen it shows a little drawn one, every part of it named "Placeholder" (Catalog.prims leaves
-- those out once there is a picture). c1 is the frame or the board, c2 the paper or the blank.

local Recipe = require(script.Parent.Parent.Recipe)
local Colors = require(script.Parent.Parent.Parent.Util.Colors)

local C = Recipe.Colors

type R = Recipe.Recipe
type Prim = Recipe.Prim

local function shade(c: Color3, k: number): Color3
	return Colors.shade(c, k)
end

-- The part the picture shows on: a box between two corners, facing `face`.
local function canvas(r: R, x1: number, y1: number, z1: number, x2: number, y2: number, z2: number, face: string): Prim
	local p = r:block(x1, y1, z1, x2, y2, z2, r.c2, "SmoothPlastic")
	p.attrs = { Picture = face }
	return p
end

local function placeholder(list: { Prim })
	for _, p in list do
		p.name = "Placeholder"
	end
end

-- A little drawn picture on an upright canvas (x1..x2, y1..y2) whose face is at depth z: a sun
-- over two hills. It stands 0.03 proud of the canvas and goes when a real picture is chosen.
local function sketch(r: R, x1: number, y1: number, x2: number, y2: number, z: number)
	local w, h = x2 - x1, y2 - y1
	local made: { Prim } = {}
	local function tri(a: Vector2, b: Vector2, c: Vector2, depth: number, color: Color3)
		for _, p in
			r:tri(
				Vector3.new(x1 + a.X * w, y1 + a.Y * h, depth),
				Vector3.new(x1 + b.X * w, y1 + b.Y * h, depth),
				Vector3.new(x1 + c.X * w, y1 + c.Y * h, depth),
				0.03,
				color,
				"SmoothPlastic"
			)
		do
			table.insert(made, p)
		end
	end
	tri(Vector2.new(0.3, 0.08), Vector2.new(0.92, 0.08), Vector2.new(0.66, 0.6), z + 0.045, C.DarkLeaf)
	tri(Vector2.new(0.08, 0.08), Vector2.new(0.62, 0.08), Vector2.new(0.3, 0.46), z + 0.075, C.Leaf)
	local d = math.min(w, h) * 0.2
	table.insert(made, r:cyl(x1 + w * 0.74, y1 + h * 0.76, z + 0.045, 0.03, d, "z", C.Yellow, "SmoothPlastic"))
	placeholder(made)
end

-- The same lying flat, for a decal on the floor: the canvas's top is at y.
local function sketchFlat(r: R, s: number, y: number)
	local made: { Prim } = {}
	local function tri(a: Vector2, b: Vector2, c: Vector2, lift: number, color: Color3)
		for _, p in
			r:tri(
				Vector3.new(-s / 2 + a.X * s, y + lift, s / 2 - a.Y * s),
				Vector3.new(-s / 2 + b.X * s, y + lift, s / 2 - b.Y * s),
				Vector3.new(-s / 2 + c.X * s, y + lift, s / 2 - c.Y * s),
				0.03,
				color,
				"SmoothPlastic"
			)
		do
			table.insert(made, p)
		end
	end
	-- (each layer 0.03 over the last, so no two tops lie close enough to flicker)
	tri(Vector2.new(0.3, 0.1), Vector2.new(0.9, 0.1), Vector2.new(0.66, 0.6), 0.015, C.DarkLeaf)
	tri(Vector2.new(0.1, 0.1), Vector2.new(0.62, 0.1), Vector2.new(0.3, 0.46), 0.045, C.Leaf)
	table.insert(made, r:cyl(s * 0.24, y + 0.015, -s * 0.26, 0.03, s * 0.2, "y", C.Yellow, "SmoothPlastic"))
	placeholder(made)
end

-- A picture frame w x h with bars t wide, standing d out from the wall, as one piece, with a thin
-- darker lip along the inside of its top and bottom bars.
local function frame(r: R, w: number, h: number, t: number, d: number, y0: number, z0: number, mat: string)
	local color = r.c1
	r:piece(function(q: R)
		q:block(-w / 2, y0 + h - t, z0, w / 2, y0 + h, z0 + d, color, mat)
		q:block(-w / 2, y0, z0, w / 2, y0 + t, z0 + d, color, mat)
		q:block(-w / 2, y0 + t, z0, -w / 2 + t, y0 + h - t, z0 + d, color, mat)
		q:block(w / 2 - t, y0 + t, z0, w / 2, y0 + h - t, z0 + d, color, mat)
		local lip = shade(color, 0.78)
		q:block(-w / 2 + t, y0 + t, z0 + d - 0.08, w / 2 - t, y0 + t + 0.04, z0 + d - 0.04, lip, mat)
		q:block(-w / 2 + t, y0 + h - t - 0.04, z0 + d - 0.08, w / 2 - t, y0 + h - t, z0 + d - 0.04, lip, mat)
	end)
end

-- A framed picture on a wall: the frame, a card mount and the canvas set in it.
local function framed(r: R, w: number, h: number, t: number, mat: string)
	frame(r, w, h, t, 0.3, 0, 0.03, mat)
	local mount = Color3.fromRGB(246, 242, 232)
	r:block(-w / 2 + t - 0.02, t - 0.02, 0.05, w / 2 - t + 0.02, h - t + 0.02, 0.1, mount, "SmoothPlastic")
	local m = math.min(w, h) * 0.08
	canvas(r, -w / 2 + t + m, t + m, 0.1, w / 2 - t - m, h - t - m, 0.14, "Back")
	sketch(r, -w / 2 + t + m, t + m, w / 2 - t - m, h - t - m, 0.14)
end

-- A poster: a sheet of paper (c1) with the picture on it, held up by tape at its corners.
local function poster(r: R, w: number, h: number)
	r:block(-w / 2, 0, 0.03, w / 2, h, 0.06, r.c1, "SmoothPlastic")
	local m = 0.15
	canvas(r, -w / 2 + m, m, 0.06, w / 2 - m, h - m, 0.09, "Back")
	sketch(r, -w / 2 + m, m, w / 2 - m, h - m, 0.09)
	local tape = Color3.fromRGB(236, 226, 190)
	for _, sx in { -1, 1 } do
		for _, y in { h - 0.12, 0.12 } do
			r:boxAt(
				CFrame.new(sx * (w / 2 - 0.12), y, 0.105) * CFrame.Angles(0, 0, sx * math.rad(if y > 1 then 45 else -45)),
				0.5,
				0.16,
				0.03,
				tape,
				"SmoothPlastic"
			)
		end
	end
end

-- A decal flat on a wall: the picture alone, on a thin sheet (c2 shows until there is one).
local function wallDecal(r: R, s: number)
	canvas(r, -s / 2, 0, 0.03, s / 2, s, 0.06, "Back")
	sketch(r, -s / 2, 0, s / 2, s, 0.06)
end

-- A decal flat on the floor, lying like a mark (Catalog: "mark"): its top 0.04 over the floor.
local function floorDecal(r: R, s: number)
	canvas(r, -s / 2, 0.01, -s / 2, s / 2, 0.04, s / 2, "Top")
	sketchFlat(r, s, 0.04)
end

local items = {
	{
		id = "pic_poster",
		name = "Poster",
		cat = "pictures",
		price = 30,
		place = "wall",
		size = Vector3.new(3, 4, 0.15),
		c1 = "F7F3EA",
		c2 = "9CCBE8",
		tags = { "art" },
		picture = true,
		style = "playful",
		build = function(r: R)
			poster(r, 3, 4)
		end,
	},
	{
		id = "pic_poster_wide",
		name = "Wide poster",
		cat = "pictures",
		price = 50,
		place = "wall",
		size = Vector3.new(6, 3.5, 0.15),
		c1 = "F7F3EA",
		c2 = "9CCBE8",
		tags = { "art" },
		picture = true,
		build = function(r: R)
			poster(r, 6, 3.5)
		end,
	},
	{
		id = "pic_frame",
		name = "Picture frame",
		cat = "pictures",
		price = 50,
		place = "wall",
		size = Vector3.new(3, 3, 0.35),
		c1 = "8E6440",
		c2 = "9CCBE8",
		tags = { "art" },
		picture = true,
		style = "cozy",
		build = function(r: R)
			framed(r, 3, 3, 0.25, "Wood")
		end,
	},
	{
		id = "pic_frame_tall",
		name = "Tall picture frame",
		cat = "pictures",
		price = 60,
		place = "wall",
		size = Vector3.new(2.6, 4, 0.35),
		c1 = "3A3A40",
		c2 = "9CCBE8",
		tags = { "art" },
		picture = true,
		style = "modern",
		build = function(r: R)
			framed(r, 2.6, 4, 0.16, "Metal")
		end,
	},
	{
		id = "pic_frame_gilt",
		name = "Gilt frame",
		cat = "pictures",
		price = 90,
		place = "wall",
		size = Vector3.new(6, 4, 0.35),
		c1 = "D4AE5E",
		c2 = "9CCBE8",
		tags = { "art" },
		picture = true,
		style = "fancy",
		build = function(r: R)
			framed(r, 6, 4, 0.4, "Metal")
			-- a little carved crest on the top bar
			r:cyl(0, 3.8, 0.36, 0.06, 0.5, "z", shade(r.c1, 1.1), "Metal")
		end,
	},
	{
		id = "pic_photo",
		name = "Photo frame",
		cat = "pictures",
		price = 20,
		place = "surface",
		size = Vector3.new(1.4, 1.6, 0.7),
		c1 = "C9A27A",
		c2 = "9CCBE8",
		tags = { "art" },
		picture = true,
		style = "cozy",
		build = function(r: R)
			-- a small frame standing on its foot, held up by a strut at the back
			local w, h, t = 1.3, 1.5, 0.14
			r:piece(function(q: R)
				q:block(-w / 2, h - t, -0.06, w / 2, h, 0.06, r.c1, "Wood")
				q:block(-w / 2, 0.04, -0.06, w / 2, 0.04 + t, 0.06, r.c1, "Wood")
				q:block(-w / 2, 0.04 + t, -0.06, -w / 2 + t, h - t, 0.06, r.c1, "Wood")
				q:block(w / 2 - t, 0.04 + t, -0.06, w / 2, h - t, 0.06, r.c1, "Wood")
			end)
			r:block(-w / 2 - 0.02, 0, -0.1, w / 2 + 0.02, 0.04, 0.1, shade(r.c1, 0.85), "Wood")
			r:block(-w / 2 + t, 0.04 + t, -0.04, w / 2 - t, h - t, 0.02, r.c2, "SmoothPlastic")
			canvas(r, -w / 2 + t + 0.02, 0.06 + t, 0.02, w / 2 - t - 0.02, h - t - 0.02, 0.05, "Back")
			sketch(r, -w / 2 + t + 0.02, 0.06 + t, w / 2 - t - 0.02, h - t - 0.02, 0.05)
			r:beam(Vector3.new(0, h * 0.7, -0.07), Vector3.new(0, 0.03, -0.32), 0.24, 0.06, shade(r.c1, 0.9), "Wood")
		end,
	},
	{
		id = "pic_sign",
		name = "Standing sign",
		cat = "pictures",
		price = 60,
		place = "floor",
		size = Vector3.new(3, 5, 1.4),
		c1 = "5E5048",
		c2 = "F7F3EA",
		picture = true,
		style = "rustic",
		build = function(r: R)
			-- a board on two legs with feet, the picture on its front
			for _, sx in { -1, 1 } do
				r:block(sx * 1.35 - 0.1, 0.2, -0.1, sx * 1.35 + 0.1, 4.9, 0.1, r.c1, "Wood")
				r:block(sx * 1.35 - 0.14, 0, -0.7, sx * 1.35 + 0.14, 0.2, 0.7, shade(r.c1, 0.85), "Wood")
			end
			r:piece(function(q: R)
				q:block(-1.5, 1.8, -0.12, 1.5, 2.0, 0.12, r.c1, "Wood")
				q:block(-1.5, 4.6, -0.12, 1.5, 4.8, 0.12, r.c1, "Wood")
				q:block(-1.25, 2.0, -0.06, 1.25, 4.6, 0.06, r.c2, "Wood")
			end)
			canvas(r, -1.1, 2.1, 0.06, 1.1, 4.5, 0.1, "Back")
			sketch(r, -1.1, 2.1, 1.1, 4.5, 0.1)
		end,
	},
	{
		id = "pic_billboard",
		name = "Billboard",
		cat = "pictures",
		price = 160,
		place = "ground",
		size = Vector3.new(8, 8, 1.6),
		c1 = "4A5260",
		c2 = "F7F3EA",
		picture = true,
		style = "modern",
		build = function(r: R)
			-- a big board on two steel posts, with a walkway rail along its foot and two lamps
			-- leaning over the top to light it at night
			local metal = r.c1
			for _, sx in { -2.6, 2.6 } do
				r:cyl(sx, 1.6, -0.3, 3.2, 0.5, "y", metal, "Metal")
				r:block(sx - 0.4, 0, -0.7, sx + 0.4, 0.2, 0.1, shade(metal, 0.8), "Concrete")
			end
			r:piece(function(q: R)
				q:block(-4, 3.2, -0.5, 4, 3.4, -0.1, metal, "Metal")
				q:block(-4, 7.6, -0.5, 4, 7.8, -0.1, metal, "Metal")
				q:block(-4, 3.4, -0.5, -3.8, 7.6, -0.1, metal, "Metal")
				q:block(3.8, 3.4, -0.5, 4, 7.6, -0.1, metal, "Metal")
			end)
			r:block(-3.8, 3.4, -0.4, 3.8, 7.6, -0.2, r.c2, "SmoothPlastic")
			canvas(r, -3.7, 3.5, -0.2, 3.7, 7.5, -0.16, "Back")
			sketch(r, -3.7, 3.5, 3.7, 7.5, -0.16)
			-- the walkway along the foot of the board
			r:block(-3.8, 3.0, -0.5, 3.8, 3.2, 0.5, shade(metal, 0.9), "DiamondPlate")
			for _, sx in { -1.6, 1.6 } do
				r:beam(Vector3.new(sx, 7.8, -0.3), Vector3.new(sx, 8.0, 0.4), 0.12, 0.12, metal, "Metal")
				local lamp = r:block(sx - 0.3, 7.82, 0.4, sx + 0.3, 7.98, 0.7, C.Warm, "Neon")
				r:glow(lamp, 16, 1)
			end
		end,
	},
	{
		id = "pic_decal_wall",
		name = "Wall decal",
		cat = "pictures",
		price = 20,
		place = "wall",
		size = Vector3.new(4, 4, 0.1),
		c1 = "F7F3EA",
		c2 = "E6E1D6",
		picture = true,
		build = function(r: R)
			wallDecal(r, 4)
		end,
	},
	{
		id = "pic_decal_wall_small",
		name = "Small wall decal",
		cat = "pictures",
		price = 10,
		place = "wall",
		size = Vector3.new(2, 2, 0.1),
		c1 = "F7F3EA",
		c2 = "E6E1D6",
		picture = true,
		build = function(r: R)
			wallDecal(r, 2)
		end,
	},
	{
		id = "pic_decal_floor",
		name = "Floor decal",
		cat = "pictures",
		price = 20,
		place = "mark",
		size = Vector3.new(4, 0.08, 4),
		c1 = "F7F3EA",
		c2 = "E6E1D6",
		picture = true,
		build = function(r: R)
			floorDecal(r, 4)
		end,
	},
	{
		id = "pic_decal_floor_big",
		name = "Big floor decal",
		cat = "pictures",
		price = 50,
		place = "mark",
		size = Vector3.new(8, 0.08, 8),
		c1 = "F7F3EA",
		c2 = "E6E1D6",
		picture = true,
		build = function(r: R)
			floorDecal(r, 8)
		end,
	},
}

return items
