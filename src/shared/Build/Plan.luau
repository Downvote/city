--!strict
-- A plot's build as plain data, and every rule about changing it.
--
-- A plan holds four kinds of objects, each keyed by a string id:
--   walls  { x1, z1, x2, z2, lv, style, a = Side, b = Side }     (side a faces up x dir: see Plan.wallNormal)
--   floors { x1, z1, x2, z2, lv, c, m }
--   roofs  { x1, z1, x2, z2, lv, style, rise, dir, over, c, m, c2, m2 }
--   items  { id, x, y, z, r, lv, c1?, c2?, wall?, t?, side? }
-- Coordinates are studs in the plot's own frame: x and z run 0..Plot.Size, y is height above the ground.
--
-- Changes are lists of ops ({ op = "add" | "remove" | "set", kind, key, obj, before? }). The server
-- applies them, charges or refunds the cost difference, and keeps the inverse for undo.

local Tuning = require(script.Parent.Parent.Config.Tuning)
local Palette = require(script.Parent.Parent.Data.Palette)
local Colors = require(script.Parent.Parent.Util.Colors)
local Catalog = require(script.Parent.Catalog)

local P = Tuning.Plot

export type Side = { c: string, m: string }
export type Wall = { x1: number, z1: number, x2: number, z2: number, lv: number, style: string, a: Side, b: Side }
export type Floor = { x1: number, z1: number, x2: number, z2: number, lv: number, c: string, m: string }
export type Roof = {
	x1: number,
	z1: number,
	x2: number,
	z2: number,
	lv: number,
	style: string,
	rise: number,
	dir: number,
	over: number,
	c: string,
	m: string,
	c2: string,
	m2: string,
}
export type Item = {
	id: string,
	x: number,
	y: number,
	z: number,
	r: number,
	lv: number,
	c1: string?,
	c2: string?,
	wall: string?,
	t: number?,
	side: string?,
}
export type PlanData = {
	v: number,
	size: number?, -- usable land along each side (see Tuning.City.Land)
	nextId: number,
	walls: { [string]: Wall },
	floors: { [string]: Floor },
	roofs: { [string]: Roof },
	items: { [string]: Item },
}
export type Op = { op: string, kind: string, key: string, obj: any?, before: any? }

local Plan = {}

Plan.Kinds = { "walls", "floors", "roofs", "items" }
Plan.KindSet = { walls = true, floors = true, roofs = true, items = true }

Plan.WallStyles = {
	wall = { name = "Wall", full = true, openings = true, thick = P.WallThickness, fence = false },
	glass = { name = "Glass wall", full = true, thick = 0.4, fence = false },
	half = { name = "Half wall", height = 4, thick = P.WallThickness, fence = false },
	railing = { name = "Railing", height = 3.5, thick = 0.3, fence = true, onFloor = true },
	fence = { name = "Picket fence", height = 4, thick = 0.3, fence = true },
	hedge = { name = "Hedge", height = 5, thick = 2, fence = true },
	stone = { name = "Stone wall", height = 3, thick = 1.4, fence = true },
}
Plan.WallStyleOrder = { "wall", "half", "glass", "railing", "fence", "hedge", "stone" }

Plan.RoofStyles = {
	gable = { name = "Gable" },
	hip = { name = "Hip" },
	pyramid = { name = "Pyramid" },
	shed = { name = "Lean-to" },
	flat = { name = "Flat" },
}
Plan.RoofStyleOrder = { "gable", "hip", "pyramid", "shed", "flat" }

-- Heights ------------------------------------------------------------------------------------

function Plan.levelBase(lv: number): number
	return P.Foundation + lv * P.LevelHeight
end

function Plan.levelTop(lv: number): number
	return Plan.levelBase(lv) + P.LevelHeight
end

