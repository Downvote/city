--!strict
-- The fisher's cottage (seaside): a long, low whitewashed cottage under a blue grey slate roof,
-- blue shutters and flowers at the windows, and beside it a boat shed of weathered boards with a
-- wide open front and a little deck in front of it like a slipway. Inside the cottage a bedroom at
-- one end, a fire with two chairs drawn up to it at the other, the kitchen and a table between
-- them and the bathroom in the back corner. The shed holds the workbench, timber and crates.
--
-- The frame: x across, z back from the street (z = 0). The cottage is x 4..30 and z 10..28, the
-- shed x 32..44 and z 12..26 with its deck in front from z 1.

local HomeKit = require(script.Parent.Parent.HomeKit)

type Finish = HomeKit.Finish

local F = HomeKit.F

-- finishes
local WHITEWASH: Finish = { c = "F2F2EC", m = "WoodPlanks" }
local INSIDE: Finish = { c = "F6F2E8", m = "WoodPlanks" }
local BEDROOM: Finish = { c = "E2EAF0", m = "WoodPlanks" }
local BATH: Finish = { c = "E4EEEE", m = "CeramicTiles" }
local ROOF: Finish = { c = "5E6E7E", m = "Slate" }
local GABLE: Finish = { c = "F2F2EC", m = "WoodPlanks" }
local SHED: Finish = { c = "B8B0A2", m = "WoodPlanks" } -- weathered boards
local SHED_ROOF: Finish = { c = "6E7A84", m = "RoofShingles" }
local FLOOR: Finish = { c = "B8956E", m = "WoodPlanks" }
local FLAGS: Finish = { c = "C2BDB2", m = "Slate" }
local BATH_TILES: Finish = { c = "D2E2E2", m = "CeramicTiles" }
local SHED_FLOOR: Finish = { c = "9C8C78", m = "WoodPlanks" }
-- paint for the pieces
local BLUE = "3E6E9A" -- the door and the shutters
local BLUE_DARK = "2E5474"
local WHITE = "FAF6EC"
local CORAL = "E08566"
local SUN = "E9C46A"
local DRIFT = "B8A88E"
local WALNUT = "7E5A40"
local STONE = "A8A6A0"
local PALE_STONE = "CFCCC4"

