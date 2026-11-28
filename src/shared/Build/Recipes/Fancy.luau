--!strict
-- Fancy: an elegant townhouse look (the user: "there should be many to choose from from different
-- categories, like garden, sci fi, cozy, etc, just like bloxburg"). Velvet, marble, walnut and a
-- little gold, in soft colours, across every tab. Each piece names `style = "fancy"` so Build mode
-- can list the look together. c1 is the main colour and c2 the second, as in the other modules.

local Recipe = require(script.Parent.Parent.Recipe)
local Colors = require(script.Parent.Parent.Parent.Util.Colors)

local C = Recipe.Colors

type R = Recipe.Recipe

local GOLD = C.Gold
local WALNUT = Color3.fromRGB(107, 74, 54)
local IVORY = Color3.fromRGB(244, 238, 226)
local SHEET = Color3.fromRGB(250, 248, 243)
local MIRROR = Color3.fromRGB(214, 228, 234)
local LEAF = C.Leaf
local DARKLEAF = C.DarkLeaf

local function shade(c: Color3, k: number): Color3
	return Colors.shade(c, k)
end

local function mix(a: Color3, b: Color3, t: number): Color3
	return Colors.mix(a, b, t)
end

-- Glows at night without a light of its own (when another part of the item already has one).
local function glowOnly(p: Recipe.Prim)
	p.role = "glow"
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
		mat = mat or "Metal",
	})
end

-- Rods through a list of points, each run a little past its inner ends so the joints close up.
local function path(r: R, pts: { Vector3 }, d: number, color: Color3, mat: string?)
	for i = 1, #pts - 1 do
		local a, b = pts[i], pts[i + 1]
		local u = (b - a).Unit * (d * 0.45)
		rod(r, if i > 1 then a - u else a, if i < #pts - 1 then b + u else b, d, color, mat)
	end
end

-- A flat bar lying in the wall's plane from p1 to p2 (both at the same z, its middle): `t`
-- across in the plane and `depth` out of it. For frames round mirrors and pictures.
local function bar(r: R, p1: Vector3, p2: Vector3, t: number, depth: number, color: Color3, mat: string?)
	local v = p2 - p1
	local len = v.Magnitude
	if len < 1e-3 then
		return
	end
	local x = v / len
	local y = Vector3.zAxis:Cross(x)
	r:boxAt(CFrame.fromMatrix((p1 + p2) / 2, x, y, Vector3.zAxis), len, t, depth, color, mat)
end

-- A filled polygon as a fan of triangles from a middle point (each `thick` through).
local function fan(r: R, mid: Vector3, pts: { Vector3 }, thick: number, color: Color3, mat: string?, closed: boolean?)
	local n = #pts
	for i = 1, if closed then n else n - 1 do
		r:tri(mid, pts[i], pts[i % n + 1], thick, color, mat)
	end
end

-- A turned leg: a brass cup at the floor, a column with a bulb, and a collar up top.
local function turned(r: R, x: number, z: number, top: number, d: number, color: Color3)
	r:cyl(x, 0.05, z, 0.1, d * 1.15, "y", GOLD, "Metal")
	r:cyl(x, (0.1 + top) / 2, z, top - 0.1, d, "y", color, "Wood")
	r:ball(x, 0.1 + (top - 0.1) * 0.42, z, d * 1.5, color, "Wood")
	r:cyl(x, top - 0.07, z, 0.14, d * 1.4, "y", color, "Wood")
end

-- A cabriole leg: out at the knee, in at the ankle, on a small pad foot. (x, z) is where it meets
-- the frame at `top`; sx and sz point the knee outward.
local function cabriole(r: R, x: number, z: number, top: number, sx: number, sz: number, d: number, color: Color3)
	local t = Vector3.new(x, top, z)
	local k = Vector3.new(x + sx * 0.09, top * 0.62, z + sz * 0.09)
	local a = Vector3.new(x - sx * 0.02, top * 0.22, z - sz * 0.02)
	local f = Vector3.new(x + sx * 0.06, 0.07, z + sz * 0.06)
	rod(r, t, k + (k - t).Unit * 0.05, d * 1.3, color, "Wood")
	rod(r, k, a + (a - k).Unit * 0.04, d, color, "Wood")
	rod(r, a, f, d * 0.8, color, "Wood")
	r:lump(CFrame.new(f.X, 0.065, f.Z), d * 1.5, 0.13, d * 1.5, color, "Wood")
end

-- A cushion from (x1, y1, z1) to (x2, y2, z2) with its front and back edges rounded over.
local function cushion(r: R, x1: number, y1: number, z1: number, x2: number, y2: number, z2: number, color: Color3)
	local h = y2 - y1
	local xm, ym = (x1 + x2) / 2, (y1 + y2) / 2
	r:block(x1, y1, z1 + h / 2, x2, y2, z2 - h / 2, color, "Fabric")
	r:cyl(xm, ym, z1 + h / 2, x2 - x1, h, "x", color, "Fabric")
	r:cyl(xm, ym, z2 - h / 2, x2 - x1, h, "x", color, "Fabric")
end

-- A button pulled into padding.
local function button(r: R, x: number, y: number, z: number, color: Color3)
	r:ball(x, y, z, 0.11, shade(color, 0.72), "Fabric")
end

-- A row of brass nail heads along x, as one piece.
local function nails(r: R, x1: number, x2: number, y: number, z: number, n: number)
	r:piece(function(q: R)
		for i = 0, n - 1 do
			local x = x1 + (x2 - x1) * i / (n - 1)
			q:box(x, y, z, 0.08, 0.08, 0.06, GOLD, "Metal")
		end
	end)
end

-- A soft pillow `w` wide whose bottom is at y and whose middle is at z, leaning back a little.
local function pillow(r: R, x: number, y: number, z: number, w: number, color: Color3?)
	local col = color or SHEET
	local cf = CFrame.new(x, y + 0.22, z) * CFrame.Angles(-0.18, 0, 0)
	r:boxAt(cf, w, 0.44, 0.62, col, "Fabric")
	for _, s in { -1, 1 } do
		r:add({
			shape = "Cylinder",
			cf = cf * CFrame.new(0, 0, s * 0.31),
			size = Vector3.new(w, 0.44, 0.44),
			color = col,
			mat = "Fabric",
		})
	end
end

-- A mattress from y0 to y1 with a piped edge, and a duvet from zb that hangs over the sides and
-- the foot, its top folded back over the sheet.
local function mattress(
	r: R,
	x1: number,
	x2: number,
	z1: number,
	z2: number,
	y0: number,
	y1: number,
	zb: number,
	blanket: Color3
)
	r:block(x1, y0, z1, x2, y1, z2, SHEET, "Fabric")
	r:block(x1 - 0.03, y1 - 0.1, z1 - 0.03, x2 + 0.03, y1 - 0.05, z2 + 0.03, shade(SHEET, 0.86), "Fabric")
	local fold = mix(blanket, C.White, 0.3)
	r:block(x1 - 0.08, y1 - 0.5, zb + 0.3, x2 + 0.08, y1 + 0.12, z2 + 0.08, blanket, "Fabric")
	r:block(x1 - 0.12, y1 - 0.46, zb, x2 + 0.12, y1 + 0.2, zb + 0.4, fold, "Fabric")
	r:cyl((x1 + x2) / 2, y1 + 0.05, zb, x2 - x1 + 0.24, 0.3, "x", fold, "Fabric")
end

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
	gives: string?, -- holding E gives the player something (Data/Items.Sources)
}

