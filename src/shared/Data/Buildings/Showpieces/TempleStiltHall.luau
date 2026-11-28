--!strict
-- A main hall on stilts: a storey of timber stilts on a stone base, the hall's floor of dark
-- boards on them with a railed veranda round the room, dark timber over white plaster, lattice
-- doors, a great tiled roof sweeping up at its corners, and wide stairs up to the veranda with a
-- lantern either side at their foot. (The user, with a picture of an old temple in a forest:
-- "Make another for this as well".)
--
-- The frame: x across, z back from the street. The stilts and the floor on them are x 4..36,
-- z 18..42; the room on that floor is x 6..34, z 20..40; the stairs climb from z 4 to the
-- veranda's front edge at z 18.

local Lay = require(script.Parent.Kit.Lay)

type Finish = Lay.Finish

local BOARDS: Finish = { c = "6E5444", m = "WoodPlanks" }
local OUTSIDE: Finish = { c = "EFE9DC", m = "WoodPlanks" }
local INSIDE: Finish = { c = "E2D2B8", m = "WoodPlanks" }
local RAIL: Finish = { c = "5C4636", m = "Wood" }

local put, hang = Lay.put, Lay.hang

return function(add: any)
	add(
		"show_stilt_hall",
		"Hall on stilts",
		"A great hall raised a storey on timber stilts.",
		"pagoda",
		40,
		46,
		function(b: any)
			put(b, "temple_stilts", 20, 30, 0, 0)
			b:floor(4, 18, 36, 42, BOARDS, 1)
			b:box("", 6, 20, 34, 40, OUTSIDE, INSIDE, 1)
			Lay.open(b, "door_temple", "front", 14)
			for _, t in { 2, 6, 22, 26 } do
				hang(b, "temple_frame", "front", t, 0, "a")
			end
			hang(b, "temple_frame_narrow", "front", 9, 0, "a")
			hang(b, "temple_frame_narrow", "front", 19, 0, "a")
			for _, t in { 2, 6, 10, 14, 18, 22, 26 } do
				hang(b, "temple_frame", "back", t, 0, "a")
			end
			for _, t in { 2, 6, 10, 14, 18 } do
				hang(b, "temple_frame", "right", t, 0, "a")
				hang(b, "temple_frame", "left", t, 0, "a")
			end
			-- the veranda's rail, open at the front where the stairs come up
			Lay.styled(b, "railfl", 4, 18, 16, 18, RAIL, "railing", 1)
			Lay.styled(b, "railfr", 24, 18, 36, 18, RAIL, "railing", 1)
			Lay.styled(b, "railr", 36, 18, 36, 42, RAIL, "railing", 1)
			Lay.styled(b, "railb", 36, 42, 4, 42, RAIL, "railing", 1)
			Lay.styled(b, "raill", 4, 42, 4, 18, RAIL, "railing", 1)
			-- the great roof, on the floor over the room
			put(b, "temple_roof_great", 20, 30, 0, Lay.level(2), nil, nil, 2)
			-- the stairs up from the front, their top at the veranda
			put(b, "stairs_wide", 20, 11, 180, nil, "6E5444", "5C4636")
			put(b, "temple_lantern", 15.5, 4, 0)
			put(b, "temple_lantern", 24.5, 4, 0)
		end,
		"temple"
	)
end
