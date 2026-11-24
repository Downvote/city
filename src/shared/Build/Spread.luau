--!strict
-- Opening a building up. The user: "make the houses and other buildings bigger such that the
-- interior feels much more spacious". A ready-made building (Data/Presets, Data/Buildings) and
-- the starting house (Data/StarterHouse) are drawn with their rooms tight, then floor is let in
-- along lines across them, the way a builder pushes a wall out:
--
-- a cut { at, by } along x moves everything whose x is past `at` on by `by` studs (the same along
-- z). Walls, floors and roofs that cross the line get longer; a piece of furniture moves whole
-- with the side its middle is on, so a bed stays against its wall and a table keeps its chairs;
-- a door, a window or anything hung on a wall keeps to its side of the line in the same way. A
-- row of the same piece laid end to end (the stones along a wall's foot, a picket fence, porch
-- rails, a flower border) stays a row: the gap the line opens in it is filled with more of it.
--
-- Cuts go across open floor. One that runs along a wall's line, a floor's edge or a roof's edge
-- would tear the building apart, so Spread.apply refuses it. `by` keeps to the 2 stud wall grid.

local Catalog = require(script.Parent.Catalog)
local Tuning = require(script.Parent.Parent.Config.Tuning)

local Spread = {}

export type Cut = { number } -- { at, by }
export type Cuts = { x: { Cut }?, z: { Cut }? }
-- An object as the callers hold it: its kind, its fields, and for something hung on a wall the
-- wall it hangs on (before the spread; Spread.apply moves the wall itself when it meets it as an
-- object of its own).
export type Entry = { kind: string, obj: any, wall: any? }

-- Pieces that are laid in rows end to end, and how a gap in the row is filled: "cover" leaves no
-- gap (the new pieces overlap their neighbours a little: a fence or a stone course must not open
-- up), "fit" puts in as many whole pieces as fit with even gaps between them (a run of counters,
-- a wall of bookcases).
Spread.Rows = {
	stone_footing = "cover",
	fence_picket = "cover",
	porch_rail = "cover",
	flower_border = "fit",
	counter = "fit",
	bookcase_tall = "fit",
}

-- Where a coordinate ends up.
local NONE: { Cut } = {}

function Spread.axis(list: { Cut }?, v: number): number
	local out = v
	for _, c in list or NONE do
		if v > c[1] + 1e-6 then
			out += c[2]
		end
	end
	return out
end

function Spread.point(cuts: Cuts, x: number, z: number): (number, number)
	return Spread.axis(cuts.x, x), Spread.axis(cuts.z, z)
end

-- What a building w by d becomes.
function Spread.size(cuts: Cuts, w: number, d: number): (number, number)
	return Spread.axis(cuts.x, w), Spread.axis(cuts.z, d)
end

-- The bands of new floor, in the coordinates after the spread: { from, to } along each axis.
function Spread.bands(cuts: Cuts): { x: { { number } }, z: { { number } } }
	local function along(list: { Cut }?): { { number } }
		local bands = {}
		for _, c in list or NONE do
			local from = Spread.axis(list, c[1])
			table.insert(bands, { from, from + c[2] })
		end
		return bands
	end
	return { x = along(cuts.x), z = along(cuts.z) }
end

local function onCut(list: { Cut }?, v: number): boolean
	for _, c in list or NONE do
		if math.abs(v - c[1]) < 1e-6 then
			return true
		end
	end
	return false
end

local function check(cuts: Cuts, e: Entry)
	local o = e.obj
	local snap = Tuning.Plot.WallSnap
	for _, list: { Cut } in { cuts.x or NONE, cuts.z or NONE } do
		for _, c in list do
			assert(c[2] > 0 and (c[2] / snap) % 1 == 0, "a cut lets in whole grid squares")
		end
	end
	if e.kind == "walls" or e.kind == "floors" or e.kind == "roofs" then
		local bad = onCut(cuts.x, o.x1) or onCut(cuts.x, o.x2) or onCut(cuts.z, o.z1) or onCut(cuts.z, o.z2)
		assert(not bad, string.format("a cut runs along the edge of a %s at %g, %g", e.kind, o.x1, o.z1))
	end
end

local function wallLength(w: any): number
	return math.sqrt((w.x2 - w.x1) ^ 2 + (w.z2 - w.z1) ^ 2)
end

local function copy(t: any): any
	if type(t) ~= "table" then
		return t
	end
	local out = {}
	for k, v in t do
		out[k] = copy(v)
	end
	return out
end

-- How long one piece of a row is, along the row.
local function rowLength(id: string): number
	local def = Catalog.get(id)
	return if def then def.size.X else 4
end

