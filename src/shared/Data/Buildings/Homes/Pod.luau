--!strict
-- The pod house (sci-fi): a white eight sided pod under a pointed metal roof with an aerial on
-- top, round windows all the way round and a glass entry tube at the front. Inside, the front
-- half is one room (screens, a fish tank and an arcade cabinet on the left, a round table in the
-- middle, the kitchen with its island on the right) and the back half is the bedroom with a
-- computer desk and a big bathroom. Out to the side is a landing pad ringed with light, a ring
-- standing in the middle of it.
--
-- The frame: x across, z back from the street (z = 0). The pod is the square x 4..36, z 8..40
-- with its corners cut off eight studs, the entry tube x 16..24 and z 2..8 in front of it, the pad
-- x 38..48 and z 10..22.

local HomeKit = require(script.Parent.Parent.HomeKit)

type Finish = HomeKit.Finish

local F = HomeKit.F

-- finishes
local SHELL: Finish = { c = "F2F4F6", m = "SmoothPlastic" } -- the white pod
local INSIDE: Finish = { c = "EEF2F4", m = "SmoothPlastic" }
local BATH: Finish = { c = "DCEAEE", m = "SmoothPlastic" }
local ROOF: Finish = { c = "B4BEC8", m = "Metal" }
local TUBE: Finish = { c = "C8D2DA", m = "Metal" } -- the entry tube's frames
local FLOOR: Finish = { c = "D0D6DC", m = "Concrete" }
local BED_FLOOR: Finish = { c = "A8B4C8", m = "Carpet" }
local BATH_TILES: Finish = { c = "D6E4EA", m = "CeramicTiles" }
local PLATE: Finish = { c = "B8BEC4", m = "DiamondPlate" }
local PAD: Finish = { c = "C8CCD0", m = "Concrete" }
local GLOW: Finish = { c = "9FD8E0", m = "Neon" }
-- paint for the pieces
local CYAN = "6CC4CC"
local CYAN_DARK = "3F8C96"
local WHITE = "F2F4F6"
local SILVER = "B4BEC8"
local CHARCOAL = "4A4E56"
local CORAL = "F28C6A"

-- the length of a wall from one corner to the next
local DIAG = math.sqrt(8 * 8 * 2)

