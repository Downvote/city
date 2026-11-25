--!strict
-- The log cabin (rustic): walls of brown logs on a stone footing, a steep mossy roof with its
-- gable to the lane, carried forward over a porch on posts. One big room inside with the fire on
-- the end wall, rocking chair and armchair drawn up to it, a long table with a bench and the
-- kitchen along the other wall; at the back a bedroom with a double bed and bunks for visitors,
-- and the bathroom. Firewood stacked under the eaves, a campfire ring with log benches and a well
-- out the back, ferns and pines along the lane.
--
-- The frame: x across, z back from the street (z = 0). The cabin is x 6..32 and z 12..38, the
-- porch in front of it from z 6.

local HomeKit = require(script.Parent.Parent.HomeKit)

type Finish = HomeKit.Finish

local F = HomeKit.F

-- finishes
local LOGS: Finish = { c = "A27A58", m = "Wood" }
local INSIDE: Finish = { c = "C9A27C", m = "Wood" } -- honey logs inside
local BATH: Finish = { c = "E8DCC6", m = "WoodPlanks" }
local ROOF: Finish = { c = "6F7A64", m = "RoofShingles" } -- mossy shingles
local GABLE: Finish = { c = "8E6A4E", m = "WoodPlanks" }
local FLOOR: Finish = { c = "B48C64", m = "WoodPlanks" }
local PORCH: Finish = { c = "9A7656", m = "WoodPlanks" }
local SLATE: Finish = { c = "C2BDB2", m = "Slate" }
-- paint for the pieces
local RED = "8C4A3E" -- the door and the window frames
local CREAM = "F2E6CC"
local MUSTARD = "D9A93F"
local MOSS = "6F7A64"
local WALNUT = "7E5A40"
local OAK = "B48C64"
local STONE = "A8A29A"
local PALE_STONE = "C9C3B8"
local CHIMNEY = "9C9690"

