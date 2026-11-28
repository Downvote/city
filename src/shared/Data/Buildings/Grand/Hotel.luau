--!strict
-- The grand hotel (fancy, for a town of level 14: its front desk waits for that, Recipes/Grand).
-- The user: "make more vehicles, buildings that cost more for the endgame". Three storeys of soft
-- brick with stone at the corners under a flat roof with a parapet. A canopy over the double doors
-- leads into the lobby: the front desk across the back with the key cupboard behind it, a cafe in
-- one corner (a barista's workplace), sofas round a rug in the other, and the stair up. Upstairs,
-- four guest rooms on each floor along a corridor.
--
-- The frame: x across, z back from the street. The hotel is x 6..54 and z 10..36 on every storey.

local HomeKit = require(script.Parent.Parent.HomeKit)

type Finish = HomeKit.Finish

local F = HomeKit.F

local BRICK: Finish = { c = "D8A893", m = "Brick" }
local INSIDE: Finish = { c = "F2EBDE", m = "WoodPlanks" }
local ROOM: Finish = { c = "E8E0EC", m = "WoodPlanks" }
local LOBBY: Finish = { c = "EDE2CC", m = "WoodPlanks" }
local ROOF: Finish = { c = "8C8A86", m = "Slate" }
local MARBLE: Finish = { c = "E6E0D6", m = "Marble" }
local CHECK: Finish = { c = "DCD4C6", m = "Marble" }
local CARPET: Finish = { c = "9A5A64", m = "Carpet" }
local CORRIDOR: Finish = { c = "6E7E9A", m = "Carpet" }
local PAVING: Finish = { c = "E2DCD0", m = "Pavement" }
local RAIL: Finish = { c = "3A3A40", m = "Metal" }

local WHITE = "FAF6EC"
local GOLD = "D9A93F"
local WALNUT = "7E5A40"
local GREEN = "2F6B5E"
local WINE = "8A3A44"
local NAVY = "46608E"
local STONE_C = "D6CCB8"
local PALE = "E6DED0"

-- A guest room on level `lv` between x1 and x2, its door on the corridor side (z 24): a double
-- bed against the outside wall, a nightstand and lamp each side, a wardrobe and an armchair along
-- the side wall, and a light.
local function room(k: any, b: any, x1: number, x2: number, lv: number, paint: string)
	local mx = (x1 + x2) / 2
	k:up("bed_double", mx, 14.6, 0, lv, WALNUT, paint)
	for _, sx in { -1, 1 } do
		k:up("nightstand", mx + sx * 4.2, 11.4, 0, lv, WALNUT)
		b:item("lamp_table", mx + sx * 4.2, 11.4, 0, lv, HomeKit.top("nightstand", lv))
	end
	k:up("wardrobe", x1 + 1.4, 15, 90, lv, WALNUT)
	k:up("armchair", x1 + 2.2, 20.6, 90, lv, paint)
	k:up("light_ceiling", mx, 16, 0, lv)
end

return function(add: any)
	add(
		"grand_hotel",
		"Grand hotel",
		"Three storeys of guest rooms over a lobby with a front desk and a cafe.",
		"bed",
		60,
		44,
		function(b: any)
			local k = HomeKit.new(b)

			-- the floors -------------------------------------------------------------------------
			b:floor(6, 10, 54, 36, CHECK) -- the lobby
			for _, lv in { 1, 2 } do
				b:floor(6, 10, 54, 24, CARPET, lv) -- the rooms
				b:floor(6, 24, 54, 36, CORRIDOR, lv)
			end
			b:floor(22, 2, 38, 10, MARBLE) -- under the canopy
			b:floor(26, 0, 34, 2, PAVING)
			b:floor(2, 0, 22, 6, PAVING)
			b:floor(38, 0, 58, 6, PAVING)

			-- the walls --------------------------------------------------------------------------
			for _, lv in { 0, 1, 2 } do
				local p = if lv == 0 then "" else "l" .. lv
				k:wall(p .. "front", 6, 10, 54, 10, BRICK, if lv == 0 then LOBBY else ROOM, lv)
				k:wall(p .. "right", 54, 10, 54, 36, BRICK, if lv == 0 then LOBBY else INSIDE, lv)
				k:wall(p .. "back", 54, 36, 6, 36, BRICK, if lv == 0 then LOBBY else INSIDE, lv)
				k:wall(p .. "left", 6, 36, 6, 10, BRICK, if lv == 0 then LOBBY else INSIDE, lv)
			end
			for _, lv in { 1, 2 } do
				local p = "l" .. lv
				k:wall(p .. "hall", 54, 24, 6, 24, INSIDE, ROOM, lv)
				for i, x in { 18, 30, 42 } do
					k:wall(p .. "split" .. i, x, 10, x, 24, ROOM, ROOM, lv)
				end
				-- rails along the stairwell
				k:wall(p .. "railA", 40, 26, 52, 26, RAIL, RAIL, lv, "railing")
				k:wall(p .. "railB", 52, 34, 40, 34, RAIL, RAIL, lv, "railing")
			end

			-- the roof: flat over the top storey
			b:roof(6, 10, 54, 36, "flat", 1, 0, ROOF, BRICK, 2, 0.6)

			-- doors and windows ----------------------------------------------------------------
			k:open("door_double", "front", 30, GREEN, GOLD)
			for _, x in { 11, 18, 42, 49 } do
				k:open("win_tall", "front", x, WHITE, WHITE)
			end
			for _, lv in { 1, 2 } do
				local p = "l" .. lv
				for _, x in { 9, 15, 21, 27, 33, 39, 45, 51 } do
					k:open("win_tall", p .. "front", x, WHITE, WHITE)
				end
				for _, x in { 12, 24, 36, 48 } do
					k:open("door_panel", p .. "hall", x + 2.4, WHITE, GOLD)
				end
				k:open("win_square", p .. "left", 30, WHITE, WHITE)
				k:open("win_square", p .. "right", 30, WHITE, WHITE)
				k:open("win_square", p .. "back", 20, WHITE, WHITE)
				k:open("win_square", p .. "back", 34, WHITE, WHITE)
			end
			k:open("win_tall", "left", 20, WHITE, WHITE)
			k:open("win_tall", "left", 28, WHITE, WHITE)
			k:open("win_tall", "right", 20, WHITE, WHITE)
			k:open("door_glass", "back", 16, WHITE, GOLD)

			-- the outside --------------------------------------------------------------------------
			-- (along the front, stopping either side of the canopy)
			k:footing("front", STONE_C, PALE, 0, 19.5)
			k:footing("front", STONE_C, PALE, 28.5, 48)
			k:footing("back", STONE_C, PALE)
			for _, lv in { 0, 1, 2 } do
				k:corner(6, 10, 180, lv, PALE, STONE_C)
				k:corner(54, 10, 90, lv, PALE, STONE_C)
				k:corner(54, 36, 0, lv, PALE, STONE_C)
				k:corner(6, 36, 270, lv, PALE, STONE_C)
			end
			k:dress("l1back", { hood = { WHITE, ROOF.c }, box = { WHITE, WINE } })
			k:dress("l2back", { hood = { WHITE, ROOF.c } })
			k:hang("downpipe", "back", 53.3, 0, "a", ROOF.c, ROOF.c)
			k:hang("downpipe", "back", 6.7, 0, "a", ROOF.c, ROOF.c)
			-- the way in: the canopy over the doors, lamps and bay trees in tubs either side
			k:putY("canopy_door", 30, 7.6, 0, F, WINE, GOLD)
			k:hang("lantern_wall", "front", 25.6, 5.8)
			k:hang("lantern_wall", "front", 34.4, 5.8)
			for _, x in { 23.4, 36.6 } do
				k:putY("fancy_topiary", x, 3.6, 0, F)
				k:put("lamp_post", x, 0.8, 0)
			end
			k:put("doormat", 30, 9.2, 0)
			for _, x in { 8, 14, 46, 52 } do
				k:put("planter_box", x, 7.6, 0)
			end
			k:put("bench_garden", 11, 3.4, 0, WALNUT, GREEN)
			k:put("bench_garden", 49, 3.4, 0, WALNUT, GREEN)
			k:put("bicycle", 57.2, 20, 90)
			-- the yard behind: a terrace of tables
			for _, x in { 22, 34 } do
				k:put("bistro_set", x, 40, 0, WHITE, GREEN)
			end
			k:put("umbrella_sun", 28, 40.4, 0, WINE)
			k:put("flower_bed", 44, 40, 0, nil, WINE)

			-- the lobby ------------------------------------------------------------------------------
			-- the front desk across the back, its cupboard of keys behind it
			k:put("grand_front_desk", 30, 32.4, 180, WALNUT, GREEN)
			k:put("fancy_rug_medallion", 30, 20, 0, WINE, GOLD)
			k:put("chandelier", 30, 18, 0, GOLD)
			k:put("chandelier", 30, 28, 0, GOLD)
			k:hang("fancy_mirror_gilt", "back", 22, 4.2, "b", GOLD)
			k:hang("fancy_mirror_gilt", "back", 38, 4.2, "b", GOLD)
			k:put("plant_big", 23.4, 12, 0)
			k:put("plant_big", 36.6, 12, 0)
			k:put("coat_stand", 21.6, 34.6, 0, WALNUT)
			-- the cafe in the left corner
			k:put("work_cafe", 12, 33.6, 180, WALNUT, WHITE)
			for _, p in { { 10, 16 }, { 16, 22 }, { 10, 24 } } do
				k:put("bistro_set", p[1], p[2], 0, WHITE, GREEN)
			end
			k:put("menu_board", 18.6, 31.4, 0, GREEN)
			k:put("lamp_pendant", 12, 20, 0, GOLD)
			k:hang("art_flowers", "left", 16, 5.6, "b")
			-- the lounge in the right corner, and the stair up behind it
			k:put("fancy_sofa_camel", 44, 14.2, 0, NAVY, GOLD)
			k:put("fancy_chair_wing", 39.8, 18, 90, WINE)
			k:put("fancy_chair_wing", 48.2, 18, 270, WINE)
			k:put("fancy_table_marble", 44, 18, 0)
			k:on("vase_flowers", "fancy_table_marble", 44, 18, 0, WHITE, WINE)
			k:put("cozy_rug_patch", 44, 18, 0, "B8A0B4")
			k:put("lamp_floor", 50.4, 13.2, 0, GOLD)
			k:putY("stairs_wide", 46, 30, 90, F, WALNUT, WHITE)
			k:hang("fancy_portrait", "right", 16, 4.6, "b")

			-- upstairs: four rooms on each floor, a sofa and a plant along the corridor ------------
			for _, lv in { 1, 2 } do
				room(k, b, 6, 18, lv, if lv == 1 then WINE else NAVY)
				room(k, b, 18, 30, lv, if lv == 1 then GREEN else WINE)
				room(k, b, 30, 42, lv, if lv == 1 then NAVY else GREEN)
				room(k, b, 42, 54, lv, if lv == 1 then WINE else NAVY)
				k:up("sofa_two", 14, 34.2, 180, lv, NAVY)
				k:up("plant_big", 8.4, 33.6, 0, lv)
				k:up("plant_big", 36, 33.6, 0, lv)
				for _, x in { 12, 26, 40 } do
					k:up("light_ceiling", x, 30, 0, lv)
				end
			end
		end,
		"fancy"
	)
end
