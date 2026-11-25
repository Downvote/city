--!strict
-- A treehouse: a deck on posts round a great oak at the first floor's height, with a log hut on
-- it under a moss green roof and a rail round the edge. Stairs climb to it at the side. Inside the
-- hut a bed like a little house, a toy chest and a bean bag; out on the deck a bench and a
-- telescope. Under it and round it: a picnic table in the shade, a sandbox and a swing set.
--
-- The frame: x across, z back from the street. The oak stands at (17, 21), the deck is x 6..28,
-- z 8..28 a storey up, the hut x 10..24, z 10..18 on it in front of the trunk, the stairs x 2..6.

local Lay = require(script.Parent.Kit.Lay)

type Finish = Lay.Finish

local LOGS: Finish = { c = "B98E62", m = "WoodPlanks" }
local LOGS_IN: Finish = { c = "DDBE94", m = "WoodPlanks" }
local DECK: Finish = { c = "C49A6C", m = "WoodPlanks" }
local MOSS: Finish = { c = "8C9A6E", m = "RoofShingles" }
local RAIL: Finish = { c = "9A6B48", m = "Wood" }

local WALNUT = "9A6B48"
local OAK = "C49A6C"
local CREAM = "F2E6CC"
local SKY = "8FB3D0"
local CORAL = "E08566"
local MUSTARD = "D9A93F"

local put, hang = Lay.put, Lay.hang

return function(add: any)
	add(
		"show_treehouse",
		"Treehouse",
		"A log hut on a deck round a great oak, with stairs up, swings and a sandbox below.",
		"tree",
		34,
		34,
		function(b: any)
			-- the deck a storey up, on posts, with its rail (open at the top of the stairs)
			b:floor(6, 8, 28, 28, DECK, 1)
			for _, p in
				{ { 6.6, 8.6 }, { 17, 8.6 }, { 27.4, 8.6 }, { 6.6, 18 }, { 27.4, 18 }, { 6.6, 27.4 }, { 27.4, 27.4 } }
			do
				put(b, "pillar_square", p[1], p[2], 0, 0, WALNUT, WALNUT)
			end
			Lay.styled(b, "railf", 6, 8, 28, 8, RAIL, "railing", 1)
			Lay.styled(b, "railr", 28, 8, 28, 28, RAIL, "railing", 1)
			Lay.styled(b, "railb", 28, 28, 6, 28, RAIL, "railing", 1)
			Lay.styled(b, "raillb", 6, 28, 6, 24, RAIL, "railing", 1)
			Lay.styled(b, "raillf", 6, 20, 6, 8, RAIL, "railing", 1)
			put(b, "stairs_straight", 4, 17, 180, nil, OAK, WALNUT)
			put(b, "show_great_oak", 17, 21, 0)

			-- the hut
			b:box("hut", 10, 10, 24, 18, LOGS, LOGS_IN, 1)
			b:roof(10, 10, 24, 18, "gable", 3, 0, MOSS, LOGS, 1, 1)
			Lay.open(b, "door_wood", "hutfront", 7, SKY, CREAM)
			b:open("win_square", "hutfront", 2.4)
			b:open("win_square", "hutfront", 11.6)
			b:open("win_small", "hutleft", 4)
			b:open("win_small", "hutright", 4)
			b:open("win_small", "hutback", 3)
			hang(b, "bunting", "hutfront", 7, 9.4, "a")
			for _, t in { 2.4, 11.6 } do
				hang(b, "window_box", "hutfront", t, 1.25, "a", WALNUT, if t < 5 then CORAL else MUSTARD)
			end
			hang(b, "lantern_wall", "hutleft", 1.2, 5.2, "a")

			-- inside the hut
			put(b, "bed_kids", 20.2, 14, 90, nil, nil, nil, 1)
			put(b, "teddy", 21.4, 13.6, 250, Lay.level(1) + 1.6, nil, nil, 1)
			put(b, "toy_chest", 14.4, 16.7, 180, nil, nil, nil, 1)
			put(b, "shelf_cubes", 11.1, 15.6, 90, nil, nil, nil, 1)
			put(b, "books_stack", 11.1, 15.2, 0, Lay.level(1) + 4.8, nil, nil, 1)
			put(b, "beanbag", 12, 12.4, 30, nil, CORAL, nil, 1)
			put(b, "rug_round", 14.4, 13.6, 0, nil, nil, nil, 1)
			put(b, "lamp_floor", 22.8, 11.2, 0, nil, nil, nil, 1)
			hang(b, "art_flowers", "hutback", 9, 5.6, "b")

			-- out on the deck
			put(b, "bench_wood", 26.9, 13.6, 270, nil, SKY, OAK, 1)
			put(b, "show_telescope", 25.2, 24.6, 90, nil, nil, nil, 1)
			put(b, "flower_pot", 8, 9.4, 0, nil, nil, CORAL, 1)
			put(b, "flower_pot", 26.6, 9.4, 0, nil, nil, MUSTARD, 1)
			put(b, "crate", 8.4, 26.4, 20, nil, nil, nil, 1)
			put(b, "lantern", 8.4, 26.4, 0, Lay.level(1) + 2, nil, nil, 1)

			-- below: a picnic table in the shade, a sandbox and the swings out front
			put(b, "picnic_table", 12.6, 14, 0, nil, OAK, WALNUT)
			put(b, "sandbox", 12, 4, 0)
			put(b, "swing_set", 27.5, 4, 0)
			put(b, "lamp_post", 1.2, 7.6, 0)
			put(b, "bush", 1.8, 27, 0)
			put(b, "bush", 31.8, 12, 40)
			put(b, "flower_bed", 31.6, 22, 90)
			put(b, "rock", 21.6, 4.6, 60)
			put(b, "bicycle", 31.2, 31, 90, nil, SKY, WALNUT)
		end
	)
end
