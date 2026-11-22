--!strict
-- TVs, music, games and toys. c1 is the main body, c2 an accent (a screen, a seat, trim).

local Recipe = require(script.Parent.Parent.Recipe)
local Colors = require(script.Parent.Parent.Parent.Util.Colors)

local C = Recipe.Colors

type R = Recipe.Recipe

local function shade(c: Color3, k: number): Color3
	return Colors.shade(c, k)
end

-- A curved runner of three straight pieces through four points, joints closed up.
local function rocker(r: R, pts: { Vector3 }, size: number, color: Color3)
	for i = 1, #pts - 1 do
		local a, b = pts[i], pts[i + 1]
		local d = (b - a).Unit * 0.08
		r:beam(if i > 1 then a - d else a, if i < #pts - 1 then b + d else b, size, size, color, "Wood")
	end
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
		c1 = "A8743F",
		c2 = "2B282E",
		tags = { "tv" },
		build = function(r: R)
			for _, sx in { -1, 1 } do
				for _, sz in { -1, 1 } do
					r:box(sx * 2.25, 0.15, sz * 0.6, 0.25, 0.3, 0.25, shade(r.c1, 0.8), "Wood")
				end
			end
			r:block(-2.5, 0.3, -0.8, 2.5, 1.6, 0.8, r.c1, "Wood")
			r:block(-2.5, 1.6, -0.85, 2.5, 1.75, 0.85, shade(r.c1, 0.88), "Wood")
			-- two doors and an open middle with a games console in it
			for _, sx in { -1, 1 } do
				local xa, xb = sx * 0.85, sx * 2.4
				r:block(math.min(xa, xb), 0.4, 0.8, math.max(xa, xb), 1.5, 0.86, shade(r.c1, 1.08), "Wood")
				r:ball(sx * 1.0, 0.95, 0.9, 0.14, C.Gold, "Metal")
			end
			r:block(-0.8, 0.4, -0.7, 0.8, 1.5, 0.75, shade(r.c1, 0.55), "Wood")
			r:block(-0.6, 0.4, -0.4, 0.6, 0.65, 0.5, C.White, "SmoothPlastic")
			r:block(-0.1, 0.48, 0.5, 0.1, 0.56, 0.52, C.Blue, "Neon")
			-- the TV
			r:block(-0.8, 1.75, -0.45, 0.8, 1.85, 0.1, r.c2, "Metal")
			r:block(-0.15, 1.85, -0.3, 0.15, 2.4, -0.1, r.c2, "Metal")
			r:block(-2.1, 2.2, -0.3, 2.1, 4.7, -0.08, r.c2, "SmoothPlastic")
			r:block(-1.95, 2.35, -0.08, 1.95, 4.55, -0.05, Color3.fromRGB(40, 52, 70), "Glass")
			r:boxAt(
				CFrame.new(0.6, 3.6, -0.04) * CFrame.Angles(0, 0, -0.7),
				0.25,
				2.2,
				0.02,
				Color3.fromRGB(62, 78, 102),
				"Glass"
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
		c1 = "8A5A2E",
		c2 = "C7383F",
		tags = { "music" },
		build = function(r: R)
			r:block(-0.9, 0, -0.75, 0.9, 0.45, 0.75, r.c1, "Wood")
			r:block(-0.85, 0.45, -0.7, 0.85, 0.5, 0.7, shade(r.c1, 0.8), "Wood")
			r:cyl(-0.2, 0.525, 0, 0.05, 1.15, "y", C.DarkMetal, "Metal")
			r:cyl(-0.2, 0.565, 0, 0.03, 1.05, "y", C.Black, "SmoothPlastic")
			r:cyl(-0.2, 0.585, 0, 0.02, 0.36, "y", r.c2, "SmoothPlastic")
			r:cyl(-0.2, 0.62, 0, 0.06, 0.05, "y", C.Metal, "Metal")
			-- the arm, resting on the record
			r:cyl(0.6, 0.56, -0.45, 0.12, 0.22, "y", C.Metal, "Metal")
			r:beam(Vector3.new(0.6, 0.66, -0.45), Vector3.new(0.18, 0.64, 0.22), 0.05, 0.05, C.Metal, "Metal")
			r:block(0.1, 0.6, 0.18, 0.26, 0.66, 0.3, C.DarkMetal, "Metal")
			for _, x in { 0.5, 0.75 } do
				r:cyl(x, 0.22, 0.77, 0.06, 0.14, "z", C.Gold, "Metal")
			end
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
		c2 = "8C2F39",
		tags = { "music" },
		build = function(r: R)
			r:block(-2.4, 0, -2.0, 2.4, 4.3, -0.85, r.c1, "SmoothPlastic")
			r:block(-2.5, 4.3, -2.05, 2.5, 4.5, -0.75, shade(r.c1, 1.3), "SmoothPlastic")
			r:block(-2.2, 0.1, -0.85, 2.2, 2.3, -0.8, shade(r.c1, 1.2), "SmoothPlastic")
			-- side cheeks hold the keyboard
			for _, sx in { -1, 1 } do
				r:block(sx * 2.3 - 0.12, 0, -0.85, sx * 2.3 + 0.12, 2.75, 0.15, r.c1, "SmoothPlastic")
			end
			r:block(-2.18, 2.3, -0.85, 2.18, 2.55, 0.1, r.c1, "SmoothPlastic")
			r:block(-2.15, 2.55, -0.65, 2.15, 2.65, 0.08, C.White, "SmoothPlastic")
			-- black keys in groups of two and three
			for octave = 0, 2 do
				for i = 1, 5 do
					local kx = -1.85 + octave * 1.4 + (i - 1) * 0.2 + (if i > 2 then 0.2 else 0)
					r:block(kx, 2.65, -0.65, kx + 0.1, 2.72, -0.2, C.Black, "SmoothPlastic")
				end
			end
			r:block(-2.18, 2.55, -0.85, 2.18, 2.95, -0.65, r.c1, "SmoothPlastic")
			-- music stand with a page
			r:block(-0.9, 2.95, -0.88, 0.9, 3.65, -0.78, shade(r.c1, 1.3), "SmoothPlastic")
			r:block(-0.6, 3.0, -0.78, 0.6, 3.55, -0.75, C.Paper, "SmoothPlastic")
			for _, px in { -0.35, 0, 0.35 } do
				r:block(px - 0.1, 0.15, -0.8, px + 0.1, 0.25, -0.5, C.Gold, "Metal")
			end
			-- the bench
			for _, sx in { -1, 1 } do
				for _, sz in { -1, 1 } do
					r:box(sx * 1.1, 0.8, 1.3 + sz * 0.3, 0.2, 1.6, 0.2, r.c1, "SmoothPlastic")
				end
			end
			r:block(-1.3, 1.6, 0.8, 1.3, 1.75, 1.8, r.c1, "SmoothPlastic")
			r:block(-1.2, 1.75, 0.88, 1.2, 1.95, 1.72, r.c2, "Fabric")
			r:seat(0, 1.95, 1.3, 180)
		end,
	},
	{
		id = "arcade",
		name = "Arcade machine",
		cat = "fun",
		price = 450,
		place = "floor",
		size = Vector3.new(2.4, 6.2, 2.4),
		c1 = "5C3D8F",
		c2 = "F2C14E",
		tags = { "games" },
		build = function(r: R)
			-- side panels: deep at the bottom, set back at the screen, out again at the sign
			for _, sx in { -1, 1 } do
				local x1, x2 = sx * 1.08, sx * 1.2
				local xa, xb = math.min(x1, x2), math.max(x1, x2)
				r:block(xa, 0, -1.2, xb, 3.35, 1.05, r.c1, "SmoothPlastic")
				r:block(xa, 3.35, -1.2, xb, 5.2, 0.35, r.c1, "SmoothPlastic")
				r:block(xa, 5.2, -1.2, xb, 6.2, 0.65, r.c1, "SmoothPlastic")
				r:block(xa - 0.01, 0, 0.85, xb + 0.01, 3.35, 1.05, r.c2, "SmoothPlastic")
			end
			r:block(-1.08, 0, -1.2, 1.08, 3.05, 0.95, shade(r.c1, 0.75), "SmoothPlastic")
			r:block(-0.35, 0.9, 0.95, 0.35, 1.7, 1.0, C.DarkMetal, "Metal")
			for _, x in { -0.15, 0.15 } do
				r:block(x - 0.05, 1.2, 1.0, x + 0.05, 1.4, 1.02, C.Yellow, "Neon")
			end
			-- the control panel, sloping toward the player
			r:boxAt(CFrame.new(0, 3.2, 0.6) * CFrame.Angles(0.25, 0, 0), 2.16, 0.3, 0.95, C.Black, "SmoothPlastic")
			r:cyl(-0.5, 3.45, 0.6, 0.25, 0.08, "y", C.Black, "Metal")
			r:ball(-0.5, 3.6, 0.6, 0.22, C.Red, "Plastic")
			for i, col in { C.Red, C.Blue, C.Yellow } do
				r:cyl(0.05 + i * 0.25, 3.36, 0.55 + (i % 2) * 0.12, 0.06, 0.16, "y", col, "Plastic")
			end
			-- the screen, leaning back, with a game on it
			local scr = CFrame.new(0, 4.25, -0.05) * CFrame.Angles(-0.2, 0, 0)
			r:boxAt(scr, 2.1, 1.85, 0.2, C.Black, "SmoothPlastic")
			local screen =
				r:boxAt(scr * CFrame.new(0, 0, 0.1), 1.8, 1.5, 0.04, Color3.fromRGB(46, 58, 120), "SmoothPlastic")
			r:glow(screen, 8, 0.6, Color3.fromRGB(140, 160, 255))
			r:boxAt(scr * CFrame.new(-0.4, -0.3, 0.13), 0.2, 0.2, 0.03, C.Yellow, "Neon")
			r:boxAt(scr * CFrame.new(0.3, 0.2, 0.13), 0.2, 0.2, 0.03, C.Pink, "Neon")
			r:boxAt(scr * CFrame.new(0, -0.6, 0.13), 1.6, 0.08, 0.03, Color3.fromRGB(120, 220, 140), "Neon")
			r:block(-1.08, 3.05, -1.2, 1.08, 5.2, -0.3, shade(r.c1, 0.75), "SmoothPlastic")
			-- the lit sign at the top
			r:block(-1.08, 5.2, -1.2, 1.08, 6.0, 0.6, shade(r.c1, 0.75), "SmoothPlastic")
			r:block(-1.0, 5.3, 0.6, 1.0, 5.9, 0.65, r.c2, "SmoothPlastic")
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
		c1 = "8A5A2E",
		c2 = "D9805F",
		tags = { "games" },
		build = function(r: R)
			r:block(-1.3, 2.6, -1.3, 1.3, 2.8, 1.3, r.c1, "Wood")
			r:legs(2.6, 2.6, 2.6, 0.25, 0.12, shade(r.c1, 0.85), "Wood")
			-- a checkered board with a few pieces left mid game
			r:block(-0.9, 2.8, -0.9, 0.9, 2.84, 0.9, C.Cream, "Wood")
			for i = 0, 3 do
				for j = 0, 3 do
					if (i + j) % 2 == 0 then
						local x, z = -0.9 + i * 0.45, -0.9 + j * 0.45
						r:block(x, 2.84, z, x + 0.45, 2.86, z + 0.45, Color3.fromRGB(110, 76, 48), "Wood")
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
				r:cyl(p[1], 2.92, p[2], 0.12, 0.32, "y", if p[3] == 1 then C.Red else C.Black, "Plastic")
			end
			-- a stool on each side
			for _, sx in { -1, 1 } do
				local x = sx * 2.1
				r:cyl(x, 0.05, 0, 0.1, 0.9, "y", shade(r.c1, 0.85), "Wood")
				r:cyl(x, 0.9, 0, 1.7, 0.25, "y", shade(r.c1, 0.85), "Wood")
				r:cyl(x, 1.82, 0, 0.25, 1.2, "y", r.c2, "Fabric")
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
		c2 = "4FA9D9",
		tags = { "desk", "games" },
		build = function(r: R)
			r:block(-2.3, 2.8, -1.2, 2.3, 3.0, 1.2, r.c1, "Wood")
			for _, sx in { -1, 1 } do
				r:block(sx * 2.15 - 0.12, 0, -1.1, sx * 2.15 + 0.12, 2.8, 1.1, shade(r.c1, 0.9), "Wood")
			end
			r:block(-2.03, 1.4, -1.1, 2.03, 2.8, -1.0, shade(r.c1, 0.9), "Wood")
			-- the screen
			r:block(-0.45, 3.0, -0.8, 0.45, 3.06, -0.35, C.DarkMetal, "Metal")
			r:block(-0.1, 3.06, -0.7, 0.1, 3.6, -0.55, C.DarkMetal, "Metal")
			r:block(-1.25, 3.35, -0.62, 1.25, 4.9, -0.46, C.Black, "SmoothPlastic")
			local display = r:block(-1.12, 3.47, -0.46, 1.12, 4.78, -0.44, r.c2, "SmoothPlastic")
			r:glow(display, 6, 0.5, Color3.fromRGB(170, 210, 255))
			r:block(-0.9, 3.8, -0.44, 0.1, 4.5, -0.43, C.White, "SmoothPlastic")
			r:block(0.3, 3.8, -0.44, 0.9, 4.1, -0.43, C.Yellow, "SmoothPlastic")
			-- keyboard, mouse and a mug
			r:block(-0.8, 3.0, 0.1, 0.8, 3.08, 0.6, Color3.fromRGB(210, 210, 214), "SmoothPlastic")
			r:block(-0.72, 3.08, 0.17, 0.72, 3.1, 0.53, C.DarkMetal, "SmoothPlastic")
			r:block(1.05, 3.0, 0.2, 1.25, 3.08, 0.5, Color3.fromRGB(210, 210, 214), "SmoothPlastic")
			r:cyl(-1.6, 3.2, 0.3, 0.4, 0.32, "y", C.Red, "SmoothPlastic")
			-- the computer under the desk, with a light on the front
			r:block(1.1, 0, -0.9, 1.85, 1.9, 0.75, C.DarkMetal, "Metal")
			r:block(1.4, 0.4, 0.75, 1.55, 1.6, 0.78, C.Blue, "Neon")
		end,
	},
	{
		id = "drum_kit",
		name = "Drum kit",
		cat = "fun",
		price = 500,
		place = "floor",
		size = Vector3.new(4.4, 4.3, 3.6),
		c1 = "C7383F",
		c2 = "C9CCD3",
		tags = { "music" },
		build = function(r: R)
			-- the big drum lying on its side, its skin facing out
			r:cyl(0, 1.0, 0.5, 1.2, 2.0, "z", r.c1, "SmoothPlastic")
			for _, z in { -0.1, 1.1 } do
				r:cyl(0, 1.0, z, 0.1, 2.08, "z", r.c2, "Metal")
			end
			r:cyl(0, 1.0, 1.12, 0.04, 1.8, "z", C.White, "SmoothPlastic")
			r:cyl(0, 1.0, 1.15, 0.03, 0.8, "z", r.c1, "SmoothPlastic")
			-- two small drums on top and a tall one on the floor
			for _, x in { -0.5, 0.5 } do
				r:cyl(x, 2.3, 0.35, 0.55, 0.8, "y", r.c1, "SmoothPlastic")
				r:cyl(x, 2.59, 0.35, 0.03, 0.8, "y", C.White, "SmoothPlastic")
			end
			r:cyl(1.45, 0.95, -0.4, 1.0, 1.1, "y", r.c1, "SmoothPlastic")
			r:cyl(1.45, 1.46, -0.4, 0.03, 1.1, "y", C.White, "SmoothPlastic")
			for _, dz in { -0.35, 0.35 } do
				r:block(1.85, 0, -0.4 + dz - 0.04, 1.93, 0.6, -0.4 + dz + 0.04, r.c2, "Metal")
			end
			-- the snare on its stand
			r:cyl(-1.3, 0.9, 0.1, 1.8, 0.1, "y", r.c2, "Metal")
			r:cyl(-1.3, 0.04, 0.1, 0.08, 0.7, "y", r.c2, "Metal")
			r:cyl(-1.3, 2.0, 0.1, 0.45, 1.0, "y", r.c2, "Metal")
			r:cyl(-1.3, 2.24, 0.1, 0.03, 1.0, "y", C.White, "SmoothPlastic")
			-- two cymbals
			for _, p in { { -1.75, 3.6, 1.0 }, { 1.75, 3.9, 0.9 } } do
				r:cyl(p[1], p[2] / 2, p[3], p[2], 0.08, "y", r.c2, "Metal")
				r:cyl(p[1], 0.04, p[3], 0.08, 0.6, "y", r.c2, "Metal")
				r:cyl(p[1], p[2], p[3], 0.05, 1.3, "y", C.Gold, "Metal")
			end
			-- the drummer's stool
			r:cyl(0, 0.04, -1.3, 0.08, 0.8, "y", r.c2, "Metal")
			r:cyl(0, 0.85, -1.3, 1.6, 0.14, "y", r.c2, "Metal")
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
		c2 = "C7383F",
		tags = { "toy" },
		build = function(r: R)
			local wood = shade(r.c1, 0.75)
			for _, sx in { -1, 1 } do
				local x = sx * 0.55
				rocker(r, {
					Vector3.new(x, 0.55, -1.7),
					Vector3.new(x, 0.12, -0.6),
					Vector3.new(x, 0.12, 0.6),
					Vector3.new(x, 0.55, 1.7),
				}, 0.18, wood)
				for _, sz in { -1, 1 } do
					r:beam(
						Vector3.new(x, 0.15, sz * 0.95),
						Vector3.new(sx * 0.28, 1.55, sz * 0.75),
						0.16,
						0.16,
						wood,
						"Wood"
					)
				end
			end
			-- body, saddle, neck and head
			r:block(-0.38, 1.5, -1.0, 0.38, 2.15, 0.95, r.c1, "Wood")
			r:block(-0.42, 2.15, -0.35, 0.42, 2.27, 0.4, r.c2, "Fabric")
			r:beam(Vector3.new(0, 1.95, 0.7), Vector3.new(0, 2.75, 1.15), 0.5, 0.55, r.c1, "Wood")
			local head = CFrame.new(0, 2.8, 1.38) * CFrame.Angles(0.5, 0, 0)
			r:boxAt(head, 0.5, 0.5, 0.95, r.c1, "Wood")
			for _, sx in { -1, 1 } do
				r:boxAt(head * CFrame.new(sx * 0.15, 0.32, -0.3), 0.12, 0.25, 0.12, r.c1, "Wood")
				r:boxAt(head * CFrame.new(sx * 0.26, 0.08, 0), 0.03, 0.1, 0.1, C.Black, "SmoothPlastic")
			end
			-- mane, tail and the handle through the head
			r:beam(Vector3.new(0, 2.25, 0.62), Vector3.new(0, 3.05, 1.1), 0.18, 0.18, C.Bark, "Fabric")
			r:beam(Vector3.new(0, 2.05, -1.0), Vector3.new(0, 1.35, -1.4), 0.16, 0.16, C.Bark, "Fabric")
			r:cyl(0, 2.85, 1.25, 1.0, 0.1, "x", r.c2, "Wood")
		end,
	},
}

return items
