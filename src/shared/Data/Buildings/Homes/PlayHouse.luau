--!strict
-- The play house (playful): a bright little house with every wall a different pastel, round
-- windows, a pointed teal roof and bunting across the front. The front half is one big playroom
-- (beanbags round the TV, a games table, an arcade cabinet, a rocking horse); behind it a bedroom
-- with bunks and a little house bed, the kitchen and the bathroom. Beside it a fenced playground
-- on sand with swings, a slide, a sandpit and a picnic table, and a swing on the tree out the back.
--
-- The frame: x across, z back from the street (z = 0). The house is x 4..32 and z 12..34, the
-- playground x 34..48 and z 4..30.

local HomeKit = require(script.Parent.Parent.HomeKit)

type Finish = HomeKit.Finish

local F = HomeKit.F

-- finishes: a different pastel on every side
local BUTTER: Finish = { c = "F3DFA6", m = "WoodPlanks" }
local MINT: Finish = { c = "CFE8D8", m = "WoodPlanks" }
local BLUSH: Finish = { c = "F0CDC4", m = "WoodPlanks" }
local LILAC: Finish = { c = "DCD2EC", m = "WoodPlanks" }
local INSIDE: Finish = { c = "FAF3E6", m = "SmoothPlastic" }
local KIDS: Finish = { c = "E6F0F6", m = "SmoothPlastic" } -- the bedroom: pale sky
local BATH: Finish = { c = "E4F0EC", m = "SmoothPlastic" }
local ROOF: Finish = { c = "6FA8A0", m = "RoofShingles" } -- soft teal
local PLAY_FLOOR: Finish = { c = "D9C8E6", m = "Carpet" } -- lilac carpet
local OAK: Finish = { c = "D2AE82", m = "WoodPlanks" }
local KITCHEN_TILES: Finish = { c = "F2E6CC", m = "CeramicTiles" }
local BATH_TILES: Finish = { c = "D2E8E2", m = "CeramicTiles" }
local SAND: Finish = { c = "EAD9B0", m = "Sand" }
local PAVING: Finish = { c = "EAE6DC", m = "Pavement" }
-- paint for the pieces
local CORAL = "F28C6A" -- the front door
local TEAL = "4F9A94"
local SUN = "F2C14E"
local PINK = "E8879A"
local SKY = "7FB6D9"
local MINT_PAINT = "8CCFAE"
local WHITE = "FAF6EC"
local LILAC_PAINT = "A48CC8"

