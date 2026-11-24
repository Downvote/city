--!strict
-- The insides of the town's buildings. The user: "could you detail each model much more, with
-- more attention to detail? for example, the interiors of buildings."
--
-- Every shop, tower, little house and public building on the map is a real room: a shell with a
-- doorway you can walk through, a door that opens, a window you can see in at, and furniture that
-- suits what the place is. Then the user: "pay more attention to detail. alot of places in the
-- map are just simple shapes ... the amount of detail should be similar to the default house
-- everywhere", with a picture of a bookshop whose books were three big cubes to a shelf. So the
-- furniture is made the way the starting house's is: a bookcase has a plinth, a crown and shelves
-- of thin spines of different heights, some leaning and some lying flat; a counter has panels and
-- a till; a bakery's shelves hold loaves and baskets of long bread; a grocer's crates sit tilted
-- on a stand with the fruit heaped in them.
--
--   Interiors.shell(r, spec)            the room: floor, walls, shop window, door. Returns its box.
--   Interiors.fill(r, kind, box, tint)  the furniture for a kind of place
--
-- Everything is drawn in the building's own frame, front toward local -Z, like the rest of the
-- map's models. The town has nearly sixty of these rooms, so anything used more than once (a
-- bookcase, a shelf of books, a counter, a lamp, a sofa, a row of seats) is a piece: drawn once
-- round its own middle, merged into one mesh and copied (Geometry.piece). A room is mostly
-- pieces, which keeps the town's count of parts down; what can't be a piece (glass, a lamp that
-- lights up, a blanket in the house's own colour) is a plain part.

local Geometry = require(script.Parent.Parent.Build.Geometry)
local Recipe = require(script.Parent.Parent.Build.Recipe)

type R = Recipe.Recipe
type Prim = Geometry.Prim

local Interiors = {}

local function rgb(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end

local function shade(c: Color3, k: number): Color3
	return Color3.new(math.min(1, c.R * k), math.min(1, c.G * k), math.min(1, c.B * k))
end

-- The palette: soft walls and wood, strong colour only on small things (books, fruit, flowers).
local WHITE = rgb(250, 246, 236)
local CREAM = rgb(242, 232, 213)
local PAPER = rgb(248, 244, 234)
local WOOD = rgb(196, 154, 108) -- oak
local WALNUT = rgb(154, 107, 72)
local PALE = rgb(221, 190, 148)
local FLOOR = rgb(226, 190, 140)
local METAL = rgb(186, 192, 202)
local STEEL = rgb(150, 156, 166)
local DARK = rgb(90, 85, 96)
local INK = rgb(64, 62, 72)
local GLASS = rgb(170, 216, 244)
local BRASS = rgb(205, 170, 100)
local LEAF = rgb(110, 166, 96)
local LEAF_DARK = rgb(74, 128, 86)
local LEAF_LIGHT = rgb(150, 190, 120)
local CLAY = rgb(196, 124, 92)
local KRAFT = rgb(200, 164, 120)
local LAMPLIGHT = rgb(255, 236, 190)
local TEAL = rgb(63, 140, 134)
local FOREST = rgb(78, 127, 98)
local BERRY = rgb(184, 80, 90)
local NAVY = rgb(70, 96, 142)
local MUSTARD = rgb(217, 169, 63)
local CORAL = rgb(224, 133, 102)
local LILAC = rgb(156, 134, 184)
local BLUSH = rgb(235, 200, 194)
local SAGE = rgb(143, 179, 154)
local SKY = rgb(204, 221, 234)
local BUTTER = rgb(243, 223, 166)

-- Book spines: muted, and never two primaries side by side.
local BOOKS = {
	rgb(168, 86, 78),
	rgb(70, 110, 150),
	SAGE,
	rgb(226, 192, 114),
	rgb(142, 91, 122),
	CREAM,
	rgb(208, 138, 108),
	rgb(62, 110, 88),
	rgb(60, 62, 72),
	rgb(120, 150, 176),
	rgb(184, 150, 110),
	rgb(150, 70, 64),
}

-- A room's inside: x1..x2 across, z1 (the front, where the door is) to z2 (the back), the floor's
-- top at y and the ceiling h above it. `door` is the middle of the doorway along x.
export type Box = { x1: number, z1: number, x2: number, z2: number, y: number, h: number, door: number? }

-- Small drawing helpers -------------------------------------------------------------------------------

-- A box between two corners, in the frame `f`.
local function slab(
	r: R,
	f: CFrame,
	x1: number,
	y1: number,
	z1: number,
	x2: number,
	y2: number,
	z2: number,
	color: Color3,
	mat: string?
): Prim
	return r:boxAt(
		f * CFrame.new((x1 + x2) / 2, (y1 + y2) / 2, (z1 + z2) / 2),
		math.abs(x2 - x1),
		math.abs(y2 - y1),
		math.abs(z2 - z1),
		color,
		mat
	)
end

-- An upright cylinder standing on (x, y, z) in the frame `f`.
local function post(
	r: R,
	f: CFrame,
	x: number,
	y: number,
	z: number,
	height: number,
	d: number,
	color: Color3,
	mat: string?
): Prim
	return r:add({
		shape = "Cylinder",
		cf = f * CFrame.new(x, y + height / 2, z) * CFrame.Angles(0, 0, math.pi / 2),
		size = Vector3.new(height, d, d),
		color = color,
		mat = mat or "SmoothPlastic",
	})
end

-- A round rod from a to b (a cylinder laid along the line).
local function rod(q: R, a: Vector3, b: Vector3, d: number, color: Color3, mat: string?)
	local v = b - a
	local len = v.Magnitude
	if len < 1e-3 then
		return
	end
	local x = v / len
	local up = if math.abs(x.Y) > 0.99 then Vector3.zAxis else Vector3.yAxis
	local z = x:Cross(up).Unit
	local y = z:Cross(x).Unit
	q:add({
		shape = "Cylinder",
		cf = CFrame.fromMatrix((a + b) / 2, x, y, z),
		size = Vector3.new(len, d, d),
		color = color,
		mat = mat or "SmoothPlastic",
	})
end

-- A frame standing at (x, z) on the floor of a box, turned `yaw` degrees (0 faces the door, -90
-- faces out from the left wall, 90 out from the right wall, 180 toward the back).
local function at(box: Box, x: number, z: number, yaw: number?): CFrame
	return CFrame.new(x, box.y, z) * CFrame.Angles(0, math.rad(yaw or 0), 0)
end

-- A frame on a wall, `y` up from the floor, facing into the room: `side` is "back", "left" or
-- "right", `s` how far along it (x for the back wall, z for the sides). Things hung there are
-- drawn with their back at z = 0, a little off the plaster.
local function wallAt(b: Box, side: string, s: number, y: number): CFrame
	if side == "back" then
		return CFrame.new(s, b.y + y, b.z2 - 0.05)
	elseif side == "left" then
		return CFrame.new(b.x1 + 0.05, b.y + y, s) * CFrame.Angles(0, math.rad(-90), 0)
	end
	return CFrame.new(b.x2 - 0.05, b.y + y, s) * CFrame.Angles(0, math.rad(90), 0)
end

-- A little random number source that gives the same numbers every time for a seed, so a piece
-- drawn from it is the same piece wherever it is used.
local function dice(seed: number): () -> number
	local s = seed
	return function(): number
		s = (s * 16807) % 2147483647
		return s / 2147483647
	end
end

-- Pieces ------------------------------------------------------------------------------------------------

-- Every piece made so far, by name. A piece is drawn once round its own origin, so its key never
-- wavers; using it again is a copy with a new frame.
local kit: { [string]: Prim } = {}
local owned: { [string]: boolean } = {}

local function stamp(r: R, f: CFrame, id: string, draw: (R) -> ()): Prim
	local proto = kit[id]
	if not proto then
		local q = Recipe.new(WHITE, WHITE)
		draw(q)
		local made = Geometry.piece(q.prims, false)
		kit[id] = made
		owned[made.key or ""] = true
		proto = made
	end
	local p = table.clone(proto)
	p.cf = f * proto.cf
	return r:add(p)
end

-- The same drawing as plain parts at f, for furniture only the big public rooms have: a piece
-- costs the town a merge of its own, which isn't worth it for a handful of copies.
local function plain(r: R, f: CFrame, draw: (R) -> ())
	local q = Recipe.new(WHITE, WHITE)
	draw(q)
	for _, p in q.prims do
		p.cf = f * p.cf
		r:add(p)
	end
end

-- An invisible box that makes a piece solid to bump into (pieces never collide: the facade
-- kit's rule).
local function solid(r: R, f: CFrame, x1: number, y1: number, z1: number, x2: number, y2: number, z2: number)
	local p = r:boxAt(
		f * CFrame.new((x1 + x2) / 2, (y1 + y2) / 2, (z1 + z2) / 2),
		x2 - x1,
		y2 - y1,
		z2 - z1,
		WHITE,
		"SmoothPlastic"
	)
	p.transp = 1
end

-- Shelves ------------------------------------------------------------------------------------------------

-- A bookcase, which is also every shop's shelving: 4 wide, a stud deep, its back toward +Z. The
-- tops of its four shelves are at SHELF; goods are drawn for the lower two and used again three
-- studs up for the upper two.
local SHELF = { 0.47, 1.97, 3.47, 4.97 }
local CASE_STEP = 4.05 -- one case to the next along a wall

local function drawCase(q: R)
	local M = "Wood"
	q:block(-1.85, 0.35, 0.36, 1.85, 6.3, 0.48, shade(WOOD, 0.72), M) -- the back
	q:block(-2.0, 0, -0.5, -1.85, 6.3, 0.5, WOOD, M)
	q:block(1.85, 0, -0.5, 2.0, 6.3, 0.5, WOOD, M)
	q:block(-2.05, 6.3, -0.54, 2.05, 6.44, 0.52, WOOD, M) -- the top and its crown
	q:block(-2.12, 6.44, -0.6, 2.12, 6.6, 0.55, shade(WOOD, 0.86), M)
	q:block(-1.85, 0, -0.42, 1.85, 0.35, 0.36, shade(WOOD, 0.8), M) -- the plinth, set back
	for _, y in SHELF do
		q:block(-1.85, y - 0.12, -0.48, 1.85, y, 0.36, WOOD, M)
	end
end

-- One shelf of books on a shelf whose top is at y, from the left side along. `plan` is what comes
-- next: "b" a book standing, "lean" one leaning on the last, "gap" a space, "pile2" or "pile3"
-- books lying flat on each other.
local function bookRow(q: R, y: number, plan: string, rand: () -> number)
	local M = "SmoothPlastic"
	local x, lastH = -1.8, 1.0
	local function color(): Color3
		return BOOKS[1 + math.floor(rand() * #BOOKS)]
	end
	for step in plan:gmatch("%S+") do
		if step == "b" then
			local w = 0.16 + rand() * 0.12
			local h = 0.74 + rand() * 0.42
			local front = -0.43 + rand() * 0.05
			local depth = 0.6 + rand() * 0.08
			if x + w <= 1.8 then
				q:block(x, y, front, x + w, y + h, front + depth, color(), M)
				x += w
				lastH = h
			end
		elseif step == "lean" then
			local w = 0.2 + rand() * 0.06
			local h = lastH * 0.96
			local a = math.rad(13 + rand() * 6)
			local xl = x + h * math.sin(a) + 0.01
			if xl + w * math.cos(a) <= 1.8 then
				local cx = xl + w / 2 * math.cos(a) - h / 2 * math.sin(a)
				local cy = y + w / 2 * math.sin(a) + h / 2 * math.cos(a)
				q:boxAt(CFrame.new(cx, cy, -0.1) * CFrame.Angles(0, 0, a), w, h, 0.62, color(), M)
				x = xl + w * math.cos(a)
			end
		elseif step == "gap" then
			x += 0.26 + rand() * 0.16
		elseif step:sub(1, 4) == "pile" then
			local n = tonumber(step:sub(5)) or 2
			local L = 0.78 + rand() * 0.12
			if x + L + 0.12 <= 1.8 then
				local cx, top = x + 0.06 + L / 2, y
				for k = 1, n do
					local t = 0.13 + rand() * 0.07
					q:boxAt(
						CFrame.new(cx + (rand() - 0.5) * 0.05, top + t / 2, -0.12)
							* CFrame.Angles(0, math.rad((rand() - 0.5) * 10), 0),
						L - (k - 1) * 0.07,
						t,
						0.56 + rand() * 0.08,
						color(),
						M
					)
					top += t
				end
				x = cx + L / 2 + 0.06
			end
		end
	end
end

local function drawBooks(plan1: string, plan2: string, seed: number): (R) -> ()
	return function(q: R)
		local rand = dice(seed)
		bookRow(q, SHELF[1], plan1, rand)
		bookRow(q, SHELF[2], plan2, rand)
	end
end

local drawBooksA = drawBooks("b b b b b lean gap pile3 b b b", "pile2 b b b b b b b gap b b b", 4021)
local drawBooksB = drawBooks("b b b gap b b b b b b lean", "b b b b pile3 b b b b gap b", 7717)

-- A bakery's shelves: a basket of long loaves standing up and round loaves with their tops cut,
-- then a tray of rolls and two more loaves, and the prices hung on the shelf's edge.
local function drawLoaves(q: R)
	local M = "SmoothPlastic"
	local crust, dark, pale, wicker = rgb(214, 160, 92), rgb(178, 118, 66), rgb(236, 206, 150), rgb(186, 146, 98)
	local y = SHELF[1]
	q:cyl(-1.3, y + 0.3, -0.05, 0.6, 0.8, "y", wicker, M)
	for i, a in { { -0.14, -10, -0.1 }, { 0.12, 8, 0.05 }, { -0.02, 2, 0.12 }, { 0.16, -5, -0.12 } } do
		q:lump(
			CFrame.new(-1.3 + a[1], y + 0.72, -0.05 + a[3]) * CFrame.Angles(0, 0, math.rad(a[2])),
			0.17,
			1.05,
			0.17,
			if i % 2 == 0 then dark else crust,
			M
		)
	end
	for i, x in { -0.35, 0.5, 1.35 } do
		q:lump(CFrame.new(x, y + 0.25, -0.05), 0.78, 0.5, 0.7, if i == 2 then dark else crust, M)
		q:boxAt(CFrame.new(x, y + 0.5, -0.05) * CFrame.Angles(0, math.rad(35), 0), 0.45, 0.07, 0.06, pale, M)
	end
	y = SHELF[2]
	q:block(-1.8, y, -0.4, -0.15, y + 0.06, 0.3, rgb(170, 140, 110), M)
	for _, p in { { -1.5, -0.2 }, { -1.0, -0.18 }, { -0.5, -0.2 }, { -1.5, 0.15 }, { -1.0, 0.13 }, { -0.5, 0.15 } } do
		q:ball(p[1], y + 0.23, p[2], 0.38, crust, M)
	end
	for _, p in { { 0.4, -0.08 }, { 1.3, 0.04 } } do
		q:lump(CFrame.new(p[1], y + 0.22, p[2]), 0.8, 0.45, 0.5, dark, M)
		q:boxAt(CFrame.new(p[1], y + 0.44, p[2]) * CFrame.Angles(0, math.rad(-30), 0), 0.4, 0.07, 0.06, pale, M)
	end
	for _, x in { -1.0, 0.85 } do
		q:block(x - 0.2, SHELF[1] - 0.22, -0.53, x + 0.2, SHELF[1] - 0.04, -0.5, PAPER, M)
	end
end

-- A grocer's (or a cafe's, or a clinic's) shelves: tins stacked in a little pyramid, jars of jam,
-- two bottles, then boxes of cereal and two sacks.
local function drawJars(q: R)
	local M = "SmoothPlastic"
	local y = SHELF[1]
	local tin = rgb(188, 192, 198)
	for i, p in { { -1.55, 0 }, { -1.05, 0 }, { -1.3, 1 } } do
		local yb = y + p[2] * 0.6
		q:cyl(p[1], yb + 0.275, -0.1, 0.55, 0.46, "y", ({ rgb(196, 98, 84), FOREST, rgb(226, 182, 96) })[i], M)
		q:cyl(p[1], yb + 0.575, -0.1, 0.05, 0.4, "y", tin, M)
	end
	for i, x in { -0.45, 0.1 } do
		q:cyl(x, y + 0.25, -0.1, 0.5, 0.5, "y", if i == 1 then rgb(160, 64, 76) else rgb(222, 150, 70), M)
		q:cyl(x, y + 0.55, -0.1, 0.1, 0.56, "y", if i == 1 then WHITE else rgb(196, 98, 84), M)
	end
	for i, x in { 0.75, 1.3 } do
		q:cyl(x, y + 0.36, -0.1, 0.72, 0.42, "y", if i == 1 then rgb(206, 176, 92) else rgb(110, 150, 112), M)
		q:cyl(x, y + 0.845, -0.1, 0.25, 0.16, "y", if i == 1 then rgb(206, 176, 92) else rgb(110, 150, 112), M)
		q:cyl(x, y + 1.005, -0.1, 0.07, 0.2, "y", INK, M)
	end
	y = SHELF[2]
	for i, x in { -1.45, -0.75, -0.05 } do
		local face = ({ rgb(226, 182, 96), rgb(120, 150, 176), CORAL })[i]
		q:block(x - 0.32, y, -0.3, x + 0.32, y + 0.85, 0.05, face, M)
		q:block(x - 0.32, y + 0.85, -0.3, x + 0.32, y + 1.0, 0.05, WHITE, M)
	end
	for i, x in { 0.75, 1.4 } do
		q:lump(CFrame.new(x, y + 0.37, -0.05), 0.62, 0.75, 0.55, if i == 1 then KRAFT else CREAM, M)
	end
end

-- A clothes shop's shelves: stacks of folded tops, then jumpers and jeans.
local function drawFolds(q: R)
	local M = "Fabric"
	local rand = dice(3301)
	type Stack = { x: number, n: number, a: Color3, b: Color3 }
	local rows: { { Stack } } = {
		{
			{ x = -1.25, n = 4, a = NAVY, b = rgb(96, 120, 160) },
			{ x = 0.0, n = 3, a = CREAM, b = rgb(220, 208, 186) },
			{ x = 1.25, n = 4, a = SAGE, b = rgb(120, 160, 134) },
		},
		{
			{ x = -1.25, n = 3, a = BERRY, b = rgb(200, 120, 120) },
			{ x = 0.0, n = 4, a = MUSTARD, b = BUTTER },
			{ x = 1.25, n = 3, a = rgb(96, 120, 160), b = rgb(80, 100, 140) },
		},
	}
	for r, row in rows do
		for _, s in row do
			local top = SHELF[r]
			for k = 1, s.n do
				local t = 0.15 + rand() * 0.04
				q:boxAt(
					CFrame.new(s.x + (rand() - 0.5) * 0.08, top + t / 2, -0.08)
						* CFrame.Angles(0, math.rad((rand() - 0.5) * 6), 0),
					1.02,
					t,
					0.66,
					if k % 2 == 0 then s.b else s.a,
					M
				)
				top += t
			end
		end
	end
end

-- A toy shop's shelves: a teddy, a ball, building blocks and a car; a sailing boat, a rocket, a
-- spinning top and a drum.
local function drawToys(q: R)
	local M = "SmoothPlastic"
	local y = SHELF[1]
	local fur, snout = rgb(190, 146, 100), rgb(228, 200, 160)
	q:lump(CFrame.new(-1.35, y + 0.31, -0.05), 0.6, 0.62, 0.48, fur, M)
	q:ball(-1.35, y + 0.82, -0.08, 0.46, fur, M)
	q:ball(-1.53, y + 1.03, -0.08, 0.16, fur, M)
	q:ball(-1.17, y + 1.03, -0.08, 0.16, fur, M)
	q:ball(-1.35, y + 0.76, -0.3, 0.17, snout, M)
	q:ball(-0.55, y + 0.275, -0.05, 0.55, CORAL, M)
	q:block(-0.13, y, -0.28, 0.23, y + 0.36, 0.08, MUSTARD, M)
	q:block(0.27, y, -0.18, 0.63, y + 0.36, 0.18, SAGE, M)
	q:boxAt(CFrame.new(0.25, y + 0.54, -0.05) * CFrame.Angles(0, math.rad(20), 0), 0.36, 0.36, 0.36, NAVY, M)
	q:block(0.85, y + 0.12, -0.3, 1.65, y + 0.38, 0.1, BERRY, M)
	q:block(1.05, y + 0.38, -0.27, 1.45, y + 0.6, 0.07, SKY, M)
	for _, w in { { 0.97, -0.3 }, { 1.53, -0.3 }, { 0.97, 0.1 }, { 1.53, 0.1 } } do
		q:cyl(w[1], y + 0.12, w[2] + (if w[2] < 0 then -0.04 else 0.04), 0.08, 0.24, "z", INK, M)
	end
	y = SHELF[2]
	q:block(-1.75, y, -0.25, -0.85, y + 0.22, 0.1, NAVY, M)
	q:block(-1.32, y + 0.22, -0.09, -1.28, y + 1.15, -0.05, WALNUT, M)
	q:wedge(CFrame.new(-1.0, y + 0.7, -0.07) * CFrame.Angles(0, math.rad(-90), 0), 0.04, 0.8, 0.56, WHITE, M)
	q:cyl(-0.35, y + 0.45, -0.05, 0.7, 0.3, "y", CREAM, M)
	q:cone(-0.35, y + 0.975, -0.05, 0.35, 0.3, BERRY, M)
	q:block(-0.6, y, -0.07, -0.1, y + 0.32, -0.03, BERRY, M)
	q:block(-0.37, y, -0.3, -0.33, y + 0.32, 0.2, BERRY, M)
	q:add({
		shape = "Cone",
		cf = CFrame.new(0.35, y + 0.2, -0.05) * CFrame.Angles(math.pi, 0, 0),
		size = Vector3.new(0.5, 0.4, 0.5),
		color = MUSTARD,
		mat = M,
	})
	q:cyl(0.35, y + 0.52, -0.05, 0.25, 0.08, "y", WALNUT, M)
	q:cyl(1.2, y + 0.225, -0.05, 0.45, 0.6, "y", BERRY, M)
	q:cyl(1.2, y + 0.47, -0.05, 0.04, 0.54, "y", CREAM, M)
end

-- A florist's shelves: four pots in flower, then a cactus, ivy trailing over the edge, a
-- succulent and a watering can.
local function drawPots(q: R)
	local M = "SmoothPlastic"
	local y = SHELF[1]
	local blooms = { { CORAL, BUTTER }, { BLUSH, WHITE }, { LILAC, BLUSH }, { BUTTER, BERRY } }
	for i, x in { -1.4, -0.47, 0.47, 1.4 } do
		q:cyl(x, y + 0.225, -0.05, 0.45, 0.55, "y", CLAY, M)
		q:lump(CFrame.new(x, y + 0.6, -0.05) * CFrame.Angles(0, i, 0), 0.7, 0.42, 0.6, LEAF, M)
		q:lump(CFrame.new(x - 0.14, y + 0.8, -0.12), 0.24, 0.2, 0.24, blooms[i][1], M)
		q:lump(CFrame.new(x + 0.16, y + 0.76, 0.05), 0.22, 0.2, 0.22, blooms[i][2], M)
	end
	y = SHELF[2]
	q:cyl(-1.35, y + 0.225, -0.05, 0.45, 0.5, "y", CLAY, M)
	q:cyl(-1.35, y + 0.8, -0.05, 0.75, 0.3, "y", SAGE, M)
	q:lump(CFrame.new(-1.12, y + 0.9, -0.05) * CFrame.Angles(0, 0, math.rad(-30)), 0.16, 0.4, 0.16, SAGE, M)
	q:cyl(-0.4, y + 0.225, -0.05, 0.45, 0.55, "y", rgb(214, 204, 186), M)
	q:lump(CFrame.new(-0.4, y + 0.5, -0.15), 0.7, 0.35, 0.55, LEAF_DARK, M)
	q:lump(CFrame.new(-0.45, y + 0.15, -0.36), 0.42, 0.6, 0.26, LEAF, M)
	q:cyl(0.45, y + 0.2, -0.05, 0.4, 0.5, "y", CLAY, M)
	q:cone(0.45, y + 0.58, -0.05, 0.36, 0.5, LEAF_LIGHT, M)
	q:cyl(1.3, y + 0.225, -0.05, 0.45, 0.5, "y", rgb(120, 150, 140), M)
	rod(q, Vector3.new(1.45, y + 0.25, -0.1), Vector3.new(1.75, y + 0.6, -0.35), 0.08, rgb(120, 150, 140), M)
	q:block(1.12, y + 0.45, -0.08, 1.48, y + 0.62, -0.02, rgb(120, 150, 140), M)
end

-- A post office's shelves: parcels tied with string and bundles of letters.
local function drawParcels(q: R)
	local M = "SmoothPlastic"
	local string = rgb(236, 226, 204)
	local function parcel(x: number, y: number, sx: number, sy: number, sz: number, yaw: number, c: Color3)
		local cf = CFrame.new(x, y + sy / 2, -0.08) * CFrame.Angles(0, math.rad(yaw), 0)
		q:boxAt(cf, sx, sy, sz, c, M)
		q:boxAt(cf, sx + 0.06, sy + 0.06, 0.08, string, M)
	end
	local y = SHELF[1]
	parcel(-1.15, y, 1.2, 0.9, 0.6, 0, KRAFT)
	parcel(0.15, y, 1.0, 0.7, 0.62, 4, rgb(214, 182, 140))
	parcel(1.25, y, 0.8, 1.0, 0.6, -3, rgb(186, 150, 108))
	q:block(-1.55, y + 0.96, -0.3, -1.1, y + 0.99, 0.0, WHITE, M) -- a label on the first
	y = SHELF[2]
	parcel(-1.2, y, 1.1, 0.6, 0.6, 3, rgb(214, 182, 140))
	parcel(-1.2, y + 0.6, 0.8, 0.45, 0.5, -6, CREAM)
	for i, x in { 0.2, 0.75, 1.3 } do
		q:block(x - 0.25, y, -0.35, x + 0.25, y + 0.5 + i * 0.08, 0.2, if i == 2 then SKY else WHITE, M)
	end
	q:block(0.15, y + 0.2, -0.38, 0.25, y + 0.3, 0.23, BERRY, M) -- the band round a bundle
end

local GOODS: { [string]: (R) -> () } = {
	booksA = drawBooksA,
	booksB = drawBooksB,
	loaves = drawLoaves,
	jars = drawJars,
	folds = drawFolds,
	toys = drawToys,
	pots = drawPots,
	parcels = drawParcels,
}

-- A case with goods on it: `lower` on the bottom two shelves, `upper` on the top two.
local function shelves(r: R, f: CFrame, lower: string, upper: string)
	stamp(r, f, "case", drawCase)
	solid(r, f, -2.0, 0, -0.5, 2.0, 6.6, 0.5)
	stamp(r, f, lower, GOODS[lower])
	stamp(r, f * CFrame.new(0, SHELF[3] - SHELF[1], 0), upper, GOODS[upper])
end

-- A row of `n` cases against a wall, the first one's middle at `f` and the rest along its X.
local function shelfRow(r: R, f: CFrame, n: number, goods: { string })
	for i = 0, n - 1 do
		shelves(r, f * CFrame.new(i * CASE_STEP, 0, 0), goods[(2 * i) % #goods + 1], goods[(2 * i + 1) % #goods + 1])
	end
end

-- Furniture ------------------------------------------------------------------------------------------
-- Each is drawn round its own middle on the floor, its front toward -Z.

-- A shop counter, 6.4 wide: a panelled front, a top that overhangs, a shelf on the shopkeeper's
-- side (+Z).
local function drawCounter(q: R)
	local M = "Wood"
	q:block(-2.9, 0.3, -0.9, 2.9, 3.0, -0.72, shade(WOOD, 0.84), M)
	q:block(-3.05, 0, -0.96, -2.9, 3.0, 0.85, WOOD, M)
	q:block(2.9, 0, -0.96, 3.05, 3.0, 0.85, WOOD, M)
	q:block(-2.9, 0, -0.8, 2.9, 0.3, -0.72, shade(WOOD, 0.7), M)
	q:block(-2.9, 0, -0.72, 2.9, 0.42, 0.85, WOOD, M)
	q:block(-2.9, 1.5, -0.72, 2.9, 1.62, 0.85, WOOD, M)
	q:block(-3.25, 3.0, -1.05, 3.25, 3.3, 1.0, shade(WOOD, 1.08), M)
	q:block(-2.9, 2.55, -0.96, 2.9, 2.85, -0.9, WOOD, M)
	q:block(-2.9, 0.3, -0.96, 2.9, 0.62, -0.9, WOOD, M)
	for _, x in { -1.45, 0, 1.45 } do
		q:block(x - 0.15, 0.62, -0.96, x + 0.15, 2.55, -0.9, WOOD, M)
	end
end

local function counter(r: R, f: CFrame)
	stamp(r, f, "counter", drawCounter)
	solid(r, f, -3.05, 0, -0.96, 3.05, 3.3, 0.85)
end

-- What stands on a counter: the till turned to the shopkeeper, a card reader for the customer, a
-- bell, a jar of sweets, and paper bags and a ledger on the shelf underneath.
local function drawTill(q: R)
	local M = "SmoothPlastic"
	local y = 3.3
	local body, light = rgb(84, 86, 96), rgb(120, 124, 134)
	q:block(1.0, y, -0.35, 2.6, y + 0.36, 0.6, body, M)
	q:block(1.1, y + 0.06, 0.6, 2.5, y + 0.28, 0.66, light, M)
	q:boxAt(CFrame.new(1.8, y + 0.42, 0.25) * CFrame.Angles(math.rad(16), 0, 0), 1.2, 0.1, 0.55, INK, M)
	q:block(1.72, y + 0.36, -0.25, 1.88, y + 0.9, -0.1, body, M)
	local screen = CFrame.new(1.8, y + 1.15, -0.12) * CFrame.Angles(math.rad(-12), 0, 0)
	q:boxAt(screen, 1.1, 0.75, 0.1, INK, M)
	q:boxAt(screen * CFrame.new(0, 0, 0.07), 0.94, 0.6, 0.04, rgb(150, 190, 200), M)
	q:block(0.35, y, 0.0, 0.85, y + 0.3, 0.55, body, M)
	q:cyl(0.6, y + 0.36, 0.3, 0.36, 0.24, "x", WHITE, M)
	q:boxAt(CFrame.new(0.2, y + 0.12, -0.7) * CFrame.Angles(math.rad(-20), 0, 0), 0.4, 0.1, 0.6, INK, M)
	q:cyl(-0.9, y + 0.03, -0.55, 0.06, 0.36, "y", BRASS, M)
	q:ball(-0.9, y + 0.18, -0.55, 0.3, BRASS, M)
	q:cyl(-0.9, y + 0.345, -0.55, 0.05, 0.08, "y", BRASS, M)
	q:cyl(-1.8, y + 0.275, -0.45, 0.55, 0.5, "y", BLUSH, M)
	q:cyl(-1.8, y + 0.6, -0.45, 0.1, 0.56, "y", BERRY, M)
	q:block(-2.5, 1.62, 0.0, -1.6, 1.8, 0.7, KRAFT, M)
	q:block(-2.45, 1.8, 0.05, -1.65, 1.95, 0.65, shade(KRAFT, 1.08), M)
	q:block(-1.2, 1.62, 0.1, -0.5, 1.72, 0.6, NAVY, M)
	q:cyl(-0.2, y + 0.16, 0.5, 0.32, 0.3, "y", CREAM, M)
end

-- A plant in a pot on the floor: a square pot with a rim, soil, three stems and big leaves.
local function drawPlant(q: R)
	local M = "SmoothPlastic"
	local pot = rgb(226, 220, 208)
	q:block(-0.65, 0, -0.65, 0.65, 1.2, 0.65, pot, M)
	q:block(-0.72, 1.1, -0.72, 0.72, 1.28, 0.72, shade(pot, 0.92), M)
	q:block(-0.6, 1.2, -0.6, 0.6, 1.31, 0.6, rgb(92, 66, 46), M)
	local tops = {
		Vector3.new(-0.35, 3.4, 0.1),
		Vector3.new(0.4, 4.1, -0.15),
		Vector3.new(0.05, 3.0, 0.4),
	}
	for _, t in tops do
		rod(q, Vector3.new(t.X * 0.2, 1.25, t.Z * 0.2), t, 0.09, rgb(96, 120, 70), M)
	end
	local greens = { LEAF, LEAF_DARK, LEAF_LIGHT }
	for i = 1, 12 do
		local a = i * 2.4
		local h = 1.75 + (i - 1) * 0.22
		local out = 0.45 + (i % 3) * 0.12
		local p = Vector3.new(math.cos(a) * out, h, math.sin(a) * out)
		q:lump(
			CFrame.new(p) * CFrame.Angles(0, -a, 0) * CFrame.Angles(0, 0, math.rad(22 + (i % 4) * 8)),
			1.15,
			0.14,
			0.6,
			greens[i % 3 + 1],
			M
		)
	end
	q:lump(CFrame.new(0, 3.3, 0), 0.9, 0.8, 0.9, LEAF_DARK, M)
	q:lump(CFrame.new(0.2, 4.15, -0.1), 0.7, 0.6, 0.7, LEAF, M)
end

-- A lamp hanging from the ceiling, its origin on the plaster: a plate, a cord and a cone of a
-- shade. The light itself is the disc under it (lamp below), which can't be in a piece.
local function drawPendant(q: R)
	local M = "Metal"
	local shadeColor = rgb(70, 100, 94)
	q:block(-0.22, -0.08, -0.22, 0.22, 0, 0.22, DARK, M)
	q:cyl(0, -0.8, 0, 1.44, 0.07, "y", DARK, M)
	q:cyl(0, -1.56, 0, 0.12, 0.34, "y", BRASS, M)
	q:cone(0, -1.95, 0, 0.8, 1.7, shadeColor, M)
end

-- Pictures, their back at z = 0 and their bottom at y = 0: a frame of four bars, the canvas set
-- back in it, and what is painted in flat shapes, each layer 0.03 in front of the one behind so no
-- two lie in one plane.
local function frameOf(q: R, w: number, h: number, color: Color3)
	local M = "SmoothPlastic"
	q:block(-w / 2, 0, -0.2, w / 2, 0.18, 0, color, M)
	q:block(-w / 2, h - 0.18, -0.2, w / 2, h, 0, color, M)
	q:block(-w / 2, 0.18, -0.2, -w / 2 + 0.18, h - 0.18, 0, color, M)
	q:block(w / 2 - 0.18, 0.18, -0.2, w / 2, h - 0.18, 0, color, M)
end

-- A flat triangle painted on a picture, its front at depth z.
local function paintTri(q: R, a: Vector2, b: Vector2, c: Vector2, z: number, color: Color3)
	q:tri(
		Vector3.new(a.X, a.Y, z + 0.015),
		Vector3.new(b.X, b.Y, z + 0.015),
		Vector3.new(c.X, c.Y, z + 0.015),
		0.03,
		color,
		"SmoothPlastic"
	)
end

-- Hills, a tree, a cottage with a red roof, a cloud and the sun.
local function drawLandscape(q: R)
	local M = "SmoothPlastic"
	frameOf(q, 3.0, 2.2, rgb(190, 150, 90))
	q:block(-1.32, 0.18, -0.07, 1.32, 2.02, 0, rgb(200, 218, 228), M)
	q:cyl(0.75, 1.55, -0.085, 0.03, 0.42, "z", rgb(240, 214, 140), M)
	q:block(-0.6, 1.62, -0.1, -0.05, 1.74, -0.07, WHITE, M)
	q:block(-0.45, 1.74, -0.1, -0.2, 1.84, -0.07, WHITE, M)
	paintTri(q, Vector2.new(-1.32, 0.18), Vector2.new(0.4, 0.18), Vector2.new(-0.55, 1.05), -0.1, rgb(150, 178, 150))
	paintTri(q, Vector2.new(-0.35, 0.18), Vector2.new(1.32, 0.18), Vector2.new(0.75, 0.85), -0.13, rgb(112, 150, 98))
	q:block(-0.98, 0.62, -0.13, -0.9, 0.95, -0.1, WALNUT, M)
	q:cyl(-0.94, 1.08, -0.145, 0.03, 0.42, "z", LEAF_DARK, M)
	q:block(0.6, 0.3, -0.16, 0.9, 0.52, -0.13, CREAM, M)
	q:block(0.56, 0.52, -0.16, 0.94, 0.62, -0.13, BERRY, M)
end

-- A jug of flowers on a table, in a dark gold frame.
local function drawStillLife(q: R)
	local M = "SmoothPlastic"
	frameOf(q, 2.2, 2.8, rgb(150, 116, 70))
	q:block(-0.92, 0.18, -0.07, 0.92, 2.62, 0, rgb(64, 92, 96), M)
	q:block(-0.92, 0.18, -0.1, 0.92, 0.75, -0.07, rgb(150, 110, 80), M)
	q:cyl(0, 1.06, -0.115, 0.03, 0.62, "z", CREAM, M)
	q:block(-0.12, 1.3, -0.13, 0.12, 1.6, -0.1, CREAM, M)
	local heads: { { x: number, y: number, c: Color3 } } = {
		{ x = -0.38, y = 1.85, c = CORAL },
		{ x = 0.0, y = 2.2, c = BUTTER },
		{ x = 0.38, y = 1.9, c = BLUSH },
		{ x = 0.02, y = 1.68, c = WHITE },
	}
	for _, f in heads do
		q:cyl(f.x, f.y, -0.145, 0.03, 0.36, "z", f.c, M)
	end
	for _, s in { -1, 1 } do
		q:boxAt(CFrame.new(s * 0.52, 1.6, -0.115) * CFrame.Angles(0, 0, math.rad(s * 30)), 0.5, 0.14, 0.03, LEAF, M)
	end
end

-- A rug, 5 by 7: a cream border, a terracotta field, a medallion and corners, fringes at the ends.
-- Each layer stands 0.03 above the last so none of them flickers.
local function drawRug(q: R)
	local M = "Fabric"
	q:block(-2.5, 0, -3.5, 2.5, 0.03, 3.5, rgb(232, 218, 190), M)
	q:block(-2.13, 0, -3.13, 2.13, 0.06, 3.13, rgb(172, 96, 84), M)
	q:block(-0.88, 0, -1.37, 0.88, 0.09, 1.37, rgb(226, 196, 140), M)
	q:block(-0.33, 0, -0.57, 0.33, 0.12, 0.57, NAVY, M)
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			q:block(sx * 1.6 - 0.24, 0, sz * 2.6 - 0.24, sx * 1.6 + 0.24, 0.09, sz * 2.6 + 0.24, NAVY, M)
		end
		q:block(-2.3, 0, sx * 3.5, 2.3, 0.03, sx * 3.75, rgb(236, 226, 204), M)
	end
end

-- A little round table with a cup on each side and a flower, and a chair either side of it.
local function drawCafeSet(q: R)
	local M = "SmoothPlastic"
	local frame, seat = rgb(120, 84, 60), rgb(150, 108, 76)
	q:cyl(0, 0.08, 0, 0.16, 1.2, "y", DARK, M)
	q:cyl(0, 1.33, 0, 2.34, 0.2, "y", DARK, M)
	q:cyl(0, 2.56, 0, 0.12, 2.4, "y", PALE, M)
	for _, s in { -1, 1 } do
		local x = s * 1.85
		q:cyl(x, 1.57, 0, 0.14, 1.2, "y", seat, M)
		for _, lx in { -0.38, 0.38 } do
			for _, lz in { -0.38, 0.38 } do
				q:block(x + lx - 0.055, 0, lz - 0.055, x + lx + 0.055, 1.5, lz + 0.055, frame, M)
			end
		end
		local bx = x + s * 0.5
		for _, lz in { -0.42, 0.42 } do
			q:block(bx - 0.055, 1.64, lz - 0.055, bx + 0.055, 3.1, lz + 0.055, frame, M)
		end
		q:block(bx - 0.07, 2.82, -0.48, bx + 0.07, 3.1, 0.48, frame, M)
		q:cyl(s * 0.55, 2.64, 0.15, 0.04, 0.55, "y", WHITE, M)
		q:cyl(s * 0.55, 2.8, 0.15, 0.28, 0.34, "y", CREAM, M)
	end
	q:cyl(0, 2.83, -0.4, 0.42, 0.22, "y", SAGE, M)
	q:ball(0, 3.12, -0.4, 0.26, CORAL, M)
end

-- A sofa, 5.6 wide: cushions to sit on and lean on, rolled arms, short legs and two cushions.
local SOFA = rgb(104, 136, 160)
local function drawSofa(q: R)
	local M = "Fabric"
	q:block(-2.4, 0.35, -1.1, 2.4, 1.15, 1.1, shade(SOFA, 0.9), M)
	q:block(-2.37, 1.15, -1.16, -0.03, 1.6, 0.6, SOFA, M)
	q:block(0.03, 1.15, -1.16, 2.37, 1.6, 0.6, SOFA, M)
	q:block(-2.4, 1.15, 0.6, 2.4, 2.9, 1.2, shade(SOFA, 0.86), M)
	q:block(-2.34, 1.6, 0.22, -0.04, 2.7, 0.6, shade(SOFA, 1.05), M)
	q:block(0.04, 1.6, 0.22, 2.34, 2.7, 0.6, shade(SOFA, 1.05), M)
	for _, s in { -1, 1 } do
		q:block(s * 2.4, 0.35, -1.2, s * 2.8, 2.1, 1.2, shade(SOFA, 0.94), M)
		q:cyl(s * 2.6, 2.1, 0, 2.46, 0.56, "z", shade(SOFA, 0.94), M)
		q:block(s * 2.55 - 0.13, 0, -1.05, s * 2.55 + 0.13, 0.35, -0.8, WALNUT, M)
		q:block(s * 2.55 - 0.13, 0, 0.8, s * 2.55 + 0.13, 0.35, 1.05, WALNUT, M)
	end
	q:lump(CFrame.new(-1.85, 2.0, 0.25) * CFrame.Angles(math.rad(-15), 0, math.rad(12)), 0.9, 0.9, 0.3, MUSTARD, M)
	q:lump(CFrame.new(1.85, 2.0, 0.25) * CFrame.Angles(math.rad(-15), 0, math.rad(-12)), 0.9, 0.9, 0.3, CREAM, M)
end

-- A low table with magazines, a mug and a bowl of fruit on it, and books on the shelf below.
local function drawLowTable(q: R)
	local M = "SmoothPlastic"
	q:block(-1.6, 1.22, -0.9, 1.6, 1.38, 0.9, WALNUT, M)
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			q:block(
				sx * 1.42 - 0.09,
				0,
				sz * 0.72 - 0.09,
				sx * 1.42 + 0.09,
				1.22,
				sz * 0.72 + 0.09,
				shade(WALNUT, 0.85),
				M
			)
		end
	end
	q:block(-1.33, 0.32, -0.63, 1.33, 0.42, 0.63, shade(WALNUT, 0.92), M)
	q:boxAt(CFrame.new(-0.7, 1.4, 0.1) * CFrame.Angles(0, math.rad(12), 0), 0.9, 0.04, 1.2, BLUSH, M)
	q:boxAt(CFrame.new(-0.55, 1.44, 0.0) * CFrame.Angles(0, math.rad(-8), 0), 0.9, 0.04, 1.2, SKY, M)
	q:cyl(0.35, 1.53, -0.45, 0.3, 0.3, "y", CREAM, M)
	q:cyl(0.85, 1.48, 0.25, 0.2, 0.8, "y", rgb(110, 150, 160), M)
	q:ball(0.7, 1.66, 0.2, 0.3, rgb(184, 80, 72), M)
	q:ball(1.0, 1.66, 0.32, 0.3, MUSTARD, M)
	q:ball(0.85, 1.7, 0.08, 0.28, LEAF_LIGHT, M)
	q:block(-1.1, 0.42, -0.4, -0.2, 0.6, 0.35, NAVY, M)
	q:block(-1.05, 0.6, -0.35, -0.25, 0.74, 0.3, rgb(168, 86, 78), M)
end

-- Four seats joined on a beam, for waiting on (a clinic, a station, the post office, a hall).
local function drawSeats(q: R)
	local M = "SmoothPlastic"
	local seat = rgb(86, 140, 136)
	q:block(-3.7, 1.0, -0.15, 3.7, 1.2, 0.15, STEEL, M)
	for _, x in { -2.6, 2.6 } do
		q:block(x - 0.1, 0.1, -0.1, x + 0.1, 1.0, 0.1, STEEL, M)
		q:block(x - 0.12, 0, -0.75, x + 0.12, 0.1, 0.75, STEEL, M)
	end
	for i = 0, 3 do
		local c = -2.85 + i * 1.9
		q:block(c - 0.85, 1.2, -0.7, c + 0.85, 1.42, 0.55, seat, M)
		q:boxAt(CFrame.new(c, 2.25, 0.68) * CFrame.Angles(math.rad(8), 0, 0), 1.7, 1.55, 0.16, shade(seat, 0.92), M)
	end
	for i = 0, 4 do
		local x = -3.8 + i * 1.9
		q:block(x - 0.06, 1.42, -0.55, x + 0.06, 2.1, 0.5, STEEL, M)
	end
end

-- A wooden chair: a seat, four legs, two posts, a top rail and a slat.
local function drawChair(q: R)
	local M = "SmoothPlastic"
	q:block(-0.8, 1.42, -0.8, 0.8, 1.58, 0.8, shade(WALNUT, 1.08), M)
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			q:block(sx * 0.66 - 0.07, 0, sz * 0.66 - 0.07, sx * 0.66 + 0.07, 1.42, sz * 0.66 + 0.07, WALNUT, M)
		end
		q:block(sx * 0.66 - 0.07, 1.58, 0.6, sx * 0.66 + 0.07, 3.3, 0.74, WALNUT, M)
	end
	q:block(-0.59, 2.9, 0.62, 0.59, 3.25, 0.72, WALNUT, M)
	q:block(-0.59, 2.2, 0.63, 0.59, 2.4, 0.71, WALNUT, M)
end

-- A desk with drawers on the sitter's side (+Z), a lamp, books, papers, a pen pot, a mug and an
-- apple on it, and a chair behind.
local function drawDesk(q: R)
	local M = "SmoothPlastic"
	local front = shade(WALNUT, 1.1)
	q:block(-2.2, 2.45, -1.1, 2.2, 2.6, 1.1, WALNUT, M)
	for _, sx in { -1, 1 } do
		q:block(sx * 1.5 - 0.6, 0, -1.0, sx * 1.5 + 0.6, 2.45, 1.0, shade(WALNUT, 0.9), M)
		for k = 0, 2 do
			q:block(sx * 1.5 - 0.52, 0.15 + k * 0.76, 1.0, sx * 1.5 + 0.52, 0.83 + k * 0.76, 1.05, front, M)
		end
	end
	q:block(-0.9, 0.9, -0.95, 0.9, 2.45, -0.85, shade(WALNUT, 0.85), M)
	q:cyl(-1.6, 2.65, -0.5, 0.1, 0.5, "y", FOREST, M)
	rod(q, Vector3.new(-1.6, 2.7, -0.5), Vector3.new(-1.35, 3.55, -0.3), 0.08, DARK, M)
	q:add({
		shape = "Cone",
		cf = CFrame.new(-1.22, 3.5, -0.2) * CFrame.Angles(0, 0, math.rad(-35)),
		size = Vector3.new(0.6, 0.45, 0.6),
		color = FOREST,
		mat = M,
	})
	q:block(0.4, 2.6, -0.3, 1.5, 2.72, 0.5, NAVY, M)
	q:block(0.45, 2.72, -0.25, 1.4, 2.84, 0.42, rgb(168, 86, 78), M)
	q:boxAt(CFrame.new(-0.3, 2.615, 0.25) * CFrame.Angles(0, math.rad(-10), 0), 1.0, 0.03, 1.3, WHITE, M)
	q:cyl(1.75, 2.8, 0.6, 0.4, 0.3, "y", MUSTARD, M)
	q:cyl(1.0, 2.76, -0.65, 0.32, 0.3, "y", CREAM, M)
	q:ball(-0.6, 2.77, -0.6, 0.34, rgb(184, 80, 72), M)
	q:cyl(0, 0.08, 2.1, 0.16, 1.2, "y", DARK, M)
	q:cyl(0, 0.83, 2.1, 1.34, 0.16, "y", DARK, M)
	q:block(-0.8, 1.5, 1.4, 0.8, 1.72, 2.8, NAVY, M)
	q:block(-0.75, 1.72, 2.7, 0.75, 3.4, 2.92, NAVY, M)
end

-- A bed, its head toward +Z: an upholstered base on legs, a headboard with a rolled top, a
-- mattress, the sheet turned down, pillows, a cushion and a throw over the foot. The blanket is a
-- part of its own so it can take the house's colour (home, below).
local function drawBed(q: R)
	local M = "Fabric"
	local frame, sheet = rgb(214, 196, 170), rgb(244, 240, 230)
	q:block(-2.0, 0.35, -3.5, 2.0, 1.2, 3.4, frame, M)
	for _, sx in { -1, 1 } do
		for _, z in { -3.3, 3.2 } do
			q:block(sx * 1.8 - 0.1, 0, z - 0.1, sx * 1.8 + 0.1, 0.35, z + 0.1, WALNUT, M)
		end
	end
	q:block(-2.1, 0, 3.4, 2.1, 3.6, 3.7, shade(frame, 0.9), M)
	q:cyl(0, 3.6, 3.55, 4.26, 0.36, "x", shade(frame, 0.9), M)
	q:block(-1.85, 1.2, -3.35, 1.85, 1.85, 3.35, sheet, M)
	q:block(-1.98, 1.6, 1.15, 1.98, 1.98, 1.6, sheet, M)
	for _, x in { -0.85, 0.85 } do
		q:lump(CFrame.new(x, 2.05, 2.75) * CFrame.Angles(math.rad(-12), 0, 0), 1.5, 0.45, 0.9, CREAM, M)
	end
	q:lump(CFrame.new(0, 2.25, 2.2) * CFrame.Angles(math.rad(-20), 0, 0), 0.9, 0.7, 0.28, SAGE, M)
	q:block(-1.98, 1.9, -3.0, 1.98, 2.0, -2.35, MUSTARD, M)
end

-- A chest of drawers with a lamp, a photo in a frame and a little plant on it.
local function drawDresser(q: R)
	local M = "SmoothPlastic"
	q:block(-1.5, 0.3, -0.65, 1.5, 2.85, 0.7, WALNUT, M)
	q:block(-1.62, 2.85, -0.78, 1.62, 3.0, 0.75, shade(WALNUT, 0.9), M)
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			q:block(sx * 1.32 - 0.1, 0, sz * 0.45 - 0.1, sx * 1.32 + 0.1, 0.3, sz * 0.45 + 0.1, shade(WALNUT, 0.8), M)
		end
	end
	for k = 0, 2 do
		local y = 0.42 + k * 0.8
		q:block(-1.38, y, -0.71, 1.38, y + 0.7, -0.65, shade(WALNUT, 1.12), M)
		q:ball(-0.7, y + 0.35, -0.76, 0.14, BRASS, M)
		q:ball(0.7, y + 0.35, -0.76, 0.14, BRASS, M)
	end
	q:cyl(-0.95, 3.12, 0.1, 0.24, 0.5, "y", CREAM, M)
	q:cyl(-0.95, 3.5, 0.1, 0.55, 0.08, "y", BRASS, M)
	q:cone(-0.95, 4.0, 0.1, 0.7, 0.95, rgb(232, 214, 180), M)
	local photo = CFrame.new(0.15, 3.38, 0.2) * CFrame.Angles(math.rad(12), math.rad(15), 0)
	q:boxAt(photo, 0.62, 0.76, 0.06, BRASS, M)
	q:boxAt(photo * CFrame.new(0, 0, -0.045), 0.48, 0.6, 0.03, SKY, M)
	q:cyl(0.95, 3.18, -0.1, 0.36, 0.42, "y", CLAY, M)
	q:lump(CFrame.new(0.95, 3.55, -0.1), 0.6, 0.5, 0.55, LEAF, M)
end

-- A clock for a wall, its middle at the origin: a dark rim, a face, the hands and four marks.
local function drawClock(q: R)
	local M = "SmoothPlastic"
	q:block(-0.12, -0.12, -0.04, 0.12, 0.12, 0, DARK, M)
	q:cyl(0, 0, -0.1, 0.12, 1.6, "z", DARK, M)
	q:cyl(0, 0, -0.175, 0.03, 1.36, "z", PAPER, M)
	q:block(-0.04, -0.04, -0.23, 0.04, 0.5, -0.19, INK, M)
	q:boxAt(CFrame.new(0.15, -0.1, -0.21) * CFrame.Angles(0, 0, math.rad(-56)), 0.06, 0.38, 0.04, INK, M)
	for k = 0, 3 do
		local a = k * math.pi / 2
		q:boxAt(
			CFrame.new(math.sin(a) * 0.56, math.cos(a) * 0.56, -0.205) * CFrame.Angles(0, 0, -a),
			0.06,
			0.16,
			0.03,
			INK,
			M
		)
	end
	q:cyl(0, 0, -0.24, 0.02, 0.12, "z", BRASS, M)
end

-- A board of notices for a wall, its back at z = 0 and its bottom at y = 0: cork in a frame with
-- papers pinned on it, every other one a little further out so no two lie in one plane.
local function drawNotices(q: R)
	local M = "SmoothPlastic"
	q:block(-1.62, 0.16, -0.08, 1.62, 2.24, 0, rgb(196, 160, 118), M)
	q:block(-1.8, 0, -0.14, 1.8, 0.16, 0, WALNUT, M)
	q:block(-1.8, 2.24, -0.14, 1.8, 2.4, 0, WALNUT, M)
	q:block(-1.8, 0.16, -0.14, -1.62, 2.24, 0, WALNUT, M)
	q:block(1.62, 0.16, -0.14, 1.8, 2.24, 0, WALNUT, M)
	type Note = { x: number, y: number, w: number, h: number, turn: number, c: Color3 }
	local notes: { Note } = {
		{ x = -1.05, y = 1.55, w = 0.75, h = 0.9, turn = 4, c = CREAM },
		{ x = -0.1, y = 1.7, w = 0.7, h = 0.6, turn = -6, c = BUTTER },
		{ x = 0.95, y = 1.5, w = 0.75, h = 0.95, turn = 3, c = WHITE },
		{ x = -1.0, y = 0.62, w = 0.8, h = 0.66, turn = -3, c = BLUSH },
		{ x = 0.0, y = 0.7, w = 0.66, h = 0.8, turn = 7, c = SKY },
		{ x = 1.0, y = 0.55, w = 0.62, h = 0.5, turn = -4, c = CREAM },
	}
	local pins = { CORAL, TEAL, MUSTARD, BERRY }
	for i, n in notes do
		local z = if i % 2 == 0 then -0.125 else -0.095
		q:boxAt(CFrame.new(n.x, n.y, z) * CFrame.Angles(0, 0, math.rad(n.turn)), n.w, n.h, 0.03, n.c, M)
		if i <= 4 then
			q:ball(n.x, n.y + n.h / 2 - 0.12, -0.16, 0.1, pins[i], M)
		end
	end
end

-- A row of four cinema seats: a plinth, seats, backs leaning back and padded arms between.
local function drawCinemaSeats(q: R)
	local M = "Fabric"
	local seat, back, arm = rgb(172, 78, 84), rgb(156, 68, 76), rgb(80, 66, 74)
	q:block(-3.9, 0, -0.85, 3.9, 0.3, 0.85, arm, M)
	for i = 0, 3 do
		local c = -2.925 + i * 1.95
		q:block(c - 0.82, 1.0, -0.85, c + 0.82, 1.38, 0.35, seat, M)
		q:boxAt(CFrame.new(c, 2.35, 0.62) * CFrame.Angles(math.rad(10), 0, 0), 1.64, 2.3, 0.4, back, M)
	end
	for i = 0, 4 do
		local x = -3.9 + i * 1.95
		q:block(x - 0.1, 0.3, -0.75, x + 0.1, 1.95, 0.6, arm, M)
		q:block(x - 0.14, 1.95, -0.85, x + 0.14, 2.06, 0.6, shade(arm, 1.2), M)
	end
end

-- A pupil's desk with a shelf under the top, an open book and a pencil, and the chair on the
-- door side: the pupil faces +Z, the board.
local function drawSchoolDesk(q: R)
	local M = "SmoothPlastic"
	q:block(-1.3, 2.35, -0.8, 1.3, 2.5, 0.8, PALE, M)
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			q:block(sx * 1.15 - 0.06, 0, sz * 0.65 - 0.06, sx * 1.15 + 0.06, 2.35, sz * 0.65 + 0.06, STEEL, M)
		end
	end
	q:block(-1.09, 1.9, -0.59, 1.09, 1.98, 0.59, shade(PALE, 0.85), M)
	q:boxAt(CFrame.new(-0.25, 2.53, 0.05) * CFrame.Angles(0, math.rad(8), math.rad(-6)), 0.5, 0.04, 0.7, WHITE, M)
	q:boxAt(CFrame.new(0.24, 2.53, 0.07) * CFrame.Angles(0, math.rad(8), math.rad(6)), 0.5, 0.04, 0.7, WHITE, M)
	q:cyl(0.75, 2.53, -0.2, 0.6, 0.05, "x", MUSTARD, M)
	local seat = rgb(214, 176, 96)
	q:block(-0.75, 1.42, -2.45, 0.75, 1.56, -1.05, seat, M)
	q:block(-0.75, 1.56, -2.55, 0.75, 2.95, -2.43, seat, M)
	for _, sx in { -1, 1 } do
		for _, z in { -2.35, -1.15 } do
			q:block(sx * 0.62 - 0.05, 0, z - 0.05, sx * 0.62 + 0.05, 1.42, z + 0.05, STEEL, M)
		end
	end
end

-- A blackboard for a wall, its back at z = 0: a wooden frame, a tray with chalk and a duster,
-- and the lesson written up in words of chalk with a little drawing beside it.
local function drawBlackboard(q: R)
	local M = "SmoothPlastic"
	local chalk = rgb(232, 232, 222)
	q:block(-5.5, 0.4, -0.1, 5.5, 3.6, 0, rgb(56, 82, 74), M)
	q:block(-5.7, 0.22, -0.18, 5.7, 0.4, 0, WOOD, M)
	q:block(-5.7, 3.6, -0.18, 5.7, 3.78, 0, WOOD, M)
	q:block(-5.7, 0.4, -0.18, -5.5, 3.6, 0, WOOD, M)
	q:block(5.5, 0.4, -0.18, 5.7, 3.6, 0, WOOD, M)
	q:block(-5.7, 0, -0.5, 5.7, 0.22, 0, WOOD, M)
	q:block(-5.7, 0.22, -0.5, 5.7, 0.3, -0.42, WOOD, M)
	q:cyl(-3.2, 0.27, -0.3, 0.5, 0.1, "x", chalk, M)
	q:cyl(-2.4, 0.27, -0.25, 0.35, 0.1, "x", rgb(240, 200, 200), M)
	q:block(2.6, 0.22, -0.42, 3.3, 0.42, -0.2, rgb(214, 180, 120), M)
	local lines: { { y: number, words: { number } } } = {
		{ y = 3.05, words = { 1.3, 0.8, 1.5 } },
		{ y = 2.55, words = { 0.9, 1.6, 0.7 } },
		{ y = 2.05, words = { 1.8, 1.1 } },
		{ y = 1.55, words = { 0.7, 1.2, 0.9 } },
	}
	for _, l in lines do
		local x = -4.9
		for _, len in l.words do
			q:block(x, l.y, -0.13, x + len, l.y + 0.1, -0.1, chalk, M)
			x += len + 0.35
		end
	end
	q:cyl(3.9, 2.85, -0.115, 0.03, 0.6, "z", chalk, M)
	q:block(2.9, 1.2, -0.13, 4.3, 1.3, -0.1, chalk, M)
	q:block(3.1, 1.3, -0.13, 3.2, 2.0, -0.1, chalk, M)
	q:block(4.0, 1.3, -0.13, 4.1, 2.0, -0.1, chalk, M)
end

-- A hospital bed, its head toward +Z, on wheels, with a blanket, the sheet turned down, a pillow,
-- a rail up on one side and the notes clipped to the foot.
local function drawHospitalBed(q: R)
	local M = "SmoothPlastic"
	local frame, sheet, cover = rgb(176, 182, 190), rgb(244, 242, 236), rgb(176, 214, 206)
	q:block(-1.6, 1.0, -3.4, 1.6, 1.3, 3.4, frame, M)
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			q:cyl(sx * 1.35, 0.62, sz * 3.1, 0.76, 0.16, "y", frame, M)
			q:cyl(sx * 1.35, 0.15, sz * 3.1, 0.12, 0.3, "x", DARK, M)
		end
	end
	q:block(-1.5, 1.3, -3.3, 1.5, 1.85, 3.3, sheet, M)
	q:block(-1.55, 1.6, -3.36, 1.55, 1.92, 1.0, cover, M)
	q:block(-1.58, 1.62, 0.75, 1.58, 1.98, 1.15, sheet, M)
	q:lump(CFrame.new(0, 2.05, 2.6), 2.0, 0.45, 1.0, sheet, M)
	q:block(-1.6, 1.0, 3.4, 1.6, 3.4, 3.56, shade(frame, 1.1), M)
	q:block(-1.6, 1.0, -3.56, 1.6, 2.6, -3.4, shade(frame, 1.1), M)
	q:block(1.62, 1.55, -1.6, 1.7, 2.15, 1.6, frame, M)
	q:block(-0.4, 2.0, -3.62, 0.4, 2.45, -3.56, WHITE, M)
end

-- An old jar on a plinth, painted with a dark band, and the brass plate that says what it is.
local function drawExhibit(q: R)
	local M = "SmoothPlastic"
	local stone, band = rgb(236, 230, 218), rgb(222, 214, 200)
	local clay, paint = rgb(196, 124, 88), rgb(70, 60, 64)
	q:block(-1.3, 0, -1.3, 1.3, 0.3, 1.3, band, M)
	q:block(-1.1, 0.3, -1.1, 1.1, 2.4, 1.1, stone, M)
	q:block(-1.25, 2.4, -1.25, 1.25, 2.6, 1.25, band, M)
	q:block(-0.45, 1.55, -1.14, 0.45, 2.0, -1.1, rgb(176, 146, 92), M)
	q:cyl(0, 2.68, 0, 0.16, 0.62, "y", clay, M)
	q:lump(CFrame.new(0, 3.35, 0), 1.15, 1.3, 1.15, clay, M)
	q:cyl(0, 3.4, 0, 0.18, 1.24, "y", paint, M)
	q:cyl(0, 4.12, 0, 0.5, 0.42, "y", clay, M)
	q:cyl(0, 4.42, 0, 0.1, 0.62, "y", paint, M)
	for _, s in { -1, 1 } do
		q:boxAt(CFrame.new(s * 0.42, 3.95, 0) * CFrame.Angles(0, 0, s * math.rad(-25)), 0.1, 0.5, 0.12, clay, M)
	end
end

-- Lift doors for a wall, their back at z = 0: the opening, two doors, a frame proud of them, a
-- sill on the floor and the buttons beside. The lit sign over the doors is a part of its own.
local function drawLift(q: R)
	local M = "Metal"
	local frame, door = rgb(150, 154, 164), rgb(196, 200, 208)
	q:block(-2.4, 0, -0.18, 2.4, 6.6, 0, rgb(110, 114, 124), M)
	q:block(-1.9, 0.05, -0.26, -0.03, 6.0, -0.18, door, M)
	q:block(0.03, 0.05, -0.26, 1.9, 6.0, -0.18, door, M)
	q:block(-2.4, 0, -0.32, -1.9, 6.6, -0.18, frame, M)
	q:block(1.9, 0, -0.32, 2.4, 6.6, -0.18, frame, M)
	q:block(-1.9, 6.0, -0.32, 1.9, 6.6, -0.18, frame, M)
	q:block(-1.9, 0, -0.6, 1.9, 0.04, -0.18, frame, M)
	q:block(2.65, 2.8, -0.1, 3.05, 3.8, 0, frame, M)
	q:cyl(2.85, 3.1, -0.13, 0.06, 0.16, "z", rgb(236, 214, 160), M)
	q:cyl(2.85, 3.5, -0.13, 0.06, 0.16, "z", rgb(236, 214, 160), M)
end

-- The flats' post boxes for a wall, their back at z = 0: twelve doors with a slot in each.
local function drawMailboxes(q: R)
	local M = "Metal"
	q:block(-3.4, 2.2, -0.5, 3.4, 6.0, 0, rgb(150, 164, 160), M)
	for row = 0, 2 do
		for col = 0, 3 do
			local x = -2.52 + col * 1.68
			local y = 2.38 + row * 1.22
			q:block(x - 0.74, y, -0.55, x + 0.74, y + 1.08, -0.5, rgb(196, 176, 128), M)
			q:block(x - 0.42, y + 0.68, -0.58, x + 0.42, y + 0.8, -0.55, rgb(70, 72, 80), M)
		end
	end
end

-- A dressed figure for a shop window: a stand, a skirt and a bodice, arms, a head and a hat.
local function drawMannequin(q: R)
	local M = "SmoothPlastic"
	local form, dress, straw = rgb(238, 230, 216), rgb(112, 140, 170), rgb(222, 196, 140)
	q:block(-0.6, 0, -0.6, 0.6, 0.16, 0.6, DARK, M)
	q:cyl(0, 1.32, 0, 2.36, 0.12, "y", DARK, M)
	q:cone(0, 3.0, 0, 1.8, 1.7, dress, M)
	q:lump(CFrame.new(0, 3.95, 0), 1.0, 1.15, 0.62, dress, M)
	for _, s in { -1, 1 } do
		q:lump(CFrame.new(s * 0.62, 3.75, 0) * CFrame.Angles(0, 0, s * math.rad(8)), 0.24, 1.2, 0.26, form, M)
	end
	q:cyl(0, 4.65, 0, 0.3, 0.22, "y", form, M)
	q:ball(0, 5.05, 0, 0.6, form, M)
	q:cyl(0, 5.3, 0, 0.06, 1.1, "y", straw, M)
	q:cyl(0, 5.45, 0, 0.3, 0.55, "y", straw, M)
	q:cyl(0, 5.37, 0, 0.08, 0.61, "y", BERRY, M)
end

-- A rail of clothes on hangers, edge on to the bar: shirts, dresses and coats.
local GARMENTS = {
	SAGE,
	CREAM,
	NAVY,
	BLUSH,
	MUSTARD,
	rgb(120, 150, 176),
	BERRY,
	rgb(220, 208, 186),
	TEAL,
	CORAL,
}
local function drawRack(q: R)
	local M = "SmoothPlastic"
	for _, s in { -1, 1 } do
		q:block(s * 3.0 - 0.12, 0, -0.65, s * 3.0 + 0.12, 0.12, 0.65, STEEL, M)
		q:cyl(s * 3.0, 2.46, 0, 4.68, 0.16, "y", STEEL, M)
	end
	q:cyl(0, 4.7, 0, 6.24, 0.13, "x", STEEL, M)
	local lengths = { 1.9, 2.0, 2.8, 1.9, 2.5, 1.8, 2.9, 2.0, 2.4, 1.9 }
	for k = 1, 10 do
		local x = -2.48 + (k - 1) * 0.55
		local c = GARMENTS[k]
		q:block(x - 0.1, 4.3, -0.45, x + 0.1, 4.62, 0.45, c, M)
		q:block(x - 0.13, 4.62 - lengths[k], -0.6, x + 0.13, 4.3, 0.6, c, M)
	end
end

-- Cakes for a glass case whose floor is at 1.6 and whose glass shelf is at 2.55: a layer cake on
-- a stand, cupcakes, a tart and a roll, then croissants, macarons and doughnuts.
local function drawCakes(q: R)
	local M = "SmoothPlastic"
	local y = 1.6
	q:cyl(-2.0, y + 0.1, 0, 0.2, 0.4, "y", WHITE, M)
	q:cyl(-2.0, y + 0.225, 0, 0.05, 1.2, "y", WHITE, M)
	q:cyl(-2.0, y + 0.41, 0, 0.32, 1.0, "y", rgb(240, 214, 160), M)
	q:cyl(-2.0, y + 0.61, 0, 0.08, 1.04, "y", rgb(236, 176, 180), M)
	for i, x in { -0.8, -0.4, 0.0, 0.4 } do
		q:cyl(x, y + 0.1, -0.2, 0.2, 0.36, "y", if i % 2 == 0 then SKY else LILAC, M)
		q:lump(CFrame.new(x, y + 0.3, -0.2), 0.4, 0.3, 0.4, if i % 2 == 0 then rgb(250, 236, 224) else BLUSH, M)
	end
	q:cyl(1.4, y + 0.06, 0, 0.12, 0.9, "y", rgb(214, 164, 100), M)
	q:cyl(1.4, y + 0.15, 0, 0.06, 0.78, "y", rgb(196, 70, 80), M)
	q:cyl(2.35, y + 0.21, 0.1, 0.9, 0.42, "x", rgb(200, 150, 100), M)
	q:cyl(2.35, y + 0.21, 0.1, 0.96, 0.3, "x", rgb(244, 232, 214), M)
	y = 2.55
	for i, x in { -2.1, -1.4, -0.7 } do
		q:lump(CFrame.new(x, y + 0.13, 0.05) * CFrame.Angles(0, i * 0.5, 0), 0.6, 0.26, 0.32, rgb(214, 160, 92), M)
	end
	for i, x in { 0.1, 0.45, 0.8, 1.15 } do
		q:lump(CFrame.new(x, y + 0.08, -0.1), 0.3, 0.16, 0.3, ({ BLUSH, SAGE, BUTTER, LILAC })[i], M)
	end
	for _, x in { 1.75, 2.35 } do
		q:cyl(x, y + 0.08, 0.05, 0.16, 0.48, "y", rgb(214, 164, 100), M)
		q:cyl(x, y + 0.18, 0.05, 0.04, 0.42, "y", rgb(236, 176, 180), M)
	end
	q:block(-2.8, 1.6, 0.7, -2.6, 1.7, 0.8, WHITE, M) -- a card at the back corner
end

-- A florist's stand of zinc buckets on two steps, each with a bunch in it.
local function drawBuckets(q: R)
	local M = "SmoothPlastic"
	local stand, zinc = rgb(134, 168, 134), rgb(176, 184, 188)
	q:block(-2.2, 0, -1.2, 2.2, 0.8, 0, stand, M)
	q:block(-2.2, 0, 0, 2.2, 1.6, 1.2, shade(stand, 0.92), M)
	local spots =
		{ { -1.45, 0.8, -0.6 }, { 0, 0.8, -0.6 }, { 1.45, 0.8, -0.6 }, { -0.72, 1.6, 0.6 }, { 0.72, 1.6, 0.6 } }
	local blooms = { { CORAL, BUTTER }, { BLUSH, WHITE }, { LILAC, BLUSH }, { BUTTER, BERRY }, { WHITE, CORAL } }
	for i, s in spots do
		q:cyl(s[1], s[2] + 0.4, s[3], 0.8, 0.85, "y", zinc, M)
		q:lump(CFrame.new(s[1], s[2] + 1.1, s[3]) * CFrame.Angles(0, i, 0), 0.8, 0.9, 0.8, LEAF, M)
		q:lump(CFrame.new(s[1] - 0.15, s[2] + 1.45, s[3] - 0.1), 0.5, 0.42, 0.5, blooms[i][1], M)
		q:lump(CFrame.new(s[1] + 0.2, s[2] + 1.35, s[3] + 0.12), 0.45, 0.4, 0.45, blooms[i][2], M)
	end
	for _, x in { -1.45, 1.45 } do
		q:block(x - 0.3, 0.3, -1.23, x + 0.3, 0.55, -1.2, PAPER, M)
	end
end

-- A greengrocer's stand: three crates tilted toward the customer on a sloping bed, turned posts,
-- a shelf underneath and a price board on a rail at the back. Its fruit is a piece of its own
-- (drawFruit) in the same crates.
local CRATE_TILT = math.rad(-20)
local function crateAt(i: number): CFrame
	return CFrame.new(i * 1.75, 1.45, 0) * CFrame.Angles(CRATE_TILT, 0, 0)
end

local function drawProduce(q: R)
	local M = "Wood"
	local wood, slat = rgb(176, 132, 92), rgb(206, 170, 122)
	q:block(-2.45, 0.35, -0.85, 2.45, 0.47, 0.85, wood, M)
	q:boxAt(crateAt(0) * CFrame.new(0, -0.06, 0), 5.3, 0.12, 2.1, wood, M)
	for _, sx in { -1, 1 } do
		q:cyl(sx * 2.5, 0.53, -0.95, 1.06, 0.22, "y", wood, M)
		q:cyl(sx * 2.5, 1.2, 0.95, 2.4, 0.22, "y", wood, M)
	end
	q:block(-2.65, 2.25, 0.85, 2.65, 2.4, 1.05, wood, M)
	q:block(-0.95, 2.4, 0.9, 0.95, 3.05, 1.0, rgb(60, 72, 66), M)
	for i = -1, 1 do
		local c = crateAt(i)
		q:boxAt(c * CFrame.new(0, 0.05, 0), 1.6, 0.1, 1.9, slat, M)
		q:boxAt(c * CFrame.new(0, 0.275, -0.91), 1.6, 0.35, 0.08, slat, M)
		q:boxAt(c * CFrame.new(0, 0.35, 0.91), 1.6, 0.5, 0.08, shade(slat, 0.9), M)
		q:boxAt(c * CFrame.new(-0.76, 0.3, 0), 0.08, 0.4, 1.74, shade(slat, 0.95), M)
		q:boxAt(c * CFrame.new(0.76, 0.3, 0), 0.08, 0.4, 1.74, shade(slat, 0.95), M)
	end
end

-- Apples, oranges and lettuces heaped in the stand's crates, and two price cards.
local function drawFruit(q: R)
	local M = "SmoothPlastic"
	local rand = dice(5150)
	q:block(-2.05, 0.95, -1.06, -1.45, 1.2, -1.03, PAPER, M)
	q:block(-0.3, 0.95, -1.06, 0.3, 1.2, -1.03, PAPER, M)
	local heaps: { { crate: number, d: number, a: Color3, b: Color3 } } = {
		{ crate = -1, d = 0.36, a = rgb(184, 80, 72), b = rgb(204, 116, 80) },
		{ crate = 0, d = 0.38, a = rgb(226, 150, 78), b = rgb(234, 170, 92) },
	}
	for _, h in heaps do
		local c = crateAt(h.crate)
		for row = -1, 1 do
			for col = -1, 1 do
				q:lump(
					c
						* CFrame.new(
							col * 0.46 + (rand() - 0.5) * 0.06,
							0.1 + h.d / 2,
							row * 0.55 + (rand() - 0.5) * 0.06
						),
					h.d,
					h.d * 0.94,
					h.d,
					if (row + col) % 2 == 0 then h.a else h.b,
					M
				)
			end
		end
	end
	local c = crateAt(1)
	for i, p in { { -0.36, -0.42 }, { 0.36, -0.4 }, { -0.34, 0.4 }, { 0.36, 0.42 } } do
		q:lump(
			c * CFrame.new(p[1], 0.36, p[2]) * CFrame.Angles(0, i, 0),
			0.68,
			0.52,
			0.68,
			if i % 2 == 0 then LEAF else LEAF_LIGHT,
			M
		)
	end
end

-- A stand with its fruit, and an invisible box to bump into.
local function produceStand(r: R, f: CFrame)
	stamp(r, f, "produce", drawProduce)
	stamp(r, f, "fruit", drawFruit)
	solid(r, f, -2.65, 0, -1.05, 2.65, 2.4, 1.05)
end

-- A coffee machine for a counter top: two heads with cups under them, gauges, a steam wand, cups
-- warming on top, and the grinder beside it.
local function drawCoffee(q: R)
	local M = "SmoothPlastic"
	local body, steel = rgb(190, 92, 84), rgb(196, 200, 206)
	q:block(-1.0, 0, -0.5, 1.0, 1.3, 0.6, body, M)
	q:block(-1.06, 1.3, -0.56, 1.06, 1.42, 0.66, steel, M)
	q:block(-0.9, 0.62, -0.56, 0.9, 1.2, -0.5, steel, M)
	q:block(-0.95, 0, -0.95, 0.95, 0.12, -0.5, steel, M)
	for _, x in { -0.42, 0.42 } do
		q:cyl(x, 0.52, -0.72, 0.2, 0.34, "y", steel, M)
		q:block(x - 0.08, 0.36, -1.2, x + 0.08, 0.46, -0.72, INK, M)
		q:cyl(x, 0.25, -0.72, 0.26, 0.3, "y", CREAM, M)
		q:cyl(x * 0.7, 1.0, -0.58, 0.06, 0.22, "z", CREAM, M)
	end
	for i, x in { -0.45, 0.0, 0.45 } do
		q:cyl(x, 1.56, (i - 2) * 0.1, 0.28, 0.3, "y", CREAM, M)
	end
	rod(q, Vector3.new(0.95, 0.9, -0.3), Vector3.new(1.15, 0.35, -0.55), 0.07, steel, M)
	q:block(1.25, 0, -0.35, 1.75, 0.8, 0.25, INK, M)
	q:cyl(1.5, 1.05, -0.05, 0.5, 0.44, "y", rgb(150, 110, 80), M)
end

-- Whether a piece is one of the rooms' furniture: the facade kit counts its own pieces apart
-- from these (a shop's room is drawn inside a facade).
function Interiors.owns(key: string): boolean
	return owned[key] == true
end

-- The room itself --------------------------------------------------------------------------------------

export type Shell = {
	w: number, -- outside width and depth; the front wall is at -d / 2
	d: number,
	h: number, -- the room's height, floor to ceiling
	wall: Color3,
	mat: string?,
	inside: Color3?, -- the inner walls' colour (plaster cream by default)
	floor: Color3?,
	floorMat: string?,
	trim: Color3?,
	doorX: number?, -- where along the front the door is (0, the middle, by default)
	doorW: number?,
	doorH: number?,
	door: Color3?,
	windows: boolean?, -- false for a front wall with only a door in it
	sill: number?, -- how high the shop window starts (1 by default)
}

-- Draws a room you can walk into: a floor, three walls, and a front with a shop window either
-- side of a door that opens. The caller puts the ceiling on (the storeys above, or a roof).
function Interiors.shell(r: R, s: Shell): Box
	local w, d, h = s.w, s.d, s.h
	local T = 0.8
	local mat = s.mat or "Plaster"
	local trim = s.trim or WHITE
	local doorX = s.doorX or 0
	local dw, dh = s.doorW or 4.2, math.min(s.doorH or 6.8, h - 0.8)
	local zf = -d / 2
	local f = CFrame.identity
	-- the floor, then the back and the sides
	slab(r, f, -w / 2, 0, zf, w / 2, 0.3, d / 2, s.floor or FLOOR, s.floorMat or "WoodPlanks")
	slab(r, f, -w / 2, 0.3, d / 2 - T, w / 2, h, d / 2, s.wall, mat)
	for _, sx in { -1, 1 } do
		slab(r, f, sx * w / 2, 0.3, zf, sx * (w / 2 - T), h, d / 2 - T, s.wall, mat)
	end
	-- the front: a lintel across the top, the door's posts, and either side of the door a low wall
	-- with a pane of glass over it. The walls stop where the door's posts start, so the posts'
	-- faces in the doorway are the only ones there.
	local x1, x2 = doorX - dw / 2, doorX + dw / 2
	slab(r, f, -w / 2 + T, dh + 0.3, zf, w / 2 - T, h, zf + T, s.wall, mat)
	for _, e in { { -w / 2 + T, x1 - 0.3 }, { x2 + 0.3, w / 2 - T } } do
		local a, b = e[1], e[2]
		if b - a > 0.4 then
			if s.windows == false or b - a < 3 then
				slab(r, f, a, 0.3, zf, b, dh + 0.3, zf + T, s.wall, mat)
			else
				local sill = s.sill or 1
				slab(r, f, a, 0.3, zf, b, 0.3 + sill, zf + T, shade(s.wall, 0.86), mat)
				local pane = slab(r, f, a + 0.3, 0.3 + sill, zf + 0.3, b - 0.3, dh + 0.3, zf + 0.5, GLASS, "Glass")
				pane.transp = 0.55
				-- the window's frame: a sill, and a post at each end
				slab(r, f, a, 0.3 + sill, zf - 0.2, b, 0.6 + sill, zf + T, trim, "SmoothPlastic")
				slab(r, f, a, 0.6 + sill, zf, a + 0.3, dh + 0.3, zf + T, trim, "SmoothPlastic")
				slab(r, f, b - 0.3, 0.6 + sill, zf, b, dh + 0.3, zf + T, trim, "SmoothPlastic")
			end
		end
	end
	-- the door: its frame, standing proud of the wall inside and out (its head a touch lower than
	-- the lintel's underside), a step, and a leaf that swings in (the World service opens it for a
	-- player's prompt and for any villager who walks up)
	slab(r, f, x1 - 0.3, 0.3, zf - 0.1, x1, dh + 0.3, zf + T + 0.04, trim, "SmoothPlastic")
	slab(r, f, x2, 0.3, zf - 0.1, x2 + 0.3, dh + 0.3, zf + T + 0.04, trim, "SmoothPlastic")
	slab(r, f, x1 - 0.3, dh + 0.25, zf - 0.1, x2 + 0.3, dh + 0.6, zf + T + 0.04, trim, "SmoothPlastic")
	slab(r, f, x1 - 0.6, 0, zf - 1.4, x2 + 0.6, 0.3, zf, rgb(214, 214, 220), "Concrete")
	-- the doorway's own frame: X along the wall, Z into the room, so the leaf opens inward
	local doorway = CFrame.new(doorX, 0.3, zf + T / 2)
	local leaf = r:boxAt(doorway * CFrame.new(0, dh / 2, 0), dw, dh - 0.1, 0.3, s.door or rgb(92, 120, 160), "Wood")
	leaf.frame = doorway
	r:door(leaf, -dw / 2)
	local glassIn = r:boxAt(doorway * CFrame.new(0, dh * 0.62, 0), dw - 1.2, dh * 0.45, 0.36, GLASS, "Glass")
	glassIn.frame = doorway
	glassIn.transp = 0.5
	r:door(glassIn, -dw / 2)
	for _, sz in { -1, 1 } do
		local knob = r:lump(doorway * CFrame.new(dw / 2 - 0.5, dh * 0.42, sz * 0.3), 0.4, 0.4, 0.4, BRASS, "Metal")
		knob.frame = doorway
		r:door(knob, -dw / 2)
	end
	return { x1 = -w / 2 + T, z1 = zf + T, x2 = w / 2 - T, z2 = d / 2 - T, y = 0.3, h = h - 0.3, door = doorX }
end

-- Plain parts that go in many rooms ------------------------------------------------------------------

-- A lamp hanging from the ceiling at (x, z), lit after dark. `light` false keeps it from casting
-- light (it only glows), which is cheaper where there are many.
local function lamp(r: R, b: Box, x: number, z: number, light: boolean?)
	local top = b.y + b.h
	stamp(r, CFrame.new(x, top, z), "pendant", drawPendant)
	local disc = r:add({
		shape = "Cylinder",
		cf = CFrame.new(x, top - 2.36, z) * CFrame.Angles(0, 0, math.pi / 2),
		size = Vector3.new(0.12, 1.5, 1.5),
		color = LAMPLIGHT,
		mat = "SmoothPlastic",
	})
	if light == false then
		r:glow(disc, 0)
	else
		r:glow(disc, 22, 0.9)
	end
end

-- A coir mat inside the door, thin enough for the door to swing over it.
local function doormat(r: R, b: Box)
	local x = b.door or (b.x1 + b.x2) / 2
	slab(r, CFrame.identity, x - 1.8, b.y, b.z1 + 0.35, x + 1.8, b.y + 0.04, b.z1 + 1.95, rgb(176, 146, 104), "Fabric")
end

-- A door to the back room in the back wall at x: a frame, the door, a knob and a plate on it.
local function staffDoor(r: R, b: Box, x: number)
	local f = CFrame.new(x, b.y, b.z2)
	slab(r, f, -2.1, 0, -0.12, 2.1, 7.0, 0, WHITE, "SmoothPlastic")
	slab(r, f, -1.8, 0, -0.2, 1.8, 6.7, -0.12, WALNUT, "Wood")
	r:lump(f * CFrame.new(1.3, 3.2, -0.26), 0.24, 0.24, 0.16, BRASS, "Metal")
	slab(r, f, -0.5, 5.0, -0.23, 0.5, 5.35, -0.2, PAPER, "SmoothPlastic")
end

-- A lamp on a stand for a reading corner.
local function floorLamp(r: R, f: CFrame)
	post(r, f, 0, 0, 0, 0.16, 1.0, DARK, "Metal")
	post(r, f, 0, 0.16, 0, 4.36, 0.12, DARK, "Metal")
	r:add({
		shape = "Cone",
		cf = f * CFrame.new(0, 4.9, 0),
		size = Vector3.new(1.4, 0.9, 1.4),
		color = rgb(232, 214, 180),
		mat = "Fabric",
	})
	r:glow(r:lump(f * CFrame.new(0, 4.42, 0), 0.5, 0.4, 0.5, LAMPLIGHT), 12, 0.7)
end

-- A glass case of cakes, 6 wide: a wooden base, the glass, a glass shelf and a wooden top.
local function cakeCase(r: R, f: CFrame)
	slab(r, f, -3, 0, -1, 3, 1.6, 1, WOOD, "Wood")
	slab(r, f, -3, 1.62, -1, 3, 3.4, 1, GLASS, "Glass").transp = 0.6
	slab(r, f, -2.85, 2.5, -0.85, 2.85, 2.55, 0.85, GLASS, "Glass").transp = 0.4
	slab(r, f, -3.05, 3.4, -1.05, 3.05, 3.5, 1.05, shade(WOOD, 0.86), "Wood")
	stamp(r, f, "cakes", drawCakes)
end

-- A carpet laid along z from z1 to z2, w wide: a field with a stripe down each side.
local function runner(r: R, b: Box, x: number, z1: number, z2: number, w: number, color: Color3)
	local f = CFrame.identity
	slab(r, f, x - w / 2 + 0.3, b.y, z1, x + w / 2 - 0.3, b.y + 0.04, z2, color, "Fabric")
	for _, s in { -1, 1 } do
		slab(r, f, x + s * (w / 2 - 0.3), b.y, z1, x + s * w / 2, b.y + 0.04, z2, rgb(232, 218, 190), "Fabric")
	end
end

-- A bicycle leaning on a wall, along f's Z.
local function bike(r: R, f: CFrame)
	local frame = rgb(70, 120, 128)
	for _, z in { -1.55, 1.55 } do
		r:add({
			shape = "Cylinder",
			cf = f * CFrame.new(0, 0.95, z),
			size = Vector3.new(0.14, 1.9, 1.9),
			color = INK,
			mat = "SmoothPlastic",
		})
	end
	local function p(y: number, z: number): Vector3
		return (f * CFrame.new(0, y, z)).Position
	end
	r:beam(p(0.95, 1.55), p(2.35, -1.05), 0.06, 0.12, frame)
	r:beam(p(0.95, 0.3), p(2.55, 0.6), 0.06, 0.12, frame)
	r:beam(p(0.95, -1.55), p(2.6, -1.1), 0.06, 0.1, frame)
	r:boxAt(f * CFrame.new(0, 2.65, 0.62), 0.4, 0.14, 0.8, INK, "SmoothPlastic")
	r:cyl(p(2.7, -1.15).X, p(2.7, -1.15).Y, p(2.7, -1.15).Z, 1.4, 0.1, "x", INK, "Metal")
end

-- Shops ------------------------------------------------------------------------------------------------

-- What each kind of shop keeps on its shelves: along the back wall, and down the left wall where
-- it has shelves there too. A list is taken two at a time, the lower shelves and then the upper.
local STOCK: { [string]: { back: { string }, side: { string }? } } = {
	bakery = { back = { "loaves", "loaves", "loaves", "jars" }, side = { "loaves", "jars" } },
	grocer = { back = { "jars", "jars" }, side = { "jars", "jars" } },
	books = { back = { "booksA", "booksB", "booksB", "booksA" }, side = { "booksB", "booksA", "booksA", "booksB" } },
	clothes = { back = { "folds", "folds" } },
	cafe = { back = { "jars", "loaves" } },
	toys = { back = { "toys", "toys" }, side = { "toys", "booksB" } },
	flowers = { back = { "pots", "pots" }, side = { "pots", "pots" } },
	post = { back = { "parcels", "parcels" } },
}

Interiors.ShopKinds = { "bakery", "grocer", "books", "clothes", "cafe", "toys", "flowers" }

-- A lump at (x, y, z) in the frame f.
local function lumpAt(
	r: R,
	f: CFrame,
	x: number,
	y: number,
	z: number,
	sx: number,
	sy: number,
	sz: number,
	color: Color3,
	mat: string?
): Prim
	return r:lump(f * CFrame.new(x, y, z), sx, sy, sz, color, mat)
end

-- A big soft bear sitting up, facing -Z.
local function teddy(r: R, f: CFrame)
	local fur, light = rgb(190, 146, 100), rgb(228, 200, 160)
	lumpAt(r, f, 0, 1.2, 0, 2.2, 2.4, 1.8, fur)
	lumpAt(r, f, 0, 3.1, 0, 1.7, 1.6, 1.6, fur)
	for _, s in { -1, 1 } do
		lumpAt(r, f, s * 0.62, 3.85, 0.1, 0.6, 0.6, 0.4, fur)
		r:lump(f * CFrame.new(s * 1.1, 1.5, -0.2) * CFrame.Angles(0, 0, s * 0.4), 0.6, 1.4, 0.6, fur)
		lumpAt(r, f, s * 0.65, 0.35, -0.7, 0.8, 0.7, 1.3, fur)
	end
	lumpAt(r, f, 0, 2.95, -0.72, 0.7, 0.55, 0.5, light)
	lumpAt(r, f, 0, 1.1, -0.75, 1.2, 1.3, 0.4, light)
end

-- A toy aeroplane hung from the ceiling on a string at (x, z).
local function plane(r: R, b: Box, x: number, z: number)
	local top = b.y + b.h
	local y = top - 2.0
	r:cyl(x, top - 0.9, z, 1.8, 0.04, "y", WHITE)
	r:cyl(x, y, z, 2.4, 0.5, "z", BERRY)
	r:block(x - 1.5, y - 0.04, z - 0.45, x + 1.5, y + 0.04, z + 0.15, CREAM)
	r:block(x - 0.5, y - 0.04, z + 0.8, x + 0.5, y + 0.04, z + 1.12, CREAM)
	r:block(x - 0.04, y, z + 0.75, x + 0.04, y + 0.55, z + 1.12, BERRY)
end

-- A basket of trailing flowers hung from the ceiling at (x, z).
local function hangingBasket(r: R, b: Box, x: number, z: number)
	local top = b.y + b.h
	r:cyl(x, top - 0.8, z, 1.6, 0.05, "y", DARK, "Metal")
	r:lump(CFrame.new(x, top - 1.9, z), 1.2, 0.6, 1.2, rgb(186, 146, 98))
	r:lump(CFrame.new(x, top - 2.0, z), 1.5, 1.1, 1.5, LEAF)
	r:lump(CFrame.new(x + 0.3, top - 1.55, z - 0.3), 0.5, 0.4, 0.5, CORAL)
end

-- The post office's red box for letters.
local function postBox(r: R, f: CFrame)
	post(r, f, 0, 0, 0, 3.6, 1.2, BERRY, "Metal")
	post(r, f, 0, 3.6, 0, 0.3, 1.35, shade(BERRY, 0.85), "Metal")
	slab(r, f, -0.35, 2.7, -0.65, 0.35, 2.85, -0.5, INK, "Metal")
end

-- A shop: cases along the back wall, the counter at the back right with the till on it, the door
-- to the back room, a plant by the door, lamps overhead, and what the shop is in the window, in
-- the middle of the floor and on the walls.
local function shop(r: R, kind: string, b: Box)
	local w, d = b.x2 - b.x1, b.z2 - b.z1
	local cx = (b.x1 + b.x2) / 2
	local door = b.door or cx
	local stock = STOCK[kind] or STOCK.grocer
	-- the left window, where a shop puts its best things to be seen from the street
	local winX = (b.x1 + door - 2.4) / 2
	local n = math.clamp(math.floor((w - 10.5) / CASE_STEP), 2, 4)
	shelfRow(r, at(b, b.x1 + 2.55, b.z2 - 0.55), n, stock.back)
	local till = at(b, b.x2 - 4.2, b.z2 - 4.4)
	counter(r, till)
	stamp(r, till, "till", drawTill)
	-- behind the shopkeeper a case of stock (in a cafe a bench with the coffee machine on it), and
	-- between that and the shelves the door to the back room
	local rightStart = b.x2 - 4.6
	if kind == "cafe" then
		local bench = at(b, b.x2 - 4.2, b.z2 - 1.1, 180)
		counter(r, bench)
		stamp(r, bench * CFrame.new(0.6, 3.3, 0) * CFrame.Angles(0, math.pi, 0), "coffee", drawCoffee)
		rightStart = b.x2 - 7.5
	else
		shelves(r, at(b, b.x2 - 2.6, b.z2 - 0.55), stock.back[1], stock.back[2] or stock.back[1])
	end
	local shelfEnd = b.x1 + 0.55 + n * CASE_STEP
	if rightStart - shelfEnd >= 4.6 then
		staffDoor(r, b, (shelfEnd + rightStart) / 2)
	end
	if stock.side then
		shelfRow(r, at(b, b.x1 + 0.55, b.z2 - 7.2, -90), 2, stock.side)
	end
	doormat(r, b)
	stamp(r, at(b, b.x2 - 1.4, b.z1 + 1.5), "plant", drawPlant)
	lamp(r, b, b.x2 - 4.2, b.z2 - 4.4)
	lamp(r, b, cx - w * 0.2, b.z1 + d * 0.5, false)
	lamp(r, b, cx + w * 0.12, b.z1 + d * 0.28, false)
	-- a picture and a clock on the right wall (a bookshop's right wall has shelves: the left, then)
	local wall = if kind == "books" then "left" else "right"
	stamp(r, wallAt(b, wall, b.z1 + 6.6, 3.4), "landscape", drawLandscape)
	stamp(r, wallAt(b, wall, b.z1 + 9.8, 5.5), "clock", drawClock)
	local mid = b.z1 + d * 0.52
	if kind == "bakery" then
		cakeCase(r, at(b, winX, b.z1 + 2.3, 180))
		stamp(r, at(b, b.x2 - 5.0, b.z1 + 4.4), "cafe", drawCafeSet)
		stamp(r, at(b, cx - 1.5, mid, 90), "rug", drawRug)
		stamp(r, at(b, cx - 1.5, mid), "cafe", drawCafeSet)
	elseif kind == "grocer" then
		produceStand(r, at(b, winX, b.z1 + 2.2))
		for _, s in { { mid - 1.35, 0 }, { mid + 1.35, 180 } } do
			local f = at(b, cx - 1.5, s[1], s[2])
			produceStand(r, f)
		end
		-- sacks of potatoes by the shelves, one open, and baskets to carry things in by the door
		for i, z in { b.z1 + 8.0, b.z1 + 9.1, b.z1 + 10.2 } do
			lumpAt(
				r,
				CFrame.identity,
				b.x1 + 1.0,
				b.y + 0.65,
				z,
				1.0,
				1.3,
				0.95,
				if i == 2 then CREAM else KRAFT,
				"Fabric"
			)
		end
		for _, p in { { -0.2, 0.1 }, { 0.15, -0.15 } } do
			r:ball(b.x1 + 1.0 + p[1], b.y + 1.35, b.z1 + 9.1 + p[2], 0.34, rgb(200, 160, 110))
		end
		local basket = at(b, door + 3.2, b.z1 + 1.3)
		slab(r, basket, -0.6, 0, -0.4, 0.6, 0.55, 0.4, BERRY, "SmoothPlastic")
		slab(r, basket, -0.62, 0.55, -0.42, 0.62, 1.0, 0.42, shade(BERRY, 0.9), "SmoothPlastic")
		slab(r, basket, -0.05, 1.0, -0.38, 0.05, 1.5, 0.38, INK, "SmoothPlastic")
	elseif kind == "books" then
		shelfRow(r, at(b, b.x2 - 0.55, b.z1 + 11.1, 90), 2, { "booksB", "booksA", "booksA", "booksB" })
		stamp(r, at(b, winX, b.z1 + 2.0), "lowtable", drawLowTable)
		stamp(r, at(b, cx - 3, mid), "rug", drawRug)
		stamp(r, at(b, cx - 3, mid - 1.0), "lowtable", drawLowTable)
		stamp(r, at(b, cx - 3, mid + 1.7), "sofa", drawSofa)
		floorLamp(r, at(b, cx - 6.9, mid + 2.2))
	elseif kind == "clothes" then
		for _, z in { b.z2 - 4.4, b.z2 - 11.0 } do
			stamp(r, at(b, b.x1 + 1.0, z, -90), "rack", drawRack)
		end
		stamp(r, at(b, cx - 1.0, mid + 1.0), "rack", drawRack)
		stamp(r, at(b, cx + 4.5, mid - 2.0, 90), "rug", drawRug)
		stamp(r, at(b, cx + 4.5, mid - 2.0, 200), "mannequin", drawMannequin)
		for _, dx in { -1.8, 1.8 } do
			stamp(r, at(b, winX + dx, b.z1 + 1.8, dx * 10), "mannequin", drawMannequin)
		end
		-- a long mirror on the right wall
		local m = wallAt(b, "right", b.z1 + 13.0, 0.3)
		slab(r, m, -1.1, 0, -0.12, 1.1, 6.0, 0, WALNUT, "Wood")
		slab(r, m, -0.9, 0.2, -0.16, 0.9, 5.8, -0.12, rgb(200, 216, 222), "Glass")
	elseif kind == "cafe" then
		cakeCase(r, at(b, b.x2 - 11.6, b.z2 - 4.4))
		stamp(r, at(b, winX, b.z1 + 3.0), "cafe", drawCafeSet)
		stamp(r, at(b, b.x2 - 5.0, b.z1 + 4.4), "cafe", drawCafeSet)
		stamp(r, at(b, cx - 2.5, mid, 90), "rug", drawRug)
		stamp(r, at(b, cx - 2.5, mid), "cafe", drawCafeSet)
		stamp(r, at(b, b.x1 + 1.75, b.z1 + 14.0, -90), "sofa", drawSofa)
		stamp(r, at(b, b.x1 + 4.4, b.z1 + 14.0, 90), "lowtable", drawLowTable)
		stamp(r, wallAt(b, "left", b.z1 + 7.0, 3.2), "notices", drawNotices)
	elseif kind == "toys" then
		teddy(r, at(b, winX, b.z1 + 2.2))
		stamp(r, at(b, cx, mid), "rug", drawRug)
		local blocks = at(b, cx + 1.0, mid + 1.2)
		slab(r, blocks, -1.3, 0, -0.6, -0.1, 1.2, 0.6, MUSTARD, "SmoothPlastic")
		slab(r, blocks, 0.1, 0, -0.6, 1.3, 1.2, 0.6, SAGE, "SmoothPlastic")
		r:boxAt(
			blocks * CFrame.new(0, 1.8, 0) * CFrame.Angles(0, math.rad(25), 0),
			1.2,
			1.2,
			1.2,
			NAVY,
			"SmoothPlastic"
		)
		r:ball(cx - 1.6, b.y + 0.8, mid - 1.6, 1.6, CORAL)
		plane(r, b, cx + 1.0, b.z1 + 6.0)
	elseif kind == "flowers" then
		stamp(r, at(b, winX, b.z1 + 2.0), "buckets", drawBuckets)
		stamp(r, at(b, cx - 2, mid - 1.25), "buckets", drawBuckets)
		stamp(r, at(b, cx - 2, mid + 1.25, 180), "buckets", drawBuckets)
		hangingBasket(r, b, cx + 3.0, b.z1 + 5.5)
		hangingBasket(r, b, cx - 6.5, b.z1 + 5.5)
	elseif kind == "post" then
		-- a glass screen along the counter, the box for letters in the window, seats and notices
		-- on the left wall, sacks of post waiting by the shelves
		slab(r, till, -3.2, 3.75, -0.98, 3.2, 6.3, -0.92, GLASS, "Glass").transp = 0.55
		for _, x in { -3.1, 3.1 } do
			post(r, till, x, 3.3, -0.95, 3.0, 0.12, METAL, "Metal")
		end
		postBox(r, at(b, winX, b.z1 + 1.8))
		-- a sloping stand to fill in forms at, with two forms and a pen on it, and a carpet up the
		-- middle
		local st = at(b, cx - 3.5, b.z1 + d * 0.5)
		slab(r, st, -0.7, 0, -0.5, 0.7, 0.2, 0.5, WALNUT, "Wood")
		slab(r, st, -0.2, 0.2, -0.2, 0.2, 3.4, 0.2, WALNUT, "Wood")
		local top = st * CFrame.new(0, 3.55, 0) * CFrame.Angles(math.rad(-12), 0, 0)
		r:boxAt(top, 3.0, 0.14, 1.6, WOOD, "Wood")
		r:boxAt(top * CFrame.new(-0.6, 0.085, 0) * CFrame.Angles(0, math.rad(8), 0), 0.7, 0.03, 0.9, WHITE)
		r:boxAt(top * CFrame.new(0.55, 0.085, 0.1) * CFrame.Angles(0, math.rad(-6), 0), 0.7, 0.03, 0.9, BUTTER)
		r:add({
			shape = "Cylinder",
			cf = top * CFrame.new(1.1, 0.1, -0.4),
			size = Vector3.new(0.5, 0.06, 0.06),
			color = NAVY,
			mat = "SmoothPlastic",
		})
		runner(r, b, door, b.z1 + 2.2, b.z2 - 1.5, 3.6, rgb(160, 92, 90))
		stamp(r, at(b, b.x1 + 0.85, b.z1 + 8.5, -90), "seats", drawSeats)
		stamp(r, wallAt(b, "left", b.z1 + 8.5, 3.4), "notices", drawNotices)
		for i, x in { shelfEnd + 0.9, shelfEnd + 2.1 } do
			lumpAt(r, CFrame.identity, x, b.y + 0.75, b.z2 - 2.0 + i * 0.3, 1.2, 1.5, 1.0, rgb(214, 208, 192), "Fabric")
		end
	end
end

-- A big shop floor: the back wall lined with shelves, two islands of shelves back to back, rails
-- of clothes in rows, figures dressed up in the windows, and a till either side of the door.
local function department(r: R, b: Box)
	local w, d = b.x2 - b.x1, b.z2 - b.z1
	local cx = (b.x1 + b.x2) / 2
	local door = b.door or cx
	local n = math.floor((w - 1.1) / CASE_STEP)
	shelfRow(
		r,
		at(b, cx - (n - 1) * CASE_STEP / 2, b.z2 - 0.55),
		n,
		{ "folds", "folds", "folds", "toys", "toys", "toys", "booksA", "booksB", "jars", "jars", "pots", "pots" }
	)
	local mid = b.z1 + d * 0.55
	for _, x in { cx - 22, cx + 22 } do
		shelves(r, at(b, x, mid - 0.52), "toys", "booksA")
		shelves(r, at(b, x, mid + 0.52, 180), "folds", "jars")
		stamp(r, at(b, x + (if x < cx then 5.5 else -5.5), mid), "plant", drawPlant)
	end
	for _, x in { cx - 11, cx, cx + 11 } do
		for _, z in { b.z1 + d * 0.38, b.z1 + d * 0.72 } do
			stamp(r, at(b, x, z), "rack", drawRack)
		end
	end
	for _, x in { cx - 20, cx - 14, cx + 14, cx + 20 } do
		stamp(r, at(b, x, b.z1 + 2.0, (x - cx) * 0.8), "mannequin", drawMannequin)
	end
	for _, x in { b.x1 + 6, b.x2 - 6 } do
		local f = at(b, x, b.z1 + 7, 180)
		counter(r, f)
		stamp(r, f, "till", drawTill)
	end
	runner(r, b, door, b.z1 + 2.2, b.z1 + 13, 5, rgb(176, 96, 94))
	doormat(r, b)
	stamp(r, at(b, b.x1 + 1.5, b.z1 + 1.5), "plant", drawPlant)
	stamp(r, at(b, b.x2 - 1.5, b.z1 + 1.5), "plant", drawPlant)
	stamp(r, wallAt(b, "left", mid, 3.4), "landscape", drawLandscape)
	stamp(r, wallAt(b, "right", mid, 3.2), "stillLife", drawStillLife)
	stamp(r, wallAt(b, "right", b.z1 + d * 0.3, 5.6), "clock", drawClock)
	-- lamps between the rails, never over the shelves (they hang lower than a case is tall)
	for i, x in { cx - 16.5, cx - 5.5, cx + 5.5, cx + 16.5 } do
		lamp(r, b, x, mid, i == 2 or i == 3)
	end
end

-- The lifts in a tower's back wall, each with its lit floor sign over the doors.
local function liftDoors(r: R, b: Box, x: number)
	local f = CFrame.new(x, b.y, b.z2 - 0.05)
	stamp(r, f, "lift", drawLift)
	r:glow(slab(r, f, -0.5, 6.15, -0.36, 0.5, 6.45, -0.32, rgb(255, 196, 120), "SmoothPlastic"), 0)
end

-- A tower's lobby: lifts at the back with a carpet up to them from the door, plants. An office
-- or hotel has a desk with files behind it and sofas round a low table; flats have their post
-- boxes, seats and the notices, and somebody's bicycle.
local function lobby(r: R, b: Box, flats: boolean)
	local w, d = b.x2 - b.x1, b.z2 - b.z1
	local cx = (b.x1 + b.x2) / 2
	local door = b.door or cx
	liftDoors(r, b, cx - 3.2)
	liftDoors(r, b, cx + 3.2)
	runner(r, b, door, b.z1 + 2.2, b.z2 - 1.0, 4.0, rgb(150, 86, 90))
	doormat(r, b)
	stamp(r, at(b, b.x1 + 1.4, b.z1 + 1.5), "plant", drawPlant)
	stamp(r, at(b, b.x2 - 1.4, b.z1 + 1.5), "plant", drawPlant)
	stamp(r, at(b, cx - 7.0, b.z2 - 1.4), "plant", drawPlant)
	lamp(r, b, cx, b.z1 + d * 0.35)
	lamp(r, b, cx, b.z1 + d * 0.7, false)
	if flats then
		plain(r, wallAt(b, "left", b.z1 + d * 0.5, 0), drawMailboxes)
		stamp(r, at(b, b.x2 - 0.85, b.z1 + d * 0.5, 90), "seats", drawSeats)
		stamp(r, wallAt(b, "right", b.z1 + d * 0.5, 3.4), "notices", drawNotices)
		stamp(r, wallAt(b, "back", cx + 9.5, 3.2), "landscape", drawLandscape)
		bike(r, at(b, b.x1 + 0.45, b.z1 + 4.4))
	else
		local desk = at(b, cx + w * 0.26, b.z1 + d * 0.5, 90)
		counter(r, desk)
		stamp(r, desk, "till", drawTill)
		shelves(r, at(b, b.x2 - 0.55, b.z1 + d * 0.5, 90), "booksA", "booksB")
		local m = b.z1 + d * 0.4
		stamp(r, at(b, b.x1 + 5.2, m, 90), "rug", drawRug)
		stamp(r, at(b, b.x1 + 1.75, m, -90), "sofa", drawSofa)
		stamp(r, at(b, b.x1 + 8.65, m, 90), "sofa", drawSofa)
		stamp(r, at(b, b.x1 + 5.2, m, 90), "lowtable", drawLowTable)
		stamp(r, wallAt(b, "left", m, 3.6), "landscape", drawLandscape)
		stamp(r, wallAt(b, "back", cx + 9.5, 3.0), "notices", drawNotices)
		stamp(r, wallAt(b, "right", b.z1 + 4.5, 3.2), "stillLife", drawStillLife)
		stamp(r, wallAt(b, "back", cx - 10.5, 5.2), "clock", drawClock)
	end
end

-- A little house: a bed along the back wall in the house's own colour, a chest of drawers beside
-- it, a picture over it, a table for two by the window, books, a rug and a lamp.
local function home(r: R, b: Box, color: Color3)
	local cx, cz = (b.x1 + b.x2) / 2, (b.z1 + b.z2) / 2
	local bedAt = at(b, b.x1 + 3.9, b.z2 - 2.25, 90)
	stamp(r, bedAt, "bed", drawBed)
	slab(r, bedAt, -1.95, 1.55, -3.42, 1.95, 1.92, 1.3, color, "Fabric")
	stamp(r, at(b, b.x2 - 1.75, b.z2 - 0.8), "dresser", drawDresser)
	stamp(r, wallAt(b, "back", b.x1 + 3.6, 3.3), "landscape", drawLandscape)
	stamp(r, at(b, b.x2 - 1.7, b.z1 + 3.0, 90), "cafe", drawCafeSet)
	shelves(r, at(b, b.x1 + 0.55, b.z1 + 2.6, -90), "booksA", "booksB")
	stamp(r, at(b, cx - 0.6, b.z1 + 5.6, 90), "rug", drawRug)
	lamp(r, b, cx, cz, false)
end

-- A beach hut: a bench along the back, a towel on a peg, a board in the corner, a bucket and
-- spade, a ball and a sun hat.
local function hut(r: R, b: Box, color: Color3)
	local w = b.x2 - b.x1
	local cx = (b.x1 + b.x2) / 2
	local bw = math.min(w - 1, 5)
	local f = at(b, cx, b.z2 - 0.8)
	slab(r, f, -bw / 2, 1.3, -0.6, bw / 2, 1.5, 0.6, WOOD, "WoodPlanks")
	for _, s in { -1, 1 } do
		slab(r, f, s * (bw / 2 - 0.4) - 0.12, 0, -0.5, s * (bw / 2 - 0.4) + 0.12, 1.3, 0.5, WALNUT, "Wood")
	end
	slab(r, f, -bw / 2, 2.2, 0.6, bw / 2, 2.6, 0.75, WOOD, "WoodPlanks")
	r:cyl(cx + 0.9, b.y + 1.53, b.z2 - 0.8, 0.06, 1.4, "y", rgb(222, 196, 140))
	r:cyl(cx + 0.9, b.y + 1.76, b.z2 - 0.8, 0.4, 0.7, "y", rgb(222, 196, 140))
	r:cyl(cx + 0.9, b.y + 1.62, b.z2 - 0.8, 0.12, 0.76, "y", CORAL)
	r:cyl(b.x1 + 0.25, b.y + 4.7, b.z1 + 2.2, 0.5, 0.12, "x", WALNUT, "Wood")
	slab(r, CFrame.identity, b.x1 + 0.1, b.y + 2.4, b.z1 + 1.6, b.x1 + 0.35, b.y + 4.6, b.z1 + 2.8, color, "Fabric")
	slab(r, CFrame.identity, b.x1 + 0.05, b.y + 3.2, b.z1 + 1.57, b.x1 + 0.4, b.y + 3.5, b.z1 + 2.83, WHITE, "Fabric")
	local board = CFrame.new(b.x2 - 0.7, b.y + 3.1, b.z2 - 1.2) * CFrame.Angles(math.rad(8), 0, math.rad(6))
	r:lump(board, 1.3, 6.2, 0.3, rgb(236, 214, 160))
	r:boxAt(board, 0.25, 4.4, 0.36, TEAL, "SmoothPlastic")
	post(r, CFrame.identity, b.x1 + 1.1, b.y, b.z1 + 1.0, 0.8, 0.8, CORAL)
	r:boxAt(
		CFrame.new(b.x1 + 1.35, b.y + 1.0, b.z1 + 1.05) * CFrame.Angles(0, 0, math.rad(-20)),
		0.08,
		1.4,
		0.08,
		WALNUT,
		"Wood"
	)
	r:ball(cx + 0.3, b.y + 0.7, b.z1 + 1.6, 1.4, WHITE)
	r:cyl(cx + 0.3, b.y + 0.7, b.z1 + 1.6, 0.4, 1.46, "x", BERRY)
end

-- The library: bookcases all along the back wall and down both sides, pictures and a clock over
-- them, two reading tables with chairs under lamps, a ladder against the shelves, the
-- librarian's desk by the door and a corner with a sofa to read in.
local function readingTable(r: R, b: Box, x: number, z: number)
	local f = at(b, x, z)
	slab(r, f, -4, 2.45, -1.6, 4, 2.65, 1.6, WALNUT, "Wood")
	for _, s in { -1, 1 } do
		slab(r, f, s * 3.3 - 0.15, 0, -1.3, s * 3.3 + 0.15, 2.45, 1.3, shade(WALNUT, 0.85), "Wood")
	end
	slab(r, f, -3.15, 0.5, -0.12, 3.15, 0.75, 0.12, shade(WALNUT, 0.85), "Wood")
	for _, s in { -1, 1 } do
		plain(r, f * CFrame.new(s * 1.9, 0, 2.35), drawChair)
		plain(r, f * CFrame.new(s * 1.9, 0, -2.35) * CFrame.Angles(0, math.pi, 0), drawChair)
	end
	slab(r, f, -2.6, 2.65, -0.9, -1.7, 2.85, -0.2, rgb(168, 86, 78), "SmoothPlastic")
	r:boxAt(f * CFrame.new(1.6, 2.68, 0.5) * CFrame.Angles(0, math.rad(15), 0), 1.2, 0.06, 0.8, WHITE, "SmoothPlastic")
	lamp(r, b, x, z)
end

local function library(r: R, b: Box)
	local w, d = b.x2 - b.x1, b.z2 - b.z1
	local cx = (b.x1 + b.x2) / 2
	local door = b.door or cx
	local n = math.floor((w - 1.1) / CASE_STEP)
	local x0 = cx - (n - 1) * CASE_STEP / 2
	shelfRow(r, at(b, x0, b.z2 - 0.55), n, { "booksA", "booksB", "booksB", "booksA" })
	local m = math.max(1, math.floor((d - 7.5) / CASE_STEP))
	shelfRow(
		r,
		at(b, b.x1 + 0.55, b.z2 - 3.15 - (m - 1) * CASE_STEP, -90),
		m,
		{ "booksB", "booksA", "booksA", "booksB" }
	)
	shelfRow(r, at(b, b.x2 - 0.55, b.z2 - 3.15, 90), m, { "booksA", "booksB" })
	for i, x in { cx - 16, cx, cx + 16 } do
		if i == 2 then
			stamp(r, wallAt(b, "back", x, 7.4), "stillLife", drawStillLife)
		else
			stamp(r, wallAt(b, "back", x, 7.7), "landscape", drawLandscape)
		end
	end
	stamp(r, wallAt(b, "back", cx - 8, 8.9), "clock", drawClock)
	for _, x in { cx - 11, cx + 11 } do
		readingTable(r, b, x, b.z1 + d * 0.5)
	end
	-- the ladder against the back shelves
	local lx, lz = cx + 6.0, b.z2 - 1.15
	for _, s in { -1, 1 } do
		r:beam(
			Vector3.new(lx + s * 0.7, b.y, lz - 1.3),
			Vector3.new(lx + s * 0.7, b.y + 6.5, lz),
			0.16,
			0.16,
			WALNUT,
			"Wood"
		)
	end
	for k = 1, 6 do
		local t = k / 7
		r:cyl(lx, b.y + 6.5 * t, lz - 1.3 * (1 - t), 1.6, 0.1, "x", WALNUT, "Wood")
	end
	plain(r, at(b, door + 8.5, b.z1 + 4.5), drawDesk)
	stamp(r, wallAt(b, "left", b.z1 + 4.0, 3.2), "notices", drawNotices)
	-- the reading corner at the front left
	local rx = b.x1 + 7.5
	stamp(r, at(b, rx, b.z1 + 4.6, 90), "rug", drawRug)
	stamp(r, at(b, rx, b.z1 + 3.7), "lowtable", drawLowTable)
	stamp(r, at(b, rx, b.z1 + 6.4), "sofa", drawSofa)
	floorLamp(r, at(b, rx - 3.9, b.z1 + 6.6))
	runner(r, b, door, b.z1 + 2.2, b.z2 - 1.3, 4.0, rgb(140, 76, 84))
	doormat(r, b)
	stamp(r, at(b, b.x2 - 1.5, b.z1 + 1.5), "plant", drawPlant)
	-- a globe on a stand
	local g = at(b, b.x2 - 6.0, b.z1 + 4.5)
	post(r, g, 0, 0, 0, 0.15, 1.0, WALNUT, "Wood")
	post(r, g, 0, 0.15, 0, 2.5, 0.16, WALNUT, "Wood")
	lumpAt(r, g, 0, 3.3, 0, 1.6, 1.6, 1.6, rgb(110, 150, 176))
	lamp(r, b, cx, b.z1 + 5.0)
	lamp(r, b, cx, b.z1 + d * 0.75, false)
end

-- The museum: old bones on a long stand in the middle behind a rope, jars on plinths round them,
-- two glass cases of small finds, pictures on every wall, benches to look from, a desk by the door.
local function skeleton(r: R, f: CFrame)
	local bone = rgb(232, 222, 196)
	slab(r, f, -6.5, 0, -2, 6.5, 0.8, 2, WHITE, "Marble")
	for _, x in { -1.6, 1.8 } do
		post(r, f, x, 0.8, 0, 4.0, 0.22, DARK, "Metal")
	end
	for _, p in { { -2.8, 4.6 }, { -1.6, 4.9 }, { -0.4, 5.05 }, { 0.8, 5.0 }, { 1.9, 4.85 } } do
		lumpAt(r, f, p[1], p[2], 0, 1.3, 0.75, 0.7, bone)
	end
	r:lump(f * CFrame.new(3.0, 5.6, 0) * CFrame.Angles(0, 0, math.rad(40)), 1.4, 0.6, 0.55, bone)
	r:lump(f * CFrame.new(3.9, 6.5, 0) * CFrame.Angles(0, 0, math.rad(55)), 1.3, 0.5, 0.5, bone)
	r:lump(f * CFrame.new(4.85, 7.15, 0) * CFrame.Angles(0, 0, math.rad(-10)), 1.6, 0.9, 0.85, bone)
	r:boxAt(f * CFrame.new(5.0, 6.65, 0) * CFrame.Angles(0, 0, math.rad(-18)), 1.2, 0.22, 0.6, bone, "SmoothPlastic")
	for i, p in { { -4.0, 4.0, 1.0 }, { -5.1, 3.2, 0.8 }, { -6.0, 2.3, 0.6 } } do
		r:lump(
			f * CFrame.new(p[1], p[2], 0) * CFrame.Angles(0, 0, math.rad(30 + i * 6)),
			1.2 * p[3],
			0.6 * p[3],
			0.55 * p[3],
			bone
		)
	end
	for _, x in { -1.8, -0.8, 0.2, 1.2 } do
		lumpAt(r, f, x, 3.9, 0, 0.22, 2.0, 1.8, bone)
	end
	for _, hip in { -2.6, 1.6 } do
		for _, z in { -0.6, 0.6 } do
			local knee = f * CFrame.new(hip + 0.5, 2.5, z * 1.2)
			r:beam((f * CFrame.new(hip, 4.4, z)).Position, knee.Position, 0.35, 0.35, bone, "SmoothPlastic")
			r:beam(knee.Position, (f * CFrame.new(hip + 0.1, 0.85, z * 1.2)).Position, 0.3, 0.3, bone, "SmoothPlastic")
		end
	end
end

-- A rope on two brass posts across the front of something, len long, along f's X.
local function rope(r: R, f: CFrame, len: number)
	for _, x in { -len / 2, len / 2 } do
		post(r, f, x, 0, 0, 0.12, 0.8, BRASS, "Metal")
		post(r, f, x, 0.12, 0, 2.9, 0.16, BRASS, "Metal")
		lumpAt(r, f, x, 3.1, 0, 0.34, 0.34, 0.34, BRASS, "Metal")
	end
	r:add({
		shape = "Cylinder",
		cf = f * CFrame.new(0, 2.75, 0),
		size = Vector3.new(len, 0.16, 0.16),
		color = BERRY,
		mat = "Fabric",
	})
end

-- A glass case of small finds on a wooden base: a coiled shell in stone and a dish.
local function findsCase(r: R, f: CFrame)
	slab(r, f, -1.3, 0, -0.9, 1.3, 1.6, 0.9, WALNUT, "Wood")
	slab(r, f, -1.3, 1.62, -0.9, 1.3, 3.0, 0.9, GLASS, "Glass").transp = 0.6
	r:add({
		shape = "Cylinder",
		cf = f * CFrame.new(-0.5, 2.05, 0),
		size = Vector3.new(0.3, 0.9, 0.9),
		color = rgb(170, 160, 146),
		mat = "Slate",
	})
	post(r, f, 0.55, 1.6, 0, 0.12, 0.9, rgb(214, 176, 96), "Metal")
	lumpAt(r, f, 0.55, 1.85, 0, 0.5, 0.3, 0.5, rgb(214, 176, 96), "Metal")
end

-- A padded bench to sit and look from, w long.
local function museumBench(r: R, f: CFrame, w: number)
	slab(r, f, -w / 2, 1.05, -0.75, w / 2, 1.5, 0.75, rgb(150, 86, 90), "Fabric")
	for _, s in { -1, 1 } do
		slab(r, f, s * (w / 2 - 0.4) - 0.15, 0, -0.65, s * (w / 2 - 0.4) + 0.15, 1.05, 0.65, WALNUT, "Wood")
	end
end

local function museum(r: R, b: Box)
	local d = b.z2 - b.z1
	local cx = (b.x1 + b.x2) / 2
	local door = b.door or cx
	local mid = b.z1 + d * 0.52
	skeleton(r, at(b, cx, mid))
	rope(r, at(b, cx, mid - 3.0), 13)
	for i, x in { cx - 20, cx - 11, cx + 11, cx + 20 } do
		plain(r, at(b, x, b.z1 + d * (if i % 2 == 0 then 0.36 else 0.64)), drawExhibit)
	end
	for _, x in { cx - 15.5, cx + 15.5 } do
		findsCase(r, at(b, x, b.z2 - 2.2))
	end
	for i, x in { cx - 22, cx - 8, cx + 8, cx + 22 } do
		if i % 2 == 0 then
			stamp(r, wallAt(b, "back", x, 3.4), "stillLife", drawStillLife)
		else
			stamp(r, wallAt(b, "back", x, 3.8), "landscape", drawLandscape)
		end
	end
	stamp(r, wallAt(b, "left", mid, 3.6), "stillLife", drawStillLife)
	stamp(r, wallAt(b, "right", mid, 3.8), "landscape", drawLandscape)
	for _, x in { cx - 8, cx + 8 } do
		museumBench(r, at(b, x, b.z1 + 6.0), 5)
	end
	plain(r, at(b, door + 8.5, b.z1 + 3.5), drawDesk)
	stamp(r, wallAt(b, "left", b.z1 + 4.5, 3.2), "notices", drawNotices)
	runner(r, b, door, b.z1 + 2.2, mid - 3.6, 4.0, rgb(176, 96, 94))
	doormat(r, b)
	stamp(r, at(b, b.x1 + 1.5, b.z1 + 1.5), "plant", drawPlant)
	stamp(r, at(b, b.x2 - 1.5, b.z1 + 1.5), "plant", drawPlant)
	lamp(r, b, cx - 14, mid)
	lamp(r, b, cx + 14, mid)
	lamp(r, b, cx, b.z1 + 5.0, false)
end

-- A cinema: the screen across the back over a low stage with curtains either side, rows of seats
-- on steps that climb toward the door, the popcorn counter and a bench in the foyer.
local function cinema(r: R, b: Box)
	local w, d = b.x2 - b.x1, b.z2 - b.z1
	local cx = (b.x1 + b.x2) / 2
	local door = b.door or cx
	local I = CFrame.identity
	r:glow(
		slab(
			r,
			I,
			cx - w * 0.36,
			b.y + 2.4,
			b.z2 - 0.5,
			cx + w * 0.36,
			b.y + b.h - 1,
			b.z2 - 0.3,
			WHITE,
			"SmoothPlastic"
		),
		30,
		0.7,
		rgb(200, 220, 255)
	)
	slab(r, I, cx - w * 0.38, b.y + 2.0, b.z2 - 0.55, cx + w * 0.38, b.y + 2.4, b.z2 - 0.2, DARK, "SmoothPlastic")
	slab(r, I, cx - w * 0.42, b.y, b.z2 - 3.0, cx + w * 0.42, b.y + 1.2, b.z2 - 0.05, rgb(88, 70, 96), "Fabric")
	for _, s in { -1, 1 } do
		local x = cx + s * w * 0.39
		slab(r, I, x - 1.4, b.y + 1.2, b.z2 - 1.1, x + 1.4, b.y + b.h - 0.6, b.z2 - 0.5, rgb(150, 66, 74), "Fabric")
		slab(r, I, x - 0.9, b.y + 1.2, b.z2 - 1.3, x + 0.4, b.y + b.h - 0.6, b.z2 - 1.1, rgb(136, 58, 66), "Fabric")
	end
	slab(
		r,
		I,
		cx - w * 0.45,
		b.y + b.h - 1.0,
		b.z2 - 1.4,
		cx + w * 0.45,
		b.y + b.h,
		b.z2 - 0.05,
		rgb(136, 58, 66),
		"Fabric"
	)
	-- the rows, the highest at the back by the door, four seats to a row on each side of the aisle
	local rows = math.max(3, math.floor((d - 16) / 3.6))
	local per = math.max(1, math.floor((w * 0.36 - 1.6) / 8.1))
	local carpet = rgb(88, 70, 96)
	for row = 0, rows - 1 do
		local z = b.z1 + 9 + row * 3.6
		local rise = (rows - 1 - row) * 0.4
		if rise > 0 then
			slab(r, I, b.x1, b.y, z - 1.8, b.x2, b.y + rise, z + 1.8, carpet, "Fabric")
		end
		for _, s in { -1, 1 } do
			for k = 0, per - 1 do
				stamp(
					r,
					at(b, cx + s * (5.84 + k * 8.1), z, 180) + Vector3.new(0, rise, 0),
					"cinemaSeats",
					drawCinemaSeats
				)
			end
		end
	end
	-- steps up from the foyer in the aisle
	local top = (rows - 1) * 0.4
	local steps = math.floor(top / 0.4 + 0.5) - 1
	for k = 1, steps do
		slab(
			r,
			I,
			door - 1.5,
			b.y,
			b.z1 + 7.2 - (steps - k + 1) * 0.9,
			door + 1.5,
			b.y + k * 0.4,
			b.z1 + 7.2 - (steps - k) * 0.9,
			carpet,
			"Fabric"
		)
	end
	-- the foyer: the popcorn counter and its machine, a bench, a plant, posters, a lamp
	local c = at(b, b.x1 + 6, b.z1 + 3.4, 180)
	counter(r, c)
	stamp(r, c, "till", drawTill)
	local pop = at(b, b.x1 + 4.4, b.z1 + 3.4)
	slab(r, pop, -0.9, 3.3, -0.7, 0.9, 3.5, 0.7, BERRY, "Metal")
	slab(r, pop, -0.9, 3.5, -0.7, 0.9, 5.3, 0.7, GLASS, "Glass").transp = 0.5
	lumpAt(r, pop, 0, 4.0, 0, 1.5, 0.9, 1.1, BUTTER)
	slab(r, pop, -1.0, 5.3, -0.8, 1.0, 5.7, 0.8, BERRY, "Metal")
	stamp(r, wallAt(b, "left", b.z1 + 3.4, 4.6), "notices", drawNotices)
	stamp(r, at(b, b.x2 - 5, b.z1 + 1.4, 180), "seats", drawSeats)
	stamp(r, at(b, b.x2 - 1.4, b.z1 + 4.4), "plant", drawPlant)
	stamp(r, wallAt(b, "right", b.z1 + 9.0, 2.8), "stillLife", drawStillLife)
	stamp(r, wallAt(b, "right", b.z1 + 13.5, 3.2), "landscape", drawLandscape)
	-- lamps low on the side walls, and the way out lit over the door
	for _, s in { -1, 1 } do
		for _, z in { b.z1 + d * 0.45, b.z1 + d * 0.75 } do
			local x = if s < 0 then b.x1 + 0.05 else b.x2 - 0.25
			r:glow(slab(r, I, x, b.y + 6.0, z - 0.4, x + 0.2, b.y + 6.8, z + 0.4, LAMPLIGHT, "SmoothPlastic"), 0)
		end
	end
	r:glow(
		slab(
			r,
			I,
			door - 0.8,
			b.y + 7.4,
			b.z1 + 0.05,
			door + 0.8,
			b.y + 7.9,
			b.z1 + 0.2,
			rgb(120, 200, 140),
			"SmoothPlastic"
		),
		0
	)
	doormat(r, b)
	lamp(r, b, cx, b.z1 + 3.5)
end

-- The station hall: the ticket office behind glass, the board of departures and the clock over
-- the middle, benches back to back, a kiosk of papers, a machine for drinks, a luggage trolley.
local function station(r: R, b: Box)
	local d = b.z2 - b.z1
	local cx = (b.x1 + b.x2) / 2
	local I = CFrame.identity
	local t = at(b, cx - 22, b.z2 - 4.0)
	counter(r, t)
	stamp(r, t, "till", drawTill)
	slab(r, t, -3.2, 3.75, -0.98, 3.2, 6.3, -0.92, GLASS, "Glass").transp = 0.55
	shelves(r, at(b, cx - 22, b.z2 - 0.55), "booksA", "booksB")
	slab(r, I, cx - 8, b.y + 4.4, b.z2 - 0.4, cx + 8, b.y + 6.8, b.z2 - 0.05, DARK, "SmoothPlastic")
	for row = 0, 2 do
		r:glow(
			slab(
				r,
				I,
				cx - 7.4,
				b.y + 4.8 + row * 0.6,
				b.z2 - 0.46,
				cx + 3 - row * 2,
				b.y + 5.1 + row * 0.6,
				b.z2 - 0.4,
				rgb(236, 198, 112),
				"SmoothPlastic"
			),
			0
		)
	end
	stamp(r, wallAt(b, "back", cx + 10, 5.6), "clock", drawClock)
	for _, x in { cx - 6, cx + 8, cx + 22 } do
		stamp(r, at(b, x, b.z1 + d * 0.5 - 0.8), "seats", drawSeats)
		stamp(r, at(b, x, b.z1 + d * 0.5 + 0.8, 180), "seats", drawSeats)
	end
	-- the kiosk at the right end
	local k = at(b, b.x2 - 6, b.z2 - 4.0)
	counter(r, k)
	stamp(r, k, "till", drawTill)
	shelves(r, at(b, b.x2 - 6, b.z2 - 0.55), "booksB", "jars")
	-- a drinks machine by the ticket office
	local v = at(b, b.x1 + 2.2, b.z2 - 1.3)
	slab(r, v, -1.2, 0, -0.9, 1.2, 6.2, 0.9, rgb(70, 110, 140), "Metal")
	slab(r, v, -0.95, 1.8, -0.98, 0.5, 5.8, -0.9, rgb(214, 224, 230), "SmoothPlastic")
	slab(r, v, 0.65, 3.0, -0.96, 1.0, 4.4, -0.9, INK, "SmoothPlastic")
	-- the luggage trolley
	local l = at(b, cx + 30, b.z1 + 4)
	slab(r, l, -1.6, 0.4, -1, 1.6, 0.7, 1, METAL, "Metal")
	r:cyl(
		(l * CFrame.new(-1.0, 0.25, 0)).Position.X,
		b.y + 0.25,
		(l * CFrame.new(-1.0, 0.25, 0)).Position.Z,
		2.2,
		0.5,
		"z",
		INK,
		"Metal"
	)
	r:cyl(
		(l * CFrame.new(1.0, 0.25, 0)).Position.X,
		b.y + 0.25,
		(l * CFrame.new(1.0, 0.25, 0)).Position.Z,
		2.2,
		0.5,
		"z",
		INK,
		"Metal"
	)
	slab(r, l, 1.5, 0.7, -0.9, 1.65, 3.2, 0.9, METAL, "Metal")
	slab(r, l, -1.2, 0.7, -0.8, 0.2, 2.4, 0.8, WALNUT, "SmoothPlastic")
	slab(r, l, 0.3, 0.7, -0.6, 1.3, 1.8, 0.6, NAVY, "SmoothPlastic")
	-- bins, posters, plants, lamps
	for _, x in { cx - 13, cx + 15 } do
		local f = at(b, x, b.z1 + 1.4)
		post(r, f, 0, 0, 0, 2.2, 1.1, STEEL, "Metal")
		post(r, f, 0, 2.2, 0, 0.15, 1.2, INK, "Metal")
	end
	stamp(r, wallAt(b, "back", cx + 16.5, 3.4), "landscape", drawLandscape)
	stamp(r, wallAt(b, "back", cx - 12.5, 3.2), "stillLife", drawStillLife)
	stamp(r, wallAt(b, "left", b.z1 + d * 0.4, 3.2), "notices", drawNotices)
	stamp(r, at(b, b.x1 + 1.5, b.z1 + 1.5), "plant", drawPlant)
	stamp(r, at(b, b.x2 - 1.5, b.z1 + 1.5), "plant", drawPlant)
	doormat(r, b)
	for _, x in { cx - 20, cx, cx + 20 } do
		lamp(r, b, x, b.z1 + d * 0.5, x ~= cx)
	end
end

-- The school: two classrooms side by side (one in a narrow building), each with its board, the
-- teacher's desk, six pupils' desks, a bookcase and the children's drawings; shelves back to back
-- between them, coats on pegs by the door, a globe and a clock.
local function school(r: R, b: Box)
	local w, d = b.x2 - b.x1, b.z2 - b.z1
	local cx = (b.x1 + b.x2) / 2
	local sides: { number } = if w >= 56 then { -1, 1 } else { 0 }
	for _, side in sides do
		local ox = cx + side * w * 0.25
		plain(r, wallAt(b, "back", ox, 2.2), drawBlackboard)
		plain(r, at(b, ox + (if side < 0 then -6.5 else 6.5), b.z2 - 4.4), drawDesk)
		for row = 0, 1 do
			for col = -1, 1 do
				plain(r, at(b, ox + col * 4.4, b.z1 + 4.5 + row * 4.4), drawSchoolDesk)
			end
		end
		local left = side <= 0
		local wall = if left then "left" else "right"
		shelves(
			r,
			at(b, if left then b.x1 + 0.55 else b.x2 - 0.55, b.z2 - 3.15, if left then -90 else 90),
			"booksA",
			"booksB"
		)
		stamp(r, wallAt(b, if side == 0 then "right" else wall, b.z1 + 7.0, 3.2), "notices", drawNotices)
		lamp(r, b, ox, b.z1 + d * 0.5, side >= 0)
		lamp(r, b, ox, b.z1 + d * 0.8, false)
	end
	if #sides == 2 then
		shelves(r, at(b, cx - 0.52, b.z1 + d * 0.55, 90), "booksB", "toys")
		shelves(r, at(b, cx + 0.52, b.z1 + d * 0.55, -90), "booksA", "pots")
	end
	-- the globe beside the first board (the other side from its desk), the clock beside the last
	local first = cx + (if #sides == 2 then -w * 0.25 else 0)
	local last = cx + (if #sides == 2 then w * 0.25 else 0)
	local g = at(b, first + (if #sides == 2 then 6.5 else -6.5), b.z2 - 2.2)
	post(r, g, 0, 0, 0, 0.15, 1.0, WALNUT, "Wood")
	post(r, g, 0, 0.15, 0, 2.5, 0.16, WALNUT, "Wood")
	lumpAt(r, g, 0, 3.3, 0, 1.6, 1.6, 1.6, rgb(110, 150, 176))
	stamp(r, wallAt(b, "back", last + 8.5, 5.4), "clock", drawClock)
	-- coats on pegs along the left wall by the door
	local pegs = wallAt(b, "left", b.z1 + 2.6, 4.6)
	slab(r, pegs, -1.8, 0, -0.12, 1.8, 0.3, 0, WALNUT, "Wood")
	for i, c in { NAVY, BERRY, MUSTARD, SAGE } do
		lumpAt(r, pegs, -1.35 + (i - 1) * 0.9, -0.8, -0.32, 0.7, 1.7, 0.4, c, "Fabric")
	end
	doormat(r, b)
	stamp(r, at(b, b.x2 - 1.5, b.z1 + 1.5), "plant", drawPlant)
end

-- The clinic: reception at the front right with files behind it, seats to wait on down the left
-- wall with magazines, two beds behind curtains at the back, the doctor's desk, medicine on the
-- shelves, the red cross, scales and a drip stand.
local function curtain(r: R, b: Box, x: number, z1: number, z2: number)
	local top = b.y + b.h
	r:cyl(x, top - 0.6, (z1 + z2) / 2, z2 - z1, 0.12, "z", METAL, "Metal")
	local n = 3
	for k = 0, n - 1 do
		local a = z1 + (z2 - z1) * k / n
		local off = if k % 2 == 0 then 0 else 0.18
		slab(
			r,
			CFrame.identity,
			x - 0.08 + off,
			b.y + 0.8,
			a,
			x + 0.08 + off,
			top - 0.7,
			a + (z2 - z1) / n,
			rgb(196, 226, 220),
			"Fabric"
		)
	end
end

local function clinic(r: R, b: Box)
	local w, d = b.x2 - b.x1, b.z2 - b.z1
	local cx = (b.x1 + b.x2) / 2
	local door = b.door or cx
	local desk = at(b, b.x2 - 4.6, b.z1 + 6.5, 90)
	counter(r, desk)
	stamp(r, desk, "till", drawTill)
	shelves(r, at(b, b.x2 - 0.55, b.z1 + 6.5, 90), "booksA", "booksB")
	stamp(r, at(b, b.x1 + 0.85, b.z1 + 6.0, -90), "seats", drawSeats)
	if d >= 20 then
		stamp(r, at(b, b.x1 + 0.85, b.z1 + 14.5, -90), "seats", drawSeats)
	end
	stamp(r, at(b, b.x1 + 3.6, b.z1 + 10.25, 90), "lowtable", drawLowTable)
	stamp(r, at(b, b.x1 + 1.4, b.z1 + 1.4), "plant", drawPlant)
	stamp(r, at(b, b.x2 - 1.4, b.z1 + 1.4), "plant", drawPlant)
	-- the beds at the back right, each with a curtain on a rail beside it, the red cross over the
	-- first and a drip stand by it
	local beds: { number } = if w >= 40 then { b.x2 - 4, b.x2 - 12 } else { b.x2 - 4 }
	for i, x in beds do
		plain(r, at(b, x, b.z2 - 4.2), drawHospitalBed)
		curtain(r, b, x - 3.9, b.z2 - 8.2, b.z2 - 0.6)
		if i == 1 then
			local c = CFrame.new(x, b.y, b.z2)
			slab(r, c, -1.2, 4.3, -0.25, 1.2, 4.9, -0.05, BERRY, "SmoothPlastic")
			slab(r, c, -0.3, 3.7, -0.25, 0.3, 5.5, -0.05, BERRY, "SmoothPlastic")
		end
	end
	local s = at(b, b.x2 - 1.2, b.z2 - 2.0)
	post(r, s, 0, 0, 0, 0.12, 1.0, STEEL, "Metal")
	post(r, s, 0, 0.12, 0, 5.6, 0.1, STEEL, "Metal")
	lumpAt(r, s, 0.25, 5.2, 0, 0.4, 0.7, 0.2, rgb(214, 236, 232))
	-- the doctor's corner at the back left: the desk, a chair for the patient, medicine on the
	-- shelves and the scales
	plain(r, at(b, b.x1 + 7, b.z2 - 4.5), drawDesk)
	plain(r, at(b, b.x1 + 7, b.z2 - 7.4, 180), drawChair)
	shelves(r, at(b, b.x1 + 14, b.z2 - 0.55), "jars", "jars")
	local sc = at(b, b.x1 + 11, b.z2 - 2.2)
	slab(r, sc, -0.7, 0, -0.7, 0.7, 0.3, 0.7, STEEL, "Metal")
	post(r, sc, 0, 0.3, 0.5, 4.6, 0.16, STEEL, "Metal")
	slab(r, sc, -0.4, 4.0, 0.3, 0.4, 4.6, 0.62, WHITE, "SmoothPlastic")
	stamp(r, wallAt(b, "left", b.z2 - 4.6, 3.6), "notices", drawNotices)
	stamp(r, wallAt(b, "right", b.z1 + 12.6, 3.4), "landscape", drawLandscape)
	stamp(r, wallAt(b, "back", b.x1 + 7, 5.4), "clock", drawClock)
	runner(r, b, door, b.z1 + 2.2, b.z1 + 12.0, 4.0, rgb(110, 150, 150))
	doormat(r, b)
	lamp(r, b, cx, b.z1 + d * 0.5)
	lamp(r, b, b.x2 - 8, b.z2 - 4.2, false)
	lamp(r, b, b.x1 + 8, b.z1 + 8.0, false)
end

-- Furnishes a room for a kind of place. `tint` is a colour of the building's own to pick up.
function Interiors.fill(r: R, kind: string, b: Box, tint: Color3?)
	if kind == "lobby" then
		lobby(r, b, false)
	elseif kind == "flats" then
		lobby(r, b, true)
	elseif kind == "home" then
		home(r, b, tint or SKY)
	elseif kind == "hut" then
		hut(r, b, tint or SKY)
	elseif kind == "library" then
		library(r, b)
	elseif kind == "museum" then
		museum(r, b)
	elseif kind == "cinema" then
		cinema(r, b)
	elseif kind == "station" then
		station(r, b)
	elseif kind == "school" then
		school(r, b)
	elseif kind == "clinic" then
		clinic(r, b)
	elseif kind == "department" then
		department(r, b)
	else
		shop(r, kind, b)
	end
end

return Interiors
