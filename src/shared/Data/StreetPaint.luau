--!strict
-- What is laid flat on the town's ground on top of its streets and paving: patterns in the
-- paving, markings, covers and gratings (see docs/GAME_DESIGN.md, "A denser, more detailed
-- town"). TownMap.ground adds these to its own list.
--
-- Everything is worked out by rule from Town.Roads and the square's own spots, so it stays right
-- when buildings move: a stop line, an arrow, tactile paving and a yellow kerb at every
-- crossing; manhole covers and kerb gratings along every street; a cycle lane each side of Main
-- Street and a bus bay at its stop; bays painted where the cars park on the side streets; rings
-- of stone round the fountain, tiled aprons in front of the square's buildings, bands in front
-- of the hall, a threshold under the gate.
--
-- Nothing here stands up or can be bumped into. Each mark is a thin box (or a piece of thin
-- boxes) lying on the surface it belongs to, a hair above whatever TownMap.ground has already
-- laid there, so two flat faces never share a height and flicker.

local Recipe = require(script.Parent.Parent.Build.Recipe)
local Geometry = require(script.Parent.Parent.Build.Geometry)
local Rng = require(script.Parent.Parent.Util.Rng)
local Town = require(script.Parent.Town)

type R = Recipe.Recipe
type Prim = Geometry.Prim
type Region = { number }

local StreetPaint = {}

local function rgb(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end

local WHITE = rgb(250, 250, 246)
local YELLOW = rgb(255, 210, 70)
local TACTILE = rgb(250, 196, 50)
local TACTILE_DARK = rgb(226, 168, 36)
local IRON = rgb(70, 74, 86)
local IRON_LIGHT = rgb(104, 108, 122)
local CYCLE = rgb(176, 86, 74)
local SAND = rgb(228, 216, 194)
local SLATE = rgb(170, 176, 188)
local JOINT = rgb(120, 126, 140)
local TILE_LIGHT = rgb(244, 236, 214)
local TILE_DARK = rgb(92, 150, 146)

-- Heights. The road's surface, a sidewalk's and the square's paving are TownMap.ground's.
local ROAD = 0.05
local WALK = 0.3
local PAVING = 0.27
local KERB = 0.42 -- the top of a kerb stone
StreetPaint.Heights = { road = ROAD, walk = WALK, paving = PAVING }

-- The main street's bus stop (TownMap stands the shelter there and World/Ambience pulls the bus
-- in at it), on the south side.
local BUS_STOP_X = 96

-- Pieces --------------------------------------------------------------------------------------------------

-- Each mark is drawn once round the origin and stamped where it is wanted (see Data/Landmarks).
-- A mark on a road is drawn for somebody travelling along it: ahead is local -Z, their right
-- hand is local +X, and the road's surface is y = 0.
local protos: { [string]: Prim } = {}
local function proto(id: string, draw: (R) -> ()): Prim
	local made = protos[id]
	if not made then
		local q = Recipe.new(WHITE, WHITE)
		draw(q)
		made = Geometry.piece(q.prims, false)
		protos[id] = made
	end
	return made
end

-- A frame at (x, y, z) for somebody heading (fx, fz).
local function heading(x: number, y: number, z: number, fx: number, fz: number): CFrame
	return CFrame.new(x, y, z) * CFrame.Angles(0, math.atan2(-fx, -fz), 0)
end

local function manhole(q: R)
	q:cyl(0, 0.015, 0, 0.03, 3.2, "y", IRON, "Metal")
	q:cyl(0, 0.019, 0, 0.038, 2.6, "y", IRON_LIGHT, "Metal")
	q:box(0, 0.022, 0, 2.3, 0.044, 0.3, IRON, "Metal")
	q:box(0, 0.022, 0, 0.3, 0.044, 2.3, IRON, "Metal")
	q:cyl(0, 0.025, 0, 0.05, 0.8, "y", IRON_LIGHT, "Metal")
end

-- A grating in the gutter, its long side along the kerb.
local function grating(q: R)
	q:box(0, 0.016, 0, 1.1, 0.032, 3.2, IRON, "Metal")
	for i = -2, 2 do
		q:box(0, 0.02, i * 0.58, 0.8, 0.04, 0.26, rgb(40, 42, 52), "Metal")
	end
end

-- Six studs of tactile paving at a crossing: yellow, with raised bars.
local function tactile(q: R)
	q:box(0, 0.012, 0, 1.3, 0.024, 6, TACTILE, "Concrete")
	for i = 0, 6 do
		q:box(0, 0.02, -2.7 + i * 0.9, 1, 0.04, 0.34, TACTILE_DARK, "Concrete")
	end
end

-- A stop line across the lane, and an arrow on the way up to it. `half` is the road's half
-- width, `lane` how far out the middle of the lane is.
local function stopLine(half: number, lane: number): (R) -> ()
	return function(q: R)
		q:box((half - 0.5) / 2 + 0.4, 0.016, 0, half - 1.3, 0.032, 0.9, WHITE, "SmoothPlastic")
		q:box(lane, 0.016, 13.2, 0.5, 0.032, 4, WHITE, "SmoothPlastic")
		q:tri(
			Vector3.new(lane, 0.016, 8.6),
			Vector3.new(lane - 1, 0.016, 11.2),
			Vector3.new(lane + 1, 0.016, 11.2),
			0.032,
			WHITE,
			"SmoothPlastic"
		)
	end
end

-- Parking bays at the kerb, `count` of them in a row, thirteen studs each.
local function bays(half: number, count: number): (R) -> ()
	return function(q: R)
		local long = 13 * count
		q:box(half - 5.6, 0.014, 0, 0.3, 0.028, long + 0.3, WHITE, "SmoothPlastic")
		for i = 0, count do
			q:box(half - 3.1, 0.014, -long / 2 + i * 13, 4.7, 0.028, 0.3, WHITE, "SmoothPlastic")
		end
	end
end

-- A bicycle and a chevron, painted in a cycle lane.
local function bicycle(q: R)
	q:box(0, 0.016, 0.1, 0.22, 0.032, 2.2, WHITE, "SmoothPlastic")
	for _, z in { -1.1, 1.3 } do
		q:cyl(0, 0.014, z, 0.028, 1.4, "y", WHITE, "SmoothPlastic")
		q:cyl(0, 0.017, z, 0.034, 0.86, "y", CYCLE, "SmoothPlastic")
	end
	q:box(0, 0.018, -0.5, 1, 0.036, 0.2, WHITE, "SmoothPlastic")
	q:boxAt(
		CFrame.new(-0.42, 0.016, -3.3) * CFrame.Angles(0, math.rad(40), 0),
		0.24,
		0.032,
		1.3,
		WHITE,
		"SmoothPlastic"
	)
	q:boxAt(
		CFrame.new(0.42, 0.016, -3.3) * CFrame.Angles(0, math.rad(-40), 0),
		0.24,
		0.032,
		1.3,
		WHITE,
		"SmoothPlastic"
	)
end

-- A bus bay: a yellow box at the kerb, hatched.
local function busBay(q: R)
	local long, wide = 26, 3.4
	for _, sx in { -1, 1 } do
		q:box(sx * wide / 2, 0.016, 0, 0.3, 0.032, long, YELLOW, "SmoothPlastic")
	end
	for _, sz in { -1, 1 } do
		q:box(0, 0.016, sz * long / 2, wide + 0.3, 0.032, 0.3, YELLOW, "SmoothPlastic")
	end
	for i = -2, 2 do
		q:boxAt(
			CFrame.new(0, 0.016, i * 5.2) * CFrame.Angles(0, math.rad(50), 0),
			0.3,
			0.032,
			4.2,
			YELLOW,
			"SmoothPlastic"
		)
	end
end

-- A yellow box across a junction, crossed corner to corner.
local function junctionBox(w: number, d: number): (R) -> ()
	return function(q: R)
		for _, sx in { -1, 1 } do
			q:box(sx * w / 2, 0.016, 0, 0.36, 0.032, d + 0.36, YELLOW, "SmoothPlastic")
		end
		for _, sz in { -1, 1 } do
			q:box(0, 0.016, sz * d / 2, w, 0.032, 0.36, YELLOW, "SmoothPlastic")
		end
		-- three lines each way, parallel to the box's own diagonals
		local long = math.sqrt(w * w + d * d)
		for _, s in { -1, 1 } do
			local turn = CFrame.Angles(0, math.atan2(w, s * d), 0)
			for _, k in { -0.5, 0, 0.5 } do
				local at = turn * CFrame.new(k * w * d / long, 0.016, 0)
				q:boxAt(at, 0.3, 0.032, long * (1 - math.abs(k)) - 1, YELLOW, "SmoothPlastic")
			end
		end
	end
end

-- A checker of tiles, eight studs by six.
local function checker(q: R)
	q:box(0, 0.01, 0, 8, 0.02, 6, TILE_LIGHT, "CeramicTiles")
	for i = 0, 3 do
		for j = 0, 2 do
			if (i + j) % 2 == 0 then
				q:box(-3 + i * 2, 0.014, -2 + j * 2, 2, 0.028, 2, TILE_DARK, "CeramicTiles")
			end
		end
	end
end

-- The joints of the fountain's rings: short lines out from the middle, in two rounds.
local function spokes(q: R)
	for i = 0, 11 do
		local a = i / 12 * math.pi * 2
		local turn = CFrame.Angles(0, -a, 0)
		q:boxAt(turn * CFrame.new(16.55, 0.005, 0), 3.1, 0.01, 0.22, JOINT, "Pavement")
		local b = a + math.pi / 12
		q:boxAt(CFrame.Angles(0, -b, 0) * CFrame.new(22.25, 0.005, 0), 2.5, 0.01, 0.22, JOINT, "Pavement")
	end
end

-- Roads ---------------------------------------------------------------------------------------------------

type Cross = { at: number, half: number, walk: number }
type Road = {
	along: boolean, -- runs along X
	at: number, -- its middle line's z (or x)
	a1: number,
	a2: number,
	half: number,
	walk: number,
	main: boolean,
	cross: { Cross },
}

-- The roads as this file wants them, each with the roads that cross it (as TownMap.crossings).
local function roads(): { Road }
	local out: { Road } = {}
	for _, road in Town.Roads do
		local along = road[2] == road[4]
		local a1 = if along then math.min(road[1], road[3]) else math.min(road[2], road[4])
		local a2 = if along then math.max(road[1], road[3]) else math.max(road[2], road[4])
		local at = if along then road[2] else road[1]
		local cross: { Cross } = {}
		for _, o in Town.Roads do
			if o ~= road and (o[2] == o[4]) ~= along then
				local oAt = if along then o[1] else o[2]
				local o1 = if along then math.min(o[2], o[4]) else math.min(o[1], o[3])
				local o2 = if along then math.max(o[2], o[4]) else math.max(o[1], o[3])
				if oAt >= a1 - 1 and oAt <= a2 + 1 and at >= o1 - 1 and at <= o2 + 1 then
					table.insert(cross, { at = oAt, half = o[5], walk = o[6] })
				end
			end
		end
		table.sort(cross, function(a, b)
			return a.at < b.at
		end)
		table.insert(out, {
			along = along,
			at = at,
			a1 = a1,
			a2 = a2,
			half = road[5],
			walk = road[6],
			main = road.name == "Main Street",
			cross = cross,
		})
	end
	return out
end

-- How far `u` along a road is from the corner of the nearest junction (less than 0 inside one).
local function fromJunction(road: Road, u: number): number
	local least = math.huge
	for _, c in road.cross do
		least = math.min(least, math.abs(u - c.at) - c.half - c.walk)
	end
	return least
end

-- Where people cross a road on a zebra: { u, half the crossing's width }. The ones TownMap
-- paints just outside each junction, the main street's own three, and the one this file adds on
-- Hill Road at the foot of the stair.
StreetPaint.StairCrossing = 0 -- its x on Hill Road
local function zebras(road: Road): { { number } }
	local out: { { number } } = {}
	for _, c in road.cross do
		for _, dir in { -1, 1 } do
			local u = c.at + dir * (c.half + c.walk + 4)
			if u > road.a1 + 4 and u < road.a2 - 4 then
				table.insert(out, { u, 3, dir })
			end
		end
	end
	if road.main then
		for _, x in { 0, -274, 274 } do
			table.insert(out, { x, 6, 0 })
		end
	elseif road.along and road.at == Town.RingZ then
		table.insert(out, { StreetPaint.StairCrossing, 3, 0 })
	end
	return out
end

-- Where the cars stand at the kerb on the side streets: { road, u, side }. TownMap parks them
-- with this same seeded walk (its "cars parked at the kerb"), so a bay is painted under each.
type Spot = { road: Road, u: number, side: number }
local function parked(all: { Road }): { Spot }
	local out: { Spot } = {}
	local parking = Rng.new(41)
	for k, road in all do
		if k > 1 then
			local u = road.a1 + 40 + parking:float(0, 30)
			while u < road.a2 - 40 do
				local side = if parking:chance(0.5) then 1 else -1
				if fromJunction(road, u) >= 14 then
					parking:int(1, 6) -- (which car it is: drawn to keep in step with TownMap)
					table.insert(out, { road = road, u = u, side = side })
				end
				u += 70 + parking:float(0, 50)
			end
		end
	end
	return out
end

-- Where a bay is painted for a parked car, for the specs: the car's own spot.
function StreetPaint.parked(): { Vector3 }
	local out: { Vector3 } = {}
	for _, spot in parked(roads()) do
		local road, u, side = spot.road, spot.u, spot.side
		local v = side * (road.half - 2.8)
		table.insert(out, if road.along then Vector3.new(u, 0, road.at + v) else Vector3.new(road.at + v, 0, u))
	end
	return out
end

-- The ground ------------------------------------------------------------------------------------------------

-- The primitives inside `region` ({ x1, z1, x2, z2 }), or all of them.
function StreetPaint.ground(region: Region?): { Prim }
	local r = Recipe.new(WHITE, WHITE)

	-- a flat box between two corners, cut to the region
	local function flat(
		x1: number,
		z1: number,
		x2: number,
		z2: number,
		y1: number,
		y2: number,
		color: Color3,
		mat: string?
	)
		if x1 > x2 then
			x1, x2 = x2, x1
		end
		if z1 > z2 then
			z1, z2 = z2, z1
		end
		if region then
			x1, z1, x2, z2 =
				math.max(x1, region[1]), math.max(z1, region[2]), math.min(x2, region[3]), math.min(z2, region[4])
		end
		if x1 < x2 and z1 < z2 then
			r:block(x1, y1, z1, x2, y2, z2, color, mat).collide = false
		end
	end
	-- a piece, kept whole when its middle is in the region
	local function mark(id: string, at: CFrame, draw: (R) -> ())
		if region and (at.X < region[1] or at.X > region[3] or at.Z < region[2] or at.Z > region[4]) then
			return
		end
		local made = proto(id, draw)
		local p = table.clone(made)
		p.cf = at * made.cf
		r:add(p)
	end

	local all = roads()
	for _, road in all do
		local hw = road.half
		-- (u along, v across) to the world, and the frame of somebody travelling along it
		local function xz(u: number, v: number): (number, number)
			if road.along then
				return u, road.at + v
			end
			return road.at + v, u
		end
		-- `s` is 1 for travelling toward greater u. They keep to their right: that is v > 0 on a
		-- road along X and v < 0 on one along Z.
		local function going(u: number, v: number, y: number, s: number): CFrame
			local x, z = xz(u, v)
			return heading(x, y, z, if road.along then s else 0, if road.along then 0 else s)
		end
		local function right(s: number): number
			return if road.along then s else -s
		end
		local function rect(
			u1: number,
			v1: number,
			u2: number,
			v2: number,
			y1: number,
			y2: number,
			col: Color3,
			mat: string?
		)
			local xa, za = xz(u1, v1)
			local xb, zb = xz(u2, v2)
			flat(xa, za, xb, zb, y1, y2, col, mat)
		end
		local lane = if road.main then 6.5 else 2.9

		local crossingsHere = zebras(road)
		for _, zebra in crossingsHere do
			local u, half, dir = zebra[1], zebra[2], zebra[3]
			-- tactile paving on both kerbs
			for _, side in { -1, 1 } do
				for k = 1, half / 3 do
					local uk = u - half + 3 + (k - 1) * 6
					mark("tactile", going(uk, side * (hw + 1.35), WALK, 1), tactile)
				end
			end
			-- where the traffic waits: on the far side from a junction, on both sides of a
			-- crossing that stands alone
			for _, s in { -1, 1 } do
				if dir == 0 or s == -dir then
					mark("stop:" .. hw, going(u - s * (half + 2.5), 0, ROAD, s), stopLine(hw, lane))
				end
			end
			-- the kerb painted yellow on the way up to it: no stopping here
			for _, s in { -1, 1 } do
				if dir == 0 or s == -dir then
					for _, side in { -1, 1 } do
						local u1, u2 = u - s * (half + 0.5), u - s * (half + 8.5)
						rect(u1, side * hw, u2, side * (hw + 0.6), KERB, KERB + 0.025, YELLOW)
					end
				end
			end
			-- the stair's crossing has no stripes of TownMap's, so they are painted here
			if dir == 0 and not road.main then
				local v = -hw + 1.6
				while v < hw - 2.6 do
					rect(u - half, v, u + half, v + 1.6, ROAD, ROAD + 0.032, WHITE)
					v += 2.8
				end
			end
		end
		-- no closer to a crossing than this is anything else painted along the kerb
		local function nearZebra(u: number, room: number): boolean
			for _, zebra in crossingsHere do
				if math.abs(u - zebra[1]) < zebra[2] + room then
					return true
				end
			end
			return false
		end

		-- a manhole cover in one lane every so often (half way between the square covers
		-- TownMap lays, and in the other lane), and gratings in both gutters
		local m, turn = road.a1 + 105, 0
		while m < road.a2 - 40 do
			if fromJunction(road, m) > 12 and not nearZebra(m, 6) then
				local v = if turn % 2 == 0 then -hw * 0.45 else hw * 0.45
				mark("manhole", going(m, v, ROAD, 1), manhole)
			end
			m += 118
			turn += 1
		end
		local g, n = road.a1 + 76, 0
		while g < road.a2 - 30 do
			if fromJunction(road, g) > 9 and not nearZebra(g, 5) then
				-- (TownMap has a plain drain on the v > 0 side at every other one of these)
				for _, side in { -1, 1 } do
					if side < 0 or n % 2 == 1 then
						mark("grating", going(g, side * (hw - 0.75), ROAD, 1), grating)
					end
				end
			end
			g += 59
			n += 1
		end

		if road.main then
			-- a cycle lane along each kerb, broken at the junctions, the crossings and the bus bay
			for _, s in { -1, 1 } do
				local side = right(s)
				local u = road.a1 + 6
				local from: number? = nil
				local function close(to: number)
					if from and to - from > 14 then
						rect(from, side * 10.6, to, side * 13.2, ROAD, ROAD + 0.024, CYCLE, "Asphalt")
						rect(from, side * 10.2, to, side * 10.5, ROAD, ROAD + 0.03, WHITE)
						local b = from + 9
						while b < to - 6 do
							mark("bicycle", going(b, side * 11.9, ROAD + 0.024, s), bicycle)
							b += 88
						end
					end
					from = nil
				end
				while u < road.a2 - 6 do
					local busy = fromJunction(road, u) < 11
						or nearZebra(u, 4)
						or (side < 0 and math.abs(u - BUS_STOP_X) < 15)
					if busy then
						close(u)
					elseif not from then
						from = u
					end
					u += 1
				end
				close(u)
			end
			mark("busBay", going(BUS_STOP_X, -11.9, ROAD, -1), busBay)
			-- a yellow box where the avenues cross
			for _, c in road.cross do
				if math.abs(c.at) < Town.HalfLength - 60 then
					local id = string.format("box:%dx%d", 2 * c.half - 2, 2 * hw - 2)
					mark(id, CFrame.new(c.at, ROAD, road.at), junctionBox(2 * c.half - 2, 2 * hw - 2))
				end
			end
		end
	end

	-- bays where the cars park
	for _, spot in parked(all) do
		local road, u, side = spot.road, spot.u, spot.side
		-- three in a row where there is room, one where a crossing is near, none right by one
		local room = fromJunction(road, u)
		local count = 0
		for _, n in { 3, 1 } do
			local fits = room >= 10.5 + n * 6.5
			for _, zebra in zebras(road) do
				if math.abs(u - zebra[1]) < zebra[2] + 4 + n * 6.5 then
					fits = false
				end
			end
			if fits and count == 0 then
				count = n
			end
		end
		if count > 0 then
			local s = if road.along then side else -side
			local x, z = u, road.at
			if not road.along then
				x, z = road.at, u
			end
			local id = string.format("bays:%d:%d", road.half, count)
			mark(
				id,
				heading(x, ROAD, z, if road.along then s else 0, if road.along then 0 else s),
				bays(road.half, count)
			)
		end
	end

	-- the square -------------------------------------------------------------------------------------
	local f = Town.Spots.Fountain
	if
		not region or (region[1] < f.X + 26 and region[3] > f.X - 26 and region[2] < f.Z + 26 and region[4] > f.Z - 26)
	then
		-- rings of two stones round the fountain, each a little higher than the one outside it
		local rings: { { r: number, c: Color3 } } = {
			{ r = 24, c = JOINT },
			{ r = 23.5, c = SAND },
			{ r = 21, c = SLATE },
			{ r = 18.6, c = JOINT },
			{ r = 18.1, c = SAND },
			{ r = 15, c = SLATE },
			{ r = 12.4, c = JOINT },
			{ r = 11.9, c = SAND },
		}
		local top = PAVING + 0.05
		for _, ring in rings do
			local disc = r:cyl(f.X, (PAVING + top) / 2, f.Z, top - PAVING, ring.r * 2, "y", ring.c, "Pavement")
			disc.collide = false
			top += 0.005
		end
		local made = proto("spokes", spokes)
		local p = table.clone(made)
		p.cf = CFrame.new(f.X, top, f.Z) * made.cf
		r:add(p)
	end
	-- tiled aprons in front of the tailor, the notice board and the shop
	local function apron(x1: number, z1: number, modules: number)
		for i = 0, modules - 1 do
			mark("checker", CFrame.new(x1 + 4 + i * 8, PAVING, z1 + 3), checker)
		end
	end
	local S = Town.Spots
	apron(S.Tailor.X - 12, S.Tailor.Z - 16, 3)
	apron(S.Board.X - 8, S.Board.Z - 7.4, 2)
	apron(S.Shop.X - 12, S.Shop.Z + 10, 3)
	-- bands of stone in front of the hall
	for i = 0, 2 do
		local z1 = S.Hall.Z + 8.4 + i * 3.8
		flat(
			S.Hall.X - 16,
			z1,
			S.Hall.X + 16,
			z1 + 3.8,
			PAVING,
			PAVING + 0.03 + i * 0.002,
			if i % 2 == 0 then SLATE else SAND,
			"Pavement"
		)
	end
	-- the threshold under the gate: a band of stone across the way in, edged, with a darker
	-- panel under each bay
	local edge = Town.StreetHalfWidth + Town.SidewalkWidth
	local sq = Town.SquareCenter
	flat(sq.X - 19.5, edge + 0.3, sq.X + 19.5, edge + 4.7, PAVING, PAVING + 0.03, SAND, "Pavement")
	flat(sq.X - 19.5, edge + 0.3, sq.X + 19.5, edge + 0.7, PAVING, PAVING + 0.036, JOINT, "Pavement")
	flat(sq.X - 19.5, edge + 4.3, sq.X + 19.5, edge + 4.7, PAVING, PAVING + 0.036, JOINT, "Pavement")
	flat(sq.X - 5.6, edge + 1.3, sq.X + 5.6, edge + 3.7, PAVING, PAVING + 0.036, SLATE, "Pavement")
	for _, sx in { -1, 1 } do
		flat(sq.X + sx * 9.4, edge + 1.3, sq.X + sx * 15.4, edge + 3.7, PAVING, PAVING + 0.036, SLATE, "Pavement")
	end
	return r.prims
end

return StreetPaint
