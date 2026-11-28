--!strict
-- More decor across the looks (the user: "Add much more decor"): a gnome on his toadstool, a tower
-- of herb pots, a knitting basket, a ladder of plants, a driftwood signpost, a clam shell planter,
-- a gumball machine, a marble bust, hay bales with pumpkins, a tall vase of branches and a stone
-- lantern. Still pieces, at the starting house's level of detail, in textured materials, round
-- where the real thing is round.

local Recipe = require(script.Parent.Parent.Recipe)
local K = require(script.Parent.Parent.RecipeKit)
local Colors = require(script.Parent.Parent.Parent.Util.Colors)

local C = Recipe.Colors

type R = Recipe.Recipe
type Prim = Recipe.Prim

local CLAY = Color3.fromRGB(196, 120, 86)
local SOIL = Color3.fromRGB(92, 66, 46)
local CREAM = Color3.fromRGB(246, 240, 226)
local INK = Color3.fromRGB(52, 48, 56)
local TWINE = Color3.fromRGB(196, 172, 128)
local STONE = Color3.fromRGB(160, 156, 150)

local function shade(c: Color3, k: number): Color3
	return Colors.shade(c, k)
end

local function mix(a: Color3, b: Color3, t: number): Color3
	return Colors.mix(a, b, t)
end

-- A clay pot at (x, y, z), its foot at y: a body, a rim, soil in it. Returns the soil's top.
local function pot(r: R, x: number, y: number, z: number, d: number, h: number, col: Color3): number
	K.disc(r, x, y + h * 0.3, z, h * 0.6, d * 0.78, col, "Brick")
	K.disc(r, x, y + h * 0.72, z, h * 0.3, d * 0.9, col, "Brick")
	K.disc(r, x, y + h - 0.06, z, 0.14, d * 1.08, shade(col, 1.08), "Brick")
	K.disc(r, x, y + h - 0.08, z, 0.04, d * 0.86, SOIL, "Ground")
	return y + h - 0.06
end

-- A sprig of herbs from (x, y, z): a few stems with leaves along them.
local function herb(r: R, x: number, y: number, z: number, h: number, col: Color3, seed: number)
	for k = 0, 3 do
		local a = seed + k * 1.6
		local tip = Vector3.new(x + math.cos(a) * h * 0.3, y + h * (0.7 + (k % 2) * 0.3), z + math.sin(a) * h * 0.3)
		local stem = r:beam(Vector3.new(x, y, z), tip, 0.03, 0.03, shade(col, 0.8), "Grass")
		if stem then
			stem.collide = false
		end
		for j = 1, 3 do
			local p = Vector3.new(x, y, z):Lerp(tip, j / 3.3)
			r:noCollide(r:lump(CFrame.new(p) * CFrame.Angles(0, a + j, 0.5), 0.2, 0.05, 0.11, col, "Grass"))
		end
	end
end

-- A pumpkin at (x, y, z), its foot at y: ribbed lumps round a stalk.
local function pumpkin(r: R, x: number, y: number, z: number, d: number, col: Color3)
	for k = 0, 5 do
		local a = k * math.pi / 3
		r:lump(
			CFrame.new(x + math.cos(a) * d * 0.18, y + d * 0.36, z + math.sin(a) * d * 0.18) * CFrame.Angles(0, -a, 0),
			d * 0.55,
			d * 0.72,
			d * 0.42,
			if k % 2 == 0 then col else shade(col, 0.92),
			"Fabric"
		)
	end
	r:cyl(x, y + d * 0.76, z, d * 0.18, d * 0.1, "y", Color3.fromRGB(110, 120, 70), "Wood")
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
	surface: number?,
	gives: string?,
	build: (r: R) -> (),
}

