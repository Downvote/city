--!strict
-- The town hall (fancy, for a town of level 16: its tower clock waits for that, Recipes/Grand).
-- The user: "make more vehicles, buildings that cost more for the endgame". A tall hall of pale
-- stone under a hipped slate roof, with a clock tower at its front: the big clock on the tower's
-- top storey and a tall pyramid roof over it. Through the tower's doors is the hall
-- itself, rows of seats facing a stage at the back (a musician's workplace), chandeliers, portraits
-- and a grand piano. A paved square in front with a fountain, benches and lamps.
--
-- The frame: x across, z back from the street. The hall is x 8..48 by z 18..46, the tower x 22..34
-- by z 8..18 on three storeys, the square z 0..8 in front of it all.

local HomeKit = require(script.Parent.Parent.HomeKit)

type Finish = HomeKit.Finish

local STONE: Finish = { c = "E8E0D0", m = "Limestone" }
local INSIDE: Finish = { c = "F2EBDE", m = "WoodPlanks" }
local HALL: Finish = { c = "E9DDCB", m = "WoodPlanks" }
local ROOF: Finish = { c = "5E6A78", m = "Slate" }
local PARQUET: Finish = { c = "9A6B48", m = "WoodPlanks" }
local OAK: Finish = { c = "C49A6C", m = "WoodPlanks" }
local FLAGS: Finish = { c = "BDB8AE", m = "Cobblestone" }
local PAVING: Finish = { c = "E2DCD0", m = "Pavement" }

local WHITE = "FAF6EC"
local GOLD = "D9A93F"
local WALNUT = "7E5A40"
local NAVY = "46608E"
local WINE = "8A3A44"
local STONE_C = "BDB8AE"
local PALE = "DAD4C8"
local ROSE = "D9707F"

return function(add: any)
	add(
		"grand_townhall",
		"Town hall",
		"A hall of stone for concerts and meetings, under a clock tower.",
		"clock",
		56,
		52,
		function(b: any)
			local k = HomeKit.new(b)

			-- the floors -------------------------------------------------------------------------
			b:floor(8, 18, 48, 46, PARQUET) -- the hall
			b:floor(22, 8, 34, 18, FLAGS) -- the tower's foot
			b:floor(22, 8, 34, 18, OAK, 1)
			b:floor(22, 8, 34, 18, OAK, 2)
			b:floor(0, 0, 56, 8, PAVING) -- the square
			b:floor(0, 8, 22, 12, PAVING)
			b:floor(34, 8, 56, 12, PAVING)

			-- the walls --------------------------------------------------------------------------
			k:wall("frontL", 8, 18, 22, 18, STONE, HALL)
			k:wall("frontR", 34, 18, 48, 18, STONE, HALL)
			k:wall("right", 48, 18, 48, 46, STONE, HALL)
			k:wall("back", 48, 46, 8, 46, STONE, HALL)
			k:wall("left", 8, 46, 8, 18, STONE, HALL)
			for _, lv in { 0, 1, 2 } do
				local p = "t" .. lv
				k:wall(p .. "front", 22, 8, 34, 8, STONE, INSIDE, lv)
				k:wall(p .. "right", 34, 8, 34, 18, STONE, INSIDE, lv)
				k:wall(
					p .. "back",
					34,
					18,
					22,
					18,
					if lv == 0 then INSIDE else STONE,
					if lv == 0 then HALL else INSIDE,
					lv
				)
				k:wall(p .. "left", 22, 18, 22, 8, STONE, INSIDE, lv)
			end

			-- the roofs: the hall's hipped, the tower's a tall pyramid
			b:roof(8, 18, 48, 46, "hip", 10, 0, ROOF, STONE, 0, 1)
			b:roof(22, 8, 34, 18, "pyramid", 10, 0, ROOF, STONE, 2, 1)

			-- doors and windows ----------------------------------------------------------------
			k:open("door_double", "t0front", 28, NAVY, GOLD)
			k:open("arch_wide", "t0back", 28)
			k:open("win_tall", "t1front", 28, WHITE, WHITE)
			k:open("win_tall", "t1left", 13, WHITE, WHITE)
			k:open("win_tall", "t1right", 13, WHITE, WHITE)
			k:open("win_small", "t2left", 13, WHITE, WHITE)
			k:open("win_small", "t2right", 13, WHITE, WHITE)
			for _, x in { 12, 18 } do
				k:open("win_floor", "frontL", x, WHITE, WHITE)
			end
			for _, x in { 38, 44 } do
				k:open("win_floor", "frontR", x, WHITE, WHITE)
			end
			for _, z in { 24, 30, 36, 42 } do
				k:open("win_floor", "left", z, WHITE, WHITE)
				k:open("win_floor", "right", z, WHITE, WHITE)
			end
			k:open("door_double", "back", 16, WALNUT, GOLD)

			-- the outside --------------------------------------------------------------------------
			for _, w in { "frontL", "frontR", "back", "t0left", "t0right" } do
				k:footing(w, STONE_C, PALE)
			end
			k:corner(8, 18, 180, 0, PALE, STONE_C)
			k:corner(48, 18, 90, 0, PALE, STONE_C)
			k:corner(48, 46, 0, 0, PALE, STONE_C)
			k:corner(8, 46, 270, 0, PALE, STONE_C)
			for _, lv in { 0, 1, 2 } do
				k:corner(22, 8, 180, lv, PALE, STONE_C)
				k:corner(34, 8, 90, lv, PALE, STONE_C)
			end
			-- the clock on the tower's top storey, looking down the square
			k:hang("grand_tower_clock", "t2front", 28, 1.6, "a", WHITE, NAVY)
			k:hang("lantern_wall", "t0front", 23.6, 5.8)
			k:hang("lantern_wall", "t0front", 32.4, 5.8)
			k:hang("downpipe", "back", 47.3, 0, "a", ROOF.c, ROOF.c)
			k:hang("downpipe", "back", 8.7, 0, "a", ROOF.c, ROOF.c)
			-- the square: the fountain, benches round it, lamps and flowers
			k:put("fountain", 28, 3.6, 0)
			k:put("bench_garden", 21, 3.6, 90, WALNUT, NAVY)
			k:put("bench_garden", 35, 3.6, 270, WALNUT, NAVY)
			for _, x in { 4, 16, 40, 52 } do
				k:put("lamp_post", x, 1.2, 0)
			end
			for _, x in { 10, 46 } do
				k:put("flower_border", x, 10.4, 0, STONE_C, ROSE)
			end
			k:put("postbox", 3.2, 10, 90)
			k:put("bicycle", 53, 9.6, 90)
			-- the garden behind
			for _, x in { 26, 34, 42 } do
				k:put("flower_bed", x, 48.6, 0, nil, ROSE)
			end
			k:put("bench_garden", 6, 49.4, 180, WALNUT, NAVY)

			-- the tower ------------------------------------------------------------------------------
			k:put("clock_grandfather", 23.1, 15, 90, WALNUT)
			k:put("fancy_rug_medallion", 28, 12.6, 90, WINE, GOLD)
			k:put("light_ceiling", 28, 13, 0)
			k:up("bench_wood", 25, 12.6, 90, 1, WALNUT)
			k:up("light_ceiling", 28, 13, 0, 1)
			k:up("light_ceiling", 28, 13, 0, 2)

			-- the hall: rows of seats facing the stage, the piano beside it, chandeliers --------------
			k:put("work_stage", 28, 41.4, 180, WINE, GOLD)
			k:put("stage_curtain", 28, 45.1, 180, WINE)
			k:put("fancy_piano_grand", 39.6, 40.4, 200, WALNUT)
			for _, z in { 23.6, 27, 30.4, 33.8 } do
				for _, x in { 13.4, 20.4, 35.6, 42.6 } do
					k:put("seat_row", x, z, 0, WINE)
				end
			end
			for _, z in { 24, 34 } do
				k:put("chandelier", 20.4, z, 0, GOLD)
				k:put("chandelier", 35.6, z, 0, GOLD)
			end
			k:put("rug_long", 28, 28, 0, WINE)
			for _, z in { 27, 33, 39 } do
				k:hang("fancy_sconce", "left", z, 6.2, "b", GOLD)
				k:hang("fancy_sconce", "right", z, 6.2, "b", GOLD)
			end
			k:hang("fancy_portrait", "back", 11, 5.0, "b")
			k:hang("fancy_portrait", "back", 45, 5.0, "b")
			k:put("plant_big", 10.4, 43.6, 0)
			k:put("plant_big", 45.6, 43.6, 0)
			k:put("fancy_urn_plinth", 10.2, 20.2, 0, PALE, ROSE)
			k:put("fancy_urn_plinth", 45.8, 20.2, 0, PALE, ROSE)
			k:put("clock_grandfather", 9.1, 36, 90, WALNUT)
			k:put("coat_stand", 46.6, 22.4, 0, WALNUT)
		end,
		"fancy"
	)
end
