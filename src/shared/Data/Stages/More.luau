--!nonstrict
-- The sets made for the newer cutscene events (Data/Events/Moments), each in its own space as
-- Data/Stages describes. The user: "Make more cutscene events, like: villager dreams of being in
-- a purple field with a tree of red leaves ... villagers racing with each other ... villager
-- dreaming of being stuck in a pizza place, with animatronics on the loose ... villagers petting
-- a cat ... villager(s) skywatching ... much more, reference tomodachi life for event ideas".
-- Only the ideas are taken: every set, prop and robot here is the town's own.

local Recipe = require(script.Parent.Parent.Parent.Build.Recipe)
local K = require(script.Parent.Kit)

type R = Recipe.Recipe

local rgb, yaw, v3, shade = K.rgb, K.yaw, K.v3, K.shade
local town, rand, item = K.town, K.rand, K.item

local list = {}

local function stage(def: any)
	table.insert(list, def)
end

local IRON = rgb(52, 52, 60)
local WARM = rgb(255, 214, 150)

-- A room's shell: a floor of boards, three walls (back at z = back, the sides at x = +-w/2) with a
-- skirting and a rail, and a ceiling, all from z = back to z = front. The front is left open for
-- the camera.
local function room(
	r: R,
	w: number,
	back: number,
	front: number,
	h: number,
	wall: Color3,
	floor: Color3,
	ceiling: Color3,
	noBack: boolean?
)
	local x1, x2 = -w / 2, w / 2
	K.boards(r, x1, back, x2, front, 0, floor)
	r:block(x1 - 0.6, -0.8, back - 0.6, x2 + 0.6, -0.06, front, shade(floor, 0.6), "Wood")
	if not noBack then
		r:block(x1 - 0.6, 0, back - 0.6, x2 + 0.6, h, back, wall, "WoodPlanks")
		r:block(x1, 0, back, x2, 0.5, back + 0.12, shade(wall, 0.72), "Wood")
		r:block(x1, 3.2, back, x2, 3.4, back + 0.1, shade(wall, 0.72), "Wood")
	end
	r:block(x1 - 0.6, 0, back, x1, h, front, wall, "WoodPlanks")
	r:block(x2, 0, back, x2 + 0.6, h, front, wall, "WoodPlanks")
	r:block(x1 - 0.6, h, back - 0.6, x2 + 0.6, h + 0.5, front, ceiling, "Wood")
	local trim = shade(wall, 0.72)
	r:block(x1, 0, back, x1 + 0.12, 0.5, front, trim, "Wood")
	r:block(x2 - 0.12, 0, back, x2, 0.5, front, trim, "Wood")
	r:block(x1, h - 0.3, back, x2, h, back + 0.2, trim, "Wood")
end

-- 1. A purple field in a dream ---------------------------------------------------------------------
-- A field of violet grass and flowers rolling off into a pink haze, one big tree in the middle
-- with leaves of deep red, a few of them fallen, far hills and trees in the same colours. Behind
-- the trunk, where only a look round shows him, a man stands still: a long grey coat, a flat
-- cap, his face in its shadow (a prop, brought in when the villager looks).
stage({
	id = "violetfield",
	name = "A purple field in a dream",
	marks = {
		{ at = v3(-1.2, 0, -1), yaw = 10 },
		{ at = v3(-3.1, 0, -13.2), yaw = 200 },
		{ at = v3(6.4, 0, -5), yaw = -40 },
	},
	shots = {
		wide = { eye = v3(1.5, 5.2, 16), look = v3(-0.5, 6.5, -12), fov = 48 },
		two = { eye = v3(1.2, 4.8, 6.4), look = v3(0, 4.4, -2), fov = 38 },
		side = { eye = v3(-12, 5.5, 4), look = v3(-1, 5.5, -10), fov = 44 },
		tree = { eye = v3(2.5, 2.2, 0), look = v3(0, 12, -15), fov = 50 },
		walk = { eye = v3(-7.5, 5, -2), look = v3(-2.5, 4.4, -13), fov = 40 },
		behind = { eye = v3(-9, 5.4, -25), look = v3(0.2, 4.4, -15.8), fov = 48 },
	},
	bounds = { lo = v3(-16, 1, -28), hi = v3(16, 16, 22) },
	light = {
		hour = 16.9,
		face = 24,
		air = { color = rgb(220, 176, 236), decay = rgb(176, 120, 214), density = 0.36, haze = 2.2 },
		grade = { tint = rgb(250, 234, 255), saturation = 0.16 },
	},
	props = {
		man = {
			spots = { behind = CFrame.new(1.8, 0, -18.6) * yaw(137) },
			build = function(r: R)
				local COAT = rgb(92, 94, 104)
				-- legs, a long coat to his knees, arms down in his pockets, a scarf, a flat cap
				for _, sx in { -0.42, 0.42 } do
					r:box(sx, 1.2, 0, 0.7, 2.4, 0.75, rgb(52, 52, 60), "Fabric")
					r:box(sx, 0.15, -0.15, 0.75, 0.3, 1.0, rgb(40, 36, 36), "Fabric")
				end
				r:block(-1.1, 1.6, -0.6, 1.1, 5.0, 0.6, COAT, "Fabric")
				r:block(-0.08, 1.6, -0.62, 0.08, 4.6, -0.6, shade(COAT, 0.7), "Fabric")
				for _, sx in { -1.3, 1.3 } do
					r:box(sx, 3.8, 0, 0.55, 2.3, 0.7, shade(COAT, 0.92), "Fabric")
				end
				r:box(0, 5.1, 0, 1.2, 0.35, 0.9, rgb(130, 60, 60), "Fabric")
				r:ball(0, 5.95, 0, 1.25, rgb(214, 186, 168), "SmoothPlastic")
				r:cyl(0, 6.6, -0.05, 0.3, 1.35, "y", rgb(70, 66, 70), "Fabric")
				r:box(0, 6.5, -0.65, 1.1, 0.12, 0.5, rgb(70, 66, 70), "Fabric")
			end,
		},
	},
	build = function(r: R)
		local GRASS = rgb(150, 112, 196)
		local DEEP = rgb(120, 86, 170)
		r:block(-260, -1, -300, 260, 0, 140, GRASS, "Grass")
		-- soft rises in the field, and far hills in the haze
		local next = rand(41)
		for i = 1, 10 do
			local x, z = (next() - 0.5) * 120, -60 - next() * 50
			r:lump(
				CFrame.new(x, -1, z),
				30 + next() * 20,
				4 + next() * 3,
				18 + next() * 10,
				if i % 2 == 0 then GRASS else DEEP,
				"Grass"
			)
		end
		for i = 1, 6 do
			local x = -150 + i * 50 + next() * 20
			r:lump(CFrame.new(x, -6, -170 - next() * 40), 90, 26 + next() * 20, 50, rgb(170, 130, 200), "Grass")
		end
		-- the tree: a thick trunk that forks, roots spreading, and a crown of red
		local BARK = rgb(96, 70, 70)
		local base = v3(0, 0, -16)
		local function limb(a: Vector3, b: Vector3, w: number)
			r:beam(a, b, w, w, BARK, "Wood")
			r:ball(b.X, b.Y, b.Z, w * 1.02, BARK, "Wood")
		end
		limb(base, base + v3(0.4, 5, 0), 2.4)
		limb(base + v3(0.4, 5, 0), base + v3(-0.3, 8.5, 0.3), 2.0)
		limb(base + v3(-0.3, 8.5, 0.3), base + v3(-3.6, 12, 0.8), 1.3)
		limb(base + v3(-0.3, 8.5, 0.3), base + v3(3.4, 12.6, -0.6), 1.3)
		limb(base + v3(-0.3, 8.5, 0.3), base + v3(0.4, 13.5, -2.6), 1.1)
		for k = 0, 5 do
			local a = k * math.pi / 3 + 0.3
			r:beam(base + v3(0, 0.6, 0), base + v3(math.cos(a) * 2.6, 0.05, math.sin(a) * 2.6), 0.8, 0.5, BARK, "Wood")
		end
		local REDS = { rgb(196, 46, 56), rgb(168, 34, 52), rgb(214, 70, 64) }
		local crown = base + v3(0, 13, -0.5)
		for k = 1, 16 do
			local a = next() * math.pi * 2
			local d = next() * 6
			local c = crown + v3(math.cos(a) * d, (next() - 0.4) * 4, math.sin(a) * d * 0.8)
			local leaf = r:ball(c.X, c.Y, c.Z, 4 + next() * 3, REDS[k % 3 + 1], "Grass")
			leaf.name = "Leaf"
		end
		-- leaves fallen round it
		for i = 1, 40 do
			local a = next() * math.pi * 2
			local d = 3 + next() * 9
			r:boxAt(
				CFrame.new(base.X + math.cos(a) * d, 0.03 + (i % 6) * 0.03, base.Z + math.sin(a) * d)
					* yaw(next() * 180),
				0.5,
				0.05,
				0.32,
				REDS[i % 3 + 1],
				"Grass"
			)
		end
		-- the grass and its flowers, thick near and thinner further off
		K.tufts(r, -14, -12, 14, 14, 0, 90, 7, rgb(170, 120, 214))
		K.tufts(r, -18, -26, 18, -12, 0, 50, 8, rgb(150, 104, 200))
		local FLOWERS = { rgb(196, 150, 236), rgb(236, 196, 250), rgb(150, 110, 220), rgb(250, 220, 240) }
		K.flowers(r, -13, -8, 13, 12, 0, 46, 11, FLOWERS)
		K.flowers(r, -16, -26, 16, -10, 0, 30, 12, FLOWERS)
		-- far trees in the haze, red crowns on dark trunks
		for i = 1, 7 do
			local x = -90 + i * 25 + next() * 8
			local z = -60 - next() * 40
			r:cyl(x, 4, z, 8, 1.2, "y", BARK, "Wood")
			r:ball(x, 10, z, 9 + next() * 3, REDS[i % 3 + 1], "Grass")
		end
		-- petals hanging still in the air, as dreams have them
		for i = 1, 18 do
			r:boxAt(
				CFrame.new((next() - 0.5) * 24, 2 + next() * 10, -20 + next() * 26)
					* CFrame.Angles(next() * 3, next() * 3, next() * 3),
				0.34,
				0.04,
				0.24,
				REDS[i % 3 + 1],
				"SmoothPlastic"
			)
		end
	end,
})

