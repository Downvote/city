--!strict
-- What is laid flat on the town's ground on top of its streets and paving: patterns in the
-- paving, markings, covers and gratings (see docs/GAME_DESIGN.md, "A denser, more detailed
-- town"). TownMap.ground adds these to its own list.

local Geometry = require(script.Parent.Parent.Build.Geometry)

type Prim = Geometry.Prim

local StreetPaint = {}

-- The primitives inside `region` ({ x1, z1, x2, z2 }), or all of them.
function StreetPaint.ground(_region: { number }?): { Prim }
	return {}
end

return StreetPaint
