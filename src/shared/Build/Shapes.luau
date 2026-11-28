--!strict
-- Turns a plan's walls, floors and roofs into primitives (see Build/Geometry), in the plot's frame.

local Tuning = require(script.Parent.Parent.Config.Tuning)
local Colors = require(script.Parent.Parent.Util.Colors)
local Geometry = require(script.Parent.Geometry)
local Plan = require(script.Parent.Plan)
-- (convex polygons on the ground plane: fitting roofs that meet)
local Poly = require(script.Parent.Poly)

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
	else
		Shapes.fence(w.style, out, slab, base, d, n, len, height, thick, e1, e2, ca, ma)
	end
	return out
end

-- The fences that came later (Plan.WallStyles, after the stone wall). `slab` is Shapes.wall's own
-- (a box along the wall); the rest are the wall's frame: `base` its start at the bottom, `d`
-- along it, `n` across it, and its length, height, thickness, end reaches and paint.
local POST_EVERY = 5

-- Where the posts of a run go: both ends and evenly between, about `every` apart.
local function postsAlong(len: number, every: number): { number }
	local count = math.max(1, math.ceil(len / every - 0.01))
	local out = {}
	for i = 0, count do
		table.insert(out, i * len / count)
	end
	return out
end

function Shapes.fence(
	style: string,
	out: { Prim },
	slab: (number, number, number, number, number, number, Color3, string) -> Prim?,
	base: Vector3,
	d: Vector3,
	n: Vector3,
	len: number,
	height: number,
	thick: number,
	e1: number,
	e2: number,
	ca: Color3,
	ma: string
)
	-- a point on the wall: s along it, y up from its bottom, o across it (towards side a)
	local function at(s: number, y: number, o: number): Vector3
		return base + d * s + n * o + Vector3.new(0, y, 0)
	end
	-- an upright cylinder (a post, a cane, a stake) at s, from y0 to y1
	local function post(s: number, y0: number, y1: number, o: number, dia: number, color: Color3, mat: string): Prim
		local prim: Prim = {
			shape = "Cylinder",
			cf = CFrame.fromMatrix(at(s, (y0 + y1) / 2, o), Vector3.yAxis, d),
			size = Vector3.new(y1 - y0, dia, dia),
			color = color,
			mat = mat,
		}
		table.insert(out, prim)
		return prim
	end
	-- a round rail along the wall from s0 to s1 at height y
	local function pole(s0: number, s1: number, y: number, o: number, dia: number, color: Color3, mat: string): Prim
		local prim: Prim = {
			shape = "Cylinder",
			cf = CFrame.fromMatrix(at((s0 + s1) / 2, y, o), d, Vector3.yAxis),
			size = Vector3.new(s1 - s0, dia, dia),
			color = color,
			mat = mat,
		}
		table.insert(out, prim)
		return prim
	end
	local function add(prim: Prim?)
		if prim then
			table.insert(out, prim)
		end
	end

	if style == "brick" then
		-- a low wall of brick under a stone coping, with a pier at each end and every few studs
		local stone = Color3.fromRGB(214, 208, 198)
		slab(-e1, len + e2, 0, height - 0.3, 0, thick, ca, ma)
		slab(-e1 - 0.08, len + e2 + 0.08, height - 0.3, height, 0, thick + 0.16, stone, "Concrete")
		for _, s in postsAlong(len, 7) do
			slab(s - 0.75, s + 0.75, 0, height + 0.2, 0, thick + 0.3, ca, ma)
			slab(s - 0.9, s + 0.9, height + 0.2, height + 0.45, 0, thick + 0.56, stone, "Concrete")
		end
	elseif style == "bamboo" then
		-- canes side by side, a little uneven at the top, a thicker one at each post, lashed to
		-- two rails of split cane on either side
		local tie = Colors.shade(ca, 0.72)
		local count = math.max(2, math.floor(len / 0.46))
		local posts = postsAlong(len, 4)
		for i = 0, count do
			local s = i * len / count
			local near = false
			for _, p in posts do
				if math.abs(p - s) < 0.3 then
					near = true
				end
			end
			if not near then
				local top = height - 0.15 - ((i * 7) % 5) * 0.07
				post(s, 0, top, ((i % 2) * 2 - 1) * 0.04, 0.36, ca, ma)
				-- a joint ring part way up each cane
				post(s, top * 0.55, top * 0.55 + 0.08, ((i % 2) * 2 - 1) * 0.04, 0.42, tie, ma)
			end
		end
		for _, p in posts do
			post(p, 0, height + 0.15, 0, 0.5, Colors.shade(ca, 0.9), ma)
		end
		for _, y in { height * 0.3, height * 0.72 } do
			pole(-e1, len + e2, y, 0.27, 0.16, tie, ma)
			pole(-e1, len + e2, y, -0.27, 0.16, tie, ma)
		end
	elseif style == "iron" then
		-- square posts with a ball on top, two rails and close set bars ending in spear points
		for _, p in postsAlong(len, POST_EVERY) do
			slab(p - 0.18, p + 0.18, 0, height + 0.1, 0, 0.36, ca, ma)
			slab(p - 0.24, p + 0.24, height + 0.1, height + 0.2, 0, 0.48, ca, ma)
			add({
				shape = "Ball",
				cf = CFrame.new(at(p, height + 0.4, 0)),
				size = Vector3.new(0.4, 0.4, 0.4),
				color = ca,
				mat = ma,
			})
		end
		slab(-e1, len + e2, 0.45, 0.65, 0, 0.16, ca, ma)
		slab(-e1, len + e2, height - 0.75, height - 0.55, 0, 0.16, ca, ma)
		local count = math.max(2, math.floor(len / 0.5))
		for i = 1, count - 1 do
			local s = i * len / count
			slab(s - 0.05, s + 0.05, 0.15, height - 0.2, 0, 0.1, ca, ma)
			add({
				shape = "Cone",
				cf = CFrame.new(at(s, height - 0.05, 0)),
				size = Vector3.new(0.2, 0.3, 0.2),
				color = ca,
				mat = ma,
			})
		end
	elseif style == "rail" then
		-- a ranch fence: square posts with a capped top, three wide boards across one face
		for _, p in postsAlong(len, 6) do
			slab(p - 0.25, p + 0.25, 0, height, 0, 0.5, ca, ma)
			slab(p - 0.32, p + 0.32, height, height + 0.12, 0, 0.64, Colors.shade(ca, 0.92), ma)
		end
		for _, y in { 0.75, 1.85, 2.95 } do
			slab(-e1, len + e2, y - 0.25, y + 0.25, 0.32, 0.14, ca, ma)
		end
	elseif style == "log" then
		-- round log posts with two log rails run through them
		for _, p in postsAlong(len, POST_EVERY) do
			post(p, 0, height + 0.2, 0, 0.75, ca, ma)
			post(p, height + 0.2, height + 0.28, 0, 0.55, Colors.shade(ca, 1.15), ma)
		end
		for _, y in { 1.1, 2.6 } do
			pole(-e1, len + e2, y, 0, 0.5, Colors.shade(ca, 0.9), ma)
		end
	elseif style == "balustrade" then
		-- glass panels between slim posts, under a flat handrail, on a low shoe
		for _, p in postsAlong(len, 4) do
			slab(p - 0.13, p + 0.13, 0.25, height - 0.15, 0, 0.26, ca, ma)
		end
		slab(-e1, len + e2, height - 0.15, height, 0, 0.36, ca, ma)
		slab(-e1, len + e2, 0, 0.25, 0, 0.3, Colors.shade(ca, 0.8), ma)
		local pane = slab(0, len, 0.25, height - 0.15, 0, 0.1, Color3.fromRGB(196, 230, 242), "Glass")
		if pane then
			pane.transp = 0.6
		end
	elseif style == "lightrail" then
		-- slim dark posts, a top rail and a low rail, each with a strip of light under it in the
		-- fence's paint (so the paint tool picks the colour of the light)
		local frame = Color3.fromRGB(58, 62, 74)
		for _, p in postsAlong(len, 4) do
			slab(p - 0.15, p + 0.15, 0, height, 0, 0.3, frame, "Metal")
			slab(p - 0.1, p + 0.1, height, height + 0.12, 0, 0.2, ca, "Neon")
		end
		slab(-e1, len + e2, height - 0.3, height - 0.08, 0, 0.36, frame, "Metal")
		slab(-e1, len + e2, height - 0.42, height - 0.3, 0, 0.2, ca, "Neon")
		slab(-e1, len + e2, 0.55, 0.75, 0, 0.3, frame, "Metal")
		slab(-e1, len + e2, 0.43, 0.55, 0, 0.16, ca, "Neon")
		for _, y in { height * 0.42, height * 0.62 } do
			slab(-e1, len + e2, y - 0.04, y + 0.04, 0, 0.1, frame, "Metal")
		end
	elseif style == "rope" then
		-- wooden posts with a cap, and two ropes hanging in a dip from one to the next
		local rope = Color3.fromRGB(212, 190, 146)
		local posts = postsAlong(len, POST_EVERY)
		for _, p in posts do
			post(p, 0, height, 0, 0.5, ca, ma)
			add({
				shape = "Cone",
				cf = CFrame.new(at(p, height + 0.15, 0)),
				size = Vector3.new(0.6, 0.3, 0.6),
				color = Colors.shade(ca, 0.85),
				mat = ma,
			})
		end
		for i = 1, #posts - 1 do
			local s0, s1 = posts[i], posts[i + 1]
			local mid = (s0 + s1) / 2
			for _, y in { height - 0.45, height * 0.45 } do
				local dip = math.min(0.45, (s1 - s0) * 0.08)
				add(Geometry.beam(at(s0, y, 0), at(mid, y - dip, 0), 0.16, 0.16, rope, "Fabric"))
				add(Geometry.beam(at(mid, y - dip, 0), at(s1, y, 0), 0.16, 0.16, rope, "Fabric"))
			end
		end
	elseif style == "willow" then
		-- withies woven in and out of upright stakes: each row passes in front of one stake and
		-- behind the next, the rows two shades of the paint
		local stakes = postsAlong(len, 1.5)
		local row, y = 0, 0.2
		while y + 0.34 <= height - 0.15 do
			local color = if row % 2 == 0 then ca else Colors.shade(ca, 0.86)
			for i = 1, #stakes - 1 do
				local side = if (i + row) % 2 == 0 then 0.09 else -0.09
				slab(stakes[i], stakes[i + 1], y, y + 0.34, side, 0.12, color, ma)
			end
			row += 1
			y += 0.4
		end
		-- (the stakes a little thicker than the weave, so their sides stand clear of it)
		for _, s in stakes do
			post(s, 0, height, 0, 0.38, Colors.shade(ca, 0.7), ma)
		end
	end
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
Shapes.CeilingDrop = 0.05 -- how far under the walls' tops a roof's ceiling lies
Shapes.CeilingThick = 0.2
Shapes.CeilingInset = 0.07
-- A glass roof (a glasshouse's) is see-through by this much, with no board ceiling under it: drawn
-- solid, it read as a flat white sheet (the user: "the roof of this premade building has no texture
-- or color").
Shapes.GlassRoof = 0.45

-- A ground floor in one of these is a path or a yard laid in the ground, not a slab on it (the
-- user's "paths flush with the ground, with an edge": a cobble path used to stand on the lawn as a
-- slab with its side showing). It keeps the ground floor's height, so whatever stands on it stays
-- put, but the grass rises to meet it in a gentle bank all round, and a darker edging course runs
-- round its rim. Soft ground (grass, sand) gets the bank and no edging. Anything else on the ground
-- floor is a room's floor and stays a plain slab.
Shapes.Laid = {
	Cobblestone = true,
	Pavement = true,
	Pebble = true,
	Brick = true,
	Asphalt = true,
	Rock = true,
	Sandstone = true,
	Limestone = true,
	Grass = false,
	Sand = false,
} :: { [string]: boolean }
Shapes.EdgeWidth = 0.5 -- the edging course round a laid floor's rim
Shapes.BankRun = 1.4 -- how far out the grass bank round it reaches
Shapes.Turf = Color3.fromRGB(138, 192, 112) -- the plots' own grass (Services/World)
local KERB = Color3.fromRGB(214, 212, 206)

-- Is this ground floor laid in the ground (true with an edging course, false with none), or a
-- room's slab (nil)?
function Shapes.laid(f: Plan.Floor): boolean?
	if f.lv ~= 0 then
		return nil
	end
	local base = string.match(f.m, "^[^:]+") or f.m
	return Shapes.Laid[base]
end

-- A floor laid in the ground: the edging course along the floor's own sides and the rest inside
-- it, side by side so no two faces lie over each other, both cut by the floor's holes; then the
-- grass bank outside each side, from a little under the ground up to the floor's top. A bank's
-- back is set a little into the floor, and its ends run past the corners so the banks meet.
local function laidFloor(out: { Prim }, f: Plan.Floor, edged: boolean, cuts: { { number } }, color: Color3)
	local top = P.Foundation
	local function cut(rect: { number }): { { number } }
		local rects = { rect }
		for _, h in cuts do
			rects = Shapes.subtract(rects, h)
		end
		return rects
	end
	local x1, z1, x2, z2 = f.x1, f.z1, f.x2, f.z2
	local w = if edged then math.min(Shapes.EdgeWidth, (x2 - x1) / 4, (z2 - z1) / 4) else 0
	for _, r in cut({ x1 + w, z1 + w, x2 - w, z2 - w }) do
		table.insert(out, Geometry.span(Vector3.new(r[1], 0, r[2]), Vector3.new(r[3], top, r[4]), color, f.m))
	end
	if w > 0 then
		local base = string.match(f.m, "^[^:]+") or f.m
		local edgeColor = if base == "Asphalt" then KERB else Colors.shade(color, 0.8)
		local edgeMat = if base == "Asphalt" then "Concrete" else f.m
		for _, e in
			{
				{ x1, z1, x2, z1 + w },
				{ x1, z2 - w, x2, z2 },
				{ x1, z1 + w, x1 + w, z2 - w },
				{ x2 - w, z1 + w, x2, z2 - w },
			}
		do
			for _, r in cut(e) do
				table.insert(
					out,
					Geometry.span(Vector3.new(r[1], 0, r[2]), Vector3.new(r[3], top, r[4]), edgeColor, edgeMat)
				)
			end
		end
	end
	-- the bank: a wedge is full height at its +Z and slopes down to -Z, so each is turned to
	-- face away from the floor. None runs off the plot (onto the sidewalk at the front), so a
	-- side whose bank would is left as it is and the others stop at the edge.
	local run, low, into = Shapes.BankRun, -0.1, 0.08
	local h, size = top - low, P.Size
	local yMid = low + h / 2
	-- (stopped a hair inside the plot's edge, so a bank never ends flush with the floor's own end)
	local ax1, ax2 = math.max(0.05, x1 - run), math.min(size - 0.05, x2 + run)
	local az1, az2 = math.max(0.05, z1 - run), math.min(size - 0.05, z2 + run)
	local function bank(cf: CFrame, length: number)
		local p = Geometry.box(cf, Vector3.new(length, h, run), Shapes.Turf, "Grass")
		p.shape = "Wedge"
		p.name = "Bank"
		table.insert(out, p)
	end
	local back = run / 2 - into -- from the floor's edge to the bank's middle
	if z1 - run >= 0 then
		bank(CFrame.new((ax1 + ax2) / 2, yMid, z1 - back), ax2 - ax1)
	end
	if z2 + run <= size then
		bank(CFrame.new((ax1 + ax2) / 2, yMid, z2 + back) * CFrame.Angles(0, math.pi, 0), ax2 - ax1)
	end
	if x1 - run >= 0 then -- (local +Z turned to +X)
		bank(CFrame.new(x1 - back, yMid, (az1 + az2) / 2) * CFrame.Angles(0, math.pi / 2, 0), az2 - az1)
	end
	if x2 + run <= size then
		bank(CFrame.new(x2 + back, yMid, (az1 + az2) / 2) * CFrame.Angles(0, -math.pi / 2, 0), az2 - az1)
	end
end

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
	local laid = Shapes.laid(f)
	if laid ~= nil then
		laidFloor(out, f, laid, cuts, color)
		return out
	end
	for _, r in rects do
		if f.lv == 0 then
			table.insert(
				out,
				Geometry.span(Vector3.new(r[1], 0, r[2]), Vector3.new(r[3], P.Foundation, r[4]), color, f.m)
			)
		elseif f.lv < 0 then
			-- the basement's: a slab as deep as the ground floor's, on the bottom of the dig
			-- (Build/Basement), with nothing under it to show a ceiling
			local top = Plan.levelBase(f.lv)
			table.insert(
				out,
				Geometry.span(Vector3.new(r[1], top - P.Foundation, r[2]), Vector3.new(r[3], top, r[4]), color, f.m)
			)
		else
			local top = Plan.levelBase(f.lv)
			table.insert(
				out,
				Geometry.span(
					Vector3.new(r[1], top - 1, r[2]),
					Vector3.new(r[3], top - 0.2, r[4]),
					CEILING,
					"WoodPlanks"
				)
			)
			table.insert(
				out,
				Geometry.span(Vector3.new(r[1], top - 0.2, r[2]), Vector3.new(r[3], top, r[4]), color, f.m)
			)
		end
	end
	return out
end

-- Ground floors that meet ---------------------------------------------------------------------------
--
-- Ground floors that touch or overlap are drawn as one (the user: "make it such that paths dont z
-- fight if interesecting each other, and their edges merge together so it outlines their entire
-- combined shape"). Where two overlap, the one laid last lies on top and the other leaves that part
-- out, so no two tops lie in one place. A laid floor's edging course runs only round the outside of
-- all of them together (round a room's floor or a grass path it meets, none), turning in at an
-- inside corner, and its grass bank only along that outside, carried round an outside corner and
-- stopped at an inside one. Each floor draws what lies over its own part, so a change redraws the
-- floors it touches (Plan.affected). A floor touching none is drawn as it always was.

local function laidLater(a: string, b: string): boolean
	local na, nb = tonumber(a), tonumber(b)
	if na and nb and na ~= nb then
		return na > nb
	end
	return a > b
end

-- Do two floors' rectangles touch or overlap?
function Shapes.floorsMeet(a: Plan.Floor, b: Plan.Floor): boolean
	return a.lv == b.lv and a.x1 <= b.x2 + EPS and a.x2 >= b.x1 - EPS and a.z1 <= b.z2 + EPS and a.z2 >= b.z1 - EPS
end

-- Rectangles of one kind merged into as few as will do: `cells[j][i]` is the kind of the cell
-- between xs[i], xs[i + 1] and zs[j], zs[j + 1] (nil for none).
local function mergeCells(xs: { number }, zs: { number }, cells: { { string? } }): { { any } }
	local out: { { any } } = {}
	local open: { [string]: { any } } = {}
	for j = 1, #zs - 1 do
		local runs: { [string]: { any } } = {}
		local i = 1
		while i <= #xs - 1 do
			local kind = cells[j][i]
			local k = i
			while k + 1 <= #xs - 1 and cells[j][k + 1] == kind do
				k += 1
			end
			if kind then
				local id = xs[i] .. "," .. xs[k + 1] .. "," .. kind
				local was = open[id]
				if was then
					was[4] = zs[j + 1]
					runs[id] = was
				else
					local made: { any } = { xs[i], zs[j], xs[k + 1], zs[j + 1], kind }
					table.insert(out, made)
					runs[id] = made
				end
			end
			i = k + 1
		end
		open = runs
	end
	return out
end

-- Ground floor `key` of the plan, drawn with the ground floors it meets. `holes` are cut from it.
function Shapes.groundFloor(plan: Plan.PlanData, key: string, holes: { { number } }?): { Prim }
	local f = plan.floors[key]
	local near: { Plan.Floor } = {}
	local over: { { number } } = {} -- the parts of it laid over later
	for k, g in plan.floors do
		if k ~= key and Shapes.floorsMeet(f, g) then
			table.insert(near, g)
			if
				laidLater(k, key)
				and math.min(f.x2, g.x2) - math.max(f.x1, g.x1) > EPS
				and math.min(f.z2, g.z2) - math.max(f.z1, g.z1) > EPS
			then
				table.insert(over, { g.x1, g.z1, g.x2, g.z2 })
			end
		end
	end
	local laid = Shapes.laid(f)
	if #near == 0 or (laid == nil and #over == 0) then
		return Shapes.floor(f, holes)
	end
	local out: { Prim } = {}
	local top = P.Foundation
	local color = Colors.fromHex(f.c)
	local mine = { { f.x1, f.z1, f.x2, f.z2 } }
	for _, h in over do
		mine = Shapes.subtract(mine, h)
	end
	local cuts: { { number } } = holes or {}
	local function slab(r: { number }, c: Color3, m: string, cutBy: { { number } })
		local rs = { r }
		for _, h in cutBy do
			rs = Shapes.subtract(rs, h)
		end
		for _, q in rs do
			table.insert(out, Geometry.span(Vector3.new(q[1], 0, q[2]), Vector3.new(q[3], top, q[4]), c, m))
		end
	end
	if laid == nil then
		-- a room's floor: its slab, less what is laid over it (its stairwells a hair wider, as alone)
		local wide = {}
		for _, h in cuts do
			table.insert(wide, { h[1] - 0.05, h[2] - 0.05, h[3] + 0.05, h[4] + 0.05 })
		end
		for _, r in mine do
			slab(r, color, f.m, wide)
		end
		return out
	end

	-- all of them together
	local union = { { f.x1, f.z1, f.x2, f.z2 } }
	for _, g in near do
		table.insert(union, { g.x1, g.z1, g.x2, g.z2 })
	end
	local function inside(x: number, z: number): boolean
		for _, u in union do
			if x > u[1] and x < u[3] and z > u[2] and z < u[4] then
				return true
			end
		end
		return false
	end
	local function covered(x1: number, z1: number, x2: number, z2: number): boolean
		local rs = { { x1, z1, x2, z2 } }
		for _, u in union do
			rs = Shapes.subtract(rs, u)
			if #rs == 0 then
				return true
			end
		end
		return false
	end

	-- the top: the edging course within `w` of the outside of them all, the rest inside it
	local x1, z1, x2, z2 = f.x1, f.z1, f.x2, f.z2
	local w = if laid then math.min(Shapes.EdgeWidth, (x2 - x1) / 4, (z2 - z1) / 4) else 0
	local base = string.match(f.m, "^[^:]+") or f.m
	local edgeColor = if base == "Asphalt" then KERB else Colors.shade(color, 0.8)
	local edgeMat = if base == "Asphalt" then "Concrete" else f.m
	for _, r in mine do
		if w <= 0 then
			slab(r, color, f.m, cuts)
			continue
		end
		-- (the lines where the course can change: this part's sides, every edge of them all, and
		-- those moved in and out by the course's width)
		local function breaks(lo: number, hi: number, edges: { number }): { number }
			local list = { lo, hi, lo + w, hi - w }
			for _, e in edges do
				table.insert(list, e - w)
				table.insert(list, e)
				table.insert(list, e + w)
			end
			table.sort(list)
			local cut = {}
			for _, v in list do
				local c = math.clamp(v, lo, hi)
				if #cut == 0 or c > cut[#cut] + 1e-4 then
					table.insert(cut, c)
				end
			end
			return cut
		end
		local ex, ez = {}, {}
		for _, u in union do
			table.insert(ex, u[1])
			table.insert(ex, u[3])
			table.insert(ez, u[2])
			table.insert(ez, u[4])
		end
		local xs = breaks(r[1], r[3], ex)
		local zs = breaks(r[2], r[4], ez)
		local cells: { { string? } } = {}
		for j = 1, #zs - 1 do
			cells[j] = {}
			local cz = (zs[j] + zs[j + 1]) / 2
			for i = 1, #xs - 1 do
				local cx = (xs[i] + xs[i + 1]) / 2
				local g = w - 1e-4
				cells[j][i] = if covered(cx - g, cz - g, cx + g, cz + g) then "inner" else "edge"
			end
		end
		for _, q in mergeCells(xs, zs, cells) do
			if q[5] == "inner" then
				slab({ q[1], q[2], q[3], q[4] }, color, f.m, cuts)
			else
				slab({ q[1], q[2], q[3], q[4] }, edgeColor, edgeMat, cuts)
			end
		end
	end

	-- the bank, along the outside of them all next to this floor's own part
	local run, low, into = Shapes.BankRun, -0.1, 0.08
	local h, size = top - low, P.Size
	local yMid = low + h / 2
	local back = run / 2 - into
	local d = 1e-3
	type Side = { alongX: boolean, at: number, out: number, from: number, to: number }
	local sides: { [string]: { Side } } = {}
	for _, r in mine do
		for _, sd in
			{
				{ alongX = true, at = r[2], out = -1, from = r[1], to = r[3] },
				{ alongX = true, at = r[4], out = 1, from = r[1], to = r[3] },
				{ alongX = false, at = r[1], out = -1, from = r[2], to = r[4] },
				{ alongX = false, at = r[3], out = 1, from = r[2], to = r[4] },
			} :: { Side }
		do
			local stops = { sd.from, sd.to }
			for _, u in union do
				local ends: { number } = if sd.alongX then { u[1], u[3] } else { u[2], u[4] }
				for _, e in ends do
					if e > sd.from and e < sd.to then
						table.insert(stops, e)
					end
				end
			end
			table.sort(stops)
			for i = 1, #stops - 1 do
				local a, b = stops[i], stops[i + 1]
				if b > a + 1e-4 then
					local mid = (a + b) / 2
					local px, pz
					if sd.alongX then
						px, pz = mid, sd.at + sd.out * d
					else
						px, pz = sd.at + sd.out * d, mid
					end
					if not inside(px, pz) then
						local id = tostring(sd.alongX) .. "," .. sd.at .. "," .. sd.out
						sides[id] = sides[id] or {}
						table.insert(sides[id], { alongX = sd.alongX, at = sd.at, out = sd.out, from = a, to = b })
					end
				end
			end
		end
	end
	for _, list in sides do
		table.sort(list, function(p, q)
			return p.from < q.from
		end)
		-- (runs end to end along one line are one bank)
		local merged: { Side } = {}
		for _, sd in list do
			local last = merged[#merged]
			if last and math.abs(last.to - sd.from) < 1e-4 then
				last.to = sd.to
			else
				table.insert(merged, { alongX = sd.alongX, at = sd.at, out = sd.out, from = sd.from, to = sd.to })
			end
		end
		for _, sd in merged do
			if sd.at + sd.out * run < 0 or sd.at + sd.out * run > size then
				continue -- (it would run off the plot: left as it is)
			end
			-- round an outside corner the bank carries on to meet the next; at an inside one, or where
			-- another floor's part carries the edge on, it stops
			local function turns(atEnd: number, past: number): boolean
				local px, pz
				if sd.alongX then
					px, pz = atEnd + past * d, sd.at - sd.out * d
				else
					px, pz = sd.at - sd.out * d, atEnd + past * d
				end
				return not inside(px, pz)
			end
			local a = if turns(sd.from, -1) then sd.from - run else sd.from
			local b = if turns(sd.to, 1) then sd.to + run else sd.to
			a, b = math.max(0.05, a), math.min(size - 0.05, b)
			if b <= a + 1e-3 then
				continue
			end
			local p = Geometry.box(CFrame.new(), Vector3.new(b - a, h, run), Shapes.Turf, "Grass")
			if sd.alongX then
				local z = sd.at + sd.out * back
				p.cf = CFrame.new((a + b) / 2, yMid, z)
					* (if sd.out < 0 then CFrame.identity else CFrame.Angles(0, math.pi, 0))
			else
				local x = sd.at + sd.out * back
				p.cf = CFrame.new(x, yMid, (a + b) / 2)
					* CFrame.Angles(0, if sd.out < 0 then math.pi / 2 else -math.pi / 2, 0)
			end
			p.shape = "Wedge"
			p.name = "Bank"
			table.insert(out, p)
		end
	end
	return out
end

-- Roofs -----------------------------------------------------------------------------------------
--
-- A roof alone is drawn as it always was. Roofs on one floor that meet or overlap are fitted
-- together the way a roofer would build them (the user: "it seems like when roofs are put
-- together, z fighting occurs"): each face of a roof is cut where another roof's face lies over it
-- inside that roof's own walls (a valley where two meet, an eave that runs in under its
-- neighbour), and where two faces lie in one plane (two roofs in a row, their overhangs over the
-- same strip) only the roof that was there first keeps it. A gable or a lean-to's end that
-- another roof closes is left out, one that stands against another roof is set back inside its
-- own roof so it never shares a plane with the other's end, and the ceiling runs on to the joint.
-- Ridge caps in one line, and a flat roof's low walls, are cut the same way. (Roofs.)

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

-- One flat face of a roof, as Shapes.roof would draw it alone (`call` with `pts`), with its plane
-- (the top of its boards: h = A + Bx x + Bz z, and its underside's A) and its outline on the plot.
type Face = {
	call: string, -- "quad" or "tri" (Geometry's), or "slab" (a flat roof's box)
	pts: { Vector3 },
	color: Color3,
	mat: string,
	plan: Poly.Polygon,
	top: Poly.Polygon, -- the outline of its top (its boards grow out from `plan` along their normal)
	sx: number, -- how far the top lies from the underside across the ground
	sz: number,
	A: number,
	Bx: number,
	Bz: number,
	under: number, -- the underside's A
	lo: Vector3?, -- (a flat roof's box)
	hi: Vector3?,
}
-- A vertical end: a gable (or a lean-to's side) across the line u, or a lean-to's high wall.
type End = { kind: string, u: number }
type Drawn = {
	r: Plan.Roof,
	style: string,
	Pt: (number, number, number) -> Vector3,
	U: number,
	V: number,
	y0: number,
	top: number,
	o: number,
	faces: { Face },
	caps: { { Vector3 } },
	parapets: { { Vector3 } },
}

local RT = P.RoofThickness
-- the gable ends: a little thinner than a wall, so where a wall of the storey above runs
-- through one the gable is hidden inside it rather than flickering on its faces
local GABLE = P.WallThickness - 0.06

local function face(call: string, pts: { Vector3 }, color: Color3, mat: string, t: number): Face
	local n = if call == "tri"
		then (pts[2] - pts[1]):Cross(pts[3] - pts[1])
		else (pts[2] - pts[1]):Cross(pts[4] - pts[1])
	if n.Magnitude < 1e-9 then
		n = Vector3.yAxis
	end
	n = n.Unit
	if n.Y < 0 then
		n = -n
	end
	local ny = math.max(n.Y, 1e-3)
	local q = pts[1] + n * t
	local plan: Poly.Polygon = {}
	local topPlan: Poly.Polygon = {}
	for _, p in pts do
		table.insert(plan, { p.X, p.Z })
		table.insert(topPlan, { p.X + n.X * t, p.Z + n.Z * t })
	end
	local bx, bz = -n.X / ny, -n.Z / ny
	return {
		call = call,
		pts = pts,
		color = color,
		mat = mat,
		plan = Poly.ccw(Poly.clean(plan)),
		top = Poly.ccw(Poly.clean(topPlan)),
		sx = n.X * t,
		sz = n.Z * t,
		A = q.Y - bx * q.X - bz * q.Z,
		Bx = bx,
		Bz = bz,
		under = pts[1].Y - bx * pts[1].X - bz * pts[1].Z,
	}
end

-- What a roof is made of, worked out once, before anything is drawn.
local function roofParts(r: Plan.Roof): Drawn
	local color = Colors.fromHex(r.c)
	local t = RT
	local o = r.over
	local y0 = Plan.levelTop(r.lv)
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
	local d: Drawn = {
		r = r,
		style = style,
		Pt = Pt,
		U = U,
		V = V,
		y0 = y0,
		top = top,
		o = o,
		faces = {},
		caps = {},
		parapets = {},
	}
	local function slope(call: string, pts: { Vector3 })
		table.insert(d.faces, face(call, pts, color, r.m, t))
	end
	if style == "flat" then
		local lo, hi = Pt(-o, y0, -o), Pt(U + o, y0 + 0.8, V + o)
		local f = face("slab", {
			Vector3.new(lo.X, y0 + 0.8, lo.Z),
			Vector3.new(hi.X, y0 + 0.8, lo.Z),
			Vector3.new(hi.X, y0 + 0.8, hi.Z),
			Vector3.new(lo.X, y0 + 0.8, hi.Z),
		}, color, r.m, 0)
		f.lo, f.hi = lo, hi
		f.under = y0
		table.insert(d.faces, f)
		local y1, y2 = y0 + 0.8, y0 + 2
		local corners = { Pt(-o, 0, -o), Pt(U + o, 0, -o), Pt(U + o, 0, V + o), Pt(-o, 0, V + o) }
		for i = 1, 4 do
			local a, b = corners[i], corners[i % 4 + 1]
			table.insert(d.parapets, { Vector3.new(a.X, (y1 + y2) / 2, a.Z), Vector3.new(b.X, (y1 + y2) / 2, b.Z) })
		end
	elseif style == "gable" then
		local s = r.rise / (V / 2)
		local ye = y0 - s * o
		slope("quad", { Pt(-o, ye, -o), Pt(U + o, ye, -o), Pt(U + o, top, V / 2), Pt(-o, top, V / 2) })
		slope("quad", { Pt(-o, ye, V + o), Pt(U + o, ye, V + o), Pt(U + o, top, V / 2), Pt(-o, top, V / 2) })
		table.insert(d.caps, { Pt(-o, top, V / 2), Pt(U + o, top, V / 2) })
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
			slope("quad", { e1, e2, r2, r1 })
			slope("quad", { e4, e3, r2, r1 })
			table.insert(d.caps, { r1, r2 })
		else
			slope("tri", { e1, e2, r1 })
			slope("tri", { e4, e3, r1 })
		end
		slope("tri", { e1, e4, r1 })
		slope("tri", { e2, e3, r2 })
	elseif style == "shed" then
		local s = r.rise / V
		local yLow = y0 - s * o
		local yHigh = top + s * o
		slope("quad", { Pt(-o, yLow, -o), Pt(U + o, yLow, -o), Pt(U + o, yHigh, V + o), Pt(-o, yHigh, V + o) })
	end
	return d
end

-- Where the roof's top is over a point, by one of its faces.
local function heightOf(f: Face, x: number, z: number): number
	return f.A + f.Bx * x + f.Bz * z
end
local function undersideOf(f: Face, x: number, z: number): number
	return f.under + f.Bx * x + f.Bz * z
end

-- Which of two roofs was there first (keys are the plan's numbers; it keeps what they share).
local function first(a: string, b: string): boolean
	local na, nb = tonumber(a), tonumber(b)
	if na and nb and na ~= nb then
		return na < nb
	end
	return a < b
end

type Other = { key: string, roof: Plan.Roof, parts: Drawn? }
export type RoofJoin = { key: string, others: { Other } }

local function partsOf(o: Other): Drawn
	local p = o.parts
	if p then
		return p
	end
	local made = roofParts(o.roof)
	o.parts = made
	return made
end

local function footOf(r: Plan.Roof): Poly.Polygon
	return Poly.rect(r.x1, r.z1, r.x2, r.z2)
end

-- What of face `f` of roof `r` (its top's outline, on the ground) the others hide. Over the two
-- roofs' rooms the higher top hides the lower; over the other's room this one keeps only what stands
-- clear over the other's top (an eave or a flat roof's edge running in under it goes); out past both
-- the higher hides the lower. Faces in one plane: the roof that was there first keeps what they share.
local function hiders(f: Face, r: Plan.Roof, join: RoofJoin): { Poly.Polygon }
	local out: { Poly.Polygon } = {}
	local mine = footOf(r)
	local function add(poly: Poly.Polygon, a: number, b: number, c: number)
		if #poly >= 3 then
			local part = Poly.clip(poly, a, b, c)
			if #part >= 3 and math.abs(Poly.area(part)) > 1e-3 then
				table.insert(out, part)
			end
		end
	end
	for _, o in join.others do
		local parts = partsOf(o)
		local foot = footOf(o.roof)
		local before = first(o.key, join.key)
		for _, g in parts.faces do
			local over = Poly.intersect(f.top, g.top)
			if #over >= 3 and math.abs(Poly.area(over)) > 1e-3 then
				local same = true
				for _, p in over do
					if math.abs(heightOf(g, p[1], p[2]) - heightOf(f, p[1], p[2])) > 0.02 then
						same = false
						break
					end
				end
				if same then
					if before then
						table.insert(out, over)
					end
				else
					-- (g's top over f's top: dA + dBx x + dBz z > 0; over f's underside: the same less f's thickness)
					local dx, dz, dTop = g.Bx - f.Bx, g.Bz - f.Bz, g.A - f.A
					local dUnder = g.A - f.under
					local inFoot = Poly.intersect(over, foot)
					add(Poly.intersect(inFoot, mine), dx, dz, dTop)
					for _, piece in Poly.subtract(inFoot, mine) do
						add(piece, dx, dz, dUnder)
					end
					for _, piece in Poly.subtractAll(over, { mine, foot }) do
						add(piece, dx, dz, dTop)
					end
				end
			end
		end
	end
	return out
end

-- Draws a face, or what is left of it.
local function drawFace(out: { Prim }, f: Face, pieces: { Poly.Polygon }?)
	local up = Vector3.yAxis
	if not pieces then
		if f.call == "slab" then
			table.insert(out, Geometry.span(f.lo :: Vector3, f.hi :: Vector3, f.color, f.mat))
		elseif f.call == "quad" then
			Geometry.append(out, Geometry.quad(f.pts[1], f.pts[2], f.pts[3], f.pts[4], RT, f.color, f.mat, up))
		else
			Geometry.append(out, Geometry.tri(f.pts[1], f.pts[2], f.pts[3], RT, f.color, f.mat, up))
		end
		return
	end
	for _, piece in pieces do
		if f.call == "slab" then
			local lo, hi = f.lo :: Vector3, f.hi :: Vector3
			local box, x1, z1, x2, z2 = Poly.box(piece)
			if box then
				table.insert(out, Geometry.span(Vector3.new(x1, lo.Y, z1), Vector3.new(x2, hi.Y, z2), f.color, f.mat))
			else
				for i = 2, #piece - 1 do
					local a, b, c = piece[1], piece[i], piece[i + 1]
					Geometry.append(
						out,
						Geometry.tri(
							Vector3.new(a[1], lo.Y, a[2]),
							Vector3.new(b[1], lo.Y, b[2]),
							Vector3.new(c[1], lo.Y, c[2]),
							hi.Y - lo.Y,
							f.color,
							f.mat,
							up
						)
					)
				end
			end
		else
			local pts = {}
			for _, p in piece do
				table.insert(pts, Vector3.new(p[1], undersideOf(f, p[1], p[2]), p[2]))
			end
			if #pts == 4 then
				Geometry.append(out, Geometry.quad(pts[1], pts[2], pts[3], pts[4], RT, f.color, f.mat, up))
			else
				for i = 2, #pts - 1 do
					Geometry.append(out, Geometry.tri(pts[1], pts[i], pts[i + 1], RT, f.color, f.mat, up))
				end
			end
		end
	end
end

-- Spans of a line (from s0 to s1 along it) less the spans in `cuts`, each { from, to }.
local function spansLeft(s0: number, s1: number, cuts: { { number } }): { { number } }
	local spans = { { s0, s1 } }
	for _, c in cuts do
		local next = {}
		for _, sp in spans do
			if c[2] <= sp[1] + 1e-4 or c[1] >= sp[2] - 1e-4 then
				table.insert(next, sp)
			else
				if c[1] > sp[1] + 0.05 then
					table.insert(next, { sp[1], c[1] })
				end
				if c[2] < sp[2] - 0.05 then
					table.insert(next, { c[2], sp[2] })
				end
			end
		end
		spans = next
	end
	return spans
end

-- A beam along the top of a roof from a to b (a ridge cap, or a flat roof's low wall), as the spans
-- along it, from a, that the others take away: theirs in the same line where they were there first
-- (`lines` finds them, each reaching `ext` past its ends), and what lies under their faces inside
-- their walls (when `buried` gives the beam's height).
local function cutLine(
	a: Vector3,
	b: Vector3,
	join: RoofJoin,
	lines: (Drawn) -> { { Vector3 } },
	ext: number,
	buried: number?
): { { number } }
	local d = b - a
	local len = Vector3.new(d.X, 0, d.Z).Magnitude
	if len < 1e-3 then
		return {}
	end
	local dir = Vector3.new(d.X, 0, d.Z) / len
	local cuts: { { number } } = {}
	for _, o in join.others do
		local parts = partsOf(o)
		if first(o.key, join.key) then
			for _, line in lines(parts) do
				local p, q = line[1], line[2]
				local e = Vector3.new(q.X - p.X, 0, q.Z - p.Z)
				local el = e.Magnitude
				if el > 1e-3 and math.abs(p.Y - a.Y) < 0.02 and math.abs(e.Unit:Dot(dir)) > 0.9999 then
					local rel = Vector3.new(p.X - a.X, 0, p.Z - a.Z)
					local off = rel - dir * rel:Dot(dir)
					if off.Magnitude < 0.02 then
						local s1 = rel:Dot(dir)
						local s2 = Vector3.new(q.X - a.X, 0, q.Z - a.Z):Dot(dir)
						table.insert(cuts, { math.min(s1, s2) - ext, math.max(s1, s2) + ext })
					end
				elseif el > 1e-3 and math.abs(p.Y - a.Y) < 0.02 then
					-- (one across it at its height: the two tops would lie in one plane where they
					-- cross, so this one stops at the sides of that one)
					local eu = e / el
					local cross = dir.X * eu.Z - dir.Z * eu.X
					if math.abs(cross) > 1e-3 then
						local rx, rz = p.X - a.X, p.Z - a.Z
						local s = (rx * eu.Z - rz * eu.X) / cross -- along this one
						local w = (rx * dir.Z - rz * dir.X) / cross -- along that one
						if w > -ext - 0.5 and w < el + ext + 0.5 and s > -0.5 and s < len + 0.5 then
							local half = 0.45 / math.abs(cross) + 0.45 * math.abs(eu:Dot(dir)) / math.abs(cross) + 0.04
							table.insert(cuts, { s - half, s + half })
						end
					end
				end
			end
		end
		if buried then
			local foot = footOf(o.roof)
			for _, g in parts.faces do
				local s0, s1 = Poly.segment(Poly.intersect(g.top, foot), a.X, a.Z, dir.X, dir.Z, -1, len + 1)
				if s0 and s1 then
					-- where g's top is over the line: h(s) = h0 + k s > buried
					local h0 = heightOf(g, a.X, a.Z)
					local k = g.Bx * dir.X + g.Bz * dir.Z
					local lo, hi = s0, s1
					if math.abs(k) < 1e-6 then
						if h0 <= buried then
							lo = hi
						end
					elseif k > 0 then
						lo = math.max(lo, (buried - h0) / k)
					else
						hi = math.min(hi, (buried - h0) / k)
					end
					if hi > lo + 1e-3 then
						-- (a hair more, so its cut end never lies on the cut end of the boards under it)
						table.insert(cuts, { lo - 0.04, hi + 0.04 })
					end
				end
			end
		end
	end
	return cuts
end

-- How an end of roof `d` across the line `u` (its own frame) meets the others: "skip" (another
-- roof closes it), "back" (it stands against another: drawn inside its own roof) or nil.
-- `profile(v)` is the height of its top edge `v` along it, `v0`..`v1` its run.
local function endState(
	d: Drawn,
	join: RoofJoin,
	along: (number) -> Vector3,
	v0: number,
	v1: number,
	profile: (number) -> number
): string?
	local a, b = along(v0), along(v1)
	local state: string? = nil
	for _, o in join.others do
		local q = o.roof
		local lo, hi = a:Min(b), a:Max(b)
		local g = 0.01
		-- (it stands against the other where it meets its walls or runs under its overhang)
		local w = q.over + g
		local touches = lo.X <= q.x2 + w
			and hi.X >= q.x1 - w
			and lo.Z <= q.z2 + w
			and hi.Z >= q.z1 - w
			and math.max(
					math.min(hi.X, q.x2 + q.over) - math.max(lo.X, q.x1 - q.over),
					math.min(hi.Z, q.z2 + q.over) - math.max(lo.Z, q.z1 - q.over)
				)
				> 0.05
		if touches then
			state = "back"
			local inside = lo.X >= q.x1 - g and hi.X <= q.x2 + g and lo.Z >= q.z1 - g and hi.Z <= q.z2 + g
			if inside then
				local parts = partsOf(o)
				local closed = true
				for i = 0, 12 do
					local v = v0 + (v1 - v0) * i / 12
					local p = along(v)
					local best = -math.huge
					for _, f in parts.faces do
						if Poly.inside(f.plan, p.X, p.Z, 1e-3) then
							best = math.max(best, undersideOf(f, p.X, p.Z))
						end
					end
					if best < profile(v) - 0.05 then
						closed = false
						break
					end
				end
				if closed then
					return "skip"
				end
			end
		end
	end
	return state
end

-- A roof drawn on its own, or (`join`) fitted to the roofs it meets.
function Shapes.roof(r: Plan.Roof, join: RoofJoin?): { Prim }
	local out: { Prim } = {}
	local d = roofParts(r)
	local color = Colors.fromHex(r.c)
	local color2 = Colors.fromHex(r.c2)
	local t = RT
	local Pt, U, V, y0, top = d.Pt, d.U, d.V, d.y0, d.top
	local style = d.style
	local joined = join ~= nil and #join.others > 0
	local function add(list: { Prim })
		Geometry.append(out, list)
	end
	local function cap(a: Vector3, b: Vector3, ends: { boolean }?)
		-- a hair past the roof's own ends, so its end faces don't lie on the gable ends' faces
		local along = if (b - a).Magnitude > 1e-3 then (b - a).Unit * 0.04 else Vector3.zero
		local a2 = if not ends or ends[1] then a - along else a
		local b2 = if not ends or ends[2] then b + along else b
		local prim = Geometry.beam(
			a2 + Vector3.new(0, t * 0.9, 0),
			b2 + Vector3.new(0, t * 0.9, 0),
			0.9,
			0.45,
			Colors.shade(color, 0.85),
			r.m
		)
		if prim then
			table.insert(out, prim)
		end
	end
	-- a beam from a to b less what the others take, at its original ends or where it is cut
	local function cutBeam(a: Vector3, b: Vector3, cuts: { { number } }, draw: (Vector3, Vector3, { boolean }) -> ())
		local flat = Vector3.new(b.X - a.X, 0, b.Z - a.Z)
		local len = flat.Magnitude
		if len < 1e-3 then
			return
		end
		local dir = (b - a) / len
		for _, sp in spansLeft(0, len, cuts) do
			draw(a + dir * sp[1], a + dir * sp[2], { sp[1] <= 1e-4, sp[2] >= len - 1e-4 })
		end
	end

	-- under a pitched roof, a flat ceiling of boards across the rooms at the top of the walls (the
	-- user: "make it such that roofs create a flat bottom below it as a ceiling instead of letting
	-- players see the inner pyramid of the roof"). Its top sits a little under the walls' tops so
	-- the two never lie level, and it goes with the roof (hidden with it in Build mode).
	if style ~= "flat" then
		-- (in a hair from the roof's edges, inside the walls standing on them but on no face of theirs)
		local i = Shapes.CeilingInset
		local c1, c2 =
			Pt(i, y0 - Shapes.CeilingDrop - Shapes.CeilingThick, i), Pt(U - i, y0 - Shapes.CeilingDrop, V - i)
		local lo, hi = c1:Min(c2), c1:Max(c2)
		if not joined then
			local ceiling = Geometry.span(lo, hi, CEILING, "WoodPlanks")
			ceiling.name = "Ceiling"
			table.insert(out, ceiling)
		else
			-- (run on to a side another roof meets, and left out under one that was there first; a
			-- glass roof has no ceiling to meet, so this one keeps its edge on that side)
			local x1, z1, x2, z2 = lo.X, lo.Z, hi.X, hi.Z
			local cuts = {}
			for _, other in (join :: RoofJoin).others do
				local q = other.roof
				if q.m == "Glass" then
					continue
				end
				local overX = math.min(r.x2, q.x2) - math.max(r.x1, q.x1)
				local overZ = math.min(r.z2, q.z2) - math.max(r.z1, q.z1)
				if overX > -1e-3 and overZ > 0.05 then
					if q.x1 <= r.x1 + 1e-3 and q.x2 >= r.x1 - 1e-3 then
						x1 = r.x1
					end
					if q.x2 >= r.x2 - 1e-3 and q.x1 <= r.x2 + 1e-3 then
						x2 = r.x2
					end
				end
				if overZ > -1e-3 and overX > 0.05 then
					if q.z1 <= r.z1 + 1e-3 and q.z2 >= r.z1 - 1e-3 then
						z1 = r.z1
					end
					if q.z2 >= r.z2 - 1e-3 and q.z1 <= r.z2 + 1e-3 then
						z2 = r.z2
					end
				end
				local qStyle = if q.rise <= 0.01 then "flat" else q.style
				if qStyle ~= "flat" and first(other.key, (join :: RoofJoin).key) and overX > 1e-3 and overZ > 1e-3 then
					table.insert(cuts, { q.x1, q.z1, q.x2, q.z2 })
				end
			end
			local rects = { { x1, z1, x2, z2 } }
			for _, h in cuts do
				rects = Shapes.subtract(rects, h)
			end
			for _, rc in rects do
				local ceiling = Geometry.span(
					Vector3.new(rc[1], lo.Y, rc[2]),
					Vector3.new(rc[3], hi.Y, rc[4]),
					CEILING,
					"WoodPlanks"
				)
				ceiling.name = "Ceiling"
				table.insert(out, ceiling)
			end
		end
	end

	-- the faces, each less what the others hide
	for _, f in d.faces do
		if joined then
			local hide = hiders(f, r, join :: RoofJoin)
			if #hide > 0 then
				-- (what is hidden of its top, taken off its underside: the boards grow out to the top,
				-- so where two meet in a valley their tops meet on the line and their boards don't cross)
				for i, h in hide do
					local moved = {}
					for _, p in h do
						table.insert(moved, { p[1] - f.sx, p[2] - f.sz })
					end
					hide[i] = moved
				end
				drawFace(out, f, Poly.subtractAll(f.plan, hide, 1e-3))
			else
				drawFace(out, f, nil)
			end
		else
			drawFace(out, f, nil)
		end
	end

	-- the ridge caps
	local function capsOf(p: Drawn)
		return p.caps
	end
	for _, c in d.caps do
		if joined then
			local cuts = cutLine(c[1], c[2], join :: RoofJoin, capsOf, 0.04, c[1].Y + t * 0.9)
			-- (a hair past its ends when they are its own: cut by 0.04 from them)
			local a, b = c[1], c[2]
			local along = if (b - a).Magnitude > 1e-3 then (b - a).Unit * 0.04 else Vector3.zero
			local len = (b - a).Magnitude + 0.08
			if #cuts == 0 then
				cap(a, b)
			else
				for i, cc in cuts do
					cuts[i] = { cc[1] + 0.04, cc[2] + 0.04 }
				end
				local a0 = a - along
				local dir = (b - a).Unit
				for _, sp in spansLeft(0, len, cuts) do
					cap(a0 + dir * sp[1], a0 + dir * sp[2], { false, false })
				end
			end
		else
			cap(c[1], c[2])
		end
	end

	if style == "flat" then
		local function parapetsOf(p: Drawn)
			return p.parapets
		end
		for _, seg in d.parapets do
			local a, b = seg[1], seg[2]
			local function draw(p: Vector3, q: Vector3)
				local prim = Geometry.beam(p, q, 0.5, 1.2, color2, r.m2)
				if prim then
					table.insert(out, prim)
				end
			end
			if joined then
				local cuts = cutLine(a, b, join :: RoofJoin, parapetsOf, 0)
				-- (and where another roof's reach lies just outside it: the roofs join there. Tested
				-- a little out from the wall, so one along the line of a shared edge stays.)
				local flat = Vector3.new(b.X - a.X, 0, b.Z - a.Z)
				local len = flat.Magnitude
				local dir = flat / math.max(len, 1e-6)
				local outward = Vector3.new(-dir.Z, 0, dir.X)
				local mid = Vector3.new((r.x1 + r.x2) / 2, 0, (r.z1 + r.z2) / 2)
				if outward:Dot(Vector3.new(a.X - mid.X, 0, a.Z - mid.Z)) < 0 then
					outward = -outward
				end
				local p0 = a + outward * 0.3
				for _, other in (join :: RoofJoin).others do
					local q = other.roof
					local g = q.over
					local s0, s1 = Poly.segment(
						Poly.rect(q.x1 - g, q.z1 - g, q.x2 + g, q.z2 + g),
						p0.X,
						p0.Z,
						dir.X,
						dir.Z,
						0,
						len
					)
					if s0 and s1 then
						table.insert(cuts, { s0, s1 })
					end
				end
				cutBeam(a, b, cuts, function(p, q)
					draw(p, q)
				end)
			else
				draw(a, b)
			end
		end
	elseif style == "gable" then
		for _, u in { 0, U } do
			local inward = if u == 0 then 1 else -1
			local state = if joined
				then endState(
					d,
					join :: RoofJoin,
					function(v)
						return Pt(u, y0, v)
					end,
					0,
					V,
					function(v)
						return y0 + r.rise * (1 - math.abs(v - V / 2) / (V / 2))
					end
				)
				else nil
			if state ~= "skip" then
				local uc = if state == "back" then u + inward * GABLE / 2 else u
				add(Geometry.triangle(Pt(uc, y0, 0), Pt(uc, y0, V), Pt(uc, top, V / 2), GABLE, color2, r.m2))
			end
		end
	elseif style == "shed" then
		-- The ends stop at the high side's face, which runs on over them to their outer faces:
		-- the same shape, but where the high side leans on a taller wall the ends' feet keep off
		-- the joints of the walls under that wall's foot.
		local g = GABLE / 2
		local ends: { string? } = { nil, nil }
		local wall: string? = nil
		if joined then
			for i, u in { 0, U } do
				ends[i] = endState(
					d,
					join :: RoofJoin,
					function(v)
						return Pt(u, y0, v)
					end,
					0,
					V,
					function(v)
						return y0 + r.rise * v / V
					end
				)
			end
			wall = endState(
				d,
				join :: RoofJoin,
				function(u)
					return Pt(u, y0, V)
				end,
				0,
				U,
				function()
					return top
				end
			)
		end
		local vWall = if wall == "back" then V - g else V
		local vEnd = if wall == "skip" then V elseif wall == "back" then V - 2 * g else V - g
		local topEnd = y0 + r.rise * vEnd / V
		for i, u in { 0, U } do
			if ends[i] ~= "skip" then
				local inward = if u == 0 then 1 else -1
				local uc = if ends[i] == "back" then u + inward * g else u
				add(Geometry.triangle(Pt(uc, y0, 0), Pt(uc, y0, vEnd), Pt(uc, topEnd, vEnd), GABLE, color2, r.m2))
			end
		end
		if wall ~= "skip" then
			local u0 = if ends[1] == nil then -g else 0
			local u1 = if ends[2] == nil then U + g else U
			add(
				Geometry.quad(
					Pt(u0, y0, vWall),
					Pt(u1, y0, vWall),
					Pt(u1, top, vWall),
					Pt(u0, top, vWall),
					GABLE,
					color2,
					r.m2
				)
			)
		end
	end
	if r.m == "Glass" then
		-- a glasshouse's roof: its glass see-through, and no board ceiling hiding the sky
		local kept: { Prim } = {}
		for _, p in out do
			if p.name ~= "Ceiling" then
				if p.mat == "Glass" then
					p.transp = math.max(p.transp or 0, Shapes.GlassRoof)
				end
				table.insert(kept, p)
			end
		end
		out = kept
	end
	return out
end

-- Do two roofs on one floor reach each other (their overhangs included)?
function Shapes.roofsMeet(a: Plan.Roof, b: Plan.Roof): boolean
	if a.lv ~= b.lv then
		return false
	end
	local ga, gb = a.over + 0.05, b.over + 0.05
	return a.x1 - ga <= b.x2 + gb and a.x2 + ga >= b.x1 - gb and a.z1 - ga <= b.z2 + gb and a.z2 + ga >= b.z1 - gb
end

-- Roof `key` of the plan, fitted to the roofs on its floor it meets.
function Shapes.roofIn(plan: Plan.PlanData, key: string): { Prim }?
	local r = plan.roofs[key]
	if not r then
		return nil
	end
	local others: { Other } = {}
	for k, q in plan.roofs do
		if k ~= key and Shapes.roofsMeet(r, q) then
			table.insert(others, { key = k, roof = q })
		end
	end
	if #others == 0 then
		return Shapes.roof(r)
	end
	return Shapes.roof(r, { key = key, others = others })
end

return Shapes