return function(add: any)
	add(
		"home_pod",
		"Pod house",
		"A round white pod with portholes, a glass way in and a landing pad beside it.",
		"moon",
		48,
		42,
		function(b: any)
			local k = HomeKit.new(b)

			-- the floors -------------------------------------------------------------------------
			-- (square floors under the cut corners stay outside the walls, as a step round the pod)
			b:floor(4, 8, 36, 26, FLOOR)
			b:floor(4, 26, 22, 40, BED_FLOOR)
			b:floor(22, 26, 36, 40, BATH_TILES)
			b:floor(16, 2, 24, 8, PLATE) -- the entry tube
			b:floor(18, 0, 22, 2, PAD) -- the path in, between two strips of light
			b:floor(16, 0, 18, 2, GLOW)
			b:floor(22, 0, 24, 2, GLOW)
			-- the landing pad: a ring of light round a plain middle
			b:floor(38, 10, 48, 12, GLOW)
			b:floor(38, 20, 48, 22, GLOW)
			b:floor(38, 12, 40, 20, GLOW)
			b:floor(46, 12, 48, 20, GLOW)
			b:floor(40, 12, 46, 20, PAD)

			-- the walls: the eight sides clockwise from the front, then the two inside ------------
			k:wall("front", 12, 8, 28, 8, SHELL, INSIDE)
			k:wall("fr", 28, 8, 36, 16, SHELL, INSIDE)
			k:wall("right", 36, 16, 36, 32, SHELL, INSIDE)
			k:wall("br", 36, 32, 28, 40, SHELL, BATH)
			k:wall("back", 28, 40, 12, 40, SHELL, INSIDE)
			k:wall("bl", 12, 40, 4, 32, SHELL, INSIDE)
			k:wall("left", 4, 32, 4, 16, SHELL, INSIDE)
			k:wall("fl", 4, 16, 12, 8, SHELL, INSIDE)
			k:wall("mid", 4, 26, 36, 26, INSIDE, INSIDE)
			k:wall("bathwall", 22, 26, 22, 40, BATH, INSIDE)
			-- the entry tube: glass sides, a plain front for the door
			k:wall("tubeL", 16, 8, 16, 2, TUBE, TUBE, 0, "glass")
			k:wall("tubeF", 16, 2, 24, 2, SHELL, INSIDE)
			k:wall("tubeR", 24, 2, 24, 8, TUBE, TUBE, 0, "glass")

			-- the roof: a point over the whole pod, and a flat lid on the tube
			b:roof(4, 8, 36, 40, "pyramid", 6, 0, ROOF, ROOF, 0, 0.8)
			b:roof(16, 2, 24, 8, "flat", 0, 0, ROOF, TUBE, 0, 0.2)

			-- doors and windows: round windows on every side but the front --------------------------
			k:open("door_glass", "front", 20, CYAN, CYAN)
			k:open("door_glass", "tubeF", 20, CYAN, CYAN)
			for _, w in { "fr", "fl", "br", "bl" } do
				k:openT("win_porthole", w, DIAG / 2, WHITE, CYAN)
			end
			k:open("win_porthole", "front", 13.8, WHITE, CYAN)
			k:open("win_porthole", "front", 26.2, WHITE, CYAN)
			k:open("win_porthole", "right", 29.6, WHITE, CYAN)
			k:open("win_porthole", "left", 18.4, WHITE, CYAN)
			k:open("win_porthole", "back", 20, WHITE, CYAN)
			k:open("door_glass", "mid", 17, CYAN, CYAN)
			k:open("door_glass", "mid", 25, CYAN, CYAN)

			-- the outside ----------------------------------------------------------------------------
			-- the aerial on the point, lamps by the door, the pad's ring and some rocks and pines
			k:up("weathervane", 20, 24, 0, 1, SILVER, CYAN)
			k:hang("sconce", "tubeF", 17.2, 6.4, "a", CYAN)
			k:hang("sconce", "tubeF", 22.8, 6.4, "a", CYAN)
			k:hang("sconce", "right", 25.4, 6.4, "a", CYAN)
			k:hang("sconce", "left", 24.4, 6.4, "a", CYAN)
			k:putY("sculpture_ring", 43, 16, 90, F, SILVER, CYAN)
			k:put("lamp_post", 13.0, 1.4, 0, SILVER)
			k:put("lamp_post", 27.0, 1.4, 0, SILVER)
			k:put("rock", 8.4, 4.4, 30)
			k:put("rock", 31.8, 4.0, 160)
			k:put("bush", 11.2, 3.6, 0)
			k:put("bush", 28.6, 4.2, 0)
			k:put("tree_pine", 3.0, 4.0, 0)
			k:put("tree_pine", 42.8, 34.6, 0)
			k:put("tree_pine", 3.4, 38.4, 0)
			k:put("rock", 40.6, 26.4, 80)
			k:put("planter_box", 43, 8.6, 0, WHITE, CYAN)
			k:put("planter_box", 43, 23.4, 0, WHITE, CORAL)
			for _, z in { 12, 16, 20 } do
				k:put("path_stones", 37.2, z + 0.4, z * 7 % 30)
			end

			-- the front room -----------------------------------------------------------------------
			-- screens on the left wall with the sofa facing them, the fish tank and the arcade
			-- cabinet in the corners, a round table in the middle, the kitchen on the right
			k:hang("tv_wall", "left", 21, 4.2, "b")
			k:put("sofa_three", 11.6, 21, 270, CHARCOAL, CYAN)
			k:put("rug_round", 7.6, 21, 0, "A8B4C8", CYAN)
			k:put("table_coffee", 7.6, 21, 90, WHITE, SILVER)
			k:on("plant_small", "table_coffee", 7.5, 20.2, 0)
			k:put("aquarium", 6.6, 24.75, 180, WHITE, CYAN)
			k:put("arcade", 9.3, 13.3, 45, CYAN, CHARCOAL)
			k:put("beanbag", 14.2, 12.6, 0, CORAL)
			k:put("table_round", 20, 18, 0, WHITE, SILVER)
			k:on("vase_flowers", "table_round", 20, 18, 0, WHITE, CORAL)
			k:put("chair_dining", 17.7, 18, 90, WHITE, CYAN)
			k:put("chair_dining", 22.3, 18, 270, WHITE, CYAN)
			k:put("chair_dining", 20, 20.3, 180, WHITE, CYAN)
			k:put("chair_dining", 20, 15.7, 0, WHITE, CYAN)
			k:put("counter_sink", 34.35, 17.65, 270, WHITE, SILVER)
			k:put("stove", 34.35, 20.65, 270, WHITE, SILVER)
			k:put("counter", 34.35, 23.65, 270, WHITE, SILVER)
			k:on("microwave", "counter", 34.4, 23.6, 270, WHITE)
			k:on("kettle", "stove", 34.5, 21.2, 250, CYAN)
			k:put("fridge", 30.3, 24.35, 180, WHITE)
			k:put("kitchen_island", 29, 17.5, 0, WHITE, CYAN)
			k:on("toaster", "kitchen_island", 27.2, 17.6, 0, SILVER)
			k:put("stool_bar", 27.5, 20.2, 180, SILVER, CYAN)
			k:put("stool_bar", 30.5, 20.2, 180, SILVER, CYAN)
			k:put("lamp_pendant", 20, 18, 0, CYAN)
			k:put("lamp_pendant", 29, 17.5, 0, CYAN)
			k:put("light_ceiling", 10, 18, 0)
			k:put("light_ceiling", 20, 11.6, 0)
			k:put("coat_stand", 25.6, 10.2, 0, SILVER, CYAN)
			k:hang("clock_wall", "mid", 11, 7.6, "a", CYAN)

			-- the bedroom --------------------------------------------------------------------------
			k:put("bed_double", 14.8, 35.5, 180, WHITE, "A8B4C8")
			k:put("nightstand", 18.75, 38.75, 180, WHITE)
			k:on("lamp_table", "nightstand", 18.75, 38.75, 180, CYAN)
			k:put("desk_computer", 5.55, 29, 90, WHITE, CHARCOAL)
			k:put("chair_wood", 8.0, 29, 270, CHARCOAL, CYAN)
			k:put("wardrobe", 11.6, 27.45, 0, WHITE)
			k:put("beanbag", 8.4, 35.0, 0, CYAN)
			k:hang("art_abstract", "back", 15, 7.6, "b")
			k:put("light_ceiling", 14, 32, 0)

			-- the bathroom
			k:put("bathtub", 25, 36.55, 180)
			k:put("toilet", 34.25, 29, 270)
			k:put("sink_vanity", 29, 27.35, 0, WHITE)
			k:hang("mirror_wall", "mid", 29, 4.8, "b")
			k:put("washing_machine", 23.65, 29.5, 90)
			k:put("laundry_basket", 23.4, 32.4, 90)
			k:put("towel_rail", 31.6, 27.0, 0, nil, CYAN)
			k:put("light_ceiling", 29, 32, 0)
		end,
		"scifi"
	)
end
