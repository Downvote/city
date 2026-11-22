--!strict
-- Bathroom things. c1 is the main body (porcelain, cabinet or tiles), c2 a trim or fabric.

local Recipe = require(script.Parent.Parent.Recipe)
local Colors = require(script.Parent.Parent.Parent.Util.Colors)

local C = Recipe.Colors

type R = Recipe.Recipe

local function shade(c: Color3, k: number): Color3
	return Colors.shade(c, k)
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
		id = "toilet",
		name = "Toilet",
		cat = "bath",
		price = 150,
		place = "floor",
		size = Vector3.new(1.8, 3.2, 2.8),
		c1 = "F7F3EA",
		c2 = "C9DCE6",
		tags = { "bath" },
		build = function(r: R)
			r:block(-0.5, 0, -1.1, 0.5, 0.2, 0.5, r.c1, "SmoothPlastic")
			r:block(-0.4, 0.2, -1.0, 0.4, 1.0, 0.4, r.c1, "SmoothPlastic")
			r:block(-0.65, 0.9, -0.95, 0.65, 1.42, 0.2, r.c1, "SmoothPlastic")
			r:cyl(0, 1.16, 0.25, 0.52, 1.3, "y", r.c1, "SmoothPlastic")
			-- the seat and its lid
			r:block(-0.72, 1.42, -0.85, 0.72, 1.54, 0.25, r.c2, "SmoothPlastic")
			r:cyl(0, 1.48, 0.28, 0.12, 1.44, "y", r.c2, "SmoothPlastic")
			-- the tank
			r:block(-0.8, 1.5, -1.4, 0.8, 3.0, -0.88, r.c1, "SmoothPlastic")
			r:block(-0.85, 3.0, -1.42, 0.85, 3.15, -0.82, shade(r.c1, 0.95), "SmoothPlastic")
			r:block(-0.65, 2.7, -0.88, -0.35, 2.8, -0.72, C.Metal, "Metal")
			r:seat(0, 1.54, -0.1)
		end,
	},
	{
		id = "bathtub",
		name = "Bathtub",
		cat = "bath",
		price = 300,
		place = "floor",
		size = Vector3.new(3.4, 2.9, 6.2),
		c1 = "F7F3EA",
		c2 = "DEB252",
		tags = { "bath" },
		build = function(r: R)
			for _, sx in { -1, 1 } do
				for _, sz in { -1, 1 } do
					r:ball(sx * 1.15, 0.22, sz * 2.3, 0.44, r.c2, "Metal")
				end
			end
			-- a deep tub, rounded underneath at both ends
			r:block(-1.6, 0.9, -2.95, 1.6, 2.1, 2.95, r.c1, "SmoothPlastic")
			r:block(-1.6, 0.4, -2.45, 1.6, 0.9, 2.45, r.c1, "SmoothPlastic")
			for _, sz in { -1, 1 } do
				r:cyl(0, 0.9, sz * 2.45, 3.2, 1.0, "x", r.c1, "SmoothPlastic")
			end
			-- a rolled rim round the water
			for _, sx in { -1, 1 } do
				r:block(sx * 1.55 - 0.15, 2.1, -3.05, sx * 1.55 + 0.15, 2.32, 3.05, shade(r.c1, 0.97), "SmoothPlastic")
			end
			for _, sz in { -1, 1 } do
				r:block(-1.4, 2.1, sz * 2.9 - 0.15, 1.4, 2.32, sz * 2.9 + 0.15, shade(r.c1, 0.97), "SmoothPlastic")
			end
			local water = r:block(-1.4, 2.08, -2.75, 1.4, 2.2, 2.75, C.Water, "Glass")
			water.transp = 0.2
			for _, p in { { -0.8, 1.8, 0.5 }, { -0.4, 2.1, 0.35 }, { 0.6, -1.9, 0.45 } } do
				r:ball(p[1], 2.22, p[2], p[3], C.White, "SmoothPlastic")
			end
			-- a rubber duck
			r:ball(0.5, 2.35, 0.8, 0.45, C.Yellow, "Plastic")
			r:ball(0.5, 2.62, 0.95, 0.3, C.Yellow, "Plastic")
			r:block(0.44, 2.58, 1.08, 0.56, 2.64, 1.2, Color3.fromRGB(240, 140, 50), "Plastic")
			-- the tap at the back end
			r:cyl(0, 2.55, -2.95, 0.5, 0.16, "y", r.c2, "Metal")
			r:beam(Vector3.new(0, 2.75, -2.95), Vector3.new(0, 2.7, -2.5), 0.14, 0.14, r.c2, "Metal")
			for _, x in { -0.35, 0.35 } do
				r:ball(x, 2.45, -2.95, 0.2, r.c2, "Metal")
			end
		end,
	},
	{
		id = "shower",
		name = "Shower",
		cat = "bath",
		price = 350,
		place = "floor",
		size = Vector3.new(3.6, 7.6, 3.6),
		c1 = "BFE0E8",
		c2 = "C9CCD3",
		tags = { "bath" },
		build = function(r: R)
			r:block(-1.8, 0, -1.8, 1.8, 0.3, 1.8, C.White, "SmoothPlastic")
			r:cyl(0.3, 0.31, 0.3, 0.02, 0.3, "y", C.DarkMetal, "Metal")
			-- tiled walls at the back and on the left
			r:block(-1.8, 0.3, -1.8, 1.8, 7.6, -1.6, r.c1, "CeramicTiles")
			r:block(-1.8, 0.3, -1.6, -1.6, 7.6, 1.8, r.c1, "CeramicTiles")
			-- glass on the other two sides, in a metal frame
			r:glass(-1.6, 0.3, 1.68, 1.68, 7.3, 1.76)
			r:glass(1.68, 0.3, -1.6, 1.76, 7.3, 1.68)
			r:block(-1.6, 7.3, 1.64, 1.8, 7.45, 1.8, r.c2, "Metal")
			r:block(1.64, 7.3, -1.6, 1.8, 7.45, 1.64, r.c2, "Metal")
			r:block(1.64, 0.3, 1.64, 1.8, 7.3, 1.8, r.c2, "Metal")
			r:block(0.5, 3.2, 1.76, 0.6, 4.4, 1.86, r.c2, "Metal")
			-- shower head, pipe and tap
			r:cyl(0, 5.6, -1.53, 2.4, 0.14, "y", r.c2, "Metal")
			r:beam(Vector3.new(0, 6.75, -1.53), Vector3.new(0, 6.75, -0.95), 0.14, 0.14, r.c2, "Metal")
			r:cyl(0, 6.62, -0.9, 0.12, 0.7, "y", r.c2, "Metal")
			r:cyl(0, 3.9, -1.55, 0.15, 0.4, "z", r.c2, "Metal")
			-- a little shelf with two bottles
			r:block(-1.6, 3.6, -1.6, -1.0, 3.7, -1.0, C.White, "SmoothPlastic")
			r:cyl(-1.4, 3.95, -1.35, 0.5, 0.24, "y", C.Pink, "SmoothPlastic")
			r:cyl(-1.15, 3.9, -1.4, 0.4, 0.22, "y", Color3.fromRGB(143, 179, 154), "SmoothPlastic")
		end,
	},
	{
		id = "sink_vanity",
		name = "Sink vanity",
		cat = "bath",
		price = 180,
		place = "floor",
		size = Vector3.new(3, 4, 2),
		surface = 3.1,
		c1 = "7A9CC6",
		c2 = "F2EFE8",
		tags = { "bath" },
		build = function(r: R)
			for _, sx in { -1, 1 } do
				for _, sz in { -1, 1 } do
					r:box(sx * 1.3, 0.15, sz * 0.75, 0.25, 0.3, 0.25, shade(r.c1, 0.7), "Wood")
				end
			end
			r:block(-1.45, 0.3, -0.95, 1.45, 2.9, 0.88, r.c1, "Wood")
			for _, sx in { -1, 1 } do
				local xa, xb = sx * 0.04, sx * 1.35
				r:block(math.min(xa, xb), 0.42, 0.88, math.max(xa, xb), 2.78, 0.94, shade(r.c1, 1.08), "Wood")
				r:ball(sx * 0.22, 2.3, 0.98, 0.16, C.Gold, "Metal")
			end
			r:block(-1.5, 2.9, -1.0, 1.5, 3.1, 1.0, r.c2, "Marble")
			-- a round bowl sitting on the top
			r:cyl(0, 3.32, 0.1, 0.44, 1.4, "y", C.White, "SmoothPlastic")
			r:cyl(0, 3.54, 0.1, 0.02, 1.15, "y", Color3.fromRGB(214, 222, 226), "SmoothPlastic")
			r:cyl(0, 3.45, -0.75, 0.7, 0.16, "y", C.Metal, "Metal")
			r:beam(Vector3.new(0, 3.82, -0.75), Vector3.new(0, 3.82, -0.25), 0.13, 0.13, C.Metal, "Metal")
			r:cyl(0, 3.7, -0.25, 0.15, 0.13, "y", C.Metal, "Metal")
			r:ball(0.35, 3.2, -0.75, 0.18, C.Metal, "Metal")
		end,
	},
	{
		id = "towel_rail",
		name = "Towel rail",
		cat = "bath",
		price = 40,
		place = "floor",
		size = Vector3.new(2.4, 3.6, 1),
		c1 = "C99A62",
		c2 = "E8A0A8",
		tags = { "bath" },
		build = function(r: R)
			for _, sx in { -1, 1 } do
				local x = sx * 1.05
				r:block(x - 0.12, 0, -0.45, x + 0.12, 0.15, 0.45, r.c1, "Wood")
				r:cyl(x, 1.75, 0, 3.3, 0.18, "y", r.c1, "Wood")
				r:ball(x, 3.45, 0, 0.26, r.c1, "Wood")
			end
			for _, y in { 3.3, 2.1 } do
				r:cyl(0, y, 0, 2.1, 0.12, "x", r.c1, "Wood")
			end
			-- a big towel over the top bar and a small one lower down
			r:block(-0.75, 1.75, 0.07, 0.75, 3.3, 0.14, r.c2, "Fabric")
			r:block(-0.75, 2.4, -0.14, 0.75, 3.3, -0.07, r.c2, "Fabric")
			r:cyl(0, 3.3, 0, 1.5, 0.28, "x", r.c2, "Fabric")
			r:block(-0.76, 1.95, 0.13, 0.76, 2.1, 0.15, C.White, "Fabric")
			local small = Colors.mix(r.c2, C.White, 0.5)
			r:block(-0.85, 1.2, 0.07, -0.15, 2.1, 0.13, small, "Fabric")
			r:cyl(-0.5, 2.1, 0, 0.7, 0.24, "x", small, "Fabric")
		end,
	},
	{
		id = "washing_machine",
		name = "Washing machine",
		cat = "bath",
		price = 260,
		place = "floor",
		size = Vector3.new(2.6, 3.2, 2.6),
		surface = 3.2,
		c1 = "F7F3EA",
		c2 = "C9CCD3",
		tags = { "bath" },
		build = function(r: R)
			for _, sx in { -1, 1 } do
				for _, sz in { -1, 1 } do
					r:box(sx * 1.1, 0.05, sz * 1.0, 0.25, 0.1, 0.25, C.DarkMetal, "Rubber")
				end
			end
			r:block(-1.3, 0.1, -1.3, 1.3, 3.2, 1.2, r.c1, "Metal")
			r:block(-1.3, 2.55, 1.2, 1.3, 3.2, 1.24, shade(r.c1, 0.92), "Metal")
			r:cyl(0.75, 2.88, 1.28, 0.1, 0.4, "z", r.c2, "Metal")
			r:block(-1.0, 2.75, 1.24, -0.2, 3.0, 1.26, Color3.fromRGB(120, 200, 140), "Neon")
			-- the round door, with washing inside
			r:cyl(0, 1.35, 1.25, 0.12, 1.7, "z", r.c2, "Metal")
			r:cyl(0, 1.35, 1.3, 0.06, 1.3, "z", Color3.fromRGB(70, 96, 112), "Glass")
			r:cyl(0.1, 1.1, 1.31, 0.03, 0.6, "z", C.Pink, "Fabric")
			r:cyl(-0.2, 1.25, 1.32, 0.03, 0.4, "z", C.Yellow, "Fabric")
			r:block(0.75, 1.15, 1.3, 0.85, 1.55, 1.38, shade(r.c2, 0.8), "Metal")
		end,
	},
	{
		id = "laundry_basket",
		name = "Laundry basket",
		cat = "bath",
		price = 30,
		place = "floor",
		size = Vector3.new(1.6, 1.8, 1.2),
		c1 = "D9B57E",
		c2 = "7A9CC6",
		tags = { "bath" },
		build = function(r: R)
			r:block(-0.72, 0, -0.52, 0.72, 1.2, 0.52, r.c1, "WoodPlanks")
			r:block(-0.8, 1.2, -0.6, 0.8, 1.38, 0.6, shade(r.c1, 0.85), "WoodPlanks")
			for _, sx in { -1, 1 } do
				r:block(sx * 0.8 - 0.03, 1.0, -0.2, sx * 0.8 + 0.03, 1.12, 0.2, shade(r.c1, 0.6), "Wood")
			end
			-- clothes heaped over the top
			r:ball(-0.3, 1.18, 0.0, 0.8, r.c2, "Fabric")
			r:ball(0.3, 1.2, -0.1, 0.7, C.White, "Fabric")
			r:ball(0.12, 1.28, 0.22, 0.55, C.Pink, "Fabric")
			-- a sleeve hanging over the front
			r:block(0.3, 1.38, 0.3, 0.55, 1.46, 0.67, r.c2, "Fabric")
			r:block(0.3, 0.85, 0.6, 0.55, 1.46, 0.67, r.c2, "Fabric")
		end,
	},
}

return items
