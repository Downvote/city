--!strict
-- The ice cream parlour, where the ice cream seller works. A flat roofed kiosk in boards striped
-- blush and white, with a serving hatch in the middle of its front, the ice cream cart just
-- inside it and a giant cone up on the roof. Inside are a freezer of tubs, a booth and a table;
-- out of the side door is an open pavilion under a little pyramid roof with a picnic table, and
-- behind it a blossom tree.
--
-- The frame: x across, z back from the street (z = 0). The kiosk is x 2..22 and z 6..20, the
-- pavilion beside it x 22..32 and z 6..16.

local Catalog = require(script.Parent.Parent.Parent.Build.Catalog)
local Tuning = require(script.Parent.Parent.Parent.Config.Tuning)

type Finish = { c: string, m: string }

local F = Tuning.Plot.Foundation

-- finishes: boards in two colours for the stripes, a sage parapet and pavilion roof
local BLUSH: Finish = { c = "E6BAB4", m = "WoodPlanks" }
local WHITE: Finish = { c = "F6F0E2", m = "WoodPlanks" }
local INSIDE: Finish = { c = "F6EDE6", m = "SmoothPlastic" }
local FLAT: Finish = { c = "D8D2C6", m = "Concrete" }
local SAGE: Finish = { c = "86A886", m = "RoofShingles" }
local SAGE_BAND: Finish = { c = "86A886", m = "SmoothPlastic" }
local TILES: Finish = { c = "EADFD8", m = "CeramicTiles" }
local DECK: Finish = { c = "DDBE94", m = "WoodPlanks" }
local PAVING: Finish = { c = "EAE6DC", m = "Pavement" }
local RAIL: Finish = { c = "FAF6EC", m = "Wood" }

-- paint for the pieces
local TRIM = "FAF6EC"
local BERRY = "B8505A"
local WALNUT = "9A6B48"
local MINT = "B6D8C6"

-- The last piece laid, painted.
local function paint(b: any, c1: string?, c2: string?)
	local obj = b.objects[#b.objects].obj
	obj.c1 = c1
	obj.c2 = c2
end

-- Something hung on a named wall: `t` along it, its bottom `y` above the wall's foot (the ground
-- on the ground floor), on side "a" (outside) or "b".
local function hang(b: any, id: string, wall: string, t: number, y: number, side: string, c1: string?, c2: string?)
	table.insert(b.objects, {
		kind = "items",
		obj = { id = id, x = 0, y = y, z = 0, r = 0, lv = b.walls[wall].lv, t = t, side = side, c1 = c1, c2 = c2 },
		wallName = wall,
	})
end

-- The top of a piece standing on the floor, for what stands on it.
local function top(id: string): number
	local def = Catalog.get(id)
	return F + (if def and def.surface then def.surface else 0)
end

-- A run of walls along a line, each `len` studs long in turn blush and white, starting with
-- `first`: the stripes. Returns the names given to them, prefix .. 1, 2 and on.
local function stripes(
	b: any,
	prefix: string,
	x1: number,
	z1: number,
	x2: number,
	z2: number,
	lengths: { number },
	first: Finish,
	other: Finish
)
	local dx, dz = x2 - x1, z2 - z1
	local total = math.abs(dx) + math.abs(dz)
	local ux, uz = dx / total, dz / total
	local at = 0
	for i, len in lengths do
		local finish = if i % 2 == 1 then first else other
		b:wall(prefix .. i, x1 + ux * at, z1 + uz * at, x1 + ux * (at + len), z1 + uz * (at + len), finish, INSIDE)
		at += len
	end
end

