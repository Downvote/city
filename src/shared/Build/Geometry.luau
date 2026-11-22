--!strict
-- Geometry as plain data. Walls, floors, roofs and furniture are first described as a list of
-- primitives (a box, a wedge, a cylinder...) and only then turned into Parts by Build/Builder.
-- That keeps the shapes testable outside Roblox and lets the preview tool draw them.

export type Light = {
	range: number,
	brightness: number,
	color: Color3,
	kind: string?, -- "point" (default) or "spot"
	face: string?, -- for spot lights: the NormalId name
}

export type Prim = {
	shape: string, -- "Block" | "Wedge" | "CornerWedge" | "Cylinder" | "Ball"
	cf: CFrame,
	size: Vector3,
	color: Color3,
	mat: string,
	transp: number?,
	collide: boolean?,
	name: string?,
	light: Light?,
	effect: string?, -- "fire" | "smoke" | "sparkles"
	role: string?, -- "door" (the swinging leaf), "seat", "bed", "glow" (switched on at night)
	attrs: { [string]: any }?,
}

local Geometry = {}

local EPS = 1e-3

function Geometry.box(cf: CFrame, size: Vector3, color: Color3, mat: string?): Prim
	return { shape = "Block", cf = cf, size = size, color = color, mat = mat or "SmoothPlastic" }
end

-- An axis aligned box spanning two corners.
function Geometry.span(a: Vector3, b: Vector3, color: Color3, mat: string?): Prim
	local lo = a:Min(b)
	local hi = a:Max(b)
	local size = hi - lo
	return Geometry.box(CFrame.new((lo + hi) / 2), size, color, mat)
end

-- A box running from p1 to p2 (its long axis), `width` across horizontally and `height` tall.
function Geometry.beam(p1: Vector3, p2: Vector3, width: number, height: number, color: Color3, mat: string?): Prim?
	local d = p2 - p1
	local len = d.Magnitude
	if len < EPS then
		return nil
	end
	local dir = d / len
	local up = Vector3.yAxis
	if math.abs(dir:Dot(up)) > 0.999 then
		up = Vector3.zAxis
	end
	-- X across, Y up-ish, Z along the beam
	local right = up:Cross(dir).Unit
	local trueUp = dir:Cross(right).Unit
	local cf = CFrame.fromMatrix((p1 + p2) / 2, right, trueUp, -dir)
	return Geometry.box(cf, Vector3.new(width, height, len), color, mat)
end

-- A filled triangle of the given thickness, as two wedges. The classic construction:
-- the longest edge is split at the foot of the altitude into two right triangles.
function Geometry.triangle(a: Vector3, b: Vector3, c: Vector3, thickness: number, color: Color3, mat: string?): { Prim }
	local ab, ac, bc = b - a, c - a, c - b
	local abd, acd, bcd = ab:Dot(ab), ac:Dot(ac), bc:Dot(bc)
	if abd > acd and abd > bcd then
		c, a = a, c
	elseif acd > bcd and acd > abd then
		a, b = b, a
	end
	ab, ac, bc = b - a, c - a, c - b
	local cross = ac:Cross(ab)
	if cross.Magnitude < EPS or bc.Magnitude < EPS then
		return {}
	end
	local right = cross.Unit
	local up = bc:Cross(right).Unit
	local back = bc.Unit
	local height = math.abs(ab:Dot(up))
	if height < EPS then
		return {}
	end
	local out = {}
	local d1 = math.abs(ab:Dot(back))
	local d2 = math.abs(ac:Dot(back))
	if d1 > EPS then
		table.insert(out, {
			shape = "Wedge",
			cf = CFrame.fromMatrix((a + b) / 2, right, up, back),
			size = Vector3.new(thickness, height, d1),
			color = color,
			mat = mat or "SmoothPlastic",
		})
	end
	if d2 > EPS then
		table.insert(out, {
			shape = "Wedge",
			cf = CFrame.fromMatrix((a + c) / 2, -right, up, -back),
			size = Vector3.new(thickness, height, d2),
			color = color,
			mat = mat or "SmoothPlastic",
		})
	end
	return out