return function(add: any)
	add(
		"home_log_cabin",
		"Log cabin",
		"Logs, a steep roof and a porch, a fire inside and a campfire ring out the back.",
		"tree",
		44,
		46,
		function(b: any)
			local k = HomeKit.new(b)

			-- the floors -------------------------------------------------------------------------
			b:floor(6, 12, 32, 28, FLOOR) -- the big room and the hall
			b:floor(6, 28, 20, 38, FLOOR) -- the bedroom's back part
			b:floor(20, 28, 32, 38, SLATE)
			b:floor(6, 6, 32, 12, PORCH)

			-- the walls ----------------------------------------------------------------------------
			k:wall("front", 6, 12, 32, 12, LOGS, INSIDE)
			k:wall("right", 32, 12, 32, 38, LOGS, INSIDE)
			k:wall("backB", 32, 38, 20, 38, LOGS, BATH)
			k:wall("backR", 20, 38, 6, 38, LOGS, INSIDE)
			k:wall("left", 6, 38, 6, 12, LOGS, INSIDE)
			k:wall("bedwall", 6, 24, 20, 24, INSIDE, INSIDE)
			k:wall("split", 20, 24, 20, 38, BATH, INSIDE)
			k:wall("bathwall", 20, 28, 32, 28, INSIDE, BATH)

			-- the roof: steep, its gable to the lane, on over the porch
			b:roof(6, 6, 32, 38, "gable", 11, 1, ROOF, GABLE, 0, 0.6)

			-- doors and windows ------------------------------------------------------------------
			k:open("door_wood", "front", 19, RED, CREAM)
			k:open("win_square", "front", 11, RED, CREAM)
			k:open("win_square", "front", 27, RED, CREAM)
			k:open("win_square", "right", 17.6, RED, CREAM)
			k:open("win_small", "right", 33, RED, CREAM)
			k:open("win_square", "left", 31, RED, CREAM)
			k:open("win_small", "left", 24, RED, CREAM)
			k:open("win_square", "backR", 13, RED, CREAM)
			k:open("door_wood", "bedwall", 16, WALNUT, CREAM)
			k:open("door_wood", "bathwall", 26, WALNUT, CREAM)

			-- the outside --------------------------------------------------------------------------
			for _, w in { "right", "backB", "backR", "left" } do
				k:footing(w, STONE, PALE_STONE)
			end
			k:dress("left", { shutters = { RED, WALNUT }, box = { WALNUT, MUSTARD } })
			k:dress("right", { shutters = { RED, WALNUT }, box = { WALNUT, "D9707F" } })
			k:dress("backR", { shutters = { RED, WALNUT } })
			k:corner(6, 12, 180, 0, WALNUT, WALNUT)
			k:corner(32, 12, 90, 0, WALNUT, WALNUT)
			k:corner(32, 38, 0, 0, WALNUT, WALNUT)
			k:corner(6, 38, 270, 0, WALNUT, WALNUT)
			-- an attic window in each gable
			k:up("window_attic", 19, 6, 180, 1, CREAM, RED)
			k:up("window_attic", 19, 38, 0, 1, CREAM, RED)
			k:hang("downpipe", "backB", 31.3, 0, "a", WALNUT, WALNUT)
			k:put("water_butt", 31.0, 39.8, 0, MOSS, WALNUT)

			-- the porch: posts at its corners and either side of the steps, rails between
			for _, x in { 7.4, 13.0, 16.4, 21.6, 25.0, 30.6 } do
				k:put("porch_post", x, 6.6, 0, OAK, WALNUT)
			end
			k:put("porch_rail", 10.2, 6.6, 0, OAK, WALNUT)
			k:put("porch_rail", 27.8, 6.6, 0, OAK, WALNUT)
			k:put("porch_rail", 6.5, 9.4, 90, OAK, WALNUT)
			k:put("porch_rail", 31.5, 9.4, 90, OAK, WALNUT)
			k:putY("doorstep", 19, 4.8, 180, 0, PALE_STONE, STONE)
			k:put("doormat", 19, 10.9, 0)
			k:hang("lantern_wall", "front", 15.9, 5.6)
			k:hang("lantern_wall", "front", 22.1, 5.6)
			k:put("chair_rocking", 10.4, 9.6, 165, WALNUT, MUSTARD)
			k:put("chair_rocking", 27.4, 9.6, 195, WALNUT, "D9707F")
			k:putY("crate", 13.6, 10.8, 10, F, OAK, OAK)
			k:on("lantern", "crate", 13.6, 10.8, 0)
			k:putY("woodpile", 24.4, 11.1, 0, F)
			k:put("flower_pot", 16.6, 11.0, 0, nil, MUSTARD)

			-- along the lane and up the path
			k:put("path_stones", 19, 1.6, 0)
			k:put("path_stones", 18.6, 3.4, 25)
			k:put("mailbox", 23.6, 3.8, 0, RED, WALNUT)
			k:put("flower_border", 6, 3.8, 0, WALNUT, MUSTARD)
			k:put("flower_border", 30, 3.8, 0, WALNUT, "D9707F")
			k:put("tree_pine", 3.0, 9.0, 0)
			k:put("tree_pine", 40.4, 8.4, 0)
			k:put("bush", 35.2, 4.6, 0)
			k:put("bush", 11.4, 1.8, 0)
			k:put("bush", 26.8, 1.9, 0)
			k:put("rock", 14.8, 2.2, 100)
			k:put("flower_border", 32.6, 1.4, 0, WALNUT, MUSTARD)

			-- firewood under the eaves down the right, a sawhorse and crates
			k:put("woodpile", 33.45, 21, 90)
			k:put("woodpile", 33.45, 24.6, 90)
			k:putY("sawhorse", 37.2, 22.6, 80, 0, OAK, WALNUT)
			k:putY("crate", 36.8, 27.4, 20, 0, OAK, OAK)
			k:putY("crate", 36.9, 27.3, 35, 2, OAK, OAK)
			k:put("rock", 40.2, 17.4, 60)

			-- the back: the campfire ring with log benches round it, the well, pines
			k:put("campfire", 12, 42.4, 0)
			k:putY("bench_wood", 12, 45.0, 180, 0, WALNUT)
			k:putY("bench_wood", 8.4, 42.4, 90, 0, WALNUT)
			k:putY("bench_wood", 15.6, 42.4, 270, 0, WALNUT)
			k:put("well", 37.6, 41.0, 0)
			k:put("tree_pine", 2.8, 33.2, 0)
			k:put("tree_pine", 40.0, 33.6, 0)
			k:put("tree_pine", 25.0, 43.2, 0)
			k:put("bird_house", 2.6, 24.0, 0, WALNUT, MOSS)
			k:put("rock", 20.0, 41.4, 140)

			-- the big room -------------------------------------------------------------------------
			-- the fire on the end wall with the wood beside it, two chairs drawn up on a rug
			k:put("chimney_hearth", 8.2, 18, 90, CHIMNEY, PALE_STONE)
			k:put("woodpile", 7.1, 22.0, 90)
			k:put("rug_round", 13.6, 18, 0, "B8505A", MUSTARD)
			k:put("chair_rocking", 13.4, 15.2, 300, WALNUT, MUSTARD)
			k:put("armchair", 13.6, 20.9, 240, "B8505A")
			k:put("table_side", 15.0, 18.0, 0, WALNUT)
			k:on("lantern", "table_side", 15.0, 18.0, 0)
			k:put("bookshelf", 11.2, 23.35, 180, WALNUT)
			k:hang("art_landscape", "front", 11, 9.2, "b")
			-- the long table with a bench on one side and chairs on the other
			k:put("table_dining_long", 23.5, 18, 90, WALNUT)
			k:on("lantern", "table_dining_long", 23.5, 17.0, 0)
			k:on("vase_flowers", "table_dining_long", 23.4, 19.4, 0, CREAM, MUSTARD)
			k:put("bench_wood", 20.3, 18, 90, WALNUT)
			k:put("chair_wood", 26.9, 16, 270, WALNUT, "B8505A")
			k:put("chair_wood", 26.9, 20, 270, WALNUT, "B8505A")
			k:put("lamp_pendant", 23.5, 15.8, 0, WALNUT)
			k:put("lamp_pendant", 23.5, 20.2, 0, WALNUT)
			-- the kitchen along the right wall
			k:put("stove", 30.4, 14.6, 270, CREAM, WALNUT)
			k:put("counter_sink", 30.4, 17.6, 270, OAK, WALNUT)
			k:put("counter", 30.4, 20.6, 270, OAK, WALNUT)
			k:on("kettle", "stove", 30.5, 14.0, 250, RED)
			k:on("toaster", "counter", 30.6, 21.2, 270, CREAM)
			k:put("pantry", 30.6, 23.9, 270, OAK, WALNUT)
			k:hang("shelf_wall", "right", 20.6, 7.0, "b", WALNUT)
			k:hang("coat_hooks", "front", 23.6, 5.4, "b", WALNUT)
			k:hang("clock_wall", "bedwall", 8.4, 7.8, "a", RED)
			k:put("light_ceiling", 13.6, 18, 0)
			k:put("plant_big", 18.2, 26.0, 0)

			-- the bedroom: the double bed and the bunks along the back wall, the wardrobe by the door
			k:put("bed_double", 10.2, 33.85, 180, WALNUT, "B8505A")
			k:put("nightstand", 14.3, 36.75, 180, WALNUT)
			k:on("lamp_table", "nightstand", 14.3, 36.75, 180)
			k:put("bed_bunk", 17.5, 34.05, 180, WALNUT, MUSTARD)
			k:put("wardrobe", 9, 25.45, 0, WALNUT)
			k:put("toy_chest", 17.6, 26.6, 0, WALNUT)
			k:hang("art_flowers", "bedwall", 12.2, 5.6, "b")
			k:put("light_ceiling", 12.6, 30, 0)

			-- the bathroom
			k:put("bathtub", 29.9, 34.55, 180)
			k:put("toilet", 22.3, 36.25, 180)
			k:put("sink_vanity", 25.5, 36.65, 180, OAK)
			k:hang("mirror_wall", "backB", 25.5, 5.0, "b")
			k:put("towel_rail", 21.0, 31.6, 90, nil, MUSTARD)
			k:put("laundry_basket", 24.2, 29.4, 0)
			k:put("light_ceiling", 26, 32.6, 0)
		end,
		"rustic"
	)
end
