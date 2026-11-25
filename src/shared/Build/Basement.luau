--!strict
-- The basement: floor -1, under the ground floor. The user: "add gamepasses, just like bloxburg.
-- add collisions, and a gamepass should be there to remove it, another for basement, another for
-- more levels ...". What a basement is, as plain data and rules, for the plan (Plan.validate,
-- Plan.removeOps), the drawing (the Builder: the concrete lining round its open sides), the server
-- (Services/Basement digs the ground) and Build mode (the ground hidden while floor -1 is shown).
--
-- A basement room is its floor: a floor on level -1 opens the ground over it. The plot's ground
-- parts are cut round its rectangle exactly, and the terrain under it is dug out in whole voxels,
-- from under its slab (Basement.Bottom, 12 under the ground) up to the ground, so the dig reaches
-- up to 2 studs past a floor's edge where the edge isn't on the terrain's grid. The lining stands
-- in that gap under the ground, so the room has clean concrete sides wherever nobody has built a
-- wall. Walls, stairs and furniture on level -1 stand over a basement floor, and selling a floor
-- takes along what only it held up. Water keeps clear of a basement's dig, and a basement of the
-- water's. A stair on level -1 climbs to the ground floor and cuts its hole in the floor there.
--
-- No services, so the specs run it.

local Tuning = require(script.Parent.Parent.Config.Tuning)
local Catalog = require(script.Parent.Catalog)
local Geometry = require(script.Parent.Geometry)

local P = Tuning.Plot
local B = Tuning.Basement

local Basement = {}

export type Rect = { number } -- x1, z1, x2, z2 on the plot

Basement.Level = P.Lowest -- the basement's level in a plan: -1
Basement.Voxel = 4 -- the terrain's voxels
Basement.Offset = 2 -- the terrain's grid lies 2 past the plot's own (Town.plotFrame; Build/Water too)
Basement.Bottom = Basement.Level * P.LevelHeight -- -12: under the basement's slab, where the dig stops
Basement.Top = 0 -- the ground
Basement.LiningColor = Color3.fromRGB(168, 162, 152)

local EPS = 1e-3

local function finite(n: any): boolean
	return type(n) == "number" and n == n and n ~= math.huge and n ~= -math.huge
end

-- Every basement floor's rectangle, less the floor `ignoreKey` and with `extra` (a floor being put
-- down or moved) added.
function Basement.rects(plan: any, ignoreKey: string?, extra: Rect?): { Rect }
	local out: { Rect } = {}
	for key, f in (plan and plan.floors) or {} do
		if key ~= ignoreKey and type(f) == "table" and f.lv == Basement.Level then
			if finite(f.x1) and finite(f.z1) and finite(f.x2) and finite(f.z2) then
				table.insert(out, { f.x1, f.z1, f.x2, f.z2 })
			end
		end
	end
	if extra then
		table.insert(out, extra)
	end
	return out
end

-- Is there a basement anywhere on the plan?
function Basement.has(plan: any): boolean
	for _, f in (plan and plan.floors) or {} do
		if type(f) == "table" and f.lv == Basement.Level then
			return true
		end
	end
	return false
end

-- Is the point over a basement floor (its edges count)?
function Basement.onFloor(rects: { Rect }, x: number, z: number): boolean
	for _, r in rects do
		if x >= r[1] - EPS and x <= r[3] + EPS and z >= r[2] - EPS and z <= r[4] + EPS then
			return true
		end
	end
	return false
end

-- What of rectangle `r` is left once every rectangle in `cuts` is taken out of it.
local function leftOver(r: Rect, cuts: { Rect }): { Rect }
	local rects = { r }
	for _, h in cuts do
		local out = {}
		for _, q in rects do
			local x1, z1, x2, z2 = q[1], q[2], q[3], q[4]
			local hx1, hz1, hx2, hz2 = math.max(h[1], x1), math.max(h[2], z1), math.min(h[3], x2), math.min(h[4], z2)
			if hx1 >= hx2 - EPS or hz1 >= hz2 - EPS then
				table.insert(out, q)
			else
				if hz1 > z1 + EPS then
					table.insert(out, { x1, z1, x2, hz1 })
				end
				if hz2 < z2 - EPS then
					table.insert(out, { x1, hz2, x2, z2 })
				end
				if hx1 > x1 + EPS then
					table.insert(out, { x1, hz1, hx1, hz2 })
				end
				if hx2 < x2 - EPS then
					table.insert(out, { hx2, hz1, x2, hz2 })
				end
			end
		end
		rects = out
	end
	return rects
end

