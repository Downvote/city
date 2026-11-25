--!strict
-- The barn house (rustic): a tall barn in soft red boards with white corners, its steep gable to
-- the yard and a pair of big doors under the hayloft window. Inside, the front half is open to the
-- rafters: a long table with benches, the sofa drawn up to a fire on the side wall. A stair climbs
-- the left wall to a loft over the back half where the bed is; under the loft are the kitchen and
-- the bathroom. A sliding door on the side opens onto a fenced vegetable garden, and there is a
-- swing on the tree out the back.
--
-- The frame: x across, z back from the street (z = 0). The barn is x 6..32 and z 10..38, the loft
-- x 6..32 and z 24..38 a floor up, the garden x 34..46 and z 12..36.

local HomeKit = require(script.Parent.Parent.HomeKit)

type Finish = HomeKit.Finish

local F = HomeKit.F

-- finishes
local BOARDS: Finish = { c = "B86A5E", m = "WoodPlanks" } -- soft barn red
local INSIDE: Finish = { c = "D8BC98", m = "WoodPlanks" } -- pale boards inside
local BATH: Finish = { c = "EEE6D8", m = "WoodPlanks" }
local ROOF: Finish = { c = "6E6A66", m = "RoofShingles" } -- weathered grey
local GABLE: Finish = { c = "B86A5E", m = "WoodPlanks" }
local FLOOR: Finish = { c = "A88462", m = "WoodPlanks" }
local LOFT: Finish = { c = "C49A6C", m = "WoodPlanks" }
local BATH_TILES: Finish = { c = "D8D2C6", m = "Slate" }
local YARD: Finish = { c = "C9BCA6", m = "Pebble" }
local FENCE: Finish = { c = "F2EDE2", m = "Wood" }
local RAIL: Finish = { c = "8E6A4E", m = "Wood" }
-- paint for the pieces
local WHITE = "F2EDE2"
local RED = "B86A5E"
local WALNUT = "7E5A40"
local OAK = "C49A6C"
local MUSTARD = "D9A93F"
local SAGE = "86A886"
local DENIM = "6F86A6"
local STONE = "A8A29A"
local PALE_STONE = "C9C3B8"

