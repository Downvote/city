--!strict
-- An observatory: a square lilac grey study under a flat roof with its round dome on top, the
-- slit open and the big telescope looking out. Inside, a desk with a computer, star charts,
-- bookcases and a globe, and a smaller telescope at the window. Outside, a path between planters,
-- a sundial and another telescope on the lawn for anyone who comes to look.
--
-- The frame: x across, z back from the street. The study is x 6..20, z 8..22; the dome stands on
-- its roof in the middle.

local Lay = require(script.Parent.Kit.Lay)

type Finish = Lay.Finish

local WALLS: Finish = { c = "D8D2E6", m = "Plaster" }
local INSIDE: Finish = { c = "F4E9D8", m = "Plaster" }
local FLOOR: Finish = { c = "9A6B48", m = "WoodPlanks" }
local CEILING: Finish = { c = "F7F3EA", m = "Plaster" }
local ROOF: Finish = { c = "8A8494", m = "Concrete" }
local TRIM: Finish = { c = "F4F1EA", m = "Plaster" }
local PAVING: Finish = { c = "EAE6DC", m = "Pavement" }

local WHITE = "FAF6EC"
local NAVY = "46608E"
local STONE = "D6CCB8"
local OAK = "C49A6C"
local WALNUT = "9A6B48"
local LILAC = "9C86B8"
local BUTTER = "F3DFA6"

local put, hang = Lay.put, Lay.hang

return function(add: any)
	add(
		"show_observatory",
		"Observatory",
		"A study with a domed telescope on its roof and a sundial out front.",
		"moon",
		26,
		28,
		function(b: any)
			-- the study, its ceiling, the flat roof and the dome on it, its slit to the street
			b:floor(6, 8, 20, 22, FLOOR)
			b:box("", 6, 8, 20, 22, WALLS, INSIDE)
			b:floor(6, 8, 20, 22, CEILING, 1)
			b:roof(6, 8, 20, 22, "flat", 0, 0, ROOF, TRIM, 0, 0.6)
			put(b, "show_dome", 13, 15, 180, Lay.level(1) + 0.8, nil, NAVY, 1)

			-- doors and windows
			Lay.open(b, "door_double", "front", 7, NAVY, WHITE)
			b:open("win_tall", "front", 2.4)
			b:open("win_tall", "front", 11.6)
			for _, w in { "left", "right" } do
				b:open("win_tall", w, 3.5)
				b:open("win_tall", w, 10.5)
			end
			b:open("win_porthole", "back", 4)
			b:open("win_porthole", "back", 10)
			for _, t in { 2.4, 11.6 } do
				hang(b, "window_hood", "front", t, Lay.F + 8.38, "a", STONE, STONE)
			end
			Lay.footing(b, "front", 14, { { 3.4, 10.6 } }, STONE)
			Lay.footing(b, "left", 14, nil, STONE)
			Lay.footing(b, "right", 14, nil, STONE)
			Lay.footing(b, "back", 14, nil, STONE)
			Lay.corners(b, { { 6, 8, 180 }, { 20, 8, 90 }, { 20, 22, 0 }, { 6, 22, 270 } }, STONE)

			-- the study
			b:item("doormat", 13, 9.2, 0)
			put(b, "desk_computer", 13, 20.5, 180, nil, OAK, NAVY)
			put(b, "chair_wood", 13, 18.2, 0, nil, OAK, NAVY)
			put(b, "bookshelf", 7.1, 15, 90, nil, WALNUT)
			put(b, "bookshelf", 18.9, 15, 270, nil, WALNUT)
			put(b, "show_telescope", 17.4, 10.4, 200)
			put(b, "table_round", 9.6, 11.4, 0, nil, WHITE, WALNUT)
			put(b, "globe", 9.6, 11.4, 30, Lay.top("table_round"))
			put(b, "armchair", 8.8, 19.3, 135, nil, LILAC, OAK)
			put(b, "rug_round", 13, 14.6, 0)
			put(b, "lamp_floor", 16.6, 20.6, 0)
			put(b, "light_ceiling", 13, 15, 0)
			hang(b, "art_abstract", "back", 7, 6.4, "b")
			hang(b, "art_landscape", "left", 7, 7.4, "b")
			hang(b, "clock_wall", "right", 7, 8.4, "b")
			hang(b, "shelf_wall", "back", 3.6, 7.8, "b", OAK)

			-- outside: the path between planters, a sundial, a telescope on the lawn
			b:floor(10, 0, 16, 8, PAVING)
			put(b, "planter_box", 7.6, 5.2, 0, nil, WALNUT, LILAC)
			put(b, "planter_box", 18.4, 5.2, 0, nil, WALNUT, BUTTER)
			put(b, "lamp_post", 9, 1.4, 0)
			put(b, "lamp_post", 17, 1.4, 0)
			put(b, "show_sundial", 3.6, 3.6, 0)
			put(b, "show_telescope", 22.6, 3.2, 150, 0)
			put(b, "bench_garden", 3, 15, 270, nil, OAK, NAVY)
			put(b, "bush", 23, 12, 0)
			put(b, "bush", 23, 18, 30)
			put(b, "tree_pine", 3.4, 24.6, 0)
			put(b, "tree_pine", 22.6, 24.6, 0)
		end
	)
end
