--!strict
-- The greenhouse cottage (garden): a one room brick cottage with its gable to the lane and a long
-- glasshouse built on to its side, the glass roof running out of the cottage's own. Inside the
-- cottage a bed against the back wall, a little kitchen along one wall and a table for two, the
-- bathroom in the corner; in the glasshouse benches of pots along the glass, a potting table down
-- the middle and a bed of vegetables at the far end. In front, a kitchen garden of vegetable beds
-- behind a picket fence; behind, a pond, fruit trees and a bench.
--
-- The frame: x across, z back from the street (z = 0). The cottage is x 4..18 and z 12..30, the
-- glasshouse x 18..40 and z 14..28, the kitchen garden in front of the glasshouse.

local HomeKit = require(script.Parent.Parent.HomeKit)

type Finish = HomeKit.Finish

-- finishes
local BRICK: Finish = { c = "D8A48E", m = "Brick" } -- soft brick
local INSIDE: Finish = { c = "F4ECDC", m = "WoodPlanks" }
local BATH: Finish = { c = "E4EDE6", m = "CeramicTiles" }
local TILE_ROOF: Finish = { c = "B98A72", m = "ClayRoofTiles" }
local GABLE: Finish = { c = "E8D8C0", m = "WoodPlanks" }
local FRAMES: Finish = { c = "FAF6EC", m = "WoodPlanks" } -- the glasshouse's white frames
local PANES: Finish = { c = "9CCBBE", m = "Glass" } -- its roof: sea green glass, see-through (Shapes.GlassRoof)
local FLOOR: Finish = { c = "B48C64", m = "WoodPlanks" }
local BATH_TILES: Finish = { c = "D8E2DA", m = "CeramicTiles" }
local RED_BRICK: Finish = { c = "D69A82", m = "Brick" } -- the glasshouse floor
local GRAVEL: Finish = { c = "D9D2C2", m = "Pebble" } -- the paths
-- paint for the pieces
local FOREST = "4E7F62" -- the door and the shutters
local FOREST_DARK = "3E6650"
local WHITE = "FAF6EC"
local OAK = "C49A6C"
local WALNUT = "9A6B48"
local PINK = "E8879A"
local CORAL = "E08566"
local LILAC = "9C86B8"
local BUTTER = "E9C46A"
local STONE = "BDB8AE"
local PALE_STONE = "DAD4C8"

