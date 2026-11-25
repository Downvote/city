--!strict
-- Stretch: a piece made wider, deeper or taller (the user: "another [gamepass] for x y
-- scaling"). A placed piece keeps how far it is stretched along its own width, height and depth
-- as `sx`, `sy` and `sz` on its plan item (Plan), each from Tuning.Passes.StretchMin to
-- StretchMax and left off at 1. Every part of the piece is scaled from the piece's own pivot (its
-- frame: the middle of its foot), so a stretched table still stands on the floor, and its
-- footprint (Plan.itemRect), its height on a wall, its solid body (Build/Collide) and its
-- drawing (Build/Builder) all follow. Who may stretch is Sim/Passes' to say and the server's to
-- check (Build/Placing); this only knows what a stretch does. Plain data, so the specs run it.
--
-- Some pieces keep their size: a door or a window (its hole in the wall is measured), stairs
-- (their climb is a storey) and a workplace (its villager's loop of spots round it was laid out
-- to the drawing: Sim/Routine). A mark and a ceiling piece stretch across but not up (a mark's
-- layer is its thickness, a ceiling light hangs from its top).

local Tuning = require(script.Parent.Parent.Config.Tuning)
local Geometry = require(script.Parent.Geometry)

type Prim = Geometry.Prim

local Stretch = {}

local K = Tuning.Passes

Stretch.Fields = { "sx", "sy", "sz" }
Stretch.Step = 0.25 -- what Build mode's controls move it by

-- Along which of its sides may this piece be stretched? (width, height, depth)
function Stretch.axes(def: any): (boolean, boolean, boolean)
	if not def or def.place == "opening" or def.place == "stairs" or def.job then
		return false, false, false
	end
	if def.place == "mark" or def.place == "ceiling" then
		return true, false, true
	end
	return true, true, true
end

-- Can this piece be stretched at all?
function Stretch.can(def: any): boolean
	local x, y, z = Stretch.axes(def)
	return x or y or z
end

local function finite(n: any): boolean
	return type(n) == "number" and n == n and n ~= math.huge and n ~= -math.huge
end

-- How far an item is stretched along its width, height and depth (1, 1, 1 when it isn't).
function Stretch.of(item: any): Vector3
	if type(item) ~= "table" then
		return Vector3.one
	end
	local function one(v: any): number
		return if finite(v) and v > 0 then v else 1
	end
	return Vector3.new(one(item.sx), one(item.sy), one(item.sz))
end

-- Is an item stretched at all?
function Stretch.any(item: any): boolean
	local s = Stretch.of(item)
	return math.abs(s.X - 1) > 1e-6 or math.abs(s.Y - 1) > 1e-6 or math.abs(s.Z - 1) > 1e-6
end

-- The box a piece takes up as it stands, stretched (its catalog size times its stretch).
function Stretch.size(def: any, item: any): Vector3
	local size: Vector3 = if def then def.size else Vector3.one
	return size * Stretch.of(item)
end

-- Is the stretch an item carries one a piece of this kind can have? (Plan.validItem)
function Stretch.valid(def: any, item: any): (boolean, string?)
	local allowed = { Stretch.axes(def) }
	for i, field in Stretch.Fields do
		local v = item[field]
		if v ~= nil then
			if not finite(v) then
				return false, "bad number"
			end
			if v < K.StretchMin - 1e-6 or v > K.StretchMax + 1e-6 then
				return false, "stretched too far"
			end
			if not allowed[i] and math.abs(v - 1) > 1e-6 then
				return false, "that keeps its size"
			end
		end
	end
	return true
end

-- One stretch value made safe: within the range, to a hundredth, nil when it is 1 or makes no
-- sense. (Plan.sanitize clamps a loaded item's stretch with it, and Build mode's controls too.)
function Stretch.clampValue(v: any): number?
	if not finite(v) then
		return nil
	end
	local c = math.clamp(v, K.StretchMin, K.StretchMax)
	c = math.floor(c * 100 + 0.5) / 100
	return if math.abs(c - 1) < 1e-6 then nil else c
end

-- A copy of an item with its stretch clamped into the range and left off along the sides its
-- piece keeps (an old or broken save loads as near to what it was as it can).
function Stretch.clamped(def: any, item: any): any
	if type(item) ~= "table" then
		return item
	end
	local out = table.clone(item)
	local allowed = { Stretch.axes(def) }
	for i, field in Stretch.Fields do
		out[field] = if allowed[i] then Stretch.clampValue(item[field]) else nil
	end
	return out
end

-- Scales one frame and size from the origin of the space they are in by `s` along its X, Y
-- and Z: the middle moves out, and each side of the box grows by how much the scale stretches
-- the way it points. A box standing square (or turned in quarter turns) comes out exact; one at
-- another angle stays a box of the same turn, the size it reaches along its own sides.
function Stretch.scaleBox(cf: CFrame, size: Vector3, s: Vector3): (CFrame, Vector3, Vector3)
	local p = cf.Position * s
	local ax = (cf.RightVector * s).Magnitude
	local ay = (cf.UpVector * s).Magnitude
	local az = (cf.LookVector * s).Magnitude
	local local3 = Vector3.new(ax, ay, az)
	return cf - cf.Position + p, size * local3, local3
end

local function r3(n: number): string
	return string.format("%.3f", n)
end

local function scaleOne(prim: Prim, s: Vector3): Prim
	local q = table.clone(prim)
	local cf, size, local3 = Stretch.scaleBox(prim.cf, prim.size, s)
	q.cf, q.size = cf, size
	if prim.shape == "Piece" and prim.parts then
		-- the shapes inside a piece are kept relative to its middle: scale them by the piece's
		-- own stretch along its sides
		local parts = table.create(#prim.parts)
		for i, sub in prim.parts do
			parts[i] = scaleOne(sub, local3)
		end
		q.parts = parts
		-- (a stretched piece isn't the piece the town merges: it gets a key of its own)
		q.key = (prim.key or "") .. "@" .. r3(local3.X) .. "," .. r3(local3.Y) .. "," .. r3(local3.Z)
	end
	return q
end

-- The prims of a piece drawn in its own space (Catalog.prims, its pivot at the origin), each
-- scaled by the stretch `s`. Returns a new list; a stretch of 1 returns the list as it was.
function Stretch.prims(prims: { Prim }, s: Vector3): { Prim }
	if math.abs(s.X - 1) < 1e-6 and math.abs(s.Y - 1) < 1e-6 and math.abs(s.Z - 1) < 1e-6 then
		return prims
	end
	local out = table.create(#prims)
	for i, p in prims do
		out[i] = scaleOne(p, s)
	end
	return out
end

return Stretch
