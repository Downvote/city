--!strict
-- Cozy: soft, warm things to live with. The user: "add much much more buildings, decoration,
-- paths, fences and other options. there should be many to choose from from different
-- categories, like garden, sci fi, cozy, etc, just like bloxburg". Every piece here has
-- style = "cozy" (Catalog.Styles) and sits in one of Build mode's usual tabs as well.
-- c1 is the main colour (a fabric or a paint), c2 the second one (a throw, a trim, a pot).
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
local KNIT = Color3.fromRGB(234, 223, 200)
local LINEN = Color3.fromRGB(240, 233, 219)
local SHEET = Color3.fromRGB(250, 248, 243)
local WICKER = Color3.fromRGB(198, 160, 110)
local CLAY = Color3.fromRGB(196, 122, 90)
local CHINA = Color3.fromRGB(244, 240, 232)
local INK = Color3.fromRGB(52, 48, 54)
local SOOT = Color3.fromRGB(40, 36, 38)
local WALNUT = Color3.fromRGB(110, 76, 52)
local LEATHER = Color3.fromRGB(122, 84, 58)
local BRASS = Color3.fromRGB(196, 164, 98)
local MUSTARD = Color3.fromRGB(214, 178, 110)
local SAGE = Color3.fromRGB(150, 172, 140)
local ROSE = Color3.fromRGB(201, 139, 134)
local DUSK = Color3.fromRGB(143, 166, 184)
local SOIL = Color3.fromRGB(86, 62, 46)
local PAGE = Color3.fromRGB(246, 240, 224)

local BOOKS = {
	Color3.fromRGB(184, 92, 88),
	Color3.fromRGB(96, 132, 168),
	Color3.fromRGB(143, 170, 140),
	Color3.fromRGB(214, 176, 96),
	Color3.fromRGB(128, 98, 140),
	Color3.fromRGB(232, 216, 186),
	Color3.fromRGB(110, 78, 56),
	Color3.fromRGB(205, 140, 112),
	Color3.fromRGB(70, 92, 84),
}

-- A small fixed random, so a shelf of books comes out the same every time.
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
		mat = mat or r.mat or "Metal",
	})
end

-- A cylinder along the X axis of a frame.
local function cylAt(r: R, cf: CFrame, len: number, d: number, color: Color3, mat: string?): Recipe.Prim
	return r:add({ shape = "Cylinder", cf = cf, size = V(len, d, d), color = color, mat = mat or r.mat or "Wood" })
end

-- A cushion from (x1, y1, z1) to (x2, y2, z2) with its front and back edges rounded over.
local function cushion(r: R, x1: number, y1: number, z1: number, x2: number, y2: number, z2: number, color: Color3)
	local h = y2 - y1
	local xm, ym = (x1 + x2) / 2, (y1 + y2) / 2
	r:block(x1, y1, z1 + h / 2, x2, y2, z2 - h / 2, color, "Fabric")
	r:cyl(xm, ym, z1 + h / 2, x2 - x1, h, "x", color, "Fabric")
	r:cyl(xm, ym, z2 - h / 2, x2 - x1, h, "x", color, "Fabric")
end

-- A square scatter cushion at a frame, with a piped edge in a deeper shade.
local function pillow(r: R, cf: CFrame, w: number, h: number, color: Color3)
	r:boxAt(cf, w, h, 0.32, color, "Fabric")
	r:boxAt(cf, w + 0.06, h + 0.06, 0.12, shade(color, 0.8), "Fabric")
end

-- A bed pillow `w` wide whose bottom is at y and whose middle is at z, leaning back a little.
local function bedPillow(r: R, x: number, y: number, z: number, w: number, color: Color3)
	local cf = CFrame.new(x, y + 0.22, z) * CFrame.Angles(-0.18, 0, 0)
	r:boxAt(cf, w, 0.44, 0.62, color, "Fabric")
	for _, s in { -1, 1 } do
		cylAt(r, cf * CFrame.new(0, 0, s * 0.31), w, 0.44, color, "Fabric")
	end
end

-- A book lying flat at a frame (its middle): l long, d deep, t thick, spine toward -z. Two
-- boards and a spine round a block of pages set a little in.
local function lyingBook(r: R, cf: CFrame, l: number, d: number, t: number, color: Color3)
	local b = 0.025
	r:boxAt(cf * CFrame.new(0, t / 2 - b / 2, 0), l, b, d, color, "Cardboard")
	r:boxAt(cf * CFrame.new(0, -t / 2 + b / 2, 0), l, b, d, color, "Cardboard")
	r:boxAt(cf * CFrame.new(0, 0, -d / 2 + b / 2), l, t, b, color, "Cardboard")
	r:boxAt(cf * CFrame.new(0, 0, (b - 0.03) / 2), l - 0.06, t - 2 * b, d - b - 0.03, PAGE, "Cardboard")
end

