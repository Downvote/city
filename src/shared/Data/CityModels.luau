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
			q:box(0, 1.8 + i * 0.5, 0.6, 4, 0.3, 0.12, WOOD, "Wood")
		end
		for _, sx in { -1, 1 } do
			local ex = sx * 1.7
			q:box(ex, 0.56, -0.5, 0.16, 1.12, 0.16, DARK, "Wood")
			q:box(ex, 1.28, 0.5, 0.16, 2.56, 0.16, DARK, "Wood")
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
		local spots = { { -1.35, -1.3, 0.9 }, { 0.2, -1.45, 1.25 }, { 1.4, -1.1, 0.75 }, { 1.4, 0.6, 1.1 }, { -0.4, 1.4, 0.8 }, { -1.45, 0.4, 1.3 } }
		for i, s in spots do
			sprig(q, s[1], 1.12, s[2], s[3], BLOOMS[(i - 1) % 4 + 1], LEAVES[(i - 1) % 3 + 1])
		end
		for i, s in { { -2.0, 0.9 }, { 0.8, -2.0 }, { 2.0, -0.4 }, { -0.9, 2.0 } } do
			q:lump(CFrame.new(s[1], 0.98, s[2]) * CFrame.Angles(0.4, i, 0.3), 0.9, 0.7, 0.8, LEAVES[i % 3 + 1])
		end
	end)
	r:lump(at * CFrame.new(0.1, 2.0, 0.1) * CFrame.Angles(0.2, 0.6, 0.1), 2.5, 2.1, 2.4, LEAF, "SmoothPlastic").name = "Leaf"
end

