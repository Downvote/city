--!strict
-- Pieces keep out of each other. The user: "add collisions, and a gamepass should be there to
-- remove it". As in the genre's best known builder, a piece can't go where it would stand in
-- another piece's body or in a wall: the ghost turns red and says what it bumps into, and the
-- server turns it down. Free Placing (Sim/Passes.collides) lets its owner put pieces anywhere.
--
-- What is a piece's body is Build/Solid's to say: the parts people bump into (a sofa's seat,
-- back and arms, a table's top and legs, a tree's trunk), never the little things on it. On top
-- of that, a piece that sits on or in others never gets in the way and nothing gets in its way:
--   * what hangs on a wall or from a ceiling, small things that stand on a surface, marks,
--     rugs and other flat pieces (Solid.none)
--   * doors and windows, which sit in their walls by their own rules (Plan.validItem)
--   * paths, which are walked on and stood on
-- Walls are boxes along their line, as tall and thick as they stand, with their doorways and
-- windows cut out of them, so a piece can stand in a doorway. Floors and roofs are left out:
-- what is put on a floor stands on it.
--
-- Only a change is checked (Build/Placing, Services/Build): a new piece, a piece moved, turned
-- or stretched, and a new wall (against the pieces it would run through). A plan that already
-- has pieces in each other (an old save, a ready-made building's own pieces, which touch) loads
-- and stays as it is. Plain data, so the specs run it.

local Tuning = require(script.Parent.Parent.Config.Tuning)
local Catalog = require(script.Parent.Catalog)
local Geometry = require(script.Parent.Geometry)
local Plan = require(script.Parent.Plan)
local Solid = require(script.Parent.Solid)
local Stretch = require(script.Parent.Stretch)
local Unstick = require(script.Parent.Parent.Sim.Unstick)

local Collide = {}

export type Box = { cf: CFrame, size: Vector3 }

-- Two pieces may overlap by this much at each face and still count as touching: pushed flush
-- against each other on the grid, a counter's top a hair over its box.
Collide.Touch = 0.08

-- Pieces laid in a row that meet at a shared post: fence panels and the garden gate, porch rails
-- and porch posts. Two of these may overlap where they meet (a corner of a fence shares its post).
Collide.Joins =
	{ fence_picket = true, gate_garden = true, porch_rail = true, porch_post = true } :: { [string]: boolean }

-- how many steps a stair's body is cut into (Collide.body), and how far under the line of its
-- treads it reaches, straight down (the strings and the hidden ramp are within it)
Collide.StairSteps = 7
Collide.StairUnder = 1.2

-- Does this piece stay out of the reckoning altogether (it sits on or in others)?
function Collide.passes(def: Catalog.Def): boolean
	if def.place == "opening" or Solid.none(def) then
		return true
	end
	return Catalog.isPath(def)
end

-- A piece's body in its own space (its pivot at the origin), as boxes: the parts of it that
-- are solid, shapes inside its pieces each by itself. Worked out once a piece.
local bodies: { [string]: { Box } } = {}
function Collide.body(def: Catalog.Def): { Box }
	local known = bodies[def.id]
	if known then
		return known
	end
	local out: { Box } = {}
	if def.place == "stairs" then
		-- stairs are their run and their width, rising a storey from their foot (+Z) to their top
		-- end (-Z, Recipes/Structure): a band of steps along the line of the treads, as deep under
		-- it as the strings and the hidden ramp reach (StairUnder). Under the high end there is
		-- room, as there is to see: a cupboard can go there. (Their drawing's ramp is tilted
		-- wedges, whose boxes would reach past both ends.)
		local n = Collide.StairSteps
		local run = def.size.Z / n
		local H = Tuning.Plot.LevelHeight
		for i = 1, n do
			local top = H * i / n
			local bottom = math.max(0, H * (i - 1) / n - Collide.StairUnder)
			table.insert(out, {
				cf = CFrame.new(0, (top + bottom) / 2, def.size.Z / 2 - run * (i - 0.5)),
				size = Vector3.new(def.size.X, top - bottom, run),
			})
		end
	elseif not Collide.passes(def) then
		local prims = Geometry.flatten(Solid.apply(def, Catalog.prims(def)))
		for _, p in prims do
			if p.collide ~= false and p.size.X > 1e-3 and p.size.Y > 1e-3 and p.size.Z > 1e-3 then
				table.insert(out, { cf = p.cf, size = p.size })
			end
		end
	end
	bodies[def.id] = out
	return out
end

-- The world box round a box: its lowest and highest corners.
local function extent(b: Box): (Vector3, Vector3)
	local cf, h = b.cf, b.size / 2
	local r, u, l = cf.RightVector, cf.UpVector, cf.LookVector
	local half = Vector3.new(
		math.abs(r.X) * h.X + math.abs(u.X) * h.Y + math.abs(l.X) * h.Z,
		math.abs(r.Y) * h.X + math.abs(u.Y) * h.Y + math.abs(l.Y) * h.Z,
		math.abs(r.Z) * h.X + math.abs(u.Z) * h.Y + math.abs(l.Z) * h.Z
	)
	return cf.Position - half, cf.Position + half
end

-- A body made ready to test: each box a touch smaller all round, and the box round them all.
export type Shape = { boxes: { Box }, lo: Vector3, hi: Vector3 }

local function shapeOf(boxes: { Box }): Shape
	local t = Collide.Touch
	local lo = Vector3.new(math.huge, math.huge, math.huge)
	local hi = -lo
	local shrunk: { Box } = table.create(#boxes)
	for _, b in boxes do
		local size = Vector3.new(
			math.max(0.01, b.size.X - 2 * t),
			math.max(0.01, b.size.Y - 2 * t),
			math.max(0.01, b.size.Z - 2 * t)
		)
		local box = { cf = b.cf, size = size }
		table.insert(shrunk, box)
		local a, c = extent(box)
		lo, hi = lo:Min(a), hi:Max(c)
	end
	return { boxes = shrunk, lo = lo, hi = hi }
end

local EMPTY: Shape = { boxes = {}, lo = Vector3.zero, hi = Vector3.zero }

local function r3(n: any): string
	return if type(n) == "number" then string.format("%.3f", n) else tostring(n)
end

-- what an item's body comes to, kept by where and how it stands (a plan's items are copied on
-- every change, so they are known by what they are, not which table they are)
local shapes: { [string]: Shape } = {}
local shapeCount = 0

local function itemSignature(item: any): string
	return table.concat({
		tostring(item.id),
		r3(item.x),
		r3(item.y),
		r3(item.z),
		r3(item.r),
		r3(item.sx),
		r3(item.sy),
		r3(item.sz),
	}, "|")
end

-- The body of a free standing item where it stands in the plot, ready to test. Pieces that
-- pass (above), and items on a wall, have none.
function Collide.itemShape(item: any): Shape
	local def: Catalog.Def? = if type(item) == "table" and type(item.id) == "string" then Catalog.get(item.id) else nil
	if not def or Collide.passes(def) or item.wall ~= nil then
		return EMPTY
	end
	if type(item.x) ~= "number" or type(item.y) ~= "number" or type(item.z) ~= "number" then
		return EMPTY
	end
	local sig = itemSignature(item)
	local known = shapes[sig]
	if known then
		return known
	end
	local frame = CFrame.new(item.x, item.y, item.z) * CFrame.Angles(0, math.rad(item.r or 0), 0)
	local s = Stretch.of(item)
	local boxes: { Box } = {}
	for _, b in Collide.body(def) do
		local cf, size = b.cf, b.size
		if Stretch.any(item) then
			cf, size = Stretch.scaleBox(cf, size, s)
		end
		table.insert(boxes, { cf = frame * cf, size = size })
	end
	local shape = if #boxes > 0 then shapeOf(boxes) else EMPTY
	if shapeCount > 6000 then
		shapes, shapeCount = {}, 0
	end
	shapeCount += 1
	shapes[sig] = shape
	return shape
end

-- A wall's boxes: along its line, as tall and thick as it stands, with each door and window
-- cut out (`openings` as Plan.openings gives them: t, width, bottom, top).
function Collide.wallBoxes(w: any, openings: { { number } }?): { Box }
	local out: { Box } = {}
	local len = Plan.wallLength(w)
	if len < 1e-3 then
		return out
	end
	local thick = Plan.wallThickness(w.style)
	local bottom, height = Plan.wallSpan(w.style, w.lv)
	local d = Plan.wallDir(w)
	local start = Vector3.new(w.x1, 0, w.z1)
	local function piece(t1: number, t2: number, y1: number, y2: number)
		t1, t2 = math.max(0, t1), math.min(len, t2)
		y1, y2 = math.max(0, y1), math.min(height, y2)
		if t2 - t1 < 1e-3 or y2 - y1 < 1e-3 then
			return
		end
		local mid = start + d * ((t1 + t2) / 2) + Vector3.new(0, bottom + (y1 + y2) / 2, 0)
		table.insert(out, {
			cf = CFrame.fromMatrix(mid, d, Vector3.yAxis),
			size = Vector3.new(t2 - t1, y2 - y1, thick),
		})
	end
	local at = 0
	local list: { { number } } = openings or {}
	for _, o in list do
		local t, wide, y0, y1 = o[1], o[2], o[3], o[4]
		piece(at, t - wide / 2, 0, height)
		piece(t - wide / 2, t + wide / 2, 0, y0)
		piece(t - wide / 2, t + wide / 2, y1, height)
		at = math.max(at, t + wide / 2)
	end
	piece(at, len, 0, height)
	return out
end

local function wallShape(plan: any, key: string?, w: any): Shape
	local openings = if key and plan.walls[key] then Plan.openings(plan, key) else nil
	local boxes = Collide.wallBoxes(w, openings)
	return if #boxes > 0 then shapeOf(boxes) else EMPTY
end

local function near(a: Shape, b: Shape): boolean
	return #a.boxes > 0
		and #b.boxes > 0
		and a.lo.X < b.hi.X
		and a.hi.X > b.lo.X
		and a.lo.Y < b.hi.Y
		and a.hi.Y > b.lo.Y
		and a.lo.Z < b.hi.Z
		and a.hi.Z > b.lo.Z
end

-- Do two bodies overlap (more than touching)?
function Collide.overlaps(a: Shape, b: Shape): boolean
	if not near(a, b) then
		return false
	end
	for _, p in a.boxes do
		local plo, phi = extent(p)
		for _, q in b.boxes do
			local qlo, qhi = extent(q)
			if
				plo.X < qhi.X
				and phi.X > qlo.X
				and plo.Y < qhi.Y
				and phi.Y > qlo.Y
				and plo.Z < qhi.Z
				and phi.Z > qlo.Z
				and Unstick.overlaps(p, q)
			then
				return true
			end
		end
	end
	return false
end

-- What a thing is called when something bumps into it: "the sofa", "the picket fence", "a wall".
local function lowered(name: string): string
	local second = string.sub(name, 2, 2)
	if second ~= "" and string.upper(second) == second and string.lower(second) ~= second then
		return name -- a name that starts with capitals (TV stand) keeps them
	end
	return string.lower(string.sub(name, 1, 1)) .. string.sub(name, 2)
end

function Collide.nameOf(kind: string, obj: any): string
	if kind == "walls" then
		local style = Plan.WallStyles[obj.style]
		if style and style.fence then
			return "the " .. lowered(style.name)
		end
		return "a wall"
	end
	local def = Catalog.get(obj.id)
	return if def then "the " .. lowered(def.name) else "something"
end

-- What an object put here would bump into: the kind and key of the first thing in the plan it
-- would be in, or nil. `kind` is "items" or "walls" (nothing else is checked). `ignore` holds keys
-- not to look at: the piece itself when it is being moved, and whatever the same change puts
-- down (a ready-made building's pieces may touch each other).
function Collide.hit(plan: any, kind: string, obj: any, ignore: { [string]: boolean }?): (string?, string?)
	local skip = ignore or {}
	if kind == "items" then
		local shape = Collide.itemShape(obj)
		if #shape.boxes == 0 then
			return nil, nil
		end
		local joins = Collide.Joins[obj.id] == true
		for key, other in plan.items do
			if
				not skip[key]
				and not (joins and Collide.Joins[other.id])
				and Collide.overlaps(shape, Collide.itemShape(other))
			then
				return "items", key
			end
		end
		for key, w in plan.walls do
			if not skip[key] then
				-- (a cheap look at the wall's line first: most walls are nowhere near)
				local t = Plan.wallThickness(w.style)
				local bottom, height = Plan.wallSpan(w.style, w.lv)
				if
					math.min(w.x1, w.x2) - t < shape.hi.X
					and math.max(w.x1, w.x2) + t > shape.lo.X
					and math.min(w.z1, w.z2) - t < shape.hi.Z
					and math.max(w.z1, w.z2) + t > shape.lo.Z
					and bottom < shape.hi.Y
					and bottom + height > shape.lo.Y
					and Collide.overlaps(shape, wallShape(plan, key, w))
				then
					return "walls", key
				end
			end
		end
	elseif kind == "walls" then
		local shape = wallShape(plan, nil, obj)
		for key, other in plan.items do
			if not skip[key] and Collide.overlaps(shape, Collide.itemShape(other)) then
				return "items", key
			end
		end
	end
	return nil, nil
end

-- Can an object go here without bumping into anything? ok, or false and what it bumps into, in
-- words for the label by the pointer and the server's answer ("bumps into the sofa").
function Collide.check(plan: any, kind: string, obj: any, ignore: { [string]: boolean }?): (boolean, string?)
	local hitKind, hitKey = Collide.hit(plan, kind, obj, ignore)
	if hitKind and hitKey then
		local other = plan[hitKind][hitKey]
		return false, "bumps into " .. Collide.nameOf(hitKind, other)
	end
	return true
end

-- A whole change put down at once (a ready-made building tried on a copy of the plan): every
-- piece and wall it makes, checked against what `plan` had before it. `made` lists them by kind
-- and key in `trial`, the copy with them in.
function Collide.checkMade(plan: any, trial: any, made: { { kind: string, key: string } }): (boolean, string?)
	-- (only what is near the change is looked at: the plan's pieces and walls within the box
	-- round everything it puts down)
	local lo = Vector3.new(math.huge, math.huge, math.huge)
	local hi = -lo
	local objs = {}
	for _, m in made do
		local obj = if m.kind == "items" or m.kind == "walls" then trial[m.kind][m.key] else nil
		if obj then
			table.insert(objs, { kind = m.kind, obj = obj })
			local shape = if m.kind == "items" then Collide.itemShape(obj) else wallShape(trial, nil, obj)
			if #shape.boxes > 0 then
				lo, hi = lo:Min(shape.lo), hi:Max(shape.hi)
			end
		end
	end
	if lo.X > hi.X then
		return true
	end
	local around = { items = {}, walls = {} }
	for key, it in plan.items do
		local shape = Collide.itemShape(it)
		if #shape.boxes > 0 and near(shape, { boxes = shape.boxes, lo = lo, hi = hi }) then
			around.items[key] = it
		end
	end
	for key, w in plan.walls do
		local t = Plan.wallThickness(w.style) + 1
		if
			math.min(w.x1, w.x2) - t < hi.X
			and math.max(w.x1, w.x2) + t > lo.X
			and math.min(w.z1, w.z2) - t < hi.Z
			and math.max(w.z1, w.z2) + t > lo.Z
		then
			around.walls[key] = w
		end
	end
	-- (and the doors and windows in those walls, which cut their doorways)
	for key, it in plan.items do
		if type(it.wall) == "string" and around.walls[it.wall] then
			around.items[key] = it
		end
	end
	for _, o in objs do
		local hitKind, hitKey = Collide.hit({ items = around.items, walls = around.walls }, o.kind, o.obj)
		if hitKind and hitKey then
			return false, "bumps into " .. Collide.nameOf(hitKind, plan[hitKind][hitKey])
		end
	end
	return true
end

return Collide
