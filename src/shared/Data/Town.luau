--!strict
-- The town's layout: where the plots, the street and the plaza are. Shared so the client can find
-- its plot's frame and the server can build the map.
--
-- The street runs along X through z = 0. Plots line both sides of it, four each, with the town
-- square on the north side of the middle and the market and the gate out of town on the south.
-- Each plot has its own frame: local x and z run 0..Plot.Size, local z = 0 is the street edge.

local Tuning = require(script.Parent.Parent.Config.Tuning)

local Town = {}

local SIZE = Tuning.Plot.Size

Town.StreetHalfWidth = 14
Town.SidewalkWidth = 6
Town.PlotSetback = 22 -- plot front edge distance from the street's middle
Town.PlotCentersX = { -382, -166, 166, 382 }
Town.SquareCenter = Vector3.new(0, 0, 82)
Town.MarketCenter = Vector3.new(0, 0, -82)
Town.HalfLength = 520 -- street runs from -HalfLength to HalfLength

-- The frame of plot i (1..8): its local origin is the front left corner, seen from the street.
function Town.plotFrame(i: number): CFrame
	local north = i <= 4
	local cx = Town.PlotCentersX[(i - 1) % 4 + 1]
	if north then
		return CFrame.new(cx - SIZE / 2, 0, Town.PlotSetback)
	end
	return CFrame.new(cx + SIZE / 2, 0, -Town.PlotSetback) * CFrame.Angles(0, math.pi, 0)
end

function Town.plotCenter(i: number): Vector3
	return Town.plotFrame(i) * Vector3.new(SIZE / 2, 0, SIZE / 2)
end

-- Where a player arrives on their plot: on the sidewalk in front of it, facing in.
function Town.plotArrival(i: number): CFrame
	local f = Town.plotFrame(i)
	local pos = f * Vector3.new(SIZE / 2, 3, -4)
	local look = f * Vector3.new(SIZE / 2, 3, 20)
	return CFrame.lookAt(pos, look)
end

-- Is a world position on plot i? Returns the plot-local position too.
function Town.toPlot(i: number, world: Vector3): (boolean, Vector3)
	local p = Town.plotFrame(i):PointToObjectSpace(world)
	return p.X >= 0 and p.X <= SIZE and p.Z >= 0 and p.Z <= SIZE, p
end

-- Spots of interest in the plaza (world space).
Town.Spots = {
	Fountain = Vector3.new(0, 0, 80),
	Board = Vector3.new(-24, 0, 40),
	Tailor = Vector3.new(30, 0, 48),
	Shop = Vector3.new(-26, 0, -48),
	Hall = Vector3.new(0, 0, -124),
	Spawn = Vector3.new(0, 0, 58),
	Festival = Vector3.new(0, 0, 95),
}

return Town