-- The bottom and height of a wall of this style on this level.
function Plan.wallSpan(style: string, lv: number): (number, number)
	local def = Plan.WallStyles[style] or Plan.WallStyles.wall
	local bottom = if lv == 0 and not def.onFloor then 0 else Plan.levelBase(lv)
	if def.full then
		return bottom, Plan.levelTop(lv) - bottom
	end
	return bottom, def.height :: number
end

function Plan.wallThickness(style: string): number
	local def = Plan.WallStyles[style] or Plan.WallStyles.wall
	return def.thick
end

-- Wall frames --------------------------------------------------------------------------------

function Plan.wallLength(w: Wall): number
	return math.sqrt((w.x2 - w.x1) ^ 2 + (w.z2 - w.z1) ^ 2)
end

function Plan.wallDir(w: Wall): Vector3
	local d = Vector3.new(w.x2 - w.x1, 0, w.z2 - w.z1)
	if d.Magnitude < 1e-6 then
		return Vector3.xAxis
	end
	return d.Unit
end

-- Side "a" of a wall faces along this normal, side "b" the other way.
function Plan.wallNormal(w: Wall): Vector3
	local d = Plan.wallDir(w)
	return Vector3.new(d.Z, 0, -d.X)
end

-- A frame on the wall: X runs along the wall (as seen from that side), Y up, Z out of that side.
-- Origin at distance t from the wall's start, height y above the wall bottom, in the wall's middle plane.
function Plan.wallFrame(w: Wall, t: number, y: number, side: string?): CFrame
	local d = Plan.wallDir(w)
	local n = Plan.wallNormal(w)
	local bottom = Plan.wallSpan(w.style, w.lv)
	local pos = Vector3.new(w.x1, 0, w.z1) + d * t + Vector3.new(0, bottom + y, 0)
	if side == "b" then
		return CFrame.fromMatrix(pos, -d, Vector3.yAxis, -n)
	end
	return CFrame.fromMatrix(pos, d, Vector3.yAxis, n)
end

-- The frame an item is built in.
function Plan.itemFrame(plan: PlanData, item: Item): CFrame?
	local def = Catalog.get(item.id)
	if not def then
		return nil
	end
	if def.place == "opening" or def.place == "wall" then
		local w = item.wall and plan.walls[item.wall]
		if not w then
			return nil
		end
		local frame = Plan.wallFrame(w, item.t or 0, item.y, item.side)
		if def.place == "wall" then
			frame = frame * CFrame.new(0, 0, Plan.wallThickness(w.style) / 2)
		end
		return frame
	end
	return CFrame.new(item.x, item.y, item.z) * CFrame.Angles(0, math.rad(item.r), 0)
end

-- Footprint helpers ---------------------------------------------------------------------------

-- The axis aligned rectangle an item covers on the ground (rotation included), as x1, z1, x2, z2.
function Plan.itemRect(item: Item): (number, number, number, number)
	local def = Catalog.get(item.id)
	local size = if def then def.size else Vector3.new(1, 1, 1)
	local a = math.rad(item.r)
	local c, s = math.abs(math.cos(a)), math.abs(math.sin(a))
	local hx = (size.X * c + size.Z * s) / 2
	local hz = (size.X * s + size.Z * c) / 2
	return item.x - hx, item.z - hz, item.x + hx, item.z + hz
end

-- Rectangles cut out of the floors of level lv (stairwells coming up from lv - 1).
function Plan.holes(plan: PlanData, lv: number): { { number } }
	local out = {}
	if lv <= 0 then
		return out
	end
	for _, item in plan.items do
		local def = Catalog.get(item.id)
		if def and def.place == "stairs" and item.lv == lv - 1 then
			local x1, z1, x2, z2 = Plan.itemRect(item)
			table.insert(out, { x1, z1, x2, z2 })
		end
	end
	return out
end

-- Items attached to a wall.
function Plan.attached(plan: PlanData, wallKey: string): { string }
	local out = {}
	for key, item in plan.items do
		if item.wall == wallKey then
			table.insert(out, key)
		end
	end
	table.sort(out)
	return out
