--!strict
-- Workplaces. Each one opens a job (Data/Jobs) for one villager. The worker stands at `workSpot`
-- (item space) facing `workYaw` degrees (0 faces +Z, the customer side) during work hours, and
-- from there goes round the job's loop of spots (Sim/Routine: the crates, the machine, the
-- board). Those spots name parts drawn here: move a part and its spot moves with it, or the
-- Routine spec will say it stands in something. Each one is drawn with the parts the real thing
-- has (the user: "the amount of detail should be similar to the default house everywhere"),
-- the small repeated ones as pieces so a workplace stays a few dozen parts.

local Recipe = require(script.Parent.Parent.Recipe)
local Colors = require(script.Parent.Parent.Parent.Util.Colors)

local C = Recipe.Colors

type R = Recipe.Recipe

local function shade(c: Color3, k: number): Color3
	return Colors.shade(c, k)
end

-- Woods, metals and paper, from the town's palette
local OAK = Color3.fromRGB(196, 154, 108)
local WALNUT = Color3.fromRGB(154, 107, 72)
local PALE = Color3.fromRGB(221, 190, 148)
local IRON = Color3.fromRGB(90, 85, 96)
local TRIM = Color3.fromRGB(250, 246, 236)
local KRAFT = Color3.fromRGB(196, 154, 98)
local BRASS = Color3.fromRGB(201, 164, 100)
local ZINC = Color3.fromRGB(176, 182, 188)
local SLATE = Color3.fromRGB(58, 70, 66)
local CHALK = Color3.fromRGB(236, 234, 226)
local INK = Color3.fromRGB(70, 66, 74)

-- Food and flowers are small accents: varied, never a pure hue
local APPLE = Color3.fromRGB(190, 72, 70)
local APPLE_BLUSH = Color3.fromRGB(212, 120, 82)
local ORANGE = Color3.fromRGB(232, 148, 70)
local LEMON = Color3.fromRGB(234, 204, 104)
local PEAR = Color3.fromRGB(184, 198, 106)
local CABBAGE = Color3.fromRGB(176, 206, 140)
local CABBAGE_LEAF = Color3.fromRGB(112, 160, 98)
local CARROT = Color3.fromRGB(226, 126, 58)
local STALK = Color3.fromRGB(108, 82, 56)
local CRUST = Color3.fromRGB(214, 166, 104)
local CRUST_DARK = Color3.fromRGB(178, 126, 76)

-- Produce, drawn on a recipe or into a piece at a frame (the middle of the fruit). Apples and
-- oranges are about the same size, so they differ in colour and in what is on top: a stalk and
-- now and then a leaf on an apple, a little green star on an orange.
local function apple(q: R, at: CFrame, col: Color3, leaf: boolean)
	local p = at.Position
	q:ball(p.X, p.Y, p.Z, 0.44, col)
	q:boxAt(at * CFrame.new(0.02, 0.24, 0) * CFrame.Angles(0, 0, -0.35), 0.05, 0.16, 0.05, STALK)
	if leaf then
		q:lump(at * CFrame.new(0.12, 0.25, 0.02) * CFrame.Angles(0.2, 0, -0.7), 0.2, 0.05, 0.11, C.Leaf)
	end
end

local function orange(q: R, at: CFrame)
	q:lump(at, 0.5, 0.46, 0.5, ORANGE)
	q:boxAt(at * CFrame.new(0, 0.23, 0) * CFrame.Angles(0, math.rad(45), 0), 0.12, 0.04, 0.12, C.DarkLeaf)
end

-- A cabbage: a pale heart with three dark outer leaves cupped round it.
local function cabbage(q: R, at: CFrame, turn: number)
	q:lump(at * CFrame.Angles(0, turn, 0), 0.62, 0.56, 0.62, CABBAGE)
	for k = 0, 2 do
		local a = turn + k * math.pi * 2 / 3
		local leaf = at * CFrame.Angles(0, a, 0) * CFrame.new(0, -0.04, 0.26) * CFrame.Angles(-0.5, 0, 0)
		q:lump(leaf, 0.5, 0.42, 0.14, CABBAGE_LEAF)
	end
end

-- A carrot lying along +z from `at` (its thick end), with its leafy top behind.
local function carrot(q: R, at: CFrame)
	q:add({
		shape = "Cone",
		cf = at * CFrame.new(0, 0, 0.42) * CFrame.Angles(math.rad(90), 0, 0),
		size = Vector3.new(0.24, 0.84, 0.24),
		color = CARROT,
		mat = "SmoothPlastic",
	})
	for _, a in { -0.4, 0.4 } do
		q:boxAt(at * CFrame.Angles(0, a, 0) * CFrame.new(0, 0.06, -0.2), 0.07, 0.06, 0.42, C.Leaf)
	end
end

-- An open crate of slats, standing on its floor at `cf`: w across, d deep, h tall.
local function crate(q: R, cf: CFrame, w: number, d: number, h: number, col: Color3)
	q:boxAt(cf * CFrame.new(0, 0.09, 0), w - 0.06, 0.1, d - 0.06, shade(col, 0.8), "Wood")
	for _, s in { -1, 1 } do
		q:boxAt(cf * CFrame.new(0, 0.2, s * (d / 2 - 0.04)), w - 0.2, 0.18, 0.08, col, "Wood")
		q:boxAt(cf * CFrame.new(0, h - 0.1, s * (d / 2 - 0.04)), w - 0.2, 0.18, 0.08, col, "Wood")
		q:boxAt(cf * CFrame.new(s * (w / 2 - 0.05), h / 2, 0), 0.1, h, d, shade(col, 0.9), "Wood")
	end
end

-- A price card on a stick, pushed into whatever it stands in: (x, y, z) is the stick's foot.
local function ticket(q: R, x: number, y: number, z: number, card: Color3)
	q:block(x - 0.03, y, z - 0.03, x + 0.03, y + 0.7, z + 0.03, PALE)
	q:boxAt(CFrame.new(x, y + 0.78, z + 0.04) * CFrame.Angles(math.rad(-12), 0, 0), 0.5, 0.32, 0.04, card)
end

-- A wheel for a cart, its axle along z: an iron tyre and a wooden rim of eight segments each,
-- six spokes and a hub. One piece.
local function cartWheel(r: R, x: number, y: number, z: number, d: number, wood: Color3)
	r:piece(function(q: R)
		local c = CFrame.new(x, y, z)
		local tyre, rim = d / 2 - 0.05, d / 2 - 0.17
		for k = 0, 7 do
			local turn = c * CFrame.Angles(0, 0, k * math.pi / 4)
			q:boxAt(turn * CFrame.new(0, tyre, 0), d * 0.42, 0.1, 0.12, IRON)
			q:boxAt(turn * CFrame.new(0, rim, 0), d * 0.36, 0.16, 0.2, wood)
		end
		for k = 0, 2 do
			q:boxAt(c * CFrame.Angles(0, 0, k * math.pi / 3 + math.pi / 6), 0.08, d - 0.4, 0.08, wood)
		end
		q:cyl(x, y, z, 0.3, 0.36, "z", shade(wood, 0.8))
	end)
end

-- Turned posts: a square foot, a round shaft with a collar near each end, and a square cap.
-- Drawn into a piece; h is the post's height, d its thickness.
local function turnedPost(q: R, x: number, z: number, h: number, d: number, col: Color3)
	q:block(x - d / 2 - 0.06, 0, z - d / 2 - 0.06, x + d / 2 + 0.06, 0.45, z + d / 2 + 0.06, col, "Wood")
	q:cyl(x, 0.55, z, 0.22, d + 0.08, "y", col, "Wood")
	q:cyl(x, h / 2, z, h - 1.2, d, "y", col, "Wood")
	q:cyl(x, h - 0.6, z, 0.2, d + 0.08, "y", col, "Wood")
	q:block(x - d / 2 - 0.04, h - 0.5, z - d / 2 - 0.04, x + d / 2 + 0.04, h, z + d / 2 + 0.04, col, "Wood")
end

