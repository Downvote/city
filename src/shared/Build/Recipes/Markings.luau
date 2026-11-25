--!strict
-- Markings: flat paint for floors, paths and the ground (the user: "add another section where
-- players can put down markings, like in bloxburg"). Lines, arrows, road marks, parking bays,
-- shapes, courts and games, chalk drawings, prints, and block letters and numbers to spell
-- things out with.
--
-- A mark is paint and nothing else: one layer H thick lying on whatever it is put down on (place
-- "mark", which never stands in anyone's way). Each is drawn the way real paint is laid: a dashed
-- line is separate dashes, an arrow a shaft and a head that meet, a crossing bars with gaps, a
-- letter clean block strokes. The shapes of one mark lie side by side and never on top of each
-- other, so two paints never share a face (shapes of the same paint may overlap: the same paint
-- can't be seen to flicker). They are gathered into pieces (Geometry.piece), so a court of eighty
-- lines is a handful of meshes in the game; round dots stay parts of their own.
--
-- In a mark's own space the side a person reads it from is +Z (its front): ahead of them is -Z
-- and their right hand +X. So an arrow points to -Z and a letter's top is toward -Z.
-- c1 is the paint (white or a soft yellow), c2 the second paint of a two colour mark.

local Recipe = require(script.Parent.Parent.Recipe)
local Geometry = require(script.Parent.Parent.Geometry)

type R = Recipe.Recipe
type Prim = Recipe.Prim

local H = 0.05 -- how thick the paint is
local MAT = "SmoothPlastic"

local WHITE = "F5F3EE"
local YELLOW = "F0CC6E"
local PINK = "EBA3B4" -- pink chalk
local DUSK = "7B9DC4" -- a dusty blue
local BRICK = "C96B5E" -- a dusty red
local SLATE = "4A4652" -- the dark squares of a chequer

local CHALK_GREEN = Color3.fromRGB(156, 201, 142)
local CHALK_BLUE = Color3.fromRGB(126, 178, 226)
local CHALK_WHITE = Color3.fromRGB(244, 242, 236)

local function v(x: number, z: number): Vector3
	return Vector3.new(x, H / 2, z)
end

-- Drawing ---------------------------------------------------------------------------------------

-- A rectangle of paint between two corners.
local function rect(q: R, x1: number, z1: number, x2: number, z2: number, color: Color3)
	q:block(x1, 0, z1, x2, H, z2, color, MAT)
end

-- A straight stroke w wide along the line from (x1, z1) to (x2, z2). `cap` carries it on past
-- each end by half its width, so strokes that meet at a corner fill it.
local function stroke(q: R, x1: number, z1: number, x2: number, z2: number, w: number, color: Color3, cap: boolean?)
	local dx, dz = x2 - x1, z2 - z1
	local len = math.sqrt(dx * dx + dz * dz)
	if len < 1e-4 then
		return
	end
	if cap then
		local ex, ez = dx / len * w / 2, dz / len * w / 2
		x1, z1, x2, z2 = x1 - ex, z1 - ez, x2 + ex, z2 + ez
		len += w
	end
	if math.abs(dx) < 1e-6 then
		rect(q, x1 - w / 2, z1, x1 + w / 2, z2, color)
	elseif math.abs(dz) < 1e-6 then
		rect(q, x1, z1 - w / 2, x2, z1 + w / 2, color)
	else
		local cf = CFrame.new((x1 + x2) / 2, H / 2, (z1 + z2) / 2) * CFrame.Angles(0, math.atan2(dx, dz), 0)
		q:boxAt(cf, w, H, len, color, MAT)
	end
end

-- A filled triangle of paint.
local function tri(q: R, x1: number, z1: number, x2: number, z2: number, x3: number, z3: number, color: Color3)
	q:tri(v(x1, z1), v(x2, z2), v(x3, z3), H, color, MAT)
end

-- A right triangle of paint as a single wedge: its square corner at (x, z), one leg (ax, az) from
-- there and the other (bx, bz), the two square to each other.
local function corner(q: R, x: number, z: number, ax: number, az: number, bx: number, bz: number, color: Color3)
	local a, b = Vector3.new(ax, 0, az), Vector3.new(bx, 0, bz)
	local la, lb = a.Magnitude, b.Magnitude
	if la < 1e-4 or lb < 1e-4 then
		return
	end
	-- (a Roblox wedge's square corner is at its bottom back: its legs run along -Z and +Y)
	local up, back = b / lb, -a / la
	q:wedge(CFrame.fromMatrix(v(x, z) + (a + b) / 2, up:Cross(back), up, back), H, lb, la, color, MAT)
end

-- Part of a ring round (cx, cz): `n` boxes from angle a0 to a1 (radians, from +X toward +Z), the
-- middle of the stroke `rad` out and the stroke `w` across. Each box runs out to its neighbours'
-- outer corners, so together they make an even band with no gaps between them (inside, they
-- overlap in the same paint). `every` draws only every so many boxes, for a dashed curve.
local function arc(
	q: R,
	cx: number,
	cz: number,
	rad: number,
	w: number,
	a0: number,
	a1: number,
	n: number,
	color: Color3,
	every: number?
)
	local d = (a1 - a0) / n
	local len = 2 * (rad + w / 2) * math.tan(math.abs(d) / 2)
	for i = 0, n - 1 do
		if every and i % every ~= 0 then
			continue
		end
		local a = a0 + (i + 0.5) * d
		local cf = CFrame.new(cx + math.cos(a) * rad, H / 2, cz + math.sin(a) * rad) * CFrame.Angles(0, -a, 0)
		q:boxAt(cf, w, H, len, color, MAT)
	end
end

-- A whole ring of `n` boxes, the first at angle 0. Rings of the same `n` round the same middle fit
-- against each other exactly (a target's bands), and so does a disc of the same `n` (below) whose
-- corners are at the inner edge's apothem / cos(pi / n).
local function ring(q: R, cx: number, cz: number, rad: number, w: number, n: number, color: Color3, skip: number?)
	local d = 2 * math.pi / n
	for i = 0, n - 1 do
		if skip and i % skip == 0 then
			continue
		end
		local a = i * d
		local len = 2 * (rad + w / 2) * math.tan(d / 2)
		local cf = CFrame.new(cx + math.cos(a) * rad, H / 2, cz + math.sin(a) * rad) * CFrame.Angles(0, -a, 0)
		q:boxAt(cf, w, H, len, color, MAT)
	end
end

-- A filled polygon of n sides (a multiple of 4) round (cx, cz), its corners rx across and rz along
-- from the middle (an oval when they differ), laid as strips across it: a box down the middle of
-- each strip and a wedge at each end of it.
local function disc(q: R, cx: number, cz: number, rx: number, rz: number, n: number, color: Color3)
	local m = math.floor(n / 4)
	local step = 2 * math.pi / n
	local xs, zs = {}, {}
	for j = 0, m - 1 do
		local t = (j + 0.5) * step
		xs[j] = rx * math.cos(t)
		zs[j] = rz * math.sin(t)
	end
	rect(q, cx - xs[0], cz - zs[0], cx + xs[0], cz + zs[0], color)
	for j = 0, m - 2 do
		for _, sz in { -1, 1 } do
			local z1, z2 = cz + sz * zs[j], cz + sz * zs[j + 1]
			rect(q, cx - xs[j + 1], z1, cx + xs[j + 1], z2, color)
			for _, sx in { -1, 1 } do
				corner(q, cx + sx * xs[j + 1], z1, sx * (xs[j] - xs[j + 1]), 0, 0, z2 - z1, color)
			end
		end
	end
end

-- The corner radius of a disc that fills a ring of `n` boxes whose inner edge is `apothem` out.
local function within(apothem: number, n: number): number
	return apothem / math.cos(math.pi / n)
end

-- A run of straight strokes w wide through the points (x, z pairs), mitred where they meet so the
-- paint turns each corner in one even band. `closed` joins the last point back to the first.
local function polyline(q: R, pts: { number }, w: number, color: Color3, closed: boolean?)
	local ps: { Vector3 } = {}
	for i = 1, #pts, 2 do
		table.insert(ps, Vector3.new(pts[i], 0, pts[i + 1]))
	end
	local n = #ps
	local function normal(a: Vector3, b: Vector3): Vector3
		local d = (b - a).Unit
		return Vector3.new(-d.Z, 0, d.X)
	end
	local offs: { Vector3 } = {}
	for i = 1, n do
		local prev = if i > 1 then ps[i - 1] elseif closed then ps[n] else nil
		local nxt = if i < n then ps[i + 1] elseif closed then ps[1] else nil
		local nIn = if prev then normal(prev, ps[i]) else nil
		local nOut = if nxt then normal(ps[i], nxt) else nil
		local o: Vector3
		if nIn and nOut then
			local m = nIn + nOut
			if m.Magnitude < 1e-6 then
				o = nIn * (w / 2)
			else
				m = m.Unit
				o = m * (w / 2 / m:Dot(nIn))
			end
		else
			o = ((nIn or nOut) :: Vector3) * (w / 2)
		end
		offs[i] = o
	end
	local lift = Vector3.new(0, H / 2, 0)
	local last = if closed then n else n - 1
	for i = 1, last do
		local j = i % n + 1
		local a, b = ps[i] + lift, ps[j] + lift
		q:quad(a + offs[i], b + offs[j], b - offs[j], a - offs[i], H, color, MAT)
	end
end

-- A round dot of paint, `dx` across and `dz` along, turned by `yaw` (the low poly kit draws it
-- eight sided, which is round enough for a toe or a pad).
local function dot(q: R, x: number, z: number, dx: number, dz: number, color: Color3, yaw: number?)
	q:noCollide(q:add({
		shape = "Cylinder",
		cf = CFrame.new(x, H / 2, z) * CFrame.Angles(0, yaw or 0, 0) * CFrame.Angles(0, 0, math.pi / 2),
		size = Vector3.new(H, dx, dz),
		color = color,
		mat = MAT,
	}))
end

-- Letters ---------------------------------------------------------------------------------------
--
-- Block letters and numbers on a grid five cells wide and seven tall (y up), every stroke one cell
-- thick. Each shape is one of:
--   r x0,y0,x1,y1      a rectangle of cells
--   p xb,yb,xt,yt,w    a slanted stroke: its bottom edge runs w cells from (xb, yb) and its top
--                      edge w cells from (xt, yt), so its ends lie flat like the others'
--   c x,y,sx,sy        a corner cut at 45 degrees: the half cell with its square corner at (x, y)
--                      and its legs one cell along sx and sy
-- Where a slanted stroke ends, it ends inside another stroke or on the glyph's top or bottom.

local GLYPHS: { [string]: string } = {
	A = "p0,0,2,7,1 p4,0,2,7,1 r1,2,4,3",
	B = "r0,0,1,7 r1,6,4,7 r1,3,4,4 r1,0,4,1 r4,4,5,6 r4,1,5,3 c4,6,1,1 c4,4,1,-1 c4,3,1,1 c4,1,1,-1",
	C = "r0,1,1,6 r1,6,4,7 r1,0,4,1 r4,5,5,6 r4,1,5,2 c1,6,-1,1 c1,1,-1,-1 c4,6,1,1 c4,1,1,-1",
	D = "r0,0,1,7 r1,6,4,7 r1,0,4,1 r4,1,5,6 c4,6,1,1 c4,1,1,-1",
	E = "r0,0,1,7 r1,6,5,7 r1,3,4,4 r1,0,5,1",
	F = "r0,0,1,7 r1,6,5,7 r1,3,4,4",
	G = "r0,1,1,6 r1,6,4,7 r1,0,4,1 r4,5,5,6 r2,3,5,4 r4,1,5,3 c1,6,-1,1 c1,1,-1,-1 c4,6,1,1 c4,1,1,-1",
	H = "r0,0,1,7 r4,0,5,7 r1,3,4,4",
	I = "r2,0,3,7 r1,6,4,7 r1,0,4,1",
	J = "r1,6,5,7 r3,1,4,6 r1,0,3,1 r0,1,1,3 c1,1,-1,-1 c3,1,1,-1",
	K = "r0,0,1,7 p0,3,3.8,7,1.2 p3.8,0,0,4,1.2",
	L = "r0,0,1,7 r1,0,5,1",
	M = "r0,0,1,7 r4,0,5,7 p2,2,0,7,1 p2,2,4,7,1",
	N = "r0,0,1,7 r4,0,5,7 p4,0,0,7,1",
	O = "r0,1,1,6 r4,1,5,6 r1,0,4,1 r1,6,4,7 c1,6,-1,1 c4,6,1,1 c1,1,-1,-1 c4,1,1,-1",
	P = "r0,0,1,7 r1,6,4,7 r1,3,4,4 r4,4,5,6 c4,6,1,1 c4,4,1,-1",
	Q = "r0,1,1,6 r4,1,5,6 r1,0,4,1 r1,6,4,7 c1,6,-1,1 c4,6,1,1 c1,1,-1,-1 c4,1,1,-1 p3.8,0,2.4,2.4,1.2",
	R = "r0,0,1,7 r1,6,4,7 r1,3,4,4 r4,4,5,6 c4,6,1,1 c4,4,1,-1 p4,0,2.2,3.5,1",
	S = "r1,6,5,7 r0,4,1,6 r1,3,4,4 r4,1,5,3 r0,0,4,1 c1,6,-1,1 c1,4,-1,-1 c4,3,1,1 c4,1,1,-1",
	T = "r0,6,5,7 r2,0,3,6",
	U = "r0,1,1,7 r4,1,5,7 r1,0,4,1 c1,1,-1,-1 c4,1,1,-1",
	V = "p2,0,0,7,1 p2,0,4,7,1 r2,0,3,1",
	W = "r0,0,1,7 r4,0,5,7 p0,0,2,5,1 p4,0,2,5,1",
	X = "p0,0,4,7,1 p4,0,0,7,1 r2,3,3,4",
	Y = "p2,3,0,7,1 p2,3,4,7,1 r2,0,3,4",
	Z = "r0,6,5,7 r0,0,5,1 p0,0.5,3.8,6.5,1.2",
	["0"] = "r0,1,1,6 r4,1,5,6 r1,0,4,1 r1,6,4,7 c1,6,-1,1 c4,6,1,1 c1,1,-1,-1 c4,1,1,-1 p1,1,3,6,1",
	["1"] = "r2,0,3,7 r1,5,2,6 c2,6,-1,1 r1,0,4,1",
	["2"] = "r1,6,4,7 r0,5,1,6 r4,4,5,6 r1,3,4,4 r0,1,1,3 r0,0,5,1 c1,6,-1,1 c4,6,1,1 c4,4,1,-1 c1,3,-1,1",
	["3"] = "r0,6,4,7 r4,4,5,6 r1,3,4,4 r4,1,5,3 r0,0,4,1 c4,6,1,1 c4,4,1,-1 c4,3,1,1 c4,1,1,-1",
	["4"] = "r0,3,1,7 r0,2,5,3 r3,0,4,7",
	["5"] = "r0,6,5,7 r0,3,1,6 r1,3,4,4 r4,1,5,3 r0,0,4,1 c4,3,1,1 c4,1,1,-1",
	["6"] = "r1,6,5,7 r0,1,1,6 r1,3,4,4 r4,1,5,3 r1,0,4,1 c1,6,-1,1 c1,1,-1,-1 c4,3,1,1 c4,1,1,-1",
	["7"] = "r0,6,5,7 p1,0,4,6.5,1",
	["8"] = "r1,6,4,7 r1,3,4,4 r1,0,4,1 r0,4,1,6 r0,1,1,3 r4,4,5,6 r4,1,5,3 "
		.. "c1,6,-1,1 c4,6,1,1 c1,1,-1,-1 c4,1,1,-1 c1,4,-1,-1 c1,3,-1,1 c4,4,1,-1 c4,3,1,1",
	["9"] = "r1,6,4,7 r0,4,1,6 r1,3,4,4 r4,1,5,6 r0,0,4,1 c1,6,-1,1 c4,6,1,1 c1,4,-1,-1 c4,1,1,-1",
}

type Shape = { kind: string, n: { number } }

local parsed: { [string]: { Shape } } = {}

local function shapesOf(ch: string): { Shape }
	local done = parsed[ch]
	if done then
		return done
	end
	local out: { Shape } = {}
	for token in string.gmatch(GLYPHS[ch] or "", "%S+") do
		local n: { number } = {}
		for num in string.gmatch(token:sub(2), "[^,]+") do
			table.insert(n, tonumber(num) :: number)
		end
		table.insert(out, { kind = token:sub(1, 1), n = n })
	end
	parsed[ch] = out
	return out
end

-- One letter or number centred on (ox, oz), each cell cw across and ch along.
local function glyph(q: R, letter: string, ox: number, oz: number, cw: number, ch: number, color: Color3)
	local function X(g: number): number
		return ox + (g - 2.5) * cw
	end
	local function Z(g: number): number
		return oz - (g - 3.5) * ch
	end
	for _, s in shapesOf(letter) do
		local n = s.n
		if s.kind == "r" then
			rect(q, X(n[1]), Z(n[2]), X(n[3]), Z(n[4]), color)
		elseif s.kind == "p" then
			local xb, yb, xt, yt, w = n[1], n[2], n[3], n[4], n[5]
			q:quad(v(X(xb), Z(yb)), v(X(xb + w), Z(yb)), v(X(xt + w), Z(yt)), v(X(xt), Z(yt)), H, color, MAT)
		else
			corner(q, X(n[1]), Z(n[2]), n[3] * cw, 0, 0, -n[4] * ch, color)
		end
	end
end

-- A word in block letters centred on (x, z), each letter's cells cw by ch and the letters `gap`
-- apart.
local function word(q: R, text: string, x: number, z: number, cw: number, ch: number, gap: number, color: Color3)
	local n = #text
	local at = x - (n * 5 * cw + (n - 1) * gap) / 2 + 2.5 * cw
	for i = 1, n do
		local letter = text:sub(i, i)
		if letter ~= " " then
			glyph(q, letter, at, z, cw, ch, color)
		end
		at += 5 * cw + gap
	end
end

-- Pieces ----------------------------------------------------------------------------------------

local function upright(p: Prim): boolean
	if p.shape ~= "Block" then
		return false
	end
	local _, _, _, a, _, _, _, e, _, _, _, k = p.cf:GetComponents()
	return math.abs(a - 1) < 1e-4 and math.abs(e - 1) < 1e-4 and math.abs(k - 1) < 1e-4
end

-- A small upright square inside a turned box or a wedge lying flat, in its paint: something for a
-- piece to be built round where a run of shapes is all slants and curves (a piece wants one box
-- that isn't turned).
local function inside(p: Prim): Prim?
	local s: number
	local at: Vector3
	if p.shape == "Block" and math.abs(p.cf.UpVector.Y) > 0.999 then
		s = math.min(p.size.X, p.size.Z) * 0.35
		at = p.cf.Position
	elseif p.shape == "Wedge" and math.abs(p.cf.RightVector.Y) > 0.999 then
		-- the middle of the circle inside the triangle, its square corner at the bottom back
		local la, lb = p.size.Z, p.size.Y
		local r = (la + lb - math.sqrt(la * la + lb * lb)) / 2
		s = r * 1.2
		at = (p.cf * CFrame.new(0, -lb / 2 + r, la / 2 - r)).Position
	else
		return nil
	end
	if s < 0.01 then
		return nil
	end
	return Geometry.box(CFrame.new(at.X, H / 2, at.Z), Vector3.new(s, H, s), p.color, p.mat)
end

-- Draws a mark on r: `draw` paints its shapes on a recipe of its own, and they go onto r as pieces
-- of a few dozen shapes each (one mesh apiece in the game), the round dots as parts of their own.
-- Nothing of it is solid: paint is walked over.
local function paint(r: R, draw: (R) -> ())
	local q = Recipe.new(r.c1, r.c2)
	draw(q)
	local flat: { Prim } = {}
	local loose: { Prim } = {}
	for _, p in q.prims do
		if Geometry.merges(p) then
			table.insert(flat, p)
		else
			table.insert(loose, p)
		end
	end
	local room = Geometry.PieceMax - 1 -- (leaving room for a square to build it round)
	for start = 1, #flat, room do
		local shapes = table.move(flat, start, math.min(start + room - 1, #flat), 1, {})
		local found = false
		for _, p in shapes do
			if upright(p) then
				found = true
				break
			end
		end
		if not found then
			for _, p in shapes do
				local square = inside(p)
				if square then
					table.insert(shapes, 1, square)
					found = true
					break
				end
			end
		end
		if found then
			r:add(Geometry.piece(shapes))
		else
			for _, p in shapes do
				table.insert(loose, p)
			end
		end
	end
	for _, p in loose do
		r:noCollide(r:add(p))
	end
end

-- Marks -----------------------------------------------------------------------------------------

type Item = {
	id: string,
	name: string,
	cat: string,
	price: number,
	place: string,
	size: Vector3,
	c1: string,
	c2: string?,
	tags: { string }?,
	style: string?,
	build: (r: R) -> (),
}

type Spec = {
	id: string,
	name: string,
	price: number,
	w: number,
	d: number,
	c1: string,
	c2: string?,
	style: string?,
	tags: { string }?,
	draw: (q: R, c1: Color3, c2: Color3) -> (),
}

local items: { Item } = {}

-- A mark w across and d along, its paint drawn by s.draw(q, c1, c2).
local function mark(s: Spec)
	table.insert(items, {
		id = s.id,
		name = s.name,
		cat = "markings",
		price = s.price,
		place = "mark",
		size = Vector3.new(s.w, H, s.d),
		c1 = s.c1,
		c2 = s.c2,
		style = s.style,
		tags = s.tags,
		build = function(r: R)
			paint(r, function(q: R)
				s.draw(q, r.c1, r.c2)
			end)
		end,
	})
end

-- Lines

mark({
	id = "mark_line",
	name = "Line",
	price = 6,
	w = 1,
	d = 8,
	c1 = WHITE,
	draw = function(q: R, c: Color3)
		rect(q, -0.15, -4, 0.15, 4, c)
	end,
})

mark({
	id = "mark_line_long",
	name = "Long line",
	price = 12,
	w = 1,
	d = 24,
	c1 = WHITE,
	draw = function(q: R, c: Color3)
		rect(q, -0.15, -12, 0.15, 12, c)
	end,
})

mark({
	id = "mark_line_thick",
	name = "Thick line",
	price = 8,
	w = 1,
	d = 8,
	c1 = WHITE,
	draw = function(q: R, c: Color3)
		rect(q, -0.4, -4, 0.4, 4, c)
	end,
})

mark({
	id = "mark_line_dashed",
	name = "Dashed line",
	price = 8,
	w = 1,
	d = 16,
	c1 = WHITE,
	draw = function(q: R, c: Color3)
		-- four dashes with half a gap at each end, so two laid end to end keep the rhythm
		for i = 0, 3 do
			local z = -6 + i * 4
			rect(q, -0.15, z - 1.2, 0.15, z + 1.2, c)
		end
	end,
})

mark({
	id = "mark_line_double",
	name = "Double line",
	price = 10,
	w = 2,
	d = 8,
	c1 = YELLOW,
	draw = function(q: R, c: Color3)
		rect(q, -0.5, -4, -0.2, 4, c)
		rect(q, 0.2, -4, 0.5, 4, c)
	end,
})

mark({
	id = "mark_line_corner",
	name = "Corner line",
	price = 6,
	w = 4,
	d = 4,
	c1 = WHITE,
	draw = function(q: R, c: Color3)
		rect(q, -2, -2, -1.7, 2, c)
		rect(q, -1.7, -2, 2, -1.7, c)
	end,
})

mark({
	id = "mark_line_curve",
	name = "Curved line",
	price = 10,
	w = 4,
	d = 4,
	c1 = WHITE,
	draw = function(q: R, c: Color3)
		-- a quarter circle from one corner of its square to the opposite one
		arc(q, 2, 2, 3.85, 0.3, math.pi, 1.5 * math.pi, 12, c)
	end,
})

mark({
	id = "mark_line_zigzag",
	name = "Zigzag line",
	price = 10,
	w = 2,
	d = 12,
	c1 = YELLOW,
	draw = function(q: R, c: Color3)
		local pts = {}
		for i = 0, 8 do
			table.insert(pts, if i % 2 == 0 then -0.65 else 0.65)
			table.insert(pts, -5.6 + i * 1.4)
		end
		polyline(q, pts, 0.25, c)
	end,
})

mark({
	id = "mark_chevrons",
	name = "Chevrons",
	price = 12,
	w = 2,
	d = 8,
	c1 = WHITE,
	draw = function(q: R, c: Color3)
		for _, z in { -3.4, -1.4, 0.6, 2.6 } do
			polyline(q, { -0.85, z + 0.85, 0, z, 0.85, z + 0.85 }, 0.35, c)
		end
	end,
})

-- On the road

mark({
	id = "mark_stop_line",
	name = "Stop line",
	price = 16,
	w = 8,
	d = 6,
	c1 = WHITE,
	draw = function(q: R, c: Color3)
		rect(q, -3.8, -2.9, 3.8, -2.1, c)
		word(q, "STOP", 0, 1, 0.3, 0.34, 0.35, c)
	end,
})

mark({
	id = "mark_give_way",
	name = "Give way",
	price = 12,
	w = 8,
	d = 2,
	c1 = WHITE,
	draw = function(q: R, c: Color3)
		-- a row of teeth pointing at whoever is coming
		for i = -2, 2 do
			local x = i * 1.6
			tri(q, x - 0.6, -0.8, x + 0.6, -0.8, x, 0.8, c)
		end
	end,
})

mark({
	id = "mark_slow",
	name = "Slow",
	price = 12,
	w = 8,
	d = 3,
	c1 = WHITE,
	draw = function(q: R, c: Color3)
		word(q, "SLOW", 0, 0, 0.3, 0.34, 0.35, c)
	end,
})

mark({
	id = "mark_crossing",
	name = "Zebra crossing",
	price = 20,
	w = 10,
	d = 6,
	c1 = WHITE,
	draw = function(q: R, c: Color3)
		for i = -2, 2 do
			rect(q, i * 2 - 0.6, -3, i * 2 + 0.6, 3, c)
		end
	end,
})

mark({
	id = "mark_hatched_box",
	name = "Hatched box",
	price = 16,
	w = 8,
	d = 8,
	c1 = YELLOW,
	draw = function(q: R, c: Color3)
		rect(q, -4, -4, -3.7, 4, c)
		rect(q, 3.7, -4, 4, 4, c)
		rect(q, -3.7, -4, 3.7, -3.7, c)
		rect(q, -3.7, 3.7, 3.7, 4, c)
		-- slanted lines from edge to edge, each ending on the middle of the edge line
		local a = 3.85
		for k = -3, 3 do
			local off = k * 2
			if off >= 0 then
				stroke(q, -a + off, -a, a, a - off, 0.3, c)
			else
				stroke(q, -a, -a - off, a + off, a, 0.3, c)
			end
		end
	end,
})

mark({
	id = "mark_bike",
	name = "Bike lane sign",
	price = 14,
	w = 4,
	d = 4,
	c1 = WHITE,
	draw = function(q: R, c: Color3)
		-- a bicycle side on, its wheels at the front edge and its saddle and bars toward the back
		local z0 = -0.2
		ring(q, -1.1, 0.5 + z0, 0.8, 0.18, 16, c)
		ring(q, 1.1, 0.5 + z0, 0.8, 0.18, 16, c)
		local w = 0.16
		local function bar(x1: number, z1: number, x2: number, z2: number)
			stroke(q, x1, z1 + z0, x2, z2 + z0, w, c, true)
		end
		bar(-1.1, 0.5, -0.05, 0.5) -- chain stay
		bar(-1.1, 0.5, -0.45, -0.55) -- seat stay
		bar(-0.05, 0.5, -0.55, -0.8) -- seat tube, up to the saddle
		bar(-0.45, -0.55, 0.8, -0.55) -- top tube
		bar(-0.05, 0.5, 0.8, -0.55) -- down tube
		bar(0.8, -0.55, 1.1, 0.5) -- fork
		bar(0.8, -0.55, 0.7, -0.95) -- stem
		bar(0.7, -0.95, 1.05, -0.95) -- bars
		stroke(q, -0.85, -0.9 + z0, -0.3, -0.9 + z0, 0.2, c, true) -- saddle
	end,
})

-- Arrows (pointing ahead, to -Z)

local SHAFT = 0.5
local HEAD = 0.8 -- half the width of an arrow's head
local POINT = 1.8 -- how long the head is

mark({
	id = "mark_arrow",
	name = "Arrow",
	price = 10,
	w = 2,
	d = 6,
	c1 = WHITE,
	draw = function(q: R, c: Color3)
		rect(q, -SHAFT / 2, -1.4, SHAFT / 2, 3, c)
		tri(q, -HEAD, -1.2, HEAD, -1.2, 0, -3, c)
	end,
})

-- A turn arrow: up its shaft, round a bend and off to one side (side -1 is left, 1 right).
local function turnArrow(q: R, c: Color3, side: number)
	local sx = -side
	rect(q, sx * 1.2 - SHAFT / 2, -0.5, sx * 1.2 + SHAFT / 2, 3, c)
	if side < 0 then
		arc(q, sx * 0.3, -0.5, 0.9, SHAFT, 0, -math.pi / 2, 6, c)
	else
		arc(q, sx * 0.3, -0.5, 0.9, SHAFT, math.pi, 1.5 * math.pi, 6, c)
	end
	tri(q, sx * 0.2, -1.4 - HEAD, sx * 0.2, -1.4 + HEAD, sx * 0.2 + side * POINT, -1.4, c)
end

mark({
	id = "mark_arrow_left",
	name = "Left turn arrow",
	price = 10,
	w = 4,
	d = 6,
	c1 = WHITE,
	draw = function(q: R, c: Color3)
		turnArrow(q, c, -1)
	end,
})

mark({
	id = "mark_arrow_right",
	name = "Right turn arrow",
	price = 10,
	w = 4,
	d = 6,
	c1 = WHITE,
	draw = function(q: R, c: Color3)
		turnArrow(q, c, 1)
	end,
})

mark({
	id = "mark_arrow_both",
	name = "Two way arrow",
	price = 12,
	w = 2,
	d = 8,
	c1 = WHITE,
	draw = function(q: R, c: Color3)
		rect(q, -SHAFT / 2, -2.4, SHAFT / 2, 2.4, c)
		tri(q, -HEAD, -2.2, HEAD, -2.2, 0, -4, c)
		tri(q, -HEAD, 2.2, HEAD, 2.2, 0, 4, c)
	end,
})

mark({
	id = "mark_arrow_uturn",
	name = "U turn arrow",
	price = 12,
	w = 4,
	d = 6,
	c1 = WHITE,
	draw = function(q: R, c: Color3)
		local ox = 0.27
		rect(q, ox + 1 - SHAFT / 2, -1, ox + 1 + SHAFT / 2, 3, c)
		arc(q, ox, -1, 1, SHAFT, 0, -math.pi, 12, c)
		rect(q, ox - 1 - SHAFT / 2, -1, ox - 1 + SHAFT / 2, 0.7, c)
		tri(q, ox - 1 - HEAD, 0.5, ox - 1 + HEAD, 0.5, ox - 1, 0.5 + POINT, c)
	end,
})

mark({
	id = "mark_arrow_split",
	name = "Ahead or right arrow",
	price = 12,
	w = 4,
	d = 6,
	c1 = WHITE,
	draw = function(q: R, c: Color3)
		local x = -0.6
		rect(q, x - SHAFT / 2, -1.4, x + SHAFT / 2, 3, c)
		tri(q, x - HEAD, -1.2, x + HEAD, -1.2, x, -3, c)
		-- a branch off to the right, its head square to it
		local k = math.sqrt(0.5)
		local bx, bz = 0.45, 0.55 -- the middle of the branch's head at its base
		stroke(q, x, 1.6, bx + 0.2 * k, bz - 0.2 * k, SHAFT, c)
		tri(q, bx + HEAD * k, bz + HEAD * k, bx - HEAD * k, bz - HEAD * k, bx + POINT * k, bz - POINT * k, c)
	end,
})

-- Parking

mark({
	id = "mark_parking_bay",
	name = "Parking bay",
	price = 16,
	w = 8,
	d = 14,
	c1 = WHITE,
	draw = function(q: R, c: Color3)
		rect(q, -4, -7, -3.7, 7, c)
		rect(q, 3.7, -7, 4, 7, c)
		rect(q, -3.7, -7, 3.7, -6.7, c)
	end,
})

mark({
	id = "mark_parking_row",
	name = "Parking row",
	price = 40,
	w = 24,
	d = 14,
	c1 = WHITE,
	draw = function(q: R, c: Color3)
		-- three bays side by side, sharing the lines between them
		for _, x in { -11.85, -3.95, 3.95, 11.85 } do
			rect(q, x - 0.15, -6.7, x + 0.15, 7, c)
		end
		rect(q, -12, -7, 12, -6.7, c)
	end,
})

mark({
	id = "mark_loading_box",
	name = "Loading box",
	price = 24,
	w = 8,
	d = 14,
	c1 = YELLOW,
	draw = function(q: R, c: Color3)
		rect(q, -4, -7, -3.7, 7, c)
		rect(q, 3.7, -7, 4, 7, c)
		rect(q, -3.7, -7, 3.7, -6.7, c)
		rect(q, -3.7, 6.7, 3.7, 7, c)
		word(q, "LOADING", 0, 3.6, 0.15, 0.32, 0.17, c)
	end,
})

-- Shapes

mark({
	id = "mark_circle",
	name = "Circle",
	price = 10,
	w = 4,
	d = 4,
	c1 = WHITE,
	draw = function(q: R, c: Color3)
		disc(q, 0, 0, 1.95, 1.95, 24, c)
	end,
})

mark({
	id = "mark_ring",
	name = "Ring",
	price = 10,
	w = 6,
	d = 6,
	c1 = WHITE,
	draw = function(q: R, c: Color3)
		ring(q, 0, 0, 2.7, 0.4, 24, c)
	end,
})

mark({
	id = "mark_square",
	name = "Square",
	price = 8,
	w = 4,
	d = 4,
	c1 = WHITE,
	draw = function(q: R, c: Color3)
		rect(q, -2, -2, -1.7, 2, c)
		rect(q, 1.7, -2, 2, 2, c)
		rect(q, -1.7, -2, 1.7, -1.7, c)
		rect(q, -1.7, 1.7, 1.7, 2, c)
	end,
})

mark({
	id = "mark_triangle",
	name = "Triangle",
	price = 8,
	w = 4,
	d = 4,
	c1 = WHITE,
	draw = function(q: R, c: Color3)
		polyline(q, { 0, -1.2, 1.386, 1.2, -1.386, 1.2 }, 0.3, c, true)
	end,
})

mark({
	id = "mark_star",
	name = "Star",
	price = 12,
	w = 4,
	d = 4,
	c1 = YELLOW,
	draw = function(q: R, c: Color3)
		local cz = 0.18
		local function at(k: number, rad: number): (number, number)
			local a = -math.pi / 2 + k * math.pi / 5
			return math.cos(a) * rad, cz + math.sin(a) * rad
		end
		-- five points round a pentagon, laid side by side
		for k = 0, 4 do
			local tx, tz = at(2 * k, 1.95)
			local ax, az = at(2 * k - 1, 0.78)
			local bx, bz = at(2 * k + 1, 0.78)
			tri(q, ax, az, tx, tz, bx, bz, c)
		end
		local x0, z0 = at(1, 0.78)
		for k = 1, 3 do
			local x1, z1 = at(2 * k + 1, 0.78)
			local x2, z2 = at(2 * k + 3, 0.78)
			tri(q, x0, z0, x1, z1, x2, z2, c)
		end
	end,
})

mark({
	id = "mark_heart",
	name = "Heart",
	price = 12,
	w = 4,
	d = 4,
	c1 = WHITE,
	draw = function(q: R, c: Color3)
		-- a square stood on its corner, with a round lobe on each of its upper sides
		local side, cz = 2.2, 0.161
		q:boxAt(CFrame.new(0, H / 2, cz) * CFrame.Angles(0, math.pi / 4, 0), side, H, side, c, MAT)
		local off = side / 2 / math.sqrt(2)
		for _, sx in { -1, 1 } do
			disc(q, sx * off, cz - off, side / 2, side / 2, 20, c)
		end
	end,
})

mark({
	id = "mark_x",
	name = "Big X",
	price = 8,
	w = 4,
	d = 4,
	c1 = WHITE,
	draw = function(q: R, c: Color3)
		for _, a in { math.pi / 4, -math.pi / 4 } do
			q:boxAt(CFrame.new(0, H / 2, 0) * CFrame.Angles(0, a, 0), 0.6, H, 4.8, c, MAT)
		end
	end,
})

mark({
	id = "mark_target",
	name = "Target",
	price = 20,
	w = 6,
	d = 6,
	c1 = WHITE,
	c2 = BRICK,
	draw = function(q: R, c1: Color3, c2: Color3)
		-- bands of the two paints side by side, round a middle of the first
		local n = 24
		disc(q, 0, 0, within(0.5, n), within(0.5, n), n, c1)
		for i, inner in { 0.5, 1.1, 1.7, 2.3 } do
			ring(q, 0, 0, inner + 0.3, 0.6, n, if i % 2 == 1 then c2 else c1)
		end
	end,
})

mark({
	id = "mark_helipad",
	name = "Helipad",
	price = 40,
	w = 12,
	d = 12,
	c1 = WHITE,
	style = "modern",
	draw = function(q: R, c: Color3)
		ring(q, 0, 0, 5.6, 0.6, 32, c)
		glyph(q, "H", 0, 0, 0.55, 0.75, c)
	end,
})

-- Games and courts

mark({
	id = "mark_hopscotch",
	name = "Hopscotch",
	price = 24,
	w = 4,
	d = 14,
	c1 = WHITE,
	c2 = YELLOW,
	style = "playful",
	tags = { "games" },
	draw = function(q: R, c1: Color3, c2: Color3)
		-- chalk squares numbered 1 to 8 from the front, two side by side at 4 and 5 and at 7 and
		-- 8, and a half circle to turn round in at the far end
		local w = 0.2
		local one, two = 0.95, 1.9 -- half the width of a single square and of a pair
		local zs = {}
		for i = 0, 6 do
			zs[i] = 6.9 - i * 1.95
		end
		local function line(x1: number, z1: number, x2: number, z2: number)
			stroke(q, x1, z1, x2, z2, w, c1, true)
		end
		for i = 0, 6 do
			local half = if i <= 2 then one else two
			line(-half, zs[i], half, zs[i])
		end
		for _, sx in { -1, 1 } do
			line(sx * one, zs[0], sx * one, zs[3])
			line(sx * two, zs[3], sx * two, zs[4])
			line(sx * one, zs[4], sx * one, zs[5])
			line(sx * two, zs[5], sx * two, zs[6])
		end
		line(0, zs[3], 0, zs[4])
		line(0, zs[5], 0, zs[6])
		arc(q, 0, zs[6], two, w, math.pi, 2 * math.pi, 12, c1)
		local function num(n: string, x: number, row: number)
			glyph(q, n, x, (zs[row - 1] + zs[row]) / 2, 0.12, 0.17, c2)
		end
		num("1", 0, 1)
		num("2", 0, 2)
		num("3", 0, 3)
		num("4", -one, 4)
		num("5", one, 4)
		num("6", 0, 5)
		num("7", -one, 6)
		num("8", one, 6)
	end,
})

mark({
	id = "mark_four_square",
	name = "Four square",
	price = 20,
	w = 8,
	d = 8,
	c1 = WHITE,
	c2 = YELLOW,
	style = "playful",
	tags = { "games" },
	draw = function(q: R, c1: Color3, c2: Color3)
		rect(q, -4, -4, -3.7, 4, c1)
		rect(q, 3.7, -4, 4, 4, c1)
		rect(q, -3.7, -4, 3.7, -3.7, c1)
		rect(q, -3.7, 3.7, 3.7, 4, c1)
		rect(q, -0.15, -3.7, 0.15, 3.7, c1)
		rect(q, -3.7, -0.15, -0.15, 0.15, c1)
		rect(q, 0.15, -0.15, 3.7, 0.15, c1)
		glyph(q, "1", -1.9, 1.9, 0.2, 0.3, c2)
		glyph(q, "2", 1.9, 1.9, 0.2, 0.3, c2)
		glyph(q, "3", 1.9, -1.9, 0.2, 0.3, c2)
		glyph(q, "4", -1.9, -1.9, 0.2, 0.3, c2)
	end,
})

mark({
	id = "mark_chessboard",
	name = "Chessboard",
	price = 40,
	w = 8,
	d = 8,
	c1 = WHITE,
	c2 = SLATE,
	style = "playful",
	tags = { "games" },
	draw = function(q: R, c1: Color3, c2: Color3)
		-- eight by eight, a dark square at each player's left hand
		for i = 0, 7 do
			for j = 0, 7 do
				local x, z = -4 + i, 4 - j
				rect(q, x, z - 1, x + 1, z, if (i + j) % 2 == 0 then c2 else c1)
			end
		end
	end,
})

mark({
	id = "mark_noughts",
	name = "Noughts and crosses",
	price = 12,
	w = 6,
	d = 6,
	c1 = WHITE,
	c2 = PINK,
	style = "playful",
	tags = { "games" },
	draw = function(q: R, c1: Color3, c2: Color3)
		for _, s in { -0.95, 0.95 } do
			rect(q, s - 0.1, -2.8, s + 0.1, 2.8, c1)
			rect(q, -2.8, s - 0.1, 2.8, s + 0.1, c1)
		end
		-- a game just started: a cross in the middle and a nought in a corner
		for _, a in { math.pi / 4, -math.pi / 4 } do
			q:boxAt(CFrame.new(0, H / 2, 0) * CFrame.Angles(0, a, 0), 0.22, H, 1.4, c2, MAT)
		end
		ring(q, -1.9, 1.9, 0.55, 0.2, 12, c2)
	end,
})

mark({
	id = "mark_basketball",
	name = "Basketball half court",
	price = 70,
	w = 24,
	d = 20,
	c1 = WHITE,
	draw = function(q: R, c: Color3)
		local w = 0.3
		-- the edges: the baseline under the hoop, the sidelines and the halfway line
		rect(q, -12, -10, 12, -9.7, c)
		rect(q, -12, 9.7, 12, 10, c)
		rect(q, -12, -9.7, -11.7, 9.7, c)
		rect(q, 11.7, -9.7, 12, 9.7, c)
		-- half the centre circle
		arc(q, 0, 9.85, 2.4, w, math.pi, 2 * math.pi, 12, c)
		-- the lane, its free throw line and circle (dashed inside the lane), and its hash marks
		for _, sx in { -1, 1 } do
			rect(q, sx * 2.4 - w / 2, -9.7, sx * 2.4 + w / 2, -3.25, c)
			for _, z in { -7.6, -6.4, -5.2 } do
				rect(q, sx * 2.55, z - 0.15, sx * 3.05, z + 0.15, c)
			end
		end
		rect(q, -2.25, -3.55, 2.25, -3.25, c)
		arc(q, 0, -3.4, 2.4, w, 0, math.pi, 12, c)
		arc(q, 0, -3.4, 2.4, w, math.pi, 2 * math.pi, 12, c, 2)
		-- round the hoop: the small arc under it and the three point line
		local hoop = -8.4
		arc(q, 0, hoop, 1.25, w, 0, math.pi, 8, c)
		for _, sx in { -1, 1 } do
			rect(q, sx * 10.4 - w / 2, -9.7, sx * 10.4 + w / 2, hoop, c)
		end
		arc(q, 0, hoop, 10.4, w, 0, math.pi, 24, c)
	end,
})

mark({
	id = "mark_tennis",
	name = "Tennis half court",
	price = 50,
	w = 14,
	d = 16,
	c1 = WHITE,
	draw = function(q: R, c: Color3)
		-- the net's line at the back, the baseline at the front, the doubles and singles sidelines,
		-- the service line, the line between the two service boxes and the centre mark
		rect(q, -7, -8, 7, -7.7, c)
		rect(q, -7, 7.7, 7, 8, c)
		for _, sx in { -1, 1 } do
			rect(q, sx * 6.85 - 0.15, -7.7, sx * 6.85 + 0.15, 7.7, c)
			rect(q, sx * 5.25 - 0.15, -7.7, sx * 5.25 + 0.15, 7.7, c)
		end
		rect(q, -5.1, 0.25, 5.1, 0.55, c)
		rect(q, -0.15, -7.7, 0.15, 0.25, c)
		rect(q, -0.15, 7.2, 0.15, 7.7, c)
	end,
})

mark({
	id = "mark_track_lane",
	name = "Track lane",
	price = 24,
	w = 3,
	d = 24,
	c1 = WHITE,
	c2 = YELLOW,
	draw = function(q: R, c1: Color3, c2: Color3)
		rect(q, -1.5, -12, -1.3, 12, c1)
		rect(q, 1.3, -12, 1.5, 12, c1)
		rect(q, -1.3, 9.0, 1.3, 9.4, c1)
		glyph(q, "1", 0, 10.7, 0.16, 0.2, c2)
	end,
})

mark({
	id = "mark_start_line",
	name = "Start line",
	price = 20,
	w = 8,
	d = 5,
	c1 = WHITE,
	c2 = SLATE,
	draw = function(q: R, c1: Color3, c2: Color3)
		-- a chequered band, then the word on the side you start from
		for i = 0, 15 do
			for j = 0, 1 do
				local x, z = -4 + i * 0.5, -2.2 + j * 0.5
				rect(q, x, z, x + 0.5, z + 0.5, if (i + j) % 2 == 0 then c2 else c1)
			end
		end
		word(q, "START", 0, 0.95, 0.24, 0.3, 0.3, c1)
	end,
})

-- By the sea

mark({
	id = "mark_compass",
	name = "Compass rose",
	price = 30,
	w = 10,
	d = 10,
	c1 = WHITE,
	c2 = DUSK,
	style = "seaside",
	draw = function(q: R, c1: Color3, c2: Color3)
		-- eight points round the middle, each split down its length into the two paints. The
		-- four long ones meet in the middle; the four short ones stand on their sides.
		local function at(k: number, rad: number): Vector3
			local a = -math.pi / 2 + k * math.pi / 4
			return Vector3.new(math.cos(a) * rad, 0, math.sin(a) * rad)
		end
		local function piece(a: Vector3, b: Vector3, cc: Vector3, color: Color3)
			tri(q, a.X, a.Z, b.X, b.Z, cc.X, cc.Z, color)
		end
		local mid = Vector3.zero
		for k = 0, 6, 2 do
			local tip = at(k, 3.5)
			piece(mid, tip, at(k - 1, 0.55), c1)
			piece(mid, tip, at(k + 1, 0.55), c2)
		end
		for k = 1, 7, 2 do
			local base = at(k, 0.55)
			local tip = at(k, 2.3)
			local left = base + (at(k - 1, 3.5) - base) * 0.3
			local right = base + (at(k + 1, 3.5) - base) * 0.3
			piece(base, left, tip, c1)
			piece(base, right, tip, c2)
		end
		-- a ring round it, broken where the long points cross it, and N at the top
		ring(q, 0, 0, 2.85, 0.2, 24, c1, 6)
		glyph(q, "N", 0, -4.25, 0.18, 0.2, c1)
	end,
})

-- Prints

-- One bare foot, toes to -Z, at (x, z): side 1 is a right foot (its big toe to -X), -1 a left.
local function foot(q: R, c: Color3, x: number, z: number, side: number)
	local t = side * 0.12 -- turned out a little
	local ct, st = math.cos(t), math.sin(t)
	local function put(fx: number, fz: number, dx: number, dz: number)
		local lx = fx * side
		dot(q, x + lx * ct - fz * st, z + lx * st + fz * ct, dx, dz, c, -t)
	end
	put(0.02, 0.33, 0.34, 0.38) -- heel
	put(0.1, 0.06, 0.22, 0.5) -- the outer edge
	put(0, -0.18, 0.46, 0.36) -- ball
	put(-0.12, -0.5, 0.18, 0.18)
	put(0.04, -0.54, 0.12, 0.12)
	put(0.15, -0.52, 0.11, 0.11)
	put(0.24, -0.46, 0.1, 0.1)
	put(0.31, -0.38, 0.09, 0.09)
end

mark({
	id = "mark_footprints",
	name = "Footprints",
	price = 10,
	w = 2,
	d = 6,
	c1 = WHITE,
	draw = function(q: R, c: Color3)
		foot(q, c, 0.4, -2.1, 1)
		foot(q, c, -0.4, -0.7, -1)
		foot(q, c, 0.4, 0.7, 1)
		foot(q, c, -0.4, 2.1, -1)
	end,
})

mark({
	id = "mark_pawprints",
	name = "Paw prints",
	price = 10,
	w = 2,
	d = 6,
	c1 = WHITE,
	draw = function(q: R, c: Color3)
		for i, z in { -2.1, -0.7, 0.7, 2.1 } do
			local x = if i % 2 == 1 then 0.35 else -0.35
			dot(q, x, z + 0.12, 0.44, 0.36, c)
			dot(q, x - 0.26, z - 0.22, 0.15, 0.19, c)
			dot(q, x - 0.09, z - 0.36, 0.15, 0.19, c)
			dot(q, x + 0.09, z - 0.36, 0.15, 0.19, c)
			dot(q, x + 0.26, z - 0.22, 0.15, 0.19, c)
		end
	end,
})

-- Chalk

mark({
	id = "mark_chalk_sun",
	name = "Chalk sun",
	price = 10,
	w = 4,
	d = 4,
	c1 = YELLOW,
	style = "playful",
	draw = function(q: R, c: Color3)
		ring(q, 0, 0, 0.9, 0.18, 16, c)
		for k = 0, 7 do
			local a = k * math.pi / 4
			stroke(q, math.cos(a) * 1.25, math.sin(a) * 1.25, math.cos(a) * 1.85, math.sin(a) * 1.85, 0.18, c)
		end
		dot(q, -0.3, -0.2, 0.18, 0.18, c)
		dot(q, 0.3, -0.2, 0.18, 0.18, c)
		arc(q, 0, 0, 0.45, 0.12, 0.5, math.pi - 0.5, 6, c)
	end,
})

mark({
	id = "mark_chalk_flower",
	name = "Chalk flower",
	price = 10,
	w = 3,
	d = 4,
	c1 = WHITE,
	c2 = YELLOW,
	style = "playful",
	draw = function(q: R, c1: Color3, c2: Color3)
		local cz = -0.75
		dot(q, 0, cz, 0.55, 0.55, c2)
		for k = 0, 5 do
			local a = math.pi / 6 + k * math.pi / 3
			dot(q, math.cos(a) * 0.75, cz + math.sin(a) * 0.75, 0.36, 0.66, c1, math.pi / 2 - a)
		end
		stroke(q, 0, 0.45, 0, 1.9, 0.14, CHALK_GREEN)
		dot(q, -0.27, 1.2, 0.2, 0.5, CHALK_GREEN, -math.pi / 4)
		dot(q, 0.27, 1.35, 0.2, 0.5, CHALK_GREEN, math.pi / 4)
	end,
})

mark({
	id = "mark_chalk_house",
	name = "Chalk house",
	price = 10,
	w = 4,
	d = 4,
	c1 = WHITE,
	c2 = PINK,
	style = "playful",
	draw = function(q: R, c1: Color3, c2: Color3)
		local w = 0.14
		local function line(x1: number, z1: number, x2: number, z2: number, color: Color3)
			stroke(q, x1, z1, x2, z2, w, color, true)
		end
		-- the walls
		line(-1.1, -0.3, 1.1, -0.3, c1)
		line(-1.1, 1.7, 1.1, 1.7, c1)
		line(-1.1, -0.3, -1.1, 1.7, c1)
		line(1.1, -0.3, 1.1, 1.7, c1)
		-- a door with a knob, and a window with a cross in it
		line(-0.75, 0.75, -0.75, 1.7, c1)
		line(-0.15, 0.75, -0.15, 1.7, c1)
		line(-0.75, 0.75, -0.15, 0.75, c1)
		dot(q, -0.3, 1.25, 0.1, 0.1, c1)
		line(0.2, 0.15, 0.8, 0.15, c1)
		line(0.2, 0.75, 0.8, 0.75, c1)
		line(0.2, 0.15, 0.2, 0.75, c1)
		line(0.8, 0.15, 0.8, 0.75, c1)
		line(0.5, 0.15, 0.5, 0.75, c1)
		line(0.2, 0.45, 0.8, 0.45, c1)
		-- the roof, over the walls with a little gap, and a chimney on it
		polyline(q, { -1.45, -0.5, 0, -1.75, 1.45, -0.5 }, w, c2)
		line(0.7, -1.06, 0.7, -1.55, c2)
		line(1, -0.84, 1, -1.55, c2)
		line(0.7, -1.55, 1, -1.55, c2)
	end,
})

mark({
	id = "mark_chalk_smiley",
	name = "Smiley",
	price = 10,
	w = 4,
	d = 4,
	c1 = YELLOW,
	style = "playful",
	draw = function(q: R, c: Color3)
		ring(q, 0, 0, 1.75, 0.24, 20, c)
		dot(q, -0.55, -0.45, 0.24, 0.42, c)
		dot(q, 0.55, -0.45, 0.24, 0.42, c)
		arc(q, 0, -0.05, 0.95, 0.22, 0.45, math.pi - 0.45, 8, c)
	end,
})

mark({
	id = "mark_chalk_rainbow",
	name = "Chalk rainbow",
	price = 14,
	w = 6,
	d = 4,
	c1 = YELLOW,
	c2 = PINK,
	style = "playful",
	draw = function(q: R, c1: Color3, c2: Color3)
		-- three bands side by side, and a cloud at each end
		local cz = 0.9
		arc(q, 0, cz, 1.25, 0.5, math.pi, 2 * math.pi, 12, CHALK_BLUE)
		arc(q, 0, cz, 1.75, 0.5, math.pi, 2 * math.pi, 12, c1)
		arc(q, 0, cz, 2.25, 0.5, math.pi, 2 * math.pi, 12, c2)
		for _, sx in { -1, 1 } do
			dot(q, sx * 1.75, 1.45, 0.55, 0.55, CHALK_WHITE)
			dot(q, sx * 1.32, 1.55, 0.4, 0.4, CHALK_WHITE)
			dot(q, sx * 2.18, 1.55, 0.42, 0.42, CHALK_WHITE)
		end
	end,
})

-- Numbers and letters, for spelling things out: each its own mark two studs across, so they can
-- be laid in a row.

for i = 0, 9 do
	local n = tostring(i)
	mark({
		id = "mark_number_" .. n,
		name = "Number " .. n,
		price = 4,
		w = 2,
		d = 3,
		c1 = WHITE,
		draw = function(q: R, c: Color3)
			glyph(q, n, 0, 0, 0.32, 0.38, c)
		end,
	})
end

for i = string.byte("A"), string.byte("Z") do
	local letter = string.char(i)
	mark({
		id = "mark_letter_" .. string.lower(letter),
		name = "Letter " .. letter,
		price = 4,
		w = 2,
		d = 3,
		c1 = WHITE,
		draw = function(q: R, c: Color3)
			glyph(q, letter, 0, 0, 0.32, 0.38, c)
		end,
	})
end

return items
