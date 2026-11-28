-- The ground over the plot, hidden on this player's screen while Build mode shows the basement
-- (floor -1, Build/Basement), as the genre's best known builder does. The user: "another
-- [gamepass] for basement". The plot's ground parts (World's Base, Water's pieces of it, Plots'
-- lawn and curbs) fade out, and the terrain under the land, from the basement's floor up to the
-- ground, is cleared on this screen alone (terrain a LocalScript writes stays on its own screen),
-- so the rooms, the grid and what is being placed down there show from above. Going up a floor or
-- leaving Build mode brings the ground back as the server has it.
--
-- The ground and any water in it are cleared, and what was there is kept to put back. What the
-- plan digs (a basement block, a pool) is the server's: this screen never writes over it, so what
-- the server digs or fills meanwhile (a room dug or sold) reaches this screen as the server writes
-- it. (It once wrote back what it had kept over a room dug while the basement was shown, which left
-- the sea's water there for good: the user, "moving up after viewing the basement also causes water
-- patches to appear permanantly".) The terrain the server sends may fill some of the cleared ground
-- in again, so it is cleared again after each change to the plan; a voxel filled again is the
-- server's truth, and that is what goes back when the ground comes back.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Plan = require(Shared.Build.Plan)
local Basement = require(Shared.Build.Basement)

local Underground = {}

local V = Basement.Voxel
local CHANNELS = { "SolidMaterial", "SolidOccupancy", "LiquidOccupancy" }

type Voxel = { m: any, o: number, l: number }
type Saved = {
	plotModel: Instance,
	region: Region3,
	frame: CFrame,
	i0: number, -- the region's corner, in the world's voxels
	k0: number,
	nx: number,
	ny: number,
	nz: number,
	classic: boolean,
	-- what this screen cleared, as the server last had it: x, y, z packed. A voxel the plan digs
	-- (a basement block, a water) is the server's and never in here.
	orig: { [number]: Voxel },
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

-- Fades the plot's ground out on this screen. Called again after every change, since the server
-- cuts the ground afresh round what it digs, and the new pieces come in shown.
local function fadeParts(plotModel: Instance)
	for _, child in plotModel:GetChildren() do
		if isGround(child) and faded[child :: BasePart] == nil then
			faded[child :: BasePart] = (child :: BasePart).CanQuery
		end
	end
	local land = plotModel:FindFirstChild("Land")
	if land then
		for _, d in land:GetDescendants() do
			if d:IsA("BasePart") and faded[d] == nil then
				faded[d] = d.CanQuery
			end
		end
	end
	for part in faded do
		if part.Parent then
			part.LocalTransparencyModifier = 1
			part.CanQuery = false
		else
			faded[part] = nil
		end
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

-- The rectangles the plan has dug now, on the plot: its basement's blocks and its waters.
local function dugRects(plan: any): { { number } }
	local out = Basement.blocks(plan)
	for _, w in (plan and plan.waters) or {} do
		if type(w) == "table" and type(w.x1) == "number" then
			table.insert(out, { w.x1, w.z1, w.x2, w.z2 })
		end
	end
	return out
end

-- Is the voxel column at (i, k) in one of those?
local function dugNow(frame: CFrame, dug: { { number } }, i: number, k: number): boolean
	local at = frame:PointToObjectSpace(Vector3.new((i + 0.5) * V, 0, (k + 0.5) * V))
	for _, b in dug do
		if at.X > b[1] and at.X < b[3] and at.Z > b[2] and at.Z < b[4] then
			return true
		end
	end
	return false
end

-- What the terrain holds in the region now, as one voxel reader.
local function readNow(t: any, s: Saved): (number, number, number) -> Voxel
	if s.classic then
		local materials, occupancy = t:ReadVoxels(s.region, V)
		return function(x, y, z)
			local m = materials[x][y][z]
			local o = occupancy[x][y][z]
			if m == Enum.Material.Water then
				return { m = Enum.Material.Air, o = 0, l = o }
			end
			return { m = m, o = o, l = 0 }
		end
	end
	local ch = t:ReadVoxelChannels(s.region, V, CHANNELS)
	return function(x, y, z)
		return { m = ch.SolidMaterial[x][y][z], o = ch.SolidOccupancy[x][y][z], l = ch.LiquidOccupancy[x][y][z] }
	end
end

-- Is there anything in a voxel: ground, or water? (Both hide the rooms. The sea once lay under
-- every plot's ground, hidden in the plot's own ground part, and was all the basement showed.)
local function filled(v: Voxel): boolean
	return (v.o > 0 and v.m ~= Enum.Material.Air and v.m ~= Enum.Material.Water) or v.l > 0
end

-- Writes the region: `pick(x, y, z)` says what each voxel holds.
local function write(t: any, s: Saved, pick: (number, number, number) -> Voxel)
	local mat, occ, liq = table.create(s.nx), table.create(s.nx), table.create(s.nx)
	for x = 1, s.nx do
		local mx, ox, lx = table.create(s.ny), table.create(s.ny), table.create(s.ny)
		for y = 1, s.ny do
			local ml, ol, ll = table.create(s.nz), table.create(s.nz), table.create(s.nz)
			for z = 1, s.nz do
				local v = pick(x, y, z)
				if s.classic then
					-- (one material a voxel: water where there is no ground)
					if v.l > 0 and not (v.o > 0 and v.m ~= Enum.Material.Air) then
						ml[z], ol[z] = Enum.Material.Water, v.l
					else
						ml[z], ol[z] = v.m, v.o
					end
				else
					ml[z], ol[z], ll[z] = v.m, v.o, v.l
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

local AIR: Voxel = { m = Enum.Material.Air, o = 0, l = 0 }

-- Clears the ground and the water under the land on this screen, as the plan has it now. What the
-- plan digs is left as the server has it (the server writes it, and its writes reach this screen);
-- everything else that is filled is cleared, and kept as it is now to put back. A voxel cleared
-- before and filled again has been sent again by the server, so what it holds now is the truth.
local function clear(s: Saved, plan: any)
	local t = terrain()
	if not t then
		return
	end
	local now = readNow(t, s)
	local dug = dugRects(plan)
	local keep: { [number]: boolean } = {}
	for x = 1, s.nx do
		for z = 1, s.nz do
			keep[x * 4096 + z] = dugNow(s.frame, dug, s.i0 + x - 1, s.k0 + z - 1)
		end
	end
	write(t, s, function(x, y, z)
		local v = now(x, y, z)
		local p = pack(x, y, z)
		if keep[x * 4096 + z] then
			s.orig[p] = nil
			return v
		end
		if filled(v) then
			s.orig[p] = v
		end
		return AIR
	end)
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
	local classic = false
	local got, ch = pcall(function()
		return t:ReadVoxelChannels(region, V, CHANNELS)
	end)
	if not (got and type(ch) == "table" and ch.SolidMaterial) then
		classic = true
	end
	local s: Saved = {
		plotModel = plotModel,
		region = region,
		frame = frame,
		i0 = i0,
		k0 = k0,
		nx = nx,
		ny = ny,
		nz = nz,
		classic = classic,
		orig = {},
	}
	saved = s
	local ok, why = pcall(clear, s, plan)
	if not ok then
		warn("[Underground] couldn't hide the ground: " .. tostring(why))
	end
end

-- Clears the ground again after a change to the plan (`plan`, as it is now): the terrain the
-- server sends may fill some of it in, and the server cuts the plot's ground afresh.
function Underground.refresh(plan: any)
	local s = saved
	if s then
		fadeParts(s.plotModel)
		pcall(clear, s, plan)
	end
end

-- Brings the ground back as the server has it: what this screen cleared goes back, unless the plan
-- digs it now or the server has sent it again since.
function Underground.show(plan: any)
	unfadeParts()
	local s = saved
	saved = nil
	local t = terrain()
	if not s or not t then
		return
	end
	local ok, why = pcall(function()
		local now = readNow(t, s)
		local dug = dugRects(plan)
		local keep: { [number]: boolean } = {}
		for x = 1, s.nx do
			for z = 1, s.nz do
				keep[x * 4096 + z] = dugNow(s.frame, dug, s.i0 + x - 1, s.k0 + z - 1)
			end
		end
		write(t, s, function(x, y, z)
			local v = now(x, y, z)
			local back = s.orig[pack(x, y, z)]
			if back and not keep[x * 4096 + z] and not filled(v) then
				return back
			end
			return v
		end)
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
