--!strict
-- The town's set pieces: the things you find your way by (see docs/GAME_DESIGN.md, "A denser,
-- more detailed town"). TownMap.prims asks here for a model by name, and TownMap.placements adds
-- where they stand before the street scene goes on round them.

local Geometry = require(script.Parent.Parent.Build.Geometry)

type Prim = Geometry.Prim
export type Placement = { name: string, cf: CFrame, action: string?, opens: string?, tag: string? }

local Landmarks = {}

-- The primitives of the model called `name`, or nil if it isn't one of these.
function Landmarks.prims(_name: string): { Prim }?
	return nil
end

-- Where each one stands.
function Landmarks.placements(): { Placement }
	return {}
end

return Landmarks
