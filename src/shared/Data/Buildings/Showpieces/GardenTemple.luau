--!strict
-- A garden temple: ten white columns on a marble floor under a low green copper roof with a
-- pediment at each end, a statue in the middle and a chandelier over it. Steps come up from a
-- pond in front, with an urn either side of the water, a lamp at each corner of the front, two
-- pines behind and flowers down the sides.
--
-- The frame: x across, z back from the street. The marble is x 2..20, z 10..24, the roof
-- x 4..18, z 12..22 with its ridge running back; the pond is in front of the steps.

local Lay = require(script.Parent.Kit.Lay)

type Finish = Lay.Finish

local MARBLE: Finish = { c = "F7F3EA", m = "Marble" }
local CEILING: Finish = { c = "F7F3EA", m = "WoodPlanks" }
local COPPER: Finish = { c = "8FB0A0", m = "Slate" }
local PEDIMENT: Finish = { c = "F4F1EA", m = "Marble" }

local WHITE = "F7F3EA"
local STONE = "D6CCB8"
local CORAL = "E08566"
local LILAC = "9C86B8"

local put = Lay.put

return function(add: any)
	add(
		"show_garden_temple",
		"Garden temple",
		"White columns under a copper roof round a statue, with steps up from a pond.",
		"hall",
		22,
		28,
		function(b: any)
			b:floor(2, 10, 20, 24, MARBLE)
			b:floor(6, 14, 16, 20, CEILING, 1)
			b:roof(4, 12, 18, 22, "gable", 3.5, 1, COPPER, PEDIMENT, 0, 1.2)
			for _, z in { 13, 21 } do
				for _, x in { 5, 9, 13, 17 } do
					put(b, "pillar_round", x, z, 0, nil, WHITE, WHITE)
				end
			end
			put(b, "pillar_round", 5, 17, 0, nil, WHITE, WHITE)
			put(b, "pillar_round", 17, 17, 0, nil, WHITE, WHITE)

			-- inside: the statue, its chandelier, urns either side
			put(b, "sculpture_form", 11, 17, 0, nil, WHITE, STONE)
			put(b, "chandelier", 11, 17, 0)
			put(b, "show_urn", 7.4, 19.2, 0, Lay.F, nil, CORAL)
			put(b, "show_urn", 14.6, 19.2, 0, Lay.F, nil, LILAC)

			-- in front: the steps, the pond, urns and lamps
			put(b, "doorstep", 11, 8.8, 180, 0, STONE, STONE)
			put(b, "pond", 11, 4, 0)
			put(b, "show_urn", 3, 4.4, 0, nil, nil, CORAL)
			put(b, "show_urn", 19, 4.4, 0, nil, nil, LILAC)
			put(b, "lamp_post", 5.6, 8.6, 0)
			put(b, "lamp_post", 16.4, 8.6, 0)

			-- round the sides and behind
			for _, z in { 14, 20 } do
				put(b, "flower_bed", 1, z, 90)
				put(b, "flower_bed", 21, z, 90)
			end
			put(b, "tree_pine", 2.6, 25.4, 0)
			put(b, "tree_pine", 19.4, 25.4, 0)
			put(b, "bush", 11, 26, 0)
		end
	)
end
