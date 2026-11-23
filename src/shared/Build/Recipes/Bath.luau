--!strict
-- Bathroom things. c1 is the main body (porcelain, cabinet or tiles), c2 a trim or fabric.

local Recipe = require(script.Parent.Parent.Recipe)
local Colors = require(script.Parent.Parent.Parent.Util.Colors)

local C = Recipe.Colors

type R = Recipe.Recipe

local CHROME = Color3.fromRGB(200, 204, 210)
local PORCELAIN = Color3.fromRGB(250, 249, 246)

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

-- A towel folded over a bar at (x, y, z) running along x, hanging down `drop` on both sides.
local function towel(r: R, x: number, y: number, z: number, w: number, drop: number, color: Color3)
	r:block(x - w / 2, y - drop, z + 0.06, x + w / 2, y, z + 0.13, color, "Fabric")
	r:block(x - w / 2, y - drop * 0.7, z - 0.13, x + w / 2, y, z - 0.06, color, "Fabric")
	r:cyl(x, y, z, w, 0.26, "x", color, "Fabric")
	r:block(x - w / 2 - 0.01, y - drop + 0.12, z + 0.12, x + w / 2 + 0.01, y - drop + 0.2, z + 0.14, C.White, "Fabric")
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
			-- a rounded pedestal under a rounded bowl
			r:block(-0.4, 0, -1.05, 0.4, 1.0, 0.2, r.c1, "SmoothPlastic")
			r:cyl(0, 0.5, 0.2, 1.0, 0.8, "y", r.c1, "SmoothPlastic")
			r:block(-0.62, 0.95, -0.95, 0.62, 1.4, 0.22, r.c1, "SmoothPlastic")
			r:cyl(0, 1.175, 0.22, 0.45, 1.24, "y", r.c1, "SmoothPlastic")
			-- the seat and its lid, closed
			r:block(-0.66, 1.4, -0.86, 0.66, 1.47, 0.24, shade(r.c1, 0.96), "SmoothPlastic")
			r:cyl(0, 1.435, 0.24, 0.07, 1.32, "y", shade(r.c1, 0.96), "SmoothPlastic")
			r:block(-0.62, 1.47, -0.82, 0.62, 1.55, 0.22, r.c2, "SmoothPlastic")
			r:cyl(0, 1.51, 0.22, 0.08, 1.24, "y", r.c2, "SmoothPlastic")
			for _, x in { -0.4, 0.4 } do
				r:block(x - 0.1, 1.45, -0.92, x + 0.1, 1.58, -0.8, CHROME, "Metal")
			end
			-- the tank with a lid and a push button
			r:block(-0.82, 1.45, -1.4, 0.82, 2.95, -0.92, r.c1, "SmoothPlastic")
			r:block(-0.86, 2.95, -1.43, 0.86, 3.1, -0.88, shade(r.c1, 0.95), "SmoothPlastic")
			r:cyl(0, 3.12, -1.15, 0.05, 0.3, "y", CHROME, "Metal")
			r:seat(0, 1.55, -0.1)
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
		c2 = "D4AE5E",
		tags = { "bath" },
		build = function(r: R)
			-- four claw feet
			for _, sx in { -1, 1 } do
				for _, sz in { -1, 1 } do
					r:ball(sx * 1.12, 0.2, sz * 2.25, 0.4, r.c2, "Metal")
					r:block(
						sx * 1.12 - 0.1,
						0.25,
						sz * 2.25 - 0.1,
						sx * 1.12 + 0.1,
						0.6,
						sz * 2.25 + 0.1,
						r.c2,
						"Metal"
					)
				end
			end
			-- a deep tub, rounded underneath at both ends, with a rolled rim
			r:block(-1.55, 0.95, -2.85, 1.55, 2.1, 2.85, r.c1, "SmoothPlastic")
			r:block(-1.55, 0.45, -2.35, 1.55, 0.95, 2.35, r.c1, "SmoothPlastic")
			for _, sz in { -1, 1 } do
				r:cyl(0, 0.95, sz * 2.35, 3.1, 1.0, "x", r.c1, "SmoothPlastic")
			end
			for _, sx in { -1, 1 } do
				r:cyl(sx * 1.52, 2.15, 0, 5.9, 0.32, "z", shade(r.c1, 0.97), "SmoothPlastic")
			end
			for _, sz in { -1, 1 } do
				r:cyl(0, 2.15, sz * 2.86, 3.2, 0.32, "x", shade(r.c1, 0.97), "SmoothPlastic")
			end
			local water = r:block(-1.38, 2.0, -2.7, 1.38, 2.12, 2.7, C.Water, "Glass")
			water.transp = 0.2
			for _, p in { { -0.8, 1.8, 0.5 }, { -0.4, 2.1, 0.35 }, { 0.6, -1.9, 0.45 }, { 0.2, -1.5, 0.3 } } do
				r:ball(p[1], 2.14, p[2], p[3], C.White, "SmoothPlastic")
			end
			-- a rubber duck
			r:ball(0.5, 2.27, 0.8, 0.45, C.Yellow, "Plastic")
			r:ball(0.5, 2.54, 0.95, 0.3, C.Yellow, "Plastic")
			r:block(0.44, 2.5, 1.08, 0.56, 2.56, 1.2, Color3.fromRGB(224, 154, 94), "Plastic")
			-- a tall tap at the back end with a hand shower
			for _, x in { -0.3, 0.3 } do
				r:cyl(x, 2.45, -2.88, 0.4, 0.14, "y", r.c2, "Metal")
				r:cyl(x, 2.68, -2.88, 0.08, 0.24, "y", r.c2, "Metal")
			end
			rod(r, Vector3.new(0, 2.3, -2.88), Vector3.new(0, 2.85, -2.88), 0.14, r.c2, "Metal")
			rod(r, Vector3.new(0, 2.82, -2.9), Vector3.new(0, 2.78, -2.5), 0.12, r.c2, "Metal")
			r:block(-0.36, 2.55, -2.95, 0.36, 2.63, -2.82, r.c2, "Metal")
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
			r:block(-1.8, 0, -1.8, 1.8, 0.3, 1.8, PORCELAIN, "SmoothPlastic")
			r:block(-1.6, 0.3, -1.6, 1.7, 0.32, 1.7, shade(PORCELAIN, 0.94), "SmoothPlastic")
			r:block(0.1, 0.32, -0.2, 0.5, 0.34, 0.2, C.DarkMetal, "Metal")
			-- tiled walls at the back and on the left, with a trim strip
			r:block(-1.8, 0.3, -1.8, 1.8, 7.6, -1.6, r.c1, "CeramicTiles")
			r:block(-1.8, 0.3, -1.6, -1.6, 7.6, 1.8, r.c1, "CeramicTiles")
			r:block(-1.6, 3.0, -1.6, 1.8, 3.15, -1.56, shade(r.c1, 0.8), "CeramicTiles")
			r:block(-1.6, 3.0, -1.6, -1.56, 3.15, 1.8, shade(r.c1, 0.8), "CeramicTiles")
			-- glass on the other two sides, in a slim frame, with a door handle
			r:glass(-1.6, 0.3, 1.68, 1.68, 7.3, 1.76)
			r:glass(1.68, 0.3, -1.6, 1.76, 7.3, 1.68)
			r:block(-1.6, 7.3, 1.64, 1.8, 7.42, 1.8, r.c2, "Metal")
			r:block(1.64, 7.3, -1.6, 1.8, 7.42, 1.64, r.c2, "Metal")
			r:block(1.64, 0.3, 1.64, 1.8, 7.3, 1.8, r.c2, "Metal")
			r:block(-0.02, 0.3, 1.66, 0.04, 7.3, 1.78, r.c2, "Metal")
			r:cyl(-0.2, 3.8, 1.88, 1.4, 0.08, "y", r.c2, "Metal")
			for _, y in { 3.2, 4.4 } do
				r:block(-0.23, y - 0.03, 1.76, -0.17, y + 0.03, 1.88, r.c2, "Metal")
			end
			-- a rain head on an arm, a mixer, and a hand shower on a rail
			rod(r, Vector3.new(0, 6.9, -1.6), Vector3.new(0, 6.9, -0.6), 0.1, CHROME, "Metal")
			r:block(-0.5, 6.78, -1.0, 0.5, 6.86, 0.0, CHROME, "Metal")
			r:block(-0.45, 6.76, -0.95, 0.45, 6.78, -0.05, shade(CHROME, 0.75), "Metal")
			r:cyl(0, 3.9, -1.56, 0.08, 0.5, "z", CHROME, "Metal")
			r:cyl(0, 3.9, -1.5, 0.12, 0.2, "z", CHROME, "Metal")
			r:block(0, 3.86, -1.46, 0.35, 3.94, -1.4, CHROME, "Metal")
			r:cyl(0.9, 4.6, -1.56, 2.2, 0.08, "y", CHROME, "Metal")
			rod(r, Vector3.new(0.9, 5.2, -1.5), Vector3.new(0.9, 5.7, -1.35), 0.12, CHROME, "Metal")
			-- a niche with two bottles
			r:block(-1.6, 3.6, -1.6, -1.0, 3.7, -1.0, PORCELAIN, "SmoothPlastic")
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
					rod(
						r,
						Vector3.new(sx * 1.28, 0.55, sz * 0.72),
						Vector3.new(sx * 1.32, 0, sz * 0.76),
						0.16,
						C.Gold,
						"Metal"
					)
				end
			end
			r:block(-1.45, 0.5, -0.95, 1.45, 2.9, 0.88, r.c1, "Wood")
			-- two drawers with brass pulls
			local front = shade(r.c1, 1.06)
			for _, y in { { 0.6, 1.66 }, { 1.74, 2.8 } } do
				r:block(-1.36, y[1], 0.88, 1.36, y[2], 0.94, front, "Wood")
				r:block(-1.2, y[1] + 0.14, 0.94, 1.2, y[2] - 0.14, 0.95, shade(r.c1, 0.94), "Wood")
				local ym = (y[1] + y[2]) / 2
				r:block(-0.35, ym - 0.04, 0.95, 0.35, ym + 0.04, 1.02, C.Gold, "Metal")
			end
			r:block(-1.5, 2.9, -1.0, 1.5, 3.1, 1.0, r.c2, "Marble")
			-- a round bowl sitting on the top
			r:cyl(0, 3.3, 0.1, 0.4, 1.4, "y", PORCELAIN, "SmoothPlastic")
			r:cyl(0, 3.5, 0.1, 0.02, 1.2, "y", Color3.fromRGB(214, 222, 226), "SmoothPlastic")
			r:cyl(0, 3.12, 0.1, 0.04, 0.9, "y", shade(PORCELAIN, 0.9), "SmoothPlastic")
			-- a tall tap behind it, a soap pump and a rolled towel
			r:cyl(0, 3.5, -0.72, 0.8, 0.16, "y", CHROME, "Metal")
			rod(r, Vector3.new(0, 3.86, -0.72), Vector3.new(0, 3.86, -0.25), 0.12, CHROME, "Metal")
			r:cyl(0, 3.78, -0.25, 0.14, 0.12, "y", CHROME, "Metal")
			rod(r, Vector3.new(0, 3.6, -0.72), Vector3.new(0.3, 3.68, -0.72), 0.06, CHROME, "Metal")
			r:cyl(-1.05, 3.32, -0.6, 0.44, 0.24, "y", C.Cream, "SmoothPlastic")
			r:cyl(-1.05, 3.6, -0.6, 0.12, 0.06, "y", CHROME, "Metal")
			r:cyl(1.05, 3.24, -0.45, 0.28, 0.5, "z", C.White, "Fabric")
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
				r:block(x - 0.1, 0, -0.45, x + 0.1, 0.12, 0.45, r.c1, "Wood")
				r:cyl(x, 0.02, -0.4, 0.04, 0.16, "y", shade(r.c1, 0.7), "Rubber")
				r:cyl(x, 0.02, 0.4, 0.04, 0.16, "y", shade(r.c1, 0.7), "Rubber")
				r:block(x - 0.08, 0.12, -0.08, x + 0.08, 3.35, 0.08, r.c1, "Wood")
				r:cyl(x, 3.42, 0, 0.14, 0.2, "y", shade(r.c1, 0.85), "Wood")
			end
			for _, y in { 3.2, 2.15, 1.1 } do
				r:cyl(0, y, 0, 2.1, 0.1, "x", r.c1, "Wood")
			end
			-- a big towel over the top bar, a hand towel lower down
			towel(r, 0, 3.2, 0, 1.5, 0.95, r.c2)
			towel(r, 0.3, 1.1, 0, 0.8, 0.65, Colors.mix(r.c2, C.White, 0.5))
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
			r:block(-1.3, 0.1, -1.3, 1.3, 3.1, 1.2, r.c1, "Metal")
			r:block(-1.32, 3.1, -1.32, 1.32, 3.2, 1.24, shade(r.c1, 0.94), "Metal")
			-- a control strip: soap drawer, display, buttons and a dial
			r:block(-1.3, 2.55, 1.2, 1.3, 3.1, 1.24, shade(r.c1, 0.92), "Metal")
			r:block(-1.22, 2.65, 1.24, -0.6, 3.0, 1.28, r.c1, "Metal")
			r:block(-1.1, 2.76, 1.28, -0.72, 2.84, 1.3, C.Metal, "Metal")
			r:block(-0.45, 2.72, 1.24, 0.35, 2.98, 1.26, C.Black, "Glass")
			r:block(-0.36, 2.79, 1.26, 0.1, 2.9, 1.265, Color3.fromRGB(120, 200, 140), "Neon")
			r:cyl(0.82, 2.84, 1.27, 0.08, 0.42, "z", r.c2, "Metal")
			r:cyl(0.82, 2.84, 1.32, 0.04, 0.24, "z", C.DarkMetal, "Metal")
			-- the round door, with washing inside
			r:cyl(0, 1.35, 1.24, 0.06, 1.95, "z", shade(r.c1, 0.9), "Metal")
			r:cyl(0, 1.35, 1.28, 0.1, 1.7, "z", r.c2, "Metal")
			r:cyl(0, 1.35, 1.33, 0.04, 1.3, "z", Color3.fromRGB(70, 96, 112), "Glass")
			r:cyl(0.1, 1.15, 1.32, 0.03, 0.6, "z", C.Pink, "Fabric")
			r:cyl(-0.22, 1.3, 1.33, 0.03, 0.42, "z", C.Yellow, "Fabric")
			r:block(0.72, 1.15, 1.32, 0.86, 1.55, 1.4, shade(r.c2, 0.8), "Metal")
			r:block(-1.0, 0.18, 1.2, 1.0, 0.36, 1.23, shade(r.c1, 0.85), "Metal")
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
			-- a woven basket: bands of two shades, a rim and two hand holes
			r:block(-0.7, 0, -0.5, 0.7, 0.08, 0.5, shade(r.c1, 0.75), "Fabric")
			for i = 0, 3 do
				local y = 0.08 + i * 0.28
				r:block(-0.72, y, -0.52, 0.72, y + 0.28, 0.52, if i % 2 == 0 then r.c1 else shade(r.c1, 0.9), "Fabric")
			end
			r:block(-0.8, 1.2, -0.6, 0.8, 1.36, 0.6, shade(r.c1, 0.82), "Fabric")
			for _, sx in { -1, 1 } do
				r:block(sx * 0.72 - 0.02, 0.98, -0.18, sx * 0.72 + 0.02, 1.1, 0.18, shade(r.c1, 0.5), "Fabric")
			end
			-- clothes heaped over the top
			r:ball(-0.3, 1.2, 0.0, 0.8, r.c2, "Fabric")
			r:ball(0.3, 1.22, -0.1, 0.7, C.White, "Fabric")
			r:ball(0.12, 1.3, 0.22, 0.55, C.Pink, "Fabric")
			-- a sleeve hanging over the front
			r:block(0.3, 1.36, 0.3, 0.55, 1.44, 0.65, r.c2, "Fabric")
			r:block(0.3, 0.85, 0.6, 0.55, 1.44, 0.66, r.c2, "Fabric")
		end,
	},
}

return items