end

-- Openings in a wall as { t, w, y0, y1 } (y measured from the wall bottom).
function Plan.openings(plan: PlanData, wallKey: string): { { number } }
	local out = {}
	local w = plan.walls[wallKey]
	if not w then
		return out
	end
	for _, item in plan.items do
		if item.wall == wallKey then
			local def = Catalog.get(item.id)
			if def and def.place == "opening" and def.opening then
				-- item.y is measured from the wall bottom
				table.insert(out, { item.t or 0, def.opening.w, item.y, item.y + def.opening.h })
			end
		end
	end
	table.sort(out, function(p, q)
		return p[1] < q[1]
	end)
	return out
end

-- Where a door or window sits by default: its sill above the floor. On the ground floor a wall
-- starts at the ground while the floor is on the foundation, so the foundation is added.
function Plan.openingY(w: Wall, sill: number): number
	local bottom = Plan.wallSpan(w.style, w.lv)
	return sill + (Plan.levelBase(w.lv) - bottom)
end

-- Costs --------------------------------------------------------------------------------------

local function cells(x1: number, z1: number, x2: number, z2: number): number
	local s = P.WallSnap
	return math.max(1, math.floor(((x2 - x1) / s) * ((z2 - z1) / s) + 0.5))
end

function Plan.cost(kind: string, obj: any): number
	if kind == "walls" then
		local def = Plan.WallStyles[obj.style] or Plan.WallStyles.wall
		local per = if def.fence then Tuning.Prices.FencePerStud else Tuning.Prices.WallPerStud
		return math.max(1, math.floor(Plan.wallLength(obj) * per + 0.5))
	elseif kind == "floors" then
		return cells(obj.x1, obj.z1, obj.x2, obj.z2) * Tuning.Prices.FloorPerCell
	elseif kind == "roofs" then
		return cells(obj.x1, obj.z1, obj.x2, obj.z2) * Tuning.Prices.RoofPerCell
	elseif kind == "items" then
		local def = Catalog.get(obj.id)
		return if def then def.price else 0
	end
	return 0
end

-- The coins a change costs (negative when it refunds).
function Plan.changeCost(ops: { Op }): number
	local total = 0
	for _, op in ops do
		if op.op == "add" then
			total += Plan.cost(op.kind, op.obj)
		elseif op.op == "remove" then
			total -= Plan.cost(op.kind, op.obj)
		elseif op.op == "set" then
			total += Plan.cost(op.kind, op.obj) - Plan.cost(op.kind, op.before)
		end
	end
	return total
end

-- Validation ---------------------------------------------------------------------------------

local function finite(n: any): boolean
	return type(n) == "number" and n == n and n ~= math.huge and n ~= -math.huge
end

local function onGrid(n: number): boolean
	local s = P.WallSnap
	return math.abs(n / s - math.floor(n / s + 0.5)) < 1e-6
end

-- The usable land of a plot of this size, as x1, z1, x2, z2: centred left to right, starting at
-- the street.
function Plan.boundsOf(size: number): (number, number, number, number)
	local x1 = (P.Size - size) / 2
	return x1, 0, x1 + size, size
end

function Plan.size(plan: any): number
	return if plan and type(plan.size) == "number" then plan.size else Tuning.City.Land[1].Size
end

function Plan.bounds(plan: any): (number, number, number, number)
	return Plan.boundsOf(Plan.size(plan))
end

export type Bounds = { number }

local function inside(x: number, z: number, b: Bounds): boolean
	return x >= b[1] - 1e-6 and x <= b[3] + 1e-6 and z >= b[2] - 1e-6 and z <= b[4] + 1e-6
end

local function boundsList(plan: any): Bounds
	local x1, z1, x2, z2 = Plan.bounds(plan)
	return { x1, z1, x2, z2 }
