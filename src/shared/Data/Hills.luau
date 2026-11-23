--!strict
-- The hills north of Hill Road, as a faceted low poly landscape: a smooth height function
-- (a few round peaks, flattened where things stand on them), sampled on a grid and drawn as
-- flat triangles, so the slopes catch the light in facets. Shared and free of services, so the
-- World service builds it, the preview draws it and the specs check it.
--
-- `Hills.at(x, z)` gives the height of the drawn surface (what you'd stand on), so things placed
-- on the hills sit on it exactly.

local Geometry = require(script.Parent.Parent.Build.Geometry)

type Prim = Geometry.Prim

local Hills = {}

Hills.X1, Hills.X2 = -1100, 1100
Hills.Z1, Hills.Z2 = 290, 940
Hills.Cell = 50
Hills.Thickness = 1.2

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

-- The smooth height (before it's drawn as facets).
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

-- the grid of heights, computed once
local nx = math.floor((Hills.X2 - Hills.X1) / Hills.Cell)
local nz = math.floor((Hills.Z2 - Hills.Z1) / Hills.Cell)
local grid: { { number } } = {}
for i = 0, nx do
	local col = {}
	for j = 0, nz do
		col[j + 1] = Hills.smooth(Hills.X1 + i * Hills.Cell, Hills.Z1 + j * Hills.Cell)
	end
	grid[i + 1] = col
end

local function node(i: number, j: number): number
	if i < 0 or j < 0 or i > nx or j > nz then
		return 0
	end
	return grid[i + 1][j + 1]
end

-- Which way a cell is split into its two triangles (alternating, for a less regular look).
local function diag(i: number, j: number): boolean
	return (i + j) % 2 == 0
end

-- The height of the drawn surface at x, z (0 off the hills).
function Hills.at(x: number, z: number): number
	if x < Hills.X1 or x >= Hills.X2 or z < Hills.Z1 or z >= Hills.Z2 then
		return 0
	end
	local fx = (x - Hills.X1) / Hills.Cell
	local fz = (z - Hills.Z1) / Hills.Cell
	local i, j = math.floor(fx), math.floor(fz)
	local u, v = fx - i, fz - j
	local h00, h10, h01, h11 = node(i, j), node(i + 1, j), node(i, j + 1), node(i + 1, j + 1)
	if h00 < 0.3 and h10 < 0.3 and h01 < 0.3 and h11 < 0.3 then
		return 0 -- a flat cell isn't drawn: the island's grass is underneath
	end
	local h
	if diag(i, j) then
		if u >= v then
			h = h00 + (h10 - h00) * u + (h11 - h10) * v
		else
			h = h00 + (h11 - h01) * u + (h01 - h00) * v
		end
	else
		if u + v <= 1 then
			h = h00 + (h10 - h00) * u + (h01 - h00) * v
		else
			h = h11 + (h01 - h11) * (1 - u) + (h10 - h11) * (1 - v)
		end
	end
	return h + Hills.Thickness / 2
end

-- How steep the surface is at x, z (rise over run).
function Hills.slope(x: number, z: number): number
	local e = 4
	local gx = (Hills.at(x + e, z) - Hills.at(x - e, z)) / (2 * e)
	local gz = (Hills.at(x, z + e) - Hills.at(x, z - e)) / (2 * e)
	return math.sqrt(gx * gx + gz * gz)
end

local GRASS = {
	Color3.fromRGB(112, 188, 84),
	Color3.fromRGB(122, 196, 88),
	Color3.fromRGB(104, 180, 80),
}
local HIGH = Color3.fromRGB(150, 200, 96)
local STEEP = Color3.fromRGB(84, 150, 70)

-- The hills as flat triangles. `region` { x1, z1, x2, z2 } keeps only the cells inside it.
function Hills.prims(region: { number }?): { Prim }
	local out: { Prim } = {}
	local function tri(a: Vector3, b: Vector3, c: Vector3, k: number)
		local avg = (a.Y + b.Y + c.Y) / 3
		local n = (b - a):Cross(c - a)
		local steep = if n.Magnitude > 0 then 1 - math.abs(n.Unit.Y) else 0
		local col = GRASS[k % #GRASS + 1]
		col = col:Lerp(HIGH, math.clamp(avg / 90, 0, 0.6))
		col = col:Lerp(STEEP, math.clamp(steep * 2.2, 0, 0.7))
		for _, p in Geometry.triangle(a, b, c, Hills.Thickness, col, "Grass") do
			p.name = "Hill"
			table.insert(out, p)
		end
	end
	for i = 0, nx - 1 do
		for j = 0, nz - 1 do
			local h00, h10, h01, h11 = node(i, j), node(i + 1, j), node(i, j + 1), node(i + 1, j + 1)
			if h00 >= 0.3 or h10 >= 0.3 or h01 >= 0.3 or h11 >= 0.3 then
				local x0, z0 = Hills.X1 + i * Hills.Cell, Hills.Z1 + j * Hills.Cell
				local x1, z1 = x0 + Hills.Cell, z0 + Hills.Cell
				local cx, cz = (x0 + x1) / 2, (z0 + z1) / 2
				if not region or (cx >= region[1] and cx <= region[3] and cz >= region[2] and cz <= region[4]) then
					local p00 = Vector3.new(x0, h00, z0)
					local p10 = Vector3.new(x1, h10, z0)
					local p01 = Vector3.new(x0, h01, z1)
					local p11 = Vector3.new(x1, h11, z1)
					local k = i * 7 + j * 13
					if diag(i, j) then
						tri(p00, p10, p11, k)
						tri(p00, p11, p01, k + 1)
					else
						tri(p00, p10, p01, k)
						tri(p10, p11, p01, k + 1)
					end
				end
			end
		end
	end
	return out
end

return Hills
