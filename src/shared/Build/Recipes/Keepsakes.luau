--!strict
-- Keepsakes: things a villager made and gave you in an event (Data/Events: a portrait from the
-- painter, a pot from the potter, a quilt, a carved bird...). They cost nothing, and you can put
-- down as many of each as you were given (Sim/Keepsakes keeps the count; the Build service
-- checks it). Drawn at the level of everything else in the catalog: a thing made of the parts
-- the real one has. c1 is the main colour, c2 the second.

local Recipe = require(script.Parent.Parent.Recipe)
local Colors = require(script.Parent.Parent.Parent.Util.Colors)

local C = Recipe.Colors

type R = Recipe.Recipe

local function shade(c: Color3, k: number): Color3
	return Colors.shade(c, k)
end

local SKIN = Color3.fromRGB(236, 196, 160)
local INK = Color3.fromRGB(70, 52, 48)
local CORK = Color3.fromRGB(196, 160, 112)
local SAND = Color3.fromRGB(232, 214, 170)

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

-- A picture frame w x h with bars t wide, d deep from the wall, as one piece.
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

-- A flat disc facing out of a picture (+z), z1..z2 deep.
local function dot(r: R, x: number, y: number, z1: number, z2: number, d: number, color: Color3)
	r:cyl(x, y, (z1 + z2) / 2, z2 - z1, d, "z", color, "Fabric")
end

-- A flat triangle on a picture, at depth z.
local function flatTri(r: R, a: Vector2, b: Vector2, c: Vector2, z: number, color: Color3)
	r:tri(Vector3.new(a.X, a.Y, z), Vector3.new(b.X, b.Y, z), Vector3.new(c.X, c.Y, z), 0.03, color, "Fabric")
end

-- See-through, for glass that is round (a bottle, a jar, a globe).
local function clear(p: Recipe.Prim): Recipe.Prim
	p.transp = 0.6
	return p
end

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
	build: (r: R) -> (),
}

