--!strict
-- Rustic: farmhouse and cabin things, rough boards, logs, iron and straw. The user: "add much
-- much more buildings, decoration, paths, fences and other options. there should be many to
-- choose from from different categories, like garden, sci fi, cozy, etc, just like bloxburg".
-- Every piece here has style = "rustic" (Catalog.Styles) and sits in one of Build mode's usual
-- tabs as well. c1 is the main colour (a wood, a paint), c2 the second (iron, a cloth, flowers).
-- Fronts face +z; wall pieces stand out from the wall along +z.

local Recipe = require(script.Parent.Parent.Recipe)
local Colors = require(script.Parent.Parent.Parent.Util.Colors)

local C = Recipe.Colors

type R = Recipe.Recipe

local function shade(c: Color3, k: number): Color3
	return Colors.shade(c, k)
end

local function mix(a: Color3, b: Color3, t: number): Color3
	return Colors.mix(a, b, t)
end

local V = Vector3.new

-- Colours for the small things, soft and a little dusty like the rest of the palette.
local BARK = Color3.fromRGB(104, 78, 56)
local ENDGRAIN = Color3.fromRGB(214, 182, 134)
local IRON = Color3.fromRGB(62, 58, 60)
local STRAW = Color3.fromRGB(217, 190, 120)
local TWINE = Color3.fromRGB(190, 162, 122)
local GINGHAM = Color3.fromRGB(188, 104, 96)
local CREAM = Color3.fromRGB(240, 232, 216)
local SHEET = Color3.fromRGB(248, 245, 238)
local WOOL = Color3.fromRGB(236, 228, 212)
local STONEWARE = Color3.fromRGB(206, 196, 176)
local DELFT = Color3.fromRGB(104, 136, 172)
local SOIL = Color3.fromRGB(86, 62, 46)
local INSIDE = Color3.fromRGB(58, 44, 36)
local WATER = Color3.fromRGB(120, 176, 200)
local MUSTARD = Color3.fromRGB(214, 178, 110)
local SAGE = Color3.fromRGB(150, 172, 140)
local ROSE = Color3.fromRGB(201, 139, 134)
local DUSK = Color3.fromRGB(143, 166, 184)
local LAVENDER = Color3.fromRGB(150, 128, 182)
local BRASS = Color3.fromRGB(196, 164, 98)
local PAGE = Color3.fromRGB(246, 240, 224)
local MIRROR = Color3.fromRGB(205, 225, 234)

-- A small fixed random, so the same piece comes out the same every time.
local function rng(seed: number): () -> number
	local s = seed % 2147483646 + 1
	return function(): number
		s = (s * 16807) % 2147483647
		return s / 2147483647
	end
end

-- Glows at night without a light of its own (when another part of the item already has one).
local function glowOnly(p: Recipe.Prim)
	p.role = "glow"
end

-- Something see-through.
local function clear(p: Recipe.Prim, t: number): Recipe.Prim
	p.transp = t
	return p
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
		size = V(len, d, d),
		color = color,
		mat = mat or "SmoothPlastic",
	})
end

