--!strict
-- What the town's public buildings are fitted out with: the clinic's canopy, ward bed and
-- medicine cabinet, the school's bell and desks, the post office's pillar box, sorting shelves,
-- trolley and gable clock, the library's tall bookcase, and a hanging sign for each of them.
-- They are ordinary catalog pieces, so they are on sale in Build mode too.

local Recipe = require(script.Parent.Parent.Recipe)
local Colors = require(script.Parent.Parent.Parent.Util.Colors)

local C = Recipe.Colors

type R = Recipe.Recipe

local function shade(c: Color3, k: number): Color3
	return Colors.shade(c, k)
end

local SHEET = Color3.fromRGB(250, 248, 243)
local KRAFT = Color3.fromRGB(196, 154, 98)
local STRING = Color3.fromRGB(232, 222, 196)
local BERRY = Color3.fromRGB(184, 80, 90)

local SPINES = {
	Color3.fromRGB(176, 68, 62),
	Color3.fromRGB(70, 110, 150),
	Color3.fromRGB(143, 179, 154),
	Color3.fromRGB(232, 190, 92),
	Color3.fromRGB(142, 91, 122),
	C.Cream,
	Color3.fromRGB(217, 128, 95),
	Color3.fromRGB(62, 110, 88),
	Color3.fromRGB(60, 62, 72),
}

