--!strict
-- A temple hall: one room 20 by 12 on a floor of dark boards, its walls dark timber over white
-- plaster, lattice doors in the middle of the front, a veranda of boards round it behind a low
-- rail, and a tiled roof sweeping up at its corners over it all. A gravel path comes up to the
-- doors between two tall stone lanterns. (The user, with a picture of an old temple in a forest:
-- "Make another for this as well".)
--
-- The frame: x across, z back from the street. The room is x 6..26, z 8..20; the veranda runs
-- round it to x 4..28, z 6..22, and the roof's eaves reach a little past that.

local Lay = require(script.Parent.Kit.Lay)

type Finish = Lay.Finish

local BOARDS: Finish = { c = "6E5444", m = "WoodPlanks" }
local VERANDA: Finish = { c = "7A5E4A", m = "WoodPlanks" }
local OUTSIDE: Finish = { c = "EFE9DC", m = "WoodPlanks" }
local INSIDE: Finish = { c = "E2D2B8", m = "WoodPlanks" }
local RAIL: Finish = { c = "5C4636", m = "Wood" }
local GRAVEL: Finish = { c = "CFC8B8", m = "Pebble" }

local F = Lay.F
local put, hang = Lay.put, Lay.hang

return function(add: any)
	add(
		"show_temple_hall",
		"Temple hall",
		"A plastered hall with lattice doors and a veranda.",
		"pagoda",
		32,
		26,
		function(b: any)
			b:floor(6, 8, 26, 20, BOARDS)
			b:floor(4, 6, 28, 8, VERANDA)
			b:floor(4, 20, 28, 22, VERANDA)
			b:floor(4, 8, 6, 20, VERANDA)
			b:floor(26, 8, 28, 20, VERANDA)
			b:floor(14, 0, 18, 6, GRAVEL)
			b:box("", 6, 8, 26, 20, OUTSIDE, INSIDE)
			Lay.open(b, "door_temple", "front", 10)
			-- the timber frame over the plaster, all round
			for _, t in { 2, 18 } do
				hang(b, "temple_frame", "front", t, F, "a")
			end
			hang(b, "temple_frame_narrow", "front", 5, F, "a")
			hang(b, "temple_frame_narrow", "front", 15, F, "a")
			for _, t in { 2, 6, 10, 14, 18 } do
				hang(b, "temple_frame", "back", t, F, "a")
			end
			for _, t in { 2, 6, 10 } do
				hang(b, "temple_frame", "right", t, F, "a")
				hang(b, "temple_frame", "left", t, F, "a")
			end
			-- the rail round the veranda, open at the front for the path
			Lay.styled(b, "railfl", 4, 6, 14, 6, RAIL, "railing")
			Lay.styled(b, "railfr", 18, 6, 28, 6, RAIL, "railing")
			Lay.styled(b, "railr", 28, 6, 28, 22, RAIL, "railing")
			Lay.styled(b, "railb", 28, 22, 4, 22, RAIL, "railing")
			Lay.styled(b, "raill", 4, 22, 4, 6, RAIL, "railing")
			-- the roof, standing on the floor over the room
			put(b, "temple_roof", 16, 14, 0, Lay.level(1), nil, nil, 1)
			-- a lantern each side of the path
			put(b, "temple_lantern", 11, 2.4, 0)
			put(b, "temple_lantern", 21, 2.4, 0)
		end,
		"temple"
	)
end
