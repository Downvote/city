--!strict
-- The small things that make the island look lived in: street furniture for the sidewalks,
-- pocket plazas and gardens for the gaps between buildings, and props for the hills, the beach
-- and the sea. The user: "detail the entire map more". None of them is a tree: trees keep to the
-- parks, the hills and the beach (the user: "remove the trees near the road").
--
-- Each is a recipe drawn round its own middle, front facing local -Z. The user then asked for
-- more: "alot of places in the map are just simple shapes. try to make them more detailed and
-- recognizable for the things they are, the amount of detail should be similar to the default
-- house everywhere". So each is made of the parts the real thing has: a planter has feet, a lip,
-- soil, leaves spilling over and flowers on stems; a bench has slats, iron ends and arms.
--
-- The town has a budget of parts and of different pieces (the Town spec). What the town puts
-- down by the dozen (planters, flower beds, hedges, benches, lamps) is drawn as pieces
-- (Recipe.piece: a handful of shapes made into one mesh, once) and the same pieces are used
-- again in the pockets. A piece is drawn round the origin and then stood where it goes, so it
-- stays the same mesh however it is turned. What stands in only a few places is plain parts.

local Recipe = require(script.Parent.Parent.Build.Recipe)
local AmbientModels = require(script.Parent.AmbientModels)

type R = Recipe.Recipe

local DetailModels = {}
DetailModels.Models = {} :: { [string]: (R) -> () }
local M = DetailModels.Models

