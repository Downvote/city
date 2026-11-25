--!strict
-- Pillars: columns and posts to hold up a porch roof or a balcony, or to stand on their own (the
-- user: "also, add pillars to building as well"). They are Build mode's Pillars tab and stand on
-- any floor or the ground. Each carries a style (Catalog.Styles). c1 paints the body, c2 the trim:
-- the base, the capital and the head, or what wraps the body (a rope, a rose, a stripe).
--
-- Heights. A storey is H from floor to floor. Under a floor above, the ceiling is CEIL over the
-- floor (Shapes.floor: the upper floor's slab and the plaster under it take the storey's top
-- stud); under a roof, the roof sits at H. So a full height pillar's capital ends at CEIL and a
-- plain head block runs on from there to TOP: hidden in the slab under a floor, the block the
-- beam sits on under a roof. TOP stops a tenth short of H, so the head never shows through the
-- floor above or flickers with it. The half height ones are gate piers, pedestals and posts.

local Recipe = require(script.Parent.Parent.Recipe)
local Tuning = require(script.Parent.Parent.Parent.Config.Tuning)
local Colors = require(script.Parent.Parent.Parent.Util.Colors)

local C = Recipe.Colors

type R = Recipe.Recipe
type Prim = Recipe.Prim

local H = Tuning.Plot.LevelHeight
local CEIL = H - 1
local TOP = H - 0.1

local function shade(c: Color3, k: number): Color3
	return Colors.shade(c, k)
end

-- Glows at night without a light of its own (when another part of the item already has one).
local function glowOnly(p: Prim)
	p.role = "glow"
end

-- A cylinder standing upright round (x, z) from y1 to y2.
local function drum(r: R, x: number, z: number, y1: number, y2: number, d: number, color: Color3, mat: string?): Prim
	return r:cyl(x, (y1 + y2) / 2, z, y2 - y1, d, "y", color, mat)
end

-- A square block round the upright through the middle, w across, from y1 to y2.
local function square(r: R, y1: number, y2: number, w: number, color: Color3, mat: string?): Prim
	return r:block(-w / 2, y1, -w / 2, w / 2, y2, w / 2, color, mat)
end

-- A box turned `yaw` about the upright through (x, z), w by d across, from y1 to y2.
local function turned(
	r: R,
	x: number,
	z: number,
	y1: number,
	y2: number,
	w: number,
	d: number,
	yaw: number,
	color: Color3,
	mat: string?
): Prim
	return r:boxAt(CFrame.new(x, (y1 + y2) / 2, z) * CFrame.Angles(0, yaw, 0), w, y2 - y1, d, color, mat)
end

-- A six sided prism round the upright through (x, z), its corners `rad` from the middle with two
-- of them on the x axis: three boxes a sixth of a turn apart (the first one square to the axes).
local function hex(r: R, x: number, z: number, y1: number, y2: number, rad: number, color: Color3, mat: string?)
	for k = 0, 2 do
		turned(r, x, z, y1, y2, rad, rad * math.sqrt(3), k * math.pi / 3, color, mat)
	end
end

-- A round rod from a to b (a cylinder laid along the line).
local function rod(r: R, a: Vector3, b: Vector3, d: number, color: Color3, mat: string?)
	local v = b - a
	local len = v.Magnitude
	if len < 1e-3 then
		return
	end
	local x = v / len
	local up = if math.abs(x.Y) > 0.99 then Vector3.zAxis else Vector3.yAxis
	local z = x:Cross(up).Unit
	local y = z:Cross(x).Unit
	r:add({
		shape = "Cylinder",
		cf = CFrame.fromMatrix((a + b) / 2, x, y, z),
		size = Vector3.new(len, d, d),
		color = color,
		mat = mat or "SmoothPlastic",
	})
end

-- A point on a helix round the upright: `a` radians round, at height y, `rad` out.
local function around(a: number, y: number, rad: number): Vector3
	return Vector3.new(math.cos(a) * rad, y, math.sin(a) * rad)
end

-- Beams i1..i2 of a band winding round the upright: `turns` times round from y1 to y2 in `n`
-- straight lengths, `rad` from the middle, starting `phase` round; each length is `w` deep (out
-- from the middle) and `h` across the band. Drawn on q, a piece's recipe, with a small block
-- square to the axes in the middle so the piece has one.
local function helix(
	q: R,
	i1: number,
	i2: number,
	n: number,
	y1: number,
	y2: number,
	turns: number,
	rad: number,
	phase: number,
	w: number,
	h: number,
	color: Color3,
	mat: string
)
	local ym = y1 + (y2 - y1) * (i1 + i2) / (2 * n)
	q:block(-0.05, ym - 0.05, -0.05, 0.05, ym + 0.05, 0.05, color, mat)
	for i = i1, i2 - 1 do
		local a1 = phase + turns * 2 * math.pi * i / n
		local a2 = phase + turns * 2 * math.pi * (i + 1) / n
		local p1 = around(a1, y1 + (y2 - y1) * i / n, rad)
		local p2 = around(a2, y1 + (y2 - y1) * (i + 1) / n, rad)
		-- each length runs a hair past both its ends, so the band has no notches at the joints
		local d = (p2 - p1).Unit * 0.03
		q:beam(p1 - d, p2 + d, w, h, color, mat)
	end
end

-- Pillar shapes in the plain old way: a fluted shaft is a few squares turned evenly about the
-- upright, so their corners stand as the ridges between the flutes.
local function fluted(q: R, y1: number, y2: number, d: number, n: number, color: Color3, mat: string)
	local s = d / math.sqrt(2)
	for k = 0, n - 1 do
		turned(q, 0, 0, y1, y2, s, s, k * (math.pi / 2) / n, color, mat)
	end
end