local items: { Item } = {
	------------------------------------------------------------------------------------------
	-- Seating
	{
		id = "fancy_chaise",
		name = "Chaise longue",
		cat = "seating",
		style = "fancy",
		price = 260,
		place = "floor",
		size = Vector3.new(6.4, 3.3, 2.6),
		c1 = "B98A93",
		c2 = "5E4232",
		tags = { "seat" },
		build = function(r: R)
			local frame = shade(r.c1, 0.86)
			-- six turned legs under a show wood rail with a gold bead along its front
			for _, x in { -2.8, 0.2, 2.8 } do
				for _, z in { -0.92, 0.92 } do
					turned(r, x, z, 0.62, 0.22, r.c2)
				end
			end
			r:block(-3.0, 0.62, -1.15, 3.0, 0.86, 1.15, r.c2, "Wood")
			r:block(-3.0, 0.7, 1.15, 3.0, 0.77, 1.19, GOLD, "Metal")
			-- the padded seat with a rounded front
			cushion(r, -2.65, 0.86, -1.08, 2.95, 1.42, 1.1, r.c1)
			-- the high scrolled end, its scroll faces with a gold rosette in each
			r:block(-3.15, 0.86, -1.1, -2.65, 2.35, 1.1, r.c1, "Fabric")
			r:cyl(-2.95, 2.4, 0, 2.2, 0.85, "z", r.c1, "Fabric")
			for _, s in { -1, 1 } do
				r:cyl(-2.95, 2.4, s * 1.12, 0.04, 0.62, "z", frame, "Fabric")
				r:cyl(-2.95, 2.4, s * 1.155, 0.05, 0.24, "z", GOLD, "Metal")
			end
			-- a back that runs down from the scroll toward the foot, rolled along its top
			r:block(-2.65, 1.42, -1.1, 0.9, 1.76, -0.66, r.c1, "Fabric")
			r:tri(
				Vector3.new(-2.65, 1.75, -0.88),
				Vector3.new(0.9, 1.75, -0.88),
				Vector3.new(-2.65, 2.85, -0.88),
				0.44,
				r.c1,
				"Fabric"
			)
			rod(r, Vector3.new(-2.68, 2.86, -0.88), Vector3.new(0.98, 1.72, -0.88), 0.52, frame, "Fabric")
			-- buttons pulled into the back and the seat
			for _, p in { { -2.2, 1.6 }, { -1.2, 1.6 }, { -0.2, 1.6 }, { -1.7, 2.12 } } do
				button(r, p[1], p[2], -0.66, r.c1)
			end
			for i, x in { -1.8, -0.6, 0.6, 1.8 } do
				button(r, x, 1.42, if i % 2 == 0 then 0.45 else -0.15, r.c1)
			end
			-- a bolster with gold ends against the scroll
			r:cyl(-2.33, 1.72, 0.15, 1.56, 0.6, "z", IVORY, "Fabric")
			for _, z in { -0.65, 0.95 } do
				r:cyl(-2.33, 1.72, z, 0.06, 0.32, "z", GOLD, "Metal")
			end
			r:seat(-1.2, 1.42, 0.2)
			r:seat(1.6, 1.42, 0.2)
		end,
	},
	{
		id = "fancy_sofa_camel",
		name = "Camelback sofa",
		cat = "seating",
		style = "fancy",
		price = 340,
		place = "floor",
		size = Vector3.new(7.2, 3.8, 3.0),
		c1 = "5F8A86",
		c2 = "5E4232",
		tags = { "seat" },
		build = function(r: R)
			local frame = shade(r.c1, 0.88)
			-- carved front legs, plain splayed back legs
			for _, x in { -3.1, 0, 3.1 } do
				local sx = if x < 0 then -1 elseif x > 0 then 1 else 0
				cabriole(r, x, 1.1, 0.62, sx, 1, 0.2, r.c2)
			end
			for _, sx in { -1, 1 } do
				rod(r, Vector3.new(sx * 3.1, 0.64, -1.1), Vector3.new(sx * 3.22, 0, -1.26), 0.2, r.c2, "Wood")
			end
			-- the frame, a show wood apron with a carved shell in the middle
			r:block(-2.8, 0.62, -1.4, 2.8, 1.25, 1.15, frame, "Fabric")
			r:block(-3.45, 0.55, 1.15, 3.45, 0.82, 1.3, r.c2, "Wood")
			r:lump(CFrame.new(0, 0.7, 1.32), 0.62, 0.34, 0.14, r.c2, "Wood")
			-- one long seat cushion
			cushion(r, -2.78, 1.25, -0.9, 2.78, 1.85, 1.15, r.c1)
			-- the back rises to a hump in the middle, rolled along its top
			r:block(-2.95, 1.25, -1.4, 2.95, 2.62, -0.85, r.c1, "Fabric")
			local tops: { Vector3 } = {}
			for i = 0, 6 do
				local x = -2.95 + i * 5.9 / 6
				local y = 2.7 + 0.85 * (1 - (x / 3.1) ^ 2) ^ 1.5
				table.insert(tops, Vector3.new(x, y, -1.12))
			end
			for i = 1, 6 do
				local a, b = tops[i], tops[i + 1]
				r:quad(Vector3.new(a.X, 2.6, -1.12), Vector3.new(b.X, 2.6, -1.12), b, a, 0.55, r.c1, "Fabric")
			end
			path(r, tops, 0.4, frame, "Fabric")
			-- buttons in rows across the back
			local rows: { { y: number, xs: { number } } } = {
				{ y = 1.95, xs = { -2.4, -1.2, 0, 1.2, 2.4 } },
				{ y = 2.5, xs = { -1.8, -0.6, 0.6, 1.8 } },
				{ y = 3.0, xs = { -0.6, 0.6 } },
			}
			for _, row in rows do
				for _, x in row.xs do
					button(r, x, row.y, -0.85, r.c1)
				end
			end
			-- rolled arms with a scroll face and a gold rosette at the front
			for _, sx in { -1, 1 } do
				local xo, xi = sx * 3.55, sx * 2.8
				local xm = sx * 3.175
				r:block(math.min(xo, xi), 0.62, -1.4, math.max(xo, xi), 2.15, 1.15, r.c1, "Fabric")
				r:cyl(xm, 2.17, -0.12, 2.55, 0.82, "z", r.c1, "Fabric")
				r:block(xm - 0.32, 0.72, 1.15, xm + 0.32, 2.1, 1.19, frame, "Fabric")
				r:cyl(xm, 2.17, 1.17, 0.04, 0.66, "z", frame, "Fabric")
				r:cyl(xm, 2.17, 1.21, 0.05, 0.24, "z", GOLD, "Metal")
				-- a round bolster against each arm
				r:cyl(sx * 2.48, 2.15, 0.05, 1.3, 0.6, "z", IVORY, "Fabric")
				for _, z in { -0.6, 0.7 } do
					r:cyl(sx * 2.48, 2.15, z, 0.06, 0.32, "z", GOLD, "Metal")
				end
			end
			-- a square cushion in the middle with a piped edge
			local pc = CFrame.new(0, 2.4, -0.6) * CFrame.Angles(-0.22, 0, 0)
			r:lump(pc, 1.2, 1.1, 0.42, mix(r.c1, IVORY, 0.55), "Fabric")
			local pb = (pc * CFrame.new(0, 0, 0.2)).Position
			button(r, pb.X, pb.Y, pb.Z, mix(r.c1, IVORY, 0.55))
			for _, x in { -2.0, 0, 2.0 } do
				r:seat(x, 1.85, 0.25)
			end
		end,
	},
	{
		id = "fancy_chair_wing",
		name = "Wingback chair",
		cat = "seating",
		style = "fancy",
		price = 190,
		place = "floor",
		size = Vector3.new(3.2, 4.7, 3.2),
		c1 = "9DB39B",
		c2 = "5E4232",
		tags = { "seat" },
		build = function(r: R)
			local frame = shade(r.c1, 0.9)
			for _, sx in { -1, 1 } do
				cabriole(r, sx * 1.28, 1.15, 0.62, sx, 1, 0.2, r.c2)
				rod(r, Vector3.new(sx * 1.28, 0.64, -1.2), Vector3.new(sx * 1.4, 0, -1.4), 0.2, r.c2, "Wood")
			end
			-- the base with brass nails along its front, and the seat cushion
			r:block(-1.5, 0.62, -1.45, 1.5, 1.25, 1.3, frame, "Fabric")
			nails(r, -1.38, 1.38, 1.12, 1.33, 12)
			cushion(r, -0.98, 1.25, -0.95, 0.98, 1.75, 1.3, r.c1)
			-- the back leans a little and is arched over the top
			local back = CFrame.new(0, 1.25, -1.2) * CFrame.Angles(-0.1, 0, 0)
			r:boxAt(back * CFrame.new(0, 1.35, 0), 2.2, 2.7, 0.5, r.c1, "Fabric")
			local arch: { Vector3 } = {}
			for i = 0, 8 do
				local a = i * math.pi / 8
				table.insert(arch, back:PointToWorldSpace(Vector3.new(-math.cos(a) * 1.1, 2.7 + math.sin(a) * 0.66, 0)))
			end
			fan(r, back:PointToWorldSpace(Vector3.new(0, 2.69, 0)), arch, 0.5, r.c1, "Fabric")
			path(r, arch, 0.3, frame, "Fabric")
			for _, p in { { -0.55, 1.2 }, { 0.55, 1.2 }, { 0, 1.9 }, { -0.55, 2.55 }, { 0.55, 2.55 } } do
				local b = back:PointToWorldSpace(Vector3.new(p[1], p[2], 0.25))
				button(r, b.X, b.Y, b.Z, r.c1)
			end
			-- wings each side, rolled along their front edge, over rolled arms
			for _, sx in { -1, 1 } do
				local x = sx * 1.25
				local w1, w2 = Vector3.new(x, 2.2, -0.15), Vector3.new(x, 3.55, -0.28)
				r:quad(Vector3.new(x, 1.75, -1.35), w1, w2, Vector3.new(x, 3.95, -1.45), 0.3, r.c1, "Fabric")
				path(r, { Vector3.new(x, 2.15, -0.12), w2, Vector3.new(x, 3.96, -1.46) }, 0.38, frame, "Fabric")
				local xo, xi = sx * 1.56, sx * 1.0
				r:block(math.min(xo, xi), 1.25, -1.0, math.max(xo, xi), 2.3, 1.3, r.c1, "Fabric")
				r:cyl(sx * 1.28, 2.3, 0.15, 2.3, 0.62, "z", r.c1, "Fabric")
				r:block(sx * 1.28 - 0.3, 1.3, 1.3, sx * 1.28 + 0.3, 2.25, 1.34, frame, "Fabric")
				r:cyl(sx * 1.28, 2.3, 1.32, 0.04, 0.66, "z", frame, "Fabric")
			end
			r:seat(0, 1.75, 0.25)
		end,
	},
	{
		id = "fancy_ottoman",
		name = "Tufted ottoman",
		cat = "seating",
		style = "fancy",
		price = 90,
		place = "floor",
		size = Vector3.new(2.8, 1.9, 2.8),
		c1 = "C98E96",
		c2 = "D4B26A",
		tags = { "seat" },
		build = function(r: R)
			-- four short gold legs with feet, under a padded drum
			for i = 0, 3 do
				local a = i * math.pi / 2 + math.pi / 4
				local x, z = math.cos(a) * 0.92, math.sin(a) * 0.92
				rod(r, Vector3.new(x, 0.47, z), Vector3.new(x * 1.1, 0.06, z * 1.1), 0.16, r.c2, "Metal")
				r:cyl(x * 1.1, 0.04, z * 1.1, 0.08, 0.22, "y", shade(r.c2, 0.8), "Metal")
			end
			r:cyl(0, 0.95, 0, 0.9, 2.6, "y", r.c1, "Fabric")
			r:cyl(0, 0.49, 0, 0.1, 2.68, "y", r.c2, "Metal")
			r:cyl(0, 1.39, 0, 0.08, 2.68, "y", shade(r.c1, 0.8), "Fabric")
			-- pleats down the side
			r:piece(function(q: R)
				q:box(1.32, 0.92, 0, 0.05, 0.8, 0.08, shade(r.c1, 0.82), "Fabric")
				for i = 1, 7 do
					local a = i * math.pi / 4
					q:boxAt(
						CFrame.new(math.cos(a) * 1.32, 0.92, math.sin(a) * 1.32) * CFrame.Angles(0, -a, 0),
						0.05,
						0.8,
						0.08,
						shade(r.c1, 0.82),
						"Fabric"
					)
				end
			end)
			-- a domed, buttoned top
			r:lump(CFrame.new(0, 1.45, 0), 2.56, 0.75, 2.56, r.c1, "Fabric")
			button(r, 0, 1.82, 0, r.c1)
			for i = 0, 5 do
				local a = i * math.pi / 3
				button(r, math.cos(a) * 0.68, 1.75, math.sin(a) * 0.68, r.c1)
			end
			r:seat(0, 1.82, 0)
		end,
	},

	------------------------------------------------------------------------------------------
	-- Tables
	{
		id = "fancy_table_marble",
		name = "Marble side table",
		cat = "tables",
		style = "fancy",
		price = 110,
		place = "floor",
		size = Vector3.new(2.2, 2.6, 2.2),
		c1 = "ECE6DE",
		c2 = "C9A55E",
		tags = { "table" },
		surface = 2.56,
		build = function(r: R)
			-- a round marble top on a gold band and apron, hung with beads
			r:cyl(0, 2.48, 0, 0.16, 2.1, "y", r.c1, "Marble")
			r:cyl(0, 2.36, 0, 0.08, 1.86, "y", r.c2, "Metal")
			r:cyl(0, 2.2, 0, 0.24, 1.3, "y", r.c2, "Metal")
			for i = 0, 7 do
				local a = i * math.pi / 4 + math.pi / 8
				r:ball(math.cos(a) * 0.62, 2.05, math.sin(a) * 0.62, 0.12, r.c2, "Metal")
			end
			-- a stem with a knop, and a finial below the under tier
			r:cyl(0, 1.3, 0, 1.56, 0.2, "y", r.c2, "Metal")
			r:ball(0, 1.4, 0, 0.36, r.c2, "Metal")
			r:add({
				shape = "Cone",
				cf = CFrame.new(0, 0.42, 0) * CFrame.Angles(math.pi, 0, 0),
				size = Vector3.new(0.2, 0.24, 0.2),
				color = r.c2,
				mat = "Metal",
			})
			r:cyl(0, 0.62, 0, 0.08, 1.12, "y", r.c1, "Marble")
			-- three S shaped legs on ball feet
			for i = 0, 2 do
				local a = i * math.pi * 2 / 3 + math.pi / 2
				local dx, dz = math.cos(a), math.sin(a)
				local pts: { Vector3 } = {}
				for _, p in { { 0.12, 2.0 }, { 0.6, 1.55 }, { 0.68, 1.1 }, { 0.5, 0.62 }, { 0.72, 0.2 } } do
					table.insert(pts, Vector3.new(dx * p[1], p[2], dz * p[1]))
				end
				path(r, pts, 0.12, r.c2, "Metal")
				r:ball(dx * 0.78, 0.1, dz * 0.78, 0.2, r.c2, "Metal")
			end
		end,
	},
	{
		id = "fancy_bureau",
		name = "Writing bureau",
		cat = "tables",
		style = "fancy",
		price = 260,
		place = "floor",
		size = Vector3.new(3.6, 4.3, 2.4),
		c1 = "7A5640",
		c2 = "5F7F6A",
		tags = { "desk" },
		build = function(r: R)
			local dk = shade(r.c1, 0.82)
			local front = shade(r.c1, 1.06)
			for _, sx in { -1, 1 } do
				cabriole(r, sx * 1.58, 0.48, 0.62, sx, 1, 0.2, r.c1)
				cabriole(r, sx * 1.58, -0.85, 0.62, sx, -1, 0.2, r.c1)
			end
			-- the drawer case: three drawers with brass handles and keyholes
			r:block(-1.75, 0.62, -1.0, 1.75, 2.55, 0.65, r.c1, "Wood")
			for _, d in { { 0.72, 1.32 }, { 1.4, 1.92 }, { 2.0, 2.24 } } do
				r:block(-1.62, d[1], 0.65, 1.62, d[2], 0.69, front, "Wood")
			end
			r:piece(function(q: R)
				for _, y in { 1.02, 1.66, 2.12 } do
					for _, x in { -0.85, 0.85 } do
						q:box(x, y, 0.72, 0.4, 0.07, 0.05, GOLD, "Metal")
					end
					q:box(0, y, 0.71, 0.08, 0.14, 0.03, GOLD, "Metal")
				end
			end)
			-- two lopers pulled out to hold the flap
			for _, sx in { -1, 1 } do
				r:block(sx * 1.3, 2.28, -0.2, sx * 1.6, 2.55, 1.1, r.c1, "Wood")
				r:cyl(sx * 1.45, 2.43, 1.13, 0.06, 0.12, "z", GOLD, "Metal")
			end
			r:block(-1.8, 2.5, -1.04, 1.8, 2.58, 0.72, dk, "Wood")
			-- the slanted top section: sides, back, a flat top
			for _, sx in { -1, 1 } do
				local x = sx * 1.7
				r:quad(
					Vector3.new(x, 2.58, -1.0),
					Vector3.new(x, 2.58, 0.0),
					Vector3.new(x, 3.6, -0.6),
					Vector3.new(x, 3.6, -1.0),
					0.1,
					r.c1,
					"Wood"
				)
				r:block(x - 0.05, 3.6, -1.0, x + 0.05, 4.1, -0.6, r.c1, "Wood")
			end
			r:block(-1.65, 2.58, -1.0, 1.65, 4.1, -0.9, dk, "Wood")
			r:block(-1.8, 4.1, -1.06, 1.8, 4.22, -0.54, r.c1, "Wood")
			-- inside: small drawers below, pigeonholes above with letters in some
			r:block(-1.65, 2.58, -0.9, 1.65, 3.3, -0.42, dk, "Wood")
			r:piece(function(q: R)
				q:block(-1.6, 2.68, -0.42, -0.9, 3.2, -0.38, front, "Wood")
				q:block(0.9, 2.68, -0.42, 1.6, 3.2, -0.38, front, "Wood")
				q:block(-0.8, 2.68, -0.42, 0.8, 3.2, -0.38, shade(r.c1, 0.95), "Wood")
			end)
			for _, x in { -1.25, 0, 1.25 } do
				r:ball(x, 2.94, -0.36, 0.08, GOLD, "Metal")
			end
			r:piece(function(q: R)
				q:block(-1.65, 3.3, -0.9, 1.65, 3.36, -0.5, r.c1, "Wood")
				for _, x in { -1.1, -0.55, 0, 0.55, 1.1 } do
					q:block(x - 0.03, 3.36, -0.9, x + 0.03, 4.1, -0.62, r.c1, "Wood")
				end
			end)
			for _, x in { -0.82, 0.27, 1.37 } do
				r:block(x - 0.03, 3.36, -0.85, x + 0.03, 3.74, -0.66, C.Paper, "Cardboard")
			end
			-- the writing flap, let down, with a leather top
			r:block(-1.62, 2.58, 0.0, 1.62, 2.68, 1.15, r.c1, "Wood")
			r:block(-1.38, 2.68, 0.15, 1.38, 2.71, 1.0, r.c2, "Leather")
			-- an inkwell and a quill, and a letter half written
			r:cyl(0.95, 2.78, 0.35, 0.14, 0.22, "y", C.Black, "Glass")
			r:cyl(0.95, 2.86, 0.35, 0.04, 0.14, "y", GOLD, "Metal")
			local quill = CFrame.new(1.05, 3.05, 0.32) * CFrame.Angles(0.15, 0, -0.35)
			r:boxAt(quill, 0.12, 0.5, 0.03, C.White, "Cardboard")
			rod(r, (quill * CFrame.new(0, -0.25, 0)).Position, Vector3.new(0.95, 2.86, 0.35), 0.025, C.Black)
			r:boxAt(
				CFrame.new(-0.2, 2.725, 0.55) * CFrame.Angles(0, 0.12, 0),
				0.8,
				0.03,
				0.58,
				C.Paper,
				"Cardboard"
			)
			r:boxAt(
				CFrame.new(-0.25, 2.75, 0.5) * CFrame.Angles(0, 0.12, 0),
				0.5,
				0.02,
				0.04,
				Color3.fromRGB(70, 74, 96),
				"Glass"
			)
		end,
	},
	{
		id = "fancy_tea_set",
		name = "Tea table",
		gives = "tea", -- holding E gives something (Data/Items.Sources)
		cat = "tables",
		style = "fancy",
		price = 150,
		place = "floor",
		size = Vector3.new(3.2, 3.4, 3.2),
		c1 = "F2EAE0",
		c2 = "9FB4C9",
		tags = { "table" },
		build = function(r: R)
			-- a walnut pedestal on three feet, under a long round cloth with a scalloped hem
			r:cyl(0, 1.0, 0, 1.6, 0.3, "y", WALNUT, "Wood")
			for i = 0, 2 do
				local a = i * math.pi * 2 / 3 + math.pi / 2
				local dx, dz = math.cos(a), math.sin(a)
				r:beam(Vector3.new(0, 0.3, 0), Vector3.new(dx * 0.95, 0.12, dz * 0.95), 0.18, 0.2, WALNUT, "Wood")
				r:ball(dx * 0.98, 0.1, dz * 0.98, 0.2, WALNUT, "Wood")
			end
			r:cyl(0, 2.02, 0, 0.86, 2.84, "y", r.c1, "Fabric")
			r:cyl(0, 2.29, 0, 0.08, 2.92, "y", shade(r.c1, 0.9), "Fabric")
			r:piece(function(q: R)
				q:box(1.43, 1.56, 0, 0.06, 0.12, 0.3, shade(r.c1, 0.95), "Fabric")
				for i = 1, 15 do
					local a = i * math.pi / 8
					q:boxAt(
						CFrame.new(math.cos(a) * 1.43, 1.56, math.sin(a) * 1.43) * CFrame.Angles(0, -a, 0),
						0.06,
						0.12,
						0.3,
						shade(r.c1, 0.95),
						"Fabric"
					)
				end
			end)
			local top = 2.45
			-- a round teapot with a spout, a handle and a lid
			local tx, tz = 0.45, -0.35
			r:cyl(tx, top + 0.03, tz, 0.06, 0.42, "y", shade(r.c2, 0.85), "Marble")
			r:lump(CFrame.new(tx, top + 0.33, tz), 0.72, 0.56, 0.72, r.c2, "Marble")
			r:cyl(tx, top + 0.62, tz, 0.06, 0.4, "y", IVORY, "Marble")
			r:ball(tx, top + 0.7, tz, 0.13, GOLD, "Metal")
			rod(r, Vector3.new(tx + 0.25, top + 0.28, tz), Vector3.new(tx + 0.5, top + 0.55, tz), 0.09, r.c2)
			path(r, {
				Vector3.new(tx - 0.3, top + 0.48, tz),
				Vector3.new(tx - 0.5, top + 0.4, tz),
				Vector3.new(tx - 0.3, top + 0.2, tz),
			}, 0.06, r.c2)
			-- two cups of tea on saucers
			for _, p in { { -0.6, 0.55 }, { 0.5, 0.72 } } do
				r:cyl(p[1], top + 0.02, p[2], 0.04, 0.44, "y", IVORY, "Marble")
				r:cyl(p[1], top + 0.14, p[2], 0.2, 0.26, "y", r.c2, "Marble")
				r:cyl(p[1], top + 0.245, p[2], 0.05, 0.2, "y", Color3.fromRGB(150, 96, 62), "Glass")
				r:block(
					p[1] + 0.13,
					top + 0.08,
					p[2] - 0.02,
					p[1] + 0.2,
					top + 0.18,
					p[2] + 0.02,
					r.c2,
					"Marble"
				)
			end
			-- a stand of three plates with little cakes
			local sx, sz = -0.55, -0.45
			r:cyl(sx, top + 0.6, sz, 1.2, 0.05, "y", GOLD, "Metal")
			r:ball(sx, top + 1.24, sz, 0.12, GOLD, "Metal")
			local cakes =
				{ Color3.fromRGB(244, 184, 200), Color3.fromRGB(246, 224, 160), Color3.fromRGB(196, 222, 200) }
			for i, t in { { 0.12, 0.9, 4 }, { 0.5, 0.7, 3 }, { 0.86, 0.5, 2 } } do
				local y = top + t[1]
				r:cyl(sx, y, sz, 0.04, t[2], "y", IVORY, "Marble")
				local n = t[3]
				for k = 0, n - 1 do
					local a = k * math.pi * 2 / n + i
					local rr = if n == 2 then 0.13 else t[2] * 0.3
					local cx, cz = sx + math.cos(a) * rr, sz + math.sin(a) * rr
					r:cyl(cx, y + 0.08, cz, 0.12, 0.15, "y", cakes[(k + i) % 3 + 1], "Sand")
					if k == 0 then
						r:ball(cx, y + 0.17, cz, 0.07, C.Red, "Marble")
					end
				end
			end
			-- a bud vase with one rose
			r:cyl(0.0, top + 0.16, 0.05, 0.32, 0.12, "y", MIRROR, "Glass")
			rod(r, Vector3.new(0, top + 0.3, 0.05), Vector3.new(0.02, top + 0.55, 0.06), 0.025, DARKLEAF)
			r:ball(0.02, top + 0.58, 0.06, 0.13, Color3.fromRGB(214, 120, 140), "Plaster")
		end,
	},

	------------------------------------------------------------------------------------------
	-- Beds
	{
		id = "fancy_bed_sleigh",
		name = "Sleigh bed",
		cat = "beds",
		style = "fancy",
		price = 560,
		place = "floor",
		size = Vector3.new(6.2, 4.8, 8.6),
		c1 = "8A6248",
		c2 = "B7A3C2",
		tags = { "bed" },
		build = function(r: R)
			local dk = shade(r.c1, 0.84)
			-- bun feet, side rails with a raised panel, a base under the mattress
			for _, sx in { -1, 1 } do
				for _, sz in { -1, 1 } do
					r:cyl(sx * 2.92, 0.22, sz * 3.65, 0.44, 0.44, "y", dk, "Wood")
					r:ball(sx * 2.92, 0.3, sz * 3.65, 0.5, dk, "Wood")
				end
				r:block(sx * 2.85, 0.45, -3.75, sx * 3.05, 1.55, 3.75, r.c1, "Wood")
				local xo = sx * 3.05 + sx * 0.02
				r:block(math.min(xo, sx * 3.05), 0.62, -3.1, math.max(xo, sx * 3.05) + 0.02 * sx, 1.38, 3.1, dk, "Wood")
			end
			r:block(-2.85, 0.9, -3.7, 2.85, 1.2, 3.7, dk, "Wood")
			mattress(r, -2.75, 2.75, -3.6, 3.5, 1.2, 1.95, -1.0, r.c2)
			pillow(r, -1.3, 1.95, -3.0, 2.1)
			pillow(r, 1.3, 1.95, -3.0, 2.1)
			r:boxAt(CFrame.new(0, 2.5, -2.55) * CFrame.Angles(-0.3, 0, 0.05), 1.1, 1.1, 0.26, r.c2, "Fabric")
			-- a throw folded across the foot
			r:block(-2.9, 2.08, 2.2, 2.9, 2.16, 3.0, mix(r.c2, IVORY, 0.5), "Fabric")
			-- the headboard curls back at the top, the footboard forward, each like a sleigh
			for _, e in { { -1, -3.95, 2.45, 4.0, -0.14 }, { 1, 3.95, 1.7, 2.6, 0.18 } } do
				local sz, z, y, h, tilt = e[1], e[2], e[3], e[4], e[5]
				local cf = CFrame.new(0, y, z) * CFrame.Angles(tilt, 0, 0)
				r:boxAt(cf, 5.8, h, 0.22, r.c1, "Wood")
				-- a raised panel facing the bed at the head and the room at the foot, with a gold
				-- line inlaid round it
				r:boxAt(cf * CFrame.new(0, 0, 0.135), 4.6, h - 1.4, 0.05, shade(r.c1, 1.08), "Wood")
				local gz = 0.18
				local hw, hh = 2.15, (h - 1.4) / 2 - 0.15
				r:boxAt(cf * CFrame.new(0, hh, gz), 2 * hw, 0.05, 0.04, GOLD, "Metal")
				r:boxAt(cf * CFrame.new(0, -hh, gz), 2 * hw, 0.05, 0.04, GOLD, "Metal")
				r:boxAt(cf * CFrame.new(-hw, 0, gz), 0.05, 2 * hh - 0.05, 0.04, GOLD, "Metal")
				r:boxAt(cf * CFrame.new(hw, 0, gz), 0.05, 2 * hh - 0.05, 0.04, GOLD, "Metal")
				local topP = (cf * CFrame.new(0, h / 2, 0)).Position
				local roll = Vector3.new(0, topP.Y - 0.08, topP.Z + sz * 0.18)
				r:cyl(0, roll.Y, roll.Z, 6.0, if sz < 0 then 0.7 else 0.6, "x", r.c1, "Wood")
				for _, sx in { -1, 1 } do
					r:beam(
						Vector3.new(sx * 2.95, 0.45, sz * 3.75),
						Vector3.new(sx * 2.95, roll.Y, roll.Z),
						0.32,
						0.32,
						dk,
						"Wood"
					)
					r:cyl(sx * 3.02, roll.Y, roll.Z, 0.04, if sz < 0 then 0.76 else 0.66, "x", dk, "Wood")
					r:cyl(sx * 3.06, roll.Y, roll.Z, 0.05, 0.28, "x", GOLD, "Metal")
				end
			end
			r:sleep(-1.3, 1.95, 0.2)
			r:sleep(1.3, 1.95, 0.2)
		end,
	},
	{
		id = "fancy_bed_crown",
		name = "Crown canopy bed",
		cat = "beds",
		style = "fancy",
		price = 640,
		place = "floor",
		size = Vector3.new(5.8, 9.2, 7.8),
		c1 = "EDE6DA",
		c2 = "C7A0A8",
		tags = { "bed" },
		build = function(r: R)
			local pleat = shade(r.c2, 0.9)
			-- a gathered skirt round the base, with pleats
			r:block(-2.62, 0.05, -3.5, 2.62, 1.3, 3.55, r.c2, "Fabric")
			r:piece(function(q: R)
				for i = 0, 8 do
					local x = -2.3 + i * 0.575
					q:block(x - 0.09, 0.05, 3.55, x + 0.09, 1.25, 3.59, pleat, "Fabric")
				end
				for _, sx in { -1, 1 } do
					for i = 0, 8 do
						local z = -3.1 + i * 0.78
						q:block(sx * 2.62 - 0.02, 0.05, z - 0.09, sx * 2.62 + 0.02, 1.25, z + 0.09, pleat, "Fabric")
					end
				end
			end)
			mattress(r, -2.55, 2.55, -3.5, 3.45, 1.3, 2.0, -0.6, mix(r.c2, IVORY, 0.55))
			pillow(r, -1.25, 2.0, -2.95, 2.0)
			pillow(r, 1.25, 2.0, -2.95, 2.0)
			r:boxAt(CFrame.new(0, 2.5, -2.45) * CFrame.Angles(-0.3, 0, 0), 1.0, 0.9, 0.26, r.c2, "Fabric")
			r:cyl(0, 2.24, -2.1, 1.6, 0.42, "x", IVORY, "Fabric")
			-- an upholstered headboard with an arched crest
			r:block(-2.72, 0.3, -3.85, 2.72, 4.0, -3.6, r.c1, "Wood")
			r:lump(CFrame.new(0, 4.0, -3.72), 3.6, 1.6, 0.25, r.c1, "Wood")
			r:block(-2.4, 2.1, -3.6, 2.4, 3.8, -3.5, mix(r.c2, IVORY, 0.35), "Fabric")
			for _, p in { { -1.6, 2.5 }, { -0.8, 3.2 }, { 0, 2.5 }, { 0.8, 3.2 }, { 1.6, 2.5 } } do
				button(r, p[1], p[2], -3.5, mix(r.c2, IVORY, 0.35))
			end
			r:ball(0, 4.86, -3.72, 0.22, GOLD, "Metal")
			-- the gilded crown on the wall, its half round band, points and a cap
			local zc = -3.88
			local rim: { Vector3 } = {}
			for i = 0, 6 do
				local a = i * math.pi / 6
				table.insert(rim, Vector3.new(math.cos(a) * 1.25, 8.55, zc + math.sin(a) * 1.25))
			end
			path(r, rim, 0.3, GOLD, "Metal")
			fan(r, Vector3.new(0, 8.75, zc), rim, 0.08, r.c1, "Wood")
			for i = 0, 6 do
				local p = rim[i + 1]
				r:cyl(p.X, 8.78, p.Z, 0.14, 0.06, "y", GOLD, "Metal")
				r:ball(p.X, 8.9, p.Z, 0.16, GOLD, "Metal")
			end
			r:ball(0, 9.02, zc + 0.6, 0.26, GOLD, "Metal")
			-- drapes fall from the crown behind the bed and out to each side, tied back
			r:quad(
				Vector3.new(-1.2, 8.45, -3.92),
				Vector3.new(1.2, 8.45, -3.92),
				Vector3.new(2.4, 4.1, -3.92),
				Vector3.new(-2.4, 4.1, -3.92),
				0.05,
				pleat,
				"Fabric"
			)
			for _, sx in { -1, 1 } do
				r:quad(
					Vector3.new(sx * 1.1, 8.45, -2.95),
					Vector3.new(sx * 1.25, 8.45, -3.84),
					Vector3.new(sx * 2.88, 3.4, -3.84),
					Vector3.new(sx * 2.88, 3.4, -3.2),
					0.08,
					r.c2,
					"Fabric"
				)
				r:quad(
					Vector3.new(sx * 2.88, 3.4, -3.2),
					Vector3.new(sx * 2.88, 3.4, -3.84),
					Vector3.new(sx * 2.84, 0.05, -3.84),
					Vector3.new(sx * 2.94, 0.05, -2.3),
					0.08,
					r.c2,
					"Fabric"
				)
				r:cyl(sx * 2.88, 3.4, -3.6, 0.16, 0.6, "y", GOLD, "Fabric")
				r:add({
					shape = "Cone",
					cf = CFrame.new(sx * 2.88, 2.95, -3.2) * CFrame.Angles(math.pi, 0, 0),
					size = Vector3.new(0.22, 0.42, 0.22),
					color = GOLD,
					mat = "Fabric",
				})
				r:ball(sx * 2.88, 3.2, -3.2, 0.14, GOLD, "Fabric")
			end
			r:sleep(-1.25, 2.0, 0.2)
			r:sleep(1.25, 2.0, 0.2)
		end,
	},

	------------------------------------------------------------------------------------------
	-- Storage
	{
		id = "fancy_dressing_table",
		name = "Dressing table",
		cat = "storage",
		style = "fancy",
		price = 280,
		place = "floor",
		size = Vector3.new(4.4, 5.6, 1.9),
		c1 = "EDE6DA",
		c2 = "C9A55E",
		tags = { "mirror", "storage" },
		build = function(r: R)
			local front = shade(r.c1, 0.94)
			for _, sx in { -1, 1 } do
				for _, sz in { -1, 1 } do
					cabriole(r, sx * 1.95, sz * 0.68, 0.7, sx, sz, 0.18, r.c1)
				end
				-- a pedestal of two drawers each side, with gold knobs
				r:block(sx * 1.0, 0.7, -0.85, sx * 2.15, 2.25, 0.8, r.c1, "Wood")
				for _, d in { { 0.8, 1.48 }, { 1.56, 2.18 } } do
					local x1, x2 = sx * 1.08, sx * 2.07
					r:block(math.min(x1, x2), d[1], 0.8, math.max(x1, x2), d[2], 0.84, front, "Wood")
					r:ball(sx * 1.575, (d[1] + d[2]) / 2, 0.88, 0.12, r.c2, "Metal")
				end
			end
			-- the long middle drawer and the top with a moulded edge
			r:block(-2.15, 2.25, -0.85, 2.15, 2.55, 0.8, r.c1, "Wood")
			r:block(-0.95, 2.3, 0.8, 0.95, 2.5, 0.84, front, "Wood")
			r:ball(0, 2.4, 0.88, 0.1, r.c2, "Metal")
			r:block(-2.25, 2.55, -0.95, 2.25, 2.62, 0.95, shade(r.c1, 0.9), "Wood")
			r:block(-2.2, 2.62, -0.9, 2.2, 2.7, 0.9, r.c1, "Wood")
			-- three mirrors: an arched one in the middle and two wings turned toward you
			r:block(-0.9, 2.7, -0.82, 0.9, 5.0, -0.7, r.c2, "Metal")
			r:lump(CFrame.new(0, 5.0, -0.76), 1.8, 0.9, 0.12, r.c2, "Metal")
			r:block(-0.74, 2.86, -0.7, 0.74, 4.95, -0.66, MIRROR, "Glass")
			r:lump(CFrame.new(0, 4.95, -0.68), 1.48, 0.62, 0.04, MIRROR, "Glass")
			r:ball(0, 5.5, -0.76, 0.16, r.c2, "Metal")
			for _, sx in { -1, 1 } do
				local hinge = CFrame.new(sx * 0.9, 3.85, -0.76) * CFrame.Angles(0, -sx * 0.5, 0)
				local wing = hinge * CFrame.new(sx * 0.46, 0, 0)
				r:boxAt(wing, 0.92, 1.9, 0.1, r.c2, "Metal")
				r:boxAt(wing * CFrame.new(0, 0, 0.065), 0.74, 1.72, 0.04, MIRROR, "Glass")
			end
			-- perfume bottles, a jewellery box and a hairbrush
			for i, p in { { -1.55, 0.35 }, { -1.25, 0.5 } } do
				local h = if i == 1 then 0.34 else 0.26
				r:cyl(p[1], 2.7 + h / 2, p[2], h, 0.2, "y", Color3.fromRGB(226, 190, 204), "Glass")
				r:cyl(p[1], 2.7 + h + 0.04, p[2], 0.08, 0.08, "y", r.c2, "Metal")
				r:ball(p[1] + 0.1, 2.7 + h + 0.06, p[2], 0.1, Color3.fromRGB(214, 140, 160), "Glass")
			end
			r:block(1.05, 2.7, 0.15, 1.65, 2.95, 0.6, Color3.fromRGB(150, 110, 140), "Fabric")
			r:block(1.02, 2.95, 0.12, 1.68, 3.02, 0.63, r.c2, "Metal")
			r:block(1.3, 2.88, 0.63, 1.4, 2.95, 0.65, r.c2, "Metal")
			r:boxAt(CFrame.new(0.4, 2.74, 0.45) * CFrame.Angles(0, -0.4, 0), 0.7, 0.07, 0.12, r.c2, "Metal")
			r:boxAt(CFrame.new(0.65, 2.78, 0.35) * CFrame.Angles(0, -0.4, 0), 0.34, 0.12, 0.26, WALNUT, "Wood")
		end,
	},
	{
		id = "fancy_bookcase_glass",
		name = "Glass front bookcase",
		gives = "books", -- holding E gives something (Data/Items.Sources)
		cat = "storage",
		style = "fancy",
		price = 380,
		place = "floor",
		size = Vector3.new(4.4, 7.5, 1.7),
		c1 = "6B4A36",
		c2 = "D8CFBE",
		tags = { "books", "storage" },
		build = function(r: R)
			local dk = shade(r.c1, 0.82)
			-- a plinth, a cupboard below with two panelled doors
			r:block(-2.15, 0, -0.8, 2.15, 0.35, 0.75, dk, "Wood")
			r:block(-2.05, 0.35, -0.75, 2.05, 2.6, 0.6, r.c1, "Wood")
			for _, sx in { -1, 1 } do
				local x1, x2 = sx * 0.03, sx * 1.95
				r:block(math.min(x1, x2), 0.45, 0.6, math.max(x1, x2), 2.5, 0.64, shade(r.c1, 1.06), "Wood")
				local p1, p2 = sx * 0.28, sx * 1.7
				r:block(math.min(p1, p2), 0.7, 0.64, math.max(p1, p2), 2.25, 0.68, shade(r.c1, 0.94), "Wood")
				r:ball(sx * 0.15, 1.5, 0.7, 0.12, GOLD, "Metal")
			end
			r:block(-2.15, 2.6, -0.8, 2.15, 2.75, 0.78, dk, "Wood")
			-- the glazed cabinet: sides, a pale back, shelves
			for _, sx in { -1, 1 } do
				local x1, x2 = sx * 1.85, sx * 1.95
				r:block(math.min(x1, x2), 2.75, -0.75, math.max(x1, x2), 6.6, 0.3, r.c1, "Wood")
			end
			r:block(-1.85, 2.75, -0.75, 1.85, 6.6, -0.68, r.c2, "Wood")
			r:block(-1.85, 2.75, -0.68, 1.85, 2.83, 0.28, r.c1, "Wood")
			r:block(-1.85, 6.5, -0.68, 1.85, 6.6, 0.28, r.c1, "Wood")
			for _, y in { 3.85, 4.95 } do
				r:block(-1.85, y, -0.68, 1.85, y + 0.08, 0.2, r.c1, "Wood")
			end
			-- three rows of books
			local spines = {
				Color3.fromRGB(150, 70, 78),
				Color3.fromRGB(70, 96, 120),
				Color3.fromRGB(96, 120, 88),
				Color3.fromRGB(196, 160, 96),
				Color3.fromRGB(120, 86, 120),
				Color3.fromRGB(222, 211, 188),
			}
			for row, y in { 2.83, 3.93, 5.03 } do
				r:piece(function(q: R)
					local x = -1.78
					local i = row
					while x < 1.5 do
						local w = 0.15 + ((i * 7) % 5) * 0.025
						local h = 0.7 + ((i * 3) % 4) * 0.08
						q:block(x, y, -0.66, x + w, y + h, -0.12, spines[i % #spines + 1], "Cardboard")
						x += w + 0.015
						i += 1
					end
					q:boxAt(
						CFrame.new(1.62, y + 0.36, -0.42) * CFrame.Angles(0, 0, -0.3),
						0.16,
						0.78,
						0.5,
						spines[(row + 2) % #spines + 1],
						"Cardboard"
					)
				end, nil, "Cardboard")
			end
			-- two glazed doors with glazing bars
			for _, sx in { -1, 1 } do
				local xa, xb = sx * 0.02, sx * 1.85
				local x1, x2 = math.min(xa, xb), math.max(xa, xb)
				r:glass(x1 + 0.1, 2.9, 0.325, x2 - 0.1, 6.45, 0.355)
				r:piece(function(q: R)
					q:block(x1, 2.83, 0.3, x2, 2.95, 0.38, r.c1, "Wood")
					q:block(x1, 6.4, 0.3, x2, 6.5, 0.38, r.c1, "Wood")
					q:block(x1, 2.95, 0.3, x1 + 0.1, 6.4, 0.38, r.c1, "Wood")
					q:block(x2 - 0.1, 2.95, 0.3, x2, 6.4, 0.38, r.c1, "Wood")
					local xm = (x1 + x2) / 2
					q:block(xm - 0.03, 2.95, 0.3, xm + 0.03, 6.4, 0.38, r.c1, "Wood")
					for _, y in { 4.1, 5.25 } do
						q:block(x1 + 0.1, y - 0.03, 0.3, x2 - 0.1, y + 0.03, 0.38, r.c1, "Wood")
					end
				end)
				r:ball(sx * 0.18, 4.6, 0.42, 0.1, GOLD, "Metal")
			end
			-- a stepped cornice and a broken pediment with an urn in the gap
			r:block(-2.05, 6.6, -0.8, 2.05, 6.75, 0.42, r.c1, "Wood")
			r:block(-2.2, 6.75, -0.85, 2.2, 6.92, 0.52, dk, "Wood")
			r:block(-2.12, 6.92, -0.8, 2.12, 7.02, 0.46, r.c1, "Wood")
			for _, sx in { -1, 1 } do
				r:tri(
					Vector3.new(sx * 2.0, 7.02, 0.32),
					Vector3.new(sx * 0.35, 7.02, 0.32),
					Vector3.new(sx * 0.35, 7.45, 0.32),
					0.2,
					r.c1,
					"Wood"
				)
			end
			r:cyl(0, 7.08, 0.3, 0.12, 0.34, "y", GOLD, "Metal")
			r:lump(CFrame.new(0, 7.26, 0.3), 0.3, 0.28, 0.3, GOLD, "Metal")
			r:ball(0, 7.43, 0.3, 0.1, GOLD, "Metal")
		end,
	},

	------------------------------------------------------------------------------------------
	-- Lights
	{
		id = "fancy_chandelier_crystal",
		name = "Crystal chandelier",
		cat = "lights",
		style = "fancy",
		price = 520,
		place = "ceiling",
		size = Vector3.new(3.6, 3.4, 3.6),
		c1 = "D4AE5E",
		c2 = "E6EEF4",
		tags = { "light" },
		build = function(r: R)
			-- the ceiling rose and a short chain of links
			r:cyl(0, -0.05, 0, 0.1, 0.9, "y", r.c1, "Metal")
			r:cyl(0, -0.16, 0, 0.12, 0.4, "y", r.c1, "Metal")
			for i = 0, 3 do
				local y = -0.33 - i * 0.18
				if i % 2 == 0 then
					r:box(0, y, 0, 0.05, 0.2, 0.14, r.c1, "Metal")
				else
					r:box(0, y, 0, 0.14, 0.2, 0.05, r.c1, "Metal")
				end
			end
			-- a crown with a ring of drops, a glass ball, the hub
			r:cyl(0, -1.2, 0, 0.5, 0.14, "y", r.c1, "Metal")
			r:ball(0, -1.0, 0, 0.22, r.c1, "Metal")
			local crown: { Vector3 } = {}
			for i = 0, 8 do
				local a = i * math.pi / 4
				table.insert(crown, Vector3.new(math.cos(a) * 0.58, -1.38, math.sin(a) * 0.58))
			end
			path(r, crown, 0.07, r.c1, "Metal")
			for i = 0, 3 do
				local a = i * math.pi / 2 + math.pi / 4
				rod(
					r,
					Vector3.new(0, -1.2, 0),
					Vector3.new(math.cos(a) * 0.56, -1.38, math.sin(a) * 0.56),
					0.05,
					r.c1,
					"Metal"
				)
			end
			for i = 0, 7 do
				local a = i * math.pi / 4
				local x, z = math.cos(a) * 0.58, math.sin(a) * 0.58
				r:ball(x, -1.5, z, 0.12, r.c2, "Glass")
				r:add({
					shape = "Cone",
					cf = CFrame.new(x, -1.66, z) * CFrame.Angles(math.pi, 0, 0),
					size = Vector3.new(0.12, 0.2, 0.12),
					color = r.c2,
					mat = "Glass",
				})
			end
			r:ball(0, -1.78, 0, 0.5, r.c2, "Glass")
			r:cyl(0, -2.12, 0, 0.26, 0.3, "y", r.c1, "Metal")
			r:lump(CFrame.new(0, -2.36, 0), 0.9, 0.36, 0.9, r.c1, "Metal")
			-- six arms out to candles, a drop under each elbow and swags of beads between
			local elbows: { Vector3 } = {}
			for i = 0, 5 do
				local a = i * math.pi / 3
				local dx, dz = math.cos(a), math.sin(a)
				local e = Vector3.new(dx * 1.15, -2.5, dz * 1.15)
				table.insert(elbows, e)
				path(
					r,
					{ Vector3.new(dx * 0.42, -2.35, dz * 0.42), e, Vector3.new(dx * 1.5, -2.15, dz * 1.5) },
					0.09,
					r.c1,
					"Metal"
				)
				r:cyl(dx * 1.5, -2.1, dz * 1.5, 0.08, 0.32, "y", r.c1, "Metal")
				r:cyl(dx * 1.5, -1.83, dz * 1.5, 0.46, 0.14, "y", IVORY, "Plaster")
				local flame = r:ball(dx * 1.5, -1.53, dz * 1.5, 0.13, C.Warm, "Glass")
				if i == 0 then
					r:glow(flame, 22, 1.6)
				else
					glowOnly(flame)
				end
				r:ball(e.X, -2.64, e.Z, 0.12, r.c2, "Glass")
				r:add({
					shape = "Cone",
					cf = CFrame.new(e.X, -2.82, e.Z) * CFrame.Angles(math.pi, 0, 0),
					size = Vector3.new(0.14, 0.24, 0.14),
					color = r.c2,
					mat = "Glass",
				})
			end
			for i = 1, 6 do
				local a, b = elbows[i], elbows[i % 6 + 1]
				local m = (a + b) / 2 * 0.92 + Vector3.new(0, -0.32, 0)
				r:beam(a, m, 0.05, 0.05, r.c2, "Glass")
				r:beam(m, b, 0.05, 0.05, r.c2, "Glass")
			end
			-- a ball and a long drop below the hub
			r:ball(0, -2.7, 0, 0.36, r.c2, "Glass")
			r:add({
				shape = "Cone",
				cf = CFrame.new(0, -3.1, 0) * CFrame.Angles(math.pi, 0, 0),
				size = Vector3.new(0.24, 0.5, 0.24),
				color = r.c2,
				mat = "Glass",
			})
		end,
	},
	{
		id = "fancy_sconce",
		name = "Candle sconce",
		cat = "lights",
		style = "fancy",
		price = 70,
		place = "wall",
		size = Vector3.new(1.6, 2.4, 1.0),
		c1 = "D4AE5E",
		c2 = "F4EFE4",
		tags = { "light" },
		build = function(r: R)
			-- a gold back plate, arched at the top and pointed below, with a mirror in it
			r:block(-0.32, 0.55, 0, 0.32, 1.9, 0.1, r.c1, "Metal")
			r:cyl(0, 1.9, 0.05, 0.1, 0.64, "z", r.c1, "Metal")
			r:add({
				shape = "Cone",
				cf = CFrame.new(0, 0.42, 0.05) * CFrame.Angles(math.pi, 0, 0),
				size = Vector3.new(0.4, 0.36, 0.1),
				color = r.c1,
				mat = "Metal",
			})
			r:lump(CFrame.new(0, 1.38, 0.11), 0.42, 0.9, 0.06, MIRROR, "Glass")
			r:ball(0, 2.28, 0.05, 0.18, r.c1, "Metal")
			-- two curling arms, each with a cup, a candle and a crystal drop
			for _, sx in { -1, 1 } do
				path(r, {
					Vector3.new(sx * 0.15, 0.85, 0.1),
					Vector3.new(sx * 0.45, 0.72, 0.42),
					Vector3.new(sx * 0.6, 1.05, 0.68),
				}, 0.08, r.c1, "Metal")
				r:cyl(sx * 0.6, 1.1, 0.68, 0.08, 0.3, "y", r.c1, "Metal")
				r:cyl(sx * 0.6, 1.39, 0.68, 0.5, 0.13, "y", r.c2, "Plaster")
				local flame = r:ball(sx * 0.6, 1.7, 0.68, 0.13, C.Warm, "Glass")
				if sx < 0 then
					r:glow(flame, 12, 1)
				else
					glowOnly(flame)
				end
				r:ball(sx * 0.6, 0.96, 0.68, 0.1, MIRROR, "Glass")
			end
		end,
	},
	{
		id = "fancy_candelabra",
		name = "Candelabra",
		cat = "lights",
		style = "fancy",
		price = 60,
		place = "surface",
		size = Vector3.new(1.7, 2.2, 0.7),
		c1 = "C9CCD2",
		c2 = "F4EFE4",
		tags = { "light" },
		build = function(r: R)
			-- a stepped round foot, a stem with two knops
			r:cyl(0, 0.03, 0, 0.06, 0.62, "y", r.c1, "Metal")
			r:cyl(0, 0.1, 0, 0.08, 0.48, "y", r.c1, "Metal")
			r:lump(CFrame.new(0, 0.16, 0), 0.4, 0.2, 0.4, r.c1, "Metal")
			r:cyl(0, 0.68, 0, 0.98, 0.1, "y", r.c1, "Metal")
			r:ball(0, 0.45, 0, 0.2, r.c1, "Metal")
			r:ball(0, 0.92, 0, 0.16, r.c1, "Metal")
			-- five lights: one tall in the middle, two pairs on curling arms
			local tops = {
				Vector3.new(0, 1.2, 0),
				Vector3.new(-0.4, 1.25, 0),
				Vector3.new(0.4, 1.25, 0),
				Vector3.new(-0.74, 1.12, 0),
				Vector3.new(0.74, 1.12, 0),
			}
			for _, sx in { -1, 1 } do
				path(
					r,
					{ Vector3.new(0, 1.12, 0), Vector3.new(sx * 0.3, 1.02, 0), tops[if sx < 0 then 2 else 3] },
					0.06,
					r.c1,
					"Metal"
				)
				path(
					r,
					{ Vector3.new(0, 0.98, 0), Vector3.new(sx * 0.55, 0.9, 0), tops[if sx < 0 then 4 else 5] },
					0.06,
					r.c1,
					"Metal"
				)
			end
			for i, t in tops do
				local h = if i == 1 then 0.62 else 0.5
				r:cyl(t.X, t.Y + 0.03, t.Z, 0.06, 0.22, "y", r.c1, "Metal")
				r:cyl(t.X, t.Y + 0.06 + h / 2, t.Z, h, 0.1, "y", r.c2, "Plaster")
				local flame = r:ball(t.X, t.Y + 0.12 + h, t.Z, 0.1, C.Warm, "Glass")
				if i == 1 then
					r:glow(flame, 10, 1)
				else
					glowOnly(flame)
				end
			end
		end,
	},

	------------------------------------------------------------------------------------------
	-- Fun
	{
		id = "fancy_piano_grand",
		name = "Grand piano",
		cat = "fun",
		style = "fancy",
		price = 1200,
		place = "floor",
		size = Vector3.new(4.8, 5.4, 8.6),
		c1 = "3A3238",
		c2 = "B98A93",
		tags = { "music" },
		build = function(r: R)
			local OUT = {
				{ -2.3, 1.2 },
				{ -2.3, -3.9 },
				{ -2.05, -4.22 },
				{ -1.5, -4.25 },
				{ -0.85, -3.8 },
				{ -0.2, -2.9 },
				{ 0.45, -1.95 },
				{ 1.15, -1.15 },
				{ 1.85, -0.5 },
				{ 2.25, 0.1 },
				{ 2.3, 0.6 },
				{ 2.3, 1.2 },
			}
			-- three legs on brass castors
			for _, p in { { -1.95, 0.85 }, { 1.95, 0.85 }, { -1.75, -3.55 } } do
				r:cyl(p[1], 0.08, p[2], 0.16, 0.3, "y", GOLD, "Metal")
				r:cyl(p[1], 1.08, p[2], 1.84, 0.42, "y", r.c1, "Wood")
				r:cyl(p[1], 0.3, p[2], 0.12, 0.5, "y", r.c1, "Wood")
				r:block(p[1] - 0.3, 2.0, p[2] - 0.3, p[1] + 0.3, 2.16, p[2] + 0.3, r.c1, "Wood")
			end
			-- the case: a wall round the outline
			for i = 1, #OUT - 1 do
				local a, b = OUT[i], OUT[i + 1]
				local pa, pb = Vector3.new(a[1], 2.63, a[2]), Vector3.new(b[1], 2.63, b[2])
				local u = (pb - pa).Unit * 0.08
				r:beam(pa - u, pb + u, 0.16, 0.95, r.c1, "Wood")
			end
			r:block(-2.3, 2.15, 1.12, 2.3, 3.1, 1.28, r.c1, "Wood")
			-- inside: the soundboard, the gold frame and the strings
			local inner: { Vector3 } = {}
			for _, p in OUT do
				table.insert(inner, Vector3.new(p[1], 2.92, p[2]))
			end
			fan(r, Vector3.new(-0.9, 2.92, -1.0), inner, 0.06, Color3.fromRGB(217, 185, 138), "Wood", true)
			r:piece(function(q: R)
				q:block(-2.15, 2.95, 0.68, 2.15, 3.01, 0.84, GOLD, "Metal")
				q:block(-1.86, 2.95, -3.7, -1.72, 3.01, 0.68, GOLD, "Metal")
				q:beam(Vector3.new(-0.6, 2.98, 0.68), Vector3.new(-0.95, 2.98, -3.3), 0.14, 0.06, GOLD, "Metal")
				q:beam(Vector3.new(0.9, 2.98, 0.68), Vector3.new(0.3, 2.98, -1.9), 0.14, 0.06, GOLD, "Metal")
			end)
			r:piece(function(q: R)
				for i = 0, 9 do
					local x = -2.05 + i * 0.44
					local zEnd = if x < -0.85 then -3.9 elseif x < 0.45 then -2.9 + (x + 0.2) * 1.4 else -1.6 + x * 0.6
					q:block(x - 0.012, 3.03, zEnd + 0.15, x + 0.012, 3.05, 0.62, Color3.fromRGB(190, 182, 168), "Metal")
				end
			end)
			-- the lid, held open on its stick
			local lid = 0.5
			local lidPts: { Vector3 } = {}
			for _, p in OUT do
				local u = p[1] + 2.3
				table.insert(lidPts, Vector3.new(-2.3 + u * math.cos(lid), 3.16 + u * math.sin(lid), p[2]))
			end
			local lm = Vector3.new(-2.3 + 1.4 * math.cos(lid), 3.16 + 1.4 * math.sin(lid), -1.0)
			fan(r, lm, lidPts, 0.08, r.c1, "Wood", true)
			rod(r, Vector3.new(1.25, 3.1, -0.9), Vector3.new(0.82, 4.82, -0.9), 0.07, r.c1, "Wood")
			-- the keyboard: a key bed, cheeks, white keys with gaps, black keys in twos and threes
			r:block(-2.3, 2.3, 1.28, 2.3, 2.62, 2.15, r.c1, "Wood")
			for _, sx in { -1, 1 } do
				local x1, x2 = sx * 2.06, sx * 2.3
				r:block(math.min(x1, x2), 2.62, 1.28, math.max(x1, x2), 2.98, 2.15, r.c1, "Wood")
			end
			r:block(-2.06, 2.62, 1.28, 2.06, 3.1, 1.36, r.c1, "Wood")
			r:block(-2.0, 2.62, 1.36, 2.0, 2.72, 2.1, C.White, "Marble")
			local n = 27
			local w = 4.0 / n
			r:piece(function(q: R)
				for k = 1, n - 1 do
					local x = -2.0 + k * w
					q:block(x - 0.01, 2.72, 1.5, x + 0.01, 2.75, 2.1, Color3.fromRGB(200, 196, 190), "Metal")
				end
			end, nil, "Metal")
			r:piece(function(q: R)
				for k = 0, n - 2 do
					if table.find({ 0, 1, 3, 4, 5 }, k % 7) then
						local x = -2.0 + (k + 1) * w
						q:block(x - 0.045, 2.72, 1.38, x + 0.045, 2.82, 1.82, C.Black, "Wood")
					end
				end
			end, nil, "Wood")
			r:block(-0.2, 2.95, 1.36, 0.2, 3.0, 1.39, GOLD, "Metal")
			-- the music desk with a page of music
			local desk = CFrame.new(0, 3.5, 0.95) * CFrame.Angles(-0.25, 0, 0)
			r:boxAt(desk, 2.2, 0.75, 0.08, r.c1, "Wood")
			r:boxAt(desk * CFrame.new(0, 0.05, 0.055), 1.3, 0.6, 0.03, C.Paper, "Cardboard")
			-- the pedal lyre
			for _, sx in { -1, 1 } do
				path(r, {
					Vector3.new(sx * 0.32, 2.3, 1.0),
					Vector3.new(sx * 0.4, 1.4, 1.05),
					Vector3.new(sx * 0.25, 0.5, 1.05),
				}, 0.12, r.c1, "Wood")
				rod(r, Vector3.new(sx * 0.1, 0.5, 1.05), Vector3.new(sx * 0.1, 1.8, 1.05), 0.04, GOLD, "Metal")
			end
			r:block(-0.45, 0.25, 0.85, 0.45, 0.5, 1.25, r.c1, "Wood")
			r:piece(function(q: R)
				for _, x in { -0.2, 0, 0.2 } do
					q:block(x - 0.05, 0.28, 1.25, x + 0.05, 0.34, 1.5, GOLD, "Metal")
				end
			end)
			-- a padded bench facing the keys
			for _, sx in { -1, 1 } do
				for _, sz in { -1, 1 } do
					rod(
						r,
						Vector3.new(sx * 0.9, 1.8, 3.45 + sz * 0.3),
						Vector3.new(sx * 0.95, 0, 3.45 + sz * 0.33),
						0.16,
						r.c1,
						"Wood"
					)
				end
				rod(r, Vector3.new(sx * 0.93, 0.5, 3.12), Vector3.new(sx * 0.93, 0.5, 3.78), 0.07, r.c1, "Wood")
			end
			r:block(-1.1, 1.8, 3.05, 1.1, 1.95, 3.85, r.c1, "Wood")
			r:block(-1.02, 1.95, 3.12, 1.02, 2.15, 3.78, r.c2, "Fabric")
			button(r, -0.45, 2.15, 3.45, r.c2)
			button(r, 0.45, 2.15, 3.45, r.c2)
			r:seat(0, 2.15, 3.45, 180)
		end,
	},
	{
		id = "fancy_harp",
		name = "Harp",
		cat = "fun",
		style = "fancy",
		price = 600,
		place = "floor",
		size = Vector3.new(1.4, 5.4, 2.8),
		c1 = "D4AE5E",
		c2 = "8A6248",
		tags = { "music" },
		build = function(r: R)
			-- a base on four feet with pedals round it
			r:block(-0.55, 0.15, -1.15, 0.55, 0.5, 0.95, r.c2, "Wood")
			r:block(-0.6, 0.45, -1.2, 0.6, 0.53, 1.0, r.c1, "Metal")
			for _, sx in { -1, 1 } do
				for _, z in { -0.95, 0.75 } do
					r:ball(sx * 0.42, 0.1, z, 0.22, r.c1, "Metal")
				end
				r:piece(function(q: R)
					for _, z in { -0.6, -0.2, 0.2, 0.6 } do
						q:block(sx * 0.55, 0.24, z - 0.05, sx * 0.72, 0.3, z + 0.05, r.c1, "Metal")
					end
				end)
			end
			-- the column with a drum at its foot and a capital on top
			r:cyl(0, 0.7, -0.95, 0.35, 0.5, "y", r.c1, "Metal")
			r:cyl(0, 2.75, -0.95, 4.1, 0.3, "y", r.c1, "Metal")
			r:cyl(0, 4.82, -0.95, 0.24, 0.48, "y", r.c1, "Metal")
			r:lump(CFrame.new(0, 5.05, -0.95), 0.44, 0.34, 0.44, r.c1, "Metal")
			r:ball(0, 5.27, -0.95, 0.16, r.c1, "Metal")
			-- the soundbox, wide at the foot and narrow at the top, with a gold rib for the strings
			local s1, s2 = Vector3.new(0, 0.6, -0.65), Vector3.new(0, 4.25, 1.2)
			local dir = (s2 - s1).Unit
			local nrm = Vector3.new(0, dir.Z, -dir.Y)
			local mid = s1:Lerp(s2, 0.5)
			r:beam(s1, mid + dir * 0.05, 0.9, 0.55, r.c2, "Wood")
			r:beam(mid - dir * 0.05, s2, 0.62, 0.42, r.c2, "Wood")
			r:beam(s1 + nrm * 0.3, s2 + nrm * 0.24, 0.12, 0.06, r.c1, "Metal")
			-- the neck curls from the column over to the soundbox
			local neck = {
				Vector3.new(0, 4.82, -0.95),
				Vector3.new(0, 5.1, -0.45),
				Vector3.new(0, 4.92, 0.15),
				Vector3.new(0, 4.6, 0.7),
				Vector3.new(0, 4.45, 1.22),
			}
			for i = 1, #neck - 1 do
				local a, b = neck[i], neck[i + 1]
				local u = (b - a).Unit * 0.1
				r:beam(if i > 1 then a - u else a, if i < #neck - 1 then b + u else b, 0.24, 0.34, r.c1, "Metal")
			end
			-- strings from the neck down to the rib, every fourth one red
			local function neckY(z: number): number
				for i = 1, #neck - 1 do
					local a, b = neck[i], neck[i + 1]
					if z >= a.Z and z <= b.Z then
						return a.Y + (b.Y - a.Y) * (z - a.Z) / (b.Z - a.Z)
					end
				end
				return neck[#neck].Y
			end
			for i = 0, 10 do
				local z = -0.55 + i * 0.155
				local yb = s1.Y + (z - s1.Z) * dir.Y / dir.Z + 0.33
				local yt = neckY(z) - 0.17
				if yt > yb + 0.1 then
					rod(r, Vector3.new(0, yb, z), Vector3.new(0, yt, z), 0.035, if i % 4 == 1 then C.Red else IVORY)
				end
			end
		end,
	},

	------------------------------------------------------------------------------------------
	-- Decor
	{
		id = "fancy_clock_mantel",
		name = "Mantel clock",
		cat = "decor",
		style = "fancy",
		price = 70,
		place = "surface",
		size = Vector3.new(1.4, 1.7, 0.8),
		c1 = "6B4A36",
		c2 = "D4AE5E",
		tags = { "clock" },
		build = function(r: R)
			for _, sx in { -1, 1 } do
				for _, sz in { -1, 1 } do
					r:ball(sx * 0.48, 0.07, sz * 0.22, 0.14, r.c2, "Metal")
				end
			end
			r:block(-0.62, 0.12, -0.32, 0.62, 0.22, 0.32, shade(r.c1, 0.85), "Wood")
			r:block(-0.55, 0.22, -0.28, 0.55, 1.1, 0.28, r.c1, "Wood")
			r:block(-0.6, 1.1, -0.31, 0.6, 1.16, 0.31, shade(r.c1, 0.85), "Wood")
			-- a bell top with a brass handle and finial
			r:lump(CFrame.new(0, 1.16, 0), 1.0, 0.5, 0.5, r.c1, "Wood")
			r:ball(0, 1.43, 0, 0.12, r.c2, "Metal")
			path(r, {
				Vector3.new(-0.25, 1.32, 0),
				Vector3.new(-0.25, 1.56, 0),
				Vector3.new(0.25, 1.56, 0),
				Vector3.new(0.25, 1.32, 0),
			}, 0.04, r.c2, "Metal")
			-- pillars at the front corners and gold frets on the sides
			for _, sx in { -1, 1 } do
				r:cyl(sx * 0.49, 0.66, 0.29, 0.84, 0.08, "y", r.c2, "Metal")
				r:block(sx * 0.55, 0.45, -0.15, sx * 0.55 + sx * 0.03, 0.85, 0.15, r.c2, "Metal")
			end
			-- the dial in a gold bezel, with marks and hands
			r:cyl(0, 0.68, 0.3, 0.04, 0.72, "z", r.c2, "Metal")
			r:cyl(0, 0.68, 0.33, 0.04, 0.6, "z", C.Paper, "Cardboard")
			r:piece(function(q: R)
				q:block(-0.02, 0.9, 0.35, 0.02, 0.96, 0.38, C.Black, "Metal")
				q:block(-0.02, 0.4, 0.35, 0.02, 0.46, 0.38, C.Black, "Metal")
				q:block(-0.28, 0.66, 0.35, -0.22, 0.7, 0.38, C.Black, "Metal")
				q:block(0.22, 0.66, 0.35, 0.28, 0.7, 0.38, C.Black, "Metal")
			end, nil, "Metal")
			r:boxAt(
				CFrame.new(-0.06, 0.72, 0.395) * CFrame.Angles(0, 0, 0.9),
				0.03,
				0.15,
				0.03,
				C.Black,
				"Metal"
			)
			r:boxAt(
				CFrame.new(0.07, 0.76, 0.395) * CFrame.Angles(0, 0, -0.5),
				0.025,
				0.2,
				0.03,
				C.Black,
				"Metal"
			)
			r:ball(0, 0.68, 0.4, 0.05, r.c2, "Metal")
		end,
	},
	{
		id = "fancy_urn_plinth",
		name = "Urn on a plinth",
		cat = "decor",
		style = "fancy",
		price = 140,
		place = "floor",
		size = Vector3.new(1.8, 5.2, 1.8),
		c1 = "ECE6DE",
		c2 = "9DB39B",
		tags = { "plant" },
		build = function(r: R)
			-- a marble plinth with a sunk panel on each face
			r:block(-0.8, 0, -0.8, 0.8, 0.3, 0.8, r.c1, "Marble")
			r:block(-0.7, 0.3, -0.7, 0.7, 0.45, 0.7, shade(r.c1, 0.95), "Marble")
			r:block(-0.58, 0.45, -0.58, 0.58, 2.9, 0.58, r.c1, "Marble")
			r:piece(function(q: R)
				q:block(-0.42, 0.75, 0.58, 0.42, 2.6, 0.61, shade(r.c1, 0.92), "Marble")
				q:block(-0.42, 0.75, -0.61, 0.42, 2.6, -0.58, shade(r.c1, 0.92), "Marble")
				q:block(0.58, 0.75, -0.42, 0.61, 2.6, 0.42, shade(r.c1, 0.92), "Marble")
				q:block(-0.61, 0.75, -0.42, -0.58, 2.6, 0.42, shade(r.c1, 0.92), "Marble")
			end)
			r:block(-0.68, 2.9, -0.68, 0.68, 3.05, 0.68, shade(r.c1, 0.95), "Marble")
			r:block(-0.76, 3.05, -0.76, 0.76, 3.2, 0.76, r.c1, "Marble")
			-- the urn: a foot, a round bowl, a lipped rim and two loop handles
			r:cyl(0, 3.26, 0, 0.12, 0.62, "y", r.c2, "Marble")
			r:cyl(0, 3.42, 0, 0.22, 0.32, "y", r.c2, "Marble")
			r:lump(CFrame.new(0, 3.95, 0), 1.22, 0.92, 1.22, r.c2, "Marble")
			r:cyl(0, 4.41, 0, 0.14, 1.0, "y", r.c2, "Marble")
			r:cyl(0, 4.52, 0, 0.08, 1.16, "y", shade(r.c2, 0.88), "Marble")
			r:cyl(0, 4.575, 0, 0.03, 1.0, "y", C.Soil, "Sand")
			for _, sx in { -1, 1 } do
				path(r, {
					Vector3.new(sx * 0.48, 4.32, 0),
					Vector3.new(sx * 0.74, 4.25, 0),
					Vector3.new(sx * 0.66, 3.9, 0),
					Vector3.new(sx * 0.5, 3.8, 0),
				}, 0.07, shade(r.c2, 0.88))
			end
			-- ferns in the middle, hydrangea heads and ivy trailing over the rim
			r:lump(CFrame.new(0, 4.72, 0), 0.95, 0.42, 0.95, DARKLEAF, "Grass")
			for i = 0, 5 do
				local a = i * math.pi / 3 + 0.3
				r:boxAt(
					CFrame.new(math.cos(a) * 0.38, 4.95, math.sin(a) * 0.38)
						* CFrame.Angles(0, -a, 0)
						* CFrame.Angles(0, 0, 0.6),
					0.9,
					0.05,
					0.24,
					if i % 2 == 0 then LEAF else DARKLEAF,
					"Grass"
				)
			end
			for i, p in { { 0.22, 5.0, 0.18 }, { -0.25, 4.95, 0.1 }, { 0.0, 5.05, -0.26 } } do
				r:lump(
					CFrame.new(p[1], p[2], p[3]),
					0.4,
					0.3,
					0.4,
					if i == 2 then Color3.fromRGB(196, 186, 226) else Color3.fromRGB(240, 222, 230),
					"Fabric"
				)
			end
			r:piece(function(q: R)
				q:box(0.52, 4.62, 0.3, 0.16, 0.05, 0.16, LEAF, "Grass")
				for k, a in { 0.6, 2.3, 3.7, 5.2 } do
					local dx, dz = math.cos(a), math.sin(a)
					for j = 0, 3 do
						local rr = 0.6 + j * 0.03
						q:boxAt(
							CFrame.new(dx * rr, 4.45 - j * 0.2, dz * rr) * CFrame.Angles(0, -a + j + k, 0.5),
							0.16,
							0.04,
							0.16,
							if (j + k) % 2 == 0 then LEAF else DARKLEAF,
							"Grass"
						)
					end
				end
			end, nil, "Grass")
		end,
	},
	{
		id = "fancy_rug_medallion",
		name = "Medallion rug",
		cat = "decor",
		style = "fancy",
		price = 140,
		place = "floor",
		size = Vector3.new(8, 0.15, 5.6),
		c1 = "A8BCCB",
		c2 = "EDE3CF",
		tags = { "rug" },
		build = function(r: R)
			local deep = shade(r.c1, 0.75)
			-- layers that each sit 0.025 on the last: the edge, a pale band, the field
			r:noCollide(r:block(-4, 0, -2.8, 4, 0.025, 2.8, shade(r.c1, 0.82), "Carpet"))
			r:noCollide(r:block(-3.7, 0.025, -2.5, 3.7, 0.05, 2.5, r.c2, "Carpet"))
			r:noCollide(r:block(-3.4, 0.05, -2.2, 3.4, 0.075, 2.2, r.c1, "Carpet"))
			-- small diamonds round the band, squares at its corners
			r:piece(function(q: R)
				for _, sx in { -1, 1 } do
					for _, sz in { -1, 1 } do
						q:box(sx * 3.55, 0.0625, sz * 2.35, 0.18, 0.025, 0.18, deep, "Carpet")
					end
				end
				for i = 0, 7 do
					local x = -2.8 + i * 0.8
					for _, sz in { -1, 1 } do
						q:boxAt(
							CFrame.new(x, 0.0625, sz * 2.35) * CFrame.Angles(0, math.pi / 4, 0),
							0.18,
							0.025,
							0.18,
							deep,
							"Carpet"
						)
					end
				end
				for i = 0, 3 do
					local z = -1.2 + i * 0.8
					for _, sx in { -1, 1 } do
						q:boxAt(
							CFrame.new(sx * 3.55, 0.0625, z) * CFrame.Angles(0, math.pi / 4, 0),
							0.18,
							0.025,
							0.18,
							deep,
							"Carpet"
						)
					end
				end
			end)
			-- a line round the field, a corner piece in each corner, the medallion in the middle
			local y4 = 0.0875
			r:piece(function(q: R)
				q:block(-3.2, 0.075, -2.0, 3.2, 0.1, -1.9, deep, "Carpet")
				q:block(-3.2, 0.075, 1.9, 3.2, 0.1, 2.0, deep, "Carpet")
				q:block(-3.2, 0.075, -1.9, -3.1, 0.1, 1.9, deep, "Carpet")
				q:block(3.1, 0.075, -1.9, 3.2, 0.1, 1.9, deep, "Carpet")
			end)
			for _, sx in { -1, 1 } do
				for _, sz in { -1, 1 } do
					r:noCollide(
						r:tri(
							Vector3.new(sx * 3.0, y4, sz * 1.8),
							Vector3.new(sx * 1.9, y4, sz * 1.8),
							Vector3.new(sx * 3.0, y4, sz * 1.05),
							0.025,
							r.c2,
							"Carpet"
						)[1]
					)
				end
			end
			r:quad(
				Vector3.new(-1.7, y4, 0),
				Vector3.new(0, y4, -1.05),
				Vector3.new(1.7, y4, 0),
				Vector3.new(0, y4, 1.05),
				0.025,
				r.c2,
				"Carpet"
			)
			r:quad(
				Vector3.new(-1.05, y4 + 0.025, 0),
				Vector3.new(0, y4 + 0.025, -0.64),
				Vector3.new(1.05, y4 + 0.025, 0),
				Vector3.new(0, y4 + 0.025, 0.64),
				0.025,
				deep,
				"Carpet"
			)
			r:boxAt(CFrame.new(0, y4 + 0.05, 0) * CFrame.Angles(0, math.pi / 4, 0), 0.4, 0.025, 0.4, r.c2, "Carpet")
			for _, sx in { -1, 1 } do
				r:boxAt(
					CFrame.new(sx * 1.95, y4, 0) * CFrame.Angles(0, math.pi / 4, 0),
					0.3,
					0.025,
					0.3,
					deep,
					"Carpet"
				)
			end
			-- a fringe at both ends
			r:piece(function(q: R)
				for _, s in { -1, 1 } do
					for i = 0, 11 do
						local z = -2.6 + i * (5.2 / 11)
						q:block(s * 4.0, 0, z - 0.05, s * 4.2, 0.03, z + 0.05, C.Cream, "Fabric")
					end
				end
			end)
			for _, p in r.prims do
				p.collide = false
			end
		end,
	},

	------------------------------------------------------------------------------------------
	-- On walls
	{
		id = "fancy_mirror_gilt",
		name = "Gilded mirror",
		cat = "walldecor",
		style = "fancy",
		price = 120,
		place = "wall",
		size = Vector3.new(2.8, 4.6, 0.4),
		c1 = "C9A55E",
		c2 = "D6E4EA",
		tags = { "mirror" },
		build = function(r: R)
			-- an arch topped glass in a moulded gold frame
			r:block(-0.95, 0.5, 0.06, 0.95, 3.1, 0.12, r.c2, "Glass")
			r:cyl(0, 3.1, 0.09, 0.06, 1.9, "z", r.c2, "Glass")
			local zf = 0.11
			local frame: { Vector3 } = { Vector3.new(1.06, 0.4, zf) }
			for i = 0, 8 do
				local a = i * math.pi / 8
				table.insert(frame, Vector3.new(math.cos(a) * 1.06, 3.1 + math.sin(a) * 1.06, zf))
			end
			table.insert(frame, Vector3.new(-1.06, 0.4, zf))
			for i = 1, #frame - 1 do
				local a, b = frame[i], frame[i + 1]
				local u = (b - a).Unit * 0.11
				bar(r, a - u, b + u, 0.24, 0.2, r.c1, "Metal")
			end
			bar(r, Vector3.new(-1.17, 0.4, zf), Vector3.new(1.17, 0.4, zf), 0.24, 0.2, r.c1, "Metal")
			-- a shell crest with scrolls, leaves at the sides and a drop below
			r:lump(CFrame.new(0, 4.28, 0.13), 0.72, 0.5, 0.18, r.c1, "Metal")
			for _, sx in { -1, 1 } do
				r:ball(sx * 0.42, 4.12, 0.13, 0.24, r.c1, "Metal")
				r:lump(CFrame.new(sx * 1.24, 2.1, 0.12), 0.18, 0.7, 0.14, r.c1, "Metal")
				r:ball(sx * 1.24, 2.55, 0.12, 0.14, r.c1, "Metal")
			end
			r:lump(CFrame.new(0, 0.2, 0.12), 0.8, 0.32, 0.16, r.c1, "Metal")
			r:ball(0, 4.5, 0.13, 0.12, r.c1, "Metal")
		end,
	},
	{
		id = "fancy_portrait",
		name = "Oil portrait",
		cat = "walldecor",
		style = "fancy",
		price = 110,
		place = "wall",
		size = Vector3.new(2.6, 3.4, 0.6),
		c1 = "C9A55E",
		c2 = "56644F",
		tags = { "art" },
		build = function(r: R)
			-- the canvas in a deep gold frame with a bead inside it and rosettes at the corners
			r:block(-0.9, 0.45, 0.02, 0.9, 2.75, 0.1, r.c2, "Fabric")
			r:piece(function(q: R)
				q:block(-1.18, 0.2, 0, 1.18, 0.45, 0.17, r.c1, "Metal")
				q:block(-1.18, 2.75, 0, 1.18, 3.0, 0.17, r.c1, "Metal")
				q:block(-1.18, 0.45, 0, -0.9, 2.75, 0.17, r.c1, "Metal")
				q:block(0.9, 0.45, 0, 1.18, 2.75, 0.17, r.c1, "Metal")
			end)
			r:piece(function(q: R)
				q:block(-0.9, 0.45, 0.1, 0.9, 0.5, 0.15, shade(r.c1, 0.8), "Metal")
				q:block(-0.9, 2.7, 0.1, 0.9, 2.75, 0.15, shade(r.c1, 0.8), "Metal")
				q:block(-0.9, 0.5, 0.1, -0.85, 2.7, 0.15, shade(r.c1, 0.8), "Metal")
				q:block(0.85, 0.5, 0.1, 0.9, 2.7, 0.15, shade(r.c1, 0.8), "Metal")
			end)
			for _, sx in { -1, 1 } do
				for _, y in { 0.32, 2.87 } do
					r:ball(sx * 1.04, y, 0.17, 0.2, r.c1, "Metal")
				end
			end
			-- the sitter: shoulders in a dark coat, a white collar, a face under dark hair
			local z1, z2 = 0.115, 0.145
			r:quad(
				Vector3.new(-0.72, 0.5, z1),
				Vector3.new(0.72, 0.5, z1),
				Vector3.new(0.42, 1.36, z1),
				Vector3.new(-0.42, 1.36, z1),
				0.03,
				Color3.fromRGB(64, 70, 96),
				"Fabric"
			)
			r:block(-0.12, 1.36, 0.1, 0.12, 1.6, 0.13, Color3.fromRGB(228, 190, 160), "Fabric")
			r:cyl(0, 2.0, z1, 0.03, 0.7, "z", Color3.fromRGB(84, 62, 48), "Fabric")
			r:cyl(0, 1.86, z2, 0.03, 0.56, "z", Color3.fromRGB(232, 196, 168), "Fabric")
			r:piece(function(q: R)
				q:block(-0.15, 1.9, 0.175, -0.07, 1.96, 0.2, Color3.fromRGB(60, 46, 40), "Fabric")
				q:block(0.07, 1.9, 0.175, 0.15, 1.96, 0.2, Color3.fromRGB(60, 46, 40), "Fabric")
				q:block(-0.08, 1.7, 0.175, 0.08, 1.73, 0.2, Color3.fromRGB(176, 110, 100), "Fabric")
			end, nil, "Fabric")
			r:block(-0.22, 1.24, 0.13, 0.22, 1.4, 0.16, C.White, "Fabric")
			r:block(-0.05, 0.75, 0.13, 0.05, 1.2, 0.16, Color3.fromRGB(184, 150, 90), "Fabric")
			-- a brass picture light over the top
			rod(r, Vector3.new(0, 3.0, 0.08), Vector3.new(0, 3.22, 0.42), 0.06, GOLD, "Metal")
			r:cyl(0, 3.22, 0.44, 1.0, 0.2, "x", GOLD, "Metal")
			local tube = r:cyl(0, 3.13, 0.46, 0.9, 0.1, "x", C.Warm, "Glass")
			r:glow(tube, 6, 0.6)
		end,
	},
	{
		id = "fancy_curtains_swag",
		name = "Swag curtains",
		cat = "walldecor",
		style = "fancy",
		price = 140,
		place = "wall",
		size = Vector3.new(6.4, 7.2, 1.0),
		c1 = "C7A0A8",
		c2 = "C9A55E",
		build = function(r: R)
			local fold = shade(r.c1, 0.9)
			-- a gold pole on brackets with ball ends
			r:cyl(0, 6.95, 0.6, 5.9, 0.14, "x", r.c2, "Metal")
			for _, sx in { -1, 1 } do
				rod(r, Vector3.new(sx * 2.6, 6.95, 0), Vector3.new(sx * 2.6, 6.95, 0.6), 0.08, r.c2, "Metal")
				r:ball(sx * 3.0, 6.95, 0.6, 0.28, r.c2, "Metal")
				r:cyl(sx * 2.86, 6.95, 0.6, 0.06, 0.22, "x", r.c2, "Metal")
			end
			-- each side curtain is gathered into a tie and falls out again to the floor
			for _, sx in { -1, 1 } do
				local tie = Vector3.new(sx * 2.88, 2.8, 0)
				for i = 0, 3 do
					local z = if i % 2 == 0 then 0.44 else 0.54
					local col = if i % 2 == 0 then fold else r.c1
					local top = Vector3.new(sx * (1.85 + i * 0.36), 6.85, z)
					local mid = Vector3.new(tie.X - sx * (0.15 - i * 0.1), tie.Y, z)
					local foot = Vector3.new(sx * (2.0 + i * 0.36), 0.05, z)
					bar(r, top, mid, 0.4, 0.16, col, "Fabric")
					bar(r, mid, foot, 0.38, 0.16, col, "Fabric")
				end
				r:block(tie.X - 0.45, 2.72, 0.3, tie.X + 0.45, 2.88, 0.68, r.c2, "Fabric")
				r:add({
					shape = "Cone",
					cf = CFrame.new(sx * 2.5, 2.38, 0.66) * CFrame.Angles(math.pi, 0, 0),
					size = Vector3.new(0.2, 0.4, 0.2),
					color = r.c2,
					mat = "Fabric",
				})
				r:ball(sx * 2.5, 2.62, 0.66, 0.14, r.c2, "Fabric")
				rod(r, Vector3.new(sx * 2.65, 2.8, 0.66), Vector3.new(sx * 2.5, 2.66, 0.66), 0.04, r.c2, "Fabric")
				-- a cascade at the outer end of the valance
				r:tri(
					Vector3.new(sx * 2.55, 6.85, 0.74),
					Vector3.new(sx * 3.15, 6.85, 0.74),
					Vector3.new(sx * 3.15, 4.9, 0.74),
					0.1,
					fold,
					"Fabric"
				)
			end
			-- two swags across the top, a deeper fold under a shallow one, rosettes where they meet
			for _, x0 in { -2.6, 0 } do
				for k, s in { { 0.9, 0.45, 0.68 }, { 0.45, 0.3, 0.62 } } do
					local pts: { Vector3 } = {}
					for i = 0, 6 do
						local t = i / 6
						table.insert(pts, Vector3.new(x0 + t * 2.6, 6.62 - s[1] * math.sin(t * math.pi), s[3]))
					end
					for i = 1, #pts - 1 do
						local a, b = pts[i], pts[i + 1]
						local u = (b - a).Unit * 0.1
						bar(r, a - u, b + u, s[2], 0.18, if k == 1 then r.c1 else fold, "Fabric")
					end
				end
			end
			for _, x in { -2.6, 0, 2.6 } do
				r:cyl(x, 6.62, 0.82, 0.08, 0.38, "z", r.c2, "Metal")
			end
		end,
	},

	------------------------------------------------------------------------------------------
	-- Bathroom
	{
		id = "fancy_bath_slipper",
		name = "Slipper bath",
		cat = "bath",
		style = "fancy",
		price = 420,
		place = "floor",
		size = Vector3.new(3.4, 3.5, 6.4),
		c1 = "C08C6E",
		c2 = "F4F1EA",
		tags = { "bath" },
		build = function(r: R)
			local rim = shade(r.c1, 1.1)
			-- a walnut plinth with rounded ends
			r:block(-1.3, 0, -1.6, 1.3, 0.32, 1.6, WALNUT, "Wood")
			for _, sz in { -1, 1 } do
				r:cyl(0, 0.16, sz * 1.6, 0.32, 2.6, "y", WALNUT, "Wood")
			end
			-- the copper tub, round at both ends, its bottom eased in
			r:block(-1.4, 0.55, -1.6, 1.4, 2.0, 1.6, r.c1, "Metal")
			for _, sz in { -1, 1 } do
				r:cyl(0, 1.275, sz * 1.6, 1.45, 2.8, "y", r.c1, "Metal")
			end
			r:lump(CFrame.new(0, 0.6, 0), 2.6, 0.6, 5.6, r.c1, "Metal")
			-- enamel inside, water, and a rolled rim
			r:block(-1.22, 1.96, -1.6, 1.22, 2.03, 1.6, r.c2, "Marble")
			for _, sz in { -1, 1 } do
				r:cyl(0, 1.995, sz * 1.6, 0.07, 2.44, "y", r.c2, "Marble")
			end
			local water = r:block(-1.15, 2.0, -1.5, 1.15, 2.07, 1.5, C.Water, "Glass")
			water.transp = 0.35
			local ring: { Vector3 } = {}
			for i = 0, 6 do
				local a = i * math.pi / 6
				table.insert(ring, Vector3.new(math.cos(a) * 1.4, 2.02, 1.6 + math.sin(a) * 1.4))
			end
			path(r, ring, 0.18, rim, "Metal")
			for _, sx in { -1, 1 } do
				rod(r, Vector3.new(sx * 1.4, 2.02, -1.6), Vector3.new(sx * 1.4, 2.02, 1.6), 0.18, rim, "Metal")
			end
			-- the high slipper end at the back, enamel inside, rolled along its top
			local back: { Vector3 } = {}
			for i = 0, 6 do
				local a = math.pi + i * math.pi / 6
				local dx, dz = math.cos(a), math.sin(a)
				local h = 0.5 + 0.55 * math.sin(i * math.pi / 6)
				local base = Vector3.new(dx * 1.33, 2.0, -1.6 + dz * 1.33)
				local top = Vector3.new(dx * 1.42, 2.0 + h, -1.6 + dz * 1.42)
				table.insert(back, top)
				if i < 6 then
					local a2 = math.pi + (i + 1) * math.pi / 6
					local h2 = 0.5 + 0.55 * math.sin((i + 1) * math.pi / 6)
					local base2 = Vector3.new(math.cos(a2) * 1.33, 2.0, -1.6 + math.sin(a2) * 1.33)
					local top2 = Vector3.new(math.cos(a2) * 1.42, 2.0 + h2, -1.6 + math.sin(a2) * 1.42)
					r:quad(base, base2, top2, top, 0.14, r.c1, "Metal")
					local inB = Vector3.new(base.X * 0.9, base.Y, -1.6 + (base.Z + 1.6) * 0.9)
					local inB2 = Vector3.new(base2.X * 0.9, base2.Y, -1.6 + (base2.Z + 1.6) * 0.9)
					local inT = Vector3.new(top.X * 0.91, top.Y - 0.08, -1.6 + (top.Z + 1.6) * 0.91)
					local inT2 = Vector3.new(top2.X * 0.91, top2.Y - 0.08, -1.6 + (top2.Z + 1.6) * 0.91)
					r:quad(inB, inB2, inT2, inT, 0.05, r.c2, "Marble")
				end
			end
			path(r, back, 0.18, rim, "Metal")
			-- a gooseneck tap standing at the foot, with two cross handles
			path(r, {
				Vector3.new(0, 0, 3.08),
				Vector3.new(0, 2.55, 3.08),
				Vector3.new(0, 2.85, 2.9),
				Vector3.new(0, 2.7, 2.62),
				Vector3.new(0, 2.45, 2.56),
			}, 0.12, C.Gold, "Metal")
			r:cyl(0, 0.04, 3.08, 0.08, 0.36, "y", C.Gold, "Metal")
			for _, sx in { -1, 1 } do
				rod(r, Vector3.new(0, 1.9, 3.08), Vector3.new(sx * 0.3, 1.9, 3.08), 0.07, C.Gold, "Metal")
				r:box(sx * 0.3, 1.9, 3.08, 0.05, 0.05, 0.26, C.Gold, "Metal")
			end
			-- a wooden rack across the tub with a candle, soap and a sponge
			r:block(-1.6, 2.13, 0.1, 1.6, 2.19, 0.62, WALNUT, "Wood")
			r:cyl(-0.7, 2.31, 0.36, 0.24, 0.2, "y", IVORY, "Marble")
			local flame = r:ball(-0.7, 2.48, 0.36, 0.08, C.Warm, "Glass")
			r:glow(flame, 6, 0.6)
			r:block(0.0, 2.19, 0.22, 0.34, 2.29, 0.46, Color3.fromRGB(226, 210, 232), "Marble")
			r:block(0.6, 2.19, 0.18, 1.0, 2.36, 0.5, Color3.fromRGB(240, 214, 150), "Foil")
		end,
	},
	{
		id = "fancy_washstand",
		name = "Marble washstand",
		cat = "bath",
		style = "fancy",
		price = 260,
		place = "floor",
		size = Vector3.new(3.0, 4.8, 1.8),
		c1 = "ECE6DE",
		c2 = "C9A55E",
		tags = { "bath" },
		build = function(r: R)
			-- two gold legs in front with a towel bar between, a marble shelf low down
			for _, sx in { -1, 1 } do
				path(r, {
					Vector3.new(sx * 1.2, 2.75, 0.55),
					Vector3.new(sx * 1.3, 1.6, 0.66),
					Vector3.new(sx * 1.18, 0.12, 0.6),
				}, 0.14, r.c2, "Metal")
				r:cyl(sx * 1.18, 0.05, 0.6, 0.1, 0.26, "y", r.c2, "Metal")
				r:block(sx * 1.25 - 0.08, 0.9, -0.85, sx * 1.25 + 0.08, 2.75, -0.72, r.c2, "Metal")
			end
			r:block(-1.3, 0.55, -0.85, 1.3, 0.65, 0.55, r.c1, "Marble")
			rod(r, Vector3.new(-1.26, 1.9, 0.66), Vector3.new(1.26, 1.9, 0.66), 0.08, r.c2, "Metal")
			-- a towel over the bar and a folded one on the shelf
			local towel = Color3.fromRGB(236, 226, 218)
			r:block(-0.6, 1.3, 0.58, 0.6, 1.98, 0.74, towel, "Fabric")
			r:block(-0.6, 1.42, 0.74, 0.6, 1.48, 0.77, shade(towel, 0.9), "Fabric")
			r:block(-0.5, 0.65, -0.45, 0.5, 0.9, 0.25, towel, "Fabric")
			r:block(-0.53, 0.72, -0.48, 0.53, 0.78, 0.28, Color3.fromRGB(198, 176, 196), "Fabric")
			-- the marble top, a splashback, and a round basin standing on it
			r:block(-1.45, 2.75, -0.88, 1.45, 2.95, 0.78, r.c1, "Marble")
			r:block(-1.45, 2.95, -0.88, 1.45, 3.8, -0.74, r.c1, "Marble")
			r:cyl(0, 3.85, -0.81, 2.9, 0.14, "x", shade(r.c1, 0.95), "Marble")
			r:cyl(0.1, 3.03, -0.02, 0.16, 0.5, "y", C.White, "Marble")
			r:lump(CFrame.new(0.1, 3.25, -0.02), 1.3, 0.5, 1.1, C.White, "Marble")
			r:cyl(0.1, 3.5, -0.02, 0.06, 1.24, "y", shade(C.White, 0.95), "Marble")
			r:cyl(0.1, 3.56, -0.02, 0.03, 0.96, "y", Color3.fromRGB(196, 222, 232), "Glass")
			-- a swan neck tap with two handles
			path(r, {
				Vector3.new(0.1, 2.95, -0.62),
				Vector3.new(0.1, 3.95, -0.62),
				Vector3.new(0.1, 4.12, -0.42),
				Vector3.new(0.1, 3.9, -0.24),
			}, 0.09, r.c2, "Metal")
			for _, sx in { -1, 1 } do
				r:cyl(0.1 + sx * 0.42, 3.05, -0.6, 0.2, 0.12, "y", r.c2, "Metal")
				r:ball(0.1 + sx * 0.42, 3.2, -0.6, 0.16, C.White, "Marble")
			end
			-- a soap dish and a jug
			r:cyl(-1.0, 2.98, 0.3, 0.06, 0.4, "y", r.c2, "Metal")
			r:block(-1.12, 3.01, 0.22, -0.88, 3.09, 0.38, Color3.fromRGB(226, 210, 232), "Marble")
			r:cyl(1.05, 3.2, 0.25, 0.5, 0.36, "y", Color3.fromRGB(170, 196, 214), "Glass")
			r:cyl(1.05, 3.48, 0.25, 0.1, 0.42, "y", Color3.fromRGB(170, 196, 214), "Glass")
		end,
	},

	------------------------------------------------------------------------------------------
	-- Kitchen
	{
		id = "fancy_range",
		name = "Range cooker",
		gives = "cook", -- holding E gives something (Data/Items.Sources)
		cat = "kitchen",
		style = "fancy",
		price = 480,
		place = "floor",
		size = Vector3.new(4.0, 4.0, 2.6),
		c1 = "9DB39B",
		c2 = "C9A55E",
		tags = { "kitchen" },
		surface = 3.15,
		build = function(r: R)
			local dk = shade(r.c1, 0.85)
			-- the body on a dark plinth
			r:block(-1.85, 0, -1.1, 1.85, 0.25, 0.9, C.Black, "Metal")
			r:block(-1.95, 0.25, -1.2, 1.95, 3.1, 1.0, r.c1, "Metal")
			-- two oven doors with windows and long bar handles
			for _, sx in { -1, 1 } do
				local x1, x2 = sx * 0.06, sx * 1.85
				local xa, xb = math.min(x1, x2), math.max(x1, x2)
				r:block(xa, 0.4, 1.0, xb, 2.2, 1.04, shade(r.c1, 1.06), "Metal")
				r:block(xa + 0.3, 0.75, 1.04, xb - 0.3, 1.75, 1.07, Color3.fromRGB(52, 48, 54), "Glass")
				r:block(xa + 0.24, 0.69, 1.04, xb - 0.24, 0.75, 1.07, r.c2, "Metal")
				rod(r, Vector3.new(xa + 0.25, 2.0, 1.22), Vector3.new(xb - 0.25, 2.0, 1.22), 0.08, r.c2, "Metal")
				for _, x in { xa + 0.3, xb - 0.3 } do
					rod(r, Vector3.new(x, 2.0, 1.04), Vector3.new(x, 2.0, 1.22), 0.06, r.c2, "Metal")
				end
			end
			-- a row of brass knobs on a dark band
			r:block(-1.85, 2.35, 1.0, 1.85, 2.85, 1.04, dk, "Metal")
			for i = 0, 5 do
				local x = -1.5 + i * 0.6
				r:cyl(x, 2.6, 1.1, 0.12, 0.24, "z", r.c2, "Metal")
				r:block(x - 0.02, 2.64, 1.16, x + 0.02, 2.72, 1.18, dk, "Metal")
			end
			-- a towel rail across the front
			rod(r, Vector3.new(-1.9, 2.95, 1.25), Vector3.new(1.9, 2.95, 1.25), 0.1, r.c2, "Metal")
			for _, sx in { -1, 1 } do
				rod(r, Vector3.new(sx * 1.8, 2.95, 1.0), Vector3.new(sx * 1.8, 2.95, 1.25), 0.08, r.c2, "Metal")
			end
			r:block(0.6, 2.4, 1.17, 1.1, 3.03, 1.33, Color3.fromRGB(236, 226, 218), "Fabric")
			-- the hob: a black top with five burners and grates
			r:block(-1.95, 3.1, -1.2, 1.95, 3.15, 1.0, C.Black, "Metal")
			for _, p in { { -1.3, 0.4 }, { -1.3, -0.6 }, { 0, -0.1 }, { 1.3, 0.4 }, { 1.3, -0.6 } } do
				r:cyl(p[1], 3.17, p[2], 0.04, 0.5, "y", C.DarkMetal, "Metal")
				r:cyl(p[1], 3.2, p[2], 0.04, 0.22, "y", r.c2, "Metal")
				r:piece(function(q: R)
					q:block(p[1] - 0.36, 3.15, p[2] - 0.03, p[1] + 0.36, 3.23, p[2] + 0.03, C.DarkMetal, "Metal")
					q:block(p[1] - 0.03, 3.15, p[2] - 0.36, p[1] + 0.03, 3.23, p[2] + 0.36, C.DarkMetal, "Metal")
				end)
			end
			-- a backguard with a brass edge and a little shelf
			r:block(-1.95, 3.15, -1.2, 1.95, 3.8, -1.05, r.c1, "Metal")
			r:block(-1.95, 3.8, -1.25, 1.95, 3.88, -0.8, r.c2, "Metal")
			r:block(-1.8, 3.45, -1.05, 1.8, 3.5, -1.0, r.c2, "Metal")
			-- a copper pan on the back burner
			r:cyl(-1.3, 3.38, -0.6, 0.3, 0.7, "y", Color3.fromRGB(196, 140, 108), "Metal")
			rod(r, Vector3.new(-1.65, 3.45, -0.6), Vector3.new(-2.0, 3.5, -0.6), 0.06, C.DarkMetal, "Metal")
		end,
	},

	------------------------------------------------------------------------------------------
	-- Garden
	{
		id = "fancy_topiary",
		name = "Topiary planter",
		cat = "garden",
		style = "fancy",
		price = 120,
		place = "ground",
		size = Vector3.new(2.2, 5.6, 2.2),
		c1 = "EDE6DA",
		c2 = "6E8A5E",
		tags = { "plant" },
		build = function(r: R)
			local dk = shade(r.c1, 0.9)
			-- a square planter box with corner posts, ball finials and panelled sides
			r:block(-0.85, 0.2, -0.85, 0.85, 1.6, 0.85, r.c1, "Wood")
			for _, sx in { -1, 1 } do
				for _, sz in { -1, 1 } do
					r:block(sx * 1.0 - 0.15, 0, sz * 1.0 - 0.15, sx * 1.0 + 0.15, 1.75, sz * 1.0 + 0.15, r.c1, "Wood")
					r:ball(sx * 1.0, 1.9, sz * 1.0, 0.3, r.c1, "Wood")
				end
			end
			r:piece(function(q: R)
				q:block(-0.62, 0.45, 0.85, 0.62, 1.35, 0.89, dk, "Wood")
				q:block(-0.62, 0.45, -0.89, 0.62, 1.35, -0.85, dk, "Wood")
				q:block(0.85, 0.45, -0.62, 0.89, 1.35, 0.62, dk, "Wood")
				q:block(-0.89, 0.45, -0.62, -0.85, 1.35, 0.62, dk, "Wood")
			end)
			r:block(-0.95, 1.6, -0.95, 0.95, 1.7, 0.95, r.c1, "Wood")
			r:block(-0.82, 1.7, -0.82, 0.82, 1.73, 0.82, C.Soil, "Sand")
			-- a clipped tree: a trunk through two balls of leaves
			r:cyl(0, 3.0, 0, 2.6, 0.16, "y", C.Bark, "Wood")
			r:lump(CFrame.new(0, 2.55, 0), 1.05, 0.95, 1.05, shade(r.c2, 0.92), "Grass")
			r:lump(CFrame.new(0, 4.4, 0), 1.75, 1.65, 1.75, r.c2, "Grass")
			r:lump(CFrame.new(0, 4.45, 0) * CFrame.Angles(0, math.pi / 8, 0), 1.7, 1.6, 1.7, shade(r.c2, 1.06), "Grass")
		end,
	},
}

return items