local items: { Item } = {
	{
		id = "decor_gnome_toadstool",
		name = "Gnome on a toadstool",
		cat = "garden",
		style = "playful",
		price = 70,
		place = "ground",
		size = Vector3.new(1.8, 2.6, 1.8),
		c1 = "D9625E",
		c2 = "6E9FC2",
		build = function(r: R)
			-- a big toadstool: a pale stalk and a spotted cap
			r:cyl(0, 0.5, 0, 1.0, 0.5, "y", CREAM, "Plaster").smooth = true
			K.disc(r, 0, 0.04, 0, 0.08, 0.7, shade(CREAM, 0.9), "Plaster")
			local cap = r:ball(0, 1.05, 0, 1.7, r.c1, "Plaster")
			cap.size = Vector3.new(1.7, 0.6, 1.7)
			cap.smooth = true
			K.disc(r, 0, 0.98, 0, 0.06, 1.5, CREAM, "Plaster")
			for i, p in { { 0.4, 0.2 }, { -0.35, 0.4 }, { 0.1, -0.5 }, { -0.5, -0.2 }, { 0.55, -0.35 } } do
				local spot = r:lump(
					CFrame.new(p[1], 1.28 - (p[1] ^ 2 + p[2] ^ 2) * 0.35, p[2])
						* CFrame.Angles(p[2] * 0.6, i, -p[1] * 0.6),
					0.22,
					0.06,
					0.2,
					CREAM,
					"Plaster"
				)
				spot.collide = false
			end
			-- the gnome sitting on it, legs over the edge: boots, trousers, a coat, a white beard,
			-- a round nose and a tall pointed hat
			local y = 1.32
			for _, sx in { -1, 1 } do
				r:cyl(sx * 0.13, y + 0.04, 0.32, 0.4, 0.14, "z", r.c2, "Fabric")
				r:cyl(sx * 0.13, y - 0.12, 0.54, 0.3, 0.13, "y", r.c2, "Fabric")
				r:lump(CFrame.new(sx * 0.13, y - 0.3, 0.6), 0.16, 0.12, 0.24, Color3.fromRGB(96, 70, 52), "Leather")
			end
			r:lump(CFrame.new(0, y + 0.3, 0.1), 0.5, 0.56, 0.42, r.c2, "Fabric")
			r:block(-0.25, y + 0.12, -0.05, 0.25, y + 0.18, 0.31, Color3.fromRGB(96, 70, 52), "Leather")
			K.sphere(r, 0, y + 0.68, 0.12, 0.36, Color3.fromRGB(240, 206, 180), "Plaster")
			r:lump(CFrame.new(0, y + 0.5, 0.26) * CFrame.Angles(-0.4, 0, 0), 0.34, 0.4, 0.14, CREAM, "Fabric")
			K.sphere(r, 0, y + 0.66, 0.3, 0.11, Color3.fromRGB(232, 150, 130), "Plaster")
			for _, sx in { -1, 1 } do
				K.sphere(r, sx * 0.08, y + 0.74, 0.27, 0.04, INK, "Metal")
				r:lump(
					CFrame.new(sx * 0.27, y + 0.3, 0.16) * CFrame.Angles(0.5, 0, sx * 0.3),
					0.12,
					0.3,
					0.12,
					r.c2,
					"Fabric"
				)
				K.sphere(r, sx * 0.3, y + 0.16, 0.26, 0.1, Color3.fromRGB(240, 206, 180), "Plaster")
			end
			K.disc(r, 0, y + 0.82, 0.1, 0.06, 0.42, r.c1, "Fabric")
			local hat = r:cone(0, y + 1.1, 0.08, 0.62, 0.4, r.c1, "Fabric")
			hat.cf = CFrame.new(0, y + 1.1, 0.04) * CFrame.Angles(-0.25, 0, 0)
		end,
	},
	{
		id = "decor_herb_tower",
		name = "Herb pot tower",
		cat = "garden",
		style = "garden",
		price = 60,
		place = "ground",
		size = Vector3.new(1.6, 2.4, 1.6),
		c1 = "C47A56",
		c2 = "6FA05E",
		gives = "herbs",
		build = function(r: R)
			-- three clay pots stacked on a rod, each tipped a little, herbs spilling out of each
			r:cyl(0, 1.1, 0, 2.2, 0.06, "y", Color3.fromRGB(90, 88, 96), "Metal")
			local pots = {
				{ y = 0, d = 1.2, h = 0.7, x = 0, z = 0, tip = 0 },
				{ y = 0.62, d = 0.95, h = 0.6, x = 0.12, z = 0.08, tip = 0.25 },
				{ y = 1.14, d = 0.75, h = 0.5, x = -0.1, z = -0.06, tip = -0.3 },
			}
			for i, p in pots do
				local top = pot(r, p.x, p.y, p.z, p.d, p.h, if i == 2 then shade(r.c1, 1.08) else r.c1)
				local lean = Vector3.new(math.sin(p.tip), 0, math.cos(p.tip)) * p.d * 0.25
				herb(
					r,
					p.x + lean.X,
					top,
					p.z + lean.Z,
					0.75 + i * 0.05,
					if i == 3 then mix(r.c2, C.Yellow, 0.25) else r.c2,
					i * 2
				)
				herb(r, p.x - lean.X * 0.5, top, p.z - lean.Z * 0.5, 0.6, shade(r.c2, 0.85), i * 3 + 1)
			end
			-- a little slate label in the bottom pot
			r:block(0.32, 0.62, 0.3, 0.52, 0.76, 0.32, INK, "Slate")
			r:block(0.41, 0.4, 0.3, 0.43, 0.62, 0.32, C.Bark, "Wood")
		end,
	},
	{
		id = "decor_knitting_basket",
		name = "Knitting basket",
		cat = "decor",
		style = "cozy",
		price = 40,
		place = "floor",
		size = Vector3.new(1.6, 1.3, 1.4),
		c1 = "B89466",
		c2 = "C9707A",
		build = function(r: R)
			-- a round woven basket, its weave in rings, a rim and a handle over it
			for k = 0, 4 do
				K.hoop(
					r,
					0,
					0.12 + k * 0.14,
					0,
					0.58 + k * 0.02,
					16,
					0.14,
					if k % 2 == 0 then r.c1 else shade(r.c1, 0.88),
					"Fabric"
				)
			end
			K.disc(r, 0, 0.06, 0, 0.1, 1.1, shade(r.c1, 0.85), "Fabric")
			K.hoop(r, 0, 0.78, 0, 0.68, 18, 0.08, shade(r.c1, 0.8), "Wood")
			K.path(r, {
				Vector3.new(-0.66, 0.78, 0),
				Vector3.new(-0.5, 1.12, 0),
				Vector3.new(0, 1.26, 0),
				Vector3.new(0.5, 1.12, 0),
				Vector3.new(0.66, 0.78, 0),
			}, 0.06, shade(r.c1, 0.8), "Wood")
			-- balls of wool in it, two needles stuck in one, and a scarf spilling over the side
			for i, b in
				{
					{ x = -0.22, z = 0.12, d = 0.44, col = r.c2 },
					{ x = 0.22, z = -0.15, d = 0.4, col = Color3.fromRGB(120, 168, 200) },
					{ x = 0.12, z = 0.28, d = 0.36, col = CREAM },
				}
			do
				local ball = K.sphere(r, b.x, 0.74, b.z, b.d, b.col, "Fabric")
				ball.collide = false
				K.hoop(r, b.x, 0.74, b.z, b.d * 0.48, 10, 0.02, shade(b.col, 0.85), "Fabric")
				if i == 1 then
					for _, a in { -0.3, 0.3 } do
						K.rod(
							r,
							Vector3.new(b.x, 0.74, b.z),
							Vector3.new(b.x + a, 1.2, b.z - 0.15),
							0.03,
							C.Bark,
							"Wood"
						)
					end
				end
			end
			for k = 0, 4 do
				local z = 0.5 + k * 0.03
				r:block(
					-0.1,
					0.72 - k * 0.16,
					z,
					0.25,
					0.86 - k * 0.16,
					z + 0.04,
					if k % 2 == 0 then r.c2 else shade(r.c2, 0.88),
					"Fabric"
				)
			end
		end,
	},
	{
		id = "decor_plant_ladder",
		name = "Plant ladder",
		cat = "storage",
		style = "cozy",
		price = 95,
		place = "floor",
		size = Vector3.new(2.4, 4.2, 1.4),
		c1 = "B48A60",
		c2 = "6FA05E",
		tags = { "plant" },
		build = function(r: R)
			local wood = r.c1
			-- an A of two sides leaning together, with three shelves stepping back as they rise
			for _, sx in { -1, 1 } do
				r:beam(Vector3.new(sx * 1.1, 0, 0.6), Vector3.new(sx * 1.1, 4.1, -0.15), 0.12, 0.14, wood, "Wood")
				r:beam(
					Vector3.new(sx * 1.1, 0, -0.6),
					Vector3.new(sx * 1.1, 4.1, -0.25),
					0.1,
					0.12,
					shade(wood, 0.9),
					"Wood"
				)
			end
			for i = 0, 2 do
				local y = 0.8 + i * 1.15
				local front = 0.6 - (y / 4.1) * 0.75
				local back = -0.6 + (y / 4.1) * 0.35
				r:block(-1.05, y, back, 1.05, y + 0.08, front, wood, "WoodPlanks")
				-- pots on each shelf: a trailing one, a round one and a spiky one
				local top = pot(r, -0.6, y + 0.08, (front + back) / 2, 0.5, 0.42, CLAY)
				for k = 0, 3 do
					local a = k * 1.4
					local tip = Vector3.new(
						-0.6 + math.cos(a) * 0.3,
						top - 0.5 - (k % 2) * 0.2,
						(front + back) / 2 + math.sin(a) * 0.3
					)
					local vine = r:beam(Vector3.new(-0.6, top, (front + back) / 2), tip, 0.05, 0.05, r.c2, "Grass")
					if vine then
						vine.collide = false
					end
					r:noCollide(r:lump(CFrame.new(tip), 0.14, 0.08, 0.12, r.c2, "Grass"))
				end
				local top2 = pot(r, 0.05, y + 0.08, (front + back) / 2, 0.44, 0.36, CREAM)
				r:noCollide(
					r:lump(
						CFrame.new(0.05, top2 + 0.16, (front + back) / 2),
						0.46,
						0.36,
						0.42,
						shade(r.c2, 0.9),
						"Grass"
					)
				)
				local top3 = pot(r, 0.62, y + 0.08, (front + back) / 2, 0.4, 0.34, Color3.fromRGB(120, 150, 170))
				for k = 0, 4 do
					local a = k * math.pi * 2 / 5 + i
					local tip =
						Vector3.new(0.62 + math.cos(a) * 0.12, top3 + 0.4, (front + back) / 2 + math.sin(a) * 0.12)
					local leaf = r:beam(
						Vector3.new(0.62, top3, (front + back) / 2),
						tip,
						0.06,
						0.03,
						mix(r.c2, C.Yellow, 0.15),
						"Grass"
					)
					if leaf then
						leaf.collide = false
					end
				end
			end
		end,
	},
	{
		id = "decor_driftwood_sign",
		name = "Driftwood signpost",
		cat = "garden",
		style = "seaside",
		price = 65,
		place = "ground",
		size = Vector3.new(2.6, 4.2, 1.2),
		c1 = "C8B89C",
		c2 = "6FA8C8",
		build = function(r: R)
			-- a bleached post in a cairn of pebbles, a rope wound round it
			local post = r.c1
			r:block(-0.12, 0, -0.12, 0.12, 3.9, 0.12, post, "Wood")
			r:cone(0, 3.96, 0, 0.14, 0.24, shade(post, 0.9), "Wood")
			for i = 0, 6 do
				local a = i / 7 * math.pi * 2
				r:lump(
					CFrame.new(math.cos(a) * 0.32, 0.12, math.sin(a) * 0.32) * CFrame.Angles(0, a, 0.2),
					0.34,
					0.24,
					0.28,
					shade(STONE, 0.9 + (i % 3) * 0.06),
					"Pebble"
				)
			end
			for k = 0, 3 do
				K.hoop(r, 0, 2.0 + k * 0.08, 0, 0.15, 8, 0.04, TWINE, "Fabric")
			end
			-- four boards pointing off different ways, painted with bands, ends cut to points
			local boards = {
				{ y = 3.4, yaw = 0.15, len = 1.2, flip = 1 },
				{ y = 2.95, yaw = -0.4, len = 1.0, flip = -1 },
				{ y = 2.5, yaw = 0.6, len = 1.1, flip = 1 },
				{ y = 1.5, yaw = -0.1, len = 0.9, flip = -1 },
			}
			for i, b in boards do
				local f = CFrame.new(0, b.y, 0) * CFrame.Angles(0, b.yaw, 0)
				local col = if i % 2 == 0 then r.c2 else shade(post, 1.05)
				r:boxAt(f * CFrame.new(b.flip * (b.len / 2 + 0.1), 0, 0.16), b.len, 0.3, 0.06, col, "Wood")
				r:tri(
					(f * CFrame.new(b.flip * (b.len + 0.1), 0.15, 0.16)).Position,
					(f * CFrame.new(b.flip * (b.len + 0.28), 0, 0.16)).Position,
					(f * CFrame.new(b.flip * (b.len + 0.1), -0.15, 0.16)).Position,
					0.06,
					col,
					"Wood"
				)
				r:boxAt(
					f * CFrame.new(b.flip * (b.len / 2 + 0.1), 0, 0.215),
					b.len * 0.7,
					0.06,
					0.02,
					shade(col, 0.75),
					"Wood"
				)
				r:boxAt(
					f * CFrame.new(b.flip * 0.2, 0, 0.245),
					0.05,
					0.05,
					0.02,
					Color3.fromRGB(150, 150, 156),
					"Metal"
				)
			end
			-- a starfish and a shell nailed on, for luck
			for k = 0, 4 do
				local a = k * math.pi * 2 / 5
				r:boxAt(
					CFrame.new(0, 1.0, 0.13) * CFrame.Angles(0, 0, a) * CFrame.new(0, 0.1, 0),
					0.06,
					0.2,
					0.04,
					Color3.fromRGB(232, 150, 110),
					"Plaster"
				)
			end
			r:lump(CFrame.new(0, 0.7, 0.14), 0.16, 0.14, 0.05, Color3.fromRGB(240, 210, 200), "Marble")
		end,
	},
	{
		id = "decor_shell_planter",
		name = "Clam shell planter",
		cat = "decor",
		style = "seaside",
		price = 50,
		place = "surface",
		size = Vector3.new(1.4, 0.9, 1.2),
		c1 = "F0E2D2",
		c2 = "8FB08A",
		gives = "shells",
		tags = { "plant" },
		build = function(r: R)
			-- the lower half of a big clam, ribbed, filled with sand and little succulents
			local base = r:ball(0, 0.26, 0, 1.3, r.c1, "Marble")
			base.size = Vector3.new(1.3, 0.5, 1.1)
			base.smooth = true
			for k = -3, 3 do
				local rib = r:block(0, 0, 0, 1, 1, 1, shade(r.c1, 0.92), "Marble")
				rib.cf = CFrame.new(0, 0.26, 0) * CFrame.Angles(0, k * 0.36, 0) * CFrame.new(0, -0.02, 0.36)
				rib.size = Vector3.new(0.05, 0.36, 0.3)
			end
			K.disc(r, 0, 0.55, 0, 0.04, 1.08, Color3.fromRGB(222, 202, 164), "Sand")
			for i, p in { { -0.25, 0.1, 0.3 }, { 0.2, -0.05, 0.34 }, { 0.05, 0.25, 0.24 } } do
				for k = 0, 6 do
					local a = k * math.pi * 2 / 7 + i
					local leaf = r:lump(
						CFrame.new(p[1] + math.cos(a) * p[3] * 0.25, 0.56, p[2] + math.sin(a) * p[3] * 0.25)
							* CFrame.Angles(0, -a, 0.6),
						p[3] * 0.5,
						0.06,
						p[3] * 0.26,
						if k % 2 == 0 then r.c2 else shade(r.c2, 0.9),
						"Grass"
					)
					leaf.collide = false
				end
				K.sphere(r, p[1], 0.58, p[2], p[3] * 0.3, mix(r.c2, Color3.fromRGB(220, 160, 170), 0.35), "Grass")
			end
			-- a hinge at the back and a few small shells on the sand
			r:block(-0.15, 0.4, -0.58, 0.15, 0.52, -0.5, shade(r.c1, 0.85), "Marble")
			for i, p in { { 0.4, 0.3 }, { -0.42, -0.2 } } do
				r:lump(
					CFrame.new(p[1], 0.52, p[2]) * CFrame.Angles(0, i, 0),
					0.14,
					0.06,
					0.12,
					Color3.fromRGB(236, 190, 180),
					"Marble"
				)
			end
		end,
	},
	{
		id = "decor_gumball_machine",
		name = "Gumball machine",
		cat = "fun",
		style = "playful",
		price = 120,
		place = "floor",
		size = Vector3.new(1.2, 3.4, 1.2),
		c1 = "D9504E",
		c2 = "F4CD5C",
		tags = { "toy" },
		build = function(r: R)
			local red = r.c1
			-- a round foot, a fluted stand and the coin box with its handle and chute
			K.disc(r, 0, 0.06, 0, 0.12, 1.0, red, "Metal")
			r:cyl(0, 0.75, 0, 1.3, 0.3, "y", red, "Metal").smooth = true
			for k = 0, 7 do
				local a = k * math.pi / 4
				r:block(
					math.cos(a) * 0.15 - 0.02,
					0.2,
					math.sin(a) * 0.15 - 0.02,
					math.cos(a) * 0.15 + 0.02,
					1.3,
					math.sin(a) * 0.15 + 0.02,
					shade(red, 0.85),
					"Metal"
				)
			end
			r:block(-0.38, 1.4, -0.38, 0.38, 2.0, 0.38, red, "Metal")
			r:block(-0.4, 1.98, -0.4, 0.4, 2.05, 0.4, r.c2, "Metal")
			K.face(r, 0, 1.78, 0.4, 0.06, 0.32, C.Metal, "Metal")
			r:block(-0.03, 1.66, 0.43, 0.03, 1.9, 0.47, C.Metal, "Metal")
			r:block(-0.1, 1.42, 0.38, 0.1, 1.56, 0.5, C.Metal, "Metal")
			r:block(-0.06, 1.62, 0.4, 0.06, 1.64, 0.44, INK, "Metal")
			-- the glass globe full of gumballs, and its cap
			local globe = K.sphere(r, 0, 2.5, 0, 0.9, C.Glass, "Glass")
			globe.transp = 0.6
			local cols = {
				r.c2,
				Color3.fromRGB(110, 180, 220),
				Color3.fromRGB(130, 200, 130),
				CREAM,
				Color3.fromRGB(232, 140, 180),
				red,
			}
			local n = 0
			for layer = 0, 2 do
				local y = 2.2 + layer * 0.18
				local rad = 0.28 - math.abs(layer - 1) * 0.05
				for k = 0, 7 do
					local a = k / 8 * math.pi * 2 + layer * 0.4
					n += 1
					K.sphere(r, math.cos(a) * rad, y, math.sin(a) * rad, 0.16, cols[(n % #cols) + 1], "Plaster")
				end
				K.sphere(r, 0, y, 0, 0.16, cols[((n + 3) % #cols) + 1], "Plaster")
			end
			K.disc(r, 0, 2.95, 0, 0.1, 0.4, red, "Metal")
			K.sphere(r, 0, 3.06, 0, 0.16, r.c2, "Metal")
		end,
	},
	{
		id = "decor_marble_bust",
		name = "Marble bust",
		cat = "decor",
		style = "fancy",
		price = 220,
		place = "floor",
		size = Vector3.new(1.4, 4.4, 1.4),
		c1 = "ECE8E0",
		c2 = "B8A07A",
		tags = { "art" },
		build = function(r: R)
			local stone = r.c1
			-- a plinth: a stepped foot, a column with a brass plate and a moulded top
			r:bevel(-0.6, 0, -0.6, 0.6, 0.2, 0.6, 0.07, shade(stone, 0.9), "Marble", { wear = 0.94 })
			r:bevel(-0.5, 0.2, -0.5, 0.5, 0.32, 0.5, 0.042, stone, "Marble", { wear = 0.94 })
			r:block(-0.4, 0.32, -0.4, 0.4, 2.3, 0.4, stone, "Marble")
			r:bevel(-0.5, 2.3, -0.5, 0.5, 2.42, 0.5, 0.042, stone, "Marble", { wear = 0.94 })
			r:block(-0.56, 2.42, -0.56, 0.56, 2.5, 0.56, shade(stone, 0.92), "Marble")
			r:block(-0.22, 1.6, 0.4, 0.22, 1.78, 0.43, r.c2, "Metal")
			-- the bust: a round foot, shoulders in a draped cloth, a neck and a head looking out
			K.disc(r, 0, 2.58, 0, 0.16, 0.5, stone, "Marble")
			r:lump(CFrame.new(0, 3.0, 0), 1.0, 0.6, 0.5, stone, "Marble")
			r:lump(
				CFrame.new(0.15, 3.05, 0.12) * CFrame.Angles(0, 0, 0.5),
				0.7,
				0.18,
				0.32,
				shade(stone, 0.94),
				"Marble"
			)
			r:cyl(0, 3.38, 0.02, 0.3, 0.26, "y", stone, "Marble")
			local head = r:ball(0, 3.75, 0.04, 0.56, stone, "Marble")
			head.size = Vector3.new(0.5, 0.62, 0.56)
			head.smooth = true
			r:lump(CFrame.new(0, 3.95, -0.04), 0.56, 0.36, 0.54, shade(stone, 0.95), "Marble")
			r:lump(CFrame.new(0, 3.72, 0.3) * CFrame.Angles(0.3, 0, 0), 0.08, 0.16, 0.1, stone, "Marble")
			for _, sx in { -1, 1 } do
				r:lump(CFrame.new(sx * 0.25, 3.74, 0.04), 0.06, 0.14, 0.1, shade(stone, 0.95), "Marble")
				r:block(sx * 0.1 - 0.05, 3.8, 0.29, sx * 0.1 + 0.05, 3.81, 0.31, shade(stone, 0.85), "Marble")
			end
			-- a laurel round the head
			for k = 0, 9 do
				local a = k / 10 * math.pi * 2
				r:lump(
					CFrame.new(math.cos(a) * 0.27, 3.92, 0.04 + math.sin(a) * 0.29) * CFrame.Angles(0, -a, 0.6),
					0.14,
					0.04,
					0.08,
					shade(stone, 0.9),
					"Marble"
				)
			end
		end,
	},
	{
		id = "decor_hay_pumpkins",
		name = "Hay bales and pumpkins",
		cat = "garden",
		style = "rustic",
		price = 85,
		place = "ground",
		size = Vector3.new(3.4, 2.4, 2.2),
		c1 = "D8B66A",
		c2 = "E08A3E",
		gives = "veg",
		build = function(r: R)
			local hay = r.c1
			-- two bales side by side and one on top, each tied with two strings, straw sticking out
			local function bale(cx: number, cy: number, cz: number, yaw: number)
				local f = CFrame.new(cx, cy, cz) * CFrame.Angles(0, yaw, 0)
				r:boxAt(f, 1.5, 0.8, 0.9, hay, "Fabric")
				r:boxAt(f * CFrame.new(0, 0.42, 0), 1.44, 0.02, 0.84, shade(hay, 1.06), "Fabric")
				for _, x in { -0.4, 0.4 } do
					r:boxAt(f * CFrame.new(x, 0, 0), 0.04, 0.92, 0.97, Color3.fromRGB(150, 120, 80), "Fabric")
				end
				for k = 0, 5 do
					local p = f * CFrame.new(-0.76, -0.3 + (k % 3) * 0.28, -0.35 + math.floor(k / 3) * 0.6)
					r:noCollide(
						r:boxAt(p * CFrame.Angles(0, 0, 0.3 + k * 0.2), 0.2, 0.02, 0.02, shade(hay, 0.9), "Fabric")
					)
				end
			end
			bale(-0.78, 0.4, 0, 0)
			bale(0.78, 0.4, 0.02, 0.05)
			bale(0, 1.2, -0.05, -0.08)
			-- pumpkins on the ground and on top, and a small gourd
			pumpkin(r, -0.8, 0, 0.75, 0.6, r.c2)
			pumpkin(r, 0.55, 1.6, 0.05, 0.55, shade(r.c2, 1.05))
			pumpkin(r, 1.25, 0, 0.75, 0.42, Color3.fromRGB(236, 214, 150))
			r:lump(
				CFrame.new(-0.4, 1.68, 0.1) * CFrame.Angles(0, 0, 0.3),
				0.2,
				0.32,
				0.2,
				Color3.fromRGB(150, 170, 90),
				"Fabric"
			)
		end,
	},
	{
		id = "decor_floor_vase",
		name = "Tall vase of branches",
		cat = "decor",
		style = "modern",
		price = 75,
		place = "floor",
		size = Vector3.new(1.6, 4.6, 1.6),
		c1 = "4E5A66",
		c2 = "E8D2C8",
		tags = { "plant" },
		build = function(r: R)
			-- a tall glazed vase, wide in the middle and narrow at the neck
			local body = r:ball(0, 0.95, 0, 0.9, r.c1, "CeramicTiles")
			body.size = Vector3.new(0.9, 1.8, 0.9)
			body.smooth = true
			K.disc(r, 0, 0.05, 0, 0.1, 0.5, shade(r.c1, 0.85), "CeramicTiles")
			r:cyl(0, 1.95, 0, 0.4, 0.34, "y", r.c1, "CeramicTiles").smooth = true
			K.disc(r, 0, 2.17, 0, 0.06, 0.44, shade(r.c1, 1.15), "CeramicTiles")
			-- bare branches fanning up, with blossom along them
			local tips =
				{ { -0.6, 4.3, 0.2 }, { 0.5, 4.5, -0.1 }, { 0.1, 4.1, 0.6 }, { -0.2, 3.8, -0.6 }, { 0.65, 3.7, 0.45 } }
			for i, t in tips do
				local mid = Vector3.new(t[1] * 0.4, 3.0, t[3] * 0.4)
				local tip = Vector3.new(t[1], t[2], t[3])
				K.rod(r, Vector3.new(0, 2.1, 0), mid, 0.06, C.Bark, "Wood")
				K.rod(r, mid, tip, 0.04, C.Bark, "Wood")
				local twig = mid:Lerp(tip, 0.5)
				K.rod(r, twig, twig + Vector3.new(t[3] * 0.3, 0.3, -t[1] * 0.3), 0.025, C.Bark, "Wood")
				for j = 1, 4 do
					local p = mid:Lerp(tip, j / 4)
					r:noCollide(
						r:lump(
							CFrame.new(p + Vector3.new(0.05, 0, 0.03)) * CFrame.Angles(0, i + j, 0.4),
							0.16,
							0.12,
							0.16,
							if j % 2 == 0 then r.c2 else C.White,
							"Fabric"
						)
					)
				end
			end
		end,
	},
	{
		id = "decor_stone_lantern",
		name = "Stone lantern",
		cat = "garden",
		style = "garden",
		price = 160,
		place = "ground",
		size = Vector3.new(1.8, 3.6, 1.8),
		c1 = "A8A49C",
		c2 = "6E9A62",
		tags = { "light" },
		build = function(r: R)
			local stone = r.c1
			-- a base stone, a round post, a flat table, the light box with its windows, a wide roof
			-- curling up at the corners and a knob on top; moss here and there
			r:lump(CFrame.new(0, 0.2, 0), 1.4, 0.4, 1.3, shade(stone, 0.92), "Rock")
			r:cyl(0, 1.0, 0, 1.2, 0.46, "y", stone, "Granite").smooth = true
			r:bevel(-0.6, 1.6, -0.6, 0.6, 1.78, 0.6, 0.063, stone, "Granite", { wear = 0.94 })
			r:block(-0.4, 1.78, -0.4, 0.4, 2.42, 0.4, stone, "Granite")
			for _, sz in { -1, 1 } do
				local win = r:block(
					-0.2,
					1.88,
					sz * 0.43 - 0.015,
					0.2,
					2.3,
					sz * 0.43 + 0.015,
					Color3.fromRGB(255, 220, 160),
					"Glass"
				)
				r:glow(win, if sz > 0 then 12 else 0, 0.9)
			end
			for _, sx in { -1, 1 } do
				r:block(sx * 0.43 - 0.015, 1.92, -0.12, sx * 0.43 + 0.015, 2.22, 0.12, INK, "Granite")
			end
			r:bevel(-0.85, 2.42, -0.85, 0.85, 2.56, 0.85, 0.049, stone, "Granite", { wear = 0.94 })
			r:ramp(-0.85, 2.56, -0.85, 0.85, 2.95, 0, true, shade(stone, 0.95), "Granite")
			r:ramp(-0.85, 2.56, 0, 0.85, 2.95, 0.85, false, shade(stone, 0.95), "Granite")
			for _, sx in { -1, 1 } do
				for _, sz in { -1, 1 } do
					r:lump(
						CFrame.new(sx * 0.82, 2.6, sz * 0.82) * CFrame.Angles(sz * 0.4, 0, -sx * 0.4),
						0.2,
						0.12,
						0.2,
						stone,
						"Granite"
					)
				end
			end
			r:cyl(0, 3.02, 0, 0.14, 0.4, "y", stone, "Granite")
			K.sphere(r, 0, 3.24, 0, 0.32, stone, "Granite")
			for i, p in { { 0.5, 0.42, 0.4 }, { -0.45, 1.84, 0.5 }, { 0.3, 2.9, -0.2 } } do
				r:noCollide(r:lump(CFrame.new(p[1], p[2], p[3]) * CFrame.Angles(0, i, 0), 0.4, 0.1, 0.3, r.c2, "Grass"))
			end
		end,
	},
}

return items
