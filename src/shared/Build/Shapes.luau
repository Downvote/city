--!strict
-- Turns a plan's walls, floors and roofs into primitives (see Build/Geometry), in the plot's frame.

local Tuning = require(script.Parent.Parent.Config.Tuning)
local Colors = require(script.Parent.Parent.Util.Colors)
local Geometry = require(script.Parent.Geometry)
local Plan = require(script.Parent.Plan)

type Prim = Geometry.Prim

local P = Tuning.Plot
local EPS = 1e-4

local Shapes = {}

-- Walls -----------------------------------------------------------------------------------------

local function sameSpot(ax: number, az: number, bx: number, bz: number): boolean
	return math.abs(ax - bx) < EPS and math.abs(az - bz) < EPS
end

-- How far each end of a wall reaches past its end point (negative: it stops short), so that
-- walls meeting at a point never share any space:
--   a free end, or one wall carrying straight on from another: 0;
--   a stem (a wall ending against a line of walls that runs through, or against the middle of
--   another wall): it stops at that wall's face;
--   a corner of two walls: one of them (the smaller key) is the corner's owner. If the owner is
--   one colour through and through it runs on to the far face and the other wall stops at its
--   face. If it has two different sides, its outside layer runs on to the far face, its inside
--   layer stops at the other wall's near face, and the other wall starts on the owner's middle line.
-- Each end comes back as { a, b }: the reach of the wall's side a layer and its side b layer.
export type Reach = { number }

local function sameSides(w: Plan.Wall): boolean
	return w.a.c == w.b.c and w.a.m == w.b.m
end

local function fenceLike(w: Plan.Wall): boolean
	local style = Plan.WallStyles[w.style]
	return style ~= nil and style.fence == true
end

function Shapes.wallReach(plan: Plan.PlanData, key: string): (Reach, Reach)
	local w = plan.walls[key]
	local d = Plan.wallDir(w)
	local n = Plan.wallNormal(w)
	local function reach(x: number, z: number): Reach
		-- A fence (or a railing, hedge or stone wall) carrying a full wall's line on from a
		-- corner doesn't change how the walls there meet: they close the corner as if it
		-- weren't there, and it starts at the face of the wall across its end. (Otherwise the
		-- corner was left open where the fence's end stood in it.)
		local ends: { [string]: Plan.Wall } = { [key] = w }
		for otherKey, o in plan.walls do
			if otherKey ~= key and o.lv == w.lv and (sameSpot(o.x1, o.z1, x, z) or sameSpot(o.x2, o.z2, x, z)) then
				ends[otherKey] = o
			end
		end
		local function carriesOn(k: string): boolean
			local o = ends[k]
			if not o or not fenceLike(o) then
				return false
			end
			local od = Plan.wallDir(o)
			for qk, q in ends do
				if qk ~= k and not fenceLike(q) and math.abs(Plan.wallDir(q):Dot(od)) >= 0.999 then
					return true
				end
			end
			return false
		end
		if carriesOn(key) then
			local across = 0
			for qk, q in ends do
				if qk ~= key and not fenceLike(q) and math.abs(Plan.wallDir(q):Dot(d)) < 0.999 then
					across = math.max(across, Plan.wallThickness(q.style) / 2)
				end
			end
			if across > 0 then
				return { -across, -across }
			end
		end
		local continues = false -- a wall carries straight on from here
		local lineKey = key -- the smallest key along this wall's own line here
		local angled: { { key: string, wall: Plan.Wall, away: Vector3 } } = {}
		for otherKey, o in plan.walls do
			if
				otherKey ~= key
				and o.lv == w.lv
				and not (ends[otherKey] and not fenceLike(w) and carriesOn(otherKey))
			then
				local at1, at2 = sameSpot(o.x1, o.z1, x, z), sameSpot(o.x2, o.z2, x, z)
				local od = Plan.wallDir(o)
				local straight = math.abs(od:Dot(d)) >= 0.999
				if at1 or at2 then
					if straight then
						continues = true
						if otherKey < lineKey then
							lineKey = otherKey
						end
					else
						table.insert(angled, { key = otherKey, wall = o, away = if at1 then od else -od })
					end
				elseif not straight then
					-- does this end sit on the middle of that wall?
					local len = Plan.wallLength(o)
					local rel = Vector3.new(x - o.x1, 0, z - o.z1)
					local along = rel:Dot(od)
					local off = math.abs(rel:Dot(Plan.wallNormal(o)))
					if along > EPS and along < len - EPS and off < EPS then
						local back = -Plan.wallThickness(o.style) / 2
						return { back, back }
					end
				end
			end
		end
		if #angled == 0 then
			return { 0, 0 }
		end
		-- is one of the others part of a line running through (two of them straight with each other)?
		for i, p in angled do
			for k, q in angled do
				if i ~= k and math.abs(p.away:Dot(q.away)) >= 0.999 then
					-- at a crossing of two lines, the line with the smaller key runs through
					local theirs = if p.key < q.key then p.key else q.key
					if continues and lineKey < theirs then
						return { 0, 0 }
					end
					local back = -Plan.wallThickness(p.wall.style) / 2
					return { back, back }
				end
			end
		end
		if continues then
			return { 0, 0 }
		end
		-- a corner: who owns it? (a full wall before a fence, which draws no corner of its own)
		local owner, ownerWall = key, w
		for _, p in angled do
			local mine, theirs = fenceLike(ownerWall), fenceLike(p.wall)
			if (mine and not theirs) or (mine == theirs and p.key < owner) then
				owner, ownerWall = p.key, p.wall
			end
		end
		if owner ~= key then
			if sameSides(ownerWall) or #angled > 1 then
				local back = -Plan.wallThickness(ownerWall.style) / 2
				return { back, back }
			end
			return { 0, 0 }
		end
		if #angled > 1 then
			return { 0, 0 }
		end
		local other = angled[1]
		local t = Plan.wallThickness(other.wall.style) / 2
		if sameSides(w) or fenceLike(other.wall) then
			-- (a fence draws no corner, so both layers run on to its far face)
			return { t, t }
		end
		-- the layer on the other wall's side is the inside of the corner
		if other.away:Dot(n) > 0 then
			return { -t, t }
		end
		return { t, -t }
	end
	return reach(w.x1, w.z1), reach(w.x2, w.z2)