end

local function validLevel(lv: any): boolean
	return type(lv) == "number" and lv % 1 == 0 and lv >= 0 and lv < P.Levels
end

local function validSide(s: any): boolean
	return type(s) == "table" and Colors.isHex(s.c) and Palette.MaterialSet[s.m] == true
end

local function validRect(o: any, b: Bounds): (boolean, string?)
	for _, k in { "x1", "z1", "x2", "z2" } do
		if not finite(o[k]) then
			return false, "bad number"
		end
		if not onGrid(o[k]) then
			return false, "off the grid"
		end
	end
	if not inside(o.x1, o.z1, b) or not inside(o.x2, o.z2, b) then
		return false, "outside your land"
	end
	if o.x2 <= o.x1 or o.z2 <= o.z1 then
		return false, "too small"
	end
	if o.x2 - o.x1 > P.MaxFloorSpan or o.z2 - o.z1 > P.MaxFloorSpan then
		return false, "too big"
	end
	if not validLevel(o.lv) then
		return false, "bad level"
	end
	return true
end

function Plan.validWall(w: any, bounds: Bounds?): (boolean, string?)
	if type(w) ~= "table" then
		return false, "not a wall"
	end
	local b = bounds or boundsList(nil)
	for _, k in { "x1", "z1", "x2", "z2" } do
		if not finite(w[k]) then
			return false, "bad number"
		end
		if not onGrid(w[k]) then
			return false, "off the grid"
		end
	end
	if not inside(w.x1, w.z1, b) or not inside(w.x2, w.z2, b) then
		return false, "outside your land"
	end
	local len = Plan.wallLength(w)
	if len < P.MinWallLength - 1e-6 then
		return false, "too short"
	end
	if len > P.MaxWallLength + 1e-6 then
		return false, "too long"
	end
	if not validLevel(w.lv) then
		return false, "bad level"
	end
	if not Plan.WallStyles[w.style] then
		return false, "bad style"
	end
	if not validSide(w.a) or not validSide(w.b) then
		return false, "bad paint"
	end
	return true
end

function Plan.validFloor(f: any, bounds: Bounds?): (boolean, string?)
	if type(f) ~= "table" then
		return false, "not a floor"
	end
	local ok, err = validRect(f, bounds or boundsList(nil))
	if not ok then
		return false, err
	end
	if not validSide({ c = f.c, m = f.m }) then
		return false, "bad paint"
	end
	return true
end

function Plan.validRoof(r: any, bounds: Bounds?): (boolean, string?)
	if type(r) ~= "table" then
		return false, "not a roof"
	end
	local ok, err = validRect(r, bounds or boundsList(nil))
	if not ok then
		return false, err
	end
	if not Plan.RoofStyles[r.style] then
		return false, "bad style"
	end
	if not finite(r.rise) or r.rise < 0 or r.rise > Tuning.Plot.RoofMaxRise then
		return false, "bad height"
	end
	if type(r.dir) ~= "number" or r.dir % 1 ~= 0 or r.dir < 0 or r.dir > 3 then
		return false, "bad direction"
	end
	if not finite(r.over) or r.over < 0 or r.over > Tuning.Plot.RoofMaxOverhang then
		return false, "bad overhang"
	end
	if not validSide({ c = r.c, m = r.m }) or not validSide({ c = r.c2, m = r.m2 }) then
		return false, "bad paint"
	end
	return true
end

