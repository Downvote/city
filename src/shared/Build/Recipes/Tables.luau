--!strict
-- Tables, desks and nightstands. `surface` is the height of the top, where small things can stand.
-- c1 is the top and body, c2 the legs or a second wood.

local Recipe = require(script.Parent.Parent.Recipe)
local Colors = require(script.Parent.Parent.Parent.Util.Colors)

local C = Recipe.Colors

type R = Recipe.Recipe

local function shade(c: Color3, k: number): Color3
	return Colors.shade(c, k)
end

-- A dining table top with an apron and four legs, each with a little collar under the apron.
local function diningTable(r: R, w: number, d: number)
	local h = 3.1
	r:block(-w / 2, h - 0.25, -d / 2, w / 2, h, d / 2, r.c1, "Wood")
	r:block(-w / 2 + 0.3, h - 0.6, -d / 2 + 0.3, w / 2 - 0.3, h - 0.25, d / 2 - 0.3, shade(r.c1, 0.85), "Wood")
	local lx, lz = w / 2 - 0.42, d / 2 - 0.42
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			r:box(sx * lx, (h - 0.25) / 2, sz * lz, 0.32, h - 0.25, 0.32, r.c2, "Wood")
			r:box(sx * lx, 2.05, sz * lz, 0.4, 0.14, 0.4, r.c2, "Wood")
		end
	end
end

