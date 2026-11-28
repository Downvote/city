--!strict
-- A long hall: one room 32 by 16 on a floor of dark boards, its front dark timber over white
-- plaster with a panelled skirt and a run of tall windows of small panes, two of them curtained,
-- board doors in its second bay under a little gabled porch, a long stone step along the front, a
-- straight tiled roof with its rafters' pale ends under the eaves, and an old drum by the porch.
-- (The user, with a picture of an old hall below a wooded hill: "Make a scene of the temple like
-- this".)
--
-- The frame: x across, z back from the street. The room is x 2..34, z 10..26; the roof's gable
-- ends reach out to x 0 and 36, and its eaves to z 7 and 29.

local Lay = require(script.Parent.Kit.Lay)

type Finish = Lay.Finish

local BOARDS: Finish = { c = "6B4423", m = "WoodPlanks" }
local OUTSIDE: Finish = { c = "F7F3EA", m = "Plaster" }
local INSIDE: Finish = { c = "EADBC0", m = "WoodPlanks" }

local F = Lay.F
local put, hang = Lay.put, Lay.hang

return function(add: any)
	add("show_long_hall", "Long hall", "A plastered hall with tall windows.", "pagoda", 36, 30, function(b: any)
		b:floor(2, 10, 34, 26, BOARDS)
		b:box("", 2, 10, 34, 26, OUTSIDE, INSIDE)
		-- the front: a plain panel, the doors, then windows
		for i = 0, 7 do
			local t = 2 + 4 * i
			if i == 0 then
				hang(b, "hall_panel", "front", t, F, "a")
			elseif i == 1 then
				Lay.open(b, "door_hall", "front", t)
				hang(b, "hall_panel_door", "front", t, F, "a")
			else
				Lay.open(b, if i == 3 or i == 6 then "win_hall_curtains" else "win_hall", "front", t)
				hang(b, "hall_panel_window", "front", t, F, "a")
			end
		end
		-- windows down the back between plain panels, plain panels at the ends
		for i = 0, 7 do
			local t = 2 + 4 * i
			if i % 2 == 1 then
				Lay.open(b, "win_hall", "back", t)
				hang(b, "hall_panel_window", "back", t, F, "a")
			else
				hang(b, "hall_panel", "back", t, F, "a")
			end
		end
		for _, wall in { "right", "left" } do
			for _, t in { 2, 6, 10, 14 } do
				hang(b, "hall_panel", wall, t, F, "a")
			end
		end
		-- the roof on the floor over the room: a gable end, two lengths, the other gable end
		local roofY = Lay.level(1)
		put(b, "hall_roof_end", 5, 18, 0, roofY, nil, nil, 1)
		put(b, "hall_roof", 14, 18, 0, roofY, nil, nil, 1)
		put(b, "hall_roof", 22, 18, 0, roofY, nil, nil, 1)
		put(b, "hall_roof_end", 31, 18, 180, roofY, nil, nil, 1)
		-- the step along the front, the porch over the doors and a drum beside it
		for _, x in { 6, 14, 22, 30 } do
			put(b, "hall_step", x, 8.15, 0)
		end
		put(b, "hall_porch", 8, 7, 180)
		put(b, "oil_drum", 14, 5.4, 0)
	end, "temple")
end