return function(add: any)
	add(
		"home_greenhouse",
		"Greenhouse cottage",
		"A brick cottage with a glasshouse on the side and vegetable beds out front.",
		"plant",
		46,
		44,
		function(b: any)
			local k = HomeKit.new(b)

			-- the floors -------------------------------------------------------------------------
			b:floor(4, 12, 18, 22, FLOOR)
			b:floor(12, 22, 18, 30, FLOOR)
			b:floor(4, 22, 12, 30, BATH_TILES)
			b:floor(18, 14, 40, 28, RED_BRICK)
			b:floor(10, 0, 14, 10, GRAVEL) -- the path to the cottage door
			b:floor(26, 4, 30, 12, GRAVEL) -- and the one between the beds to the glasshouse

			-- the walls ----------------------------------------------------------------------------
			k:wall("front", 4, 12, 18, 12, BRICK, INSIDE)
			k:wall("side", 18, 12, 18, 30, BRICK, INSIDE) -- side a is the glasshouse's
			k:wall("back", 18, 30, 4, 30, BRICK, INSIDE)
			k:wall("leftB", 4, 30, 4, 22, BRICK, BATH)
			k:wall("left", 4, 22, 4, 12, BRICK, INSIDE)
			k:wall("bathF", 4, 22, 12, 22, INSIDE, BATH)
			k:wall("bathR", 12, 22, 12, 30, INSIDE, BATH)
			-- the glasshouse: glass all round but for a piece of white wall that takes the door
			k:wall("gfront1", 18, 14, 24, 14, FRAMES, FRAMES, 0, "glass")
			k:wall("gdoor", 24, 14, 30, 14, FRAMES, FRAMES)
			k:wall("gfront2", 30, 14, 40, 14, FRAMES, FRAMES, 0, "glass")
			k:wall("gright", 40, 14, 40, 28, FRAMES, FRAMES, 0, "glass")
			k:wall("gback", 40, 28, 18, 28, FRAMES, FRAMES, 0, "glass")

			-- the cottage's steep roof, and the glasshouse's, which runs out of its slope
			b:roof(4, 12, 18, 30, "gable", 7, 1, TILE_ROOF, GABLE, 0, 0.8)
			b:roof(12, 14, 40, 28, "gable", 4, 0, PANES, PANES, 0, 0.4)

			-- doors and windows ------------------------------------------------------------------
			k:open("door_front", "front", 13.4, FOREST, WHITE)
			k:open("win_square", "front", 7.2)
			k:open("win_square", "left", 17)
			k:open("win_small", "leftB", 28.3)
			k:open("door_wood", "side", 19.4, FOREST, WHITE)
			k:open("door_glass", "gdoor", 27, FOREST, FOREST)
			k:open("door_wood", "bathF", 9.6, WHITE, FOREST)

			-- the outside --------------------------------------------------------------------------
			k:dress(
				"front",
				{ shutters = { FOREST, FOREST_DARK }, hood = { WHITE, TILE_ROOF.c }, box = { WHITE, PINK } }
			)
			k:dress(
				"left",
				{ shutters = { FOREST, FOREST_DARK }, hood = { WHITE, TILE_ROOF.c }, box = { WHITE, BUTTER } }
			)
			for _, w in { "front", "left", "leftB", "back" } do
				k:footing(w, STONE, PALE_STONE)
			end
			k:footing("side", STONE, PALE_STONE, 16.2, 18)
			k:corner(4, 12, 180)
			k:corner(18, 12, 90)
			k:corner(18, 30, 0)
			k:corner(4, 30, 270)
			k:up("window_attic", 11, 12, 180, 1, WHITE, FOREST)
			k:hang("lantern_wall", "front", 16.2, 5.6)
			k:hang("hanging_basket", "front", 10.2, 5.4, "a", WALNUT, CORAL)
			k:hang("downpipe", "back", 17.3, 0)
			k:put("water_butt", 17.0, 31.8, 0, FOREST, WALNUT)
			k:hang("trellis", "leftB", 24.2, 1.3)
			k:putY("doorstep", 13.4, 10.8, 180, 0, PALE_STONE, STONE)
			k:put("path_stones", 28, 13.0, 0)
			-- in the glasshouse, on the cottage's wall: lights strung along it, baskets either side
			-- of the door
			k:hang("string_lights", "side", 21, 9.6, "a")
			k:hang("hanging_basket", "side", 15.6, 6.0, "a", WALNUT, PINK)
			k:hang("hanging_basket", "side", 23.2, 6.0, "a", WALNUT, LILAC)

			-- the kitchen garden: a picket fence round it with a gate at each path, beds in rows
			k:fenceX(0.6, 2, 42, { 12, 28 }, WHITE, WHITE)
			k:fenceZ(42.2, 0.8, 12.8, nil, WHITE, WHITE)
			for _, p in { { 21.4, 6.4 }, { 21.4, 10.6 }, { 34.6, 6.4 }, { 34.6, 10.6 }, { 39.2, 6.4 }, { 39.2, 10.6 } } do
				k:put("veg_patch", p[1], p[2], 0)
			end
			k:put("flower_border", 6.6, 2.0, 0, WHITE, PINK)
			k:put("flower_border", 18.0, 2.0, 0, WHITE, BUTTER)
			k:put("flower_border", 33.0, 2.0, 0, WHITE, CORAL)
			k:put("bird_house", 2.0, 8.0, 0, WHITE, FOREST)
			k:put("mailbox", 15.6, 2.4, 0, FOREST, WALNUT)
			k:put("lamp_post", 8.4, 9.8, 0)
			k:put("water_butt", 43.6, 31.2, 0, FOREST, WALNUT)
			k:put("bench_garden", 6.0, 6.0, 90, OAK, FOREST)

			-- the back garden: the pond, fruit trees, a bench and a woodpile by the cottage
			k:put("pond", 28.0, 36.6, 0)
			k:put("rock", 32.6, 34.0, 40)
			k:put("rock", 24.0, 39.6, 160)
			k:put("tree_blossom", 8.6, 37.6, 0)
			k:put("tree_oak", 40.6, 37.6, 0)
			k:put("bench_garden", 19.0, 41.8, 180, OAK, FOREST)
			k:put("flower_bed", 28.0, 42.0, 0, nil, PINK)
			k:put("woodpile", 2.4, 18.0, 90)
			for i, z in { 14, 18.6, 23.2, 27.8 } do
				k:put("path_stones", 42.0 + (if i % 2 == 0 then 0.4 else 0), z, i * 23 % 40)
			end

			-- the cottage ------------------------------------------------------------------------
			-- the kitchen along the left wall, a table for two, a rocking chair by the books, the bed
			-- against the back wall
			k:put("counter_sink", 5.6, 14.0, 90, WHITE, OAK)
			k:put("stove", 5.6, 17.0, 90, WHITE, OAK)
			k:put("counter", 5.6, 20.0, 90, WHITE, OAK)
			k:on("kettle", "stove", 5.7, 16.6, 120, FOREST)
			k:on("plant_small", "counter", 5.6, 20.6, 0)
			k:on("vase_flowers", "counter", 5.5, 19.4, 0, WHITE, PINK)
			k:put("table_round", 11.0, 17.6, 0, OAK)
			k:on("vase_flowers", "table_round", 11.0, 17.6, 0, WHITE, BUTTER)
			k:put("chair_wood", 8.7, 17.6, 90, OAK, FOREST)
			k:put("chair_wood", 13.3, 17.6, 270, OAK, FOREST)
			k:put("bookshelf", 16.9, 14.2, 270, WALNUT)
			k:put("rug_round", 11.0, 17.6, 0, "CFE0C8", WHITE)
			k:put("chair_rocking", 15.6, 18.4, 250, OAK, PINK)
			k:put("bed_single", 15.0, 26.05, 180, WALNUT, "CFE0C8")
			k:put("lamp_pendant", 11.0, 17.6, 0)
			k:put("light_ceiling", 15.0, 24.6, 0)
			k:hang("coat_hooks", "front", 16.4, 5.4, "b", WALNUT)
			k:hang("art_flowers", "side", 26.4, 6.0, "b")

			-- the bathroom
			k:put("shower", 9.8, 27.8, 0)
			k:put("toilet", 5.25, 28.25, 180)
			k:put("sink_vanity", 5.35, 24.6, 90, WHITE)
			k:hang("mirror_wall", "leftB", 24.4, 4.8, "b")
			k:put("light_ceiling", 8, 26, 0)

			-- the glasshouse ----------------------------------------------------------------------
			-- benches of pots along the glass, the potting table down the middle, vegetables at the
			-- far end, a chair to sit in among it all
			k:put("plant_bench", 21.0, 15.45, 0, OAK, PINK)
			k:put("plant_bench", 35.0, 15.45, 0, OAK, BUTTER)
			k:put("plant_bench", 21.2, 26.55, 180, OAK, CORAL)
			k:put("plant_bench", 27.4, 26.55, 180, OAK, LILAC)
			k:put("plant_bench", 33.6, 26.55, 180, OAK, PINK)
			k:put("veg_patch", 37.6, 21.4, 0)
			k:put("table_dining_long", 27.6, 21.0, 0, OAK, WALNUT)
			k:on("flower_pot", "table_dining_long", 25.0, 21.2, 0, nil, PINK)
			k:on("flower_pot", "table_dining_long", 26.6, 20.6, 0, nil, BUTTER)
			k:on("plant_small", "table_dining_long", 28.4, 21.3, 0)
			k:on("flower_pot", "table_dining_long", 30.0, 20.8, 0, nil, LILAC)
			k:put("chair_wood", 22.0, 21.0, 90, WHITE, FOREST)
			k:put("water_butt", 38.6, 17.9, 0, FOREST, WALNUT)
			k:put("lamp_pendant", 24.6, 21.0, 0, WHITE)
			k:put("lamp_pendant", 31.0, 21.0, 0, WHITE)
		end,
		"garden"
	)
end
