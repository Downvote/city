--!strict
-- Things that hang on a wall. The origin is on the wall's surface, +z points out into the room
-- and y = 0 is the item's bottom edge, so every drawing runs from z = 0 outward.
-- c1 is the frame or main body, c2 the picture, face or second colour.

local Recipe = require(script.Parent.Parent.Recipe)
local Colors = require(script.Parent.Parent.Parent.Util.Colors)

local C = Recipe.Colors

type R = Recipe.Recipe

local MAT = Color3.fromRGB(246, 242, 232) -- the card mount round a picture

local function shade(c: Color3, k: number): Color3
	return Colors.shade(c, k)
end

-- A round rod from a to b (a cylinder laid along the line).
local function rod(r: R, a: Vector3, b: Vector3, d: number, color: Color3, mat: string?)
	local v = b - a
	local len = v.Magnitude
	if len < 1e-3 then
		return
	end
	local x = v / len
	local up = if math.abs(x.Y) > 0.99 then Vector3.zAxis else Vector3.yAxis
	local z = x:Cross(up).Unit
	local y = z:Cross(x).Unit
	r:add({
		shape = "Cylinder",
		cf = CFrame.fromMatrix((a + b) / 2, x, y, z),
		size = Vector3.new(len, d, d),
		color = color,
		mat = mat or r.mat or "Metal",
	})
end

-- A picture frame w x h with bars t wide, standing d out from the wall, with a thin darker lip
-- along the inside of its top and bottom bars, as one piece.
local function frame(r: R, w: number, h: number, t: number, d: number, color: Color3, mat: string)
	r:piece(function(q: R)
		q:block(-w / 2, h - t, 0, w / 2, h, d, color, mat)
		q:block(-w / 2, 0, 0, w / 2, t, d, color, mat)
		q:block(-w / 2, t, 0, -w / 2 + t, h - t, d, color, mat)
		q:block(w / 2 - t, t, 0, w / 2, h - t, d, color, mat)
		local lip = shade(color, 0.78)
		q:block(-w / 2 + t, t, d - 0.08, w / 2 - t, t + 0.04, d - 0.04, lip, mat)
		q:block(-w / 2 + t, h - t - 0.04, d - 0.08, w / 2 - t, h - t, d - 0.04, lip, mat)
	end)
end

-- A flat triangle on a picture, at depth z.
local function flatTri(r: R, a: Vector2, b: Vector2, c: Vector2, z: number, color: Color3)
	r:tri(Vector3.new(a.X, a.Y, z), Vector3.new(b.X, b.Y, z), Vector3.new(c.X, c.Y, z), 0.03, color, "Fabric")
end

-- One catalog entry (Build/Catalog explains the fields).
type Item = {
	id: string,
	name: string,
	cat: string,
	price: number,
	place: string,
	size: Vector3,
	c1: string,
	c2: string?,
	tags: { string }?,
	surface: number?,
	style: string?, -- the look it belongs to (Catalog.Styles)
	build: (r: R) -> (),
}

