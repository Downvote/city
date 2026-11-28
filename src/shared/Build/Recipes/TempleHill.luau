--!strict
-- A long hall under a wooded hill, in the temple look (Catalog.Styles "temple"). The user sent a
-- picture of an old single storey hall below a steep wooded hill, red gates climbing the slope
-- beside it and a pagoda up in the trees, and asked: "Make a scene of the temple like this",
-- having said before: "You are allowed to create more decor and buildings for these scenes, and
-- put them in the ingame build mode if you do create any". So these are what such a place needs
-- that Build mode had nothing for:
--   * a long straight gable roof of grey tiles for a hall 16 deep, in sections, with rafter ends
--     under its eaves, and the gable end to finish it
--   * the hall's walls: dark timber posts and rails over white plaster with a panelled skirt,
--     in three panels (plain, round a window, over a door), tall windows of many small panes
--     (one with curtains behind) and plain board doors
--   * a small gabled porch to stand over a door, a long stone step, an old oil drum
--   * a red gateway, and a row of them for a tunnel of gates
--   * the hill itself: an earth block a storey tall to build a hill up with, a grassy slope, and
--     stone steps climbing a slope between banks
-- Our own designs, after the way such buildings are made, never the picture's place or any one
-- building.
--
-- The hill pieces stand on a floor, so they stack a storey at a time: each is a storey of solid
-- earth (Tuning.Plot.LevelHeight) under a cap of grass as deep as the ground floor's foundation,
-- so a block on the ground has its grass level with the next storey's floor, and one on a storey
-- has its grass round the feet of what stands on the storey over it. A hill block's top is solid,
-- so trees and buildings stand on it; the slopes stand what goes on them on hidden steps under
-- the grass.

local Recipe = require(script.Parent.Parent.Recipe)
local Geometry = require(script.Parent.Parent.Geometry)
local Tuning = require(script.Parent.Parent.Parent.Config.Tuning)
local Colors = require(script.Parent.Parent.Parent.Util.Colors)

type R = Recipe.Recipe
type Prim = Recipe.Prim

local H = Tuning.Plot.LevelHeight

local PLASTER = Color3.fromRGB(240, 236, 226)
local EDGE = Color3.fromRGB(226, 222, 212) -- the plastered ends of the tile rows along an eave
local STONE = Color3.fromRGB(176, 172, 162)
local ROCK = Color3.fromRGB(138, 134, 124)
local IRON = Color3.fromRGB(58, 56, 60)

local function shade(c: Color3, k: number): Color3
	return Colors.shade(c, k)
end

-- Shapes in pieces -------------------------------------------------------------------------------------
--
-- A roof or a hillside is many small shapes. They go into pieces (one mesh each in the game) of at
-- most a piece's worth, each holding a box that isn't turned for the merge to hang the rest on:
-- where a run has none, a speck is set inside the first shape.

local PER = Geometry.PieceMax - 1

local function upright(p: Prim): boolean
	if p.shape ~= "Block" then
		return false
	end
	local _, _, _, a, _, _, _, e, _, _, _, k = p.cf:GetComponents()
	return math.abs(a - 1) < 1e-4 and math.abs(e - 1) < 1e-4 and math.abs(k - 1) < 1e-4
end

