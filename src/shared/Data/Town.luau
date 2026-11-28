--!strict
-- The town's layout: where the plots, the street and the plaza are. Shared so the client can find
-- its plot's frame and the server can build the map.
--
-- The main street runs along X through z = 0. Plots line both sides of it, two each, with the
-- town square between the two on the north side and the market between the two on the south.
-- Each plot has its own frame: local x and z run 0..Plot.Size, local z = 0 is the street edge.
--
-- Round that old town a ring of roads: Hill Road along the north (the hills rise behind it),
-- Harbour Road along the south (the boardwalk, beach and sea beyond), and avenues at either end.
-- The plots are 400 deep (the user: "make player plots much bigger, double the size"), so the
-- ring runs well out past them, and the old town reaches south into the sea as a cape. East of
-- the ring is downtown, a grid of towers; west of it the civic quarter with the school, the
-- clinic, the museum and a park. Their own blocks are as deep as the old town used to be, so in
-- front of them the ring keeps to its old line (OuterRingZ) and meets the old town's stretch at
-- the first avenues.
--
-- Then the user: "could you make the max plots 6, expanding the map for it?" Two more plots of the
-- same size stand on the north side of Hill Road, back to back with the first two, between the
-- first avenues, which now run on north past them to Ridge Road (RidgeZ). The hills start behind
-- Ridge Road, and the island reaches that much further north.

local Tuning = require(script.Parent.Parent.Config.Tuning)

local Town = {}

local SIZE = Tuning.Plot.Size

Town.StreetHalfWidth = 14
Town.SidewalkWidth = 8 -- runs right up to the plots
Town.PlotSetback = 22 -- plot front edge distance from the street's middle
Town.PlotCentersX = { -266, 266 } -- the plots on each side of the street, west to east
Town.SquareCenter = Vector3.new(0, 0, 82)
Town.MarketCenter = Vector3.new(0, 0, -82)
Town.HalfLength = 1080 -- the main street runs from -HalfLength to HalfLength

-- The main street's own zebra crossings: in front of the square and the market, and out past
-- the plots at either end, between them and the avenues (the footbridge stands over the east one).
Town.MainCrossings = { 0, -490, 490 }

-- The other roads, axis aligned: { x1, z1, x2, z2, half width, sidewalk width }. The main street
-- (z = 0, StreetHalfWidth, SidewalkWidth) is the first.
Town.RingZ = 462 -- Hill Road at +RingZ, Harbour Road at -RingZ, round the old town
Town.OuterRingZ = 262 -- and in front of downtown and the civic quarter, past the first avenues
Town.RidgeZ = 922 -- Ridge Road, behind the plots on the north side of Hill Road
-- The plots on Hill Road stand back from its middle by this: past its pavement (11 + 6) and a
-- verge of grass 3 wide, so their corners lie 2 off the terrain's 4 stud grid as every plot's do
-- (Build/Water and Build/Basement count on it).
Town.HillSetback = 20
Town.AvenueX = { 542, 830, 1070 } -- avenues at these x, and at minus them
Town.CrossZ = 131 -- downtown and civic cross streets at plus and minus this
Town.Roads = {
	{ -1080, 0, 1080, 0, 14, 8, name = "Main Street" },
	{ -542, 462, 542, 462, 11, 6, name = "Hill Road" },
	{ -542, -462, 542, -462, 11, 6, name = "Harbour Road" },
} :: { any }
for k, x in Town.AvenueX do
	-- (the first avenues run on to the old town's stretch of the ring, and north past the plots
	-- on Hill Road to Ridge Road)
	local z1 = if k == 1 then -Town.RingZ else -Town.OuterRingZ
	local z2 = if k == 1 then Town.RidgeZ else Town.OuterRingZ
	for _, sx in { 1, -1 } do
		table.insert(Town.Roads, { sx * x, z1, sx * x, z2, 11, 6 })
	end
