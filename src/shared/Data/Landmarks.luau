--!strict
-- The town's set pieces: the things you find your way by (see docs/GAME_DESIGN.md, "A denser,
-- more detailed town"). TownMap.prims asks here for a model by name, and TownMap.placements adds
-- where they stand before the street scene goes on round them.
--
--   marketGate      three bays of brick piers and timber beams under tiled roofs, a name board
--                   and a clock turret, at the way into the square from Main Street
--   marketMast      a banner mast, one each side of the gate at the kerb
--   marketHall      an open hall of iron columns under one long tiled roof, five stalls inside
--                   and a canvas awning over each, along the square's west side
--   marketTentA/B, marketCart, marketGoods   loose stalls and their stock on the east side
--   footbridge      a steel footbridge over Main Street between the plots east of the square
--   hillStair       the stepped street up the hill from Hill Road: a court, broad steps, four
--                   steep flights with landings, railings and stone lanterns
--   lookoutBluff    the rock the stair climbs beside, with a paved terrace on top
--   lookoutShelter  the shelter on that terrace
--   outcropA/B, stoneLantern   rocks and lamps beside the stair
--
-- All Maplewick's own designs. Each is a recipe drawn round its own middle, front facing local
-- -Z. Every detail that repeats is a piece (Geometry.piece): it is drawn once at the origin and
-- stamped wherever it is wanted, turned if need be, so the same shapes always make the same key
-- and the server merges each only once.

local Recipe = require(script.Parent.Parent.Build.Recipe)
local Geometry = require(script.Parent.Parent.Build.Geometry)
local Hills = require(script.Parent.Hills)
local Town = require(script.Parent.Town)

type R = Recipe.Recipe
type Prim = Geometry.Prim
export type Placement = { name: string, cf: CFrame, action: string?, opens: string?, tag: string? }

local Landmarks = {}
Landmarks.Models = {} :: { [string]: (R) -> () }
local M = Landmarks.Models

