--!strict
-- The grand townhouse (fancy): two storeys of pale limestone under a slate hipped roof, a bay
-- window either side of a porch on two round pillars under a pediment, a chimney up the end
-- wall. A hall runs through the middle with the stair along one side of it. Downstairs the
-- drawing room (the fire, the sofa facing it, the piano at the back) and the kitchen with the
-- dining table in the bay; upstairs a canopy bed in the main bedroom, the bathroom behind it and
-- a second bedroom across the landing. Clipped hedges along the street, a blossom tree behind.
--
-- The frame: x across, z back from the street (z = 0). The house is x 4..34 and z 12..36 on both
-- storeys, the hall x 14..24 through the middle of it, the porch x 14..24 and z 6..12.

local HomeKit = require(script.Parent.Parent.HomeKit)

type Finish = HomeKit.Finish

local F = HomeKit.F

-- finishes
local LIMESTONE: Finish = { c = "EDE6DA", m = "Limestone" }
local INSIDE: Finish = { c = "F4EEE2", m = "Plaster" }
local BLUSH: Finish = { c = "EBDCD0", m = "Plaster" } -- the drawing room
local SAGE_WALL: Finish = { c = "E2E8DC", m = "Plaster" } -- the kitchen
local BATH: Finish = { c = "E6EEEC", m = "SmoothPlastic" }
local ROOF: Finish = { c = "5E6A78", m = "Slate" }
local PEDIMENT: Finish = { c = "E8E0D0", m = "Marble" }
local PARQUET: Finish = { c = "9A6B48", m = "WoodPlanks" }
local OAK: Finish = { c = "C49A6C", m = "WoodPlanks" }
local MARBLE: Finish = { c = "E4DED4", m = "Marble" }
local KITCHEN_TILES: Finish = { c = "E2DACB", m = "CeramicTiles" }
local PLUM_CARPET: Finish = { c = "8A7A9C", m = "Carpet" }
local BATH_TILES: Finish = { c = "DCE4E4", m = "CeramicTiles" }
local PAVING: Finish = { c = "E2DCD0", m = "Pavement" }
local HEDGE: Finish = { c = "6E9A66", m = "Grass" }
local RAIL: Finish = { c = "7E5A40", m = "Wood" }
-- paint for the pieces
local TEAL = "2E6B67" -- the front door
local GOLD = "D9A93F"
local WHITE = "FAF6EC"
local PLUM = "7A5A78"
local WALNUT = "7E5A40"
local ROSE = "D9707F"
local STONE = "BDB8AE"
local PALE = "DAD4C8"
local SAGE = "86A886"

