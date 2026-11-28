--!strict
-- Workplaces that only come out of a work crate (Data/Crates). The user: "add work crates ... which
-- give exclusive work spaces which are unique to crates ... Crate workspaces are always better than
-- any money ones, giving more effectiveness, and are more interesting than normal jobs, like "Hero",
-- "CEO", "Abnormality Surpresser", etc." Each opens one of Data/Jobs' crate jobs, carries its rarity
-- in `crate`, costs nothing (category "crates": Build mode's Crate tab lists the ones the player was
-- given, Sim/Crates counts them) and is drawn at the starting house's level, in textured materials.
-- Like the coin workplaces (Recipes/Work) the worker stands at `workSpot` facing `workYaw`, and
-- each draws its own round of spots in `loop` (Sim/Routine's steps: the Routine spec holds every
-- spot clear of the parts drawn here), with an effect for while somebody works there.

local Recipe = require(script.Parent.Parent.Recipe)
local Lively = require(script.Parent.Parent.Lively)
local Colors = require(script.Parent.Parent.Parent.Util.Colors)

type R = Recipe.Recipe

local C = Recipe.Colors

local function shade(c: Color3, k: number): Color3
	return Colors.shade(c, k)
end

local function V(x: number, y: number, z: number): Vector3
	return Vector3.new(x, y, z)
end

local OAK = Color3.fromRGB(196, 154, 108)
local WALNUT = Color3.fromRGB(112, 76, 56)
local IRON = Color3.fromRGB(86, 84, 92)
local STEEL = Color3.fromRGB(176, 182, 190)
local BRASS = Color3.fromRGB(206, 168, 98)
local PAPER = Color3.fromRGB(244, 238, 222)
local INK = Color3.fromRGB(62, 58, 70)
local CREAM = Color3.fromRGB(240, 230, 208)
local LEAF = C.Leaf

-- A screen facing +Z in `cf`: a dark bezel, its picture just proud of it (lit), and a stand foot.
local function screen(r: R, cf: CFrame, w: number, h: number, glow: Color3, stand: number?)
	r:boxAt(cf, w, h, 0.08, INK, "Metal")
	r:boxAt(cf * CFrame.new(0, 0, 0.055), w - 0.12, h - 0.12, 0.03, glow, "Neon")
	if stand and stand > 0 then
		r:boxAt(cf * CFrame.new(0, -h / 2 - stand / 2, -0.06), 0.1, stand, 0.06, INK, "Metal")
		r:boxAt(cf * CFrame.new(0, -h / 2 - stand - 0.02, 0), 0.5, 0.04, 0.34, INK, "Metal")
	end
end

-- A mug standing on (x, y, z): its body, a handle at its side and the drink inside.
local function mug(r: R, x: number, y: number, z: number, col: Color3)
	r:cyl(x, y + 0.14, z, 0.28, 0.2, "y", col, "Plastic")
	r:cyl(x, y + 0.29, z, 0.04, 0.16, "y", Color3.fromRGB(110, 72, 50), "Plastic")
	r:block(x + 0.1, y + 0.06, z - 0.02, x + 0.16, y + 0.22, z + 0.02, col, "Plastic")
end

-- A sheet of paper lying on a top at height y, turned `turn` round its middle.
local function sheet(r: R, x: number, y: number, z: number, w: number, d: number, turn: number, col: Color3?)
	r:boxAt(CFrame.new(x, y + 0.02, z) * CFrame.Angles(0, turn, 0), w, 0.04, d, col or PAPER, "Fabric")
end

-- A pot plant standing on (x, y, z): a pot, its soil and a few leaves standing out of it.
local function potPlant(r: R, x: number, y: number, z: number, size: number)
	local s = size
	local pot = Color3.fromRGB(200, 120, 90)
	r:cyl(x, y + 0.25 * s, z, 0.5 * s, 0.5 * s, "y", pot, "Brick")
	r:cyl(x, y + 0.55 * s, z, 0.1 * s, 0.58 * s, "y", shade(pot, 0.9), "Brick")
	r:cyl(x, y + 0.6 * s + 0.015, z, 0.06, 0.46 * s, "y", C.Soil, "Fabric")
	r:cyl(x, y + 1.0 * s, z, 0.9 * s, 0.06 * s, "y", C.Bark, "Wood")
	for k = 0, 7 do
		local a = k * 2.4
		local up = 0.75 + (k % 3) * 0.28 + math.floor(k / 4) * 0.3
		r:noCollide(
			r:lump(
				CFrame.new(x + math.cos(a) * 0.2 * s, y + up * s, z + math.sin(a) * 0.2 * s)
					* CFrame.Angles(0, -a, 0.45),
				0.46 * s,
				0.07 * s,
				0.3 * s,
				if k % 2 == 0 then LEAF else C.DarkLeaf,
				"Fabric"
			)
		)
	end
end

