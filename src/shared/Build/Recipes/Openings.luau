--!strict
-- Doors and windows. These sit in a wall and cut a hole in it the size of `opening`
-- (w wide, h tall, its bottom `sill` above the floor). The frame is drawn in the hole's own space:
-- x along the wall, y up from the hole's bottom, z across the wall (+z faces the side chosen).
--
-- Every hole gets its trim the way a real one does (the user: "the amount of detail should be
-- similar to the default house everywhere"): a lining over the sides of the hole, an architrave
-- round it on each face of the wall with a cap over the head, plinth blocks at a door's feet, a
-- sill and an apron under a window, and in a window a sash with its glazing bars and the glass set
-- back in the middle of the wall. All of that trim is one piece (one part). The lining reaches a
-- little into the hole, so the wall's own cut faces sit behind it and nothing flickers there.

local Recipe = require(script.Parent.Parent.Recipe)
local Tuning = require(script.Parent.Parent.Parent.Config.Tuning)
local Colors = require(script.Parent.Parent.Parent.Util.Colors)

local C = Recipe.Colors

type R = Recipe.Recipe

local function shade(c: Color3, k: number): Color3
	return Colors.shade(c, k)
end

local WALL = Tuning.Plot.WallThickness / 2 -- from the wall's middle to its face
local E = 0.05 -- how far the lining reaches into the hole
local LZ = WALL - 0.03 -- the lining's faces, just inside the wall's own
local AZ0, AZ1 = WALL - 0.03, WALL + 0.1 -- an architrave: sunk a little into the wall, standing out of it
local AW = 0.24 -- an architrave's width
local IRON = Color3.fromRGB(52, 50, 56)
local BRASS = Color3.fromRGB(206, 168, 92)

-- z from a to b on the face s (1 the chosen side, -1 the other), as a low and a high value
local function zs(s: number, a: number, b: number): (number, number)
	return math.min(s * a, s * b), math.max(s * a, s * b)
end

type Casing = {
	bottom: boolean?, -- a window: a lining under the hole too, and a sill and an apron
	sill: Color3?, -- the sill's colour (the frame's by default)
	plinth: boolean?, -- a door: the jambs stand on plinth blocks
	corners: boolean?, -- square blocks at the head's corners
	faces: { number }?, -- which faces of the wall get an architrave (both by default)
	foot: number?, -- where the jambs start when there is no sill (0)
	mat: string?,
}