-- 2. A bedroom at night ------------------------------------------------------------------------------
-- Where the dreams end: a bed against the back wall under a window full of night, a nightstand
-- with its lamp on, an alarm clock and a glass of water, a rug, a wardrobe, a bookcase, a chair
-- with clothes over it, pictures on the walls and slippers by the bed.
local BED = K.spotOf("bed_single", "bed")
stage({
	id = "bedroom",
	name = "A bedroom at night",
	marks = {
		{
			at = BED + v3(0, 0, -4.6),
			yaw = 0,
			pose = "lie",
			head = v3(0, 0.8, -1.6),
			close = { eye = BED + v3(1.6, 4.6, -3.0), look = BED + v3(0, 0.7, -6.2), fov = 34 },
		},
		{ at = v3(3.0, 0, 1.4), yaw = -50 },
		{ at = v3(-4.6, 0, -0.6), yaw = 60 },
	},
	shots = {
		wide = { eye = v3(0.5, 6.2, 9.5), look = v3(0, 2.6, -4.5), fov = 50 },
		two = { eye = v3(2, 5, 5), look = v3(1.6, 4, -1), fov = 40 },
		side = { eye = v3(-7.2, 5.4, 4.6), look = v3(0, 2.4, -5), fov = 44 },
		bed = { eye = v3(5.6, 7.4, 2.6), look = v3(0, 2.4, -6), fov = 44 },
		pillow = { eye = v3(2.6, 5.2, -4.6), look = v3(0, 2.4, -7.4), fov = 34 },
	},
	bounds = { lo = v3(-7.5, 1, -8.5), hi = v3(7.5, 9.4, 12) },
	light = { hour = 2, face = 0, indoor = true },
	build = function(r: R)
		local WALL = rgb(176, 168, 196)
		room(r, 16, -9, 6, 10, WALL, rgb(150, 112, 84), rgb(210, 204, 214))
		-- the bed against the back wall, its quilt in a soft blue
		item(r, "bed_single", CFrame.new(0, 0, -4.6), "8EA9C8", "EDE7DA")
		-- the window over it, the night outside, curtains drawn back
		K.window(r, 0, 4.4, -8.85, 4.6, 3.6, rgb(236, 230, 220), rgb(30, 40, 84))
		for _, sx in { -1, 1 } do
			r:block(sx * 2.4 - 0.7, 3.8, -8.8, sx * 2.4 + 0.7, 8.6, -8.5, rgb(150, 120, 170), "Fabric")
		end
		r:cyl(0, 8.75, -8.7, 6.4, 0.14, "x", IRON, "Metal")
		-- a moon and stars on the night behind the glass
		r:cyl(1.2, 7.1, -8.85, 0.05, 0.8, "z", rgb(240, 236, 200), "Neon")
		for _, s in { { -1.6, 7.4 }, { -0.6, 6.6 }, { 1.8, 5.4 }, { -1.9, 5.2 } } do
			r:box(s[1], s[2], -8.86, 0.1, 0.1, 0.04, rgb(250, 250, 236), "Neon")
		end
		-- the nightstand with its lamp, a clock and a glass
		item(r, "nightstand", CFrame.new(-3.4, 0, -7.6))
		item(r, "lamp_table", CFrame.new(-3.4, 2, -7.7))
		r:box(-2.9, 2.35, -7.2, 0.7, 0.6, 0.35, rgb(214, 90, 80), "SmoothPlastic")
		r:box(-2.9, 2.35, -7.02, 0.5, 0.4, 0.04, rgb(250, 248, 236), "SmoothPlastic")
		r:cyl(-3.9, 2.3, -7.1, 0.5, 0.3, "y", rgb(200, 220, 236), "Glass")
		-- the wardrobe, a bookcase and a chair with clothes on it
		item(r, "wardrobe", CFrame.new(6.2, 0, -5.2) * yaw(-90))
		item(r, "cozy_bookcase", CFrame.new(-7, 0, -3.4) * yaw(90))
		item(r, "chair_wood", CFrame.new(4.6, 0, -1.6) * yaw(-110))
		r:block(4.1, 2.35, -2.3, 5.0, 2.5, -0.9, rgb(220, 120, 110), "Fabric")
		item(r, "rug_round", CFrame.new(0, 0, 0.6), "C9A27E", "8E6E9E")
		-- slippers by the bed, pictures, a pinboard
		for _, sx in { 2.5, 3.1 } do
			r:block(sx - 0.25, 0.03, -2.4, sx + 0.25, 0.25, -1.4, rgb(240, 200, 210), "Fabric")
		end
		K.picture(r, -4.4, 6.4, -8.86, 2, 1.6, rgb(150, 112, 84), { rgb(120, 170, 210), rgb(110, 160, 100) })
		K.picture(
			r,
			4.4,
			6.0,
			-8.86,
			1.6,
			2.2,
			rgb(236, 230, 220),
			{ rgb(240, 200, 120), rgb(220, 130, 120), rgb(150, 130, 200) }
		)
		r:block(-7.86, 4.6, 1, -7.74, 6.6, 4, rgb(190, 160, 120), "Wood")
		for i, c in { rgb(250, 240, 200), rgb(200, 230, 250), rgb(250, 210, 220) } do
			r:block(-7.74, 4.8 + i * 0.5, 1.4 + i * 0.6, -7.7, 5.2 + i * 0.5, 2 + i * 0.6, c, "SmoothPlastic")
		end
		-- the ceiling light, off, and the door's frame at the side
		item(r, "light_ceiling", CFrame.new(0, 10, -1))
		r:block(7.4, 0, 2, 7.94, 8, 5, rgb(236, 230, 220), "Wood")
	end,
})

-- 3. The race track --------------------------------------------------------------------------------
-- A track of packed earth across the meadow with three lanes marked in white, the start line and
-- a finish line under a banner on two posts, little flags along a rope, hay bales at the bends,
-- a scoreboard on legs, a bench for whoever came to watch, cones, and trees round the meadow.
stage({
	id = "racetrack",
	name = "The race track",
	marks = {
		{ at = v3(-18, 0.1, -2.6), yaw = 90 },
		{ at = v3(-18, 0.1, 0), yaw = 90 },
		{ at = v3(-18, 0.1, 2.6), yaw = 90 },
		{ at = v3(16, 0.1, -2.6), yaw = 70 },
		{ at = v3(16, 0.1, 0), yaw = 100 },
		{ at = v3(16, 0.1, 2.6), yaw = 120 },
		{ at = v3(-6, 0, 8.6), yaw = 170 },
		{ at = v3(-2.4, 0, 8.8), yaw = 186 },
	},
	shots = {
		wide = { eye = v3(-2, 9, 30), look = v3(-1, 2, -1), fov = 50 },
		two = { eye = v3(-11, 4.6, -2), look = v3(-18, 4.2, -1.3), fov = 40 },
		side = { eye = v3(-24, 3.6, 12), look = v3(-18, 4, 0), fov = 44 },
		start = { eye = v3(-9.5, 2.4, 5), look = v3(-18, 4.2, 0), fov = 46 },
		finish = { eye = v3(24, 4.4, 6), look = v3(14, 4, 0), fov = 46 },
		track = { eye = v3(4, 3.2, 8), look = v3(-6, 3.5, 0), fov = 52 },
		crowd = { eye = v3(-4, 4.6, 2.5), look = v3(-4.2, 4.2, 8.8), fov = 38 },
	},
	bounds = { lo = v3(-30, 1, -14), hi = v3(30, 16, 34) },
	light = { hour = 10.5, face = 145 },
	build = function(r: R)
		local GRASS = rgb(126, 170, 92)
		local EARTH = rgb(196, 160, 118)
		local WHITE = rgb(246, 244, 236)
		r:block(-200, -1, -160, 200, 0, 120, GRASS, "Grass")
		r:block(-40, 0, -4.2, 40, 0.1, 4.2, EARTH, "Ground")
		-- lane lines, the start and the finish (a black and white check)
		for _, z in { -4.0, -1.3, 1.3, 4.0 } do
			r:block(-40, 0.1, z - 0.07, 40, 0.14, z + 0.07, WHITE, "SmoothPlastic")
		end
		r:block(-17.0, 0.1, -4, -16.6, 0.14, 4, WHITE, "SmoothPlastic")
		for i = 0, 15 do
			for j = 0, 1 do
				r:block(
					17 + j * 0.5,
					0.14,
					-4 + i * 0.5,
					17.5 + j * 0.5,
					0.18,
					-3.5 + i * 0.5,
					if (i + j) % 2 == 0 then rgb(40, 40, 44) else WHITE,
					"SmoothPlastic"
				)
			end
		end
		-- the finish banner on two posts
		for _, z in { -5.2, 5.2 } do
			r:cyl(17.5, 3.6, z, 7.2, 0.4, "y", rgb(220, 220, 226), "Metal")
			r:cyl(17.5, 7.3, z, 0.3, 0.6, "y", rgb(220, 90, 80), "Metal")
		end
		r:block(17.4, 5.6, -5, 17.6, 7, 5, rgb(236, 92, 84), "Fabric")
		for i = 0, 9 do
			r:block(17.62, 6.0, -4.4 + i * 0.9, 17.66, 6.6, -4.0 + i * 0.9, WHITE, "SmoothPlastic")
		end
		-- the rope of little flags along the far side, on posts
		local FLAGS = { rgb(236, 110, 100), rgb(250, 200, 90), rgb(110, 170, 230), rgb(140, 200, 120) }
		for x = -28, 28, 8 do
			r:cyl(x, 1.8, -6, 3.6, 0.22, "y", rgb(150, 112, 84), "Wood")
		end
		for x = -28, 20, 8 do
			K.bunting(r, v3(x, 3.5, -6), v3(x + 8, 3.5, -6), 0.5, 6, FLAGS)
		end
		-- hay bales, cones and the scoreboard
		for _, at in { { -26, -6.5 }, { 26, -6.6 }, { -26, 6.6 }, { 24, 7 } } do
			town(r, "hayBale", CFrame.new(at[1], 0, at[2]) * yaw(at[1]))
		end
		for x = -12, 12, 6 do
			r:cone(x, 0.6, 4.8, 1.2, 0.8, rgb(250, 140, 60), "SmoothPlastic")
			r:box(x, 0.06, 4.8, 1.0, 0.12, 1.0, rgb(250, 140, 60), "SmoothPlastic")
		end
		for _, x in { 8.6, 12.4 } do
			r:cyl(x, 2.4, -10, 4.8, 0.3, "y", rgb(150, 112, 84), "Wood")
		end
		r:block(8, 4.4, -10.2, 13, 7.4, -9.8, rgb(60, 84, 70), "Wood")
		r:block(8.3, 4.7, -9.8, 12.7, 7.1, -9.76, rgb(40, 60, 50), "SmoothPlastic")
		for i, w in { 1.6, 1.2, 1.8 } do
			r:block(8.7, 6.8 - i * 0.6, -9.76, 8.7 + w, 6.9 - i * 0.6, -9.72, WHITE, "SmoothPlastic")
		end
		-- a bench for whoever watches, and a cool box
		item(r, "bench_wood", CFrame.new(-4.2, 0, 10.6) * yaw(180))
		item(r, "sea_cool_box", CFrame.new(-0.4, 0, 10.6))
		-- the meadow round it
		K.tufts(r, -30, -14, 30, -4.6, 0, 70, 3)
		K.tufts(r, -30, 4.6, 30, 16, 0, 70, 4)
		K.flowers(r, -30, 5, 30, 16, 0, 30, 5, { rgb(250, 240, 180), rgb(240, 160, 180), rgb(200, 180, 250) })
		for i, at in { { -30, -22 }, { -12, -26 }, { 10, -24 }, { 30, -20 }, { 38, 14 }, { -38, 12 } } do
			K.roundTree(r, at[1], 0, at[2], 12 + (i % 3) * 2, i * 7)
		end
		town(r, "windmill", CFrame.new(60, 0, -80) * yaw(30))
	end,
})

