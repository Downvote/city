--!strict
-- Things that hang on a wall. The origin is on the wall's surface, +z points out into the room
-- and y = 0 is the item's bottom edge, so every drawing runs from z = 0 outward.
-- c1 is the frame or main body, c2 the picture, face or second colour.

local Recipe = require(script.Parent.Parent.Recipe)
local Colors = require(script.Parent.Parent.Parent.Util.Colors)

local C = Recipe.Colors

type R = Recipe.Recipe

local function shade(c: Color3, k: number): Color3
	return Colors.shade(c, k)
end

-- A picture frame w x h with bars t wide, standing d out from the wall.
local function frame(r: R, w: number, h: number, t: number, d: number, color: Color3, mat: string)
	r:block(-w / 2, h - t, 0, w / 2, h, d, color, mat)
	r:block(-w / 2, 0, 0, w / 2, t, d, color, mat)
	r:block(-w / 2, t, 0, -w / 2 + t, h - t, d, color, mat)
	r:block(w / 2 - t, t, 0, w / 2, h - t, d, color, mat)
end

-- A flat triangle on a picture, at depth z.
local function flatTri(r: R, a: Vector2, b: Vector2, c: Vector2, z: number, color: Color3)
	r:tri(Vector3.new(a.X, a.Y, z), Vector3.new(b.X, b.Y, z), Vector3.new(c.X, c.Y, z), 0.03, color, "SmoothPlastic")
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
		id = "art_landscape",
		name = "Landscape painting",
		cat = "walldecor",
		price = 60,
		place = "wall",
		size = Vector3.new(4, 3, 0.3),
		c1 = "8A5A2E",
		c2 = "9CCBE8",
		tags = { "art" },
		build = function(r: R)
			frame(r, 4, 3, 0.25, 0.25, r.c1, "Wood")
			r:block(-1.75, 0.25, 0.02, 1.75, 2.75, 0.12, r.c2, "SmoothPlastic")
			r:cyl(1.0, 2.1, 0.13, 0.03, 0.55, "z", C.Yellow, "SmoothPlastic")
			r:cyl(-0.9, 2.25, 0.13, 0.03, 0.4, "z", C.White, "SmoothPlastic")
			r:cyl(-0.6, 2.3, 0.13, 0.03, 0.5, "z", C.White, "SmoothPlastic")
			flatTri(r, Vector2.new(-0.4, 0.6), Vector2.new(1.75, 0.6), Vector2.new(1.75, 1.55), 0.14, C.DarkLeaf)
			flatTri(r, Vector2.new(-1.75, 0.6), Vector2.new(0.8, 0.6), Vector2.new(-0.6, 1.6), 0.16, C.Leaf)
			r:block(-1.75, 0.25, 0.12, 1.75, 0.65, 0.18, Color3.fromRGB(120, 180, 90), "SmoothPlastic")
			-- a little house on the hill
			r:block(-0.85, 0.65, 0.18, -0.45, 0.95, 0.2, C.White, "SmoothPlastic")
			flatTri(r, Vector2.new(-0.92, 0.95), Vector2.new(-0.38, 0.95), Vector2.new(-0.65, 1.15), 0.2, C.Red)
		end,
	},
	{
		id = "art_flowers",
		name = "Flower painting",
		cat = "walldecor",
		price = 50,
		place = "wall",
		size = Vector3.new(2.4, 3, 0.3),
		c1 = "DEB252",
		c2 = "3E5A4A",
		tags = { "art" },
		build = function(r: R)
			frame(r, 2.4, 3, 0.22, 0.25, r.c1, "Metal")
			r:block(-0.98, 0.22, 0.02, 0.98, 2.78, 0.12, r.c2, "SmoothPlastic")
			r:block(-0.98, 0.22, 0.12, 0.98, 0.5, 0.14, shade(r.c2, 0.7), "SmoothPlastic")
			r:block(-0.28, 0.5, 0.12, 0.28, 1.2, 0.15, C.Blue, "SmoothPlastic")
			r:block(-0.18, 1.2, 0.12, 0.18, 1.35, 0.15, C.Blue, "SmoothPlastic")
			local flowers = {
				{ x = -0.4, y = 2.0, col = C.Pink },
				{ x = 0.35, y = 2.2, col = C.Yellow },
				{ x = 0.0, y = 2.45, col = C.Red },
				{ x = -0.1, y = 1.8, col = C.White },
			}
			for _, f in flowers do
				r:beam(Vector3.new(0, 1.35, 0.14), Vector3.new(f.x, f.y, 0.14), 0.04, 0.04, C.Leaf, "SmoothPlastic")
				r:cyl(f.x, f.y, 0.15, 0.03, 0.42, "z", f.col, "SmoothPlastic")
			end
		end,
	},
	{
		id = "art_abstract",
		name = "Abstract print",
		cat = "walldecor",
		price = 40,
		place = "wall",
		size = Vector3.new(3, 3, 0.25),
		c1 = "2B282E",
		c2 = "F7F3EA",
		tags = { "art" },
		build = function(r: R)
			frame(r, 3, 3, 0.12, 0.2, r.c1, "SmoothPlastic")
			r:block(-1.38, 0.12, 0.02, 1.38, 2.88, 0.1, r.c2, "SmoothPlastic")
			r:cyl(-0.35, 1.85, 0.11, 0.03, 1.2, "z", C.Yellow, "SmoothPlastic")
			r:block(0.05, 0.5, 0.11, 1.0, 1.7, 0.14, Color3.fromRGB(217, 128, 95), "SmoothPlastic")
			r:block(-1.0, 0.5, 0.11, -0.2, 0.95, 0.15, C.Blue, "SmoothPlastic")
			r:block(-1.0, 1.15, 0.11, 1.0, 1.22, 0.16, C.Black, "SmoothPlastic")
		end,
	},
	{
		id = "clock_wall",
		name = "Wall clock",
		cat = "walldecor",
		price = 35,
		place = "wall",
		size = Vector3.new(1.8, 1.8, 0.4),
		c1 = "C7383F",
		c2 = "F7F3EA",
		tags = { "clock" },
		build = function(r: R)
			r:cyl(0, 0.9, 0.13, 0.26, 1.8, "z", r.c1, "SmoothPlastic")
			r:cyl(0, 0.9, 0.28, 0.05, 1.5, "z", r.c2, "SmoothPlastic")
			for i = 0, 3 do
				local a = i * math.pi / 2
				local x, y = math.cos(a) * 0.6, 0.9 + math.sin(a) * 0.6
				r:block(x - 0.05, y - 0.05, 0.3, x + 0.05, y + 0.05, 0.33, C.Black, "SmoothPlastic")
			end
			r:boxAt(
				CFrame.new(0.12, 1.05, 0.33) * CFrame.Angles(0, 0, -0.65),
				0.06,
				0.42,
				0.02,
				C.Black,
				"SmoothPlastic"
			)
			r:boxAt(CFrame.new(-0.05, 1.2, 0.34) * CFrame.Angles(0, 0, 0.15), 0.05, 0.6, 0.02, C.Black, "SmoothPlastic")
			r:cyl(0, 0.9, 0.35, 0.03, 0.12, "z", r.c1, "SmoothPlastic")
		end,
	},
	{
		id = "mirror_wall",
		name = "Wall mirror",
		cat = "walldecor",
		price = 50,
		place = "wall",
		size = Vector3.new(2.6, 3.4, 0.4),
		c1 = "C99A62",
		c2 = "F7F3EA",
		tags = { "mirror" },
		build = function(r: R)
			local mirror = Color3.fromRGB(205, 225, 234)
			r:block(-1.2, 0.15, 0, 1.2, 2.2, 0.2, r.c1, "Wood")
			r:cyl(0, 2.2, 0.1, 0.2, 2.4, "z", r.c1, "Wood")
			r:block(-1.0, 0.35, 0.2, 1.0, 2.2, 0.24, mirror, "Glass")
			r:cyl(0, 2.2, 0.22, 0.04, 2.0, "z", mirror, "Glass")
			r:boxAt(CFrame.new(0.25, 1.6, 0.25) * CFrame.Angles(0, 0, -0.5), 0.18, 1.6, 0.01, C.White, "Glass")
			-- a little ledge underneath
			r:block(-1.3, 0, 0, 1.3, 0.15, 0.38, r.c2, "Wood")
		end,
	},
	{
		id = "shelf_wall",
		name = "Wall shelf",
		cat = "walldecor",
		price = 40,
		place = "wall",
		size = Vector3.new(3.6, 1.6, 1),
		c1 = "C99A62",
		c2 = "45454A",
		tags = { "books" },
		build = function(r: R)
			r:block(-1.8, 0.4, 0, 1.8, 0.55, 0.95, r.c1, "Wood")
			for _, x in { -1.2, 1.2 } do
				r:tri(
					Vector3.new(x, 0.4, 0.02),
					Vector3.new(x, 0.4, 0.75),
					Vector3.new(x, 0.0, 0.02),
					0.1,
					r.c2,
					"Metal"
				)
			end
			-- books, one leaning, and a small plant
			local covers = { C.Red, C.Blue, Color3.fromRGB(143, 179, 154), C.Yellow }
			for i, col in covers do
				local x = -1.6 + (i - 1) * 0.24
				r:block(x, 0.55, 0.15, x + 0.21, 0.55 + 0.7 + (i % 2) * 0.15, 0.85, col, "SmoothPlastic")
			end
			r:boxAt(
				CFrame.new(-0.42, 0.88, 0.5) * CFrame.Angles(0, 0, -0.35),
				0.2,
				0.7,
				0.7,
				Color3.fromRGB(142, 91, 122),
				"SmoothPlastic"
			)
			r:cyl(1.0, 0.78, 0.5, 0.46, 0.5, "y", Color3.fromRGB(196, 110, 80), "SmoothPlastic")
			r:ball(1.0, 1.15, 0.5, 0.55, C.Leaf, "Grass")
			r:ball(0.82, 1.05, 0.62, 0.35, C.DarkLeaf, "Grass")
		end,
	},
	{
		id = "sconce",
		name = "Wall lamp",
		cat = "walldecor",
		price = 45,
		place = "wall",
		size = Vector3.new(1, 2, 1.2),
		c1 = "F2E1C4",
		c2 = "B08A4A",
		tags = { "light" },
		build = function(r: R)
			r:block(-0.25, 0.3, 0, 0.25, 1.2, 0.08, r.c2, "Metal")
			r:beam(Vector3.new(0, 0.6, 0.08), Vector3.new(0, 0.95, 0.55), 0.1, 0.1, r.c2, "Metal")
			r:cyl(0, 1.0, 0.6, 0.12, 0.3, "y", r.c2, "Metal")
			r:ball(0, 1.25, 0.6, 0.35, C.Warm, "SmoothPlastic")
			local lampshade = r:cyl(0, 1.5, 0.6, 0.7, 0.9, "y", r.c1, "Fabric")
			r:glow(lampshade, 12, 1)
		end,
	},
	{
		id = "tv_wall",
		name = "Wall TV",
		cat = "walldecor",
		price = 280,
		place = "wall",
		size = Vector3.new(5.4, 3.2, 0.4),
		c1 = "2B282E",
		c2 = "283446",
		tags = { "tv" },
		build = function(r: R)
			r:block(-0.6, 1.0, 0, 0.6, 2.2, 0.15, C.DarkMetal, "Metal")
			r:block(-2.7, 0, 0.15, 2.7, 3.2, 0.35, r.c1, "SmoothPlastic")
			r:block(-2.55, 0.15, 0.35, 2.55, 3.05, 0.37, r.c2, "Glass")
			r:boxAt(CFrame.new(0.8, 1.7, 0.375) * CFrame.Angles(0, 0, -0.7), 0.25, 2.4, 0.01, shade(r.c2, 1.5), "Glass")
			r:block(2.3, 0.05, 0.35, 2.4, 0.1, 0.37, Color3.fromRGB(120, 200, 140), "Neon")
		end,
	},
	{
		id = "coat_hooks",
		name = "Coat hooks",
		cat = "walldecor",
		price = 30,
		place = "wall",
		size = Vector3.new(3, 1.6, 0.6),
		c1 = "F7F3EA",
		c2 = "45454A",
		tags = { "storage" },
		build = function(r: R)
			r:block(-1.5, 0.9, 0, 1.5, 1.4, 0.15, r.c1, "Wood")
			for _, x in { -1.05, -0.35, 0.35, 1.05 } do
				r:cyl(x, 1.1, 0.3, 0.3, 0.1, "z", r.c2, "Metal")
				r:ball(x, 1.15, 0.46, 0.14, r.c2, "Metal")
			end
			-- a scarf on one hook and a cap on another
			r:block(-1.2, 0.05, 0.32, -0.9, 1.1, 0.42, C.Red, "Fabric")
			r:block(-1.2, 0.05, 0.32, -0.9, 0.2, 0.43, C.White, "Fabric")
			r:ball(0.35, 1.0, 0.42, 0.5, C.Blue, "Fabric")
			r:block(0.15, 0.82, 0.42, 0.55, 0.88, 0.6, C.Blue, "Fabric")
		end,
	},
	{
		id = "awning",
		name = "Striped awning",
		cat = "walldecor",
		price = 90,
		place = "wall",
		size = Vector3.new(6, 2, 2.6),
		c1 = "C7383F",
		c2 = "F7F3EA",
		build = function(r: R)
			r:block(-3, 1.85, 0, 3, 2.0, 0.15, shade(r.c1, 0.7), "Wood")
			for i = 0, 5 do
				local x = -2.5 + i
				local col = if i % 2 == 0 then r.c1 else r.c2
				r:beam(Vector3.new(x, 1.9, 0.1), Vector3.new(x, 0.95, 2.45), 1.0, 0.1, col, "Fabric")
				-- a scalloped flap along the front
				r:block(x - 0.5, 0.5, 2.38, x + 0.5, 0.97, 2.48, col, "Fabric")
				r:cyl(x, 0.5, 2.43, 0.1, 1.0, "z", col, "Fabric")
			end
			for _, x in { -2.9, 2.9 } do
				r:beam(Vector3.new(x, 0.6, 0.02), Vector3.new(x, 0.95, 2.35), 0.08, 0.08, C.DarkMetal, "Metal")
			end
		end,
	},
	{
		id = "curtains",
		name = "Curtains",
		cat = "walldecor",
		price = 70,
		place = "wall",
		size = Vector3.new(5.6, 6, 0.8),
		c1 = "8FB39A",
		c2 = "B08A4A",
		build = function(r: R)
			r:cyl(0, 5.75, 0.55, 5.3, 0.12, "x", r.c2, "Metal")
			for _, sx in { -1, 1 } do
				r:ball(sx * 2.7, 5.75, 0.55, 0.26, r.c2, "Metal")
				r:block(sx * 2.4 - 0.05, 5.65, 0, sx * 2.4 + 0.05, 5.85, 0.55, r.c2, "Metal")
				-- a panel hanging in soft folds, tied back halfway down
				for i = 0, 3 do
					local x1 = sx * (2.6 - i * 0.36)
					local x2 = sx * (2.6 - (i + 1) * 0.36)
					local deep = i % 2 == 0
					r:block(
						math.min(x1, x2),
						0.2,
						if deep then 0.15 else 0.25,
						math.max(x1, x2),
						5.65,
						if deep then 0.45 else 0.55,
						if deep then r.c1 else shade(r.c1, 1.1),
						"Fabric"
					)
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
			end
			r:block(-2.8, 5.85, 0.1, 2.8, 6.0, 0.7, r.c2, "Metal")
		end,
	},
}

return items
