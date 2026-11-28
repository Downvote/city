--!strict
-- What a food shop is fitted out with: a glass case of cakes, a rack of loaves, shelves of tins,
-- a stand of fruit, a freezer of ice cream tubs, a booth to sit in, a board for the pavement, a
-- hatch to serve through, and signs with a picture on them. The ready-made grocer's, café,
-- bakery and ice cream parlour (Data/Buildings) are furnished with these, and each is on sale by
-- itself in Build mode.
-- Floor pieces face +z, the side a customer stands. c1 is the body, c2 the trim.

local Recipe = require(script.Parent.Parent.Recipe)
local Colors = require(script.Parent.Parent.Parent.Util.Colors)

local C = Recipe.Colors

type R = Recipe.Recipe

-- Food and paint, kept soft: nothing here is a pure hue (the town's palette, docs/GAME_DESIGN).
local CRUST = Color3.fromRGB(214, 166, 104)
local CRUST_DARK = Color3.fromRGB(178, 126, 76)
local WAFER = Color3.fromRGB(226, 184, 124)
local ORANGE = Color3.fromRGB(226, 150, 96)
local APPLE = Color3.fromRGB(196, 84, 84)
local LEMON = Color3.fromRGB(232, 200, 104)
local CABBAGE = Color3.fromRGB(132, 176, 112)
local CHOC = Color3.fromRGB(128, 94, 72)
local MINT = Color3.fromRGB(176, 220, 196)
local VANILLA = Color3.fromRGB(250, 238, 210)
local STRAWBERRY = Color3.fromRGB(232, 168, 178)
local LILAC = Color3.fromRGB(190, 172, 214)
local BERRY = Color3.fromRGB(184, 80, 90)
local NAVY = Color3.fromRGB(70, 96, 142)
local MUSTARD = Color3.fromRGB(217, 169, 63)
local FOREST = Color3.fromRGB(78, 127, 98)
local IRON = Color3.fromRGB(90, 85, 96)
local PALE_WOOD = Color3.fromRGB(221, 190, 148)

local function shade(c: Color3, k: number): Color3
	return Colors.shade(c, k)
end

-- A pane of glass at any frame.
local function glassAt(r: R, cf: CFrame, sx: number, sy: number, sz: number)
	local p = r:boxAt(cf, sx, sy, sz, C.Glass, "Glass")
	p.transp = 0.55
	p.collide = false
end

-- A loaf lying along x at (x, y, z): y is what it lies on.
local function loaf(r: R, x: number, y: number, z: number, len: number, turn: number?)
	local cf = CFrame.new(x, y + 0.26, z) * CFrame.Angles(0, math.rad(turn or 0), 0)
	r:lump(cf, len, 0.56, 0.66, CRUST, "Sand")
end

-- Produce, drawn into a piece at a frame (the middle of the fruit): apples have a stalk and now
-- and then a leaf, oranges a little green star, lemons a point at each end, and a cabbage is a
-- pale heart with dark leaves cupped round it. (The market stall in Recipes/Work draws the same.)
local STALK = Color3.fromRGB(108, 82, 56)
local LEAF_DARK = Color3.fromRGB(112, 160, 98)
local function apple(q: R, at: CFrame, col: Color3, leaf: boolean)
	local p = at.Position
	q:ball(p.X, p.Y, p.Z, 0.42, col)
	q:boxAt(at * CFrame.new(0.02, 0.23, 0) * CFrame.Angles(0, 0, -0.35), 0.05, 0.16, 0.05, STALK)
	if leaf then
		q:lump(at * CFrame.new(0.12, 0.24, 0.02) * CFrame.Angles(0.2, 0, -0.7), 0.2, 0.05, 0.11, C.Leaf)
	end
end

local function orange(q: R, at: CFrame)
	q:lump(at, 0.48, 0.44, 0.48, ORANGE)
	q:boxAt(at * CFrame.new(0, 0.22, 0) * CFrame.Angles(0, math.rad(45), 0), 0.12, 0.04, 0.12, C.DarkLeaf)
end

local function lemon(q: R, at: CFrame)
	q:lump(at, 0.46, 0.34, 0.34, LEMON)
	q:lump(at * CFrame.new(0.24, 0, 0), 0.12, 0.12, 0.12, shade(LEMON, 0.92))
end

local function cabbage(q: R, at: CFrame, turn: number)
	q:lump(at * CFrame.Angles(0, turn, 0), 0.62, 0.56, 0.62, Color3.fromRGB(176, 206, 140))
	for k = 0, 2 do
		local a = turn + k * math.pi * 2 / 3
		local leaf = at * CFrame.Angles(0, a, 0) * CFrame.new(0, -0.04, 0.26) * CFrame.Angles(-0.5, 0, 0)
		q:lump(leaf, 0.5, 0.42, 0.14, LEAF_DARK)
	end
end

-- A board for a wall sign: w by h, its bottom edge at y = 0, hung flat on the wall from two iron
-- hooks. c1 is the board and c2 the moulding round it. The picture goes on at z = FACE.
local FACE = 0.22
local function signBoard(r: R, w: number, h: number)
	r:block(-w / 2 + 0.12, 0.12, 0.04, w / 2 - 0.12, h - 0.12, FACE, r.c1, "Wood")
	r:piece(function(q: R)
		q:block(-w / 2, 0, 0.02, w / 2, 0.2, 0.3, r.c2, "Wood")
		q:block(-w / 2, h - 0.2, 0.02, w / 2, h, 0.3, r.c2, "Wood")
		q:block(-w / 2, 0.2, 0.02, -w / 2 + 0.2, h - 0.2, 0.3, r.c2, "Wood")
		q:block(w / 2 - 0.2, 0.2, 0.02, w / 2, h - 0.2, 0.3, r.c2, "Wood")
	end)
	r:piece(function(q: R)
		for _, x in { -w / 2 + 0.6, w / 2 - 0.6 } do
			q:block(x - 0.07, h, 0, x + 0.07, h + 0.3, 0.1, IRON, "Metal")
			q:block(x - 0.07, h - 0.1, 0.1, x + 0.07, h + 0.3, 0.2, IRON, "Metal")
		end
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
	opening: { w: number, h: number, sill: number }?,
	style: string?, -- the look it belongs to (Catalog.Styles)
	build: (r: R) -> (),
}

local items: { Item } = {
	{
		id = "display_case",
		name = "Cake display case",
		cat = "kitchen",
		price = 240,
		place = "floor",
		size = Vector3.new(4, 4.3, 2.4),
		c1 = "FAF6EC",
		c2 = "9A6B48",
		tags = { "kitchen" },
		build = function(r: R)
			-- a counter with glass round its top half: the glass faces the customer and the back
			-- is open for whoever serves. Two shelves of cakes, buns and tarts.
			r:block(-2, 0, -1.1, 2, 0.3, 0.9, shade(r.c1, 0.55), "Wood")
			r:block(-2, 0.3, -1.2, 2, 1.7, 1.1, r.c1, "Wood")
			r:block(-1.7, 0.6, 1.1, 1.7, 1.4, 1.14, shade(r.c1, 0.9), "Wood")
			r:block(-2, 1.7, -1.2, 2, 1.86, 1.15, r.c2, "Wood")
			r:piece(function(q: R)
				q:block(-2, 4.0, -1.2, 2, 4.18, 1.15, r.c2, "Wood")
				for _, x in { -1.93, 1.93 } do
					q:block(x - 0.07, 1.86, 1.0, x + 0.07, 4.0, 1.14, r.c2, "Wood")
					q:block(x - 0.07, 1.86, -1.2, x + 0.07, 4.0, -1.06, r.c2, "Wood")
				end
			end)
			r:glass(-1.86, 1.86, 1.02, 1.86, 4.0, 1.1).collide = false
			r:glass(-1.98, 1.86, -1.06, -1.9, 4.0, 1.0).collide = false
			r:glass(1.9, 1.86, -1.06, 1.98, 4.0, 1.0).collide = false
			local shelf = r:block(-1.86, 2.9, -1.0, 1.86, 2.96, 0.95, C.White, "Glass")
			shelf.transp = 0.3
			-- the bottom shelf: a pink cake on a stand, a round of buns and a tart
			r:cyl(-1.1, 1.93, 0.1, 0.14, 1.2, "y", C.White, "Marble")
			r:cyl(-1.1, 2.25, 0.1, 0.5, 1.0, "y", STRAWBERRY, "Plaster")
			r:cyl(-1.1, 2.54, 0.1, 0.08, 1.02, "y", VANILLA, "Plaster")
			r:ball(-1.1, 2.68, 0.1, 0.24, APPLE, "Marble")
			for i, p in { { 0.05, 0.4 }, { 0.6, 0.45 }, { 0.3, -0.15 }, { 0.85, -0.1 } } do
				r:ball(p[1], 2.1, p[2], 0.5, if i % 2 == 0 then CRUST_DARK else CRUST, "Sand")
			end
			r:cyl(1.45, 1.96, 0.2, 0.2, 0.9, "y", CRUST, "Sand")
			r:cyl(1.45, 2.08, 0.2, 0.06, 0.7, "y", APPLE, "Marble")
			-- the top shelf: iced cakes in a row and a loaf
			for i, col in { STRAWBERRY, VANILLA, CHOC, MINT } do
				local x = -1.5 + (i - 1) * 0.6
				r:cyl(x, 3.1, 0.3, 0.28, 0.42, "y", WAFER, "Sand")
				r:ball(x, 3.32, 0.3, 0.46, col, "Plaster")
			end
			loaf(r, 1.05, 2.96, 0.2, 1.3, 12)
			r:cyl(-0.6, 3.04, -0.45, 0.16, 0.8, "y", CHOC, "Plaster")
			r:cyl(0.3, 3.04, -0.45, 0.16, 0.8, "y", VANILLA, "Plaster")
		end,
	},
	{
		id = "bread_rack",
		name = "Bread rack",
		cat = "storage",
		style = "rustic",
		price = 160,
		place = "floor",
		size = Vector3.new(4, 6.8, 1.8),
		c1 = "C49A6C",
		c2 = "9A6B48",
		tags = { "storage" },
		build = function(r: R)
			-- a baker's rack: three sloping shelves of loaves, and a basket of long ones at the
			-- foot. c1 the boards, c2 the posts.
			r:piece(function(q: R)
				for _, x in { -1.86, 1.86 } do
					q:block(x - 0.1, 0, -0.82, x + 0.1, 6.6, -0.62, r.c2, "Wood")
					q:block(x - 0.1, 0, 0.6, x + 0.1, 5.4, 0.8, r.c2, "Wood")
					q:block(x - 0.08, 0.5, -0.65, x + 0.08, 0.7, 0.6, r.c2, "Wood")
				end
				q:block(-1.96, 6.6, -0.9, 1.96, 6.78, -0.55, r.c2, "Wood")
			end)
			r:block(-1.76, 1.0, -0.84, 1.76, 6.4, -0.76, shade(r.c1, 0.82), "WoodPlanks")
			r:block(-1.76, 0.5, -0.7, 1.76, 0.64, 0.7, r.c1, "WoodPlanks")
			for i, y in { 2.0, 3.6, 5.2 } do
				local cf = CFrame.new(0, y, 0) * CFrame.Angles(math.rad(14), 0, 0)
				r:boxAt(cf, 3.7, 0.14, 1.5, r.c1, "WoodPlanks")
				r:boxAt(cf * CFrame.new(0, 0.115, 0.8), 3.66, 0.37, 0.1, r.c2, "Wood")
				for k = 0, 2 do
					local x = -1.2 + k * 1.2
					local at = cf * CFrame.new(x, 0.34, 0.1) * CFrame.Angles(0, math.rad((i + k) % 2 * 16 - 8), 0)
					r:lump(at, 1.0, 0.56, 0.7, if (i + k) % 3 == 0 then CRUST_DARK else CRUST, "Sand")
				end
			end
			-- the basket and its long loaves
			r:block(-1.5, 0.64, -0.5, -0.1, 1.5, 0.5, Color3.fromRGB(196, 154, 98), "Fabric")
			for i, x in { -1.2, -0.8, -0.4 } do
				local cf = CFrame.new(x, 1.7, 0.05 - i * 0.08)
					* CFrame.Angles(math.rad(-8 - i * 3), 0, math.rad(i * 5 - 10))
				r:lump(cf, 0.34, 2.4, 0.34, CRUST, "Sand")
			end
			loaf(r, 0.95, 0.64, 0, 1.3, -10)
		end,
	},
	{
		id = "shop_shelves",
		name = "Shop shelves",
		cat = "storage",
		price = 150,
		place = "floor",
		size = Vector3.new(4, 7, 1.6),
		c1 = "F2E6CC",
		c2 = "9A6B48",
		tags = { "storage" },
		build = function(r: R)
			-- a grocer's shelves: boxes at the foot, then tins, then jars and bottles, then bags.
			-- c1 the back board, c2 the frame and the shelves.
			r:block(-1.84, 0.3, -0.8, 1.84, 6.8, -0.68, r.c1, "WoodPlanks")
			r:piece(function(q: R)
				q:block(-2, 0, -0.8, -1.84, 6.8, 0.7, r.c2, "Wood")
				q:block(1.84, 0, -0.8, 2, 6.8, 0.7, r.c2, "Wood")
				q:block(-2, 6.8, -0.8, 2, 7, 0.78, r.c2, "Wood")
				q:block(-1.84, 0, -0.68, 1.84, 0.3, 0.6, shade(r.c2, 0.8), "Wood")
				for _, y in { 0.3, 1.9, 3.5, 5.1 } do
					q:block(-1.84, y, -0.68, 1.84, y + 0.14, 0.72, r.c2, "Wood")
				end
			end)
			-- boxes
			r:piece(function(q: R)
				local cols = { MUSTARD, BERRY, NAVY, FOREST }
				for i, col in cols do
					local x = -1.72 + (i - 1) * 0.88
					q:block(x, 0.44, -0.5, x + 0.74, 1.6 - (i % 2) * 0.2, 0.4, col, "Cardboard")
					q:block(x + 0.14, 0.9, 0.4, x + 0.6, 1.3 - (i % 2) * 0.2, 0.44, C.Paper, "Cardboard")
				end
			end, nil, "Cardboard")
			-- tins, two deep
			local tins = { BERRY, BERRY, MUSTARD, NAVY, NAVY, FOREST }
			for i, col in tins do
				local x = -1.5 + (i - 1) * 0.6
				r:cyl(x, 2.44, 0.3, 0.8, 0.5, "y", col, "Cardboard")
				r:cyl(x, 2.44, 0.3, 0.3, 0.58, "y", C.Paper, "Cardboard")
				if i % 2 == 0 then
					r:cyl(x, 2.44, -0.3, 0.8, 0.5, "y", C.Metal, "Metal")
				end
			end
			-- jars with lids, and three bottles
			for i, col in { APPLE, ORANGE, LEMON } do
				local x = -1.45 + (i - 1) * 0.66
				r:cyl(x, 3.99, 0.25, 0.7, 0.54, "y", col, "Cardboard")
				r:cyl(x, 4.4, 0.25, 0.12, 0.58, "y", C.Gold, "Metal")
			end
			for i, col in { FOREST, CRUST_DARK, FOREST } do
				local x = 0.6 + (i - 1) * 0.5
				r:cyl(x, 4.09, 0.2, 0.9, 0.38, "y", col, "Glass")
				r:cyl(x, 4.7, 0.2, 0.34, 0.16, "y", col, "Glass")
			end
			-- bags of flour and sugar on top
			for i, x in { -1.3, -0.4, 0.5, 1.35 } do
				local col = if i % 2 == 0 then Color3.fromRGB(214, 196, 160) else C.Paper
				r:lump(CFrame.new(x, 5.76, 0.05), 0.8, 1.05, 0.6, col, "Fabric")
				r:block(x - 0.2, 5.6, 0.34, x + 0.2, 5.9, 0.37, if i % 2 == 0 then BERRY else NAVY, "Fabric")
			end
		end,
	},
	{
		id = "produce_stand",
		name = "Fruit and veg stand",
		cat = "decor",
		style = "rustic",
		price = 120,
		place = "floor",
		size = Vector3.new(4.4, 3.8, 2.8),
		c1 = "DDBE94",
		c2 = "9A6B48",
		tags = { "plant" },
		build = function(r: R)
			-- four crates on a stepped trestle, tipped toward whoever is buying: apples and
			-- oranges in front, cabbages and lemons behind. c1 the crates, c2 the trestle.
			r:piece(function(q: R)
				for _, x in { -2, 2 } do
					q:block(x - 0.1, 0, 1.0, x + 0.1, 1.3, 1.2, r.c2, "Wood")
					q:block(x - 0.1, 0, -1.3, x + 0.1, 2.5, -1.1, r.c2, "Wood")
					q:block(x - 0.08, 0.5, -1.1, x + 0.08, 0.68, 1.0, r.c2, "Wood")
				end
				q:block(-2.1, 1.2, 0.0, 2.1, 1.36, 1.25, r.c2, "Wood")
				q:block(-2.1, 2.3, -1.35, 2.1, 2.46, -0.1, r.c2, "Wood")
				q:block(-2, 0.5, -1.25, 2, 0.66, -1.12, r.c2, "Wood")
			end)
			local goods = {
				{ x = -1.05, y = 1.5, z = 0.62, step = 1.36, kind = 1 },
				{ x = 1.05, y = 1.5, z = 0.62, step = 1.36, kind = 2 },
				{ x = -1.05, y = 2.6, z = -0.72, step = 2.46, kind = 3 },
				{ x = 1.05, y = 2.6, z = -0.72, step = 2.46, kind = 4 },
			}
			for _, g in goods do
				local cf = CFrame.new(g.x, g.y, g.z) * CFrame.Angles(math.rad(16), 0, 0)
				-- the crate, propped on a block at the back: a floor, slatted sides, two ends
				r:piece(function(q: R)
					q:block(
						g.x - 0.7,
						g.step,
						g.z - 0.6,
						g.x + 0.7,
						g.step + 0.22,
						g.z - 0.4,
						shade(r.c1, 0.7),
						"WoodPlanks"
					)
					q:boxAt(cf, 1.84, 0.12, 1.12, shade(r.c1, 0.85), "WoodPlanks")
					for _, sz in { -1, 1 } do
						q:boxAt(cf * CFrame.new(0, 0.16, sz * 0.56), 1.8, 0.18, 0.1, r.c1, "WoodPlanks")
						q:boxAt(cf * CFrame.new(0, 0.44, sz * 0.56), 1.8, 0.18, 0.1, r.c1, "WoodPlanks")
					end
					for _, sx in { -1, 1 } do
						q:boxAt(cf * CFrame.new(sx * 0.9, 0.3, 0), 0.1, 0.54, 1.3, shade(r.c1, 0.88), "WoodPlanks")
					end
				end)
				-- what is in it
				r:piece(function(q: R)
					local foot = cf * CFrame.new(0.62, 0.1, -0.38)
					q:block(
						foot.X - 0.03,
						foot.Y,
						foot.Z - 0.03,
						foot.X + 0.03,
						foot.Y + 0.66,
						foot.Z + 0.03,
						PALE_WOOD
					)
					q:boxAt(
						CFrame.new(foot.X, foot.Y + 0.74, foot.Z + 0.04) * CFrame.Angles(math.rad(-12), 0, 0),
						0.46,
						0.3,
						0.04,
						if g.kind % 2 == 0 then LEMON else C.Paper
					)
					for i = 0, 7 do
						local col, row = i % 4, i // 4
						local at = cf * CFrame.new(-0.6 + col * 0.4, 0.3 + (i % 2) * 0.04, -0.2 + row * 0.4)
						if g.kind == 1 then
							apple(q, at, if i % 3 == 1 then shade(APPLE, 0.85) else APPLE, i % 2 == 0)
						elseif g.kind == 2 then
							orange(q, at)
						elseif g.kind == 4 then
							lemon(q, at * CFrame.Angles(0, (i % 3 - 1) * 0.4, 0))
						end
					end
					if g.kind == 3 then
						for i = 0, 2 do
							cabbage(q, cf * CFrame.new(-0.55 + i * 0.55, 0.34, (i % 2) * 0.16 - 0.08), i * 1.3)
						end
					end
				end, nil, "Wood")
			end
		end,
	},
	{
		id = "menu_board",
		name = "Pavement board",
		cat = "decor",
		price = 45,
		place = "floor",
		size = Vector3.new(2.2, 3.6, 2.2),
		c1 = "9A6B48",
		c2 = "5A5560",
		build = function(r: R)
			-- two chalkboards hinged at the top, to stand outside a shop: c1 the frames, c2 the
			-- boards. Today's is chalked on both.
			for _, s in { -1, 1 } do
				-- (each leans in at the top, so the two meet under the hinge like an A)
				local cf = CFrame.new(0, 1.72, s * 0.5) * CFrame.Angles(math.rad(-s * 15), 0, 0)
				r:boxAt(cf, 2.1, 3.5, 0.12, r.c1, "Wood")
				r:boxAt(cf * CFrame.new(0, 0.15, s * 0.07), 1.78, 2.7, 0.04, r.c2, "Slate")
				local face = cf * CFrame.new(0, 0.15, s * 0.11)
				r:boxAt(face * CFrame.new(0, 1.0, 0), 1.1, 0.16, 0.04, C.White, "Plaster")
				for i, w in { 1.3, 0.9, 1.2 } do
					r:boxAt(face * CFrame.new(-0.1, 0.5 - i * 0.36, 0), w, 0.08, 0.04, C.White, "Plaster")
				end
				r:boxAt(face * CFrame.new(0.35, -1.0, 0), 0.5, 0.4, 0.04, LEMON, "Marble")
			end
			r:cyl(0, 3.42, 0, 2.1, 0.16, "x", IRON, "Metal")
		end,
	},
	{
		id = "freezer_icecream",
		name = "Ice cream freezer",
		cat = "kitchen",
		price = 320,
		place = "floor",
		size = Vector3.new(5, 4.2, 2.6),
		c1 = "FAF6EC",
		c2 = "B8505A",
		tags = { "kitchen" },
		build = function(r: R)
			-- a scooping cabinet: eight tubs under a sloping glass, a stack of cones on the end.
			-- c1 the cabinet, c2 its stripe and rail.
			r:block(-2.5, 0, -1.2, 2.5, 0.3, 1.0, shade(r.c1, 0.55), "Metal")
			r:block(-2.5, 0.3, -1.3, 2.5, 2.6, 1.2, r.c1, "Metal")
			r:block(-2.5, 1.3, 1.2, 2.5, 1.9, 1.24, r.c2, "Metal")
			r:block(-2.5, 2.6, -1.3, 2.5, 2.74, 1.24, shade(r.c1, 0.9), "Metal")
			r:block(-2.3, 2.74, -1.0, 2.3, 2.8, 0.9, Color3.fromRGB(205, 225, 235), "Metal")
			local tubs = { STRAWBERRY, VANILLA, CHOC, MINT, LEMON, LILAC, CHOC, STRAWBERRY }
			for i, col in tubs do
				local x = -1.72 + ((i - 1) % 4) * 1.15
				local z = if i <= 4 then 0.4 else -0.5
				r:cyl(x, 2.9, z, 0.24, 0.84, "y", C.Metal, "Metal")
				r:cyl(x, 2.98, z, 0.2, 0.72, "y", col, "Plaster")
				r:noCollide(r:ball(x + 0.1, 3.1, z, 0.44, shade(col, 0.94), "Plaster"))
			end
			-- the glass: a sloping pane to the customer, a flat one over, and two end cheeks
			glassAt(r, CFrame.new(0, 3.3, 0.86) * CFrame.Angles(math.rad(-35), 0, 0), 4.8, 1.3, 0.08)
			glassAt(r, CFrame.new(0, 3.84, -0.1), 4.8, 0.08, 1.3)
			r:piece(function(q: R)
				q:block(-2.5, 3.76, -0.8, 2.5, 3.92, -0.66, r.c2, "Metal")
				q:block(-2.5, 3.76, 0.42, 2.5, 3.92, 0.6, r.c2, "Metal")
				for _, x in { -2.44, 2.44 } do
					q:block(x - 0.06, 2.74, -0.8, x + 0.06, 3.8, -0.66, r.c2, "Metal")
				end
			end)
			-- cones in a stack on the server's side
			r:cyl(2.0, 2.84, -1.0, 0.2, 0.6, "y", C.Metal, "Metal")
			for i = 0, 2 do
				r:add({
					shape = "Cone",
					cf = CFrame.new(2.0, 3.3 + i * 0.22, -1.0) * CFrame.Angles(math.pi, 0, 0),
					size = Vector3.new(0.5, 0.9, 0.5),
					color = WAFER,
					mat = "Sand",
					collide = false,
				})
			end
		end,
	},
	{
		id = "booth_seat",
		name = "Booth seat",
		cat = "seating",
		price = 130,
		place = "floor",
		size = Vector3.new(4.4, 4.4, 2.4),
		c1 = "B8505A",
		c2 = "FAF6EC",
		tags = { "seat" },
		build = function(r: R)
			-- a padded bench with a high back, for two: c1 the padding, c2 the frame
			r:block(-2.2, 0, -1.2, 2.2, 0.3, 0.9, shade(r.c2, 0.6), "Wood")
			r:block(-2.2, 0.3, -1.2, 2.2, 1.5, 1.05, r.c2, "Wood")
			r:block(-2.15, 1.5, -0.7, 2.15, 1.95, 1.15, r.c1, "Leather")
			r:block(-2.2, 1.5, -1.2, 2.2, 4.2, -0.9, r.c2, "Wood")
			r:block(-2.2, 4.2, -1.2, 2.2, 4.36, -0.6, r.c2, "Wood")
			for i = 0, 5 do
				local x = -2.1 + i * 0.7
				local deep = i % 2 == 0
				r:block(
					x,
					1.95,
					-0.9,
					x + 0.7,
					4.1,
					if deep then -0.62 else -0.56,
					if deep then r.c1 else shade(r.c1, 0.93),
					"Leather"
				)
			end
			for _, sx in { -1, 1 } do
				r:block(
					math.min(sx * 2.05, sx * 2.2),
					1.5,
					-0.9,
					math.max(sx * 2.05, sx * 2.2),
					2.6,
					1.05,
					r.c2,
					"Wood"
				)
			end
			r:seat(-1.05, 1.95, 0.25)
			r:seat(1.05, 1.95, 0.25)
		end,
	},
	{
		id = "hatch_serving",
		name = "Serving hatch",
		cat = "windows",
		price = 180,
		place = "opening",
		size = Vector3.new(6.8, 5.8, 4.2),
		opening = { w = 6, h = 4.4, sill = 3.2 },
		c1 = "C49A6C",
		c2 = "FAF6EC",
		build = function(r: R)
			-- an open hatch to serve the street through: a shelf across the sill that reaches out
			-- both ways, and a board flap propped up over it. c1 the shelf and the flap, c2 the frame.
			local w, h = 6, 4.4
			r:piece(function(q: R)
				q:block(-w / 2 - 0.3, 0, -0.45, -w / 2, h + 0.3, 0.45, r.c2, "Wood")
				q:block(w / 2, 0, -0.45, w / 2 + 0.3, h + 0.3, 0.45, r.c2, "Wood")
				q:block(-w / 2 - 0.3, h, -0.45, w / 2 + 0.3, h + 0.3, 0.45, r.c2, "Wood")
			end)
			r:block(-w / 2 - 0.3, -0.28, -1.0, w / 2 + 0.3, 0, 1.3, r.c1, "WoodPlanks")
			r:block(-w / 2 - 0.3, -0.34, 1.24, w / 2 + 0.3, 0.04, 1.34, shade(r.c1, 0.8), "Wood")
			for _, x in { -2.6, 2.6 } do
				r:wedge(
					CFrame.new(x, -0.44, 0.76) * CFrame.Angles(math.pi, 0, 0),
					0.16,
					0.32,
					0.9,
					shade(r.c1, 0.75),
					"Wood"
				)
			end
			-- the flap, hinged along the top of the hole, and the two sticks that hold it up
			local flap = CFrame.new(0, h + 0.62, 1.12) * CFrame.Angles(math.rad(-22), 0, 0)
			r:boxAt(flap, w + 0.4, 0.14, 1.9, r.c1, "WoodPlanks")
			r:boxAt(flap * CFrame.new(0, -0.1, 0), w + 0.1, 0.06, 1.6, shade(r.c1, 0.85), "WoodPlanks")
			for _, x in { -2.9, 2.9 } do
				r:beam(Vector3.new(x, 0, 1.2), Vector3.new(x, h + 0.9, 1.9), 0.1, 0.1, IRON, "Metal")
			end
		end,
	},
	{
		id = "sign_grocer",
		name = "Grocer's sign",
		cat = "walldecor",
		price = 60,
		place = "wall",
		size = Vector3.new(3.4, 3.4, 0.8),
		c1 = "F2E6CC",
		c2 = "4E7F62",
		build = function(r: R)
			-- an apple and a pear on a board
			signBoard(r, 3.4, 3.0)
			r:lump(CFrame.new(-0.62, 1.3, FACE + 0.12), 1.3, 1.24, 0.3, APPLE, "Marble")
			r:block(-0.66, 1.86, FACE, -0.58, 2.3, FACE + 0.1, C.Bark, "Wood")
			r:lump(CFrame.new(-0.34, 2.14, FACE + 0.08) * CFrame.Angles(0, 0, math.rad(-30)), 0.6, 0.26, 0.14, CABBAGE, "Marble")
			r:lump(CFrame.new(0.72, 1.14, FACE + 0.12), 1.0, 1.0, 0.3, LEMON, "Marble")
			r:lump(CFrame.new(0.72, 1.74, FACE + 0.12), 0.62, 0.9, 0.26, LEMON, "Marble")
			r:block(0.68, 2.14, FACE, 0.76, 2.48, FACE + 0.1, C.Bark, "Wood")
		end,
	},
	{
		id = "sign_cafe",
		name = "Café sign",
		cat = "walldecor",
		price = 60,
		place = "wall",
		size = Vector3.new(3.4, 3.4, 0.8),
		c1 = "F2E6CC",
		c2 = "3F8C86",
		build = function(r: R)
			-- a cup on its saucer with steam coming off it
			signBoard(r, 3.4, 3.0)
			local cup = Color3.fromRGB(63, 140, 134)
			r:block(-1.0, 0.56, FACE, 1.0, 0.72, FACE + 0.14, cup, "Marble")
			r:block(-0.62, 0.72, FACE, 0.5, 1.7, FACE + 0.2, cup, "Marble")
			r:block(-0.5, 0.62, FACE, 0.38, 0.72, FACE + 0.2, cup, "Marble")
			r:block(-0.62, 1.56, FACE + 0.2, 0.5, 1.7, FACE + 0.23, C.Bark, "Wood")
			r:cyl(0.6, 1.2, FACE + 0.1, 0.12, 0.84, "z", cup, "Marble")
			r:cyl(0.6, 1.2, FACE + 0.11, 0.22, 0.4, "z", r.c1, "Wood")
			for i, x in { -0.4, 0.0, 0.4 } do
				local lean = CFrame.new(x - 0.06, 2.16 + (i % 2) * 0.1, FACE + 0.06) * CFrame.Angles(0, 0, math.rad(14))
				r:boxAt(lean, 0.12, 0.5, 0.08, C.White, "Wood")
				r:boxAt(lean * CFrame.new(0.12, 0.4, 0) * CFrame.Angles(0, 0, math.rad(-28)), 0.12, 0.4, 0.08, C.White, "Wood")
			end
		end,
	},
	{
		id = "sign_bakery",
		name = "Bakery sign",
		cat = "walldecor",
		price = 60,
		place = "wall",
		size = Vector3.new(3.4, 3.4, 0.8),
		c1 = "F2E6CC",
		c2 = "9A6B48",
		build = function(r: R)
			-- a round loaf with three cuts across it, and an ear of wheat either side
			signBoard(r, 3.4, 3.0)
			r:lump(CFrame.new(0, 1.3, FACE + 0.12), 1.9, 1.2, 0.34, CRUST, "Sand")
			for _, x in { -0.45, 0, 0.45 } do
				local cut = CFrame.new(x, 1.42, FACE + 0.3) * CFrame.Angles(0, 0, math.rad(-28))
				r:boxAt(cut, 0.1, 0.6, 0.06, VANILLA, "Plaster")
			end
			for _, sx in { -1, 1 } do
				r:beam(
					Vector3.new(sx * 1.22, 0.5, FACE + 0.04),
					Vector3.new(sx * 1.3, 2.5, FACE + 0.04),
					0.07,
					0.07,
					MUSTARD, "Wood"
				)
				for i = 0, 3 do
					local at = CFrame.new(sx * (1.27 + i * 0.012), 1.5 + i * 0.3, FACE + 0.06)
					r:lump(at * CFrame.Angles(0, 0, math.rad(sx * 32)), 0.2, 0.42, 0.1, MUSTARD, "Wood")
				end
			end
		end,
	},
	{
		id = "cone_giant",
		name = "Giant ice cream cone",
		cat = "decor",
		style = "playful",
		price = 220,
		place = "floor",
		size = Vector3.new(3.4, 10, 3.4),
		c1 = "E8A8B2",
		c2 = "FAF6EC",
		build = function(r: R)
			-- A cone as tall as a door with two scoops and a cherry, on a block: for the pavement
			-- outside a parlour, or for its roof (stand it on the level above a flat roof and the
			-- block comes up through the slab). c1 the bottom scoop and the block's band, c2 the block.
			-- The cone is four corner wedges meeting at its point, which show in any server (a
			-- round cone needs the low poly kit, and without it became a plain post: the user, "the
			-- ice cream dosent look like an ice cream sign"), with a rim and a criss-cross of waffle.
			r:block(-1.1, 0.04, -1.1, 1.1, 1.8, 1.1, r.c2, "Concrete")
			r:block(-1.16, 1.2, -1.16, 1.16, 1.5, 1.16, r.c1, "Plaster")
			local a, h, tip = 1.3, 4.3, 1.8
			-- (built point up about its middle, then turned over so the point is at the bottom)
			local over = CFrame.new(0, tip + h / 2, 0) * CFrame.Angles(math.pi, 0, 0)
			for _, q in { { -1, 1, 0 }, { 1, 1, 90 }, { 1, -1, 180 }, { -1, -1, -90 } } do
				r:add({
					shape = "CornerWedge",
					cf = over * CFrame.new(q[1] * a / 2, 0, q[2] * a / 2) * CFrame.Angles(0, math.rad(q[3]), 0),
					size = Vector3.new(a, h, a),
					color = WAFER,
					mat = "Sand",
				})
			end
			-- the waffle: darker bands across each face, a little proud of it
			local slope = math.atan2(h, a)
			for k = 0, 3 do
				local face = CFrame.Angles(0, math.rad(k * 90), 0)
				for i, t in { 0.35, 0.62 } do
					-- (t of the way down from the rim: the face is narrower there)
					local w = 2 * a * (1 - t) - 0.1
					local at = CFrame.new(0, tip + h * (1 - t), -a * (1 - t) - 0.03)
					r:noCollide(
						r:boxAt(
							face * at * CFrame.Angles(-(math.pi / 2 - slope), 0, 0),
							w,
							0.12,
							0.05,
							shade(WAFER, 0.78),
							"Sand"
						)
					)
					local _ = i
				end
			end
			r:block(
				-a - 0.08,
				tip + h - 0.06,
				-a - 0.08,
				a + 0.08,
				tip + h + 0.3,
				a + 0.08,
				shade(WAFER, 0.88),
				"Sand"
			)
			-- two scoops wider than the cone, the bottom one in c1, and a cherry
			r:ball(0, tip + h + 0.9, 0, 3.2, r.c1, "Plaster")
			r:ball(0, tip + h + 2.2, 0, 2.5, MINT, "Plaster")
			r:noCollide(r:ball(0, tip + h + 3.35, 0, 0.6, APPLE, "Marble"))
			-- drips over the rim
			r:noCollide(r:lump(CFrame.new(0.95, tip + h + 0.1, 0.8), 0.5, 0.9, 0.5, r.c1, "Plaster"))
			r:noCollide(r:lump(CFrame.new(-1.05, tip + h + 0.2, -0.6), 0.5, 0.7, 0.5, r.c1, "Plaster"))
		end,
	},
}

return items
