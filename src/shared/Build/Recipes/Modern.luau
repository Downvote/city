--!strict
-- Modern pieces: clean lines in light oak, white and grey, with one soft teal on small things (a
-- pillow, a vase, a shape in a print). Each carries style = "modern" so Build mode can list them
-- together, and sits in the category of what it is.
-- c1 is the main colour (fabric, a body or a top), c2 the second one (oak, legs or a frame).

local Recipe = require(script.Parent.Parent.Recipe)
local Colors = require(script.Parent.Parent.Parent.Util.Colors)

local C = Recipe.Colors

type R = Recipe.Recipe

local OAK = Color3.fromRGB(214, 184, 140)
local WHITE = Color3.fromRGB(240, 238, 233)
local GREY = Color3.fromRGB(150, 152, 158)
local CHAR = Color3.fromRGB(62, 62, 68) -- powder coated black metal
local TEAL = Color3.fromRGB(92, 146, 142) -- the one accent
local STONE = Color3.fromRGB(228, 226, 220)
local STEEL = Color3.fromRGB(186, 189, 194)
local MIRROR = Color3.fromRGB(205, 225, 234)

-- spines for books, soft and dusty
local BOOKS = {
	Color3.fromRGB(118, 138, 150),
	Color3.fromRGB(206, 182, 140),
	Color3.fromRGB(160, 104, 96),
	Color3.fromRGB(232, 226, 214),
	Color3.fromRGB(96, 112, 106),
	Color3.fromRGB(176, 158, 172),
	Color3.fromRGB(88, 90, 98),
}

local function shade(c: Color3, k: number): Color3
	return Colors.shade(c, k)
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
		mat = mat or "SmoothPlastic",
	})
end

