--!strict
-- The manor (fancy, for a town of level 12: its crystal chandelier waits for that, Recipes/Grand).
-- The user: "make more vehicles, buildings that cost more for the endgame". Two storeys of pale
-- stone under slate with a wing either side: the library in the left wing, a glass orangery in the
-- right. A pillared porch under a pediment opens into the hall, the chandelier over it and the
-- stair up its back; the drawing room on one side with the fire and the grand piano, the dining
-- room on the other. Upstairs the main bedroom, a guest room and the bathroom. In front, a paved
-- court with a fountain on each lawn, clipped trees by the path and lamps.
--
-- The frame: x across, z back from the street (z = 0). The house is x 18..46 and z 14..38 on both
-- storeys, the wings x 4..18 and 46..60 by z 18..38 on the ground, the porch x 26..38 by z 8..14.

local HomeKit = require(script.Parent.Parent.HomeKit)

type Finish = HomeKit.Finish

local F = HomeKit.F

local STONE: Finish = { c = "ECE5D8", m = "Limestone" }
local INSIDE: Finish = { c = "F4EEE2", m = "WoodPlanks" }
local SAGE: Finish = { c = "DDE6D8", m = "WoodPlanks" }
local ROSE_WALL: Finish = { c = "EEDDD4", m = "WoodPlanks" }
local GLASSWALL: Finish = { c = "E8EEF0", m = "Glass" }
local ROOF: Finish = { c = "5E6A78", m = "Slate" }
local PEDIMENT: Finish = { c = "E8E0D0", m = "Marble" }
local MARBLE: Finish = { c = "E6E0D6", m = "Marble" }
local PARQUET: Finish = { c = "9A6B48", m = "WoodPlanks" }
local OAK: Finish = { c = "C49A6C", m = "WoodPlanks" }
local TERRACOTTA: Finish = { c = "D4A48A", m = "CeramicTiles" }
local CARPET: Finish = { c = "8A7A9C", m = "Carpet" }
local BATH: Finish = { c = "DCE4E4", m = "CeramicTiles" }
local GRAVEL: Finish = { c = "E2DCD0", m = "Pavement" }
local HEDGE: Finish = { c = "6E9A66", m = "Grass" }

local WHITE = "FAF6EC"
local GOLD = "D9A93F"
local WALNUT = "7E5A40"
local TEAL = "2E6B67"
local PLUM = "7A5A78"
local ROSE = "D9707F"
local SAGE_C = "86A886"
local STONE_C = "BDB8AE"
local PALE = "DAD4C8"

