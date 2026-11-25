--!strict
-- A potting shed: a sage green boarded shed under a lean-to roof in a fenced garden, with a work
-- bench, tools and a bike inside. Round the side, under a canopy, the potting bench with its pots;
-- staging against the fence, two vegetable beds by the gate, a woodpile, a water butt and a bench.
--
-- The frame: x across, z back from the street. The fence runs round the edge with its gate at
-- x 10..14 on the front; the shed is x 2..12, z 8..16.

local Lay = require(script.Parent.Kit.Lay)

type Finish = Lay.Finish

local SAGE_BOARDS: Finish = { c = "B9CBB4", m = "WoodPlanks" }
local INSIDE: Finish = { c = "E6D5B4", m = "WoodPlanks" }
local FLOOR: Finish = { c = "C49A6C", m = "WoodPlanks" }
local SHINGLE: Finish = { c = "8A7A6E", m = "RoofShingles" }
local PALINGS: Finish = { c = "F4F1EA", m = "Wood" }

local CREAM = "F2E6CC"
local SAGE = "6F8F6A"
local OAK = "C49A6C"
local WALNUT = "9A6B48"
local TERRACOTTA = "C9806A"
local CORAL = "E08566"
local MUSTARD = "D9A93F"

local put, hang = Lay.put, Lay.hang

return function(add: any)
	add(
		"show_potting_shed",
		"Potting shed",
		"A green garden shed with a covered potting bench, in a fenced garden with vegetable beds.",
		"pot",
		26,
		20,
		function(b: any)
			-- the fence, with a gate on the street
			Lay.styled(b, "fencefl", 0, 0, 10, 0, PALINGS, "fence")
			Lay.styled(b, "fencefr", 14, 0, 26, 0, PALINGS, "fence")
			Lay.styled(b, "fencer", 26, 0, 26, 20, PALINGS, "fence")
			Lay.styled(b, "fenceb", 26, 20, 0, 20, PALINGS, "fence")
			Lay.styled(b, "fencel", 0, 20, 0, 0, PALINGS, "fence")
			put(b, "gate_garden", 12, 0.4, 0, 0, CREAM, CREAM)

			-- the shed
			b:floor(2, 8, 12, 16, FLOOR)
			b:box("", 2, 8, 12, 16, SAGE_BOARDS, INSIDE)
			b:roof(2, 8, 12, 16, "shed", 2.4, 0, SHINGLE, SAGE_BOARDS, 0, 1)
			Lay.open(b, "door_wood", "front", 3, CREAM, WALNUT)
			b:open("win_square", "front", 7.4)
			b:open("win_small", "left", 4)
			b:open("win_small", "back", 5)
			hang(b, "window_box", "front", 7.4, Lay.F + 1.65, "a", WALNUT, CORAL)
			hang(b, "window_hood", "front", 7.4, Lay.F + 7.38, "a", CREAM, SHINGLE.c)
			hang(b, "lantern_wall", "front", 0.5, 5.4, "a")
			Lay.corners(b, { { 2, 8, 180 }, { 12, 8, 90 }, { 12, 16, 0 }, { 2, 16, 270 } }, CREAM)
			Lay.footing(b, "front", 10, { { 0.6, 5.4 } })
			Lay.footing(b, "left", 8)
			Lay.footing(b, "back", 10)
			hang(b, "downpipe", "back", 0.6, 0, "a")

			-- inside: the bench and tools, crates, the bike
			b:item("doormat", 5, 9.2, 0)
			put(b, "workbench", 6, 14.5, 180, nil, OAK, WALNUT)
			put(b, "lamp_desk", 4.6, 14.6, 200, Lay.top("workbench"), MUSTARD)
			put(b, "flower_pot", 7.2, 14.7, 0, Lay.top("workbench"), nil, CORAL)
			hang(b, "tool_board", "back", 5, 6.8, "b", WALNUT, OAK)
			hang(b, "shelf_wall", "left", 4, 7.6, "b", OAK)
			hang(b, "coat_hooks", "front", 8.6, 5.2, "b")
			put(b, "bicycle", 10.6, 12, 0, nil, SAGE, WALNUT)
			put(b, "crate", 3.4, 9.6, 20, nil, OAK, OAK)
			put(b, "lamp_pendant", 7, 12, 0, nil, MUSTARD)

			-- the potting corner round the side, under a canopy (what stands on the grass out here
			-- goes down at 0, the ground, not on a floor)
			put(b, "canopy_door", 14.5, 12, 90, 0, CREAM, SAGE)
			put(b, "workbench", 13.5, 12, 90, 0, OAK, WALNUT)
			for i, z in { 10.4, 11.6, 13.2 } do
				put(b, "flower_pot", 13.3, z, 0, Lay.top("workbench", 0), nil, if i == 2 then MUSTARD else CORAL)
			end
			hang(b, "tool_board", "right", 4, 5.6, "a", WALNUT, OAK)
			put(b, "plant_bench", 24.6, 12, 270, 0, OAK, TERRACOTTA)
			put(b, "water_butt", 13.4, 6.8, 0, nil, SAGE, WALNUT)
			put(b, "crate", 16.2, 7.2, 0, 0, OAK, OAK)
			put(b, "crate", 16.3, 7.1, 20, Lay.top("crate", 0), OAK, OAK)

			-- the garden: beds by the gate, a path to the door, a woodpile and a bench
			put(b, "veg_patch", 18.5, 4.5, 0)
			put(b, "veg_patch", 22.5, 4.5, 0)
			put(b, "path_stones", 12, 2.2, 0)
			put(b, "path_stones", 10, 4.2, 20)
			put(b, "path_stones", 7.6, 6.2, 40)
			put(b, "flower_border", 5, 1.6, 0)
			put(b, "gnome", 8.4, 2.4, 200)
			put(b, "bird_house", 1.4, 4.6, 0)
			put(b, "woodpile", 7, 17.2, 0, nil, WALNUT, WALNUT)
			put(b, "bench_garden", 21, 17.8, 180, nil, OAK, SAGE)
			put(b, "bush", 15.6, 17.8, 0)
		end
	)
end
