--!strict
-- The town's street buildings, drawn from a kit of facade parts (see docs/GAME_DESIGN.md, "A
-- denser, more detailed town"). TownMap.prims asks here first for a model by name.

local Geometry = require(script.Parent.Parent.Build.Geometry)

type Prim = Geometry.Prim

local Facades = {}

-- The primitives of the model called `name`, or nil if it isn't one of these.
function Facades.prims(_name: string): { Prim }?
	return nil
end

return Facades