-- A drawer front with a round knob, on the +z face at z.
local function drawer(r: R, x1: number, y1: number, x2: number, y2: number, z: number, color: Color3)
	r:block(x1, y1, z, x2, y2, z + 0.06, color, "Wood")
	r:ball((x1 + x2) / 2, (y1 + y2) / 2, z + 0.1, 0.16, C.Gold, "Metal")
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
		id = "table_coffee",
		name = "Coffee table",
		cat = "tables",
		price = 80,
		place = "floor",
		size = Vector3.new(4, 1.6, 2.4),
		surface = 1.6,
		c1 = "A8743F",
		c2 = "6B4423",
		tags = { "table" },
		build = function(r: R)
			r:block(-2, 1.35, -1.2, 2, 1.6, 1.2, r.c1, "Wood")
			r:block(-1.8, 1.15, -1.0, 1.8, 1.35, 1.0, r.c2, "Wood")
			r:legs(4, 2.4, 1.35, 0.25, 0.12, r.c2, "Wood")
			r:block(-1.75, 0.3, -0.95, 1.75, 0.42, 0.95, r.c1, "WoodPlanks")
			-- a couple of magazines on the shelf
			r:block(0.35, 0.42, -0.45, 1.25, 0.5, 0.25, C.Paper, "SmoothPlastic")
			r:block(0.45, 0.5, -0.4, 1.2, 0.56, 0.2, C.Blue, "SmoothPlastic")
		end,
	},
	{
		id = "table_dining_small",
		name = "Small dining table",
		cat = "tables",
		price = 120,
		place = "floor",
		size = Vector3.new(3.6, 3.1, 3.6),
		surface = 3.1,
		c1 = "C99A62",
		c2 = "A8743F",
		tags = { "table" },
		build = function(r: R)
			diningTable(r, 3.6, 3.6)
		end,
	},
	{
		id = "table_dining_long",
		name = "Long dining table",
		cat = "tables",
		price = 200,
		place = "floor",
		size = Vector3.new(7.2, 3.15, 3.6),
		surface = 3.1,
		c1 = "8A5A2E",
		c2 = "6B4423",
		tags = { "table" },
		build = function(r: R)
			diningTable(r, 7.2, 3.6)
			-- a cloth runner down the middle
			r:block(-3.0, 3.1, -0.5, 3.0, 3.14, 0.5, C.Cream, "Fabric")
		end,
	},
	{
		id = "table_round",
		name = "Round table",
		cat = "tables",
		price = 140,
		place = "floor",
		size = Vector3.new(3.6, 3.1, 3.6),
		surface = 3.1,
		c1 = "F7F3EA",
		c2 = "A8743F",
		tags = { "table" },
		build = function(r: R)
			r:cyl(0, 2.975, 0, 0.25, 3.6, "y", r.c1, "Wood")
			r:cyl(0, 2.75, 0, 0.2, 2.6, "y", r.c2, "Wood")
			r:cyl(0, 1.55, 0, 2.3, 0.6, "y", r.c2, "Wood")
			r:cyl(0, 0.45, 0, 0.3, 1.0, "y", r.c2, "Wood")
			-- four feet in a cross
			r:block(-1.3, 0, -0.22, 1.3, 0.3, 0.22, r.c2, "Wood")
			r:block(-0.22, 0, -1.3, 0.22, 0.3, 1.3, r.c2, "Wood")
		end,
	},
	{
		id = "table_side",
		name = "Side table",
		cat = "tables",
		price = 60,
		place = "floor",
		size = Vector3.new(1.8, 2.4, 1.8),
		surface = 2.4,
		c1 = "F7F3EA",
		c2 = "8FB39A",
		tags = { "table" },
		build = function(r: R)
			r:block(-0.9, 2.2, -0.9, 0.9, 2.4, 0.9, r.c1, "Wood")
			r:block(-0.75, 1.6, -0.75, 0.75, 2.2, 0.75, shade(r.c1, 0.92), "Wood")
			drawer(r, -0.6, 1.68, 0.6, 2.12, 0.75, r.c2)
			r:legs(1.6, 1.6, 1.6, 0.18, 0.05, shade(r.c1, 0.92), "Wood")
			r:block(-0.7, 0.45, -0.7, 0.7, 0.57, 0.7, shade(r.c1, 0.92), "Wood")
		end,
	},
	{
		id = "nightstand",
		name = "Nightstand",
		cat = "tables",
		price = 70,
		place = "floor",
		size = Vector3.new(2, 2.4, 1.8),
		surface = 2.4,
		c1 = "F7F3EA",
		c2 = "C99A62",
		tags = { "table", "storage" },
		build = function(r: R)
			for _, sx in { -1, 1 } do
				for _, sz in { -1, 1 } do
					r:box(sx * 0.78, 0.15, sz * 0.68, 0.24, 0.3, 0.24, r.c2, "Wood")
				end
			end
			r:block(-0.95, 0.3, -0.85, 0.95, 2.25, 0.85, r.c1, "Wood")
			r:block(-1, 2.25, -0.9, 1, 2.4, 0.9, r.c2, "Wood")
			drawer(r, -0.8, 0.45, 0.8, 1.2, 0.85, shade(r.c1, 0.94))
			drawer(r, -0.8, 1.35, 0.8, 2.1, 0.85, shade(r.c1, 0.94))
		end,
	},
	{
		id = "desk",
		name = "Desk",
		cat = "tables",
		price = 150,
		place = "floor",
		size = Vector3.new(4.6, 3, 2.4),
		surface = 3,
		c1 = "C99A62",
		c2 = "F7F3EA",
		tags = { "desk", "table" },
		build = function(r: R)
			r:block(-2.3, 2.8, -1.2, 2.3, 3.0, 1.2, r.c1, "Wood")
			-- drawers on the right
			r:block(0.9, 0, -1.1, 2.2, 2.8, 1.1, r.c2, "Wood")
			for _, y in { { 0.15, 0.95 }, { 1.05, 1.8 }, { 1.9, 2.65 } } do
				drawer(r, 1.02, y[1], 2.08, y[2], 1.1, shade(r.c2, 0.92))
			end
			-- legs on the left and a panel at the back
			for _, z in { -0.95, 0.95 } do
				r:box(-2.0, 1.4, z, 0.26, 2.8, 0.26, r.c2, "Wood")
			end
			r:block(-1.95, 1.5, -1.05, 0.9, 2.8, -0.9, r.c2, "Wood")
		end,
	},
	{
		id = "workbench",
		name = "Work bench",
		cat = "tables",
		price = 180,
		place = "floor",
		size = Vector3.new(5, 5.2, 2.4),
		surface = 3.2,
		c1 = "C99A62",
		c2 = "8A5A2E",
		tags = { "table" },
		build = function(r: R)
			r:block(-2.5, 2.8, -1.2, 2.5, 3.2, 1.2, r.c1, "Wood")
			for _, sx in { -1, 1 } do
				for _, sz in { -1, 1 } do
					r:box(sx * 2.15, 1.4, sz * 0.9, 0.4, 2.8, 0.4, r.c2, "Wood")
				end
			end
			r:block(-2.0, 0.5, -0.9, 2.0, 0.7, 0.9, r.c1, "WoodPlanks")
			r:block(-1.8, 0.7, -0.6, -0.7, 1.45, 0.45, Color3.fromRGB(196, 160, 112), "Wood")
			-- a pegboard with tools at the back
			r:block(-2.4, 3.2, -1.2, 2.4, 5.2, -1.0, r.c2, "Wood")
			r:block(-1.62, 3.6, -1.0, -1.48, 4.6, -0.9, C.Bark, "Wood")
			r:block(-1.85, 4.45, -1.0, -1.25, 4.75, -0.86, C.DarkMetal, "Metal")
			r:block(-0.7, 3.75, -1.0, 0.5, 4.35, -0.95, C.Metal, "Metal")
			r:block(0.5, 3.75, -1.0, 0.95, 4.4, -0.88, C.Red, "SmoothPlastic")
			r:block(1.55, 3.6, -1.0, 1.7, 4.4, -0.92, C.Metal, "Metal")
			r:block(1.45, 4.4, -1.0, 1.8, 4.7, -0.92, C.Metal, "Metal")
			-- a vice on the front corner
			r:block(1.6, 3.2, 0.65, 2.2, 3.6, 1.05, C.DarkMetal, "Metal")
			r:block(1.5, 3.32, 1.05, 2.3, 3.44, 1.17, C.Metal, "Metal")
		end,
	},
}

return items
