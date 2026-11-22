--!strict
-- Trees, plants and things for the yard. Most of these stand on the ground outdoors.
-- c1 is the main colour (leaves, stone, paint), c2 the second (bark, trim, fabric).

local Recipe = require(script.Parent.Parent.Recipe)
local Colors = require(script.Parent.Parent.Parent.Util.Colors)

local C = Recipe.Colors

type R = Recipe.Recipe

local function shade(c: Color3, k: number): Color3
	return Colors.shade(c, k)
end

-- A water surface: see-through enough to show what is under it, and you walk into it.
local function water(p: Recipe.Prim, transp: number?): Recipe.Prim
	p.transp = transp or 0.2
	p.collide = false
	return p
end

-- One tier of a pine: a four sided cone from y0 up to y1, `half` wide at its base.
local function pineTier(r: R, y0: number, y1: number, half: number, turn: number, color: Color3)
	local corners = {}
	for k = 0, 3 do
		local a = turn + math.pi / 4 + k * math.pi / 2
		table.insert(corners, Vector3.new(math.cos(a) * half * math.sqrt(2), y0, math.sin(a) * half * math.sqrt(2)))
	end
	local apex = Vector3.new(0, y1, 0)
	for k = 1, 4 do
		r:tri(corners[k], corners[k % 4 + 1], apex, 0.3, if k % 2 == 0 then color else shade(color, 0.9), "Grass")
	end
	r:boxAt(
		CFrame.new(0, y0 + 0.05, 0) * CFrame.Angles(0, -turn, 0),
		half * 2,
		0.1,
		half * 2,
		shade(color, 0.7),
		"Grass"
	)
end

-- A curved runner of straight pieces through the given points, joints closed up.
local function rail(r: R, pts: { Vector3 }, w: number, h: number, color: Color3, mat: string)
	for i = 1, #pts - 1 do
		local a, b = pts[i], pts[i + 1]
		local d = (b - a).Unit * 0.06
		r:beam(if i > 1 then a - d else a, if i < #pts - 1 then b + d else b, w, h, color, mat)
	end
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
	build: (r: R) -> (),
}

