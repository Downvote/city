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

-- How far each end of a wall reaches past its end point. Ends that meet another wall at an angle
-- reach half a thickness so corners close; free ends and straight continuations don't, so nothing
-- overlaps there.
function Shapes.wallReach(plan: Plan.PlanData, key: string): (number, number)
	local w = plan.walls[key]
	local half = Plan.wallThickness(w.style) / 2
	local d = Plan.wallDir(w)
	local function reach(x: number, z: number): number
		for otherKey, o in plan.walls do
			if otherKey ~= key and o.lv == w.lv then
				local touches = sameSpot(o.x1, o.z1, x, z) or sameSpot(o.x2, o.z2, x, z)
				if touches then
					local od = Plan.wallDir(o)
					if math.abs(od:Dot(d)) < 0.999 then
						return half
					end
				end
			end
		end
		return 0
	end
	return reach(w.x1, w.z1), reach(w.x2, w.z2)
end

-- Draws one wall. `openings` are { t, w, y0, y1 } (see Plan.openings); reach1/reach2 from wallReach.
function Shapes.wall(w: Plan.Wall, openings: { { number } }?, reach1: number?, reach2: number?): { Prim }
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
	local e1, e2 = reach1 or 0, reach2 or 0

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

	local function piece(s0: number, s1: number, y0: number, y1: number)
		if same then
			slab(s0, s1, y0, y1, 0, thick, ca, ma)
		else
			slab(s0, s1, y0, y1, thick / 4, thick / 2, ca, ma)
			slab(s0, s1, y0, y1, -thick / 4, thick / 2, cb, mb)
		end
	end

	if w.style == "wall" or w.style == "half" then
		local s = -e1
		for _, o in openings or {} do
			local o0, o1 = o[1] - o[2] / 2, o[1] + o[2] / 2
			piece(s, o0, 0, height)
			piece(o0, o1, 0, o[3])
			piece(o0, o1, o[4], height)
			s = o1
		end
		piece(s, len + e2, 0, height)
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

function Shapes.floor(f: Plan.Floor, holes: { { number } }?): { Prim }
	local out: { Prim } = {}
	local rects = { { f.x1, f.z1, f.x2, f.z2 } }
	for _, h in holes or {} do
		rects = Shapes.subtract(rects, h)
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
	local wt = P.WallThickness
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
		local prim = Geometry.beam(
			a + Vector3.new(0, t * 0.9, 0),
			b + Vector3.new(0, t * 0.9, 0),
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
			add(Geometry.triangle(Pt(u, y0, 0), Pt(u, y0, V), Pt(u, top, V / 2), wt, color2, r.m2))
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
		for _, u in { 0, U } do
			add(Geometry.triangle(Pt(u, y0, 0), Pt(u, y0, V), Pt(u, top, V), wt, color2, r.m2))
		end
		add(Geometry.quad(Pt(0, y0, V), Pt(U, y0, V), Pt(U, top, V), Pt(0, top, V), wt, color2, r.m2))
	end
	return out
end

return Shapes
