--!strict
-- The town's layout: where the plots, the street and the middle of town are. Shared so the client
-- can find its plot's frame and the server can build the map.
--
-- The town is the user's city pack (Data/CityPack, laid out by Data/CityMap). Main Street is the
-- pack suburb's road to the bridge, running along X through z = 0: two lanes each way with a
-- planted strip between them. The eight plots line it where the suburb's houses stood, four each
-- side, their front edge at the back of the sidewalk. Each plot has its own frame: local x and z
-- run 0..Plot.Size, local z = 0 is the street edge.
--
-- West of the plots Main Street climbs onto the motorway; east of them is the middle of town (the
-- green by the river with the spawn, the tailor's and the news board, the city hall across the
-- road), then the bridge over the river to downtown.

local Tuning = require(script.Parent.Parent.Config.Tuning)

local Town = {}

local SIZE = Tuning.Plot.Size

Town.StreetHalfWidth = 30.5 -- the carriageway, curb to curb
Town.SidewalkWidth = 7 -- runs right up to the plots
Town.PlotSetback = 38 -- plot front edge distance from the street's middle
Town.PlotCentersX = { -312, -104, 104, 312 }
-- Main Street's ends: the top of the motorway ramp in the west, the junction in downtown in the east
-- (Data/CityMap's StreetProfile has its height along the way)
Town.StreetWest = -497
Town.StreetEast = 1328

-- The roads the town's cars use, axis aligned: { x1, z1, x2, z2, half width, sidewalk width }.
-- Main Street is the first. Where people cross it: the gaps between the plots and the middle of town.
Town.Roads = {
	{ -497, 0, 1328, 0, 30.5, 7, name = "Main Street" },
} :: { any }
Town.Crossings = { -208, 0, 208, 416, 596 }

-- Where the villager creator's stage stands: high over the beach north of the plots, between two
-- of its huts, the sea beyond it. Stages for several players line up westward from here.
Town.CreatorSpot = Vector3.new(288, 0, -600)
Town.CreatorGap = 34
-- How high over the beach the stage floats. Nothing of the town is near it up there, so the
-- creator can stand its own backdrop behind the mannequin.
Town.CreatorHeight = 420

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

-- Spots of interest in the middle of town (world space): the spawn and the festival spot on the
-- green, and the doors of the news board, the tailor's and the city hall (Data/CityMap puts them).
Town.Spots = {
	Spawn = Vector3.new(680, 0, -88),
	Festival = Vector3.new(684, 0, -128),
	Board = Vector3.new(652, 0, -56),
	Tailor = Vector3.new(615, 0, -36.6),
	Hall = Vector3.new(643, 0, 39.5),
}

return Town