-- A row of standing books from x1 to x2 on a shelf at y, at most maxH tall, their spines at zf.
-- One piece a row, so a wall of books stays light. `seed` varies the row.
local function books(r: R, x1: number, x2: number, y: number, maxH: number, zf: number, seed: number)
	local s = seed
	local function rand(): number
		s = (s * 1103515245 + 12345) % 2147483648
		return s / 2147483648
	end
	r:piece(function(q: R)
		local x = x1
		while x < x2 - 0.2 do
			local w = math.min(0.24 + rand() * 0.22, x2 - x)
			local h = maxH * (0.72 + rand() * 0.28)
			local col = SPINES[1 + math.floor(rand() * #SPINES)]
			q:block(x, y, zf - 0.9, x + w - 0.03, y + h, zf - rand() * 0.08, col, "SmoothPlastic")
			x += w
		end
	end)
end

-- A parcel done up with string: a box between two corners with a band round it each way.
local function parcel(r: R, x1: number, y1: number, z1: number, x2: number, y2: number, z2: number, color: Color3)
	r:block(x1, y1, z1, x2, y2, z2, color, "Fabric")
	local xm, zm = (x1 + x2) / 2, (z1 + z2) / 2
	r:piece(function(q: R)
		q:block(xm - 0.05, y1, z1 - 0.04, xm + 0.05, y2 + 0.04, z2 + 0.04, STRING, "Fabric")
		q:block(x1 - 0.04, y1, zm - 0.05, x2 + 0.04, y2 + 0.04, zm + 0.05, STRING, "Fabric")
	end)
end

-- A board hung from an iron arm so it stands out square from the wall and reads from along
-- the street (the workshop's sign is the same make). `picture` draws on one face: x is the
-- face (-1 or 1), and the board runs from z 0.6 to 2.9 and y 0.8 to 2.9.
local function hangingSign(r: R, picture: (q: R, x: number) -> ())
	r:piece(function(q: R)
		q:block(-0.1, 2.5, 0, 0.1, 3.5, 0.08, C.DarkMetal, "Metal")
		q:block(-0.05, 3.2, 0.08, 0.05, 3.3, 3.1, C.DarkMetal, "Metal")
		q:beam(Vector3.new(0, 2.6, 0.08), Vector3.new(0, 3.2, 1.1), 0.08, 0.08, C.DarkMetal, "Metal")
		for _, z in { 0.9, 2.6 } do
			q:block(-0.03, 2.9, z - 0.03, 0.03, 3.2, z + 0.03, C.DarkMetal, "Metal")
		end
	end)
	r:block(-0.08, 0.86, 0.6, 0.08, 2.84, 2.9, r.c1, "Wood")
	local edge = shade(r.c1, 0.62)
	r:block(-0.12, 2.78, 0.56, 0.12, 2.9, 2.94, edge, "Wood")
	r:block(-0.12, 0.8, 0.56, 0.12, 0.92, 2.94, edge, "Wood")
	r:piece(function(q: R)
		for _, sx in { -1, 1 } do
			picture(q, sx * 0.1)
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
	style: string?, -- the look it belongs to (Catalog.Styles)
	build: (r: R) -> (),
	gives: string?, -- holding E gives the player something (Data/Items.Sources)
}

local items: { Item } = {
	-- the clinic -----------------------------------------------------------------------------
	{
		id = "canopy_door",
		name = "Door canopy",
		cat = "structure",
		price = 140,
		place = "floor",
		size = Vector3.new(8, 9.8, 4.4),
		c1 = "FAF6EC",
		c2 = "3F8C86",
		build = function(r: R)
			-- A flat roof over a doorway on two posts, its back (-z) against the wall: a deck with
			-- a beam along its front, a band round its edge (c2) with a lip on top and a bead
			-- under it, brackets up from the posts and out from the wall, and a lantern hung
			-- under the middle that comes on after dark. c1 the posts and the deck.
			local post = r.c1
			for _, sx in { -1, 1 } do
				local x = sx * 3.65
				r:block(x - 0.42, 0, 1.38, x + 0.42, 0.34, 2.2, shade(post, 0.78), "Concrete")
				r:block(x - 0.2, 0.34, 1.6, x + 0.2, 9, 2, post, "Metal")
				r:block(x - 0.28, 8.7, 1.52, x + 0.28, 9, 2.08, shade(post, 0.88), "Metal")
			end
			r:piece(function(q: R)
				for _, sx in { -1, 1 } do
					local x = sx * 3.65
					q:block(x - 0.26, 0.34, 1.54, x + 0.26, 0.62, 2.06, shade(post, 0.9), "Metal")
					q:block(x - 0.25, 8.4, 1.55, x + 0.25, 8.52, 2.05, shade(post, 0.9), "Metal")
					q:beam(Vector3.new(x, 7.5, 1.8), Vector3.new(x - sx * 1.2, 8.72, 1.8), 0.14, 0.14, post, "Metal")
					q:block(x - 0.2, 7.0, -2.2, x + 0.2, 7.5, -2.12, post, "Metal")
					q:beam(Vector3.new(x, 7.2, -2.12), Vector3.new(x, 9.0, -0.7), 0.14, 0.14, post, "Metal")
				end
				q:block(-3.45, 8.72, 1.62, 3.45, 9.0, 1.98, shade(post, 0.85), "Metal")
			end)
			r:block(-4, 9, -2.2, 4, 9.3, 2.2, post, "SmoothPlastic")
			r:block(-3.8, 9.3, -2.2, 3.8, 9.42, 2, shade(post, 0.9), "SmoothPlastic")
			r:block(-4, 8.72, -2.2, 4, 9, -2.02, shade(post, 0.85), "SmoothPlastic")
			r:piece(function(q: R)
				q:block(-4, 9.3, 2, 4, 9.8, 2.2, r.c2)
				q:block(-4, 9.3, -2.2, -3.8, 9.8, 2, r.c2)
				q:block(3.8, 9.3, -2.2, 4, 9.8, 2, r.c2)
				local lip = shade(r.c2, 0.85)
				q:block(-4.06, 9.8, 1.94, 4.06, 9.88, 2.26, lip)
				q:block(-4.06, 9.8, -2.2, -3.74, 9.88, 1.94, lip)
				q:block(3.74, 9.8, -2.2, 4.06, 9.88, 1.94, lip)
				q:block(-4.04, 9.22, 2.2, 4.04, 9.3, 2.26, lip)
				q:block(-4.06, 9.22, -2.2, -4, 9.3, 2.26, lip)
				q:block(4, 9.22, -2.2, 4.06, 9.3, 2.26, lip)
			end)
			-- the lantern on its chain
			r:piece(function(q: R)
				q:block(-0.03, 8.3, -0.03, 0.03, 9.0, 0.03, C.DarkMetal, "Metal")
				q:block(-0.32, 8.12, -0.32, 0.32, 8.3, 0.32, C.DarkMetal, "Metal")
				q:block(-0.3, 7.4, -0.3, 0.3, 7.5, 0.3, C.DarkMetal, "Metal")
				for _, sx in { -1, 1 } do
					for _, sz in { -1, 1 } do
						q:block(
							sx * 0.26 - 0.03,
							7.5,
							sz * 0.26 - 0.03,
							sx * 0.26 + 0.03,
							8.12,
							sz * 0.26 + 0.03,
							C.DarkMetal,
							"Metal"
						)
					end
				end
				q:ball(0, 7.34, 0, 0.14, C.DarkMetal, "Metal")
			end)
			r:glow(r:noCollide(r:block(-0.25, 7.5, -0.25, 0.25, 8.12, 0.25, C.Warm, "SmoothPlastic")), 14, 1)
		end,
	},
	{
		id = "bed_ward",
		name = "Ward bed",
		cat = "beds",
		price = 260,
		place = "floor",
		size = Vector3.new(3.8, 4.4, 7.4),
		c1 = "FAF6EC",
		c2 = "A9D4CC",
		tags = { "bed" },
		build = function(r: R)
			-- A hospital bed on castors: a white iron frame (c1) with a barred head and foot, a
			-- blanket (c2) and a chart hung on the foot rail. The head is at the back (-z).
			local iron = r.c1
			for _, sx in { -1, 1 } do
				for _, sz in { -1, 1 } do
					r:cyl(sx * 1.62, 0.26, sz * 3.3, 0.22, 0.52, "x", C.Black, "SmoothPlastic")
					r:block(
						sx * 1.62 - 0.08,
						0.3,
						sz * 3.3 - 0.08,
						sx * 1.62 + 0.08,
						1.1,
						sz * 3.3 + 0.08,
						iron,
						"Metal"
					)
				end
				r:block(sx * 1.66 - 0.09, 1.02, -3.5, sx * 1.66 + 0.09, 1.24, 3.5, iron, "Metal")
			end
			r:block(-1.6, 1.05, -3.42, 1.6, 1.2, 3.42, shade(iron, 0.8), "Metal")
			r:block(-1.6, 1.2, -3.4, 1.6, 1.86, 3.4, SHEET, "Fabric")
			r:block(-1.68, 1.36, -0.7, 1.68, 1.98, 3.44, r.c2, "Fabric")
			r:block(-1.72, 1.36, -1.1, 1.72, 2.04, -0.66, Colors.mix(r.c2, C.White, 0.45), "Fabric")
			r:block(-1.15, 1.86, -3.2, 1.15, 2.26, -2.25, SHEET, "Fabric")
			-- the head and the foot: two posts, a top rail and a row of bars
			for _, e in { { -3.55, 4.2 }, { 3.55, 3.1 } } do
				local z, top = e[1], e[2]
				for _, sx in { -1, 1 } do
					r:cyl(sx * 1.68, top / 2 + 0.2, z, top - 0.4, 0.24, "y", iron, "Metal")
					r:ball(sx * 1.68, top + 0.05, z, 0.34, iron, "Metal")
				end
				r:cyl(0, top - 0.1, z, 3.22, 0.2, "x", iron, "Metal")
				r:cyl(0, 1.5, z, 3.22, 0.16, "x", iron, "Metal")
				r:piece(function(q: R)
					for i = -2, 2 do
						q:block(i * 0.56 - 0.05, 1.5, z - 0.05, i * 0.56 + 0.05, top - 0.1, z + 0.05, iron, "Metal")
					end
				end)
			end
			r:piece(function(q: R)
				q:block(-0.42, 1.7, 3.66, 0.42, 2.8, 3.7, Color3.fromRGB(122, 96, 70), "SmoothPlastic")
				q:block(-0.36, 1.76, 3.7, 0.36, 2.62, 3.74, C.Paper, "SmoothPlastic")
				q:block(-0.18, 2.62, 3.7, 0.18, 2.78, 3.78, C.Metal, "SmoothPlastic")
			end)
			r:sleep(0, 1.95, 0.1)
		end,
	},
	{
		id = "medicine_cabinet",
		name = "Medicine cabinet",
		cat = "storage",
		price = 190,
		place = "floor",
		size = Vector3.new(3.6, 6.6, 1.6),
		c1 = "FAF6EC",
		c2 = "9CCFC4",
		tags = { "storage" },
		build = function(r: R)
			-- A cupboard (its doors c2) with a glazed case of bottles and jars on top.
			local dk = shade(r.c1, 0.86)
			r:block(-1.8, 0, -0.8, 1.8, 0.3, 0.62, dk, "SmoothPlastic")
			r:block(-1.8, 0.3, -0.8, 1.8, 2.6, 0.7, r.c1, "SmoothPlastic")
			for _, sx in { -1, 1 } do
				local x1, x2 = math.min(sx * 0.06, sx * 1.66), math.max(sx * 0.06, sx * 1.66)
				r:block(x1, 0.46, 0.7, x2, 2.44, 0.76, r.c2, "SmoothPlastic")
				r:block(sx * 0.3 - 0.05, 1.2, 0.76, sx * 0.3 + 0.05, 1.8, 0.82, C.Metal, "Metal")
			end
			r:block(-1.86, 2.6, -0.8, 1.86, 2.76, 0.78, dk, "SmoothPlastic")
			r:block(-1.8, 2.76, -0.8, 1.8, 6.4, -0.68, r.c1, "SmoothPlastic")
			r:block(-1.8, 2.76, -0.68, -1.66, 6.4, 0.5, r.c1, "SmoothPlastic")
			r:block(1.66, 2.76, -0.68, 1.8, 6.4, 0.5, r.c1, "SmoothPlastic")
			r:block(-1.86, 6.4, -0.8, 1.86, 6.58, 0.56, dk, "SmoothPlastic")
			for _, y in { 3.92, 5.14 } do
				r:block(-1.66, y, -0.68, 1.66, y + 0.1, 0.42, r.c1, "SmoothPlastic")
			end
			-- bottles and jars, a shelf at a time
			local amber = Color3.fromRGB(176, 106, 52)
			local blue = Color3.fromRGB(86, 132, 178)
			local green = Color3.fromRGB(96, 160, 124)
			local rows: { { y: number, cols: { Color3 } } } = {
				{ y = 2.76, cols = { amber, C.White, blue, amber, green, C.White } },
				{ y = 4.02, cols = { C.White, green, amber, blue, C.White } },
				{ y = 5.24, cols = { blue, amber, C.White, green } },
			}
			for n, row in rows do
				local y = row.y
				local cols = row.cols
				r:piece(function(q: R)
					for i, col in cols do
						local x = -1.66 + (i - 0.5) * 3.32 / #cols
						local h = 0.55 + ((i + n) % 3) * 0.14
						q:cyl(x, y + h / 2, -0.1, h, 0.42, "y", col, "SmoothPlastic")
						q:block(x - 0.1, y + h, -0.2, x + 0.1, y + h + 0.14, 0, C.DarkMetal, "SmoothPlastic")
					end
				end)
			end
			r:glass(-1.66, 2.86, 0.4, 1.66, 6.4, 0.46)
			r:block(-0.07, 2.76, 0.38, 0.07, 6.4, 0.5, r.c1, "SmoothPlastic")
			r:block(-1.66, 2.76, 0.38, 1.66, 2.86, 0.5, r.c1, "SmoothPlastic")
		end,
	},
	{
		id = "sign_clinic",
		name = "Clinic sign",
		cat = "walldecor",
		price = 40,
		place = "wall",
		size = Vector3.new(0.6, 3.6, 3.2),
		c1 = "FAF6EC",
		c2 = "3F8C86",
		build = function(r: R)
			-- a hanging board with a cross on both faces: c1 the board, c2 the cross
			local cross = r.c2
			hangingSign(r, function(q: R, x: number)
				q:box(x, 1.85, 1.75, 0.04, 1.5, 0.5, cross, "SmoothPlastic")
				q:box(x, 1.85, 1.75, 0.04, 0.5, 1.5, cross, "SmoothPlastic")
			end)
		end,
	},
	-- the school -----------------------------------------------------------------------------
	{
		id = "school_bell",
		name = "School bell",
		cat = "decor",
		price = 220,
		place = "floor",
		size = Vector3.new(4, 6, 2.4),
		c1 = "D9A93F",
		c2 = "9A6B48",
		build = function(r: R)
			-- A bell (c1) hung from a beam between two posts (c2), with its rope. It stands in
			-- a yard, or up in a belfry on the floor above the door.
			local dk = shade(r.c2, 0.8)
			for _, sx in { -1, 1 } do
				local x = sx * 1.7
				r:block(x - 0.28, 0, -1.1, x + 0.28, 0.3, 1.1, dk, "Wood")
				r:block(x - 0.2, 0.3, -0.22, x + 0.2, 5.4, 0.22, r.c2, "Wood")
				for _, sz in { -1, 1 } do
					r:beam(Vector3.new(x, 0.3, sz * 0.95), Vector3.new(x, 1.7, sz * 0.2), 0.3, 0.26, r.c2, "Wood")
				end
			end
			r:block(-2, 5.4, -0.3, 2, 5.9, 0.3, r.c2, "Wood")
			r:block(-0.24, 4.95, -0.24, 0.24, 5.4, 0.24, C.DarkMetal, "Metal")
			r:cone(0, 4.3, 0, 2.3, 2.3, r.c1, "Metal")
			r:cyl(0, 3.26, 0, 0.3, 2.5, "y", shade(r.c1, 0.86), "Metal")
			r:cyl(0, 3.02, 0, 0.26, 0.2, "y", C.DarkMetal, "Metal")
			r:ball(0, 2.8, 0, 0.46, C.DarkMetal, "Metal")
			r:cyl(0, 1.75, 0, 1.9, 0.12, "y", STRING, "Fabric")
			r:ball(0, 0.8, 0, 0.28, STRING, "Fabric")
		end,
	},
	{
		id = "school_desk",
		name = "School desk",
		cat = "tables",
		price = 110,
		place = "floor",
		size = Vector3.new(4, 3.3, 3.6),
		c1 = "C49A6C",
		c2 = "5A5560",
		tags = { "desk", "seat" },
		surface = 2.7,
		build = function(r: R)
			-- A desk for two with its bench on the same iron frame (c2). They sit at the front
			-- (+z) and face the desk. On top: a slate, an open book and a pencil.
			local dk = shade(r.c1, 0.85)
			for _, sx in { -1, 1 } do
				local x = sx * 1.78
				r:block(x - 0.12, 0, -1.65, x + 0.12, 0.2, 1.65, r.c2, "Metal")
				r:block(x - 0.1, 0.2, -1.55, x + 0.1, 2.5, -1.35, r.c2, "Metal")
				r:block(x - 0.1, 0.2, -0.6, x + 0.1, 2.5, -0.4, r.c2, "Metal")
				r:block(x - 0.1, 0.2, 0.55, x + 0.1, 1.7, 0.75, r.c2, "Metal")
				r:block(x - 0.1, 0.2, 1.42, x + 0.1, 3.2, 1.62, r.c2, "Metal")
			end
			r:block(-1.9, 2.5, -1.75, 1.9, 2.7, -0.25, r.c1, "Wood")
			r:block(-1.68, 1.0, -1.62, 1.68, 2.5, -1.5, dk, "Wood")
			r:block(-1.68, 1.85, -1.5, 1.68, 1.97, -0.5, dk, "Wood")
			r:block(-1.9, 1.7, 0.45, 1.9, 1.9, 1.5, r.c1, "Wood")
			r:block(-1.82, 2.5, 1.5, 1.82, 3.25, 1.66, r.c1, "Wood")
			r:piece(function(q: R)
				q:block(-1.4, 2.7, -1.45, -0.5, 2.76, -0.75, Color3.fromRGB(150, 110, 70), "SmoothPlastic")
				q:block(-1.32, 2.76, -1.37, -0.58, 2.8, -0.83, Color3.fromRGB(52, 70, 62), "SmoothPlastic")
				q:block(0.4, 2.7, -1.4, 0.92, 2.75, -0.7, C.Paper, "SmoothPlastic")
				q:block(0.96, 2.7, -1.4, 1.48, 2.75, -0.7, C.Paper, "SmoothPlastic")
				q:block(0.5, 2.75, -0.62, 1.2, 2.81, -0.55, C.Yellow, "SmoothPlastic")
			end)
			r:seat(-0.95, 1.9, 1.0, 180)
			r:seat(0.95, 1.9, 1.0, 180)
		end,
	},
	-- the post office ------------------------------------------------------------------------
	{
		id = "postbox",
		name = "Pillar box",
		cat = "garden",
		price = 90,
		place = "ground",
		size = Vector3.new(2, 5.2, 2),
		c1 = "B8505A",
		c2 = "5A5560",
		build = function(r: R)
			-- A round box to post letters in (c1) on a dark foot (c2), its slot under a hood
			-- at the front.
			r:cyl(0, 0.3, 0, 0.6, 1.9, "y", r.c2, "Metal")
			r:cyl(0, 2.4, 0, 3.6, 1.6, "y", r.c1, "Metal")
			r:cyl(0, 4.3, 0, 0.3, 1.9, "y", shade(r.c1, 0.82), "Metal")
			r:lump(CFrame.new(0, 4.5, 0), 1.8, 1.1, 1.8, r.c1, "Metal")
			r:cyl(0, 5.08, 0, 0.16, 0.4, "y", r.c2, "Metal")
			r:block(-0.52, 3.42, 0.7, 0.52, 3.66, 0.84, r.c2, "Metal")
			r:block(-0.64, 3.66, 0.6, 0.64, 3.78, 0.94, shade(r.c1, 0.82), "Metal")
			r:block(-0.38, 2.4, 0.74, 0.38, 3.1, 0.84, C.Paper, "SmoothPlastic")
			r:block(-0.26, 2.84, 0.84, 0.26, 2.92, 0.86, r.c2, "SmoothPlastic")
			r:block(-0.26, 2.62, 0.84, 0.12, 2.7, 0.86, r.c2, "SmoothPlastic")
		end,
	},
	{
		id = "sorting_shelves",
		name = "Sorting shelves",
		cat = "storage",
		price = 170,
		place = "floor",
		size = Vector3.new(4.4, 6.6, 1.8),
		c1 = "9A6B48",
		c2 = "F2E6CC",
		tags = { "storage" },
		build = function(r: R)
			-- Pigeonholes of letters over two shelves of parcels and a sack: c1 the wood, c2
			-- the labels under each row.
			local dk = shade(r.c1, 0.82)
			r:block(-2.2, 0, -0.9, -2.04, 6.4, 0.85, r.c1, "Wood")
			r:block(2.04, 0, -0.9, 2.2, 6.4, 0.85, r.c1, "Wood")
			r:block(-2.04, 0.3, -0.9, 2.04, 6.4, -0.78, shade(r.c1, 0.7), "Wood")
			r:block(-2.26, 6.4, -0.9, 2.26, 6.58, 0.9, dk, "Wood")
			r:block(-2.04, 0, -0.78, 2.04, 0.3, 0.75, dk, "Wood")
			-- two deep shelves below
			for _, y in { 0.3, 1.5 } do
				r:block(-2.04, y, -0.78, 2.04, y + 0.14, 0.82, r.c1, "Wood")
			end
			parcel(r, -1.8, 0.44, -0.5, -0.5, 1.3, 0.6, KRAFT)
			parcel(r, -0.3, 0.44, -0.6, 0.5, 1.0, 0.5, shade(KRAFT, 0.88))
			r:lump(CFrame.new(1.3, 0.92, 0), 1.3, 1.0, 1.2, Color3.fromRGB(150, 160, 172), "Fabric")
			r:cyl(1.3, 1.42, 0, 0.2, 0.5, "y", Color3.fromRGB(128, 138, 150), "Fabric")
			parcel(r, -1.6, 1.64, -0.6, -0.2, 2.3, 0.5, shade(KRAFT, 0.92))
			parcel(r, 0.4, 1.64, -0.5, 1.7, 2.5, 0.6, KRAFT)
			-- four rows of four pigeonholes
			r:block(-2.04, 2.7, -0.78, 2.04, 2.84, 0.82, r.c1, "Wood")
			for row = 1, 4 do
				local y = 2.84 + row * 0.89
				r:block(-2.04, y - 0.1, -0.78, 2.04, y, 0.78, r.c1, "Wood")
				r:block(-2.04, y - 0.14, 0.78, 2.04, y + 0.02, 0.82, r.c2, "SmoothPlastic")
			end
			for i = 1, 3 do
				local x = -2.04 + i * 1.02
				r:block(x - 0.05, 2.84, -0.78, x + 0.05, 6.4, 0.76, r.c1, "Wood")
			end
			local paper = { C.Paper, Color3.fromRGB(222, 206, 170), Color3.fromRGB(188, 208, 226), C.Paper }
			r:piece(function(q: R)
				for row = 0, 3 do
					for col = 0, 3 do
						local n = (row * 5 + col * 3) % 4
						if n ~= 3 then
							local x = -2.04 + col * 1.02 + 0.16
							local y = 2.84 + row * 0.89
							for k = 0, n do
								q:block(
									x + k * 0.2,
									y,
									-0.6,
									x + k * 0.2 + 0.07,
									y + 0.5 + ((k + col) % 2) * 0.12,
									0.6 - k * 0.08,
									paper[(row + col + k) % 4 + 1],
									"SmoothPlastic"
								)
							end
						end
					end
				end
			end)
		end,
	},
	{
		id = "parcel_cart",
		name = "Parcel trolley",
		cat = "storage",
		price = 80,
		place = "floor",
		size = Vector3.new(2.8, 4.8, 3),
		c1 = "B8505A",
		c2 = "C49A6C",
		tags = { "storage" },
		build = function(r: R)
			-- A sack truck (c1) with three parcels (c2) tied up with string on its plate. The
			-- handles are at the back (-z).
			for _, sx in { -1, 1 } do
				local x = sx * 0.9
				r:block(x - 0.08, 0.5, -1.12, x + 0.08, 4.5, -0.96, r.c1, "Metal")
				r:cyl(sx * 1.2, 0.6, -1.0, 0.3, 1.2, "x", C.Black, "SmoothPlastic")
				r:cyl(sx * 1.2, 0.6, -1.0, 0.4, 0.46, "x", C.Metal, "Metal")
			end
			r:cyl(0, 0.6, -1.0, 2.2, 0.14, "x", C.DarkMetal, "Metal")
			for _, y in { 1.5, 2.8, 4.1 } do
				r:block(-0.9, y, -1.1, 0.9, y + 0.14, -0.98, r.c1, "Metal")
			end
			r:cyl(0, 4.5, -1.04, 2.3, 0.2, "x", C.Black, "SmoothPlastic")
			r:block(-1.05, 0.3, -1.1, 1.05, 0.42, 0.9, r.c1, "Metal")
			r:block(-0.14, 0, 0.6, 0.14, 0.3, 0.86, C.DarkMetal, "Metal")
			parcel(r, -1.0, 0.42, -0.9, 1.0, 1.7, 0.8, r.c2)
			parcel(r, -0.8, 1.7, -0.86, 0.7, 2.7, 0.5, shade(r.c2, 0.9))
			parcel(r, -0.5, 2.7, -0.8, 0.6, 3.4, 0.2, Colors.mix(r.c2, C.White, 0.2))
			r:block(-0.75, 0.9, 0.8, -0.15, 1.4, 0.84, C.Paper, "SmoothPlastic")
		end,
	},
	{
		id = "gable_clock",
		name = "Gable clock",
		cat = "walldecor",
		style = "fancy",
		price = 150,
		place = "floor",
		size = Vector3.new(4.4, 5.6, 1.4),
		c1 = "FAF6EC",
		c2 = "5A5560",
		build = function(r: R)
			-- A big clock for a gable end, where nothing can hang: stand it on the floor above,
			-- the middle of its footprint on the wall's line and its back to the gable (the
			-- attic window goes up the same way). c1 the face, c2 the rim and the hands.
			local z0 = 0.3 -- the gable's face
			local y = 3 -- the middle of the face
			r:noCollide(r:cyl(0, y, z0 + 0.16, 0.32, 4.2, "z", r.c2, "Metal"))
			r:noCollide(r:cyl(0, y, z0 + 0.34, 0.06, 3.6, "z", r.c1, "SmoothPlastic"))
			r:piece(function(q: R)
				for i = 0, 11 do
					local a = i * math.pi / 6
					local big = i % 3 == 0
					local len = if big then 0.5 else 0.28
					local cf = CFrame.new(math.cos(a) * 1.45, y + math.sin(a) * 1.45, z0 + 0.39)
						* CFrame.Angles(0, 0, a)
					q:boxAt(cf, len, if big then 0.16 else 0.09, 0.04, r.c2, "SmoothPlastic")
				end
			end)
			-- ten past ten
			r:noCollide(
				r:boxAt(
					CFrame.new(-0.36, y + 0.3, z0 + 0.42) * CFrame.Angles(0, 0, 0.88),
					0.16,
					0.95,
					0.04,
					r.c2,
					"Metal"
				)
			)
			r:noCollide(
				r:boxAt(
					CFrame.new(0.52, y + 0.42, z0 + 0.45) * CFrame.Angles(0, 0, -0.88),
					0.12,
					1.4,
					0.04,
					r.c2,
					"Metal"
				)
			)
			r:noCollide(r:cyl(0, y, z0 + 0.75 - 0.3, 0.18, 0.34, "z", C.Gold, "Metal"))
		end,
	},
	{
		id = "sign_post",
		name = "Post office sign",
		cat = "walldecor",
		price = 40,
		place = "wall",
		size = Vector3.new(0.6, 3.6, 3.2),
		c1 = "46608E",
		c2 = "FAF6EC",
		build = function(r: R)
			-- a hanging board with a letter on both faces: c1 the board, c2 the envelope
			local paper = r.c2
			local line = shade(r.c2, 0.6)
			hangingSign(r, function(q: R, x: number)
				local out = if x > 0 then 0.04 else -0.04
				q:box(x, 1.85, 1.75, 0.04, 1.1, 1.7, paper, "SmoothPlastic")
				-- the flap: two lines down from the top corners to the middle
				for _, sz in { -1, 1 } do
					local cf = CFrame.new(x + out, 2.13, 1.75 + sz * 0.42) * CFrame.Angles(sz * 0.58, 0, 0)
					q:boxAt(cf, 0.04, 0.07, 1.0, line, "SmoothPlastic")
				end
				q:box(x + out, 1.86, 1.75, 0.04, 0.26, 0.26, BERRY, "SmoothPlastic")
			end)
		end,
	},
	-- the library ----------------------------------------------------------------------------
	{
		id = "bookcase_tall",
		name = "Tall bookcase with a ladder",
		gives = "books", -- holding E gives something (Data/Items.Sources)
		cat = "storage",
		style = "fancy",
		price = 320,
		place = "floor",
		size = Vector3.new(5, 10.6, 2.6),
		c1 = "9A6B48",
		c2 = "D9A93F",
		tags = { "books", "storage" },
		build = function(r: R)
			-- Six shelves of books nearly to the ceiling, with a ladder on a rail to reach the
			-- top ones: c1 the case, c2 the rail and the ladder.
			local dk = shade(r.c1, 0.82)
			local zb, zf = -1.3, -0.1 -- the back of the case, its front edge
			r:block(-2.5, 0, zb, -2.3, 10.2, zf, r.c1, "Wood")
			r:block(2.3, 0, zb, 2.5, 10.2, zf, r.c1, "Wood")
			r:block(-2.3, 0.5, zb, 2.3, 10.2, zb + 0.12, shade(r.c1, 0.68), "Wood")
			r:block(-2.3, 0, zb + 0.1, 2.3, 0.5, zf - 0.1, dk, "Wood")
			r:block(-2.58, 10.2, zb, 2.58, 10.4, zf + 0.06, r.c1, "Wood")
			r:block(-2.64, 10.4, zb, 2.64, 10.6, zf + 0.14, dk, "Wood")
			r:block(-0.08, 0.5, zb + 0.12, 0.08, 10.2, zf - 0.04, r.c1, "Wood")
			for i = 0, 5 do
				local y = 0.5 + i * 1.62
				r:block(-2.3, y, zb + 0.12, 2.3, y + 0.14, zf, r.c1, "Wood")
				books(r, -2.24, -0.12, y + 0.14, 1.3, zf - 0.06, 5 + i * 7)
				books(r, 0.12, 2.24, y + 0.14, 1.3, zf - 0.06, 23 + i * 11)
			end
			-- the rail and the ladder leaning on it
			r:cyl(0, 8.3, 0.08, 4.9, 0.14, "x", r.c2, "Metal")
			for _, x in { -2.2, 2.2 } do
				r:block(x - 0.06, 8.24, zf, x + 0.06, 8.36, 0.1, r.c2, "Metal")
			end
			local foot, head = Vector3.new(0, 0, 1.2), Vector3.new(0, 8.5, 0.16)
			for _, sx in { -1, 1 } do
				local off = Vector3.new(1.2 + sx * 0.5, 0, 0)
				r:beam(foot + off, head + off, 0.14, 0.2, r.c2, "Wood")
			end
			r:piece(function(q: R)
				for i = 1, 7 do
					local p = foot:Lerp(head, i / 8) + Vector3.new(1.2, 0, 0)
					q:box(p.X, p.Y, p.Z, 0.9, 0.1, 0.22, r.c2, "Wood")
				end
			end)
		end,
	},
	{
		id = "sign_library",
		name = "Library sign",
		cat = "walldecor",
		price = 40,
		place = "wall",
		size = Vector3.new(0.6, 3.6, 3.2),
		c1 = "F2E6CC",
		c2 = "B8505A",
		build = function(r: R)
			-- a hanging board with an open book on both faces: c1 the board, c2 the cover
			local cover = r.c2
			local ink = Color3.fromRGB(96, 92, 88)
			hangingSign(r, function(q: R, x: number)
				local out = if x > 0 then 0.04 else -0.04
				q:box(x, 1.78, 1.75, 0.04, 1.2, 1.9, cover, "SmoothPlastic")
				for _, sz in { -1, 1 } do
					q:box(x + out, 1.86, 1.75 + sz * 0.46, 0.04, 1.04, 0.8, C.Paper, "SmoothPlastic")
					for i = 0, 2 do
						q:box(x + out * 2, 2.14 - i * 0.26, 1.75 + sz * 0.46, 0.04, 0.06, 0.54, ink, "SmoothPlastic")
					end
				end
			end)
		end,
	},
}

return items
