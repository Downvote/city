--!strict
-- What the things in a player's bag (Data/Items) look like in the world: the little model in a
-- player's hand while they hold one (Services/Bag, BagUse "hold") and the one lying on the
-- ground after a drop. The user: "check the models for handheld items. make them look more
-- detailed and more recognizable for the things they are. also, some of them are held wrongly,
-- such as the flowers being held upside down".
--
-- Every thing has a model of its own, made of the parts the real one has: a tulip is a stem, two
-- leaves and a cup of petals; a cup of tea stands on a saucer with its handle and its spoon; a book
-- has its boards, its pages and its spine. Made things are drawn `smooth` (Roblox's own round
-- shapes); what grows keeps the low poly kit's facets. Nothing is flat plastic, and leaves and
-- petals are Fabric, never Grass (the seasons recolour Grass). They are drawn as plain parts,
-- never merged pieces (Services/Bag welds every part to the hand at once), at most
-- Tuning.Carry.Parts of them.
--
-- A model is drawn in the hand's own space, the grip at the origin: +Y up and +Z out in front of
-- the player, so a thing's front faces whoever looks at them. That is the space of a Roblox tool:
-- the hand's RightGripAttachment turned to face forward (ThingModels.inHand). With the arm held
-- out as for a tool (client World/Carry plays the body's own `toolnone` animation while
-- `Holding` is set) the fist sits round the origin, about x -0.5..0.5, y -0.5..0.5 and z -0.3..0
-- on a blocky R15 hand (ThingModels.Fist), and a thing is held one of three ways:
--   by a stem or a handle  through the fist at z = IN (flowers, herbs, the skewer, a cone)
--   in the hand            in front of the fist, its lower half behind the fingers (a glass, a jar,
--                          a book, a letter, a chocolate bar)
--   on the hand            standing on the top of the fist, y = ON (plates, bowls, the tea, an
--                          apple, the music box); `on` lifts these to the top of a smaller hand
-- `lie` is how it lies once dropped: "stand" keeps it upright (a cup, a bowl), "flat" lays it on
-- its back with its front to the sky (a book, a letter, a flower with its stem along the ground).
-- ThingModels.lying turns it and sets it on the ground.
--
-- Flower heads are prims named `Bloom` (the ThingModels spec checks they are over the hand when
-- held).

local Geometry = require(script.Parent.Parent.Build.Geometry)
local Recipe = require(script.Parent.Parent.Build.Recipe)

type Prim = Geometry.Prim
type R = Recipe.Recipe

export type Thing = {
	id: string,
	prims: { Prim }, -- in the hand's space, the grip at the origin
	lie: CFrame, -- from a spot on the ground (y = 0 the ground, +Z its front) to the thing's space
	on: boolean, -- it stands on the top of the fist
}

local ThingModels = {}

local ON = 0.5 -- the top of the fist: what is carried on the hand stands here
local IN = -0.12 -- through the middle of the fist: a stem or a handle runs here
local BACK = -0.12 -- the middle of what stands on the fist, front to back

-- The fist on a blocky R15 hand in the hand's space, for the previews and the specs: its middle
-- and size.
ThingModels.Fist = { at = Vector3.new(0, 0, -0.15), size = Vector3.new(1, 1, 0.3) }

-- The arm as Roblox's own `toolnone` animation holds it, near enough, in Data/Moves' degrees: the
-- upper arm a little forward, the forearm out in front. Only the previews and the specs use it.
ThingModels.CarryPose = { RightShoulder = { 15, 0, 0 }, RightElbow = { 75, 0, 0 } }

-- Colours ----------------------------------------------------------------------------------------

