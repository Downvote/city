--!strict
-- Particle makers: small pieces that give off an effect (the user: "particle makers"). Each is a
-- neat base with a hidden spot the effect comes out of (Build/Lively.fx, Data/Effects), and the
-- first paint colours what it gives off, so the paint tool turns gold sparkles blue or white snow
-- pink. Every player's own screen makes the effect near the camera (client World/Lively). Rates
-- stay low, so a garden full of them is still light to draw.

local Recipe = require(script.Parent.Parent.Recipe)
local Lively = require(script.Parent.Parent.Lively)
local Colors = require(script.Parent.Parent.Parent.Util.Colors)

local C = Recipe.Colors

type R = Recipe.Recipe
type Prim = Recipe.Prim

local INK = Color3.fromRGB(52, 48, 56)
local IRON = Color3.fromRGB(84, 82, 92)

local function shade(c: Color3, k: number): Color3
	return Colors.shade(c, k)
end

local function mix(a: Color3, b: Color3, t: number): Color3
	return Colors.mix(a, b, t)
end

-- A round rod from a to b.
local function rod(r: R, a: Vector3, b: Vector3, d: number, color: Color3, mat: string?): Prim?
	local v = b - a
	local len = v.Magnitude
	if len < 1e-3 then
		return nil
	end
	local x = v / len
	local up = if math.abs(x.Y) > 0.99 then Vector3.zAxis else Vector3.yAxis
	local z = x:Cross(up).Unit
	local y = z:Cross(x).Unit
	return r:add({
		shape = "Cylinder",
		cf = CFrame.fromMatrix((a + b) / 2, x, y, z),
		size = Vector3.new(len, d, d),
		color = color,
		mat = mat or r.mat or "Metal",
	})
end

-- A cone at a frame, its point along the frame's Y.
local function coneAt(r: R, cf: CFrame, h: number, d: number, color: Color3, mat: string?): Prim
	return r:add({ shape = "Cone", cf = cf, size = Vector3.new(d, h, d), color = color, mat = mat or r.mat or "Wood" })
end

-- A round plinth `d` across and `h` tall: a foot, a body and a lip, the lip's top at h.
local function plinth(r: R, d: number, h: number, color: Color3, mat: string)
	r:cyl(0, 0.06, 0, 0.12, d, "y", shade(color, 0.85), mat)
	r:cyl(0, (0.12 + h - 0.08) / 2, 0, h - 0.2, d * 0.86, "y", color, mat)
	r:cyl(0, h - 0.04, 0, 0.08, d, "y", shade(color, 1.06), mat)
end

type Item = {
	id: string,
	name: string,
	cat: string,
	style: string?,
	price: number,
	place: string,
	size: Vector3,
	c1: string,
	c2: string?,
	tags: { string }?,
	lively: boolean?,
	vip: boolean?,
	build: (r: R) -> (),
}