return function(add: any)
	add(
		"home_fisher_cottage",
		"Fisher's cottage",
		"A low white cottage by the water, with a boat shed and a little deck beside it.",
		"sun",
		46,
		36,
		function(b: any)
			local k = HomeKit.new(b)

			-- the floors -------------------------------------------------------------------------
			b:floor(4, 10, 14, 28, FLOOR) -- the bedroom
			b:floor(14, 10, 30, 20, FLAGS) -- the kitchen end and the fire
			b:floor(14, 20, 22, 28, FLAGS)
			b:floor(22, 20, 30, 28, BATH_TILES)
			b:floor(32, 12, 44, 26, SHED_FLOOR)

			-- the walls ----------------------------------------------------------------------------
			k:wall("front", 4, 10, 30, 10, WHITEWASH, INSIDE)
			k:wall("right", 30, 10, 30, 28, WHITEWASH, INSIDE)
			k:wall("back", 30, 28, 4, 28, WHITEWASH, INSIDE)
			k:wall("left", 4, 28, 4, 10, WHITEWASH, BEDROOM)
			k:wall("bedwall", 14, 10, 14, 28, INSIDE, BEDROOM)
			k:wall("bathF", 22, 20, 30, 20, INSIDE, BATH)
			k:wall("bathL", 22, 20, 22, 28, BATH, INSIDE)
			-- the shed
			k:wall("shedF", 32, 12, 44, 12, SHED, SHED)
			k:wall("shedR", 44, 12, 44, 26, SHED, SHED)
			k:wall("shedB", 44, 26, 32, 26, SHED, SHED)
			k:wall("shedL", 32, 26, 32, 12, SHED, SHED)

			b:roof(4, 10, 30, 28, "gable", 7, 0, ROOF, GABLE, 0, 0.8)
			b:roof(32, 12, 44, 26, "gable", 6, 1, SHED_ROOF, SHED, 0, 0.6)

			-- doors and windows ------------------------------------------------------------------
			k:open("door_front", "front", 18, BLUE, WHITE)
			k:open("win_square", "front", 9)
			k:open("win_square", "front", 24.6)
			k:open("win_square", "left", 18)
			k:open("win_small", "back", 26)
			k:open("door_wood", "bedwall", 13.5, BLUE, WHITE)
			k:open("door_wood", "bathF", 24.6, WHITE, BLUE)
			k:open("arch_wide", "shedF", 38)
			k:open("win_small", "shedR", 19)
			k:open("win_small", "shedL", 19)

			-- the outside --------------------------------------------------------------------------
			for _, w in { "front", "right", "back", "left" } do
				k:footing(w, STONE, PALE_STONE)
				k:dress(w, { shutters = { BLUE, BLUE_DARK }, box = { WHITE, if w == "back" then SUN else CORAL } })
			end
			k:corner(4, 10, 180, 0, PALE_STONE, STONE)
			k:corner(30, 10, 90, 0, PALE_STONE, STONE)
			k:corner(30, 28, 0, 0, PALE_STONE, STONE)
			k:corner(4, 28, 270, 0, PALE_STONE, STONE)
			k:hang("lantern_wall", "front", 15.2, 5.6)
			k:up("window_attic", 30, 19, 90, 1, WHITE, BLUE)
			k:up("window_attic", 4, 19, 270, 1, WHITE, BLUE)
			k:hang("downpipe", "back", 29.3, 0)
			k:put("water_butt", 29.0, 29.8, 0, BLUE, WALNUT)
			k:putY("doorstep", 18, 8.8, 180, 0, PALE_STONE, STONE)
			-- along the front: a bench under the window, pots by the door, crates of floats
			k:putY("bench_wood", 9, 8.3, 0, 0, DRIFT)
			k:put("flower_pot", 14.4, 8.6, 0, nil, CORAL)
			k:put("flower_pot", 21.6, 8.6, 0, nil, SUN)
			k:putY("crate", 26.6, 8.4, 10, 0, DRIFT, DRIFT)
			k:putY("crate", 29.5, 7.4, 35, 0, DRIFT, DRIFT)
			k:put("mailbox", 3.0, 3.0, 0, BLUE, WHITE)
			k:put("path_stones", 18, 5.6, 0)
			k:put("path_stones", 17.6, 3.0, 20)
			k:put("rock", 7.0, 3.4, 60)
			k:put("rock", 11.4, 1.8, 200)
			k:put("bush", 24.0, 3.6, 0)
			k:put("flower_border", 1.6, 24, 90, STONE, CORAL)
			-- the deck in front of the shed, beach chairs and an umbrella on it
			k:putY("deck_platform", 38, 5.6, 0, 0, DRIFT, WALNUT)
			k:putY("beach_chair", 35.6, 4.8, 200, 1, WHITE, BLUE)
			k:putY("umbrella_sun", 40.4, 4.4, 0, 1, WHITE, CORAL)
			k:put("lamp_post", 31.0, 4.0, 0)
			-- behind: a bench looking out over the water, rocks and beach grass
			k:put("bench_garden", 16, 33.6, 0, DRIFT, BLUE)
			k:put("beach_chair", 23.0, 33.2, 20, WHITE, SUN)
			k:put("rock", 36.0, 31.0, 120)
			k:put("rock", 41.6, 33.4, 20)
			k:put("bush", 7.0, 32.0, 0)
			k:put("woodpile", 33.45, 29.0, 0)
			k:put("bicycle", 45.0, 30.0, 0, BLUE, WHITE)

			-- the cottage --------------------------------------------------------------------------
			-- the bedroom
			k:put("bed_double", 8.6, 23.85, 180, WALNUT, "C8DCE8")
			k:put("nightstand", 12.65, 26.75, 180, WALNUT)
			k:on("lamp_table", "nightstand", 12.65, 26.75, 180)
			k:put("wardrobe", 5.45, 14.0, 90, WHITE)
			k:put("dresser", 10.0, 11.25, 0, WHITE)
			k:on("candles", "dresser", 9.0, 11.3, 0)
			k:on("vase_flowers", "dresser", 11.2, 11.2, 0, WHITE, CORAL)
			k:put("rug_round", 9.6, 17.2, 0, "C8DCE8", WHITE)
			k:hang("art_landscape", "back", 8.6, 6.6, "b")
			k:put("light_ceiling", 9, 19, 0)

			-- the fire at the end with two chairs drawn up to it
			k:put("fireplace", 28.45, 14.5, 270, "C9C3B8", WHITE)
			k:put("rug_round", 25.0, 15.0, 0, "C8DCE8", BLUE)
			k:put("armchair", 24.0, 12.8, 90, BLUE)
			k:put("chair_rocking", 24.0, 17.3, 90, WALNUT, CORAL)
			k:put("lamp_floor", 21.4, 11.2, 0)
			k:put("light_ceiling", 25.4, 15, 0)
			k:hang("clock_wall", "right", 19.5, 8.0, "b", BLUE)

			-- the kitchen along the back wall, the table in the middle
			k:put("counter_sink", 15.9, 26.35, 180, WHITE, BLUE)
			k:put("stove", 18.9, 26.35, 180, WHITE, BLUE)
			k:on("kettle", "stove", 18.6, 26.3, 160, CORAL)
			k:put("fridge", 20.35, 22.0, 270, WHITE)
			k:put("table_dining_small", 17.5, 17.0, 0, DRIFT)
			k:on("vase_flowers", "table_dining_small", 17.5, 17.0, 0, WHITE, SUN)
			k:put("chair_wood", 17.5, 14.7, 0, DRIFT, BLUE)
			k:put("chair_wood", 19.8, 17.0, 270, DRIFT, BLUE)
			k:put("lamp_pendant", 17.5, 17.0, 0)
			k:hang("shelf_wall", "back", 17.4, 7.4, "b", WALNUT)

			-- the bathroom
			k:put("bathtub", 27.95, 24.55, 180)
			k:put("toilet", 23.75, 26.5, 90)
			k:put("sink_vanity", 23.35, 23.0, 90, WHITE)
			k:hang("mirror_wall", "bathL", 23.0, 4.8, "a")
			k:put("light_ceiling", 26, 24, 0)

			-- the boat shed: the bench at the back, timber along one side, crates by the door
			k:put("workbench", 38, 24.45, 180, DRIFT)
			k:hang("tool_board", "shedB", 38, 6.4, "b")
			k:put("timber_rack", 33.55, 18.4, 90)
			k:put("plank_stack", 42.25, 18.4, 270)
			k:putY("sawhorse", 38.6, 18.6, 90, F)
			k:put("crate", 34.0, 23.6, 15, DRIFT, DRIFT)
			k:on("lantern", "crate", 34.0, 23.6, 0)
			k:put("lamp_pendant", 38, 19, 0)
		end,
		"seaside"
	)
end