-- Checks an item against the plan it would sit in. `ignoreKey` skips the item itself when moving it.
function Plan.validItem(plan: PlanData, item: any, ignoreKey: string?): (boolean, string?)
	if type(item) ~= "table" or type(item.id) ~= "string" then
		return false, "not an item"
	end
	local def = Catalog.get(item.id)
	if not def then
		return false, "unknown item"
	end
	if not validLevel(item.lv) then
		return false, "bad level"
	end
	if item.c1 ~= nil and not Colors.isHex(item.c1) then
		return false, "bad paint"
	end
	if item.c2 ~= nil and not Colors.isHex(item.c2) then
		return false, "bad paint"
	end
	if not finite(item.y) then
		return false, "bad number"
	end
	if def.place == "opening" or def.place == "wall" then
		if type(item.wall) ~= "string" then
			return false, "needs a wall"
		end
		local w = plan.walls[item.wall]
		if not w then
			return false, "that wall is gone"
		end
		if w.style ~= "wall" then
			return false, "only plain walls take this"
		end
		if item.lv ~= w.lv then
			return false, "bad level"
		end
		if item.side ~= "a" and item.side ~= "b" then
			return false, "bad side"
		end
		if not finite(item.t) then
			return false, "bad number"
		end
		local len = Plan.wallLength(w)
		local _, height = Plan.wallSpan(w.style, w.lv)
		if def.place == "opening" then
			local o = def.opening :: any
			local m = Tuning.Plot.OpeningMargin
			local t = item.t :: number
			if t - o.w / 2 < m - 1e-6 or t + o.w / 2 > len - m + 1e-6 then
				return false, "doesn't fit on this wall"
			end
			if item.y < 0 or item.y + o.h > height - 0.4 + 1e-6 then
				return false, "doesn't fit on this wall"
			end
			for key, other in plan.items do
				if key ~= ignoreKey and other.wall == item.wall then
					local odef = Catalog.get(other.id)
					if odef and odef.place == "opening" then
						local oo = odef.opening :: any
						if math.abs((other.t or 0) - t) < (oo.w + o.w) / 2 + m - 1e-6 then
							return false, "too close to another door or window"
						end
					end
				end
			end
		else
			if (item.t :: number) < 0 or (item.t :: number) > len then
				return false, "off the wall"
			end
			if item.y < 0 or item.y + def.size.Y > height + 1e-6 then
				return false, "off the wall"
			end
		end
		return true
	end
	-- free standing items
	if not finite(item.x) or not finite(item.z) or not finite(item.r) then
		return false, "bad number"
	end
	if item.wall ~= nil or item.t ~= nil or item.side ~= nil then
		return false, "not a wall item"
	end
	local b = boundsList(plan)
	if not inside(item.x, item.z, b) then
		return false, "outside your land"
	end
	local x1, z1, x2, z2 = Plan.itemRect(item)
	local slack = 0.05
	if x1 < b[1] - slack or z1 < b[2] - slack or x2 > b[3] + slack or z2 > b[4] + slack then
		return false, "outside your land"
	end
	if def.place == "ground" and item.lv ~= 0 then
		return false, "goes outside on the ground"
	end
	if def.place == "stairs" then
		if item.lv >= P.Levels - 1 then
			return false, "no floor above"
		end
		if item.r % 90 ~= 0 then
			return false, "stairs turn in quarter steps"
		end
		local expected = if item.lv == 0 then P.Foundation else Plan.levelBase(item.lv)
		if math.abs(item.y - expected) > 1e-3 then
			return false, "stairs start on the floor"
		end
		return true
	end
	if def.place == "ceiling" then
		local expected = Plan.levelTop(item.lv) - (if item.lv < P.Levels - 1 then 1 else 0)
		if math.abs(item.y - expected) > 1e-3 then
			return false, "goes on the ceiling"
		end
		return true
	end
	local lo = if item.lv == 0 then 0 else Plan.levelBase(item.lv) - 0.01
	local hi = Plan.levelTop(item.lv) - 0.5
	if item.y < lo or item.y > hi then
		return false, "bad height"
	end
	return true
end