-- 4. A pizza parlour at night, in a dream ------------------------------------------------------------
-- The night watch's little office at the front: a desk with four screens showing the rooms, a
-- lamp, a fan, a mug and the rota, a door at the side, posters and a clock on the walls, and a
-- big window into the dining room. In there, under the few lights left on: tables in checked
-- cloths, chairs, party hats, an arcade cabinet, the oven's glow, and a little stage at the back
-- where three clunky robot mascots stand. They don't always stay there.
local function robot(r: R, body: Color3, trim: Color3, kind: number)
	-- feet on wheels, a barrel of a body with an apron, arms holding something out
	for _, sx in { -0.7, 0.7 } do
		r:box(sx, 0.45, 0, 0.8, 0.9, 1.2, IRON, "Metal")
		r:cyl(sx, 0.35, 0.55, 0.3, 0.6, "x", rgb(40, 40, 44), "Rubber")
		r:cyl(sx, 1.6, 0, 1.8, 0.45, "y", rgb(150, 150, 160), "Metal")
	end
	r:cyl(0, 3.6, 0, 2.6, 2.5, "y", body, "Metal")
	r:cyl(0, 4.95, 0, 0.2, 2.6, "y", trim, "Metal")
	r:cyl(0, 2.3, 0, 0.2, 2.6, "y", trim, "Metal")
	r:block(-0.9, 2.5, -1.3, 0.9, 4.6, -1.15, rgb(244, 242, 236), "Fabric")
	for k = 0, 2 do
		r:cyl(0, 3.2 + k * 0.5, -1.28, 0.08, 0.26, "z", trim, "Metal")
	end
	for _, sx in { -1.45, 1.45 } do
		r:ball(sx, 4.6, 0, 0.7, trim, "Metal")
		r:beam(v3(sx, 4.6, 0), v3(sx * 0.95, 3.6, -1.2), 0.45, 0.45, rgb(150, 150, 160), "Metal")
		r:ball(sx * 0.95, 3.6, -1.3, 0.55, rgb(150, 150, 160), "Metal")
	end
	if kind == 1 then
		-- a tray with a pizza on it
		r:cyl(0, 3.75, -1.6, 0.1, 2.4, "y", rgb(180, 180, 190), "Metal")
		r:cyl(0, 3.86, -1.6, 0.12, 2.1, "y", rgb(240, 196, 110), "SmoothPlastic")
		r:cyl(0, 3.93, -1.6, 0.04, 1.8, "y", rgb(214, 80, 60), "SmoothPlastic")
	elseif kind == 2 then
		-- a microphone
		r:cyl(0.9, 4.2, -1.5, 0.7, 0.16, "y", IRON, "Metal")
		r:ball(0.9, 4.6, -1.5, 0.34, rgb(70, 70, 76), "Metal")
	else
		-- a bell
		r:cone(-0.9, 3.9, -1.5, 0.5, 0.6, rgb(230, 190, 90), "Metal")
	end
end

local function robotHead(r: R, body: Color3, trim: Color3, kind: number)
	r:cyl(0, 5.3, 0, 0.6, 0.7, "y", rgb(150, 150, 160), "Metal")
	if kind == 2 then
		-- a round head like a pizza, pepperoni and all
		r:cyl(0, 6.6, 0, 0.6, 2.6, "z", rgb(240, 196, 110), "SmoothPlastic")
		for _, at in { { -0.6, 7.2 }, { 0.7, 6.0 }, { -0.3, 5.9 } } do
			r:cyl(at[1], at[2], -0.32, 0.06, 0.4, "z", rgb(200, 70, 60), "SmoothPlastic")
		end
	else
		r:block(-1.1, 5.6, -0.95, 1.1, 7.4, 0.95, body, "Metal")
		r:block(-0.7, 5.8, -0.98, 0.7, 6.0, -0.94, IRON, "Metal")
		for k = 0, 3 do
			r:block(-0.6 + k * 0.4, 5.75, -1.0, -0.42 + k * 0.4, 6.0, -0.96, rgb(240, 240, 236), "SmoothPlastic")
		end
	end
	-- round eyes that glow, and on top a chef's hat, a bow or an antenna
	for _, sx in { -0.48, 0.48 } do
		r:cyl(sx, 6.85, -1.0, 0.12, 0.7, "z", rgb(240, 240, 236), "SmoothPlastic")
		r:glow(
			r:cyl(sx, 6.85, -1.08, 0.06, 0.34, "z", rgb(255, 214, 90), "Neon"),
			if sx > 0 then 7 else 0,
			1.2,
			rgb(255, 214, 90)
		)
	end
	if kind == 1 then
		r:cyl(0, 7.9, 0, 1.0, 1.5, "y", rgb(246, 246, 246), "Fabric")
		for k = 0, 4 do
			local a = k * math.pi * 2 / 5
			r:ball(math.cos(a) * 0.6, 8.6, math.sin(a) * 0.6, 0.9, rgb(250, 250, 250), "Fabric")
		end
	elseif kind == 3 then
		r:cyl(0, 8.0, 0, 1.2, 0.12, "y", IRON, "Metal")
		r:ball(0, 8.7, 0, 0.36, rgb(240, 90, 80), "Neon")
	end
	r:block(-0.5, 5.35, -1.12, 0.5, 5.65, -0.95, trim, "Fabric")
end

local function robotProp(body: Color3, trim: Color3, kind: number, spots: { [string]: CFrame }, start: string): any
	local moves = {
		hall = { swing = { axis = "y", amp = 40, rate = 0.3, phase = kind * 0.2 } },
		window = { tilt = { axis = "z", deg = 18 } },
		door = { swing = { axis = "z", amp = 8, rate = 0.8 } },
	}
	local by = {}
	for spot, m in moves do
		if spots[spot] then
			by[spot] = m
		end
	end
	return {
		spots = spots,
		start = start,
		build = function(r: R)
			robot(r, body, trim, kind)
		end,
		parts = {
			head = {
				pivot = CFrame.new(0, 5.4, 0),
				build = function(r: R)
					robotHead(r, body, trim, kind)
				end,
				motion = { swing = { axis = "y", amp = 6, rate = 0.12, phase = kind * 0.3 } },
				by = by,
			},
		},
	}
end

