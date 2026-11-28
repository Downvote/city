--!strict
-- Convex polygons on the plot's ground plane, as { { x, z }, ... } counter-clockwise (a positive
-- area with x across and z down the plot). Shapes uses them to fit roofs that meet together: a roof
-- face is cut where another roof lies over it, or where one in the same plane was there first.
-- No services, so the specs run it.

local Poly = {}

export type Pt = { number } -- x, z
export type Polygon = { Pt }

local EPS = 1e-6

-- The signed area (positive counter-clockwise).
function Poly.area(p: Polygon): number
	local a = 0
	local n = #p
	for i = 1, n do
		local q, r = p[i], p[i % n + 1]
		a += q[1] * r[2] - r[1] * q[2]
	end
	return a / 2
end

-- The same polygon counter-clockwise.
function Poly.ccw(p: Polygon): Polygon
	if Poly.area(p) >= 0 then
		return p
	end
	local out = {}
	for i = #p, 1, -1 do
		table.insert(out, p[i])
	end
	return out
end

-- An axis aligned rectangle.
function Poly.rect(x1: number, z1: number, x2: number, z2: number): Polygon
	return { { x1, z1 }, { x2, z1 }, { x2, z2 }, { x1, z2 } }
end

-- Drops points that repeat the one before or lie on the line through their neighbours.
function Poly.clean(p: Polygon): Polygon
	local pts: Polygon = {}
	for _, q in p do
		local last = pts[#pts]
		if not last or math.abs(last[1] - q[1]) > 1e-5 or math.abs(last[2] - q[2]) > 1e-5 then
			table.insert(pts, q)
		end
	end
	while #pts > 1 and math.abs(pts[1][1] - pts[#pts][1]) <= 1e-5 and math.abs(pts[1][2] - pts[#pts][2]) <= 1e-5 do
		table.remove(pts)
	end
	local changed = true
	while changed and #pts >= 3 do
		changed = false
		local n = #pts
		for i = 1, n do
			local a, b, c = pts[(i - 2) % n + 1], pts[i], pts[i % n + 1]
			local cross = (b[1] - a[1]) * (c[2] - a[2]) - (b[2] - a[2]) * (c[1] - a[1])
			local len = math.max(math.abs(c[1] - a[1]), math.abs(c[2] - a[2]), 1e-9)
			if math.abs(cross) / len < 1e-5 then
				table.remove(pts, i)
				changed = true
				break
			end
		end
	end
	return pts
end

-- What of `p` lies where a * x + b * z + c >= 0.
function Poly.clip(p: Polygon, a: number, b: number, c: number): Polygon
	local out: Polygon = {}
	local n = #p
	for i = 1, n do
		local q, r = p[i], p[i % n + 1]
		local fq = a * q[1] + b * q[2] + c
		local fr = a * r[1] + b * r[2] + c
		if fq >= -EPS then
			table.insert(out, q)
		end
		if (fq > EPS and fr < -EPS) or (fq < -EPS and fr > EPS) then
			local t = fq / (fq - fr)
			table.insert(out, { q[1] + (r[1] - q[1]) * t, q[2] + (r[2] - q[2]) * t })
		end
	end
	return Poly.clean(out)
end

-- The half planes inside a convex counter-clockwise polygon: { a, b, c } for each edge.
local function edges(q: Polygon): { { number } }
	local out = {}
	local n = #q
	for i = 1, n do
		local s, e = q[i], q[i % n + 1]
		-- left of s -> e: (e - s) x (p - s) >= 0
		local a = -(e[2] - s[2])
		local b = e[1] - s[1]
		table.insert(out, { a, b, -(a * s[1] + b * s[2]) })
	end
	return out
end

-- Where two convex polygons overlap.
function Poly.intersect(p: Polygon, q: Polygon): Polygon
	local out = p
	for _, h in edges(Poly.ccw(q)) do
		if #out < 3 then
			return {}
		end
		out = Poly.clip(out, h[1], h[2], h[3])
	end
	return if #out >= 3 then out else {}
end

-- What of `p` lies outside convex `q`, as convex pieces that never overlap.
function Poly.subtract(p: Polygon, q: Polygon, minArea: number?): { Polygon }
	local least = minArea or 1e-4
	local pieces = {}
	local rest = p
	for _, h in edges(Poly.ccw(q)) do
		if #rest < 3 then
			break
		end
		local outside = Poly.clip(rest, -h[1], -h[2], -h[3])
		if #outside >= 3 and math.abs(Poly.area(outside)) > least then
			table.insert(pieces, outside)
		end
		rest = Poly.clip(rest, h[1], h[2], h[3])
	end
	if #rest >= 3 and math.abs(Poly.area(rest)) > least and #Poly.intersect(rest, q) < 3 then
		-- (q was too thin to cut anything off)
		table.insert(pieces, rest)
	end
	return pieces
end

-- What of `p` lies outside every polygon in `cuts`.
function Poly.subtractAll(p: Polygon, cuts: { Polygon }, minArea: number?): { Polygon }
	local pieces = { p }
	for _, q in cuts do
		local next = {}
		for _, piece in pieces do
			for _, left in Poly.subtract(piece, q, minArea) do
				table.insert(next, left)
			end
		end
		pieces = next
		if #pieces == 0 then
			break
		end
	end
	return pieces
end

-- Is the point inside (or on the edge of) a convex counter-clockwise polygon?
function Poly.inside(p: Polygon, x: number, z: number, slack: number?): boolean
	local g = slack or 1e-6
	for _, h in edges(Poly.ccw(p)) do
		local len = math.sqrt(h[1] * h[1] + h[2] * h[2])
		if len > 0 and (h[1] * x + h[2] * z + h[3]) / len < -g then
			return false
		end
	end
	return #p >= 3
end

-- The stretch of a line (x0, z0) + s (dx, dz), from s0 to s1, that lies inside a convex polygon
-- (`margin` in from its edges), as its two ends, or nil when none of it does.
function Poly.segment(
	p: Polygon,
	x0: number,
	z0: number,
	dx: number,
	dz: number,
	s0: number,
	s1: number,
	margin: number?
): (number?, number?)
	if #p < 3 then
		return nil, nil
	end
	local m = margin or 0
	local lo, hi = s0, s1
	for _, h in edges(Poly.ccw(p)) do
		local len = math.sqrt(h[1] * h[1] + h[2] * h[2])
		if len > 0 then
			-- f(s) = f0 + k s >= m, the distance in from this edge
			local f0 = (h[1] * x0 + h[2] * z0 + h[3]) / len - m
			local k = (h[1] * dx + h[2] * dz) / len
			if math.abs(k) < 1e-9 then
				if f0 < -1e-9 then
					return nil, nil
				end
			elseif k > 0 then
				lo = math.max(lo, -f0 / k)
			else
				hi = math.min(hi, -f0 / k)
			end
		end
	end
	if hi <= lo + 1e-6 then
		return nil, nil
	end
	return lo, hi
end

-- Is it an axis aligned rectangle? Returns its x1, z1, x2, z2.
function Poly.box(p: Polygon): (boolean, number, number, number, number)
	if #p ~= 4 then
		return false, 0, 0, 0, 0
	end
	local x1, z1, x2, z2 = math.huge, math.huge, -math.huge, -math.huge
	for _, q in p do
		x1, z1, x2, z2 = math.min(x1, q[1]), math.min(z1, q[2]), math.max(x2, q[1]), math.max(z2, q[2])
	end
	for _, q in p do
		local onX = math.abs(q[1] - x1) < 1e-5 or math.abs(q[1] - x2) < 1e-5
		local onZ = math.abs(q[2] - z1) < 1e-5 or math.abs(q[2] - z2) < 1e-5
		if not (onX and onZ) then
			return false, 0, 0, 0, 0
		end
	end
	return true, x1, z1, x2, z2
end

return Poly
