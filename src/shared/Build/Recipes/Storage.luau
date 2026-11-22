--!strict
-- Shelves, dressers, wardrobes and other places to keep things.
-- c1 is the body, c2 the fronts, a top or the things kept inside.

local Recipe = require(script.Parent.Parent.Recipe)
local Colors = require(script.Parent.Parent.Parent.Util.Colors)

local C = Recipe.Colors

type R = Recipe.Recipe

local function shade(c: Color3, k: number): Color3
	return Colors.shade(c, k)
end

local BOOK_COLOURS = {
	C.Red,
	C.Blue,
	Color3.fromRGB(143, 179, 154),
	C.Yellow,
	Color3.fromRGB(142, 91, 122),
	C.Cream,
	Color3.fromRGB(217, 128, 95),
	Color3.fromRGB(62, 110, 88),
}

-- A row of standing books from x1 to x2 on a shelf at y, at most maxH tall. `seed` varies the row.
local function books(r: R, x1: number, x2: number, y: number, maxH: number, seed: number)
	local s = seed
	local function rand(): number
		s = (s * 1103515245 + 12345) % 2147483648
		return s / 2147483648
	end
	local x = x1
	while x < x2 - 0.2 do
		local w = math.min(0.28 + rand() * 0.2, x2 - x)
		local h = maxH * (0.72 + rand() * 0.28)
		local col = BOOK_COLOURS[1 + math.floor(rand() * #BOOK_COLOURS)]
		r:block(x, y, -0.55, x + w - 0.03, y + h, 0.45, col, "SmoothPlastic")
		x += w
	end
end

-- A drawer front with knobs (one in the middle, or two when it is wide).
local function drawer(r: R, x1: number, y1: number, x2: number, y2: number, z: number, color: Color3)
	r:block(x1, y1, z, x2, y2, z + 0.06, color, "Wood")
	local ym = (y1 + y2) / 2
	if x2 - x1 > 2 then
		r:ball(x1 + (x2 - x1) * 0.25, ym, z + 0.1, 0.18, C.Gold, "Metal")
		r:ball(x1 + (x2 - x1) * 0.75, ym, z + 0.1, 0.18, C.Gold, "Metal")
	else
		r:ball((x1 + x2) / 2, ym, z + 0.1, 0.18, C.Gold, "Metal")
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
		id = "bookshelf",
		name = "Bookshelf",
		cat = "storage",
		price = 120,
		place = "floor",
		size = Vector3.new(3.6, 6.4, 1.6),
		c1 = "A8743F",
		c2 = "D9805F",
		tags = { "books", "storage" },
		build = function(r: R)
			r:block(-1.8, 0, -0.8, -1.6, 6.15, 0.8, r.c1, "Wood")
			r:block(1.6, 0, -0.8, 1.8, 6.15, 0.8, r.c1, "Wood")
			r:block(-1.8, 6.15, -0.8, 1.8, 6.4, 0.8, shade(r.c1, 0.88), "Wood")
			r:block(-1.6, 0, -0.75, 1.6, 0.4, 0.8, shade(r.c1, 0.88), "Wood")
			r:block(-1.6, 0.4, -0.8, 1.6, 6.15, -0.7, shade(r.c1, 0.75), "Wood")
			for _, y in { 1.9, 3.35, 4.8 } do
				r:block(-1.6, y, -0.7, 1.6, y + 0.15, 0.75, r.c1, "Wood")
			end
			books(r, -1.55, 0.35, 0.4, 1.35, 3)
			r:block(0.55, 0.4, -0.55, 1.5, 1.15, 0.5, r.c2, "Fabric")
			books(r, -1.55, -0.1, 2.05, 1.25, 11)
			r:cyl(0.95, 2.4, 0, 0.7, 0.6, "y", Color3.fromRGB(196, 110, 80), "SmoothPlastic")
			r:ball(0.95, 3.0, 0, 0.75, C.Leaf, "Grass")
			books(r, -0.5, 1.55, 3.5, 1.3, 7)
			books(r, -1.55, 0.0, 4.95, 1.15, 5)
			r:block(0.5, 4.95, -0.5, 1.4, 5.15, 0.35, C.Blue, "SmoothPlastic")
			r:block(0.55, 5.15, -0.45, 1.35, 5.33, 0.3, C.Cream, "SmoothPlastic")
		end,
	},
	{
		id = "dresser",
		name = "Dresser",
		cat = "storage",
		price = 150,
		place = "floor",
		size = Vector3.new(4, 3.4, 1.8),
		surface = 3.4,
		c1 = "8FB39A",
		c2 = "C99A62",
		tags = { "storage" },
		build = function(r: R)
			for _, sx in { -1, 1 } do
				for _, sz in { -1, 1 } do
					r:cyl(sx * 1.7, 0.2, sz * 0.65, 0.4, 0.34, "y", r.c2, "Wood")
				end
			end
			r:block(-1.9, 0.4, -0.85, 1.9, 3.2, 0.85, r.c1, "Wood")
			r:block(-2, 3.2, -0.9, 2, 3.4, 0.9, r.c2, "Wood")
			local front = shade(r.c1, 1.08)
			drawer(r, -1.75, 0.55, 1.75, 1.35, 0.85, front)
			drawer(r, -1.75, 1.47, 1.75, 2.25, 0.85, front)
			drawer(r, -1.75, 2.37, -0.06, 3.05, 0.85, front)
			drawer(r, 0.06, 2.37, 1.75, 3.05, 0.85, front)
		end,
	},
	{
		id = "wardrobe",
		name = "Wardrobe",
		cat = "storage",
		price = 220,
		place = "floor",
		size = Vector3.new(4, 7.2, 2.2),
		c1 = "A8743F",
		c2 = "C99A62",
		tags = { "storage" },
		build = function(r: R)
			r:block(-2, 0, -1, 2, 0.4, 1, shade(r.c1, 0.85), "Wood")
			r:block(-1.9, 0.4, -0.95, 1.9, 6.8, 0.95, r.c1, "Wood")
			r:block(-2, 6.8, -1, 2, 7.0, 1.05, shade(r.c1, 0.85), "Wood")
			r:block(-1.9, 7.0, -0.95, 1.9, 7.2, 0.95, shade(r.c1, 0.85), "Wood")
			for _, sx in { -1, 1 } do
				local xa, xb = sx * 0.03, sx * 1.8
				local x1, x2 = math.min(xa, xb), math.max(xa, xb)
				local xm = (x1 + x2) / 2
				r:block(x1, 0.6, 0.95, x2, 6.6, 1.0, r.c2, "Wood")
				r:block(xm - 0.6, 3.9, 1.0, xm + 0.6, 6.2, 1.04, shade(r.c2, 0.9), "Wood")
				r:block(xm - 0.6, 1.0, 1.0, xm + 0.6, 3.5, 1.04, shade(r.c2, 0.9), "Wood")
				r:block(sx * 0.18 - 0.05, 3.4, 1.0, sx * 0.18 + 0.05, 4.1, 1.1, C.Gold, "Metal")
			end
		end,
	},
	{
		id = "cabinet",
		name = "Cabinet",
		cat = "storage",
		price = 140,
		place = "floor",
		size = Vector3.new(4.4, 2.8, 1.8),
		surface = 2.8,
		c1 = "5C7FA3",
		c2 = "C99A62",
		tags = { "storage" },
		build = function(r: R)
			for _, sx in { -1, 1 } do
				for _, sz in { -1, 1 } do
					r:beam(
						Vector3.new(sx * 1.85, 0.55, sz * 0.6),
						Vector3.new(sx * 1.98, 0, sz * 0.7),
						0.2,
						0.2,
						r.c2,
						"Wood"
					)
				end
			end
			r:block(-2.1, 0.5, -0.85, 2.1, 2.6, 0.85, r.c1, "Wood")
			r:block(-2.2, 2.6, -0.9, 2.2, 2.8, 0.9, r.c2, "Wood")
			local front = shade(r.c1, 1.1)
			-- two doors with two drawers between them
			for _, sx in { -1, 1 } do
				local xa, xb = sx * 0.72, sx * 1.98
				local x1, x2 = math.min(xa, xb), math.max(xa, xb)
				r:block(x1, 0.62, 0.85, x2, 2.48, 0.91, front, "Wood")
				r:block(sx * 0.9 - 0.05, 1.3, 0.91, sx * 0.9 + 0.05, 1.8, 0.98, C.Gold, "Metal")
			end
			drawer(r, -0.62, 0.62, 0.62, 1.5, 0.85, front)
			drawer(r, -0.62, 1.6, 0.62, 2.48, 0.85, front)
		end,
	},
	{
		id = "toy_chest",
		name = "Toy chest",
		cat = "storage",
		price = 90,
		place = "floor",
		size = Vector3.new(3.2, 2.4, 1.9),
		c1 = "7FB8D9",
		c2 = "F7F3EA",
		tags = { "toy", "storage" },
		build = function(r: R)
			r:block(-1.5, 0, -0.85, 1.5, 1.5, 0.85, r.c1, "Wood")
			r:block(-1.55, 1.5, -0.9, 1.55, 1.78, 0.9, shade(r.c1, 0.85), "Wood")
			-- a painted band near the top and a handle on each end
			r:block(-1.52, 1.22, -0.87, 1.52, 1.38, 0.87, r.c2, "Wood")
			r:block(-1.52, 0, -0.87, 1.52, 0.14, 0.87, r.c2, "Wood")
			for _, sx in { -1, 1 } do
				r:block(sx * 1.5 - 0.06, 0.85, -0.25, sx * 1.5 + 0.08, 1.0, 0.25, C.DarkMetal, "Metal")
			end
			-- letter blocks painted on the front
			local cols = { C.Red, C.Yellow, Color3.fromRGB(86, 160, 72) }
			for i, col in cols do
				local x = -0.9 + (i - 1) * 0.9
				r:block(x - 0.32, 0.45, 0.85, x + 0.32, 1.09, 0.9, col, "SmoothPlastic")
			end
			r:ball(0.8, 2.08, 0.1, 0.6, C.Red, "Plastic")
			r:block(-1.0, 1.78, -0.35, -0.5, 2.28, 0.15, C.Yellow, "Wood")
		end,
	},
	{
		id = "shelf_cubes",
		name = "Cube shelf",
		cat = "storage",
		price = 110,
		place = "floor",
		size = Vector3.new(3.4, 4.8, 1.5),
		surface = 4.8,
		c1 = "F7F3EA",
		c2 = "D9805F",
		tags = { "storage" },
		build = function(r: R)
			local t = 0.15
			-- outer box, a middle divider and two shelves: six cubbies
			r:block(-1.7, 0, -0.75, -1.7 + t, 4.8, 0.75, r.c1, "Wood")
			r:block(1.7 - t, 0, -0.75, 1.7, 4.8, 0.75, r.c1, "Wood")
			r:block(-1.7, 4.8 - t, -0.75, 1.7, 4.8, 0.75, r.c1, "Wood")
			r:block(-1.7, 0, -0.75, 1.7, 0.2, 0.75, r.c1, "Wood")
			r:block(-t / 2, 0.2, -0.75, t / 2, 4.65, 0.75, r.c1, "Wood")
			r:block(-1.55, 0.2, -0.75, 1.55, 4.65, -0.65, shade(r.c1, 0.85), "Wood")
			for _, y in { 1.68, 3.17 } do
				r:block(-1.55, y - t / 2, -0.65, 1.55, y + t / 2, 0.75, r.c1, "Wood")
			end
			-- fabric bins in two cubbies, books and a plant in others
			for _, p in { { -0.8, 0.2 }, { 0.8, 1.755 } } do
				local x, y = p[1], p[2]
				r:block(x - 0.62, y, -0.55, x + 0.62, y + 1.25, 0.65, r.c2, "Fabric")
				r:block(x - 0.25, y + 0.85, 0.65, x + 0.25, y + 1.0, 0.68, shade(r.c2, 0.6), "Fabric")
			end
			books(r, -1.5, -0.15, 1.755, 1.2, 9)
			books(r, 0.15, 1.5, 3.245, 1.15, 21)
			r:cyl(-0.8, 3.55, 0, 0.6, 0.6, "y", Color3.fromRGB(196, 110, 80), "SmoothPlastic")
			r:ball(-0.8, 4.05, 0, 0.7, C.Leaf, "Grass")
		end,
	},
	{
		id = "coat_stand",
		name = "Coat stand",
		cat = "storage",
		price = 50,
		place = "floor",
		size = Vector3.new(1.8, 6, 1.8),
		c1 = "6B4423",
		c2 = "C7383F",
		tags = { "storage" },
		build = function(r: R)
			r:cyl(0, 0.1, 0, 0.2, 1.4, "y", r.c1, "Wood")
			r:cyl(0, 0.25, 0, 0.1, 0.9, "y", shade(r.c1, 0.85), "Wood")
			r:cyl(0, 3.0, 0, 5.6, 0.24, "y", r.c1, "Wood")
			r:ball(0, 5.85, 0, 0.36, r.c1, "Wood")
			for i = 0, 3 do
				local a = i * math.pi / 2
				local dx, dz = math.cos(a), math.sin(a)
				r:beam(
					Vector3.new(dx * 0.1, 5.2, dz * 0.1),
					Vector3.new(dx * 0.55, 5.55, dz * 0.55),
					0.1,
					0.1,
					r.c1,
					"Wood"
				)
				r:ball(dx * 0.57, 5.58, dz * 0.57, 0.14, r.c1, "Wood")
			end
			-- a coat on one hook, a scarf and a hat on others
			r:block(0.14, 3.3, -0.42, 0.52, 5.0, 0.42, r.c2, "Fabric")
			r:cyl(0.33, 5.0, 0, 0.84, 0.38, "z", r.c2, "Fabric")
			for _, sz in { -1, 1 } do
				r:block(0.18, 3.75, sz * 0.42, 0.48, 5.0, sz * 0.6, shade(r.c2, 0.85), "Fabric")
			end
			for _, y in { 4.5, 4.0 } do
				r:ball(0.53, y, 0, 0.1, C.Gold, "Metal")
			end
			r:block(-0.16, 4.1, 0.5, 0.16, 5.45, 0.62, C.Yellow, "Fabric")
			r:cyl(-0.55, 5.45, 0, 0.06, 0.8, "y", C.Bark, "Fabric")
			r:cyl(-0.55, 5.62, 0, 0.32, 0.5, "y", C.Bark, "Fabric")
		end,
	},
}

return items