end

-- How much bigger than a door or window its hole in the wall is cut, all round. Doors and
-- windows line their hole from 0.1 outside its edge (Recipes/Openings), so the cut stays hidden.
local HOLE = 0.04

-- Draws one wall. `openings` are { t, w, y0, y1 } (see Plan.openings); reach1/reach2 from wallReach.
function Shapes.wall(w: Plan.Wall, openings: { { number } }?, reach1: any, reach2: any): { Prim }
	local out: { Prim } = {}
	local style = Plan.WallStyles[w.style] or Plan.WallStyles.wall
	local len = Plan.wallLength(w)
	local d = Plan.wallDir(w)
	local n = Plan.wallNormal(w)
	local bottom, height = Plan.wallSpan(w.style, w.lv)
	local thick = style.thick
	local base = Vector3.new(w.x1, bottom, w.z1)
	local ca, cb = Colors.fromHex(w.a.c), Colors.fromHex(w.b.c)
	local ma, mb = w.a.m, w.b.m
	local same = w.a.c == w.b.c and w.a.m == w.b.m
	-- each end's reach, per layer (a plain number means both layers)
	local r1: Reach = if type(reach1) == "table" then reach1 else { reach1 or 0, reach1 or 0 }
	local r2: Reach = if type(reach2) == "table" then reach2 else { reach2 or 0, reach2 or 0 }
	local e1a, e1b, e2a, e2b = r1[1], r1[2], r2[1], r2[2]
	local e1, e2 = math.max(e1a, e1b), math.max(e2a, e2b)

	-- a slab along the wall from s0 to s1, heights y0..y1 above the bottom, offset across the wall
	local function slab(
		s0: number,
		s1: number,
		y0: number,
		y1: number,
		offset: number,
		t: number,
		color: Color3,
		mat: string
	): Prim?
		if s1 - s0 < 1e-3 or y1 - y0 < 1e-3 then
			return nil
		end
		local center = base + d * ((s0 + s1) / 2) + n * offset + Vector3.new(0, (y0 + y1) / 2, 0)
		local prim =
			Geometry.box(CFrame.fromMatrix(center, d, Vector3.yAxis), Vector3.new(s1 - s0, y1 - y0, t), color, mat)
		table.insert(out, prim)
		return prim
	end

	-- a piece of the wall's run; the first and last pieces take each layer's own reach
	local function piece(s0: number, s1: number, y0: number, y1: number, first: boolean?, last: boolean?)
		if same then
			slab(if first then -e1a else s0, if last then len + e2a else s1, y0, y1, 0, thick, ca, ma)
		else
			slab(if first then -e1a else s0, if last then len + e2a else s1, y0, y1, thick / 4, thick / 2, ca, ma)
			slab(if first then -e1b else s0, if last then len + e2b else s1, y0, y1, -thick / 4, thick / 2, cb, mb)
		end
	end

	if w.style == "wall" or w.style == "half" then
		local s = 0
		local first = true
		local cuts: { { number } } = openings or {}
		for _, o in cuts do
			-- the hole is cut a hair bigger than the door or window, so the wall's cut faces sit
			-- inside its trim and don't flicker against the trim's own faces (and a door's step
			-- under the hole sinks just under the floor beside it)
			local o0, o1 = o[1] - o[2] / 2 - HOLE, o[1] + o[2] / 2 + HOLE
			piece(s, o0, 0, height, first, false)
			piece(o0, o1, 0, o[3] - HOLE)
			piece(o0, o1, o[4] + HOLE, height)
			s = o1
			first = false
		end
		piece(s, len, 0, height, first, true)
		if w.style == "half" then
			-- a cap board on top
			slab(-e1, len + e2, height, height + 0.3, 0, thick + 0.3, Colors.shade(ca, 0.92), ma)
		end
	elseif w.style == "glass" then
		local posts = math.max(1, math.ceil(len / 6))
		local frameColor = ca
		slab(-e1, len + e2, 0, 0.5, 0, thick, frameColor, ma)
		slab(-e1, len + e2, height - 0.5, height, 0, thick, frameColor, ma)
		for i = 0, posts do
			local s = i * len / posts
			slab(s - 0.2, s + 0.2, 0.5, height - 0.5, 0, thick + 0.1, frameColor, ma)
		end
		local pane = slab(0, len, 0.5, height - 0.5, 0, 0.15, Color3.fromRGB(196, 230, 242), "Glass")
		if pane then
			pane.transp = 0.6
		end
	elseif w.style == "fence" then
		local posts = math.max(1, math.ceil(len / 4))
		for i = 0, posts do
			local s = i * len / posts
			slab(s - 0.25, s + 0.25, 0, height + 0.25, 0, 0.5, ca, ma)
		end
		for _, y in { height * 0.3, height * 0.75 } do
			slab(0, len, y - 0.15, y + 0.15, -0.12, 0.15, ca, ma)
		end
		local count = math.floor(len / 1.0)
		for i = 0, count - 1 do
			local s = (i + 0.5) * len / count
			slab(s - 0.2, s + 0.2, 0.2, height - 0.2, 0.06, 0.12, ca, ma)
		end
	elseif w.style == "railing" then
		local posts = math.max(1, math.ceil(len / 4))
		for i = 0, posts do
			local s = i * len / posts
			slab(s - 0.2, s + 0.2, 0, height, 0, 0.4, ca, ma)
		end
		slab(-e1, len + e2, height - 0.25, height, 0, 0.45, ca, ma)
		slab(0, len, 0.3, 0.5, 0, 0.25, ca, ma)
		local count = math.floor(len / 0.8)
		for i = 1, count - 1 do
			local s = i * len / count
			slab(s - 0.07, s + 0.07, 0.5, height - 0.25, 0, 0.14, ca, ma)
		end
	elseif w.style == "hedge" then
		slab(-e1, len + e2, 0, height - 0.6, 0, thick, ca, ma)
		slab(-e1 + 0.2, len + e2 - 0.2, height - 0.6, height, 0, thick - 0.4, Colors.shade(ca, 1.08), ma)
	elseif w.style == "stone" then
		slab(-e1, len + e2, 0, height - 0.3, 0, thick, ca, ma)
		slab(-e1 - 0.1, len + e2 + 0.1, height - 0.3, height, 0, thick + 0.2, Colors.shade(ca, 0.85), "Concrete")
	end
	return out