-- A path of rods through the points, each a little longer so the joints close up.
local function path(r: R, pts: { Vector3 }, d: number, color: Color3, mat: string?)
	for i = 1, #pts - 1 do
		local a, b = pts[i], pts[i + 1]
		local e = (b - a).Unit * d * 0.4
		rod(r, if i > 1 then a - e else a, if i < #pts - 1 then b + e else b, d, color, mat)
	end
end

-- A cylinder along the X axis of a frame.
local function cylAt(r: R, cf: CFrame, len: number, d: number, color: Color3, mat: string?): Recipe.Prim
	return r:add({ shape = "Cylinder", cf = cf, size = V(len, d, d), color = color, mat = mat or "SmoothPlastic" })
end

-- Staves standing round (cx, cz) from y0 to y0 + h, n of them: each runs from rBot at the foot
-- out to rMid half way up and in to rTop at the top (all three equal draws straight sides). One
-- piece, the staves in slightly different browns. Returns a stave's width.
local function staves(
	r: R,
	cx: number,
	cz: number,
	y0: number,
	h: number,
	rBot: number,
	rMid: number,
	rTop: number,
	n: number,
	wood: Color3
): number
	local w = 2 * math.pi * math.max(rBot, rMid, rTop) / n + 0.02
	local ym = y0 + h / 2
	local bulge = math.abs(rMid - (rBot + rTop) / 2) > 1e-3
	local straight = math.abs(rBot - rTop) < 1e-3 and not bulge
	-- (a piece holds at most 28 shapes, so bulging staves go in batches)
	local per = if bulge then 13 else 27
	for first = 0, n - 1, per do
		r:piece(function(q: R)
			q:box(cx, ym, cz, 0.1, 0.1, 0.1, wood, "Wood")
			for i = first, math.min(n, first + per) - 1 do
				local a = (i + 0.5) * 2 * math.pi / n
				local dx, dz = math.cos(a), math.sin(a)
				local col = shade(wood, 0.9 + ((i * 7) % 5) * 0.05)
				local function at(rad: number, y: number): Vector3
					return V(cx + dx * rad, y, cz + dz * rad)
				end
				if straight then
					q:boxAt(CFrame.new(at(rBot, ym)) * CFrame.Angles(0, -a, 0), 0.1, h, w, col, "Wood")
				elseif bulge then
					local e = V(0, 0.02, 0)
					q:beam(at(rBot, y0), at(rMid, ym) + e, w, 0.1, col, "Wood")
					q:beam(at(rMid, ym) - e, at(rTop, y0 + h), w, 0.1, col, "Wood")
				else
					q:beam(at(rBot, y0), at(rTop, y0 + h), w, 0.1, col, "Wood")
				end
			end
		end)
	end
	return w
end

-- An iron hoop round staves whose middles are `rad` out at height y: a short strap on each
-- stave, so it follows the staves round and leaves a tub open to look into.
local function hoopRing(r: R, cx: number, cz: number, y: number, rad: number, n: number, color: Color3)
	local w = 2 * (rad + 0.07) * math.tan(math.pi / n) + 0.01
	local a0 = math.pi / n
	r:piece(function(q: R)
		q:box(cx + math.cos(a0) * rad, y, cz + math.sin(a0) * rad, 0.02, 0.02, 0.02, color, "Metal")
		for i = 0, n - 1 do
			local a = (i + 0.5) * 2 * math.pi / n
			q:boxAt(
				CFrame.new(cx + math.cos(a) * (rad + 0.07), y, cz + math.sin(a) * (rad + 0.07))
					* CFrame.Angles(0, -a, 0),
				0.04,
				0.14,
				w,
				color,
				"Metal"
			)
		end
	end)
end

-- A ring of n short beams round `centre` in the plane of u and v, `rad` out: a wheel's rim, a
-- wreath's twigs, an iron hoop. `across` is its width out of that plane, `thick` its depth
-- toward the middle. Drawn on q (a recipe or a piece).
local function ring(
	q: R,
	centre: Vector3,
	u: Vector3,
	v: Vector3,
	rad: number,
	n: number,
	across: number,
	thick: number,
	color: Color3,
	mat: string,
	turn: number?
)
	for i = 0, n - 1 do
		local a1 = (i + (turn or 0)) * 2 * math.pi / n
		local a2 = (i + 1 + (turn or 0)) * 2 * math.pi / n
		local p1 = centre + (u * math.cos(a1) + v * math.sin(a1)) * rad
		local p2 = centre + (u * math.cos(a2) + v * math.sin(a2)) * rad
		local e = (p2 - p1).Unit * thick * 0.5
		q:beam(p1 - e, p2 + e, across, thick, color, mat)
	end
end

-- A lidded glass jar of something (jam, peaches, pickles) standing on y.
local function jar(r: R, x: number, y: number, z: number, d: number, h: number, fill: Color3, cap: Color3?)
	clear(r:cyl(x, y + h / 2, z, h, d, "y", Color3.fromRGB(222, 234, 230), "Glass"), 0.5)
	r:cyl(x, y + h * 0.42, z, h * 0.8, d - 0.08, "y", fill, "SmoothPlastic")
	r:cyl(x, y + h + 0.03, z, 0.06, d * 0.92, "y", C.Metal, "Metal")
	if cap then
		r:cyl(x, y + h + 0.075, z, 0.03, d + 0.12, "y", cap, "Fabric")
		r:cyl(x, y + h - 0.02, z, 0.04, d + 0.04, "y", TWINE, "Fabric")
	end
end

-- A clay pot standing on y: a body, a rolled rim and soil showing at the top. Returns the
-- height of the soil.
local function pot(r: R, x: number, y: number, z: number, d: number, h: number, color: Color3): number
	r:cyl(x, y + h * 0.4, z, h * 0.8, d * 0.84, "y", color, "SmoothPlastic")
	r:cyl(x, y + h * 0.88, z, h * 0.24, d, "y", shade(color, 1.06), "SmoothPlastic")
	r:cyl(x, y + h + 0.015, z, 0.03, d * 0.8, "y", SOIL, "Sand")
	return y + h + 0.03
end

-- A bunch of herbs hung upside down from a tie at `top`: stems fanning down to leafy tips. One
-- piece.
local function herbs(r: R, top: Vector3, len: number, leaf: Color3, seed: number)
	local rand = rng(seed)
	r:piece(function(q: R)
		q:box(top.X, top.Y - 0.05, top.Z, 0.1, 0.1, 0.1, TWINE, "SmoothPlastic")
		for i = 0, 5 do
			local a = i * math.pi / 3 + rand() * 0.4
			local tip = top + V(math.cos(a) * 0.16, -len * (0.8 + rand() * 0.2), math.sin(a) * 0.1)
			q:beam(top - V(0, 0.08, 0), tip, 0.025, 0.025, shade(leaf, 0.75), "SmoothPlastic")
			q:lump(
				CFrame.new(tip) * CFrame.Angles(0, a, 0.2),
				0.12,
				0.26,
				0.1,
				if i % 2 == 0 then leaf else shade(leaf, 1.1),
				"SmoothPlastic"
			)
		end
	end)
end

-- A cloth patchwork on top of something: nx by nz patches over x1..x2, z1..z2, y to y + 0.03.
local function patchwork(
	r: R,
	x1: number,
	x2: number,
	z1: number,
	z2: number,
	y: number,
	nx: number,
	nz: number,
	colours: { Color3 },
	seed: number
)
	local rand = rng(seed)
	r:piece(function(q: R)
		for i = 0, nx - 1 do
			for j = 0, nz - 1 do
				local a, b = x1 + (x2 - x1) * i / nx, x1 + (x2 - x1) * (i + 1) / nx
				local c, d = z1 + (z2 - z1) * j / nz, z1 + (z2 - z1) * (j + 1) / nz
				q:block(a, y, c, b, y + 0.03, d, colours[1 + math.floor(rand() * #colours)], "Fabric")
			end
		end
	end)
end

-- A bed pillow `w` wide whose bottom is at y and whose middle is at z, leaning back a little.
local function bedPillow(r: R, x: number, y: number, z: number, w: number, color: Color3)
	local cf = CFrame.new(x, y + 0.22, z) * CFrame.Angles(-0.18, 0, 0)
	r:boxAt(cf, w, 0.44, 0.62, color, "Fabric")
	for _, s in { -1, 1 } do
		cylAt(r, cf * CFrame.new(0, 0, s * 0.31), w, 0.44, color, "Fabric")
	end
end

-- A small bucket of staves with two hoops, water in it and a wire handle.
local function bucket(r: R, x: number, y: number, z: number, rad: number, h: number, wood: Color3)
	staves(r, x, z, y, h, rad, rad, rad, 10, wood)
	r:cyl(x, y + (h - 0.12) / 2, z, h - 0.12, 2 * (rad - 0.06), "y", INSIDE, "Wood")
	clear(r:cyl(x, y + h - 0.09, z, 0.04, 2 * (rad - 0.05), "y", WATER, "Glass"), 0.15)
	for _, f in { 0.15, 0.55 } do
		hoopRing(r, x, z, y + h * f, rad, 10, IRON)
	end
	path(r, {
		V(x - rad - 0.02, y + h * 0.8, z),
		V(x - rad * 0.6, y + h + 0.3, z),
		V(x + rad * 0.6, y + h + 0.3, z),
		V(x + rad + 0.02, y + h * 0.8, z),
	}, 0.04, IRON, "Metal")
end

-- One catalog entry (Build/Catalog explains the fields).
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
	surface: number?,
	style: string,
	build: (r: R) -> (),
	gives: string?, -- holding E gives the player something (Data/Items.Sources)
}

local items: { Item } = {
	{
		id = "rustic_log_bench",
		name = "Log bench",
		cat = "seating",
		price = 110,
		place = "floor",
		size = V(5.6, 3.1, 2.2),
		c1 = "B08A60",
		c2 = "6B4E36",
		tags = { "seat" },
		style = "rustic",
		build = function(r: R)
			local wood, bark = r.c1, r.c2
			-- a log split down the middle, flat side up, on two stumps
			local yc, zc, rad = 1.6, 0.25, 0.5
			local s = rad * 0.4142
			r:block(-2.6, yc - rad, zc - s, 2.6, yc, zc + s, bark, "Wood")
			r:block(-2.6, yc - s, zc - rad, 2.6, yc, zc + rad, bark, "Wood")
			for _, sz in { -1, 1 } do
				r:tri(
					V(0, yc - rad, zc + sz * s),
					V(0, yc - s, zc + sz * rad),
					V(0, yc - s, zc + sz * s),
					5.2,
					bark,
					"Wood"
				)
			end
			r:block(-2.57, yc, zc - rad, 2.57, yc + 0.06, zc + rad, wood, "Wood")
			for _, sx in { -1, 1 } do
				local x0 = sx * 2.6
				r:block(x0, yc - s, zc - rad + 0.08, x0 + sx * 0.03, yc, zc + rad - 0.08, ENDGRAIN, "Wood")
				r:block(x0, yc - rad + 0.08, zc - s + 0.03, x0 + sx * 0.03, yc - s, zc + s - 0.03, ENDGRAIN, "Wood")
				-- the stumps, with a knot or two
				r:cyl(sx * 1.9, 0.6, zc, 1.2, 0.8, "y", bark, "Wood")
				r:lump(CFrame.new(sx * 1.9 + sx * 0.38, 0.5, zc + 0.1), 0.12, 0.18, 0.14, shade(bark, 0.8), "Wood")
			end
			r:lump(CFrame.new(-0.8, yc - 0.35, zc + rad), 0.2, 0.14, 0.08, shade(bark, 0.8), "Wood")
			r:lump(CFrame.new(1.2, yc - 0.3, zc - rad), 0.16, 0.12, 0.08, shade(bark, 0.8), "Wood")
			-- a back of two branch posts and two thinner logs
			for _, sx in { -1, 1 } do
				rod(r, V(sx * 1.9, yc - 0.1, -0.25), V(sx * 1.95, 3.05, -0.7), 0.18, bark, "Wood")
			end
			r:cyl(0, 2.85, -0.64, 4.9, 0.34, "x", bark, "Wood")
			r:cyl(0, 2.25, -0.45, 4.4, 0.26, "x", shade(bark, 1.1), "Wood")
			for _, sx in { -1, 1 } do
				r:cyl(sx * 2.465, 2.85, -0.64, 0.03, 0.26, "x", ENDGRAIN, "Wood")
				r:cyl(sx * 2.215, 2.25, -0.45, 0.03, 0.2, "x", ENDGRAIN, "Wood")
			end
			r:seat(-1.2, yc + 0.06, zc)
			r:seat(1.2, yc + 0.06, zc)
		end,
	},
	{
		id = "rustic_slab_table",
		name = "Slab table",
		cat = "tables",
		price = 220,
		place = "floor",
		size = V(7, 2.7, 3.4),
		c1 = "B5895A",
		c2 = "7A5A3E",
		tags = { "table" },
		surface = 2.6,
		style = "rustic",
		build = function(r: R)
			local wood, frame = r.c1, r.c2
			-- a thick slab with its bark left on the edges, in three uneven runs
			local runs: { { any } } = {
				{ -3.3, -1.0, -1.38, 1.42, { -2.9, -1.7 } },
				{ -1.2, 1.4, -1.45, 1.36, { -0.6, 0.7 } },
				{ 1.2, 3.3, -1.32, 1.45, { 1.8, 2.9 } },
			}
			for _, run in runs do
				r:piece(function(q: R)
					q:block(run[1], 2.25, run[3], run[2], 2.6, run[4], wood, "Wood")
					for i, x in run[5] do
						for _, side in { run[3], run[4] } do
							local sz = if side > 0 then 1 else -1
							q:lump(CFrame.new(x, 2.42, side + sz * 0.03), 0.9 + i * 0.15, 0.26, 0.2, BARK, "Wood")
						end
					end
				end)
			end
			-- a crack across it, held by a bow tie key of darker wood
			local dark = shade(frame, 0.7)
			r:beam(V(-0.25, 2.615, 0.25), V(0.03, 2.615, 0.64), 0.04, 0.03, dark, "Wood")
			r:beam(V(0.27, 2.615, 0.96), V(0.55, 2.615, 1.3), 0.04, 0.03, dark, "Wood")
			local key = CFrame.new(0.15, 2.615, 0.8) * CFrame.Angles(0, math.atan2(0.41, 0.3), 0)
			for _, s in { -1, 1 } do
				local a = (key * CFrame.new(s * 0.2, 0, -0.12)).Position
				local b = (key * CFrame.new(s * 0.2, 0, 0.12)).Position
				r:tri(a, b, key.Position, 0.03, dark, "Wood")
			end
			r:boxAt(key, 0.08, 0.03, 0.08, dark, "Wood")
			-- two X trestles of rough timber, a stretcher through them pinned with wedges
			for _, sx in { -1, 1 } do
				local x = sx * 2.5
				r:beam(V(x, 0.12, -1.15), V(x, 2.05, 1.0), 0.22, 0.3, frame, "Wood")
				r:beam(V(x, 0.12, 1.15), V(x, 2.05, -1.0), 0.22, 0.3, frame, "Wood")
				r:block(x - 0.14, 0, -1.35, x + 0.14, 0.24, 1.35, frame, "Wood")
				r:block(x - 0.14, 2.0, -1.3, x + 0.14, 2.25, 1.3, frame, "Wood")
				r:block(sx * 2.74, 0.9, -0.04, sx * 2.8, 1.4, 0.04, dark, "Wood")
			end
			r:block(-2.74, 1.0, -0.11, 2.74, 1.3, 0.11, frame, "Wood")
		end,
	},
	{
		id = "rustic_wood_stove",
		name = "Wood stove",
		gives = "cook", -- holding E gives something (Data/Items.Sources)
		cat = "kitchen",
		price = 320,
		place = "floor",
		size = V(3.2, 8, 3),
		c1 = "4A4648",
		c2 = "B8A27A",
		tags = { "kitchen" },
		style = "rustic",
		build = function(r: R)
			local iron, trim = r.c1, r.c2
			local face = shade(iron, 1.18)
			-- a stone pad, four legs, the firebox and its cooking top
			r:block(-1.6, 0, -1.5, 1.6, 0.12, 1.5, Color3.fromRGB(150, 146, 140), "Slate")
			for _, sx in { -1, 1 } do
				for _, sz in { -1, 1 } do
					r:block(sx * 0.85 - 0.1, 0.12, sz * 0.7 - 0.1, sx * 0.85 + 0.1, 0.72, sz * 0.7 + 0.1, iron, "Metal")
					r:cyl(sx * 0.85, 0.17, sz * 0.7, 0.1, 0.28, "y", iron, "Metal")
				end
			end
			r:block(-1.15, 0.62, -1.05, 1.15, 0.72, 0.95, iron, "Metal")
			r:block(-1.05, 0.72, -0.95, 1.05, 2.55, 0.85, iron, "Metal")
			r:block(-1.2, 2.55, -1.1, 1.2, 2.68, 1.0, iron, "Metal")
			for _, sx in { -1, 1 } do
				r:cyl(sx * 0.5, 2.695, 0.1, 0.03, 0.62, "y", face, "Metal")
				for _, y in { 1.2, 1.6, 2.0 } do
					r:block(sx * 1.05, y, -0.8, sx * 1.08, y + 0.08, 0.7, face, "Metal")
				end
			end
			-- the door with a window on the fire, hinges, a latch and a vent; an ash drawer
			r:block(-0.7, 1.0, 0.85, 0.7, 2.3, 0.93, face, "Metal")
			local glow = r:block(-0.5, 1.32, 0.93, 0.5, 2.05, 0.96, Color3.fromRGB(255, 150, 80), "SmoothPlastic")
			r:glow(glow, 16, 1.2, Color3.fromRGB(255, 160, 90))
			for _, x in { -0.17, 0.17 } do
				r:block(x - 0.03, 1.32, 0.96, x + 0.03, 2.05, 0.99, iron, "Metal")
			end
			r:piece(function(q: R)
				q:block(-0.56, 1.26, 0.93, 0.56, 1.32, 0.99, iron, "Metal")
				q:block(-0.56, 2.05, 0.93, 0.56, 2.11, 0.99, iron, "Metal")
				q:block(-0.56, 1.32, 0.93, -0.5, 2.05, 0.99, iron, "Metal")
				q:block(0.5, 1.32, 0.93, 0.56, 2.05, 0.99, iron, "Metal")
			end)
			for _, y in { 1.25, 2.05 } do
				r:cyl(-0.72, y, 0.93, 0.2, 0.08, "y", trim, "Metal")
			end
			r:cyl(0.6, 1.65, 1.02, 0.14, 0.08, "z", trim, "Metal")
			r:ball(0.6, 1.65, 1.12, 0.14, trim, "Metal")
			r:cyl(0, 1.14, 0.95, 0.04, 0.2, "z", trim, "Metal")
			r:block(-0.6, 0.76, 0.85, 0.6, 0.94, 0.9, face, "Metal")
			r:block(-0.12, 0.8, 0.9, 0.12, 0.88, 0.94, trim, "Metal")
			-- a towel rail along the front with a tea towel over it
			for _, sx in { -1, 1 } do
				r:block(sx * 0.95 - 0.04, 2.4, 0.85, sx * 0.95 + 0.04, 2.5, 1.1, trim, "Metal")
			end
			r:cyl(0, 2.45, 1.08, 2.0, 0.06, "x", trim, "Metal")
			r:block(0.2, 1.95, 1.115, 0.7, 2.49, 1.15, CREAM, "Fabric")
			r:block(0.2, 2.45, 1.0, 0.7, 2.49, 1.115, CREAM, "Fabric")
			for _, x in { 0.3, 0.55 } do
				r:block(x, 1.95, 1.15, x + 0.08, 2.49, 1.18, GINGHAM, "Fabric")
			end
			-- the flue: a collar, joints and a damper, turning into the wall at the top
			r:cyl(0, 2.78, -0.5, 0.12, 0.72, "y", iron, "Metal")
			r:cyl(0, 4.95, -0.5, 4.3, 0.6, "y", iron, "Metal")
			for _, y in { 3.6, 5.2, 6.6 } do
				r:cyl(0, y, -0.5, 0.08, 0.66, "y", shade(iron, 0.8), "Metal")
			end
			r:cyl(0, 4.2, -0.5, 0.9, 0.05, "x", iron, "Metal")
			r:cyl(0.48, 4.2, -0.5, 0.12, 0.14, "x", trim, "Metal")
			r:ball(0, 7.3, -0.5, 0.62, iron, "Metal")
			r:cyl(0, 7.3, -0.985, 0.97, 0.6, "z", iron, "Metal")
			r:cyl(0, 7.3, -1.47, 0.06, 0.95, "z", trim, "Metal")
			-- a kettle warming on the right hand lid
			local enamel = Color3.fromRGB(124, 152, 170)
			r:lump(CFrame.new(0.5, 2.98, 0.1), 0.72, 0.56, 0.72, enamel, "Metal")
			r:cyl(0.5, 3.28, 0.1, 0.06, 0.36, "y", enamel, "Metal")
			r:ball(0.5, 3.35, 0.1, 0.12, IRON, "Metal")
			rod(r, V(0.78, 2.9, 0.1), V(1.02, 3.14, 0.1), 0.1, enamel, "Metal")
			path(
				r,
				{ V(0.5, 3.18, -0.22), V(0.5, 3.52, -0.06), V(0.5, 3.52, 0.26), V(0.5, 3.18, 0.42) },
				0.04,
				IRON,
				"Metal"
			)
			r:cyl(0.5, 3.52, 0.1, 0.3, 0.1, "z", Color3.fromRGB(120, 88, 60), "Wood")
		end,
	},
	{
		id = "rustic_barrel_table",
		name = "Barrel table",
		cat = "tables",
		price = 120,
		place = "floor",
		size = V(2.8, 3.3, 2.8),
		c1 = "A87A4E",
		c2 = "5A5560",
		tags = { "table" },
		surface = 3.23,
		style = "rustic",
		build = function(r: R)
			-- an old barrel stood on end: bulging staves, four iron hoops and its bung
			local rEnd, rMid = 0.92, 1.04
			r:cyl(0, 1.5, 0, 2.96, 2 * (rEnd - 0.06), "y", INSIDE, "Wood")
			staves(r, 0, 0, 0, 3.0, rEnd, rMid, rEnd, 14, r.c1)
			for _, y in { 0.22, 0.95, 2.05, 2.78 } do
				local rad = rEnd + (rMid - rEnd) * (1 - math.abs(y - 1.5) / 1.5)
				hoopRing(r, 0, 0, y, rad, 14, r.c2)
			end
			r:cyl(0, 1.5, 1.12, 0.12, 0.22, "z", shade(r.c1, 0.7), "Wood")
			-- a round top of planks
			local top = shade(r.c1, 1.12)
			r:cyl(0, 3.1, 0, 0.2, 2.7, "y", top, "Wood")
			r:piece(function(q: R)
				for _, x in { -0.81, -0.27, 0.27, 0.81 } do
					local c = math.sqrt(1.35 ^ 2 - x ^ 2) * 0.92
					q:block(x - 0.02, 3.2, -c, x + 0.02, 3.23, c, shade(top, 0.75), "Wood")
				end
			end)
		end,
	},
	{
		id = "rustic_iron_bed",
		name = "Iron bed",
		cat = "beds",
		price = 300,
		place = "floor",
		size = V(4.6, 4.8, 7.6),
		c1 = "3E3B40",
		c2 = "B87B6A",
		tags = { "bed" },
		style = "rustic",
		build = function(r: R)
			local iron, quilt = r.c1, r.c2
			-- four posts with brass knobs and feet
			for _, sz in { -1, 1 } do
				local h = if sz < 0 then 4.4 else 3.1
				for _, sx in { -1, 1 } do
					local x, z = sx * 2.05, sz * 3.55
					r:cyl(x, h / 2, z, h, 0.18, "y", iron, "Metal")
					r:ball(x, h + 0.1, z, 0.3, BRASS, "Metal")
					r:cyl(x, h - 0.5, z, 0.06, 0.24, "y", BRASS, "Metal")
					r:cyl(x, 0.05, z, 0.1, 0.26, "y", BRASS, "Metal")
				end
			end
			-- a head and a foot of curved rails and spindles, a rosette in the head's middle
			local function arch(z: number, base: number, rise: number)
				local pts = {}
				for i = 0, 6 do
					local x = -2.05 + i * 4.1 / 6
					table.insert(pts, V(x, base + rise * (1 - (x / 2.05) ^ 2), z))
				end
				path(r, pts, 0.12, iron, "Metal")
			end
			arch(-3.55, 3.75, 0.45)
			arch(3.55, 2.6, 0.2)
			for _, rail in { { -3.55, 1.5 }, { -3.55, 2.0 }, { 3.55, 1.5 } } do
				r:cyl(0, rail[2], rail[1], 4.1, 0.1, "x", iron, "Metal")
			end
			for i = -4, 4 do
				local x = i * 0.4
				rod(r, V(x, 1.5, -3.55), V(x, 3.75 + 0.45 * (1 - (x / 2.05) ^ 2), -3.55), 0.06, iron, "Metal")
			end
			for i = -3, 3 do
				local x = i * 0.5
				rod(r, V(x, 1.5, 3.55), V(x, 2.6 + 0.2 * (1 - (x / 2.05) ^ 2), 3.55), 0.06, iron, "Metal")
			end
			r:cyl(0, 2.9, -3.55, 0.06, 0.5, "z", BRASS, "Metal")
			r:cyl(0, 2.9, -3.55, 0.1, 0.3, "z", iron, "Metal")
			-- side rails, a ticking mattress and a patchwork quilt
			for _, sx in { -1, 1 } do
				r:block(sx * 2.05 - 0.06, 1.0, -3.5, sx * 2.05 + 0.06, 1.2, 3.5, iron, "Metal")
			end
			r:block(-1.95, 1.05, -3.45, 1.95, 1.15, 3.45, shade(iron, 0.8), "Metal")
			r:block(-1.85, 1.15, -3.4, 1.85, 1.85, 3.4, Color3.fromRGB(236, 232, 222), "Fabric")
			for _, x in { -1.2, -0.4, 0.4, 1.2 } do
				r:block(x - 0.04, 1.15, 3.4, x + 0.04, 1.85, 3.43, DUSK, "Fabric")
			end
			r:block(-1.92, 1.42, -1.0, 1.92, 1.92, 3.46, quilt, "Fabric")
			patchwork(
				r,
				-1.92,
				1.92,
				-1.0,
				3.46,
				1.92,
				4,
				6,
				{ quilt, CREAM, shade(quilt, 0.8), MUSTARD, SAGE, CREAM },
				5
			)
			for _, sx in { -1, 1 } do
				r:block(sx * 1.92, 1.42, -1.0, sx * 1.95, 1.52, 3.46, shade(quilt, 0.75), "Fabric")
			end
			r:cyl(0, 1.92, -1.0, 3.9, 0.3, "x", SHEET, "Fabric")
			for _, sx in { -1, 1 } do
				bedPillow(r, sx * 0.85, 1.85, -2.85, 1.55, CREAM)
			end
			-- a striped wool blanket folded at the foot
			r:block(-1.95, 1.95, 2.3, 1.95, 2.13, 3.2, WOOL, "Fabric")
			for _, z in { 2.45, 2.95 } do
				r:block(-1.98, 1.95, z, 1.98, 2.16, z + 0.12, GINGHAM, "Fabric")
			end
			r:sleep(0, 1.95, 0.4)
		end,
	},
	{
		id = "rustic_hay_seat",
		name = "Hay bale seat",
		cat = "seating",
		price = 50,
		place = "floor",
		size = V(3.2, 1.9, 1.9),
		c1 = "D9BC74",
		c2 = "A8634F",
		tags = { "seat" },
		style = "rustic",
		build = function(r: R)
			local hay = r.c1
			-- a bale pressed in slices, each a touch different, bound with twine
			local tops = { 1.46, 1.5, 1.47, 1.45, 1.5, 1.46 }
			local fronts = { 0.77, 0.8, 0.78, 0.76, 0.8, 0.77 }
			for i = 1, 6 do
				local x = -1.5 + (i - 1) * 0.5
				local col = if i % 3 == 0 then shade(hay, 0.94) elseif i % 3 == 1 then hay else shade(hay, 1.05)
				r:block(x, 0, -fronts[7 - i], x + 0.5, tops[i], fronts[i], col, "Fabric")
			end
			for _, x in { -0.75, 0.75 } do
				r:block(x - 0.03, 1.5, -0.83, x + 0.03, 1.53, 0.83, TWINE, "Fabric")
				r:block(x - 0.03, 0, 0.8, x + 0.03, 1.53, 0.83, TWINE, "Fabric")
				r:block(x - 0.03, 0, -0.83, x + 0.03, 1.53, -0.8, TWINE, "Fabric")
			end
			-- loose straws sticking out
			local rand = rng(3)
			r:piece(function(q: R)
				q:box(0, 0.7, 0, 0.1, 0.1, 0.1, hay, "Fabric")
				for i = 0, 13 do
					local x = -1.4 + rand() * 2.8
					local side = if i % 2 == 0 then 1 else -1
					local a = V(x, 0.3 + rand() * 1.1, side * 0.7)
					local b = a + V((rand() - 0.5) * 0.3, (rand() - 0.3) * 0.25, side * (0.25 + rand() * 0.15))
					q:beam(a, b, 0.03, 0.03, if i % 3 == 0 then shade(hay, 1.12) else hay, "Fabric")
				end
			end)
			-- a plaid blanket folded on top and hanging over the front
			local plaid = r.c2
			r:block(-1.3, 1.45, -0.7, 0.3, 1.58, 0.86, plaid, "Fabric")
			r:block(-1.3, 0.95, 0.86, 0.3, 1.58, 0.9, plaid, "Fabric")
			for _, z in { -0.35, 0.35 } do
				r:block(-1.3, 1.58, z, 0.3, 1.61, z + 0.1, shade(plaid, 0.75), "Fabric")
			end
			for _, x in { -0.9, -0.3 } do
				r:block(x, 1.61, -0.7, x + 0.1, 1.64, 0.86, CREAM, "Fabric")
				r:block(x, 0.95, 0.93, x + 0.1, 1.58, 0.96, CREAM, "Fabric")
			end
			r:block(-1.3, 1.2, 0.9, 0.3, 1.3, 0.93, shade(plaid, 0.75), "Fabric")
			for i = 0, 7 do
				r:cyl(-1.2 + i * 0.2, 0.89, 0.88, 0.12, 0.05, "y", plaid, "Fabric")
			end
			r:seat(-0.5, 1.58, 0.05)
			r:seat(0.9, 1.5, 0.05)
		end,
	},
	{
		id = "rustic_dresser",
		name = "Plank dresser",
		cat = "storage",
		price = 260,
		place = "floor",
		size = V(4.6, 5.6, 2),
		c1 = "A57B55",
		c2 = "3E3A3C",
		tags = { "storage", "mirror" },
		style = "rustic",
		build = function(r: R)
			local wood, iron = r.c1, r.c2
			local dk = shade(wood, 0.78)
			local rand = rng(9)
			local function board(): Color3
				return shade(wood, 0.92 + rand() * 0.16)
			end
			-- bracket feet, a plinth, a dark case and sides of two boards each
			for _, sx in { -1, 1 } do
				for _, sz in { -1, 1 } do
					r:block(sx * 1.85, 0, sz * 0.55, sx * 2.2, 0.32, sz * 0.9, dk, "Wood")
				end
			end
			r:block(-2.2, 0.32, -0.92, 2.2, 0.48, 0.92, wood, "Wood")
			r:block(-2.05, 0.48, -0.95, 2.05, 3.5, 0.82, shade(wood, 0.5), "Wood")
			for _, sx in { -1, 1 } do
				r:block(sx * 2.05, 0.48, -0.95, sx * 2.22, 3.5, -0.05, board(), "Wood")
				r:block(sx * 2.05, 0.48, -0.05, sx * 2.22, 3.5, 0.88, board(), "Wood")
			end
			-- a top of three boards, cut a little unevenly
			for i, zs in { { -1.0, -0.36 }, { -0.33, 0.31 }, { 0.34, 0.98 } } do
				r:block(-2.32 + i * 0.02, 3.5, zs[1], 2.33 - i * 0.03, 3.7, zs[2], board(), "Wood")
			end
			-- drawers of two boards each, with iron cup pulls
			local function drawer(x1: number, x2: number, y1: number, y2: number)
				local ym = (y1 + y2) / 2
				r:block(x1, y1, 0.85, x2, ym, 0.93, board(), "Wood")
				r:block(x1, ym, 0.85, x2, y2, 0.93, board(), "Wood")
			end
			local function pull(x: number, y: number)
				r:block(x - 0.22, y - 0.02, 0.93, x + 0.22, y + 0.08, 0.98, iron, "Metal")
				r:cyl(x, y - 0.04, 0.97, 0.44, 0.08, "x", iron, "Metal")
			end
			drawer(-2.0, 2.0, 0.55, 1.45)
			drawer(-2.0, 2.0, 1.52, 2.42)
			drawer(-2.0, -0.04, 2.49, 3.42)
			drawer(0.04, 2.0, 2.49, 3.42)
			for _, sx in { -1, 1 } do
				pull(sx * 1.0, 1.0)
				pull(sx * 1.0, 1.97)
				pull(sx * 1.02, 2.95)
			end
			-- iron corner straps with rivets
			for _, sx in { -1, 1 } do
				for _, y in { 0.55, 3.0 } do
					r:block(sx * 2.22, y, 0.5, sx * 2.25, y + 0.45, 0.88, iron, "Metal")
					r:block(sx * 2.05, y, 0.88, sx * 2.25, y + 0.45, 0.91, iron, "Metal")
					r:ball(sx * 2.15, y + 0.22, 0.92, 0.06, shade(iron, 1.3), "Metal")
					r:ball(sx * 2.26, y + 0.22, 0.65, 0.06, shade(iron, 1.3), "Metal")
				end
			end
			-- a swing mirror on two posts, a lace runner and a little vase
			r:block(-1.25, 3.7, -0.95, 1.25, 3.82, -0.6, wood, "Wood")
			for _, sx in { -1, 1 } do
				r:block(sx * 1.1 - 0.07, 3.82, -0.85, sx * 1.1 + 0.07, 5.5, -0.71, dk, "Wood")
				r:ball(sx * 1.1, 5.56, -0.78, 0.16, dk, "Wood")
				r:cyl(sx * 1.0, 4.7, -0.78, 0.08, 0.12, "x", BRASS, "Metal")
			end
			local f = CFrame.new(0, 4.7, -0.78) * CFrame.Angles(-0.08, 0, 0)
			r:piece(function(q: R)
				q:boxAt(f * CFrame.new(0, 0.69, 0), 1.9, 0.12, 0.08, dk, "Wood")
				q:boxAt(f * CFrame.new(0, -0.69, 0), 1.9, 0.12, 0.08, dk, "Wood")
				q:boxAt(f * CFrame.new(-0.89, 0, 0), 0.12, 1.26, 0.08, dk, "Wood")
				q:boxAt(f * CFrame.new(0.89, 0, 0), 0.12, 1.26, 0.08, dk, "Wood")
				q:box(0, 4.7, -0.78, 0.02, 0.02, 0.02, dk, "Wood")
			end)
			r:boxAt(f * CFrame.new(0, 0, -0.01), 1.66, 1.26, 0.03, MIRROR, "Glass")
			r:boxAt(f * CFrame.new(0.3, 0.15, 0.02) * CFrame.Angles(0, 0, -0.6), 0.1, 0.8, 0.02, C.White, "Glass")
			r:block(-1.6, 3.7, -0.4, 1.6, 3.73, 0.5, CREAM, "Fabric")
			r:cyl(1.4, 3.93, 0.1, 0.4, 0.24, "y", STONEWARE, "SmoothPlastic")
			rod(r, V(1.4, 4.1, 0.1), V(1.5, 4.55, 0.12), 0.03, C.DarkLeaf, "SmoothPlastic")
			r:ball(1.5, 4.58, 0.12, 0.16, ROSE, "Fabric")
			r:cyl(-1.3, 3.75, 0.15, 0.04, 0.4, "y", BRASS, "Metal")
		end,
	},
	{
		id = "rustic_hurricane",
		name = "Hurricane lantern",
		cat = "lights",
		price = 55,
		place = "ceiling",
		size = V(1.4, 3.6, 1.4),
		c1 = "4F4A46",
		c2 = "F2E2C0",
		tags = { "light" },
		style = "rustic",
		build = function(r: R)
			local iron = r.c1
			-- a hook in the ceiling and a chain down
			r:cyl(0, -0.04, 0, 0.08, 0.5, "y", iron, "Metal")
			r:cyl(0, -0.15, 0, 0.14, 0.08, "y", iron, "Metal")
			r:piece(function(q: R)
				for i = 0, 8 do
					local y = -0.3 - i * 0.15
					q:boxAt(
						CFrame.new(0, y, 0) * CFrame.Angles(0, (i % 2) * math.pi / 2, 0),
						0.1,
						0.17,
						0.03,
						iron,
						"Metal"
					)
				end
			end)
			-- the cap, the glass globe in its wire guard, the fuel tank and the side tubes
			r:cone(0, -1.7, 0, 0.14, 0.26, iron, "Metal")
			r:cyl(0, -1.84, 0, 0.14, 0.3, "y", iron, "Metal")
			r:cyl(0, -1.97, 0, 0.12, 0.5, "y", iron, "Metal")
			clear(r:lump(CFrame.new(0, -2.55, 0), 0.7, 0.95, 0.7, r.c2, "Glass"), 0.45)
			local flame = r:ball(0, -2.72, 0, 0.16, C.Warm, "SmoothPlastic")
			r:glow(flame, 14, 1.1)
			r:cyl(0, -2.86, 0, 0.12, 0.06, "y", CREAM, "Fabric")
			r:cyl(0, -3.0, 0, 0.1, 0.4, "y", BRASS, "Metal")
			for k = 0, 3 do
				local a = k * math.pi / 2 + math.pi / 4
				local dx, dz = math.cos(a), math.sin(a)
				path(
					r,
					{ V(dx * 0.22, -2.02, dz * 0.22), V(dx * 0.42, -2.55, dz * 0.42), V(dx * 0.3, -3.05, dz * 0.3) },
					0.035,
					iron,
					"Metal"
				)
			end
			r:cyl(0, -2.55, 0, 0.04, 0.86, "y", iron, "Metal")
			r:cyl(0, -3.2, 0, 0.3, 0.9, "y", iron, "Metal")
			r:cyl(0, -3.38, 0, 0.06, 0.8, "y", shade(iron, 0.8), "Metal")
			for _, sx in { -1, 1 } do
				path(
					r,
					{ V(sx * 0.4, -3.15, 0), V(sx * 0.52, -3.1, 0), V(sx * 0.52, -2.0, 0), V(sx * 0.24, -1.97, 0) },
					0.08,
					iron,
					"Metal"
				)
			end
			r:cyl(0.24, -2.98, 0.3, 0.1, 0.1, "z", BRASS, "Metal")
			path(
				r,
				{ V(-0.45, -3.05, 0), V(-0.3, -1.62, 0), V(0, -1.55, 0), V(0.3, -1.62, 0), V(0.45, -3.05, 0) },
				0.03,
				iron,
				"Metal"
			)
		end,
	},
	{
		id = "rustic_barn_light",
		name = "Barn light",
		cat = "lights",
		price = 60,
		place = "wall",
		size = V(1.8, 2.4, 2.4),
		c1 = "4E6B5C",
		c2 = "3E3A3C",
		tags = { "light" },
		style = "rustic",
		build = function(r: R)
			local shadeCol, iron = r.c1, r.c2
			-- a round wall plate, a gooseneck arm with a brace under it
			r:cyl(0, 1.9, 0.04, 0.08, 0.55, "z", iron, "Metal")
			for _, sx in { -1, 1 } do
				r:cyl(sx * 0.17, 1.9, 0.095, 0.03, 0.06, "z", shade(iron, 1.4), "Metal")
			end
			path(
				r,
				{ V(0, 1.9, 0.08), V(0, 2.12, 0.55), V(0, 2.14, 1.05), V(0, 1.95, 1.4), V(0, 1.6, 1.52) },
				0.1,
				iron,
				"Metal"
			)
			path(r, { V(0, 1.55, 0.08), V(0, 1.62, 0.4), V(0, 1.95, 0.75) }, 0.05, iron, "Metal")
			r:cyl(0, 1.62, 0.42, 0.04, 0.16, "x", iron, "Metal")
			-- a wide enamel shade in steps, white inside, and the bulb under it
			r:cyl(0, 1.55, 1.52, 0.14, 0.22, "y", iron, "Metal")
			r:cyl(0, 1.46, 1.52, 0.1, 0.42, "y", shadeCol, "Metal")
			r:cyl(0, 1.37, 1.52, 0.1, 0.8, "y", shadeCol, "Metal")
			r:cyl(0, 1.28, 1.52, 0.1, 1.2, "y", shadeCol, "Metal")
			r:cyl(0, 1.2, 1.52, 0.08, 1.56, "y", shadeCol, "Metal")
			r:cyl(0, 1.145, 1.52, 0.03, 1.5, "y", C.White, "Metal")
			local bulb = r:ball(0, 1.02, 1.52, 0.34, C.Warm, "SmoothPlastic")
			r:glow(bulb, 16, 1.2)
		end,
	},
	{
		id = "rustic_peg_rack",
		name = "Peg rack",
		cat = "walldecor",
		price = 70,
		place = "wall",
		size = V(5, 2.6, 1.2),
		c1 = "9C7650",
		c2 = "3E3A3C",
		tags = { "storage" },
		style = "rustic",
		build = function(r: R)
			local wood = r.c1
			-- a board with five pegs, a little shelf on top on two brackets
			r:block(-2.4, 1.0, 0, 2.4, 1.7, 0.16, wood, "Wood")
			for _, x in { -2.2, 0, 2.2 } do
				r:cyl(x, 1.6, 0.175, 0.03, 0.08, "z", r.c2, "Metal")
			end
			r:block(-2.45, 1.7, 0, 2.45, 1.8, 0.6, wood, "Wood")
			for _, x in { -1.5, 1.5 } do
				r:tri(V(x, 1.7, 0.16), V(x, 1.7, 0.52), V(x, 1.32, 0.16), 0.1, wood, "Wood")
			end
			local peg = shade(wood, 1.12)
			for _, x in { -2.0, -1.0, 0, 1.0, 2.0 } do
				r:cyl(x, 1.35, 0.32, 0.32, 0.1, "z", peg, "Wood")
				r:cyl(x, 1.35, 0.5, 0.06, 0.16, "z", peg, "Wood")
			end
			-- a straw hat with a ribbon
			r:cyl(-2.0, 1.15, 0.6, 0.05, 1.0, "z", STRAW, "Fabric")
			r:cyl(-2.0, 1.15, 0.73, 0.22, 0.56, "z", STRAW, "Fabric")
			r:cyl(-2.0, 1.15, 0.68, 0.06, 0.62, "z", ROSE, "Fabric")
			-- a coil of rope
			local rope = Color3.fromRGB(196, 170, 128)
			r:piece(function(q: R)
				q:box(-1.0, 1.25, 0.4, 0.18, 0.14, 0.18, shade(rope, 0.85), "Fabric")
				ring(q, V(-1.0, 0.95, 0.36), Vector3.xAxis, Vector3.yAxis, 0.32, 10, 0.1, 0.1, rope, "Fabric")
				ring(
					q,
					V(-1.0, 0.93, 0.44),
					Vector3.xAxis,
					Vector3.yAxis,
					0.3,
					10,
					0.1,
					0.1,
					shade(rope, 0.92),
					"Fabric",
					0.5
				)
			end)
			-- a basket of eggs hanging by its handle
			path(
				r,
				{ V(-0.3, 0.85, 0.42), V(-0.15, 1.3, 0.42), V(0.15, 1.3, 0.42), V(0.3, 0.85, 0.42) },
				0.06,
				TWINE,
				"Fabric"
			)
			r:block(-0.38, 0.35, 0.18, 0.38, 0.85, 0.7, TWINE, "Fabric")
			for _, y in { 0.48, 0.66 } do
				r:block(-0.38, y, 0.7, 0.38, y + 0.06, 0.73, shade(TWINE, 0.8), "Fabric")
			end
			r:block(-0.41, 0.8, 0.15, 0.41, 0.9, 0.76, shade(TWINE, 0.9), "Fabric")
			for i, p in { { -0.18, 0.4 }, { 0.05, 0.5 }, { 0.2, 0.36 } } do
				r:lump(
					CFrame.new(p[1], 0.95, p[2]),
					0.18,
					0.24,
					0.18,
					if i == 2 then CREAM else Color3.fromRGB(214, 176, 140),
					"SmoothPlastic"
				)
			end
			-- a checked tea towel on a loop
			r:block(0.7, 0.5, 0.45, 1.3, 1.25, 0.49, CREAM, "Fabric")
			r:piece(function(q: R)
				for _, x in { 0.78, 0.98, 1.18 } do
					q:block(x, 0.5, 0.49, x + 0.08, 1.25, 0.52, GINGHAM, "Fabric")
				end
				for _, y in { 0.6, 0.85, 1.1 } do
					q:block(0.7, y, 0.52, 1.3, y + 0.08, 0.55, GINGHAM, "Fabric")
				end
			end)
			r:block(0.96, 1.25, 0.36, 1.04, 1.42, 0.5, CREAM, "Fabric")
			-- lavender drying upside down
			herbs(r, V(2.0, 1.28, 0.48), 0.62, LAVENDER, 4)
			-- on the shelf: two jars and a candle in a tin holder
			jar(r, -1.8, 1.8, 0.3, 0.34, 0.44, Color3.fromRGB(176, 84, 92), GINGHAM)
			jar(r, -1.3, 1.8, 0.3, 0.3, 0.36, Color3.fromRGB(226, 170, 90), nil)
			r:cyl(1.6, 1.83, 0.3, 0.06, 0.4, "y", C.Metal, "Metal")
			r:cyl(1.6, 2.0, 0.3, 0.28, 0.16, "y", CREAM, "SmoothPlastic")
			r:block(1.8, 1.83, 0.26, 1.96, 1.86, 0.34, C.Metal, "Metal")
		end,
	},
	{
		id = "rustic_churn",
		name = "Butter churn",
		cat = "kitchen",
		price = 70,
		place = "floor",
		size = V(1.6, 4, 1.6),
		c1 = "B58A5C",
		c2 = "5A5560",
		tags = { "kitchen" },
		style = "rustic",
		build = function(r: R)
			-- a tall tapered churn of staves on a board, a lid and the dasher's handle
			r:block(-0.75, 0, -0.75, 0.75, 0.1, 0.75, shade(r.c1, 0.8), "Wood")
			r:cyl(0, 1.4, 0, 2.56, 2 * (0.45 - 0.06), "y", INSIDE, "Wood")
			staves(r, 0, 0, 0.1, 2.6, 0.6, 0.525, 0.45, 12, r.c1)
			for _, y in { 0.35, 1.4, 2.45 } do
				hoopRing(r, 0, 0, y, 0.6 - 0.15 * (y - 0.1) / 2.6, 12, r.c2)
			end
			for _, sx in { -1, 1 } do
				r:block(sx * 0.42, 2.18, -0.1, sx * 0.66, 2.32, 0.1, r.c1, "Wood")
			end
			r:cyl(0, 2.76, 0, 0.12, 1.0, "y", r.c1, "Wood")
			r:cyl(0, 2.86, 0, 0.08, 0.4, "y", shade(r.c1, 0.85), "Wood")
			local pale = shade(r.c1, 1.15)
			r:cyl(0, 3.35, 0, 1.1, 0.12, "y", pale, "Wood")
			r:cyl(0, 3.9, 0, 0.5, 0.12, "x", pale, "Wood")
			-- a pat of butter in a little dish beside it
			r:cyl(0.55, 0.13, 0.55, 0.06, 0.34, "y", STONEWARE, "SmoothPlastic")
			r:block(0.45, 0.16, 0.48, 0.65, 0.26, 0.62, Color3.fromRGB(246, 226, 150), "SmoothPlastic")
		end,
	},
	{
		id = "rustic_crate_shelf",
		name = "Crate shelf",
		cat = "storage",
		price = 130,
		place = "floor",
		size = V(4.8, 5, 1.7),
		c1 = "C29A6A",
		c2 = "8A6A4A",
		tags = { "storage" },
		style = "rustic",
		build = function(r: R)
			-- open crates stacked on their sides, each of slats with gaps between
			local zb, zf = -0.8, 0.7
			local function crate(x1: number, y1: number, x2: number, y2: number, col: Color3)
				local t = 0.08
				local ym, zm = (y1 + y2) / 2, (zb + zf) / 2
				r:piece(function(q: R)
					for _, yy in { { y1, y1 + t }, { y2 - t, y2 } } do
						q:block(x1, yy[1], zb, x2, yy[2], zm - 0.02, col, "Wood")
						q:block(x1, yy[1], zm + 0.02, x2, yy[2], zf, col, "Wood")
					end
					for _, xx in { { x1, x1 + t }, { x2 - t, x2 } } do
						q:block(xx[1], y1, zb, xx[2], ym - 0.03, zf, col, "Wood")
						q:block(xx[1], ym + 0.03, zb, xx[2], y2, zf, col, "Wood")
					end
					q:block(x1, y1, zb, x2, ym - 0.03, zb + t, col, "Wood")
					q:block(x1, ym + 0.03, zb, x2, y2, zb + t, col, "Wood")
					q:block(x1 + t, y1 + t, zf - 0.1, x1 + t + 0.08, y2 - t, zf, shade(col, 0.9), "Wood")
					q:block(x2 - t - 0.08, y1 + t, zf - 0.1, x2 - t, y2 - t, zf, shade(col, 0.9), "Wood")
				end)
			end
			local a, b = r.c1, r.c2
			crate(-2.35, 0, -0.8, 1.4, a)
			crate(-0.75, 0, 0.8, 1.4, b)
			crate(0.85, 0, 2.4, 1.4, shade(a, 0.94))
			crate(-1.6, 1.4, -0.05, 2.8, shade(b, 1.1))
			crate(0.05, 1.4, 1.6, 2.8, a)
			crate(-0.8, 2.8, 0.75, 4.2, shade(a, 1.05))
			-- a stencilled mark on one crate's side
			r:block(-2.39, 0.4, -0.4, -2.35, 1.0, 0.3, shade(a, 0.75), "Wood")
			r:block(-2.42, 0.55, -0.2, -2.39, 0.85, 0.1, shade(a, 1.15), "Wood")
			-- jars of preserves, a pile of apples, folded cloths
			for i, f in { Color3.fromRGB(176, 70, 80), Color3.fromRGB(232, 160, 70), Color3.fromRGB(130, 160, 90) } do
				jar(r, -2.4 + i * 0.4, 0.08, 0.05, 0.32, 0.48, f, if i == 2 then GINGHAM else nil)
			end
			local apples = { Color3.fromRGB(186, 74, 64), Color3.fromRGB(150, 176, 90), Color3.fromRGB(196, 92, 70) }
			for i = 0, 4 do
				r:ball(-0.5 + i * 0.25, 0.23, -0.2 + (i % 2) * 0.3, 0.3, apples[1 + i % 3], "SmoothPlastic")
			end
			for i = 0, 2 do
				r:ball(-0.38 + i * 0.25, 0.48, 0.0, 0.3, apples[1 + (i + 1) % 3], "SmoothPlastic")
			end
			for i, col in { CREAM, GINGHAM, SAGE } do
				local y = 0.08 + (i - 1) * 0.2
				r:block(1.0, y, -0.5, 2.25, y + 0.18, 0.4, col, "Fabric")
				r:cyl(1.625, y + 0.09, 0.4, 1.25, 0.18, "x", col, "Fabric")
			end
			-- a watering can in one, books and a tin in the next
			local can = Color3.fromRGB(150, 170, 160)
			r:cyl(-0.85, 1.78, -0.1, 0.55, 0.6, "y", can, "Metal")
			rod(r, V(-0.6, 1.65, 0.05), V(-0.25, 2.1, 0.25), 0.08, can, "Metal")
			r:cyl(-0.23, 2.12, 0.26, 0.06, 0.16, "y", can, "Metal")
			path(
				r,
				{ V(-1.15, 1.95, -0.1), V(-1.1, 2.4, -0.1), V(-0.7, 2.4, -0.1), V(-0.6, 2.05, -0.1) },
				0.06,
				can,
				"Metal"
			)
			for i, col in { Color3.fromRGB(110, 78, 56), DUSK } do
				local y = 1.48 + (i - 1) * 0.14
				r:block(0.25, y, -0.5, 1.15, y + 0.13, 0.3, col, "SmoothPlastic")
				r:block(0.27, y + 0.025, 0.3, 1.13, y + 0.105, 0.33, PAGE, "SmoothPlastic")
			end
			r:cyl(1.35, 1.66, 0, 0.36, 0.3, "y", Color3.fromRGB(186, 110, 96), "Metal")
			-- eggs in the top crate and a pot of rosemary on it
			r:cyl(-0.02, 3.0, -0.1, 0.2, 0.9, "y", TWINE, "Fabric")
			for i, p in { { -0.2, -0.2 }, { 0.1, -0.05 }, { -0.05, 0.2 }, { 0.2, 0.2 } } do
				r:lump(
					CFrame.new(p[1], 3.15, p[2] - 0.1),
					0.18,
					0.24,
					0.18,
					if i % 2 == 0 then CREAM else Color3.fromRGB(214, 176, 140),
					"SmoothPlastic"
				)
			end
			local s = pot(r, 0.0, 4.2, -0.1, 0.44, 0.36, Color3.fromRGB(196, 122, 90))
			r:piece(function(q: R)
				q:box(0.0, s + 0.05, -0.1, 0.06, 0.1, 0.06, C.DarkLeaf, "SmoothPlastic")
				for i = 0, 6 do
					local a = i * 0.9
					q:lump(
						CFrame.new(math.cos(a) * 0.1, s + 0.25, -0.1 + math.sin(a) * 0.08)
							* CFrame.Angles(0, 0, math.cos(a) * 0.25),
						0.07,
						0.48,
						0.07,
						if i % 2 == 0 then C.DarkLeaf else SAGE,
						"SmoothPlastic"
					)
				end
			end)
		end,
	},
	{
		id = "rustic_sink",
		name = "Farmhouse sink",
		cat = "kitchen",
		price = 260,
		place = "floor",
		size = V(4.2, 4.4, 2.6),
		c1 = "EAE4D8",
		c2 = "B98C5E",
		tags = { "kitchen" },
		style = "rustic",
		build = function(r: R)
			local china, wood = r.c1, r.c2
			-- a wooden base on a kick, rails either side of the sink's apron
			r:block(-2.0, 0, -1.15, 2.0, 0.25, 0.9, shade(wood, 0.7), "Wood")
			for _, sx in { -1, 1 } do
				r:block(sx * 1.9, 0.25, -1.2, sx * 2.05, 2.95, 1.0, wood, "Wood")
				r:block(sx * 1.9, 2.3, 0.85, sx * 1.3, 2.95, 1.0, wood, "Wood")
			end
			r:block(-1.9, 0.25, -1.2, 1.9, 2.95, -1.08, shade(wood, 0.8), "Wood")
			r:block(-1.9, 0.25, -1.08, 1.9, 0.4, 1.0, wood, "Wood")
			-- a checked curtain on a rod in place of doors
			r:cyl(0, 2.04, 1.1, 3.8, 0.05, "x", BRASS, "Metal")
			for _, sx in { -1, 1 } do
				for i = 0, 8 do
					local x = sx * (0.12 + i * 0.215)
					r:cyl(
						x,
						1.22,
						if i % 2 == 0 then 1.12 else 1.18,
						1.68,
						0.24,
						"y",
						if i % 2 == 0 then GINGHAM else CREAM,
						"Fabric"
					)
				end
			end
			-- a butcher block worktop round the sink, in planks
			local rand = rng(4)
			local function plank(x1: number, z1: number, x2: number, z2: number)
				r:block(x1, 2.95, z1, x2, 3.25, z2, shade(wood, 0.92 + rand() * 0.14), "Wood")
			end
			for _, zs in { { -1.3, -0.93 }, { -0.93, -0.56 }, { -0.56, -0.2 } } do
				plank(-2.1, zs[1], 2.1, zs[2])
			end
			for i = 0, 3 do
				local z1 = -0.2 + i * 0.325
				plank(-2.1, z1, -1.3, z1 + 0.325)
				plank(1.3, z1, 2.1, z1 + 0.325)
			end
			-- the deep sink with its apron front, a drain in the bottom
			r:block(-1.3, 2.1, 1.05, 1.3, 3.2, 1.25, china, "SmoothPlastic")
			r:block(-1.3, 2.1, -0.2, 1.3, 3.2, 0.0, china, "SmoothPlastic")
			r:block(-1.3, 2.1, 0.0, -1.1, 3.2, 1.05, china, "SmoothPlastic")
			r:block(1.1, 2.1, 0.0, 1.3, 3.2, 1.05, china, "SmoothPlastic")
			r:block(-1.1, 2.1, 0.0, 1.1, 2.3, 1.05, china, "SmoothPlastic")
			r:cyl(0, 2.315, 0.5, 0.03, 0.22, "y", C.Metal, "Metal")
			-- a bridge tap with cross handles
			local tap = C.Metal
			for _, sx in { -1, 1 } do
				local x = sx * 0.45
				r:cyl(x, 3.455, -0.75, 0.41, 0.12, "y", tap, "Metal")
				r:block(x - 0.16, 3.66, -0.79, x + 0.16, 3.72, -0.71, tap, "Metal")
				r:block(x - 0.04, 3.66, -0.91, x + 0.04, 3.72, -0.59, tap, "Metal")
				r:cyl(x, 3.75, -0.75, 0.06, 0.1, "y", C.White, "SmoothPlastic")
			end
			r:cyl(0, 3.6, -0.75, 1.0, 0.1, "x", tap, "Metal")
			path(r, { V(0, 3.6, -0.75), V(0, 4.2, -0.65), V(0, 4.28, -0.3), V(0, 4.0, -0.02) }, 0.1, tap, "Metal")
			r:cyl(0, 3.95, -0.02, 0.1, 0.12, "y", tap, "Metal")
			-- a crock of brushes, a bar of soap on a dish and a tea towel over the edge
			r:cyl(1.7, 3.5, -0.8, 0.5, 0.42, "y", STONEWARE, "SmoothPlastic")
			r:cyl(1.7, 3.6, -0.8, 0.08, 0.48, "y", DELFT, "SmoothPlastic")
			rod(r, V(1.65, 3.6, -0.8), V(1.55, 4.15, -0.7), 0.06, Color3.fromRGB(176, 140, 100), "Wood")
			r:block(1.45, 4.15, -0.75, 1.62, 4.3, -0.62, STRAW, "Fabric")
			rod(r, V(1.75, 3.6, -0.82), V(1.85, 4.05, -0.9), 0.05, Color3.fromRGB(176, 140, 100), "Wood")
			r:lump(CFrame.new(1.87, 4.12, -0.92), 0.14, 0.2, 0.06, Color3.fromRGB(176, 140, 100), "Wood")
			r:cyl(-1.65, 3.27, -0.5, 0.04, 0.42, "y", STONEWARE, "SmoothPlastic")
			r:block(-1.8, 3.29, -0.58, -1.5, 3.39, -0.42, Color3.fromRGB(232, 220, 190), "SmoothPlastic")
			r:block(1.45, 3.25, 0.8, 1.95, 3.28, 1.1, CREAM, "Fabric")
			r:block(1.45, 2.55, 1.1, 1.95, 3.28, 1.14, CREAM, "Fabric")
			r:block(1.55, 2.55, 1.14, 1.65, 3.28, 1.17, GINGHAM, "Fabric")
			r:block(1.75, 2.55, 1.14, 1.85, 3.28, 1.17, GINGHAM, "Fabric")
		end,
	},
	{
		id = "rustic_quilt_chest",
		name = "Quilt chest",
		cat = "storage",
		price = 180,
		place = "floor",
		size = V(4.2, 2.4, 2.2),
		c1 = "8C6448",
		c2 = "3E3A3C",
		tags = { "storage" },
		style = "rustic",
		build = function(r: R)
			local wood, iron = r.c1, r.c2
			local rand = rng(12)
			local function board(): Color3
				return shade(wood, 0.92 + rand() * 0.16)
			end
			-- a chest of wide planks on bun feet
			for _, sx in { -1, 1 } do
				for _, sz in { -1, 1 } do
					r:ball(sx * 1.75, 0.15, sz * 0.75, 0.3, shade(wood, 0.8), "Wood")
				end
			end
			r:block(-1.95, 0.25, -0.85, 1.95, 1.85, 0.85, INSIDE, "Wood")
			for i = 0, 2 do
				r:block(-1.95, 0.25 + i * 0.55, 0.85, 1.95, 0.25 + (i + 1) * 0.55, 0.95, board(), "Wood")
			end
			r:block(-1.95, 0.25, -0.95, 1.95, 1.9, -0.85, board(), "Wood")
			for _, sx in { -1, 1 } do
				r:block(sx * 1.95, 0.25, -0.95, sx * 2.05, 1.9, 0.95, board(), "Wood")
			end
			for _, zs in { { -1.02, -0.35 }, { -0.35, 0.32 }, { 0.32, 1.02 } } do
				r:block(-2.1, 1.9, zs[1], 2.1, 2.08, zs[2], board(), "Wood")
			end
			-- iron strap hinges over the lid, corner plates, a hasp
			for _, x in { -1.2, 1.2 } do
				r:block(x - 0.1, 2.08, -1.02, x + 0.1, 2.11, -0.1, iron, "Metal")
				r:boxAt(CFrame.new(x, 2.095, -0.1) * CFrame.Angles(0, math.pi / 4, 0), 0.14, 0.03, 0.14, iron, "Metal")
				r:block(x - 0.1, 1.2, -1.05, x + 0.1, 2.11, -1.02, iron, "Metal")
				for _, z in { -0.85, -0.5 } do
					r:ball(x, 2.12, z, 0.06, shade(iron, 1.3), "Metal")
				end
			end
			for _, sx in { -1, 1 } do
				for _, y in { 0.25, 1.5 } do
					r:block(sx * 1.7, y, 0.95, sx * 1.95, y + 0.35, 0.98, iron, "Metal")
					r:block(sx * 2.05, y, 0.6, sx * 2.08, y + 0.35, 0.95, iron, "Metal")
				end
			end
			r:block(-0.1, 1.45, 0.95, 0.1, 1.9, 0.98, iron, "Metal")
			r:block(-0.12, 1.9, 1.02, 0.12, 2.06, 1.05, iron, "Metal")
			r:cyl(0, 1.55, 1.02, 0.04, 0.12, "z", iron, "Metal")
			-- rope handles at the ends
			for _, sx in { -1, 1 } do
				path(r, {
					V(sx * 2.05, 1.35, -0.3),
					V(sx * 2.22, 1.08, -0.2),
					V(sx * 2.22, 1.08, 0.2),
					V(sx * 2.05, 1.35, 0.3),
				}, 0.08, TWINE, "Fabric")
				for _, z in { -0.3, 0.3 } do
					r:ball(sx * 2.08, 1.35, z, 0.14, shade(TWINE, 0.85), "Fabric")
				end
			end
			-- a patchwork quilt folded on the lid
			local quilt = ROSE
			r:block(-1.3, 2.08, -0.75, 0.9, 2.26, 0.7, quilt, "Fabric")
			patchwork(
				r,
				-1.3,
				0.9,
				-0.75,
				0.7,
				2.26,
				4,
				3,
				{ quilt, CREAM, MUSTARD, SAGE, DUSK, shade(quilt, 0.8) },
				21
			)
			r:cyl(-0.2, 2.17, 0.7, 2.2, 0.18, "x", quilt, "Fabric")
		end,
	},
	{
		id = "rustic_rocker",
		name = "Log rocker",
		cat = "seating",
		price = 150,
		place = "floor",
		size = V(2.8, 4.6, 3.6),
		c1 = "A87E58",
		c2 = "EDE6D8",
		tags = { "seat" },
		style = "rustic",
		build = function(r: R)
			local wood = r.c1
			local dk = shade(wood, 0.8)
			for _, sx in { -1, 1 } do
				local x = sx * 1.1
				-- a rocker of three runs, log legs and a rail under the seat
				path(r, { V(x, 0.55, -1.65), V(x, 0.14, -0.6), V(x, 0.14, 0.6), V(x, 0.5, 1.65) }, 0.24, dk, "Wood")
				rod(r, V(x, 0.2, 0.65), V(x, 2.62, 0.65), 0.26, wood, "Wood")
				rod(r, V(x, 0.2, -0.65), V(x, 1.85, -0.65), 0.26, wood, "Wood")
				rod(r, V(sx * 1.0, 1.75, -0.65), V(sx * 1.0, 4.4, -1.25), 0.24, wood, "Wood")
				r:cyl(x, 1.6, 0, 1.5, 0.22, "z", dk, "Wood")
				-- a flat topped arm with a round end
				r:block(x - 0.13, 2.55, -0.8, x + 0.13, 2.72, 0.82, wood, "Wood")
				r:cyl(x, 2.635, 0.82, 0.17, 0.26, "y", wood, "Wood")
				r:cyl(sx * 1.0, 4.4, -1.25, 0.03, 0.2, "y", ENDGRAIN, "Wood")
			end
			-- a seat of five poles with pale cut ends
			for _, z in { -0.6, -0.3, 0, 0.3, 0.6 } do
				r:cyl(0, 1.8, z, 2.3, 0.3, "x", wood, "Wood")
				for _, sx in { -1, 1 } do
					r:cyl(sx * 1.165, 1.8, z, 0.03, 0.22, "x", ENDGRAIN, "Wood")
				end
			end
			-- a back of three boards between two rails
			r:cyl(0, 4.2, -1.2, 2.2, 0.32, "x", wood, "Wood")
			r:cyl(0, 2.2, -0.76, 2.0, 0.22, "x", wood, "Wood")
			for _, x in { -0.55, 0, 0.55 } do
				r:beam(V(x, 2.2, -0.79), V(x, 4.1, -1.17), 0.4, 0.08, shade(wood, 1.06), "Wood")
			end
			-- a sheepskin over the seat and up the back, with a woolly edge
			local fleece = r.c2
			r:block(-0.9, 1.95, -0.65, 0.9, 2.02, 0.75, fleece, "Fabric")
			local mid = (V(0, 2.1, -0.75) + V(0, 3.7, -1.05)) / 2
			local dir = (V(0, 3.7, -1.05) - V(0, 2.1, -0.75)).Unit
			r:boxAt(
				CFrame.fromMatrix(mid, Vector3.xAxis, dir, Vector3.xAxis:Cross(dir)) * CFrame.new(0, 0, 0.1),
				1.0,
				1.6,
				0.07,
				fleece,
				"Fabric"
			)
			r:piece(function(q: R)
				q:box(0, 1.98, 0, 0.1, 0.04, 0.1, fleece, "Fabric")
				for i = 0, 5 do
					q:lump(CFrame.new(-0.75 + i * 0.3, 1.99, 0.76), 0.26, 0.12, 0.14, shade(fleece, 0.96), "Fabric")
				end
				for i = 0, 3 do
					q:lump(CFrame.new(-0.42 + i * 0.28, 3.72, -0.97), 0.24, 0.14, 0.12, shade(fleece, 0.96), "Fabric")
				end
			end)
			r:seat(0, 2.02, 0.1)
		end,
	},
	{
		id = "rustic_milk_stool",
		name = "Milking stool",
		cat = "seating",
		price = 35,
		place = "floor",
		size = V(1.6, 1.5, 1.6),
		c1 = "B48A5E",
		c2 = "8C6448",
		tags = { "seat" },
		style = "rustic",
		build = function(r: R)
			-- three splayed legs wedged through a thick round seat, a rung between two of them
			local legs: { { Vector3 } } = {}
			for i = 0, 2 do
				local a = i * math.pi * 2 / 3 + math.pi / 2
				local dx, dz = math.cos(a), math.sin(a)
				local top, foot = V(dx * 0.33, 1.25, dz * 0.33), V(dx * 0.62, 0, dz * 0.62)
				rod(r, top, foot, 0.16, r.c2, "Wood")
				table.insert(legs, { top, foot })
				r:cyl(dx * 0.33, 1.445, dz * 0.33, 0.03, 0.16, "y", ENDGRAIN, "Wood")
				r:boxAt(
					CFrame.new(dx * 0.33, 1.475, dz * 0.33) * CFrame.Angles(0, -a, 0),
					0.03,
					0.03,
					0.14,
					shade(r.c2, 0.6),
					"Wood"
				)
			end
			local function at(l: { Vector3 }, t: number): Vector3
				return l[2]:Lerp(l[1], t)
			end
			rod(r, at(legs[2], 0.36), at(legs[3], 0.36), 0.08, r.c2, "Wood")
			r:cyl(0, 1.17, 0, 0.08, 1.2, "y", shade(r.c1, 0.9), "Wood")
			r:cyl(0, 1.32, 0, 0.22, 1.4, "y", r.c1, "Wood")
			-- a little heart cut into the seat
			local heart = shade(r.c1, 0.7)
			for _, sx in { -1, 1 } do
				r:cyl(sx * 0.05, 1.445, -0.13, 0.03, 0.12, "y", heart, "Wood")
			end
			r:boxAt(CFrame.new(0, 1.445, -0.06) * CFrame.Angles(0, math.pi / 4, 0), 0.12, 0.03, 0.12, heart, "Wood")
			r:seat(0, 1.43, 0)
		end,
	},
	{
		id = "rustic_soak_tub",
		name = "Wooden soaking tub",
		cat = "bath",
		price = 320,
		place = "floor",
		size = V(4.6, 3, 5.6),
		c1 = "B88D5E",
		c2 = "5A5560",
		tags = { "bath" },
		style = "rustic",
		build = function(r: R)
			local wood = r.c1
			local cz = -0.75
			-- a round tub of staves on two sleepers, three hoops round it, water inside
			for _, z in { cz - 1.05, cz + 1.05 } do
				r:block(-1.7, 0, z - 0.15, 1.7, 0.25, z + 0.15, shade(wood, 0.75), "Wood")
			end
			r:cyl(0, 0.35, cz, 0.2, 3.9, "y", shade(wood, 0.7), "Wood")
			r:cyl(0, 1.25, cz, 1.8, 3.84, "y", shade(wood, 0.5), "Wood")
			clear(r:cyl(0, 2.15, cz, 0.06, 3.86, "y", WATER, "Glass"), 0.15)
			staves(r, 0, cz, 0.2, 2.4, 2.0, 2.0, 2.0, 20, wood)
			for _, y in { 0.5, 1.4, 2.3 } do
				hoopRing(r, 0, cz, y, 2.0, 20, r.c2)
			end
			-- steps up to it, a bucket and a ladle on the top one
			r:block(-1.0, 0, 2.05, 1.0, 0.84, 2.8, wood, "Wood")
			r:block(-1.05, 0.84, 2.05, 1.05, 0.92, 2.86, shade(wood, 1.08), "Wood")
			r:block(-1.0, 0, 1.3, 1.0, 1.69, 2.05, wood, "Wood")
			r:block(-1.05, 1.69, 1.3, 1.05, 1.77, 2.1, shade(wood, 1.08), "Wood")
			bucket(r, 0.5, 1.77, 1.68, 0.26, 0.5, shade(wood, 1.1))
			rod(r, V(0.5, 2.1, 1.66), V(0.15, 2.6, 1.5), 0.05, Color3.fromRGB(176, 140, 100), "Wood")
			-- a towel over the rim
			r:block(-2.18, 1.5, cz - 0.4, -2.14, 2.64, cz + 0.4, CREAM, "Fabric")
			r:block(-2.18, 2.6, cz - 0.4, -1.86, 2.64, cz + 0.4, CREAM, "Fabric")
			r:block(-1.9, 2.25, cz - 0.4, -1.86, 2.6, cz + 0.4, CREAM, "Fabric")
			r:block(-2.21, 1.62, cz - 0.4, -2.18, 1.72, cz + 0.4, DUSK, "Fabric")
			r:seat(0, 1.2, cz)
		end,
	},
	{
		id = "rustic_washstand",
		name = "Washstand",
		cat = "bath",
		price = 170,
		place = "floor",
		size = V(3, 4.8, 1.8),
		c1 = "A47A54",
		c2 = "E9E3D6",
		tags = { "bath", "mirror" },
		style = "rustic",
		build = function(r: R)
			local wood, china = r.c1, r.c2
			-- four legs, a drawer under the top and a shelf low down
			for _, sx in { -1, 1 } do
				for _, sz in { -1, 1 } do
					r:block(sx * 1.2, 0, sz * 0.6, sx * 1.35, 3.0, sz * 0.75, wood, "Wood")
				end
			end
			r:block(-1.2, 2.5, -0.6, 1.2, 3.0, 0.6, wood, "Wood")
			r:block(-1.0, 2.55, 0.6, 1.0, 2.95, 0.65, shade(wood, 1.08), "Wood")
			r:ball(0, 2.75, 0.7, 0.12, shade(wood, 0.7), "Wood")
			r:block(-1.45, 3.0, -0.82, 1.45, 3.15, 0.82, wood, "Wood")
			r:block(-1.2, 0.5, -0.6, 1.2, 0.6, 0.6, wood, "Wood")
			-- a splashback with a round top and a round mirror on it
			r:block(-1.4, 3.15, -0.82, 1.4, 3.9, -0.7, wood, "Wood")
			r:cyl(0, 3.9, -0.76, 0.12, 1.6, "z", wood, "Wood")
			r:cyl(0, 4.15, -0.68, 0.04, 1.04, "z", shade(wood, 0.75), "Wood")
			r:cyl(0, 4.15, -0.645, 0.03, 0.86, "z", MIRROR, "Glass")
			-- towel bars at both ends, a linen towel on one
			for _, sx in { -1, 1 } do
				for _, z in { -0.55, 0.55 } do
					r:block(sx * 1.45, 2.8, z - 0.04, sx * 1.58, 2.9, z + 0.04, wood, "Wood")
				end
				r:cyl(sx * 1.55, 2.85, 0, 1.2, 0.07, "z", wood, "Wood")
			end
			r:cyl(1.55, 2.85, 0, 0.8, 0.16, "z", CREAM, "Fabric")
			r:block(1.45, 2.1, -0.4, 1.48, 2.85, 0.4, CREAM, "Fabric")
			r:block(1.62, 2.25, -0.4, 1.65, 2.85, 0.4, CREAM, "Fabric")
			r:block(1.65, 2.35, -0.4, 1.68, 2.45, 0.4, DUSK, "Fabric")
			-- a basin with a jug standing in it, and a soap dish
			r:cyl(0, 3.2, 0.05, 0.1, 0.7, "y", china, "SmoothPlastic")
			r:cyl(0, 3.36, 0.05, 0.22, 1.3, "y", china, "SmoothPlastic")
			r:cyl(0, 3.49, 0.05, 0.04, 1.4, "y", DELFT, "SmoothPlastic")
			r:cyl(0, 3.525, 0.05, 0.03, 1.1, "y", WATER, "SmoothPlastic")
			r:cyl(0.15, 3.79, 0.1, 0.5, 0.42, "y", china, "SmoothPlastic")
			r:cyl(0.15, 3.9, 0.1, 0.06, 0.46, "y", DELFT, "SmoothPlastic")
			r:block(-0.12, 3.92, 0.06, -0.04, 4.04, 0.14, china, "SmoothPlastic")
			r:block(0.36, 3.6, 0.07, 0.44, 3.95, 0.13, china, "SmoothPlastic")
			r:cyl(1.0, 3.17, 0.45, 0.04, 0.4, "y", china, "SmoothPlastic")
			r:block(0.88, 3.19, 0.38, 1.12, 3.27, 0.52, Color3.fromRGB(226, 210, 180), "SmoothPlastic")
			-- on the shelf: a folded towel and a tin jug
			r:block(-0.9, 0.6, -0.4, 0.1, 0.8, 0.4, CREAM, "Fabric")
			r:block(-0.9, 0.62, 0.4, 0.1, 0.72, 0.43, DUSK, "Fabric")
			r:cyl(0.6, 0.9, 0, 0.6, 0.42, "y", C.Metal, "Metal")
			r:block(0.82, 0.8, -0.04, 0.9, 1.08, 0.04, C.Metal, "Metal")
		end,
	},
	{
		id = "rustic_pantry_shelf",
		name = "Pantry shelf",
		gives = "pantry", -- holding E gives something (Data/Items.Sources)
		cat = "kitchen",
		price = 80,
		place = "wall",
		size = V(4.2, 2.4, 1.1),
		c1 = "9C734D",
		c2 = "3E3A3C",
		tags = { "storage" },
		style = "rustic",
		build = function(r: R)
			local wood, iron = r.c1, r.c2
			-- a thick board on forged brackets
			r:block(-2.0, 1.4, 0, 2.0, 1.55, 1.0, wood, "Wood")
			for _, x in { -1.4, 1.4 } do
				r:block(x - 0.04, 0.7, 0, x + 0.04, 1.4, 0.08, iron, "Metal")
				r:block(x - 0.04, 1.32, 0.08, x + 0.04, 1.4, 0.85, iron, "Metal")
				r:beam(V(x, 0.78, 0.06), V(x, 1.34, 0.75), 0.06, 0.06, iron, "Metal")
				r:ball(x, 0.7, 0.06, 0.12, iron, "Metal")
				r:cyl(x, 1.0, 0.1, 0.04, 0.06, "z", shade(iron, 1.4), "Metal")
			end
			-- jars of preserves along it and a stoneware crock
			local fills = {
				Color3.fromRGB(176, 70, 80),
				Color3.fromRGB(232, 160, 70),
				Color3.fromRGB(130, 160, 90),
				Color3.fromRGB(196, 120, 150),
				Color3.fromRGB(226, 196, 110),
			}
			for i, x in { -1.6, -1.05, -0.5, 0.1, 0.6 } do
				local h = if i <= 3 then 0.55 else 0.4
				jar(r, x, 1.55, 0.5, if i <= 3 then 0.42 else 0.34, h, fills[i], if i % 2 == 1 then GINGHAM else nil)
				r:block(
					x - 0.08,
					1.55 + h * 0.3,
					0.5 + (if i <= 3 then 0.21 else 0.17),
					x + 0.08,
					1.55 + h * 0.5,
					0.53 + (if i <= 3 then 0.21 else 0.17),
					PAGE,
					"SmoothPlastic"
				)
			end
			r:cyl(1.45, 1.85, 0.45, 0.6, 0.55, "y", STONEWARE, "SmoothPlastic")
			r:cyl(1.45, 1.9, 0.45, 0.08, 0.6, "y", DELFT, "SmoothPlastic")
			r:cyl(1.45, 2.18, 0.45, 0.06, 0.58, "y", shade(STONEWARE, 0.9), "SmoothPlastic")
			r:ball(1.45, 2.24, 0.45, 0.12, shade(STONEWARE, 0.9), "SmoothPlastic")
			-- a rail under it with herbs drying and a ladle on a hook
			r:cyl(0, 1.25, 0.7, 2.8, 0.05, "x", iron, "Metal")
			for i, x in { -0.9, -0.2, 0.5 } do
				herbs(r, V(x, 1.2, 0.7), 0.55, if i == 2 then Color3.fromRGB(150, 160, 110) else SAGE, 10 + i)
			end
			path(r, { V(1.0, 1.25, 0.7), V(1.0, 1.1, 0.7), V(1.06, 1.06, 0.7) }, 0.03, iron, "Metal")
			r:cyl(1.06, 0.72, 0.7, 0.66, 0.05, "y", C.Metal, "Metal")
			r:lump(CFrame.new(1.06, 0.36, 0.7), 0.26, 0.14, 0.26, C.Metal, "Metal")
		end,
	},
	{
		id = "rustic_wreath",
		name = "Wheat wreath",
		cat = "walldecor",
		price = 45,
		place = "wall",
		size = V(2.4, 2.6, 0.5),
		c1 = "8A6A4A",
		c2 = "D7B26A",
		tags = { "art" },
		style = "rustic",
		build = function(r: R)
			local twig, wheat = r.c1, r.c2
			local c = V(0, 1.2, 0.2)
			-- a nail and a twine loop
			r:cyl(0, 2.45, 0.05, 0.1, 0.05, "z", IRON, "Metal")
			rod(r, V(0, 2.45, 0.08), V(-0.3, 2.05, 0.16), 0.03, TWINE, "Fabric")
			rod(r, V(0, 2.45, 0.08), V(0.3, 2.05, 0.16), 0.03, TWINE, "Fabric")
			-- two rings of twigs woven round
			for k = 0, 1 do
				r:piece(function(q: R)
					q:box(0, 1.2, 0.2 + k * 0.08, 0.02, 0.02, 0.02, twig, "Wood")
					ring(
						q,
						c + V(0, 0, k * 0.08),
						Vector3.xAxis,
						Vector3.yAxis,
						0.9 - k * 0.12,
						16,
						0.12,
						0.12,
						shade(twig, 1 - k * 0.12),
						"Wood",
						k * 0.5
					)
				end)
			end
			-- ears of wheat round it in bunches, and a few dried flowers
			for b = 0, 2 do
				r:piece(function(q: R)
					q:box(0, 1.2, 0.3, 0.02, 0.02, 0.02, wheat, "SmoothPlastic")
					for k = 0, 3 do
						local a = (b * 4 + k) * math.pi * 2 / 12
						local base = c + V(math.cos(a), math.sin(a), 0) * 0.84 + V(0, 0, 0.16)
						local t = V(-math.sin(a), math.cos(a), 0)
						for s = -1, 1 do
							local tip = base + t * 0.32 + V(math.cos(a), math.sin(a), 0) * (s * 0.1)
							q:beam(base, tip, 0.025, 0.025, shade(wheat, 0.85), "SmoothPlastic")
							local ang = math.atan2(tip.Y - base.Y, tip.X - base.X) - math.pi / 2
							q:lump(CFrame.new(tip) * CFrame.Angles(0, 0, ang), 0.08, 0.24, 0.08, wheat, "SmoothPlastic")
						end
					end
				end)
			end
			for i = 0, 5 do
				local a = i * math.pi / 3 + 0.3
				local p = c + V(math.cos(a), math.sin(a), 0) * 0.78 + V(0, 0, 0.3)
				r:ball(p.X, p.Y, p.Z, 0.14, if i % 2 == 0 then CREAM else Color3.fromRGB(186, 110, 86), "Fabric")
			end
			-- a gingham bow at the bottom
			for _, s in { -1, 1 } do
				r:boxAt(
					CFrame.new(s * 0.18, 0.36, 0.42) * CFrame.Angles(0, 0, s * 0.45),
					0.34,
					0.18,
					0.06,
					GINGHAM,
					"Fabric"
				)
				r:boxAt(
					CFrame.new(s * 0.1, 0.1, 0.4) * CFrame.Angles(0, 0, s * 0.3),
					0.09,
					0.4,
					0.04,
					GINGHAM,
					"Fabric"
				)
			end
			r:box(0, 0.34, 0.45, 0.14, 0.15, 0.1, shade(GINGHAM, 0.85), "Fabric")
		end,
	},
	{
		id = "rustic_log_holder",
		name = "Log holder",
		cat = "decor",
		price = 90,
		place = "floor",
		size = V(3, 3, 1.6),
		c1 = "7A5A40",
		c2 = "3E3A3C",
		style = "rustic",
		build = function(r: R)
			local bark, iron = r.c1, r.c2
			local c = V(0, 1.55, 0)
			-- two iron hoops on feet, tied together with bars
			for _, z in { -0.6, 0.6 } do
				r:piece(function(q: R)
					q:block(-0.9, 0, z - 0.05, 0.9, 0.12, z + 0.05, iron, "Metal")
					q:block(-0.05, 0.12, z - 0.04, 0.05, 0.22, z + 0.04, iron, "Metal")
					ring(q, c + V(0, 0, z), Vector3.xAxis, Vector3.yAxis, 1.35, 20, 0.08, 0.06, iron, "Metal")
				end)
			end
			for _, a in { -math.pi / 2 - 0.5, -math.pi / 2 + 0.5, math.pi, 0 } do
				r:cyl(math.cos(a) * 1.37, 1.55 + math.sin(a) * 1.37, 0, 1.28, 0.06, "z", iron, "Metal")
			end
			-- split logs stacked inside, their cut ends pale
			local rand = rng(2)
			local rows = { -1.08, -0.68, -0.28, 0.12, 0.52 }
			for i, dy in rows do
				local off = if i % 2 == 0 then 0.22 else 0
				for k = -3, 3 do
					local x = k * 0.44 + off
					local d = 0.38 + rand() * 0.08
					if math.sqrt(x * x + dy * dy) + d / 2 < 1.3 then
						local col = shade(bark, 0.9 + rand() * 0.2)
						r:cyl(x, 1.55 + dy, 0, 1.3, d, "z", col, "Wood")
						r:cyl(x, 1.55 + dy, 0.665, 0.03, d * 0.78, "z", shade(ENDGRAIN, 0.92 + rand() * 0.12), "Wood")
					end
				end
			end
		end,
	},
	{
		id = "rustic_rag_rug",
		name = "Rag rug",
		cat = "decor",
		price = 60,
		place = "floor",
		size = V(4, 0.1, 6.4),
		c1 = "8FA6B8",
		c2 = "C98B86",
		tags = { "rug" },
		style = "rustic",
		build = function(r: R)
			-- woven from strips of old cloth: bands across in many colours, flecked with the next
			local colours = { r.c1, CREAM, r.c2, MUSTARD, SAGE, shade(r.c1, 0.8), CREAM, ROSE, DUSK }
			local n = 16
			local function band(i: number): (number, number)
				return -2.88 + i * 0.36, -2.88 + (i + 1) * 0.36
			end
			for i = 0, n - 1 do
				local z1, z2 = band(i)
				r:noCollide(r:block(-1.9, 0, z1, 1.9, 0.04, z2, colours[1 + i % #colours], "Fabric"))
			end
			for half = 0, 1 do
				r:noCollide(r:piece(function(q: R)
					q:box(0, 0.02, 0, 0.05, 0.02, 0.05, CREAM, "Fabric")
					for i = half * 8, half * 8 + 7 do
						local z1, z2 = band(i)
						local zm = (z1 + z2) / 2
						local col = colours[1 + (i + 3) % #colours]
						for k = 0, 2 do
							local x = -1.3 + k * 1.3 + (if i % 2 == 0 then 0.3 else -0.3)
							q:block(x - 0.24, 0.04, zm - 0.06, x + 0.24, 0.065, zm + 0.06, col, "Fabric")
						end
					end
				end))
			end
			for _, sx in { -1, 1 } do
				r:noCollide(r:block(sx * 1.9, 0, -2.88, sx * 2.0, 0.045, 2.88, shade(r.c1, 0.7), "Fabric"))
			end
			r:noCollide(r:piece(function(q: R)
				for _, s in { -1, 1 } do
					for i = 0, 11 do
						local x = -1.76 + i * 0.32
						q:block(x - 0.04, 0, s * 2.88, x + 0.04, 0.03, s * 3.15, CREAM, "Fabric")
					end
				end
			end))
		end,
	},
	{
		id = "rustic_pie_cupboard",
		name = "Pie cupboard",
		cat = "kitchen",
		price = 280,
		place = "floor",
		size = V(3.6, 6.3, 1.8),
		c1 = "93A58F",
		c2 = "B9B4A8",
		tags = { "storage", "kitchen" },
		style = "rustic",
		build = function(r: R)
			local paint, tin = r.c1, r.c2
			local door = shade(paint, 1.06)
			-- a painted case on bun feet with a cornice
			for _, sx in { -1, 1 } do
				for _, sz in { -1, 1 } do
					r:ball(sx * 1.45, 0.15, sz * 0.6, 0.3, shade(paint, 0.85), "Wood")
				end
				r:block(sx * 1.6, 0.3, -0.85, sx * 1.75, 5.2, 0.75, paint, "Wood")
			end
			r:block(-1.6, 0.3, -0.85, 1.6, 5.2, -0.75, shade(paint, 0.8), "Wood")
			r:block(-1.6, 0.3, -0.75, 1.6, 0.5, 0.75, paint, "Wood")
			r:block(-1.6, 0.5, -0.75, 1.6, 5.2, 0.7, shade(paint, 0.45), "Wood")
			r:block(-1.85, 5.2, -0.92, 1.85, 5.35, 0.9, paint, "Wood")
			r:block(-1.95, 5.35, -0.95, 1.95, 5.5, 0.98, paint, "Wood")
			-- lower doors with raised panels, two drawers, upper doors of punched tin
			for _, sx in { -1, 1 } do
				local xo, xi = sx * 1.55, sx * 0.03
				r:block(xo, 0.55, 0.75, xi, 2.95, 0.81, door, "Wood")
				r:block(xo - sx * 0.18, 0.75, 0.81, xi + sx * 0.18, 2.75, 0.84, paint, "Wood")
				r:cyl(sx * 0.2, 1.9, 0.86, 0.1, 0.1, "z", shade(paint, 0.6), "Wood")
				r:block(xo, 3.0, 0.75, xi, 3.5, 0.81, door, "Wood")
				r:cyl(sx * 0.79, 3.25, 0.86, 0.1, 0.1, "z", shade(paint, 0.6), "Wood")
				local x1, x2 = math.min(xo, xi), math.max(xo, xi)
				r:piece(function(q: R)
					q:block(x1, 3.55, 0.75, x2, 3.7, 0.83, door, "Wood")
					q:block(x1, 5.0, 0.75, x2, 5.15, 0.83, door, "Wood")
					q:block(x1, 3.7, 0.75, x1 + 0.15, 5.0, 0.83, door, "Wood")
					q:block(x2 - 0.15, 3.7, 0.75, x2, 5.0, 0.83, door, "Wood")
				end)
				local cx, cy = (x1 + x2) / 2, 4.35
				r:piece(function(q: R)
					q:block(x1 + 0.15, 3.7, 0.75, x2 - 0.15, 5.0, 0.79, tin, "Metal")
					local dots = { { 0, 0 } }
					for k = 0, 11 do
						local a = k * math.pi / 6
						local rad = 0.42 / (math.abs(math.cos(a)) + math.abs(math.sin(a)))
						table.insert(dots, { math.cos(a) * rad, math.sin(a) * rad })
					end
					for _, s in { { -1, -1 }, { -1, 1 }, { 1, -1 }, { 1, 1 } } do
						table.insert(dots, { s[1] * 0.42, s[2] * 0.48 })
					end
					for _, p in dots do
						q:block(
							cx + p[1] - 0.025,
							cy + p[2] - 0.025,
							0.79,
							cx + p[1] + 0.025,
							cy + p[2] + 0.025,
							0.82,
							shade(tin, 0.55),
							"Metal"
						)
					end
				end)
				for _, y in { 0.8, 2.6, 3.75, 4.9 } do
					r:block(xo, y, 0.81, xo - sx * 0.08, y + 0.2, 0.84, IRON, "Metal")
				end
			end
			r:boxAt(CFrame.new(0, 4.35, 0.86) * CFrame.Angles(0, 0, 0.3), 0.08, 0.32, 0.04, shade(paint, 0.6), "Wood")
			r:cyl(0, 4.35, 0.89, 0.03, 0.06, "z", IRON, "Metal")
			-- a crock of wooden spoons on top
			r:cyl(0.6, 5.75, 0.0, 0.5, 0.46, "y", STONEWARE, "SmoothPlastic")
			r:cyl(0.6, 5.85, 0.0, 0.08, 0.52, "y", DELFT, "SmoothPlastic")
			local spoon = Color3.fromRGB(196, 160, 112)
			for i = 0, 2 do
				local a = i * 2.1
				local tip = V(0.6 + math.cos(a) * 0.22, 6.25, math.sin(a) * 0.12)
				rod(r, V(0.6, 5.7, 0), tip, 0.05, spoon, "Wood")
				r:lump(CFrame.new(tip + V(0, 0.08, 0)), 0.14, 0.2, 0.06, spoon, "Wood")
			end
			r:block(-1.2, 5.5, -0.4, -0.3, 5.62, 0.3, CREAM, "Fabric")
			r:block(-1.0, 5.62, -0.4, -0.9, 5.65, 0.3, GINGHAM, "Fabric")
		end,
	},
	{
		id = "rustic_wheelbarrow",
		name = "Wheelbarrow planter",
		cat = "garden",
		price = 140,
		place = "ground",
		size = V(2.6, 2.6, 5),
		c1 = "A2784F",
		c2 = "D98C8C",
		tags = { "plant" },
		style = "rustic",
		build = function(r: R)
			local wood = r.c1
			local dk = shade(wood, 0.78)
			-- a spoked wooden wheel with an iron tyre
			local hub = V(0, 0.55, 1.9)
			r:piece(function(q: R)
				q:box(0, 0.55, 1.9, 0.02, 0.02, 0.02, wood, "Wood")
				ring(q, hub, Vector3.yAxis, Vector3.zAxis, 0.48, 12, 0.12, 0.12, wood, "Wood")
			end)
			r:piece(function(q: R)
				q:box(0, 0.55, 1.9, 0.02, 0.02, 0.02, IRON, "Metal")
				ring(q, hub, Vector3.yAxis, Vector3.zAxis, 0.57, 12, 0.1, 0.06, IRON, "Metal")
			end)
			r:cyl(0, 0.55, 1.9, 0.3, 0.24, "x", dk, "Wood")
			r:cyl(0, 0.55, 1.9, 0.6, 0.08, "x", IRON, "Metal")
			for k = 0, 5 do
				local a = k * math.pi / 3
				rod(r, hub, hub + V(0, math.cos(a), math.sin(a)) * 0.46, 0.07, wood, "Wood")
			end
			-- two rails from the axle back to the handles, legs under the back
			for _, sx in { -1, 1 } do
				path(
					r,
					{ V(sx * 0.32, 0.55, 1.9), V(sx * 0.75, 1.05, -1.4), V(sx * 0.82, 1.3, -2.4) },
					0.14,
					wood,
					"Wood"
				)
				r:cyl(sx * 0.82, 1.3, -2.3, 0.3, 0.17, "z", dk, "Wood")
				r:beam(V(sx * 0.66, 1.1, -0.95), V(sx * 0.7, 0, -1.1), 0.14, 0.14, wood, "Wood")
				r:block(sx * 0.7 - 0.08, 0, -1.4, sx * 0.7 + 0.08, 0.1, -0.85, dk, "Wood")
			end
			-- the tray: a floor, plank sides, a back board and a sloping front
			r:block(-0.5, 0.75, 0.75, 0.5, 1.08, 0.9, dk, "Wood")
			r:block(-0.7, 1.08, -1.3, 0.7, 1.18, 0.9, wood, "Wood")
			for _, sx in { -1, 1 } do
				r:block(sx * 0.7, 1.08, -1.3, sx * 0.8, 1.49, 0.9, wood, "Wood")
				r:block(sx * 0.7, 1.49, -1.3, sx * 0.8, 1.9, 0.9, shade(wood, 1.08), "Wood")
				r:tri(V(sx * 0.75, 1.08, 0.9), V(sx * 0.75, 1.9, 0.9), V(sx * 0.75, 1.9, 1.27), 0.1, wood, "Wood")
				r:block(sx * 0.8, 1.6, -1.35, sx * 0.83, 1.9, -1.1, IRON, "Metal")
			end
			r:block(-0.8, 1.08, -1.4, 0.8, 1.9, -1.3, wood, "Wood")
			local front = V(0, 1.08, 0.9)
			local top = V(0, 1.9, 1.27)
			local dir = (top - front).Unit
			r:boxAt(
				CFrame.fromMatrix((front + top) / 2 + V(0, 0, 0.05), Vector3.xAxis, dir, Vector3.xAxis:Cross(dir)),
				1.6,
				(top - front).Magnitude,
				0.1,
				shade(wood, 0.94),
				"Wood"
			)
			-- soil and flowers spilling over the sides
			r:block(-0.7, 1.75, -1.3, 0.7, 1.82, 1.0, SOIL, "Sand")
			local blooms = { r.c2, CREAM, MUSTARD, r.c2, Color3.fromRGB(196, 150, 200), r.c2, CREAM, MUSTARD, r.c2 }
			local rand = rng(8)
			for i, col in blooms do
				local x = -0.45 + ((i - 1) % 3) * 0.45 + (rand() - 0.5) * 0.12
				local z = -1.0 + math.floor((i - 1) / 3) * 0.75 + (rand() - 0.5) * 0.2
				local h = 0.35 + rand() * 0.3
				r:box(x, 1.82 + h / 2, z, 0.04, h, 0.04, C.DarkLeaf, "SmoothPlastic")
				r:ball(x, 1.86 + h, z, 0.26, col, "SmoothPlastic")
				r:ball(x, 1.9 + h, z, 0.1, if col == MUSTARD then C.White else C.Yellow, "SmoothPlastic")
			end
			r:piece(function(q: R)
				q:box(0, 1.85, 0, 0.1, 0.06, 0.1, C.Leaf, "SmoothPlastic")
				for i = 0, 7 do
					local x = -0.5 + (i % 4) * 0.33
					local z = -1.1 + math.floor(i / 4) * 1.4 + (i % 2) * 0.3
					q:lump(
						CFrame.new(x, 1.92, z) * CFrame.Angles(0, i, 0),
						0.42,
						0.22,
						0.32,
						if i % 2 == 0 then C.Leaf else C.DarkLeaf,
						"SmoothPlastic"
					)
				end
			end)
			r:piece(function(q: R)
				q:box(-0.75, 1.85, -0.2, 0.04, 0.1, 0.04, C.DarkLeaf, "SmoothPlastic")
				for i = 0, 4 do
					local y = 1.82 - i * 0.18
					q:lump(
						CFrame.new(-0.86 - (if i == 0 then 0 else 0.02), y, -0.2 + (i % 2) * 0.12)
							* CFrame.Angles(0, 0, 0.3),
						0.06,
						0.2,
						0.16,
						C.Leaf,
						"SmoothPlastic"
					)
				end
				q:box(-0.84, 1.45, -0.15, 0.03, 0.75, 0.03, C.DarkLeaf, "SmoothPlastic")
			end)
		end,
	},
	{
		id = "rustic_pump",
		name = "Water pump",
		cat = "garden",
		price = 150,
		place = "ground",
		size = V(2.4, 4.2, 3),
		c1 = "4E5D58",
		c2 = "8B8478",
		style = "rustic",
		build = function(r: R)
			local iron, stone = r.c1, r.c2
			local rand = rng(6)
			-- a plinth faced with stones and a flat stone in front for the bucket
			r:piece(function(q: R)
				q:block(-1.0, 0, -1.3, 1.0, 0.5, 0.3, stone, "Slate")
				for i = 0, 3 do
					q:lump(
						CFrame.new(-0.75 + i * 0.5, 0.25, 0.3),
						0.42,
						0.36,
						0.14,
						shade(stone, 0.88 + rand() * 0.22),
						"Slate"
					)
				end
				for _, sx in { -1, 1 } do
					for i = 0, 2 do
						q:lump(
							CFrame.new(sx * 1.0, 0.25, -1.0 + i * 0.5),
							0.14,
							0.36,
							0.42,
							shade(stone, 0.88 + rand() * 0.22),
							"Slate"
						)
					end
				end
			end)
			r:block(-0.9, 0, 0.3, 0.9, 0.15, 1.45, shade(stone, 1.08), "Slate")
			-- the cast iron body, its spout and cap
			r:cyl(0, 0.58, -0.6, 0.16, 0.7, "y", iron, "Metal")
			r:cyl(0, 1.75, -0.6, 2.5, 0.42, "y", iron, "Metal")
			for _, y in { 1.2, 2.45 } do
				r:cyl(0, y, -0.6, 0.08, 0.48, "y", shade(iron, 0.85), "Metal")
			end
			r:cyl(0, 3.06, -0.6, 0.12, 0.56, "y", iron, "Metal")
			r:lump(CFrame.new(0, 3.16, -0.6), 0.46, 0.2, 0.46, iron, "Metal")
			path(r, { V(0, 2.3, -0.42), V(0, 2.32, 0.35), V(0, 2.1, 0.52) }, 0.18, iron, "Metal")
			r:cyl(0, 2.04, 0.54, 0.06, 0.22, "y", shade(iron, 0.85), "Metal")
			clear(r:ball(0, 1.9, 0.54, 0.08, WATER, "Glass"), 0.3)
			-- the handle: a piston rod, a link to the back and a long lever with a knob
			r:cyl(0, 3.33, -0.58, 0.3, 0.07, "y", iron, "Metal")
			rod(r, V(0, 3.05, -0.86), V(0, 3.53, -0.8), 0.07, iron, "Metal")
			r:beam(V(0, 3.45, -0.48), V(0, 3.86, -1.42), 0.1, 0.12, iron, "Metal")
			r:ball(0, 3.9, -1.44, 0.18, iron, "Metal")
			r:cyl(0, 3.53, -0.8, 0.16, 0.1, "x", shade(iron, 1.3), "Metal")
			-- a bucket under the spout
			bucket(r, 0, 0.15, 0.9, 0.34, 0.62, Color3.fromRGB(176, 140, 96))
		end,
	},
}

return items
