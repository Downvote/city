--!strict
-- Fittings for four trades: the florist's stand and plant bench, the artist's canvases and
-- sculptures, the music hall's seats and curtains, the builder's timber and big barn doors, and
-- a hanging sign each for the flower shop, the studio and the hall (the workshop's is in
-- WallDecor). The ready-made buildings in Data/Buildings use them; they are on sale in Build
-- mode like everything else.

local Recipe = require(script.Parent.Parent.Recipe)
local Colors = require(script.Parent.Parent.Parent.Util.Colors)

local C = Recipe.Colors

type R = Recipe.Recipe

local function shade(c: Color3, k: number): Color3
	return Colors.shade(c, k)
end

local LILAC = Color3.fromRGB(156, 122, 214)
local ORANGE = Color3.fromRGB(232, 150, 88)
local TERRACOTTA = Color3.fromRGB(196, 104, 62)
local ZINC = Color3.fromRGB(176, 182, 188)

-- The iron arm a hanging sign swings from: a plate on the wall, an arm square out from it, a
-- brace and two links. The board hangs under it between z = 0.5 and 2.66 (WallDecor's workshop
-- sign has the same arm, so the four hang alike).
local function signArm(r: R)
	r:piece(function(q: R)
		q:block(-0.1, 2.3, 0, 0.1, 3.3, 0.08, C.DarkMetal, "Metal")
		q:block(-0.05, 3.0, 0.08, 0.05, 3.1, 2.8, C.DarkMetal, "Metal")
		q:beam(Vector3.new(0, 2.4, 0.08), Vector3.new(0, 3.0, 1.0), 0.08, 0.08, C.DarkMetal, "Metal")
		for _, z in { 0.78, 2.38 } do
			q:block(-0.03, 2.7, z - 0.03, 0.03, 3.0, z + 0.03, C.DarkMetal, "Metal")
		end
	end)
end

-- A canvas on its stretcher leaning back against a wall behind it (-z): `w` wide and `h` tall,
-- its foot at z = foot. Returns its frame, for painting on its face (x across, y up the canvas,
-- z = 0.1 just proud of it).
local function canvas(r: R, x: number, foot: number, w: number, h: number, face: Color3, wood: Color3): CFrame
	local lean = math.rad(12)
	local cf = CFrame.new(x, h * math.cos(lean) / 2, foot - h * math.sin(lean) / 2) * CFrame.Angles(-lean, 0, 0)
	r:boxAt(cf, w, h, 0.14, wood, "Wood")
	r:boxAt(cf * CFrame.new(0, 0, 0.08), w - 0.08, h - 0.08, 0.04, face, "Fabric")
	return cf
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
	opening: { w: number, h: number, sill: number }?,
	build: (r: R) -> (),
}

