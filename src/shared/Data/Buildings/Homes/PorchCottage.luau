--!strict
-- The porch cottage (cozy): a long, low house under one big shingled roof that sweeps down over
-- a deep porch across its front. A fire on the end wall of the front room, the sofa facing it, a
-- round table by the window; behind, a bedroom, a bathroom and the kitchen. Rocking chairs and a
-- woodpile on the porch, a picket fence and a gate in front, vegetables and a blossom tree out
-- the back.
--
-- The frame: x across, z back from the street (z = 0). The house is x 4..34 and z 14..38, the
-- porch in front of it from z 8, the front garden from the fence at z 0.6.

local HomeKit = require(script.Parent.Parent.HomeKit)

type Finish = HomeKit.Finish

local F = HomeKit.F

-- finishes
local WALLS: Finish = { c = "F2E4C8", m = "Plaster" } -- warm cream
local GABLE: Finish = { c = "DCC6A2", m = "WoodPlanks" } -- honey boards in the gable ends
local ROOF: Finish = { c = "8E6E5C", m = "RoofShingles" } -- cocoa shingles
local FRONT_ROOM: Finish = { c = "F6EEDC", m = "Plaster" }
local BEDROOM: Finish = { c = "E4E9DD", m = "Plaster" }
local BATH: Finish = { c = "E3EDF0", m = "CeramicTiles" }
local KITCHEN: Finish = { c = "F6ECCF", m = "Plaster" }
local OAK: Finish = { c = "C49A6C", m = "WoodPlanks" }
local ROSE_CARPET: Finish = { c = "C9A9A0", m = "Carpet" }
local BATH_TILES: Finish = { c = "DCE6E4", m = "CeramicTiles" }
local KITCHEN_TILES: Finish = { c = "EADBC0", m = "CeramicTiles" }
local DECK: Finish = { c = "B48C64", m = "WoodPlanks" }
-- paint for the pieces
local SAGE = "6E9A7A" -- the door and the shutters
local SAGE_DARK = "557A60"
local WHITE = "FAF6EC"
local ROSE = "D9707F"
local BUTTER = "E9C46A"
local LILAC = "9C86B8"
local WALNUT = "9A6B48"
local OAK_PAINT = "C49A6C"
local CHIMNEY = "C08A72"
local STONE = "BDB8AE"
local PALE_STONE = "DAD4C8"

