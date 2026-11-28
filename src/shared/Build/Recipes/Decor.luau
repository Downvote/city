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
		mat = mat or r.mat or "Metal",
	})
end

-- A flat leaf on a stem: the stem runs from `base` to `tip`, where a leaf w long points on
-- outward and droops a little, with a pale vein down its middle.
local function leaf(r: R, base: Vector3, tip: Vector3, w: number, color: Color3)
	rod(r, base, tip, 0.06, shade(color, 0.7), "Grass")
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
		"Grass"
	)
	r:boxAt(cf * CFrame.new(0, 0, w * 0.55), 0.04, 0.11, w * 1.1, shade(color, 1.18), "Grass")
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
	style: string?, -- the look it belongs to (Catalog.Styles)
	build: (r: R) -> (),
}

local items: { Item } = {
	{
		id = "rug_round",
		name = "Round rug",
		cat = "decor",
		style = "cozy",
		price = 60,
		place = "floor",
		size = Vector3.new(6, 0.1, 6),
		c1 = "D08A6C",
		c2 = "F2E8D5",
		tags = { "rug" },
		build = function(r: R)
			-- layers that each sit 0.025 on the last, so no two faces share a plane: a darker
			-- edge, a pale band, the field, and the pattern on top
			flat(r, r:cyl(0, 0.0125, 0, 0.025, 6, "y", shade(r.c1, 0.9), "Carpet"))
			flat(r, r:cyl(0, 0.0375, 0, 0.025, 5.6, "y", r.c2, "Carpet"))
			flat(r, r:cyl(0, 0.0625, 0, 0.025, 5.25, "y", r.c1, "Carpet"))
			local y = 0.0875
			-- a medallion: eight petals round a dark middle, inside a ring of dashes
			r:piece(function(q: R)
				q:box(0, y, 0, 0.5, 0.025, 0.5, shade(r.c1, 0.78), "Carpet")
				q:cyl(0, y, 0, 0.025, 0.8, "y", shade(r.c1, 0.78), "Carpet")
				for i = 0, 7 do
					local a = i * math.pi / 4 + math.pi / 4
					q:boxAt(
						CFrame.new(math.cos(a) * 0.8, y, math.sin(a) * 0.8) * CFrame.Angles(0, -a + math.pi / 4, 0),
						0.46,
						0.025,
						0.46,
						r.c2,
						"Carpet"
					)
				end
				for i = 0, 11 do
					local a = i * math.pi / 6
					q:boxAt(
						CFrame.new(math.cos(a) * 1.3, y, math.sin(a) * 1.3) * CFrame.Angles(0, -a, 0),
						0.14,
						0.025,
						0.4,
						shade(r.c1, 0.8),
						"Carpet"
					)
				end
			end)
			-- a ring of little diamonds out toward the band
			r:piece(function(q: R)
				for i = 0, 7 do
					local a = i * math.pi / 4 + math.pi / 4
					q:boxAt(
						CFrame.new(math.cos(a) * 2.0, y, math.sin(a) * 2.0) * CFrame.Angles(0, -a + math.pi / 4, 0),
						0.42,
						0.025,
						0.42,
						r.c2,
						"Carpet"
					)
				end
			end)
		end,
	},
	{
		id = "rug_long",
		name = "Long rug",
		cat = "decor",
		style = "cozy",
		price = 70,
		place = "floor",
		size = Vector3.new(4, 0.1, 8),
		c1 = "7A9CC6",
		c2 = "F2E8D5",
		tags = { "rug" },
		build = function(r: R)
			-- layers that each sit 0.025 on the last: a darker edge, a pale band, the field, and
			-- the pattern on top (three diamonds in outline and a line round the field)
			flat(r, r:block(-2, 0, -3.8, 2, 0.025, 3.8, shade(r.c1, 0.9), "Carpet"))
			flat(r, r:block(-1.75, 0.025, -3.55, 1.75, 0.05, 3.55, r.c2, "Carpet"))
			flat(r, r:block(-1.55, 0.05, -3.35, 1.55, 0.075, 3.35, r.c1, "Carpet"))
			local y = 0.0875
			r:piece(function(q: R)
				q:block(-1.35, 0.075, -3.15, 1.35, 0.1, -3.03, r.c2, "Carpet")
				q:block(-1.35, 0.075, 3.03, 1.35, 0.1, 3.15, r.c2, "Carpet")
				q:block(-1.35, 0.075, -3.03, -1.23, 0.1, 3.03, r.c2, "Carpet")
				q:block(1.23, 0.075, -3.03, 1.35, 0.1, 3.03, r.c2, "Carpet")
				for _, z in { -2.0, 0, 2.0 } do
					local pts = {
						Vector3.new(0, y, z - 0.78),
						Vector3.new(0.78, y, z),
						Vector3.new(0, y, z + 0.78),
						Vector3.new(-0.78, y, z),
					}
					for k = 1, 4 do
						local a, b = pts[k], pts[k % 4 + 1]
						local d = (b - a).Unit * 0.07
						q:beam(a - d, b + d, 0.14, 0.025, r.c2, "Carpet")
					end
					q:boxAt(
						CFrame.new(0, y, z) * CFrame.Angles(0, math.pi / 4, 0),
						0.42,
						0.025,
						0.42,
						shade(r.c1, 0.78),
						"Carpet"
					)
				end
			end)
			-- tassels at both ends
			r:piece(function(q: R)
				for _, s in { -1, 1 } do
					for i = 0, 8 do
						local x = -1.8 + i * 0.45
						q:block(x - 0.06, 0, s * 3.8, x + 0.06, 0.035, s * 4.0, C.Cream, "Fabric")
					end
				end
			end)
		end,
	},
	{
		id = "plant_small",
		name = "Small plant",
		cat = "decor",
		style = "garden",
		price = 20,
		place = "surface",
		size = Vector3.new(1, 1.5, 1),
		c1 = "C07A60",
		c2 = "6A9A5C",
		tags = { "plant" },
		build = function(r: R)
			-- a pot with a rolled rim on a saucer, soil a little below the rim, and a rosette of
			-- leaves on short stems round a new one still curled up
			r:cyl(0, 0.03, 0, 0.06, 0.8, "y", shade(r.c1, 0.85), "Sandstone")
			r:cyl(0, 0.33, 0, 0.54, 0.6, "y", r.c1, "Sandstone")
			r:cyl(0, 0.62, 0, 0.14, 0.72, "y", shade(r.c1, 1.08), "Sandstone")
			r:cyl(0, 0.64, 0, 0.04, 0.56, "y", C.Soil, "Sand")
			local base = Vector3.new(0, 0.66, 0)
			for i = 0, 6 do
				local a = i * math.pi * 2 / 7 + 0.3
				local high = i % 2 == 0
				local reach = if high then 0.16 else 0.22
				local tip = Vector3.new(math.cos(a) * reach, if high then 1.06 else 0.9, math.sin(a) * reach)
				leaf(r, base, tip, if high then 0.34 else 0.3, if high then r.c2 else shade(r.c2, 0.85))
			end
			r:cone(0, 1.12, 0, 0.42, 0.12, shade(r.c2, 1.12), "Grass")
		end,
	},
	{
		id = "plant_big",
		name = "Big plant",
		cat = "decor",
		style = "garden",
		price = 60,
		place = "floor",
		size = Vector3.new(3.2, 5.4, 3.2),
		c1 = "F2E8D5",
		c2 = "5E8E5A",
		tags = { "plant" },
		build = function(r: R)
			-- a tall pot with a band, and a plant of big flat leaves on long stems
			r:cyl(0, 0.06, 0, 0.12, 1.3, "y", shade(r.c1, 0.8), "Sandstone")
			r:cyl(0, 0.75, 0, 1.3, 1.5, "y", r.c1, "Sandstone")
			r:cyl(0, 1.0, 0, 0.12, 1.56, "y", shade(r.c1, 0.85), "Sandstone")
			r:cyl(0, 1.44, 0, 0.12, 1.62, "y", shade(r.c1, 1.05), "Sandstone")
			r:cyl(0, 1.45, 0, 0.04, 1.4, "y", C.Soil, "Sand")
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
		style = "cozy",
		price = 25,
		place = "surface",
		size = Vector3.new(1, 2, 1),
		c1 = "7A9CC6",
		c2 = "F59EB5",
		tags = { "plant" },
		build = function(r: R)
			r:cyl(0, 0.05, 0, 0.1, 0.4, "y", shade(r.c1, 0.85), "Marble")
			r:ball(0, 0.35, 0, 0.6, r.c1, "Marble")
			r:cyl(0, 0.7, 0, 0.3, 0.26, "y", r.c1, "Marble")
			r:cyl(0, 0.86, 0, 0.04, 0.34, "y", shade(r.c1, 1.1), "Marble")
			local heads = { { 0.28, 1.55, 0.1 }, { -0.25, 1.68, -0.05 }, { 0.05, 1.85, -0.2 }, { -0.08, 1.48, 0.28 } }
			for i, h in heads do
				local top = Vector3.new(h[1], h[2], h[3])
				rod(r, Vector3.new(0, 0.8, 0), top, 0.04, C.DarkLeaf, "Grass")
				r:ball(h[1], h[2], h[3], 0.3, if i % 2 == 0 then C.Yellow else r.c2, "Fabric")
				r:ball(
					h[1],
					h[2] + 0.1,
					h[3],
					0.12,
					if i % 2 == 0 then Color3.fromRGB(224, 154, 94) else C.Yellow,
					"Fabric"
				)
			end
			r:boxAt(CFrame.new(0.2, 1.1, -0.05) * CFrame.Angles(0, 0, -0.7), 0.06, 0.4, 0.18, C.Leaf, "Grass")
			r:boxAt(CFrame.new(-0.18, 1.05, 0.08) * CFrame.Angles(0, 0, 0.7), 0.06, 0.4, 0.18, C.Leaf, "Grass")
		end,
	},
	{
		id = "books_stack",
		name = "Stack of books",
		cat = "decor",
		style = "cozy",
		price = 15,
		place = "surface",
		size = Vector3.new(1.4, 0.8, 1.1),
		c1 = "B8505A",
		c2 = "3E6E58",
		tags = { "books" },
		build = function(r: R)
			-- four hardbacks and a paperback, each with its covers, a spine and a page block
			-- set back from the edges, a ribbon hanging out of one and a pencil left on top
			local covers = {
				r.c1,
				Color3.fromRGB(94, 122, 150),
				r.c2,
				Color3.fromRGB(201, 166, 94),
				Color3.fromRGB(222, 211, 188),
			}
			local turns = { 0, -0.1, 0.12, -0.04, 0.2 }
			local sizes = {
				Vector3.new(1.22, 0.2, 0.9),
				Vector3.new(1.12, 0.16, 0.84),
				Vector3.new(1.16, 0.18, 0.86),
				Vector3.new(1.0, 0.14, 0.76),
				Vector3.new(0.86, 0.12, 0.62),
			}
			local y = 0
			local frames: { CFrame } = {}
			r:piece(function(q: R)
				for i, col in covers do
					local s = sizes[i]
					local w, h, d = s.X, s.Y, s.Z
					local cf = CFrame.new(
						if i % 2 == 0 then 0.03 else -0.02,
						y + h / 2,
						if i % 2 == 0 then -0.02 else 0.02
					) * CFrame.Angles(0, turns[i], 0)
					frames[i] = cf
					local c = 0.03
					q:boxAt(cf * CFrame.new(0, h / 2 - c / 2, 0), w, c, d, col, "Cardboard")
					q:boxAt(cf * CFrame.new(0, -h / 2 + c / 2, 0), w, c, d, col, "Cardboard")
					q:boxAt(cf * CFrame.new(-w / 2 - 0.02, 0, 0), 0.04, h, d + 0.02, shade(col, 0.84), "Cardboard")
					q:boxAt(cf * CFrame.new(0.01, 0, 0), w - 0.08, h - 2 * c, d - 0.06, C.Paper, "Cardboard")
					y += h
				end
			end, nil, "Cardboard")
			-- the ribbon comes out of the fourth book's pages and over its front edge
			local s4 = sizes[4]
			r:boxAt(frames[4] * CFrame.new(0.25, -0.1, s4.Z / 2 + 0.02), 0.06, 0.26, 0.03, C.Red, "Fabric")
			-- a pencil with a pink rubber and a sharpened point
			local pencil = CFrame.new(0.05, y + 0.04, 0.0) * CFrame.Angles(0, 0.5, 0)
			r:add({
				shape = "Cylinder",
				cf = pencil,
				size = Vector3.new(0.7, 0.08, 0.08),
				color = C.Yellow,
				mat = "Wood",
			})
			r:add({
				shape = "Cylinder",
				cf = pencil * CFrame.new(-0.4, 0, 0),
				size = Vector3.new(0.1, 0.08, 0.08),
				color = C.Pink,
				mat = "Cardboard",
			})
			r:add({
				shape = "Cone",
				cf = pencil * CFrame.new(0.42, 0, 0) * CFrame.Angles(0, 0, -math.pi / 2),
				size = Vector3.new(0.08, 0.14, 0.08),
				color = Color3.fromRGB(222, 196, 150),
				mat = "Wood",
			})
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
			r:ball(0, cy, 0, 1.0, r.c1, "Cardboard")
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
				r:ball(dir.X, cy + dir.Y, dir.Z, p[4], r.c2, "Cardboard")
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
		style = "cozy",
		price = 20,
		place = "surface",
		size = Vector3.new(1.2, 1.1, 1.2),
		c1 = "F7F3EA",
		c2 = "D4AE5E",
		tags = { "light" },
		build = function(r: R)
			-- a brass tray with three pillar candles of different heights, each with a pool of
			-- melted wax round its wick and wax run down its side
			r:cyl(0, 0.03, 0, 0.06, 1.16, "y", r.c2, "Metal")
			r:cyl(0, 0.075, 0, 0.03, 1.0, "y", shade(r.c2, 0.88), "Metal")
			local set = { { -0.25, 0.1, 0.8, 0.34 }, { 0.25, 0.05, 0.6, 0.3 }, { 0.02, -0.3, 0.45, 0.32 } }
			local wax = shade(r.c1, 0.97)
			for i, c in set do
				local x, z, h, d = c[1], c[2], c[3], c[4]
				local y0 = 0.09
				r:cyl(x, y0 + h / 2, z, h, d, "y", r.c1, "Plaster")
				r:cyl(x, y0 + h + 0.015, z, 0.03, d - 0.08, "y", shade(r.c1, 0.9), "Plaster")
				for k, len in { 0.14 + i * 0.05, 0.26 - i * 0.04 } do
					local a = math.pi / 8 + (k + i) * 1.9
					local rx, rz = x + math.cos(a) * (d / 2 + 0.005), z + math.sin(a) * (d / 2 + 0.005)
					r:cyl(rx, y0 + h - len / 2 + 0.035, rz, len, 0.05, "y", wax, "Plaster")
					r:ball(rx, y0 + h - len + 0.01, rz, 0.07, wax, "Plaster")
				end
				r:cyl(x, y0 + h + 0.07, z, 0.08, 0.03, "y", C.Black, "Fabric")
				local flame = r:ball(x, y0 + h + 0.17, z, 0.13, C.Warm, "Glass")
				local tip = r:cone(x, y0 + h + 0.27, z, 0.14, 0.09, C.Warm, "Glass")
				glowOnly(tip)
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
		style = "playful",
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
				r:ball(sx * 0.12, 1.12, 0.27, 0.07, C.Black, "Fabric")
			end
			r:ball(0, 1.05, 0.03, 0.62, r.c1, "Fabric")
			r:ball(0, 0.98, 0.27, 0.26, r.c2, "Fabric")
			r:ball(0, 1.02, 0.39, 0.09, C.Black, "Fabric")
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
		style = "cozy",
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
			local ember = r:block(-0.72, 0.3, -0.55, 0.72, 0.4, 0.2, Color3.fromRGB(255, 120, 50), "Glass")
			r:glow(ember, 18, 1.4, Color3.fromRGB(255, 160, 90))
			r:cyl(0, 0.65, -0.35, 1.5, 0.42, "x", C.Bark, "Wood")
			r:cyl(0, 0.65, 0.05, 1.4, 0.38, "x", shade(C.Bark, 1.15), "Wood")
			local top = r:cyl(0, 0.98, -0.15, 1.4, 0.36, "x", C.Bark, "Wood")
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
				r:cyl(x, 5.2, 0.3, 0.5, 0.18, "y", C.White, "Marble")
			end
			r:block(-0.35, 4.75, 0.05, 0.35, 5.35, 0.45, Color3.fromRGB(110, 76, 48), "Wood")
			r:cyl(0, 5.05, 0.46, 0.03, 0.42, "z", C.Cream, "Plaster")
			r:cyl(1.5, 4.95, 0.2, 0.4, 0.4, "y", C.White, "Marble")
			r:ball(1.5, 5.3, 0.2, 0.5, C.Leaf, "Grass")
		end,
	},
	{
		id = "aquarium",
		name = "Fish tank",
		cat = "decor",
		style = "seaside",
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
				r:block(math.min(xa, xb) + 0.15, 0.47, 0.95, math.max(xa, xb) - 0.15, 1.93, 0.99, r.c1, "Wood")
				r:block(sx * 0.12 - 0.03, 0.9, 0.95, sx * 0.12 + 0.03, 1.5, 1.03, C.Gold, "Metal")
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
			r:block(0.8, 2.6, 0.0, 1.0, 2.9, 0.04, C.Black, "Rock")
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
				local body = CFrame.new(f.x, f.y, f.z)
				r:lump(body, 0.42, 0.24, 0.14, f.col, "Marble")
				r:tri(
					Vector3.new(f.x + 0.18, f.y, f.z),
					Vector3.new(f.x + 0.36, f.y + 0.12, f.z),
					Vector3.new(f.x + 0.36, f.y - 0.12, f.z),
					0.04,
					shade(f.col, 0.85),
					"Marble"
				)
				r:ball(f.x - 0.12, f.y + 0.03, f.z + 0.06, 0.05, C.Black, "Rock")
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
		style = "fancy",
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
			r:boxAt(at(0.3, 3.6, 0.05), 0.18, 2.4, 0.04, C.White, "Glass")
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
		style = "fancy",
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
			r:block(-0.98, 4.97, -0.68, 0.98, 5.12, 0.68, dk, "Wood")
			r:cyl(0, 5.9, 0.66, 0.04, 1.45, "z", r.c2, "Metal")
			r:cyl(0, 5.9, 0.69, 0.04, 1.25, "z", C.Cream, "Metal")
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
					"Metal"
				)
			end
			r:boxAt(CFrame.new(0.15, 6.0, 0.73) * CFrame.Angles(0, 0, -1.0), 0.05, 0.4, 0.02, C.Black, "Metal")
			r:boxAt(CFrame.new(0, 6.08, 0.74) * CFrame.Angles(0, 0, 0.1), 0.05, 0.36, 0.02, C.Black, "Metal")
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
		style = "fancy",
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
				r:beam(a2 + Vector3.new(0, 1.3, 0), b2 + Vector3.new(0, 1.3, 0), 0.16, 0.08, shade(r.c1, 1.2), "Wood")
				-- a painted branch of blossom running across the cloth, on the side facing the room
				local n = Vector3.new(-along.Z, 0, along.X)
				if n.Z < 0 then
					n = -n
				end
				local function on(t: number, y: number): Vector3
					return a2:Lerp(b2, t) + Vector3.new(0, y, 0) + n * 0.08
				end
				local twig = Color3.fromRGB(110, 84, 70)
				local bloom = Colors.mix(C.Pink, C.Cream, 0.35)
				local rise = if i == 2 then -0.5 else 0.5
				r:beam(on(0.12, 3.4 - rise), on(0.88, 3.4 + rise), 0.04, 0.06, twig, "Wood")
				r:beam(on(0.45, 3.4 - rise * 0.1), on(0.62, 4.15), 0.04, 0.05, twig, "Wood")
				for k, t in { 0.2, 0.38, 0.55, 0.7, 0.84 } do
					local y = 3.4 - rise + rise * 2 * (t - 0.12) / 0.76 + (if k % 2 == 0 then 0.16 else -0.12)
					r:ball(on(t, y).X, on(t, y).Y, on(t, y).Z, 0.16, if k % 2 == 0 then bloom else C.Pink, "Fabric")
				end
				r:ball(on(0.62, 4.2).X, on(0.62, 4.2).Y, on(0.62, 4.2).Z, 0.14, bloom, "Fabric")
			end
		end,
	},
	{
		id = "doormat",
		name = "Doormat",
		cat = "decor",
		style = "cozy",
		price = 15,
		place = "floor",
		size = Vector3.new(3, 0.12, 1.8),
		c1 = "C8A46A",
		c2 = "8E6440",
		build = function(r: R)
			-- a coir mat: a woven border (c2), the bristle field (c1) in raised rows, and a band of
			-- the border's colour across each end. Its layers miss the 0.06 of a door's threshold.
			flat(r, r:block(-1.5, 0, -0.9, 1.5, 0.03, 0.9, r.c2, "Fabric"))
			flat(r, r:block(-1.32, 0.03, -0.72, 1.32, 0.09, 0.72, shade(r.c1, 0.82), "Carpet"))
			r:piece(function(q: R)
				for i = 0, 12 do
					local z = -0.66 + i * 0.11
					local col = if i == 1 or i == 11 then r.c2 elseif i % 2 == 0 then r.c1 else shade(r.c1, 0.92)
					q:block(-1.26, 0.09, z - 0.035, 1.26, 0.12, z + 0.035, col, "Carpet")
				end
			end)
		end,
	},
}

return items
