--!strict
-- Worn edges for the town's own models (the user: "for edges and corners where faces meet, is
-- it possible to detail and weather them such that edges have weathering detail on their
-- textures or is smoothed?"). Roblox shades a part's edges as sharp as a knife, so where an edge
-- is looked at closely (a counter's top, a step, a kerb, a table) it is drawn worn off: a slab
-- whose top edges are cut back at 45 degrees, the cut a little darker than the face, as an edge
-- goes that hands and feet have rubbed for years.
--
-- The cut is a wedge along each edge, sat on the slab's body; the top is set in by the cut's
-- width on those sides. Where two cut edges meet, the corner is left open by a cube of `e`,
-- too small to see.

local Geometry = require(script.Parent.Parent.Build.Geometry)
local Recipe = require(script.Parent.Parent.Build.Recipe)

type R = Recipe.Recipe
type Prim = Geometry.Prim

local Edging = {}

-- How much darker a worn cut is than the face it runs along.
Edging.Wear = 0.9

local function shade(c: Color3, k: number): Color3
	return Color3.new(math.min(1, c.R * k), math.min(1, c.G * k), math.min(1, c.B * k))
end

export type Sides = { front: boolean?, back: boolean?, left: boolean?, right: boolean? }

-- Every side.
Edging.All = { front = true, back = true, left = true, right = true } :: Sides
-- The front (-Z) and the two ends: a counter or a desk against a wall.
Edging.Open = { front = true, left = true, right = true } :: Sides
-- Only the front: a step, a kerb seen from the road.
Edging.Front = { front = true } :: Sides

-- A slab from (x1, y1, z1) to (x2, y2, z2) on `q` with its top edges on `sides` worn off by `e`
-- (front is -Z, left -X). Returns the shapes, the body first.
function Edging.slab(
	q: R,
	x1: number,
	y1: number,
	z1: number,
	x2: number,
	y2: number,
	z2: number,
	color: Color3,
	mat: string,
	e: number,
	sides: Sides
): { Prim }
	if x1 > x2 then
		x1, x2 = x2, x1
	end
	if y1 > y2 then
		y1, y2 = y2, y1
	end
	if z1 > z2 then
		z1, z2 = z2, z1
	end
	e = math.min(e, (y2 - y1) * 0.5, (x2 - x1) * 0.25, (z2 - z1) * 0.25)
	local out: { Prim } = {}
	table.insert(out, q:block(x1, y1, z1, x2, y2 - e, z2, color, mat))
	local ix1 = if sides.left then x1 + e else x1
	local ix2 = if sides.right then x2 - e else x2
	local iz1 = if sides.front then z1 + e else z1
	local iz2 = if sides.back then z2 - e else z2
	table.insert(out, q:block(ix1, y2 - e, iz1, ix2, y2, iz2, color, mat))
	local worn = shade(color, Edging.Wear)
	local y = y2 - e / 2
	-- (a wedge is full height at its back, +Z, and slopes down to its front: turned so its back
	-- is toward the slab's middle)
	if sides.front then
		table.insert(out, q:wedge(CFrame.new((ix1 + ix2) / 2, y, z1 + e / 2), ix2 - ix1, e, e, worn, mat))
	end
	if sides.back then
		local cf = CFrame.new((ix1 + ix2) / 2, y, z2 - e / 2) * CFrame.Angles(0, math.pi, 0)
		table.insert(out, q:wedge(cf, ix2 - ix1, e, e, worn, mat))
	end
	if sides.left then
		local cf = CFrame.new(x1 + e / 2, y, (iz1 + iz2) / 2) * CFrame.Angles(0, math.pi / 2, 0)
		table.insert(out, q:wedge(cf, iz2 - iz1, e, e, worn, mat))
	end
	if sides.right then
		local cf = CFrame.new(x2 - e / 2, y, (iz1 + iz2) / 2) * CFrame.Angles(0, -math.pi / 2, 0)
		table.insert(out, q:wedge(cf, iz2 - iz1, e, e, worn, mat))
	end
	return out
end

return Edging