-- A row of books standing upright from x1 toward x2 on a shelf at height y, their spines facing
-- +Z with the middle of their depth at z. `seed` varies the widths, heights and colours.
local function bookRow(r: R, x1: number, x2: number, y: number, z: number, depth: number, seed: number)
	r:piece(function(q: R)
		local x = x1
		local i = seed
		while true do
			local w = 0.1 + ((i * 37) % 5) * 0.025
			if x + w > x2 then
				break
			end
			local h = 0.52 + ((i * 53) % 7) * 0.05
			local col = BOOKS[(i % #BOOKS) + 1]
			q:block(x, y, z - depth / 2, x + w, y + h, z + depth / 2, col, "SmoothPlastic")
			x += w + 0.012
			i += 1
		end
	end)
end

-- Books lying in a pile at (x, y, z), `n` of them, each a little turned.
local function bookPile(r: R, x: number, y: number, z: number, n: number, seed: number)
	local top = y
	for k = 1, n do
		local i = seed + k
		local w = 0.62 + ((i * 29) % 4) * 0.05
		local d = 0.46 + ((i * 17) % 3) * 0.04
		local t = 0.08 + ((i * 13) % 3) * 0.02
		r:boxAt(
			CFrame.new(x, top + t / 2, z) * CFrame.Angles(0, ((i * 41) % 7 - 3) * 0.05, 0),
			w,
			t,
			d,
			BOOKS[(i % #BOOKS) + 1],
			"SmoothPlastic"
		)
		top += t
	end
	return top
end

-- A small potted plant: a white pot, soil, and a few leafy lumps, its foot at (x, y, z).
local function pottedPlant(r: R, x: number, y: number, z: number, s: number, potColor: Color3?)
	local pot = potColor or WHITE
	r:cyl(x, y + 0.03 * s, z, 0.06 * s, 0.34 * s, "y", shade(pot, 0.8), "SmoothPlastic")
	r:cyl(x, y + 0.24 * s, z, 0.36 * s, 0.44 * s, "y", pot, "SmoothPlastic")
	r:cyl(x, y + 0.43 * s, z, 0.04 * s, 0.38 * s, "y", C.Soil, "Sand")
	r:lump(CFrame.new(x, y + 0.6 * s, z) * CFrame.Angles(0.3, 0.6, 0.2), 0.5 * s, 0.36 * s, 0.44 * s, C.Leaf, "Grass")
	r:lump(
		CFrame.new(x + 0.12 * s, y + 0.75 * s, z - 0.06 * s) * CFrame.Angles(0.6, 0.1, 0.5),
		0.32 * s,
		0.3 * s,
		0.3 * s,
		C.DarkLeaf,
		"Grass"
	)
	r:lump(
		CFrame.new(x - 0.14 * s, y + 0.68 * s, z + 0.08 * s) * CFrame.Angles(-0.4, 0.9, 0.1),
		0.3 * s,
		0.24 * s,
		0.28 * s,
		shade(C.Leaf, 1.08),
		"Grass"
	)
end

-- A point along a cubic curve through p0..p3 (t from 0 to 1).
local function bezier(p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, t: number): Vector3
	local u = 1 - t
	return p0 * (u * u * u) + p1 * (3 * u * u * t) + p2 * (3 * u * t * t) + p3 * (t * t * t)
end

-- A flat round plate that reads as round: four squares turned by a sixteenth of a turn each make a
-- sixteen sided disc (a cylinder this small would be the kit's eight sided prism). With axis "z"
-- it stands across x and y round (cx, cy), z1 to z2 deep; with axis "y" it lies across x and z
-- round (cx, cy as z), z1 to z2 high.
local function roundPlate(
	r: R,
	cx: number,
	cy: number,
	z1: number,
	z2: number,
	d: number,
	axis: string,
	color: Color3,
	mat: string
)
	r:piece(function(q: R)
		for k = 0, 3 do
			local a = k * math.pi / 8
			if axis == "z" then
				q:boxAt(CFrame.new(cx, cy, (z1 + z2) / 2) * CFrame.Angles(0, 0, a), d, d, z2 - z1, color, mat)
			else
				q:boxAt(CFrame.new(cx, (z1 + z2) / 2, cy) * CFrame.Angles(0, a, 0), d, z2 - z1, d, color, mat)
			end
		end
	end)
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
}

local items: { Item } = {
	---------------------------------------------------------------------------------------------
	-- Seating
	{
		id = "modern_sofa",
		name = "Low sofa",
		cat = "seating",
		style = "modern",
		price = 300,
		place = "floor",
		size = Vector3.new(7.2, 2.7, 3.2),
		c1 = "A9ABAE",
		c2 = "D6B88C",
		tags = { "seat" },
		build = function(r: R)
			local frame = shade(r.c1, 0.88)
			local legH = 0.4
			-- slim tapered oak legs, splayed out a touch
			for _, x in { -3.3, 0, 3.3 } do
				for _, z in { -1.3, 1.2 } do
					local sx = if x < 0 then -1 elseif x > 0 then 1 else 0
					local sz = if z < 0 then -1 else 1
					rod(
						r,
						Vector3.new(x, legH + 0.02, z),
						Vector3.new(x + sx * 0.06, 0, z + sz * 0.06),
						0.16,
						r.c2,
						"Wood"
					)
				end
			end
			-- a square box frame: the base between the arms, the back and two block arms
			r:block(-3.0, legH, -1.6, 3.0, 0.95, 1.45, frame, "Fabric")
			r:block(-3.0, legH, -1.6, 3.0, 2.2, -1.05, frame, "Fabric")
			for _, sx in { -1, 1 } do
				r:block(
					math.min(sx * 3.0, sx * 3.6),
					legH,
					-1.6,
					math.max(sx * 3.0, sx * 3.6),
					1.95,
					1.55,
					frame,
					"Fabric"
				)
				-- a stitched seam along the top of each arm
				r:block(sx * 3.3 - 0.02, 1.95, -1.5, sx * 3.3 + 0.02, 1.98, 1.45, shade(r.c1, 0.72), "Fabric")
			end
			-- three square seat cushions with a piped edge, and three back cushions leaning on the back
			for i = 1, 3 do
				local x1 = -3.0 + (i - 1) * 2.0 + 0.03
				local x2 = x1 + 1.94
				local xm = (x1 + x2) / 2
				r:block(x1, 0.95, -1.05, x2, 1.55, 1.55, r.c1, "Fabric")
				r:block(x1 - 0.03, 1.22, -1.03, x2 + 0.03, 1.28, 1.59, shade(r.c1, 0.78), "Fabric")
				local back = CFrame.new(xm, 1.55, -0.8) * CFrame.Angles(-0.14, 0, 0)
				r:boxAt(back * CFrame.new(0, 0.58, 0), 1.94, 1.16, 0.5, r.c1, "Fabric")
				r:boxAt(back * CFrame.new(0, 0.58, 0), 2.02, 0.06, 0.58, shade(r.c1, 0.78), "Fabric")
				r:seat(xm, 1.55, 0.35)
			end
			-- one pillow in the accent, one striped, and a throw over the right arm
			r:boxAt(CFrame.new(-2.35, 1.98, -0.45) * CFrame.Angles(-0.25, 0, -0.12), 1.05, 1.05, 0.3, TEAL, "Fabric")
			local striped = CFrame.new(2.35, 1.98, -0.45) * CFrame.Angles(-0.25, 0, 0.12)
			r:boxAt(striped, 1.05, 1.05, 0.3, WHITE, "Fabric")
			for _, y in { -0.3, 0, 0.3 } do
				r:boxAt(striped * CFrame.new(0, y, 0), 1.13, 0.1, 0.38, GREY, "Fabric")
			end
			local oat = Color3.fromRGB(222, 210, 186)
			r:block(3.05, 1.95, -0.25, 3.6, 2.04, 0.65, oat, "Fabric")
			r:block(3.6, 0.95, -0.25, 3.65, 2.04, 0.65, oat, "Fabric")
			r:piece(function(q: R)
				for k = 0, 8 do
					local z = -0.22 + k * 0.105
					q:block(3.6, 0.82, z, 3.64, 0.95, z + 0.04, shade(oat, 0.9), "Fabric")
				end
			end)
		end,
	},
	{
		id = "modern_shell_chair",
		name = "Shell chair",
		cat = "seating",
		style = "modern",
		price = 120,
		place = "floor",
		size = Vector3.new(2.4, 3.0, 2.4),
		c1 = "E9E4DA",
		c2 = "D6B88C",
		tags = { "seat" },
		build = function(r: R)
			-- four splayed oak legs, braced with crossed wires on every side
			local function onLeg(sx: number, sz: number, y: number): Vector3
				local top = Vector3.new(sx * 0.55, 1.42, sz * 0.5)
				local bot = Vector3.new(sx * 0.86, 0, sz * 0.8)
				return bot + (top - bot) * (y / 1.42)
			end
			for _, sx in { -1, 1 } do
				for _, sz in { -1, 1 } do
					rod(r, onLeg(sx, sz, 0), onLeg(sx, sz, 1.42), 0.14, r.c2, "Wood")
				end
			end
			local sides = {
				{ { -1, 1 }, { 1, 1 } },
				{ { -1, -1 }, { 1, -1 } },
				{ { -1, -1 }, { -1, 1 } },
				{ { 1, -1 }, { 1, 1 } },
			}
			for _, s in sides do
				local a, b = s[1], s[2]
				rod(r, onLeg(a[1], a[2], 1.1), onLeg(b[1], b[2], 0.5), 0.05, CHAR, "Metal")
				rod(r, onLeg(b[1], b[2], 1.1), onLeg(a[1], a[2], 0.5), 0.05, CHAR, "Metal")
			end
			r:block(-0.62, 1.42, -0.56, 0.62, 1.5, 0.56, CHAR, "Metal")
			-- the moulded seat, with a rolled front lip
			r:boxAt(CFrame.new(0, 1.57, 0.1) * CFrame.Angles(-0.06, 0, 0), 1.9, 0.12, 1.8, r.c1, "SmoothPlastic")
			r:cyl(0, 1.62, 1.0, 1.9, 0.16, "x", r.c1, "SmoothPlastic")
			-- the shell: a curved back falling away into low arms, its top a smooth line
			local A, N, cz = 1.75, 8, 0.05
			local function rim(k: number): (Vector3, Vector3)
				local a = -A + k * (2 * A / N)
				local h = 0.55 + 0.75 * math.cos(a * math.pi / (2 * A)) ^ 2
				local bot = Vector3.new(math.sin(a) * 0.92, 1.5, cz - math.cos(a) * 0.92)
				local top = Vector3.new(math.sin(a) * 1.02, 1.5 + h, cz - math.cos(a) * 1.02)
				return bot, top
			end
			for k = 0, N - 1 do
				local b1, t1 = rim(k)
				local b2, t2 = rim(k + 1)
				r:quad(b1, b2, t2, t1, 0.12, r.c1, "SmoothPlastic")
			end
			for _, k in { 0, N } do
				local b, t = rim(k)
				rod(r, b, t, 0.12, r.c1, "SmoothPlastic")
			end
			-- a slim pad on the seat
			local pad = Color3.fromRGB(176, 174, 170)
			r:block(-0.78, 1.64, -0.5, 0.78, 1.76, 0.82, pad, "Fabric")
			r:cyl(0, 1.7, 0.82, 1.56, 0.12, "x", pad, "Fabric")
			r:seat(0, 1.76, 0.15)
		end,
	},
	{
		id = "modern_stool",
		name = "Counter stool",
		cat = "seating",
		style = "modern",
		price = 70,
		place = "floor",
		size = Vector3.new(1.6, 3.4, 1.6),
		c1 = "D6B88C",
		c2 = "3E3E44",
		tags = { "seat" },
		build = function(r: R)
			-- a heavy round foot, a column with its lift sleeve, a foot ring on three spokes
			r:cyl(0, 0.05, 0, 0.1, 1.3, "y", r.c2, "Metal")
			r:cyl(0, 0.13, 0, 0.06, 0.6, "y", shade(r.c2, 1.25), "Metal")
			r:cyl(0, 1.23, 0, 2.2, 0.16, "y", STEEL, "Metal")
			r:cyl(0, 1.95, 0, 0.7, 0.26, "y", r.c2, "Metal")
			local n = 8
			for i = 0, n - 1 do
				local a1, a2 = i * 2 * math.pi / n, (i + 1) * 2 * math.pi / n
				rod(
					r,
					Vector3.new(math.cos(a1) * 0.52, 1.0, math.sin(a1) * 0.52),
					Vector3.new(math.cos(a2) * 0.52, 1.0, math.sin(a2) * 0.52),
					0.07,
					r.c2,
					"Metal"
				)
			end
			for i = 0, 2 do
				local a = i * 2 * math.pi / 3 + math.pi / 2
				rod(
					r,
					Vector3.new(0, 1.0, 0),
					Vector3.new(math.cos(a) * 0.5, 1.0, math.sin(a) * 0.5),
					0.05,
					r.c2,
					"Metal"
				)
			end
			-- an oak seat with a leather pad, and a low curved back on two posts
			r:cyl(0, 2.36, 0, 0.12, 0.5, "y", r.c2, "Metal")
			r:cyl(0, 2.5, 0, 0.16, 1.4, "y", r.c1, "Wood")
			r:cyl(0, 2.62, 0, 0.08, 1.2, "y", Color3.fromRGB(96, 92, 90), "Fabric")
			for _, sx in { -1, 1 } do
				rod(r, Vector3.new(sx * 0.34, 2.55, -0.5), Vector3.new(sx * 0.38, 3.05, -0.6), 0.06, r.c2, "Metal")
			end
			for i = -1, 1 do
				r:boxAt(
					CFrame.new(i * 0.36, 3.12, -0.62 + math.abs(i) * 0.1) * CFrame.Angles(-0.1, -i * 0.45, 0),
					0.42,
					0.26,
					0.08,
					r.c1,
					"Wood"
				)
			end
			r:seat(0, 2.66, 0)
		end,
	},

	---------------------------------------------------------------------------------------------
	-- Tables
	{
		id = "modern_coffee_table",
		name = "Glass coffee table",
		cat = "tables",
		style = "modern",
		price = 110,
		place = "floor",
		size = Vector3.new(4.4, 1.5, 2.6),
		surface = 1.5,
		c1 = "D6B88C",
		c2 = "EDEBE6",
		tags = { "table" },
		build = function(r: R)
			-- an oak frame of square legs and rails, a white shelf low down, a glass top
			for _, sx in { -1, 1 } do
				for _, sz in { -1, 1 } do
					r:block(sx * 2.0 - 0.09, 0, sz * 1.1 - 0.09, sx * 2.0 + 0.09, 1.38, sz * 1.1 + 0.09, r.c1, "Wood")
				end
				r:block(-1.91, 1.2, sx * 1.1 - 0.07, 1.91, 1.38, sx * 1.1 + 0.07, r.c1, "Wood")
				r:block(sx * 2.0 - 0.07, 1.2, -1.01, sx * 2.0 + 0.07, 1.38, 1.01, r.c1, "Wood")
			end
			r:block(-1.91, 0.3, -1.01, 1.91, 0.4, 1.01, r.c2, "Wood")
			r:glass(-2.2, 1.38, -1.3, 2.2, 1.5, 1.3)
			-- magazines and two big books on the shelf
			for k = 0, 2 do
				r:boxAt(
					CFrame.new(-1.0 + k * 0.05, 0.42 + k * 0.03, 0.1) * CFrame.Angles(0, (k - 1) * 0.18, 0),
					1.0,
					0.03,
					1.3,
					BOOKS[k + 2],
					"SmoothPlastic"
				)
			end
			bookPile(r, 0.9, 0.4, -0.2, 2, 3)
			-- on the glass a teal bowl of lemons, and a book with a candle on it
			r:cyl(0.95, 1.56, 0.25, 0.12, 0.5, "y", shade(TEAL, 0.85), "SmoothPlastic")
			r:cyl(0.95, 1.69, 0.25, 0.14, 0.8, "y", TEAL, "SmoothPlastic")
			for _, p in { { 0.82, 0.18 }, { 1.08, 0.3 }, { 0.95, 0.1 } } do
				r:ball(p[1], 1.86, p[2] + 0.1, 0.24, C.Yellow, "SmoothPlastic")
			end
			local top = bookPile(r, -1.2, 1.5, -0.4, 1, 6)
			r:cyl(-1.2, top + 0.15, -0.4, 0.3, 0.3, "y", WHITE, "SmoothPlastic")
			r:cyl(-1.2, top + 0.34, -0.4, 0.08, 0.03, "y", C.Black, "SmoothPlastic")
		end,
	},
	{
		id = "modern_dining_table",
		name = "Slab table",
		cat = "tables",
		style = "modern",
		price = 180,
		place = "floor",
		size = Vector3.new(6.4, 3.1, 3.4),
		surface = 3.1,
		c1 = "D6B88C",
		c2 = "EDEBE6",
		tags = { "table" },
		build = function(r: R)
			-- a thick oak top over a shadow rail, on two white sled frames joined by a rail
			r:block(-3.2, 2.94, -1.7, 3.2, 3.1, 1.7, r.c1, "Wood")
			r:block(-2.9, 2.84, -1.45, 2.9, 2.94, 1.45, shade(r.c1, 0.7), "Wood")
			for _, sx in { -1, 1 } do
				local x = sx * 2.3
				r:piece(function(q: R)
					q:block(x - 0.08, 2.68, -1.3, x + 0.08, 2.84, 1.3, r.c2, "Metal")
					q:block(x - 0.08, 0.04, -1.3, x + 0.08, 0.2, 1.3, r.c2, "Metal")
					for _, sz in { -1, 1 } do
						q:block(x - 0.08, 0.2, sz * 1.22 - 0.08, x + 0.08, 2.68, sz * 1.22 + 0.08, r.c2, "Metal")
					end
				end, true)
				for _, sz in { -1, 1 } do
					r:block(x - 0.07, 0, sz * 1.2 - 0.07, x + 0.07, 0.04, sz * 1.2 + 0.07, CHAR, "Rubber")
				end
			end
			r:block(-2.22, 2.6, -0.06, 2.22, 2.76, 0.06, r.c2, "Metal")
			-- a linen runner down the middle and a low oak bowl of pears on it
			local linen = Color3.fromRGB(222, 214, 198)
			r:block(-2.4, 3.1, -0.55, 2.4, 3.13, 0.55, linen, "Fabric")
			r:piece(function(q: R)
				for k = 0, 11 do
					local z = -0.53 + k * 0.095
					for _, sx in { -1, 1 } do
						local xa, xb = sx * 2.4, sx * 2.52
						q:block(
							math.min(xa, xb),
							3.1,
							z,
							math.max(xa, xb),
							3.12,
							z + 0.035,
							shade(linen, 0.92),
							"Fabric"
						)
					end
				end
			end)
			r:cyl(0.6, 3.17, 0, 0.08, 0.7, "y", shade(OAK, 0.7), "Wood")
			r:cyl(0.6, 3.27, 0, 0.12, 1.1, "y", shade(OAK, 0.85), "Wood")
			for _, p in { { 0.4, -0.1 }, { 0.75, 0.12 }, { 0.62, -0.2 } } do
				r:lump(
					CFrame.new(p[1], 3.46, p[2]) * CFrame.Angles(0.2, p[1], 0.1),
					0.26,
					0.32,
					0.26,
					Color3.fromRGB(196, 190, 110),
					"SmoothPlastic"
				)
			end
		end,
	},
	{
		id = "modern_nest_tables",
		name = "Nest of tables",
		cat = "tables",
		style = "modern",
		price = 90,
		place = "floor",
		size = Vector3.new(2.4, 2.0, 2.2),
		surface = 2.0,
		c1 = "EDEBE6",
		c2 = "D6B88C",
		tags = { "table" },
		build = function(r: R)
			-- the big table: a white top on a thin black frame
			r:block(-1.15, 1.9, -0.95, 1.15, 2.0, 0.95, r.c1, "SmoothPlastic")
			for _, sx in { -1, 1 } do
				for _, sz in { -1, 1 } do
					rod(
						r,
						Vector3.new(sx * 1.0, 1.86, sz * 0.8),
						Vector3.new(sx * 1.05, 0, sz * 0.85),
						0.08,
						CHAR,
						"Metal"
					)
				end
				r:block(-1.0, 1.82, sx * 0.8 - 0.03, 1.0, 1.9, sx * 0.8 + 0.03, CHAR, "Metal")
				r:block(sx * 1.0 - 0.03, 1.82, -0.77, sx * 1.0 + 0.03, 1.9, 0.77, CHAR, "Metal")
			end
			-- the small one tucked under it, pulled out a little, with an oak top
			local cz = 0.38
			r:block(-0.75, 1.32, cz - 0.68, 0.75, 1.4, cz + 0.68, r.c2, "Wood")
			for _, sx in { -1, 1 } do
				for _, sz in { -1, 1 } do
					rod(
						r,
						Vector3.new(sx * 0.65, 1.28, cz + sz * 0.58),
						Vector3.new(sx * 0.66, 0, cz + sz * 0.6),
						0.07,
						CHAR,
						"Metal"
					)
				end
				r:block(-0.65, 1.25, cz + sx * 0.58 - 0.025, 0.65, 1.32, cz + sx * 0.58 + 0.025, CHAR, "Metal")
			end
			-- a book left on the big one
			r:boxAt(CFrame.new(0.5, 2.04, -0.4) * CFrame.Angles(0, 0.25, 0), 0.7, 0.08, 0.52, BOOKS[1], "SmoothPlastic")
		end,
	},
	{
		id = "modern_desk",
		name = "Desk with monitor",
		cat = "tables",
		style = "modern",
		price = 260,
		place = "floor",
		size = Vector3.new(4.8, 4.9, 2.4),
		surface = 3,
		c1 = "D6B88C",
		c2 = "EDEBE6",
		tags = { "desk", "table" },
		build = function(r: R)
			r:block(-2.4, 2.88, -1.2, 2.4, 3.0, 1.2, r.c1, "Wood")
			-- a white pedestal of three drawers on the right, on a dark plinth
			r:block(1.05, 0, -1.05, 2.25, 0.1, 1.0, shade(r.c2, 0.55), "SmoothPlastic")
			r:block(1.0, 0.1, -1.1, 2.3, 2.88, 1.05, r.c2, "SmoothPlastic")
			for _, y in { { 0.14, 0.98 }, { 1.02, 1.86 }, { 1.9, 2.84 } } do
				r:block(1.04, y[1], 1.05, 2.26, y[2], 1.1, shade(r.c2, 1.02), "SmoothPlastic")
				r:block(1.4, y[2] - 0.12, 1.1, 1.9, y[2] - 0.06, 1.13, shade(r.c2, 0.6), "SmoothPlastic")
			end
			-- a black U leg on the left, and a cable tray under the back
			r:piece(function(q: R)
				q:block(-2.28, 0, -1.05, -2.12, 0.12, 1.05, CHAR, "Metal")
				q:block(-2.28, 2.76, -1.05, -2.12, 2.88, 1.05, CHAR, "Metal")
				for _, sz in { -1, 1 } do
					q:block(-2.28, 0.12, sz * 0.95 - 0.06, -2.12, 2.76, sz * 0.95 + 0.06, CHAR, "Metal")
				end
				q:block(-2.0, 2.6, -1.1, 0.9, 2.88, -1.0, CHAR, "Metal")
				q:block(-2.0, 2.6, -1.0, 0.9, 2.64, -0.8, CHAR, "Metal")
			end, true)
			-- the monitor on its stand, a desktop on the screen
			r:block(-0.65, 3.0, -0.82, 0.05, 3.04, -0.36, CHAR, "Metal")
			r:block(-0.36, 3.04, -0.74, -0.24, 3.95, -0.62, CHAR, "Metal")
			r:block(-1.55, 3.5, -0.62, 0.95, 4.85, -0.54, CHAR, "SmoothPlastic")
			r:block(-1.48, 3.6, -0.54, 0.88, 4.78, -0.51, Color3.fromRGB(150, 184, 200), "SmoothPlastic")
			r:block(-1.48, 3.6, -0.51, 0.88, 3.7, -0.48, Color3.fromRGB(72, 80, 92), "SmoothPlastic")
			r:block(-1.3, 3.95, -0.51, -0.2, 4.6, -0.48, WHITE, "SmoothPlastic")
			r:block(-1.3, 4.5, -0.48, -0.2, 4.6, -0.45, Color3.fromRGB(110, 120, 132), "SmoothPlastic")
			r:block(-0.05, 3.85, -0.51, 0.7, 4.35, -0.48, Color3.fromRGB(232, 228, 216), "SmoothPlastic")
			r:block(0.05, 4.05, -0.48, 0.6, 4.25, -0.45, TEAL, "SmoothPlastic")
			rod(r, Vector3.new(-0.3, 3.6, -0.75), Vector3.new(-0.3, 2.66, -0.95), 0.05, C.Black, "Rubber")
			-- a white keyboard with its rows of keys, a mouse, a teal mug and a little plant
			r:block(-1.2, 3.0, 0.05, 0.4, 3.06, 0.55, WHITE, "SmoothPlastic")
			r:piece(function(q: R)
				for row = 0, 3 do
					local z = 0.12 + row * 0.11
					for k = 0, 6 do
						local x = -1.14 + k * 0.215
						q:block(x, 3.06, z, x + 0.18, 3.09, z + 0.08, shade(WHITE, 0.88), "SmoothPlastic")
					end
				end
			end)
			r:lump(CFrame.new(0.8, 3.05, 0.35), 0.18, 0.1, 0.28, WHITE, "SmoothPlastic")
			r:cyl(1.65, 3.18, 0.2, 0.36, 0.3, "y", TEAL, "SmoothPlastic")
			r:cyl(1.65, 3.375, 0.2, 0.03, 0.22, "y", Color3.fromRGB(92, 66, 50), "SmoothPlastic")
			r:block(1.8, 3.08, 0.17, 1.88, 3.28, 0.23, TEAL, "SmoothPlastic")
			pottedPlant(r, 1.95, 3.0, -0.75, 0.9)
		end,
	},

	---------------------------------------------------------------------------------------------
	-- Beds
	{
		id = "modern_bed",
		name = "Platform bed",
		cat = "beds",
		style = "modern",
		price = 340,
		place = "floor",
		size = Vector3.new(6.6, 3.4, 8),
		c1 = "D6B88C",
		c2 = "A9B2AF",
		tags = { "bed" },
		build = function(r: R)
			-- a low oak platform on a dark plinth set back underneath, so it seems to float
			r:block(-2.9, 0, -3.4, 2.9, 0.35, 3.5, shade(r.c1, 0.4), "Wood")
			r:block(-3.3, 0.35, -3.7, 3.3, 0.85, 4.0, r.c1, "Wood")
			-- a wide oak headboard with three padded panels
			r:block(-3.3, 0.35, -4.0, 3.3, 3.3, -3.7, shade(r.c1, 0.92), "Wood")
			local pad = shade(r.c2, 0.82)
			for _, x in { { -2.5, -0.86 }, { -0.82, 0.82 }, { 0.86, 2.5 } } do
				r:block(x[1], 1.3, -3.7, x[2], 2.9, -3.45, pad, "Fabric")
				r:cyl((x[1] + x[2]) / 2, 2.9, -3.575, x[2] - x[1], 0.25, "x", pad, "Fabric")
			end
			-- the mattress, a turned back sheet and the duvet with its rolled top
			r:block(-2.5, 0.85, -3.45, 2.5, 1.55, 3.6, WHITE, "Fabric")
			r:block(-2.52, 1.55, -3.4, 2.52, 1.6, -1.0, shade(WHITE, 0.96), "Fabric")
			r:block(-2.56, 1.4, -0.9, 2.56, 1.72, 3.66, r.c2, "Fabric")
			r:cyl(0, 1.64, -0.95, 5.12, 0.36, "x", r.c2, "Fabric")
			-- pillows propped on the headboard, a small one in the accent
			for _, sx in { -1, 1 } do
				r:boxAt(
					CFrame.new(sx * 1.2, 1.98, -3.1) * CFrame.Angles(-0.35, 0, sx * 0.04),
					2.0,
					0.95,
					0.4,
					shade(WHITE, 0.94),
					"Fabric"
				)
			end
			r:boxAt(CFrame.new(0, 1.92, -2.62) * CFrame.Angles(-0.3, 0, 0), 1.0, 0.7, 0.26, TEAL, "Fabric")
			-- an oat throw across the foot, over both sides
			local oat = Color3.fromRGB(222, 210, 186)
			r:block(-2.62, 1.72, 2.3, 2.62, 1.78, 3.2, oat, "Fabric")
			for _, sx in { -1, 1 } do
				r:block(
					math.min(sx * 2.58, sx * 2.62),
					1.15,
					2.3,
					math.max(sx * 2.58, sx * 2.62),
					1.72,
					3.2,
					oat,
					"Fabric"
				)
			end
			-- on the ledge, a pile of books on one side and a cup on the other
			bookPile(r, -2.9, 0.85, -2.9, 2, 1)
			r:cyl(2.9, 1.0, -3.0, 0.3, 0.26, "y", WHITE, "SmoothPlastic")
			r:block(3.03, 0.95, -3.03, 3.1, 1.08, -2.97, WHITE, "SmoothPlastic")
			r:sleep(0, 1.72, 0.4, 0)
		end,
	},

	---------------------------------------------------------------------------------------------
	-- Storage
	{
		id = "modern_ladder_shelf",
		name = "Ladder shelf",
		cat = "storage",
		style = "modern",
		price = 110,
		place = "floor",
		size = Vector3.new(2.6, 6.4, 1.8),
		c1 = "D6B88C",
		c2 = "EDEBE6",
		tags = { "books", "storage" },
		build = function(r: R)
			-- two rails leaning on the wall, and shelves that get shallower toward the top
			local function railZ(y: number): number
				return 0.8 - 1.6 * y / 6.35
			end
			for _, sx in { -1, 1 } do
				r:beam(Vector3.new(sx * 1.2, 0, 0.8), Vector3.new(sx * 1.2, 6.35, -0.8), 0.14, 0.18, r.c1, "Wood")
			end
			local tops = {}
			for i, y in { 0.55, 1.95, 3.35, 4.75 } do
				local zf = railZ(y + 0.05) + 0.08
				r:block(-1.13, y, -0.85, 1.13, y + 0.1, zf, r.c2, "Wood")
				r:block(-1.13, y + 0.1, -0.85, 1.13, y + 0.22, -0.79, r.c2, "Wood")
				tops[i] = { y = y + 0.1, z = zf }
			end
			-- bottom: a woven basket with a rolled blanket, and a pile of books
			local y1 = tops[1].y
			local basket = Color3.fromRGB(200, 170, 124)
			r:block(-1.0, y1, -0.6, -0.1, y1 + 0.6, 0.35, basket, "Fabric")
			r:piece(function(q: R)
				for _, y in { 0.12, 0.27, 0.42 } do
					q:block(-1.02, y1 + y, 0.35, -0.08, y1 + y + 0.06, 0.38, shade(basket, 0.8), "Fabric")
					q:block(-1.03, y1 + y, -0.58, -1.0, y1 + y + 0.06, 0.35, shade(basket, 0.8), "Fabric")
				end
			end)
			r:cyl(-0.55, y1 + 0.66, -0.1, 0.8, 0.34, "x", Color3.fromRGB(222, 210, 186), "Fabric")
			bookPile(r, 0.5, y1, 0.0, 3, 2)
			-- second: a row of books and a little plant
			bookRow(r, -1.05, 0.15, tops[2].y, -0.42, 0.7, 4)
			pottedPlant(r, 0.65, tops[2].y, -0.3, 1.0)
			-- third: a teal vase and a framed photo leaning on the wall
			local y3 = tops[3].y
			r:cyl(-0.6, y3 + 0.3, -0.45, 0.6, 0.4, "y", TEAL, "SmoothPlastic")
			r:cyl(-0.6, y3 + 0.68, -0.45, 0.16, 0.2, "y", TEAL, "SmoothPlastic")
			local photo = CFrame.new(0.45, y3 + 0.38, -0.62) * CFrame.Angles(-0.15, 0, 0)
			r:boxAt(photo, 0.7, 0.76, 0.06, C.Black, "SmoothPlastic")
			r:boxAt(photo * CFrame.new(0, 0, 0.045), 0.58, 0.64, 0.03, WHITE, "SmoothPlastic")
			r:boxAt(photo * CFrame.new(0, 0, 0.075), 0.42, 0.48, 0.03, Color3.fromRGB(150, 176, 186), "SmoothPlastic")
			-- top: two books and a stone ball
			local top = bookPile(r, -0.4, tops[4].y, -0.55, 2, 5)
			r:ball(0.55, tops[4].y + 0.18, -0.55, 0.36, Color3.fromRGB(196, 194, 188), "Slate")
			local _ = top
		end,
	},
	{
		id = "modern_sideboard",
		name = "Sideboard",
		cat = "storage",
		style = "modern",
		price = 200,
		place = "floor",
		size = Vector3.new(5.6, 2.9, 1.8),
		surface = 2.87,
		c1 = "D6B88C",
		c2 = "3E3E44",
		tags = { "storage" },
		build = function(r: R)
			-- black hairpin legs at each end
			for _, sx in { -1, 1 } do
				local x = sx * 2.45
				for _, sz in { -1, 1 } do
					rod(r, Vector3.new(x, 0.9, sz * 0.6), Vector3.new(x, 0.03, sz * 0.12), 0.06, r.c2, "Metal")
				end
				rod(r, Vector3.new(x, 0.03, -0.15), Vector3.new(x, 0.03, 0.15), 0.06, r.c2, "Metal")
				r:block(x - 0.12, 0.86, -0.7, x + 0.12, 0.9, 0.7, r.c2, "Metal")
			end
			-- the case, darker inside so the gaps between the fronts show, and its top
			r:block(-2.8, 0.9, -0.85, 2.8, 2.75, 0.75, shade(r.c1, 0.62), "Wood")
			for _, sx in { -1, 1 } do
				r:block(
					math.min(sx * 2.8, sx * 2.84),
					0.9,
					-0.85,
					math.max(sx * 2.8, sx * 2.84),
					2.75,
					0.8,
					r.c1,
					"Wood"
				)
			end
			r:block(-2.85, 2.75, -0.9, 2.85, 2.87, 0.85, r.c1, "Wood")
			-- fluted doors either side, two plain drawers in the middle
			for _, sx in { -1, 1 } do
				local xa, xb = sx * 0.97, sx * 2.76
				local x1, x2 = math.min(xa, xb), math.max(xa, xb)
				r:block(x1, 0.94, 0.75, x2, 2.71, 0.8, r.c1, "Wood")
				r:piece(function(q: R)
					local n = 12
					local step = (x2 - x1 - 0.12) / n
					for k = 0, n - 1 do
						local x = x1 + 0.06 + k * step + 0.02
						q:block(x, 1.0, 0.8, x + step - 0.04, 2.65, 0.83, shade(r.c1, 0.94), "Wood")
					end
				end)
				local px = sx * 1.12
				r:block(px - 0.03, 1.5, 0.83, px + 0.03, 2.1, 0.88, r.c2, "Metal")
			end
			for _, y in { { 0.94, 1.8 }, { 1.85, 2.71 } } do
				r:block(-0.93, y[1], 0.75, 0.93, y[2], 0.8, r.c1, "Wood")
				r:block(-0.4, y[2] - 0.14, 0.8, 0.4, y[2] - 0.08, 0.83, shade(r.c1, 0.5), "Wood")
			end
			-- a low bowl, and two books with a stone ball on them at one end
			r:cyl(-1.7, 2.93, 0.0, 0.12, 0.45, "y", shade(TEAL, 0.85), "SmoothPlastic")
			r:cyl(-1.7, 3.05, 0.0, 0.12, 0.9, "y", TEAL, "SmoothPlastic")
			local top = bookPile(r, 1.9, 2.87, -0.1, 2, 4)
			r:ball(1.9, top + 0.16, -0.1, 0.32, Color3.fromRGB(196, 194, 188), "Slate")
		end,
	},

	---------------------------------------------------------------------------------------------
	-- Kitchen
	{
		id = "modern_breakfast_bar",
		name = "Breakfast bar",
		cat = "kitchen",
		style = "modern",
		price = 280,
		place = "floor",
		size = Vector3.new(6, 3.4, 2.8),
		surface = 3.4,
		c1 = "E6E4DF",
		c2 = "9A9DA3",
		tags = { "kitchen", "table" },
		build = function(r: R)
			-- a stone top that runs down both ends to the floor
			r:block(-3, 3.24, -1.4, 3, 3.4, 1.4, r.c1, "Marble")
			for _, sx in { -1, 1 } do
				r:block(math.min(sx * 2.84, sx * 3), 0, -1.4, math.max(sx * 2.84, sx * 3), 3.24, 1.4, r.c1, "Marble")
			end
			-- the cupboards face the kitchen side (the back), handleless under a channel
			r:block(-2.84, 0, -1.2, 2.84, 0.35, 0.45, CHAR, "SmoothPlastic")
			r:block(-2.84, 0.35, -1.35, 2.84, 3.24, 0.45, shade(r.c2, 0.6), "SmoothPlastic")
			for k = 0, 3 do
				local x1 = -2.8 + k * 1.41
				r:block(x1, 0.38, -1.4, x1 + 1.37, 2.98, -1.35, r.c2, "SmoothPlastic")
			end
			r:block(-2.82, 3.04, -1.43, 2.82, 3.14, -1.35, shade(r.c2, 0.5), "SmoothPlastic")
			-- the seating side is clad in oak slats, under an overhang for your knees
			for half = 0, 1 do
				r:piece(function(q: R)
					for k = 0, 15 do
						local x = -2.8 + (half * 16 + k) * 0.177
						q:block(x, 0.05, 0.45, x + 0.13, 3.2, 0.5, OAK, "Wood")
					end
				end)
			end
			-- a bowl of lemons, a pepper mill and a pot of herbs
			r:cyl(-1.3, 3.46, 0.5, 0.12, 0.5, "y", shade(WHITE, 0.9), "SmoothPlastic")
			r:cyl(-1.3, 3.6, 0.5, 0.16, 1.0, "y", WHITE, "SmoothPlastic")
			for _, p in { { -1.45, 0.42 }, { -1.15, 0.58 }, { -1.3, 0.35 }, { -1.22, 0.62 } } do
				r:ball(p[1], 3.78, p[2], 0.26, C.Yellow, "SmoothPlastic")
			end
			r:cyl(0.2, 3.65, 0.6, 0.5, 0.22, "y", OAK, "Wood")
			r:ball(0.2, 3.92, 0.6, 0.12, C.DarkMetal, "Metal")
			pottedPlant(r, 2.2, 3.4, 0.3, 0.5)
		end,
	},
	{
		id = "modern_coffee_machine",
		name = "Coffee machine",
		cat = "kitchen",
		style = "modern",
		price = 90,
		place = "surface",
		size = Vector3.new(1.3, 1.4, 1.1),
		c1 = "C9CBCF",
		c2 = "D6B88C",
		tags = { "kitchen" },
		build = function(r: R)
			-- a steel body with its brew head out over a drip tray
			r:block(-0.55, 0, -0.5, 0.55, 0.12, 0.5, CHAR, "Metal")
			r:block(-0.6, 0.12, -0.5, 0.6, 1.1, 0.25, r.c1, "Metal")
			r:block(-0.6, 0.85, 0.25, 0.6, 1.1, 0.48, r.c1, "Metal")
			r:piece(function(q: R)
				q:block(-0.45, 0.12, 0.27, 0.45, 0.15, 0.48, shade(r.c1, 0.75), "Metal")
				for k = 0, 4 do
					q:block(-0.4 + k * 0.2, 0.15, 0.3, -0.36 + k * 0.2, 0.17, 0.45, shade(r.c1, 0.6), "Metal")
				end
			end)
			-- the group head, the handle in oak, and a cup under it
			r:cyl(-0.1, 0.79, 0.36, 0.12, 0.28, "y", shade(r.c1, 0.85), "Metal")
			r:cyl(-0.1, 0.68, 0.36, 0.1, 0.3, "y", STEEL, "Metal")
			rod(r, Vector3.new(-0.1, 0.68, 0.48), Vector3.new(-0.1, 0.64, 0.82), 0.08, r.c2, "Wood")
			r:cyl(-0.1, 0.24, 0.36, 0.18, 0.2, "y", WHITE, "SmoothPlastic")
			-- a steam wand and its knob, a pressure dial and two buttons
			rod(r, Vector3.new(0.42, 0.85, 0.32), Vector3.new(0.48, 0.36, 0.42), 0.04, STEEL, "Metal")
			r:cyl(0.42, 0.95, 0.5, 0.06, 0.1, "z", r.c2, "Wood")
			r:cyl(0.22, 0.98, 0.5, 0.04, 0.2, "z", WHITE, "SmoothPlastic")
			r:block(0.215, 0.98, 0.52, 0.225, 1.06, 0.53, C.Red, "SmoothPlastic")
			for _, x in { -0.42, -0.3 } do
				r:block(x - 0.04, 0.95, 0.48, x + 0.04, 1.01, 0.51, CHAR, "SmoothPlastic")
			end
			-- a glass bean hopper on top, and two cups warming
			r:cyl(0.25, 1.13, -0.2, 0.06, 0.3, "y", CHAR, "Metal")
			local hopper = r:cyl(0.25, 1.26, -0.2, 0.2, 0.36, "y", C.Glass, "Glass")
			hopper.transp = 0.4
			r:cyl(0.25, 1.22, -0.2, 0.12, 0.28, "y", Color3.fromRGB(96, 66, 46), "Sand")
			r:cyl(0.25, 1.38, -0.2, 0.04, 0.38, "y", CHAR, "Metal")
			for _, x in { -0.38, -0.12 } do
				r:cyl(x, 1.18, -0.25, 0.16, 0.18, "y", WHITE, "SmoothPlastic")
			end
			local led = r:block(-0.52, 1.03, 0.48, -0.46, 1.06, 0.51, Color3.fromRGB(120, 220, 160), "Neon")
			glowOnly(led)
		end,
	},

	---------------------------------------------------------------------------------------------
	-- Bathroom
	{
		id = "modern_basin_unit",
		name = "Basin unit",
		cat = "bath",
		style = "modern",
		price = 200,
		place = "floor",
		size = Vector3.new(3.4, 3.8, 1.8),
		surface = 2.75,
		c1 = "D6B88C",
		c2 = "ECEAE5",
		tags = { "bath" },
		build = function(r: R)
			-- a slim black frame with a slatted shelf low down and a towel bar at the side
			r:piece(function(q: R)
				for _, sx in { -1, 1 } do
					for _, sz in { -1, 1 } do
						q:block(
							sx * 1.55 - 0.05,
							0,
							sz * 0.75 - 0.05,
							sx * 1.55 + 0.05,
							2.6,
							sz * 0.75 + 0.05,
							CHAR,
							"Metal"
						)
					end
					q:block(sx * 1.55 - 0.04, 0.36, -0.7, sx * 1.55 + 0.04, 0.42, 0.7, CHAR, "Metal")
				end
			end, true)
			r:piece(function(q: R)
				for k = 0, 5 do
					local z = -0.66 + k * 0.23
					q:block(-1.5, 0.42, z, 1.5, 0.48, z + 0.17, r.c1, "Wood")
				end
			end)
			for _, sz in { -1, 1 } do
				rod(r, Vector3.new(1.6, 2.2, sz * 0.75), Vector3.new(1.72, 2.2, sz * 0.75), 0.05, CHAR, "Metal")
			end
			rod(r, Vector3.new(1.72, 2.2, -0.78), Vector3.new(1.72, 2.2, 0.78), 0.06, CHAR, "Metal")
			r:block(1.68, 1.5, -0.4, 1.76, 2.24, 0.35, Color3.fromRGB(196, 210, 206), "Fabric")
			-- the oak drawer under the stone top, with a long black pull
			r:block(-1.5, 1.6, -0.75, 1.5, 2.6, 0.75, shade(r.c1, 0.7), "Wood")
			r:block(-1.48, 1.63, 0.75, 1.48, 2.57, 0.8, r.c1, "Wood")
			r:block(-0.6, 2.38, 0.8, 0.6, 2.44, 0.86, CHAR, "Metal")
			r:block(-1.65, 2.6, -0.85, 1.65, 2.75, 0.85, r.c2, "Marble")
			-- a square basin standing on the top, and a tall black tap
			local bx, bz, w, d, t = -0.15, 0.1, 1.5, 1.0, 0.08
			r:piece(function(q: R)
				q:block(
					bx - w / 2 + t,
					2.75,
					bz - d / 2 + t,
					bx + w / 2 - t,
					2.82,
					bz + d / 2 - t,
					WHITE,
					"SmoothPlastic"
				)
				for _, s in { -1, 1 } do
					q:block(
						bx - w / 2,
						2.75,
						bz + s * (d / 2 - t / 2) - t / 2,
						bx + w / 2,
						3.1,
						bz + s * (d / 2 - t / 2) + t / 2,
						WHITE,
						"SmoothPlastic"
					)
					q:block(
						bx + s * (w / 2 - t / 2) - t / 2,
						2.75,
						bz - d / 2 + t,
						bx + s * (w / 2 - t / 2) + t / 2,
						3.1,
						bz + d / 2 - t,
						WHITE,
						"SmoothPlastic"
					)
				end
			end)
			r:cyl(bx, 2.835, bz, 0.03, 0.14, "y", STEEL, "Metal")
			r:cyl(bx, 3.15, -0.62, 0.8, 0.1, "y", CHAR, "Metal")
			rod(r, Vector3.new(bx, 3.5, -0.62), Vector3.new(bx, 3.5, -0.2), 0.08, CHAR, "Metal")
			rod(r, Vector3.new(bx, 3.3, -0.62), Vector3.new(bx + 0.28, 3.36, -0.62), 0.05, CHAR, "Metal")
			-- an amber soap bottle, a folded hand towel and two rolled towels on the shelf
			r:cyl(1.15, 2.95, -0.45, 0.4, 0.22, "y", Color3.fromRGB(180, 130, 80), "Glass")
			r:cyl(1.15, 3.2, -0.45, 0.1, 0.08, "y", CHAR, "SmoothPlastic")
			rod(r, Vector3.new(1.15, 3.24, -0.45), Vector3.new(1.15, 3.24, -0.32), 0.04, CHAR, "SmoothPlastic")
			r:block(0.85, 2.75, 0.05, 1.45, 2.85, 0.6, WHITE, "Fabric")
			r:block(0.87, 2.85, 0.07, 1.43, 2.94, 0.58, Color3.fromRGB(196, 210, 206), "Fabric")
			for _, x in { -0.6, 0.15 } do
				r:cyl(x, 0.68, 0, 1.0, 0.4, "z", WHITE, "Fabric")
			end
		end,
	},
	{
		id = "modern_shower",
		name = "Walk in shower",
		cat = "bath",
		style = "modern",
		price = 380,
		place = "floor",
		size = Vector3.new(3.6, 7.6, 3.6),
		c1 = "D9D7D2",
		c2 = "3E3E44",
		tags = { "bath" },
		build = function(r: R)
			-- two walls of large tiles and a low stone tray with a long drain
			r:block(-1.8, 0, -1.8, 1.8, 7.6, -1.6, r.c1, "Marble")
			r:block(-1.8, 0, -1.6, -1.6, 7.6, 1.8, r.c1, "Marble")
			r:block(-1.6, 0, -1.6, 1.8, 0.18, 1.8, STONE, "Marble")
			r:block(-1.4, 0.18, -1.48, 1.6, 0.21, -1.32, STEEL, "Metal")
			r:piece(function(q: R)
				local grout = shade(r.c1, 0.8)
				for _, y in { 1.9, 3.8, 5.7 } do
					q:block(-1.6, y - 0.015, -1.6, 1.8, y + 0.015, -1.57, grout, "SmoothPlastic")
					q:block(-1.6, y - 0.015, -1.57, -1.57, y + 0.015, 1.8, grout, "SmoothPlastic")
				end
				q:block(0.085, 0.18, -1.6, 0.115, 7.6, -1.57, grout, "SmoothPlastic")
				q:block(-1.6, 0.18, 0.085, -1.57, 7.6, 0.115, grout, "SmoothPlastic")
			end)
			-- a fixed glass screen in a slim black frame, held by a bar to the back wall
			r:glass(-1.54, 0.3, 1.6, 0.3, 7.0, 1.66)
			r:block(-1.6, 0.18, 1.56, 0.36, 0.3, 1.7, r.c2, "Metal")
			r:block(0.3, 0.3, 1.58, 0.36, 7.0, 1.68, r.c2, "Metal")
			r:block(-1.6, 7.0, 1.58, 0.36, 7.06, 1.68, r.c2, "Metal")
			r:block(-1.6, 0.3, 1.56, -1.54, 7.0, 1.7, r.c2, "Metal")
			rod(r, Vector3.new(0.33, 7.03, 1.6), Vector3.new(0.33, 7.03, -1.6), 0.06, r.c2, "Metal")
			-- a square rain head on an arm, the mixer, and a hand shower on its rail
			rod(r, Vector3.new(0.2, 7.12, -1.6), Vector3.new(0.2, 7.12, -0.6), 0.08, r.c2, "Metal")
			r:block(-0.35, 7.0, -1.15, 0.75, 7.08, -0.05, r.c2, "Metal")
			r:block(-0.3, 6.97, -1.1, 0.7, 7.0, -0.1, STEEL, "Metal")
			r:cyl(0.2, 3.6, -1.57, 0.06, 0.5, "z", r.c2, "Metal")
			rod(r, Vector3.new(0.2, 3.6, -1.54), Vector3.new(0.2, 3.6, -1.3), 0.08, r.c2, "Metal")
			rod(r, Vector3.new(0.2, 3.6, -1.32), Vector3.new(0.45, 3.6, -1.32), 0.06, r.c2, "Metal")
			rod(r, Vector3.new(1.25, 2.8, -1.5), Vector3.new(1.25, 5.2, -1.5), 0.06, r.c2, "Metal")
			for _, y in { 2.8, 5.2 } do
				rod(r, Vector3.new(1.25, y, -1.6), Vector3.new(1.25, y, -1.5), 0.06, r.c2, "Metal")
			end
			r:block(1.18, 4.5, -1.5, 1.32, 4.65, -1.4, r.c2, "Metal")
			rod(r, Vector3.new(1.25, 4.6, -1.42), Vector3.new(1.25, 5.1, -1.3), 0.12, r.c2, "Metal")
			r:cyl(1.25, 5.18, -1.29, 0.1, 0.32, "y", r.c2, "Metal")
			-- its hose hangs in a loop down to an outlet beside the mixer
			local hose = {
				Vector3.new(1.25, 4.55, -1.42),
				Vector3.new(1.3, 3.0, -1.36),
				Vector3.new(1.18, 2.55, -1.36),
				Vector3.new(0.92, 2.62, -1.4),
				Vector3.new(0.78, 3.1, -1.5),
			}
			for k = 1, #hose - 1 do
				rod(r, hose[k], hose[k + 1], 0.05, r.c2, "Metal")
			end
			r:cyl(0.78, 3.1, -1.56, 0.08, 0.12, "z", r.c2, "Metal")
			-- a black ledge with three bottles
			r:block(-1.6, 3.2, -0.8, -1.3, 3.26, 0.4, r.c2, "Metal")
			for i, z in { -0.55, -0.2, 0.15 } do
				local h = 0.5 - i * 0.06
				local col = ({ WHITE, GREY, TEAL })[i]
				r:cyl(-1.45, 3.26 + h / 2, z, h, 0.22, "y", col, "SmoothPlastic")
				r:cyl(-1.45, 3.26 + h + 0.04, z, 0.08, 0.1, "y", CHAR, "SmoothPlastic")
			end
		end,
	},

	---------------------------------------------------------------------------------------------
	-- Lights
	{
		id = "modern_arc_lamp",
		name = "Arc lamp",
		cat = "lights",
		style = "modern",
		price = 130,
		place = "floor",
		size = Vector3.new(5, 7.2, 1.6),
		c1 = "F0EEE9",
		c2 = "C4A468",
		tags = { "light" },
		build = function(r: R)
			-- a heavy marble block, and a brass stem that arcs up and over to hang the shade
			r:block(-2.45, 0, -0.55, -1.35, 0.5, 0.55, WHITE, "Marble")
			r:cyl(-1.9, 0.56, 0, 0.12, 0.3, "y", r.c2, "Metal")
			local p0, p1 = Vector3.new(-1.9, 0.55, 0), Vector3.new(-1.9, 7.5, 0)
			local p2, p3 = Vector3.new(1.7, 7.4, 0), Vector3.new(1.7, 6.25, 0)
			local n = 14
			local last = p0
			for k = 1, n do
				local p = bezier(p0, p1, p2, p3, k / n)
				rod(r, last, p, 0.1, r.c2, "Metal")
				if k < n then
					r:ball(p.X, p.Y, p.Z, 0.1, r.c2, "Metal")
				end
				last = p
			end
			-- the dome: a collar, four steps out to the rim, a warm disc under it
			r:cyl(1.7, 6.15, 0, 0.2, 0.14, "y", r.c2, "Metal")
			r:cyl(1.7, 6.0, 0, 0.14, 0.5, "y", r.c1, "Metal")
			r:cyl(1.7, 5.86, 0, 0.16, 0.95, "y", r.c1, "Metal")
			r:cyl(1.7, 5.68, 0, 0.22, 1.3, "y", r.c1, "Metal")
			r:cyl(1.7, 5.46, 0, 0.26, 1.55, "y", r.c1, "Metal")
			local disc = r:cyl(1.7, 5.3, 0, 0.06, 1.4, "y", C.Warm, "SmoothPlastic")
			r:glow(disc, 18, 1.2)
			-- the cord running off the back of the base
			rod(r, Vector3.new(-2.2, 0.15, -0.55), Vector3.new(-2.3, 0.03, -0.8), 0.05, C.Black, "Rubber")
		end,
	},
	{
		id = "modern_cluster_pendant",
		name = "Globe cluster light",
		cat = "lights",
		style = "modern",
		price = 110,
		place = "ceiling",
		size = Vector3.new(2.4, 4, 2.4),
		c1 = "F4F1EA",
		c2 = "C4A468",
		tags = { "light" },
		build = function(r: R)
			-- a round brass plate, and three opal globes hung at different heights
			r:cyl(0, -0.05, 0, 0.1, 1.3, "y", r.c2, "Metal")
			r:cyl(0, -0.13, 0, 0.06, 1.0, "y", shade(r.c2, 0.9), "Metal")
			local drops = { { 0, 1.9, 0.8 }, { 2.1, 2.4, 0.7 }, { 4.2, 2.9, 0.9 } }
			for i, d in drops do
				local a = d[1]
				local x, z = math.cos(a) * 0.45, math.sin(a) * 0.45
				local len, dia = d[2], d[3]
				r:cyl(x, -0.16 - (len - 0.16) / 2, z, len - 0.16, 0.03, "y", CHAR, "Rubber")
				r:cyl(x, -len - 0.06, z, 0.14, 0.18, "y", r.c2, "Metal")
				r:cyl(x, -len - 0.18, z, 0.1, 0.28, "y", r.c2, "Metal")
				local globe = r:ball(x, -len - 0.22 - dia / 2, z, dia, r.c1, "SmoothPlastic")
				if i == 1 then
					r:glow(globe, 16, 1.2)
				else
					glowOnly(globe)
				end
			end
		end,
	},
	{
		id = "modern_dome_lamp",
		name = "Dome lamp",
		cat = "lights",
		style = "modern",
		price = 50,
		place = "surface",
		size = Vector3.new(1.2, 1.5, 1.2),
		c1 = "8FB3AE",
		c2 = "F0EEE9",
		tags = { "light" },
		build = function(r: R)
			-- one glossy colour from foot to dome, a warm disc under the dome
			r:cyl(0, 0.04, 0, 0.08, 0.72, "y", r.c1, "SmoothPlastic")
			r:cyl(0, 0.12, 0, 0.08, 0.52, "y", shade(r.c1, 1.05), "SmoothPlastic")
			r:cyl(0, 0.35, 0, 0.4, 0.22, "y", r.c1, "SmoothPlastic")
			r:cyl(0, 0.75, 0, 0.4, 0.16, "y", r.c1, "SmoothPlastic")
			r:cyl(0, 1.0, 0, 0.12, 1.15, "y", r.c1, "SmoothPlastic")
			r:cyl(0, 1.12, 0, 0.12, 1.05, "y", r.c1, "SmoothPlastic")
			r:cyl(0, 1.24, 0, 0.12, 0.85, "y", r.c1, "SmoothPlastic")
			r:cyl(0, 1.34, 0, 0.08, 0.55, "y", r.c1, "SmoothPlastic")
			r:cyl(0, 1.4, 0, 0.04, 0.26, "y", r.c1, "SmoothPlastic")
			local disc = r:cyl(0, 0.92, 0, 0.04, 0.9, "y", r.c2, "SmoothPlastic")
			r:glow(disc, 10, 1)
			-- the cord out of the back of the foot
			rod(r, Vector3.new(0, 0.05, -0.36), Vector3.new(0, 0.03, -0.6), 0.04, CHAR, "Rubber")
		end,
	},

	---------------------------------------------------------------------------------------------
	-- Fun
	{
		id = "modern_media_console",
		name = "Media console",
		cat = "fun",
		style = "modern",
		price = 320,
		place = "floor",
		size = Vector3.new(6.4, 5, 1.8),
		c1 = "EDEBE6",
		c2 = "D6B88C",
		tags = { "tv" },
		build = function(r: R)
			local dark = shade(r.c1, 0.55)
			-- a long white case on a dark plinth set well back, an open bay in the middle
			r:block(-2.9, 0, -0.6, 2.9, 0.3, 0.5, CHAR, "SmoothPlastic")
			for _, sx in { -1, 1 } do
				local xa, xb = sx * 0.8, sx * 3.14
				r:block(math.min(xa, xb), 0.3, -0.85, math.max(xa, xb), 1.6, 0.72, dark, "SmoothPlastic")
				r:block(
					math.min(sx * 3.14, sx * 3.2),
					0.3,
					-0.85,
					math.max(sx * 3.14, sx * 3.2),
					1.6,
					0.78,
					r.c1,
					"SmoothPlastic"
				)
				-- two push doors on each side, the gaps between them dark
				for _, d in { { 0.84, 1.96 }, { 2.0, 3.12 } } do
					local x1, x2 = sx * d[1], sx * d[2]
					r:block(math.min(x1, x2), 0.34, 0.72, math.max(x1, x2), 1.56, 0.78, r.c1, "SmoothPlastic")
				end
			end
			r:block(-0.8, 0.3, -0.85, 0.8, 1.6, -0.6, dark, "SmoothPlastic")
			r:block(-0.8, 0.3, -0.6, 0.8, 0.36, 0.72, r.c1, "SmoothPlastic")
			r:block(-0.8, 0.92, -0.6, 0.8, 0.98, 0.7, r.c1, "SmoothPlastic")
			r:block(-3.22, 1.6, -0.88, 3.22, 1.72, 0.8, r.c2, "Wood")
			-- in the bay: a box with a light on it, and a row of records above the shelf
			r:block(-0.55, 0.36, -0.4, 0.15, 0.5, 0.3, CHAR, "SmoothPlastic")
			glowOnly(r:block(-0.45, 0.42, 0.3, -0.35, 0.45, 0.33, Color3.fromRGB(120, 220, 160), "Neon"))
			r:piece(function(q: R)
				local cols = { TEAL, BOOKS[2], BOOKS[4], BOOKS[3], BOOKS[1], BOOKS[6], BOOKS[5] }
				for i, col in cols do
					local x = -0.7 + (i - 1) * 0.1
					q:block(x, 0.98, -0.5, x + 0.07, 1.54, 0.45, col, "SmoothPlastic")
				end
			end)
			r:boxAt(CFrame.new(0.4, 1.24, 0) * CFrame.Angles(0, 0, -0.3), 0.07, 0.56, 0.95, BOOKS[7], "SmoothPlastic")
			-- a flat TV on a pedestal, a soft picture of hills under a low sun
			r:block(-0.7, 1.72, -0.55, 0.7, 1.76, -0.1, CHAR, "Metal")
			r:block(-0.08, 1.76, -0.44, 0.08, 2.3, -0.3, CHAR, "Metal")
			r:block(-2.4, 2.1, -0.3, 2.4, 4.85, -0.22, CHAR, "SmoothPlastic")
			r:block(-2.34, 2.16, -0.22, 2.34, 4.79, -0.19, Color3.fromRGB(196, 208, 214), "SmoothPlastic")
			r:block(-2.34, 2.16, -0.19, 2.34, 2.9, -0.16, Color3.fromRGB(122, 150, 140), "SmoothPlastic")
			r:block(-2.34, 2.9, -0.19, 0.4, 3.25, -0.16, Color3.fromRGB(160, 180, 168), "SmoothPlastic")
			r:cyl(1.2, 3.75, -0.175, 0.03, 0.9, "z", Color3.fromRGB(236, 206, 160), "SmoothPlastic")
			-- a sound bar, a teal vase with dry stems, books and a stone ball
			r:block(-1.3, 1.72, 0.1, 1.3, 1.92, 0.42, CHAR, "Fabric")
			r:block(-1.24, 1.75, 0.42, 1.24, 1.89, 0.45, Color3.fromRGB(84, 84, 90), "Fabric")
			r:cyl(-2.7, 2.05, 0.1, 0.66, 0.4, "y", TEAL, "SmoothPlastic")
			r:cyl(-2.7, 2.45, 0.1, 0.14, 0.2, "y", TEAL, "SmoothPlastic")
			for i, tip in
				{ Vector3.new(-2.95, 3.6, 0.0), Vector3.new(-2.55, 3.35, 0.25), Vector3.new(-2.75, 3.1, -0.1) }
			do
				rod(r, Vector3.new(-2.7, 2.4, 0.1), tip, 0.04, Color3.fromRGB(150, 124, 90), "Wood")
				r:lump(
					CFrame.new(tip) * CFrame.Angles(0.4 * i, i, 0),
					0.22,
					0.3,
					0.2,
					Color3.fromRGB(210, 190, 150),
					"Fabric"
				)
			end
			local top = bookPile(r, 2.6, 1.72, 0.1, 2, 2)
			r:ball(2.6, top + 0.16, 0.1, 0.32, Color3.fromRGB(196, 194, 188), "Slate")
		end,
	},
	{
		id = "modern_speaker",
		name = "Tower speaker",
		cat = "fun",
		style = "modern",
		price = 150,
		place = "floor",
		size = Vector3.new(1.3, 4.3, 1.4),
		c1 = "D6B88C",
		c2 = "3E3E44",
		tags = { "music" },
		build = function(r: R)
			-- a plate on four little spikes, an oak case and a black front with its drivers
			for _, sx in { -1, 1 } do
				for _, sz in { -1, 1 } do
					r:cyl(sx * 0.5, 0.06, sz * 0.55, 0.12, 0.1, "y", STEEL, "Metal")
				end
			end
			r:block(-0.6, 0.12, -0.65, 0.6, 0.2, 0.65, r.c2, "Metal")
			r:block(-0.45, 0.2, -0.6, 0.45, 4.2, 0.5, r.c1, "Wood")
			r:block(-0.43, 0.25, 0.5, 0.43, 4.15, 0.54, r.c2, "SmoothPlastic")
			r:cyl(0, 3.75, 0.56, 0.04, 0.3, "z", STEEL, "Metal")
			r:ball(0, 3.75, 0.58, 0.14, Color3.fromRGB(70, 70, 76), "SmoothPlastic")
			for _, y in { 3.05, 2.2 } do
				r:cyl(0, y, 0.56, 0.04, 0.66, "z", Color3.fromRGB(78, 78, 84), "Rubber")
				r:cyl(0, y, 0.605, 0.03, 0.5, "z", Color3.fromRGB(110, 110, 116), "SmoothPlastic")
				r:ball(0, y, 0.63, 0.18, Color3.fromRGB(70, 70, 76), "SmoothPlastic")
			end
			r:cyl(0, 0.8, 0.56, 0.04, 0.3, "z", C.Black, "SmoothPlastic")
			glowOnly(r:block(-0.05, 4.02, 0.54, 0.05, 4.06, 0.57, TEAL, "Neon"))
			rod(r, Vector3.new(0, 0.5, -0.6), Vector3.new(0, 0.03, -0.75), 0.05, C.Black, "Rubber")
		end,
	},

	---------------------------------------------------------------------------------------------
	-- Decor
	{
		id = "modern_tall_planter",
		name = "Tall planter",
		cat = "decor",
		style = "modern",
		price = 70,
		place = "floor",
		size = Vector3.new(1.6, 5.4, 1.6),
		c1 = "ECEAE5",
		c2 = "4F7A55",
		tags = { "plant" },
		build = function(r: R)
			-- a tall white planter on a dark foot, with pebbles on the soil
			r:cyl(0, 0.08, 0, 0.16, 1.0, "y", CHAR, "SmoothPlastic")
			r:cyl(0, 1.25, 0, 2.2, 1.3, "y", r.c1, "SmoothPlastic")
			r:cyl(0, 2.12, 0, 0.1, 1.38, "y", shade(r.c1, 0.94), "SmoothPlastic")
			r:cyl(0, 2.37, 0, 0.04, 1.15, "y", C.Soil, "Sand")
			for i = 0, 4 do
				local a = i * 1.3
				r:ball(math.cos(a) * 0.4, 2.4, math.sin(a) * 0.4, 0.12, C.Stone, "Slate")
			end
			-- a snake plant: stiff upright leaves ending in points, leaning out a little
			for i = 1, 9 do
				local a = i * 2.4
				local rr = 0.08 + 0.12 * (i % 3)
				local x, z = math.cos(a) * rr, math.sin(a) * rr
				local h = 1.6 + ((i * 7) % 5) * 0.25
				local tilt = 0.06 + 0.05 * (i % 3)
				local yaw = math.atan2(math.cos(a), math.sin(a))
				local cf = CFrame.new(x, 2.35, z) * CFrame.Angles(0, yaw, 0) * CFrame.Angles(tilt, 0, 0)
				local col = if i % 2 == 0 then r.c2 else shade(r.c2, 1.2)
				r:boxAt(cf * CFrame.new(0, h / 2, 0), 0.3, h, 0.06, col, "SmoothPlastic")
				local top = cf * CFrame.new(0, h, 0)
				r:tri(
					(top * CFrame.new(-0.15, 0, 0)).Position,
					(top * CFrame.new(0.15, 0, 0)).Position,
					(top * CFrame.new(0.03, 0.45, 0)).Position,
					0.06,
					col,
					"SmoothPlastic"
				)
			end
		end,
	},
	{
		id = "modern_rug",
		name = "Shapes rug",
		cat = "decor",
		style = "modern",
		price = 70,
		place = "floor",
		size = Vector3.new(6, 0.1, 4.2),
		c1 = "D9D4CB",
		c2 = "8E9096",
		tags = { "rug" },
		build = function(r: R)
			-- layers that each sit 0.025 on the last: an edge, the field, then the shapes
			r:noCollide(r:block(-3, 0, -2.1, 3, 0.025, 2.1, shade(r.c1, 0.85), "Fabric"))
			r:noCollide(r:block(-2.9, 0.025, -2.0, 2.9, 0.05, 2.0, r.c1, "Fabric"))
			r:noCollide(r:block(-2.4, 0.05, -1.5, -0.2, 0.075, 0.6, r.c2, "Fabric"))
			r:noCollide(r:cyl(0.9, 0.0625, -0.4, 0.025, 1.6, "y", TEAL, "Fabric"))
			r:noCollide(r:block(1.9, 0.05, -1.6, 2.6, 0.075, -0.6, Color3.fromRGB(206, 182, 140), "Fabric"))
			r:noCollide(r:cyl(2.25, 0.0625, -1.6, 0.025, 0.7, "y", Color3.fromRGB(206, 182, 140), "Fabric"))
			r:piece(function(q: R)
				for _, z in { 0.9, 1.15, 1.4 } do
					q:block(-0.1, 0.05, z - 0.04, 2.5, 0.075, z + 0.04, CHAR, "Fabric")
				end
				q:block(-2.4, 0.05, 1.0, -1.0, 0.075, 1.08, CHAR, "Fabric")
			end)
			-- a short fringe at both ends
			for _, sx in { -1, 1 } do
				r:piece(function(q: R)
					for k = 0, 19 do
						local z = -1.95 + k * 0.205
						local x1, x2 = sx * 3.0, sx * 3.22
						q:block(math.min(x1, x2), 0, z, math.max(x1, x2), 0.02, z + 0.04, shade(r.c1, 0.95), "Fabric")
					end
				end)
			end
		end,
	},

	---------------------------------------------------------------------------------------------
	-- On walls
	{
		id = "modern_floating_shelves",
		name = "Floating shelves",
		cat = "walldecor",
		style = "modern",
		price = 70,
		place = "wall",
		size = Vector3.new(4, 3.6, 1),
		c1 = "D6B88C",
		c2 = "EDEBE6",
		tags = { "books" },
		build = function(r: R)
			-- three oak boards set off from one another, with no brackets showing
			r:block(-1.9, 2.9, 0, 0.4, 3.02, 0.9, r.c1, "Wood")
			r:block(-0.4, 1.7, 0, 1.9, 1.82, 0.9, r.c1, "Wood")
			r:block(-1.6, 0.5, 0, 0.7, 0.62, 0.9, r.c1, "Wood")
			-- top: a row of books and a trailing plant
			bookRow(r, -1.8, -0.55, 3.02, 0.4, 0.62, 1)
			r:cyl(0.05, 3.2, 0.45, 0.36, 0.42, "y", r.c2, "SmoothPlastic")
			r:cyl(0.05, 3.39, 0.45, 0.03, 0.36, "y", C.Soil, "Sand")
			for k = 0, 3 do
				local y = 3.45 - k * 0.32
				r:lump(
					CFrame.new(0.15 + k * 0.05, y, 0.72 + (k % 2) * 0.08) * CFrame.Angles(0.3 * k, 0.5 * k, 0.2),
					0.3,
					0.26,
					0.24,
					if k % 2 == 0 then C.Leaf else C.DarkLeaf,
					"Grass"
				)
			end
			-- middle: books lying in a pile, a teal vase and a framed photo
			bookPile(r, 0.1, 1.82, 0.45, 3, 3)
			r:cyl(0.85, 2.05, 0.45, 0.46, 0.3, "y", TEAL, "SmoothPlastic")
			r:cyl(0.85, 2.34, 0.45, 0.12, 0.14, "y", TEAL, "SmoothPlastic")
			local photo = CFrame.new(1.45, 2.2, 0.28) * CFrame.Angles(-0.15, 0, 0)
			r:boxAt(photo, 0.7, 0.8, 0.06, r.c1, "Wood")
			r:boxAt(photo * CFrame.new(0, 0, 0.045), 0.56, 0.66, 0.03, WHITE, "SmoothPlastic")
			r:boxAt(photo * CFrame.new(0, -0.05, 0.075), 0.4, 0.4, 0.03, Color3.fromRGB(170, 150, 120), "SmoothPlastic")
			-- low: three books leaning on each other, a bowl and a candle
			for k = 0, 2 do
				r:boxAt(
					CFrame.new(-1.45 + k * 0.16, 0.92, 0.4) * CFrame.Angles(0, 0, -0.35),
					0.12,
					0.7,
					0.55,
					BOOKS[k + 3],
					"SmoothPlastic"
				)
			end
			r:cyl(-0.3, 0.68, 0.45, 0.12, 0.5, "y", shade(WHITE, 0.9), "SmoothPlastic")
			r:cyl(-0.3, 0.78, 0.45, 0.1, 0.62, "y", WHITE, "SmoothPlastic")
			r:cyl(0.35, 0.75, 0.45, 0.26, 0.26, "y", WHITE, "SmoothPlastic")
			r:cyl(0.35, 0.9, 0.45, 0.06, 0.03, "y", C.Black, "SmoothPlastic")
		end,
	},
	{
		id = "modern_print",
		name = "Shapes print",
		cat = "walldecor",
		style = "modern",
		price = 50,
		place = "wall",
		size = Vector3.new(2.8, 3.8, 0.2),
		c1 = "D6B88C",
		c2 = "E9DFCF",
		tags = { "art" },
		build = function(r: R)
			-- a thin oak frame round a white mount, and a print of plain shapes on sand
			r:piece(function(q: R)
				q:block(-1.4, 0, 0, -1.3, 3.8, 0.16, r.c1, "Wood")
				q:block(1.3, 0, 0, 1.4, 3.8, 0.16, r.c1, "Wood")
				q:block(-1.3, 3.7, 0, 1.3, 3.8, 0.16, r.c1, "Wood")
				q:block(-1.3, 0, 0, 1.3, 0.1, 0.16, r.c1, "Wood")
			end)
			r:block(-1.3, 0.1, 0, 1.3, 3.7, 0.1, WHITE, "SmoothPlastic")
			r:block(-1.0, 0.45, 0.1, 1.0, 3.35, 0.13, r.c2, "SmoothPlastic")
			r:block(-0.75, 0.75, 0.13, 0.15, 1.9, 0.16, GREY, "SmoothPlastic")
			r:cyl(-0.3, 1.9, 0.145, 0.03, 0.9, "z", GREY, "SmoothPlastic")
			r:cyl(0.4, 2.6, 0.145, 0.03, 0.9, "z", TEAL, "SmoothPlastic")
			r:block(-0.85, 0.58, 0.13, 0.85, 0.62, 0.16, CHAR, "SmoothPlastic")
			r:cyl(0.6, 1.2, 0.145, 0.03, 0.3, "z", shade(OAK, 0.8), "SmoothPlastic")
		end,
	},
	{
		id = "modern_round_mirror",
		name = "Round mirror",
		cat = "walldecor",
		style = "modern",
		price = 70,
		place = "wall",
		size = Vector3.new(2.6, 3.6, 0.3),
		c1 = "D6B88C",
		c2 = "8A6448",
		tags = { "mirror" },
		build = function(r: R)
			-- a round mirror on an oak disc, hung from a brass peg by a leather strap
			roundPlate(r, 0, 1.3, 0, 0.12, 2.5, "z", r.c1, "Wood")
			roundPlate(r, 0, 1.3, 0.12, 0.15, 2.3, "z", MIRROR, "Glass")
			r:boxAt(CFrame.new(-0.35, 1.6, 0.17) * CFrame.Angles(0, 0, -0.6), 0.12, 1.2, 0.04, WHITE, "Glass")
			local peg = Vector3.new(0, 3.35, 0.14)
			for _, sx in { -1, 1 } do
				local a = math.rad(50)
				local p = Vector3.new(sx * math.sin(a) * 1.25, 1.3 + math.cos(a) * 1.25, 0.14)
				r:beam(peg, p, 0.16, 0.04, r.c2, "Fabric")
				r:ball(p.X, p.Y, p.Z + 0.02, 0.08, C.Gold, "Metal")
			end
			r:cyl(0, 3.35, 0.1, 0.2, 0.16, "z", C.Gold, "Metal")
			r:ball(0, 3.35, 0.22, 0.14, C.Gold, "Metal")
		end,
	},
	{
		id = "modern_wall_clock",
		name = "Oak wall clock",
		cat = "walldecor",
		style = "modern",
		price = 40,
		place = "wall",
		size = Vector3.new(1.8, 1.8, 0.3),
		c1 = "D6B88C",
		c2 = "2F2F35",
		tags = { "clock" },
		build = function(r: R)
			-- an oak face with marks but no numbers, two dark hands and a teal second hand
			roundPlate(r, 0, 0.9, 0, 0.12, 1.7, "z", r.c1, "Wood")
			r:piece(function(q: R)
				q:block(-0.03, 1.46, 0.12, 0.03, 1.66, 0.15, r.c2, "SmoothPlastic")
				for i = 1, 11 do
					local a = i * math.pi / 6
					local long = i % 3 == 0
					local rr = if long then 0.66 else 0.7
					q:boxAt(
						CFrame.new(math.sin(a) * rr, 0.9 + math.cos(a) * rr, 0.135) * CFrame.Angles(0, 0, -a),
						0.06,
						if long then 0.2 else 0.06,
						0.03,
						r.c2,
						"SmoothPlastic"
					)
				end
			end)
			local function hand(angle: number, len: number, w: number, z: number, col: Color3)
				r:boxAt(
					CFrame.new(0, 0.9, z) * CFrame.Angles(0, 0, -angle) * CFrame.new(0, len / 2 - 0.08, 0),
					w,
					len,
					0.03,
					col,
					"SmoothPlastic"
				)
			end
			hand(math.rad(305), 0.45, 0.07, 0.165, r.c2)
			hand(math.rad(60), 0.62, 0.05, 0.195, r.c2)
			hand(math.rad(160), 0.66, 0.02, 0.225, TEAL)
			r:cyl(0, 0.9, 0.245, 0.03, 0.1, "z", TEAL, "SmoothPlastic")
		end,
	},

	---------------------------------------------------------------------------------------------
	-- Garden
	{
		id = "modern_concrete_planter",
		name = "Concrete planter",
		cat = "garden",
		style = "modern",
		price = 90,
		place = "ground",
		size = Vector3.new(5, 2.6, 1.6),
		c1 = "A9AAA6",
		c2 = "7B9A62",
		tags = { "plant" },
		build = function(r: R)
			-- a long trough on two dark feet, soil sunk below its rim
			for _, sx in { -1, 1 } do
				r:block(sx * 2.0 - 0.3, 0, -0.6, sx * 2.0 + 0.3, 0.1, 0.6, CHAR, "SmoothPlastic")
			end
			r:piece(function(q: R)
				q:block(-2.5, 0.1, -0.8, 2.5, 0.22, 0.8, r.c1, "Concrete")
				for _, s in { -1, 1 } do
					q:block(-2.5, 0.22, s * 0.74 - 0.06, 2.5, 1.5, s * 0.74 + 0.06, r.c1, "Concrete")
					q:block(s * 2.44 - 0.06, 0.22, -0.68, s * 2.44 + 0.06, 1.5, 0.68, r.c1, "Concrete")
				end
			end, true)
			r:block(-2.38, 0.22, -0.68, 2.38, 1.4, 0.68, C.Soil, "Sand")
			-- three clumps of tall grass with pale plumes, two clipped balls between them
			for c, cx in { -1.6, 0, 1.6 } do
				r:piece(function(q: R)
					q:block(cx - 0.15, 1.4, -0.15, cx + 0.15, 1.5, 0.15, shade(r.c2, 0.8), "SmoothPlastic")
					local n = 16
					for k = 0, n - 1 do
						local yaw = k * 2 * math.pi / n + c * 0.3
						local h = 1.0 + ((k * 7 + c) % 5) * 0.12
						local lean = 0.2 + ((k * 3) % 4) * 0.08
						local col = if k % 2 == 0 then r.c2 else shade(r.c2, 1.15)
						q:boxAt(
							CFrame.new(cx, 1.4, 0)
								* CFrame.Angles(0, yaw, 0)
								* CFrame.Angles(lean, 0, 0)
								* CFrame.new(0, h / 2, 0),
							0.08,
							h,
							0.03,
							col,
							"SmoothPlastic"
						)
					end
				end)
				for k = 0, 3 do
					local a = k * 1.7 + c
					r:lump(
						CFrame.new(cx + math.cos(a) * 0.35, 2.45 + (k % 2) * 0.15, math.sin(a) * 0.3)
							* CFrame.Angles(0.3, a, 0.2),
						0.12,
						0.36,
						0.12,
						Color3.fromRGB(226, 210, 170),
						"Fabric"
					)
				end
			end
			for _, x in { -0.8, 0.8 } do
				r:lump(CFrame.new(x, 1.75, 0) * CFrame.Angles(0.2, x, 0.1), 0.85, 0.75, 0.85, C.DarkLeaf, "Grass")
			end
		end,
	},
	{
		id = "modern_lounger",
		name = "Sun lounger",
		cat = "garden",
		style = "modern",
		price = 130,
		place = "ground",
		size = Vector3.new(2.6, 2.9, 6.4),
		c1 = "C9A574",
		c2 = "EDEBE6",
		tags = { "seat" },
		build = function(r: R)
			-- a white frame: side rails, two legs at the foot and two wheels at the head
			for _, sx in { -1, 1 } do
				r:block(sx * 1.15 - 0.06, 0.95, -2.6, sx * 1.15 + 0.06, 1.15, 3.1, r.c2, "Metal")
				r:block(sx * 1.15 - 0.06, 0, 2.84, sx * 1.15 + 0.06, 0.95, 2.96, r.c2, "Metal")
				r:block(sx * 1.15 - 0.06, 0.3, -2.51, sx * 1.15 + 0.06, 0.95, -2.39, r.c2, "Metal")
				r:cyl(sx * 1.24, 0.3, -2.45, 0.12, 0.6, "x", CHAR, "Rubber")
				r:cyl(sx * 1.31, 0.3, -2.45, 0.04, 0.2, "x", STEEL, "Metal")
				rod(r, Vector3.new(sx * 1.1, 1.15, -2.2), Vector3.new(sx * 1.1, 1.95, -2.06), 0.08, r.c2, "Metal")
			end
			for _, z in { -2.5, 2.9 } do
				r:block(-1.09, 0.9, z - 0.05, 1.09, 1.0, z + 0.05, r.c2, "Metal")
			end
			-- oak slats along the bed and up the raised back
			local hinge = CFrame.new(0, 1.06, -1.0) * CFrame.Angles(0.7, 0, 0)
			r:piece(function(q: R)
				for k = 0, 13 do
					local z1 = -0.97 + k * 0.29
					q:block(-1.09, 1.0, z1, 1.09, 1.12, z1 + 0.24, r.c1, "Wood")
				end
				for k = 0, 7 do
					q:boxAt(hinge * CFrame.new(0, 0, -(0.2 + k * 0.29)), 2.18, 0.12, 0.24, r.c1, "Wood")
				end
			end)
			for _, sx in { -1, 1 } do
				r:boxAt(hinge * CFrame.new(sx * 1.15, -0.04, -1.25), 0.12, 0.16, 2.5, r.c2, "Metal")
			end
			-- a grey pad over both, and a teal towel rolled at the head
			local pad = Color3.fromRGB(176, 178, 182)
			r:block(-1.0, 1.12, -0.85, 1.0, 1.3, 2.9, pad, "Fabric")
			r:boxAt(hinge * CFrame.new(0, 0.15, -1.25), 2.0, 0.18, 2.3, pad, "Fabric")
			local towel = hinge * CFrame.new(0, 0.42, -2.0)
			r:add({ shape = "Cylinder", cf = towel, size = Vector3.new(1.6, 0.45, 0.45), color = TEAL, mat = "Fabric" })
			for _, x in { -0.55, 0.55 } do
				r:add({
					shape = "Cylinder",
					cf = towel * CFrame.new(x, 0, 0),
					size = Vector3.new(0.1, 0.52, 0.52),
					color = WHITE,
					mat = "Fabric",
				})
			end
			r:seat(0, 1.3, 1.0)
		end,
	},
	{
		id = "modern_fire_table",
		name = "Fire table",
		cat = "garden",
		style = "modern",
		price = 240,
		place = "ground",
		size = Vector3.new(4, 1.9, 2.6),
		c1 = "B5B3AE",
		c2 = "8FB1BD",
		build = function(r: R)
			-- a concrete block on a dark plinth, its top a frame round a bed of glass beads
			r:block(-1.85, 0, -1.15, 1.85, 0.1, 1.15, CHAR, "SmoothPlastic")
			r:block(-2.0, 0.1, -1.3, 2.0, 1.38, 1.3, r.c1, "Concrete")
			r:piece(function(q: R)
				q:block(-2.0, 1.38, -1.3, 2.0, 1.52, -0.6, r.c1, "Concrete")
				q:block(-2.0, 1.38, 0.6, 2.0, 1.52, 1.3, r.c1, "Concrete")
				for _, s in { -1, 1 } do
					q:block(
						math.min(s * 1.35, s * 2.0),
						1.38,
						-0.6,
						math.max(s * 1.35, s * 2.0),
						1.52,
						0.6,
						r.c1,
						"Concrete"
					)
				end
			end, true)
			r:block(-1.35, 1.38, -0.6, 1.35, 1.44, 0.6, r.c2, "Glass")
			for i = 0, 9 do
				local x = -1.15 + (i % 5) * 0.55 + (i // 5) * 0.2
				local z = if i < 5 then -0.38 else 0.36
				r:ball(x, 1.47, z, 0.1, shade(r.c2, 1.1), "Glass")
			end
			-- the burner with its flames, inside a low glass guard
			local burner = r:block(-0.9, 1.44, -0.08, 0.9, 1.5, 0.08, STEEL, "Metal")
			r:fire(burner)
			local flame = r:lump(CFrame.new(0, 1.62, 0), 1.5, 0.26, 0.12, Color3.fromRGB(255, 170, 80), "Neon")
			r:glow(flame, 20, 1.4, Color3.fromRGB(255, 170, 100))
			r:noCollide(flame)
			for _, s in { -1, 1 } do
				r:glass(-1.2, 1.44, s * 0.5 - 0.02, 1.2, 1.85, s * 0.5 + 0.02)
				r:glass(s * 1.2 - 0.02, 1.44, -0.48, s * 1.2 + 0.02, 1.85, 0.48)
			end
			-- the gas knob on the front
			r:cyl(1.5, 0.85, 1.33, 0.06, 0.26, "z", STEEL, "Metal")
			r:block(1.46, 0.8, 1.36, 1.54, 0.9, 1.4, STEEL, "Metal")
		end,
	},
}

return items
