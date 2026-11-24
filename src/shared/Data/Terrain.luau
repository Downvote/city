--!strict
-- The island's natural ground as Roblox terrain: the grass and the hills, a sandy beach all the
-- way round whose edge at the water is a run of soft curves, the shallows and the deep sea. The
-- user: "the shoreline should be wavy, with water lapping up to it", then, with a picture of a
-- Roblox place covered in tall golden green grass, "make the grass and plants like in the image".
-- So the grass is Roblox's own terrain grass with its long blades (Terrain.Decoration, set in the
-- place file), and the water is Roblox's terrain water with waves that run up the sand.
--
-- Shared and free of services: this module says what to fill (heights and materials, column by
-- column, and the voxels from them), the World service writes it into workspace.Terrain when the
-- server starts, the previews draw it and the specs check it.
--
-- Terrain is a grid of 4 stud voxels. Each column of the grid gets one height (its surface) and
-- one material; a voxel is filled as far as the surface reaches into it, and the water as far as
-- the sea's level does, so the water's edge lies on the sloping sand wherever the two meet.
--
-- Grass blades show through thin parts laid on them, so nothing built stands on grass: under
-- every road, pavement, floor and plot the ground is LeafyGrass (green, no blades), or Ground (a
-- worn path) under the stepping stones up the hills. TownMap.cover lists what is built.

local Hills = require(script.Parent.Hills)

local Terrain = {}

Terrain.Voxel = 4

-- The island: grass out to here, then the beach, then the shallows, then the deep sea. The
-- beach's width and the shallows' are on average; the coast waves in and out round them.
Terrain.IslandX = 1100 -- grass from -IslandX to IslandX
Terrain.IslandN = 940 -- and from -IslandS to IslandN (the hills run up to the north shore)
Terrain.IslandS = 292
Terrain.Beach = 38
Terrain.Shallows = 92