-- The trim round a w x h hole, drawn on q (a piece's recipe).
local function casing(q: R, w: number, h: number, color: Color3, o: Casing?)
	local opts: Casing = o or {}
	local mat = opts.mat or "Wood"
	local x0, x1 = -w / 2, w / 2
	local yb = if opts.bottom then -0.1 else 0
	q:block(x0 - 0.1, yb, -LZ, x0 + E, h + 0.1, LZ, color, mat)
	q:block(x1 - E, yb, -LZ, x1 + 0.1, h + 0.1, LZ, color, mat)
	q:block(x0 + E, h - E, -LZ, x1 - E, h + 0.1, LZ, color, mat)
	if opts.bottom then
		q:block(x0 + E, -0.1, -LZ, x1 - E, E, LZ, color, mat)
	end
	local top = h - E + AW + 0.02
	local faces: { number } = opts.faces or { 1, -1 }
	for _, s in faces do
		local za, zb = zs(s, AZ0, AZ1)
		local foot = opts.foot or 0
		if opts.bottom then
			local sa, sb = zs(s, LZ, 0.56)
			q:block(x0 - AW - 0.06, E - 0.12, sa, x1 + AW + 0.06, E + 0.05, sb, opts.sill or color, mat)
			local aa, ab = zs(s, AZ0, AZ1 - 0.02)
			q:block(x0 - AW + 0.08, -0.3, aa, x1 - (-AW + 0.08), E - 0.12, ab, opts.sill or color, mat)
			foot = E + 0.05
		elseif opts.plinth then
			local pa, pb = zs(s, AZ0, AZ1 + 0.03)
			q:block(x0 - AW - 0.03, 0, pa, x0 + E, 0.8, pb, color, mat)
			q:block(x1 - E, 0, pa, x1 + AW + 0.03, 0.8, pb, color, mat)
			foot = 0.8
		end
		q:block(x0 - AW, foot, za, x0 + E, h - E, zb, color, mat)
		q:block(x1 - E, foot, za, x1 + AW, h - E, zb, color, mat)
		q:block(x0 - AW - 0.03, h - E, za, x1 + AW + 0.03, top, zb, color, mat)
		local ca, cb = zs(s, AZ0, AZ1 + 0.04)
		q:block(x0 - AW - 0.06, top, ca, x1 + AW + 0.06, top + 0.07, cb, color, mat)
		if opts.corners then
			local ka, kb = zs(s, AZ1 - 0.02, AZ1 + 0.05)
			for _, x in { x0 - AW / 2 + E / 2, x1 + AW / 2 - E / 2 } do
				q:box(x, h - E + AW / 2, (ka + kb) / 2, AW - 0.08, AW - 0.08, kb - ka, color, mat)
			end
		end
	end
end

-- A sash filling x0..x1, y0..y1 in the middle of the wall: a frame `t` wide round it, glazing
-- bars down at each x in `xs` and across at each y in `ys`, and a deeper meeting rail at `meet`.
local function sash(
	q: R,
	x0: number,
	x1: number,
	y0: number,
	y1: number,
	t: number,
	color: Color3,
	xs: { number },
	ys: { number },
	meet: number?,
	mat: string?
)
	local m = mat or "Wood"
	q:block(x0, y0, -0.09, x0 + t, y1, 0.09, color, m)
	q:block(x1 - t, y0, -0.09, x1, y1, 0.09, color, m)
	q:block(x0 + t, y0, -0.09, x1 - t, y0 + t * 1.3, 0.09, color, m)
	q:block(x0 + t, y1 - t, -0.09, x1 - t, y1, 0.09, color, m)
	if meet then
		q:block(x0 + t, meet - 0.07, -0.12, x1 - t, meet + 0.07, 0.12, color, m)
	end
	for _, x in xs do
		q:block(x - 0.04, y0 + t * 1.3, -0.06, x + 0.04, y1 - t, 0.06, color, m)
	end
	for _, y in ys do
		q:block(x0 + t, y - 0.04, -0.06, x1 - t, y + 0.04, 0.06, color, m)
	end
end

-- A window's glass, set back in the middle of the wall behind its sash.
local function pane(r: R, w: number, h: number, bottom: boolean?)
	return r:glass(
		-w / 2 + E + 0.05,
		(if bottom == false then 0 else E) + 0.05,
		-0.03,
		w / 2 - E - 0.05,
		h - E - 0.05,
		0.03
	)
end

-- A whole window of w x h: trim, sash and glass. `xs` and `ys` place the glazing bars across the
-- hole (from its middle and its bottom), `meet` a sash window's meeting rail.
local function window(
	r: R,
	w: number,
	h: number,
	frameColor: Color3,
	sillColor: Color3,
	xs: { number },
	ys: { number },
	meet: number?,
	mat: string?
)
	local t = if w <= 2 then 0.12 else 0.15
	r:piece(function(q: R)
		casing(q, w, h, frameColor, { bottom = true, sill = sillColor, mat = mat })
		sash(q, -w / 2 + E, w / 2 - E, E, h - E, t, frameColor, xs, ys, meet, mat)
	end)
	pane(r, w, h)
end

-- Marks every prim as part of a swinging leaf hinged at hingeX.
local function swing(r: R, parts: { Recipe.Prim? }, hingeX: number)
	for _, p in parts do
		if p then
			r:door(p, hingeX)
		end
	end
end

-- A round knob on a rose plate, on both faces of a leaf `thick` deep, at (x, y).
local function knobs(r: R, x: number, y: number, thick: number, color: Color3): { Recipe.Prim? }
	local out: { Recipe.Prim? } = {}
	for _, s in { -1, 1 } do
		table.insert(out, r:cyl(x, y, s * (thick / 2 + 0.03), 0.06, 0.3, "z", color, "Metal"))
		table.insert(out, r:ball(x, y, s * (thick / 2 + 0.16), 0.28, color, "Metal"))
	end
	return out
end

-- A raised and fielded panel on both faces of a leaf `thick` deep: x1..x2, y1..y2.
local function fielded(
	r: R,
	x1: number,
	x2: number,
	y1: number,
	y2: number,
	thick: number,
	color: Color3
): { Recipe.Prim? }
	local h = thick / 2
	return {
		r:block(x1, y1, -h - 0.04, x2, y2, h + 0.04, shade(color, 0.96), "Wood"),
		r:block(x1 + 0.14, y1 + 0.14, -h - 0.08, x2 - 0.14, y2 - 0.14, h + 0.08, color, "Wood"),
	}
end

-- The hinges a leaf hangs on, on the lining at x: three knuckles on the chosen face.
local function hinges(q: R, x: number, h: number)
	for _, y in { 0.9, h / 2, h - 1.0 } do
		q:block(x - 0.05, y - 0.25, 0.1, x + 0.05, y + 0.25, 0.2, IRON, "Wood")
	end
end

-- A plain sloped board: high along z1 and down to nothing at z2, as one wedge.
local function slope(
	r: R,
	x1: number,
	y1: number,
	z1: number,
	x2: number,
	y2: number,
	z2: number,
	color: Color3,
	mat: string
): Recipe.Prim
	-- a wedge is full height at its own back (+Z), so its back is turned to z1
	local turn = if z2 > z1 then CFrame.Angles(0, math.pi, 0) else CFrame.identity
	return r:wedge(
		CFrame.new((x1 + x2) / 2, (y1 + y2) / 2, (z1 + z2) / 2) * turn,
		math.abs(x2 - x1),
		math.abs(y2 - y1),
		math.abs(z2 - z1),
		color,
		mat
	)
end

-- A bracket on a wall item's wall (z = 0) under a shelf at height y: a triangle `drop` tall
-- and `out` deep, as one wedge turned upside down, with a little scroll at its foot.
local function bracket(q: R, x: number, y: number, drop: number, out: number, color: Color3, mat: string?)
	local m = mat or "Wood"
	q:wedge(CFrame.new(x, y - drop / 2, 0.02 + out / 2) * CFrame.Angles(math.pi, 0, 0), 0.16, drop, out, color, m)
	q:block(x - 0.08, y - drop - 0.12, 0.02, x + 0.08, y - drop + 0.06, 0.16, color, m)
end

-- A louvred shutter from x1 to x2, y0 to y1, its back at z: two stiles and rails (frame) with
-- slats leaning out between them (slats), and a middle rail.
local function shutter(q: R, x1: number, x2: number, y0: number, y1: number, z: number, frame: Color3, slats: Color3)
	q:block(x1, y0, z, x1 + 0.2, y1, z + 0.2, frame, "Wood")
	q:block(x2 - 0.2, y0, z, x2, y1, z + 0.2, frame, "Wood")
	q:block(x1 + 0.2, y0, z, x2 - 0.2, y0 + 0.3, z + 0.2, frame, "Wood")
	q:block(x1 + 0.2, y1 - 0.24, z, x2 - 0.2, y1, z + 0.2, frame, "Wood")
	local mid = (y0 + y1) / 2
	q:block(x1 + 0.2, mid - 0.1, z, x2 - 0.2, mid + 0.1, z + 0.2, frame, "Wood")
	for _, run in { { y0 + 0.3, mid - 0.1 }, { mid + 0.1, y1 - 0.24 } } do
		local n = math.max(2, math.floor((run[2] - run[1]) / 0.3))
		local step = (run[2] - run[1]) / n
		for i = 0, n - 1 do
			local y = run[1] + (i + 0.5) * step
			q:boxAt(
				CFrame.new((x1 + x2) / 2, y, z + 0.1) * CFrame.Angles(math.rad(35), 0, 0),
				x2 - x1 - 0.4,
				step * 1.05,
				0.05,
				slats,
				"Wood"
			)
		end
	end
end

-- A planted box's worth of flowers on q: a mound of leaves along x0..x1 at height y, stems up
-- out of it with leaves at their middles and flower heads of `heads` colours at different heights,
-- and a few trailing stems over the front edge at z1.
local function planting(r: R, x0: number, x1: number, y: number, z0: number, z1: number, heads: { Color3 })
	local leaf, dark = C.Leaf, C.DarkLeaf
	r:piece(function(q: R)
		q:block(x0, y - 0.06, z0, x1, y + 0.12, z1, dark, "Grass")
		local n = 6
		for i = 0, n - 1 do
			local t = (i + 0.5) / n
			local x = x0 + (x1 - x0) * t
			local s = 0.42 + (i % 3) * 0.06
			q:lump(
				CFrame.new(x, y + 0.2, (z0 + z1) / 2 + (if i % 2 == 0 then 0.06 else -0.06))
					* CFrame.Angles(0, ((i % 3) - 1) * 0.25, 0),
				s + 0.2,
				0.36,
				s,
				if i % 2 == 0 then leaf else shade(leaf, 0.9),
				"Grass"
			)
		end
		-- stems trailing over the front edge
		for _, p in { { 0.12, 0.5 }, { 0.36, 0.34 }, { 0.62, 0.56 }, { 0.88, 0.4 } } do
			local x = x0 + (x1 - x0) * p[1]
			q:lump(
				CFrame.new(x, y - p[2] / 2, z1 + 0.24) * CFrame.Angles(0.3, 0, 0.3),
				0.2,
				p[2] + 0.12,
				0.16,
				leaf,
				"Grass"
			)
			q:lump(
				CFrame.new(x + 0.08, y - p[2] - 0.02, z1 + 0.28) * CFrame.Angles(0, p[1] * 4, 0),
				0.22,
				0.12,
				0.2,
				dark,
				"Grass"
			)
		end
	end)
	r:piece(function(q: R)
		local n = #heads
		for i, col in heads do
			local t = (i - 0.5) / n
			local x = x0 + (x1 - x0) * t
			local z = if i % 2 == 0 then z0 + (z1 - z0) * 0.3 else z0 + (z1 - z0) * 0.7
			local top = y + 0.5 + ((i * 7) % 3) * 0.13
			q:block(x - 0.03, y + 0.1, z - 0.03, x + 0.03, top, z + 0.03, dark, "Grass")
			q:lump(
				CFrame.new(x + 0.12, y + (top - y) * 0.55, z) * CFrame.Angles(0, 0, -0.6),
				0.3,
				0.1,
				0.18,
				leaf,
				"Grass"
			)
			q:lump(CFrame.new(x, top, z) * CFrame.Angles(0.25, i, 0), 0.42, 0.14, 0.42, col, "Grass")
			q:ball(x, top + 0.08, z + 0.02, 0.14, if col == C.Yellow then C.White else C.Yellow, "Grass")
		end
	end)
end

local items: { any } = {
	{
		id = "door_wood",
		name = "Wooden door",
		cat = "doors",
		price = 120,
		place = "opening",
		size = Vector3.new(4.6, 8.2, 1),
		opening = { w = 4, h = 8, sill = 0 },
		c1 = "AD7E55",
		c2 = "F7F3EA",
		build = function(r: R)
			-- a cottage door of boards: five upright boards on the chosen face's side with dark
			-- joins between them, iron strap hinges and a latch on that face, and on the other
			-- the three ledges and the braces that hold the boards together
			r:piece(function(q: R)
				casing(q, 4, 8, r.c2, { plinth = true })
				q:block(-1.95, 0, -0.32, 1.95, 0.06, 0.32, shade(r.c2, 0.8), "Wood")
			end)
			local hinge = -1.92
			local x0, x1, top = -1.92, 1.92, 7.9
			local parts: { Recipe.Prim? } = {}
			table.insert(parts, r:block(x0 + 0.06, 0.14, -0.06, x1 - 0.06, top - 0.04, 0.06, shade(r.c1, 0.6), "Wood"))
			local bw = (x1 - x0) / 5
			for i = 0, 4 do
				local col = if i % 2 == 0 then r.c1 else shade(r.c1, 0.93)
				table.insert(
					parts,
					r:block(x0 + i * bw + 0.02, 0.1, -0.09, x0 + (i + 1) * bw - 0.02, top, 0.09, col, "Wood")
				)
			end
			for _, y in { 1.3, 6.7 } do
				table.insert(parts, r:block(x0 + 0.05, y - 0.11, 0.09, x0 + 2.6, y + 0.11, 0.13, IRON, "Metal"))
				table.insert(parts, r:cyl(x0 + 2.6, y, 0.11, 0.04, 0.3, "z", IRON, "Metal"))
			end
			table.insert(parts, r:block(x1 - 0.5, 3.7, 0.09, x1 - 0.34, 4.5, 0.13, IRON, "Metal"))
			table.insert(parts, r:cyl(x1 - 0.42, 4.1, 0.22, 0.1, 0.34, "x", IRON, "Metal"))
			for _, y in { 0.9, 4.0, 7.1 } do
				table.insert(parts, r:block(x0 + 0.1, y - 0.25, -0.15, x1 - 0.1, y + 0.25, -0.09, r.c1, "Wood"))
			end
			table.insert(
				parts,
				r:beam(Vector3.new(x0 + 0.4, 1.1, -0.12), Vector3.new(x1 - 0.4, 3.8, -0.12), 0.06, 0.34, r.c1, "Wood")
			)
			table.insert(
				parts,
				r:beam(Vector3.new(x0 + 0.4, 4.2, -0.12), Vector3.new(x1 - 0.4, 6.9, -0.12), 0.06, 0.34, r.c1, "Wood")
			)
			table.insert(parts, r:block(x1 - 0.5, 3.95, -0.19, x1 - 0.25, 4.25, -0.15, IRON, "Metal"))
			swing(r, parts, hinge)
		end,
	},
	{
		id = "door_panel",
		name = "Panel door",
		cat = "doors",
		price = 160,
		place = "opening",
		size = Vector3.new(4.6, 8.2, 1),
		opening = { w = 4, h = 8, sill = 0 },
		c1 = "FAF6EC",
		c2 = "F7F3EA",
		build = function(r: R)
			-- four raised and fielded panels on both faces, a brass knob on a rose
			r:piece(function(q: R)
				casing(q, 4, 8, r.c2, { plinth = true })
				q:block(-1.95, 0, -0.32, 1.95, 0.06, 0.32, shade(r.c2, 0.8), "Wood")
				hinges(q, -1.95, 8)
			end)
			local hinge = -1.92
			local parts: { Recipe.Prim? } = {}
			table.insert(parts, r:block(-1.92, 0.1, -0.1, 1.92, 7.9, 0.1, r.c1, "SmoothPlastic"))
			for _, x in { { -1.55, -0.12 }, { 0.12, 1.55 } } do
				for _, y in { { 0.55, 3.3 }, { 4.1, 7.45 } } do
					for _, p in fielded(r, x[1], x[2], y[1], y[2], 0.2, r.c1) do
						table.insert(parts, p)
					end
				end
			end
			for _, p in knobs(r, 1.5, 3.75, 0.2, BRASS) do
				table.insert(parts, p)
			end
			swing(r, parts, hinge)
		end,
	},
	{
		id = "door_glass",
		name = "Glass door",
		cat = "doors",
		price = 220,
		place = "opening",
		size = Vector3.new(4.6, 8.2, 1),
		opening = { w = 4, h = 8, sill = 0 },
		c1 = "45454A",
		c2 = "45454A",
		build = function(r: R)
			-- a shop door: a slim metal frame round one big pane, a kick plate at the foot and a
			-- long pull handle standing off both faces
			r:piece(function(q: R)
				casing(q, 4, 8, r.c2, { mat = "Metal" })
				q:block(-1.95, 0, -0.32, 1.95, 0.06, 0.32, C.Metal, "Metal")
			end)
			local hinge = -1.92
			local parts: { Recipe.Prim? } = {
				r:block(-1.92, 0.1, -0.1, -1.5, 7.9, 0.1, r.c1, "Metal"),
				r:block(1.5, 0.1, -0.1, 1.92, 7.9, 0.1, r.c1, "Metal"),
				r:block(-1.5, 0.1, -0.1, 1.5, 0.9, 0.1, r.c1, "Metal"),
				r:block(-1.5, 7.45, -0.1, 1.5, 7.9, 0.1, r.c1, "Metal"),
				r:block(-1.88, 0.14, -0.13, 1.88, 0.8, 0.13, C.Metal, "Metal"),
				r:glass(-1.5, 0.9, -0.04, 1.5, 7.45, 0.04),
			}
			for _, s in { -1, 1 } do
				table.insert(parts, r:cyl(1.7, 4.0, s * 0.36, 2.6, 0.12, "y", C.Metal, "Metal"))
				for _, y in { 2.95, 5.05 } do
					table.insert(parts, r:block(1.66, y - 0.05, s * 0.08, 1.74, y + 0.05, s * 0.34, C.Metal, "Metal"))
				end
			end
			swing(r, parts, hinge)
		end,
	},
	{
		id = "door_front",
		name = "Front door with window",
		cat = "doors",
		price = 260,
		place = "opening",
		size = Vector3.new(4.6, 8.2, 1),
		opening = { w = 4, h = 8, sill = 0 },
		c1 = "46608E",
		c2 = "FAF6EC",
		build = function(r: R)
			-- a front door: two fielded panels below, four little panes above, a brass letter
			-- plate on the chosen face and a knob on both
			r:piece(function(q: R)
				casing(q, 4, 8, r.c2, { plinth = true, corners = true })
				q:block(-1.95, 0, -0.32, 1.95, 0.06, 0.32, C.Stone, "Wood")
				hinges(q, -1.95, 8)
			end)
			local hinge = -1.92
			local parts: { Recipe.Prim? } = {
				r:block(-1.92, 0.1, -0.1, 1.92, 4.6, 0.1, r.c1, "SmoothPlastic"),
				r:block(-1.92, 6.9, -0.1, 1.92, 7.9, 0.1, r.c1, "SmoothPlastic"),
				r:block(-1.92, 4.6, -0.1, -1.1, 6.9, 0.1, r.c1, "SmoothPlastic"),
				r:block(1.1, 4.6, -0.1, 1.92, 6.9, 0.1, r.c1, "SmoothPlastic"),
				r:glass(-1.1, 4.6, -0.04, 1.1, 6.9, 0.04),
				r:block(-0.04, 4.55, -0.07, 0.04, 6.95, 0.07, r.c1, "SmoothPlastic"),
				r:block(-1.15, 5.71, -0.07, 1.15, 5.79, 0.07, r.c1, "SmoothPlastic"),
				r:block(-0.45, 3.45, 0.1, 0.45, 3.75, 0.14, BRASS, "Metal"),
				r:block(-0.34, 3.55, 0.14, 0.34, 3.65, 0.17, shade(BRASS, 0.7), "Metal"),
			}
			for _, x in { { -1.5, -0.12 }, { 0.12, 1.5 } } do
				for _, p in fielded(r, x[1], x[2], 0.55, 3.15, 0.2, r.c1) do
					table.insert(parts, p)
				end
			end
			for _, p in knobs(r, 1.5, 3.95, 0.2, BRASS) do
				table.insert(parts, p)
			end
			swing(r, parts, hinge)
		end,
	},
	{
		id = "door_double",
		name = "Double doors",
		cat = "doors",
		price = 340,
		place = "opening",
		size = Vector3.new(6.6, 8.2, 1),
		opening = { w = 6, h = 8, sill = 0 },
		c1 = "8E6440",
		c2 = "F7F3EA",
		build = function(r: R)
			-- two leaves meeting in the middle, each with a tall and a short fielded panel and a
			-- knob, and a strip down the join
			r:piece(function(q: R)
				casing(q, 6, 8, r.c2, { plinth = true })
				q:block(-2.95, 0, -0.32, 2.95, 0.06, 0.32, shade(r.c2, 0.8), "Wood")
				hinges(q, -2.95, 8)
				hinges(q, 2.95, 8)
			end)
			for _, side in { -1, 1 } do
				local hinge = side * 2.92
				local a, b = math.min(side * 2.92, side * 0.02), math.max(side * 2.92, side * 0.02)
				local parts: { Recipe.Prim? } = { r:block(a, 0.1, -0.1, b, 7.9, 0.1, r.c1, "Wood") }
				for _, y in { { 0.55, 2.6 }, { 3.3, 7.45 } } do
					for _, p in fielded(r, a + 0.38, b - 0.38, y[1], y[2], 0.2, r.c1) do
						table.insert(parts, p)
					end
				end
				for _, p in knobs(r, side * 0.4, 3.0, 0.2, BRASS) do
					table.insert(parts, p)
				end
				if side == 1 then
					table.insert(parts, r:block(0.02, 0.1, 0.1, 0.16, 7.9, 0.15, shade(r.c1, 0.9), "Wood"))
				end
				swing(r, parts, hinge)
			end
		end,
	},
	{
		id = "door_barn",
		name = "Sliding barn door",
		cat = "doors",
		price = 280,
		place = "opening",
		size = Vector3.new(8.4, 8.8, 1.2),
		opening = { w = 4, h = 8, sill = 0 },
		c1 = "8E4048",
		c2 = "45454A",
		build = function(r: R)
			-- boards held by two rails and a brace, hung by two wheels from an iron track over the
			-- hole on the chosen side, and slid along it to open
			r:piece(function(q: R)
				casing(q, 4, 8, C.Cream)
			end)
			r:piece(function(q: R)
				q:block(-4.2, 8.3, 0.44, 4.2, 8.42, 0.6, r.c2, "Metal")
				for _, x in { -3.9, -0.1, 3.9 } do
					q:block(x - 0.08, 8.29, 0.3, x + 0.08, 8.47, 0.46, r.c2, "Metal")
				end
				for _, x in { -4.15, 4.15 } do
					q:block(x - 0.05, 8.42, 0.46, x + 0.05, 8.6, 0.58, r.c2, "Metal")
				end
			end)
			local parts: { Recipe.Prim? } = {}
			table.insert(parts, r:block(-2.1, 0.14, 0.53, 2.1, 8.16, 0.71, shade(r.c1, 0.55), "WoodPlanks"))
			for i = 0, 3 do
				local x = -2.2 + i * 1.1
				table.insert(
					parts,
					r:block(
						x + 0.03,
						0.1,
						0.5,
						x + 1.07,
						8.2,
						0.74,
						if i % 2 == 0 then r.c1 else shade(r.c1, 0.92),
						"WoodPlanks"
					)
				)
			end
			for _, y in { 1.5, 6.9 } do
				table.insert(parts, r:block(-2.1, y - 0.22, 0.74, 2.1, y + 0.22, 0.86, C.White, "Wood"))
			end
			table.insert(
				parts,
				r:beam(Vector3.new(-1.85, 1.7, 0.8), Vector3.new(1.85, 6.7, 0.8), 0.1, 0.4, C.White, "Wood")
			)
			for _, x in { -1.6, 1.6 } do
				table.insert(parts, r:block(x - 0.07, 7.8, 0.6, x + 0.07, 8.58, 0.78, r.c2, "Metal"))
				table.insert(parts, r:cyl(x, 8.58, 0.52, 0.08, 0.32, "z", r.c2, "Metal"))
			end
			table.insert(parts, r:block(1.7, 3.6, 0.74, 1.8, 4.6, 0.84, r.c2, "Metal"))
			for _, p in parts do
				if p then
					p.role = "door"
					p.collide = false
					p.attrs = { Slide = 4.2 }
				end
			end
		end,
	},
	{
		id = "door_garage",
		name = "Garage door",
		cat = "doors",
		price = 420,
		place = "opening",
		size = Vector3.new(8.6, 8.2, 1),
		opening = { w = 8, h = 8, sill = 0 },
		c1 = "F7F3EA",
		c2 = "D6D6D6",
		build = function(r: R)
			-- four sections that lift away, each with two raised panels, a row of little windows in
			-- the top one and a handle in the bottom one
			r:piece(function(q: R)
				casing(q, 8, 8, r.c2)
			end)
			local parts: { Recipe.Prim? } = {}
			for i = 0, 3 do
				local y = 0.1 + i * 1.95
				table.insert(parts, r:block(-3.92, y, -0.12, 3.92, y + 1.9, 0.12, r.c1, "Metal"))
				if i < 3 then
					for _, x in { { -3.6, -0.15 }, { 0.15, 3.6 } } do
						table.insert(
							parts,
							r:block(x[1], y + 0.35, -0.16, x[2], y + 1.55, 0.16, shade(r.c1, 0.96), "Metal")
						)
					end
				else
					for k = 0, 3 do
						local x = -3.0 + k * 2.0
						table.insert(
							parts,
							r:block(
								x - 0.7,
								y + 0.55,
								-0.15,
								x + 0.7,
								y + 1.3,
								0.15,
								Color3.fromRGB(70, 88, 104),
								"Glass"
							)
						)
					end
				end
			end
			table.insert(parts, r:block(-0.4, 0.9, 0.12, 0.4, 1.1, 0.2, C.DarkMetal, "Metal"))
			for _, p in parts do
				if p then
					p.role = "door"
					p.collide = false
					p.attrs = { Lift = 7.6 }
				end
			end
		end,
	},
	{
		id = "arch_open",
		name = "Open doorway",
		cat = "doors",
		price = 40,
		place = "opening",
		size = Vector3.new(4.6, 8.2, 1),
		opening = { w = 4, h = 8, sill = 0 },
		c1 = "F7F3EA",
		c2 = "F7F3EA",
		build = function(r: R)
			-- a cased opening: lining, architraves on plinths and square blocks at the corners
			r:piece(function(q: R)
				casing(q, 4, 8, r.c1, { plinth = true, corners = true })
			end)
		end,
	},
	{
		id = "arch_wide",
		name = "Wide doorway",
		cat = "doors",
		price = 70,
		place = "opening",
		size = Vector3.new(8.6, 9.2, 1),
		opening = { w = 8, h = 9, sill = 0 },
		c1 = "F7F3EA",
		c2 = "F7F3EA",
		build = function(r: R)
			-- a wide cased opening with curved brackets in its top corners, so it reads as an arch
			r:piece(function(q: R)
				casing(q, 8, 9, r.c1, { plinth = true })
			end)
			r:piece(function(q: R)
				q:block(-4 + E, 9 - E - 0.3, -LZ + 0.02, -4 + E + 0.3, 9 - E, LZ - 0.02, r.c1, "Wood")
				local rad = 1.5
				for _, sx in { -1, 1 } do
					local cx, cy = sx * (4 - E - rad), 9 - E - rad
					local corner = Vector3.new(sx * (4 - E), 9 - E, 0)
					local n = 4
					for i = 0, n - 1 do
						local a1 = i / n * math.pi / 2
						local a2 = (i + 1) / n * math.pi / 2
						local p1 = Vector3.new(cx + sx * math.cos(a1) * rad, cy + math.sin(a1) * rad, 0)
						local p2 = Vector3.new(cx + sx * math.cos(a2) * rad, cy + math.sin(a2) * rad, 0)
						q:tri(corner, p1, p2, LZ * 2 - 0.04, r.c1, "Wood")
					end
				end
			end)
		end,
	},
	-- windows ------------------------------------------------------------------------------
	{
		id = "win_small",
		name = "Small window",
		cat = "windows",
		price = 50,
		place = "opening",
		size = Vector3.new(2.6, 2.6, 1.2),
		opening = { w = 2, h = 2, sill = 5 },
		c1 = "FAF6EC",
		c2 = "FAF6EC",
		build = function(r: R)
			-- a little casement of four panes
			window(r, 2, 2, r.c1, r.c2, { 0 }, { 1.0 })
		end,
	},
	{
		id = "win_square",
		name = "Window",
		cat = "windows",
		price = 90,
		place = "opening",
		size = Vector3.new(4.6, 4.6, 1.2),
		opening = { w = 4, h = 4, sill = 3 },
		c1 = "FAF6EC",
		c2 = "FAF6EC",
		build = function(r: R)
			-- a sash window: two sashes of two panes each, meeting in the middle (c2 the sill)
			window(r, 4, 4, r.c1, r.c2, { 0 }, {}, 2.0)
		end,
	},
	{
		id = "win_wide",
		name = "Wide window",
		cat = "windows",
		price = 140,
		place = "opening",
		size = Vector3.new(6.6, 4.6, 1.2),
		opening = { w = 6, h = 4, sill = 3 },
		c1 = "FAF6EC",
		c2 = "FAF6EC",
		build = function(r: R)
			-- three lights, each with a top light over a transom
			window(r, 6, 4, r.c1, r.c2, { -1, 1 }, { 2.9 })
		end,
	},
	{
		id = "win_tall",
		name = "Tall window",
		cat = "windows",
		price = 110,
		place = "opening",
		size = Vector3.new(2.6, 6.6, 1.2),
		opening = { w = 2, h = 6, sill = 2 },
		c1 = "FAF6EC",
		c2 = "FAF6EC",
		build = function(r: R)
			-- a tall sash of six panes
			window(r, 2, 6, r.c1, r.c2, { 0 }, { 1.5, 4.5 }, 3.0)
		end,
	},
	{
		id = "win_picture",
		name = "Picture window",
		cat = "windows",
		price = 240,
		place = "opening",
		size = Vector3.new(8.6, 5.6, 1.2),
		opening = { w = 8, h = 5, sill = 2.5 },
		c1 = "45454A",
		c2 = "45454A",
		build = function(r: R)
			-- one big pane between two narrow side lights, in a slim dark frame
			window(r, 8, 5, r.c1, r.c2, { -2.75, 2.75 }, {}, nil, "Metal")
		end,
	},
	{
		id = "win_shutters",
		name = "Window with shutters",
		cat = "windows",
		price = 170,
		place = "opening",
		size = Vector3.new(8.2, 4.6, 1.4),
		opening = { w = 4, h = 4, sill = 3 },
		c1 = "5E8E5A",
		c2 = "FAF6EC",
		build = function(r: R)
			-- a casement of six panes (c2) with a louvred shutter folded back either side on the
			-- chosen face (c1)
			window(r, 4, 4, r.c2, r.c2, { 0 }, { 2.7 })
			for _, sx in { -1, 1 } do
				local a, b = math.min(sx * 2.32, sx * 4.05), math.max(sx * 2.32, sx * 4.05)
				r:piece(function(q: R)
					shutter(q, a, b, 0, 4.1, 0.44, r.c1, shade(r.c1, 0.9))
				end)
			end
			r:piece(function(q: R)
				for _, sx in { -1, 1 } do
					for _, y in { 0.7, 3.4 } do
						q:block(sx * 2.26 - 0.06, y - 0.08, 0.4, sx * 2.26 + 0.06, y + 0.08, 0.68, IRON, "Metal")
					end
				end
			end)
		end,
	},
	{
		id = "win_floor",
		name = "Floor to ceiling glass",
		cat = "windows",
		price = 260,
		place = "opening",
		size = Vector3.new(4.6, 10.6, 1.2),
		opening = { w = 4, h = 10, sill = 0.5 },
		c1 = "2A2A2E",
		c2 = "2A2A2E",
		build = function(r: R)
			-- a slim dark frame from floor to ceiling, a rail across low down and a top light
			window(r, 4, 10, r.c1, r.c2, {}, { 0.9, 7.6 }, nil, "Metal")
		end,
	},
	{
		id = "win_porthole",
		name = "Porthole window",
		cat = "windows",
		price = 130,
		place = "opening",
		size = Vector3.new(3.4, 3.4, 1.2),
		opening = { w = 3, h = 3, sill = 4 },
		c1 = "D4AE5E",
		c2 = "F7F3EA",
		build = function(r: R)
			-- a square hole with its corners filled, so the glass reads as round, and a brass ring
			-- round it on both faces, held by bolts
			r:piece(function(q: R)
				casing(q, 3, 3, r.c2, { bottom = true })
				local k = 0.95
				for _, c in { { -1.45, E, 1, 1 }, { 1.45, E, -1, 1 }, { -1.45, 3 - E, 1, -1 }, { 1.45, 3 - E, -1, -1 } } do
					local x, y, sx, sy = c[1], c[2], c[3], c[4]
					q:tri(
						Vector3.new(x, y, 0),
						Vector3.new(x + sx * k, y, 0),
						Vector3.new(x, y + sy * k, 0),
						LZ * 2 - 0.04,
						r.c2,
						"Wood"
					)
				end
			end)
			r:glass(-1.42, 0.08, -0.03, 1.42, 2.92, 0.03)
			r:piece(function(q: R)
				for _, s in { -1, 1 } do
					for k = 0, 3 do
						local a = k * math.pi / 2 + math.pi / 4
						q:box(
							math.cos(a) * 1.38,
							1.5 + math.sin(a) * 1.38,
							s * 0.37,
							0.12,
							0.12,
							0.04,
							shade(r.c1, 0.8),
							"Metal"
						)
					end
				end
				local n = 10
				for _, s in { -1, 1 } do
					for i = 0, n - 1 do
						local a1 = i / n * math.pi * 2
						local a2 = (i + 1) / n * math.pi * 2
						local rad = 1.38
						q:beam(
							Vector3.new(math.cos(a1) * rad, 1.5 + math.sin(a1) * rad, s * 0.29),
							Vector3.new(math.cos(a2) * rad, 1.5 + math.sin(a2) * rad, s * 0.29),
							0.14,
							0.2,
							r.c1,
							"Metal"
						)
					end
				end
			end)
		end,
	},
	{
		id = "win_bay",
		name = "Bay window",
		cat = "windows",
		price = 250,
		place = "opening",
		size = Vector3.new(6.8, 7.4, 4.4),
		opening = { w = 6, h = 6, sill = 2 },
		c1 = "FAF6EC",
		c2 = "B8505A",
		build = function(r: R)
			-- the hole's own trim inside, then a bay with slanted sides standing out of the wall on
			-- the side chosen: a seat board, three panes and a little roof of its own (c2)
			local W, F = 3, 1.5 -- half the hole's width, half the front pane's
			local Z0, Z1 = 0.3, 1.9 -- the wall's face, the bay's front
			r:piece(function(q: R)
				casing(q, 6, 6, r.c1, { faces = { -1 }, foot = 0.06 })
				q:block(-W - 0.05, -0.3, -0.55, W + 0.05, 0.06, Z0 + 0.02, r.c1, "Wood")
				q:block(-F, -0.3, Z0, F, 0.06, Z1, r.c1, "Wood")
				q:block(-F + 0.2, -0.55, Z0, F - 0.2, -0.3, Z1 - 0.35, shade(r.c1, 0.88), "Wood")
				q:block(-F, 4.2, Z1 - 0.26, F, 4.36, Z1 - 0.04, r.c1, "Wood")
				q:block(-0.07, 0.06, Z1 - 0.24, 0.07, 4.2, Z1 - 0.06, r.c1, "Wood")
				q:block(-F - 0.1, 5.8, Z1 - 0.3, F + 0.1, 6.3, Z1 + 0.05, r.c1, "Wood")
				for _, sx in { -1, 1 } do
					q:tri(
						Vector3.new(sx * F, -0.12, Z0),
						Vector3.new(sx * W, -0.12, Z0),
						Vector3.new(sx * F, -0.12, Z1),
						0.36,
						r.c1,
						"Wood"
					)
					q:block(sx * F - 0.14, 0.06, Z1 - 0.28, sx * F + 0.14, 5.8, Z1, r.c1, "Wood")
					local along = Vector3.new(sx * (F - W), 0, Z1 - Z0)
					local len = along.Magnitude
					local side =
						CFrame.fromMatrix(Vector3.new(sx * (W + F) / 2, 0, (Z0 + Z1) / 2), along.Unit, Vector3.yAxis)
					q:boxAt(side * CFrame.new(0, 4.28, 0), len, 0.16, 0.2, r.c1, "Wood")
					q:boxAt(side * CFrame.new(0, 6.05, 0), len + 0.25, 0.5, 0.3, r.c1, "Wood")
				end
			end)
			local front = r:block(-F + 0.14, 0.1, Z1 - 0.18, F - 0.14, 5.76, Z1 - 0.12, C.Glass, "Glass")
			front.transp = 0.55
			for _, sx in { -1, 1 } do
				local along = Vector3.new(sx * (F - W), 0, Z1 - Z0)
				local len = along.Magnitude
				local side =
					CFrame.fromMatrix(Vector3.new(sx * (W + F) / 2, 0, (Z0 + Z1) / 2), along.Unit, Vector3.yAxis)
				local p = r:boxAt(side * CFrame.new(0, 2.93, 0), len - 0.1, 5.66, 0.06, C.Glass, "Glass")
				p.transp = 0.55
				r:tri(
					Vector3.new(sx * F, 7.4, Z0),
					Vector3.new(sx * (W + 0.25), 6.3, Z0),
					Vector3.new(sx * F, 6.3, Z1 + 0.25),
					0.2,
					shade(r.c2, 0.9),
					"ClayRoofTiles"
				)
			end
			slope(r, -F, 6.3, Z0, F, 7.4, Z1 + 0.25, r.c2, "ClayRoofTiles")
		end,
	},
	-- things that hang on the wall round a window --------------------------------------------
	{
		id = "shutters",
		name = "Shutters",
		cat = "windows",
		price = 40,
		place = "wall",
		size = Vector3.new(8.2, 4.4, 0.4),
		c1 = "5E8E5A",
		c2 = "3D6650",
		build = function(r: R)
			-- a pair of louvred shutters either side of a window four studs wide: c1 the frames,
			-- c2 the slats, on iron hinges and with a hook at the foot
			for _, sx in { -1, 1 } do
				local a, b = math.min(sx * 2.4, sx * 4.05), math.max(sx * 2.4, sx * 4.05)
				r:piece(function(q: R)
					shutter(q, a, b, 0, 4.3, 0.04, r.c1, r.c2)
				end)
			end
			r:piece(function(q: R)
				for _, sx in { -1, 1 } do
					for _, y in { 0.7, 3.6 } do
						q:box(sx * 2.5, y, 0.26, 0.4, 0.16, 0.08, IRON, "Metal")
					end
					q:box(sx * 3.25, 0.15, 0.2, 0.3, 0.1, 0.16, IRON, "Metal")
				end
			end)
		end,
	},
	{
		id = "window_box",
		name = "Window box",
		cat = "windows",
		price = 35,
		place = "wall",
		size = Vector3.new(4.6, 2.1, 1.2),
		c1 = "8E6440",
		c2 = "D9707F",
		tags = { "plant" },
		build = function(r: R)
			-- a box of boards on two brackets, to hang under a window: c1 the box, c2 the flowers,
			-- with leaves trailing over its front
			r:piece(function(q: R)
				for _, x in { -1.6, 1.6 } do
					bracket(q, x, 0.5, 0.42, 0.8, shade(r.c1, 0.75), "WoodPlanks")
				end
				q:block(-2.16, 0.5, 0.02, 2.16, 0.76, 1.02, shade(r.c1, 0.95), "WoodPlanks")
				q:block(-2.16, 0.76, 0.02, 2.16, 0.98, 1.02, r.c1, "WoodPlanks")
				q:block(-2.16, 0.98, 0.02, 2.16, 1.2, 1.02, shade(r.c1, 0.95), "WoodPlanks")
				-- a rim round the top, and the earth inside it
				q:block(-2.28, 1.2, 0.86, 2.28, 1.32, 1.1, shade(r.c1, 0.85), "WoodPlanks")
				q:block(-2.28, 1.2, 0, 2.28, 1.32, 0.16, shade(r.c1, 0.85), "WoodPlanks")
				for _, x in { -2.2, 2.2 } do
					q:block(x - 0.08, 1.2, 0.16, x + 0.08, 1.32, 0.86, shade(r.c1, 0.85), "WoodPlanks")
					q:block(x * 1.01 - 0.06, 0.46, 0.06, x * 1.01 + 0.06, 1.2, 1.06, shade(r.c1, 0.82), "WoodPlanks")
				end
				q:block(-2.12, 1.2, 0.16, 2.12, 1.26, 0.86, C.Soil, "WoodPlanks")
			end)
			planting(r, -1.95, 1.95, 1.3, 0.22, 0.82, { r.c2, C.White, r.c2, C.Yellow, r.c2, C.White })
		end,
	},
	{
		id = "window_hood",
		name = "Window hood",
		cat = "windows",
		price = 15,
		place = "wall",
		size = Vector3.new(5, 1, 1),
		c1 = "FAF6EC",
		c2 = "B8505A",
		build = function(r: R)
			-- a little pent roof on two shaped brackets, to hang over a window or a door: c1 the
			-- woodwork (a wall plate, the brackets and a fascia), c2 the roof and its rows of tiles
			r:piece(function(q: R)
				q:block(-2.3, 0.1, 0.02, 2.3, 0.6, 0.14, r.c1, "Wood")
				for _, x in { -2.05, 2.05 } do
					bracket(q, x, 0.5, 0.36, 0.62, r.c1)
				end
				q:block(-2.45, 0.42, 0.74, 2.45, 0.62, 0.84, r.c1, "Wood")
			end)
			slope(r, -2.5, 0.6, 0.02, 2.5, 1, 0.92, r.c2, "ClayRoofTiles")
			local angle = math.atan2(0.4, 0.9)
			r:piece(function(q: R)
				q:block(-2.53, 0.94, 0.06, 2.53, 1.0, 0.14, shade(r.c2, 0.85), "ClayRoofTiles")
				for i, t in { 0.3, 0.62 } do
					local z = 0.92 - t * 0.9
					local y = 0.6 + t * 0.4
					q:boxAt(
						CFrame.new(0, y + 0.03, z) * CFrame.Angles(angle, 0, 0),
						4.96,
						0.05,
						0.1,
						shade(r.c2, if i == 1 then 0.9 else 0.94),
						"ClayRoofTiles"
					)
				end
			end)
		end,
	},
	{
		id = "window_attic",
		name = "Attic window",
		cat = "windows",
		price = 60,
		place = "floor",
		size = Vector3.new(4, 4.8, 1.4),
		c1 = "FAF6EC",
		c2 = "5E8E5A",
		build = function(r: R)
			-- A window for a gable end, where a wall's own windows can't go: stand it on the
			-- floor above, the middle of its footprint on the wall's line and its back to the
			-- gable. It cuts no hole, so the glass is dark. c1 the frame, c2 its two shutters.
			local z0 = 0.3 -- the gable's face
			local y0 = 1.4 -- the sill, above the top of the wall below
			local pane = r:block(-1.2, y0, z0, 1.2, y0 + 3, z0 + 0.06, Color3.fromRGB(72, 98, 122), "Glass")
			pane.collide = false
			r:piece(function(q: R)
				q:block(-1.48, y0 - 0.22, z0, 1.48, y0, z0 + 0.42, r.c1, "Wood")
				q:block(-1.3, y0 - 0.5, z0, 1.3, y0 - 0.22, z0 + 0.12, r.c1, "Wood")
				q:block(-1.42, y0 + 3, z0, 1.42, y0 + 3.24, z0 + 0.3, r.c1, "Wood")
				q:block(-1.5, y0 + 3.24, z0, 1.5, y0 + 3.32, z0 + 0.36, r.c1, "Wood")
				for _, sx in { -1, 1 } do
					local x1, x2 = math.min(sx * 1.2, sx * 1.42), math.max(sx * 1.2, sx * 1.42)
					q:block(x1, y0, z0, x2, y0 + 3, z0 + 0.26, r.c1, "Wood")
				end
				q:block(-0.05, y0, z0 + 0.06, 0.05, y0 + 3, z0 + 0.16, r.c1, "Wood")
				q:block(-1.2, y0 + 1.45, z0 + 0.06, 1.2, y0 + 1.55, z0 + 0.16, r.c1, "Wood")
				q:block(-1.2, y0 + 2.95, z0 + 0.06, 1.2, y0 + 3, z0 + 0.2, r.c1, "Wood")
			end)
			r:piece(function(q: R)
				for _, sx in { -1, 1 } do
					local a, b = math.min(sx * 1.46, sx * 1.98), math.max(sx * 1.46, sx * 1.98)
					q:block(a, y0, z0, b, y0 + 3, z0 + 0.1, shade(r.c2, 0.8), "Wood")
					for i = 0, 3 do
						local y = y0 + 0.12 + i * 0.72
						q:block(
							a + 0.04,
							y,
							z0 + 0.1,
							b - 0.04,
							y + 0.6,
							z0 + 0.16,
							if i % 2 == 0 then r.c2 else shade(r.c2, 0.94),
							"Wood"
						)
					end
				end
			end)
		end,
	},
}

return items