local items: { Item } = {
	{
		id = "art_landscape",
		name = "Landscape painting",
		cat = "walldecor",
		style = "cozy",
		price = 60,
		place = "wall",
		size = Vector3.new(4, 3, 0.3),
		c1 = "8E6440",
		c2 = "9CCBE8",
		tags = { "art" },
		build = function(r: R)
			-- a deep frame (c1) round a card mount, and in it a sky (c2) with a sun and clouds, two
			-- hills, a field and a little house; each layer stands a little in front of the last
			frame(r, 4, 3, 0.22, 0.32, r.c1, "Wood")
			r:block(-1.78, 0.22, 0.02, 1.78, 2.78, 0.08, MAT, "Cardboard")
			r:block(-1.55, 0.45, 0.08, 1.55, 2.55, 0.11, r.c2, "Fabric")
			r:block(-1.55, 1.9, 0.11, 1.55, 2.55, 0.14, shade(r.c2, 1.1), "Fabric")
			r:cyl(0.95, 2.1, 0.155, 0.03, 0.5, "z", C.Yellow, "Fabric")
			r:cyl(-0.85, 2.2, 0.155, 0.03, 0.36, "z", C.White, "Fabric")
			r:cyl(-0.58, 2.24, 0.185, 0.03, 0.46, "z", C.White, "Fabric")
			r:cyl(-0.35, 2.18, 0.155, 0.03, 0.3, "z", C.White, "Fabric")
			flatTri(r, Vector2.new(-0.4, 0.8), Vector2.new(1.55, 0.8), Vector2.new(1.55, 1.65), 0.155, C.DarkLeaf)
			flatTri(r, Vector2.new(-1.55, 0.8), Vector2.new(0.8, 0.8), Vector2.new(-0.6, 1.7), 0.185, C.Leaf)
			r:block(-1.55, 0.45, 0.205, 1.55, 0.85, 0.23, Color3.fromRGB(150, 190, 90), "Fabric")
			r:block(-1.55, 0.6, 0.23, 1.55, 0.66, 0.26, Color3.fromRGB(205, 180, 100), "Fabric")
			r:block(-0.85, 0.85, 0.2, -0.45, 1.13, 0.26, C.White, "Fabric")
			flatTri(r, Vector2.new(-0.92, 1.13), Vector2.new(-0.38, 1.13), Vector2.new(-0.65, 1.33), 0.245, C.Red)
		end,
	},
	{
		id = "art_flowers",
		name = "Flower painting",
		cat = "walldecor",
		style = "cozy",
		price = 50,
		place = "wall",
		size = Vector3.new(2.4, 3, 0.3),
		c1 = "D4AE5E",
		c2 = "3E5A4A",
		tags = { "art" },
		build = function(r: R)
			-- a gilt frame (c1) round a dark canvas (c2): a table edge, a jug and a bunch of
			-- flowers on long stems
			frame(r, 2.4, 3, 0.2, 0.32, r.c1, "Metal")
			r:block(-1.0, 0.2, 0.02, 1.0, 2.8, 0.1, r.c2, "Fabric")
			r:block(-1.0, 0.2, 0.1, 1.0, 0.55, 0.13, shade(r.c2, 0.65), "Fabric")
			r:block(-0.3, 0.55, 0.1, 0.3, 1.2, 0.13, Color3.fromRGB(110, 160, 200), "Fabric")
			r:block(-0.2, 1.2, 0.1, 0.2, 1.35, 0.13, Color3.fromRGB(110, 160, 200), "Fabric")
			r:block(-0.3, 0.8, 0.13, 0.3, 0.88, 0.16, C.White, "Fabric")
			local flowers = {
				{ x = -0.45, y = 2.0, z = 0.19, col = C.Pink },
				{ x = 0.4, y = 2.15, z = 0.19, col = C.Yellow },
				{ x = 0.0, y = 2.45, z = 0.22, col = Color3.fromRGB(220, 126, 108) },
				{ x = -0.15, y = 1.75, z = 0.25, col = C.White },
				{ x = 0.3, y = 1.7, z = 0.22, col = Color3.fromRGB(196, 160, 230) },
			}
			for _, f in flowers do
				r:beam(Vector3.new(0, 1.35, 0.14), Vector3.new(f.x, f.y, 0.14), 0.04, 0.04, C.Leaf, "Fabric")
				r:cyl(f.x, f.y, f.z - 0.015, 0.03, 0.4, "z", f.col, "Fabric")
				r:cyl(f.x, f.y, f.z + 0.015, 0.03, 0.14, "z", if f.col == C.Yellow then C.White else C.Yellow, "Fabric")
			end
		end,
	},
	{
		id = "art_abstract",
		name = "Abstract print",
		cat = "walldecor",
		style = "modern",
		price = 40,
		place = "wall",
		size = Vector3.new(3, 3, 0.25),
		c1 = "2B282E",
		c2 = "F7F3EA",
		tags = { "art" },
		build = function(r: R)
			-- a slim frame (c1) round a mount and a print (c2) of a few overlapping shapes
			frame(r, 3, 3, 0.1, 0.24, r.c1, "Wood")
			r:block(-1.4, 0.1, 0.02, 1.4, 2.9, 0.06, MAT, "Cardboard")
			r:block(-1.1, 0.4, 0.06, 1.1, 2.6, 0.09, r.c2, "Fabric")
			r:cyl(-0.3, 1.85, 0.105, 0.03, 1.1, "z", Color3.fromRGB(224, 180, 102), "Fabric")
			r:block(0.05, 0.6, 0.12, 0.9, 1.7, 0.15, Color3.fromRGB(208, 138, 108), "Fabric")
			r:block(-0.9, 0.6, 0.09, -0.2, 1.0, 0.12, Color3.fromRGB(90, 130, 160), "Fabric")
			r:block(-0.9, 1.2, 0.15, 0.9, 1.26, 0.18, C.Black, "Fabric")
			r:cyl(0.55, 2.2, 0.105, 0.03, 0.3, "z", Color3.fromRGB(143, 179, 154), "Fabric")
		end,
	},
	{
		id = "clock_wall",
		name = "Wall clock",
		cat = "walldecor",
		style = "cozy",
		price = 35,
		place = "wall",
		size = Vector3.new(1.8, 1.8, 0.4),
		c1 = "B8505A",
		c2 = "F7F3EA",
		tags = { "clock" },
		build = function(r: R)
			-- a round case (c1) with a darker bezel, a face (c2) with the four quarter numbers
			-- and ticks for the other hours, two hands, a thin second hand and a pin
			r:cyl(0, 0.9, 0.12, 0.24, 1.8, "z", r.c1, "Wood")
			r:cyl(0, 0.9, 0.27, 0.06, 1.66, "z", shade(r.c1, 0.8), "Wood")
			r:cyl(0, 0.9, 0.3, 0.06, 1.5, "z", r.c2, "Metal")
			local ink = Color3.fromRGB(52, 48, 54)
			-- the numbers, drawn as strokes: a, b, c, d, e, f, g run round from the top and the
			-- middle bar comes last, as on a clock radio
			local segs = {
				["1"] = { "b", "c" },
				["2"] = { "a", "b", "g", "e", "d" },
				["3"] = { "a", "b", "g", "c", "d" },
				["6"] = { "a", "f", "g", "e", "d", "c" },
				["9"] = { "a", "b", "c", "d", "f", "g" },
			}
			local function digit(q: R, ch: string, cx: number, cy: number)
				local w, h, s = 0.09, 0.16, 0.026
				local where = {
					a = { cx, cy + h / 2, w, s },
					d = { cx, cy - h / 2, w, s },
					g = { cx, cy, w, s },
					b = { cx + w / 2, cy + h / 4, s, h / 2 },
					c = { cx + w / 2, cy - h / 4, s, h / 2 },
					e = { cx - w / 2, cy - h / 4, s, h / 2 },
					f = { cx - w / 2, cy + h / 4, s, h / 2 },
				}
				for _, k in segs[ch] do
					local p = where[k]
					q:box(p[1], p[2], 0.345, p[3], p[4], 0.03, ink, "Metal")
				end
			end
			r:piece(function(q: R)
				digit(q, "1", -0.07, 1.42)
				digit(q, "2", 0.07, 1.42)
				digit(q, "3", 0.52, 0.9)
				digit(q, "6", 0, 0.38)
				digit(q, "9", -0.52, 0.9)
			end)
			r:piece(function(q: R)
				q:box(0, 0.9, 0.345, 0.12, 0.12, 0.03, ink, "Metal")
				for i = 0, 11 do
					if i % 3 ~= 0 then
						local a = i * math.pi / 6
						q:boxAt(
							CFrame.new(math.cos(a) * 0.62, 0.9 + math.sin(a) * 0.62, 0.345) * CFrame.Angles(0, 0, a),
							0.12,
							0.035,
							0.03,
							ink,
							"Metal"
						)
					end
				end
			end, nil, "Metal")
			r:boxAt(CFrame.new(0.12, 1.05, 0.375) * CFrame.Angles(0, 0, -0.65), 0.06, 0.42, 0.03, ink, "Metal")
			r:boxAt(CFrame.new(-0.05, 1.2, 0.405) * CFrame.Angles(0, 0, 0.15), 0.045, 0.6, 0.03, ink, "Metal")
			r:boxAt(CFrame.new(0.15, 0.62, 0.435) * CFrame.Angles(0, 0, 0.5), 0.02, 0.62, 0.03, r.c1, "Wood")
			r:cyl(0, 0.9, 0.465, 0.03, 0.1, "z", r.c1, "Wood")
		end,
	},
	{
		id = "mirror_wall",
		name = "Wall mirror",
		cat = "walldecor",
		style = "fancy",
		price = 50,
		place = "wall",
		size = Vector3.new(2.6, 3.4, 0.4),
		c1 = "C99A62",
		c2 = "F7F3EA",
		tags = { "mirror" },
		build = function(r: R)
			-- an arched mirror in a slim frame, over a little ledge
			local mirror = Color3.fromRGB(205, 225, 234)
			local cy = 2.25
			r:block(-0.95, 0.3, 0.02, 0.95, cy, 0.08, mirror, "Glass")
			r:cyl(0, cy, 0.05, 0.06, 1.9, "z", mirror, "Glass")
			r:boxAt(CFrame.new(0.25, 1.7, 0.1) * CFrame.Angles(0, 0, -0.5), 0.16, 1.5, 0.04, C.White, "Glass")
			for _, sx in { -1, 1 } do
				r:block(sx * 1.05 - 0.1, 0.2, 0, sx * 1.05 + 0.1, cy, 0.18, r.c1, "Wood")
			end
			r:block(-1.15, 0.2, 0, 1.15, 0.36, 0.18, r.c1, "Wood")
			local n = 7
			for i = 0, n - 1 do
				local a1 = i / n * math.pi
				local a2 = (i + 1) / n * math.pi
				local p1 = Vector3.new(math.cos(a1) * 1.05, cy + math.sin(a1) * 1.05, 0.09)
				local p2 = Vector3.new(math.cos(a2) * 1.05, cy + math.sin(a2) * 1.05, 0.09)
				local d = (p2 - p1).Unit * 0.07
				r:beam(p1 - d, p2 + d, 0.18, 0.18, r.c1, "Wood")
			end
			r:block(-1.3, 0, 0, 1.3, 0.14, 0.38, r.c2, "Wood")
			r:block(-1.2, 0.14, 0, 1.2, 0.2, 0.06, shade(r.c2, 0.85), "Wood")
		end,
	},
	{
		id = "shelf_wall",
		name = "Wall shelf",
		cat = "walldecor",
		style = "cozy",
		price = 40,
		place = "wall",
		size = Vector3.new(3.6, 1.6, 1),
		c1 = "C99A62",
		c2 = "45454A",
		tags = { "books" },
		build = function(r: R)
			-- a board (c1) on two iron brackets (c2), with a row of books: thin spines of different
			-- heights in muted colours, one leaning on the row and two lying flat, then a framed
			-- photo and a little plant in a pot
			r:block(-1.8, 0.4, 0, 1.8, 0.55, 0.95, r.c1, "Wood")
			r:block(-1.8, 0.34, 0.9, 1.8, 0.4, 0.95, shade(r.c1, 0.8), "Wood")
			for _, x in { -1.2, 1.2 } do
				r:block(x - 0.05, 0.0, 0, x + 0.05, 0.4, 0.08, r.c2, "Metal")
				r:tri(
					Vector3.new(x, 0.4, 0.06),
					Vector3.new(x, 0.4, 0.75),
					Vector3.new(x, 0.02, 0.06),
					0.08,
					r.c2,
					"Metal"
				)
			end
			r:piece(function(q: R)
				local books = {
					{ w = 0.14, h = 0.72, c = Color3.fromRGB(70, 96, 142) },
					{ w = 0.18, h = 0.86, c = Color3.fromRGB(168, 86, 90) },
					{ w = 0.12, h = 0.64, c = Color3.fromRGB(214, 170, 82) },
					{ w = 0.16, h = 0.8, c = Color3.fromRGB(78, 127, 98) },
					{ w = 0.13, h = 0.74, c = Color3.fromRGB(196, 154, 108) },
					{ w = 0.17, h = 0.9, c = Color3.fromRGB(110, 140, 168) },
					{ w = 0.12, h = 0.68, c = Color3.fromRGB(138, 111, 144) },
				}
				local x = -1.7
				for i, b in books do
					local front = 0.84 + (i % 3) * 0.02
					q:block(x, 0.55, front - 0.62, x + b.w, 0.55 + b.h, front, b.c, "Cardboard")
					if i == 2 or i == 6 then
						q:block(
							x + 0.02,
							0.55 + b.h - 0.2,
							front,
							x + b.w - 0.02,
							0.55 + b.h - 0.13,
							front + 0.03,
							C.Paper,
							"Cardboard"
						)
					end
					x += b.w + 0.012
				end
				q:boxAt(
					CFrame.new(x + 0.2, 0.86, 0.5) * CFrame.Angles(0, 0, -0.38),
					0.15,
					0.72,
					0.6,
					Color3.fromRGB(150, 98, 120),
					"Cardboard"
				)
				-- two lying flat, and the photo in its frame
				q:block(0.6, 0.55, 0.22, 1.1, 0.66, 0.84, Color3.fromRGB(63, 140, 134), "Cardboard")
				q:block(0.64, 0.66, 0.26, 1.06, 0.75, 0.8, Color3.fromRGB(224, 133, 102), "Cardboard")
				local photo = CFrame.new(0.05, 0.94, 0.35) * CFrame.Angles(-0.15, 0, 0)
				q:boxAt(photo, 0.56, 0.7, 0.06, C.Black, "Cardboard")
				q:boxAt(photo * CFrame.new(0, 0, 0.05), 0.42, 0.56, 0.02, C.Paper, "Cardboard")
				q:boxAt(photo * CFrame.new(0, -0.1, 0.08), 0.42, 0.3, 0.02, Color3.fromRGB(150, 190, 120), "Cardboard")
			end, nil, "Cardboard")
			r:cyl(1.45, 0.77, 0.5, 0.44, 0.44, "y", Color3.fromRGB(236, 232, 222), "Marble")
			r:piece(function(q: R)
				q:box(1.45, 1.0, 0.5, 0.3, 0.06, 0.3, C.Soil, "Grass")
				q:lump(CFrame.new(1.45, 1.2, 0.5) * CFrame.Angles(0, 0.4, 0), 0.5, 0.36, 0.46, C.Leaf, "Grass")
				q:lump(CFrame.new(1.3, 1.12, 0.66) * CFrame.Angles(0, 1.1, 0), 0.32, 0.26, 0.3, C.DarkLeaf, "Grass")
				q:lump(CFrame.new(1.62, 0.9, 0.62) * CFrame.Angles(0.4, 0, -0.4), 0.16, 0.36, 0.14, C.Leaf, "Grass")
				q:lump(CFrame.new(1.28, 0.86, 0.4) * CFrame.Angles(-0.3, 0, 0.4), 0.16, 0.32, 0.14, C.DarkLeaf, "Grass")
			end)
		end,
	},
	{
		id = "sconce",
		name = "Wall lamp",
		cat = "walldecor",
		style = "fancy",
		price = 45,
		place = "wall",
		size = Vector3.new(1, 2, 1.2),
		c1 = "F2E1C4",
		c2 = "B08E58",
		tags = { "light" },
		build = function(r: R)
			r:cyl(0, 0.75, 0.03, 0.06, 0.55, "z", r.c2, "Metal")
			r:cyl(0, 0.75, 0.08, 0.06, 0.32, "z", shade(r.c2, 0.85), "Metal")
			rod(r, Vector3.new(0, 0.75, 0.1), Vector3.new(0, 0.95, 0.5), 0.09, r.c2, "Metal")
			rod(r, Vector3.new(0, 0.93, 0.5), Vector3.new(0, 0.93, 0.6), 0.09, r.c2, "Metal")
			r:cyl(0, 1.02, 0.6, 0.16, 0.26, "y", r.c2, "Metal")
			r:ball(0, 1.22, 0.6, 0.32, C.Warm, "Glass")
			local lampshade = r:cyl(0, 1.45, 0.6, 0.7, 0.86, "y", r.c1, "Fabric")
			r:glow(lampshade, 12, 1)
			r:cyl(0, 1.1, 0.6, 0.08, 0.94, "y", r.c2, "Metal")
			r:cyl(0, 1.8, 0.6, 0.08, 0.94, "y", r.c2, "Metal")
		end,
	},
	{
		id = "tv_wall",
		name = "Wall TV",
		cat = "walldecor",
		style = "modern",
		price = 280,
		place = "wall",
		size = Vector3.new(5.4, 3.2, 0.4),
		c1 = "2B282E",
		c2 = "283446",
		tags = { "tv" },
		build = function(r: R)
			-- the bracket on the wall, its arm, and the set: a slim back, a bezel round the screen
			-- with a softened edge, and a cable running down out of sight
			r:block(-0.8, 1.0, 0, 0.8, 2.2, 0.08, C.DarkMetal, "Metal")
			for _, x in { -0.55, 0.55 } do
				r:cyl(x, 1.15, 0.04, 0.06, 0.08, "z", shade(C.DarkMetal, 1.3), "Metal")
				r:cyl(x, 2.05, 0.04, 0.06, 0.08, "z", shade(C.DarkMetal, 1.3), "Metal")
			end
			r:block(-0.3, 1.3, 0.08, 0.3, 1.9, 0.18, C.DarkMetal, "Metal")
			r:block(-2.6, 0.1, 0.18, 2.6, 3.1, 0.24, shade(r.c1, 0.8), "Metal")
			r:bevel(-2.7, 0, 0.24, 2.7, 3.2, 0.32, 0.03, r.c1, "Metal", { wear = 1.25 })
			r:block(-2.62, 0.08, 0.32, 2.62, 3.12, 0.36, r.c2, "Glass")
			r:boxAt(CFrame.new(0.8, 1.7, 0.375) * CFrame.Angles(0, 0, -0.7), 0.25, 2.4, 0.03, shade(r.c2, 1.5), "Glass")
			r:boxAt(CFrame.new(1.2, 1.9, 0.375) * CFrame.Angles(0, 0, -0.7), 0.1, 1.8, 0.03, shade(r.c2, 1.35), "Glass")
			r:block(-0.3, 0, 0.32, 0.3, 0.06, 0.36, shade(r.c1, 1.4), "Metal")
			r:block(2.3, 0.02, 0.32, 2.4, 0.06, 0.35, Color3.fromRGB(120, 200, 140), "Neon")
		end,
	},
	{
		id = "coat_hooks",
		name = "Coat hooks",
		cat = "walldecor",
		style = "rustic",
		price = 30,
		place = "wall",
		size = Vector3.new(3, 1.6, 0.6),
		c1 = "F7F3EA",
		c2 = "45454A",
		tags = { "storage" },
		build = function(r: R)
			r:block(-1.5, 0.9, 0, 1.5, 1.4, 0.12, r.c1, "Wood")
			r:block(-1.5, 1.4, 0, 1.5, 1.46, 0.16, shade(r.c1, 0.9), "Wood")
			for _, x in { -1.05, -0.35, 0.35, 1.05 } do
				r:cyl(x, 1.12, 0.14, 0.06, 0.16, "z", r.c2, "Metal")
				rod(r, Vector3.new(x, 1.12, 0.14), Vector3.new(x, 1.0, 0.36), 0.07, r.c2, "Metal")
				r:ball(x, 1.04, 0.4, 0.12, r.c2, "Metal")
			end
			-- a scarf on one hook, a tote bag on another and a cap on a third
			r:block(-1.2, 0.05, 0.3, -0.9, 1.1, 0.5, C.Red, "Fabric")
			r:block(-1.23, 0.02, 0.27, -0.87, 0.2, 0.53, C.White, "Fabric")
			r:block(-0.6, 0.25, 0.2, -0.1, 0.85, 0.36, Color3.fromRGB(214, 196, 160), "Fabric")
			rod(
				r,
				Vector3.new(-0.5, 0.85, 0.28),
				Vector3.new(-0.35, 1.05, 0.38),
				0.04,
				Color3.fromRGB(150, 110, 70),
				"Fabric"
			)
			rod(
				r,
				Vector3.new(-0.2, 0.85, 0.28),
				Vector3.new(-0.35, 1.05, 0.38),
				0.04,
				Color3.fromRGB(150, 110, 70),
				"Fabric"
			)
			r:ball(0.35, 0.95, 0.42, 0.46, C.Blue, "Fabric")
			r:block(0.17, 0.78, 0.42, 0.53, 0.84, 0.6, C.Blue, "Fabric")
		end,
	},
	{
		id = "awning",
		name = "Striped awning",
		cat = "walldecor",
		style = "seaside",
		price = 90,
		place = "wall",
		size = Vector3.new(6, 2, 2.6),
		c1 = "B8505A",
		c2 = "F7F3EA",
		build = function(r: R)
			r:block(-3, 1.82, 0, 3, 2.0, 0.14, shade(r.c1, 0.7), "Wood")
			for i = 0, 5 do
				local x = -2.5 + i
				local col = if i % 2 == 0 then r.c1 else r.c2
				r:beam(Vector3.new(x, 1.9, 0.1), Vector3.new(x, 0.95, 2.45), 1.0, 0.08, col, "Fabric")
				-- a scalloped flap along the front
				r:block(x - 0.5, 0.55, 2.39, x + 0.5, 0.97, 2.47, col, "Fabric")
				r:cyl(x, 0.55, 2.43, 0.08, 1.0, "z", col, "Fabric")
			end
			r:cyl(0, 0.96, 2.43, 6.1, 0.14, "x", shade(r.c1, 0.7), "Metal")
			for _, x in { -2.9, 2.9 } do
				rod(r, Vector3.new(x, 0.5, 0.02), Vector3.new(x, 0.95, 2.35), 0.07, C.DarkMetal, "Metal")
				r:block(x - 0.08, 0.4, 0, x + 0.08, 0.62, 0.06, C.DarkMetal, "Metal")
			end
		end,
	},
	{
		id = "curtains",
		name = "Curtains",
		cat = "walldecor",
		style = "cozy",
		price = 70,
		place = "wall",
		size = Vector3.new(5.6, 6, 0.8),
		c1 = "8FB39A",
		c2 = "B08E58",
		build = function(r: R)
			r:cyl(0, 5.75, 0.55, 5.3, 0.12, "x", r.c2, "Metal")
			for _, sx in { -1, 1 } do
				r:ball(sx * 2.7, 5.75, 0.55, 0.26, r.c2, "Metal")
				r:block(sx * 2.4 - 0.05, 5.65, 0, sx * 2.4 + 0.05, 5.85, 0.55, r.c2, "Metal")
				r:cyl(sx * 2.4, 5.75, 0.03, 0.06, 0.24, "z", r.c2, "Metal")
				-- a panel hanging in soft folds from rings, tied back halfway down
				for i = 0, 3 do
					local x1 = sx * (2.6 - i * 0.36)
					local x2 = sx * (2.6 - (i + 1) * 0.36)
					local deep = i % 2 == 0
					r:block(
						math.min(x1, x2),
						0.2,
						if deep then 0.15 else 0.25,
						math.max(x1, x2),
						5.6,
						if deep then 0.45 else 0.55,
						if deep then r.c1 else shade(r.c1, 1.1),
						"Fabric"
					)
				end
				for i = 0, 2 do
					r:cyl(sx * (2.42 - i * 0.6), 5.68, 0.55, 0.04, 0.2, "x", r.c2, "Metal")
				end
				r:block(
					math.min(sx * 2.65, sx * 1.1),
					2.4,
					0.12,
					math.max(sx * 2.65, sx * 1.1),
					2.6,
					0.6,
					r.c2,
					"Fabric"
				)
				r:block(
					math.min(sx * 2.69, sx * 1.12),
					0.14,
					0.12,
					math.max(sx * 2.69, sx * 1.12),
					0.3,
					0.63,
					shade(r.c1, 0.85),
					"Fabric"
				)
			end
		end,
	},
	{
		id = "bunting",
		name = "Bunting",
		cat = "walldecor",
		style = "playful",
		price = 25,
		place = "wall",
		size = Vector3.new(8, 1.4, 0.3),
		c1 = "F7F3EA",
		c2 = "F7F3EA",
		build = function(r: R)
			-- a cord (c1) with eight little flags in the colours flags come in
			r:block(-3.95, 1.22, 0.06, 3.95, 1.3, 0.14, r.c1, "Fabric")
			local flags = { C.Red, C.Yellow, C.Blue, Color3.fromRGB(120, 191, 94), C.Pink, C.Yellow, C.Red, C.Blue }
			r:piece(function(q: R)
				q:block(-4, 1.16, 0.03, -3.9, 1.36, 0.17, C.DarkMetal, "Fabric")
				for i, col in flags do
					local x = -3.5 + (i - 1)
					q:tri(
						Vector3.new(x - 0.4, 1.22, 0.1),
						Vector3.new(x + 0.4, 1.22, 0.1),
						Vector3.new(x, 0.3 + (i % 2) * 0.08, 0.1),
						0.06,
						col,
						"Fabric"
					)
				end
				q:block(3.9, 1.16, 0.03, 4, 1.36, 0.17, C.DarkMetal, "Fabric")
			end)
		end,
	},
	{
		id = "tool_board",
		name = "Tool board",
		cat = "walldecor",
		style = "rustic",
		price = 45,
		place = "wall",
		size = Vector3.new(4, 3, 0.5),
		c1 = "8E6440",
		c2 = "D6BE96",
		build = function(r: R)
			-- a framed board with tools hung on it and a rack of jars under: c1 the frame and
			-- the rack, c2 the board
			r:block(-2, 0.5, 0, 2, 3, 0.1, r.c1, "Wood")
			r:block(-1.86, 0.64, 0.1, 1.86, 2.86, 0.14, r.c2, "Wood")
			r:block(-2, 0.32, 0, 2, 0.5, 0.46, r.c1, "Wood")
			r:piece(function(q: R)
				-- a square, a hammer, a saw, a spanner, pliers and a level, then jars on the rack
				q:block(-1.7, 1.0, 0.14, -1.6, 2.0, 0.2, C.Metal, "Metal")
				q:block(-1.7, 1.0, 0.14, -1.0, 1.1, 0.2, C.Metal, "Metal")
				q:block(-0.72, 1.0, 0.14, -0.6, 2.1, 0.22, C.Bark, "Metal")
				q:block(-0.95, 2.1, 0.14, -0.37, 2.38, 0.26, C.DarkMetal, "Metal")
				q:block(-0.1, 1.3, 0.14, 0.9, 1.9, 0.18, C.Metal, "Metal")
				q:block(0.9, 1.35, 0.14, 1.25, 1.85, 0.24, C.Red, "Metal")
				q:block(1.5, 0.95, 0.14, 1.62, 1.9, 0.2, C.Metal, "Metal")
				q:cyl(1.56, 2.05, 0.17, 0.08, 0.4, "z", C.Metal, "Metal")
				q:block(-0.3, 2.35, 0.14, 1.3, 2.6, 0.22, C.Yellow, "Metal")
				q:block(0.42, 2.42, 0.22, 0.58, 2.53, 0.26, Color3.fromRGB(150, 210, 230), "Metal")
				for i, col in { C.Blue, C.Red, C.Metal, C.Yellow } do
					q:cyl(-1.5 + (i - 1) * 0.55, 0.72, 0.26, 0.44, 0.3, "y", col, "Metal")
				end
			end)
		end,
	},
	{
		id = "sign_workshop",
		name = "Workshop sign",
		cat = "walldecor",
		price = 40,
		place = "wall",
		size = Vector3.new(0.6, 3.3, 3),
		c1 = "F2E8D5",
		c2 = "6E4C34",
		build = function(r: R)
			-- a board with a hammer on it, hung from an iron arm so it stands out square from
			-- the wall and reads from along the street: c1 the board, c2 its edges
			r:piece(function(q: R)
				q:block(-0.13, 2.3, 0, 0.13, 3.3, 0.08, C.DarkMetal, "Metal")
				q:block(-0.05, 3.0, 0.08, 0.05, 3.1, 2.8, C.DarkMetal, "Metal")
				q:beam(Vector3.new(0, 2.4, 0.08), Vector3.new(0, 3.0, 1.0), 0.08, 0.08, C.DarkMetal, "Metal")
				for _, z in { 0.78, 2.38 } do
					q:block(-0.03, 2.7, z - 0.03, 0.03, 3.0, z + 0.03, C.DarkMetal, "Metal")
				end
			end)
			r:block(-0.08, 0.9, 0.5, 0.08, 2.7, 2.66, r.c1, "Wood")
			r:block(-0.12, 2.58, 0.46, 0.12, 2.74, 2.7, r.c2, "Wood")
			r:block(-0.12, 0.86, 0.46, 0.12, 1.02, 2.7, r.c2, "Wood")
			local handle = Color3.fromRGB(196, 150, 96)
			r:piece(function(q: R)
				-- the same hammer on both faces: a nail, a handle and a head
				for _, sx in { -1, 1 } do
					q:box(sx * 0.11, 1.35, 2.2, 0.06, 0.3, 0.06, C.DarkMetal, "Metal")
					local lean = CFrame.new(sx * 0.1, 1.8, 1.5) * CFrame.Angles(math.rad(-35), 0, 0)
					q:boxAt(lean, 0.04, 1.3, 0.16, handle, "Metal")
					q:boxAt(lean * CFrame.new(sx * 0.02, 0.6, 0), 0.1, 0.3, 0.66, C.DarkMetal, "Metal")
				end
			end)
		end,
	},
}

return items