-- Spreads the entries in place, and returns the pieces that fill the gaps opened in rows (each an
-- entry of the same kind, hanging on the same wall where it hangs on one).
function Spread.apply(cuts: Cuts, entries: { Entry }): { Entry }
	for _, e in entries do
		check(cuts, e)
	end
	-- where things hung on walls go, worked out on the walls as they were
	local hung: { [Entry]: number } = {}
	local before: { [Entry]: number } = {}
	for _, e in entries do
		local w = e.wall
		if w then
			local len = wallLength(w)
			local dx, dz = (w.x2 - w.x1) / len, (w.z2 - w.z1) / len
			local t = e.obj.t or 0
			local px, pz = Spread.point(cuts, w.x1 + dx * t, w.z1 + dz * t)
			local ax, az = Spread.point(cuts, w.x1, w.z1)
			local bx, bz = Spread.point(cuts, w.x2, w.z2)
			local nlen = math.sqrt((bx - ax) ^ 2 + (bz - az) ^ 2)
			hung[e] = ((px - ax) * (bx - ax) + (pz - az) * (bz - az)) / nlen
			before[e] = t
		end
	end
	-- rows, before anything moves: the same piece laid end to end, each with the next along
	local rows: { [string]: { any } } = {}
	local walls: { [any]: string } = {}
	local wallCount = 0
	for _, e in entries do
		local o = e.obj
		if e.kind == "items" and Spread.Rows[o.id] and (e.wall or o.r % 90 == 0) then
			local key, along
			if e.wall then
				if not walls[e.wall] then
					wallCount += 1
					walls[e.wall] = tostring(wallCount)
				end
				key = "w" .. walls[e.wall] .. tostring(o.side)
				along = before[e]
			elseif o.r % 180 == 0 then
				key = string.format("x%.2f", o.z)
				along = o.x
			else
				key = string.format("z%.2f", o.x)
				along = o.z
			end
			-- (whatever their paint: a border of flowers in turn pink and lilac is still one row)
			key = string.format("%s|%s|%.2f|%d", key, o.id, o.y, o.lv)
			rows[key] = rows[key] or {}
			table.insert(rows[key], { e, along } :: { any })
		end
	end
	local pairs_: { { Entry } } = {}
	local keys = {}
	for key in rows do
		table.insert(keys, key)
	end
	table.sort(keys) -- (the same fills in the same order every time)
	for _, key in keys do
		local row = rows[key]
		table.sort(row, function(p, q)
			return p[2] < q[2]
		end)
		for i = 1, #row - 1 do
			local len = rowLength(row[i][1].obj.id)
			if row[i + 1][2] - row[i][2] <= len + 0.15 then
				table.insert(pairs_, { row[i][1], row[i + 1][1] })
			end
		end
	end
	-- what stands on top of another piece (a lamp on a desk, a kettle on a counter) must move
	-- with it: a line between them would leave it in the air
	local stands: { { Entry } } = {}
	for _, a in entries do
		if a.kind == "items" and not a.wall then
			for _, b in entries do
				local def = if b ~= a and b.kind == "items" and not b.wall then Catalog.get(b.obj.id) else nil
				if
					def
					and def.surface
					and b.obj.lv == a.obj.lv
					and math.abs(a.obj.y - (b.obj.y + def.surface)) < 0.05
				then
					local rad = math.rad(b.obj.r)
					local c, sn = math.abs(math.cos(rad)), math.abs(math.sin(rad))
					local hx = (def.size.X * c + def.size.Z * sn) / 2
					local hz = (def.size.X * sn + def.size.Z * c) / 2
					if math.abs(a.obj.x - b.obj.x) <= hx and math.abs(a.obj.z - b.obj.z) <= hz then
						table.insert(stands, { a, b })
					end
				end
			end
		end
	end
	local function moved(e: Entry): (number, number)
		local x, z = Spread.point(cuts, e.obj.x, e.obj.z)
		return x - e.obj.x, z - e.obj.z
	end
	for _, pair in stands do
		local ax, az = moved(pair[1])
		local bx, bz = moved(pair[2])
		assert(
			math.abs(ax - bx) < 1e-6 and math.abs(az - bz) < 1e-6,
			string.format("a cut runs between %s and the %s it stands on", pair[1].obj.id, pair[2].obj.id)
		)
	end
	-- now move everything
	for _, e in entries do
		local o = e.obj
		if e.kind == "walls" or e.kind == "floors" or e.kind == "roofs" then
			o.x1, o.z1 = Spread.point(cuts, o.x1, o.z1)
			o.x2, o.z2 = Spread.point(cuts, o.x2, o.z2)
		elseif e.kind == "items" and not e.wall then
			o.x, o.z = Spread.point(cuts, o.x, o.z)
		end
	end
	for e, t in hung do
		e.obj.t = t
	end
	-- and fill the rows the lines opened
	local fills: { Entry } = {}
	for _, pair in pairs_ do
		local a, b = pair[1], pair[2]
		local len = rowLength(a.obj.id)
		local from, to
		if a.wall then
			from, to = math.min(a.obj.t, b.obj.t), math.max(a.obj.t, b.obj.t)
		elseif a.obj.r % 180 == 0 then
			from, to = math.min(a.obj.x, b.obj.x), math.max(a.obj.x, b.obj.x)
		else
			from, to = math.min(a.obj.z, b.obj.z), math.max(a.obj.z, b.obj.z)
		end
		local gap = to - from - len -- the bare stretch between the two pieces
		local n = if Spread.Rows[a.obj.id] == "cover" then math.ceil(gap / len - 1e-6) else math.floor(gap / len + 0.05)
		if gap > 0.05 and n > 0 then
			-- spread evenly along the gap
			for i = 1, n do
				local at = from + (to - from) * i / (n + 1)
				local o = copy(a.obj)
				if a.wall then
					o.t = at
				elseif a.obj.r % 180 == 0 then
					o.x = at
				else
					o.z = at
				end
				table.insert(fills, { kind = "items", obj = o, wall = a.wall })
			end
		end
	end
	return fills
end

return Spread
