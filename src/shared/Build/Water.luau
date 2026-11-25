--!strict
-- Water on a plot: a pool or a pond the player drags out in Build mode, and the rules for what may
-- stand in it. The user: "also, add ability to add water, along with things that can go in the
-- water".
--
-- A plan keeps its water as a fifth kind of object (Plan: "waters"), each a rectangle on the
-- ground floor:
--   waters { x1, z1, x2, z2, lv = 0, edge, depth }
--     edge   "tile" (a tiled pool), "stone" (a rim of flagstones) or "pond" (a natural bank with
--            pebbles and reeds)
--     depth  "shallow" (paddling) or "swim"
-- In the game the water is Roblox terrain water, so people wade and swim in it: the server digs
-- the rectangle out of the ground and fills it (Services/Water), and puts the ground back when the
-- water goes. What is drawn here is the rest: the rim or the bank, and the lining of the basin
-- (its walls and floor, so the basin is closed whatever the ground under it is). The previews
-- have no terrain, so there the water itself is a flat see-through slab (Water.drawSurface).
--
-- The terrain is a grid of 4 stud voxels and the plots' corners sit 2 studs off it, so a water's
-- edges lie at 2 past every 4 in the plot's frame (Water.Offset): each one is exactly a block of
-- voxels, and filling or clearing it never touches a voxel outside it.
--
-- Pieces made for water (Recipes/Water) have place = "water" and say how they sit with `water`:
--   "float"   on the surface (boats, floats, lily pads, a shoal under it)
--   "bottom"  standing on the floor of shallow water (reeds, stepping stones)
--   "edge"    on the bank, reaching out over the water (a jetty, a ladder, a diving board)
-- and `draft`, how far their own frame's floor lies under that (a hull's depth in the water, a
-- post's reach under the bank). Nothing else may stand in water unless it is up on something
-- over it: the rim, a jetty, a raft (Water.Raised).
--
-- Shared and free of services: Plan calls it to check, price and tidy water, Builder to draw it,
-- Build mode to drag it out, and the specs run it.

local Tuning = require(script.Parent.Parent.Config.Tuning)
local Catalog = require(script.Parent.Catalog)
local Geometry = require(script.Parent.Geometry)

type Prim = Geometry.Prim

local T = Tuning.Water
local EPS = 1e-6

local Water = {}

export type Water = {
	x1: number,
	z1: number,
	x2: number,
	z2: number,
	lv: number,
	edge: string,
	depth: string,
}

Water.Voxel = 4 -- the terrain's voxels
Water.Snap = 4 -- a water's edges snap to every 4 studs...
Water.Offset = 2 -- ...2 past the plot's own grid, which is the terrain's (Town.plotFrame)
Water.Surface = -0.5 -- the water's top, a little under the ground (0)
Water.Lining = 0.4 -- the basin's walls and floor
Water.Raised = 0.25 -- what stands this high over water is up on something (the rim, a raft)

-- How deep: the voxel layers dug out under the ground, and the top of the basin's floor.
Water.Depths = {
	shallow = { name = "Paddling", layers = 1, floor = -2.5 },
	swim = { name = "Swimming", layers = 2, floor = -7.5 },
}
Water.DepthOrder = { "shallow", "swim" }

-- What goes round it: its name, and how far in from the rectangle's edge the open water starts
-- (a piece that floats keeps inside that).
Water.Edges = {
	tile = { name = "Tiled pool", inset = 1.2 },
	stone = { name = "Stone rim", inset = 1.4 },
	pond = { name = "Pond", inset = 1.8 },
}
Water.EdgeOrder = { "tile", "stone", "pond" }

-- Draws the water itself as a see-through slab. The server turns it off (Services/Water): in the
-- game the terrain is the water. The previews and the placing ghost keep it.
Water.drawSurface = true

-- Numbers and the grid ----------------------------------------------------------------------------

local function finite(n: any): boolean
	return type(n) == "number" and n == n and n ~= math.huge and n ~= -math.huge
end

local function onGrid(n: number): boolean
	local k = (n - Water.Offset) / Water.Snap
	return math.abs(k - math.floor(k + 0.5)) < 1e-6
end