return function(add: any)
	add(
		"home_porch_cottage",
		"Porch cottage",
		"A long low cottage with a deep porch, a fire in the front room and a gate to the lane.",
		"house",
		38,
		46,
		function(b: any)
			local k = HomeKit.new(b)

			-- the floors -------------------------------------------------------------------------
			b:floor(4, 14, 34, 26, OAK) -- the front room and the dining corner
			b:floor(4, 26, 18, 38, ROSE_CARPET) -- the bedroom
			b:floor(18, 26, 24, 38, BATH_TILES)
			b:floor(24, 26, 34, 38, KITCHEN_TILES)
			b:floor(4, 8, 34, 14, DECK) -- the porch

			-- the walls, clockwise round the outside, then the ones inside ----------------------
			k:wall("front", 4, 14, 34, 14, WALLS, FRONT_ROOM)
			k:wall("rightD", 34, 14, 34, 26, WALLS, FRONT_ROOM)
			k:wall("rightK", 34, 26, 34, 38, WALLS, KITCHEN)
			k:wall("backK", 34, 38, 24, 38, WALLS, KITCHEN)
			k:wall("backB", 24, 38, 18, 38, WALLS, BATH)
			k:wall("backR", 18, 38, 4, 38, WALLS, BEDROOM)
			k:wall("leftB", 4, 38, 4, 26, WALLS, BEDROOM)
			k:wall("leftL", 4, 26, 4, 14, WALLS, FRONT_ROOM)
			k:wall("hallR", 4, 26, 18, 26, FRONT_ROOM, BEDROOM)
			k:wall("hallB", 18, 26, 24, 26, FRONT_ROOM, BATH)
			k:wall("hallK", 24, 26, 34, 26, FRONT_ROOM, KITCHEN)
			k:wall("bathL", 18, 26, 18, 38, BATH, BEDROOM)
			k:wall("bathR", 24, 26, 24, 38, KITCHEN, BATH)

			-- one roof over the house and the porch, the ridge along the house
			b:roof(4, 8, 34, 38, "gable", 9.5, 0, ROOF, GABLE, 0, 1)

			-- doors and windows ------------------------------------------------------------------
			k:open("door_front", "front", 19, SAGE, WHITE)
			k:open("win_square", "front", 9)
			k:open("win_square", "front", 29)
			k:open("win_square", "rightD", 20)
			k:open("win_square", "backK", 28.45)
			k:open("win_small", "backB", 21)
			k:open("win_square", "leftB", 33.6)
			k:open("win_small", "leftL", 16)
			k:open("door_wood", "hallR", 15.4, WALNUT, WHITE)
			k:open("door_wood", "hallB", 21, WALNUT, WHITE)
			k:open("arch_wide", "hallK", 29)

			-- the outside --------------------------------------------------------------------------
			k:dress("front", { shutters = { SAGE, SAGE_DARK }, hood = { WHITE, ROOF.c }, box = { WHITE, ROSE } })
			k:dress("rightD", { shutters = { SAGE, SAGE_DARK }, hood = { WHITE, ROOF.c }, box = { WHITE, BUTTER } })
			k:dress("leftB", { shutters = { SAGE, SAGE_DARK }, hood = { WHITE, ROOF.c }, box = { WHITE, LILAC } })
			k:dress("backK", { hood = { WHITE, ROOF.c }, box = { WHITE, ROSE } })
			for _, w in { "rightD", "rightK", "backK", "backB", "backR", "leftB", "leftL" } do
				k:footing(w, STONE, PALE_STONE)
			end
			k:corner(4, 14, 180)
			k:corner(34, 14, 90)
			k:corner(34, 38, 0)
			k:corner(4, 38, 270)
			k:hang("downpipe", "backK", 33.3, 0)
			k:hang("downpipe", "backR", 4.7, 0)
			k:put("water_butt", 33.2, 39.8, 0, SAGE, WALNUT)
			k:hang("trellis", "leftL", 20.5, 1.3)
			k:hang("trellis", "rightK", 32, 1.3)
			k:hang("hanging_basket", "rightK", 28.4, 5.4, "a", WALNUT, ROSE)
			k:hang("hanging_basket", "leftB", 29.2, 5.4, "a", WALNUT, BUTTER)
			-- a window up in each gable (the left one clear of the chimney's stack)
			k:up("window_attic", 34, 23, 90, 1, WHITE, SAGE)
			k:up("window_attic", 4, 28, 270, 1, WHITE, SAGE)

			-- the porch: posts under the eave with rails between them, steps up from the path,
			-- lanterns either side of the door, lights strung over it
			for _, x in { 5.4, 10.6, 16.4, 21.6, 27.4, 32.6 } do
				k:put("porch_post", x, 8.6, 0, WHITE, WHITE)
			end
			for _, x in { 8, 13.5, 24.5, 30 } do
				k:put("porch_rail", x, 8.6, 0, WHITE, WHITE)
			end
			k:put("porch_rail", 4.5, 11.4, 90, WHITE, WHITE)
			k:put("porch_rail", 33.5, 11.4, 90, WHITE, WHITE)
			k:putY("doorstep", 19, 6.8, 180, 0, PALE_STONE, STONE)
			k:put("doormat", 19, 12.9, 0)
			k:hang("lantern_wall", "front", 15.9, 5.6)
			k:hang("lantern_wall", "front", 22.1, 5.6)
			k:hang("string_lights", "front", 19, 9.8)
			k:put("chair_rocking", 7.8, 11.6, 180, OAK_PAINT, ROSE)
			k:put("chair_rocking", 28.6, 11.4, 165, OAK_PAINT, SAGE)
			k:put("bench_wood", 12.8, 12.75, 0, WALNUT)
			k:put("flower_pot", 16.0, 13.0, 0, nil, ROSE)
			k:put("flower_pot", 22.4, 13.1, 0, nil, BUTTER)
			k:putY("woodpile", 32.0, 12.9, 0, F)

			-- the front garden
			k:fenceX(0.6, 1, 37, { 19 }, WHITE, WHITE)
			k:fenceZ(1, 0.8, 8.8, nil, WHITE, WHITE)
			k:fenceZ(37, 0.8, 8.8, nil, WHITE, WHITE)
			for _, x in { 5, 9, 13 } do
				k:put("flower_border", x, 2.1, 0, WHITE, if x == 9 then LILAC else ROSE)
			end
			for _, x in { 25, 29, 33 } do
				k:put("flower_border", x, 2.1, 0, WHITE, if x == 29 then ROSE else BUTTER)
			end
			k:put("path_stones", 19, 2.0, 0)
			k:put("path_stones", 19.2, 4.1, 15)
			k:put("mailbox", 21.8, 2.6, 0, SAGE, WALNUT)
			k:put("lamp_post", 16.1, 2.6, 0)
			k:put("flower_bed", 12, 6.4, 0, nil, ROSE)
			k:put("flower_bed", 26, 6.4, 0, nil, LILAC)
			k:put("bush", 2.4, 10.4, 0)
			k:put("bush", 35.6, 10.4, 0)
			k:put("bird_house", 35.2, 4.6, 20, WHITE, SAGE)

			-- the side path down the right, round to the back garden
			for i, z in { 12, 16.4, 20.8, 25.2, 29.6, 34 } do
				k:put("path_stones", 36 + (if i % 2 == 0 then 0.3 else -0.2), z, i * 17 % 40)
			end
			k:put("flower_border", 2, 19.2, 90, STONE, BUTTER)
			k:put("flower_border", 2, 23.6, 90, STONE, ROSE)

			-- the back garden
			k:put("veg_patch", 8, 42.2, 0)
			k:put("veg_patch", 12.6, 42.2, 0)
			k:put("bird_house", 16.6, 41.6, 0, WHITE, SAGE)
			k:put("bench_garden", 22.5, 44.6, 180, OAK_PAINT, SAGE)
			k:put("tree_blossom", 30.8, 42.2, 0)
			k:put("path_stones", 36.1, 38.6, 30)
			k:put("path_stones", 26.2, 41.6, 10)

			-- the front room -----------------------------------------------------------------------
			-- the fire on the end wall, the sofa facing it across a round rug, an armchair turned
			-- to it from the corner by the books, the dining table in the window on the right
			k:put("chimney_hearth", 5.9, 20, 90, CHIMNEY, PALE_STONE)
			k:put("rug_round", 11.5, 19.6, 0, "C98F7A", BUTTER)
			k:put("table_coffee", 11.5, 19.6, 90, WALNUT)
			k:on("books_stack", "table_coffee", 11.3, 18.9, 20)
			k:on("candles", "table_coffee", 11.7, 20.6, 0)
			k:put("sofa_three", 16.0, 20, 270, SAGE, WHITE)
			k:put("armchair", 11.0, 23.3, 225, ROSE)
			k:put("lamp_floor", 7.6, 23.05, 0)
			k:put("bookshelf", 7.0, 24.85, 180, WALNUT)
			k:put("clock_grandfather", 14.0, 15.05, 0, WALNUT)
			k:put("coat_stand", 22.4, 15.3, 0, WALNUT)
			k:put("table_round", 28.4, 19.6, 0, OAK_PAINT)
			k:on("vase_flowers", "table_round", 28.4, 19.6, 0, WHITE, ROSE)
			k:put("chair_dining", 28.4, 17.3, 0, OAK_PAINT, SAGE)
			k:put("chair_dining", 28.4, 21.9, 180, OAK_PAINT, SAGE)
			k:put("chair_dining", 26.1, 19.6, 90, OAK_PAINT, SAGE)
			k:put("chair_dining", 30.7, 19.6, 270, OAK_PAINT, SAGE)
			k:put("cabinet", 32.75, 23.4, 270, WALNUT)
			k:on("candles", "cabinet", 32.7, 22.4, 0)
			k:on("plant_small", "cabinet", 32.7, 24.4, 0)
			k:put("plant_big", 32.0, 15.95, 0)
			k:put("lamp_pendant", 28.4, 19.6, 0)
			k:put("light_ceiling", 11.5, 19.6, 0)
			k:hang("art_landscape", "hallR", 7, 7.8, "a")
			k:hang("art_flowers", "rightD", 15.6, 5.8, "b")
			k:hang("curtains", "front", 9, 2.2, "b", "E6CFC4", WALNUT)
			k:hang("curtains", "front", 29, 2.2, "b", "E6CFC4", WALNUT)

			-- the bedroom --------------------------------------------------------------------------
			k:put("bed_double", 11, 33.85, 180, WALNUT, "E6CFC4")
			k:put("nightstand", 6.9, 36.75, 180, WALNUT)
			k:on("lamp_table", "nightstand", 6.9, 36.75, 180)
			k:put("nightstand", 15.1, 36.75, 180, WALNUT)
			k:on("lamp_table", "nightstand", 15.1, 36.75, 180)
			k:put("wardrobe", 5.45, 28.6, 90, WALNUT)
			k:put("dresser", 10.6, 27.25, 0, WALNUT)
			k:on("plant_small", "dresser", 9.4, 27.2, 0)
			k:hang("mirror_wall", "hallR", 10.6, 4.8, "b")
			k:hang("art_flowers", "backR", 11, 6.8, "b")
			k:hang("curtains", "leftB", 33.6, 2.2, "b", "CFE0D8", WALNUT)
			k:put("light_ceiling", 11, 31, 0)

			-- the bathroom
			k:put("bathtub", 21.95, 34.55, 0)
			k:put("toilet", 19.3, 36.25, 180)
			k:put("sink_vanity", 19.35, 29.5, 90)
			k:hang("mirror_wall", "bathL", 29.5, 4.8, "a")
			k:put("towel_rail", 23.15, 29.5, 270, nil, SAGE)
			k:put("light_ceiling", 21, 31.5, 0)

			-- the kitchen: the counters along the back under the window, the fridge and the
			-- pantry either side, a little table for breakfast
			k:put("counter_corner", 25.65, 36.35, 180)
			k:put("counter_sink", 28.45, 36.35, 180)
			k:put("stove", 31.45, 36.35, 180)
			k:on("kettle", "stove", 31.0, 36.3, 160, SAGE)
			k:on("toaster", "counter_corner", 25.6, 36.5, 180)
			k:put("fridge", 32.35, 31.5, 270)
			k:put("pantry", 25.45, 29.6, 90, WHITE, SAGE)
			k:put("table_dining_small", 28.4, 31.4, 0, OAK_PAINT)
			k:put("chair_wood", 28.4, 29.1, 0, OAK_PAINT, SAGE)
			k:put("chair_wood", 28.4, 33.7, 180, OAK_PAINT, SAGE)
			k:hang("shelf_wall", "backK", 32.2, 7.2, "b", WALNUT)
			k:put("lamp_pendant", 28.4, 31.4, 0)
		end,
		"cozy"
	)
end
