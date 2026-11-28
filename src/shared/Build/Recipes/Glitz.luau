--!strict
-- Things to show off (the user: "more enticing types of things"): a disco ball throwing turning
-- spots of light, string lights that twinkle, a jukebox with a rainbow of neon, a dance floor whose
-- tiles change colour, neon signs, a photo booth, a wall of fish and a popcorn cart. What moves,
-- glimmers or gives off something is named for World/Lively (Build/Lively has the names), so it
-- comes alive on each player's own screen near the camera.

local Recipe = require(script.Parent.Parent.Recipe)
local Lively = require(script.Parent.Parent.Lively)
local Colors = require(script.Parent.Parent.Parent.Util.Colors)

local C = Recipe.Colors

type R = Recipe.Recipe
type Prim = Recipe.Prim

local INK = Color3.fromRGB(52, 48, 56)
local CHROME = Color3.fromRGB(214, 218, 226)
local CREAM = Color3.fromRGB(246, 240, 226)

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
		mat = mat or "Metal",
	})
end

-- Rods through a list of points, each run a little past its ends so the joints close. Returns
-- the rods drawn.
local function path(r: R, pts: { Vector3 }, d: number, color: Color3, mat: string?, closed: boolean?): { Prim }
	local out = {}
	local n = #pts
	for i = 1, (if closed then n else n - 1) do
		local a, b = pts[i], pts[i % n + 1]
		local u = (b - a).Unit * (d * 0.45)
		local p = rod(r, a - u, b + u, d, color, mat)
		if p then
			table.insert(out, p)
		end
	end
	return out
end

-- A flat star of eight points: two squares, one turned an eighth, in the frame's XY plane.
local function star(r: R, cf: CFrame, s: number, thick: number, color: Color3, mat: string?)
	r:boxAt(cf, s, s, thick, color, mat)
	r:boxAt(cf * CFrame.Angles(0, 0, math.pi / 4), s, s, thick, color, mat)
end

-- A neon sign's tube: rods round the outline, lit, a light on the first one, a couple that
-- flicker now and then.
local function neon(r: R, pts: { Vector3 }, color: Color3)
	local tubes = path(r, pts, 0.1, color, "Neon", true)
	for i, p in tubes do
		if i == 1 then
			r:glow(p, 10, 0.9, color)
		else
			r:glow(p, 0)
		end
		if i == 4 or i == #tubes - 2 then
			Lively.twinkle(p)
		end
	end
end

-- A sign's clear backing on four standoffs, `w` by `h`, its bottom at y0.
local function backing(r: R, w: number, h: number, y0: number, tint: Color3)
	local plate = r:block(-w / 2, y0, 0.06, w / 2, y0 + h, 0.12, tint, "Glass")
	plate.transp = 0.6
	for _, sx in { -1, 1 } do
		for _, sy in { 0, 1 } do
			r:cyl(sx * (w / 2 - 0.15), y0 + 0.15 + sy * (h - 0.3), 0.07, 0.14, 0.1, "z", CHROME, "Metal")
		end
	end
end