-- The nearest edge line to v, kept inside lo..hi (the land's edges, which are on the plot's grid).
function Water.snap(v: number, lo: number, hi: number): number
	local s, o = Water.Snap, Water.Offset
	local g = math.floor((v - o) / s + 0.5) * s + o
	local first = math.ceil((lo - o) / s - 1e-6) * s + o
	local last = math.floor((hi - o) / s + 1e-6) * s + o
	return math.clamp(g, first, math.max(first, last))
end

function Water.depthOf(w: any): { name: string, layers: number, floor: number }
	return Water.Depths[w.depth] or Water.Depths.swim
end

function Water.edgeOf(w: any): { name: string, inset: number }
	return Water.Edges[w.edge] or Water.Edges.tile
end

-- Rectangles --------------------------------------------------------------------------------------

-- Do two rectangles { x1, z1, x2, z2 } share any area (touching edges don't count)?
local function overlaps(a: any, b: any): boolean
	return a.x1 < b.x2 - 1e-3 and b.x1 < a.x2 - 1e-3 and a.z1 < b.z2 - 1e-3 and b.z1 < a.z2 - 1e-3
end

local function rectOf(x1: number, z1: number, x2: number, z2: number): any
	return { x1 = x1, z1 = z1, x2 = x2, z2 = z2 }
end

-- Does the line from (ax, az) to (bx, bz) pass through the inside of the rectangle (running
-- along its edge doesn't count)? Clips the line to the rectangle, a little shrunk.
local function crosses(ax: number, az: number, bx: number, bz: number, r: any): boolean
	local g = 1e-3
	local x1, z1, x2, z2 = r.x1 + g, r.z1 + g, r.x2 - g, r.z2 - g
	local t0, t1 = 0, 1
	local dx, dz = bx - ax, bz - az
	for _, edge in { { -dx, ax - x1 }, { dx, x2 - ax }, { -dz, az - z1 }, { dz, z2 - az } } do
		local p, q = edge[1], edge[2]
		if math.abs(p) < 1e-9 then
			if q < 0 then
				return false
			end
		else
			local t = q / p
			if p < 0 then
				t0 = math.max(t0, t)
			else
				t1 = math.min(t1, t)
			end
			if t0 > t1 then
				return false
			end
		end
	end
	return true
end

-- The rectangles of `rect` left over once the holes are cut out of it (all { x1, z1, x2, z2 }).
-- The server cuts the plot's ground this way round the water (Services/Water).
function Water.cutRects(rect: { number }, holes: { { number } }): { { number } }
	local rects = { rect }
	for _, h in holes do
		local out = {}
		for _, r in rects do
			local x1, z1, x2, z2 = r[1], r[2], r[3], r[4]
			local hx1, hz1, hx2, hz2 = math.max(h[1], x1), math.max(h[2], z1), math.min(h[3], x2), math.min(h[4], z2)
			if hx1 >= hx2 - 1e-3 or hz1 >= hz2 - 1e-3 then
				table.insert(out, r)
			else
				if hz1 > z1 + 1e-3 then
					table.insert(out, { x1, z1, x2, hz1 })
				end
				if hz2 < z2 - 1e-3 then
					table.insert(out, { x1, hz2, x2, z2 })
				end
				if hx1 > x1 + 1e-3 then
					table.insert(out, { x1, hz1, hx1, hz2 })
				end
				if hx2 < x2 - 1e-3 then
					table.insert(out, { hx2, hz1, x2, hz2 })
				end
			end
		end
		rects = out
	end
	return rects
end

-- Every water's rectangle, for cutting the ground.
function Water.holes(plan: any): { { number } }
	local out = {}
	for _, w in (plan and plan.waters) or {} do
		table.insert(out, { w.x1, w.z1, w.x2, w.z2 })
	end
	return out
end

-- The water a point is in (strictly inside its rectangle), and its key.
function Water.at(plan: any, x: number, z: number): (any, string?)
	for key, w in (plan and plan.waters) or {} do
		if x > w.x1 and x < w.x2 and z > w.z1 and z < w.z2 then
			return w, key
		end
	end
	return nil, nil
end

-- An item's footprint on the ground, turned as it stands, as x1, z1, x2, z2 (as Plan.itemRect).
local function footprint(item: any, def: Catalog.Def): (number, number, number, number)
	local a = math.rad(item.r or 0)
	local c, s = math.abs(math.cos(a)), math.abs(math.sin(a))
	local hx = (def.size.X * c + def.size.Z * s) / 2
	local hz = (def.size.X * s + def.size.Z * c) / 2
	return item.x - hx, item.z - hz, item.x + hx, item.z + hz
end

-- Pieces made for water ----------------------------------------------------------------------------

-- How a piece sits in water ("float", "bottom", "edge"), nil for any other piece.
function Water.sitOf(def: Catalog.Def): string?
	if def.place ~= "water" then
		return nil
	end
	local sit = (def :: any).water
	return if sit == "bottom" or sit == "edge" then sit else "float"
end

-- The height a piece made for water stands at: its frame's floor, `draft` under the surface (a
-- float), the ground (an edge piece) or the floor of shallow water (standing on the bottom).
function Water.pieceY(def: Catalog.Def): number
	local sit = Water.sitOf(def)
	local draft = (def :: any).draft
	local d = if type(draft) == "number" then draft else 0
	if sit == "edge" then
		return -d
	elseif sit == "bottom" then
		return Water.Depths.shallow.floor - d
	end
	return Water.Surface - d
end

-- Says what water makes of an item standing at lv 0 with this footprint: true when it is a piece
-- made for water and sits right, false and why when it may not stand there, and nil when water has
-- nothing to say (it is nowhere near any, or up on something over it) and the usual rules decide.
-- Plan.validItem asks it.
function Water.checkItem(
	plan: any,
	item: any,
	def: Catalog.Def,
	x1: number,
	z1: number,
	x2: number,
	z2: number
): (boolean?, string?)
	local waters = (plan and plan.waters) or {}
	local sit = Water.sitOf(def)
	if sit then
		if item.lv ~= 0 then
			return false, "that goes in water on the ground"
		end
		if math.abs(item.y - Water.pieceY(def)) > 1e-3 then
			return false, "bad height"
		end
		local foot = rectOf(x1, z1, x2, z2)
		if sit == "edge" then
			-- partly over the water, partly on the side
			for _, w in waters do
				if overlaps(foot, w) then
					local inside = x1 >= w.x1 - 1e-3 and z1 >= w.z1 - 1e-3 and x2 <= w.x2 + 1e-3 and z2 <= w.z2 + 1e-3
					if inside then
						return false, "put it at the edge, with its back on the side"
					end
					return true
				end
			end
			return false, "that goes at the edge of a pool or a pond"
		end
		local w = Water.at(plan, item.x, item.z)
		if not w then
			return false, "that goes in water"
		end
		local inset = Water.edgeOf(w).inset - 0.05
		if x1 < w.x1 + inset or z1 < w.z1 + inset or x2 > w.x2 - inset or z2 > w.z2 - inset then
			return false, "too close to the edge"
		end
		if sit == "bottom" and w.depth ~= "shallow" then
			return false, "that needs shallow water"
		end
		return true
	end
	if item.lv ~= 0 then
		return nil
	end
	-- anything else stays out of the water, unless it stands up on something over it
	local g = 0.05
	local foot = rectOf(x1 + g, z1 + g, x2 - g, z2 - g)
	for _, w in waters do
		if overlaps(foot, w) and (item.y < Water.Raised or def.place == "stairs") then
			return false, "that can't go in the water"
		end
	end
	return nil
end

-- The items that go with a water when it is taken away: the pieces made for water that touch it,
-- and whatever stands out over its open water (on a raft, say). The rim keeps what is on it.
function Water.piecesIn(plan: any, key: string): { string }
	local out = {}
	local w = plan.waters and plan.waters[key]
	if not w then
		return out
	end
	local inset = Water.edgeOf(w).inset
	local open = rectOf(w.x1 + inset, w.z1 + inset, w.x2 - inset, w.z2 - inset)
	for itemKey, item in plan.items or {} do
		local def = Catalog.get(item.id)
		if def and item.lv == 0 and item.wall == nil and type(item.x) == "number" and type(item.z) == "number" then
			local x1, z1, x2, z2 = footprint(item, def)
			if def.place == "water" then
				if overlaps(rectOf(x1, z1, x2, z2), w) then
					table.insert(out, itemKey)
				end
			elseif item.x > open.x1 and item.x < open.x2 and item.z > open.z1 and item.z < open.z2 then
				table.insert(out, itemKey)
			end
		end
	end
	table.sort(out)
	return out
end

-- Checking water ------------------------------------------------------------------------------------

local FIELDS = { "x1", "z1", "x2", "z2" }

-- Checks a water against the plan it would go in (`b` the land: x1, z1, x2, z2). `ignoreKey`
-- skips the water itself when it is being changed.
function Water.valid(plan: any, w: any, ignoreKey: string?, b: { number }): (boolean, string?)
	if type(w) ~= "table" then
		return false, "not water"
	end
	for _, k in FIELDS do
		if not finite(w[k]) then
			return false, "bad number"
		end
		if not onGrid(w[k]) then
			return false, "off the grid"
		end
	end
	if w.lv ~= 0 then
		return false, "water goes on the ground floor"
	end
	if type(w.edge) ~= "string" or not Water.Edges[w.edge] then
		return false, "bad edge"
	end
	if type(w.depth) ~= "string" or not Water.Depths[w.depth] then
		return false, "bad depth"
	end
	if w.x1 < b[1] - EPS or w.z1 < b[2] - EPS or w.x2 > b[3] + EPS or w.z2 > b[4] + EPS then
		return false, "outside your land"
	end
	local sx, sz = w.x2 - w.x1, w.z2 - w.z1
	if sx < T.MinSide - EPS or sz < T.MinSide - EPS then
		return false, "too small"
	end
	if sx > T.MaxSide + EPS or sz > T.MaxSide + EPS then
		return false, "too big"
	end
	-- nothing built over it: it's outdoors, on open ground
	for key, o in (plan and plan.waters) or {} do
		if key ~= ignoreKey and overlaps(w, o) then
			return false, "there's water there already"
		end
	end
	for _, f in (plan and plan.floors) or {} do
		if overlaps(w, f) then
			return false, "there's a floor there"
		end
	end
	for _, r in (plan and plan.roofs) or {} do
		if overlaps(w, r) then
			return false, "water goes outdoors, not under a roof"
		end
	end
	for _, wall in (plan and plan.walls) or {} do
		if crosses(wall.x1, wall.z1, wall.x2, wall.z2, w) then
			return false, "there's a wall in the way"
		end
	end
	-- what stands there: nothing on the ground, and what is in the water still has to fit it
	local before = ignoreKey and plan.waters and plan.waters[ignoreKey]
	local view = { waters = {} :: { [string]: any } }
	for key, o in (plan and plan.waters) or {} do
		if key ~= ignoreKey then
			view.waters[key] = o
		end
	end
	view.waters[ignoreKey or "?new"] = w
	for _, item in (plan and plan.items) or {} do
		local def = Catalog.get(item.id)
		if def and item.lv == 0 and item.wall == nil and type(item.x) == "number" and type(item.z) == "number" then
			local x1, z1, x2, z2 = footprint(item, def)
			local foot = rectOf(x1, z1, x2, z2)
			if overlaps(foot, w) or (before and overlaps(foot, before)) then
				local ok = Water.checkItem(view, item, def, x1, z1, x2, z2)
				if ok == false then
					return false,
						if def.place == "water"
							then "take out what's in the water first"
							else "move what's standing there first"
				end
			end
		end
	end
	return true
end

-- Can a wall, floor or roof go up with the plan's water where it is? Nothing is built over water.
-- (Plan.validate asks it after its own checks pass.)
function Water.clearOf(plan: any, kind: string, obj: any): (boolean, string?)
	local waters = plan and plan.waters
	if not waters or next(waters) == nil or type(obj) ~= "table" then
		return true
	end
	for _, w in waters do
		if kind == "walls" then
			if crosses(obj.x1, obj.z1, obj.x2, obj.z2, w) then
				return false, "that's over the water"
			end
		elseif kind == "floors" or kind == "roofs" then
			if overlaps(obj, w) then
				return false, "that's over the water"
			end
		end
	end
	return true
end

-- What it costs: by the WallSnap square, more the deeper it is.
function Water.cost(w: any): number
	if type(w) ~= "table" or not finite(w.x1) or not finite(w.x2) or not finite(w.z1) or not finite(w.z2) then
		return 0
	end
	local s = Tuning.Plot.WallSnap
	local cells = math.max(1, math.floor(((w.x2 - w.x1) / s) * ((w.z2 - w.z1) / s) + 0.5))
	local per = T.PerCell[w.depth] or T.PerCell.swim
	return cells * per
end

-- Only the fields a water has, with plain values (Plan.clean).
function Water.clean(obj: any): any
	if type(obj) ~= "table" then
		return obj
	end
	local out: { [string]: any } = {}
	for _, k in { "x1", "z1", "x2", "z2", "lv" } do
		if type(obj[k]) == "number" then
			out[k] = obj[k]
		end
	end
	for _, k in { "edge", "depth" } do
		if type(obj[k]) == "string" and #obj[k] <= 16 then
			out[k] = obj[k]
		end
	end
	return out
end

-- The terrain ------------------------------------------------------------------------------------------

-- The block of voxels a water fills, in the plot's frame: its low and high corners (from the
-- bottom of the dug out layers to the ground), and how full of water each layer is, from the
-- bottom up (the top one only to the surface).
function Water.voxels(w: any): (Vector3, Vector3, { number })
	local layers = Water.depthOf(w).layers
	local V = Water.Voxel
	local lo = Vector3.new(w.x1, -layers * V, w.z1)
	local hi = Vector3.new(w.x2, 0, w.z2)
	local fill = {}
	for k = 1, layers do
		local bottom = -layers * V + (k - 1) * V
		table.insert(fill, math.clamp((Water.Surface - bottom) / V, 0, 1))
	end
	return lo, hi, fill
