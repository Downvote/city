--!strict
-- A windmill: a brick base with the mill room in it, a gallery round the floor above with a rail,
-- and a cream boarded top under a pointed cap, its sails across the front. A path comes up to
-- the door past sacks of flour, a vegetable plot behind a fence takes the right hand side, an oak
-- and a pine stand at the back.
--
-- The frame: x across, z back from the street. The base is x 8..20, z 10..22; the gallery is the
-- floor of the first storey over all of it, and the boarded top stands back on x 10..18, z 12..20.
-- The sails hang on the cap's front gable, x 5..23 as they turn.

local Lay = require(script.Parent.Kit.Lay)

type Finish = Lay.Finish

local BRICK: Finish = { c = "D8A48E", m = "Brick" }
local PLASTER: Finish = { c = "F2E6CC", m = "Plaster" }
local BOARDS: Finish = { c = "F2E6CC", m = "WoodPlanks" }
local BOARDS_IN: Finish = { c = "E6D5B4", m = "WoodPlanks" }
local FLAGS: Finish = { c = "BDB8AE", m = "Cobblestone" }
local OAK_FLOOR: Finish = { c = "C49A6C", m = "WoodPlanks" }
local CAP: Finish = { c = "7A6A5E", m = "RoofShingles" }
local RAIL: Finish = { c = "F4F1EA", m = "Wood" }
local PALINGS: Finish = { c = "C49A6C", m = "Wood" }

local WHITE = "FAF6EC"
local SAGE = "6F8F6A"
local WALNUT = "9A6B48"
local OAK = "C49A6C"
local SACK = "E2D3B4"
local CORAL = "E08566"
local MUSTARD = "D9A93F"

local put, hang = Lay.put, Lay.hang