local CHAIR = (CFrame.new(0, 0, 0.4) * yaw(180)) * K.spotOf("chair_wood", "seat")
stage({
	id = "parlour",
	name = "A pizza parlour at night",
	marks = {
		{
			at = CHAIR,
			yaw = 180,
			sit = true,
			close = { eye = v3(-2.4, 5.7, -1.6), look = v3(0, 4.25, 0.4), fov = 38 },
		},
		{ at = v3(4.8, 0, 1.2), yaw = -100 },
		{ at = v3(-4.4, 0, 2.6), yaw = 150 },
	},
	shots = {
		wide = { eye = v3(2.4, 7, 8.4), look = v3(-0.5, 4, -6), fov = 52 },
		two = { eye = v3(2.6, 5.4, 4.6), look = v3(0.8, 4.2, -0.5), fov = 40 },
		side = { eye = v3(-5.6, 6, 6.4), look = v3(0, 4, -3), fov = 48 },
		desk = { eye = v3(0.8, 5.6, 3.6), look = v3(-0.2, 4.3, -2.6), fov = 40 },
		screens = { eye = v3(-0.2, 4.9, -0.6), look = v3(-0.4, 3.8, -2.8), fov = 36 },
		hall = { eye = v3(-1.2, 6.2, -3.6), look = v3(1, 4.4, -20), fov = 48 },
		window = { eye = v3(1.6, 6.6, 1.8), look = v3(-1, 5.0, -7), fov = 44 },
		door = { eye = v3(-1.8, 5, 2.6), look = v3(6.6, 5.2, -0.6), fov = 44 },
	},
	bounds = { lo = v3(-6.4, 1, -4.4), hi = v3(6.4, 9.4, 12) },
	light = { hour = 23.5, face = 0, indoor = true, grade = { tint = rgb(226, 236, 255), saturation = 0.02 } },
	props = {
		chef = robotProp(rgb(196, 70, 60), rgb(240, 200, 90), 1, {
			stage = CFrame.new(-5, 2.2, -26),
			hall = CFrame.new(-3, 0, -15) * yaw(-20),
			window = CFrame.new(-1.4, 0, -7.6),
		}, "stage"),
		pepper = robotProp(rgb(110, 150, 200), rgb(240, 240, 236), 2, {
			stage = CFrame.new(0, 2.2, -26.5),
			hall = CFrame.new(4, 0, -18) * yaw(30),
			door = CFrame.new(7.8, 0, -0.6) * yaw(-90),
		}, "stage"),
		waiter = robotProp(rgb(120, 180, 120), rgb(70, 60, 80), 3, {
			stage = CFrame.new(5, 2.2, -26),
			hall = CFrame.new(1, 0, -12) * yaw(-10),
		}, "stage"),
		door = {
			spots = { open = CFrame.new(7.3, 0, 1.6) * yaw(-80), shut = CFrame.new(7.3, 0, 1.6) },
			start = "open",
			build = function(r: R)
				r:block(-0.1, 0.02, -3.2, 0.1, 7.8, 0, rgb(120, 130, 140), "Metal")
				r:block(-0.16, 5.4, -2.6, 0.16, 6.6, -0.6, rgb(60, 70, 90), "Glass")
				r:cyl(-0.2, 3.6, -2.8, 0.1, 0.3, "x", IRON, "Metal")
			end,
		},
	},
	build = function(r: R)
		local WALL = rgb(120, 116, 104)
		-- the office: floor tiles, walls, a ceiling with a tube light
		r:block(-7, -0.8, -6.2, 7, 0, 12, rgb(70, 70, 76), "Concrete")
		for i = 0, 6 do
			for j = 0, 8 do
				if (i + j) % 2 == 0 then
					r:block(
						-7 + i * 2,
						0,
						-5.9 + j * 2,
						-5 + i * 2,
						0.04,
						-3.9 + j * 2,
						rgb(96, 96, 104),
						"SmoothPlastic"
					)
				end
			end
		end
		r:block(-7.6, 0, -6.2, -7, 10, 12, WALL, "Concrete")
		r:block(7, 7.8, -6.2, 7.6, 10, 12, WALL, "Concrete")
		r:block(7, 0, -6.2, 7.6, 7.8, -1.6, WALL, "Concrete")
		r:block(7, 0, 1.6, 7.6, 7.8, 12, WALL, "Concrete")
		r:block(-7.6, 10, -6.4, 7.6, 10.6, 12, rgb(90, 90, 96), "Concrete")
		-- the back wall with its big window into the dining room
		r:block(-7.6, 0, -6.6, 7.6, 2.8, -6.0, WALL, "Concrete")
		r:block(-7.6, 7.4, -6.6, 7.6, 10, -6.0, WALL, "Concrete")
		r:block(-7.6, 2.8, -6.6, -5, 7.4, -6.0, WALL, "Concrete")
		r:block(5, 2.8, -6.6, 7.6, 7.4, -6.0, WALL, "Concrete")
		r:glass(-5, 2.8, -6.36, 5, 7.4, -6.24)
		r:block(-5.2, 2.6, -6.7, 5.2, 2.84, -5.7, rgb(150, 150, 156), "Metal")
		-- the dark passage past the side door
		r:block(7.6, -0.8, -2.2, 16, 0, 2.2, rgb(60, 60, 66), "Concrete")
		r:block(7.6, 0, -2.8, 16, 9, -2.2, rgb(90, 86, 80), "Concrete")
		r:block(7.6, 0, 2.2, 16, 9, 2.8, rgb(90, 86, 80), "Concrete")
		r:block(16, 0, -2.8, 16.6, 9, 2.8, rgb(90, 86, 80), "Concrete")
		r:block(7.6, 9, -2.8, 16.6, 9.6, 2.8, rgb(70, 70, 76), "Concrete")
		r:glow(r:box(15.9, 7.6, 0, 0.1, 0.6, 1.6, rgb(120, 230, 140), "Neon"), 8, 0.6, rgb(120, 230, 140))
		-- the tube light, buzzing
		r:block(-2.4, 9.6, 1.2, 2.4, 10, 1.8, rgb(200, 200, 206), "Metal")
		r:glow(r:block(-2.2, 9.45, 1.3, 2.2, 9.6, 1.7, rgb(220, 236, 255), "Neon"), 22, 1.2, rgb(220, 236, 255))
		-- the desk, its chair and the four screens
		r:block(-4.2, 2.9, -3.4, 4.2, 3.2, -1.2, rgb(110, 90, 70), "Wood")
		for _, x in { -3.9, 3.9 } do
			r:block(x - 0.2, 0, -3.3, x + 0.2, 2.9, -1.3, rgb(90, 74, 58), "Wood")
		end
		r:block(-3.7, 0.4, -3.3, 3.7, 2.9, -3.1, rgb(96, 80, 62), "Wood")
		item(r, "chair_wood", CFrame.new(0, 0, 0.4) * yaw(180), "4B4E57", "4B4E57")
		local SCREEN = rgb(60, 90, 80)
		for i, x in { -2.7, -0.9, 0.9, 2.7 } do
			local y = if i % 2 == 0 then 4.4 else 4.2
			r:block(x - 0.85, y - 0.75, -3.1, x + 0.85, y + 0.75, -2.4, rgb(44, 44, 48), "Plastic")
			r:block(x - 0.7, y - 0.6, -2.42, x + 0.7, y + 0.6, -2.36, SCREEN, "Neon")
			-- what each camera sees: a table, the stage, a door
			r:block(x - 0.5, y - 0.4, -2.36, x + 0.5, y - 0.3, -2.32, rgb(90, 130, 110), "Neon")
			r:block(
				x - 0.15 + (i - 2.5) * 0.1,
				y - 0.3,
				-2.36,
				x + 0.15 + (i - 2.5) * 0.1,
				y + 0.2,
				-2.32,
				rgb(120, 170, 140),
				"Neon"
			)
			r:block(x + 0.45, y + 0.38, -2.36, x + 0.6, y + 0.5, -2.32, rgb(230, 90, 80), "Neon")
			r:block(x - 0.15, 3.2, -2.9, x + 0.15, y - 0.75, -2.7, rgb(44, 44, 48), "Plastic")
		end
		-- a keyboard, a mug, the rota, a desk fan and a lamp
		r:block(-1, 3.2, -2.2, 1, 3.32, -1.6, rgb(50, 50, 56), "Plastic")
		for k = 0, 7 do
			r:block(-0.9 + k * 0.24, 3.32, -2.1, -0.74 + k * 0.24, 3.38, -1.7, rgb(80, 80, 88), "Plastic")
		end
		r:cyl(2.2, 3.55, -1.8, 0.7, 0.5, "y", rgb(240, 236, 226), "SmoothPlastic")
		r:block(-2.6, 3.2, -2.1, -1.6, 3.24, -1.4, rgb(250, 248, 240), "SmoothPlastic")
		item(r, "lamp_desk", CFrame.new(-3.4, 3.2, -2.2) * yaw(30))
		item(r, "plant_small", CFrame.new(3.7, 3.2, -1.7))
		-- posters, a clock, a fuse box, a bin
		K.picture(
			r,
			-5.2,
			6,
			-6.0,
			2.6,
			2.2,
			rgb(220, 70, 60),
			{ rgb(250, 210, 120), rgb(240, 160, 90), rgb(220, 70, 60) }
		)
		r:cyl(-7, 8, 2.6, 0.12, 1.6, "x", rgb(240, 240, 236), "SmoothPlastic")
		r:box(-6.92, 8.1, 2.6, 0.04, 0.6, 0.08, rgb(40, 40, 44), "SmoothPlastic")
		r:box(-6.92, 8, 2.85, 0.04, 0.08, 0.5, rgb(40, 40, 44), "SmoothPlastic")
		r:block(-7, 4, 6, -6.6, 6.4, 8, rgb(150, 150, 156), "Metal")
		item(r, "laundry_basket", CFrame.new(-5.6, 0, 5) * yaw(90))
		-- the dining room through the window: a checked floor, tables, chairs, the stage
		r:block(-14, -0.8, -32, 14, 0, -6.6, rgb(60, 60, 66), "Concrete")
		for i = 0, 13 do
			for j = 0, 11 do
				if (i + j) % 2 == 0 then
					r:block(
						-14 + i * 2,
						0,
						-32 + j * 2,
						-12 + i * 2,
						0.04,
						-30 + j * 2,
						rgb(200, 200, 204),
						"SmoothPlastic"
					)
				end
			end
		end
		r:block(-14.6, 0, -32, -14, 12, -6.6, rgb(170, 70, 60), "Concrete")
		r:block(14, 0, -32, 14.6, 12, -6.6, rgb(170, 70, 60), "Concrete")
		r:block(-14.6, 0, -32.6, 14.6, 12, -32, rgb(150, 60, 56), "Concrete")
		r:block(-14.6, 12, -32.6, 14.6, 12.6, -6.6, rgb(60, 56, 60), "Concrete")
		for _, at in { { -8, -12 }, { 8, -12 }, { -7, -20 }, { 7, -21 } } do
			r:cyl(at[1], 2.6, at[2], 0.2, 4.4, "y", rgb(240, 240, 236), "Fabric")
			for k = 0, 3 do
				r:block(
					at[1] - 2.2 + k * 1.1,
					2.72,
					at[2] - 2.2,
					at[1] - 1.65 + k * 1.1,
					2.74,
					at[2] + 2.2,
					rgb(214, 70, 64),
					"Fabric"
				)
			end
			r:cyl(at[1], 1.3, at[2], 2.5, 0.4, "y", IRON, "Metal")
			for _, s in { -1, 1 } do
				item(r, "chair_dining", CFrame.new(at[1] + s * 3, 0, at[2]) * yaw(-s * 90), "C0453C", "C0453C")
			end
			r:cone(at[1] + 0.6, 3.2, at[2] - 0.4, 0.9, 0.6, rgb(120, 200, 230), "SmoothPlastic")
		end
		-- a gumball machine and a stack of high chairs by the wall
		r:cyl(-12.4, 1.4, -17, 2.8, 0.8, "y", rgb(200, 60, 60), "Metal")
		r:ball(-12.4, 3.6, -17, 1.8, rgb(200, 220, 236), "Glass")
		for k = 0, 9 do
			r:ball(
				-12.4 + math.cos(k) * 0.5,
				3.2 + (k % 3) * 0.3,
				-17 + math.sin(k) * 0.5,
				0.3,
				({ rgb(240, 90, 90), rgb(250, 210, 90), rgb(110, 170, 240) })[k % 3 + 1],
				"SmoothPlastic"
			)
		end
		r:cyl(-12.4, 4.6, -17, 0.3, 0.6, "y", rgb(200, 60, 60), "Metal")
		-- the oven in the corner, its door glowing
		r:block(9, 0, -31, 13.6, 6.4, -27, rgb(150, 100, 80), "Brick")
		r:cyl(11.3, 6.4, -29, 1.2, 4.6, "y", rgb(150, 100, 80), "Brick")
		local oven =
			r:glow(r:block(10.2, 1.6, -27.0, 12.4, 3.4, -26.9, rgb(255, 140, 60), "Neon"), 14, 1.2, rgb(255, 150, 80))
		oven.attrs = { Stays = true }
		-- the stage: a step up, curtains, a starry back, two spotlights on it
		r:block(-9, 0, -31, 9, 2.2, -23, rgb(110, 60, 70), "Wood")
		r:block(-9, 2.2, -31.9, 9, 11.4, -31.5, rgb(60, 40, 90), "Fabric")
		for _, sx in { -1, 1 } do
			r:block(sx * 9 - 2, 2.2, -31.4, sx * 9 + 1, 11.4, -30.8, rgb(170, 40, 56), "Fabric")
		end
		for k = 1, 12 do
			r:box(-7 + k * 1.15, 4 + (k * 37 % 7), -31.45, 0.2, 0.2, 0.04, rgb(255, 230, 140), "Neon")
		end
		for _, x in { -5, 5 } do
			local spot =
				r:glow(r:cyl(x, 11.2, -22, 0.8, 0.8, "y", rgb(255, 236, 200), "Neon"), 24, 1.4, rgb(255, 230, 190))
			-- (the stage lights stay on when the office goes dark)
			spot.attrs = { Stays = true }
		end
		-- party hats and balloons left from the day
		for _, at in { { -6, -9 }, { 9, -16 }, { 3, -9.5 } } do
			r:cyl(at[1], 5.6, at[2], 4.2, 0.04, "y", rgb(230, 230, 230), "Plastic")
			r:ball(at[1], 8, at[2], 1.4, if at[1] > 0 then rgb(230, 90, 90) else rgb(110, 160, 230), "SmoothPlastic")
		end
	end,
})

