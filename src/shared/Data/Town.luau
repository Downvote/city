--!strict
-- The town's layout: where the plots, the street and the plaza are. Shared so the client can find
-- its plot's frame and the server can build the map.
--
-- The main street runs along X through z = 0. Plots line both sides of it, four each, with the town
-- square on the north side of the middle and the market on the south. Each plot has its own
-- frame: local x and z run 0..Plot.Size, local z = 0 is the street edge.
--
-- Round that old town a ring of roads: Hill Road along the north (the hills rise behind it),
-- Harbour Road along the south (the boardwalk, beach and sea beyond), and avenues at either end.
-- East of the ring is downtown, a grid of towers; west of it the civic quarter with the school,
-- the clinic, the museum and a park.

local Tuning = require(script.Parent.Parent.Config.Tuning)

local Town = {}

local SIZE = Tuning.Plot.Size

Town.StreetHalfWidth = 14
Town.SidewalkWidth = 8 -- runs right up to the plots
Town.PlotSetback = 22 -- plot front edge distance from the street's middle
Town.PlotCentersX = { -382, -166, 166, 382 }
Town.SquareCenter = Vector3.new(0, 0, 82)
Town.MarketCenter = Vector3.new(0, 0, -82)
Town.HalfLength = 1080 -- the main street runs from -HalfLength to HalfLength

-- The other roads, axis aligned: { x1, z1, x2, z2, half width, sidewalk width }. The main street
-- (z = 0, StreetHalfWidth, SidewalkWidth) is the first.
Town.RingZ = 262 -- Hill Road at +RingZ, Harbour Road at -RingZ
Town.AvenueX = { 542, 830, 1070 } -- avenues at these x, and at minus them
Town.CrossZ = 131 -- downtown and civic cross streets at plus and minus this
Town.Roads = {
	{ -1080, 0, 1080, 0, 14, 8, name = "Main Street" },
	{ -1070, 262, 1070, 262, 11, 6, name = "Hill Road" },
	{ -1070, -262, 1070, -262, 11, 6, name = "Harbour Road" },
} :: { any }
for _, x in Town.AvenueX do
	for _, sx in { 1, -1 } do
		table.insert(Town.Roads, { sx * x, -262, sx * x, 262, 11, 6 })
	end
end
for _, sx in { 1, -1 } do
	for _, z in { 131, -131 } do
		local a, b = 542, 1070
		table.insert(Town.Roads, { sx * a, z, sx * b, z, 11, 6 })
	end
end

-- The districts, for the map: { name, x1, z1, x2, z2 }.
Town.Districts = {
	{ name = "Old Town", x1 = -525, z1 = -245, x2 = 525, z2 = 245 },
	{ name = "Downtown", x1 = 559, z1 = -245, x2 = 1053, z2 = 245 },
	{ name = "Civic Quarter", x1 = -1053, z1 = -245, x2 = -559, z2 = 245 },
	{ name = "The Hills", x1 = -1100, z1 = 290, x2 = 1100, z2 = 920 },
	{ name = "Waterfront", x1 = -1070, z1 = -340, x2 = 1070, z2 = -279 },
}

-- Where the villager creator's stage stands: a flat meadow just north of Hill Road, the town
-- behind it. Stages for several players line up westward from here.
Town.CreatorSpot = Vector3.new(-330, 0, 318)
Town.CreatorGap = 34
-- How high over the meadow the stage floats. Nothing of the town is near it up there, so the
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

-- Spots of interest in the plaza (world space).
Town.Spots = {
	Fountain = Vector3.new(0, 0, 80),
	Board = Vector3.new(-24, 0, 40),
	Tailor = Vector3.new(30, 0, 48),
	Shop = Vector3.new(-26, 0, -48),
	Hall = Vector3.new(0, 0, -124),
	Spawn = Vector3.new(0, 0, 58),
	Festival = Vector3.new(0, 0, 106), -- in front of the bandstand
}

return Town