-- A flower bed in a stone edging, 5.2 by 2: soil, plants of three heights and two low mounds.
local function flowerBed(r: R, at: CFrame)
	stamp(r, "flowerBed", at, function(q)
		for _, s in { -1, 1 } do
			q:box(0, 0.15, s * 0.9, 5.2, 0.3, 0.2, rgb(206, 200, 188))
			q:box(s * 2.5, 0.15, 0, 0.2, 0.3, 1.6, rgb(206, 200, 188))
		end
		q:box(0, 0.11, 0, 4.8, 0.22, 1.6, SOIL)
		local spots = { { -1.9, -0.3, 0.75 }, { -1.1, 0.35, 1.05 }, { -0.3, -0.35, 0.6 }, { 0.5, 0.3, 0.95 }, { 1.25, -0.3, 0.7 }, { 1.95, 0.3, 1.0 } }
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
-- grid starts at, the wall's face at z = 0 and the street toward -z): slim mullions the whole
-- height, a broader one every third, and a sill under every floor's band of windows.
local function towerGrid(q: R, len: number, floors: number, fh: number, trim: Color3)
	local n = math.max(2, math.floor((len - 2) / 3.5))
	local step = (len - 2) / n
	local top = floors * fh
	for i = 1, n - 1 do
		local x = -len / 2 + 1 + i * step
		if i % 3 == 0 then
			q:box(x, top / 2, -0.15, 0.5, top, 0.3, trim)
		else
			q:box(x, top / 2, -0.11, 0.16, top, 0.22, trim)
		end
	end
	for k = 0, floors - 1 do
		q:box(0, k * fh + 0.98, -0.17, len - 1.4, 0.26, 0.34, trim)
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
		local faces = {
			{ w, CFrame.new(0, 0, -d / 2) },
			{ w, CFrame.new(0, 0, d / 2) * yaw(180) },
			{ d, CFrame.new(w / 2, 0, 0) * yaw(-90) },
			{ d, CFrame.new(-w / 2, 0, 0) * yaw(90) },
		}
		for c = 0, halves - 1 do
			for _, face in faces do
				local len = face[1] :: number
				stamp(
					r,
					string.format("towerGrid:%g:%d:%s", len, per, trim:ToHex()),
					CFrame.new(0, g + c * per * fh, 0) * (face[2] :: CFrame),
					function(q)
						towerGrid(q, len, per, fh, trim)
					end
				)
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
		stamp(r, "waterTank", CFrame.new(-w / 2 + 6, h + 1, d / 2 - 6), waterTank, true)
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
				r:glow(r:ball(math.cos(a) * pad / 2, h + 1.75, math.sin(a) * pad / 2, 0.5, rgb(255, 214, 120), "Neon"), 0)
			end
		elseif top == "spire" then
			-- a crown of three steps, each under a cap, and the mast with its light
			local steps = { { w / 3, 1, 5 }, { w / 4, 5, 7.6 }, { w / 6, 7.6, 9.8 } }
			for i, st in steps do
				local hw = st[1] :: number
				r:block(-hw, h + st[2], -hw, hw, h + st[3] - 0.3, hw, if i == 2 then shade(spec.wall, 0.86) else spec.wall, "SmoothPlastic")
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
				local leaf = r:lump(CFrame.new(sx * w / 5, h + 2.8, d / 4) * CFrame.Angles(0.2, sx, 0.1), 3.6, 2.8, 3.2, LEAF_DARK)
				leaf.name = "Leaf"
				r:lump(CFrame.new(sx * (w / 5 + 2.2), h + 2.1, d / 4 - 1.6) * CFrame.Angles(0, sx * 2, 0.2), 2, 1.5, 1.8, LEAF).name =
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
		-- a stud proud of the wall, from over the awning up to the flower boxes.
		local fascia =
			r:block(-w / 2 + 0.6, 7.65, -d / 2 - 1, w / 2 - 0.6, 9.42, -d / 2, spec.sign or awning, "SmoothPlastic")
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
				-- a frame round each window, and a sill with a flower box under it
				r:block(x - 1.4, y1 + 2.4, -d / 2 - 0.2, x + 1.4, y1 + 2.7, -d / 2, trim, "SmoothPlastic")
				r:block(x - 1.5, y1 - 0.5, -d / 2 - 0.7, x + 1.5, y1, -d / 2, trim, "SmoothPlastic")
				local flowers = if c % 2 == 0 then rgb(238, 146, 160) else rgb(238, 204, 118)
				r:block(x - 1.3, y1, -d / 2 - 0.6, x + 1.3, y1 + 0.5, -d / 2 - 0.15, flowers, "SmoothPlastic")
			end
			r:block(-w / 2 - 0.1, y1, -d / 2 + 1, -w / 2, y1 + 2.4, d / 2 - 1, GLASS, "Glass")
			r:block(w / 2, y1, -d / 2 + 1, w / 2 + 0.1, y1 + 2.4, d / 2 - 1, GLASS, "Glass")
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
		r:block(w / 2 - 7, h + 0.3, d / 2 - 6, w / 2 - 3, h + 1.9, d / 2 - 2.5, METAL, "Metal")
		r:cyl(-w / 2 + 4, h + 1.1, d / 2 - 4, 1.6, 1.2, "y", METAL, "Metal")
		r:block(-w / 2 + 7, h + 0.3, d / 2 - 3, -w / 2 + 9, h + 3, d / 2 - 1.4, rgb(188, 130, 110), "Brick")
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
		-- chimney's cap, a hood over the door on brackets, and a window in each end wall
		stamp(r, string.format("houseTrim:%gx%g", w, d), CFrame.identity, function(q)
			for _, s in { -1, 1 } do
				q:box(0, roofY(z0) - 0.2, s * (z0 - 0.075), w + 1, 0.4, 0.15, WHITE)
				q:beam(
					Vector3.new(s * (hx - 0.075), roofY(z0) - 0.22, -z0),
					Vector3.new(s * (hx - 0.075), ridge - 0.22, 0),
					0.15,
					0.4,
					WHITE
				)
				q:beam(
					Vector3.new(s * (hx - 0.075), roofY(z0) - 0.22, z0),
					Vector3.new(s * (hx - 0.075), ridge - 0.22, 0),
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
				-- a bracket under each end of the hood
				q:beam(Vector3.new(s * 1.55, 6.1, -d / 2), Vector3.new(s * 1.55, 6.82, -d / 2 - 0.8), 0.12, 0.12, WHITE)
			end
			q:box(0, ridge + t * math.sqrt(1 - sin * sin), 0, w + 1, 0.26, 2 * t * sin + 0.36, WHITE)
			q:box(w / 4, h + rh * 0.9 + 1.8, d / 5, 1.7, 0.2, 1.7, WHITE)
			q:box(0, 6.94, -d / 2 - 0.5, 3.8, 0.18, 1.0, WHITE)
			q:box(0, 6.82, -d / 2 - 0.94, 3.8, 0.3, 0.12, WHITE)
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

-- A low poly tree: an eight sided trunk under a crown of faceted lumps, each a different green and
-- turned its own way (Build/LowPoly cuts the shapes).
local function lowTree(r: R, x: number, y: number, z: number, s: number)
	r:cyl(x, y + 2 * s, z, 4 * s, 1.1 * s, "y", BARK, "Wood")
	-- (every clump is named Leaf: the client sways each one in the wind, World/Ambience)
	local clumps = {
		{ 0, 5.2, 0, 6.4, 5, 6, 1, 0.2, 0.6, 0.1 },
		{ 1.9, 6.4, -0.9, 4.6, 3.8, 4.4, 1.1, 0.5, 1.3, 0.3 },
		{ -1.8, 6, 1.1, 4.8, 4, 4.6, 0.88, -0.3, 2.2, 0.4 },
		{ 0.2, 7.9, 0.5, 3.8, 3, 3.6, 1.2, 0.4, 0.2, -0.5 },
	}
	for _, c in clumps do
		local leaf = r:lump(
			CFrame.new(x + c[1] * s, y + c[2] * s, z + c[3] * s) * CFrame.Angles(c[8], c[9], c[10]),
			c[4] * s,
			c[5] * s,
			c[6] * s,
			shade(LEAF, c[7])
		)
		leaf.name = "Leaf"
	end
end
CityModels.lowTree = lowTree

-- A low poly pine: a trunk under three stacked cones, each a little smaller and turned a little.
local function lowPine(r: R, x: number, y: number, z: number, s: number)
	r:cyl(x, y + 1.3 * s, z, 2.6 * s, 0.9 * s, "y", BARK, "Wood")
	local tiers = { { 4.3, 4.6, 6.4, 1 }, { 6.5, 4, 5, 1.08 }, { 8.7, 3.6, 3.4, 1.16 } }
	for i, t in tiers do
		local cone = r:cone(x, y + t[1] * s, z, t[2] * s, t[3] * s, shade(LEAF_DARK, t[4]))
		cone.cf = cone.cf * CFrame.Angles(0, math.rad(i * 22.5), 0)
		cone.name = "Leaf"
	end
end
CityModels.lowPine = lowPine

M.lowTree = function(r: R)
	lowTree(r, 0, 0, 0, 1)
end
M.lowTreeBig = function(r: R)
	lowTree(r, 0, 0, 0, 1.4)
end
M.lowPine = function(r: R)
	lowPine(r, 0, 0, 0, 1)
end
M.lowPineBig = function(r: R)
	lowPine(r, 0, 0, 0, 1.5)
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
			r:block(-hw, 0, hd - 1.5, hw, 2.2, hd, hedge, "SmoothPlastic")
			r:block(-hw, 0, -hd, -hw + 1.5, 2.2, hd - 1.5, hedge, "SmoothPlastic")
			r:block(hw - 1.5, 0, -hd, hw, 2.2, hd - 1.5, hedge, "SmoothPlastic")
			r:block(-hw + 1.5, 0, -hd, -4, 2.2, -hd + 1.5, hedge, "SmoothPlastic")
			r:block(4, 0, -hd, hw - 1.5, 2.2, -hd + 1.5, hedge, "SmoothPlastic")
			r:block(-2.6, 0.16, -hd, 2.6, 0.22, -hd + margin, rgb(232, 226, 214), "Pavement")
			for _, sx in { -1, 1 } do
				-- gate posts either side of the path, with a lamp on each
				gatePost(r, sx * 3.3, -hd + 0.4)
				-- round shrubs in the back corners (no trees this close to a road)
				r:ball(sx * (hw - 4), 1.6, hd - 4, 4, LEAF, "SmoothPlastic").name = "Leaf"
				r:ball(sx * (hw - 6.4), 1.1, hd - 3.4, 2.6, shade(LEAF, 1.14), "SmoothPlastic").name = "Leaf"
				-- a flower bed either side of the path
				flowerBed(r, CFrame.new(sx * 6, 0.16, -hd + 3) * (if sx < 0 then yaw(180) else CFrame.identity))
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
M.streetLamp = function(r: R)
	stamp(r, "streetLamp", CFrame.identity, function(q)
		q:box(0, 0.25, 0, 0.5, 0.5, 0.5, DARK, "Metal")
		q:cyl(0, 0.62, 0, 0.24, 0.44, "y", DARK, "Metal")
		q:cyl(0, 4.8, 0, 8.4, 0.3, "y", DARK, "Metal")
		q:cyl(0, 2.6, 0, 0.18, 0.42, "y", DARK, "Metal")
		q:box(0, 8.82, -1.1, 0.22, 0.2, 2.6, DARK, "Metal")
		q:beam(Vector3.new(0, 7.7, -0.1), Vector3.new(0, 8.72, -1.5), 0.12, 0.12, DARK, "Metal")
		q:box(0, 8.8, -2.3, 1.4, 0.3, 1.4, DARK, "Metal")
		q:box(0, 8.6, -2.3, 1.2, 0.1, 1.2, shade(DARK, 1.3), "Metal")
	end)
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
	-- the tall sign blade on the corner
	local corner = r:block(w / 2 - 3, 7, -d / 2 - 2.5, w / 2 - 1.8, h + 8, -d / 2 + 0.5, rgb(255, 110, 120), "Neon")
	sign(r:glow(corner, 0), "cinema", "blade")
	-- poster frames
	for _, x in { -w / 2 + 4, w / 2 - 8 } do
		advert(r:block(x, 9.5, -d / 2 - 0.2, x + 4, 13, -d / 2, rgb(224, 186, 110), "SmoothPlastic"), "Front", "film")
	end
	r:block(-w / 2 - 0.4, h, -d / 2 - 0.4, w / 2 + 0.4, h + 1, d / 2 + 0.4, rgb(204, 178, 130), "SmoothPlastic")
	-- and its name on the roof
	sign(roofBoard(r, 13, h + 1, 4, -d / 2 + 1.2, rgb(200, 110, 120)), "cinema", "roof", "Front")
	-- what's coming, big, down both side walls
	for _, sx in { -1, 1 } do
		for _, z in { -12, 2 } do
			local poster = r:block(sx * w / 2, 3, z, sx * (w / 2 + 0.2), 12, z + 8, rgb(224, 186, 110), "SmoothPlastic")
			advert(poster, if sx > 0 then "Right" else "Left", "film")
		end
	end
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
	-- a way through to the platform at the back
	-- the ceiling and the long pitched roof over it, with a clock gable over the doors
	local roof = rgb(110, 140, 168)
	r:block(-w / 2 - 1, h, -d / 2 - 1, w / 2 + 1, h + 0.5, d / 2 + 1, WHITE, "SmoothPlastic")
	r:wedge(CFrame.new(0, h + 3, -d / 4 - 0.5), w + 4, 5, d / 2 + 1, roof, "RoofShingles")
	r:wedge(CFrame.new(0, h + 3, d / 4 + 0.5) * CFrame.Angles(0, math.pi, 0), w + 4, 5, d / 2 + 1, roof, "RoofShingles")
	r:block(-5, h + 0.5, -d / 2 - 1.6, 5, h + 8, -d / 2 - 0.6, wall, "SmoothPlastic")
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
	-- the platform and the line behind, with a train waiting
	r:block(-w / 2 - 10, 0, d / 2, w / 2 + 10, 1.2, d / 2 + 12, STONE, "SmoothPlastic")
	r:block(-w / 2 - 10, 1.2, d / 2 + 11, w / 2 + 10, 1.3, d / 2 + 12, rgb(232, 204, 120), "SmoothPlastic")
	for _, z in { d / 2 + 15.5, d / 2 + 20.5 } do
		r:block(-w / 2 - 30, 0.1, z - 0.3, w / 2 + 30, 0.6, z + 0.3, METAL, "Metal")
	end
	local carriage = rgb(88, 134, 180)
	for k = 0, 2 do
		local x = -40 + k * 30
		r:block(x - 13, 1, d / 2 + 13.5, x + 13, 8, d / 2 + 22.5, carriage, "SmoothPlastic")
		r:block(x - 12, 4.4, d / 2 + 13.38, x + 12, 6.6, d / 2 + 13.5, GLASS, "Glass")
		r:block(x - 13.1, 7.6, d / 2 + 13.4, x + 13.1, 8.4, d / 2 + 22.6, WHITE, "SmoothPlastic")
	end
	r:wedge(CFrame.new(51.5, 4.5, d / 2 + 18) * CFrame.Angles(0, math.rad(-90), 0), 9, 7, 5, carriage, "SmoothPlastic")
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
	r:block(-25, 0.3, 3, 25, 0.34, 6, rgb(236, 226, 204), "Pavement")
	r:block(-2.5, 0.3, 3, 2.5, 0.34, 8.5, rgb(236, 226, 204), "Pavement")
	for _, p in { { -19, -3.5, 1.05 }, { -8, -4.5, 0.95 }, { 8, -4.5, 1 }, { 19, -3.5, 1.1 } } do
		lowTree(r, p[1], 0.3, p[2], p[3])
	end
	for i, x in { -13.5, 0, 13.5 } do
		r:block(x - 3, 0.3, -1.4, x + 3, 0.55, 1.4, rgb(124, 92, 66), "Ground")
		for k = 0, 3 do
			local col = ({ rgb(240, 148, 164), rgb(240, 206, 118), rgb(250, 246, 236), rgb(184, 160, 222) })[(i + k) % 4 + 1]
			r:ball(x - 2.1 + k * 1.4, 0.85, 0, 1.1, col)
		end
	end
	for _, x in { -16, -6, 6, 16 } do
		bench(r, x, 7.2, 180)
	end
end

-- A car park: grey tarmac and white bay lines.
M.carPark = function(r: R)
	r:block(-50, 0, -30, 50, 0.22, 30, rgb(140, 146, 158), "SmoothPlastic")
	for x = -45, 45, 10 do
		for _, z in { -28, 10 } do
			r:block(x - 0.2, 0.22, z, x + 0.2, 0.25, z + 18, WHITE, "SmoothPlastic")
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
	-- a clock tower over the middle, with a bell under its roof
	r:block(-6, 13.4, -10, 6, 24, 2, wall, "SmoothPlastic")
	r:wedge(CFrame.new(0, 26, -7), 13, 4, 6, rgb(194, 126, 99), "SmoothPlastic")
	r:wedge(CFrame.new(0, 26, -1) * CFrame.Angles(0, math.pi, 0), 13, 4, 6, rgb(194, 126, 99), "SmoothPlastic")
	r:cyl(0, 20, -10.2, 0.4, 6, "z", WHITE, "SmoothPlastic")
	r:cyl(0, 20, -10.45, 0.2, 4.4, "z", DARK, "SmoothPlastic")
	r:block(-0.15, 20, -10.6, 0.15, 22, -10.45, WHITE, "SmoothPlastic")
	r:block(-0.15, 19.85, -10.6, 1.4, 20.15, -10.45, WHITE, "SmoothPlastic")
end

-- A sports field: a pitch with lines and goals, a running track round it and seats along a side.
M.sportsField = function(r: R)
	r:block(-60, 0, -36, 60, 0.25, 36, rgb(200, 134, 112), "SmoothPlastic")
	r:block(-50, 0.25, -28, 50, 0.3, 28, rgb(132, 184, 104), "SmoothPlastic")
	for _, line in
		{
			{ -48, -26.4, 48, -26 },
			{ -48, 26, 48, 26.4 },
			{ -48.4, -26, -48, 26 },
			{ 48, -26, 48.4, 26 },
			{ -0.2, -26, 0.2, 26 },
		}
	do
		r:block(line[1], 0.3, line[2], line[3], 0.34, line[4], WHITE, "SmoothPlastic")
	end
	for _, sx in { -1, 1 } do
		local x = sx * 47
		r:block(x - 0.3, 0.3, -5, x + 0.3, 4.5, -4.4, WHITE, "SmoothPlastic")
		r:block(x - 0.3, 0.3, 4.4, x + 0.3, 4.5, 5, WHITE, "SmoothPlastic")
		r:block(x - 0.3, 4.5, -5, x + 0.3, 5.1, 5, WHITE, "SmoothPlastic")
	end
	for k = 0, 2 do
		r:block(
			-36,
			0,
			38 + k * 2,
			36,
			1 + k * 1.2,
			40 + k * 2,
			if k % 2 == 0 then rgb(96, 138, 176) else WHITE,
			"SmoothPlastic"
		)
	end
end

M.clinic = function(r: R)
	CityModels.shop({
		kind = "clinic",
		w = 46,
		d = 28,
		floors = 3,
		wall = WHITE,
		awning = rgb(92, 158, 148),
		cols = 7,
		ads = false,
	})(r)
	-- the cross on the front
	r:block(-1.6, 18.6, -14.6, 1.6, 24.6, -14.2, rgb(214, 96, 96), "SmoothPlastic")
	r:block(-4.6, 20, -14.6, 4.6, 23.2, -14.2, rgb(214, 96, 96), "SmoothPlastic")
	-- a canopy over the ambulance bay on the side, with the ambulance under it
	r:block(23, 8.4, -12, 33, 9, 4, rgb(92, 158, 148), "SmoothPlastic")
	for _, z in { -11, 3 } do
		r:block(32.4, 0, z - 0.3, 33, 8.4, z + 0.3, WHITE, "SmoothPlastic")
	end
	car(r, 28, 0.1, -4, 0, WHITE)
	r:block(26, 2.6, -8.4, 30, 5.6, -1, WHITE, "SmoothPlastic")
	r:block(27.4, 3.6, -8.5, 28.6, 4.6, -8.4, rgb(214, 96, 96), "SmoothPlastic")
	r:glow(r:block(27.6, 5.6, -6, 28.4, 6, -5, rgb(90, 160, 255), "SmoothPlastic"), 0)
end

M.library = function(r: R)
	local wall = rgb(206, 144, 120)
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
	-- tall windows along the front, each with a stone sill and a keystone over it
	for x = -22, 22, 8.8 do
		if math.abs(x) > 4 then
			lit(r, r:block(x - 1.6, 2.4, -14.15, x + 1.6, 10, -14, GLASS, "Glass"))
			r:block(x - 2, 2, -14.5, x + 2, 2.4, -14, WHITE, "SmoothPlastic")
			r:block(x - 0.6, 10, -14.3, x + 0.6, 10.9, -14, WHITE, "SmoothPlastic")
		end
	end
	r:block(-29, 12, -15, 29, 13.2, 15, WHITE, "SmoothPlastic")
	-- the name over the door on a stone band, and a lamp either side
	r:block(-7, 8.4, -14.5, 7, 10.4, -14, WHITE, "SmoothPlastic")
	sign(
		r:block(-6.5, 8.65, -14.62, 6.5, 10.15, -14.5, shade(wall, 0.7), "SmoothPlastic"),
		"library",
		"fascia",
		"Front"
	)
	for _, sx in { -1, 1 } do
		r:glow(r:ball(sx * 4.4, 6.4, -14.6, 1, rgb(255, 236, 190), "SmoothPlastic"), 0)
	end
end

M.museum = function(r: R)
	local stone = rgb(244, 240, 230)
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
	-- a low terrace of steps, columns with a base and a cap each, and a pediment over them
	for k = 0, 2 do
		r:block(-24 - k, 0, -24 - k * 1.2, 24 + k, 0.3 - k * 0.1, -14, shade(stone, 0.95), "SmoothPlastic")
	end
	for x = -20, 20, 8 do
		r:cyl(x, 7.1, -20, 13.6, 2.2, "y", WHITE, "SmoothPlastic")
		r:block(x - 1.5, 0.3, -21.5, x + 1.5, 1, -18.5, WHITE, "SmoothPlastic")
		r:block(x - 1.5, 13.2, -21.5, x + 1.5, 13.9, -18.5, WHITE, "SmoothPlastic")
	end
	r:block(-24, 13.9, -22, 24, 15, -14, stone, "SmoothPlastic")
	r:wedge(CFrame.new(-12, 17.5, -18) * CFrame.Angles(0, math.rad(90), 0), 8, 5, 24, stone, "SmoothPlastic")
	r:wedge(CFrame.new(12, 17.5, -18) * CFrame.Angles(0, math.rad(-90), 0), 8, 5, 24, stone, "SmoothPlastic")
	-- banners down the wall either side, and one strung across the columns over the way in
	for _, x in { -25, 25 } do
		sign(r:block(x - 1.4, 4, -14.3, x + 1.4, 11, -14.1, rgb(196, 100, 94), "Fabric"), "museum", "blade", "Front")
	end
	sign(r:block(-11, 9.6, -21.45, 11, 12.4, -21.25, rgb(196, 100, 94), "Fabric"), "museum", "fascia", "Front")
end

M.fireStation = function(r: R)
	local red = rgb(196, 106, 92)
	r:block(-26, 0, -14, 26, 11, 14, red, "Brick")
	for k = -1, 1 do
		local x = k * 15
		r:block(x - 5.5, 0.2, -14.2, x + 5.5, 8, -14, rgb(240, 236, 228), "SmoothPlastic")
		for y = 2, 7, 1.6 do
			r:block(x - 5.5, y, -14.3, x + 5.5, y + 0.15, -14.2, rgb(196, 200, 210), "SmoothPlastic")
		end
	end
	r:block(-27, 11, -15, 27, 12, 15, WHITE, "SmoothPlastic")
	-- its name over the bay doors
	sign(r:glow(r:block(-12, 8.5, -14.35, 12, 10.5, -14, WHITE, "SmoothPlastic"), 0), "fire", "fascia", "Front")
	-- the hose tower
	r:block(20, 11, 4, 28, 26, 12, red, "SmoothPlastic")
	r:block(19.5, 26, 3.5, 28.5, 27, 12.5, WHITE, "SmoothPlastic")
	-- a fire engine out front
	local fx, fz = -15, -22
	r:block(fx - 4, 1.2, fz - 7, fx + 4, 5.4, fz + 5, red, "SmoothPlastic")
	r:block(fx - 4, 1.2, fz - 10, fx + 4, 6, fz - 7, red, "SmoothPlastic")
	r:block(fx - 3.6, 3.6, fz - 10.1, fx + 3.6, 5.4, fz - 10, GLASS, "Glass")
	r:block(fx - 3, 5.4, fz - 5, fx + 3, 5.9, fz + 4, METAL, "Metal")
	for _, wx in { -4.2, 4.2 } do
		for _, wz in { -8, 3 } do
			r:cyl(fx + wx, 1.2, fz + wz, 0.8, 2.4, "x", DARK, "SmoothPlastic")
		end
	end
end

-- A row of four little houses, each with a garden hedge and a shrub.
M.houseRow = function(r: R)
	local walls = { rgb(240, 205, 176), rgb(204, 221, 234), rgb(243, 223, 166), rgb(207, 226, 208) }
	local roofs = { rgb(79, 138, 140), rgb(194, 126, 99), rgb(110, 140, 168), rgb(184, 102, 92) }
	for k = 0, 3 do
		local x = -27 + k * 18
		house(r, x, 0, 13, 11, walls[k + 1], roofs[k + 1], 0)
		r:block(x - 8, 0, -9, x + 8, 1.2, -8.2, LEAF_DARK, "SmoothPlastic")
		-- a shrub in each back garden (no trees this close to the road)
		r:ball(x + 6, 1.3, 6, 3, LEAF, "SmoothPlastic")
		r:ball(x + 4.4, 0.9, 6.6, 2, shade(LEAF, 1.15), "SmoothPlastic")
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

-- A park with a pond, a little bridge, trees and benches.
M.pondPark = function(r: R)
	r:block(-110, 0, -42, 110, 0.3, 42, rgb(136, 190, 108), "SmoothPlastic")
	r:cyl(-10, 0.32, 0, 0.1, 64, "y", rgb(214, 210, 196), "SmoothPlastic")
	r:cyl(-10, 0.36, 0, 0.12, 58, "y", WATER, "SmoothPlastic")
	-- the bridge across
	r:block(-14, 0.4, -32, -6, 1.6, 32, WOOD, "WoodPlanks")
	for _, x in { -14, -6 } do
		r:block(x - 0.3, 1.6, -30, x + 0.3, 3, 30, WOOD_DARK, "Wood")
	end
	-- ducks
	for _, p in { { -30, -8 }, { -26, -12 }, { 10, 10 } } do
		r:ball(p[1], 0.9, p[2], 1.2, WHITE, "SmoothPlastic")
		r:ball(p[1] - 0.7, 1.5, p[2], 0.7, WHITE, "SmoothPlastic")
	end
	for _, p in
		{ { 50, -20 }, { 70, 18 }, { 86, -10 }, { -70, 20 }, { -86, -18 }, { 40, 20 }, { -60, -20 }, { 88, 20 } }
	do
		lowTree(r, p[1], 0.3, p[2], 1.3)
	end
	for _, p in { { 30, -6, 90 }, { 30, 6, 90 }, { -60, 0, -90 } } do
		bench(r, p[1], p[2], p[3])
	end
end

-- A playground: a slide, swings, a roundabout and a sandpit.
M.playground = function(r: R)
	r:block(-40, 0, -30, 40, 0.25, 30, rgb(236, 214, 178), "SmoothPlastic")
	-- the slide: a ladder tower and a chute down
	r:block(-24, 0, -6, -18, 6, 0, rgb(96, 146, 190), "SmoothPlastic")
	r:ramp(-24, 0.25, 0, -18, 6, 14, false, rgb(230, 190, 104), "SmoothPlastic")
	-- swings
	for _, x in { 4, 16 } do
		r:beam(Vector3.new(x - 6, 0, -14), Vector3.new(x - 6, 8, -10), 0.5, 0.5, rgb(212, 114, 102), "SmoothPlastic")
		r:beam(Vector3.new(x + 6, 0, -14), Vector3.new(x + 6, 8, -10), 0.5, 0.5, rgb(212, 114, 102), "SmoothPlastic")
	end
	r:block(-2, 7.8, -10.3, 22, 8.4, -9.7, rgb(212, 114, 102), "SmoothPlastic")
	for _, x in { 1, 7, 13, 19 } do
		r:block(x - 0.9, 2, -10.6, x + 0.9, 2.3, -9.4, DARK, "SmoothPlastic")
	end
	-- the roundabout
	r:cyl(18, 0.7, 14, 0.8, 9, "y", rgb(128, 180, 104), "SmoothPlastic")
	r:cyl(18, 1.9, 14, 2, 1, "y", METAL, "Metal")
	-- a sandpit
	r:block(-32, 0.25, 12, -16, 0.5, 26, rgb(240, 224, 184), "Sand")
end

M.basketCourt = function(r: R)
	r:block(-30, 0, -18, 30, 0.25, 18, rgb(210, 150, 118), "SmoothPlastic")
	r:block(-28, 0.25, -16, 28, 0.28, -15.6, WHITE, "SmoothPlastic")
	r:block(-28, 0.25, 15.6, 28, 0.28, 16, WHITE, "SmoothPlastic")
	r:block(-0.2, 0.25, -16, 0.2, 0.28, 16, WHITE, "SmoothPlastic")
	for _, sx in { -1, 1 } do
		local x = sx * 27
		r:cyl(x + sx * 1.5, 4.5, 0, 9, 0.6, "y", DARK, "Metal")
		r:block(x - 0.2, 8, -3, x + 0.2, 11, 3, WHITE, "SmoothPlastic")
		r:cyl(x - sx * 1.4, 8.6, 0, 0.2, 2.2, "y", rgb(220, 118, 92), "Metal")
	end
end

-- The hills ---------------------------------------------------------------------------------------

M.barn = function(r: R)
	local red = rgb(188, 98, 86)
	r:block(-14, 0, -10, 14, 10, 10, red, "SmoothPlastic")
	r:wedge(CFrame.new(0, 13, -5.25), 30, 6, 10.5, WHITE, "SmoothPlastic")
	r:wedge(CFrame.new(0, 13, 5.25) * CFrame.Angles(0, math.pi, 0), 30, 6, 10.5, WHITE, "SmoothPlastic")
	r:block(-5, 0.2, -10.2, 5, 8, -10, rgb(250, 246, 236), "SmoothPlastic")
	r:beam(Vector3.new(-4.6, 0.6, -10.3), Vector3.new(4.6, 7.6, -10.3), 0.6, 0.15, red, "SmoothPlastic")
	r:beam(Vector3.new(4.6, 0.6, -10.3), Vector3.new(-4.6, 7.6, -10.3), 0.6, 0.15, red, "SmoothPlastic")
	-- the silo beside it
	r:cyl(20, 9, 0, 18, 9, "y", rgb(214, 220, 228), "SmoothPlastic")
	r:ball(20, 18, 0, 9, rgb(124, 150, 180), "SmoothPlastic")
end

-- A windmill: a white tower, a cap and four sails that turn.
M.windmill = function(r: R)
	r:cyl(0, 5, 0, 10, 9, "y", WHITE, "SmoothPlastic")
	r:cyl(0, 12.5, 0, 5, 7, "y", WHITE, "SmoothPlastic")
	r:block(-3.4, 15, -3.4, 3.4, 18, 3.4, rgb(184, 102, 92), "SmoothPlastic")
	r:block(-1.2, 0.2, -4.6, 1.2, 3.6, -4.3, DOOR, "SmoothPlastic")
	local hub = r:cyl(0, 16.5, -4.6, 1.6, 2, "z", WOOD_DARK, "Wood")
	hub.name = "Hub"
	for k = 0, 3 do
		local a = k * math.pi / 2 + math.pi / 4
		local tip = Vector3.new(math.cos(a) * 11, 16.5 + math.sin(a) * 11, -5.2)
		local arm = r:beam(Vector3.new(0, 16.5, -5.2), tip, 0.5, 0.5, WOOD_DARK, "Wood")
		if arm then
			arm.name = "Spin"
		end
		local mid = Vector3.new(math.cos(a) * 6.5, 16.5 + math.sin(a) * 6.5, -5.4)
		local sail = r:boxAt(CFrame.new(mid) * CFrame.Angles(0, 0, a), 8, 2.6, 0.2, rgb(255, 250, 240), "Fabric")
		sail.name = "Spin"
	end
end

-- A field of crop rows inside a low fence.
local function field(r: R, x: number, z: number, w: number, d: number, crop: Color3)
	r:block(x - w / 2, 0, z - d / 2, x + w / 2, 0.3, z + d / 2, rgb(164, 126, 96), "SmoothPlastic")
	local rows = math.floor(d / 5)
	for k = 0, rows - 1 do
		local rz = z - d / 2 + (k + 0.5) * d / rows
		r:block(x - w / 2 + 1, 0.3, rz - 1, x + w / 2 - 1, 1.2, rz + 1, crop, "SmoothPlastic")
	end
	for _, side in { { -1, 0 }, { 1, 0 }, { 0, -1 }, { 0, 1 } } do
		local horizontal = side[2] ~= 0
		local fx, fz = x + side[1] * (w / 2 + 1), z + side[2] * (d / 2 + 1)
		local len = if horizontal then w + 2 else d + 2
		r:box(fx, 1.6, fz, if horizontal then len else 0.3, 0.3, if horizontal then 0.3 else len, WOOD, "Wood")
	end
end

local function cow(r: R, x: number, z: number, yaw: number)
	local f = CFrame.new(x, 0, z) * CFrame.Angles(0, math.rad(yaw), 0)
	r:boxAt(f * CFrame.new(0, 2.4, 0), 2.2, 2, 4, WHITE, "SmoothPlastic")
	r:boxAt(f * CFrame.new(0.6, 2.9, 0.6), 1.2, 1, 1.6, DARK, "SmoothPlastic")
	r:boxAt(f * CFrame.new(0, 3.1, -2.6), 1.6, 1.6, 1.6, WHITE, "SmoothPlastic")
	r:boxAt(f * CFrame.new(0, 2.6, -3.5), 1.2, 0.8, 0.4, rgb(255, 180, 180), "SmoothPlastic")
	for _, lx in { -0.7, 0.7 } do
		for _, lz in { -1.4, 1.4 } do
			r:boxAt(f * CFrame.new(lx, 0.7, lz), 0.5, 1.4, 0.5, DARK, "SmoothPlastic")
		end
	end
end

-- The farm on its plateau (the barn and windmill are their own pieces): fields, hay and cows.
M.farmyard = function(r: R)
	field(r, -60, -40, 46, 34, rgb(226, 200, 124))
	field(r, -60, 10, 46, 34, rgb(130, 182, 104))
	field(r, 0, 50, 46, 30, rgb(218, 166, 116))
	for _, p in { { 30, -20 }, { 36, -14 }, { 26, -12 } } do
		r:cyl(p[1], 1.4, p[2], 3, 2.8, "x", rgb(230, 206, 138), "SmoothPlastic")
	end
	for _, p in { { 50, 20, 30 }, { 60, 30, 200 }, { 44, 36, 120 } } do
		cow(r, p[1], p[2], p[3])
	end
	-- a path of flat stones across the yard
	for k = 0, 8 do
		r:cyl(-20 + k * 7, 0.1, -60 + k * 6, 0.25, 3.4, "y", rgb(222, 214, 196), "SmoothPlastic")
	end
end

-- The lookout: a wooden platform up on posts, with two ramps up to it, a telescope and benches.
M.lookout = function(r: R)
	local deckY = 12
	r:block(-7, deckY - 0.6, -13, 7, deckY, 7, WOOD, "WoodPlanks")
	for _, p in { { -6.5, -12.5 }, { 6.5, -12.5 }, { -6.5, 6.5 }, { 6.5, 6.5 } } do
		r:block(p[1] - 0.6, 0, p[2] - 0.6, p[1] + 0.6, deckY, p[2] + 0.6, WOOD_DARK, "Wood")
	end
	-- railings round the deck (open where the top ramp lands)
	r:block(-7, deckY, 6.6, 7, deckY + 2.6, 7, WOOD_DARK, "Wood")
	r:block(-7, deckY, -13, -6.6, deckY + 2.6, 7, WOOD_DARK, "Wood")
	r:block(-7, deckY, -13, 7, deckY + 2.6, -12.6, WOOD_DARK, "Wood")
	r:block(6.6, deckY, -9, 7, deckY + 2.6, 7, WOOD_DARK, "Wood")
	-- up from the ground on the east side, a landing, and back up to the deck
	r:ramp(7, 0, -9, 11, deckY / 2, 9, true, WOOD, "WoodPlanks")
	r:block(7, deckY / 2 - 0.6, 9, 15, deckY / 2, 13, WOOD, "WoodPlanks")
	r:ramp(11, deckY / 2, -9, 15, deckY, 9, false, WOOD, "WoodPlanks")
	r:block(7, deckY - 0.6, -13, 15, deckY, -9, WOOD, "WoodPlanks")
	r:block(7, deckY / 2, 12.6, 15, deckY / 2 + 2.4, 13, WOOD_DARK, "Wood")
	-- a roof over half the deck
	r:wedge(CFrame.new(0, deckY + 7, -0.5), 16, 3, 7, rgb(194, 126, 99), "SmoothPlastic")
	r:wedge(CFrame.new(0, deckY + 7, 6.5) * CFrame.Angles(0, math.pi, 0), 16, 3, 7, rgb(194, 126, 99), "SmoothPlastic")
	for _, x in { -6.5, 6.5 } do
		r:block(x - 0.3, deckY, 6, x + 0.3, deckY + 5.5, 6.6, WOOD_DARK, "Wood")
	end
	-- the telescope, looking out over the town
	r:cyl(-3, deckY + 1.6, -10, 3.2, 0.4, "y", DARK, "Metal")
	r:boxAt(CFrame.new(-3, deckY + 3.4, -10.6) * CFrame.Angles(math.rad(-18), 0, 0), 0.9, 0.9, 3, METAL, "Metal")
	bench(r, 3, -4, 180)
end

M.observatory = function(r: R)
	r:cyl(0, 4, 0, 8, 18, "y", WHITE, "SmoothPlastic")
	r:ball(0, 8, 0, 17.4, rgb(236, 240, 246), "SmoothPlastic")
	r:boxAt(CFrame.new(0, 12, -6) * CFrame.Angles(math.rad(-38), 0, 0), 3, 9, 1, DARK, "SmoothPlastic")
	r:block(-1.6, 0.2, -9.1, 1.6, 4.6, -8.9, DOOR, "SmoothPlastic")
	for k = 0, 1 do
		r:block(-3 - k, 0, -10.4 - k * 1.2, 3 + k, 0.5 * (2 - k), -9 - k * 1.2, STONE, "SmoothPlastic")
	end
end

M.radioMast = function(r: R)
	r:block(-3, 0, -3, 3, 1, 3, STONE, "SmoothPlastic")
	r:cyl(0, 19, 0, 36, 1, "y", rgb(206, 112, 102), "Metal")
	r:cyl(0, 13, 0, 1, 3, "y", WHITE, "Metal")
	r:cyl(0, 25, 0, 1, 2.4, "y", WHITE, "Metal")
	r:glow(r:ball(0, 37.5, 0, 1.4, rgb(255, 80, 70), "Neon"), 0)
end

local function tent(r: R, x: number, z: number, yaw: number, col: Color3)
	local f = CFrame.new(x, 0, z) * CFrame.Angles(0, math.rad(yaw), 0)
	r:wedge(f * CFrame.new(0, 2, -1.75), 5, 4, 3.5, col, "Fabric")
	r:wedge(f * CFrame.new(0, 2, 1.75) * CFrame.Angles(0, math.pi, 0), 5, 4, 3.5, shade(col, 0.88), "Fabric")
end

-- The campsite in the pines: tents round a fire, a log cabin and a picnic table.
M.camp = function(r: R)
	tent(r, -12, -6, 20, rgb(220, 144, 100))
	tent(r, 6, -14, -30, rgb(96, 142, 186))
	tent(r, 14, 4, 80, rgb(124, 176, 100))
	-- the campfire
	for k = 0, 3 do
		local a = k * math.pi / 2 + 0.4
		r:boxAt(CFrame.new(0, 0.5, 0) * CFrame.Angles(0, a, math.rad(15)), 3, 0.6, 0.6, WOOD_DARK, "Wood")
	end
	r:fire(r:glow(r:ball(0, 1, 0, 1.2, rgb(255, 150, 60), "Neon"), 14, 1.4, rgb(255, 170, 90)))
	for k = 0, 4 do
		local a = k / 5 * math.pi * 2
		r:cyl(math.cos(a) * 6, 0.6, math.sin(a) * 6, 1.2, 1.4, "y", ROCK, "SmoothPlastic")
	end
	house(r, -22, 20, 14, 10, rgb(164, 124, 92), rgb(106, 92, 90), 160)
	-- a picnic table
	r:block(16, 2.4, 18, 22, 2.8, 22, WOOD, "Wood")
	for _, z in { 17, 23 } do
		r:block(16, 1.4, z - 0.5, 22, 1.7, z + 0.5, WOOD, "Wood")
	end
end

-- The waterfront ----------------------------------------------------------------------------------

-- A ferris wheel: two legs either side of the hub, a rim of beams, spokes and cabins.
M.ferrisWheel = function(r: R)
	local R0 = 16
	local hy = R0 + 4
	local col = rgb(212, 114, 102)
	for _, sz in { -2.2, 2.2 } do
		r:beam(Vector3.new(-9, 0, sz), Vector3.new(0, hy, sz), 1, 1, WHITE, "Metal")
		r:beam(Vector3.new(9, 0, sz), Vector3.new(0, hy, sz), 1, 1, WHITE, "Metal")
	end
	local hub = r:cyl(0, hy, 0, 5.4, 2.4, "z", METAL, "Metal")
	hub.name = "Hub"
	local n = 16
	for k = 0, n - 1 do
		local a1, a2 = k / n * math.pi * 2, (k + 1) / n * math.pi * 2
		local p1 = Vector3.new(math.cos(a1) * R0, hy + math.sin(a1) * R0, 0)
		local p2 = Vector3.new(math.cos(a2) * R0, hy + math.sin(a2) * R0, 0)
		local rim = r:beam(p1, p2, 0.8, 1.2, if k % 2 == 0 then col else rgb(232, 198, 118), "SmoothPlastic")
		if rim then
			rim.name = "Spin"
		end
		if k % 2 == 0 then
			local spoke = r:beam(Vector3.new(0, hy, 0), p1, 0.4, 0.4, WHITE, "Metal")
			if spoke then
				spoke.name = "Spin"
			end
			local cabinCol = ({ rgb(100, 146, 192), rgb(128, 180, 104), rgb(232, 192, 110), rgb(172, 142, 206) })[(k / 2) % 4 + 1]
			local c = r:box(p1.X, p1.Y - 2.2, 0, 3, 2.6, 2.6, cabinCol, "SmoothPlastic")
			c.name = "Cabin"
			local roof = r:box(p1.X, p1.Y - 0.7, 0, 3.4, 0.5, 3, WHITE, "SmoothPlastic")
			roof.name = "Cabin"
		end
	end
	r:block(-11, 0, -4, 11, 0.6, 4, STONE, "SmoothPlastic")
end

-- A carousel: a round deck, a striped canopy and horses on poles that go round.
M.carousel = function(r: R)
	r:cyl(0, 0.5, 0, 1, 20, "y", rgb(232, 198, 118), "SmoothPlastic")
	local hub = r:cyl(0, 4, 0, 8, 1.6, "y", rgb(212, 114, 102), "Metal")
	hub.name = "Hub"
	r:cyl(0, 8.4, 0, 0.8, 22, "y", rgb(212, 114, 102), "SmoothPlastic")
	r:cyl(0, 9.2, 0, 0.8, 14, "y", WHITE, "SmoothPlastic")
	r:cyl(0, 10, 0, 0.8, 7, "y", rgb(212, 114, 102), "SmoothPlastic")
	local horses = { WHITE, rgb(244, 204, 216), rgb(204, 224, 240), rgb(244, 226, 176), rgb(214, 236, 214), WHITE }
	for k = 0, 5 do
		local a = k / 6 * math.pi * 2
		local x, z = math.cos(a) * 7, math.sin(a) * 7
		local pole = r:cyl(x, 4.6, z, 7.6, 0.3, "y", rgb(232, 198, 118), "Metal")
		pole.name = "Spin"
		local body = r:boxAt(CFrame.new(x, 3, z) * CFrame.Angles(0, -a, 0), 1, 1.4, 3, horses[k + 1], "SmoothPlastic")
		body.name = "Spin"
		local head = r:boxAt(
			CFrame.new(x, 4, z) * CFrame.Angles(0, -a, 0) * CFrame.new(0, 0, -1.6),
			0.9,
			1.4,
			1,
			horses[k + 1],
			"SmoothPlastic"
		)
		head.name = "Spin"
	end
end

-- A food stall with a striped awning.
M.stall = function(r: R)
	r:block(-4, 0, -2.5, 4, 3, 2.5, WHITE, "SmoothPlastic")
	r:block(-4.2, 3, -2.7, 4.2, 3.2, 2.7, rgb(232, 194, 118), "SmoothPlastic")
	for k = 0, 3 do
		local x = -4 + k * 2
		r:boxAt(
			CFrame.new(x + 1, 5, -3.3) * CFrame.Angles(math.rad(25), 0, 0),
			2,
			0.2,
			3,
			if k % 2 == 0 then rgb(212, 114, 102) else WHITE,
			"Fabric"
		)
	end
	for _, x in { -3.8, 3.8 } do
		r:block(x - 0.2, 3.2, -2.6, x + 0.2, 6, -2.2, WHITE, "SmoothPlastic")
	end
end

-- The fairground pier: a wide deck out over the water on posts, with railings.
M.fairPier = function(r: R)
	r:block(-8, -0.1, -40, 8, 0.4, 2, WOOD, "WoodPlanks")
	r:block(-60, -0.1, -130, 60, 0.4, -40, WOOD, "WoodPlanks")
	for _, x in { -60, 60 } do
		r:block(x - 0.3, 0.4, -130, x + 0.3, 3, -40, WHITE, "SmoothPlastic")
	end
	r:block(-60, 0.4, -130.3, 60, 3, -129.7, WHITE, "SmoothPlastic")
	for x = -50, 50, 25 do
		for _, z in { -50, -90, -125 } do
			r:cyl(x, -3, z, 6, 1.2, "y", WOOD_DARK, "Wood")
		end
	end
	for _, z in { -10, -30 } do
		r:cyl(-6, -3, z, 6, 1, "y", WOOD_DARK, "Wood")
		r:cyl(6, -3, z, 6, 1, "y", WOOD_DARK, "Wood")
	end
end

M.lighthouse = function(r: R)
	-- rocks round the foot
	for _, p in { { -8, -4, 9 }, { 6, -7, 8 }, { 8, 6, 10 }, { -6, 8, 8 }, { 0, 0, 13 } } do
		r:ball(p[1], -1, p[2], p[3], ROCK, "SmoothPlastic")
	end
	local y = 4
	local diam = 11
	for k = 0, 5 do
		local col = if k % 2 == 0 then WHITE else rgb(204, 100, 90)
		r:cyl(0, y + 2.5, 0, 5, diam, "y", col, "SmoothPlastic")
		y += 5
		diam -= 0.7
	end
	r:cyl(0, y + 0.3, 0, 0.6, diam + 4, "y", DARK, "SmoothPlastic")
	r:cyl(0, y + 1.8, 0, 2.4, diam + 3.6, "y", WHITE, "SmoothPlastic")
	r:cyl(0, y + 4, 0, 4.4, diam - 1.6, "y", GLASS, "Glass")
	r:glow(r:ball(0, y + 4, 0, 3, rgb(255, 240, 180), "Neon"), 40, 2, rgb(255, 236, 190))
	r:ball(0, y + 7, 0, diam - 1, rgb(204, 100, 90), "SmoothPlastic")
	r:block(-1.4, 4, -5.6, 1.4, 8, -5.3, DOOR, "SmoothPlastic")
	-- a little jetty to the beach
	r:block(-2, 0.1, -60, 2, 0.6, -6, WOOD, "WoodPlanks")
end

M.beachHuts = function(r: R)
	local cols = { rgb(232, 150, 146), rgb(140, 186, 220), rgb(238, 208, 128), rgb(150, 204, 176), rgb(190, 170, 220) }
	for k = 0, 4 do
		house(r, -24 + k * 12, 0, 8, 7, cols[k + 1], WHITE, 0, "hut")
	end
end

M.lifeguard = function(r: R)
	for _, p in { { -2, -2 }, { 2, -2 }, { -2, 2 }, { 2, 2 } } do
		r:block(p[1] - 0.3, 0, p[2] - 0.3, p[1] + 0.3, 7, p[2] + 0.3, WHITE, "SmoothPlastic")
	end
	r:block(-2.6, 7, -2.6, 2.6, 11, 2.6, rgb(212, 110, 98), "SmoothPlastic")
	r:block(-2.2, 8.8, -2.65, 2.2, 10.4, -2.6, GLASS, "Glass")
	r:block(-3, 11, -3, 3, 11.6, 3, WHITE, "SmoothPlastic")
	r:ramp(-1.2, 0, 3, 1.2, 7, 12, false, WOOD, "WoodPlanks")
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
