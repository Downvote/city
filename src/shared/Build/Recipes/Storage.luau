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
	Color3.fromRGB(176, 68, 62),
	Color3.fromRGB(70, 110, 150),
	Color3.fromRGB(143, 179, 154),
	Color3.fromRGB(232, 190, 92),
	Color3.fromRGB(142, 91, 122),
	C.Cream,
	Color3.fromRGB(217, 128, 95),
	Color3.fromRGB(62, 110, 88),
	Color3.fromRGB(60, 62, 72),
}

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
		mat = mat or "SmoothPlastic",
	})
end

-- A row of standing books from x1 to x2 on a shelf at y, at most maxH tall, front edge at zf.
-- `seed` varies the row.
local function books(r: R, x1: number, x2: number, y: number, maxH: number, zf: number, seed: number)
	local s = seed
	local function rand(): number
		s = (s * 1103515245 + 12345) % 2147483648
		return s / 2147483648
	end
	local x = x1
	while x < x2 - 0.2 do
		local w = math.min(0.22 + rand() * 0.2, x2 - x)
		local h = maxH * (0.7 + rand() * 0.3)
		local col = BOOK_COLOURS[1 + math.floor(rand() * #BOOK_COLOURS)]
		r:block(x, y, zf - 1.0 + rand() * 0.1, x + w - 0.03, y + h, zf - rand() * 0.08, col, "SmoothPlastic")
		x += w
	end
end

-- A potted plant: a pot on the shelf at (x, y, z) with a leafy top.
local function pottedPlant(r: R, x: number, y: number, z: number, size: number)
	r:cyl(x, y + size * 0.3, z, size * 0.6, size * 0.62, "y", Color3.fromRGB(226, 220, 208), "SmoothPlastic")
	r:ball(x, y + size * 0.85, z, size * 0.8, C.Leaf, "Grass")
	r:ball(x + size * 0.2, y + size * 1.05, z - size * 0.1, size * 0.5, C.DarkLeaf, "Grass")
end

-- A drawer front with a bar pull (two pulls on a wide one), on the +z face at z.
local function drawer(r: R, x1: number, y1: number, x2: number, y2: number, z: number, color: Color3)
	r:block(x1, y1, z, x2, y2, z + 0.06, color, "Wood")
	local ym = (y1 + y2) / 2
	local pulls: { number } = { (x1 + x2) / 2 }
	if x2 - x1 > 2.4 then
		pulls = { x1 + (x2 - x1) * 0.25, x1 + (x2 - x1) * 0.75 }
	end
	for _, xm in pulls do
		r:block(xm - 0.3, ym - 0.04, z + 0.06, xm + 0.3, ym + 0.04, z + 0.13, C.Gold, "Metal")
	end
end

-- A shaker door: a flat door with a darker inset panel and a long bar handle on one side.
local function door(r: R, x1: number, y1: number, x2: number, y2: number, z: number, color: Color3, handleX: number)
	r:block(x1, y1, z, x2, y2, z + 0.06, color, "Wood")
	r:block(x1 + 0.22, y1 + 0.25, z + 0.06, x2 - 0.22, y2 - 0.25, z + 0.07, shade(color, 0.9), "Wood")
	local hl = math.min(1.2, (y2 - y1) * 0.3)
	local ym = (y1 + y2) / 2
	r:block(handleX - 0.04, ym - hl / 2, z + 0.1, handleX + 0.04, ym + hl / 2, z + 0.15, C.Gold, "Metal")
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
		c2 = "D9C7A7",
		tags = { "books", "storage" },
		build = function(r: R)
			local dk = shade(r.c1, 0.85)
			r:block(-1.8, 0, -0.8, -1.62, 6.15, 0.75, r.c1, "Wood")
			r:block(1.62, 0, -0.8, 1.8, 6.15, 0.75, r.c1, "Wood")
			-- a crown on top and a kick board at the bottom
			r:block(-1.8, 6.05, -0.8, 1.8, 6.25, 0.75, r.c1, "Wood")
			r:block(-1.86, 6.25, -0.8, 1.86, 6.4, 0.8, dk, "Wood")
			r:block(-1.62, 0, -0.7, 1.62, 0.42, 0.7, dk, "Wood")
			r:block(-1.62, 0.42, -0.8, 1.62, 6.05, -0.7, shade(r.c1, 0.7), "Wood")
			for _, y in { 0.42, 1.88, 3.33, 4.78 } do
				r:block(-1.62, y, -0.7, 1.62, y + 0.14, 0.72, r.c1, "Wood")
			end
			-- two fabric bins at the bottom
			for _, x in { -0.8, 0.8 } do
				r:block(x - 0.72, 0.56, -0.55, x + 0.72, 1.62, 0.62, r.c2, "Fabric")
				r:block(x - 0.25, 1.3, 0.62, x + 0.25, 1.42, 0.64, shade(r.c2, 0.6), "Fabric")
			end
			books(r, -1.55, 0.45, 2.02, 1.25, 0.65, 11)
			pottedPlant(r, 1.0, 2.02, 0.05, 0.9)
			books(r, -0.4, 1.55, 3.47, 1.25, 0.65, 7)
			-- a small framed photo standing on a shelf
			r:boxAt(
				CFrame.new(-1.0, 3.95, 0.1) * CFrame.Angles(-0.15, 0.2, 0),
				0.8,
				0.95,
				0.08,
				C.Black,
				"SmoothPlastic"
			)
			r:boxAt(
				CFrame.new(-1.0, 3.95, 0.15) * CFrame.Angles(-0.15, 0.2, 0),
				0.62,
				0.77,
				0.02,
				C.Paper,
				"SmoothPlastic"
			)
			books(r, -1.55, 0.1, 4.92, 1.1, 0.65, 5)
			r:block(0.4, 4.92, -0.45, 1.45, 5.1, 0.4, Color3.fromRGB(70, 110, 150), "SmoothPlastic")
			r:block(0.45, 5.1, -0.4, 1.4, 5.27, 0.35, C.Cream, "SmoothPlastic")
			r:cyl(0.92, 5.42, 0, 0.3, 0.36, "y", Color3.fromRGB(217, 128, 95), "SmoothPlastic")
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
					rod(
						r,
						Vector3.new(sx * 1.65, 0.6, sz * 0.62),
						Vector3.new(sx * 1.72, 0, sz * 0.68),
						0.18,
						r.c2,
						"Wood"
					)
				end
			end
			r:block(-1.88, 0.56, -0.82, 1.88, 3.22, 0.82, r.c1, "Wood")
			r:block(-2, 3.22, -0.9, 2, 3.4, 0.9, r.c2, "Wood")
			r:block(-1.92, 0.5, -0.84, 1.92, 0.58, 0.84, shade(r.c2, 0.85), "Wood")
			-- three rows of drawers, two to a row
			local front = shade(r.c1, 1.06)
			for _, y in { { 0.66, 1.46 }, { 1.54, 2.3 }, { 2.38, 3.12 } } do
				drawer(r, -1.78, y[1], -0.04, y[2], 0.82, front)
				drawer(r, 0.04, y[1], 1.78, y[2], 0.82, front)
			end
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
			local dk = shade(r.c1, 0.85)
			r:block(-1.9, 0, -0.95, 1.9, 0.4, 0.9, dk, "Wood")
			r:block(-1.92, 0.4, -1.0, 1.92, 6.8, 0.98, r.c1, "Wood")
			-- a stepped crown
			r:block(-1.98, 6.8, -1.04, 1.98, 6.98, 1.04, r.c1, "Wood")
			r:block(-2, 6.98, -1.08, 2, 7.2, 1.1, dk, "Wood")
			-- two tall shaker doors over a wide drawer
			door(r, -1.82, 1.6, -0.03, 6.7, 0.98, r.c2, -0.2)
			door(r, 0.03, 1.6, 1.82, 6.7, 0.98, r.c2, 0.2)
			drawer(r, -1.82, 0.5, 1.82, 1.5, 0.98, r.c2)
		end,
	},
	{
		id = "cabinet",
		name = "Sideboard",
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
					rod(
						r,
						Vector3.new(sx * 1.85, 0.62, sz * 0.6),
						Vector3.new(sx * 1.98, 0, sz * 0.7),
						0.18,
						r.c2,
						"Wood"
					)
				end
			end
			r:block(-2.1, 0.55, -0.85, 2.1, 2.62, 0.85, r.c1, "Wood")
			r:block(-2.2, 2.62, -0.9, 2.2, 2.8, 0.9, r.c2, "Wood")
			r:block(-2.12, 0.5, -0.86, 2.12, 0.58, 0.86, shade(r.c2, 0.85), "Wood")
			-- two fluted doors with a pair of drawers between them
			local front = shade(r.c1, 1.08)
			for _, sx in { -1, 1 } do
				local xa, xb = sx * 0.72, sx * 2.0
				local x1, x2 = math.min(xa, xb), math.max(xa, xb)
				r:block(x1, 0.66, 0.85, x2, 2.52, 0.91, front, "Wood")
				for k = 1, 4 do
					local x = x1 + k * (x2 - x1) / 5
					r:block(x - 0.025, 0.76, 0.91, x + 0.025, 2.42, 0.93, shade(front, 0.82), "Wood")
				end
				r:cyl(sx * 0.88, 1.6, 0.96, 0.1, 0.16, "z", C.Gold, "Metal")
			end
			drawer(r, -0.62, 0.66, 0.62, 1.55, 0.85, front)
			drawer(r, -0.62, 1.63, 0.62, 2.52, 0.85, front)
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
			r:block(-1.5, 0.12, -0.85, 1.5, 1.5, 0.85, r.c1, "Wood")
			r:block(-1.52, 0, -0.87, 1.52, 0.14, 0.87, r.c2, "Wood")
			-- a lid with a rounded front edge and a painted band under it
			r:block(-1.56, 1.5, -0.9, 1.56, 1.74, 0.78, shade(r.c1, 0.88), "Wood")
			r:cyl(0, 1.62, 0.78, 3.12, 0.24, "x", shade(r.c1, 0.88), "Wood")
			r:block(-1.52, 1.22, -0.87, 1.52, 1.38, 0.87, r.c2, "Wood")
			-- rope handles on the ends
			for _, sx in { -1, 1 } do
				for _, z in { -0.28, 0.28 } do
					r:block(sx * 1.5 - 0.02 * sx, 0.95, z - 0.05, sx * 1.58, 1.08, z + 0.05, C.DarkMetal, "Metal")
				end
				r:cyl(sx * 1.57, 0.92, 0, 0.62, 0.1, "z", C.Cream, "Fabric")
			end
			-- letter blocks painted on the front
			local cols = { C.Red, C.Yellow, Color3.fromRGB(86, 160, 72) }
			for i, col in cols do
				local x = -0.9 + (i - 1) * 0.9
				r:block(x - 0.32, 0.4, 0.85, x + 0.32, 1.04, 0.9, col, "SmoothPlastic")
				r:block(x - 0.12, 0.6, 0.9, x + 0.12, 0.84, 0.92, C.White, "SmoothPlastic")
			end
			-- a ball and a block left on the lid
			r:ball(0.8, 2.04, 0.1, 0.6, C.Red, "Plastic")
			r:block(-1.0, 1.74, -0.35, -0.5, 2.24, 0.15, C.Yellow, "Wood")
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
			-- fabric bins with a finger hole, books and a plant in others
			for _, p in { { -0.8, 0.2 }, { 0.8, 1.755 }, { 0.8, 0.2 } } do
				local x, y = p[1], p[2]
				local col = if p[2] > 1 then Colors.mix(r.c2, C.Cream, 0.4) else r.c2
				r:block(x - 0.64, y + 0.02, -0.55, x + 0.64, y + 1.3, 0.66, col, "Fabric")
				r:block(x - 0.25, y + 0.95, 0.66, x + 0.25, y + 1.1, 0.68, shade(col, 0.55), "Fabric")
			end
			books(r, -1.5, -0.15, 1.755, 1.2, 0.68, 9)
			books(r, 0.15, 1.5, 3.245, 1.15, 0.68, 21)
			pottedPlant(r, -0.8, 3.245, 0, 0.85)
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
			-- three splayed feet round a turned pole
			for i = 0, 2 do
				local a = i * math.pi * 2 / 3 + math.pi / 2
				local dx, dz = math.cos(a), math.sin(a)
				rod(
					r,
					Vector3.new(dx * 0.08, 1.0, dz * 0.08),
					Vector3.new(dx * 0.78, 0.04, dz * 0.78),
					0.14,
					r.c1,
					"Wood"
				)
				r:cyl(dx * 0.78, 0.04, dz * 0.78, 0.08, 0.2, "y", shade(r.c1, 0.7), "Wood")
			end
			r:cyl(0, 3.1, 0, 5.4, 0.22, "y", r.c1, "Wood")
			r:cyl(0, 1.0, 0, 0.2, 0.34, "y", shade(r.c1, 0.85), "Wood")
			r:ball(0, 5.85, 0, 0.32, r.c1, "Wood")
			for i = 0, 3 do
				local a = i * math.pi / 2
				local dx, dz = math.cos(a), math.sin(a)
				rod(
					r,
					Vector3.new(dx * 0.08, 5.15, dz * 0.08),
					Vector3.new(dx * 0.52, 5.55, dz * 0.52),
					0.09,
					r.c1,
					"Wood"
				)
				r:ball(dx * 0.54, 5.57, dz * 0.54, 0.14, C.Gold, "Metal")
			end
			-- a coat on one hook, a scarf on another and a hat on top of one
			r:block(0.14, 3.3, -0.42, 0.52, 5.0, 0.42, r.c2, "Fabric")
			r:cyl(0.33, 5.0, 0, 0.84, 0.38, "z", r.c2, "Fabric")
			for _, sz in { -1, 1 } do
				r:block(0.18, 3.75, sz * 0.42, 0.48, 5.0, sz * 0.6, shade(r.c2, 0.85), "Fabric")
			end
			for _, y in { 4.5, 4.0 } do
				r:ball(0.53, y, 0, 0.1, C.Gold, "Metal")
			end
			r:block(-0.16, 4.1, 0.5, 0.16, 5.45, 0.62, C.Yellow, "Fabric")
			r:block(-0.16, 4.1, 0.48, 0.16, 4.2, 0.64, C.White, "Fabric")
			r:cyl(-0.55, 5.45, 0, 0.06, 0.8, "y", C.Bark, "Fabric")
			r:cyl(-0.55, 5.62, 0, 0.32, 0.5, "y", C.Bark, "Fabric")
			r:cyl(-0.55, 5.5, 0, 0.06, 0.52, "y", C.Cream, "Fabric")
		end,
	},
	{
		id = "crate",
		name = "Crate",
		cat = "storage",
		price = 20,
		place = "floor",
		size = Vector3.new(2.2, 2, 2.2),
		surface = 2,
		c1 = "C99A62",
		c2 = "C99A62",
		tags = { "storage" },
		build = function(r: R)
			-- a packing crate: boards (c1) held by darker battens round every edge
			r:block(-1, 0.06, -1, 1, 1.94, 1, r.c1, "WoodPlanks")
			local batten = Color3.fromRGB(122, 84, 50)
			r:piece(function(q: R)
				for _, y in { 0.1, 1.9 } do
					q:block(-1.1, y - 0.1, -1.1, 1.1, y + 0.1, -0.9, batten, "Wood")
					q:block(-1.1, y - 0.1, 0.9, 1.1, y + 0.1, 1.1, batten, "Wood")
					q:block(-1.1, y - 0.1, -0.9, -0.9, y + 0.1, 0.9, batten, "Wood")
					q:block(0.9, y - 0.1, -0.9, 1.1, y + 0.1, 0.9, batten, "Wood")
				end
				for _, sx in { -1, 1 } do
					for _, sz in { -1, 1 } do
						q:box(sx * 1, 1, sz * 1, 0.2, 1.6, 0.2, batten, "Wood")
					end
				end
				-- a brace across the front and the back
				q:beam(Vector3.new(-0.9, 0.25, 1.03), Vector3.new(0.9, 1.75, 1.03), 0.08, 0.2, batten, "Wood")
				q:beam(Vector3.new(0.9, 0.25, -1.03), Vector3.new(-0.9, 1.75, -1.03), 0.08, 0.2, batten, "Wood")
			end, true)
		end,
	},
}

return items