local items: { Item } = {
	{
		id = "tree_oak",
		name = "Oak tree",
		cat = "garden",
		price = 120,
		place = "ground",
		size = Vector3.new(8, 12, 8),
		c1 = "5DAA4A",
		c2 = "6E4C30",
		tags = { "plant" },
		build = function(r: R)
			r:cyl(0, 0.3, 0, 0.6, 1.8, "y", r.c2, "Wood")
			r:cyl(0, 3.2, 0, 6.0, 1.2, "y", r.c2, "Wood")
			r:beam(Vector3.new(0, 4.4, 0), Vector3.new(-1.8, 6.8, 0.6), 0.55, 0.55, r.c2, "Wood")
			r:beam(Vector3.new(0, 4.9, 0), Vector3.new(1.6, 7.2, -0.8), 0.55, 0.55, r.c2, "Wood")
			r:ball(0, 8.5, 0, 5.5, r.c1, "Grass")
			r:ball(-2.0, 7.4, 0.8, 3.8, shade(r.c1, 0.85), "Grass")
			r:ball(2.0, 7.6, -0.6, 4.0, shade(r.c1, 0.92), "Grass")
			r:ball(0.5, 7.2, 2.0, 3.5, shade(r.c1, 1.06), "Grass")
			r:ball(-0.8, 7.6, -2.0, 3.6, shade(r.c1, 0.8), "Grass")
			r:ball(0.8, 10.2, 0.4, 3.4, shade(r.c1, 1.1), "Grass")
		end,
	},
	{
		id = "tree_pine",
		name = "Pine tree",
		cat = "garden",
		price = 100,
		place = "ground",
		size = Vector3.new(5, 13, 5),
		c1 = "3E7F4E",
		c2 = "6E4C30",
		tags = { "plant" },
		build = function(r: R)
			r:cyl(0, 1.5, 0, 3.0, 0.8, "y", r.c2, "Wood")
			pineTier(r, 2.0, 7.0, 2.4, 0, r.c1)
			pineTier(r, 5.0, 9.8, 1.7, math.pi / 4, shade(r.c1, 1.08))
			pineTier(r, 8.0, 12.9, 1.4, 0, shade(r.c1, 1.16))
		end,
	},
	{
		id = "tree_blossom",
		name = "Blossom tree",
		cat = "garden",
		price = 160,
		place = "ground",
		size = Vector3.new(7, 10, 7),
		c1 = "F4B6C8",
		c2 = "6E4C30",
		tags = { "plant" },
		build = function(r: R)
			r:cyl(0, 0.25, 0, 0.5, 1.4, "y", r.c2, "Wood")
			rail(
				r,
				{ Vector3.new(0, 0, 0), Vector3.new(0.35, 2.6, 0.2), Vector3.new(-0.15, 5.0, 0) },
				0.75,
				0.75,
				r.c2,
				"Wood"
			)
			r:beam(Vector3.new(0, 4.4, 0), Vector3.new(-1.6, 5.8, 0.5), 0.4, 0.4, r.c2, "Wood")
			r:beam(Vector3.new(0.1, 4.0, 0), Vector3.new(1.5, 5.6, -0.4), 0.4, 0.4, r.c2, "Wood")
			r:ball(0, 7.0, 0, 4.5, r.c1, "Grass")
			r:ball(-1.8, 6.2, 0.6, 3.0, shade(r.c1, 0.9), "Grass")
			r:ball(1.7, 6.4, -0.5, 3.2, shade(r.c1, 0.95), "Grass")
			r:ball(0.4, 6.0, 1.7, 2.8, shade(r.c1, 1.04), "Grass")
			r:ball(-0.6, 6.5, -1.7, 2.8, shade(r.c1, 0.86), "Grass")
			r:ball(0.3, 8.6, 0.2, 2.6, shade(r.c1, 1.06), "Grass")
			-- petals fallen on the grass
			for _, p in { { 1.6, 1.2 }, { -1.4, 1.8 }, { 2.2, -1.0 }, { -2.0, -1.2 } } do
				r:noCollide(r:cyl(p[1], 0.02, p[2], 0.04, 0.5, "y", r.c1, "SmoothPlastic"))
			end
		end,
	},
	{
		id = "bush",
		name = "Bush",
		cat = "garden",
		price = 30,
		place = "ground",
		size = Vector3.new(3, 2.4, 3),
		c1 = "4E9A44",
		c2 = "F7F3EA",
		tags = { "plant" },
		build = function(r: R)
			r:ball(0, 1.1, 0, 2.2, r.c1, "Grass")
			r:ball(-0.75, 0.75, 0.3, 1.5, shade(r.c1, 0.85), "Grass")
			r:ball(0.75, 0.8, -0.2, 1.6, shade(r.c1, 0.92), "Grass")
			r:ball(0.2, 0.7, 0.8, 1.3, shade(r.c1, 1.08), "Grass")
			r:ball(-0.1, 1.55, -0.4, 1.4, shade(r.c1, 1.04), "Grass")
			-- a few small flowers
			for _, p in { { 0.5, 1.9, 0.45 }, { -0.6, 1.5, 0.8 }, { 0.9, 1.2, 0.85 }, { -0.95, 1.6, -0.4 } } do
				r:ball(p[1], p[2], p[3], 0.26, r.c2, "SmoothPlastic")
			end
		end,
	},
	{
		id = "flower_bed",
		name = "Flower bed",
		cat = "garden",
		price = 50,
		place = "ground",
		size = Vector3.new(4, 1.3, 2),
		c1 = "F59EB5",
		c2 = "8A5A2E",
		tags = { "plant" },
		build = function(r: R)
			for _, s in { -1, 1 } do
				r:block(-2, 0, s * 1 - 0.15, 2, 0.5, s * 1 + 0.15, r.c2, "Wood")
				r:block(s * 2 - 0.15, 0, -0.85, s * 2 + 0.15, 0.5, 0.85, r.c2, "Wood")
			end
			r:block(-1.85, 0, -0.85, 1.85, 0.42, 0.85, C.Soil, "Sand")
			local heads = { r.c1, C.Yellow, C.White, r.c1, C.Red, C.Yellow, r.c1, C.White }
			for i, col in heads do
				local x = -1.5 + ((i - 1) % 4) * 1.0 + (if i > 4 then 0.4 else 0)
				local z = if i > 4 then 0.4 else -0.35
				r:cyl(x, 0.65, z, 0.5, 0.08, "y", C.DarkLeaf, "SmoothPlastic")
				r:ball(x, 0.95, z, 0.36, col, "SmoothPlastic")
			end
			for _, x in { -1.0, 0.0, 1.0 } do
				r:ball(x, 0.5, 0.05, 0.5, C.Leaf, "Grass")
			end
		end,
	},
	{
		id = "rock",
		name = "Rock",
		cat = "garden",
		price = 20,
		place = "ground",
		size = Vector3.new(3, 1.6, 2.6),
		c1 = "9A9AA0",
		c2 = "6FA055",
		build = function(r: R)
			local main = CFrame.new(-0.2, 0.55, -0.1) * CFrame.Angles(0.15, 0.4, 0.12)
			r:boxAt(main, 1.9, 1.2, 1.5, r.c1, "Slate")
			r:boxAt(main * CFrame.new(-0.25, 0.62, -0.15), 0.9, 0.08, 0.7, r.c2, "Grass")
			r:boxAt(
				CFrame.new(0.9, 0.3, 0.6) * CFrame.Angles(-0.2, 1.0, 0.15),
				1.0,
				0.7,
				0.8,
				shade(r.c1, 0.9),
				"Slate"
			)
			r:boxAt(
				CFrame.new(-0.9, 0.15, 0.85) * CFrame.Angles(0.1, 0.3, -0.2),
				0.5,
				0.35,
				0.45,
				shade(r.c1, 1.08),
				"Slate"
			)
		end,
	},
	{
		id = "pond",
		name = "Pond",
		cat = "garden",
		price = 300,
		place = "ground",
		size = Vector3.new(7, 1.2, 7),
		c1 = "5AAADC",
		c2 = "A0A0A6",
		build = function(r: R)
			-- a dark bed with the water over it
			r:cyl(0, 0.04, 0, 0.08, 5.6, "y", Color3.fromRGB(46, 84, 90), "Slate")
			water(r:cyl(0, 0.2, 0, 0.12, 5.8, "y", r.c1, "Glass"))
			-- stones round the edge
			for i = 0, 11 do
				local t = i / 12 * math.pi * 2
				local x, z = math.cos(t) * 3.0, math.sin(t) * 3.0
				local col = if i % 3 == 0 then shade(r.c2, 0.85) elseif i % 3 == 1 then r.c2 else shade(r.c2, 1.1)
				r:boxAt(CFrame.new(x, 0.2, z) * CFrame.Angles(0, -t + (i % 2) * 0.3, 0), 0.8, 0.5, 1.2, col, "Slate")
			end
			-- lily pads, a flower and some reeds
			for _, p in { { -1.2, 0.8 }, { 0.9, -1.0 } } do
				r:noCollide(r:cyl(p[1], 0.28, p[2], 0.04, 0.8, "y", C.Leaf, "SmoothPlastic"))
			end
			r:ball(-1.1, 0.36, 0.75, 0.26, C.Pink, "SmoothPlastic")
			for _, p in { { 1.7, -1.5, 1.5 }, { 2.0, -1.0, 1.2 } } do
				r:noCollide(r:cyl(p[1], p[3] / 2, p[2], p[3], 0.08, "y", C.DarkLeaf, "SmoothPlastic"))
				r:noCollide(r:cyl(p[1], p[3] - 0.15, p[2], 0.35, 0.16, "y", C.Bark, "SmoothPlastic"))
			end
		end,
	},
	{
		id = "fountain",
		name = "Stone fountain",
		cat = "garden",
		price = 450,
		place = "ground",
		size = Vector3.new(6, 5.3, 6),
		c1 = "B8B4AC",
		c2 = "5AAADC",
		build = function(r: R)
			r:cyl(0, 0.5, 0, 1.0, 6, "y", r.c1, "Cobblestone")
			-- a raised lip round the basin
			for i = 0, 7 do
				local a1 = i / 8 * math.pi * 2
				local a2 = (i + 1) / 8 * math.pi * 2
				r:beam(
					Vector3.new(math.cos(a1) * 2.75, 1.12, math.sin(a1) * 2.75),
					Vector3.new(math.cos(a2) * 2.75, 1.12, math.sin(a2) * 2.75),
					0.5,
					0.25,
					shade(r.c1, 0.92),
					"Cobblestone"
				)
			end
			water(r:cyl(0, 1.04, 0, 0.08, 5.2, "y", r.c2, "Glass"))
			r:cyl(0, 2.1, 0, 2.2, 0.8, "y", r.c1, "Cobblestone")
			r:cyl(0, 3.4, 0, 0.4, 2.6, "y", r.c1, "Cobblestone")
			water(r:cyl(0, 3.62, 0, 0.06, 2.2, "y", r.c2, "Glass"))
			r:cyl(0, 4.1, 0, 1.0, 0.4, "y", r.c1, "Cobblestone")
			r:cyl(0, 4.7, 0, 0.25, 1.2, "y", r.c1, "Cobblestone")
			water(r:ball(0, 5.05, 0, 0.45, r.c2, "Glass"), 0.3)
			-- water spilling over the upper bowl
			for i = 0, 3 do
				local a = i * math.pi / 2 + math.pi / 4
				water(r:cyl(math.cos(a) * 1.22, 2.3, math.sin(a) * 1.22, 2.3, 0.14, "y", r.c2, "Glass"), 0.4)
			end
		end,
	},
	{
		id = "bench_garden",
		name = "Garden bench",
		cat = "garden",
		price = 90,
		place = "ground",
		size = Vector3.new(5, 3.4, 2),
		c1 = "B07A45",
		c2 = "2F3B35",
		tags = { "seat" },
		build = function(r: R)
			for _, sx in { -1, 1 } do
				local x = sx * 2.2
				r:block(x - 0.1, 0, 0.55, x + 0.1, 2.3, 0.75, r.c2, "Metal")
				r:beam(Vector3.new(x, 0, -0.7), Vector3.new(x, 3.3, -0.95), 0.2, 0.2, r.c2, "Metal")
				r:block(x - 0.1, 1.45, -0.8, x + 0.1, 1.6, 0.75, r.c2, "Metal")
				r:block(x - 0.13, 2.3, -0.85, x + 0.13, 2.42, 0.85, r.c2, "Metal")
				r:ball(x, 2.36, 0.85, 0.24, r.c2, "Metal")
			end
			for _, z in { -0.6, -0.2, 0.2, 0.6 } do
				r:block(-2.4, 1.6, z - 0.16, 2.4, 1.75, z + 0.16, r.c1, "WoodPlanks")
			end
			for _, y in { 2.2, 2.65, 3.1 } do
				local z = -0.8 - (y - 1.6) * 0.08
				r:block(-2.4, y - 0.15, z - 0.06, 2.4, y + 0.15, z + 0.06, r.c1, "WoodPlanks")
			end
			r:seat(-1.1, 1.75, 0)
			r:seat(1.1, 1.75, 0)
		end,
	},
	{
		id = "picnic_table",
		name = "Picnic table",
		cat = "garden",
		price = 150,
		place = "ground",
		size = Vector3.new(5, 2.8, 5.4),
		surface = 2.8,
		c1 = "B07A45",
		c2 = "8A5A2E",
		tags = { "seat", "table" },
		build = function(r: R)
			for _, z in { -0.9, -0.3, 0.3, 0.9 } do
				r:block(-2.5, 2.55, z - 0.28, 2.5, 2.8, z + 0.28, r.c1, "WoodPlanks")
			end
			for _, z in { -2.1, 2.1 } do
				r:block(-2.5, 1.45, z - 0.35, 2.5, 1.65, z + 0.35, r.c1, "WoodPlanks")
			end
			for _, x in { -1.9, 1.9 } do
				r:beam(Vector3.new(x, 0, -2.4), Vector3.new(x, 2.55, -0.4), 0.25, 0.25, r.c2, "Wood")
				r:beam(Vector3.new(x, 0, 2.4), Vector3.new(x, 2.55, 0.4), 0.25, 0.25, r.c2, "Wood")
				r:block(x - 0.12, 1.25, -2.45, x + 0.12, 1.45, 2.45, r.c2, "Wood")
				r:block(x - 0.12, 2.35, -1.2, x + 0.12, 2.55, 1.2, r.c2, "Wood")
			end
			for _, x in { -1.1, 1.1 } do
				r:seat(x, 1.65, -2.1, 0)
				r:seat(x, 1.65, 2.1, 180)
			end
		end,
	},
	{
		id = "mailbox",
		name = "Mailbox",
		cat = "garden",
		price = 40,
		place = "ground",
		size = Vector3.new(1.2, 3.6, 1.8),
		c1 = "5C7FA3",
		c2 = "8A5A2E",
		build = function(r: R)
			r:block(-0.15, 0, -0.15, 0.15, 2.6, 0.15, r.c2, "Wood")
			r:block(-0.3, 2.45, -0.5, 0.3, 2.6, 0.5, r.c2, "Wood")
			r:block(-0.45, 2.6, -0.8, 0.45, 3.1, 0.8, r.c1, "Metal")
			r:cyl(0, 3.1, 0, 1.6, 0.9, "z", r.c1, "Metal")
			r:block(-0.4, 2.65, 0.8, 0.4, 3.1, 0.84, shade(r.c1, 0.85), "Metal")
			r:cyl(0, 3.1, 0.82, 0.04, 0.8, "z", shade(r.c1, 0.85), "Metal")
			r:block(-0.05, 3.15, 0.84, 0.05, 3.25, 0.9, C.Metal, "Metal")
			-- the flag on the side
			r:block(0.45, 2.75, -0.3, 0.52, 3.55, -0.22, C.Red, "Metal")
			r:block(0.45, 3.3, -0.22, 0.52, 3.55, 0.15, C.Red, "Metal")
		end,
	},
	{
		id = "swing_set",
		name = "Swing set",
		cat = "garden",
		price = 350,
		place = "ground",
		size = Vector3.new(7, 7, 4.4),
		c1 = "C7383F",
		c2 = "F2C14E",
		build = function(r: R)
			for _, x in { -3.2, 3.2 } do
				r:beam(Vector3.new(x, 0, -2.0), Vector3.new(x, 6.6, 0), 0.35, 0.35, r.c1, "Metal")
				r:beam(Vector3.new(x, 0, 2.0), Vector3.new(x, 6.6, 0), 0.35, 0.35, r.c1, "Metal")
				r:block(x - 0.1, 1.9, -1.4, x + 0.1, 2.1, 1.4, r.c1, "Metal")
			end
			r:cyl(0, 6.6, 0, 6.8, 0.4, "x", r.c1, "Metal")
			for _, x in { -1.3, 1.3 } do
				for _, dx in { -0.55, 0.55 } do
					r:block(x + dx - 0.03, 1.6, -0.03, x + dx + 0.03, 6.45, 0.03, C.DarkMetal, "Metal")
				end
				r:block(x - 0.65, 1.45, -0.35, x + 0.65, 1.6, 0.35, r.c2, "Plastic")
				r:seat(x, 1.6, 0)
			end
		end,
	},
	{
		id = "slide",
		name = "Slide",
		cat = "garden",
		price = 280,
		place = "ground",
		size = Vector3.new(3, 5.4, 8),
		c1 = "5C7FA3",
		c2 = "F2C14E",
		build = function(r: R)
			-- a platform on four posts, with rails round it
			for _, x in { -1.1, 1.1 } do
				for _, z in { -2.7, -1.3 } do
					r:box(x, 2.7, z, 0.25, 5.4, 0.25, r.c1, "Metal")
				end
				r:block(x - 0.08, 5.1, -2.8, x + 0.08, 5.25, -1.2, r.c1, "Metal")
			end
			r:block(-1.2, 4.0, -2.8, 1.2, 4.25, -1.2, shade(r.c1, 1.2), "WoodPlanks")
			r:block(-1.1, 5.1, -2.8, 1.1, 5.25, -2.65, r.c1, "Metal")
			-- the ladder at the back
			for _, x in { -0.7, 0.7 } do
				r:beam(Vector3.new(x, 0, -3.8), Vector3.new(x, 4.25, -2.8), 0.15, 0.15, r.c1, "Metal")
			end
			for i = 1, 4 do
				local f = i / 5
				r:block(-0.7, f * 4.25 - 0.05, -3.8 + f - 0.08, 0.7, f * 4.25 + 0.05, -3.8 + f + 0.08, C.Metal, "Metal")
			end
			-- the chute, its sides and the flat end
			local top, foot = Vector3.new(0, 4.15, -1.2), Vector3.new(0, 0.75, 3.0)
			r:beam(top, foot, 1.4, 0.12, r.c2, "Plastic")
			for _, x in { -0.75, 0.75 } do
				r:beam(
					top + Vector3.new(x, 0.2, 0),
					foot + Vector3.new(x, 0.2, 0),
					0.12,
					0.45,
					shade(r.c2, 0.85),
					"Plastic"
				)
				r:block(x - 0.06, 0.55, 3.0, x + 0.06, 1.0, 3.9, shade(r.c2, 0.85), "Plastic")
			end
			r:block(-0.7, 0.55, 2.95, 0.7, 0.7, 3.9, r.c2, "Plastic")
			r:block(-0.15, 0, 2.6, 0.15, 0.6, 2.9, r.c1, "Metal")
		end,
	},
	{
		id = "sandbox",
		name = "Sandbox",
		cat = "garden",
		price = 80,
		place = "ground",
		size = Vector3.new(5, 1.2, 5),
		c1 = "C99A62",
		c2 = "EBD9A6",
		tags = { "toy" },
		build = function(r: R)
			for _, s in { -1, 1 } do
				r:block(-2.5, 0, s * 2.5 - 0.35 * s, 2.5, 0.7, s * 2.5, r.c1, "WoodPlanks")
				r:block(s * 2.5 - 0.35 * s, 0, -2.15, s * 2.5, 0.7, 2.15, r.c1, "WoodPlanks")
			end
			r:block(-2.15, 0, -2.15, 2.15, 0.45, 2.15, r.c2, "Sand")
			r:cyl(0.8, 0.5, -0.6, 0.3, 1.6, "y", r.c2, "Sand")
			-- a sand castle, a bucket and a spade
			r:block(0.5, 0.6, -0.9, 1.1, 1.0, -0.3, shade(r.c2, 0.95), "Sand")
			r:block(0.65, 1.0, -0.75, 0.95, 1.2, -0.45, shade(r.c2, 0.95), "Sand")
			r:cyl(-1.0, 0.7, 0.8, 0.5, 0.55, "y", C.Red, "Plastic")
			r:beam(Vector3.new(-1.27, 0.9, 0.8), Vector3.new(-1.0, 1.15, 0.8), 0.04, 0.04, C.Red, "Plastic")
			r:beam(Vector3.new(-0.73, 0.9, 0.8), Vector3.new(-1.0, 1.15, 0.8), 0.04, 0.04, C.Red, "Plastic")
			r:beam(Vector3.new(-0.2, 0.5, 1.2), Vector3.new(0.4, 0.62, 1.6), 0.08, 0.08, C.Blue, "Plastic")
			r:boxAt(CFrame.new(-0.35, 0.5, 1.05) * CFrame.Angles(0, -0.6, 0), 0.35, 0.05, 0.4, C.Blue, "Plastic")
		end,
	},
	{
		id = "campfire",
		name = "Campfire",
		cat = "garden",
		price = 60,
		place = "ground",
		size = Vector3.new(3, 1.2, 3),
		c1 = "8C8C92",
		c2 = "6E4C30",
		tags = { "light" },
		build = function(r: R)
			for i = 0, 7 do
				local t = i / 8 * math.pi * 2
				r:boxAt(
					CFrame.new(math.cos(t) * 1.15, 0.22, math.sin(t) * 1.15) * CFrame.Angles(0, -t + (i % 2) * 0.4, 0),
					0.6,
					0.45,
					0.5,
					if i % 2 == 0 then r.c1 else shade(r.c1, 1.12),
					"Slate"
				)
			end
			local ember = r:cyl(0, 0.05, 0, 0.1, 1.3, "y", Color3.fromRGB(255, 120, 50), "SmoothPlastic")
			r:glow(ember, 20, 1.5, Color3.fromRGB(255, 160, 90))
			r:cyl(0, 0.3, 0, 1.6, 0.35, "x", r.c2, "Wood")
			local top = r:cyl(0, 0.55, 0, 1.6, 0.35, "z", shade(r.c2, 1.15), "Wood")
			r:fire(top)
		end,
	},
	{
		id = "well",
		name = "Well",
		cat = "garden",
		price = 220,
		place = "ground",
		size = Vector3.new(4, 6.4, 4),
		c1 = "A0A0A6",
		c2 = "B5523B",
		build = function(r: R)
			r:cyl(0, 1.0, 0, 2.0, 3.4, "y", r.c1, "Cobblestone")
			r:cyl(0, 2.12, 0, 0.25, 3.7, "y", shade(r.c1, 0.9), "Cobblestone")
			r:cyl(0, 2.26, 0, 0.04, 2.8, "y", Color3.fromRGB(40, 70, 90), "Glass")
			for _, x in { -1.5, 1.5 } do
				r:box(x, 3.55, 0, 0.3, 3.1, 0.3, C.Bark, "Wood")
			end
			-- a little roof
			r:ramp(-1.95, 4.95, -2.0, 1.95, 6.3, 0, true, r.c2, "Slate")
			r:ramp(-1.95, 4.95, 0, 1.95, 6.3, 2.0, false, r.c2, "Slate")
			r:block(-2.0, 6.2, -0.15, 2.0, 6.4, 0.15, shade(r.c2, 0.8), "Slate")
			-- the winch, its handle, the rope and the bucket
			r:cyl(0, 4.3, 0, 3.0, 0.3, "x", C.Bark, "Wood")
			r:block(1.65, 4.0, -0.04, 1.75, 4.35, 0.04, C.DarkMetal, "Metal")
			r:block(1.65, 3.95, -0.04, 1.95, 4.05, 0.04, C.DarkMetal, "Metal")
			r:cyl(0, 3.75, 0, 1.0, 0.06, "y", C.Cream, "Fabric")
			r:cyl(0, 3.05, 0, 0.45, 0.55, "y", shade(C.Bark, 1.3), "WoodPlanks")
		end,
	},
	{
		id = "gnome",
		name = "Garden gnome",
		cat = "garden",
		price = 25,
		place = "ground",
		size = Vector3.new(1, 2, 1),
		c1 = "C7383F",
		c2 = "4F7FBF",
		build = function(r: R)
			for _, x in { -0.15, 0.15 } do
				r:block(x - 0.12, 0, -0.1, x + 0.12, 0.15, 0.22, C.Bark, "SmoothPlastic")
			end
			r:cyl(0, 0.5, 0, 0.7, 0.66, "y", r.c2, "SmoothPlastic")
			r:cyl(0, 0.6, 0, 0.08, 0.68, "y", C.Black, "SmoothPlastic")
			for _, sx in { -1, 1 } do
				r:ball(sx * 0.36, 0.65, 0.05, 0.22, r.c2, "SmoothPlastic")
			end
			r:ball(0, 0.95, 0.14, 0.48, C.White, "SmoothPlastic")
			r:ball(0, 1.15, 0.02, 0.46, Color3.fromRGB(245, 205, 175), "SmoothPlastic")
			r:ball(0, 1.12, 0.24, 0.15, Color3.fromRGB(235, 150, 140), "SmoothPlastic")
			-- a tall pointed hat
			r:cyl(0, 1.37, 0, 0.12, 0.58, "y", r.c1, "SmoothPlastic")
			r:cyl(0, 1.55, 0, 0.24, 0.44, "y", r.c1, "SmoothPlastic")
			r:cyl(0, 1.77, 0, 0.2, 0.28, "y", r.c1, "SmoothPlastic")
			r:cyl(0, 1.93, 0, 0.12, 0.13, "y", r.c1, "SmoothPlastic")
		end,
	},
	{
		id = "umbrella_sun",
		name = "Sun umbrella",
		cat = "garden",
		price = 120,
		place = "ground",
		size = Vector3.new(6, 6.6, 6),
		c1 = "E8735A",
		c2 = "F7F3EA",
		build = function(r: R)
			r:cyl(0, 0.15, 0, 0.3, 1.2, "y", C.DarkMetal, "Metal")
			r:cyl(0, 3.2, 0, 6.0, 0.18, "y", C.White, "Metal")
			-- eight panels in two colours
			local apex = Vector3.new(0, 6.3, 0)
			for i = 0, 7 do
				local a1 = i / 8 * math.pi * 2
				local a2 = (i + 1) / 8 * math.pi * 2
				local p1 = Vector3.new(math.cos(a1) * 2.9, 5.0, math.sin(a1) * 2.9)
				local p2 = Vector3.new(math.cos(a2) * 2.9, 5.0, math.sin(a2) * 2.9)
				r:tri(p1, p2, apex, 0.1, if i % 2 == 0 then r.c1 else r.c2, "Fabric")
			end
			r:ball(0, 6.4, 0, 0.3, C.White, "Metal")
		end,
	},
	{
		id = "planter_box",
		name = "Planter box",
		cat = "garden",
		price = 50,
		place = "ground",
		size = Vector3.new(4, 2, 1.6),
		c1 = "B07A45",
		c2 = "F2C14E",
		tags = { "plant" },
		build = function(r: R)
			for _, sx in { -1, 1 } do
				for _, sz in { -1, 1 } do
					r:box(sx * 1.8, 0.2, sz * 0.6, 0.3, 0.4, 0.3, shade(r.c1, 0.8), "Wood")
				end
			end
			r:block(-2, 0.4, -0.8, 2, 1.3, 0.8, r.c1, "WoodPlanks")
			r:block(-2, 1.3, -0.8, 2, 1.4, -0.65, shade(r.c1, 0.85), "Wood")
			r:block(-2, 1.3, 0.65, 2, 1.4, 0.8, shade(r.c1, 0.85), "Wood")
			r:block(-1.85, 1.3, -0.65, 1.85, 1.34, 0.65, C.Soil, "Sand")
			for i = 0, 4 do
				local x = -1.5 + i * 0.75
				r:ball(x, 1.6, 0, 0.62, if i % 2 == 0 then C.Leaf else C.DarkLeaf, "Grass")
			end
			for _, x in { -1.1, 0.4, 1.5 } do
				r:ball(x, 1.95, 0.1, 0.26, r.c2, "SmoothPlastic")
			end
		end,
	},
	{
		id = "path_stones",
		name = "Stepping stones",
		cat = "garden",
		price = 15,
		place = "ground",
		size = Vector3.new(2, 0.2, 2),
		c1 = "A8A49C",
		c2 = "A8A49C",
		build = function(r: R)
			r:cyl(-0.35, 0.08, -0.4, 0.16, 1.1, "y", r.c1, "Slate")
			r:cyl(0.5, 0.07, 0.3, 0.14, 0.9, "y", shade(r.c1, 0.92), "Slate")
			r:cyl(-0.45, 0.06, 0.62, 0.12, 0.65, "y", shade(r.c1, 1.06), "Slate")
		end,
	},
	{
		id = "bbq",
		name = "BBQ grill",
		cat = "garden",
		price = 180,
		place = "ground",
		size = Vector3.new(2.6, 3.2, 2.2),
		c1 = "C7383F",
		c2 = "45454A",
		build = function(r: R)
			for i = 0, 2 do
				local a = i / 3 * math.pi * 2 + math.pi / 2
				r:beam(
					Vector3.new(math.cos(a) * 0.45, 1.75, math.sin(a) * 0.45),
					Vector3.new(math.cos(a) * 0.85, 0, math.sin(a) * 0.85),
					0.12,
					0.12,
					r.c2,
					"Metal"
				)
			end
			r:cyl(0, 0.6, 0, 0.08, 1.2, "y", r.c2, "Metal")
			r:cyl(0, 1.75, 0, 0.3, 1.4, "y", r.c1, "Metal")
			r:cyl(0, 2.1, 0, 0.5, 1.9, "y", r.c1, "Metal")
			r:cyl(0, 2.37, 0, 0.04, 1.85, "y", C.Metal, "Metal")
			-- the domed lid, a little vent and the handle
			r:cyl(0, 2.55, 0, 0.3, 1.85, "y", r.c1, "Metal")
			r:cyl(0, 2.8, 0, 0.22, 1.35, "y", r.c1, "Metal")
			local vent = r:cyl(0.35, 2.94, 0, 0.06, 0.25, "y", r.c2, "Metal")
			vent.effect = "smoke"
			r:block(-0.25, 3.05, -0.05, 0.25, 3.12, 0.05, r.c2, "Metal")
			for _, x in { -0.2, 0.2 } do
				r:block(x - 0.03, 2.9, -0.03, x + 0.03, 3.05, 0.03, r.c2, "Metal")
			end
			-- a side shelf
			r:block(0.95, 2.0, -0.5, 1.3, 2.06, 0.5, Color3.fromRGB(176, 122, 69), "Wood")
			r:block(0.9, 1.6, -0.04, 1.0, 2.0, 0.04, r.c2, "Metal")
		end,
	},
	{
		id = "beach_chair",
		name = "Beach chair",
		cat = "garden",
		price = 70,
		place = "ground",
		size = Vector3.new(2.2, 2.8, 3.4),
		c1 = "4FA9D9",
		c2 = "C99A62",
		tags = { "seat" },
		build = function(r: R)
			for _, sx in { -1, 1 } do
				local x = sx * 0.95
				r:beam(Vector3.new(x, 0, 1.45), Vector3.new(x, 1.4, 1.2), 0.12, 0.14, r.c2, "Wood")
				r:beam(Vector3.new(x, 0, -0.3), Vector3.new(x, 2.7, -1.55), 0.12, 0.14, r.c2, "Wood")
				r:beam(Vector3.new(x, 1.35, 1.3), Vector3.new(x, 0.75, -0.7), 0.12, 0.14, r.c2, "Wood")
			end
			r:cyl(0, 2.62, -1.5, 2.0, 0.14, "x", r.c2, "Wood")
			r:cyl(0, 1.32, 1.22, 2.0, 0.14, "x", r.c2, "Wood")
			-- a striped sling that sags into a seat
			for i = 0, 2 do
				local x = -0.6 + i * 0.6
				local col = if i % 2 == 0 then r.c1 else C.White
				r:beam(Vector3.new(x, 1.25, 1.2), Vector3.new(x, 0.9, 0.0), 0.6, 0.06, col, "Fabric")
				r:beam(Vector3.new(x, 0.9, 0.0), Vector3.new(x, 2.55, -1.45), 0.6, 0.06, col, "Fabric")
			end
			r:seat(0, 0.95, 0.3)
		end,
	},
}

return items
