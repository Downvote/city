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
Town.AvenueX = { 542, 830, 1070 } -- avenues at these x, and at minus them
Town.CrossZ = 131 -- downtown and civic cross streets at plus and minus this
Town.Roads = {
	{ -1080, 0, 1080, 0, 14, 8, name = "Main Street" },
	{ -542, 462, 542, 462, 11, 6, name = "Hill Road" },
	{ -542, -462, 542, -462, 11, 6, name = "Harbour Road" },
	-- (the ring's stretches past the first avenues, on its old line)
	{ 542, 262, 1070, 262, 11, 6, name = "Hill Road" },
	{ -1070, 262, -542, 262, 11, 6, name = "Hill Road" },
	{ 542, -262, 1070, -262, 11, 6, name = "Harbour Road" },
	{ -1070, -262, -542, -262, 11, 6, name = "Harbour Road" },
} :: { any }
for k, x in Town.AvenueX do
	-- (the first avenues run on to the old town's stretch of the ring)
	local z = if k == 1 then Town.RingZ else Town.OuterRingZ
	for _, sx in { 1, -1 } do
		table.insert(Town.Roads, { sx * x, -z, sx * x, z, 11, 6 })
	end
end
for _, sx in { 1, -1 } do
	for _, z in { 131, -131 } do
		local a, b = 542, 1070
		table.insert(Town.Roads, { sx * a, z, sx * b, z, 11, 6 })
	end
end

-- Where the ring runs at x: the old town's stretch between the first avenues, the old line past
-- them.
function Town.ringAt(x: number): number
	return if math.abs(x) <= Town.AvenueX[1] then Town.RingZ else Town.OuterRingZ
end

-- The districts, for the map: { name, x1, z1, x2, z2 }.
Town.Districts = {
	{ name = "Old Town", x1 = -525, z1 = -445, x2 = 525, z2 = 445 },
	{ name = "Downtown", x1 = 559, z1 = -245, x2 = 1053, z2 = 245 },
	{ name = "Civic Quarter", x1 = -1053, z1 = -245, x2 = -559, z2 = 245 },
	{ name = "The Hills", x1 = -1100, z1 = 290, x2 = 1100, z2 = 920 },
	{ name = "Waterfront", x1 = -1070, z1 = -540, x2 = 1070, z2 = -279 },
}

-- Where the villager creator's stage stands: a flat meadow just north of Hill Road, the town
-- behind it. Stages for several players line up westward from here.
Town.CreatorSpot = Vector3.new(-330, 0, 530)
Town.CreatorGap = 34
-- How high over the meadow the stage floats. Nothing of the town is near it up there, so the
-- creator can stand its own backdrop behind the mannequin.
Town.CreatorHeight = 420

-- The frame of plot i (1..Plot.Count): its local origin is the front left corner, seen from the
-- street. The first ones are north of the street, west to east, the rest south of it, turned.
function Town.plotFrame(i: number): CFrame
	local per = #Town.PlotCentersX
	local north = i <= per
	local cx = Town.PlotCentersX[(i - 1) % per + 1]
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
