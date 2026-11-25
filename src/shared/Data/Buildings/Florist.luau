--!strict
-- The florist's: a tall shop with its gable to the street and a glasshouse beside it, buckets of
-- flowers out on the pavement, a terrace in front of the glasshouse and a little cutting garden
-- behind a picket fence at the back.
local Catalog = require(script.Parent.Parent.Parent.Build.Catalog)
local Tuning = require(script.Parent.Parent.Parent.Config.Tuning)

type Finish = { c: string, m: string }

local F = Tuning.Plot.Foundation

-- finishes (the town's palette)
local PEACH: Finish = { c = "F0CDB0", m = "WoodPlanks" } -- the shop outside
local SHOP_IN: Finish = { c = "F6F0E2", m = "WoodPlanks" }
local BOARDS: Finish = { c = "FAF6EC", m = "WoodPlanks" } -- the gable end
local TRIM: Finish = { c = "FAF6EC", m = "WoodPlanks" } -- the glasshouse's frames and white wall
local TEAL: Finish = { c = "4F8A8C", m = "RoofShingles" }
local PANES: Finish = { c = "CFE0DE", m = "Glass" } -- the glasshouse roof: pale glass, on purpose
local TILES: Finish = { c = "F2E6CC", m = "CeramicTiles" }
local RED_BRICK: Finish = { c = "D69A82", m = "Brick" } -- the glasshouse floor
local PAVING: Finish = { c = "EAE6DC", m = "Pavement" }
local PICKETS: Finish = { c = "FAF6EC", m = "Wood" }
-- paint for the pieces
local WHITE = "FAF6EC"
local FOREST = "4E7F62" -- the accent: the door, the awnings, the cart
local FOREST_DARK = "3E6650"
local OAK = "C49A6C"
local WALNUT = "9A6B48"
local PINK = "E8879A"
local CORAL = "E08566"
local LILAC = "9C86B8"
local BUTTER = "E9C46A"

-- what was laid last takes these paints
local function paint(b: any, c1: string?, c2: string?)
	local o = b.objects[#b.objects].obj
	o.c1 = c1
	o.c2 = c2
end

-- something hung on a wall, its bottom `y` above the wall's foot, on side "a" or "b"
local function hang(b: any, id: string, wall: string, t: number, y: number, side: string?, c1: string?, c2: string?)
	local w = b.walls[wall]
	assert(w and Catalog.get(id), "bad wall piece " .. id .. " on " .. wall)
	table.insert(b.objects, {
		kind = "items",
		obj = { id = id, x = 0, y = y, z = 0, r = 0, lv = w.lv, t = t, side = side or "a", c1 = c1, c2 = c2 },
		wallName = wall,
	})
end

-- a free-standing piece on the ground floor, painted if given
-- a wall of another style (stone, fence, glass), the same finish both sides
local function styled(b: any, name: string, x1: number, z1: number, x2: number, z2: number, f: Finish, style: string)
	b:wall(name, x1, z1, x2, z2, f, f)
	b.walls[name].style = style
end

local function put(b: any, id: string, x: number, z: number, r: number?, y: number?, c1: string?, c2: string?)
	b:item(id, x, z, r or 0, 0, y)
	if c1 or c2 then
		paint(b, c1, c2)
	end
end

-- the top of a piece of furniture standing on the floor, for what stands on it
local function top(id: string): number
	local def = Catalog.get(id)
	return F + (if def and def.surface then def.surface else 0)
end

return function(add: any)
	add(
		"florist",
		"Flower shop",
		"A flower shop with a glasshouse built on the side.",
		"flower",
		34,
		30,
		function(b: any)
			-- The shop is x 2 to 18 and z 8 to 24, its gable to the street. The glasshouse is set
			-- back beside it (x 18 to 32, z 12 to 24) behind a little terrace, the pavement runs
			-- along the front and the cutting garden along the back.
			b:floor(2, 8, 18, 24, TILES)
			b:floor(18, 12, 32, 24, RED_BRICK)
			b:floor(0, 0, 34, 8, PAVING)
			b:floor(18, 8, 32, 12, PAVING)

			b:wall("front", 2, 8, 18, 8, PEACH, SHOP_IN)
			b:wall("side", 18, 8, 18, 12, PEACH, SHOP_IN)
			b:wall("party", 18, 12, 18, 24, PEACH, SHOP_IN) -- side a is the glasshouse's
			b:wall("back", 18, 24, 2, 24, PEACH, SHOP_IN)
			b:wall("left", 2, 24, 2, 8, PEACH, SHOP_IN)
			-- the glasshouse: glass all round but for a white piece of wall that takes the door
			styled(b, "glassfront1", 18, 12, 22, 12, TRIM, "glass")
			b:wall("glassdoor", 22, 12, 28, 12, TRIM, TRIM)
			styled(b, "glassfront2", 28, 12, 32, 12, TRIM, "glass")
			styled(b, "glassright", 32, 12, 32, 24, TRIM, "glass")
			styled(b, "glassback", 32, 24, 18, 24, TRIM, "glass")
			-- the picket fence round the garden, open at the right end where the side path comes in
			styled(b, "fenceback", 32, 30, 2, 30, PICKETS, "fence")
			styled(b, "fenceleft", 2, 30, 2, 24, PICKETS, "fence")

			-- the shop's steep roof, and the glasshouse's, which dies into the shop's slope
			b:roof(2, 8, 18, 24, "gable", 9, 1, TEAL, BOARDS, 0, 1.2)
			b:roof(12, 12, 32, 24, "gable", 5, 0, PANES, PANES, 0, 0.6)

			-- doors and windows
			b:open("win_picture", "front", 6)
			paint(b, FOREST, FOREST)
			b:open("door_front", "front", 13.4)
			paint(b, FOREST, WHITE)
			b:open("win_square", "left", 4.6)
			b:open("win_square", "left", 11.4)
			b:open("door_wood", "back", 2.6)
			paint(b, FOREST, WHITE)
			b:open("win_square", "back", 10)
			b:open("arch_wide", "party", 5.2)
			b:open("door_glass", "glassdoor", 3.6)
			paint(b, FOREST, FOREST)

			-- outside: the awnings over the window, the sign out from the side wall where the
			-- street can read it, trim at the windows, stone along the foot of the walls
			hang(b, "awning", "front", 3.2, 8.8, "a", FOREST, WHITE)
			hang(b, "awning", "front", 9.2, 8.8, "a", FOREST, WHITE)
			hang(b, "sign_flowers", "side", 0.9, 8.6, "a")
			hang(b, "lantern_wall", "side", 2.8, 5.6, "a")
			hang(b, "hanging_basket", "side", 0.9, 5.2, "a", WALNUT, BUTTER)
			for _, t in { 4.6, 11.4 } do
				hang(b, "window_hood", "left", t, 7.78, "a", WHITE, TEAL.c)
				hang(b, "window_box", "left", t, 2.05, "a", WHITE, PINK)
			end
			hang(b, "hanging_basket", "left", 8, 5.4, "a", WALNUT, CORAL)
			hang(b, "shutters", "back", 10, 3.25, "a", FOREST, FOREST_DARK)
			hang(b, "window_hood", "back", 10, 7.78, "a", WHITE, TEAL.c)
			hang(b, "window_box", "back", 10, 2.05, "a", WHITE, LILAC)
			for _, t in { 2, 6, 10, 14 } do
				hang(b, "stone_footing", "left", t, 0, "a")
			end
			for _, t in { 6.9, 10.45, 14 } do -- (clear of the door's frame)
				hang(b, "stone_footing", "back", t, 0, "a")
			end
			hang(b, "stone_footing", "side", 2, 0, "a")
			hang(b, "downpipe", "back", 14.6, 0, "a")
			put(b, "water_butt", 3.4, 25.7, 0, nil, FOREST, WALNUT)
			put(b, "corner_board", 2, 8, 180, 0)
			put(b, "corner_board", 18, 8, 90, 0)
			put(b, "corner_board", 2, 24, 270, 0)
			-- the attic windows up in the gables
			b:item("window_attic", 10, 8, 180, 1)
			paint(b, WHITE, FOREST)
			b:item("window_attic", 10, 24, 0, 1)
			paint(b, WHITE, FOREST)

			-- the pavement: steps of buckets under the window, pots by the door, a bike, a lamp
			put(b, "flower_stand", 8, 6.2, 180, F, FOREST, PINK)
			put(b, "flower_pot", 3.4, 7, 0, F, nil, CORAL)
			put(b, "flower_pot", 4.7, 6.7, 0, F, nil, BUTTER)
			put(b, "flower_pot", 11.3, 7, 0, F, nil, LILAC)
			put(b, "flower_pot", 12.2, 5.6, 0, F, nil, PINK)
			put(b, "lamp_post", 18, 3, 0, F)
			put(b, "lamp_post", 1, 1.4, 0, F)
			put(b, "mailbox", 1, 5.6, 90, F, FOREST, WALNUT)
			put(b, "bicycle", 11, 3.4, 90, F, FOREST, WALNUT)
			put(b, "doormat", 15.4, 9.4, 0)
			put(b, "planter_box", 4, 2.9, 0, F, OAK, PINK)
			put(b, "planter_box", 25, 2.9, 0, F, OAK, BUTTER)
			-- the terrace in front of the glasshouse
			put(b, "flower_stand", 20.9, 10.4, 180, F, FOREST, LILAC)
			put(b, "bench_garden", 30.4, 9.4, 180, F, OAK, FOREST)
			put(b, "flower_pot", 31.3, 11, 0, F, nil, PINK)
			put(b, "flower_pot", 28.8, 11.1, 0, F, nil, BUTTER)
			put(b, "flower_pot", 16.4, 3.2, 0, F, nil, CORAL)
			put(b, "flower_pot", 19.6, 3.6, 0, F, nil, LILAC)
			-- the side path down the right to the garden, and the flowers along the left
			put(b, "path_stones", 33, 13.5, 0)
			put(b, "path_stones", 33, 17.5, 90)
			put(b, "path_stones", 33, 21.5, 0)
			put(b, "path_stones", 32.8, 25.6, 0)
			for _, z in { 11.2, 16, 20.8 } do
				put(b, "flower_border", 1, z, 270, nil, WHITE, PINK)
			end

			-- the cutting garden behind: a bench against the fence, a potting bench against the
			-- glass, beds of flowers to cut, and the stones from the back door
			put(b, "path_stones", 15.4, 25.4, 0)
			put(b, "path_stones", 15.6, 27.8, 10)
			put(b, "bench_garden", 8.2, 28.8, 180, nil, OAK, FOREST)
			put(b, "bush", 3.8, 28.4, 0)
			put(b, "flower_bed", 11.2, 25.8, 0, nil, PINK)
			put(b, "gnome", 17.4, 28.9, 200)
			put(b, "plant_bench", 22.6, 25.5, 0, 0, OAK, BUTTER)
			put(b, "flower_bed", 21.2, 28.8, 0, nil, LILAC)
			put(b, "flower_bed", 25.8, 28.8, 0, nil, CORAL)
			put(b, "bird_house", 29.8, 28.6, 0, nil, WHITE, FOREST)
			put(b, "crate", 29.6, 25.6, 10, 0, OAK, OAK)
			put(b, "flower_pot", 29.6, 25.6, 0, 2, nil, PINK)
			put(b, "path_stones", 33, 28.6, 0)

			-- the shop: the flower cart in the middle with room all round it, steps of buckets
			-- along the left wall, a long table of vases in the window, and the back counter
			-- where the bunches are made up, a kettle on the end of it
			put(b, "work_flowers", 10.5, 17, 180, nil, FOREST, WHITE)
			put(b, "rug_round", 10.5, 13.2, 0, nil, "D9B8A8", WHITE)
			put(b, "flower_stand", 3.8, 13.8, 90, nil, FOREST, CORAL)
			put(b, "flower_stand", 3.8, 18.9, 90, nil, FOREST, BUTTER)
			put(b, "flower_pot", 3.2, 9.2, 0, F, nil, PINK)
			put(b, "flower_pot", 4.5, 10.6, 0, F, nil, LILAC)
			put(b, "table_dining_long", 9, 10.4, 0, nil, OAK, WALNUT)
			put(b, "vase_flowers", 6.6, 10.6, 0, top("table_dining_long"), WHITE, PINK)
			put(b, "vase_flowers", 8.4, 10.2, 0, top("table_dining_long"), "8FB3C8", BUTTER)
			put(b, "plant_small", 10.2, 10.6, 0, top("table_dining_long"))
			put(b, "vase_flowers", 11.6, 10.3, 0, top("table_dining_long"), WHITE, LILAC)
			put(b, "coat_stand", 3.3, 22.7, 0, nil, WALNUT, FOREST)
			put(b, "counter_sink", 6.8, 22.4, 180, nil, WHITE, "DAD4C8")
			put(b, "counter", 9.8, 22.4, 180, nil, WHITE, "DAD4C8")
			put(b, "kettle", 10.6, 22.6, 200, top("counter"), CORAL)
			put(b, "vase_flowers", 9.2, 22.7, 0, top("counter"), WHITE, PINK)
			put(b, "stool", 12.3, 22.6, 0, nil, OAK, FOREST)
			put(b, "lamp_pendant", 10.5, 15.2, 0, nil, WHITE)
			put(b, "lamp_pendant", 9, 10.6, 0, nil, WHITE)
			put(b, "light_ceiling", 15.4, 20, 0)
			hang(b, "clock_wall", "back", 14.2, 7.6, "b", FOREST)
			hang(b, "art_flowers", "back", 6, 5.4, "b")
			hang(b, "curtains", "back", 10, 3.9, "b", "CFE2D0", OAK)
			hang(b, "bunting", "back", 8, 10.2, "b", WHITE)
			hang(b, "shelf_wall", "left", 8, 8, "b", OAK)
			hang(b, "art_landscape", "side", 2, 5.6, "b")
			hang(b, "sconce", "party", 10.6, 6.6, "b")

			-- the glasshouse: benches of pots round the glass, a table for two in the middle
			put(b, "plant_bench", 30.4, 17.8, 270, nil, OAK, PINK)
			put(b, "plant_bench", 27.4, 22.5, 180, nil, OAK, CORAL)
			put(b, "plant_bench", 21.4, 22.5, 180, nil, OAK, LILAC)
			put(b, "water_butt", 30.6, 13.5, 0, F, FOREST, WALNUT)
			put(b, "flower_pot", 28.6, 13, 0, F, nil, PINK)
			put(b, "table_round", 25, 17.4, 0, nil, WHITE, OAK)
			put(b, "vase_flowers", 25, 17.4, 0, top("table_round"), WHITE, CORAL)
			put(b, "chair_wood", 22.8, 17.4, 90, nil, WHITE, FOREST)
			put(b, "chair_wood", 27.2, 17.4, 270, nil, WHITE, FOREST)
			put(b, "flower_pot", 22.4, 20.2, 0, F, nil, BUTTER)
			put(b, "flower_pot", 27.8, 20.2, 0, F, nil, PINK)
			put(b, "lamp_pendant", 25, 15, 0, nil, WHITE)
			put(b, "lamp_pendant", 25, 20.2, 0, nil, WHITE)
			hang(b, "string_lights", "party", 5.2, 10.2, "a")
			hang(b, "hanging_basket", "party", 10.9, 6.4, "a", WALNUT, PINK)

			-- opened up: the shop wider either side of the cart and deeper, the glasshouse wider
			-- and deeper, the terrace and the garden with them
			b:spread({ x = { { 5, 4 }, { 14.6, 4 }, { 29, 4 } }, z = { { 11.6, 4 }, { 20.95, 4 } } })
		end
	)
end
