--!strict
-- Shelves, dressers, wardrobes and other places to keep things.
-- c1 is the body, c2 the fronts, a top or the things kept inside.
--
-- Nothing here lies flat on another face: a front stands at least 0.03 proud of what it is on,
-- so no two faces share a plane and flicker (z-fighting).

local Recipe = require(script.Parent.Parent.Recipe)
local Colors = require(script.Parent.Parent.Parent.Util.Colors)

local C = Recipe.Colors

type R = Recipe.Recipe

local function shade(c: Color3, k: number): Color3
	return Colors.shade(c, k)
end

-- Book covers: soft, a little dusty, never a primary colour.
local BOOK_COLOURS = {
	Color3.fromRGB(154, 90, 82), -- brick
	Color3.fromRGB(94, 122, 150), -- dusty blue
	Color3.fromRGB(126, 154, 122), -- sage
	Color3.fromRGB(201, 166, 94), -- mustard
	Color3.fromRGB(138, 111, 144), -- plum
	Color3.fromRGB(222, 211, 188), -- cream
	Color3.fromRGB(185, 122, 94), -- terracotta
	Color3.fromRGB(79, 107, 92), -- forest
	Color3.fromRGB(90, 85, 96), -- charcoal
	Color3.fromRGB(168, 138, 106), -- tan
	Color3.fromRGB(110, 140, 168), -- slate
	Color3.fromRGB(184, 102, 92), -- rose
}
local GILT = Color3.fromRGB(214, 190, 132)

-- A little random number source, the same every time for the same seed.
local function rng(seed: number): () -> number
	local s = seed
	return function(): number
		s = (s * 1103515245 + 12345) % 2147483648
		return s / 2147483648
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

type Box = { cf: CFrame, size: Vector3, color: Color3 }

