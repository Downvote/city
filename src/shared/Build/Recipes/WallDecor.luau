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
		mat = mat or "SmoothPlastic",
	})
end

-- A picture frame w x h with bars t wide, standing d out from the wall, with a thin darker lip
-- round the inside edge and a flat backing board behind.
local function frame(r: R, w: number, h: number, t: number, d: number, color: Color3, mat: string)
	r:block(-w / 2 + 0.05, 0.05, 0, w / 2 - 0.05, h - 0.05, 0.02, shade(color, 0.6), mat)
	r:block(-w / 2, h - t, 0, w / 2, h, d, color, mat)
	r:block(-w / 2, 0, 0, w / 2, t, d, color, mat)
	r:block(-w / 2, t, 0, -w / 2 + t, h - t, d, color, mat)
	r:block(w / 2 - t, t, 0, w / 2, h - t, d, color, mat)
	local lip = shade(color, 0.78)
	r:block(-w / 2 + t, t, d - 0.06, w / 2 - t, t + 0.04, d - 0.02, lip, mat)
	r:block(-w / 2 + t, h - t - 0.04, d - 0.06, w / 2 - t, h - t, d - 0.02, lip, mat)
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
			frame(r, 4, 3, 0.22, 0.25, r.c1, "Wood")
			r:block(-1.78, 0.22, 0.02, 1.78, 2.78, 0.1, MAT, "SmoothPlastic")
			-- sky, a sun and clouds, two hills, a field and a little house
			r:block(-1.55, 0.45, 0.1, 1.55, 2.55, 0.12, r.c2, "SmoothPlastic")
			r:block(-1.55, 1.9, 0.12, 1.55, 2.55, 0.125, shade(r.c2, 1.1), "SmoothPlastic")
			r:cyl(0.95, 2.1, 0.13, 0.02, 0.5, "z", C.Yellow, "SmoothPlastic")
			r:cyl(-0.85, 2.2, 0.13, 0.02, 0.36, "z", C.White, "SmoothPlastic")
			r:cyl(-0.58, 2.24, 0.135, 0.02, 0.46, "z", C.White, "SmoothPlastic")
			r:cyl(-0.35, 2.18, 0.13, 0.02, 0.3, "z", C.White, "SmoothPlastic")
			flatTri(r, Vector2.new(-0.4, 0.8), Vector2.new(1.55, 0.8), Vector2.new(1.55, 1.65), 0.14, C.DarkLeaf)
			flatTri(r, Vector2.new(-1.55, 0.8), Vector2.new(0.8, 0.8), Vector2.new(-0.6, 1.7), 0.16, C.Leaf)
			r:block(-1.55, 0.45, 0.12, 1.55, 0.85, 0.18, Color3.fromRGB(150, 190, 90), "SmoothPlastic")
			r:block(-1.55, 0.6, 0.18, 1.55, 0.66, 0.185, Color3.fromRGB(205, 180, 100), "SmoothPlastic")
			r:block(-0.85, 0.85, 0.18, -0.45, 1.13, 0.2, C.White, "SmoothPlastic")
			flatTri(r, Vector2.new(-0.92, 1.13), Vector2.new(-0.38, 1.13), Vector2.new(-0.65, 1.33), 0.2, C.Red)
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
			frame(r, 2.4, 3, 0.2, 0.25, r.c1, "Metal")
			r:block(-1.0, 0.2, 0.02, 1.0, 2.8, 0.12, r.c2, "SmoothPlastic")
			-- a table edge, a jug and a bunch of flowers
			r:block(-1.0, 0.2, 0.12, 1.0, 0.55, 0.14, shade(r.c2, 0.65), "SmoothPlastic")
			r:block(-0.3, 0.55, 0.12, 0.3, 1.2, 0.15, Color3.fromRGB(110, 160, 200), "SmoothPlastic")
			r:block(-0.2, 1.2, 0.12, 0.2, 1.35, 0.15, Color3.fromRGB(110, 160, 200), "SmoothPlastic")
			r:block(-0.3, 0.8, 0.15, 0.3, 0.88, 0.16, C.White, "SmoothPlastic")
			local flowers = {
				{ x = -0.45, y = 2.0, col = C.Pink },
				{ x = 0.4, y = 2.15, col = C.Yellow },
				{ x = 0.0, y = 2.45, col = Color3.fromRGB(230, 110, 90) },
				{ x = -0.15, y = 1.75, col = C.White },
				{ x = 0.3, y = 1.7, col = Color3.fromRGB(196, 160, 230) },
			}
			for _, f in flowers do
				r:beam(Vector3.new(0, 1.35, 0.14), Vector3.new(f.x, f.y, 0.14), 0.04, 0.04, C.Leaf, "SmoothPlastic")
				r:cyl(f.x, f.y, 0.15, 0.03, 0.4, "z", f.col, "SmoothPlastic")
				r:cyl(f.x, f.y, 0.165, 0.02, 0.14, "z", C.Yellow, "SmoothPlastic")
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
			frame(r, 3, 3, 0.1, 0.2, r.c1, "SmoothPlastic")
			r:block(-1.4, 0.1, 0.02, 1.4, 2.9, 0.08, MAT, "SmoothPlastic")
			r:block(-1.1, 0.4, 0.08, 1.1, 2.6, 0.1, r.c2, "SmoothPlastic")
			r:cyl(-0.3, 1.85, 0.11, 0.02, 1.1, "z", Color3.fromRGB(232, 180, 80), "SmoothPlastic")
			r:block(0.05, 0.6, 0.1, 0.9, 1.7, 0.12, Color3.fromRGB(217, 128, 95), "SmoothPlastic")
			r:block(-0.9, 0.6, 0.1, -0.2, 1.0, 0.13, Color3.fromRGB(90, 130, 160), "SmoothPlastic")
			r:block(-0.9, 1.2, 0.1, 0.9, 1.26, 0.14, C.Black, "SmoothPlastic")
			r:cyl(0.55, 2.2, 0.11, 0.02, 0.3, "z", Color3.fromRGB(143, 179, 154), "SmoothPlastic")
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
			r:cyl(0, 0.9, 0.27, 0.04, 1.66, "z", shade(r.c1, 0.8), "SmoothPlastic")
			r:cyl(0, 0.9, 0.28, 0.05, 1.5, "z", r.c2, "SmoothPlastic")
			for i = 0, 11 do
				local a = i * math.pi / 6
				local big = i % 3 == 0
				local len = if big then 0.18 else 0.1
				local cf = CFrame.new(math.cos(a) * 0.6, 0.9 + math.sin(a) * 0.6, 0.315) * CFrame.Angles(0, 0, a)
				r:boxAt(cf, len, if big then 0.06 else 0.035, 0.02, C.Black, "SmoothPlastic")
			end
			r:boxAt(
				CFrame.new(0.12, 1.05, 0.33) * CFrame.Angles(0, 0, -0.65),
				0.06,
				0.42,
				0.02,
				C.Black,
				"SmoothPlastic"
			)
			r:boxAt(
				CFrame.new(-0.05, 1.2, 0.34) * CFrame.Angles(0, 0, 0.15),
				0.045,
				0.6,
				0.02,
				C.Black,
				"SmoothPlastic"
			)
			r:boxAt(CFrame.new(0.15, 0.62, 0.345) * CFrame.Angles(0, 0, 0.5), 0.02, 0.62, 0.01, r.c1, "SmoothPlastic")
			r:cyl(0, 0.9, 0.35, 0.03, 0.1, "z", r.c1, "SmoothPlastic")
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
			-- an arched mirror in a slim frame, over a little ledge
			local mirror = Color3.fromRGB(205, 225, 234)
			local cy = 2.25
			r:block(-0.95, 0.3, 0.02, 0.95, cy, 0.08, mirror, "Glass")
			r:cyl(0, cy, 0.05, 0.06, 1.9, "z", mirror, "Glass")
			r:boxAt(CFrame.new(0.25, 1.7, 0.09) * CFrame.Angles(0, 0, -0.5), 0.16, 1.5, 0.01, C.White, "Glass")
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
				r:beam(p1 - d, p2 + d, 0.2, 0.18, r.c1, "Wood")
			end
			r:block(-1.3, 0, 0, 1.3, 0.14, 0.38, r.c2, "Wood")
			r:block(-1.2, 0.14, 0, 1.2, 0.2, 0.06, shade(r.c2, 0.85), "Wood")
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
			r:block(-1.8, 0.37, 0.9, 1.8, 0.4, 0.95, shade(r.c1, 0.8), "Wood")
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
			-- books, one leaning, a small framed photo and a plant
			local covers =
				{ Color3.fromRGB(176, 68, 62), Color3.fromRGB(70, 110, 150), Color3.fromRGB(143, 179, 154), C.Yellow }
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
			r:boxAt(CFrame.new(0.3, 0.92, 0.35) * CFrame.Angles(-0.15, 0, 0), 0.6, 0.72, 0.06, C.Black, "SmoothPlastic")
			r:boxAt(
				CFrame.new(0.3, 0.92, 0.39) * CFrame.Angles(-0.15, 0, 0),
				0.46,
				0.58,
				0.02,
				C.Paper,
				"SmoothPlastic"
			)
			r:cyl(1.1, 0.78, 0.5, 0.46, 0.5, "y", Color3.fromRGB(236, 232, 222), "SmoothPlastic")
			r:ball(1.1, 1.15, 0.5, 0.55, C.Leaf, "Grass")
			r:ball(0.92, 1.05, 0.62, 0.35, C.DarkLeaf, "Grass")
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
			r:cyl(0, 0.75, 0.03, 0.06, 0.55, "z", r.c2, "Metal")
			r:cyl(0, 0.75, 0.08, 0.06, 0.32, "z", shade(r.c2, 0.85), "Metal")
			rod(r, Vector3.new(0, 0.75, 0.1), Vector3.new(0, 0.95, 0.5), 0.09, r.c2, "Metal")
			rod(r, Vector3.new(0, 0.93, 0.5), Vector3.new(0, 0.93, 0.6), 0.09, r.c2, "Metal")
			r:cyl(0, 1.02, 0.6, 0.16, 0.26, "y", r.c2, "Metal")
			r:ball(0, 1.22, 0.6, 0.32, C.Warm, "SmoothPlastic")
			local lampshade = r:cyl(0, 1.45, 0.6, 0.7, 0.86, "y", r.c1, "Fabric")
			r:glow(lampshade, 12, 1)
			r:cyl(0, 1.12, 0.6, 0.04, 0.88, "y", r.c2, "Metal")
			r:cyl(0, 1.78, 0.6, 0.04, 0.88, "y", r.c2, "Metal")
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
			r:block(-0.8, 1.0, 0, 0.8, 2.2, 0.08, C.DarkMetal, "Metal")
			r:block(-0.3, 1.3, 0.08, 0.3, 1.9, 0.18, C.DarkMetal, "Metal")
			r:block(-2.7, 0, 0.18, 2.7, 3.2, 0.32, r.c1, "SmoothPlastic")
			r:block(-2.62, 0.08, 0.32, 2.62, 3.12, 0.34, r.c2, "Glass")
			r:boxAt(CFrame.new(0.8, 1.7, 0.345) * CFrame.Angles(0, 0, -0.7), 0.25, 2.4, 0.01, shade(r.c2, 1.5), "Glass")
			r:boxAt(CFrame.new(1.2, 1.9, 0.345) * CFrame.Angles(0, 0, -0.7), 0.1, 1.8, 0.01, shade(r.c2, 1.35), "Glass")
			r:block(-0.3, 0, 0.32, 0.3, 0.06, 0.36, shade(r.c1, 1.4), "SmoothPlastic")
			r:block(2.3, 0.02, 0.32, 2.4, 0.06, 0.35, Color3.fromRGB(120, 200, 140), "Neon")
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
			r:block(-1.5, 0.9, 0, 1.5, 1.4, 0.12, r.c1, "Wood")
			r:block(-1.5, 1.4, 0, 1.5, 1.46, 0.16, shade(r.c1, 0.9), "Wood")
			for _, x in { -1.05, -0.35, 0.35, 1.05 } do
				r:cyl(x, 1.12, 0.14, 0.06, 0.16, "z", r.c2, "Metal")
				rod(r, Vector3.new(x, 1.12, 0.14), Vector3.new(x, 1.0, 0.36), 0.07, r.c2, "Metal")
				r:ball(x, 1.04, 0.4, 0.12, r.c2, "Metal")
			end
			-- a scarf on one hook, a tote bag on another and a cap on a third
			r:block(-1.2, 0.05, 0.3, -0.9, 1.1, 0.4, C.Red, "Fabric")
			r:block(-1.21, 0.05, 0.3, -0.89, 0.2, 0.41, C.White, "Fabric")
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
		price = 90,
		place = "wall",
		size = Vector3.new(6, 2, 2.6),
		c1 = "C7383F",
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
			r:cyl(0, 0.96, 2.43, 6.0, 0.08, "x", shade(r.c1, 0.7), "Metal")
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
					math.min(sx * 2.6, sx * 1.16),
					0.2,
					0.14,
					math.max(sx * 2.6, sx * 1.16),
					0.32,
					0.56,
					shade(r.c1, 0.85),
					"Fabric"
				)
			end
		end,
	},
}

return items