-- Is the rectangle wholly over basement floors? `slack` lets it reach that far past them (a piece's
-- footprint may hang a hair over a floor's edge, as it may over the land's).
function Basement.covers(rects: { Rect }, x1: number, z1: number, x2: number, z2: number, slack: number?): boolean
	local g = slack or 0
	local r = { x1 + g, z1 + g, x2 - g, z2 - g }
	if r[3] <= r[1] + EPS or r[4] <= r[2] + EPS then
		return Basement.onFloor(rects, (x1 + x2) / 2, (z1 + z2) / 2)
	end
	for _, left in leftOver(r, rects) do
		if left[3] - left[1] > EPS and left[4] - left[2] > EPS then
			return false
		end
	end
	return true
end

-- Does a wall from (x1, z1) to (x2, z2) run over basement floors all the way (along their edges
-- counts)? Looked at every half stud.
function Basement.carries(rects: { Rect }, x1: number, z1: number, x2: number, z2: number): boolean
	local len = math.sqrt((x2 - x1) ^ 2 + (z2 - z1) ^ 2)
	local n = math.max(1, math.ceil(len / 0.5))
	for i = 0, n do
		local t = i / n
		if not Basement.onFloor(rects, x1 + (x2 - x1) * t, z1 + (z2 - z1) * t) then
			return false
		end
	end
	return true
end

-- The ground a piece covers (as Plan.itemRect has it: this module can't ask Plan).
local function footprint(item: any): (number, number, number, number)
	local def = Catalog.get(item.id)
	local size = if def then def.size else Vector3.new(1, 1, 1)
	local a = math.rad(if finite(item.r) then item.r else 0)
	local c, s = math.abs(math.cos(a)), math.abs(math.sin(a))
	local hx = (size.X * c + size.Z * s) / 2
	local hz = (size.X * s + size.Z * c) / 2
	return item.x - hx, item.z - hz, item.x + hx, item.z + hz
end

-- Digging ---------------------------------------------------------------------------------------------

-- The block of ground a basement floor digs, on the plot: its rectangle out to the terrain's grid.
function Basement.block(r: Rect): Rect
	local V, O = Basement.Voxel, Basement.Offset
	return {
		math.floor((r[1] - O) / V + EPS) * V + O,
		math.floor((r[2] - O) / V + EPS) * V + O,
		math.ceil((r[3] - O) / V - EPS) * V + O,
		math.ceil((r[4] - O) / V - EPS) * V + O,
	}
end

-- Every block of ground the plan's basement digs (they may overlap: Services/Basement digs their
-- columns once).
function Basement.blocks(plan: any): { Rect }
	local out = {}
	for _, r in Basement.rects(plan) do
		table.insert(out, Basement.block(r))
	end
	return out
end

local function overlaps(a: Rect, x1: number, z1: number, x2: number, z2: number): boolean
	return a[1] < x2 - EPS and a[3] > x1 + EPS and a[2] < z2 - EPS and a[4] > z1 + EPS
end

-- Rules ----------------------------------------------------------------------------------------------------

Basement.Why = {
	noFloor = "dig a basement floor there first",
	edge = "too close to the edge of your land",
	water = "too close to the water",
	roof = "roofs go above the ground",
	stranded = "move what stands on it first",
	basement = "too close to the basement",
}

-- What on level -1 stands over no basement floor once the floors are `rects` (a floor sold, moved or
-- made smaller): walls and free standing pieces, as { kind, key }, walls first. What hangs on a wall
-- goes with its wall (Plan.removeOps).
function Basement.stranded(plan: any, rects: { Rect }): { { kind: string, key: string } }
	local out = {}
	local walls, items = {}, {}
	for key, w in (plan and plan.walls) or {} do
		if type(w) == "table" and w.lv == Basement.Level then
			if not Basement.carries(rects, w.x1, w.z1, w.x2, w.z2) then
				table.insert(walls, key)
			end
		end
	end
	for key, item in (plan and plan.items) or {} do
		if type(item) == "table" and item.lv == Basement.Level and item.wall == nil and finite(item.x) and finite(item.z) then
			local x1, z1, x2, z2 = footprint(item)
			if not Basement.covers(rects, x1, z1, x2, z2, 0.05) then
				table.insert(items, key)
			end
		end
	end
	table.sort(walls)
	table.sort(items)
	for _, key in walls do
		table.insert(out, { kind = "walls", key = key })
	end
	for _, key in items do
		table.insert(out, { kind = "items", key = key })
	end
	return out
end

