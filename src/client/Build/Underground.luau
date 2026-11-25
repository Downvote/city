-- The ground over the plot, hidden on this player's screen while Build mode shows the basement
-- (floor -1, Build/Basement), as the genre's best known builder does. The user: "another
-- [gamepass] for basement". The plot's ground parts (World's Base, Water's pieces of it, Plots'
-- lawn and curbs) fade out, and the terrain under the land, from the basement's floor up to the
-- ground, is cleared on this screen alone (terrain a LocalScript writes stays on its own screen),
-- so the rooms, the grid and what is being placed down there show from above. Going up a floor or
-- leaving Build mode brings the ground back as the server has it.
--
-- Only solid ground is cleared, and what was there is kept to put back. What the server digs or
-- fills meanwhile (a room dug or sold, a pool) reaches this screen as the server writes it: when
-- the ground comes back, a voxel the plan has dug now (a basement block, a water) is left as the
-- server made it, and the rest is put back as it was. The terrain the server sends may fill some
-- of the cleared ground in again, so it is cleared again after each change to the plan.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Plan = require(Shared.Build.Plan)
local Basement = require(Shared.Build.Basement)

local Underground = {}

local V = Basement.Voxel
local CHANNELS = { "SolidMaterial", "SolidOccupancy", "LiquidOccupancy" }

type Saved = {
	region: Region3,
	frame: CFrame,
	i0: number, -- the region's corner, in the world's voxels
	k0: number,
	nx: number,
	ny: number,
	nz: number,
	classic: boolean,
	before: any, -- the channels (or materials and occupancy) read when it was hidden
	cleared: { [number]: boolean }, -- which voxels were solid and cleared: x, y, z packed
}

local saved: Saved? = nil
local faded: { [BasePart]: boolean } = {} -- the parts faded out, with what their CanQuery was

-- (the specs hand in a stand-in)
Underground.terrain = nil :: any

local function terrain(): any
	if Underground.terrain then
		return Underground.terrain
	end
	local ok, t = pcall(function()
		return (workspace :: any).Terrain
	end)
	return if ok then t else nil
end

local function pack(x: number, y: number, z: number): number
	return (x * 64 + y) * 4096 + z
end

local function isGround(part: Instance): boolean
	if not part:IsA("BasePart") then
		return false
	end
	local plot = part.Parent
	if part.Name == "Base" or part:GetAttribute("WaterPiece") == "Base" then
		return plot ~= nil and plot:IsA("Model")
	end
	return false
end

local function fadeParts(plotModel: Instance)
	for _, child in plotModel:GetChildren() do
		if isGround(child) then
			faded[child :: BasePart] = (child :: BasePart).CanQuery
		end
	end
	local land = plotModel:FindFirstChild("Land")
	if land then
		for _, d in land:GetDescendants() do
			if d:IsA("BasePart") then
				faded[d] = d.CanQuery
			end
		end
	end
	for part in faded do
		part.LocalTransparencyModifier = 1
		part.CanQuery = false
	end
end

local function unfadeParts()
	for part, canQuery in faded do
		if part.Parent then
			part.LocalTransparencyModifier = 0
			part.CanQuery = canQuery
		end
	end
	faded = {}
end

-- The block of the world's voxels under the land, as region and corner: the land's rectangle in
-- to the terrain's grid (its outer two studs are never dug: Tuning.Basement.Margin).
local function landRegion(frame: CFrame, plan: any): (Region3?, number, number, number, number, number)
	local x1, z1, x2, z2 = Plan.bounds(plan)
	local O = Basement.Offset
	x1 = math.ceil((x1 - O) / V - 1e-3) * V + O
	z1 = math.ceil((z1 - O) / V - 1e-3) * V + O
	x2 = math.floor((x2 - O) / V + 1e-3) * V + O
	z2 = math.floor((z2 - O) / V + 1e-3) * V + O
	if x2 <= x1 or z2 <= z1 then
		return nil, 0, 0, 0, 0, 0
	end
	local a, b = frame * Vector3.new(x1, 0, z1), frame * Vector3.new(x2, 0, z2)
	local low, high = a:Min(b), a:Max(b)
	local i0, k0 = math.floor(low.X / V + 0.5), math.floor(low.Z / V + 0.5)
	local nx = math.floor(high.X / V + 0.5) - i0
	local nz = math.floor(high.Z / V + 0.5) - k0
	local ny = math.floor((Basement.Top - Basement.Bottom) / V + 0.5)
	local region = Region3.new(
		Vector3.new(i0 * V, Basement.Bottom, k0 * V),
		Vector3.new((i0 + nx) * V, Basement.Top, (k0 + nz) * V)
	)
	return region, i0, k0, nx, ny, nz
end

-- Writes air into every voxel that was cleared.
local function clear(s: Saved)
	local t = terrain()
	if not t then
		return
	end
	local air = Enum.Material.Air
	local before = s.before
	local mat, occ, liq = table.create(s.nx), table.create(s.nx), table.create(s.nx)
	for x = 1, s.nx do
		local mx, ox, lx = table.create(s.ny), table.create(s.ny), table.create(s.ny)
		for y = 1, s.ny do
			local ml, ol, ll = table.create(s.nz), table.create(s.nz), table.create(s.nz)
			for z = 1, s.nz do
				if s.cleared[pack(x, y, z)] then
					ml[z], ol[z], ll[z] = air, 0, 0
				elseif s.classic then
					ml[z], ol[z], ll[z] = before.materials[x][y][z], before.occupancy[x][y][z], 0
				else
					ml[z], ol[z], ll[z] =
						before.SolidMaterial[x][y][z], before.SolidOccupancy[x][y][z], before.LiquidOccupancy[x][y][z]
				end
			end
			mx[y], ox[y], lx[y] = ml, ol, ll
		end
		mat[x], occ[x], liq[x] = mx, ox, lx
	end
	if s.classic then
		t:WriteVoxels(s.region, V, mat, occ)
	else
		t:WriteVoxelChannels(s.region, V, { SolidMaterial = mat, SolidOccupancy = occ, LiquidOccupancy = liq })
	end