local function rgb(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end

local function shade(c: Color3, k: number): Color3
	return Color3.new(math.min(1, c.R * k), math.min(1, c.G * k), math.min(1, c.B * k))
end

-- One palette for all of them, so the gate, the hall, the bridge and the stair read as one town's.
local WHITE = rgb(250, 250, 248)
local CREAM = rgb(240, 230, 208)
local BRICK = rgb(176, 96, 74)
local STONE = rgb(208, 202, 188)
local STONE_DARK = rgb(172, 166, 154)
local PAVE = rgb(196, 190, 178)
local TIMBER = rgb(98, 70, 50)
local TIMBER_LIGHT = rgb(160, 116, 78)
local CRATE = rgb(198, 152, 98)
local TILE = rgb(52, 124, 122)
local IRON = rgb(50, 78, 74)
local STEEL = rgb(64, 104, 110)
local DECK = rgb(188, 190, 196)
local GOLD = rgb(222, 178, 82)
local INK = rgb(46, 44, 54)
local LAMP = rgb(255, 224, 156)
local RED = rgb(214, 84, 70)
local TEAL = rgb(64, 150, 140)
local YELLOW = rgb(240, 190, 80)
local ROCK = rgb(150, 146, 140)
local ROCK_DARK = rgb(124, 120, 118)
local ROCK_LIGHT = rgb(176, 170, 160)
local SACK = rgb(206, 184, 140)

local BRICK_MAT = "Brick:Maple"
local TILE_MAT = "ClayRoofTiles:Barrel"
local STONE_MAT = "Concrete"
local SLAB_MAT = "Pavement:Slabs"
local CANVAS_MAT = "Fabric:Canvas"
local ROCK_MAT = "Rock:Cliff"
local SLAT_MAT = "WoodPlanks:Slats"

-- Pieces ----------------------------------------------------------------------------------------------

-- Stamps the piece called `id` at `at`. The first time, `draw` draws its shapes round the
-- origin; after that the same primitive is copied and only its frame differs. (Drawing a piece
-- where it stands would give keys that differ in their last decimal from one place to the next.)
local protos: { [string]: Prim } = {}
local function stamp(r: R, id: string, at: CFrame, draw: (R) -> (), collide: boolean?): Prim
	local proto = protos[id]
	if not proto then
		local q = Recipe.new(WHITE, WHITE)
		draw(q)
		proto = Geometry.piece(q.prims, collide)
		protos[id] = proto
	end
	local p = table.clone(proto)
	p.cf = at * proto.cf
	return r:add(p)
end

local function yaw(deg: number): CFrame
	return CFrame.Angles(0, math.rad(deg), 0)
end

-- A gable roof's tiles, its ridge along X from x1 to x2: two slopes from the ridge down past the
-- eaves (at height `eave`, `half` out from the ridge), a ridge cap and raised rows of tiles.
local function tiles(
	q: R,
	x1: number,
	x2: number,
	eave: number,
	half: number,
	rise: number,
	over: number,
	rows: number,
	color: Color3?
)
	local col = color or TILE
	local dark = shade(col, 0.8)
	local cx, w = (x1 + x2) / 2, x2 - x1
	local run = math.sqrt(half * half + rise * rise)
	local k = (run + over) / run
	q:box(cx, eave + rise + 0.2, 0, w + 0.4, 0.45, 0.9, dark, TILE_MAT)
	for _, side in { -1, 1 } do
		local ridge = Vector3.new(cx, eave + rise, 0)
		local foot = Vector3.new(cx, eave + rise - rise * k, side * half * k)
		q:beam(ridge, foot, w, 0.3, col, TILE_MAT)
		local lift = Vector3.new(0, half / run, side * rise / run) * 0.24
		for i = 1, rows do
			local shift = Vector3.new(x1 + (i - 0.5) * w / rows - cx, 0, 0) + lift
			q:beam(ridge + shift, foot + shift, 0.42, 0.2, dark, TILE_MAT)
		end
	end
end

-- The triangle that closes a gable roof's end, at x, standing on height y.
local function gable(q: R, x: number, thick: number, y: number, half: number, rise: number, color: Color3, mat: string)
	q:wedge(CFrame.new(x, y + rise / 2, -half / 2), thick, rise, half, color, mat)
	q:wedge(CFrame.new(x, y + rise / 2, half / 2) * yaw(180), thick, rise, half, color, mat)
end

-- A lantern hanging from (x, y, z): an iron frame and a pane that lights after dark. A range of 0
-- glows without a light of its own.
local function lantern(r: R, x: number, y: number, z: number, range: number)
	stamp(r, "lantern", CFrame.new(x, y, z), function(q)
		q:box(0, -0.3, 0, 0.12, 0.6, 0.12, IRON, "Metal")
		q:box(0, -0.68, 0, 1.3, 0.2, 1.3, IRON, "Metal")
		q:box(0, -0.5, 0, 0.7, 0.16, 0.7, IRON, "Metal")
		for _, sx in { -1, 1 } do
			for _, sz in { -1, 1 } do
				q:box(sx * 0.5, -1.43, sz * 0.5, 0.12, 1.3, 0.12, IRON, "Metal")
			end
		end
		q:box(0, -2.18, 0, 1.2, 0.2, 1.2, IRON, "Metal")
	end)
	local pane = r:box(x, y - 1.43, z, 0.86, 1.3, 0.86, LAMP, "Glass")
	pane.collide = false
	r:glow(pane, range, 1.2)
end

-- A stone lantern standing on (x, y, z): a square post, a lamp box between four corner stones
-- and a cap. The stair up the hill is lit by these.
local function stoneLantern(r: R, x: number, y: number, z: number, range: number)
	stamp(r, "stoneLantern", CFrame.new(x, y, z), function(q)
		q:box(0, 0.25, 0, 1.6, 0.5, 1.6, STONE_DARK, STONE_MAT)
		q:box(0, 1.8, 0, 0.8, 2.6, 0.8, STONE, STONE_MAT)
		q:box(0, 3.25, 0, 1.5, 0.3, 1.5, STONE_DARK, STONE_MAT)
		for _, sx in { -1, 1 } do
			for _, sz in { -1, 1 } do
				q:box(sx * 0.55, 3.95, sz * 0.55, 0.28, 1.1, 0.28, STONE, STONE_MAT)
			end
		end
		q:box(0, 4.65, 0, 1.9, 0.3, 1.9, STONE_DARK, STONE_MAT)
		q:box(0, 4.95, 0, 1.1, 0.3, 1.1, STONE, STONE_MAT)
		q:box(0, 5.25, 0, 0.45, 0.3, 0.45, STONE_DARK, STONE_MAT)
	end, true)
	local pane = r:box(x, y + 3.95, z, 0.84, 1.1, 0.84, LAMP, "Glass")
	pane.collide = false
	r:glow(pane, range, 1)
end

M.stoneLantern = function(r: R)
	stoneLantern(r, 0, 0, 0, 12)
end

-- Market goods ------------------------------------------------------------------------------------------

local PRODUCE = {
	apples = rgb(214, 66, 60),
	oranges = rgb(245, 150, 50),
	lemons = rgb(250, 214, 80),
	greens = rgb(104, 176, 84),
}

-- A slatted crate of fruit (or an empty one), standing on `at`.
local function crate(r: R, kind: string?, at: CFrame)
	stamp(r, "crate:" .. (kind or "empty"), at, function(q)
		q:box(0, 0.08, 0, 2, 0.16, 1.4, CRATE, "SmoothPlastic")
		q:box(0, 0.5, -0.64, 2, 0.84, 0.12, CRATE, "SmoothPlastic")
		q:box(0, 0.5, 0.64, 2, 0.84, 0.12, CRATE, "SmoothPlastic")
		q:box(-0.94, 0.5, 0, 0.12, 0.84, 1.16, shade(CRATE, 0.86), "SmoothPlastic")
		q:box(0.94, 0.5, 0, 0.12, 0.84, 1.16, shade(CRATE, 0.86), "SmoothPlastic")
		if kind then
			local col = PRODUCE[kind]
			for i = 0, 5 do
				local x, z = -0.58 + (i % 3) * 0.58, -0.28 + math.floor(i / 3) * 0.56
				q:ball(x, 0.78 + (i % 2) * 0.06, z, 0.6, if i % 4 == 3 then shade(col, 0.86) else col, "SmoothPlastic")
			end
		end
	end)
end

local BLOOMS = { pink = rgb(245, 140, 170), gold = rgb(255, 206, 84), white = rgb(248, 246, 240) }

-- A bucket of cut flowers.
local function bucket(r: R, kind: string, at: CFrame)
	stamp(r, "bucket:" .. kind, at, function(q)
		local col = BLOOMS[kind]
		q:cyl(0, 0.55, 0, 1.1, 1.1, "y", rgb(150, 160, 170), "SmoothPlastic")
		q:box(0, 1.35, 0, 0.8, 0.6, 0.8, rgb(84, 150, 80), "SmoothPlastic")
		for i = 0, 4 do
			local a = i * 1.257
			q:ball(math.cos(a) * 0.42, 1.8 + (i % 2) * 0.2, math.sin(a) * 0.42, 0.52, col, "SmoothPlastic")
		end
		q:ball(0, 2.1, 0, 0.5, shade(col, 0.9), "SmoothPlastic")
	end)
end

-- A basket of loaves.
local function basket(r: R, at: CFrame)
	stamp(r, "basket", at, function(q)
		q:cyl(0, 0.35, 0, 0.7, 1.7, "y", rgb(206, 170, 110), "SmoothPlastic")
		q:box(0, 0.8, 0, 1.1, 0.34, 0.44, rgb(196, 130, 70), "SmoothPlastic")
		q:boxAt(CFrame.new(-0.2, 0.86, 0.4) * yaw(35), 1, 0.32, 0.42, rgb(214, 150, 84), "SmoothPlastic")
		q:boxAt(CFrame.new(0.2, 0.86, -0.42) * yaw(-25), 1, 0.32, 0.42, rgb(184, 118, 62), "SmoothPlastic")
	end)
end

local function barrel(r: R, at: CFrame)
	stamp(r, "barrel", at, function(q)
		q:cyl(0, 1.3, 0, 2.6, 1.9, "y", TIMBER_LIGHT, "WoodPlanks")
		q:cyl(0, 0.6, 0, 0.16, 2.02, "y", INK, "WoodPlanks")
		q:cyl(0, 2, 0, 0.16, 2.02, "y", INK, "WoodPlanks")
		q:box(0, 2.62, 0, 1.2, 0.06, 1.2, TIMBER, "WoodPlanks")
	end, true)
end

-- Sacks on a pallet.
local function sacks(r: R, at: CFrame)
	stamp(r, "sacks", at, function(q)
		q:box(0, 0.15, 0, 3.2, 0.3, 2.4, CRATE, "Fabric")
		q:lump(CFrame.new(-0.8, 0.95, 0.1) * CFrame.Angles(0, 0.3, 0.1), 1.7, 1.5, 1.9, SACK, "Fabric")
		q:lump(CFrame.new(0.8, 0.9, -0.1) * CFrame.Angles(0, -0.4, -0.1), 1.7, 1.4, 1.9, shade(SACK, 0.92), "Fabric")
		q:lump(CFrame.new(0.1, 1.9, 0) * CFrame.Angles(0.1, 1.2, 0), 1.8, 1.2, 1.6, shade(SACK, 1.06), "Fabric")
	end, true)
end

-- A shop scale: a pan on a post with a dial.
local function scale(r: R, at: CFrame)
	stamp(r, "scale", at, function(q)
		q:box(0, 0.12, 0, 1, 0.24, 0.8, IRON, "Metal")
		q:box(0, 0.7, 0.2, 0.16, 0.9, 0.16, IRON, "Metal")
		q:cyl(0, 1.3, 0.2, 0.14, 0.8, "z", CREAM, "Metal")
		q:box(0, 0.4, -0.15, 1.1, 0.1, 0.7, rgb(190, 196, 204), "Metal")
	end)
end

-- A stall's counter: a boarded front under a thick top.
local function counter(r: R, at: CFrame)
	stamp(r, "counter", at, function(q)
		q:box(0, 1.35, 0, 6.4, 2.7, 1.5, TIMBER_LIGHT, "WoodPlanks")
		q:box(0, 2.82, 0, 6.9, 0.25, 2, TIMBER, "WoodPlanks")
		for _, x in { -2.2, 0, 2.2 } do
			q:box(x, 1.3, -0.78, 0.3, 2.5, 0.1, TIMBER, "WoodPlanks")
		end
	end, true)
end

-- Two shelves stepping up from the front, for crates and buckets to stand on.
local function rack(r: R, at: CFrame)
	stamp(r, "rack", at, function(q)
		q:box(-3.1, 1.3, 0, 0.25, 2.6, 3, TIMBER, "WoodPlanks")
		q:box(3.1, 1.3, 0, 0.25, 2.6, 3, TIMBER, "WoodPlanks")
		q:box(0, 1.3, -0.75, 6.2, 0.2, 1.5, TIMBER_LIGHT, "WoodPlanks")
		q:box(0, 2.2, 0.75, 6.2, 0.2, 1.5, TIMBER_LIGHT, "WoodPlanks")
		q:box(0, 0.75, -0.02, 6.2, 1.3, 0.12, TIMBER, "WoodPlanks")
	end, true)
end

-- What stands on a rack at `at`: three things on each shelf, tipped a little to the front.
local function onRack(at: CFrame, put: (number, CFrame) -> ())
	for i = 0, 2 do
		local x = (i - 1) * 2.06
		put(i + 1, at * CFrame.new(x, 1.4, -0.75) * CFrame.Angles(math.rad(-9), 0, 0))
		put(i + 4, at * CFrame.new(x, 2.3, 0.75) * CFrame.Angles(math.rad(-9), 0, 0))
	end
end

-- The name board on the gate is made the way the Signs service reads a building's own board
-- (a part named Sign with SignForm and SignHome, both big sides showing), but Data/Signs has no
-- words for a market yet and a board whose kind it doesn't know is left bare. Once Signs.Shops
-- has a `market` entry, name it here and the gate gets its name on both sides.
local GATE_SIGN: string? = nil

-- The market gate ---------------------------------------------------------------------------------------

-- Three bays across the way into the square: brick piers on stone feet, timber beams with knee
-- braces, a little tiled roof over each bay, the market's name on a board over the middle and a
-- clock turret on its roof. Lanterns hang in every bay.
M.marketGate = function(r: R)
	for _, sx in { -1, 1 } do
		r:box(sx * 7.5, 6.4, 0, 2.6, 10.4, 2.6, BRICK, BRICK_MAT)
		stamp(r, "gatePierTall", CFrame.new(sx * 7.5, 0, 0), function(q)
			q:box(0, 0.6, 0, 3.3, 1.2, 3.3, STONE, STONE_MAT)
			q:box(0, 1.35, 0, 2.95, 0.3, 2.95, STONE_DARK, STONE_MAT)
			q:box(0, 6.6, 0, 2.85, 0.45, 2.85, STONE, STONE_MAT)
			q:box(0, 11.85, 0, 3.3, 0.5, 3.3, STONE, STONE_MAT)
			q:box(0, 12.25, 0, 2.8, 0.3, 2.8, STONE_DARK, STONE_MAT)
		end)
		r:box(sx * 17, 4.8, 0, 2.2, 7.6, 2.2, BRICK, BRICK_MAT)
		stamp(r, "gatePierLow", CFrame.new(sx * 17, 0, 0), function(q)
			q:box(0, 0.5, 0, 2.9, 1, 2.9, STONE, STONE_MAT)
			q:box(0, 1.14, 0, 2.55, 0.28, 2.55, STONE_DARK, STONE_MAT)
			q:box(0, 8.82, 0, 2.9, 0.45, 2.9, STONE, STONE_MAT)
		end)
		-- the side bay: a beam from the tall pier out over the low one, braced at both ends,
		-- with its own roof (the far side is the same one turned round)
		local turn = if sx > 0 then CFrame.identity else yaw(180)
		stamp(r, "gateSideBeam", turn, function(q)
			q:box(13.7, 9.5, 0, 9.8, 0.9, 1.4, TIMBER, "Wood")
			q:box(18.75, 9.5, 0, 0.5, 1.2, 1.7, TIMBER_LIGHT, "Wood")
			q:beam(Vector3.new(8.8, 7.5, 0), Vector3.new(10.6, 9.1, 0), 0.5, 0.4, TIMBER, "Wood")
			q:beam(Vector3.new(15.9, 7.5, 0), Vector3.new(14.1, 9.1, 0), 0.5, 0.4, TIMBER, "Wood")
			q:box(13.9, 10.12, 0, 10.6, 0.34, 3.8, TIMBER_LIGHT, "Wood")
			gable(q, 8.95, 0.3, 10.29, 2.4, 1.4, TIMBER_LIGHT, "Wood")
			gable(q, 19.05, 0.3, 10.29, 2.4, 1.4, TIMBER_LIGHT, "Wood")
		end)
		stamp(r, "gateSideRoof", turn, function(q)
			tiles(q, 8.8, 19.4, 10.3, 2.4, 1.4, 0.5, 6)
		end)
		lantern(r, sx * 13.7, 9.05, 0, 0)
		lantern(r, sx * 4.3, 12.4, 0, 16)
		-- a banner on the street side of each tall pier, and one facing the square
		for _, sz in { -1, 1 } do
			stamp(
				r,
				"gateBanner",
				CFrame.new(sx * 7.5, 0, sz * 1.3) * (if sz < 0 then CFrame.identity else yaw(180)),
				function(q)
					q:box(0, 10.3, -0.5, 1.9, 0.16, 0.16, INK, CANVAS_MAT)
					q:box(0, 8.1, -0.5, 1.5, 4.2, 0.08, TEAL, CANVAS_MAT)
					q:box(0, 6.5, -0.56, 1.5, 0.5, 0.06, CREAM, CANVAS_MAT)
					q:box(0, 9.5, -0.56, 1.5, 0.3, 0.06, CREAM, CANVAS_MAT)
				end
			)
		end
	end
	-- the main beam over the middle bay, and the frame the name board sits in
	stamp(r, "gateBeam", CFrame.identity, function(q)
		q:box(0, 13, 0, 20.4, 1.2, 1.8, TIMBER, "Wood")
		q:box(0, 13.72, 0, 21, 0.25, 2.2, TIMBER_LIGHT, "Wood")
		for _, sx in { -1, 1 } do
			q:box(sx * 10.35, 13, 0, 0.5, 1.5, 2.1, TIMBER_LIGHT, "Wood")
			q:beam(Vector3.new(sx * 6.2, 10.3, 0), Vector3.new(sx * 4.2, 12.4, 0), 0.6, 0.45, TIMBER, "Wood")
			q:box(sx * 6.05, 10.1, 0, 0.5, 0.7, 1.2, TIMBER_LIGHT, "Wood")
			q:box(sx * 6.9, 15.15, 0, 0.7, 2.6, 0.7, TIMBER, "Wood")
			q:box(sx * 9.1, 15.45, 0, 0.5, 3.2, 0.5, TIMBER, "Wood")
		end
		q:box(0, 16.75, 0, 19, 0.6, 1.6, TIMBER, "Wood")
		q:box(0, 14, 0, 12.8, 0.2, 0.9, TIMBER_LIGHT, "Wood")
		for _, sz in { -1, 1 } do
			q:box(0, 16.93, sz * 2.9, 19.2, 0.25, 0.3, TIMBER_LIGHT, "Wood")
		end
		gable(q, -9.35, 0.3, 17.05, 3.1, 1.9, TIMBER_LIGHT, "Wood")
		gable(q, 9.35, 0.3, 17.05, 3.1, 1.9, TIMBER_LIGHT, "Wood")
	end)
	-- the board itself, blank until Data/Signs has a name for the market (see GATE_SIGN)
	local board = r:box(0, 15.15, 0, 12.4, 2.1, 0.5, CREAM, "SmoothPlastic")
	board.name = "Sign"
	board.collide = false
	board.attrs = { SignKind = GATE_SIGN, SignForm = "fascia", SignHome = board.cf:Inverse() }
	r:glow(board, 0)
	stamp(r, "gateRoof", CFrame.identity, function(q)
		tiles(q, -9.6, 9.6, 17.05, 3.1, 1.9, 0.5, 12)
	end)
	-- the clock turret astride the ridge, a face to the street and one to the square
	stamp(r, "gateClock", CFrame.identity, function(q)
		q:box(0, 19.75, 0, 3, 3.7, 3, CREAM, "SmoothPlastic")
		q:box(0, 21.75, 0, 3.5, 0.3, 3.5, IRON, "SmoothPlastic")
		q:box(0, 18.05, 0, 3.4, 0.3, 3.4, IRON, "SmoothPlastic")
		q:wedge(CFrame.new(0, 22.55, -0.95), 3.8, 1.3, 1.9, TILE, "SmoothPlastic")
		q:wedge(CFrame.new(0, 22.55, 0.95) * yaw(180), 3.8, 1.3, 1.9, TILE, "SmoothPlastic")
		q:box(0, 23.5, 0, 0.2, 0.8, 0.2, GOLD, "SmoothPlastic")
		q:box(0, 24, 0, 0.5, 0.3, 0.5, GOLD, "SmoothPlastic")
		for _, sz in { -1, 1 } do
			local z = sz * 1.56
			q:cyl(0, 20, z, 0.14, 2.7, "z", IRON, "SmoothPlastic")
			local f = sz * 1.76
			q:beam(Vector3.new(0, 20, f), Vector3.new(sz * 0.62, 20.62, f), 0.05, 0.16, INK, "SmoothPlastic")
			q:beam(Vector3.new(0, 20, f), Vector3.new(-sz * 0.42, 20.52, f), 0.05, 0.2, INK, "SmoothPlastic")
			q:box(0, 20.92, f, 0.14, 0.26, 0.05, INK, "SmoothPlastic")
			q:box(0, 19.08, f, 0.14, 0.26, 0.05, INK, "SmoothPlastic")
			q:box(0.92, 20, f, 0.26, 0.14, 0.05, INK, "SmoothPlastic")
			q:box(-0.92, 20, f, 0.26, 0.14, 0.05, INK, "SmoothPlastic")
		end
	end)
	for _, sz in { -1, 1 } do
		local face = r:cyl(0, 20, sz * 1.66, 0.14, 2.3, "z", WHITE, "SmoothPlastic")
		face.collide = false
		face.attrs = { NightColor = LAMP }
		r:glow(face, 0)
	end
end

-- A tall mast with a long banner, one each side of the gate at the kerb. (They also keep the
-- street's wires from being strung across the gate's face: the street scene strings a span only
-- where nothing stands in its way.)
M.marketMast = function(r: R)
	r:box(0, 0.6, 0, 1.4, 1.2, 1.4, STONE, STONE_MAT)
	stamp(r, "mast", CFrame.identity, function(q)
		q:box(0, 1.35, 0, 1, 0.3, 1, STONE_DARK, "Metal")
		q:box(0, 11.2, 0, 0.4, 19.4, 0.4, IRON, "Metal")
		q:box(0.95, 19.6, 0, 2.3, 0.22, 0.22, IRON, "Metal")
		q:box(0.95, 8.3, 0, 2.3, 0.18, 0.18, IRON, "Metal")
		q:box(0, 21.1, 0, 0.6, 0.5, 0.6, GOLD, "Metal")
	end)
	stamp(r, "mastBanner", CFrame.identity, function(q)
		q:box(1.15, 13.95, 0, 1.8, 11, 0.08, TEAL, CANVAS_MAT)
		q:box(1.15, 18.5, 0, 1.8, 0.5, 0.1, CREAM, CANVAS_MAT)
		q:box(1.15, 9.4, 0, 1.8, 0.5, 0.1, CREAM, CANVAS_MAT)
		q:boxAt(CFrame.new(1.15, 14, 0) * CFrame.Angles(0, 0, math.rad(45)), 0.9, 0.9, 0.1, CREAM, CANVAS_MAT)
	end)
end

-- The market hall ---------------------------------------------------------------------------------------

local HALL_BAYS = 5
local HALL_BAY = 8

-- An awning hung from the hall's front: canvas in stripes sloping out over the paving, a
-- valance along its edge and two rods to hold it out.
local function awning(r: R, at: CFrame, color: Color3, name: string)
	stamp(r, "awning:" .. name, at, function(q)
		local w, n = 7.4, 6
		for i = 0, n - 1 do
			local x = -w / 2 + (i + 0.5) * w / n
			local col = if i % 2 == 0 then color else CREAM
			q:beam(Vector3.new(x, 8.9, -4.9), Vector3.new(x, 7.3, -8.3), w / n, 0.12, col, CANVAS_MAT)
			q:box(x, 7, -8.32, w / n, 0.56, 0.08, col, CANVAS_MAT)
		end
		for _, sx in { -1, 1 } do
			q:beam(Vector3.new(sx * 3.6, 7.5, -4.9), Vector3.new(sx * 3.6, 7.24, -8.2), 0.1, 0.1, INK, CANVAS_MAT)
		end
	end)
end

-- A lamp hanging on a long cord under the hall's ridge.
local function pendant(r: R, x: number, y: number, z: number, range: number)
	stamp(r, "pendant", CFrame.new(x, y, z), function(q)
		q:box(0, -1.5, 0, 0.08, 3, 0.08, INK, "Metal")
		q:box(0, -3.05, 0, 0.8, 0.25, 0.8, IRON, "Metal")
		q:box(0, -3.25, 0, 1.6, 0.16, 1.6, IRON, "Metal")
	end)
	local bulb = r:box(x, y - 3.45, z, 0.8, 0.24, 0.8, LAMP, "SmoothPlastic")
	bulb.collide = false
	r:glow(bulb, range, 1.1)
end

-- An open market hall, forty studs long: twelve iron columns, timber trusses, one tiled roof
-- with three raised vents along its ridge, a low brick wall and a slatted screen at the back.
-- Five stalls stand in its bays: a greengrocer, a fishmonger, a baker, a florist and a dry
-- goods stall. A striped awning hangs out over the paving in front of each.
M.marketHall = function(r: R)
	local L = HALL_BAYS * HALL_BAY
	local FLOOR = 0.3
	-- the floor, a step up from the square, with dark tiles set in it bay by bay
	r:block(-L / 2 - 0.8, 0, -5.6, L / 2 + 0.8, FLOOR, 5.4, STONE, SLAB_MAT)
	for i = 1, HALL_BAYS do
		local bx = -L / 2 + (i - 0.5) * HALL_BAY
		stamp(r, "hallTiles", CFrame.new(bx, FLOOR, -0.4), function(q)
			for ix = 0, 3 do
				for iz = 0, 3 do
					if (ix + iz) % 2 == 0 then
						q:box(-3 + ix * 2, 0.012, -3 + iz * 2, 2, 0.024, 2, STONE_DARK, SLAB_MAT)
					end
				end
			end
		end)
	end
	-- columns front and back, a truss over each pair
	for i = 0, HALL_BAYS do
		local x = -L / 2 + i * HALL_BAY
		for _, z in { -4.6, 4.6 } do
			stamp(r, "hallColumn", CFrame.new(x, FLOOR, z), function(q)
				q:box(0, 0.4, 0, 1.1, 0.8, 1.1, IRON, "Metal")
				q:box(0, 4.6, 0, 0.55, 7.6, 0.55, IRON, "Metal")
				q:box(0, 1, 0, 0.8, 0.3, 0.8, shade(IRON, 1.3), "Metal")
				q:box(0, 8.3, 0, 0.8, 0.25, 0.8, shade(IRON, 1.3), "Metal")
				q:box(0, 8.75, 0, 1, 0.5, 1, IRON, "Metal")
			end, true)
		end
		stamp(r, "hallTruss", CFrame.new(x, FLOOR, 0), function(q)
			q:box(0, 9.3, 0, 0.5, 0.55, 11.4, TIMBER, "Wood")
			q:box(0, 10.9, 0, 0.4, 2.7, 0.4, TIMBER, "Wood")
			for _, sz in { -1, 1 } do
				q:beam(Vector3.new(0, 12.4, 0), Vector3.new(0, 9.6, sz * 6.05), 0.4, 0.5, TIMBER, "Wood")
				q:beam(Vector3.new(0, 7.7, sz * 4.5), Vector3.new(0, 9.1, sz * 3.1), 0.35, 0.35, TIMBER_LIGHT, "Wood")
			end
		end)
	end
	stamp(r, "hallPurlins", CFrame.new(0, FLOOR, 0), function(q)
		q:box(0, 9.8, -4.6, L + 1, 0.45, 0.45, TIMBER_LIGHT, "Wood")
		q:box(0, 9.8, 4.6, L + 1, 0.45, 0.45, TIMBER_LIGHT, "Wood")
		q:box(0, 12.3, 0, L + 1, 0.5, 0.35, TIMBER_LIGHT, "Wood")
	end)
	-- the roof, a bay at a time, and the vents along its ridge
	local span = (L + 1.2) / HALL_BAYS
	for i = 1, HALL_BAYS do
		local bx = (i - (HALL_BAYS + 1) / 2) * span
		stamp(r, "hallRoof", CFrame.new(bx, FLOOR, 0), function(q)
			tiles(q, -span / 2, span / 2, 9.9, 6.1, 2.85, 0.7, 8)
		end)
		if i >= 2 and i <= 4 then
			stamp(r, "hallVent", CFrame.new(bx, FLOOR, 0), function(q)
				q:box(0, 12.75, 0, 7, 1.5, 2.6, TIMBER, "Wood")
				for _, sz in { -1, 1 } do
					for k = 0, 2 do
						q:box(0, 12.95 + k * 0.28, sz * 1.34, 6.6, 0.12, 0.12, TIMBER_LIGHT, "Wood")
					end
				end
			end)
			stamp(r, "hallVentRoof", CFrame.new(bx, FLOOR, 0), function(q)
				tiles(q, -3.9, 3.9, 13.5, 1.9, 0.9, 0.4, 5)
			end)
		end
	end
	for _, sx in { -1, 1 } do
		stamp(
			r,
			"hallGable",
			CFrame.new(sx * (L / 2 + 0.35), FLOOR, 0) * (if sx > 0 then CFrame.identity else yaw(180)),
			function(q)
				q:box(0, 9.35, 0, 0.32, 0.6, 12.2, TIMBER, "Wood")
				gable(q, 0, 0.3, 9.6, 6.1, 2.85, TIMBER_LIGHT, "Wood")
				q:cyl(0.12, 10.8, 0, 0.3, 1.5, "x", TIMBER, "Wood")
			end
		)
	end
	-- the back: a low brick wall with a stone coping, and a slatted screen over it
	r:block(-L / 2, FLOOR, 4.3, L / 2, 3.6, 4.9, BRICK, BRICK_MAT)
	r:noCollide(r:block(-L / 2 - 0.2, 3.6, 4.15, L / 2 + 0.2, 3.85, 5.05, STONE, STONE_MAT))
	r:noCollide(r:block(-L / 2, 3.85, 4.5, L / 2, 7.2, 4.75, TIMBER_LIGHT, SLAT_MAT))

	-- the stalls
	local function bay(i: number): CFrame
		return CFrame.new(-L / 2 + (i - 0.5) * HALL_BAY, FLOOR, 0)
	end
	for i = 1, HALL_BAYS do
		counter(r, bay(i) * CFrame.new(0, 0, 2.5))
		awning(r, bay(i) * CFrame.new(0, 0, 0), if i % 2 == 1 then RED else TEAL, if i % 2 == 1 then "red" else "teal")
		pendant(r, -L / 2 + (i - 0.5) * HALL_BAY, FLOOR + 12.05, 0, if i % 2 == 0 then 18 else 0)
	end
	-- three of them have a name up on the screen behind the counter
	local NAMED: { { bay: number, kind: string } } =
		{ { bay = 1, kind = "grocer" }, { bay = 3, kind = "bakery" }, { bay = 4, kind = "flowers" } }
	for _, stall in NAMED do
		local at = bay(stall.bay)
		local board = r:box(at.X, FLOOR + 5.6, 4.36, 5.6, 1.5, 0.2, CREAM, "SmoothPlastic")
		board.name = "Sign"
		board.collide = false
		board.attrs = { SignKind = stall.kind, SignForm = "fascia", SignFace = "Front", SignHome = board.cf:Inverse() }
		r:glow(board, 0)
	end
	-- the greengrocer
	local FRUIT = { "apples", "greens", "oranges", "lemons", "oranges", "apples" }
	rack(r, bay(1) * CFrame.new(0, 0, -1.9))
	onRack(bay(1) * CFrame.new(0, 0, -1.9), function(n, at)
		crate(r, FRUIT[n], at)
	end)
	scale(r, bay(1) * CFrame.new(1.8, 2.95, 2.5))
	crate(r, "greens", bay(1) * CFrame.new(-1.6, 2.95, 2.5) * yaw(8))
	-- the fishmonger: a table of ice
	stamp(r, "fishTable", bay(2) * CFrame.new(0, 0, -1.9), function(q)
		q:box(0, 2.45, 0, 6.2, 0.3, 2.8, rgb(190, 196, 204), "SmoothPlastic")
		for _, sx in { -1, 1 } do
			for _, sz in { -1, 1 } do
				q:box(sx * 2.8, 1.15, sz * 1.1, 0.25, 2.3, 0.25, IRON, "SmoothPlastic")
			end
		end
		q:box(0, 2.78, 0, 5.8, 0.36, 2.4, rgb(226, 240, 248), "SmoothPlastic")
		local fish = { rgb(150, 170, 190), rgb(240, 150, 130), rgb(120, 150, 180) }
		for k = 0, 5 do
			local x, z = -2.1 + (k % 3) * 2.1, -0.55 + math.floor(k / 3) * 1.1
			q:boxAt(CFrame.new(x, 3.04, z) * yaw(18 - k * 9), 1.4, 0.2, 0.42, fish[k % 3 + 1], "SmoothPlastic")
		end
	end, true)
	scale(r, bay(2) * CFrame.new(-1.7, 2.95, 2.5))
	barrel(r, bay(2) * CFrame.new(2.6, 0, 0.6))
	-- the baker
	rack(r, bay(3) * CFrame.new(0, 0, -1.9))
	onRack(bay(3) * CFrame.new(0, 0, -1.9), function(n, at)
		if n % 2 == 1 or n == 4 then
			basket(r, at)
		end
	end)
	for _, x in { -2, 0.2, 2.2 } do
		basket(r, bay(3) * CFrame.new(x, 2.95, 2.5))
	end
	sacks(r, bay(3) * CFrame.new(-2.2, 0, 0.4) * yaw(20))
	-- the florist
	local FLOWERS = { "pink", "gold", "white", "white", "pink", "gold" }
	rack(r, bay(4) * CFrame.new(0, 0, -1.9))
	onRack(bay(4) * CFrame.new(0, 0, -1.9), function(n, at)
		bucket(r, FLOWERS[n], CFrame.new(at.Position))
	end)
	bucket(r, "gold", bay(4) * CFrame.new(-2.4, 2.95, 2.5))
	bucket(r, "pink", bay(4) * CFrame.new(3.3, 0, 0.3))
	-- dry goods: barrels, sacks and what came in this morning
	barrel(r, bay(5) * CFrame.new(-2.4, 0, -2.2))
	barrel(r, bay(5) * CFrame.new(-0.2, 0, -2.7))
	barrel(r, bay(5) * CFrame.new(2.4, 0, -2))
	sacks(r, bay(5) * CFrame.new(0.4, 0, -0.2) * yaw(-12))
	crate(r, nil, bay(5) * CFrame.new(-1.6, 2.95, 2.5) * yaw(-6))
	crate(r, "lemons", bay(5) * CFrame.new(1.4, 2.95, 2.5) * yaw(5))
	crate(r, nil, bay(5) * CFrame.new(1.4, 3.87, 2.5) * yaw(-10))
end

-- Loose stalls ------------------------------------------------------------------------------------------

-- A stall under a ridge tent: four posts, canvas in stripes, a counter of crates.
local function tent(color: Color3, name: string, goods: { string }): (R) -> ()
	return function(r: R)
		counter(r, CFrame.new(0, 0, 0.5))
		stamp(r, "tentFrame", CFrame.identity, function(q)
			for _, sx in { -1, 1 } do
				for _, sz in { -1, 1 } do
					q:box(sx * 3.7, 3.5, sz * 2, 0.3, 7, 0.3, TIMBER, "Wood")
				end
				q:box(sx * 3.7, 7.7, 0, 0.25, 1.4, 0.25, TIMBER, "Wood")
				q:box(sx * 3.7, 7.05, 0, 0.25, 0.25, 4.2, TIMBER, "Wood")
			end
			for _, sz in { -1, 1 } do
				q:box(0, 7.05, sz * 2, 7.7, 0.25, 0.25, TIMBER, "Wood")
			end
			q:box(0, 8.4, 0, 8.4, 0.25, 0.25, TIMBER, "Wood")
		end)
		stamp(r, "tentCanvas:" .. name, CFrame.identity, function(q)
			local w, n = 8.2, 5
			for i = 0, n - 1 do
				local x = -w / 2 + (i + 0.5) * w / n
				local col = if i % 2 == 0 then color else CREAM
				for _, sz in { -1, 1 } do
					q:beam(Vector3.new(x, 8.62, 0), Vector3.new(x, 7.2, sz * 2.8), w / n, 0.12, col, CANVAS_MAT)
				end
			end
			for _, sz in { -1, 1 } do
				q:box(0, 6.92, sz * 2.8, w, 0.56, 0.08, color, CANVAS_MAT)
			end
		end)
		for i, kind in goods do
			crate(r, kind, CFrame.new(-2.2 + (i - 1) * 2.2, 2.95, 0.3) * CFrame.Angles(math.rad(-12), 0, 0))
		end
		crate(r, goods[1], CFrame.new(-2.3, 0, -1.3) * yaw(12))
		crate(r, nil, CFrame.new(2.2, 0, -1.4) * yaw(-8))
		lantern(r, 0, 8.27, 0, 0)
	end
end

M.marketTentA = tent(RED, "red", { "apples", "oranges", "lemons" })
M.marketTentB = tent(YELLOW, "yellow", { "greens", "lemons", "apples" })

-- A flower seller's handcart under a big parasol.
M.marketCart = function(r: R)
	stamp(r, "cart", CFrame.identity, function(q)
		q:box(0, 2, 0, 5, 0.3, 2.6, TIMBER_LIGHT, "WoodPlanks")
		for _, sz in { -1, 1 } do
			q:box(0, 2.55, sz * 1.24, 5, 0.8, 0.14, TIMBER, "WoodPlanks")
			q:cyl(-0.7, 1.3, sz * 1.5, 0.3, 2.6, "z", TIMBER, "WoodPlanks")
			q:cyl(-0.7, 1.3, sz * 1.62, 0.1, 0.7, "z", INK, "WoodPlanks")
			q:beam(Vector3.new(2.4, 2.1, sz * 1.1), Vector3.new(4.4, 2.7, sz * 1.1), 0.18, 0.18, TIMBER, "WoodPlanks")
		end
		for _, sx in { -1, 1 } do
			q:box(sx * 2.43, 2.55, 0, 0.14, 0.8, 2.34, TIMBER, "WoodPlanks")
		end
		q:box(2.1, 0.95, 0, 0.22, 1.9, 0.22, TIMBER, "WoodPlanks")
	end, true)
	stamp(r, "cartParasol", CFrame.identity, function(q)
		q:box(-0.2, 5.8, 0, 0.22, 7.6, 0.22, INK, CANVAS_MAT)
		local tip = Vector3.new(-0.2, 9.7, 0)
		for i = 0, 7 do
			local a1, a2 = i / 8 * math.pi * 2, (i + 1) / 8 * math.pi * 2
			local p1 = Vector3.new(-0.2 + math.cos(a1) * 4.3, 8.3, math.sin(a1) * 4.3)
			local p2 = Vector3.new(-0.2 + math.cos(a2) * 4.3, 8.3, math.sin(a2) * 4.3)
			q:tri(tip, p1, p2, 0.12, if i % 2 == 0 then TEAL else CREAM, CANVAS_MAT)
		end
	end)
	bucket(r, "pink", CFrame.new(-1.6, 2.15, -0.5))
	bucket(r, "white", CFrame.new(-0.4, 2.15, 0.5))
	bucket(r, "gold", CFrame.new(0.9, 2.15, -0.4))
	bucket(r, "pink", CFrame.new(1.9, 2.15, 0.5))
	bucket(r, "gold", CFrame.new(-3.4, 0, -1.6))
	bucket(r, "white", CFrame.new(-3.8, 0, 0.2))
end

-- What a market leaves standing about: barrels, sacks and crates.
M.marketGoods = function(r: R)
	barrel(r, CFrame.new(-2.2, 0, 0.4))
	barrel(r, CFrame.new(-0.1, 0, 0.9))
	sacks(r, CFrame.new(2.6, 0, 0.3) * yaw(15))
	crate(r, "oranges", CFrame.new(-1.2, 0, -1.4) * yaw(-10))
	crate(r, nil, CFrame.new(1, 0, -1.5) * yaw(6))
	crate(r, "greens", CFrame.new(1, 0.92, -1.5) * yaw(-14))
end

-- The footbridge ----------------------------------------------------------------------------------------

Landmarks.Bridge = {
	x = 274.25, -- the middle of the gap between the plots east of the square
	foot = 19, -- how far from the street's middle the stairs come down, on both sides
	deck = 13.2, -- the top of the deck
	clear = 11, -- nothing hangs lower than this over the road
}

-- A run of handrail: posts, a top rail, a rail at the knee and bars between. `long` studs
-- along local Z from the origin.
local function rail(r: R, at: CFrame, long: number)
	stamp(r, "rail:" .. long, at, function(q)
		q:box(0, 3.3, long / 2, 0.26, 0.26, long, STEEL, "Metal")
		q:box(0, 0.5, long / 2, 0.16, 0.16, long, STEEL, "Metal")
		local posts = math.max(1, math.floor(long / 4.75 + 0.5))
		for i = 0, posts do
			q:box(0, 1.65, math.clamp(i * long / posts, 0.15, long - 0.15), 0.3, 3.3, 0.3, STEEL, "Metal")
		end
		local bars = math.floor(long / 0.95)
		for i = 1, bars - 1 do
			q:box(0, 1.9, i * long / bars, 0.1, 2.7, 0.1, shade(STEEL, 1.25), "Metal")
		end
	end, true)
end

-- A steel footbridge over Main Street. A stair climbs from each pavement to a half landing and
-- turns back up to the deck, which crosses on two girders well clear of the bus. Lamps at its
-- four corners, and an advertising board on each side for the traffic to read.
M.footbridge = function(r: R)
	local B = Landmarks.Bridge
	local RISE, TREAD, STEPS = 0.645, 1.4, 10
	local RUN = TREAD * (STEPS - 1)
	local MID = B.deck - RISE * STEPS -- the half landing
	local GROUND = B.deck - 2 * RISE * STEPS
	-- (drawn with z = 0 at the street's middle, then moved so the model's own middle is the
	-- foot of its north stair: a placement may not stand in the road)
	local function flight(at: CFrame)
		stamp(r, "bridgeFlight", at, function(q)
			for j = 1, STEPS - 1 do
				q:box(0, RISE * j - 0.11, TREAD * (j - 0.5), 4.3, 0.22, TREAD + 0.1, DECK, "Metal")
			end
			for _, sx in { -1, 1 } do
				q:beam(
					Vector3.new(sx * 2.1, -0.2, -0.3),
					Vector3.new(sx * 2.1, RISE * STEPS - 0.45, RUN + 0.1),
					0.25,
					0.9,
					STEEL,
					"Metal"
				)
			end
		end)
		-- what people walk on: a ramp nobody sees, along the noses of the treads
		local slope = Vector3.new(0, RISE * STEPS, RUN + TREAD)
		local down = Vector3.new(0, -slope.Z, slope.Y).Unit * 0.15
		local ramp = r:beam(
			at * (Vector3.new(0, 0, -TREAD) + down),
			at * (Vector3.new(0, RISE * STEPS, RUN) + down),
			4.5,
			0.3,
			WHITE
		)
		if ramp then
			ramp.transp = 1
		end
		for _, sx in { -1, 1 } do
			stamp(r, "bridgeFlightRail", at * CFrame.new(sx * 2.25, 0, 0), function(q)
				local function nose(z: number): number
					return RISE + z / TREAD * RISE
				end
				for _, z in { 0.2, 4.3, 8.4, RUN - 0.2 } do
					q:box(0, nose(z) + 1.55, z, 0.3, 3.5, 0.3, STEEL, "Metal")
				end
				for _, up in { 3.2, 1.7, 0.4 } do
					q:beam(
						Vector3.new(0, nose(0) + up, 0),
						Vector3.new(0, nose(RUN) + up, RUN),
						0.2,
						0.22,
						STEEL,
						"Metal"
					)
				end
			end, true)
		end
	end
	for _, s in { 1, -1 } do
		local turn = if s > 0 then CFrame.identity else yaw(180)
		-- up from the pavement on the west half, away from the street
		flight(CFrame.new(-2.5, GROUND, s * B.foot) * turn)
		-- the half landing, on two posts
		local z1, z2 = s * (B.foot + RUN), s * (B.foot + RUN + 4.75)
		r:block(-4.75, MID - 0.35, math.min(z1, z2), 4.75, MID, math.max(z1, z2), DECK, STONE_MAT)
		for _, x in { -4.3, 4.3 } do
			r:box(x, (MID - 0.35 - 0.3) / 2, z2 - s * 0.5, 0.6, MID - 0.35 + 0.3, 0.6, STEEL, "Metal")
		end
		rail(r, CFrame.new(-4.75, MID, z2) * yaw(90), 9.5)
		rail(r, CFrame.new(-4.75, MID, math.min(z1, z2)), 4.75)
		rail(r, CFrame.new(4.75, MID, math.min(z1, z2)), 4.75)
		-- and back toward the street on the east half, up to the deck
		flight(CFrame.new(2.5, MID, s * (B.foot + RUN)) * turn * yaw(180))
		-- the posts under the end of the deck, and the beam across them
		for _, x in { 0.6, 4.4 } do
			r:box(x, (B.deck - 1.9 - 0.3) / 2, s * (B.foot - 0.6), 0.7, B.deck - 1.9 + 0.3, 0.7, STEEL, "Metal")
		end
		stamp(r, "bridgePortal", CFrame.new(2.5, B.deck, s * (B.foot - 0.6)), function(q)
			q:box(0, -1.6, 0, 5.2, 0.6, 0.8, STEEL, "Metal")
			q:beam(Vector3.new(-1.9, -3.4, 0), Vector3.new(-0.6, -1.9, 0), 0.5, 0.3, STEEL, "Metal")
			q:beam(Vector3.new(1.9, -3.4, 0), Vector3.new(0.6, -1.9, 0), 0.5, 0.3, STEEL, "Metal")
		end)
	end
	-- the deck, its girders and its rails
	r:block(0.25, B.deck - 0.35, -B.foot, 4.75, B.deck, B.foot, DECK, STONE_MAT)
	for _, x in { 0.25, 4.75 } do
		stamp(r, "bridgeGirder", CFrame.new(x, B.deck - 0.35, 0), function(q)
			local long = 2 * B.foot
			q:box(0, -0.75, 0, 0.24, 1.5, long, STEEL, "Metal")
			q:box(0, -0.08, 0, 0.7, 0.16, long, STEEL, "Metal")
			q:box(0, -1.42, 0, 0.7, 0.16, long, STEEL, "Metal")
			for i = 0, 8 do
				q:box(0, -0.75, -B.foot + 0.2 + i * (long - 0.4) / 8, 0.6, 1.3, 0.16, shade(STEEL, 0.82), "Metal")
			end
		end)
		for i = 0, 3 do
			rail(r, CFrame.new(x, B.deck, -B.foot + i * 9.5), 9.5)
		end
	end
	-- a board on each side, facing the traffic
	for _, s in { -1, 1 } do
		local x = if s < 0 then 0.25 - 0.5 else 4.75 + 0.5
		local board = r:box(x, B.deck - 0.6, 0, 0.2, 2.6, 16, CREAM, "SmoothPlastic")
		board.name = "Ad"
		board.collide = false
		board.attrs = { SignFace = if s < 0 then "Left" else "Right" }
		stamp(r, "bridgeBoard", CFrame.new(x, B.deck - 0.6, 0), function(q)
			q:box(0, 1.4, 0, 0.3, 0.2, 16.4, STEEL, "Metal")
			q:box(0, -1.4, 0, 0.3, 0.2, 16.4, STEEL, "Metal")
			q:box(0, 0, -8.1, 0.3, 2.6, 0.2, STEEL, "Metal")
			q:box(0, 0, 8.1, 0.3, 2.6, 0.2, STEEL, "Metal")
		end)
	end
	-- lamps over the four corners of the deck
	for _, s in { -1, 1 } do
		for _, sx in { -1, 1 } do
			local x, z = if sx < 0 then 0.25 else 4.75, s * 12
			stamp(
				r,
				"bridgeLamp",
				CFrame.new(x, B.deck, z) * (if sx < 0 then CFrame.identity else yaw(180)),
				function(q)
					q:box(0, 4.2, 0, 0.26, 8.4, 0.26, STEEL, "Metal")
					q:box(0.7, 8.3, 0, 1.6, 0.2, 0.2, STEEL, "Metal")
					q:box(1.3, 8.1, 0, 1, 0.24, 0.9, STEEL, "Metal")
				end
			)
			local head = r:box(x - sx * 1.3, B.deck + 7.9, z, 0.8, 0.18, 0.7, LAMP, "SmoothPlastic")
			head.collide = false
			r:glow(head, 18, 1)
		end
	end
	Geometry.transform(r.prims, CFrame.new(0, 0, -B.foot))
end

-- The stair up the hill ---------------------------------------------------------------------------------

-- Where it is, and how it is cut. It starts at the back of Hill Road's pavement, opposite the
-- walk up from the square, and climbs north.
local STAIR_X = 0
local STAIR_Z = Town.RingZ + 11 + 6
local STAIR_HALF = 4.5 -- half the width of the steps
local STAIR_EDGE = 5.4 -- and out to the outside of the walls beside them
local LIFT = 0.25 -- how far a step sits over the hill under it
local TREAD = 5 -- a broad step, front to back
local FLIGHTS = 4
local FLIGHT_STEPS = 8 -- risers in a flight, a stud each
-- How deep a flight's treads may be, the deepest first: a flight takes the deepest that still
-- outclimbs the hill under it by enough for a landing, so it stands no higher over the grass
-- than it must.
local FLIGHT_TREADS = { 2, 1.75, 1.5 }
local LANDING = 4.5 -- the least a landing runs before the hill has caught up with it

export type Step = { z1: number, z2: number, y: number, kind: string }
type Flight = { z: number, y: number, tread: number }
type Profile = {
	court: Step,
	treads: { Step },
	flights: { Flight },
	landings: { Step },
	steps: { Step },
	top: number, -- the height of the last landing and of the terrace
	front: number, -- the terrace, south to north
	back: number,
	neck: number, -- the east end runs on this far beside the last landing
	knollBack: number,
}

-- The highest the drawn hill gets under a patch of ground.
local function hillOver(x1: number, x2: number, z1: number, z2: number): number
	local top = -0.1
	local n = math.max(1, math.ceil((z2 - z1) / 0.5))
	for i = 0, n do
		local z = z1 + (z2 - z1) * i / n
		for j = 0, 4 do
			top = math.max(top, Hills.at(x1 + (x2 - x1) * j / 4, z))
		end
	end
	return top
end

local TERRACE_X1, TERRACE_X2 = STAIR_X - 27, STAIR_X - STAIR_EDGE
local NECK_X1 = STAIR_X - 14
local KNOLL_X1 = STAIR_X - 41
local KNOLL_RISE = 3.2

-- The stair is cut to the hill as it is drawn, so that every step sits just on it. A court at
-- the bottom, broad steps while the ground is gentle, then flights of eight risers. Each flight
-- climbs a little faster than the hill does, and the landing after it runs on level until the
-- hill has caught up, so nothing is ever buried and nothing stands far off the ground.
local profile: Profile? = nil
local function stairProfile(): Profile
	if profile then
		return profile
	end
	local x1, x2 = STAIR_X - STAIR_EDGE, STAIR_X + STAIR_EDGE
	local steps: { Step } = {}
	local z = STAIR_Z
	local y = math.max(0.85, hillOver(x1 - 0.8, x2 + 0.8, z, z + 11.5) + LIFT)
	local court: Step = { z1 = z, z2 = z + 11.5, y = y, kind = "court" }
	table.insert(steps, court)
	z += 11.5
	local treads: { Step } = {}
	while #treads < 16 do
		local top = math.max(hillOver(x1, x2, z, z + TREAD) + LIFT, y + 0.25)
		if top - y > 1.15 then
			break
		end
		y = top
		local tread: Step = { z1 = z, z2 = z + TREAD, y = y, kind = "tread" }
		table.insert(treads, tread)
		table.insert(steps, tread)
		z += TREAD
	end
	local flights: { Flight } = {}
	local landings: { Step } = {}
	for _ = 1, FLIGHTS do
		local tread = FLIGHT_TREADS[#FLIGHT_TREADS]
		for _, t in FLIGHT_TREADS do
			-- it will do if no step of it is under the hill and its landing has room
			local run = t * (FLIGHT_STEPS - 1)
			local fits = hillOver(x1 - 0.8, x2 + 0.8, z + run, z + run + LANDING) + LIFT <= y + FLIGHT_STEPS
			for j = 1, FLIGHT_STEPS - 1 do
				fits = fits and hillOver(x1, x2, z + t * (j - 1), z + t * j) + 0.1 <= y + j
			end
			if fits then
				tread = t
				break
			end
		end
		table.insert(flights, { z = z, y = y, tread = tread })
		for j = 1, FLIGHT_STEPS - 1 do
			table.insert(steps, { z1 = z + tread * (j - 1), z2 = z + tread * j, y = y + j, kind = "step" })
		end
		z += tread * (FLIGHT_STEPS - 1)
		y += FLIGHT_STEPS
		local last = z + 3
		while last - z < 9 and hillOver(x1 - 0.8, x2 + 0.8, z, last + 0.25) + LIFT <= y do
			last += 0.25
		end
		local landing: Step = { z1 = z, z2 = last, y = y, kind = "landing" }
		table.insert(landings, landing)
		table.insert(steps, landing)
		z = last
	end
	-- the terrace beside the last landing: level with it, from a rail's length short of the
	-- landing back to where the hill comes up to meet it
	local top = landings[#landings]
	local front = top.z1 - 21.6
	local back = top.z1
	while back < top.z2 + 3 and hillOver(TERRACE_X1, TERRACE_X2, back, back + 0.25) + 0.15 <= top.y do
		back += 0.25
	end
	-- (the hill is lower toward the stair, so the end of the terrace nearest it reaches a
	-- little further back, and the way through from the landing is that much wider)
	local neck = back
	while neck < top.z2 and hillOver(NECK_X1, TERRACE_X2, neck, neck + 0.25) + 0.15 <= top.y do
		neck += 0.25
	end
	local knollBack = back
	while
		knollBack < back + 12
		and hillOver(KNOLL_X1, TERRACE_X1, knollBack, knollBack + 0.25) + 0.8 <= top.y + KNOLL_RISE
	do
		knollBack += 0.25
	end
	local made: Profile = {
		court = court,
		treads = treads,
		flights = flights,
		landings = landings,
		steps = steps,
		top = top.y,
		front = front,
		back = back,
		neck = neck,
		knollBack = knollBack,
	}
	profile = made
	return made
end

-- The stair as the specs want it: where it runs, and every level surface of it from the road
-- up (the steps of a steep flight are walked on a ramp laid along their noses).
function Landmarks.stair(): { x: number, half: number, steps: { Step }, top: number }
	local p = stairProfile()
	return { x = STAIR_X, half = STAIR_HALF, steps = p.steps, top = p.top }
end

-- The lookout's terrace: its corners and its height. `neck` is how far back its east end
-- reaches, from x = `neckX` to the stair. `rock` is the whole of the rock it is the top of, the
-- knoll at its west end included, and how high the knoll stands.
function Landmarks.terrace(): {
	x1: number,
	z1: number,
	x2: number,
	z2: number,
	y: number,
	neck: number,
	neckX: number,
	rock: { x1: number, z1: number, x2: number, z2: number, y: number },
}
	local p = stairProfile()
	return {
		x1 = TERRACE_X1,
		z1 = p.front,
		x2 = TERRACE_X2,
		z2 = p.back,
		y = p.top,
		neck = p.neck,
		neckX = NECK_X1,
		rock = { x1 = KNOLL_X1, z1 = p.front, x2 = TERRACE_X2, z2 = p.knollBack, y = p.top + KNOLL_RISE },
	}
end

-- The stepped street: a paved court off Hill Road between two lanterns on plinths, broad steps
-- with a pale nosing and stepped kerbs, then the flights, their walls, railings and landings.
-- Drawn where it stands, then moved so its own middle is the foot of the stair.
M.hillStair = function(r: R)
	local p = stairProfile()
	local X = STAIR_X
	-- the court
	local c = p.court
	r:block(X - 6.4, c.y - 1.4, c.z1, X + 6.4, c.y, c.z2, PAVE, SLAB_MAT)
	r:noCollide(r:block(X - 6.5, c.y - 0.5, c.z1 - 0.1, X + 6.5, c.y + 0.03, c.z1 + 0.7, STONE, STONE_MAT))
	for _, sx in { -1, 1 } do
		r:block(X + sx * 7.3 - 0.9, -0.2, c.z1 + 0.4, X + sx * 7.3 + 0.9, c.y + 1, c.z1 + 2.2, STONE_DARK, STONE_MAT)
		stoneLantern(r, X + sx * 7.3, c.y + 1, c.z1 + 1.3, 14)
		r:block(X + sx * 6.9 - 0.5, c.y - 1.4, c.z1 + 2.2, X + sx * 6.9 + 0.5, c.y + 0.9, c.z2, STONE_DARK, STONE_MAT)
	end
	-- the broad steps
	for i, t in p.treads do
		local at = CFrame.new(X, t.y, t.z1)
		stamp(r, "broadStep", at, function(q)
			q:box(0, -0.9, TREAD / 2, 2 * STAIR_HALF, 1.8, TREAD, PAVE, SLAB_MAT)
			q:box(0, -0.22, 0.34, 2 * STAIR_HALF, 0.44, 0.7, STONE, SLAB_MAT)
		end, true)
		stamp(r, "broadKerb", at, function(q)
			for _, sx in { -1, 1 } do
				q:box(sx * (STAIR_HALF + 0.45), 0, TREAD / 2, 0.9, 2.4, TREAD, STONE_DARK, STONE_MAT)
				q:box(sx * (STAIR_HALF + 0.45), 1.3, TREAD / 2, 1.1, 0.22, TREAD + 0.1, STONE, STONE_MAT)
			end
		end)
		if i % 3 == 2 then
			local side = if i % 2 == 0 then -1 else 1
			local lx, lz = X + side * (STAIR_EDGE + 1.3), t.z1 + TREAD / 2
			stoneLantern(r, lx, hillOver(lx - 0.8, lx + 0.8, lz - 0.8, lz + 0.8) - 0.5, lz, 12)
		end
	end
	-- the flights
	for _, f in p.flights do
		local T = f.tread
		local RUN = T * (FLIGHT_STEPS - 1)
		local slope = Vector3.new(0, FLIGHT_STEPS, RUN + T)
		local down = Vector3.new(0, -slope.Z, slope.Y).Unit
		local at = CFrame.new(X, f.y, f.z)
		stamp(r, "stairFlight:" .. T, at, function(q)
			for j = 1, FLIGHT_STEPS - 1 do
				q:box(0, j - 1.8, T * (j - 0.5), 2 * STAIR_HALF, 3.6, T, PAVE, SLAB_MAT)
			end
			for j = 1, FLIGHT_STEPS do
				q:box(0, j - 0.12, T * (j - 1) + 0.2, 2 * STAIR_HALF + 0.02, 0.28, 0.5, STONE, SLAB_MAT)
			end
			-- the walls beside the steps follow the slope, with a block at the foot and the head
			local a, b = Vector3.new(0, 1, 0), Vector3.new(0, FLIGHT_STEPS + 1, RUN + T)
			for _, sx in { -1, 1 } do
				local off = Vector3.new(sx * (STAIR_HALF + 0.45), 0.9, 0) + down * 1.6
				q:beam(a + off, b + off - slope.Unit * 1.4, 0.9, 3.2, STONE_DARK, SLAB_MAT)
				q:box(sx * (STAIR_HALF + 0.45), 0.4, 0, 1.1, 3.6, 1.1, STONE, SLAB_MAT)
				q:box(sx * (STAIR_HALF + 0.45), FLIGHT_STEPS + 0.4, RUN, 1.1, 3.6, 1.1, STONE, SLAB_MAT)
			end
		end)
		-- the ramp people walk up, from a tread's depth before the first riser to the landing
		local shift = down * 0.2
		local ramp = r:beam(
			at * (Vector3.new(0, 0, -T) + shift),
			at * (Vector3.new(0, FLIGHT_STEPS, RUN) + shift),
			2 * STAIR_HALF,
			0.4,
			WHITE
		)
		if ramp then
			ramp.transp = 1
		end
		for _, sx in { -1, 1 } do
			stamp(r, "stairRail:" .. T, at * CFrame.new(sx * (STAIR_HALF + 0.45), 0, 0), function(q)
				local function wall(z: number): number
					return 1.9 + z / T
				end
				for i = 0, 3 do
					local z = 1.2 + i * (RUN - 2.4) / 3
					q:box(0, wall(z) + 1.4, z, 0.24, 3, 0.24, IRON, "Metal")
				end
				for _, up in { 2.9, 1.5 } do
					q:beam(
						Vector3.new(0, wall(0.6) + up, 0.6),
						Vector3.new(0, wall(RUN - 0.6) + up, RUN - 0.6),
						0.22,
						0.22,
						IRON,
						"Metal"
					)
				end
			end, true)
		end
	end
	-- the landings, wide enough for a lantern at each side (the last one opens west onto the
	-- terrace, so it stops at the wall on that side)
	for i, l in p.landings do
		local last = i == #p.landings
		local west = if last then X - STAIR_EDGE else X - 6.3
		r:block(west, l.y - 3.8, l.z1, X + 6.3, l.y, l.z2, PAVE, SLAB_MAT)
		if not last then
			stoneLantern(r, X - 5.5, l.y, l.z1 + 1.5, if i % 2 == 1 then 12 else 0)
		end
		stoneLantern(r, X + 5.5, l.y, l.z1 + 1.5, if i % 2 == 0 then 12 else 0)
	end
	Geometry.transform(r.prims, CFrame.new(-STAIR_X, 0, -STAIR_Z))
end

-- Rock ----------------------------------------------------------------------------------------------------

-- A bay of cliff: slabs of rock in layers, each turned a little and standing out further toward
-- the foot. Drawn facing local -Z with its top at the origin; it is twelve wide and sixteen
-- deep, and is sunk into the ground where the cliff is lower.
local function rockSlab(
	q: R,
	x: number,
	y: number,
	z: number,
	sx: number,
	sy: number,
	sz: number,
	turn: number,
	roll: number,
	col: Color3
)
	q:boxAt(CFrame.new(x, y, z) * CFrame.Angles(0, math.rad(turn), math.rad(roll)), sx, sy, sz, col, ROCK_MAT)
end

local function cliff(r: R, kind: string, at: CFrame)
	stamp(r, "cliff:" .. kind, at, function(q)
		q:box(0, -8, 0.3, 12, 16, 0.6, ROCK_DARK, ROCK_MAT)
		if kind == "a" then
			rockSlab(q, 0.3, -1.7, -0.5, 12.4, 3.4, 1.8, 3, 0, ROCK_LIGHT)
			rockSlab(q, -0.8, -5.3, -1, 11.2, 4.2, 2.8, -4, 1.5, ROCK)
			rockSlab(q, 0.5, -9.8, -1.5, 12.6, 5.2, 3.8, 2.5, -1, ROCK_DARK)
			rockSlab(q, -0.2, -14.2, -2.2, 12.2, 4.4, 5.2, -3, 0, ROCK)
			rockSlab(q, 3.9, -5.6, -1.9, 3, 9.4, 2.6, 12, 2, ROCK_LIGHT)
			rockSlab(q, -3.6, -2.9, -1.3, 4.2, 1.6, 2.2, -8, -3, ROCK_DARK)
		elseif kind == "b" then
			rockSlab(q, -0.4, -1.3, -0.4, 12.2, 2.6, 1.6, -2, 0, ROCK)
			rockSlab(q, 0.9, -4.4, -1.1, 10.4, 3.8, 3, 5, -1.5, ROCK_LIGHT)
			rockSlab(q, -0.6, -8.6, -1.4, 12.4, 4.8, 3.4, -3, 1, ROCK)
			rockSlab(q, 0.4, -13.4, -2, 12.6, 5.4, 4.8, 3, 0, ROCK_DARK)
			rockSlab(q, -4.2, -6.8, -2, 2.8, 8.2, 2.8, -14, -2, ROCK_DARK)
			rockSlab(q, 2.6, -2.2, -1.5, 3.6, 1.4, 2.4, 10, 3, ROCK_LIGHT)
			rockSlab(q, 1.8, -10.6, -3, 4.4, 2.2, 2.6, 16, 0, ROCK_LIGHT)
		else
			-- a flat bay, for where the stair runs close beside the rock
			rockSlab(q, 0, -1.2, -0.25, 12, 2.4, 0.7, 0, 0, ROCK_LIGHT)
			rockSlab(q, -1.8, -4.6, -0.3, 8.2, 4, 0.8, 0, 2, ROCK_DARK)
			rockSlab(q, 3.2, -5.4, -0.2, 5, 5.6, 0.6, 0, -1.5, ROCK)
			rockSlab(q, 0.4, -9.6, -0.3, 11.4, 4.6, 0.8, 0, -1, ROCK)
			rockSlab(q, -0.6, -13.8, -0.3, 11.8, 4, 0.8, 0, 1, ROCK_DARK)
		end
	end)
end

-- A lump of rock coming out of the hillside.
M.outcropA = function(r: R)
	r:lump(CFrame.new(0, 1.2, 0) * CFrame.Angles(0.2, 0.5, 0.1), 7.4, 5.6, 6, ROCK, ROCK_MAT)
	r:lump(CFrame.new(3.4, 0.5, 1.2) * CFrame.Angles(-0.1, 1.1, 0.3), 4.6, 3.6, 4, ROCK_DARK, ROCK_MAT)
	r:lump(CFrame.new(-3, 0.4, -1.4) * CFrame.Angles(0.3, 2.2, -0.2), 4.2, 3.4, 3.6, ROCK_LIGHT, ROCK_MAT)
	r:boxAt(CFrame.new(0.6, 2.9, -0.6) * CFrame.Angles(0.15, 0.7, 0.2), 3.2, 2.6, 2.8, ROCK_LIGHT, ROCK_MAT)
end

M.outcropB = function(r: R)
	r:boxAt(CFrame.new(0, 1.4, 0) * CFrame.Angles(0.1, 0.3, -0.12), 6.4, 5.2, 4.6, ROCK_DARK, ROCK_MAT)
	r:boxAt(CFrame.new(-2.6, 0.8, 1.6) * CFrame.Angles(-0.2, 1, 0.1), 4, 3.8, 3.4, ROCK, ROCK_MAT)
	r:lump(CFrame.new(2.8, 0.6, -1) * CFrame.Angles(0.2, 0.4, 0.3), 4.8, 3.6, 4.4, ROCK_LIGHT, ROCK_MAT)
	r:boxAt(CFrame.new(0.8, 3.8, 0.3) * CFrame.Angles(0.2, 1.3, 0.25), 2.6, 2.2, 2.4, ROCK, ROCK_MAT)
	r:lump(CFrame.new(-1.2, 0.2, -2.6) * CFrame.Angles(0, 1.9, 0), 3.2, 2.4, 2.8, ROCK_DARK, ROCK_MAT)
end

-- A timber bench facing local -Z, with two places to sit.
local function bench(r: R, at: CFrame)
	stamp(r, "bench", at, function(q)
		q:box(0, 1.55, 0, 4.8, 0.25, 1.5, TIMBER_LIGHT, "WoodPlanks")
		q:box(0, 2.6, 0.75, 4.8, 1.3, 0.22, TIMBER_LIGHT, "WoodPlanks")
		for _, sx in { -1, 1 } do
			q:box(sx * 2, 0.72, 0, 0.3, 1.44, 1.3, TIMBER, "WoodPlanks")
			q:box(sx * 2, 2.3, 0.75, 0.3, 2, 0.3, TIMBER, "WoodPlanks")
		end
	end, true)
	for _, x in { -1.2, 1.2 } do
		local spot = r:seat(x, 1.68, 0, 180)
		spot.cf = at * spot.cf
	end
end

-- The rock the stair climbs beside. A paved terrace on top, level with the stair's last
-- landing and railed along its drop, with a higher knoll of bare rock at its west end where
-- the pines stand. Its faces are bays of layered rock.
M.lookoutBluff = function(r: R)
	local p = stairProfile()
	local top = p.top
	local x1, x2 = TERRACE_X1, TERRACE_X2
	local foot = hillOver(KNOLL_X1, x2, p.front - 6, p.front) - 12
	-- the rock itself, and the paving on it
	r:block(x1, foot, p.front, x2, top - 0.25, p.back, ROCK, ROCK_MAT)
	r:block(x1, top - 0.25, p.front + 0.9, x2, top, p.back, PAVE, SLAB_MAT)
	if p.neck > p.back then
		r:block(NECK_X1, foot, p.back, x2, top - 0.25, p.neck, ROCK, ROCK_MAT)
		r:block(NECK_X1, top - 0.25, p.back, x2, top, p.neck, PAVE, SLAB_MAT)
	end
	r:noCollide(r:block(x1, top - 0.25, p.front, x2, top + 0.04, p.front + 0.9, STONE, STONE_MAT))
	-- the knoll
	local kt = top + KNOLL_RISE
	r:block(KNOLL_X1, foot, p.front + 1.5, x1, kt, p.knollBack, ROCK, ROCK_MAT)
	r:boxAt(
		CFrame.new(KNOLL_X1 + 7, kt + 0.9, (p.front + p.knollBack) / 2 + 1) * yaw(5),
		9,
		2.2,
		p.knollBack - p.front - 9,
		ROCK_LIGHT,
		ROCK_MAT
	)
	r:lump(
		CFrame.new(x1 - 1.2, kt + 0.2, p.front + 4) * CFrame.Angles(0.2, 0.6, 0.1),
		4.6,
		3.4,
		4.2,
		ROCK_DARK,
		ROCK_MAT
	)
	r:lump(
		CFrame.new(x1 - 0.6, kt - 0.4, p.back - 4) * CFrame.Angles(-0.1, 1.4, 0.2),
		4,
		3.2,
		4.6,
		ROCK_LIGHT,
		ROCK_MAT
	)
	r:lump(
		CFrame.new(KNOLL_X1 + 2, kt + 0.4, p.front + 3.4) * CFrame.Angles(0.1, 2.3, -0.2),
		3.8,
		2.8,
		3.6,
		ROCK,
		ROCK_MAT
	)
	-- the faces: south over the town, east beside the stair, west and south round the knoll
	cliff(r, "a", CFrame.new(x1 + 5.6, top - 0.3, p.front))
	cliff(r, "b", CFrame.new(x2 - 5.6, top - 0.3, p.front))
	cliff(r, "b", CFrame.new(KNOLL_X1 + 6.6, kt - 0.1, p.front + 1.5))
	cliff(r, "flat", CFrame.new(x2, top - 0.3, p.front + 6) * yaw(-90))
	cliff(r, "flat", CFrame.new(x2, top - 0.3, p.front + 16.6) * yaw(-90))
	cliff(r, "a", CFrame.new(KNOLL_X1, kt - 0.1, p.front + 8) * yaw(90))
	cliff(r, "b", CFrame.new(KNOLL_X1, kt - 0.1, p.front + 20) * yaw(90))
	-- boulders fallen at its foot
	for i, b in { { x1 + 3, 3.4 }, { x2 - 8, 2.6 }, { KNOLL_X1 + 4, 3 } } do
		local bx, bz = b[1], p.front - 3.6 - (i % 2) * 1.6
		local by = hillOver(bx - 1, bx + 1, bz - 1, bz + 1)
		r:lump(
			CFrame.new(bx, by + b[2] * 0.2, bz) * CFrame.Angles(0.2 * i, 0.9 * i, 0.1),
			b[2] * 1.5,
			b[2],
			b[2] * 1.3,
			if i % 2 == 0 then ROCK_LIGHT else ROCK_DARK,
			ROCK_MAT
		)
	end
	-- a rail along the drop: over the town, and down the side the stair climbs
	local function fence(at: CFrame)
		stamp(r, "terraceRail", at, function(q)
			q:box(0, 3.2, 0, 5.4, 0.3, 0.36, TIMBER, "Wood")
			q:box(0, 1.9, 0, 5.4, 0.2, 0.2, TIMBER_LIGHT, "Wood")
			q:box(0, 0.8, 0, 5.4, 0.2, 0.2, TIMBER_LIGHT, "Wood")
			for _, sx in { -1, 1 } do
				q:box(sx * 2.5, 1.6, 0, 0.36, 3.2, 0.36, TIMBER, "Wood")
			end
		end, true)
	end
	for i = 0, 3 do
		fence(CFrame.new(x1 + 2.7 + i * 5.4, top, p.front + 0.45))
		fence(CFrame.new(x2 - 0.45, top, p.front + 2.7 + i * 5.4) * yaw(90))
	end
	-- benches along the rail, a telescope, and a lantern at each corner
	bench(r, CFrame.new(x1 + 5.2, top, p.front + 3))
	bench(r, CFrame.new(x2 - 5.6, top, p.front + 3))
	stamp(r, "telescope", CFrame.new((x1 + x2) / 2, top, p.front + 1.5), function(q)
		q:box(0, 0.12, 0, 1, 0.24, 1, IRON, "Metal")
		q:box(0, 1.7, 0, 0.26, 3, 0.26, IRON, "Metal")
		q:beam(Vector3.new(0, 3.7, 1), Vector3.new(0, 3.1, -1.2), 0.56, 0.56, rgb(190, 196, 204), "Metal")
		q:beam(Vector3.new(0, 3.75, 1.2), Vector3.new(0, 3.7, 1), 0.34, 0.34, IRON, "Metal")
	end, true)
	stoneLantern(r, x1 + 1.1, top, p.front + 1.8, 12)
	stoneLantern(r, x2 - 1.4, top, p.front + 1.8, 0)
	Geometry.transform(r.prims, CFrame.new(-(x1 + x2) / 2, 0, -(p.front + p.back) / 2))
end

-- The shelter on the terrace: six posts under a tiled roof, open to the view, a slatted screen
-- behind against the wind, two benches and a lantern.
M.lookoutShelter = function(r: R)
	for _, x in { -5.6, 0, 5.6 } do
		for _, z in { -3.4, 3.4 } do
			r:box(x, 3.8, z, 0.5, 7.6, 0.5, TIMBER, "Wood")
		end
	end
	stamp(r, "shelterFrame", CFrame.identity, function(q)
		for _, sz in { -1, 1 } do
			q:box(0, 7.85, sz * 3.4, 12.6, 0.5, 0.5, TIMBER, "Wood")
		end
		for _, x in { -5.6, 0, 5.6 } do
			q:box(x, 7.85, 0, 0.4, 0.45, 7.4, TIMBER_LIGHT, "Wood")
			q:box(x, 9, 0, 0.36, 1.9, 0.36, TIMBER_LIGHT, "Wood")
		end
		for _, sx in { -1, 1 } do
			for _, sz in { -1, 1 } do
				q:beam(
					Vector3.new(sx * 5.6, 6.2, sz * 3.4),
					Vector3.new(sx * 4.2, 7.6, sz * 3.4),
					0.3,
					0.3,
					TIMBER_LIGHT,
					"Wood"
				)
				q:beam(
					Vector3.new(0, 6.2, sz * 3.4),
					Vector3.new(sx * 1.4, 7.6, sz * 3.4),
					0.3,
					0.3,
					TIMBER_LIGHT,
					"Wood"
				)
			end
			gable(q, sx * 6.5, 0.3, 8.1, 4.4, 2.2, TIMBER_LIGHT, "Wood")
		end
		q:box(0, 10.05, 0, 13.2, 0.3, 0.3, TIMBER, "Wood")
	end)
	stamp(r, "shelterRoof", CFrame.identity, function(q)
		tiles(q, -7, 7, 8.1, 4.4, 2.2, 0.6, 8)
	end)
	r:block(-5.35, 0.6, 3.3, 5.35, 3.8, 3.5, TIMBER_LIGHT, SLAT_MAT)
	bench(r, CFrame.new(-2.8, 0, 2.2))
	bench(r, CFrame.new(2.8, 0, 2.2))
	lantern(r, 0, 7.6, 0, 16)
end

-- Where everything stands ---------------------------------------------------------------------------------

function Landmarks.prims(name: string): { Prim }?
	local build = M[name]
	if not build then
		return nil
	end
	local r = Recipe.new(WHITE, WHITE)
	build(r)
	return r.prims
end

function Landmarks.placements(): { Placement }
	local out: { Placement } = {}
	local function put(name: string, x: number, y: number, z: number, turn: number)
		table.insert(out, { name = name, cf = CFrame.new(x, y, z) * yaw(turn) })
	end
	local PAVING = 0.27 -- the square's paving
	local sq = Town.SquareCenter

	-- the gate, just inside the square where the walk comes in off Main Street
	put("marketGate", sq.X, PAVING, Town.StreetHalfWidth + Town.SidewalkWidth + 2.5, 0)
	put("marketMast", sq.X - 12.5, 0.3, Town.StreetHalfWidth + 1.8, 0)
	put("marketMast", sq.X + 12.5, 0.3, Town.StreetHalfWidth + 1.8, 180)
	-- the hall down the square's west side, open to the fountain
	put("marketHall", sq.X - 43.5, PAVING, sq.Z - 9, -90)
	put("marketGoods", sq.X - 43, PAVING, sq.Z - 33.5, -90)
	-- loose stalls down the east side, north of the tailor
	put("marketTentA", sq.X + 44, PAVING, sq.Z - 15.5, 90)
	put("marketCart", sq.X + 43.4, PAVING, sq.Z - 3.5, 90)
	put("marketTentB", sq.X + 44, PAVING, sq.Z + 8.5, 90)

	-- the footbridge, east of the square where the main street's own crossing is
	local B = Landmarks.Bridge
	put("footbridge", B.x, 0, B.foot, 0)

	-- the hill: the stair, the rock beside it, the shelter on the rock
	local p = stairProfile()
	put("hillStair", STAIR_X, 0, STAIR_Z, 0)
	put("lookoutBluff", (TERRACE_X1 + TERRACE_X2) / 2, 0, (p.front + p.back) / 2, 0)
	put("lookoutShelter", TERRACE_X1 + 10.4, p.top, p.front + 13.6, 0)
	-- pines on the knoll and up the slope behind the rock
	local kt = p.top + KNOLL_RISE
	put("lowPineBig", KNOLL_X1 + 7.5, kt + 1.9, p.front + 10, 40)
	put("lowPine", KNOLL_X1 + 4.5, kt + 1.9, p.front + 20, 150)
	put("lowPine", KNOLL_X1 + 10.5, kt, p.front + 4.6, 260)
	local function onHill(name: string, x: number, z: number, turn: number, sink: number)
		put(name, x, Hills.at(x, z) - sink, z, turn)
	end
	onHill("lowPineBig", TERRACE_X1 + 4, p.back + 7, 80, 0.1)
	onHill("lowPine", TERRACE_X1 + 14, p.back + 10, 200, 0.1)
	onHill("lowPineBig", KNOLL_X1 - 6, p.back + 2, 310, 0.1)
	onHill("lowPine", KNOLL_X1 - 9, p.front + 8, 20, 0.1)
	onHill("lowPine", KNOLL_X1 - 16, p.back - 5, 100, 0.1)
	onHill("lowPineBig", KNOLL_X1 - 21, p.front - 4, 170, 0.1)
	onHill("lowPine", KNOLL_X1 - 12, p.front - 15, 230, 0.1)
	onHill("lowPineBig", TERRACE_X1 - 6, p.back + 19, 290, 0.1)
	onHill("lowPine", STAIR_X + 40, p.front - 8, 60, 0.1)
	onHill("lowPineBig", STAIR_X + 45, p.front + 14, 130, 0.1)
	onHill("lowPine", STAIR_X + 37, p.back + 8, 340, 0.1)
	-- rock coming out of the slope beside the stair and under the bluff
	onHill("outcropA", STAIR_X + 12.5, p.flights[1].z + 6, 30, 1.2)
	onHill("outcropB", STAIR_X + 13, p.flights[3].z + 2, 200, 1.4)
	onHill("outcropB", STAIR_X - 13.5, p.flights[1].z - 2, 110, 1.4)
	onHill("outcropA", KNOLL_X1 - 5, p.front - 5, 250, 1.2)
	onHill("outcropA", STAIR_X + 11, p.landings[#p.landings].z2 + 4, 140, 1.4)
	onHill("outcropB", STAIR_X + 42, p.front + 3, 320, 1.4)
	onHill("outcropB", KNOLL_X1 - 16, p.front + 12, 70, 1.4)
	return out
end

return Landmarks