-- A loop of spots (Sim/Routine's steps), each with only the fields it needs.
local function steps(list: { any }): { any }
	return list
end

-- Four plain legs under a top from x1..x2, z1..z2 at height h.
local function tableLegs(r: R, x1: number, z1: number, x2: number, z2: number, h: number, d: number, col: Color3)
	for _, x in { x1 + d / 2, x2 - d / 2 } do
		for _, z in { z1 + d / 2, z2 - d / 2 } do
			r:block(x - d / 2, 0, z - d / 2, x + d / 2, h, z + d / 2, col, "Wood")
		end
	end
end

local items: { any } = {
	-- Common ------------------------------------------------------------------------------------
	{
		id = "crate_magic",
		name = "Magic stage",
		cat = "crates",
		crate = "common",
		price = 0,
		place = "floor",
		job = "magician",
		size = Vector3.new(6, 6.4, 4.4),
		c1 = "A8434F",
		c2 = "D8B45E",
		tags = { "work" },
		style = "playful",
		lively = true,
		workSpot = Vector3.new(0, 0.5, -0.1),
		workYaw = 0,
		loop = steps({
			{ name = "show", stay = { 6, 9 }, act = "wave", say = 0.45 },
			{ name = "hat", at = V(1.8, 0.5, 1.15), look = V(1.8, 3.2, -0.9), stay = { 3, 5 }, act = "point" },
			{ name = "show", stay = { 4, 6 }, say = 0.3 },
			{ name = "trunk", at = V(-1.9, 0.5, 0.7), look = V(-1.9, 1.2, -0.9), stay = { 3, 5 }, act = "point" },
			{ name = "bow", stay = { 3, 4 }, act = "cheer", say = 0.6 },
		}),
		build = function(r: R)
			-- A little stage: a plank platform with a velvet skirt and a gold edge, a curtain of
			-- velvet folds on a gold rail with bulbs along it, a round prop table with a top hat
			-- (a rabbit's ears out of it), a wand and a fan of cards, and a painted trunk of stars.
			local velvet, gold = r.c1, r.c2
			local deck = Color3.fromRGB(118, 82, 60)
			r:block(-2.9, 0, -2.1, 2.9, 0.5, 1.6, deck, "WoodPlanks")
			r:block(-2.9, 0.04, 1.6, 2.9, 0.44, 1.64, shade(velvet, 0.85), "Fabric")
			r:block(-2.9, 0.38, 1.64, 2.9, 0.46, 1.68, gold, "Metal")
			-- the rail on two gold posts, and the bulbs along it
			for _, x in { -2.75, 2.75 } do
				r:cyl(x, 3.22, -1.95, 5.44, 0.24, "y", gold, "Metal")
				r:ball(x, 6.02, -1.95, 0.32, gold, "Metal")
			end
			r:block(-2.7, 5.7, -2.06, 2.7, 5.9, -1.84, gold, "Metal")
			for i = 0, 6 do
				Lively.twinkle(r:ball(-2.1 + i * 0.7, 5.62, -1.76, 0.16, Color3.fromRGB(255, 226, 160), "Neon"))
			end
			-- the curtain: folds standing in and out
			for i = 0, 10 do
				local x = -2.3 + i * 0.46
				local z = if i % 2 == 0 then -1.98 else -1.88
				r:block(
					x - 0.25,
					0.5,
					z - 0.06,
					x + 0.25,
					5.66,
					z + 0.06,
					shade(velvet, if i % 2 == 0 then 1 else 0.86),
					"Fabric"
				)
			end
			r:block(-2.7, 5.05, -1.82, 2.7, 5.66, -1.74, shade(velvet, 0.78), "Fabric")
			r:block(-2.7, 4.98, -1.74, 2.7, 5.08, -1.7, gold, "Metal")
			-- the prop table: a stem on a foot, a cloth over its top
			r:cyl(1.8, 0.56, -0.9, 0.08, 0.7, "y", gold, "Metal")
			r:cyl(1.8, 1.5, -0.9, 1.9, 0.14, "y", gold, "Metal")
			r:cyl(1.8, 2.62, -0.9, 0.36, 1.3, "y", shade(velvet, 0.9), "Fabric")
			-- the top hat with its band, the rabbit's ears coming up out of it
			r:cyl(1.8, 2.82, -0.9, 0.04, 0.84, "y", INK, "Fabric")
			r:cyl(1.8, 3.14, -0.9, 0.6, 0.5, "y", INK, "Fabric")
			r:cyl(1.8, 2.92, -0.9, 0.1, 0.56, "y", velvet, "Fabric")
			for _, x in { 1.72, 1.88 } do
				r:lump(
					CFrame.new(x, 3.62, -0.92) * CFrame.Angles(0, 0, (x - 1.8) * 2),
					0.1,
					0.42,
					0.07,
					C.White,
					"Fabric"
				)
				r:lump(
					CFrame.new(x, 3.62, -0.88) * CFrame.Angles(0, 0, (x - 1.8) * 2),
					0.05,
					0.3,
					0.03,
					C.Pink,
					"Fabric"
				)
			end
			-- the wand and a fan of cards in front of the hat
			r:cyl(1.62, 2.83, -0.38, 0.7, 0.06, "x", INK, "Wood")
			r:cyl(1.95, 2.83, -0.38, 0.1, 0.07, "x", C.White, "Plastic")
			for k = 0, 3 do
				r:boxAt(
					CFrame.new(-1.9, 1.465 + k * 0.035, -0.9)
						* CFrame.Angles(0, -0.6 + k * 0.3, 0)
						* CFrame.new(0, 0, 0.1),
					0.18,
					0.03,
					0.26,
					if k % 2 == 0 then C.White else Color3.fromRGB(196, 84, 84),
					"Fabric"
				)
			end
			-- the trunk: painted boards, a lid, brass corners, a scatter of stars on its front
			local blue = Color3.fromRGB(74, 90, 134)
			r:block(-2.5, 0.5, -1.35, -1.3, 1.25, -0.45, blue, "Wood")
			r:block(-2.53, 1.25, -1.38, -1.27, 1.45, -0.42, shade(blue, 0.8), "Wood")
			for _, x in { -2.53, -1.37 } do
				r:block(x, 0.5, -0.45, x + 0.1, 1.45, -0.4, gold, "Metal")
			end
			r:block(-1.98, 1.0, -0.42, -1.82, 1.3, -0.39, gold, "Metal")
			for _, s in { { -2.25, 0.8 }, { -1.55, 0.78 }, { -2.05, 1.12 } } do
				for k = 0, 1 do
					r:boxAt(
						CFrame.new(s[1], s[2], -0.435) * CFrame.Angles(0, 0, k * math.pi / 4),
						0.14,
						0.14,
						0.03,
						Color3.fromRGB(240, 206, 110),
						"Metal"
					)
				end
			end
			Lively.fx(r, "sparkles", 1.8, 3.5, -0.9, { w = 0.6, d = 0.6, work = true, color = gold })
		end,
	},
	{
		id = "crate_fortune",
		name = "Fortune booth",
		cat = "crates",
		crate = "common",
		price = 0,
		place = "floor",
		job = "fortune",
		size = Vector3.new(5.2, 6.4, 4.8),
		c1 = "6E5A9A",
		c2 = "E2C072",
		tags = { "work" },
		style = "fancy",
		lively = true,
		workSpot = Vector3.new(0, 0, -1.05),
		workYaw = 0,
		loop = steps({
			{ name = "ball", stay = { 7, 11 }, act = "point", beat = 4.5, say = 0.4 },
			{ name = "chest", at = V(-1.95, 0, -0.85), look = V(-1.9, 0.6, -1.9), stay = { 3, 5 }, act = "point" },
			{ name = "ball", stay = { 5, 8 }, say = 0.3 },
			{ name = "out front", at = V(0, 0, 3.25), look = V(0, 3, 12), stay = { 3, 5 }, act = "wave", say = 0.5 },
		}),
		build = function(r: R)
			-- A fortune teller's booth: a back drape on two posts, a striped canopy over four,
			-- scallops along its front, a round table under a floor length cloth, the crystal ball
			-- on its brass claw stand (a light moving in it), cards laid out, two candles and a
			-- little chest of charms beside the teller.
			local cloth, gold = r.c1, r.c2
			local wood = Color3.fromRGB(104, 72, 58)
			for _, p in { { -2.4, -2.3 }, { 2.4, -2.3 }, { -2.4, 2.1 }, { 2.4, 2.1 } } do
				r:cyl(p[1], 3.0, p[2], 6.0, 0.2, "y", wood, "Wood")
				r:ball(p[1], 6.08, p[2], 0.26, gold, "Metal")
			end
			for i = 0, 9 do
				local x = -2.16 + i * 0.48
				local z = if i % 2 == 0 then -2.32 else -2.22
				r:block(
					x - 0.25,
					0.05,
					z - 0.05,
					x + 0.25,
					5.8,
					z + 0.05,
					shade(cloth, if i % 2 == 0 then 0.92 else 0.78),
					"Fabric"
				)
			end
			-- the canopy, striped, and its scalloped front
			for i = 0, 7 do
				local x1 = -2.6 + i * 0.65
				r:block(x1, 6.0, -2.45, x1 + 0.65, 6.12, 2.3, if i % 2 == 0 then cloth else gold, "Fabric")
			end
			for i = 0, 7 do
				r:lump(
					CFrame.new(-2.28 + i * 0.65, 5.92, 2.3),
					0.62,
					0.3,
					0.08,
					if i % 2 == 0 then cloth else gold,
					"Fabric"
				)
			end
			-- the table: a cloth to the floor and a gold cloth over its top
			r:cyl(0, 1.31, 0.95, 2.52, 1.7, "y", cloth, "Fabric")
			r:cyl(0, 2.6, 0.95, 0.06, 1.8, "y", gold, "Fabric")
			for k = 0, 11 do
				local a = k * math.pi / 6
				r:noCollide(
					r:lump(
						CFrame.new(math.cos(a) * 0.88, 2.48, 0.95 + math.sin(a) * 0.88),
						0.16,
						0.24,
						0.16,
						gold,
						"Fabric"
					)
				)
			end
			-- the ball on its stand, a light turning slowly inside it
			r:cyl(0, 2.69, 0.95, 0.12, 0.4, "y", BRASS, "Metal")
			for k = 0, 2 do
				local a = k * math.pi * 2 / 3
				r:lump(
					CFrame.new(math.cos(a) * 0.17, 2.8, 0.95 + math.sin(a) * 0.17) * CFrame.Angles(0, -a, 0.5),
					0.06,
					0.18,
					0.06,
					BRASS,
					"Metal"
				)
			end
			local glass = r:ball(0, 3.04, 0.95, 0.62, Color3.fromRGB(206, 196, 240), "Glass")
			glass.transp = 0.45
			Lively.twinkle(r:ball(0, 3.04, 0.95, 0.26, Color3.fromRGB(190, 160, 255), "Neon"), true)
			-- three cards laid out, face up, in front of the ball
			for i = -1, 1 do
				local cf = CFrame.new(i * 0.32, 2.63, 1.47) * CFrame.Angles(0, i * 0.12, 0)
				r:boxAt(cf * CFrame.new(0, 0.02, 0), 0.24, 0.04, 0.36, CREAM, "Fabric")
				r:boxAt(cf * CFrame.new(0, 0.06, 0), 0.16, 0.04, 0.26, shade(cloth, 0.7), "Fabric")
			end
			-- two candles, lit
			for _, x in { -0.62, 0.62 } do
				r:cyl(x, 2.82, 0.65, 0.38, 0.12, "y", CREAM, "Plastic")
				r:glow(r:ball(x, 3.06, 0.65, 0.1, Color3.fromRGB(255, 200, 110), "Neon"), 8, 0.5)
			end
			-- the chest of charms beside the teller
			r:block(-2.3, 0.05, -2.05, -1.5, 0.8, -1.55, wood, "Wood")
			r:block(-2.33, 0.8, -2.08, -1.47, 0.95, -1.52, shade(wood, 0.8), "Wood")
			r:block(-1.98, 0.5, -1.52, -1.82, 0.74, -1.49, gold, "Metal")
			Lively.fx(
				r,
				"sparkles",
				0,
				3.5,
				0.95,
				{ w = 0.6, d = 0.6, work = true, color = Color3.fromRGB(196, 170, 255) }
			)
		end,
	},
	{
		id = "crate_critic",
		name = "Tasting table",
		cat = "crates",
		crate = "common",
		price = 0,
		place = "floor",
		job = "critic",
		size = Vector3.new(6, 4.8, 3.6),
		c1 = "F2EDE2",
		c2 = "8C5A48",
		tags = { "work", "table" },
		style = "fancy",
		workSpot = Vector3.new(0, 0, -1.3),
		workYaw = 0,
		loop = steps({
			{ name = "taste", stay = { 7, 10 }, act = "point", say = 0.4 },
			{ name = "notes", at = V(-1.8, 0, -1.6), look = V(-1.0, 3, 0.4), stay = { 4, 6 }, act = "point" },
			{ name = "taste", stay = { 5, 8 }, say = 0.3 },
			{ name = "board", at = V(2.6, 0, 2.0), look = V(2.6, 3.4, 0.2), stay = { 3, 5 }, act = "point", say = 0.4 },
		}),
		build = function(r: R)
			-- A tasting table: a cloth over a wooden table on turned legs, three dishes laid out
			-- (a slice of cake, a bowl of soup, one under a silver cloche), the critic's notebook and
			-- pen, a glass of water, cutlery, a service bell, and a chalk menu on an easel.
			local cloth, wood = r.c1, r.c2
			local china = Color3.fromRGB(248, 246, 240)
			for _, x in { -1.25, 1.25 } do
				for _, z in { -0.05, 0.95 } do
					r:cyl(x, 1.35, z, 2.7, 0.18, "y", wood, "Wood")
					r:cyl(x, 0.6, z, 0.2, 0.24, "y", shade(wood, 0.85), "Wood")
				end
			end
			r:block(-1.4, 2.7, -0.15, 1.4, 2.85, 1.05, wood, "Wood")
			r:block(-1.45, 2.85, -0.2, 1.45, 2.9, 1.1, cloth, "Fabric")
			r:block(-1.45, 2.5, 1.1, 1.45, 2.9, 1.13, cloth, "Fabric")
			r:block(-1.45, 2.5, -0.23, 1.45, 2.9, -0.2, cloth, "Fabric")
			-- the dishes, each on its plate
			for _, x in { -0.85, 0, 0.85 } do
				r:cyl(x, 2.92, 0.55, 0.04, 0.6, "y", china, "Plastic")
			end
			-- a slice of cake, its layers and cream
			r:boxAt(
				CFrame.new(-0.85, 3.02, 0.55) * CFrame.Angles(0, 0.4, 0),
				0.3,
				0.16,
				0.22,
				Color3.fromRGB(214, 166, 104),
				"Fabric"
			)
			r:boxAt(CFrame.new(-0.85, 3.13, 0.55) * CFrame.Angles(0, 0.4, 0), 0.3, 0.06, 0.22, CREAM, "Fabric")
			r:ball(-0.84, 3.2, 0.55, 0.08, Color3.fromRGB(196, 72, 80), "Plastic")
			-- the soup in its bowl
			r:cyl(0, 3.02, 0.55, 0.16, 0.42, "y", china, "Plastic")
			r:cyl(0, 3.11, 0.55, 0.04, 0.36, "y", Color3.fromRGB(222, 150, 80), "Fabric")
			-- the cloche and its knob
			r:lump(CFrame.new(0.85, 2.96, 0.55), 0.5, 0.42, 0.5, STEEL, "Metal")
			r:ball(0.85, 3.2, 0.55, 0.08, STEEL, "Metal")
			-- notebook, pen, glass, cutlery and the bell
			sheet(r, -0.7, 2.9, -0.02, 0.5, 0.34, 0.15, Color3.fromRGB(150, 64, 64))
			sheet(r, -0.7, 2.94, -0.02, 0.44, 0.3, 0.15, PAPER)
			r:cyl(-0.4, 3.0, 0.0, 0.34, 0.04, "x", INK, "Plastic")
			local water = r:cyl(1.3, 3.04, 0.15, 0.28, 0.16, "y", Color3.fromRGB(206, 232, 240), "Glass")
			water.transp = 0.3
			for _, x in { -0.42, 0.42 } do
				r:block(x - 0.02, 2.9, 0.3, x + 0.02, 2.93, 0.75, STEEL, "Metal")
			end
			r:cyl(1.15, 2.95, 0.85, 0.06, 0.24, "y", BRASS, "Metal")
			r:lump(CFrame.new(1.15, 3.02, 0.85), 0.2, 0.14, 0.2, BRASS, "Metal")
			-- the menu easel: two legs leaning, a back leg, a chalkboard in a wooden frame
			for _, x in { 2.35, 2.85 } do
				r:boxAt(CFrame.new(x, 2.0, 0.3) * CFrame.Angles(-0.12, 0, 0), 0.1, 4.0, 0.1, OAK, "Wood")
			end
			r:boxAt(CFrame.new(2.6, 1.75, -0.15) * CFrame.Angles(0.25, 0, 0), 0.1, 3.6, 0.1, OAK, "Wood")
			r:boxAt(
				CFrame.new(2.6, 3.0, 0.24) * CFrame.Angles(-0.12, 0, 0),
				0.68,
				1.3,
				0.06,
				Color3.fromRGB(56, 64, 60),
				"Slate"
			)
			for k = 0, 3 do
				r:boxAt(
					CFrame.new(2.6, 3.42 - k * 0.24, 0.28) * CFrame.Angles(-0.12, 0, 0),
					0.44 - (k % 2) * 0.12,
					0.04,
					0.04,
					Color3.fromRGB(236, 234, 226),
					"Fabric"
				)
			end
			Lively.fx(r, "steam", 0, 3.2, 0.55, { w = 0.3, d = 0.3, work = true })
		end,
	},
	-- Uncommon ----------------------------------------------------------------------------------
	{
		id = "crate_radio",
		name = "Radio booth",
		cat = "crates",
		crate = "uncommon",
		price = 0,
		place = "floor",
		job = "radio",
		size = Vector3.new(6, 5.6, 3.6),
		c1 = "D86A4A",
		c2 = "4A4E5A",
		tags = { "work", "music" },
		style = "modern",
		lively = true,
		workSpot = Vector3.new(0, 0, -1.35),
		workYaw = 0,
		loop = steps({
			{ name = "on air", stay = { 6, 9 }, act = "wave", say = 0.45 },
			{ name = "records", at = V(-1.9, 0, -1.6), look = V(-1.5, 3, 0.4), stay = { 3, 5 }, act = "point" },
			{ name = "on air", stay = { 5, 8 }, act = "point", beat = 4, say = 0.35 },
			{ name = "wave", at = V(0, 0, 2.65), look = V(0, 3, 12), stay = { 3, 5 }, act = "cheer", say = 0.5 },
		}),
		build = function(r: R)
			-- A radio host's desk: panels at the ends, a front panel in the station's colour with
			-- foam on it, a mixing desk with its faders and meters (lit), a microphone on a boom arm
			-- over the host, headphones, two speakers, an on air lamp on a stalk, and a crate of
			-- records under the desk.
			local panel, dark = r.c1, r.c2
			local foam = Color3.fromRGB(70, 72, 80)
			for _, x in { -2.05, 1.95 } do
				r:block(x, 0, -0.1, x + 0.1, 2.6, 1.1, dark, "Wood")
			end
			r:block(-2.1, 2.6, -0.15, 2.1, 2.76, 1.15, shade(dark, 1.2), "Wood")
			r:block(-1.95, 0.3, 1.0, 1.95, 2.6, 1.1, panel, "Wood")
			for i = 0, 5 do
				for j = 0, 2 do
					r:block(
						-1.75 + i * 0.6,
						0.55 + j * 0.68,
						1.1,
						-1.27 + i * 0.6,
						1.07 + j * 0.68,
						1.16,
						foam,
						"Fabric"
					)
				end
			end
			-- the mixing desk: a sloped panel, faders, knobs and the meters
			local deck = CFrame.new(0, 2.88, 0.45) * CFrame.Angles(-0.3, 0, 0)
			r:boxAt(deck, 1.7, 0.2, 0.7, INK, "Metal")
			for i = 0, 7 do
				local x = -0.7 + i * 0.2
				r:boxAt(deck * CFrame.new(x, 0.13, -0.12 + (i % 3) * 0.06), 0.06, 0.06, 0.1, C.White, "Plastic")
				r:boxAt(deck * CFrame.new(x, 0.13, 0.22), 0.07, 0.06, 0.07, STEEL, "Metal")
			end
			r:block(-0.75, 2.76, 0.86, 0.75, 3.32, 1.0, INK, "Metal")
			for i = 0, 5 do
				local lit = r:block(
					-0.62 + i * 0.22,
					3.1,
					0.82,
					-0.46 + i * 0.22,
					3.22,
					0.86,
					if i < 4 then Color3.fromRGB(120, 210, 140) else Color3.fromRGB(240, 170, 90),
					"Neon"
				)
				if i % 2 == 1 then
					Lively.twinkle(lit)
				end
			end
			-- the boom arm from a clamp at the back, the microphone and its screen over the host
			r:block(-1.3, 2.76, -0.12, -1.1, 3.0, 0.08, IRON, "Metal")
			r:noCollide(r:beam(V(-1.2, 3.0, -0.02), V(-0.8, 4.2, -0.1), 0.07, 0.07, IRON, "Metal") :: any)
			r:noCollide(r:beam(V(-0.8, 4.2, -0.1), V(-0.05, 4.32, -0.35), 0.07, 0.07, IRON, "Metal") :: any)
			r:noCollide(r:cyl(0, 4.32, -0.5, 0.36, 0.2, "z", INK, "Metal"))
			r:noCollide(r:ball(0, 4.32, -0.7, 0.24, STEEL, "Metal"))
			r:noCollide(r:cyl(0, 4.32, -0.92, 0.03, 0.42, "z", INK, "Fabric"))
			-- headphones lying on the desk
			for _, x in { 1.05, 1.45 } do
				r:cyl(x, 2.85, 0.35, 0.14, 0.22, "y", INK, "Plastic")
			end
			r:beam(V(1.05, 2.92, 0.35), V(1.45, 2.92, 0.35), 0.05, 0.05, dark, "Plastic")
			-- the speakers at either end, their cones in front
			for _, x in { -1.75, 1.75 } do
				r:block(x - 0.25, 2.76, 0.3, x + 0.25, 3.5, 0.75, INK, "Wood")
				r:cyl(x, 3.0, 0.77, 0.04, 0.32, "z", foam, "Fabric")
				r:cyl(x, 3.32, 0.77, 0.04, 0.16, "z", foam, "Fabric")
			end
			-- the on air lamp on its stalk
			r:cyl(1.3, 3.2, 0.95, 0.9, 0.06, "y", IRON, "Metal")
			r:block(1.05, 3.65, 0.85, 1.55, 3.95, 1.05, INK, "Metal")
			Lively.twinkle(r:block(1.1, 3.7, 1.05, 1.5, 3.9, 1.08, Color3.fromRGB(226, 70, 70), "Neon"))
			-- the records in their crate under the desk
			r:block(-1.6, 0, -0.05, -0.7, 0.75, 0.6, OAK, "Wood")
			for i = 0, 6 do
				r:cyl(-1.5 + i * 0.12, 0.6, 0.27, 0.02, 0.56, "x", if i % 3 == 0 then panel else INK, "Plastic")
			end
			Lively.fx(r, "music", 0, 4.7, -0.2, { w = 0.8, d = 0.5, work = true })
		end,
	},
	{
		id = "crate_detective",
		name = "Detective's desk",
		cat = "crates",
		crate = "uncommon",
		price = 0,
		place = "floor",
		job = "detective",
		size = Vector3.new(7, 5.4, 3.6),
		c1 = "7A5038",
		c2 = "3E5A4C",
		tags = { "work", "desk" },
		style = "cozy",
		lively = true,
		workSpot = Vector3.new(-0.1, 0, -1.25),
		workYaw = 0,
		loop = steps({
			{ name = "case notes", stay = { 7, 10 }, act = "point", say = 0.35 },
			{
				name = "board",
				at = V(2.75, 0, 0.8),
				look = V(2.6, 3.4, -0.65),
				stay = { 4, 7 },
				act = "point",
				say = 0.3,
			},
			{ name = "case notes", stay = { 5, 8 }, say = 0.25 },
			{ name = "window", at = V(-0.1, 0, 2.65), look = V(-0.1, 3, 12), stay = { 3, 5 } },
		}),
		build = function(r: R)
			-- A detective's office: a walnut desk with a green leather top, drawers on the detective's
			-- side, a banker's lamp (lit), a magnifying glass, case files and a cold coffee; a cork
			-- board of photos and notes joined by red string; a coat stand with the hat and the coat.
			local wood, leather = r.c1, r.c2
			local cork = Color3.fromRGB(196, 154, 106)
			r:block(-1.6, 2.55, 0, 1.4, 2.7, 1.2, wood, "Wood")
			r:block(-1.45, 2.7, 0.1, 1.25, 2.74, 1.1, leather, "Leather")
			r:block(-1.55, 0, 0.05, -1.35, 2.55, 1.15, wood, "Wood")
			r:block(0.55, 0, 0.05, 1.35, 2.55, 1.15, shade(wood, 0.92), "Wood")
			for j = 0, 2 do
				r:block(0.6, 0.2 + j * 0.78, 0.02, 1.3, 0.88 + j * 0.78, 0.05, shade(wood, 1.08), "Wood")
				r:block(0.88, 0.5 + j * 0.78, -0.01, 1.02, 0.58 + j * 0.78, 0.02, BRASS, "Metal")
			end
			r:block(-1.35, 1.2, 1.05, 0.55, 2.55, 1.1, shade(wood, 0.85), "Wood")
			-- the lamp: a brass foot and stem, a green shade, lit
			r:cyl(-1.05, 2.78, 0.75, 0.06, 0.34, "y", BRASS, "Metal")
			r:cyl(-1.05, 3.05, 0.75, 0.5, 0.05, "y", BRASS, "Metal")
			r:cyl(-1.05, 3.34, 0.7, 0.62, 0.24, "x", Color3.fromRGB(70, 130, 96), "Glass")
			r:glow(r:cyl(-1.05, 3.24, 0.7, 0.5, 0.08, "x", Color3.fromRGB(255, 226, 170), "Neon"), 10, 0.7)
			-- the files, the magnifying glass and the coffee
			for k = 0, 2 do
				sheet(r, 0.1, 2.74 + k * 0.05, 0.55, 0.62, 0.44, 0.1 - k * 0.12, Color3.fromRGB(222, 196, 140))
			end
			sheet(r, 0.0, 2.89, 0.5, 0.36, 0.3, 0.3, PAPER)
			r:cyl(0.75, 2.79, 0.35, 0.03, 0.34, "y", BRASS, "Metal")
			local lens = r:cyl(0.75, 2.83, 0.35, 0.02, 0.28, "y", Color3.fromRGB(206, 232, 240), "Glass")
			lens.transp = 0.4
			r:beam(V(0.89, 2.79, 0.42), V(1.15, 2.79, 0.55), 0.06, 0.05, WALNUT, "Wood")
			mug(r, 0.95, 2.74, 0.85, PAPER)
			-- the cork board on its legs, to the right
			for _, x in { 1.95, 3.25 } do
				r:block(x - 0.06, 0, -0.71, x + 0.06, 4.8, -0.59, WALNUT, "Wood")
			end
			r:block(1.9, 2.3, -0.75, 3.3, 4.6, -0.7, WALNUT, "Wood")
			r:block(2.03, 2.4, -0.7, 3.17, 4.5, -0.66, cork, "Fabric")
			local notes: { { any } } = {
				{ 2.2, 4.2, PAPER },
				{ 2.75, 4.1, Color3.fromRGB(236, 206, 120) },
				{ 3.0, 3.5, PAPER },
				{ 2.3, 3.3, Color3.fromRGB(170, 200, 220) },
				{ 2.7, 2.8, PAPER },
			}
			for i, n in notes do
				r:boxAt(
					CFrame.new(n[1], n[2], -0.64) * CFrame.Angles(0, 0, (i % 3 - 1) * 0.12),
					0.34,
					0.4,
					0.03,
					n[3],
					"Fabric"
				)
				r:ball(n[1], n[2] + 0.14, -0.62, 0.06, Color3.fromRGB(200, 70, 70), "Plastic")
			end
			for i = 1, #notes - 1 do
				local a, b = notes[i], notes[i + 1]
				r:beam(
					V(a[1], a[2] + 0.14, -0.6),
					V(b[1], b[2] + 0.14, -0.6),
					0.025,
					0.025,
					Color3.fromRGB(196, 60, 64),
					"Fabric"
				)
			end
			-- the coat stand: a pole on three feet, the coat and the hat on its hooks
			r:cyl(-2.6, 2.2, -0.6, 4.4, 0.1, "y", WALNUT, "Wood")
			for k = 0, 2 do
				local a = k * math.pi * 2 / 3
				r:beam(
					V(-2.6, 0.3, -0.6),
					V(-2.6 + math.cos(a) * 0.4, 0.02, -0.6 + math.sin(a) * 0.4),
					0.06,
					0.06,
					WALNUT,
					"Wood"
				)
			end
			r:lump(CFrame.new(-2.6, 3.3, -0.42), 0.6, 1.8, 0.32, Color3.fromRGB(176, 150, 112), "Fabric")
			r:cyl(-2.6, 4.46, -0.6, 0.04, 0.62, "y", Color3.fromRGB(110, 96, 84), "Fabric")
			r:cyl(-2.6, 4.6, -0.6, 0.26, 0.36, "y", Color3.fromRGB(110, 96, 84), "Fabric")
			Lively.fx(r, "paper", -0.1, 3.4, 0.55, { w = 0.6, d = 0.4, work = true })
		end,
	},
	{
		id = "crate_tester",
		name = "Game test desk",
		cat = "crates",
		crate = "uncommon",
		price = 0,
		place = "floor",
		job = "tester",
		size = Vector3.new(6, 4.8, 3.6),
		c1 = "3C4250",
		c2 = "6AC0D8",
		tags = { "work", "games", "desk" },
		style = "scifi",
		lively = true,
		workSpot = Vector3.new(0, 0, -1.2),
		workYaw = 0,
		loop = steps({
			{ name = "play", stay = { 7, 11 }, act = "point", beat = 2.5, say = 0.3 },
			{ name = "shelf", at = V(2.45, 0, -1.7), look = V(2.45, 2.5, 0), stay = { 3, 5 }, act = "point" },
			{ name = "notes", stay = { 4, 6 }, say = 0.35 },
			{ name = "stretch", at = V(-1.6, 0, -1.7), look = V(-1.6, 3, 2), stay = { 3, 4 }, act = "cheer" },
		}),
		build = function(r: R)
			-- A games tester's desk: a dark top on two frames, two screens (lit), a keyboard and a
			-- mouse, a gamepad, cans and a bag of crisps, a tower under the desk with a light strip
			-- running through colours, and a shelf of game boxes at the end.
			local body, light = r.c1, r.c2
			for _, x in { -1.75, 1.65 } do
				r:block(x, 0, 0.05, x + 0.1, 2.5, 1.05, shade(body, 0.8), "Metal")
			end
			r:block(-1.85, 2.5, 0, 1.85, 2.62, 1.1, body, "Wood")
			r:block(-1.85, 2.56, 1.1, 1.85, 2.6, 1.13, light, "Neon")
			screen(
				r,
				CFrame.new(-0.72, 3.4, 0.82) * CFrame.Angles(0, math.pi + 0.22, 0),
				1.3,
				0.8,
				Color3.fromRGB(96, 170, 150),
				0.34
			)
			screen(
				r,
				CFrame.new(0.72, 3.4, 0.82) * CFrame.Angles(0, math.pi - 0.22, 0),
				1.3,
				0.8,
				Color3.fromRGB(110, 150, 200),
				0.34
			)
			-- the keyboard's keys, and the mouse
			r:block(-0.55, 2.62, 0.2, 0.35, 2.68, 0.5, INK, "Plastic")
			r:piece(function(q: R)
				for row = 0, 2 do
					for k = 0, 7 do
						local x = -0.5 + k * 0.105
						q:block(
							x,
							2.68,
							0.24 + row * 0.08,
							x + 0.08,
							2.71,
							0.3 + row * 0.08,
							Color3.fromRGB(96, 98, 108),
							"Plastic"
						)
					end
				end
			end)
			r:lump(CFrame.new(0.65, 2.66, 0.35), 0.14, 0.08, 0.22, INK, "Plastic")
			-- the gamepad: a body, two grips, the sticks and buttons
			r:lump(CFrame.new(-1.2, 2.68, 0.4), 0.46, 0.1, 0.24, Color3.fromRGB(236, 236, 240), "Plastic")
			for _, s in { -1, 1 } do
				r:lump(
					CFrame.new(-1.2 + s * 0.2, 2.67, 0.32) * CFrame.Angles(0, s * 0.4, 0),
					0.16,
					0.1,
					0.24,
					Color3.fromRGB(236, 236, 240),
					"Plastic"
				)
				r:cyl(-1.2 + s * 0.09, 2.74, 0.43, 0.04, 0.07, "y", INK, "Plastic")
			end
			r:ball(-1.06, 2.74, 0.36, 0.05, Color3.fromRGB(230, 96, 96), "Plastic")
			-- two cans and a bag of crisps
			for k, x in { 1.2, 1.38 } do
				r:cyl(
					x,
					2.8,
					0.3 + k * 0.08,
					0.36,
					0.12,
					"y",
					if k == 1 then light else Color3.fromRGB(230, 140, 80),
					"Metal"
				)
			end
			r:lump(
				CFrame.new(1.4, 2.72, 0.75) * CFrame.Angles(0, 0.3, 0.2),
				0.4,
				0.18,
				0.3,
				Color3.fromRGB(236, 196, 90),
				"Plastic"
			)
			-- the tower and its light strip
			r:block(-1.45, 0.05, 0.2, -0.95, 1.4, 0.95, INK, "Metal")
			Lively.twinkle(r:block(-0.95, 0.3, 0.35, -0.92, 1.25, 0.4, light, "Neon"), true)
			-- the shelf of game boxes
			r:block(2.15, 0, -0.35, 2.85, 0.08, 0.35, OAK, "Wood")
			for _, x in { 2.15, 2.77 } do
				r:block(x, 0.08, -0.35, x + 0.08, 3.6, 0.35, OAK, "Wood")
			end
			for j = 1, 3 do
				r:block(2.23, j * 1.12, -0.35, 2.77, j * 1.12 + 0.06, 0.35, OAK, "Wood")
			end
			local box =
				{ light, Color3.fromRGB(230, 120, 110), Color3.fromRGB(240, 204, 100), Color3.fromRGB(150, 120, 200) }
			for j = 0, 2 do
				local y = if j == 0 then 0.08 else j * 1.12 + 0.06
				for k = 0, 3 do
					local z = -0.27 + k * 0.15
					r:block(2.28, y, z, 2.72, y + 0.62 + (k % 2) * 0.06, z + 0.11, box[(j + k) % #box + 1], "Plastic")
				end
			end
			Lively.fx(r, "glints", 0, 3.6, 0.75, { w = 1.8, h = 0.6, d = 0.2, work = true, color = light })
		end,
	},
	-- Rare ---------------------------------------------------------------------------------------
	{
		id = "crate_inventor",
		name = "Inventor's bench",
		cat = "crates",
		crate = "rare",
		price = 0,
		place = "floor",
		job = "inventor",
		size = Vector3.new(6.4, 6.4, 3.6),
		c1 = "B07A4E",
		c2 = "5E8C9A",
		tags = { "work" },
		style = "scifi",
		lively = true,
		workSpot = Vector3.new(0, 0, 1.75),
		workYaw = 180,
		loop = steps({
			{ name = "tinker", stay = { 6, 9 }, act = "toolslash", beat = 2.4, say = 0.3 },
			{ name = "coil", at = V(3.15, 0, 1.8), look = V(2.9, 3.5, 0), stay = { 3, 5 }, act = "point" },
			{ name = "tinker", stay = { 5, 8 }, act = "toolslash", beat = 2.4 },
			{
				name = "beakers",
				at = V(-1.9, 0, 2.0),
				look = V(-1.9, 3.4, 0),
				stay = { 4, 6 },
				act = "point",
				beat = 3,
			},
			{ name = "step back", at = V(0.4, 0, 3.4), look = V(0, 3, 0), stay = { 3, 4 }, icon = "idea" },
		}),
		build = function(r: R)
			-- An inventor's bench: a thick top on iron legs, a pegboard of tools behind with a big gear
			-- turning on it, a robot arm bolted to the bench, a clock taken apart, beakers of glowing
			-- liquid in a rack, a blueprint laid flat and two rolled, and a coil tower at the end
			-- that throws sparks while they work.
			local wood, machine = r.c1, r.c2
			for _, x in { -2.3, 2.3 } do
				for _, z in { -0.5, 0.5 } do
					r:block(x - 0.1, 0, z - 0.1, x + 0.1, 2.9, z + 0.1, IRON, "Metal")
				end
				r:block(x - 0.06, 0.5, -0.4, x + 0.06, 0.66, 0.4, IRON, "Metal")
			end
			r:block(-2.4, 0.5, -0.06, 2.4, 0.66, 0.06, IRON, "Metal")
			r:block(-2.45, 2.9, -0.65, 2.45, 3.1, 0.65, wood, "Wood")
			-- the pegboard and its tools
			for _, x in { -2.4, 2.4 } do
				r:block(x - 0.08, 3.1, -0.78, x + 0.08, 5.6, -0.66, IRON, "Metal")
			end
			r:block(-2.32, 3.6, -0.8, 2.32, 5.5, -0.74, Color3.fromRGB(196, 170, 130), "Wood")
			r:piece(function(q: R)
				for i = 0, 7 do
					for j = 0, 2 do
						q:block(
							-2.1 + i * 0.6,
							3.8 + j * 0.45,
							-0.74,
							-2.04 + i * 0.6,
							3.86 + j * 0.45,
							-0.7,
							IRON,
							"Metal"
						)
					end
				end
				q:block(0.6, 4.0, -0.73, 0.7, 4.9, -0.69, Color3.fromRGB(196, 124, 92), "Metal")
				q:block(0.45, 4.85, -0.73, 0.85, 5.0, -0.69, IRON, "Metal")
				q:block(1.4, 4.1, -0.73, 1.48, 5.0, -0.69, STEEL, "Metal")
				q:block(1.3, 4.95, -0.73, 1.58, 5.08, -0.69, STEEL, "Metal")
			end)
			-- the big gear turning on the pegboard
			Lively.pivot(r, CFrame.new(-1.4, 4.6, -0.66), "spin", { speed = 0.6, axis = "Z" })
			Lively.moving(r, 1, function()
				r:cyl(-1.4, 4.6, -0.66, 0.08, 0.8, "z", BRASS, "Metal")
				for k = 0, 9 do
					local a = k * math.pi / 5
					r:boxAt(
						CFrame.new(-1.4, 4.6, -0.66) * CFrame.Angles(0, 0, a) * CFrame.new(0, 0.44, 0),
						0.12,
						0.14,
						0.08,
						BRASS,
						"Metal"
					)
				end
				r:cyl(-1.4, 4.6, -0.6, 0.06, 0.16, "z", IRON, "Metal")
			end)
			-- the robot arm: its base, two arms and a gripper
			r:cyl(-0.4, 3.18, -0.2, 0.16, 0.5, "y", machine, "Metal")
			r:beam(V(-0.4, 3.26, -0.2), V(-0.2, 4.0, 0.0), 0.14, 0.14, machine, "Metal")
			r:ball(-0.2, 4.0, 0.0, 0.2, IRON, "Metal")
			r:beam(V(-0.2, 4.0, 0.0), V(0.3, 3.6, 0.25), 0.12, 0.12, machine, "Metal")
			for _, s in { -1, 1 } do
				r:boxAt(
					CFrame.new(0.32 + s * 0.06, 3.46, 0.27) * CFrame.Angles(0, 0, s * 0.3),
					0.04,
					0.2,
					0.06,
					STEEL,
					"Metal"
				)
			end
			-- the clock taken apart: its case, face and loose gears
			r:cyl(0.9, 3.13, 0.2, 0.06, 0.6, "y", BRASS, "Metal")
			r:cyl(0.9, 3.18, 0.2, 0.02, 0.5, "y", CREAM, "Plastic")
			for k, g in { { 1.4, 0.35, 0.22 }, { 1.25, 0.05, 0.14 }, { 0.6, -0.45, 0.16 } } do
				r:cyl(g[1], 3.13, g[2], 0.04, g[3], "y", if k == 2 then STEEL else BRASS, "Metal")
			end
			-- the beakers in their rack, glowing
			r:block(-2.2, 3.1, -0.3, -1.3, 3.2, 0.3, IRON, "Metal")
			for k, col in
				{ Color3.fromRGB(140, 230, 160), Color3.fromRGB(240, 200, 110), Color3.fromRGB(150, 190, 250) }
			do
				local x = -2.05 + (k - 1) * 0.3
				local glass = r:cyl(x, 3.5, 0, 0.6, 0.2, "y", Color3.fromRGB(220, 236, 240), "Glass")
				glass.transp = 0.5
				local liquid = r:cyl(x, 3.38, 0, 0.32, 0.14, "y", col, "Neon")
				if k ~= 2 then
					Lively.twinkle(liquid)
				end
			end
			-- the blueprints
			sheet(r, 0.2, 3.1, 0.35, 1.0, 0.5, 0.05, Color3.fromRGB(110, 150, 196))
			for _, x in { 1.8, 2.05 } do
				r:cyl(x, 3.18, -0.35, 0.9, 0.14, "z", Color3.fromRGB(150, 186, 220), "Fabric")
			end
			-- the coil tower: a base, a wound column, the ring on top
			r:block(2.65, 0, -0.3, 3.15, 0.5, 0.3, IRON, "Metal")
			r:cyl(2.9, 2.5, 0, 3.9, 0.36, "y", Color3.fromRGB(196, 120, 80), "Metal")
			for k = 0, 8 do
				r:cyl(2.9, 0.8 + k * 0.4, 0, 0.06, 0.42, "y", BRASS, "Metal")
			end
			r:cyl(2.9, 4.55, 0, 0.2, 0.6, "y", STEEL, "Metal")
			r:ball(2.9, 4.8, 0, 0.36, STEEL, "Metal")
			Lively.fx(r, "sparks", 2.9, 5.1, 0, { w = 0.5, d = 0.5, work = true })
		end,
	},
	{
		id = "crate_stargazer",
		name = "Star telescope",
		cat = "crates",
		crate = "rare",
		price = 0,
		place = "floor",
		job = "stargazer",
		size = Vector3.new(5.2, 5.6, 4.4),
		c1 = "3E4A78",
		c2 = "C9A464",
		tags = { "work" },
		style = "fancy",
		lively = true,
		workSpot = Vector3.new(0, 0, 1.9),
		workYaw = 180,
		loop = steps({
			{ name = "look", stay = { 8, 12 }, act = "point", say = 0.3 },
			{ name = "chart", at = V(-1.9, 0, 1.8), look = V(-1.9, 3, 0), stay = { 4, 6 }, act = "point", beat = 4 },
			{ name = "look", stay = { 6, 9 } },
			{
				name = "sky",
				at = V(1.6, 0, 2.2),
				look = V(1.6, 9, -2),
				stay = { 3, 5 },
				act = "cheer",
				icon = "sparkle",
			},
		}),
		build = function(r: R)
			-- A big brass telescope on a wooden tripod, tilted up at the sky with its eyepiece and
			-- finder, on a round rug of stars, a little desk of star charts with a celestial globe
			-- turning on it, and a basket of rolled maps.
			local navy, brass = r.c1, r.c2
			local wood = Color3.fromRGB(122, 86, 62)
			r:cyl(0, 0.03, 0, 0.06, 4.2, "y", navy, "Fabric")
			for k = 0, 6 do
				local a = k * math.pi * 2 / 7
				r:boxAt(
					CFrame.new(math.cos(a) * 1.4, 0.075, math.sin(a) * 1.4) * CFrame.Angles(0, a, 0),
					0.16,
					0.04,
					0.16,
					brass,
					"Fabric"
				)
			end
			-- the tripod
			local apex = V(0, 3.2, 0)
			for _, foot in { V(-0.9, 0, 0.5), V(0.9, 0, 0.5), V(0, 0, -1.0) } do
				r:beam(apex, foot, 0.12, 0.12, wood, "Wood")
				r:cyl(foot.X, 0.1, foot.Z, 0.2, 0.18, "y", brass, "Metal")
			end
			r:cyl(0, 3.3, 0, 0.3, 0.42, "y", brass, "Metal")
			r:block(-0.16, 3.45, -0.16, 0.16, 3.8, 0.16, IRON, "Metal")
			-- the tube, its rings, the finder and the eyepiece (high up: never in the way)
			local dir = V(0, math.sin(math.rad(35)), -math.cos(math.rad(35)))
			local mid = V(0, 4.15, -0.25)
			local tube = CFrame.lookAt(mid, mid + dir)
			r:noCollide(r:cyl(0, 0, 0, 3.0, 0.5, "z", navy, "Metal"))
			local last = r.prims[#r.prims]
			last.cf = tube * CFrame.Angles(0, math.pi / 2, 0)
			for _, at in { -1.4, -0.4, 0.6, 1.38 } do
				local ring = r:noCollide(r:cyl(0, 0, 0, 0.1, 0.56, "z", brass, "Metal"))
				ring.cf = tube * CFrame.new(0, 0, at) * CFrame.Angles(0, math.pi / 2, 0)
			end
			local finder = r:noCollide(r:cyl(0, 0, 0, 0.9, 0.14, "z", brass, "Metal"))
			finder.cf = tube * CFrame.new(0.24, 0.24, -0.2) * CFrame.Angles(0, math.pi / 2, 0)
			local eye = r:noCollide(r:cyl(0, 0, 0, 0.3, 0.14, "z", INK, "Metal"))
			eye.cf = tube
				* CFrame.new(0, 0.2, 1.4)
				* CFrame.Angles(math.rad(-50), 0, 0)
				* CFrame.Angles(0, math.pi / 2, 0)
			-- the chart desk, its globe turning
			tableLegs(r, -2.4, -0.6, -1.4, 0.4, 2.4, 0.12, wood)
			r:block(-2.45, 2.4, -0.65, -1.35, 2.52, 0.45, wood, "Wood")
			sheet(r, -1.9, 2.52, 0.1, 0.8, 0.5, 0.1, Color3.fromRGB(40, 50, 86))
			for k = 0, 4 do
				r:ball(-2.1 + k * 0.1, 2.58, 0.0 + (k % 2) * 0.15, 0.04, Color3.fromRGB(250, 236, 180), "Neon")
			end
			r:cyl(-1.9, 2.6, -0.35, 0.08, 0.3, "y", brass, "Metal")
			r:cyl(-1.9, 2.8, -0.35, 0.32, 0.05, "y", brass, "Metal")
			Lively.pivot(r, CFrame.new(-1.9, 3.15, -0.35), "spin", { speed = 0.4, axis = "Y" })
			Lively.moving(r, 1, function()
				r:ball(-1.9, 3.15, -0.35, 0.56, navy, "Metal")
				for k = 0, 3 do
					local a = k * math.pi / 2
					r:ball(
						-1.9 + math.cos(a) * 0.27,
						3.2 + (k % 2) * 0.12,
						-0.35 + math.sin(a) * 0.27,
						0.06,
						Color3.fromRGB(250, 236, 180),
						"Neon"
					)
				end
			end)
			r:cyl(-1.9, 3.15, -0.35, 0.74, 0.05, "y", brass, "Metal")
			-- the basket of maps
			r:cyl(1.9, 0.45, -0.9, 0.9, 0.7, "y", Color3.fromRGB(196, 160, 110), "Fabric")
			for k = 0, 3 do
				r:cyl(
					1.78 + (k % 2) * 0.24,
					1.15 + k * 0.05,
					-0.98 + math.floor(k / 2) * 0.18,
					0.9,
					0.12,
					"y",
					if k % 2 == 0 then PAPER else Color3.fromRGB(176, 196, 226),
					"Fabric"
				)
			end
			Lively.fx(
				r,
				"sparkles",
				0,
				5.3,
				-1.6,
				{ w = 0.6, d = 0.6, work = true, color = Color3.fromRGB(250, 236, 180) }
			)
		end,
	},
	-- Epic -----------------------------------------------------------------------------------------
	{
		id = "crate_ceo",
		name = "Corner office",
		cat = "crates",
		crate = "epic",
		price = 0,
		place = "floor",
		job = "ceo",
		size = Vector3.new(8, 5.4, 4.4),
		c1 = "5C3A2C",
		c2 = "2E3440",
		tags = { "work", "desk" },
		style = "modern",
		lively = true,
		workSpot = Vector3.new(0.6, 0, -0.95),
		workYaw = 0,
		loop = steps({
			{ name = "calls", stay = { 7, 10 }, act = "point", say = 0.4 },
			{
				name = "chart",
				at = V(3.6, 0, 0.4),
				look = V(3.4, 3.6, -1.3),
				stay = { 4, 6 },
				act = "point",
				beat = 3,
				say = 0.3,
			},
			{ name = "calls", stay = { 5, 8 }, say = 0.3 },
			{ name = "window", at = V(0.6, 0, 3.1), look = V(0.6, 3, 12), stay = { 3, 5 }, act = "wave" },
		}),
		build = function(r: R)
			-- A boss's desk: a deep walnut top with a brass edge on two pedestals and a panelled
			-- front, a laptop (lit), a desk phone, a brass name plate, a pen pot, reports and a
			-- coffee; a high backed leather chair pushed aside, a chart of the year on an easel with
			-- its bars climbing and an arrow up, a globe on a floor stand turning, and a tall plant.
			local wood, leather = r.c1, r.c2
			r:block(-2.2, 2.7, 0.2, 2.2, 2.9, 1.7, wood, "Wood")
			r:block(-2.22, 2.84, 0.17, 2.22, 2.93, 0.22, BRASS, "Metal")
			for _, x in { -2.15, 1.25 } do
				r:block(x, 0, 0.25, x + 0.9, 2.7, 1.65, shade(wood, 0.92), "Wood")
			end
			r:block(-1.25, 0.6, 1.6, 1.25, 2.7, 1.65, shade(wood, 0.85), "Wood")
			for i = 0, 2 do
				r:block(-1.05 + i * 0.75, 0.85, 1.65, -0.45 + i * 0.75, 2.45, 1.68, shade(wood, 0.95), "Wood")
			end
			for _, x in { -2.15, 1.25 } do
				for j = 0, 2 do
					r:block(x + 0.08, 0.2 + j * 0.8, 0.22, x + 0.82, 0.88 + j * 0.8, 0.25, shade(wood, 1.06), "Wood")
					r:block(x + 0.35, 0.5 + j * 0.8, 0.19, x + 0.55, 0.56 + j * 0.8, 0.22, BRASS, "Metal")
				end
			end
			-- the laptop, open toward the boss
			r:block(0.2, 2.9, 0.55, 1.1, 2.95, 1.15, STEEL, "Metal")
			r:boxAt(CFrame.new(0.65, 3.24, 1.2) * CFrame.Angles(-0.25, math.pi, 0), 0.9, 0.6, 0.04, STEEL, "Metal")
			r:boxAt(
				CFrame.new(0.65, 3.24, 1.17) * CFrame.Angles(-0.25, math.pi, 0),
				0.8,
				0.5,
				0.03,
				Color3.fromRGB(120, 170, 210),
				"Neon"
			)
			-- the phone, the name plate, the pens, reports and a coffee
			r:block(-1.5, 2.9, 0.7, -1.0, 3.02, 1.1, INK, "Plastic")
			r:cyl(-1.25, 3.08, 0.82, 0.5, 0.1, "x", INK, "Plastic")
			r:boxAt(CFrame.new(0.65, 2.98, 0.32) * CFrame.Angles(0.5, 0, 0), 0.8, 0.18, 0.05, BRASS, "Metal")
			r:cyl(1.5, 3.05, 1.0, 0.3, 0.2, "y", INK, "Leather")
			for k = 0, 2 do
				r:cyl(1.46 + k * 0.05, 3.25, 1.0, 0.3, 0.03, "y", if k == 1 then BRASS else INK, "Plastic")
			end
			for k = 0, 2 do
				sheet(
					r,
					-0.5,
					2.9 + k * 0.04,
					0.9,
					0.5,
					0.66,
					0.05 * k,
					if k == 2 then PAPER else Color3.fromRGB(206, 214, 226)
				)
			end
			mug(r, -1.7, 2.9, 0.4, Color3.fromRGB(240, 240, 236))
			-- the chair, pushed aside: a seat, a tall back with its buttons, arms, a stem on castors
			local chair = CFrame.new(-1.7, 0, -0.6) * CFrame.Angles(0, 0.5, 0)
			r:boxAt(chair * CFrame.new(0, 1.85, 0), 1.0, 0.3, 0.95, leather, "Leather")
			r:boxAt(chair * CFrame.new(0, 2.04, 0.02), 0.86, 0.1, 0.8, shade(leather, 1.15), "Leather")
			local back = chair * CFrame.new(0, 2.75, -0.46) * CFrame.Angles(-0.12, 0, 0)
			r:boxAt(back, 0.95, 1.5, 0.24, leather, "Leather")
			for k = 0, 2 do
				r:boxAt(back * CFrame.new(0, -0.45 + k * 0.42, 0.15), 0.8, 0.32, 0.06, shade(leather, 1.15), "Leather")
			end
			r:lump(chair * CFrame.new(0, 3.62, -0.56), 0.7, 0.36, 0.26, leather, "Leather")
			for _, s in { -1, 1 } do
				r:boxAt(chair * CFrame.new(s * 0.52, 2.25, 0), 0.12, 0.12, 0.8, INK, "Metal")
			end
			r:boxAt(chair * CFrame.new(0, 1.2, 0), 0.12, 1.1, 0.12, INK, "Metal")
			for k = 0, 4 do
				local a = k * math.pi * 2 / 5
				r:boxAt(chair * CFrame.Angles(0, a, 0) * CFrame.new(0, 0.32, 0.32), 0.1, 0.1, 0.64, INK, "Metal")
				r:ball(
					(chair * CFrame.Angles(0, a, 0) * CFrame.new(0, 0.12, 0.62)).Position.X,
					0.12,
					(chair * CFrame.Angles(0, a, 0) * CFrame.new(0, 0.12, 0.62)).Position.Z,
					0.22,
					INK,
					"Plastic"
				)
			end
			-- the chart on its easel, its bars climbing and the arrow
			for _, x in { 2.95, 3.85 } do
				r:boxAt(CFrame.new(x, 2.1, -1.2) * CFrame.Angles(-0.08, 0, 0), 0.1, 4.2, 0.1, INK, "Metal")
			end
			r:block(2.85, 2.2, -1.4, 3.95, 4.4, -1.32, PAPER, "Fabric")
			local bars = {
				Color3.fromRGB(110, 150, 200),
				Color3.fromRGB(120, 190, 150),
				Color3.fromRGB(240, 196, 100),
				Color3.fromRGB(226, 120, 110),
			}
			for i, col in bars do
				r:block(2.95 + (i - 1) * 0.24, 2.45, -1.32, 3.12 + (i - 1) * 0.24, 2.6 + i * 0.36, -1.28, col, "Fabric")
			end
			r:beam(V(3.0, 3.0, -1.25), V(3.82, 4.1, -1.25), 0.07, 0.03, Color3.fromRGB(196, 70, 70), "Fabric")
			r:boxAt(
				CFrame.new(3.84, 4.13, -1.25) * CFrame.Angles(0, 0, math.rad(-37) + math.pi / 4),
				0.2,
				0.2,
				0.03,
				Color3.fromRGB(196, 70, 70),
				"Fabric"
			)
			-- the globe on its stand, turning
			r:cyl(-3.3, 0.06, 1.4, 0.12, 0.7, "y", WALNUT, "Wood")
			r:cyl(-3.3, 1.2, 1.4, 2.2, 0.1, "y", WALNUT, "Wood")
			Lively.pivot(r, CFrame.new(-3.3, 2.75, 1.4), "spin", { speed = 0.3, axis = "Y" })
			Lively.moving(r, 1, function()
				r:ball(-3.3, 2.75, 1.4, 0.9, Color3.fromRGB(110, 160, 190), "Plastic")
				for k = 0, 2 do
					local a = k * 2.1
					r:lump(
						CFrame.new(-3.3 + math.cos(a) * 0.3, 2.8 + (k - 1) * 0.15, 1.4 + math.sin(a) * 0.3),
						0.36,
						0.3,
						0.36,
						Color3.fromRGB(150, 186, 120),
						"Plastic"
					)
				end
			end)
			r:cyl(-3.3, 2.75, 1.4, 1.1, 0.05, "y", BRASS, "Metal")
			-- the plant in the back corner
			potPlant(r, -3.3, 0, -1.5, 1.6)
			Lively.fx(r, "till", 0.65, 3.6, 1.0, { w = 0.6, d = 0.4, work = true })
		end,
	},
	{
		id = "crate_hero",
		name = "Hero's lookout",
		cat = "crates",
		crate = "epic",
		price = 0,
		place = "floor",
		job = "hero",
		size = Vector3.new(6.4, 6.4, 4.8),
		c1 = "C8484E",
		c2 = "F0C24E",
		tags = { "work" },
		style = "playful",
		lively = true,
		workSpot = Vector3.new(0, 0.6, 0),
		workYaw = 0,
		loop = steps({
			{ name = "watch", stay = { 7, 10 }, act = "point", say = 0.4 },
			{
				name = "light",
				at = V(1.9, 0.6, 0.65),
				look = V(1.9, 1.8, -1.3),
				stay = { 3, 5 },
				act = "point",
				beat = 3,
			},
			{ name = "watch", stay = { 5, 8 }, say = 0.3 },
			{ name = "cape", at = V(-2.0, 0.6, 0.45), look = V(-2.0, 3, -1.2), stay = { 3, 5 }, act = "point" },
			{ name = "pose", stay = { 3, 4 }, act = "cheer", say = 0.6 },
		}),
		build = function(r: R)
			-- A hero's lookout: a concrete deck with a rail round the back and the sides and a step at
			-- the front, a searchlight on a pedestal that swings to and fro, a cape on a stand with its
			-- gold badge, a radio on a crate, and a map of the town pinned to a board.
			local hero, gold = r.c1, r.c2
			local stone = Color3.fromRGB(176, 176, 180)
			r:block(-3.0, 0, -2.3, 3.0, 0.6, 1.5, stone, "Concrete")
			r:block(-3.0, 0, 1.5, 3.0, 0.3, 2.1, shade(stone, 0.92), "Concrete")
			r:block(-3.0, 0.56, 1.5, 3.0, 0.6, 1.56, gold, "Metal")
			-- the rail
			for _, x in { -2.9, -1.45, 0, 1.45, 2.9 } do
				r:cyl(x, 1.1, -2.2, 1.0, 0.1, "y", STEEL, "Metal")
			end
			r:cyl(0, 1.62, -2.2, 5.9, 0.1, "x", STEEL, "Metal")
			for _, x in { -2.9, 2.9 } do
				for _, z in { -1.1, 0.0, 1.1 } do
					r:cyl(x, 1.1, z, 1.0, 0.1, "y", STEEL, "Metal")
				end
				r:cyl(x, 1.62, -0.55, 3.3, 0.1, "z", STEEL, "Metal")
			end
			-- the searchlight: its pedestal, the yoke and the lamp, swinging slowly
			r:cyl(1.9, 1.0, -1.3, 0.8, 0.5, "y", IRON, "Metal")
			Lively.pivot(r, CFrame.new(1.9, 1.5, -1.3), "swing", { speed = 0.35, amount = 0.5, axis = "Y" })
			Lively.moving(r, 1, function()
				for _, s in { -1, 1 } do
					r:block(1.9 + s * 0.5 - 0.05, 1.45, -1.4, 1.9 + s * 0.5 + 0.05, 2.1, -1.2, IRON, "Metal")
				end
				local lamp = CFrame.new(1.9, 2.0, -1.3) * CFrame.Angles(math.rad(25), 0, 0)
				local drum = r:cyl(0, 0, 0, 0.85, 0.85, "z", hero, "Metal")
				drum.cf = lamp * CFrame.Angles(0, math.pi / 2, 0)
				local rim = r:cyl(0, 0, 0, 0.08, 0.96, "z", STEEL, "Metal")
				rim.cf = lamp * CFrame.new(0, 0, 0.44) * CFrame.Angles(0, math.pi / 2, 0)
				local lens = r:cyl(0, 0, 0, 0.03, 0.72, "z", Color3.fromRGB(255, 236, 170), "Neon")
				lens.cf = lamp * CFrame.new(0, 0, 0.495) * CFrame.Angles(0, math.pi / 2, 0)
				for k = 0, 2 do
					local fin = r:cyl(0, 0, 0, 0.05, 0.92, "z", shade(hero, 0.7), "Metal")
					fin.cf = lamp * CFrame.new(0, 0, -0.32 + k * 0.12) * CFrame.Angles(0, math.pi / 2, 0)
				end
				r:boxAt(lamp * CFrame.new(0, 0.5, -0.1), 0.12, 0.16, 0.5, IRON, "Metal")
			end)
			-- the cape on its stand, the badge on its back
			r:cyl(-2.0, 0.66, -1.2, 0.12, 0.6, "y", IRON, "Metal")
			r:cyl(-2.0, 2.0, -1.2, 2.7, 0.1, "y", IRON, "Metal")
			r:block(-2.45, 3.3, -1.32, -1.55, 3.5, -1.08, IRON, "Metal")
			r:boxAt(CFrame.new(-2.0, 2.4, -1.26) * CFrame.Angles(0.06, 0, 0), 1.0, 2.0, 0.08, hero, "Fabric")
			for _, s in { -1, 1 } do
				r:boxAt(
					CFrame.new(-2.0 + s * 0.55, 2.3, -1.24) * CFrame.Angles(0.06, 0, s * 0.12),
					0.24,
					1.8,
					0.08,
					shade(hero, 0.85),
					"Fabric"
				)
			end
			r:cyl(-2.0, 2.9, -1.33, 0.04, 0.4, "z", gold, "Metal")
			r:boxAt(CFrame.new(-2.0, 2.9, -1.36) * CFrame.Angles(0, 0, math.pi / 4), 0.2, 0.2, 0.03, hero, "Metal")
			-- the radio on its crate
			r:block(2.2, 0.6, 0.6, 2.8, 1.3, 1.2, OAK, "Wood")
			r:block(2.3, 1.3, 0.75, 2.7, 1.55, 1.05, INK, "Metal")
			r:noCollide(r:cyl(2.62, 1.85, 0.8, 0.6, 0.03, "y", STEEL, "Metal"))
			Lively.twinkle(r:ball(2.4, 1.48, 1.07, 0.06, Color3.fromRGB(240, 90, 90), "Neon"))
			-- the map of the town on its board, by the rail
			r:block(-0.9, 0.6, -2.08, -0.82, 3.0, -2.0, OAK, "Wood")
			r:block(0.82, 0.6, -2.08, 0.9, 3.0, -2.0, OAK, "Wood")
			r:block(-0.95, 2.0, -2.12, 0.95, 3.1, -2.06, OAK, "Wood")
			r:block(-0.78, 2.08, -2.06, 0.78, 3.02, -2.02, Color3.fromRGB(226, 220, 196), "Fabric")
			for k, b in { { -0.4, 2.7, 0.5, 0.06 }, { 0.2, 2.5, 0.06, 0.6 }, { 0.3, 2.3, 0.7, 0.06 } } do
				r:block(
					b[1] - b[3] / 2,
					b[2] - b[4] / 2,
					-2.02,
					b[1] + b[3] / 2,
					b[2] + b[4] / 2,
					-1.99,
					if k == 2 then Color3.fromRGB(140, 180, 210) else Color3.fromRGB(150, 140, 126),
					"Fabric"
				)
			end
			r:ball(0.25, 2.45, -1.98, 0.08, hero, "Plastic")
			Lively.fx(
				r,
				"rays",
				1.9,
				2.3,
				-0.7,
				{ w = 0.8, d = 0.4, work = true, color = Color3.fromRGB(255, 236, 170) }
			)
		end,
	},
	-- Legendary -------------------------------------------------------------------------------------
	{
		id = "crate_keeper",
		name = "Containment tank",
		cat = "crates",
		crate = "legendary",
		price = 0,
		place = "floor",
		job = "keeper",
		size = Vector3.new(7, 5.6, 4.8),
		c1 = "D7DDE2",
		c2 = "4FB8A8",
		tags = { "work" },
		style = "scifi",
		lively = true,
		workSpot = Vector3.new(-2.3, 0, 1.9),
		workYaw = 180,
		loop = steps({
			{ name = "readings", stay = { 7, 10 }, act = "point", beat = 3.5, say = 0.3 },
			{
				name = "tank",
				at = V(0.1, 0, 1.3),
				look = V(0, 2.4, -1.2),
				stay = { 4, 7 },
				act = "point",
				icon = "question",
				say = 0.3,
			},
			{ name = "readings", stay = { 5, 8 } },
			{ name = "lamp", at = V(2.6, 0, 0.15), look = V(2.6, 3, -1.6), stay = { 3, 4 } },
		}),
		build = function(r: R)
			-- A containment tank and its desk: a floor plate with hazard stripes, a tall glass tank on a
			-- heavy base with a cap, pipes and bolts, and in it the thing nobody can name, glowing and
			-- floating, two rings turning round it; a console of screens and switches with the big
			-- button, a warning lamp turning on a pole, and a yellow sign that says keep back.
			local panel, glow = r.c1, r.c2
			local dark = Color3.fromRGB(70, 76, 86)
			local yellow = Color3.fromRGB(236, 196, 80)
			r:block(-3.4, 0, -2.35, 3.4, 0.12, 2.35, Color3.fromRGB(150, 154, 160), "Metal")
			-- the tank: base, glass, cap, the stripes round its base
			r:cyl(0, 0.47, -1.2, 0.7, 2.2, "y", dark, "Metal")
			for k = 0, 11 do
				local a = k * math.pi / 6
				r:boxAt(
					CFrame.new(math.cos(a) * 1.11, 0.47, -1.2 + math.sin(a) * 1.11) * CFrame.Angles(0, -a, 0),
					0.04,
					0.5,
					0.44,
					if k % 2 == 0 then yellow else Color3.fromRGB(52, 52, 58),
					"Metal"
				)
			end
			local tank = r:cyl(0, 2.42, -1.2, 3.2, 1.9, "y", Color3.fromRGB(190, 230, 232), "Glass")
			tank.transp = 0.65
			r:cyl(0, 4.27, -1.2, 0.5, 2.2, "y", panel, "Metal")
			r:cyl(0, 4.6, -1.2, 0.16, 1.2, "y", dark, "Metal")
			for k = 0, 7 do
				local a = k * math.pi / 4
				r:ball(math.cos(a) * 1.0, 4.04, -1.2 + math.sin(a) * 1.0, 0.1, STEEL, "Metal")
			end
			for _, s in { -1, 1 } do
				r:cyl(s * 1.25, 4.3, -1.2, 0.5, 0.18, "x", STEEL, "Metal")
				r:cyl(s * 1.48, 2.2, -1.2, 4.2, 0.18, "y", STEEL, "Metal")
			end
			-- the thing in the tank, and its rings
			Lively.pivot(r, CFrame.new(0, 2.4, -1.2), "bob", { speed = 0.8, amount = 0.25, axis = "Y" })
			Lively.moving(r, 1, function()
				r:lump(CFrame.new(0, 2.4, -1.2) * CFrame.Angles(0.5, 0.3, 0.7), 0.7, 0.7, 0.7, glow, "Neon")
				r:lump(
					CFrame.new(0.05, 2.45, -1.15) * CFrame.Angles(0.2, 0.9, 0.1),
					0.5,
					0.62,
					0.5,
					shade(glow, 1.2),
					"Neon"
				)
			end)
			Lively.pivot(
				r,
				CFrame.new(0, 2.4, -1.2) * CFrame.Angles(0.4, 0, 0),
				"spin",
				{ speed = 1.2, axis = "Y", group = 2 }
			)
			Lively.moving(r, 2, function()
				for k = 0, 9 do
					local a = k * math.pi / 5
					r:boxAt(
						CFrame.new(0, 2.4, -1.2)
							* CFrame.Angles(0.4, 0, 0)
							* CFrame.Angles(0, a, 0)
							* CFrame.new(0, 0, 0.62),
						0.32,
						0.04,
						0.06,
						Color3.fromRGB(220, 250, 244),
						"Neon"
					)
				end
			end)
			-- the console: a sloped desk on a cabinet, its screens, switches and the big button
			r:block(-3.3, 0.12, -0.4, -1.3, 2.4, 0.4, panel, "Metal")
			r:boxAt(CFrame.new(-2.3, 2.55, 0.25) * CFrame.Angles(-0.35, 0, 0), 2.08, 0.3, 0.9, dark, "Metal")
			for _, x in { -2.85, -1.75 } do
				screen(r, CFrame.new(x, 3.02, -0.3), 0.95, 0.65, Color3.fromRGB(100, 200, 180), 0.25)
			end
			for i = 0, 5 do
				local lit = r:boxAt(
					CFrame.new(-2.9 + i * 0.22, 2.72, 0.45) * CFrame.Angles(-0.35, 0, 0),
					0.1,
					0.05,
					0.1,
					if i % 2 == 0 then glow else yellow,
					"Neon"
				)
				if i % 3 == 0 then
					Lively.twinkle(lit)
				end
			end
			r:cyl(-1.75, 2.78, 0.4, 0.12, 0.34, "y", dark, "Metal")
			r:cyl(-1.75, 2.88, 0.4, 0.1, 0.26, "y", Color3.fromRGB(220, 70, 70), "Plastic")
			-- the warning lamp on its pole, turning
			r:cyl(2.6, 1.6, -1.6, 3.0, 0.14, "y", dark, "Metal")
			r:cyl(2.6, 3.15, -1.6, 0.12, 0.44, "y", dark, "Metal")
			local dome = r:cyl(2.6, 3.42, -1.6, 0.42, 0.4, "y", Color3.fromRGB(250, 170, 90), "Glass")
			dome.transp = 0.3
			Lively.pivot(r, CFrame.new(2.6, 3.42, -1.6), "spin", { speed = 3, axis = "Y", group = 3 })
			Lively.moving(r, 3, function()
				r:block(2.42, 3.32, -1.63, 2.78, 3.52, -1.57, Color3.fromRGB(255, 150, 70), "Neon")
			end)
			-- the keep back sign on its post
			r:cyl(3.1, 0.9, 2.0, 1.6, 0.08, "y", dark, "Metal")
			r:boxAt(CFrame.new(3.1, 1.9, 2.06) * CFrame.Angles(0, 0, math.pi / 4), 0.6, 0.6, 0.04, yellow, "Metal")
			r:block(3.06, 1.78, 2.08, 3.14, 2.06, 2.11, Color3.fromRGB(52, 52, 58), "Metal")
			r:block(3.06, 1.68, 2.08, 3.14, 1.74, 2.11, Color3.fromRGB(52, 52, 58), "Metal")
			Lively.fx(r, "tankbubbles", 0, 1.2, -1.2, { w = 1.2, h = 0.2, d = 1.2, work = true })
		end,
	},
}

return items
