--!strict
-- The town's street buildings, drawn from a kit of facade parts (see docs/GAME_DESIGN.md, "A
-- denser, more detailed town"). TownMap.prims asks here first for a model by name.
--
-- A building is made from a spec: how wide, how deep, how many storeys, and a seed that picks
-- the rest (the shop on the ground floor, the windows, the colours, what is on the roof). They
-- stand wall to wall, so each is a solid box with its detail on the street face only: a shop
-- front between two piers, storeys of window bays, a parapet or a tiled roof. A corner building
-- has a second street face. A few can be walked into (`inside`): their ground floor is a room
-- from Data/Interiors behind the same kind of front.
--
-- Every detail that repeats is a piece (Geometry.piece): drawn once round its own origin, kept,
-- and stamped wherever it is wanted, so the same window is the same mesh all over town. Windows
-- that light up, name boards and posters stay ordinary parts, because the game looks for them.
--
-- Space: the model's origin is the middle of the footprint on the ground, the front faces local
-- -Z (as in Data/CityModels). A wall is drawn in "face space": x along the wall, y up, the wall's
-- own surface at z = 0 and everything on it reaching toward -z.
--
-- Names: "facade:<w>x<d>:<storeys>:<seed>" and then any of ":cl" / ":cr" (a second street face
-- on the left or right, seen from the front), ":sign=<kind>" (whose name goes over the door, a
-- key of Data/Signs.Shops), ":in=<kind>" (a room to walk into, a kind Data/Interiors furnishes),
-- ":shop=<kind>", ":top=<flat|pitched>", ":nb" (another building stands against its back, which
-- is left bare), ":wall=<n>", ":look=<n>". Facades.name writes one from a spec. The presets in Facades.Presets have plain names.

local Recipe = require(script.Parent.Parent.Build.Recipe)
local Geometry = require(script.Parent.Parent.Build.Geometry)
local CityModels = require(script.Parent.CityModels)
local Interiors = require(script.Parent.Interiors)

type R = Recipe.Recipe
type Prim = Geometry.Prim

local Facades = {}

export type Spec = {
	w: number, -- the frontage: 12 to 34 studs in a row, up to 80 for a big shop
	d: number, -- front to back
	storeys: number, -- the ground floor and those above it, 2 to 8
	seed: number,
	corner: string?, -- "left" or "right": that side is a street face too
	shop: string?, -- the ground floor: one of Facades.Shops (picked by the seed when left out)
	top: string?, -- "flat" or "pitched"
	wall: number?, -- which of Facades.Walls
	look: number?, -- which of Facades.Looks
	sign: string?, -- the kind of place whose name is on it; none leaves the board bare
	inside: string?, -- the kind of room behind the door, for a building people can walk into
	back: boolean?, -- false when another building stands against its back, which is then left bare
}

-- The ground floor is as tall as the shops in Data/CityModels, and so are the storeys.
Facades.Ground = 8.4
Facades.Storey = 4.4
Facades.Reach = 3.4 -- how far an awning, a step or a stool may stand out from a street face
Facades.BackReach = 0.9 -- and a back door's step from the back wall
local G = Facades.Ground
local FH = Facades.Storey
local TOP = 0.6

-- How high the walls of a building of so many storeys stand.
function Facades.height(storeys: number): number
	return G + (storeys - 1) * FH + TOP
end