Terrain.WaterY = -1.2 -- the sea's level
Terrain.Ground = -0.1 -- the top of the flat grass (things on the ground stand at 0)
Terrain.Dry = -0.3 -- the sand where the grass ends
Terrain.Floor = -16 -- the deep sea's floor
Terrain.Bottom = -20 -- the lowest voxels
Terrain.Sink = 0.25 -- how far the ground drops out of sight under a paved floor
Terrain.Margin = 1.5 -- no blades within this of anything built (they'd poke through its edge)

-- Where the terrain is written column by column: the island and its sea out to Reach past the
-- grass, short of the islets on the horizon. Past it, out to Far, the open sea is filled in big
-- blocks. All on the 4 stud grid.
Terrain.Reach = 280
Terrain.Far = 3000
Terrain.Region = {
	-(Terrain.IslandX + Terrain.Reach),
	-(Terrain.IslandS + Terrain.Reach),
	Terrain.IslandX + Terrain.Reach,
	Terrain.IslandN + Terrain.Reach,
}

-- The colours of the terrain's materials (Terrain:SetMaterialColor sets one for the whole map).
-- The grass is a warm, slightly golden green, as in the user's picture; LeafyGrass, the grass
-- under what is built, is the same green so the edge of a lawn doesn't show. The sand is the
-- beach's, the deep floor the dark blue the sea used to show over it.
Terrain.Colors = {
	Grass = { 136, 172, 86 },
	LeafyGrass = { 140, 176, 92 },
	Ground = { 150, 124, 92 },
	Sand = { 244, 228, 188 },
	Rock = { 150, 146, 140 },
	Slate = { 96, 148, 186 },
}

-- The water (the Terrain's water properties): clear and turquoise over the sand, with small
-- waves that run up the beach and back.
Terrain.Water = {
	Color = { 64, 166, 178 },
	Transparency = 0.8,
	Reflectance = 0.3,
	WaveSize = 0.15,
	WaveSpeed = 9,
}

-- The grass: as long as Roblox grows it (Terrain.GrassLength, 0.1 to 1), and a breeze from the
-- south west for it to lean in (Workspace.GlobalWind). Both are in default.project.json: Roblox
-- doesn't let scripts set the grass.
Terrain.GrassLength = 1
Terrain.Wind = { 4, 0, 2.5 } -- studs a second: a breeze, not a gale

-- Every material the terrain uses, by name.
Terrain.Materials = { "Grass", "LeafyGrass", "Ground", "Sand", "Rock", "Slate", "Water", "Air" }

local IX, IN, IS = Terrain.IslandX, Terrain.IslandN, Terrain.IslandS
local SPAN_X, SPAN_Z = 2 * IX, IS + IN
local AROUND = 2 * (SPAN_X + SPAN_Z) -- the coast's length, round the grass

local function smoothstep(a: number, b: number, x: number): number
	local t = math.clamp((x - a) / (b - a), 0, 1)
	return t * t * (3 - 2 * t)
end

-- Where a point is against the island's grass: how far out from it (negative inside), and where
-- along the coast its nearest stretch is, in studs round from the south west corner (east along
-- the south shore, then north, west and south again).
function Terrain.coast(x: number, z: number): (number, number)
	local dx = math.max(-IX - x, 0, x - IX)
	local dz = math.max(-IS - z, 0, z - IN)
	local d
	local cx, cz = math.clamp(x, -IX, IX), math.clamp(z, -IS, IN)
	if dx > 0 or dz > 0 then
		d = math.sqrt(dx * dx + dz * dz)
	else
		local w, e, s, n = x + IX, IX - x, z + IS, IN - z
		local m = math.min(w, e, s, n)
		d = -m
		if m == s then
			cz = -IS
		elseif m == n then
			cz = IN
		elseif m == e then
			cx = IX
		else
			cx = -IX
		end
	end
	local s
	if cz == -IS and cx > -IX then
		s = cx + IX
	elseif cx == IX then
		s = SPAN_X + (cz + IS)
	elseif cz == IN then
		s = SPAN_X + SPAN_Z + (IX - cx)
	else
		s = 2 * SPAN_X + SPAN_Z + (IN - cz)
	end
	return d, s
end

-- Gentle curves along the coast: { waves round the whole island, studs out and in, where it
-- starts }. A whole number of waves, so the coast closes on itself; long bays, then smaller
-- coves and points on them, then ripples.
local WATER = { { 6, 7, 0.4 }, { 13, 6, 2.1 }, { 29, 4, 4.3 }, { 61, 2.6, 1.2 }, { 113, 1.4, 5.0 } }
local GRASS = { { 9, 7, 1.7 }, { 23, 5, 3.9 }, { 53, 2.5, 0.6 } }
local DEEP = { { 7, 10, 2.8 }, { 19, 5, 0.9 } }

local function waves(list: { { number } }, s: number): number
	local sum = 0
	for _, w in list do
		sum += w[2] * math.sin(w[1] * s * (2 * math.pi / AROUND) + w[3])
	end
	return sum
end

-- How far out from the grass the water's edge is, at a place along the coast.
function Terrain.waterLine(s: number): number
	return 36 + waves(WATER, s)
end

-- How far out the grass reaches over the sand: in and out along the east, west and north shores
-- (grassy points between coves), and along the south the sand runs a voxel in under the
-- boardwalk, so no grass shows at its edge.
function Terrain.grassLine(s: number): number
	local u = if s > AROUND - 400 then s - AROUND else s
	local south = smoothstep(-90, 0, u) * (1 - smoothstep(SPAN_X, SPAN_X + 90, u))
	local g = math.max(0, 6 + waves(GRASS, s)) * (1 - south) - Terrain.Voxel * south
	return math.min(g, Terrain.waterLine(s) - 16)
end

-- Where the shallows end and the sea floor drops away to the deep, out past the hidden walls
-- that keep people in the shallows (TownMap.ground's, at Beach + Shallows).
function Terrain.deepLine(s: number): number
	return Terrain.Beach + Terrain.Shallows + 20 + waves(DEEP, s)
end

-- Rock shows through the grass in bits on the steeper slopes: none where the hill is gentler
-- than this, and more of it the steeper it gets.
Terrain.Crag = 0.45

-- A smooth noise from 0 to 1 over cells `cell` studs across, the same every time.
local function hash(i: number, j: number): number
	local h = math.sin(i * 127.1 + j * 311.7) * 43758.5453
	return h - math.floor(h)
end
local function noise(x: number, z: number, cell: number): number
	local fx, fz = x / cell, z / cell
	local i, j = math.floor(fx), math.floor(fz)
	local u, v = fx - i, fz - j
	u, v = u * u * (3 - 2 * u), v * v * (3 - 2 * v)
	local a = hash(i, j) + (hash(i + 1, j) - hash(i, j)) * u
	local b = hash(i, j + 1) + (hash(i + 1, j + 1) - hash(i, j + 1)) * u
	return a + (b - a) * v
end

-- Whether the hill shows rock at x, z.
function Terrain.rocky(x: number, z: number): boolean
	local slope = Hills.slope(x, z)
	return slope > Terrain.Crag and noise(x, z, 14) > 0.82 - (slope - Terrain.Crag) * 0.7
end

-- The height of the ground at x, z and what it is, as nature made it: grass (on the hills too),
-- then sand from where the grass ends, sloping gently to the water's edge and on down under
-- the water, then the drop to the deep floor.
function Terrain.natural(x: number, z: number): (number, string)
	local d, s = Terrain.coast(x, z)
	-- (well inland, or far out past the drop, there is no shore to work out)
	if d > Terrain.Beach + Terrain.Shallows + 120 then
		return Terrain.Floor, "Slate"
	end
	local g = if d < -2 * Terrain.Voxel then d else Terrain.grassLine(s)
	if d <= g then
		local hill = Hills.at(x, z)
		if hill > 0 and Terrain.rocky(x, z) then
			return Terrain.Ground + hill, "Rock"
		end
		return Terrain.Ground + hill, "Grass"
	end
	local w = Terrain.waterLine(s)
	local h
	if d <= w then
		-- the dry sand: nearly level by the grass, sloping more as it nears the water
		local t = (d - g) / (w - g)
		h = Terrain.Dry - (Terrain.Dry - Terrain.WaterY) * t ^ 1.6
	else
		h = Terrain.WaterY - 2.4 * (1 - math.exp(-(d - w) / 36))
		local deep = Terrain.deepLine(s)
		if d > deep then
			h += (Terrain.Floor - h) * smoothstep(deep, deep + 70, d)
		end
	end
	return h, if h < -9 then "Slate" else "Sand"
end

-- The height of the ground where something stands on it (what the terrain's surface is there).
function Terrain.height(x: number, z: number): number
	return (Terrain.natural(x, z))
end

-- A point on the water's edge. `side` is "south", "north", "east" or "west" and `u` the x (south,
-- north) or the z (east, west) along it; `out` moves it that far out to sea (negative: up the
-- beach). Returns x, z.
function Terrain.shore(side: string, u: number, out: number?): (number, number)
	local more = out or 0
	if side == "south" then
		local _, s = Terrain.coast(u, -IS)
		return u, -IS - Terrain.waterLine(s) - more
	elseif side == "north" then
		local _, s = Terrain.coast(u, IN)
		return u, IN + Terrain.waterLine(s) + more
	elseif side == "east" then
		local _, s = Terrain.coast(IX, u)
		return IX + Terrain.waterLine(s) + more, u
	end
	local _, s = Terrain.coast(-IX, u)
	return -IX - Terrain.waterLine(s) - more, u
end

-- A point on the dry beach: `frac` of the way from where the grass ends (0) to the water (1).
function Terrain.onBeach(side: string, u: number, frac: number): (number, number)
	local x, z = Terrain.shore(side, u)
	local _, s = Terrain.coast(x, z)
	local back = (1 - frac) * (Terrain.waterLine(s) - Terrain.grassLine(s))
	if side == "south" then
		return x, z + back
	elseif side == "north" then
		return x, z - back
	elseif side == "east" then
		return x - back, z
	end
	return x + back, z
end

-- A rectangle with something built on it. `kind` is "paved" (a floor or a paved surface laid on
-- the ground: the ground under it sinks out of sight), "built" (whatever a placed model puts on
-- the ground) or "path" (stepping stones: a worn path of bare ground).
export type Cover = { x1: number, z1: number, x2: number, z2: number, kind: string }

-- A block of the open sea for Terrain:FillBlock.
export type SeaBlock = { center: Vector3, size: Vector3, material: string }

-- A triangle of the preview's ground.
export type Tri = { a: Vector3, b: Vector3, c: Vector3, color: Color3, mat: string, transp: number }

-- Every column of the region: its surface's height and its material, in rows (k = j * nx + i + 1
-- for the column i across, j down, from the region's corner).
export type Plan = {
	x1: number,
	z1: number,
	nx: number,
	nz: number,
	height: { number },
	material: { string },
}

-- Works out every column, from nature and from what is built (TownMap.cover). `pause`, if given,
-- is called after every row, so the server can let other work run in between.
function Terrain.plan(cover: { Cover }, pause: (() -> ())?): Plan
	local V = Terrain.Voxel
	local R = Terrain.Region
	local nx, nz = (R[3] - R[1]) // V, (R[4] - R[2]) // V
	-- what is built over each column (1 a path, 2 anything else), and the columns wholly under
	-- a paved floor
	local over: { number } = table.create(nx * nz, 0)
	local sunk: { [number]: boolean } = {}
	local m = Terrain.Margin
	for _, c in cover do
		local x1, z1, x2, z2 = c.x1, c.z1, c.x2, c.z2
		local level = if c.kind == "path" then 1 else 2
		local i1 = math.max(0, math.floor((x1 - m - R[1]) / V))
		local i2 = math.min(nx - 1, math.ceil((x2 + m - R[1]) / V) - 1)
		local j1 = math.max(0, math.floor((z1 - m - R[2]) / V))
		local j2 = math.min(nz - 1, math.ceil((z2 + m - R[2]) / V) - 1)
		for j = j1, j2 do
			local row = j * nx + 1
			for i = i1, i2 do
				if over[row + i] < level then
					over[row + i] = level
				end
			end
		end
		if c.kind == "paved" then
			for j = math.max(0, math.ceil((z1 - R[2]) / V)), math.min(nz - 1, math.floor((z2 - R[2]) / V) - 1) do
				for i = math.max(0, math.ceil((x1 - R[1]) / V)), math.min(nx - 1, math.floor((x2 - R[1]) / V) - 1) do
					sunk[j * nx + i + 1] = true
				end
			end
		end
	end
	local height: { number } = table.create(nx * nz, 0)
	local material: { string } = table.create(nx * nz, "Air")
	for j = 0, nz - 1 do
		local z = R[2] + V * j + V / 2
		for i = 0, nx - 1 do
			local x = R[1] + V * i + V / 2
			local k = j * nx + i + 1
			local h, mat = Terrain.natural(x, z)
			if mat == "Grass" or mat == "Rock" then
				local o = over[k]
				if o == 2 then
					mat = "LeafyGrass"
				elseif o == 1 then
					mat = "Ground"
				end
				if sunk[k] then
					h -= Terrain.Sink
				end
			end
			height[k] = h
			material[k] = mat
		end
		if pause then
			pause()
		end
	end
	return { x1 = R[1], z1 = R[2], nx = nx, nz = nz, height = height, material = material }
end

-- The column of the plan a point is in: its height and material (nil off the region).
function Terrain.at(plan: Plan, x: number, z: number): (number?, string?)
	local i = math.floor((x - plan.x1) / Terrain.Voxel)
	local j = math.floor((z - plan.z1) / Terrain.Voxel)
	if i < 0 or j < 0 or i >= plan.nx or j >= plan.nz then
		return nil, nil
	end
	local k = j * plan.nx + i + 1
	return plan.height[k], plan.material[k]
end

-- The plan in tiles of `size` columns a side, to write one at a time: { i0, j0, ni, nj }.
function Terrain.tiles(plan: Plan, size: number?): { { number } }
	local n = size or 64
	local out = {}
	for j0 = 0, plan.nz - 1, n do
		for i0 = 0, plan.nx - 1, n do
			table.insert(out, { i0, j0, math.min(n, plan.nx - i0), math.min(n, plan.nz - j0) })
		end
	end
	return out
end

-- The voxels of one tile, for Terrain:WriteVoxelChannels: the region's low and high corners and
-- the channels (SolidMaterial, SolidOccupancy, LiquidOccupancy), each indexed [x][y][z].
-- `mats` turns a material's name into what the channel holds (Enum.Material in the game).
-- A voxel's sand and the sea in it are both kept (Roblox's shorelines), so the water's edge
-- lies on the slope and not on the voxels' steps.
function Terrain.voxels(plan: Plan, tile: { number }, mats: { [string]: any }): (Vector3, Vector3, { [string]: any })
	local V = Terrain.Voxel
	local i0, j0, ni, nj = tile[1], tile[2], tile[3], tile[4]
	local top = Terrain.WaterY
	for b = 0, nj - 1 do
		local row = (j0 + b) * plan.nx + i0 + 1
		for a = 0, ni - 1 do
			top = math.max(top, plan.height[row + a])
		end
	end
	local ny = math.max(1, math.ceil((top - Terrain.Bottom) / V - 1e-6))
	local solidMat, solidOcc, liquidOcc = table.create(ni), table.create(ni), table.create(ni)
	local air = mats.Air
	for a = 1, ni do
		local ma, oa, la = table.create(ny), table.create(ny), table.create(ny)
		for y = 1, ny do
			ma[y] = table.create(nj, air)
			oa[y] = table.create(nj, 0)
			la[y] = table.create(nj, 0)
		end
		solidMat[a], solidOcc[a], liquidOcc[a] = ma, oa, la
	end
	local wy = Terrain.WaterY
	for c = 1, nj do
		local row = (j0 + c - 1) * plan.nx + i0
		for a = 1, ni do
			local k = row + a
			local h = plan.height[k]
			local mat = mats[plan.material[k]]
			local ma, oa, la = solidMat[a], solidOcc[a], liquidOcc[a]
			for y = 1, ny do
				local y0 = Terrain.Bottom + (y - 1) * V
				local solid = (h - y0) / V
				if solid >= 1 then
					ma[y][c] = mat
					oa[y][c] = 1
				else
					if solid > 1 / 255 then
						ma[y][c] = mat
						oa[y][c] = solid
					end
					if h < wy and y0 < wy then
						la[y][c] = math.min(1, (wy - y0) / V)
					end
				end
			end
		end
	end
	local lo = Vector3.new(plan.x1 + i0 * V, Terrain.Bottom, plan.z1 + j0 * V)
	local hi = lo + Vector3.new(ni * V, ny * V, nj * V)
	return lo, hi, { SolidMaterial = solidMat, SolidOccupancy = solidOcc, LiquidOccupancy = liquidOcc }
end

-- The same voxels for the older Terrain:WriteVoxels, which holds one material a voxel: where the
-- ground is under half of a voxel the sea takes it.
function Terrain.classic(channels: { [string]: any }, mats: { [string]: any }): ({ any }, { any })
	local solidMat, solidOcc, liquidOcc = channels.SolidMaterial, channels.SolidOccupancy, channels.LiquidOccupancy
	local materials, occupancy = {}, {}
	for a, plane in solidMat do
		local mx, ox = {}, {}
		for y, line in plane do
			local ml, ol = {}, {}
			for c, m in line do
				local solid, liquid = solidOcc[a][y][c], liquidOcc[a][y][c]
				if liquid > 0 and solid < 0.5 then
					ml[c], ol[c] = mats.Water, liquid
				else
					ml[c], ol[c] = m, solid
				end
			end
			mx[y], ox[y] = ml, ol
		end
		materials[a], occupancy[a] = mx, ox
	end
	return materials, occupancy
end

-- The open sea past the region, out to Far, as blocks for Terrain:FillBlock. Each piece of the
-- sea is two: the deep floor and the water over it.
function Terrain.openSea(): { SeaBlock }
	local R, F = Terrain.Region, Terrain.Far
	local strips = {
		{ -F, -F, F, R[2] },
		{ -F, R[4], F, F },
		{ -F, R[2], R[1], R[4] },
		{ R[3], R[2], F, R[4] },
	}
	local STEP = 1000
	local out: { SeaBlock } = {}
	for _, st in strips do
		local x = st[1]
		while x < st[3] do
			local x2 = math.min(x + STEP, st[3])
			local z = st[2]
			while z < st[4] do
				local z2 = math.min(z + STEP, st[4])
				local cx, cz, sx, sz = (x + x2) / 2, (z + z2) / 2, x2 - x, z2 - z
				local floor = Terrain.Floor - Terrain.Bottom
				local water = Terrain.WaterY - Terrain.Floor
				table.insert(out, {
					center = Vector3.new(cx, Terrain.Bottom + floor / 2, cz),
					size = Vector3.new(sx, floor, sz),
					material = "Slate",
				})
				table.insert(out, {
					center = Vector3.new(cx, Terrain.Floor + water / 2, cz),
					size = Vector3.new(sx, water, sz),
					material = "Water",
				})
				z = z2
			end
			x = x2
		end
	end
	return out
end

-- The terrain as triangles for the previews (tools/preview/dump.luau): the ground of `plan` in
-- the region { x1, z1, x2, z2 }, every `step` studs (a whole number of voxels), coloured by
-- material, and the sea's surface over all of it, see through. Flat runs of one colour are
-- joined.
function Terrain.preview(plan: Plan, region: { number }, step: number?): { Tri }
	local V = Terrain.Voxel
	local k = math.max(1, math.floor((step or V) / V))
	local out: { Tri } = {}
	local function color(mat: string, shade: number): Color3
		local c = Terrain.Colors[mat] or Terrain.Colors.Grass
		return Color3.fromRGB(
			math.clamp(c[1] * shade, 0, 255),
			math.clamp(c[2] * shade, 0, 255),
			math.clamp(c[3] * shade, 0, 255)
		)
	end
	local function tri(a: Vector3, b: Vector3, c: Vector3, col: Color3, mat: string, transp: number?)
		table.insert(out, { a = a, b = b, c = c, color = col, mat = mat, transp = transp or 0 })
	end
	-- the grid's nodes are column centres, `k` columns apart
	local i1 = math.max(0, math.floor((region[1] - plan.x1) / V))
	local i2 = math.min(plan.nx - 1, math.ceil((region[3] - plan.x1) / V))
	local j1 = math.max(0, math.floor((region[2] - plan.z1) / V))
	local j2 = math.min(plan.nz - 1, math.ceil((region[4] - plan.z1) / V))
	local function node(i: number, j: number): (Vector3, string)
		i, j = math.min(i, plan.nx - 1), math.min(j, plan.nz - 1)
		local idx = j * plan.nx + i + 1
		return Vector3.new(plan.x1 + i * V + V / 2, plan.height[idx], plan.z1 + j * V + V / 2), plan.material[idx]
	end
	-- a triangle takes the colours of its corners' materials, mixed, as Roblox blends one
	-- material into the next
	local function mixed(m1: string, m2: string, m3: string, shade: number): Color3
		if m1 == m2 and m2 == m3 then
			return color(m1, shade)
		end
		local a, b, c = color(m1, shade), color(m2, shade), color(m3, shade)
		return Color3.new((a.R + b.R + c.R) / 3, (a.G + b.G + c.G) / 3, (a.B + b.B + c.B) / 3)
	end
	for j = j1, j2 - 1, k do
		local i = i1
		while i < i2 do
			local p00, m = node(i, j)
			local p10, m10 = node(i + k, j)
			local p01, m01 = node(i, j + k)
			local p11, m11 = node(i + k, j + k)
			-- a little play in the colour, so a lawn isn't one flat sheet in the preview
			local shade = 0.985 + 0.03 * ((i * 7 + j * 13) % 5) / 4
			local flat = p00.Y == p10.Y and p00.Y == p01.Y and p00.Y == p11.Y
			flat = flat and m10 == m and m01 == m and m11 == m
			if flat then
				-- run on east while the ground stays level and of one material
				local run = i + k
				while run < i2 do
					local q10, qm = node(run + k, j)
					local q11 = node(run + k, j + k)
					local q00, q00m = node(run, j)
					local q01 = node(run, j + k)
					if q00m ~= m or qm ~= m or q10.Y ~= p00.Y or q11.Y ~= p00.Y or q00.Y ~= p00.Y or q01.Y ~= p00.Y then
						break
					end
					run += k
				end
				local e0 = node(run, j)
				local e1 = node(run, j + k)
				tri(p00, e0, e1, color(m, shade), m)
				tri(p00, e1, p01, color(m, shade), m)
				i = run
			else
				tri(p00, p10, p11, mixed(m, m10, m11, shade), m)
				tri(p00, p11, p01, mixed(m, m11, m01, shade), m)
				i += k
			end
		end
	end
	-- the sea over it all (the land stands out of it)
	local wy = Terrain.WaterY
	local a, b = Vector3.new(region[1], wy, region[2]), Vector3.new(region[3], wy, region[2])
	local c, d = Vector3.new(region[3], wy, region[4]), Vector3.new(region[1], wy, region[4])
	local sea = Terrain.Water.Color
	local water = Color3.fromRGB(sea[1], sea[2], sea[3])
	tri(a, b, c, water, "Water", 0.45)
	tri(a, c, d, water, "Water", 0.45)
	-- and past the region, the open sea's floor
	local R = Terrain.Region
	if region[1] < R[1] or region[2] < R[2] or region[3] > R[3] or region[4] > R[4] then
		local f = Terrain.Floor
		local deep = color("Slate", 1)
		local fa, fb = Vector3.new(region[1], f, region[2]), Vector3.new(region[3], f, region[2])
		local fc, fd = Vector3.new(region[3], f, region[4]), Vector3.new(region[1], f, region[4])
		tri(fa, fb, fc, deep, "Slate")
		tri(fa, fc, fd, deep, "Slate")
	end
	return out
end

return Terrain