return function(add: any)
	add(
		"home_barn",
		"Barn house",
		"A tall red barn with big doors, a loft bedroom under the roof and a vegetable garden.",
		"house",
		48,
		48,
		function(b: any)
			local k = HomeKit.new(b)

			-- the floors -------------------------------------------------------------------------
			b:floor(6, 10, 32, 26, FLOOR) -- the open front half
			b:floor(6, 26, 22, 38, FLOOR) -- the kitchen
			b:floor(22, 26, 32, 38, BATH_TILES)
			b:floor(6, 24, 32, 38, LOFT, 1) -- the loft
			b:floor(14, 2, 24, 10, YARD) -- in front of the big doors

			-- the walls ----------------------------------------------------------------------------
			k:wall("front", 6, 10, 32, 10, BOARDS, INSIDE)
			k:wall("right", 32, 10, 32, 38, BOARDS, INSIDE)
			k:wall("back", 32, 38, 6, 38, BOARDS, INSIDE)
			k:wall("left", 6, 38, 6, 10, BOARDS, INSIDE)
			k:wall("bathF", 22, 26, 32, 26, INSIDE, BATH)
			k:wall("bathL", 22, 26, 22, 38, INSIDE, BATH)
			-- the loft's rail, and its end beside the stair
			k:wall("rail", 12, 24, 32, 24, RAIL, RAIL, 1, "railing")
			k:wall("railend", 12, 24, 12, 26, RAIL, RAIL, 1, "railing")
			-- the garden's fence, open at the front corner by the barn
			k:wall("fenceF", 36, 12, 46, 12, FENCE, FENCE, 0, "fence")
			k:wall("fenceR", 46, 12, 46, 36, FENCE, FENCE, 0, "fence")
			k:wall("fenceB", 46, 36, 34, 36, FENCE, FENCE, 0, "fence")

			-- the steep roof, its gable to the yard
			b:roof(6, 10, 32, 38, "gable", 13, 1, ROOF, GABLE, 0, 0.8)

			-- doors and windows ------------------------------------------------------------------
			k:open("door_barn_big", "front", 19, RED, WHITE)
			k:open("win_square", "front", 10.4, WHITE, WHITE)
			k:open("win_square", "front", 27.6, WHITE, WHITE)
			k:open("door_barn", "right", 21.5, RED, WHITE)
			k:open("win_square", "right", 30, WHITE, WHITE)
			k:open("win_square", "left", 30, WHITE, WHITE)
			k:open("win_tall", "left", 17, WHITE, WHITE)
			k:open("win_square", "back", 13.45, WHITE, WHITE)
			k:open("door_wood", "bathF", 24.8, WHITE, RED)

			-- the outside --------------------------------------------------------------------------
			for _, w in { "front", "right", "back", "left" } do
				k:footing(w, STONE, PALE_STONE)
			end
			k:corner(6, 10, 180, 0, WHITE, WHITE)
			k:corner(32, 10, 90, 0, WHITE, WHITE)
			k:corner(32, 38, 0, 0, WHITE, WHITE)
			k:corner(6, 38, 270, 0, WHITE, WHITE)
			k:dress("front", { box = { WHITE, MUSTARD }, hood = { WHITE, ROOF.c } })
			k:dress("left", { shutters = { WHITE, PALE_STONE }, box = { WHITE, "D9707F" } })
			k:dress("right", { shutters = { WHITE, PALE_STONE }, box = { WHITE, MUSTARD } })
			k:dress("back", { hood = { WHITE, ROOF.c } })
			-- the hayloft window over the big doors, and one in the back gable
			k:up("window_attic", 19, 10, 180, 1, WHITE, RED)
			k:up("window_attic", 19, 38, 0, 1, WHITE, RED)
			k:hang("lantern_wall", "front", 14.0, 6.0)
			k:hang("lantern_wall", "front", 24.0, 6.0)
			k:hang("lantern_wall", "right", 16.6, 6.0)
			k:hang("downpipe", "back", 31.3, 0, "a", ROOF.c, ROOF.c)
			k:put("water_butt", 31.0, 39.8, 0, SAGE, WALNUT)
			-- the yard in front: crates, a bench by the doors, a cart wheel's worth of flowers
			k:putY("crate", 25.6, 4.4, 15, 0, OAK, OAK)
			k:putY("crate", 25.7, 4.3, 40, 2, OAK, OAK)
			k:putY("bench_wood", 11.0, 8.4, 0, 0, WALNUT)
			k:put("flower_border", 30.0, 7.6, 0, WALNUT, MUSTARD)
			k:put("flower_border", 8.0, 4.0, 0, WALNUT, "D9707F")
			k:put("planter_box", 13.0, 1.4, 0, WALNUT, MUSTARD)
			k:put("mailbox", 26.4, 1.4, 0, RED, WHITE)
			k:put("lamp_post", 12.0, 4.6, 0)
			-- the vegetable garden through the side door, a woodpile and a sawhorse by the wall
			for _, p in { { 38.6, 16.4 }, { 43.4, 16.4 }, { 38.6, 22.4 }, { 43.4, 22.4 }, { 38.6, 28.4 }, { 43.4, 28.4 } } do
				k:put("veg_patch", p[1], p[2], 0)
			end
			k:put("water_butt", 44.6, 33.8, 0, SAGE, WALNUT)
			k:putY("sawhorse", 41.0, 33.4, 90, 0, OAK, WALNUT)
			k:put("woodpile", 33.45, 30.0, 90)
			k:put("woodpile", 33.45, 13.6, 90)
			for _, z in { 18, 22 } do
				k:put("path_stones", 34.6, z, z * 11 % 40)
			end
			-- behind: the tree with a swing, a bench, a picnic table
			k:put("tree_swing", 14, 43, 0)
			k:put("picnic_table", 30.4, 43.2, 0, OAK, WALNUT)
			k:put("bird_house", 3.0, 30.0, 0, WHITE, RED)
			k:put("bush", 3.0, 14.0, 0)
			k:put("bush", 40.0, 41.0, 0)

			-- downstairs: the open front half -------------------------------------------------------
			-- the stair up the left wall, the long table with benches, the sofa facing the fire on
			-- the right wall
			k:putY("stairs_open", 8.35, 19, 180, F, WALNUT, "4A4A50")
			k:put("table_dining_long", 15.5, 19, 0, OAK)
			k:on("lantern", "table_dining_long", 14.0, 19.0, 0)
			k:on("vase_flowers", "table_dining_long", 17.0, 19.1, 0, WHITE, MUSTARD)
			k:put("bench_wood", 15.5, 15.6, 0, WALNUT)
			k:put("bench_wood", 15.5, 22.4, 180, WALNUT)
			k:put("fireplace", 30.45, 14, 270, "A8A29A", WHITE)
			k:put("sofa_three", 23.5, 14.1, 90, DENIM, MUSTARD)
			k:put("rug_round", 27, 14.1, 0, "B8505A", MUSTARD)
			k:put("table_coffee", 27, 14.1, 90, WALNUT)
			k:on("books_stack", "table_coffee", 26.9, 13.3, 15)
			k:put("armchair", 27, 19.0, 180, MUSTARD)
			k:put("lamp_floor", 23.6, 20.6, 0)
			k:put("coat_stand", 12.6, 11.6, 0, WALNUT, RED)
			k:hang("sconce", "left", 22.6, 6.6, "b")
			k:hang("art_landscape", "right", 14, 8.0, "b")
			k:hang("clock_wall", "front", 10.4, 8.6, "b", RED)

			-- under the loft: the kitchen, and the bathroom behind its wall
			k:put("counter_corner", 7.65, 36.35, 180, WHITE, WALNUT)
			k:put("stove", 10.45, 36.35, 180, WHITE, WALNUT)
			k:put("counter_sink", 13.45, 36.35, 180, OAK, WALNUT)
			k:put("counter", 16.45, 36.35, 180, OAK, WALNUT)
			k:put("fridge", 19.95, 36.35, 180, WHITE)
			k:on("kettle", "stove", 10.1, 36.3, 160, RED)
			k:on("toaster", "counter", 16.5, 36.5, 180, WHITE)
			k:put("pantry", 7.45, 29.5, 90, OAK, WALNUT)
			k:put("kitchen_island", 14, 30.6, 0, OAK, WALNUT)
			k:on("plant_small", "kitchen_island", 12.6, 30.6, 0)
			k:put("stool_bar", 12.5, 27.9, 0, WALNUT, RED)
			k:put("stool_bar", 15.5, 27.9, 0, WALNUT, RED)
			k:put("light_ceiling", 14, 30.6, 0)
			k:hang("shelf_wall", "back", 18.2, 7.4, "b", WALNUT)

			k:put("bathtub", 29.9, 34.55, 180)
			k:put("toilet", 23.4, 36.25, 180)
			k:put("sink_vanity", 26.0, 36.65, 180, OAK)
			k:hang("mirror_wall", "back", 26.0, 5.0, "b")
			k:put("washing_machine", 23.65, 30, 90)
			k:put("towel_rail", 31.15, 28.5, 270, nil, SAGE)
			k:put("light_ceiling", 27, 31, 0)

			-- the loft: the bed under the back gable, a chair at the rail looking down
			k:up("bed_double", 19, 33.85, 180, 1, WALNUT, DENIM)
			k:up("nightstand", 14.9, 36.75, 180, 1, WALNUT)
			b:item("lamp_table", 14.9, 36.75, 180, 1, HomeKit.top("nightstand", 1))
			k:up("nightstand", 23.1, 36.75, 180, 1, WALNUT)
			b:item("lamp_table", 23.1, 36.75, 180, 1, HomeKit.top("nightstand", 1))
			k:up("rug_round", 19, 28.2, 0, 1, "C9A9A0", MUSTARD)
			k:up("armchair", 25.6, 27.6, 225, 1, SAGE)
			k:up("dresser", 12.5, 31, 90, 1, WALNUT)
			b:item("plant_small", 12.5, 30.0, 0, 1, HomeKit.top("dresser", 1))
			k:up("toy_chest", 19, 30.9, 180, 1, RED)
			k:up("lamp_pendant", 19, 28.2, 0, 1, WALNUT)
		end,
		"rustic"
	)
end