return function(add: any)
	add(
		"icecream",
		"Ice cream parlour",
		"Scoops through the hatch, a booth inside and a pavilion with a picnic table.",
		"sun",
		34,
		24,
		function(b: any)
			-- the floors
			b:floor(2, 6, 22, 20, TILES)
			b:floor(22, 6, 32, 16, DECK)
			b:floor(0, 0, 34, 6, PAVING)

			-- the kiosk: the front in stripes either side of the hatch's long board, the left side
			-- in stripes round a window's, plain blush behind and on the pavilion side
			stripes(b, "front", 2, 6, 22, 6, { 2, 2, 2, 8, 2, 2, 2 }, BLUSH, WHITE)
			b:wall("back", 22, 20, 2, 20, BLUSH, INSIDE)
			b:wall("side", 22, 6, 22, 20, BLUSH, INSIDE)
			b:roof(2, 6, 22, 20, "flat", 0, 0, FLAT, SAGE_BAND, 0, 0.6)
			-- the pavilion: a rail round its open sides, a pyramid roof on posts
			b:wall("railright", 32, 6, 32, 16, RAIL, RAIL)
			b.walls.railright.style = "railing"
			b:wall("railback", 32, 16, 22, 16, RAIL, RAIL)
			b.walls.railback.style = "railing"
			b:wall("railfront", 28, 6, 32, 6, RAIL, RAIL)
			b.walls.railfront.style = "railing"
			b:roof(22, 6, 32, 16, "pyramid", 5, 0, SAGE, SAGE, 0, 0.8)

			-- doors and windows
			b:open("hatch_serving", "front4", 4)
			paint(b, "DDBE94", TRIM)
			b:open("door_glass", "side", 5)
			paint(b, BERRY, BERRY)
			b:open("win_square", "side", 11)
			b:open("win_wide", "back", 15.4)
			b:open("win_square", "back", 5)

			-- outside ---------------------------------------------------------------------------
			-- the giant cone up on the roof over the hatch, bunting over the hatch, baskets on the
			-- stripes beside it, an awning on the side window, lights strung in the pavilion
			b:item("cone_giant", 12, 10.4, 0, 1)
			hang(b, "bunting", "front4", 4, 10.4, "a")
			for _, w in { "front3", "front5" } do
				hang(b, "hanging_basket", w, 1, 7.6, "a")
			end
			hang(b, "lantern_wall", "front1", 1, 5.6, "a")
			hang(b, "lantern_wall", "front7", 1, 5.6, "a")
			for _, t in { 15.4, 5 } do
				hang(b, "window_hood", "back", t, F + 7.38, "a", TRIM, SAGE.c)
				hang(b, "window_box", "back", t, F + 1.65, "a", WALNUT, BERRY)
			end
			hang(b, "window_hood", "side", 11, F + 7.38, "a", TRIM, SAGE.c)
			hang(b, "window_box", "side", 11, F + 1.65, "a", WALNUT, MINT)
			for _, t in { 2, 6, 10, 14, 18 } do
				hang(b, "stone_footing", "back", t, 0, "a", "BDB8AE")
			end
			hang(b, "trellis", "back", 10.6, 1.3, "a")
			hang(b, "string_lights", "side", 5, 10.4, "a")
			hang(b, "lantern_wall", "side", 1.4, 5.6, "a")
			for _, c in { { 2, 6, 180 }, { 22, 20, 0 }, { 2, 20, 270 } } do
				b:item("corner_board", c[1], c[2], c[3], 0, 0)
				paint(b, TRIM, TRIM)
			end
			hang(b, "downpipe", "back", 0.6, 0, "a")
			hang(b, "downpipe", "back", 19.4, 0, "a")
			-- the pavilion's posts (their feet a hair in from the rail's posts), its picnic table
			-- and a bench along the back rail
			for _, p in { { 31.5, 6.6 }, { 31.5, 15.4 }, { 28, 15.4 } } do
				b:item("porch_post", p[1], p[2], 0)
				paint(b, TRIM, TRIM)
			end
			b:item("porch_post", 31.5, 11, 90)
			paint(b, TRIM, TRIM)
			b:item("picnic_table", 28, 11, 0, 0, F)
			b:item("vase_flowers", 28, 11, 0, 0, F + 2.8)
			b:item("lantern", 26.6, 11.4, 0, 0, F + 2.8)
			b:item("bench_wood", 24.8, 14.9, 180)
			b:item("lamp_pendant", 28, 11, 0)
			b:item("flower_pot", 23, 6.8, 0)
			b:item("flower_pot", 31, 13, 0)
			b:item("doormat", 23.2, 11, 90)

			-- the pavement: a queue for the hatch between a board and a planter, a lamp at each
			-- end, a sun umbrella over a table for the overflow
			b:item("menu_board", 5.6, 3.2, 160)
			b:item("planter_box", 18.6, 1, 0, 0, F)
			b:item("lamp_post", 1.2, 1.4, 0, 0, F)
			b:item("lamp_post", 22.8, 1.2, 0, 0, F)
			b:item("umbrella_sun", 29.4, 3, 0, 0, F)
			b:item("table_round", 29.4, 3, 0)
			paint(b, TRIM, WALNUT)
			b:item("chair_wood", 27.2, 3, 90)
			b:item("chair_wood", 31.6, 3, 270)
			b:item("flower_pot", 24.4, 1.2, 0)
			b:item("flower_pot", 20.6, 4.6, 0)
			b:item("flower_pot", 3.4, 4.6, 0)
			b:item("bicycle", 0.9, 11, 0)
			for _, z in { 16.2, 20.4 } do
				b:item("flower_border", 0.9, z, 90)
			end

			-- behind: a blossom tree in the grass, deck chairs under it, the water butt and crates
			b:item("tree_blossom", 27.6, 20.4, 0)
			b:item("beach_chair", 24.6, 21.6, 150)
			b:item("beach_chair", 31.6, 20.4, 210)
			b:item("bird_house", 32.8, 22.8, 200)
			b:item("water_butt", 3.4, 22.6, 90)
			b:item("crate", 7, 22.4, 0)
			b:item("crate", 7.1, 22.3, 25, 0, 2)
			b:item("crate", 9.4, 22.6, 340)
			b:item("bush", 17.6, 22.2, 0)

			-- the kiosk ------------------------------------------------------------------------------
			-- the cart just inside the hatch, the freezer of tubs along the side
			b:item("work_icecream", 12, 9, 180)
			paint(b, "EBC8C2", TRIM)
			b:item("freezer_icecream", 3.6, 11, 90)
			paint(b, TRIM, BERRY)
			hang(b, "shelf_wall", "front4", 4, 9.2, "b")
			b:item("coat_stand", 20.6, 7.4, 0)
			-- a booth by the back window, a table for two on a rug, the worker's counters along
			-- the back with the sink, the kettle and the fridge
			b:item("booth_seat", 3.5, 17.3, 90)
			paint(b, BERRY, TRIM)
			b:item("table_round", 6.5, 17.3, 0)
			paint(b, TRIM, WALNUT)
			b:item("booth_seat", 9.5, 17.3, 270)
			paint(b, BERRY, TRIM)
			b:item("vase_flowers", 6.5, 17.3, 0, 0, top("table_round"))
			b:item("rug_round", 15.6, 14.4, 0)
			b:item("table_round", 15.6, 14.4, 0)
			paint(b, TRIM, WALNUT)
			b:item("chair_wood", 13.4, 14.4, 90)
			b:item("chair_wood", 17.8, 14.4, 270)
			b:item("counter_sink", 14.2, 18.4, 180)
			b:item("counter", 17.2, 18.4, 180)
			b:item("fridge", 20.2, 18.4, 180)
			b:item("kettle", 17.6, 18.5, 160, 0, top("counter"))
			b:item("plant_small", 16.4, 18.6, 0, 0, top("counter"))
			b:item("lamp_pendant", 6.5, 17.4, 0)
			b:item("lamp_pendant", 15.6, 14.4, 0)
			b:item("light_ceiling", 12, 13, 0)
			b:item("light_ceiling", 6.5, 11, 0)
			hang(b, "curtains", "back", 15.4, F + 2.2, "b", "F2E6CC", BERRY)
			hang(b, "shelf_wall", "back", 9.8, 7.2, "b")
			hang(b, "art_abstract", "side", 7.6, 9.2, "b")
			hang(b, "clock_wall", "side", 11, 9, "b")
			hang(b, "sconce", "side", 2, 6.4, "b")
			hang(b, "coat_hooks", "back", 1.6, 7.8, "b")
			b:item("flower_pot", 13.1, 18.6, 0, 0, top("counter_sink"))

			-- opened up: the kiosk wider either side of the cart and deeper behind it, the
			-- pavilion with it
			b:spread({ x = { { 11.5, 4 }, { 12.3, 4 } }, z = { { 12.6, 6 } } })
			-- the left side in stripes round its window, on the longer wall
			stripes(b, "left", 2, 26, 2, 6, { 2, 2, 12, 2, 2 }, BLUSH, WHITE)
			b:open("win_square", "left3", 6)
			hang(b, "awning", "left3", 6, F + 7.2, "a", BERRY, TRIM)
			hang(b, "window_box", "left3", 6, F + 1.65, "a", WALNUT, MINT)
			hang(b, "art_abstract", "left2", 1, 7, "b")
			hang(b, "art_flowers", "left3", 6, 8.2, "b")
			hang(b, "sconce", "left1", 1, 6.4, "b")
			-- a post more along the pavilion's longer side, and a table for two by the freezer
			b:item("porch_post", 39.5, 16.2, 90)
			paint(b, TRIM, TRIM)
			b:item("table_round", 9.6, 15.6, 0)
			paint(b, TRIM, WALNUT)
			b:item("chair_wood", 7.4, 15.6, 90)
			b:item("chair_wood", 11.8, 15.6, 270)
			b:item("vase_flowers", 9.6, 15.6, 0, 0, top("table_round"))
			b:item("lamp_pendant", 9.6, 15.6, 0)
		end
	)
end
