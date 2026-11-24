--!strict
-- Trees, plants and things for the yard. Most of these stand on the ground outdoors.
-- c1 is the main colour (leaves, stone, paint), c2 the second (bark, trim, fabric).

local Recipe = require(script.Parent.Parent.Recipe)
local Colors = require(script.Parent.Parent.Parent.Util.Colors)

local C = Recipe.Colors

type R = Recipe.Recipe

local function shade(c: Color3, k: number): Color3
	return Colors.shade(c, k)
end

-- A water surface: see-through enough to show what is under it, and you walk into it.
local function water(p: Recipe.Prim, transp: number?): Recipe.Prim
	p.transp = transp or 0.2
	p.collide = false
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
		size = Vector3.new(len, d, d),
		color = color,
		mat = mat or "SmoothPlastic",
	})
end

-- Roots that flare out round the foot of a trunk.
local function roots(r: R, n: number, reach: number, thick: number, color: Color3)
	for i = 0, n - 1 do
		local a = i / n * math.pi * 2 + 0.4
		r:beam(
			Vector3.new(0, thick * 1.4, 0),
			Vector3.new(math.cos(a) * reach, 0.05, math.sin(a) * reach),
			thick,
			thick * 0.8,
			color,
			"Wood"
		)
	end
end

-- One bough of a fir on r: a wedge hanging from the trunk at height y, `len` long, `wide` across
-- and `thick` where it leaves the trunk, pointing out along the angle `a` and tipped `droop` down.
-- It starts `inset` inside the trunk.
local function bough(
	r: R,
	y: number,
	a: number,
	len: number,
	wide: number,
	thick: number,
	droop: number,
	inset: number,
	color: Color3
)
	local out = Vector3.new(math.cos(a), 0, math.sin(a))
	local along = out * math.cos(droop) - Vector3.yAxis * math.sin(droop)
	local up = out * math.sin(droop) + Vector3.yAxis * math.cos(droop)
	local back = -along
	-- (right, up and back are a right-handed set, as every frame must be)
	local right = up:Cross(back)
	local foot = Vector3.new(0, y, 0) - along * inset
	local cf = CFrame.fromMatrix(foot + along * ((len + inset) / 2) + up * (thick / 2), right, up, back)
	r:wedge(cf, wide, thick, len + inset, color, "Grass")
end

-- A fir's crown on r, the way the town's are drawn (Data/CityModels): `rows` of drooping boughs,
-- three to a row, from the lowest tips at `base` up to a slim spire whose point is at `top`, the
-- lowest boughs `reach` long and each row turned against the one under it. Dark in the middle,
-- `leaf` on the boughs low down and `lit` (where the sun catches it) at the top.
local function firCrown(r: R, base: number, top: number, reach: number, rows: number, leaf: Color3, lit: Color3)
	local droop0 = 0.72
	local low = base + reach * math.sin(droop0) * 0.9
	local high = top - (top - base) * 0.15
	local core = reach * 0.22
	r:box(0, (base + 0.6 + high) / 2, 0, core, high - base - 0.6, core, shade(leaf, 0.55), "Grass")
	for i = 0, rows - 1 do
		local t = i / (rows - 1)
		local y = low + (high - low) * t ^ 0.85
		local len = reach * (1 - 0.7 * t)
		local droop = droop0 - 0.24 * t
		local tone = Colors.mix(leaf, lit, t ^ 1.4)
		local turn = i * (math.pi / 3 + 0.19)
		for k = 0, 2 do
			local color = if k == 0 then tone elseif k == 1 then shade(tone, 0.86) else shade(tone, 0.93)
			bough(
				r,
				y,
				turn + k * math.pi * 2 / 3,
				len,
				len * 0.95 + 0.3,
				len * 0.34 + 0.25,
				droop,
				math.min(core * 0.4, len * 0.15),
				color
			)
		end
	end
	for k = 0, 2 do
		bough(r, high - 0.3, k * math.pi * 2 / 3 + 0.5, 0.45 + reach * 0.08, 0.36, top - high + 0.3, 0, 0, lit)
	end
end

-- A broadleaf crown on r: a heart of leaves, four clumps round its lower edge, three above and a
-- small one at the crown, darker underneath and lighter where the sun is. Each clump is a faceted
-- lump squashed and turned its own way. `s` scales it (1 is 8 studs across and 6 deep, its
-- middle at y 8 before scaling).
local CROWN = {
	-- x, y, z, width, height, depth, tone (0 low to 1 top), turn
	{ 0, 8.0, 0, 4.6, 3.8, 4.4, 0.4, 0.2 },
	{ 2.0, 6.9, 0.4, 3.2, 2.6, 3.0, 0.12, 0.9 },
	{ -0.6, 6.7, 1.9, 3.0, 2.5, 3.2, 0.06, 2.1 },
	{ -1.9, 6.9, -0.5, 3.2, 2.6, 2.9, 0, 1.4 },
	{ 0.5, 6.6, -1.9, 3.0, 2.4, 3.0, 0.08, 0.3 },
	{ 1.2, 9.2, 0.6, 3.0, 2.6, 2.9, 0.7, 0.5 },
	{ -1.2, 9.4, 0.5, 2.9, 2.5, 3.0, 0.75, 2.7 },
	{ 0, 9.1, -1.3, 3.0, 2.5, 2.8, 0.7, 1.9 },
	{ 0.1, 10.5, 0.1, 2.5, 2.0, 2.5, 1, 1.1 },
}
local function crown(r: R, s: number, leaf: Color3, lit: Color3)
	local under = shade(leaf, 0.74)
	for _, c in CROWN do
		local t = c[7]
		local tone = if t < 0.5 then Colors.mix(under, leaf, t * 2) else Colors.mix(leaf, lit, t * 2 - 1)
		r:lump(
			CFrame.new(c[1] * s, c[2] * s, c[3] * s) * CFrame.Angles(0.3, c[8], -0.25),
			c[4] * s,
			c[5] * s,
			c[6] * s,
			tone,
			"Grass"
		)
	end
end