-- 5. A hilltop on a clear day -------------------------------------------------------------------------
-- Grass at the top of the hill behind town, a checked blanket with a basket and a flask on it, a
-- kite lying in the grass, wildflowers, a stile in an old fence and one small tree. Big soft
-- clouds float over the sea, and the town is far below in the haze. A cloud in somebody's shape
-- can turn up among them (the `cloud` spot).
stage({
	id = "hilltop",
	name = "A hilltop under the clouds",
	marks = {
		{
			at = v3(-1.4, 0.16, -0.6),
			yaw = 0,
			pose = "lie",
			head = v3(0, 0.9, -1.6),
			close = { eye = v3(-1.0, 6.2, 1.4), look = v3(-1.4, 0.9, -2.0), fov = 32 },
		},
		{
			at = v3(1.4, 0.16, -0.6),
			yaw = 0,
			pose = "lie",
			head = v3(0, 0.9, -1.6),
			close = { eye = v3(1.8, 6.2, 1.4), look = v3(1.4, 0.9, -2.0), fov = 32 },
		},
		{ at = v3(-5.4, 0, 2.6), yaw = 70 },
		{ at = v3(-3.2, 0, 5.4), yaw = -142 },
	},
	shots = {
		wide = { eye = v3(3, 6, 15), look = v3(-1, 2, -3), fov = 48 },
		two = { eye = v3(0, 9.6, 3.6), look = v3(0, 0.8, -1.6), fov = 40 },
		side = { eye = v3(-10, 4, 6), look = v3(-1.5, 2.4, -1), fov = 44 },
		up = { eye = v3(0.4, 2.2, 2.6), look = v3(6, 40, -60), fov = 56 },
		sky = { eye = v3(0.4, 2, 2.6), look = v3(8, 62, -110), fov = 56 },
		lawn = { eye = v3(-12, 3.4, 9), look = v3(-4.2, 1.8, 3.6), fov = 42 },
	},
	bounds = { lo = v3(-16, 1, -12), hi = v3(16, 16, 20) },
	light = { hour = 13, face = 150 },
	spots = { cloud = CFrame.new(8, 68, -110) * yaw(180) },
	build = function(r: R)
		local GRASS = rgb(128, 172, 92)
		r:block(-80, -1, -40, 80, 0, 60, GRASS, "Grass")
		-- the hill falls away behind: grass going down, the town and the sea far below
		r:ramp(-80, -60, -120, 80, 0, -40, true, GRASS, "Grass")
		r:block(-600, -64, -900, 600, -60, -120, rgb(70, 120, 170), "SmoothPlastic")
		local next = rand(5)
		local x = -160
		local k = 0
		while x < 160 do
			k += 1
			local w = 8 + next() * 10
			K.farBlock(
				r,
				x + w / 2,
				-200 - next() * 30,
				w,
				8,
				-64,
				-50 + next() * 10,
				rgb(196, 186, 180),
				nil,
				k,
				if k % 3 == 0 then "gable" else ""
			)
			x += w + 2 + next() * 6
		end
		-- the blanket, checked, with a basket and a flask
		for i = 0, 5 do
			for j = 0, 5 do
				r:block(
					-3.2 + i * 1.07,
					0.02,
					-3.2 + j * 1.07,
					-2.13 + i * 1.07,
					0.12,
					-2.13 + j * 1.07,
					if (i + j) % 2 == 0 then rgb(214, 90, 84) else rgb(244, 236, 220),
					"Fabric"
				)
			end
		end
		item(r, "cozy_blanket_basket", CFrame.new(3.6, 0, 1.6) * yaw(-20))
		r:cyl(3.8, 0.5, -1.6, 1.0, 0.36, "y", rgb(110, 150, 200), "Metal")
		r:cyl(3.8, 1.05, -1.6, 0.12, 0.4, "y", rgb(60, 60, 66), "Metal")
		-- the kite in the grass with its tail
		r:quad(
			v3(5, 0.05, 4),
			v3(6.3, 0.05, 3.3),
			v3(7.6, 0.05, 4.2),
			v3(6.2, 0.05, 6.2),
			0.04,
			rgb(250, 200, 80),
			"Fabric"
		)
		for i = 1, 5 do
			r:boxAt(
				CFrame.new(6.2 - i * 0.6, 0.05, 6.4 + i * 0.5) * yaw(30 * i),
				0.3,
				0.04,
				0.2,
				if i % 2 == 0 then rgb(240, 90, 90) else rgb(90, 150, 240),
				"Fabric"
			)
		end
		-- the stile in the old fence, and a small tree by it
		for z = -14, 14, 4 do
			r:box(-11, 1.4, z, 0.35, 2.8, 0.35, rgb(130, 100, 76), "Wood")
		end
		for _, y in { 0.9, 2.1 } do
			r:block(-11.1, y - 0.12, -14, -10.9, y + 0.12, 14, rgb(150, 116, 86), "Wood")
		end
		r:block(-11.6, 0.9, 1.2, -10.4, 1.1, 2.8, rgb(150, 116, 86), "Wood")
		K.roundTree(r, -13, 0, -6, 11, 21)
		-- wildflowers and tufts all round
		K.tufts(r, -14, -10, 14, 16, 0, 110, 15)
		K.flowers(
			r,
			-14,
			-10,
			14,
			16,
			0,
			50,
			16,
			{ rgb(250, 240, 170), rgb(240, 170, 200), rgb(180, 190, 250), rgb(250, 250, 250) }
		)
		-- the clouds: big soft heaps out over the sea
		for i, c in
			{
				{ -60, 50, -120, 14 },
				{ -20, 74, -150, 18 },
				{ 40, 58, -130, 15 },
				{ 80, 80, -170, 20 },
				{ -90, 82, -170, 16 },
				{ 20, 38, -90, 9 },
			}
		do
			K.cloud(r, CFrame.new(c[1], c[2], c[3]), c[4], i * 13)
		end
	end,
})

-- 6. A strange room in a dream -----------------------------------------------------------------------
-- A sitting room that has got everything a little wrong: the table, its chairs and a lamp stand
-- on the ceiling, a door hangs high up on the wall, a staircase climbs into the ceiling and stops,
-- a clock has too many hands, the window shows day in one pane and night in the other, the walls
-- are papered with stars, and books and a teacup hang in the air.
stage({
	id = "oddroom",
	name = "A strange room in a dream",
	marks = {
		{ at = v3(0, 0, 0), yaw = 0, pose = "float", head = v3(0, 5.4, 0) },
		{ at = v3(-4.6, 0, 2.4), yaw = 40 },
		{ at = v3(4.6, 0, 2.4), yaw = -40 },
	},
	shots = {
		wide = { eye = v3(1, 6.4, 13), look = v3(0, 5.6, -4), fov = 54 },
		two = { eye = v3(-1.6, 5.4, 6), look = v3(0, 5.4, 0), fov = 38 },
		side = { eye = v3(-8, 4.2, 7), look = v3(1, 7, -5), fov = 50 },
		ceiling = { eye = v3(0, 3.6, 7), look = v3(0, 11.5, -3), fov = 52 },
		clock = { eye = v3(3, 6.4, 4), look = v3(6.4, 7.4, -7.6), fov = 36 },
	},
	bounds = { lo = v3(-9, 1, -7.5), hi = v3(9, 13, 16) },
	light = {
		hour = 15,
		face = 30,
		indoor = true,
		air = { color = rgb(220, 196, 240), decay = rgb(190, 160, 230), density = 0.3, haze = 2 },
		grade = { tint = rgb(246, 236, 255), saturation = 0.14 },
	},
	props = {
		books = {
			spots = { air = CFrame.new(-3.6, 6.4, -3) },
			start = "air",
			parts = {
				one = {
					pivot = CFrame.new(0, 0, 0),
					build = function(r: R)
						r:boxAt(CFrame.Angles(0.4, 0.3, 0.2), 1.2, 0.3, 1.6, rgb(150, 70, 66), "Fabric")
					end,
					motion = { bob = { amp = 0.4, rate = 0.25 }, swing = { axis = "y", amp = 20, rate = 0.1 } },
				},
				two = {
					pivot = CFrame.new(2, 1.6, 0.6),
					build = function(r: R)
						r:boxAt(
							CFrame.new(2, 1.6, 0.6) * CFrame.Angles(-0.3, 0.8, 0.5),
							1.0,
							0.26,
							1.4,
							rgb(70, 96, 140),
							"Fabric"
						)
					end,
					motion = { bob = { amp = 0.5, rate = 0.2, phase = 0.4 } },
				},
				cup = {
					pivot = CFrame.new(8.2, 0.2, 0.4),
					build = function(r: R)
						r:cyl(8.2, 0.2, 0.4, 0.6, 0.6, "y", rgb(250, 250, 246), "SmoothPlastic")
						r:cyl(8.2, -0.12, 0.4, 0.06, 1.0, "y", rgb(250, 250, 246), "SmoothPlastic")
					end,
					motion = {
						bob = { amp = 0.3, rate = 0.3, phase = 0.7 },
						swing = { axis = "z", amp = 15, rate = 0.15 },
					},
				},
			},
		},
	},
	build = function(r: R)
		local WALL = rgb(120, 110, 176)
		room(r, 18, -8, 8, 12, WALL, rgb(170, 140, 110), rgb(150, 120, 100))
		-- stars on the walls
		local next = rand(77)
		for i = 1, 40 do
			local x, y = (next() - 0.5) * 17, 1 + next() * 10
			r:block(x - 0.15, y - 0.15, -7.98, x + 0.15, y + 0.15, -7.94, rgb(250, 230, 140), "SmoothPlastic")
		end
		-- the furniture on the ceiling, upside down
		local up = CFrame.new(0, 12, -2) * CFrame.Angles(0, 0, math.pi)
		item(r, "table_round", up, "B98B66", "B98B66")
		item(r, "chair_dining", up * CFrame.new(-2.6, 0, 0) * yaw(90))
		item(r, "chair_dining", up * CFrame.new(2.6, 0, 0) * yaw(-90))
		item(r, "lamp_floor", CFrame.new(-6, 12, 2) * CFrame.Angles(0, 0, math.pi))
		item(r, "rug_round", CFrame.new(0, 12, -2) * CFrame.Angles(0, 0, math.pi), "7E9CC8", "E8C77E")
		-- a door halfway up the back wall
		r:block(1.2, 5.6, -7.96, 4, 10.6, -7.8, rgb(200, 150, 100), "Wood")
		r:cyl(3.5, 8, -7.7, 0.2, 0.3, "z", rgb(230, 190, 90), "Metal")
		-- stairs that climb into the ceiling
		for k = 0, 9 do
			r:block(
				-8.4 + k * 0.1,
				k * 1.2,
				-7.6 + k * 1.1,
				-6,
				k * 1.2 + 1.2,
				-6.4 + k * 1.1,
				rgb(170, 130, 100),
				"WoodPlanks"
			)
		end
		-- the clock with too many hands
		r:cyl(6.4, 7.4, -7.9, 0.2, 3.6, "z", rgb(240, 236, 220), "SmoothPlastic")
		r:cyl(6.4, 7.4, -8.0, 0.2, 4.0, "z", rgb(150, 110, 80), "Wood")
		for k = 0, 6 do
			r:boxAt(
				CFrame.new(6.4, 7.4, -7.76) * CFrame.Angles(0, 0, k * 0.9) * CFrame.new(0, 0.7, 0),
				0.1,
				1.4,
				0.04,
				rgb(40, 40, 44),
				"SmoothPlastic"
			)
		end
		-- the window: day on the left, night on the right
		r:block(-5.6, 4.4, -7.98, -4.1, 8, -7.9, rgb(150, 200, 250), "Neon")
		r:block(-4.1, 4.4, -7.98, -2.6, 8, -7.9, rgb(30, 36, 80), "SmoothPlastic")
		r:block(-5.8, 4.2, -7.96, -2.4, 4.4, -7.7, rgb(240, 236, 226), "Wood")
		r:block(-5.8, 8, -7.96, -2.4, 8.2, -7.7, rgb(240, 236, 226), "Wood")
		r:block(-4.2, 4.4, -7.96, -4.0, 8, -7.7, rgb(240, 236, 226), "Wood")
		-- an armchair facing the wall, and a lamp that lights the room
		item(r, "armchair", CFrame.new(5.4, 0, -4.6) * yaw(200), "C98BB5", "C98BB5")
		r:glow(r:ball(-7, 3.2, 4, 0.8, WARM, "Neon"), 20, 1.4, WARM)
		r:cyl(-7, 1.6, 4, 3.2, 0.2, "y", IRON, "Metal")
		r:glow(r:ball(6.6, 9.4, 4, 0.8, rgb(220, 200, 255), "Neon"), 20, 1.2, rgb(220, 200, 255))
	end,
})

