--!strict
-- The glass house (modern): one wide flat roof on slim posts over two wings. The living wing at
-- the front left is glass to the street, open plan, with a pond in front of the glass; the
-- sleeping wing at the back right looks onto a wooden deck through a glass wall, with the
-- bathroom and a study behind the bedroom. The roof runs on over the deck and over a paved
-- terrace behind the living wing, where the barbecue is.
--
-- The frame: x across, z back from the street (z = 0). The living wing is x 4..24 and z 8..24,
-- the sleeping wing x 24..40 and z 16..36, the roof x 4..40 and z 8..36 over both, the deck in
-- front of the sleeping wing from z 2.

local HomeKit = require(script.Parent.Parent.HomeKit)

type Finish = HomeKit.Finish

local F = HomeKit.F

-- finishes
local WALLS: Finish = { c = "EEEBE4", m = "WoodPlanks" } -- warm white boards
local FRAMES: Finish = { c = "4E4E54", m = "Metal" } -- the glass walls' dark frames
local INSIDE: Finish = { c = "F4F2EE", m = "WoodPlanks" }
local BATH: Finish = { c = "E6ECEC", m = "CeramicTiles" }
local ROOF: Finish = { c = "8A8A90", m = "Concrete" }
local FASCIA: Finish = { c = "4E4E54", m = "Metal" }
local CONCRETE_FLOOR: Finish = { c = "D9D4CB", m = "Concrete" }
local WOOD_FLOOR: Finish = { c = "C8AE8A", m = "WoodPlanks" }
local BATH_TILES: Finish = { c = "D8DCDC", m = "CeramicTiles" }
local DECK: Finish = { c = "A07E60", m = "WoodPlanks" }
local PAVING: Finish = { c = "DDD8CE", m = "Pavement" }
-- paint for the pieces
local CHARCOAL = "4E4E54"
local GREY = "8C8C94"
local WHITE = "F4F2EE"
local MUSTARD = "D9A93F"
local OAK = "C8AE8A"
local WALNUT = "7E5A40"
local SAGE = "86A886"