local items: { Item } = {
	{
		id = "keep_portrait",
		name = "Portrait",
		cat = "keepsakes",
		price = 0,
		place = "wall",
		size = Vector3.new(2.4, 3, 0.35),
		c1 = "C9A15A",
		c2 = "8FB7C9",
		tags = { "keepsake", "art" },
		build = function(r: R)
			-- a gilt frame (c1) round a painted portrait on a sky blue ground (c2): shoulders in
			-- a red jumper, a white collar, a round face with rosy cheeks, a fringe, a smile, the
			-- painter's brush dabs in the corners, and a brass plate on the bottom bar
			frame(r, 2.4, 3, 0.2, 0.3, r.c1, "Wood")
			r:block(-1.0, 0.2, 0.02, 1.0, 2.8, 0.08, r.c2, "Fabric")
			r:block(-1.0, 2.0, 0.08, 1.0, 2.8, 0.11, shade(r.c2, 1.12), "Fabric")
			local shirt = Color3.fromRGB(196, 92, 88)
			r:block(-0.62, 0.2, 0.11, 0.62, 0.9, 0.14, shirt, "Fabric")
			dot(r, -0.62, 0.7, 0.11, 0.14, 0.4, shirt)
			dot(r, 0.62, 0.7, 0.11, 0.14, 0.4, shirt)
			r:block(-0.82, 0.2, 0.11, -0.62, 0.7, 0.14, shirt, "Fabric")
			r:block(0.62, 0.2, 0.11, 0.82, 0.7, 0.14, shirt, "Fabric")
			r:block(-0.14, 0.88, 0.14, 0.14, 1.12, 0.17, shade(SKIN, 0.9), "Fabric")
			flatTri(r, Vector2.new(-0.3, 0.9), Vector2.new(0, 0.9), Vector2.new(-0.14, 0.7), 0.185, C.White)
			flatTri(r, Vector2.new(0, 0.9), Vector2.new(0.3, 0.9), Vector2.new(0.14, 0.7), 0.185, C.White)
			local hair = Color3.fromRGB(110, 72, 52)
			dot(r, 0, 1.66, 0.14, 0.17, 0.86, hair)
			dot(r, 0, 1.5, 0.17, 0.21, 0.76, SKIN)
			r:block(-0.32, 1.74, 0.21, 0.32, 1.84, 0.24, hair, "Fabric")
			r:block(-0.18, 1.5, 0.21, -0.1, 1.6, 0.24, INK, "Fabric")
			r:block(0.1, 1.5, 0.21, 0.18, 1.6, 0.24, INK, "Fabric")
			dot(r, -0.24, 1.38, 0.21, 0.23, 0.13, Color3.fromRGB(236, 150, 150))
			dot(r, 0.24, 1.38, 0.21, 0.23, 0.13, Color3.fromRGB(236, 150, 150))
			r:block(-0.1, 1.31, 0.21, 0.1, 1.35, 0.24, Color3.fromRGB(170, 80, 76), "Fabric")
			r:block(-0.13, 1.35, 0.21, -0.09, 1.38, 0.24, Color3.fromRGB(170, 80, 76), "Fabric")
			r:block(0.09, 1.35, 0.21, 0.13, 1.38, 0.24, Color3.fromRGB(170, 80, 76), "Fabric")
			-- dabs of paint and the painter's mark
			dot(r, -0.78, 2.55, 0.11, 0.14, 0.16, C.Yellow)
			dot(r, 0.72, 2.35, 0.11, 0.14, 0.2, C.White)
			dot(r, 0.55, 2.45, 0.11, 0.14, 0.14, C.White)
			r:block(0.6, 0.26, 0.14, 0.86, 0.3, 0.17, INK, "Fabric")
			r:block(-0.28, 0.05, 0.3, 0.28, 0.15, 0.33, C.Gold, "Metal")
		end,
	},
	{
		id = "keep_pot",
		name = "Clay pot",
		cat = "keepsakes",
		price = 0,
		place = "surface",
		size = Vector3.new(1.2, 1.9, 1.2),
		c1 = "C9774F",
		c2 = "5E8C99",
		tags = { "keepsake", "plant" },
		build = function(r: R)
			-- thrown on a wheel: a foot, a round belly in rings, a glazed band (c2) with drips,
			-- a neck and a rolled rim, and a sprig of dried lavender standing in it
			local mat = "Slate"
			r:cyl(0, 0.05, 0, 0.1, 0.62, "y", shade(r.c1, 0.8), mat)
			-- the belly's outline, bottom to top: a ring every 0.1 at the width the curve has there
			local y = 0.1
			while y < 1.3 do
				local t = (y + 0.05 - 0.1) / 1.2
				local d = 0.62 + 0.46 * math.sin(math.min(1, t * 1.25) * math.pi) ^ 0.8
				if t > 0.8 then
					d = math.min(d, 0.6 + (1 - t) * 0.9)
				end
				r:cyl(0, y + 0.05, 0, 0.1, d, "y", r.c1, mat)
				y += 0.1
			end
			r:cyl(0, 1.34, 0, 0.08, 0.74, "y", shade(r.c1, 1.08), mat)
			r:cyl(0, 1.4, 0, 0.04, 0.5, "y", shade(r.c1, 0.45), mat)
			r:cyl(0, 0.68, 0, 0.14, 1.16, "y", r.c2, "Glass")
			for i = 0, 5 do
				local a = i * math.pi / 3 + 0.3
				r:boxAt(
					CFrame.new(math.cos(a) * 0.56, 0.55, math.sin(a) * 0.56) * CFrame.Angles(0, -a, 0),
					0.05,
					0.14 + (i % 2) * 0.06,
					0.08,
					r.c2,
					"Glass"
				)
			end
			-- lavender: stems up out of the neck, little purple heads along their tops
			local stems =
				{ Vector3.new(-0.12, 1.85, 0.06), Vector3.new(0.05, 1.9, -0.08), Vector3.new(0.16, 1.78, 0.1) }
			for _, top in stems do
				local base = Vector3.new(top.X * 0.3, 1.2, top.Z * 0.3)
				rod(r, base, top, 0.035, C.DarkLeaf)
				for k = 0, 3 do
					local p = base:Lerp(top, 0.68 + k * 0.1)
					r:lump(CFrame.new(p), 0.07, 0.1, 0.07, Color3.fromRGB(150, 120, 196), "Sandstone")
				end
			end
		end,
	},
	{
		id = "keep_bird",
		name = "Carved bird",
		cat = "keepsakes",
		price = 0,
		place = "surface",
		size = Vector3.new(1.4, 1.2, 0.8),
		c1 = "C49A68",
		c2 = "6E4E36",
		tags = { "keepsake" },
		build = function(r: R)
			-- whittled from one bit of wood (c1): a plump body, wings, a cocked tail, a round
			-- head with a little beak, on two pegs in a bevelled base (c2) with a brass plate
			r:block(-0.6, 0, -0.3, 0.6, 0.16, 0.3, r.c2, "Wood")
			r:block(-0.54, 0.16, -0.24, 0.54, 0.2, 0.24, shade(r.c2, 1.15), "Wood")
			r:block(-0.22, 0.04, 0.3, 0.22, 0.12, 0.33, C.Gold, "Metal")
			for _, z in { -0.08, 0.08 } do
				r:cyl(-0.02, 0.28, z, 0.16, 0.05, "y", INK, "Wood")
			end
			r:lump(CFrame.new(-0.02, 0.56, 0) * CFrame.Angles(0, 0, math.rad(-10)), 0.86, 0.5, 0.48, r.c1, "Wood")
			for _, s in { -1, 1 } do
				r:lump(
					CFrame.new(-0.08, 0.6, s * 0.25) * CFrame.Angles(0, 0, math.rad(-16)),
					0.56,
					0.3,
					0.1,
					shade(r.c1, 0.82),
					"Wood"
				)
				r:ball(0.48, 0.9, s * 0.13, 0.06, INK, "Wood")
			end
			r:ball(0.38, 0.86, 0, 0.36, r.c1, "Wood")
			r:wedge(CFrame.new(0.61, 0.85, 0) * CFrame.Angles(0, -math.pi / 2, 0), 0.08, 0.08, 0.16, C.Yellow, "Wood")
			r:wedge(
				CFrame.new(-0.5, 0.68, 0) * CFrame.Angles(0, math.pi / 2, 0) * CFrame.Angles(math.rad(-22), 0, 0),
				0.28,
				0.08,
				0.34,
				shade(r.c1, 0.9),
				"Wood"
			)
		end,
	},
	{
		id = "keep_quilt",
		name = "Patchwork quilt",
		cat = "keepsakes",
		price = 0,
		place = "floor",
		size = Vector3.new(3.6, 3.4, 1.4),
		c1 = "D9826E",
		c2 = "F2DFA8",
		tags = { "keepsake" },
		build = function(r: R)
			-- a quilt over a wooden rack: two posts each side on feet, a top rail and a low
			-- one; the quilt folds over the top and hangs both ways, its front in patches of four
			-- colours (c1, c2, a blue and a green) with cream stitching between them, a heart in
			-- the middle and a binding along the hem
			local wood = Color3.fromRGB(150, 110, 76)
			for _, x in { -1.6, 1.6 } do
				r:block(x - 0.06, 0, -0.65, x + 0.06, 0.12, 0.65, shade(wood, 0.85), "Wood")
				for _, z in { -0.45, 0.45 } do
					r:block(x - 0.06, 0.12, z - 0.06, x + 0.06, 3.08, z + 0.06, wood, "Wood")
				end
				r:block(x - 0.06, 3.08, -0.51, x + 0.06, 3.18, 0.51, wood, "Wood")
			end
			r:cyl(0, 3.0, 0, 3.08, 0.12, "x", wood, "Wood")
			r:cyl(0, 0.6, -0.45, 3.08, 0.1, "x", wood, "Wood")
			local cream = Color3.fromRGB(246, 236, 214)
			r:cyl(0, 3.0, 0, 2.84, 0.44, "x", r.c2, "Fabric")
			r:block(-1.42, 1.0, 0.1, 1.42, 3.0, 0.16, cream, "Fabric")
			r:block(-1.42, 1.3, -0.16, 1.42, 3.0, -0.1, r.c2, "Fabric")
			local colours = { r.c1, r.c2, Color3.fromRGB(130, 170, 200), Color3.fromRGB(150, 190, 130) }
			local cols, rows = 4, 3
			local w, h = 2.84 / cols, 1.9 / rows
			for i = 0, cols - 1 do
				for j = 0, rows - 1 do
					local x1 = -1.42 + i * w + 0.03
					local y1 = 1.06 + j * h + 0.03
					local colour = colours[(i + j) % #colours + 1]
					r:block(x1, y1, 0.16, x1 + w - 0.06, y1 + h - 0.06, 0.19, colour, "Fabric")
				end
			end
			-- a heart sewn on the middle, and the binding along the hem
			local heart = Color3.fromRGB(200, 90, 100)
			dot(r, -0.1, 2.08, 0.19, 0.22, 0.24, heart)
			dot(r, 0.1, 2.08, 0.19, 0.22, 0.24, heart)
			flatTri(r, Vector2.new(-0.22, 2.04), Vector2.new(0.22, 2.04), Vector2.new(0, 1.8), 0.205, heart)
			r:block(-1.44, 0.96, 0.16, 1.44, 1.04, 0.2, shade(r.c1, 0.75), "Fabric")
			r:block(-1.44, 1.26, -0.2, 1.44, 1.34, -0.16, shade(r.c1, 0.75), "Fabric")
		end,
	},
	{
		id = "keep_boat",
		name = "Ship in a bottle",
		cat = "keepsakes",
		price = 0,
		place = "surface",
		size = Vector3.new(1.9, 1.0, 0.8),
		c1 = "8A5A3C",
		c2 = "EEE6D2",
		tags = { "keepsake" },
		build = function(r: R)
			-- a bottle lying on a cradle (c1) with a brass label, its cork in; inside, a sea of
			-- blue putty, a little hull with two masts, white sails (c2) and a red pennant
			r:block(-0.75, 0, -0.3, 0.75, 0.1, 0.3, r.c1, "Wood")
			for _, x in { -0.45, 0.35 } do
				r:block(x - 0.06, 0.1, -0.22, x + 0.06, 0.32, 0.22, shade(r.c1, 1.1), "Wood")
			end
			r:block(-0.2, 0.02, 0.3, 0.2, 0.08, 0.33, C.Gold, "Metal")
			clear(r:cyl(-0.1, 0.62, 0, 1.2, 0.62, "x", C.Glass, "Glass"))
			clear(r:cyl(0.57, 0.62, 0, 0.14, 0.44, "x", C.Glass, "Glass"))
			clear(r:cyl(0.73, 0.62, 0, 0.2, 0.22, "x", C.Glass, "Glass"))
			r:cyl(0.87, 0.62, 0, 0.12, 0.2, "x", CORK, "Wood")
			r:block(-0.6, 0.38, -0.12, 0.4, 0.44, 0.12, C.Water, "Glass")
			local hull = Color3.fromRGB(110, 70, 50)
			r:block(-0.42, 0.44, -0.07, 0.14, 0.52, 0.07, hull, "Wood")
			r:wedge(CFrame.new(0.21, 0.48, 0) * CFrame.Angles(0, -math.pi / 2, 0), 0.14, 0.08, 0.14, hull, "Wood")
			for _, x in { -0.26, 0.0 } do
				r:cyl(x, 0.68, 0, 0.32, 0.03, "y", hull, "Wood")
				r:block(x - 0.01, 0.58, -0.1, x + 0.01, 0.8, 0.1, r.c2, "Fabric")
			end
			r:block(-0.01, 0.82, 0.015, 0.11, 0.86, 0.035, C.Red, "Fabric")
		end,
	},
	{
		id = "keep_shells",
		name = "Jar of shells",
		cat = "keepsakes",
		price = 0,
		place = "surface",
		size = Vector3.new(0.8, 1.1, 0.8),
		c1 = "6FA3B8",
		c2 = "E8667A",
		tags = { "keepsake" },
		build = function(r: R)
			-- a glass jar with a bed of sand and the shells from a day on the beach, a lid (c1)
			-- with a ribbon round it (c2) tied in a bow, and a starfish on top
			clear(r:cyl(0, 0.4, 0, 0.8, 0.6, "y", C.Glass, "Glass"))
			r:cyl(0, 0.1, 0, 0.16, 0.52, "y", SAND, "Sand")
			local shells: { { any } } = {
				{ -0.14, 0.22, 0.1, Color3.fromRGB(246, 200, 190) },
				{ 0.14, 0.22, -0.08, C.White },
				{ 0.1, 0.23, 0.14, Color3.fromRGB(240, 180, 140) },
				{ -0.12, 0.23, -0.14, Color3.fromRGB(230, 220, 200) },
				{ 0.02, 0.3, 0.0, Color3.fromRGB(246, 200, 190) },
				{ -0.16, 0.32, 0.0, C.White },
				{ 0.16, 0.32, 0.04, Color3.fromRGB(220, 160, 150) },
				{ 0.0, 0.38, -0.14, Color3.fromRGB(240, 180, 140) },
			}
			for i, s in shells do
				local cf = CFrame.new(s[1], s[2], s[3]) * CFrame.Angles(0, i * 0.9, 0.3)
				r:lump(cf, 0.16, 0.08, 0.13, s[4], "Marble")
			end
			r:cone(-0.04, 0.44, 0.12, 0.14, 0.08, Color3.fromRGB(236, 208, 170), "Marble")
			r:cyl(0, 0.83, 0, 0.06, 0.66, "y", r.c2, "Fabric")
			r:cyl(0, 0.89, 0, 0.06, 0.64, "y", r.c1, "Metal")
			for _, s in { -1, 1 } do
				r:lump(
					CFrame.new(s * 0.08, 0.83, 0.34) * CFrame.Angles(0, 0, s * 0.5),
					0.14,
					0.08,
					0.04,
					shade(r.c2, 0.9),
					"Fabric"
				)
			end
			r:ball(0, 0.83, 0.34, 0.06, r.c2, "Fabric")
			local star = Color3.fromRGB(236, 140, 90)
			for i = 0, 4 do
				local a = i * math.pi * 2 / 5
				rod(r, Vector3.new(0, 0.935, 0), Vector3.new(math.cos(a) * 0.17, 0.935, math.sin(a) * 0.17), 0.05, star)
			end
		end,
	},
	{
		id = "keep_birdhouse",
		name = "Birdhouse",
		cat = "keepsakes",
		price = 0,
		place = "ground",
		size = Vector3.new(1.6, 5.4, 1.6),
		c1 = "D8C3A0",
		c2 = "8C5A4A",
		tags = { "keepsake" },
		build = function(r: R)
			-- a little house (c1) with a pitched roof (c2) on a post: a round door, a perch,
			-- flowers painted on its front, a ledge with a bird already moved in, and stones
			-- round the foot of the post
			local wood = Color3.fromRGB(150, 110, 76)
			r:block(-0.15, 0, -0.15, 0.15, 3.8, 0.15, wood, "Wood")
			for _, s in { -1, 1 } do
				r:beam(Vector3.new(s * 0.15, 3.3, 0), Vector3.new(s * 0.5, 3.78, 0), 0.08, 0.1, wood, "Wood")
			end
			r:block(-0.6, 3.8, -0.55, 0.6, 3.9, 0.6, shade(wood, 1.1), "Wood")
			r:block(-0.45, 3.9, -0.45, 0.45, 4.7, 0.45, r.c1, "Wood")
			r:tri(Vector3.new(-0.45, 4.7, 0), Vector3.new(0.45, 4.7, 0), Vector3.new(0, 5.05, 0), 0.9, r.c1, "Wood")
			local slope = math.atan2(0.35, 0.45)
			for _, s in { -1, 1 } do
				r:boxAt(CFrame.new(s * 0.25, 4.92, 0) * CFrame.Angles(0, 0, -s * slope), 0.72, 0.08, 1.1, r.c2, "Wood")
			end
			r:cyl(0, 5.1, 0, 1.14, 0.12, "z", shade(r.c2, 0.8), "Wood")
			r:cyl(0, 4.35, 0.465, 0.03, 0.28, "z", INK, "Wood")
			r:cyl(0, 4.08, 0.55, 0.2, 0.05, "z", wood, "Wood")
			-- painted flowers
			for _, f in { { -0.3, 4.05 }, { 0.3, 4.05 }, { -0.3, 4.55 }, { 0.3, 4.55 } } do
				dot(r, f[1], f[2], 0.45, 0.48, 0.12, C.Pink)
				dot(r, f[1], f[2], 0.48, 0.51, 0.05, C.Yellow)
			end
			-- the bird on the ledge
			local bird = Color3.fromRGB(150, 110, 90)
			r:lump(CFrame.new(0.36, 4.0, 0.38) * CFrame.Angles(0, -0.6, 0), 0.2, 0.13, 0.13, bird, "Wood")
			r:ball(0.42, 4.1, 0.43, 0.11, bird, "Wood")
			r:wedge(
				CFrame.new(0.46, 4.1, 0.5) * CFrame.Angles(0, -math.pi + 0.6, 0),
				0.03,
				0.03,
				0.06,
				C.Yellow,
				"Wood"
			)
			for i, a in { 0.3, 1.6, 2.7, 4.0, 5.2 } do
				r:lump(
					CFrame.new(math.cos(a) * 0.4, 0.08, math.sin(a) * 0.4) * CFrame.Angles(0, a, 0),
					0.26 + (i % 2) * 0.08,
					0.16,
					0.22,
					C.Stone,
					"Slate"
				)
			end
		end,
	},
	{
		id = "keep_chime",
		name = "Wind chime",
		cat = "keepsakes",
		price = 0,
		place = "ceiling",
		size = Vector3.new(1.2, 2.2, 1.2),
		c1 = "B98A5A",
		c2 = "A8B8C0",
		tags = { "keepsake", "music" },
		build = function(r: R)
			-- hung from a hook: a wooden disc (c1), six metal tubes (c2) of different lengths on
			-- threads round it, a clapper in the middle and a painted sail at the bottom
			local thread = Color3.fromRGB(230, 220, 200)
			r:cyl(0, -0.12, 0, 0.24, 0.04, "y", C.DarkMetal, "Metal")
			r:cyl(0, -0.3, 0, 0.08, 0.9, "y", r.c1, "Wood")
			r:cyl(0, -0.25, 0, 0.02, 0.6, "y", shade(r.c1, 0.85), "Wood")
			local lengths = { 0.6, 0.75, 0.9, 1.05, 0.85, 0.7 }
			for i, len in lengths do
				local a = (i - 1) * math.pi / 3
				local x, z = math.cos(a) * 0.32, math.sin(a) * 0.32
				r:cyl(x, -0.445, z, 0.21, 0.015, "y", thread, "Fabric")
				r:cyl(x, -0.55 - len / 2, z, len, 0.09, "y", r.c2, "Metal")
				r:cyl(x, -0.55 - len - 0.005, z, 0.01, 0.06, "y", shade(r.c2, 0.6), "Metal")
			end
			r:cyl(0, -0.6, 0, 0.52, 0.015, "y", thread, "Fabric")
			r:cyl(0, -0.88, 0, 0.04, 0.3, "y", r.c1, "Wood")
			r:cyl(0, -1.17, 0, 0.54, 0.015, "y", thread, "Fabric")
			r:block(-0.15, -1.86, -0.02, 0.15, -1.44, 0.02, r.c1, "Wood")
			dot(r, 0, -1.62, 0.02, 0.05, 0.16, r.c2)
			dot(r, 0, -1.62, -0.05, -0.02, 0.16, r.c2)
		end,
	},
	{
		id = "keep_mug",
		name = "Painted mug",
		cat = "keepsakes",
		price = 0,
		place = "surface",
		size = Vector3.new(0.9, 0.8, 0.7),
		c1 = "F2E8D5",
		c2 = "E8667A",
		tags = { "keepsake" },
		build = function(r: R)
			-- a mug (c1) painted by hand (c2): a band round the bottom with dots on it, a heart
			-- on the front, a round handle, and tea in it
			r:cyl(0, 0.015, 0, 0.03, 0.5, "y", shade(r.c1, 0.85), "Slate")
			r:cyl(0, 0.38, 0, 0.7, 0.56, "y", r.c1, "Slate")
			r:cyl(0, 0.735, 0, 0.03, 0.46, "y", Color3.fromRGB(150, 96, 60), "Glass")
			r:cyl(0, 0.14, 0, 0.08, 0.62, "y", r.c2, "Slate")
			for i = 0, 7 do
				local a = i * math.pi / 4
				r:ball(math.cos(a) * 0.31, 0.24, math.sin(a) * 0.31, 0.05, r.c2, "Slate")
			end
			dot(r, -0.06, 0.48, 0.27, 0.31, 0.13, r.c2)
			dot(r, 0.06, 0.48, 0.27, 0.31, 0.13, r.c2)
			flatTri(r, Vector2.new(-0.12, 0.465), Vector2.new(0.12, 0.465), Vector2.new(0, 0.33), 0.29, r.c2)
			local pts = {
				Vector3.new(0.26, 0.6, 0),
				Vector3.new(0.4, 0.57, 0),
				Vector3.new(0.43, 0.42, 0),
				Vector3.new(0.4, 0.26, 0),
				Vector3.new(0.26, 0.22, 0),
			}
			for k = 1, #pts - 1 do
				local d = (pts[k + 1] - pts[k]).Unit * 0.03
				r:beam(pts[k] - d, pts[k + 1] + d, 0.1, 0.07, r.c1, "Slate")
			end
		end,
	},
	{
		id = "keep_flowers",
		name = "Pressed flowers",
		cat = "keepsakes",
		price = 0,
		place = "wall",
		size = Vector3.new(2, 2.4, 0.3),
		c1 = "E8E2D6",
		c2 = "F6EFD9",
		tags = { "keepsake", "art" },
		build = function(r: R)
			-- a pale frame (c1) round a card (c2) with flowers pressed flat on it: a daisy, two
			-- poppies and a sprig of lavender on thin stems with leaves, and a little paper label
			frame(r, 2, 2.4, 0.16, 0.25, r.c1, "Wood")
			r:block(-0.84, 0.16, 0.02, 0.84, 2.24, 0.06, r.c2, "Cardboard")
			local stem = C.DarkLeaf
			local flowers = {
				{ base = Vector2.new(-0.2, 0.55), top = Vector2.new(-0.45, 1.75) },
				{ base = Vector2.new(0.0, 0.55), top = Vector2.new(0.1, 1.95) },
				{ base = Vector2.new(0.2, 0.55), top = Vector2.new(0.48, 1.6) },
			}
			for _, f in flowers do
				r:beam(
					Vector3.new(f.base.X, f.base.Y, 0.075),
					Vector3.new(f.top.X, f.top.Y, 0.075),
					0.035,
					0.03,
					stem,
					"Grass"
				)
				local mid = f.base:Lerp(f.top, 0.45)
				r:boxAt(
					CFrame.new(mid.X + 0.08, mid.Y, 0.075) * CFrame.Angles(0, 0, -0.7),
					0.22,
					0.08,
					0.03,
					C.Leaf,
					"Grass"
				)
				r:boxAt(
					CFrame.new(mid.X - 0.08, mid.Y + 0.1, 0.075) * CFrame.Angles(0, 0, 0.7),
					0.22,
					0.08,
					0.03,
					C.Leaf,
					"Grass"
				)
			end
			-- the daisy
			local d = flowers[1].top
			for i = 0, 7 do
				local a = i * math.pi / 4
				r:boxAt(
					CFrame.new(d.X + math.cos(a) * 0.12, d.Y + math.sin(a) * 0.12, 0.105) * CFrame.Angles(0, 0, a),
					0.18,
					0.07,
					0.03,
					C.White,
					"Fabric"
				)
			end
			dot(r, d.X, d.Y, 0.12, 0.15, 0.12, C.Yellow)
			-- the poppy, and a bud
			local p = flowers[3].top
			dot(r, p.X, p.Y, 0.09, 0.12, 0.34, Color3.fromRGB(214, 86, 80))
			dot(r, p.X, p.Y, 0.12, 0.15, 0.1, INK)
			dot(r, 0.62, 1.2, 0.09, 0.12, 0.16, Color3.fromRGB(214, 86, 80))
			-- the lavender
			local l = flowers[2].top
			for k = 0, 4 do
				dot(r, l.X - 0.02 * k, l.Y - 0.1 * k, 0.09, 0.12, 0.09, Color3.fromRGB(150, 120, 196))
			end
			r:block(-0.34, 0.26, 0.06, 0.34, 0.42, 0.09, C.Paper, "Cardboard")
			r:block(-0.26, 0.32, 0.09, 0.2, 0.35, 0.12, INK, "Cardboard")
		end,
	},
	{
		id = "keep_trophy",
		name = "Marrow trophy",
		cat = "keepsakes",
		price = 0,
		place = "surface",
		size = Vector3.new(1.0, 1.6, 0.8),
		c1 = "D6B060",
		c2 = "5B3A29",
		tags = { "keepsake" },
		build = function(r: R)
			-- second prize at the marrow show: a gold cup (c1) on a stem, two handles and a
			-- little striped marrow on its rim, on a wooden base (c2) with a plate and a rosette
			r:block(-0.4, 0, -0.3, 0.4, 0.22, 0.3, r.c2, "Wood")
			r:block(-0.3, 0.22, -0.22, 0.3, 0.36, 0.22, shade(r.c2, 1.18), "Wood")
			r:block(-0.2, 0.05, 0.3, 0.2, 0.17, 0.33, shade(r.c1, 1.1), "Metal")
			dot(r, -0.3, 0.11, 0.3, 0.33, 0.14, C.Blue)
			dot(r, -0.3, 0.11, 0.33, 0.36, 0.06, C.White)
			r:cyl(0, 0.38, 0, 0.04, 0.3, "y", r.c1, "Metal")
			r:cyl(0, 0.52, 0, 0.24, 0.1, "y", r.c1, "Metal")
			r:ball(0, 0.66, 0, 0.18, r.c1, "Metal")
			r:cyl(0, 0.8, 0, 0.12, 0.36, "y", r.c1, "Metal")
			r:cyl(0, 0.93, 0, 0.14, 0.52, "y", r.c1, "Metal")
			r:cyl(0, 1.07, 0, 0.14, 0.6, "y", r.c1, "Metal")
			r:cyl(0, 1.16, 0, 0.04, 0.66, "y", shade(r.c1, 1.12), "Metal")
			for _, s in { -1, 1 } do
				local pts = {
					Vector3.new(s * 0.28, 1.1, 0),
					Vector3.new(s * 0.44, 1.06, 0),
					Vector3.new(s * 0.44, 0.9, 0),
					Vector3.new(s * 0.24, 0.84, 0),
				}
				for k = 1, #pts - 1 do
					local d = (pts[k + 1] - pts[k]).Unit * 0.025
					r:beam(pts[k] - d, pts[k + 1] + d, 0.05, 0.05, r.c1, "Metal")
				end
			end
			local green = Color3.fromRGB(96, 140, 80)
			r:lump(CFrame.new(0.02, 1.3, 0) * CFrame.Angles(0, 0, math.rad(14)), 0.46, 0.22, 0.22, green, "Marble")
			for _, x in { -0.1, 0.02, 0.14 } do
				r:lump(
					CFrame.new(x, 1.3 + x * 0.24, 0) * CFrame.Angles(0, 0, math.rad(14)),
					0.04,
					0.23,
					0.23,
					shade(green, 1.3),
					"Marble"
				)
			end
			r:cyl(0.26, 1.37, 0, 0.08, 0.05, "x", C.Bark, "Wood")
		end,
	},
	{
		id = "keep_photo",
		name = "Photo of friends",
		cat = "keepsakes",
		price = 0,
		place = "surface",
		size = Vector3.new(1.2, 1.4, 0.7),
		c1 = "4F6D8A",
		c2 = "BFD9E6",
		tags = { "keepsake", "art" },
		build = function(r: R)
			-- a standing frame (c1) on a leg, round a photo (c2 sky): three friends side by side
			-- in front of the fountain on a sunny day, a heart sticker in the corner
			r:piece(function(q: R)
				q:block(-0.55, 0, -0.06, 0.55, 0.12, 0.06, r.c1, "Wood")
				q:block(-0.55, 1.28, -0.06, 0.55, 1.4, 0.06, r.c1, "Wood")
				q:block(-0.55, 0.12, -0.06, -0.43, 1.28, 0.06, r.c1, "Wood")
				q:block(0.43, 0.12, -0.06, 0.55, 1.28, 0.06, r.c1, "Wood")
			end)
			r:block(-0.43, 0.12, -0.04, 0.43, 1.28, 0.0, r.c2, "Cardboard")
			r:block(-0.43, 0.12, 0.0, 0.43, 0.42, 0.03, Color3.fromRGB(150, 190, 110), "Cardboard")
			dot(r, 0.28, 1.1, 0.0, 0.03, 0.16, C.Yellow)
			-- the fountain behind them
			r:block(-0.22, 0.42, 0.0, 0.22, 0.56, 0.03, C.Stone, "Cardboard")
			r:block(-0.04, 0.56, 0.0, 0.04, 0.75, 0.03, C.Stone, "Cardboard")
			dot(r, 0, 0.84, 0.0, 0.03, 0.18, C.Water)
			-- three friends in front
			local shirts =
				{ Color3.fromRGB(214, 100, 96), Color3.fromRGB(120, 160, 210), Color3.fromRGB(240, 200, 100) }
			for i, shirt in shirts do
				local x = -0.27 + (i - 1) * 0.27
				r:block(x - 0.08, 0.3, 0.03, x + 0.08, 0.6, 0.06, shirt, "Cardboard")
				dot(r, x, 0.7, 0.03, 0.06, 0.16, SKIN)
				r:block(x - 0.08, 0.74, 0.06, x + 0.08, 0.79, 0.09, if i == 2 then C.Bark else INK, "Cardboard")
			end
			dot(r, -0.36, 1.18, 0.0, 0.03, 0.1, C.Pink)
			r:beam(Vector3.new(0, 1.0, -0.06), Vector3.new(0, 0.02, -0.5), 0.1, 0.05, shade(r.c1, 0.8), "Wood")
		end,
	},
	{
		id = "keep_globe",
		name = "Snow globe",
		cat = "keepsakes",
		price = 0,
		place = "surface",
		size = Vector3.new(0.9, 1.1, 0.9),
		c1 = "6E4E36",
		c2 = "C93F4E",
		tags = { "keepsake" },
		build = function(r: R)
			-- a glass ball on a turned wooden base (c1) with a gold band; inside, a snowy
			-- ground, a little house with a red roof (c2) and a door, a pine and falling snow
			r:cyl(0, 0.12, 0, 0.24, 0.8, "y", r.c1, "Wood")
			r:cyl(0, 0.18, 0, 0.06, 0.84, "y", C.Gold, "Metal")
			r:cyl(0, 0.27, 0, 0.06, 0.6, "y", shade(r.c1, 1.15), "Wood")
			clear(r:ball(0, 0.64, 0, 0.8, C.Glass, "Glass"))
			r:cyl(0, 0.33, 0, 0.06, 0.5, "y", C.White, "Snow")
			r:block(-0.12, 0.36, -0.08, 0.08, 0.52, 0.08, C.Cream, "Plaster")
			r:tri(
				Vector3.new(-0.15, 0.52, 0),
				Vector3.new(0.11, 0.52, 0),
				Vector3.new(-0.02, 0.62, 0),
				0.2,
				r.c2,
				"Wood"
			)
			r:block(-0.05, 0.36, 0.08, 0.01, 0.46, 0.1, C.Bark, "Wood")
			r:cyl(0.15, 0.4, 0.06, 0.08, 0.04, "y", C.Bark, "Wood")
			r:cone(0.15, 0.53, 0.06, 0.22, 0.14, C.DarkLeaf, "Grass")
			for _, p in
				{
					Vector3.new(-0.18, 0.8, 0.1),
					Vector3.new(0.12, 0.88, -0.1),
					Vector3.new(0.2, 0.72, 0.16),
					Vector3.new(-0.08, 0.95, -0.04),
					Vector3.new(0.02, 0.76, 0.22),
					Vector3.new(-0.22, 0.66, -0.14),
				}
			do
				r:ball(p.X, p.Y, p.Z, 0.035, C.White, "Snow")
			end
			r:cyl(0, 0.12, -0.44, 0.08, 0.06, "z", C.Gold, "Metal")
		end,
	},
	{
		id = "keep_lantern",
		name = "Paper lantern",
		cat = "keepsakes",
		price = 0,
		place = "surface",
		size = Vector3.new(0.9, 1.5, 0.9),
		c1 = "F2C77A",
		c2 = "8A5A3C",
		tags = { "keepsake", "light" },
		build = function(r: R)
			-- folded paper (c1) round a candle, glowing at night: a round base and a cap (c2),
			-- thin ribs at its folds, painted petals round the middle and a wire handle
			r:cyl(0, 0.05, 0, 0.1, 0.62, "y", r.c2, "Wood")
			local rings = {
				{ 0.1, 0.3, 0.52 },
				{ 0.3, 0.55, 0.7 },
				{ 0.55, 0.85, 0.78 },
				{ 0.85, 1.1, 0.7 },
				{ 1.1, 1.25, 0.52 },
			}
			for i, ring in rings do
				local p = r:cyl(0, (ring[1] + ring[2]) / 2, 0, ring[2] - ring[1], ring[3], "y", r.c1, "Fabric")
				if i == 3 then
					r:glow(p, 10, 0.9)
				end
			end
			for _, y in { 0.3, 0.55, 0.85, 1.1 } do
				r:cyl(0, y, 0, 0.03, 0.8, "y", shade(r.c2, 1.1), "Wood")
			end
			for i = 0, 5 do
				local a = i * math.pi / 3
				r:lump(
					CFrame.new(math.cos(a) * 0.4, 0.7, math.sin(a) * 0.4) * CFrame.Angles(0, -a, 0),
					0.04,
					0.14,
					0.1,
					Color3.fromRGB(214, 96, 90),
					"Fabric"
				)
			end
			r:cyl(0, 1.28, 0, 0.06, 0.38, "y", r.c2, "Wood")
			local handle = {
				Vector3.new(-0.16, 1.31, 0),
				Vector3.new(-0.1, 1.44, 0),
				Vector3.new(0.1, 1.44, 0),
				Vector3.new(0.16, 1.31, 0),
			}
			for k = 1, #handle - 1 do
				rod(r, handle[k], handle[k + 1], 0.03, C.DarkMetal, "Metal")
			end
		end,
	},
	{
		id = "keep_cushion",
		name = "Knitted cushion",
		cat = "keepsakes",
		price = 0,
		place = "surface",
		size = Vector3.new(1.3, 0.6, 1.3),
		c1 = "8FB7C9",
		c2 = "F2E8D5",
		tags = { "keepsake" },
		build = function(r: R)
			-- a plump knitted cushion (c1): a square with soft rolled edges and round corners,
			-- three cables of knit down its top, a big button in the middle and a tassel at each
			-- corner (c2)
			local h, e = 0.44, 0.42
			r:block(-e, 0.06, -e, e, 0.06 + h, e, r.c1, "Fabric")
			for _, s in { -1, 1 } do
				r:cyl(s * e, 0.06 + h / 2, 0, e * 2, h, "z", r.c1, "Fabric")
				r:cyl(0, 0.06 + h / 2, s * e, e * 2, h, "x", r.c1, "Fabric")
				for _, t in { -1, 1 } do
					r:ball(s * e, 0.06 + h / 2, t * e, h, r.c1, "Fabric")
				end
			end
			for _, z in { -0.26, 0, 0.26 } do
				for k = -2, 2 do
					r:lump(
						CFrame.new(k * 0.15, 0.06 + h + 0.02, z) * CFrame.Angles(0, if k % 2 == 0 then 0.5 else -0.5, 0),
						0.17,
						0.08,
						0.11,
						shade(r.c1, 1.15),
						"Fabric"
					)
				end
			end
			r:cyl(0, 0.06 + h + 0.05, 0, 0.06, 0.2, "y", r.c2, "Fabric")
			for _, x in { -1, 1 } do
				for _, z in { -1, 1 } do
					local corner = Vector3.new(x * (e + 0.16), 0.3, z * (e + 0.16))
					rod(r, Vector3.new(x * (e + 0.12), 0.3, z * (e + 0.12)), corner, 0.03, r.c2, "Fabric")
					r:cone(corner.X + x * 0.04, 0.24, corner.Z + z * 0.04, 0.16, 0.12, r.c2, "Fabric")
				end
			end
		end,
	},
	{
		id = "keep_gull",
		name = "Driftwood gull",
		cat = "keepsakes",
		price = 0,
		place = "floor",
		size = Vector3.new(2, 3, 2),
		c1 = "C8B89C",
		c2 = "8E8A84",
		tags = { "keepsake", "art" },
		build = function(r: R)
			-- a gull made of driftwood (c1) from the beach, on a flat stone (c2) with pebbles:
			-- two stick legs, a body of bleached branches bound with rope, wings of long sticks,
			-- a round float for a head with a painted eye and an orange beak
			r:cyl(0, 0.1, 0, 0.2, 1.8, "y", r.c2, "Slate")
			for i, a in { 0.4, 1.9, 3.1, 4.4, 5.6 } do
				r:lump(
					CFrame.new(math.cos(a) * 0.62, 0.24, math.sin(a) * 0.62) * CFrame.Angles(0, a, 0),
					0.22 + (i % 2) * 0.08,
					0.12,
					0.18,
					shade(r.c2, 0.9 + (i % 3) * 0.08),
					"Slate"
				)
			end
			local leg = shade(r.c1, 0.8)
			rod(r, Vector3.new(-0.15, 0.2, 0.12), Vector3.new(0, 1.2, 0.05), 0.08, leg, "Wood")
			rod(r, Vector3.new(0.12, 0.2, -0.1), Vector3.new(0.05, 1.2, -0.04), 0.08, leg, "Wood")
			for k = 0, 3 do
				rod(
					r,
					Vector3.new(-0.7, 1.3 + k * 0.1, (k - 1.5) * 0.06),
					Vector3.new(0.45, 1.5 + k * 0.08, (k - 1.5) * 0.04),
					0.16,
					shade(r.c1, 0.92 + k * 0.05),
					"Wood"
				)
			end
			r:cyl(-0.1, 1.48, 0, 0.1, 0.42, "x", Color3.fromRGB(196, 170, 120), "Fabric")
			r:cyl(0.2, 1.54, 0, 0.1, 0.4, "x", Color3.fromRGB(196, 170, 120), "Fabric")
			for _, s in { -1, 1 } do
				for k = 0, 2 do
					rod(
						r,
						Vector3.new(-0.05 + k * 0.08, 1.6, s * 0.08),
						Vector3.new(-0.45 + k * 0.12, 2.25 + k * 0.12, s * (0.8 - k * 0.12)),
						0.08,
						shade(r.c1, 1 + k * 0.04),
						"Wood"
					)
				end
			end
			r:ball(0.62, 1.86, 0, 0.38, Color3.fromRGB(236, 232, 222), "Wood")
			for _, s in { -1, 1 } do
				r:ball(0.7, 1.92, s * 0.17, 0.07, INK, "Wood")
			end
			r:wedge(CFrame.new(0.92, 1.82, 0) * CFrame.Angles(0, -math.pi / 2, 0), 0.12, 0.1, 0.26, C.Yellow, "Wood")
		end,
	},
}

return items