end

-- Is the voxel column at (i, k) dug by the plan now (a basement block or a water)?
local function dugNow(frame: CFrame, plan: any, i: number, k: number): boolean
	local at = frame:PointToObjectSpace(Vector3.new((i + 0.5) * V, 0, (k + 0.5) * V))
	for _, b in Basement.blocks(plan) do
		if at.X > b[1] and at.X < b[3] and at.Z > b[2] and at.Z < b[4] then
			return true
		end
	end
	for _, w in (plan and plan.waters) or {} do
		if type(w) == "table" and at.X > w.x1 and at.X < w.x2 and at.Z > w.z1 and at.Z < w.z2 then
			return true
		end
	end
	return false
end

-- Hides the ground over plot `plotModel` (its frame `frame`, its plan `plan`) on this screen.
function Underground.hide(plotModel: Instance?, frame: CFrame, plan: any)
	if saved or not plotModel then
		return
	end
	fadeParts(plotModel)
	local t = terrain()
	local region, i0, k0, nx, ny, nz = landRegion(frame, plan)
	if not t or not region then
		return
	end
	local ok, why = pcall(function()
		local classic = false
		local before: any
		local got, ch = pcall(function()
			return t:ReadVoxelChannels(region, V, CHANNELS)
		end)
		if got and type(ch) == "table" and ch.SolidMaterial then
			before = ch
		else
			classic = true
			local materials, occupancy = t:ReadVoxels(region, V)
			before = { materials = materials, occupancy = occupancy }
		end
		local cleared = {}
		for x = 1, nx do
			for y = 1, ny do
				for z = 1, nz do
					local solid = if classic then before.occupancy[x][y][z] else before.SolidOccupancy[x][y][z]
					local mat = if classic then before.materials[x][y][z] else before.SolidMaterial[x][y][z]
					if solid > 0 and mat ~= Enum.Material.Air and mat ~= Enum.Material.Water then
						cleared[pack(x, y, z)] = true
					end
				end
			end
		end
		local s: Saved = {
			region = region,
			frame = frame,
			i0 = i0,
			k0 = k0,
			nx = nx,
			ny = ny,
			nz = nz,
			classic = classic,
			before = before,
			cleared = cleared,
		}
		saved = s
		clear(s)
	end)
	if not ok then
		warn("[Underground] couldn't hide the ground: " .. tostring(why))
	end
end

-- Clears the ground again (the terrain the server sends after a change may fill some of it in).
function Underground.refresh()
	local s = saved
	if s then
		pcall(clear, s)
	end
end

-- Brings the ground back: what was cleared as it was, unless the plan has dug it since.
function Underground.show(plan: any)
	unfadeParts()
	local s = saved
	saved = nil
	local t = terrain()
	if not s or not t then
		return
	end
	local ok, why = pcall(function()
		local now: any
		if s.classic then
			local materials, occupancy = t:ReadVoxels(s.region, V)
			now = { materials = materials, occupancy = occupancy }
		else
			now = t:ReadVoxelChannels(s.region, V, CHANNELS)
		end
		local before = s.before
		local mat, occ, liq = table.create(s.nx), table.create(s.nx), table.create(s.nx)
		for x = 1, s.nx do
			local mx, ox, lx = table.create(s.ny), table.create(s.ny), table.create(s.ny)
			for y = 1, s.ny do
				mx[y], ox[y], lx[y] = table.create(s.nz), table.create(s.nz), table.create(s.nz)
			end
			mat[x], occ[x], liq[x] = mx, ox, lx
		end
		for x = 1, s.nx do
			for z = 1, s.nz do
				local keep = dugNow(s.frame, plan, s.i0 + x - 1, s.k0 + z - 1)
				for y = 1, s.ny do
					local back = s.cleared[pack(x, y, z)] and not keep
					local src = if back then before else now
					if s.classic then
						mat[x][y][z], occ[x][y][z], liq[x][y][z] = src.materials[x][y][z], src.occupancy[x][y][z], 0
					else
						mat[x][y][z], occ[x][y][z], liq[x][y][z] =
							src.SolidMaterial[x][y][z], src.SolidOccupancy[x][y][z], src.LiquidOccupancy[x][y][z]
					end
				end
			end
		end
		if s.classic then
			t:WriteVoxels(s.region, V, mat, occ)
		else
			t:WriteVoxelChannels(s.region, V, { SolidMaterial = mat, SolidOccupancy = occ, LiquidOccupancy = liq })
		end
	end)
	if not ok then
		warn("[Underground] couldn't bring the ground back: " .. tostring(why))
	end
end

-- Is the ground hidden now?
function Underground.isHidden(): boolean
	return saved ~= nil or next(faded) ~= nil
end

return Underground