return function(add: any)
	add(
		"home_play_house",
		"Play house",
		"A bright little house with round windows, a playroom and its own playground.",
		"gamepad",
		50,
		46,
		function(b: any)
			local k = HomeKit.new(b)

			-- the floors -------------------------------------------------------------------------
			b:floor(4, 12, 32, 22, PLAY_FLOOR)
			b:floor(4, 22, 16, 34, OAK) -- the bedroom
			b:floor(16, 22, 26, 34, KITCHEN_TILES)
			b:floor(26, 22, 32, 34, BATH_TILES)
			b:floor(34, 4, 48, 30, SAND) -- the playground
			b:floor(16, 0, 20, 12, PAVING) -- the path

			-- the walls ----------------------------------------------------------------------------
			k:wall("front", 4, 12, 32, 12, BUTTER, INSIDE)
			k:wall("right", 32, 12, 32, 34, MINT, INSIDE)
			k:wall("back", 32, 34, 4, 34, BLUSH, INSIDE)
			k:wall("left", 4, 34, 4, 12, LILAC, INSIDE)
			k:wall("mid", 4, 22, 32, 22, INSIDE, KIDS)
			k:wall("kitL", 16, 22, 16, 34, INSIDE, KIDS)
			k:wall("kitR", 26, 22, 26, 34, BATH, INSIDE)

			b:roof(4, 12, 32, 34, "pyramid", 8, 0, ROOF, ROOF, 0, 0.8)

			-- doors and windows: round ones all round ----------------------------------------------
			k:open("door_front", "front", 18, CORAL, WHITE)
			k:open("win_porthole", "front", 9, WHITE, SUN)
			k:open("win_porthole", "front", 27, WHITE, PINK)
			k:open("win_porthole", "left", 17, WHITE, SKY)
			k:open("win_porthole", "left", 28, WHITE, MINT_PAINT)
			k:open("win_porthole", "right", 19.5, WHITE, LILAC_PAINT)
			k:open("win_small", "right", 25, WHITE, TEAL)
			k:open("win_square", "back", 20.85, WHITE, TEAL)
			k:open("door_wood", "mid", 12, SKY, WHITE)
			k:open("arch_open", "mid", 21)
			k:open("door_wood", "mid", 29, MINT_PAINT, WHITE)

			-- the outside --------------------------------------------------------------------------
			-- bunting along the front, an awning over the door, flowers under the round windows
			k:hang("bunting", "front", 9, 9.4)
			k:hang("bunting", "front", 27, 9.4)
			k:hang("awning", "front", 18, 9.0, "a", CORAL, WHITE)
			k:hang("window_box", "front", 9, 2.9, "a", WHITE, PINK)
			k:hang("window_box", "front", 27, 2.9, "a", WHITE, SUN)
			k:hang("window_box", "left", 17, 2.9, "a", WHITE, SUN)
			k:hang("string_lights", "right", 16, 9.6)
			k:hang("lantern_wall", "front", 14.8, 5.6, "a", TEAL)
			k:hang("downpipe", "back", 31.3, 0, "a", TEAL, TEAL)
			k:hang("trellis", "back", 10, 1.3)
			k:corner(4, 12, 180, 0, WHITE, WHITE)
			k:corner(32, 12, 90, 0, WHITE, WHITE)
			k:corner(32, 34, 0, 0, WHITE, WHITE)
			k:corner(4, 34, 270, 0, WHITE, WHITE)
			k:putY("doorstep", 18, 10.8, 180, 0, WHITE, SKY)
			-- the front garden: a gnome among the flowers, a mailbox, a lamp by the path
			k:put("flower_bed", 9, 8.4, 0, nil, PINK)
			k:put("flower_bed", 27, 8.4, 0, nil, LILAC_PAINT)
			k:put("gnome", 12.4, 8.0, 200)
			k:put("gnome", 24.0, 8.6, 160)
			k:put("bush", 5.6, 4.0, 0)
			k:put("bush", 29.4, 3.6, 0)
			k:put("mailbox", 21.6, 1.4, 0, SKY, WHITE)
			k:put("lamp_post", 14.6, 1.4, 0, TEAL)
			k:put("bird_house", 2.4, 20.0, 0, PINK, TEAL)
			k:put("flower_border", 2.2, 27, 90, WHITE, SUN)

			-- the playground: a fence round the sand, swings, a slide, the sandpit, a picnic table
			k:fenceX(3.0, 34, 50, nil, WHITE, WHITE)
			k:fenceZ(49.0, 5.0, 29.0, nil, WHITE, WHITE)
			k:fenceX(29.8, 34, 50, { 40 }, WHITE, WHITE)
			k:putY("swing_set", 39.6, 9.4, 0, F, SKY, SUN)
			k:putY("slide", 45.0, 19.6, 0, F, PINK, SUN)
			k:putY("sandbox", 38.4, 19.6, 0, F, TEAL, SUN)
			k:putY("picnic_table", 39.0, 26.0, 90, F, SUN, WHITE)
			k:putY("umbrella_sun", 39.0, 26.0, 0, F, WHITE, CORAL)
			k:putY("flower_pot", 35.0, 5.6, 0, F, nil, PINK)
			k:putY("bench_garden", 45.6, 10.0, 270, F, WHITE, TEAL)

			-- out the back: the tree with a swing, a bench, the barbecue
			k:put("tree_swing", 12, 40, 0)
			k:put("bench_garden", 26, 43.6, 180, WHITE, TEAL)
			k:put("bbq", 31.0, 38.8, 0, TEAL)
			k:put("flower_bed", 22, 37.2, 0, nil, SUN)

			-- the playroom -------------------------------------------------------------------------
			-- beanbags round the TV on the end wall, the games table and the arcade cabinet on the
			-- other side, shelves of toys
			k:hang("tv_wall", "left", 17, 4.0, "b")
			k:put("rug_round", 8.8, 17, 0, SKY, SUN)
			k:put("beanbag", 9.6, 14.4, 0, CORAL)
			k:put("beanbag", 11.6, 17.2, 0, SUN)
			k:put("beanbag", 9.6, 20.0, 0, MINT_PAINT)
			k:put("toy_chest", 5.6, 14.2, 90, PINK)
			k:put("bookshelf", 6.5, 20.85, 180, WHITE)
			k:put("rocking_horse", 14.6, 15.0, 30, WHITE, PINK)
			k:put("table_games", 25.4, 16.8, 0, SUN, TEAL)
			k:put("stool", 22.4, 16.8, 0, TEAL, SUN)
			k:put("stool", 28.4, 16.8, 0, TEAL, PINK)
			k:put("arcade", 30.45, 14.6, 270, PINK, TEAL)
			k:put("shelf_cubes", 25.0, 20.95, 180, WHITE)
			k:on("teddy", "shelf_cubes", 24.4, 20.9, 200)
			k:on("plant_small", "shelf_cubes", 25.8, 20.9, 0)
			k:put("plant_big", 22.0, 14.2, 0)
			k:put("light_ceiling", 9, 17, 0)
			k:put("light_ceiling", 25, 17, 0)
			k:hang("art_abstract", "front", 22.6, 6.6, "b")
			k:hang("clock_wall", "mid", 17.6, 8.6, "a", CORAL)

			-- the bedroom: bunks and a little house bed side by side, a lamp between them
			k:put("bed_bunk", 6.55, 30.05, 180, WHITE, SKY)
			k:put("bed_kids", 13.5, 30.25, 180, WHITE, PINK)
			k:put("nightstand", 10.1, 32.75, 180, WHITE)
			k:on("lamp_table", "nightstand", 10.1, 32.75, 180, SUN)
			k:put("toy_chest", 7.4, 23.3, 0, SUN)
			k:put("rug_round", 10.2, 25.4, 0, SUN, WHITE)
			k:hang("art_flowers", "left", 25, 6.4, "b")
			k:put("light_ceiling", 10, 28, 0)

			-- the kitchen
			k:put("fridge", 17.85, 32.35, 180, WHITE)
			k:put("counter_sink", 20.85, 32.35, 180, WHITE, TEAL)
			k:put("stove", 23.85, 32.35, 180, WHITE, TEAL)
			k:on("kettle", "stove", 23.5, 32.3, 160, CORAL)
			k:put("table_round", 21, 27.2, 0, WHITE, SUN)
			k:on("vase_flowers", "table_round", 21, 27.2, 0, WHITE, PINK)
			k:put("chair_wood", 18.7, 27.2, 90, SUN, TEAL)
			k:put("chair_wood", 23.3, 27.2, 270, PINK, TEAL)
			k:put("chair_wood", 21, 29.5, 180, SKY, TEAL)
			k:put("lamp_pendant", 21, 27.2, 0, CORAL)

			-- the bathroom
			k:put("bathtub", 29.95, 30.55, 0)
			k:put("toilet", 27.3, 32.25, 180)
			k:put("sink_vanity", 27.35, 25.6, 90, WHITE)
			k:hang("mirror_wall", "kitR", 25.6, 4.8, "a")
			k:put("light_ceiling", 29, 28, 0)
		end,
		"playful"
	)
end
