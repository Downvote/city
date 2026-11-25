--!strict
-- A lighthouse: an eight sided tower in white and soft red bands, three storeys tall, its flat
-- top a gallery with the lantern on it. The keeper's cottage stands beside it with a fireplace,
-- a bed and a table, and rocks, a fog bell and a bench face the sea.
--
-- The frame: x across, z back from the street (the sea, as it's drawn). The tower's eight walls
-- go round (13, 13), its straight sides 6 long on the lines x 6, x 20, z 6 and z 20, its corners
-- cut off; the cottage is x 24..34, z 10..20.

local Lay = require(script.Parent.Kit.Lay)

type Finish = Lay.Finish

local WHITE_PLASTER: Finish = { c = "F6F0E2", m = "Plaster" }
local RED_PLASTER: Finish = { c = "C9786A", m = "Plaster" }
local INSIDE: Finish = { c = "F4E9D8", m = "Plaster" }
local FLAGS: Finish = { c = "BDB8AE", m = "Cobblestone" }
local BOARDS: Finish = { c = "C49A6C", m = "WoodPlanks" }
local GALLERY: Finish = { c = "6E6A72", m = "Concrete" }
local TRIM: Finish = { c = "F4F1EA", m = "SmoothPlastic" }
local TILES: Finish = { c = "BC7468", m = "ClayRoofTiles" }

local WHITE = "FAF6EC"
local NAVY = "46608E"
local RED = "C9786A"
local OAK = "C49A6C"
local WALNUT = "9A6B48"

local put, hang = Lay.put, Lay.hang

local OCTAGON = { { 10, 6 }, { 16, 6 }, { 20, 10 }, { 20, 16 }, { 16, 20 }, { 10, 20 }, { 6, 16 }, { 6, 10 } }

return function(add: any)
	add(
		"show_lighthouse",
		"Lighthouse",
		"A striped lighthouse with its lamp up top, and the keeper's cottage beside it.",
		"lamp",
		36,
		30,
		function(b: any)
			-- the tower on its square stone plinth, a storey at a time, and the floors inside it
			b:floor(6, 6, 20, 20, FLAGS)
			for lv = 0, 2 do
				Lay.ring(b, "t" .. lv .. "_", OCTAGON, if lv == 1 then RED_PLASTER else WHITE_PLASTER, INSIDE, lv)
				if lv > 0 then
					b:floor(10, 6, 16, 20, BOARDS, lv)
					b:floor(6, 10, 10, 16, BOARDS, lv)
					b:floor(16, 10, 20, 16, BOARDS, lv)
				end
			end
			-- the gallery on top, and the lantern standing on it
			b:roof(6, 6, 20, 20, "flat", 0, 0, GALLERY, TRIM, 2, 1)
			put(b, "show_lantern", 13, 13, 0, Lay.level(3) + 0.8, WHITE, RED, 3)

			-- the door, round windows up the tower and small ones on the corners
			Lay.open(b, "door_wood", "t0_1", 3, NAVY, WHITE)
			for lv = 1, 2 do
				b:open("win_porthole", "t" .. lv .. "_1", 3)
				b:open("win_porthole", "t" .. lv .. "_5", 3)
				b:open("win_small", "t" .. lv .. "_3", 3)
				b:open("win_small", "t" .. lv .. "_7", 3)
			end
			b:open("win_small", "t0_3", 3)
			b:open("win_small", "t0_7", 3)
			for i = 2, 8 do
				Lay.footing(b, "t0_" .. i, if i % 2 == 1 then 6 else 5.66)
			end
			Lay.footing(b, "t0_1", 6, { { 0.6, 5.4 } })

			-- inside the foot of the tower: the oil store
			b:item("doormat", 13, 7.2, 0)
			put(b, "water_butt", 8.4, 13, 0, nil, RED, WALNUT)
			put(b, "water_butt", 9.6, 15.6, 30, nil, RED, WALNUT)
			put(b, "crate", 17.4, 12.4, 10)
			put(b, "crate", 17.5, 12.3, 30, Lay.top("crate"))
			put(b, "lantern", 17.5, 12.3, 0, Lay.top("crate", Lay.top("crate")))
			put(b, "workbench", 13, 18.5, 180, nil, OAK, WALNUT)
			put(b, "lamp_pendant", 13, 13, 0)
			hang(b, "coat_hooks", "t0_5", 3, 5.4, "b")

			-- the keeper's cottage
			b:floor(24, 10, 34, 20, BOARDS)
			b:box("c", 24, 10, 34, 20, WHITE_PLASTER, INSIDE)
			b:roof(24, 10, 34, 20, "gable", 5, 0, TILES, WHITE_PLASTER, 0, 1)
			Lay.open(b, "door_front", "cfront", 3, NAVY, WHITE)
			b:open("win_square", "cfront", 7.6)
			b:open("win_square", "cleft", 5)
			b:open("win_small", "cright", 5)
			b:open("win_small", "cback", 7.4)
			hang(b, "window_box", "cfront", 7.6, Lay.F + 1.65, "a", NAVY, "E08566")
			hang(b, "window_box", "cleft", 5, Lay.F + 1.65, "a", NAVY, "F3DFA6")
			Lay.footing(b, "cfront", 10, { { 0.4, 5.6 } })
			Lay.footing(b, "cleft", 10)
			Lay.footing(b, "cright", 10)
			Lay.footing(b, "cback", 10)
			Lay.corners(b, { { 24, 10, 180 }, { 34, 10, 90 }, { 34, 20, 0 }, { 24, 20, 270 } }, WHITE)
			hang(b, "downpipe", "cback", 0.6, 0, "a")
			-- inside: the fireplace on the back wall, the bed along the side, a table by the window
			put(b, "chimney_hearth", 31, 18.1, 180, nil, "B8665C", "DAD4C8")
			b:item("doormat", 27, 11.2, 0)
			put(b, "bed_single", 26.2, 15.2, 0, nil, NAVY, WHITE)
			put(b, "table_round", 31, 12.4, 0, nil, WHITE, OAK)
			put(b, "chair_wood", 31, 14.8, 180, nil, OAK, NAVY)
			put(b, "chair_wood", 33.0, 12.4, 270, nil, OAK, NAVY)
			put(b, "kettle", 31.3, 12.2, 200, Lay.top("table_round"))
			put(b, "lamp_pendant", 31, 12.4, 0)
			hang(b, "art_flowers", "cleft", 1.5, 6, "b")
			hang(b, "clock_wall", "cleft", 8.4, 8.4, "b")

			-- outside: the paths, rocks round the tower's foot, the fog bell, a bench
			put(b, "path_stones", 13, 1, 0)
			put(b, "path_stones", 13, 3, 0)
			put(b, "path_stones", 22, 13, 30)
			put(b, "path_stones", 27, 7.6, 15)
			put(b, "lamp_post", 17.6, 2.6, 0)
			put(b, "rock", 4, 4, 30)
			put(b, "rock", 2.4, 18, 120)
			put(b, "rock", 21.6, 4, 70)
			put(b, "rock", 8.6, 25.4, 200)
			put(b, "bush", 4.4, 9.6, 0)
			put(b, "school_bell", 4, 24, 90, 0, "B0894F", WALNUT)
			put(b, "bench_garden", 30.6, 5.6, 180, nil, WHITE, NAVY)
			put(b, "flower_border", 31.4, 8.8, 0)
			put(b, "water_butt", 23, 22, 0, nil, NAVY, WALNUT)
			put(b, "woodpile", 35.2, 15, 90, nil, WALNUT, WALNUT)
			put(b, "show_surfboards", 20, 26, 180, 0)
			put(b, "tree_pine", 31.6, 26.4, 0)
		end
	)
end
