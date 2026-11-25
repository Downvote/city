--!strict
-- The beach house (seaside): pale blue boards up on white posts over the sand, a hipped roof, a
-- deck along the front and down one side with white rails, and a stair up from the sand under the
-- side deck. Upstairs is a bright front room with the kitchen in the corner, and behind it a
-- bedroom, a bathroom with a round window and a little bunk room. Down on the sand are beach
-- chairs under an umbrella, a shower to rinse off, the barbecue and a picnic table in the shade.
--
-- The frame: x across, z back from the street (z = 0). The house is x 6..30 and z 10..30 a floor
-- up, the deck x 6..36 and z 4..10 with the side deck x 30..36 and z 10..30, all on posts.

local HomeKit = require(script.Parent.Parent.HomeKit)

type Finish = HomeKit.Finish

local F = HomeKit.F

-- finishes
local BOARDS: Finish = { c = "BFD6E8", m = "WoodPlanks" } -- pale sky boards
local INSIDE: Finish = { c = "F7F3EA", m = "WoodPlanks" }
local BATH: Finish = { c = "E3EFEF", m = "SmoothPlastic" }
local ROOF: Finish = { c = "7E93A6", m = "RoofShingles" } -- slate blue
local RAIL: Finish = { c = "FAF6EC", m = "Wood" }
local FLOOR: Finish = { c = "D9C8A8", m = "WoodPlanks" }
local DECK: Finish = { c = "C9B08C", m = "WoodPlanks" } -- weathered
local BATH_TILES: Finish = { c = "D2E6E6", m = "CeramicTiles" }
local SAND: Finish = { c = "E8D9B4", m = "Sand" }
-- paint for the pieces
local NAVY = "3E5A7A"
local WHITE = "FAF6EC"
local CORAL = "E08566"
local AQUA = "8FC8C8"
local DRIFT = "C9B08C" -- driftwood
local SUN = "E9C46A"

