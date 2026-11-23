--!strict
-- Rugs, plants and little things that make a room feel lived in.
-- c1 is the main colour, c2 the second one (a pattern, leaves, a trim).

local Recipe = require(script.Parent.Parent.Recipe)
local Colors = require(script.Parent.Parent.Parent.Util.Colors)

local C = Recipe.Colors

type R = Recipe.Recipe

local function shade(c: Color3, k: number): Color3
	return Colors.shade(c, k)
end

-- Glows at night without a light of its own (when another part of the item already has one).
local function glowOnly(p: Recipe.Prim)
	p.role = "glow"
end

-- A flat rug layer: walked over, never bumped into.
local function flat(r: R, p: Recipe.Prim)
	r:noCollide(p)
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

-- A flat leaf on a stem: the stem runs from `base` to `tip`, where a leaf w long points on
-- outward and droops a little, with a pale vein down its middle.
local function leaf(r: R, base: Vector3, tip: Vector3, w: number, color: Color3)
	rod(r, base, tip, 0.06, shade(color, 0.7), "SmoothPlastic")
	local dir = tip - base
	local flatDir = Vector3.new(dir.X, 0, dir.Z)
	local yaw = if flatDir.Magnitude > 1e-3 then math.atan2(flatDir.X, flatDir.Z) else 0
	local cf = CFrame.new(tip) * CFrame.Angles(0, yaw, 0) * CFrame.Angles(-0.35, 0, 0)
	r:boxAt(
		cf * CFrame.new(0, 0, w * 0.55) * CFrame.Angles(0, math.pi / 4, 0),
		w * 0.78,
		0.05,
		w * 0.78,
		color,
		"SmoothPlastic"
	)
	r:boxAt(cf * CFrame.new(0, 0.005, w * 0.55), 0.04, 0.05, w * 1.1, shade(color, 1.18), "SmoothPlastic")
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
		id = "rug_round",
		name = "Round rug",
		cat = "decor",
		price = 60,
		place = "floor",
		size = Vector3.new(6, 0.1, 6),
		c1 = "D08A6C",
		c2 = "F2E8D5",
		tags = { "rug" },
		build = function(r: R)
			flat(r, r:cyl(0, 0.03, 0, 0.06, 6, "y", r.c1, "Carpet"))
			flat(r, r:cyl(0, 0.035, 0, 0.07, 5.4, "y", r.c2, "Carpet"))
			flat(r, r:cyl(0, 0.04, 0, 0.08, 5.1, "y", r.c1, "Carpet"))
			flat(r, r:cyl(0, 0.045, 0, 0.09, 2.4, "y", shade(r.c1, 0.85), "Carpet"))
			flat(r, r:cyl(0, 0.05, 0, 0.1, 1.6, "y", r.c2, "Carpet"))
			flat(r, r:cyl(0, 0.055, 0, 0.1, 0.7, "y", r.c1, "Carpet"))
			-- a ring of little diamonds between the border and the middle
			for i = 0, 7 do
				local a = i * math.pi / 4
				flat(
					r,
					r:boxAt(
						CFrame.new(math.cos(a) * 1.85, 0.045, math.sin(a) * 1.85)
							* CFrame.Angles(0, -a + math.pi / 4, 0),
						0.45,
						0.09,
						0.45,
						r.c2,
						"Carpet"
					)
				)
			end
		end,
	},
	{
		id = "rug_long",
		name = "Long rug",
		cat = "decor",
		price = 70,
		place = "floor",
		size = Vector3.new(4, 0.1, 8),
		c1 = "7A9CC6",
		c2 = "F2E8D5",
		tags = { "rug" },
		build = function(r: R)
			flat(r, r:block(-2, 0, -3.8, 2, 0.06, 3.8, r.c1, "Carpet"))
			flat(r, r:block(-1.7, 0, -3.5, 1.7, 0.07, 3.5, r.c2, "Carpet"))
			flat(r, r:block(-1.5, 0, -3.3, 1.5, 0.08, 3.3, r.c1, "Carpet"))
			for _, z in { -2.2, 0, 2.2 } do
				flat(
					r,
					r:boxAt(CFrame.new(0, 0.045, z) * CFrame.Angles(0, math.pi / 4, 0), 1.2, 0.09, 1.2, r.c2, "Carpet")
				)
				flat(
					r,
					r:boxAt(
						CFrame.new(0, 0.05, z) * CFrame.Angles(0, math.pi / 4, 0),
						0.6,
						0.1,
						0.6,
						shade(r.c1, 0.8),
						"Carpet"
					)
				)
			end
			-- tassels at both ends
			for _, s in { -1, 1 } do
				for i = 0, 8 do
					local x = -1.8 + i * 0.45
					flat(r, r:block(x - 0.06, 0, s * 3.8, x + 0.06, 0.035, s * 4.0, C.Cream, "Fabric"))
				end
			end
		end,
	},
	{
		id = "plant_small",
		name = "Small plant",
		cat = "decor",
		price = 20,
		place = "surface",
		size = Vector3.new(1, 1.5, 1),
		c1 = "C07A60",
		c2 = "6A9A5C",
		tags = { "plant" },
		build = function(r: R)
			-- a pot on a saucer with a rosette of fat leaves
			r:cyl(0, 0.03, 0, 0.06, 0.8, "y", shade(r.c1, 0.85), "SmoothPlastic")
			r:cyl(0, 0.3, 0, 0.5, 0.62, "y", r.c1, "SmoothPlastic")
			r:cyl(0, 0.6, 0, 0.14, 0.74, "y", shade(r.c1, 1.08), "SmoothPlastic")
			r:cyl(0, 0.66, 0, 0.04, 0.62, "y", C.Soil, "Sand")
			for i = 0, 6 do
				local a = i * math.pi * 2 / 7
				local lift = if i % 2 == 0 then 0.5 else 0.8
				local cf = CFrame.new(math.cos(a) * 0.12, 0.72, math.sin(a) * 0.12)
					* CFrame.Angles(0, -a + math.pi / 2, 0)
					* CFrame.Angles(-lift, 0, 0)
				r:boxAt(
					cf * CFrame.new(0, 0, 0.22),
					0.2,
					0.12,
					0.46,
					if i % 2 == 0 then r.c2 else shade(r.c2, 0.85),
					"SmoothPlastic"
				)
			end
			r:ball(0, 0.88, 0, 0.3, shade(r.c2, 1.1), "SmoothPlastic")
		end,
	},
	{
		id = "plant_big",
		name = "Big plant",
		cat = "decor",
		price = 60,
		place = "floor",
		size = Vector3.new(3.2, 5.4, 3.2),
		c1 = "F2E8D5",
		c2 = "5E8E5A",
		tags = { "plant" },
		build = function(r: R)
			-- a tall pot with a band, and a plant of big flat leaves on long stems
			r:cyl(0, 0.06, 0, 0.12, 1.3, "y", shade(r.c1, 0.8), "SmoothPlastic")
			r:cyl(0, 0.75, 0, 1.3, 1.5, "y", r.c1, "SmoothPlastic")
			r:cyl(0, 1.0, 0, 0.12, 1.52, "y", shade(r.c1, 0.85), "SmoothPlastic")
			r:cyl(0, 1.44, 0, 0.12, 1.62, "y", shade(r.c1, 1.05), "SmoothPlastic")
			r:cyl(0, 1.5, 0, 0.04, 1.4, "y", C.Soil, "Sand")
			local base = Vector3.new(0, 1.5, 0)
			local tips = {
				{ 0.5, 4.2, 0.2, 1.5 },
				{ -0.55, 3.9, -0.25, 1.5 },
				{ 0.15, 4.4, -0.5, 1.4 },
				{ -0.3, 3.3, 0.6, 1.4 },
				{ 0.7, 3.1, -0.45, 1.3 },
				{ -0.75, 2.7, 0.2, 1.2 },
				{ 0.1, 3.6, 0.7, 1.3 },
				{ -0.2, 4.6, 0.1, 1.2 },
				{ 0.6, 2.5, 0.45, 1.1 },
			}
			for i, t in tips do
				leaf(r, base, Vector3.new(t[1], t[2], t[3]), t[4], if i % 2 == 0 then r.c2 else shade(r.c2, 0.85))
			end
		end,
	},
	{
		id = "vase_flowers",
		name = "Flower vase",
		cat = "decor",
		price = 25,
		place = "surface",
		size = Vector3.new(1, 2, 1),
		c1 = "7A9CC6",
		c2 = "F59EB5",
		tags = { "plant" },
		build = function(r: R)
			r:cyl(0, 0.05, 0, 0.1, 0.4, "y", shade(r.c1, 0.85), "SmoothPlastic")
			r:ball(0, 0.35, 0, 0.6, r.c1, "SmoothPlastic")
			r:cyl(0, 0.7, 0, 0.3, 0.26, "y", r.c1, "SmoothPlastic")
			r:cyl(0, 0.86, 0, 0.04, 0.34, "y", shade(r.c1, 1.1), "SmoothPlastic")
			local heads = { { 0.28, 1.55, 0.1 }, { -0.25, 1.68, -0.05 }, { 0.05, 1.85, -0.2 }, { -0.08, 1.48, 0.28 } }
			for i, h in heads do
				local top = Vector3.new(h[1], h[2], h[3])
				rod(r, Vector3.new(0, 0.8, 0), top, 0.04, C.DarkLeaf, "SmoothPlastic")
				r:ball(h[1], h[2], h[3], 0.3, if i % 2 == 0 then C.Yellow else r.c2, "SmoothPlastic")
				r:ball(
					h[1],
					h[2] + 0.1,
					h[3],
					0.12,
					if i % 2 == 0 then Color3.fromRGB(224, 154, 94) else C.Yellow,
					"SmoothPlastic"
				)
			end
			r:boxAt(CFrame.new(0.2, 1.1, -0.05) * CFrame.Angles(0, 0, -0.7), 0.06, 0.4, 0.18, C.Leaf, "SmoothPlastic")
			r:boxAt(CFrame.new(-0.18, 1.05, 0.08) * CFrame.Angles(0, 0, 0.7), 0.06, 0.4, 0.18, C.Leaf, "SmoothPlastic")
		end,
	},
	{
		id = "books_stack",
		name = "Stack of books",
		cat = "decor",
		price = 15,
		place = "surface",
		size = Vector3.new(1.4, 0.8, 1.1),
		c1 = "B8505A",
		c2 = "3E6E58",
		tags = { "books" },
		build = function(r: R)
			local covers = { r.c1, Color3.fromRGB(70, 110, 150), r.c2, C.Yellow }
			local turns = { 0.05, -0.12, 0.1, -0.05 }
			local y = 0
			for i, col in covers do
				local h = if i == 2 then 0.2 else 0.15
				local w = 1.2 - i * 0.06
				local cf = CFrame.new(0, y + h / 2, 0) * CFrame.Angles(0, turns[i], 0)
				r:boxAt(cf, w, h, 0.85, col, "SmoothPlastic")
				r:boxAt(cf * CFrame.new(0.04, 0, 0.02), w - 0.04, h - 0.05, 0.85, C.Paper, "SmoothPlastic")
				r:boxAt(cf * CFrame.new(-w / 2 + 0.12, 0, 0), 0.05, h + 0.005, 0.86, shade(col, 0.7), "SmoothPlastic")
				y += h
			end
			-- a ribbon bookmark hanging out of the top one
			r:block(0.1, y - 0.3, 0.42, 0.16, y - 0.01, 0.46, C.Red, "Fabric")
		end,
	},
	{
		id = "globe",
		name = "Globe",
		cat = "decor",
		price = 45,
		place = "surface",
		size = Vector3.new(1.3, 1.8, 1.2),
		c1 = "6AA2C8",
		c2 = "86C060",
		build = function(r: R)
			r:cyl(0, 0.05, 0, 0.1, 0.8, "y", C.Bark, "Wood")
			r:cyl(0, 0.13, 0, 0.06, 0.6, "y", shade(C.Bark, 1.2), "Wood")
			r:cyl(0, 0.32, 0, 0.36, 0.12, "y", C.Gold, "Metal")
			local cy = 1.1
			r:ball(0, cy, 0, 1.0, r.c1, "SmoothPlastic")
			-- land: patches that only just poke out of the sea
			for _, p in
				{
					{ 0.6, 0.4, 0.6, 0.5 },
					{ -0.4, -0.3, 0.7, 0.42 },
					{ -0.7, 0.6, -0.3, 0.4 },
					{ 0.3, -0.6, -0.6, 0.36 },
					{ 0.8, -0.1, -0.2, 0.3 },
				}
			do
				local dir = Vector3.new(p[1], p[2], p[3]).Unit * (0.54 - p[4] / 2)
				r:ball(dir.X, cy + dir.Y, dir.Z, p[4], r.c2, "SmoothPlastic")
			end
			-- the half ring that holds it, on a tilted axis
			local n = 6
			for i = 0, n - 1 do
				local a1 = -math.pi / 2 + i / n * math.pi
				local a2 = -math.pi / 2 + (i + 1) / n * math.pi
				r:beam(
					Vector3.new(math.cos(a1) * 0.6, cy + math.sin(a1) * 0.6, 0),
					Vector3.new(math.cos(a2) * 0.6, cy + math.sin(a2) * 0.6, 0),
					0.07,
					0.07,
					C.Gold,
					"Metal"
				)
			end
			r:ball(0, cy + 0.6, 0, 0.1, C.Gold, "Metal")
		end,
	},
	{
		id = "candles",
		name = "Candles",
		cat = "decor",
		price = 20,
		place = "surface",
		size = Vector3.new(1.2, 1.1, 1.2),
		c1 = "F7F3EA",
		c2 = "D4AE5E",
		tags = { "light" },
		build = function(r: R)
			r:cyl(0, 0.03, 0, 0.06, 1.15, "y", r.c2, "Metal")
			r:cyl(0, 0.07, 0, 0.03, 1.05, "y", shade(r.c2, 0.85), "Metal")
			local set = { { -0.25, 0.1, 0.8 }, { 0.25, 0.05, 0.6 }, { 0, -0.3, 0.45 } }
			for i, c in set do
				local x, z, h = c[1], c[2], c[3]
				r:cyl(x, 0.08 + h / 2, z, h, 0.3, "y", r.c1, "SmoothPlastic")
				r:cyl(x, 0.08 + h, z, 0.02, 0.24, "y", shade(r.c1, 0.9), "SmoothPlastic")
				r:cyl(x, 0.13 + h, z, 0.08, 0.03, "y", C.Black, "SmoothPlastic")
				local flame = r:ball(x, 0.22 + h, z, 0.14, C.Warm, "SmoothPlastic")
				if i == 1 then
					r:glow(flame, 10, 0.8)
				else
					glowOnly(flame)
				end
			end
		end,
	},
	{
		id = "teddy",
		name = "Teddy bear",
		cat = "decor",
		price = 30,
		place = "surface",
		size = Vector3.new(1.1, 1.45, 1),
		c1 = "B08258",
		c2 = "E9D3B0",
		tags = { "toy" },
		build = function(r: R)
			r:ball(0, 0.45, 0, 0.8, r.c1, "Fabric")
			r:ball(0, 0.42, 0.2, 0.5, r.c2, "Fabric")
			for _, sx in { -1, 1 } do
				r:ball(sx * 0.4, 0.55, 0.08, 0.3, r.c1, "Fabric")
				r:ball(sx * 0.22, 0.17, 0.28, 0.34, r.c1, "Fabric")
				r:cyl(sx * 0.22, 0.17, 0.44, 0.03, 0.2, "z", r.c2, "Fabric")
				r:ball(sx * 0.22, 1.32, 0, 0.24, r.c1, "Fabric")
				r:ball(sx * 0.22, 1.33, 0.06, 0.13, r.c2, "Fabric")
				r:ball(sx * 0.12, 1.12, 0.27, 0.07, C.Black, "SmoothPlastic")
			end
			r:ball(0, 1.05, 0.03, 0.62, r.c1, "Fabric")
			r:ball(0, 0.98, 0.27, 0.26, r.c2, "Fabric")
			r:ball(0, 1.02, 0.39, 0.09, C.Black, "SmoothPlastic")
			-- a bow at the neck
			r:ball(0, 0.78, 0.33, 0.08, C.Red, "Fabric")
			for _, sx in { -1, 1 } do
				r:boxAt(
					CFrame.new(sx * 0.11, 0.78, 0.31) * CFrame.Angles(0, 0, sx * 0.3),
					0.16,
					0.12,
					0.06,
					C.Red,
					"Fabric"
				)
			end
		end,
	},
	{
		id = "fireplace",
		name = "Fireplace",
		cat = "decor",
		price = 400,
		place = "floor",
		size = Vector3.new(6, 6.4, 2.4),
		c1 = "B0624E",
		c2 = "F2E8D5",
		build = function(r: R)
			-- a stone hearth, a brick surround and a dark firebox
			r:block(-3, 0, -1.2, 3, 0.3, 1.2, C.Stone, "Slate")
			r:block(-3, 0.3, -1.2, -1.7, 4.4, 0.55, r.c1, "Brick")
			r:block(1.7, 0.3, -1.2, 3, 4.4, 0.55, r.c1, "Brick")
			r:block(-1.7, 3.2, -1.2, 1.7, 4.4, 0.55, r.c1, "Brick")
			r:block(-1.7, 0.3, -1.1, 1.7, 3.2, -0.7, Color3.fromRGB(40, 36, 38), "Slate")
			r:block(-1.7, 0.3, -1.2, 1.7, 3.2, -1.1, r.c1, "Brick")
			r:block(-1.7, 0.3, -0.7, -1.6, 3.2, 0.5, Color3.fromRGB(60, 54, 54), "Slate")
			r:block(1.6, 0.3, -0.7, 1.7, 3.2, 0.5, Color3.fromRGB(60, 54, 54), "Slate")
			-- a painted wooden surround with pilasters and a mantel shelf on top
			for _, sx in { -1, 1 } do
				r:block(sx * 2.4 - 0.45, 0.3, 0.55, sx * 2.4 + 0.45, 4.4, 0.75, r.c2, "Wood")
				r:block(sx * 2.4 - 0.55, 0.3, 0.55, sx * 2.4 + 0.55, 0.7, 0.85, shade(r.c2, 0.9), "Wood")
				r:block(sx * 2.4 - 0.55, 4.1, 0.55, sx * 2.4 + 0.55, 4.4, 0.85, shade(r.c2, 0.95), "Wood")
			end
			r:block(-1.95, 3.6, 0.55, 1.95, 4.4, 0.72, r.c2, "Wood")
			r:block(-3, 4.4, -1.2, 3, 4.65, 1.0, r.c2, "Wood")
			r:block(-2.9, 4.65, -1.2, 2.9, 4.75, 0.9, shade(r.c2, 0.9), "Wood")
			r:block(-2.3, 4.75, -1.2, 2.3, 6.4, -0.3, r.c1, "Brick")
			-- a grate with logs and a fire
			for _, x in { -0.8, 0.8 } do
				r:block(x - 0.06, 0.3, -0.6, x + 0.06, 0.6, 0.3, C.DarkMetal, "Metal")
			end
			local ember = r:block(-0.8, 0.3, -0.6, 0.8, 0.4, 0.2, Color3.fromRGB(255, 120, 50), "SmoothPlastic")
			r:glow(ember, 18, 1.4, Color3.fromRGB(255, 160, 90))
			r:cyl(0, 0.65, -0.35, 1.7, 0.42, "x", C.Bark, "Wood")
			r:cyl(0, 0.65, 0.05, 1.5, 0.38, "x", shade(C.Bark, 1.15), "Wood")
			local top = r:cyl(0, 0.98, -0.15, 1.5, 0.36, "x", C.Bark, "Wood")
			r:fire(top)
			-- a brass fire screen in front
			r:block(-1.3, 0.3, 0.85, 1.3, 0.38, 0.95, C.Gold, "Metal")
			r:block(-1.3, 1.5, 0.85, 1.3, 1.56, 0.95, C.Gold, "Metal")
			for _, x in { -1.3, 0, 1.3 } do
				r:block(x - 0.04, 0.3, 0.86, x + 0.04, 1.56, 0.94, C.Gold, "Metal")
			end
			-- candlesticks, a little clock and a plant on the mantel
			for _, x in { -2.5, 2.5 } do
				r:cyl(x, 4.85, 0.3, 0.2, 0.3, "y", C.Gold, "Metal")
				r:cyl(x, 5.2, 0.3, 0.5, 0.18, "y", C.White, "SmoothPlastic")
			end
			r:block(-0.35, 4.75, 0.05, 0.35, 5.35, 0.45, Color3.fromRGB(110, 76, 48), "Wood")
			r:cyl(0, 5.05, 0.46, 0.03, 0.42, "z", C.Cream, "SmoothPlastic")
			r:cyl(1.5, 4.95, 0.2, 0.4, 0.4, "y", C.White, "SmoothPlastic")
			r:ball(1.5, 5.3, 0.2, 0.5, C.Leaf, "Grass")
		end,
	},
	{
		id = "aquarium",
		name = "Fish tank",
		cat = "decor",
		price = 300,
		place = "floor",
		size = Vector3.new(4, 4.8, 1.8),
		c1 = "6E4C34",
		c2 = "2B282E",
		build = function(r: R)
			-- a cabinet stand with two doors
			r:block(-1.95, 0, -0.85, 1.95, 0.2, 0.8, shade(r.c1, 0.6), "Wood")
			r:block(-2, 0.2, -0.9, 2, 2.2, 0.9, r.c1, "Wood")
			for _, sx in { -1, 1 } do
				local xa, xb = sx * 0.04, sx * 1.9
				r:block(math.min(xa, xb), 0.32, 0.9, math.max(xa, xb), 2.08, 0.95, shade(r.c1, 1.12), "Wood")
				r:block(math.min(xa, xb) + 0.15, 0.47, 0.95, math.max(xa, xb) - 0.15, 1.93, 0.96, r.c1, "Wood")
				r:block(sx * 0.25 - 0.03, 0.9, 0.96, sx * 0.25 + 0.03, 1.5, 1.02, C.Gold, "Metal")
			end
			-- the tank: a black frame, gravel, a rock, a little castle and weed
			r:block(-1.9, 2.2, -0.8, 1.9, 2.35, 0.8, r.c2, "Metal")
			for _, sx in { -1, 1 } do
				for _, sz in { -1, 1 } do
					r:box(sx * 1.86, 3.375, sz * 0.76, 0.08, 2.05, 0.08, r.c2, "Metal")
				end
			end
			r:block(-1.82, 2.35, -0.72, 1.82, 2.6, 0.72, Color3.fromRGB(222, 196, 150), "Pebble")
			r:ball(-1.1, 2.6, -0.25, 0.65, C.Stone, "Rock")
			r:block(0.6, 2.6, -0.5, 1.2, 3.3, 0.0, Color3.fromRGB(200, 190, 175), "Slate")
			r:block(0.75, 3.3, -0.4, 1.05, 3.5, -0.1, Color3.fromRGB(200, 190, 175), "Slate")
			r:block(0.8, 2.6, 0.0, 1.0, 2.9, 0.02, C.Black, "SmoothPlastic")
			for _, p in { { -1.5, 0.2, 3.9 }, { -1.3, -0.4, 3.6 }, { 1.5, -0.3, 3.8 }, { 0.2, -0.5, 3.2 } } do
				r:beam(Vector3.new(p[1], 2.6, p[2]), Vector3.new(p[1] + 0.12, p[3], p[2]), 0.1, 0.2, C.Leaf, "Grass")
			end
			-- fish and a few bubbles
			local fish = {
				{ x = -0.3, y = 3.5, z = 0.1, col = C.Yellow },
				{ x = 0.2, y = 3.0, z = 0.2, col = Color3.fromRGB(224, 154, 94) },
				{ x = -0.6, y = 3.95, z = -0.3, col = C.Blue },
			}
			for _, f in fish do
				r:block(f.x - 0.2, f.y - 0.12, f.z - 0.07, f.x + 0.2, f.y + 0.12, f.z + 0.07, f.col, "SmoothPlastic")
				r:block(f.x + 0.2, f.y - 0.1, f.z - 0.03, f.x + 0.32, f.y + 0.1, f.z + 0.03, f.col, "SmoothPlastic")
			end
			for _, b in { { -1.0, 3.2 }, { -0.95, 3.6 }, { -1.05, 3.95 } } do
				r:ball(b[1], b[2], -0.25, 0.1, C.White, "Glass")
			end
			local water = r:block(-1.82, 2.6, -0.72, 1.82, 4.2, 0.72, C.Water, "Glass")
			water.transp = 0.6
			-- a hood on top with a light strip under it
			r:block(-1.92, 4.4, -0.82, 1.92, 4.75, 0.82, r.c2, "Metal")
			r:block(-1.8, 4.36, -0.7, 1.8, 4.4, 0.7, C.White, "Neon")
		end,
	},
	{
		id = "mirror_floor",
		name = "Floor mirror",
		cat = "decor",
		price = 80,
		place = "floor",
		size = Vector3.new(2.2, 6.3, 1.2),
		c1 = "D4AE5E",
		c2 = "6E4C34",
		tags = { "mirror" },
		build = function(r: R)
			-- an arched mirror leaning back against the wall behind it
			local mirror = Color3.fromRGB(205, 225, 234)
			local lean = CFrame.new(0, 0.12, 0.35) * CFrame.Angles(-0.1, 0, 0)
			local function at(x: number, y: number, z: number): CFrame
				return lean * CFrame.new(x, y, z)
			end
			r:boxAt(at(0, 2.5, 0), 1.7, 5.0, 0.06, mirror, "Glass")
			r:add({
				shape = "Cylinder",
				cf = at(0, 5.0, 0) * CFrame.Angles(0, math.pi / 2, 0),
				size = Vector3.new(0.06, 1.7, 1.7),
				color = mirror,
				mat = "Glass",
			})
			r:boxAt(at(0.3, 3.6, 0.04), 0.18, 2.4, 0.01, C.White, "Glass")
			for _, sx in { -1, 1 } do
				r:boxAt(at(sx * 0.93, 2.5, 0), 0.16, 5.0, 0.14, r.c1, "Metal")
			end
			r:boxAt(at(0, 0.03, 0), 2.02, 0.16, 0.14, r.c1, "Metal")
			local n = 6
			for i = 0, n - 1 do
				local a1 = i / n * math.pi
				local a2 = (i + 1) / n * math.pi
				local p1 = at(math.cos(a1) * 0.93, 5.0 + math.sin(a1) * 0.93, 0).Position
				local p2 = at(math.cos(a2) * 0.93, 5.0 + math.sin(a2) * 0.93, 0).Position
				r:beam(p1, p2, 0.16, 0.14, r.c1, "Metal")
			end
			-- two little wooden feet to stop it sliding
			for _, sx in { -1, 1 } do
				r:block(sx * 0.75 - 0.18, 0, 0.0, sx * 0.75 + 0.18, 0.14, 0.55, r.c2, "Wood")
			end
		end,
	},
	{
		id = "clock_grandfather",
		name = "Grandfather clock",
		cat = "decor",
		price = 250,
		place = "floor",
		size = Vector3.new(2, 7.9, 1.4),
		c1 = "6E4C34",
		c2 = "D4AE5E",
		tags = { "clock" },
		build = function(r: R)
			local dk = shade(r.c1, 0.82)
			-- a plinth with a raised panel
			r:block(-1.0, 0, -0.7, 1.0, 0.35, 0.7, dk, "Wood")
			r:block(-0.9, 0.35, -0.6, 0.9, 2.2, 0.6, r.c1, "Wood")
			r:block(-0.6, 0.75, 0.6, 0.6, 1.8, 0.64, shade(r.c1, 1.15), "Wood")
			r:block(-0.95, 2.1, -0.65, 0.95, 2.25, 0.65, dk, "Wood")
			-- the waist: a back, two sides and a glass door with the pendulum behind it
			r:block(-0.7, 2.25, -0.5, 0.7, 5.0, -0.3, r.c1, "Wood")
			for _, sx in { -1, 1 } do
				r:block(sx * 0.6 - 0.1, 2.25, -0.3, sx * 0.6 + 0.1, 5.0, 0.5, r.c1, "Wood")
			end
			r:block(-0.5, 2.25, 0.3, 0.5, 2.45, 0.5, r.c1, "Wood")
			r:glass(-0.5, 2.45, 0.42, 0.5, 4.85, 0.47)
			r:block(-0.03, 3.1, -0.05, 0.03, 4.95, 0.05, r.c2, "Metal")
			r:cyl(0, 3.0, 0, 0.08, 0.45, "z", r.c2, "Metal")
			for _, x in { -0.25, 0.25 } do
				r:block(x - 0.015, 3.8, -0.05, x + 0.015, 4.95, -0.02, r.c2, "Metal")
				r:cyl(x, 3.7, -0.035, 0.24, 0.12, "y", r.c2, "Metal")
			end
			-- the hood with the face, under an arched top with finials
			r:block(-0.95, 5.0, -0.65, 0.95, 6.8, 0.65, r.c1, "Wood")
			r:block(-0.98, 5.0, -0.68, 0.98, 5.12, 0.68, dk, "Wood")
			r:cyl(0, 5.9, 0.66, 0.04, 1.45, "z", r.c2, "Metal")
			r:cyl(0, 5.9, 0.69, 0.04, 1.25, "z", C.Cream, "SmoothPlastic")
			for i = 0, 11 do
				local a = i * math.pi / 6
				local big = i % 3 == 0
				local s = if big then 0.05 else 0.025
				r:block(
					math.cos(a) * 0.5 - s,
					5.9 + math.sin(a) * 0.5 - s,
					0.71,
					math.cos(a) * 0.5 + s,
					5.9 + math.sin(a) * 0.5 + s,
					0.73,
					C.Black,
					"SmoothPlastic"
				)
			end
			r:boxAt(CFrame.new(0.15, 6.0, 0.73) * CFrame.Angles(0, 0, -1.0), 0.05, 0.4, 0.02, C.Black, "SmoothPlastic")
			r:boxAt(CFrame.new(0, 6.08, 0.74) * CFrame.Angles(0, 0, 0.1), 0.05, 0.36, 0.02, C.Black, "SmoothPlastic")
			r:block(-1.0, 6.8, -0.7, 1.0, 7.0, 0.7, dk, "Wood")
			r:cyl(0, 7.0, 0, 1.2, 1.4, "z", r.c1, "Wood")
			for _, x in { -0.85, 0.85 } do
				r:cyl(x, 7.08, 0.2, 0.16, 0.16, "y", r.c2, "Metal")
				r:ball(x, 7.25, 0.2, 0.2, r.c2, "Metal")
			end
			r:ball(0, 7.75, 0, 0.22, r.c2, "Metal")
		end,
	},
	{
		id = "screen_folding",
		name = "Folding screen",
		cat = "decor",
		price = 90,
		place = "floor",
		size = Vector3.new(4.4, 5.2, 1),
		c1 = "6E4C34",
		c2 = "F2E8D5",
		build = function(r: R)
			-- three framed panels standing in a zigzag, each with a cloth face and two rails
			local pts = {
				Vector3.new(-2.06, 0, 0.3),
				Vector3.new(-0.69, 0, -0.3),
				Vector3.new(0.69, 0, 0.3),
				Vector3.new(2.06, 0, -0.3),
			}
			for i = 1, 3 do
				local a, b = pts[i], pts[i + 1]
				local along = (b - a).Unit
				local a2, b2 = a + along * 0.08, b - along * 0.08
				for _, p in { a2, b2 } do
					r:beam(p + Vector3.new(0, 0, 0), p + Vector3.new(0, 5.1, 0), 0.14, 0.14, r.c1, "Wood")
				end
				r:beam(a2 + Vector3.new(0, 5.05, 0), b2 + Vector3.new(0, 5.05, 0), 0.14, 0.12, r.c1, "Wood")
				r:beam(a2 + Vector3.new(0, 0.5, 0), b2 + Vector3.new(0, 0.5, 0), 0.14, 0.12, r.c1, "Wood")
				r:beam(a2 + Vector3.new(0, 2.9, 0), b2 + Vector3.new(0, 2.9, 0), 0.1, 3.9, r.c2, "Fabric")
				r:beam(a2 + Vector3.new(0, 1.3, 0), b2 + Vector3.new(0, 1.3, 0), 0.12, 0.08, shade(r.c1, 1.2), "Wood")
			end
		end,
	},
	{
		id = "doormat",
		name = "Doormat",
		cat = "decor",
		price = 15,
		place = "floor",
		size = Vector3.new(3, 0.12, 1.8),
		c1 = "C8A46A",
		c2 = "8E6440",
		build = function(r: R)
			-- a bristly mat with a border and two stripes: c1 the mat, c2 the border
			flat(r, r:block(-1.5, 0, -0.9, 1.5, 0.06, 0.9, r.c2, "Fabric"))
			flat(r, r:block(-1.32, 0.06, -0.72, 1.32, 0.1, 0.72, r.c1, "Carpet"))
			for _, z in { -0.4, 0.4 } do
				flat(r, r:block(-1.1, 0.1, z - 0.06, 1.1, 0.12, z + 0.06, r.c2, "Fabric"))
			end
		end,
	},
}

return items