local items: { Item } = {
	{
		id = "fx_sparkles",
		name = "Sparkle stone",
		cat = "effects",
		style = "fancy",
		price = 120,
		place = "floor",
		size = Vector3.new(1.6, 2.0, 1.6),
		c1 = "F6D58A",
		c2 = "B8B4C4",
		lively = true,
		build = function(r: R)
			plinth(r, 1.5, 0.6, r.c2, "Marble")
			-- a cluster of crystal points, lit from inside
			local glass = mix(r.c1, C.White, 0.45)
			local points = {
				{ 0, 0, 0, 1.1, 0.5 },
				{ 0.25, 0.15, 0.4, 0.7, 0.34 },
				{ -0.28, 0.1, -0.5, 0.6, 0.3 },
				{ -0.2, -0.25, 0.35, 0.55, 0.28 },
				{ 0.22, -0.2, -0.3, 0.5, 0.26 },
			}
			for i, p in points do
				local cf = CFrame.new(p[1], 0.6 + p[4] / 2 - 0.05, p[2]) * CFrame.Angles(p[3] * 0.6, i, p[3])
				local c = coneAt(r, cf, p[4], p[5], glass, "Glass")
				c.transp = 0.15
				if i == 1 then
					r:glow(c, 8, 0.8, r.c1)
				end
			end
			Lively.fx(r, "sparkles", 0, 1.5, 0, { w = 0.9, h = 0.6, d = 0.9 })
		end,
	},
	{
		id = "fx_fireflies",
		name = "Firefly lantern",
		cat = "effects",
		style = "garden",
		price = 140,
		place = "floor",
		size = Vector3.new(1.6, 3.2, 1.6),
		c1 = "E8F08A",
		c2 = "B4B0A8",
		lively = true,
		build = function(r: R)
			local stone = r.c2
			local dk = shade(stone, 0.86)
			-- a stone post lantern: a footing, a post, the light box and a roof with a knob
			r:bevel(-0.7, 0, -0.7, 0.7, 0.2, 0.7, 0.07, dk, "Slate", { wear = 0.94 })
			r:cyl(0, 0.85, 0, 1.3, 0.42, "y", stone, "Slate")
			r:bevel(-0.5, 1.5, -0.5, 0.5, 1.62, 0.5, 0.042, dk, "Slate", { wear = 0.94 })
			for _, sx in { -1, 1 } do
				for _, sz in { -1, 1 } do
					r:block(
						sx * 0.4 - 0.08,
						1.62,
						sz * 0.4 - 0.08,
						sx * 0.4 + 0.08,
						2.3,
						sz * 0.4 + 0.08,
						stone,
						"Slate"
					)
				end
			end
			local light = r:block(-0.3, 1.62, -0.3, 0.3, 2.2, 0.3, mix(r.c1, C.Warm, 0.5), "Glass")
			r:glow(light, 10, 0.8, mix(r.c1, C.Warm, 0.6))
			r:bevel(-0.62, 2.3, -0.62, 0.62, 2.42, 0.62, 0.042, dk, "Slate", { wear = 0.94 })
			r:add({
				shape = "Cone",
				cf = CFrame.new(0, 2.72, 0),
				size = Vector3.new(1.5, 0.6, 1.5),
				color = stone,
				mat = "Slate",
			})
			r:ball(0, 3.08, 0, 0.22, dk, "Slate")
			-- moss on the footing
			for i, p in { { -0.55, 0.45 }, { 0.5, -0.5 }, { 0.45, 0.55 } } do
				r:lump(CFrame.new(p[1], 0.24, p[2]) * CFrame.Angles(0, i, 0), 0.42, 0.18, 0.34, C.Leaf, "Grass")
			end
			Lively.fx(r, "fireflies", 0, 1.9, 0, { w = 1.4, h = 1.2, d = 1.4 })
		end,
	},
	{
		id = "fx_smoke",
		name = "Smoke machine",
		cat = "effects",
		style = "modern",
		price = 110,
		place = "floor",
		size = Vector3.new(1.6, 1.0, 1.2),
		c1 = "D8D6E2",
		c2 = "3A3842",
		lively = true,
		build = function(r: R)
			local box = r.c2
			-- a dark box on rubber feet, a grille at the front, knobs and a lamp
			for _, sx in { -1, 1 } do
				for _, sz in { -1, 1 } do
					r:cyl(sx * 0.6, 0.04, sz * 0.4, 0.08, 0.16, "y", INK, "Rubber")
				end
			end
			r:block(-0.75, 0.08, -0.55, 0.75, 0.8, 0.5, box, "Metal")
			r:block(-0.7, 0.8, -0.5, 0.7, 0.84, 0.45, shade(box, 1.2), "Metal")
			for i = 0, 5 do
				r:block(-0.6, 0.2 + i * 0.09, 0.5, 0.15, 0.24 + i * 0.09, 0.53, shade(box, 0.7), "Metal")
			end
			for i, x in { 0.32, 0.55 } do
				r:cyl(x, 0.55, 0.52, 0.06, 0.14, "z", if i == 1 then C.Metal else C.Red, "Metal")
			end
			local lamp = r:block(0.4, 0.22, 0.5, 0.5, 0.3, 0.53, Color3.fromRGB(120, 220, 140), "Neon")
			r:glow(lamp, 0)
			-- the nozzle on top, and the lead out of the back
			r:cyl(0, 0.92, 0.1, 0.16, 0.3, "y", IRON, "Metal")
			r:cyl(0, 1.02, 0.1, 0.04, 0.22, "y", INK, "Metal")
			rod(r, Vector3.new(0.5, 0.3, -0.55), Vector3.new(0.6, 0.06, -0.58), 0.06, INK, "Rubber")
			Lively.fx(r, "smoke", 0, 1.0, 0.1, { w = 0.3, d = 0.3 })
		end,
	},
	{
		id = "fx_bubbles",
		name = "Bubble machine",
		cat = "effects",
		style = "playful",
		price = 120,
		place = "floor",
		size = Vector3.new(1.6, 1.5, 1.3),
		c1 = "D6EEF8",
		c2 = "8CC8B8",
		lively = true,
		build = function(r: R)
			local body = r.c2
			-- a rounded toy box with a fan grille, a tray of soap and a turning wheel of wands
			r:block(-0.7, 0.1, -0.5, 0.7, 0.9, 0.4, body, "Metal")
			for _, sx in { -1, 1 } do
				r:cyl(sx * 0.7, 0.5, -0.05, 0.8, 0.9, "z", body, "Metal")
			end
			r:block(-0.55, 0, -0.4, 0.55, 0.1, 0.3, shade(body, 0.8), "Metal")
			r:cyl(0, 0.55, -0.52, 0.04, 0.6, "z", shade(body, 0.7), "Metal")
			for k = -2, 2 do
				r:block(k * 0.1 - 0.015, 0.3, -0.56, k * 0.1 + 0.015, 0.8, -0.53, INK, "Metal")
			end
			local tray = r:block(-0.45, 0.35, 0.4, 0.45, 0.5, 0.62, C.Yellow, "Metal")
			tray.collide = false
			local soap = r:block(-0.4, 0.5, 0.43, 0.4, 0.53, 0.59, mix(r.c1, C.White, 0.3), "Glass")
			soap.transp = 0.3
			r:cyl(0.5, 0.95, 0, 0.1, 0.16, "y", C.Red, "Metal")
			local hub = CFrame.new(0, 0.75, 0.52)
			Lively.pivot(r, hub, "spin", { speed = 1.6, axis = "X" })
			Lively.moving(r, 1, function()
				r:cyl(0, 0.75, 0.52, 0.8, 0.1, "x", C.White, "Metal")
				for k = 0, 5 do
					local a = k * math.pi / 3
					local tip = Vector3.new(0, 0.75 + math.cos(a) * 0.34, 0.52 + math.sin(a) * 0.34)
					rod(r, Vector3.new(0, 0.75, 0.52), tip, 0.04, C.White, "Metal")
					r:add({
						shape = "Cylinder",
						cf = CFrame.new(tip),
						size = Vector3.new(0.03, 0.18, 0.18),
						color = if k % 2 == 0 then C.Pink else C.Blue,
						mat = "Metal",
					})
				end
			end)
			Lively.fx(r, "bubbles", 0, 1.0, 0.55, { w = 0.5, d = 0.3 })
		end,
	},
	{
		id = "fx_confetti",
		name = "Confetti popper",
		cat = "effects",
		style = "playful",
		price = 150,
		place = "floor",
		size = Vector3.new(1.6, 2.6, 1.6),
		c1 = "F28CA8",
		c2 = "7FB6E0",
		lively = true,
		build = function(r: R)
			-- a little tripod, a tube on a swivel pointing up and a band of stripes round it
			for k = 0, 2 do
				local a = k * math.pi * 2 / 3
				rod(
					r,
					Vector3.new(math.cos(a) * 0.65, 0, math.sin(a) * 0.65),
					Vector3.new(0, 1.1, 0),
					0.08,
					IRON,
					"Metal"
				)
			end
			r:ball(0, 1.12, 0, 0.24, IRON, "Metal")
			local tube = CFrame.new(0, 1.7, 0.1) * CFrame.Angles(math.rad(12), 0, 0)
			r:add({
				shape = "Cylinder",
				cf = tube * CFrame.Angles(0, 0, math.pi / 2),
				size = Vector3.new(1.3, 0.5, 0.5),
				color = r.c2,
				mat = "Cardboard",
			})
			for k = -1, 1 do
				r:add({
					shape = "Cylinder",
					cf = tube * CFrame.new(0, k * 0.36, 0) * CFrame.Angles(0, 0, math.pi / 2),
					size = Vector3.new(0.12, 0.58, 0.58),
					color = if k == 0 then C.Yellow else r.c1,
					mat = "Cardboard",
				})
			end
			r:add({
				shape = "Cylinder",
				cf = tube * CFrame.new(0, 0.66, 0) * CFrame.Angles(0, 0, math.pi / 2),
				size = Vector3.new(0.06, 0.62, 0.62),
				color = C.White,
				mat = "Cardboard",
			})
			r:add({
				shape = "Cylinder",
				cf = tube * CFrame.new(0, 0.7, 0) * CFrame.Angles(0, 0, math.pi / 2),
				size = Vector3.new(0.03, 0.4, 0.4),
				color = INK,
				mat = "Metal",
			})
			-- a pull string with a tassel
			rod(r, Vector3.new(0.25, 1.2, 0.0), Vector3.new(0.35, 0.8, 0.05), 0.03, C.White, "Fabric")
			r:ball(0.35, 0.76, 0.05, 0.1, C.Yellow, "Fabric")
			Lively.fx(r, "confetti", 0, 2.42, 0.25, { w = 0.3, d = 0.3 })
		end,
	},
	{
		id = "fx_maple",
		name = "Autumn maple",
		cat = "effects",
		style = "garden",
		price = 180,
		place = "floor",
		size = Vector3.new(2.8, 4.4, 2.8),
		c1 = "E08A4E",
		c2 = "8A6A52",
		lively = true,
		build = function(r: R)
			-- a square wooden planter with soil, a crooked trunk and branches
			r:block(-0.8, 0, -0.8, 0.8, 0.9, 0.8, r.c2, "WoodPlanks")
			for _, sz in { -1, 1 } do
				r:block(-0.88, 0.85, sz * 0.81 - 0.07, 0.88, 0.97, sz * 0.81 + 0.07, shade(r.c2, 0.85), "Wood")
				r:block(sz * 0.81 - 0.07, 0.85, -0.74, sz * 0.81 + 0.07, 0.97, 0.74, shade(r.c2, 0.85), "Wood")
			end
			r:block(-0.74, 0.9, -0.74, 0.74, 0.93, 0.74, C.Soil, "Ground")
			r:beam(Vector3.new(0, 0.9, 0), Vector3.new(0.15, 2.2, 0.05), 0.24, 0.24, C.Bark, "Wood")
			r:beam(Vector3.new(0.15, 2.2, 0.05), Vector3.new(-0.1, 2.9, 0), 0.2, 0.2, C.Bark, "Wood")
			r:beam(Vector3.new(0.12, 2.0, 0.05), Vector3.new(0.75, 2.75, 0.2), 0.12, 0.12, C.Bark, "Wood")
			r:beam(Vector3.new(0.0, 2.5, 0.0), Vector3.new(-0.7, 3.0, -0.3), 0.1, 0.1, C.Bark, "Wood")
			-- the crown in autumn shades, a few leaves on the soil already
			local leaves = {
				{ 0, 3.4, 0, 1.9, 1.3 },
				{ 0.7, 3.0, 0.3, 1.2, 0.9 },
				{ -0.7, 3.2, -0.3, 1.3, 1.0 },
				{ 0.2, 3.0, -0.65, 1.1, 0.8 },
				{ -0.3, 3.85, 0.3, 1.0, 0.8 },
			}
			for i, l in leaves do
				local col = shade(r.c1, 0.86 + (i % 3) * 0.08)
				local p =
					r:lump(CFrame.new(l[1], l[2], l[3]) * CFrame.Angles(0, i, 0), l[4], l[5], l[4] * 0.9, col, "Grass")
				p.name = "Leaf"
			end
			for i, p in { { -0.4, 0.3 }, { 0.3, -0.35 }, { 0.45, 0.4 } } do
				r:boxAt(
					CFrame.new(p[1], 0.945, p[2]) * CFrame.Angles(0, i, 0),
					0.22,
					0.03,
					0.16,
					shade(r.c1, 0.9),
					"Grass"
				)
			end
			Lively.fx(r, "leaves", 0, 2.9, 0, { w = 2.0, h = 0.4, d = 2.0 })
		end,
	},
	{
		id = "fx_snow_cloud",
		name = "Snow cloud",
		cat = "effects",
		style = "playful",
		price = 160,
		place = "ceiling",
		size = Vector3.new(2.6, 1.9, 1.8),
		c1 = "F6F8FC",
		c2 = "E6EAF2",
		lively = true,
		build = function(r: R)
			-- a cloud of soft lumps on a fine wire from the ceiling
			r:cyl(0, -0.03, 0, 0.06, 0.3, "y", C.White, "Snow")
			rod(r, Vector3.new(0, -0.06, 0), Vector3.new(0, -0.7, 0), 0.02, Color3.fromRGB(200, 200, 206), "Metal")
			local puffs = {
				{ 0, -1.05, 0, 1.2, 0.8 },
				{ -0.62, -1.2, 0.05, 0.9, 0.62 },
				{ 0.65, -1.18, -0.05, 0.95, 0.66 },
				{ -0.25, -0.88, -0.2, 0.8, 0.6 },
				{ 0.3, -0.9, 0.25, 0.75, 0.55 },
				{ 0, -1.32, 0.1, 1.6, 0.45 },
			}
			for i, p in puffs do
				r:lump(
					CFrame.new(p[1], p[2], p[3]) * CFrame.Angles(0, i, 0),
					p[4],
					p[5],
					p[4] * 0.8,
					if i % 2 == 0 then r.c2 else C.White,
					"Fabric"
				)
			end
			Lively.fx(r, "snow", 0, -1.5, 0, { w = 1.6, h = 0.1, d = 0.9 })
		end,
	},
	{
		id = "fx_mist",
		name = "Mist bowl",
		cat = "effects",
		style = "garden",
		price = 130,
		place = "floor",
		size = Vector3.new(1.8, 1.4, 1.8),
		c1 = "E2ECF0",
		c2 = "9C9AA4",
		lively = true,
		build = function(r: R)
			local stone = r.c2
			-- a shallow stone bowl on a short pedestal, brim full of still water
			r:cyl(0, 0.06, 0, 0.12, 1.0, "y", shade(stone, 0.85), "Slate")
			r:cyl(0, 0.4, 0, 0.6, 0.5, "y", stone, "Slate")
			r:cyl(0, 0.75, 0, 0.1, 0.9, "y", shade(stone, 0.9), "Slate")
			r:cyl(0, 0.925, 0, 0.25, 1.7, "y", stone, "Slate")
			local water = r:cyl(0, 1.065, 0, 0.07, 1.62, "y", Color3.fromRGB(150, 196, 210), "Glass")
			water.transp = 0.2
			-- a rounded lip all round the brim
			for i = 0, 15 do
				local a1, a2 = i / 16 * math.pi * 2, (i + 1) / 16 * math.pi * 2
				local p1 = Vector3.new(math.cos(a1) * 0.84, 1.1, math.sin(a1) * 0.84)
				local p2 = Vector3.new(math.cos(a2) * 0.84, 1.1, math.sin(a2) * 0.84)
				local u = (p2 - p1).Unit * 0.045
				rod(r, p1 - u, p2 + u, 0.1, shade(stone, 1.06), "Slate")
			end
			for i, p in { { 0.3, 0.2 }, { -0.35, -0.1 } } do
				r:ball(p[1], 1.12, p[2], 0.14 + i * 0.03, Color3.fromRGB(110, 106, 120), "Pebble")
			end
			Lively.fx(r, "mist", 0, 1.2, 0, { w = 1.0, d = 1.0 })
		end,
	},
	{
		id = "fx_firepit",
		name = "Fire pit",
		cat = "effects",
		style = "rustic",
		price = 200,
		place = "ground",
		size = Vector3.new(3.0, 1.4, 3.0),
		c1 = "B8AFA2",
		c2 = "8A6448",
		lively = true,
		build = function(r: R)
			-- a gravel pad, a ring of stones, crossed logs with ash and glowing coals under them
			r:cyl(0, 0.04, 0, 0.08, 3.0, "y", Color3.fromRGB(176, 168, 156), "Pebble")
			for i = 0, 9 do
				local a = i / 10 * math.pi * 2
				r:lump(
					CFrame.new(math.cos(a) * 1.15, 0.3, math.sin(a) * 1.15) * CFrame.Angles(0, -a, 0.1),
					0.56,
					0.48,
					0.7,
					shade(r.c1, 0.9 + (i % 3) * 0.06),
					"Slate"
				)
			end
			r:cyl(0, 0.12, 0, 0.08, 1.8, "y", Color3.fromRGB(96, 92, 92), "Slate")
			local coals = r:cyl(0, 0.18, 0, 0.06, 1.2, "y", Color3.fromRGB(232, 110, 60), "Neon")
			r:glow(coals, 16, 1.2, Color3.fromRGB(255, 170, 100))
			for k = 0, 3 do
				local a = k * math.pi / 2 + 0.3
				r:beam(
					Vector3.new(math.cos(a) * 0.75, 0.22, math.sin(a) * 0.75),
					Vector3.new(math.cos(a) * 0.1, 0.62, math.sin(a) * 0.1),
					0.22,
					0.22,
					r.c2,
					"Wood"
				)
			end
			Lively.fx(r, "flames", 0, 0.45, 0, { w = 0.7, d = 0.7 })
			Lively.fx(r, "embers", 0, 0.7, 0, { w = 0.5, d = 0.5 })
		end,
	},
	{
		id = "fx_sunbeam",
		name = "Sunbeam lamp",
		cat = "effects",
		style = "fancy",
		price = 170,
		place = "ceiling",
		size = Vector3.new(2.2, 0.8, 2.2),
		c1 = "FFE6B0",
		c2 = "D6B46A",
		lively = true,
		build = function(r: R)
			-- a brass ring on the ceiling holding a frosted glass disc, with crystal drops round it
			r:cyl(0, -0.08, 0, 0.16, 2.1, "y", r.c2, "Metal")
			r:cyl(0, -0.22, 0, 0.12, 1.9, "y", shade(r.c2, 0.85), "Metal")
			local disc = r:cyl(0, -0.3, 0, 0.06, 1.7, "y", mix(r.c1, C.White, 0.5), "Glass")
			disc.transp = 0.1
			r:glow(disc, 14, 1.0, r.c1)
			for i = 0, 7 do
				local a = i / 8 * math.pi * 2
				local x, z = math.cos(a) * 0.98, math.sin(a) * 0.98
				rod(r, Vector3.new(x, -0.28, z), Vector3.new(x, -0.5, z), 0.02, r.c2, "Metal")
				local drop = r:add({
					shape = "Cone",
					cf = CFrame.new(x, -0.6, z) * CFrame.Angles(math.pi, 0, 0),
					size = Vector3.new(0.12, 0.22, 0.12),
					color = C.Glass,
					mat = "Glass",
				})
				drop.transp = 0.2
			end
			Lively.fx(r, "rays", 0, -0.4, 0, { w = 1.2, d = 1.2 })
		end,
	},
	{
		id = "fx_hearts",
		name = "Heart maker",
		cat = "effects",
		style = "playful",
		price = 130,
		place = "floor",
		size = Vector3.new(1.4, 1.7, 1.0),
		c1 = "F49AB4",
		c2 = "F6E6EE",
		lively = true,
		build = function(r: R)
			-- a heart shaped box on little legs, a bow on top and a slot the hearts come out of
			for _, sx in { -1, 1 } do
				r:cyl(sx * 0.3, 0.12, 0, 0.24, 0.12, "y", r.c2, "Metal")
			end
			local heart = CFrame.new(0, 0.85, 0)
			r:boxAt(heart * CFrame.Angles(0, 0, math.pi / 4), 0.7, 0.7, 0.6, r.c1, "Metal")
			for _, sx in { -1, 1 } do
				r:cyl(sx * 0.25, 1.1, 0, 0.6, 0.7, "z", r.c1, "Metal")
			end
			r:boxAt(
				heart * CFrame.new(0, 0.05, 0.32) * CFrame.Angles(0, 0, math.pi / 4),
				0.36,
				0.36,
				0.03,
				r.c2,
				"Metal"
			)
			for _, sx in { -1, 1 } do
				r:cyl(sx * 0.13, 1.1, 0.32, 0.03, 0.36, "z", r.c2, "Metal")
			end
			r:block(-0.25, 1.42, -0.05, 0.25, 1.46, 0.05, INK, "Metal")
			for _, sx in { -1, 1 } do
				r:lump(
					CFrame.new(sx * 0.16, 1.52, -0.2) * CFrame.Angles(0, 0, sx * 0.5),
					0.26,
					0.14,
					0.1,
					C.Yellow,
					"Fabric"
				)
			end
			r:ball(0, 1.52, -0.2, 0.1, C.Yellow, "Fabric")
			Lively.fx(r, "hearts", 0, 1.5, 0, { w = 0.4, d = 0.2 })
		end,
	},
	{
		id = "fx_blossom",
		name = "Blossom bough",
		cat = "effects",
		style = "garden",
		price = 160,
		place = "ceiling",
		size = Vector3.new(3.4, 2.0, 1.4),
		c1 = "F6C2D2",
		c2 = "7A5A44",
		lively = true,
		build = function(r: R)
			-- a branch hung level on two cords, twigs off it and clusters of blossom
			for _, x in { -1.1, 1.1 } do
				rod(r, Vector3.new(x, 0, 0), Vector3.new(x, -0.9, 0), 0.03, Color3.fromRGB(220, 210, 196), "Fabric")
				r:cyl(x, -0.03, 0, 0.06, 0.16, "y", r.c2, "Wood")
			end
			r:beam(Vector3.new(-1.6, -0.95, 0), Vector3.new(1.6, -0.9, 0.05), 0.16, 0.16, r.c2, "Wood")
			local twigs = {
				{ -1.2, -0.95, -0.9, -1.45, 0.4 },
				{ -0.3, -0.93, 0.1, -1.4, -0.4 },
				{ 0.5, -0.92, 0.9, -1.5, 0.3 },
				{ 1.3, -0.91, 1.5, -1.3, -0.3 },
			}
			for i, t in twigs do
				r:beam(Vector3.new(t[1], t[2], 0), Vector3.new(t[3], t[4], t[5]), 0.07, 0.07, r.c2, "Wood")
				for k = 0, 2 do
					local x = t[3] + (k - 1) * 0.18
					local y = t[4] + (k % 2) * 0.12
					r:lump(
						CFrame.new(x, y, t[5] + (k - 1) * 0.1) * CFrame.Angles(0, i + k, 0),
						0.32,
						0.26,
						0.3,
						shade(r.c1, 0.95 + k * 0.04),
						"Fabric"
					)
				end
				r:ball(t[3], t[4] + 0.06, t[5], 0.08, C.Yellow, "Fabric")
			end
			Lively.fx(r, "petals", 0, -1.45, 0, { w = 2.6, h = 0.1, d = 0.9 })
		end,
	},
}

return items
