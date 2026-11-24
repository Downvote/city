--!strict
-- The hills north of Hill Road: a smooth height function (a few round peaks, flattened where
-- things stand on them, nothing at the edges). Shared and free of services, so the terrain
-- (Data/Terrain) is filled from it, the preview draws it and the specs check it.
--
-- `Hills.at(x, z)` gives the height of the hills there, so things placed on the hills sit on
-- them. (They were drawn as flat triangles of parts, a faceted low poly landscape, until the
-- user asked for Roblox's own terrain grass: "make the grass and plants like in the image".)

local Hills = {}

Hills.X1, Hills.X2 = -1100, 1100
Hills.Z1, Hills.Z2 = 290, 940

-- Behind the old town the hills start further north: its plots run 400 back from the main street
-- (the user: "make player plots much bigger, double the size") and Hill Road runs behind them,
-- so between the first avenues the foot of the hills is `depth` further north, and beside them it
-- eases back to Z1 over `ease`. Past that, in front of downtown and the civic quarter, the hills
-- are as they always were.
Hills.Notch = { half = 560, ease = 160, depth = 200 }
Hills.Rise = 120 -- the hills come up from nothing over this much, north of their foot

-- round peaks: { x, z, height, radius }. (The lookout's moved north, and lost a little height, when
-- the old town grew; the two small ones that stood behind the old town went north with it.)
local PEAKS = {
	{ 0, 720, 80, 230 },
	{ -380, 760, 75, 190 },
	{ 380, 760, 65, 200 },
	{ 860, 720, 57, 210 },
	{ -860, 720, 60, 200 },
	{ -800, 480, 23, 240 },
	{ 780, 490, 30, 220 },
	{ 220, 620, 18, 130 },
	{ -190, 630, 22, 140 },
}

-- flat tops where things stand: { name, x, z, radius } (their height is the hills' there). The
-- farm and the camp stand clear of the notch behind the old town, the stones out of the farm's way.
Hills.Plateaus = {
	{ name = "lookout", x = 0, z = 720, r = 46 },
	{ name = "observatory", x = -380, z = 760, r = 40 },
	{ name = "farm", x = -800, z = 480, r = 130 },
	{ name = "camp", x = 780, z = 490, r = 86 },
	{ name = "radio", x = 380, z = 760, r = 30 },
	{ name = "tarn", x = 860, z = 720, r = 46 }, -- a mountain lake
	{ name = "stones", x = -920, z = 750, r = 34 }, -- a ring of standing stones
}

-- ground kept flat (at 0): { x1, z1, x2, z2 } with a soft edge. The creator's meadow, behind Hill
-- Road west of the stair.
local FLATS = {
	{ -540, 480, -300, 566 },
}

local function smoothstep(a: number, b: number, x: number): number
	local t = math.clamp((x - a) / (b - a), 0, 1)
	return t * t * (3 - 2 * t)
end

-- Where the hills start at x: Z1, or `depth` further north behind the old town.
function Hills.foot(x: number): number
	local N = Hills.Notch
	return Hills.Z1 + N.depth * (1 - smoothstep(N.half, N.half + N.ease, math.abs(x)))
end

-- How much of the hills stands at x, z for the notch behind the old town: nothing south of the
-- notch's foot between the first avenues, all of them past the notch's sides.
local function notch(x: number, z: number): number
	local N = Hills.Notch
	local z0 = Hills.Z1 + N.depth
	local inside = 1 - smoothstep(N.half, N.half + N.ease, math.abs(x))
	return 1 - inside * (1 - smoothstep(z0, z0 + Hills.Rise, z))
end

local function raw(x: number, z: number): number
	local h = 0
	for _, p in PEAKS do
		local dx, dz = x - p[1], z - p[2]
		h += p[3] * math.exp(-(dx * dx + dz * dz) / (p[4] * p[4]))
	end
	-- nothing at the edge by the town: rising from Hill Road
	return h * smoothstep(Hills.Z1, Hills.Z1 + Hills.Rise, z)
end

-- Down to the shore at the north and at both ends. (This goes on after the flat tops are
-- worked in, over a good width, so the hills come down to the beach as slopes and not as a
-- wall behind the observatory and the mast: the hills are smooth terrain now, and a drop the
-- facets once spread over a cell would show.)
local function shores(x: number, z: number): number
	return (1 - smoothstep(Hills.Z2 - 165, Hills.Z2 - 5, z))
		* (1 - smoothstep(Hills.X2 - 170, Hills.X2 - 10, math.abs(x)))
end

-- The plateaus' heights, worked out once.
local plateauH: { [string]: number } = {}
for _, p in Hills.Plateaus do
	plateauH[p.name] = raw(p.x, p.z)
end

-- The height of the hills, worked out from the peaks, the flat tops and the meadow, and cut
-- back behind the old town.
function Hills.smooth(x: number, z: number): number
	local h = raw(x, z)
	for _, p in Hills.Plateaus do
		local d = math.sqrt((x - p.x) ^ 2 + (z - p.z) ^ 2)
		if d < p.r + 60 then
			local k = 1 - smoothstep(p.r, p.r + 60, d)
			h = h + (plateauH[p.name] - h) * k
		end
	end
	for _, f in FLATS do
		local dx = math.max(f[1] - x, 0, x - f[3])
		local dz = math.max(f[2] - z, 0, z - f[4])
		local d = math.sqrt(dx * dx + dz * dz)
		h *= smoothstep(0, 150, d)
	end
	return h * notch(x, z) * shores(x, z)
end

-- The height of a plateau's flat top.
function Hills.plateau(name: string): number
	return plateauH[name] or 0
end

-- The height of the ground at x, z (0 off the hills). The hills are Roblox terrain
-- (Data/Terrain fills it to this height less a tenth, the island's grass), so things placed
-- on the hills at `at` less a tenth sit on it exactly.
function Hills.at(x: number, z: number): number
	if x < Hills.X1 or x >= Hills.X2 or z < Hills.Z1 or z >= Hills.Z2 then
		return 0
	end
	local h = Hills.smooth(x, z)
	-- (a trace of height at the foot is the grass itself)
	return if h < 0.01 then 0 else h
end

-- How steep the surface is at x, z (rise over run).
function Hills.slope(x: number, z: number): number
	local e = 4
	local gx = (Hills.at(x + e, z) - Hills.at(x - e, z)) / (2 * e)
	local gz = (Hills.at(x, z + e) - Hills.at(x, z - e)) / (2 * e)
	return math.sqrt(gx * gx + gz * gz)
end

return Hills
