--!strict
-- Lamps and lights. The part that shines (a shade, a bulb or a flame) is marked with r:glow,
-- so it lights up after dark. Ceiling lights hang down from the origin (negative y).
-- c1 is the shade or main body, c2 the stand or metal.

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
		id = "lamp_floor",
		name = "Floor lamp",
		cat = "lights",
		price = 70,
		place = "floor",
		size = Vector3.new(1.8, 6.1, 1.8),
		c1 = "F2E1C4",
		c2 = "B08A4A",
		tags = { "light" },
		build = function(r: R)
			r:cyl(0, 0.1, 0, 0.2, 1.3, "y", r.c2, "Metal")
			r:cyl(0, 0.27, 0, 0.14, 0.7, "y", r.c2, "Metal")
			r:cyl(0, 2.6, 0, 4.8, 0.16, "y", r.c2, "Metal")
			r:cyl(0, 4.7, 0, 0.2, 0.3, "y", r.c2, "Metal")
			r:ball(0, 4.95, 0, 0.45, C.Warm, "SmoothPlastic")
			local lampshade = r:cyl(0, 5.35, 0, 1.1, 1.6, "y", r.c1, "Fabric")
			r:glow(lampshade, 16, 1.2)
			r:cyl(0, 5.95, 0, 0.1, 1.3, "y", shade(r.c1, 0.9), "Fabric")
		end,
	},
	{
		id = "lamp_table",
		name = "Table lamp",
		cat = "lights",
		price = 40,
		place = "surface",
		size = Vector3.new(1.3, 2, 1.3),
		c1 = "F7F3EA",
		c2 = "7A9CC6",
		tags = { "light" },
		build = function(r: R)
			r:cyl(0, 0.05, 0, 0.1, 0.55, "y", r.c2, "SmoothPlastic")
			r:ball(0, 0.45, 0, 0.8, r.c2, "SmoothPlastic")
			r:cyl(0, 1.0, 0, 0.4, 0.12, "y", C.Gold, "Metal")
			local lampshade = r:cyl(0, 1.55, 0, 0.65, 1.2, "y", r.c1, "Fabric")
			r:glow(lampshade, 12, 1)
			r:ball(0, 1.92, 0, 0.14, C.Gold, "Metal")
		end,
	},
	{
		id = "lamp_desk",
		name = "Desk lamp",
		cat = "lights",
		price = 45,
		place = "surface",
		size = Vector3.new(1.2, 1.8, 1.6),
		c1 = "D9805F",
		c2 = "45454A",
		tags = { "light" },
		build = function(r: R)
			r:cyl(0, 0.06, -0.35, 0.12, 0.9, "y", r.c2, "Metal")
			r:beam(Vector3.new(0, 0.12, -0.35), Vector3.new(0, 1.3, -0.6), 0.1, 0.1, r.c1, "Metal")
			r:ball(0, 1.3, -0.6, 0.18, r.c2, "Metal")
			r:beam(Vector3.new(0, 1.3, -0.6), Vector3.new(0, 1.5, 0.4), 0.1, 0.1, r.c1, "Metal")
			r:cyl(0, 1.55, 0.45, 0.15, 0.32, "y", r.c1, "Metal")
			r:cyl(0, 1.32, 0.45, 0.35, 0.65, "y", r.c1, "Metal")
			local bulb = r:ball(0, 1.12, 0.45, 0.34, C.Warm, "SmoothPlastic")
			r:glow(bulb, 10, 1)
		end,
	},
	{
		id = "light_ceiling",
		name = "Ceiling light",
		cat = "lights",
		price = 60,
		place = "ceiling",
		size = Vector3.new(1.9, 0.8, 1.9),
		c1 = "FFF4DC",
		c2 = "C9A35A",
		tags = { "light" },
		build = function(r: R)
			r:cyl(0, -0.05, 0, 0.1, 1.0, "y", r.c2, "Metal")
			local dome = r:cyl(0, -0.35, 0, 0.5, 1.8, "y", r.c1, "Glass")
			r:glow(dome, 18, 1.3)
			r:cyl(0, -0.66, 0, 0.12, 1.3, "y", r.c1, "Glass")
			r:ball(0, -0.75, 0, 0.12, r.c2, "Metal")
		end,
	},
	{
		id = "lamp_pendant",
		name = "Pendant lamp",
		cat = "lights",
		price = 70,
		place = "ceiling",
		size = Vector3.new(1.8, 3.2, 1.8),
		c1 = "E0B04A",
		c2 = "45454A",
		tags = { "light" },
		build = function(r: R)
			r:cyl(0, -0.06, 0, 0.12, 0.6, "y", r.c2, "Metal")
			r:cyl(0, -1.16, 0, 2.1, 0.06, "y", r.c2, "SmoothPlastic")
			-- a stepped dome for a shade
			r:cyl(0, -2.325, 0, 0.25, 0.5, "y", r.c1, "Metal")
			r:cyl(0, -2.575, 0, 0.25, 1.1, "y", r.c1, "Metal")
			r:cyl(0, -2.825, 0, 0.25, 1.7, "y", r.c1, "Metal")
			local bulb = r:ball(0, -2.95, 0, 0.45, C.Warm, "SmoothPlastic")
			r:glow(bulb, 16, 1.2)
		end,
	},
	{
		id = "chandelier",
		name = "Chandelier",
		cat = "lights",
		price = 400,
		place = "ceiling",
		size = Vector3.new(3.4, 2.8, 3.4),
		c1 = "DEB252",
		c2 = "F7F3EA",
		tags = { "light" },
		build = function(r: R)
			r:cyl(0, -0.06, 0, 0.12, 0.7, "y", r.c1, "Metal")
			-- a short chain
			for i = 0, 2 do
				local y = -0.25 - i * 0.36
				if i % 2 == 0 then
					r:cyl(0, y, 0, 0.36, 0.12, "y", r.c1, "Metal")
				else
					r:ball(0, y, 0, 0.2, r.c1, "Metal")
				end
			end
			r:ball(0, -1.4, 0, 0.55, r.c1, "Metal")
			r:cyl(0, -1.95, 0, 0.8, 0.35, "y", r.c1, "Metal")
			r:ball(0, -2.4, 0, 0.5, r.c1, "Metal")
			r:ball(0, -2.65, 0, 0.2, r.c1, "Metal")
			-- six curved arms, each with a candle
			for i = 0, 5 do
				local a = i * math.pi / 3
				local cx, cz = math.cos(a), math.sin(a)
				r:beam(
					Vector3.new(cx * 0.15, -2.25, cz * 0.15),
					Vector3.new(cx * 0.9, -2.15, cz * 0.9),
					0.1,
					0.1,
					r.c1,
					"Metal"
				)
				r:beam(
					Vector3.new(cx * 0.9, -2.15, cz * 0.9),
					Vector3.new(cx * 1.4, -1.9, cz * 1.4),
					0.1,
					0.1,
					r.c1,
					"Metal"
				)
				r:cyl(cx * 1.45, -1.85, cz * 1.45, 0.12, 0.36, "y", r.c1, "Metal")
				r:cyl(cx * 1.45, -1.55, cz * 1.45, 0.5, 0.18, "y", r.c2, "SmoothPlastic")
				local flame = r:ball(cx * 1.45, -1.22, cz * 1.45, 0.18, C.Warm, "SmoothPlastic")
				if i == 0 then
					r:glow(flame, 20, 1.5)
				else
					glowOnly(flame)
				end
			end
		end,
	},
	{
		id = "lantern",
		name = "Lantern",
		cat = "lights",
		price = 35,
		place = "surface",
		size = Vector3.new(0.9, 1.5, 0.9),
		c1 = "45454A",
		c2 = "F7F3EA",
		tags = { "light" },
		build = function(r: R)
			r:cyl(0, 0.06, 0, 0.12, 0.8, "y", r.c1, "Metal")
			r:glass(-0.3, 0.12, -0.3, 0.3, 0.95, 0.3)
			for _, sx in { -1, 1 } do
				for _, sz in { -1, 1 } do
					r:box(sx * 0.31, 0.535, sz * 0.31, 0.06, 0.83, 0.06, r.c1, "Metal")
				end
			end
			r:cyl(0, 0.3, 0, 0.36, 0.2, "y", r.c2, "SmoothPlastic")
			local flame = r:ball(0, 0.56, 0, 0.17, C.Warm, "SmoothPlastic")
			r:glow(flame, 10, 1)
			r:cyl(0, 1.0, 0, 0.1, 0.8, "y", r.c1, "Metal")
			r:cyl(0, 1.12, 0, 0.14, 0.5, "y", r.c1, "Metal")
			-- the loop handle
			for _, sx in { -1, 1 } do
				r:block(sx * 0.18 - 0.03, 1.19, -0.03, sx * 0.18 + 0.03, 1.45, 0.03, r.c1, "Metal")
			end
			r:block(-0.21, 1.42, -0.03, 0.21, 1.48, 0.03, r.c1, "Metal")
		end,
	},
	{
		id = "string_lights",
		name = "String lights",
		cat = "lights",
		price = 50,
		place = "wall",
		size = Vector3.new(8, 1.6, 0.5),
		c1 = "4A4A4A",
		c2 = "FFD696",
		tags = { "light" },
		build = function(r: R)
			local z = 0.3
			-- two loops of wire hung from three hooks
			local function wireY(x: number): number
				local xc = if x < 0 then -2 else 2
				local t = (x - xc) / 2
				return 1.4 - 0.75 * (1 - t * t)
			end
			for _, x in { -3.9, 0, 3.9 } do
				r:cyl(x, 1.42, z / 2, z, 0.12, "z", r.c1, "Metal")
			end
			local xs = { -3.9, -3, -2, -1, 0, 1, 2, 3, 3.9 }
			for i = 1, #xs - 1 do
				local a, b = xs[i], xs[i + 1]
				r:beam(Vector3.new(a, wireY(a), z), Vector3.new(b, wireY(b), z), 0.05, 0.05, r.c1, "SmoothPlastic")
			end
			local colours = { r.c2, C.Pink, r.c2, C.Blue, r.c2, C.Yellow, r.c2, Color3.fromRGB(150, 220, 140) }
			for i = 1, 8 do
				local x = -3.5 + (i - 1)
				local bulb = r:ball(x, wireY(x) - 0.16, z, 0.28, colours[i], "SmoothPlastic")
				if i == 1 then
					r:glow(bulb, 12, 0.9)
				else
					glowOnly(bulb)
				end
			end
		end,
	},
	{
		id = "lamp_post",
		name = "Lamp post",
		cat = "lights",
		price = 120,
		place = "ground",
		size = Vector3.new(1.4, 9, 1.4),
		c1 = "2F3B35",
		c2 = "FFE2A8",
		tags = { "light" },
		build = function(r: R)
			r:block(-0.6, 0, -0.6, 0.6, 0.45, 0.6, r.c1, "Metal")
			r:cyl(0, 0.7, 0, 0.5, 0.75, "y", r.c1, "Metal")
			r:cyl(0, 4.1, 0, 6.4, 0.28, "y", r.c1, "Metal")
			r:cyl(0, 7.25, 0, 0.2, 0.5, "y", r.c1, "Metal")
			r:cyl(0, 7.42, 0, 0.14, 0.95, "y", r.c1, "Metal")
			local glass = r:block(-0.36, 7.49, -0.36, 0.36, 8.35, 0.36, r.c2, "Glass")
			r:glow(glass, 24, 1.6)
			for _, sx in { -1, 1 } do
				for _, sz in { -1, 1 } do
					r:box(sx * 0.4, 7.92, sz * 0.4, 0.08, 0.86, 0.08, r.c1, "Metal")
				end
			end
			r:cyl(0, 8.43, 0, 0.16, 1.2, "y", r.c1, "Metal")
			r:cyl(0, 8.6, 0, 0.2, 0.7, "y", r.c1, "Metal")
			r:ball(0, 8.82, 0, 0.3, r.c1, "Metal")
		end,
	},
}

return items