local function rgb(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end

local function shade(c: Color3, k: number): Color3
	return Color3.new(math.clamp(c.R * k, 0, 1), math.clamp(c.G * k, 0, 1), math.clamp(c.B * k, 0, 1))
end

local function hex(s: string): Color3
	local r = tonumber(s:sub(1, 2), 16) or 255
	local g = tonumber(s:sub(3, 4), 16) or 255
	local b = tonumber(s:sub(5, 6), 16) or 255
	return Color3.fromRGB(r, g, b)
end

local STEM = rgb(92, 140, 70)
local LEAF = rgb(110, 166, 88)
local DEEP_LEAF = rgb(76, 128, 70)
local WHITE = rgb(246, 244, 238)
local CHINA = rgb(242, 240, 233)
local PAPER = rgb(248, 244, 232)
local KRAFT = rgb(214, 186, 140)
local GOLD = rgb(220, 178, 76)
local SILVER = rgb(196, 200, 208)
local DARK_WOOD = rgb(116, 82, 56)
local CRUST = rgb(208, 150, 82)
local DOUGH = rgb(228, 178, 104)
local CREAM = rgb(246, 236, 210)
local HONEY = rgb(226, 150, 40)
local RED = rgb(214, 70, 72)

-- Shapes -------------------------------------------------------------------------------------------

local function smooth(p: Prim): Prim
	p.smooth = true
	return p
end

-- A cylinder from `a` to `b`, `d` across.
local function rod(r: R, a: Vector3, b: Vector3, d: number, color: Color3, mat: string, round: boolean?): Prim
	local mid = (a + b) / 2
	local up = if math.abs((b - a).Unit.Y) > 0.99 then Vector3.zAxis else Vector3.yAxis
	local p = r:add({
		shape = "Cylinder",
		cf = CFrame.lookAt(mid, b, up) * CFrame.Angles(0, math.pi / 2, 0),
		size = Vector3.new((b - a).Magnitude, d, d),
		color = color,
		mat = mat,
	})
	if round then
		smooth(p)
	end
	return p
end

-- An upright round slab: a plate, a saucer, a pancake, the layers of a bowl (`h` tall, `d` across,
-- its bottom at y).
local function slab(r: R, x: number, y: number, z: number, h: number, d: number, color: Color3, mat: string): Prim
	return smooth(r:cyl(x, y + h / 2, z, h, d, "y", color, mat))
end

-- A round disc facing +Z (a coin, a sun on a drawing), its back at z.
local function face(r: R, x: number, y: number, z: number, t: number, d: number, color: Color3, mat: string): Prim
	return smooth(r:cyl(x, y, z + t / 2, t, d, "z", color, mat))
end

-- A cone pointing down, its point at `tip`.
local function downCone(r: R, x: number, tip: number, z: number, h: number, d: number, color: Color3, mat: string): Prim
	return r:add({
		shape = "Cone",
		cf = CFrame.new(x, tip + h / 2, z) * CFrame.Angles(math.pi, 0, 0),
		size = Vector3.new(d, h, d),
		color = color,
		mat = mat,
	})
end

-- A stem from y1 to y2.
local function stem(r: R, x: number, y1: number, y2: number, z: number, d: number, color: Color3?): Prim
	return r:cyl(x, (y1 + y2) / 2, z, y2 - y1, d, "y", color or STEM, "Fabric")
end

-- A leaf standing out from a stem at (x, y): `w` wide, `h` long, leaning out by `lean` (radians,
-- to +X when positive) and turned `yaw` about the stem.
local function leaf(
	r: R,
	x: number,
	y: number,
	z: number,
	w: number,
	h: number,
	lean: number,
	yaw: number,
	color: Color3?
)
	local cf = CFrame.new(x, y, z) * CFrame.Angles(0, yaw, 0) * CFrame.Angles(0, 0, -lean) * CFrame.new(0, h / 2, 0)
	r:lump(cf, w, h, 0.05, color or LEAF, "Fabric")
end

-- Flowers ------------------------------------------------------------------------------------------

-- A tulip's head: three petals round the outside and three inside, cupped round a base.
local function tulipHead(r: R, at: CFrame, c: Color3, size: number)
	local s = size
	local base = r:lump(at * CFrame.new(0, -0.14 * s, 0), 0.3 * s, 0.26 * s, 0.3 * s, shade(c, 0.88), "Fabric")
	base.name = "Bloom"
	for k = 0, 2 do
		local a = k * math.pi * 2 / 3
		local outer = at * CFrame.Angles(0, a, 0) * CFrame.new(0, 0.04 * s, 0.09 * s) * CFrame.Angles(0.16, 0, 0)
		r:lump(outer, 0.27 * s, 0.5 * s, 0.11 * s, c, "Fabric")
		local inner = at
			* CFrame.Angles(0, a + math.pi / 3, 0)
			* CFrame.new(0, 0.06 * s, 0.05 * s)
			* CFrame.Angles(0.1, 0, 0)
		r:lump(inner, 0.24 * s, 0.46 * s, 0.1 * s, shade(c, 0.82), "Fabric")
	end
end

local function tulip(r: R, c: Color3)
	stem(r, 0, -0.45, 1.36, IN, 0.09)
	leaf(r, 0.03, 0.42, IN, 0.24, 0.8, 0.3, 0.2)
	leaf(r, -0.03, 0.5, IN, 0.22, 0.72, -0.26, -0.4, DEEP_LEAF)
	tulipHead(r, CFrame.new(0, 1.56, IN), c, 1)
end

-- A daisy's head facing `at`'s +Y: a ring of white petals round a yellow middle.
local function daisyHead(r: R, at: CFrame, size: number, petals: number)
	local s = size
	for k = 0, petals - 1 do
		local a = k * math.pi * 2 / petals
		local cf = at * CFrame.Angles(0, a, 0) * CFrame.new(0, 0, 0.21 * s) * CFrame.Angles(-0.14, 0, 0)
		r:lump(cf, 0.11 * s, 0.035 * s, 0.3 * s, WHITE, "Fabric")
	end
	local mid = r:lump(at * CFrame.new(0, 0.03 * s, 0), 0.2 * s, 0.1 * s, 0.2 * s, rgb(242, 190, 60), "Sand")
	mid.name = "Bloom"
end

local function daisy(r: R, _c: Color3)
	stem(r, 0, -0.4, 1.28, IN, 0.07)
	leaf(r, 0.02, 0.55, IN, 0.16, 0.42, 0.55, 0.3)
	leaf(r, -0.02, 0.78, IN, 0.14, 0.36, -0.6, -0.3, DEEP_LEAF)
	daisyHead(r, CFrame.new(0, 1.36, IN + 0.04) * CFrame.Angles(math.rad(50), 0, 0), 1, 12)
end

local function sunflower(r: R, _c: Color3)
	stem(r, 0, -0.35, 1.6, IN, 0.14, rgb(84, 128, 64))
	-- two broad leaves on the stem, drooping a little
	for i, side in { 1, -1 } do
		local y = if i == 1 then 0.8 else 1.12
		local cf = CFrame.new(side * 0.3, y, IN + 0.02)
			* CFrame.Angles(0, side * 0.3, 0)
			* CFrame.Angles(0, 0, side * -0.35)
		r:lump(cf, 0.56, 0.05, 0.36, if i == 1 then LEAF else DEEP_LEAF, "Fabric")
	end
	-- the head, turned to whoever looks: green behind, a ring of petals, the brown seed disc
	local head = CFrame.new(0, 1.8, IN + 0.08) * CFrame.Angles(math.rad(72), 0, 0)
	local flat = CFrame.Angles(0, 0, math.pi / 2)
	r:add({
		shape = "Cylinder",
		cf = head * CFrame.new(0, -0.05, 0) * flat,
		size = Vector3.new(0.08, 0.56, 0.56),
		color = rgb(90, 134, 66),
		mat = "Fabric",
	})
	for k = 0, 13 do
		local a = k * math.pi * 2 / 14
		local cf = head * CFrame.Angles(0, a, 0) * CFrame.new(0, 0, 0.42) * CFrame.Angles(-0.1, 0, 0)
		r:lump(cf, 0.16, 0.04, 0.36, if k % 2 == 0 then rgb(242, 190, 46) else rgb(236, 172, 40), "Fabric")
	end
	local seeds = r:add({
		shape = "Cylinder",
		cf = head * CFrame.new(0, 0.01, 0) * flat,
		size = Vector3.new(0.08, 0.6, 0.6),
		color = rgb(112, 74, 44),
		mat = "Sand",
	})
	seeds.name = "Bloom"
	r:add({
		shape = "Cylinder",
		cf = head * CFrame.new(0, 0.06, 0) * flat,
		size = Vector3.new(0.04, 0.34, 0.34),
		color = rgb(82, 52, 32),
		mat = "Sand",
	})
end

-- A rose: a full head with a tighter heart.
local function rose(r: R, x: number, y: number, z: number, c: Color3, d: number)
	local head = r:ball(x, y, z, d, c, "Fabric")
	head.name = "Bloom"
	r:ball(x, y + d * 0.32, z, d * 0.55, shade(c, 0.78), "Fabric")
end

local function bouquet(r: R, c: Color3)
	local z = IN + 0.04
	-- the stems' cut ends under the wrap, and the wrap: kraft paper rolled into a cone
	stem(r, 0, -0.52, -0.1, z, 0.14)
	downCone(r, 0, -0.2, z, 1.26, 0.9, rgb(244, 226, 196), "Cardboard")
	-- a ribbon round its neck, tied in a bow at the front
	slab(r, 0, 0.2, z, 0.1, 0.38, c, "Fabric")
	for _, side in { -1, 1 } do
		r:lump(CFrame.new(side * 0.11, 0.25, z + 0.2) * CFrame.Angles(0, 0, side * 0.5), 0.2, 0.13, 0.07, c, "Fabric")
	end
	-- leaves at the paper's mouth, then the flowers over them
	leaf(r, 0.2, 0.96, z - 0.12, 0.2, 0.42, 0.7, 0.4, DEEP_LEAF)
	leaf(r, -0.22, 0.98, z + 0.1, 0.2, 0.4, -0.8, -0.3)
	leaf(r, 0.05, 0.98, z - 0.3, 0.18, 0.38, 0.2, 1.4)
	rose(r, 0, 1.32, z, c, 0.32)
	rose(r, 0.25, 1.2, z + 0.14, rgb(246, 196, 206), 0.28)
	rose(r, -0.14, 1.24, z - 0.22, shade(c, 0.86), 0.28)
	local tulipCup = r:lump(
		CFrame.new(-0.27, 1.24, z + 0.1) * CFrame.Angles(0, 0, 0.25),
		0.2,
		0.3,
		0.2,
		rgb(244, 214, 110),
		"Fabric"
	)
	tulipCup.name = "Bloom"
	daisyHead(r, CFrame.new(0.1, 1.2, z + 0.3) * CFrame.Angles(math.rad(60), 0, 0), 0.7, 0)
	r:lump(CFrame.new(0.1, 1.2, z + 0.3) * CFrame.Angles(math.rad(60), 0, 0), 0.34, 0.04, 0.34, WHITE, "Fabric")
	for k, at in
		{ Vector3.new(0.27, 1.32, z - 0.16), Vector3.new(0.34, 1.12, z - 0.02), Vector3.new(-0.32, 1.08, z - 0.12) }
	do
		r:ball(at.X, at.Y, at.Z, 0.1 + (k % 2) * 0.02, WHITE, "Fabric")
	end
end

local function herbs(r: R, _c: Color3)
	-- four sprigs tied together just over the hand, fanning out, each with pairs of pointed leaves
	-- and one at its tip
	smooth(r:cyl(0, 0.62, IN, 0.08, 0.22, "y", rgb(198, 168, 118), "Fabric"))
	r:cyl(0, 0.2, IN, 0.84, 0.13, "y", STEM, "Fabric") -- the stems' ends, tied together in the hand
	local greens = { rgb(108, 170, 88), rgb(84, 146, 72), rgb(130, 184, 100), rgb(96, 158, 80) }
	for k = 1, 4 do
		local t = (k - 2.5) * 0.2
		local up = 0.72 + (if k == 2 or k == 3 then 0.12 else 0)
		local frame = CFrame.new(0, 0.62, IN) * CFrame.Angles(0, (k - 2.5) * 0.9, 0) * CFrame.Angles(0, 0, -t)
		r:boxAt(frame * CFrame.new(0, up / 2, 0), 0.04, up, 0.04, STEM, "Fabric")
		local green = greens[k]
		local along: { number } = if k == 2 or k == 3 then { 0.32, 0.56 } else { 0.4 }
		for _, d in along do
			for _, side in { -1, 1 } do
				r:lump(
					frame * CFrame.new(0, d, 0) * CFrame.Angles(0, 0, side * 0.9) * CFrame.new(0, 0.12, 0),
					0.13,
					0.26,
					0.03,
					green,
					"Fabric"
				)
			end
		end
		r:lump(frame * CFrame.new(0, up + 0.1, 0), 0.12, 0.26, 0.03, green, "Fabric")
	end
end

-- Drinks ------------------------------------------------------------------------------------------

local function tea(r: R, _c: Color3)
	local z = BACK
	slab(r, 0, ON, z, 0.03, 0.5, CHINA, "Marble") -- the saucer's foot
	slab(r, 0, ON + 0.03, z, 0.05, 0.8, CHINA, "Marble") -- the saucer
	slab(r, 0, ON + 0.08, z, 0.05, 0.3, CHINA, "Marble") -- the cup's foot
	slab(r, 0, ON + 0.12, z, 0.24, 0.46, CHINA, "Marble") -- the cup, a blue band, its lip
	slab(r, 0, ON + 0.36, z, 0.04, 0.46, rgb(126, 168, 204), "Marble")
	slab(r, 0, ON + 0.4, z, 0.03, 0.46, CHINA, "Marble")
	slab(r, 0, ON + 0.405, z, 0.05, 0.4, rgb(124, 74, 40), "Marble") -- the tea
	-- the handle on the right
	r:box(0.27, ON + 0.36, z, 0.12, 0.05, 0.05, CHINA, "Marble")
	r:box(0.27, ON + 0.2, z, 0.12, 0.05, 0.05, CHINA, "Marble")
	r:box(0.335, ON + 0.28, z, 0.05, 0.21, 0.05, CHINA, "Marble")
	-- a teaspoon on the saucer
	local spoon = CFrame.new(-0.12, ON + 0.09, z + 0.26) * CFrame.Angles(0, 0.5, 0)
	r:boxAt(spoon, 0.04, 0.02, 0.26, SILVER, "Metal")
	r:lump(spoon * CFrame.new(0, 0.005, -0.15), 0.1, 0.03, 0.13, SILVER, "Metal")
end

local function juice(r: R, _c: Color3)
	local z = 0.2
	local glass = smooth(r:cyl(0, 0.15, z, 0.8, 0.42, "y", rgb(222, 236, 240), "Glass"))
	glass.transp = 0.6
	smooth(r:cyl(0, 0.1, z, 0.62, 0.37, "y", rgb(250, 140, 30), "Marble")) -- the juice
	for k, at in { Vector3.new(-0.06, 0.39, z + 0.04), Vector3.new(0.07, 0.38, z - 0.05) } do
		local ice = r:boxAt(CFrame.new(at) * CFrame.Angles(0.3, 0.5 * k, 0.2), 0.13, 0.13, 0.13, WHITE, "Glass")
		ice.transp = 0.35
	end
	rod(r, Vector3.new(-0.05, 0.02, z), Vector3.new(-0.13, 0.78, z - 0.06), 0.05, rgb(232, 98, 110), "Plaster", true)
	-- a slice of orange cut to sit on the rim
	face(r, 0.19, 0.5, z - 0.025, 0.05, 0.32, rgb(240, 138, 40), "Marble")
	face(r, 0.19, 0.5, z, 0.055, 0.26, rgb(250, 196, 100), "Marble")
end

-- Books and paper ----------------------------------------------------------------------------------

-- A closed book standing up with its cover to the front: its two boards, its pages and its spine
-- (on the left, as a book lies with its cover up). `b` is its bottom, `z` its back. Returns the
-- cover's front.
local function book(r: R, w: number, h: number, t: number, b: number, z: number, color: Color3, mat: string): number
	local y = b + h / 2
	r:box(0, y, z + 0.025, w, h, 0.05, color, mat)
	r:box(0, y, z + t - 0.025, w, h, 0.05, color, mat)
	r:box(-w / 2 + 0.04, y, z + t / 2, 0.08, h, t, color, mat)
	r:block(-w / 2 + 0.08, b + 0.03, z + 0.05, w / 2 - 0.03, b + h - 0.03, z + t - 0.05, PAPER, "Cardboard")
	return z + t
end

local function storybook(r: R, c: Color3)
	local cover = shade(c, 0.9)
	local w, h, b = 1.0, 1.3, -0.22
	local front = book(r, w, h, 0.28, b, 0.02, cover, "Fabric")
	-- a title plate and a gold star on the cover, gold bands on the spine
	r:box(0.04, b + h * 0.74, front + 0.015, 0.6, 0.2, 0.03, CREAM, "Cardboard")
	for _, a in { 0, math.pi / 4 } do
		r:boxAt(CFrame.new(0.04, b + h * 0.38, front + 0.015) * CFrame.Angles(0, 0, a), 0.2, 0.2, 0.03, GOLD, "Metal")
	end
	for _, y in { b + 0.2, b + h - 0.2 } do
		r:box(-w / 2 + 0.04, y, 0.02 + 0.14, 0.1, 0.05, 0.34, GOLD, "Metal")
	end
end

local function poems(r: R, c: Color3)
	local cover = shade(c, 0.8)
	local w, h, b = 0.9, 1.2, -0.2
	local front = book(r, w, h, 0.22, b, 0.02, cover, "Leather")
	-- a gold frame round the cover, a feather in it, a ribbon marker hanging out at the foot
	local fx, fy = 0.04, b + h / 2
	r:box(fx, fy + 0.46, front + 0.015, 0.68, 0.035, 0.03, GOLD, "Metal")
	r:box(fx, fy - 0.46, front + 0.015, 0.68, 0.035, 0.03, GOLD, "Metal")
	r:box(fx - 0.3225, fy, front + 0.015, 0.035, 0.885, 0.03, GOLD, "Metal")
	r:box(fx + 0.3225, fy, front + 0.015, 0.035, 0.885, 0.03, GOLD, "Metal")
	r:lump(CFrame.new(fx, fy, front + 0.02) * CFrame.Angles(0, 0, -0.5), 0.12, 0.56, 0.03, CREAM, "Fabric")
	r:box(fx - 0.02, fy - 0.1, front + 0.045, 0.02, 0.5, 0.02, CREAM, "Fabric")
	r:box(0.2, b - 0.12, 0.13, 0.07, 0.3, 0.02, rgb(196, 64, 76), "Fabric")
end

local function drawing(r: R, _c: Color3)
	-- a sheet of paper held up by its foot, with a picture in crayon on it: sky, grass, a house, a
	-- tree and the sun
	local b = -0.1
	r:box(0, b + 0.45, 0.03, 1.2, 0.9, 0.02, PAPER, "Cardboard")
	local z = 0.06 -- the crayon, 0.03 over the paper
	local function mark(x: number, y: number, w: number, h: number, color: Color3)
		r:box(x, y, z, w, h, 0.02, color, "Plaster")
	end
	mark(0, b + 0.8, 1.1, 0.12, rgb(150, 196, 236)) -- sky
	mark(0, b + 0.11, 1.1, 0.14, rgb(110, 180, 90)) -- grass
	mark(-0.16, b + 0.31, 0.34, 0.26, rgb(220, 96, 88)) -- the house
	r:tri(
		Vector3.new(-0.36, b + 0.44, z),
		Vector3.new(0.04, b + 0.44, z),
		Vector3.new(-0.16, b + 0.62, z),
		0.02,
		rgb(150, 92, 60),
		"Plaster"
	)
	r:box(-0.16, b + 0.25, z + 0.03, 0.08, 0.14, 0.02, rgb(120, 76, 50), "Plaster") -- its door
	mark(0.28, b + 0.3, 0.05, 0.22, rgb(130, 92, 60)) -- the tree
	face(r, 0.28, b + 0.47, z - 0.01, 0.02, 0.24, rgb(96, 168, 80), "Plaster")
	face(r, 0.44, b + 0.62, z - 0.01, 0.02, 0.16, rgb(246, 196, 60), "Plaster") -- the sun
end

local function letter(r: R, _c: Color3)
	-- an envelope seen from the back: the bottom flap, the top flap over it, a wax seal
	local b, top = -0.12, 0.6
	r:box(0, (b + top) / 2, 0.04, 1.1, top - b, 0.04, rgb(242, 230, 204), "Cardboard")
	r:tri(
		Vector3.new(-0.55, b, 0.08),
		Vector3.new(0.55, b, 0.08),
		Vector3.new(0, 0.3, 0.08),
		0.02,
		rgb(232, 218, 188),
		"Cardboard"
	)
	r:tri(
		Vector3.new(-0.55, top, 0.11),
		Vector3.new(0.55, top, 0.11),
		Vector3.new(0, 0.18, 0.11),
		0.02,
		rgb(224, 208, 176),
		"Cardboard"
	)
	face(r, 0, 0.2, 0.11, 0.04, 0.18, rgb(196, 70, 70), "Marble")
	face(r, 0, 0.2, 0.15, 0.03, 0.09, rgb(160, 50, 54), "Marble")
end

-- Crafts and finds ---------------------------------------------------------------------------------

local function toyboat(r: R, c: Color3)
	local y, z = ON, BACK
	local hull = shade(c, 0.95)
	r:box(-0.075, y + 0.11, z, 0.65, 0.22, 0.34, hull, "Wood")
	-- the pointed bow
	r:tri(
		Vector3.new(0.25, y + 0.11, z - 0.17),
		Vector3.new(0.25, y + 0.11, z + 0.17),
		Vector3.new(0.56, y + 0.11, z),
		0.22,
		hull,
		"Wood"
	)
	-- a painted stripe down each side, the deck, the mast and two sails, a flag
	r:box(-0.075, y + 0.15, z + 0.185, 0.65, 0.05, 0.03, rgb(92, 150, 196), "Wood")
	r:box(-0.075, y + 0.15, z - 0.185, 0.65, 0.05, 0.03, rgb(92, 150, 196), "Wood")
	r:box(-0.08, y + 0.235, z, 0.6, 0.03, 0.3, rgb(232, 204, 158), "Wood")
	r:cyl(-0.02, y + 0.7, z, 0.92, 0.05, "y", DARK_WOOD, "Wood")
	r:tri(
		Vector3.new(0.01, y + 0.32, z),
		Vector3.new(0.01, y + 1.1, z),
		Vector3.new(0.42, y + 0.32, z),
		0.03,
		WHITE,
		"Fabric"
	)
	r:tri(
		Vector3.new(-0.05, y + 0.36, z),
		Vector3.new(-0.05, y + 0.94, z),
		Vector3.new(-0.34, y + 0.36, z),
		0.03,
		rgb(232, 132, 120),
		"Fabric"
	)
	r:box(0.06, y + 1.12, z, 0.14, 0.08, 0.02, RED, "Fabric")
end

local function seashell(r: R, c: Color3)
	-- a scallop standing on its hinge: ribs fanning out over a backing, two little wings at the
	-- hinge
	local hinge = CFrame.new(0, ON + 0.02, 0.02)
	local light = c:Lerp(WHITE, 0.4)
	r:lump(hinge * CFrame.new(0, 0.25, -0.03), 0.62, 0.5, 0.05, shade(c, 0.85), "Marble")
	for k = -3, 3 do
		local cf = hinge * CFrame.Angles(0, 0, -k * 0.27) * CFrame.new(0, 0.26, 0)
		r:lump(cf, 0.17, 0.52, 0.07, if k % 2 == 0 then c else light, "Marble")
	end
	for _, side in { -1, 1 } do
		r:box(side * 0.1, ON + 0.05, 0.02, 0.12, 0.09, 0.06, light, "Marble")
	end
end

local function pebble(r: R, _c: Color3)
	local cf = CFrame.new(0, ON + 0.15, BACK)
	r:lump(cf, 0.56, 0.3, 0.42, rgb(150, 160, 174), "Slate")
	r:lump(cf * CFrame.Angles(0, 0.55, 0), 0.6, 0.36, 0.09, rgb(222, 226, 232), "Slate")
	-- a few dark specks on its top
	for _, p in { { -0.05, 0.03 }, { 0.06, -0.04 }, { 0.02, 0.06 } } do
		r:box(p[1], ON + 0.315, BACK + p[2], 0.04, 0.04, 0.04, rgb(96, 104, 118), "Slate")
	end
end

local function acornOn(r: R, nut: Color3, cap: Color3, mat: string, capMat: string, y: number, z: number)
	downCone(r, 0, y + 0.02, z, 0.12, 0.12, shade(nut, 0.9), mat)
	r:lump(CFrame.new(0, y + 0.27, z), 0.36, 0.42, 0.36, nut, mat)
	r:lump(CFrame.new(0, y + 0.45, z), 0.42, 0.2, 0.42, cap, capMat)
	r:cyl(0.02, y + 0.6, z, 0.14, 0.05, "y", shade(cap, 0.8), capMat)
end

local function acorn(r: R, _c: Color3)
	acornOn(r, rgb(198, 142, 84), rgb(128, 94, 60), "Wood", "Sand", ON, BACK)
	-- an oak leaf it came down with
	r:lump(
		CFrame.new(0.16, ON + 0.2, BACK - 0.12) * CFrame.Angles(0, 0.5, 0) * CFrame.Angles(0, 0, -1.1),
		0.46,
		0.04,
		0.22,
		rgb(126, 156, 74),
		"Fabric"
	)
end

local function luckycoin(r: R, _c: Color3)
	-- standing on its edge on the fingers: a rim, its face, a four leaf clover on it
	local y, z = ON + 0.28, -0.01
	face(r, 0, y, z, 0.08, 0.56, rgb(222, 184, 72), "Metal")
	face(r, 0, y, z + 0.07, 0.04, 0.44, rgb(204, 160, 56), "Metal")
	for k = 0, 3 do
		local a = math.pi / 4 + k * math.pi / 2
		face(r, math.cos(a) * 0.06, y + 0.03 + math.sin(a) * 0.06, z + 0.11, 0.03, 0.12, rgb(244, 212, 104), "Metal")
	end
	r:boxAt(
		CFrame.new(0.03, y - 0.08, z + 0.125) * CFrame.Angles(0, 0, 0.4),
		0.03,
		0.12,
		0.03,
		rgb(244, 212, 104),
		"Metal"
	)
end

-- Treasures ----------------------------------------------------------------------------------------

local function musicbox(r: R, c: Color3)
	local y, z = ON, BACK
	local wood = c:Lerp(rgb(150, 92, 70), 0.35)
	r:box(0, y + 0.27, z, 0.86, 0.42, 0.56, wood, "Wood")
	r:box(0, y + 0.12, z, 0.92, 0.05, 0.62, GOLD, "Metal")
	r:box(0, y + 0.405, z, 0.92, 0.05, 0.62, GOLD, "Metal")
	for _, sx in { -0.36, 0.36 } do
		for _, sz in { -0.22, 0.22 } do
			smooth(r:ball(sx, y + 0.05, z + sz, 0.12, GOLD, "Metal"))
		end
	end
	-- the lid open back on its hinge, a mirror inside it
	local hinge = CFrame.new(0, y + 0.48, z - 0.28) * CFrame.Angles(math.rad(-100), 0, 0)
	r:boxAt(hinge * CFrame.new(0, 0.03, 0.3), 0.9, 0.06, 0.6, shade(wood, 0.9), "Wood")
	r:boxAt(hinge * CFrame.new(0, -0.015, 0.3), 0.68, 0.02, 0.44, SILVER, "Metal")
	-- inside: a velvet lining, the drum and its comb, and a dancer who turns
	r:box(0, y + 0.495, z, 0.72, 0.03, 0.44, rgb(170, 52, 70), "Fabric")
	smooth(r:cyl(-0.16, y + 0.56, z, 0.3, 0.1, "x", GOLD, "Metal"))
	r:box(-0.16, y + 0.53, z + 0.09, 0.3, 0.02, 0.07, SILVER, "Metal")
	r:cone(0.2, y + 0.59, z, 0.14, 0.2, rgb(244, 176, 200), "Fabric")
	r:lump(CFrame.new(0.2, y + 0.71, z), 0.08, 0.14, 0.06, rgb(244, 176, 200), "Fabric")
	smooth(r:ball(0.2, y + 0.82, z, 0.07, rgb(236, 196, 160), "Plaster"))
	-- the key that winds it, on the right
	smooth(r:cyl(0.48, y + 0.27, z, 0.1, 0.05, "x", GOLD, "Metal"))
	r:box(0.53, y + 0.33, z, 0.04, 0.18, 0.04, GOLD, "Metal")
	smooth(r:cyl(0.56, y + 0.41, z, 0.1, 0.07, "x", GOLD, "Metal"))
end

local function snowglobe(r: R, _c: Color3)
	local y, z = ON, BACK
	slab(r, 0, y, z, 0.22, 0.56, rgb(120, 84, 62), "Wood")
	slab(r, 0, y + 0.145, z, 0.05, 0.6, GOLD, "Metal")
	local globe = smooth(r:ball(0, y + 0.52, z, 0.64, rgb(200, 230, 246), "Glass"))
	globe.transp = 0.6
	-- inside: snow on the ground, a fir, a snowman and a few flakes in the air
	slab(r, 0, y + 0.22, z, 0.06, 0.44, rgb(240, 244, 248), "Plaster")
	r:cone(0.1, y + 0.45, z - 0.04, 0.32, 0.22, rgb(70, 120, 84), "Fabric")
	r:box(0.1, y + 0.3, z - 0.04, 0.05, 0.04, 0.05, DARK_WOOD, "Wood")
	smooth(r:ball(-0.1, y + 0.34, z + 0.06, 0.13, WHITE, "Plaster"))
	smooth(r:ball(-0.1, y + 0.44, z + 0.06, 0.09, WHITE, "Plaster"))
	for _, at in
		{
			Vector3.new(-0.15, 0.62, 0.05),
			Vector3.new(0.12, 0.72, 0.08),
			Vector3.new(-0.02, 0.76, -0.1),
			Vector3.new(0.18, 0.56, -0.06),
		}
	do
		r:box(at.X, y + at.Y, z + at.Z, 0.035, 0.035, 0.035, WHITE, "Plaster")
	end
end

local function goldacorn(r: R, _c: Color3)
	local y, z = ON, BACK
	-- on a velvet cushion with gold tassels at its corners
	r:lump(CFrame.new(0, y + 0.09, z), 0.72, 0.18, 0.72, rgb(176, 62, 74), "Fabric")
	for _, sx in { -0.26, 0.26 } do
		for _, sz in { -0.26, 0.26 } do
			smooth(r:ball(sx, y + 0.09, z + sz, 0.08, GOLD, "Metal"))
		end
	end
	acornOn(r, rgb(240, 190, 64), rgb(214, 150, 50), "Metal", "Metal", y + 0.15, z)
end

-- Fruit and greens ---------------------------------------------------------------------------------

local function appleOn(r: R, skin: Color3, leafColor: Color3, mat: string)
	local y, z = ON, BACK + 0.04
	r:lump(CFrame.new(0, y + 0.27, z), 0.58, 0.52, 0.58, skin, mat)
	r:boxAt(CFrame.new(0.02, y + 0.58, z) * CFrame.Angles(0, 0, -0.25), 0.045, 0.16, 0.045, DARK_WOOD, "Wood")
	r:lump(CFrame.new(0.13, y + 0.6, z) * CFrame.Angles(0, 0.4, 0.4), 0.24, 0.03, 0.12, leafColor, "Fabric")
end

local function apple(r: R, _c: Color3)
	appleOn(r, rgb(222, 64, 74), LEAF, "Marble")
end

local function goldapple(r: R, _c: Color3)
	appleOn(r, rgb(236, 186, 62), rgb(196, 190, 90), "Metal")
end

local function strawberry(r: R, _c: Color3)
	-- a big strawberry held up: broad shoulders narrowing to a point, seeds, a star of leaves
	local y, z = ON, 0.0
	local red = rgb(226, 64, 84)
	r:lump(CFrame.new(0, y + 0.52, z), 0.52, 0.34, 0.52, red, "Marble")
	downCone(r, 0, y + 0.04, z, 0.5, 0.5, red, "Marble")
	for _, s in { { -0.7, 0.2 }, { 0.5, 0.2 }, { -0.2, 0.32 }, { 0.9, 0.32 }, { 0.3, 0.44 }, { -1.0, 0.44 } } do
		local a, h = s[1], s[2]
		local rad = 0.25 * (h - 0.04) / 0.5 + 0.015
		r:box(math.sin(a) * rad, y + h, z + math.cos(a) * rad, 0.035, 0.035, 0.035, rgb(250, 224, 120), "Plaster")
	end
	for k = 0, 4 do
		local cf = CFrame.new(0, y + 0.69, z)
			* CFrame.Angles(0, k * math.pi * 2 / 5, 0)
			* CFrame.new(0, 0, 0.12)
			* CFrame.Angles(0.3, 0, 0)
		r:lump(cf, 0.12, 0.04, 0.26, LEAF, "Fabric")
	end
	r:cyl(0, y + 0.78, z, 0.16, 0.045, "y", STEM, "Fabric")
end

local function starfruit(r: R, _c: Color3)
	-- a slice, a star, held up on its point
	local x0, y0, z = 0, ON + 0.38, -0.01
	local skin = rgb(232, 204, 72)
	r:cyl(x0, y0, z + 0.05, 0.1, 0.36, "z", skin, "Marble")
	for k = 0, 4 do
		local a = math.pi / 2 + k * math.pi * 2 / 5
		local tip = Vector3.new(x0 + math.cos(a) * 0.42, y0 + math.sin(a) * 0.42, z + 0.05)
		local l = a - math.pi / 5
		local rr = a + math.pi / 5
		local b1 = Vector3.new(x0 + math.cos(l) * 0.17, y0 + math.sin(l) * 0.17, z + 0.05)
		local b2 = Vector3.new(x0 + math.cos(rr) * 0.17, y0 + math.sin(rr) * 0.17, z + 0.05)
		r:tri(tip, b1, b2, 0.1, skin, "Marble")
	end
	face(r, x0, y0, z + 0.1, 0.03, 0.2, rgb(246, 236, 170), "Marble") -- its pale middle
	for k = 0, 4 do
		local a = math.pi / 2 + k * math.pi * 2 / 5
		r:box(
			x0 + math.cos(a) * 0.065,
			y0 + math.sin(a) * 0.065,
			z + 0.145,
			0.035,
			0.035,
			0.03,
			rgb(150, 110, 60),
			"Plaster"
		)
	end
end

local function carrot(r: R, _c: Color3)
	-- held by its greens, the root hanging down
	local z = IN
	local greens = { LEAF, DEEP_LEAF, rgb(128, 180, 96), LEAF }
	for k = 0, 3 do
		local t = (k - 1.5) * 0.12
		local frame = CFrame.new(-0.06 + k * 0.04, -0.3, z + (k % 2) * 0.03) * CFrame.Angles(0.05 * (k - 1.5), 0, -t)
		r:boxAt(frame * CFrame.new(0, 0.6, 0), 0.045, 1.2, 0.045, STEM, "Fabric")
		-- a feathery frond at its top
		r:lump(frame * CFrame.new(0, 1.3, 0) * CFrame.Angles(0, k * 0.8, 0), 0.18, 0.46, 0.04, greens[k + 1], "Fabric")
	end
	local orange = rgb(240, 132, 48)
	r:lump(CFrame.new(0, -0.32, z), 0.4, 0.16, 0.4, orange, "Plaster")
	downCone(r, 0, -1.25, z, 0.93, 0.4, orange, "Plaster")
	-- rings round it, darker, narrowing to the tip
	for _, ring in { { -0.55, 0.33 }, { -0.8, 0.22 }, { -1.02, 0.13 } } do
		r:cyl(0, ring[1], z, 0.03, ring[2], "y", rgb(214, 108, 38), "Plaster")
	end
end

local function broccoli(r: R, _c: Color3)
	local z = IN
	local stalk = rgb(156, 196, 110)
	r:cyl(0, 0.08, z, 0.96, 0.2, "y", stalk, "Fabric")
	for _, b in { { -0.12, 0.4 }, { 0.12, -0.4 }, { 0, 0 } } do
		r:boxAt(
			CFrame.new(b[1] * 0.6, 0.66, z + b[2] * 0.2) * CFrame.Angles(b[2] * 0.4, 0, -b[1] * 3),
			0.07,
			0.3,
			0.07,
			stalk,
			"Fabric"
		)
	end
	local florets = {
		{ 0, 1.02, 0, 0.36 },
		{ -0.2, 0.9, 0.02, 0.32 },
		{ 0.2, 0.92, -0.02, 0.32 },
		{ -0.1, 0.96, 0.18, 0.3 },
		{ 0.12, 0.98, 0.16, 0.3 },
		{ -0.06, 0.94, -0.2, 0.3 },
		{ 0.14, 1.06, -0.14, 0.28 },
	}
	for k, f in florets do
		r:ball(f[1], f[2], z + f[3], f[4], if k % 2 == 0 then rgb(62, 126, 64) else rgb(78, 146, 72), "Fabric")
	end
end

local function pickles(r: R, _c: Color3)
	local z = 0.16
	local jar = smooth(r:cyl(0, 0.1, z, 0.72, 0.5, "y", rgb(222, 236, 222), "Glass"))
	jar.transp = 0.5
	local brine = smooth(r:cyl(0, 0.07, z, 0.58, 0.44, "y", rgb(206, 220, 150), "Glass"))
	brine.transp = 0.6
	for k, at in
		{
			Vector3.new(-0.1, 0.06, z + 0.08),
			Vector3.new(0.1, 0.04, z + 0.07),
			Vector3.new(0.02, 0.08, z - 0.1),
			Vector3.new(-0.06, 0.1, z - 0.02),
		}
	do
		r:lump(CFrame.new(at) * CFrame.Angles(0.1 * k, 0, 0.12 * (k - 2.5)), 0.13, 0.44, 0.13, rgb(88, 136, 56), "Sand")
	end
	slab(r, 0, 0.46, z, 0.1, 0.46, rgb(200, 170, 90), "Metal")
	r:box(0, 0.12, z + 0.275, 0.3, 0.18, 0.02, CREAM, "Cardboard")
end

-- Baking and sweets --------------------------------------------------------------------------------

local function cookie(r: R, _c: Color3)
	-- three cookies in a little stack, the top one tipped to show its chips
	local y, z = ON, BACK
	local dough = rgb(226, 176, 108)
	slab(r, 0, y, z, 0.1, 0.56, dough, "Sand")
	r:add(smooth({
		shape = "Cylinder",
		cf = CFrame.new(0.03, y + 0.15, z + 0.01) * CFrame.Angles(0, 0.4, 0) * CFrame.Angles(0, 0, math.pi / 2),
		size = Vector3.new(0.1, 0.54, 0.54),
		color = shade(dough, 0.94),
		mat = "Sand",
	}))
	local top = CFrame.new(-0.02, y + 0.27, z + 0.03) * CFrame.Angles(0.3, 0, 0)
	r:add(smooth({
		shape = "Cylinder",
		cf = top * CFrame.Angles(0, 0, math.pi / 2),
		size = Vector3.new(0.1, 0.55, 0.55),
		color = dough,
		mat = "Sand",
	}))
	for _, p in { { 0.1, 0.08 }, { -0.12, 0.05 }, { 0.02, -0.12 }, { -0.06, 0.15 }, { 0.14, -0.06 } } do
		r:lump(top * CFrame.new(p[1], 0.06, p[2]), 0.08, 0.05, 0.08, rgb(96, 60, 40), "Plaster")
	end
end

local function honey(r: R, _c: Color3)
	local z = 0.14
	local jar = smooth(r:cyl(0, 0.11, z, 0.52, 0.55, "y", rgb(246, 222, 170), "Glass"))
	jar.transp = 0.35
	smooth(r:cyl(0, 0.085, z, 0.39, 0.48, "y", HONEY, "Marble"))
	-- a cloth tied over the lid with string, puffed up on top, its corners hanging down
	local cloth = rgb(214, 96, 88)
	slab(r, 0, 0.36, z, 0.14, 0.54, cloth, "Fabric")
	r:lump(CFrame.new(0, 0.5, z), 0.58, 0.14, 0.58, cloth, "Fabric")
	for k = 0, 3 do
		local a = math.pi / 4 + k * math.pi / 2
		local cf = CFrame.new(0, 0.42, z) * CFrame.Angles(0, a, 0) * CFrame.new(0, 0, 0.27) * CFrame.Angles(0.3, 0, 0)
		r:lump(cf, 0.16, 0.2, 0.04, cloth, "Fabric")
	end
	slab(r, 0, 0.43, z, 0.03, 0.58, rgb(198, 168, 118), "Fabric")
	-- a label with a honeycomb on it, and a drip down the side
	r:box(0, 0.12, z + 0.3, 0.3, 0.2, 0.02, CREAM, "Cardboard")
	r:cyl(0, 0.12, z + 0.325, 0.03, 0.1, "z", HONEY, "Marble")
	r:lump(CFrame.new(0.14, 0.3, z + 0.25), 0.07, 0.16, 0.05, HONEY, "Marble")
end

local function tart(r: R, _c: Color3)
	local y, z = ON, BACK
	-- a fluted pastry shell (two eight sided rings turned apart), cream, berries on top
	r:cyl(0, y + 0.09, z, 0.18, 0.72, "y", CRUST, "Sand")
	r:add({
		shape = "Cylinder",
		cf = CFrame.new(0, y + 0.09, z) * CFrame.Angles(0, math.pi / 8, 0) * CFrame.Angles(0, 0, math.pi / 2),
		size = Vector3.new(0.18, 0.72, 0.72),
		color = CRUST,
		mat = "Sand",
	})
	slab(r, 0, y + 0.18, z, 0.035, 0.6, CREAM, "Marble")
	local blue, red = rgb(84, 80, 150), rgb(204, 64, 90)
	local berries: { { x: number, z: number, d: number, blue: boolean } } = {
		{ x = 0, z = 0, d = 0.14, blue = true },
		{ x = 0.18, z = 0.02, d = 0.13, blue = false },
		{ x = -0.18, z = -0.03, d = 0.13, blue = true },
		{ x = 0.06, z = 0.18, d = 0.13, blue = false },
		{ x = -0.08, z = -0.18, d = 0.13, blue = false },
		{ x = 0.13, z = -0.15, d = 0.13, blue = true },
		{ x = -0.15, z = 0.13, d = 0.13, blue = true },
	}
	for _, b in berries do
		-- blueberries smooth skinned, raspberries knobbly
		r:ball(b.x, y + 0.26, z + b.z, b.d, if b.blue then blue else red, if b.blue then "Marble" else "Sand")
	end
	r:lump(CFrame.new(0.04, y + 0.34, z + 0.03) * CFrame.Angles(0.3, 0.5, 0), 0.16, 0.03, 0.08, LEAF, "Fabric")
end

local function honeycake(r: R, _c: Color3)
	local y, z = ON, BACK
	slab(r, 0, y, z, 0.04, 0.84, CHINA, "Marble")
	-- a slice: sponge and cream in layers, honey over the top
	local function layer(y1: number, h: number, color: Color3, mat: string)
		r:tri(
			Vector3.new(-0.36, y1 + h / 2, z - 0.22),
			Vector3.new(0.36, y1 + h / 2, z - 0.22),
			Vector3.new(0, y1 + h / 2, z + 0.32),
			h,
			color,
			mat
		)
	end
	local b = y + 0.04
	layer(b, 0.1, DOUGH, "Sand")
	layer(b + 0.1, 0.05, CREAM, "Plaster")
	layer(b + 0.15, 0.1, DOUGH, "Sand")
	layer(b + 0.25, 0.05, CREAM, "Plaster")
	layer(b + 0.3, 0.03, HONEY, "Marble")
	r:lump(CFrame.new(-0.17, b + 0.27, z + 0.06) * CFrame.Angles(0, 0.6, 0), 0.06, 0.12, 0.06, HONEY, "Marble")
	r:lump(CFrame.new(0.15, b + 0.26, z + 0.1) * CFrame.Angles(0, -0.6, 0), 0.06, 0.14, 0.06, HONEY, "Marble")
	r:cyl(0, b + 0.36, z - 0.02, 0.05, 0.16, "y", rgb(236, 176, 60), "Marble")
end

local function pancakes(r: R, _c: Color3)
	local y, z = ON, BACK
	slab(r, 0, y, z, 0.04, 0.86, CHINA, "Marble")
	for k = 0, 3 do
		slab(
			r,
			0,
			y + 0.04 + k * 0.08,
			z,
			0.08,
			if k % 2 == 0 then 0.62 else 0.6,
			if k % 2 == 0 then rgb(222, 166, 90) else rgb(206, 148, 76),
			"Sand"
		)
	end
	slab(r, 0, y + 0.36, z, 0.03, 0.5, HONEY, "Marble")
	for _, a in { -0.5, 0.2, 0.8 } do
		r:boxAt(
			CFrame.new(math.sin(a) * 0.3, y + 0.31, z + math.cos(a) * 0.3) * CFrame.Angles(0, a, 0),
			0.06,
			0.14,
			0.03,
			HONEY,
			"Marble"
		)
	end
	r:boxAt(CFrame.new(0, y + 0.43, z) * CFrame.Angles(0, 0.4, 0), 0.16, 0.08, 0.16, rgb(250, 230, 150), "Plaster")
end

local function icecream(r: R, _c: Color3)
	local z = 0.05
	local wafer = rgb(214, 162, 96)
	downCone(r, 0, -0.44, z, 0.88, 0.38, wafer, "Sand")
	smooth(r:cyl(0, 0.47, z, 0.07, 0.42, "y", shade(wafer, 0.9), "Sand"))
	for _, ring in { { 0.15, 0.29 }, { -0.15, 0.16 } } do
		r:cyl(0, ring[1], z, 0.03, ring[2], "y", shade(wafer, 0.82), "Sand")
	end
	local pink = rgb(246, 150, 180)
	smooth(r:ball(0, 0.7, z, 0.46, pink, "Plaster"))
	smooth(r:ball(0, 1.0, z, 0.4, rgb(246, 232, 196), "Plaster"))
	r:lump(CFrame.new(0.12, 0.5, z + 0.18) * CFrame.Angles(0.3, 0, 0.2), 0.12, 0.18, 0.08, pink, "Plaster")
	smooth(r:ball(0.02, 1.25, z, 0.13, rgb(210, 40, 60), "Marble"))
	r:boxAt(CFrame.new(0.05, 1.36, z) * CFrame.Angles(0, 0, -0.4), 0.025, 0.14, 0.025, STEM, "Fabric")
	local sprinkles = { rgb(120, 180, 230), rgb(250, 220, 90), rgb(130, 200, 120), rgb(230, 110, 160) }
	for k, color in sprinkles do
		local a = k * 1.4
		local at = CFrame.new(math.sin(a) * 0.15, 1.08 + (k % 2) * 0.05, z + math.cos(a) * 0.15)
		r:boxAt(at * CFrame.Angles(0, a, 0.8), 0.07, 0.025, 0.025, color, "Plaster")
	end
end

local function chocolate(r: R, _c: Color3)
	-- a bar standing in its wrapper, the foil torn back and four squares showing
	local z = 0.1
	r:box(0, 0, z, 0.66, 0.6, 0.16, rgb(176, 58, 70), "Cardboard")
	r:box(0, 0.12, z, 0.72, 0.08, 0.22, GOLD, "Metal")
	r:box(0, 0.33, z, 0.64, 0.06, 0.15, SILVER, "Foil")
	local brown = rgb(110, 66, 40)
	r:box(0, 0.54, z, 0.6, 0.88, 0.11, brown, "Plaster")
	for _, sx in { -0.14, 0.14 } do
		for _, sy in { 0.53, 0.82 } do
			r:box(sx, sy, z + 0.07, 0.24, 0.24, 0.03, rgb(128, 78, 48), "Plaster")
		end
	end
end

local function pudding(r: R, _c: Color3)
	local y, z = ON, BACK
	slab(r, 0, y, z, 0.04, 0.72, CHINA, "Marble")
	local custard = rgb(240, 200, 100)
	slab(r, 0, y + 0.04, z, 0.12, 0.5, custard, "Marble")
	slab(r, 0, y + 0.16, z, 0.12, 0.46, custard, "Marble")
	slab(r, 0, y + 0.28, z, 0.1, 0.42, custard, "Marble")
	local caramel = rgb(150, 84, 36)
	slab(r, 0, y + 0.38, z, 0.05, 0.42, caramel, "Marble")
	for _, a in { -0.6, 0.3, 1.2 } do
		r:lump(
			CFrame.new(math.sin(a) * 0.215, y + 0.33, z + math.cos(a) * 0.215) * CFrame.Angles(0, a, 0),
			0.06,
			0.14,
			0.04,
			caramel,
			"Marble"
		)
	end
	smooth(r:ball(0, y + 0.48, z, 0.14, WHITE, "Plaster"))
	smooth(r:ball(0.01, y + 0.58, z, 0.09, rgb(210, 40, 60), "Marble"))
end

-- Meals --------------------------------------------------------------------------------------------

-- A bowl standing on the fist: a foot, a body that widens, a rim, and what is in it at the top.
-- Returns where its surface is.
local function bowl(r: R, color: Color3, mat: string, fill: Color3): number
	local y, z = ON, BACK
	slab(r, 0, y, z, 0.05, 0.46, color, mat)
	slab(r, 0, y + 0.05, z, 0.14, 0.66, color, mat)
	slab(r, 0, y + 0.19, z, 0.16, 0.82, color, mat)
	slab(r, 0, y + 0.33, z, 0.04, 0.87, shade(color, 1.12), mat)
	slab(r, 0, y + 0.35, z, 0.05, 0.76, fill, "Marble")
	return y + 0.4
end

local function soup(r: R, _c: Color3)
	local top = bowl(r, rgb(110, 150, 186), "Marble", rgb(214, 176, 128))
	local z = BACK
	for k, p in { { -0.16, 0.06 }, { 0.12, 0.14 }, { 0.04, -0.16 } } do
		r:lump(
			CFrame.new(p[1], top + 0.015, z + p[2]) * CFrame.Angles(0, k, 0),
			0.17,
			0.05,
			0.12,
			rgb(176, 130, 92),
			"Plaster"
		)
	end
	for k, p in { { 0.18, -0.06 }, { -0.04, 0.2 }, { -0.2, -0.14 } } do
		r:boxAt(CFrame.new(p[1], top + 0.01, z + p[2]) * CFrame.Angles(0, k, 0), 0.06, 0.02, 0.05, LEAF, "Fabric")
	end
	r:beam(Vector3.new(0.12, top, z - 0.1), Vector3.new(0.4, top + 0.3, z - 0.22), 0.05, 0.02, SILVER, "Metal")
end

local function stew(r: R, _c: Color3)
	local top = bowl(r, rgb(172, 100, 70), "Marble", rgb(160, 64, 44))
	local z = BACK
	for _, side in { -1, 1 } do
		r:box(side * 0.46, ON + 0.28, z, 0.12, 0.06, 0.22, rgb(172, 100, 70), "Marble")
	end
	local carrot, potato, meat = rgb(232, 126, 52), rgb(228, 204, 140), rgb(118, 70, 48)
	local chunks: { { x: number, z: number, s: number, c: Color3 } } = {
		{ x = -0.15, z = 0.08, s = 0.1, c = carrot },
		{ x = 0.14, z = 0.12, s = 0.12, c = potato },
		{ x = 0.02, z = -0.14, s = 0.12, c = meat },
		{ x = -0.18, z = -0.12, s = 0.11, c = meat },
		{ x = 0.2, z = -0.1, s = 0.1, c = carrot },
	}
	for k, c in chunks do
		local cf = CFrame.new(c.x, top + c.s * 0.25, z + c.z) * CFrame.Angles(0.3, k, 0.2)
		r:boxAt(cf, c.s, c.s, c.s, c.c, "Plaster")
	end
	r:lump(CFrame.new(0.04, top + 0.04, z + 0.12), 0.12, 0.05, 0.08, LEAF, "Fabric")
	r:lump(CFrame.new(-0.06, top + 0.04, z), 0.1, 0.05, 0.1, DEEP_LEAF, "Fabric")
end

local function salad(r: R, _c: Color3)
	local top = bowl(r, rgb(186, 138, 92), "Wood", rgb(96, 150, 70))
	local z = BACK
	local greens = { rgb(130, 190, 96), rgb(96, 160, 76), rgb(160, 206, 110) }
	for k = 0, 5 do
		local a = k * math.pi / 3
		local cf = CFrame.new(math.cos(a) * 0.2, top + 0.06, z + math.sin(a) * 0.2) * CFrame.Angles(0.4, a, 0.3)
		r:lump(cf, 0.32, 0.16, 0.26, greens[k % 3 + 1], "Fabric")
	end
	for _, p in { { 0.12, 0.1 }, { -0.16, 0.02 }, { 0.02, -0.16 } } do
		smooth(r:ball(p[1], top + 0.14, z + p[2], 0.14, rgb(220, 70, 60), "Marble"))
	end
	for k, p in { { -0.02, 0.16 }, { 0.18, -0.1 } } do
		r:add(smooth({
			shape = "Cylinder",
			cf = CFrame.new(p[1], top + 0.16, z + p[2])
				* CFrame.Angles(0.5 * k, k, 0)
				* CFrame.Angles(0, 0, math.pi / 2),
			size = Vector3.new(0.03, 0.17, 0.17),
			color = rgb(190, 220, 150),
			mat = "Plaster",
		}))
	end
end

local function curry(r: R, _c: Color3)
	local y, z = ON, BACK
	slab(r, 0, y, z, 0.05, 0.92, CHINA, "Marble")
	r:lump(CFrame.new(-0.17, y + 0.14, z), 0.42, 0.24, 0.52, rgb(246, 244, 236), "Sand")
	r:lump(CFrame.new(0.15, y + 0.08, z + 0.02), 0.5, 0.1, 0.6, rgb(196, 104, 40), "Marble")
	local chunks: { { x: number, z: number, c: Color3 } } = {
		{ x = 0.14, z = 0.12, c = rgb(236, 206, 120) },
		{ x = 0.26, z = -0.08, c = rgb(232, 128, 48) },
		{ x = 0.08, z = -0.16, c = rgb(130, 82, 52) },
	}
	for k, c in chunks do
		r:boxAt(CFrame.new(c.x, y + 0.15, z + c.z) * CFrame.Angles(0.3, k, 0.2), 0.11, 0.11, 0.11, c.c, "Plaster")
	end
	r:lump(
		CFrame.new(-0.2, y + 0.28, z - 0.04) * CFrame.Angles(0, 0.4, 0.3),
		0.06,
		0.06,
		0.22,
		rgb(214, 48, 48),
		"Marble"
	)
	r:lump(CFrame.new(-0.1, y + 0.27, z + 0.1), 0.08, 0.04, 0.08, LEAF, "Fabric")
	r:beam(Vector3.new(-0.02, y + 0.12, z + 0.16), Vector3.new(0.3, y + 0.22, z + 0.42), 0.06, 0.02, SILVER, "Metal")
end

local function cheese(r: R, _c: Color3)
	local y, z = ON, BACK
	local yellow = rgb(242, 196, 70)
	-- a wedge cut from a wheel, its point to the front, the rind round its back, holes in it
	r:tri(
		Vector3.new(-0.4, y + 0.2, z - 0.22),
		Vector3.new(0.4, y + 0.2, z - 0.22),
		Vector3.new(0, y + 0.2, z + 0.34),
		0.36,
		yellow,
		"Plaster"
	)
	r:box(0, y + 0.2, z - 0.25, 0.82, 0.42, 0.06, rgb(226, 160, 52), "Plaster")
	local hole = rgb(212, 160, 50)
	for _, p in { { -0.12, -0.08, 0.1 }, { 0.14, -0.02, 0.08 }, { 0, 0.14, 0.07 } } do
		smooth(r:cyl(p[1], y + 0.39, z + p[2], 0.03, p[3], "y", hole, "Plaster"))
	end
	-- and two on the left face
	local a, b = Vector3.new(-0.4, 0, z - 0.22), Vector3.new(0, 0, z + 0.34)
	local along = (b - a).Unit
	local out = Vector3.new(-along.Z, 0, along.X)
	for _, p in { { 0.3, 0.12, 0.09 }, { 0.62, 0.26, 0.07 } } do
		local at = a:Lerp(b, p[1]) + Vector3.new(0, y + p[2], 0) + out * 0.015
		rod(r, at - out * 0.015, at + out * 0.015, p[3], hole, "Plaster", true)
	end
end

local function bread(r: R, _c: Color3)
	local y, z = ON, BACK
	r:lump(CFrame.new(0, y + 0.18, z), 0.66, 0.36, 0.5, rgb(214, 156, 84), "Sand")
	r:lump(CFrame.new(0, y + 0.24, z), 0.6, 0.3, 0.44, rgb(184, 118, 58), "Sand")
	for _, x in { -0.15, 0, 0.15 } do
		r:boxAt(CFrame.new(x, y + 0.385, z) * CFrame.Angles(0, 0.45, 0), 0.05, 0.03, 0.34, rgb(236, 210, 160), "Sand")
	end
end

local function riceball(r: R, _c: Color3)
	-- a rice ball standing up: a triangle with round corners (the triangle between the corners'
	-- middles, a band out along each side and a round end at each corner), seaweed at its foot
	local y, z = ON, BACK + 0.05
	local rice = rgb(244, 242, 236)
	local depth, round = 0.28, 0.1
	local a, b, c = Vector3.new(-0.2, y + 0.16, z), Vector3.new(0.2, y + 0.16, z), Vector3.new(0, y + 0.46, z)
	r:tri(a, b, c, depth, rice, "Sand")
	for _, edge in { { a, b }, { b, c }, { c, a } } do
		local p, q = edge[1], edge[2]
		local along = q - p
		local out = Vector3.new(along.Y, -along.X, 0).Unit
		local mid = (p + q) / 2 + out * (round / 2)
		local frame = CFrame.fromMatrix(mid, along.Unit, out, along.Unit:Cross(out))
		r:boxAt(frame, along.Magnitude, round, depth, rice, "Sand")
	end
	for _, p in { a, b, c } do
		smooth(r:cyl(p.X, p.Y, p.Z, depth, round * 2, "z", rice, "Sand"))
	end
	r:box(0, y + 0.17, z, 0.28, 0.28, depth + 0.06, rgb(40, 58, 46), "Fabric")
	for k, p in { { 0.02, 0.5 }, { 0.08, 0.44 }, { -0.01, 0.43 }, { 0.12, 0.36 } } do
		r:boxAt(
			CFrame.new(p[1], y + p[2], z + depth / 2 + 0.015) * CFrame.Angles(0, 0, k),
			0.035,
			0.02,
			0.03,
			rgb(60, 50, 44),
			"Plaster"
		)
	end
end

local function skewer(r: R, _c: Color3)
	-- a whole fish grilled on a stick, held up by the stick, head up, the stick out of its mouth
	local z = IN
	r:cyl(0, 0.635, z, 2.17, 0.05, "y", rgb(196, 160, 112), "Wood")
	local body = rgb(132, 166, 196)
	r:lump(CFrame.new(0, 1.12, z), 0.34, 0.86, 0.16, body, "Marble")
	r:lump(CFrame.new(-0.12, 1.12, z), 0.2, 0.8, 0.12, rgb(92, 120, 150), "Marble")
	local fin = rgb(100, 128, 156)
	r:tri(Vector3.new(0, 0.74, z), Vector3.new(-0.2, 0.52, z), Vector3.new(0.2, 0.52, z), 0.05, fin, "Marble")
	r:tri(Vector3.new(-0.17, 1.35, z), Vector3.new(-0.17, 0.95, z), Vector3.new(-0.3, 1.08, z), 0.03, fin, "Marble")
	face(r, 0.04, 1.4, z + 0.05, 0.02, 0.09, WHITE, "Marble")
	face(r, 0.045, 1.4, z + 0.07, 0.03, 0.045, rgb(40, 36, 40), "Marble")
	for _, y in { 0.96, 1.1, 1.24 } do
		r:boxAt(CFrame.new(0.02, y, z + 0.095) * CFrame.Angles(0, 0, 0.4), 0.2, 0.035, 0.03, rgb(70, 54, 46), "Plaster")
	end
end

local function dragonchili(r: R, _c: Color3)
	-- a big red chili held by its stalk, rising from its green cap and curling to its point
	local z = IN
	r:cyl(0, 0.08, z, 0.76, 0.07, "y", STEM, "Fabric")
	r:lump(CFrame.new(0, 0.5, z), 0.3, 0.14, 0.3, rgb(96, 140, 64), "Fabric")
	local red = rgb(226, 58, 58)
	r:lump(CFrame.new(0.04, 0.9, z) * CFrame.Angles(0, 0, -0.12), 0.32, 0.8, 0.32, red, "Marble")
	r:lump(CFrame.new(0.14, 1.28, z) * CFrame.Angles(0, 0, -0.4), 0.2, 0.5, 0.2, shade(red, 0.94), "Marble")
	r:add({
		shape = "Cone",
		cf = CFrame.new(0.26, 1.52, z) * CFrame.Angles(0, 0, -0.8),
		size = Vector3.new(0.13, 0.26, 0.13),
		color = shade(red, 0.88),
		mat = "Marble",
	})
	r:lump(CFrame.new(-0.04, 0.86, z + 0.15) * CFrame.Angles(0, 0, -0.1), 0.05, 0.4, 0.03, rgb(246, 140, 130), "Marble")
end

local function pie(r: R, _c: Color3)
	local y, z = ON, BACK
	-- a whole pumpkin pie: a faceted crust, its crimped edge, the filling and a dollop of cream
	r:cyl(0, y + 0.08, z, 0.16, 0.9, "y", CRUST, "Sand")
	slab(r, 0, y + 0.16, z, 0.03, 0.74, rgb(226, 132, 50), "Marble")
	for k = 0, 9 do
		local a = k * math.pi * 2 / 10
		r:ball(math.cos(a) * 0.4, y + 0.17, z + math.sin(a) * 0.4, 0.13, shade(CRUST, 0.92), "Sand")
	end
	smooth(r:ball(0, y + 0.24, z, 0.17, WHITE, "Plaster"))
	r:cone(0, y + 0.35, z, 0.16, 0.13, WHITE, "Plaster")
end

-- The list -----------------------------------------------------------------------------------------

type Drawer = (r: R, c: Color3) -> ()

-- Each thing's drawing and how it lies once dropped.
local MODELS: { [string]: { draw: Drawer, lie: string } } = {
	-- the things of their own
	strawberry = { draw = strawberry, lie = "stand" },
	herbs = { draw = herbs, lie = "flat" },
	cookie = { draw = cookie, lie = "stand" },
	honey = { draw = honey, lie = "stand" },
	tea = { draw = tea, lie = "stand" },
	juice = { draw = juice, lie = "stand" },
	storybook = { draw = storybook, lie = "flat" },
	poems = { draw = poems, lie = "flat" },
	tulip = { draw = tulip, lie = "flat" },
	daisy = { draw = daisy, lie = "flat" },
	sunflower = { draw = sunflower, lie = "flat" },
	bouquet = { draw = bouquet, lie = "flat" },
	drawing = { draw = drawing, lie = "flat" },
	toyboat = { draw = toyboat, lie = "stand" },
	letter = { draw = letter, lie = "flat" },
	seashell = { draw = seashell, lie = "flat" },
	pebble = { draw = pebble, lie = "stand" },
	acorn = { draw = acorn, lie = "stand" },
	luckycoin = { draw = luckycoin, lie = "flat" },
	musicbox = { draw = musicbox, lie = "stand" },
	snowglobe = { draw = snowglobe, lie = "stand" },
	goldacorn = { draw = goldacorn, lie = "stand" },
	-- the foods
	apple = { draw = apple, lie = "stand" },
	bread = { draw = bread, lie = "stand" },
	carrot = { draw = carrot, lie = "flat" },
	cheese = { draw = cheese, lie = "stand" },
	soup = { draw = soup, lie = "stand" },
	skewer = { draw = skewer, lie = "flat" },
	tart = { draw = tart, lie = "stand" },
	honeycake = { draw = honeycake, lie = "stand" },
	riceball = { draw = riceball, lie = "stand" },
	pancakes = { draw = pancakes, lie = "stand" },
	curry = { draw = curry, lie = "stand" },
	pie = { draw = pie, lie = "stand" },
	icecream = { draw = icecream, lie = "flat" },
	salad = { draw = salad, lie = "stand" },
	chocolate = { draw = chocolate, lie = "flat" },
	pudding = { draw = pudding, lie = "stand" },
	broccoli = { draw = broccoli, lie = "flat" },
	pickles = { draw = pickles, lie = "stand" },
	stew = { draw = stew, lie = "stand" },
	starfruit = { draw = starfruit, lie = "flat" },
	dragonchili = { draw = dragonchili, lie = "flat" },
	goldapple = { draw = goldapple, lie = "stand" },
}

-- Making and placing -------------------------------------------------------------------------------

local function turnFor(lie: string): CFrame
	if lie == "flat" then
		return CFrame.Angles(-math.pi / 2, 0, 0) -- its front to the sky
	end
	return CFrame.identity
end

-- Whether a thing has a model of its own (every thing in Data/Items has: the Bag spec checks).
function ThingModels.has(id: string): boolean
	return MODELS[id] ~= nil
end

-- Every id with a model, sorted.
function ThingModels.ids(): { string }
	local out = {}
	for id in MODELS do
		table.insert(out, id)
	end
	table.sort(out)
	return out
end

-- A thing's model, by its item (Data/Items) or id. A thing with no model of its own (none should
-- be) is a small parcel.
function ThingModels.draw(item: any): Thing
	local id: string = if type(item) == "table" then item.id else tostring(item)
	local color = if type(item) == "table" and type(item.color) == "string" then hex(item.color) else WHITE
	local entry = MODELS[id]
	local r = Recipe.new(color, color)
	local lie = "stand"
	if entry then
		entry.draw(r, color)
		lie = entry.lie
	else
		r:box(0, ON + 0.2, BACK, 0.5, 0.4, 0.4, KRAFT, "Cardboard")
		r:box(0, ON + 0.2, BACK, 0.52, 0.1, 0.42, RED, "Fabric")
	end
	local prims = r.prims
	-- how it lies: turned, its lowest point on the ground and its middle over the spot
	local turn = turnFor(lie)
	local turned = {}
	for i, p in prims do
		local q = table.clone(p)
		q.cf = turn * p.cf
		turned[i] = q
	end
	local lo, hi = Geometry.bounds(Geometry.flatten(turned))
	local mid = (lo + hi) / 2
	local onGround = CFrame.new(-mid.X, -lo.Y, -mid.Z) * turn
	-- on the hand: all of it over the fist's top
	local allLo = Geometry.bounds(Geometry.flatten(prims))
	local on = allLo.Y >= ON - 0.05
	return { id = id, prims = prims, lie = onGround, on = on }
end

-- The thing's space in the world for a hand's grip (its RightGripAttachment's WorldCFrame, or
-- ThingModels.gripIn on a hand without one). `hand` is the hand's size: what stands on the fist
-- goes up or down to the top of a hand bigger or smaller than the blocky one.
function ThingModels.inHand(thing: Thing, grip: CFrame, hand: Vector3?): CFrame
	local lift = if thing.on and hand then hand.Z / 2 - ON else 0
	return grip * CFrame.Angles(0, math.pi, 0) * CFrame.new(0, lift, 0)
end

-- Where a hand of this size holds things, in the hand's own frame: at its fingertips' end, turned
-- as Roblox's RightGripAttachment is (a tool's handle stands up out of a fist held out).
function ThingModels.gripIn(hand: Vector3): CFrame
	return CFrame.new(0, -hand.Y / 2, 0) * CFrame.Angles(-math.pi / 2, 0, 0)
end

-- The thing's space for one lying on the ground at `spot` (its y the ground, any turn about Y).
function ThingModels.lying(thing: Thing, spot: CFrame): CFrame
	return spot * thing.lie
end

return ThingModels