end
table.insert(Town.Roads, { -542, Town.RidgeZ, 542, Town.RidgeZ, 11, 6, name = "Ridge Road" })
for _, sx in { 1, -1 } do
	for _, z in { 131, -131 } do
		local a, b = 542, 1070
		table.insert(Town.Roads, { sx * a, z, sx * b, z, 11, 6 })
	end
end
-- The ring's stretches past the first avenues, on its old line along the backs of downtown and the
-- civic quarter: streets of their own now, with their own names on the plates.
for _, r in
	{
		{ 542, 262, 1070, 262, "Hillside Row" },
		{ -1070, 262, -542, 262, "Mill Row" },
		{ 542, -262, 1070, -262, "Quay Street" },
		{ -1070, -262, -542, -262, "Strand Road" },
	} :: { { any } }
do
	table.insert(Town.Roads, { r[1], r[2], r[3], r[4], 11, 6, name = r[5] })
end

-- Where the ring runs at x: the old town's stretch between the first avenues, the old line past
-- them.
function Town.ringAt(x: number): number
	return if math.abs(x) <= Town.AvenueX[1] then Town.RingZ else Town.OuterRingZ
end

-- How far north the town's roads reach at x: Ridge Road between the first avenues, the old line
-- past them.
function Town.northAt(x: number): number
	return if math.abs(x) <= Town.AvenueX[1] then Town.RidgeZ else Town.OuterRingZ
end

-- The districts, for the map: { name, x1, z1, x2, z2 }.
Town.Districts = {
	{ name = "Old Town", x1 = -525, z1 = -445, x2 = 525, z2 = 905 },
	{ name = "Downtown", x1 = 559, z1 = -245, x2 = 1053, z2 = 245 },
	{ name = "Civic Quarter", x1 = -1053, z1 = -245, x2 = -559, z2 = 245 },
	{ name = "The Hills", x1 = -1100, z1 = 290, x2 = 1100, z2 = 1380 },
	{ name = "Waterfront", x1 = -1070, z1 = -540, x2 = 1070, z2 = -279 },
}

-- Where the villager creator's stage stands: a flat meadow just north of Ridge Road, the town
-- behind it. Stages for several players line up westward from here.
Town.CreatorSpot = Vector3.new(-330, 0, 990)
Town.CreatorGap = 34
-- How high over the meadow the stage floats. Nothing of the town is near it up there, so the
-- creator can stand its own backdrop behind the mannequin.
Town.CreatorHeight = 420

-- The rows of plots, a row to each side of a street: the street's middle (z), the side the plots
-- stand on (1 north, -1 south) and how far back from the middle their fronts are. Each row has a
-- plot at each of PlotCentersX, west to east.
Town.PlotRows = {
	{ z = 0, side = 1, setback = Town.PlotSetback }, -- plots 1 and 2, north of Main Street
	{ z = 0, side = -1, setback = Town.PlotSetback }, -- 3 and 4, south of it
	{ z = Town.RingZ, side = 1, setback = Town.HillSetback }, -- 5 and 6, north of Hill Road
}

-- The row plot i is in.
function Town.plotRow(i: number): { z: number, side: number, setback: number }
	return Town.PlotRows[math.floor((i - 1) / #Town.PlotCentersX) + 1]
end

-- The frame of plot i (1..Plot.Count): its local origin is the front left corner, seen from the
-- street. Row by row (Town.PlotRows), west to east; those south of their street are turned.
function Town.plotFrame(i: number): CFrame
	local per = #Town.PlotCentersX
	local row = Town.plotRow(i)
	local cx = Town.PlotCentersX[(i - 1) % per + 1]
	if row.side > 0 then
		return CFrame.new(cx - SIZE / 2, 0, row.z + row.setback)
	end
	return CFrame.new(cx + SIZE / 2, 0, row.z - row.setback) * CFrame.Angles(0, math.pi, 0)
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
