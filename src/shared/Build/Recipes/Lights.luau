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

-- A drum shade from y1 to y2, d across, with thin rims top and bottom; returns the glowing part.
local function drum(r: R, x: number, y1: number, y2: number, z: number, d: number, color: Color3, rim: Color3)
	local body = r:cyl(x, (y1 + y2) / 2, z, y2 - y1, d, "y", color, "Fabric")
	r:cyl(x, y1 + 0.01, z, 0.08, d + 0.08, "y", rim, "Metal")
	r:cyl(x, y2 - 0.01, z, 0.08, d + 0.08, "y", rim, "Metal")
	return body
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
		id = "lamp_floor",
		name = "Floor lamp",
		cat = "lights",
		style = "cozy",
		price = 70,
		place = "floor",
		size = Vector3.new(1.8, 6.1, 1.8),
		c1 = "F2E1C4",
		c2 = "B08E58",
		tags = { "light" },
		build = function(r: R)
			-- three splayed legs meeting at a collar, a slim stem and a drum shade
			for i = 0, 2 do
				local a = i * math.pi * 2 / 3 + math.pi / 2
				local dx, dz = math.cos(a), math.sin(a)
				rod(
					r,
					Vector3.new(dx * 0.72, 0, dz * 0.72),
					Vector3.new(dx * 0.06, 3.3, dz * 0.06),
					0.12,
					r.c2,
					"Metal"
				)
				r:cyl(dx * 0.72, 0.03, dz * 0.72, 0.06, 0.16, "y", C.Black, "Rubber")
			end
			r:cyl(0, 3.3, 0, 0.3, 0.22, "y", shade(r.c2, 0.85), "Metal")
			r:cyl(0, 4.2, 0, 1.6, 0.09, "y", r.c2, "Metal")
			r:cyl(0, 4.95, 0, 0.12, 0.26, "y", r.c2, "Metal")
			r:ball(0, 5.15, 0, 0.42, C.Warm, "Glass")
			local lampshade = drum(r, 0, 4.85, 6.0, 0, 1.6, r.c1, r.c2)
			r:glow(lampshade, 16, 1.2)
			r:cyl(0, 6.05, 0, 0.06, 0.18, "y", r.c2, "Metal")
		end,
	},
	{
		id = "lamp_table",
		name = "Table lamp",
		cat = "lights",
		style = "cozy",
		price = 40,
		place = "surface",
		size = Vector3.new(1.3, 2, 1.3),
		c1 = "F7F3EA",
		c2 = "7A9CC6",
		tags = { "light" },
		build = function(r: R)
			-- a round ceramic base on a brass foot, and a drum shade
			r:cyl(0, 0.04, 0, 0.08, 0.6, "y", C.Gold, "Metal")
			r:ball(0, 0.42, 0, 0.74, r.c2, "Marble")
			r:cyl(0, 0.82, 0, 0.14, 0.34, "y", r.c2, "Marble")
			r:cyl(0, 0.92, 0, 0.06, 0.24, "y", C.Gold, "Metal")
			r:cyl(0, 1.05, 0, 0.2, 0.08, "y", C.Gold, "Metal")
			r:ball(0, 1.22, 0, 0.26, C.Warm, "Glass")
			local lampshade = drum(r, 0, 1.1, 1.9, 0, 1.2, r.c1, C.Gold)
			r:glow(lampshade, 12, 1)
			r:ball(0, 1.95, 0, 0.12, C.Gold, "Metal")
		end,
	},
	{
		id = "lamp_desk",
		name = "Desk lamp",
		cat = "lights",
		style = "modern",
		price = 45,
		place = "surface",
		size = Vector3.new(1.2, 1.8, 1.6),
		c1 = "D08A6C",
		c2 = "45454A",
		tags = { "light" },
		build = function(r: R)
			-- a heavy round foot, two arms with a joint between and a cone shade
			r:cyl(0, 0.05, -0.4, 0.1, 0.8, "y", r.c2, "Metal")
			r:cyl(0, 0.13, -0.4, 0.06, 0.6, "y", shade(r.c2, 1.2), "Metal")
			r:cyl(0, 0.2, -0.4, 0.1, 0.16, "y", r.c2, "Metal")
			rod(r, Vector3.new(0, 0.2, -0.4), Vector3.new(0, 1.28, -0.62), 0.08, r.c1, "Metal")
			r:cyl(0, 1.3, -0.62, 0.16, 0.16, "x", r.c2, "Metal")
			rod(r, Vector3.new(0, 1.3, -0.62), Vector3.new(0, 1.5, 0.32), 0.08, r.c1, "Metal")
			rod(r, Vector3.new(0.06, 0.3, -0.38), Vector3.new(0.06, 1.2, -0.58), 0.03, C.Metal, "Metal")
			r:cyl(0, 1.5, 0.35, 0.12, 0.18, "x", r.c2, "Metal")
			r:cyl(0, 1.44, 0.45, 0.12, 0.3, "y", r.c1, "Metal")
			r:cyl(0, 1.33, 0.45, 0.12, 0.48, "y", r.c1, "Metal")
			r:cyl(0, 1.21, 0.45, 0.14, 0.66, "y", r.c1, "Metal")
			local bulb = r:ball(0, 1.14, 0.45, 0.32, C.Warm, "Glass")
			r:glow(bulb, 10, 1)
		end,
	},
	{
		id = "light_ceiling",
		name = "Ceiling light",
		cat = "lights",
		style = "modern",
		price = 60,
		place = "ceiling",
		size = Vector3.new(1.9, 0.8, 1.9),
		c1 = "FFF4DC",
		c2 = "C9A35A",
		tags = { "light" },
		build = function(r: R)
			-- a ceiling plate and collar (c2), a band, and a glass bowl (c1) in three steps
			-- narrowing to a little finial
			r:cyl(0, -0.04, 0, 0.08, 1.0, "y", r.c2, "Metal")
			r:cyl(0, -0.12, 0, 0.1, 0.5, "y", shade(r.c2, 0.9), "Metal")
			r:cyl(0, -0.2, 0, 0.06, 1.86, "y", r.c2, "Metal")
			local bowl = r:cyl(0, -0.33, 0, 0.2, 1.7, "y", r.c1, "Glass")
			r:glow(bowl, 18, 1.3)
			r:cyl(0, -0.51, 0, 0.16, 1.3, "y", shade(r.c1, 0.97), "Glass")
			r:cyl(0, -0.65, 0, 0.12, 0.8, "y", shade(r.c1, 0.94), "Glass")
			r:ball(0, -0.76, 0, 0.14, r.c2, "Metal")
		end,
	},
	{
		id = "lamp_pendant",
		name = "Pendant lamp",
		cat = "lights",
		style = "modern",
		price = 70,
		place = "ceiling",
		size = Vector3.new(1.8, 3.2, 1.8),
		c1 = "D8B062",
		c2 = "45454A",
		tags = { "light" },
		build = function(r: R)
			r:cyl(0, -0.05, 0, 0.1, 0.6, "y", r.c2, "Metal")
			r:cyl(0, -0.14, 0, 0.08, 0.2, "y", r.c2, "Metal")
			r:cyl(0, -1.15, 0, 1.95, 0.05, "y", C.Black, "Rubber")
			r:cyl(0, -2.17, 0, 0.12, 0.22, "y", r.c2, "Metal")
			-- a smooth stepped dome, white inside
			r:cyl(0, -2.3, 0, 0.16, 0.44, "y", r.c1, "Metal")
			r:cyl(0, -2.45, 0, 0.16, 0.86, "y", r.c1, "Metal")
			r:cyl(0, -2.62, 0, 0.2, 1.26, "y", r.c1, "Metal")
			r:cyl(0, -2.84, 0, 0.26, 1.6, "y", r.c1, "Metal")
			r:cyl(0, -3.0, 0, 0.02, 1.5, "y", C.White, "Glass")
			local bulb = r:ball(0, -2.92, 0, 0.42, C.Warm, "Glass")
			r:glow(bulb, 16, 1.2)
		end,
	},
	{
		id = "chandelier",
		name = "Chandelier",
		cat = "lights",
		style = "fancy",
		price = 400,
		place = "ceiling",
		size = Vector3.new(3.4, 2.8, 3.4),
		c1 = "D4AE5E",
		c2 = "F7F3EA",
		tags = { "light" },
		build = function(r: R)
			r:cyl(0, -0.05, 0, 0.1, 0.8, "y", r.c1, "Metal")
			r:cyl(0, -0.14, 0, 0.1, 0.3, "y", r.c1, "Metal")
			-- a short chain
			for i = 0, 2 do
				local y = -0.3 - i * 0.34
				if i % 2 == 0 then
					r:cyl(0, y, 0, 0.34, 0.1, "y", r.c1, "Metal")
				else
					r:ball(0, y, 0, 0.18, r.c1, "Metal")
				end
			end
			r:ball(0, -1.4, 0, 0.55, r.c1, "Metal")
			r:cyl(0, -1.95, 0, 0.8, 0.32, "y", r.c1, "Metal")
			r:ball(0, -2.4, 0, 0.5, r.c1, "Metal")
			r:ball(0, -2.68, 0, 0.18, r.c1, "Metal")
			-- six curved arms, each with a drip cup, a candle and a hanging drop
			for i = 0, 5 do
				local a = i * math.pi / 3
				local cx, cz = math.cos(a), math.sin(a)
				rod(
					r,
					Vector3.new(cx * 0.15, -2.25, cz * 0.15),
					Vector3.new(cx * 0.9, -2.15, cz * 0.9),
					0.09,
					r.c1,
					"Metal"
				)
				rod(
					r,
					Vector3.new(cx * 0.88, -2.16, cz * 0.88),
					Vector3.new(cx * 1.42, -1.9, cz * 1.42),
					0.09,
					r.c1,
					"Metal"
				)
				r:cyl(cx * 1.45, -1.86, cz * 1.45, 0.08, 0.38, "y", r.c1, "Metal")
				r:cyl(cx * 1.45, -1.55, cz * 1.45, 0.5, 0.16, "y", r.c2, "Plaster")
				local flame = r:ball(cx * 1.45, -1.22, cz * 1.45, 0.16, C.Warm, "Glass")
				if i == 0 then
					r:glow(flame, 20, 1.5)
				else
					glowOnly(flame)
				end
				r:ball(cx * 1.0, -2.36, cz * 1.0, 0.14, Color3.fromRGB(230, 240, 248), "Glass")
			end
		end,
	},
	{
		id = "lantern",
		name = "Lantern",
		cat = "lights",
		style = "rustic",
		price = 35,
		place = "surface",
		size = Vector3.new(0.9, 1.5, 0.9),
		c1 = "45454A",
		c2 = "F7F3EA",
		tags = { "light" },
		build = function(r: R)
			r:block(-0.36, 0, -0.36, 0.36, 0.1, 0.36, r.c1, "Metal")
			r:glass(-0.3, 0.1, -0.3, 0.3, 0.95, 0.3)
			for _, sx in { -1, 1 } do
				for _, sz in { -1, 1 } do
					r:box(sx * 0.31, 0.53, sz * 0.31, 0.06, 0.86, 0.06, r.c1, "Metal")
				end
			end
			-- a candle inside
			r:cyl(0, 0.28, 0, 0.36, 0.2, "y", r.c2, "Glass")
			local flame = r:ball(0, 0.55, 0, 0.16, C.Warm, "Glass")
			r:glow(flame, 10, 1)
			-- a stepped roof and a ring to carry it by
			r:block(-0.38, 0.95, -0.38, 0.38, 1.02, 0.38, r.c1, "Metal")
			r:block(-0.28, 1.02, -0.28, 0.28, 1.1, 0.28, r.c1, "Metal")
			r:block(-0.16, 1.1, -0.16, 0.16, 1.18, 0.16, r.c1, "Metal")
			r:cyl(0, 1.32, 0, 0.05, 0.3, "z", r.c1, "Metal")
			r:block(-0.03, 1.18, -0.03, 0.03, 1.2, 0.03, r.c1, "Metal")
		end,
	},
	{
		id = "string_lights",
		name = "String lights",
		cat = "lights",
		style = "cozy",
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
				r:cyl(x, 1.42, z / 2, z, 0.1, "z", r.c1, "Metal")
			end
			local xs = { -3.9, -3, -2, -1, 0, 1, 2, 3, 3.9 }
			for i = 1, #xs - 1 do
				local a, b = xs[i], xs[i + 1]
				r:beam(Vector3.new(a, wireY(a), z), Vector3.new(b, wireY(b), z), 0.05, 0.05, r.c1, "Rubber")
			end
			local colours = { r.c2, C.Pink, r.c2, C.Blue, r.c2, C.Yellow, r.c2, Color3.fromRGB(150, 220, 140) }
			for i = 1, 8 do
				local x = -3.5 + (i - 1)
				local y = wireY(x)
				r:cyl(x, y - 0.08, z, 0.12, 0.12, "y", r.c1, "Rubber")
				local bulb = r:ball(x, y - 0.24, z, 0.26, colours[i], "Glass")
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
		style = "garden",
		price = 120,
		place = "ground",
		size = Vector3.new(1.4, 9, 1.4),
		c1 = "2F3B35",
		c2 = "FFE2A8",
		tags = { "light" },
		build = function(r: R)
			-- a stepped base, a slim post with collars, and a four sided lantern
			r:block(-0.62, 0, -0.62, 0.62, 0.3, 0.62, r.c1, "Metal")
			r:block(-0.48, 0.3, -0.48, 0.48, 0.55, 0.48, r.c1, "Metal")
			r:cyl(0, 0.85, 0, 0.6, 0.6, "y", r.c1, "Metal")
			r:cyl(0, 1.2, 0, 0.12, 0.46, "y", shade(r.c1, 1.3), "Metal")
			r:cyl(0, 4.2, 0, 6.0, 0.26, "y", r.c1, "Metal")
			r:cyl(0, 6.6, 0, 0.14, 0.4, "y", shade(r.c1, 1.3), "Metal")
			r:cyl(0, 7.25, 0, 0.2, 0.46, "y", r.c1, "Metal")
			r:block(-0.48, 7.35, -0.48, 0.48, 7.48, 0.48, r.c1, "Metal")
			local glass = r:block(-0.36, 7.48, -0.36, 0.36, 8.35, 0.36, r.c2, "Glass")
			r:glow(glass, 24, 1.6)
			for _, sx in { -1, 1 } do
				for _, sz in { -1, 1 } do
					r:box(sx * 0.4, 7.92, sz * 0.4, 0.08, 0.88, 0.08, r.c1, "Metal")
				end
			end
			r:block(-0.52, 8.35, -0.52, 0.52, 8.45, 0.52, r.c1, "Metal")
			r:block(-0.38, 8.45, -0.38, 0.38, 8.55, 0.38, r.c1, "Metal")
			r:block(-0.24, 8.55, -0.24, 0.24, 8.65, 0.24, r.c1, "Metal")
			r:ball(0, 8.82, 0, 0.28, r.c1, "Metal")
		end,
	},
	{
		id = "lantern_wall",
		name = "Porch lantern",
		cat = "lights",
		style = "rustic",
		price = 45,
		place = "wall",
		size = Vector3.new(1, 2.2, 1.3),
		c1 = "2F3B35",
		c2 = "FFE2A8",
		tags = { "light" },
		build = function(r: R)
			-- a lantern on an arm, for beside a door: a back plate, the arm, a glass box with
			-- four bars and a stepped lid. c1 is the iron, c2 the glass.
			r:block(-0.25, 0.7, 0, 0.25, 2.05, 0.08, r.c1, "Metal")
			r:block(-0.06, 1.85, 0.08, 0.06, 1.97, 0.72, r.c1, "Metal")
			r:block(-0.05, 1.68, 0.6, 0.05, 1.85, 0.7, r.c1, "Metal")
			r:block(-0.36, 1.5, 0.29, 0.36, 1.6, 1.01, r.c1, "Metal")
			r:block(-0.22, 1.6, 0.43, 0.22, 1.68, 0.87, r.c1, "Metal")
			local glass = r:block(-0.26, 0.62, 0.39, 0.26, 1.5, 0.91, r.c2, "Glass")
			r:glow(glass, 20, 1.4)
			for _, sx in { -1, 1 } do
				for _, sz in { -1, 1 } do
					r:box(sx * 0.28, 1.06, 0.65 + sz * 0.28, 0.07, 0.88, 0.07, r.c1, "Metal")
				end
			end
			r:block(-0.32, 0.5, 0.33, 0.32, 0.62, 0.97, r.c1, "Metal")
			r:ball(0, 0.42, 0.65, 0.2, r.c1, "Metal")
		end,
	},
}

return items