return function(add: any)
	add(
		"home_grand_townhouse",
		"Grand townhouse",
		"Two storeys of pale stone with bay windows, a pillared porch and a piano in the drawing room.",
		"hall",
		40,
		44,
		function(b: any)
			local k = HomeKit.new(b)

			-- the floors -------------------------------------------------------------------------
			b:floor(4, 12, 14, 36, PARQUET) -- the drawing room
			b:floor(14, 12, 24, 36, MARBLE) -- the hall
			b:floor(24, 12, 34, 36, KITCHEN_TILES) -- the kitchen and dining room
			b:floor(4, 12, 14, 28, PLUM_CARPET, 1) -- the main bedroom
			b:floor(4, 28, 14, 36, BATH_TILES, 1)
			b:floor(14, 12, 24, 36, OAK, 1) -- the landing
			b:floor(24, 12, 34, 36, OAK, 1) -- the second bedroom
			b:floor(14, 6, 24, 12, MARBLE) -- the porch
			b:floor(16, 0, 22, 4, PAVING) -- the path

			-- the walls, both storeys --------------------------------------------------------------
			k:wall("front", 4, 12, 34, 12, LIMESTONE, INSIDE)
			k:wall("right", 34, 12, 34, 36, LIMESTONE, SAGE_WALL)
			k:wall("back", 34, 36, 4, 36, LIMESTONE, INSIDE)
			k:wall("left", 4, 36, 4, 12, LIMESTONE, BLUSH)
			k:wall("hallL", 14, 12, 14, 36, INSIDE, BLUSH)
			k:wall("hallR", 24, 12, 24, 36, SAGE_WALL, INSIDE)
			k:wall("upfront", 4, 12, 34, 12, LIMESTONE, INSIDE, 1)
			k:wall("upright", 34, 12, 34, 36, LIMESTONE, INSIDE, 1)
			k:wall("upback", 34, 36, 4, 36, LIMESTONE, INSIDE, 1)
			k:wall("upleft", 4, 36, 4, 12, LIMESTONE, INSIDE, 1)
			k:wall("uphallL", 14, 12, 14, 36, INSIDE, INSIDE, 1)
			k:wall("uphallR", 24, 12, 24, 36, INSIDE, INSIDE, 1)
			k:wall("upsplit", 4, 28, 14, 28, INSIDE, BATH, 1)
			-- the rail along the stairwell, round to the bookshelf at its back end
			k:wall("rail", 18, 18, 18, 32, RAIL, RAIL, 1, "railing")
			k:wall("railback", 18, 32, 20, 32, RAIL, RAIL, 1, "railing")
			-- clipped hedges along the street, the path between them
			k:wall("hedgeL", 2, 2, 14, 2, HEDGE, HEDGE, 0, "hedge")
			k:wall("hedgeR", 24, 2, 38, 2, HEDGE, HEDGE, 0, "hedge")

			-- the roofs: hipped slate over the house, a pediment over the porch that dies into the
			-- upper wall
			b:roof(4, 12, 34, 36, "hip", 8, 0, ROOF, LIMESTONE, 1, 1)
			b:roof(14, 6, 24, 12, "gable", 4, 1, ROOF, PEDIMENT, 0, 0.3)

			-- doors and windows ------------------------------------------------------------------
			k:open("door_double", "front", 19, TEAL, WHITE)
			k:open("win_bay", "front", 9, WHITE, ROOF.c)
			k:open("win_bay", "front", 29, WHITE, ROOF.c)
			k:open("win_square", "upfront", 9, WHITE, WHITE)
			k:open("win_tall", "upfront", 19, WHITE, WHITE)
			k:open("win_square", "upfront", 29, WHITE, WHITE)
			k:open("win_tall", "left", 14.6, WHITE, WHITE)
			k:open("win_tall", "left", 31, WHITE, WHITE)
			k:open("win_tall", "right", 26, WHITE, WHITE)
			k:open("win_square", "back", 26.55, WHITE, WHITE)
			k:open("door_wood", "back", 16.9, TEAL, WHITE)
			k:open("win_square", "upback", 9, WHITE, WHITE)
			k:open("win_square", "upback", 29, WHITE, WHITE)
			k:open("arch_open", "hallL", 28.5)
			k:open("arch_open", "hallR", 15)
			k:open("door_panel", "uphallL", 15, WHITE, GOLD)
			k:open("door_panel", "uphallL", 33.3, WHITE, GOLD)
			k:open("door_panel", "uphallR", 15, WHITE, GOLD)

			-- the outside --------------------------------------------------------------------------
			for _, w in { "front", "right", "back", "left" } do
				k:footing(w, STONE, PALE)
			end
			for _, lv in { 0, 1 } do
				k:corner(4, 12, 180, lv, PALE, STONE)
				k:corner(34, 12, 90, lv, PALE, STONE)
				k:corner(34, 36, 0, lv, PALE, STONE)
				k:corner(4, 36, 270, lv, PALE, STONE)
			end
			k:dress("upfront", { hood = { WHITE, ROOF.c }, box = { WHITE, ROSE } })
			k:dress("upback", { hood = { WHITE, ROOF.c }, box = { WHITE, GOLD } })
			k:dress("back", { hood = { WHITE, ROOF.c }, box = { WHITE, PLUM } })
			k:putY("chimney", 2.15, 22, 90, 0, "C9B8A4", "68686E")
			k:hang("downpipe", "back", 33.3, 0, "a", ROOF.c, ROOF.c)
			-- the porch: two round pillars under the pediment, lanterns either side of the door
			k:putY("pillar_round", 15.2, 7.4, 0, F, WHITE, WHITE)
			k:putY("pillar_round", 22.8, 7.4, 0, F, WHITE, WHITE)
			k:putY("doorstep", 19, 4.8, 180, 0, PALE, STONE)
			k:hang("lantern_wall", "front", 14.9, 5.8)
			k:hang("lantern_wall", "front", 23.1, 5.8)
			k:putY("flower_pot", 15.4, 10.6, 0, F, nil, ROSE)
			k:putY("flower_pot", 22.6, 10.6, 0, F, nil, ROSE)
			k:put("doormat", 19, 10.9, 0)
			-- the front garden: a lamp at the gap in the hedge, clipped bushes under the bays
			k:put("lamp_post", 15.6, 2.4, 0)
			for _, x in { 3.6, 31.6 } do
				k:put("bush", x, 6.6, 0)
			end
			k:put("flower_border", 9, 5.0, 0, STONE, ROSE)
			k:put("flower_border", 29, 5.0, 0, STONE, PLUM)
			k:put("planter_box", 11.4, 9.4, 0, STONE, GOLD)
			k:put("planter_box", 26.6, 9.4, 0, STONE, GOLD)
			-- the garden behind: stones from the back door to a bench under the blossom
			k:put("path_stones", 16.9, 37.6, 0)
			k:put("path_stones", 17.4, 39.8, 20)
			k:put("bench_garden", 22.0, 42.4, 180, WALNUT, SAGE)
			k:put("tree_blossom", 30.4, 40.2, 0)
			k:put("flower_bed", 9.0, 38.4, 0, nil, ROSE)
			k:put("flower_bed", 13.4, 41.8, 0, nil, PLUM)

			-- downstairs ---------------------------------------------------------------------------
			-- the hall: the stair up its right side, a way past it on the left
			k:putY("stairs_straight", 21.6, 25, 0, F, WALNUT, WHITE)
			k:put("lamp_pendant", 19, 15, 0, GOLD)
			k:hang("mirror_wall", "hallL", 17, 4.6, "a")
			k:hang("art_landscape", "hallL", 22.5, 6.4, "a")
			k:put("plant_big", 15.9, 16.4, 0)

			-- the drawing room: the fire on the end wall with the sofa facing it, an armchair in
			-- the bay, the piano at the back by the books
			k:put("fireplace", 5.55, 21, 90, "C9B8A4", WHITE)
			k:put("sofa_three", 11.9, 21, 270, PLUM, GOLD)
			k:put("rug_round", 8.6, 21, 0, "B8A0B4", GOLD)
			k:put("table_coffee", 8.5, 21, 90, WALNUT, GOLD)
			k:on("candles", "table_coffee", 8.5, 20.2, 0)
			k:on("books_stack", "table_coffee", 8.6, 21.8, 15)
			k:put("armchair", 9, 14.6, 0, TEAL)
			k:put("lamp_floor", 12.8, 13.3, 0, GOLD)
			k:put("piano", 9, 33.65, 180, WALNUT)
			k:put("stool", 9, 30.4, 0, WALNUT, PLUM)
			k:put("bookshelf", 5.15, 28, 90, WALNUT)
			k:put("chandelier", 8.6, 21, 0, GOLD)
			k:hang("art_flowers", "hallL", 21, 6.6, "b")

			-- the kitchen: the table in the bay, the counters along the back
			k:put("table_dining_long", 29, 20.5, 0, WALNUT)
			k:on("vase_flowers", "table_dining_long", 29, 20.5, 0, WHITE, ROSE)
			for _, x in { 27, 31 } do
				k:put("chair_dining", x, 17.4, 0, WALNUT, TEAL)
				k:put("chair_dining", x, 23.6, 180, WALNUT, TEAL)
			end
			k:put("lamp_pendant", 27, 20.5, 0, GOLD)
			k:put("lamp_pendant", 31, 20.5, 0, GOLD)
			k:put("counter_corner", 32.35, 34.35, 180, WHITE, PALE)
			k:put("stove", 29.55, 34.35, 180, WHITE, PALE)
			k:put("counter_sink", 26.55, 34.35, 180, WHITE, PALE)
			k:on("kettle", "stove", 29.2, 34.3, 160, TEAL)
			k:on("toaster", "counter_corner", 32.3, 34.5, 180, WHITE)
			k:put("fridge", 32.35, 29.5, 270, WHITE)
			k:hang("shelf_wall", "back", 31.0, 7.4, "b", WALNUT)
			k:hang("clock_wall", "hallR", 26.5, 7.6, "a", TEAL)

			-- upstairs -----------------------------------------------------------------------------
			-- the landing: a bench under the front window, a bookshelf closing off the stairwell
			k:up("bench_wood", 19, 13.4, 0, 1, WALNUT)
			k:up("bookshelf", 21.8, 32.85, 180, 1, WALNUT)
			k:up("light_ceiling", 16, 25, 0, 1)

			-- the main bedroom: the canopy bed's head to the end wall
			k:up("bed_canopy", 8.25, 20, 90, 1, WALNUT, PLUM)
			k:up("nightstand", 5.25, 15.75, 90, 1, WALNUT)
			b:item("lamp_table", 5.25, 15.75, 90, 1, HomeKit.top("nightstand", 1))
			k:up("nightstand", 5.25, 24.25, 90, 1, WALNUT)
			b:item("lamp_table", 5.25, 24.25, 90, 1, HomeKit.top("nightstand", 1))
			k:up("wardrobe", 12.55, 25.6, 270, 1, WALNUT)
			k:hang("mirror_wall", "upsplit", 8.5, 4.8, "a")
			k:up("light_ceiling", 9, 20, 0, 1)

			-- the bathroom
			k:up("bathtub", 8.0, 33.95, 90, 1)
			k:up("toilet", 6.0, 29.75, 0, 1)
			k:up("sink_vanity", 10.0, 29.35, 0, 1, WHITE)
			k:hang("mirror_wall", "upsplit", 10.0, 4.8, "b")
			k:up("towel_rail", 13.15, 29.5, 270, 1, nil, GOLD)
			k:up("light_ceiling", 9, 32, 0, 1)

			-- the second bedroom
			k:up("bed_double", 29.85, 26, 270, 1, WALNUT, SAGE)
			k:up("nightstand", 32.75, 21.95, 270, 1, WALNUT)
			b:item("lamp_table", 32.75, 21.95, 0, 1, HomeKit.top("nightstand", 1))
			k:up("nightstand", 32.75, 30.05, 270, 1, WALNUT)
			b:item("lamp_table", 32.75, 30.05, 0, 1, HomeKit.top("nightstand", 1))
			k:up("desk", 28, 34.45, 180, 1, WALNUT)
			k:up("chair_wood", 28, 32.2, 0, 1, WALNUT, SAGE)
			b:item("books_stack", 29.2, 34.6, 10, 1, HomeKit.top("desk", 1))
			k:up("armchair", 29.5, 14.6, 0, 1, ROSE)
			k:up("lamp_floor", 32.8, 13.3, 0, 1, GOLD)
			k:up("rug_round", 29.5, 18.8, 0, 1, "C9D6C4", WHITE)
			k:up("light_ceiling", 29, 22, 0, 1)
		end,
		"fancy"
	)
end
