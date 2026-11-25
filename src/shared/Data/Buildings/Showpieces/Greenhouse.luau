--!strict
-- A greenhouse: glass sides under a glass roof, its gable ends white with tall panes either side of
-- a glass door. Inside, staging full of pots down both sides, two vegetable beds in the middle and
-- a potting bench at the back. Outside, more beds behind, flowers along the sides and a water
-- butt to fill the cans from.
--
-- The frame: x across, z back from the street. The greenhouse is x 4..20, z 6..22, its ridge
-- running back from the street.

local Lay = require(script.Parent.Kit.Lay)

type Finish = Lay.Finish

local FRAME: Finish = { c = "F4F1EA", m = "WoodPlanks" }
local GRAVEL: Finish = { c = "D8D0BE", m = "Pebble" }
local BRICK_PATH: Finish = { c = "C88A6E", m = "Brick" }

local WHITE = "F4F1EA"
local SAGE = "6F8F6A"
local OAK = "C49A6C"
local WALNUT = "9A6B48"
local TERRACOTTA = "C9806A"
local CORAL = "E08566"

local put = Lay.put

return function(add: any)
	add(
		"show_greenhouse",
		"Greenhouse",
		"A glass house with pots on staging down both sides and vegetable beds in the middle.",
		"plant",
		24,
		28,
		function(b: any)
			b:floor(4, 6, 20, 22, GRAVEL)
			b:floor(10, 0, 14, 6, BRICK_PATH)
			-- the white ends with their panes, the glass sides, and the glass roof standing on them
			b:wall("front", 4, 6, 20, 6, FRAME, FRAME)
			Lay.styled(b, "right", 20, 6, 20, 22, FRAME, "glass")
			b:wall("back", 20, 22, 4, 22, FRAME, FRAME)
			Lay.styled(b, "left", 4, 22, 4, 6, FRAME, "glass")
			put(b, "show_glass_roof", 12, 14, 0, Lay.level(1), WHITE, WHITE, 1)
			Lay.open(b, "door_glass", "front", 8, SAGE, WHITE)
			b:open("win_floor", "front", 3.2)
			b:open("win_floor", "front", 12.8)
			for _, t in { 3.2, 8, 12.8 } do
				b:open("win_floor", "back", t)
			end

			-- inside: staging down both sides, the beds, the potting bench
			for _, z in { 10, 17 } do
				put(b, "plant_bench", 5.6, z, 90, nil, OAK, TERRACOTTA)
				put(b, "plant_bench", 18.4, z, 270, nil, OAK, TERRACOTTA)
			end
			put(b, "veg_patch", 10, 15.4, 0, Lay.F)
			put(b, "veg_patch", 14, 15.4, 0, Lay.F)
			put(b, "workbench", 12, 20.4, 180, nil, OAK, WALNUT)
			put(b, "flower_pot", 10.6, 20.6, 0, Lay.top("workbench"), nil, CORAL)
			put(b, "plant_small", 12.2, 20.4, 0, Lay.top("workbench"))
			put(b, "flower_pot", 13.6, 20.7, 0, Lay.top("workbench"), nil, "9C86B8")
			put(b, "crate", 8.2, 20.6, 15, nil, OAK, OAK)
			put(b, "flower_pot", 15.8, 20.6, 0, nil, nil, CORAL)
			b:item("doormat", 12, 7.2, 0)

			-- outside: the path in, beds behind, flowers down the sides, the water butt
			put(b, "show_urn", 8, 3, 0, nil, nil, CORAL)
			put(b, "show_urn", 16, 3, 0, nil, nil, "F3DFA6")
			put(b, "water_butt", 21.8, 4.6, 0, nil, SAGE, WALNUT)
			for _, z in { 9, 14, 19 } do
				put(b, "flower_border", 2.4, z, 90)
			end
			put(b, "woodpile", 22.6, 12, 90, nil, WALNUT, WALNUT)
			put(b, "bush", 22.2, 18, 0)
			for _, x in { 6, 10, 14, 18 } do
				put(b, "veg_patch", x, 25, 0)
			end
		end
	)
end