return function(add: any)
	add(
		"home_beach_house",
		"Beach house",
		"Up on posts over the sand, with a deck on two sides and a stair down to the beach.",
		"sun",
		40,
		36,
		function(b: any)
			local k = HomeKit.new(b)

			-- the floors: sand underneath, the house and its decks a floor up --------------------
			b:floor(2, 0, 40, 36, SAND)
			b:floor(6, 10, 18, 30, FLOOR, 1) -- the front room and the bedroom
			b:floor(18, 10, 30, 20, FLOOR, 1)
			b:floor(18, 20, 24, 30, BATH_TILES, 1)
			b:floor(24, 20, 30, 30, FLOOR, 1)
			b:floor(6, 4, 36, 10, DECK, 1)
			b:floor(30, 10, 36, 30, DECK, 1)

			-- the walls upstairs, the rails round the decks --------------------------------------
			k:wall("front", 6, 10, 30, 10, BOARDS, INSIDE, 1)
			k:wall("right", 30, 10, 30, 30, BOARDS, INSIDE, 1)
			k:wall("back", 30, 30, 6, 30, BOARDS, INSIDE, 1)
			k:wall("left", 6, 30, 6, 10, BOARDS, INSIDE, 1)
			k:wall("mid", 6, 20, 30, 20, INSIDE, INSIDE, 1)
			k:wall("bathL", 18, 20, 18, 30, BATH, INSIDE, 1)
			k:wall("bathR", 24, 20, 24, 30, INSIDE, BATH, 1)
			k:wall("railF", 6, 4, 36, 4, RAIL, RAIL, 1, "railing")
			k:wall("railR", 36, 4, 36, 30, RAIL, RAIL, 1, "railing")
			k:wall("railL", 6, 8, 6, 4, RAIL, RAIL, 1, "railing")

			b:roof(6, 10, 30, 30, "hip", 6, 0, ROOF, BOARDS, 1, 1.2)

			-- doors and windows ------------------------------------------------------------------
			k:open("door_glass", "front", 18, NAVY, WHITE)
			k:open("win_wide", "front", 10, WHITE, WHITE)
			k:open("win_wide", "front", 25.4, WHITE, WHITE)
			k:open("win_square", "right", 12.6, WHITE, WHITE)
			k:open("win_square", "left", 24.5, WHITE, WHITE)
			k:open("win_porthole", "back", 21, WHITE, NAVY)
			k:open("door_wood", "mid", 15, WHITE, NAVY)
			k:open("door_wood", "mid", 21, WHITE, NAVY)
			k:open("door_wood", "mid", 26.6, WHITE, NAVY)

			-- outside, upstairs: shutters, lights, and on the deck loungers and a table ---------------
			k:dress("left", { shutters = { NAVY, "2E4660" }, box = { WHITE, CORAL } })
			k:dress("right", { shutters = { NAVY, "2E4660" } })
			k:hang("lantern_wall", "front", 15.0, 5.4, "a")
			k:hang("lantern_wall", "front", 21.0, 5.4, "a")
			k:hang("string_lights", "front", 10, 9.6, "a")
			k:hang("string_lights", "front", 25.4, 9.6, "a")
			for _, p in { { 6, 10 }, { 30, 10 }, { 30, 30 }, { 6, 30 } } do
				k:corner(p[1], p[2], if p[2] == 10 then (if p[1] == 6 then 180 else 90) else (if p[1] == 6 then 270 else 0), 1, WHITE, WHITE)
			end
			k:up("chair_lounge", 9.6, 7.0, 180, 1, WHITE, AQUA)
			k:up("chair_lounge", 12.8, 7.0, 180, 1, WHITE, CORAL)
			k:up("table_side", 15.2, 6.2, 0, 1, WHITE)
			b:item("flower_pot", 15.2, 6.2, 0, 1, HomeKit.top("table_side", 1))
			k:up("table_round", 27.4, 7.0, 0, 1, WHITE, DRIFT)
			k:up("chair_wood", 25.1, 7.0, 90, 1, WHITE, NAVY)
			k:up("chair_wood", 29.7, 7.0, 270, 1, WHITE, NAVY)
			b:item("vase_flowers", 27.4, 7.0, 0, 1, HomeKit.top("table_round", 1))
			k:up("chair_rocking", 33.2, 12.0, 270, 1, WHITE, AQUA)
			k:up("flower_pot", 34.6, 5.2, 0, 1, nil, CORAL)
			k:up("flower_pot", 7.2, 5.2, 0, 1, nil, SUN)
			k:up("flower_pot", 6.9, 9.0, 0, 1, nil, CORAL)

			-- the stair up from the sand, under the side deck (it lands at the deck's front end)
			k:putY("stairs_straight", 33, 23, 0, F, WHITE, DRIFT)

			-- the posts: under every corner of the house and the decks, and along their edges
			-- (each set in a little from the floor's edges, its top hidden in the floor)
			for _, p in {
				{ 6.6, 4.6 },
				{ 14, 4.6 },
				{ 22, 4.6 },
				{ 29.5, 4.6 },
				{ 35.4, 4.6 },
				{ 6.6, 10 },
				{ 35.4, 10 },
				{ 6.6, 20 },
				{ 35.4, 15.4 },
				{ 6.6, 29.4 },
				{ 18, 29.4 },
				{ 29.5, 29.4 },
			} do
				k:putY("pillar_square", p[1], p[2], 0, F - 0.1, WHITE, WHITE)
			end

			-- down on the sand -------------------------------------------------------------------
			k:putY("beach_chair", 12, 1.9, 180, F, WHITE, CORAL)
			k:putY("beach_chair", 15, 1.9, 180, F, WHITE, AQUA)
			k:putY("umbrella_sun", 8.6, 3.2, 0, F, WHITE, CORAL)
			k:putY("beach_chair", 30, 2.1, 200, F, WHITE, SUN)
			k:putY("rock", 38.0, 2.2, 40, F)
			k:putY("rock", 3.6, 2.4, 200, F)
			k:putY("shower", 38.0, 32.0, 270, F)
			k:putY("picnic_table", 13, 16.6, 0, F, DRIFT, WHITE)
			k:putY("bbq", 22.6, 15.0, 0, F, NAVY)
			k:putY("bicycle", 27.0, 21.6, 90, F, CORAL, WHITE)
			k:putY("crate", 9.4, 26.2, 15, F, DRIFT, DRIFT)
			k:putY("crate", 9.5, 26.1, 40, F + 2, DRIFT, DRIFT)
			k:putY("water_butt", 4.4, 22.0, 0, F, NAVY, DRIFT)
			k:putY("planter_box", 3.8, 12.0, 90, F, DRIFT, CORAL)
			k:putY("bush", 3.6, 33.0, 0, F)
			k:putY("bush", 22.0, 33.4, 0, F)
			k:putY("mailbox", 38.6, 1.6, 0, F, NAVY, WHITE)
			k:putY("lamp_post", 38.4, 12.0, 0, F, WHITE)

			-- upstairs: the front room ------------------------------------------------------------
			-- the sofa with its back to the bedrooms looking out to sea, the kitchen in the corner
			k:up("sofa_three", 11, 18.0, 180, 1, WHITE, AQUA)
			k:up("rug_round", 11, 14, 0, 1, "BFD6E8", WHITE)
			k:up("table_coffee", 11, 14.0, 0, 1, DRIFT)
			b:item("books_stack", 10.4, 14.2, 15, 1, HomeKit.top("table_coffee", 1))
			k:up("armchair", 7.9, 13.0, 90, 1, CORAL)
			k:up("lamp_floor", 15.8, 18.6, 0, 1)
			k:up("plant_big", 15.6, 12.2, 0, 1)
			k:up("counter_sink", 28.4, 12.0, 270, 1, WHITE, AQUA)
			k:up("stove", 28.4, 15.0, 270, 1, WHITE, AQUA)
			k:up("fridge", 28.4, 18.2, 270, 1, WHITE)
			b:item("kettle", 28.5, 15.5, 250, 1, HomeKit.top("stove", 1))
			k:up("table_dining_small", 23, 15, 0, 1, WHITE)
			k:up("chair_dining", 20.7, 15, 90, 1, WHITE, NAVY)
			k:up("chair_dining", 23, 17.3, 180, 1, WHITE, NAVY)
			b:item("vase_flowers", 23, 15, 0, 1, HomeKit.top("table_dining_small", 1))
			k:up("light_ceiling", 11, 14, 0, 1)
			k:up("lamp_pendant", 23, 15, 0, 1, WHITE)
			k:hang("art_landscape", "mid", 9, 6.8, "a")
			k:hang("clock_wall", "front", 7.6, 7.6, "b", NAVY)

			-- the bedroom
			k:up("bed_double", 12, 25.85, 180, 1, WHITE, AQUA)
			k:up("nightstand", 7.9, 28.75, 180, 1, WHITE)
			b:item("lamp_table", 7.9, 28.75, 180, 1, HomeKit.top("nightstand", 1))
			k:up("nightstand", 16.1, 28.75, 180, 1, WHITE)
			b:item("lamp_table", 16.1, 28.75, 180, 1, HomeKit.top("nightstand", 1))
			k:hang("art_flowers", "back", 12, 6.8, "b")
			k:up("light_ceiling", 12, 23, 0, 1)

			-- the bathroom
			k:up("shower", 20.15, 27.85, 0, 1)
			k:up("toilet", 22.25, 24.2, 270, 1)
			k:up("sink_vanity", 19.35, 22.6, 90, 1, WHITE)
			k:up("light_ceiling", 21, 25, 0, 1)

			-- the bunk room
			k:up("bed_bunk", 27, 26.05, 180, 1, WHITE, CORAL)
			k:up("toy_chest", 26.9, 21.4, 0, 1, AQUA)
			k:up("light_ceiling", 27, 24, 0, 1)
		end,
		"seaside"
	)
end