end

-- Drawing ----------------------------------------------------------------------------------------------

local function rgb(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end

local TILE = rgb(190, 224, 228) -- the pool's pale tiles
local TILE_BAND = rgb(72, 136, 170) -- the blue mosaic along the waterline
local LANE = rgb(60, 104, 140) -- the dark line along the floor
local COPING = rgb(236, 230, 216)
local STONES = { rgb(176, 170, 158), rgb(188, 182, 170), rgb(160, 156, 146), rgb(170, 160, 146) }
local STONE_WALL = rgb(136, 130, 120)
local STONE_FLOOR = rgb(112, 110, 104)
local BANK = rgb(126, 106, 80)
local MUD = rgb(90, 78, 60)
local MUD_FLOOR = rgb(78, 70, 54)
local PEBBLES = { rgb(168, 160, 150), rgb(140, 132, 122), rgb(186, 176, 160), rgb(122, 112, 100) }
local REED = rgb(104, 140, 76)
local REED_LIT = rgb(150, 168, 92)
local CATTAIL = rgb(118, 80, 54)
local SURFACE = rgb(64, 166, 178) -- the terrain's own water colour (Data/Terrain)

-- A steady pseudo random number in 0..1 from two numbers, so the same water is drawn the same
-- way every time.
local function noise(a: number, b: number): number
	local v = math.sin(a * 12.9898 + b * 78.233) * 43758.5453
	return v - math.floor(v)
end

local function span(
	out: { Prim },
	x1: number,
	y1: number,
	z1: number,
	x2: number,
	y2: number,
	z2: number,
	c: Color3,
	m: string
): Prim
	local p = Geometry.span(Vector3.new(x1, y1, z1), Vector3.new(x2, y2, z2), c, m)
	table.insert(out, p)
	return p
end

-- The basin: four walls just inside the rectangle, from the bottom of the dug out layers up to
-- `top`, and the floor between them.
local function basin(out: { Prim }, w: any, top: number, wall: Color3, wallMat: string, floor: Color3, floorMat: string)
	local d = Water.depthOf(w)
	local bottom = -d.layers * Water.Voxel
	local t = Water.Lining
	local x1, z1, x2, z2 = w.x1, w.z1, w.x2, w.z2
	span(out, x1, bottom, z1, x1 + t, top, z2, wall, wallMat)
	span(out, x2 - t, bottom, z1, x2, top, z2, wall, wallMat)
	span(out, x1 + t, bottom, z1, x2 - t, top, z1 + t, wall, wallMat)
	span(out, x1 + t, bottom, z2 - t, x2 - t, top, z2, wall, wallMat)
	span(out, x1 + t, bottom, z1 + t, x2 - t, d.floor, z2 - t, floor, floorMat)
end

-- A tiled pool: pale tiles, a band of blue mosaic at the waterline, a smooth stone coping round
-- the top and, in a pool deep enough to swim in, a dark line along the floor.
local function tilePool(out: { Prim }, w: any)
	local d = Water.depthOf(w)
	local x1, z1, x2, z2 = w.x1, w.z1, w.x2, w.z2
	basin(out, w, 0, TILE, "CeramicTiles", TILE, "CeramicTiles")
	-- the waterline band on the walls' inner faces, 0.04 proud of them
	local t, b = Water.Lining, 0.04
	local y1, y2 = Water.Surface - 0.45, Water.Surface + 0.3
	span(out, x1 + t, y1, z1 + t, x1 + t + b, y2, z2 - t, TILE_BAND, "CeramicTiles")
	span(out, x2 - t - b, y1, z1 + t, x2 - t, y2, z2 - t, TILE_BAND, "CeramicTiles")
	span(out, x1 + t + b, y1, z1 + t, x2 - t - b, y2, z1 + t + b, TILE_BAND, "CeramicTiles")
	span(out, x1 + t + b, y1, z2 - t - b, x2 - t - b, y2, z2 - t, TILE_BAND, "CeramicTiles")
	-- the coping: the long sides whole, the short ones between them
	local cw, ch = Water.Edges.tile.inset, 0.35
	span(out, x1, 0, z1, x1 + cw, ch, z2, COPING, "Limestone")
	span(out, x2 - cw, 0, z1, x2, ch, z2, COPING, "Limestone")
	span(out, x1 + cw, 0, z1, x2 - cw, ch, z1 + cw, COPING, "Limestone")
	span(out, x1 + cw, 0, z2 - cw, x2 - cw, ch, z2, COPING, "Limestone")
	-- a lip under the coping's inner edge, where it overhangs the water
	local lip = 0.12
	span(out, x1 + t + b, -lip, z1 + t + b, x1 + cw, 0, z2 - t - b, COPING, "Limestone")
	span(out, x2 - cw, -lip, z1 + t + b, x2 - t - b, 0, z2 - t - b, COPING, "Limestone")
	span(out, x1 + cw, -lip, z1 + t + b, x2 - cw, 0, z1 + cw, COPING, "Limestone")
	span(out, x1 + cw, -lip, z2 - cw, x2 - cw, 0, z2 - t - b, COPING, "Limestone")
	if w.depth == "swim" then
		-- a lane line along the floor's long way, with a bar across each end
		local long = (x2 - x1) >= (z2 - z1)
		local y = d.floor
		local a1, a2 = if long then x1 else z1, if long then x2 else z2
		local mid = if long then (z1 + z2) / 2 else (x1 + x2) / 2
		local half, bar, endIn = 0.3, 1.2, 1.6
		local s1, s2 = a1 + t + endIn, a2 - t - endIn
		if s2 - s1 > 2 then
			local function lay(u1: number, v1: number, u2: number, v2: number)
				if long then
					span(out, u1, y, v1, u2, y + 0.04, v2, LANE, "CeramicTiles")
				else
					span(out, v1, y, u1, v2, y + 0.04, u2, LANE, "CeramicTiles")
				end
			end
			lay(s1, mid - bar, s1 + 2 * half, mid + bar)
			lay(s2 - 2 * half, mid - bar, s2, mid + bar)
			lay(s1 + 2 * half, mid - half, s2 - 2 * half, mid + half)
		end
	end
end

-- A rim of flagstones in a few greys, each its own length and height, with a gap between them.
local function stoneRim(out: { Prim }, w: any)
	local x1, z1, x2, z2 = w.x1, w.z1, w.x2, w.z2
	basin(out, w, 0, STONE_WALL, "Cobblestone", STONE_FLOOR, "Slate")
	local sw, gap = Water.Edges.stone.inset, 0.1
	local function stone(ax: number, az: number, bx: number, bz: number, seed: number)
		local h = 0.3 + noise(ax + seed, bz) * 0.14
		local col = STONES[1 + math.floor(noise(bx, az + seed) * #STONES) % #STONES]
		span(out, ax + gap / 2, 0, az + gap / 2, bx - gap / 2, h, bz - gap / 2, col, "Slate")
	end
	-- the four corners, square
	stone(x1, z1, x1 + sw, z1 + sw, 1)
	stone(x2 - sw, z1, x2, z1 + sw, 2)
	stone(x1, z2 - sw, x1 + sw, z2, 3)
	stone(x2 - sw, z2 - sw, x2, z2, 4)
	-- and the sides between them, in stones of 1.8 to 3 studs
	local function run(a0: number, a1: number, alongX: boolean, c1: number, c2: number, seed: number)
		local a = a0
		while a < a1 - 1e-3 do
			local b = math.min(a1, a + 1.8 + noise(a, seed) * 1.2)
			if a1 - b < 1.2 then
				b = a1 -- no sliver left at the end
			end
			if alongX then
				stone(a, c1, b, c2, seed)
			else
				stone(c1, a, c2, b, seed)
			end
			a = b
		end
	end
	run(x1 + sw, x2 - sw, true, z1, z1 + sw, 5)
	run(x1 + sw, x2 - sw, true, z2 - sw, z2, 6)
	run(z1 + sw, z2 - sw, false, x1, x1 + sw, 7)
	run(z1 + sw, z2 - sw, false, x2 - sw, x2, 8)
end

-- A clump of reeds and two bulrushes standing on the bank at (x, z), its foot at y.
local function reeds(out: { Prim }, x: number, z: number, y: number, seed: number)
	for k = 0, 6 do
		local a = k * 2.4 + seed
		local lean = 0.12 + noise(k, seed) * 0.16
		local h = 2.2 + noise(seed, k) * 1.1
		local r = 0.12 + noise(k + 3, seed) * 0.28
		local foot = Vector3.new(x + math.cos(a) * r, y, z + math.sin(a) * r)
		local top = foot + Vector3.new(math.cos(a) * lean * h, h, math.sin(a) * lean * h)
		local blade = Geometry.beam(foot, top, 0.12, 0.05, if k % 3 == 0 then REED_LIT else REED, "Grass")
		if blade then
			blade.collide = false
			table.insert(out, blade)
		end
	end
	for k = 0, 1 do
		local a = seed + k * 2.9
		local bx, bz = x + math.cos(a) * 0.25, z + math.sin(a) * 0.25
		local h = 2.6 + k * 0.5
		local stem =
			Geometry.span(Vector3.new(bx - 0.04, y, bz - 0.04), Vector3.new(bx + 0.04, y + h, bz + 0.04), REED, "Grass")
		stem.collide = false
		table.insert(out, stem)
		table.insert(out, {
			shape = "Cylinder",
			cf = CFrame.new(bx, y + h - 0.45, bz) * CFrame.Angles(0, 0, math.pi / 2),
			size = Vector3.new(0.6, 0.22, 0.22),
			color = CATTAIL,
			mat = "Fabric",
			collide = false,
		})
	end
end

-- A pond: an earthy bank sloping into the water all round, pebbles along the waterline, reeds in
-- two corners and a few stones on its muddy floor.
local function pond(out: { Prim }, w: any)
	local x1, z1, x2, z2 = w.x1, w.z1, w.x2, w.z2
	local d = Water.depthOf(w)
	local bi = Water.Edges.pond.inset
	local low = Water.Surface - 0.7 -- where the bank ends, under the water
	-- the basin's walls stop just under the bank's underside
	basin(out, w, -0.62, MUD, "Mud", MUD_FLOOR, "Mud")
	-- the bank: four slopes meeting at the corners, from the ground at the edge down into the water
	local o = {
		Vector3.new(x1, 0, z1),
		Vector3.new(x2, 0, z1),
		Vector3.new(x2, 0, z2),
		Vector3.new(x1, 0, z2),
	}
	local i = {
		Vector3.new(x1 + bi, low, z1 + bi),
		Vector3.new(x2 - bi, low, z1 + bi),
		Vector3.new(x2 - bi, low, z2 - bi),
		Vector3.new(x1 + bi, low, z2 - bi),
	}
	for k = 1, 4 do
		local n = k % 4 + 1
		for _, p in Geometry.quad(o[k], o[n], i[n], i[k], 0.3, BANK, "Ground", Vector3.new(0, -1, 0)) do
			table.insert(out, p)
		end
	end
	-- the bank's height at a distance in from the edge
	local function bankY(inset: number): number
		return low * math.clamp(inset / bi, 0, 1)
	end
	-- pebbles along the waterline, and now and then one higher up the bank
	local wet = bi * (Water.Surface / low)
	local function pebbles(a0: number, a1: number, alongX: boolean, edge: number, inward: number, seed: number)
		local a = a0 + 0.8
		local k = 0
		while a < a1 - 0.8 do
			local r = 0.3 + noise(a, seed) * 0.28
			local into = wet + (noise(seed, a) - 0.5) * 0.5
			if k % 3 == 2 then
				into = 0.35 + noise(a + 1, seed) * 0.3
			end
			local y = bankY(into) + r * 0.15
			local x, z
			if alongX then
				x, z = a, edge + inward * into
			else
				x, z = edge + inward * into, a
			end
			table.insert(out, {
				shape = "Ball",
				cf = CFrame.new(x, y, z) * CFrame.Angles(0, noise(x, z) * 6, 0),
				size = Vector3.new(r * 1.3, r * 0.7, r),
				color = PEBBLES[1 + math.floor(noise(z, x) * #PEBBLES) % #PEBBLES],
				mat = "Pebble",
			})
			a += 1.3 + noise(a, seed + 1) * 0.6
			k += 1
		end
	end
	pebbles(x1 + bi, x2 - bi, true, z1, 1, 1)
	pebbles(x1 + bi, x2 - bi, true, z2, -1, 2)
	pebbles(z1 + bi, z2 - bi, false, x1, 1, 3)
	pebbles(z1 + bi, z2 - bi, false, x2, -1, 4)
	-- reeds in two corners, and halfway along a long side
	local ry = bankY(bi * 0.55)
	reeds(out, x1 + bi * 0.55, z1 + bi * 0.55, ry, 0.7)
	reeds(out, x2 - bi * 0.55, z2 - bi * 0.55, ry, 2.3)
	if x2 - x1 >= 24 then
		reeds(out, (x1 + x2) / 2 + 1.5, z1 + bi * 0.55, ry, 4.1)
	end
	-- stones lying on the floor, seen through the water
	for k = 0, 4 do
		local fx = x1 + bi + (x2 - x1 - 2 * bi) * noise(k, x1 + z1)
		local fz = z1 + bi + (z2 - z1 - 2 * bi) * noise(x2, k + z2)
		local r = 0.6 + noise(fx, fz) * 0.6
		table.insert(out, {
			shape = "Ball",
			cf = CFrame.new(fx, d.floor + r * 0.15, fz) * CFrame.Angles(0, k, 0),
			size = Vector3.new(r * 1.4, r * 0.6, r),
			color = PEBBLES[1 + k % #PEBBLES],
			mat = "Pebble",
		})
	end
end

-- Everything drawn for one water, in the plot's frame.
function Water.prims(w: any): { Prim }
	local out: { Prim } = {}
	if w.edge == "pond" then
		pond(out, w)
	elseif w.edge == "stone" then
		stoneRim(out, w)
	else
		tilePool(out, w)
	end
	if Water.drawSurface then
		-- the water itself, for the previews and the placing ghost (in the game it's terrain)
		local g = Water.Lining + 0.06
		local p =
			span(out, w.x1 + g, Water.Surface - 0.12, w.z1 + g, w.x2 - g, Water.Surface, w.z2 - g, SURFACE, "Glass")
		p.transp = 0.4
		p.collide = false
		p.name = "WaterSurface"
	end
	return out
end

-- The colour of the water, for whatever draws it (Build mode's tray, the previews).
Water.Color = SURFACE

return Water
