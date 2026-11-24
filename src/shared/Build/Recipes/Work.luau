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
	q:boxAt(cf * CFrame.new(0, 0.05, 0), w - 0.06, 0.1, d - 0.06, shade(col, 0.8), "Wood")
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

-- A wheel for a cart, its axle along z: a tyre of eight sides, a hub and six spokes. One piece.
local function cartWheel(r: R, x: number, y: number, z: number, d: number, rim: Color3)
	r:piece(function(q: R)
		q:block(x - 0.08, y - 0.08, z - 0.16, x + 0.08, y + 0.08, z + 0.16, IRON)
		q:cyl(x, y, z, 0.16, d, "z", IRON, "SmoothPlastic")
		q:cyl(x, y, z, 0.2, d - 0.22, "z", rim, "SmoothPlastic")
		q:cyl(x, y, z, 0.26, 0.36, "z", rim, "SmoothPlastic")
		for k = 0, 2 do
			q:boxAt(CFrame.new(x, y, z) * CFrame.Angles(0, 0, k * math.pi / 3), 0.09, d - 0.3, 0.1, rim)
		end
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
					local mid = CFrame.new(s * (w / 2 - 0.04), (yBack + yFront) / 2 - deep / 2, (zBack + zFront) / 2)
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
							orange(q, at * CFrame.new(-0.46 + (k % 3) * 0.46, ((k + 1) % 2) * 0.05, -0.36 + (k // 3) * 0.36))
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
				q:block(-2.95, H + 0.42, -0.98, -1.75, H + 0.5, -0.32, shade(KRAFT, 0.8))
				for k = 0, 5 do
					local px = -2.65 + (k % 3) * 0.32
					local pz = -0.82 + (k // 3) * 0.36
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
				q:block(-3.3, 1.02, 1.5, -2.7, 1.1, 2.0, Color3.fromRGB(176, 154, 116))
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
		c1 = "8A5A2E",
		c2 = "F7F3EA",
		tags = { "work" },
		workSpot = Vector3.new(0, 0, -2.4),
		workYaw = 0,
		build = function(r: R)
			counter(r, 8, 2.4, 3.6, r.c1, r.c2)
			-- espresso machine
			r:block(-3.2, 3.6, -0.9, -1.4, 5.2, 0.4, C.Metal, "Metal")
			r:block(-3, 4.2, 0.4, -1.6, 4.4, 0.8, C.DarkMetal, "Metal")
			r:cyl(-2.3, 3.85, 0.6, 0.5, 0.45, "y", C.White, "SmoothPlastic")
			-- cups and a cake stand
			for i = 0, 2 do
				r:cyl(0.2 + i * 0.6, 3.85, 0.5, 0.5, 0.42, "y", C.White, "SmoothPlastic")
			end
			r:cyl(2.6, 3.7, 0, 0.2, 1.4, "y", C.White, "SmoothPlastic")
			r:cyl(2.6, 4.05, 0, 0.5, 1.1, "y", C.Pink, "SmoothPlastic")
			r:cyl(2.6, 4.45, 0, 0.3, 0.9, "y", C.Cream, "SmoothPlastic")
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
		c1 = "C7383F",
		c2 = "68686E",
		tags = { "work" },
		workSpot = Vector3.new(0, 0, 3.4),
		workYaw = 180,
		build = function(r: R)
			r:block(-3, 0, -2, 3, 1.2, 2, r.c2, "Concrete")
			r:block(-2.8, 1.2, -1.8, 2.8, 5, 1.8, r.c1, "Brick")
			r:block(-2.4, 5, -1.4, 2.4, 5.8, 1.4, r.c1, "Brick")
			r:block(-0.6, 5.8, -0.6, 0.6, 7, 0.6, r.c2, "Concrete")
			-- the glowing mouth
			local mouth = r:block(-1.3, 1.6, 1.75, 1.3, 3.4, 1.85, Color3.fromRGB(255, 150, 60), "Neon")
			r:fire(mouth)
			r:block(-1.6, 3.4, 1.8, 1.6, 3.7, 2, r.c2, "Concrete")
			-- loaves on a board
			r:block(-2.9, 1.2, 1.9, 2.9, 1.4, 2.0, WOOD, "Wood")
			for i = 0, 2 do
				r:ball(-1.8 + i * 1.8, 5.95, 0.9, 0.7, Color3.fromRGB(214, 160, 90), "SmoothPlastic")
			end
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
		c1 = "4FA9D9",
		c2 = "FFFFFF",
		tags = { "work", "plant" },
		workSpot = Vector3.new(0, 0, -2.6),
		workYaw = 0,
		build = function(r: R)
			r:block(-2.6, 1.2, -1.2, 2.6, 2.8, 1.2, r.c1, "Wood")
			r:block(-2.7, 2.8, -1.3, 2.7, 3, 1.3, r.c2, "Wood")
			wheel(r, -2.75, 1, 0, 2)
			wheel(r, 2.75, 1, 0, 2)
			r:block(-0.2, 0, 0.9, 0.2, 1.2, 1.1, DARK, "Wood")
			local blooms = { C.Pink, C.Red, C.Yellow, C.White, Color3.fromRGB(156, 122, 214), C.Pink }
			for i = 0, 5 do
				local x = -2 + (i % 3) * 2
				local z = if i < 3 then -0.5 else 0.5
				r:cyl(x, 3.4, z, 0.8, 0.9, "y", C.Metal, "Metal")
				for k = 0, 2 do
					r:ball(x - 0.3 + k * 0.3, 4.05 + (k % 2) * 0.2, z, 0.5, blooms[i + 1], "SmoothPlastic")
				end
			end
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
		c2 = "FFFFFF",
		tags = { "work", "art" },
		workSpot = Vector3.new(0, 0, -2.4),
		workYaw = 0,
		build = function(r: R)
			r:beam(Vector3.new(-1, 0, 0.6), Vector3.new(-0.15, 6.2, 0), 0.18, 0.18, r.c1, "Wood")
			r:beam(Vector3.new(1, 0, 0.6), Vector3.new(0.15, 6.2, 0), 0.18, 0.18, r.c1, "Wood")
			r:beam(Vector3.new(0, 0, -1), Vector3.new(0, 5.6, 0.2), 0.18, 0.18, r.c1, "Wood")
			r:block(-1.1, 2.4, 0.2, 1.1, 2.6, 0.6, r.c1, "Wood")
			-- the canvas faces the painter, who stands behind it
			r:block(-1.2, 2.6, 0.15, 1.2, 5.4, 0.3, r.c2, "Fabric")
			r:block(-0.8, 3.2, 0.08, 0.2, 4.2, 0.15, C.Blue, "SmoothPlastic")
			r:block(-0.2, 3.8, 0.08, 0.9, 4.9, 0.15, C.Yellow, "SmoothPlastic")
			r:ball(0.4, 3.3, 0.1, 0.5, C.Red, "SmoothPlastic")
			-- palette on a stool
			r:cyl(1.2, 1.2, -1, 0.2, 1.1, "y", DARK, "Wood")
			r:cyl(1.2, 0.55, -1, 1.1, 0.2, "y", DARK, "Wood")
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
		c1 = "FFFFFF",
		c2 = "E8667A",
		tags = { "work" },
		workSpot = Vector3.new(-1.8, 0, -2.6),
		workYaw = 0,
		build = function(r: R)
			counter(r, 4.4, 2, 3.2, r.c1, Color3.fromRGB(205, 225, 235))
			r:block(-1.5, 3.2, -0.6, -0.1, 4.2, 0.4, C.DarkMetal, "SmoothPlastic")
			-- a red cross on a stand
			r:block(-2.4, 0, -1.3, -2.2, 6, -1.1, C.Metal, "Metal")
			r:block(-2.9, 4.8, -1.25, -1.7, 5.2, -1.15, r.c2, "SmoothPlastic")
			r:block(-2.5, 4.4, -1.25, -2.1, 5.6, -1.15, r.c2, "SmoothPlastic")
			-- an exam bed to the side
			r:block(2.4, 0, -2.2, 4.4, 2.4, 2.2, C.Metal, "Metal")
			r:block(2.3, 2.4, -2.4, 4.5, 2.9, 2.4, Color3.fromRGB(150, 210, 220), "Fabric")
			r:block(2.5, 2.9, -2.3, 4.3, 3.2, -1.3, C.White, "Fabric")
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
			for _, x in { -3.6, 3.6 } do
				r:block(x - 0.2, 0, -0.9, x + 0.2, 7, -0.5, r.c2, "Wood")
				r:block(x - 0.2, 0, -1.3, x + 0.2, 0.3, -0.1, r.c2, "Wood")
			end
			r:block(-3.8, 2.6, -0.8, 3.8, 7, -0.6, r.c2, "Wood")
			r:block(-3.5, 2.9, -0.6, 3.5, 6.7, -0.55, r.c1, "SmoothPlastic")
			r:block(-3.5, 2.6, -0.65, 3.5, 2.8, -0.35, r.c2, "Wood")
			-- chalk marks
			r:block(-3, 5.6, -0.54, -0.8, 5.75, -0.52, C.White, "SmoothPlastic")
			r:block(-3, 5, -0.54, -1.6, 5.15, -0.52, C.White, "SmoothPlastic")
			r:block(0.4, 4.4, -0.54, 2.8, 4.55, -0.52, C.White, "SmoothPlastic")
			r:block(0.4, 3.8, -0.54, 2, 3.95, -0.52, C.White, "SmoothPlastic")
			-- a little desk in front
			r:block(-0.9, 0, 0.6, 0.9, 2.4, 1.4, r.c2, "Wood")
			r:block(-1.1, 2.4, 0.4, 1.1, 2.6, 1.5, r.c2, "Wood")
			r:ball(0.5, 2.85, 0.9, 0.5, C.Red, "SmoothPlastic")
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
		c1 = "9C2A2E",
		c2 = "45454A",
		tags = { "work", "music" },
		workSpot = Vector3.new(0, 0.5, -0.5),
		workYaw = 0,
		build = function(r: R)
			r:block(-4, 0, -3, 4, 0.5, 2, r.c1, "WoodPlanks")
			r:ramp(-1.2, 0, 2, 1.2, 0.5, 3, false, r.c1, "WoodPlanks")
			-- speakers
			for _, x in { -3.3, 3.3 } do
				r:block(x - 0.6, 0.5, -2.8, x + 0.6, 3.1, -1.6, r.c2, "SmoothPlastic")
				r:cyl(x, 2.2, -1.55, 0.1, 0.9, "z", C.Black, "SmoothPlastic")
				r:cyl(x, 1.1, -1.55, 0.1, 0.7, "z", C.Black, "SmoothPlastic")
			end
			-- mic stand
			r:cyl(0, 0.55, 0.8, 0.1, 0.8, "y", C.DarkMetal, "Metal")
			r:cyl(0, 2.3, 0.8, 3.5, 0.12, "y", C.DarkMetal, "Metal")
			r:ball(0, 4.15, 0.8, 0.35, C.Metal, "Metal")
			-- bunting
			for i = 0, 6 do
				local x = -3.6 + i * 1.2
				r:tri(
					Vector3.new(x - 0.4, 5.6, -2.9),
					Vector3.new(x + 0.4, 5.6, -2.9),
					Vector3.new(x, 4.9, -2.9),
					0.05,
					if i % 2 == 0 then C.Yellow else C.Blue,
					"Fabric"
				)
			end
			r:block(-3.9, 5.6, -2.95, 3.9, 5.7, -2.85, C.White, "Fabric")
			for _, x in { -3.9, 3.9 } do
				r:block(x - 0.1, 0.5, -3, x + 0.1, 5.8, -2.8, C.DarkMetal, "Metal")
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