-- A row of standing books on a shelf, x1 to x2 along it, spines at z = zf facing +z, at most
-- maxH tall. Thin spines of muted colours and different heights, now and then one leaning on
-- its neighbour and a short pile lying flat. One piece a row.
local SPINES = {
	Color3.fromRGB(168, 84, 76),
	Color3.fromRGB(84, 112, 142),
	Color3.fromRGB(132, 166, 132),
	Color3.fromRGB(214, 180, 104),
	Color3.fromRGB(128, 92, 118),
	Color3.fromRGB(230, 220, 196),
	Color3.fromRGB(196, 124, 92),
	Color3.fromRGB(70, 104, 88),
	Color3.fromRGB(96, 90, 100),
}
local function books(r: R, x1: number, x2: number, y: number, maxH: number, zf: number, depth: number, seed: number)
	local s = seed
	local function rand(): number
		s = (s * 1103515245 + 12345) % 2147483648
		return s / 2147483648
	end
	r:piece(function(q: R)
		local x = x1
		local n = 0
		while x < x2 - 0.25 and n < 24 do
			local w = math.min(0.18 + rand() * 0.16, x2 - x)
			local h = maxH * (0.7 + rand() * 0.3)
			local col = SPINES[1 + math.floor(rand() * #SPINES)]
			local back = zf - depth + rand() * 0.08
			if n == 4 and x + 1.0 < x2 then
				-- a little pile lying flat
				for k = 0, 2 do
					local t = 0.12 + k * 0.02
					local lo = y + k * 0.14
					q:block(x + k * 0.03, lo, back + k * 0.04, x + 0.8 - k * 0.04, lo + t, zf - 0.04, SPINES[(n + k) % 9 + 1])
				end
				x += 0.86
			elseif n == 9 and x + w + 0.2 < x2 then
				-- one leaning on its neighbour
				local lean = CFrame.new(x + w / 2 + h * 0.13, y + h * 0.49, (back + zf) / 2) * CFrame.Angles(0, 0, -0.28)
				q:boxAt(lean, w - 0.03, h, zf - back, col)
				x += w + 0.32
			else
				q:block(x, y, back, x + w - 0.03, y + h, zf, col)
				x += w
			end
			n += 1
		end
	end)
end

-- A striped cloth awning on a slope: stripes running back to front, a valance across the front
-- with a scalloped edge, and plain valances down the sides. Its top runs from (yBack at zBack)
-- down to (yFront at zFront), w across. One piece a colour.
local function stripedAwning(
	r: R,
	w: number,
	zBack: number,
	zFront: number,
	yBack: number,
	yFront: number,
	n: number,
	c1: Color3,
	c2: Color3
)
	local run = zFront - zBack
	local fall = yBack - yFront
	local len = math.sqrt(run * run + fall * fall)
	local tilt = math.atan2(fall, run)
	local sw = w / n
	local deep = 0.42 -- the valance
	for pass, col in { c1, c2 } do
		r:piece(function(q: R)
			for i = 0, n - 1 do
				if i % 2 == pass - 1 then
					local x = -w / 2 + (i + 0.5) * sw
					local mid = CFrame.new(x, (yBack + yFront) / 2, (zBack + zFront) / 2) * CFrame.Angles(tilt, 0, 0)
					q:boxAt(mid, sw, 0.08, len, col, "Fabric")
					q:block(x - sw / 2, yFront - deep, zFront - 0.04, x + sw / 2, yFront, zFront + 0.04, col, "Fabric")
					for k = 0, 1 do
						q:cyl(x - sw / 4 + k * sw / 2, yFront - deep, zFront, 0.06, sw / 2, "z", col, "Fabric")
					end
				end
			end
			if pass == 1 then
				for _, s in { -1, 1 } do
					local mid = CFrame.new(s * (w / 2 + 0.01), (yBack + yFront) / 2 - deep / 2, (zBack + zFront) / 2)
						* CFrame.Angles(tilt, 0, 0)
					q:boxAt(mid, 0.06, deep, len, col, "Fabric")
				end
			end
		end)
	end
end

-- A counter you serve across: the customer side is +Z. A body (c1), a top (c2) with a lip
-- that stands proud of it all round, raised panels down the front and a dark kick at its foot.
local function counter(r: R, w: number, d: number, h: number, body: Color3, top: Color3)
	r:block(-w / 2, 0.2, -d / 2, w / 2, h - 0.2, d / 2, body, "Wood")
	r:block(-w / 2 + 0.06, 0, -d / 2 + 0.06, w / 2 - 0.06, 0.2, d / 2 - 0.06, shade(body, 0.6), "Wood")
	r:block(-w / 2 - 0.15, h - 0.2, -d / 2 - 0.1, w / 2 + 0.15, h, d / 2 + 0.15, top, "Wood")
	r:piece(function(q: R)
		q:block(-w / 2 - 0.08, h - 0.32, -d / 2 - 0.04, w / 2 + 0.08, h - 0.2, d / 2 + 0.08, shade(top, 0.86), "Wood")
		local panels = math.max(2, math.floor(w / 1.6 + 0.5))
		local pw = (w - 0.3) / panels
		for i = 0, panels - 1 do
			local x1 = -w / 2 + 0.15 + i * pw + 0.12
			local x2 = x1 + pw - 0.24
			q:block(x1, 0.5, d / 2, x2, h - 0.62, d / 2 + 0.06, shade(body, 1.08), "Wood")
		end
	end)
end

local function wheel(r: R, x: number, y: number, z: number, d: number)
	r:cyl(x, y, z, 0.3, d, "x", C.Black, "SmoothPlastic")
	r:cyl(x, y, z, 0.34, d * 0.4, "x", C.Metal, "Metal")
end

local WOOD = Color3.fromRGB(150, 100, 60)
local DARK = Color3.fromRGB(105, 70, 42)

local items: { any } = {
	{
		id = "work_market",
		name = "Market stall",
		cat = "work",
		price = 450,
		place = "floor",
		job = "shopkeeper",
		size = Vector3.new(8, 9.5, 6),
		c1 = "6FA86A",
		c2 = "FAF6EC",
		tags = { "work" },
		workSpot = Vector3.new(0, 0, -2.2),
		workYaw = 0,
		build = function(r: R)
			-- A greengrocer's stall: a boarded counter with a sloping display of four crates
			-- tipped toward whoever is buying, the till and the scale behind them, under a
			-- striped cloth awning (c1 and c2) on four turned posts. Price cards in the crates,
			-- a chalk board hung from the front rail, spare stock on the shelf underneath.
			local H = 3.2 -- the counter's top
			-- the frame: four turned posts and the rails along their tops
			r:piece(function(q: R)
				for _, x in { -3.8, 3.8 } do
					turnedPost(q, x, -2.8, 8.7, 0.3, WALNUT)
					turnedPost(q, x, 0.85, 7.55, 0.3, WALNUT)
				end
				q:block(-3.95, 8.42, -2.92, 3.95, 8.62, -2.68, WALNUT, "Wood")
				q:block(-3.95, 7.28, 0.74, 3.95, 7.48, 0.96, WALNUT, "Wood")
				for _, x in { -3.8, 3.8 } do
					q:beam(Vector3.new(x, 8.52, -2.8), Vector3.new(x, 7.38, 0.85), 0.18, 0.2, WALNUT, "Wood")
				end
			end, true)
			stripedAwning(r, 8.4, -3.1, 2.55, 8.86, 7.15, 8, r.c1, r.c2)
			-- the counter: a dark body, boards down the front and the ends, a thick top
			r:block(-3.4, 0, -0.55, 3.4, H - 0.2, 0.9, shade(WALNUT, 0.7), "Wood")
			r:block(-3.6, H - 0.22, -1.12, 3.6, H, 1.1, WALNUT, "WoodPlanks")
			r:piece(function(q: R)
				for i = 0, 8 do
					local x = -3.4 + i * (6.8 / 9)
					local col = if i % 2 == 0 then OAK else shade(OAK, 0.92)
					q:block(x + 0.03, 0.1, 0.9, x + 6.8 / 9 - 0.03, H - 0.24, 0.98, col, "Wood")
				end
				q:block(-3.44, H - 0.6, 0.98, 3.44, H - 0.3, 1.04, shade(OAK, 0.84), "Wood")
				q:block(-3.44, 0.1, 0.98, 3.44, 0.4, 1.04, shade(OAK, 0.84), "Wood")
				for _, s in { -1, 1 } do
					q:block(s * 3.4 - 0.08, 0, -1.08, s * 3.4 + 0.08, H - 0.24, 1.0, OAK, "Wood")
				end
				-- the shelf underneath, on the server's side
				q:block(-3.32, 0.26, -1.06, 3.32, 0.38, -0.5, shade(OAK, 0.9), "Wood")
				q:block(-3.32, 1.56, -1.06, 3.32, 1.68, -0.5, shade(OAK, 0.9), "Wood")
			end, true)
			-- the display: four crates tipped forward on a riser, and a step behind them
			r:block(-3.5, H, -1.08, 3.5, H + 0.42, -0.2, shade(OAK, 0.86), "Wood")
			local tip = CFrame.Angles(math.rad(18), 0, 0)
			local crates = {}
			for i = 0, 3 do
				local x = -2.55 + i * 1.7
				local cf = CFrame.new(x, H + 0.28, 0.42) * tip
				crates[i + 1] = cf
			end
			for _, cf in crates do
				r:piece(function(q: R)
					q:block(cf.X - 0.7, H, -0.2, cf.X + 0.7, H + 0.3, 0.05, shade(OAK, 0.7), "Wood")
					crate(q, cf * CFrame.new(0, -0.05, 0), 1.6, 1.24, 0.5, PALE)
				end)
			end
			-- apples, oranges, cabbages and carrots, a card stuck in each
			local cards = { C.Paper, LEMON, C.Paper, LEMON }
			for i, cf in crates do
				r:piece(function(q: R)
					local at = cf * CFrame.new(0, 0.3, 0)
					if i == 1 then
						for k = 0, 8 do
							local col = if k % 3 == 1 then APPLE_BLUSH else APPLE
							apple(q, at * CFrame.new(-0.48 + (k % 3) * 0.48, (k // 3) % 2 * 0.06, -0.36 + (k // 3) * 0.36), col, k % 4 == 0)
						end
					elseif i == 2 then
						for k = 0, 8 do
							orange(q, at * CFrame.new(-0.46 + (k % 3) * 0.46, ((k + 1) % 2) * 0.05, -0.33 + (k // 3) * 0.33))
						end
					elseif i == 3 then
						for k = 0, 3 do
							cabbage(q, at * CFrame.new(-0.36 + (k % 2) * 0.72, 0.06, -0.26 + (k // 2) * 0.52), k * 1.3)
						end
					else
						for k = 0, 6 do
							carrot(q, at * CFrame.new(-0.6 + k * 0.2, (k % 2) * 0.1, -0.42) * CFrame.Angles(0, (k % 3 - 1) * 0.12, 0))
						end
					end
					local foot = cf * CFrame.new(0.5, 0.1, -0.45)
					ticket(q, foot.X, foot.Y, foot.Z, cards[i])
				end)
			end
			-- the till in front of the server, facing them, its drawer at the bottom
			r:piece(function(q: R)
				local y = H + 0.42
				q:block(-0.6, y, -1.0, 0.5, y + 0.52, -0.36, BRASS)
				q:block(-0.56, y + 0.04, -1.06, 0.46, y + 0.24, -1.0, shade(BRASS, 0.85))
				q:block(-0.14, y + 0.11, -1.1, 0.04, y + 0.16, -1.06, IRON)
				q:boxAt(CFrame.new(-0.05, y + 0.62, -0.78) * CFrame.Angles(math.rad(-30), 0, 0), 1.0, 0.1, 0.52, shade(BRASS, 0.9))
				q:block(-0.45, y + 0.52, -0.56, 0.35, y + 1.0, -0.4, BRASS)
				q:boxAt(CFrame.new(-0.05, y + 0.92, -0.33) * CFrame.Angles(math.rad(20), 0, 0), 0.6, 0.24, 0.06, shade(BRASS, 0.7))
			end)
			r:piece(function(q: R)
				local y = H + 0.42
				local slope = CFrame.new(-0.05, y + 0.62, -0.78) * CFrame.Angles(math.rad(-30), 0, 0)
				q:block(-0.4, y + 0.99, -0.52, 0.3, y + 1.03, -0.44, C.Paper)
				for row = 0, 2 do
					for col = 0, 3 do
						q:boxAt(slope * CFrame.new(-0.33 + col * 0.22, 0.07, -0.15 + row * 0.15), 0.14, 0.06, 0.1, CHALK)
					end
				end
			end)
			-- the scale: an enamel stand with a round dial to the customer and a pan on top
			r:piece(function(q: R)
				local x, y = 2.2, H + 0.42
				q:block(x - 0.5, y, -0.98, x + 0.5, y + 0.2, -0.36, TRIM)
				q:block(x - 0.16, y + 0.2, -0.76, x + 0.16, y + 0.62, -0.56, TRIM)
				q:cyl(x, y + 0.98, -0.66, 0.22, 0.86, "z", TRIM, "SmoothPlastic")
				q:cyl(x, y + 0.98, -0.66, 0.3, 0.7, "z", C.White, "SmoothPlastic")
				q:boxAt(CFrame.new(x + 0.08, y + 1.06, -0.49) * CFrame.Angles(0, 0, -0.7), 0.05, 0.3, 0.04, APPLE)
				q:block(x - 0.06, y + 1.38, -0.72, x + 0.06, y + 1.52, -0.6, TRIM)
			end)
			r:piece(function(q: R)
				local x, y = 2.2, H + 1.94
				q:block(x - 0.06, y - 0.06, -0.72, x + 0.06, y, -0.6, ZINC, "Metal")
				q:cyl(x, y + 0.04, -0.66, 0.08, 1.0, "y", ZINC, "Metal")
				q:cyl(x, y + 0.11, -0.66, 0.08, 0.86, "y", shade(ZINC, 0.86), "Metal")
			end)
			r:piece(function(q: R)
				local x, y = 2.2, H + 2.18
				apple(q, CFrame.new(x - 0.16, y, -0.62), APPLE, false)
				apple(q, CFrame.new(x + 0.18, y, -0.7), APPLE_BLUSH, true)
				-- a basket of pears at the other end of the step
				q:block(-2.93, H + 0.42, -0.96, -1.77, H + 0.5, -0.34, shade(KRAFT, 0.8))
				for k = 0, 5 do
					local px = -2.65 + (k % 3) * 0.32
					local pz = -0.75 + (k // 3) * 0.24
					q:lump(CFrame.new(px, H + 0.74, pz) * CFrame.Angles(0, 0, (k % 2 - 0.5) * 0.4), 0.36, 0.44, 0.36, PEAR)
					q:lump(CFrame.new(px, H + 0.96, pz), 0.24, 0.24, 0.24, PEAR)
				end
			end)
			r:piece(function(q: R)
				-- the basket's sides
				q:block(-2.95, H + 0.42, -1.0, -1.75, H + 0.82, -0.94, KRAFT, "Fabric")
				q:block(-2.95, H + 0.42, -0.36, -1.75, H + 0.82, -0.3, KRAFT, "Fabric")
				q:block(-3.0, H + 0.42, -1.0, -2.94, H + 0.82, -0.3, KRAFT, "Fabric")
				q:block(-1.76, H + 0.42, -1.0, -1.7, H + 0.82, -0.3, KRAFT, "Fabric")
				q:beam(Vector3.new(-2.94, H + 0.82, -0.65), Vector3.new(-2.35, H + 1.4, -0.65), 0.06, 0.08, KRAFT, "Fabric")
				q:beam(Vector3.new(-1.76, H + 0.82, -0.65), Vector3.new(-2.35, H + 1.4, -0.65), 0.06, 0.08, KRAFT, "Fabric")
			end)
			-- spare stock on the shelf: a crate, a sack of potatoes and a stack of paper bags
			r:piece(function(q: R)
				crate(q, CFrame.new(-2.2, 0.38, -0.78), 1.4, 0.5, 0.5, PALE)
			end)
			r:piece(function(q: R)
				q:block(1.3, 0.38, -1.0, 2.1, 0.46, -0.56, KRAFT, "Fabric")
				q:block(1.32, 0.46, -0.98, 2.08, 0.54, -0.58, shade(KRAFT, 0.92), "Fabric")
				q:block(-0.6, 0.38, -0.95, 0.6, 0.42, -0.6, KRAFT, "Fabric")
				q:lump(CFrame.new(0, 0.82, -0.78), 1.2, 0.86, 0.5, Color3.fromRGB(190, 168, 128), "Fabric")
				q:lump(CFrame.new(0, 1.28, -0.78) * CFrame.Angles(0, 0, 0.2), 0.5, 0.26, 0.3, Color3.fromRGB(176, 154, 116), "Fabric")
			end)
			-- the price board: a slate hung on a nail on the front post, by its string
			r:piece(function(q: R)
				q:block(3.24, 3.9, 1.0, 4.36, 4.86, 1.1, WALNUT, "Wood")
				q:block(3.78, 5.1, 0.96, 3.82, 5.16, 1.06, IRON, "Wood")
				q:beam(Vector3.new(3.36, 4.86, 1.05), Vector3.new(3.8, 5.14, 1.05), 0.03, 0.03, KRAFT, "Wood")
				q:beam(Vector3.new(4.24, 4.86, 1.05), Vector3.new(3.8, 5.14, 1.05), 0.03, 0.03, KRAFT, "Wood")
			end)
			r:piece(function(q: R)
				q:block(3.32, 3.98, 1.1, 4.28, 4.78, 1.14, SLATE)
				for i, w in { 0.6, 0.44, 0.66, 0.5 } do
					local y = 4.68 - i * 0.15
					q:block(3.42, y, 1.14, 3.42 + w, y + 0.05, 1.18, CHALK)
				end
				q:block(4.0, 4.04, 1.14, 4.2, 4.2, 1.18, LEMON)
			end)
			-- a string of onions at one end of the awning, a bunch of garlic at the other
			r:piece(function(q: R)
				for _, e in { { -3.4, Color3.fromRGB(214, 164, 92) }, { 3.4, Color3.fromRGB(238, 230, 214) } } do
					local x, col = e[1], e[2]
					q:block(x - 0.03, 5.9, 2.17, x + 0.03, 7.2, 2.23, KRAFT)
					for k = 0, 3 do
						q:lump(CFrame.new(x + (k % 2 - 0.5) * 0.24, 6.55 - k * 0.2, 2.2), 0.34, 0.3, 0.32, col)
					end
				end
			end)
			-- a sack of potatoes on the ground by the front corner
			r:noCollide(r:lump(CFrame.new(-3.0, 0.55, 1.75), 1.0, 1.1, 0.9, Color3.fromRGB(190, 168, 128), "Fabric"))
			r:piece(function(q: R)
				q:block(-2.45, 0, 1.95, -2.2, 0.18, 2.15, Color3.fromRGB(196, 160, 112))
				for k = 0, 2 do
					q:ball(-3.15 + k * 0.28, 1.2, 1.72 + (k % 2) * 0.12, 0.3, Color3.fromRGB(196, 160, 112))
				end
			end)
		end,
	},
	{
		id = "work_cafe",
		name = "Cafe counter",
		cat = "work",
		price = 520,
		place = "floor",
		job = "barista",
		size = Vector3.new(8, 5.5, 3),
		c1 = "8A5A3C",
		c2 = "F2ECE0",
		tags = { "work" },
		workSpot = Vector3.new(0, 0, -2.4),
		workYaw = 0,
		build = function(r: R)
			-- A café's counter (c1, its top c2): the espresso machine at one end with its grinder
			-- and a jug of milk, the till in the middle, cups stacked to hand, then croissants on
			-- a board, a cake under a glass bell and the syrups at the other end. A brass rail
			-- runs along the foot of the front.
			local H = 3.6
			counter(r, 7.6, 2.2, H, r.c1, r.c2)
			r:piece(function(q: R)
				for _, x in { -3.1, 0, 3.1 } do
					q:block(x - 0.06, 0.3, 1.1, x + 0.06, 0.44, 1.38, BRASS, "Metal")
				end
				q:cyl(0, 0.37, 1.32, 6.6, 0.14, "x", BRASS, "Metal")
			end)
			-- the barista's side: two fridge doors under the machine, open shelves at the other end
			r:piece(function(q: R)
				for _, e in { { -3.6, -2.0 }, { -1.9, -0.3 } } do
					q:block(e[1], 0.35, -1.16, e[2], 3.1, -1.1, ZINC, "Metal")
					q:block(e[2] - 0.22, 1.4, -1.24, e[2] - 0.14, 2.6, -1.16, shade(ZINC, 0.7), "Metal")
				end
			end)
			r:piece(function(q: R)
				q:block(0.1, 0.35, -1.14, 3.6, 3.1, -1.1, shade(r.c1, 0.45), "Wood")
				for _, y in { 0.35, 1.25, 2.15 } do
					q:block(0.1, y, -1.34, 3.6, y + 0.1, -1.14, shade(r.c1, 0.85), "Wood")
				end
			end)
			r:piece(function(q: R)
				-- cups upside down, cartons of milk and a sleeve of paper cups
				for i = 0, 5 do
					q:cyl(0.5 + i * 0.32, 1.47, -1.24, 0.24, 0.24, "y", C.White)
				end
				for i = 0, 2 do
					q:block(2.55 + i * 0.32, 0.45, -1.32, 2.81 + i * 0.32, 1.0, -1.18, C.Paper)
					q:block(2.6 + i * 0.32, 0.78, -1.36, 2.76 + i * 0.32, 0.92, -1.3, Color3.fromRGB(84, 112, 142))
				end
				q:block(0.4, 0.45, -1.3, 2.2, 0.9, -1.16, KRAFT)
				for i = 0, 2 do
					q:cyl(0.6 + i * 0.4, 2.55, -1.24, 0.6, 0.3, "y", C.Paper)
				end
				q:cyl(2.4, 2.4, -1.24, 0.3, 0.34, "y", Color3.fromRGB(122, 88, 66))
				q:cyl(3.0, 2.45, -1.24, 0.4, 0.34, "y", Color3.fromRGB(122, 88, 66))
			end)
			-- the espresso machine, its business end to the barista (-z)
			local MX1, MX2 = -3.4, -1.4
			r:piece(function(q: R)
				q:block(MX1, H, -0.85, MX2, H + 0.15, 0.35, shade(ZINC, 0.72), "Metal")
				q:block(MX1 + 0.1, H + 0.15, -0.7, MX2 - 0.1, H + 1.15, 0.3, Color3.fromRGB(184, 80, 90), "Metal")
				q:block(MX1 + 0.16, H + 0.2, -0.78, MX2 - 0.16, H + 1.1, -0.7, ZINC, "Metal")
				q:block(MX1 + 0.04, H + 1.15, -0.76, MX2 - 0.04, H + 1.25, 0.36, ZINC, "Metal")
				for _, x in { MX1 + 0.08, MX2 - 0.08 } do
					q:block(x - 0.03, H + 1.25, -0.72, x + 0.03, H + 1.45, 0.32, ZINC, "Metal")
				end
				q:block(MX1 + 0.4, H + 0.62, -0.92, MX2 - 0.4, H + 0.78, -0.78, ZINC, "Metal")
				for _, x in { -2.75, -2.05 } do
					q:cyl(x, H + 0.52, -0.92, 0.2, 0.32, "y", ZINC, "Metal")
					q:cyl(x, H + 0.4, -0.92, 0.1, 0.36, "y", IRON, "Metal")
					q:block(x - 0.05, H + 0.37, -1.5, x + 0.05, H + 0.45, -1.06, C.Black, "Metal")
				end
				q:block(MX1 + 0.3, H, -1.16, MX2 - 0.3, H + 0.1, -0.78, shade(ZINC, 0.8), "Metal")
				for i = 0, 2 do
					q:block(MX1 + 0.36, H + 0.1, -1.12 + i * 0.1, MX2 - 0.36, H + 0.14, -1.08 + i * 0.1, ZINC, "Metal")
				end
				q:cyl(-2.4, H + 0.95, -0.81, 0.08, 0.3, "z", TRIM, "Metal")
				q:beam(Vector3.new(MX2 - 0.1, H + 0.95, -0.62), Vector3.new(MX2 + 0.06, H + 0.25, -0.95), 0.07, 0.07, ZINC, "Metal")
			end)
			-- cups: two under the spouts, four warming on top, two stacks of cups and saucers
			r:piece(function(q: R)
				for _, x in { -2.75, -2.05 } do
					q:cyl(x, H + 0.24, -0.95, 0.2, 0.2, "y", C.White)
				end
				for i = 0, 3 do
					q:cyl(-3.1 + i * 0.4, H + 1.37, -0.3 + (i % 2) * 0.3, 0.24, 0.24, "y", C.White)
				end
				for _, x in { 0.95, 1.45 } do
					for k = 0, 2 do
						q:cyl(x, H + 0.03 + k * 0.3, -0.7, 0.06, 0.46, "y", C.White)
						q:cyl(x, H + 0.18 + k * 0.3, -0.7, 0.24, 0.3, "y", C.White)
					end
				end
				q:block(1.8, H, -0.98, 2.04, H + 0.3, -0.74, C.Paper)
			end)
			-- the grinder: a dark stand and a hopper of beans, and a jug of milk beside the steam
			r:piece(function(q: R)
				q:block(-1.2, H, -0.75, -0.6, H + 0.7, -0.15, IRON)
				q:block(-1.1, H + 0.12, -0.85, -0.7, H + 0.18, -0.75, C.Black)
				q:add({
					shape = "Cone",
					cf = CFrame.new(-0.9, H + 1.0, -0.45) * CFrame.Angles(math.pi, 0, 0),
					size = Vector3.new(0.66, 0.6, 0.66),
					color = Color3.fromRGB(122, 88, 66),
					mat = "SmoothPlastic",
				})
				q:cyl(-0.9, H + 1.33, -0.45, 0.08, 0.66, "y", IRON)
				q:cyl(-1.28, H + 0.22, -1.02, 0.44, 0.3, "y", ZINC)
				q:block(-1.31, H + 0.34, -1.24, -1.25, H + 0.42, -1.14, ZINC)
			end)
			-- the till, its screen to the barista and a little one to the customer
			r:piece(function(q: R)
				q:block(-0.15, H, -0.95, 0.75, H + 0.3, -0.25, Color3.fromRGB(90, 85, 96))
				q:block(0.2, H + 0.3, -0.62, 0.4, H + 0.55, -0.5, Color3.fromRGB(90, 85, 96))
				local screen = CFrame.new(0.3, H + 0.78, -0.56) * CFrame.Angles(math.rad(-18), 0, 0)
				q:boxAt(screen, 0.9, 0.56, 0.08, IRON)
				q:boxAt(screen * CFrame.new(0, 0, -0.06), 0.78, 0.44, 0.06, C.Glass)
				q:block(0.5, H + 0.3, -0.25, 0.7, H + 0.5, -0.19, IRON)
				q:block(-0.1, H + 0.3, -0.9, 0.7, H + 0.34, -0.7, CHALK)
			end)
			-- croissants on a board
			r:piece(function(q: R)
				q:block(0.9, H, 0.1, 2.15, H + 0.08, 0.95, PALE, "SmoothPlastic")
				for i, p in { { 1.22, 0.35 }, { 1.82, 0.4 }, { 1.52, 0.75 } } do
					local at = CFrame.new(p[1], H + 0.2, p[2]) * CFrame.Angles(0, i * 0.9, 0)
					q:lump(at, 0.46, 0.26, 0.28, CRUST)
					for _, s in { -1, 1 } do
						q:lump(at * CFrame.new(s * 0.26, -0.03, -0.06) * CFrame.Angles(0, s * 0.7, 0), 0.3, 0.2, 0.2, CRUST_DARK)
					end
				end
			end)
			-- the cake on its stand, under a glass bell
			r:piece(function(q: R)
				q:block(2.65, H, -0.2, 3.05, H + 0.04, 0.2, TRIM)
				q:cyl(2.85, H + 0.04, 0.0, 0.08, 0.7, "y", TRIM)
				q:cyl(2.85, H + 0.28, 0.0, 0.44, 0.14, "y", TRIM)
				q:cyl(2.85, H + 0.52, 0.0, 0.06, 1.1, "y", TRIM)
				q:cyl(2.85, H + 0.75, 0.0, 0.4, 0.8, "y", Color3.fromRGB(232, 168, 178))
				q:cyl(2.85, H + 0.98, 0.0, 0.08, 0.84, "y", C.White)
				for k = 0, 4 do
					local a = k * math.pi * 2 / 5
					q:ball(2.85 + math.cos(a) * 0.28, H + 1.08, 0.0 + math.sin(a) * 0.28, 0.12, APPLE)
				end
			end)
			local bell = r:cyl(2.85, H + 0.98, 0.0, 0.86, 1.2, "y", C.Glass, "Glass")
			bell.transp = 0.6
			bell.collide = false
			local top = r:lump(CFrame.new(2.85, H + 1.4, 0.0), 1.2, 0.4, 1.2, C.Glass, "Glass")
			top.transp = 0.6
			top.collide = false
			r:noCollide(r:ball(2.85, H + 1.64, 0.0, 0.16, ZINC, "Metal"))
			-- three syrups with pumps, and a small standing menu card on the front corner
			r:piece(function(q: R)
				for i, col in { Color3.fromRGB(176, 106, 52), Color3.fromRGB(140, 70, 60), Color3.fromRGB(214, 180, 104) } do
					local x = 3.1 + (i - 2) * 0.28
					q:cyl(x, H + 0.35, -0.9, 0.7, 0.24, "y", col)
					q:cyl(x, H + 0.76, -0.9, 0.12, 0.12, "y", C.Black)
					q:block(x - 0.03, H + 0.8, -0.93, x + 0.03, H + 0.92, -0.87, C.Black)
					q:block(x - 0.02, H + 0.88, -1.03, x + 0.02, H + 0.92, -0.9, C.Black)
				end
				q:boxAt(CFrame.new(3.55, H + 0.32, 0.98) * CFrame.Angles(math.rad(14), 0, 0), 0.6, 0.66, 0.04, SLATE)
				q:boxAt(CFrame.new(3.55, H + 0.32, 0.78) * CFrame.Angles(math.rad(-14), 0, 0), 0.6, 0.66, 0.04, SLATE)
			end)
			r:piece(function(q: R)
				local face = CFrame.new(3.55, H + 0.32, 0.98) * CFrame.Angles(math.rad(14), 0, 0)
				for i, w in { 0.4, 0.28, 0.36 } do
					q:boxAt(face * CFrame.new(-0.05, 0.22 - i * 0.12, 0.04), w, 0.05, 0.04, CHALK)
				end
				q:block(3.1, H, 1.02, 3.4, H + 0.06, 1.08, CHALK)
			end)
		end,
	},
	{
		id = "work_bakery",
		name = "Bread oven",
		cat = "work",
		price = 560,
		place = "floor",
		job = "baker",
		size = Vector3.new(6, 7, 4),
		c1 = "B8665C",
		c2 = "A8A096",
		tags = { "work" },
		workSpot = Vector3.new(0, 0, 3.4),
		workYaw = 180,
		build = function(r: R)
			-- A wood fired oven (c1 the brick, c2 the stone): a brick base with the logs stacked
			-- in an arch under it, a stone hearth that runs out in front as a ledge, a faceted
			-- dome with an arched mouth and the fire inside, the iron door leant beside it and a
			-- chimney with a pot at the back. Loaves on a peel and a basket of them on the ledge.
			local brick, stone = r.c1, r.c2
			local soot = Color3.fromRGB(52, 44, 46)
			local light = shade(brick, 1.16)
			local HEARTH = 2.7
			-- the base, its wood store and the hearth
			r:block(-2.8, 0.25, -1.9, 2.8, 2.4, 1.8, brick, "Brick")
			r:block(-3.0, 2.4, -2.0, 3.0, HEARTH, 2.2, stone, "Concrete")
			r:block(-2.9, 0, -1.95, 2.9, 0.25, 1.86, shade(stone, 0.85), "Concrete")
			r:piece(function(q: R)
				q:block(-0.9, 0.25, 1.8, 0.9, 1.1, 1.9, soot)
				q:cyl(0, 1.1, 1.85, 0.1, 1.8, "z", soot)
			end)
			r:piece(function(q: R)
				-- the logs in the store, their cut ends out
				local log = Color3.fromRGB(196, 156, 108)
				local rows = { { 0.45, 4 }, { 0.8, 3 }, { 1.15, 2 }, { 1.5, 1 } }
				for _, row in rows do
					local y, n = row[1], row[2]
					for i = 0, n - 1 do
						local x = (i - (n - 1) / 2) * 0.42
						q:cyl(x, y, 1.66, 0.56, 0.38, "z", if (i + n) % 2 == 0 then log else shade(log, 0.88))
					end
				end
				q:block(0.11, 0.38, 1.46, 0.31, 0.52, 1.86, log)
			end)
			-- the stone arch over the store, a stone at a time
			r:piece(function(q: R)
				for k = 0, 8 do
					local a = math.rad(k * 22.5)
					local at = CFrame.new(math.cos(a) * 1.06, 1.1 + math.sin(a) * 1.06, 1.9) * CFrame.Angles(0, 0, a)
					q:boxAt(at, 0.3, 0.26, 0.16, stone, "Concrete")
				end
				for _, s in { -1, 1 } do
					q:block(s * 1.06 - 0.15, 0.25, 1.82, s * 1.06 + 0.15, 1.1, 1.98, stone, "Concrete")
				end
			end)
			-- the dome and the porch round its mouth
			r:lump(CFrame.new(0, HEARTH, -0.2), 5.0, 4.4, 3.36, brick, "Brick")
			r:block(-1.25, HEARTH, 0.9, 1.25, 4.7, 1.9, brick, "Brick")
			r:block(-1.38, 4.7, 0.82, 1.38, 4.9, 2.0, stone, "Concrete")
			-- the mouth: dark inside, the fire low in it, a ring of light bricks round it
			r:piece(function(q: R)
				q:block(-0.72, HEARTH, 1.9, 0.72, 3.5, 1.96, soot)
				q:cyl(0, 3.5, 1.93, 0.06, 1.44, "z", soot)
			end)
			local fire = r:block(-0.52, HEARTH, 1.96, 0.52, 3.02, 2.0, Color3.fromRGB(255, 150, 60), "Neon")
			r:fire(fire)
			r:piece(function(q: R)
				for k = 0, 6 do
					local a = math.rad(k * 30)
					local at = CFrame.new(math.cos(a) * 0.92, 3.5 + math.sin(a) * 0.92, 1.95) * CFrame.Angles(0, 0, a)
					q:boxAt(at, 0.36, 0.26, 0.12, light, "Brick")
				end
				for _, s in { -1, 1 } do
					for k = 0, 2 do
						q:block(s * 0.86 - 0.12, HEARTH + k * 0.27, 1.89, s * 0.86 + 0.12, HEARTH + 0.24 + k * 0.27, 2.01, light, "Brick")
					end
				end
			end)
			-- the iron door, leant against the side of the base on its hook
			r:piece(function(q: R)
				local door = CFrame.new(-2.97, 0.6, 0.9) * CFrame.Angles(0, 0, math.rad(-7))
				q:block(-2.88, 1.62, 0.84, -2.8, 1.72, 0.96, IRON, "Metal")
				q:boxAt(door, 0.08, 1.1, 0.9, IRON, "Metal")
				q:cyl(door.X - 0.07, 1.15, 0.9, 0.08, 0.9, "x", IRON, "Metal")
				q:boxAt(door * CFrame.new(-0.07, 0.2, 0), 0.08, 0.08, 0.4, shade(IRON, 1.3), "Metal")
			end)
			-- the chimney, its cap and pot
			r:block(-0.45, 4.2, -1.35, 0.45, 6.55, -0.45, brick, "Brick")
			r:block(-0.58, 6.55, -1.48, 0.58, 6.8, -0.32, stone, "Concrete")
			local pot = r:cyl(0, 7.05, -0.9, 0.5, 0.44, "y", Color3.fromRGB(196, 116, 80), "Brick")
			r:smoke(pot)
			-- the peel on the ledge with two loaves on it, its handle out past the end
			r:piece(function(q: R)
				q:block(1.4, HEARTH, 1.3, 2.4, HEARTH + 0.06, 2.12, PALE, "Wood")
				q:block(2.4, HEARTH + 0.01, 1.66, 3.55, HEARTH + 0.07, 1.78, PALE, "Wood")
			end)
			r:piece(function(q: R)
				q:block(1.6, HEARTH + 0.2, 1.6, 1.76, HEARTH + 0.4, 1.84, CRUST)
				q:lump(CFrame.new(1.68, HEARTH + 0.3, 1.72) * CFrame.Angles(0, 0.3, 0), 0.44, 0.5, 0.86, CRUST)
				q:lump(CFrame.new(2.14, HEARTH + 0.28, 1.68) * CFrame.Angles(0, -0.2, 0), 0.42, 0.46, 0.8, CRUST_DARK)
				for k = 0, 2 do
					q:boxAt(
						CFrame.new(1.68, HEARTH + 0.56, 1.72) * CFrame.Angles(0, 0.3, 0) * CFrame.new(0, 0, -0.24 + k * 0.24),
						0.3,
						0.06,
						0.06,
						C.Paper
					)
				end
			end)
			-- a basket of round loaves on the ledge at the other side, a long one stuck up in it
			r:piece(function(q: R)
				q:block(-2.7, HEARTH, 1.22, -1.5, HEARTH + 0.1, 2.08, KRAFT, "Fabric")
				q:block(-2.74, HEARTH, 1.18, -1.46, HEARTH + 0.42, 1.24, KRAFT, "Fabric")
				q:block(-2.74, HEARTH, 2.06, -1.46, HEARTH + 0.42, 2.12, KRAFT, "Fabric")
				q:block(-2.76, HEARTH, 1.24, -2.7, HEARTH + 0.42, 2.06, KRAFT, "Fabric")
				q:block(-1.5, HEARTH, 1.24, -1.44, HEARTH + 0.42, 2.06, KRAFT, "Fabric")
			end)
			r:piece(function(q: R)
				for i, p in { { -2.35, 1.45 }, { -1.85, 1.5 }, { -2.3, 1.85 }, { -1.8, 1.86 } } do
					q:lump(CFrame.new(p[1], HEARTH + 0.42, p[2]), 0.5, 0.42, 0.5, if i % 2 == 0 then CRUST_DARK else CRUST)
					q:block(p[1] - 0.14, HEARTH + 0.62, p[2] - 0.03, p[1] + 0.14, HEARTH + 0.68, p[2] + 0.03, C.Paper)
				end
				q:lump(CFrame.new(-2.05, HEARTH + 0.9, 1.65) * CFrame.Angles(0.3, 0, -0.35), 0.26, 1.4, 0.26, CRUST)
			end)
			-- a sack of flour against the back corner
			r:noCollide(r:lump(CFrame.new(2.35, 0.6, -2.3), 0.9, 1.2, 0.7, Color3.fromRGB(232, 222, 200), "Fabric"))
		end,
	},
	{
		id = "work_flowers",
		name = "Flower cart",
		cat = "work",
		price = 380,
		place = "floor",
		job = "florist",
		size = Vector3.new(6, 4.6, 3.6),
		c1 = "6A9EA6",
		c2 = "FAF6EC",
		tags = { "work", "plant" },
		workSpot = Vector3.new(0, 0, -2.6),
		workYaw = 0,
		build = function(r: R)
			-- A florist's handcart (c1 the boards, c2 the trim): two big spoked wheels, shafts
			-- and a prop leg at one end, and on its bed six zinc buckets in two rows, each of
			-- one kind: roses, tulips, sunflowers, lavender, daisies and mixed sweet peas. A roll
			-- of brown paper hangs at the other end and a slate of prices on the side.
			local trim = r.c2
			-- the bed: planked sides on a body, trim along the top and the foot, corner posts
			r:block(-2.5, 1.3, -1.0, 2.0, 2.5, 1.0, shade(r.c1, 0.8), "Wood")
			r:piece(function(q: R)
				for _, s in { -1, 1 } do
					for k = 0, 2 do
						local y = 1.4 + k * 0.36
						local col = if k % 2 == 0 then r.c1 else shade(r.c1, 0.93)
						q:block(-2.42, y, s * 1.0 - 0.04, 1.92, y + 0.32, s * 1.0 + 0.04, col, "Wood")
					end
				end
				for _, x in { -2.5, 2.0 } do
					for k = 0, 2 do
						local y = 1.4 + k * 0.36
						q:block(x - 0.04, y, -0.92, x + 0.04, y + 0.32, 0.92, if k % 2 == 0 then r.c1 else shade(r.c1, 0.93), "Wood")
					end
				end
			end, true)
			r:piece(function(q: R)
				q:block(-2.62, 2.5, -1.12, 2.12, 2.62, 1.12, trim, "Wood")
				q:block(-2.64, 1.22, -1.14, 2.14, 1.36, 1.14, trim, "Wood")
				q:block(-2.4, 2.62, -0.98, 1.9, 2.9, -0.02, shade(r.c1, 0.85), "Wood")
				for _, x in { -2.5, 2.0 } do
					for _, z in { -1.0, 1.0 } do
						q:block(x - 0.1, 1.22, z - 0.1, x + 0.1, 2.5, z + 0.1, trim, "Wood")
					end
				end
				-- the frame underneath, the shafts and the prop leg
				for _, z in { -0.7, 0.7 } do
					q:block(-2.4, 1.06, z - 0.09, 2.45, 1.22, z + 0.09, shade(WALNUT, 0.85), "Wood")
					q:beam(Vector3.new(2.05, 2.1, z), Vector3.new(3.3, 2.35, z), 0.12, 0.14, WALNUT, "Wood")
					q:block(2.25, 0, z - 0.07, 2.4, 1.06, z + 0.07, shade(WALNUT, 0.85), "Wood")
				end
				q:cyl(3.24, 2.34, 0, 1.62, 0.16, "z", WALNUT, "Wood")
			end)
			cartWheel(r, -0.7, 1.1, 1.22, 2.2, WALNUT)
			cartWheel(r, -0.7, 1.1, -1.22, 2.2, WALNUT)
			r:piece(function(q: R)
				q:block(-0.78, 1.02, -1.3, -0.62, 1.18, 1.3, IRON, "Metal")
				-- the zinc buckets, the back row a step up, a band round each
				for i = 0, 5 do
					local x = -1.7 + (i % 3) * 1.4
					local back = i >= 3
					local z = if back then -0.5 else 0.5
					local y0 = if back then 2.9 else 2.62
					q:cyl(x, y0 + 0.38, z, 0.76, 0.76, "y", ZINC, "Metal")
					q:cyl(x, y0 + 0.7, z, 0.08, 0.84, "y", shade(ZINC, 0.88), "Metal")
				end
			end)
			-- a bucket of flowers: leaves at its mouth, stems leaning out a little, blooms on top
			local function bucket(x: number, y0: number, z: number, kind: number)
				r:piece(function(q: R)
					local top = y0 + 0.76
					q:block(x - 0.05, top - 0.1, z - 0.05, x + 0.05, top + 0.2, z + 0.05, C.DarkLeaf)
					q:lump(CFrame.new(x - 0.12, top + 0.12, z + 0.06) * CFrame.Angles(0, kind, 0.3), 0.6, 0.3, 0.42, C.Leaf)
					q:lump(CFrame.new(x + 0.14, top + 0.1, z - 0.08) * CFrame.Angles(0, -kind, -0.3), 0.5, 0.28, 0.4, C.DarkLeaf)
					local n = if kind == 4 then 7 else 5
					for k = 0, n - 1 do
						local a = k / n * math.pi * 2 + kind
						local rad = if k == 0 then 0 else 0.22
						local px, pz = x + math.cos(a) * rad, z + math.sin(a) * rad
						local h = 0.55 + ((k * 7 + kind) % 3) * 0.12
						local lean = CFrame.new(px, top + h / 2, pz) * CFrame.Angles(math.sin(a) * rad * 0.8, 0, -math.cos(a) * rad * 0.8)
						q:boxAt(lean, 0.05, h, 0.05, C.DarkLeaf)
						local head = lean * CFrame.new(0, h / 2 + 0.08, 0)
						local p = head.Position
						if kind == 1 then -- roses: a deep head with a darker heart
							q:ball(p.X, p.Y, p.Z, 0.3, Color3.fromRGB(214, 108, 124))
							q:ball(p.X, p.Y + 0.1, p.Z, 0.16, Color3.fromRGB(168, 66, 86))
						elseif kind == 2 then -- tulips: a tall cup
							q:lump(head * CFrame.new(0, 0.06, 0), 0.22, 0.34, 0.22, if k % 2 == 0 then Color3.fromRGB(226, 120, 96) else LEMON)
						elseif kind == 3 then -- sunflowers: a yellow disc with a brown heart, facing out
							local out = Vector3.new(math.cos(a) * 0.3, 0.6, math.sin(a) * 0.3 + 0.8)
							local face = CFrame.lookAt(p, p + out) * CFrame.Angles(0, math.pi / 2, 0)
							q:add({
								shape = "Cylinder",
								cf = face,
								size = Vector3.new(0.06, 0.44, 0.44),
								color = Color3.fromRGB(236, 196, 76),
								mat = "SmoothPlastic",
							})
							q:add({
								shape = "Cylinder",
								cf = face * CFrame.new(0.05, 0, 0),
								size = Vector3.new(0.06, 0.2, 0.2),
								color = Color3.fromRGB(110, 76, 50),
								mat = "SmoothPlastic",
							})
						elseif kind == 4 then -- lavender: thin spikes
							q:lump(head * CFrame.new(0, 0.1, 0), 0.1, 0.42, 0.1, Color3.fromRGB(150, 128, 190))
						elseif kind == 5 then -- daisies: white with a yellow middle
							q:lump(head, 0.32, 0.08, 0.32, C.White)
							q:ball(p.X, p.Y + 0.05, p.Z, 0.12, LEMON)
						else -- sweet peas: soft pinks and lilacs
							local cols = { Color3.fromRGB(232, 168, 190), Color3.fromRGB(190, 172, 214), C.White }
							q:ball(p.X, p.Y, p.Z, 0.26, cols[k % 3 + 1])
							q:ball(p.X + 0.1, p.Y - 0.1, p.Z, 0.2, cols[(k + 1) % 3 + 1])
						end
					end
				end)
			end
			for i = 0, 5 do
				local back = i >= 3
				bucket(-1.7 + (i % 3) * 1.4, if back then 2.9 else 2.62, if back then -0.5 else 0.5, i + 1)
			end
			-- a roll of brown paper at the end, its sheet hanging down, and a ball of string
			r:piece(function(q: R)
				for _, z in { -0.8, 0.8 } do
					q:block(-3.0, 2.2, z - 0.04, -2.54, 2.3, z + 0.04, IRON)
				end
				q:cyl(-2.85, 2.25, 0, 1.5, 0.36, "z", KRAFT)
				q:block(-3.08, 1.3, -0.6, -3.02, 2.25, 0.6, KRAFT)
				q:ball(-2.3, 2.77, 0.75, 0.3, C.Paper)
			end)
			-- the slate of prices on the customer's side, and a card in each front bucket
			r:piece(function(q: R)
				q:block(0.65, 1.5, 1.04, 1.85, 2.36, 1.1, WALNUT)
				q:block(0.73, 1.58, 1.1, 1.77, 2.28, 1.14, SLATE)
				for i, w in { 0.7, 0.5, 0.64 } do
					local y = 2.18 - i * 0.16
					q:block(0.83, y, 1.14, 0.83 + w, y + 0.05, 1.18, CHALK)
				end
				for i = 0, 2 do
					local x = -1.7 + i * 1.4 + 0.3
					ticket(q, x, 3.1, 0.78, if i == 1 then LEMON else C.Paper)
				end
			end)
		end,
	},
	{
		id = "work_easel",
		name = "Artist's easel",
		cat = "work",
		price = 300,
		place = "floor",
		job = "artist",
		size = Vector3.new(3, 6.4, 3),
		c1 = "A8743F",
		c2 = "F4EFE4",
		tags = { "work", "art" },
		workSpot = Vector3.new(0, 0, -2.4),
		workYaw = 0,
		build = function(r: R)
			-- A studio easel (c1): two legs and a third behind, a ledge and a clamp holding a
			-- canvas (c2) that faces the painter, who stands behind it (-z). On it a landscape
			-- half done: sky, hills, a house and a tree, the corner still bare. Beside it a
			-- little table with the palette, a jar of brushes, tubes and a rag; a dust sheet
			-- under it all, and a finished picture leant against the back leg.
			local wood = r.c1
			local lean = math.rad(4.7)
			local function onLegs(y: number): number
				return -0.35 + math.tan(lean) * y
			end
			local L = onLegs(2.4)
			r:piece(function(q: R)
				q:block(-1.1, 2.36, L - 0.45, 1.1, 2.48, L + 0.05, wood, "Wood")
				q:block(-1.1, 2.48, L - 0.45, 1.1, 2.6, L - 0.37, wood, "Wood")
				for _, s in { -1, 1 } do
					q:beam(Vector3.new(s * 0.85, 0, onLegs(0)), Vector3.new(s * 0.14, 6.2, onLegs(6.2)), 0.16, 0.16, wood, "Wood")
				end
				q:beam(Vector3.new(0, 1.0, onLegs(1.0)), Vector3.new(0, 6.35, onLegs(6.35)), 0.18, 0.14, wood, "Wood")
				q:beam(Vector3.new(0, 5.7, onLegs(5.7) + 0.08), Vector3.new(0, 0, 1.35), 0.16, 0.16, wood, "Wood")
				q:beam(Vector3.new(-0.72, 1.1, onLegs(1.1)), Vector3.new(0.72, 1.1, onLegs(1.1)), 0.12, 0.12, wood, "Wood")
				q:beam(Vector3.new(0, 1.1, onLegs(1.1)), Vector3.new(0, 1.1, 1.08), 0.1, 0.1, wood, "Wood")
				-- the clamp over the canvas's top edge
				q:boxAt(CFrame.new(0, 5.42, onLegs(5.42) - 0.24) * CFrame.Angles(lean, 0, 0), 0.3, 0.2, 0.5, shade(wood, 0.8), "Wood")
			end, true)
			-- the canvas on its stretcher: the cloth to the painter, the bars behind
			local canvas = CFrame.new(0, 3.92, onLegs(3.92) - 0.3) * CFrame.Angles(lean, 0, 0)
			r:piece(function(q: R)
				local pale = PALE
				for _, s in { -1, 1 } do
					q:boxAt(canvas * CFrame.new(s * 1.14, 0, 0.08), 0.12, 2.8, 0.16, pale, "Wood")
					q:boxAt(canvas * CFrame.new(0, s * 1.34, 0.08), 2.16, 0.12, 0.16, pale, "Wood")
				end
				q:boxAt(canvas * CFrame.new(0, 0, 0.07), 2.16, 0.1, 0.12, shade(pale, 0.9), "Wood")
				q:boxAt(canvas * CFrame.new(0, 0, 0.11), 0.1, 2.56, 0.12, shade(pale, 0.9), "Wood")
				-- a spare bar on the floor
				q:block(-1.3, 0, 1.55, -0.5, 0.1, 1.67, pale, "Wood")
			end)
			r:piece(function(q: R)
				local function paint(x: number, y: number, w: number, h: number, layer: number, col: Color3, turn: number?)
					q:boxAt(canvas * CFrame.new(x, y, -0.06 - layer * 0.04) * CFrame.Angles(0, 0, turn or 0), w, h, 0.04, col, "Fabric")
				end
				q:boxAt(canvas * CFrame.new(0, 0, -0.02), 2.4, 2.8, 0.04, r.c2, "Fabric")
				paint(0, 0.65, 2.2, 1.3, 0, Color3.fromRGB(172, 206, 222))
				paint(-0.15, -0.55, 1.9, 1.1, 0, Color3.fromRGB(132, 174, 110))
				paint(-0.45, 0.02, 1.5, 0.5, 2, Color3.fromRGB(96, 142, 104), 0.12)
				paint(0.5, 0.05, 1.0, 0.42, 1, Color3.fromRGB(110, 150, 120), -0.18)
				q:add({
					shape = "Cylinder",
					cf = canvas * CFrame.new(0.65, 0.85, -0.12) * CFrame.Angles(0, math.pi / 2, 0),
					size = Vector3.new(0.04, 0.42, 0.42),
					color = Color3.fromRGB(240, 200, 110),
					mat = "Fabric",
				})
				-- the house: a wall, a door and a roof of two slopes
				paint(-0.35, -0.42, 0.5, 0.36, 3, C.Cream)
				paint(-0.35, -0.5, 0.1, 0.2, 4, Color3.fromRGB(150, 92, 70))
				paint(-0.5, -0.13, 0.36, 0.08, 4, Color3.fromRGB(196, 116, 90), 0.6)
				paint(-0.2, -0.13, 0.36, 0.08, 4, Color3.fromRGB(196, 116, 90), -0.6)
				-- the tree
				paint(-0.9, -0.5, 0.08, 0.4, 1, Color3.fromRGB(122, 90, 66))
				q:lump(canvas * CFrame.new(-0.9, -0.18, -0.19), 0.42, 0.42, 0.06, Color3.fromRGB(74, 118, 82), "Fabric")
				-- a rag hung over the ledge
				q:block(0.62, 2.05, L - 0.51, 0.98, 2.64, L - 0.45, Color3.fromRGB(214, 200, 176), "Fabric")
			end)
			-- the dust sheet, spattered
			r:piece(function(q: R)
				q:block(-1.45, 0, -1.95, 1.45, 0.05, 1.0, Color3.fromRGB(226, 218, 200), "Fabric")
				for i, p in { { -0.6, -1.2 }, { 0.4, -0.7 }, { -0.2, 0.6 }, { 0.9, -1.5 }, { -1.0, 0.2 } } do
					local cols = { C.Blue, LEMON, APPLE, Color3.fromRGB(132, 174, 110), C.Blue }
					q:lump(CFrame.new(p[1], 0.06, p[2]) * CFrame.Angles(0, i, 0), 0.26, 0.04, 0.18, cols[i], "Fabric")
				end
			end)
			-- the palette table: a round top on three legs
			r:piece(function(q: R)
				q:block(1.15, 1.1, -1.05, 1.25, 1.18, -0.95, WALNUT, "Wood")
				q:cyl(1.2, 1.24, -1.0, 0.12, 1.1, "y", WALNUT, "Wood")
				for k = 0, 2 do
					local a = k * math.pi * 2 / 3 + 0.4
					q:beam(Vector3.new(1.2 + math.cos(a) * 0.32, 1.18, -1.0 + math.sin(a) * 0.32), Vector3.new(1.2 + math.cos(a) * 0.5, 0, -1.0 + math.sin(a) * 0.5), 0.1, 0.1, WALNUT, "Wood")
				end
			end, true)
			-- on it: the palette with its dabs, tubes of paint, a rag and a jar of brushes
			r:piece(function(q: R)
				local top = 1.3
				q:block(1.4, top, -1.32, 1.52, top + 0.1, -1.24, C.Paper)
				q:lump(CFrame.new(1.0, top + 0.03, -0.92) * CFrame.Angles(0, 0.4, 0), 0.9, 0.06, 0.6, PALE)
				local dabs = { APPLE, LEMON, C.Blue, C.White, Color3.fromRGB(132, 174, 110), Color3.fromRGB(150, 92, 70) }
				for i, col in dabs do
					local a = 0.4 + (i - 1) * 0.55
					q:lump(CFrame.new(1.0 + math.cos(a) * 0.3, top + 0.08, -0.92 + math.sin(a) * 0.2), 0.12, 0.06, 0.12, col)
				end
				q:cyl(1.25, top + 0.06, -0.52, 0.36, 0.12, "x", C.Blue)
				q:lump(CFrame.new(0.92, top + 0.06, -1.32) * CFrame.Angles(0, 0.8, 0.1), 0.34, 0.12, 0.26, Color3.fromRGB(214, 200, 176))
				q:cyl(1.5, top + 0.2, -1.2, 0.4, 0.3, "y", Color3.fromRGB(176, 200, 210))
				for k = 0, 3 do
					local a = k * math.pi / 2 + 0.3
					local foot = Vector3.new(1.5 + math.cos(a) * 0.06, top + 0.2, -1.2 + math.sin(a) * 0.06)
					local tip = foot + Vector3.new(math.cos(a) * 0.14, 0.7, math.sin(a) * 0.14)
					q:beam(foot, tip, 0.05, 0.05, if k % 2 == 0 then WALNUT else C.Red)
					q:beam(tip, tip + (tip - foot).Unit * 0.1, 0.07, 0.07, dabs[k + 1])
				end
			end)
			-- a finished picture leant against the back leg, facing out
			r:piece(function(q: R)
				local pic = CFrame.new(0, 0.55, 1.35) * CFrame.Angles(math.rad(-20), 0, 0)
				q:boxAt(pic, 1.3, 1.06, 0.08, WALNUT)
				q:boxAt(pic * CFrame.new(0, 0, 0.06), 1.12, 0.88, 0.04, Color3.fromRGB(226, 206, 168))
				q:boxAt(pic * CFrame.new(0, -0.1, 0.1), 0.5, 0.56, 0.04, Color3.fromRGB(122, 96, 110))
				q:boxAt(pic * CFrame.new(0, 0.2, 0.14), 0.3, 0.3, 0.04, Color3.fromRGB(232, 196, 170))
				q:block(-0.5, 0, 1.6, 0.5, 0.06, 1.7, WALNUT)
			end)
		end,
	},
	{
		id = "work_clinic",
		name = "Clinic desk",
		cat = "work",
		price = 900,
		place = "floor",
		job = "doctor",
		size = Vector3.new(9, 6, 5),
		c1 = "F6F0E2",
		c2 = "D9707E",
		tags = { "work" },
		workSpot = Vector3.new(-1.8, 0, -2.6),
		workYaw = 0,
		build = function(r: R)
			-- A doctor's corner (c1 the furniture, c2 the stripe and the cross): a desk with a
			-- drawer stand, a screen and keyboard, notes, a lamp, pens and a stethoscope; an
			-- examination couch on a steel frame with a roll of paper across it and a step to
			-- climb on; and a white sign with the cross on a pole by the desk.
			local body = r.c1
			local steel = Color3.fromRGB(176, 182, 190)
			local H = 3.2
			-- the desk: a top, a stand of three drawers, an end panel and a modesty board
			r:block(-2.4, H - 0.16, -1.0, 1.8, H, 1.0, body, "SmoothPlastic")
			r:block(-2.36, 0, -0.9, -1.0, H - 0.16, 0.9, body, "SmoothPlastic")
			r:block(1.56, 0, -0.9, 1.76, H - 0.16, 0.9, body, "SmoothPlastic")
			r:block(-1.0, 0.8, 0.7, 1.56, H - 0.16, 0.82, body, "SmoothPlastic")
			r:piece(function(q: R)
				for k = 0, 2 do
					local y = 0.2 + k * 0.92
					q:block(-2.3, y, -0.96, -1.06, y + 0.82, -0.9, shade(body, 0.94))
					q:block(-1.86, y + 0.56, -1.02, -1.5, y + 0.64, -0.96, steel)
				end
				q:block(-1.0, 1.6, 0.82, 1.56, 1.9, 0.86, r.c2)
				q:block(-2.44, H - 0.3, -1.04, 1.84, H - 0.16, 1.04, shade(body, 0.9))
			end)
			-- the screen, turned to the doctor, its keyboard and mouse
			r:piece(function(q: R)
				q:block(-1.15, H, -0.15, -0.45, H + 0.06, 0.25, Color3.fromRGB(70, 66, 74))
				q:block(-0.86, H + 0.06, 0.0, -0.74, H + 0.5, 0.12, Color3.fromRGB(70, 66, 74))
				local screen = CFrame.new(-0.8, H + 0.95, 0.0) * CFrame.Angles(math.rad(8), 0, 0)
				q:boxAt(screen, 1.5, 0.95, 0.1, Color3.fromRGB(70, 66, 74))
				q:boxAt(screen * CFrame.new(0, 0.03, -0.07), 1.36, 0.8, 0.06, Color3.fromRGB(190, 216, 226))
				q:boxAt(screen * CFrame.new(-0.3, 0.2, -0.11), 0.6, 0.08, 0.04, Color3.fromRGB(120, 160, 186))
				q:boxAt(screen * CFrame.new(-0.2, 0.02, -0.11), 0.8, 0.06, 0.04, Color3.fromRGB(150, 180, 200))
				q:boxAt(screen * CFrame.new(-0.25, -0.12, -0.11), 0.7, 0.06, 0.04, Color3.fromRGB(150, 180, 200))
				q:block(-1.45, H, -0.75, -0.25, H + 0.06, -0.4, Color3.fromRGB(226, 224, 220))
				for i = 0, 2 do
					q:block(-1.4, H + 0.06, -0.72 + i * 0.1, -0.3, H + 0.1, -0.66 + i * 0.1, Color3.fromRGB(196, 194, 192))
				end
				q:lump(CFrame.new(0.0, H + 0.04, -0.58), 0.16, 0.08, 0.24, Color3.fromRGB(226, 224, 220))
			end)
			-- notes, a clipboard, pens in a cup and a box of tissues
			r:piece(function(q: R)
				q:block(0.25, H, -0.75, 1.0, H + 0.06, -0.2, C.Paper)
				q:block(0.29, H + 0.06, -0.72, 0.98, H + 0.12, -0.24, Color3.fromRGB(236, 232, 222))
				q:block(0.2, H + 0.12, -0.5, 0.95, H + 0.16, -0.46, Color3.fromRGB(150, 180, 200))
				q:block(-2.2, H, -0.7, -1.6, H + 0.06, 0.1, Color3.fromRGB(150, 110, 70))
				q:block(-2.14, H + 0.06, -0.62, -1.66, H + 0.1, 0.0, C.Paper)
				q:block(-2.0, H + 0.1, 0.0, -1.8, H + 0.16, 0.08, steel)
				for i = 0, 2 do
					q:block(-2.08, H + 0.1, -0.5 + i * 0.14, -1.72, H + 0.14, -0.46 + i * 0.14, Color3.fromRGB(150, 160, 170))
				end
				q:cyl(1.3, H + 0.22, 0.45, 0.44, 0.3, "y", Color3.fromRGB(106, 150, 160))
				for k = 0, 2 do
					q:beam(Vector3.new(1.3, H + 0.3, 0.45), Vector3.new(1.3 + (k - 1) * 0.12, H + 0.78, 0.45 + (k % 2) * 0.08), 0.05, 0.05, if k == 1 then C.Blue else INK)
				end
				q:block(0.3, H, 0.3, 0.9, H + 0.36, 0.7, Color3.fromRGB(206, 226, 214))
				q:lump(CFrame.new(0.6, H + 0.42, 0.5), 0.26, 0.2, 0.18, C.White)
			end)
			-- the stethoscope lying by the keyboard
			r:piece(function(q: R)
				local y = H + 0.04
				local pts = {
					Vector3.new(-2.0, y, 0.35),
					Vector3.new(-1.8, y, 0.65),
					Vector3.new(-1.4, y, 0.68),
					Vector3.new(-1.25, y, 0.4),
					Vector3.new(-1.45, y, 0.18),
				}
				q:block(-2.05, H, 0.3, -1.95, H + 0.07, 0.4, INK)
				for i = 1, #pts - 1 do
					q:beam(pts[i], pts[i + 1], 0.06, 0.06, INK)
				end
				q:cyl(-1.5, H + 0.05, 0.14, 0.08, 0.22, "y", steel)
				q:beam(pts[1], Vector3.new(-2.25, y, 0.55), 0.05, 0.05, INK)
				q:beam(pts[1], Vector3.new(-2.2, y, 0.22), 0.05, 0.05, INK)
			end)
			-- the lamp, an arm over the notes
			r:piece(function(q: R)
				q:cyl(1.3, H + 0.04, -0.55, 0.08, 0.44, "y", steel)
				q:block(1.26, H + 0.08, -0.59, 1.34, H + 0.14, -0.51, steel)
				q:beam(Vector3.new(1.3, H + 0.08, -0.55), Vector3.new(1.15, H + 0.95, -0.35), 0.07, 0.07, steel)
				q:beam(Vector3.new(1.15, H + 0.95, -0.35), Vector3.new(0.75, H + 1.05, -0.45), 0.07, 0.07, steel)
			end)
			r:add({
				shape = "Cone",
				cf = CFrame.new(0.68, H + 0.92, -0.47),
				size = Vector3.new(0.44, 0.34, 0.44),
				color = r.c2,
				mat = "SmoothPlastic",
				collide = false,
			})
			r:glow(r:noCollide(r:block(0.56, H + 0.7, -0.59, 0.8, H + 0.76, -0.35, C.Warm, "Neon")), 10, 0.7)
			-- the sign with the cross, on a pole by the desk
			r:piece(function(q: R)
				q:block(-3.95, 0, -1.95, -3.45, 0.12, -1.45, steel)
				q:block(-3.74, 0.12, -1.74, -3.66, 4.9, -1.66, steel)
			end, true)
			r:piece(function(q: R)
				q:block(-4.3, 4.6, -1.66, -3.1, 5.8, -1.6, C.White)
				q:block(-3.9, 4.75, -1.6, -3.5, 5.65, -1.56, r.c2)
				q:block(-4.15, 5.0, -1.6, -3.25, 5.4, -1.56, r.c2)
				q:block(-3.9, 4.75, -1.7, -3.5, 5.65, -1.66, r.c2)
				q:block(-4.15, 5.0, -1.7, -3.25, 5.4, -1.66, r.c2)
			end)
			-- the couch: a steel frame on four legs, a padded top that rises at the head
			r:piece(function(q: R)
				for _, x in { 2.5, 4.3 } do
					for _, z in { -1.9, 1.9 } do
						q:block(x - 0.08, 0, z - 0.08, x + 0.08, 2.3, z + 0.08, steel, "Metal")
					end
					q:block(x - 0.06, 0.5, -1.9, x + 0.06, 0.62, 1.9, steel, "Metal")
				end
				q:block(2.4, 2.2, -2.1, 4.4, 2.34, 2.1, steel, "Metal")
			end, true)
			r:block(2.45, 2.34, -1.1, 4.35, 2.74, 2.1, Color3.fromRGB(150, 196, 190), "Fabric")
			r:boxAt(CFrame.new(3.4, 2.82, -1.62) * CFrame.Angles(math.rad(22), 0, 0), 1.9, 0.4, 1.1, Color3.fromRGB(150, 196, 190), "Fabric")
			r:piece(function(q: R)
				-- the paper sheet down the middle, its roll at the head, and a pillow
				q:block(2.85, 2.74, -1.0, 3.95, 2.78, 2.05, C.White, "Fabric")
				q:cyl(3.4, 2.6, -2.05, 1.3, 0.34, "x", C.White, "Fabric")
				q:lump(CFrame.new(3.4, 3.14, -1.6) * CFrame.Angles(math.rad(22), 0, 0), 1.1, 0.26, 0.56, C.White, "Fabric")
			end)
			-- the step to climb up by
			r:piece(function(q: R)
				q:block(1.95, 0, 0.2, 2.35, 1.0, 1.2, steel, "Metal")
				q:block(1.9, 1.0, 0.15, 2.4, 1.08, 1.25, Color3.fromRGB(90, 85, 96), "Metal")
			end, true)
		end,
	},
	{
		id = "work_school",
		name = "Chalkboard",
		cat = "work",
		price = 760,
		place = "floor",
		job = "teacher",
		size = Vector3.new(8, 7.2, 3),
		c1 = "2F4F3A",
		c2 = "A8743F",
		tags = { "work", "books" },
		-- in front of the little desk with room to stand (it was 1.8, right up against the desk)
		workSpot = Vector3.new(0, 0, 2.9),
		workYaw = 0,
		build = function(r: R)
			-- A schoolroom board (c1 the slate, c2 the wood) between two posts on long feet,
			-- a moulded frame, a tray of chalk with the duster and a map rolled up along the
			-- top. Today's lesson is on it: a title, four lines of writing, a sum in dots and a
			-- drawing of a house under the sun. A little desk in front with books, the globe, a
			-- bell and an apple, and the pointer leant against a post.
			local wood = r.c2
			local FRONT = -0.62 -- the slate's face
			r:piece(function(q: R)
				for _, s in { -1, 1 } do
					q:block(s * 3.4, 0.3, -0.92, s * 3.76, 7.0, -0.58, wood, "Wood")
					q:block(s * 3.34, 0, -1.4, s * 3.82, 0.3, -0.1, shade(wood, 0.85), "Wood")
					q:block(s * 3.32, 7.0, -0.96, s * 3.84, 7.12, -0.54, shade(wood, 0.85), "Wood")
				end
				q:block(-3.4, 2.6, -0.8, 3.4, 6.9, -0.7, shade(wood, 0.8), "Wood")
				q:block(-3.4, 6.72, -0.7, 3.4, 6.9, -0.54, wood, "Wood")
				q:block(-3.4, 2.6, -0.7, 3.4, 2.78, -0.54, wood, "Wood")
				for _, s in { -1, 1 } do
					q:block(s * 3.22, 2.78, -0.7, s * 3.4, 6.72, -0.54, wood, "Wood")
				end
				q:block(-3.3, 2.6, -0.54, 3.3, 2.7, -0.3, shade(wood, 0.9), "Wood")
				q:block(-3.3, 2.7, -0.36, 3.3, 2.8, -0.3, shade(wood, 0.9), "Wood")
			end, true)
			r:block(-3.22, 2.78, -0.7, 3.22, 6.72, FRONT, r.c1, "Slate")
			-- the back: two battens and a brace across them
			r:piece(function(q: R)
				for _, y in { 3.0, 6.4 } do
					q:block(-3.4, y - 0.14, -0.88, 3.4, y + 0.14, -0.8, wood, "Wood")
				end
				for _, s in { -1, 1 } do
					q:beam(Vector3.new(s * 3.2, 3.14, -0.84), Vector3.new(0, 6.26, -0.84), 0.08, 0.2, wood, "Wood")
				end
			end)
			-- the map, rolled up over the board on two brackets, its pull ring hanging down
			r:piece(function(q: R)
				for _, x in { -2.9, 2.9 } do
					q:block(x - 0.06, 6.9, -0.72, x + 0.06, 7.12, -0.42, IRON, "Metal")
				end
				q:cyl(0, 7.06, -0.44, 6.2, 0.26, "x", Color3.fromRGB(214, 200, 160), "Metal")
				for _, x in { -3.12, 3.12 } do
					q:cyl(x, 7.06, -0.44, 0.1, 0.32, "x", shade(wood, 0.7), "Metal")
				end
				q:block(-0.03, 6.62, -0.33, 0.03, 6.94, -0.29, IRON, "Metal")
				q:cyl(0, 6.56, -0.31, 0.04, 0.16, "z", IRON, "Metal")
			end)
			-- chalk in the tray and the duster
			r:piece(function(q: R)
				q:block(1.6, 2.7, -0.52, 2.3, 2.84, -0.38, shade(wood, 1.15))
				q:block(1.62, 2.84, -0.5, 2.28, 2.92, -0.4, Color3.fromRGB(150, 150, 156))
				for i, col in { CHALK, CHALK, Color3.fromRGB(236, 186, 196), LEMON } do
					q:cyl(-2.4 + i * 0.5, 2.74, -0.46 + (i % 2) * 0.06, 0.4, 0.08, "x", col)
				end
			end)
			-- the lesson: a title underlined and four lines of writing on the left
			local function stroke(q: R, x: number, y: number, w: number, h: number, col: Color3?)
				q:block(x, y, FRONT, x + w, y + h, FRONT + 0.04, col or CHALK)
			end
			r:piece(function(q: R)
				local x = -2.9
				for _, w in { 0.5, 0.36, 0.62 } do
					stroke(q, x, 6.22, w, 0.12)
					x += w + 0.16
				end
				stroke(q, -2.92, 6.04, 1.9, 0.05)
				local rows = { { 0.5, 0.3, 0.7, 0.4 }, { 0.36, 0.62, 0.3, 0.5 }, { 0.7, 0.42, 0.56, 0.24 }, { 0.3, 0.5, 0.38 } }
				for i, row in rows do
					local wx = -2.9
					for _, w in row do
						stroke(q, wx, 5.66 - i * 0.4, w, 0.08)
						wx += w + 0.14
					end
				end
			end)
			-- a sum in dots: two and three make five
			r:piece(function(q: R)
				local function dots(x: number, n: number): number
					for k = 0, n - 1 do
						q:cyl(x + k * 0.22, 3.4, FRONT + 0.03, 0.06, 0.16, "z", CHALK)
					end
					return x + n * 0.22 + 0.1
				end
				local x = dots(-2.9, 2)
				stroke(q, x, 3.37, 0.22, 0.06)
				stroke(q, x + 0.08, 3.29, 0.06, 0.22)
				x = dots(x + 0.36, 3)
				stroke(q, x, 3.33, 0.24, 0.05)
				stroke(q, x, 3.43, 0.24, 0.05)
				dots(x + 0.36, 5)
			end)
			-- the drawing: a house with a door, a roof in pink chalk and the sun in yellow
			r:piece(function(q: R)
				local pink, yellow = Color3.fromRGB(236, 186, 196), Color3.fromRGB(240, 222, 150)
				stroke(q, 0.8, 3.3, 0.06, 0.9)
				stroke(q, 1.94, 3.3, 0.06, 0.9)
				stroke(q, 0.8, 3.3, 1.2, 0.06)
				stroke(q, 1.24, 3.36, 0.05, 0.42)
				stroke(q, 1.5, 3.36, 0.05, 0.42)
				stroke(q, 1.24, 3.74, 0.31, 0.05)
				for _, s in { -1, 1 } do
					local cf = CFrame.new(1.4 + s * 0.34, 4.42, FRONT + 0.03) * CFrame.Angles(0, 0, -s * 0.62)
					q:boxAt(cf, 0.84, 0.06, 0.06, pink)
				end
				q:cyl(2.55, 5.5, FRONT + 0.03, 0.06, 0.42, "z", yellow)
				for k = 0, 5 do
					local a = k * math.pi / 3 + 0.3
					local cf = CFrame.new(2.55 + math.cos(a) * 0.42, 5.5 + math.sin(a) * 0.42, FRONT + 0.03) * CFrame.Angles(0, 0, a)
					q:boxAt(cf, 0.2, 0.05, 0.06, yellow)
				end
			end)
			-- the little desk: a top, a drawer to the front and four legs
			r:block(-1.1, 2.4, 0.4, 1.1, 2.6, 1.5, wood, "Wood")
			r:piece(function(q: R)
				for _, x in { -0.95, 0.95 } do
					for _, z in { 0.55, 1.35 } do
						q:block(x - 0.1, 0, z - 0.1, x + 0.1, 2.4, z + 0.1, shade(wood, 0.85), "Wood")
					end
				end
				q:block(-0.85, 1.9, 0.45, 0.85, 2.4, 1.45, shade(wood, 0.9), "Wood")
				q:block(-0.6, 1.98, 1.45, 0.6, 2.32, 1.5, wood, "Wood")
				q:block(-0.12, 2.1, 1.5, 0.12, 2.18, 1.56, BRASS, "Wood")
			end, true)
			-- on it: a pile of books, the globe, a bell and an apple
			r:piece(function(q: R)
				local y = 2.6
				for i, col in { SPINES[2], SPINES[1], SPINES[4] } do
					local lo = y + (i - 1) * 0.16
					local a, b = -0.95 + i * 0.03, -0.35 - i * 0.02
					local z1, z2 = 0.55, 1.05 - i * 0.03
					q:block(a, lo, z1, b, lo + 0.03, z2, col)
					q:block(a, lo + 0.13, z1, b, lo + 0.16, z2, col)
					q:block(a, lo + 0.03, z1, a + 0.03, lo + 0.13, z2, col)
					q:block(a + 0.03, lo + 0.03, z1 + 0.02, b - 0.02, lo + 0.13, z2 - 0.02, C.Paper)
				end
				q:add({
					shape = "Cone",
					cf = CFrame.new(0.75, y + 0.14, 0.7),
					size = Vector3.new(0.34, 0.28, 0.34),
					color = BRASS,
					mat = "SmoothPlastic",
				})
				q:block(0.72, y + 0.22, 0.67, 0.78, y + 0.44, 0.73, WALNUT)
				q:ball(0.75, y + 0.48, 0.7, 0.12, WALNUT)
				apple(q, CFrame.new(0.55, y + 0.2, 1.2), APPLE, true)
			end)
			r:piece(function(q: R)
				local y = 2.6
				local c = Vector3.new(0.05, y + 0.72, 0.85)
				q:cyl(0.05, y + 0.03, 0.85, 0.06, 0.42, "y", WALNUT)
				q:block(0.02, y + 0.06, 0.82, 0.08, y + 0.4, 0.88, WALNUT)
				q:ball(c.X, c.Y, c.Z, 0.62, Color3.fromRGB(110, 160, 196))
				for i, d in { Vector3.new(0.6, 0.3, 0.7), Vector3.new(-0.7, 0.4, 0.5), Vector3.new(0.1, -0.5, 0.8), Vector3.new(-0.4, 0.1, -0.9) } do
					local at = CFrame.lookAt(c, c + d) * CFrame.new(0, 0, -0.27)
					q:lump(at, 0.3 - i * 0.03, 0.22, 0.1, Color3.fromRGB(132, 174, 110))
				end
				for k = 0, 3 do
					local a1, a2 = math.rad(-90 + k * 45), math.rad(-45 + k * 45)
					q:beam(
						c + Vector3.new(math.cos(a1) * 0.4, math.sin(a1) * 0.4, 0),
						c + Vector3.new(math.cos(a2) * 0.4, math.sin(a2) * 0.4, 0),
						0.05,
						0.05,
						BRASS
					)
				end
			end)
			-- the pointer leant against the left post
			r:piece(function(q: R)
				q:block(-3.22, 0, -0.05, -3.12, 0.06, 0.05, WALNUT)
				q:beam(Vector3.new(-3.17, 0.02, 0.0), Vector3.new(-3.34, 3.8, -0.5), 0.07, 0.07, WALNUT)
				q:beam(Vector3.new(-3.33, 3.6, -0.47), Vector3.new(-3.34, 3.8, -0.5), 0.09, 0.09, CHALK)
			end)
		end,
	},
	{
		id = "work_stage",
		name = "Little stage",
		cat = "work",
		price = 620,
		place = "floor",
		job = "musician",
		size = Vector3.new(8, 6, 6),
		c1 = "A8484E",
		c2 = "45454A",
		tags = { "work", "music" },
		workSpot = Vector3.new(0, 0.5, -0.5),
		workYaw = 0,
		build = function(r: R)
			-- A little stage (c1 the cloth, c2 the speakers): a boarded deck with a pleated
			-- skirt and two steps up at the front, a curtain hung behind between two posts with
			-- bunting and a string of lights along the top, a speaker each side, a microphone on
			-- a boom stand, a guitar on its stand, a stool and two wedges at the front.
			local cloth = r.c1
			local box = r.c2
			local TOP = 0.5
			-- the deck: a frame, boards on top, a rounded nosing and a pleated skirt
			r:block(-3.9, 0, -2.9, 3.9, TOP - 0.08, 1.9, shade(WALNUT, 0.6), "Wood")
			r:piece(function(q: R)
				for i = 0, 7 do
					local z = -2.9 + i * 0.6
					q:block(-3.95, TOP - 0.08, z + 0.01, 3.95, TOP, z + 0.59, if i % 2 == 0 then OAK else shade(OAK, 0.93), "Wood")
				end
				q:cyl(0, TOP - 0.06, 1.94, 7.9, 0.14, "x", shade(OAK, 0.8), "Wood")
				-- two steps up at the front
				q:block(-1.2, 0, 1.96, 1.2, 0.33, 2.5, OAK, "Wood")
				q:block(-1.2, 0, 2.5, 1.2, 0.17, 3.0, shade(OAK, 0.93), "Wood")
			end, true)
			r:piece(function(q: R)
				for i = 0, 15 do
					local x = -3.9 + i * 0.4875
					local deep = i % 2 == 0
					q:block(x, 0.03, 1.9, x + 0.4875, TOP - 0.1, if deep then 1.96 else 2.0, if deep then shade(cloth, 0.9) else cloth, "Fabric")
				end
				for _, s in { -1, 1 } do
					q:block(s * 3.9, 0.03, -2.9, s * 3.96, TOP - 0.1, 1.9, shade(cloth, 0.9), "Fabric")
				end
			end)
			-- the posts, the bar across and the curtain hung between them in folds
			r:piece(function(q: R)
				for _, s in { -1, 1 } do
					q:block(s * 3.75, TOP, -2.98, s * 3.95, 5.82, -2.78, shade(WALNUT, 0.8), "Wood")
				end
				q:block(-3.95, 5.62, -2.98, 3.95, 5.82, -2.78, shade(WALNUT, 0.8), "Wood")
			end, true)
			r:piece(function(q: R)
				for i = 0, 9 do
					local x = -3.75 + i * 0.75
					local deep = i % 2 == 0
					q:block(x, TOP, -2.98, x + 0.75, 5.62, if deep then -2.9 else -2.84, if deep then shade(cloth, 0.86) else cloth, "Fabric")
				end
				for i = 0, 6 do
					local x = -3.3 + i * 1.1
					q:block(x, 5.3, -2.78, x + 0.08, 5.62, -2.74, LEMON, "Fabric")
				end
			end)
			-- bunting along the bar
			r:piece(function(q: R)
				q:block(-3.75, 5.5, -2.74, 3.75, 5.54, -2.7, C.Paper, "Fabric")
				local flags = { LEMON, Color3.fromRGB(106, 150, 190), APPLE, Color3.fromRGB(132, 174, 110) }
				for i = 0, 8 do
					local x = -3.4 + i * 0.85
					q:tri(Vector3.new(x - 0.3, 5.5, -2.72), Vector3.new(x + 0.3, 5.5, -2.72), Vector3.new(x, 4.95, -2.72), 0.04, flags[i % 4 + 1], "Fabric")
				end
			end)
			-- a string of lights below the bunting, sagging between the posts
			local sag = {}
			for i = 0, 6 do
				local t = i / 6
				local x = -3.6 + t * 7.2
				table.insert(sag, Vector3.new(x, 4.75 - math.sin(t * math.pi) * 0.4, -2.68))
			end
			r:piece(function(q: R)
				q:block(-3.75, 4.7, -2.76, -3.6, 4.8, -2.66, INK)
				for i = 1, #sag - 1 do
					q:beam(sag[i], sag[i + 1], 0.04, 0.04, INK)
				end
			end)
			for i = 2, #sag - 1 do
				local p = sag[i]
				local bulb = r:noCollide(r:ball(p.X, p.Y - 0.16, p.Z, 0.22, C.Warm, "SmoothPlastic"))
				r:glow(bulb, if i == 4 then 14 else 0, 0.9)
			end
			-- the speakers: a cabinet with a big cone and a small one, corners capped
			for _, s in { -1, 1 } do
				local x = s * 3.2
				r:block(x - 0.55, TOP, -2.72, x + 0.55, TOP + 2.6, -1.62, box, "SmoothPlastic")
				r:piece(function(q: R)
					q:block(x - 0.45, TOP + 0.12, -1.62, x + 0.45, TOP + 2.48, -1.58, shade(box, 0.75))
					q:cyl(x, TOP + 0.9, -1.56, 0.06, 0.8, "z", Color3.fromRGB(40, 38, 44))
					q:cyl(x, TOP + 0.9, -1.52, 0.06, 0.44, "z", Color3.fromRGB(70, 68, 76))
					q:cyl(x, TOP + 0.9, -1.48, 0.06, 0.16, "z", Color3.fromRGB(110, 108, 116))
					q:cyl(x, TOP + 1.95, -1.56, 0.06, 0.36, "z", Color3.fromRGB(40, 38, 44))
					q:cyl(x, TOP + 1.95, -1.52, 0.06, 0.14, "z", Color3.fromRGB(110, 108, 116))
					for _, cy in { TOP + 0.06, TOP + 2.54 } do
						for _, cx in { -1, 1 } do
							q:block(x + cx * 0.55 - 0.09, cy - 0.09, -1.66, x + cx * 0.55 + 0.09, cy + 0.09, -1.56, ZINC)
						end
					end
				end)
			end
			-- the microphone on its boom stand, a lead running back to the speaker
			r:piece(function(q: R)
				local x, z = 0, 0.8
				q:block(x - 0.05, TOP, z - 0.05, x + 0.05, TOP + 0.12, z + 0.05, IRON, "Metal")
				for k = 0, 2 do
					local a = k * math.pi * 2 / 3 + 0.5
					q:beam(Vector3.new(x, TOP + 0.3, z), Vector3.new(x + math.cos(a) * 0.45, TOP + 0.02, z + math.sin(a) * 0.45), 0.06, 0.06, IRON, "Metal")
				end
				q:cyl(x, TOP + 2.0, z, 3.4, 0.09, "y", IRON, "Metal")
				q:cyl(x, TOP + 3.7, z, 0.12, 0.16, "y", ZINC, "Metal")
				q:beam(Vector3.new(x, TOP + 3.7, z), Vector3.new(x, TOP + 4.0, z - 0.6), 0.06, 0.06, IRON, "Metal")
				q:beam(Vector3.new(x, TOP + 4.0, z - 0.6), Vector3.new(x, TOP + 3.92, z - 0.86), 0.1, 0.1, IRON, "Metal")
				q:ball(x, TOP + 3.9, z - 0.92, 0.18, ZINC, "Metal")
			end)
			r:piece(function(q: R)
				local pts = { Vector3.new(0.2, TOP + 0.02, 0.8), Vector3.new(0.9, TOP + 0.02, 0.4), Vector3.new(1.6, TOP + 0.02, 0.0), Vector3.new(2.4, TOP + 0.02, -1.0), Vector3.new(2.66, TOP + 0.02, -1.5) }
				q:block(2.5, TOP, -1.56, 2.66, TOP + 0.06, -1.44, C.Black)
				for i = 1, #pts - 1 do
					q:beam(pts[i], pts[i + 1], 0.05, 0.05, C.Black)
				end
			end)
			-- the guitar on its stand, leant back a little
			r:piece(function(q: R)
				local g = CFrame.new(-2.55, TOP + 0.95, -1.9) * CFrame.Angles(math.rad(-12), 0, 0)
				local body = Color3.fromRGB(200, 140, 84)
				q:block(-2.95, TOP, -2.05, -2.15, TOP + 0.08, -1.75, IRON)
				for _, s in { -1, 1 } do
					q:beam(Vector3.new(-2.55 + s * 0.35, TOP + 0.04, -1.8), Vector3.new(-2.55 + s * 0.15, TOP + 1.3, -2.18), 0.06, 0.06, IRON)
				end
				q:lump(g * CFrame.new(0, -0.35, 0), 1.0, 0.9, 0.3, body)
				q:lump(g * CFrame.new(0, 0.3, 0), 0.76, 0.66, 0.3, body)
				q:boxAt(g * CFrame.new(0, -0.05, 0.16), 0.26, 0.26, 0.06, Color3.fromRGB(60, 44, 40))
				q:boxAt(g * CFrame.new(0, -0.52, 0.16), 0.4, 0.08, 0.06, Color3.fromRGB(90, 62, 44))
				q:boxAt(g * CFrame.new(0, 1.25, 0.02), 0.16, 1.4, 0.1, WALNUT)
				q:boxAt(g * CFrame.new(0, 2.05, 0.0), 0.24, 0.36, 0.08, Color3.fromRGB(90, 62, 44))
				for _, s in { -1, 1 } do
					q:boxAt(g * CFrame.new(s * 0.16, 2.05, 0.0), 0.08, 0.06, 0.06, ZINC)
				end
			end)
			-- a stool for between songs, and two wedges at the front facing the singer
			r:piece(function(q: R)
				local x, z = -1.5, -2.2
				q:cyl(x, TOP + 1.7, z, 0.12, 0.7, "y", Color3.fromRGB(70, 66, 74))
				q:block(x - 0.05, TOP + 0.4, z - 0.25, x + 0.05, TOP + 0.48, z + 0.25, IRON)
				for _, a in { 0, math.pi / 2, math.pi, math.pi * 1.5 } do
					q:beam(Vector3.new(x + math.cos(a) * 0.18, TOP + 1.64, z + math.sin(a) * 0.18), Vector3.new(x + math.cos(a) * 0.3, TOP, z + math.sin(a) * 0.3), 0.06, 0.06, IRON)
				end
			end)
			for _, x in { -1.7, 1.7 } do
				r:noCollide(r:wedge(CFrame.new(x, TOP + 0.3, 1.45), 1.0, 0.6, 0.66, box))
			end
		end,
	},
	{
		id = "work_builder",
		name = "Builder's bench",
		cat = "work",
		price = 600,
		place = "floor",
		job = "builder",
		size = Vector3.new(7, 4.4, 3.6),
		c1 = "C99A62",
		c2 = "45454A",
		tags = { "work" },
		workSpot = Vector3.new(0, 0, 2.6),
		workYaw = 180,
		build = function(r: R)
			r:legs(6.4, 2.4, 3, 0.4, 0.1, DARK, "Wood")
			r:block(-3.3, 3, -1.3, 3.3, 3.4, 1.3, r.c1, "WoodPlanks")
			r:block(-3, 0.8, -1, 3, 1, 1, DARK, "Wood")
			-- tools
			r:block(-2.4, 3.4, 0.2, -1, 3.55, 0.5, C.Metal, "Metal")
			r:block(-1, 3.4, 0.25, -0.4, 3.6, 0.45, Color3.fromRGB(199, 56, 63), "SmoothPlastic")
			r:block(0.6, 3.4, -0.6, 2.8, 3.6, -0.2, C.Cream, "Wood")
			r:block(0.6, 3.6, -0.6, 2.8, 3.8, -0.2, C.Cream, "Wood")
			-- a pegboard
			r:block(-3.3, 3.4, -1.5, 3.3, 4.4, -1.3, r.c2, "Metal")
			for i = 0, 4 do
				r:block(-2.6 + i * 1.2, 3.7, -1.3, -2.3 + i * 1.2, 4.2, -1.2, C.Metal, "Metal")
			end
		end,
	},
	{
		id = "work_post",
		name = "Post office desk",
		cat = "work",
		price = 420,
		place = "floor",
		job = "postie",
		size = Vector3.new(7, 5.6, 3),
		c1 = "C7383F",
		c2 = "F7F3EA",
		tags = { "work", "storage" },
		workSpot = Vector3.new(0.6, 0, -2.4),
		workYaw = 0,
		build = function(r: R)
			counter(r, 5, 2.2, 3.4, r.c1, r.c2)
			-- letter cubbies at the end
			r:block(2.6, 0, -1.1, 3.5, 5.6, 1.1, DARK, "Wood")
			for row = 0, 3 do
				for col = 0, 1 do
					r:block(
						3.48,
						1 + row * 1.1,
						-0.9 + col * 1,
						3.52,
						1.8 + row * 1.1,
						-0.2 + col * 1,
						C.Paper,
						"SmoothPlastic"
					)
				end
			end
			-- parcels
			r:block(-2, 3.4, -0.5, -0.8, 4.3, 0.5, Color3.fromRGB(196, 154, 98), "Fabric")
			r:block(-0.6, 3.4, -0.3, 0.2, 3.9, 0.4, Color3.fromRGB(196, 154, 98), "Fabric")
			r:block(0.6, 3.4, 0, 1.6, 3.45, 0.7, C.Paper, "SmoothPlastic")
		end,
	},
	{
		id = "work_icecream",
		name = "Ice cream cart",
		cat = "work",
		price = 400,
		place = "floor",
		job = "icecream",
		size = Vector3.new(5, 7.4, 3.6),
		c1 = "FFD1DC",
		c2 = "FFFFFF",
		tags = { "work" },
		workSpot = Vector3.new(0, 0, -2.6),
		workYaw = 0,
		build = function(r: R)
			r:block(-2.2, 1.1, -1.1, 2.2, 3.2, 1.1, r.c1, "SmoothPlastic")
			r:block(-2.3, 3.2, -1.2, 2.3, 3.4, 1.2, r.c2, "SmoothPlastic")
			wheel(r, -2.3, 0.9, 0.4, 1.8)
			wheel(r, 2.3, 0.9, 0.4, 1.8)
			r:block(-0.15, 0, -0.9, 0.15, 1.1, -0.6, C.Metal, "Metal")
			local tubs = { Color3.fromRGB(255, 240, 220), Color3.fromRGB(120, 80, 50), Color3.fromRGB(245, 158, 181) }
			for i = 0, 2 do
				r:cyl(-1.3 + i * 1.3, 3.55, 0, 0.3, 1, "y", tubs[i + 1], "SmoothPlastic")
			end
			-- umbrella
			r:cyl(1, 5, -0.6, 4, 0.15, "y", C.White, "Metal")
			for i = 0, 7 do
				local a1 = i / 8 * math.pi * 2
				local a2 = (i + 1) / 8 * math.pi * 2
				r:tri(
					Vector3.new(1 + math.cos(a1) * 1.6, 6.6, -0.6 + math.sin(a1) * 1.3),
					Vector3.new(1 + math.cos(a2) * 1.6, 6.6, -0.6 + math.sin(a2) * 1.3),
					Vector3.new(1, 7.3, -0.6),
					0.1,
					if i % 2 == 0 then r.c1 else r.c2,
					"Fabric"
				)
			end
		end,
	},
	{
		id = "work_library",
		name = "Library desk",
		cat = "work",
		price = 640,
		place = "floor",
		job = "librarian",
		size = Vector3.new(9, 7, 3),
		c1 = "6B4423",
		c2 = "F2E8D5",
		tags = { "work", "books" },
		workSpot = Vector3.new(-1.5, 0, -2.4),
		workYaw = 0,
		build = function(r: R)
			counter(r, 5, 2, 3.2, r.c1, r.c2)
			-- a bookcase at the end
			r:block(2.8, 0, -1.2, 4.4, 7, 1.2, r.c1, "Wood")
			local spines = { C.Red, C.Blue, C.Yellow, C.Leaf, Color3.fromRGB(156, 122, 214) }
			for row = 0, 3 do
				for i = 0, 4 do
					r:block(
						2.75,
						0.5 + row * 1.6,
						-1 + i * 0.42,
						2.85,
						1.7 + row * 1.6,
						-0.65 + i * 0.42,
						spines[(i + row) % 5 + 1],
						"SmoothPlastic"
					)
				end
			end
			-- book stack and a lamp
			for i = 0, 2 do
				r:block(
					-2 + i * 0.1,
					3.2 + i * 0.35,
					-0.4,
					-0.8 + i * 0.1,
					3.5 + i * 0.35,
					0.4,
					spines[i + 1],
					"SmoothPlastic"
				)
			end
			r:cyl(0.8, 3.3, 0, 0.2, 0.6, "y", C.Gold, "Metal")
			r:cyl(0.8, 3.9, 0, 1.2, 0.12, "y", C.Gold, "Metal")
			local shade = r:block(0.4, 4.4, -0.4, 1.2, 4.9, 0.4, Color3.fromRGB(78, 154, 68), "SmoothPlastic")
			r:glow(shade, 10, 0.8)
		end,
	},
}

return items