-- A curved runner of straight pieces through the given points, joints closed up.
local function rail(r: R, pts: { Vector3 }, w: number, h: number, color: Color3, mat: string)
	for i = 1, #pts - 1 do
		local a, b = pts[i], pts[i + 1]
		local d = (b - a).Unit * 0.06
		r:beam(if i > 1 then a - d else a, if i < #pts - 1 then b + d else b, w, h, color, mat)
	end
end

-- A flower on a stem at (x, z), its head at height h.
local function flower(r: R, x: number, z: number, y0: number, h: number, head: Color3)
	r:cyl(x, (y0 + h) / 2, z, h - y0, 0.07, "y", C.DarkLeaf, "SmoothPlastic")
	r:cyl(x, h, z, 0.1, 0.38, "y", head, "SmoothPlastic")
	r:ball(x, h + 0.06, z, 0.14, if head == C.Yellow then Color3.fromRGB(200, 132, 62) else C.Yellow, "SmoothPlastic")
end

local AMBER = Color3.fromRGB(200, 132, 62)
local CORAL = Color3.fromRGB(224, 133, 102)
local SUNLIT = Color3.fromRGB(196, 190, 110) -- leaves where the sun catches them lean warm
local LILAC = Color3.fromRGB(156, 134, 184)

-- One flower drawn on q (a piece's recipe): a stem from y0 up to its head at h, a leaf part way
-- up, the head (a flat cup of petals, tipped a little) and the middle on top of it.
local function bloom(q: R, x: number, z: number, y0: number, h: number, head: Color3, turn: number)
	q:block(x - 0.035, y0, z - 0.035, x + 0.035, h, z + 0.035, C.DarkLeaf, "SmoothPlastic")
	local side = if math.floor(turn * 3) % 2 == 0 then 1 else -1
	q:lump(
		CFrame.new(x + side * 0.12, y0 + (h - y0) * 0.5, z) * CFrame.Angles(0, turn, side * -0.6),
		0.32,
		0.09,
		0.16,
		C.Leaf,
		"SmoothPlastic"
	)
	q:lump(CFrame.new(x, h, z) * CFrame.Angles(0.2, turn, 0), 0.4, 0.14, 0.4, head, "SmoothPlastic")
	q:ball(x, h + 0.08, z + 0.02, 0.14, if head == C.Yellow then AMBER else C.Yellow, "SmoothPlastic")
end

-- A spike of little flowers (lavender, foxglove) on q: a stem and three tufts up its top.
local function spike(q: R, x: number, z: number, y0: number, h: number, color: Color3)
	q:block(x - 0.03, y0, z - 0.03, x + 0.03, h - 0.3, z + 0.03, C.DarkLeaf, "SmoothPlastic")
	for i = 0, 2 do
		local s = 0.24 - i * 0.05
		q:lump(
			CFrame.new(x, h - 0.42 + i * 0.19, z) * CFrame.Angles(0, i * 0.8, 0),
			s,
			0.24,
			s,
			if i % 2 == 0 then color else shade(color, 1.12),
			"SmoothPlastic"
		)
	end
end

-- Leaves on q: a low bed from x0 to x1 and z0 to z1 at height y, and n clumps along it.
local function leaves(q: R, x0: number, x1: number, z0: number, z1: number, y: number, n: number, size: number)
	q:block(x0, y - 0.05, z0, x1, y + 0.08, z1, C.DarkLeaf, "Grass")
	for i = 0, n - 1 do
		local x = x0 + (x1 - x0) * (i + 0.5) / n
		local s = size * (0.85 + (i % 3) * 0.1)
		local z = (z0 + z1) / 2 + (if i % 2 == 0 then 0.15 else -0.15) * (z1 - z0)
		q:lump(
			CFrame.new(x, y + s * 0.28, z) * CFrame.Angles(0, i * 1.3, 0),
			s * 1.15,
			s * 0.62,
			math.min(s, (z1 - z0) * 0.9),
			if i % 2 == 0 then C.Leaf else shade(C.Leaf, 0.86),
			"Grass"
		)
	end
end

-- A trailing stem hanging over an edge at (x, y, z), its leaves ending in a little tuft.
local function trail(q: R, x: number, y: number, z: number, len: number, lean: number)
	q:lump(CFrame.new(x, y - len / 2, z) * CFrame.Angles(lean, 0, 0.3), 0.2, len + 0.1, 0.16, C.Leaf, "Grass")
	q:lump(
		CFrame.new(x + 0.06, y - len, z + lean * 0.2) * CFrame.Angles(0, x * 3, 0),
		0.24,
		0.13,
		0.2,
		C.DarkLeaf,
		"Grass"
	)
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
	build: (r: R) -> (),
}

local items: { Item } = {
	{
		id = "tree_oak",
		name = "Oak tree",
		cat = "garden",
		price = 120,
		place = "ground",
		size = Vector3.new(8, 12, 8),
		c1 = "6EA460",
		c2 = "6E4C30",
		tags = { "plant" },
		build = function(r: R)
			roots(r, 4, 1.2, 0.45, r.c2)
			r:cyl(0, 0.6, 0, 1.2, 1.5, "y", r.c2, "Wood")
			r:cyl(0, 3.0, 0, 4.4, 1.15, "y", r.c2, "Wood")
			rod(r, Vector3.new(0, 4.2, 0), Vector3.new(-1.8, 6.8, 0.6), 0.55, r.c2, "Wood")
			rod(r, Vector3.new(0, 4.6, 0), Vector3.new(1.6, 7.2, -0.8), 0.55, r.c2, "Wood")
			rod(r, Vector3.new(0, 5.0, 0), Vector3.new(0.3, 7.6, 1.4), 0.45, r.c2, "Wood")
			-- a full, soft crown of squashed clumps, darker underneath and lighter on top
			crown(r, 1, r.c1, Colors.mix(r.c1, SUNLIT, 0.28))
		end,
	},
	{
		id = "tree_pine",
		name = "Pine tree",
		cat = "garden",
		price = 100,
		place = "ground",
		size = Vector3.new(5, 13, 5),
		c1 = "4A7F58",
		c2 = "6E4C30",
		tags = { "plant" },
		build = function(r: R)
			-- a straight trunk on its roots showing under rows of drooping boughs that get shorter
			-- up to a slim spire, dark in the middle and lighter at the top (as the town's firs are)
			roots(r, 3, 0.9, 0.35, r.c2)
			r:cyl(0, 1.4, 0, 2.8, 0.7, "y", r.c2, "Wood")
			firCrown(r, 1.2, 12.9, 2.6, 7, shade(r.c1, 0.82), Colors.mix(r.c1, SUNLIT, 0.32))
			-- a few cones fallen under it
			r:piece(function(q: R)
				q:box(1.3, 0.08, 0.9, 0.14, 0.14, 0.24, C.Bark, "Wood")
				q:lump(CFrame.new(-1.1, 0.08, 1.2) * CFrame.Angles(0, 0.7, 1.4), 0.24, 0.16, 0.16, C.Bark, "Wood")
				q:lump(CFrame.new(0.6, 0.08, -1.4) * CFrame.Angles(0, 2.1, 1.4), 0.24, 0.16, 0.16, C.Bark, "Wood")
			end)
		end,
	},
	{
		id = "tree_blossom",
		name = "Blossom tree",
		cat = "garden",
		price = 160,
		place = "ground",
		size = Vector3.new(7, 10, 7),
		c1 = "F4B6C8",
		c2 = "6E4C30",
		tags = { "plant" },
		build = function(r: R)
			roots(r, 4, 0.9, 0.35, r.c2)
			rail(
				r,
				{ Vector3.new(0, 0, 0), Vector3.new(0.35, 2.6, 0.2), Vector3.new(-0.15, 5.0, 0) },
				0.7,
				0.7,
				r.c2,
				"Wood"
			)
			rod(r, Vector3.new(0, 4.2, 0), Vector3.new(-1.7, 5.8, 0.5), 0.36, r.c2, "Wood")
			rod(r, Vector3.new(0.1, 3.8, 0), Vector3.new(1.6, 5.6, -0.4), 0.36, r.c2, "Wood")
			rod(r, Vector3.new(0, 4.6, 0), Vector3.new(0.2, 6.0, -1.5), 0.3, r.c2, "Wood")
			crown(r, 0.8, r.c1, Colors.mix(r.c1, C.White, 0.35))
			-- petals fallen on the grass
			for _, p in { { 1.6, 1.2 }, { -1.4, 1.8 }, { 2.2, -1.0 }, { -2.0, -1.2 }, { 0.4, 2.4 }, { -0.6, -2.2 } } do
				r:noCollide(r:cyl(p[1], 0.02, p[2], 0.04, 0.45, "y", r.c1, "SmoothPlastic"))
			end
		end,
	},
	{
		id = "bush",
		name = "Bush",
		cat = "garden",
		price = 30,
		place = "ground",
		size = Vector3.new(3, 2.4, 3),
		c1 = "5E8E5A",
		c2 = "F7F3EA",
		tags = { "plant" },
		build = function(r: R)
			r:ball(0, 1.1, 0, 2.2, r.c1, "Grass")
			r:ball(-0.75, 0.75, 0.3, 1.5, shade(r.c1, 0.85), "Grass")
			r:ball(0.75, 0.8, -0.2, 1.6, shade(r.c1, 0.92), "Grass")
			r:ball(0.2, 0.7, 0.8, 1.3, shade(r.c1, 1.06), "Grass")
			r:ball(-0.1, 1.55, -0.4, 1.4, shade(r.c1, 1.04), "Grass")
			r:ball(0.5, 1.6, 0.35, 1.0, shade(r.c1, 1.12), "Grass")
			-- small flowers dotted over it (c2): five petals in a flat cup and a yellow middle
			r:piece(function(q: R)
				q:box(0, 1.1, 0, 0.2, 0.2, 0.2, r.c1, "SmoothPlastic")
				for i, p in
					{
						{ 0.6, 2.0, 0.55 },
						{ -0.6, 1.5, 0.82 },
						{ 0.92, 1.2, 0.85 },
						{ -0.98, 1.6, -0.4 },
						{ 0.1, 2.25, -0.3 },
						{ -0.3, 1.95, 0.4 },
						{ 1.05, 1.5, -0.25 },
						{ -0.45, 1.15, 1.0 },
					}
				do
					local out = Vector3.new(p[1], p[2] - 1.1, p[3]).Unit
					local tilt = CFrame.new(p[1], p[2], p[3]) * CFrame.Angles(out.Z * 0.7, i, -out.X * 0.7)
					q:lump(tilt, 0.42, 0.12, 0.42, r.c2, "SmoothPlastic")
					q:ball(p[1] + out.X * 0.04, p[2] + 0.07, p[3] + out.Z * 0.04, 0.13, C.Yellow, "SmoothPlastic")
				end
			end)
		end,
	},
	{
		id = "flower_bed",
		name = "Flower bed",
		cat = "garden",
		price = 50,
		place = "ground",
		size = Vector3.new(4, 1.4, 2),
		c1 = "F59EB5",
		c2 = "8E6440",
		tags = { "plant" },
		build = function(r: R)
			-- a raised bed of boards with corner posts, full of flowers at different heights:
			-- c1 the main flowers, c2 the boards
			for _, s in { -1, 1 } do
				r:block(-1.9, 0, s * 0.92 - 0.08, 1.9, 0.5, s * 0.92 + 0.08, r.c2, "Wood")
				r:block(s * 1.92 - 0.08, 0, -0.84, s * 1.92 + 0.08, 0.5, 0.84, r.c2, "Wood")
				for _, t in { -1, 1 } do
					r:box(s * 1.92, 0.3, t * 0.92, 0.22, 0.6, 0.22, shade(r.c2, 0.85), "Wood")
				end
			end
			r:block(-1.84, 0, -0.84, 1.84, 0.42, 0.84, C.Soil, "Sand")
			r:piece(function(q: R)
				leaves(q, -1.75, 1.75, -0.72, 0.72, 0.44, 7, 0.55)
			end)
			r:piece(function(q: R)
				bloom(q, -1.4, -0.4, 0.5, 1.15, r.c1, 0.3)
				bloom(q, -0.7, 0.35, 0.5, 0.95, C.White, 1.2)
				bloom(q, 0.0, -0.35, 0.5, 1.25, r.c1, 2.1)
				bloom(q, 0.75, 0.4, 0.5, 1.0, C.Yellow, 0.8)
				bloom(q, 1.45, -0.3, 0.5, 1.2, r.c1, 1.7)
				bloom(q, -1.5, 0.45, 0.5, 0.9, CORAL, 2.6)
			end)
			r:piece(function(q: R)
				spike(q, -0.4, -0.55, 0.5, 1.38, LILAC)
				spike(q, 1.0, -0.6, 0.5, 1.32, LILAC)
				bloom(q, 0.35, 0.5, 0.5, 0.88, C.White, 0.5)
				bloom(q, 1.55, 0.5, 0.5, 0.92, r.c1, 2.9)
			end)
		end,
	},
	{
		id = "rock",
		name = "Rock",
		cat = "garden",
		price = 20,
		place = "ground",
		size = Vector3.new(3, 1.6, 2.6),
		c1 = "9A9AA0",
		c2 = "6FA055",
		build = function(r: R)
			-- a boulder, a smaller stone leaning on it and a few pebbles, all sunk a little into
			-- the ground, with moss (c2) on top
			r:lump(CFrame.new(-0.2, 0.58, -0.1) * CFrame.Angles(0.12, 0.4, 0.1), 2.1, 1.25, 1.7, r.c1, "Slate")
			r:lump(
				CFrame.new(-0.35, 1.05, -0.2) * CFrame.Angles(0.05, 1.1, -0.08),
				1.2,
				0.5,
				1.0,
				shade(r.c1, 1.07),
				"Slate"
			)
			r:lump(
				CFrame.new(0.95, 0.36, 0.6) * CFrame.Angles(-0.2, 1.0, 0.25),
				1.1,
				0.78,
				0.9,
				shade(r.c1, 0.9),
				"Slate"
			)
			r:lump(
				CFrame.new(-0.95, 0.16, 0.9) * CFrame.Angles(0.1, 0.3, -0.2),
				0.6,
				0.38,
				0.5,
				shade(r.c1, 1.08),
				"Slate"
			)
			r:piece(function(q: R)
				q:box(-0.4, 1.28, -0.25, 0.5, 0.08, 0.4, r.c2, "Grass")
				q:lump(CFrame.new(-0.45, 1.28, -0.2) * CFrame.Angles(0, 0.6, 0), 0.8, 0.12, 0.6, r.c2, "Grass")
				q:lump(
					CFrame.new(-1.05, 0.95, -0.4) * CFrame.Angles(0, 0.2, 0.6),
					0.5,
					0.1,
					0.45,
					shade(r.c2, 0.9),
					"Grass"
				)
				q:lump(CFrame.new(0.85, 0.72, 0.55) * CFrame.Angles(0.2, 1.0, 0), 0.4, 0.1, 0.32, r.c2, "Grass")
			end)
			r:piece(function(q: R)
				q:box(1.25, 0.05, -0.75, 0.2, 0.1, 0.16, shade(r.c1, 0.95), "Slate")
				q:lump(
					CFrame.new(0.9, 0.07, -0.95) * CFrame.Angles(0, 0.4, 0),
					0.3,
					0.16,
					0.24,
					shade(r.c1, 1.1),
					"Slate"
				)
				q:lump(
					CFrame.new(-1.3, 0.06, -0.2) * CFrame.Angles(0, 1.2, 0),
					0.24,
					0.14,
					0.2,
					shade(r.c1, 0.88),
					"Slate"
				)
				q:lump(
					CFrame.new(0.2, 0.05, 1.15) * CFrame.Angles(0, 2.0, 0),
					0.22,
					0.12,
					0.18,
					shade(r.c1, 1.02),
					"Slate"
				)
			end)
		end,
	},
	{
		id = "pond",
		name = "Pond",
		cat = "garden",
		price = 300,
		place = "ground",
		size = Vector3.new(7, 1.6, 7),
		c1 = "6CA6CC",
		c2 = "A0A0A6",
		build = function(r: R)
			-- a dark bed with the water over it
			r:cyl(0, 0.04, 0, 0.08, 5.6, "y", Color3.fromRGB(46, 84, 90), "Slate")
			water(r:cyl(0, 0.2, 0, 0.12, 5.8, "y", r.c1, "Glass"))
			-- flat stones round the edge, a few stacked
			for i = 0, 13 do
				local t = i / 14 * math.pi * 2
				local x, z = math.cos(t) * 3.0, math.sin(t) * 3.0
				local col = if i % 3 == 0 then shade(r.c2, 0.85) elseif i % 3 == 1 then r.c2 else shade(r.c2, 1.1)
				local h = if i % 4 == 0 then 0.6 else 0.45
				r:boxAt(CFrame.new(x, h / 2, z) * CFrame.Angles(0, -t + (i % 2) * 0.3, 0), 0.8, h, 1.15, col, "Slate")
			end
			-- lily pads, a flower and some reeds
			for _, p in { { -1.2, 0.8 }, { 0.9, -1.0 }, { 0.2, 1.5 } } do
				r:noCollide(r:cyl(p[1], 0.28, p[2], 0.04, 0.8, "y", C.Leaf, "SmoothPlastic"))
			end
			r:ball(-1.1, 0.36, 0.75, 0.26, C.Pink, "SmoothPlastic")
			r:ball(-1.1, 0.42, 0.75, 0.12, C.Yellow, "SmoothPlastic")
			for _, p in { { 1.7, -1.5, 1.5 }, { 2.0, -1.0, 1.2 }, { 1.4, -1.9, 1.0 } } do
				r:noCollide(r:cyl(p[1], p[3] / 2, p[2], p[3], 0.08, "y", C.DarkLeaf, "SmoothPlastic"))
				r:noCollide(r:cyl(p[1], p[3] - 0.15, p[2], 0.35, 0.16, "y", C.Bark, "SmoothPlastic"))
			end
		end,
	},
	{
		id = "fountain",
		name = "Stone fountain",
		cat = "garden",
		price = 450,
		place = "ground",
		size = Vector3.new(6, 5.4, 6),
		c1 = "B8B4AC",
		c2 = "6CA6CC",
		build = function(r: R)
			local dk = shade(r.c1, 0.9)
			r:cyl(0, 0.1, 0, 0.2, 6, "y", dk, "Cobblestone")
			r:cyl(0, 0.6, 0, 0.9, 5.7, "y", r.c1, "Cobblestone")
			-- a raised lip round the basin
			for i = 0, 9 do
				local a1 = i / 10 * math.pi * 2
				local a2 = (i + 1) / 10 * math.pi * 2
				r:beam(
					Vector3.new(math.cos(a1) * 2.72, 1.15, math.sin(a1) * 2.72),
					Vector3.new(math.cos(a2) * 2.72, 1.15, math.sin(a2) * 2.72),
					0.45,
					0.3,
					dk,
					"Cobblestone"
				)
			end
			water(r:cyl(0, 1.06, 0, 0.08, 5.1, "y", r.c2, "Glass"))
			-- a turned pedestal, a wide bowl, and a little top bowl with a spout
			r:cyl(0, 1.3, 0, 0.5, 1.1, "y", dk, "Marble")
			r:cyl(0, 2.1, 0, 1.2, 0.7, "y", r.c1, "Marble")
			r:cyl(0, 2.8, 0, 0.2, 1.0, "y", dk, "Marble")
			r:cyl(0, 3.1, 0, 0.2, 1.9, "y", r.c1, "Marble")
			r:cyl(0, 3.35, 0, 0.3, 2.7, "y", r.c1, "Marble")
			water(r:cyl(0, 3.52, 0, 0.06, 2.4, "y", r.c2, "Glass"))
			r:cyl(0, 3.9, 0, 0.8, 0.4, "y", r.c1, "Marble")
			r:cyl(0, 4.35, 0, 0.12, 0.8, "y", dk, "Marble")
			r:cyl(0, 4.5, 0, 0.2, 1.1, "y", r.c1, "Marble")
			r:cyl(0, 4.75, 0, 0.3, 0.3, "y", r.c1, "Marble")
			water(r:ball(0, 5.05, 0, 0.45, r.c2, "Glass"), 0.3)
			-- water spilling over the wide bowl
			for i = 0, 5 do
				local a = i * math.pi / 3 + math.pi / 6
				water(r:cyl(math.cos(a) * 1.3, 2.35, math.sin(a) * 1.3, 2.1, 0.14, "y", r.c2, "Glass"), 0.4)
			end
		end,
	},
	{
		id = "bench_garden",
		name = "Garden bench",
		cat = "garden",
		price = 90,
		place = "ground",
		size = Vector3.new(5, 3.4, 2),
		c1 = "B08258",
		c2 = "2F3B35",
		tags = { "seat" },
		build = function(r: R)
			-- cast iron ends: a front leg, a back leg running up into the back, an arm with a curl
			for _, sx in { -1, 1 } do
				local x = sx * 2.2
				rail(
					r,
					{ Vector3.new(x, 0, 0.75), Vector3.new(x, 1.0, 0.68), Vector3.new(x, 2.3, 0.72) },
					0.16,
					0.18,
					r.c2,
					"Metal"
				)
				rail(
					r,
					{ Vector3.new(x, 0, -0.7), Vector3.new(x, 1.55, -0.75), Vector3.new(x, 3.3, -1.0) },
					0.16,
					0.2,
					r.c2,
					"Metal"
				)
				r:block(x - 0.08, 1.45, -0.8, x + 0.08, 1.6, 0.78, r.c2, "Metal")
				r:block(x - 0.1, 2.28, -0.85, x + 0.1, 2.4, 0.78, r.c2, "Metal")
				r:cyl(x, 2.26, 0.82, 0.2, 0.3, "x", r.c2, "Metal")
				r:block(x - 0.06, 0, -0.75, x + 0.06, 0.12, 0.8, r.c2, "Metal")
			end
			for _, z in { -0.6, -0.2, 0.2, 0.6 } do
				r:block(-2.4, 1.6, z - 0.16, 2.4, 1.75, z + 0.16, r.c1, "WoodPlanks")
			end
			for _, y in { 2.2, 2.62, 3.04 } do
				local z = -0.76 - (y - 1.6) * 0.13
				r:boxAt(CFrame.new(0, y, z) * CFrame.Angles(-0.2, 0, 0), 4.8, 0.3, 0.12, r.c1, "WoodPlanks")
			end
			r:seat(-1.1, 1.75, 0)
			r:seat(1.1, 1.75, 0)
		end,
	},
	{
		id = "picnic_table",
		name = "Picnic table",
		cat = "garden",
		price = 150,
		place = "ground",
		size = Vector3.new(5, 2.8, 5.4),
		surface = 2.8,
		c1 = "B08258",
		c2 = "8E6440",
		tags = { "seat", "table" },
		build = function(r: R)
			for _, z in { -0.9, -0.3, 0.3, 0.9 } do
				r:block(-2.5, 2.55, z - 0.27, 2.5, 2.8, z + 0.27, r.c1, "WoodPlanks")
			end
			for _, z in { -2.1, 2.1 } do
				for _, dz in { -0.18, 0.18 } do
					r:block(-2.5, 1.45, z + dz - 0.16, 2.5, 1.65, z + dz + 0.16, r.c1, "WoodPlanks")
				end
			end
			for _, x in { -1.9, 1.9 } do
				r:beam(Vector3.new(x, 0, -2.4), Vector3.new(x, 2.55, -0.4), 0.25, 0.25, r.c2, "Wood")
				r:beam(Vector3.new(x, 0, 2.4), Vector3.new(x, 2.55, 0.4), 0.25, 0.25, r.c2, "Wood")
				r:block(x - 0.12, 1.25, -2.45, x + 0.12, 1.45, 2.45, r.c2, "Wood")
				r:block(x - 0.12, 2.35, -1.2, x + 0.12, 2.55, 1.2, r.c2, "Wood")
			end
			r:beam(Vector3.new(-1.9, 1.35, 0), Vector3.new(0, 2.45, 0), 0.18, 0.18, r.c2, "Wood")
			r:beam(Vector3.new(1.9, 1.35, 0), Vector3.new(0, 2.45, 0), 0.18, 0.18, r.c2, "Wood")
			for _, x in { -1.1, 1.1 } do
				r:seat(x, 1.65, -2.1, 0)
				r:seat(x, 1.65, 2.1, 180)
			end
		end,
	},
	{
		id = "mailbox",
		name = "Mailbox",
		cat = "garden",
		price = 40,
		place = "ground",
		size = Vector3.new(1.2, 3.6, 1.8),
		c1 = "5C7FA3",
		c2 = "8E6440",
		build = function(r: R)
			r:block(-0.22, 0, -0.22, 0.22, 0.12, 0.22, shade(r.c2, 0.8), "Wood")
			r:block(-0.15, 0, -0.15, 0.15, 2.6, 0.15, r.c2, "Wood")
			r:block(-0.3, 2.45, -0.55, 0.3, 2.6, 0.55, r.c2, "Wood")
			r:beam(Vector3.new(0, 1.9, 0.12), Vector3.new(0, 2.45, 0.45), 0.12, 0.12, r.c2, "Wood")
			-- a box with a rounded top, a front door and a red flag on the side
			r:block(-0.45, 2.6, -0.8, 0.45, 3.1, 0.8, r.c1, "Metal")
			r:cyl(0, 3.1, 0, 1.6, 0.9, "z", r.c1, "Metal")
			r:block(-0.42, 2.63, 0.8, 0.42, 3.1, 0.84, shade(r.c1, 0.85), "Metal")
			r:cyl(0, 3.1, 0.82, 0.04, 0.84, "z", shade(r.c1, 0.85), "Metal")
			r:block(-0.1, 3.18, 0.84, 0.1, 3.26, 0.92, C.Metal, "Metal")
			r:block(-0.25, 2.7, 0.84, 0.25, 2.88, 0.86, C.White, "SmoothPlastic")
			r:cyl(0.47, 3.0, -0.25, 0.04, 0.12, "x", C.DarkMetal, "Metal")
			r:block(0.47, 2.75, -0.3, 0.53, 3.55, -0.22, C.Red, "Metal")
			r:block(0.47, 3.3, -0.22, 0.53, 3.55, 0.15, C.Red, "Metal")
		end,
	},
	{
		id = "swing_set",
		name = "Swing set",
		cat = "garden",
		price = 350,
		place = "ground",
		size = Vector3.new(7, 7, 4.4),
		c1 = "B8505A",
		c2 = "E8C46C",
		build = function(r: R)
			-- an A frame at each end (c1) with a brace and a cross bar, and two swings: a rubber
			-- sling (c2) on chains of links, clamped at the ends
			for _, x in { -3.2, 3.2 } do
				rod(r, Vector3.new(x, 0, -2.0), Vector3.new(x, 6.6, 0), 0.32, r.c1, "Metal")
				rod(r, Vector3.new(x, 0, 2.0), Vector3.new(x, 6.6, 0), 0.32, r.c1, "Metal")
				rod(r, Vector3.new(x, 2.0, -1.4), Vector3.new(x, 2.0, 1.4), 0.16, r.c1, "Metal")
				for _, z in { -2.0, 2.0 } do
					r:cyl(x, 0.05, z, 0.1, 0.5, "y", C.DarkMetal, "Metal")
				end
			end
			r:cyl(0, 6.6, 0, 6.8, 0.38, "x", r.c1, "Metal")
			for _, x in { -3.45, 3.45 } do
				r:cyl(x, 6.6, 0, 0.1, 0.46, "x", C.DarkMetal, "Metal")
			end
			for _, x in { -1.3, 1.3 } do
				for _, dx in { -0.55, 0.55 } do
					r:cyl(x + dx, 6.45, 0, 0.12, 0.16, "z", C.Metal, "Metal")
					r:piece(function(q: R)
						-- a chain: each link turned across the one before
						local y0, y1, n = 1.76, 6.4, 23
						local step = (y1 - y0) / n
						for k = 0, n - 1 do
							local y = y0 + (k + 0.5) * step
							if k % 2 == 0 then
								q:box(x + dx, y, 0, 0.1, step + 0.06, 0.03, C.DarkMetal, "Metal")
							else
								q:box(x + dx, y, 0, 0.03, step + 0.06, 0.1, C.DarkMetal, "Metal")
							end
						end
					end)
				end
				r:block(x - 0.42, 1.46, -0.32, x + 0.42, 1.56, 0.32, r.c2, "Rubber")
				for _, sx in { -1, 1 } do
					r:boxAt(
						CFrame.new(x + sx * 0.56, 1.58, 0) * CFrame.Angles(0, 0, sx * 0.45),
						0.34,
						0.1,
						0.64,
						r.c2,
						"Rubber"
					)
					r:block(x + sx * 0.55 - 0.06, 1.62, -0.06, x + sx * 0.55 + 0.06, 1.8, 0.06, C.DarkMetal, "Metal")
				end
				r:seat(x, 1.6, 0)
			end
		end,
	},
	{
		id = "slide",
		name = "Slide",
		cat = "garden",
		price = 280,
		place = "ground",
		size = Vector3.new(3, 7.4, 8),
		c1 = "5C7FA3",
		c2 = "E8C46C",
		build = function(r: R)
			-- a deck on four posts with rails round it, under a little peaked roof
			for _, x in { -1.1, 1.1 } do
				for _, z in { -2.7, -1.3 } do
					r:box(x, 3.15, z, 0.25, 6.3, 0.25, r.c1, "Metal")
				end
				r:block(x - 0.08, 5.1, -2.8, x + 0.08, 5.22, -1.2, r.c1, "Metal")
				for _, z in { -2.4, -2.0, -1.6 } do
					r:block(x - 0.04, 4.25, z - 0.04, x + 0.04, 5.1, z + 0.04, r.c1, "Metal")
				end
			end
			r:block(-1.2, 4.0, -2.8, 1.2, 4.25, -1.2, shade(r.c1, 1.25), "WoodPlanks")
			r:block(-1.1, 5.1, -2.8, 1.1, 5.22, -2.68, r.c1, "Metal")
			r:ramp(-1.35, 6.3, -3.0, 1.35, 7.3, -2.0, true, r.c2, "Plastic")
			r:ramp(-1.35, 6.3, -2.0, 1.35, 7.3, -1.0, false, r.c2, "Plastic")
			r:block(-1.35, 7.2, -2.08, 1.35, 7.35, -1.92, shade(r.c2, 0.8), "Plastic")
			-- the ladder at the back
			for _, x in { -0.7, 0.7 } do
				r:beam(Vector3.new(x, 0, -3.8), Vector3.new(x, 4.25, -2.8), 0.15, 0.15, r.c1, "Metal")
			end
			for i = 1, 4 do
				local f = i / 5
				r:block(-0.7, f * 4.25 - 0.05, -3.8 + f - 0.08, 0.7, f * 4.25 + 0.05, -3.8 + f + 0.08, C.Metal, "Metal")
			end
			-- the chute, its sides and the flat end
			local top, foot = Vector3.new(0, 4.15, -1.2), Vector3.new(0, 0.75, 3.0)
			r:beam(top, foot, 1.4, 0.12, r.c2, "Plastic")
			for _, x in { -0.76, 0.76 } do
				r:beam(
					top + Vector3.new(x, 0.2, 0),
					foot + Vector3.new(x, 0.2, 0),
					0.12,
					0.45,
					shade(r.c2, 0.85),
					"Plastic"
				)
				r:block(x - 0.06, 0.55, 3.0, x + 0.06, 1.0, 3.9, shade(r.c2, 0.85), "Plastic")
			end
			r:block(-0.7, 0.55, 2.95, 0.7, 0.7, 3.9, r.c2, "Plastic")
			r:block(-0.15, 0, 2.6, 0.15, 0.6, 2.9, r.c1, "Metal")
		end,
	},
	{
		id = "sandbox",
		name = "Sandbox",
		cat = "garden",
		price = 80,
		place = "ground",
		size = Vector3.new(5, 1.2, 5),
		c1 = "C99A62",
		c2 = "EBD9A6",
		tags = { "toy" },
		build = function(r: R)
			for _, s in { -1, 1 } do
				r:block(-2.5, 0, s * 2.5 - 0.35 * s, 2.5, 0.7, s * 2.5, r.c1, "WoodPlanks")
				r:block(s * 2.5 - 0.35 * s, 0, -2.15, s * 2.5, 0.7, 2.15, r.c1, "WoodPlanks")
				r:block(-2.5, 0.7, s * 2.5 - 0.45 * s, 2.5, 0.78, s * 2.5 + 0.03 * s, shade(r.c1, 0.9), "Wood")
			end
			-- corner seats
			for _, sx in { -1, 1 } do
				for _, sz in { -1, 1 } do
					r:tri(
						Vector3.new(sx * 2.15, 0.74, sz * 2.15),
						Vector3.new(sx * 1.2, 0.74, sz * 2.15),
						Vector3.new(sx * 2.15, 0.74, sz * 1.2),
						0.1,
						shade(r.c1, 0.9),
						"Wood"
					)
				end
			end
			r:block(-2.15, 0, -2.15, 2.15, 0.45, 2.15, r.c2, "Sand")
			r:cyl(0.8, 0.5, -0.6, 0.3, 1.6, "y", r.c2, "Sand")
			-- a sand castle, a bucket and a spade
			r:block(0.5, 0.6, -0.9, 1.1, 1.0, -0.3, shade(r.c2, 0.95), "Sand")
			r:block(0.65, 1.0, -0.75, 0.95, 1.2, -0.45, shade(r.c2, 0.95), "Sand")
			r:cyl(-1.0, 0.7, 0.8, 0.5, 0.55, "y", C.Red, "Plastic")
			r:beam(Vector3.new(-1.27, 0.9, 0.8), Vector3.new(-1.0, 1.15, 0.8), 0.04, 0.04, C.Red, "Plastic")
			r:beam(Vector3.new(-0.73, 0.9, 0.8), Vector3.new(-1.0, 1.15, 0.8), 0.04, 0.04, C.Red, "Plastic")
			r:beam(Vector3.new(-0.2, 0.5, 1.2), Vector3.new(0.4, 0.62, 1.6), 0.08, 0.08, C.Blue, "Plastic")
			r:boxAt(CFrame.new(-0.35, 0.5, 1.05) * CFrame.Angles(0, -0.6, 0), 0.35, 0.05, 0.4, C.Blue, "Plastic")
		end,
	},
	{
		id = "campfire",
		name = "Campfire",
		cat = "garden",
		price = 60,
		place = "ground",
		size = Vector3.new(3, 1.4, 3),
		c1 = "8C8C92",
		c2 = "6E4C30",
		tags = { "light" },
		build = function(r: R)
			-- a ring of rough stones round glowing embers, and logs leaned together over them
			r:piece(function(q: R)
				q:box(0, 0.03, 0, 0.3, 0.06, 0.3, shade(r.c1, 0.6), "Slate")
				for i = 0, 8 do
					local t = i / 9 * math.pi * 2
					q:lump(
						CFrame.new(math.cos(t) * 1.15, 0.15, math.sin(t) * 1.15)
							* CFrame.Angles(0.1, -t + (i % 2) * 0.5, 0.08),
						0.56,
						0.38,
						0.46,
						if i % 2 == 0 then r.c1 else shade(r.c1, 1.12),
						"Slate"
					)
				end
			end)
			local ember = r:cyl(0, 0.05, 0, 0.1, 1.3, "y", Color3.fromRGB(255, 120, 50), "SmoothPlastic")
			r:glow(ember, 20, 1.5, Color3.fromRGB(255, 160, 90))
			for i = 0, 3 do
				local a = i * math.pi / 2 + 0.3
				rod(
					r,
					Vector3.new(math.cos(a) * 0.7, 0.1, math.sin(a) * 0.7),
					Vector3.new(0, 1.1, 0),
					0.2,
					if i % 2 == 0 then r.c2 else shade(r.c2, 1.15),
					"Wood"
				)
			end
			local top = r:cyl(0, 0.3, 0, 1.4, 0.3, "x", shade(r.c2, 0.85), "Wood")
			r:fire(top)
		end,
	},
	{
		id = "well",
		name = "Well",
		cat = "garden",
		price = 220,
		place = "ground",
		size = Vector3.new(4, 6.6, 4),
		c1 = "A0A0A6",
		c2 = "B0624E",
		build = function(r: R)
			r:cyl(0, 1.0, 0, 2.0, 3.4, "y", r.c1, "Cobblestone")
			r:cyl(0, 0.1, 0, 0.2, 3.6, "y", shade(r.c1, 0.85), "Cobblestone")
			r:cyl(0, 2.12, 0, 0.25, 3.7, "y", shade(r.c1, 0.9), "Cobblestone")
			r:cyl(0, 2.26, 0, 0.04, 2.8, "y", Color3.fromRGB(40, 70, 90), "Glass")
			for _, x in { -1.5, 1.5 } do
				r:box(x, 3.65, 0, 0.3, 3.3, 0.3, C.Bark, "Wood")
			end
			r:block(-1.65, 5.2, -0.12, 1.65, 5.42, 0.12, C.Bark, "Wood")
			-- a shingled roof
			r:ramp(-1.95, 5.1, -2.0, 1.95, 6.45, 0, true, r.c2, "Slate")
			r:ramp(-1.95, 5.1, 0, 1.95, 6.45, 2.0, false, r.c2, "Slate")
			for _, sz in { -1, 1 } do
				r:block(-2.0, 5.0, sz * 2.0 - 0.1, 2.0, 5.15, sz * 2.0 + 0.1, shade(r.c2, 0.8), "Slate")
			end
			r:block(-2.0, 6.35, -0.15, 2.0, 6.55, 0.15, shade(r.c2, 0.8), "Slate")
			-- the winch, its crank, the rope and a banded bucket
			r:cyl(0, 4.3, 0, 3.0, 0.32, "x", C.Bark, "Wood")
			r:block(1.65, 4.0, -0.04, 1.75, 4.35, 0.04, C.DarkMetal, "Metal")
			r:block(1.65, 3.95, -0.04, 1.95, 4.05, 0.04, C.DarkMetal, "Metal")
			r:cyl(0, 3.75, 0, 1.0, 0.06, "y", C.Cream, "Fabric")
			r:cyl(0, 3.05, 0, 0.45, 0.55, "y", shade(C.Bark, 1.3), "WoodPlanks")
			r:cyl(0, 3.15, 0, 0.06, 0.57, "y", C.DarkMetal, "Metal")
		end,
	},
	{
		id = "gnome",
		name = "Garden gnome",
		cat = "garden",
		price = 25,
		place = "ground",
		size = Vector3.new(1, 2, 1),
		c1 = "B8505A",
		c2 = "5A80B0",
		build = function(r: R)
			-- a garden gnome: boots, a coat (c2) with a belt, arms, a white beard, a round nose
			-- and a tall pointed hat (c1) tipped back a little
			local skin = Color3.fromRGB(245, 205, 175)
			for _, x in { -0.15, 0.15 } do
				r:lump(CFrame.new(x, 0.09, 0.06), 0.26, 0.18, 0.38, C.Bark, "SmoothPlastic")
			end
			r:cyl(0, 0.38, 0, 0.44, 0.7, "y", r.c2, "SmoothPlastic")
			r:cyl(0, 0.7, 0, 0.2, 0.58, "y", r.c2, "SmoothPlastic")
			r:cyl(0, 0.54, 0, 0.09, 0.78, "y", C.Black, "SmoothPlastic")
			r:block(-0.09, 0.5, 0.36, 0.09, 0.58, 0.43, C.Gold, "Metal")
			for _, sx in { -1, 1 } do
				r:lump(
					CFrame.new(sx * 0.34, 0.62, 0.06) * CFrame.Angles(0.3, 0, sx * 0.35),
					0.2,
					0.36,
					0.22,
					r.c2,
					"SmoothPlastic"
				)
				r:ball(sx * 0.38, 0.45, 0.15, 0.15, skin, "SmoothPlastic")
			end
			r:lump(CFrame.new(0, 0.8, 0.2) * CFrame.Angles(0.35, 0, 0), 0.46, 0.56, 0.26, C.White, "SmoothPlastic")
			r:ball(0, 1.06, 0.04, 0.46, skin, "SmoothPlastic")
			r:lump(CFrame.new(0, 0.98, 0.24) * CFrame.Angles(0, 0, 0), 0.32, 0.1, 0.12, C.White, "SmoothPlastic")
			r:ball(0, 1.04, 0.28, 0.15, Color3.fromRGB(232, 150, 140), "SmoothPlastic")
			for _, sx in { -1, 1 } do
				r:ball(sx * 0.1, 1.13, 0.24, 0.06, C.Black, "SmoothPlastic")
			end
			r:cyl(0, 1.23, 0, 0.08, 0.6, "y", r.c1, "SmoothPlastic")
			r:add({
				shape = "Cone",
				cf = CFrame.new(0, 1.62, -0.04) * CFrame.Angles(-0.12, 0, 0),
				size = Vector3.new(0.54, 0.76, 0.54),
				color = r.c1,
				mat = "SmoothPlastic",
			})
		end,
	},
	{
		id = "umbrella_sun",
		name = "Sun umbrella",
		cat = "garden",
		price = 120,
		place = "ground",
		size = Vector3.new(6, 6.6, 6),
		c1 = "DC806A",
		c2 = "F7F3EA",
		build = function(r: R)
			r:cyl(0, 0.12, 0, 0.24, 1.3, "y", C.DarkMetal, "Metal")
			r:cyl(0, 0.3, 0, 0.12, 0.5, "y", C.DarkMetal, "Metal")
			r:cyl(0, 3.2, 0, 6.0, 0.16, "y", C.White, "Metal")
			r:cyl(0, 2.4, 0, 0.3, 0.26, "y", C.Metal, "Metal")
			r:cyl(0.16, 2.4, 0, 0.06, 0.3, "x", C.Metal, "Metal")
			-- eight panels in two colours, with a flap hanging off each edge
			local apex = Vector3.new(0, 6.3, 0)
			for i = 0, 7 do
				local a1 = i / 8 * math.pi * 2
				local a2 = (i + 1) / 8 * math.pi * 2
				local p1 = Vector3.new(math.cos(a1) * 2.9, 5.0, math.sin(a1) * 2.9)
				local p2 = Vector3.new(math.cos(a2) * 2.9, 5.0, math.sin(a2) * 2.9)
				local col = if i % 2 == 0 then r.c1 else r.c2
				r:tri(p1, p2, apex, 0.08, col, "Fabric")
				local mid = (p1 + p2) / 2
				local am = (a1 + a2) / 2
				r:boxAt(
					CFrame.new(mid.X, 4.82, mid.Z) * CFrame.Angles(0, -am + math.pi / 2, 0),
					(p2 - p1).Magnitude,
					0.36,
					0.04,
					col,
					"Fabric"
				)
				rod(
					r,
					Vector3.new(0, 4.4, 0),
					Vector3.new(math.cos(a1) * 2.0, 5.38, math.sin(a1) * 2.0),
					0.04,
					C.Metal,
					"Metal"
				)
			end
			r:ball(0, 6.4, 0, 0.28, C.White, "Metal")
		end,
	},
	{
		id = "planter_box",
		name = "Planter box",
		cat = "garden",
		price = 50,
		place = "ground",
		size = Vector3.new(4, 2.2, 1.6),
		c1 = "B08258",
		c2 = "E8C46C",
		tags = { "plant" },
		build = function(r: R)
			-- a trough of boards on four feet (c1), a rail round its top with the earth inside,
			-- leaves spilling over its sides and flowers (c2) standing up at different heights
			for _, sx in { -1, 1 } do
				for _, sz in { -1, 1 } do
					r:box(sx * 1.8, 0.2, sz * 0.6, 0.3, 0.4, 0.3, shade(r.c1, 0.8), "Wood")
				end
			end
			for i = 0, 2 do
				local y = 0.4 + i * 0.3
				r:block(-2, y, -0.8, 2, y + 0.28, 0.8, if i % 2 == 0 then r.c1 else shade(r.c1, 0.92), "WoodPlanks")
			end
			r:piece(function(q: R)
				q:block(-2.05, 1.3, -0.85, 2.05, 1.4, -0.65, shade(r.c1, 0.85), "Wood")
				q:block(-2.05, 1.3, 0.65, 2.05, 1.4, 0.85, shade(r.c1, 0.85), "Wood")
				for _, sx in { -1, 1 } do
					q:block(sx * 1.95 - 0.1, 1.3, -0.65, sx * 1.95 + 0.1, 1.4, 0.65, shade(r.c1, 0.85), "Wood")
				end
			end)
			r:block(-1.85, 1.28, -0.65, 1.85, 1.35, 0.65, C.Soil, "Sand")
			r:piece(function(q: R)
				leaves(q, -1.8, 1.8, -0.52, 0.52, 1.4, 6, 0.62)
				for _, x in { -1.5, -0.4, 0.7, 1.6 } do
					trail(q, x, 1.38, 0.95, 0.45 + (x % 0.5), 0.3)
				end
				for _, x in { -1.0, 1.1 } do
					trail(q, x, 1.38, -0.95, 0.4, -0.3)
				end
			end)
			r:piece(function(q: R)
				bloom(q, -1.45, 0.2, 1.45, 1.95, r.c2, 0.4)
				bloom(q, -0.75, -0.25, 1.45, 2.12, C.White, 1.3)
				bloom(q, 0.05, 0.25, 1.45, 1.9, r.c2, 2.2)
				bloom(q, 0.9, -0.2, 1.45, 2.08, CORAL, 0.9)
				bloom(q, 1.55, 0.2, 1.45, 1.94, r.c2, 1.8)
				spike(q, -0.3, -0.3, 1.45, 2.18, LILAC)
				spike(q, 1.25, -0.35, 1.45, 2.15, LILAC)
			end)
		end,
	},
	{
		id = "path_stones",
		name = "Stepping stones",
		cat = "garden",
		price = 15,
		place = "ground",
		size = Vector3.new(2, 0.2, 2),
		c1 = "A8A49C",
		c2 = "A8A49C",
		build = function(r: R)
			-- four flat stones, each two rounded slabs laid over each other so its edge isn't
			-- even, and tufts of grass coming up between them
			local function stone(x: number, z: number, d: number, turn: number, k: number)
				for j = 0, 1 do
					r:add({
						shape = "Cylinder",
						cf = CFrame.new(x + j * 0.07, 0.07, z - j * 0.05)
							* CFrame.Angles(0, turn + j * 0.5, 0)
							* CFrame.Angles(0, 0, math.pi / 2),
						size = Vector3.new(0.14, d * (1 - j * 0.12), d * (0.86 - j * 0.04)),
						color = shade(r.c1, k),
						mat = "Slate",
					})
				end
			end
			stone(-0.35, -0.4, 1.1, 0.2, 1)
			stone(0.5, 0.3, 0.9, 1.1, 0.93)
			stone(-0.45, 0.62, 0.65, 2.0, 1.06)
			stone(0.62, -0.62, 0.42, 0.6, 0.98)
			r:piece(function(q: R)
				for i, p in { { 0.15, -0.95 }, { -0.95, 0.15 }, { 0.95, 0.85 }, { -0.05, 0.95 } } do
					q:box(p[1], 0.02, p[2], 0.1, 0.04, 0.1, C.DarkLeaf, "Grass")
					for k = 0, 2 do
						q:add({
							shape = "Cone",
							cf = CFrame.new(p[1] + (k - 1) * 0.06, 0.1, p[2] + (k % 2) * 0.04)
								* CFrame.Angles(0, i, (k - 1) * 0.45),
							size = Vector3.new(0.07, 0.2 - k * 0.03, 0.07),
							color = if k == 1 then C.Leaf else C.DarkLeaf,
							mat = "Grass",
						})
					end
				end
			end)
		end,
	},
	{
		id = "bbq",
		name = "BBQ grill",
		cat = "garden",
		price = 180,
		place = "ground",
		size = Vector3.new(2.6, 3.2, 2.2),
		c1 = "B8505A",
		c2 = "45454A",
		build = function(r: R)
			-- three legs, two of them on wheels, with a shelf ring between
			for i = 0, 2 do
				local a = i / 3 * math.pi * 2 + math.pi / 2
				local foot = Vector3.new(math.cos(a) * 0.85, 0, math.sin(a) * 0.85)
				rod(
					r,
					Vector3.new(math.cos(a) * 0.45, 1.75, math.sin(a) * 0.45),
					foot + Vector3.new(0, 0.12, 0),
					0.1,
					r.c2,
					"Metal"
				)
				if i > 0 then
					r:cyl(foot.X, 0.15, foot.Z, 0.1, 0.3, "x", C.Black, "Rubber")
				end
			end
			r:cyl(0, 0.6, 0, 0.06, 1.2, "y", r.c2, "Metal")
			r:cyl(0, 1.75, 0, 0.3, 1.4, "y", r.c1, "Metal")
			r:cyl(0, 2.1, 0, 0.5, 1.9, "y", r.c1, "Metal")
			r:cyl(0, 2.37, 0, 0.04, 1.85, "y", C.Metal, "Metal")
			-- the domed lid, a little vent and the handle
			r:cyl(0, 2.55, 0, 0.3, 1.85, "y", r.c1, "Metal")
			r:cyl(0, 2.8, 0, 0.22, 1.35, "y", r.c1, "Metal")
			r:cyl(0, 2.93, 0, 0.06, 0.8, "y", r.c1, "Metal")
			local vent = r:cyl(0.35, 2.98, 0, 0.06, 0.25, "y", r.c2, "Metal")
			vent.effect = "smoke"
			r:block(-0.25, 3.08, -0.05, 0.25, 3.15, 0.05, r.c2, "Metal")
			for _, x in { -0.2, 0.2 } do
				r:block(x - 0.03, 2.95, -0.03, x + 0.03, 3.08, 0.03, r.c2, "Metal")
			end
			-- a side shelf with tools hanging under it
			r:block(0.95, 2.0, -0.5, 1.3, 2.06, 0.5, Color3.fromRGB(176, 130, 88), "Wood")
			r:block(0.9, 1.6, -0.04, 1.0, 2.0, 0.04, r.c2, "Metal")
			for _, z in { -0.3, 0.3 } do
				r:block(1.23, 1.4, z - 0.02, 1.27, 2.0, z + 0.02, C.Metal, "Metal")
				r:block(1.21, 1.3, z - 0.07, 1.29, 1.42, z + 0.07, C.Metal, "Metal")
			end
		end,
	},
	{
		id = "beach_chair",
		name = "Beach chair",
		cat = "garden",
		price = 70,
		place = "ground",
		size = Vector3.new(2.2, 2.8, 3.4),
		c1 = "6AA2C8",
		c2 = "C99A62",
		tags = { "seat" },
		build = function(r: R)
			for _, sx in { -1, 1 } do
				local x = sx * 0.95
				r:beam(Vector3.new(x, 0, 1.45), Vector3.new(x, 1.4, 1.2), 0.12, 0.14, r.c2, "Wood")
				r:beam(Vector3.new(x, 0, -0.3), Vector3.new(x, 2.7, -1.55), 0.12, 0.14, r.c2, "Wood")
				r:beam(Vector3.new(x, 1.35, 1.3), Vector3.new(x, 0.75, -0.7), 0.12, 0.14, r.c2, "Wood")
				r:block(x - 0.08, 1.35, -0.4, x + 0.08, 1.45, 1.3, r.c2, "Wood")
			end
			r:cyl(0, 2.62, -1.5, 2.0, 0.14, "x", r.c2, "Wood")
			r:cyl(0, 1.32, 1.22, 2.0, 0.14, "x", r.c2, "Wood")
			-- a striped sling that sags into a seat
			for i = 0, 2 do
				local x = -0.6 + i * 0.6
				local col = if i % 2 == 0 then r.c1 else C.White
				r:beam(Vector3.new(x, 1.25, 1.2), Vector3.new(x, 0.9, 0.0), 0.6, 0.06, col, "Fabric")
				r:beam(Vector3.new(x, 0.9, 0.0), Vector3.new(x, 2.55, -1.45), 0.6, 0.06, col, "Fabric")
			end
			r:seat(0, 0.95, 0.3)
		end,
	},
	{
		id = "woodpile",
		name = "Woodpile",
		cat = "garden",
		price = 40,
		place = "ground",
		size = Vector3.new(3.4, 2.7, 1.4),
		c1 = "6E4C34",
		c2 = "6E4C34",
		build = function(r: R)
			-- a rack of two runners and four uprights (c1), stacked with split logs
			for _, sz in { -1, 1 } do
				r:block(-1.6, 0, sz * 0.35 - 0.1, 1.6, 0.22, sz * 0.35 + 0.1, r.c1, "Wood")
				for _, sx in { -1, 1 } do
					r:block(sx * 1.6 - 0.1, 0.22, sz * 0.35 - 0.1, sx * 1.6 + 0.1, 2.6, sz * 0.35 + 0.1, r.c1, "Wood")
				end
			end
			local pale = Color3.fromRGB(214, 178, 128)
			local tones = { C.Bark, shade(C.Bark, 1.22), pale, shade(C.Bark, 0.86) }
			r:piece(function(q: R)
				-- a bundle of kindling on top, then the logs in four rows, their ends to the front
				q:box(0.3, 2.3, 0, 1.3, 0.16, 1.0, pale, "Wood")
				local n = 0
				for row = 0, 3 do
					local count = if row % 2 == 0 then 5 else 4
					for i = 0, count - 1 do
						n += 1
						local x = (i - (count - 1) / 2) * 0.58
						q:cyl(x, 0.5 + row * 0.49, 0, 1.2, 0.56, "z", tones[(n * 3 + row) % #tones + 1], "Wood")
					end
				end
			end, true)
		end,
	},
	{
		id = "hanging_basket",
		name = "Hanging basket",
		cat = "garden",
		price = 35,
		place = "wall",
		size = Vector3.new(1.8, 3.4, 2),
		c1 = "AD7E55",
		c2 = "F59EB5",
		tags = { "plant" },
		build = function(r: R)
			-- an iron bracket on the wall, three chains and a basket of flowers: c1 the basket,
			-- c2 the flowers
			r:piece(function(q: R)
				q:block(-0.1, 2.3, 0, 0.1, 3.35, 0.08, C.DarkMetal, "Metal")
				q:block(-0.06, 3.14, 0.08, 0.06, 3.26, 1.3, C.DarkMetal, "Metal")
				q:beam(Vector3.new(0, 2.4, 0.08), Vector3.new(0, 3.14, 0.9), 0.08, 0.08, C.DarkMetal, "Metal")
				for i = 0, 2 do
					local a = i * math.pi * 2 / 3 + 0.5
					q:beam(
						Vector3.new(0, 3.14, 1.1),
						Vector3.new(math.cos(a) * 0.6, 2.0, 1.1 + math.sin(a) * 0.6),
						0.05,
						0.05,
						C.DarkMetal,
						"Metal"
					)
				end
			end)
			r:cyl(0, 1.8, 1.1, 0.45, 1.36, "y", r.c1, "Wood")
			r:cyl(0, 1.45, 1.1, 0.25, 0.9, "y", shade(r.c1, 0.82), "Wood")
			r:piece(function(q: R)
				q:box(0, 2.05, 1.1, 0.8, 0.2, 0.8, C.DarkLeaf, "Grass")
				q:ball(0, 2.25, 1.1, 1.0, C.Leaf, "Grass")
				q:ball(-0.45, 2.1, 1.3, 0.6, C.DarkLeaf, "Grass")
				q:ball(0.4, 2.12, 0.85, 0.62, C.Leaf, "Grass")
				-- stems trailing over the rim
				q:ball(0.62, 1.6, 1.45, 0.42, C.Leaf, "Grass")
				q:ball(-0.66, 1.45, 0.9, 0.38, C.DarkLeaf, "Grass")
				q:ball(0.1, 1.3, 1.72, 0.34, C.Leaf, "Grass")
			end)
			r:piece(function(q: R)
				for i, p in
					{
						{ 0, 2.72, 1.1 },
						{ -0.42, 2.45, 1.42 },
						{ 0.46, 2.5, 1.3 },
						{ 0.3, 2.42, 0.72 },
						{ -0.4, 2.4, 0.8 },
					}
				do
					bloom(q, p[1], p[3], 2.1, p[2], if i == 4 then C.White else r.c2, i * 1.1)
				end
			end)
		end,
	},
	{
		id = "bicycle",
		name = "Bicycle",
		cat = "garden",
		price = 100,
		place = "ground",
		size = Vector3.new(1.4, 3.4, 5.2),
		c1 = "6AA2C8",
		c2 = "8E6440",
		build = function(r: R)
			-- a town bike on its stand, front wheel to +z: c1 the frame, c2 the saddle and basket.
			-- Each wheel is a tyre round a rim with spokes and a hub; the stays and the fork come
			-- down either side of the wheels to their hubs.
			local bb = Vector3.new(0, 1.05, -0.25) -- where the pedals turn
			local seat = Vector3.new(0, 2.55, -0.75)
			local head = Vector3.new(0, 2.75, 1.0)
			local rear, front = Vector3.new(0, 1, -1.55), Vector3.new(0, 1, 1.55)
			r:piece(function(q: R)
				q:box(0, 1.05, -0.25, 0.34, 0.3, 0.3, C.DarkMetal, "Metal")
				for _, hub in { rear, front } do
					q:cyl(hub.X, hub.Y, hub.Z, 0.14, 2.0, "x", C.Black, "Metal")
					q:cyl(hub.X, hub.Y, hub.Z, 0.2, 1.62, "x", Color3.fromRGB(205, 208, 214), "Metal")
					q:cyl(hub.X, hub.Y, hub.Z, 0.4, 0.3, "x", C.DarkMetal, "Metal")
					for k = 0, 2 do
						q:boxAt(
							CFrame.new(hub) * CFrame.Angles(k * math.pi / 3, 0, 0),
							0.26,
							1.5,
							0.03,
							C.Metal,
							"Metal"
						)
					end
				end
				-- cranks and pedals, the handlebar on its stem, the stand and a carrier at the back
				q:beam(Vector3.new(0.24, 1.4, -0.1), Vector3.new(0.24, 0.7, -0.4), 0.08, 0.1, C.Metal, "Metal")
				q:box(0.4, 1.42, -0.1, 0.3, 0.08, 0.22, C.Black, "Metal")
				q:box(0.4, 0.68, -0.4, 0.3, 0.08, 0.22, C.Black, "Metal")
				q:beam(head, Vector3.new(0, 3.25, 0.92), 0.1, 0.1, C.Metal, "Metal")
				q:cyl(0, 3.25, 0.92, 1.3, 0.1, "x", C.Metal, "Metal")
				q:cyl(-0.58, 3.25, 0.92, 0.24, 0.16, "x", C.Black, "Metal")
				q:cyl(0.58, 3.25, 0.92, 0.24, 0.16, "x", C.Black, "Metal")
				q:beam(Vector3.new(-0.12, 1.0, -0.6), Vector3.new(-0.5, 0.03, -0.95), 0.07, 0.07, C.Metal, "Metal")
				q:box(0, 2.12, -1.65, 0.44, 0.06, 1.1, C.Metal, "Metal")
				q:beam(Vector3.new(0, 2.1, -2.1), rear + Vector3.new(0, 0.25, 0), 0.06, 0.06, C.Metal, "Metal")
			end)
			local w = 0.14
			r:beam(seat, head, w, w, r.c1, "Metal")
			r:beam(head, bb, w, w, r.c1, "Metal")
			r:beam(bb, Vector3.new(0, 2.92, -0.87), w, w, r.c1, "Metal")
			for _, sx in { -1, 1 } do
				local hubRear = rear + Vector3.new(sx * 0.24, 0, 0)
				r:beam(bb + Vector3.new(sx * 0.06, 0, 0), hubRear, 0.08, 0.08, r.c1, "Metal")
				r:beam(seat + Vector3.new(sx * 0.06, 0, 0), hubRear, 0.08, 0.08, r.c1, "Metal")
				r:beam(
					head + Vector3.new(sx * 0.07, -0.12, 0.02),
					front + Vector3.new(sx * 0.24, 0, 0),
					0.08,
					0.08,
					r.c1,
					"Metal"
				)
			end
			r:boxAt(CFrame.new(0, 3.0, -0.92) * CFrame.Angles(0.08, 0, 0), 0.42, 0.14, 0.82, r.c2, "Leather")
			-- a basket on the handlebar with a loaf in it
			r:block(-0.45, 2.6, 1.2, 0.45, 3.1, 1.9, r.c2, "WoodPlanks")
			r:block(-0.5, 3.1, 1.15, 0.5, 3.18, 1.95, shade(r.c2, 0.8), "Wood")
			r:lump(
				CFrame.new(0.1, 3.22, 1.55) * CFrame.Angles(0, 0.4, 0.3),
				0.3,
				0.22,
				0.7,
				Color3.fromRGB(214, 164, 96),
				"SmoothPlastic"
			)
		end,
	},
	{
		id = "fence_picket",
		name = "Picket fence panel",
		cat = "garden",
		price = 8,
		place = "ground",
		size = Vector3.new(4, 3.1, 0.4),
		c1 = "FAF6EC",
		c2 = "FAF6EC",
		build = function(r: R)
			-- four studs of fence, to go with the garden gate: a post each end with a cap and a
			-- little point, two rails behind (c2), and five pickets with pointed tops (c1) that
			-- rise to the middle
			r:piece(function(q: R)
				for _, sx in { -1, 1 } do
					q:block(sx * 1.86 - 0.14, 0, -0.14, sx * 1.86 + 0.14, 2.84, 0.14, r.c2, "Wood")
					q:block(sx * 1.86 - 0.18, 2.84, -0.18, sx * 1.86 + 0.18, 2.92, 0.18, r.c2, "Wood")
					q:cone(sx * 1.86, 3.01, 0, 0.18, 0.28, r.c2, "Wood")
				end
				for _, y in { 0.8, 2.0 } do
					q:block(-1.72, y, -0.14, 1.72, y + 0.24, -0.04, r.c2, "Wood")
				end
			end, true)
			r:piece(function(q: R)
				for i, h in { 2.25, 2.45, 2.6, 2.45, 2.25 } do
					local x = -1.36 + (i - 1) * 0.68
					q:block(x - 0.22, 0.25, -0.04, x + 0.22, h, 0.06, r.c1, "Wood")
					q:boxAt(CFrame.new(x, h, 0.01) * CFrame.Angles(0, 0, math.pi / 4), 0.31, 0.31, 0.1, r.c1, "Wood")
				end
			end, true)
		end,
	},
	{
		id = "gate_garden",
		name = "Garden gate",
		cat = "garden",
		price = 30,
		place = "ground",
		size = Vector3.new(4.4, 4, 0.6),
		c1 = "FAF6EC",
		c2 = "FAF6EC",
		build = function(r: R)
			-- two posts with a ball on top (c2), and a picket gate between them (c1) on iron
			-- hinges, with a brace and a latch, that swings open like a door when somebody comes
			-- up to it
			-- the posts are parts of their own, so the way between them stays open (a piece
			-- that collides does so as one box)
			for _, sx in { -1, 1 } do
				r:block(sx * 1.95 - 0.22, 0, -0.22, sx * 1.95 + 0.22, 3.4, 0.22, r.c2, "Wood")
			end
			r:piece(function(q: R)
				for _, sx in { -1, 1 } do
					q:block(sx * 1.95 - 0.3, 3.4, -0.3, sx * 1.95 + 0.3, 3.52, 0.3, r.c2, "Wood")
					q:ball(sx * 1.95, 3.76, 0, 0.5, r.c2, "Wood")
				end
				for _, y in { 0.86, 2.11 } do
					q:block(-1.75, y - 0.08, -0.17, -1.62, y + 0.08, -0.1, C.DarkMetal, "Wood")
				end
				q:block(1.62, 1.66, 0.1, 1.75, 1.9, 0.22, C.DarkMetal, "Wood")
			end)
			local hinge = -1.7
			local leaf = {}
			for _, y in { 0.75, 2.0 } do
				table.insert(leaf, r:block(-1.68, y, -0.12, 1.66, y + 0.24, -0.02, r.c1, "Wood"))
				table.insert(leaf, r:block(-1.68, y + 0.05, -0.16, -1.0, y + 0.19, -0.12, C.DarkMetal, "Metal"))
			end
			for i, h in { 2.7, 2.5, 2.35, 2.5, 2.7 } do
				local x = -1.36 + (i - 1) * 0.68
				table.insert(leaf, r:block(x - 0.22, 0.3, -0.02, x + 0.22, h, 0.08, r.c1, "Wood"))
				table.insert(
					leaf,
					r:boxAt(CFrame.new(x, h, 0.03) * CFrame.Angles(0, 0, math.pi / 4), 0.31, 0.31, 0.1, r.c1, "Wood")
				)
			end
			local brace = r:beam(Vector3.new(-1.6, 0.85, -0.07), Vector3.new(1.6, 2.1, -0.07), 0.1, 0.22, r.c1, "Wood")
			if brace then
				table.insert(leaf, brace)
			end
			table.insert(leaf, r:block(1.5, 1.7, 0.08, 1.72, 1.86, 0.2, C.DarkMetal, "Metal"))
			for _, p in leaf do
				r:door(p, hinge)
			end
		end,
	},
	{
		id = "flower_border",
		name = "Flower border",
		cat = "garden",
		price = 30,
		place = "ground",
		size = Vector3.new(4, 1.7, 1.4),
		c1 = "B4B4B8",
		c2 = "F59EB5",
		tags = { "plant" },
		build = function(r: R)
			-- a strip of dug earth behind a row of rounded edging stones (c1), full of leaves, with
			-- tall spikes at the back and flowers (c2) in front
			r:block(-2, 0, -0.7, 2, 0.16, 0.5, C.Soil, "Sand")
			r:piece(function(q: R)
				q:block(-1.95, 0, 0.5, 1.95, 0.06, 0.64, shade(r.c1, 0.8), "Slate")
				for i = 0, 8 do
					local x = -1.78 + i * 0.445
					q:lump(
						CFrame.new(x, 0.16, 0.57) * CFrame.Angles(0, (i % 3) * 0.3 - 0.3, (i % 2) * 0.1),
						0.46,
						0.34,
						0.24,
						if i % 2 == 0 then r.c1 else shade(r.c1, 1.08),
						"Slate"
					)
				end
			end)
			r:piece(function(q: R)
				leaves(q, -1.9, 1.9, -0.6, 0.4, 0.2, 6, 0.62)
			end)
			r:piece(function(q: R)
				spike(q, -1.3, -0.42, 0.25, 1.55, LILAC)
				spike(q, 0.2, -0.45, 0.25, 1.65, LILAC)
				spike(q, 1.35, -0.4, 0.25, 1.5, shade(LILAC, 1.1))
				bloom(q, -1.7, 0.1, 0.3, 0.95, r.c2, 0.4)
				bloom(q, -0.6, 0.0, 0.3, 1.1, C.White, 1.6)
				bloom(q, 0.75, 0.12, 0.3, 1.0, r.c2, 2.4)
				bloom(q, 1.65, 0.0, 0.3, 1.12, C.Yellow, 0.9)
			end)
		end,
	},
	{
		id = "veg_patch",
		name = "Vegetable patch",
		cat = "garden",
		price = 50,
		place = "ground",
		size = Vector3.new(4, 3.4, 4),
		c1 = "8E6440",
		c2 = "8E6440",
		tags = { "plant" },
		build = function(r: R)
			-- a square of dug earth inside four boards (c1): a row of cabbages, a row of carrot
			-- tops, two pumpkins and beans up a wigwam of canes
			for _, s in { -1, 1 } do
				r:block(-2, 0, s * 1.9 - 0.1, 2, 0.5, s * 1.9 + 0.1, r.c1, "Wood")
				r:block(s * 1.9 - 0.1, 0, -1.8, s * 1.9 + 0.1, 0.5, 1.8, r.c1, "Wood")
			end
			r:block(-1.8, 0, -1.8, 1.8, 0.36, 1.8, C.Soil, "Sand")
			r:piece(function(q: R)
				-- three ridges of earth
				for _, z in { -1.15, 0, 1.15 } do
					q:block(-1.7, 0.36, z - 0.32, 1.7, 0.5, z + 0.32, Color3.fromRGB(104, 76, 54), "Sand")
				end
			end)
			local cabbage = Color3.fromRGB(150, 196, 120)
			local pumpkin = Color3.fromRGB(222, 142, 78)
			r:piece(function(q: R)
				q:box(-1.3, 0.62, 1.15, 0.5, 0.3, 0.5, C.Leaf, "Grass")
				for i = 0, 3 do
					q:ball(-1.3 + i * 0.87, 0.72, 1.15, 0.7, if i % 2 == 0 then cabbage else C.Leaf, "Grass")
				end
				for i = 0, 5 do
					q:cone(-1.5 + i * 0.6, 0.8, 0, 0.7, 0.32, if i % 2 == 0 then C.Leaf else C.DarkLeaf, "Grass")
				end
				q:ball(-1.2, 0.72, -1.2, 0.8, pumpkin, "Grass")
				q:ball(-0.35, 0.66, -1.0, 0.62, pumpkin, "Grass")
				q:ball(-0.75, 0.6, -1.5, 0.5, C.Leaf, "Grass")
				-- the beans: leaves up the canes
				q:ball(1.05, 1.0, -1.15, 0.7, C.Leaf, "Grass")
				q:ball(1.1, 1.7, -1.1, 0.6, C.DarkLeaf, "Grass")
				q:ball(1.05, 2.35, -1.15, 0.45, C.Leaf, "Grass")
			end)
			local cane = Color3.fromRGB(196, 164, 110)
			r:piece(function(q: R)
				-- a name stake at the corner, then three canes tied at the top
				q:block(1.45, 0.36, 1.5, 1.55, 1.1, 1.56, cane, "Wood")
				q:block(1.25, 0.85, 1.57, 1.75, 1.15, 1.61, C.Paper, "Wood")
				for k = 0, 2 do
					local a = k * math.pi * 2 / 3 + 0.5
					q:beam(
						Vector3.new(1.05 + math.cos(a) * 0.6, 0.36, -1.15 + math.sin(a) * 0.6),
						Vector3.new(1.05, 3.3, -1.15),
						0.07,
						0.07,
						cane,
						"Wood"
					)
				end
			end)
		end,
	},
	{
		id = "tree_swing",
		name = "Tree with a swing",
		cat = "garden",
		price = 180,
		place = "ground",
		size = Vector3.new(10, 13, 9),
		c1 = "6EA460",
		c2 = "6E4C30",
		tags = { "plant", "seat" },
		build = function(r: R)
			-- an old tree with one long bough, and a plank on two ropes hung from it
			roots(r, 4, 1.4, 0.5, r.c2)
			r:cyl(0, 0.7, 0, 1.4, 1.7, "y", r.c2, "Wood")
			r:cyl(0, 3.6, 0, 5.2, 1.3, "y", r.c2, "Wood")
			rod(r, Vector3.new(0, 5.4, 0), Vector3.new(4.3, 6.6, 0.2), 0.6, r.c2, "Wood")
			rod(r, Vector3.new(0, 5.6, 0), Vector3.new(-1.9, 8.0, -0.6), 0.6, r.c2, "Wood")
			rod(r, Vector3.new(0, 5.8, 0), Vector3.new(0.4, 8.4, 1.5), 0.5, r.c2, "Wood")
			r:ball(0, 9.6, 0, 6.0, r.c1, "Grass")
			r:ball(-2.4, 8.3, 0.9, 4.2, shade(r.c1, 0.85), "Grass")
			r:ball(2.6, 8.6, -0.7, 4.6, shade(r.c1, 0.9), "Grass")
			r:ball(0.6, 8.1, 2.4, 4.0, shade(r.c1, 0.95), "Grass")
			r:ball(-0.9, 8.5, -2.4, 4.0, shade(r.c1, 0.8), "Grass")
			r:ball(2.0, 10.6, 1.1, 3.6, shade(r.c1, 1.08), "Grass")
			r:ball(-1.7, 10.9, -0.7, 3.6, shade(r.c1, 1.04), "Grass")
			r:ball(0.4, 11.7, -0.3, 3.2, shade(r.c1, 1.14), "Grass")
			r:piece(function(q: R)
				q:box(3.6, 1.95, 0.2, 0.7, 0.14, 1.9, Color3.fromRGB(196, 150, 96), "Wood")
				for _, z in { -0.55, 0.95 } do
					q:cyl(3.6, 4.2, z, 4.4, 0.09, "y", C.Cream, "Wood")
				end
			end)
			r:seat(3.6, 2.02, 0.2, 90)
		end,
	},
	{
		id = "water_butt",
		name = "Water butt",
		cat = "garden",
		price = 40,
		place = "ground",
		size = Vector3.new(2.2, 3.6, 2.4),
		c1 = "4E7F5A",
		c2 = "A65E42",
		build = function(r: R)
			-- a rain barrel (c1) on a stand of bricks (c2), with a lid and a tap at the front
			r:block(-0.8, 0, -0.8, 0.8, 0.5, 0.8, r.c2, "Brick")
			r:cyl(0, 1.9, 0, 2.8, 1.92, "y", r.c1, "SmoothPlastic")
			r:cyl(0, 3.36, 0, 0.14, 2.06, "y", shade(r.c1, 0.8), "SmoothPlastic")
			r:piece(function(q: R)
				q:box(0, 0.95, 1.08, 0.16, 0.16, 0.3, C.Gold, "Metal")
				q:box(0, 1.06, 1.18, 0.08, 0.2, 0.08, C.Gold, "Metal")
				q:cyl(0, 1.2, 0, 0.1, 1.98, "y", C.DarkMetal, "Metal")
				q:cyl(0, 2.7, 0, 0.1, 1.98, "y", C.DarkMetal, "Metal")
				q:block(-0.3, 3.43, -0.06, 0.3, 3.5, 0.06, C.DarkMetal, "Metal")
			end)
			-- a watering can left beside it
			r:piece(function(q: R)
				local can = Color3.fromRGB(63, 140, 134)
				q:box(0.82, 0.04, 1.0, 0.36, 0.08, 0.36, shade(can, 0.85), "Metal")
				q:cyl(0.82, 0.28, 1.0, 0.42, 0.4, "y", can, "Metal")
				q:beam(Vector3.new(0.72, 0.3, 1.0), Vector3.new(0.44, 0.62, 1.0), 0.07, 0.07, can, "Metal")
				q:cyl(0.42, 0.64, 1.0, 0.06, 0.12, "x", shade(can, 0.8), "Metal")
				q:beam(Vector3.new(0.96, 0.5, 1.0), Vector3.new(0.9, 0.62, 1.0), 0.05, 0.05, can, "Metal")
				q:beam(Vector3.new(0.9, 0.62, 1.0), Vector3.new(0.66, 0.62, 1.0), 0.05, 0.05, can, "Metal")
			end)
		end,
	},
	{
		id = "bird_house",
		name = "Bird house",
		cat = "garden",
		price = 30,
		place = "ground",
		size = Vector3.new(1.6, 7.4, 1.6),
		c1 = "F2E8D5",
		c2 = "B8505A",
		build = function(r: R)
			-- a nest box (c1) with a pitched roof (c2) up a pole, and somebody at home
			r:cyl(0, 2.6, 0, 5.2, 0.26, "y", C.Bark, "Wood")
			r:block(-0.62, 5.1, -0.55, 0.62, 5.22, 0.55, shade(r.c1, 0.8), "Wood")
			r:block(-0.5, 5.22, -0.45, 0.5, 6.2, 0.45, r.c1, "Wood")
			r:tri(Vector3.new(-0.5, 6.2, 0), Vector3.new(0.5, 6.2, 0), Vector3.new(0, 6.65, 0), 0.9, r.c1, "Wood")
			for _, sx in { -1, 1 } do
				r:beam(Vector3.new(sx * 0.72, 6.08, 0), Vector3.new(0, 6.82, 0), 1.2, 0.1, r.c2, "Wood")
			end
			r:piece(function(q: R)
				q:cyl(0, 5.78, 0.47, 0.04, 0.32, "z", C.Black, "SmoothPlastic")
				q:cyl(0, 5.5, 0.56, 0.24, 0.07, "z", C.Bark, "SmoothPlastic")
				-- a blue tit on the ridge
				q:ball(0.1, 7.02, 0.1, 0.34, C.Blue, "SmoothPlastic")
				q:ball(0.22, 7.2, 0.14, 0.22, C.Yellow, "SmoothPlastic")
				q:block(0.3, 7.17, 0.12, 0.42, 7.22, 0.16, C.Black, "SmoothPlastic")
				q:block(-0.2, 6.98, 0.07, -0.02, 7.03, 0.13, C.Blue, "SmoothPlastic")
			end)
		end,
	},
	{
		id = "flower_pot",
		name = "Flower pot",
		cat = "garden",
		price = 20,
		place = "surface",
		size = Vector3.new(1.4, 2.3, 1.4),
		c1 = "C0765A",
		c2 = "D9707F",
		tags = { "plant" },
		build = function(r: R)
			-- a clay pot (c1) with a rolled rim, leaves spilling over it and flowers (c2) standing up
			-- out of them at different heights, for a step, a porch or a windowsill
			r:cyl(0, 0.06, 0, 0.12, 0.78, "y", shade(r.c1, 0.85), "Sand")
			r:cyl(0, 0.46, 0, 0.68, 0.95, "y", r.c1, "Sand")
			r:cyl(0, 0.91, 0, 0.22, 1.2, "y", shade(r.c1, 1.08), "Sand")
			r:cyl(0, 1.05, 0, 0.06, 1.02, "y", C.Soil, "Sand")
			r:piece(function(q: R)
				q:box(0, 1.12, 0, 0.6, 0.1, 0.6, C.DarkLeaf, "Grass")
				q:lump(CFrame.new(0, 1.34, 0) * CFrame.Angles(0, 0.5, 0), 0.95, 0.45, 0.85, C.Leaf, "Grass")
				q:lump(CFrame.new(-0.32, 1.22, 0.28) * CFrame.Angles(0, 1.2, 0), 0.55, 0.36, 0.5, C.DarkLeaf, "Grass")
				q:lump(
					CFrame.new(0.36, 1.25, -0.22) * CFrame.Angles(0, 2.0, 0),
					0.55,
					0.36,
					0.5,
					shade(C.Leaf, 0.88),
					"Grass"
				)
				trail(q, 0.55, 1.05, 0.25, 0.4, 0.2)
				trail(q, -0.5, 1.05, -0.3, 0.32, -0.2)
				trail(q, -0.15, 1.05, 0.6, 0.36, 0.3)
			end)
			r:piece(function(q: R)
				bloom(q, 0.0, 0.0, 1.2, 2.12, r.c2, 0.3)
				bloom(q, -0.36, 0.28, 1.2, 1.78, r.c2, 1.4)
				bloom(q, 0.4, 0.18, 1.2, 1.86, C.White, 2.3)
				bloom(q, 0.12, -0.4, 1.2, 1.7, r.c2, 0.9)
				bloom(q, -0.3, -0.25, 1.2, 1.96, shade(r.c2, 1.1), 2.8)
			end)
		end,
	},
	{
		id = "trellis",
		name = "Rose trellis",
		cat = "garden",
		price = 40,
		place = "wall",
		size = Vector3.new(3, 8, 1),
		c1 = "F7F3EA",
		c2 = "D9707F",
		tags = { "plant" },
		build = function(r: R)
			-- a lattice against a wall (c1) with a rose climbing it (c2 the flowers)
			for _, x in { -1.1, 1.1 } do
				r:block(x - 0.07, 0, 0.06, x + 0.07, 7.9, 0.16, r.c1, "Wood")
			end
			for _, y in { 0.9, 3.2, 5.5, 7.7 } do
				r:block(-1.4, y - 0.07, 0.02, 1.4, y + 0.07, 0.1, r.c1, "Wood")
			end
			r:piece(function(q: R)
				-- the stem in three runs, then leaves where it turns
				q:block(-0.1, 0, 0.16, 0.1, 2.4, 0.34, C.Bark, "Grass")
				q:beam(Vector3.new(0, 2.3, 0.25), Vector3.new(-0.8, 4.6, 0.25), 0.14, 0.14, C.Bark, "Grass")
				q:beam(Vector3.new(-0.8, 4.5, 0.25), Vector3.new(0.6, 7.2, 0.25), 0.12, 0.12, C.Bark, "Grass")
				for i, p in
					{
						{ 0.25, 1.2, 0.7 },
						{ -0.35, 2.3, 0.85 },
						{ 0.7, 3.0, 0.75 },
						{ -0.9, 3.7, 0.9 },
						{ -0.2, 4.6, 0.8 },
						{ -1.0, 5.4, 0.7 },
						{ 0.5, 5.6, 0.85 },
						{ -0.3, 6.5, 0.75 },
						{ 0.8, 6.9, 0.9 },
						{ 0.1, 7.4, 0.7 },
					}
				do
					q:ball(p[1], p[2], 0.5, p[3], if i % 2 == 0 then C.DarkLeaf else C.Leaf, "Grass")
				end
			end)
			for _, p in { { 0.5, 1.6 }, { -0.7, 3.1 }, { 0.3, 4.2 }, { -0.6, 5.9 }, { 0.9, 6.3 }, { 0.2, 7.6 } } do
				r:noCollide(r:ball(p[1], p[2], 0.82, 0.36, r.c2, "SmoothPlastic"))
			end
		end,
	},
}

return items
