--!strict
-- The town's other buildings and landmarks, the ones nobody builds: downtown's towers and shops,
-- the civic quarter's school, clinic, library, museum and fire station, the farm and the lookout
-- in the hills, the fairground pier, the lighthouse and the beach huts. Each is a recipe drawn
-- round its own footprint's middle, front facing local -Z (the placement turns it to its street).
-- Most are made from a few kinds (towers, shop rows, houses) with their own colours and sizes.
--
-- Spinning parts: a model's "Hub" part gives the axle (its X axis); parts named "Spin" turn with
-- it and parts named "Cabin" go round with it but stay upright (World/Ambience moves them).

local Recipe = require(script.Parent.Parent.Build.Recipe)
local Geometry = require(script.Parent.Parent.Build.Geometry)
local Interiors = require(script.Parent.Interiors)

type R = Recipe.Recipe
type Prim = Recipe.Prim

local CityModels = {}
CityModels.Models = {} :: { [string]: (R) -> () }
local M = CityModels.Models

local function rgb(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end

local WHITE = rgb(250, 246, 236)
local GLASS = rgb(150, 206, 240)
local DOOR = rgb(70, 86, 110)
local WOOD = rgb(196, 154, 108)
local WOOD_DARK = rgb(154, 107, 72)
local STONE = rgb(218, 212, 200)
local ROCK = rgb(150, 152, 160)
local LEAF = rgb(78, 160, 70)
local LEAF_DARK = rgb(52, 128, 66)
local BARK = rgb(140, 98, 62)
local METAL = rgb(186, 192, 202)
local DARK = rgb(64, 70, 86)
local WATER = rgb(84, 168, 236)

local function shade(c: Color3, k: number): Color3
	return Color3.new(math.min(1, c.R * k), math.min(1, c.G * k), math.min(1, c.B * k))
end

local function yaw(deg: number): CFrame
	return CFrame.Angles(0, math.rad(deg), 0)
end

-- Colours for the small things: soft and a little dusty, strong colour only on accents.
local TRIM_DARK = rgb(90, 85, 96)
local TYRE = rgb(54, 54, 62)
local PANE = rgb(132, 170, 196) -- glass drawn as paint, where a piece holds it
local SOIL = rgb(106, 80, 60)
local POT = rgb(200, 132, 104)
local BLOOMS = { rgb(226, 138, 156), rgb(234, 196, 112), rgb(246, 240, 226), rgb(170, 150, 206), rgb(224, 128, 102) }
local LEAVES = { rgb(96, 150, 92), rgb(120, 170, 104), rgb(78, 128, 84) }

-- Pieces ---------------------------------------------------------------------------------------------
-- A detail used over and over (a car's wheels and glass, a bench, a window's frame) is a piece
-- (Geometry.piece): a handful of shapes that go round as one part. It is drawn once round the
-- origin and stamped wherever it is wanted, so the same shapes always make the same key and the
-- server merges each only once. (Drawing it where it stands gives keys that differ in their last
-- decimal.) `id` names everything that changes its shapes or its colours.
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

-- The same drawing as a stamp, made as plain parts where it stands: for details used once or
-- twice, which would cost a merge each and save next to nothing. `collide` false keeps people
-- from tripping on them (lines, nets).
local function drawAt(r: R, at: CFrame, draw: (R) -> (), collide: boolean?)
	local q = Recipe.new(WHITE, WHITE)
	draw(q)
	for _, p in q.prims do
		p.cf = at * p.cf
		if collide == false then
			p.collide = false
		end
		r:add(p)
	end
end

-- A little plant on a stem: leaves round the foot and a flower on top. For the planting pieces.
local function sprig(q: R, x: number, y: number, z: number, tall: number, bloom: Color3, leaf: Color3)
	q:box(x, y + tall / 2, z, 0.08, tall, 0.08, leaf)
	q:lump(CFrame.new(x, y + 0.18, z) * CFrame.Angles(0.3, x * 2, 0.2), 0.62, 0.34, 0.5, leaf)
	q:lump(CFrame.new(x, y + tall, z) * CFrame.Angles(0.2, z * 3, 0.4), 0.48, 0.4, 0.48, bloom)
end

-- A window that's lit after dark: glass by day, warm lamplight at night (the World service swaps
-- its colour and material when the lamps come on).
local LAMPLIGHT = rgb(255, 224, 156)
local function lit(r: R, pane: Recipe.Prim): Recipe.Prim
	r:glow(pane, 0)
	pane.attrs = { NightColor = LAMPLIGHT }
	return pane
end
CityModels.lit = lit

-- A park bench facing local -Z: three seat slats and two back slats on dark cast ends, each end
-- a front leg, a back leg running up to hold the back, a rail under the seat and an arm.
local function bench(r: R, x: number, z: number, yawDeg: number)
	stamp(r, "bench", CFrame.new(x, 0, z) * yaw(yawDeg), function(q)
		for i = 0, 2 do
			q:box(0, 1.19, -0.47 + i * 0.44, 4, 0.14, 0.38, WOOD, "Wood")
		end
		for i = 0, 1 do
			q:box(0, 1.8 + i * 0.5, 0.62, 4, 0.3, 0.12, WOOD, "Wood")
		end
		for _, sx in { -1, 1 } do
			local ex = sx * 1.7
			q:box(ex, 0.56, -0.5, 0.16, 1.12, 0.16, DARK, "Wood")
			q:box(ex, 1.28, 0.55, 0.16, 2.56, 0.16, DARK, "Wood")
			q:box(ex, 1.05, 0, 0.16, 0.14, 1.16, DARK, "Wood")
			q:box(ex, 1.72, -0.12, 0.16, 0.12, 1.0, DARK, "Wood")
			q:box(ex, 1.45, -0.55, 0.16, 0.55, 0.12, DARK, "Wood")
		end
		q:box(0, 0.35, 0, 3.24, 0.1, 0.1, DARK, "Wood")
	end, true)
end

-- A stone tub of flowers, its planting and the clipped shrub in the middle (the shrub is a part of
-- its own named Leaf, so it sways): the tub on a foot with a rim round its top, soil just under
-- the rim, flowers on stems at different heights and trailing leaves spilling over the edge.
local function tub(r: R, x: number, z: number, turn: number)
	local at = CFrame.new(x, 0, z) * yaw(turn)
	stamp(r, "tubPot", at, function(q)
		q:box(0, 0.1, 0, 4.4, 0.2, 4.4, rgb(214, 208, 198), "Concrete")
		q:box(0, 0.6, 0, 4.1, 0.8, 4.1, rgb(226, 222, 214), "Concrete")
		for _, s in { -1, 1 } do
			q:box(0, 1.09, s * 2.05, 4.4, 0.18, 0.3, rgb(214, 208, 198), "Concrete")
			q:box(s * 2.05, 1.09, 0, 0.3, 0.18, 3.8, rgb(214, 208, 198), "Concrete")
		end
	end, true)
	stamp(r, "tubPlants", at, function(q)
		q:box(0, 1.06, 0, 3.8, 0.12, 3.8, SOIL)
		local spots = {
			{ -1.35, -1.3, 0.9 },
			{ 0.2, -1.45, 1.25 },
			{ 1.4, -1.1, 0.75 },
			{ 1.4, 0.6, 1.1 },
			{ -0.4, 1.4, 0.8 },
			{ -1.45, 0.4, 1.3 },
		}
		for i, s in spots do
			sprig(q, s[1], 1.12, s[2], s[3], BLOOMS[(i - 1) % 4 + 1], LEAVES[(i - 1) % 3 + 1])
		end
		for i, s in { { -1.6, 0.9 }, { 0.8, -1.6 }, { 1.6, -0.4 }, { -0.9, 1.6 } } do
			q:lump(CFrame.new(s[1], 1.0, s[2]) * CFrame.Angles(0.4, i, 0.3), 0.8, 0.6, 0.7, LEAVES[i % 3 + 1])
		end
	end)
	r:lump(at * CFrame.new(0.1, 2.0, 0.1) * CFrame.Angles(0.2, 0.6, 0.1), 2.5, 2.1, 2.4, LEAF, "SmoothPlastic").name =
		"Leaf"
end

-- A flower bed in a stone edging, 5.2 by 2: soil, plants of three heights and two low mounds.
local function flowerBed(r: R, at: CFrame)
	stamp(r, "flowerBed", at, function(q)
		for _, s in { -1, 1 } do
			q:box(0, 0.15, s * 0.9, 5.2, 0.3, 0.2, rgb(206, 200, 188))
			q:box(s * 2.5, 0.15, 0, 0.2, 0.3, 1.6, rgb(206, 200, 188))
		end
		q:box(0, 0.11, 0, 4.8, 0.22, 1.6, SOIL)
		local spots = {
			{ -1.9, -0.3, 0.75 },
			{ -1.1, 0.35, 1.05 },
			{ -0.3, -0.35, 0.6 },
			{ 0.5, 0.3, 0.95 },
			{ 1.25, -0.3, 0.7 },
			{ 1.95, 0.3, 1.0 },
		}
		for i, s in spots do
			sprig(q, s[1], 0.22, s[2], s[3], BLOOMS[(i + 1) % 5 + 1], LEAVES[i % 3 + 1])
		end
		q:lump(CFrame.new(-0.7, 0.32, 0.05) * CFrame.Angles(0.2, 0.8, 0), 1.2, 0.5, 0.9, LEAVES[2])
		q:lump(CFrame.new(1.6, 0.3, -0.05) * CFrame.Angles(0.1, 2.1, 0), 1.0, 0.45, 0.8, LEAVES[1])
	end)
end
CityModels.flowerBed = flowerBed

-- A gate post: a plinth, a shaft, a cap and a seat for its lamp (the lamp is a part of its own).
local function gatePost(r: R, x: number, z: number)
	stamp(r, "gatePost", CFrame.new(x, 0, z), function(q)
		q:box(0, 0.2, 0, 1, 0.4, 1, rgb(214, 208, 198), "Concrete")
		q:box(0, 1.6, 0, 0.76, 2.4, 0.76, rgb(232, 228, 220), "Concrete")
		q:box(0, 2.9, 0, 1, 0.2, 1, rgb(214, 208, 198), "Concrete")
		q:box(0, 3.06, 0, 0.6, 0.12, 0.6, rgb(214, 208, 198), "Concrete")
		q:box(0, 1.2, 0, 0.84, 0.1, 0.84, rgb(214, 208, 198), "Concrete")
	end, true)
	r:glow(r:ball(x, 3.52, z, 0.8, rgb(255, 236, 190), "SmoothPlastic"), 10, 0.8)
end

-- A run of post and rail fence `len` long along x, centred on the origin: posts at each end and
-- in the middle, a rail at the knee and one at the top.
local function fenceRun(q: R, len: number)
	for _, x in { -len / 2, 0, len / 2 } do
		q:box(x, 1.1, 0, 0.3, 2.2, 0.3, WOOD_DARK, "Wood")
	end
	q:box(0, 0.95, 0, len, 0.22, 0.14, WOOD, "Wood")
	q:box(0, 1.8, 0, len, 0.22, 0.14, WOOD, "Wood")
end

-- A post and rail railing from a to b standing on their height: posts about every 2.4 studs, a
-- top rail and a rail at the knee. Plain parts, for one-off places like the lookout.
local function railing(r: R, a: Vector3, b: Vector3, tall: number, color: Color3)
	local len = (b - a).Magnitude
	local n = math.max(1, math.floor(len / 2.4 + 0.5))
	for i = 0, n do
		local p = a + (b - a) * (i / n)
		r:box(p.X, p.Y + tall / 2, p.Z, 0.22, tall, 0.22, color, "Wood")
	end
	r:beam(a + Vector3.new(0, tall - 0.1, 0), b + Vector3.new(0, tall - 0.1, 0), 0.24, 0.2, color, "Wood")
	r:beam(a + Vector3.new(0, tall * 0.45, 0), b + Vector3.new(0, tall * 0.45, 0), 0.16, 0.16, color, "Wood")
end

-- See-through water you can walk into.
local function water(p: Prim?)
	if p then
		p.transp = 0.25
		p.collide = false
	end
end