-- A row of upright books on a shelf at y, from x0 toward x1, their backs at zb. Drawn as one
-- piece; every spine has a pale band. Returns where the row ends.
local function bookRow(r: R, x0: number, x1: number, y: number, zb: number, hmax: number, seed: number): number
	local rand = rng(seed)
	local x = x0
	r:piece(function(q: R)
		while true do
			local w = 0.13 + rand() * 0.11
			if x + w > x1 then
				break
			end
			local h = hmax * (0.74 + rand() * 0.26)
			local d = 0.72 + rand() * 0.2
			local col = BOOKS[1 + math.floor(rand() * #BOOKS)]
			q:block(x, y, zb, x + w, y + h, zb + d, col, "Cardboard")
			local band = if rand() < 0.5 then mix(col, C.Cream, 0.55) else BRASS
			q:block(x + 0.02, y + h * 0.72, zb + d, x + w - 0.02, y + h * 0.72 + 0.07, zb + d + 0.03, band, "Cardboard")
			x += w + 0.01
		end
	end, nil, "Cardboard")
	return x
end

-- A woven basket from x1 to x2 and z1 to z2, standing on y, h tall: bands across the front, a
-- rim round the top and a leather tab to pull it by.
local function basket(r: R, x1: number, x2: number, y: number, z1: number, z2: number, h: number)
	r:block(x1, y, z1, x2, y + h, z2, WICKER, "Fabric")
	r:piece(function(q: R)
		for i = 1, 3 do
			local by = y + h * (0.2 + 0.24 * (i - 1))
			q:block(x1, by, z2, x2, by + 0.07, z2 + 0.03, shade(WICKER, 0.82), "Fabric")
		end
	end)
	r:block(x1 - 0.03, y + h - 0.1, z1 - 0.03, x2 + 0.03, y + h + 0.04, z2 + 0.06, shade(WICKER, 0.9), "Fabric")
	local xm = (x1 + x2) / 2
	r:block(xm - 0.17, y + h * 0.42, z2 + 0.03, xm + 0.17, y + h * 0.66, z2 + 0.07, LEATHER, "Fabric")
end

-- A clay pot standing on y: a body, a rolled rim and soil showing at the top. Returns the
-- height of the soil.
local function pot(r: R, x: number, y: number, z: number, d: number, h: number, color: Color3): number
	r:cyl(x, y + h * 0.4, z, h * 0.8, d * 0.84, "y", color, "Sandstone")
	r:cyl(x, y + h * 0.88, z, h * 0.24, d, "y", shade(color, 1.06), "Sandstone")
	r:cyl(x, y + h + 0.015, z, 0.03, d * 0.8, "y", SOIL, "Sand")
	return y + h + 0.03
end

-- A trailing vine: a stem from `from` (a pot's rim) over to `top` (the edge it falls over), then
-- straight down `len`, with heart shaped leaves turned out on both sides. One piece. `seed`
-- turns the leaves a little differently on each vine.
local function vine(r: R, from: Vector3, top: Vector3, len: number, seed: number)
	local rand = rng(seed)
	r:piece(function(q: R)
		q:box(top.X, top.Y - len / 2, top.Z, 0.03, len, 0.03, C.DarkLeaf, "Grass")
		q:beam(from, top + V(0, 0.015, 0), 0.03, 0.03, C.DarkLeaf, "Grass")
		local function leafAt(p: Vector3, s: number, k: number)
			local col = if rand() < 0.5 then C.Leaf else shade(C.Leaf, 1.12)
			q:lump(
				CFrame.new(p + V(s * 0.09, 0, 0.03)) * CFrame.Angles(0.35, 0, s * (0.5 + rand() * 0.5)),
				0.24 * k,
				0.18 * k,
				0.05,
				col,
				"Grass"
			)
		end
		for i = 1, 2 do
			leafAt(from:Lerp(top, i / 3) + V(0, 0.05, 0), if i % 2 == 0 then 1 else -1, 0.9)
		end
		local n = math.max(2, math.floor(len / 0.16))
		for i = 1, n do
			leafAt(V(top.X, top.Y - (i - 0.5) * len / n, top.Z), if i % 2 == 0 then 1 else -1, 1 - 0.3 * i / n)
		end
	end, nil, "Grass")
end

-- A tuft of leaves on a pot: lumps leaning out round the middle and one on top.
local function leafTuft(r: R, x: number, y: number, z: number, s: number, seed: number)
	local rand = rng(seed)
	r:piece(function(q: R)
		q:box(x, y + 0.05 * s, z, 0.08, 0.1 * s, 0.08, C.DarkLeaf, "Grass")
		for i = 0, 6 do
			local a = i * math.pi * 2 / 7 + rand() * 0.4
			local col = if i % 2 == 0 then C.Leaf else C.DarkLeaf
			q:lump(
				CFrame.new(x + math.cos(a) * 0.17 * s, y + 0.12 * s, z + math.sin(a) * 0.17 * s)
					* CFrame.Angles(0, -a, 0)
					* CFrame.Angles(0, 0, 0.5),
				0.34 * s,
				0.08 * s,
				0.2 * s,
				col,
				"Grass"
			)
		end
		q:lump(CFrame.new(x, y + 0.24 * s, z), 0.22 * s, 0.18 * s, 0.22 * s, shade(C.Leaf, 1.1), "Grass")
	end, nil, "Grass")
end

-- A picture frame standing on a shelf, leaning back against the wall behind: w by h at the
-- frame `cf` (the middle of its foot), with a photo of a hill and a sun in it.
local function standingFrame(r: R, cf: CFrame, w: number, h: number, color: Color3, sky: Color3)
	local f = cf * CFrame.Angles(-0.16, 0, 0)
	local b = 0.08
	r:boxAt(f * CFrame.new(0, b / 2, 0), w, b, 0.07, color, "Wood")
	r:boxAt(f * CFrame.new(0, h - b / 2, 0), w, b, 0.07, color, "Wood")
	r:boxAt(f * CFrame.new(-w / 2 + b / 2, h / 2, 0), b, h - 2 * b, 0.07, color, "Wood")
	r:boxAt(f * CFrame.new(w / 2 - b / 2, h / 2, 0), b, h - 2 * b, 0.07, color, "Wood")
	r:boxAt(f * CFrame.new(0, h / 2, -0.01), w - 2 * b, h - 2 * b, 0.03, sky, "Cardboard")
	r:boxAt(f * CFrame.new(0, b + (h - 2 * b) * 0.22, 0.02), w - 2 * b, (h - 2 * b) * 0.44, 0.03, SAGE, "Cardboard")
	cylAt(r, f * CFrame.new(w * 0.15, h * 0.68, 0.02) * CFrame.Angles(0, math.pi / 2, 0), 0.03, w * 0.22, MUSTARD)
end

-- A wall frame from (cx - w/2, y0) to (cx + w/2, y0 + h), b wide and d deep.
local function wallFrame(r: R, cx: number, y0: number, w: number, h: number, b: number, d: number, color: Color3)
	r:piece(function(q: R)
		q:block(cx - w / 2, y0, 0, cx + w / 2, y0 + b, d, color, "Wood")
		q:block(cx - w / 2, y0 + h - b, 0, cx + w / 2, y0 + h, d, color, "Wood")
		q:block(cx - w / 2, y0 + b, 0, cx - w / 2 + b, y0 + h - b, d, color, "Wood")
		q:block(cx + w / 2 - b, y0 + b, 0, cx + w / 2, y0 + h - b, d, color, "Wood")
	end)
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
		id = "cozy_wingback",
		name = "Wingback chair",
		cat = "seating",
		price = 160,
		place = "floor",
		size = V(3.6, 4.3, 3.4),
		c1 = "C4877A",
		c2 = "E9DFC8",
		tags = { "seat" },
		style = "cozy",
		build = function(r: R)
			local body = r.c1
			local deep = shade(body, 0.82)
			-- little bun feet peeking out under a skirt with a piped hem
			for _, sx in { -1, 1 } do
				for _, sz in { -1, 1 } do
					r:cyl(sx * 1.35, 0.06, sz * 1.2, 0.12, 0.32, "y", WALNUT, "Wood")
				end
			end
			r:block(-1.6, 0.12, -1.45, 1.6, 1.12, 1.5, body, "Fabric")
			r:cyl(0, 0.2, 1.52, 2.4, 0.09, "x", deep, "Fabric")
			-- rolled arms with a scroll panel on the front
			for _, sx in { -1, 1 } do
				local xo, xi = sx * 1.78, sx * 1.24
				r:block(math.min(xo, xi), 0.12, -1.1, math.max(xo, xi), 2.3, 1.5, body, "Fabric")
				r:cyl(sx * 1.51, 2.3, 0.2, 2.6, 0.6, "z", body, "Fabric")
				r:block(sx * 1.51 - 0.22, 0.32, 1.5, sx * 1.51 + 0.22, 2.2, 1.54, deep, "Fabric")
				r:cyl(sx * 1.51, 2.3, 1.52, 0.04, 0.66, "z", deep, "Fabric")
			end
			-- the tall back, rolled over at the top, and the wings that wrap round your head
			r:block(-1.6, 1.12, -1.7, 1.6, 3.9, -1.1, body, "Fabric")
			r:cyl(0, 3.9, -1.4, 3.2, 0.6, "x", body, "Fabric")
			for _, sx in { -1, 1 } do
				local x1, x2 = sx * 1.3, sx * 1.6
				r:block(math.min(x1, x2), 2.3, -1.6, math.max(x1, x2), 3.9, -0.5, body, "Fabric")
				r:cyl(sx * 1.45, 3.3, -0.55, 0.3, 1.2, "x", body, "Fabric")
			end
			-- a deep seat cushion and a buttoned back cushion leaning on the frame
			cushion(r, -1.22, 1.12, -0.9, 1.22, 1.62, 1.55, body)
			local back = CFrame.new(0, 1.62, -0.92) * CFrame.Angles(-0.12, 0, 0)
			r:boxAt(back * CFrame.new(0, 1.0, 0), 2.36, 2.0, 0.42, body, "Fabric")
			cylAt(r, back * CFrame.new(0, 2.0, 0), 2.36, 0.42, body, "Fabric")
			for _, bx in { -0.6, 0, 0.6 } do
				local p = (back * CFrame.new(bx, 1.25, 0.21)).Position
				r:ball(p.X, p.Y, p.Z, 0.1, deep, "Fabric")
			end
			-- a striped knitted throw over the left arm, falling inside onto the seat, fringed
			local throw = r.c2
			local stripe = mix(throw, body, 0.45)
			r:cyl(-1.51, 2.3, 0.25, 1.2, 0.7, "z", throw, "Fabric")
			r:block(-1.9, 1.25, -0.35, -1.86, 2.3, 0.85, throw, "Fabric")
			r:block(-1.16, 1.62, -0.35, -1.12, 2.3, 0.85, throw, "Fabric")
			r:block(-1.12, 1.62, -0.35, -0.82, 1.68, 0.85, throw, "Fabric")
			for _, y in { 1.5, 1.85 } do
				r:block(-1.93, y, -0.35, -1.9, y + 0.12, 0.85, stripe, "Fabric")
			end
			for _, z in { -0.05, 0.55 } do
				r:cyl(-1.51, 2.3, z, 0.12, 0.76, "z", stripe, "Fabric")
			end
			for i = 0, 5 do
				r:cyl(-1.88, 1.17, -0.27 + i * 0.22, 0.16, 0.06, "y", throw, "Fabric")
			end
			-- a round knitted cushion in the other corner
			local round = CFrame.new(0.66, 2.12, -0.5) * CFrame.Angles(-0.3, 0, 0) * CFrame.Angles(0, math.pi / 2, 0)
			cylAt(r, round, 0.32, 0.95, KNIT, "Fabric")
			local b = (round * CFrame.new(-0.17, 0, 0)).Position
			r:ball(b.X, b.Y, b.Z, 0.12, shade(KNIT, 0.8), "Fabric")
			r:seat(0, 1.62, 0.35)
		end,
	},
	{
		id = "cozy_window_seat",
		name = "Window seat",
		cat = "seating",
		price = 220,
		place = "floor",
		size = V(6, 3.2, 2.4),
		c1 = "EAE2D3",
		c2 = "93AABB",
		tags = { "seat", "storage" },
		style = "cozy",
		build = function(r: R)
			local wood = r.c1
			-- a built in box with two cubbies, on a recessed kick
			r:block(-2.95, 0, -1.15, 2.95, 0.25, 0.9, shade(wood, 0.78), "Wood")
			r:block(-3, 0.25, -1.2, 3, 1.5, -1.05, wood, "Wood")
			for _, sx in { -1, 1 } do
				r:block(math.min(sx * 3, sx * 2.8), 0.25, -1.05, math.max(sx * 3, sx * 2.8), 1.5, 1.0, wood, "Wood")
			end
			r:block(-0.15, 0.25, -1.05, 0.15, 1.5, 1.0, wood, "Wood")
			r:block(-2.8, 0.25, -1.05, 2.8, 0.4, 1.0, wood, "Wood")
			r:block(-2.8, 1.3, 0.85, 2.8, 1.5, 1.0, wood, "Wood")
			for _, sx in { -1, 1 } do
				r:block(
					math.min(sx * 2.8, sx * 0.15),
					0.4,
					-1.05,
					math.max(sx * 2.8, sx * 0.15),
					1.5,
					-1.0,
					shade(wood, 0.84),
					"Wood"
				)
			end
			r:block(-3.08, 1.5, -1.2, 3.08, 1.62, 1.12, wood, "Wood")
			r:cyl(0, 1.56, 1.12, 6.16, 0.12, "x", wood, "Wood")
			-- a basket in each cubby: blankets rolled up in one, yarn in the other
			for _, sx in { -1, 1 } do
				local cx = sx * 1.475
				basket(r, cx - 1.12, cx + 1.12, 0.4, -0.85, 0.8, 0.72)
			end
			r:cyl(1.475, 1.3, 0.1, 1.8, 0.36, "x", r.c2, "Fabric")
			r:cyl(1.475, 1.3, -0.3, 1.7, 0.34, "x", KNIT, "Fabric")
			r:ball(-1.9, 1.3, 0.1, 0.38, ROSE, "Fabric")
			r:ball(-1.35, 1.28, -0.2, 0.34, MUSTARD, "Fabric")
			r:ball(-0.85, 1.28, 0.15, 0.32, SAGE, "Fabric")
			-- a long buttoned pad
			local pad = r.c2
			cushion(r, -2.95, 1.62, -1.15, 2.95, 1.98, 1.1, pad)
			for i = -2, 2 do
				r:ball(i * 1.2, 1.98, -0.05, 0.1, shade(pad, 0.75), "Fabric")
			end
			-- scatter cushions against the window, bolsters at the ends
			pillow(r, CFrame.new(-1.45, 2.55, -0.85) * CFrame.Angles(-0.28, 0, 0.06), 1.4, 1.1, KNIT)
			pillow(r, CFrame.new(0.05, 2.5, -0.85) * CFrame.Angles(-0.3, 0, -0.04), 1.25, 1.0, mix(pad, C.Cream, 0.45))
			pillow(r, CFrame.new(1.5, 2.55, -0.85) * CFrame.Angles(-0.26, 0, 0.05), 1.4, 1.1, MUSTARD)
			for _, sx in { -1, 1 } do
				r:cyl(sx * 2.55, 2.22, -0.05, 1.9, 0.48, "z", LINEN, "Fabric")
				for _, z in { -0.75, 0.65 } do
					r:cyl(sx * 2.55, 2.22, z, 0.06, 0.54, "z", shade(LINEN, 0.8), "Fabric")
				end
				r:cyl(sx * 2.55, 2.22, 0.92, 0.04, 0.3, "z", shade(LINEN, 0.8), "Fabric")
			end
			-- a book left open, face down, on the pad
			local bk = CFrame.new(0.9, 2.03, 0.45) * CFrame.Angles(0, 0.4, 0)
			for _, s in { -1, 1 } do
				local half = bk * CFrame.new(s * 0.27, 0, 0) * CFrame.Angles(0, 0, -s * 0.18)
				r:boxAt(half * CFrame.new(0, 0.03, 0), 0.56, 0.04, 0.78, BOOKS[2], "Cardboard")
				r:boxAt(half * CFrame.new(0, -0.02, 0), 0.5, 0.06, 0.72, PAGE, "Cardboard")
			end
			r:seat(-1.4, 1.98, 0.3)
			r:seat(1.4, 1.98, 0.3)
		end,
	},
	{
		id = "cozy_reading_lamp",
		name = "Reading lamp",
		cat = "lights",
		price = 85,
		place = "floor",
		size = V(2.2, 5.6, 2.2),
		c1 = "E6C9A2",
		c2 = "B08E58",
		tags = { "light" },
		style = "cozy",
		build = function(r: R)
			local z0 = -0.45
			-- a weighted foot on felt, a slim stem with a switch collar
			r:cyl(0, 0.03, z0, 0.06, 1.2, "y", shade(r.c2, 0.5), "Fabric")
			r:cyl(0, 0.12, z0, 0.12, 1.1, "y", r.c2, "Metal")
			r:cyl(0, 0.23, z0, 0.1, 0.5, "y", r.c2, "Metal")
			r:cyl(0, 2.62, z0, 4.8, 0.1, "y", r.c2, "Metal")
			r:cyl(0, 1.2, z0, 0.16, 0.18, "y", shade(r.c2, 0.8), "Metal")
			-- a little round tray part way up, for a mug and the book you're on
			r:cyl(0, 2.3, z0, 0.14, 0.26, "y", r.c2, "Metal")
			r:cyl(0, 2.42, z0, 0.1, 1.3, "y", WALNUT, "Wood")
			lyingBook(r, CFrame.new(0.32, 2.54, -0.5) * CFrame.Angles(0, 0.25, 0), 0.52, 0.66, 0.14, BOOKS[1])
			lyingBook(r, CFrame.new(0.34, 2.67, -0.48) * CFrame.Angles(0, -0.15, 0), 0.44, 0.58, 0.12, BOOKS[3])
			local mug = Color3.fromRGB(150, 176, 196)
			r:cyl(-0.32, 2.62, -0.22, 0.3, 0.3, "y", mug, "Marble")
			r:block(-0.53, 2.56, -0.25, -0.47, 2.7, -0.19, mug, "Marble")
			r:beam(V(-0.32, 2.77, -0.22), V(-0.2, 2.62, -0.12), 0.02, 0.02, C.Cream, "Fabric")
			r:block(-0.22, 2.5, -0.105, -0.14, 2.62, -0.075, C.Cream, "Fabric")
			-- an arm out over your chair and a pleated drum shade
			r:ball(0, 5.04, z0, 0.18, r.c2, "Metal")
			rod(r, V(0, 5.04, z0), V(0, 5.38, 0.3), 0.08, r.c2, "Metal")
			r:ball(0, 5.38, 0.3, 0.14, r.c2, "Metal")
			r:cyl(0, 5.31, 0.3, 0.12, 0.08, "y", r.c2, "Metal")
			local drum = r:cyl(0, 4.775, 0.3, 0.95, 1.4, "y", r.c1, "Fabric")
			r:glow(drum, 14, 1.1)
			r:piece(function(q: R)
				q:box(0, 4.775, 0.3, 0.1, 0.1, 0.1, shade(r.c1, 0.9), "Fabric")
				for i = 0, 7 do
					local a = i * math.pi / 4 + math.pi / 8
					q:boxAt(
						CFrame.new(math.cos(a) * 0.77, 4.775, 0.3 + math.sin(a) * 0.77) * CFrame.Angles(0, -a, 0),
						0.05,
						0.82,
						0.06,
						shade(r.c1, 0.9),
						"Fabric"
					)
				end
			end)
			r:cyl(0, 4.3, 0.3, 0.06, 1.48, "y", r.c2, "Metal")
			r:cyl(0, 5.25, 0.3, 0.06, 1.48, "y", r.c2, "Metal")
			-- a pull chain with a bead
			r:cyl(0.3, 4.03, 0.3, 0.44, 0.03, "y", r.c2, "Metal")
			r:ball(0.3, 3.79, 0.3, 0.09, r.c2, "Metal")
		end,
	},
	{
		id = "cozy_pouf",
		name = "Knitted pouf",
		cat = "seating",
		price = 45,
		place = "floor",
		size = V(2, 1.5, 2),
		c1 = "D9C9A8",
		c2 = "B9906A",
		tags = { "seat" },
		style = "cozy",
		build = function(r: R)
			-- a firm drum with chunky cables knitted round it, a domed top and a button
			r:cyl(0, 0.04, 0, 0.08, 1.86, "y", r.c2, "Fabric")
			r:cyl(0, 0.7, 0, 1.3, 1.8, "y", r.c1, "Fabric")
			for i = 0, 15 do
				local a = i * math.pi / 8
				r:cyl(
					math.cos(a) * 0.9,
					0.7,
					math.sin(a) * 0.9,
					1.2,
					0.24,
					"y",
					if i % 2 == 0 then r.c1 else shade(r.c1, 0.94),
					"Fabric"
				)
			end
			for half = 0, 1 do
				r:piece(function(q: R)
					q:box(0, 0.7, 0, 0.1, 0.1, 0.1, r.c1, "Fabric")
					for i = half * 8, half * 8 + 7 do
						local a = i * math.pi / 8
						local rib = if i % 2 == 0 then r.c1 else shade(r.c1, 0.94)
						local ys: { number } = if i % 2 == 0 then { 0.42, 0.98 } else { 0.7 }
						for _, y in ys do
							q:lump(
								CFrame.new(math.cos(a) * 0.98, y, math.sin(a) * 0.98) * CFrame.Angles(0, -a, 0),
								0.2,
								0.3,
								0.3,
								rib,
								"Fabric"
							)
						end
					end
				end)
			end
			r:cyl(0, 1.35, 0, 0.06, 1.86, "y", r.c2, "Fabric")
			r:lump(CFrame.new(0, 1.38, 0), 1.6, 0.2, 1.6, r.c1, "Fabric")
			r:cyl(0, 1.49, 0, 0.04, 0.22, "y", r.c2, "Fabric")
			r:seat(0, 1.48, 0)
		end,
	},
	{
		id = "cozy_bookcase",
		name = "Cottage bookcase",
		gives = "books", -- holding E gives something (Data/Items.Sources)
		cat = "storage",
		price = 260,
		place = "floor",
		size = V(4.2, 7.2, 1.6),
		c1 = "93A48C",
		c2 = "EDE2CC",
		tags = { "books", "storage", "plant" },
		style = "cozy",
		build = function(r: R)
			local wood = r.c1
			-- a painted case on a plinth, a cream back and a stepped cornice
			r:block(-2.1, 0, -0.8, 2.1, 0.35, 0.76, wood, "Wood")
			for _, sx in { -1, 1 } do
				r:block(
					math.min(sx * 2.1, sx * 1.95),
					0.35,
					-0.8,
					math.max(sx * 2.1, sx * 1.95),
					6.7,
					0.7,
					wood,
					"Wood"
				)
			end
			r:block(-1.95, 0.35, -0.8, 1.95, 6.7, -0.68, r.c2, "Wood")
			r:block(-2.18, 6.7, -0.86, 2.18, 6.86, 0.8, wood, "Wood")
			r:block(-2.1, 6.86, -0.8, 2.1, 7.0, 0.74, wood, "Wood")
			r:block(-1.95, 0.35, -0.68, 1.95, 0.5, 0.68, wood, "Wood")
			for _, y in { 2.05, 3.6, 5.15 } do
				r:block(-1.95, y - 0.12, -0.68, 1.95, y, 0.68, wood, "Wood")
			end
			-- bottom: two baskets, one with a blanket rolled in it
			basket(r, -1.85, -0.1, 0.5, -0.6, 0.5, 0.95)
			basket(r, 0.1, 1.85, 0.5, -0.6, 0.5, 0.95)
			r:cyl(0.975, 1.6, -0.1, 1.5, 0.34, "x", ROSE, "Fabric")
			-- second shelf: a row of books and a lying stack with a little succulent on top
			bookRow(r, -1.9, 0.45, 2.05, -0.62, 1.25, 11)
			lyingBook(r, CFrame.new(1.15, 2.13, -0.1), 1.05, 0.8, 0.16, BOOKS[4])
			lyingBook(r, CFrame.new(1.12, 2.29, -0.12) * CFrame.Angles(0, 0.08, 0), 0.95, 0.74, 0.16, BOOKS[2])
			lyingBook(r, CFrame.new(1.16, 2.43, -0.08) * CFrame.Angles(0, -0.1, 0), 0.85, 0.66, 0.12, BOOKS[6])
			local soil = pot(r, 1.15, 2.49, -0.1, 0.42, 0.34, CHINA)
			leafTuft(r, 1.15, soil, -0.1, 0.8, 3)
			-- third shelf: a photo leaning at the back, books, one leaning over, and a jug
			standingFrame(r, CFrame.new(-1.45, 3.6, -0.45), 0.7, 0.9, WALNUT, DUSK)
			local e = bookRow(r, -0.95, 0.75, 3.6, -0.62, 1.2, 27)
			r:boxAt(
				CFrame.new(e + 0.36, 3.6 + 0.52, -0.2) * CFrame.Angles(0, 0, -0.5),
				0.18,
				1.12,
				0.8,
				BOOKS[5],
				"Cardboard"
			)
			r:cyl(1.5, 3.85, 0.0, 0.5, 0.42, "y", DUSK, "Cardboard")
			r:cyl(1.5, 4.15, 0.0, 0.1, 0.3, "y", DUSK, "Cardboard")
			r:block(1.7, 3.75, -0.04, 1.78, 4.05, 0.04, DUSK, "Cardboard")
			-- top shelf: a trailing plant whose vines fall over the front, and more books
			local s2 = pot(r, -1.35, 5.15, -0.15, 0.62, 0.5, CLAY)
			leafTuft(r, -1.35, s2, -0.15, 1.1, 7)
			for i, v in { { -1.62, 1.4 }, { -1.3, 0.9 }, { -1.0, 1.15 } } do
				vine(r, V(v[1] * 0.4 - 0.8, s2 - 0.05, 0.1), V(v[1], 5.17, 0.74), v[2], i)
			end
			bookRow(r, -0.6, 1.88, 5.15, -0.62, 1.3, 43)
		end,
	},
	{
		id = "cozy_tea_trolley",
		name = "Tea trolley",
		cat = "kitchen",
		price = 140,
		place = "floor",
		size = V(3.2, 3.2, 1.8),
		c1 = "A8754F",
		c2 = "C8AD72",
		tags = { "kitchen" },
		style = "cozy",
		build = function(r: R)
			local wood, metal = r.c1, r.c2
			-- brass posts on casters
			for _, sx in { -1, 1 } do
				for _, sz in { -1, 1 } do
					local x, z = sx * 1.3, sz * 0.68
					r:cyl(x, 1.6, z, 2.3, 0.1, "y", metal, "Metal")
					r:block(x - 0.1, 0.36, z - 0.09, x + 0.1, 0.45, z + 0.09, metal, "Metal")
					for _, s in { -1, 1 } do
						r:block(
							math.min(x + s * 0.07, x + s * 0.1),
							0.12,
							z - 0.06,
							math.max(x + s * 0.07, x + s * 0.1),
							0.36,
							z + 0.06,
							metal,
							"Metal"
						)
					end
					r:cyl(x, 0.17, z, 0.1, 0.34, "x", C.Black, "Rubber")
					r:cyl(x, 0.17, z, 0.2, 0.1, "x", metal, "Metal")
				end
			end
			-- two trays with lips, and a brass gallery round the top one
			for _, y in { 0.85, 2.4 } do
				r:block(-1.45, y, -0.82, 1.45, y + 0.1, 0.82, wood, "Wood")
				r:piece(function(q: R)
					for _, sz in { -1, 1 } do
						q:block(
							-1.45,
							y + 0.1,
							math.min(sz * 0.76, sz * 0.82),
							1.45,
							y + 0.2,
							math.max(sz * 0.76, sz * 0.82),
							wood,
							"Wood"
						)
					end
					for _, sx in { -1, 1 } do
						q:block(
							math.min(sx * 1.39, sx * 1.45),
							y + 0.1,
							-0.76,
							math.max(sx * 1.39, sx * 1.45),
							y + 0.2,
							0.76,
							wood,
							"Wood"
						)
					end
				end)
			end
			for _, sz in { -1, 1 } do
				r:cyl(0, 2.72, sz * 0.68, 2.6, 0.05, "x", metal, "Metal")
			end
			r:cyl(-1.3, 2.72, 0, 1.36, 0.05, "z", metal, "Metal")
			-- the handle: the right posts bend out to a wooden grip
			for _, sz in { -1, 1 } do
				rod(r, V(1.3, 2.74, sz * 0.68), V(1.48, 3.0, sz * 0.68), 0.08, metal, "Metal")
			end
			r:cyl(1.48, 3.0, 0, 1.46, 0.07, "z", metal, "Metal")
			r:cyl(1.48, 3.0, 0, 0.9, 0.18, "z", wood, "Wood")
			-- a teapot with a blue band, two cups on saucers and a plate of biscuits
			local blue = Color3.fromRGB(110, 146, 182)
			local top = 2.5
			r:lump(CFrame.new(-0.6, top + 0.3, 0), 0.72, 0.6, 0.72, CHINA, "Marble")
			r:cyl(-0.6, top + 0.3, 0, 0.08, 0.78, "y", blue, "Marble")
			r:cyl(-0.6, top + 0.62, 0, 0.06, 0.4, "y", CHINA, "Marble")
			r:ball(-0.6, top + 0.7, 0, 0.12, blue, "Marble")
			rod(r, V(-0.88, top + 0.22, 0), V(-1.1, top + 0.5, 0), 0.1, CHINA, "Marble")
			rod(r, V(-0.3, top + 0.48, 0), V(-0.14, top + 0.45, 0), 0.06, CHINA, "Marble")
			rod(r, V(-0.14, top + 0.47, 0), V(-0.14, top + 0.2, 0), 0.06, CHINA, "Marble")
			rod(r, V(-0.14, top + 0.22, 0), V(-0.3, top + 0.18, 0), 0.06, CHINA, "Marble")
			for _, cup in { { 0.22, 0.38 }, { 0.62, -0.32 } } do
				local x, z = cup[1], cup[2]
				r:cyl(x, top + 0.02, z, 0.04, 0.4, "y", CHINA, "Marble")
				r:cyl(x, top + 0.13, z, 0.18, 0.26, "y", CHINA, "Marble")
				r:cyl(x, top + 0.15, z, 0.03, 0.32, "y", blue, "Marble")
				r:block(x + 0.13, top + 0.08, z - 0.025, x + 0.2, top + 0.18, z + 0.025, CHINA, "Marble")
			end
			r:cyl(0.92, top + 0.02, 0.36, 0.04, 0.62, "y", CHINA, "Marble")
			local biscuit = Color3.fromRGB(214, 172, 112)
			for i = 0, 3 do
				local a = i * math.pi / 2 + 0.4
				r:cyl(
					0.92 + math.cos(a) * 0.14,
					top + 0.065,
					0.36 + math.sin(a) * 0.14,
					0.05,
					0.2,
					"y",
					biscuit,
					"Sand"
				)
			end
			r:cyl(0.92, top + 0.115, 0.36, 0.05, 0.2, "y", shade(biscuit, 0.9), "Sand")
			-- below: a folded tea towel and a cake tin
			r:block(-1.2, 1.05, -0.5, -0.3, 1.17, 0.4, LINEN, "Fabric")
			for _, x in { -1.0, -0.5 } do
				r:block(x, 1.17, -0.5, x + 0.1, 1.2, 0.4, ROSE, "Fabric")
			end
			local tin = Color3.fromRGB(190, 112, 104)
			r:cyl(0.6, 1.27, 0, 0.44, 0.7, "y", tin, "Metal")
			r:cyl(0.6, 1.52, 0, 0.08, 0.76, "y", shade(tin, 0.85), "Metal")
			r:ball(0.6, 1.6, 0, 0.12, BRASS, "Metal")
		end,
	},
	{
		id = "cozy_hearth",
		name = "Stone hearth",
		cat = "decor",
		price = 420,
		place = "floor",
		size = V(6.4, 7, 2.6),
		c1 = "BBB2A4",
		c2 = "7A5638",
		style = "cozy",
		build = function(r: R)
			local stone = r.c1
			local rand = rng(5)
			local function tone(): Color3
				return shade(stone, 0.88 + rand() * 0.2)
			end
			-- a slate hearth, two stone piers and a firebox lined with soot
			r:block(-3.2, 0, -1.3, 3.2, 0.3, 1.3, Color3.fromRGB(128, 124, 124), "Slate")
			for _, sx in { -1, 1 } do
				r:piece(function(q: R)
					q:block(
						math.min(sx * 3.0, sx * 1.6),
						0.3,
						-1.3,
						math.max(sx * 3.0, sx * 1.6),
						3.0,
						0.55,
						stone,
						"Slate"
					)
					for row = 0, 4 do
						local y = 0.6 + row * 0.54
						local off = if row % 2 == 0 then 0 else 0.23
						for col = 0, 2 do
							local x = sx * (1.85 + col * 0.47 + off)
							if math.abs(x) < 2.92 then
								q:lump(CFrame.new(x, y, 0.55), 0.42, 0.46, 0.2, tone(), "Slate")
							end
						end
						for col = 0, 1 do
							q:lump(CFrame.new(sx * 3.0, y + off, -0.8 + col * 0.95), 0.2, 0.46, 0.7, tone(), "Slate")
						end
					end
				end)
			end
			r:block(-1.6, 0.3, -1.3, 1.6, 3.0, -0.9, SOOT, "Slate")
			for _, sx in { -1, 1 } do
				r:block(
					math.min(sx * 1.6, sx * 1.5),
					0.3,
					-0.9,
					math.max(sx * 1.6, sx * 1.5),
					3.0,
					0.55,
					Color3.fromRGB(62, 56, 56),
					"Slate"
				)
			end
			r:block(-1.5, 0.3, -0.9, 1.5, 0.33, 0.5, Color3.fromRGB(70, 64, 62), "Slate")
			-- an old oak beam for a mantel, with adze marks and two iron pins
			local beam = r.c2
			r:block(-3.15, 3.0, -1.3, 3.15, 3.6, 0.95, beam, "Wood")
			r:piece(function(q: R)
				for i, x in { -2.4, -1.1, 0.3, 1.6, 2.6 } do
					local y = 3.1 + (i % 3) * 0.13
					q:block(x - 0.28, y, 0.95, x + 0.28, y + 0.06, 0.98, shade(beam, 0.8), "Wood")
				end
			end)
			for _, sx in { -1, 1 } do
				r:cyl(sx * 2.85, 3.3, 0.97, 0.06, 0.12, "z", SOOT, "Metal")
			end
			-- the chimney breast, faced with stones
			r:piece(function(q: R)
				q:block(-2.8, 3.6, -1.3, 2.8, 7.0, 0.2, stone, "Slate")
				for row = 0, 4 do
					local y = 3.95 + row * 0.65
					local xs: { number } = if row % 2 == 0
						then { -2.2, -1.1, 0, 1.1, 2.2 }
						else { -1.65, -0.55, 0.55, 1.65 }
					for _, x in xs do
						q:lump(CFrame.new(x, y, 0.2), 0.95, 0.56, 0.2, tone(), "Slate")
					end
				end
			end)
			-- iron dogs, three logs and the embers under them
			for _, sx in { -1, 1 } do
				r:block(sx * 0.75 - 0.05, 0.33, -0.55, sx * 0.75 + 0.05, 0.5, 0.35, SOOT, "Metal")
				r:cyl(sx * 0.75, 0.66, 0.35, 0.36, 0.1, "y", SOOT, "Metal")
				r:ball(sx * 0.75, 0.88, 0.35, 0.14, SOOT, "Metal")
			end
			local ember = r:block(-0.7, 0.33, -0.6, 0.7, 0.43, 0.25, Color3.fromRGB(255, 124, 56), "Glass")
			r:glow(ember, 18, 1.4, Color3.fromRGB(255, 160, 90))
			r:cyl(0, 0.68, -0.3, 1.8, 0.42, "x", C.Bark, "Wood")
			r:cyl(0, 0.66, 0.1, 1.7, 0.38, "x", shade(C.Bark, 1.15), "Wood")
			local topLog = r:cyl(0, 0.98, -0.1, 1.6, 0.36, "x", C.Bark, "Wood")
			r:fire(topLog)
			-- spare logs on the hearth, their cut ends pale
			for _, lg in { { 0.86, 0.47 }, { 1.2, 0.47 }, { 1.03, 0.8 } } do
				r:cyl(2.45, lg[2], lg[1], 1.0, 0.34, "x", C.Bark, "Wood")
				for _, sx in { -1, 1 } do
					r:cyl(2.45 + sx * 0.515, lg[2], lg[1], 0.03, 0.26, "x", Color3.fromRGB(214, 180, 132), "Wood")
				end
			end
			-- on the mantel: candlesticks, a little clock, a photo and a jar of dried flowers
			for _, sx in { -1, 1 } do
				local x = sx * 2.6
				r:cyl(x, 3.64, 0.55, 0.08, 0.36, "y", BRASS, "Metal")
				r:cyl(x, 3.85, 0.55, 0.34, 0.12, "y", BRASS, "Metal")
				r:cyl(x, 4.05, 0.55, 0.06, 0.24, "y", BRASS, "Metal")
				r:cyl(x, 4.33, 0.55, 0.5, 0.16, "y", C.Cream, "Plaster")
				glowOnly(r:ball(x, 4.64, 0.55, 0.1, C.Warm, "Glass"))
			end
			r:block(0.15, 3.6, 0.35, 0.85, 4.25, 0.75, WALNUT, "Wood")
			r:block(0.1, 4.25, 0.3, 0.9, 4.33, 0.8, WALNUT, "Wood")
			r:cyl(0.5, 3.95, 0.765, 0.03, 0.42, "z", C.Cream, "Plaster")
			r:block(0.49, 3.95, 0.78, 0.51, 4.12, 0.81, INK, "Metal")
			r:block(0.5, 3.94, 0.81, 0.64, 3.96, 0.84, INK, "Metal")
			standingFrame(r, CFrame.new(-1.3, 3.6, 0.5), 0.8, 1.0, BRASS, Color3.fromRGB(180, 206, 222))
			r:cyl(1.55, 3.82, 0.55, 0.44, 0.3, "y", CHINA, "Marble")
			local dried = { MUSTARD, ROSE, C.Cream, Color3.fromRGB(196, 140, 96), MUSTARD }
			for i = 1, 5 do
				local a = i * 1.3
				local tip = V(1.55 + math.cos(a) * 0.22, 4.55 + (i % 3) * 0.12, 0.55 + math.sin(a) * 0.12)
				rod(r, V(1.55, 3.95, 0.55), tip, 0.03, Color3.fromRGB(120, 110, 70), "Wood")
				r:ball(tip.X, tip.Y, tip.Z, 0.12, dried[i], "Fabric")
			end
			-- a garland of greenery along the beam's edge, with a few red berries
			r:piece(function(q: R)
				q:box(0, 3.3, 0.5, 0.1, 0.1, 0.1, C.DarkLeaf, "Grass")
				for i = 0, 19 do
					local x = -2.95 + i * 0.31
					local t = (math.abs(x) - 1.475) / 1.475
					local y = 3.56 - 0.3 * (1 - t * t)
					local col = if i % 2 == 0 then C.Leaf else C.DarkLeaf
					q:lump(
						CFrame.new(x, y, 1.0) * CFrame.Angles(0, 0, if i % 2 == 0 then 0.4 else -0.4),
						0.38,
						0.24,
						0.24,
						col,
						"Grass"
					)
				end
				for _, x in { -2.3, -1.4, -0.6, 0.6, 1.4, 2.3 } do
					local t = (math.abs(x) - 1.475) / 1.475
					q:ball(x, 3.48 - 0.3 * (1 - t * t), 1.12, 0.1, Color3.fromRGB(178, 70, 72), "Grass")
				end
			end, nil, "Grass")
		end,
	},
	{
		id = "cozy_garland",
		name = "Fairy light garland",
		cat = "lights",
		price = 60,
		place = "wall",
		size = V(7, 2, 0.6),
		c1 = "6E9A6A",
		c2 = "FFD99E",
		tags = { "light" },
		style = "cozy",
		build = function(r: R)
			-- greenery in two swags between three bows, with warm little bulbs tucked in it
			local function swagY(x: number): number
				local xc = if x < 0 then -1.65 else 1.65
				local t = (x - xc) / 1.65
				return 1.7 - 0.75 * (1 - t * t)
			end
			for row = 0, 1 do
				r:piece(function(q: R)
					q:box(-3.2, swagY(-3.2), 0.3, 0.05, 0.05, 0.05, r.c1, "Grass")
					local n = 24
					for i = 0, n - 1 do
						local x = -3.25 + (i + row * 0.5) * 6.5 / n
						local y = swagY(x) + row * 0.07
						local col = if (i + row) % 3 == 0
							then shade(r.c1, 0.78)
							elseif (i + row) % 3 == 1 then r.c1
							else mix(r.c1, C.Yellow, 0.18)
						local sz = if row == 0 then 0.42 else 0.32
						q:lump(
							CFrame.new(x, y, 0.28 + row * 0.08) * CFrame.Angles(0, 0, if i % 2 == 0 then 0.45 else -0.4),
							sz,
							sz * 0.7,
							sz * 0.7,
							col,
							"Grass"
						)
					end
				end, nil, "Grass")
			end
			for _, x in { -2.6, -0.7, 0.9, 2.5 } do
				r:lump(CFrame.new(x, swagY(x) - 0.16, 0.36), 0.14, 0.22, 0.14, C.Bark, "Wood")
			end
			for i = 0, 13 do
				local x = -3.0 + i * 6.0 / 13
				local y = swagY(x) + (if i % 2 == 0 then 0.09 else -0.1)
				local bulb = r:ball(x, y, 0.5, 0.13, r.c2, "Glass")
				if i == 6 then
					r:glow(bulb, 12, 0.9)
				else
					glowOnly(bulb)
				end
			end
			-- a hook and a ribbon bow at each point it hangs from
			local ribbon = Color3.fromRGB(184, 98, 98)
			for _, x in { -3.3, 0, 3.3 } do
				r:cyl(x, 1.86, 0.08, 0.16, 0.06, "z", INK, "Metal")
				for _, s in { -1, 1 } do
					r:boxAt(
						CFrame.new(x + s * 0.16, 1.8, 0.44) * CFrame.Angles(0, 0, s * 0.5),
						0.3,
						0.16,
						0.06,
						ribbon,
						"Fabric"
					)
					r:boxAt(
						CFrame.new(x + s * 0.09, 1.52, 0.42) * CFrame.Angles(0, 0, s * 0.25),
						0.08,
						0.4,
						0.04,
						ribbon,
						"Fabric"
					)
				end
				r:box(x, 1.77, 0.46, 0.12, 0.13, 0.1, shade(ribbon, 0.85), "Fabric")
			end
		end,
	},
	{
		id = "cozy_quilt_ladder",
		name = "Quilt ladder",
		cat = "decor",
		price = 70,
		place = "floor",
		size = V(2.4, 6.2, 1.8),
		c1 = "B48A60",
		c2 = "C98B86",
		style = "cozy",
		build = function(r: R)
			local function zAt(y: number): number
				return 0.62 - 1.37 * y / 6.1
			end
			-- two rails leaning on the wall, five round rungs
			for _, sx in { -1, 1 } do
				r:beam(V(sx * 1.0, 0, zAt(0)), V(sx * 1.0, 6.1, zAt(6.1)), 0.16, 0.12, r.c1, "Wood")
			end
			for i = 1, 5 do
				local y = 0.1 + i * 1.05
				r:cyl(0, y, zAt(y), 2.0, 0.11, "x", shade(r.c1, 0.9), "Wood")
			end
			-- a patchwork quilt over the fourth rung: patches in front, plain behind
			local y4 = 0.1 + 4 * 1.05
			local z4 = zAt(y4)
			r:cyl(0, y4, z4, 1.5, 0.3, "x", r.c2, "Fabric")
			r:block(-0.75, 2.6, z4 - 0.12, 0.75, y4, z4 - 0.06, r.c2, "Fabric")
			local patches = { r.c2, LINEN, MUSTARD, SAGE, shade(r.c2, 0.8), DUSK }
			r:piece(function(q: R)
				for row = 0, 3 do
					for col = 0, 3 do
						local x1 = -0.75 + col * 0.375
						local y2 = y4 - row * 0.35
						q:block(
							x1,
							y2 - 0.35,
							z4 + 0.06,
							x1 + 0.375,
							y2,
							z4 + 0.12,
							patches[1 + (row * 2 + col) % #patches],
							"Fabric"
						)
					end
				end
			end)
			-- a striped knitted blanket over the second rung, fringed at the bottom
			local y2 = 0.1 + 2 * 1.05
			local z2 = zAt(y2)
			r:cyl(0, y2, z2, 1.6, 0.36, "x", KNIT, "Fabric")
			r:block(-0.8, 0.9, z2 + 0.09, 0.8, y2, z2 + 0.15, KNIT, "Fabric")
			r:block(-0.8, 1.3, z2 - 0.15, 0.8, y2, z2 - 0.09, KNIT, "Fabric")
			for _, y in { 1.2, 1.5, 1.8 } do
				r:block(-0.8, y, z2 + 0.15, 0.8, y + 0.1, z2 + 0.18, ROSE, "Fabric")
			end
			for i = 0, 7 do
				r:cyl(-0.7 + i * 0.2, 0.84, z2 + 0.12, 0.12, 0.05, "y", KNIT, "Fabric")
			end
			-- a linen towel folded over the top rung
			local y5 = 0.1 + 5 * 1.05
			local z5 = zAt(y5)
			r:cyl(-0.2, y5, z5, 1.0, 0.26, "x", LINEN, "Fabric")
			r:block(-0.7, y5 - 0.55, z5 + 0.06, 0.3, y5, z5 + 0.1, LINEN, "Fabric")
			r:block(-0.7, y5 - 0.4, z5 - 0.1, 0.3, y5, z5 - 0.06, LINEN, "Fabric")
			r:block(-0.7, y5 - 0.45, z5 + 0.1, 0.3, y5 - 0.39, z5 + 0.13, DUSK, "Fabric")
		end,
	},
	{
		id = "cozy_cat_bed",
		name = "Cat bed",
		cat = "decor",
		price = 55,
		place = "floor",
		size = V(2.4, 1.3, 2.4),
		c1 = "B9A8C6",
		c2 = "D79A5E",
		style = "cozy",
		build = function(r: R)
			-- a round padded bed: a base, a puffy rim and a cushion in the middle
			r:cyl(0, 0.12, 0, 0.24, 2.2, "y", shade(r.c1, 0.85), "Fabric")
			r:piece(function(q: R)
				q:box(0, 0.12, 0, 0.1, 0.1, 0.1, r.c1, "Fabric")
				for i = 0, 11 do
					local a = i * math.pi / 6
					q:lump(
						CFrame.new(math.cos(a) * 0.82, 0.42, math.sin(a) * 0.82) * CFrame.Angles(0, -a, 0),
						0.6,
						0.5,
						0.62,
						r.c1,
						"Fabric"
					)
				end
			end)
			r:cyl(0, 0.33, 0, 0.18, 1.5, "y", LINEN, "Fabric")
			-- a ginger cat curled up asleep, tail round its paws
			local fur = r.c2
			local white = Color3.fromRGB(246, 238, 226)
			r:lump(CFrame.new(0.05, 0.62, -0.05) * CFrame.Angles(0, 0.3, 0), 1.05, 0.48, 0.78, fur, "Fabric")
			r:lump(CFrame.new(0.3, 0.7, -0.15), 0.5, 0.42, 0.5, fur, "Fabric")
			for i, x in { 0.12, 0.3, 0.48 } do
				r:lump(
					CFrame.new(x, 0.83 + (if i == 2 then 0.03 else 0), -0.08) * CFrame.Angles(0, 0.3, 0),
					0.09,
					0.08,
					0.5,
					shade(fur, 0.8),
					"Fabric"
				)
			end
			r:lump(CFrame.new(-0.42, 0.74, 0.22), 0.52, 0.44, 0.48, fur, "Fabric")
			for _, sx in { -1, 1 } do
				r:cone(-0.42 + sx * 0.14, 1.02, 0.2, 0.2, 0.17, fur, "Fabric")
				local ex = -0.42 + sx * 0.07
				r:block(ex - 0.035, 0.77, 0.45, ex + 0.035, 0.785, 0.48, INK, "Metal")
			end
			r:lump(CFrame.new(-0.42, 0.65, 0.44), 0.22, 0.14, 0.1, white, "Fabric")
			r:ball(-0.42, 0.7, 0.48, 0.06, C.Pink, "Fabric")
			r:lump(CFrame.new(-0.28, 0.48, 0.4), 0.22, 0.14, 0.16, white, "Fabric")
			r:lump(CFrame.new(-0.6, 0.48, 0.38), 0.22, 0.14, 0.16, white, "Fabric")
			for i, p in { V(0.48, 0.5, 0.28), V(0.3, 0.47, 0.44), V(0.08, 0.46, 0.52), V(-0.12, 0.47, 0.54) } do
				r:lump(CFrame.new(p), 0.22, 0.16, 0.2, if i == 4 then white else fur, "Fabric")
			end
			-- a ball of yarn rolled away, its loose end trailing over the rim
			local yarn = Color3.fromRGB(214, 150, 160)
			r:ball(0.86, 0.18, 0.92, 0.36, yarn, "Fabric")
			r:cyl(0.86, 0.18, 0.92, 0.04, 0.38, "y", shade(yarn, 0.85), "Fabric")
			r:beam(V(0.75, 0.3, 0.86), V(0.55, 0.62, 0.62), 0.03, 0.03, yarn, "Fabric")
		end,
	},
	{
		id = "cozy_plant_stand",
		name = "Plant stand",
		cat = "garden",
		price = 95,
		place = "floor",
		size = V(3.2, 3.8, 1.8),
		c1 = "B48A60",
		c2 = "C67A5C",
		tags = { "plant" },
		style = "cozy",
		build = function(r: R)
			local wood = r.c1
			local function zFront(y: number): number
				return 0.8 - 1.42 * y / 3.5
			end
			-- an A frame of posts with three stepped tiers of slats
			for _, sx in { -1, 1 } do
				r:block(sx * 1.45 - 0.07, 0, -0.82, sx * 1.45 + 0.07, 3.6, -0.68, wood, "Wood")
				r:beam(V(sx * 1.45, 0, 0.8), V(sx * 1.45, 3.5, zFront(3.5)), 0.14, 0.14, wood, "Wood")
			end
			for _, y in { 0.9, 1.95, 3.0 } do
				local front = zFront(y) + 0.05
				local mid = (-0.82 + front) / 2
				for _, sx in { -1, 1 } do
					r:block(
						sx * 1.31 - 0.07,
						y - 0.25,
						-0.8,
						sx * 1.31 + 0.07,
						y - 0.1,
						front - 0.05,
						shade(wood, 0.85),
						"Wood"
					)
				end
				r:block(-1.55, y - 0.1, -0.82, 1.55, y, mid - 0.02, wood, "Wood")
				r:block(-1.55, y - 0.1, mid + 0.02, 1.55, y, front, wood, "Wood")
			end
			-- bottom: a fern arching out of a wide pot, and a little cactus
			local s1 = pot(r, -0.75, 0.9, 0.0, 0.8, 0.55, r.c2)
			r:piece(function(q: R)
				q:box(-0.75, s1 + 0.05, 0.0, 0.1, 0.1, 0.1, C.DarkLeaf, "Grass")
				for i = 0, 8 do
					local a = i * math.pi * 2 / 9
					local dx, dz = math.cos(a), math.sin(a)
					local col = if i % 2 == 0 then C.Leaf else C.DarkLeaf
					q:lump(
						CFrame.new(-0.75 + dx * 0.3, s1 + 0.25, dz * 0.3)
							* CFrame.Angles(0, -a, 0)
							* CFrame.Angles(0, 0, 0.6),
						0.7,
						0.05,
						0.2,
						col,
						"Grass"
					)
					q:lump(
						CFrame.new(-0.75 + dx * 0.68, s1 + 0.3, dz * 0.68)
							* CFrame.Angles(0, -a, 0)
							* CFrame.Angles(0, 0, -0.35),
						0.5,
						0.05,
						0.17,
						col,
						"Grass"
					)
				end
			end, nil, "Grass")
			local s2 = pot(r, 0.8, 0.9, 0.05, 0.5, 0.4, CHINA)
			local cactus = Color3.fromRGB(104, 150, 104)
			r:cyl(0.8, s2 + 0.25, 0.05, 0.5, 0.3, "y", cactus, "Grass")
			r:ball(0.8, s2 + 0.5, 0.05, 0.3, cactus, "Grass")
			r:cyl(0.96, s2 + 0.3, 0.05, 0.14, 0.12, "x", cactus, "Grass")
			r:cyl(1.04, s2 + 0.42, 0.05, 0.22, 0.12, "y", cactus, "Grass")
			r:ball(0.8, s2 + 0.66, 0.05, 0.08, C.Pink, "Fabric")
			-- middle: a succulent rosette and a violet in flower
			local s3 = pot(r, -0.75, 1.95, -0.35, 0.5, 0.38, mix(r.c2, C.Cream, 0.5))
			r:piece(function(q: R)
				q:box(-0.75, s3 + 0.04, -0.35, 0.08, 0.08, 0.08, SAGE, "Marble")
				for i = 0, 7 do
					local a = i * math.pi / 4
					q:lump(
						CFrame.new(-0.75 + math.cos(a) * 0.12, s3 + 0.08, -0.35 + math.sin(a) * 0.12)
							* CFrame.Angles(0, -a, 0)
							* CFrame.Angles(0, 0, 0.45),
						0.24,
						0.08,
						0.12,
						if i % 2 == 0 then SAGE else shade(SAGE, 1.12),
						"Marble"
					)
				end
				q:lump(CFrame.new(-0.75, s3 + 0.14, -0.35), 0.14, 0.14, 0.14, shade(SAGE, 1.15), "Marble")
			end, nil, "Marble")
			local s4 = pot(r, 0.7, 1.95, -0.35, 0.5, 0.38, r.c2)
			leafTuft(r, 0.7, s4, -0.35, 1.0, 9)
			for i = 0, 4 do
				local a = i * 1.26
				r:ball(
					0.7 + math.cos(a) * 0.14,
					s4 + 0.3 + (i % 2) * 0.06,
					-0.35 + math.sin(a) * 0.14,
					0.1,
					Color3.fromRGB(150, 116, 186),
					"Fabric"
				)
			end
			-- top: a trailing plant with vines over the front
			local s5 = pot(r, 0.0, 3.0, -0.59, 0.48, 0.44, r.c2)
			leafTuft(r, 0.0, s5, -0.59, 1.0, 13)
			for i, x in { -0.25, 0.05, 0.3 } do
				vine(r, V(x * 0.5, s5 - 0.05, -0.42), V(x, 3.02, -0.3), 0.75 + (i % 2) * 0.2, 20 + i)
			end
		end,
	},
	{
		id = "cozy_bunk",
		name = "Cabin bunk bed",
		cat = "beds",
		price = 420,
		place = "floor",
		size = V(4.4, 7.5, 7.4),
		c1 = "C9A57A",
		c2 = "9DB3A2",
		tags = { "bed" },
		style = "cozy",
		build = function(r: R)
			local wood = r.c1
			local dk = shade(wood, 0.86)
			-- four round posts with ball tops
			for _, sx in { -1, 1 } do
				for _, sz in { -1, 1 } do
					r:cyl(sx * 1.85, 3.55, sz * 3.4, 7.1, 0.4, "y", wood, "Wood")
					r:ball(sx * 1.85, 7.25, sz * 3.4, 0.42, dk, "Wood")
				end
			end
			-- two bunks, each with a patchwork quilt in its own colours
			local function bunk(yb: number, quilt: Color3, seed: number)
				for _, sx in { -1, 1 } do
					r:block(sx * 1.85 - 0.1, yb, -3.2, sx * 1.85 + 0.1, yb + 0.4, 3.2, wood, "Wood")
				end
				r:block(-1.75, yb + 0.15, -3.2, 1.75, yb + 0.25, 3.2, dk, "Wood")
				local top = yb + 0.85
				r:block(-1.7, yb + 0.25, -3.2, 1.7, top - 0.1, 3.2, SHEET, "Fabric")
				r:block(-1.76, top - 0.45, -1.4, 1.76, top - 0.03, 3.26, quilt, "Fabric")
				local rand = rng(seed)
				local patches = { quilt, LINEN, shade(quilt, 0.8), MUSTARD, mix(quilt, ROSE, 0.5), LINEN }
				r:piece(function(q: R)
					for row = 0, 5 do
						for col = 0, 3 do
							local x1 = -1.76 + col * 0.88
							local z1 = -1.4 + row * (4.66 / 6)
							q:block(
								x1,
								top - 0.03,
								z1,
								x1 + 0.88,
								top,
								z1 + 4.66 / 6,
								patches[1 + math.floor(rand() * #patches)],
								"Fabric"
							)
						end
					end
				end)
				r:cyl(0, top - 0.02, -1.4, 3.6, 0.3, "x", SHEET, "Fabric")
				bedPillow(r, 0, top - 0.1, -2.55, 2.4, LINEN)
				r:sleep(0, top, 0.2)
			end
			bunk(0.7, r.c2, 3)
			bunk(4.5, ROSE, 8)
			-- headboards of upright boards, a low footboard, rails round the top bunk
			for _, base in { { 1.0, 3.1 }, { 4.8, 6.9 } } do
				for i = 0, 3 do
					r:block(
						-1.65 + i * 0.825,
						base[1],
						-3.5,
						-1.65 + (i + 1) * 0.825,
						base[2],
						-3.3,
						if i % 2 == 0 then wood else shade(wood, 0.94),
						"Wood"
					)
				end
			end
			r:block(-1.65, 1.0, 3.3, 1.65, 2.2, 3.5, wood, "Wood")
			r:block(-1.65, 4.5, 3.3, 1.65, 4.95, 3.5, wood, "Wood")
			for _, sx in { -1, 1 } do
				for _, y in { 5.65, 6.45 } do
					r:block(sx * 1.85 - 0.08, y, -3.2, sx * 1.85 + 0.08, y + 0.2, 3.2, wood, "Wood")
				end
			end
			-- the ladder: rungs across the foot posts
			for _, y in { 2.9, 3.7, 5.9, 6.7 } do
				r:cyl(0, y, 3.4, 3.3, 0.14, "x", dk, "Wood")
			end
			-- a curtain for the bottom bunk, tied back at both ends
			r:cyl(2.1, 4.3, 0, 6.4, 0.06, "z", BRASS, "Metal")
			for _, zc in { -2.7, 2.7 } do
				for i = 0, 4 do
					local z = zc - 0.4 + i * 0.2
					r:cyl(if i % 2 == 0 then 2.06 else 2.13, 2.75, z, 2.9, 0.22, "y", LINEN, "Fabric")
				end
				r:block(2.0, 2.4, zc - 0.55, 2.22, 2.52, zc + 0.55, shade(r.c2, 0.85), "Fabric")
			end
			-- a little shelf over the top pillow with a book and a plant, and a knitted bunny below
			r:block(-1.3, 6.2, -3.3, -0.2, 6.28, -3.0, wood, "Wood")
			lyingBook(r, CFrame.new(-0.95, 6.34, -3.15) * CFrame.Angles(0, 0.2, 0), 0.4, 0.26, 0.12, BOOKS[5])
			local s = pot(r, -0.5, 6.28, -3.15, 0.24, 0.2, CLAY)
			r:ball(-0.5, s + 0.08, -3.15, 0.2, C.Leaf, "Grass")
			local bun = Color3.fromRGB(232, 222, 206)
			r:lump(CFrame.new(1.0, 1.85, -2.0), 0.4, 0.46, 0.34, bun, "Fabric")
			r:ball(1.0, 2.22, -2.0, 0.32, bun, "Fabric")
			for _, sx in { -1, 1 } do
				r:lump(
					CFrame.new(1.0 + sx * 0.08, 2.5, -2.02) * CFrame.Angles(0, 0, sx * -0.2),
					0.09,
					0.34,
					0.06,
					bun,
					"Fabric"
				)
			end
		end,
	},
	{
		id = "cozy_rug_braided",
		name = "Braided rug",
		cat = "decor",
		price = 70,
		place = "floor",
		size = V(6, 0.15, 4.2),
		c1 = "C98B86",
		c2 = "E9DFC8",
		tags = { "rug" },
		style = "cozy",
		build = function(r: R)
			-- an oval of braids in rings of colour, each ring a layer 0.025 over the last
			local a = 0.9
			local rings: { { any } } = {
				{ 2.1, shade(r.c1, 0.85) },
				{ 1.78, r.c2 },
				{ 1.46, r.c1 },
				{ 1.14, mix(r.c1, MUSTARD, 0.55) },
				{ 0.82, r.c2 },
				{ 0.5, r.c1 },
			}
			for i, ring in rings do
				local rad, col = ring[1], ring[2]
				local y0 = (i - 1) * 0.025
				r:noCollide(r:block(-a, y0, -rad, a, y0 + 0.025, rad, col, "Carpet"))
				for _, sx in { -1, 1 } do
					r:noCollide(r:cyl(sx * a, y0 + 0.0125, 0, 0.025, rad * 2, "y", col, "Carpet"))
				end
			end
			-- the braid's twist on the outside ring: short slanted strands all the way round
			local pts = {}
			local function along(s: number): (number, number, number)
				-- a point on the middle of the outside ring and the way it runs there
				local rad = 1.94
				local straight = 2 * a
				local arc = math.pi * rad
				local total = 2 * straight + 2 * arc
				s = s % total
				if s < straight then
					return -a + s, rad, 0
				end
				s -= straight
				if s < arc then
					local t = s / rad
					return a + math.sin(t) * rad, math.cos(t) * rad, -t
				end
				s -= arc
				if s < straight then
					return a - s, -rad, math.pi
				end
				s -= straight
				local t = s / rad
				return -a - math.sin(t) * rad, -math.cos(t) * rad, math.pi - t
			end
			local total = 4 * a + 2 * math.pi * 1.94
			local n = 48
			for i = 0, n - 1 do
				local x, z, ang = along(i * total / n)
				table.insert(pts, { x, z, ang })
			end
			for half = 0, 1 do
				r:piece(function(q: R)
					q:box(0, 0.0125, 0, 0.05, 0.02, 0.05, shade(r.c1, 0.85), "Carpet")
					for i = half * 24 + 1, half * 24 + 24 do
						local p = pts[i]
						q:boxAt(
							CFrame.new(p[1], 0.0425, p[2]) * CFrame.Angles(0, p[3] + 0.7, 0),
							0.24,
							0.035,
							0.09,
							if i % 2 == 0 then r.c2 else shade(r.c1, 0.72),
							"Carpet"
						)
					end
				end)
			end
			for _, p in r.prims do
				if p.shape == "Piece" then
					p.collide = false
				end
			end
		end,
	},
	{
		id = "cozy_rug_patch",
		name = "Patchwork rug",
		cat = "decor",
		price = 75,
		place = "floor",
		size = V(5, 0.12, 5),
		c1 = "8FA6B8",
		c2 = "EADFC8",
		tags = { "rug" },
		style = "cozy",
		build = function(r: R)
			-- a backing, a pale field for the stitching to show through, and 25 patches
			r:noCollide(r:block(-2.5, 0, -2.5, 2.5, 0.025, 2.5, shade(r.c1, 0.72), "Carpet"))
			r:noCollide(r:block(-2.35, 0.025, -2.35, 2.35, 0.05, 2.35, r.c2, "Carpet"))
			local colours = { r.c1, LINEN, MUSTARD, SAGE, ROSE, shade(r.c1, 0.8), r.c2 }
			r:noCollide(r:piece(function(q: R)
				for i = 0, 4 do
					for j = 0, 4 do
						local x = -1.8 + i * 0.9
						local z = -1.8 + j * 0.9
						local col = colours[1 + (i * 3 + j * 2) % #colours]
						q:block(x - 0.42, 0.05, z - 0.42, x + 0.42, 0.075, z + 0.42, col, "Carpet")
					end
				end
			end))
			-- a small diamond sewn on every other patch
			for i = 0, 4 do
				for j = 0, 4 do
					if (i + j) % 2 == 0 then
						r:noCollide(
							r:boxAt(
								CFrame.new(-1.8 + i * 0.9, 0.0875, -1.8 + j * 0.9) * CFrame.Angles(0, math.pi / 4, 0),
								0.28,
								0.025,
								0.28,
								if (i * 3 + j * 2) % 7 == 1 then ROSE else r.c2,
								"Carpet"
							)
						)
					end
				end
			end
			-- tassels along both ends
			r:noCollide(r:piece(function(q: R)
				for _, s in { -1, 1 } do
					for i = 0, 10 do
						local x = -2.25 + i * 0.45
						q:block(
							x - 0.05,
							0,
							math.min(s * 2.5, s * 2.72),
							x + 0.05,
							0.03,
							math.max(s * 2.5, s * 2.72),
							C.Cream,
							"Fabric"
						)
					end
				end
			end))
		end,
	},
	{
		id = "cozy_photo_wall",
		name = "Photo frames",
		cat = "walldecor",
		price = 55,
		place = "wall",
		size = V(4.4, 3.2, 0.25),
		c1 = "8E6440",
		c2 = "EDE6D6",
		tags = { "art" },
		style = "cozy",
		build = function(r: R)
			-- five frames hung close together, each with its own photo: two people, a hill
			-- walk, the cat, a jug of flowers and a sunset over the sea
			local frames = {
				{ cx = -1.4, y0 = 1.2, w = 1.3, h = 1.8, col = r.c1 },
				{ cx = 0.05, y0 = 1.9, w = 1.2, h = 1.0, col = r.c2 },
				{ cx = 0.05, y0 = 0.55, w = 1.0, h = 1.1, col = BRASS },
				{ cx = 1.45, y0 = 1.55, w = 1.0, h = 1.3, col = shade(r.c1, 0.75) },
				{ cx = 1.5, y0 = 0.3, w = 0.9, h = 0.9, col = r.c2 },
			}
			for _, f in frames do
				wallFrame(r, f.cx, f.y0, f.w, f.h, 0.1, 0.2, f.col)
			end
			local function photo(f: any, bg: Color3, draw: (q: R, x1: number, y1: number, x2: number, y2: number) -> ())
				local x1, x2 = f.cx - f.w / 2 + 0.1, f.cx + f.w / 2 - 0.1
				local y1, y2 = f.y0 + 0.1, f.y0 + f.h - 0.1
				r:piece(function(q: R)
					q:block(x1, y1, 0, x2, y2, 0.05, C.Paper, "Cardboard")
					q:block(x1 + 0.08, y1 + 0.08, 0.05, x2 - 0.08, y2 - 0.08, 0.08, bg, "Cardboard")
					draw(q, x1 + 0.08, y1 + 0.08, x2 - 0.08, y2 - 0.08)
				end, nil, "Cardboard")
			end
			local skin1, skin2 = Color3.fromRGB(232, 196, 166), Color3.fromRGB(176, 128, 96)
			photo(
				frames[1],
				Color3.fromRGB(176, 206, 222),
				function(q: R, x1: number, y1: number, x2: number, y2: number)
					q:block(x1, y1, 0.08, x2, y1 + 0.35, 0.11, SAGE, "Cardboard")
					for i, p in
						{ { -0.22, skin1, ROSE, WALNUT }, { 0.22, skin2, Color3.fromRGB(90, 140, 140), INK } } :: { { any } }
					do
						local x = (x1 + x2) / 2 + p[1]
						local top = y1 + 0.75 + (i - 1) * 0.06
						q:block(x - 0.18, y1, 0.11, x + 0.18, top, 0.14, p[3], "Cardboard")
						q:cyl(x, top, 0.125, 0.03, 0.36, "z", p[3], "Cardboard")
						q:cyl(x, top + 0.34, 0.125, 0.03, 0.34, "z", p[4], "Cardboard")
						q:cyl(x, top + 0.3, 0.155, 0.03, 0.28, "z", p[2], "Cardboard")
					end
				end
			)
			photo(
				frames[2],
				Color3.fromRGB(196, 220, 232),
				function(q: R, x1: number, y1: number, x2: number, y2: number)
					q:tri(V(x1, y1, 0.095), V(x2, y1, 0.095), V(x2, y1 + 0.5, 0.095), 0.03, C.DarkLeaf, "Cardboard")
					q:tri(V(x1, y1, 0.125), V(x1 + 0.7, y1, 0.125), V(x1, y1 + 0.42, 0.125), 0.03, C.Leaf, "Cardboard")
					q:cyl(x2 - 0.22, y2 - 0.18, 0.095, 0.03, 0.18, "z", MUSTARD, "Cardboard")
					q:block(x1 + 0.45, y1 + 0.05, 0.14, x1 + 0.5, y1 + 0.2, 0.17, INK, "Cardboard")
				end
			)
			photo(
				frames[3],
				Color3.fromRGB(238, 216, 184),
				function(q: R, x1: number, y1: number, x2: number, y2: number)
					local cx = (x1 + x2) / 2
					local cat = Color3.fromRGB(96, 88, 92)
					q:cyl(cx, y1 + 0.22, 0.095, 0.03, 0.42, "z", cat, "Cardboard")
					q:cyl(cx, y1 + 0.5, 0.095, 0.03, 0.28, "z", cat, "Cardboard")
					for _, s in { -1, 1 } do
						q:tri(
							V(cx + s * 0.13, y1 + 0.55, 0.095),
							V(cx + s * 0.02, y1 + 0.6, 0.095),
							V(cx + s * 0.12, y1 + 0.74, 0.095),
							0.03,
							cat,
							"Cardboard"
						)
						q:block(
							cx + s * 0.06 - 0.025,
							y1 + 0.5,
							0.11,
							cx + s * 0.06 + 0.025,
							y1 + 0.55,
							0.14,
							MUSTARD,
							"Cardboard"
						)
					end
					q:boxAt(
						CFrame.new(cx + 0.27, y1 + 0.2, 0.095) * CFrame.Angles(0, 0, -0.6),
						0.07,
						0.36,
						0.03,
						cat,
						"Cardboard"
					)
				end
			)
			photo(
				frames[4],
				Color3.fromRGB(226, 214, 200),
				function(q: R, x1: number, y1: number, x2: number, y2: number)
					local cx = (x1 + x2) / 2
					q:block(x1, y1, 0.08, x2, y1 + 0.15, 0.11, WALNUT, "Cardboard")
					q:block(cx - 0.14, y1 + 0.15, 0.08, cx + 0.14, y1 + 0.45, 0.11, DUSK, "Cardboard")
					for i, b in
						{ { -0.18, 0.75, ROSE }, { 0.05, 0.85, MUSTARD }, { 0.2, 0.68, C.Cream } } :: { { any } }
					do
						q:beam(V(cx, y1 + 0.45, 0.095), V(cx + b[1], y1 + b[2], 0.095), 0.03, 0.03, C.Leaf, "Cardboard")
						q:cyl(cx + b[1], y1 + b[2], 0.125 + (i % 2) * 0.03, 0.03, 0.16, "z", b[3], "Cardboard")
					end
				end
			)
			photo(
				frames[5],
				Color3.fromRGB(232, 178, 140),
				function(q: R, x1: number, y1: number, x2: number, y2: number)
					local cx = (x1 + x2) / 2
					q:block(x1, y1 + 0.32, 0.08, x2, y1 + 0.44, 0.11, Color3.fromRGB(240, 204, 160), "Cardboard")
					q:cyl(cx, y1 + 0.3, 0.125, 0.03, 0.3, "z", Color3.fromRGB(244, 222, 150), "Cardboard")
					q:block(x1, y1, 0.14, x2, y1 + 0.26, 0.17, Color3.fromRGB(110, 150, 176), "Cardboard")
					q:block(x1 + 0.1, y1 + 0.12, 0.17, x1 + 0.3, y1 + 0.15, 0.2, C.Cream, "Cardboard")
				end
			)
		end,
	},
	{
		id = "cozy_sideboard",
		name = "Sideboard with radio",
		cat = "storage",
		price = 240,
		place = "floor",
		size = V(5.2, 4.4, 1.8),
		c1 = "B07F58",
		c2 = "E5D8BE",
		tags = { "storage", "music" },
		style = "cozy",
		build = function(r: R)
			local wood = r.c1
			local front = shade(wood, 1.08)
			-- a low case on splayed legs with brass shoes
			for _, sx in { -1, 1 } do
				for _, sz in { -1, 1 } do
					rod(r, V(sx * 2.25, 0.86, sz * 0.55), V(sx * 2.35, 0.08, sz * 0.66), 0.15, wood, "Wood")
					r:cyl(sx * 2.355, 0.05, sz * 0.665, 0.1, 0.16, "y", BRASS, "Metal")
				end
			end
			r:block(-2.5, 0.8, -0.85, 2.5, 2.7, 0.68, wood, "Wood")
			r:block(-2.6, 2.7, -0.9, 2.6, 2.85, 0.78, wood, "Wood")
			-- cane fronted doors either side of three drawers
			local cane = Color3.fromRGB(216, 192, 150)
			for _, sx in { -1, 1 } do
				local xo, xi = sx * 2.44, sx * 0.86
				r:block(math.min(xo, xi), 0.88, 0.68, math.max(xo, xi), 2.62, 0.72, front, "Wood")
				local co, ci = sx * 2.24, sx * 1.06
				r:block(math.min(co, ci), 1.06, 0.72, math.max(co, ci), 2.44, 0.75, cane, "Fabric")
				r:piece(function(q: R)
					for i = 1, 3 do
						local x = co + (ci - co) * i / 4
						q:block(x - 0.02, 1.06, 0.75, x + 0.02, 2.44, 0.78, shade(cane, 0.82), "Fabric")
					end
					for i = 1, 5 do
						local y = 1.06 + 1.38 * i / 6
						q:block(
							math.min(co, ci),
							y - 0.02,
							0.75,
							math.max(co, ci),
							y + 0.02,
							0.78,
							shade(cane, 0.82),
							"Fabric"
						)
					end
				end)
				r:ball(sx * 0.98, 1.75, 0.77, 0.12, BRASS, "Metal")
			end
			for i = 0, 2 do
				local y1 = 0.88 + i * 0.6
				r:block(-0.8, y1, 0.68, 0.8, y1 + 0.54, 0.72, front, "Wood")
				r:block(-0.3, y1 + 0.23, 0.72, 0.3, y1 + 0.31, 0.76, BRASS, "Metal")
			end
			-- an old wooden radio with an arched top, a cloth grille, a dial and two knobs
			r:block(-1.85, 2.85, -0.55, -0.35, 3.55, 0.25, WALNUT, "Wood")
			r:cyl(-1.1, 3.55, -0.15, 0.8, 1.5, "z", WALNUT, "Wood")
			r:block(-1.55, 3.15, 0.25, -0.65, 3.6, 0.28, r.c2, "Fabric")
			r:cyl(-1.1, 3.6, 0.265, 0.03, 0.9, "z", r.c2, "Fabric")
			for _, x in { -1.35, -1.1, -0.85 } do
				r:block(x - 0.035, 3.15, 0.28, x + 0.035, 3.9, 0.31, shade(WALNUT, 0.8), "Wood")
			end
			r:block(-1.55, 2.95, 0.25, -0.65, 3.1, 0.28, Color3.fromRGB(240, 222, 180), "Wood")
			r:block(-1.2, 2.96, 0.28, -1.17, 3.09, 0.31, C.Red, "Wood")
			for _, x in { -1.69, -0.51 } do
				r:cyl(x, 3.02, 0.3, 0.1, 0.16, "z", shade(WALNUT, 0.7), "Wood")
			end
			-- two books with a photo on them, and a lace doily under a snake plant
			lyingBook(r, CFrame.new(0.4, 2.93, -0.1) * CFrame.Angles(0, 0.1, 0), 0.9, 0.62, 0.16, BOOKS[7])
			lyingBook(r, CFrame.new(0.42, 3.08, -0.12) * CFrame.Angles(0, -0.12, 0), 0.8, 0.56, 0.14, BOOKS[2])
			standingFrame(r, CFrame.new(0.4, 3.15, -0.25), 0.55, 0.7, BRASS, Color3.fromRGB(226, 196, 170))
			r:cyl(1.5, 2.865, 0, 0.03, 0.9, "y", LINEN, "Fabric")
			r:piece(function(q: R)
				q:box(1.5, 2.865, 0, 0.1, 0.03, 0.1, LINEN, "Fabric")
				for i = 0, 9 do
					local a = i * math.pi / 5
					q:cyl(1.5 + math.cos(a) * 0.45, 2.865, math.sin(a) * 0.45, 0.03, 0.18, "y", LINEN, "Fabric")
				end
			end)
			local s = pot(r, 1.5, 2.88, 0, 0.48, 0.42, CHINA)
			local blade = Color3.fromRGB(96, 140, 96)
			for i = 0, 5 do
				local a = i * 1.05
				r:boxAt(
					CFrame.new(1.5 + math.cos(a) * 0.08, s + 0.36 + (i % 3) * 0.08, math.sin(a) * 0.08)
						* CFrame.Angles(0, -a, 0)
						* CFrame.Angles(0, 0, 0.12),
					0.04,
					0.75 + (i % 3) * 0.15,
					0.12,
					if i % 2 == 0 then blade else mix(blade, C.Yellow, 0.25),
					"Wood"
				)
			end
		end,
	},
	{
		id = "cozy_side_table",
		name = "Skirted side table",
		cat = "tables",
		price = 65,
		place = "floor",
		size = V(2.2, 2.35, 2.2),
		c1 = "E9DFC8",
		c2 = "8E6440",
		tags = { "table" },
		surface = 2.3,
		style = "cozy",
		build = function(r: R)
			-- three turned legs with a round shelf low down
			for i = 0, 2 do
				local a = i * math.pi * 2 / 3 + math.pi / 2
				local x, z = math.cos(a) * 0.6, math.sin(a) * 0.6
				r:cyl(x, 0.8, z, 1.6, 0.14, "y", r.c2, "Wood")
				r:ball(x, 1.05, z, 0.22, r.c2, "Wood")
				r:ball(x, 0.09, z, 0.18, r.c2, "Wood")
			end
			r:cyl(0, 0.5, 0, 0.08, 1.4, "y", r.c2, "Wood")
			-- a cloth over the top, falling halfway down to a scalloped hem
			r:cyl(0, 1.95, 0, 0.7, 2.0, "y", r.c1, "Fabric")
			r:cyl(0, 1.73, 0, 0.08, 2.06, "y", shade(r.c1, 0.88), "Fabric")
			r:piece(function(q: R)
				q:box(0, 1.9, 0, 0.1, 0.1, 0.1, r.c1, "Fabric")
				for i = 0, 15 do
					local a = i * math.pi / 8
					q:ball(math.cos(a) * 0.98, 1.6, math.sin(a) * 0.98, 0.2, r.c1, "Fabric")
				end
			end)
			-- on the shelf: two books and a basket of yarn
			lyingBook(r, CFrame.new(-0.12, 0.6, 0.12) * CFrame.Angles(0, 0.3, 0), 0.7, 0.5, 0.12, BOOKS[4])
			lyingBook(r, CFrame.new(-0.1, 0.72, 0.1) * CFrame.Angles(0, -0.1, 0), 0.6, 0.44, 0.12, BOOKS[1])
			r:cyl(0.3, 0.68, -0.3, 0.28, 0.5, "y", WICKER, "Fabric")
			r:cyl(0.3, 0.76, -0.3, 0.06, 0.54, "y", shade(WICKER, 0.82), "Fabric")
			r:ball(0.24, 0.88, -0.36, 0.26, DUSK, "Fabric")
			r:ball(0.38, 0.86, -0.22, 0.22, MUSTARD, "Fabric")
		end,
	},
	{
		id = "cozy_blanket_basket",
		name = "Blanket basket",
		cat = "storage",
		price = 60,
		place = "floor",
		size = V(2.2, 2.6, 2.2),
		c1 = "C9A574",
		c2 = "C98B86",
		tags = { "storage" },
		style = "cozy",
		build = function(r: R)
			-- a round basket of woven staves with bands round it and rope handles
			r:cyl(0, 0.8, 0, 1.5, 1.7, "y", shade(r.c1, 0.6), "Fabric")
			r:piece(function(q: R)
				q:box(0, 0.8, 0, 0.1, 0.1, 0.1, r.c1, "Fabric")
				for i = 0, 15 do
					local a = i * math.pi / 8
					q:boxAt(
						CFrame.new(math.cos(a) * 0.92, 0.8, math.sin(a) * 0.92) * CFrame.Angles(0, -a, 0),
						0.08,
						1.5,
						0.32,
						if i % 2 == 0 then r.c1 else shade(r.c1, 0.92),
						"Fabric"
					)
				end
			end)
			for _, y in { 0.3, 0.65, 1.0, 1.35 } do
				r:cyl(0, y, 0, 0.12, 2.0, "y", shade(r.c1, 0.84), "Fabric")
			end
			r:cyl(0, 1.58, 0, 0.14, 2.06, "y", shade(r.c1, 0.8), "Fabric")
			r:cyl(0, 1.665, 0, 0.03, 1.8, "y", shade(r.c1, 0.45), "Fabric")
			local rope = Color3.fromRGB(214, 196, 160)
			for _, sx in { -1, 1 } do
				local pts =
					{ V(sx * 1.0, 1.3, -0.3), V(sx * 1.1, 1.62, -0.18), V(sx * 1.1, 1.62, 0.18), V(sx * 1.0, 1.3, 0.3) }
				for i = 1, 3 do
					rod(r, pts[i], pts[i + 1], 0.08, rope, "Fabric")
				end
			end
			-- three rolled blankets standing in it, their ends rolled in a spiral
			for _, b in
				{ { -0.35, 0.18, 0.62, 2.35, r.c2 }, { 0.38, 0.22, 0.56, 2.1, LINEN }, { 0.0, -0.4, 0.58, 2.5, SAGE } } :: { { any } }
			do
				local x, z, d, top, col = b[1], b[2], b[3], b[4], b[5]
				r:cyl(x, (1.68 + top) / 2, z, top - 1.68, d, "y", col, "Fabric")
				r:cyl(x, top + 0.015, z, 0.03, d * 0.62, "y", shade(col, 0.82), "Fabric")
				r:cyl(x, top + 0.045, z, 0.03, d * 0.28, "y", col, "Fabric")
			end
			-- a knitted throw over the front of the rim
			r:block(-0.5, 1.65, 0.6, 0.5, 1.72, 1.12, KNIT, "Fabric")
			r:block(-0.5, 0.75, 1.07, 0.5, 1.72, 1.12, KNIT, "Fabric")
			for _, y in { 0.95, 1.25 } do
				r:block(-0.5, y, 1.12, 0.5, y + 0.08, 1.15, ROSE, "Fabric")
			end
			for i = 0, 4 do
				r:cyl(-0.4 + i * 0.2, 0.69, 1.095, 0.12, 0.05, "y", KNIT, "Fabric")
			end
		end,
	},
	{
		id = "cozy_tea_set",
		name = "Tea set",
		gives = "tea", -- holding E gives something (Data/Items.Sources)
		cat = "kitchen",
		price = 40,
		place = "surface",
		size = V(2.6, 1.1, 1.6),
		c1 = "C98B86",
		c2 = "F2EDE4",
		tags = { "kitchen" },
		style = "cozy",
		build = function(r: R)
			local china = r.c2
			-- a wooden tray with raised ends and hand holds
			r:block(-1.25, 0, -0.75, 1.25, 0.06, 0.75, WALNUT, "Wood")
			r:piece(function(q: R)
				for _, sz in { -1, 1 } do
					q:block(
						-1.19,
						0.06,
						math.min(sz * 0.69, sz * 0.75),
						1.19,
						0.14,
						math.max(sz * 0.69, sz * 0.75),
						WALNUT,
						"Wood"
					)
				end
				for _, sx in { -1, 1 } do
					q:block(
						math.min(sx * 1.19, sx * 1.25),
						0.06,
						-0.75,
						math.max(sx * 1.19, sx * 1.25),
						0.32,
						0.75,
						WALNUT,
						"Wood"
					)
				end
			end)
			for _, sx in { -1, 1 } do
				r:block(
					math.min(sx * 1.25, sx * 1.28),
					0.18,
					-0.25,
					math.max(sx * 1.25, sx * 1.28),
					0.25,
					0.25,
					SOOT,
					"Wood"
				)
			end
			-- a teapot in a knitted cosy with a pompom, its spout and handle poking out
			r:lump(CFrame.new(-0.45, 0.48, 0), 0.86, 0.84, 0.86, r.c1, "Fabric")
			r:cyl(-0.45, 0.13, 0, 0.14, 0.92, "y", shade(r.c1, 0.85), "Fabric")
			for _, y in { 0.4, 0.58 } do
				r:cyl(-0.45, y, 0, 0.06, 0.92, "y", C.Cream, "Fabric")
			end
			r:ball(-0.45, 0.95, 0, 0.22, LINEN, "Fabric")
			rod(r, V(-0.8, 0.35, 0), V(-1.05, 0.55, 0), 0.1, china, "Marble")
			rod(r, V(-0.06, 0.6, 0), V(0.1, 0.58, 0), 0.06, china, "Marble")
			rod(r, V(0.1, 0.6, 0), V(0.1, 0.3, 0), 0.06, china, "Marble")
			rod(r, V(0.1, 0.32, 0), V(-0.04, 0.28, 0), 0.06, china, "Marble")
			-- two cups on saucers, a milk jug and a sugar bowl with its spoon
			local band = Color3.fromRGB(110, 146, 182)
			for _, cup in { { 0.45, 0.3 }, { 0.85, -0.35 } } do
				local x, z = cup[1], cup[2]
				r:cyl(x, 0.08, z, 0.04, 0.38, "y", china, "Marble")
				r:cyl(x, 0.2, z, 0.2, 0.26, "y", china, "Marble")
				r:cyl(x, 0.22, z, 0.03, 0.32, "y", band, "Marble")
				r:block(x + 0.13, 0.14, z - 0.025, x + 0.2, 0.26, z + 0.025, china, "Marble")
			end
			r:cyl(0.92, 0.2, 0.38, 0.28, 0.24, "y", china, "Marble")
			r:block(0.76, 0.28, 0.36, 0.8, 0.34, 0.4, china, "Marble")
			r:block(1.04, 0.14, 0.36, 1.08, 0.3, 0.4, china, "Marble")
			r:lump(CFrame.new(0.35, 0.16, -0.4), 0.32, 0.2, 0.32, china, "Marble")
			r:cyl(0.35, 0.27, -0.4, 0.04, 0.24, "y", band, "Marble")
			r:boxAt(CFrame.new(0.45, 0.33, -0.38) * CFrame.Angles(0, 0.2, -0.5), 0.28, 0.025, 0.04, C.Metal, "Metal")
		end,
	},
	{
		id = "cozy_candle_jars",
		name = "Candle jars",
		cat = "lights",
		price = 30,
		place = "surface",
		size = V(1.8, 1.0, 1.0),
		c1 = "B48A60",
		c2 = "F2E6CF",
		tags = { "light" },
		style = "cozy",
		build = function(r: R)
			-- a little tray with three glass jars, a candle burning in each
			r:block(-0.85, 0, -0.45, 0.85, 0.06, 0.45, r.c1, "Wood")
			r:piece(function(q: R)
				for _, sz in { -1, 1 } do
					q:block(
						-0.85,
						0.06,
						math.min(sz * 0.4, sz * 0.45),
						0.85,
						0.12,
						math.max(sz * 0.4, sz * 0.45),
						r.c1,
						"Wood"
					)
				end
				for _, sx in { -1, 1 } do
					q:block(
						math.min(sx * 0.8, sx * 0.85),
						0.06,
						-0.4,
						math.max(sx * 0.8, sx * 0.85),
						0.12,
						0.4,
						r.c1,
						"Wood"
					)
				end
			end)
			local jars = { { -0.45, 0.05, 0.5, 0.42 }, { 0.1, -0.08, 0.82, 0.4 }, { 0.55, 0.12, 0.38, 0.36 } }
			for i, j in jars do
				local x, z, h, d = j[1], j[2], j[3], j[4]
				local g = r:cyl(x, 0.06 + h / 2, z, h, d, "y", Color3.fromRGB(226, 236, 232), "Glass")
				g.transp = 0.55
				local hc = h * 0.55
				r:cyl(x, 0.06 + hc / 2, z, hc, d - 0.1, "y", r.c2, "Plaster")
				r:cyl(x, 0.06 + hc + 0.03, z, 0.06, 0.02, "y", INK, "Metal")
				local flame = r:ball(x, 0.06 + hc + 0.1, z, 0.08, C.Warm, "Glass")
				if i == 2 then
					r:glow(flame, 10, 0.9)
				else
					glowOnly(flame)
				end
			end
			-- twine round the tall one, tied in a bow
			local twine = Color3.fromRGB(190, 160, 120)
			r:cyl(0.1, 0.36, -0.08, 0.05, 0.46, "y", twine, "Fabric")
			for _, s in { -1, 1 } do
				r:boxAt(
					CFrame.new(0.1 + s * 0.06, 0.37, 0.17) * CFrame.Angles(0, 0, s * 0.5),
					0.1,
					0.06,
					0.03,
					twine,
					"Fabric"
				)
			end
			-- pebbles and a sprig of eucalyptus round the jars
			for _, p in { { -0.7, 0.3 }, { -0.12, 0.3 }, { 0.3, -0.3 }, { 0.72, -0.25 }, { -0.68, -0.3 } } do
				r:lump(CFrame.new(p[1], 0.1, p[2]) * CFrame.Angles(0, p[1], 0), 0.14, 0.08, 0.11, C.Stone, "Rock")
			end
			local euc = Color3.fromRGB(140, 170, 156)
			rod(r, V(-0.15, 0.08, 0.32), V(0.55, 0.08, 0.36), 0.025, euc, "Grass")
			for i = 0, 4 do
				local x = -0.05 + i * 0.14
				r:lump(CFrame.new(x, 0.085, 0.34 + (if i % 2 == 0 then 0.04 else -0.04)), 0.1, 0.02, 0.1, euc, "Grass")
			end
		end,
	},
	{
		id = "cozy_mug_shelf",
		name = "Mug shelf",
		cat = "kitchen",
		price = 50,
		place = "wall",
		size = V(3.4, 2.2, 0.95),
		c1 = "DCD2C0",
		c2 = "9DB3A2",
		tags = { "storage" },
		style = "cozy",
		build = function(r: R)
			local wood = r.c1
			-- a back rail with a scalloped edge, a shelf on two shaped brackets
			r:block(-1.6, 0.9, 0, 1.6, 1.5, 0.08, wood, "Wood")
			r:piece(function(q: R)
				q:box(0, 0.95, 0.04, 0.1, 0.1, 0.08, wood, "Wood")
				for i = 0, 9 do
					q:cyl(-1.44 + i * 0.32, 0.9, 0.04, 0.08, 0.22, "z", wood, "Wood")
				end
			end)
			r:block(-1.7, 1.5, 0, 1.7, 1.6, 0.86, wood, "Wood")
			r:cyl(0, 1.55, 0.86, 3.4, 0.1, "x", wood, "Wood")
			for _, sx in { -1, 1 } do
				r:tri(V(sx * 1.3, 1.5, 0.08), V(sx * 1.3, 0.92, 0.08), V(sx * 1.3, 1.5, 0.7), 0.1, r.c2, "Wood")
			end
			-- tins for tea and coffee, a sugar jar, a plant and two plates on the shelf
			local tins: { { any } } = {
				{ -1.15, Color3.fromRGB(150, 176, 150) },
				{ -0.6, Color3.fromRGB(226, 210, 180) },
				{ -0.05, Color3.fromRGB(196, 120, 110) },
			}
			for _, t in tins do
				r:cyl(t[1], 1.85, 0.45, 0.5, 0.42, "y", t[2], "Metal")
				r:cyl(t[1], 2.13, 0.45, 0.06, 0.46, "y", shade(t[2], 0.8), "Metal")
				r:block(t[1] - 0.08, 1.76, 0.66, t[1] + 0.08, 1.92, 0.69, C.Paper, "Cardboard")
			end
			local soil = pot(r, 0.62, 1.6, 0.45, 0.4, 0.3, CLAY)
			leafTuft(r, 0.62, soil, 0.45, 0.75, 31)
			for i = 0, 1 do
				r:cyl(1.2 + i * 0.12, 1.98, 0.22 + i * 0.06, 0.05, 0.7, "z", if i == 0 then C.White else r.c2, "Marble")
			end
			-- four mugs hung by their handles from brass cup hooks
			local mugs = { DUSK, ROSE, MUSTARD, SAGE }
			for i, x in { -1.2, -0.4, 0.4, 1.2 } do
				local col = mugs[i]
				rod(r, V(x - 0.03, 1.5, 0.55), V(x - 0.03, 1.15, 0.55), 0.04, BRASS, "Metal")
				r:cyl(x + 0.22, 1.08, 0.55, 0.38, 0.34, "y", col, "Marble")
				r:cyl(x + 0.22, 1.13, 0.55, 0.04, 0.38, "y", C.White, "Marble")
				r:block(x - 0.06, 1.17, 0.52, x + 0.06, 1.22, 0.58, col, "Marble")
				r:block(x - 0.06, 0.97, 0.52, x - 0.01, 1.22, 0.58, col, "Marble")
				r:block(x - 0.06, 0.97, 0.52, x + 0.06, 1.02, 0.58, col, "Marble")
			end
		end,
	},
	{
		id = "cozy_floor_cushions",
		name = "Floor cushions",
		cat = "seating",
		price = 90,
		place = "floor",
		size = V(5.2, 1.6, 2.6),
		c1 = "C98B86",
		c2 = "93AABB",
		tags = { "seat" },
		style = "cozy",
		build = function(r: R)
			-- two stacks of fat square cushions, buttoned, with tassels at the corners
			local function stack(cx: number, lower: Color3, upper: Color3)
				for k, col in { lower, upper } do
					local y = (k - 1) * 0.55
					cushion(r, cx - 1.0, y, -1.0, cx + 1.0, y + 0.55, 1.0, col)
					local tassel = mix(col, C.Cream, 0.3)
					for _, sx in { -1, 1 } do
						for _, sz in { -1, 1 } do
							local a, b = V(cx + sx * 0.97, y + 0.28, sz * 0.72), V(cx + sx * 1.1, y + 0.24, sz * 0.84)
							rod(r, a, b, 0.05, tassel, "Fabric")
							r:ball(b.X, b.Y, b.Z, 0.09, tassel, "Fabric")
						end
					end
				end
				for _, b in { { 0, 0 }, { -0.45, -0.45 }, { 0.45, -0.45 }, { -0.45, 0.45 }, { 0.45, 0.45 } } do
					r:ball(cx + b[1], 1.1, b[2], 0.1, shade(upper, 0.72), "Fabric")
				end
			end
			stack(-1.55, mix(r.c1, C.Cream, 0.35), r.c1)
			stack(1.55, mix(r.c2, C.Cream, 0.35), r.c2)
			-- a knitted throw folded on one and a bolster behind the other
			r:block(1.1, 1.1, -0.6, 2.2, 1.22, 0.5, KNIT, "Fabric")
			r:block(1.4, 1.22, -0.6, 1.52, 1.25, 0.5, ROSE, "Fabric")
			r:cyl(-1.55, 1.4, -0.75, 1.9, 0.6, "x", MUSTARD, "Fabric")
			for _, sx in { -1, 1 } do
				r:cyl(-1.55 + sx * 0.97, 1.4, -0.75, 0.04, 0.34, "x", shade(MUSTARD, 0.8), "Fabric")
			end
			-- a little round tray table between them with a cup of tea
			for i = 0, 2 do
				local a = i * math.pi * 2 / 3 + math.pi / 2
				rod(
					r,
					V(math.cos(a) * 0.22, 0.8, -0.2 + math.sin(a) * 0.22),
					V(math.cos(a) * 0.34, 0, -0.2 + math.sin(a) * 0.34),
					0.08,
					WALNUT,
					"Wood"
				)
			end
			r:cyl(0, 0.84, -0.2, 0.08, 0.95, "y", WALNUT, "Wood")
			r:cyl(0, 0.89, -0.2, 0.02, 0.9, "y", shade(WALNUT, 1.15), "Wood")
			r:cyl(0.1, 0.92, -0.1, 0.04, 0.34, "y", CHINA, "Marble")
			r:cyl(0.1, 1.03, -0.1, 0.18, 0.24, "y", CHINA, "Marble")
			r:block(0.22, 0.97, -0.125, 0.28, 1.08, -0.075, CHINA, "Marble")
			r:seat(-1.55, 1.1, 0.15)
			r:seat(1.55, 1.1, 0.15)
		end,
	},
	{
		id = "cozy_linen_cupboard",
		name = "Linen cupboard",
		cat = "bath",
		price = 200,
		place = "floor",
		size = V(2.6, 6.6, 1.6),
		c1 = "DCD5C6",
		c2 = "9DB3A2",
		tags = { "bath", "storage" },
		style = "cozy",
		build = function(r: R)
			local paint = r.c1
			-- a tall painted cupboard on bun feet
			for _, sx in { -1, 1 } do
				for _, sz in { -1, 1 } do
					r:ball(sx * 1.0, 0.15, sz * 0.55, 0.3, shade(paint, 0.9), "Wood")
				end
			end
			r:block(-1.28, 0.25, -0.78, 1.28, 0.45, 0.68, paint, "Wood")
			for _, sx in { -1, 1 } do
				r:block(
					math.min(sx * 1.12, sx * 1.25),
					0.45,
					-0.75,
					math.max(sx * 1.12, sx * 1.25),
					5.8,
					0.6,
					paint,
					"Wood"
				)
			end
			r:block(-1.12, 0.45, -0.75, 1.12, 5.8, -0.65, shade(paint, 0.9), "Wood")
			r:block(-1.32, 5.8, -0.8, 1.32, 5.95, 0.72, paint, "Wood")
			r:block(-1.25, 5.95, -0.75, 1.25, 6.05, 0.66, paint, "Wood")
			for _, y in { 1.5, 4.3 } do
				r:block(-1.12, y - 0.1, -0.65, 1.12, y, 0.55, paint, "Wood")
			end
			r:block(-1.12, 2.3, 0.5, 1.12, 3.0, 0.6, paint, "Wood")
			r:block(-1.12, 2.3, -0.65, 1.12, 2.4, 0.5, paint, "Wood")
			-- a drawer, and a glazed door over stacks of folded towels
			r:block(-1.08, 2.38, 0.6, 1.08, 2.9, 0.68, shade(paint, 1.05), "Wood")
			r:ball(0, 2.64, 0.72, 0.12, BRASS, "Metal")
			r:piece(function(q: R)
				q:block(-1.1, 3.0, 0.6, 1.1, 3.15, 0.68, shade(paint, 1.05), "Wood")
				q:block(-1.1, 5.55, 0.6, 1.1, 5.7, 0.68, shade(paint, 1.05), "Wood")
				q:block(-1.1, 3.15, 0.6, -0.95, 5.55, 0.68, shade(paint, 1.05), "Wood")
				q:block(0.95, 3.15, 0.6, 1.1, 5.55, 0.68, shade(paint, 1.05), "Wood")
				q:block(-0.025, 3.15, 0.64, 0.025, 5.55, 0.67, shade(paint, 1.05), "Wood")
				q:block(-0.95, 4.33, 0.64, 0.95, 4.38, 0.67, shade(paint, 1.05), "Wood")
			end)
			r:glass(-0.95, 3.15, 0.61, 0.95, 5.55, 0.63)
			r:ball(0.85, 4.1, 0.72, 0.1, BRASS, "Metal")
			local towels = { r.c2, LINEN, ROSE, DUSK, mix(r.c2, C.Cream, 0.5), MUSTARD }
			local k = 0
			for _, y0 in { 3.0, 4.3 } do
				for _, x in { -0.52, 0.52 } do
					for j = 0, 2 do
						k += 1
						local col = towels[1 + k % #towels]
						local y = y0 + j * 0.2
						r:block(x - 0.42, y, -0.55, x + 0.42, y + 0.18, 0.32, col, "Fabric")
						r:cyl(x, y + 0.09, 0.32, 0.84, 0.18, "x", col, "Fabric")
					end
				end
			end
			-- open below: bottles of bath salts on a shelf and a basket of rolled towels
			for i, b in { { -0.7, DUSK }, { -0.3, ROSE }, { 0.15, SAGE } } :: { { any } } do
				local h = 0.4 + (i % 2) * 0.12
				r:cyl(b[1], 1.5 + h / 2, -0.1, h, 0.26, "y", b[2], "Glass")
				r:cyl(b[1], 1.5 + h + 0.06, -0.1, 0.12, 0.14, "y", Color3.fromRGB(176, 140, 100), "Wood")
			end
			r:block(0.4, 1.5, -0.4, 1.0, 1.62, 0.3, C.White, "Fabric")
			r:block(0.43, 1.62, -0.38, 0.97, 1.74, 0.28, ROSE, "Fabric")
			basket(r, -0.95, 0.95, 0.45, -0.5, 0.45, 0.72)
			for i, x in { -0.5, 0.0, 0.5 } do
				local col = towels[i + 1]
				r:cyl(x, 1.33, -0.05, 0.9, 0.42, "z", col, "Fabric")
				r:cyl(x, 1.33, 0.415, 0.03, 0.26, "z", shade(col, 0.82), "Fabric")
			end
			-- a plant and a candle on top
			local s = pot(r, -0.5, 6.05, 0, 0.36, 0.28, CLAY)
			leafTuft(r, -0.5, s, 0, 0.7, 17)
			r:cyl(0.5, 6.2, 0.05, 0.3, 0.26, "y", C.Cream, "Plaster")
			r:cyl(0.5, 6.37, 0.05, 0.04, 0.02, "y", INK, "Metal")
		end,
	},
	{
		id = "cozy_cuckoo",
		name = "Cuckoo clock",
		cat = "walldecor",
		price = 90,
		place = "wall",
		size = V(1.8, 3.9, 0.8),
		c1 = "8E6440",
		c2 = "F2EBDD",
		tags = { "clock" },
		style = "cozy",
		build = function(r: R)
			local wood = r.c1
			local dk = shade(wood, 0.75)
			-- a little house: a body, a shelf under it, a pitched roof and a carved bird on top
			r:block(-0.6, 1.8, 0, 0.6, 3.1, 0.55, wood, "Wood")
			r:block(-0.72, 1.7, 0, 0.72, 1.8, 0.62, dk, "Wood")
			r:tri(V(-0.6, 3.1, 0.275), V(0.6, 3.1, 0.275), V(0, 3.52, 0.275), 0.55, wood, "Wood")
			for _, sx in { -1, 1 } do
				r:boxAt(
					CFrame.new(sx * 0.41, 3.32, 0.33) * CFrame.Angles(0, 0, -sx * 0.632),
					1.05,
					0.08,
					0.72,
					dk,
					"Wood"
				)
			end
			r:lump(CFrame.new(0, 3.72, 0.3), 0.32, 0.2, 0.18, dk, "Wood")
			r:ball(0.13, 3.82, 0.3, 0.14, dk, "Wood")
			r:boxAt(CFrame.new(-0.2, 3.76, 0.3) * CFrame.Angles(0, 0, 0.5), 0.2, 0.05, 0.14, dk, "Wood")
			-- the bird door, open, with the bird looking out
			r:block(-0.13, 2.84, 0.55, 0.13, 3.06, 0.58, INK, "Metal")
			r:boxAt(CFrame.new(-0.24, 2.95, 0.66) * CFrame.Angles(0, 1.2, 0), 0.26, 0.24, 0.03, dk, "Wood")
			r:ball(0, 2.95, 0.64, 0.14, MUSTARD, "Wood")
			r:block(-0.02, 2.93, 0.7, 0.02, 2.96, 0.76, Color3.fromRGB(220, 130, 70), "Wood")
			-- the clock face with ticks, two hands and a pin, in a brass bezel
			r:cyl(0, 2.35, 0.565, 0.03, 0.9, "z", BRASS, "Metal")
			r:cyl(0, 2.35, 0.58, 0.06, 0.8, "z", r.c2, "Wood")
			r:piece(function(q: R)
				for i = 0, 11 do
					local a = i * math.pi / 6
					local long = i % 3 == 0
					q:boxAt(
						CFrame.new(math.sin(a) * 0.31, 2.35 + math.cos(a) * 0.31, 0.625) * CFrame.Angles(0, 0, -a),
						if long then 0.04 else 0.025,
						if long then 0.1 else 0.06,
						0.03,
						INK,
						"Metal"
					)
				end
			end, nil, "Metal")
			r:boxAt(CFrame.new(0.06, 2.42, 0.655) * CFrame.Angles(0, 0, -0.7), 0.04, 0.2, 0.03, INK, "Metal")
			r:boxAt(CFrame.new(-0.08, 2.47, 0.685) * CFrame.Angles(0, 0, 0.55), 0.03, 0.28, 0.03, INK, "Metal")
			r:cyl(0, 2.35, 0.7, 0.04, 0.06, "z", BRASS, "Metal")
			-- carved leaves round the face
			for _, p in { { -0.45, 2.75 }, { 0.45, 2.75 }, { -0.45, 1.95 }, { 0.45, 1.95 } } do
				r:lump(CFrame.new(p[1], p[2], 0.58) * CFrame.Angles(0, 0, p[1] * p[2]), 0.26, 0.14, 0.08, dk, "Wood")
			end
			-- two chains down to pine cone weights, and a pendulum with a leaf for a bob
			local bronze = Color3.fromRGB(120, 92, 60)
			for _, w in { { -0.28, 0.45 }, { 0.28, 0.8 } } do
				local x, y = w[1], w[2]
				r:cyl(x, (1.7 + y + 0.42) / 2, 0.3, 1.7 - y - 0.42, 0.03, "y", BRASS, "Metal")
				r:lump(CFrame.new(x, y + 0.2, 0.3), 0.2, 0.44, 0.2, bronze, "Metal")
				for k = 0, 2 do
					r:cyl(x, y + 0.08 + k * 0.12, 0.3, 0.04, 0.22, "y", shade(bronze, 0.8), "Metal")
				end
				r:cyl(x, y + 0.44, 0.3, 0.05, 0.08, "y", BRASS, "Metal")
			end
			r:cyl(0, 1.1, 0.36, 1.2, 0.04, "y", BRASS, "Metal")
			r:lump(CFrame.new(0, 0.42, 0.36), 0.3, 0.38, 0.05, dk, "Wood")
		end,
	},
}

return items
