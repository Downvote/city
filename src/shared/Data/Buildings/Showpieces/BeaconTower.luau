--!strict
-- A beacon tower: a cool white control room with glass doors and tall panes, a terrace on its roof
-- behind a rail, a glass room on the terrace and the lit beacon mast standing on top of that.
-- Inside, a pair of computer desks, a screen on the wall and an arcade machine for the quiet
-- nights; out on the paving, planters and lamps.
--
-- The frame: x across, z back from the street. The control room is x 6..16, z 6..16, the glass
-- room x 8..14, z 8..14 on the terrace over it.

local Lay = require(script.Parent.Kit.Lay)

type Finish = Lay.Finish

local SHELL: Finish = { c = "E8ECEF", m = "SmoothPlastic" }
local INSIDE: Finish = { c = "DDE3E8", m = "SmoothPlastic" }
local PLATE: Finish = { c = "9AA0A8", m = "DiamondPlate" }
local DECK: Finish = { c = "B4B4B8", m = "Concrete" }
local FRAME: Finish = { c = "D8DCE2", m = "Metal" }
local ROOF: Finish = { c = "8A9098", m = "Metal" }
local PAVING: Finish = { c = "C8CCD2", m = "Concrete" }

local CYAN = "7FD8F0"
local SLATE = "5A6470"
local WHITE = "F4F6F8"

local put, hang = Lay.put, Lay.hang

return function(add: any)
	add(
		"show_beacon_tower",
		"Beacon tower",
		"A white control room with a glass lookout on its roof and a lit beacon on top.",
		"zoom",
		22,
		22,
		function(b: any)
			-- the paving round it
			b:floor(0, 0, 22, 6, PAVING)
			b:floor(0, 16, 22, 22, PAVING)
			b:floor(0, 6, 6, 16, PAVING)
			b:floor(16, 6, 22, 16, PAVING)

			-- the control room and the terrace on it
			b:floor(6, 6, 16, 16, PLATE)
			b:box("", 6, 6, 16, 16, SHELL, INSIDE)
			b:floor(6, 6, 16, 16, DECK, 1)
			Lay.styled(b, "railf", 6, 6, 16, 6, FRAME, "railing", 1)
			Lay.styled(b, "railr", 16, 6, 16, 16, FRAME, "railing", 1)
			Lay.styled(b, "railb", 16, 16, 6, 16, FRAME, "railing", 1)
			Lay.styled(b, "raill", 6, 16, 6, 6, FRAME, "railing", 1)
			-- the glass room, its flat roof, the beacon on that
			Lay.styled(b, "glassf", 8, 8, 14, 8, FRAME, "glass", 1)
			Lay.styled(b, "glassr", 14, 8, 14, 14, FRAME, "glass", 1)
			Lay.styled(b, "glassb", 14, 14, 8, 14, FRAME, "glass", 1)
			Lay.styled(b, "glassl", 8, 14, 8, 8, FRAME, "glass", 1)
			b:roof(8, 8, 14, 14, "flat", 0, 0, ROOF, FRAME, 1, 0.6)
			put(b, "show_beacon", 11, 11, 0, Lay.level(2) + 0.8, WHITE, CYAN, 2)

			-- doors and windows
			Lay.open(b, "door_glass", "front", 5, SLATE, WHITE)
			for _, w in { "left", "right", "back" } do
				b:open("win_floor", w, 2.8)
				b:open("win_floor", w, 7.2)
			end
			hang(b, "lantern_wall", "front", 1.4, 5.6, "a", SLATE, CYAN)
			hang(b, "lantern_wall", "front", 8.6, 5.6, "a", SLATE, CYAN)
			Lay.corners(b, { { 6, 6, 180 }, { 16, 6, 90 }, { 16, 16, 0 }, { 6, 16, 270 } }, SLATE)

			-- the control room
			b:item("doormat", 11, 7.2, 0)
			put(b, "desk_computer", 9.4, 14.6, 180, nil, WHITE, SLATE)
			put(b, "desk_computer", 13.4, 14.6, 180, nil, WHITE, SLATE)
			put(b, "chair_wood", 9.4, 12.4, 0, nil, WHITE, SLATE)
			put(b, "chair_wood", 13.4, 12.4, 0, nil, WHITE, SLATE)
			put(b, "arcade", 7.6, 8.2, 90)
			put(b, "shelf_cubes", 14.9, 9, 270, nil, WHITE)
			hang(b, "tv_wall", "left", 5, 6.4, "b")
			put(b, "light_ceiling", 11, 11, 0)
			-- the lookout
			put(b, "chair_lounge", 11, 10.6, 0, nil, CYAN, SLATE, 1)
			put(b, "lamp_floor", 9, 13, 0, nil, nil, nil, 1)
			put(b, "plant_big", 13, 13, 0, nil, nil, nil, 1)

			-- outside
			put(b, "planter_box", 3, 4, 0, Lay.F, SLATE, CYAN)
			put(b, "planter_box", 19, 4, 0, Lay.F, SLATE, CYAN)
			for _, p in { { 1.2, 1.2 }, { 20.8, 1.2 }, { 1.2, 20.8 }, { 20.8, 20.8 } } do
				put(b, "lamp_post", p[1], p[2], 0, Lay.F, SLATE, CYAN)
			end
			put(b, "bench_garden", 3, 11, 270, Lay.F, WHITE, SLATE)
			put(b, "bench_garden", 19, 11, 90, Lay.F, WHITE, SLATE)
			put(b, "rock", 11, 19.4, 20, Lay.F)
			put(b, "plant_big", 4, 18.6, 0)
			put(b, "plant_big", 18, 18.6, 0)
		end
	)
end