end

local function isRectangle(p1: Vector3, p2: Vector3, p3: Vector3, p4: Vector3): boolean
	local e1 = p2 - p1
	local e2 = p4 - p1
	if e1.Magnitude < EPS or e2.Magnitude < EPS then
		return false
	end
	if math.abs(e1.Unit:Dot(e2.Unit)) > 1e-3 then
		return false
	end
	return ((p1 + e1 + e2) - p3).Magnitude < 1e-3
end

-- A flat four sided face (corners in order). A rectangle becomes one box, anything else two triangles.
-- The thickness grows to the side `outward` points to, when given, so a roof's top face lands on the plane.
function Geometry.quad(
	p1: Vector3,
	p2: Vector3,
	p3: Vector3,
	p4: Vector3,
	thickness: number,
	color: Color3,
	mat: string?,
	outward: Vector3?
): { Prim }
	local out = {}
	local shift = Vector3.zero
	if outward then
		local n = (p2 - p1):Cross(p4 - p1)
		if n.Magnitude > EPS then
			n = n.Unit
			if n:Dot(outward) < 0 then
				n = -n
			end
			shift = n * (thickness / 2)
		end
	end
	p1, p2, p3, p4 = p1 + shift, p2 + shift, p3 + shift, p4 + shift
	if isRectangle(p1, p2, p3, p4) then
		local x = (p2 - p1)
		local z = (p4 - p1)
		local xu = x.Unit
		local zu = z.Unit
		local y = zu:Cross(xu).Unit
		local cf = CFrame.fromMatrix((p1 + p3) / 2, xu, y)
		table.insert(out, Geometry.box(cf, Vector3.new(x.Magnitude, thickness, z.Magnitude), color, mat))
		return out
	end
	for _, prim in Geometry.triangle(p1, p2, p3, thickness, color, mat) do
		table.insert(out, prim)
	end
	for _, prim in Geometry.triangle(p1, p3, p4, thickness, color, mat) do
		table.insert(out, prim)
	end
	return out
end

-- A triangle whose thickness grows to one side, like Geometry.quad with `outward`.
function Geometry.tri(
	a: Vector3,
	b: Vector3,
	c: Vector3,
	thickness: number,
	color: Color3,
	mat: string?,
	outward: Vector3?
): { Prim }
	local shift = Vector3.zero
	if outward then
		local n = (b - a):Cross(c - a)
		if n.Magnitude > EPS then
			n = n.Unit
			if n:Dot(outward) < 0 then
				n = -n
			end
			shift = n * (thickness / 2)
		end
	end
	return Geometry.triangle(a + shift, b + shift, c + shift, thickness, color, mat)
end

-- Moves a list of prims by a frame (prims are made in a local space, then placed).
function Geometry.transform(prims: { Prim }, cf: CFrame): { Prim }
	for _, p in prims do
		p.cf = cf * p.cf
	end
	return prims
end

function Geometry.append(into: { Prim }, list: { Prim })
	for _, p in list do
		table.insert(into, p)
	end
end

-- Corners of a prim's box, for bounds checks.
function Geometry.corners(p: Prim): { Vector3 }
	local h = p.size / 2
	local out = {}
	local wedge = p.shape == "Wedge"
	for _, sx in { -1, 1 } do
		for _, sy in { -1, 1 } do
			for _, sz in { -1, 1 } do
				-- a wedge has no top front edge: it is full height only at its back (+Z)
				if not (wedge and sy == 1 and sz == -1) then
					table.insert(out, p.cf * Vector3.new(h.X * sx, h.Y * sy, h.Z * sz))
				end
			end
		end
	end
	return out
end

function Geometry.bounds(prims: { Prim }): (Vector3, Vector3)
	local lo = Vector3.new(math.huge, math.huge, math.huge)
	local hi = -lo
	for _, p in prims do
		for _, c in Geometry.corners(p) do
			lo = lo:Min(c)
			hi = hi:Max(c)
		end
	end
	return lo, hi
end

return Geometry