end

-- Floors ----------------------------------------------------------------------------------------

-- Cuts rectangle h out of each rectangle in rects (all as { x1, z1, x2, z2 }).
function Shapes.subtract(rects: { { number } }, h: { number }): { { number } }
	local out = {}
	for _, r in rects do
		local x1, z1, x2, z2 = r[1], r[2], r[3], r[4]
		local hx1, hz1, hx2, hz2 = math.max(h[1], x1), math.max(h[2], z1), math.min(h[3], x2), math.min(h[4], z2)
		if hx1 >= hx2 - EPS or hz1 >= hz2 - EPS then
			table.insert(out, r)
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
	return out
end

local CEILING = Color3.fromRGB(247, 243, 234)

-- `under` are the walls of the storey below, as { x1, z1, x2, z2 } on the plan: an upper floor
-- stops at them and their own tops carry on level with it, so a floor never lies over the top of a
-- wall and flickers with it (in an upstairs doorway, at the edge of a terrace).
function Shapes.floor(f: Plan.Floor, holes: { { number } }?, under: { { number } }?): { Prim }
	local out: { Prim } = {}
	local rects = { { f.x1, f.z1, f.x2, f.z2 } }
	local cuts: { { number } } = holes or {}
	for _, h in cuts do
		-- a stair's hole is cut a hair wider than the stair, so where it stops at a wall the
		-- floor's cut edge sits inside the wall instead of on its face
		local g = 0.05
		rects = Shapes.subtract(rects, { h[1] - g, h[2] - g, h[3] + g, h[4] + g })
	end
	local walls: { { number } } = under or {}
	if f.lv > 0 then
		for _, w in walls do
			rects = Shapes.subtract(rects, w)
		end
	end
	local color = Colors.fromHex(f.c)
	for _, r in rects do
		if f.lv == 0 then
			table.insert(
				out,
				Geometry.span(Vector3.new(r[1], 0, r[2]), Vector3.new(r[3], P.Foundation, r[4]), color, f.m)
			)
		else
			local top = Plan.levelBase(f.lv)
			table.insert(
				out,
				Geometry.span(Vector3.new(r[1], top - 1, r[2]), Vector3.new(r[3], top - 0.2, r[4]), CEILING, "Plaster")
			)
			table.insert(
				out,
				Geometry.span(Vector3.new(r[1], top - 0.2, r[2]), Vector3.new(r[3], top, r[4]), color, f.m)
			)
		end
	end
	return out