return function(add: any)
	add(
		"grand_manor",
		"Manor house",
		"Two storeys of stone with two wings, a crystal chandelier in the hall and a glass orangery.",
		"house",
		64,
		50,
		function(b: any)
			local k = HomeKit.new(b)

			-- the floors -------------------------------------------------------------------------
			b:floor(18, 14, 28, 38, PARQUET) -- the drawing room
			b:floor(28, 14, 36, 38, MARBLE) -- the hall
			b:floor(36, 14, 46, 38, PARQUET) -- the dining room
			b:floor(4, 18, 18, 38, OAK) -- the library
			b:floor(46, 18, 60, 38, TERRACOTTA) -- the orangery
			b:floor(18, 14, 28, 38, CARPET, 1) -- the main bedroom
			b:floor(28, 14, 36, 38, OAK, 1) -- the landing
			b:floor(36, 14, 46, 30, CARPET, 1) -- the guest room
			b:floor(36, 30, 46, 38, BATH, 1)
			b:floor(26, 8, 38, 14, MARBLE) -- the porch
			b:floor(28, 0, 36, 8, GRAVEL) -- the path up to it
			b:floor(10, 0, 28, 6, GRAVEL) -- the court across the front
			b:floor(36, 0, 54, 6, GRAVEL)

			-- the walls ---------------------------------------------------------------------------
			k:wall("front", 18, 14, 46, 14, STONE, INSIDE)
			k:wall("right", 46, 14, 46, 18, STONE, INSIDE)
			k:wall("back", 46, 38, 18, 38, STONE, INSIDE)
			k:wall("left", 18, 18, 18, 14, STONE, INSIDE)
			k:wall("hallL", 28, 14, 28, 38, ROSE_WALL, INSIDE)
			k:wall("hallR", 36, 38, 36, 14, SAGE, INSIDE)
			-- the wings: the library's, and the orangery's of glass
			k:wall("lfront", 4, 18, 18, 18, STONE, INSIDE)
			k:wall("lback", 18, 38, 4, 38, STONE, INSIDE)
			k:wall("lleft", 4, 38, 4, 18, STONE, INSIDE)
			k:wall("lshared", 18, 18, 18, 38, ROSE_WALL, INSIDE)
			k:wall("rfront", 46, 18, 60, 18, GLASSWALL, GLASSWALL, 0, "glass")
			k:wall("rright", 60, 18, 60, 38, GLASSWALL, GLASSWALL, 0, "glass")
			k:wall("rback", 60, 38, 46, 38, GLASSWALL, GLASSWALL, 0, "glass")
			k:wall("rshared", 46, 38, 46, 18, SAGE, STONE)
			-- upstairs
			k:wall("upfront", 18, 14, 46, 14, STONE, INSIDE, 1)
			k:wall("upright", 46, 14, 46, 38, STONE, INSIDE, 1)
			k:wall("upback", 46, 38, 18, 38, STONE, INSIDE, 1)
			k:wall("upleft", 18, 38, 18, 14, STONE, INSIDE, 1)
			k:wall("uphallL", 28, 14, 28, 38, INSIDE, INSIDE, 1)
			k:wall("uphallR", 36, 38, 36, 14, INSIDE, INSIDE, 1)
			k:wall("upbath", 36, 30, 46, 30, INSIDE, BATH, 1)
			-- clipped hedges along the street, the way in between them
			k:wall("hedgeL", 2, 2, 10, 2, HEDGE, HEDGE, 0, "hedge")
			k:wall("hedgeR", 54, 2, 62, 2, HEDGE, HEDGE, 0, "hedge")

			-- the roofs: hipped slate over the house and each wing, a pediment over the porch
			b:roof(18, 14, 46, 38, "hip", 9, 0, ROOF, STONE, 1, 1)
			b:roof(4, 18, 18, 38, "hip", 6, 0, ROOF, STONE, 0, 1)
			b:roof(46, 18, 60, 38, "hip", 6, 0, ROOF, STONE, 0, 1)
			b:roof(26, 8, 38, 14, "gable", 4, 1, ROOF, PEDIMENT, 0, 0.2)

			-- doors and windows ----------------------------------------------------------------
			k:open("door_double", "front", 32, TEAL, GOLD)
			for _, x in { 21, 25, 39, 43 } do
				k:open("win_tall", "front", x, WHITE, WHITE)
				k:open("win_tall", "upfront", x, WHITE, WHITE)
			end
			k:open("win_square", "upfront", 32, WHITE, WHITE)
			for _, x in { 21.5, 42.5 } do
				k:open("win_tall", "back", x, WHITE, WHITE)
				k:open("win_square", "upback", x, WHITE, WHITE)
			end
			k:open("win_tall", "upback", 32, WHITE, WHITE)
			k:open("win_tall", "upleft", 26, WHITE, WHITE)
			k:open("win_tall", "upright", 22, WHITE, WHITE)
			for _, x in { 8, 14 } do
				k:open("win_tall", "lfront", x, WHITE, WHITE)
			end
			k:open("win_tall", "lback", 11, WHITE, WHITE)
			k:open("win_tall", "lleft", 24, WHITE, WHITE)
			k:open("win_tall", "lleft", 32, WHITE, WHITE)
			k:open("arch_wide", "hallL", 19)
			k:open("arch_wide", "hallR", 19)
			k:open("door_panel", "lshared", 32, WHITE, GOLD)
			k:open("door_glass", "rshared", 30, WHITE, GOLD)
			k:open("door_wood", "uphallL", 18, WHITE, GOLD)
			k:open("door_wood", "uphallR", 18, WHITE, GOLD)
			k:open("door_wood", "uphallR", 34, WHITE, GOLD)

			-- the outside --------------------------------------------------------------------------
			for _, w in { "front", "back", "lfront", "lback", "lleft" } do
				k:footing(w, STONE_C, PALE)
			end
			for _, lv in { 0, 1 } do
				k:corner(18, 14, 180, lv, PALE, STONE_C)
				k:corner(46, 14, 90, lv, PALE, STONE_C)
				k:corner(46, 38, 0, lv, PALE, STONE_C)
				k:corner(18, 38, 270, lv, PALE, STONE_C)
			end
			k:corner(4, 18, 180, 0, PALE, STONE_C)
			k:corner(4, 38, 270, 0, PALE, STONE_C)
			k:dress("upback", { hood = { WHITE, ROOF.c }, box = { WHITE, ROSE } })
			k:hang("downpipe", "back", 45.3, 0, "a", ROOF.c, ROOF.c)
			k:hang("downpipe", "back", 18.7, 0, "a", ROOF.c, ROOF.c)
			-- the porch: four fluted pillars under the pediment, lanterns by the door, urns
			for _, x in { 27.2, 30.6, 33.4, 36.8 } do
				k:putY("pillar_fluted", x, 9.2, 0, F, WHITE, WHITE)
			end
			k:hang("lantern_wall", "front", 27.9, 5.8)
			k:hang("lantern_wall", "front", 36.1, 5.8)
			k:put("doormat", 32, 12.9, 0)
			k:putY("fancy_urn_plinth", 27.4, 12.4, 0, F, PALE, ROSE)
			k:putY("fancy_urn_plinth", 36.6, 12.4, 0, F, PALE, ROSE)
			-- the court: clipped trees by the path, lamps, a fountain on each lawn, flowers
			for _, x in { 26.4, 37.6 } do
				k:put("fancy_topiary", x, 4.0, 0)
				k:put("lamp_post", x, 7.0, 0)
			end
			k:put("fountain", 9, 11, 0)
			k:put("fountain", 55, 11, 0)
			for _, x in { 14, 50 } do
				k:put("bench_garden", x, 10.6, 0, WALNUT, SAGE_C)
			end
			k:put("flower_border", 21, 8.6, 0, STONE_C, ROSE)
			k:put("flower_border", 43, 8.6, 0, STONE_C, PLUM)
			k:put("topiary_spiral", 2.4, 16, 0)
			k:put("topiary_spiral", 61.6, 16, 0)
			-- behind: a terrace of flowers and a sundial on the lawn
			k:put("sundial", 32, 44, 0)
			k:put("flower_bed", 24, 41, 0, nil, ROSE)
			k:put("flower_bed", 40, 41, 0, nil, PLUM)
			k:put("bench_garden", 32, 47.6, 180, WALNUT, SAGE_C)
			k:put("statue_hare", 10, 44, 20)
			k:put("bird_bath", 54, 44, 0)

			-- the hall -----------------------------------------------------------------------------
			k:put("grand_chandelier", 32, 19.4, 0, GOLD, WHITE)
			k:putY("stairs_straight", 32, 30.8, 0, F, WALNUT, WHITE)
			k:put("fancy_rug_medallion", 32, 19.4, 90, "8A3A44", GOLD)
			k:put("clock_grandfather", 28.9, 26, 90, WALNUT)
			k:hang("fancy_mirror_gilt", "hallR", 25, 4.2, "b", GOLD)
			k:put("plant_big", 34.2, 15.9, 0)
			k:put("plant_big", 29.8, 15.9, 0)

			-- the drawing room: the fire on the back wall, the sofa facing it, the piano at the front
			k:put("fireplace", 23, 36.7, 180, "C9B8A4", WHITE)
			k:on("fancy_clock_mantel", "fireplace", 23, 36.9, 180, GOLD)
			k:put("fancy_sofa_camel", 23, 30.2, 0, PLUM, GOLD)
			k:put("fancy_table_marble", 23, 33.2, 0)
			k:put("fancy_chair_wing", 19.8, 33.4, 90, TEAL)
			k:put("fancy_chair_wing", 26.2, 33.4, 270, TEAL)
			k:put("fancy_piano_grand", 23, 20.4, 0, WALNUT)
			k:put("chandelier", 23, 26, 0, GOLD)
			k:hang("fancy_portrait", "hallL", 30, 4.4, "a")
			k:hang("fancy_curtains_swag", "front", 21, 0.4, "b", ROSE)

			-- the dining room: the long table with its chairs, the sideboard, candles
			k:put("table_dining_long", 41, 26, 90, WALNUT)
			for _, z in { 23.6, 26, 28.4 } do
				k:put("chair_dining", 38.6, z, 90, WALNUT, TEAL)
				k:put("chair_dining", 43.4, z, 270, WALNUT, TEAL)
			end
			k:on("fancy_candelabra", "table_dining_long", 41, 24.2, 90, GOLD)
			k:on("vase_flowers", "table_dining_long", 41, 27.4, 0, WHITE, ROSE)
			k:put("cozy_sideboard", 41, 37.1, 180, WALNUT)
			k:put("chandelier", 41, 26, 0, GOLD)
			k:hang("art_landscape", "hallR", 30, 5.6, "a")
			k:hang("fancy_sconce", "right", 16, 5.4, "b", GOLD)

			-- the library: tall cases round it, chairs by the fire's warmth, the desk and the globe
			k:put("bookcase_tall", 6.4, 24, 90, WALNUT)
			k:put("bookcase_tall", 6.4, 32, 90, WALNUT)
			k:put("fancy_bookcase_glass", 11, 37.1, 180, WALNUT)
			k:put("fancy_bureau", 12, 19.6, 0, WALNUT)
			k:put("cozy_wingback", 13, 28, 270, SAGE_C)
			k:put("cozy_wingback", 9.4, 28, 90, ROSE)
			k:put("cozy_side_table", 11.2, 30.6, 0, WALNUT)
			k:on("globe", "cozy_side_table", 11.2, 30.6, 0)
			k:put("cozy_reading_lamp", 15.6, 31.6, 0, GOLD)
			k:put("fancy_rug_medallion", 11, 28, 0, "4E6A5E", GOLD)
			k:put("chandelier", 11, 28, 0, GOLD)

			-- the orangery: lemon trees in tubs, a tea table and the stand of flowers
			for _, x in { 49, 57 } do
				for _, z in { 21, 35 } do
					k:put("plant_big", x, z, 0)
				end
			end
			k:put("fancy_tea_set", 53, 28, 0, WHITE, GOLD)
			k:put("chair_wood", 53, 25.2, 0, WHITE, SAGE_C)
			k:put("chair_wood", 53, 30.8, 180, WHITE, SAGE_C)
			k:put("flower_stand", 57.4, 28, 270, WHITE)
			k:put("cozy_plant_stand", 48.6, 28, 90)

			-- upstairs -----------------------------------------------------------------------------
			-- the landing over the hall
			k:up("cozy_window_seat", 32, 15.4, 0, 1, WHITE, ROSE)
			k:up("light_ceiling", 32, 20, 0, 1)
			-- the main bedroom: the crowned bed, the dressing table, the wardrobe, a chaise
			k:up("fancy_bed_crown", 23, 33.5, 180, 1, WALNUT, PLUM)
			k:up("nightstand", 19.4, 36.8, 180, 1, WALNUT)
			b:item("lamp_table", 19.4, 36.8, 180, 1, HomeKit.top("nightstand", 1))
			k:up("nightstand", 26.6, 36.8, 180, 1, WALNUT)
			b:item("lamp_table", 26.6, 36.8, 180, 1, HomeKit.top("nightstand", 1))
			k:up("fancy_dressing_table", 19.2, 22, 90, 1, WALNUT)
			k:up("wardrobe", 26.7, 22, 270, 1, WALNUT)
			k:up("fancy_chaise", 23, 16.6, 0, 1, ROSE)
			k:up("chandelier", 23, 26, 0, 1, GOLD)
			-- the guest room
			k:up("fancy_bed_sleigh", 41, 24.6, 0, 1, WALNUT, SAGE_C)
			k:up("nightstand", 37.4, 21.4, 0, 1, WALNUT)
			k:up("fancy_bureau", 44.6, 17, 270, 1, WALNUT)
			k:up("rug_round", 41, 18.6, 0, 1, "C9D6C4", WHITE)
			k:up("light_ceiling", 41, 22, 0, 1)
			-- the bathroom
			k:up("fancy_bath_slipper", 41, 34.4, 90, 1)
			k:up("fancy_washstand", 44.8, 31.6, 270, 1, WHITE)
			k:up("toilet", 37.6, 36.4, 90, 1)
			k:up("towel_rail", 37.4, 31.4, 90, 1, nil, GOLD)
			k:up("light_ceiling", 41, 34, 0, 1)
		end,
		"fancy"
	)
end
