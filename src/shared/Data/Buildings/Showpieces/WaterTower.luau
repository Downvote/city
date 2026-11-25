--!strict
-- A water tower: a wooden tank under a pointed lid on a railed platform, held up on four legs
-- and on the brick pump house underneath, with a ladder up the side. In the pump house, drums
-- of water, a bench and tools; round it on the gravel, a water butt, crates, a bench and a lamp.
--
-- The frame: x across, z back from the street. The platform is x 4..16, z 4..16 a storey up,
-- the pump house x 6..14, z 6..14 under it, the ladder on the platform's right edge.

local Lay = require(script.Parent.Kit.Lay)

type Finish = Lay.Finish

local BRICK: Finish = { c = "C98A72", m = "Brick" }
local INSIDE: Finish = { c = "F4E9D8", m = "Plaster" }
local FLAGS: Finish = { c = "BDB8AE", m = "Cobblestone" }
local DECK: Finish = { c = "B98E62", m = "WoodPlanks" }
local RAIL: Finish = { c = "9A6B48", m = "Wood" }
local GRAVEL: Finish = { c = "D8D0BE", m = "Pebble" }

local STONE = "D6CCB8"
local WALNUT = "9A6B48"
local OAK = "C49A6C"
local SAGE = "6F8F6A"
local NAVY = "46608E"
local CORAL = "E08566"

local put, hang = Lay.put, Lay.hang

return function(add: any)
	add(
		"show_water_tower",
		"Water tower",
		"A wooden water tank on a platform over a little brick pump house, with a ladder up.",
		"rain",
		22,
		22,
		function(b: any)
			-- the gravel round it
			b:floor(0, 0, 22, 6, GRAVEL)
			b:floor(0, 14, 22, 22, GRAVEL)
			b:floor(0, 6, 6, 14, GRAVEL)
			b:floor(14, 6, 22, 14, GRAVEL)

			-- the pump house
			b:floor(6, 6, 14, 14, FLAGS)
			b:box("", 6, 6, 14, 14, BRICK, INSIDE)
			Lay.open(b, "door_wood", "front", 4, SAGE, STONE)
			b:open("win_small", "left", 4)
			b:open("win_small", "right", 4)
			hang(b, "window_hood", "front", 4, 8.78, "a", STONE, STONE)
			Lay.footing(b, "front", 8, { { 1.6, 6.4 } }, STONE)
			Lay.footing(b, "left", 8, nil, STONE)
			Lay.footing(b, "right", 8, nil, STONE)
			Lay.footing(b, "back", 8, nil, STONE)
			Lay.corners(b, { { 6, 6, 180 }, { 14, 6, 90 }, { 14, 14, 0 }, { 6, 14, 270 } }, STONE)

			-- the platform on its legs, the rail (open where the ladder comes up) and the tank
			b:floor(4, 4, 16, 16, DECK, 1)
			for _, p in { { 4.5, 4.5 }, { 15.5, 4.5 }, { 4.5, 15.5 }, { 15.5, 15.5 } } do
				put(b, "pillar_square", p[1], p[2], 0, 0, WALNUT, WALNUT)
			end
			Lay.styled(b, "railf", 4, 4, 16, 4, RAIL, "railing", 1)
			Lay.styled(b, "railrf", 16, 4, 16, 8, RAIL, "railing", 1)
			Lay.styled(b, "railrb", 16, 12, 16, 16, RAIL, "railing", 1)
			Lay.styled(b, "railb", 16, 16, 4, 16, RAIL, "railing", 1)
			Lay.styled(b, "raill", 4, 16, 4, 4, RAIL, "railing", 1)
			put(b, "show_water_tank", 10, 10, 0, nil, nil, nil, 1)
			put(b, "show_ladder", 16.5, 10, 90, 0, WALNUT, WALNUT)

			-- inside the pump house
			b:item("doormat", 10, 7.2, 0)
			put(b, "water_butt", 7.6, 12.4, 0, nil, NAVY, WALNUT)
			put(b, "water_butt", 9.8, 12.6, 20, nil, NAVY, WALNUT)
			put(b, "workbench", 11.6, 12.4, 180, nil, OAK, WALNUT)
			hang(b, "tool_board", "back", 2.4, 6.4, "b", WALNUT, OAK)
			put(b, "lamp_pendant", 10, 10, 0)

			-- round about
			put(b, "water_butt", 3, 8, 0, Lay.F, SAGE, WALNUT)
			put(b, "crate", 17.6, 6.6, 15, Lay.F, OAK, OAK)
			put(b, "crate", 17.7, 6.5, 40, Lay.top("crate"), OAK, OAK)
			put(b, "bench_garden", 11, 19, 180, Lay.F, OAK, SAGE)
			put(b, "lamp_post", 2, 2, 0, Lay.F)
			put(b, "flower_bed", 16, 2.6, 0, Lay.F)
			put(b, "bush", 19.6, 19.6, 0, Lay.F)
			put(b, "bush", 2.4, 19.6, 30, Lay.F)
			put(b, "woodpile", 20.8, 12, 90, Lay.F, WALNUT, WALNUT)
		end
	)
end