end

-- Roofs -----------------------------------------------------------------------------------------

-- Maps a roof's own (u along the ridge, v across) frame onto the plot for each direction.
local function mapper(r: Plan.Roof, dir: number): ((number, number, number) -> Vector3, number, number)
	local xs, zs = r.x2 - r.x1, r.z2 - r.z1
	if dir == 0 then
		return function(u, y, v)
			return Vector3.new(r.x1 + u, y, r.z1 + v)
		end, xs, zs
	elseif dir == 2 then
		return function(u, y, v)
			return Vector3.new(r.x2 - u, y, r.z2 - v)
		end, xs, zs
	elseif dir == 1 then
		return function(u, y, v)
			return Vector3.new(r.x1 + v, y, r.z1 + u)
		end, zs, xs
	else
		return function(u, y, v)
			return Vector3.new(r.x2 - v, y, r.z2 - u)
		end, zs, xs
	end
end

function Shapes.roof(r: Plan.Roof): { Prim }
	local out: { Prim } = {}
	local color = Colors.fromHex(r.c)
	local color2 = Colors.fromHex(r.c2)
	local t = P.RoofThickness
	-- the gable ends: a little thinner than a wall, so where a wall of the storey above runs
	-- through one the gable is hidden inside it rather than flickering on its faces
	local GABLE = P.WallThickness - 0.06
	local o = r.over
	local y0 = Plan.levelTop(r.lv)
	local up = Vector3.yAxis
	local style = r.style
	if r.rise <= 0.01 then
		style = "flat"
	end
	local dir = r.dir
	local Pt, U, V = mapper(r, dir)
	if style == "hip" and U < V then
		dir = (dir + 1) % 4
		Pt, U, V = mapper(r, dir)
	end
	local top = y0 + r.rise

	local function add(list: { Prim })
		Geometry.append(out, list)
	end
	local function cap(a: Vector3, b: Vector3)
		-- a hair past the roof's own ends, so its end faces don't lie on the gable ends' faces
		local along = if (b - a).Magnitude > 1e-3 then (b - a).Unit * 0.04 else Vector3.zero
		local prim = Geometry.beam(
			a - along + Vector3.new(0, t * 0.9, 0),
			b + along + Vector3.new(0, t * 0.9, 0),
			0.9,
			0.45,
			Colors.shade(color, 0.85),
			r.m
		)
		if prim then
			table.insert(out, prim)
		end
	end

	if style == "flat" then
		local lo = Pt(-o, y0, -o)
		local hi = Pt(U + o, y0 + 0.8, V + o)
		table.insert(out, Geometry.span(lo, hi, color, r.m))
		local y1, y2 = y0 + 0.8, y0 + 2
		local corners = { Pt(-o, 0, -o), Pt(U + o, 0, -o), Pt(U + o, 0, V + o), Pt(-o, 0, V + o) }
		for i = 1, 4 do
			local a, b = corners[i], corners[i % 4 + 1]
			local prim = Geometry.beam(
				Vector3.new(a.X, (y1 + y2) / 2, a.Z),
				Vector3.new(b.X, (y1 + y2) / 2, b.Z),
				0.5,
				y2 - y1,
				color2,
				r.m2
			)
			if prim then
				table.insert(out, prim)
			end
		end
	elseif style == "gable" then
		local s = r.rise / (V / 2)
		local ye = y0 - s * o
		add(
			Geometry.quad(
				Pt(-o, ye, -o),
				Pt(U + o, ye, -o),
				Pt(U + o, top, V / 2),
				Pt(-o, top, V / 2),
				t,
				color,
				r.m,
				up
			)
		)
		add(
			Geometry.quad(
				Pt(-o, ye, V + o),
				Pt(U + o, ye, V + o),
				Pt(U + o, top, V / 2),
				Pt(-o, top, V / 2),
				t,
				color,
				r.m,
				up
			)
		)
		cap(Pt(-o, top, V / 2), Pt(U + o, top, V / 2))
		for _, u in { 0, U } do
			add(Geometry.triangle(Pt(u, y0, 0), Pt(u, y0, V), Pt(u, top, V / 2), GABLE, color2, r.m2))
		end
	elseif style == "hip" or style == "pyramid" then
		local half = if style == "hip" then V / 2 else math.min(U, V) / 2
		local s = r.rise / half
		local ye = y0 - s * o
		local e1, e2, e3, e4 = Pt(-o, ye, -o), Pt(U + o, ye, -o), Pt(U + o, ye, V + o), Pt(-o, ye, V + o)
		local r1, r2
		if style == "hip" then
			r1, r2 = Pt(V / 2, top, V / 2), Pt(U - V / 2, top, V / 2)
		else
			r1 = Pt(U / 2, top, V / 2)
			r2 = r1
		end
		if (r2 - r1).Magnitude > 0.01 then
			add(Geometry.quad(e1, e2, r2, r1, t, color, r.m, up))
			add(Geometry.quad(e4, e3, r2, r1, t, color, r.m, up))
			cap(r1, r2)
		else
			add(Geometry.tri(e1, e2, r1, t, color, r.m, up))
			add(Geometry.tri(e4, e3, r1, t, color, r.m, up))
		end
		add(Geometry.tri(e1, e4, r1, t, color, r.m, up))
		add(Geometry.tri(e2, e3, r2, t, color, r.m, up))
	elseif style == "shed" then
		local s = r.rise / V
		local yLow = y0 - s * o
		local yHigh = top + s * o
		add(
			Geometry.quad(
				Pt(-o, yLow, -o),
				Pt(U + o, yLow, -o),
				Pt(U + o, yHigh, V + o),
				Pt(-o, yHigh, V + o),
				t,
				color,
				r.m,
				up
			)
		)
		-- The ends stop at the high side's face, which runs on over them to their outer faces:
		-- the same shape, but where the high side leans on a taller wall the ends' feet keep off
		-- the joints of the walls under that wall's foot.
		local g = GABLE / 2
		local vEnd = V - g
		local topEnd = y0 + r.rise * vEnd / V
		for _, u in { 0, U } do
			add(Geometry.triangle(Pt(u, y0, 0), Pt(u, y0, vEnd), Pt(u, topEnd, vEnd), GABLE, color2, r.m2))
		end
		add(Geometry.quad(Pt(-g, y0, V), Pt(U + g, y0, V), Pt(U + g, top, V), Pt(-g, top, V), GABLE, color2, r.m2))
	end
	return out
end

return Shapes
