--!strict
-- More for the garden, all in the garden look (Catalog.Styles). First paths to lay across a
-- lawn: each has "path" in its id, so Build mode's Paths tab lists it beside the floors, and the
-- squares are four studs a side so they butt up edge to edge. Then what a gardener keeps: a cold
-- frame, a little greenhouse, a raised bed, a pond, a beehive, seats under a pergola, a potting
-- bench. c1 is the main colour and c2 the second, as everywhere.

local Recipe = require(script.Parent.Parent.Recipe)
local Colors = require(script.Parent.Parent.Parent.Util.Colors)
local K = require(script.Parent.Parent.RecipeKit) -- (water that moves: K.surface, K.roundSurface)

local C = Recipe.Colors

type R = Recipe.Recipe

local STYLE = "garden"

local function shade(c: Color3, k: number): Color3
	return Colors.shade(c, k)
end

-- A number from 0 to 1, always the same for the same i and j (to scatter stones and pebbles).
local function hash(i: number, j: number): number
	local v = math.sin(i * 12.9898 + j * 78.233) * 43758.5453
	return v - math.floor(v)
end

-- Glass, of any shapes drawn for it (a pane at an angle, a gable's triangle).
local function glaze(list: { Recipe.Prim })
	for _, p in list do
		p.color = C.Glass
		p.mat = "Glass"
		p.transp = 0.55
	end
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
local function rail(r: R, pts: { Vector3 }, w: number, h: number, color: Color3, mat: string)
	for i = 1, #pts - 1 do
		local a, b = pts[i], pts[i + 1]
		local d = (b - a).Unit * 0.06
		r:beam(if i > 1 then a - d else a, if i < #pts - 1 then b + d else b, w, h, color, mat)
	end
end

local AMBER = Color3.fromRGB(200, 132, 62)
local CORAL = Color3.fromRGB(224, 133, 102)
local LILAC = Color3.fromRGB(156, 134, 184)
local CANE = Color3.fromRGB(196, 164, 110)
local CLAY = Color3.fromRGB(184, 118, 90)
local TOMATO = Color3.fromRGB(208, 96, 78)

-- One flower drawn on q (a piece's recipe): a stem from y0 up to its head at h, a leaf part way
-- up, the head (a flat cup of petals, tipped a little) and the middle on top of it.
local function bloom(q: R, x: number, z: number, y0: number, h: number, head: Color3, turn: number)
	q:block(x - 0.035, y0, z - 0.035, x + 0.035, h, z + 0.035, C.DarkLeaf, "SmoothPlastic")
	local side = if math.floor(turn * 3) % 2 == 0 then 1 else -1
	q:lump(
		CFrame.new(x + side * 0.12, y0 + (h - y0) * 0.5, z) * CFrame.Angles(0, turn, side * -0.6),
		0.32,
		0.09,
		0.16,
		C.Leaf,
		"SmoothPlastic"
	)
	q:lump(CFrame.new(x, h, z) * CFrame.Angles(0.2, turn, 0), 0.4, 0.14, 0.4, head, "SmoothPlastic")
	q:ball(x, h + 0.08, z + 0.02, 0.14, if head == C.Yellow then AMBER else C.Yellow, "SmoothPlastic")
end

-- A trailing stem hanging over an edge at (x, y, z), its leaves ending in a little tuft.
local function trail(q: R, x: number, y: number, z: number, len: number, lean: number)
	q:lump(CFrame.new(x, y - len / 2, z) * CFrame.Angles(lean, 0, 0.3), 0.2, len + 0.1, 0.16, C.Leaf, "Grass")
	q:lump(
		CFrame.new(x + 0.06, y - len, z + lean * 0.2) * CFrame.Angles(0, x * 3, 0),
		0.24,
		0.13,
		0.2,
		C.DarkLeaf,
		"Grass"
	)
end

-- A tuft of grass on q (a piece in Grass) at (x, z), standing on y0: three blades leaning apart.
local function tuft(q: R, x: number, z: number, y0: number, turn: number, h: number?)
	local hh = h or 0.22
	for k = 0, 2 do
		q:add({
			shape = "Cone",
			cf = CFrame.new(x + (k - 1) * 0.06, y0 + (hh - k * 0.03) / 2, z + (k % 2) * 0.04)
				* CFrame.Angles(0, turn, (k - 1) * 0.45),
			size = Vector3.new(0.08, hh - k * 0.03, 0.08),
			color = if k == 1 then C.Leaf else C.DarkLeaf,
			mat = "Grass",
		})
	end
end

-- A small bird on q (a piece in SmoothPlastic) standing at (x, y, z) and looking along -x or +x
-- (dir): a body, a paler breast, a head, a beak, a tail and two eyes. Its beak is a plain box, so
-- it can start the piece.
local function bird(q: R, x: number, y: number, z: number, dir: number, back: Color3, breast: Color3)
	q:box(x + dir * 0.235, y + 0.27, z, 0.07, 0.035, 0.045, AMBER, "SmoothPlastic")
	q:lump(CFrame.new(x, y + 0.14, z), 0.34, 0.2, 0.22, back, "SmoothPlastic")
	q:lump(CFrame.new(x + dir * 0.08, y + 0.11, z), 0.2, 0.16, 0.18, breast, "SmoothPlastic")
	q:ball(x + dir * 0.14, y + 0.27, z, 0.18, back, "SmoothPlastic")
	q:boxAt(
		CFrame.new(x - dir * 0.22, y + 0.2, z) * CFrame.Angles(0, 0, dir * -0.5),
		0.18,
		0.035,
		0.1,
		shade(back, 0.8),
		"SmoothPlastic"
	)
	for _, sz in { -1, 1 } do
		q:ball(x + dir * 0.19, y + 0.3, z + sz * 0.065, 0.045, C.Black, "SmoothPlastic")
		q:box(x + dir * 0.02, y + 0.03, z + sz * 0.05, 0.025, 0.06, 0.025, AMBER, "SmoothPlastic")
	end
end

-- One catalog entry (Build/Catalog explains the fields).
type Item = {
	id: string,
	name: string,
	cat: string,
	style: string,
	price: number,
	place: string,
	size: Vector3,
	c1: string,
	c2: string?,
	tags: { string }?,
	surface: number?,
	lively: boolean?, -- moves or gives off an effect (Build/Lively): a pond's water drifts
	build: (r: R) -> (),
	gives: string?, -- holding E gives the player something (Data/Items.Sources)
}

local items: { Item } = {
	-- Paths ---------------------------------------------------------------------------------------
	{
		id = "path_gravel",
		name = "Gravel path",
		cat = "garden",
		style = STYLE,
		price = 15,
		place = "ground",
		size = Vector3.new(4, 0.3, 4),
		c1 = "C9BFAE",
		c2 = "9A9388",
		build = function(r: R)
			-- a square of raked gravel (c1) that meets the next square edge to edge, bigger
			-- pebbles (c2) pressed into it and a weed or two coming up
			r:block(-2, 0, -2, 2, 0.1, 2, r.c1, "Pebble")
			r:piece(function(q: R)
				q:box(0, 0.05, 0, 0.1, 0.04, 0.1, r.c2, "Slate")
				for i = 1, 22 do
					local x = -1.82 + hash(i, 1) * 3.64
					local z = -1.82 + hash(i, 2) * 3.64
					local s = 0.14 + hash(i, 3) * 0.16
					local k = hash(i, 4)
					local tone = if k < 0.35 then r.c2 elseif k < 0.7 then shade(r.c2, 1.14) else shade(r.c2, 0.84)
					q:lump(CFrame.new(x, 0.1, z) * CFrame.Angles(0, k * 6, 0), s, s * 0.55, s * 0.8, tone, "Slate")
				end
			end)
			r:piece(function(q: R)
				q:box(1.3, 0.12, -1.5, 0.08, 0.04, 0.08, C.DarkLeaf, "Grass")
				tuft(q, 1.3, -1.5, 0.1, 0.4)
				tuft(q, -1.55, 1.2, 0.1, 1.9)
				tuft(q, -0.4, -1.72, 0.1, 2.7, 0.16)
			end)
		end,
	},
	{
		id = "path_brick",
		name = "Brick path",
		cat = "garden",
		style = STYLE,
		price = 25,
		place = "ground",
		size = Vector3.new(4, 0.3, 4),
		c1 = "B87A62",
		c2 = "CFC6B6",
		build = function(r: R)
			-- clay pavers (c1) laid in a basket weave on mortar (c2): a pair of bricks to each
			-- square, every square turned across its neighbours, the bricks in a few tones
			r:block(-2, 0, -2, 2, 0.1, 2, r.c2, "Concrete")
			local tones = {
				r.c1,
				shade(r.c1, 0.9),
				shade(r.c1, 1.08),
				Colors.mix(r.c1, Color3.fromRGB(140, 104, 88), 0.35),
			}
			for half = 0, 1 do
				r:piece(function(q: R)
					for i = 0, 3 do
						for j = half * 2, half * 2 + 1 do
							local cx, cz = -1.5 + i, -1.5 + j
							for b = -1, 1, 2 do
								local tone = tones[math.floor(hash(i * 4 + j, b) * 4) + 1]
								if (i + j) % 2 == 0 then
									q:box(cx, 0.12, cz + b * 0.25, 0.92, 0.12, 0.42, tone, "Concrete")
								else
									q:box(cx + b * 0.25, 0.12, cz, 0.42, 0.12, 0.92, tone, "Concrete")
								end
							end
						end
					end
				end)
			end
		end,
	},
	{
		id = "path_crazy",
		name = "Crazy paving",
		cat = "garden",
		style = STYLE,
		price = 25,
		place = "ground",
		size = Vector3.new(4, 0.3, 4),
		c1 = "BAB3A7",
		c2 = "8F887C",
		build = function(r: R)
			-- odd shaped flat stones (c1) fitted together on grout (c2), moss in a few joints: a
			-- grid of corners pushed about, each stone drawn a little inside its four
			r:block(-2, 0, -2, 2, 0.08, 2, r.c2, "Concrete")
			local pts: { [number]: { [number]: Vector3 } } = {}
			for i = 0, 4 do
				pts[i] = {}
				for j = 0, 4 do
					local dx = if i > 0 and i < 4 then (hash(i, j) - 0.5) * 0.56 else 0
					local dz = if j > 0 and j < 4 then (hash(j + 7, i + 3) - 0.5) * 0.56 else 0
					pts[i][j] = Vector3.new(-2 + i + dx, 0.1, -2 + j + dz)
				end
			end
			type Stone = { p: { Vector3 }, n: number }
			local stones: { Stone } = {}
			for i = 0, 3 do
				for j = 0, 3 do
					table.insert(stones, {
						p = { pts[i][j], pts[i + 1][j], pts[i + 1][j + 1], pts[i][j + 1] },
						n = i * 4 + j,
					})
				end
			end
			for g = 0, 2 do
				r:piece(function(q: R)
					for n = g * 6 + 1, math.min(g * 6 + 6, #stones) do
						local s = stones[n]
						local m = (s.p[1] + s.p[2] + s.p[3] + s.p[4]) / 4
						local k = hash(s.n, 9)
						local tone = if k < 0.4 then r.c1 elseif k < 0.7 then shade(r.c1, 1.08) else shade(r.c1, 0.9)
						local c = {}
						for e = 1, 4 do
							c[e] = s.p[e] + (m - s.p[e]).Unit * 0.08
						end
						if n == g * 6 + 1 then
							q:box(m.X, 0.06, m.Z, 0.1, 0.04, 0.1, tone, "Slate")
						end
						q:quad(c[1], c[2], c[3], c[4], 0.12 + hash(s.n, 5) * 0.03, tone, "Slate")
					end
				end)
			end
			r:piece(function(q: R)
				q:box(pts[1][1].X, 0.1, pts[1][1].Z, 0.06, 0.04, 0.06, C.DarkLeaf, "Grass")
				for _, ij in { { 1, 1 }, { 3, 2 }, { 2, 3 }, { 1, 3 } } do
					local p = pts[ij[1]][ij[2]]
					q:lump(
						CFrame.new(p.X, 0.1, p.Z) * CFrame.Angles(0, ij[1] + ij[2], 0),
						0.3,
						0.07,
						0.16,
						C.DarkLeaf,
						"Grass"
					)
				end
				tuft(q, pts[3][2].X, pts[3][2].Z, 0.08, 1.2, 0.16)
			end)
		end,
	},
	{
		id = "path_boardwalk",
		name = "Boardwalk",
		cat = "garden",
		style = STYLE,
		price = 30,
		place = "ground",
		size = Vector3.new(4, 0.4, 4),
		c1 = "A98768",
		c2 = "6F5A48",
		build = function(r: R)
			-- planks (c1) laid across three bearers (c2) a little off the ground, a nail where
			-- each plank crosses a bearer; the squares butt up end to end into a walk
			for _, x in { -1.55, 0, 1.55 } do
				r:block(x - 0.15, 0, -2, x + 0.15, 0.2, 2, r.c2, "Wood")
			end
			r:piece(function(q: R)
				for k = 0, 7 do
					local z = -1.75 + k * 0.5
					local tone = if k % 3 == 0 then shade(r.c1, 0.93) elseif k % 3 == 1 then r.c1 else shade(r.c1, 1.06)
					q:block(-2, 0.2, z - 0.23, 2, 0.32, z + 0.23, tone, "Wood")
				end
			end, true)
			r:piece(function(q: R)
				for k = 0, 7 do
					for _, x in { -1.55, 0, 1.55 } do
						q:box(x, 0.335, -1.75 + k * 0.5, 0.07, 0.03, 0.07, C.DarkMetal, "Metal")
					end
				end
			end)
		end,
	},
	{
		id = "path_curve",
		name = "Curved gravel path",
		cat = "garden",
		style = STYLE,
		price = 30,
		place = "ground",
		size = Vector3.new(6, 0.3, 6),
		c1 = "C9BFAE",
		c2 = "A8A399",
		build = function(r: R)
			-- gravel (c1) four studs wide turning a corner, from the front edge round to the
			-- right one, edged both sides with rounded setts (c2): lay gravel squares on from
			-- either end
			local function at(a: number, rad: number, y: number): Vector3
				return Vector3.new(3 + math.cos(a) * rad, y, 3 + math.sin(a) * rad)
			end
			local n = 6
			r:piece(function(q: R)
				local m = at(math.pi * 1.25, 4, 0.05)
				q:box(m.X, 0.05, m.Z, 0.2, 0.1, 0.2, r.c1, "Pebble")
				for i = 0, n - 1 do
					local a1 = math.pi + i / n * math.pi / 2
					local a2 = math.pi + (i + 1) / n * math.pi / 2
					q:quad(
						at(a1, 2.2, 0.05),
						at(a1, 5.8, 0.05),
						at(a2, 5.8, 0.05),
						at(a2, 2.2, 0.05),
						0.1,
						r.c1,
						"Pebble"
					)
				end
			end)
			r:piece(function(q: R)
				local m = at(math.pi * 1.25, 2.1, 0)
				q:box(m.X, 0.05, m.Z, 0.1, 0.06, 0.1, r.c2, "Slate")
				for _, edge in { { 2.1, 7 }, { 5.88, 18 } } do
					local rad, count = edge[1], edge[2]
					for i = 0, count - 1 do
						local a = math.pi + (i + 0.5) / count * math.pi / 2
						local k = hash(i, rad)
						q:lump(
							CFrame.new(at(a, rad, 0.1)) * CFrame.Angles(0, -(a + math.pi / 2) + (k - 0.5) * 0.3, 0),
							rad * math.pi / 2 / count + 0.06,
							0.2 + k * 0.05,
							0.24,
							if k < 0.5 then r.c2 else shade(r.c2, 1.1),
							"Slate"
						)
					end
				end
			end)
			r:piece(function(q: R)
				local m = at(math.pi * 1.1, 3.5, 0)
				q:box(m.X, 0.06, m.Z, 0.1, 0.04, 0.1, shade(r.c2, 0.9), "Slate")
				for i = 1, 10 do
					local a = math.pi + hash(i, 21) * math.pi / 2
					local s = 0.14 + hash(i, 23) * 0.12
					q:lump(
						CFrame.new(at(a, 2.5 + hash(i, 22) * 3.0, 0.1)) * CFrame.Angles(0, i, 0),
						s,
						s * 0.5,
						s * 0.8,
						if i % 2 == 0 then shade(r.c2, 0.9) else shade(r.c2, 1.12),
						"Slate"
					)
				end
			end)
		end,
	},
	{
		id = "path_logs",
		name = "Log slices",
		cat = "garden",
		style = STYLE,
		price = 15,
		place = "ground",
		size = Vector3.new(2, 0.4, 4),
		c1 = "D2B48A",
		c2 = "6E5038",
		build = function(r: R)
			-- three rounds sawn off a log and set in the grass to step on: bark (c2) round the
			-- side, the pale cut face (c1) on top with a ring, the heart and a split
			for i, p in { { -0.22, -1.3, 1.25 }, { 0.28, 0.05, 1.0 }, { -0.14, 1.35, 1.15 } } do
				local x, z, d = p[1], p[2], p[3]
				r:cyl(x, 0.11, z, 0.22, d, "y", r.c2, "Wood")
				r:cyl(x, 0.235, z, 0.03, d - 0.12, "y", r.c1, "Wood")
				r:piece(function(q: R)
					q:box(x, 0.295, z, 0.12, 0.03, 0.12, shade(r.c1, 0.72), "Wood")
					q:cyl(x, 0.265, z, 0.03, d * 0.56, "y", shade(r.c1, 0.9), "Wood")
					local a = i * 2.1
					local mid = d * 0.38
					q:boxAt(
						CFrame.new(x + math.cos(a) * mid, 0.265, z + math.sin(a) * mid) * CFrame.Angles(0, -a, 0),
						d * 0.14,
						0.03,
						0.035,
						shade(r.c1, 0.66),
						"Wood"
					)
				end)
			end
			r:piece(function(q: R)
				q:box(0.68, 0.02, -0.6, 0.08, 0.04, 0.08, C.DarkLeaf, "Grass")
				tuft(q, 0.68, -0.6, 0, 0.5)
				tuft(q, -0.72, 0.62, 0, 2.2)
				tuft(q, 0.6, 1.88, 0, 1.4, 0.18)
				tuft(q, -0.75, -0.2, 0, 2.9, 0.16)
			end)
		end,
	},
	{
		id = "path_edging",
		name = "Path edging",
		cat = "garden",
		style = STYLE,
		price = 10,
		place = "ground",
		size = Vector3.new(4, 0.4, 0.6),
		c1 = "B4B0A8",
		c2 = "7FA05F",
		build = function(r: R)
			-- a row of rounded edging stones (c1) bedded in a strip of earth, moss (c2) on a few
			-- and grass coming up between: lay it along the side of a path
			r:block(-2, 0, -0.27, 2, 0.04, 0.27, C.Soil, "Sand")
			r:piece(function(q: R)
				q:box(0, 0.08, 0, 0.1, 0.04, 0.1, r.c1, "Slate")
				for i = 0, 9 do
					local k = hash(i, 31)
					q:lump(
						CFrame.new(-1.8 + i * 0.4, 0.13, (k - 0.5) * 0.06)
							* CFrame.Angles(0, (k - 0.5) * 0.5, (hash(i, 32) - 0.5) * 0.2),
						0.44,
						0.3 + k * 0.06,
						0.38,
						if k < 0.4 then r.c1 elseif k < 0.75 then shade(r.c1, 1.08) else shade(r.c1, 0.9),
						"Slate"
					)
				end
			end)
			r:piece(function(q: R)
				q:box(-1.6, 0.06, 0.2, 0.08, 0.04, 0.08, C.DarkLeaf, "Grass")
				for _, i in { 1, 4, 8 } do
					q:lump(CFrame.new(-1.8 + i * 0.4, 0.29, 0) * CFrame.Angles(0, i, 0), 0.26, 0.06, 0.2, r.c2, "Grass")
				end
				for _, t in { { -1.6, 0.2 }, { -0.4, -0.2 }, { 0.6, 0.2 }, { 1.4, -0.21 } } do
					tuft(q, t[1], t[2], 0.04, t[1] * 2)
				end
			end)
		end,
	},
	{
		id = "path_arch",
		name = "Rose arch",
		cat = "garden",
		style = STYLE,
		price = 90,
		place = "ground",
		size = Vector3.new(5.4, 8.2, 1.6),
		c1 = "F2EEE6",
		c2 = "E08A9A",
		tags = { "plant" },
		build = function(r: R)
			-- an arch to walk a path under: two ladder sides of square posts and rungs with a
			-- zigzag up them and a round top of two arcs tied by slats, painted (c1), and a rose
			-- (c2 the flowers) climbing one side and over
			local w, top = 2.3, 5.4
			for _, sx in { -1, 1 } do
				for _, sz in { -0.6, 0.6 } do
					r:block(sx * w - 0.09, 0, sz - 0.09, sx * w + 0.09, top, sz + 0.09, r.c1, "Wood")
				end
			end
			r:piece(function(q: R)
				local ys = { 0.5, 1.5, 2.5, 3.5, 4.5, 5.3 }
				for _, sx in { -1, 1 } do
					local x = sx * w
					for i, y in ys do
						q:block(x - 0.05, y - 0.04, -0.51, x + 0.05, y + 0.04, 0.51, r.c1, "Wood")
						if i < #ys then
							local za = if i % 2 == 1 then -0.48 else 0.48
							q:beam(Vector3.new(x, y, za), Vector3.new(x, ys[i + 1], -za), 0.05, 0.06, r.c1, "Wood")
						end
					end
				end
			end)
			r:piece(function(q: R)
				local n = 8
				q:block(-0.05, top + w - 0.05, -0.7, 0.05, top + w + 0.05, 0.7, r.c1, "Wood")
				for _, sz in { -0.6, 0.6 } do
					for i = 0, n - 1 do
						local a1, a2 = i / n * math.pi, (i + 1) / n * math.pi
						local p1 = Vector3.new(math.cos(a1) * w, top + math.sin(a1) * w, sz)
						local p2 = Vector3.new(math.cos(a2) * w, top + math.sin(a2) * w, sz)
						local d = (p2 - p1).Unit * 0.05
						q:beam(p1 - d, p2 + d, 0.18, 0.16, r.c1, "Wood")
					end
				end
				for i = 1, n - 1 do
					if i ~= n / 2 then
						local a = i / n * math.pi
						q:boxAt(
							CFrame.new(math.cos(a) * w, top + math.sin(a) * w, 0) * CFrame.Angles(0, 0, a),
							0.1,
							0.1,
							1.4,
							r.c1,
							"Wood"
						)
					end
				end
			end)
			-- the rose: its stem up the left side, leaves along it and over the top, flowers
			r:piece(function(q: R)
				q:block(-2.08, 0, 0.66, -1.98, 0.6, 0.76, C.Bark, "Wood")
				local stem = {
					Vector3.new(-2.03, 0.5, 0.71),
					Vector3.new(-2.1, 2.2, 0.74),
					Vector3.new(-1.98, 4.0, 0.7),
					Vector3.new(-2.15, 5.5, 0.66),
					Vector3.new(-1.6, 7.0, 0.62),
					Vector3.new(-0.4, 7.75, 0.6),
					Vector3.new(0.9, 7.6, 0.62),
				}
				for i = 1, #stem - 1 do
					q:beam(stem[i], stem[i + 1], 0.1, 0.1, C.Bark, "Wood")
				end
			end)
			r:piece(function(q: R)
				q:box(-2.3, 0.9, 0.62, 0.3, 0.3, 0.3, C.DarkLeaf, "Grass")
				local clumps = {
					{ -2.2, 1.0, 0.72, 0.6 },
					{ -2.45, 1.9, 0.5, 0.7 },
					{ -2.1, 2.7, 0.8, 0.65 },
					{ -2.4, 3.5, 0.45, 0.75 },
					{ -2.15, 4.3, 0.78, 0.7 },
					{ -2.35, 5.1, 0.4, 0.8 },
					{ -2.05, 5.8, 0.75, 0.7 },
					{ -1.75, 6.6, 0.4, 0.8 },
					{ -1.3, 7.2, 0.7, 0.75 },
					{ -0.6, 7.65, 0.35, 0.8 },
					{ 0.1, 7.8, 0.7, 0.7 },
					{ 0.8, 7.7, 0.35, 0.65 },
					{ 1.4, 7.35, 0.65, 0.6 },
					{ -2.5, 2.4, -0.4, 0.6 },
					{ -2.3, 4.6, -0.55, 0.65 },
					{ -1.0, 7.5, -0.5, 0.7 },
					{ 0.4, 7.85, -0.4, 0.6 },
				}
				for i, c in clumps do
					q:lump(
						CFrame.new(c[1], c[2], c[3]) * CFrame.Angles(0.3, i * 1.3, -0.2),
						c[4],
						c[4] * 0.7,
						c[4] * 0.8,
						if i % 3 == 0 then C.DarkLeaf elseif i % 3 == 1 then C.Leaf else shade(C.Leaf, 0.88),
						"Grass"
					)
				end
			end)
			r:piece(function(q: R)
				q:box(-2.05, 1.25, 0.98, 0.06, 0.06, 0.06, shade(r.c2, 0.8), "SmoothPlastic")
				local roses = {
					{ -2.05, 1.2, 0.95 },
					{ -2.55, 2.1, 0.7 },
					{ -1.95, 2.9, 1.0 },
					{ -2.55, 3.7, 0.62 },
					{ -1.9, 4.5, 1.0 },
					{ -2.5, 5.3, 0.6 },
					{ -1.85, 6.0, 0.95 },
					{ -1.45, 6.85, 0.62 },
					{ -1.0, 7.4, 0.95 },
					{ -0.3, 7.95, 0.6 },
					{ 0.35, 7.95, 0.92 },
					{ 1.1, 7.75, 0.55 },
					{ 1.6, 7.3, 0.85 },
					{ -2.6, 2.6, -0.55 },
					{ -2.45, 4.8, -0.75 },
					{ -0.8, 7.65, -0.75 },
					{ 0.6, 8.0, -0.55 },
				}
				for i, p in roses do
					local col = if i % 5 == 0 then C.White elseif i % 2 == 0 then shade(r.c2, 1.1) else r.c2
					q:lump(
						CFrame.new(p[1], p[2], p[3]) * CFrame.Angles(0.4, i, 0.2),
						0.32,
						0.24,
						0.32,
						col,
						"SmoothPlastic"
					)
				end
			end)
		end,
	},

	-- Growing ---------------------------------------------------------------------------------------
	{
		id = "cold_frame",
		name = "Cold frame",
		gives = "veg", -- holding E gives something (Data/Items.Sources)
		cat = "garden",
		style = STYLE,
		price = 70,
		place = "ground",
		size = Vector3.new(4, 3, 2.4),
		c1 = "A37E5A",
		c2 = "F0EDE4",
		tags = { "plant" },
		build = function(r: R)
			-- a low box of boards (c1), taller at the back, under two glazed lids in white frames
			-- (c2): the left one shut, the right one propped open on a stick. Inside, lettuces at
			-- the back and rows of seedlings coming up
			local lo, hi, d = 0.9, 1.5, 1.2
			local slope = (hi - lo) / (2 * d)
			local function lidY(z: number): number
				return hi - (z + d) * slope
			end
			r:block(-2, 0, d - 0.14, 2, lo, d, r.c1, "WoodPlanks")
			r:block(-2, 0, -d, 2, hi, -d + 0.14, r.c1, "WoodPlanks")
			for _, sx in { -1, 1 } do
				local zb, zf = -d + 0.14, d - 0.14
				r:block(sx * 1.86, 0, zb, sx * 2, lidY(zf), zf, r.c1, "WoodPlanks")
				r:ramp(sx * 1.86, lidY(zf), zb, sx * 2, lidY(zb), zf, false, r.c1, "WoodPlanks")
				for _, sz in { -1, 1 } do
					local h = if sz > 0 then lo - 0.05 else hi - 0.05
					r:block(sx * 1.83, 0, sz * 1.03, sx * 2.03, h, sz * 1.23, shade(r.c1, 0.85), "Wood")
				end
			end
			r:block(-1.86, 0, -d + 0.14, 1.86, 0.5, d - 0.14, C.Soil, "Sand")
			r:piece(function(q: R)
				q:box(0, 0.52, 0, 0.1, 0.04, 0.1, C.DarkLeaf, "Grass")
				for i = 0, 4 do
					local x = -1.4 + i * 0.7
					q:lump(CFrame.new(x, 0.66, -0.62) * CFrame.Angles(0, i, 0), 0.58, 0.32, 0.52, C.Leaf, "Grass")
					q:lump(
						CFrame.new(x + 0.02, 0.8, -0.6) * CFrame.Angles(0, i * 2, 0),
						0.32,
						0.24,
						0.3,
						Color3.fromRGB(168, 204, 122),
						"Grass"
					)
				end
				for row = 0, 1 do
					for i = 0, 5 do
						q:lump(
							CFrame.new(-1.45 + i * 0.58 + row * 0.2, 0.58, 0.12 + row * 0.5)
								* CFrame.Angles(0, i + row, 0),
							0.22,
							0.12,
							0.14,
							if (i + row) % 2 == 0 then C.Leaf else Color3.fromRGB(150, 196, 112),
							"Grass"
						)
					end
				end
			end)
			-- the lids: a frame of four bars with a glazing bar down the middle, the glass and a
			-- handle at the front; `frame` is the middle of the lid, its z down the slope
			local len = math.sqrt((2 * d) ^ 2 + (hi - lo) ^ 2)
			local tilt = math.atan2(hi - lo, 2 * d)
			local function lid(frame: CFrame)
				for _, sx in { -1, 1 } do
					r:boxAt(frame * CFrame.new(sx * 0.88, 0, 0), 0.16, 0.1, len, r.c2, "Wood")
				end
				for _, sz in { -1, 1 } do
					r:boxAt(frame * CFrame.new(0, 0, sz * (len / 2 - 0.08)), 1.6, 0.1, 0.16, r.c2, "Wood")
				end
				r:boxAt(frame, 0.08, 0.08, len - 0.3, r.c2, "Wood")
				local g = r:boxAt(frame, 1.6, 0.02, len - 0.3, C.Glass, "Glass")
				g.transp = 0.55
				r:boxAt(frame * CFrame.new(0, 0.04, len / 2 + 0.05), 0.4, 0.06, 0.1, C.DarkMetal, "Metal")
			end
			lid(CFrame.new(-0.98, (hi + lo) / 2, 0) * CFrame.Angles(tilt, 0, 0) * CFrame.new(0, 0.05, 0))
			local open = 0.85
			lid(CFrame.new(0.98, hi, -d) * CFrame.Angles(tilt - open, 0, 0) * CFrame.new(0, 0.05, len / 2))
			-- the stick holding it up
			local under = CFrame.new(0.98, hi, -d) * CFrame.Angles(tilt - open, 0, 0) * CFrame.new(0.55, 0, len - 0.35)
			r:beam(Vector3.new(1.53, lo, d - 0.07), under.Position, 0.08, 0.08, C.Bark, "Wood")
		end,
	},
	{
		id = "greenhouse_mini",
		name = "Little greenhouse",
		gives = "fruit", -- holding E gives something (Data/Items.Sources)
		cat = "garden",
		style = STYLE,
		price = 380,
		place = "ground",
		size = Vector3.new(5, 5, 3.6),
		c1 = "F0EEE8",
		c2 = "B07A62",
		tags = { "plant" },
		build = function(r: R)
			-- a glasshouse on a low brick wall (c2) with a sill, white glazing bars (c1) round the
			-- panes and up a pitched glass roof. Through the glass: a slatted bench of pots along
			-- the back and tomatoes up canes either side of the door
			local W, D, sill, eave, ridge = 2.4, 1.7, 1.0, 3.5, 4.7
			-- the dwarf wall (the door's gap in its front), the sill round its top, the floor
			r:block(-W, 0, -D, W, 0.9, -D + 0.3, r.c2, "Brick")
			for _, sx in { -1, 1 } do
				r:block(sx * W, 0, D - 0.3, sx * 0.75, 0.9, D, r.c2, "Brick")
				r:block(sx * W, 0, -D + 0.3, sx * (W - 0.3), 0.9, D - 0.3, r.c2, "Brick")
			end
			r:piece(function(q: R)
				q:block(-W - 0.05, 0.9, -D - 0.05, W + 0.05, sill, -D + 0.35, shade(r.c1, 0.94), "Wood")
				for _, sx in { -1, 1 } do
					q:block(sx * (W + 0.05), 0.9, D + 0.05, sx * 0.72, sill, D - 0.35, shade(r.c1, 0.94), "Wood")
					q:block(sx * (W + 0.05), 0.9, -D + 0.35, sx * (W - 0.35), sill, D - 0.35, shade(r.c1, 0.94), "Wood")
				end
			end)
			r:block(-W + 0.3, 0, -D + 0.3, W - 0.3, 0.06, D - 0.3, Color3.fromRGB(150, 146, 140), "Slate")
			r:block(-0.75, 0, D - 0.3, 0.75, 0.06, D, Color3.fromRGB(150, 146, 140), "Slate")
			-- the frame: posts, door jambs, eaves, the ridge, rafters and a bar halfway up
			r:piece(function(q: R)
				for _, z in { -D, D } do
					for _, x in { -W, -0.78, 0.78, W } do
						local y0 = if z > 0 and math.abs(x) < 1 then 0.06 else sill
						q:block(x - 0.06, y0, z - 0.06, x + 0.06, eave, z + 0.06, r.c1, "Wood")
					end
					q:block(-W - 0.06, eave, z - 0.07, W + 0.06, eave + 0.12, z + 0.07, r.c1, "Wood")
				end
				for _, x in { -W, W } do
					q:block(x - 0.06, sill, -0.06, x + 0.06, ridge, 0.06, r.c1, "Wood")
					q:block(x - 0.05, 2.3, -D, x + 0.05, 2.38, D, r.c1, "Wood")
				end
				q:block(-W - 0.06, ridge - 0.04, -0.08, W + 0.06, ridge + 0.1, 0.08, r.c1, "Wood")
				q:block(-W, 2.3, -D - 0.05, W, 2.38, -D + 0.05, r.c1, "Wood")
				for _, sx in { -1, 1 } do
					q:block(sx * W, 2.3, D - 0.05, sx * 0.84, 2.38, D + 0.05, r.c1, "Wood")
				end
				-- the door's frame and its handle
				q:block(-0.72, 0.06, D - 0.04, 0.72, 0.2, D + 0.04, r.c1, "Wood")
				q:block(-0.72, 1.95, D - 0.04, 0.72, 2.05, D + 0.04, r.c1, "Wood")
				q:block(-0.72, 3.0, D - 0.04, 0.72, 3.1, D + 0.04, r.c1, "Wood")
			end)
			r:piece(function(q: R)
				q:block(-0.2, ridge - 0.04, -0.08, 0.2, ridge + 0.1, 0.08, r.c1, "Wood")
				for _, x in { -W, -0.78, 0.78, W } do
					for _, sz in { -1, 1 } do
						q:beam(
							Vector3.new(x, eave + 0.1, sz * D),
							Vector3.new(x, ridge + 0.05, 0),
							0.1,
							0.1,
							r.c1,
							"Wood"
						)
					end
				end
			end)
			r:block(0.48, 1.85, D + 0.04, 0.56, 2.15, D + 0.1, C.DarkMetal, "Metal")
			-- the glass
			glaze({ r:block(-W + 0.06, sill, -D - 0.02, W - 0.06, eave, -D + 0.02, C.Glass, "Glass") })
			for _, sx in { -1, 1 } do
				glaze({ r:block(sx * (W - 0.06), sill, D - 0.02, sx * 0.84, eave, D + 0.02, C.Glass, "Glass") })
				glaze({ r:block(sx * (W - 0.02), sill, -D + 0.06, sx * (W + 0.02), eave, D - 0.06, C.Glass, "Glass") })
				glaze(
					r:tri(
						Vector3.new(sx * W, eave + 0.12, -D + 0.1),
						Vector3.new(sx * W, eave + 0.12, D - 0.1),
						Vector3.new(sx * W, ridge - 0.06, 0),
						0.04,
						C.Glass,
						"Glass"
					)
				)
				glaze(
					r:quad(
						Vector3.new(-W, eave + 0.14, sx * D),
						Vector3.new(W, eave + 0.14, sx * D),
						Vector3.new(W, ridge + 0.02, 0),
						Vector3.new(-W, ridge + 0.02, 0),
						0.04,
						C.Glass,
						"Glass"
					)
				)
			end
			glaze({ r:block(-0.66, 0.2, D - 0.01, 0.66, 3.0, D + 0.01, C.Glass, "Glass") })
			-- inside: the bench along the back with pots of seedlings on it
			r:piece(function(q: R)
				for i = 0, 3 do
					q:block(-2.0, 1.84, -1.3 + i * 0.16, 2.0, 1.92, -1.18 + i * 0.16, C.Bark, "Wood")
				end
				for _, x in { -1.8, 0, 1.8 } do
					q:block(x - 0.06, 0.06, -0.84, x + 0.06, 1.84, -0.74, C.Bark, "Wood")
				end
			end)
			r:piece(function(q: R)
				q:box(-1.6, 2.17, -1.05, 0.2, 0.2, 0.2, CLAY, "Sand")
				for i = 0, 4 do
					local x = -1.6 + i * 0.8
					local tone = if i % 2 == 0 then CLAY else shade(CLAY, 0.92)
					q:cyl(x, 2.17, -1.05, 0.5, 0.46, "y", tone, "Sand")
					q:cyl(x, 2.43, -1.05, 0.1, 0.56, "y", shade(tone, 1.06), "Sand")
				end
			end)
			r:piece(function(q: R)
				q:box(-1.6, 2.5, -1.05, 0.1, 0.04, 0.1, C.Soil, "Grass")
				for i = 0, 4 do
					q:cyl(-1.6 + i * 0.8, 2.495, -1.05, 0.03, 0.46, "y", C.Soil, "Grass")
				end
				for i = 0, 4 do
					local x = -1.6 + i * 0.8
					q:lump(CFrame.new(x, 2.72, -1.05) * CFrame.Angles(0, i, 0), 0.5, 0.42, 0.46, C.Leaf, "Grass")
					q:lump(
						CFrame.new(x + 0.1, 2.92, -1.0) * CFrame.Angles(0, i * 2, 0),
						0.3,
						0.26,
						0.28,
						C.DarkLeaf,
						"Grass"
					)
				end
				-- the tomatoes by the door
				for _, sx in { -1, 1 } do
					for k = 0, 3 do
						q:lump(
							CFrame.new(sx * 1.55 + (k % 2 - 0.5) * 0.3, 0.9 + k * 0.62, 0.8) * CFrame.Angles(0, k, 0.3),
							0.6,
							0.4,
							0.5,
							if k % 2 == 0 then C.Leaf else C.DarkLeaf,
							"Grass"
						)
					end
				end
			end)
			r:piece(function(q: R)
				for _, sx in { -1, 1 } do
					q:block(sx * 1.55 - 0.03, 0.06, 0.77, sx * 1.55 + 0.03, 3.3, 0.83, CANE, "Wood")
				end
			end)
			r:piece(function(q: R)
				q:box(-1.42, 1.43, 1.02, 0.06, 0.03, 0.06, C.DarkLeaf, "SmoothPlastic")
				for _, sx in { -1, 1 } do
					for k, p in
						{
							{ 0.13, 1.25, 0.98 },
							{ -0.12, 1.4, 1.02 },
							{ 0.15, 2.05, 1.0 },
							{ -0.16, 2.6, 0.98 },
							{ 0.1, 3.0, 1.0 },
						}
					do
						q:ball(
							sx * 1.55 + p[1],
							p[2],
							p[3],
							0.22,
							if k == 4 then Color3.fromRGB(150, 180, 90) else TOMATO,
							"SmoothPlastic"
						)
					end
				end
			end)
		end,
	},
	{
		id = "raised_bed_veg",
		name = "Raised veg bed",
		gives = "veg", -- holding E gives something (Data/Items.Sources)
		cat = "garden",
		style = STYLE,
		price = 90,
		place = "ground",
		size = Vector3.new(4.4, 3.6, 2.4),
		c1 = "8A6C52",
		c2 = "D0604E",
		tags = { "plant" },
		build = function(r: R)
			-- a bed of old sleepers (c1) three high, laid like bricks so the corners lock, full of
			-- earth: tomatoes (c2) up canes at the back, lettuces at the front, spring onions and
			-- a strawberry trailing over the corner
			local H = 0.38
			for k = 0, 2 do
				local y0 = k * H
				local a = if k == 1 then shade(r.c1, 0.9) else r.c1
				local b = if k == 1 then r.c1 else shade(r.c1, 0.9)
				for _, s in { -1, 1 } do
					if k % 2 == 0 then
						r:block(-2.2, y0, s * 0.84, 2.2, y0 + H, s * 1.2, a, "Wood")
						r:block(s * 1.84, y0, -0.84, s * 2.2, y0 + H, 0.84, b, "Wood")
					else
						r:block(-1.84, y0, s * 0.84, 1.84, y0 + H, s * 1.2, a, "Wood")
						r:block(s * 1.84, y0, -1.2, s * 2.2, y0 + H, 1.2, b, "Wood")
					end
				end
			end
			local soil = 3 * H - 0.08
			r:block(-1.84, 0, -0.84, 1.84, soil, 0.84, C.Soil, "Sand")
			-- canes, two to a plant, crossed at the top
			r:piece(function(q: R)
				for _, x in { -1.25, -0.1 } do
					q:block(x - 0.03, soil, -0.53, x + 0.03, 3.4, -0.47, CANE, "Wood")
				end
				q:block(-1.5, 3.2, -0.53, 0.15, 3.26, -0.47, CANE, "Wood")
			end)
			r:piece(function(q: R)
				q:box(-1.25, soil + 0.02, -0.3, 0.1, 0.04, 0.1, C.DarkLeaf, "Grass")
				for _, x in { -1.25, -0.1 } do
					for k = 0, 4 do
						local side = if k % 2 == 0 then 1 else -1
						q:lump(
							CFrame.new(x + side * 0.2, soil + 0.35 + k * 0.45, -0.42 + side * 0.08)
								* CFrame.Angles(0.2, k * 1.4, side * 0.3),
							0.58,
							0.34,
							0.46,
							if k % 2 == 0 then C.Leaf else C.DarkLeaf,
							"Grass"
						)
					end
				end
				-- lettuces, an outer ruff and a paler heart
				for i = 0, 3 do
					local x = -1.5 + i * 0.66
					q:lump(CFrame.new(x, soil + 0.14, 0.42) * CFrame.Angles(0, i, 0), 0.62, 0.3, 0.58, C.Leaf, "Grass")
					q:lump(
						CFrame.new(x, soil + 0.26, 0.42) * CFrame.Angles(0, i * 2, 0),
						0.34,
						0.28,
						0.34,
						Color3.fromRGB(176, 208, 128),
						"Grass"
					)
				end
				-- spring onions
				for i = 0, 5 do
					q:add({
						shape = "Cone",
						cf = CFrame.new(1.15 + (i % 3) * 0.16, soil + 0.32, -0.5 + math.floor(i / 3) * 0.2)
							* CFrame.Angles(0, i, (i % 3 - 1) * 0.12),
						size = Vector3.new(0.09, 0.64 + (i % 2) * 0.14, 0.09),
						color = if i % 2 == 0 then C.Leaf else C.DarkLeaf,
						mat = "Grass",
					})
				end
			end)
			-- the strawberry: leaves on the corner and runners over the front
			r:piece(function(q: R)
				q:box(1.45, soil + 0.04, 0.45, 0.1, 0.06, 0.1, C.DarkLeaf, "Grass")
				q:lump(
					CFrame.new(1.45, soil + 0.12, 0.45) * CFrame.Angles(0, 0.5, 0),
					0.62,
					0.24,
					0.56,
					C.DarkLeaf,
					"Grass"
				)
				q:lump(CFrame.new(1.2, soil + 0.1, 0.7) * CFrame.Angles(0, 1.5, 0), 0.4, 0.18, 0.36, C.Leaf, "Grass")
				trail(q, 1.5, soil + 0.15, 1.3, 0.45, 0.25)
				trail(q, 1.05, soil + 0.15, 1.3, 0.35, 0.2)
			end)
			r:piece(function(q: R)
				q:box(-1.12, 1.4, -0.32, 0.06, 0.03, 0.06, C.DarkLeaf, "SmoothPlastic")
				for _, x in { -1.25, -0.1 } do
					for k, p in
						{
							{ 0.13, 1.22, -0.3 },
							{ -0.12, 1.42, -0.28 },
							{ 0.16, 1.95, -0.3 },
							{ -0.15, 2.45, -0.26 },
							{ 0.12, 2.9, -0.3 },
						}
					do
						q:ball(
							x + p[1],
							p[2],
							p[3],
							0.2,
							if k == 5 then Color3.fromRGB(150, 180, 90) else r.c2,
							"SmoothPlastic"
						)
					end
				end
				for _, p in { { 1.55, soil - 0.2, 1.32 }, { 1.08, soil - 0.16, 1.3 }, { 1.7, soil + 0.2, 0.62 } } do
					q:lump(CFrame.new(p[1], p[2], p[3]), 0.13, 0.16, 0.13, Color3.fromRGB(214, 70, 74), "SmoothPlastic")
				end
			end)
		end,
	},
	{
		id = "pond_raised",
		name = "Raised pond",
		cat = "garden",
		style = STYLE,
		price = 260,
		place = "ground",
		size = Vector3.new(6, 2.4, 4),
		c1 = "B0846A",
		c2 = "6CA6CC",
		lively = true,
		build = function(r: R)
			-- a long pond in a brick wall (c1) at sitting height, capped with stone slabs, the
			-- water (c2) a little under them: lily pads with a flower and a frog, two koi showing
			-- their backs and an iris in the corner
			r:block(-3, 0, -2, 3, 1.4, -1.6, r.c1, "Brick")
			r:block(-3, 0, 1.6, 3, 1.4, 2, r.c1, "Brick")
			r:block(-3, 0, -1.6, -2.6, 1.4, 1.6, r.c1, "Brick")
			r:block(2.6, 0, -1.6, 3, 1.4, 1.6, r.c1, "Brick")
			r:block(-2.6, 0, -1.6, 2.6, 1.0, 1.6, Color3.fromRGB(46, 84, 90), "Slate")
			K.surface(r, -2.6, 1.24, -1.6, 2.6, 1.6, r.c2) -- (its ripples drift: World/Lively)
			local stone = Color3.fromRGB(198, 192, 180)
			r:piece(function(q: R)
				for _, sz in { -1, 1 } do
					for i = 0, 3 do
						local x1 = -3.06 + i * 1.53
						q:block(
							x1 + 0.02,
							1.4,
							sz * 2.06,
							x1 + 1.51,
							1.56,
							sz * 1.5,
							if (i + sz) % 2 == 0 then stone else shade(stone, 0.93),
							"Slate"
						)
					end
					for i = 0, 1 do
						q:block(
							sz * 3.06,
							1.4,
							-1.48 + i * 1.5,
							sz * 2.5,
							1.56,
							-0.02 + i * 1.5,
							shade(stone, 0.96),
							"Slate"
						)
					end
				end
			end, true)
			for _, p in { { -1.5, 0.6, 0.8 }, { 0.4, -0.7, 0.7 }, { 1.6, 0.5, 0.6 } } do
				r:noCollide(r:cyl(p[1], 1.255, p[2], 0.03, p[3], "y", C.Leaf, "SmoothPlastic"))
			end
			r:piece(function(q: R)
				q:box(-1.5, 1.29, 0.6, 0.06, 0.03, 0.06, C.Yellow, "SmoothPlastic")
				for k = 0, 4 do
					local a = k / 5 * math.pi * 2
					q:lump(
						CFrame.new(-1.5 + math.cos(a) * 0.1, 1.33, 0.6 + math.sin(a) * 0.1) * CFrame.Angles(0, -a, 0.6),
						0.22,
						0.08,
						0.12,
						C.Pink,
						"SmoothPlastic"
					)
				end
				q:ball(-1.5, 1.37, 0.6, 0.12, C.Yellow, "SmoothPlastic")
				-- the frog on the next pad
				q:lump(CFrame.new(0.42, 1.36, -0.7), 0.26, 0.18, 0.3, Color3.fromRGB(120, 160, 80), "SmoothPlastic")
				for _, sx in { -1, 1 } do
					q:ball(0.42 + sx * 0.07, 1.44, -0.6, 0.08, Color3.fromRGB(120, 160, 80), "SmoothPlastic")
					q:ball(0.42 + sx * 0.07, 1.46, -0.57, 0.035, C.Black, "SmoothPlastic")
				end
				-- two koi, their backs at the surface
				for i, p in { { 0.5, 0.7, 0.4 }, { -0.6, -0.5, -0.5 } } do
					local col = if i == 1 then Color3.fromRGB(236, 140, 72) else C.White
					q:lump(
						CFrame.new(p[1], 1.2, p[2]) * CFrame.Angles(0, p[3], 0),
						0.2,
						0.14,
						0.56,
						col,
						"SmoothPlastic"
					)
					q:lump(
						CFrame.new(p[1] - math.sin(p[3]) * 0.33, 1.2, p[2] - math.cos(p[3]) * 0.33)
							* CFrame.Angles(0, p[3], 0),
						0.2,
						0.05,
						0.16,
						col,
						"SmoothPlastic"
					)
					q:lump(
						CFrame.new(p[1] + math.sin(p[3]) * 0.06, 1.25, p[2] + math.cos(p[3]) * 0.06)
							* CFrame.Angles(0, p[3], 0),
						0.1,
						0.06,
						0.2,
						if i == 1 then C.White else Color3.fromRGB(236, 140, 72),
						"SmoothPlastic"
					)
				end
			end)
			-- the iris: blades up out of the water and two purple flowers
			r:piece(function(q: R)
				q:box(-2.2, 1.26, -1.2, 0.3, 0.04, 0.3, C.DarkLeaf, "Grass")
				for k = 0, 5 do
					local a = k / 6 * math.pi * 2
					q:lump(
						CFrame.new(-2.2 + math.cos(a) * 0.1, 1.85, -1.2 + math.sin(a) * 0.1)
							* CFrame.Angles(math.sin(a) * 0.18, a, math.cos(a) * 0.18),
						0.07,
						1.2 - (k % 2) * 0.25,
						0.18,
						if k % 2 == 0 then C.Leaf else C.DarkLeaf,
						"Grass"
					)
				end
			end)
			r:piece(function(q: R)
				q:box(-2.1, 2.15, -1.1, 0.06, 0.06, 0.06, C.Yellow, "SmoothPlastic")
				for _, p in { { -2.1, 2.2, -1.1 }, { -2.32, 2.05, -1.3 } } do
					for k = 0, 2 do
						local a = k / 3 * math.pi * 2
						q:lump(
							CFrame.new(p[1] + math.cos(a) * 0.08, p[2], p[3] + math.sin(a) * 0.08)
								* CFrame.Angles(0, -a, 0.9),
							0.24,
							0.06,
							0.12,
							LILAC,
							"SmoothPlastic"
						)
					end
				end
			end)
		end,
	},
	{
		id = "compost_bin",
		name = "Compost bays",
		cat = "garden",
		style = STYLE,
		price = 60,
		place = "ground",
		size = Vector3.new(4.4, 2.6, 2.8),
		c1 = "8C6A4C",
		c2 = "5E4636",
		build = function(r: R)
			-- two bays of boards (c1) between posts, one half full of rotted compost (c2), the
			-- other piled with fresh clippings and peelings, and a fork left against the front
			for _, x in { -2.1, 0, 2.1 } do
				for _, z in { -0.95, 0.95 } do
					r:block(x - 0.1, 0, z - 0.1, x + 0.1, 2.3, z + 0.1, shade(r.c1, 0.82), "Wood")
				end
			end
			r:piece(function(q: R)
				for k = 0, 4 do
					local y = 0.1 + k * 0.42
					local tone = if k % 2 == 0 then r.c1 else shade(r.c1, 0.9)
					q:block(-2.1, y, -1.0, 2.1, y + 0.34, -0.9, tone, "WoodPlanks")
					for _, x in { -2.1, 0, 2.1 } do
						q:block(x - 0.05, y, -0.9, x + 0.05, y + 0.34, 0.9, tone, "WoodPlanks")
					end
					if k < 2 then
						q:block(-2.1, y, 0.9, 0, y + 0.34, 1.0, tone, "WoodPlanks")
					end
					if k < 4 then
						q:block(0, y, 0.9, 2.1, y + 0.34, 1.0, tone, "WoodPlanks")
					end
				end
			end, true)
			r:piece(function(q: R)
				q:box(-1.0, 0.3, 0, 1.8, 0.6, 1.6, r.c2, "Sand")
				for i, p in
					{
						{ -1.5, 0.75, -0.4 },
						{ -0.6, 0.8, -0.3 },
						{ -1.1, 0.95, 0.35 },
						{ -0.45, 0.7, 0.5 },
						{ -1.6, 0.7, 0.5 },
					}
				do
					q:lump(
						CFrame.new(p[1], p[2], p[3]) * CFrame.Angles(0, i, 0),
						0.9,
						0.5,
						0.8,
						if i % 2 == 0 then r.c2 else shade(r.c2, 1.15),
						"Sand"
					)
				end
				q:box(1.05, 0.6, 0, 1.8, 1.2, 1.6, shade(r.c2, 1.1), "Sand")
				for i, p in { { 0.6, 1.4, -0.3 }, { 1.4, 1.5, -0.2 }, { 1.0, 1.65, 0.3 }, { 1.5, 1.3, 0.5 } } do
					q:lump(
						CFrame.new(p[1], p[2], p[3]) * CFrame.Angles(0, i, 0),
						0.9,
						0.6,
						0.8,
						shade(r.c2, 1.2),
						"Sand"
					)
				end
			end)
			r:piece(function(q: R)
				q:box(1.0, 1.9, 0, 0.1, 0.04, 0.1, C.DarkLeaf, "Grass")
				for i, p in
					{
						{ 0.7, 1.82, -0.2 },
						{ 1.35, 1.88, 0.1 },
						{ 0.95, 1.98, 0.4 },
						{ 1.6, 1.7, -0.45 },
						{ 0.4, 1.66, 0.45 },
					}
				do
					q:lump(
						CFrame.new(p[1], p[2], p[3]) * CFrame.Angles(0.2, i * 1.2, 0.1),
						0.6,
						0.2,
						0.5,
						if i % 2 == 0 then C.Leaf else Color3.fromRGB(160, 170, 90),
						"Grass"
					)
				end
			end)
			r:piece(function(q: R)
				q:box(1.2, 2.06, 0.1, 0.06, 0.06, 0.06, C.White, "SmoothPlastic")
				q:lump(
					CFrame.new(0.75, 2.0, -0.1) * CFrame.Angles(0, 0.6, 0.4),
					0.5,
					0.1,
					0.12,
					C.Yellow,
					"SmoothPlastic"
				)
				q:lump(
					CFrame.new(0.82, 2.0, 0.02) * CFrame.Angles(0, -0.4, -0.3),
					0.4,
					0.1,
					0.12,
					C.Yellow,
					"SmoothPlastic"
				)
				q:lump(CFrame.new(1.25, 2.04, 0.15), 0.2, 0.12, 0.16, C.White, "SmoothPlastic")
				q:lump(CFrame.new(1.4, 2.02, 0.0), 0.18, 0.1, 0.14, C.White, "SmoothPlastic")
				q:ball(1.55, 1.95, 0.45, 0.22, Color3.fromRGB(196, 96, 80), "SmoothPlastic")
				q:lump(
					CFrame.new(-1.0, 1.06, 0.1) * CFrame.Angles(0, 1, 0),
					0.34,
					0.08,
					0.2,
					Color3.fromRGB(214, 160, 70),
					"SmoothPlastic"
				)
			end)
			-- a digging fork against the boards: its tines down in the grass
			r:piece(function(q: R)
				q:box(-1.0, 0.05, 1.32, 0.5, 0.06, 0.06, C.Metal, "Metal")
				for i = 0, 3 do
					q:block(-1.21 + i * 0.14, 0.05, 1.3, -1.17 + i * 0.14, 0.72, 1.34, C.Metal, "Metal")
				end
				q:block(-1.25, 0.72, 1.27, -0.75, 0.8, 1.35, C.Metal, "Metal")
			end)
			r:beam(Vector3.new(-1.0, 0.8, 1.31), Vector3.new(-1.0, 2.35, 1.07), 0.1, 0.1, C.Bark, "Wood")
			r:block(-1.18, 2.35, 1.0, -0.82, 2.43, 1.12, C.Bark, "Wood")
		end,
	},
	{
		id = "beehive",
		name = "Beehive",
		gives = "honey", -- holding E gives something (Data/Items.Sources)
		cat = "garden",
		style = STYLE,
		price = 110,
		place = "ground",
		size = Vector3.new(2.2, 3.4, 2.2),
		c1 = "F0E6D2",
		c2 = "8A9A86",
		build = function(r: R)
			-- a painted hive (c1) of two boxes on a stand of legs, a landing board at the front, a
			-- gabled roof (c2) and bees about the door
			for _, sx in { -1, 1 } do
				for _, sz in { -1, 1 } do
					r:block(sx * 0.7 - 0.08, 0, sz * 0.7 - 0.08, sx * 0.7 + 0.08, 0.9, sz * 0.7 + 0.08, C.Bark, "Wood")
				end
			end
			r:block(-0.85, 0.9, -0.85, 0.85, 1.05, 0.85, C.Bark, "Wood")
			r:block(-0.8, 1.05, -0.8, 0.8, 1.15, 0.8, shade(r.c1, 0.85), "Wood")
			r:ramp(-0.6, 1.0, 0.8, 0.6, 1.15, 1.12, false, shade(r.c1, 0.85), "Wood")
			-- the brood box and the super above it, each with a rim round its top and handholds
			for _, b in { { 1.15, 1.95 }, { 1.98, 2.55 } } do
				r:block(-0.75, b[1], -0.75, 0.75, b[2], 0.75, r.c1, "Wood")
				r:block(-0.78, b[2] - 0.1, -0.78, 0.78, b[2] - 0.03, 0.78, shade(r.c1, 0.92), "Wood")
				for _, sx in { -1, 1 } do
					r:block(
						sx * 0.75,
						(b[1] + b[2]) / 2 - 0.05,
						-0.2,
						sx * 0.79,
						(b[1] + b[2]) / 2 + 0.05,
						0.2,
						shade(r.c1, 0.7),
						"Wood"
					)
				end
			end
			r:block(-0.76, 1.95, -0.76, 0.76, 1.98, 0.76, shade(r.c1, 0.8), "Wood")
			r:block(-0.4, 1.17, 0.75, 0.4, 1.27, 0.79, Color3.fromRGB(60, 50, 44), "Wood")
			-- the roof
			r:block(-0.85, 2.55, -0.85, 0.85, 2.6, 0.85, shade(r.c2, 0.9), "WoodPlanks")
			r:ramp(-0.95, 2.6, -0.95, 0.95, 3.1, 0, true, r.c2, "WoodPlanks")
			r:ramp(-0.95, 2.6, 0, 0.95, 3.1, 0.95, false, r.c2, "WoodPlanks")
			r:block(-0.98, 3.05, -0.08, 0.98, 3.15, 0.08, shade(r.c2, 0.8), "WoodPlanks")
			-- the bees: a plain box body on the first, the rest striped balls with wings
			r:piece(function(q: R)
				q:box(0.2, 1.32, 0.95, 0.1, 0.08, 0.14, C.Yellow, "SmoothPlastic")
				for i, p in { { -0.3, 1.6, 1.05 }, { 0.5, 1.9, 1.0 }, { -0.1, 2.3, 1.08 }, { 0.65, 1.45, 0.98 } } do
					q:ball(p[1], p[2], p[3], 0.12, C.Yellow, "SmoothPlastic")
					q:ball(p[1] - 0.07, p[2], p[3] - 0.02, 0.09, C.Black, "SmoothPlastic")
					q:lump(
						CFrame.new(p[1], p[2] + 0.07, p[3]) * CFrame.Angles(0, i, 0.3),
						0.14,
						0.03,
						0.08,
						C.White,
						"SmoothPlastic"
					)
				end
			end)
		end,
	},
	{
		id = "bird_bath",
		name = "Bird bath",
		cat = "garden",
		style = STYLE,
		price = 70,
		place = "ground",
		size = Vector3.new(2.2, 3.2, 2.2),
		c1 = "BDB8AE",
		c2 = "7FB4CC",
		lively = true,
		build = function(r: R)
			-- a stone bath (c1) on a turned stem: a square foot, collars, a wide shallow bowl with
			-- a rolled lip and water (c2) in it, a sparrow on the rim
			local dk = shade(r.c1, 0.86)
			r:block(-0.62, 0, -0.62, 0.62, 0.18, 0.62, dk, "Slate")
			r:cyl(0, 0.28, 0, 0.2, 0.9, "y", r.c1, "Slate")
			r:cyl(0, 1.2, 0, 1.64, 0.42, "y", r.c1, "Slate")
			r:cyl(0, 0.46, 0, 0.16, 0.6, "y", dk, "Slate")
			r:cyl(0, 1.95, 0, 0.16, 0.6, "y", dk, "Slate")
			r:cyl(0, 2.12, 0, 0.18, 1.0, "y", r.c1, "Slate")
			r:cyl(0, 2.3, 0, 0.18, 1.6, "y", r.c1, "Slate")
			r:cyl(0, 2.46, 0, 0.14, 2.0, "y", r.c1, "Slate")
			K.roundSurface(r, 0, 2.6, 0, 1.8, r.c2) -- (its ripples drift: World/Lively)
			for i = 0, 9 do
				local a1 = i / 10 * math.pi * 2
				local a2 = (i + 1) / 10 * math.pi * 2
				r:beam(
					Vector3.new(math.cos(a1) * 0.93, 2.62, math.sin(a1) * 0.93),
					Vector3.new(math.cos(a2) * 0.93, 2.62, math.sin(a2) * 0.93),
					0.16,
					0.17,
					shade(r.c1, 1.05),
					"Slate"
				)
			end
			r:piece(function(q: R)
				bird(q, 0.78, 2.7, 0.42, -1, Color3.fromRGB(150, 112, 80), Color3.fromRGB(214, 196, 170))
			end)
			r:piece(function(q: R)
				q:box(0.5, 0.2, 0.5, 0.08, 0.04, 0.08, C.DarkLeaf, "Grass")
				q:lump(
					CFrame.new(-0.4, 0.2, 0.45) * CFrame.Angles(0, 0.4, 0),
					0.4,
					0.06,
					0.3,
					Color3.fromRGB(126, 158, 96),
					"Grass"
				)
				q:lump(
					CFrame.new(0.45, 0.2, -0.4) * CFrame.Angles(0, 1.4, 0),
					0.34,
					0.06,
					0.26,
					Color3.fromRGB(126, 158, 96),
					"Grass"
				)
				for _, t in { { 0.75, 0.55 }, { -0.78, -0.4 }, { -0.5, 0.8 }, { 0.6, -0.8 } } do
					tuft(q, t[1], t[2], 0, t[1] * 3)
				end
			end)
		end,
	},
	{
		id = "sundial",
		name = "Garden sundial",
		cat = "garden",
		style = STYLE,
		price = 80,
		place = "ground",
		size = Vector3.new(1.6, 3.4, 1.6),
		c1 = "C8C2B6",
		c2 = "C9A35E",
		build = function(r: R)
			-- a stone column (c1) on a stepped base, a brass dial (c2) on its cap with the hours
			-- marked round its edge and a gnomon standing up across it, ivy at the foot
			local dk = shade(r.c1, 0.88)
			r:cyl(0, 0.08, 0, 0.16, 1.55, "y", dk, "Slate")
			r:block(-0.52, 0.16, -0.52, 0.52, 0.42, 0.52, r.c1, "Slate")
			r:cyl(0, 0.5, 0, 0.16, 0.66, "y", dk, "Slate")
			r:cyl(0, 1.5, 0, 2.0, 0.46, "y", r.c1, "Slate")
			r:cyl(0, 2.48, 0, 0.16, 0.66, "y", dk, "Slate")
			r:block(-0.5, 2.56, -0.5, 0.5, 2.76, 0.5, r.c1, "Slate")
			r:cyl(0, 2.8, 0, 0.08, 0.92, "y", r.c2, "Metal")
			r:piece(function(q: R)
				q:box(0, 2.855, -0.36, 0.03, 0.03, 0.12, shade(r.c2, 0.6), "Metal")
				for k = -6, 6 do
					if k ~= 0 then
						local a = -math.pi / 2 + k * math.pi / 12
						q:boxAt(
							CFrame.new(math.cos(a) * 0.36, 2.855, math.sin(a) * 0.36)
								* CFrame.Angles(0, -a + math.pi / 2, 0),
							0.03,
							0.03,
							if k % 3 == 0 then 0.14 else 0.08,
							shade(r.c2, 0.6),
							"Metal"
						)
					end
				end
			end)
			r:tri(
				Vector3.new(0, 2.84, 0.22),
				Vector3.new(0, 2.84, -0.36),
				Vector3.new(0, 3.26, -0.36),
				0.05,
				shade(r.c2, 0.9),
				"Metal"
			)
			r:piece(function(q: R)
				q:box(-0.4, 0.18, 0.62, 0.08, 0.04, 0.08, C.DarkLeaf, "Grass")
				for i, p in
					{
						{ -0.42, 0.3, 0.6 },
						{ -0.62, 0.55, 0.3 },
						{ -0.3, 0.7, 0.56 },
						{ 0.6, 0.3, -0.45 },
						{ -0.25, 1.0, 0.28 },
						{ -0.6, 0.2, -0.3 },
					}
				do
					q:lump(
						CFrame.new(p[1], p[2], p[3]) * CFrame.Angles(0.3, i * 1.1, 0.2),
						0.3,
						0.14,
						0.26,
						if i % 2 == 0 then C.DarkLeaf else C.Leaf,
						"Grass"
					)
				end
			end)
		end,
	},
	{
		id = "flower_barrow",
		name = "Flower barrow",
		gives = "bunches", -- holding E gives something (Data/Items.Sources)
		cat = "garden",
		style = STYLE,
		price = 75,
		place = "ground",
		size = Vector3.new(2.2, 2.6, 4.6),
		c1 = "A5805C",
		c2 = "E79AAE",
		tags = { "plant" },
		build = function(r: R)
			-- an old wooden wheelbarrow (c1) left on the lawn and planted up: an iron tyred wheel,
			-- two shafts to the handles, a pair of legs, and the tray full of flowers (c2)
			-- spilling over its sides
			local wz = 1.7
			r:cyl(0, 0.55, wz, 0.2, 1.1, "x", C.DarkMetal, "Metal")
			r:cyl(0, 0.55, wz, 0.28, 0.9, "x", r.c1, "Wood")
			r:cyl(0, 0.55, wz, 0.46, 0.26, "x", shade(r.c1, 0.8), "Wood")
			for k = 0, 3 do
				r:boxAt(
					CFrame.new(0, 0.55, wz) * CFrame.Angles(k * math.pi / 4, 0, 0),
					0.36,
					0.84,
					0.07,
					shade(r.c1, 0.85),
					"Wood"
				)
			end
			for _, sx in { -1, 1 } do
				local front = Vector3.new(sx * 0.32, 0.55, wz)
				local back = Vector3.new(sx * 0.78, 1.05, -2.1)
				r:beam(front, back, 0.12, 0.14, shade(r.c1, 0.9), "Wood")
				rod(r, back, back + Vector3.new(sx * 0.02, 0.02, -0.18), 0.13, C.Bark, "Wood")
				local t = (wz + 0.9) / (wz + 2.1)
				local at = front:Lerp(back, t)
				r:beam(at, Vector3.new(sx * 0.68, 0.06, -1.0), 0.1, 0.1, shade(r.c1, 0.9), "Wood")
				r:block(sx * 0.68 - 0.08, 0, -1.08, sx * 0.68 + 0.08, 0.08, -0.92, shade(r.c1, 0.8), "Wood")
			end
			r:block(-0.7, 0.66, 0.7, 0.7, 0.95, 0.9, shade(r.c1, 0.85), "Wood")
			r:block(-0.7, 0.86, -0.9, 0.7, 0.95, -0.7, shade(r.c1, 0.85), "Wood")
			-- the tray: a floor, two sides, a back and a front that leans out
			r:block(-0.62, 0.95, -1.1, 0.62, 1.05, 1.12, r.c1, "WoodPlanks")
			for _, sx in { -1, 1 } do
				r:quad(
					Vector3.new(sx * 0.67, 0.95, -1.2),
					Vector3.new(sx * 0.67, 0.95, 1.12),
					Vector3.new(sx * 0.67, 1.62, 1.45),
					Vector3.new(sx * 0.67, 1.62, -1.2),
					0.1,
					r.c1,
					"WoodPlanks"
				)
			end
			r:block(-0.62, 0.95, -1.2, 0.62, 1.62, -1.1, r.c1, "WoodPlanks")
			r:quad(
				Vector3.new(-0.62, 0.95, 1.17),
				Vector3.new(0.62, 0.95, 1.17),
				Vector3.new(0.62, 1.62, 1.5),
				Vector3.new(-0.62, 1.62, 1.5),
				0.1,
				r.c1,
				"WoodPlanks"
			)
			r:block(-0.62, 1.05, -1.1, 0.62, 1.45, 1.2, C.Soil, "Sand")
			r:piece(function(q: R)
				q:box(0, 1.47, 0, 0.6, 0.04, 0.6, C.DarkLeaf, "Grass")
				for i = 0, 4 do
					local z = -0.82 + i * 0.48
					q:lump(
						CFrame.new((i % 2 - 0.5) * 0.4, 1.6, z) * CFrame.Angles(0, i, 0),
						0.7,
						0.36,
						0.6,
						if i % 2 == 0 then C.Leaf else C.DarkLeaf,
						"Grass"
					)
				end
				for _, sx in { -1, 1 } do
					for _, z in { -0.7, 0.1, 0.8 } do
						trail(q, sx * 0.78, 1.6, z + sx * 0.1, 0.5 + (z % 0.3), 0)
					end
				end
				trail(q, 0.2, 1.6, 1.58, 0.45, 0.3)
			end)
			r:piece(function(q: R)
				bloom(q, -0.3, -0.8, 1.5, 2.1, r.c2, 0.3)
				bloom(q, 0.25, -0.45, 1.5, 2.3, C.White, 1.2)
				bloom(q, -0.2, 0.0, 1.5, 2.2, r.c2, 2.2)
				bloom(q, 0.3, 0.4, 1.5, 2.0, C.Yellow, 0.7)
				bloom(q, -0.25, 0.75, 1.5, 2.05, shade(r.c2, 1.1), 2.6)
				bloom(q, 0.25, 1.05, 1.5, 1.85, CORAL, 1.6)
			end)
		end,
	},
	{
		id = "obelisk_sweetpea",
		name = "Sweet pea obelisk",
		gives = "flowers", -- holding E gives something (Data/Items.Sources)
		cat = "garden",
		style = STYLE,
		price = 55,
		place = "ground",
		size = Vector3.new(2, 6, 2),
		c1 = "6F8A7A",
		c2 = "C99BD6",
		tags = { "plant" },
		build = function(r: R)
			-- a painted wooden obelisk (c1) of four legs drawn in to a point, square rings round
			-- it and a ball on top, with sweet peas (c2 and friends) climbing it
			local base, topY, tip = 0.8, 5.2, 0.12
			local function off(y: number): number
				return base - (base - tip) * (y / topY)
			end
			r:cyl(0, 0.04, 0, 0.08, 1.95, "y", C.Soil, "Sand")
			for _, sx in { -1, 1 } do
				for _, sz in { -1, 1 } do
					r:beam(
						Vector3.new(sx * base, 0, sz * base),
						Vector3.new(sx * tip, topY, sz * tip),
						0.12,
						0.12,
						r.c1,
						"Wood"
					)
				end
			end
			r:piece(function(q: R)
				q:block(-0.2, topY - 0.1, -0.2, 0.2, topY + 0.05, 0.2, r.c1, "Wood")
				q:ball(0, topY + 0.28, 0, 0.42, r.c1, "Wood")
				for _, y in { 1.3, 2.6, 3.8 } do
					local o = off(y) + 0.02
					for _, s in { -1, 1 } do
						q:block(-o - 0.04, y - 0.05, s * o - 0.04, o + 0.04, y + 0.05, s * o + 0.04, r.c1, "Wood")
						q:block(s * o - 0.04, y - 0.05, -o + 0.04, s * o + 0.04, y + 0.05, o - 0.04, r.c1, "Wood")
					end
				end
			end)
			r:piece(function(q: R)
				q:box(0.6, 0.1, 0.6, 0.12, 0.12, 0.12, C.DarkLeaf, "Grass")
				for i = 0, 25 do
					local y = 0.25 + i * 0.18
					local corner = i % 4
					local sx = if corner == 0 or corner == 3 then 1 else -1
					local sz = if corner < 2 then 1 else -1
					local o = off(y) + 0.12
					q:lump(
						CFrame.new(sx * o + (hash(i, 41) - 0.5) * 0.4, y, sz * o + (hash(i, 42) - 0.5) * 0.4)
							* CFrame.Angles(0.4, i * 1.3, 0.3),
						0.64 - y * 0.05,
						0.34,
						0.5 - y * 0.04,
						if i % 2 == 0 then C.Leaf else shade(C.Leaf, 0.86),
						"Grass"
					)
				end
			end)
			r:piece(function(q: R)
				q:box(0.75, 0.9, 0.75, 0.06, 0.06, 0.06, r.c2, "SmoothPlastic")
				local cols = { r.c2, Color3.fromRGB(240, 166, 192), C.White, Color3.fromRGB(186, 122, 168) }
				for i = 0, 23 do
					local y = 0.7 + i * 0.18
					local a = i * 2.4
					local o = off(y) + 0.22
					local px, pz = math.cos(a) * o * 1.2, math.sin(a) * o * 1.2
					q:lump(
						CFrame.new(px, y, pz) * CFrame.Angles(0, math.pi / 2 - math.atan2(pz, px), 0.2),
						0.34,
						0.3,
						0.08,
						cols[i % 4 + 1],
						"SmoothPlastic"
					)
				end
			end)
		end,
	},
	{
		id = "statue_hare",
		name = "Stone hare",
		cat = "garden",
		style = STYLE,
		price = 95,
		place = "ground",
		size = Vector3.new(1.8, 4, 1.8),
		c1 = "B9B4AA",
		c2 = "7E9F62",
		tags = { "art" },
		build = function(r: R)
			-- a hare sitting up on a square plinth, carved in stone (c1): haunches, a long body,
			-- its head tipped down, ears up, front paws together and a round tail, moss (c2)
			-- in the corners
			local dk = shade(r.c1, 0.86)
			r:block(-0.8, 0, -0.8, 0.8, 0.16, 0.8, dk, "Slate")
			r:block(-0.62, 0.16, -0.62, 0.62, 1.36, 0.62, r.c1, "Slate")
			r:block(-0.74, 1.36, -0.74, 0.74, 1.52, 0.74, dk, "Slate")
			r:lump(CFrame.new(0, 1.92, -0.12), 0.92, 0.8, 1.0, r.c1, "Slate")
			r:lump(CFrame.new(0, 2.3, 0.14) * CFrame.Angles(-0.25, 0, 0), 0.7, 1.0, 0.66, r.c1, "Slate")
			r:lump(CFrame.new(0, 2.92, 0.34) * CFrame.Angles(0.35, 0, 0), 0.5, 0.46, 0.66, r.c1, "Slate")
			for _, sx in { -1, 1 } do
				r:lump(
					CFrame.new(sx * 0.12, 3.5, 0.12) * CFrame.Angles(-0.35, 0, sx * -0.18),
					0.17,
					0.9,
					0.28,
					r.c1,
					"Slate"
				)
				r:lump(
					CFrame.new(sx * 0.12, 3.5, 0.16) * CFrame.Angles(-0.35, 0, sx * -0.18),
					0.1,
					0.7,
					0.2,
					dk,
					"Slate"
				)
				r:lump(CFrame.new(sx * 0.15, 1.86, 0.5) * CFrame.Angles(0.15, 0, 0), 0.17, 0.62, 0.2, r.c1, "Slate")
				r:lump(CFrame.new(sx * 0.34, 1.6, 0.18), 0.24, 0.16, 0.66, r.c1, "Slate")
				r:ball(sx * 0.2, 3.02, 0.55, 0.07, dk, "Slate")
			end
			r:ball(0, 1.9, -0.62, 0.3, shade(r.c1, 1.06), "Slate")
			r:piece(function(q: R)
				q:box(-0.5, 1.54, -0.5, 0.1, 0.04, 0.1, r.c2, "Grass")
				q:lump(CFrame.new(-0.52, 1.52, -0.52) * CFrame.Angles(0, 0.5, 0), 0.4, 0.08, 0.3, r.c2, "Grass")
				q:lump(
					CFrame.new(0.55, 1.52, 0.5) * CFrame.Angles(0, 1.2, 0),
					0.32,
					0.08,
					0.26,
					shade(r.c2, 0.9),
					"Grass"
				)
				q:lump(CFrame.new(-0.6, 0.6, 0.62) * CFrame.Angles(1.57, 0, 0.3), 0.3, 0.07, 0.5, r.c2, "Grass")
				q:lump(CFrame.new(0.66, 0.16, -0.66) * CFrame.Angles(0, 0.8, 0), 0.4, 0.08, 0.34, r.c2, "Grass")
				tuft(q, 0.75, 0.6, 0, 0.4)
				tuft(q, -0.7, -0.75, 0, 2.2)
			end)
		end,
	},
	{
		id = "topiary_spiral",
		name = "Spiral topiary",
		cat = "garden",
		style = STYLE,
		price = 60,
		place = "ground",
		size = Vector3.new(1.6, 5.2, 1.6),
		c1 = "4E7F58",
		c2 = "B77A5E",
		tags = { "plant" },
		build = function(r: R)
			-- box clipped into a spiral (c1) round a dark core, in a square clay planter (c2)
			-- with a rim of four boards and earth inside
			r:block(-0.62, 0.08, -0.62, 0.62, 1.1, 0.62, r.c2, "Sand")
			for _, sx in { -1, 1 } do
				for _, sz in { -1, 1 } do
					r:block(sx * 0.62, 0, sz * 0.62, sx * 0.44, 0.08, sz * 0.44, shade(r.c2, 0.8), "Sand")
				end
			end
			r:piece(function(q: R)
				for _, s in { -1, 1 } do
					q:block(-0.72, 0.98, s * 0.58, 0.72, 1.16, s * 0.72, shade(r.c2, 1.06), "Sand")
					q:block(s * 0.58, 0.98, -0.58, s * 0.72, 1.16, 0.58, shade(r.c2, 1.06), "Sand")
				end
			end)
			r:block(-0.58, 1.1, -0.58, 0.58, 1.13, 0.58, C.Soil, "Sand")
			r:cyl(0, 1.38, 0, 0.5, 0.14, "y", C.Bark, "Wood")
			r:piece(function(q: R)
				q:box(0, 1.7, 0, 0.12, 0.12, 0.12, shade(r.c1, 0.6), "Grass")
				q:cone(0, 3.15, 0, 3.0, 0.32, shade(r.c1, 0.6), "Grass")
				local n = 22
				for i = 0, n - 1 do
					local t = i / (n - 1)
					local a = t * 2.6 * math.pi * 2
					local rad = 0.42 * (1 - t) + 0.08
					local s = 0.72 * (1 - t) + 0.26
					q:lump(
						CFrame.new(math.cos(a) * rad, 1.78 + t * 3.0, math.sin(a) * rad) * CFrame.Angles(0, -a, 0.3),
						s,
						s * 0.7,
						s,
						if i % 2 == 0 then r.c1 else shade(r.c1, 1.12),
						"Grass"
					)
				end
				q:ball(0, 4.95, 0, 0.3, shade(r.c1, 1.15), "Grass")
			end)
		end,
	},
	{
		id = "topiary_tiers",
		name = "Tiered topiary",
		cat = "garden",
		style = STYLE,
		price = 55,
		place = "ground",
		size = Vector3.new(1.6, 4.8, 1.6),
		c1 = "5A8A5C",
		c2 = "C9C2B4",
		tags = { "plant" },
		build = function(r: R)
			-- a stem with three clipped balls up it, getting smaller, in a round stone pot (c2)
			r:cyl(0, 0.08, 0, 0.16, 0.86, "y", shade(r.c2, 0.86), "Slate")
			r:cyl(0, 0.54, 0, 0.8, 1.12, "y", r.c2, "Slate")
			r:cyl(0, 0.75, 0, 0.12, 1.18, "y", shade(r.c2, 0.92), "Slate")
			r:cyl(0, 1.0, 0, 0.16, 1.3, "y", shade(r.c2, 1.05), "Slate")
			r:cyl(0, 1.1, 0, 0.04, 1.1, "y", C.Soil, "Sand")
			r:cyl(0, 2.7, 0, 3.2, 0.12, "y", C.Bark, "Wood")
			r:piece(function(q: R)
				q:box(0, 1.9, 0, 0.3, 0.3, 0.3, shade(r.c1, 0.8), "Grass")
				local lit = shade(r.c1, 1.15)
				for _, b in { { 1.9, 1.3 }, { 3.15, 1.02 }, { 4.15, 0.72 } } do
					local y, d = b[1], b[2]
					q:lump(CFrame.new(0, y, 0) * CFrame.Angles(0, y, 0), d, d * 0.92, d, r.c1, "Grass")
					q:lump(
						CFrame.new(-d * 0.12, y + d * 0.14, d * 0.08) * CFrame.Angles(0.3, y * 2, 0),
						d * 0.7,
						d * 0.6,
						d * 0.7,
						lit,
						"Grass"
					)
					q:lump(
						CFrame.new(d * 0.14, y - d * 0.16, -d * 0.1) * CFrame.Angles(0.2, y * 3, 0),
						d * 0.76,
						d * 0.5,
						d * 0.74,
						shade(r.c1, 0.85),
						"Grass"
					)
				end
			end)
		end,
	},
	{
		id = "bird_table",
		name = "Bird table",
		cat = "garden",
		style = STYLE,
		price = 45,
		place = "ground",
		size = Vector3.new(2.2, 6, 2.2),
		c1 = "8E6A4A",
		c2 = "7A8F7E",
		build = function(r: R)
			-- a post on crossed feet (c1) holding a tray with a lip, four little posts up to a
			-- roof (c2), seed on the tray, a robin feeding, a tit on the ridge and a fat ball
			-- hung from the eave
			r:block(-0.12, 0, -0.12, 0.12, 4.2, 0.12, r.c1, "Wood")
			r:block(-0.9, 0, -0.1, 0.9, 0.16, 0.1, shade(r.c1, 0.85), "Wood")
			r:block(-0.1, 0, -0.9, 0.1, 0.16, 0.9, shade(r.c1, 0.85), "Wood")
			for k = 0, 3 do
				local a = k * math.pi / 2
				r:beam(
					Vector3.new(math.cos(a) * 0.7, 0.16, math.sin(a) * 0.7),
					Vector3.new(math.cos(a) * 0.12, 0.9, math.sin(a) * 0.12),
					0.08,
					0.08,
					shade(r.c1, 0.85),
					"Wood"
				)
			end
			r:block(-0.8, 4.2, -0.8, 0.8, 4.3, 0.8, r.c1, "Wood")
			r:piece(function(q: R)
				for _, s in { -1, 1 } do
					q:block(-0.8, 4.3, s * 0.72, 0.8, 4.4, s * 0.8, shade(r.c1, 0.9), "Wood")
					q:block(s * 0.72, 4.3, -0.72, s * 0.8, 4.4, 0.72, shade(r.c1, 0.9), "Wood")
				end
				for _, sx in { -1, 1 } do
					for _, sz in { -1, 1 } do
						q:block(
							sx * 0.62 - 0.05,
							4.3,
							sz * 0.62 - 0.05,
							sx * 0.62 + 0.05,
							5.15,
							sz * 0.62 + 0.05,
							r.c1,
							"Wood"
						)
					end
				end
				q:block(-0.72, 5.12, -0.72, 0.72, 5.2, 0.72, r.c1, "Wood")
			end)
			r:ramp(-1.0, 5.2, -1.0, 1.0, 5.75, 0, true, r.c2, "WoodPlanks")
			r:ramp(-1.0, 5.2, 0, 1.0, 5.75, 1.0, false, r.c2, "WoodPlanks")
			r:block(-1.04, 5.7, -0.07, 1.04, 5.8, 0.07, shade(r.c2, 0.8), "WoodPlanks")
			r:piece(function(q: R)
				q:box(-0.3, 4.32, -0.2, 0.08, 0.04, 0.06, Color3.fromRGB(214, 186, 130), "SmoothPlastic")
				for i = 1, 12 do
					q:lump(
						CFrame.new(-0.55 + hash(i, 51) * 1.1, 4.32, -0.55 + hash(i, 52) * 1.1) * CFrame.Angles(0, i, 0),
						0.08,
						0.05,
						0.06,
						if i % 3 == 0 then C.Bark else Color3.fromRGB(214, 186, 130),
						"SmoothPlastic"
					)
				end
				q:lump(
					CFrame.new(0.35, 4.36, -0.35) * CFrame.Angles(0, 0.5, 0),
					0.3,
					0.12,
					0.3,
					Color3.fromRGB(196, 90, 80),
					"SmoothPlastic"
				)
				q:lump(
					CFrame.new(0.35, 4.43, -0.35) * CFrame.Angles(0, 0.5, 0),
					0.24,
					0.02,
					0.24,
					Color3.fromRGB(240, 226, 190),
					"SmoothPlastic"
				)
			end)
			r:piece(function(q: R)
				bird(q, -0.3, 4.3, 0.35, 1, Color3.fromRGB(140, 110, 84), Color3.fromRGB(222, 120, 80))
			end)
			r:piece(function(q: R)
				bird(q, 0.3, 5.78, 0, -1, C.Blue, C.Yellow)
			end)
			r:cyl(0.5, 4.95, 0.92, 0.5, 0.03, "y", C.DarkMetal, "Metal")
			r:ball(0.5, 4.56, 0.92, 0.32, Color3.fromRGB(214, 186, 130), "SmoothPlastic")
			r:ball(0.5, 4.56, 0.92, 0.36, C.DarkMetal, "Metal").transp = 0.6
		end,
	},

	-- To sit at and work at ---------------------------------------------------------------------------
	{
		id = "bench_pergola",
		name = "Pergola bench",
		cat = "seating",
		style = STYLE,
		price = 260,
		place = "ground",
		size = Vector3.new(6.4, 8, 3.4),
		c1 = "B08A64",
		c2 = "A890C8",
		tags = { "seat", "plant" },
		build = function(r: R)
			-- a timber pergola (c1) of four posts in iron shoes, two beams and rafters across, a
			-- slatted bench along its back, and wisteria (c2) up two posts and hanging from the
			-- top
			for _, sx in { -1, 1 } do
				for _, sz in { -1, 1 } do
					r:block(sx * 2.9 - 0.18, 0, sz * 1.4 - 0.18, sx * 2.9 + 0.18, 6.9, sz * 1.4 + 0.18, r.c1, "Wood")
					r:block(
						sx * 2.9 - 0.22,
						0,
						sz * 1.4 - 0.22,
						sx * 2.9 + 0.22,
						0.3,
						sz * 1.4 + 0.22,
						C.DarkMetal,
						"Metal"
					)
				end
				r:block(-3.2, 6.9, sx * 1.4 - 0.12, 3.2, 7.4, sx * 1.4 + 0.12, shade(r.c1, 0.92), "Wood")
			end
			r:piece(function(q: R)
				for i = 0, 6 do
					local x = -2.7 + i * 0.9
					q:block(x - 0.08, 7.4, -1.7, x + 0.08, 7.75, 1.7, r.c1, "Wood")
				end
			end)
			-- the bench
			r:piece(function(q: R)
				for _, x in { -2.1, 0, 2.1 } do
					q:block(x - 0.07, 0, -0.42, x + 0.07, 1.62, -0.28, shade(r.c1, 0.85), "Wood")
					q:block(x - 0.07, 0, -1.2, x + 0.07, 3.2, -1.06, shade(r.c1, 0.85), "Wood")
					q:block(x - 0.07, 1.48, -1.06, x + 0.07, 1.62, -0.42, shade(r.c1, 0.85), "Wood")
				end
				for _, z in { -1.0, -0.7, -0.4 } do
					q:block(-2.3, 1.62, z - 0.13, 2.3, 1.74, z + 0.13, r.c1, "Wood")
				end
				for _, y in { 2.2, 2.6, 3.0 } do
					q:block(-2.3, y - 0.14, -1.06, 2.3, y + 0.14, -0.96, r.c1, "Wood")
				end
				for _, sx in { -1, 1 } do
					q:block(sx * 2.3 - 0.08, 2.3, -1.06, sx * 2.3 + 0.08, 2.4, -0.25, shade(r.c1, 0.85), "Wood")
					q:block(sx * 2.3 - 0.06, 1.74, -0.4, sx * 2.3 + 0.06, 2.3, -0.3, shade(r.c1, 0.85), "Wood")
				end
			end, true)
			r:seat(-1.1, 1.74, -0.7)
			r:seat(1.1, 1.74, -0.7)
			-- the wisteria's old twisting stems up the two back posts and along the beam
			for _, sx in { -1, 1 } do
				r:piece(function(q: R)
					q:block(sx * 2.62 - 0.06, 0, -1.12, sx * 2.62 + 0.06, 0.3, -1.0, C.Bark, "Wood")
					rail(q, {
						Vector3.new(sx * 2.62, 0.2, -1.06),
						Vector3.new(sx * 3.15, 1.5, -1.3),
						Vector3.new(sx * 2.95, 3.0, -1.66),
						Vector3.new(sx * 2.64, 4.5, -1.42),
						Vector3.new(sx * 2.92, 6.0, -1.12),
						Vector3.new(sx * 3.1, 6.95, -1.3),
						Vector3.new(sx * 2.0, 7.5, -1.62),
						Vector3.new(sx * 0.6, 7.5, -1.6),
					}, 0.12, 0.12, C.Bark, "Wood")
				end)
			end
			r:piece(function(q: R)
				q:box(0, 7.5, -1.4, 0.2, 0.2, 0.2, C.DarkLeaf, "Grass")
				for i = 0, 11 do
					local x = -3.0 + i * 0.55
					for _, z in { -1.4, 1.4 } do
						q:lump(
							CFrame.new(x, 7.55 + (i % 2) * 0.1, z + (hash(i, z) - 0.5) * 0.4)
								* CFrame.Angles(0.3, i * 1.7, 0.2),
							0.7,
							0.4,
							0.6,
							if (i + z) % 2 == 0 then C.Leaf else shade(C.Leaf, 0.85),
							"Grass"
						)
					end
				end
			end)
			r:piece(function(q: R)
				q:box(-2.0, 6.9, 0.2, 0.08, 0.08, 0.08, shade(r.c2, 0.9), "SmoothPlastic")
				for i, p in
					{
						{ -2.0, -1.0 },
						{ -1.1, 0.6 },
						{ -0.4, -0.9 },
						{ 0.5, 1.1 },
						{ 1.2, -0.6 },
						{ 2.1, 0.3 },
						{ -2.4, 1.3 },
						{ 1.7, 1.4 },
					}
				do
					for k = 0, 2 do
						local s = 0.56 - k * 0.13
						q:lump(
							CFrame.new(p[1], 7.1 - k * 0.4, p[2]) * CFrame.Angles(0, i + k, 0),
							s,
							0.48,
							s,
							if k == 2 then Colors.mix(r.c2, C.White, 0.35) elseif k == 1 then shade(r.c2, 1.06) else r.c2,
							"SmoothPlastic"
						)
					end
				end
			end)
		end,
	},
	{
		id = "swing_canopy",
		name = "Canopy swing",
		cat = "seating",
		style = STYLE,
		price = 240,
		place = "ground",
		size = Vector3.new(6.4, 6.6, 3.6),
		c1 = "8DB0A8",
		c2 = "EFEBE2",
		tags = { "seat" },
		build = function(r: R)
			-- a two seater swinging bench under a striped canopy: a painted frame (c2) of two
			-- A ends and a top bar, the seat on four rods with cushions (c1), the canopy's
			-- stripes and a scalloped edge in c1 and white
			for _, x in { -3.0, 3.0 } do
				rod(r, Vector3.new(x, 0.05, -1.6), Vector3.new(x, 5.4, 0), 0.16, r.c2, "Metal")
				rod(r, Vector3.new(x, 0.05, 1.6), Vector3.new(x, 5.4, 0), 0.16, r.c2, "Metal")
				r:block(x - 0.07, 0, -1.7, x + 0.07, 0.1, 1.7, r.c2, "Metal")
				rod(r, Vector3.new(x, 1.6, -1.12), Vector3.new(x, 1.6, 1.12), 0.08, r.c2, "Metal")
				rod(r, Vector3.new(x, 5.4, 0), Vector3.new(x, 5.5, 1.72), 0.07, r.c2, "Metal")
				rod(r, Vector3.new(x, 5.4, 0), Vector3.new(x, 5.5, -1.72), 0.07, r.c2, "Metal")
				rod(r, Vector3.new(x, 5.4, 0), Vector3.new(x, 6.28, 0), 0.07, r.c2, "Metal")
			end
			r:cyl(0, 5.4, 0, 6.3, 0.2, "x", r.c2, "Metal")
			r:cyl(0, 6.28, 0, 6.3, 0.08, "x", r.c2, "Metal")
			-- the canopy in stripes, and its scalloped edge hanging from each side
			for _, sz in { -1, 1 } do
				for i = 0, 5 do
					local x1, x2 = -3.15 + i * 1.05, -3.15 + (i + 1) * 1.05
					r:quad(
						Vector3.new(x1, 5.52, sz * 1.76),
						Vector3.new(x2, 5.52, sz * 1.76),
						Vector3.new(x2, 6.34, 0),
						Vector3.new(x1, 6.34, 0),
						0.06,
						if i % 2 == 0 then r.c1 else C.White,
						"Fabric"
					)
				end
			end
			r:piece(function(q: R)
				for _, sz in { -1, 1 } do
					q:block(-3.15, 5.36, sz * 1.76 - 0.02, 3.15, 5.5, sz * 1.76 + 0.02, r.c1, "Fabric")
					for i = 0, 11 do
						local x = -2.89 + i * 0.525
						q:block(
							x - 0.2,
							5.22,
							sz * 1.76 - 0.02,
							x + 0.2,
							5.36,
							sz * 1.76 + 0.02,
							if i % 2 == 0 then r.c1 else C.White,
							"Fabric"
						)
					end
				end
			end)
			-- the seat on its rods
			for _, sx in { -1, 1 } do
				for _, sz in { -1, 1 } do
					rod(
						r,
						Vector3.new(sx * 2.1, 5.3, sz * 0.08),
						Vector3.new(sx * 2.1, 1.82, sz * 0.5),
						0.05,
						C.DarkMetal,
						"Metal"
					)
				end
				r:block(sx * 2.15, 1.82, -0.65, sx * 2.27, 2.5, 0.55, r.c2, "Metal")
				r:block(sx * 2.08, 2.5, -0.65, sx * 2.34, 2.58, 0.6, r.c2, "Metal")
			end
			r:block(-2.2, 1.7, -0.65, 2.2, 1.82, 0.6, r.c2, "Metal")
			r:boxAt(CFrame.new(0, 2.6, -0.74) * CFrame.Angles(-0.18, 0, 0), 4.4, 1.6, 0.1, r.c2, "Metal")
			r:block(-2.12, 1.82, -0.58, 2.12, 2.08, 0.55, r.c1, "Fabric")
			r:boxAt(CFrame.new(0, 2.62, -0.58) * CFrame.Angles(-0.18, 0, 0), 4.2, 1.3, 0.22, r.c1, "Fabric")
			for _, sx in { -1, 1 } do
				r:lump(
					CFrame.new(sx * 1.6, 2.4, -0.36) * CFrame.Angles(-0.3, sx * 0.25, sx * 0.2),
					0.7,
					0.7,
					0.24,
					if sx < 0 then C.White else shade(r.c1, 0.8),
					"Fabric"
				)
			end
			r:seat(-1.0, 2.08, 0)
			r:seat(1.0, 2.08, 0)
		end,
	},
	{
		id = "potting_bench",
		name = "Potting bench",
		cat = "tables",
		style = STYLE,
		price = 120,
		place = "floor",
		size = Vector3.new(4.4, 4.8, 2),
		surface = 2.9,
		c1 = "9C7A58",
		c2 = "B8765A",
		tags = { "table" },
		build = function(r: R)
			-- a slatted bench (c1) with a shelf under it and a board and a high shelf at the
			-- back, set out for potting: clay pots (c2) stacked and planted, a trowel, spilt
			-- earth, a sack of compost and a watering can underneath
			local tone = shade(r.c1, 0.88)
			for _, sx in { -1, 1 } do
				r:block(sx * 2.0 - 0.1, 0, 0.7, sx * 2.0 + 0.1, 2.8, 0.9, tone, "Wood")
				r:block(sx * 2.0 - 0.1, 0, -0.9, sx * 2.0 + 0.1, 4.6, -0.7, tone, "Wood")
			end
			r:piece(function(q: R)
				for i = 0, 4 do
					local z = -0.76 + i * 0.38
					q:block(
						-2.15,
						2.8,
						z - 0.17,
						2.15,
						2.9,
						z + 0.17,
						if i % 2 == 0 then r.c1 else shade(r.c1, 1.05),
						"Wood"
					)
				end
				for i = 0, 3 do
					local z = -0.66 + i * 0.44
					q:block(-1.9, 0.6, z - 0.19, 1.9, 0.7, z + 0.19, shade(r.c1, 0.95), "Wood")
				end
				for _, z in { -0.8, 0.8 } do
					q:block(-1.9, 0.48, z - 0.06, 1.9, 0.6, z + 0.06, tone, "Wood")
					q:block(-1.9, 2.62, z - 0.06, 1.9, 2.8, z + 0.06, tone, "Wood")
				end
				q:block(-1.9, 2.9, -0.7, 1.9, 3.7, -0.62, r.c1, "Wood")
				q:block(-2.15, 4.0, -0.95, 2.15, 4.1, -0.4, r.c1, "Wood")
				q:block(-2.0, 4.42, -0.9, 2.0, 4.52, -0.7, tone, "Wood")
			end, true)
			for _, sx in { -1, 1 } do
				r:tri(
					Vector3.new(sx * 1.7, 4.0, -0.7),
					Vector3.new(sx * 1.7, 4.0, -0.45),
					Vector3.new(sx * 1.7, 3.72, -0.7),
					0.08,
					tone,
					"Wood"
				)
			end
			-- pots: a stack of three on the bench, one planted, small herbs on the shelf
			r:piece(function(q: R)
				q:box(-1.4, 3.08, 0.1, 0.4, 0.36, 0.4, r.c2, "Sand")
				q:cyl(-1.4, 3.15, 0.1, 0.5, 0.56, "y", r.c2, "Sand")
				q:cyl(-1.4, 3.45, 0.1, 0.1, 0.66, "y", shade(r.c2, 1.06), "Sand")
				q:cyl(-1.4, 3.58, 0.1, 0.16, 0.52, "y", shade(r.c2, 0.95), "Sand")
				q:cyl(-1.4, 3.7, 0.1, 0.1, 0.62, "y", shade(r.c2, 1.06), "Sand")
				q:cyl(-1.4, 3.82, 0.1, 0.14, 0.5, "y", r.c2, "Sand")
				q:cyl(-1.4, 3.93, 0.1, 0.08, 0.58, "y", shade(r.c2, 1.06), "Sand")
				q:cyl(0.15, 3.12, 0.2, 0.44, 0.5, "y", r.c2, "Sand")
				q:cyl(0.15, 3.36, 0.2, 0.08, 0.58, "y", shade(r.c2, 1.06), "Sand")
				for i, x in { -1.2, -0.3, 0.6 } do
					q:cyl(x, 4.25, -0.68, 0.3, 0.32, "y", if i % 2 == 0 then r.c2 else shade(r.c2, 0.92), "Sand")
				end
				for i, x in { -1.2, -0.6, 0, 0.6, 1.2 } do
					q:cyl(
						x,
						0.9,
						-0.2 + (i % 2) * 0.25,
						0.4,
						0.42,
						"y",
						if i % 2 == 0 then r.c2 else shade(r.c2, 0.9),
						"Sand"
					)
				end
			end)
			r:piece(function(q: R)
				q:box(0.15, 3.41, 0.2, 0.4, 0.02, 0.4, C.Soil, "Grass")
				q:lump(CFrame.new(0.15, 3.62, 0.2) * CFrame.Angles(0, 0.4, 0), 0.5, 0.4, 0.46, C.Leaf, "Grass")
				q:lump(CFrame.new(0.2, 3.84, 0.15) * CFrame.Angles(0, 1.3, 0), 0.3, 0.26, 0.3, C.DarkLeaf, "Grass")
				for i, x in { -1.2, -0.3, 0.6 } do
					q:lump(
						CFrame.new(x, 4.5, -0.68) * CFrame.Angles(0, i, 0),
						0.36,
						0.3,
						0.34,
						if i == 2 then C.DarkLeaf else C.Leaf,
						"Grass"
					)
				end
				-- spilt earth on the bench
				q:lump(CFrame.new(0.9, 2.92, 0.1) * CFrame.Angles(0, 0.6, 0), 0.6, 0.08, 0.4, C.Soil, "Grass")
				q:lump(CFrame.new(1.25, 2.92, -0.2) * CFrame.Angles(0, 1.6, 0), 0.3, 0.06, 0.2, C.Soil, "Grass")
			end)
			-- a trowel, the sack and a watering can
			r:lump(CFrame.new(1.05, 2.93, 0.45) * CFrame.Angles(0, 0.3, 0), 0.24, 0.04, 0.4, C.Metal, "Metal")
			rod(r, Vector3.new(1.12, 2.95, 0.66), Vector3.new(1.2, 2.95, 0.98), 0.08, C.Bark, "Wood")
			r:lump(
				CFrame.new(1.2, 1.1, -0.1) * CFrame.Angles(0, 0.2, 0.1),
				1.0,
				0.85,
				0.8,
				Color3.fromRGB(176, 150, 110),
				"Fabric"
			)
			r:lump(CFrame.new(1.28, 1.54, -0.08), 0.5, 0.16, 0.4, Color3.fromRGB(160, 134, 96), "Fabric")
			r:piece(function(q: R)
				local can = Color3.fromRGB(96, 140, 132)
				q:box(-0.2, 0.74, 0.55, 0.3, 0.06, 0.3, shade(can, 0.85), "Metal")
				q:cyl(-0.2, 0.98, 0.55, 0.44, 0.46, "y", can, "Metal")
				q:beam(Vector3.new(-0.4, 0.95, 0.55), Vector3.new(-0.75, 1.3, 0.55), 0.07, 0.07, can, "Metal")
				q:cyl(-0.77, 1.32, 0.55, 0.06, 0.14, "x", shade(can, 0.8), "Metal")
				q:beam(Vector3.new(0.02, 1.15, 0.55), Vector3.new(-0.02, 1.32, 0.55), 0.05, 0.05, can, "Metal")
				q:beam(Vector3.new(-0.02, 1.32, 0.55), Vector3.new(-0.32, 1.32, 0.55), 0.05, 0.05, can, "Metal")
			end)
		end,
	},
	{
		id = "bistro_set",
		name = "Bistro set",
		cat = "tables",
		style = STYLE,
		price = 140,
		place = "floor",
		size = Vector3.new(4.8, 3.4, 2.2),
		surface = 2.6,
		c1 = "556B66",
		c2 = "D8CFC0",
		tags = { "table", "seat" },
		build = function(r: R)
			-- a little round iron table (c1) with a stone top (c2) and two folding chairs facing
			-- across it, a jug of flowers in the middle
			r:cyl(0, 2.55, 0, 0.1, 1.6, "y", r.c2, "Marble")
			r:cyl(0, 2.45, 0, 0.1, 1.66, "y", r.c1, "Metal")
			r:cyl(0, 1.3, 0, 2.2, 0.12, "y", r.c1, "Metal")
			r:cyl(0, 1.0, 0, 0.12, 0.22, "y", r.c1, "Metal")
			for k = 0, 2 do
				local a = k / 3 * math.pi * 2 + 0.5
				local c, s = math.cos(a), math.sin(a)
				rail(r, {
					Vector3.new(c * 0.05, 1.0, s * 0.05),
					Vector3.new(c * 0.42, 0.42, s * 0.42),
					Vector3.new(c * 0.66, 0.04, s * 0.66),
				}, 0.07, 0.07, r.c1, "Metal")
				r:ball(c * 0.68, 0.05, s * 0.68, 0.1, r.c1, "Metal")
				rod(r, Vector3.new(0, 2.0, 0), Vector3.new(c * 0.6, 2.4, s * 0.6), 0.05, r.c1, "Metal")
			end
			-- the chairs, each looking at the table
			for _, sx in { -1, 1 } do
				local cx = sx * 1.75
				local f = -sx
				r:piece(function(q: R)
					for _, z in { -0.42, 0.42 } do
						q:block(cx - 0.45, 1.44, z - 0.03, cx + 0.45, 1.52, z + 0.03, r.c1, "Metal")
						q:beam(
							Vector3.new(cx + f * 0.45, 0, z),
							Vector3.new(cx - f * 0.3, 1.46, z),
							0.06,
							0.06,
							r.c1,
							"Metal"
						)
						q:beam(
							Vector3.new(cx + f * 0.3, 1.46, z),
							Vector3.new(cx - f * 0.5, 0, z),
							0.06,
							0.06,
							r.c1,
							"Metal"
						)
						q:block(
							cx - f * 0.46 - 0.03,
							1.46,
							z - 0.03,
							cx - f * 0.46 + 0.03,
							3.25,
							z + 0.03,
							r.c1,
							"Metal"
						)
					end
					for _, d in { -0.3, -0.1, 0.1, 0.3 } do
						q:block(cx + f * d - 0.08, 1.52, -0.46, cx + f * d + 0.08, 1.6, 0.46, r.c1, "Metal")
					end
					for _, y in { 2.55, 3.05 } do
						q:block(
							cx - f * 0.46 - 0.04,
							y - 0.14,
							-0.45,
							cx - f * 0.46 + 0.04,
							y + 0.14,
							0.45,
							r.c1,
							"Metal"
						)
					end
				end, true)
				r:seat(cx, 1.6, 0, if sx < 0 then 90 else -90)
			end
			r:piece(function(q: R)
				q:box(0.15, 2.62, -0.1, 0.24, 0.04, 0.24, C.White, "SmoothPlastic")
				q:cyl(0.15, 2.82, -0.1, 0.38, 0.3, "y", C.White, "SmoothPlastic")
				q:cyl(0.15, 3.0, -0.1, 0.06, 0.24, "y", C.Blue, "SmoothPlastic")
				q:beam(Vector3.new(0.3, 2.95, -0.1), Vector3.new(0.4, 2.75, -0.1), 0.04, 0.05, C.White, "SmoothPlastic")
			end)
			r:piece(function(q: R)
				bloom(q, 0.1, -0.12, 3.0, 3.3, C.Pink, 0.4)
				bloom(q, 0.24, -0.02, 3.0, 3.22, C.Yellow, 1.5)
				bloom(q, 0.12, 0.0, 3.0, 3.36, C.White, 2.5)
			end)
		end,
	},

	-- Keeping things ----------------------------------------------------------------------------------
	{
		id = "chest_garden",
		name = "Garden chest",
		cat = "storage",
		style = STYLE,
		price = 80,
		place = "floor",
		size = Vector3.new(3.8, 2.2, 2),
		c1 = "8FA08C",
		c2 = "6E5A48",
		tags = { "storage" },
		build = function(r: R)
			-- a slatted chest for cushions and tools: painted slats (c1) between corner posts
			-- (c2), a lid with battens, iron handles at the ends, a hasp and a padlock, and a pair
			-- of gloves left on top
			for _, sx in { -1, 1 } do
				for _, sz in { -1, 1 } do
					r:block(sx * 1.6, 0, sz * 0.7, sx * 1.8, 1.7, sz * 0.9, r.c2, "Wood")
				end
			end
			r:piece(function(q: R)
				for k = 0, 3 do
					local y = 0.1 + k * 0.4
					local tone = if k % 2 == 0 then r.c1 else shade(r.c1, 0.94)
					for _, sz in { -1, 1 } do
						q:block(-1.6, y, sz * 0.75, 1.6, y + 0.34, sz * 0.85, tone, "WoodPlanks")
					end
					for _, sx in { -1, 1 } do
						q:block(sx * 1.65, y, -0.7, sx * 1.75, y + 0.34, 0.7, tone, "WoodPlanks")
					end
				end
			end, true)
			r:block(-1.85, 1.7, -0.95, 1.85, 1.86, 0.95, r.c1, "WoodPlanks")
			for _, x in { -1.2, 1.2 } do
				r:block(x - 0.1, 1.86, -0.9, x + 0.1, 1.92, 0.9, r.c2, "Wood")
			end
			r:piece(function(q: R)
				for _, sx in { -1, 1 } do
					q:block(sx * 1.88, 0.98, -0.28, sx * 1.93, 1.06, 0.28, C.DarkMetal, "Metal")
					for _, z in { -0.24, 0.24 } do
						q:block(sx * 1.8, 0.98, z - 0.04, sx * 1.88, 1.06, z + 0.04, C.DarkMetal, "Metal")
					end
				end
				q:block(-0.12, 1.42, 0.85, 0.12, 1.75, 0.9, C.DarkMetal, "Metal")
			end)
			r:block(-0.1, 1.24, 0.9, 0.1, 1.44, 0.98, C.Gold, "Metal")
			r:cyl(0, 1.48, 0.94, 0.04, 0.12, "z", C.Metal, "Metal")
			-- the gloves
			local glove = Color3.fromRGB(214, 140, 110)
			for i, p in { { -0.3, 0.1, 0.4 }, { 0.15, -0.05, -0.3 } } do
				r:lump(CFrame.new(p[1], 1.9, p[2]) * CFrame.Angles(0, p[3], 0), 0.34, 0.1, 0.5, glove, "Fabric")
				r:lump(
					CFrame.new(p[1] - math.sin(p[3]) * 0.3, 1.9, p[2] - math.cos(p[3]) * 0.3)
						* CFrame.Angles(0, p[3], 0),
					0.38,
					0.12,
					0.18,
					if i == 1 then C.Cream else shade(C.Cream, 0.92),
					"Fabric"
				)
			end
		end,
	},
	{
		id = "rack_garden_tools",
		name = "Garden tool rack",
		cat = "walldecor",
		style = STYLE,
		price = 65,
		place = "wall",
		size = Vector3.new(3.4, 5, 0.9),
		c1 = "9C7A58",
		c2 = "8A9098",
		tags = { "storage" },
		build = function(r: R)
			-- a board of planks (c1) on the wall with a rail of pegs, and the tools hung on it:
			-- a rake by its head, a spade and a fork by their grips, shears and a trowel on hooks
			-- (steel in c2), and a ball of twine
			r:piece(function(q: R)
				for i = 0, 3 do
					local x = -1.6 + i * 0.8
					q:block(
						x + 0.02,
						0.6,
						0,
						x + 0.78,
						4.7,
						0.1,
						if i % 2 == 0 then r.c1 else shade(r.c1, 0.93),
						"Wood"
					)
				end
				q:block(-1.6, 4.15, 0.1, 1.6, 4.4, 0.2, shade(r.c1, 0.85), "Wood")
				q:block(-1.6, 1.0, 0.1, 1.6, 1.2, 0.2, shade(r.c1, 0.85), "Wood")
			end)
			for _, x in { -1.3, -0.9, -0.35, 0.45, 1.15 } do
				r:cyl(x, 4.3, 0.33, 0.26, 0.1, "z", C.Bark, "Wood")
			end
			for _, y in { 3.4, 2.4 } do
				r:cyl(1.15, y, 0.33, 0.26, 0.08, "z", C.DarkMetal, "Metal")
			end
			local handle = Color3.fromRGB(176, 138, 96)
			-- the rake: its head on two pegs, tines up, the handle hanging down
			r:piece(function(q: R)
				q:block(-1.55, 4.35, 0.28, -0.65, 4.45, 0.38, r.c2, "Metal")
				for i = 0, 6 do
					local x = -1.5 + i * 0.13
					q:block(x - 0.02, 4.45, 0.31, x + 0.02, 4.68, 0.35, r.c2, "Metal")
				end
			end)
			r:cyl(-1.1, 2.4, 0.33, 3.9, 0.1, "y", handle, "Wood")
			-- the spade and the fork: a D grip over a peg, the shaft, the blade or the tines
			for _, t in { { x = -0.35, spade = true }, { x = 0.45, spade = false } } do
				local x, spade = t.x, t.spade
				r:piece(function(q: R)
					q:block(x - 0.17, 4.35, 0.28, x + 0.17, 4.43, 0.38, handle, "Wood")
					q:beam(
						Vector3.new(x - 0.15, 4.4, 0.33),
						Vector3.new(x - 0.04, 3.95, 0.33),
						0.06,
						0.06,
						handle,
						"Wood"
					)
					q:beam(
						Vector3.new(x + 0.15, 4.4, 0.33),
						Vector3.new(x + 0.04, 3.95, 0.33),
						0.06,
						0.06,
						handle,
						"Wood"
					)
				end)
				r:cyl(x, 2.9, 0.33, 2.1, 0.1, "y", handle, "Wood")
				r:piece(function(q: R)
					if spade then
						q:block(x - 0.25, 0.7, 0.3, x + 0.25, 1.6, 0.36, r.c2, "Metal")
						q:block(x - 0.27, 1.56, 0.28, x + 0.27, 1.64, 0.38, r.c2, "Metal")
						q:beam(
							Vector3.new(x, 1.6, 0.33),
							Vector3.new(x, 1.9, 0.33),
							0.14,
							0.1,
							shade(r.c2, 0.85),
							"Metal"
						)
						q:tri(
							Vector3.new(x - 0.25, 0.7, 0.33),
							Vector3.new(x + 0.25, 0.7, 0.33),
							Vector3.new(x, 0.5, 0.33),
							0.06,
							r.c2,
							"Metal"
						)
					else
						q:block(x - 0.26, 1.5, 0.29, x + 0.26, 1.62, 0.37, r.c2, "Metal")
						for i = 0, 3 do
							local tx = x - 0.21 + i * 0.14
							q:block(tx - 0.025, 0.66, 0.31, tx + 0.025, 1.5, 0.35, r.c2, "Metal")
						end
						q:beam(
							Vector3.new(x, 1.6, 0.33),
							Vector3.new(x, 1.9, 0.33),
							0.12,
							0.1,
							shade(r.c2, 0.85),
							"Metal"
						)
					end
				end)
			end
			-- shears and a trowel, each on its hook
			r:piece(function(q: R)
				q:block(1.12, 3.3, 0.3, 1.18, 3.42, 0.36, C.DarkMetal, "Metal")
				q:beam(Vector3.new(1.15, 3.3, 0.36), Vector3.new(0.98, 2.6, 0.36), 0.06, 0.03, r.c2, "Metal")
				q:beam(Vector3.new(1.15, 3.3, 0.39), Vector3.new(1.32, 2.6, 0.39), 0.06, 0.03, r.c2, "Metal")
			end)
			r:beam(
				Vector3.new(1.15, 3.32, 0.36),
				Vector3.new(0.95, 3.9, 0.36),
				0.08,
				0.05,
				Color3.fromRGB(184, 80, 90),
				"Plastic"
			)
			r:beam(
				Vector3.new(1.15, 3.32, 0.39),
				Vector3.new(1.35, 3.9, 0.39),
				0.08,
				0.05,
				Color3.fromRGB(184, 80, 90),
				"Plastic"
			)
			r:cyl(1.15, 2.1, 0.33, 0.5, 0.1, "y", handle, "Wood")
			r:lump(CFrame.new(1.15, 1.6, 0.33), 0.24, 0.5, 0.05, r.c2, "Metal")
			r:ball(-0.95, 1.38, 0.32, 0.32, Color3.fromRGB(214, 190, 140), "Fabric")
		end,
	},
	{
		id = "planter_wall_herbs",
		name = "Herb wall planter",
		gives = "herbs", -- holding E gives something (Data/Items.Sources)
		cat = "walldecor",
		style = STYLE,
		price = 45,
		place = "wall",
		size = Vector3.new(2.6, 4, 1),
		c1 = "A48462",
		c2 = "8FA3AE",
		tags = { "plant" },
		build = function(r: R)
			-- a ladder of three shelves (c1) on the wall, each with a tin pot (c2) of herbs and a
			-- wooden label: basil at the bottom, chives in flower, rosemary at the top
			local shelves = { 0.3, 1.4, 2.5 }
			r:piece(function(q: R)
				for _, sx in { -1, 1 } do
					q:block(sx * 1.08, 0, 0, sx * 1.22, 3.3, 0.12, r.c1, "Wood")
				end
				for _, y in shelves do
					q:block(-1.25, y - 0.08, 0, 1.25, y, 0.8, r.c1, "Wood")
					q:block(-1.25, y, 0.74, 1.25, y + 0.06, 0.8, shade(r.c1, 0.9), "Wood")
				end
			end)
			for _, y in shelves do
				for _, sx in { -1, 1 } do
					r:tri(
						Vector3.new(sx * 1.15, y - 0.08, 0.12),
						Vector3.new(sx * 1.15, y - 0.08, 0.66),
						Vector3.new(sx * 1.15, y - 0.5, 0.12),
						0.08,
						shade(r.c1, 0.88),
						"Wood"
					)
				end
			end
			local pots = { { -0.3, shelves[1] }, { 0.25, shelves[2] }, { -0.2, shelves[3] } }
			for _, p in pots do
				local x, y = p[1], p[2]
				r:cyl(x, y + 0.23, 0.42, 0.46, 0.6, "y", r.c2, "Metal")
				r:cyl(x, y + 0.38, 0.42, 0.08, 0.64, "y", shade(r.c2, 0.88), "Metal")
				r:cyl(x, y + 0.475, 0.42, 0.03, 0.5, "y", C.Soil, "Sand")
				r:piece(function(q: R)
					q:block(x + 0.18, y + 0.4, 0.58, x + 0.22, y + 0.7, 0.62, Color3.fromRGB(214, 190, 150), "Wood")
					q:block(x + 0.12, y + 0.66, 0.57, x + 0.28, y + 0.78, 0.63, Color3.fromRGB(214, 190, 150), "Wood")
				end)
			end
			-- basil: two layers of round leaves
			r:piece(function(q: R)
				q:box(-0.3, 0.82, 0.42, 0.1, 0.06, 0.1, C.DarkLeaf, "Grass")
				for i = 0, 9 do
					local a = i * 1.3
					local up = if i < 6 then 0 else 1
					local out = if i < 6 then 0.2 else 0.08
					q:lump(
						CFrame.new(-0.3 + math.cos(a) * out, 0.9 + up * 0.17, 0.42 + math.sin(a) * out)
							* CFrame.Angles(0.35, a, 0.3),
						0.36,
						0.13,
						0.28,
						if i % 2 == 0 then Color3.fromRGB(116, 176, 96) else C.Leaf,
						"Grass"
					)
				end
			end)
			-- chives: a clump of blades with round purple heads
			r:piece(function(q: R)
				q:box(0.25, 1.9, 0.42, 0.1, 0.04, 0.1, C.DarkLeaf, "Grass")
				for i = 0, 9 do
					local a = i * 0.7
					local x, z = 0.25 + math.cos(a) * 0.13, 0.42 + math.sin(a) * 0.11
					q:block(x - 0.02, 1.88, z - 0.02, x + 0.02, 2.2 + (i % 3) * 0.05, z + 0.02, C.Leaf, "Grass")
				end
			end)
			r:piece(function(q: R)
				q:box(0.25, 2.28, 0.42, 0.06, 0.06, 0.06, LILAC, "SmoothPlastic")
				for _, p in { { 0.15, 2.31, 0.47 }, { 0.36, 2.34, 0.4 }, { 0.26, 2.37, 0.32 }, { 0.2, 2.27, 0.36 } } do
					q:ball(p[1], p[2], p[3], 0.16, LILAC, "SmoothPlastic")
				end
			end)
			-- rosemary: upright grey green sprigs
			r:piece(function(q: R)
				q:box(-0.2, 3.0, 0.42, 0.1, 0.04, 0.1, Color3.fromRGB(92, 124, 104), "Grass")
				for i = 0, 10 do
					local a = i * 1.1
					local out = if i < 7 then 0.16 else 0.06
					local h = 0.75 + (i % 3) * 0.12
					q:add({
						shape = "Cone",
						cf = CFrame.new(-0.2 + math.cos(a) * out, 2.98 + h / 2, 0.42 + math.sin(a) * out * 0.8)
							* CFrame.Angles(math.sin(a) * 0.22, 0, math.cos(a) * -0.22),
						size = Vector3.new(0.16, h, 0.16),
						color = if i % 2 == 0 then Color3.fromRGB(92, 124, 104) else Color3.fromRGB(116, 146, 122),
						mat = "Grass",
					})
				end
			end)
		end,
	},

	-- Lights ----------------------------------------------------------------------------------------
	{
		id = "lantern_garden",
		name = "Garden lantern",
		cat = "lights",
		style = STYLE,
		price = 60,
		place = "ground",
		size = Vector3.new(1.2, 4.6, 1.2),
		c1 = "4A524F",
		c2 = "7E9E8A",
		tags = { "light" },
		build = function(r: R)
			-- a short iron post (c1) with a square glazed lantern on top under a little roof
			-- (c2), a candle burning in it, and grass round its foot
			r:cyl(0, 0.08, 0, 0.16, 0.8, "y", r.c1, "Metal")
			r:cyl(0, 0.24, 0, 0.16, 0.5, "y", r.c1, "Metal")
			r:cyl(0, 1.75, 0, 2.9, 0.18, "y", r.c1, "Metal")
			r:cyl(0, 1.2, 0, 0.12, 0.28, "y", r.c2, "Metal")
			r:cyl(0, 3.1, 0, 0.16, 0.34, "y", r.c2, "Metal")
			r:block(-0.36, 3.2, -0.36, 0.36, 3.28, 0.36, r.c1, "Metal")
			for _, sx in { -1, 1 } do
				for _, sz in { -1, 1 } do
					r:block(
						sx * 0.33 - 0.03,
						3.28,
						sz * 0.33 - 0.03,
						sx * 0.33 + 0.03,
						4.0,
						sz * 0.33 + 0.03,
						r.c1,
						"Metal"
					)
				end
				r:glass(-0.3, 3.28, sx * 0.31 - 0.01, 0.3, 4.0, sx * 0.31 + 0.01)
				r:glass(sx * 0.31 - 0.01, 3.28, -0.3, sx * 0.31 + 0.01, 4.0, 0.3)
			end
			r:block(-0.4, 4.0, -0.4, 0.4, 4.06, 0.4, r.c1, "Metal")
			r:cone(0, 4.22, 0, 0.32, 0.9, r.c2, "Metal")
			r:ball(0, 4.44, 0, 0.16, r.c2, "Metal")
			r:cyl(0, 3.45, 0, 0.34, 0.16, "y", C.Cream, "SmoothPlastic")
			r:glow(r:lump(CFrame.new(0, 3.72, 0), 0.08, 0.16, 0.08, C.Warm, "SmoothPlastic"), 16, 1.1)
			r:piece(function(q: R)
				q:box(0.42, 0.02, 0.1, 0.08, 0.04, 0.08, C.DarkLeaf, "Grass")
				tuft(q, 0.42, 0.1, 0, 0.3)
				tuft(q, -0.4, 0.3, 0, 1.7)
				tuft(q, 0.1, -0.45, 0, 2.6, 0.18)
			end)
		end,
	},
	{
		id = "jar_fireflies",
		name = "Firefly jar",
		cat = "lights",
		style = STYLE,
		price = 25,
		place = "surface",
		size = Vector3.new(0.8, 1.3, 0.8),
		c1 = "C9A27A",
		c2 = "F2E48C",
		tags = { "light" },
		build = function(r: R)
			-- a glass jar with a cloth (c1) tied over its neck and a wire handle, grass in the
			-- bottom and fireflies (c2) glowing inside
			r:cyl(0, 0.03, 0, 0.06, 0.62, "y", Color3.fromRGB(176, 210, 206), "Glass")
			r:cyl(0, 0.48, 0, 0.84, 0.64, "y", C.Glass, "Glass").transp = 0.6
			r:cyl(0, 0.95, 0, 0.1, 0.48, "y", C.Glass, "Glass").transp = 0.6
			r:cyl(0, 0.95, 0, 0.05, 0.53, "y", C.Cream, "Fabric")
			r:cyl(0, 1.03, 0, 0.08, 0.56, "y", r.c1, "Fabric")
			for k = 0, 3 do
				local a = k * math.pi / 2 + 0.4
				r:lump(
					CFrame.new(math.cos(a) * 0.27, 0.97, math.sin(a) * 0.27) * CFrame.Angles(0, -a, 0.2),
					0.08,
					0.14,
					0.18,
					shade(r.c1, 0.9),
					"Fabric"
				)
			end
			for _, sx in { -1, 1 } do
				r:beam(Vector3.new(sx * 0.27, 0.95, 0), Vector3.new(0, 1.26, 0), 0.03, 0.03, C.DarkMetal, "Metal")
			end
			r:piece(function(q: R)
				q:box(0, 0.08, 0, 0.3, 0.04, 0.3, C.DarkLeaf, "Grass")
				tuft(q, -0.08, 0.05, 0.06, 0.2, 0.3)
				tuft(q, 0.12, -0.08, 0.06, 1.4, 0.26)
			end)
			local light = Colors.mix(r.c2, C.Leaf, 0.2)
			for i, p in
				{
					{ 0.1, 0.5, 0.05 },
					{ -0.12, 0.66, -0.08 },
					{ 0.05, 0.78, 0.14 },
					{ -0.15, 0.36, 0.12 },
					{ 0.17, 0.3, -0.1 },
					{ 0.0, 0.58, -0.17 },
				}
			do
				local fly = r:ball(p[1], p[2], p[3], 0.07, r.c2, "SmoothPlastic")
				if i == 1 then
					r:glow(fly, 8, 0.8, light)
				else
					r:glow(fly, 0)
				end
			end
		end,
	},

	-- Games -----------------------------------------------------------------------------------------
	{
		id = "croquet_set",
		name = "Croquet set",
		cat = "fun",
		style = STYLE,
		price = 70,
		place = "ground",
		size = Vector3.new(4.4, 1.6, 3.2),
		c1 = "A07E5C",
		c2 = "5C7FA3",
		tags = { "games" },
		build = function(r: R)
			-- a lawn game laid out: two white hoops, the striped winning peg, two mallets (c1
			-- with a band of c2) dropped on the grass and four balls
			local white = C.White
			for _, h in { { 0.9, 0.5, 0 }, { -0.6, -0.9, math.pi / 2 } } do
				local frame = CFrame.new(h[1], 0, h[2]) * CFrame.Angles(0, h[3], 0)
				local across = h[3] ~= 0
				r:piece(function(q: R)
					-- the top bar first, square to the plot (a piece hangs on a box that isn't turned)
					q:box(
						h[1],
						0.7,
						h[2],
						if across then 0.06 else 0.3,
						0.06,
						if across then 0.3 else 0.06,
						white,
						"Metal"
					)
					for _, sx in { -1, 1 } do
						q:boxAt(frame * CFrame.new(sx * 0.27, 0.32, 0), 0.06, 0.64, 0.06, white, "Metal")
					end
					for _, sx in { -1, 1 } do
						q:boxAt(
							frame * CFrame.new(sx * 0.21, 0.67, 0) * CFrame.Angles(0, 0, sx * 0.75),
							0.16,
							0.06,
							0.06,
							white,
							"Metal"
						)
					end
				end)
			end
			r:cyl(1.7, 0.65, -1.1, 1.3, 0.14, "y", white, "Wood")
			for i, col in { C.Blue, C.Red, C.Black, C.Yellow } do
				r:cyl(1.7, 0.72 + i * 0.12, -1.1, 0.1, 0.18, "y", col, "Wood")
			end
			r:ball(1.7, 1.33, -1.1, 0.16, white, "Wood")
			-- the mallets: a shaft, a head across its end with a coloured band at each face
			local function mallet(frame: CFrame, band: Color3)
				r:boxAt(frame * CFrame.new(1.2, 0, 0), 2.4, 0.08, 0.08, shade(r.c1, 1.1), "Wood")
				r:boxAt(frame * CFrame.new(2.3, 0, 0), 0.3, 0.14, 0.14, C.Bark, "Wood")
				r:add({
					shape = "Cylinder",
					cf = frame * CFrame.new(-0.1, 0.06, 0) * CFrame.Angles(0, math.pi / 2, 0),
					size = Vector3.new(0.8, 0.3, 0.3),
					color = r.c1,
					mat = "Wood",
				})
				for _, s in { -1, 1 } do
					r:add({
						shape = "Cylinder",
						cf = frame * CFrame.new(-0.1, 0.06, s * 0.32) * CFrame.Angles(0, math.pi / 2, 0),
						size = Vector3.new(0.06, 0.36, 0.36),
						color = band,
						mat = "Wood",
					})
				end
			end
			mallet(CFrame.new(-1.6, 0.15, 1.15), r.c2)
			mallet(CFrame.new(-1.75, 0.15, -1.2) * CFrame.Angles(0, -math.pi / 2 + 0.25, 0), C.Red)
			for _, b in
				{
					{ x = 0.2, z = 0.9, c = C.Blue },
					{ x = 1.45, z = -0.2, c = C.Red },
					{ x = -0.2, z = -0.2, c = C.Black },
					{ x = 0.8, z = 1.3, c = C.Yellow },
				}
			do
				r:ball(b.x, 0.17, b.z, 0.34, b.c, "Plastic")
			end
		end,
	},
	-- (end of items)
}

return items