local items: { Item } = {
	-- the florist's ------------------------------------------------------------------------------
	{
		id = "flower_stand",
		name = "Flower stand",
		cat = "decor",
		price = 110,
		place = "floor",
		size = Vector3.new(5, 4.6, 2.8),
		c1 = "8FB39A",
		c2 = "F59EB5",
		tags = { "plant" },
		build = function(r: R)
			-- Three steps of buckets, the way a flower shop sets them out on the pavement: c1 the
			-- woodwork, c2 the flowers there are most of.
			local tops = { 1.0, 1.9, 2.8 } -- each step's top, front to back
			local mids = { 0.9, 0, -0.9 } -- and the middle of it
			local frame = shade(r.c1, 0.8)
			r:piece(function(q: R)
				for _, sx in { -1, 1 } do
					local x = sx * 2.3
					q:block(x - 0.1, 0, 1.1, x + 0.1, 0.86, 1.3, frame, "Wood")
					q:block(x - 0.1, 0, -0.1, x + 0.1, 1.76, 0.1, frame, "Wood")
					q:block(x - 0.1, 0, -1.3, x + 0.1, 2.66, -1.1, frame, "Wood")
					q:beam(Vector3.new(x, 0.78, 1.3), Vector3.new(x, 2.58, -1.3), 0.16, 0.2, frame, "Wood")
				end
				q:block(-2.3, 0.3, -1.26, 2.3, 0.5, -1.14, frame, "Wood")
			end, true)
			for i, top in tops do
				r:block(-2.45, top - 0.14, mids[i] - 0.45, 2.45, top, mids[i] + 0.45, r.c1, "WoodPlanks")
			end
			-- nine zinc buckets, and a rail along the back of the top step
			r:piece(function(q: R)
				q:block(-2.45, 2.8, -1.34, 2.45, 2.9, -1.26, ZINC, "Metal")
				for i, top in tops do
					for _, x in { -1.5, 0, 1.5 } do
						q:cyl(x, top + 0.4, mids[i], 0.8, 0.74, "y", ZINC, "Metal")
					end
				end
			end, true)
			-- leaves in every bucket, taller stems in the back row
			r:piece(function(q: R)
				for i, top in tops do
					for k, x in { -1.5, 0, 1.5 } do
						q:ball(x, top + 0.95, mids[i], 0.8, if (i + k) % 2 == 0 then C.Leaf else C.DarkLeaf, "Grass")
					end
				end
				for _, x in { -1.5, 0, 1.5 } do
					q:block(x - 0.05, 3.7, -0.95, x + 0.05, 4.2, -0.85, C.DarkLeaf, "Grass")
				end
			end)
			-- the flowers: three heads to a bucket, a colour to a bucket
			local blooms = { r.c2, C.Yellow, C.Red, C.White, r.c2, LILAC, ORANGE, r.c2, C.White }
			for i, top in tops do
				r:piece(function(q: R)
					-- a little price card on the edge of the step
					q:box(1.9, top - 0.07, mids[i] + 0.47, 0.5, 0.3, 0.04, C.Paper, "SmoothPlastic")
					for k, x in { -1.5, 0, 1.5 } do
						local col = blooms[(i - 1) * 3 + k]
						local y = top + (if i == 3 then 1.5 else 1.25)
						q:ball(x - 0.24, y, mids[i] + 0.12, 0.42, col, "SmoothPlastic")
						q:ball(x + 0.22, y + 0.1, mids[i] - 0.1, 0.42, col, "SmoothPlastic")
						q:ball(x + 0.02, y + 0.22, mids[i] + 0.2, 0.38, col, "SmoothPlastic")
					end
				end)
			end
		end,
	},
	{
		id = "plant_bench",
		name = "Plant bench",
		cat = "garden",
		price = 120,
		place = "floor",
		size = Vector3.new(6, 5.4, 2.4),
		c1 = "C49A6C",
		c2 = "F59EB5",
		tags = { "plant" },
		build = function(r: R)
			-- A slatted bench for a glasshouse: a tray of seedlings, pots at every stage and a
			-- watering can on top, sacks and spare pots under it. c1 the wood, c2 the flowers.
			local leg = shade(r.c1, 0.72)
			r:piece(function(q: R)
				for _, sx in { -1, 1 } do
					for _, sz in { -1, 1 } do
						q:box(sx * 2.75, 1.45, sz * 0.95, 0.3, 2.9, 0.3, leg, "Wood")
					end
					q:block(sx * 2.75 - 0.1, 0.8, -0.8, sx * 2.75 + 0.1, 1.0, 0.8, leg, "Wood")
				end
				q:block(-2.6, 2.6, 1.0, 2.6, 2.9, 1.1, leg, "Wood")
				q:block(-2.6, 2.6, -1.1, 2.6, 2.9, -1.0, leg, "Wood")
			end, true)
			for i = 0, 4 do
				local z = -1.15 + i * 0.47
				r:block(-3, 2.9, z, 3, 3.1, z + 0.42, if i % 2 == 0 then r.c1 else shade(r.c1, 0.92), "WoodPlanks")
			end
			for _, z in { -0.6, 0, 0.6 } do
				r:block(-2.65, 1.0, z - 0.24, 2.65, 1.1, z + 0.24, shade(r.c1, 0.86), "WoodPlanks")
			end
			-- the seed tray, the pots and the spare ones stacked under the bench
			r:piece(function(q: R)
				q:block(-2.7, 3.1, -0.7, -1.1, 3.4, 0.6, shade(r.c1, 0.8), "Wood")
				q:block(-2.6, 3.36, -0.6, -1.2, 3.44, 0.5, C.Soil, "Wood")
				q:cyl(-0.3, 3.5, -0.3, 0.8, 0.9, "y", TERRACOTTA, "Wood")
				q:cyl(0.9, 3.42, 0.35, 0.64, 0.74, "y", TERRACOTTA, "Wood")
				q:cyl(1.9, 3.5, -0.4, 0.8, 0.9, "y", TERRACOTTA, "Wood")
				q:cyl(-0.3, 3.92, -0.3, 0.06, 0.76, "y", C.Soil, "Wood")
				q:cyl(1.9, 3.92, -0.4, 0.06, 0.76, "y", C.Soil, "Wood")
				q:cyl(1.6, 1.5, 0.1, 0.8, 1.0, "y", TERRACOTTA, "Wood")
				q:cyl(1.6, 1.98, 0.1, 0.36, 0.9, "y", shade(TERRACOTTA, 0.9), "Wood")
				q:cyl(0.5, 1.4, -0.2, 0.6, 0.76, "y", shade(TERRACOTTA, 0.9), "Wood")
			end, true)
			-- a sack of compost under the bench
			r:block(-2.3, 1.1, -0.6, -0.7, 1.75, 0.5, Color3.fromRGB(196, 170, 120), "Fabric")
			r:block(-2.0, 1.76, -0.3, -1.0, 1.78, 0.2, Color3.fromRGB(96, 140, 84), "Fabric")
			-- seedlings, a leafy plant, a small one and one in flower
			r:piece(function(q: R)
				q:block(-2.5, 3.44, -0.52, -2.42, 3.74, -0.44, C.Leaf, "Grass")
				for i = 0, 3 do
					for j = 0, 2 do
						q:ball(
							-2.45 + i * 0.37,
							3.6,
							-0.42 + j * 0.4,
							0.3,
							if (i + j) % 2 == 0 then C.Leaf else C.DarkLeaf,
							"Grass"
						)
					end
				end
				q:lump(CFrame.new(-0.3, 4.35, -0.3), 1.0, 1.1, 0.95, C.DarkLeaf, "Grass")
				q:lump(CFrame.new(-0.15, 4.75, -0.35) * CFrame.Angles(0, 0.6, 0.3), 0.7, 0.8, 0.6, C.Leaf, "Grass")
				q:ball(0.9, 3.95, 0.35, 0.6, C.Leaf, "Grass")
				q:ball(1.9, 4.2, -0.4, 0.9, C.Leaf, "Grass")
			end)
			for _, p in { { 1.65, 4.6, -0.25 }, { 2.1, 4.66, -0.5 }, { 1.92, 4.78, -0.2 }, { 1.8, 4.5, -0.66 } } do
				r:noCollide(r:ball(p[1], p[2], p[3], 0.36, r.c2, "SmoothPlastic"))
			end
			-- the watering can at the front
			r:piece(function(q: R)
				q:box(2.35, 3.45, 0.55, 0.5, 0.7, 0.5, ZINC, "Metal")
				q:beam(Vector3.new(2.35, 3.35, 0.8), Vector3.new(2.35, 3.85, 1.12), 0.12, 0.12, ZINC, "Metal")
				q:block(2.3, 3.8, 0.2, 2.4, 3.9, 0.56, ZINC, "Metal")
				q:block(2.3, 3.3, 0.2, 2.4, 3.9, 0.3, ZINC, "Metal")
			end)
		end,
	},
	{
		id = "sign_flowers",
		name = "Flower shop sign",
		cat = "walldecor",
		price = 40,
		place = "wall",
		size = Vector3.new(0.6, 3.3, 3),
		c1 = "FAF6EC",
		c2 = "4E7F62",
		build = function(r: R)
			-- a round board with a flower on both faces, hung square from the wall so it reads
			-- from along the street: c1 the board, c2 its rim and the leaves
			signArm(r)
			local y, z = 1.7, 1.58
			r:cyl(0, y, z, 0.16, 2.0, "x", r.c1, "Wood")
			r:cyl(0, y, z, 0.1, 2.2, "x", r.c2, "Wood")
			r:piece(function(q: R)
				for _, sx in { -1, 1 } do
					local x = sx * 0.1
					q:box(x, y - 0.42, z, 0.04, 0.6, 0.1, r.c2, "Metal")
					q:boxAt(
						CFrame.new(x, y - 0.5, z + 0.2) * CFrame.Angles(math.rad(-35), 0, 0),
						0.04,
						0.16,
						0.4,
						r.c2,
						"Metal"
					)
					q:boxAt(
						CFrame.new(x, y - 0.36, z - 0.2) * CFrame.Angles(math.rad(35), 0, 0),
						0.04,
						0.16,
						0.4,
						r.c2,
						"Metal"
					)
					for k = 0, 4 do
						local a = math.rad(90 + k * 72)
						q:cyl(
							x,
							y + 0.22 + math.sin(a) * 0.36,
							z + math.cos(a) * 0.36,
							0.04,
							0.42,
							"x",
							C.Pink,
							"Metal"
						)
					end
					q:cyl(sx * 0.12, y + 0.22, z, 0.04, 0.3, "x", C.Yellow, "Metal")
				end
			end)
		end,
	},
	-- the artist's -------------------------------------------------------------------------------
	{
		id = "sign_palette",
		name = "Studio sign",
		cat = "walldecor",
		price = 40,
		place = "wall",
		size = Vector3.new(0.6, 3.3, 3),
		c1 = "DDBE94",
		c2 = "9A6B48",
		tags = { "art" },
		build = function(r: R)
			-- a painter's palette with its dabs of paint and a brush across it, the same on both
			-- faces: c1 the palette, c2 its edge and the brush
			signArm(r)
			local y, z = 1.7, 1.58
			r:cyl(0, y, z, 0.16, 2.0, "x", r.c1, "Wood")
			r:cyl(0, y, z, 0.1, 2.16, "x", r.c2, "Wood")
			local dabs = { C.Red, C.Yellow, C.Blue, Color3.fromRGB(120, 191, 94), C.White }
			r:piece(function(q: R)
				for _, sx in { -1, 1 } do
					local x = sx * 0.1
					-- the thumb hole, the dabs round the top and the brush
					q:box(x, y - 0.45, z + 0.45, 0.04, 0.3, 0.3, shade(r.c2, 0.6), "Metal")
					for k, col in dabs do
						local a = math.rad(30 + (k - 1) * 32)
						q:cyl(x, y + math.sin(a) * 0.62, z + math.cos(a) * 0.62, 0.04, 0.34, "x", col, "Metal")
					end
					local lean = CFrame.new(sx * 0.17, y - 0.15, z - 0.1) * CFrame.Angles(math.rad(40), 0, 0)
					q:boxAt(lean, 0.04, 0.1, 1.5, r.c2, "Metal")
					q:boxAt(lean * CFrame.new(0, 0, -0.85), 0.04, 0.16, 0.26, C.Blue, "Metal")
				end
			end)
		end,
	},
	{
		id = "canvas_stack",
		name = "Stack of canvases",
		cat = "decor",
		price = 60,
		place = "floor",
		size = Vector3.new(3.6, 4.4, 2),
		c1 = "7FB8D9",
		c2 = "C49A6C",
		tags = { "art" },
		build = function(r: R)
			-- Three canvases leaning on the wall behind them, a big blank one at the back, a
			-- seascape started and a small one nearly done: c1 the sea, c2 the stretchers.
			canvas(r, 0, -0.05, 3.3, 4.2, C.Paper, r.c2)
			local sea = canvas(r, -0.35, 0.36, 2.6, 3.1, r.c1, r.c2)
			r:piece(function(q: R)
				-- a tube of paint left on the floor, then the picture: a low sun, its light on
				-- the water and a strip of shore
				q:block(1.3, 0, 0.6, 1.7, 0.14, 0.76, C.Red, "Fabric")
				q:boxAt(sea * CFrame.new(0, -0.9, 0.12), 2.5, 1.2, 0.04, shade(r.c1, 0.72), "Fabric")
				q:boxAt(sea * CFrame.new(0.5, 0.75, 0.12), 0.6, 0.6, 0.04, C.Yellow, "Fabric")
				q:boxAt(sea * CFrame.new(0.5, -0.5, 0.165), 0.5, 0.12, 0.04, C.Yellow, "Fabric")
				q:boxAt(sea * CFrame.new(0.45, -0.85, 0.165), 0.8, 0.12, 0.04, C.Yellow, "Fabric")
				q:boxAt(sea * CFrame.new(-0.6, -1.4, 0.165), 1.3, 0.2, 0.04, Color3.fromRGB(226, 204, 150), "Fabric")
			end)
			local small = canvas(r, 0.75, 0.78, 1.7, 2.0, Color3.fromRGB(244, 226, 190), r.c2)
			r:piece(function(q: R)
				q:block(-1.7, 0, 0.5, -1.3, 0.1, 0.9, C.Paper, "Fabric")
				q:boxAt(small * CFrame.new(-0.3, 0.3, 0.12), 0.7, 0.9, 0.04, C.Red, "Fabric")
				q:boxAt(small * CFrame.new(0.35, -0.2, 0.12), 0.6, 0.7, 0.04, Color3.fromRGB(62, 110, 88), "Fabric")
				q:boxAt(small * CFrame.new(0.1, 0.55, 0.165), 0.9, 0.14, 0.04, C.Black, "Fabric")
			end)
		end,
	},
	{
		id = "sculpture_form",
		name = "Standing sculpture",
		cat = "decor",
		price = 220,
		place = "floor",
		size = Vector3.new(2.4, 6.6, 2.4),
		c1 = "BDB8AE",
		c2 = "F2EFE8",
		tags = { "art" },
		build = function(r: R)
			-- A carved figure, more or less, on a block of stone: three leaning forms and a head.
			-- c1 the plinth, c2 the carving.
			r:block(-1, 0, -1, 1, 1.5, 1, r.c1, "Concrete")
			r:block(-1.1, 1.5, -1.1, 1.1, 1.72, 1.1, shade(r.c1, 0.86), "Concrete")
			r:block(-0.6, 1.72, -0.5, 0.6, 1.9, 0.5, shade(r.c2, 0.84), "Marble")
			r:lump(CFrame.new(-0.05, 3.0, 0) * CFrame.Angles(0, 0.5, 0.16), 1.3, 2.5, 1.0, r.c2, "Marble")
			r:lump(CFrame.new(0.22, 4.55, 0.05) * CFrame.Angles(0.2, -0.3, -0.42), 1.5, 1.5, 0.9, r.c2, "Marble")
			r:lump(
				CFrame.new(-0.3, 4.1, 0.2) * CFrame.Angles(0.5, 0.2, 0.9),
				0.6,
				1.4,
				0.55,
				shade(r.c2, 0.93),
				"Marble"
			)
			r:ball(0.05, 5.8, 0, 0.9, r.c2, "Marble")
		end,
	},
	{
		id = "sculpture_ring",
		name = "Ring sculpture",
		cat = "decor",
		price = 260,
		place = "floor",
		size = Vector3.new(4, 6, 1.6),
		c1 = "BDB8AE",
		c2 = "5E8C7A",
		tags = { "art" },
		build = function(r: R)
			-- A hoop of cast metal stood on edge on a low block, with a ball caught in it.
			-- c1 the plinth, c2 the metal.
			r:block(-1.3, 0, -0.75, 1.3, 1.5, 0.75, r.c1, "Concrete")
			r:block(-1.4, 1.5, -0.8, 1.4, 1.7, 0.8, shade(r.c1, 0.86), "Concrete")
			local cy, rad = 3.6, 1.7
			local pts = {}
			for k = 0, 7 do
				local a = math.rad(22.5 + k * 45)
				table.insert(pts, Vector3.new(math.cos(a) * rad, cy + math.sin(a) * rad, 0))
			end
			for k = 1, 8 do
				local a, b = pts[k], pts[k % 8 + 1]
				local d = (b - a).Unit * 0.22
				-- every other segment a little thinner, so where two meet their faces don't lie together
				local thick = if k % 2 == 0 then 0.55 else 0.47
				r:beam(a - d, b + d, thick, 0.55, if k % 2 == 0 then r.c2 else shade(r.c2, 0.9), "Metal")
			end
			r:block(-0.5, 1.7, -0.34, 0.5, 1.82, 0.34, shade(r.c2, 0.8), "Metal")
			r:ball(0.45, cy + 0.45, 0, 1.0, shade(r.c2, 1.25), "Metal")
		end,
	},
	-- the music hall's ---------------------------------------------------------------------------
	{
		id = "sign_music",
		name = "Music hall sign",
		cat = "walldecor",
		price = 40,
		place = "wall",
		size = Vector3.new(0.6, 3.3, 3),
		c1 = "FAF6EC",
		c2 = "6F5676",
		tags = { "music" },
		build = function(r: R)
			-- a board with two notes joined at the top, the same on both faces: c1 the board,
			-- c2 its edges and the notes
			signArm(r)
			r:block(-0.08, 0.96, 0.5, 0.08, 2.64, 2.66, r.c1, "Wood")
			r:block(-0.12, 2.58, 0.46, 0.12, 2.7, 2.7, r.c2, "Wood")
			r:block(-0.12, 0.9, 0.46, 0.12, 1.02, 2.7, r.c2, "Wood")
			r:piece(function(q: R)
				for _, sx in { -1, 1 } do
					local x = sx * 0.1
					q:box(x, 1.75, 1.34, 0.04, 0.9, 0.1, r.c2, "Metal")
					q:box(x, 1.85, 2.14, 0.04, 0.9, 0.1, r.c2, "Metal")
					q:beam(Vector3.new(x, 2.14, 1.29), Vector3.new(x, 2.24, 2.19), 0.04, 0.2, r.c2, "Metal")
					q:cyl(x, 1.3, 1.18, 0.04, 0.42, "x", r.c2, "Metal")
					q:cyl(x, 1.4, 1.98, 0.04, 0.42, "x", r.c2, "Metal")
				end
			end)
		end,
	},
	{
		id = "seat_row",
		name = "Row of hall seats",
		cat = "seating",
		price = 150,
		place = "floor",
		size = Vector3.new(6.2, 3.8, 2.4),
		c1 = "B8505A",
		c2 = "8A5E40",
		tags = { "seat" },
		build = function(r: R)
			-- three seats in a row, the kind a hall or a little cinema has: c1 the cloth, c2 the
			-- wood of the ends, the arms and the backs
			r:piece(function(q: R)
				for i = 0, 3 do
					local x = -2.95 + i * 1.967
					q:block(x - 0.12, 0, -0.9, x + 0.12, 2.3, 0.85, r.c2, "Wood")
					q:block(x - 0.2, 2.3, -0.75, x + 0.2, 2.46, 0.95, shade(r.c2, 1.25), "Wood")
					q:block(x - 0.3, 0, -1.05, x + 0.3, 0.14, 1.0, shade(r.c2, 0.8), "Wood")
				end
				q:block(-2.95, 0.5, -0.86, 2.95, 0.7, -0.7, r.c2, "Wood")
			end, true)
			for i = 0, 2 do
				local x = -1.967 + i * 1.967
				r:block(x - 0.82, 1.4, -0.65, x + 0.82, 1.8, 0.85, r.c1, "Fabric")
				r:block(x - 0.82, 1.28, -0.65, x + 0.82, 1.4, 0.8, shade(r.c2, 0.85), "Wood")
				local back = CFrame.new(x, 2.75, -0.88) * CFrame.Angles(math.rad(-9), 0, 0)
				r:boxAt(back * CFrame.new(0, 0, -0.1), 1.72, 2.0, 0.14, r.c2, "Wood")
				r:boxAt(back * CFrame.new(0, 0.02, 0.04), 1.6, 1.8, 0.2, r.c1, "Fabric")
				r:seat(x, 1.8, 0.1)
			end
			-- a brass number on the end by the aisle
			r:cyl(3.08, 1.5, 0.1, 0.04, 0.4, "x", C.Gold, "Metal")
			r:cyl(-3.08, 1.5, 0.1, 0.04, 0.4, "x", C.Gold, "Metal")
		end,
	},
	{
		id = "stage_curtain",
		name = "Stage curtains",
		cat = "decor",
		price = 180,
		place = "floor",
		size = Vector3.new(11.2, 10.8, 1.2),
		c1 = "B8505A",
		c2 = "D9A93F",
		build = function(r: R)
			-- A pelmet with a row of swags and a drape drawn back at each side, to stand across
			-- the front of a stage (the middle is open to walk through): c1 the cloth, c2 the
			-- braid and the ties.
			r:block(-5.6, 9.4, -0.3, 5.6, 10.72, 0.3, r.c1, "Fabric")
			r:block(-5.64, 9.28, -0.34, 5.64, 9.42, 0.34, r.c2, "Fabric")
			r:block(-5.64, 10.66, -0.36, 5.64, 10.8, 0.36, shade(r.c1, 0.8), "Fabric")
			for i = 0, 3 do
				local x = -2.85 + i * 1.9
				r:noCollide(r:cyl(x, 9.32, 0, 0.5, 1.9, "z", shade(r.c1, if i % 2 == 0 then 1.12 else 0.94), "Fabric"))
			end
			for _, sx in { -1, 1 } do
				-- the drape in folds, gathered in at the tie
				for i = 0, 3 do
					local x1 = sx * (5.5 - i * 0.4)
					local x2 = sx * (5.5 - (i + 1) * 0.4)
					local deep = i % 2 == 0
					local z1, z2 = if deep then -0.28 else -0.14, if deep then 0.14 else 0.28
					local col = if deep then r.c1 else shade(r.c1, 1.12)
					r:block(math.min(x1, x2), 4.3, z1, math.max(x1, x2), 9.3, z2, col, "Fabric")
					if i < 3 then
						r:block(math.min(x1, x2), 0, z1, math.max(x1, x2), 4.3, z2, col, "Fabric")
					end
				end
				r:block(
					math.min(sx * 5.56, sx * 4.2),
					4.1,
					-0.36,
					math.max(sx * 5.56, sx * 4.2),
					4.4,
					0.36,
					r.c2,
					"Fabric"
				)
				r:noCollide(r:ball(sx * 4.25, 3.9, 0.3, 0.4, r.c2, "Fabric"))
			end
		end,
	},
	-- the builder's ------------------------------------------------------------------------------
	{
		id = "timber_rack",
		name = "Timber rack",
		cat = "storage",
		price = 140,
		place = "floor",
		size = Vector3.new(7.2, 6.6, 2.4),
		c1 = "5A5560",
		c2 = "DDBE94",
		tags = { "storage" },
		build = function(r: R)
			-- Three posts with arms, and timber laid along them: beams at the bottom, planks in
			-- the middle, boards and poles on top. c1 the rack, c2 the timber.
			r:piece(function(q: R)
				for _, x in { -2.9, 0, 2.9 } do
					q:block(x - 0.16, 0, -1.0, x + 0.16, 6.5, -0.7, r.c1, "Metal")
					q:block(x - 0.2, 0, -1.1, x + 0.2, 0.2, 1.1, r.c1, "Metal")
					for _, y in { 0.9, 2.8, 4.7 } do
						q:block(x - 0.12, y, -0.7, x + 0.12, y + 0.2, 1.05, r.c1, "Metal")
						q:block(x - 0.12, y + 0.2, 0.93, x + 0.12, y + 0.5, 1.05, r.c1, "Metal")
					end
				end
			end, true)
			local dark, pale = shade(r.c2, 0.82), shade(r.c2, 1.1)
			r:piece(function(q: R)
				-- three heavy beams
				q:block(-3.5, 1.1, -0.62, 3.5, 1.7, -0.08, dark, "Wood")
				q:block(-3.4, 1.1, 0.0, 3.6, 1.7, 0.54, r.c2, "Wood")
				q:block(-3.3, 1.7, -0.5, 3.3, 2.26, 0.04, pale, "Wood")
				-- planks, two piles
				for i = 0, 3 do
					q:block(
						-3.5 + i * 0.05,
						3.0 + i * 0.24,
						-0.64,
						3.4 + i * 0.05,
						3.22 + i * 0.24,
						0.1,
						if i % 2 == 0 then r.c2 else pale,
						"Wood"
					)
				end
				for i = 0, 2 do
					q:block(
						-3.2,
						3.0 + i * 0.24,
						0.2,
						3.6,
						3.22 + i * 0.24,
						0.88,
						if i % 2 == 0 then pale else dark,
						"Wood"
					)
				end
				-- thin boards and a few poles
				for i = 0, 2 do
					q:block(
						-3.4,
						4.9 + i * 0.14,
						-0.6,
						3.5,
						5.02 + i * 0.14,
						0.2,
						if i % 2 == 0 then dark else r.c2,
						"Wood"
					)
				end
				for i = 0, 2 do
					q:cyl(0.1 * i, 5.08, 0.36 + i * 0.26, 6.8, 0.26, "x", if i % 2 == 0 then pale else r.c2, "Wood")
				end
			end, true)
			-- the ends of the beams are painted, the way a yard marks its stock
			r:block(3.5, 1.12, -0.6, 3.54, 1.68, -0.1, C.Red, "SmoothPlastic")
			r:block(3.6, 1.12, 0.02, 3.64, 1.68, 0.52, C.Red, "SmoothPlastic")
		end,
	},
	{
		id = "plank_stack",
		name = "Stack of planks",
		cat = "storage",
		price = 45,
		place = "floor",
		size = Vector3.new(6.4, 2.3, 2.8),
		surface = 2.04,
		c1 = "DDBE94",
		c2 = "9A6B48",
		tags = { "storage" },
		build = function(r: R)
			-- sawn planks piled on three bearers with sticks between the layers, so the air gets
			-- through, and two more thrown on top: c1 the planks, c2 the bearers
			local tones = { r.c1, shade(r.c1, 0.88), shade(r.c1, 1.08), shade(r.c1, 0.94) }
			r:piece(function(q: R)
				for _, x in { -2.3, 0, 2.3 } do
					q:block(x - 0.2, 0, -1.3, x + 0.2, 0.3, 1.3, r.c2, "Wood")
				end
				for layer = 0, 3 do
					local y = 0.3 + layer * 0.38
					for i = 0, 3 do
						local z = -1.24 + i * 0.63
						local slip = ((layer * 3 + i * 5) % 4) * 0.06 - 0.1
						q:block(-3 + slip, y, z, 3 + slip, y + 0.3, z + 0.58, tones[(layer + i * 3) % 4 + 1], "Wood")
					end
					if layer < 3 then
						for _, x in { -2.3, 2.3 } do
							q:block(x - 0.1, y + 0.3, -1.2, x + 0.1, y + 0.38, 1.2, r.c2, "Wood")
						end
					end
				end
			end, true)
			r:boxAt(CFrame.new(-0.2, 1.89, -0.3) * CFrame.Angles(0, math.rad(7), 0), 5.8, 0.3, 0.58, tones[3], "Wood")
			r:boxAt(CFrame.new(0.3, 1.89, 0.85) * CFrame.Angles(0, math.rad(-5), 0), 5.6, 0.3, 0.58, tones[2], "Wood")
		end,
	},
	{
		id = "door_barn_big",
		name = "Big barn doors",
		cat = "doors",
		price = 380,
		place = "opening",
		size = Vector3.new(8.6, 10.4, 1.2),
		opening = { w = 8, h = 10, sill = 0 },
		c1 = "B8505A",
		c2 = "FAF6EC",
		build = function(r: R)
			-- A pair of boarded doors eight studs wide and ten tall, each braced with a Z and hung
			-- on long iron straps; they swing open like any door. c1 the boards, c2 the braces
			-- and the frame.
			local W, H = 8, 10
			r:block(-W / 2 - 0.3, 0, -0.45, -W / 2, H + 0.3, 0.45, r.c2, "Wood")
			r:block(W / 2, 0, -0.45, W / 2 + 0.3, H + 0.3, 0.45, r.c2, "Wood")
			r:block(-W / 2 - 0.3, H, -0.45, W / 2 + 0.3, H + 0.3, 0.45, r.c2, "Wood")
			for _, sx in { -1, 1 } do
				local hinge = sx * (W / 2 - 0.05)
				local x1, x2 = math.min(sx * 0.03, hinge), math.max(sx * 0.03, hinge)
				local parts = {}
				table.insert(parts, r:block(x1, 0.05, -0.12, x2, H - 0.15, 0.12, r.c1, "WoodPlanks"))
				-- the brace on the outside: three rails and a strut that runs up from the hinge
				for _, y in { 0.9, 5.0, 9.0 } do
					table.insert(parts, r:block(x1 + 0.1, y - 0.25, 0.12, x2 - 0.1, y + 0.25, 0.24, r.c2, "Wood"))
				end
				for _, span in { { 1.15, 4.75 }, { 5.25, 8.75 } } do
					local strut = r:beam(
						Vector3.new(hinge - sx * 0.3, span[1], 0.18),
						Vector3.new(sx * 0.35, span[2], 0.18),
						0.12,
						0.44,
						r.c2,
						"Wood"
					)
					if strut then
						table.insert(parts, strut)
					end
				end
				-- two straps and a ring to pull it by, and a bar across on the inside
				for _, y in { 0.9, 9.0 } do
					table.insert(
						parts,
						r:block(hinge - sx * 1.6, y - 0.1, 0.24, hinge, y + 0.1, 0.3, C.DarkMetal, "Metal")
					)
				end
				table.insert(parts, r:cyl(sx * 0.6, 4.2, 0.28, 0.08, 0.56, "z", C.DarkMetal, "Metal"))
				table.insert(parts, r:block(x1 + 0.2, 4.7, -0.22, x2 - 0.2, 5.0, -0.12, shade(r.c1, 0.75), "Wood"))
				for _, p in parts do
					r:door(p, hinge)
				end
			end
		end,
	},
}

return items
