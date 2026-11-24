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

-- round peaks: { x, z, height, radius }
local PEAKS = {
	{ 0, 640, 96, 230 },
	{ -380, 760, 75, 190 },
	{ 380, 760, 65, 200 },
	{ 860, 720, 57, 210 },
	{ -860, 720, 60, 200 },
	{ -700, 480, 23, 240 },
	{ 650, 520, 36, 220 },
	{ 200, 440, 21, 140 },
	{ -170, 470, 26, 150 },
}

-- flat tops where things stand: { name, x, z, radius } (their height is the hills' there)
Hills.Plateaus = {
	{ name = "lookout", x = 0, z = 640, r = 46 },
	{ name = "observatory", x = -380, z = 760, r = 40 },
	{ name = "farm", x = -700, z = 480, r = 130 },
	{ name = "camp", x = 650, z = 520, r = 86 },
	{ name = "radio", x = 380, z = 760, r = 30 },
	{ name = "tarn", x = 860, z = 720, r = 46 }, -- a mountain lake
	{ name = "stones", x = -860, z = 720, r = 34 }, -- a ring of standing stones
}

-- ground kept flat (at 0): { x1, z1, x2, z2 } with a soft edge. The creator's meadow.
local FLATS = {
	{ -600, 280, -120, 372 },
}

local function smoothstep(a: number, b: number, x: number): number
	local t = math.clamp((x - a) / (b - a), 0, 1)
	return t * t * (3 - 2 * t)
end

local function raw(x: number, z: number): number
	local h = 0
	for _, p in PEAKS do
		local dx, dz = x - p[1], z - p[2]
		h += p[3] * math.exp(-(dx * dx + dz * dz) / (p[4] * p[4]))
	end
	-- nothing at the edges: rising from Hill Road, down to the north shore and both ends
	local ez = smoothstep(Hills.Z1, Hills.Z1 + 120, z) * (1 - smoothstep(Hills.Z2 - 150, Hills.Z2 - 50, z))
	local ex = 1 - smoothstep(Hills.X2 - 170, Hills.X2 - 50, math.abs(x))
	return h * ez * ex
end

-- The plateaus' heights, worked out once.
local plateauH: { [string]: number } = {}
for _, p in Hills.Plateaus do
	plateauH[p.name] = raw(p.x, p.z)
end

-- The height of the hills, worked out from the peaks, the flat tops and the meadow.
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
		h *= smoothstep(0, 70, d)
	end
	return h
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