local function rgb(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end

local function shade(c: Color3, k: number): Color3
	return Color3.new(math.min(1, c.R * k), math.min(1, c.G * k), math.min(1, c.B * k))
end

local WHITE = rgb(250, 246, 236)
local CREAM = rgb(250, 246, 236)
local STONE = rgb(214, 208, 198)
local DARK = rgb(64, 70, 86)
local METAL = rgb(176, 182, 190)
local BRASS = rgb(222, 178, 82)
local GLASS = rgb(150, 206, 240) -- a window that lights up, by day
local PANE = rgb(118, 164, 196) -- the glass drawn into a window's own piece
local DIM = rgb(66, 58, 62) -- a room seen from the street by day
local TIMBER = rgb(154, 107, 72)
local TIMBER_PALE = rgb(196, 154, 108)
local DECKS = { rgb(170, 164, 156), rgb(186, 176, 160), rgb(156, 160, 164), rgb(178, 140, 122), rgb(146, 168, 156) }

local PLAIN = "SmoothPlastic"

-- What the walls are made of: one of the painted looks and a warm colour for it.
Facades.Walls = {
	{ mat = "Concrete:Stucco", color = rgb(242, 226, 198) },
	{ mat = "Concrete:Stucco", color = rgb(240, 205, 176) },
	{ mat = "Concrete:Stucco", color = rgb(234, 192, 170) },
	{ mat = "Concrete:Stucco", color = rgb(243, 223, 166) },
	{ mat = "Concrete:Stucco", color = rgb(200, 222, 208) },
	{ mat = "Concrete:Panel", color = rgb(212, 202, 188) },
	{ mat = "Concrete:Panel", color = rgb(228, 212, 180) },
	{ mat = "Brick:Maple", color = rgb(204, 142, 118) },
	{ mat = "Brick:Maple", color = rgb(214, 170, 134) },
	{ mat = "CeramicTiles:Mosaic", color = rgb(228, 180, 150) },
	{ mat = "CeramicTiles:Mosaic", color = rgb(150, 190, 178) },
	{ mat = "CeramicTiles:Mosaic", color = rgb(238, 228, 208) },
} :: { { mat: string, color: Color3 } }

-- A ground floor that isn't the wall above it: dark brick, glazed tile or timber slats.
local BASES = {
	{ mat = "Brick:Maple", color = rgb(172, 112, 94) },
	{ mat = "CeramicTiles:Mosaic", color = rgb(76, 122, 116) },
	{ mat = "WoodPlanks:Slats", color = rgb(158, 116, 82) },
	{ mat = "CeramicTiles:Mosaic", color = rgb(94, 110, 150) },
} :: { { mat: string, color: Color3 } }

-- A storey added on the roof later, in sheet metal.
local ATTICS = { rgb(158, 180, 190), rgb(180, 124, 104), rgb(214, 206, 184) }

-- Paint. The trims are few because every window comes in each of them; the awnings are the
-- strong colours of the street.
local TRIMS = {
	{
		id = "c",
		color = CREAM,
		shutter = rgb(72, 128, 122),
		riser = rgb(70, 112, 106),
		doors = { rgb(52, 92, 80), rgb(166, 78, 80) },
		shade = rgb(62, 128, 104),
	},
	{
		id = "b",
		color = rgb(108, 76, 56),
		shutter = rgb(140, 98, 66),
		riser = rgb(150, 96, 80),
		doors = { rgb(112, 78, 54), rgb(70, 96, 142) },
		shade = rgb(222, 180, 100),
	},
	{
		id = "g",
		color = rgb(60, 112, 98),
		shutter = rgb(232, 222, 200),
		riser = rgb(196, 188, 172),
		doors = { rgb(70, 74, 88), rgb(166, 78, 80) },
		shade = rgb(222, 138, 104),
	},
}
local AWNINGS = {
	{ id = "r", color = rgb(194, 98, 90) },
	{ id = "g", color = rgb(66, 132, 110) },
	{ id = "n", color = rgb(70, 96, 142) },
	{ id = "y", color = rgb(226, 184, 98) },
	{ id = "t", color = rgb(222, 138, 104) },
}
local ROOFS = { rgb(194, 126, 99), rgb(184, 102, 92), rgb(108, 126, 144) }
local APRONS = { rgb(236, 226, 208), rgb(226, 170, 146), rgb(150, 196, 186), rgb(236, 210, 154) }

-- A look is a trim and an awning that go together. (A trim brings its own doors, the tiles
-- under its shop windows and the canvas over its upstairs windows: those are drawn into pieces,
-- and there should not be too many different pieces.)
Facades.Looks = {
	{ trim = 1, awning = 1 },
	{ trim = 1, awning = 2 },
	{ trim = 1, awning = 3 },
	{ trim = 2, awning = 4 },
	{ trim = 2, awning = 5 },
	{ trim = 2, awning = 2 },
	{ trim = 3, awning = 5 },
	{ trim = 3, awning = 4 },
} :: { { trim: number, awning: number } }

-- The kinds of ground floor: a glazed shop front under an awning, a roller shutter half down,
-- a counter open to the pavement under a tiled lean-to, a house door with windows, a garage.
Facades.Shops = { "glazed", "shutter", "counter", "door", "garage" }

-- Dice ------------------------------------------------------------------------------------------------
-- Whole number sums only, so a seed gives the same building in Roblox as in the specs.

type Dice = { float: () -> number, int: (number, number) -> number, chance: (number) -> boolean }

local function dice(seed: number): Dice
	local s = (math.floor(seed) * 7919 + 104729) % 2147483647
	if s == 0 then
		s = 1
	end
	local function float(): number
		s = (s * 48271) % 2147483647
		return s / 2147483647
	end
	for _ = 1, 4 do
		float()
	end
	return {
		float = float,
		int = function(a: number, b: number): number
			return a + math.floor(float() * (b - a + 1))
		end,
		chance = function(p: number): boolean
			return float() < p
		end,
	}
end
Facades.dice = dice

local function pick<T>(d: Dice, list: { T }): T
	return list[d.int(1, #list)]
end

-- Pieces ----------------------------------------------------------------------------------------------

-- Every piece made so far, by its own name. A piece is drawn once, round its own origin, with
-- the same numbers every time, so its key never wavers; using it again is a copy with a new place.
local kit: { [string]: Prim } = {}

local function piece(id: string, draw: (R) -> ()): Prim
	local made: Prim? = kit[id]
	if made then
		return made
	end
	local q = Recipe.new(WHITE, WHITE)
	draw(q)
	local new = Geometry.piece(q.prims, false)
	kit[id] = new
	return new
end

-- A wall being drawn on: `f` takes face space to the model's.
type Face = { f: CFrame, w: number, out: { Prim } }

local function add(face: Face, prim: Prim): Prim
	prim.cf = face.f * prim.cf
	table.insert(face.out, prim)
	return prim
end

local function block(
	face: Face,
	x1: number,
	y1: number,
	z1: number,
	x2: number,
	y2: number,
	z2: number,
	color: Color3,
	mat: string?
): Prim
	return add(face, Geometry.span(Vector3.new(x1, y1, z1), Vector3.new(x2, y2, z2), color, mat))
end

local function stamp(face: Face, id: string, x: number, y: number, draw: (R) -> ()): Prim
	local made = piece(id, draw)
	local p = table.clone(made)
	p.cf = face.f * CFrame.new(x, y, 0) * made.cf
	table.insert(face.out, p)
	return p
end

-- A pane that is glass by day and lamplight after dark, just proud of the glass in the piece
-- behind it and behind that piece's bars.
local pen = Recipe.new(WHITE, WHITE)
local function lit(face: Face, x1: number, y1: number, x2: number, y2: number, color: Color3?): Prim
	local pane = block(face, x1, y1, -0.14, x2, y2, -0.1, color or GLASS, "Glass")
	pane.collide = false
	return CityModels.lit(pen, pane)
end

-- Windows ---------------------------------------------------------------------------------------------
-- Each is drawn with y = 0 at its storey's floor and x = 0 at the middle of its bay. The glass
-- is in the piece, so a window that never lights up is one part.

local SILL, HEAD = 1, 3.5

-- An opening `hw` either side of the middle: the glass, a head, two jambs and a sill.
local function opening(q: R, hw: number, y1: number, y2: number, trim: Color3)
	q:block(-hw, y1, -0.1, hw, y2, 0, PANE)
	q:block(-hw - 0.3, y2, -0.4, hw + 0.3, y2 + 0.3, 0, trim)
	q:block(-hw - 0.3, y1, -0.3, -hw, y2, 0, trim)
	q:block(hw, y1, -0.3, hw + 0.3, y2, 0, trim)
	q:block(-hw - 0.5, y1 - 0.25, -0.6, hw + 0.5, y1, 0, trim)
end

local function single(q: R, trim: Color3)
	opening(q, 1.3, SILL, HEAD, trim)
	q:block(-0.07, SILL, -0.22, 0.07, HEAD, -0.1, trim)
	q:block(-1.3, 2.62, -0.22, 1.3, 2.76, -0.1, trim)
end

type Window = { class: string, half: number, hw: number, y1: number, y2: number, draw: (R, any, any) -> () }

-- (the trim and the awning a window is drawn with are entries of TRIMS and AWNINGS)
local WINDOWS: { [string]: Window } = {
	single = {
		class = "N",
		half = 1.8,
		hw = 1.3,
		y1 = SILL,
		y2 = HEAD,
		draw = function(q: R, trim: any, _awning: any)
			single(q, trim.color)
		end,
	},
	-- a window with a box of flowers on its sill
	flower = {
		class = "N",
		half = 1.8,
		hw = 1.3,
		y1 = SILL,
		y2 = HEAD,
		draw = function(q: R, trim: any, _awning: any)
			single(q, trim.color)
			q:block(-1.7, 0.45, -1, 1.7, 0.95, -0.5, rgb(172, 118, 92))
			q:block(-1.55, 0.95, -0.95, 1.55, 1.2, -0.55, rgb(86, 150, 84))
			for i, x in { -1.2, -0.4, 0.4, 1.2 } do
				local col = if i % 2 == 0 then rgb(250, 130, 150) else rgb(248, 210, 112)
				q:block(x - 0.22, 1.15, -0.98, x + 0.22, 1.55, -0.56, col)
			end
		end,
	},
	-- two lights with a post between them
	pair = {
		class = "W",
		half = 2.8,
		hw = 2.3,
		y1 = SILL,
		y2 = HEAD,
		draw = function(q: R, trim: any, _awning: any)
			opening(q, 2.3, SILL, HEAD, trim.color)
			q:block(-0.3, SILL, -0.3, 0.3, HEAD, 0, trim.color)
			q:block(-2.3, 2.62, -0.22, -0.3, 2.76, -0.1, trim.color)
			q:block(0.3, 2.62, -0.22, 2.3, 2.76, -0.1, trim.color)
		end,
	},
	-- one long window in four lights
	wide = {
		class = "W",
		half = 3.1,
		hw = 2.6,
		y1 = SILL,
		y2 = HEAD,
		draw = function(q: R, trim: any, _awning: any)
			opening(q, 2.6, SILL, HEAD, trim.color)
			for _, x in { -1.3, 0, 1.3 } do
				q:block(x - 0.07, SILL, -0.22, x + 0.07, HEAD, -0.1, trim.color)
			end
		end,
	},
	-- a glazed door onto a balcony with a rail
	balcony = {
		class = "W",
		half = 2.8,
		hw = 1.5,
		y1 = 0.3,
		y2 = 3.6,
		draw = function(q: R, trim: any, _awning: any)
			q:block(-1.5, 0.3, -0.1, 1.5, 3.6, 0, PANE)
			q:block(-1.8, 3.6, -0.4, 1.8, 3.9, 0, trim.color)
			q:block(-1.8, 0.3, -0.3, -1.5, 3.6, 0, trim.color)
			q:block(1.5, 0.3, -0.3, 1.8, 3.6, 0, trim.color)
			q:block(-0.08, 0.3, -0.22, 0.08, 3.6, -0.1, trim.color)
			-- the slab, with a lip, and the rail round it
			q:block(-2.8, -0.1, -2, 2.8, 0.3, 0, STONE)
			q:block(-2.8, 1.72, -2, 2.8, 1.86, -1.86, DARK)
			q:block(-2.8, 0.5, -1.98, 2.8, 0.6, -1.88, DARK)
			for _, sx in { -1, 1 } do
				q:block(sx * 2.8, 1.72, -1.86, sx * 2.66, 1.86, 0, DARK)
				q:block(sx * 2.78, 0.3, -1, sx * 2.68, 1.72, -0.9, DARK)
			end
			for k = 0, 8 do
				local x = -2.73 + k * 0.6825
				q:block(x - 0.05, 0.3, -1.98, x + 0.05, 1.72, -1.88, DARK)
			end
		end,
	},
	-- a window between two louvred shutters
	shutter = {
		class = "W",
		half = 2.8,
		hw = 1.3,
		y1 = SILL,
		y2 = HEAD,
		draw = function(q: R, trim: any, _awning: any)
			single(q, trim.color)
			for _, sx in { -1, 1 } do
				q:block(sx * 1.62, SILL, -0.16, sx * 2.72, HEAD, 0, trim.shutter)
				for k = 0, 4 do
					local y = SILL + 0.3 + k * 0.48
					q:block(sx * 1.72, y, -0.24, sx * 2.62, y + 0.14, -0.16, shade(trim.shutter, 0.82))
				end
			end
		end,
	},
	-- two lights under a little canvas awning
	awned = {
		class = "W",
		half = 2.9,
		hw = 2.3,
		y1 = SILL,
		y2 = HEAD,
		draw = function(q: R, trim: any, _awning: any)
			opening(q, 2.3, SILL, HEAD, trim.color)
			q:block(-0.3, SILL, -0.3, 0.3, HEAD, 0, trim.color)
			q:wedge(CFrame.new(0, 3.85, -0.85), 5.8, 0.6, 1.7, trim.shade)
			q:block(-2.9, 3.2, -1.7, 2.9, 3.56, -1.62, CREAM)
			for _, x in { -1.9, 0, 1.9 } do
				q:block(x - 0.48, 3.2, -1.72, x + 0.48, 3.56, -1.7, trim.shade)
			end
		end,
	},
}

-- Shop fronts ------------------------------------------------------------------------------------------
-- Drawn with y = 0 on the pavement and x = 0 at the middle of the unit.

-- A glazed front `w` wide: tiled risers, a window either side of the door, a transom rail.
local function glazed(q: R, w: number, trim: Color3, riser: Color3, door: Color3)
	local h = w / 2
	q:block(-h, 6.4, -0.35, h, 6.7, 0, trim)
	for _, sx in { -1, 1 } do
		q:block(sx * h, 0, -0.35, sx * 1.9, 1.1, 0, riser)
		q:block(sx * h, 1.1, -0.3, sx * (h - 0.3), 6.4, 0, trim)
		q:block(sx * 1.9, 0, -0.3, sx * 1.6, 6.4, 0, trim)
		q:block(sx * (h - 0.3), 5.1, -0.25, sx * 1.9, 5.3, 0, trim)
		q:block(sx * (h - 0.3), 1.1, -0.1, sx * 1.9, 6.4, 0, PANE)
		local mid = sx * (h + 1.6) / 2
		q:block(mid - 0.07, 1.1, -0.25, mid + 0.07, 5.1, -0.1, trim)
	end
	q:block(-1.6, 0.15, -0.22, 1.6, 6.4, 0, door)
	q:block(-1.1, 2.4, -0.27, 1.1, 5.9, -0.22, PANE)
	q:block(0.95, 3, -0.36, 1.1, 3.8, -0.27, BRASS)
	q:block(-2.1, 0, -1, 2.1, 0.15, 0, STONE)
end

-- A roller shutter, half down over a dim shop with a couple of crates inside, or right down.
local function roller(q: R, slats: Color3, down: boolean)
	q:block(-5, 6, -0.5, 5, 6.7, 0, shade(slats, 0.8), "Metal:Shutter")
	for _, sx in { -1, 1 } do
		q:block(sx * 5, 0, -0.3, sx * 4.7, 6, 0, shade(slats, 0.7), "Metal:Shutter")
	end
	local foot = if down then 0.25 else 2.9
	q:block(-4.7, foot, -0.2, 4.7, 6, 0, slats, "Metal:Shutter")
	q:block(-4.7, foot - 0.18, -0.26, 4.7, foot, 0, shade(slats, 0.6), "Metal:Shutter")
	if down then
		q:block(-0.5, 0.5, -0.27, 0.5, 0.75, -0.2, shade(slats, 0.6), "Metal:Shutter")
	else
		q:block(-3.6, 0, -0.4, -2, 1.3, -0.16, TIMBER_PALE, "Metal:Shutter")
		q:block(-1.9, 0, -0.34, -0.7, 0.9, -0.16, rgb(96, 150, 190), "Metal:Shutter")
		q:block(1.2, 0, -0.4, 3.4, 1.7, -0.16, TIMBER, "Metal:Shutter")
	end
end

-- A counter open to the pavement: slatted timber under a worktop, posts, a rail with short
-- curtains, a shelf of jars at the back, stools in front and two paper lanterns.
local function counter(q: R, cloth: Color3)
	local MAT = "WoodPlanks:Slats"
	q:block(-5.6, 0, -0.9, 5.6, 3, -0.5, TIMBER, MAT)
	q:block(-5.8, 3, -1.2, 5.8, 3.3, 0, TIMBER_PALE, MAT)
	q:block(-6, 6.15, -0.5, 6, 6.6, 0, shade(TIMBER, 0.8), MAT)
	for _, sx in { -1, 1 } do
		q:block(sx * 6, 0, -0.5, sx * 5.6, 6.15, 0, shade(TIMBER, 0.8), MAT)
	end
	for k = 0, 3 do
		local x = -5.4 + k * 2.8
		q:block(x, 5, -0.46, x + 2.4, 6.15, -0.38, if k % 2 == 0 then cloth else CREAM, MAT)
	end
	q:block(-5, 4.2, -0.34, 5, 4.34, -0.14, TIMBER_PALE, MAT)
	for i, x in { -4, -2.6, 1.8, 3.4 } do
		local col = ({ rgb(220, 128, 106), rgb(120, 176, 150), rgb(238, 200, 110), rgb(240, 236, 226) })[i]
		q:block(x - 0.3, 4.34, -0.34, x + 0.3, 4.34 + 0.4 + (i % 2) * 0.2, -0.16, col, MAT)
	end
	for _, x in { -4.2, -1.4, 1.4, 4.2 } do
		q:cyl(x, 2.15, -2.3, 0.3, 1.1, "y", TIMBER_PALE, MAT)
		q:cyl(x, 1, -2.3, 2, 0.26, "y", DARK, MAT)
	end
	for _, x in { -5, 5 } do
		q:block(x - 0.04, 5.3, -2.24, x + 0.04, 5.9, -2.16, DARK, MAT)
		q:cyl(x, 4.85, -2.2, 0.9, 0.8, "y", rgb(216, 108, 88), MAT)
	end
end

-- The tiled lean-to over a counter: a slope of barrel tiles, its edge board and two struts.
local function leanTo(q: R, tiles: Color3)
	local MAT = "ClayRoofTiles:Barrel"
	q:block(-6.3, 5.86, -3.34, 6.3, 6.1, -3.14, shade(tiles, 0.72), MAT)
	local run, drop = 3.3, 1.3
	local len = math.sqrt(run * run + drop * drop)
	local slope = CFrame.new(0, 6.86, -run / 2) * CFrame.Angles(-math.atan2(drop, run), 0, 0)
	q:boxAt(slope, 12.6, 0.28, len, tiles, MAT)
	for _, sx in { -1, 1 } do
		q:beam(Vector3.new(sx * 5.8, 5.2, 0), Vector3.new(sx * 5.8, 6.2, -2.6), 0.2, 0.2, shade(tiles, 0.6), MAT)
	end
end

-- A house door beside a small window: a panelled leaf under a fanlight, a step, a wall lamp.
local function houseDoor(q: R, trim: Color3, door: Color3)
	q:block(-0.9, 6.4, -0.35, 2.9, 6.7, 0, trim)
	q:block(-0.9, 0, -0.3, -0.6, 6.4, 0, trim)
	q:block(2.6, 0, -0.3, 2.9, 6.4, 0, trim)
	q:block(-0.6, 0.15, -0.16, 2.6, 5.5, 0, door)
	q:block(-0.1, 0.7, -0.22, 2.1, 2.5, -0.16, shade(door, 1.18))
	q:block(-0.1, 3, -0.22, 2.1, 5, -0.16, shade(door, 1.18))
	q:block(2.2, 2.7, -0.3, 2.36, 3.3, -0.16, BRASS)
	q:block(0.5, 2.62, -0.2, 1.5, 2.82, -0.16, BRASS)
	q:block(-0.6, 5.5, -0.25, 2.6, 5.7, 0, trim)
	q:block(-0.6, 5.7, -0.1, 2.6, 6.4, 0, PANE)
	q:block(0.93, 5.7, -0.2, 1.07, 6.4, -0.1, trim)
	q:block(-1.1, 0, -0.9, 3.1, 0.15, 0, STONE)
	-- the little window
	q:block(-2.6, 3.4, -0.1, -1.5, 5.6, 0, PANE)
	q:block(-2.8, 5.6, -0.3, -1.3, 5.8, 0, trim)
	q:block(-2.8, 3.2, -0.4, -1.3, 3.4, 0, trim)
	q:block(-2.8, 3.4, -0.25, -2.6, 5.6, 0, trim)
	q:block(-1.5, 3.4, -0.25, -1.3, 5.6, 0, trim)
	q:block(-2.6, 4.44, -0.2, -1.5, 4.56, -0.1, trim)
	-- the lamp
	q:block(-2.12, 6.5, -0.5, -1.98, 6.62, 0, DARK)
	q:block(-2.3, 5.98, -0.74, -1.8, 6.5, -0.26, rgb(255, 236, 190))
end

-- A garage door in ribbed sheet with a row of small lights, hazard paint on the posts and a
-- ramp over the kerb.
local function garage(q: R, sheet: Color3)
	local MAT = "Metal:Corrugated"
	q:block(-5, 6.2, -0.35, 5, 6.7, 0, shade(sheet, 0.7), MAT)
	for _, sx in { -1, 1 } do
		q:block(sx * 5, 1.2, -0.3, sx * 4.6, 6.2, 0, shade(sheet, 0.7), MAT)
		q:block(sx * 5, 0, -0.32, sx * 4.6, 1.2, 0, rgb(244, 196, 66), MAT)
		q:block(sx * 5, 0.4, -0.34, sx * 4.6, 0.8, 0, DARK, MAT)
	end
	q:block(-4.6, 0.1, -0.15, 4.6, 6.2, 0, sheet, MAT)
	for _, y in { 1.6, 3.1, 4.6 } do
		q:block(-4.6, y, -0.2, 4.6, y + 0.12, -0.15, shade(sheet, 0.78), MAT)
	end
	for k = 0, 3 do
		local x = -3.3 + k * 2.2
		q:block(x - 0.7, 4.95, -0.19, x + 0.7, 5.6, -0.15, PANE, MAT)
	end
	q:block(-0.6, 0.9, -0.24, 0.6, 1.08, -0.15, DARK, MAT)
	q:wedge(CFrame.new(0, 0.09, -0.6), 9.2, 0.18, 1.2, STONE, MAT)
end

-- A canvas awning `w` wide over a shop: stripes sloping down from a rail on the wall, a
-- valance hanging from its front edge and an arm at each end.
local AWNING_RUN, AWNING_DROP = 3, 1
local function awning(q: R, w: number, canvas: Color3)
	local MAT = "Fabric:Canvas"
	local h = w / 2
	q:block(-h, 6.94, -0.16, h, 7.1, 0, DARK, MAT)
	local len = math.sqrt(AWNING_RUN * AWNING_RUN + AWNING_DROP * AWNING_DROP)
	local tilt = CFrame.Angles(-math.atan2(AWNING_DROP, AWNING_RUN), 0, 0)
	local n = 6
	for k = 0, n - 1 do
		local x = -h + (k + 0.5) * w / n
		local col = if k % 2 == 0 then canvas else CREAM
		q:boxAt(CFrame.new(x, 7 - AWNING_DROP / 2, -AWNING_RUN / 2) * tilt, w / n, 0.14, len, col, MAT)
		q:block(x - w / n / 2, 5.5, -AWNING_RUN - 0.06, x + w / n / 2, 6.04, -AWNING_RUN + 0.04, col, MAT)
	end
	for _, sx in { -1, 1 } do
		local x = sx * (h - 0.1)
		q:beam(Vector3.new(x, 5.7, 0), Vector3.new(x, 5.95, -AWNING_RUN + 0.1), 0.1, 0.1, DARK, MAT)
	end
end

-- A pier at the end of a shop front: a plinth, a shaft and a cap up to the first floor.
local PIERS = {
	{ mat = "Brick:Maple", color = rgb(180, 116, 96) },
	{ mat = "Brick:Maple", color = rgb(200, 148, 108) },
	{ mat = "Concrete:Panel", color = rgb(204, 198, 188) },
	{ mat = "CeramicTiles:Mosaic", color = rgb(74, 120, 112) },
	{ mat = "Concrete:Stucco", color = rgb(240, 230, 210) },
} :: { { mat: string, color: Color3 } }
local function pier(q: R, look: { mat: string, color: Color3 })
	q:block(-0.5, 0.6, -0.26, 0.5, 7.9, 0, look.color, look.mat)
	q:block(-0.6, 0, -0.4, 0.6, 0.6, 0, shade(look.color, 0.8), look.mat)
	q:block(-0.6, 7.9, -0.4, 0.6, G, 0, shade(look.color, 1.1), look.mat)
end

-- Things on the wall ---------------------------------------------------------------------------------

-- A square downpipe from a hopper under the roof to a shoe at the pavement, clipped to the wall
-- at every storey. Drawn with y = 0 on the pavement.
local function downpipe(q: R, height: number)
	q:block(-0.16, 0.3, -0.4, 0.16, height - 0.9, -0.1, DARK)
	q:block(-0.38, height - 0.9, -0.56, 0.38, height - 0.3, 0, DARK)
	q:block(-0.16, 0, -0.75, 0.16, 0.3, -0.1, DARK)
	local y = 3
	while y < height - 2 do
		q:block(-0.3, y, -0.44, 0.3, y + 0.14, 0, METAL)
		y += FH
	end
end

-- An air conditioner's outdoor box on two brackets, its pipe running up the wall. Drawn with
-- y = 0 at the bottom of the brackets.
local function airCon(q: R)
	q:block(-1.1, 0.14, -0.98, 1.1, 1.22, -0.08, rgb(236, 230, 216))
	q:block(-0.86, 0.3, -1.03, 0.2, 1.06, -0.98, DARK)
	q:block(-0.42, 0.6, -1.06, -0.24, 0.76, -1.03, METAL)
	q:block(0.42, 0.34, -1.02, 0.92, 0.44, -0.98, METAL)
	q:block(0.42, 0.56, -1.02, 0.92, 0.66, -0.98, METAL)
	for _, sx in { -1, 1 } do
		q:block(sx * 0.8 - 0.06, 0, -1, sx * 0.8 + 0.06, 0.14, 0, DARK)
	end
	q:block(1.14, 0.5, -0.2, 1.26, 1.3, -0.06, METAL)
end

-- An electricity meter in its box, a smaller box beside it and the conduit up the wall.
local function meter(q: R)
	q:block(-0.6, 3.1, -0.34, 0.6, 4.9, 0, rgb(206, 208, 212))
	q:block(-0.42, 3.9, -0.38, 0.42, 4.7, -0.34, rgb(92, 104, 122))
	q:block(-0.42, 3.3, -0.38, 0.1, 3.7, -0.34, rgb(236, 200, 96))
	q:block(0.8, 3.5, -0.26, 1.4, 4.3, 0, rgb(186, 190, 196))
	q:block(-0.07, 4.9, -0.2, 0.07, 7.6, -0.06, DARK)
	q:block(0.6, 3.84, -0.18, 0.8, 3.96, -0.06, DARK)
end

-- The two arms a blade sign hangs on, `rise` apart.
local function bladeArms(q: R, rise: number)
	q:block(-0.12, 0, -0.7, 0.12, 0.25, 0, DARK)
	q:block(-0.12, rise, -0.7, 0.12, rise + 0.25, 0, DARK)
end

-- The back of a building, all in one piece: a door with a step and a lamp, a barred window, the
-- kitchen's vent and its duct, a gas box, a downpipe, and a pair of small windows to each of
-- `rows` storeys. Drawn with y = 0 on the ground and x = 0 at the middle of the back wall.
local function backWall(q: R, rows: number)
	local top = G + rows * FH
	q:block(-5, 0.15, -0.12, -2.4, 6, 0, rgb(86, 100, 120))
	q:block(-5.2, 6, -0.25, -2.2, 6.25, 0, CREAM)
	q:block(-5.3, 0, -0.8, -2.1, 0.15, 0, STONE)
	q:block(-3.95, 6.5, -0.5, -3.45, 6.9, 0, rgb(255, 236, 190))
	q:block(1, 3.6, -0.1, 4, 5.6, 0, PANE)
	q:block(0.8, 3.36, -0.3, 4.2, 3.6, 0, CREAM)
	q:block(0.8, 5.6, -0.2, 4.2, 5.8, 0, CREAM)
	for _, x in { 1.75, 2.5, 3.25 } do
		q:block(x - 0.05, 3.6, -0.2, x + 0.05, 5.6, -0.14, DARK)
	end
	q:block(-1.4, 5.2, -0.5, -0.4, 6.2, 0, METAL)
	q:block(-1.05, 6.2, -0.4, -0.75, top - 0.6, -0.1, METAL)
	q:block(-1.7, 0.4, -0.4, -0.3, 1.6, 0, rgb(206, 208, 212))
	q:block(5.2, 0.3, -0.4, 5.5, top, -0.1, DARK)
	q:block(5, top, -0.56, 5.7, top + 0.5, 0, DARK)
	for row = 0, rows - 1 do
		local y = G + row * FH
		for _, x in { -3.6, 2.5 } do
			q:block(x - 1, y + 1.2, -0.1, x + 1, y + 3.3, 0, PANE)
			q:block(x - 1.2, y + 0.96, -0.3, x + 1.2, y + 1.2, 0, CREAM)
			q:block(x - 1.2, y + 3.3, -0.2, x + 1.2, y + 3.5, 0, CREAM)
		end
	end
end

-- A cloth banner hanging from an arm, for a shop with no name to put out.
local function banner(q: R, cloth: Color3)
	q:block(-0.1, 4.3, -2.3, 0.1, 4.5, 0, DARK)
	q:block(-0.06, 0.2, -2.2, 0.06, 4.3, -0.6, cloth)
	q:block(-0.08, 3.3, -2.2, 0.08, 3.7, -0.6, CREAM)
	q:block(-0.08, 0.9, -2.2, 0.08, 1.1, -0.6, CREAM)
	q:block(-0.1, 0.1, -2.25, 0.1, 0.2, -0.55, DARK)
end

-- Things on the roof ---------------------------------------------------------------------------------
-- Drawn round their own middle with y = 0 on the roof. Each says how much roof it needs.

type Clutter = { id: string, w: number, d: number, draw: (R) -> () }

local CLUTTER: { Clutter } = {
	-- a water tank on a steel frame, with a ladder
	{
		id = "tank",
		w = 3.8,
		d = 3.8,
		draw = function(q: R)
			q:block(-1.5, 2, -1.5, 1.5, 2.2, 1.5, DARK)
			for _, sx in { -1, 1 } do
				for _, sz in { -1, 1 } do
					q:block(sx * 1.4 - 0.1, 0, sz * 1.4 - 0.1, sx * 1.4 + 0.1, 2, sz * 1.4 + 0.1, DARK)
				end
				q:beam(Vector3.new(sx * 1.4, 0.2, -1.4), Vector3.new(sx * 1.4, 1.9, 1.4), 0.1, 0.1, DARK)
			end
			q:cyl(0, 3.7, 0, 3, 3.1, "y", rgb(226, 220, 206))
			q:cyl(0, 5.3, 0, 0.2, 3.3, "y", rgb(96, 150, 160))
			for _, sx in { -1, 1 } do
				q:block(sx * 0.3 - 0.04, 0, -1.74, sx * 0.3 + 0.04, 5.1, -1.66, METAL)
			end
			for _, y in { 1, 2.2, 3.4, 4.6 } do
				q:block(-0.3, y, -1.73, 0.3, y + 0.08, -1.67, METAL)
			end
		end,
	},
	-- the hut over the stairs, with its door and a lamp
	{
		id = "hut",
		w = 4.4,
		d = 5,
		draw = function(q: R)
			q:block(-1.9, 0, -2.3, 1.9, 4.6, 2.3, rgb(226, 216, 198))
			q:block(-2.1, 4.6, -2.6, 2.1, 4.9, 2.5, STONE)
			q:block(-1.1, 0, -2.38, 0.5, 3.9, -2.3, rgb(86, 100, 120))
			q:block(0.2, 1.8, -2.44, 0.34, 2.3, -2.38, BRASS)
			q:block(0.9, 3.5, -2.5, 1.4, 3.9, -2.3, rgb(255, 236, 190))
		end,
	},
	-- two mushroom vents and a duct with a louvred end
	{
		id = "vents",
		w = 5.2,
		d = 2.6,
		draw = function(q: R)
			q:block(-2.4, 0, -0.9, 0.2, 1.3, 0.9, METAL)
			q:block(-2.46, 0.2, -0.7, -2.4, 1.1, 0.7, DARK)
			q:block(-2.2, 1.3, -0.5, -1.2, 1.5, 0.5, DARK)
			for _, x in { 1, 2.1 } do
				q:cyl(x, 0.6, 0.2, 1.2, 0.5, "y", METAL)
				q:cyl(x, 1.3, 0.2, 0.3, 0.96, "y", shade(METAL, 0.8))
			end
		end,
	},
	-- a television aerial on a block
	{
		id = "aerial",
		w = 3.4,
		d = 3.6,
		draw = function(q: R)
			q:block(-0.4, 0, -0.4, 0.4, 0.4, 0.4, STONE)
			q:block(-0.09, 0.4, -0.09, 0.09, 6.4, 0.09, METAL)
			q:block(-0.06, 5.9, -1.7, 0.06, 6.02, 1.5, METAL)
			q:block(-1.5, 5.9, -1.4, 1.5, 6.02, -1.28, METAL)
			q:block(-1.2, 5.9, -0.3, 1.2, 6.02, -0.18, METAL)
			q:block(-0.9, 5.9, 0.8, 0.9, 6.02, 0.92, METAL)
		end,
	},
	-- washing on a line between two posts
	{
		id = "line",
		w = 5.8,
		d = 1.8,
		draw = function(q: R)
			for _, sx in { -1, 1 } do
				q:block(sx * 2.7 - 0.08, 0, -0.08, sx * 2.7 + 0.08, 3.4, 0.08, METAL)
				q:block(sx * 2.7 - 0.06, 3.3, -0.7, sx * 2.7 + 0.06, 3.42, 0.7, METAL)
			end
			for _, z in { -0.5, 0.5 } do
				q:block(-2.7, 3.34, z - 0.03, 2.7, 3.4, z + 0.03, DARK)
			end
			local wash: { { any } } = {
				{ -2, -0.5, 0.9, 1.2, rgb(250, 250, 248) },
				{ -0.8, -0.5, 0.7, 0.9, rgb(240, 120, 110) },
				{ 0.5, -0.5, 1.1, 1.4, rgb(120, 170, 220) },
				{ -1.2, 0.5, 1, 1, rgb(250, 214, 110) },
				{ 1.5, 0.5, 0.9, 1.3, rgb(250, 250, 248) },
			}
			for _, c in wash do
				q:block(c[1] - c[3] / 2, 3.34 - c[4], c[2] - 0.04, c[1] + c[3] / 2, 3.34, c[2] + 0.04, c[5])
			end
		end,
	},
	-- a length of railing
	{
		id = "rail",
		w = 6.2,
		d = 0.6,
		draw = function(q: R)
			q:block(-3, 1.9, -0.07, 3, 2.04, 0.07, METAL)
			q:block(-3, 1, -0.05, 3, 1.1, 0.05, METAL)
			for k = 0, 4 do
				local x = -2.93 + k * 1.465
				q:block(x - 0.07, 0, -0.07, x + 0.07, 1.9, 0.07, METAL)
			end
		end,
	},
	-- a steel frame that once held a sign
	{
		id = "frame",
		w = 6.4,
		d = 2.6,
		draw = function(q: R)
			for _, sx in { -1, 1 } do
				q:block(sx * 2.9 - 0.1, 0, -0.9, sx * 2.9 + 0.1, 4.6, -0.7, DARK)
				q:beam(Vector3.new(sx * 2.9, 3.6, -0.7), Vector3.new(sx * 2.9, 0.1, 1.1), 0.12, 0.12, DARK)
			end
			for _, y in { 1.4, 3, 4.5 } do
				q:block(-3, y, -0.88, 3, y + 0.14, -0.72, DARK)
			end
			q:beam(Vector3.new(-2.9, 1.5, -0.8), Vector3.new(2.9, 4.5, -0.8), 0.1, 0.1, DARK)
		end,
	},
	-- a skylight over the stairwell
	{
		id = "skylight",
		w = 3.4,
		d = 2.8,
		draw = function(q: R)
			q:block(-1.5, 0, -1.2, 1.5, 0.5, 1.2, STONE)
			q:wedge(CFrame.new(0, 0.85, 0), 2.8, 0.7, 2.2, PANE)
			q:block(-0.06, 0.5, -1.1, 0.06, 0.62, 1.1, DARK)
		end,
	},
}

-- A brick chimney for a tiled roof, drawn with y = 0 where it comes through the tiles.
local function chimney(q: R)
	local MAT = "Brick:Maple"
	q:block(-0.8, -1.4, -0.7, 0.8, 2, 0.7, rgb(178, 116, 96), MAT)
	q:block(-0.95, 2, -0.85, 0.95, 2.3, 0.85, shade(rgb(178, 116, 96), 0.8), MAT)
	q:block(-0.35, 2.3, -0.35, 0.35, 3, 0.35, rgb(196, 134, 110), MAT)
end

-- Laying a wall out -----------------------------------------------------------------------------------

-- The window bays across a wall `fw` wide: each a class ("W" wide, "N" narrow) and where its
-- middle is. `d` picks among the rhythms that fit.
local MIN_PITCH: { [string]: number } = { W = 6.6, N = 4.4 }
local RHYTHMS = { "W", "WW", "NN", "NNN", "WNW", "NWN", "WWW", "WNNW", "NWWN", "NNNN", "WWWW", "WNWNW", "NWNWN" }
local function columns(fw: number, d: Dice): { { class: string, x: number } }
	local room = fw - 1.6
	local fits: { string } = {}
	for _, rhythm in RHYTHMS do
		local need = 0
		for c in rhythm:gmatch(".") do
			need += MIN_PITCH[c]
		end
		-- (and not so few that the wall is mostly blank)
		if need <= room and need >= room * 0.66 then
			table.insert(fits, rhythm)
		end
	end
	local rhythm = if #fits > 0 then pick(d, fits) else "N"
	if #fits == 0 and room > 30 then
		-- a long wall: wide bays all along it, or wide and narrow turn about
		local mixed = d.chance(0.5)
		rhythm = ""
		local need = 0
		while need + MIN_PITCH.W <= room do
			local c = if mixed and #rhythm % 2 == 1 and need + MIN_PITCH.N + MIN_PITCH.W <= room then "N" else "W"
			rhythm ..= c
			need += MIN_PITCH[c]
		end
	end
	local need = 0
	for c in rhythm:gmatch(".") do
		need += MIN_PITCH[c]
	end
	local scale = room / need
	local out = {}
	local x = -room / 2
	for c in rhythm:gmatch(".") do
		local slot = MIN_PITCH[c] * scale
		table.insert(out, { class = c, x = x + slot / 2 })
		x += slot
	end
	return out
end

type Unit = { kind: string, w: number }

-- What one building is made with, settled once from its spec and seed.
type Plan = {
	spec: Spec,
	d: Dice,
	h: number,
	wall: { mat: string, color: Color3 },
	base: { mat: string, color: Color3 }?,
	trim: any,
	awning: any,
	door: Color3,
	riser: Color3,
	pier: number,
	doorIndex: number, -- which of the trim's two door colours
	shop: string,
	pitched: boolean,
	wide: string, -- the window kinds its bays use
	narrow: string,
	feature: string?, -- another kind for the middle bays
	crown: string?, -- another kind for the top storey
	cap: Color3,
}

-- One street face: the ground floor, the storeys, what hangs on them and the band along the top.
local function drawFace(face: Face, plan: Plan, main: boolean)
	local spec, d = plan.spec, plan.d
	local fw, half = face.w, face.w / 2
	local trim, canvas = plan.trim, plan.awning
	local storeys = spec.storeys
	local walkIn = spec.inside ~= nil

	-- the ground floor: a pier at each end and the shop's units between them
	local pierLook = PIERS[plan.pier]
	for _, sx in { -1, 1 } do
		stamp(face, "pier:" .. plan.pier, sx * (half - 0.6), 0, function(q: R)
			pier(q, pierLook)
		end)
	end
	local room = fw - 2.4
	local units: { Unit } = {}
	local groundWindows = 0
	if walkIn then
		-- (the room's own front is there already, on the main face; its side wall is plain)
		room = 0
	elseif not main then
		-- round the corner: the shop window carries on if there is room, else house windows
		if plan.shop == "glazed" and room >= 10 then
			table.insert(units, { kind = "glazed", w = if room >= 12 then 12 else 10 })
		elseif plan.shop == "shutter" and room >= 10 then
			table.insert(units, { kind = "shutter", w = 10 })
		else
			groundWindows = math.max(1, math.floor(room / 5.4))
		end
	elseif plan.shop == "glazed" then
		table.insert(units, { kind = "glazed", w = if room >= 12 then 12 else 10 })
		if room >= 24.4 and d.chance(0.6) then
			table.insert(units, { kind = "glazed", w = 12 })
		elseif room >= 22.4 and d.chance(0.5) then
			table.insert(units, { kind = "shutter", w = 10 })
		end
	elseif plan.shop == "shutter" then
		table.insert(units, { kind = "shutter", w = 10 })
		if room >= 20.4 and d.chance(0.6) then
			table.insert(units, { kind = if d.chance(0.5) then "shutter" else "shut", w = 10 })
		end
	elseif plan.shop == "counter" then
		table.insert(units, { kind = "counter", w = 12 })
		if room >= 22.4 and d.chance(0.5) then
			table.insert(units, { kind = "glazed", w = 10 })
		end
	elseif plan.shop == "garage" then
		table.insert(units, { kind = "garage", w = 10 })
		if room >= 20.4 and d.chance(0.4) then
			table.insert(units, { kind = "shut", w = 10 })
		end
	end
	local used = 0
	for _, u in units do
		used += u.w
	end
	if main and not walkIn then
		-- the door to the rooms upstairs, at one end; a house is that door and its windows
		if plan.shop == "door" then
			table.insert(units, if d.chance(0.5) then 1 else #units + 1, { kind = "door", w = 6 })
			used += 6
			groundWindows = math.max(1, math.floor((room - used) / 6.4))
		elseif room - used >= 6.3 and d.chance(0.85) then
			table.insert(units, if d.chance(0.5) then 1 else #units + 1, { kind = "door", w = 6 })
			used += 6
		end
	end
	for _ = 1, groundWindows do
		table.insert(units, { kind = "window", w = 5.6 })
		used += 5.6
	end
	local gap = (room - used) / (#units + 1)
	local x = -half + 1.2 + gap
	local named = false
	local boardFrom, boardTo = math.huge, -math.huge
	for i, u in units do
		local cx = x + u.w / 2
		if u.kind == "glazed" then
			stamp(face, string.format("glazed:%d:%s:%d", u.w, trim.id, plan.doorIndex), cx, 0, function(q: R)
				glazed(q, u.w, trim.color, plan.riser, plan.door)
			end)
			if d.chance(0.7) then
				lit(face, cx - u.w / 2 + 0.3, 1.1, cx + u.w / 2 - 0.3, 6.4)
			end
			stamp(face, string.format("awning:%d:%s", u.w, canvas.id), cx, 0, function(q: R)
				awning(q, u.w + 0.4, canvas.color)
			end)
			boardFrom, boardTo = math.min(boardFrom, cx - u.w / 2), math.max(boardTo, cx + u.w / 2)
			if main and i == 1 and d.chance(0.55) then
				local apron =
					block(face, cx - u.w / 2, 0, -3, cx + u.w / 2, 0.05, 0, pick(d, APRONS), "CeramicTiles:Checker")
				apron.collide = false
			end
		elseif u.kind == "shutter" or u.kind == "shut" then
			local down = u.kind == "shut"
			local slats = if plan.spec.seed % 2 == 0 then rgb(168, 176, 172) else rgb(150, 170, 186)
			stamp(face, string.format("roller:%s:%d", u.kind, plan.spec.seed % 2), cx, 0, function(q: R)
				roller(q, slats, down)
			end)
			if not down then
				-- the shop behind the shutter: dim by day, lit after dark
				lit(face, cx - 4.7, 0.05, cx + 4.7, 2.72, DIM)
			end
			if d.chance(0.35) then
				stamp(face, string.format("awning:%d:%s", u.w, canvas.id), cx, 0, function(q: R)
					awning(q, u.w + 0.4, canvas.color)
				end)
			end
			boardFrom, boardTo = math.min(boardFrom, cx - u.w / 2), math.max(boardTo, cx + u.w / 2)
		elseif u.kind == "counter" then
			local cloth = if plan.spec.seed % 2 == 0 then rgb(70, 96, 142) else rgb(194, 98, 90)
			stamp(face, "counter:" .. plan.spec.seed % 2, cx, 0, function(q: R)
				counter(q, cloth)
			end)
			local tiles = ROOFS[plan.spec.seed % #ROOFS + 1]
			stamp(face, "leanTo:" .. plan.spec.seed % #ROOFS, cx, 0, function(q: R)
				leanTo(q, tiles)
			end)
			lit(face, cx - 5.6, 3.3, cx + 5.6, 6.15, rgb(104, 76, 60))
			if d.chance(0.5) then
				local apron = block(face, cx - 6, 0, -3.2, cx + 6, 0.05, 0, pick(d, APRONS), "CeramicTiles:Checker")
				apron.collide = false
			end
		elseif u.kind == "door" then
			stamp(face, string.format("door:%s:%d", trim.id, plan.doorIndex), cx - 0.15, 0, function(q: R)
				houseDoor(q, trim.color, plan.door)
			end)
			if main and spec.sign and (plan.shop == "door" or #units == 1) and not named then
				-- a house or an office: its name on a plate over the door
				local plate = block(face, cx - 1.4, 7.1, -0.3, cx + 3.1, 8.2, 0, canvas.color)
				CityModels.sign(pen:glow(plate, 0), spec.sign, "fascia", "Front")
				named = true
			end
		elseif u.kind == "garage" then
			local sheet = if plan.spec.seed % 2 == 0 then rgb(196, 204, 200) else rgb(170, 190, 204)
			stamp(face, "garage:" .. plan.spec.seed % 2, cx, 0, function(q: R)
				garage(q, sheet)
			end)
			boardFrom, boardTo = math.min(boardFrom, cx - u.w / 2), math.max(boardTo, cx + u.w / 2)
		else
			-- a house window on the ground floor, set higher than those upstairs
			local kind = if plan.wide == "balcony" or plan.wide == "awned" then "pair" else plan.wide
			local win = WINDOWS[kind]
			stamp(face, string.format("win:%s:%s", kind, trim.id), cx, 1.7, function(q: R)
				win.draw(q, trim, canvas)
			end)
			if d.chance(0.35) then
				lit(face, cx - win.hw, 1.7 + win.y1, cx + win.hw, 1.7 + win.y2)
			end
		end
		-- between two units, where there is bare wall: the meter
		if i < #units and gap >= 2 and d.chance(0.5) then
			stamp(face, "meter", x + u.w + gap / 2 - 0.4, 0, meter)
		end
		x += u.w + gap
	end
	if walkIn and main then
		-- awnings over the room's own windows, either side of its door
		local aw = if fw >= 28 then 12 else 10
		local avail = half - 1.4
		local n = math.max(1, math.floor(avail / (aw + 0.4)))
		for _, sx in { -1, 1 } do
			for k = 0, n - 1 do
				local cx = sx * (0.1 + (k + 0.5) * avail / n)
				stamp(face, string.format("awning:%d:%s", aw, canvas.id), cx, 0.3, function(q: R)
					awning(q, aw + 0.4, canvas.color)
				end)
			end
		end
		boardFrom, boardTo = -half + 1.3, half - 1.3
	end
	-- the board over the shop: its name if it has one, else left bare
	if boardTo > boardFrom then
		local y1 = if walkIn then 7.42 else 7.12
		local board = block(face, boardFrom + 0.2, y1, -0.42, boardTo - 0.2, 8.3, 0, canvas.color)
		if spec.sign and not named and (main or walkIn) then
			CityModels.sign(pen:glow(board, 0), spec.sign, "fascia", "Front")
			named = true
		elseif spec.sign and not main then
			CityModels.sign(pen:glow(board, 0), spec.sign, "fascia", "Front")
		else
			board.color = shade(canvas.color, 0.9)
		end
	end

	-- the storeys: a window in every bay, some of them lit after dark
	local cols = columns(fw, d)
	local middle = (#cols + 1) / 2
	local kinds: { { string } } = {}
	for s = 1, storeys - 1 do
		local y0 = G + (s - 1) * FH
		kinds[s] = {}
		for c, col in cols do
			local kind = if col.class == "N" then plan.narrow else plan.wide
			if col.class == "W" then
				if plan.crown and s == storeys - 1 and storeys > 2 then
					kind = plan.crown
				elseif plan.feature and math.abs(c - middle) < 0.6 then
					kind = plan.feature
				end
			end
			kinds[s][c] = kind
			local win = WINDOWS[kind]
			stamp(face, string.format("win:%s:%s", kind, trim.id), col.x, y0, function(q: R)
				win.draw(q, trim, canvas)
			end)
			if d.chance(0.38) then
				lit(face, col.x - win.hw, y0 + win.y1, col.x + win.hw, y0 + win.y2)
			end
		end
	end
	-- air conditioners under a window here and there, over the head of the one below
	local hung = 0
	for s = 2, storeys - 1 do
		for c, col in cols do
			local below, here = kinds[s - 1][c], kinds[s][c]
			local clear = here ~= "balcony" and below ~= "balcony" and below ~= "awned"
			if clear and hung < 2 and d.chance(0.16) then
				local off = if col.class == "W" then (if d.chance(0.5) then 1 else -1) else 0
				stamp(face, "aircon", col.x + off, G + (s - 1) * FH - 0.62, airCon)
				hung += 1
			end
		end
	end

	-- a string course over the shop, the band along the top, a downpipe at one end and
	-- sometimes a blade sign at the other
	-- (on a corner the front's bands run on past the wall's end to meet the side's)
	local left = -half - (if main and spec.corner == "left" then 0.4 else 0)
	local right = half + (if main and spec.corner == "right" then 0.4 else 0)
	if d.chance(0.6) then
		block(face, left, G - 0.2, -0.2, right, G + 0.16, 0, plan.cap)
	end
	if not plan.pitched then
		block(face, left, plan.h - 0.5, -0.4, right, plan.h + 1, 0.5, plan.cap)
	end
	local pipeSide = if d.chance(0.5) then 1 else -1
	if main and d.chance(0.6) then
		stamp(face, "pipe:" .. storeys, pipeSide * (half - 0.42), 0, function(q: R)
			downpipe(q, plan.h)
		end)
	end
	local wantsBlade = main and spec.sign ~= nil and (plan.shop == "counter" or d.chance(0.4))
	if main and not (wantsBlade and plan.shop ~= "door") and plan.shop ~= "door" and d.chance(0.3) then
		-- no name to hang out: a cloth banner on an arm instead
		stamp(face, "banner:" .. canvas.id, -pipeSide * (half - 0.5), G + 0.9, function(q: R)
			banner(q, canvas.color)
		end)
	end
	if wantsBlade and plan.shop ~= "door" and spec.sign then
		local tall = storeys >= 3
		local y1, y2 = G + (if tall then 1.2 else 0.5), G + (if tall then 7.8 else 5.2)
		local bx = -pipeSide * (half - 0.5)
		local board = block(face, bx - 0.2, y1, -2.9, bx + 0.2, y2, -0.7, canvas.color)
		CityModels.sign(pen:glow(board, 0), spec.sign, "blade")
		board.collide = false
		local rise = y2 - y1 - 1.2
		stamp(face, if tall then "arms:tall" else "arms:low", bx, y1 + 0.5, function(q: R)
			bladeArms(q, rise)
		end)
	end
end

-- Whole buildings -------------------------------------------------------------------------------------

local W_KINDS = { "pair", "pair", "pair", "wide", "wide", "shutter", "shutter", "balcony", "awned" }
local N_KINDS = { "single", "single", "flower" }

local function build(spec: Spec): { Prim }
	local d = dice(spec.seed)
	local w, depth, storeys = spec.w, spec.d, spec.storeys
	local h = Facades.height(storeys)
	local out: { Prim } = {}
	local r = Recipe.new(WHITE, WHITE)
	r.prims = out

	-- (painted render is the commonest wall: twice as likely as any of the others)
	local wallIndex = d.int(1, #Facades.Walls + 5)
	if wallIndex > #Facades.Walls then
		wallIndex -= #Facades.Walls
	end
	local wall = Facades.Walls[spec.wall or wallIndex]
	local look = Facades.Looks[spec.look or d.int(1, #Facades.Looks)]
	local doorIndex = d.int(1, 2)
	local shop = spec.shop or pick(d, { "glazed", "glazed", "glazed", "shutter", "counter", "door", "door", "garage" })
	if w < 12.4 then
		shop = "door"
	elseif w < 15 and shop == "counter" then
		shop = "glazed"
	end
	local pitched = false
	if spec.top == "pitched" then
		pitched = true
	elseif spec.top ~= "flat" then
		pitched = not spec.corner and storeys <= 4 and depth <= 18 and d.chance(0.3)
	end
	local base = if d.chance(0.42) then pick(d, BASES) else nil
	local attic: Color3? = if storeys >= 3 and not pitched and d.chance(0.14) then pick(d, ATTICS) else nil
	local wide = pick(d, W_KINDS)
	local plan: Plan = {
		spec = spec,
		d = d,
		h = h,
		wall = wall,
		base = base,
		trim = TRIMS[look.trim],
		awning = AWNINGS[look.awning],
		door = TRIMS[look.trim].doors[doorIndex],
		riser = TRIMS[look.trim].riser,
		pier = d.int(1, #PIERS),
		doorIndex = doorIndex,
		shop = shop,
		pitched = pitched,
		wide = wide,
		narrow = pick(d, N_KINDS),
		feature = if wide ~= "balcony" and d.chance(0.3) then "balcony" else nil,
		crown = if d.chance(0.22) then pick(d, { "wide", "shutter", "pair" }) else nil,
		cap = if look.trim == 1 then CREAM else shade(wall.color, 0.82),
	}

	-- the body: a room to walk into under the storeys, or one solid box (two when the ground
	-- floor is its own material, three with a storey of sheet metal on top)
	local upperFrom = 0
	if spec.inside then
		local ground = base or wall
		local box = Interiors.shell(r, {
			w = w,
			d = depth,
			h = G,
			wall = ground.color,
			mat = ground.mat,
			trim = plan.trim.color,
			door = plan.door,
		})
		Interiors.fill(r, spec.inside, box, wall.color)
		upperFrom = G
	elseif base then
		r:block(-w / 2, 0, -depth / 2, w / 2, G, depth / 2, base.color, base.mat)
		upperFrom = G
	end
	local upperTo = if attic then h - TOP - FH else h
	r:block(-w / 2, upperFrom, -depth / 2, w / 2, upperTo, depth / 2, wall.color, wall.mat)
	if attic then
		r:block(-w / 2, upperTo, -depth / 2, w / 2, h, depth / 2, attic, "Metal:Corrugated")
	end

	-- the street faces
	local front: Face = { f = CFrame.new(0, 0, -depth / 2), w = w, out = out }
	drawFace(front, plan, true)
	if spec.corner then
		local sx = if spec.corner == "right" then 1 else -1
		local side: Face = {
			f = CFrame.new(sx * w / 2, 0, 0) * CFrame.Angles(0, -sx * math.pi / 2, 0),
			w = depth,
			out = out,
		}
		drawFace(side, plan, false)
	end

	-- the back, where it shows: a door, a few small windows, a pipe
	if spec.back ~= false and not spec.inside and w >= 14 then
		local rows = math.min(storeys - 1, 2)
		local behind: Face = { f = CFrame.new(0, 0, depth / 2) * CFrame.Angles(0, math.pi, 0), w = w, out = out }
		local sx = if d.chance(0.5) then 1 else -1
		stamp(behind, "back:" .. rows, sx * (w / 2 - 6.2) * d.float(), 0, function(q: R)
			backWall(q, rows)
		end)
	end

	-- the top
	if pitched then
		-- two slopes of barrel tiles over a gable of the wall's own stuff, the eaves over the street
		local rise = depth * 0.26
		r:wedge(CFrame.new(0, h + rise / 2, -depth / 4), w, rise, depth / 2, wall.color, wall.mat)
		r:wedge(
			CFrame.new(0, h + rise / 2, depth / 4) * CFrame.Angles(0, math.pi, 0),
			w,
			rise,
			depth / 2,
			wall.color,
			wall.mat
		)
		local tiles = pick(d, ROOFS)
		local run = depth / 2
		local len = math.sqrt(run * run + rise * rise)
		local a = math.atan2(rise, run)
		local RIDGE, THICK = 0.1, 0.3
		for _, sz in { -1, 1 } do
			-- (the eaves hang over the street; behind, the tiles stop at the wall)
			local EAVE = if sz < 0 then 0.9 else -THICK * rise / run - 0.01
			-- (the slab's middle: half way up the slope, slid down toward the eaves, lifted by half
			-- its thickness)
			local alongY, alongZ = math.sin(a), -sz * math.cos(a)
			local normalY, normalZ = math.cos(a), sz * math.sin(a)
			local slide = (RIDGE - EAVE) / 2
			local cy = h + rise / 2 + alongY * slide + normalY * THICK / 2
			local cz = sz * run / 2 + alongZ * slide + normalZ * THICK / 2
			r:boxAt(
				CFrame.new(0, cy, cz) * CFrame.Angles(sz * a, 0, 0),
				w,
				THICK,
				len + EAVE + RIDGE,
				tiles,
				"ClayRoofTiles:Barrel"
			)
		end
		r:block(-w / 2, h - 0.5, -depth / 2 - 0.3, w / 2, h - 0.1, -depth / 2, plan.cap, PLAIN)
		if d.chance(0.7) then
			local cx = (if d.chance(0.5) then 1 else -1) * (w / 2 - 2.4)
			local made = piece("chimney", chimney)
			local p = table.clone(made)
			p.cf = CFrame.new(cx, h + rise * 0.55, depth * 0.22) * made.cf
			table.insert(out, p)
		end
	else
		-- a flat roof: a deck inside the parapet, and what people keep up there
		local inL = if spec.corner == "left" then 0.5 else 0.25
		local inR = if spec.corner == "right" then 0.5 else 0.25
		r:block(-w / 2 + inL, h, -depth / 2 + 0.5, w / 2 - inR, h + 0.14, depth / 2 - 0.25, pick(d, DECKS), "Concrete")
		local x1, x2 = -w / 2 + 1, w / 2 - 1
		local z1, z2 = -depth / 2 + 1.4, depth / 2 - 0.8
		local across = math.max(1, math.floor((x2 - x1) / 6.4))
		local rows = if z2 - z1 >= 10.4 then 2 else 1
		local slots: { { number } } = {}
		for i = 0, across - 1 do
			for j = 0, rows - 1 do
				table.insert(slots, { i, j })
			end
		end
		-- (a big roof has more on it)
		local want = math.max(1 + math.floor(w / 13) + (if d.chance(0.5) then 1 else 0), math.floor(w * depth / 200))
		want = math.min(#slots, want)
		local sw, sd = (x2 - x1) / across, (z2 - z1) / rows
		for _ = 1, want do
			local slot = table.remove(slots, d.int(1, #slots)) :: { number }
			local item = pick(d, CLUTTER)
			if item.w <= sw and item.d <= sd then
				local cx = x1 + (slot[1] + 0.5) * sw + (d.float() - 0.5) * (sw - item.w)
				local cz = z1 + (slot[2] + 0.5) * sd + (d.float() - 0.5) * (sd - item.d)
				local made = piece("roof:" .. item.id, item.draw)
				local p = table.clone(made)
				p.cf = CFrame.new(cx, h + 0.14, cz) * made.cf
				table.insert(out, p)
			end
		end
	end
	return out
end

-- Names and presets ------------------------------------------------------------------------------------

-- Ready-made buildings with plain names, one of each kind of thing the kit draws (the preview
-- and the spec go through them; the map mostly asks by spec).
Facades.Presets = {
	rowBakery = { w = 24, d = 14, storeys = 3, seed = 11, shop = "glazed", sign = "bakery", top = "flat" },
	rowNoodles = { w = 20, d = 14, storeys = 2, seed = 12, shop = "counter", sign = "cafe", top = "pitched" },
	rowShutter = { w = 26, d = 14, storeys = 4, seed = 13, shop = "shutter", top = "flat" },
	rowHouse = { w = 18, d = 14, storeys = 3, seed = 14, shop = "door", sign = "flats", top = "pitched" },
	rowGarage = { w = 22, d = 14, storeys = 2, seed = 15, shop = "garage", top = "flat" },
	rowTall = { w = 30, d = 16, storeys = 5, seed = 16, shop = "glazed", sign = "books", top = "flat" },
	rowCorner = { w = 26, d = 16, storeys = 4, seed = 17, shop = "glazed", sign = "grocer", corner = "right" },
	rowCornerLeft = { w = 22, d = 14, storeys = 3, seed = 18, shop = "door", corner = "left" },
	rowWide = { w = 34, d = 14, storeys = 3, seed = 19, shop = "glazed", sign = "clothes", top = "flat" },
	rowNarrow = { w = 16, d = 14, storeys = 4, seed = 20, shop = "glazed", sign = "flowers" },
	rowOffice = { w = 28, d = 16, storeys = 6, seed = 21, shop = "door", sign = "office", top = "flat" },
	rowTeaHouse = { w = 28, d = 14, storeys = 3, seed = 22, shop = "counter", sign = "cafe", top = "flat" },
	rowShop = { w = 26, d = 22, storeys = 3, seed = 23, inside = "bakery", sign = "bakery", top = "flat" },
	rowShopCorner = { w = 30, d = 22, storeys = 2, seed = 24, inside = "toys", sign = "toys", corner = "left" },
} :: { [string]: Spec }

-- The name the map places a spec by.
function Facades.name(spec: Spec): string
	local name = string.format("facade:%dx%d:%d:%d", spec.w, spec.d, spec.storeys, spec.seed)
	if spec.corner == "left" then
		name ..= ":cl"
	elseif spec.corner == "right" then
		name ..= ":cr"
	end
	for _, key in { "sign", "shop", "top" } do
		local value = (spec :: any)[key]
		if value then
			name ..= string.format(":%s=%s", key, value)
		end
	end
	if spec.inside then
		name ..= ":in=" .. spec.inside
	end
	if spec.back == false then
		name ..= ":nb"
	end
	for _, key in { "wall", "look" } do
		local value = (spec :: any)[key]
		if value then
			name ..= string.format(":%s=%d", key, value)
		end
	end
	return name
end

-- The spec a name stands for, or nil if it isn't one of these buildings.
function Facades.spec(name: string): Spec?
	local preset = Facades.Presets[name]
	if preset then
		return preset
	end
	local w, depth, storeys, seed, rest = name:match("^facade:(%d+)x(%d+):(%d+):(%d+)(.*)$")
	if not w then
		return nil
	end
	local spec: Spec = {
		w = tonumber(w) :: number,
		d = tonumber(depth) :: number,
		storeys = tonumber(storeys) :: number,
		seed = tonumber(seed) :: number,
	}
	for opt in (rest :: string):gmatch(":([^:]+)") do
		local key, value = opt:match("^(%a+)=(.+)$")
		if opt == "cl" then
			spec.corner = "left"
		elseif opt == "cr" then
			spec.corner = "right"
		elseif opt == "nb" then
			spec.back = false
		elseif key == "sign" then
			spec.sign = value
		elseif key == "shop" then
			spec.shop = value
		elseif key == "top" then
			spec.top = value
		elseif key == "in" then
			spec.inside = value
		elseif key == "wall" then
			spec.wall = tonumber(value)
		elseif key == "look" then
			spec.look = tonumber(value)
		else
			return nil
		end
	end
	if spec.w < 12 or spec.w > 80 or spec.d < 10 or spec.storeys < 2 or spec.storeys > 8 then
		return nil
	end
	return spec
end

-- The box a building keeps inside, in its own space: its walls, on a street face as far again
-- as an awning reaches, and behind as far as the back door's step. { x1, z1, x2, z2 }.
function Facades.footprint(spec: Spec): { number }
	local left = if spec.corner == "left" then Facades.Reach else 0
	local right = if spec.corner == "right" then Facades.Reach else 0
	local behind = if spec.back == false or spec.inside then 0 else Facades.BackReach
	return { -spec.w / 2 - left, -spec.d / 2 - Facades.Reach, spec.w / 2 + right, spec.d / 2 + behind }
end

-- A string of paper lanterns across a lane `span` studs wide, wall to wall: placed in the middle
-- of the lane, the string running along local x.
local function lanterns(q: R, span: number)
	local h = span / 2
	q:block(-h, 10.9, -0.04, h, 10.98, 0.04, DARK)
	local n = math.floor(span / 2.4)
	for k = 1, n do
		local x = -h + k * span / (n + 1)
		-- (they hang lower toward the middle, as if the string sagged)
		local y = 10.7 - 0.9 * (1 - (2 * x / span) ^ 2)
		q:block(x - 0.03, y, -0.03, x + 0.03, 10.9, 0.03, DARK)
		local col = ({ rgb(216, 108, 88), rgb(238, 200, 118), rgb(244, 236, 220) })[k % 3 + 1]
		q:block(x - 0.32, y - 0.85, -0.32, x + 0.32, y, 0.32, col)
		q:block(x - 0.2, y - 0.95, -0.2, x + 0.2, y - 0.85, 0.2, DARK)
	end
end

local built: { [string]: { Prim } } = {}

-- The primitives of the model called `name`, or nil if it isn't one of these. (A fresh list
-- each time: callers move what they are given.)
function Facades.prims(name: string): { Prim }?
	local made = built[name]
	if not made then
		local span = name:match("^laneLights:(%d+)$")
		local spec = Facades.spec(name)
		if span then
			-- "laneLights:<span>": lanterns strung across a lane that wide
			local wide = tonumber(span) :: number
			made = {
				table.clone(piece(name, function(q: R)
					lanterns(q, wide)
				end)),
			}
		elseif spec then
			made = build(spec)
		else
			return nil
		end
		built[name] = made
	end
	local out = table.create(#made)
	for i, p in made do
		local c = table.clone(p)
		if c.attrs then
			c.attrs = table.clone(c.attrs)
		end
		out[i] = c
	end
	return out
end

-- How many different pieces the kit has drawn so far.
function Facades.pieces(): number
	local n = 0
	for _ in kit do
		n += 1
	end
	return n
end

return Facades
