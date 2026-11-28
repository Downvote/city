--!strict
-- A temple gate: a roofed gate in a tiled wall, a run of wall either side of it and a gravel path
-- through, with a lantern each side inside. (The user, with a picture of an old temple in a
-- forest: "Make another for this as well".)
--
-- The frame: x across, z back from the street. The wall runs along z 6, x 0..12 and 20..32, and
-- the gate stands in the gap between.

local Lay = require(script.Parent.Kit.Lay)

type Finish = Lay.Finish

local WALL: Finish = { c = "F0ECE2", m = "Plaster" }
local GRAVEL: Finish = { c = "CFC8B8", m = "Pebble" }

local put = Lay.put

return function(add: any)
	add("show_temple_gate", "Temple gate", "A roofed gate in a tiled wall.", "tiledWall", 32, 12, function(b: any)
		Lay.styled(b, "wallw", 0, 6, 12, 6, WALL, "tiled")
		Lay.styled(b, "walle", 20, 6, 32, 6, WALL, "tiled")
		b:floor(14, 0, 18, 12, GRAVEL)
		put(b, "temple_gate", 16, 6, 0, 0)
		put(b, "temple_lantern", 9, 10, 0)
		put(b, "temple_lantern", 23, 10, 0)
	end, "temple")
end