-- 7. The town square -----------------------------------------------------------------------------------
-- Stone paving round a fountain, benches, lamp posts with bunting strung between them, planters,
-- a little stage of boards with a table for a judge, and the shopfronts behind with their awnings.
-- Late afternoon.
stage({
	id = "square",
	name = "The town square",
	marks = {
		{ at = v3(-2.4, 0.1, 1.2), yaw = 18 },
		{ at = v3(2.4, 0.1, 1.2), yaw = -18 },
		{ at = v3(0, 0.1, -2.6), yaw = 0 },
		{ at = v3(-6.4, 0.1, 4.4), yaw = 60 },
		{ at = v3(6.4, 0.1, 4.4), yaw = -60 },
		{ at = v3(-6.8, 0.1, 0.8), yaw = 100 },
		{ at = v3(6.2, 0.1, -1.6), yaw = -100 },
	},
	shots = {
		wide = { eye = v3(2, 8.4, 20), look = v3(0, 3.6, -2), fov = 48 },
		two = { eye = v3(0, 5, 8.6), look = v3(0, 4.4, 1.2), fov = 36 },
		side = { eye = v3(-14, 6, 10), look = v3(0, 3.6, 0), fov = 44 },
		high = { eye = v3(10, 14, 16), look = v3(0, 2, 0), fov = 46 },
		judge = { eye = v3(1.4, 5.2, 3.2), look = v3(0, 4.4, -2.6), fov = 34 },
	},
	bounds = { lo = v3(-18, 1, -8), hi = v3(18, 18, 26) },
	light = { hour = 16.6, face = 125 },
	build = function(r: R)
		local STONE = rgb(196, 186, 172)
		r:block(-200, -1, -200, 200, 0, 200, rgb(120, 160, 90), "Grass")
		r:block(-30, 0, -30, 30, 0.1, 30, shade(STONE, 0.92), "Slate")
		for i = -7, 6 do
			for j = -7, 6 do
				if (i + j) % 2 == 0 then
					r:block(i * 4 + 0.1, 0.1, j * 4 + 0.1, i * 4 + 3.9, 0.14, j * 4 + 3.9, STONE, "Slate")
				end
			end
		end
		-- the fountain behind them, and the stage with the judge's table to the side
		item(r, "fountain", CFrame.new(0, 0.14, -10))
		r:block(-9, 0.1, -6, -4, 1.1, -2, rgb(150, 112, 84), "WoodPlanks")
		item(r, "table_round", CFrame.new(-6.5, 1.1, -4.6), "B98B66", "B98B66")
		r:block(-7.2, 4.1, -4.4, -5.8, 4.14, -3.6, rgb(250, 248, 240), "SmoothPlastic")
		item(r, "bench_wood", CFrame.new(10, 0.1, -3) * yaw(-90))
		item(r, "bench_wood", CFrame.new(-11, 0.1, 6) * yaw(90))
		-- lamp posts round the square with bunting between them
		local FLAGS = { rgb(236, 110, 100), rgb(250, 200, 90), rgb(110, 170, 230), rgb(140, 200, 120) }
		local posts = { v3(-12, 0.1, -6), v3(12, 0.1, -6), v3(-13, 0.1, 8), v3(13, 0.1, 8) }
		for _, p in posts do
			K.lampPost(r, p.X, p.Y, p.Z, 8)
		end
		K.bunting(r, posts[1] + v3(0, 8, 0), posts[2] + v3(0, 8, 0), 1.2, 14, FLAGS)
		K.bunting(r, posts[1] + v3(0, 7.6, 0), posts[3] + v3(0, 7.6, 0), 1.0, 9, FLAGS)
		K.bunting(r, posts[2] + v3(0, 7.6, 0), posts[4] + v3(0, 7.6, 0), 1.0, 9, FLAGS)
		-- planters at the corners
		for _, p in { v3(-16, 0.1, 0), v3(16, 0.1, 0), v3(-8, 0.1, 12), v3(8, 0.1, 12) } do
			K.pot(r, p.X, p.Y, p.Z, 1.4, rgb(176, 120, 96), rgb(240, 150, 170))
		end
		-- the shops behind: fronts with their awnings, windows and doors
		for i, x in { -24, -8, 8, 24 } do
			local wall = ({ rgb(236, 220, 196), rgb(210, 226, 220), rgb(240, 210, 200), rgb(220, 214, 236) })[i]
			r:block(x - 7.8, 0.1, -32, x + 7.8, 16, -24, wall, "WoodPlanks")
			r:wedge(CFrame.new(x, 18, -28) * yaw(0), 15.6, 4, 8, rgb(170, 110, 100), "Slate")
			K.window(r, x - 3.6, 3, -23.9, 3.4, 3.6, rgb(250, 248, 240), rgb(120, 150, 170))
			K.window(r, x + 3.6, 9.4, -23.9, 3, 3.2, rgb(250, 248, 240), rgb(120, 150, 170))
			K.window(r, x - 3.6, 9.4, -23.9, 3, 3.2, rgb(250, 248, 240), rgb(120, 150, 170))
			r:block(x + 2.2, 0.1, -24.1, x + 5, 6.6, -23.9, rgb(110, 80, 70), "Wood")
			local AWN = ({ rgb(220, 90, 80), rgb(80, 150, 130), rgb(230, 170, 80), rgb(130, 110, 190) })[i]
			for k = 0, 7 do
				r:wedge(
					CFrame.new(x - 7 + k * 2 + 1, 7.4, -22.6) * yaw(180),
					2,
					1.2,
					2.8,
					if k % 2 == 0 then AWN else rgb(250, 248, 240),
					"Fabric"
				)
			end
		end
	end,
})

-- 8. A throne room, in a daydream -----------------------------------------------------------------------
-- A great hall of pale stone: a red carpet up steps to a golden throne under a canopy, columns
-- down each side, tall windows full of morning, banners, chandeliers lit, statues and urns of
-- flowers.
local THRONE = K.spotOf("vip_throne", "seat")
stage({
	id = "throne",
	name = "A throne room",
	marks = {
		{ at = v3(0, 2.54, -15.6) + THRONE, yaw = 0, sit = true },
		{ at = v3(-2.4, 0.1, -3), yaw = 180 },
		{ at = v3(2.4, 0.1, -3), yaw = 180 },
		{ at = v3(-5.6, 0.1, -6), yaw = 140 },
		{ at = v3(5.6, 0.1, -6), yaw = -140 },
	},
	shots = {
		wide = { eye = v3(0, 8, 14), look = v3(0, 5, -12), fov = 50 },
		two = { eye = v3(4, 5.6, 2.6), look = v3(0, 4.4, -3), fov = 40 },
		side = { eye = v3(-6, 7, 7), look = v3(0, 5, -10), fov = 46 },
		throne = { eye = v3(0, 7.4, -4.6), look = v3(0, 6, -15.4), fov = 44 },
		bow = { eye = v3(-3.4, 8.4, -11.6), look = v3(0, 2.4, -3), fov = 44 },
	},
	bounds = { lo = v3(-11, 1, -15), hi = v3(11, 18, 20) },
	light = { hour = 10.5, face = 150, indoor = true, grade = { tint = rgb(255, 244, 226), saturation = 0.1 } },
	build = function(r: R)
		local STONE = rgb(226, 220, 206)
		r:block(-14, -0.8, -20, 14, 0.1, 20, rgb(190, 184, 172), "Marble")
		for i = -7, 6 do
			for j = -10, 9 do
				if (i + j) % 2 == 0 then
					r:block(i * 2, 0.1, j * 2, i * 2 + 2, 0.14, j * 2 + 2, STONE, "Marble")
				end
			end
		end
		r:block(-14, 0, -20.6, 14, 20, -20, STONE, "Marble")
		r:block(-14.6, 0, -20, -14, 20, 20, STONE, "Marble")
		r:block(14, 0, -20, 14.6, 20, 20, STONE, "Marble")
		r:block(-14.6, 20, -20.6, 14.6, 20.6, 20, rgb(200, 190, 170), "Marble")
		-- the dais and its steps, the carpet, the throne under its canopy
		for k = 0, 2 do
			r:block(-6 + k, 0.14 + k * 0.8, -19.6, 6 - k, 0.94 + k * 0.8, -11 - k * 1.2, rgb(206, 198, 184), "Marble")
			r:block(
				-1.6,
				0.94 + k * 0.8,
				-12.2 - k * 1.2,
				1.6,
				1.0 + k * 0.8,
				-11 - k * 1.2,
				rgb(170, 40, 50),
				"Fabric"
			)
		end
		r:block(-1.6, 0.14, -11, 1.6, 0.2, 18, rgb(170, 40, 50), "Fabric")
		item(r, "vip_throne", CFrame.new(0, 2.54, -15.6))
		r:block(-3, 12, -19.6, 3, 12.6, -15, rgb(190, 150, 70), "Metal")
		for _, sx in { -1, 1 } do
			r:block(sx * 3 - 0.8, 2.5, -19.5, sx * 3 + 0.8, 12, -19.2, rgb(150, 40, 60), "Fabric")
		end
		-- columns down each side, banners between them, tall windows
		for z = -16, 12, 7 do
			for _, sx in { -1, 1 } do
				item(r, "pillar_fluted", CFrame.new(sx * 9, 0.14, z), "EEE8DA", "EEE8DA")
				r:block(sx * 9 - 1.2, 12, z - 1.2, sx * 9 + 1.2, 13, z + 1.2, STONE, "Marble")
			end
		end
		for z = -12.5, 9, 7 do
			for _, sx in { -1, 1 } do
				r:block(sx * 13.9 - 0.04, 4, z - 1.8, sx * 13.9 + 0.04, 15, z + 1.8, rgb(250, 240, 210), "Neon")
				r:block(sx * 13.9 - 0.1, 3.8, z - 2, sx * 13.9 + 0.1, 4, z + 2, rgb(200, 170, 110), "Metal")
				r:block(sx * 13.6 - 0.1, 8, z + 2.2, sx * 13.6 + 0.1, 15, z + 3.6, rgb(160, 40, 60), "Fabric")
				r:block(sx * 13.55 - 0.1, 11, z + 2.6, sx * 13.55 + 0.1, 12, z + 3.2, rgb(230, 190, 90), "Metal")
			end
		end
		-- the chandeliers, lit
		for _, z in { -8, 4 } do
			item(r, "vip_chandelier", CFrame.new(0, 20, z))
			r:glow(r:ball(0, 17.2, z, 0.6, WARM, "Neon"), 30, 1.5, WARM)
		end
		-- statues and urns of flowers by the steps
		for _, sx in { -1, 1 } do
			item(r, "vip_star_statue", CFrame.new(sx * 7, 0.1, -12) * yaw(-sx * 20))
			item(r, "fancy_urn_plinth", CFrame.new(sx * 4.5, 0.1, -9) * yaw(sx * 10))
		end
		-- a gilt frame on the back wall over it all
		K.picture(
			r,
			0,
			15.6,
			-20,
			6,
			3.4,
			rgb(200, 160, 80),
			{ rgb(120, 150, 200), rgb(150, 190, 120), rgb(240, 210, 140) }
		)
	end,
})