-- A fish facing +X with a tail, a fin and eyes, `len` long.
local function fish(r: R, at: CFrame, len: number, col: Color3)
	r:lump(at, len, len * 0.5, len * 0.32, col, "Marble")
	local tail = at * CFrame.new(-len * 0.5, 0, 0)
	r:tri(
		tail.Position,
		(tail * CFrame.new(-len * 0.32, len * 0.24, 0)).Position,
		(tail * CFrame.new(-len * 0.32, -len * 0.24, 0)).Position,
		0.03,
		shade(col, 0.86),
		"Marble"
	)
	r:tri(
		(at * CFrame.new(-len * 0.1, len * 0.2, 0)).Position,
		(at * CFrame.new(len * 0.12, len * 0.2, 0)).Position,
		(at * CFrame.new(-len * 0.16, len * 0.36, 0)).Position,
		0.02,
		shade(col, 0.86),
		"Marble"
	)
	for _, s in { -1, 1 } do
		local eye = at * CFrame.new(len * 0.3, len * 0.06, s * len * 0.13)
		r:ball(eye.X, eye.Y, eye.Z, len * 0.09, INK, "Marble")
	end
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
		id = "glitz_disco",
		name = "Disco ball",
		cat = "lights",
		style = "playful",
		price = 260,
		place = "ceiling",
		size = Vector3.new(2, 2.4, 2),
		c1 = "D2D6DE",
		c2 = "4A4856",
		tags = { "light", "music" },
		lively = true,
		build = function(r: R)
			-- a mount and a little motor on the ceiling, a short chain down
			r:cyl(0, -0.05, 0, 0.1, 0.5, "y", r.c2, "Metal")
			r:cyl(0, -0.22, 0, 0.24, 0.32, "y", r.c2, "Metal")
			for k = 0, 3 do
				local y = -0.38 - k * 0.12
				r:boxAt(CFrame.new(0, y, 0) * CFrame.Angles(0, k * math.pi / 2, 0), 0.06, 0.13, 0.03, CHROME, "Metal")
			end
			-- the mirror ball, turning, and three coloured spots inside it that sweep the room at night
			local mid = CFrame.new(0, -1.55, 0)
			Lively.pivot(r, mid, "spin", { speed = 0.8 })
			Lively.moving(r, 1, function()
				r:cyl(0, -0.86, 0, 0.12, 0.24, "y", CHROME, "Metal")
				r:ball(0, -1.55, 0, 1.4, r.c1, "Foil")
				local spots =
					{ Color3.fromRGB(250, 170, 200), Color3.fromRGB(150, 200, 250), Color3.fromRGB(250, 226, 150) }
				for k, col in spots do
					local lamp = r:boxAt(
						mid * CFrame.Angles(0, k * math.pi * 2 / 3, 0) * CFrame.Angles(math.rad(40), 0, 0),
						0.2,
						0.2,
						0.2,
						col,
						"Glass"
					)
					lamp.transp = 1
					lamp.collide = false
					r:glow(lamp, 20, 1.6, col)
					local light = lamp.light
					if light then
						light.kind = "spot"
						light.face = "Bottom"
					end
				end
			end)
			Lively.fx(r, "glints", 0, -1.55, 0, { w = 1.3, h = 1.3, d = 1.3 })
		end,
	},
	{
		id = "glitz_twinkle",
		name = "Twinkle lights",
		cat = "lights",
		style = "cozy",
		price = 70,
		place = "wall",
		size = Vector3.new(8, 1.8, 0.5),
		c1 = "FFE6A8",
		c2 = "3E4A3E",
		tags = { "light" },
		lively = true,
		build = function(r: R)
			-- a wire in two swags from three hooks, a bulb hanging at every turn of it
			local pts: { Vector3 } = {}
			for i = 0, 16 do
				local t = i / 16
				table.insert(pts, Vector3.new(-3.8 + 7.6 * t, 1.5 - 0.6 * math.abs(math.sin(t * math.pi * 2)), 0.16))
			end
			for i = 1, 16 do
				local a, b = pts[i], pts[i + 1]
				local u = (b - a).Unit * 0.02
				rod(r, a - u, b + u, 0.04, r.c2, "Rubber")
			end
			for _, i in { 1, 9, 17 } do
				local p = pts[i]
				r:block(p.X - 0.06, p.Y - 0.04, 0, p.X + 0.06, p.Y + 0.12, 0.2, r.c2, "Metal")
			end
			for i = 2, 16 do
				local p = pts[i]
				r:cyl(p.X, p.Y - 0.08, p.Z, 0.12, 0.09, "y", r.c2, "Rubber")
				local bulb = r:lump(CFrame.new(p.X, p.Y - 0.24, p.Z), 0.15, 0.22, 0.15, r.c1, "Neon")
				r:glow(bulb, if i == 9 then 10 else 0, 0.8, r.c1)
				Lively.twinkle(bulb)
			end
		end,
	},
	{
		id = "glitz_jukebox",
		name = "Jukebox",
		cat = "fun",
		style = "playful",
		price = 520,
		place = "floor",
		size = Vector3.new(2.8, 5.2, 1.8),
		c1 = "C77E62",
		c2 = "F2D98C",
		tags = { "music" },
		lively = true,
		build = function(r: R)
			-- a plinth, the cabinet and its round top
			r:block(-1.4, 0, -0.8, 1.4, 0.3, 0.8, INK, "Metal")
			r:block(-1.3, 0.3, -0.75, 1.3, 3.8, 0.7, r.c1, "Wood")
			r:cyl(0, 3.8, -0.025, 1.45, 2.6, "z", r.c1, "Wood")
			for _, sx in { -1, 1 } do
				r:block(sx * 1.3 - 0.12, 0.3, 0.6, sx * 1.3 + 0.04, 3.8, 0.78, r.c2, "Metal")
			end
			-- the window: a dark arch with the records standing in a row behind clear glass
			r:block(-0.9, 2.6, 0.7, 0.9, 3.8, 0.74, Color3.fromRGB(40, 44, 70), "Glass")
			r:cyl(0, 3.8, 0.72, 0.04, 1.8, "z", Color3.fromRGB(40, 44, 70), "Glass")
			local labels = { C.Red, C.Yellow, C.Blue, C.Pink, Color3.fromRGB(120, 200, 140) }
			for i = 0, 4 do
				local x = -0.7 + i * 0.35
				r:cyl(x, 3.3, 0.76, 0.04, 0.42, "z", INK, "Metal")
				r:cyl(x, 3.3, 0.795, 0.03, 0.14, "z", labels[i + 1], "Cardboard")
			end
			local front = r:block(-0.9, 2.6, 0.84, 0.9, 3.8, 0.86, C.Glass, "Glass")
			front.transp = 0.75
			local dome = r:cyl(0, 3.8, 0.85, 0.02, 1.8, "z", C.Glass, "Glass")
			dome.transp = 0.75
			-- an arch of neon round the window, running through the colours
			local arch: { Vector3 } = { Vector3.new(-1.18, 1.3, 0.8) }
			for k = 0, 10 do
				local a = math.pi - k * math.pi / 10
				table.insert(arch, Vector3.new(math.cos(a) * 1.18, 3.8 + math.sin(a) * 1.18, 0.8))
			end
			table.insert(arch, Vector3.new(1.18, 1.3, 0.8))
			for i = 1, #arch - 1 do
				local a, b = arch[i], arch[i + 1]
				local u = (b - a).Unit * 0.05
				local tube = rod(r, a - u, b + u, 0.12, if i % 2 == 0 then C.Pink else C.Blue, "Neon")
				if tube then
					r:glow(tube, if i == 6 then 12 else 0, 0.9, Color3.fromRGB(250, 190, 220))
					Lively.twinkle(tube, true)
				end
			end
			-- the buttons to pick a song, a coin slot, and the speaker grille
			r:block(-0.9, 2.1, 0.7, 0.9, 2.5, 0.78, CREAM, "Metal")
			for row = 0, 1 do
				for k = 0, 6 do
					r:block(
						-0.75 + k * 0.22,
						2.18 + row * 0.16,
						0.78,
						-0.63 + k * 0.22,
						2.28 + row * 0.16,
						0.82,
						if (k + row) % 3 == 0 then C.Red else C.White,
						"Rubber"
					)
				end
			end
			r:block(0.98, 2.15, 0.7, 1.12, 2.45, 0.8, CHROME, "Metal")
			r:block(1.03, 2.2, 0.8, 1.07, 2.4, 0.83, INK, "Metal")
			r:block(-0.95, 0.6, 0.7, 0.95, 1.9, 0.74, Color3.fromRGB(70, 60, 64), "Fabric")
			for i = 0, 5 do
				r:block(-0.95, 0.72 + i * 0.2, 0.74, 0.95, 0.78 + i * 0.2, 0.78, r.c2, "Metal")
			end
			Lively.fx(r, "notes", 0, 5.05, 0, { w = 0.8, d = 0.4, color = CREAM })
		end,
	},
	{
		id = "glitz_dance_floor",
		name = "Light-up dance floor",
		cat = "fun",
		style = "playful",
		price = 400,
		place = "floor",
		size = Vector3.new(6, 0.2, 6),
		c1 = "F4A6C0",
		c2 = "D6DAE2",
		lively = true,
		build = function(r: R)
			-- a dark base, a bright frame round it and sixteen tiles that glow and change colour
			r:block(-2.8, 0, -2.8, 2.8, 0.06, 2.8, INK, "Metal")
			r:block(-3, 0, -3, 3, 0.2, -2.8, r.c2, "Metal")
			r:block(-3, 0, 2.8, 3, 0.2, 3, r.c2, "Metal")
			r:block(-3, 0, -2.8, -2.8, 0.2, 2.8, r.c2, "Metal")
			r:block(2.8, 0, -2.8, 3, 0.2, 2.8, r.c2, "Metal")
			local colours =
				{ r.c1, Color3.fromRGB(150, 200, 246), Color3.fromRGB(250, 222, 140), Color3.fromRGB(160, 222, 170) }
			for i = 0, 3 do
				for j = 0, 3 do
					local x, z = -2.75 + i * 1.4, -2.75 + j * 1.4
					local tile = r:block(x, 0.06, z, x + 1.3, 0.16, z + 1.3, colours[(i + j) % 4 + 1], "Neon")
					Lively.twinkle(tile, true)
				end
			end
		end,
	},
	{
		id = "glitz_neon_heart",
		name = "Neon heart sign",
		cat = "walldecor",
		style = "playful",
		price = 150,
		place = "wall",
		size = Vector3.new(2.6, 2.4, 0.3),
		c1 = "F28CB0",
		c2 = "DDE6EE",
		lively = true,
		build = function(r: R)
			backing(r, 2.5, 2.2, 0.1, r.c2)
			local pts: { Vector3 } = {}
			for k = 0, 23 do
				local t = k / 24 * math.pi * 2
				local x = 16 * math.sin(t) ^ 3
				local y = 13 * math.cos(t) - 5 * math.cos(2 * t) - 2 * math.cos(3 * t) - math.cos(4 * t)
				table.insert(pts, Vector3.new(x * 0.066, 1.36 + y * 0.066, 0.2))
			end
			neon(r, pts, r.c1)
			rod(r, Vector3.new(0, 0.1, 0.1), Vector3.new(0, 0.0, 0.02), 0.04, INK, "Metal")
		end,
	},
	{
		id = "glitz_neon_star",
		name = "Neon star sign",
		cat = "walldecor",
		style = "playful",
		price = 150,
		place = "wall",
		size = Vector3.new(2.6, 2.6, 0.3),
		c1 = "F6D878",
		c2 = "DDE6EE",
		lively = true,
		build = function(r: R)
			backing(r, 2.5, 2.4, 0.1, r.c2)
			local pts: { Vector3 } = {}
			for k = 0, 9 do
				local a = math.pi / 2 + k * math.pi / 5
				local rad = if k % 2 == 0 then 1.1 else 0.46
				table.insert(pts, Vector3.new(math.cos(a) * rad, 1.25 + math.sin(a) * rad, 0.2))
			end
			neon(r, pts, r.c1)
			rod(r, Vector3.new(0, 0.1, 0.1), Vector3.new(0, 0.0, 0.02), 0.04, INK, "Metal")
		end,
	},
	{
		id = "glitz_photo_booth",
		name = "Photo booth",
		cat = "fun",
		style = "playful",
		price = 600,
		place = "floor",
		size = Vector3.new(4.2, 6.8, 3.4),
		c1 = "E89AA6",
		c2 = "F6E3A8",
		tags = { "seat" },
		lively = true,
		build = function(r: R)
			local wall = r.c1
			-- the booth: a floor plate, walls on three sides and half the front, a roof
			r:block(-2.1, 0, -1.7, 2.1, 0.15, 1.7, INK, "Metal")
			r:block(-2.1, 0.15, -1.7, 2.1, 6.0, -1.5, wall, "Fabric")
			r:block(-2.1, 0.15, -1.5, -1.9, 6.0, 1.7, wall, "Fabric")
			r:block(1.9, 0.15, -1.5, 2.1, 6.0, 1.7, wall, "Fabric")
			r:block(0.1, 0.15, 1.5, 1.9, 6.0, 1.7, wall, "Fabric")
			r:block(-1.9, 5.0, 1.5, 0.1, 6.0, 1.7, wall, "Fabric")
			r:block(-2.2, 6.0, -1.8, 2.2, 6.2, 1.8, r.c2, "Fabric")
			-- a lit sign box on top with stars and a camera on it, bulbs along its edge
			local sign = r:block(-1.6, 6.2, 0.9, 1.6, 6.75, 1.4, CREAM, "Metal")
			r:glow(sign, 10, 0.8)
			for _, x in { -1.1, 1.1 } do
				star(r, CFrame.new(x, 6.47, 1.42), 0.32, 0.03, r.c1, "Metal")
			end
			r:block(-0.3, 6.32, 1.4, 0.3, 6.62, 1.44, INK, "Metal")
			r:cyl(0, 6.47, 1.47, 0.04, 0.18, "z", CHROME, "Metal")
			for k = 0, 6 do
				local bulb = r:ball(-1.5 + k * 0.5, 6.78, 1.15, 0.14, C.Yellow, "Neon")
				r:glow(bulb, 0)
				Lively.twinkle(bulb)
			end
			-- a curtain on a rail across the doorway, pulled to one side
			r:cyl(-0.9, 4.9, 1.6, 2.0, 0.06, "x", CHROME, "Metal")
			for k = 0, 4 do
				local x = -1.8 + k * 0.26
				r:noCollide(
					r:block(
						x,
						1.2,
						if k % 2 == 0 then 1.52 else 1.58,
						x + 0.28,
						4.88,
						if k % 2 == 0 then 1.58 else 1.64,
						Color3.fromRGB(192, 90, 100),
						"Fabric"
					)
				)
			end
			-- inside: a stool, and the camera on the back wall with its screen and flash
			r:cyl(-0.9, 0.85, 0.5, 1.4, 0.18, "y", CHROME, "Metal")
			r:cyl(-0.9, 1.6, 0.5, 0.14, 0.9, "y", r.c2, "Fabric")
			r:seat(-0.9, 1.67, 0.5, 180)
			r:block(-1.4, 2.2, -1.5, -0.4, 3.4, -1.4, INK, "Metal")
			local screen = r:block(-1.3, 2.3, -1.4, -0.5, 2.9, -1.37, Color3.fromRGB(120, 150, 200), "Cardboard")
			r:glow(screen, 0)
			r:cyl(-0.9, 3.12, -1.38, 0.06, 0.24, "z", CHROME, "Metal")
			local flash = r:block(-1.2, 3.25, -1.4, -0.6, 3.36, -1.36, C.White, "Neon")
			Lively.twinkle(flash)
			-- outside: a coin box, the slot the photos come out of and a strip waiting in it
			r:block(0.4, 2.6, 1.7, 0.8, 3.2, 1.8, CHROME, "Metal")
			r:block(0.55, 2.95, 1.8, 0.65, 3.1, 1.83, INK, "Metal")
			r:block(0.9, 1.8, 1.7, 1.5, 1.9, 1.76, INK, "Metal")
			r:block(1.05, 1.0, 1.7, 1.35, 1.82, 1.74, C.White, "Cardboard")
			for k = 0, 3 do
				r:block(
					1.1,
					1.05 + k * 0.19,
					1.74,
					1.3,
					1.2 + k * 0.19,
					1.77,
					if k % 2 == 0 then C.Blue else C.Pink,
					"Cardboard"
				)
			end
			star(r, CFrame.new(1.0, 4.1, 1.72), 0.6, 0.03, r.c2, "Fabric")
		end,
	},
	{
		id = "glitz_aquarium",
		name = "Aquarium wall",
		cat = "decor",
		style = "seaside",
		price = 900,
		place = "floor",
		size = Vector3.new(8, 7, 1.8),
		c1 = "5E7A8C",
		c2 = "7CC6DA",
		lively = true,
		build = function(r: R)
			local frame = Color3.fromRGB(46, 52, 60)
			-- a cabinet with four doors under the tank
			r:block(-4, 0, -0.9, 4, 1.2, 0.9, r.c1, "Wood")
			for k = 0, 3 do
				local x = -3.85 + k * 1.95
				r:block(x, 0.12, 0.9, x + 1.8, 1.08, 0.94, shade(r.c1, 1.1), "Wood")
				r:block(x + 0.85, 0.5, 0.94, x + 0.95, 0.7, 0.98, CHROME, "Metal")
			end
			-- the tank: a frame, sand, rocks, coral and weed, the water and the clear front
			r:block(-4, 1.2, -0.9, 4, 1.35, 0.9, frame, "Metal")
			r:block(-3.85, 1.35, -0.75, 3.85, 1.65, 0.75, Color3.fromRGB(230, 210, 166), "Sand")
			for _, sx in { -1, 1 } do
				for _, sz in { -1, 1 } do
					r:block(
						sx * 3.94 - 0.06,
						1.35,
						sz * 0.84 - 0.06,
						sx * 3.94 + 0.06,
						6.4,
						sz * 0.84 + 0.06,
						frame,
						"Metal"
					)
				end
			end
			r:block(-4, 6.4, -0.9, 4, 6.6, 0.9, frame, "Metal")
			r:block(-4, 6.6, -0.9, 4, 7.0, 0.9, r.c1, "Wood")
			local strip = r:block(-3.8, 6.36, -0.7, 3.8, 6.4, 0.7, C.White, "Neon")
			r:glow(strip, 14, 0.9, Color3.fromRGB(170, 220, 250))
			local rocks = { { -2.6, 2.0, -0.3, 1.2 }, { 1.4, 1.9, -0.4, 1.0 }, { 3.1, 1.8, 0.2, 0.7 } }
			for i, p in rocks do
				r:lump(
					CFrame.new(p[1], p[2], p[3]) * CFrame.Angles(0, i, 0.2),
					p[4] * 1.3,
					p[4],
					p[4],
					Color3.fromRGB(150, 146, 150),
					"Slate"
				)
			end
			local corals = {
				{ at = Vector3.new(-1.4, 2.0, 0.1), col = C.Pink },
				{ at = Vector3.new(-1.1, 2.3, -0.3), col = Color3.fromRGB(240, 150, 100) },
				{ at = Vector3.new(2.2, 2.1, 0.3), col = Color3.fromRGB(246, 200, 110) },
				{ at = Vector3.new(0.2, 1.95, -0.4), col = Color3.fromRGB(200, 150, 220) },
			}
			for i, c in corals do
				local col = c.col
				for k = 0, 2 do
					r:lump(
						CFrame.new(c.at.X + (k - 1) * 0.18, c.at.Y + k * 0.15, c.at.Z)
							* CFrame.Angles(0, i + k, 0.3 * (k - 1)),
						0.24,
						0.6,
						0.24,
						shade(col, 0.92 + k * 0.06),
						"Rock"
					)
				end
			end
			-- weed in clumps: a stem that bends as it grows, a leaf or two off it
			for k = 0, 7 do
				local x, z = -3.4 + k * 0.95, -0.5 + (k % 3) * 0.2
				local top = 2.8 + (k % 4) * 0.45
				local lean = if k % 2 == 0 then 0.2 else -0.2
				local col = if k % 2 == 0 then C.Leaf else C.DarkLeaf
				local mid = Vector3.new(x + lean, (1.65 + top) / 2, z)
				r:beam(Vector3.new(x, 1.65, z), mid, 0.08, 0.16, col, "Grass")
				r:beam(mid, Vector3.new(x - lean * 0.5, top, z + 0.05), 0.07, 0.14, col, "Grass")
				r:lump(
					CFrame.new(mid + Vector3.new(lean * 0.8, 0.2, 0)) * CFrame.Angles(0, 0, -lean * 3),
					0.3,
					0.12,
					0.1,
					col,
					"Grass"
				)
			end
			r:block(0.6, 1.65, 0.1, 1.0, 1.9, 0.4, Color3.fromRGB(150, 110, 70), "Wood")
			r:block(0.58, 1.9, 0.08, 1.02, 1.98, 0.42, C.Gold, "Metal")
			for _, b in { { -2.8, -0.3 }, { 2.4, 0.1 } } do
				r:ball(b[1], 1.7, b[2], 0.22, Color3.fromRGB(120, 116, 124), "Slate")
				Lively.fx(r, "tankbubbles", b[1], 1.8, b[2], { w = 0.2, d = 0.2 })
			end
			local water = r:block(-3.85, 1.65, -0.75, 3.85, 6.36, 0.75, r.c2, "Glass")
			water.transp = 0.65
			water.collide = false
			local glass = r:block(-3.86, 1.35, 0.78, 3.86, 6.4, 0.8, C.Glass, "Glass")
			glass.transp = 0.85
			-- the fish, swimming the length of the tank and turning round at the ends
			local school = {
				{
					at = Vector3.new(0, 4.8, 0.2),
					reach = 2.6,
					speed = 0.35,
					phase = 0,
					len = 0.6,
					col = Color3.fromRGB(246, 200, 76),
				},
				{
					at = Vector3.new(0.5, 3.6, -0.3),
					reach = 2.2,
					speed = 0.5,
					phase = 2,
					len = 0.5,
					col = Color3.fromRGB(238, 140, 70),
				},
				{
					at = Vector3.new(-0.5, 2.7, 0.35),
					reach = 2.8,
					speed = 0.28,
					phase = 4,
					len = 0.7,
					col = Color3.fromRGB(110, 170, 230),
				},
				{
					at = Vector3.new(1.0, 5.6, -0.2),
					reach = 1.6,
					speed = 0.6,
					phase = 1,
					len = 0.3,
					col = Color3.fromRGB(244, 160, 190),
				},
			}
			for g, f in school do
				local at = CFrame.new(f.at)
				Lively.pivot(
					r,
					at,
					"pace",
					{ speed = f.speed, amount = f.reach, axis = "X", phase = f.phase, group = g }
				)
				Lively.moving(r, g, function()
					if g == 4 then
						for k = 0, 2 do
							fish(r, at * CFrame.new(k * 0.25 - 0.25, (k % 2) * 0.2, (k - 1) * 0.2), f.len, f.col)
						end
					else
						fish(r, at, f.len, f.col)
					end
				end)
			end
		end,
	},
	{
		id = "glitz_popcorn",
		name = "Popcorn cart",
		cat = "fun",
		style = "playful",
		price = 350,
		place = "floor",
		size = Vector3.new(3.2, 5.6, 2.2),
		c1 = "D86A64",
		c2 = "F6E3A8",
		lively = true,
		build = function(r: R)
			-- two big wheels at one end, legs at the other, a handle to push it by
			for _, sz in { -1, 1 } do
				r:cyl(-1.0, 0.7, sz * 1.0, 0.12, 1.4, "z", INK, "Rubber")
				r:cyl(-1.0, 0.7, sz * 1.0, 0.18, 1.0, "z", r.c2, "Metal")
				r:cyl(-1.0, 0.7, sz * 1.0, 0.24, 0.24, "z", C.Gold, "Metal")
				r:block(1.2, 0, sz * 0.62 - 0.08, 1.36, 1.0, sz * 0.62 + 0.08, r.c2, "Metal")
				rod(r, Vector3.new(1.5, 2.0, sz * 0.6), Vector3.new(1.58, 2.3, sz * 0.6), 0.06, CHROME, "Metal")
			end
			r:cyl(-1.0, 0.7, 0, 1.9, 0.1, "z", CHROME, "Metal")
			rod(r, Vector3.new(1.58, 2.3, -0.62), Vector3.new(1.58, 2.3, 0.62), 0.08, CHROME, "Metal")
			-- the cart, trimmed top and bottom, a striped popcorn box painted on its front
			r:block(-1.5, 1.0, -0.85, 1.5, 2.4, 0.85, r.c1, "Metal")
			r:block(-1.55, 2.3, -0.9, 1.55, 2.45, 0.9, r.c2, "Cardboard")
			r:block(-1.55, 0.95, -0.9, 1.55, 1.1, 0.9, r.c2, "Cardboard")
			for k = 0, 2 do
				r:block(-0.55 + k * 0.38, 1.35, 0.85, -0.37 + k * 0.38, 2.05, 0.89, C.White, "Cardboard")
			end
			for k = 0, 3 do
				r:ball(-0.45 + k * 0.3, 2.12, 0.88, 0.22, CREAM, "Sand")
			end
			-- the glass case on top: posts, panes, a lid, a heap of popcorn and the kettle
			for _, sx in { -1, 1 } do
				for _, sz in { -1, 1 } do
					r:block(
						sx * 1.4 - 0.05,
						2.45,
						sz * 0.75 - 0.05,
						sx * 1.4 + 0.05,
						4.3,
						sz * 0.75 + 0.05,
						r.c2,
						"Metal"
					)
				end
			end
			for _, sz in { -1, 1 } do
				r:glass(-1.35, 2.45, sz * 0.75 - 0.02, 1.35, 4.3, sz * 0.75 + 0.02)
			end
			for _, sx in { -1, 1 } do
				r:glass(sx * 1.4 - 0.02, 2.45, -0.7, sx * 1.4 + 0.02, 4.3, 0.7)
			end
			r:block(-1.5, 4.3, -0.85, 1.5, 4.45, 0.85, r.c2, "Cardboard")
			for k, p in { { -0.8, 0.2 }, { -0.4, -0.3 }, { 0.1, 0.1 }, { 0.6, -0.2 }, { 0.9, 0.3 }, { -0.2, 0.4 } } do
				r:lump(CFrame.new(p[1], 2.62, p[2]) * CFrame.Angles(0, k, 0), 0.7, 0.4, 0.6, CREAM, "Sand")
			end
			rod(r, Vector3.new(0, 4.3, 0), Vector3.new(0, 3.95, 0), 0.06, CHROME, "Metal")
			r:cyl(0, 3.65, 0, 0.5, 0.7, "y", CHROME, "Metal")
			r:cyl(0, 3.93, 0, 0.06, 0.74, "y", shade(CHROME, 0.85), "Metal")
			local bulb = r:ball(0.9, 4.15, 0, 0.18, C.Warm, "Neon")
			r:glow(bulb, 10, 0.8)
			-- the striped roof on four thin posts, a scalloped edge and a knob on top
			for _, sx in { -1, 1 } do
				for _, sz in { -1, 1 } do
					r:block(
						sx * 1.4 - 0.04,
						4.45,
						sz * 0.75 - 0.04,
						sx * 1.4 + 0.04,
						5.0,
						sz * 0.75 + 0.04,
						r.c2,
						"Metal"
					)
				end
			end
			for k = 0, 4 do
				r:block(
					-1.6 + k * 0.64,
					5.0,
					-1.0,
					-0.96 + k * 0.64,
					5.15,
					1.0,
					if k % 2 == 0 then r.c1 else r.c2,
					"Fabric"
				)
				for _, sz in { -1, 1 } do
					r:block(
						-1.6 + k * 0.64 + 0.08,
						4.85,
						sz * 1.0 - 0.03,
						-0.96 + k * 0.64 - 0.08,
						5.0,
						sz * 1.0 + 0.03,
						if k % 2 == 0 then r.c2 else r.c1,
						"Fabric"
					)
				end
			end
			r:ball(0, 5.3, 0, 0.3, C.Gold, "Metal")
			Lively.fx(r, "popcorn", 0, 3.3, 0, { w = 0.4, d = 0.4 })
		end,
	},
}

return items