-- A post that tapers: four faces leaning in from `b` out (half its width) at y1 to `t` out at y2,
-- each `th` thick inside its outer face, round a core square to the axes.
local function taper(q: R, y1: number, y2: number, b: number, t: number, th: number, color: Color3, mat: string)
	q:block(-t + th, y1, -t + th, t - th, y2, t - th, shade(color, 0.9), mat)
	local function face(f: (number, number, number) -> Vector3)
		q:quad(f(-b, y1, b), f(b, y1, b), f(t, y2, t), f(-t, y2, t), th, color, mat)
	end
	-- (each face's middle lies half its thickness in from its outer face)
	local inB, inT = b - th / 2, t - th / 2
	face(function(u, y, _)
		local s = if y == y1 then inB else inT
		return Vector3.new(u, y, s)
	end)
	face(function(u, y, _)
		local s = if y == y1 then inB else inT
		return Vector3.new(-u, y, -s)
	end)
	face(function(u, y, _)
		local s = if y == y1 then inB else inT
		return Vector3.new(s, y, -u)
	end)
	face(function(u, y, _)
		local s = if y == y1 then inB else inT
		return Vector3.new(-s, y, u)
	end)
end

-- Letters and numbers for the toy blocks, as cells on a grid five across and five up:
-- { column from, row from, column to, row to }, rows counted from the bottom.
local GLYPHS: { [string]: { { number } } } = {
	A = { { 0, 0, 0, 3 }, { 4, 0, 4, 3 }, { 1, 4, 3, 4 }, { 1, 2, 3, 2 } },
	B = { { 0, 0, 0, 4 }, { 1, 4, 3, 4 }, { 1, 2, 3, 2 }, { 1, 0, 3, 0 }, { 4, 3, 4, 3 }, { 4, 1, 4, 1 } },
	C = { { 0, 1, 0, 3 }, { 1, 4, 4, 4 }, { 1, 0, 4, 0 } },
	E = { { 0, 0, 0, 4 }, { 1, 4, 4, 4 }, { 1, 2, 3, 2 }, { 1, 0, 4, 0 } },
	H = { { 0, 0, 0, 4 }, { 4, 0, 4, 4 }, { 1, 2, 3, 2 } },
	T = { { 0, 4, 4, 4 }, { 2, 0, 2, 3 } },
	["1"] = { { 2, 0, 2, 4 }, { 1, 3, 1, 3 }, { 1, 0, 3, 0 } },
	["2"] = { { 0, 4, 3, 4 }, { 4, 3, 4, 3 }, { 1, 2, 3, 2 }, { 0, 1, 0, 1 }, { 0, 0, 4, 0 } },
	["3"] = { { 0, 4, 3, 4 }, { 4, 3, 4, 3 }, { 1, 2, 3, 2 }, { 4, 1, 4, 1 }, { 0, 0, 3, 0 } },
	["4"] = { { 0, 2, 0, 4 }, { 3, 0, 3, 4 }, { 0, 2, 4, 2 } },
	["5"] = { { 0, 4, 4, 4 }, { 0, 3, 0, 3 }, { 0, 2, 3, 2 }, { 4, 1, 4, 1 }, { 0, 0, 3, 0 } },
	["7"] = { { 0, 4, 4, 4 }, { 4, 3, 4, 3 }, { 3, 2, 3, 2 }, { 2, 0, 2, 1 } },
}

-- The soft toy colours the blocks take turns with c1 and c2
local TOY_PINK = Color3.fromRGB(238, 164, 176)
local TOY_GREEN = Color3.fromRGB(150, 204, 162)

local PALE_STONE = Color3.fromRGB(214, 208, 198)
local SCI_DARK = Color3.fromRGB(70, 74, 84)
local ROSE_STEM = Color3.fromRGB(96, 104, 62)

-- One catalog entry (Build/Catalog explains the fields).
type Item = {
	id: string,
	name: string,
	cat: string,
	style: string,
	price: number,
	place: string,
	size: Vector3,
	c1: string,
	c2: string?,
	tags: { string }?,
	surface: number?,
	build: (r: R) -> (),
}

local items: { Item } = {
	-- Modern ---------------------------------------------------------------------------------------
	{
		id = "pillar_plain",
		name = "Plain column",
		cat = "pillars",
		style = "modern",
		price = 70,
		place = "floor",
		size = Vector3.new(2, H, 2),
		c1 = "F1EFEA",
		c2 = "B9B5AD",
		build = function(r: R)
			-- a plain round column (c1) from the floor to the ceiling, on a thin round plate (c2)
			-- with a dark reveal over it, and a matching plate where it meets the ceiling
			drum(r, 0, 0, 0, 0.12, 1.86, r.c2, "Metal")
			drum(r, 0, 0, 0.12, 0.2, 1.5, shade(r.c2, 0.55), "Metal")
			drum(r, 0, 0, 0.2, CEIL - 0.12, 1.6, r.c1, "Plaster")
			drum(r, 0, 0, CEIL - 0.12, CEIL, 1.86, r.c2, "Metal")
			drum(r, 0, 0, CEIL, TOP, 1.6, r.c1, "Plaster")
		end,
	},
	{
		id = "pillar_steel",
		name = "Steel column",
		cat = "pillars",
		style = "modern",
		price = 45,
		place = "floor",
		size = Vector3.new(1, H, 1),
		c1 = "3E3E44",
		c2 = "9EA2AA",
		build = function(r: R)
			-- a slim round steel column (c1) welded to a base plate (c2) with four gussets and
			-- bolted down, and the same at its head under a cap plate
			r:piece(function(q: R)
				q:block(-0.42, 0, -0.42, 0.42, 0.1, 0.42, r.c2, "Metal")
				q:block(-0.42, TOP - 0.1, -0.42, 0.42, TOP, 0.42, r.c2, "Metal")
				for _, y in { 0.1, TOP - 0.1 } do
					local up = if y < 1 then 1 else -1
					local tip = y + up * 0.42
					for _, s in { -1, 1 } do
						q:tri(
							Vector3.new(s * 0.22, y, 0),
							Vector3.new(s * 0.4, y, 0),
							Vector3.new(s * 0.22, tip, 0),
							0.05,
							r.c2,
							"Metal"
						)
						q:tri(
							Vector3.new(0, y, s * 0.22),
							Vector3.new(0, y, s * 0.4),
							Vector3.new(0, tip, s * 0.22),
							0.05,
							r.c2,
							"Metal"
						)
					end
				end
			end, true)
			drum(r, 0, 0, 0.1, TOP - 0.1, 0.46, r.c1, "Metal")
			r:piece(function(q: R)
				for _, sx in { -1, 1 } do
					for _, sz in { -1, 1 } do
						q:block(
							sx * 0.3 - 0.05,
							0.1,
							sz * 0.3 - 0.05,
							sx * 0.3 + 0.05,
							0.17,
							sz * 0.3 + 0.05,
							C.DarkMetal,
							"Metal"
						)
						q:block(
							sx * 0.3 - 0.025,
							0.17,
							sz * 0.3 - 0.025,
							sx * 0.3 + 0.025,
							0.21,
							sz * 0.3 + 0.025,
							C.DarkMetal,
							"Metal"
						)
					end
				end
			end)
		end,
	},
	{
		id = "pillar_concrete",
		name = "Concrete pillar",
		cat = "pillars",
		style = "modern",
		price = 70,
		place = "floor",
		size = Vector3.new(2, H, 2),
		c1 = "BEBBB4",
		c2 = "45454A",
		build = function(r: R)
			-- a cast concrete pillar (c1) that seems to float: a dark shadow gap (c2) at the floor
			-- and another at the ceiling, rows of tie holes where the formwork was held, and the
			-- line where one pour met the next
			r:piece(function(q: R)
				square(q, 0, 0.14, 1.32, r.c2, "Concrete")
				square(q, CEIL - 0.14, CEIL, 1.32, r.c2, "Concrete")
			end, true)
			r:piece(function(q: R)
				square(q, 0.14, CEIL - 0.14, 1.6, r.c1, "Concrete")
				square(q, CEIL, TOP, 1.6, r.c1, "Concrete")
				square(q, 5.4, 5.44, 1.66, shade(r.c1, 0.9), "Concrete")
			end, true)
			-- (two rows of ties to each pour, a piece each)
			for _, rows in { { 1.8, 3.9 }, { 7.0, 9.1 } } do
				r:piece(function(q: R)
					local hole = shade(r.c1, 0.55)
					for _, y in rows do
						for _, u in { -0.42, 0.42 } do
							q:block(u - 0.05, y - 0.05, 0.8, u + 0.05, y + 0.05, 0.83, hole, "Concrete")
							q:block(u - 0.05, y - 0.05, -0.83, u + 0.05, y + 0.05, -0.8, hole, "Concrete")
							q:block(0.8, y - 0.05, u - 0.05, 0.83, y + 0.05, u + 0.05, hole, "Concrete")
							q:block(-0.83, y - 0.05, u - 0.05, -0.8, y + 0.05, u + 0.05, hole, "Concrete")
						end
					end
				end)
			end
		end,
	},
	{
		id = "pillar_slats",
		name = "Slatted column",
		cat = "pillars",
		style = "modern",
		price = 90,
		place = "floor",
		size = Vector3.new(2, H, 2),
		c1 = "C9A27A",
		c2 = "3E3E44",
		build = function(r: R)
			-- a square column clad in oak slats (c1) with dark gaps between them over a dark core
			-- (c2), on a dark plinth with a band at the top
			r:piece(function(q: R)
				square(q, 0, CEIL, 1.4, r.c2, "Wood")
				square(q, 0, 0.3, 1.72, r.c2, "Wood")
				square(q, CEIL - 0.3, CEIL, 1.72, r.c2, "Wood")
				square(q, CEIL, TOP, 1.6, r.c2, "Wood")
			end, true)
			r:piece(function(q: R)
				local y1, y2 = 0.3, CEIL - 0.3
				for i = 0, 4 do
					local u = -0.56 + i * 0.28
					local k = if i % 2 == 0 then 1 else 0.95
					q:block(u - 0.08, y1, 0.7, u + 0.08, y2, 0.82, shade(r.c1, k), "Wood")
					q:block(-u - 0.08, y1, -0.82, -u + 0.08, y2, -0.7, shade(r.c1, k), "Wood")
					q:block(0.7, y1, -u - 0.08, 0.82, y2, -u + 0.08, shade(r.c1, k), "Wood")
					q:block(-0.82, y1, u - 0.08, -0.7, y2, u + 0.08, shade(r.c1, k), "Wood")
				end
				for _, sx in { -1, 1 } do
					for _, sz in { -1, 1 } do
						q:block(
							sx * 0.76 - 0.08,
							y1,
							sz * 0.76 - 0.08,
							sx * 0.76 + 0.08,
							y2,
							sz * 0.76 + 0.08,
							r.c1,
							"Wood"
						)
					end
				end
			end, true)
		end,
	},

	-- Cozy -----------------------------------------------------------------------------------------
	{
		id = "pillar_boxed",
		name = "Square pillar",
		cat = "pillars",
		style = "cozy",
		price = 80,
		place = "floor",
		size = Vector3.new(2, H, 2),
		c1 = "F0EBE0",
		c2 = "DDD3C2",
		build = function(r: R)
			-- a boxed column as on an old porch: a plinth block, the shaft (c1) with a raised
			-- frame round a sunk panel on each face, and a cap (c2) stepped out to the ceiling
			r:piece(function(q: R)
				square(q, 0, 0.9, 1.8, r.c2, "Wood")
				square(q, 0.9, 1.04, 1.66, shade(r.c2, 1.04), "Wood")
				square(q, CEIL - 0.74, CEIL - 0.6, 1.62, r.c2, "Wood")
				square(q, CEIL - 0.6, CEIL - 0.32, 1.72, shade(r.c2, 1.04), "Wood")
				square(q, CEIL - 0.32, CEIL, 1.86, r.c2, "Wood")
				square(q, CEIL, TOP, 1.72, shade(r.c2, 0.96), "Wood")
			end, true)
			r:piece(function(q: R)
				local y1, y2 = 1.04, CEIL - 0.74
				square(q, y1, y2, 1.5, r.c1, "Wood")
				-- the frame on each face: two stiles and a rail at each end, 0.04 proud
				local trim = shade(r.c1, 1.03)
				for _, s in { -1, 1 } do
					for _, u in { -0.55, 0.55 } do
						q:block(u - 0.1, y1 + 0.3, s * 0.75 - 0.02, u + 0.1, y2 - 0.3, s * 0.75 + 0.04, trim, "Wood")
						q:block(s * 0.75 - 0.02, y1 + 0.3, u - 0.1, s * 0.75 + 0.04, y2 - 0.3, u + 0.1, trim, "Wood")
					end
					for _, y in { y1 + 0.3, y2 - 0.5 } do
						q:block(-0.45, y, s * 0.75 - 0.02, 0.45, y + 0.2, s * 0.75 + 0.04, trim, "Wood")
						q:block(s * 0.75 - 0.02, y, -0.45, s * 0.75 + 0.04, y + 0.2, 0.45, trim, "Wood")
					end
				end
			end, true)
		end,
	},
	{
		id = "pillar_turned",
		name = "Turned post",
		cat = "pillars",
		style = "cozy",
		price = 60,
		place = "floor",
		size = Vector3.new(1, H, 1),
		c1 = "F4F0E6",
		c2 = "E2DACB",
		build = function(r: R)
			-- a white porch post turned on a lathe: square at the foot and the top (c1), where a
			-- rail or a beam would meet it, and between them a vase, rings, a long taper and a
			-- bead, under a cap (c2) and the head
			r:piece(function(q: R)
				square(q, 0, 2.2, 0.8, r.c1, "Wood")
				square(q, 2.2, 2.3, 0.86, r.c2, "Wood")
				square(q, 8.5, 8.6, 0.86, r.c2, "Wood")
				square(q, 8.6, CEIL - 0.5, 0.8, r.c1, "Wood")
				square(q, CEIL - 0.5, CEIL - 0.36, 0.88, r.c2, "Wood")
				square(q, CEIL - 0.36, CEIL, 0.98, r.c2, "Wood")
				square(q, CEIL, TOP, 0.9, shade(r.c2, 0.96), "Wood")
			end, true)
			drum(r, 0, 0, 2.3, 2.46, 0.6, r.c1, "Wood")
			drum(r, 0, 0, 2.46, 2.58, 0.76, r.c1, "Wood")
			r:lump(CFrame.new(0, 3.3, 0), 0.8, 1.6, 0.8, r.c1, "Wood")
			drum(r, 0, 0, 3.9, 4.5, 0.4, r.c1, "Wood")
			drum(r, 0, 0, 4.5, 4.62, 0.68, r.c1, "Wood")
			drum(r, 0, 0, 4.62, 6.2, 0.54, r.c1, "Wood")
			drum(r, 0, 0, 6.2, 7.5, 0.46, r.c1, "Wood")
			r:ball(0, 7.78, 0, 0.62, r.c1, "Wood")
			drum(r, 0, 0, 8.04, 8.22, 0.44, r.c1, "Wood")
			drum(r, 0, 0, 8.22, 8.34, 0.74, r.c1, "Wood")
			drum(r, 0, 0, 8.34, 8.5, 0.6, r.c1, "Wood")
		end,
	},
	{
		id = "pillar_carved",
		name = "Carved post",
		cat = "pillars",
		style = "cozy",
		price = 90,
		place = "floor",
		size = Vector3.new(1, H, 1),
		c1 = "A87A52",
		c2 = "7A5236",
		build = function(r: R)
			-- a square post carved by hand: a moulded foot (c2), the shaft (c1) with bands of beads
			-- low and high, a lozenge with a smaller one above and below on every face, and a
			-- bracket cap (c2) under the head
			r:piece(function(q: R)
				square(q, 0, 0.7, 1, r.c2, "Wood")
				square(q, 0.7, 0.86, 0.88, shade(r.c2, 1.1), "Wood")
				square(q, CEIL - 0.56, CEIL - 0.36, 0.88, shade(r.c2, 1.1), "Wood")
				square(q, CEIL - 0.36, CEIL, 1, r.c2, "Wood")
				square(q, CEIL, TOP, 0.9, shade(r.c2, 0.95), "Wood")
			end, true)
			r:piece(function(q: R)
				-- the shaft, its corners taken off between the bands and stopped square at them
				square(q, 0.86, 2.7, 0.66, r.c1, "Wood")
				q:block(-0.33, 2.7, -0.25, 0.33, 8.7, 0.25, r.c1, "Wood")
				q:block(-0.25, 2.7, -0.33, 0.25, 8.7, 0.33, r.c1, "Wood")
				square(q, 8.7, CEIL - 0.56, 0.66, r.c1, "Wood")
				local bead = shade(r.c1, 0.86)
				for _, y in { 1.9, 2.14, 2.38, 8.86, 9.1, 9.34 } do
					square(q, y, y + 0.14, 0.74, bead, "Wood")
				end
				local carve = shade(r.c1, 1.12)
				for _, l in { { 5.6, 0.34 }, { 4.5, 0.22 }, { 6.7, 0.22 } } do
					local y, s = l[1], l[2]
					local f = CFrame.Angles(0, 0, math.pi / 4)
					local g = CFrame.Angles(math.pi / 4, 0, 0)
					q:boxAt(CFrame.new(0, y, 0.34) * f, s, s, 0.06, carve, "Wood")
					q:boxAt(CFrame.new(0, y, -0.34) * f, s, s, 0.06, carve, "Wood")
					q:boxAt(CFrame.new(0.34, y, 0) * g, 0.06, s, s, carve, "Wood")
					q:boxAt(CFrame.new(-0.34, y, 0) * g, 0.06, s, s, carve, "Wood")
				end
			end, true)
		end,
	},
	{
		id = "pillar_porch_pier",
		name = "Porch pier",
		cat = "pillars",
		style = "cozy",
		price = 120,
		place = "floor",
		size = Vector3.new(2, H, 2),
		c1 = "F2EEE4",
		c2 = "B06A52",
		build = function(r: R)
			-- a porch column of the bungalow kind: a brick pier (c2) as high as a half wall, with a
			-- stone cap, and on it a wide post (c1) that tapers to the top, with a base trim, a
			-- cap and the head
			r:piece(function(q: R)
				square(q, 0, 0.3, 1.94, shade(r.c2, 0.86), "Brick")
				square(q, 0.3, 3.72, 1.82, r.c2, "Brick")
				square(q, 1.3, 1.5, 1.88, shade(r.c2, 0.9), "Brick")
			end, true)
			r:block(-1, 3.72, -1, 1, 4, 1, PALE_STONE, "Concrete")
			r:piece(function(q: R)
				square(q, 4, 4.32, 1.4, shade(r.c1, 0.97), "Wood")
				square(q, 4.32, 4.44, 1.3, r.c1, "Wood")
				taper(q, 4.44, CEIL - 0.7, 0.6, 0.44, 0.1, r.c1, "Wood")
				square(q, CEIL - 0.7, CEIL - 0.52, 1.02, shade(r.c1, 0.97), "Wood")
				square(q, CEIL - 0.52, CEIL, 1.24, r.c1, "Wood")
				square(q, CEIL, TOP, 1.1, shade(r.c1, 0.95), "Wood")
			end, true)
		end,
	},
	{
		id = "pillar_lamp",
		name = "Lamp column",
		cat = "pillars",
		style = "cozy",
		price = 110,
		place = "floor",
		size = Vector3.new(2, H, 2),
		c1 = "E9E1D2",
		c2 = "C2B39A",
		tags = { "light" },
		build = function(r: R)
			-- a plastered column (c1) on a stone base, capped (c2), with an iron lantern hung
			-- from a bracket on its front that lights up after dark
			r:piece(function(q: R)
				square(q, 0, 0.6, 1.5, r.c2, "Limestone")
				square(q, 0.6, 0.76, 1.36, shade(r.c2, 1.05), "Limestone")
				square(q, CEIL - 0.6, CEIL - 0.44, 1.36, shade(r.c2, 1.05), "Limestone")
				square(q, CEIL - 0.44, CEIL, 1.5, r.c2, "Limestone")
				square(q, CEIL, TOP, 1.4, shade(r.c2, 0.95), "Limestone")
			end, true)
			square(r, 0.76, CEIL - 0.6, 1.1, r.c1, "Plaster")
			-- the bracket: a back plate on the column, an arm out with a strut under it, a hook
			local z0, zl, y0 = 0.55, 0.8, 6.3 -- the column's face, the lantern's middle, its foot
			local hw, ht = 0.2, 0.74 -- the lantern's half width and its height to the top plate
			local iron = C.DarkMetal
			r:piece(function(q: R)
				q:block(-0.22, y0 + 0.5, z0, 0.22, y0 + 1.7, z0 + 0.06, iron, "Metal")
				q:block(-0.04, y0 + 1.36, z0 + 0.06, 0.04, y0 + 1.44, zl + 0.04, iron, "Metal")
				q:beam(
					Vector3.new(0, y0 + 0.9, z0 + 0.06),
					Vector3.new(0, y0 + 1.38, zl - 0.06),
					0.06,
					0.06,
					iron,
					"Metal"
				)
				q:block(-0.02, y0 + ht + 0.4, zl - 0.02, 0.02, y0 + 1.36, zl + 0.02, iron, "Metal")
				-- the lantern: a foot plate, four corner bars, a top plate, a drop under it
				q:block(-hw, y0, zl - hw, hw, y0 + 0.06, zl + hw, iron, "Metal")
				for _, sx in { -1, 1 } do
					for _, sz in { -1, 1 } do
						local x, z = sx * (hw - 0.025), zl + sz * (hw - 0.025)
						q:block(x - 0.025, y0 + 0.06, z - 0.025, x + 0.025, y0 + ht, z + 0.025, iron, "Metal")
					end
				end
				q:block(-hw - 0.01, y0 + ht, zl - hw - 0.01, hw + 0.01, y0 + ht + 0.06, zl + hw + 0.01, iron, "Metal")
				q:block(-0.04, y0 - 0.12, zl - 0.04, 0.04, y0, zl + 0.04, iron, "Metal")
			end)
			r:cone(0, y0 + ht + 0.06 + 0.17, zl, 0.34, 0.4, iron, "Metal")
			r:ball(0, y0 + ht + 0.4, zl, 0.1, iron, "Metal")
			r:glass(-hw + 0.04, y0 + 0.06, zl - hw + 0.04, hw - 0.04, y0 + ht, zl + hw - 0.04)
			r:cyl(0, y0 + 0.16, zl, 0.2, 0.14, "y", C.Cream, "SmoothPlastic")
			local flame = r:ball(0, y0 + 0.36, zl, 0.16, C.Warm, "SmoothPlastic")
			r:glow(flame, 14, 1.1)
		end,
	},

	-- Fancy ----------------------------------------------------------------------------------------
	{
		id = "pillar_tuscan",
		name = "Tuscan column",
		cat = "pillars",
		style = "fancy",
		price = 120,
		place = "floor",
		size = Vector3.new(2, H, 2),
		c1 = "EDE6D8",
		c2 = "DCD2C0",
		build = function(r: R)
			-- the plainest of the old orders: a square plinth, one roll, a smooth shaft (c1), a
			-- ring and a neck, a flared cushion, and a square abacus (c2) up to the ceiling
			r:piece(function(q: R)
				square(q, 0, 0.5, 2, r.c2, "Limestone")
				square(q, CEIL - 0.42, CEIL, 1.96, r.c2, "Limestone")
				square(q, CEIL, TOP, 1.8, shade(r.c2, 0.96), "Limestone")
			end, true)
			drum(r, 0, 0, 0.5, 0.82, 1.82, r.c2, "Limestone")
			drum(r, 0, 0, 0.82, 0.94, 1.58, r.c2, "Limestone")
			drum(r, 0, 0, 0.94, 9.7, 1.46, r.c1, "Limestone")
			drum(r, 0, 0, 9.7, 9.88, 1.58, r.c2, "Limestone")
			drum(r, 0, 0, 9.88, 10.4, 1.42, r.c1, "Limestone")
			-- the cushion: a cone stood on its point, rising out of the neck
			r:add({
				shape = "Cone",
				cf = CFrame.new(0, CEIL - 0.42 - 0.45, 0) * CFrame.Angles(math.pi, 0, 0),
				size = Vector3.new(1.92, 0.9, 1.92),
				color = r.c2,
				mat = "Limestone",
			})
		end,
	},
	{
		id = "pillar_fluted",
		name = "Fluted column",
		cat = "pillars",
		style = "fancy",
		price = 160,
		place = "floor",
		size = Vector3.new(2, H, 2),
		c1 = "F2EEE6",
		c2 = "E2D8C6",
		build = function(r: R)
			-- a column after the old temples: a square plinth, a base of two rolls with a hollow
			-- between, a shaft fluted all round (c1), a ring, a capital (c2) with a scroll at each
			-- side and an eye in each scroll, and the abacus up to the ceiling
			r:piece(function(q: R)
				square(q, 0, 0.4, 2, r.c2, "Marble")
				square(q, CEIL - 0.3, CEIL, 1.94, r.c2, "Marble")
				square(q, CEIL, TOP, 1.8, shade(r.c2, 0.96), "Marble")
				q:block(-0.64, CEIL - 0.95, -0.7, 0.64, CEIL - 0.3, 0.7, r.c2, "Marble")
			end, true)
			drum(r, 0, 0, 0.4, 0.64, 1.84, r.c2, "Marble")
			drum(r, 0, 0, 0.64, 0.76, 1.54, r.c2, "Marble")
			drum(r, 0, 0, 0.76, 0.96, 1.68, r.c2, "Marble")
			drum(r, 0, 0, 0.96, 1.06, 1.52, r.c1, "Marble")
			r:piece(function(q: R)
				fluted(q, 1.06, 9.7, 1.46, 6, r.c1, "Marble")
			end, true)
			drum(r, 0, 0, 9.7, 9.86, 1.58, r.c2, "Marble")
			drum(r, 0, 0, 9.86, CEIL - 0.95, 1.62, r.c2, "Marble")
			for _, sx in { -1, 1 } do
				r:cyl(sx * 0.64, CEIL - 0.72, 0, 1.4, 0.7, "z", r.c2, "Marble")
				r:cyl(sx * 0.64, CEIL - 0.72, 0, 1.46, 0.3, "z", shade(r.c2, 0.88), "Marble")
			end
		end,
	},
	{
		id = "pillar_twisted",
		name = "Twisted column",
		cat = "pillars",
		style = "fancy",
		price = 180,
		place = "floor",
		size = Vector3.new(2, H, 2),
		c1 = "E8DFD0",
		c2 = "D4BC86",
		build = function(r: R)
			-- a barley twist: two strands (c1) winding round each other up the shaft; under them a
			-- plinth and a roll, over them a ring, a bell with leaves curling out round it and the
			-- abacus (c2)
			r:piece(function(q: R)
				square(q, 0, 0.45, 2, r.c1, "Marble")
				square(q, CEIL - 0.36, CEIL, 1.96, r.c2, "Marble")
				square(q, CEIL, TOP, 1.8, shade(r.c2, 0.95), "Marble")
			end, true)
			drum(r, 0, 0, 0.45, 0.74, 1.78, r.c2, "Marble")
			drum(r, 0, 0, 0.74, 0.9, 1.4, r.c1, "Marble")
			-- the shaft: two strands winding round each other about a slim core, two and a half
			-- times round, each strand in three pieces
			drum(r, 0, 0, 0.9, 9.6, 0.74, shade(r.c1, 0.9), "Marble")
			local n = 60
			for strand = 0, 1 do
				for third = 0, 2 do
					r:piece(function(q: R)
						helix(
							q,
							third * 20,
							third * 20 + 20,
							n,
							0.9,
							9.6,
							2.5,
							0.4,
							strand * math.pi,
							0.44,
							0.44,
							r.c1,
							"Marble"
						)
					end, true)
				end
			end
			drum(r, 0, 0, 9.6, 9.76, 1.5, r.c2, "Marble")
			drum(r, 0, 0, 9.76, CEIL - 0.36, 1.2, r.c2, "Marble")
			r:piece(function(q: R)
				q:block(-0.4, 9.76, -0.4, 0.4, 10.0, 0.4, r.c2, "Marble")
				for k = 0, 7 do
					local a = k * math.pi / 4 + math.pi / 8
					q:boxAt(
						CFrame.new(math.cos(a) * 0.64, 10.08, math.sin(a) * 0.64)
							* CFrame.Angles(0, math.pi / 2 - a, 0)
							* CFrame.Angles(0.45, 0, 0),
						0.46,
						0.66,
						0.1,
						r.c2,
						"Marble"
					)
				end
			end)
		end,
	},
	{
		id = "pillar_gate",
		name = "Gate pier",
		cat = "pillars",
		style = "fancy",
		price = 90,
		place = "floor",
		size = Vector3.new(2, 6.4, 2),
		c1 = "D8D0C0",
		c2 = "ECE6DA",
		build = function(r: R)
			-- a pier for the end of a wall or either side of a gate: a plinth, a shaft of stone
			-- in courses (c1) with every other one standing proud, a moulded cap (c2), a neck and
			-- a ball on top
			r:piece(function(q: R)
				square(q, 0, 0.6, 2, shade(r.c1, 0.9), "Limestone")
				for i = 1, 5 do
					local y = 0.6 + (i - 1) * 0.74
					local proud = i % 2 == 1
					square(
						q,
						y,
						y + 0.74,
						if proud then 1.84 else 1.74,
						shade(r.c1, if proud then 1 else 0.95),
						"Limestone"
					)
				end
			end, true)
			r:piece(function(q: R)
				square(q, 4.3, 4.46, 1.92, r.c2, "Limestone")
				square(q, 4.46, 4.74, 2, r.c2, "Limestone")
				square(q, 4.74, 4.9, 1.6, shade(r.c2, 0.95), "Limestone")
			end, true)
			drum(r, 0, 0, 4.9, 5.06, 0.9, r.c2, "Limestone")
			drum(r, 0, 0, 5.06, 5.24, 0.5, r.c2, "Limestone")
			r:ball(0, 5.79, 0, 1.2, r.c2, "Limestone")
		end,
	},
	{
		id = "pillar_pedestal",
		name = "Pedestal",
		cat = "pillars",
		style = "fancy",
		price = 60,
		place = "floor",
		size = Vector3.new(2, 3.6, 2),
		c1 = "F0ECE4",
		c2 = "D8CDB8",
		surface = 3.6,
		build = function(r: R)
			-- a short pedestal for a vase or a bust: a plinth and a moulding (c2), the die (c1)
			-- with a raised panel on each face, a cornice and a flat top to stand things on
			r:piece(function(q: R)
				square(q, 0, 0.3, 2, r.c2, "Marble")
				square(q, 0.3, 0.48, 1.84, shade(r.c2, 1.04), "Marble")
				square(q, 0.48, 2.92, 1.6, r.c1, "Marble")
				local panel = shade(r.c1, 0.96)
				q:block(-0.5, 0.8, 0.8, 0.5, 2.6, 0.84, panel, "Marble")
				q:block(-0.5, 0.8, -0.84, 0.5, 2.6, -0.8, panel, "Marble")
				q:block(0.8, 0.8, -0.5, 0.84, 2.6, 0.5, panel, "Marble")
				q:block(-0.84, 0.8, -0.5, -0.8, 2.6, 0.5, panel, "Marble")
				square(q, 2.92, 3.1, 1.84, shade(r.c2, 1.04), "Marble")
				square(q, 3.1, 3.36, 2, r.c2, "Marble")
				square(q, 3.36, 3.6, 1.92, r.c1, "Marble")
			end, true)
		end,
	},

	-- Rustic ---------------------------------------------------------------------------------------
	{
		id = "pillar_brick",
		name = "Brick pier",
		cat = "pillars",
		style = "rustic",
		price = 100,
		place = "floor",
		size = Vector3.new(2, H, 2),
		c1 = "B0644E",
		c2 = "D8D2C6",
		build = function(r: R)
			-- a brick pier (c1) on a stone footing: a plinth a little wider, two bands of bricks
			-- on end, the top stepped out in two courses under a stone cap (c2) at the ceiling
			r:piece(function(q: R)
				square(q, 0, 0.45, 2, r.c2, "Concrete")
				square(q, CEIL - 0.5, CEIL, 2, r.c2, "Concrete")
				square(q, CEIL, TOP, 1.88, shade(r.c2, 0.95), "Concrete")
			end, true)
			r:piece(function(q: R)
				square(q, 0.45, 1.4, 1.88, shade(r.c1, 0.92), "Brick")
				square(q, 1.4, CEIL - 1.0, 1.72, r.c1, "Brick")
				for _, y in { 3.9, 7.0 } do
					square(q, y, y + 0.32, 1.8, shade(r.c1, 0.88), "Brick")
				end
				square(q, CEIL - 1.0, CEIL - 0.76, 1.8, shade(r.c1, 0.96), "Brick")
				square(q, CEIL - 0.76, CEIL - 0.5, 1.88, shade(r.c1, 0.9), "Brick")
			end, true)
		end,
	},
	{
		id = "pillar_stone",
		name = "Stone pillar",
		cat = "pillars",
		style = "rustic",
		price = 110,
		place = "floor",
		size = Vector3.new(2, H, 2),
		c1 = "BDB7AA",
		c2 = "A39E93",
		build = function(r: R)
			-- a pillar of dressed stones (c1) in courses, two to a course and laid the other way
			-- from the course under, each a touch different in size and shade, deep mortar joints
			-- between them, on a footing stone with a big cap stone (c2) at the ceiling
			r:piece(function(q: R)
				square(q, 0, 0.5, 2, r.c2, "Slate")
				square(q, CEIL - 0.45, CEIL, 2, r.c2, "Slate")
				square(q, CEIL, TOP, 1.86, shade(r.c2, 0.95), "Slate")
			end, true)
			r:piece(function(q: R)
				local y0, y1, n = 0.5, CEIL - 0.45, 10
				square(q, y0, y1, 1.48, shade(r.c1, 0.6), "Slate")
				local course = (y1 - y0) / n
				for i = 0, n - 1 do
					local ya, yb = y0 + i * course + 0.035, y0 + (i + 1) * course - 0.035
					for j, s in { -1, 1 } do
						local k = 0.92 + ((i * 7 + j * 3) % 5) * 0.03
						local grow = ((i * 5 + j) % 3) * 0.02
						local w = 0.9 + grow -- across the course's middle joint
						local d = 1.8 + grow -- along it
						local inner = 0.03
						if i % 2 == 0 then
							q:block(
								if s < 0 then -w else inner,
								ya,
								-d / 2,
								if s < 0 then -inner else w,
								yb,
								d / 2,
								shade(r.c1, k),
								"Slate"
							)
						else
							q:block(
								-d / 2,
								ya,
								if s < 0 then -w else inner,
								d / 2,
								yb,
								if s < 0 then -inner else w,
								shade(r.c1, k),
								"Slate"
							)
						end
					end
				end
			end, true)
		end,
	},
	{
		id = "pillar_timber",
		name = "Timber post",
		cat = "pillars",
		style = "rustic",
		price = 80,
		place = "floor",
		size = Vector3.new(2, H, 2),
		c1 = "9A7250",
		c2 = "6E4C34",
		build = function(r: R)
			-- a squared oak post (c1) with its edges taken off, on a stone pad, carrying a short
			-- beam (c2) on its head with a knee brace each side from the post up under it, every
			-- joint held by oak pegs
			r:block(-0.62, 0, -0.62, 0.62, 0.36, 0.62, C.Stone, "Slate")
			local top = CEIL - 0.6
			r:piece(function(q: R)
				q:block(-0.4, 0.36, -0.33, 0.4, top, 0.33, r.c1, "Wood")
				q:block(-0.33, 0.36, -0.4, 0.33, top, 0.4, r.c1, "Wood")
				-- pegs through the post where the braces meet it, and low down for the sill
				local peg = shade(r.c1, 0.7)
				for _, y in { 8.85, 1.4 } do
					q:block(-0.05, y - 0.05, 0.4, 0.05, y + 0.05, 0.43, peg, "Wood")
					q:block(-0.05, y - 0.05, -0.43, 0.05, y + 0.05, -0.4, peg, "Wood")
				end
			end, true)
			r:piece(function(q: R)
				q:block(-1, top, -0.42, 1, TOP, 0.42, r.c2, "Wood")
				for _, sx in { -1, 1 } do
					q:beam(
						Vector3.new(sx * 0.36, top - 1.7, 0),
						Vector3.new(sx * 0.8, top + 0.04, 0),
						0.26,
						0.3,
						r.c2,
						"Wood"
					)
					q:block(
						sx * 0.7 - 0.05,
						top + 0.2,
						0.42,
						sx * 0.7 + 0.05,
						top + 0.3,
						0.45,
						shade(r.c2, 0.7),
						"Wood"
					)
					q:block(
						sx * 0.7 - 0.05,
						top + 0.2,
						-0.45,
						sx * 0.7 + 0.05,
						top + 0.3,
						-0.42,
						shade(r.c2, 0.7),
						"Wood"
					)
				end
			end, true)
		end,
	},
	{
		id = "pillar_log",
		name = "Log post",
		cat = "pillars",
		style = "rustic",
		price = 60,
		place = "floor",
		size = Vector3.new(2, H, 2),
		c1 = "7E6046",
		c2 = "C9A57A",
		build = function(r: R)
			-- a whole trunk with its bark on (c1) standing on a flat stone, a swelling at its foot,
			-- strips of rough bark, a knot, a lopped branch showing its sawn end (c2) and a split
			-- log laid across its top to take a beam
			r:lump(CFrame.new(0, 0.18, 0) * CFrame.Angles(0, 0.4, 0), 1.96, 0.4, 1.8, C.Stone, "Slate")
			drum(r, 0, 0, 0.3, 1.0, 1.56, shade(r.c1, 0.92), "Wood")
			drum(r, 0, 0, 1.0, CEIL - 0.6, 1.36, r.c1, "Wood")
			r:piece(function(q: R)
				q:block(-0.3, 4, -0.3, 0.3, 5, 0.3, r.c1, "Wood")
				for k = 0, 5 do
					local a = k * math.pi / 3 + 0.3
					local y1 = 1.2 + (k % 3) * 0.9
					local y2 = y1 + 3.2 + (k % 2) * 2.4
					turned(
						q,
						math.cos(a) * 0.64,
						math.sin(a) * 0.64,
						y1,
						y2,
						0.16,
						0.24,
						math.pi / 2 - a,
						shade(r.c1, 0.82),
						"Wood"
					)
				end
			end)
			rod(r, Vector3.new(0.4, 6.0, 0.2), Vector3.new(0.84, 6.5, 0.42), 0.4, r.c1, "Wood")
			rod(r, Vector3.new(0.84, 6.5, 0.42), Vector3.new(0.88, 6.545, 0.44), 0.32, r.c2, "Wood")
			r:lump(CFrame.new(-0.6, 3.4, -0.32) * CFrame.Angles(0, 0.5, 0), 0.3, 0.42, 0.3, shade(r.c1, 0.75), "Wood")
			r:lump(CFrame.new(-0.2, 8.1, 0.64) * CFrame.Angles(0, 0.2, 0), 0.3, 0.36, 0.26, shade(r.c1, 0.75), "Wood")
			-- the saddle: a short log along x, its sawn ends showing, and the head on it
			r:cyl(0, CEIL - 0.25, 0, 1.94, 0.9, "x", shade(r.c1, 1.05), "Wood")
			r:cyl(0, CEIL - 0.25, 0, 2, 0.7, "x", r.c2, "Wood")
			r:block(-0.6, CEIL, -0.5, 0.6, TOP, 0.5, shade(r.c1, 1.05), "Wood")
		end,
	},

	-- Sci-fi ---------------------------------------------------------------------------------------
	{
		id = "pillar_light",
		name = "Light column",
		cat = "pillars",
		style = "scifi",
		price = 150,
		place = "floor",
		size = Vector3.new(2, H, 2),
		c1 = "DCE2EA",
		c2 = "8FE3F2",
		tags = { "light" },
		build = function(r: R)
			-- a tube of glass with a light running up its middle (c2), rings of light round it, all
			-- held in white metal (c1) at the foot and the head and by rings on the glass; it
			-- glows after dark
			drum(r, 0, 0, 0, 0.36, 1.92, r.c1, "Metal")
			drum(r, 0, 0, 0.36, 0.6, 1.66, shade(r.c1, 0.86), "Metal")
			drum(r, 0, 0, CEIL - 0.6, CEIL - 0.36, 1.66, shade(r.c1, 0.86), "Metal")
			drum(r, 0, 0, CEIL - 0.36, CEIL, 1.92, r.c1, "Metal")
			drum(r, 0, 0, CEIL, TOP, 1.8, r.c1, "Metal")
			local tube = drum(r, 0, 0, 0.6, CEIL - 0.6, 1.36, C.Glass, "Glass")
			tube.transp = 0.6
			local core = drum(r, 0, 0, 0.6, CEIL - 0.6, 0.34, r.c2, "Neon")
			r:glow(core, 18, 1.4, r.c2)
			for _, y in { 2.4, 4.8, 7.2, 9.4 } do
				glowOnly(drum(r, 0, 0, y, y + 0.05, 0.8, r.c2, "Neon"))
			end
			for _, y in { 3.6, 6.0, 8.3 } do
				drum(r, 0, 0, y, y + 0.14, 1.44, r.c1, "Metal")
			end
			-- three thin rods inside the glass from the foot to the head
			r:piece(function(q: R)
				for k = 0, 2 do
					local a = k * 2 * math.pi / 3 + math.pi / 2
					local x, z = math.cos(a) * 0.5, math.sin(a) * 0.5
					q:block(x - 0.03, 0.6, z - 0.03, x + 0.03, CEIL - 0.6, z + 0.03, shade(r.c1, 0.9), "Metal")
				end
			end)
		end,
	},
	{
		id = "pillar_pylon",
		name = "Pylon",
		cat = "pillars",
		style = "scifi",
		price = 160,
		place = "floor",
		size = Vector3.new(2, H, 2),
		c1 = "A7AFBA",
		c2 = "6FE0C4",
		build = function(r: R)
			-- a pylon of grey plating (c1): a sloped foot, a core with eight ribs running up it,
			-- three rings of light (c2) round it, a little status light low down, and a crown
			-- sloping out to the ceiling
			local dark = shade(r.c1, 0.72)
			local y1, y2 = 0.9, CEIL - 1.0 -- the ribs and the core
			r:piece(function(q: R)
				square(q, 0, 0.3, 1.96, dark, "Metal")
				square(q, 0.3, CEIL - 0.4, 1.16, shade(r.c1, 0.84), "Metal")
				square(q, CEIL - 0.4, CEIL, 1.96, dark, "Metal")
				square(q, CEIL, TOP, 1.8, dark, "Metal")
				for _, yaw in { 0, math.pi / 2, math.pi, -math.pi / 2 } do
					local out = CFrame.Angles(0, yaw, 0)
					-- (a wedge is full height at its back, +z: turned so its back faces the core)
					q:wedge(
						out * CFrame.new(0, 0.6, 0.73) * CFrame.Angles(0, math.pi, 0),
						1.4,
						0.6,
						0.26,
						dark,
						"Metal"
					)
					q:wedge(
						out
							* CFrame.new(0, CEIL - 0.7, 0.73)
							* CFrame.Angles(0, math.pi, 0)
							* CFrame.Angles(0, 0, math.pi),
						1.4,
						0.6,
						0.26,
						dark,
						"Metal"
					)
				end
			end, true)
			r:piece(function(q: R)
				q:block(-0.09, y1, 0.5, 0.09, y2, 0.88, r.c1, "Metal")
				q:block(-0.09, y1, -0.88, 0.09, y2, -0.5, r.c1, "Metal")
				q:block(0.5, y1, -0.09, 0.88, y2, 0.09, r.c1, "Metal")
				q:block(-0.88, y1, -0.09, -0.5, y2, 0.09, r.c1, "Metal")
				for k = 0, 3 do
					local a = math.pi / 4 + k * math.pi / 2
					turned(
						q,
						math.cos(a) * 0.6,
						math.sin(a) * 0.6,
						y1 + 0.3,
						y2 - 0.3,
						0.16,
						0.5,
						math.pi / 2 - a,
						r.c1,
						"Metal"
					)
				end
			end, true)
			for i, y in { 3.2, 6.0, 8.6 } do
				-- a dark collar round the ribs with the light set in it
				square(r, y - 0.12, y + 0.28, 1.82, dark, "Metal")
				local band = r:block(-0.94, y, -0.94, 0.94, y + 0.16, 0.94, r.c2, "Neon")
				if i == 2 then
					r:glow(band, 14, 1.1, r.c2)
				else
					glowOnly(band)
				end
			end
			glowOnly(r:block(-0.36, 1.4, 0.58, -0.2, 1.5, 0.61, r.c2, "Neon"))
			r:block(-0.36, 1.2, 0.58, -0.2, 1.3, 0.61, dark, "Metal")
		end,
	},
	{
		id = "pillar_hex",
		name = "Hex column",
		cat = "pillars",
		style = "scifi",
		price = 140,
		place = "floor",
		size = Vector3.new(2, H, 2),
		c1 = "E6EAF0",
		c2 = "9CC6FF",
		build = function(r: R)
			-- a six sided column of white panels (c1) in three lengths with dark seams between
			-- them, a strip of light (c2) down every edge that glows after dark, on a wider dark
			-- foot and under a wider dark head
			r:piece(function(q: R)
				hex(q, 0, 0, 0, 0.4, 1.0, SCI_DARK, "Metal")
				hex(q, 0, 0, 0.4, CEIL - 0.4, 0.78, SCI_DARK, "Metal")
				hex(q, 0, 0, CEIL - 0.4, CEIL, 1.0, SCI_DARK, "Metal")
				hex(q, 0, 0, CEIL, TOP, 0.94, SCI_DARK, "Metal")
			end, true)
			r:piece(function(q: R)
				for _, s in { { 0.4, 3.84 }, { 3.9, 7.0 }, { 7.06, CEIL - 0.4 } } do
					hex(q, 0, 0, s[1], s[2], 0.86, r.c1, "Metal")
				end
			end, true)
			for k = 0, 5 do
				local a = k * math.pi / 3
				local x, z = math.cos(a) * 0.86, math.sin(a) * 0.86
				local strip = r:block(x - 0.05, 0.5, z - 0.05, x + 0.05, CEIL - 0.5, z + 0.05, r.c2, "Neon")
				if k == 0 then
					r:glow(strip, 16, 1.2, r.c2)
				else
					glowOnly(strip)
				end
			end
		end,
	},

	-- Seaside --------------------------------------------------------------------------------------
	{
		id = "pillar_palm",
		name = "Palm post",
		cat = "pillars",
		style = "seaside",
		price = 90,
		place = "floor",
		size = Vector3.new(2, H, 2),
		c1 = "9C7B5A",
		c2 = "C4A57C",
		build = function(r: R)
			-- a palm trunk cut to length for a post: a swollen foot, rough rings of trunk (c1)
			-- one on another, each a little narrower and turned from the last, the old leaf bases
			-- (c2) sticking out under the cut top, two coconuts left on, and a plank cap on top
			r:lump(CFrame.new(0, 0.32, 0), 1.9, 0.9, 1.9, shade(r.c1, 0.86), "Wood")
			local y0, y1, n = 0.5, CEIL - 1.0, 14
			local ring = (y1 - y0) / n
			for part = 0, 2 do
				r:piece(function(q: R)
					local a, b = part * 5, math.min(part * 5 + 4, n - 1)
					square(q, y0 + a * ring, y0 + (b + 1) * ring, 0.6, shade(r.c1, 0.8), "Wood")
					for i = a, b do
						-- each ring is two squares an eighth of a turn apart, so it reads round,
						-- flaring out at its top where the old leaf was
						local s = 1.2 - i * 0.018
						local ya = y0 + i * ring
						local yaw = i * 0.2
						local body = if i % 2 == 0 then r.c1 else shade(r.c1, 0.96)
						for _, t in { 0, math.pi / 4 } do
							turned(q, 0, 0, ya, ya + ring, s, s, yaw + t, body, "Wood")
							turned(
								q,
								0,
								0,
								ya + ring - 0.1,
								ya + ring,
								s + 0.08,
								s + 0.08,
								yaw + t,
								shade(r.c1, 1.07),
								"Wood"
							)
						end
					end
				end, true)
			end
			-- the leaf bases, coconuts, and the cap
			r:piece(function(q: R)
				square(q, y1 - 0.2, y1 + 0.2, 0.6, r.c2, "Wood")
				for k = 0, 6 do
					local a = k * 2 * math.pi / 7
					q:boxAt(
						CFrame.new(math.cos(a) * 0.62, y1 - 0.25, math.sin(a) * 0.62)
							* CFrame.Angles(0, math.pi / 2 - a, 0)
							* CFrame.Angles(-0.7, 0, 0),
						0.34,
						0.7,
						0.08,
						if k % 2 == 0 then r.c2 else shade(r.c2, 0.9),
						"Wood"
					)
				end
			end)
			r:ball(0.38, y1 - 0.55, 0.46, 0.42, Color3.fromRGB(110, 82, 56), "Wood")
			r:ball(-0.5, y1 - 0.6, 0.28, 0.4, Color3.fromRGB(122, 92, 60), "Wood")
			square(r, y1, y1 + 0.4, 1.3, shade(r.c1, 0.95), "Wood")
			r:piece(function(q: R)
				square(q, y1 + 0.4, CEIL, 1.6, r.c2, "WoodPlanks")
				square(q, CEIL, TOP, 1.5, shade(r.c2, 0.95), "WoodPlanks")
			end, true)
		end,
	},
	{
		id = "pillar_rope",
		name = "Rope pier",
		cat = "pillars",
		style = "seaside",
		price = 80,
		place = "floor",
		size = Vector3.new(2, H, 2),
		c1 = "A3998A",
		c2 = "D4BC8E",
		build = function(r: R)
			-- a weathered pile (c1) like the ones under a pier: a round post with splits down it,
			-- weed round its foot, two thick wraps of rope (c2) with an end hanging down, an iron
			-- ring, and a cap board on top
			drum(r, 0, 0, 0, CEIL - 0.3, 1.5, r.c1, "Wood")
			drum(r, 0, 0, 0, 0.6, 1.56, Color3.fromRGB(104, 128, 92), "Grass")
			r:piece(function(q: R)
				local split = shade(r.c1, 0.62)
				for k, s in { { 0, 1.4, 4.2 }, { 2.1, 4.6, 9.4 }, { 3.9, 0.9, 2.8 }, { 5.2, 6.3, 9.9 } } do
					local a = s[1]
					turned(
						q,
						math.cos(a) * 0.75,
						math.sin(a) * 0.75,
						s[2],
						s[3],
						0.05,
						0.06,
						math.pi / 2 - a,
						split,
						"Wood"
					)
					if k == 1 then
						q:block(-0.1, 5, -0.1, 0.1, 5.2, 0.1, split, "Wood")
					end
				end
			end)
			for _, band in { 2.1, 7.6 } do
				for i = 0, 4 do
					local y = band + i * 0.18
					drum(r, 0, 0, y, y + 0.16, 1.68, if i % 2 == 0 then r.c2 else shade(r.c2, 0.9), "Fabric")
				end
			end
			r:beam(Vector3.new(0.62, 2.2, 0.5), Vector3.new(0.68, 1.1, 0.58), 0.14, 0.14, r.c2, "Fabric")
			r:beam(Vector3.new(0.68, 1.12, 0.58), Vector3.new(0.6, 0.7, 0.66), 0.14, 0.14, shade(r.c2, 0.9), "Fabric")
			-- the iron ring: a staple in the post and a ring hanging from it
			r:piece(function(q: R)
				q:block(-0.12, 5.3, 0.7, 0.12, 5.4, 0.8, C.DarkMetal, "Metal")
				local f = CFrame.new(0, 5.06, 0.8) * CFrame.Angles(0, 0, math.pi / 4)
				for _, p in
					{ { 0, 0.17, 0.3, 0.06 }, { 0, -0.17, 0.3, 0.06 }, { 0.17, 0, 0.06, 0.3 }, { -0.17, 0, 0.06, 0.3 } }
				do
					q:boxAt(f * CFrame.new(p[1], p[2], 0), p[3], p[4], 0.06, C.DarkMetal, "Metal")
				end
			end)
			r:piece(function(q: R)
				square(q, CEIL - 0.3, CEIL, 1.76, shade(r.c1, 0.9), "Wood")
				square(q, CEIL, TOP, 1.6, shade(r.c1, 0.86), "Wood")
			end, true)
		end,
	},
	{
		id = "pillar_mooring",
		name = "Mooring post",
		cat = "pillars",
		style = "seaside",
		price = 40,
		place = "floor",
		size = Vector3.new(2, 3.4, 2),
		c1 = "8E7B66",
		c2 = "D4BC8E",
		build = function(r: R)
			-- a short thick post (c1) like the ones along a quay: a rounded top, an iron band, and
			-- a rope (c2) looped over it with its end trailing to a coil on the floor
			drum(r, 0, 0, 0, 2.9, 1.4, r.c1, "Wood")
			drum(r, 0, 0, 2.9, 3.06, 1.22, shade(r.c1, 0.92), "Wood")
			r:lump(CFrame.new(0, 3.12, 0), 1.08, 0.56, 1.08, shade(r.c1, 0.96), "Wood")
			drum(r, 0, 0, 2.3, 2.46, 1.48, C.DarkMetal, "Metal")
			drum(r, 0, 0, 1.7, 1.9, 1.62, r.c2, "Fabric")
			r:beam(Vector3.new(0.62, 1.78, 0.36), Vector3.new(0.78, 0.8, 0.58), 0.16, 0.16, r.c2, "Fabric")
			r:beam(Vector3.new(0.78, 0.82, 0.58), Vector3.new(0.72, 0.1, 0.74), 0.16, 0.16, r.c2, "Fabric")
			drum(r, 0.66, 0.76, 0, 0.1, 0.5, shade(r.c2, 0.92), "Fabric")
			drum(r, 0.66, 0.76, 0.1, 0.18, 0.34, r.c2, "Fabric")
		end,
	},

	-- Garden ---------------------------------------------------------------------------------------
	{
		id = "pillar_rose",
		name = "Rose pillar",
		cat = "pillars",
		style = "garden",
		price = 120,
		place = "floor",
		size = Vector3.new(2, H, 2),
		c1 = "E4DED2",
		c2 = "D9707F",
		tags = { "plant" },
		build = function(r: R)
			-- a square stone pillar (c1) with a rose climbing it: a stem winding round it, clumps
			-- of leaves all the way up, and roses (c2), more of them toward the top
			r:piece(function(q: R)
				square(q, 0, 0.5, 1.6, shade(r.c1, 0.92), "Limestone")
				square(q, 0.5, CEIL - 0.5, 1.0, r.c1, "Limestone")
				square(q, CEIL - 0.5, CEIL - 0.3, 1.3, shade(r.c1, 1.03), "Limestone")
				square(q, CEIL - 0.3, CEIL, 1.5, r.c1, "Limestone")
				square(q, CEIL, TOP, 1.4, shade(r.c1, 0.95), "Limestone")
			end, true)
			local y1, y2, turns, rad, phase = 0.5, CEIL - 0.6, 3.5, 0.64, 0.4
			local function along(t: number, off: number, out: number): (Vector3, number)
				local a = phase + turns * 2 * math.pi * t + off
				return around(a, y1 + (y2 - y1) * t, out), a
			end
			r:piece(function(q: R)
				helix(q, 0, 27, 27, y1, y2, turns, rad, phase, 0.12, 0.12, ROSE_STEM, "Grass")
			end)
			-- thirty clumps of leaves in two pieces, thicker toward the top where the sun is
			for half = 0, 1 do
				r:piece(function(q: R)
					q:block(-0.1, 3 + half * 4, -0.1, 0.1, 3.2 + half * 4, 0.1, C.Leaf, "Grass")
					for i = half * 15, half * 15 + 14 do
						local t = ((i + 0.5) / 30) ^ 0.85
						local p, a = along(t, if i % 2 == 0 then 0.4 else -0.35, 0.68)
						local sz = 0.44 + (i % 4) * 0.05
						local leaf = if i % 3 == 0 then C.DarkLeaf else C.Leaf
						q:lump(CFrame.new(p) * CFrame.Angles(0, a, 0.4), sz, sz * 0.7, sz, leaf, "Grass")
					end
				end)
			end
			for i = 0, 13 do
				local t = 0.16 + 0.8 * ((i + 0.5) / 14) ^ 0.7
				local p, a = along(t, if i % 2 == 0 then 0.15 else 0.6, 0.78)
				local d = 0.28 + (i % 3) * 0.03
				local bloom = r:lump(
					CFrame.new(p) * CFrame.Angles(0.3, a, 0),
					d,
					d * 0.86,
					d,
					if i % 3 == 1 then shade(r.c2, 1.1) else r.c2,
					"SmoothPlastic"
				)
				r:noCollide(bloom)
			end
		end,
	},
	{
		id = "pillar_trellis",
		name = "Trellis column",
		cat = "pillars",
		style = "garden",
		price = 90,
		place = "floor",
		size = Vector3.new(2, H, 2),
		c1 = "F2EFE8",
		c2 = "CFC8B8",
		tags = { "plant" },
		build = function(r: R)
			-- an open column of trellis (c1) you can see through: four corner posts, rails across
			-- every side and two uprights behind them, on a solid base (c2) with a cap at the
			-- ceiling, and ivy climbing one corner
			r:piece(function(q: R)
				square(q, 0, 0.4, 2, r.c2, "Wood")
				square(q, CEIL - 0.4, CEIL, 1.96, r.c2, "Wood")
				square(q, CEIL, TOP, 1.8, shade(r.c2, 0.95), "Wood")
			end, true)
			local y1, y2 = 0.4, CEIL - 0.4
			r:piece(function(q: R)
				for _, sx in { -1, 1 } do
					for _, sz in { -1, 1 } do
						q:block(
							sx * 0.86 - 0.1,
							y1,
							sz * 0.86 - 0.1,
							sx * 0.86 + 0.1,
							y2,
							sz * 0.86 + 0.1,
							r.c1,
							"Wood"
						)
					end
					for _, u in { -0.28, 0.28 } do
						q:block(u - 0.05, y1, sx * 0.83 - 0.04, u + 0.05, y2, sx * 0.83 + 0.04, r.c1, "Wood")
						q:block(sx * 0.83 - 0.04, y1, u - 0.05, sx * 0.83 + 0.04, y2, u + 0.05, r.c1, "Wood")
					end
				end
			end, true)
			r:piece(function(q: R)
				for i = 1, 7 do
					local y = y1 + i * (y2 - y1) / 8
					q:block(-0.76, y - 0.05, 0.87, 0.76, y + 0.05, 0.93, r.c1, "Wood")
					q:block(-0.76, y - 0.05, -0.93, 0.76, y + 0.05, -0.87, r.c1, "Wood")
					q:block(0.87, y - 0.05, -0.76, 0.93, y + 0.05, 0.76, r.c1, "Wood")
					q:block(-0.93, y - 0.05, -0.76, -0.87, y + 0.05, 0.76, r.c1, "Wood")
				end
			end, true)
			-- the ivy up the front left corner and round onto the front
			r:piece(function(q: R)
				local pts = {
					Vector3.new(-0.98, 0.4, 0.98),
					Vector3.new(-1.0, 2.6, 0.9),
					Vector3.new(-0.9, 4.8, 1.0),
					Vector3.new(-0.4, 6.3, 1.0),
					Vector3.new(0.2, 7.4, 1.0),
				}
				q:block(-0.95, 0.4, 0.9, -0.85, 0.5, 1.0, C.Bark, "Grass")
				for i = 1, #pts - 1 do
					q:beam(pts[i], pts[i + 1], 0.08, 0.08, C.Bark, "Grass")
				end
				for i, l in
					{
						{ -0.86, 1.2, 0.86, 0.5 },
						{ -0.86, 2.2, 0.86, 0.56 },
						{ -0.82, 3.1, 0.82, 0.5 },
						{ -0.86, 4.0, 0.86, 0.56 },
						{ -0.7, 5.0, 0.84, 0.5 },
						{ -0.46, 5.9, 0.84, 0.48 },
						{ -0.1, 6.6, 0.84, 0.46 },
						{ 0.26, 7.3, 0.84, 0.4 },
						{ -0.9, 5.4, 0.6, 0.42 },
					}
				do
					q:lump(
						CFrame.new(l[1], l[2], l[3]) * CFrame.Angles(0, i * 0.7, 0.3),
						l[4],
						l[4] * 0.62,
						l[4],
						if i % 2 == 0 then C.Leaf else C.DarkLeaf,
						"Grass"
					)
				end
			end)
		end,
	},
	{
		id = "pillar_planter",
		name = "Planter post",
		cat = "pillars",
		style = "garden",
		price = 70,
		place = "floor",
		size = Vector3.new(2, 5.2, 2),
		c1 = "CFC9BC",
		c2 = "C98466",
		tags = { "plant" },
		build = function(r: R)
			-- a short stone post (c1) with a clay bowl (c2) on top full of flowers, and trails of
			-- ivy hanging over its rim
			r:piece(function(q: R)
				square(q, 0, 0.4, 1.7, shade(r.c1, 0.92), "Limestone")
				square(q, 0.4, 3.0, 1.2, r.c1, "Limestone")
				square(q, 3.0, 3.3, 1.6, shade(r.c1, 1.03), "Limestone")
			end, true)
			drum(r, 0, 0, 3.3, 3.48, 0.9, shade(r.c2, 0.9), "Brick")
			drum(r, 0, 0, 3.48, 3.72, 1.3, r.c2, "Brick")
			drum(r, 0, 0, 3.72, 4.08, 1.66, r.c2, "Brick")
			drum(r, 0, 0, 4.08, 4.2, 1.84, shade(r.c2, 0.92), "Brick")
			drum(r, 0, 0, 4.2, 4.24, 1.6, C.Soil, "Sand")
			r:piece(function(q: R)
				q:block(-0.5, 4.2, -0.5, 0.5, 4.3, 0.5, C.DarkLeaf, "Grass")
				for k = 0, 5 do
					local a = k * math.pi / 3 + 0.2
					local s = 0.5 + (k % 2) * 0.08
					q:lump(
						CFrame.new(math.cos(a) * 0.48, 4.42, math.sin(a) * 0.48) * CFrame.Angles(0, a, 0.2),
						s,
						s * 0.7,
						s,
						if k % 2 == 0 then C.Leaf else C.DarkLeaf,
						"Grass"
					)
				end
				q:lump(CFrame.new(0, 4.6, 0), 0.6, 0.5, 0.6, C.Leaf, "Grass")
				-- ivy trailing over the rim, each trail a few leaves down the bowl's side
				for k, len in { 4, 2, 3, 2 } do
					local a = k * math.pi / 2 + 0.6
					for m = 0, len - 1 do
						local out, side = 0.9 - m * 0.02, (if m % 2 == 0 then 0.05 else -0.05)
						local x = math.cos(a) * out - math.sin(a) * side
						local z = math.sin(a) * out + math.cos(a) * side
						local leaf = if (k + m) % 2 == 0 then C.Leaf else C.DarkLeaf
						q:lump(
							CFrame.new(x, 4.06 - m * 0.22, z) * CFrame.Angles(0.3, a, 0.2),
							0.26,
							0.24,
							0.22,
							leaf,
							"Grass"
						)
					end
				end
			end)
			local heads = { C.Pink, C.White, C.Pink, C.Yellow, C.White, C.Yellow }
			for k, f in
				{
					Vector3.new(0.3, 4.86, 0.2),
					Vector3.new(-0.36, 4.8, 0.1),
					Vector3.new(0.02, 4.98, -0.32),
					Vector3.new(-0.12, 4.74, 0.5),
					Vector3.new(0.5, 4.7, -0.3),
					Vector3.new(-0.5, 4.76, -0.36),
				}
			do
				r:noCollide(r:lump(CFrame.new(f) * CFrame.Angles(0.2, k, 0), 0.3, 0.14, 0.3, heads[k], "SmoothPlastic"))
			end
		end,
	},
	{
		id = "pillar_bamboo",
		name = "Bamboo post",
		cat = "pillars",
		style = "garden",
		price = 40,
		place = "floor",
		size = Vector3.new(1, H, 1),
		c1 = "B9A86A",
		c2 = "8A6A4A",
		build = function(r: R)
			-- three bamboo canes (c1) bound together into one slim post, each with its own joints,
			-- lashed with cord (c2) at the foot, the middle and the head, on a stone pad
			r:block(-0.45, 0, -0.45, 0.45, 0.22, 0.45, C.Stone, "Slate")
			for i, p in { { 0.15, 0 }, { -0.08, 0.14 }, { -0.08, -0.14 } } do
				drum(r, p[1], p[2], 0.22, CEIL, 0.3, if i == 2 then shade(r.c1, 0.94) else r.c1, "Wood")
				for j = 0, 3 do
					local y = 1.6 + j * 2.4 + i * 0.5
					drum(r, p[1], p[2], y, y + 0.08, 0.34, shade(r.c1, 0.86), "Wood")
				end
			end
			for _, y in { 0.6, 5.3, CEIL - 0.8 } do
				drum(r, 0, 0, y, y + 0.26, 0.68, r.c2, "Fabric")
			end
			r:block(-0.42, CEIL, -0.42, 0.42, TOP, 0.42, shade(r.c1, 0.9), "Wood")
		end,
	},

	-- Playful --------------------------------------------------------------------------------------
	{
		id = "pillar_candy",
		name = "Candy column",
		cat = "pillars",
		style = "playful",
		price = 100,
		place = "floor",
		size = Vector3.new(2, H, 2),
		c1 = "F7F1EA",
		c2 = "E58A9A",
		build = function(r: R)
			-- a round column (c1) with a candy stripe (c2) winding up it and a thin mint one beside
			-- it, a ring of sweets on a ledge near the top, and a striped band at the ceiling
			local mint = Color3.fromRGB(150, 210, 186)
			drum(r, 0, 0, 0, 0.5, 1.9, r.c2, "SmoothPlastic")
			drum(r, 0, 0, 0.5, 0.7, 1.6, r.c1, "SmoothPlastic")
			drum(r, 0, 0, 0.7, CEIL, 1.4, r.c1, "SmoothPlastic")
			-- (each stripe three times round in 54 lengths, 18 to a piece)
			local n, y1, y2 = 54, 0.7, 9.9
			for k = 0, 2 do
				r:piece(function(q: R)
					helix(q, k * 18, k * 18 + 18, n, y1, y2, 3, 0.74, 0, 0.1, 0.42, r.c2, "SmoothPlastic")
				end)
				r:piece(function(q: R)
					helix(q, k * 18, k * 18 + 18, n, y1, y2, 3, 0.74, math.pi, 0.1, 0.16, mint, "SmoothPlastic")
				end)
			end
			drum(r, 0, 0, 9.9, 10.08, 1.72, r.c2, "SmoothPlastic")
			for k = 0, 7 do
				local a = k * math.pi / 4 + math.pi / 8
				local col = ({ C.Yellow, mint, C.Pink, C.Blue })[k % 4 + 1]
				r:ball(math.cos(a) * 0.74, 10.23, math.sin(a) * 0.74, 0.3, col, "SmoothPlastic")
			end
			drum(r, 0, 0, CEIL - 0.3, CEIL, 1.66, r.c2, "SmoothPlastic")
			drum(r, 0, 0, CEIL - 0.19, CEIL - 0.11, 1.7, r.c1, "SmoothPlastic")
			drum(r, 0, 0, CEIL, TOP, 1.56, r.c1, "SmoothPlastic")
		end,
	},
	{
		id = "pillar_blocks",
		name = "Block stack",
		cat = "pillars",
		style = "playful",
		price = 110,
		place = "floor",
		size = Vector3.new(2, H, 2),
		c1 = "F2D27A",
		c2 = "8EC3E6",
		build = function(r: R)
			-- toy blocks stacked up to the ceiling, each a little turned from the one under it,
			-- with a raised border and a letter or a number on two faces; c1 and c2 paint every
			-- other block and the others are pink and green, under a flat plank
			local n = 7
			local s = CEIL / n
			local w = 1.52
			local faces =
				{ { "A", "1" }, { "B", "2" }, { "C", "3" }, { "E", "4" }, { "H", "5" }, { "T", "7" }, { "1", "A" } }
			for i = 0, n - 1 do
				local col = ({ r.c1, r.c2, TOY_PINK, TOY_GREEN })[i % 4 + 1]
				local ink = shade(col, 0.68)
				local rim = shade(col, 1.12)
				local yaw = ((i * 3) % 5 - 2) * 0.07
				local f = CFrame.new(((i * 7) % 3 - 1) * 0.04, i * s + s / 2, ((i * 5) % 3 - 1) * 0.04)
					* CFrame.Angles(0, yaw, 0)
				r:piece(function(q: R)
					q:block(-0.1, i * s + s / 2 - 0.1, -0.1, 0.1, i * s + s / 2 + 0.1, 0.1, col, "SmoothPlastic")
					q:boxAt(f, w, s, w, col, "SmoothPlastic")
					local h = w / 2
					-- on the front (+z: u runs along x) and the right (+x: u runs along -z)
					local function strip(face: number, u1: number, v1: number, u2: number, v2: number, color: Color3)
						local cu, cv, su, sv = (u1 + u2) / 2, (v1 + v2) / 2, u2 - u1, v2 - v1
						if face == 1 then
							q:boxAt(f * CFrame.new(cu, cv, h + 0.015), su, sv, 0.05, color, "SmoothPlastic")
						else
							q:boxAt(f * CFrame.new(h + 0.015, cv, -cu), 0.05, sv, su, color, "SmoothPlastic")
						end
					end
					for face = 1, 2 do
						local e, t = h - 0.08, 0.1
						strip(face, -e, e - t, e, e, rim)
						strip(face, -e, -e, e, -e + t, rim)
						strip(face, -e, -e + t, -e + t, e - t, rim)
						strip(face, e - t, -e + t, e, e - t, rim)
						local cell = 0.15
						for _, g in GLYPHS[faces[i + 1][face]] do
							strip(
								face,
								-0.375 + g[1] * cell,
								-0.375 + g[2] * cell,
								-0.375 + (g[3] + 1) * cell,
								-0.375 + (g[4] + 1) * cell,
								ink
							)
						end
					end
				end, true)
			end
			r:piece(function(q: R)
				q:block(-0.9, CEIL, -0.6, 0.9, TOP, 0.6, shade(r.c2, 0.9), "Wood")
			end, true)
		end,
	},
	{
		id = "pillar_pencil",
		name = "Pencil post",
		cat = "pillars",
		style = "playful",
		price = 50,
		place = "floor",
		size = Vector3.new(2, 5.7, 2),
		c1 = "F0C75E",
		c2 = "E8A0A8",
		build = function(r: R)
			-- a giant pencil stood on its end: the rubber (c2) at the foot in a metal band with
			-- ridges, the six sided body (c1) with its letters, the sharpened wood and a lead tip
			r:piece(function(q: R)
				hex(q, 0, 0, 0, 0.6, 0.86, r.c2, "Rubber")
			end, true)
			r:piece(function(q: R)
				hex(q, 0, 0, 0.6, 1.2, 0.9, C.Metal, "Metal")
				hex(q, 0, 0, 0.74, 0.82, 0.94, shade(C.Metal, 0.9), "Metal")
				hex(q, 0, 0, 0.98, 1.06, 0.94, shade(C.Metal, 0.9), "Metal")
			end, true)
			r:piece(function(q: R)
				hex(q, 0, 0, 1.2, 4.4, 0.88, r.c1, "SmoothPlastic")
				-- the letters on the front face: an H and a B
				local z = 0.88 * math.sqrt(3) / 2
				local ink = Color3.fromRGB(70, 66, 74)
				for _, b in
					{
						{ -0.3, 2.4, -0.25, 2.8 },
						{ -0.1, 2.4, -0.05, 2.8 },
						{ -0.25, 2.58, -0.1, 2.62 },
						{ 0.05, 2.4, 0.1, 2.8 },
						{ 0.1, 2.76, 0.24, 2.8 },
						{ 0.1, 2.58, 0.24, 2.62 },
						{ 0.1, 2.4, 0.24, 2.44 },
						{ 0.24, 2.44, 0.29, 2.58 },
						{ 0.24, 2.62, 0.29, 2.76 },
					}
				do
					q:block(b[1], b[2], z - 0.01, b[3], b[4], z + 0.03, ink, "SmoothPlastic")
				end
			end, true)
			r:cone(0, 4.4 + 0.6, 0, 1.2, 1.56, Color3.fromRGB(232, 201, 154), "Wood")
			r:cone(0, 5.2 + 0.25, 0, 0.5, 0.54, Color3.fromRGB(70, 66, 74), "Slate")
		end,
	},
}

return items
