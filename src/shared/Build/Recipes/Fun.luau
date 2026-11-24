--!strict
-- TVs, music, games and toys. c1 is the main body, c2 an accent (a screen, a seat, trim).

local Recipe = require(script.Parent.Parent.Recipe)
local Colors = require(script.Parent.Parent.Parent.Util.Colors)

local C = Recipe.Colors

type R = Recipe.Recipe

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

-- A curved runner of straight pieces through the given points, joints closed up.
local function rocker(r: R, pts: { Vector3 }, size: number, color: Color3)
	for i = 1, #pts - 1 do
		local a, b = pts[i], pts[i + 1]
		local d = (b - a).Unit * 0.08
		r:beam(if i > 1 then a - d else a, if i < #pts - 1 then b + d else b, size, size, color, "Wood")
	end
end

-- A drum lying on its side or standing up: a shell, a metal hoop at each end and a white head
-- stretched over the hoop, so the hoop shows as a ring round it.
local function drum(
	r: R,
	x: number,
	y: number,
	z: number,
	len: number,
	d: number,
	axis: string,
	shell: Color3,
	hoop: Color3
)
	r:cyl(x, y, z, len - 0.2, d, axis, shell, "SmoothPlastic")
	local ux = if axis == "x" then 1 else 0
	local uy = if axis == "y" then 1 else 0
	local uz = if axis == "z" then 1 else 0
	for _, s in { -1, 1 } do
		local h = len / 2 - 0.05
		r:cyl(x + ux * s * h, y + uy * s * h, z + uz * s * h, 0.1, d + 0.06, axis, hoop, "Metal")
		local o = len / 2 + 0.015
		r:cyl(x + ux * s * o, y + uy * s * o, z + uz * s * o, 0.03, d - 0.04, axis, C.White, "SmoothPlastic")
	end
end

-- A cymbal on a stand at (x, z), its plate at height h.
local function cymbal(r: R, x: number, z: number, h: number, d: number, metal: Color3)
	for i = 0, 2 do
		local a = i * math.pi * 2 / 3
		rod(
			r,
			Vector3.new(x + math.cos(a) * 0.4, 0, z + math.sin(a) * 0.4),
			Vector3.new(x, 0.7, z),
			0.05,
			metal,
			"Metal"
		)
	end
	r:cyl(x, h / 2 + 0.3, z, h - 0.6, 0.07, "y", metal, "Metal")
	r:cyl(x, h, z, 0.04, d, "y", C.Gold, "Metal")
	r:cyl(x, h + 0.04, z, 0.05, d * 0.25, "y", C.Gold, "Metal")
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
		id = "tv_stand",
		name = "TV on a stand",
		cat = "fun",
		price = 300,
		place = "floor",
		size = Vector3.new(5, 4.7, 1.8),
		c1 = "AD7E55",
		c2 = "2B282E",
		tags = { "tv" },
		build = function(r: R)
			local wood = r.c1
			local dk = shade(r.c1, 0.8)
			-- a low console on splayed legs: slatted doors either side of an open middle with a shelf
			for _, sx in { -1, 1 } do
				for _, sz in { -1, 1 } do
					rod(r, Vector3.new(sx * 2.2, 0.4, sz * 0.6), Vector3.new(sx * 2.28, 0, sz * 0.68), 0.16, dk, "Wood")
				end
			end
			for _, sx in { -1, 1 } do
				local xa, xb = sx * 0.82, sx * 2.5
				r:block(math.min(xa, xb), 0.38, -0.8, math.max(xa, xb), 1.6, 0.8, wood, "Wood")
			end
			r:block(-0.82, 0.38, -0.8, 0.82, 0.46, 0.8, wood, "Wood")
			r:block(-0.82, 1.52, -0.8, 0.82, 1.6, 0.8, wood, "Wood")
			r:block(-0.82, 0.46, -0.8, 0.82, 1.52, -0.66, shade(r.c1, 0.5), "Wood")
			r:block(-0.82, 0.96, -0.66, 0.82, 1.02, 0.74, wood, "Wood")
			r:block(-2.5, 1.6, -0.85, 2.5, 1.72, 0.85, shade(r.c1, 0.88), "Wood")
			for _, sx in { -1, 1 } do
				local xa, xb = sx * 0.85, sx * 2.42
				local x1, x2 = math.min(xa, xb), math.max(xa, xb)
				r:block(x1, 0.46, 0.8, x2, 1.52, 0.84, shade(r.c1, 1.06), "Wood")
				r:piece(function(q: R)
					for k = 1, 5 do
						local x = x1 + k * (x2 - x1) / 6
						q:block(x - 0.025, 0.54, 0.84, x + 0.025, 1.44, 0.88, shade(r.c1, 0.8), "Wood")
					end
				end)
				r:ball(sx * 0.98, 0.99, 0.9, 0.1, C.Gold, "Metal")
			end
			-- below the shelf a games console with a pad in front of it, above it a row of games
			r:block(-0.62, 0.46, -0.42, 0.38, 0.66, 0.42, C.White, "SmoothPlastic")
			r:block(-0.58, 0.66, -0.38, 0.34, 0.7, 0.38, shade(C.White, 0.9), "SmoothPlastic")
			local led = r:block(-0.52, 0.53, 0.42, -0.22, 0.57, 0.45, C.Blue, "Neon")
			r:glow(led, 0)
			r:lump(
				CFrame.new(0.55, 0.53, 0.4) * CFrame.Angles(0, 0.4, 0),
				0.42,
				0.12,
				0.26,
				C.DarkMetal,
				"SmoothPlastic"
			)
			r:piece(function(q: R)
				local cols = {
					Color3.fromRGB(94, 122, 150),
					Color3.fromRGB(184, 102, 92),
					Color3.fromRGB(126, 154, 122),
					Color3.fromRGB(201, 166, 94),
					Color3.fromRGB(90, 85, 96),
					Color3.fromRGB(138, 111, 144),
				}
				for i, col in cols do
					local x = -0.75 + (i - 1) * 0.09
					q:block(x, 1.02, -0.5, x + 0.08, 1.46, 0.32, col, "SmoothPlastic")
				end
				q:block(0.05, 1.02, -0.45, 0.7, 1.1, 0.3, Color3.fromRGB(94, 122, 150), "SmoothPlastic")
				q:block(0.08, 1.1, -0.42, 0.66, 1.18, 0.28, Color3.fromRGB(222, 211, 188), "SmoothPlastic")
			end)
			-- a slim TV on a centre foot: a dark body, a bezel round a screen set in behind it,
			-- and a picture of hills under a sky
			r:block(-0.9, 1.72, -0.45, 0.9, 1.78, 0.1, r.c2, "Metal")
			r:block(-0.12, 1.78, -0.36, 0.12, 2.2, -0.25, r.c2, "Metal")
			r:block(-2.15, 2.1, -0.32, 2.15, 4.65, -0.2, r.c2, "SmoothPlastic")
			r:piece(function(q: R)
				q:block(-2.15, 4.55, -0.2, 2.15, 4.65, -0.13, r.c2, "SmoothPlastic")
				q:block(-2.15, 2.1, -0.2, 2.15, 2.26, -0.13, r.c2, "SmoothPlastic")
				q:block(-2.15, 2.26, -0.2, -2.07, 4.55, -0.13, r.c2, "SmoothPlastic")
				q:block(2.07, 2.26, -0.2, 2.15, 4.55, -0.13, r.c2, "SmoothPlastic")
			end)
			r:block(-0.08, 2.15, -0.13, 0.08, 2.2, -0.1, Color3.fromRGB(120, 124, 132), "Metal")
			r:block(-2.07, 2.26, -0.2, 2.07, 4.55, -0.17, Color3.fromRGB(122, 160, 196), "SmoothPlastic")
			r:tri(
				Vector3.new(-2.07, 2.9, -0.155),
				Vector3.new(-0.9, 3.55, -0.155),
				Vector3.new(0.2, 2.9, -0.155),
				0.03,
				Color3.fromRGB(126, 160, 120),
				"SmoothPlastic"
			)
			r:tri(
				Vector3.new(0.2, 2.9, -0.155),
				Vector3.new(1.2, 3.35, -0.155),
				Vector3.new(2.07, 2.9, -0.155),
				0.03,
				Color3.fromRGB(104, 144, 104),
				"SmoothPlastic"
			)
			r:block(-2.07, 2.26, -0.17, 2.07, 2.9, -0.14, Color3.fromRGB(96, 136, 92), "SmoothPlastic")
			r:cyl(1.1, 3.95, -0.155, 0.03, 0.5, "z", Color3.fromRGB(250, 220, 140), "SmoothPlastic")
			-- a sound bar with a grille, a little plant and the remote
			r:block(-1.2, 1.72, 0.25, 1.2, 1.95, 0.55, C.Black, "Fabric")
			for _, sx in { -1, 1 } do
				r:cyl(sx * 1.2, 1.835, 0.4, 0.3, 0.23, "z", C.Black, "Fabric")
			end
			r:block(-1.1, 1.76, 0.55, 1.1, 1.91, 0.58, Color3.fromRGB(70, 68, 76), "Fabric")
			r:cyl(1.95, 1.92, 0.35, 0.4, 0.42, "y", Color3.fromRGB(226, 220, 208), "SmoothPlastic")
			r:cyl(1.95, 2.06, 0.35, 0.06, 0.34, "y", C.Soil, "Sand")
			r:lump(CFrame.new(1.95, 2.35, 0.35) * CFrame.Angles(0.3, 0.6, 0.2), 0.5, 0.38, 0.46, C.Leaf, "Grass")
			r:lump(CFrame.new(2.05, 2.55, 0.3) * CFrame.Angles(0.6, 0.1, 0.5), 0.3, 0.3, 0.3, C.DarkLeaf, "Grass")
			r:boxAt(
				CFrame.new(-1.9, 1.75, 0.45) * CFrame.Angles(0, 0.3, 0),
				0.18,
				0.06,
				0.6,
				C.DarkMetal,
				"SmoothPlastic"
			)
		end,
	},
	{
		id = "record_player",
		name = "Record player",
		cat = "fun",
		price = 120,
		place = "surface",
		size = Vector3.new(1.8, 0.75, 1.6),
		c1 = "8E6440",
		c2 = "B8505A",
		tags = { "music" },
		build = function(r: R)
			for _, sx in { -1, 1 } do
				for _, sz in { -1, 1 } do
					r:cyl(sx * 0.75, 0.03, sz * 0.62, 0.06, 0.14, "y", C.Black, "Rubber")
				end
			end
			r:block(-0.9, 0.06, -0.75, 0.9, 0.45, 0.75, r.c1, "Wood")
			r:block(-0.86, 0.45, -0.71, 0.86, 0.48, 0.71, C.Black, "SmoothPlastic")
			-- the platter, the record and its label
			r:cyl(-0.2, 0.51, 0, 0.06, 1.18, "y", C.Metal, "Metal")
			r:cyl(-0.2, 0.555, 0, 0.03, 1.1, "y", C.Black, "SmoothPlastic")
			r:cyl(-0.2, 0.585, 0, 0.03, 0.86, "y", Color3.fromRGB(40, 40, 46), "SmoothPlastic")
			r:cyl(-0.2, 0.615, 0, 0.03, 0.36, "y", r.c2, "SmoothPlastic")
			r:cyl(-0.2, 0.655, 0, 0.05, 0.05, "y", C.Metal, "Metal")
			-- the arm on its post, resting on the record, and a counterweight
			r:cyl(0.6, 0.56, -0.45, 0.12, 0.22, "y", C.Metal, "Metal")
			rod(r, Vector3.new(0.6, 0.66, -0.6), Vector3.new(0.6, 0.66, -0.45), 0.08, C.DarkMetal, "Metal")
			rod(r, Vector3.new(0.6, 0.66, -0.45), Vector3.new(0.18, 0.63, 0.22), 0.04, C.Metal, "Metal")
			r:block(0.1, 0.59, 0.18, 0.26, 0.65, 0.32, C.DarkMetal, "Metal")
			-- knobs on the front
			for _, x in { 0.45, 0.72 } do
				r:cyl(x, 0.24, 0.77, 0.06, 0.14, "z", C.Gold, "Metal")
			end
			r:block(-0.75, 0.2, 0.75, -0.55, 0.28, 0.78, Color3.fromRGB(120, 220, 160), "Neon")
		end,
	},
	{
		id = "piano",
		name = "Piano",
		cat = "fun",
		price = 700,
		place = "floor",
		size = Vector3.new(5, 4.5, 4),
		c1 = "2B282E",
		c2 = "84424A",
		tags = { "music" },
		build = function(r: R)
			local hi = shade(r.c1, 1.35)
			-- the upright case, with a lid and a moulding round the top
			r:block(-2.4, 0.15, -2.0, 2.4, 4.3, -0.85, r.c1, "SmoothPlastic")
			r:block(-2.45, 0, -2.0, 2.45, 0.15, -0.8, hi, "SmoothPlastic")
			r:block(-2.5, 4.3, -2.05, 2.5, 4.45, -0.75, hi, "SmoothPlastic")
			r:block(-2.2, 2.9, -0.86, 2.2, 4.2, -0.82, shade(r.c1, 1.15), "SmoothPlastic")
			r:block(-2.2, 0.3, -0.86, 2.2, 2.25, -0.82, shade(r.c1, 1.15), "SmoothPlastic")
			-- side cheeks hold the keyboard, each on a toe block
			for _, sx in { -1, 1 } do
				r:block(sx * 2.3 - 0.12, 0.15, -0.85, sx * 2.3 + 0.12, 2.8, 0.18, r.c1, "SmoothPlastic")
				r:cyl(sx * 2.3, 2.8, -0.33, 1.02, 0.24, "z", r.c1, "SmoothPlastic")
				r:block(sx * 2.3 - 0.14, 0, -0.85, sx * 2.3 + 0.14, 0.15, 0.25, hi, "SmoothPlastic")
				r:block(sx * 1.95 - 0.1, 0, -0.85, sx * 1.95 + 0.1, 2.3, -0.65, r.c1, "SmoothPlastic")
			end
			r:block(-2.18, 2.25, -0.85, 2.18, 2.55, 0.12, r.c1, "SmoothPlastic")
			-- white keys with a thin gap between each, and black keys in twos and threes on them
			r:piece(function(q: R)
				local kw = 4.3 / 21
				for k = 0, 20 do
					local x = -2.15 + k * kw
					q:block(x + 0.012, 2.55, -0.65, x + kw - 0.012, 2.66, 0.1, C.White, "SmoothPlastic")
				end
			end)
			for octave = 0, 2 do
				for i = 1, 5 do
					local kx = -1.85 + octave * 1.4 + (i - 1) * 0.2 + (if i > 2 then 0.2 else 0)
					r:block(kx, 2.66, -0.65, kx + 0.11, 2.75, -0.18, C.Black, "SmoothPlastic")
				end
			end
			r:block(-2.18, 2.55, -0.85, 2.18, 2.95, -0.65, r.c1, "SmoothPlastic")
			-- a music stand with a page, and three brass pedals
			r:block(-0.9, 2.95, -0.88, 0.9, 3.7, -0.78, hi, "SmoothPlastic")
			r:block(-0.95, 2.95, -0.78, 0.95, 3.02, -0.66, hi, "SmoothPlastic")
			r:boxAt(CFrame.new(0, 3.35, -0.75) * CFrame.Angles(-0.1, 0, 0), 1.2, 0.6, 0.02, C.Paper, "SmoothPlastic")
			for _, px in { -0.35, 0, 0.35 } do
				r:block(px - 0.06, 0.12, -0.82, px + 0.06, 0.2, -0.5, C.Gold, "Metal")
			end
			-- the bench, with a padded top
			for _, sx in { -1, 1 } do
				for _, sz in { -1, 1 } do
					r:box(sx * 1.1, 0.8, 1.3 + sz * 0.32, 0.18, 1.6, 0.18, r.c1, "SmoothPlastic")
				end
				r:block(sx * 1.1 - 0.06, 0.4, 0.98, sx * 1.1 + 0.06, 0.5, 1.62, r.c1, "SmoothPlastic")
			end
			r:block(-1.3, 1.5, 0.82, 1.3, 1.68, 1.78, r.c1, "SmoothPlastic")
			r:block(-1.22, 1.68, 0.88, 1.22, 1.92, 1.72, r.c2, "Fabric")
			r:seat(0, 1.92, 1.3, 180)
		end,
	},
	{
		id = "arcade",
		name = "Arcade machine",
		cat = "fun",
		price = 450,
		place = "floor",
		size = Vector3.new(2.4, 6.2, 2.4),
		c1 = "6A5490",
		c2 = "E8C46C",
		tags = { "games" },
		build = function(r: R)
			-- side panels: deep at the bottom, set back at the screen, out again at the sign
			for _, sx in { -1, 1 } do
				local x1, x2 = sx * 1.08, sx * 1.2
				local xa, xb = math.min(x1, x2), math.max(x1, x2)
				r:block(xa, 0, -1.2, xb, 3.35, 1.05, r.c1, "SmoothPlastic")
				r:block(xa, 3.35, -1.2, xb, 5.2, 0.35, r.c1, "SmoothPlastic")
				r:block(xa, 5.2, -1.2, xb, 6.2, 0.65, r.c1, "SmoothPlastic")
				r:block(xa - 0.03, 0, 0.85, xb + 0.03, 3.38, 1.08, r.c2, "SmoothPlastic")
				-- a painted stripe down each side
				r:beam(
					Vector3.new(sx * 1.225, 0.6, -0.9),
					Vector3.new(sx * 1.225, 4.6, 0.1),
					0.03,
					0.3,
					r.c2,
					"SmoothPlastic"
				)
			end
			r:block(-1.08, 0, -1.2, 1.08, 3.05, 0.95, shade(r.c1, 0.75), "SmoothPlastic")
			r:block(-1.08, 0, 0.95, 1.08, 0.2, 1.05, C.Black, "SmoothPlastic")
			-- the coin door
			r:block(-0.4, 0.9, 0.95, 0.4, 1.8, 1.0, C.DarkMetal, "Metal")
			for _, x in { -0.16, 0.16 } do
				r:block(x - 0.06, 1.25, 1.0, x + 0.06, 1.5, 1.04, C.Red, "Neon")
			end
			-- the control panel, sloping toward the player
			r:boxAt(CFrame.new(0, 3.2, 0.6) * CFrame.Angles(0.25, 0, 0), 2.16, 0.3, 0.95, C.Black, "SmoothPlastic")
			r:cyl(-0.5, 3.45, 0.6, 0.25, 0.06, "y", C.Black, "Metal")
			r:ball(-0.5, 3.6, 0.6, 0.2, C.Red, "Plastic")
			for i, col in { C.Red, C.Blue, C.Yellow, Color3.fromRGB(120, 200, 120) } do
				r:cyl(-0.05 + i * 0.22, 3.37, 0.55 + (i % 2) * 0.12, 0.06, 0.15, "y", col, "Plastic")
			end
			-- the screen, leaning back, with a game on it
			local scr = CFrame.new(0, 4.25, -0.05) * CFrame.Angles(-0.2, 0, 0)
			r:boxAt(scr, 2.1, 1.85, 0.2, C.Black, "SmoothPlastic")
			local screen =
				r:boxAt(scr * CFrame.new(0, 0, 0.115), 1.8, 1.5, 0.03, Color3.fromRGB(46, 52, 88), "SmoothPlastic")
			r:glow(screen, 8, 0.6, Color3.fromRGB(140, 160, 255))
			r:boxAt(scr * CFrame.new(-0.4, -0.3, 0.15), 0.2, 0.2, 0.03, C.Yellow, "Neon")
			r:boxAt(scr * CFrame.new(0.3, 0.2, 0.15), 0.2, 0.2, 0.03, C.Pink, "Neon")
			r:boxAt(scr * CFrame.new(0, -0.6, 0.15), 1.6, 0.08, 0.03, Color3.fromRGB(120, 220, 140), "Neon")
			r:block(-1.08, 3.05, -1.2, 1.08, 5.2, -0.3, shade(r.c1, 0.75), "SmoothPlastic")
			-- the lit sign at the top
			r:block(-1.08, 5.2, -1.2, 1.08, 6.0, 0.6, shade(r.c1, 0.75), "SmoothPlastic")
			local sign = r:block(-1.0, 5.3, 0.6, 1.0, 5.9, 0.65, r.c2, "SmoothPlastic")
			r:glow(sign, 0)
			r:block(-0.7, 5.5, 0.65, 0.7, 5.7, 0.67, C.Pink, "SmoothPlastic")
			r:block(-1.2, 6.0, -1.2, 1.2, 6.2, 0.65, r.c1, "SmoothPlastic")
		end,
	},
	{
		id = "table_games",
		name = "Board game table",
		cat = "fun",
		price = 250,
		place = "floor",
		size = Vector3.new(5.4, 2.9, 2.8),
		c1 = "8E6440",
		c2 = "D08A6C",
		tags = { "games" },
		build = function(r: R)
			local dk = shade(r.c1, 0.85)
			r:block(-1.3, 2.6, -1.3, 1.3, 2.8, 1.3, r.c1, "Wood")
			r:block(-1.24, 2.54, -1.24, 1.24, 2.6, 1.24, dk, "Wood")
			r:block(-1.1, 2.25, -1.1, 1.1, 2.54, 1.1, dk, "Wood")
			for _, sx in { -1, 1 } do
				for _, sz in { -1, 1 } do
					rod(
						r,
						Vector3.new(sx * 0.98, 2.3, sz * 0.98),
						Vector3.new(sx * 1.06, 0, sz * 1.06),
						0.2,
						dk,
						"Wood"
					)
				end
			end
			-- a checkered board with a few pieces left mid game
			r:block(-0.96, 2.8, -0.96, 0.96, 2.83, 0.96, Color3.fromRGB(110, 76, 48), "Wood")
			r:block(-0.9, 2.83, -0.9, 0.9, 2.86, 0.9, C.Cream, "Wood")
			for i = 0, 3 do
				for j = 0, 3 do
					if (i + j) % 2 == 0 then
						local x, z = -0.9 + i * 0.45, -0.9 + j * 0.45
						r:block(x, 2.86, z, x + 0.45, 2.89, z + 0.45, Color3.fromRGB(110, 76, 48), "Wood")
					end
				end
			end
			for _, p in
				{
					{ -0.675, -0.675, 1 },
					{ 0.225, -0.675, 1 },
					{ -0.225, -0.225, 1 },
					{ 0.675, 0.225, 2 },
					{ -0.225, 0.675, 2 },
					{ 0.225, 0.225, 2 },
				}
			do
				r:cyl(p[1], 2.95, p[2], 0.12, 0.32, "y", if p[3] == 1 then C.Red else C.Black, "Plastic")
			end
			-- a padded stool on each side
			for _, sx in { -1, 1 } do
				local x = sx * 2.15
				for _, dz in { -0.4, 0.4 } do
					for _, dx in { -0.4, 0.4 } do
						rod(r, Vector3.new(x + dx * 0.8, 1.65, dz * 0.8), Vector3.new(x + dx, 0, dz), 0.12, dk, "Wood")
					end
				end
				r:cyl(x, 1.7, 0, 0.14, 1.25, "y", dk, "Wood")
				r:cyl(x, 1.86, 0, 0.18, 1.15, "y", r.c2, "Fabric")
				r:seat(x, 1.95, 0, sx * -90)
			end
		end,
	},
	{
		id = "desk_computer",
		name = "Computer desk",
		cat = "fun",
		price = 400,
		place = "floor",
		size = Vector3.new(4.6, 4.9, 2.4),
		surface = 3,
		c1 = "F7F3EA",
		c2 = "6AA2C8",
		tags = { "desk", "games" },
		build = function(r: R)
			local frame = Color3.fromRGB(60, 62, 70)
			r:block(-2.3, 2.82, -1.2, 2.3, 3.0, 1.2, r.c1, "Wood")
			r:block(-2.24, 2.76, -1.14, 2.24, 2.82, 1.14, shade(r.c1, 0.8), "Wood")
			-- two metal leg frames joined by a back rail
			for _, sx in { -1, 1 } do
				local x = sx * 2.05
				r:block(x - 0.08, 0, -1.05, x + 0.08, 0.12, 1.05, frame, "Metal")
				r:block(x - 0.07, 0.12, -0.12, x + 0.07, 2.64, 0.12, frame, "Metal")
				r:block(x - 0.08, 2.64, -1.05, x + 0.08, 2.76, 1.05, frame, "Metal")
			end
			r:block(-1.97, 2.3, -0.9, 1.97, 2.42, -0.78, frame, "Metal")
			-- the screen on a stand: a bezel round a display set back inside it, windows open on it
			r:block(-0.4, 3.0, -0.85, 0.4, 3.04, -0.4, frame, "Metal")
			r:block(-0.08, 3.04, -0.74, 0.08, 3.65, -0.62, frame, "Metal")
			r:block(-1.3, 3.3, -0.66, 1.3, 4.85, -0.56, C.Black, "SmoothPlastic")
			r:piece(function(q: R)
				q:block(-1.3, 4.77, -0.56, 1.3, 4.85, -0.5, C.Black, "SmoothPlastic")
				q:block(-1.3, 3.3, -0.56, 1.3, 3.42, -0.5, C.Black, "SmoothPlastic")
				q:block(-1.3, 3.42, -0.56, -1.22, 4.77, -0.5, C.Black, "SmoothPlastic")
				q:block(1.22, 3.42, -0.56, 1.3, 4.77, -0.5, C.Black, "SmoothPlastic")
			end)
			local display = r:block(-1.22, 3.42, -0.56, 1.22, 4.77, -0.53, Color3.fromRGB(60, 78, 120), "SmoothPlastic")
			r:glow(display, 6, 0.5, Color3.fromRGB(170, 210, 255))
			local wins: { { x1: number, y1: number, x2: number, y2: number, col: Color3 } } = {
				{ x1 = -1.0, y1 = 3.6, x2 = 0.0, y2 = 4.5, col = r.c2 },
				{ x1 = 0.2, y1 = 3.6, x2 = 1.0, y2 = 3.95, col = C.Yellow },
				{ x1 = 0.2, y1 = 4.08, x2 = 1.0, y2 = 4.5, col = C.Pink },
			}
			for _, w in wins do
				r:block(w.x1, w.y1, -0.53, w.x2, w.y2, -0.5, w.col, "SmoothPlastic")
				r:block(w.x1, w.y2 - 0.1, -0.5, w.x2, w.y2, -0.47, shade(w.col, 0.7), "SmoothPlastic")
			end
			-- a desk mat with a keyboard of real keys, a mouse, a mug and headphones
			r:block(-1.3, 3.0, -0.1, 1.6, 3.03, 0.85, Color3.fromRGB(50, 52, 58), "Fabric")
			r:block(-0.95, 3.03, 0.12, 0.7, 3.1, 0.62, C.DarkMetal, "SmoothPlastic")
			local keys = Color3.fromRGB(92, 94, 104)
			for half = 0, 1 do
				r:piece(function(q: R)
					for row = half * 2, half * 2 + 1 do
						local z = 0.2 + row * 0.11
						if row == 3 then
							q:block(-0.5, 3.1, z - 0.045, 0.3, 3.13, z + 0.045, keys, "SmoothPlastic")
							for _, x in { -0.85, -0.68, 0.45, 0.62 } do
								q:block(x - 0.065, 3.1, z - 0.045, x + 0.065, 3.13, z + 0.045, keys, "SmoothPlastic")
							end
						else
							for k = 0, 9 do
								local x = -0.86 + k * 0.165
								q:block(x - 0.065, 3.1, z - 0.045, x + 0.065, 3.13, z + 0.045, keys, "SmoothPlastic")
							end
						end
					end
				end)
			end
			r:lump(CFrame.new(1.16, 3.08, 0.42), 0.22, 0.1, 0.34, C.DarkMetal, "SmoothPlastic")
			r:cyl(-1.75, 3.22, 0.35, 0.44, 0.34, "y", C.Red, "SmoothPlastic")
			r:cyl(-1.75, 3.455, 0.35, 0.03, 0.26, "y", Color3.fromRGB(96, 64, 44), "SmoothPlastic")
			rod(r, Vector3.new(-1.92, 3.34, 0.35), Vector3.new(-2.04, 3.3, 0.35), 0.06, C.Red, "SmoothPlastic")
			rod(r, Vector3.new(-2.04, 3.3, 0.35), Vector3.new(-2.04, 3.14, 0.35), 0.06, C.Red, "SmoothPlastic")
			rod(r, Vector3.new(-2.04, 3.14, 0.35), Vector3.new(-1.92, 3.1, 0.35), 0.06, C.Red, "SmoothPlastic")
			for _, x in { 1.55, 2.05 } do
				r:cyl(x, 3.05, -0.62, 0.1, 0.36, "y", C.Black, "SmoothPlastic")
				r:cyl(x, 3.115, -0.62, 0.03, 0.26, "y", r.c2, "Fabric")
			end
			rod(r, Vector3.new(1.55, 3.06, -0.8), Vector3.new(1.8, 3.06, -0.98), 0.06, C.Black, "SmoothPlastic")
			rod(r, Vector3.new(1.8, 3.06, -0.98), Vector3.new(2.05, 3.06, -0.8), 0.06, C.Black, "SmoothPlastic")
			-- the computer under the desk: a tinted glass side with lit fans, a power light, feet
			for _, x in { 1.08, 1.72 } do
				for _, z in { -0.85, 0.7 } do
					r:block(x - 0.06, 0, z - 0.06, x + 0.06, 0.12, z + 0.06, C.Black, "Rubber")
				end
			end
			r:block(1.0, 0.12, -0.95, 1.8, 2.1, 0.8, C.DarkMetal, "Metal")
			r:block(0.97, 0.3, -0.8, 1.0, 1.95, 0.65, Color3.fromRGB(40, 44, 60), "Glass")
			for _, y in { 0.75, 1.5 } do
				local fan = r:cyl(0.925, y, -0.1, 0.03, 0.55, "x", r.c2, "Neon")
				r:glow(fan, 0)
			end
			r:block(1.3, 1.85, 0.8, 1.5, 1.95, 0.83, C.Blue, "Neon")
			r:block(1.2, 1.4, 0.8, 1.6, 1.7, 0.83, Color3.fromRGB(60, 62, 70), "Metal")
		end,
	},
	{
		id = "drum_kit",
		name = "Drum kit",
		cat = "fun",
		price = 500,
		place = "floor",
		size = Vector3.new(4.4, 4.3, 3.6),
		c1 = "B8505A",
		c2 = "C9CCD3",
		tags = { "music" },
		build = function(r: R)
			-- the bass drum lying on its side, its head facing out, on two little legs
			drum(r, 0, 1.0, 0.5, 1.2, 2.0, "z", r.c1, r.c2)
			r:cyl(0, 1.0, 1.145, 0.03, 0.8, "z", r.c1, "SmoothPlastic")
			for _, sx in { -1, 1 } do
				rod(r, Vector3.new(sx * 0.7, 0.4, 0.8), Vector3.new(sx * 0.95, 0, 1.0), 0.06, r.c2, "Metal")
			end
			-- two toms mounted on top and a floor tom on legs
			r:cyl(0, 2.05, 0.35, 0.3, 0.1, "y", r.c2, "Metal")
			for _, x in { -0.5, 0.5 } do
				drum(r, x, 2.35, 0.3, 0.55, 0.8, "y", r.c1, r.c2)
			end
			drum(r, 1.45, 1.05, -0.4, 0.9, 1.1, "y", r.c1, r.c2)
			for _, dz in { -0.35, 0.35 } do
				rod(r, Vector3.new(1.9, 0, -0.4 + dz), Vector3.new(1.95, 0.9, -0.4 + dz), 0.06, r.c2, "Metal")
			end
			-- the snare on its stand
			for i = 0, 2 do
				local a = i * math.pi * 2 / 3
				rod(
					r,
					Vector3.new(-1.5 + math.cos(a) * 0.35, 0, 0.1 + math.sin(a) * 0.35),
					Vector3.new(-1.5, 0.6, 0.1),
					0.05,
					r.c2,
					"Metal"
				)
			end
			r:cyl(-1.5, 1.15, 0.1, 1.1, 0.08, "y", r.c2, "Metal")
			drum(r, -1.5, 1.92, 0.1, 0.42, 1.0, "y", r.c2, r.c2)
			-- a hi hat and a crash cymbal
			cymbal(r, -1.75, 1.05, 3.4, 1.1, r.c2)
			r:cyl(-1.75, 3.32, 1.05, 0.04, 1.1, "y", C.Gold, "Metal")
			cymbal(r, 1.75, 0.95, 3.9, 1.3, r.c2)
			-- the drummer's stool
			for i = 0, 2 do
				local a = i * math.pi * 2 / 3 + math.pi / 2
				rod(
					r,
					Vector3.new(math.cos(a) * 0.4, 0, -1.3 + math.sin(a) * 0.4),
					Vector3.new(0, 0.7, -1.3),
					0.06,
					r.c2,
					"Metal"
				)
			end
			r:cyl(0, 1.15, -1.3, 1.0, 0.12, "y", r.c2, "Metal")
			r:cyl(0, 1.75, -1.3, 0.3, 1.1, "y", C.Black, "Fabric")
			r:seat(0, 1.9, -1.3)
		end,
	},
	{
		id = "rocking_horse",
		name = "Rocking horse",
		cat = "fun",
		price = 120,
		place = "floor",
		size = Vector3.new(1.4, 3.2, 3.6),
		c1 = "E9D3B0",
		c2 = "B8505A",
		tags = { "toy" },
		build = function(r: R)
			local wood = shade(r.c1, 0.75)
			local dk = shade(r.c1, 0.55)
			local mane = Color3.fromRGB(122, 88, 62)
			-- two curved rockers with scrolled ends, joined by a bar at each end
			for _, sx in { -1, 1 } do
				local x = sx * 0.55
				rocker(r, {
					Vector3.new(x, 0.55, -1.7),
					Vector3.new(x, 0.12, -0.6),
					Vector3.new(x, 0.12, 0.6),
					Vector3.new(x, 0.55, 1.7),
				}, 0.18, wood)
				for _, sz in { -1, 1 } do
					r:cyl(x, 0.62, sz * 1.68, 0.26, 0.22, "x", shade(wood, 0.9), "Wood")
				end
			end
			for _, sz in { -1, 1 } do
				rod(r, Vector3.new(-0.55, 0.42, sz * 1.38), Vector3.new(0.55, 0.42, sz * 1.38), 0.1, wood, "Wood")
			end
			-- legs from the rockers up into the body, each with a dark hoof
			for _, sx in { -1, 1 } do
				for _, sz in { -1, 1 } do
					local foot = Vector3.new(sx * 0.55, 0.22, sz * 0.95)
					local hip = Vector3.new(sx * 0.26, 1.62, sz * 0.72)
					rod(r, foot + (hip - foot).Unit * 0.2, hip, 0.18, r.c1, "Wood")
					rod(r, foot, foot + (hip - foot).Unit * 0.22, 0.22, dk, "Wood")
				end
			end
			-- a rounded body, the rump a little higher than the chest
			r:lump(CFrame.new(0, 1.85, -0.05), 0.82, 0.78, 2.2, r.c1, "Wood")
			r:lump(CFrame.new(0, 1.92, -0.7), 0.78, 0.72, 0.9, r.c1, "Wood")
			-- the neck and head, leaning forward, with a lighter muzzle, nostrils and eyes
			r:beam(Vector3.new(0, 1.9, 0.75), Vector3.new(0, 2.75, 1.25), 0.44, 0.5, r.c1, "Wood")
			local head = CFrame.new(0, 2.78, 1.4) * CFrame.Angles(0.55, 0, 0)
			r:lump(head, 0.46, 0.5, 0.82, r.c1, "Wood")
			r:lump(head * CFrame.new(0, -0.05, 0.36), 0.38, 0.38, 0.34, shade(r.c1, 0.86), "Wood")
			for _, sx in { -1, 1 } do
				r:boxAt(head * CFrame.new(sx * 0.1, 0.0, 0.53), 0.06, 0.08, 0.04, C.Black, "SmoothPlastic")
				local eye = (head * CFrame.new(sx * 0.21, 0.12, 0.02)).Position
				r:ball(eye.X, eye.Y, eye.Z, 0.1, C.Black, "SmoothPlastic")
				-- pointed ears
				r:add({
					shape = "Cone",
					cf = head * CFrame.new(sx * 0.13, 0.32, -0.22) * CFrame.Angles(-0.3, 0, sx * -0.2),
					size = Vector3.new(0.14, 0.26, 0.12),
					color = r.c1,
					mat = "Wood",
				})
			end
			-- a mane of tufts down the neck, a forelock and a tail
			for k = 0, 5 do
				local t = k / 5
				local p = Vector3.new(0, 2.05, 0.55):Lerp(Vector3.new(0, 2.95, 1.08), t)
				r:lump(CFrame.new(p) * CFrame.Angles(0.4 + k, 0.2 * k, 0.3), 0.2, 0.24, 0.26, mane, "Fabric")
			end
			r:lump(head * CFrame.new(0, 0.28, 0.1) * CFrame.Angles(0.3, 0.4, 0), 0.18, 0.12, 0.22, mane, "Fabric")
			r:beam(Vector3.new(0, 2.05, -1.1), Vector3.new(0, 1.65, -1.45), 0.2, 0.18, mane, "Fabric")
			r:beam(Vector3.new(0, 1.7, -1.42), Vector3.new(0, 1.15, -1.5), 0.24, 0.16, mane, "Fabric")
			-- a saddle with a raised front and back on a cloth, stirrups hanging on straps
			r:block(-0.43, 2.18, -0.35, 0.43, 2.26, 0.4, r.c2, "Fabric")
			r:block(-0.45, 1.68, -0.25, -0.41, 2.22, 0.3, r.c2, "Fabric")
			r:block(0.41, 1.68, -0.25, 0.45, 2.22, 0.3, r.c2, "Fabric")
			r:block(-0.48, 1.68, -0.25, -0.45, 1.74, 0.3, C.Yellow, "Fabric")
			r:block(0.45, 1.68, -0.25, 0.48, 1.74, 0.3, C.Yellow, "Fabric")
			r:block(-0.3, 2.26, -0.25, 0.3, 2.36, 0.3, Color3.fromRGB(122, 88, 62), "Fabric")
			r:cyl(0, 2.38, 0.26, 0.5, 0.18, "x", Color3.fromRGB(122, 88, 62), "Fabric")
			r:cyl(0, 2.4, -0.22, 0.56, 0.22, "x", Color3.fromRGB(122, 88, 62), "Fabric")
			for _, sx in { -1, 1 } do
				r:block(sx * 0.5 - 0.02, 1.2, 0.0, sx * 0.5 + 0.02, 1.68, 0.05, C.Bark, "Fabric")
				r:block(sx * 0.5 - 0.05, 1.12, -0.1, sx * 0.5 + 0.05, 1.2, 0.15, C.DarkMetal, "Metal")
			end
			-- a bridle and reins, and the handle through the head
			for _, sx in { -1, 1 } do
				r:beam(
					(head * CFrame.new(sx * 0.24, -0.12, 0.42)).Position,
					Vector3.new(sx * 0.27, 2.42, 0.32),
					0.03,
					0.04,
					r.c2,
					"Fabric"
				)
			end
			r:cyl(0, 2.88, 1.3, 1.0, 0.1, "x", r.c2, "Wood")
			for _, sx in { -1, 1 } do
				r:cyl(sx * 0.5, 2.88, 1.3, 0.1, 0.16, "x", shade(r.c2, 0.85), "Wood")
			end
		end,
	},
}

return items