return function(add: any)
	add(
		"home_glass_house",
		"Glass house",
		"A flat roofed house with glass to the garden, a deck and a pond out front.",
		"window",
		46,
		40,
		function(b: any)
			local k = HomeKit.new(b)

			-- the floors -------------------------------------------------------------------------
			b:floor(4, 8, 24, 24, CONCRETE_FLOOR) -- the living wing, open plan
			b:floor(24, 16, 40, 28, WOOD_FLOOR) -- the bedroom
			b:floor(24, 28, 32, 36, BATH_TILES)
			b:floor(32, 28, 40, 36, WOOD_FLOOR) -- the study
			b:floor(24, 2, 44, 16, DECK)
			b:floor(4, 24, 24, 36, PAVING) -- the terrace behind
			b:floor(26, 0, 30, 2, PAVING) -- the path in from the street

			-- the walls ----------------------------------------------------------------------------
			-- the living wing: glass across the front, the door onto the deck at the side
			k:wall("lfront", 4, 8, 24, 8, FRAMES, FRAMES, 0, "glass")
			k:wall("lright", 24, 8, 24, 16, WALLS, INSIDE)
			k:wall("lshare", 24, 16, 24, 24, INSIDE, INSIDE)
			k:wall("lback", 24, 24, 4, 24, WALLS, INSIDE)
			k:wall("lleft", 4, 24, 4, 8, WALLS, INSIDE)
			-- the sleeping wing: glass onto the deck, plain walls behind
			k:wall("sfront", 24, 16, 40, 16, FRAMES, FRAMES, 0, "glass")
			k:wall("sright", 40, 16, 40, 36, WALLS, INSIDE)
			k:wall("sbackS", 40, 36, 32, 36, WALLS, INSIDE)
			k:wall("sbackB", 32, 36, 24, 36, WALLS, BATH)
			k:wall("sleftB", 24, 36, 24, 28, WALLS, BATH)
			k:wall("sleft", 24, 28, 24, 24, WALLS, INSIDE)
			k:wall("smid", 24, 28, 40, 28, INSIDE, BATH)
			k:wall("ssplit", 32, 28, 32, 36, INSIDE, BATH)

			-- one flat roof over everything, deep over the glass
			b:roof(4, 8, 40, 36, "flat", 0, 0, ROOF, FASCIA, 0, 1.6)

			-- doors and windows ------------------------------------------------------------------
			k:open("door_glass", "lright", 13.6, CHARCOAL, CHARCOAL)
			k:open("arch_open", "lshare", 20)
			k:open("win_wide", "lback", 11.35, CHARCOAL, CHARCOAL)
			k:open("door_glass", "lback", 20.5, CHARCOAL, CHARCOAL)
			k:open("win_tall", "lleft", 18.6, CHARCOAL, CHARCOAL)
			k:open("door_wood", "smid", 29, WHITE, CHARCOAL)
			k:open("door_wood", "smid", 34.8, WHITE, CHARCOAL)
			k:open("win_square", "sright", 31.5, CHARCOAL, CHARCOAL)
			k:open("win_small", "sbackB", 29.6, CHARCOAL, CHARCOAL)

			-- the outside ----------------------------------------------------------------------------
			-- slim posts at the roof's open corners, lights on the walls, the deck and the path
			k:putY("pillar_square", 39.5, 8.5, 0, F, CHARCOAL, CHARCOAL)
			k:putY("pillar_square", 4.5, 35.5, 0, F, CHARCOAL, CHARCOAL)
			k:hang("sconce", "lright", 10.8, 6.2, "a", CHARCOAL)
			k:hang("sconce", "lback", 17.6, 6.2, "a", CHARCOAL)
			k:hang("sconce", "sright", 26, 6.2, "a", CHARCOAL)
			k:hang("downpipe", "sbackS", 39.3, 0, "a", CHARCOAL, CHARCOAL)
			k:hang("downpipe", "lleft", 9, 0, "a", CHARCOAL, CHARCOAL)
			-- on the deck: two loungers under a sun umbrella, a table in the shade of the roof
			k:putY("chair_lounge", 31, 5.0, 180, F, WHITE, MUSTARD)
			k:putY("chair_lounge", 34.2, 5.0, 180, F, WHITE, MUSTARD)
			k:putY("umbrella_sun", 42.4, 5.0, 0, F, WHITE, CHARCOAL)
			k:putY("planter_box", 42.0, 14.6, 0, F, CHARCOAL, SAGE)
			k:putY("planter_box", 25.0, 6.0, 90, F, CHARCOAL, MUSTARD)
			k:put("table_round", 32.6, 12.4, 0, WALNUT, CHARCOAL)
			k:on("vase_flowers", "table_round", 32.6, 12.4, 0, WHITE, MUSTARD)
			k:put("chair_wood", 30.3, 12.4, 90, CHARCOAL, CHARCOAL)
			k:put("chair_wood", 34.9, 12.4, 270, CHARCOAL, CHARCOAL)
			k:put("chair_wood", 32.6, 14.7, 180, CHARCOAL, CHARCOAL)
			k:putY("flower_pot", 25.2, 15.0, 0, F, nil, MUSTARD)
			-- the garden in front of the glass: the pond with rocks and grasses, a lamp at the path
			k:put("pond", 12, 4.2, 0)
			k:put("rock", 17.2, 2.0, 30)
			k:put("rock", 6.4, 2.3, 200)
			k:put("bush", 19.8, 4.6, 0)
			k:put("bush", 2.0, 5.0, 0)
			k:put("flower_border", 2.0, 14, 90, CHARCOAL, SAGE)
			k:put("flower_border", 2.0, 19, 90, CHARCOAL, MUSTARD)
			k:put("lamp_post", 24.2, 1.4, 0, CHARCOAL)
			k:put("mailbox", 22.2, 1.4, 0, CHARCOAL, WHITE)
			k:put("tree_pine", 42.4, 30, 0)
			k:put("tree_pine", 43.0, 22.6, 0)
			-- the terrace behind: a table for six, the barbecue, planters along the edge
			k:putY("picnic_table", 12, 30.4, 90, F, OAK, CHARCOAL)
			k:putY("bbq", 20.6, 33.9, 180, F, CHARCOAL)
			k:putY("planter_box", 4.4, 29.6, 90, F, CHARCOAL, SAGE)
			k:putY("planter_box", 16.4, 35.0, 0, F, CHARCOAL, MUSTARD)

			-- the living wing --------------------------------------------------------------------
			-- the kitchen along the back, an island with stools, the sofa facing the TV on the
			-- end wall, a round table by the glass
			k:put("fridge", 5.85, 22.35, 180, WHITE)
			k:put("counter", 8.85, 22.35, 180, WHITE, CHARCOAL)
			k:put("counter_sink", 11.85, 22.35, 180, WHITE, CHARCOAL)
			k:put("stove", 14.85, 22.35, 180, WHITE, CHARCOAL)
			k:on("kettle", "counter", 8.6, 22.4, 200, MUSTARD)
			k:on("toaster", "counter", 9.4, 22.6, 180, CHARCOAL)
			k:put("kitchen_island", 15.5, 18.0, 0, WHITE, OAK)
			k:on("vase_flowers", "kitchen_island", 14.0, 18.0, 0, WHITE, MUSTARD)
			k:put("stool_bar", 14.0, 15.3, 0, CHARCOAL, OAK)
			k:put("stool_bar", 17.0, 15.3, 0, CHARCOAL, OAK)
			k:put("lamp_pendant", 14.0, 18.0, 0, CHARCOAL)
			k:put("lamp_pendant", 17.0, 18.0, 0, CHARCOAL)
			k:hang("tv_wall", "lleft", 13, 4.2, "b")
			k:put("sofa_two", 11.0, 13.0, 270, GREY, MUSTARD)
			k:put("rug_long", 7.4, 13.0, 0, "BFB8AC", CHARCOAL)
			k:put("table_coffee", 7.4, 13.0, 90, OAK, CHARCOAL)
			k:on("books_stack", "table_coffee", 7.3, 12.2, 15)
			k:put("lamp_floor", 5.4, 9.4, 0, CHARCOAL)
			k:put("plant_big", 6.0, 18.2, 0)
			k:put("table_round", 19.5, 11.5, 0, WHITE, CHARCOAL)
			k:on("plant_small", "table_round", 19.5, 11.5, 0)
			k:put("chair_dining", 17.2, 11.5, 90, CHARCOAL, OAK)
			k:put("chair_dining", 19.5, 9.3, 0, CHARCOAL, OAK)
			k:put("chair_dining", 19.5, 13.8, 180, CHARCOAL, OAK)
			k:put("light_ceiling", 8, 13, 0)
			k:put("light_ceiling", 19.5, 11.5, 0)
			k:hang("art_abstract", "lback", 6.4, 7.6, "b")
			k:hang("clock_wall", "lshare", 23, 7.4, "b")

			-- the bedroom: the bed's head to the end wall, an armchair turned to the deck
			k:put("bed_double", 35.85, 22, 270, CHARCOAL, WHITE)
			k:put("nightstand", 38.75, 17.95, 270, OAK)
			k:on("lamp_table", "nightstand", 38.75, 17.95, 0, nil, nil)
			k:put("nightstand", 38.75, 26.05, 270, OAK)
			k:on("lamp_table", "nightstand", 38.75, 26.05, 0)
			k:put("wardrobe", 25.45, 25.0, 90, WHITE)
			k:put("armchair", 28.5, 18.0, 180, MUSTARD)
			k:put("lamp_floor", 25.3, 17.3, 0, CHARCOAL)
			k:put("rug_round", 30.6, 22.4, 0, "BFB8AC", MUSTARD)
			k:hang("art_abstract", "sright", 22, 6.8, "b")
			k:put("light_ceiling", 31, 22.4, 0)

			-- the bathroom
			k:put("shower", 26.15, 33.8, 0)
			k:put("toilet", 29.5, 34.25, 180)
			k:put("sink_vanity", 30.65, 30.8, 270, WHITE)
			k:hang("mirror_wall", "ssplit", 30.8, 4.8, "b")
			k:put("towel_rail", 25.0, 29.6, 90, nil, MUSTARD)
			k:put("light_ceiling", 28, 31.6, 0)

			-- the study
			k:put("desk_computer", 33.55, 32.5, 90, OAK, CHARCOAL)
			k:put("chair_wood", 35.6, 32.5, 270, CHARCOAL, CHARCOAL)
			k:put("bookshelf", 36.5, 34.85, 180, OAK)
			k:put("beanbag", 38.2, 31.0, 0, MUSTARD)
			k:put("light_ceiling", 36, 31.6, 0)
		end,
		"modern"
	)
end