local function rgb(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end

local function shade(c: Color3, k: number): Color3
	return Color3.new(math.min(1, c.R * k), math.min(1, c.G * k), math.min(1, c.B * k))
end

local WHITE = rgb(250, 246, 236)
local STONE = rgb(226, 222, 214)
local ROCK = rgb(150, 152, 160)
local SOIL = rgb(118, 88, 64)
local FOLIAGE = rgb(108, 164, 92)
local FOLIAGE_DARK = rgb(76, 130, 84)
local FOLIAGE_LIGHT = rgb(142, 186, 106)
local MOSS = rgb(120, 168, 96)
local STEM = rgb(96, 142, 80)
local HEDGE = rgb(80, 140, 84)
local HEDGE_LIGHT = rgb(102, 158, 96)
local WOOD = rgb(196, 154, 108)
local WOOD_DARK = rgb(154, 107, 72)
local METAL = rgb(186, 192, 202)
local DARK = rgb(64, 70, 86)
local GLASS = rgb(150, 206, 240)
local WATER = rgb(84, 168, 236)
local LAWN = rgb(132, 190, 106)
local ASPHALT = rgb(104, 108, 120)
local PAVING = rgb(232, 226, 214)
local CLAY = rgb(190, 130, 104)
local BRONZE = rgb(110, 164, 144)
local GOLD = rgb(214, 180, 90)
local SAND = rgb(238, 206, 150)
local REED = rgb(96, 150, 70)
local CATTAIL = rgb(130, 96, 64)
local RED = rgb(214, 108, 98)
local BLUE = rgb(96, 140, 190)
local YELLOW = rgb(236, 198, 110)
local TEAL = rgb(88, 164, 156)
local PINK = rgb(240, 158, 176)
local BLOOMS = { rgb(240, 148, 164), rgb(240, 206, 118), rgb(250, 246, 236), rgb(184, 160, 222), rgb(236, 156, 110) }

local function bloom(i: number): Color3
	return BLOOMS[(i - 1) % #BLOOMS + 1]
end

-- Draws with `draw` round the origin and adds what it drew to `r`, stood at `cf`. A piece drawn
-- inside keeps its shapes, so its mesh, whichever way the group is turned.
local function group(r: R, cf: CFrame, draw: (R) -> ())
	local q = Recipe.new(r.c1, r.c2)
	draw(q)
	for _, p in q.prims do
		p.cf = cf * p.cf
		r:add(p)
	end
end

-- Draws shapes as parts of their own, for what is placed too seldom to be worth a piece. Like
-- a piece, they can't be bumped into unless `collide` says so.
local function parts(r: R, draw: (R) -> (), collide: boolean?)
	local q = Recipe.new(r.c1, r.c2)
	draw(q)
	for _, p in q.prims do
		if not collide then
			p.collide = false
		end
		r:add(p)
	end
end

-- A stem from `base` up to just under a flower's head at `top`.
local function stem(p: R, x: number, z: number, base: number, top: number)
	p:block(x - 0.05, base, z - 0.05, x + 0.05, top - 0.12, z + 0.05, STEM, "Grass")
end

-- A tuft of grass: two blades leaning apart.
local function tuft(p: R, x: number, y: number, z: number, h: number, turn: number, mat: string?)
	for k = 0, 1 do
		local a = turn + k * 2.6
		p:cone(0, 0, 0, h, 0.3, if k == 1 then FOLIAGE_LIGHT else FOLIAGE, mat or "Grass").cf = CFrame.new(
			x + math.cos(a) * 0.12,
			y + h / 2,
			z + math.sin(a) * 0.12
		) * CFrame.Angles(math.sin(a) * 0.3, 0, -math.cos(a) * 0.3)
	end
end

-- Planters -------------------------------------------------------------------------------------------

-- The street planter: a stone trough 6 long and 1.8 deep along x on four feet, a lip round its
-- top, soil sunk inside, mounds of leaves and flowers at two heights, the tall ones on stems.
-- Three pieces and the soil. (Leaves spilling over the lip were tried: the town stands a news box
-- with its box overhanging a planter's edge where it can, and they took that room.)
local TALL = { { -2.0, -0.2, 2.45 }, { -0.3, 0.22, 2.7 }, { 1.7, -0.1, 2.5 } }
local LOW = {
	{ -2.45, 0.25, 2.0 },
	{ -1.1, -0.25, 2.12 },
	{ 0.7, 0.2, 2.04 },
	{ 2.45, -0.1, 1.9 },
}
local MOUNDS = {
	{ -2.3, 0.1, 1.2, 1.0, 0.2 },
	{ -1.35, -0.1, 1.3, 1.1, -0.25 },
	{ -0.45, 0.1, 1.25, 1.0, 0.3 },
	{ 0.5, -0.1, 1.3, 1.15, 0.1 },
	{ 1.45, 0.1, 1.2, 1.0, -0.3 },
	{ 2.35, -0.08, 1.15, 0.95, 0.25 },
}

local function plantsInTrough(q: R)
	q:piece(function(p: R)
		for _, s in TALL do
			stem(p, s[1], s[2], 1.2, s[3])
		end
		local greens = { FOLIAGE, FOLIAGE_DARK, FOLIAGE_LIGHT }
		for k, m in MOUNDS do
			p:lump(
				CFrame.new(m[1], 1.52, m[2]) * CFrame.Angles(0, m[5], 0),
				m[3],
				m[4],
				1.0,
				greens[k % 3 + 1],
				"Grass"
			)
		end
	end)
	q:piece(function(p: R)
		for i, s in TALL do
			p:ball(s[1], s[3], s[2], 0.6, bloom(i), "Fabric")
		end
		for i, s in LOW do
			p:ball(s[1], s[3], s[2], 0.42, bloom(i + 3), "Fabric")
		end
		-- the yellow eye of the tallest
		p:box(TALL[2][1], TALL[2][3] + 0.24, TALL[2][2], 0.18, 0.18, 0.18, YELLOW, "Fabric")
	end)
end

local function planter(r: R, cf: CFrame)
	group(r, cf, function(q: R)
		q:piece(function(p: R)
			local foot, lip = shade(STONE, 0.84), shade(STONE, 1.04)
			for _, sx in { -1, 1 } do
				p:block(sx * 2.45 - 0.35, 0, -0.66, sx * 2.45 + 0.35, 0.22, 0.66, foot, "Concrete")
			end
			p:block(-2.86, 0.2, -0.76, 2.86, 1.02, 0.76, STONE, "Concrete")
			p:block(-3, 0.98, -0.9, 3, 1.34, -0.66, lip, "Concrete")
			p:block(-3, 0.98, 0.66, 3, 1.34, 0.9, lip, "Concrete")
			p:block(-3, 0.98, -0.66, -2.74, 1.34, 0.66, lip, "Concrete")
			p:block(2.74, 0.98, -0.66, 3, 1.34, 0.66, lip, "Concrete")
		end, true)
		q:block(-2.76, 1.0, -0.68, 2.76, 1.24, 0.68, SOIL, "Ground")
		plantsInTrough(q)
	end)
end

-- A clipped shrub in a clay pot: a saucer, the pot with a rolled rim, soil, a short trunk, and
-- the two clumps of leaves that lean with the wind (parts named Leaf).
local function shrub(r: R, x: number, y: number, z: number)
	group(r, CFrame.new(x, y, z), function(q: R)
		q:piece(function(p: R)
			p:cyl(0, 0.07, 0, 0.14, 2.0, "y", shade(CLAY, 0.86), "SmoothPlastic")
			p:cyl(0, 0.55, 0, 0.82, 1.5, "y", shade(CLAY, 0.94), "SmoothPlastic")
			p:cyl(0, 1.2, 0, 0.6, 1.8, "y", CLAY, "SmoothPlastic")
			p:cyl(0, 1.62, 0, 0.3, 2.1, "y", shade(CLAY, 1.06), "SmoothPlastic")
			p:cyl(0, 1.82, 0, 0.12, 1.84, "y", SOIL, "SmoothPlastic")
			p:block(-0.12, 1.7, -0.12, 0.12, 2.4, 0.12, WOOD_DARK, "SmoothPlastic")
		end, true)
		q:ball(0, 3.2, 0, 2.7, FOLIAGE, "SmoothPlastic").name = "Leaf"
		q:ball(0.55, 3.95, -0.35, 1.6, shade(FOLIAGE, 1.15), "SmoothPlastic").name = "Leaf"
	end)
end

-- The clipped hedge, 16 long, 1.8 deep and 2.2 tall along x: a body, soft lumps along its top so
-- it reads as leaves and not as a box, and a few flowers coming through. One piece.
local function hedgeRow(r: R, cf: CFrame)
	group(r, cf, function(q: R)
		q:piece(function(p: R)
			p:block(-7.84, 0, -0.8, 7.84, 1.5, 0.8, HEDGE, "Grass")
			for k = 0, 5 do
				p:lump(
					CFrame.new(-6.5 + k * 2.6, 1.42 + (k % 2) * 0.06, 0),
					3.0,
					1.5,
					1.84,
					if k % 2 == 0 then HEDGE_LIGHT else HEDGE,
					"Grass"
				)
			end
			for k, x in { -5.2, 0.4, 5.3 } do
				p:ball(x, 2.22, (k % 2 - 0.5) * 0.5, 0.5, bloom(k), "Grass")
			end
		end, true)
	end)
end

-- A patch of wildflowers about 4 across: stems of different heights with their heads, and tufts
-- of grass. Two pieces, also used in the pockets' beds and lawns.
local WILD = {}
for k = 0, 5 do
	local a = k * 2.4
	local d = 0.8 + k * 0.6
	table.insert(WILD, { math.cos(a) * d, math.sin(a) * d, 0.6 + (k * 3 % 4) * 0.22 })
end

local function wildflowers(r: R, cf: CFrame)
	group(r, cf, function(q: R)
		q:piece(function(p: R)
			for _, s in WILD do
				stem(p, s[1], s[2], 0, s[3])
			end
			for k = 0, 1 do
				local s = WILD[k * 3 + 1]
				p:lump(CFrame.new(s[1] + 0.2, 0.2, s[2]) * CFrame.Angles(0, k, 0), 1.0, 0.6, 0.8, FOLIAGE_DARK, "Grass")
			end
			for k = 0, 1 do
				local a = 1.2 + k * 2.4
				local d = 1.6 + k * 0.9
				tuft(p, math.cos(a) * d, 0, math.sin(a) * d, 0.8 + k * 0.2, a)
			end
		end)
		q:piece(function(p: R)
			for k, s in ipairs(WILD) do
				p:ball(s[1], s[3], s[2], 0.6, bloom(k), "Fabric")
			end
			p:box(WILD[1][1], WILD[1][3] + 0.2, WILD[1][2], 0.14, 0.14, 0.14, YELLOW, "Fabric")
		end)
	end)
end

-- A bed edged in timber, `w` by `d` round the origin, with soil sunk inside it.
local function edgedBed(r: R, cf: CFrame, w: number, d: number)
	group(r, cf, function(q: R)
		local hx, hz, t = w / 2, d / 2, 0.18
		parts(q, function(p: R)
			p:block(-hx, 0, -hz, hx, 0.42, -hz + t, WOOD_DARK, "Wood")
			p:block(-hx, 0, hz - t, hx, 0.42, hz, WOOD_DARK, "Wood")
			p:block(-hx, 0, -hz + t, -hx + t, 0.42, hz - t, WOOD_DARK, "Wood")
			p:block(hx - t, 0, -hz + t, hx, 0.42, hz - t, WOOD_DARK, "Wood")
		end, true)
		q:block(-hx + t - 0.02, 0, -hz + t - 0.02, hx - t + 0.02, 0.3, hz - t + 0.02, SOIL, "Ground")
	end)
end

-- A bush on the ground: three lumps of leaves.
local function bush(r: R, x: number, y: number, z: number, s: number, turn: number)
	parts(r, function(p: R)
		local f = CFrame.new(x, y, z) * CFrame.Angles(0, turn, 0)
		p:lump(f * CFrame.new(0, 1.4 * s, 0), 3.6 * s, 2.8 * s, 3.3 * s, FOLIAGE, "Grass")
		p:lump(f * CFrame.new(0.9 * s, 2.1 * s, -0.5 * s), 2.2 * s, 1.8 * s, 2 * s, FOLIAGE_LIGHT, "Grass")
		p:lump(f * CFrame.new(-1 * s, 1 * s, 0.8 * s), 2 * s, 1.5 * s, 1.8 * s, FOLIAGE_DARK, "Grass")
	end, true)
end

-- Seats, lamps and bins ----------------------------------------------------------------------------

-- A park bench 4 long, sat on from local -Z: cast iron ends with arms and a bar between them,
-- slats on the seat and up the back. Two pieces.
local BACK_LEAN = math.rad(6)
local function bench(r: R, x: number, z: number, yaw: number, y: number?)
	group(r, CFrame.new(x, y or 0, z) * CFrame.Angles(0, math.rad(yaw), 0), function(q: R)
		q:piece(function(p: R)
			for _, sx in { -1, 1 } do
				local ex = sx * 1.75
				p:block(ex - 0.08, 0, -0.62, ex + 0.08, 1.82, -0.46, DARK, "Metal")
				p:beam(Vector3.new(ex, 0, 0.42), Vector3.new(ex, 2.7, 0.72), 0.16, 0.16, DARK, "Metal")
				p:block(ex - 0.1, 1.82, -0.7, ex + 0.1, 1.94, 0.5, DARK, "Metal")
			end
			p:block(-1.83, 0.98, -0.1, 1.83, 1.1, 0.06, DARK, "Metal")
		end, true)
		q:piece(function(p: R)
			for k = 0, 2 do
				local z0 = -0.6 + k * 0.4
				p:block(-2, 1.1, z0, 2, 1.22, z0 + 0.34, WOOD, "Wood")
			end
			for k = 0, 1 do
				local h = 1.7 + k * 0.55
				local zl = 0.42 + (h / 2.7) * 0.3 - 0.13
				p:boxAt(CFrame.new(0, h, zl) * CFrame.Angles(BACK_LEAN, 0, 0), 4, 0.38, 0.08, WOOD, "Wood")
			end
		end)
	end)
end

-- A lamp on a post, lit at night: a foot, a base, the post, and a lantern of four bars under a
-- cap. The glass is its own part, for the light.
local function lamp(r: R, x: number, y: number, z: number)
	group(r, CFrame.new(x, y, z), function(q: R)
		q:piece(function(p: R)
			p:block(-0.5, 0, -0.5, 0.5, 0.3, 0.5, DARK, "Metal")
			p:cyl(0, 0.75, 0, 0.9, 0.6, "y", DARK, "Metal")
			p:cyl(0, 2.9, 0, 3.4, 0.32, "y", DARK, "Metal")
			p:cyl(0, 4.65, 0, 0.18, 0.6, "y", DARK, "Metal")
			for _, s in { { -1, -1 }, { 1, -1 }, { -1, 1 }, { 1, 1 } } do
				p:block(
					s[1] * 0.42 - 0.05,
					4.74,
					s[2] * 0.42 - 0.05,
					s[1] * 0.42 + 0.05,
					5.9,
					s[2] * 0.42 + 0.05,
					DARK,
					"Metal"
				)
			end
			p:cone(0, 6.15, 0, 0.5, 1.25, DARK, "Metal")
			p:ball(0, 6.48, 0, 0.26, DARK, "Metal")
		end, true)
		q:glow(q:block(-0.36, 4.74, -0.36, 0.36, 5.9, 0.36, rgb(255, 236, 190), "SmoothPlastic"), 14, 1)
	end)
end

-- A litter bin: a round bin on a foot, a band, a domed lid, and the slot.
local function bin(r: R, x: number, y: number, z: number)
	parts(r, function(p: R)
		local green = rgb(84, 120, 104)
		p:block(x - 0.45, y, z - 0.45, x + 0.45, y + 0.16, z + 0.45, DARK, "Metal")
		p:cyl(x, y + 1.05, z, 1.8, 1.5, "y", green, "Metal")
		p:cyl(x, y + 1.5, z, 0.22, 1.56, "y", shade(green, 0.84), "Metal")
		p:cyl(x, y + 2.02, z, 0.14, 1.62, "y", DARK, "Metal")
		p:cone(x, y + 2.3, z, 0.42, 1.5, green, "Metal")
		p:block(x - 0.42, y + 1.62, z - 0.8, x + 0.42, y + 1.88, z - 0.7, rgb(40, 42, 50), "Metal")
	end, true)
end

-- A round table under a parasol, with two bistro chairs.
local function cafe(r: R, x: number, y: number, z: number, top: Color3)
	parts(r, function(p: R)
		local function block(
			x1: number,
			y1: number,
			z1: number,
			x2: number,
			y2: number,
			z2: number,
			c: Color3,
			m: string
		)
			p:block(x + x1, y + y1, z + z1, x + x2, y + y2, z + z2, c, m)
		end
		block(-0.6, 0, -0.6, 0.6, 0.1, 0.6, DARK, "Metal")
		p:cyl(x, y + 1.3, z, 2.4, 0.24, "y", DARK, "Metal")
		p:cyl(x, y + 5.2, z, 4.9, 0.16, "y", WHITE, "Metal")
		p:cyl(x, y + 2.65, z, 0.2, 3.4, "y", WOOD, "Wood")
		for _, sx in { -1, 1 } do
			local cx = sx * 2.7
			for _, l in { { -1, -1 }, { 1, -1 }, { -1, 1 }, { 1, 1 } } do
				block(
					cx + l[1] * 0.42 - 0.05,
					0,
					l[2] * 0.42 - 0.05,
					cx + l[1] * 0.42 + 0.05,
					1.7,
					l[2] * 0.42 + 0.05,
					DARK,
					"Metal"
				)
			end
			p:cyl(x + cx, y + 1.79, z, 0.18, 1.3, "y", WOOD, "Wood")
			block(cx + sx * 0.38, 1.88, -0.42, cx + sx * 0.5, 2.98, 0.42, WOOD, "Wood")
		end
		p:cone(x, y + 7.7, z, 1.6, 7.4, top, "Fabric")
		p:cyl(x, y + 6.72, z, 0.36, 7.3, "y", WHITE, "Fabric")
	end, true)
end

-- Street furniture ----------------------------------------------------------------------------------

M.planterBox = function(r: R)
	planter(r, CFrame.identity)
end

-- (the same planter turned about, so its flowers run the other way)
M.planterBox2 = function(r: R)
	planter(r, CFrame.Angles(0, math.pi, 0))
end

M.shrubPot = function(r: R)
	shrub(r, 0, 0, 0)
end

-- A rack of three steel hoops with two town bikes standing in it, one each way: tyres and
-- wheels, the frame, the fork, bars and a saddle. Each bike is a piece of its own (the same one
-- turned about), so that no piece's box takes in the rack between them.
local function bike(r: R, cf: CFrame)
	group(r, cf, function(q: R)
		q:piece(function(p: R)
			local col = rgb(88, 150, 170)
			for _, z in { 1.3, -1.5 } do
				-- a tyre of eight short lengths round two crossed spokes, so the wheel is open
				local ring = {}
				for k = 0, 7 do
					local a = (k + 0.5) * math.pi / 4
					ring[k + 1] = Vector3.new(0, 1 + 0.9 * math.cos(a), z + 0.9 * math.sin(a))
				end
				for k = 1, 8 do
					local a, b = ring[k], ring[k % 8 + 1]
					local along = (b - a).Unit * 0.05
					p:beam(a - along, b + along, 0.14, 0.16, rgb(46, 48, 58), "Metal")
				end
				p:beam(Vector3.new(0, 0.14, z), Vector3.new(0, 1.86, z), 0.03, 0.03, METAL, "Metal")
				p:beam(Vector3.new(0, 1, z - 0.86), Vector3.new(0, 1, z + 0.86), 0.03, 0.03, METAL, "Metal")
			end
			local bb, seat, head = Vector3.new(0, 1.0, 0.1), Vector3.new(0, 2.3, 0.55), Vector3.new(0, 2.25, -1.0)
			p:beam(bb, seat, 0.12, 0.12, col, "Metal")
			p:beam(bb, head, 0.14, 0.14, col, "Metal")
			p:beam(seat, head, 0.12, 0.12, col, "Metal")
			p:beam(bb, Vector3.new(0, 1, 1.3), 0.08, 0.08, col, "Metal")
			p:beam(seat, Vector3.new(0, 1, 1.3), 0.08, 0.08, col, "Metal")
			p:beam(Vector3.new(0, 2.65, -1.05), Vector3.new(0, 1, -1.5), 0.1, 0.1, col, "Metal")
			p:block(-0.07, 2.64, -1.65, 0.07, 2.76, -0.45, DARK, "Metal")
			p:block(-0.14, 2.35, 0.4, 0.14, 2.5, 0.85, rgb(90, 66, 52), "Metal")
		end)
	end)
end

M.bikeRack = function(r: R)
	parts(r, function(p: R)
		p:block(-2.2, 0, -0.1, 2.2, 0.08, 0.1, DARK, "Metal")
		for _, x in { -2.2, 0, 2.2 } do
			for _, sz in { -1, 1 } do
				p:block(x - 0.08, 0, sz * 0.75 - 0.08, x + 0.08, 1.45, sz * 0.75 + 0.08, METAL, "Metal")
			end
			p:cyl(x, 1.45, 0, 1.66, 0.16, "z", METAL, "Metal")
		end
	end, true)
	bike(r, CFrame.new(-1.1, 0, -0.1))
	bike(r, CFrame.new(1.1, 0, -0.1) * CFrame.Angles(0, math.pi, 0))
end

-- A post box on a post: a foot, the post and its collar, a box with a round top and a rim, the
-- slot under its hood, and a plate saying when it's collected.
M.mailbox = function(r: R)
	r:piece(function(p: R)
		p:block(-0.45, 0, -0.45, 0.45, 0.12, 0.45, DARK, "Metal")
		p:block(-0.22, 0.12, -0.22, 0.22, 2.4, 0.22, DARK, "Metal")
		p:block(-0.3, 2.1, -0.3, 0.3, 2.4, 0.3, shade(DARK, 1.2), "Metal")
		p:block(-0.9, 2.4, -0.7, 0.9, 3.9, 0.7, BLUE, "Metal")
		p:cyl(0, 3.9, 0, 1.8, 1.4, "x", BLUE, "Metal")
		p:block(-0.92, 3.86, -0.72, 0.92, 3.94, 0.72, shade(BLUE, 0.8), "Metal")
		p:block(-0.66, 3.5, -0.77, 0.66, 3.6, -0.7, shade(BLUE, 0.82), "Metal")
		p:block(-0.55, 3.34, -0.74, 0.55, 3.46, -0.7, rgb(36, 40, 50), "Metal")
		p:block(-0.4, 2.7, -0.74, 0.4, 3.1, -0.7, WHITE, "Metal")
	end, true)
end

-- Traffic lights: a pole on a foot on the corner with an arm out over the road (local -Z) on a
-- brace, and the head with a backboard and a hood over each lamp. The lamps are three
-- parts named Red, Amber and Green, which the client switches.
M.trafficLight = function(r: R)
	r:piece(function(p: R)
		p:block(-0.34, 0, -0.34, 0.34, 0.16, 0.34, DARK, "Metal")
		p:cyl(0, 5.6, 0, 11.2, 0.5, "y", DARK, "Metal")
	end, true)
	r:piece(function(p: R)
		p:block(-0.2, 10.5, -7, 0.2, 10.9, -0.24, DARK, "Metal")
		p:beam(Vector3.new(0, 9.3, -0.25), Vector3.new(0, 10.5, -2.8), 0.16, 0.16, DARK, "Metal")
		p:block(-0.7, 8.3, -7.6, 0.7, 11.3, -6.6, rgb(50, 54, 66), "Metal")
		p:block(-1.05, 8.0, -6.6, 1.05, 11.6, -6.48, rgb(42, 46, 56), "Metal")
		for _, y in { 10.6, 9.8, 9 } do
			p:block(-0.48, y + 0.36, -8.1, 0.48, y + 0.46, -7.6, rgb(50, 54, 66), "Metal")
		end
	end)
	-- (the client changes the lights: red, green, amber, turn about with the other road's)
	r:ball(0, 10.6, -7.66, 0.7, rgb(240, 80, 70), "SmoothPlastic").name = "Red"
	r:ball(0, 9.8, -7.66, 0.7, rgb(250, 200, 80), "SmoothPlastic").name = "Amber"
	r:ball(0, 9, -7.66, 0.7, rgb(90, 220, 120), "SmoothPlastic").name = "Green"
end

-- A kiosk selling papers and snacks: a hatch with its frame and a counter, papers and jars of
-- sweets on it, magazines in a rack at the side, a striped awning with a scalloped edge, the
-- roof's trim and a sign on top.
local KIOSK_WALL = rgb(240, 220, 170)
M.kiosk = function(r: R)
	r:block(-4, 0, -3, 4, 0.3, 3, STONE, "Concrete")
	r:block(-3.6, 0.3, -1.6, 3.6, 7, 2.6, KIOSK_WALL, "Plaster")
	r:glow(r:block(-3, 3, -1.75, 3, 5.6, -1.6, rgb(120, 90, 70), "SmoothPlastic"), 0).attrs =
		{ NightColor = rgb(255, 224, 156) }
	parts(r, function(p: R)
		p:block(-3.3, 2.6, -2.6, 3.3, 3, -1.6, WOOD, "Wood")
		p:block(-3.3, 2.2, -1.9, 3.3, 2.6, -1.6, WOOD_DARK, "Wood")
		p:block(-3.25, 2.95, -1.82, -3, 5.85, -1.6, WOOD_DARK, "Wood")
		p:block(3, 2.95, -1.82, 3.25, 5.85, -1.6, WOOD_DARK, "Wood")
		p:block(-3.25, 5.6, -1.82, 3.25, 5.85, -1.6, WOOD_DARK, "Wood")
		p:block(-3.9, 7, -1.95, 3.9, 7.55, 2.9, rgb(176, 92, 84), "Wood")
		p:block(-4, 7.55, -2.05, 4, 7.7, 3, WHITE, "Wood")
		p:block(-2.5, 7.7, -1.62, 2.5, 9, -1.36, WOOD_DARK, "Wood")
		p:block(-2.3, 7.85, -1.68, 2.3, 8.85, -1.6, WHITE, "SmoothPlastic")
		-- papers and jars on the counter
		for k, c in { rgb(236, 232, 222), rgb(214, 206, 190), rgb(232, 224, 200) } do
			p:block(-2.9 + (k - 1) * 0.85, 3, -2.5, -2.2 + (k - 1) * 0.85, 3.1 + k * 0.05, -1.9, c, "SmoothPlastic")
		end
		for k, col in { PINK, YELLOW } do
			p:cyl(0.9 + k * 0.7, 3.3, -2.2, 0.6, 0.5, "y", col, "SmoothPlastic")
			p:cyl(0.9 + k * 0.7, 3.65, -2.2, 0.1, 0.38, "y", WHITE, "SmoothPlastic")
		end
		-- the rack on the left side: two shelves of magazines leaning back
		p:block(-3.95, 1, -1.2, -3.6, 1.12, 2.2, WOOD_DARK, "Wood")
		local covers = { RED, BLUE, YELLOW, TEAL, PINK, rgb(184, 160, 222) }
		for row = 0, 1 do
			for k = 0, 2 do
				p:boxAt(
					CFrame.new(-3.72, 1.7 + row * 1.3, -0.6 + k * 1.05) * CFrame.Angles(0, 0, math.rad(-12)),
					0.06,
					1.0,
					0.8,
					covers[(row * 3 + k) % #covers + 1],
					"SmoothPlastic"
				)
			end
		end
	end, true)
	-- the awning: stripes, and a scalloped edge hanging from them
	parts(r, function(p: R)
		for k = 0, 3 do
			p:boxAt(
				CFrame.new(-2.85 + k * 1.9, 6.3, -2.9) * CFrame.Angles(math.rad(20), 0, 0),
				1.9,
				0.2,
				2.9,
				if k % 2 == 0 then RED else WHITE,
				"Fabric"
			)
		end
		for k = 0, 3 do
			local x = -2.85 + k * 1.9
			local c = if k % 2 == 0 then RED else WHITE
			p:block(x - 0.95, 5.5, -4.32, x + 0.95, 5.78, -4.26, c, "Fabric")
			for _, dx in { -0.475, 0.475 } do
				p:cyl(x + dx, 5.4, -4.29, 0.06, 0.76, "z", c, "Fabric")
			end
		end
	end)
end

M.cafeLite = function(r: R)
	cafe(r, 0, 0, 0, RED)
end

M.cafeLite2 = function(r: R)
	cafe(r, 0, 0, 0, TEAL)
end

-- A food truck with its hatch open (the hatch faces local -Z): the box body with a stripe, the
-- cab with its windscreen, lights and mirrors, wheels with hubs, an awning propped over the
-- hatch, a counter on brackets with a menu board, jars and cups, and a chimney for the stove.
local function truck(r: R, x: number, z: number, body: Color3)
	group(r, CFrame.new(x, 0, z), function(q: R)
		q:block(-6, 1.2, -3, 4, 8, 3, body, "SmoothPlastic")
		q:block(4, 1.2, -2.8, 7.6, 5.4, 2.8, WHITE, "SmoothPlastic")
		q:block(5.4, 3.4, -2.86, 7.66, 5.2, 2.86, GLASS, "Glass")
		q:block(-4.6, 4, -3.1, 2.4, 6.6, -3, rgb(84, 66, 62), "SmoothPlastic")
		parts(q, function(p: R)
			p:block(-6.04, 2.6, -3.04, 4, 3.2, 3.04, WHITE, "SmoothPlastic")
			p:block(7.6, 1.0, -2.9, 7.9, 1.7, 2.9, DARK, "SmoothPlastic")
			for _, sz in { -1, 1 } do
				p:block(7.6, 2.3, sz * 2.1 - 0.4, 7.7, 2.8, sz * 2.1 + 0.4, rgb(255, 236, 190), "SmoothPlastic")
				p:block(5.6, 4.5, sz * 3.2 - 0.25, 5.8, 4.9, sz * 3.2 + 0.25, DARK, "SmoothPlastic")
			end
			p:cyl(-2, 8.5, 0, 1, 1.4, "y", METAL, "SmoothPlastic")
			p:cyl(-2, 9.1, 0, 0.2, 1.8, "y", DARK, "SmoothPlastic")
			-- the counter on its brackets, a menu board, jars and cups
			p:block(-4.8, 3.6, -3.9, 2.6, 4, -3, WOOD, "Wood")
			for _, bx in { -4.2, 2 } do
				p:beam(Vector3.new(bx, 2.9, -3.02), Vector3.new(bx, 3.6, -3.7), 0.14, 0.14, WOOD_DARK, "Wood")
			end
			p:block(-1.2, 8.1, -3.12, 1.2, 9.4, -3, WOOD_DARK, "Wood")
			p:block(-1.05, 8.25, -3.16, 1.05, 9.25, -3.12, rgb(60, 72, 70), "Wood")
			p:cyl(-3.6, 4.4, -3.5, 0.8, 0.5, "y", rgb(240, 200, 160), "Wood")
			p:cyl(-2.9, 4.35, -3.5, 0.7, 0.5, "y", rgb(220, 160, 170), "Wood")
			p:cyl(1.6, 4.35, -3.5, 0.7, 0.4, "y", WHITE, "Wood")
			-- the awning, its scalloped edge and the props under it
			p:boxAt(CFrame.new(-1.1, 7.3, -4.3) * CFrame.Angles(math.rad(-14), 0, 0), 7.4, 0.2, 2.8, WHITE, "Fabric")
			for k = 0, 6 do
				local wx = -4.4 + k * 1.1
				p:block(wx - 0.55, 6.55, -5.72, wx + 0.55, 6.95, -5.64, if k % 2 == 0 then body else WHITE, "Fabric")
			end
			for _, px in { -4.6, 2.4 } do
				p:beam(Vector3.new(px, 4.0, -3.4), Vector3.new(px, 6.6, -5.5), 0.1, 0.1, DARK, "Metal")
			end
		end)
		for _, wx in { -3.6, 5 } do
			q:cyl(wx, 1.1, 0, 6.4, 2.2, "z", DARK, "SmoothPlastic")
			q:cyl(wx, 1.1, 0, 6.5, 1.1, "z", METAL, "Metal")
		end
	end)
end

M.foodTruck = function(r: R)
	truck(r, 0, 0, PINK)
end

M.foodTruck2 = function(r: R)
	truck(r, 0, 0, TEAL)
end

-- A statue on a stepped plinth: two steps, the die with a gold plaque and a cornice, and on top a
-- bronze figure in a long coat and a hat, a book under one arm and the other raised.
local function statue(r: R, x: number, y: number, z: number)
	group(r, CFrame.new(x, y, z), function(q: R)
		parts(q, function(p: R)
			p:block(-3, 0, -3, 3, 0.6, 3, STONE, "Concrete")
			p:block(-2.4, 0.6, -2.4, 2.4, 1.0, 2.4, shade(STONE, 0.97), "Concrete")
			p:block(-2, 1.0, -2, 2, 3.1, 2, shade(STONE, 0.94), "Concrete")
			p:block(-2.3, 3.1, -2.3, 2.3, 3.7, 2.3, STONE, "Concrete")
		end, true)
		parts(q, function(p: R)
			p:block(-1.1, 3.7, -1.1, 1.1, 3.9, 1.1, shade(BRONZE, 0.8), "Metal")
			for _, sx in { -1, 1 } do
				p:block(sx * 0.32 - 0.25, 3.9, -0.3, sx * 0.32 + 0.25, 5.7, 0.3, shade(BRONZE, 0.9), "Metal")
			end
			p:cone(0, 5.65, 0, 1.6, 1.7, BRONZE, "Metal")
			p:block(-0.7, 5.6, -0.45, 0.7, 7.4, 0.45, BRONZE, "Metal")
			p:cyl(0, 7.3, 0, 1.9, 0.8, "x", BRONZE, "Metal")
			p:ball(0, 8.15, 0, 1.0, shade(BRONZE, 1.08), "Metal")
			p:cyl(0, 8.55, 0, 0.12, 1.3, "y", shade(BRONZE, 0.85), "Metal")
			p:cyl(0, 8.85, 0, 0.5, 0.82, "y", shade(BRONZE, 0.85), "Metal")
			p:boxAt(
				CFrame.new(1.05, 8.0, -0.35) * CFrame.Angles(math.rad(25), 0, math.rad(-22)),
				0.4,
				1.7,
				0.4,
				BRONZE,
				"Metal"
			)
			p:block(-1.12, 5.9, -0.2, -0.72, 7.3, 0.2, BRONZE, "Metal")
			p:block(-1.16, 5.6, -0.55, -0.84, 6.4, 0.12, shade(BRONZE, 0.75), "Metal")
			p:block(-1.2, 1.7, -2.06, 1.2, 2.6, -2, GOLD, "Metal")
		end, true)
	end)
end

M.statue = function(r: R)
	statue(r, 0, 0, 0)
end

-- A small round fountain: an eight sided basin with a coping round its rim and water in it, and
-- in the middle a pedestal holding two bowls, one over the other, the jet spraying from the top.
local function fountain(r: R, x: number, y: number, z: number)
	group(r, CFrame.new(x, y, z), function(q: R)
		parts(q, function(p: R)
			p:cyl(0, 0.45, 0, 0.9, 10.8, "y", shade(STONE, 0.95), "Concrete")
			local side = 2 * 5.6 * math.tan(math.pi / 8)
			for k = 0, 7 do
				p:boxAt(
					CFrame.Angles(0, k * math.pi / 4, 0) * CFrame.new(0, 1.1, 5.3),
					side,
					0.4,
					0.6,
					STONE,
					"Concrete"
				)
			end
			p:cyl(0, 1.6, 0, 1.4, 1.3, "y", shade(STONE, 0.92), "Concrete")
			p:cone(0, 0, 0, 0.9, 4.4, STONE, "Concrete").cf = CFrame.new(0, 1.85, 0) * CFrame.Angles(math.pi, 0, 0)
			p:cyl(0, 2.45, 0, 0.5, 4.4, "y", STONE, "Concrete")
			p:cyl(0, 3.1, 0, 0.8, 0.6, "y", shade(STONE, 0.92), "Concrete")
			p:cone(0, 0, 0, 0.5, 2, STONE, "Concrete").cf = CFrame.new(0, 3.35, 0) * CFrame.Angles(math.pi, 0, 0)
			p:cyl(0, 3.75, 0, 0.3, 2, "y", STONE, "Concrete")
			p:cyl(0, 3.98, 0, 0.3, 0.32, "y", shade(STONE, 0.92), "Concrete")
		end, true)
		q:cyl(0, 0.87, 0, 0.3, 10.4, "y", WATER, "SmoothPlastic")
		q:cyl(0, 2.77, 0, 0.1, 3.9, "y", WATER, "SmoothPlastic")
		q:cyl(0, 3.97, 0, 0.1, 1.7, "y", WATER, "SmoothPlastic")
		local jet = q:cyl(0, 5, 0, 2, 0.5, "y", rgb(214, 240, 255), "Glass")
		jet.transp = 0.35
		jet.collide = false
		jet.name = "Jet" -- the client sprays water from it
	end)
end

M.fountainSmall = function(r: R)
	fountain(r, 0, 0, 0)
end

-- A billboard on two legs: a sunny picture and two lines of writing. (The town draws the one in
-- Data/StreetModels by this name; this one is no longer seen.)
M.billboard = function(r: R)
	for _, x in { -5, 5 } do
		r:block(x - 0.3, 0, -0.3, x + 0.3, 9, 0.3, DARK, "Metal")
	end
	r:block(-8, 9, -0.4, 8, 17, 0.4, WHITE, "SmoothPlastic")
	r:block(-7.4, 9.6, -0.5, 7.4, 16.4, -0.4, rgb(140, 206, 250), "SmoothPlastic")
	r:cyl(-3.6, 13, -0.52, 0.1, 4.4, "z", YELLOW, "SmoothPlastic")
	r:block(0.4, 13.4, -0.56, 6.4, 14.4, -0.5, WHITE, "SmoothPlastic")
	r:block(0.4, 11.4, -0.56, 4.6, 12.4, -0.5, WHITE, "SmoothPlastic")
end

M.hedgeRow = function(r: R)
	hedgeRow(r, CFrame.identity)
end

-- A flower bed 12 long: timber edging, soil, mounds of leaves and flowers at two heights.
M.flowerStrip = function(r: R)
	edgedBed(r, CFrame.identity, 12, 2.2)
	local tall =
		{ { -4.6, 0.3, 1.35 }, { -2.2, -0.35, 1.55 }, { 0.4, 0.25, 1.4 }, { 2.9, -0.3, 1.6 }, { 4.9, 0.3, 1.3 } }
	r:piece(function(p: R)
		for _, s in tall do
			stem(p, s[1], s[2], 0.28, s[3])
		end
		local greens = { FOLIAGE, FOLIAGE_DARK, FOLIAGE_LIGHT }
		for k = 0, 6 do
			p:lump(
				CFrame.new(-5 + k * 1.66, 0.62, (k % 2 - 0.5) * 0.5) * CFrame.Angles(0, k * 0.5, 0),
				1.5,
				1.0,
				1.15,
				greens[k % 3 + 1],
				"Grass"
			)
		end
	end)
	r:piece(function(p: R)
		for i, s in tall do
			p:ball(s[1], s[3], s[2], 0.52, bloom(i), "Fabric")
		end
		for k = 0, 5 do
			p:ball(-4.2 + k * 1.66, 1.12, (k % 2 - 0.5) * -0.55, 0.42, bloom(k + 3), "Fabric")
		end
		p:box(-2.2, 1.77, -0.35, 0.16, 0.16, 0.16, YELLOW, "Fabric")
	end)
end

-- A manhole cover, flat on the road: a rim and a cover with ribs across it.
M.manhole = function(r: R)
	r:cyl(0, 0.02, 0, 0.04, 3, "y", rgb(84, 88, 100), "Metal")
	r:cyl(0, 0.09, 0, 0.1, 2.4, "y", rgb(104, 108, 120), "Metal")
	for k = -1, 1 do
		r:block(
			-0.9 + math.abs(k) * 0.25,
			0.14,
			k * 0.5 - 0.06,
			0.9 - math.abs(k) * 0.25,
			0.18,
			k * 0.5 + 0.06,
			rgb(90, 94, 106),
			"Metal"
		)
	end
end

-- Pockets: little places for the gaps between buildings, each inside a 32 by 32 square -----------------

-- A terrace: a kiosk, three tables under parasols, shrubs in pots, lamps and a bin, on paving
-- with a border of darker stones.
M.pocketCafe = function(r: R)
	r:block(-14.4, 0, -14.4, 14.4, 0.12, 14.4, rgb(236, 214, 190), "Pavement")
	parts(r, function(p: R)
		local c, t = rgb(214, 200, 184), 0.6
		p:block(-15, 0, -15, 15, 0.17, -15 + t, c, "Pavement")
		p:block(-15, 0, 15 - t, 15, 0.17, 15, c, "Pavement")
		p:block(-15, 0, -15 + t, -15 + t, 0.17, 15 - t, c, "Pavement")
		p:block(15 - t, 0, -15 + t, 15, 0.17, 15 - t, c, "Pavement")
	end, true)
	group(r, CFrame.new(0, 0.12, 9), function(q: R)
		M.kiosk(q)
	end)
	cafe(r, -8, 0.12, -4, RED)
	cafe(r, 8, 0.12, -4, TEAL)
	cafe(r, 0, 0.12, -10, YELLOW)
	for _, sx in { -1, 1 } do
		shrub(r, sx * 13, 0.12, 4)
		shrub(r, sx * 13, 0.12, 9)
	end
	lamp(r, -13, 0.12, -13)
	lamp(r, 13, 0.12, -13)
	bin(r, 6, 0.12, 6.4)
end

-- A pocket garden: a lawn with a hedge down each side, a path through with an edge of darker
-- stones, two beds of flowers, shrubs where the path comes in, bushes, two benches and a lamp.
M.pocketGarden = function(r: R)
	r:block(-15, 0, -15, 15, 0.2, 15, LAWN, "Grass")
	r:block(-2, 0.2, -15, 2, 0.32, 15, PAVING, "Pavement")
	parts(r, function(p: R)
		for _, sx in { -1, 1 } do
			p:block(sx * 2 - 0.12, 0.2, -15, sx * 2 + 0.12, 0.44, 15, shade(PAVING, 0.86), "Pavement")
		end
	end, true)
	for _, sx in { -1, 1 } do
		hedgeRow(r, CFrame.new(sx * 14, 0.2, 0) * CFrame.Angles(0, math.pi / 2, 0))
		edgedBed(r, CFrame.new(sx * 8, 0.2, 0), 6, 8)
		wildflowers(r, CFrame.new(sx * 8, 0.5, -1.4) * CFrame.Angles(0, sx, 0))
		bench(r, sx * 3.6, sx * 9, sx * -90, 0.2)
		for _, sz in { -1, 1 } do
			shrub(r, sx * 3.6, 0.2, sz * 13.6)
		end
		bush(r, sx * 11, 0.2, -11.5, 0.9, sx)
		bush(r, sx * 11, 0.2, 11.5, 0.8, -sx)
	end
	lamp(r, 3.2, 0.2, 0)
	bin(r, -3.2, 0.2, 6)
end

-- A round fountain on a ring of darker paving, with benches and potted shrubs round it.
M.pocketFountain = function(r: R)
	-- (both rings stand a little clear of the ground, so their rims never meet the edge of a path
	-- laid under them, which reaches 0.02 up)
	r:cyl(0, 0.08, 0, 0.1, 30, "y", PAVING, "Pavement")
	r:cyl(0, 0.16, 0, 0.16, 16, "y", shade(PAVING, 0.9), "Pavement")
	fountain(r, 0, 0.24, 0)
	for k = 0, 3 do
		local a = math.rad(45 + k * 90)
		shrub(r, math.cos(a) * 11.5, 0.12, math.sin(a) * 11.5)
	end
	bench(r, 0, -10.5, 180, 0.12)
	bench(r, 0, 10.5, 0, 0.12)
	bench(r, -10.5, 0, 90, 0.12)
	bench(r, 10.5, 0, -90, 0.12)
	lamp(r, -13, 0.12, 0.1)
	lamp(r, 13, 0.12, 0.1)
end

-- A statue in a ring of flowers, kerbed in stone.
M.pocketStatue = function(r: R)
	r:cyl(0, 0.06, 0, 0.12, 28, "y", PAVING, "Pavement")
	r:cyl(0, 0.1, 0, 0.2, 14.6, "y", shade(STONE, 0.9), "Concrete")
	r:cyl(0, 0.16, 0, 0.3, 14, "y", SOIL, "Ground")
	statue(r, 0, 0.3, 0)
	for k = 0, 2 do
		wildflowers(
			r,
			CFrame.Angles(0, k * math.pi * 2 / 3 + 0.4, 0) * CFrame.new(5.1, 0.3, 0) * CFrame.Angles(0, k, 0)
		)
	end
	bench(r, -10, -8, 135, 0.12)
	bench(r, 10, -8, -135, 0.12)
	lamp(r, -11, 0.12, 8)
	lamp(r, 11, 0.12, 8)
end

-- Two food trucks, tables, a bin and bunting between two posts.
M.pocketTrucks = function(r: R)
	r:block(-15, 0, -15, 15, 0.1, 15, ASPHALT, "Asphalt")
	truck(r, -6.5, 10, PINK)
	truck(r, 7, 3, TEAL)
	cafe(r, -9, 0.1, -3, YELLOW)
	cafe(r, 1, 0.1, -9, RED)
	cafe(r, 10, 0.1, -9, TEAL)
	bin(r, -3, 0.1, -12)
	parts(r, function(p: R)
		for _, x in { -14, 14 } do
			p:block(x - 0.2, 0, -14.2, x + 0.2, 7, -13.8, DARK, "Metal")
			p:block(x - 0.4, 0, -14.4, x + 0.4, 0.2, -13.6, DARK, "Metal")
		end
		p:beam(Vector3.new(-14, 6.7, -14), Vector3.new(0, 6.1, -14), 0.06, 0.06, DARK, "Metal")
		p:beam(Vector3.new(0, 6.1, -14), Vector3.new(14, 6.7, -14), 0.06, 0.06, DARK, "Metal")
		for k = 0, 8 do
			local x = -12 + k * 3
			local y = 6.6 - 0.6 * (1 - math.abs(x) / 14)
			p:wedge(
				CFrame.new(x, y - 0.55, -14) * CFrame.Angles(math.pi / 2, 0, 0),
				1.1,
				0.08,
				1.1,
				({ RED, YELLOW, BLUE })[k % 3 + 1],
				"Fabric"
			)
		end
	end)
end

-- A small car park: eight bays with wheel stops, four cars, a pay machine and a sign.
M.pocketParking = function(r: R)
	r:block(-15, 0, -15, 15, 0.1, 15, ASPHALT, "Asphalt")
	parts(r, function(p: R)
		for k = 0, 4 do
			local x = -12 + k * 6
			p:block(x - 0.1, 0.1, -14, x + 0.1, 0.14, -5, WHITE, "SmoothPlastic")
			p:block(x - 0.1, 0.1, 5, x + 0.1, 0.14, 14, WHITE, "SmoothPlastic")
		end
		for k = 0, 3 do
			local x = -9 + k * 6
			p:block(x - 1.4, 0.1, -14, x + 1.4, 0.4, -13.4, shade(STONE, 0.9), "Concrete")
			p:block(x - 1.4, 0.1, 13.4, x + 1.4, 0.4, 14, shade(STONE, 0.9), "Concrete")
		end
	end)
	type Parked = { at: CFrame, color: Color3 }
	local parked: { Parked } = {
		{ at = CFrame.new(-9, 0.1, -9.5), color = RED },
		{ at = CFrame.new(3, 0.1, -9.5), color = rgb(246, 242, 232) },
		{ at = CFrame.new(-3, 0.1, 9.5) * CFrame.Angles(0, math.pi, 0), color = BLUE },
		{ at = CFrame.new(9, 0.1, 9.5) * CFrame.Angles(0, math.pi, 0), color = YELLOW },
	}
	for _, c in parked do
		group(r, c.at, function(q: R)
			for _, prim in AmbientModels.prims("parked", c.color) do
				q:add(prim)
			end
		end)
	end
	-- the pay machine and the parking sign by the way in
	parts(r, function(p: R)
		p:block(-14, 0.1, -0.45, -12.8, 0.3, 0.45, DARK, "Metal")
		p:block(-13.9, 0.3, -0.35, -12.9, 4.1, 0.35, rgb(90, 120, 170), "Metal")
		p:block(-13.96, 4.1, -0.41, -12.84, 4.3, 0.41, DARK, "Metal")
		p:block(-12.9, 2.9, -0.34, -12.85, 3.6, 0.34, rgb(170, 220, 230), "Metal")
		p:block(-12.9, 2.3, -0.3, -12.84, 2.5, 0.3, DARK, "Metal")
		p:block(-12.9, 1.8, -0.12, -12.84, 2.05, 0.12, YELLOW, "Metal")
	end, true)
	parts(r, function(p: R)
		p:block(13.28, 0.1, 0.08, 13.52, 6.1, 0.32, METAL, "Metal")
		p:block(12.4, 4.7, 0.32, 14.4, 6.7, 0.42, rgb(70, 110, 180), "Metal")
		p:block(12.9, 5.0, 0.42, 13.2, 6.4, 0.48, WHITE, "Metal")
		p:block(13.2, 6.1, 0.42, 13.85, 6.4, 0.48, WHITE, "Metal")
		p:block(13.2, 5.5, 0.42, 13.85, 5.8, 0.48, WHITE, "Metal")
		p:block(13.7, 5.8, 0.42, 14.0, 6.1, 0.48, WHITE, "Metal")
	end, true)
	lamp(r, -14, 0.1, 4)
	lamp(r, 14, 0.1, -3)
end

-- A picnic table: five boards on top, two on each bench, and at each end two legs crossed under
-- a bearer for the top and one for the seats, braced from the middle. One piece.
local function picnic(r: R, x: number, y: number, z: number, yaw: number)
	group(r, CFrame.new(x, y, z) * CFrame.Angles(0, math.rad(yaw), 0), function(q: R)
		q:piece(function(p: R)
			for k = -2, 2 do
				p:block(-3, 2.28, k * 0.52 - 0.24, 3, 2.5, k * 0.52 + 0.24, WOOD, "Wood")
			end
			for _, sz in { -1, 1 } do
				for k = 0, 1 do
					local zc = sz * (1.95 + k * 0.5)
					p:block(-3, 1.2, zc - 0.22, 3, 1.4, zc + 0.22, WOOD, "Wood")
				end
			end
			for _, sx in { -1, 1 } do
				local ex = sx * 2.2
				p:block(ex - 0.14, 2.06, -1.3, ex + 0.14, 2.28, 1.3, WOOD_DARK, "Wood")
				p:block(ex - 0.14, 0.98, -2.7, ex + 0.14, 1.2, 2.7, WOOD_DARK, "Wood")
				for _, sz in { -1, 1 } do
					p:beam(Vector3.new(ex, 0, sz * 2.3), Vector3.new(ex, 2.2, sz * 0.5), 0.26, 0.28, WOOD_DARK, "Wood")
				end
				p:beam(Vector3.new(ex, 1.1, 0), Vector3.new(0, 2.1, 0), 0.16, 0.16, WOOD_DARK, "Wood")
			end
		end, true)
	end)
end

M.picnicTable = function(r: R)
	picnic(r, 0, 0, 0, 0)
end

-- Picnic tables on a lawn, with a kettle barbecue, a checked blanket with a basket and a plate
-- on it, flowers and bushes.
M.pocketPicnic = function(r: R)
	r:block(-15, 0, -15, 15, 0.2, 15, LAWN, "Grass")
	picnic(r, -7, 0.2, -6, 20)
	picnic(r, 7, 0.2, 5, -15)
	parts(r, function(p: R)
		local o = Vector3.new(-8.5, 0.2, 8.2)
		for k = 0, 2 do
			local a = k * math.pi * 2 / 3
			p:beam(
				o + Vector3.new(math.cos(a) * 0.9, 0, math.sin(a) * 0.9),
				o + Vector3.new(math.cos(a) * 0.45, 1.6, math.sin(a) * 0.45),
				0.12,
				0.12,
				DARK,
				"Metal"
			)
		end
		p:lump(CFrame.new(o + Vector3.new(0, 1.9, 0)), 2.0, 1.2, 2.0, rgb(150, 70, 66), "Metal")
		p:lump(
			CFrame.new(o + Vector3.new(0, 2.42, 0)) * CFrame.Angles(0, math.pi / 8, 0),
			1.86,
			1.0,
			1.86,
			rgb(170, 82, 76),
			"Metal"
		)
		p:block(o.X - 0.3, o.Y + 2.88, o.Z - 0.08, o.X + 0.3, o.Y + 3.03, o.Z + 0.08, DARK, "Metal")
		p:block(o.X + 0.9, o.Y + 1.9, o.Z - 0.5, o.X + 1.7, o.Y + 1.98, o.Z + 0.5, WOOD_DARK, "Wood")
	end, true)
	parts(r, function(p: R)
		for i = 0, 3 do
			for j = 0, 2 do
				p:block(
					4 + i * 1.75,
					0.2,
					-12 + j * 1.67,
					5.75 + i * 1.75,
					0.32,
					-10.33 + j * 1.67,
					if (i + j) % 2 == 0 then RED else WHITE,
					"Fabric"
				)
			end
		end
		p:block(5, 0.32, -11, 6.6, 1.2, -9.8, WOOD, "Wood")
		p:block(4.95, 1.2, -11.05, 6.65, 1.36, -9.75, WOOD_DARK, "Wood")
		p:beam(Vector3.new(5.1, 1.36, -10.4), Vector3.new(5.8, 2.1, -10.4), 0.12, 0.12, WOOD_DARK, "Wood")
		p:beam(Vector3.new(5.8, 2.1, -10.4), Vector3.new(6.5, 1.36, -10.4), 0.12, 0.12, WOOD_DARK, "Wood")
		p:cyl(8, 0.35, -9, 0.06, 1.1, "y", WHITE, "SmoothPlastic")
	end)
	wildflowers(r, CFrame.new(-11, 0.2, -11))
	wildflowers(r, CFrame.new(11, 0.2, 11) * CFrame.Angles(0, 2, 0))
	bush(r, 12, 0.2, -12, 1, 0.4)
	bush(r, -12, 0.2, 12, 0.85, 1.2)
end

-- A raised vegetable bed 8 by 6: plank sides, soil and a crop of one kind.
local function vegBed(r: R, x: number, z: number, kind: number)
	group(r, CFrame.new(x, 0.2, z), function(q: R)
		edgedBed(q, CFrame.identity, 8, 6)
		parts(q, function(p: R)
			if kind == 1 then
				-- cabbages: a head in a ring of outer leaves
				for i = 0, 2 do
					for j = 0, 1 do
						local cx, cz = -2.4 + i * 2.4, -1.2 + j * 2.4
						p:lump(
							CFrame.new(cx, 0.55, cz) * CFrame.Angles(0, i + j, 0),
							1.7,
							0.5,
							1.7,
							FOLIAGE_DARK,
							"Grass"
						)
						p:ball(cx, 0.82, cz, 0.95, rgb(170, 204, 140), "Grass")
					end
				end
			elseif kind == 2 then
				-- carrots: rows of feathery tops over a ridge with the orange shoulders showing
				for j = 0, 2 do
					p:block(
						-3.3,
						0.3,
						-1.8 + j * 1.8 - 0.2,
						3.3,
						0.42,
						-1.8 + j * 1.8 + 0.2,
						rgb(226, 140, 84),
						"Grass"
					)
					for i = 0, 3 do
						p:cone(-2.7 + i * 1.8, 0.8, -1.8 + j * 1.8, 0.9, 0.5, FOLIAGE_LIGHT, "Grass")
					end
				end
			elseif kind == 3 then
				-- tomatoes on canes
				for i = 0, 2 do
					for _, cz in { -1.3, 1.3 } do
						local cx = -2.4 + i * 2.4
						p:block(cx - 0.05, 0.3, cz - 0.05, cx + 0.05, 2.6, cz + 0.05, rgb(176, 150, 100), "Wood")
						p:lump(CFrame.new(cx, 1.4, cz) * CFrame.Angles(0, i, 0), 0.9, 1.7, 0.9, FOLIAGE, "Grass")
						p:ball(cx + 0.32, 1.2, cz - 0.25, 0.34, rgb(206, 92, 84), "SmoothPlastic")
					end
				end
			else
				-- lettuces in rows
				for i = 0, 3 do
					for j = 0, 2 do
						p:lump(
							CFrame.new(-2.7 + i * 1.8, 0.52, -1.8 + j * 1.8) * CFrame.Angles(0, i * 0.7 + j, 0),
							1.15,
							0.6,
							1.15,
							if (i + j) % 2 == 0 then rgb(164, 196, 110) else FOLIAGE_LIGHT,
							"Grass"
						)
					end
				end
			end
		end)
	end)
end

-- An allotment: four vegetable beds, a shed with a door and a window, a water butt, tools and
-- a watering can, with a hedge down each side.
M.pocketAllotment = function(r: R)
	r:block(-15, 0, -15, 15, 0.2, 15, LAWN, "Grass")
	for i, p in { { -8, -7 }, { 2, -7 }, { -8, 3 }, { 2, 3 } } do
		vegBed(r, p[1], p[2], i)
	end
	-- the shed: plank walls, a felt roof that overhangs, corner posts, a door in its frame with
	-- two rails and a handle, and a window with a sill on the side
	local shedWall = rgb(176, 124, 104)
	local door = rgb(110, 84, 62)
	r:block(8, 0.2, 6, 14, 6, 13, shedWall, "WoodPlanks")
	parts(r, function(p: R)
		p:block(7.5, 6, 5.5, 14.5, 6.35, 13.5, rgb(84, 80, 86), "Wood")
		p:block(7.4, 5.75, 5.4, 14.6, 6.0, 5.6, shade(shedWall, 0.8), "Wood")
		for _, c in { { 8, 6 }, { 14, 6 }, { 8, 13 }, { 14, 13 } } do
			p:block(c[1] - 0.18, 0.2, c[2] - 0.18, c[1] + 0.18, 5.75, c[2] + 0.18, shade(shedWall, 0.78), "Wood")
		end
		p:block(9.7, 0.2, 5.86, 12.3, 4.7, 6, shade(shedWall, 0.78), "Wood")
		p:block(10, 0.2, 5.8, 12, 4.4, 5.86, door, "Wood")
		for _, y in { 1, 3.6 } do
			p:block(10.05, y, 5.74, 11.95, y + 0.3, 5.8, shade(door, 0.85), "Wood")
		end
		p:block(11.5, 2.2, 5.66, 11.75, 2.4, 5.74, DARK, "Metal")
		p:block(7.86, 2.6, 8.4, 8, 4.8, 11, WHITE, "Wood")
		p:block(7.74, 2.4, 8.2, 8, 2.6, 11.2, WHITE, "Wood")
	end, true)
	r:block(7.8, 2.8, 8.6, 7.86, 4.6, 10.8, GLASS, "Glass")
	-- the water butt on its stand, with hoops, a lid and a tap
	parts(r, function(p: R)
		local x, y, z, blue = 11, 0.2, -10, rgb(90, 128, 170)
		p:block(x - 1.4, y, z - 1.4, x + 1.4, y + 0.7, z + 1.4, WOOD_DARK, "Wood")
		p:cyl(x, y + 2.05, z, 2.7, 2.6, "y", blue, "SmoothPlastic")
		p:cyl(x, y + 1.3, z, 0.18, 2.66, "y", shade(blue, 0.84), "SmoothPlastic")
		p:cyl(x, y + 2.7, z, 0.18, 2.66, "y", shade(blue, 0.84), "SmoothPlastic")
		p:cyl(x, y + 3.45, z, 0.12, 2.76, "y", shade(blue, 0.68), "SmoothPlastic")
		p:block(x - 0.12, y + 1.1, z - 1.5, x + 0.12, y + 1.24, z - 1.25, DARK, "Metal")
	end, true)
	-- a spade and a rake leaning on the shed, and a watering can
	parts(r, function(p: R)
		p:beam(Vector3.new(14.3, 0.2, 9), Vector3.new(14.9, 4.6, 9.3), 0.12, 0.12, WOOD, "Wood")
		p:boxAt(CFrame.new(14.25, 0.75, 8.97) * CFrame.Angles(0, 0, math.rad(8)), 0.08, 1, 0.75, METAL, "Metal")
		p:beam(Vector3.new(14.3, 0.2, 10.6), Vector3.new(14.9, 5, 10.4), 0.12, 0.12, WOOD, "Wood")
		p:block(14.85, 4.9, 9.9, 15, 5.05, 10.9, DARK, "Metal")
		p:cyl(5.8, 0.75, 12.8, 1.1, 1.1, "y", rgb(104, 150, 120), "Metal")
		p:beam(Vector3.new(5.8, 0.9, 12.4), Vector3.new(5.8, 1.6, 11.6), 0.14, 0.14, rgb(104, 150, 120), "Metal")
	end)
	for _, sx in { -1, 1 } do
		hedgeRow(r, CFrame.new(sx * 14.1, 0.2, -2) * CFrame.Angles(0, math.pi / 2, 0))
	end
end

-- A little duck pond: water in a rim of stones, reeds with brown heads, lily pads with flowers,
-- stepping stones, two benches and flowers. (The ducks are the client's: they swim.)
M.pocketPond = function(r: R)
	r:block(-15, 0, -15, 15, 0.2, 15, LAWN, "Grass")
	r:cyl(0, 0.26, 0, 0.12, 19.4, "y", shade(SOIL, 1.2), "Ground")
	r:cyl(0, 0.38, 0, 0.12, 17.6, "y", WATER, "SmoothPlastic")
	parts(r, function(p: R)
		for k = 0, 13 do
			local a = k * math.pi * 2 / 14
			p:lump(
				CFrame.new(math.cos(a) * 9.2, 0.38, math.sin(a) * 9.2) * CFrame.Angles(0, -a + (k % 3) * 0.4, 0),
				2.6 + (k % 3) * 0.4,
				0.6 + (k % 2) * 0.2,
				1.3,
				shade(ROCK, 1.1 + (k % 3) * 0.06),
				"Slate"
			)
		end
		for k = 0, 2 do
			p:cyl(4.5 + k * 2.6, 0.44, 4.5 + k * 2.2, 0.24, 2, "y", ROCK, "Slate")
		end
	end, true)
	parts(r, function(p: R)
		for k = 0, 4 do
			local a = math.rad(196 + k * 14)
			local x, z = math.cos(a) * 8.1, math.sin(a) * 8.1
			local h = 2.4 + (k % 3) * 0.5
			p:block(x - 0.07, 0.3, z - 0.07, x + 0.07, 0.3 + h, z + 0.07, REED, "Grass")
			p:cyl(x, 0.3 + h - 0.3, z, 0.6, 0.24, "y", CATTAIL, "Grass")
		end
		for _, l in { { -3, 2, 1.4 }, { -4.4, -1, 1.1 }, { 2.4, -4, 1.3 }, { 1, 4.6, 1.0 } } do
			p:cyl(l[1], 0.46, l[2], 0.04, l[3], "y", rgb(96, 168, 92), "SmoothPlastic")
		end
		p:ball(-3.1, 0.6, 2.1, 0.4, PINK, "SmoothPlastic")
		p:ball(2.5, 0.6, -4.1, 0.36, WHITE, "SmoothPlastic")
	end)
	bench(r, -11, -11, 135, 0.2)
	bench(r, 11, -11, -135, 0.2)
	wildflowers(r, CFrame.new(11.5, 0.2, 11.5))
	wildflowers(r, CFrame.new(-11.5, 0.2, 11.5) * CFrame.Angles(0, 2.5, 0))
end

-- A small playground: swings on an A frame, a slide with a ladder, a sandpit with toys in it, a
-- roundabout and a bench.
M.pocketPlay = function(r: R)
	r:block(-15, 0, -15, 15, 0.2, 15, rgb(240, 220, 176), "Sand")
	parts(r, function(p: R)
		-- the swings: two A frames, the top bar, chains and seats
		for _, x in { -12, -4 } do
			for _, sz in { -1, 1 } do
				p:beam(Vector3.new(x, 0.2, -9 + sz * 1.6), Vector3.new(x, 7.1, -9), 0.3, 0.3, RED, "Metal")
			end
		end
		p:cyl(-8, 7, -9, 8.4, 0.4, "x", RED, "Metal")
		for _, x in { -10, -6 } do
			p:block(x - 0.8, 1.6, -9.4, x + 0.8, 1.8, -8.6, DARK, "SmoothPlastic")
			for _, sx in { -1, 1 } do
				p:block(x + sx * 0.7 - 0.04, 1.8, -9.04, x + sx * 0.7 + 0.04, 6.8, -8.96, METAL, "Metal")
			end
		end
	end, true)
	parts(r, function(p: R)
		-- the slide: a tower on four posts with a rail, a ladder up the back and the chute's sides
		for _, c in { { 4, -10 }, { 8, -10 }, { 4, -6 }, { 8, -6 } } do
			p:block(c[1] - 0.15, 0.2, c[2] - 0.15, c[1] + 0.15, 6.4, c[2] + 0.15, BLUE, "SmoothPlastic")
		end
		p:block(3.78, 4.8, -10.22, 8.22, 5, -5.78, shade(BLUE, 1.15), "SmoothPlastic")
		p:block(4, 6.2, -10.2, 8, 6.4, -10, BLUE, "SmoothPlastic")
		p:block(3.75, 6.2, -10, 3.95, 6.4, -6, BLUE, "SmoothPlastic")
		p:block(8.05, 6.2, -10, 8.25, 6.4, -6, BLUE, "SmoothPlastic")
		for _, x in { 5.2, 6.8 } do
			p:beam(Vector3.new(x, 0.2, -12.2), Vector3.new(x, 5, -10.15), 0.16, 0.16, BLUE, "SmoothPlastic")
		end
		for k = 1, 4 do
			local t = k / 5
			local y, z = 0.2 + 4.8 * t, -12.2 + 2.05 * t
			p:block(5.28, y - 0.05, z - 0.08, 6.72, y + 0.05, z + 0.08, shade(BLUE, 1.15), "SmoothPlastic")
		end
		for _, x in { 4.45, 7.55 } do
			p:beam(Vector3.new(x, 5.4, -6), Vector3.new(x, 0.6, 3), 0.2, 0.4, shade(YELLOW, 0.9), "SmoothPlastic")
		end
	end, true)
	r:ramp(4.6, 0.2, -6, 7.4, 5, 3, false, YELLOW, "SmoothPlastic")
	-- the sandpit: a timber frame, the sand, a bucket and spade and a half built castle
	parts(r, function(p: R)
		p:block(-12, 0.2, 2, -3, 0.8, 2.6, WOOD, "Wood")
		p:block(-12, 0.2, 10.4, -3, 0.8, 11, WOOD, "Wood")
		p:block(-12, 0.2, 2.6, -11.4, 0.8, 10.4, WOOD, "Wood")
		p:block(-3.6, 0.2, 2.6, -3, 0.8, 10.4, WOOD, "Wood")
	end, true)
	r:block(-11.42, 0.2, 2.58, -3.58, 0.6, 10.42, rgb(255, 236, 190), "Sand")
	parts(r, function(p: R)
		p:cyl(-8, 0.9, 6, 0.6, 0.9, "y", RED, "SmoothPlastic")
		p:cyl(-8, 1.22, 6, 0.08, 1.0, "y", shade(RED, 0.8), "SmoothPlastic")
		p:beam(Vector3.new(-6.4, 0.65, 5.2), Vector3.new(-5.2, 0.9, 5.9), 0.1, 0.1, YELLOW, "SmoothPlastic")
		p:block(-6.75, 0.6, 4.95, -6.25, 0.68, 5.45, YELLOW, "SmoothPlastic")
		p:lump(CFrame.new(-9.4, 0.7, 8.6), 1.6, 0.7, 1.4, rgb(250, 230, 180), "Sand")
	end)
	-- the roundabout: the turning plate, the hub, handles and a ring to hold
	parts(r, function(p: R)
		p:cyl(8, 0.7, 9, 0.3, 6.6, "y", TEAL, "Metal")
		p:cyl(8, 0.9, 9, 0.12, 2, "y", shade(TEAL, 1.15), "Metal")
		for k = 0, 3 do
			local a = k * math.pi / 2
			local hx, hz = 8 + math.cos(a) * 1.8, 9 + math.sin(a) * 1.8
			p:block(hx - 0.06, 0.85, hz - 0.06, hx + 0.06, 1.8, hz + 0.06, YELLOW, "Metal")
		end
		p:cyl(8, 1.8, 9, 0.12, 3.8, "y", YELLOW, "Metal")
	end, true)
	bench(r, 0, 13, 0, 0.2)
end

-- The hills -------------------------------------------------------------------------------------------

-- Rocks: lumps of stone with pebbles at their foot, and moss on top.
M.boulder = function(r: R)
	r:piece(function(p: R)
		p:block(-0.8, 0, -0.8, 0.8, 1.2, 0.8, ROCK, "Slate")
		p:lump(CFrame.new(0, 1.5, 0) * CFrame.Angles(0.2, 0.5, 0.15), 5.4, 3.8, 4.6, ROCK, "Slate")
		p:lump(CFrame.new(2.6, 0.9, 1.7) * CFrame.Angles(-0.2, 1.1, 0.3), 3, 2.2, 2.6, shade(ROCK, 1.1), "Slate")
		p:lump(CFrame.new(-2.3, 0.7, -1.5) * CFrame.Angles(0.3, 0.2, -0.2), 2.4, 1.7, 2.2, shade(ROCK, 0.9), "Slate")
		p:lump(CFrame.new(-1.2, 0.2, 2.4) * CFrame.Angles(0, 0.7, 0), 0.9, 0.5, 0.7, shade(ROCK, 1.05), "Slate")
		p:lump(CFrame.new(3.7, 0.15, -0.6) * CFrame.Angles(0, 1.3, 0), 0.7, 0.4, 0.6, shade(ROCK, 0.95), "Slate")
		p:lump(CFrame.new(-3.3, 0.15, 0.7) * CFrame.Angles(0, 0.4, 0), 0.8, 0.45, 0.6, ROCK, "Slate")
	end, true)
	r:lump(CFrame.new(-0.3, 3.28, -0.1) * CFrame.Angles(0.12, 1.3, 0.06), 2.4, 0.5, 2.0, MOSS, "Grass")
end

M.boulderBig = function(r: R)
	parts(r, function(p: R)
		p:lump(CFrame.new(0, 3, 0) * CFrame.Angles(0.15, 0.7, 0.1), 10, 7.4, 8.6, ROCK, "Slate")
		p:lump(CFrame.new(4.8, 1.6, 2.8) * CFrame.Angles(-0.2, 0.3, 0.3), 5.4, 3.8, 4.8, shade(ROCK, 1.1), "Slate")
		p:lump(CFrame.new(-4.2, 1.2, -3.2) * CFrame.Angles(0.25, 1.2, -0.15), 4.4, 3, 4, shade(ROCK, 0.9), "Slate")
		p:lump(CFrame.new(-3.4, 0.3, 3.6) * CFrame.Angles(0, 0.6, 0), 1.6, 0.9, 1.3, shade(ROCK, 1.05), "Slate")
		p:lump(CFrame.new(6.3, 0.25, -1.4) * CFrame.Angles(0, 1.1, 0), 1.2, 0.7, 1, shade(ROCK, 0.95), "Slate")
	end, true)
	parts(r, function(p: R)
		p:lump(CFrame.new(1, 6.2, -1) * CFrame.Angles(0.1, 0.4, 0), 3.4, 1.4, 3, MOSS, "Grass")
		p:lump(CFrame.new(-1.6, 5.9, 1.2) * CFrame.Angles(0.15, 1.1, 0.1), 2.4, 0.7, 1.8, FOLIAGE_DARK, "Grass")
		tuft(p, -5.6, 0, 1.2, 1, 0.2)
		tuft(p, 3.4, 0, -3.6, 0.9, 1.4)
	end)
end

-- A fallen log with its sawn ends showing the rings, a stub of a branch, moss and a mushroom,
-- and the stump it came from with its roots.
M.log = function(r: R)
	local ring, core = rgb(226, 190, 140), rgb(200, 160, 112)
	parts(r, function(p: R)
		p:cyl(0, 0.9, 0, 8, 1.8, "x", WOOD_DARK, "Wood")
		p:cyl(4.01, 0.9, 0, 0.1, 1.6, "x", ring, "Wood")
		p:cyl(4.07, 0.9, 0, 0.08, 0.8, "x", core, "Wood")
		p:cyl(-4.01, 0.9, 0, 0.1, 1.6, "x", ring, "Wood")
		p:beam(Vector3.new(1.2, 1.4, -0.4), Vector3.new(1.9, 2.2, -1.2), 0.4, 0.4, WOOD_DARK, "Wood")
		p:cyl(-5.4, 0.7, 2, 1.4, 2, "y", WOOD_DARK, "Wood")
		p:cyl(-5.4, 1.49, 2, 0.06, 1.8, "y", ring, "Wood")
		for k = 0, 2 do
			local a = 0.6 + k * 2.1
			p:beam(
				Vector3.new(-5.4 + math.cos(a) * 0.7, 0.5, 2 + math.sin(a) * 0.7),
				Vector3.new(-5.4 + math.cos(a) * 1.5, 0, 2 + math.sin(a) * 1.5),
				0.4,
				0.4,
				WOOD_DARK,
				"Wood"
			)
		end
	end, true)
	parts(r, function(p: R)
		p:lump(CFrame.new(-1.2, 1.75, 0), 2.6, 0.4, 1.3, MOSS, "Grass")
		p:cyl(2.4, 1.85, 0.3, 0.3, 0.16, "y", WHITE, "SmoothPlastic")
		p:lump(CFrame.new(2.4, 2.05, 0.3), 0.6, 0.3, 0.6, rgb(206, 120, 90), "SmoothPlastic")
	end)
end

-- A signpost with three fingers, each a board with a pointed end, and a cap on its post.
M.signpost = function(r: R)
	parts(r, function(p: R)
		p:block(-0.25, 0, -0.25, 0.25, 6.4, 0.25, WOOD_DARK, "Wood")
		p:cone(0, 6.6, 0, 0.4, 0.66, shade(WOOD_DARK, 0.85), "Wood")
		local function finger(y: number, dir: number, len: number)
			local x0 = dir * 0.25
			p:block(
				math.min(x0, x0 + dir * len),
				y - 0.45,
				-0.15,
				math.max(x0, x0 + dir * len),
				y + 0.45,
				0.15,
				WOOD,
				"Wood"
			)
			for _, up in { -1, 1 } do
				local tip = CFrame.new(x0 + dir * (len + 0.25), y + up * 0.225, 0)
					* CFrame.Angles(0, -dir * math.pi / 2, 0)
					* (if up < 0 then CFrame.Angles(0, 0, math.pi) else CFrame.identity)
				p:wedge(tip, 0.3, 0.45, 0.5, WOOD, "Wood")
			end
		end
		finger(5.5, 1, 3.5)
		finger(4.15, -1, 3.1)
		finger(2.9, 1, 2.4)
	end, true)
end

-- A round bale of hay: two bands of twine, the rolled ends and a wisp loose on top.
M.hayBale = function(r: R)
	local hay = rgb(230, 206, 138)
	parts(r, function(p: R)
		p:cyl(0, 1.8, 0, 3.4, 3.6, "x", hay, "SmoothPlastic")
		for _, sx in { -1, 1 } do
			p:cyl(sx * 1.72, 1.8, 0, 0.06, 2.8, "x", rgb(210, 184, 120), "SmoothPlastic")
			p:cyl(sx * 0.8, 1.8, 0, 0.12, 3.66, "x", rgb(176, 150, 110), "SmoothPlastic")
		end
		p:cyl(1.77, 1.8, 0, 0.06, 1.4, "x", rgb(196, 168, 108), "SmoothPlastic")
		p:cone(0, 0, 0, 0.4, 0.5, shade(hay, 1.05), "SmoothPlastic").cf = CFrame.new(0.4, 3.62, 0.3)
			* CFrame.Angles(0.3, 0, 0.5)
	end, true)
end

-- A length of post and rail fence, 14 long: posts with pointed caps, three rails and a brace.
M.fenceRun = function(r: R)
	parts(r, function(p: R)
		for _, x in { -7, 0, 7 } do
			p:block(x - 0.3, 0, -0.3, x + 0.3, 3.2, 0.3, WOOD_DARK, "Wood")
			p:cone(x, 3.4, 0, 0.4, 0.62, WOOD_DARK, "Wood")
		end
		for _, y in { 2.55, 1.6, 0.65 } do
			p:block(-7, y - 0.22, -0.42, 7, y + 0.22, -0.3, WOOD, "Wood")
		end
		p:beam(Vector3.new(-6.7, 0.65, -0.36), Vector3.new(-0.3, 2.55, -0.36), 0.12, 0.3, WOOD, "Wood")
	end, true)
end

M.wildflowers = function(r: R)
	wildflowers(r, CFrame.identity)
end

-- Three mushrooms: stems, caps with pale spots and the gills under them, in a tuft of grass. One
-- piece.
M.mushrooms = function(r: R)
	r:piece(function(p: R)
		p:block(-0.1, 0, -0.1, 0.1, 0.2, 0.1, WHITE, "SmoothPlastic")
		for i, m in { { 0, 0, 1 }, { 1.4, 0.8, 0.7 }, { -1, 1.2, 0.6 } } do
			local s = m[3]
			local cap = if i == 2 then rgb(236, 160, 110) else RED
			p:cyl(m[1], 0.6 * s, m[2], 1.2 * s, 0.5 * s, "y", WHITE, "SmoothPlastic")
			p:cyl(m[1], 1.15 * s, m[2], 0.12 * s, 1.4 * s, "y", rgb(236, 220, 196), "SmoothPlastic")
			p:lump(CFrame.new(m[1], 1.35 * s, m[2]), 1.7 * s, 0.9 * s, 1.7 * s, cap, "SmoothPlastic")
			p:ball(m[1] + 0.3 * s, 1.72 * s, m[2] - 0.2 * s, 0.3 * s, WHITE, "SmoothPlastic")
		end
		tuft(p, 0.6, 0, -0.7, 0.7, 0.5, "SmoothPlastic")
		tuft(p, -1.6, 0, 0.2, 0.6, 2, "SmoothPlastic")
	end)
end

-- A mountain lake: water in a stony rim, a jetty of boards on bearers and posts with a rowing
-- boat tied to it, reeds with brown heads and lily pads, rocks and a bench.
M.tarn = function(r: R)
	r:cyl(0, 0.25, 0, 0.6, 62, "y", rgb(196, 190, 176), "Slate")
	r:cyl(0, 0.6, 0, 0.3, 56, "y", WATER, "SmoothPlastic")
	r:cyl(6, 0.82, -4, 0.1, 30, "y", shade(WATER, 1.12), "SmoothPlastic")
	parts(r, function(p: R)
		for k = 0, 4 do
			local x = -2 + k * 0.8
			p:block(x + 0.04, 0.7, -40, x + 0.76, 1, -14, WOOD, "WoodPlanks")
		end
		for _, z in { -38, -30, -22, -15 } do
			p:block(-2.1, 0.45, z - 0.2, 2.1, 0.7, z + 0.2, WOOD_DARK, "WoodPlanks")
		end
		for _, z in { -36, -26, -16 } do
			for _, x in { -1.9, 1.9 } do
				p:cyl(x, 0.9, z, 2.2, 0.5, "y", WOOD_DARK, "WoodPlanks")
			end
		end
		p:cyl(1.7, 1.5, -15, 1, 0.4, "y", WOOD_DARK, "WoodPlanks")
	end, true)
	group(r, CFrame.new(5, 0.3, -19.5), function(q: R)
		M.rowboat(q)
	end)
	parts(r, function(p: R)
		for k = 0, 7 do
			local a = math.rad(40 + k * 12)
			local x, z = math.cos(a) * 26, math.sin(a) * 26
			local h = 3 + (k % 3) * 0.5
			p:block(x - 0.1, 0.2, z - 0.1, x + 0.1, 0.2 + h, z + 0.1, REED, "Grass")
			p:cyl(x, h - 0.2, z, 0.7, 0.3, "y", CATTAIL, "Grass")
		end
		for _, l in { { -10, 8 }, { -14, 2 }, { 12, 14 }, { 16, -8 } } do
			p:cyl(l[1], 0.94, l[2], 0.08, 3, "y", rgb(96, 180, 90), "SmoothPlastic")
		end
		p:ball(-13.4, 1.12, 2.4, 0.6, PINK, "SmoothPlastic")
		p:ball(12.3, 1.1, 14.2, 0.5, WHITE, "SmoothPlastic")
	end)
	parts(r, function(p: R)
		p:lump(CFrame.new(-28, 1.2, -14) * CFrame.Angles(0.2, 0.4, 0.1), 5.6, 3.4, 4.4, ROCK, "Slate")
		p:lump(CFrame.new(-25.4, 0.5, -12.6) * CFrame.Angles(0, 1, 0), 1.6, 0.9, 1.3, shade(ROCK, 1.05), "Slate")
		p:lump(CFrame.new(26, 1, -18) * CFrame.Angles(-0.1, 1, 0.2), 4.4, 2.8, 3.8, shade(ROCK, 1.1), "Slate")
		p:lump(CFrame.new(24, 0.4, -15.8) * CFrame.Angles(0, 0.3, 0), 1.4, 0.8, 1.1, ROCK, "Slate")
	end, true)
	bench(r, -8, -34, 180, 0.25)
end

-- A ring of old standing stones on a hilltop meadow, with a flat one in the middle: each stone
-- leaning a little and worn round at the top, lichen on some, flowers round about.
M.stoneCircle = function(r: R)
	parts(r, function(p: R)
		for k = 0, 8 do
			local a = math.rad(k * 40)
			local h = 7 + (k * 7) % 4
			local f = CFrame.new(math.cos(a) * 20, h / 2 - 0.3, math.sin(a) * 20)
				* CFrame.Angles(0, -a, 0)
				* CFrame.Angles(0.06, 0, ((k % 3) - 1) * 0.08)
			local c = shade(ROCK, 0.9 + (k % 3) * 0.08)
			p:boxAt(f, 2.2, h, 3.4, c, "Slate")
			p:lump(f * CFrame.new(0, h / 2, 0), 2.3, 0.9, 3.3, c, "Slate")
		end
		p:boxAt(
			CFrame.new(20 * math.cos(math.rad(20)), 9.6, 20 * math.sin(math.rad(20)))
				* CFrame.Angles(0, math.rad(-110), 0),
			16,
			1.6,
			3,
			ROCK,
			"Slate"
		)
		p:boxAt(CFrame.new(0, 0.6, 0) * CFrame.Angles(0, 0.4, 0), 7, 1.2, 4.6, shade(ROCK, 1.1), "Slate")
	end, true)
	parts(r, function(p: R)
		for k = 0, 8, 4 do
			local a = math.rad(k * 40)
			p:lump(
				CFrame.new(math.cos(a) * 18.85, 2.6 + k * 0.2, math.sin(a) * 18.85) * CFrame.Angles(0, -a, 0),
				0.3,
				1.2,
				1.4,
				rgb(170, 186, 120),
				"Grass"
			)
		end
	end)
	for k = 0, 1 do
		wildflowers(r, CFrame.Angles(0, math.rad(30 + k * 180), 0) * CFrame.new(10, 0, 0))
	end
end

-- The beach and the sea ------------------------------------------------------------------------------

-- A beach ball: white, with a band round its middle and one over the top.
local function ball(p: R, x: number, y: number, z: number, d: number)
	p:ball(x, y, z, d, WHITE, "SmoothPlastic")
	p:cyl(x, y, z, d * 0.24, d * 1.0, "x", RED, "SmoothPlastic")
	p:cyl(x, y, z, d * 0.24, d * 1.06, "y", YELLOW, "SmoothPlastic")
end

-- A towel laid out with two stripes and a rolled pillow; beside it sandals, a book left open, a
-- bottle of sun cream and a ball (one piece, the same by every towel).
local function towel(r: R, col: Color3, stripe: Color3, top: number)
	parts(r, function(p: R)
		p:block(-1.8, -0.1, -3.3, 1.8, top, 3.3, col, "Fabric")
		p:block(-1.8, top, -0.7, 1.8, top + 0.04, -0.3, stripe, "Fabric")
		p:block(-1.8, top, 0.3, 1.8, top + 0.04, 0.7, stripe, "Fabric")
		p:cyl(0, top + 0.23, 2.6, 3.2, 0.5, "x", stripe, "Fabric")
	end)
	r:piece(function(p: R)
		for _, sx in { -1, 1 } do
			p:block(2.3 + sx * 0.3 - 0.2, 0, 1.4, 2.3 + sx * 0.3 + 0.2, 0.2, 2.4, rgb(90, 120, 170), "SmoothPlastic")
			p:block(2.3 + sx * 0.3 - 0.2, 0.2, 1.6, 2.3 + sx * 0.3 + 0.2, 0.28, 1.72, rgb(70, 96, 140), "SmoothPlastic")
		end
		p:boxAt(
			CFrame.new(0.4, 0.46, -1.6) * CFrame.Angles(0, 0.3, 0.12),
			0.8,
			0.08,
			1.1,
			rgb(120, 150, 110),
			"SmoothPlastic"
		)
		p:boxAt(
			CFrame.new(-0.36, 0.46, -1.83) * CFrame.Angles(0, 0.3, -0.12),
			0.8,
			0.08,
			1.1,
			rgb(120, 150, 110),
			"SmoothPlastic"
		)
		p:cyl(-1.1, 0.66, 1.2, 0.6, 0.36, "y", rgb(236, 200, 120), "SmoothPlastic")
		p:cyl(-1.1, 1.04, 1.2, 0.16, 0.22, "y", WHITE, "SmoothPlastic")
		ball(p, 2.6, 0.7, -2.4, 1.4)
	end)
end

M.towel = function(r: R)
	towel(r, RED, WHITE, 0.14)
end

M.towel2 = function(r: R)
	towel(r, TEAL, YELLOW, 0.36)
end

-- A sandcastle: a walled base with battlements, four towers with pointed tops, a keep, a gate
-- and a flag, with the bucket and spade that made it.
M.sandcastle = function(r: R)
	parts(r, function(p: R)
		p:block(-2, 0, -2, 2, 1.2, 2, SAND, "Sand")
		for _, s in
			{ { -0.6, -2 }, { 0.6, -2 }, { -0.6, 2 }, { 0.6, 2 }, { -2, -0.6 }, { -2, 0.6 }, { 2, -0.6 }, { 2, 0.6 } }
		do
			p:block(s[1] - 0.22, 1.2, s[2] - 0.22, s[1] + 0.22, 1.5, s[2] + 0.22, SAND, "Sand")
		end
		for _, c in { { -1.6, -1.6 }, { 1.6, -1.6 }, { -1.6, 1.6 }, { 1.6, 1.6 } } do
			p:cyl(c[1], 1.1, c[2], 2.2, 1.4, "y", shade(SAND, 0.96), "Sand")
			p:cone(c[1], 2.55, c[2], 0.7, 1.4, shade(SAND, 1.03), "Sand")
		end
		p:cyl(0, 2, 0, 1.8, 1.6, "y", SAND, "Sand")
		p:cone(0, 3.2, 0, 0.6, 1.6, shade(SAND, 1.03), "Sand")
		p:block(-0.45, 0, -2.04, 0.45, 0.8, -1.96, shade(SAND, 0.62), "Sand")
	end, true)
	parts(r, function(p: R)
		p:block(-0.06, 3.3, -0.06, 0.06, 4.6, 0.06, DARK, "SmoothPlastic")
		p:block(0.06, 3.9, -0.04, 1.1, 4.5, 0.04, RED, "SmoothPlastic")
		p:cyl(2.9, 0.5, 1.6, 1, 1.1, "y", BLUE, "SmoothPlastic")
		p:cyl(2.9, 0.98, 1.6, 0.1, 1.2, "y", shade(BLUE, 0.8), "SmoothPlastic")
		p:beam(Vector3.new(2.6, 0.15, -1.2), Vector3.new(3.6, 0.5, -2.6), 0.12, 0.12, YELLOW, "SmoothPlastic")
		p:boxAt(
			CFrame.new(2.45, 0.1, -0.95) * CFrame.Angles(0, math.rad(-35), 0),
			0.6,
			0.08,
			0.7,
			YELLOW,
			"SmoothPlastic"
		)
	end)
end

M.beachBall = function(r: R)
	parts(r, function(p: R)
		ball(p, 0, 1.1, 0, 2.2)
	end, true)
end

-- Surfboards leaning on a rack: an A frame at each end and two rails with a rubber pad, three
-- boards with rounded ends, a stripe and a fin, and a towel over the top rail.
M.surfRack = function(r: R)
	parts(r, function(p: R)
		for _, x in { -3, 3 } do
			p:block(x - 0.2, 0, -0.2, x + 0.2, 3.6, 0.2, WOOD_DARK, "Wood")
			p:beam(Vector3.new(x, 0, 1.2), Vector3.new(x, 3.4, 0.1), 0.3, 0.3, WOOD_DARK, "Wood")
		end
		p:block(-3, 3.2, -0.15, 3, 3.5, 0.15, WOOD, "Wood")
		p:block(-3, 0.7, -0.15, 3, 0.95, 0.15, WOOD, "Wood")
		p:block(-2.7, 3.22, -0.2, 2.7, 3.48, -0.15, DARK, "SmoothPlastic")
	end, true)
	parts(r, function(p: R)
		for i, x in { -1.8, 0, 1.8 } do
			local col = ({ YELLOW, TEAL, PINK })[i]
			local f = CFrame.new(x, 3.4, -0.9) * CFrame.Angles(math.rad(-14), 0, 0)
			p:boxAt(f, 1.5, 5.6, 0.3, col, "SmoothPlastic")
			for _, e in { 2.8, -2.8 } do
				p:boxAt(f * CFrame.new(0, e, 0) * CFrame.Angles(0, math.pi / 2, 0), 0.3, 1.5, 1.5, col, "SmoothPlastic").shape =
					"Cylinder"
			end
			p:boxAt(f * CFrame.new(0, 0, -0.17), 0.2, 6.4, 0.04, WHITE, "SmoothPlastic")
			p:boxAt(f * CFrame.new(0, -2.6, 0.35), 0.08, 0.5, 0.4, DARK, "SmoothPlastic")
		end
		p:block(0.6, 3.5, -0.2, 2.6, 3.6, 0.2, rgb(240, 158, 120), "Fabric")
		p:block(0.6, 2.2, 0.2, 2.6, 3.6, 0.3, rgb(240, 158, 120), "Fabric")
	end)
end

-- A rowing boat: a hull with a pointed bow, its sides capped with a rail, boards inside, two
-- seats across it and a pair of oars shipped.
M.rowboat = function(r: R)
	parts(r, function(p: R)
		p:block(-1.7, 0, -2.6, 1.7, 0.75, 4.2, BLUE, "SmoothPlastic")
		for _, sx in { -1, 1 } do
			p:block(sx * 1.7 - 0.3, 0.3, -2.6, sx * 1.7 + 0.3, 1.25, 4.4, BLUE, "SmoothPlastic")
		end
		p:block(-2, 0.3, 4.1, 2, 1.25, 4.5, BLUE, "SmoothPlastic")
		p:boxAt(CFrame.new(0, 0.62, -2.6) * CFrame.Angles(0, math.pi / 4, 0), 2.8, 1.25, 2.8, BLUE, "SmoothPlastic")
		for _, sx in { -1, 1 } do
			p:block(sx * 1.7 - 0.34, 1.25, -2.2, sx * 1.7 + 0.34, 1.37, 4.44, WHITE, "SmoothPlastic")
		end
		p:block(-2.04, 1.25, 4.1, 2.04, 1.37, 4.54, WHITE, "SmoothPlastic")
	end, true)
	parts(r, function(p: R)
		p:block(-1.4, 0.75, -2.4, 1.4, 0.85, 4.1, WOOD, "Wood")
		p:boxAt(CFrame.new(0, 1.3, -2.5) * CFrame.Angles(0, math.pi / 4, 0), 1.9, 0.12, 1.9, WOOD, "Wood")
		for _, z in { -0.4, 2.6 } do
			p:block(-1.4, 0.95, z - 0.35, 1.4, 1.08, z + 0.35, WOOD_DARK, "Wood")
		end
		for _, sx in { -1, 1 } do
			p:beam(Vector3.new(sx * 1.2, 1.15, -1.8), Vector3.new(sx * 0.6, 1.0, 3.8), 0.14, 0.14, WOOD, "Wood")
		end
	end)
end

-- A volleyball net on the sand: posts on plates, the net as strings between a top band and a
-- bottom cord, a marker rod at each end, the court marked out and a ball.
M.volleyNet = function(r: R)
	parts(r, function(p: R)
		for _, x in { -9, 9 } do
			p:block(x - 0.5, 0, -0.5, x + 0.5, 0.2, 0.5, DARK, "Metal")
			p:cyl(x, 3.6, 0, 7.2, 0.5, "y", WHITE, "Metal")
			p:cyl(x, 7.3, 0, 0.2, 0.6, "y", DARK, "Metal")
		end
	end, true)
	parts(r, function(p: R)
		p:block(-8.75, 6.82, -0.1, 8.75, 7.12, 0.1, WHITE, "Fabric")
		p:block(-8.75, 3.6, -0.04, 8.75, 3.66, 0.04, WHITE, "Fabric")
		for k = 1, 3 do
			local y = 3.6 + k * 0.82
			p:block(-8.75, y - 0.02, -0.02, 8.75, y + 0.02, 0.02, WHITE, "Fabric")
		end
		for k = 0, 8 do
			local x = -8 + k * 2
			p:block(x - 0.02, 3.66, -0.02, x + 0.02, 6.82, 0.02, WHITE, "Fabric")
		end
		for _, x in { -7.8, 7.8 } do
			p:block(x - 0.05, 3.6, -0.14, x + 0.05, 8.2, -0.06, RED, "Fabric")
		end
		for _, z in { -14, 14 } do
			p:block(-9, -0.1, z - 0.15, 9, 0.13, z + 0.15, BLUE, "Fabric")
		end
		for _, x in { -9, 9 } do
			p:block(x - 0.15, -0.1, -13.85, x + 0.15, 0.13, 13.85, BLUE, "Fabric")
		end
		ball(p, 4, 1, 6, 2)
	end)
end

-- Driftwood on the sand: a bleached branch with its stubs, a shell, a starfish and seaweed.
M.driftwood = function(r: R)
	local pale = rgb(196, 176, 150)
	parts(r, function(p: R)
		p:boxAt(CFrame.new(0, 0.5, 0) * CFrame.Angles(0, 0.5, 0.05), 7, 0.9, 1, pale, "Wood")
		p:boxAt(CFrame.new(1.6, 0.9, 1.2) * CFrame.Angles(0.2, -0.7, 0.4), 3, 0.5, 0.5, rgb(180, 160, 136), "Wood")
		p:boxAt(CFrame.new(-1.4, 0.8, -0.2) * CFrame.Angles(0, 1.6, 0.6), 1.6, 0.35, 0.35, rgb(180, 160, 136), "Wood")
		p:lump(CFrame.new(-3.1, 0.5, -1.7) * CFrame.Angles(0, 0.5, 0), 1.2, 0.9, 1.1, pale, "Wood")
	end, true)
	parts(r, function(p: R)
		for k = 0, 4 do
			local a = k * math.pi * 2 / 5
			p:boxAt(
				CFrame.new(2.1 + math.cos(a) * 0.3, 0.04, -1.6 + math.sin(a) * 0.3) * CFrame.Angles(0, -a, 0),
				0.7,
				0.08,
				0.22,
				rgb(236, 150, 110),
				"SmoothPlastic"
			)
		end
		p:cone(-2.6, 0.22, 1.2, 0.44, 0.9, PINK, "SmoothPlastic")
		p:lump(
			CFrame.new(0.6, 0.12, -1.1) * CFrame.Angles(0, 0.4, 0),
			1.6,
			0.24,
			0.7,
			rgb(80, 120, 84),
			"SmoothPlastic"
		)
	end)
end

-- A buoy bobbing out in the bay: a float with a dark collar at the water, red with a white
-- band, a frame of legs up to a lamp with a cap.
M.buoy = function(r: R)
	parts(r, function(p: R)
		p:cyl(0, 0.4, 0, 2.4, 3.6, "y", RED, "SmoothPlastic")
		p:cyl(0, 0, 0, 0.5, 3.9, "y", DARK, "SmoothPlastic")
		p:cyl(0, 1.2, 0, 0.5, 3.64, "y", WHITE, "SmoothPlastic")
		p:cyl(0, 1.75, 0, 0.3, 3.2, "y", shade(RED, 0.85), "SmoothPlastic")
		for k = 0, 3 do
			local a = k * math.pi / 2 + math.pi / 4
			p:beam(
				Vector3.new(math.cos(a) * 1.2, 1.9, math.sin(a) * 1.2),
				Vector3.new(math.cos(a) * 0.45, 4.9, math.sin(a) * 0.45),
				0.16,
				0.16,
				DARK,
				"Metal"
			)
		end
		p:block(-0.75, 3.4, -0.75, 0.75, 3.52, 0.75, DARK, "Metal")
		p:cyl(0, 4.95, 0, 0.14, 1.3, "y", DARK, "Metal")
		p:cone(0, 6.35, 0, 0.4, 0.8, DARK, "Metal")
	end, true)
	r:glow(r:ball(0, 5.6, 0, 1, rgb(255, 120, 100), "SmoothPlastic"), 12, 1, rgb(255, 120, 100))
end

-- A sailing boat at anchor: a hull with a pointed bow, a stripe and a deck, a cabin with
-- portholes and a hatch, a mast with a spreader, a boom and two sails, rails, a tiller and a flag.
local function sailboat(r: R, hull: Color3, sail: Color3)
	r:block(-3, -0.6, -8, 3, 2, 8, hull, "SmoothPlastic")
	r:wedge(CFrame.new(0, 0.7, -10.5), 6, 2.6, 5, hull, "SmoothPlastic")
	r:block(-2.4, 2, -7.4, 2.4, 2.3, 7.4, WOOD, "WoodPlanks")
	parts(r, function(p: R)
		p:block(-3.04, 1.2, -8, 3.04, 1.5, 8.04, shade(hull, 0.72), "SmoothPlastic")
		p:block(-1.6, 2.3, 1, 1.6, 4.2, 5.4, WHITE, "SmoothPlastic")
		p:block(-1.75, 4.2, 0.85, 1.75, 4.45, 5.55, shade(WHITE, 0.9), "SmoothPlastic")
		for _, sx in { -1, 1 } do
			for _, z in { 2.2, 4.2 } do
				p:cyl(sx * 1.62, 3.4, z, 0.06, 0.5, "x", rgb(60, 80, 110), "SmoothPlastic")
			end
		end
		p:block(-0.6, 2.3, 0.94, 0.6, 3.8, 1, rgb(110, 84, 62), "Wood")
		p:cyl(0, 12, -1, 20, 0.5, "y", WOOD_DARK, "Wood")
		p:block(-1.8, 15, -1.08, 1.8, 15.16, -0.92, WOOD_DARK, "Wood")
		p:block(-0.16, 4.5, -1, 0.16, 4.75, 6.6, WOOD_DARK, "Wood")
		p:beam(Vector3.new(0, 3.1, 7.27), Vector3.new(0, 3.3, 5.8), 0.1, 0.1, WOOD_DARK, "Wood")
		for _, sx in { -1, 1 } do
			for _, z in { -6.5, -1, 4, 7.3 } do
				p:block(sx * 2.7 - 0.05, 2.3, z - 0.05, sx * 2.7 + 0.05, 3.4, z + 0.05, METAL, "Metal")
			end
			p:block(sx * 2.7 - 0.05, 3.35, -6.5, sx * 2.7 + 0.05, 3.45, 7.3, METAL, "Metal")
		end
		p:beam(Vector3.new(0, 2.6, -11.6), Vector3.new(0, 20.9, -1), 0.05, 0.05, METAL, "Metal")
	end, true)
	r:wedge(CFrame.new(0, 12.5, 3.6) * CFrame.Angles(0, 0, 0), 0.2, 17, 8.4, sail, "Fabric")
	r:wedge(CFrame.new(0, 10, -4.4) * CFrame.Angles(0, math.pi, 0), 0.2, 12, 6, shade(sail, 0.94), "Fabric")
	r:block(-0.05, 21.4, -1, 0.05, 22.6, 1, RED, "Fabric")
end

M.sailboat = function(r: R)
	sailboat(r, WHITE, WHITE)
end

M.sailboat2 = function(r: R)
	sailboat(r, rgb(84, 116, 170), rgb(255, 236, 200))
end

-- Rocks breaking the surface, with weed and barnacles at the water and a gull on the tallest.
M.seaRocks = function(r: R)
	parts(r, function(p: R)
		p:lump(CFrame.new(0, 0.6, 0) * CFrame.Angles(0.15, 0.6, 0.1), 10, 6.6, 8.6, ROCK, "Slate")
		p:lump(CFrame.new(6, -0.4, 3) * CFrame.Angles(-0.2, 0.2, 0.3), 6.6, 4.4, 5.4, shade(ROCK, 0.9), "Slate")
		p:lump(CFrame.new(-5, -0.6, -4) * CFrame.Angles(0.2, 1.2, -0.2), 5.4, 4, 4.8, shade(ROCK, 1.1), "Slate")
		p:lump(CFrame.new(-3.6, -0.2, 3.8) * CFrame.Angles(0, 0.5, 0), 2.4, 1.6, 2, shade(ROCK, 0.96), "Slate")
	end, true)
	parts(r, function(p: R)
		for k = 0, 3 do
			local a = k * 1.4
			p:lump(
				CFrame.new(math.cos(a) * 4.4, 0.15, math.sin(a) * 3.8) * CFrame.Angles(0, -a, 0),
				1.8,
				0.4,
				0.9,
				if k % 2 == 0 then rgb(70, 104, 80) else rgb(214, 208, 190),
				"SmoothPlastic"
			)
		end
		-- the gull: a body, a head with a yellow beak, grey wings folded, a dark tail and legs
		p:block(0.3, 3.5, 0.1, 0.5, 3.9, 0.3, rgb(236, 180, 80), "SmoothPlastic")
		p:lump(CFrame.new(0.4, 4.2, 0.2), 1.3, 0.75, 0.75, WHITE, "SmoothPlastic")
		p:ball(0.95, 4.65, 0.2, 0.6, WHITE, "SmoothPlastic")
		p:block(1.2, 4.58, 0.15, 1.5, 4.68, 0.25, rgb(236, 180, 80), "SmoothPlastic")
		for _, sz in { -1, 1 } do
			p:lump(CFrame.new(0.2, 4.35, 0.2 + sz * 0.33), 1.2, 0.36, 0.2, rgb(170, 176, 190), "SmoothPlastic")
		end
		p:boxAt(
			CFrame.new(-0.4, 4.35, 0.2) * CFrame.Angles(0, 0, 0.3),
			0.5,
			0.12,
			0.36,
			rgb(70, 74, 86),
			"SmoothPlastic"
		)
	end)
end

function DetailModels.prims(name: string): { any }?
	local build = M[name]
	if not build then
		return nil
	end
	local r = Recipe.new(WHITE, WHITE)
	build(r)
	return r.prims
end

return DetailModels