-- 9. Stuck at the top of the big wheel -----------------------------------------------------------------
-- Inside one of the big wheel's cabins: two benches facing each other, windows all round, a rail,
-- a little lamp, a sign of the rules. Outside, the wheel's rim and spokes, the other cabins hanging
-- off it and swaying, the fairground below, the town and the sea far off at sunset.
stage({
	id = "wheel",
	name = "The top of the big wheel",
	marks = {
		{ at = v3(-2.4, 1.6, 0), yaw = 90, sit = true },
		{ at = v3(2.4, 1.6, 0), yaw = -90, sit = true },
		{ at = v3(0, 0, 1.0), yaw = 0 },
	},
	shots = {
		wide = { eye = v3(0.2, 5.4, 3.1), look = v3(0, 3.4, -1.8), fov = 60 },
		two = { eye = v3(0, 4.6, 3.1), look = v3(0, 3.8, -0.2), fov = 60 },
		side = { eye = v3(-2.6, 5.6, 3.3), look = v3(2.4, 3.2, -0.6), fov = 56 },
		out = { eye = v3(14, 2, 26), look = v3(0, -6, -1), fov = 50 },
		view = { eye = v3(0.6, 5.6, -1.6), look = v3(-10, -40, -60), fov = 50 },
	},
	bounds = { lo = v3(-3.4, 1, -3), hi = v3(30, 30, 30) },
	light = { hour = 17.6, face = -30 },
	props = {
		cabins = {
			spots = { wheel = CFrame.new(0, 0, 0) },
			start = "wheel",
			parts = {
				left = {
					pivot = CFrame.new(-35.2, -8.4, -1),
					build = function(r: R)
						r:block(-37.7, -16, -3.5, -32.7, -10.6, 1.5, rgb(110, 170, 210), "Metal")
						r:cyl(-35.2, -9.5, -1, 1.8, 0.2, "y", IRON, "Metal")
						r:block(-37.5, -14, 1.52, -32.9, -11.2, 1.56, rgb(60, 70, 90), "Glass")
					end,
					motion = { swing = { axis = "z", amp = 3, rate = 0.2 } },
				},
				right = {
					pivot = CFrame.new(35.2, -8.4, -1),
					build = function(r: R)
						r:block(32.7, -16, -3.5, 37.7, -10.6, 1.5, rgb(240, 190, 90), "Metal")
						r:cyl(35.2, -9.5, -1, 1.8, 0.2, "y", IRON, "Metal")
						r:block(32.9, -14, 1.52, 37.5, -11.2, 1.56, rgb(60, 70, 90), "Glass")
					end,
					motion = { swing = { axis = "z", amp = 3, rate = 0.17, phase = 0.4 } },
				},
			},
		},
	},
	build = function(r: R)
		local CAB = rgb(226, 96, 90)
		-- the cabin: floor, a low wall round it, glass over that, a roof, the posts
		r:block(-3.6, -0.6, -2.6, 3.6, 0, 2.6, rgb(90, 90, 96), "Metal")
		r:block(-3.6, 0, -2.6, 3.6, 2.4, -2.3, CAB, "Metal")
		r:block(-3.6, 0, -2.6, -3.3, 2.4, 2.6, CAB, "Metal")
		r:block(3.3, 0, -2.6, 3.6, 2.4, 2.6, CAB, "Metal")
		r:glass(-3.5, 2.4, -2.55, 3.5, 6.6, -2.45)
		r:glass(-3.55, 2.4, -2.45, -3.45, 6.6, 2.5)
		r:glass(3.45, 2.4, -2.45, 3.55, 6.6, 2.5)
		r:block(-3.8, 6.6, -2.8, 3.8, 7.2, 2.8, CAB, "Metal")
		r:cyl(0, 7.6, 0, 0.8, 5.6, "y", shade(CAB, 0.85), "Metal")
		for _, sx in { -3.5, 3.5 } do
			for _, sz in { -2.5, 2.5 } do
				r:box(sx, 3.3, sz, 0.24, 6.6, 0.24, rgb(230, 230, 236), "Metal")
			end
		end
		r:cyl(0, 9, 0, 2.4, 0.5, "y", IRON, "Metal")
		r:cyl(0, 10.4, 0, 0.6, 3, "x", IRON, "Metal")
		-- benches facing each other, a rail between, a lamp, the rules
		for _, sx in { -1, 1 } do
			r:block(
				sx * 3.3 - (if sx < 0 then 0 else 1.6),
				0,
				-2.2,
				sx * 3.3 + (if sx < 0 then 1.6 else 0),
				1.6,
				2.2,
				rgb(150, 112, 84),
				"WoodPlanks"
			)
			r:block(sx * 3.3 - 0.06, 1.6, -2.2, sx * 3.3 + 0.06, 3.4, 2.2, rgb(160, 120, 90), "WoodPlanks")
		end
		r:cyl(0, 2.6, -2.2, 0.12, 3.6, "x", rgb(220, 220, 226), "Metal")
		r:glow(r:ball(0, 6.4, 0, 0.5, WARM, "Neon"), 12, 1, WARM)
		r:block(-1, 4.4, -2.3, 1, 5.6, -2.26, rgb(250, 248, 236), "SmoothPlastic")
		for k = 0, 3 do
			r:block(
				-0.8,
				5.3 - k * 0.25,
				-2.26,
				0.2 + (k % 2) * 0.5,
				5.36 - k * 0.25,
				-2.22,
				rgb(60, 60, 70),
				"SmoothPlastic"
			)
		end
		-- the wheel: its rim round the hub far below the cabin, its spokes
		local hub = v3(0, -38, -1)
		local R0 = 46
		local n = 36
		for k = 0, n - 1 do
			local a0, a1 = k * 2 * math.pi / n, (k + 1) * 2 * math.pi / n
			local p0 = hub + v3(math.sin(a0) * R0, math.cos(a0) * R0, 0)
			local p1 = hub + v3(math.sin(a1) * R0, math.cos(a1) * R0, 0)
			r:beam(p0, p1, 0.7, 0.7, rgb(240, 240, 244), "Metal")
			r:beam(p0 + v3(0, 0, -2.4), p1 + v3(0, 0, -2.4), 0.5, 0.5, rgb(240, 240, 244), "Metal")
			if k % 3 == 0 and k ~= 0 then
				r:beam(hub, p0, 0.4, 0.4, rgb(220, 220, 226), "Metal")
				local bulb = r:ball(p0.X, p0.Y, p0.Z + 0.5, 0.5, WARM, "Neon")
				r:glow(bulb, 0)
			end
		end
		r:cyl(hub.X, hub.Y, hub.Z - 1.2, 3.4, 4, "z", rgb(200, 200, 206), "Metal")
		for _, sx in { -1, 1 } do
			r:beam(hub + v3(0, 0, -3), hub + v3(sx * 30, -60, -4), 1.6, 1.6, rgb(210, 210, 216), "Metal")
		end
		-- the fairground below and the town and the sea far off
		r:block(-500, -100, -700, 500, -98, 200, rgb(110, 150, 90), "Grass")
		r:block(-900, -101, -1400, 900, -99, -700, rgb(80, 120, 170), "SmoothPlastic")
		local next = rand(19)
		for i = 1, 14 do
			local x, z = (next() - 0.5) * 300, -120 - next() * 380
			K.farBlock(
				r,
				x,
				z,
				14 + next() * 12,
				12,
				-98,
				-86 + next() * 14,
				rgb(206, 180, 170),
				rgb(255, 210, 150),
				i,
				if i % 2 == 0 then "gable" else ""
			)
		end
		for i, c in { rgb(240, 120, 110), rgb(250, 210, 120), rgb(130, 190, 240) } do
			r:cone(-30 + i * 22, -92, -60 - i * 10, 10, 12, c, "Fabric")
			r:cyl(-30 + i * 22, -96, -60 - i * 10, 6, 11, "y", rgb(250, 248, 240), "Fabric")
		end
	end,
})