local function pieced(r: R, shapes: { Prim }, mat: string, collide: boolean?)
	local i = 1
	while i <= #shapes do
		local chunk: { Prim } = {}
		for j = i, math.min(#shapes, i + PER - 1) do
			table.insert(chunk, shapes[j])
		end
		i += PER
		local has = false
		for _, p in chunk do
			if upright(p) then
				has = true
				break
			end
		end
		if not has then
			local p = chunk[1]
			-- (a wedge's middle lies on its slope: a quarter in from there is inside it)
			local at = if p.shape == "Wedge" then p.cf * Vector3.new(0, -p.size.Y / 4, p.size.Z / 4) else p.cf.Position
			table.insert(chunk, Geometry.box(CFrame.new(at), Vector3.new(0.04, 0.04, 0.04), p.color, mat))
		end
		r:piece(function(q: R)
			for _, p in chunk do
				p.mat = mat
				q:add(p)
			end
		end, collide, mat)
	end
end

local function add(list: { Prim }, p: Prim?)
	if p then
		table.insert(list, p)
	end
end

local function addAll(list: { Prim }, ps: { Prim })
	for _, p in ps do
		table.insert(list, p)
	end
end

-- The long hall's roof ---------------------------------------------------------------------------------
--
-- A straight gable roof over a hall 16 deep (its walls' middles 16 apart, along z), its ridge
-- along x. It stands on the floor of the storey over the hall, that floor being the top of the
-- walls: under its eaves, along each wall's top, a timber plate, a band of plaster and the rafters
-- running out over it with their ends painted pale. The eaves reach EAVE out from the middle.

local WALL = 8.3 -- the walls' outer faces, from the middle
local EAVE = 10.7 -- the eaves' edge
local PITCH = 0.62 -- rise over run
local TILE_T = 0.32 -- the tiles' thickness
local DROP = TILE_T * math.sqrt(1 + PITCH * PITCH) -- from the tiles' face to their underside, straight down

-- the height of the tiles' face at z
local function tileY(z: number): number
	return 0.1 + (EAVE - math.abs(z)) * PITCH
end

-- One stretch of the roof from x0 to x1. `gable` is where the gable wall's outer face stands
-- (nil: no gable in this stretch), past which the roof runs on to x0 as the verge.
local function hallRoof(r: R, x0: number, x1: number, gable: number?)
	local tile, wood = r.c1, r.c2
	local ridge = shade(tile, 0.72)
	local lines = shade(tile, 0.9)
	local tiles: { Prim } = {}
	local timber: { Prim } = {}
	local pale: { Prim } = {}
	local plaster: { Prim } = {}
	local slate: { Prim } = {}
	local up = Vector3.yAxis
	local down = -up
	-- the verge's barge boards stand just past the tiles' ends
	local tx0 = if gable then x0 + 0.1 else x0
	-- the rows of tiles down each slope, and the rafters under them, every 0.8
	local rows: { number } = {}
	local n = math.floor((x1 - tx0) / 0.8 + 1e-6)
	local start = (tx0 + x1) / 2 - (n - 1) * 0.4
	for k = 0, n - 1 do
		table.insert(rows, start + k * 0.8)
	end
	local inner = if gable then gable - 0.12 else x0 -- the plate and the plaster run from here
	for _, s in { 1, -1 } do
		-- the tiles' face, its thickness growing down
		addAll(
			tiles,
			Geometry.quad(
				Vector3.new(tx0, tileY(0), 0),
				Vector3.new(x1, tileY(0), 0),
				Vector3.new(x1, tileY(EAVE), s * EAVE),
				Vector3.new(tx0, tileY(EAVE), s * EAVE),
				TILE_T,
				tile,
				"ClayRoofTiles",
				down
			)
		)
		for _, x in rows do
			-- a row of round tiles down the slope, and its end at the eave
			add(
				tiles,
				Geometry.beam(
					Vector3.new(x, tileY(0.35) + 0.07, s * 0.35),
					Vector3.new(x, tileY(EAVE - 0.04) + 0.07, s * (EAVE - 0.04)),
					0.3,
					0.14,
					lines,
					"ClayRoofTiles"
				)
			)
			add(
				tiles,
				Geometry.box(
					CFrame.new(x, tileY(EAVE) + 0.04, s * (EAVE + 0.06)),
					Vector3.new(0.32, 0.3, 0.16),
					shade(tile, 1.12),
					"ClayRoofTiles"
				)
			)
			-- a rafter under the eave, out from over the wall, its end pale
			local za, zb = WALL - 0.6, EAVE - 0.6
			local ya = tileY(za) - DROP - 0.08 - 0.17
			local yb = tileY(zb) - DROP - 0.08 - 0.17
			add(timber, Geometry.beam(Vector3.new(x, ya, s * za), Vector3.new(x, yb, s * zb), 0.26, 0.34, wood, "Wood"))
			local ye = tileY(zb + 0.3) - DROP - 0.08 - 0.17
			add(
				pale,
				Geometry.beam(
					Vector3.new(x, yb, s * zb),
					Vector3.new(x, ye, s * (zb + 0.3)),
					0.28,
					0.36,
					EDGE,
					"Plaster"
				)
			)
		end
		-- the boards under the eave, from the wall out
		addAll(
			timber,
			Geometry.quad(
				Vector3.new(tx0, tileY(WALL - 0.6) - DROP - 0.01, s * (WALL - 0.6)),
				Vector3.new(x1, tileY(WALL - 0.6) - DROP - 0.01, s * (WALL - 0.6)),
				Vector3.new(x1, tileY(EAVE) - DROP - 0.01, s * EAVE),
				Vector3.new(tx0, tileY(EAVE) - DROP - 0.01, s * EAVE),
				0.08,
				shade(wood, 0.9),
				"Wood",
				down
			)
		)
		-- the fascia across the tiles' ends
		add(
			timber,
			Geometry.span(
				Vector3.new(tx0, tileY(EAVE) - DROP - 0.25, s * (EAVE + 0.02)),
				Vector3.new(x1, tileY(EAVE) - DROP + 0.1, s * (EAVE + 0.2)),
				wood,
				"Wood"
			)
		)
		-- the plate along the wall's top, and the plaster between the rafters over it
		local yTop = tileY(WALL - 0.6) - DROP - 0.09 - 0.34
		add(
			timber,
			Geometry.span(
				Vector3.new(inner, 0, s * (WALL - 0.62)),
				Vector3.new(x1, 0.55, s * (WALL + 0.12)),
				wood,
				"Wood"
			)
		)
		add(
			plaster,
			Geometry.span(
				Vector3.new(inner, 0.55, s * (WALL - 0.62)),
				Vector3.new(x1, yTop, s * (WALL - 0.02)),
				PLASTER,
				"Plaster"
			)
		)
	end
	-- the ridge: a cap of dark tiles along the top with a bead on it
	slate[#slate + 1] = Geometry.span(
		Vector3.new(tx0 - 0.05, tileY(0) - 0.3, -0.5),
		Vector3.new(x1 + 0.04, tileY(0) + 0.5, 0.5),
		ridge,
		"Slate"
	)
	slate[#slate + 1] = Geometry.span(
		Vector3.new(tx0 - 0.05, tileY(0) + 0.5, -0.28),
		Vector3.new(x1 + 0.04, tileY(0) + 0.78, 0.28),
		shade(ridge, 0.9),
		"Slate"
	)
	if gable then
		-- the gable: plaster over the end wall up to the roof, a tie beam across its foot, a king
		-- post up the middle and struts out from it, all a storey's worth over the wall below
		local gx0, gx1 = gable, gable + 0.6
		local under = function(z: number): number
			return tileY(z) - DROP - 0.1
		end
		-- (the triangle is two upright wedges, square to the hall, so nothing of it reaches down
		-- into the end wall under it)
		local yb = under(WALL)
		add(plaster, Geometry.span(Vector3.new(gx0, 0.55, -WALL), Vector3.new(gx1, yb, WALL), PLASTER, "Plaster"))
		for _, s in { 1, -1 } do
			local h = under(0) - yb
			local turn = if s > 0 then CFrame.Angles(0, math.pi, 0) else CFrame.identity
			table.insert(plaster, {
				shape = "Wedge",
				cf = CFrame.new((gx0 + gx1) / 2, yb + h / 2, s * WALL / 2) * turn,
				size = Vector3.new(gx1 - gx0, h, WALL),
				color = PLASTER,
				mat = "Plaster",
			})
		end
		local fx = gable - 0.16
		add(
			timber,
			Geometry.span(Vector3.new(fx, 0, -WALL - 0.12), Vector3.new(gable, 0.55, WALL + 0.12), wood, "Wood")
		)
		local apex = under(0.25) - 0.05
		add(timber, Geometry.span(Vector3.new(fx, 0.55, -0.22), Vector3.new(gable, apex, 0.22), wood, "Wood"))
		local collar = 0.55 + (apex - 0.55) * 0.45
		for _, s in { 1, -1 } do
			local zc = WALL * 0.5
			add(
				timber,
				Geometry.span(
					Vector3.new(fx, collar - 0.16, s * 0.22),
					Vector3.new(gable, collar + 0.16, s * (under(zc) < collar + 0.5 and zc * 0.6 or zc)),
					wood,
					"Wood"
				)
			)
			add(
				timber,
				Geometry.beam(
					Vector3.new(fx + 0.08, 0.7, s * (WALL - 1.6)),
					Vector3.new(fx + 0.08, collar - 0.1, s * 0.4),
					0.16,
					0.26,
					wood,
					"Wood"
				)
			)
			-- the purlins' ends, out under the verge
			for _, zf in { 0.32, 0.62 } do
				local z = WALL * zf
				local y = tileY(z) - DROP - 0.3
				add(
					timber,
					Geometry.span(
						Vector3.new(x0 + 0.25, y - 0.17, s * z - 0.17),
						Vector3.new(gable, y + 0.17, s * z + 0.17),
						shade(wood, 1.06),
						"Wood"
					)
				)
			end
		end
		-- the barge boards down the verge's two edges, and a tall ridge end on the ridge
		for _, s in { 1, -1 } do
			add(
				timber,
				Geometry.beam(
					Vector3.new(x0 + 0.11, tileY(0) - 0.15, 0),
					Vector3.new(x0 + 0.11, tileY(EAVE + 0.2) - 0.15, s * (EAVE + 0.2)),
					0.22,
					0.75,
					wood,
					"Wood"
				)
			)
		end
		slate[#slate + 1] = Geometry.span(
			Vector3.new(x0 - 0.02, tileY(0) - 0.3, -0.62),
			Vector3.new(x0 + 0.5, tileY(0) + 0.95, 0.62),
			shade(ridge, 0.95),
			"Slate"
		)
		local crown =
			Geometry.box(CFrame.new(x0 + 0.27, tileY(0) + 0.95, 0), Vector3.new(0.52, 0.5, 1.0), ridge, "Slate")
		slate[#slate + 1] = crown
	end
	pieced(r, tiles, "ClayRoofTiles", true)
	pieced(r, timber, "Wood", false)
	pieced(r, pale, "Plaster", false)
	pieced(r, plaster, "Plaster", false)
	pieced(r, slate, "Slate", false)
end

-- The hall's walls ---------------------------------------------------------------------------------------
--
-- A panel is four studs of a plain wall's outside a storey high: half a timber post up each side (so
-- panels side by side share a whole one), a panelled skirt of dark boards to the sill, the window
-- band, a head rail, then two bands of plaster under a rail and the top beam. The window panel
-- leaves the window band open for a hall window between its posts; the door panel leaves room for
-- the board doors up to their head.

local SILL = 3.95 -- the skirt's top, the windows' sills
local HEAD = 8.45 -- the windows' heads
local DOOR_H = 6.6

local function panel(r: R, kind: string)
	local wood, plaster = r.c1, r.c2
	local boards = shade(wood, 0.8)
	local woods: { Prim } = {}
	local plasters: { Prim } = {}
	local function b(
		list: { Prim },
		x1: number,
		y1: number,
		z1: number,
		x2: number,
		y2: number,
		z2: number,
		c: Color3,
		m: string
	)
		table.insert(list, Geometry.span(Vector3.new(x1, y1, z1), Vector3.new(x2, y2, z2), c, m))
	end
	local e = 1.72
	-- the half posts, the top beam and the rail under it
	b(woods, -2, 0, 0, -e, H, 0.3, wood, "Wood")
	b(woods, e, 0, 0, 2, H, 0.3, wood, "Wood")
	b(woods, -e, 11.6, 0, e, H, 0.28, wood, "Wood")
	b(woods, -e, 10.5, 0, e, 10.8, 0.2, wood, "Wood")
	b(woods, -e, HEAD, 0, e, HEAD + 0.4, 0.28, wood, "Wood")
	b(plasters, -e, HEAD + 0.4, 0, e, 10.5, 0.06, plaster, "Plaster")
	b(plasters, -e, 10.8, 0, e, 11.6, 0.06, plaster, "Plaster")
	if kind == "door" then
		-- the doors' head, and plaster over it up to the window heads' line
		b(woods, -e, DOOR_H, 0, e, DOOR_H + 0.4, 0.26, wood, "Wood")
		b(plasters, -e, DOOR_H + 0.4, 0, e, HEAD, 0.06, plaster, "Plaster")
	else
		-- the skirt: dark boards in a frame of battens, two panels high and three across, under a
		-- sill that stands out as a ledge
		b(woods, -e, 0, 0, e, 0.35, 0.18, wood, "Wood")
		b(woods, -e, 1.85, 0, e, 2.05, 0.14, wood, "Wood")
		b(woods, -e, SILL - 0.4, 0, e, SILL, 0.36, wood, "Wood")
		for _, x in { -0.58, 0.58 } do
			b(woods, x - 0.06, 0.35, 0, x + 0.06, 1.85, 0.14, wood, "Wood")
			b(woods, x - 0.06, 2.05, 0, x + 0.06, SILL - 0.4, 0.14, wood, "Wood")
		end
		b(woods, -e, 0.35, 0, e, SILL - 0.4, 0.06, boards, "Wood")
		if kind == "plain" then
			b(plasters, -e, SILL, 0, e, HEAD, 0.06, plaster, "Plaster")
			b(woods, -e, 6.1, 0, e, 6.35, 0.16, wood, "Wood")
		end
	end
	pieced(r, woods, "Wood", false)
	pieced(r, plasters, "Plaster", false)
end

-- A tall window of many small panes in a timber frame, for a hole 3.4 by 4.5: two sashes side by
-- side, each two panes across and five up. `curtains` hangs cloth (c2) behind them, part drawn.
local WIN_W, WIN_H = 3.4, 4.5

local function hallWindow(r: R, curtains: boolean)
	local wood = r.c1
	local hw = WIN_W / 2
	local frame: { Prim } = {}
	local function b(x1: number, y1: number, z1: number, x2: number, y2: number, z2: number, c: Color3?)
		table.insert(frame, Geometry.span(Vector3.new(x1, y1, z1), Vector3.new(x2, y2, z2), c or wood, "Wood"))
	end
	b(-hw, 0, -0.16, -hw + 0.12, WIN_H, 0.16)
	b(hw - 0.12, 0, -0.16, hw, WIN_H, 0.16)
	b(-hw + 0.12, WIN_H - 0.12, -0.16, hw - 0.12, WIN_H, 0.16)
	b(-hw + 0.12, 0, -0.16, hw - 0.12, 0.12, 0.16)
	-- the sashes: the left one in front, the right one behind, overlapping at the middle
	local sashes = { { -hw + 0.12, 0.04, 1 }, { -0.04, hw - 0.12, -1 } }
	for _, s in sashes do
		local a, c, side = s[1], s[2], s[3]
		local z0, z1 = if side > 0 then 0.01 else -0.09, if side > 0 then 0.09 else -0.01
		local y0, y1 = 0.12, WIN_H - 0.12
		b(a, y0, z0, a + 0.1, y1, z1, shade(wood, 1.06))
		b(c - 0.1, y0, z0, c, y1, z1, shade(wood, 1.06))
		b(a + 0.1, y0, z0, c - 0.1, y0 + 0.12, z1, shade(wood, 1.06))
		b(a + 0.1, y1 - 0.1, z0, c - 0.1, y1, z1, shade(wood, 1.06))
		local m = (a + c) / 2
		b(m - 0.025, y0 + 0.12, z0, m + 0.025, y1 - 0.1, z1)
		for k = 1, 4 do
			local y = y0 + 0.12 + (y1 - y0 - 0.22) * k / 5
			b(a + 0.1, y - 0.025, z0, c - 0.1, y + 0.025, z1)
		end
		local zm = (z0 + z1) / 2
		r:glass(a + 0.1, y0 + 0.12, zm - 0.006, c - 0.1, y1 - 0.1, zm + 0.006)
	end
	pieced(r, frame, "Wood", false)
	if curtains then
		-- a rod inside, over the window, and the curtains on it in folds, one pulled most of the
		-- way to the side and the other part way
		local cloth = r.c2
		local rod = r:cyl(0, WIN_H - 0.2, -0.42, WIN_W - 0.2, 0.08, "x", IRON, "Metal")
		rod.smooth = true
		local folds: { Prim } = {}
		local function curtain(x0: number, x1: number)
			local n = math.max(2, math.floor((x1 - x0) / 0.26 + 0.5))
			for k = 0, n - 1 do
				local a = x0 + (x1 - x0) * k / n
				local c = x0 + (x1 - x0) * (k + 1) / n
				local deep = k % 2 == 0
				table.insert(
					folds,
					Geometry.span(
						Vector3.new(a, 0.3, if deep then -0.5 else -0.46),
						Vector3.new(c, WIN_H - 0.26, if deep then -0.44 else -0.4),
						if deep then shade(cloth, 0.9) else cloth,
						"Fabric"
					)
				)
			end
		end
		curtain(-hw + 0.1, -0.7)
		curtain(0.55, hw - 0.1)
		pieced(r, folds, "Fabric", false)
	end
end

-- Red gates ----------------------------------------------------------------------------------------------
--
-- A gateway of lacquered timber (c1), its feet and its top beam black (c2): two round posts, a tie
-- beam through them, a short strut, a beam over them, and the top beam over all with its ends
-- turning up. Drawn round (0, 0, z).

local function gate(r: R, z: number)
	local red, black = r.c1, r.c2
	local px = 2.7
	for _, sx in { -1, 1 } do
		local foot = r:cyl(sx * px, 0.3, z, 0.6, 0.76, "y", black, "Wood")
		foot.smooth = true
		local post = r:cyl(sx * px, 4.4, z, 7.6, 0.62, "y", red, "Wood")
		post.smooth = true
		local ring = r:cyl(sx * px, 7.62, z, 0.24, 0.72, "y", red, "Wood")
		ring.smooth = true
	end
	r:piece(function(q: R)
		q:block(-3.35, 6.25, z - 0.17, 3.35, 6.7, z + 0.17, red, "Wood")
		q:block(-0.26, 6.7, z - 0.15, 0.26, 7.74, z + 0.15, red, "Wood")
		q:block(-3.75, 7.74, z - 0.22, 3.75, 8.2, z + 0.22, red, "Wood")
	end, true, "Wood")
	r:piece(function(q: R)
		q:block(-3.2, 8.2, z - 0.32, 3.2, 8.72, z + 0.32, black, "Wood")
		for _, sx in { -1, 1 } do
			q:beam(Vector3.new(sx * 3.15, 8.46, z), Vector3.new(sx * 4.25, 8.62, z), 0.64, 0.52, black, "Wood")
			q:beam(Vector3.new(sx * 4.2, 8.62, z), Vector3.new(sx * 4.6, 8.82, z), 0.62, 0.48, black, "Wood")
		end
	end, true, "Wood")
end

-- The hill -------------------------------------------------------------------------------------------------
--
-- What the hill pieces are made of: earth (c2) with grey rock coming through it and grass (c1) over
-- the top, its edge spilling over. They stand a storey tall (H) from their foot, the grass over that.

local CAP = Tuning.Plot.Foundation -- the grass over the top

-- A little pseudo random sequence, so a piece draws the same every time.
local function seq(seed: number): () -> number
	local s = seed
	return function()
		s = (s * 16807) % 2147483647
		return s / 2147483647
	end
end

-- A frame on a face: x along it, y up, z out of it, at `at`.
local function onFace(at: Vector3, along: Vector3): CFrame
	return CFrame.fromMatrix(at, along, Vector3.yAxis)
end

-- A rock coming out of a face (`f` a frame on it), `w` along it and `h` up, standing out `stand`:
-- a faceted lump, not solid (it reaches past the piece's sides into its neighbour's).
local function rock(r: R, f: CFrame, w: number, h: number, d: number, stand: number, c: Color3)
	r:noCollide(r:lump(f * CFrame.new(0, 0, stand - d / 2) * CFrame.Angles(0.08, 0.1, -0.12), w, h, d, c, "Rock"))
end

-- A clump of grass or a shrub the same way (foliage, so never solid).
local function tuft(r: R, f: CFrame, w: number, h: number, d: number, stand: number, c: Color3)
	r:lump(f * CFrame.new(0, 0, stand - d / 2) * CFrame.Angles(0.1, -0.08, 0.06), w, h, d, c, "Grass")
end

-- The rocks, ferns and ivy on a face `span` across (its middle at `mid`, its foot at y 0) and
-- `tall` high: lumps of rock with grass over and round them, kept inside the face's ends.
local function dress(r: R, rnd: () -> number, mid: Vector3, along: Vector3, span: number, tall: number, n: number)
	local green = r.c1
	local rocky = shade(ROCK, 0.82)
	for k = 1, n do
		local w = 2.4 + rnd() * 1.6
		local room = span / 2 - w / 2 - 0.3
		local u = math.clamp(-span / 2 + span * (k - 0.5) / n + (rnd() - 0.5) * 1.5, -room, room)
		local v = tall * (0.15 + rnd() * 0.55)
		local at = mid + along * u + Vector3.new(0, v, 0)
		rock(r, onFace(at, along), w, w * (0.45 + rnd() * 0.2), 1.4, 0.25, shade(rocky, 0.9 + rnd() * 0.2))
		-- ferns and creeper over it, and a trail of it down the face
		local gw = 1.8 + rnd() * 1.2
		local gu = math.clamp(u + (rnd() - 0.5) * 1.2, -(span / 2 - gw / 2 - 0.3), span / 2 - gw / 2 - 0.3)
		tuft(
			r,
			onFace(mid + along * gu + Vector3.new(0, v + w * 0.3, 0), along),
			gw,
			1.0,
			1.0,
			0.38,
			shade(green, 0.78 + rnd() * 0.2)
		)
		local tw = 1.4 + rnd()
		local tu = math.clamp(u + (rnd() - 0.5) * 3, -(span / 2 - tw / 2 - 0.3), span / 2 - tw / 2 - 0.3)
		local tv = math.min(tall - 1.2, v + 1.5 + rnd() * 2.5)
		tuft(
			r,
			onFace(mid + along * tu + Vector3.new(0, tv, 0), along),
			tw,
			2.2 + rnd() * 1.6,
			0.8,
			0.22,
			shade(green, 0.72 + rnd() * 0.18)
		)
	end
end

-- The grass spilling over a top edge `span` long, its middle at `mid`, standing out a little.
local function rim(r: R, rnd: () -> number, mid: Vector3, along: Vector3, span: number)
	local green = r.c1
	local n = math.max(2, math.floor(span / 3.2 + 0.5))
	local w = span / n + 0.6
	for k = 0, n - 1 do
		local u = -span / 2 + span * (k + 0.5) / n
		u = math.clamp(u, -(span / 2 - w / 2 - 0.05), span / 2 - w / 2 - 0.05)
		local at = mid + along * u + Vector3.new(0, -0.22, 0)
		tuft(r, onFace(at, along), w, 0.7, 1.0, 0.3, shade(green, 0.86 + rnd() * 0.16))
	end
end

-- A hill block: a storey of earth 16 by 16 with a flat top of grass.
local FACES = {
	{ Vector3.new(0, 0, 1), Vector3.new(1, 0, 0) },
	{ Vector3.new(0, 0, -1), Vector3.new(-1, 0, 0) },
	{ Vector3.new(1, 0, 0), Vector3.new(0, 0, -1) },
	{ Vector3.new(-1, 0, 0), Vector3.new(0, 0, 1) },
}

local function hillBlock(r: R)
	local earth = r.c2
	local rnd = seq(7)
	local half = 8
	r:block(-half, 0, -half, half, H, half, earth, "Rock")
	r:block(-half, H, -half, half, H + CAP, half, r.c1, "Grass")
	-- rock and green on every face, grass spilling over every top edge
	for _, f in FACES do
		local out, along = f[1], f[2]
		dress(r, rnd, out * half, along, 2 * half, H, 3)
		rim(r, rnd, out * half + Vector3.new(0, H + CAP, 0), along, 2 * half - 0.4)
	end
end

-- An earth bank from x0 to x1 sloping up from its front (+z, at the foot) to its back (-z, a storey
-- up), grass over the slope, rock in it, and hidden steps under it to stand things on. `ends` says
-- which of its sides (-1, 1) are dressed with rock (a side against steps is plain).
local BANK_STEPS = 8

local function bank(r: R, x0: number, x1: number, ends: { number }, seed: number)
	local earth, green = r.c2, r.c1
	local rnd = seq(seed)
	local w = x1 - x0
	local xm = (x0 + x1) / 2
	local half = 8
	local function yAt(z: number): number
		return (half - z) * H / (2 * half)
	end
	-- the earth, a wedge high at the back
	r:noCollide(r:wedge(CFrame.new(xm, H / 2, 0) * CFrame.Angles(0, math.pi, 0), w, H, 2 * half, earth, "Rock"))
	-- the grass over the slope
	for _, p in
		Geometry.quad(
			Vector3.new(x0, H, -half),
			Vector3.new(x1, H, -half),
			Vector3.new(x1, 0, half),
			Vector3.new(x0, 0, half),
			CAP,
			green,
			"Grass",
			Vector3.yAxis
		)
	do
		r:add(p)
	end
	-- grass along the top edge, up to a hill block's behind it
	r:block(x0, H, -half, x1, H + CAP, -half + 0.6, green, "Grass")
	-- hidden steps under the slope, each under the grass, for what stands on it
	local run = 2 * half / BANK_STEPS
	for k = 2, BANK_STEPS do
		local zf = half - run * (k - 1) -- its front
		local p = r:block(x0 + 0.1, 0, zf - run, x1 - 0.1, yAt(zf), zf, earth, "Rock")
		p.transp = 1
	end
	-- rock, ferns and shrubs on the slope, set into it
	local n = math.max(3, math.floor(w / 2.6))
	local slope = math.atan(H / (2 * half))
	for k = 1, n do
		local sw = 1.6 + rnd() * 1.6
		local x = math.clamp(x0 + w * (k - 0.5) / n + (rnd() - 0.5) * 2, x0 + sw / 2 + 0.3, x1 - sw / 2 - 0.3)
		local z = -half + 1.6 + rnd() * (2 * half - 3.2)
		-- (a frame lying in the slope, z out of it)
		local f = CFrame.new(x, yAt(z), z) * CFrame.Angles(-(math.pi / 2 - slope), 0, 0)
		if rnd() < 0.5 then
			r:noCollide(
				r:lump(
					f * CFrame.new(0, 0, 0.1) * CFrame.Angles(0.1, rnd() * 3, 0.1),
					sw,
					1.4,
					sw * 0.7,
					shade(ROCK, 0.8 + rnd() * 0.15),
					"Rock"
				)
			)
		end
		r:lump(
			f * CFrame.new(0.4, 0.3, 0.5),
			sw * 1.1,
			sw * 0.8,
			1.2 + rnd() * 0.6,
			shade(green, 0.74 + rnd() * 0.24),
			"Grass"
		)
	end
	-- the dressed sides: rock and green on the earth's triangle, grass along the slope's edge
	for _, sx in ends do
		local x = if sx > 0 then x1 else x0
		local along = Vector3.new(0, 0, -sx)
		for k = 1, 2 do
			local z = -half + 3.5 + (k - 1) * 5 + rnd() * 1.5
			local y = yAt(z) * (0.3 + rnd() * 0.25)
			local rw = 2 + rnd()
			rock(r, onFace(Vector3.new(x, y, z), along), rw, 1.6 + rnd(), 1.2, 0.3, shade(ROCK, 0.78 + rnd() * 0.15))
		end
		for k = 0, 3 do
			local z = -half + 2.2 + k * 3.8
			tuft(
				r,
				onFace(Vector3.new(x, yAt(z) - 0.2, z), along),
				3.2,
				0.7,
				0.9,
				0.35,
				shade(green, 0.82 + rnd() * 0.14)
			)
		end
	end
end

-- The pieces ------------------------------------------------------------------------------------------------

local TIMBER_HEX = "54463C"
local TILE_HEX = "8C9494"

local items: { any } = {
	{
		id = "hall_roof",
		name = "Long hall roof",
		cat = "structure",
		style = "temple",
		price = 260,
		place = "floor",
		size = Vector3.new(8, 7.6, 22),
		c1 = TILE_HEX,
		c2 = TIMBER_HEX,
		build = function(r: R)
			-- Eight studs of a straight gable roof of grey tiles (c1) for a hall 16 deep, its ridge
			-- along the hall: stand it on the floor over the hall, in the middle across it, and set
			-- them end to end, a gable end at each end. Rows of round tiles down the slopes, the
			-- rafters' pale ends under the eaves, the timber (c2) plate and plaster along the walls'
			-- tops.
			hallRoof(r, -4, 4, nil)
		end,
	},
	{
		id = "hall_roof_end",
		name = "Long hall roof end",
		cat = "structure",
		style = "temple",
		price = 360,
		place = "floor",
		size = Vector3.new(10, 8, 22),
		c1 = TILE_HEX,
		c2 = TIMBER_HEX,
		build = function(r: R)
			-- The same roof's last eight studs with its gable: its left side (-x) is the end of the
			-- hall, the gable over the end wall (2 in from that side) and the verge running out over
			-- it with barge boards and a tall ridge end
			hallRoof(r, -5, 5, -3.3)
		end,
	},
	{
		id = "hall_panel",
		name = "Hall panel",
		cat = "walldecor",
		style = "temple",
		price = 70,
		place = "wall",
		size = Vector3.new(4, H, 0.4),
		c1 = TIMBER_HEX,
		c2 = "F0ECE2",
		build = function(r: R)
			-- four studs of a hall's outside: dark timber (c1) over white plaster (c2), a panelled
			-- skirt of boards to the sill and plaster above. Hang them side by side along a wall, a
			-- storey high from its floor, every 4 studs from its start
			panel(r, "plain")
		end,
	},
	{
		id = "hall_panel_window",
		name = "Hall window panel",
		cat = "walldecor",
		style = "temple",
		price = 60,
		place = "wall",
		size = Vector3.new(4, H, 0.4),
		c1 = TIMBER_HEX,
		c2 = "F0ECE2",
		build = function(r: R)
			-- the same with the window band left open, for a hall window between its posts
			panel(r, "window")
		end,
	},
	{
		id = "hall_panel_door",
		name = "Hall door panel",
		cat = "walldecor",
		style = "temple",
		price = 50,
		place = "wall",
		size = Vector3.new(4, H, 0.4),
		c1 = TIMBER_HEX,
		c2 = "F0ECE2",
		build = function(r: R)
			-- the same over a pair of board doors: their head, and plaster above
			panel(r, "door")
		end,
	},
	{
		id = "win_hall",
		name = "Hall window",
		cat = "windows",
		style = "temple",
		price = 110,
		place = "opening",
		size = Vector3.new(3.6, 4.7, 1),
		opening = { w = WIN_W, h = WIN_H, sill = SILL },
		c1 = TIMBER_HEX,
		c2 = "EFE8DA",
		build = function(r: R)
			-- two tall sashes of small panes in a dark timber frame (c1), the left one in front
			hallWindow(r, false)
		end,
	},
	{
		id = "win_hall_curtains",
		name = "Hall window with curtains",
		cat = "windows",
		style = "temple",
		price = 130,
		place = "opening",
		size = Vector3.new(3.6, 4.7, 1),
		opening = { w = WIN_W, h = WIN_H, sill = SILL },
		c1 = TIMBER_HEX,
		c2 = "EFE8DA",
		build = function(r: R)
			-- the hall window with curtains (c2) inside, one drawn most of the way back
			hallWindow(r, true)
		end,
	},
	{
		id = "door_hall",
		name = "Board doors",
		cat = "doors",
		style = "temple",
		price = 120,
		place = "opening",
		size = Vector3.new(4, 6.8, 1),
		opening = { w = 3.6, h = DOOR_H, sill = 0 },
		c1 = "4E4038",
		c2 = "3A3A3E",
		build = function(r: R)
			-- Two plain leaves of dark upright boards (c1) with a rail top, middle and foot, in a
			-- timber frame, and an iron ring (c2) on each
			local wood = r.c1
			r:piece(function(q: R)
				for _, sx in { -1, 1 } do
					q:block(sx * 1.64, 0, -0.2, sx * 1.8, DOOR_H, 0.2, shade(wood, 0.9), "Wood")
				end
				q:block(-1.64, DOOR_H - 0.16, -0.2, 1.64, DOOR_H, 0.2, shade(wood, 0.9), "Wood")
			end, false, "Wood")
			for _, side in { -1, 1 } do
				local hinge = side * 1.64
				local a, b = math.min(side * 1.64, side * 0.01), math.max(side * 1.64, side * 0.01)
				local parts: { Prim? } = {}
				local w = (b - a) / 3
				for k = 0, 2 do
					local tone = if k == 1 then shade(wood, 1.06) else wood
					table.insert(
						parts,
						r:block(
							a + k * w + 0.01,
							0.04,
							-0.07,
							a + (k + 1) * w - 0.01,
							DOOR_H - 0.18,
							0.07,
							tone,
							"Wood"
						)
					)
				end
				for _, y in { 0.3, 3.2, DOOR_H - 0.6 } do
					table.insert(parts, r:block(a + 0.04, y, 0.07, b - 0.04, y + 0.34, 0.15, shade(wood, 0.86), "Wood"))
					table.insert(
						parts,
						r:block(a + 0.04, y, -0.15, b - 0.04, y + 0.34, -0.07, shade(wood, 0.86), "Wood")
					)
				end
				local x = if side > 0 then a + 0.32 else b - 0.32
				local ring = r:cyl(x, 3.0, 0.2, 0.06, 0.34, "z", r.c2, "Metal")
				table.insert(parts, ring)
				for _, p in parts do
					if p then
						r:door(p, hinge)
					end
				end
			end
		end,
	},
	{
		id = "hall_porch",
		name = "Gabled porch",
		cat = "structure",
		style = "temple",
		price = 420,
		place = "floor",
		size = Vector3.new(7.2, 10, 5.4),
		c1 = TILE_HEX,
		c2 = TIMBER_HEX,
		build = function(r: R)
			-- A small porch to stand over a door, its back (-z) against the wall: two square posts
			-- (c2) on stones at the front, beams round its head, and a little gable roof of tiles
			-- (c1) over it with its gable to the front: plaster in the gable, a king post, barge
			-- boards and a round boss at the top
			local tile, wood = r.c1, r.c2
			local back, front = -2.4, 2.6
			local px, pz = 2.55, 1.8
			local beam = 6.9
			for _, sx in { -1, 1 } do
				r:bevel(
					sx * px - 0.42,
					0,
					pz - 0.42,
					sx * px + 0.42,
					0.4,
					pz + 0.42,
					0.06,
					STONE,
					"Granite",
					{ wear = 0.92 }
				)
				r:block(sx * px - 0.22, 0.4, pz - 0.22, sx * px + 0.22, beam, pz + 0.22, wood, "Wood")
			end
			r:piece(function(q: R)
				q:block(-px - 0.45, beam - 0.5, pz - 0.2, px + 0.45, beam, pz + 0.2, wood, "Wood")
				for _, sx in { -1, 1 } do
					q:block(sx * px - 0.2, beam - 0.5, back + 0.05, sx * px + 0.2, beam, pz + 0.2, wood, "Wood")
				end
				q:block(-px - 0.2, beam - 0.5, back + 0.05, px + 0.2, beam, back + 0.3, wood, "Wood")
			end, true, "Wood")
			local ridgeY, eaveY, ex = 9.35, beam + 0.25, 3.45
			local k = (ridgeY - eaveY) / ex
			local function ty(x: number): number
				return eaveY + (ex - math.abs(x)) * k
			end
			local tiles: { Prim } = {}
			local timber: { Prim } = {}
			local plaster: { Prim } = {}
			for _, s in { 1, -1 } do
				addAll(
					tiles,
					Geometry.quad(
						Vector3.new(0, ridgeY, back),
						Vector3.new(0, ridgeY, front),
						Vector3.new(s * ex, eaveY, front),
						Vector3.new(s * ex, eaveY, back),
						0.26,
						tile,
						"ClayRoofTiles",
						Vector3.new(0, -1, 0)
					)
				)
				for j = 0, 6 do
					local z = back + 0.35 + j * (front - back - 0.6) / 6
					add(
						tiles,
						Geometry.beam(
							Vector3.new(s * 0.3, ty(0.3) + 0.06, z),
							Vector3.new(s * (ex - 0.03), ty(ex - 0.03) + 0.06, z),
							0.26,
							0.12,
							shade(tile, 0.9),
							"ClayRoofTiles"
						)
					)
				end
				-- the eave's fascia, and the barge board down the gable's edge
				add(
					timber,
					Geometry.span(
						Vector3.new(s * (ex + 0.02), eaveY - 0.45, back),
						Vector3.new(s * (ex + 0.16), eaveY - 0.02, front),
						wood,
						"Wood"
					)
				)
				add(
					timber,
					Geometry.beam(
						Vector3.new(0, ridgeY + 0.05, front + 0.11),
						Vector3.new(s * (ex + 0.1), eaveY + 0.0, front + 0.11),
						0.22,
						0.6,
						wood,
						"Wood"
					)
				)
				-- the gable's plaster over the front beam, up under the roof
				addAll(
					plaster,
					Geometry.triangle(
						Vector3.new(s * (px + 0.3), beam, pz),
						Vector3.new(0, beam, pz),
						Vector3.new(0, ty(0) - 0.4, pz),
						0.3,
						PLASTER,
						"Plaster"
					)
				)
			end
			table.insert(
				tiles,
				Geometry.span(
					Vector3.new(-0.38, ridgeY - 0.25, back + 0.04),
					Vector3.new(0.38, ridgeY + 0.38, front + 0.1),
					shade(tile, 0.72),
					"ClayRoofTiles"
				)
			)
			add(
				timber,
				Geometry.span(
					Vector3.new(-0.16, beam, pz + 0.15),
					Vector3.new(0.16, ty(0) - 0.42, pz + 0.3),
					wood,
					"Wood"
				)
			)
			pieced(r, tiles, "ClayRoofTiles", true)
			pieced(r, timber, "Wood", false)
			pieced(r, plaster, "Plaster", false)
			local boss = r:cyl(0, ridgeY - 0.7, front + 0.26, 0.1, 0.4, "z", Color3.fromRGB(150, 128, 84), "Metal")
			boss.smooth = true
		end,
	},
	{
		id = "hall_step",
		name = "Long stone step",
		cat = "structure",
		style = "temple",
		price = 60,
		place = "ground",
		size = Vector3.new(8, 0.7, 2.4),
		c1 = "B4B4B8",
		c2 = "9A9AA0",
		build = function(r: R)
			-- a low step of worn concrete (c1) eight studs long, to run along a hall's front, its
			-- edge rubbed lighter
			r:bevel(-4, 0, -1.2, 4, 0.7, 1.2, 0.08, r.c1, "Concrete", { wear = 1.06 })
			r:block(-3.96, 0, 1.2, 3.96, 0.08, 1.24, r.c2, "Concrete")
		end,
	},
	{
		id = "oil_drum",
		name = "Oil drum",
		cat = "decor",
		price = 40,
		place = "floor",
		size = Vector3.new(2, 2.9, 2),
		c1 = "8E4A36",
		c2 = "6A3A2C",
		build = function(r: R)
			-- an old steel drum gone rusty (c1): two rolling hoops round it, a rim at the top and a
			-- lid with its two bungs (c2)
			local body = r:cyl(0, 1.39, 0, 2.78, 1.82, "y", r.c1, "CorrodedMetal")
			body.smooth = true
			for _, y in { 0.06, 0.95, 1.9, 2.78 } do
				local hoop = r:cyl(
					0,
					y,
					0,
					if y < 0.1 or y > 2.7 then 0.12 else 0.14,
					1.9,
					"y",
					shade(r.c1, 0.86),
					"CorrodedMetal"
				)
				hoop.smooth = true
			end
			local lid = r:cyl(0, 2.785, 0, 0.05, 1.7, "y", r.c2, "CorrodedMetal")
			lid.smooth = true
			for _, p in { { 0.5, 0.2 }, { -0.42, -0.3 } } do
				local bung = r:cyl(p[1], 2.85, p[2], 0.1, 0.26, "y", shade(r.c2, 0.9), "CorrodedMetal")
				bung.smooth = true
			end
		end,
	},
	{
		id = "temple_torii",
		name = "Red gate",
		cat = "garden",
		style = "temple",
		price = 220,
		place = "floor",
		size = Vector3.new(9.4, 9, 1),
		c1 = "C9532E",
		c2 = "2E2A2A",
		build = function(r: R)
			-- A gateway of red lacquered timber (c1) with black feet and a black top beam (c2), wide
			-- enough to walk through two abreast. Set them close one behind another for a tunnel of
			-- gates, up a flight of hill steps too
			gate(r, 0)
		end,
	},
	{
		id = "temple_torii_row",
		name = "Row of red gates",
		cat = "garden",
		style = "temple",
		price = 1000,
		place = "floor",
		size = Vector3.new(9.4, 9, 8),
		c1 = "C9532E",
		c2 = "2E2A2A",
		build = function(r: R)
			-- five of the red gates one behind another, 1.6 apart, for a tunnel of gates on level
			-- ground
			for k = 0, 4 do
				gate(r, -3.2 + k * 1.6)
			end
		end,
	},
	{
		id = "hill_block",
		name = "Hill block",
		cat = "garden",
		style = "temple",
		price = 160,
		place = "floor",
		size = Vector3.new(16, H + CAP, 16),
		c1 = "6E9A54",
		c2 = "6A6A50",
		build = function(r: R)
			-- A storey of earth (c2) sixteen studs square with grass (c1) over its top and rock
			-- coming through its sides: set them side by side and one on another, a storey at a time,
			-- to build a hill up, and stand trees and buildings on their tops
			hillBlock(r)
		end,
	},
	{
		id = "hill_slope",
		name = "Hill slope",
		cat = "garden",
		style = "temple",
		price = 140,
		place = "floor",
		size = Vector3.new(16, H + CAP, 16),
		c1 = "6E9A54",
		c2 = "6A6A50",
		build = function(r: R)
			-- A grassy bank (c1 over earth, c2) climbing a storey from its front to its back, with
			-- rock and shrubs on it: the face of a hill, in front of hill blocks
			bank(r, -8, 8, { -1, 1 }, 11)
		end,
	},
	{
		id = "hill_steps",
		name = "Hill steps",
		cat = "garden",
		style = "temple",
		price = 300,
		place = "floor",
		size = Vector3.new(16, H + CAP, 16),
		c1 = "6E9A54",
		c2 = "6A6A50",
		build = function(r: R)
			-- Twenty stone steps climbing a storey up a slope from the front to the back, between
			-- low stone kerbs and grassy banks (c1 over earth, c2) the size of a hill slope, so it
			-- goes in a row of them. Red gates stand on the steps
			local stone = Color3.fromRGB(168, 164, 156)
			local treads: { Prim } = {}
			for i = 1, 20 do
				local z1 = 8 - 0.8 * (i - 1)
				local z0 = z1 - 0.8
				local top = 0.6 * i
				local tone = shade(stone, 0.96 + (i % 3) * 0.03)
				table.insert(
					treads,
					Geometry.span(Vector3.new(-3.2, 0, z0), Vector3.new(3.2, top - 0.08, z1 - 0.06), tone, "Granite")
				)
				table.insert(
					treads,
					Geometry.span(
						Vector3.new(-3.2, top - 0.08, z0),
						Vector3.new(3.2, top, z1),
						shade(tone, 1.05),
						"Granite"
					)
				)
			end
			pieced(r, treads, "Granite", true)
			-- the kerbs, stepping up with the treads
			local kerbs: { Prim } = {}
			for _, sx in { -1, 1 } do
				for k = 1, 5 do
					local z1 = 8 - 3.2 * (k - 1)
					local top = 0.6 * 4 * k + 0.3
					table.insert(
						kerbs,
						Geometry.span(
							Vector3.new(sx * 3.2, 0, z1 - 3.2),
							Vector3.new(sx * 3.7, top, z1),
							shade(stone, 0.9),
							"Granite"
						)
					)
				end
			end
			pieced(r, kerbs, "Granite", true)
			bank(r, -8, -3.7, { -1 }, 21)
			bank(r, 3.7, 8, { 1 }, 31)
		end,
	},
}

return items