-- Signs ---------------------------------------------------------------------------------------------
-- The boards the Signs service writes on once the town is built (Services/Signs, with the words
-- from Data/Signs). A building's own board is a part named Sign (a hanging SwingSign keeps its
-- name, so it still swings) that carries:
--   SignKind  whose name goes on it: a key of Data/Signs.Shops ("bakery", "cinema", "office"...)
--   SignForm  how it is laid out: "fascia", "roof", "blade", "tile" or "marquee"
--   SignFace  the one side that shows ("Front", "Back", "Left", "Right"); left out, both big sides
--   SignHome  the way back from the board to its building's middle, so that every board on one
--             building finds the same spot and so the same name
-- A part named Ad is an advertising face: it gets one of Data/Signs' adverts, picked from where
-- it stands (AdKind "film" for the cinema's posters).
local function sign(prim: Recipe.Prim, kind: string, form: string, face: string?): Recipe.Prim
	prim.name = prim.name or "Sign"
	local attrs: { [string]: any } = prim.attrs or {}
	attrs.SignKind = kind
	attrs.SignForm = form
	attrs.SignFace = face
	attrs.SignHome = prim.cf:Inverse()
	prim.attrs = attrs
	return prim
end
CityModels.sign = sign

local function advert(prim: Recipe.Prim, face: string?, kind: string?): Recipe.Prim
	prim.name = "Ad"
	local attrs: { [string]: any } = prim.attrs or {}
	attrs.SignFace = face
	attrs.AdKind = kind
	prim.attrs = attrs
	return prim
end
CityModels.advert = advert

-- A poster on each side wall of a ground floor, toward the front (and a second further back on
-- a deep building).
local function sidePosters(r: R, w: number, d: number)
	for _, sx in { -1, 1 } do
		local face = if sx > 0 then "Right" else "Left"
		for z = -d / 2 + 3, if d >= 30 then -d / 2 + 10 else -d / 2 + 3, 7 do
			advert(r:block(sx * w / 2, 2.3, z, sx * (w / 2 + 0.2), 7.3, z + 4, DARK, "SmoothPlastic"), face)
		end
	end
end

-- A blade sign: a tall board standing out from a front wall (at z = zf) on brackets, read from
-- either side. `x` is where along the wall, `y1` to `y2` its height, `reach` how far it stands
-- out, `brackets` the heights it is fixed at.
local function blade(
	r: R,
	kind: string,
	x: number,
	y1: number,
	y2: number,
	zf: number,
	reach: number,
	color: Color3,
	brackets: { number }
)
	sign(
		r:glow(r:block(x - 0.2, y1, zf - 0.7 - reach, x + 0.2, y2, zf - 0.7, color, "SmoothPlastic"), 0),
		kind,
		"blade"
	)
	for _, y in brackets do
		r:block(x - 0.12, y, zf - 0.7, x + 0.12, y + 0.25, zf, DARK, "Metal")
	end
end

-- A board standing on a roof, braced from behind: `hw` is half its width, `y` the roof under it,
-- `z` its front.
local function roofBoard(r: R, hw: number, y: number, tall: number, z: number, color: Color3): Recipe.Prim
	local board = r:glow(r:block(-hw, y, z, hw, y + tall, z + 0.4, color, "SmoothPlastic"), 0)
	for _, sx in { -1, 1 } do
		r:beam(
			Vector3.new(sx * hw * 0.7, y + tall * 0.8, z + 0.4),
			Vector3.new(sx * hw * 0.7, y, z + 0.4 + tall * 0.6),
			0.25,
			0.25,
			DARK,
			"Metal"
		)
	end
	return board
end

-- Draws something (a room, its furniture) as if `f` were the model's middle: whatever `draw`
-- adds to the recipe is moved by `f` afterwards, doors' own frames included.
local function placed(r: R, f: CFrame, draw: () -> ())
	local from = #r.prims
	draw()
	for i = from + 1, #r.prims do
		local p = r.prims[i]
		p.cf = f * p.cf
		if p.frame then
			p.frame = f * p.frame
		end
	end
end

-- Kinds of building ---------------------------------------------------------------------------------

-- The grid over one side of a tower, in face space (x along the wall, y up from the floor the
-- grid starts at, the wall's face at z = 0 and the street toward -z): on the street front slim
-- mullions the whole height, a broader one every third and a sill under every floor's band of
-- windows; round the back and sides only the broad ones, which leaves the street scene room to
-- hang its air units between the bands (TownMap's airCon).
local function towerGrid(q: R, len: number, floors: number, fh: number, trim: Color3, front: boolean)
	local n = math.max(2, math.floor((len - 2) / 3.5))
	local step = (len - 2) / n
	local top = floors * fh
	for i = 1, n - 1 do
		local x = -len / 2 + 1 + i * step
		if i % 3 == 0 then
			q:box(x, top / 2, -0.16, 0.5, top, 0.32, trim)
		elseif front then
			q:box(x, top / 2, -0.12, 0.16, top, 0.24, trim)
		end
	end
	if front then
		for k = 0, floors - 1 do
			q:box(0, k * fh + 0.98, -0.17, len - 1.4, 0.26, 0.34, trim)
		end
	end
end

-- A balcony in face space: a slab, a railing of balusters between corner posts, and rails.
local function balcony(q: R, trim: Color3)
	q:box(0, 0.15, -1.1, 6.8, 0.3, 2.2, trim)
	q:box(0, 1.45, -2.12, 6.8, 0.12, 0.12, TRIM_DARK)
	q:box(0, 0.5, -2.12, 6.8, 0.08, 0.08, TRIM_DARK)
	for _, s in { -1, 1 } do
		q:box(s * 3.34, 1.45, -1.1, 0.12, 0.12, 2.2, TRIM_DARK)
		q:box(s * 3.34, 0.88, -2.12, 0.12, 1.15, 0.12, TRIM_DARK)
		q:box(s * 3.34, 0.88, -1.1, 0.08, 1.15, 0.08, TRIM_DARK)
	end
	for i = 1, 7 do
		q:box(-3.4 + i * 0.85, 0.95, -2.12, 0.06, 0.9, 0.06, TRIM_DARK)
	end
end

-- An air unit for a flat roof, 4 by 3.4: a casing on a skid, a fan under its guard on top and
-- louvres down the front.
local function acUnit(q: R)
	q:box(0, 0.15, 0, 3.6, 0.3, 3.0, TRIM_DARK, "Metal")
	q:box(0, 1.0, 0, 4, 1.4, 3.4, METAL, "Metal")
	q:cyl(-0.8, 1.75, 0, 0.1, 2.2, "y", shade(METAL, 0.82), "Metal")
	q:cyl(-0.8, 1.82, 0, 0.08, 0.5, "y", TRIM_DARK, "Metal")
	for i = 0, 3 do
		q:box(0.3, 0.55 + i * 0.3, -1.73, 3.0, 0.12, 0.06, shade(METAL, 0.78), "Metal")
	end
	q:box(1.5, 1.75, 0.6, 0.6, 0.1, 1.2, shade(METAL, 0.9), "Metal")
end

-- A timber water tank on legs, 4.4 across: legs, a deck, the tank with two hoops, a pointed lid
-- and a ladder up one side.
local function waterTank(q: R)
	for _, o in { { -1.4, -1.4 }, { 1.4, 1.4 }, { -1.4, 1.4 }, { 1.4, -1.4 } } do
		q:box(o[1], 0.9, o[2], 0.3, 1.8, 0.3, TRIM_DARK, "Wood")
	end
	q:box(0, 1.9, 0, 3.6, 0.2, 3.6, WOOD_DARK, "Wood")
	q:cyl(0, 3.8, 0, 3.6, 4.4, "y", rgb(196, 150, 110), "Wood")
	for _, y in { 2.7, 4.8 } do
		q:cyl(0, y, 0, 0.14, 4.56, "y", TRIM_DARK, "Wood")
	end
	q:cone(0, 6.3, 0, 1.4, 4.8, WOOD_DARK, "Wood")
	for _, x in { -0.4, 0.4 } do
		q:box(x, 3.6, -2.35, 0.1, 3.6, 0.1, TRIM_DARK, "Wood")
	end
	for i = 0, 4 do
		q:box(0, 2.2 + i * 0.7, -2.35, 0.8, 0.08, 0.08, TRIM_DARK, "Wood")
	end
end

export type TowerSpec = {
	w: number,
	d: number,
	floors: number,
	wall: Color3,
	glass: Color3?,
	base: Color3?,
	trim: Color3?,
	top: string?, -- "ac" | "helipad" | "spire" | "garden" | "sign"
	sign: Color3?,
	balconies: boolean?, -- flats: a balcony on every floor of the front
	kind: string?, -- whose name is over the door (Data/Signs.Shops): flats or an office unless said
}

-- A tower: a ground floor of shopfront glass under a canopy, then floors with a band of windows
-- right round each, a crown and something on the roof.
function CityModels.tower(spec: TowerSpec): (R) -> ()
	return function(r: R)
		local w, d = spec.w, spec.d
		local fh = 4.2
		-- the ground floor is a lobby you can walk into, so it is tall enough for a person
		local g = 8.4
		local h = g + spec.floors * fh
		local glass = spec.glass or GLASS
		local trim = spec.trim or WHITE
		local base = spec.base or shade(spec.wall, 0.9)
		local box = Interiors.shell(r, {
			w = w,
			d = d,
			h = g,
			wall = base,
			trim = trim,
			doorW = 5,
			door = shade(spec.wall, 0.7),
			floor = rgb(232, 226, 214),
			floorMat = "Marble",
		})
		Interiors.fill(r, if spec.balconies then "flats" else "lobby", box, spec.wall)
		local kind = spec.kind or (if spec.balconies then "flats" else "office")
		-- the way in: a canopy on two columns, and a sign band over the ground floor
		r:block(-5.4, g - 0.9, -d / 2 - 4, 5.4, g - 0.4, -d / 2, trim, "SmoothPlastic")
		-- the building's name on a board along the canopy's front edge, and a poster on each side
		-- wall of the lobby
		local nameBoard =
			r:block(-5.4, g - 0.4, -d / 2 - 4, 5.4, g + 1.4, -d / 2 - 3.7, spec.sign or trim, "SmoothPlastic")
		sign(r:glow(nameBoard, 0), kind, "fascia", "Front")
		sidePosters(r, w, d)
		for _, cx in { -4.8, 4.8 } do
			r:cyl(cx, (g - 0.9) / 2, -d / 2 - 3.4, g - 0.9, 0.6, "y", trim, "SmoothPlastic")
		end
		r:block(
			-w / 2 - 0.2,
			g - 0.4,
			-d / 2 - 0.4,
			w / 2 + 0.2,
			g + 0.5,
			d / 2 + 0.4,
			spec.sign or trim,
			"SmoothPlastic"
		)
		r:block(-w / 2, g, -d / 2, w / 2, h, d / 2, spec.wall, "Plaster")
		-- pilasters up the corners, then the grid of mullions and sills over every side (a very
		-- tall tower in two halves, which are the same piece)
		for _, cx in { -w / 2, w / 2 } do
			for _, cz in { -d / 2, d / 2 } do
				r:block(cx - 0.7, g, cz - 0.7, cx + 0.7, h, cz + 0.7, trim, "SmoothPlastic")
			end
		end
		local halves = if spec.floors > 20 and spec.floors % 2 == 0 then 2 else 1
		local per = spec.floors // halves
		local faces: { { len: number, at: CFrame, front: boolean } } = {
			{ len = w, at = CFrame.new(0, 0, -d / 2), front = true },
			{ len = w, at = CFrame.new(0, 0, d / 2) * yaw(180), front = false },
			{ len = d, at = CFrame.new(w / 2, 0, 0) * yaw(-90), front = false },
			{ len = d, at = CFrame.new(-w / 2, 0, 0) * yaw(90), front = false },
		}
		for c = 0, halves - 1 do
			for _, face in faces do
				local len = face.len
				drawAt(r, CFrame.new(0, g + c * per * fh, 0) * face.at, function(q)
					towerGrid(q, len, per, fh, trim, face.front)
				end)
			end
		end
		if spec.balconies then
			for k = 0, spec.floors - 1 do
				for _, sx in { -1, 1 } do
					stamp(r, "balcony:" .. trim:ToHex(), CFrame.new(sx * w / 4, g + k * fh + 0.9, -d / 2), function(q)
						balcony(q, trim)
					end)
				end
			end
		end
		for k = 0, spec.floors - 1 do
			local y1, y2 = g + k * fh + 1.1, g + (k + 1) * fh - 0.7
			local bands = {
				r:block(-w / 2 + 1, y1, -d / 2 - 0.12, w / 2 - 1, y2, -d / 2, glass, "Glass"),
				r:block(-w / 2 + 1, y1, d / 2, w / 2 - 1, y2, d / 2 + 0.12, glass, "Glass"),
				r:block(-w / 2 - 0.12, y1, -d / 2 + 1, -w / 2, y2, d / 2 - 1, glass, "Glass"),
				r:block(w / 2, y1, -d / 2 + 1, w / 2 + 0.12, y2, d / 2 - 1, glass, "Glass"),
			}
			-- somebody is always working late: about a third of the floors stay lit after dark
			for side, band in bands do
				if (k * 5 + side * 3 + spec.floors) % 3 == 0 then
					lit(r, band)
				end
			end
		end
		r:block(-w / 2 - 0.4, h, -d / 2 - 0.4, w / 2 + 0.4, h + 1, d / 2 + 0.4, trim, "SmoothPlastic")
		-- a parapet round the roof, a stair hut and a water tank on legs
		r:block(-w / 2 - 0.4, h + 1, -d / 2 - 0.4, w / 2 + 0.4, h + 2.2, -d / 2 + 0.4, trim, "SmoothPlastic")
		r:block(-w / 2 - 0.4, h + 1, d / 2 - 0.4, w / 2 + 0.4, h + 2.2, d / 2 + 0.4, trim, "SmoothPlastic")
		r:block(-w / 2 - 0.4, h + 1, -d / 2 + 0.4, -w / 2 + 0.4, h + 2.2, d / 2 - 0.4, trim, "SmoothPlastic")
		r:block(w / 2 - 0.4, h + 1, -d / 2 + 0.4, w / 2 + 0.4, h + 2.2, d / 2 - 0.4, trim, "SmoothPlastic")
		r:block(w / 2 - 9, h + 1, d / 2 - 8, w / 2 - 3, h + 4.4, d / 2 - 3, shade(spec.wall, 0.9), "Plaster")
		r:block(w / 2 - 9.2, h + 4.4, d / 2 - 8.2, w / 2 - 2.8, h + 4.7, d / 2 - 2.8, trim, "SmoothPlastic")
		r:block(w / 2 - 9.1, h + 1, d / 2 - 6.3, w / 2 - 9, h + 3.7, d / 2 - 4.7, DOOR, "SmoothPlastic")
		r:cyl(w / 2 - 4.2, h + 5.3, d / 2 - 4.2, 1.2, 0.5, "y", METAL, "Metal")
		stamp(r, "waterTank", CFrame.new(-w / 2 + 3.6, h + 1, d / 2 - 3.6), waterTank, true)
		-- offices sell their walls: a banner up the east side, and on the tall ones a screen over
		-- the door and a banner up the west side too. They stand just clear of the glass.
		if kind == "office" or kind == "tower" then
			local y1, y2 = g + fh + 0.4, g + 5 * fh - 0.4
			advert(r:block(w / 2 + 0.16, y1, -5, w / 2 + 0.46, y2, 5, DARK, "SmoothPlastic"), "Right")
			if spec.floors >= 16 then
				local hw = math.min(w * 0.24, 8)
				advert(r:block(-hw, y1 + fh, -d / 2 - 0.6, hw, y2 + fh, -d / 2 - 0.3, DARK, "SmoothPlastic"), "Front")
				advert(
					r:block(-w / 2 - 0.46, y1 + 3 * fh, -6, -w / 2 - 0.16, y2 + 5 * fh, 6, DARK, "SmoothPlastic"),
					"Left"
				)
			end
		elseif kind == "hotel" then
			-- the hotel's blade, up the front between two rows of windows
			local fixings = { g + fh + 0.4, g + 6 * fh - 0.2 }
			blade(r, kind, w / 2 - 5, g + 4, g + 28, -d / 2, 3.2, spec.sign or trim, fixings)
		end
		local top = spec.top or "ac"
		if top == "ac" then
			stamp(r, "acUnit", CFrame.new(-w / 4 + 2.5, h + 1, -d / 6 + 2) * yaw(90), acUnit, true)
			stamp(r, "acUnit", CFrame.new(w / 6 + 2, h + 1, d / 8 + 2.5), acUnit, true)
			-- a billboard on legs along the front of the roof, an advert on each side of it
			local by, bz = h + 3.2, -d / 2 + 2
			advert(r:block(-8, by, bz, 8, by + 6, bz + 0.4, DARK, "SmoothPlastic"))
			r:block(-8.2, by + 6, bz - 0.1, 8.2, by + 6.25, bz + 0.5, METAL, "Metal")
			r:block(-8.2, by - 0.25, bz - 0.1, 8.2, by, bz + 0.5, METAL, "Metal")
			for _, sx in { -1, 1 } do
				r:block(sx * 6 - 0.25, h + 1, bz + 0.4, sx * 6 + 0.25, by + 5, bz + 0.9, DARK, "Metal")
				r:beam(
					Vector3.new(sx * 6, by + 3, bz + 0.9),
					Vector3.new(sx * 6, h + 1, bz + 5),
					0.3,
					0.3,
					DARK,
					"Metal"
				)
			end
		elseif top == "helipad" then
			-- a pad on a deck, a white ring and the H, lights round its edge
			local pad = math.min(w, d) - 4
			r:cyl(0, h + 1.3, 0, 0.6, pad, "y", DARK, "SmoothPlastic")
			r:cyl(0, h + 1.63, 0, 0.06, pad - 1.4, "y", WHITE, "SmoothPlastic")
			r:cyl(0, h + 1.69, 0, 0.06, pad - 2.4, "y", shade(DARK, 1.1), "SmoothPlastic")
			for _, sx in { -1, 1 } do
				r:block(sx * 1.6 - 0.45, h + 1.72, -3.2, sx * 1.6 + 0.45, h + 1.78, 3.2, WHITE, "SmoothPlastic")
			end
			r:block(-1.15, h + 1.72, -0.4, 1.15, h + 1.78, 0.4, WHITE, "SmoothPlastic")
			for k = 0, 7 do
				local a = k / 8 * math.pi * 2
				r:glow(
					r:ball(math.cos(a) * pad / 2, h + 1.75, math.sin(a) * pad / 2, 0.5, rgb(255, 214, 120), "Neon"),
					0
				)
			end
		elseif top == "spire" then
			-- a crown of three steps, each under a cap, and the mast with its light
			local steps = { { w / 3, 1, 5 }, { w / 4, 5, 7.6 }, { w / 6, 7.6, 9.8 } }
			for i, st in steps do
				local hw = st[1] :: number
				r:block(
					-hw,
					h + st[2],
					-hw,
					hw,
					h + st[3] - 0.3,
					hw,
					if i == 2 then shade(spec.wall, 0.86) else spec.wall,
					"SmoothPlastic"
				)
				r:block(-hw - 0.3, h + st[3] - 0.3, -hw - 0.3, hw + 0.3, h + st[3], hw + 0.3, trim, "SmoothPlastic")
			end
			r:cyl(0, h + 17.5, 0, 15.4, 0.8, "y", METAL, "Metal")
			for _, y in { h + 13, h + 19 } do
				r:cyl(0, y, 0, 0.3, 1.6, "y", METAL, "Metal")
			end
			r:glow(r:ball(0, h + 25.5, 0, 1.4, rgb(255, 90, 80), "Neon"), 0)
		elseif top == "garden" then
			-- a roof garden: a lawn with a paved walk across it, beds and shrubs, a bench
			r:block(-w / 2 + 1.5, h + 1, -d / 2 + 1.5, w / 2 - 1.5, h + 1.5, d / 2 - 1.5, rgb(140, 184, 112), "Grass")
			r:block(-w / 2 + 1.5, h + 1.5, -1.5, w / 2 - 1.5, h + 1.56, 1.5, rgb(226, 220, 206), "Pavement")
			for _, sx in { -1, 1 } do
				flowerBed(r, CFrame.new(sx * w / 4, h + 1.5, -d / 2 + 4.5))
				local leaf = r:lump(
					CFrame.new(sx * w / 5, h + 2.8, d / 4) * CFrame.Angles(0.2, sx, 0.1),
					3.6,
					2.8,
					3.2,
					LEAF_DARK
				)
				leaf.name = "Leaf"
				r:lump(
					CFrame.new(sx * (w / 5 + 2.2), h + 2.1, d / 4 - 1.6) * CFrame.Angles(0, sx * 2, 0.2),
					2,
					1.5,
					1.8,
					LEAF
				).name =
					"Leaf"
			end
			bench(r, 0, d / 4 - 2, 180)
		elseif top == "sign" then
			-- the name on the roof, read from the street in front and from the one behind
			local col = spec.sign or rgb(206, 112, 100)
			sign(r:glow(r:block(-w / 3, h + 1, -1, w / 3, h + 6, 0, col, "SmoothPlastic"), 0), kind, "roof")
			r:block(-w / 3 - 0.5, h + 1, -0.5, -w / 3, h + 6, 0.5, METAL, "Metal")
			r:block(w / 3, h + 1, -0.5, w / 3 + 0.5, h + 6, 0.5, METAL, "Metal")
			r:block(-w / 3 - 0.5, h + 6, -0.5, w / 3 + 0.5, h + 6.3, 0.5, METAL, "Metal")
		end
	end
end

-- An upper window's dressing in face space round a pane 2.4 by 2.4 standing on y = 0 (the pane
-- is a part of its own, so it can light up): jambs, a head with a keystone, a sill, a cross of
-- glazing bars, and a flower box on brackets under the sill, planted and trailing.
local function shopWindow(q: R, trim: Color3)
	for _, s in { -1, 1 } do
		q:box(s * 1.31, 1.2, -0.13, 0.22, 2.64, 0.26, trim)
		q:box(s * 1.0, -0.85, -0.2, 0.12, 0.3, 0.3, trim)
		q:lump(CFrame.new(s * 0.75, -0.42, -0.62) * CFrame.Angles(0.3, s, 0.2), 0.62, 0.5, 0.32, LEAVES[2])
	end
	q:box(0, 2.54, -0.15, 3.1, 0.28, 0.3, trim)
	q:box(0, 2.66, -0.2, 0.5, 0.42, 0.4, trim)
	q:box(0, -0.1, -0.22, 3.2, 0.22, 0.44, trim)
	q:box(0, 1.2, -0.16, 0.12, 2.4, 0.08, trim)
	q:box(0, 1.74, -0.16, 2.4, 0.12, 0.08, trim)
	q:box(0, -0.47, -0.32, 2.7, 0.5, 0.56, rgb(150, 116, 88))
	for i, x in { -0.95, -0.3, 0.35, 0.95 } do
		sprig(q, x, -0.22, -0.32, 0.32 + (i % 2) * 0.16, BLOOMS[(i - 1) % 2 + 1], LEAVES[i % 3 + 1])
	end
end

-- A plainer window in face space for side walls: glass drawn as paint, a frame, a cross of bars
-- and a sill.
local function sideWindow(q: R, trim: Color3)
	q:box(0, 1.2, -0.03, 2.0, 2.4, 0.06, PANE)
	for _, s in { -1, 1 } do
		q:box(s * 1.1, 1.2, -0.1, 0.2, 2.6, 0.2, trim)
	end
	q:box(0, 2.5, -0.13, 2.6, 0.24, 0.26, trim)
	q:box(0, -0.1, -0.18, 2.7, 0.2, 0.36, trim)
	q:box(0, 1.2, -0.08, 0.1, 2.4, 0.1, trim)
	q:box(0, 1.7, -0.08, 2.0, 0.1, 0.1, trim)
end

export type ShopSpec = {
	w: number,
	d: number,
	floors: number,
	wall: Color3,
	awning: Color3?,
	trim: Color3?,
	cols: number?,
	sign: Color3?,
	kind: string?, -- what it sells, which furnishes it (Data/Interiors)
	ads: boolean?, -- false for a building that carries no adverts (the school, the clinic)
}

-- A shop row building: a shopfront and striped awning at the bottom, rows of windows above, a
-- cornice and a sign board.
function CityModels.shop(spec: ShopSpec): (R) -> ()
	return function(r: R)
		local w, d = spec.w, spec.d
		-- the shop itself is a tall ground floor you can walk into; the storeys above are flats
		local G = 8.4
		local fh = 4.4
		local h = G + (spec.floors - 1) * fh + 0.6
		local trim = spec.trim or WHITE
		local awning = spec.awning or rgb(204, 104, 96)
		local box = Interiors.shell(r, {
			w = w,
			d = d,
			h = G,
			wall = spec.wall,
			mat = "Brick",
			trim = trim,
			door = shade(awning, 0.82),
		})
		local kind = spec.kind or "grocer"
		Interiors.fill(r, kind, box, spec.wall)
		r:block(-w / 2, G, -d / 2, w / 2, h, d / 2, spec.wall, "Brick")
		-- the fascia: a box sign right across the shopfront with the shop's name on it. It stands
		-- a stud proud of the wall, from over the awning up to just under the first sills.
		local fascia =
			r:block(-w / 2 + 0.6, 7.65, -d / 2 - 1, w / 2 - 0.6, 9.3, -d / 2, spec.sign or awning, "SmoothPlastic")
		sign(r:glow(fascia, 0), kind, "fascia", "Front")
		-- the striped awning, sloping down and out over the window and the door from under the
		-- fascia. (It used to tip up, through where the fascia is now.) It reaches as far over the
		-- pavement as it did, so the building's footprint, and with it its lot, has not moved.
		local reach = 1.6 + 1.7 * math.cos(math.rad(22)) + 0.1 * math.sin(math.rad(22))
		local tilt = math.rad(12)
		local az = -d / 2 - reach + 1.7 * math.cos(tilt) + 0.1 * math.sin(tilt)
		local stripes = math.max(6, math.floor(w / 5))
		for k = 0, stripes - 1 do
			local x1 = -w / 2 + 1 + k * (w - 2) / stripes
			local x2 = x1 + (w - 2) / stripes
			local col = if k % 2 == 0 then awning else WHITE
			r:boxAt(CFrame.new((x1 + x2) / 2, 7.2, az) * CFrame.Angles(-tilt, 0, 0), x2 - x1, 0.2, 3.4, col, "Fabric")
			-- the hem hanging from its front edge, stripe by stripe
			local fy = 7.2 - 1.7 * math.sin(tilt)
			r:block(x1, fy - 0.6, -d / 2 - reach + 0.005, x2, fy - 0.08, -d / 2 - reach + 0.085, col, "Fabric")
		end
		-- two arms from the wall out to the awning's edge
		for _, sx in { -1, 1 } do
			r:beam(
				Vector3.new(sx * (w / 2 - 1.6), 5.4, -d / 2),
				Vector3.new(sx * (w / 2 - 1.6), 6.75, -d / 2 - reach + 0.45),
				0.12,
				0.12,
				DARK,
				"Metal"
			)
		end
		-- a lamp on the wall either side of the front, and a board hanging by the door
		for _, sx in { -1, 1 } do
			r:block(sx * (w / 2 - 0.5) - 0.15, 5.4, -d / 2 - 0.9, sx * (w / 2 - 0.5) + 0.15, 5.7, -d / 2, DARK, "Metal")
			r:glow(r:ball(sx * (w / 2 - 0.5), 5.1, -d / 2 - 0.9, 0.9, rgb(255, 236, 190), "SmoothPlastic"), 0)
		end
		r:block(-3.6, 6.3, -d / 2 - 2.2, -3.3, 6.6, -d / 2, DARK, "Metal")
		local hanging = r:block(-4.4, 4.6, -d / 2 - 2.1, -2.5, 6.3, -d / 2 - 1.9, spec.sign or awning, "Wood")
		hanging.name = "SwingSign"
		sign(hanging, kind, "tile", "Front")
		-- adverts: a poster on each side wall, and a big one on the blank back wall (two on a
		-- wide building)
		if spec.ads ~= false then
			sidePosters(r, w, d)
			local backs: { number } = if w >= 50 then { -w / 4, w / 4 } else { 0 }
			for _, x in backs do
				advert(r:block(x - 7, 3.5, d / 2, x + 7, 12, d / 2 + 0.2, DARK, "SmoothPlastic"), "Back")
			end
		end
		local cols = spec.cols or math.max(2, math.floor(w / 6))
		for f = 1, spec.floors - 1 do
			local y1 = G + (f - 1) * fh + 1
			for c = 0, cols - 1 do
				local x = -w / 2 + (c + 0.5) * w / cols
				local pane = r:block(x - 1.2, y1, -d / 2 - 0.12, x + 1.2, y1 + 2.4, -d / 2, GLASS, "Glass")
				if (c + f) % 2 == 0 then
					lit(r, pane)
				end
				-- its frame, sill and flower box
				stamp(r, "shopWindow:" .. trim:ToHex(), CFrame.new(x, y1, -d / 2), function(q)
					shopWindow(q, trim)
				end)
			end
			-- windows down both sides
			local n = math.max(1, math.floor((d - 4) / 7))
			for i = 1, n do
				local z = -d / 2 + 2 + (i - 0.5) * (d - 4) / n
				for _, sx in { -1, 1 } do
					stamp(r, "sideWindow:" .. trim:ToHex(), CFrame.new(sx * w / 2, y1, z) * yaw(-90 * sx), function(q)
						sideWindow(q, trim)
					end)
				end
			end
			-- a string course along the front between the storeys
			if f < spec.floors - 1 then
				r:block(
					-w / 2,
					G + f * fh - 0.12,
					-d / 2 - 0.18,
					w / 2,
					G + f * fh + 0.12,
					-d / 2,
					trim,
					"SmoothPlastic"
				)
			end
		end
		r:block(-w / 2 - 0.4, h - 0.6, -d / 2 - 0.4, w / 2 + 0.4, h + 0.3, d / 2 + 0.4, trim, "SmoothPlastic")
		-- a tall shop has a blade sign up its front, in the gap between the last two windows (a
		-- wide one has a second at the other end)
		if spec.floors >= 3 then
			local fixings = { G + 2.2, h - 2.2 }
			blade(r, kind, -w / 2 + (cols - 1) * w / cols, G + 1.7, h - 1.3, -d / 2, 2.2, spec.sign or awning, fixings)
			if w >= 50 then
				blade(r, kind, -w / 2 + w / cols, G + 1.7, h - 1.3, -d / 2, 2.2, spec.sign or awning, fixings)
			end
		end
		-- the name again on the roof
		if spec.sign then
			sign(roofBoard(r, math.min(w * 0.32, 13), h + 0.3, 3.2, -d / 2 + 0.3, spec.sign), kind, "roof", "Front")
		end
		-- on the roof: an air unit, a vent and a chimney stack
		stamp(r, "acUnit", CFrame.new(w / 2 - 5, h + 0.3, d / 2 - 4.25), acUnit, true)
		r:cyl(-w / 2 + 4, h + 1.1, d / 2 - 4, 1.6, 1.2, "y", METAL, "Metal")
		r:cyl(-w / 2 + 4, h + 2.0, d / 2 - 4, 0.2, 1.6, "y", shade(METAL, 0.85), "Metal")
		r:block(-w / 2 + 7, h + 0.3, d / 2 - 3, -w / 2 + 9, h + 3, d / 2 - 1.4, rgb(188, 130, 110), "Brick")
		r:block(-w / 2 + 6.8, h + 3, d / 2 - 3.2, -w / 2 + 9.2, h + 3.25, d / 2 - 1.2, trim, "SmoothPlastic")
		for _, x in { -w / 2 + 7.55, -w / 2 + 8.45 } do
			r:cyl(x, h + 3.6, d / 2 - 2.2, 0.7, 0.5, "y", POT, "SmoothPlastic")
		end
	end
end

-- A small house with a gable roof and a chimney: one room inside, with a bed, a table, a rug and
-- a lamp, a window either side of a door that opens.
local function house(
	r: R,
	x: number,
	z: number,
	w: number,
	d: number,
	wall: Color3,
	roof: Color3,
	turn: number?,
	inside: string?
)
	local f = CFrame.new(x, 0, z) * CFrame.Angles(0, math.rad(turn or 0), 0)
	local h = 7.2
	placed(r, f, function()
		local box = Interiors.shell(r, {
			w = w,
			d = d,
			h = h,
			wall = wall,
			doorW = 3,
			doorH = 6,
			sill = 2.4,
			door = shade(roof, 0.8),
		})
		Interiors.fill(r, inside or "home", box, roof)
	end)
	-- the ceiling, then the roof over it: the gables in the wall's colour, and two slabs of
	-- shingles that overhang them, kept inside the old roof's outline
	local rh = 3.8
	local run = d / 2 + 0.5
	local eave, ridge = h + 0.3, h + 0.3 + rh
	local t = 0.3
	local sin = rh / math.sqrt(rh * rh + run * run)
	local z0 = run - t * sin
	local function roofY(zz: number): number
		return ridge - rh * math.abs(zz) / run
	end
	placed(r, f, function()
		r:box(0, h + 0.15, 0, w + 0.4, 0.3, d + 0.4, WHITE, "SmoothPlastic")
		r:wedge(CFrame.new(0, eave + rh / 2, -run / 2), w, rh, run, wall, "Plaster")
		r:wedge(CFrame.new(0, eave + rh / 2, run / 2) * yaw(180), w, rh, run, wall, "Plaster")
		local hx = w / 2 + 0.5
		for _, s in { -1, 1 } do
			for _, p in
				Geometry.quad(
					Vector3.new(-hx, ridge, 0),
					Vector3.new(hx, ridge, 0),
					Vector3.new(hx, roofY(z0), s * z0),
					Vector3.new(-hx, roofY(z0), s * z0),
					t,
					roof,
					"RoofShingles",
					Vector3.yAxis
				)
			do
				r:add(p)
			end
		end
		-- the trim every house of this size shares: fascia and barge boards, the ridge, the
		-- chimney's cap and a window in each end wall
		stamp(r, string.format("houseTrim:%gx%g", w, d), CFrame.identity, function(q)
			for _, s in { -1, 1 } do
				q:box(0, roofY(z0) - 0.2, s * (z0 - 0.075), w + 1, 0.4, 0.15, WHITE)
				q:beam(
					Vector3.new(s * (hx - 0.13), roofY(z0) - 0.22, -z0),
					Vector3.new(s * (hx - 0.13), ridge - 0.22, 0),
					0.15,
					0.4,
					WHITE
				)
				q:beam(
					Vector3.new(s * (hx - 0.13), roofY(z0) - 0.22, z0),
					Vector3.new(s * (hx - 0.13), ridge - 0.22, 0),
					0.15,
					0.4,
					WHITE
				)
				-- the window in this end wall: glass, a frame, a bar down the middle and a sill
				local wx = s * w / 2
				q:box(wx + s * 0.03, 3.9, 0, 0.06, 2.6, 2.2, PANE)
				q:box(wx + s * 0.08, 5.3, 0, 0.16, 0.2, 2.6, WHITE)
				q:box(wx + s * 0.08, 3.9, -1.2, 0.16, 2.6, 0.2, WHITE)
				q:box(wx + s * 0.08, 3.9, 1.2, 0.16, 2.6, 0.2, WHITE)
				q:box(wx + s * 0.08, 3.9, 0, 0.16, 2.6, 0.1, WHITE)
				q:box(wx + s * 0.16, 2.5, 0, 0.32, 0.2, 2.8, WHITE)
			end
			q:box(0, ridge + t * math.sqrt(1 - sin * sin), 0, w + 1, 0.26, 2 * t * sin + 0.36, WHITE)
			q:box(w / 4, h + rh * 0.9 + 1.8, d / 5, 1.7, 0.2, 1.7, WHITE)
		end)
		-- a hood over the door on two brackets
		stamp(r, "doorHood", CFrame.new(0, 0, -d / 2), function(q)
			q:box(0, 6.94, -0.5, 3.8, 0.18, 1.0, WHITE)
			q:box(0, 6.82, -0.94, 3.8, 0.3, 0.12, WHITE)
			for _, s in { -1, 1 } do
				q:beam(Vector3.new(s * 1.55, 6.1, 0), Vector3.new(s * 1.55, 6.82, -0.8), 0.12, 0.12, WHITE)
			end
		end)
	end)
	-- a chimney with its pot (the pot smokes), and a lamp by the door
	r:boxAt(f * CFrame.new(w / 4, h + rh * 0.9, d / 5), 1.4, 3.4, 1.4, rgb(188, 130, 110), "Brick")
	r:smoke(r:cyl(0, 0, 0, 0.6, 0.6, "y", POT, "SmoothPlastic"))
	local pot = r.prims[#r.prims]
	pot.cf = f * CFrame.new(w / 4, h + rh * 0.9 + 2.2, d / 5) * pot.cf
	r:glow(r:lump(f * CFrame.new(2.6, 5.6, -d / 2 - 0.5), 0.8, 0.8, 0.8, rgb(255, 236, 190)), 0)
end
CityModels.house = house

-- Trees ----------------------------------------------------------------------------------------------
-- The user, with a picture of firs standing apart on a hill at sunset: "make the grass and plants
-- like in the image". So the woods are mostly firs: a straight thin reddish trunk showing under
-- tiers of drooping boughs that get shorter up to a thin spire, dark blue green inside and olive
-- where the tops catch the sun. A bough is a wedge hanging down and out from a dark core, and
-- each tier is turned against the one under it. The broadleaf trees have a full, soft crown of
-- leafy clumps on a forked trunk. Each crown is one piece (one mesh in the game) named Leaf, so
-- the client sways it in the wind (World/Ambience) and the trunk stays put: a tree is two parts.

local FIR_CORE = rgb(28, 50, 48)
local FIR_LOW = rgb(38, 72, 62)
local FIR_HIGH = rgb(78, 104, 66)
local FIR_TIP = rgb(118, 128, 74)
local FIR_BARK = rgb(124, 78, 58)

local function mix(a: Color3, b: Color3, t: number): Color3
	return Color3.new(a.R + (b.R - a.R) * t, a.G + (b.G - a.G) * t, a.B + (b.B - a.B) * t)
end

-- One bough on q, hanging from the middle at height y: a wedge `len` long, `wide` across and
-- `thick` where it leaves the middle, pointing out along the angle `a` and tipped `droop` down.
-- It starts `inset` inside the middle.
local function bough(
	q: R,
	y: number,
	a: number,
	len: number,
	wide: number,
	thick: number,
	droop: number,
	inset: number,
	color: Color3
)
	local out = Vector3.new(math.cos(a), 0, math.sin(a))
	local along = out * math.cos(droop) - Vector3.yAxis * math.sin(droop)
	local up = out * math.sin(droop) + Vector3.yAxis * math.cos(droop)
	local back = -along
	-- (right, up and back are a right-handed set, as every frame must be)
	local right = up:Cross(back)
	local foot = Vector3.new(0, y, 0) - along * inset
	local cf = CFrame.fromMatrix(foot + along * ((len + inset) / 2) + up * (thick / 2), right, up, back)
	q:wedge(cf, wide, thick, len + inset, color, "Grass")
end

-- A fir's crown on q: rows of boughs from the lowest tips at `base` up to a slim spire whose point
-- is at `top`, the lowest boughs `reach` long and each row turned against the one under it.
-- `boughs` is how many to a row low down (a row near the top has three).
type Fir = { base: number, top: number, reach: number, rows: number, boughs: number, trunk: number }
local function firCrown(q: R, f: Fir)
	local droop0 = 0.72
	local low = f.base + f.reach * math.sin(droop0) * 0.9
	local high = f.top - (f.top - f.base) * 0.17
	local core = f.reach * 0.24
	local function rowAt(t: number): number
		return low + (high - low) * t ^ 0.85
	end
	-- the dark middle the boughs grow from, up to the top row (the piece's square box, which the
	-- merge hangs the rest on)
	local coreTop = high
	q:box(0, (f.base + 0.6 + coreTop) / 2, 0, core, coreTop - f.base - 0.6, core, FIR_CORE, "Grass")
	for i = 0, f.rows - 1 do
		local t = i / (f.rows - 1)
		local y = rowAt(t)
		local len = f.reach * (1 - 0.74 * t)
		local droop = droop0 - 0.24 * t
		local tone = mix(FIR_LOW, FIR_HIGH, t ^ 1.4)
		local n = if t > 0.6 then 3 else f.boughs
		local turn = i * (math.pi * 2 / n / 2 + 0.19)
		for k = 0, n - 1 do
			-- every other bough a shade darker, and one a row lit at its tip
			local color = if k % 2 == 0 then tone else shade(tone, 0.84)
			if k == 0 and t > 0.3 then
				color = mix(tone, FIR_TIP, 0.4)
			end
			local wide = len * (if n == 3 then 0.9 else 0.72) + 0.3
			-- (each a little off the even spacing, so no two lie in line and share a face)
			local a = turn + k * math.pi * 2 / n + (k % 3) * 0.07
			bough(q, y, a, len, wide, len * 0.32 + 0.25, droop, math.min(core * 0.4, len * 0.15), color)
		end
	end
	-- the spire: three slim boughs standing upright round the leader
	for k = 0, 2 do
		bough(q, high - 0.3, k * math.pi * 2 / 3 + 0.5, 0.5 + f.reach * 0.07, 0.36, f.top - high + 0.3, 0, 0, FIR_HIGH)
	end
end

local FIRS: { [string]: Fir } = {
	young = { base = 0.9, top = 8.5, reach = 2.5, rows = 5, boughs = 4, trunk = 0.5 },
	fir = { base = 2.6, top = 17, reach = 4.2, rows = 6, boughs = 4, trunk = 0.8 },
	tall = { base = 3.6, top = 26, reach = 5.4, rows = 8, boughs = 3, trunk = 1.05 },
}

-- A fir standing at `at`: "young", "fir" or "tall".
local function fir(r: R, kind: string, at: CFrame)
	local f = FIRS[kind]
	drawAt(r, at, function(q)
		q:cyl(0, (f.base + 1.6) / 2, 0, f.base + 1.6, f.trunk, "y", FIR_BARK, "Wood")
	end)
	stamp(r, "fir:" .. kind, at, function(q)
		firCrown(q, f)
	end).name = "Leaf"
end
CityModels.fir = fir

-- A broadleaf tree's crown: a big heart of leaves, clumps round its lower edge and two on top,
-- darker underneath and lighter where the sun is. x, y, z, width, height, depth, tone (0 low to
-- 1 top) and a turn of its own.
local LEAF_LOW = rgb(54, 94, 60)
local LEAF_MID = rgb(82, 126, 70)
local LEAF_TOP = rgb(110, 142, 78)
local CROWN = {
	{ 0, 6.6, 0, 5.4, 4.6, 5.2, 0.4, 0.2 },
	{ 2.3, 5.5, 0.6, 3.9, 3.2, 3.6, 0.12, 0.9 },
	{ -1.7, 5.4, 1.8, 3.7, 3.0, 3.9, 0.04, 2.1 },
	{ -0.9, 5.5, -2.2, 3.9, 3.0, 3.5, 0, 1.4 },
	{ 1.2, 8.4, -0.7, 3.7, 3.1, 3.5, 0.75, 0.5 },
	{ -1.1, 8.6, 0.9, 3.5, 3.0, 3.6, 0.8, 2.7 },
	{ 0.2, 9.8, 0.1, 2.8, 2.3, 2.8, 1, 1.1 },
}
local BROAD_BARK = rgb(118, 86, 64)

-- A broadleaf tree at `at`, s 1 (or 1.35 for a big one): a trunk that forks into three limbs
-- under the crown (one piece), and the crown's clumps, each named Leaf to sway on its own.
local function broadleaf(r: R, at: CFrame, s: number)
	stamp(r, "broadTrunk:" .. s, at, function(q)
		q:box(0, 2.6 * s, 0, 1.1 * s, 5.2 * s, 1.1 * s, BROAD_BARK, "Wood")
		q:boxAt(CFrame.new(0, 2.5 * s, 0) * yaw(45), 1.1 * s, 5 * s, 1.1 * s, BROAD_BARK, "Wood")
		for _, l in { { 1.9, 6.0, 0.5 }, { -1.7, 6.2, 1.1 }, { -0.2, 6.4, -1.9 } } do
			local limb = Vector3.new(l[1] * s, l[2] * s, l[3] * s)
			q:beam(Vector3.new(0, 4.2 * s, 0), limb, 0.5 * s, 0.5 * s, BROAD_BARK, "Wood")
		end
	end)
	for _, c in CROWN do
		local t = c[7]
		local tone = if t < 0.5 then mix(LEAF_LOW, LEAF_MID, t * 2) else mix(LEAF_MID, LEAF_TOP, t * 2 - 1)
		local f = at * CFrame.new(c[1] * s, c[2] * s, c[3] * s) * CFrame.Angles(0.3, c[8], -0.25)
		r:lump(f, c[4] * s, c[5] * s, c[6] * s, tone, "Grass").name = "Leaf"
	end
end

-- A broadleaf tree in the old call's shape: s near 1 is the usual one, 1.2 or more the big one.
-- Each is turned its own way by where it stands, so a row of them doesn't look stamped.
local function lowTree(r: R, x: number, y: number, z: number, s: number)
	local turn = (x * 0.37 + z * 0.61) % (math.pi * 2)
	broadleaf(r, CFrame.new(x, y, z) * CFrame.Angles(0, turn, 0), if s >= 1.2 then 1.35 else 1)
end
CityModels.lowTree = lowTree

-- A fir in the old call's shape: s under 0.8 is a young one, over 1.25 a tall one.
local function lowPine(r: R, x: number, y: number, z: number, s: number)
	local kind = if s < 0.8 then "young" elseif s > 1.25 then "tall" else "fir"
	fir(r, kind, CFrame.new(x, y, z))
end
CityModels.lowPine = lowPine

M.lowTree = function(r: R)
	lowTree(r, 0, 0, 0, 1)
end
M.lowTreeBig = function(r: R)
	lowTree(r, 0, 0, 0, 1.4)
end
M.lowPine = function(r: R)
	fir(r, "fir", CFrame.identity)
end
M.lowPineBig = function(r: R)
	fir(r, "tall", CFrame.identity)
end
M.firYoung = function(r: R)
	fir(r, "young", CFrame.identity)
end

-- A parked car, nose to local -Z: a body and a cabin in its own colour, and everything every car
-- shares in one piece: wheels and hubs, the sloping windscreen and back window, side windows
-- either side of the pillar, bumpers, a grille, lamps, mirrors and the door shut lines.
local GLASS_CAR = rgb(120, 156, 184)
local function carKit(q: R)
	for _, sx in { -1, 1 } do
		for _, wz in { -2.85, 2.85 } do
			q:cyl(sx * 1.85, 0.75, wz, 0.6, 1.5, "x", TYRE)
			q:cyl(sx * 2.2, 0.75, wz, 0.1, 0.72, "x", rgb(200, 204, 212))
		end
		-- side windows, the pillar between them, and a mirror
		q:box(sx * 1.88, 2.66, -0.35, 0.06, 0.9, 1.5, GLASS_CAR)
		q:box(sx * 1.88, 2.66, 1.35, 0.06, 0.9, 1.5, GLASS_CAR)
		q:box(sx * 1.98, 2.18, -1.3, 0.26, 0.22, 0.34, TRIM_DARK)
		-- the door's shut line
		q:box(sx * 2.12, 1.3, 0.45, 0.04, 1.1, 0.06, shade(TRIM_DARK, 1.2))
		-- lamps front and back
		q:box(sx * 1.45, 1.55, -4.34, 0.8, 0.34, 0.08, rgb(250, 240, 208))
		q:box(sx * 1.45, 1.55, 4.34, 0.8, 0.34, 0.08, rgb(206, 84, 84))
	end
	-- the windscreen and the back window, sloping down to the bonnet and the boot
	q:wedge(CFrame.new(0, 2.65, -1.75), 3.5, 1.4, 1.1, GLASS_CAR)
	q:wedge(CFrame.new(0, 2.65, 2.55) * yaw(180), 3.5, 1.4, 0.7, GLASS_CAR)
	-- bumpers, a grille and the plates
	q:box(0, 0.85, -4.43, 4.1, 0.36, 0.28, rgb(188, 192, 200))
	q:box(0, 0.85, 4.43, 4.1, 0.36, 0.28, rgb(188, 192, 200))
	q:box(0, 1.45, -4.34, 1.5, 0.45, 0.08, TRIM_DARK)
	q:box(0, 1.12, -4.33, 1.1, 0.18, 0.06, rgb(240, 236, 222))
	q:box(0, 1.12, 4.33, 1.1, 0.18, 0.06, rgb(240, 236, 222))
end
local function car(r: R, x: number, y: number, z: number, yawDeg: number, col: Color3)
	local f = CFrame.new(x, y, z) * yaw(yawDeg)
	r:boxAt(f * CFrame.new(0, 1.3, 0), 4.2, 1.5, 8.6, col, "SmoothPlastic")
	r:boxAt(f * CFrame.new(0, 2.7, 0.5), 3.7, 1.3, 3.4, shade(col, 0.96), "SmoothPlastic")
	stamp(r, "carKit", f, carKit)
end
CityModels.car = car

local CAR_COLORS = {
	rgb(214, 120, 108),
	rgb(120, 160, 204),
	rgb(232, 200, 128),
	rgb(246, 242, 232),
	rgb(130, 184, 156),
	rgb(110, 110, 130),
}
for k, col in CAR_COLORS do
	M["parkedCar" .. k] = function(r: R)
		car(r, 0, 0, 0, 0, col)
	end
end

-- The landscaping round a building `w` by `d` (the building's footprint plus `margin` each side),
-- front to local -Z. "garden": a lawn pad, a clipped hedge round the edge with a gap for the path,
-- gate posts with lamps, a paved path to the door, shrubs in the back corners and flower beds by
-- the path. "plaza": stone tubs of flowers at the corners, and benches by the door. No trees: the
-- user asked for none near the roads, and every lot fronts one.
-- The landscaping round a building `w` by `d` (the building's footprint plus `margin` each side),
-- front to local -Z. "garden": a lawn pad, a clipped hedge round the edge with a gap for the path,
-- gate posts with lamps, a paved path to the door, shrubs in the back corners and flower beds by
-- the path. "plaza": stone tubs of flowers at the corners, and benches by the door. No trees: the
-- user asked for none near the roads, and every lot fronts one.
function CityModels.lot(w: number, d: number, kind: string, margin: number): (R) -> ()
	return function(r: R)
		local hw, hd = w / 2, d / 2
		local hedge = rgb(72, 138, 78)
		if kind == "garden" then
			r:block(-hw, 0, -hd, hw, 0.16, hd, rgb(132, 190, 106), "Grass")
			r:block(-hw, 0.16, hd - 1.5, hw, 2.2, hd, hedge, "SmoothPlastic")
			-- (the front of a lot runs under the pavement, by up to three studs, so the hedge, its
			-- gate and the path start behind that, with a strip of grass in front)
			local front = -hd + 3.2
			r:block(-hw, 0.16, front, -hw + 1.5, 2.2, hd - 1.5, hedge, "SmoothPlastic")
			r:block(hw - 1.5, 0.16, front, hw, 2.2, hd - 1.5, hedge, "SmoothPlastic")
			r:block(-hw + 1.5, 0.16, front, -4, 2.2, front + 1.4, hedge, "SmoothPlastic")
			r:block(4, 0.16, front, hw - 1.5, 2.2, front + 1.4, hedge, "SmoothPlastic")
			r:block(-2.6, 0.16, -hd + 3.2, 2.6, 0.22, -hd + margin, rgb(232, 226, 214), "Pavement")
			for _, sx in { -1, 1 } do
				-- gate posts either side of the path, with a lamp on each
				gatePost(r, sx * 3.3, -hd + 3.9)
				-- round shrubs in the back corners (no trees this close to a road)
				r:ball(sx * (hw - 4), 1.6, hd - 4, 4, LEAF, "SmoothPlastic").name = "Leaf"
				r:ball(sx * (hw - 6.4), 1.1, hd - 3.4, 2.6, shade(LEAF, 1.14), "SmoothPlastic").name = "Leaf"
				-- a flower bed down each side of the building
				flowerBed(r, CFrame.new(sx * (hw - 3.3), 0.16, 0) * yaw(90))
			end
		else
			-- a paved forecourt: flower tubs at the corners and benches by the door
			for _, sx in { -1, 1 } do
				for _, sz in { -1, 1 } do
					tub(r, sx * (hw - 3), sz * (hd - 3), (sx + 1) * 45 + (sz + 1) * 90)
				end
				bench(r, sx * 8, -hd + 2, 180)
			end
		end
	end
end

-- A light street lamp: a foot, a slim pole with a collar, an arm with a brace, and a hood over
-- the lit head (the head is its own part, so it can glow).
local function lampPost(q: R)
	q:box(0, 0.25, 0, 0.5, 0.5, 0.5, DARK, "Metal")
	q:cyl(0, 0.62, 0, 0.24, 0.44, "y", DARK, "Metal")
	q:cyl(0, 4.8, 0, 8.4, 0.3, "y", DARK, "Metal")
	q:cyl(0, 2.6, 0, 0.18, 0.42, "y", DARK, "Metal")
	q:box(0, 8.82, -1.1, 0.22, 0.2, 2.6, DARK, "Metal")
	q:beam(Vector3.new(0, 7.7, -0.1), Vector3.new(0, 8.72, -1.5), 0.12, 0.12, DARK, "Metal")
	q:box(0, 8.8, -2.3, 1.4, 0.3, 1.4, DARK, "Metal")
	q:box(0, 8.6, -2.3, 1.2, 0.1, 1.2, shade(DARK, 1.3), "Metal")
end
M.streetLamp = function(r: R)
	stamp(r, "streetLamp", CFrame.identity, lampPost)
	local head = r:block(-0.5, 8.25, -2.8, 0.5, 8.55, -1.8, rgb(255, 236, 190), "SmoothPlastic")
	r:glow(head, 16, 1)
end

M.benchLite = function(r: R)
	bench(r, 0, 0, 0)
end

-- Downtown ------------------------------------------------------------------------------------------

M.hotel = CityModels.tower({
	w = 44,
	d = 30,
	floors = 14,
	wall = rgb(250, 236, 214),
	glass = rgb(120, 190, 236),
	trim = rgb(222, 196, 146),
	top = "sign",
	sign = rgb(206, 120, 96),
	kind = "hotel",
})
M.officeBlue =
	CityModels.tower({ w = 34, d = 30, floors = 11, wall = rgb(156, 172, 190), glass = rgb(176, 222, 250), top = "ac" })
M.officeTeal = CityModels.tower({
	w = 30,
	d = 30,
	floors = 16,
	wall = rgb(116, 170, 164),
	glass = rgb(190, 240, 236),
	top = "helipad",
})
M.skyTower = CityModels.tower({
	w = 38,
	d = 38,
	floors = 26,
	wall = rgb(140, 168, 204),
	glass = rgb(206, 236, 255),
	trim = WHITE,
	top = "spire",
	kind = "tower",
})
M.apartmentPeach = CityModels.tower({
	balconies = true,
	w = 32,
	d = 26,
	floors = 9,
	wall = rgb(240, 204, 178),
	glass = GLASS,
	trim = WHITE,
	top = "garden",
})
M.apartmentMint = CityModels.tower({
	w = 32,
	d = 26,
	floors = 8,
	wall = rgb(190, 220, 198),
	glass = GLASS,
	trim = WHITE,
	top = "ac",
	balconies = true,
})
M.apartmentLilac = CityModels.tower({
	balconies = true,
	w = 28,
	d = 26,
	floors = 10,
	wall = rgb(208, 198, 228),
	glass = GLASS,
	trim = WHITE,
	top = "garden",
})
M.shopCoral = CityModels.shop({
	kind = "bakery",
	w = 30,
	d = 22,
	floors = 3,
	wall = rgb(234, 178, 164),
	awning = rgb(250, 246, 236),
	sign = rgb(92, 140, 180),
})
M.shopYellow = CityModels.shop({
	kind = "grocer",
	w = 26,
	d = 22,
	floors = 2,
	wall = rgb(243, 223, 166),
	awning = rgb(84, 150, 108),
	sign = rgb(210, 116, 104),
})
M.shopBlue = CityModels.shop({
	kind = "books",
	w = 28,
	d = 22,
	floors = 3,
	wall = rgb(178, 204, 226),
	awning = rgb(224, 184, 104),
	sign = WHITE,
})
-- three more shops, so a street isn't the same four over and over
M.shopPink = CityModels.shop({
	kind = "clothes",
	w = 28,
	d = 22,
	floors = 2,
	wall = rgb(238, 198, 204),
	awning = rgb(140, 118, 176),
	sign = rgb(140, 118, 176),
})
M.shopOrange = CityModels.shop({
	kind = "cafe",
	w = 30,
	d = 22,
	floors = 3,
	wall = rgb(240, 202, 166),
	awning = rgb(112, 82, 66),
	sign = rgb(112, 82, 66),
})
M.shopLilac = CityModels.shop({
	kind = "toys",
	w = 26,
	d = 22,
	floors = 2,
	wall = rgb(210, 200, 230),
	awning = rgb(226, 190, 112),
	sign = rgb(204, 116, 140),
})
M.shopMint = CityModels.shop({
	kind = "flowers",
	w = 24,
	d = 22,
	floors = 2,
	wall = rgb(188, 220, 200),
	awning = rgb(210, 122, 144),
	sign = rgb(224, 184, 104),
})
M.deptStore = CityModels.shop({
	kind = "department",
	w = 70,
	d = 40,
	floors = 3,
	wall = rgb(246, 240, 226),
	awning = rgb(200, 104, 96),
	cols = 10,
	sign = rgb(200, 104, 96),
})

M.cinema = function(r: R)
	local w, d, h = 56, 40, 14
	local wall = rgb(144, 118, 170)
	local trim = rgb(226, 214, 236)
	-- the hall inside: rows of seats, the screen, popcorn by the door
	local box = Interiors.shell(r, {
		w = w,
		d = d,
		h = h,
		wall = wall,
		mat = "SmoothPlastic",
		windows = false,
		doorW = 5,
		door = rgb(226, 192, 116),
		floor = rgb(96, 70, 120),
		floorMat = "Fabric",
	})
	Interiors.fill(r, "cinema", box, wall)
	-- glass poster cases either side of the doors
	for _, sx in { -1, 1 } do
		r:block(sx * 10 - 3, 1.4, -d / 2 - 0.2, sx * 10 + 3, 6, -d / 2, rgb(224, 186, 110), "SmoothPlastic")
		local poster = r:block(
			sx * 10 - 2.6,
			1.8,
			-d / 2 - 0.3,
			sx * 10 + 2.6,
			5.6,
			-d / 2 - 0.2,
			if sx < 0 then rgb(210, 120, 126) else rgb(110, 156, 200),
			"SmoothPlastic"
		)
		advert(poster, "Front", "film")
	end
	-- the marquee over the doors, lit: the cinema's name and what's on
	r:glow(r:block(-18, 7.6, -d / 2 - 4, 18, 10.8, -d / 2, rgb(255, 214, 90), "Neon"), 18, 1.2)
	sign(r:block(-17, 8, -d / 2 - 4.15, 17, 10.4, -d / 2 - 4, WHITE, "SmoothPlastic"), "cinema", "marquee", "Front")
	-- the film's name in lights: a row of bulbs along the marquee's lower edge
	for k = -8, 8 do
		r:glow(r:ball(k * 2, 7.7, -d / 2 - 4.1, 0.6, rgb(255, 250, 220), "SmoothPlastic"), 0)
	end
	-- a dark band over the marquee and under its edge, and rods up to the wall
	r:block(-18.2, 10.8, -d / 2 - 4.1, 18.2, 11.1, -d / 2, TRIM_DARK, "Metal")
	r:block(-18.2, 7.3, -d / 2 - 4.1, 18.2, 7.6, -d / 2, TRIM_DARK, "Metal")
	for _, sx in { -1, 1 } do
		r:beam(
			Vector3.new(sx * 14, 13.2, -d / 2),
			Vector3.new(sx * 14, 11.1, -d / 2 - 3.6),
			0.14,
			0.14,
			TRIM_DARK,
			"Metal"
		)
	end
	-- the tall sign blade on the corner
	local corner = r:block(w / 2 - 3, 7, -d / 2 - 2.5, w / 2 - 1.8, h + 8, -d / 2 + 0.5, rgb(255, 110, 120), "Neon")
	sign(r:glow(corner, 0), "cinema", "blade")
	-- poster frames
	for _, x in { -w / 2 + 4, w / 2 - 8 } do
		advert(r:block(x, 9.5, -d / 2 - 0.2, x + 4, 13, -d / 2, rgb(224, 186, 110), "SmoothPlastic"), "Front", "film")
	end
	-- pilasters up the front corners and down the sides, a band at the foot of the walls
	for _, sx in { -1, 1 } do
		r:block(sx * 27.4 - 0.6, 0, -d / 2 - 0.4, sx * 27.4 + 0.6, h, -d / 2, trim, "SmoothPlastic")
		r:block(sx * 18.9 - 0.5, 0, -d / 2 - 0.3, sx * 18.9 + 0.5, h, -d / 2, trim, "SmoothPlastic")
		local x1, x2 = math.min(sx * w / 2, sx * (w / 2 + 0.3)), math.max(sx * w / 2, sx * (w / 2 + 0.3))
		for _, z in { -14, -1, 12, 18.5 } do
			r:block(x1, 0, z - 0.6, x2, h, z + 0.6, trim, "SmoothPlastic")
		end
		r:block(
			math.min(sx * w / 2, sx * (w / 2 + 0.2)),
			0,
			-d / 2,
			math.max(sx * w / 2, sx * (w / 2 + 0.2)),
			1.2,
			d / 2,
			shade(wall, 0.8),
			"SmoothPlastic"
		)
	end
	r:block(-w / 2 - 0.4, h, -d / 2 - 0.4, w / 2 + 0.4, h + 1, d / 2 + 0.4, rgb(204, 178, 130), "SmoothPlastic")
	-- and its name on the roof, over a stepped crown on the front
	sign(roofBoard(r, 13, h + 1, 4, -d / 2 + 1.2, rgb(200, 110, 120)), "cinema", "roof", "Front")
	r:block(-24, h + 1, -d / 2 - 0.4, -15, h + 2.4, -d / 2 + 0.6, trim, "SmoothPlastic")
	r:block(15, h + 1, -d / 2 - 0.4, 24, h + 2.4, -d / 2 + 0.6, trim, "SmoothPlastic")
	r:block(-24, h + 2.4, -d / 2 - 0.4, -20, h + 3.6, -d / 2 + 0.6, trim, "SmoothPlastic")
	r:block(20, h + 2.4, -d / 2 - 0.4, 24, h + 3.6, -d / 2 + 0.6, trim, "SmoothPlastic")
	-- the projection room and the air units at the back of the roof
	r:block(-6, h + 1, d / 2 - 9, 6, h + 5, d / 2 - 3, shade(wall, 0.9), "SmoothPlastic")
	r:block(-6.3, h + 5, d / 2 - 9.3, 6.3, h + 5.3, d / 2 - 2.7, trim, "SmoothPlastic")
	stamp(r, "acUnit", CFrame.new(-16, h + 1, d / 2 - 6), acUnit, true)
	stamp(r, "acUnit", CFrame.new(16, h + 1, d / 2 - 6), acUnit, true)
	-- what's coming, big, down both side walls
	for _, sx in { -1, 1 } do
		for _, z in { -12, 2 } do
			local poster = r:block(sx * w / 2, 3, z, sx * (w / 2 + 0.2), 12, z + 8, rgb(224, 186, 110), "SmoothPlastic")
			advert(poster, if sx > 0 then "Right" else "Left", "film")
		end
	end
end

-- A gable roof with its ridge along x, centred on the origin: the gables in the wall's colour
-- (two wedges `w` wide from `eave` up `rise`, out `run` either side of the ridge) under two slabs
-- `t` thick that overhang them to x = +-(w / 2 + over) and stay inside z = +-run, then a cap
-- along the ridge and a fascia board under each eave. Returns the roof's height at a given z.
local function gableRoof(
	r: R,
	w: number,
	run: number,
	eave: number,
	rise: number,
	over: number,
	wall: Color3,
	wallMat: string,
	roof: Color3,
	roofMat: string,
	trim: Color3
): (number) -> number
	local t = 0.3
	r:wedge(CFrame.new(0, eave + rise / 2, -run / 2), w, rise, run, wall, wallMat)
	r:wedge(CFrame.new(0, eave + rise / 2, run / 2) * yaw(180), w, rise, run, wall, wallMat)
	local ridge = eave + rise
	local sin = rise / math.sqrt(rise * rise + run * run)
	local cos = run / math.sqrt(rise * rise + run * run)
	local z0 = run - t * sin
	local function y(z: number): number
		return ridge - rise * math.abs(z) / run
	end
	local hx = w / 2 + over
	for _, s in { -1, 1 } do
		for _, p in
			Geometry.quad(
				Vector3.new(-hx, ridge, 0),
				Vector3.new(hx, ridge, 0),
				Vector3.new(hx, y(z0), s * z0),
				Vector3.new(-hx, y(z0), s * z0),
				t,
				roof,
				roofMat,
				Vector3.yAxis
			)
		do
			r:add(p)
		end
		r:box(0, y(z0) - 0.22, s * (z0 - 0.08), 2 * hx - 0.1, 0.44, 0.16, trim, "SmoothPlastic")
	end
	r:box(0, ridge + t * cos, 0, 2 * hx - 0.1, 0.28, 2 * t * sin + 0.4, shade(roof, 0.8), roofMat)
	return y
end

-- A carriage's windows, doors, roof, stripes and wheels, round the middle of its floor; the
-- body itself (26 long, 7 tall and 9 wide) is a part of its own.
local function carriage(q: R, body: Color3)
	for _, s in { -1, 1 } do
		for i = 0, 5 do
			q:box(-9 + i * 3.6, 4.5, s * 4.53, 2.6, 1.8, 0.06, GLASS_CAR)
		end
		for _, x in { -11.4, 11.4 } do
			q:box(x, 3.0, s * 4.53, 1.3, 5.2, 0.06, shade(body, 0.8))
		end
		q:box(0, 2.9, s * 4.52, 21.2, 0.3, 0.04, WHITE)
		q:box(s * 8, 0, 0, 5, 0.8, 7, TYRE)
		q:box(s * 13.3, 3.5, 0, 0.6, 5, 3, TRIM_DARK)
	end
	q:box(0, 7.25, 0, 26.2, 0.5, 9.2, WHITE)
end

M.station = function(r: R)
	local w, d, h = 80, 22, 9
	local wall = rgb(250, 240, 222)
	-- the hall inside: the ticket office, benches, the board of departures
	local box = Interiors.shell(r, {
		w = w,
		d = d,
		h = h,
		wall = wall,
		mat = "SmoothPlastic",
		doorW = 6,
		door = rgb(110, 140, 168),
		floor = rgb(226, 222, 214),
		floorMat = "Marble",
	})
	Interiors.fill(r, "station", box, wall)
	-- the ceiling and the long pitched roof over it, with a clock gable over the doors
	local roof = rgb(110, 140, 168)
	r:block(-w / 2 - 1, h, -d / 2 - 1, w / 2 + 1, h + 0.5, d / 2 + 1, WHITE, "SmoothPlastic")
	gableRoof(r, w, d / 2 + 1, h + 0.5, 5, 2, wall, "SmoothPlastic", roof, "Slate", WHITE)
	r:block(-5, h + 0.5, -d / 2 - 1.6, 5, h + 8, -d / 2 - 0.6, wall, "SmoothPlastic")
	r:block(-5.3, h + 8, -d / 2 - 1.8, 5.3, h + 8.3, -d / 2 - 0.4, WHITE, "SmoothPlastic")
	r:wedge(CFrame.new(-2.65, h + 9.3, -d / 2 - 1.1) * yaw(90), 1.4, 2, 5.3, roof, "Slate")
	r:wedge(CFrame.new(2.65, h + 9.3, -d / 2 - 1.1) * yaw(-90), 1.4, 2, 5.3, roof, "Slate")
	r:cyl(0, h + 4.6, -d / 2 - 1.8, 0.6, 6, "z", WHITE, "SmoothPlastic")
	r:cyl(0, h + 4.6, -d / 2 - 2.15, 0.2, 4.6, "z", DARK, "SmoothPlastic")
	r:block(-0.15, h + 4.6, -d / 2 - 2.3, 0.15, h + 6.4, -d / 2 - 2.15, WHITE, "SmoothPlastic")
	r:block(-0.15, h + 4.45, -d / 2 - 2.3, 1.3, h + 4.75, -d / 2 - 2.15, WHITE, "SmoothPlastic")
	-- the station's name over the doors, and twice along the platform side
	sign(
		r:glow(r:block(-10, 7.5, -d / 2 - 0.35, 10, 8.9, -d / 2, roof, "SmoothPlastic"), 0),
		"station",
		"fascia",
		"Front"
	)
	for _, sx in { -1, 1 } do
		local board = r:block(sx * 22 - 8, 6.2, d / 2, sx * 22 + 8, 8.2, d / 2 + 0.3, roof, "SmoothPlastic")
		sign(r:glow(board, 0), "station", "fascia", "Back")
	end
	-- posters to read while the train is late
	for _, x in { -6, 0, 6 } do
		advert(r:block(x - 2, 2.3, d / 2, x + 2, 7.3, d / 2 + 0.2, DARK, "SmoothPlastic"), "Back")
	end
	-- and in big letters on two posts over the ridge, read from the street and from the platform
	sign(r:glow(r:block(-15, h + 8.2, -0.2, 15, h + 11.4, 0.2, roof, "SmoothPlastic"), 0), "station", "roof")
	for _, sx in { -1, 1 } do
		r:block(sx * 12 - 0.25, h + 5, -0.25, sx * 12 + 0.25, h + 8.2, 0.25, DARK, "Metal")
	end
	-- the platform under a canopy on posts, a lamp in every other bay
	r:block(-w / 2 - 10, 0, d / 2, w / 2 + 10, 1.2, d / 2 + 12, STONE, "SmoothPlastic")
	r:block(-w / 2 - 10, 1.2, d / 2 + 11, w / 2 + 10, 1.3, d / 2 + 12, rgb(232, 204, 120), "SmoothPlastic")
	for i = 0, 7 do
		local x = -35 + i * 10
		stamp(r, "platformCanopy", CFrame.new(x, 1.2, d / 2), function(q)
			q:cyl(0, 3.5, 7, 7, 0.4, "y", TRIM_DARK, "Metal")
			q:box(0, 7.15, 5.1, 10, 0.3, 10.2, roof, "Metal")
			q:box(0, 6.7, 10.15, 10, 0.6, 0.1, WHITE, "Metal")
			q:beam(Vector3.new(0, 5.6, 7), Vector3.new(0, 7.0, 4.2), 0.16, 0.16, TRIM_DARK, "Metal")
			q:beam(Vector3.new(0, 5.6, 7), Vector3.new(0, 7.0, 9.6), 0.16, 0.16, TRIM_DARK, "Metal")
			q:box(0, 6.9, 7, 0.9, 0.2, 0.9, TRIM_DARK, "Metal")
		end)
		if i % 2 == 0 then
			r:glow(
				r:block(x + 2.15, 7.95, d / 2 + 4.65, x + 2.85, 8.15, d / 2 + 5.35, rgb(255, 236, 190), "SmoothPlastic"),
				14,
				0.9
			)
		end
	end
	-- the line behind: ballast, sleepers and rails, with a train waiting
	r:block(-w / 2 - 30, 0, d / 2 + 14, w / 2 + 30, 0.1, d / 2 + 22, rgb(170, 164, 156), "Slate")
	for i = 0, 6 do
		stamp(r, "sleepers", CFrame.new(-60 + i * 20, 0.1, d / 2 + 18), function(q)
			for k = 0, 13 do
				q:box(-9.3 + k * (18.6 / 13), 0.12, 0, 0.9, 0.24, 7.6, rgb(120, 96, 78), "Wood")
			end
		end)
	end
	for _, z in { d / 2 + 15.5, d / 2 + 20.5 } do
		r:block(-w / 2 - 30, 0.1, z - 0.3, w / 2 + 30, 0.6, z + 0.3, METAL, "Metal")
	end
	local body = rgb(88, 134, 180)
	for k = 0, 2 do
		local x = -40 + k * 30
		r:block(x - 13, 1, d / 2 + 13.5, x + 13, 8, d / 2 + 22.5, body, "SmoothPlastic")
		stamp(r, "carriage", CFrame.new(x, 1, d / 2 + 18), function(q)
			carriage(q, body)
		end)
	end
	-- the engine's nose on the front carriage, with its lamps
	r:wedge(CFrame.new(35.5, 4.5, d / 2 + 18) * yaw(-90), 9, 7, 5, body, "SmoothPlastic")
	for _, sz in { -2.6, 2.6 } do
		r:glow(
			r:block(
				36.9,
				1.3,
				d / 2 + 18 + sz - 0.5,
				37.6,
				1.8,
				d / 2 + 18 + sz + 0.5,
				rgb(255, 240, 200),
				"SmoothPlastic"
			),
			0
		)
	end
	-- benches on the platform
	for _, x in { -20, 0, 20 } do
		bench(r, x, d / 2 + 5, 180)
	end
end

-- A pocket park on the market lane, across from the square: a lawn in a kerb, open to the lane
-- (local +Z), with a path along its front, a few trees, flower beds and benches. (The park that
-- had this whole block was cut down to it when the street buildings went up.)
M.pocketPark = function(r: R)
	r:block(-25, 0, -8.5, 25, 0.3, 8.5, rgb(136, 190, 108), "Grass")
	r:block(-25.5, 0, -9, 25.5, 0.42, -8.5, STONE, "Concrete")
	r:block(-25.5, 0, -8.5, -25, 0.42, 8.5, STONE, "Concrete")
	r:block(25, 0, -8.5, 25.5, 0.42, 8.5, STONE, "Concrete")
	-- (the paths sit sunk into the lawn, so their tops are the only ones that show)
	r:block(-25, 0.24, 3, 25, 0.36, 6, rgb(236, 226, 204), "Pavement")
	r:block(-2.5, 0.24, 6, 2.5, 0.36, 8.45, rgb(236, 226, 204), "Pavement")
	for _, p in { { -19, -3.5, 1.05 }, { -8, -4.5, 0.95 }, { 8, -4.5, 1 }, { 19, -3.5, 1.1 } } do
		lowTree(r, p[1], 0.3, p[2], p[3])
	end
	for i, x in { -13.5, 0, 13.5 } do
		flowerBed(r, CFrame.new(x, 0.3, 0) * yaw(if i == 2 then 180 else 0))
	end
	for _, x in { -16, -6, 6, 16 } do
		bench(r, x, 7.2, 180)
		local last = r.prims[#r.prims]
		last.cf = CFrame.new(0, 0.36, 0) * last.cf
	end
	-- two lamps over the walk
	for _, x in { -11, 11 } do
		stamp(r, "streetLamp", CFrame.new(x, 0.3, 7.6), lampPost)
		r:glow(r:block(x - 0.5, 8.55, 4.8, x + 0.5, 8.85, 5.8, rgb(255, 236, 190), "SmoothPlastic"), 16, 1)
	end
end

-- A car park: grey tarmac and white bay lines.
M.carPark = function(r: R)
	r:block(-50, 0, -30, 50, 0.22, 30, rgb(140, 146, 158), "SmoothPlastic")
	for x = -45, 45, 10 do
		for _, z in { -28, 10 } do
			r:block(x - 0.2, 0.19, z, x + 0.2, 0.26, z + 18, WHITE, "SmoothPlastic")
		end
	end
	-- a billboard at the far end, its legs on two of the bay lines, an advert on each side
	advert(r:block(-9, 5, 27.8, 9, 12, 28.2, DARK, "SmoothPlastic"))
	for _, x in { -5, 5 } do
		r:block(x - 0.3, 0.2, 27.7, x + 0.3, 5, 28.3, DARK, "Metal")
	end
end

-- The civic quarter -------------------------------------------------------------------------------

M.school = function(r: R)
	local wall = rgb(240, 218, 174)
	local roof = rgb(194, 126, 99)
	CityModels.shop({
		kind = "school",
		w = 70,
		d = 24,
		floors = 2,
		wall = wall,
		awning = rgb(96, 138, 176),
		cols = 10,
		sign = rgb(96, 138, 176),
		ads = false,
	})(r)
	-- a clock tower over the middle: corner pilasters, the clock, an open belfry with its bell
	-- between four posts, and a pointed roof with a vane
	r:block(-6, 13.4, -10, 6, 24, 2, wall, "SmoothPlastic")
	for _, sx in { -1, 1 } do
		for _, z in { -10, 2 } do
			r:block(sx * 6 - 0.5, 13.4, z - 0.5, sx * 6 + 0.5, 24, z + 0.5, WHITE, "SmoothPlastic")
		end
	end
	r:block(-6.6, 24, -10.6, 6.6, 24.5, 2.6, WHITE, "SmoothPlastic")
	r:cyl(0, 20, -10.2, 0.4, 6, "z", WHITE, "SmoothPlastic")
	r:cyl(0, 20, -10.45, 0.2, 4.4, "z", DARK, "SmoothPlastic")
	r:block(-0.15, 20, -10.6, 0.15, 22, -10.45, WHITE, "SmoothPlastic")
	r:block(-0.15, 19.85, -10.6, 1.4, 20.15, -10.45, WHITE, "SmoothPlastic")
	for _, sx in { -1, 1 } do
		for _, z in { -9, 1 } do
			r:block(sx * 5 - 0.6, 24.5, z - 0.6, sx * 5 + 0.6, 28, z + 0.6, WHITE, "SmoothPlastic")
		end
	end
	r:cyl(0, 26.4, -4, 0.3, 0.5, "y", DARK, "Metal")
	r:cone(0, 25.6, -4, 1.6, 2.4, rgb(214, 176, 96), "Metal")
	r:block(-6, 28, -10, 6, 28.4, 2, WHITE, "SmoothPlastic")
	local apex = Vector3.new(0, 32.2, -4)
	local corners = {
		Vector3.new(-6.4, 28.4, -10.4),
		Vector3.new(6.4, 28.4, -10.4),
		Vector3.new(6.4, 28.4, 2.4),
		Vector3.new(-6.4, 28.4, 2.4),
	}
	for k = 1, 4 do
		r:tri(corners[k], corners[k % 4 + 1], apex, 0.25, if k % 2 == 0 then roof else shade(roof, 0.88), "Slate")
	end
	r:cyl(0, 33.2, -4, 2, 0.14, "y", DARK, "Metal")
	r:block(0, 33.6, -4.04, 1.2, 33.9, -3.96, DARK, "Metal")
	-- a flag on the roof by the far end
	r:cyl(-30, 18.4, -9.5, 10, 0.2, "y", METAL, "Metal")
	r:block(-29.9, 21.6, -9.55, -27.4, 23.2, -9.45, rgb(96, 138, 176), "Fabric")
end

-- A sports field: a pitch with lines and goals, a running track round it and seats along a side.
M.sportsField = function(r: R)
	r:block(-60, 0, -36, 60, 0.25, 36, rgb(200, 134, 112), "SmoothPlastic")
	r:block(-50, 0.25, -28, 50, 0.3, 28, rgb(132, 184, 104), "Grass")
	-- the markings, sunk into the grass so only their tops show: the touch lines, halfway, the
	-- centre circle and a box at each end
	drawAt(r, CFrame.new(0, 0.3, 0), function(q)
		for _, line in
			{
				{ -48, -26.4, 48, -26 },
				{ -48, 26, 48, 26.4 },
				{ -48.4, -26.4, -48, 26.4 },
				{ 48, -26.4, 48.4, 26.4 },
				{ -0.2, -26, 0.2, 26 },
				{ -48, -10.2, -40, -9.8 },
				{ -48, 9.8, -40, 10.2 },
				{ -40.2, -10.2, -39.8, 10.2 },
				{ 40, -10.2, 48, -9.8 },
				{ 40, 9.8, 48, 10.2 },
				{ 39.8, -10.2, 40.2, 10.2 },
			}
		do
			q:box(
				(line[1] + line[3]) / 2,
				0,
				(line[2] + line[4]) / 2,
				line[3] - line[1],
				0.08,
				line[4] - line[2],
				WHITE
			)
		end
		for k = 0, 11 do
			local a = (k + 0.5) / 12 * math.pi * 2
			q:boxAt(CFrame.new(math.cos(a) * 6, 0, math.sin(a) * 6) * CFrame.Angles(0, -a, 0), 0.4, 0.08, 3.2, WHITE)
		end
	end, false)
	-- a goal at each end: posts and a bar, a frame behind and the strings of the net
	for _, sx in { -1, 1 } do
		drawAt(r, CFrame.new(sx * 47, 0.3, 0) * yaw(if sx > 0 then 0 else 180), function(q)
			for _, sz in { -1, 1 } do
				q:box(0, 2.15, sz * 4.7, 0.3, 4.3, 0.3, WHITE)
				q:box(2.4, 1.6, sz * 4.7, 0.16, 3.2, 0.16, WHITE)
				q:beam(Vector3.new(0, 4.2, sz * 4.7), Vector3.new(2.4, 3.2, sz * 4.7), 0.12, 0.12, WHITE)
				for _, y in { 1.1, 2.2 } do
					q:box(1.2, y, sz * 4.7, 2.4, 0.05, 0.05, rgb(226, 230, 234))
				end
			end
			q:box(0, 4.45, 0, 0.3, 0.3, 9.7, WHITE)
			q:box(2.4, 3.2, 0, 0.16, 0.16, 9.4, WHITE)
			for i = -3, 3 do
				q:box(2.42, 1.6, i * 1.3, 0.05, 3.2, 0.05, rgb(226, 230, 234))
			end
			for _, y in { 0.9, 1.8, 2.7 } do
				q:box(2.42, y, 0, 0.05, 0.05, 9.4, rgb(226, 230, 234))
			end
		end, true)
	end
	-- flags in the corners
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			r:cyl(sx * 48.2, 1.3, sz * 26.2, 2, 0.1, "y", WHITE, "Metal")
			r:block(
				sx * 48.2,
				1.8,
				sz * 26.2 - 0.02,
				sx * 48.2 + sx * 0.8,
				2.3,
				sz * 26.2 + 0.02,
				rgb(224, 128, 102),
				"Fabric"
			)
		end
	end
	-- the stand: three tiers with a row of seats on each, steps up the aisles and a rail behind
	for k = 0, 2 do
		r:block(
			-36,
			0,
			38 + k * 2,
			36,
			1 + k * 1.2,
			40 + k * 2,
			if k % 2 == 0 then rgb(206, 202, 196) else rgb(220, 216, 208),
			"Concrete"
		)
		r:block(
			-35.6,
			1 + k * 1.2,
			39.2 + k * 2,
			35.6,
			1.5 + k * 1.2,
			39.9 + k * 2,
			if k % 2 == 0 then rgb(96, 138, 176) else WHITE,
			"SmoothPlastic"
		)
	end
	for _, x in { -12, 12 } do
		for k = 0, 2 do
			r:block(x - 1, 0, 37.4 + k * 2, x + 1, 0.6 + k * 1.2, 38 + k * 2, rgb(190, 186, 180), "Concrete")
		end
	end
	railing(r, Vector3.new(-35.8, 3.4, 43.85), Vector3.new(35.8, 3.4, 43.85), 1.6, METAL)
end

M.clinic = function(r: R)
	local teal = rgb(92, 158, 148)
	local red = rgb(214, 96, 96)
	CityModels.shop({
		kind = "clinic",
		w = 46,
		d = 28,
		floors = 3,
		wall = WHITE,
		awning = teal,
		cols = 7,
		ads = false,
	})(r)
	-- the cross on the front
	r:block(-1.6, 18.6, -14.6, 1.6, 24.6, -14.2, red, "SmoothPlastic")
	r:block(-4.6, 20, -14.6, 4.6, 23.2, -14.2, red, "SmoothPlastic")
	-- a canopy over the ambulance bay on the side, on two posts, with the ambulance under it
	r:block(23, 8.4, -12, 33, 9, 4, teal, "SmoothPlastic")
	r:block(23, 8.1, -12, 33, 8.4, -11.7, WHITE, "SmoothPlastic")
	for _, z in { -11, 3 } do
		r:block(32.4, 0, z - 0.3, 33, 8.4, z + 0.3, WHITE, "SmoothPlastic")
	end
	-- the ambulance: a cab with its glass and a tall box behind, a red band and crosses, lights
	local f = CFrame.new(28, 0.1, -4)
	r:boxAt(f * CFrame.new(0, 1.4, -2.95), 4.2, 1.6, 3.1, WHITE, "SmoothPlastic")
	r:boxAt(f * CFrame.new(0, 3.2, -2.05), 4.0, 2.0, 1.3, WHITE, "SmoothPlastic")
	r:boxAt(f * CFrame.new(0, 3.0, 1.525), 4.2, 4.8, 5.85, WHITE, "SmoothPlastic")
	drawAt(r, f, function(q)
		for _, sx in { -1, 1 } do
			for _, wz in { -2.85, 2.85 } do
				q:cyl(sx * 1.85, 0.75, wz, 0.6, 1.5, "x", TYRE)
				q:cyl(sx * 2.2, 0.75, wz, 0.1, 0.72, "x", rgb(200, 204, 212))
			end
			q:box(sx * 2.04, 3.25, -2.05, 0.08, 1.2, 1.0, GLASS_CAR)
			q:box(sx * 2.13, 2.6, 1.525, 0.06, 0.5, 5.8, red)
			q:box(sx * 2.15, 4.1, 2.0, 0.06, 1.2, 0.4, red)
			q:box(sx * 2.15, 4.1, 2.0, 0.06, 0.4, 1.2, red)
			q:box(sx * 1.45, 1.6, -4.53, 0.8, 0.34, 0.08, rgb(250, 240, 208))
		end
		q:wedge(CFrame.new(0, 3.2, -3.3), 3.8, 2.0, 1.2, GLASS_CAR)
		q:box(0, 0.85, -4.43, 4.1, 0.36, 0.28, rgb(188, 192, 200))
		q:box(0, 0.85, 4.43, 4.1, 0.36, 0.28, rgb(188, 192, 200))
		q:box(0, 3.0, 4.47, 0.06, 4.4, 0.04, rgb(200, 204, 212))
	end)
	r:glow(r:boxAt(f * CFrame.new(0, 4.35, -2.05), 2.4, 0.3, 0.6, rgb(90, 160, 255), "Neon"), 0)
	r:glow(r:boxAt(f * CFrame.new(0, 5.5, 4.2), 3.0, 0.2, 0.3, red, "Neon"), 0)
end

-- A tall window's stone dressing in face space, round a pane 3.2 wide and 7.6 tall standing on
-- y = 0 (the pane is its own part, to light up): jambs, a sill over an apron, a head under a
-- hood moulding, a keystone, and glazing bars.
local function tallWindow(q: R, stone: Color3)
	for _, s in { -1, 1 } do
		q:box(s * 1.85, 3.8, -0.15, 0.5, 8.0, 0.3, stone)
	end
	q:box(0, -0.12, -0.25, 4.4, 0.24, 0.5, stone)
	q:box(0, -0.47, -0.1, 3.6, 0.46, 0.2, stone)
	q:box(0, 7.85, -0.18, 4.2, 0.5, 0.36, stone)
	q:box(0, 8.25, -0.3, 4.8, 0.3, 0.6, stone)
	q:box(0, 8.0, -0.35, 0.7, 1.1, 0.7, stone)
	for _, x in { -0.55, 0.55 } do
		q:box(x, 3.8, -0.17, 0.1, 7.6, 0.06, stone)
	end
	for _, y in { 1.9, 3.8, 5.7 } do
		q:box(0, y, -0.17, 3.2, 0.1, 0.06, stone)
	end
end

-- A classical column on its terrace, 13.6 tall: a plinth, a round base, the shaft, a necking
-- ring, the round of the capital and the square slab on top.
local function column(q: R, stone: Color3)
	q:box(0, 0.25, 0, 3.0, 0.5, 3.0, stone, "Marble")
	q:cyl(0, 0.68, 0, 0.36, 2.7, "y", stone, "Marble")
	q:cyl(0, 6.9, 0, 12.1, 2.1, "y", stone, "Marble")
	q:cyl(0, 12.2, 0, 0.3, 2.35, "y", stone, "Marble")
	q:cyl(0, 12.65, 0, 0.4, 2.8, "y", stone, "Marble")
	q:box(0, 13.25, 0, 3.0, 0.35, 3.0, stone, "Marble")
end

M.library = function(r: R)
	local wall = rgb(206, 144, 120)
	local stone = rgb(236, 228, 212)
	-- inside: bookcases round the walls, reading tables, the desk by the door
	local box = Interiors.shell(r, {
		w = 56,
		d = 28,
		h = 12,
		wall = wall,
		mat = "Brick",
		windows = false,
		doorW = 5,
		door = DOOR,
		floor = rgb(196, 154, 108),
	})
	Interiors.fill(r, "library", box, wall)
	-- tall windows in stone dressings, four along the front and two down each side
	local function window(at: CFrame)
		lit(r, r:boxAt(at * CFrame.new(0, 3.8, -0.075), 3.2, 7.6, 0.15, GLASS, "Glass"))
		stamp(r, "tallWindow", at, function(q)
			tallWindow(q, stone)
		end)
	end
	for _, x in { -22, -13.2, 13.2, 22 } do
		window(CFrame.new(x, 2.4, -14))
	end
	for _, z in { -6, 6 } do
		window(CFrame.new(28, 2.4, z) * yaw(-90))
		window(CFrame.new(-28, 2.4, z) * yaw(90))
	end
	-- a stone plinth round the foot of the walls
	r:block(-28.2, 0, -14.2, -8.4, 1.6, -14, stone, "Concrete")
	r:block(8.4, 0, -14.2, 28.2, 1.6, -14, stone, "Concrete")
	for _, sx in { -1, 1 } do
		r:block(math.min(sx * 28, sx * 28.2), 0, -14.2, math.max(sx * 28, sx * 28.2), 1.6, 14.2, stone, "Concrete")
	end
	-- the cornice, and a brick parapet over it
	r:block(-29, 12, -15, 29, 13.2, 15, WHITE, "SmoothPlastic")
	r:block(-28.6, 13.2, -14.6, 28.6, 14.1, -14, wall, "Brick")
	r:block(-28.6, 13.2, 14, 28.6, 14.1, 14.6, wall, "Brick")
	for _, sx in { -1, 1 } do
		r:block(math.min(sx * 28, sx * 28.6), 13.2, -14, math.max(sx * 28, sx * 28.6), 14.1, 14, wall, "Brick")
	end
	-- the way in: pilasters either side with a lantern on each, a broad step, the name over the
	-- door on a stone band, and a pediment over it all above the cornice
	r:block(-6.5, 0, -15.3, 6.5, 0.34, -14, stone, "Concrete")
	for _, sx in { -1, 1 } do
		local px = sx * 7.6
		r:block(px - 0.8, 0, -14.6, px + 0.8, 0.8, -14, stone, "Concrete")
		r:block(px - 0.6, 0.8, -14.4, px + 0.6, 12, -14, stone, "Concrete")
		r:block(px - 0.12, 6.2, -14.9, px + 0.12, 6.4, -14.4, DARK, "Metal")
		r:glow(r:block(px - 0.3, 5.3, -15.2, px + 0.3, 6.2, -14.6, rgb(255, 228, 170), "SmoothPlastic"), 0)
		r:block(px - 0.38, 6.2, -15.28, px + 0.38, 6.34, -14.52, DARK, "Metal")
	end
	r:block(-7, 8.4, -14.5, 7, 10.4, -14, WHITE, "SmoothPlastic")
	sign(
		r:block(-6.5, 8.65, -14.62, 6.5, 10.15, -14.5, shade(wall, 0.7), "SmoothPlastic"),
		"library",
		"fascia",
		"Front"
	)
	r:block(-8.2, 13.2, -15, 8.2, 14.6, -13.6, stone, "Concrete")
	r:wedge(CFrame.new(-4.1, 15.6, -14.3) * yaw(90), 1.4, 2, 8.2, stone, "Concrete")
	r:wedge(CFrame.new(4.1, 15.6, -14.3) * yaw(-90), 1.4, 2, 8.2, stone, "Concrete")
	-- a glass lantern along the middle of the roof, over the reading room
	r:glass(-10, 13.2, -4, 10, 14.8, 4)
	for _, sz in { -1, 1 } do
		r:block(-10.2, 14.8, sz * 4 - 0.2, 10.2, 15.0, sz * 4 + 0.2, TRIM_DARK, "Metal")
		r:block(-10.2, 13.2, sz * 4 - 0.15, 10.2, 13.5, sz * 4 + 0.15, TRIM_DARK, "Metal")
	end
	for _, x in { -10, -5, 0, 5, 10 } do
		r:block(x - 0.12, 13.5, -4.2, x + 0.12, 15.0, 4.2, TRIM_DARK, "Metal")
	end
end

M.museum = function(r: R)
	local stone = rgb(244, 240, 230)
	local shadow = shade(stone, 0.9)
	-- inside: things on plinths, paintings round the walls, old bones in the middle
	placed(r, CFrame.new(0, 0, 1), function()
		local box = Interiors.shell(r, {
			w = 60,
			d = 30,
			h = 13,
			wall = stone,
			mat = "Marble",
			windows = false,
			doorW = 6,
			doorH = 8,
			door = DOOR,
			floor = rgb(214, 206, 190),
			floorMat = "Marble",
		})
		Interiors.fill(r, "museum", box, stone)
	end)
	r:block(-30.4, 13, -14.4, 30.4, 13.6, 16.4, stone, "Marble")
	-- a low terrace of steps, then six columns
	for k = 0, 2 do
		r:block(-24 - k, 0, -24 - k * 1.2, 24 + k, 0.34 - k * 0.12, -14, shade(stone, 0.95), "SmoothPlastic")
	end
	for x = -20, 20, 8 do
		stamp(r, "museumColumn", CFrame.new(x, 0.3, -20), function(q)
			column(q, stone)
		end, true)
	end
	-- the beam over them in two bands under a cornice, and the pediment with a raking cornice
	-- up each side and a round window in its middle
	r:block(-24, 13.9, -22, 24, 14.45, -14, shadow, "Marble")
	r:block(-24, 14.45, -22, 24, 15, -14, stone, "SmoothPlastic")
	r:block(-24.4, 15, -22.4, 24.4, 15.35, -14, stone, "Marble")
	r:wedge(CFrame.new(-12, 17.5, -18) * CFrame.Angles(0, math.rad(90), 0), 8, 5, 24, stone, "Marble")
	r:wedge(CFrame.new(12, 17.5, -18) * CFrame.Angles(0, math.rad(-90), 0), 8, 5, 24, stone, "Marble")
	for _, sx in { -1, 1 } do
		r:beam(Vector3.new(sx * 24.4, 15.35, -22.2), Vector3.new(0, 20.45, -22.2), 0.5, 0.4, stone, "Marble")
	end
	r:cyl(0, 17.2, -22.08, 0.16, 2.6, "z", shadow, "Marble")
	r:cyl(0, 17.2, -22.18, 0.06, 1.8, "z", rgb(150, 170, 186), "Glass")
	-- banners down the wall either side, and one strung across the columns over the way in
	for _, x in { -25, 25 } do
		sign(r:block(x - 1.4, 4, -14.3, x + 1.4, 11, -14.1, rgb(196, 100, 94), "Fabric"), "museum", "blade", "Front")
	end
	sign(r:block(-11, 9.6, -21.45, 11, 12.4, -21.25, rgb(196, 100, 94), "Fabric"), "museum", "fascia", "Front")
	-- pilasters down the sides between a plinth and a frieze
	for _, sx in { -1, 1 } do
		local x1, x2 = math.min(sx * 30, sx * 30.25), math.max(sx * 30, sx * 30.25)
		r:block(x1, 0, -14, x2, 1.4, 16, shadow, "Marble")
		r:block(x1, 11.4, -14, x2, 12.4, 16, shadow, "Marble")
		for _, z in { -9, -1.5, 6, 13.5 } do
			r:block(
				math.min(sx * 30, sx * 30.4),
				1.4,
				z - 0.6,
				math.max(sx * 30, sx * 30.4),
				11.4,
				z + 0.6,
				stone,
				"Marble"
			)
		end
	end
	-- a dome over the middle hall on a drum, with a lantern on top
	r:cyl(0, 14.6, 3, 2, 13, "y", stone, "Marble")
	r:cyl(0, 15.7, 3, 0.3, 13.6, "y", shadow, "Marble")
	r:lump(CFrame.new(0, 15.85, 3), 12.4, 7.4, 12.4, rgb(150, 178, 176), "Metal")
	r:cyl(0, 20, 3, 1.3, 1.8, "y", stone, "Marble")
	r:cone(0, 21.15, 3, 1, 2.2, rgb(150, 178, 176), "Metal")
end

-- An engine house's folding door in face space, 11 wide and 7.8 tall on y = 0.2: the leaves in
-- panelled rows with a row of windows, inside a frame and under a head.
local function bayDoor(q: R)
	local leaf = rgb(240, 236, 228)
	q:box(0, 4.1, -0.1, 10.6, 7.8, 0.2, leaf)
	for _, y in { 1.6, 3.3, 6.5 } do
		q:box(0, y, -0.23, 10.6, 0.12, 0.06, shade(leaf, 0.82))
	end
	for i = 0, 3 do
		q:box(-3.9 + i * 2.6, 4.9, -0.23, 2.1, 1.0, 0.06, PANE)
	end
	for _, x in { -2.65, 0, 2.65 } do
		q:box(x, 4.1, -0.24, 0.1, 7.8, 0.08, shade(leaf, 0.82))
	end
	for _, s in { -1, 1 } do
		q:box(s * 5.55, 4.1, -0.25, 0.5, 8.2, 0.5, WHITE)
	end
	q:box(0, 8.25, -0.25, 11.6, 0.5, 0.5, WHITE)
end

-- A ladder in its own frame: two rails along z and rungs across, `long` studs from z = 0.
local function ladder(q: R, long: number, wide: number, color: Color3)
	for _, s in { -1, 1 } do
		q:box(s * wide / 2, 0, long / 2, 0.2, 0.25, long, color)
	end
	local n = math.floor(long / 1.2)
	for i = 1, n - 1 do
		q:box(0, 0, i * long / n, wide, 0.12, 0.12, color)
	end
end

M.fireStation = function(r: R)
	local red = rgb(196, 106, 92)
	local stone = rgb(232, 226, 214)
	r:block(-26, 0, -14, 26, 11, 14, red, "Brick")
	-- three bays of folding doors, stone piers between them and a plinth along the front
	for k = -1, 1 do
		stamp(r, "bayDoor", CFrame.new(k * 15, 0.2, -14), bayDoor)
	end
	for _, x in { -26, -7.5, 7.5, 26 } do
		r:block(x - 1, 0, -14.3, x + 1, 9.2, -14, stone, "Concrete")
	end
	r:block(-27, 11, -15, 27, 12, 15, WHITE, "SmoothPlastic")
	r:block(-26, 8.9, -14.25, 26, 9.2, -14, stone, "Concrete")
	-- its name over the bay doors, under a stepped gable with the station's lamp
	sign(r:glow(r:block(-12, 8.5, -14.35, 12, 10.5, -14, WHITE, "SmoothPlastic"), 0), "fire", "fascia", "Front")
	r:block(-9, 12, -14.6, 9, 13.6, -13.6, red, "Brick")
	r:block(-5, 13.6, -14.6, 5, 15, -13.6, red, "Brick")
	r:block(-9.3, 13.6, -14.8, 9.3, 13.85, -13.4, WHITE, "SmoothPlastic")
	r:block(-5.3, 15, -14.8, 5.3, 15.25, -13.4, WHITE, "SmoothPlastic")
	r:cyl(0, 14.4, -14.75, 0.3, 1.0, "z", WHITE, "SmoothPlastic")
	r:glow(r:cyl(0, 14.4, -14.95, 0.12, 0.7, "z", rgb(220, 90, 80), "Neon"), 0)
	-- windows down both sides
	for _, z in { -7, 0, 7 } do
		for _, sx in { -1, 1 } do
			stamp(r, "sideWindow:" .. WHITE:ToHex(), CFrame.new(sx * 26, 4.2, z) * yaw(-90 * sx), function(q)
				sideWindow(q, WHITE)
			end)
		end
	end
	-- the hose tower: windows up its face, louvres at the top, a cornice and a pointed roof
	r:block(20, 11, 4, 28, 26, 12, red, "Brick")
	r:block(19.5, 26, 3.5, 28.5, 27, 12.5, WHITE, "SmoothPlastic")
	for _, y in { 13.5, 18 } do
		stamp(r, "sideWindow:" .. WHITE:ToHex(), CFrame.new(24, y, 4), function(q)
			sideWindow(q, WHITE)
		end)
	end
	for i = 0, 3 do
		r:block(21.2, 22.6 + i * 0.6, 3.82, 26.8, 22.9 + i * 0.6, 4, shade(red, 0.7), "Wood")
	end
	local apex = Vector3.new(24, 30.5, 8)
	local corners = {
		Vector3.new(19.9, 27, 3.9),
		Vector3.new(28.1, 27, 3.9),
		Vector3.new(28.1, 27, 12.1),
		Vector3.new(19.9, 27, 12.1),
	}
	for k = 1, 4 do
		r:tri(
			corners[k],
			corners[k % 4 + 1],
			apex,
			0.2,
			if k % 2 == 0 then rgb(110, 92, 90) else rgb(96, 80, 80),
			"Slate"
		)
	end
	r:cyl(24, 32, 8, 3, 0.16, "y", METAL, "Metal")
	-- a fire engine out front: the cab with its glass, lockers down the body, a ladder on top,
	-- lamps, a hose reel and six wheels
	local fx, fz = -15, -22
	r:block(fx - 4, 1.2, fz - 7, fx + 4, 5.4, fz + 5, red, "SmoothPlastic")
	r:block(fx - 4, 1.2, fz - 10, fx + 4, 6, fz - 7, red, "SmoothPlastic")
	drawAt(r, CFrame.new(fx, 0, fz), function(q)
		q:box(0, 4.6, -10.04, 7.2, 1.6, 0.08, GLASS_CAR)
		for _, sx in { -1, 1 } do
			q:box(sx * 4.04, 4.7, -8.5, 0.08, 1.4, 2.4, GLASS_CAR)
			for i = 0, 2 do
				q:box(sx * 4.04, 3.5, -5.2 + i * 3.4, 0.08, 1.8, 3.0, shade(red, 0.86))
			end
			q:box(sx * 4.05, 5.0, -1.0, 0.06, 0.3, 11.8, WHITE)
			for _, wz in { -8, 0.4, 3 } do
				q:cyl(sx * 3.7, 1.2, wz, 0.8, 2.4, "x", TYRE)
			end
			q:box(sx * 2.8, 2.4, -10.06, 1.2, 0.5, 0.08, rgb(250, 240, 208))
		end
		q:box(0, 1.1, -10.05, 8.2, 0.5, 0.1, METAL)
		q:box(0, 2.6, -10.06, 3.2, 0.9, 0.08, TRIM_DARK)
		q:cyl(0, 4.6, 4.2, 2.6, 2.2, "x", shade(red, 0.8))
	end)
	drawAt(r, CFrame.new(fx, 5.55, fz - 6.5), function(q)
		ladder(q, 11, 1.8, METAL)
	end)
	r:glow(r:block(fx - 2.2, 6, fz - 9, fx + 2.2, 6.4, fz - 8.2, rgb(230, 90, 80), "Neon"), 0)
end

-- A row of four little houses, each with a garden hedge and a shrub.
M.houseRow = function(r: R)
	local walls = { rgb(240, 205, 176), rgb(204, 221, 234), rgb(243, 223, 166), rgb(207, 226, 208) }
	local roofs = { rgb(79, 138, 140), rgb(194, 126, 99), rgb(110, 140, 168), rgb(184, 102, 92) }
	for k = 0, 3 do
		local x = -27 + k * 18
		house(r, x, 0, 13, 11, walls[k + 1], roofs[k + 1], 0)
		-- a white picket fence along the front with a gate, and a flower bed either side of the
		-- path to the door
		stamp(r, "picketFence", CFrame.new(x, 0, -8.9), function(q)
			for _, sx in { -1, 1 } do
				q:box(sx * 4.7, 0.55, 0.12, 6.6, 0.16, 0.08, WHITE, "Wood")
				q:box(sx * 4.7, 1.0, 0.12, 6.6, 0.16, 0.08, WHITE, "Wood")
				for i = 0, 8 do
					q:box(sx * (1.7 + i * 0.76), 0.65, 0, 0.3, 1.3, 0.1, WHITE, "Wood")
				end
				q:box(sx * 1.45, 0.75, 0.05, 0.3, 1.5, 0.3, WHITE, "Wood")
			end
		end, true)
		for _, sx in { -1, 1 } do
			flowerBed(r, CFrame.new(x + sx * 5, 0.16, -7.2))
		end
		-- a shrub in each back garden (no trees this close to the road)
		r:ball(x + 6, 1.3, 6, 3, LEAF, "SmoothPlastic").name = "Leaf"
		r:ball(x + 4.4, 0.9, 6.6, 2, shade(LEAF, 1.15), "SmoothPlastic").name = "Leaf"
	end
end

M.postOffice = CityModels.shop({
	kind = "post",
	w = 34,
	d = 24,
	floors = 2,
	wall = rgb(170, 196, 222),
	awning = rgb(224, 190, 112),
	sign = rgb(224, 190, 112),
})

-- A park with a pond, a little bridge, trees and benches. (It fills the middle of its block,
-- open to the main street, with houses on the other three sides.)
M.pondPark = function(r: R)
	r:block(-105, 0, -34, 105, 0.3, 34, rgb(136, 190, 108), "Grass")
	r:cyl(-10, 0.32, 0, 0.12, 64, "y", rgb(214, 210, 196), "Slate")
	water(r:cyl(-10, 0.39, 0, 0.14, 58, "y", WATER, "SmoothPlastic"))
	-- stones round the edge, reeds in clumps and lily pads on the water
	drawAt(r, CFrame.new(-10, 0.3, 0), function(q)
		q:box(0, 0.02, 0, 0.6, 0.04, 0.6, ROCK)
		for k = 0, 15 do
			if k ~= 4 and k ~= 12 then
				local a = k / 16 * math.pi * 2
				q:lump(
					CFrame.new(math.cos(a) * 31.2, 0.25, math.sin(a) * 31.2) * CFrame.Angles(0.2, a * 3, 0.1),
					2.4,
					1.0,
					1.8,
					if k % 3 == 0 then shade(ROCK, 1.15) else ROCK
				)
			end
		end
	end, true)
	for i, p in { { 14, -20, 30 }, { -36, 12, 150 }, { 10, 24, 260 }, { -30, -16, 80 } } do
		stamp(r, "reeds", CFrame.new(p[1], 0.3, p[2]) * yaw(p[3]), function(q)
			q:box(0, 0.1, 0, 0.4, 0.2, 0.4, rgb(96, 128, 80))
			for k = 0, 6 do
				local a = k / 7 * math.pi * 2
				local tip = Vector3.new(math.cos(a) * 0.9, 2.4 + (k % 3) * 0.5, math.sin(a) * 0.9)
				q:beam(
					Vector3.new(math.cos(a) * 0.4, 0, math.sin(a) * 0.4),
					tip,
					0.12,
					0.12,
					if k % 2 == 0 then rgb(110, 150, 90) else rgb(132, 166, 100)
				)
				if k % 3 == 0 then
					q:lump(CFrame.new(tip.X, tip.Y - 0.4, tip.Z), 0.22, 0.6, 0.22, rgb(122, 92, 64))
				end
			end
		end)
		local _ = i
	end
	for _, p in { { -24, -6 }, { 6, 8 } } do
		drawAt(r, CFrame.new(p[1], 0.46, p[2]), function(q)
			q:box(0, 0.02, 0, 0.3, 0.02, 0.3, rgb(118, 166, 100))
			for k, o in { { 0, 0 }, { 1.6, 0.7 }, { -1.3, 1.1 }, { 0.6, -1.5 }, { -1.8, -0.8 } } do
				q:cyl(o[1], 0.02, o[2], 0.04, 1.3, "y", if k % 2 == 0 then rgb(96, 150, 92) else rgb(118, 166, 100))
			end
			q:lump(CFrame.new(1.6, 0.2, 0.7), 0.5, 0.35, 0.5, rgb(240, 196, 206))
			q:lump(CFrame.new(-1.8, 0.2, -0.8), 0.45, 0.3, 0.45, rgb(246, 240, 226))
		end, false)
	end
	-- the bridge across: the deck on piers, with railings of posts and rails
	r:block(-14, 0.4, -32, -6, 1.6, 32, WOOD, "WoodPlanks")
	for _, x in { -14, -6 } do
		for i = 0, 3 do
			stamp(r, "bridgeRail", CFrame.new(x, 1.6, -24 + i * 16) * yaw(90), function(q)
				for _, o in { -8, 0, 8 } do
					q:box(o, 0.7, 0, 0.36, 1.4, 0.36, WOOD_DARK, "Wood")
				end
				q:box(0, 1.35, 0, 16, 0.2, 0.3, WOOD_DARK, "Wood")
				q:box(0, 0.65, 0, 16, 0.14, 0.14, WOOD_DARK, "Wood")
				for k = -3, 3 do
					q:box(k * 2, 0.95, 0, 0.12, 0.7, 0.12, WOOD_DARK, "Wood")
				end
			end, true)
		end
		for _, z in { -14, 14 } do
			r:cyl(x + (if x < -10 then 0.6 else -0.6), 0.6, z, 1.2, 0.8, "y", WOOD_DARK, "Wood")
		end
	end
	-- ducks
	for i, p in { { -30, -8 }, { -26, -12 }, { 10, 10 } } do
		drawAt(r, CFrame.new(p[1], 0.46, p[2]) * yaw(i * 70), function(q)
			q:box(0, 0.2, 0, 0.5, 0.3, 0.4, WHITE)
			q:lump(CFrame.new(0, 0.3, 0), 1.3, 0.7, 0.9, WHITE)
			q:lump(CFrame.new(-0.62, 0.8, 0), 0.55, 0.55, 0.5, WHITE)
			q:box(-0.98, 0.76, 0, 0.3, 0.12, 0.2, rgb(234, 166, 72))
			q:lump(CFrame.new(0.66, 0.5, 0) * CFrame.Angles(0, 0, -0.5), 0.4, 0.25, 0.3, WHITE)
		end)
	end
	for _, p in
		{ { 50, -20 }, { 70, 18 }, { 86, -10 }, { -70, 20 }, { -86, -18 }, { 40, 20 }, { -60, -20 }, { 88, 20 } }
	do
		lowTree(r, p[1], 0.3, p[2], 1.3)
	end
	for _, p in { { 30, -6, 90 }, { 30, 6, 90 }, { -60, 0, -90 } } do
		bench(r, p[1], p[2], p[3])
		local last = r.prims[#r.prims]
		last.cf = CFrame.new(0, 0.3, 0) * last.cf
	end
	-- lamps by the benches, and flower beds
	for _, p in { { 33, 0, 90 }, { -63, 4, -90 } } do
		local at = CFrame.new(p[1], 0.3, p[2]) * yaw(p[3])
		stamp(r, "streetLamp", at, lampPost)
		r:glow(r:boxAt(at * CFrame.new(0, 8.4, -2.3), 1, 0.3, 1, rgb(255, 236, 190), "SmoothPlastic"), 16, 1)
	end
	for _, p in { { 60, 0 }, { -80, 0 }, { 20, 29 }, { -40, -29 } } do
		flowerBed(r, CFrame.new(p[1], 0.3, p[2]))
	end
end

-- A playground: a slide, swings, a roundabout and a sandpit.
M.playground = function(r: R)
	r:block(-40, 0, -30, 40, 0.25, 30, rgb(236, 214, 178), "SmoothPlastic")
	local blue, red, yellow = rgb(96, 146, 190), rgb(212, 114, 102), rgb(230, 190, 104)
	-- the slide: a deck on four posts under a little roof, a ladder up the back, low sides and
	-- the chute down the front with its rails
	for _, x in { -24, -18 } do
		for _, z in { -5.8, -0.2 } do
			r:block(x - 0.2, 0.25, z - 0.2, x + 0.2, 8.4, z + 0.2, blue, "SmoothPlastic")
		end
	end
	r:block(-24.4, 5.6, -6.2, -17.6, 6, 0.2, yellow, "WoodPlanks")
	for _, x in { -24.2, -17.8 } do
		r:block(x - 0.1, 6, -5.6, x + 0.1, 7.4, -0.4, red, "SmoothPlastic")
	end
	r:wedge(CFrame.new(-21, 9.2, -4.5), 7, 1.6, 3.4, red, "SmoothPlastic")
	r:wedge(CFrame.new(-21, 9.2, -1.5) * yaw(180), 7, 1.6, 2.6, red, "SmoothPlastic")
	drawAt(r, CFrame.new(-21, 0.25, -6.3) * CFrame.Angles(math.rad(-90), 0, 0), function(q)
		ladder(q, 5.6, 1.6, blue)
	end)
	r:ramp(-22.4, 0.25, 0.2, -19.6, 5.8, 9.6, false, yellow, "SmoothPlastic")
	for _, x in { -22.5, -19.5 } do
		r:beam(Vector3.new(x, 6.5, 0.2), Vector3.new(x, 1.0, 9.6), 0.2, 0.5, yellow, "SmoothPlastic")
	end
	r:block(-22.4, 0.25, 9.6, -19.6, 0.55, 11.2, yellow, "SmoothPlastic")
	-- swings: two A frames under one bar, four seats on their chains
	for _, x in { 4, 16 } do
		for _, sx in { -1, 1 } do
			r:beam(Vector3.new(x + sx * 6, 0, -14), Vector3.new(x + sx * 6, 8, -10), 0.5, 0.5, red, "SmoothPlastic")
			r:beam(Vector3.new(x + sx * 6, 0, -6), Vector3.new(x + sx * 6, 8, -10), 0.5, 0.5, red, "SmoothPlastic")
		end
	end
	r:block(-2, 7.8, -10.3, 22, 8.4, -9.7, red, "SmoothPlastic")
	for _, x in { 1, 7, 13, 19 } do
		r:block(x - 0.9, 2, -10.6, x + 0.9, 2.3, -9.4, DARK, "SmoothPlastic")
		for _, dx in { -0.75, 0.75 } do
			r:block(x + dx - 0.04, 2.3, -10.04, x + dx + 0.04, 7.8, -9.96, METAL, "Metal")
		end
	end
	-- the roundabout: its deck, the post in the middle and bars to hold
	r:cyl(18, 0.7, 14, 0.8, 9, "y", rgb(128, 180, 104), "SmoothPlastic")
	r:cyl(18, 1.9, 14, 2, 1, "y", METAL, "Metal")
	for k = 0, 3 do
		local a = k / 4 * math.pi * 2
		r:beam(
			Vector3.new(18, 2.8, 14),
			Vector3.new(18 + math.cos(a) * 4, 1.1, 14 + math.sin(a) * 4),
			0.16,
			0.16,
			METAL,
			"Metal"
		)
	end
	-- a sandpit in a timber edge, with a bucket and spade
	r:block(-32, 0.25, 12, -16, 0.5, 26, rgb(240, 224, 184), "Sand")
	for _, z in { 12, 26 } do
		r:block(-32.3, 0.25, z - 0.3, -15.7, 0.75, z + 0.3, WOOD, "Wood")
	end
	for _, x in { -32, -16 } do
		r:block(x - 0.3, 0.25, 12.3, x + 0.3, 0.75, 25.7, WOOD, "Wood")
	end
	r:cyl(-26, 0.85, 18, 0.7, 0.8, "y", red, "SmoothPlastic")
	r:boxAt(CFrame.new(-24.5, 0.6, 19) * CFrame.Angles(0, 0.5, 0.3), 0.3, 0.1, 1.4, blue, "SmoothPlastic")
	-- a see-saw
	r:block(26.6, 0.25, 21.4, 27.4, 1.2, 22.6, DARK, "Metal")
	r:boxAt(CFrame.new(27, 1.4, 22) * CFrame.Angles(0, 0, math.rad(9)), 9, 0.25, 1, yellow, "WoodPlanks")
	for _, sx in { -1, 1 } do
		r:boxAt(
			CFrame.new(27, 1.4, 22) * CFrame.Angles(0, 0, math.rad(9)) * CFrame.new(sx * 3.6, 0.5, 0),
			0.2,
			0.8,
			0.8,
			red,
			"SmoothPlastic"
		)
	end
	-- benches for whoever is watching
	bench(r, 0, 27, 0)
	bench(r, -34, 2, 90)
end

M.basketCourt = function(r: R)
	r:block(-30, 0, -18, 30, 0.25, 18, rgb(210, 150, 118), "SmoothPlastic")
	-- the lines, sunk into the court so only their tops show
	drawAt(r, CFrame.new(0, 0.25, 0), function(q)
		for _, line in
			{
				{ -28, -16, 28, -15.6 },
				{ -28, 15.6, 28, 16 },
				{ -28, -15.6, -27.6, 15.6 },
				{ 27.6, -15.6, 28, 15.6 },
				{ -0.2, -15.6, 0.2, 15.6 },
				{ -27.6, -3.2, -21.4, -2.8 },
				{ -27.6, 2.8, -21.4, 3.2 },
				{ -21.4, -3.2, -21, 3.2 },
				{ 21.4, -3.2, 27.6, -2.8 },
				{ 21.4, 2.8, 27.6, 3.2 },
				{ 21, -3.2, 21.4, 3.2 },
			}
		do
			q:box(
				(line[1] + line[3]) / 2,
				0,
				(line[2] + line[4]) / 2,
				line[3] - line[1],
				0.08,
				line[4] - line[2],
				WHITE
			)
		end
		for k = 0, 9 do
			local a = (k + 0.5) / 10 * math.pi * 2
			q:boxAt(
				CFrame.new(math.cos(a) * 3.6, 0, math.sin(a) * 3.6) * CFrame.Angles(0, -a, 0),
				0.4,
				0.08,
				2.3,
				WHITE
			)
		end
	end, false)
	-- a hoop at each end: a padded pole, an arm, the board with its square, the rim and the net
	for _, sx in { -1, 1 } do
		drawAt(r, CFrame.new(sx * 27, 0, 0) * yaw(if sx > 0 then 0 else 180), function(q)
			q:cyl(1.5, 4.5, 0, 9, 0.6, "y", DARK, "Metal")
			q:box(1.5, 1.0, 0, 0.9, 1.6, 0.9, rgb(96, 138, 176), "Metal")
			q:box(0.75, 9.0, 0, 1.5, 0.3, 0.3, DARK, "Metal")
			q:box(0, 9.5, 0, 0.2, 3, 6, WHITE, "Metal")
			q:box(-0.12, 8.95, -0.9, 0.06, 1.1, 0.12, rgb(214, 96, 86), "Metal")
			q:box(-0.12, 8.95, 0.9, 0.06, 1.1, 0.12, rgb(214, 96, 86), "Metal")
			q:box(-0.12, 9.45, 0, 0.06, 0.12, 1.9, rgb(214, 96, 86), "Metal")
			q:box(-0.12, 8.45, 0, 0.06, 0.12, 1.9, rgb(214, 96, 86), "Metal")
			for k = 0, 7 do
				local a1, a2 = k / 8 * math.pi * 2, (k + 1) / 8 * math.pi * 2
				local c = Vector3.new(-1.1, 8.6, 0)
				local p1 = c + Vector3.new(math.cos(a1) * 0.9, 0, math.sin(a1) * 0.9)
				local p2 = c + Vector3.new(math.cos(a2) * 0.9, 0, math.sin(a2) * 0.9)
				q:beam(p1, p2, 0.1, 0.1, rgb(220, 118, 92), "Metal")
				if k % 2 == 0 then
					q:beam(
						p1,
						c + Vector3.new(math.cos(a1) * 0.45, -1.1, math.sin(a1) * 0.45),
						0.06,
						0.06,
						rgb(240, 240, 236),
						"Metal"
					)
				end
			end
		end, true)
	end
	-- benches along one side
	bench(r, -10, 17, 0)
	bench(r, 10, 17, 0)
end

-- The hills ---------------------------------------------------------------------------------------

-- The barn: board walls with white corner boards, a slate roof over red gables, the big doors
-- braced in white with the hayloft door over them, a cupola on the ridge, windows down the sides,
-- and the silo beside it, banded, with a ladder up it.
M.barn = function(r: R)
	local red = rgb(176, 92, 80)
	r:block(-14, 0, -10, 14, 10, 10, red, "WoodPlanks")
	for _, seg in
		{
			{ -14.12, -10.12, -5.3, -10 },
			{ 5.3, -10.12, 14.12, -10 },
			{ -14.12, 10, 14.12, 10.12 },
			{ -14.12, -10, -14, 10 },
			{ 14, -10, 14.12, 10 },
		}
	do
		r:block(seg[1], 0, seg[2], seg[3], 0.8, seg[4], rgb(150, 146, 140), "Concrete")
	end
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			r:block(sx * 14 - 0.25, 0, sz * 10 - 0.25, sx * 14 + 0.25, 10, sz * 10 + 0.25, WHITE, "Wood")
		end
	end
	local ridge = 18
	placed(r, yaw(90), function()
		gableRoof(r, 20, 15, 10, 8, 0.5, red, "WoodPlanks", rgb(112, 104, 104), "Slate", WHITE)
	end)
	-- the doors, and the hayloft door in the gable over them
	drawAt(r, CFrame.new(0, 0, -10), function(q)
		q:box(0, 4.15, -0.06, 10, 7.9, 0.12, shade(red, 0.86), "Wood")
		for _, x in { -5, 0, 5 } do
			q:box(x, 4.1, -0.2, 0.5, 8.2, 0.2, WHITE, "Wood")
		end
		q:box(0, 8.1, -0.2, 10.5, 0.5, 0.2, WHITE, "Wood")
		q:box(0, 0.35, -0.2, 10.5, 0.5, 0.2, WHITE, "Wood")
		for _, sx in { -1, 1 } do
			q:beam(Vector3.new(sx * 0.4, 0.7, -0.2), Vector3.new(sx * 4.6, 7.7, -0.2), 0.14, 0.4, WHITE, "Wood")
			q:beam(Vector3.new(sx * 4.6, 0.7, -0.2), Vector3.new(sx * 0.4, 7.7, -0.2), 0.14, 0.4, WHITE, "Wood")
		end
		q:box(0, 12.2, -0.06, 3.4, 2.8, 0.12, shade(red, 0.86), "Wood")
		for _, x in { -1.85, 1.85 } do
			q:box(x, 12.2, -0.2, 0.3, 3.1, 0.2, WHITE, "Wood")
		end
		q:box(0, 13.75, -0.2, 4, 0.3, 0.2, WHITE, "Wood")
		q:box(0, 10.65, -0.2, 4, 0.3, 0.2, WHITE, "Wood")
		q:beam(Vector3.new(-1.5, 10.9, -0.2), Vector3.new(1.5, 13.5, -0.2), 0.12, 0.3, WHITE, "Wood")
		q:box(0, 14.6, -0.3, 0.5, 0.5, 0.6, WOOD_DARK, "Wood")
	end)
	-- windows down both sides
	for _, z in { -5, 0, 5 } do
		for _, sx in { -1, 1 } do
			stamp(r, "sideWindow:" .. WHITE:ToHex(), CFrame.new(sx * 14, 4.2, z) * yaw(-90 * sx), function(q)
				sideWindow(q, WHITE)
			end)
		end
	end
	-- a louvred cupola on the ridge with a vane
	r:block(-1.6, ridge - 0.6, -1.6, 1.6, ridge + 2.2, 1.6, WHITE, "Wood")
	for i = 0, 2 do
		r:block(-1.3, ridge + 0.4 + i * 0.5, -1.66, 1.3, ridge + 0.6 + i * 0.5, 1.66, rgb(214, 210, 200), "Wood")
	end
	local apex = Vector3.new(0, ridge + 4, 0)
	local cs = {
		Vector3.new(-2, ridge + 2.2, -2),
		Vector3.new(2, ridge + 2.2, -2),
		Vector3.new(2, ridge + 2.2, 2),
		Vector3.new(-2, ridge + 2.2, 2),
	}
	for k = 1, 4 do
		r:tri(cs[k], cs[k % 4 + 1], apex, 0.2, if k % 2 == 0 then rgb(112, 104, 104) else rgb(98, 92, 92), "Slate")
	end
	r:cyl(0, ridge + 4.8, 0, 1.6, 0.12, "y", DARK, "Metal")
	r:block(-0.7, ridge + 5.2, -0.04, 0.7, ridge + 5.36, 0.04, DARK, "Metal")
	-- the silo: bands round it, a domed cap and a ladder
	r:cyl(20, 9, 0, 18, 8.6, "y", rgb(214, 220, 228), "Metal")
	for _, y in { 3, 7.5, 12, 16.5 } do
		r:cyl(20, y, 0, 0.3, 9, "y", rgb(176, 184, 196), "Metal")
	end
	r:ball(20, 18, 0, 9, rgb(124, 150, 180), "Metal")
	drawAt(r, CFrame.new(20, 0.6, -4.65) * CFrame.Angles(math.rad(-90), 0, 0), function(q)
		ladder(q, 17.4, 1.2, DARK)
	end)
end

-- A windmill: a white tower in two steps with a gallery round it, a boat shaped cap and four
-- lattice sails that turn (every part of a sail is named Spin; the axle is the Hub).
M.windmill = function(r: R)
	r:cyl(0, 5.4, 0, 9.2, 8.6, "y", WHITE, "Plaster")
	r:cyl(0, 12.5, 0, 5, 7, "y", WHITE, "Plaster")
	r:cyl(0, 0.4, 0, 0.8, 9, "y", rgb(196, 190, 180), "Concrete")
	-- the gallery: a deck at the step, posts and a rail
	r:cyl(0, 10.15, 0, 0.3, 9, "y", WOOD, "WoodPlanks")
	for k = 0, 7 do
		local a1, a2 = (k + 0.5) / 8 * math.pi * 2, (k + 1.5) / 8 * math.pi * 2
		local p1 = Vector3.new(math.cos(a1) * 4.25, 11.6, math.sin(a1) * 4.25)
		local p2 = Vector3.new(math.cos(a2) * 4.25, 11.6, math.sin(a2) * 4.25)
		r:box(p1.X, 10.95, p1.Z, 0.16, 1.3, 0.16, WOOD_DARK, "Wood")
		r:beam(p1, p2, 0.14, 0.14, WOOD_DARK, "Wood")
	end
	-- the door with its frame and step, and two small windows
	r:block(-1.2, 0.2, -4.6, 1.2, 3.6, -4.3, DOOR, "Wood")
	r:block(-1.5, 0.2, -4.7, -1.2, 3.9, -4.25, WOOD_DARK, "Wood")
	r:block(1.2, 0.2, -4.7, 1.5, 3.9, -4.25, WOOD_DARK, "Wood")
	r:block(-1.5, 3.6, -4.7, 1.5, 3.9, -4.25, WOOD_DARK, "Wood")
	r:block(-1.6, 0, -5.3, 1.6, 0.25, -4.4, rgb(196, 190, 180), "Concrete")
	for _, y in { 6.6, 13 } do
		local rr = if y > 10 then 3.5 else 4.5
		r:block(-0.6, y, -rr - 0.12, 0.6, y + 1.3, -rr + 0.3, DARK, "SmoothPlastic")
		r:block(-0.8, y - 0.2, -rr - 0.2, 0.8, y, -rr + 0.3, WHITE, "Wood")
	end
	-- the cap: a band, a body and a pitched top
	r:block(-3.4, 15, -3.4, 3.4, 16.6, 3.4, rgb(184, 102, 92), "WoodPlanks")
	r:wedge(CFrame.new(0, 17.4, -1.7), 6.8, 1.6, 3.4, rgb(150, 88, 80), "WoodPlanks")
	r:wedge(CFrame.new(0, 17.4, 1.7) * yaw(180), 6.8, 1.6, 3.4, rgb(150, 88, 80), "WoodPlanks")
	local hub = r:cyl(0, 16.5, -4.6, 1.6, 2, "z", WOOD_DARK, "Wood")
	hub.name = "Hub"
	for k = 0, 3 do
		local a = k * math.pi / 2 + math.pi / 4
		local tip = Vector3.new(math.cos(a) * 11, 16.5 + math.sin(a) * 11, -5.2)
		local arm = r:beam(Vector3.new(0, 16.5, -5.1), Vector3.new(tip.X, tip.Y, -5.1), 0.5, 0.5, WOOD_DARK, "Wood")
		if arm then
			arm.name = "Spin"
		end
		-- the sail: cloth inside a frame of two rails and three bars
		local at = CFrame.new(math.cos(a) * 6.5, 16.5 + math.sin(a) * 6.5, -5.4) * CFrame.Angles(0, 0, a)
		local sail = r:boxAt(at, 7.6, 2.2, 0.12, rgb(255, 250, 240), "Fabric")
		sail.name = "Spin"
		for _, oy in { -1.2, 1.2 } do
			r:boxAt(at * CFrame.new(0, oy, -0.04), 8, 0.18, 0.12, WOOD_DARK, "Wood").name = "Spin"
		end
		for _, ox in { -3, 0, 3 } do
			r:boxAt(at * CFrame.new(ox, 0, -0.04), 0.14, 2.4, 0.12, WOOD_DARK, "Wood").name = "Spin"
		end
	end
end

-- A field of crops inside a post and rail fence: the soil, and a row of plants on every ridge.
local CROPS: { [string]: (R) -> () } = {
	wheat = function(q: R)
		q:box(0, 0.25, 0, 44, 0.5, 1.6, rgb(140, 108, 80))
		for i = 0, 13 do
			local x = -20.8 + i * 3.2
			q:lump(
				CFrame.new(x, 1.2, 0) * CFrame.Angles(0, i, 0.1),
				2.4,
				1.8,
				1.5,
				if i % 2 == 0 then rgb(222, 196, 120) else rgb(206, 178, 104)
			)
		end
	end,
	greens = function(q: R)
		q:box(0, 0.25, 0, 44, 0.5, 1.6, rgb(140, 108, 80))
		for i = 0, 13 do
			local x = -20.8 + i * 3.2
			q:lump(
				CFrame.new(x, 0.9, 0) * CFrame.Angles(0.2, i * 0.7, 0),
				1.6,
				1.1,
				1.5,
				if i % 3 == 0 then rgb(150, 190, 110) else rgb(116, 168, 96)
			)
		end
	end,
	pumpkins = function(q: R)
		q:box(0, 0.25, 0, 44, 0.5, 1.6, rgb(140, 108, 80))
		for i = 0, 6 do
			local x = -19.5 + i * 6.5
			q:lump(CFrame.new(x, 0.8, 0.1) * CFrame.Angles(0, i, 0), 1.5, 1.0, 1.4, rgb(224, 150, 84))
			q:lump(CFrame.new(x + 2.4, 0.75, -0.2) * CFrame.Angles(0.2, i, 0.1), 2.6, 0.6, 1.4, rgb(110, 150, 92))
		end
	end,
}
local function field(r: R, x: number, z: number, w: number, d: number, crop: string)
	r:block(x - w / 2, 0, z - d / 2, x + w / 2, 0.3, z + d / 2, rgb(164, 126, 96), "Ground")
	local rows = math.floor(d / 5)
	for k = 0, rows - 1 do
		local rz = z - d / 2 + (k + 0.5) * d / rows
		stamp(r, "crop:" .. crop, CFrame.new(x, 0.3, rz), CROPS[crop])
	end
	-- the fence, in runs: twelve studs where the sides allow, eight where they don't
	local run = if (w + 2) % 12 == 0 and (d + 2) % 12 == 0 then 12 else 8
	for _, side in { { 0, -1 }, { 0, 1 }, { -1, 0 }, { 1, 0 } } do
		local along = side[1] == 0
		local len = if along then w + 2 else d + 2
		local n = math.floor(len / run + 0.5)
		for i = 0, n - 1 do
			local o = -len / 2 + (i + 0.5) * run
			local at = if along
				then CFrame.new(x + o, 0, z + side[2] * (d / 2 + 1))
				else CFrame.new(x + side[1] * (w / 2 + 1), 0, z + o) * yaw(90)
			stamp(r, "fenceRun:" .. run, at, function(q)
				fenceRun(q, run)
			end, true)
		end
	end
end

-- A cow: a body with patches, a head with a muzzle and horns, legs, ears and a tail.
local function cow(r: R, x: number, z: number, turn: number)
	stamp(r, "cow", CFrame.new(x, 0, z) * yaw(turn), function(q)
		local hide, ink = rgb(246, 242, 232), rgb(70, 64, 66)
		q:box(0, 2.5, 0, 2.1, 1.7, 3.6, hide)
		q:box(0.6, 2.7, 0.5, 1.0, 1.2, 1.4, ink)
		q:box(-0.45, 2.4, -0.7, 1.3, 1.0, 1.0, ink)
		for _, lx in { -0.65, 0.65 } do
			for _, lz in { -1.3, 1.3 } do
				q:box(lx, 0.85, lz, 0.45, 1.7, 0.45, hide)
				q:box(lx, 0.12, lz, 0.5, 0.24, 0.5, ink)
			end
		end
		q:lump(CFrame.new(0, 3.1, -2.3) * CFrame.Angles(0.3, 0, 0), 1.3, 1.4, 1.5, hide)
		q:box(0, 2.75, -3.05, 1.0, 0.7, 0.5, rgb(226, 178, 170))
		for _, sx in { -1, 1 } do
			q:box(sx * 0.85, 3.5, -2.15, 0.5, 0.2, 0.3, hide)
			q:box(sx * 0.4, 3.85, -2.3, 0.14, 0.4, 0.14, rgb(232, 224, 200))
		end
		q:beam(Vector3.new(0, 3.1, 1.8), Vector3.new(0, 1.6, 2.1), 0.14, 0.14, hide)
		q:lump(CFrame.new(0, 1.45, 2.12), 0.3, 0.4, 0.3, ink)
	end, true)
end

-- The farm on its plateau (the barn and windmill are their own pieces): fields, hay and cows.
M.farmyard = function(r: R)
	field(r, -60, -40, 46, 34, "wheat")
	field(r, -60, 10, 46, 34, "greens")
	field(r, 0, 50, 46, 30, "pumpkins")
	for _, p in { { 30, -20 }, { 36, -14 }, { 26, -12 } } do
		drawAt(r, CFrame.new(p[1], 1.4, p[2]), function(q)
			q:box(0, 0, 0, 2.4, 1.2, 1.2, rgb(214, 186, 120))
			q:cyl(0, 0, 0, 3, 2.8, "x", rgb(230, 206, 138))
			for _, x in { -1.52, 1.52 } do
				q:cyl(x, 0, 0, 0.04, 2.3, "x", rgb(208, 180, 112))
			end
		end, true)
	end
	for _, p in { { 50, 20, 30 }, { 60, 30, 185 }, { 44, 36, 120 } } do
		cow(r, p[1], p[2], p[3])
	end
	-- a trough for them, and a path of flat stones across the yard
	r:block(52, 0, 25, 58, 0.95, 26.6, WOOD_DARK, "WoodPlanks")
	r:block(52.25, 0.95, 25.25, 57.75, 1.05, 26.35, WATER, "SmoothPlastic")
	r:block(52, 0.95, 25, 58, 1.2, 25.25, WOOD_DARK, "WoodPlanks")
	r:block(52, 0.95, 26.35, 58, 1.2, 26.6, WOOD_DARK, "WoodPlanks")
	r:block(52, 0.95, 25.25, 52.25, 1.2, 26.35, WOOD_DARK, "WoodPlanks")
	r:block(57.75, 0.95, 25.25, 58, 1.2, 26.35, WOOD_DARK, "WoodPlanks")
	for k = 0, 8 do
		r:cyl(-20 + k * 7, 0.1, -60 + k * 6, 0.25, 3.4, "y", rgb(222, 214, 196), "SmoothPlastic")
	end
end

-- The lookout: a wooden platform up on braced posts, with two ramps up to it, railings of posts
-- and rails, a roof over half the deck, a telescope on its tripod and a bench.
M.lookout = function(r: R)
	local deckY = 12
	r:block(-7, deckY - 0.6, -13, 7, deckY, 7, WOOD, "WoodPlanks")
	r:block(-7.1, deckY - 1.1, -13.1, 7.1, deckY - 0.6, 7, WOOD_DARK, "Wood")
	for _, p in { { -6.5, -12.5 }, { 6.5, -12.5 }, { -6.5, 6.5 }, { 6.5, 6.5 } } do
		r:block(p[1] - 0.6, 0, p[2] - 0.6, p[1] + 0.6, deckY - 1.1, p[2] + 0.6, WOOD_DARK, "Wood")
	end
	-- braces between the posts, crossed on every side
	local low, high = 1.5, deckY - 1.6
	for _, x in { -6.5, 6.5 } do
		r:beam(Vector3.new(x, low, -12), Vector3.new(x, high, 6), 0.3, 0.3, WOOD_DARK, "Wood")
		r:beam(Vector3.new(x, high, -12), Vector3.new(x, low, 6), 0.3, 0.3, WOOD_DARK, "Wood")
	end
	for _, z in { -12.5, 6.5 } do
		r:beam(Vector3.new(-6, low, z), Vector3.new(6, high, z), 0.3, 0.3, WOOD_DARK, "Wood")
		r:beam(Vector3.new(-6, high, z), Vector3.new(6, low, z), 0.3, 0.3, WOOD_DARK, "Wood")
	end
	-- railings round the deck (open where the top ramp lands)
	railing(r, Vector3.new(-6.85, deckY, 6.85), Vector3.new(6.85, deckY, 6.85), 2.6, WOOD_DARK)
	railing(r, Vector3.new(-6.85, deckY, -12.85), Vector3.new(-6.85, deckY, 6.85), 2.6, WOOD_DARK)
	railing(r, Vector3.new(-6.85, deckY, -12.85), Vector3.new(6.85, deckY, -12.85), 2.6, WOOD_DARK)
	railing(r, Vector3.new(6.85, deckY, -9), Vector3.new(6.85, deckY, 6.85), 2.6, WOOD_DARK)
	-- up from the ground on the east side, a landing, and back up to the deck
	r:ramp(7, 0, -9, 11, deckY / 2, 9, true, WOOD, "WoodPlanks")
	r:block(7, deckY / 2 - 0.6, 9, 15, deckY / 2, 13, WOOD, "WoodPlanks")
	r:ramp(11, deckY / 2, -9, 15, deckY, 9, false, WOOD, "WoodPlanks")
	r:block(7, deckY - 0.6, -13, 15, deckY, -9, WOOD, "WoodPlanks")
	railing(r, Vector3.new(7.15, deckY / 2, 12.85), Vector3.new(14.85, deckY / 2, 12.85), 2.4, WOOD_DARK)
	railing(r, Vector3.new(14.85, deckY, -12.85), Vector3.new(7.15, deckY, -12.85), 2.4, WOOD_DARK)
	for _, p in { { 14.4, 12.4 }, { 7.6, 12.4 }, { 14.4, -12.4 } } do
		local top = if p[2] > 0 then deckY / 2 - 0.6 else deckY - 0.6
		r:block(p[1] - 0.35, 0, p[2] - 0.35, p[1] + 0.35, top, p[2] + 0.35, WOOD_DARK, "Wood")
	end
	-- a roof over half the deck, on four posts
	placed(r, CFrame.new(0, 0, 3), function()
		gableRoof(r, 14, 7, deckY + 5.5, 3, 1, WOOD_DARK, "Wood", rgb(194, 126, 99), "RoofShingles", WHITE)
	end)
	for _, x in { -6.5, 6.5 } do
		for _, z in { -3.4, 6.3 } do
			r:block(x - 0.3, deckY, z - 0.3, x + 0.3, deckY + 5.5, z + 0.3, WOOD_DARK, "Wood")
		end
	end
	-- the telescope on a tripod, looking out over the town
	for k = 0, 2 do
		local a = k / 3 * math.pi * 2
		r:beam(
			Vector3.new(-3, deckY + 2.6, -10),
			Vector3.new(-3 + math.cos(a) * 0.9, deckY, -10 + math.sin(a) * 0.9),
			0.14,
			0.14,
			DARK,
			"Metal"
		)
	end
	r:boxAt(CFrame.new(-3, deckY + 3.1, -10.4) * CFrame.Angles(math.rad(-14), 0, 0), 0.8, 0.8, 2.8, METAL, "Metal")
	r:boxAt(CFrame.new(-3, deckY + 3.42, -12.0) * CFrame.Angles(math.rad(-14), 0, 0), 1.1, 1.1, 0.5, DARK, "Metal")
	bench(r, 3, -4, 180)
end

-- The observatory: a drum on a plinth with windows round it and a cornice, the dome with its
-- opening and shutters and the telescope looking out, and a porch over the door.
M.observatory = function(r: R)
	r:cyl(0, 0.5, 0, 1, 18, "y", rgb(206, 200, 190), "Concrete")
	r:cyl(0, 5, 0, 8, 17.4, "y", WHITE, "Plaster")
	r:cyl(0, 9, 0, 0.6, 18, "y", rgb(206, 200, 190), "Concrete")
	r:lump(CFrame.new(0, 9.3, 0), 17.2, 12, 17.2, rgb(214, 222, 232), "Metal")
	-- the opening down the front of the dome, its shutters drawn back either side, and the
	-- telescope looking out of it
	local function onDome(z: number, lift: number): Vector3
		return Vector3.new(0, 9.3 + 6 * math.sqrt(math.max(0, 1 - (z / 8.6) ^ 2)) + lift, z)
	end
	local zs = { -0.4, -4.0, -6.6, -8.3 }
	for i = 1, #zs - 1 do
		r:beam(onDome(zs[i], 0.1), onDome(zs[i + 1], 0.1), 2.6, 0.5, DARK, "SmoothPlastic")
		for _, sx in { -1, 1 } do
			local o = Vector3.new(sx * 2.0, -0.05, 0)
			r:beam(onDome(zs[i], 0.1) + o, onDome(zs[i + 1], 0.1) + o, 1.2, 0.5, rgb(184, 194, 206), "Metal")
		end
	end
	r:cyl(0, 0, 0, 3.6, 1.1, "x", METAL, "Metal").cf = CFrame.new(0, 14.2, -5.4)
		* CFrame.Angles(math.rad(36), 0, 0)
		* CFrame.Angles(0, math.pi / 2, 0)
	-- windows round the drum
	for _, a in { 50, 130, 230, 310 } do
		local f = CFrame.Angles(0, math.rad(a), 0) * CFrame.new(0, 4.4, -8.62)
		r:boxAt(f, 1.4, 2.2, 0.3, PANE, "SmoothPlastic")
		r:boxAt(f * CFrame.new(0, -1.25, -0.12), 1.8, 0.24, 0.5, WHITE, "SmoothPlastic")
		r:boxAt(f * CFrame.new(0, 1.25, -0.08), 1.8, 0.3, 0.42, WHITE, "SmoothPlastic")
	end
	-- the door, its frame, a little porch roof on brackets and the steps
	r:block(-1.6, 0.2, -9.1, 1.6, 4.6, -8.7, DOOR, "SmoothPlastic")
	r:block(-1.9, 0.2, -9.2, -1.6, 4.9, -8.7, WHITE, "SmoothPlastic")
	r:block(1.6, 0.2, -9.2, 1.9, 4.9, -8.7, WHITE, "SmoothPlastic")
	r:block(-1.9, 4.6, -9.2, 1.9, 4.9, -8.7, WHITE, "SmoothPlastic")
	r:block(-2.4, 5.1, -10.8, 2.4, 5.35, -8.6, rgb(150, 160, 176), "Metal")
	for _, sx in { -1, 1 } do
		r:beam(Vector3.new(sx * 2, 4.2, -8.8), Vector3.new(sx * 2, 5.1, -10.4), 0.14, 0.14, DARK, "Metal")
	end
	for k = 0, 1 do
		r:block(-3 - k, 0, -10.4 - k * 1.2, 3 + k, 0.5 * (2 - k), -9 - k * 1.2, STONE, "SmoothPlastic")
	end
end

-- The radio mast: a plinth, four splayed legs up to a straight lattice in red and white
-- sections, a platform with two dishes, the aerial and its warning light.
M.radioMast = function(r: R)
	r:block(-3, 0, -3, 3, 1, 3, STONE, "Concrete")
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			r:beam(
				Vector3.new(sx * 2.4, 1, sz * 2.4),
				Vector3.new(sx * 0.9, 5, sz * 0.9),
				0.3,
				0.3,
				rgb(206, 112, 102),
				"Metal"
			)
		end
	end
	for i = 0, 7 do
		local col, brace = rgb(206, 112, 102), WHITE
		stamp(r, "mastSection", CFrame.new(0, 5 + i * 4, 0), function(q)
			for _, sx in { -1, 1 } do
				for _, sz in { -1, 1 } do
					q:box(sx * 0.9, 2, sz * 0.9, 0.24, 4, 0.24, col, "Metal")
				end
			end
			q:box(0, 0.1, -0.9, 1.8, 0.16, 0.16, brace, "Metal")
			q:box(0, 0.1, 0.9, 1.8, 0.16, 0.16, brace, "Metal")
			q:box(-0.9, 0.1, 0, 0.16, 0.16, 1.8, brace, "Metal")
			q:box(0.9, 0.1, 0, 0.16, 0.16, 1.8, brace, "Metal")
			q:beam(Vector3.new(-0.9, 0.2, -0.9), Vector3.new(0.9, 3.9, -0.9), 0.12, 0.12, brace, "Metal")
			q:beam(Vector3.new(0.9, 0.2, 0.9), Vector3.new(-0.9, 3.9, 0.9), 0.12, 0.12, brace, "Metal")
			q:beam(Vector3.new(-0.9, 0.2, 0.9), Vector3.new(-0.9, 3.9, -0.9), 0.12, 0.12, brace, "Metal")
			q:beam(Vector3.new(0.9, 0.2, -0.9), Vector3.new(0.9, 3.9, 0.9), 0.12, 0.12, brace, "Metal")
		end)
	end
	r:block(-1.6, 37, -1.6, 1.6, 37.25, 1.6, METAL, "Metal")
	for _, a in { 0, 150 } do
		local f = CFrame.new(0, 34.5, 0) * yaw(a) * CFrame.new(0, 0, -1.4) * CFrame.Angles(math.rad(-10), 0, 0)
		r:cyl(0, 0, 0, 0.3, 1.8, "z", WHITE, "Metal").cf = f * CFrame.Angles(0, math.pi / 2, 0)
	end
	r:cyl(0, 38.6, 0, 3, 0.2, "y", METAL, "Metal")
	r:glow(r:ball(0, 40.2, 0, 0.6, rgb(255, 80, 70), "Neon"), 0)
end

-- A tent: two slopes of canvas, and what every tent shares in one piece: poles at both ends, a
-- dark door flap, guy ropes out to pegs and a mat at the door.
local function tent(r: R, x: number, z: number, turn: number, col: Color3)
	local f = CFrame.new(x, 0, z) * yaw(turn)
	r:wedge(f * CFrame.new(0, 2, -1.75), 5, 4, 3.5, col, "Fabric")
	r:wedge(f * CFrame.new(0, 2, 1.75) * CFrame.Angles(0, math.pi, 0), 5, 4, 3.5, shade(col, 0.88), "Fabric")
	stamp(r, "tentKit", f, function(q)
		q:box(3.1, 0.03, 0, 1.0, 0.06, 1.8, rgb(150, 120, 90))
		for _, sx in { -1, 1 } do
			q:box(sx * 2.62, 2.1, 0, 0.16, 4.2, 0.16, WOOD_DARK)
			q:beam(Vector3.new(sx * 2.62, 4.0, 0), Vector3.new(sx * 4.3, 0.05, 0), 0.05, 0.05, rgb(220, 214, 196))
			q:box(sx * 4.3, 0.15, 0, 0.12, 0.3, 0.12, WOOD_DARK)
		end
		q:tri(
			Vector3.new(2.53, 0.06, -1.3),
			Vector3.new(2.53, 0.06, 1.3),
			Vector3.new(2.53, 2.8, 0),
			0.04,
			rgb(86, 78, 70)
		)
	end)
end

-- The campsite in the pines: tents round a fire ringed with stones, log seats, a log cabin, a
-- picnic table and a woodpile.
M.camp = function(r: R)
	tent(r, -12, -6, 20, rgb(220, 144, 100))
	tent(r, 6, -14, -10, rgb(96, 142, 186))
	tent(r, 14, 4, 80, rgb(124, 176, 100))
	-- the campfire
	for k = 0, 3 do
		local a = k * math.pi / 2 + 0.4
		r:boxAt(CFrame.new(0, 0.5, 0) * CFrame.Angles(0, a, math.rad(15)), 3, 0.6, 0.6, WOOD_DARK, "Wood")
	end
	r:fire(r:glow(r:ball(0, 1, 0, 1.2, rgb(255, 150, 60), "Neon"), 14, 1.4, rgb(255, 170, 90)))
	drawAt(r, CFrame.identity, function(q)
		q:box(0, 0.02, 0, 0.6, 0.04, 0.6, ROCK)
		for k = 0, 7 do
			local a = k / 8 * math.pi * 2
			q:lump(
				CFrame.new(math.cos(a) * 1.9, 0.25, math.sin(a) * 1.9) * CFrame.Angles(0.3, a, 0.2),
				0.9,
				0.6,
				0.8,
				if k % 2 == 0 then ROCK else shade(ROCK, 1.15)
			)
		end
	end, true)
	for k = 0, 4 do
		local a = k / 5 * math.pi * 2
		r:cyl(math.cos(a) * 6, 0.6, math.sin(a) * 6, 1.2, 1.4, "y", ROCK, "SmoothPlastic")
	end
	for _, a in { 0.6, 2.2 } do
		r:cyl(0, 0, 0, 3.6, 1.1, "x", BARK, "Wood").cf = CFrame.Angles(0, a, 0) * CFrame.new(0, 0.55, -4.3)
	end
	house(r, -22, 20, 14, 10, rgb(164, 124, 92), rgb(106, 92, 90), 160)
	-- a picnic table: planks on two A frames, and a bench either side
	drawAt(r, CFrame.new(19, 0, 20), function(q)
		for i = 0, 2 do
			q:box(0, 2.6, -1.1 + i * 1.1, 6, 0.2, 1.0, WOOD, "Wood")
		end
		for _, sz in { -1, 1 } do
			q:box(0, 1.55, sz * 3, 6, 0.2, 1.0, WOOD, "Wood")
		end
		for _, x in { -2.2, 2.2 } do
			q:beam(Vector3.new(x, 2.5, -0.6), Vector3.new(x, 0, -3.2), 0.25, 0.25, WOOD_DARK, "Wood")
			q:beam(Vector3.new(x, 2.5, 0.6), Vector3.new(x, 0, 3.2), 0.25, 0.25, WOOD_DARK, "Wood")
			q:box(x, 1.4, 0, 0.25, 0.2, 6.4, WOOD_DARK, "Wood")
		end
	end, true)
	-- a woodpile by the cabin
	for i = 0, 5 do
		local row = if i < 3 then 0 else 1
		r:cyl(-14 + (i % 3) * 0.9 + row * 0.45, 0.45 + row * 0.8, 13.5, 2.4, 0.9, "z", BARK, "Wood")
	end
end

-- The waterfront ----------------------------------------------------------------------------------

-- A ferris wheel: braced legs either side of the hub, a rim of beams with a bulb at every joint,
-- a spoke to each joint, and cabins with a window band and a hanger (rim, spokes and bulbs are
-- named Spin and turn round the Hub; the cabins are named Cabin and stay upright). A ticket
-- booth by the platform.
M.ferrisWheel = function(r: R)
	local R0 = 16
	local hy = R0 + 4
	local col = rgb(212, 114, 102)
	for _, sz in { -2.2, 2.2 } do
		r:beam(Vector3.new(-9, 0, sz), Vector3.new(0, hy, sz), 1, 1, WHITE, "Metal")
		r:beam(Vector3.new(9, 0, sz), Vector3.new(0, hy, sz), 1, 1, WHITE, "Metal")
		for _, y in { 6, 12 } do
			local x = 9 - 9 * y / hy
			r:beam(Vector3.new(-x, y, sz), Vector3.new(x, y, sz), 0.4, 0.4, WHITE, "Metal")
		end
	end
	local hub = r:cyl(0, hy, 0, 5.6, 2.4, "z", METAL, "Metal")
	hub.name = "Hub"
	local n = 16
	for k = 0, n - 1 do
		local a1, a2 = k / n * math.pi * 2, (k + 1) / n * math.pi * 2
		local p1 = Vector3.new(math.cos(a1) * R0, hy + math.sin(a1) * R0, 0)
		local p2 = Vector3.new(math.cos(a2) * R0, hy + math.sin(a2) * R0, 0)
		local rim = r:beam(
			p1,
			p2,
			if k % 2 == 0 then 0.8 else 0.7,
			1.2,
			if k % 2 == 0 then col else rgb(232, 198, 118),
			"SmoothPlastic"
		)
		if rim then
			rim.name = "Spin"
		end
		local spoke = r:beam(Vector3.new(0, hy, 0), p1, 0.4, 0.4, WHITE, "Metal")
		if spoke then
			spoke.name = "Spin"
		end
		local bulb = r:ball(p1.X * 1.04, hy + (p1.Y - hy) * 1.04, 0, 0.6, rgb(255, 238, 190), "SmoothPlastic")
		bulb.name = "Spin"
		r:glow(bulb, 0)
		if k % 2 == 0 then
			local cabinCol = ({ rgb(100, 146, 192), rgb(128, 180, 104), rgb(232, 192, 110), rgb(172, 142, 206) })[(k / 2) % 4 + 1]
			local c = r:box(p1.X, p1.Y - 2.2, 0, 3, 2.6, 2.6, cabinCol, "SmoothPlastic")
			c.name = "Cabin"
			local glass = r:box(p1.X, p1.Y - 2.0, 0, 3.08, 0.9, 2.68, GLASS_CAR, "SmoothPlastic")
			glass.name = "Cabin"
			local roof = r:box(p1.X, p1.Y - 0.7, 0, 3.4, 0.5, 3, WHITE, "SmoothPlastic")
			roof.name = "Cabin"
			local hanger = r:box(p1.X, p1.Y - 0.2, 0, 0.3, 0.6, 0.3, DARK, "Metal")
			hanger.name = "Cabin"
		end
	end
	r:block(-11, 0, -4, 11, 0.6, 4, STONE, "SmoothPlastic")
	r:block(-11.2, 0.6, -4, 11.2, 0.75, -3.6, WHITE, "SmoothPlastic")
	drawAt(r, CFrame.new(14.2, 0, 0), function(q)
		q:box(0, 1.6, 0, 2.8, 3.2, 2.8, rgb(232, 198, 118))
		q:box(0, 3.35, 0, 3.4, 0.3, 3.4, col)
		q:box(0, 3.75, 0, 2.2, 0.5, 2.2, col)
		q:box(-1.42, 2.1, 0, 0.06, 1.1, 1.8, GLASS_CAR)
		q:box(-1.6, 1.5, 0, 0.4, 0.12, 2.0, WHITE)
		q:box(0, 0.2, 0, 3.0, 0.4, 3.0, WHITE)
	end, true)
end

-- A carousel: a round deck on a step, a striped tent roof with a scalloped edge and bulbs round
-- it, a gilded centre post round the Hub, and six horses on poles that go round (named Spin).
M.carousel = function(r: R)
	local red = rgb(212, 114, 102)
	local gold = rgb(232, 198, 118)
	r:cyl(0, 0.25, 0, 0.5, 21.6, "y", WHITE, "SmoothPlastic")
	r:cyl(0, 0.75, 0, 0.5, 20, "y", gold, "SmoothPlastic")
	local hub = r:cyl(0, 4, 0, 8, 1.6, "y", red, "Metal")
	hub.name = "Hub"
	r:cyl(0, 4.6, 0, 7.2, 3, "y", gold, "SmoothPlastic")
	drawAt(r, CFrame.identity, function(q)
		q:box(0, 12.1, 0, 1, 0.4, 1, gold, "Fabric")
		local apex = Vector3.new(0, 12, 0)
		for k = 0, 7 do
			local a1, a2 = (k + 0.5) / 8 * math.pi * 2, (k + 1.5) / 8 * math.pi * 2
			local p1 = Vector3.new(math.cos(a1) * 11, 8.8, math.sin(a1) * 11)
			local p2 = Vector3.new(math.cos(a2) * 11, 8.8, math.sin(a2) * 11)
			q:tri(apex, p1, p2, 0.16, if k % 2 == 0 then red else WHITE, "Fabric")
			local am = (k + 1) / 8 * math.pi * 2
			q:boxAt(
				CFrame.new(math.cos(am) * 10.08, 8.35, math.sin(am) * 10.08) * CFrame.Angles(0, -am + math.pi / 2, 0),
				8.2,
				0.9,
				0.1,
				if k % 2 == 0 then WHITE else red,
				"Fabric"
			)
		end
	end)
	for k = 0, 7 do
		local a = (k + 0.5) / 8 * math.pi * 2
		r:glow(r:ball(math.cos(a) * 10.6, 8.6, math.sin(a) * 10.6, 0.5, rgb(255, 238, 190), "SmoothPlastic"), 0)
	end
	local horses = { WHITE, rgb(244, 204, 216), rgb(204, 224, 240), rgb(244, 226, 176), rgb(214, 236, 214), WHITE }
	local saddles = { red, rgb(92, 140, 180), gold, rgb(140, 118, 176), red, rgb(92, 158, 148) }
	for k = 0, 5 do
		local a = k / 6 * math.pi * 2
		local x, z = math.cos(a) * 7, math.sin(a) * 7
		local f = CFrame.new(x, 0, z) * CFrame.Angles(0, -a, 0)
		local pole = r:cyl(x, 4.6, z, 7.6, 0.3, "y", gold, "Metal")
		pole.name = "Spin"
		local hide = horses[k + 1]
		local parts: { Prim? } = {
			r:lump(f * CFrame.new(0, 3, 0), 1.1, 1.2, 2.8, hide, "SmoothPlastic"),
			r:lump(
				f * CFrame.new(0, 4.0, -1.45) * CFrame.Angles(math.rad(-30), 0, 0),
				0.8,
				1.6,
				1.0,
				hide,
				"SmoothPlastic"
			),
			r:beam(f * Vector3.new(0, 2.7, -0.9), f * Vector3.new(0, 1.5, -1.7), 0.28, 0.3, hide, "SmoothPlastic"),
			r:beam(f * Vector3.new(0, 2.7, 0.9), f * Vector3.new(0, 1.5, 1.6), 0.28, 0.3, hide, "SmoothPlastic"),
			r:boxAt(f * CFrame.new(0, 3.62, 0.1), 1.2, 0.2, 1.0, saddles[k + 1], "SmoothPlastic"),
			r:lump(
				f * CFrame.new(0, 3.0, 1.55) * CFrame.Angles(math.rad(30), 0, 0),
				0.3,
				0.9,
				0.3,
				shade(hide, 0.8),
				"SmoothPlastic"
			),
		}
		for _, p in parts do
			if p then
				p.name = "Spin"
			end
		end
	end
end

-- A food kiosk: a boarded counter under a striped awning with a scalloped hem on four turned
-- posts, a back board with shelves, the menu and what it sells on the counter.
M.stall = function(r: R)
	stamp(r, "stallFrame", CFrame.identity, function(q)
		local cream, wood = rgb(244, 232, 210), WOOD_DARK
		q:box(0, 1.5, 0.3, 8, 3, 4.4, cream, "Wood")
		q:box(0, 3.1, 0, 8.4, 0.2, 5.4, WOOD, "Wood")
		for _, x in { -2.7, 0, 2.7 } do
			q:box(x, 1.65, -1.95, 0.2, 2.3, 0.12, shade(cream, 0.86), "Wood")
		end
		q:box(0, 0.25, -1.95, 8, 0.5, 0.12, wood, "Wood")
		for _, sx in { -1, 1 } do
			for _, z in { -2.4, 2.4 } do
				q:cyl(sx * 3.85, 4.5, z, 2.8, 0.3, "y", wood, "Wood")
			end
		end
		q:box(0, 4.9, 2.4, 7.4, 2.8, 0.15, shade(cream, 0.92), "Wood")
		for _, y in { 4.0, 4.9 } do
			q:box(0, y, 2.15, 7.0, 0.12, 0.4, wood, "Wood")
		end
	end, true)
	stamp(r, "stallAwning", CFrame.identity, function(q)
		local stripe, cream = rgb(212, 114, 102), rgb(250, 246, 236)
		q:box(0, 6.35, 2.55, 8.4, 0.12, 0.2, cream, "Fabric")
		for i = 0, 4 do
			local x = -4.2 + (i + 0.5) * 8.4 / 5
			local col = if i % 2 == 0 then stripe else cream
			q:beam(Vector3.new(x, 6.4, 2.6), Vector3.new(x, 5.25, -4.5), 8.4 / 5, 0.12, col, "Fabric")
			q:box(x, 4.95, -4.66, 8.4 / 5, 0.55, 0.08, col, "Fabric")
		end
	end)
	drawAt(r, CFrame.identity, function(q)
		q:box(0, 5.72, 2.28, 2.0, 0.95, 0.08, rgb(60, 70, 66))
		for i = 0, 2 do
			q:box(-0.15, 5.95 - i * 0.25, 2.22, 1.4 - i * 0.3, 0.07, 0.04, rgb(240, 236, 222))
		end
		for i = 0, 3 do
			q:cyl(-3 + i * 0.6, 4.41, 2.15, 0.7, 0.45, "y", BLOOMS[i % 4 + 1])
			q:cyl(1.6 + i * 0.6, 5.26, 2.15, 0.6, 0.4, "y", rgb(240, 236, 222))
		end
		for i = 0, 2 do
			q:cyl(-2.6, 3.35 + i * 0.12, -1.2, 0.12, 0.6, "y", rgb(240, 236, 222))
		end
		q:box(1.6, 3.4, -1.0, 1.8, 0.4, 1.2, WOOD)
		for i = 0, 3 do
			q:lump(
				CFrame.new(1.05 + i * 0.38, 3.7, -1.0 + (i % 2) * 0.2),
				0.42,
				0.42,
				0.42,
				if i % 2 == 0 then rgb(224, 128, 102) else rgb(234, 196, 112)
			)
		end
		q:box(-0.4, 3.5, -0.6, 0.9, 0.6, 0.6, METAL)
	end)
end

-- The fairground pier: a wide deck out over the water on piles, with railings of posts and rails,
-- lamps down both sides and benches at the end looking out to sea.
M.fairPier = function(r: R)
	r:block(-8, -0.1, -40, 8, 0.48, 2, WOOD, "WoodPlanks")
	r:block(-60, -0.1, -130, 60, 0.4, -40, WOOD, "WoodPlanks")
	local function rail(at: CFrame)
		stamp(r, "pierRail", at, function(q)
			for _, x in { -5, 5 } do
				q:box(x, 1.3, 0, 0.3, 2.6, 0.3, WHITE, "Wood")
			end
			q:box(0, 2.6, 0, 10, 0.22, 0.28, WHITE, "Wood")
			q:box(0, 1.3, 0, 10, 0.16, 0.16, WHITE, "Wood")
			for _, x in { -3, -1, 1, 3 } do
				q:box(x, 1.4, 0, 0.12, 2.3, 0.12, WHITE, "Wood")
			end
		end, true)
	end
	for i = 0, 8 do
		local z = -125 + i * 10
		rail(CFrame.new(-60.15, 0.4, z) * yaw(90))
		rail(CFrame.new(60.15, 0.4, z) * yaw(90))
	end
	for i = 0, 11 do
		rail(CFrame.new(-55 + i * 10, 0.4, -130.15))
	end
	for x = -50, 50, 25 do
		for _, z in { -50, -90, -125 } do
			r:cyl(x, -3, z, 6, 1.2, "y", WOOD_DARK, "Wood")
		end
	end
	for _, z in { -10, -30 } do
		r:cyl(-6, -3, z, 6, 1, "y", WOOD_DARK, "Wood")
		r:cyl(6, -3, z, 6, 1, "y", WOOD_DARK, "Wood")
	end
	-- lamps down both sides, their heads over the deck
	for _, z in { -60, -90, -120 } do
		for _, sx in { -1, 1 } do
			local at = CFrame.new(sx * 57.5, 0.4, z) * yaw(sx * 90)
			stamp(r, "streetLamp", at, lampPost)
			r:glow(r:boxAt(at * CFrame.new(0, 8.4, -2.3), 1, 0.3, 1, rgb(255, 236, 190), "SmoothPlastic"), 16, 1)
		end
	end
	for _, x in { -30, -10, 10, 30 } do
		bench(r, x, -127, 0)
		local last = r.prims[#r.prims]
		last.cf = CFrame.new(0, 0.4, 0) * last.cf
	end
end

-- The lighthouse on its rocks: a striped tower with small windows and a framed door under a
-- hood, a gallery with a railing, the lamp room with its glazing bars under a pointed cap, and a
-- jetty on piles to the beach.
M.lighthouse = function(r: R)
	for _, p in { { -8, -4, 9 }, { 6, -7, 8 }, { 8, 6, 10 }, { -6, 8, 8 }, { 0, 0, 13 } } do
		r:ball(p[1], -1, p[2], p[3], ROCK, "Slate")
	end
	local y = 4
	local diam = 11
	for k = 0, 5 do
		local col = if k % 2 == 0 then WHITE else rgb(204, 100, 90)
		r:cyl(0, y + 2.5, 0, 5, diam, "y", col, "SmoothPlastic")
		y += 5
		diam -= 0.7
	end
	-- small windows up the side facing the town
	for i, wy in { 12, 20, 28 } do
		local rad = (11 - 0.7 * math.floor((wy - 4) / 5)) / 2
		r:block(-0.5, wy, -rad - 0.15, 0.5, wy + 1.4, -rad + 0.4, DARK, "SmoothPlastic")
		r:block(-0.7, wy - 0.2, -rad - 0.3, 0.7, wy, -rad + 0.4, WHITE, "SmoothPlastic")
		local _ = i
	end
	-- the gallery, its railing, the lamp room and the cap
	r:cyl(0, y + 0.3, 0, 0.6, diam + 4, "y", DARK, "Metal")
	drawAt(r, CFrame.new(0, y + 0.6, 0), function(q)
		q:box(0, 0.05, 0, 0.6, 0.1, 0.6, DARK, "Metal")
		for k = 0, 11 do
			local a1, a2 = k / 12 * math.pi * 2, (k + 1) / 12 * math.pi * 2
			local p1 = Vector3.new(math.cos(a1) * 5.1, 1.5, math.sin(a1) * 5.1)
			local p2 = Vector3.new(math.cos(a2) * 5.1, 1.5, math.sin(a2) * 5.1)
			q:box(p1.X, 0.75, p1.Z, 0.14, 1.5, 0.14, DARK, "Metal")
			q:beam(p1, p2, 0.12, 0.12, DARK, "Metal")
		end
	end)
	r:cyl(0, y + 1.5, 0, 1.8, 7.2, "y", WHITE, "SmoothPlastic")
	r:cyl(0, y + 4.2, 0, 3.6, 5.6, "y", GLASS, "Glass")
	drawAt(r, CFrame.new(0, y + 2.4, 0), function(q)
		q:box(0, 0.08, 0, 0.6, 0.16, 0.6, DARK, "Metal")
		for k = 0, 7 do
			local a = k / 8 * math.pi * 2
			q:box(math.cos(a) * 2.85, 1.8, math.sin(a) * 2.85, 0.18, 3.6, 0.18, DARK, "Metal")
		end
		q:cyl(0, 3.65, 0, 0.3, 6.0, "y", DARK, "Metal")
	end)
	r:glow(r:ball(0, y + 4, 0, 3, rgb(255, 240, 180), "Neon"), 40, 2, rgb(255, 236, 190))
	r:cone(0, y + 7.1, 0, 2.6, 7.0, rgb(204, 100, 90), "Metal")
	r:ball(0, y + 8.75, 0, 1.0, DARK, "Metal")
	r:cyl(0, y + 9.4, 0, 1.0, 0.12, "y", DARK, "Metal")
	-- the door, its frame and a hood over it
	r:block(-1.4, 4.05, -5.6, 1.4, 8, -5.3, DOOR, "SmoothPlastic")
	r:block(-1.7, 4, -5.75, -1.4, 8.3, -5.25, WHITE, "SmoothPlastic")
	r:block(1.4, 4, -5.75, 1.7, 8.3, -5.25, WHITE, "SmoothPlastic")
	r:block(-1.7, 8, -5.75, 1.7, 8.3, -5.25, WHITE, "SmoothPlastic")
	r:block(-2.1, 8.6, -6.8, 2.1, 8.85, -5.3, rgb(204, 100, 90), "Metal")
	-- a little jetty to the beach, on piles
	r:block(-2, 0.1, -60, 2, 0.6, -6, WOOD, "WoodPlanks")
	for z = -57, -12, 9 do
		for _, x in { -1.7, 1.7 } do
			r:cyl(x, -1.5, z, 3.4, 0.5, "y", WOOD_DARK, "Wood")
		end
	end
end

M.beachHuts = function(r: R)
	local cols = { rgb(232, 150, 146), rgb(140, 186, 220), rgb(238, 208, 128), rgb(150, 204, 176), rgb(190, 170, 220) }
	for k = 0, 4 do
		house(r, -24 + k * 12, 0, 8, 7, cols[k + 1], WHITE, 0, "hut")
	end
end

M.lifeguard = function(r: R)
	local red = rgb(212, 110, 98)
	for _, p in { { -2, -2 }, { 2, -2 }, { -2, 2 }, { 2, 2 } } do
		r:block(p[1] - 0.3, 0, p[2] - 0.3, p[1] + 0.3, 7, p[2] + 0.3, WHITE, "Wood")
	end
	-- braces crossed between the legs on every side
	for _, s in { -2, 2 } do
		r:beam(Vector3.new(s, 0.6, -2), Vector3.new(s, 6.4, 2), 0.2, 0.2, WHITE, "Wood")
		r:beam(Vector3.new(s, 6.4, -2), Vector3.new(s, 0.6, 2), 0.2, 0.2, WHITE, "Wood")
		r:beam(Vector3.new(-2, 0.6, s), Vector3.new(2, 6.4, s), 0.2, 0.2, WHITE, "Wood")
		r:beam(Vector3.new(-2, 6.4, s), Vector3.new(2, 0.6, s), 0.2, 0.2, WHITE, "Wood")
	end
	-- the hut: windows on three sides, a door at the back where the ramp comes up, a life ring
	r:block(-2.6, 7, -2.6, 2.6, 11, 2.6, red, "WoodPlanks")
	r:block(-2.2, 8.8, -2.65, 2.2, 10.4, -2.6, GLASS, "Glass")
	for _, sx in { -1, 1 } do
		r:block(math.min(sx * 2.6, sx * 2.65), 8.8, -1.6, math.max(sx * 2.6, sx * 2.65), 10.4, 1.6, GLASS, "Glass")
	end
	r:block(-0.9, 7, 2.6, 0.9, 10, 2.68, WHITE, "Wood")
	r:cyl(1.6, 8.2, -2.7, 0.2, 1.2, "z", red, "SmoothPlastic")
	r:cyl(1.6, 8.2, -2.82, 0.06, 0.6, "z", WHITE, "SmoothPlastic")
	r:block(-3, 11, -3, 3, 11.6, 3, WHITE, "SmoothPlastic")
	-- a flag on the roof
	r:cyl(2.5, 13.3, -2.5, 3.4, 0.12, "y", METAL, "Metal")
	r:block(2.47, 13.6, -2.44, 2.53, 14.8, -0.7, rgb(224, 128, 102), "Fabric")
	-- the ramp up, with a handrail either side
	r:ramp(-1.2, 0, 3, 1.2, 7, 12, false, WOOD, "WoodPlanks")
	for _, x in { -1.2, 1.2 } do
		r:beam(Vector3.new(x, 2.5, 11.75), Vector3.new(x, 9.4, 3), 0.14, 0.14, WHITE, "Wood")
		r:block(x - 0.1, 0, 11.6, x + 0.1, 2.5, 11.8, WHITE, "Wood")
	end
end

function CityModels.prims(name: string): { any }?
	local build = M[name]
	if not build then
		-- "lot:<w>x<d>:<kind>:<margin>"
		local w, d, kind, margin = name:match("^lot:(%d+)x(%d+):(%a+):(%d+)$")
		if w then
			build =
				CityModels.lot(tonumber(w) :: number, tonumber(d) :: number, kind :: string, tonumber(margin) :: number)
		end
	end
	if not build then
		return nil
	end
	local r = Recipe.new(WHITE, WHITE)
	build(r)
	return r.prims
end

return CityModels