function Plan.validate(plan: PlanData, kind: string, obj: any, ignoreKey: string?): (boolean, string?)
	local b = boundsList(plan)
	if kind == "walls" then
		return Plan.validWall(obj, b)
	elseif kind == "floors" then
		return Plan.validFloor(obj, b)
	elseif kind == "roofs" then
		return Plan.validRoof(obj, b)
	elseif kind == "items" then
		return Plan.validItem(plan, obj, ignoreKey)
	end
	return false, "unknown kind"
end

-- Only the fields each kind of object has, with plain values, so nothing extra a client sends
-- ends up saved.
local FIELDS = {
	walls = { "x1", "z1", "x2", "z2", "lv", "style" },
	floors = { "x1", "z1", "x2", "z2", "lv", "c", "m" },
	roofs = { "x1", "z1", "x2", "z2", "lv", "style", "rise", "dir", "over", "c", "m", "c2", "m2" },
	items = { "id", "x", "y", "z", "r", "lv", "c1", "c2", "wall", "t", "side" },
}

function Plan.clean(kind: string, obj: any): any
	if type(obj) ~= "table" then
		return obj
	end
	local out: { [string]: any } = {}
	for _, k in FIELDS[kind] or {} do
		local v = obj[k]
		if type(v) == "number" or (type(v) == "string" and #v <= 32) then
			out[k] = v
		end
	end
	if kind == "walls" then
		for _, side in { "a", "b" } do
			local sd = obj[side]
			if type(sd) == "table" then
				out[side] = {
					c = if type(sd.c) == "string" then sd.c:sub(1, 6) else nil,
					m = if type(sd.m) == "string" then sd.m:sub(1, 32) else nil,
				}
			end
		end
	end
	return out
end

-- Limits --------------------------------------------------------------------------------------

local LIMITS = {
	walls = P.MaxWalls,
	floors = P.MaxFloors,
	roofs = P.MaxRoofs,
	items = P.MaxItems,
}

function Plan.count(plan: PlanData, kind: string): number
	local n = 0
	for _ in (plan :: any)[kind] do
		n += 1
	end
	return n
end

function Plan.limit(kind: string): number
	return LIMITS[kind] or 0
end

-- Plans and changes ----------------------------------------------------------------------------

function Plan.new(size: number?): PlanData
	return {
		v = 1,
		size = size or Tuning.City.Land[1].Size,
		nextId = 1,
		walls = {},
		floors = {},
		roofs = {},
		items = {},
	}
end

function Plan.newKey(plan: PlanData): string
	local key = tostring(plan.nextId)
	plan.nextId += 1
	return key
end

local function deepCopy(v: any): any
	if type(v) ~= "table" then
		return v
	end
	local out = {}
	for k, x in v do
		out[k] = deepCopy(x)
	end
	return out
end
Plan.copy = deepCopy

-- Applies ops in order. Returns false (and leaves the plan as it was) if any op doesn't fit.
function Plan.apply(plan: PlanData, ops: { Op }): (boolean, string?)
	local done = {}
	local function undoDone()
		for i = #done, 1, -1 do
			local op = done[i]
			local list = (plan :: any)[op.kind]
			if op.op == "add" then
				list[op.key] = nil
			elseif op.op == "remove" then
				list[op.key] = op.obj
			elseif op.op == "set" then
				list[op.key] = op.before
			end
		end
	end
	for _, op in ops do
		if not Plan.KindSet[op.kind] or type(op.key) ~= "string" then
			undoDone()
			return false, "bad op"
		end
		local list = (plan :: any)[op.kind]
		if op.op == "add" then
			if list[op.key] ~= nil then
				undoDone()
				return false, "id in use"
			end
			list[op.key] = deepCopy(op.obj)
		elseif op.op == "remove" then
			if list[op.key] == nil then
				undoDone()
				return false, "already gone"
			end
			list[op.key] = nil
		elseif op.op == "set" then
			if list[op.key] == nil then
				undoDone()
				return false, "already gone"
			end
			list[op.key] = deepCopy(op.obj)
		else
			undoDone()
			return false, "bad op"
		end
		table.insert(done, op)
		local n = tonumber(op.key)
		if n and n >= plan.nextId then
			plan.nextId = n + 1
		end
	end
	return true
end

function Plan.invert(ops: { Op }): { Op }
	local out = {}
	for i = #ops, 1, -1 do
		local op = ops[i]
		if op.op == "add" then
			table.insert(out, { op = "remove", kind = op.kind, key = op.key, obj = op.obj })
		elseif op.op == "remove" then
			table.insert(out, { op = "add", kind = op.kind, key = op.key, obj = op.obj })
		elseif op.op == "set" then
			table.insert(out, { op = "set", kind = op.kind, key = op.key, obj = op.before, before = op.obj })
		end
	end
	return out
end

-- The ops that remove an object, including whatever hangs on it.
function Plan.removeOps(plan: PlanData, kind: string, key: string): { Op }
	local ops = {}
	local obj = (plan :: any)[kind][key]
	if obj == nil then
		return ops
	end
	if kind == "walls" then
		for _, itemKey in Plan.attached(plan, key) do
			table.insert(ops, { op = "remove", kind = "items", key = itemKey, obj = deepCopy(plan.items[itemKey]) })
		end
	end
	table.insert(ops, { op = "remove", kind = kind, key = key, obj = deepCopy(obj) })
	return ops
end

-- What has to be drawn again after these ops: { kind = { key = true } }.
function Plan.affected(plan: PlanData, ops: { Op }): { [string]: { [string]: boolean } }
	local out = { walls = {}, floors = {}, roofs = {}, items = {} }
	local stairLevels = {}
	local function noteItem(obj: any)
		if not obj then
			return
		end
		local def = Catalog.get(obj.id)
		if not def then
			return
		end
		if def.place == "opening" and obj.wall then
			out.walls[obj.wall] = true
		elseif def.place == "stairs" then
			stairLevels[obj.lv + 1] = true
		end
	end
	for _, op in ops do
		out[op.kind][op.key] = true
		if op.kind == "items" then
			noteItem(op.obj)
			noteItem(op.before)
		end
	end
	for lv in stairLevels do
		for key, f in plan.floors do
			if f.lv == lv then
				out.floors[key] = true
			end
		end
	end
	-- items hanging on a wall that was repainted or moved keep their frame, so nothing else to do
	return out
end

-- Makes loaded data safe: drops anything that no longer validates (an item removed from the
-- catalog, a corrupted entry) and fixes nextId.
function Plan.sanitize(raw: any): PlanData
	local plan = Plan.new()
	if type(raw) ~= "table" then
		return plan
	end
	for _, land in Tuning.City.Land do
		if raw.size == land.Size then
			plan.size = land.Size
		end
	end
	local maxId = 0
	local function track(key: string)
		local n = tonumber(key)
		if n and n > maxId then
			maxId = n
		end
	end
	for _, kind in { "walls", "floors", "roofs" } do
		local src = raw[kind]
		if type(src) == "table" then
			for key, obj in src do
				if type(key) == "string" and Plan.validate(plan, kind, obj) then
					(plan :: any)[kind][key] = deepCopy(obj)
					track(key)
				end
			end
		end
	end
	-- items last, since wall items need their walls
	if type(raw.items) == "table" then
		for key, obj in raw.items do
			if type(key) == "string" and Plan.validItem(plan, obj, key) then
				plan.items[key] = deepCopy(obj)
				track(key)
			end
		end
	end
	plan.nextId = math.max(maxId + 1, if type(raw.nextId) == "number" then raw.nextId else 1)
	return plan
end

-- The plan's total build value, for the plot sign and leaderboards.
function Plan.value(plan: PlanData): number
	local total = 0
	for _, kind in Plan.Kinds do
		for _, obj in (plan :: any)[kind] do
			total += Plan.cost(kind, obj)
		end
	end
	return total
end

return Plan
