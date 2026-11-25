--!strict
-- A gazebo: a square deck with white pillars at its corners and a rail between them, open at the
-- front, under a sage shingle pyramid with a ceiling and a lamp. Benches on three sides face a
-- round table in the middle. Flowers, bushes and two urns round the deck, a path to the step and
-- a sundial behind.
--
-- The frame: x across, z back from the street (z = 0). The deck is x 4..20, z 4..20, the rail
-- and pillars on the square x 6..18, z 6..18 inside it, the roof over that with a deep overhang.

local Lay = require(script.Parent.Kit.Lay)

type Finish = Lay.Finish

local DECK: Finish = { c = "C49A6C", m = "WoodPlanks" }
local RAIL: Finish = { c = "F4F1EA", m = "Wood" }
local CEILING: Finish = { c = "F7F3EA", m = "WoodPlanks" }
local SAGE: Finish = { c = "8FA58A", m = "RoofShingles" }

local WHITE = "F4F1EA"
local SAGE_PAINT = "9DB89A"
local OAK = "C49A6C"
local ROSE = "E8A0B4"
local LILAC = "9C86B8"

local put = Lay.put

return function(add: any)
	add(
		"show_gazebo",
		"Gazebo",
		"A white gazebo with benches round a table, and flowers round its deck.",
		"roofPyramid",
		24,
		24,
		function(b: any)
			b:floor(4, 4, 20, 20, DECK)
			-- the rail, open in the middle of the front
			Lay.styled(b, "railfl", 6, 6, 10, 6, RAIL, "railing")
			Lay.styled(b, "railfr", 14, 6, 18, 6, RAIL, "railing")
			Lay.styled(b, "railr", 18, 6, 18, 18, RAIL, "railing")
			Lay.styled(b, "railb", 18, 18, 6, 18, RAIL, "railing")
			Lay.styled(b, "raill", 6, 18, 6, 6, RAIL, "railing")
			-- a ceiling panel to hang the lamp from, inside the pillars, and the pyramid over it
			-- (the pillars stand a stud inside its corners, so their caps stay under the roof)
			b:floor(8, 8, 16, 16, CEILING, 1)
			b:roof(6, 6, 18, 18, "pyramid", 6, 0, SAGE, RAIL, 0, 2)
			for _, p in { { 7, 7 }, { 17, 7 }, { 7, 17 }, { 17, 17 } } do
				put(b, "pillar_round", p[1], p[2], 0, nil, WHITE, WHITE)
			end

			-- inside: benches on three sides, the table, the lamp over it
			put(b, "bench_wood", 7.2, 12, 90, nil, SAGE_PAINT, OAK)
			put(b, "bench_wood", 16.8, 12, 270, nil, SAGE_PAINT, OAK)
			put(b, "bench_wood", 12, 16.8, 180, nil, SAGE_PAINT, OAK)
			put(b, "table_round", 12, 11.6, 0, nil, WHITE, OAK)
			put(b, "vase_flowers", 12.4, 11.4, 0, Lay.top("table_round"))
			put(b, "lantern", 11.4, 12, 0, Lay.top("table_round"))
			put(b, "lamp_pendant", 12, 11.6, 0, nil, SAGE_PAINT)
			put(b, "flower_pot", 9.2, 7.6, 0, nil, nil, ROSE)
			put(b, "flower_pot", 14.8, 7.6, 0, nil, nil, LILAC)
			put(b, "flower_pot", 8.8, 16.4, 0, nil, nil, LILAC)
			put(b, "flower_pot", 15.2, 16.4, 0, nil, nil, ROSE)

			-- the way in: a path, a lamp each side and flowers along the front of the deck
			put(b, "path_stones", 12, 1, 0)
			put(b, "path_stones", 12, 3, 0)
			put(b, "lamp_post", 9.6, 2.2, 0)
			put(b, "lamp_post", 14.4, 2.2, 0)
			put(b, "flower_border", 6.6, 2.6, 0)
			put(b, "flower_border", 17.4, 2.6, 0)
			put(b, "show_urn", 1.6, 1.6, 0, nil, nil, ROSE)
			put(b, "show_urn", 22.4, 1.6, 0, nil, nil, LILAC)

			-- the sides and the back
			put(b, "flower_bed", 2, 7.5, 90)
			put(b, "bush", 2, 12, 0)
			put(b, "flower_bed", 2, 16.5, 90)
			put(b, "flower_bed", 22, 7.5, 90)
			put(b, "bush", 21.6, 12, 40)
			put(b, "flower_bed", 22, 16.5, 90)
			put(b, "tree_pine", 2.6, 21.4, 0)
			put(b, "bird_house", 21.6, 21.4, 30)
			put(b, "show_sundial", 12, 21.8, 0)
			put(b, "bush", 7.6, 22, 20)
			put(b, "bush", 16.4, 22, 70)
		end
	)
end