-- Can a wall, floor or roof go on level -1 here? (Plan.validate asks once the object's own checks
-- pass. `bounds` is the land, `ignoreKey` the object itself when it is being changed.)
function Basement.check(plan: any, kind: string, obj: any, ignoreKey: string?, bounds: { number }): (boolean, string?)
	if kind == "roofs" then
		return false, Basement.Why.roof
	elseif kind == "floors" then
		local m = B.Margin
		if
			obj.x1 < bounds[1] + m - EPS
			or obj.z1 < bounds[2] + m - EPS
			or obj.x2 > bounds[3] - m + EPS
			or obj.z2 > bounds[4] - m + EPS
		then
			return false, Basement.Why.edge
		end
		local block = Basement.block({ obj.x1, obj.z1, obj.x2, obj.z2 })
		for _, w in (plan and plan.waters) or {} do
			if type(w) == "table" and overlaps(block, w.x1, w.z1, w.x2, w.z2) then
				return false, Basement.Why.water
			end
		end
		-- moved or made smaller, it still holds up everything on it
		if ignoreKey and plan and plan.floors and plan.floors[ignoreKey] then
			local rects = Basement.rects(plan, ignoreKey, { obj.x1, obj.z1, obj.x2, obj.z2 })
			if #Basement.stranded(plan, rects) > 0 then
				return false, Basement.Why.stranded
			end
		end
		return true
	elseif kind == "walls" then
		if not Basement.carries(Basement.rects(plan), obj.x1, obj.z1, obj.x2, obj.z2) then
			return false, Basement.Why.noFloor
		end
		return true
	end
	return true
end

-- Can a free standing piece stand on level -1 with this footprint? (Plan.validItem asks.)
function Basement.checkItem(plan: any, x1: number, z1: number, x2: number, z2: number): (boolean, string?)
	if not Basement.covers(Basement.rects(plan), x1, z1, x2, z2, 0.05) then
		return false, Basement.Why.noFloor
	end
	return true
end

-- Can this water go where it is, with the plan's basement? (Plan.validate asks once the water's own
-- checks pass: a basement's dig and a water's never share the ground.)
function Basement.clearOfWater(plan: any, w: any): (boolean, string?)
	for _, block in Basement.blocks(plan) do
		if overlaps(block, w.x1, w.z1, w.x2, w.z2) then
			return false, Basement.Why.basement
		end
	end
	return true
end

-- Drawing -----------------------------------------------------------------------------------------------------

-- The concrete lining round basement floor `key`'s open sides: along each edge where the ground runs
-- on, with no other basement floor past it. It stands just outside the floor, from under its slab
-- to a hair under the ground (the ground's own cut edge shows over it, like turf over a dug bank),
-- and 0.04 into the room, so it covers the ground's cut face rather than lying on it. Where two
-- floors of the basement meet, there is none.
function Basement.lining(plan: any, key: string): { Geometry.Prim }
	local out: { Geometry.Prim } = {}
	local f = plan and plan.floors and plan.floors[key]
	if type(f) ~= "table" or f.lv ~= Basement.Level then
		return out
	end
	local others = Basement.rects(plan, key)
	local T = B.Lining
	local inset = 0.04
	local y0, y1 = Basement.Bottom, Basement.Top - 0.06
	local step = P.WallSnap
	-- each side: whether it runs along x, the line it is on, which way is out, and its ends
	local sides = {
		{ alongX = true, at = f.z1, out = -1, from = f.x1, to = f.x2 },
		{ alongX = true, at = f.z2, out = 1, from = f.x1, to = f.x2 },
		{ alongX = false, at = f.x1, out = -1, from = f.z1, to = f.z2 },
		{ alongX = false, at = f.x2, out = 1, from = f.z1, to = f.z2 },
	}
	for _, side in sides do
		local runStart: number? = nil
		local u = side.from
		local function close(upTo: number)
			if runStart and upTo > runStart + EPS then
				local inner, outer = side.at - side.out * inset, side.at + side.out * (T - inset)
				local a, b
				if side.alongX then
					a, b = Vector3.new(runStart, y0, inner), Vector3.new(upTo, y1, outer)
				else
					a, b = Vector3.new(inner, y0, runStart), Vector3.new(outer, y1, upTo)
				end
				table.insert(out, Geometry.span(a, b, Basement.LiningColor, "Concrete"))
			end
			runStart = nil
		end
		while u < side.to - EPS do
			local v = math.min(u + step, side.to)
			local mid = (u + v) / 2
			local px, pz
			if side.alongX then
				px, pz = mid, side.at + side.out * 0.5
			else
				px, pz = side.at + side.out * 0.5, mid
			end
			local open = not Basement.onFloor(others, px, pz)
			if open and not runStart then
				runStart = u
			elseif not open and runStart then
				close(u)
			end
			u = v
		end
		close(side.to)
	end
	return out
end

return Basement