-- Draws boxes as pieces of at most 24 shapes, each starting with a box that isn't turned.
local function pieces(r: R, boxes: { Box })
	local upright: { Box } = {}
	local turned: { Box } = {}
	for _, b in boxes do
		local _, _, _, a, _, _, _, e, _, _, _, k = b.cf:GetComponents()
		if math.abs(a - 1) < 1e-4 and math.abs(e - 1) < 1e-4 and math.abs(k - 1) < 1e-4 then
			table.insert(upright, b)
		else
			table.insert(turned, b)
		end
	end
	local chunks: { { Box } } = {}
	local cur: { Box } = {}
	local function flush()
		if #cur > 0 then
			table.insert(chunks, cur)
			cur = {}
		end
	end
	for _, b in upright do
		table.insert(cur, b)
		if #cur >= 24 then
			flush()
		end
	end
	for _, b in turned do
		if #cur == 0 then
			-- a piece has to start with a box that isn't turned: borrow one from the last chunk
			local last = chunks[#chunks]
			if last and #last > 1 then
				table.insert(cur, table.remove(last, 1) :: Box)
			end
		end
		table.insert(cur, b)
		if #cur >= 24 then
			flush()
		end
	end
	flush()
	for _, chunk in chunks do
		r:piece(function(q: R)
			for _, b in chunk do
				q:boxAt(b.cf, b.size.X, b.size.Y, b.size.Z, b.color, "SmoothPlastic")
			end
		end)
	end
end

-- A shelf of books between x1 and x2 standing on y, at most maxH tall, between zb (the back)
-- and zf (the front): thin upright spines of different heights and colours, a few with a gilt
-- band, now and then a run of a set, one leaning on the end and sometimes a few lying flat.
-- `flat` is "left", "right" or "none" (the seed decides when it is nil).
local function shelfBooks(
	r: R,
	x1: number,
	x2: number,
	y: number,
	maxH: number,
	zb: number,
	zf: number,
	seed: number,
	flat: string?
)
	local rand = rng(seed)
	local boxes: { Box } = {}
	local depth = zf - zb
	local function pick(not1: Color3?): Color3
		local col = BOOK_COLOURS[1 + math.floor(rand() * #BOOK_COLOURS)]
		if col == not1 then
			col = BOOK_COLOURS[1 + (table.find(BOOK_COLOURS, col) :: number) % #BOOK_COLOURS]
		end
		return col
	end
	-- a few books lying flat at one end
	local side = flat or (if rand() < 0.35 then "none" elseif rand() < 0.5 then "left" else "right")
	local lo, hi = x1, x2
	if side ~= "none" and x2 - x1 > 1.4 then
		local fw = math.min(0.86, maxH * 0.8)
		local fx = if side == "left" then x1 + fw / 2 + 0.03 else x2 - fw / 2 - 0.03
		local fy = y
		local n = 2 + math.floor(rand() * 3)
		local prev: Color3? = nil
		for i = 1, n do
			local t = 0.1 + rand() * 0.07
			local w = fw * (0.86 + rand() * 0.14) - (i - 1) * 0.03
			local d = depth * (0.62 + rand() * 0.2)
			local col = pick(prev)
			prev = col
			local cf = CFrame.new(fx + (rand() - 0.5) * 0.06, fy + t / 2, zb + 0.04 + d / 2 + rand() * 0.06)
			if i > 1 then
				cf *= CFrame.Angles(0, (rand() - 0.5) * 0.18, 0)
			end
			table.insert(boxes, { cf = cf, size = Vector3.new(w, t, d), color = col })
			fy += t
		end
		if side == "left" then
			lo = x1 + fw + 0.1
		else
			hi = x2 - fw - 0.1
		end
	end
	-- the upright run, leaving room for one leaning book at the free end
	local leanLeft = side == "left" or (side == "none" and rand() < 0.5)
	local leanRoom = 0.5
	local runLo, runHi = lo, hi
	if leanLeft then
		runLo = lo + leanRoom
	else
		runHi = hi - leanRoom
	end
	local x = runLo
	local prev: Color3? = nil
	local setLeft, setCol, setH = 0, prev, 0
	local edgeH = maxH
	local firstH = maxH
	while x < runHi - 0.1 do
		local t = 0.075 + rand() * 0.1
		if x + t > runHi then
			break
		end
		local h, col
		if setLeft > 0 then
			setLeft -= 1
			h, col = setH, setCol :: Color3
		else
			h = maxH * (0.6 + rand() * 0.38)
			col = pick(prev)
			if rand() < 0.15 then
				-- a set of three or four with matching spines
				setLeft = 2 + math.floor(rand() * 2)
				setCol, setH = col, h
			end
		end
		prev = col
		local d = depth * (0.7 + rand() * 0.24)
		local back = zb + 0.03 + rand() * math.max(0, depth - d - 0.04)
		local cf = CFrame.new(x + t / 2, y + h / 2, back + d / 2)
		table.insert(boxes, { cf = cf, size = Vector3.new(t, h, d), color = col })
		if setLeft > 0 or rand() < 0.3 then
			-- a band round the spine near the top (it stands 0.025 proud all round)
			local band = if setLeft > 0 then GILT else Colors.mix(col, C.Paper, 0.55)
			table.insert(boxes, {
				cf = CFrame.new(x + t / 2, y + h * 0.8, back + d / 2),
				size = Vector3.new(t + 0.05, 0.05, d + 0.05),
				color = band,
			})
		end
		if x == runLo then
			firstH = h
		end
		edgeH = h
		x += t + (if rand() < 0.1 then 0.04 else 0.004)
	end
	-- the leaning book, its top resting on the end of the run
	local lt = 0.12 + rand() * 0.06
	local a = 0.28 + rand() * 0.16
	local touch = if leanLeft then firstH else edgeH
	local lh = math.min(maxH * (0.62 + rand() * 0.3), touch * 0.97 / math.cos(a))
	local ld = depth * (0.72 + rand() * 0.2)
	local lz = zb + 0.04 + ld / 2
	local col = pick(prev)
	if leanLeft then
		-- pivots on its bottom right corner, leaning right onto the run
		local xb = runLo - lh * math.sin(a) - 0.01
		if xb - lt * math.cos(a) >= lo - 0.02 then
			local cf = CFrame.new(
				xb - lt / 2 * math.cos(a) + lh / 2 * math.sin(a),
				y + lt / 2 * math.sin(a) + lh / 2 * math.cos(a),
				lz
			) * CFrame.Angles(0, 0, -a)
			table.insert(boxes, { cf = cf, size = Vector3.new(lt, lh, ld), color = col })
		end
	else
		-- pivots on its bottom left corner, leaning left onto the run
		local xb = x + lh * math.sin(a) + 0.01
		if xb + lt * math.cos(a) <= hi + 0.02 then
			local cf = CFrame.new(
				xb + lt / 2 * math.cos(a) - lh / 2 * math.sin(a),
				y + lt / 2 * math.sin(a) + lh / 2 * math.cos(a),
				lz
			) * CFrame.Angles(0, 0, a)
			table.insert(boxes, { cf = cf, size = Vector3.new(lt, lh, ld), color = col })
		end
	end
	pieces(r, boxes)
end

-- A fabric bin from (x1, y1, z1) to (x2, y2, z2): a folded rim round the top and a dark hand hole
-- in the front.
local function bin(r: R, x1: number, y1: number, z1: number, x2: number, y2: number, z2: number, color: Color3)
	r:block(x1, y1, z1, x2, y2 - 0.16, z2, color, "Fabric")
	r:block(x1 - 0.03, y2 - 0.16, z1 - 0.03, x2 + 0.03, y2, z2 + 0.03, shade(color, 0.88), "Fabric")
	local xm = (x1 + x2) / 2
	r:block(xm - 0.24, y2 - 0.42, z2, xm + 0.24, y2 - 0.28, z2 + 0.03, shade(color, 0.45), "Fabric")
end

-- A potted plant on a shelf at (x, y, z): a pot with a rim, soil and a few leafy clumps.
local function pottedPlant(r: R, x: number, y: number, z: number, size: number, pot: Color3?)
	local col = pot or Color3.fromRGB(226, 220, 208)
	r:cyl(x, y + size * 0.25, z, size * 0.5, size * 0.52, "y", col, "SmoothPlastic")
	r:cyl(x, y + size * 0.55, z, size * 0.12, size * 0.62, "y", shade(col, 0.92), "SmoothPlastic")
	r:cyl(x, y + size * 0.52, z, size * 0.1, size * 0.44, "y", C.Soil, "Sand")
	r:lump(
		CFrame.new(x, y + size * 0.8, z) * CFrame.Angles(0.3, 0.5, 0.2),
		size * 0.7,
		size * 0.45,
		size * 0.66,
		C.Leaf,
		"Grass"
	)
	r:lump(
		CFrame.new(x + size * 0.2, y + size * 1.02, z - size * 0.08) * CFrame.Angles(0.5, 0.2, 0.7),
		size * 0.42,
		size * 0.36,
		size * 0.4,
		C.DarkLeaf,
		"Grass"
	)
	r:lump(
		CFrame.new(x - size * 0.26, y + size * 0.72, z + size * 0.14) * CFrame.Angles(0.2, 1.1, -0.6),
		size * 0.4,
		size * 0.22,
		size * 0.3,
		shade(C.Leaf, 1.12),
		"Grass"
	)
end

-- A drawer front on the face at z, with a raised panel and a bar pull on two posts (two pulls
-- on a wide one).
local function drawer(r: R, x1: number, y1: number, x2: number, y2: number, z: number, color: Color3)
	r:block(x1, y1, z, x2, y2, z + 0.06, color, "Wood")
	r:block(x1 + 0.12, y1 + 0.1, z + 0.06, x2 - 0.12, y2 - 0.1, z + 0.1, shade(color, 1.05), "Wood")
	local ym = (y1 + y2) / 2
	local pulls: { number } = { (x1 + x2) / 2 }
	if x2 - x1 > 2.4 then
		pulls = { x1 + (x2 - x1) * 0.25, x1 + (x2 - x1) * 0.75 }
	end
	for _, xm in pulls do
		r:piece(function(q: R)
			q:block(xm - 0.3, ym - 0.035, z + 0.16, xm + 0.3, ym + 0.035, z + 0.21, C.Gold, "Metal")
			for _, s in { -1, 1 } do
				q:block(
					xm + s * 0.24 - 0.03,
					ym - 0.03,
					z + 0.1,
					xm + s * 0.24 + 0.03,
					ym + 0.03,
					z + 0.16,
					C.Gold,
					"Metal"
				)
			end
		end)
	end
end

-- A panelled door on the face at z: a frame, a raised middle panel with a moulding round it,
-- a long bar handle on one side and two hinges on the other.
local function door(r: R, x1: number, y1: number, x2: number, y2: number, z: number, color: Color3, handleX: number)
	r:block(x1, y1, z, x2, y2, z + 0.06, color, "Wood")
	r:block(x1 + 0.2, y1 + 0.22, z + 0.06, x2 - 0.2, y2 - 0.22, z + 0.09, shade(color, 0.88), "Wood")
	r:block(x1 + 0.28, y1 + 0.3, z + 0.09, x2 - 0.28, y2 - 0.3, z + 0.13, shade(color, 1.04), "Wood")
	local hl = math.min(1.2, (y2 - y1) * 0.3)
	local ym = (y1 + y2) / 2
	r:block(handleX - 0.04, ym - hl / 2, z + 0.12, handleX + 0.04, ym + hl / 2, z + 0.17, C.Gold, "Metal")
	local hingeX = if math.abs(handleX - x1) < math.abs(handleX - x2) then x2 else x1
	for _, hy in { y1 + 0.5, y2 - 0.5 } do
		r:block(hingeX - 0.04, hy - 0.16, z - 0.02, hingeX + 0.04, hy + 0.16, z + 0.1, C.Gold, "Metal")
	end
end

-- A small framed photo standing on a shelf at (x, y, z), turned by yaw.
local function photo(r: R, x: number, y: number, z: number, yaw: number, w: number, h: number, picture: Color3)
	local cf = CFrame.new(x, y + h / 2 * math.cos(0.15) + 0.04, z) * CFrame.Angles(-0.15, yaw, 0)
	r:boxAt(cf, w, h, 0.08, Color3.fromRGB(70, 56, 48), "Wood")
	r:boxAt(cf * CFrame.new(0, 0, 0.03), w - 0.14, h - 0.14, 0.08, C.Paper, "SmoothPlastic")
	r:boxAt(cf * CFrame.new(0, 0.03, 0.06), w - 0.3, h - 0.34, 0.08, picture, "SmoothPlastic")
	r:boxAt(
		cf * CFrame.new(0, -h * 0.25, 0.09),
		w - 0.38,
		(h - 0.34) * 0.4,
		0.08,
		shade(picture, 0.72),
		"SmoothPlastic"
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
		id = "bookshelf",
		name = "Bookshelf",
		cat = "storage",
		price = 120,
		place = "floor",
		size = Vector3.new(3.6, 6.4, 1.6),
		c1 = "AD7E55",
		c2 = "D9C7A7",
		tags = { "books", "storage" },
		build = function(r: R)
			local dk = shade(r.c1, 0.85)
			-- the case: sides, a top with a cove under a deeper cornice, a kick board, a back
			r:block(-1.8, 0, -0.8, -1.62, 6.05, 0.75, r.c1, "Wood")
			r:block(1.62, 0, -0.8, 1.8, 6.05, 0.75, r.c1, "Wood")
			r:block(-1.8, 6.05, -0.8, 1.8, 6.17, 0.75, r.c1, "Wood")
			r:block(-1.84, 6.17, -0.8, 1.84, 6.25, 0.79, shade(r.c1, 0.93), "Wood")
			r:block(-1.88, 6.25, -0.8, 1.88, 6.4, 0.83, dk, "Wood")
			r:block(-1.62, 0, -0.7, 1.62, 0.42, 0.7, dk, "Wood")
			r:block(-1.62, 0.42, -0.8, 1.62, 6.05, -0.7, shade(r.c1, 0.7), "Wood")
			-- shelves, each with a lip along its front
			for _, y in { 0.42, 1.88, 3.33, 4.78 } do
				r:block(-1.62, y, -0.7, 1.62, y + 0.14, 0.7, r.c1, "Wood")
				r:block(-1.62, y - 0.02, 0.7, 1.62, y + 0.14, 0.74, shade(r.c1, 0.94), "Wood")
			end
			-- two fabric bins at the bottom
			for _, x in { -0.8, 0.8 } do
				bin(r, x - 0.7, 0.56, -0.55, x + 0.7, 1.62, 0.6, r.c2)
			end
			-- books, a plant, a photo and a few odds and ends
			shelfBooks(r, -1.58, 0.5, 2.02, 1.22, -0.68, 0.66, 11, "none")
			pottedPlant(r, 1.05, 2.02, 0.02, 0.9)
			photo(r, -1.0, 3.47, 0.05, 0.2, 0.8, 0.95, Color3.fromRGB(134, 170, 196))
			shelfBooks(r, -0.42, 1.58, 3.47, 1.22, -0.68, 0.66, 7, "right")
			shelfBooks(r, -1.58, 0.32, 4.92, 1.06, -0.68, 0.66, 5, "left")
			-- a lidded box with a little vase on it
			r:block(0.42, 4.92, -0.42, 1.42, 5.2, 0.38, Color3.fromRGB(110, 140, 168), "SmoothPlastic")
			r:block(0.39, 5.2, -0.45, 1.45, 5.3, 0.41, shade(Color3.fromRGB(110, 140, 168), 0.88), "SmoothPlastic")
			r:cyl(0.92, 5.45, -0.02, 0.3, 0.32, "y", Color3.fromRGB(208, 138, 108), "SmoothPlastic")
			r:cyl(0.92, 5.66, -0.02, 0.12, 0.16, "y", Color3.fromRGB(208, 138, 108), "SmoothPlastic")
			r:cyl(0.92, 5.75, -0.02, 0.06, 0.24, "y", shade(Color3.fromRGB(208, 138, 108), 0.9), "SmoothPlastic")
		end,
	},
	{
		id = "dresser",
		name = "Dresser",
		cat = "storage",
		price = 150,
		place = "floor",
		size = Vector3.new(4, 3.4, 1.8),
		surface = 3.4,
		c1 = "8FB39A",
		c2 = "C99A62",
		tags = { "storage" },
		build = function(r: R)
			for _, sx in { -1, 1 } do
				for _, sz in { -1, 1 } do
					rod(
						r,
						Vector3.new(sx * 1.65, 0.6, sz * 0.62),
						Vector3.new(sx * 1.72, 0, sz * 0.68),
						0.18,
						r.c2,
						"Wood"
					)
					r:cyl(sx * 1.715, 0.07, sz * 0.675, 0.14, 0.24, "y", C.Gold, "Metal")
				end
			end
			-- a carcass with corner posts, a skirt rail and a top with a softened edge
			r:block(-1.84, 0.56, -0.8, 1.84, 3.22, 0.8, r.c1, "Wood")
			for _, sx in { -1, 1 } do
				r:block(sx * 1.88 - 0.08, 0.6, -0.84, sx * 1.88 + 0.08, 3.22, 0.84, shade(r.c1, 0.94), "Wood")
			end
			r:block(-1.8, 0.5, -0.76, 1.8, 0.6, 0.86, shade(r.c2, 0.85), "Wood")
			r:block(-1.96, 3.22, -0.88, 1.96, 3.28, 0.88, shade(r.c2, 0.88), "Wood")
			r:block(-2, 3.28, -0.9, 2, 3.4, 0.9, r.c2, "Wood")
			-- three rows of drawers, two to a row
			local front = shade(r.c1, 1.06)
			for _, y in { { 0.68, 1.46 }, { 1.54, 2.3 }, { 2.38, 3.14 } } do
				drawer(r, -1.76, y[1], -0.04, y[2], 0.8, front)
				drawer(r, 0.04, y[1], 1.76, y[2], 0.8, front)
			end
		end,
	},
	{
		id = "wardrobe",
		name = "Wardrobe",
		cat = "storage",
		price = 220,
		place = "floor",
		size = Vector3.new(4, 7.2, 2.2),
		c1 = "AD7E55",
		c2 = "C99A62",
		tags = { "storage" },
		build = function(r: R)
			local dk = shade(r.c1, 0.85)
			-- a plinth with bun feet, the case, and a crown in three steps
			for _, sx in { -1, 1 } do
				for _, sz in { -1, 1 } do
					r:cyl(sx * 1.7, 0.1, sz * 0.72, 0.2, 0.36, "y", dk, "Wood")
				end
			end
			r:block(-1.9, 0.2, -0.95, 1.9, 0.44, 0.92, dk, "Wood")
			r:block(-1.92, 0.44, -1.0, 1.92, 6.8, 0.98, r.c1, "Wood")
			r:block(-1.96, 6.8, -1.03, 1.96, 6.9, 1.02, shade(r.c1, 0.94), "Wood")
			r:block(-1.99, 6.9, -1.06, 1.99, 6.98, 1.06, r.c1, "Wood")
			r:block(-2, 6.98, -1.08, 2, 7.2, 1.1, dk, "Wood")
			-- two tall panelled doors over a wide drawer, a keyhole between the handles
			door(r, -1.82, 1.6, -0.03, 6.7, 0.98, r.c2, -0.2)
			door(r, 0.03, 1.6, 1.82, 6.7, 0.98, r.c2, 0.2)
			drawer(r, -1.82, 0.52, 1.82, 1.5, 0.98, r.c2)
			r:block(-0.05, 4.65, 1.04, 0.05, 4.85, 1.08, C.Gold, "Metal")
		end,
	},
	{
		id = "cabinet",
		name = "Sideboard",
		cat = "storage",
		price = 140,
		place = "floor",
		size = Vector3.new(4.4, 2.8, 1.8),
		surface = 2.8,
		c1 = "5C7FA3",
		c2 = "C99A62",
		tags = { "storage" },
		build = function(r: R)
			for _, sx in { -1, 1 } do
				for _, sz in { -1, 1 } do
					rod(
						r,
						Vector3.new(sx * 1.85, 0.62, sz * 0.6),
						Vector3.new(sx * 1.98, 0, sz * 0.7),
						0.18,
						r.c2,
						"Wood"
					)
					r:cyl(sx * 1.975, 0.07, sz * 0.695, 0.14, 0.24, "y", C.Gold, "Metal")
				end
			end
			r:block(-2.1, 0.55, -0.85, 2.1, 2.62, 0.85, r.c1, "Wood")
			r:block(-2.16, 2.62, -0.88, 2.16, 2.68, 0.88, shade(r.c2, 0.88), "Wood")
			r:block(-2.2, 2.68, -0.9, 2.2, 2.8, 0.9, r.c2, "Wood")
			r:block(-2.04, 0.5, -0.82, 2.04, 0.58, 0.9, shade(r.c2, 0.85), "Wood")
			-- two fluted doors with a pair of drawers between them
			local front = shade(r.c1, 1.08)
			for _, sx in { -1, 1 } do
				local xa, xb = sx * 0.72, sx * 2.0
				local x1, x2 = math.min(xa, xb), math.max(xa, xb)
				r:block(x1, 0.66, 0.85, x2, 2.52, 0.91, front, "Wood")
				r:piece(function(q: R)
					for k = 1, 6 do
						local x = x1 + 0.1 + k * (x2 - x1 - 0.2) / 7
						q:block(x - 0.035, 0.78, 0.91, x + 0.035, 2.4, 0.95, shade(front, 0.84), "Wood")
					end
				end)
				r:cyl(sx * 0.88, 1.6, 0.97, 0.12, 0.16, "z", C.Gold, "Metal")
				r:ball(sx * 0.88, 1.6, 1.05, 0.12, C.Gold, "Metal")
			end
			drawer(r, -0.62, 0.66, 0.62, 1.55, 0.85, front)
			drawer(r, -0.62, 1.63, 0.62, 2.52, 0.85, front)
		end,
	},
	{
		id = "toy_chest",
		name = "Toy chest",
		cat = "storage",
		price = 90,
		place = "floor",
		size = Vector3.new(3.2, 2.4, 1.9),
		c1 = "7FB8D9",
		c2 = "F7F3EA",
		tags = { "toy", "storage" },
		build = function(r: R)
			local wall = 0.12
			local lidCol = shade(r.c1, 0.88)
			-- an open box: a plinth, four walls and a floor, with painted corner strips
			r:block(-1.52, 0, -0.87, 1.52, 0.14, 0.87, r.c2, "Wood")
			r:block(-1.5, 0.14, -0.85, 1.5, 0.3, 0.85, r.c1, "Wood")
			r:block(-1.5, 0.3, 0.85 - wall, 1.5, 1.5, 0.85, r.c1, "Wood")
			r:block(-1.5, 0.3, -0.85, 1.5, 1.5, -0.85 + wall, r.c1, "Wood")
			for _, sx in { -1, 1 } do
				local xo, xi = sx * 1.5, sx * (1.5 - wall)
				r:block(math.min(xo, xi), 0.3, -0.85 + wall, math.max(xo, xi), 1.5, 0.85 - wall, r.c1, "Wood")
				-- a painted strip down each corner, a little proud of both faces and of the rim
				for _, sz in { -1, 1 } do
					local xa, xb = sx * 1.38, sx * 1.53
					local za, zb = sz * 0.73, sz * 0.88
					r:block(
						math.min(xa, xb),
						0.14,
						math.min(za, zb),
						math.max(xa, xb),
						1.53,
						math.max(za, zb),
						r.c2,
						"Wood"
					)
				end
			end
			r:block(-1.38, 1.22, 0.85, 1.38, 1.36, 0.88, r.c2, "Wood")
			-- painted letter blocks on the front
			local cols = { Color3.fromRGB(184, 102, 92), C.Yellow, Color3.fromRGB(126, 154, 122) }
			for i, col in cols do
				local x = -0.9 + (i - 1) * 0.9
				r:block(x - 0.32, 0.42, 0.85, x + 0.32, 1.06, 0.89, col, "SmoothPlastic")
				r:block(x - 0.13, 0.6, 0.89, x + 0.13, 0.88, 0.92, C.White, "SmoothPlastic")
			end
			-- rope handles on the ends
			for _, sx in { -1, 1 } do
				for _, z in { -0.28, 0.28 } do
					r:block(sx * 1.5 - 0.02 * sx, 0.95, z - 0.05, sx * 1.58, 1.08, z + 0.05, C.DarkMetal, "Metal")
				end
				r:cyl(sx * 1.57, 0.92, 0, 0.62, 0.1, "z", C.Cream, "Fabric")
			end
			-- toys heaped inside, up to just under the lid
			local inside = 1.3
			r:block(-1.38, 0.3, -0.73, 1.38, inside, 0.73, shade(r.c1, 0.6), "Wood")
			r:ball(0.72, inside + 0.2, 0.22, 0.6, Color3.fromRGB(184, 102, 92), "Plastic")
			r:cyl(0.72, inside + 0.2, 0.22, 0.08, 0.64, "x", C.White, "Plastic")
			local blocks: { { x: number, z: number, turn: number, col: Color3 } } = {
				{ x = -0.62, z = 0.3, turn = 0.25, col = C.Yellow },
				{ x = -0.25, z = -0.2, turn = 0.6, col = Color3.fromRGB(126, 154, 122) },
				{ x = -0.05, z = 0.42, turn = -0.3, col = Color3.fromRGB(94, 122, 150) },
			}
			for _, b in blocks do
				local cf = CFrame.new(b.x, inside + 0.17, b.z) * CFrame.Angles(0.15, b.turn, 0.12)
				r:boxAt(cf, 0.36, 0.36, 0.36, b.col, "Wood")
				r:boxAt(cf * CFrame.new(0, 0, 0.18), 0.16, 0.16, 0.06, C.White, "Wood")
				r:boxAt(cf * CFrame.new(0, 0.18, 0), 0.16, 0.06, 0.16, C.White, "Wood")
			end
			-- a teddy peeping out at the back, lower than the lid
			local bear = Color3.fromRGB(176, 130, 88)
			r:ball(0.25, inside + 0.2, -0.32, 0.5, bear, "Fabric")
			r:ball(0.25, inside + 0.14, -0.1, 0.22, Color3.fromRGB(233, 211, 176), "Fabric")
			for _, sx in { -1, 1 } do
				r:ball(0.25 + sx * 0.2, inside + 0.4, -0.36, 0.18, bear, "Fabric")
				r:ball(0.25 + sx * 0.09, inside + 0.27, -0.1, 0.06, C.Black, "SmoothPlastic")
			end
			-- a skipping rope over the right hand side, one handle in and one hanging out
			local rope = C.Cream
			local grip = Color3.fromRGB(184, 102, 92)
			r:cyl(1.2, inside + 0.12, 0.3, 0.32, 0.1, "x", grip, "Plastic")
			rod(r, Vector3.new(1.36, inside + 0.12, 0.3), Vector3.new(1.45, 1.56, 0.25), 0.04, rope, "Fabric")
			rod(r, Vector3.new(1.45, 1.56, 0.25), Vector3.new(1.58, 1.42, 0.15), 0.04, rope, "Fabric")
			rod(r, Vector3.new(1.58, 1.42, 0.15), Vector3.new(1.58, 0.76, 0.05), 0.04, rope, "Fabric")
			r:cyl(1.58, 0.6, 0.05, 0.32, 0.1, "y", grip, "Plastic")
			-- the lid, propped open on a wooden block wedged under its front
			local hinge = CFrame.new(0, 1.5, -0.85) * CFrame.Angles(-0.4, 0, 0)
			r:boxAt(hinge * CFrame.new(0, 0.12, 0.88), 3.12, 0.24, 1.76, lidCol, "Wood")
			r:boxAt(hinge * CFrame.new(0, 0.12, 1.79), 3.16, 0.3, 0.06, r.c2, "Wood")
			for _, sx in { -1, 1 } do
				r:boxAt(hinge * CFrame.new(sx * 1.2, 0.08, -0.04), 0.3, 0.14, 0.14, C.Gold, "Metal")
			end
			r:block(-1.22, 1.5, 0.42, -0.82, 2.02, 0.8, Color3.fromRGB(201, 166, 94), "Wood")
		end,
	},
	{
		id = "shelf_cubes",
		name = "Cube shelf",
		cat = "storage",
		price = 110,
		place = "floor",
		size = Vector3.new(3.4, 4.8, 1.5),
		surface = 4.8,
		c1 = "F7F3EA",
		c2 = "D08A6C",
		tags = { "storage" },
		build = function(r: R)
			local t = 0.15
			-- outer box, a middle divider and two shelves: six cubbies
			r:block(-1.7, 0, -0.75, -1.7 + t, 4.8, 0.75, r.c1, "Wood")
			r:block(1.7 - t, 0, -0.75, 1.7, 4.8, 0.75, r.c1, "Wood")
			r:block(-1.7 + t, 4.8 - t, -0.75, 1.7 - t, 4.8, 0.75, r.c1, "Wood")
			r:block(-1.7 + t, 0, -0.75, 1.7 - t, 0.2, 0.75, r.c1, "Wood")
			r:block(-t / 2, 0.2, -0.65, t / 2, 4.65, 0.75, r.c1, "Wood")
			r:block(-1.55, 0.2, -0.75, 1.55, 4.65, -0.65, shade(r.c1, 0.85), "Wood")
			for _, y in { 1.68, 3.17 } do
				r:block(-1.55, y - t / 2, -0.65, -t / 2, y + t / 2, 0.75, r.c1, "Wood")
				r:block(t / 2, y - t / 2, -0.65, 1.55, y + t / 2, 0.75, r.c1, "Wood")
			end
			-- fabric bins in three, books in two and a plant in the last
			for _, p in { { -0.8, 0.2 }, { 0.8, 1.755 }, { 0.8, 0.2 } } do
				local x, y = p[1], p[2]
				local col = if p[2] > 1 then Colors.mix(r.c2, C.Cream, 0.4) else r.c2
				bin(r, x - 0.62, y + 0.02, -0.55, x + 0.62, y + 1.3, 0.62, col)
			end
			shelfBooks(r, -1.52, -0.1, 1.755, 1.22, -0.63, 0.66, 9, "none")
			shelfBooks(r, 0.1, 1.52, 3.245, 1.16, -0.63, 0.66, 21, "right")
			pottedPlant(r, -0.8, 3.245, 0, 0.85, Color3.fromRGB(208, 138, 108))
		end,
	},
	{
		id = "coat_stand",
		name = "Coat stand",
		cat = "storage",
		price = 50,
		place = "floor",
		size = Vector3.new(1.8, 6, 1.8),
		c1 = "6E4C34",
		c2 = "B8505A",
		tags = { "storage" },
		build = function(r: R)
			-- three splayed feet round a turned pole
			for i = 0, 2 do
				local a = i * math.pi * 2 / 3 + math.pi / 2
				local dx, dz = math.cos(a), math.sin(a)
				rod(
					r,
					Vector3.new(dx * 0.08, 1.0, dz * 0.08),
					Vector3.new(dx * 0.78, 0.04, dz * 0.78),
					0.14,
					r.c1,
					"Wood"
				)
				r:cyl(dx * 0.78, 0.04, dz * 0.78, 0.08, 0.2, "y", shade(r.c1, 0.7), "Wood")
			end
			r:cyl(0, 3.1, 0, 5.4, 0.22, "y", r.c1, "Wood")
			r:cyl(0, 1.0, 0, 0.2, 0.34, "y", shade(r.c1, 0.85), "Wood")
			r:cyl(0, 4.95, 0, 0.14, 0.32, "y", shade(r.c1, 0.85), "Wood")
			r:ball(0, 5.85, 0, 0.32, r.c1, "Wood")
			for i = 0, 3 do
				local a = i * math.pi / 2
				local dx, dz = math.cos(a), math.sin(a)
				rod(
					r,
					Vector3.new(dx * 0.08, 5.15, dz * 0.08),
					Vector3.new(dx * 0.52, 5.55, dz * 0.52),
					0.09,
					r.c1,
					"Wood"
				)
				r:ball(dx * 0.54, 5.57, dz * 0.54, 0.14, C.Gold, "Metal")
			end
			-- a coat hung by its collar on the hook at +x: its back to the pole, the front facing out
			local coat = r.c2
			local dkc = shade(coat, 0.82)
			r:block(0.16, 3.15, -0.42, 0.46, 4.62, 0.42, coat, "Fabric")
			r:block(0.18, 4.62, -0.3, 0.46, 5.02, 0.3, coat, "Fabric")
			for _, sz in { -1, 1 } do
				r:tri(
					Vector3.new(0.31, 4.62, sz * 0.3),
					Vector3.new(0.31, 5.02, sz * 0.3),
					Vector3.new(0.31, 4.62, sz * 0.44),
					0.28,
					coat,
					"Fabric"
				)
				-- a sleeve hanging down each side with a darker cuff
				r:cyl(0.3, 4.0, sz * 0.5, 1.2, 0.22, "y", coat, "Fabric")
				r:cyl(0.3, 3.32, sz * 0.5, 0.16, 0.28, "y", dkc, "Fabric")
				-- a lapel and a pocket flap
				r:tri(
					Vector3.new(0.48, 4.95, sz * 0.05),
					Vector3.new(0.48, 4.25, sz * 0.03),
					Vector3.new(0.48, 4.95, sz * 0.26),
					0.04,
					dkc,
					"Fabric"
				)
				r:block(0.46, 3.72, sz * 0.22 - 0.13, 0.5, 3.8, sz * 0.22 + 0.13, dkc, "Fabric")
			end
			r:block(0.2, 5.02, -0.2, 0.44, 5.2, 0.2, dkc, "Fabric")
			r:block(0.46, 3.15, -0.02, 0.5, 4.25, 0.02, dkc, "Fabric")
			for _, y in { 4.05, 3.7, 3.35 } do
				r:cyl(0.5, y, -0.08, 0.04, 0.08, "x", C.Gold, "Metal")
			end
			-- a striped scarf over the hook at +z, its two ends hanging at different lengths
			local scarf = C.Yellow
			r:cyl(0, 5.5, 0.54, 0.32, 0.18, "x", scarf, "Fabric")
			r:block(-0.15, 4.2, 0.6, 0.15, 5.5, 0.66, scarf, "Fabric")
			r:block(-0.15, 4.7, 0.42, 0.15, 5.5, 0.48, scarf, "Fabric")
			for _, y in { 4.5, 4.9 } do
				r:block(-0.18, y - 0.05, 0.57, 0.18, y + 0.05, 0.69, C.White, "Fabric")
			end
			r:block(-0.18, 4.98, 0.39, 0.18, 5.08, 0.51, C.White, "Fabric")
			r:piece(function(q: R)
				for k = 0, 4 do
					local x = -0.12 + k * 0.06
					q:block(x - 0.012, 4.06, 0.615, x + 0.012, 4.2, 0.645, shade(scarf, 0.9), "Fabric")
				end
			end)
			-- a felt hat on the hook at -x
			local hat = C.Bark
			r:cyl(-0.55, 5.62, 0, 0.05, 0.72, "y", hat, "Fabric")
			r:cyl(-0.55, 5.8, 0, 0.3, 0.44, "y", hat, "Fabric")
			r:cyl(-0.55, 5.7, 0, 0.09, 0.5, "y", C.Cream, "Fabric")
			-- a closed umbrella hanging by its crook from the hook at -z
			local brolly = Color3.fromRGB(79, 107, 92)
			r:add({
				shape = "Cone",
				cf = CFrame.new(0, 4.55, -0.62) * CFrame.Angles(math.pi, 0, 0),
				size = Vector3.new(0.3, 1.3, 0.3),
				color = brolly,
				mat = "Fabric",
			})
			r:cyl(0, 5.32, -0.62, 0.26, 0.05, "y", C.DarkMetal, "Metal")
			r:cyl(0, 3.82, -0.62, 0.16, 0.04, "y", C.DarkMetal, "Metal")
			rod(r, Vector3.new(0, 5.42, -0.62), Vector3.new(0, 5.62, -0.6), 0.07, C.Bark, "Wood")
			rod(r, Vector3.new(0, 5.62, -0.6), Vector3.new(0, 5.62, -0.46), 0.07, C.Bark, "Wood")
			rod(r, Vector3.new(0, 5.62, -0.46), Vector3.new(0, 5.5, -0.42), 0.07, C.Bark, "Wood")
		end,
	},
	{
		id = "crate",
		name = "Crate",
		cat = "storage",
		price = 20,
		place = "floor",
		size = Vector3.new(2.2, 2, 2.2),
		surface = 2,
		c1 = "C99A62",
		c2 = "C99A62",
		tags = { "storage" },
		build = function(r: R)
			-- a packing crate: rough boards (c1) with gaps between them, a dark inside showing
			-- through, held by darker battens round every edge
			r:block(-0.92, 0.06, -0.92, 0.92, 1.86, 0.92, Color3.fromRGB(70, 54, 42), "Wood")
			r:piece(function(q: R)
				for i = 0, 2 do
					local y1 = 0.2 + i * 0.54
					local y2 = y1 + 0.5
					local col = if i == 1 then shade(r.c1, 0.93) else r.c1
					q:block(-0.9, y1, 0.92, 0.9, y2, 1.0, col, "WoodPlanks")
					q:block(-0.9, y1, -1.0, 0.9, y2, -0.92, col, "WoodPlanks")
					q:block(0.92, y1, -0.9, 1.0, y2, 0.9, col, "WoodPlanks")
					q:block(-1.0, y1, -0.9, -0.92, y2, 0.9, col, "WoodPlanks")
				end
				for i = 0, 3 do
					local x1 = -0.9 + i * 0.45 + 0.02
					q:block(
						x1,
						1.86,
						-0.9,
						x1 + 0.41,
						1.94,
						0.9,
						if i % 2 == 0 then r.c1 else shade(r.c1, 0.95),
						"WoodPlanks"
					)
				end
			end, true)
			local batten = Color3.fromRGB(122, 90, 62)
			r:piece(function(q: R)
				for _, y in { 0.1, 1.9 } do
					q:block(-1.1, y - 0.1, -1.1, 1.1, y + 0.1, -0.9, batten, "Wood")
					q:block(-1.1, y - 0.1, 0.9, 1.1, y + 0.1, 1.1, batten, "Wood")
					q:block(-1.1, y - 0.1, -0.9, -0.9, y + 0.1, 0.9, batten, "Wood")
					q:block(0.9, y - 0.1, -0.9, 1.1, y + 0.1, 0.9, batten, "Wood")
				end
				for _, sx in { -1, 1 } do
					for _, sz in { -1, 1 } do
						q:box(sx * 1, 1, sz * 1, 0.2, 1.6, 0.2, batten, "Wood")
					end
				end
				-- a brace across the front and the back
				q:beam(Vector3.new(-0.9, 0.25, 1.04), Vector3.new(0.9, 1.75, 1.04), 0.08, 0.2, batten, "Wood")
				q:beam(Vector3.new(0.9, 0.25, -1.04), Vector3.new(-0.9, 1.75, -1.04), 0.08, 0.2, batten, "Wood")
			end, true)
			-- nail heads on the battens and a shipping label on one side
			r:piece(function(q: R)
				for _, sx in { -1, 1 } do
					for _, y in { 0.1, 1.9 } do
						q:block(sx * 0.6 - 0.03, y - 0.03, 1.1, sx * 0.6 + 0.03, y + 0.03, 1.13, C.DarkMetal, "Metal")
						q:block(1.1, y - 0.03, sx * 0.6 - 0.03, 1.13, y + 0.03, sx * 0.6 + 0.03, C.DarkMetal, "Metal")
					end
				end
			end)
			r:block(1.0, 0.85, -0.35, 1.03, 1.3, 0.3, C.Paper, "SmoothPlastic")
			r:block(1.03, 1.12, -0.25, 1.06, 1.2, 0.18, Color3.fromRGB(184, 102, 92), "SmoothPlastic")
		end,
	},
}

return items
