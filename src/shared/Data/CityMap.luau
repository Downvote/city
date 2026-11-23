--!strict
-- The town is the user's low poly city pack (the user: "redo the map with these models and
-- city"). Data/CityPack lists the pack's kit and where the pack puts every piece; this module
-- moves the pack into the game and decides what stays.
--
-- The pack is moved, not turned: its suburb's road to the bridge becomes Main Street, along X
-- through z = 0 (Data/Town). The suburb's houses on both sides make way for the eight plots
-- (the user chose "In the west suburb"): everything that touches a plot, and the parked cars on
-- Main Street, is cleared, and the street's junction and bus stop tiles in front of the plots
-- become plain road. East of the plots, between the garden and the river, is the middle of town:
-- the spawn on the green, the tailor's in the boutique, the news board by the street, and the
-- city hall across the road. Downtown, the stadium, the river, the beach, the works and the
-- hills stay as the pack has them. A sea runs to the horizon all round, and the motorway goes
-- on over it on its pillars.
--
-- Pure data and arithmetic: no services. The World service builds what `placements()` lists
-- from the kit imported in Studio (or plain boxes when the kit isn't there).

local Tuning = require(script.Parent.Parent.Config.Tuning)
local Town = require(script.Parent.Town)
local CityPack = require(script.Parent.CityPack)

local CityMap = {}

local SIZE = Tuning.Plot.Size

-- Where the pack's frame lands in the game's: the pack's Main Street runs along its own X at
-- z = 269.43, and the plots' row is centred on the pack's x = -738.
CityMap.Offset = Vector3.new(738, 0, -269.43)
CityMap.SeaLevel = -3.57 -- the surface of the pack's own water
-- The pack's big ground slabs go down a little, so the plots' grass on top of them never
-- flickers, and the flat lots under the suburb's houses go down to just above them: where a lot
-- runs under a plot the plot's grass covers it, and behind the plots it is still the houses' lot.
CityMap.GroundDrop = 0.15
CityMap.LotTop = -0.08
-- The pack's land has holes where its lots, streets, car parks and the gas station bring their
-- own ground: what the town takes out shows this plain ground instead, a little lower, under all
-- of the west bank but the beach ({ x1, z1, x2, z2 } in the pack's frame).
CityMap.Filler = { -1396, -250, 18, 1203 }
CityMap.FillerTop = -0.22
-- A ground slab at least this big (studs², from above) is the land itself and always stays.
CityMap.LandArea = 150000

-- How each kind of pack object collides and is seen. Trees, parks and plants are walked through
-- (a tree gets a plain trunk to bump into); everything else is solid.
CityMap.Kinds = {
	road = { collide = true, query = true },
	ground = { collide = true, query = true },
	building = { collide = true, query = true },
	nature = { collide = false, query = false },
	vehicle = { collide = true, query = false },
	prop = { collide = true, query = false },
}

-- The ground of the plots: the pack's own flat grass, so a plot reads as part of the town's lawn
-- (it was a paler grass of its own and showed as a pale square in the deeper green round it), and
-- the land a player owns a step lighter so it still shows.
CityMap.PlotGround = Color3.fromRGB(76, 129, 51)
CityMap.OwnedGround = Color3.fromRGB(94, 142, 71)

-- The stand-ins' colours, when the kit isn't there (tools/preview/citypack.py has the same).
CityMap.StandIn = {
	road = Color3.fromRGB(107, 110, 117),
	ground = Color3.fromRGB(76, 129, 51), -- the pack's own grass
	building = Color3.fromRGB(219, 214, 204),
	nature = Color3.fromRGB(92, 140, 77),
	vehicle = Color3.fromRGB(191, 107, 97),
	prop = Color3.fromRGB(179, 168, 153),
	water = Color3.fromRGB(63, 117, 143), -- the pack's own water
	sand = Color3.fromRGB(222, 196, 140),
}

-- Main Street's height along X: flat between the plots, up the ramp to the motorway at the west
-- end, over the bridge to the east, and down into downtown. { x, y } points, y the road's top.
CityMap.StreetProfile = {
	{ -497, 21.43 },
	{ -354, 0.36 },
	{ 610, 0.36 },
	{ 753, 21.43 },
	{ 1110, 21.43 },
	{ 1253, 0.36 },
	{ 1328, 0.36 },
}

function CityMap.streetY(x: number): number
	local pts = CityMap.StreetProfile
	if x <= pts[1][1] then
		return pts[1][2]
	end
	for i = 2, #pts do
		local a, b = pts[i - 1], pts[i]
		if x <= b[1] then
			return a[2] + (b[2] - a[2]) * (x - a[1]) / (b[1] - a[1])
		end
	end
	return pts[#pts][2]
end

-- The middle of town's buildings, which are pack buildings put where the town needs them:
-- { key, centre x, centre z of its footprint, yaw in degrees, opens = the panel its door opens,
-- action = the prompt's words }. A building's front (its door and sign) faces its own +Z: the
-- tailor's (yaw 90) looks east over the green where people arrive, and the city hall across Main
-- Street (yaw -90) looks west onto the side street at its corner.
CityMap.Buildings = {
	{
		key = "boutique_01",
		x = 615,
		z = -65.4,
		yaw = 90,
		opens = "creator",
		action = "Make a villager",
		name = "Tailor",
	},
	{ key = "government_a", x = 615.1, z = 110, yaw = -90, opens = "city", action = "City hall", name = "Hall" },
}

-- Our own small things in the middle of town (Data/TownModels) by the street, facing the green
-- where people arrive (the welcome sign's words are on its back): { model, x, z, yaw, opens, action }.
export type Prop = {
	model: string,
	x: number,
	z: number,
	yaw: number,
	name: string,
	opens: string?,
	action: string?,
	tag: string?,
}
CityMap.Props = {
	{ model = "board", x = 652, z = -50, yaw = 180, opens = "news", action = "Town news", name = "Board" },
	{ model = "sign", x = 728, z = -48, yaw = 0, tag = "welcome", name = "Welcome" },
} :: { Prop }

-- Lawns where grass sways and fireflies come out at night: { centre x, centre z, half width,
-- half depth }. The green by the river.
CityMap.Lawns = { { 700, -96, 50, 52 } }

-- Where ducks paddle: { x, z, radius } on the river by the green.
CityMap.Ponds = { { 800, -120, 14 }, { 826, -180, 10 } }

-- The pack's Main Street tiles that are crossings or bus stops in front of the plots, and the
-- plain tile of the same length that takes each one's place there.
local STRAIGHT = {
	road_b_02 = "road_b_10",
	road_b_07 = "road_b_10",
	road_b_03 = "road_b_01",
	road_b_04 = "road_b_01",
}
local STRAIGHT_FROM, STRAIGHT_TO = -440, 440 -- along the plots' row, game x

-- The pack's traffic lights (on gantries over a carriageway, or on poles): in front of the plots
-- they stood at junctions that are gone, so they go too.
local SIGNALS = {
	streetsigns_03 = true,
	streetsigns_04 = true,
	streetsigns_05 = true,
	streetsigns_06 = true,
	streetsigns_07 = true,
	streetsigns_08 = true,
}

-- Kit keys the town doesn't place, and why. (They are in the kit all the same.)
CityMap.Unused = {
	water_a_06 = "the pack's sea north of town, 3,500 studs across: more than a part can be (the sea parts cover it)",
}

export type Piece = { name: string, size: Vector3, centre: Vector3, tris: number }
export type Placement = {
	key: string,
	kind: string,
	cf: CFrame, -- the key's own frame in the world
	scale: Vector3, -- how the key is stretched along its own axes
	lo: Vector3, -- the box round it, in the world
	hi: Vector3,
	name: string?, -- the middle of town's buildings: "Tailor", "Hall"
	added: boolean?, -- put there by this module, not by the pack
}

-- The kit's keys and their pieces.
local kit: { [string]: { kind: string, pieces: { Piece } } } = {}
for key, entry in CityPack.Kit do
	local pieces: { Piece } = {}
	for i = 2, #entry do
		local p = entry[i]
		table.insert(pieces, {
			name = p[1],
			size = Vector3.new(p[2], p[3], p[4]),
			centre = Vector3.new(p[5], p[6], p[7]),
			tris = p[8] or 0,
		})
	end
	kit[key] = { kind = entry[1], pieces = pieces }
end

function CityMap.kit(key: string): { kind: string, pieces: { Piece } }?
	return kit[key]
end

-- The box round a key's pieces in its own frame: (centre, size).
function CityMap.keyBox(key: string): (Vector3, Vector3)
	local k = kit[key]
	assert(k, "no kit key " .. key)
	local lo, hi = Vector3.one * math.huge, -Vector3.one * math.huge
	for _, p in k.pieces do
		lo = lo:Min(p.centre - p.size / 2)
		hi = hi:Max(p.centre + p.size / 2)
	end
	return (lo + hi) / 2, hi - lo
end

-- A piece's frame and size in the world for a placement.
function CityMap.pieceFrame(p: Placement, piece: Piece): (CFrame, Vector3)
	return p.cf * CFrame.new(piece.centre * p.scale), piece.size * p.scale
end

local function bounds(key: string, cf: CFrame, scale: Vector3): (Vector3, Vector3)
	local lo, hi = Vector3.one * math.huge, -Vector3.one * math.huge
	for _, piece in kit[key].pieces do
		local h = piece.size * scale / 2
		local c = piece.centre * scale
		for _, sx in { -1, 1 } do
			for _, sy in { -1, 1 } do
				for _, sz in { -1, 1 } do
					local w = cf * (c + Vector3.new(sx * h.X, sy * h.Y, sz * h.Z))
					lo = lo:Min(w)
					hi = hi:Max(w)
				end
			end
		end
	end
	return lo, hi
end

local function make(key: string, cf: CFrame, scale: Vector3, added: boolean?, name: string?): Placement
	local lo, hi = bounds(key, cf, scale)
	return { key = key, kind = kit[key].kind, cf = cf, scale = scale, lo = lo, hi = hi, added = added, name = name }
end

-- A key stood on the ground with the middle of its footprint at (x, z), turned yaw degrees.
function CityMap.standing(key: string, x: number, z: number, yaw: number, y: number?): CFrame
	local c, s = CityMap.keyBox(key)
	local turn = CFrame.Angles(0, math.rad(yaw), 0)
	local foot = Vector3.new(c.X, c.Y - s.Y / 2, c.Z)
	return CFrame.new(Vector3.new(x, y or 0, z) - turn:VectorToWorldSpace(foot)) * turn
end

-- The plots' squares and the other places that must be clear, in the world, with what may stay
-- inside: "land" keeps only the land (and the lots, sunk under the plots), "street" lets Main
-- Street's tiles stay, "notVehicles" takes only the parked cars.
export type Zone = { x1: number, z1: number, x2: number, z2: number, keep: string, why: string }
local function zone(x1: number, z1: number, x2: number, z2: number, keep: string, why: string): Zone
	return { x1 = x1, z1 = z1, x2 = x2, z2 = z2, keep = keep, why = why }
end

function CityMap.zones(): { Zone }
	local out: { Zone } = {}
	for i = 1, Tuning.Plot.Count do
		local f = Town.plotFrame(i)
		local a = f * Vector3.new(0, 0, 0)
		local b = f * Vector3.new(SIZE, 0, SIZE)
		table.insert(
			out,
			zone(math.min(a.X, b.X), math.min(a.Z, b.Z), math.max(a.X, b.X), math.max(a.Z, b.Z), "land", "plot " .. i)
		)
	end
	-- where each owner arrives, on the sidewalk in front of their plot, there's room to stand
	for i = 1, Tuning.Plot.Count do
		local at = Town.plotArrival(i).Position
		table.insert(out, zone(at.X - 4, at.Z - 4, at.X + 4, at.Z + 4, "street", "plot " .. i))
	end
	-- the parked cars come off Main Street: the game's own cars drive there
	local hw = Town.StreetHalfWidth
	table.insert(out, zone(Town.StreetWest, -hw, Town.StreetEast, hw, "notVehicles", "Main Street"))
	for _, name in { "Spawn", "Festival" } do
		local spot: Vector3 = (Town.Spots :: any)[name]
		local r = 12
		table.insert(out, zone(spot.X - r, spot.Z - r, spot.X + r, spot.Z + r, "land", name))
	end
	for _, b in CityMap.Buildings do
		local _, s = CityMap.keyBox(b.key)
		local turned = math.abs(math.cos(math.rad(b.yaw))) < 0.5
		local w, d = if turned then s.Z else s.X, if turned then s.X else s.Z
		table.insert(out, zone(b.x - w / 2 - 2, b.z - d / 2 - 2, b.x + w / 2 + 2, b.z + d / 2 + 2, "street", b.name))
	end
	for _, p in CityMap.Props do
		table.insert(out, zone(p.x - 6, p.z - 6, p.x + 6, p.z + 6, "street", p.name))
	end
	return out
end

local function isLand(p: Placement): boolean
	if p.kind ~= "ground" then
		return false
	end
	return (p.hi.X - p.lo.X) * (p.hi.Z - p.lo.Z) >= CityMap.LandArea
end

-- A flat lot (a ground slab that is not the land itself).
local function isLot(p: Placement): boolean
	return p.kind == "ground" and not isLand(p) and p.hi.Y - p.lo.Y < 0.6
end

local function keeps(rule: string, p: Placement): boolean
	if isLand(p) then
		return true
	end
	if rule == "land" and isLot(p) then
		return true -- sunk under the plot (see placements)
	end
	if rule == "notVehicles" then
		return p.kind ~= "vehicle"
	elseif rule == "street" then
		return p.kind == "road" and math.abs((p.lo.Z + p.hi.Z) / 2) < Town.StreetHalfWidth + 8
	end
	return false
end

local function touches(z: Zone, p: Placement): boolean
	local e = 0.5 -- a hair inside the edge counts, touching from outside doesn't
	return p.hi.X > z.x1 + e and p.lo.X < z.x2 - e and p.hi.Z > z.z1 + e and p.lo.Z < z.z2 - e
end

-- The motorway runs off the pack's land at its north west and south west corners: it goes on
-- over the sea, on pillars long enough to stand in the water, until the haze hides it.
local MOTORWAY_SEGMENTS = 14
local toSea: (Placement) -> Placement
local function motorway(out: { Placement })
	local seg = CityPack.Kit.road_c_01
	if not seg then
		return
	end
	local len = seg[2][4] -- the segment's length along its own Z
	local y = 12.99 -- where the pack has the segments' middles
	local o = CityMap.Offset
	local function add(cf: CFrame)
		local p = toSea(make("road_c_01", cf, Vector3.one, true))
		p.added = true
		table.insert(out, p)
	end
	-- south: both carriageways go on along +Z from the pack's last segment (z 1235.27)
	for _, x in { -1272.63, -1358.11 } do
		for k = 1, MOTORWAY_SEGMENTS do
			add(CFrame.new(Vector3.new(x, y, 1235.27 + k * len) + o))
		end
	end
	-- west: both carriageways go on along -X past the pack's last pieces (which end at x -1453)
	for _, z in { -234.14, -148.43 } do
		for k = 1, MOTORWAY_SEGMENTS do
			add(CFrame.new(Vector3.new(-1452.98 - (k - 0.5) * len, y, z) + o) * CFrame.Angles(0, math.pi / 2, 0))
		end
	end
end

-- The pack's land ends here (world x, z): the motorway pieces past it stand in the sea.
local LAND_WEST = -1396 + CityMap.Offset.X
local LAND_SOUTH = 1203 + CityMap.Offset.Z
toSea = function(p: Placement): Placement
	local c, s = CityMap.keyBox(p.key)
	local top = (p.cf * Vector3.new(c.X, c.Y + s.Y / 2, c.Z)).Y
	local sy = (top - CityMap.SeaLevel) / s.Y
	local scale = Vector3.new(p.scale.X, sy, p.scale.Z)
	local y = top - (c.Y + s.Y / 2) * sy
	return make(p.key, p.cf + Vector3.new(0, y - p.cf.Position.Y, 0), scale)
end

local cached: { Placement }? = nil
local removedList: { { key: string, kind: string, why: string, lo: Vector3, hi: Vector3 } } = {}

-- Everything of the pack the town has, in the world, and what was added: the middle of town's
-- buildings, the plain street tiles in front of the plots, the motorway over the sea.
function CityMap.placements(): { Placement }
	if cached then
		return cached
	end
	local o = CityMap.Offset
	local all: { Placement } = {}
	local dropped: { { key: string, kind: string, why: string, lo: Vector3, hi: Vector3 } } = {}
	for _, row in CityPack.Placed do
		local key = row[1]
		if CityMap.Unused[key] then
			continue
		end
		local rx, rz = row[6] or 0, row[7] or 0
		local cf = CFrame.new(Vector3.new(row[2], row[3], row[4]) + o)
			* CFrame.fromEulerAnglesYXZ(math.rad(rx), math.rad(row[5]), math.rad(rz))
		local scale = if row[8] then Vector3.new(row[8], row[9], row[10]) else Vector3.one
		local p = make(key, cf, scale)
		-- the junctions and bus stops in front of the plots become plain road
		local swap = STRAIGHT[key]
		local x = cf.Position.X
		if swap and x > STRAIGHT_FROM and x < STRAIGHT_TO and math.abs(cf.Position.Z) < 12 then
			local turn = CFrame.Angles(0, math.rad(row[5]), 0)
			local c, s = CityMap.keyBox(swap)
			local base = Vector3.new(x, 0, 0) - turn:VectorToWorldSpace(Vector3.new(c.X, c.Y - s.Y / 2, c.Z))
			p = make(swap, CFrame.new(base) * turn, Vector3.one, true)
		end
		if SIGNALS[key] and x > STRAIGHT_FROM and x < STRAIGHT_TO and math.abs(cf.Position.Z) < 45 then
			table.insert(dropped, { key = key, kind = p.kind, why = "no junction", lo = p.lo, hi = p.hi })
			continue
		end
		if isLand(p) then
			p = make(key, p.cf - Vector3.new(0, CityMap.GroundDrop, 0), scale)
		elseif isLot(p) then
			p = make(key, p.cf - Vector3.new(0, p.hi.Y - CityMap.LotTop, 0), scale)
		elseif key:sub(1, 7) == "road_c_" and (p.lo.X < LAND_WEST or p.hi.Z > LAND_SOUTH) then
			p = toSea(p) -- a motorway piece off the land's edge: its pillars reach the water
		end
		table.insert(all, p)
	end
	motorway(all)

	local zones = CityMap.zones()
	local out: { Placement } = {}
	table.clear(removedList)
	for _, d in dropped do
		table.insert(removedList, d)
	end
	for _, p in all do
		local why = nil
		for _, z in zones do
			if touches(z, p) and not keeps(z.keep, p) then
				why = z.why
				break
			end
		end
		if why then
			table.insert(removedList, { key = p.key, kind = p.kind, why = why, lo = p.lo, hi = p.hi })
		else
			table.insert(out, p)
		end
	end
	for _, b in CityMap.Buildings do
		table.insert(out, make(b.key, CityMap.standing(b.key, b.x, b.z, b.yaw), Vector3.one, true, b.name))
	end
	-- a parked car whose street or car park went stands on nothing: it goes too
	local kept: { Placement } = {}
	for _, p in out do
		local under = p.kind ~= "vehicle"
		if not under then
			local c = (p.lo + p.hi) / 2
			for _, q in out do
				if
					(q.kind == "road" or q.kind == "building")
					and c.X >= q.lo.X
					and c.X <= q.hi.X
					and c.Z >= q.lo.Z
					and c.Z <= q.hi.Z
				then
					under = true
					break
				end
			end
		end
		if under then
			table.insert(kept, p)
		else
			table.insert(removedList, { key = p.key, kind = p.kind, why = "off the road", lo = p.lo, hi = p.hi })
		end
	end
	cached = kept
	return kept
end

-- What the layout took away, and why (a plot, Main Street, a spot, a building's footprint).
function CityMap.removed(): { { key: string, kind: string, why: string, lo: Vector3, hi: Vector3 } }
	CityMap.placements()
	return removedList
end

-- Where a middle of town building's door is: on the ground a step in front of its front face,
-- and the way out of it.
function CityMap.door(name: string): (Vector3, Vector3)
	for _, b in CityMap.Buildings do
		if b.name == name then
			local _, s = CityMap.keyBox(b.key)
			local turn = CFrame.Angles(0, math.rad(b.yaw), 0)
			local out = turn:VectorToWorldSpace(Vector3.zAxis)
			return Vector3.new(b.x, 0, b.z) + out * (s.Z / 2 + 2), out
		end
	end
	error("no building " .. name)
end

-- How the kit imported in Studio stands against the manifest. `found` maps each MeshPart's name
-- to its Size and CFrame as the import made them. Studio puts a part's mesh round the middle of
-- its box and may have turned the file a quarter or half turn about the vertical, or read its
-- units differently: the sizes tell a quarter turn and the scale, and the pieces of a key cut in
-- two tell a half turn (their middles swap sides). Returns the quarter turns to undo (0..3), the
-- scale the import used, and what doesn't fit (a mirror, a piece of the wrong shape).
function CityMap.fit(found: { [string]: { size: Vector3, cf: CFrame } }): (number, number, { string })
	local byName: { [string]: Piece } = {}
	local splits: { { Piece } } = {}
	for key, k in kit do
		if CityMap.Unused[key] then
			continue
		end
		for _, piece in k.pieces do
			byName[piece.name] = piece
		end
		if #k.pieces >= 2 then
			table.insert(splits, k.pieces)
		end
	end
	local function close(a: number, b: number): boolean
		return math.abs(a - b) <= math.max(0.06, 0.03 * math.max(math.abs(a), math.abs(b)))
	end
	-- the scale, from the heights (a turn about the vertical leaves them alone)
	local ratios: { number } = {}
	for name, f in found do
		local piece = byName[name]
		if piece and piece.size.Y > 2 then
			table.insert(ratios, f.size.Y / piece.size.Y)
		end
	end
	table.sort(ratios)
	local scale = if #ratios > 0 then ratios[math.floor(#ratios / 2) + 1] else 1
	-- a quarter turn or not, from the plan sizes
	local straight, quarter = 0, 0
	for name, f in found do
		local piece = byName[name]
		if piece and math.abs(piece.size.X - piece.size.Z) > 1 then
			local s = piece.size * scale
			if close(f.size.X, s.X) and close(f.size.Z, s.Z) then
				straight += 1
			elseif close(f.size.X, s.Z) and close(f.size.Z, s.X) then
				quarter += 1
			end
		end
	end
	local odd = quarter > straight
	-- a half turn or not, from where a cut key's pieces sit against each other
	local votes = { 0, 0, 0, 0 }
	local mirrored = 0
	for _, pieces in splits do
		local a, b = pieces[1], pieces[2]
		local fa, fb = found[a.name], found[b.name]
		if fa and fb then
			local want = (b.centre - a.centre) * scale
			if want.Magnitude > 1 then
				local got = fa.cf:VectorToObjectSpace(fb.cf.Position - fa.cf.Position)
				local best, bestErr = 0, math.huge
				for k = 0, 3 do
					local q = CFrame.Angles(0, k * math.pi / 2, 0):VectorToWorldSpace(want)
					local err = (q - got).Magnitude
					if err < bestErr then
						best, bestErr = k, err
					end
					local m = Vector3.new(-q.X, q.Y, q.Z)
					if (m - got).Magnitude < want.Magnitude * 0.05 and err > want.Magnitude * 0.05 then
						mirrored += 1
					end
				end
				if bestErr < want.Magnitude * 0.05 + 0.1 then
					votes[best + 1] += 1
				end
			end
		end
	end
	local turn = if odd then 1 else 0
	if votes[turn + 3] > votes[turn + 1] then
		turn += 2
	end
	local problems: { string } = {}
	if mirrored > 0 then
		table.insert(problems, "the kit came in mirrored (look at the bank's sign in Studio)")
	end
	for name, f in found do
		local piece = byName[name]
		if piece then
			local s = piece.size * scale
			if turn % 2 == 1 then
				s = Vector3.new(s.Z, s.Y, s.X)
			end
			if not (close(f.size.X, s.X) and close(f.size.Y, s.Y) and close(f.size.Z, s.Z)) then
				table.insert(problems, ("%s is %s, the kit says %s"):format(name, tostring(f.size), tostring(s)))
			end
		end
	end
	table.sort(problems)
	return turn, scale, problems
end

-- A tree's trunk to bump into, since the tree itself is walked through: (frame, size) or nil.
function CityMap.trunk(p: Placement): (CFrame?, Vector3?)
	if p.key:sub(1, 5) ~= "tree_" then
		return nil, nil
	end
	local c, s = CityMap.keyBox(p.key)
	local foot = p.cf * (Vector3.new(c.X, c.Y - s.Y / 2, c.Z) * p.scale)
	local h = math.min(8, s.Y * p.scale.Y * 0.4)
	return CFrame.new(foot + Vector3.new(0, h / 2, 0)), Vector3.new(1.6, h, 1.6)
end

-- The sea round the pack's land, out to the horizon, as plain parts: the water over a sea floor
-- (both in tiles, since a part is at most 2048 studs), and walls nobody sees a long swim out.
-- The pack's own sea north of the town is one mesh too big for a part (Unused), so the water
-- covers it too: it runs everywhere but over the land's rectangle, and the shore's slabs reach
-- down into it.
CityMap.PackRect = { -1396, -843, 2108, 1203 } -- the pack's land and water, in its own frame
CityMap.LandRect = { -1396, -168, 2108, 1203 } -- where the pack has its own water (the river)
local FAR = 4096
local TILE = 2048
local WALL = 360 -- the walls stand this far off the pack's edges
function CityMap.sea(): { any }
	local o = CityMap.Offset
	local r = CityMap.PackRect
	local x1, z1, x2, z2 = r[1] + o.X, r[2] + o.Z, r[3] + o.X, r[4] + o.Z
	local l = CityMap.LandRect
	local lx1, lz1, lx2, lz2 = l[1] + o.X, l[2] + o.Z, l[3] + o.X, l[4] + o.Z
	local out: { any } = {}
	local function slab(a: number, b: number, c: number, d: number, y1: number, y2: number, name: string)
		local x = a
		while x < c - 0.01 do
			local w = math.min(TILE, c - x)
			local z = b
			while z < d - 0.01 do
				local dd = math.min(TILE, d - z)
				table.insert(out, {
					name = name,
					cf = CFrame.new(x + w / 2, (y1 + y2) / 2, z + dd / 2),
					size = Vector3.new(w, y2 - y1, dd),
				})
				z += dd
			end
			x += w
		end
	end
	-- the water: a frame round the land (the pack has its own river inside)
	local sy = CityMap.SeaLevel
	for _, band in
		{
			{ lx1 - FAR, lz1 - FAR, lx2 + FAR, lz1 },
			{ lx1 - FAR, lz2, lx2 + FAR, lz2 + FAR },
			{ lx1 - FAR, lz1, lx1, lz2 },
			{ lx2, lz1, lx2 + FAR, lz2 },
		}
	do
		slab(band[1], band[2], band[3], band[4], sy - 0.4, sy, "Water")
		slab(band[1], band[2], band[3], band[4], -22, -20, "SeaFloor")
	end
	for _, w in
		{
			{ x1 - WALL, z1 - WALL - 2, x2 + WALL, z1 - WALL },
			{ x1 - WALL, z2 + WALL, x2 + WALL, z2 + WALL + 2 },
			{ x1 - WALL - 2, z1 - WALL, x1 - WALL, z2 + WALL },
			{ x2 + WALL, z1 - WALL, x2 + WALL + 2, z2 + WALL },
		}
	do
		slab(w[1], w[2], w[3], w[4], -22, 80, "SeaWall")
	end
	return out
end

-- The plain ground under the suburb (see Filler), in the world: (frame, size).
function CityMap.filler(): (CFrame, Vector3)
	local o = CityMap.Offset
	local f = CityMap.Filler
	local top = CityMap.FillerTop
	local size = Vector3.new(f[3] - f[1], 2, f[4] - f[2])
	return CFrame.new((f[1] + f[3]) / 2 + o.X, top - 1, (f[2] + f[4]) / 2 + o.Z), size
end

-- Is a point (x, z) on the pack's land or water, in the world?
function CityMap.inPack(pos: Vector3): boolean
	local o = CityMap.Offset
	local r = CityMap.PackRect
	return pos.X >= r[1] + o.X and pos.X <= r[3] + o.X and pos.Z >= r[2] + o.Z and pos.Z <= r[4] + o.Z
end

return CityMap