return function(add: any)
	add(
		"show_windmill",
		"Windmill",
		"A brick mill with a gallery and sails, and a vegetable plot beside it.",
		"leaves",
		30,
		30,
		function(b: any)
			-- the base, the gallery floor over it, the boarded top and its cap
			b:floor(8, 10, 20, 22, FLAGS)
			b:box("", 8, 10, 20, 22, BRICK, PLASTER)
			b:floor(8, 10, 20, 22, OAK_FLOOR, 1)
			Lay.styled(b, "galf", 8, 10, 20, 10, RAIL, "railing", 1)
			Lay.styled(b, "galr", 20, 10, 20, 22, RAIL, "railing", 1)
			Lay.styled(b, "galb", 20, 22, 8, 22, RAIL, "railing", 1)
			Lay.styled(b, "gall", 8, 22, 8, 10, RAIL, "railing", 1)
			b:box("up", 10, 12, 18, 20, BOARDS, BOARDS_IN, 1)
			b:roof(10, 12, 18, 20, "gable", 5, 1, CAP, BOARDS, 1, 1)
			-- the sails on the front gable, the hub a little over the eaves
			put(b, "show_mill_sails", 14, 10.2, 180, 17.4, nil, nil, 1)

			-- doors and windows
			Lay.open(b, "door_wood", "front", 6, SAGE, WHITE)
			b:open("win_square", "left", 6)
			b:open("win_square", "right", 6)
			b:open("win_square", "back", 2.6)
			Lay.open(b, "door_wood", "upright", 4, SAGE, WHITE)
			b:open("win_small", "upfront", 4)
			b:open("win_small", "upleft", 4)
			b:open("win_small", "upback", 4)
			for _, w in { "left", "right", "back" } do
				local t = if w == "back" then 2.6 else 6
				hang(b, "window_hood", w, t, Lay.F + 7.38, "a", WHITE, CAP.c)
				hang(b, "window_box", w, t, Lay.F + 1.65, "a", WALNUT, if w == "back" then MUSTARD else CORAL)
			end
			hang(b, "lantern_wall", "front", 2.6, 5.6, "a")
			Lay.footing(b, "front", 12, { { 3.4, 8.6 } })
			Lay.footing(b, "left", 12)
			Lay.footing(b, "right", 12)
			Lay.footing(b, "back", 12)
			Lay.corners(b, { { 10, 12, 180 }, { 18, 12, 90 }, { 18, 20, 0 }, { 10, 20, 270 } }, WHITE, 11.9)

			-- the mill room: the counter where the flour is sold, sacks and shelves, the bench
			b:item("doormat", 14, 11.2, 0)
			put(b, "counter", 18.4, 14, 270, nil, OAK, WHITE)
			put(b, "counter", 18.4, 17, 270, nil, OAK, WHITE)
			put(b, "bread_rack", 18.4, 19.9, 270)
			put(b, "shop_shelves", 9.4, 15, 90)
			put(b, "workbench", 11.4, 20.6, 180, nil, OAK, WALNUT)
			put(b, "kettle", 10.4, 20.8, 180, Lay.top("workbench"))
			put(b, "crate", 15.4, 20.4, 0, nil, SACK, SACK)
			put(b, "crate", 15.5, 20.3, 15, Lay.top("crate") + 0.03, SACK, SACK)
			put(b, "crate", 9.8, 11.8, 10, nil, SACK, SACK)
			put(b, "lamp_pendant", 14, 15.5, 0, nil, MUSTARD)
			hang(b, "clock_wall", "front", 10, 8, "b")

			-- the miller's loft over it, and a bench and pots out on the gallery
			put(b, "bed_single", 12.2, 16.2, 0, nil, nil, nil, 1)
			put(b, "nightstand", 15.4, 19, 180, nil, nil, nil, 1)
			put(b, "crate", 16.6, 13.4, 0, nil, SACK, SACK, 1)
			put(b, "light_ceiling", 14, 16, 0, nil, nil, nil, 1)
			put(b, "bench_wood", 9.05, 16, 90, nil, SAGE, OAK, 1)
			put(b, "flower_pot", 9, 11, 0, nil, nil, CORAL, 1)
			put(b, "flower_pot", 19, 21, 0, nil, nil, MUSTARD, 1)

			-- the way in: stepping stones, sacks by the door, a lamp and a bench
			for _, z in { 1, 3, 5.2 } do
				put(b, "path_stones", 14, z, 0)
			end
			put(b, "doorstep", 14, 8.5, 180, 0)
			put(b, "crate", 9.6, 8.6, 0, 0, SACK, SACK)
			put(b, "crate", 9.7, 8.5, 20, 2.03, SACK, SACK)
			put(b, "crate", 6.8, 7.0, 35, 0, SACK, SACK)
			put(b, "flower_border", 18.2, 9.1, 0)
			put(b, "lamp_post", 11, 1.2, 0)
			put(b, "bench_garden", 4.6, 3.4, 180, nil, OAK, SAGE)
			put(b, "woodpile", 6.9, 16, 90, nil, WALNUT, WALNUT)
			put(b, "water_butt", 21.8, 21, 0, nil, SAGE, WALNUT)
			put(b, "bush", 6.2, 11.6, 0)

			-- the vegetable plot, fenced, on the right
			Lay.styled(b, "plotf", 22, 8, 30, 8, PALINGS, "fence")
			Lay.styled(b, "plotr", 30, 8, 30, 20, PALINGS, "fence")
			Lay.styled(b, "plotb", 30, 20, 22, 20, PALINGS, "fence")
			for _, p in { { 24, 11 }, { 28, 11 }, { 24, 17 }, { 28, 17 } } do
				put(b, "veg_patch", p[1], p[2], 0)
			end
			put(b, "gnome", 26, 14, 200)

			-- trees at the back
			put(b, "tree_oak", 4, 25, 0)
			put(b, "tree_pine", 27, 26, 0)
			put(b, "bush", 14, 27, 30)
		end
	)
end