-- 10. The playground -----------------------------------------------------------------------------------
-- Soft red play mats round a seesaw (a prop: it tips up and down, and the two on it go with it), a
-- swing set, a slide, a sandpit with a bucket, a bench, a low fence with a gate and trees round.
stage({
	id = "playground",
	name = "The playground",
	marks = {
		{ at = v3(-4.6, 2.1, 0), yaw = 90, sit = true, ride = { prop = "seesaw", part = "beam" } },
		{ at = v3(4.6, 2.1, 0), yaw = -90, sit = true, ride = { prop = "seesaw", part = "beam" } },
		{ at = v3(4.4, 0.1, 6.6), yaw = -150 },
		{ at = v3(-7.0, 0.1, 2.6), yaw = 120 },
	},
	shots = {
		wide = { eye = v3(0, 6.6, 17), look = v3(0, 3, -1), fov = 46 },
		two = { eye = v3(0, 5.2, 10), look = v3(0, 4.2, 0), fov = 46 },
		side = { eye = v3(-12, 5.4, 9), look = v3(0, 3.6, 0), fov = 44 },
		low = { eye = v3(1.6, 1.6, 7.6), look = v3(0, 5.6, 0), fov = 52 },
	},
	bounds = { lo = v3(-16, 1, -10), hi = v3(16, 14, 22) },
	light = { hour = 15.2, face = 120 },
	props = {
		seesaw = {
			spots = { play = CFrame.new(0, 0, 0), stuck = CFrame.new(0, 0, 0) },
			start = "play",
			build = function(r: R)
				r:block(-0.9, 0.1, -0.9, 0.9, 0.4, 0.9, rgb(120, 120, 130), "Metal")
				r:wedge(CFrame.new(0, 1.0, 0) * yaw(90), 1.8, 1.2, 1.2, rgb(230, 120, 90), "Metal")
				r:cyl(0, 1.4, 0, 0.5, 2.2, "z", rgb(70, 70, 80), "Metal")
			end,
			parts = {
				beam = {
					pivot = CFrame.new(0, 1.4, 0),
					build = function(r: R)
						r:block(-5.8, 1.5, -0.45, 5.8, 1.8, 0.45, rgb(250, 200, 90), "Wood")
						for _, sx in { -1, 1 } do
							r:block(
								sx * 4.6 - 0.8,
								1.8,
								-0.6,
								sx * 4.6 + 0.8,
								2.1,
								0.6,
								rgb(230, 90, 80),
								"SmoothPlastic"
							)
							r:cyl(sx * 3.5, 2.6, -0.5, 1.6, 0.16, "y", rgb(70, 110, 190), "Metal")
							r:cyl(sx * 3.5, 2.6, 0.5, 1.6, 0.16, "y", rgb(70, 110, 190), "Metal")
							r:cyl(sx * 3.5, 3.4, 0, 1.2, 0.16, "z", rgb(70, 110, 190), "Metal")
							r:cyl(sx * 5.8, 1.6, 0, 0.6, 0.7, "y", rgb(40, 40, 44), "Rubber")
						end
					end,
					motion = { swing = { axis = "z", amp = 14, rate = 0.32 } },
					by = { stuck = { tilt = { axis = "z", deg = -16 } } },
				},
			},
		},
	},
	build = function(r: R)
		r:block(-200, -1, -200, 200, 0, 200, rgb(126, 170, 92), "Grass")
		r:block(-12, 0, -8, 12, 0.1, 10, rgb(200, 110, 100), "Rubber")
		for i = -3, 2 do
			r:block(i * 4 + 0.05, 0.1, -8, i * 4 + 0.15, 0.14, 10, shade(rgb(200, 110, 100), 0.85), "Rubber")
		end
		item(r, "swing_set", CFrame.new(-8.4, 0.1, -5) * yaw(10))
		item(r, "slide", CFrame.new(8.6, 0.1, -4.4) * yaw(-20))
		item(r, "sandbox", CFrame.new(8.6, 0.1, 5.4))
		r:cyl(8, 0.5, 5.2, 0.8, 0.6, "y", rgb(80, 150, 230), "Plastic")
		item(r, "bench_garden", CFrame.new(-8.6, 0.1, 7.6) * yaw(150))
		-- the low fence round it with a gate, and trees
		for x = -14, 14, 2 do
			if math.abs(x) > 2 then
				r:box(x, 0.8, -10, 0.2, 1.6, 0.2, rgb(240, 236, 226), "Wood")
			end
		end
		r:block(-14, 1.2, -10.08, -2, 1.36, -9.92, rgb(240, 236, 226), "Wood")
		r:block(2, 1.2, -10.08, 14, 1.36, -9.92, rgb(240, 236, 226), "Wood")
		for i, at in { { -18, -16 }, { 0, -20 }, { 18, -15 }, { -24, 4 }, { 24, 8 } } do
			K.roundTree(r, at[1], 0, at[2], 12 + (i % 2) * 3, i * 5)
		end
		K.tufts(r, -20, -18, 20, -10.5, 0, 60, 9)
		K.flowers(r, -20, -18, 20, -11, 0, 20, 10, { rgb(250, 240, 170), rgb(240, 170, 200) })
	end,
})

-- 11. A hallway at night -------------------------------------------------------------------------------
-- The landing of a house after dark: boards and a long rug, panelled walls with pictures, a side
-- table with a lamp, a coat stand, and a door in the back wall with light spilling under it. Past
-- the door (a prop: it swings open) is a lit room where somebody is up to something.
stage({
	id = "hallway",
	name = "A hallway at night",
	marks = {
		{ at = v3(-1.0, 0.04, -2.8), yaw = 90 },
		{ at = v3(-3.6, 0.04, -1.6), yaw = 80 },
		{ at = v3(0.2, 0.04, -10.4), yaw = 0 },
	},
	shots = {
		wide = { eye = v3(3.4, 6.2, 7.6), look = v3(-1, 3.6, -3.6), fov = 50 },
		two = { eye = v3(2.6, 5.0, 2.4), look = v3(-1.8, 4.2, -2.4), fov = 42 },
		side = { eye = v3(-6.4, 5.4, 5.6), look = v3(-0.6, 4, -3.4), fov = 44 },
		door = { eye = v3(0.6, 4.8, 3.6), look = v3(0.2, 4, -4.4), fov = 40 },
		inside = { eye = v3(0.8, 5.4, -0.6), look = v3(0.2, 4.4, -10.4), fov = 46 },
	},
	bounds = { lo = v3(-6.8, 1, -15.5), hi = v3(6.8, 9.4, 12) },
	light = { hour = 1.5, face = 0, indoor = true },
	props = {
		door = {
			spots = { shut = CFrame.new(-1.6, 0, -4.3), open = CFrame.new(-1.6, 0, -4.3) * yaw(100) },
			start = "shut",
			build = function(r: R)
				r:block(0.02, 0.04, -0.12, 3.18, 7.4, 0.12, rgb(236, 230, 214), "WoodPlanks")
				for _, y in { 1.2, 4.4 } do
					r:block(0.4, y, 0.12, 2.8, y + 2.4, 0.18, rgb(226, 220, 204), "WoodPlanks")
				end
				r:ball(2.8, 3.6, 0.3, 0.3, rgb(220, 180, 90), "Metal")
			end,
		},
	},
	build = function(r: R)
		local WALL = rgb(150, 170, 160)
		room(r, 14, -4.2, 6, 9, WALL, rgb(140, 104, 78), rgb(220, 214, 200), true)
		-- (the back wall, with its doorway, is drawn below, and the floor of the room past it)
		r:block(-7.5, -0.8, -16, 7.5, 0, -4.8, rgb(130, 98, 74), "WoodPlanks")
		-- the rug down the hall, the panelling
		r:block(-5.5, 0, -3.6, 5.5, 0.04, -1, rgb(150, 70, 70), "Fabric")
		r:block(-5.3, 0.04, -3.4, 5.3, 0.08, -1.2, rgb(190, 130, 90), "Fabric")
		for x = -6.5, 6.5, 1.8 do
			r:block(x - 0.06, 0.5, 5.9, x + 0.06, 3.2, 6, rgb(130, 150, 140), "Wood")
		end
		-- pictures, the side table with its lamp, the coat stand
		K.picture(r, 4.2, 5.4, -4.4, 2.2, 1.6, rgb(120, 90, 70), { rgb(100, 140, 180), rgb(120, 160, 110) })
		K.picture(r, -4.6, 5.6, -4.4, 1.4, 1.9, rgb(236, 230, 214), { rgb(230, 180, 120), rgb(200, 120, 120) })
		item(r, "table_side", CFrame.new(4.6, 0, -3.2))
		item(r, "lamp_table", CFrame.new(4.6, 2, -3.3))
		item(r, "coat_stand", CFrame.new(-6, 0, 3))
		-- the light under the door
		r:block(-1.5, 0.02, -4.6, 1.5, 0.08, -4.5, rgb(255, 220, 160), "Neon")
		-- the room beyond: walls, a lamp on, a bed and a mirror, posters
		r:block(-7.5, 0, -16.6, 7.5, 9, -16, rgb(206, 186, 150), "WoodPlanks")
		r:block(-8.1, 0, -16, -7.5, 9, -4.8, rgb(206, 186, 150), "WoodPlanks")
		r:block(7.5, 0, -16, 8.1, 9, -4.8, rgb(206, 186, 150), "WoodPlanks")
		r:block(-8.1, 9, -16.6, 8.1, 9.5, -4.8, rgb(220, 214, 200), "Wood")
		r:glow(r:ball(0, 8.2, -10, 0.7, WARM, "Neon"), 24, 1.6, WARM)
		item(r, "bed_single", CFrame.new(-5, 0, -13.6) * yaw(90), "E8A0A8", "F2EDE2")
		item(r, "mirror_floor", CFrame.new(4.6, 0, -15.4))
		K.picture(r, 2, 6, -16, 2, 2.8, rgb(40, 40, 44), { rgb(230, 90, 90), rgb(250, 210, 90), rgb(60, 60, 70) })
		item(r, "record_player", CFrame.new(5.4, 0, -11) * yaw(-90))
		-- the wall either side of the doorway, and its frame
		r:block(-7.5, 0, -4.8, -1.6, 9, -4.2, WALL, "WoodPlanks")
		r:block(1.6, 0, -4.8, 7.5, 9, -4.2, WALL, "WoodPlanks")
		r:block(-1.6, 7.4, -4.8, 1.6, 9, -4.2, WALL, "WoodPlanks")
		r:block(-1.8, 0, -4.2, -1.6, 7.6, -4.0, rgb(236, 230, 214), "Wood")
		r:block(1.6, 0, -4.2, 1.8, 7.6, -4.0, rgb(236, 230, 214), "Wood")
		r:block(-1.8, 7.4, -4.2, 1.8, 7.6, -4.0, rgb(236, 230, 214), "Wood")
	end,
})

return list
