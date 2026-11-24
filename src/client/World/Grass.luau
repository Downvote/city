-- The island's long grass. The user, after Roblox's terrain grass didn't show for them: "you
-- should use this for grass", with SkinnedGrass, xander_z22's interactive grass from the Roblox
-- developer forum ("SkinnedGrass: performant interactive foliage"; its author: "feel free to
-- modify and use it in your own projects"). The pack ships in the place file as it came
-- (vendor/SkinnedGrass.rbxm); the server hands its module and meshes to the clients without
-- the pack's sample scripts (World.shareGrass).
--
-- A patch is one skinned mesh: a square of blades on a grid of bones, the blades round each bone
-- moving with it. Patches are laid on a grid over the island as the camera comes near, one a
-- frame. Each bone stands on the ground under it where that ground is grass all round it (the
-- terrain's Grass, which Data/Terrain keeps off everything built, or a plot's grass part) and
-- sinks out of sight anywhere else: on roads, sand, rock, water, in a house. When something is
-- built or taken down on a plot, the patches over it look again. The module sways the bones in
-- the wind (Workspace.GlobalWind, stronger in a storm) and bends them away from anyone walking
-- through. All of it is on each player's own screen.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Tuning = require(Shared.Config.Tuning)

local Grass = {}

local G = Tuning.Grass

type Cell = { model: Model, part: MeshPart, bones: { Bone }, x: number, z: number }

local cells: { [string]: Cell | false } = {}
local queue: { { number } } = {}
local folder: Folder
local template: Model
local sim: any = nil -- the SkinnedGrass object
local sizeX, sizeZ = 100, 100 -- a patch's width and depth in studs (its mesh's)
local gap = 10 -- studs between a patch's bones (measured from the first one)
local AROUND = { { 1, 1 }, { -1, 1 }, { 1, -1 }, { -1, -1 } }

local function key(i: number, j: number): string
	return i .. "," .. j
end

-- What the rays may land on: the terrain, and each plot's floor, land and what is built on it.
local function rayParams(): RaycastParams
	local list: { Instance } = { workspace.Terrain }
	local plots = workspace:FindFirstChild("Plots")
	if plots then
		for _, plot in plots:GetChildren() do
			for _, name in { "Base", "Land", "Build" } do
				local c = plot:FindFirstChild(name)
				if c then
					table.insert(list, c)
				end
			end
		end
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = list
	params.IgnoreWater = false
	return params
end

-- The ground's height at x, z, and whether grass may grow there.
local function ground(x: number, z: number, params: RaycastParams): (number?, boolean)
	local hit = workspace:Raycast(Vector3.new(x, G.Top, z), Vector3.new(0, -G.Top - 200, 0), params)
	if not hit then
		return nil, false
	end
	return hit.Position.Y, hit.Material == Enum.Material.Grass and hit.Normal.Y >= G.Flat
end

-- Stands each bone of a patch on the grass under it, or sinks it where there is none. Returns
-- how many stand. (The bones are moved through WorldCFrame, as the pack's author places them on
-- terrain, so the mesh's own scale is taken care of.)
local function conform(cell: Cell, params: RaycastParams): number
	local reach = gap * G.Spread
	local shown = 0
	for _, bone in cell.bones do
		local at = bone.WorldCFrame
		local turn = at - at.Position
		local x, z = at.Position.X, at.Position.Z
		local y, ok = ground(x, z, params)
		if ok and y then
			for _, o in AROUND do
				local y2, ok2 = ground(x + o[1] * reach, z + o[2] * reach, params)
				if not ok2 or not y2 or math.abs(y2 - y) > G.Rise then
					ok = false
					break
				end
			end
		end
		if ok and y then
			bone.WorldCFrame = CFrame.new(x, y, z) * turn
			shown += 1
		else
			bone.WorldCFrame = CFrame.new(x, (y or cell.part.Position.Y) - G.Sink, z) * turn
		end
	end
	return shown
end

local function bonesOf(part: Instance): { Bone }
	local out: { Bone } = {}
	for _, d in part:GetDescendants() do
		if d:IsA("Bone") and d.Name ~= "SkinnedGrass_Origin" then
			table.insert(out, d)
		end
	end
	return out
end

-- Lays the patch for grid square i, j: none if no grass at all grows in it.
local function make(i: number, j: number)
	local k = key(i, j)
	if cells[k] ~= nil then
		return
	end
	local cx, cz = (i + 0.5) * sizeX, (j + 0.5) * sizeZ
	local params = rayParams()
	-- (the patch sits at the middle height of its ground, so its box is round its blades)
	local sum, n = 0, 0
	for _, o in { { 0, 0 }, { 0.25, 0.25 }, { -0.25, 0.25 }, { 0.25, -0.25 }, { -0.25, -0.25 } } do
		local h = ground(cx + o[1] * sizeX, cz + o[2] * sizeZ, params)
		if h then
			sum, n = sum + h, n + 1
		end
	end
	local y = if n > 0 then sum / n else 0
	local model = template:Clone()
	local part = model:FindFirstChildOfClass("MeshPart") :: MeshPart
	part.Anchored = true
	part.CFrame = CFrame.new(cx, y, cz)
	model.Parent = folder -- (bones are only worked out in the world)
	local cell: Cell = { model = model, part = part, bones = bonesOf(part), x = cx, z = cz }
	if conform(cell, params) == 0 then
		model:Destroy()
		cells[k] = false
		return
	end
	cells[k] = cell
	sim:AddMeshes({ model })
end

-- The camera's focus: where the player is looking (their character, or Build mode's spot).
local function focus(): Vector3
	local cam = workspace.CurrentCamera
	return if cam then cam.Focus.Position else Vector3.zero
end

-- Queues the grid squares near the focus that have no patch yet, nearest first.
local function plan()
	local at = focus()
	local reach = G.Distance + G.Ahead
	local ci, cj = math.floor(at.X / sizeX), math.floor(at.Z / sizeZ)
	local ni, nj = math.ceil(reach / sizeX), math.ceil(reach / sizeZ)
	table.clear(queue)
	for i = ci - ni, ci + ni do
		for j = cj - nj, cj + nj do
			if cells[key(i, j)] == nil then
				local dx, dz = (i + 0.5) * sizeX - at.X, (j + 0.5) * sizeZ - at.Z
				local d = math.sqrt(dx * dx + dz * dz)
				if d <= reach then
					table.insert(queue, { i, j, d })
				end
			end
		end
	end
	table.sort(queue, function(a, b)
		return a[3] < b[3]
	end)
end

-- Looks again at every patch over a rectangle of the world (after a change on a plot). A patch
-- the module has put away (out of reach) is brought into the world for the moment it takes.
local function refresh(x1: number, z1: number, x2: number, z2: number)
	local params = rayParams()
	for i = math.floor(x1 / sizeX), math.floor(x2 / sizeX) do
		for j = math.floor(z1 / sizeZ), math.floor(z2 / sizeZ) do
			local cell = cells[key(i, j)]
			if cell then
				local was = cell.model.Parent
				if was ~= folder then
					cell.model.Parent = folder
				end
				conform(cell, params)
				if was ~= folder then
					cell.model.Parent = was
				end
			elseif cell == false then
				cells[key(i, j)] = nil -- (grass may grow there now: lay it again)
			end
		end
	end
end

-- Each plot: a change to what is built on it, or to its land, has the grass over it look again
-- a moment later (once for a run of changes).
local function watchPlots()
	local plots = workspace:WaitForChild("Plots", 120)
	if not plots then
		return
	end
	local waiting: { [Instance]: boolean } = {}
	local function soon(plot: Instance)
		if waiting[plot] then
			return
		end
		waiting[plot] = true
		task.delay(0.6, function()
			waiting[plot] = nil
			local base = plot:FindFirstChild("Base")
			if base and base:IsA("BasePart") then
				local p, s = base.Position, base.Size
				refresh(p.X - s.X / 2 - 2, p.Z - s.Z / 2 - 2, p.X + s.X / 2 + 2, p.Z + s.Z / 2 + 2)
			end
		end)
	end
	local function watch(plot: Instance)
		plot.ChildAdded:Connect(function()
			soon(plot)
		end)
		plot.ChildRemoved:Connect(function()
			soon(plot)
		end)
		local build = plot:WaitForChild("Build", 30)
		if build then
			build.DescendantAdded:Connect(function()
				soon(plot)
			end)
			build.DescendantRemoving:Connect(function()
				soon(plot)
			end)
		end
	end
	for _, plot in plots:GetChildren() do
		task.spawn(watch, plot)
	end
	plots.ChildAdded:Connect(watch)
end

-- Who the grass bends away from: players, and the villagers on the plots, near the focus.
local folk: { BasePart } = {}
local function gatherFolk()
	table.clear(folk)
	local at = focus()
	local function add(model: Instance?)
		local root = model and model:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") and (root.Position - at).Magnitude < G.Folk then
			table.insert(folk, root)
		end
	end
	for _, player in Players:GetPlayers() do
		add(player.Character)
	end
	local plots = workspace:FindFirstChild("Plots")
	if plots then
		for _, plot in plots:GetChildren() do
			local villagers = plot:FindFirstChild("Villagers")
			if villagers then
				for _, v in villagers:GetChildren() do
					add(v)
				end
			end
		end
	end
end

-- The pack's patch, coloured to the island's grass.
local function tint(model: Model)
	local part = model:FindFirstChildOfClass("MeshPart")
	if not part then
		return
	end
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = G.Shadows
	if G.Kind ~= "Studio" then
		return
	end
	local ok, base = pcall(function()
		return workspace.Terrain:GetMaterialColor(Enum.Material.Grass)
	end)
	if not ok then
		return
	end
	local function scaled(r: { number }): Color3
		return Color3.new(math.min(1, base.R * r[1]), math.min(1, base.G * r[2]), math.min(1, base.B * r[3]))
	end
	pcall(function()
		part.Material = (Enum.Material :: any)[G.Material]
	end)
	part.Color = scaled(G.Body)
	for _, d in part:GetChildren() do
		if d:IsA("Decal") then
			d.Color3 = scaled(G.Blades)
		end
	end
end

function Grass.start()
	task.spawn(function()
		local pack = ReplicatedStorage:WaitForChild("SkinnedGrass", 120)
		if not pack then
			warn("[Grass] the grass pack never arrived")
			return
		end
		local ok, SkinnedGrass = pcall(function()
			local module: any = pack:WaitForChild("SkinnedGrass")
			return (require :: any)(module)
		end)
		local models = pack:WaitForChild(G.Kind):WaitForChild("Models")
		local first = models:GetChildren()[1]
		if not ok or not first or not first:IsA("Model") then
			warn("[Grass] couldn't start the grass: " .. tostring(if ok then "no patch in the pack" else SkinnedGrass))
			return
		end
		-- the ground has to be there before anything is laid on it (a couple of minutes at most:
		-- a start that went wrong somewhere else still gets its grass)
		local waited = 0
		while workspace:GetAttribute("Startup") ~= "Ready" and waited < 150 do
			waited += task.wait(1)
		end
		template = first:Clone()
		tint(template)
		local part = template:FindFirstChildOfClass("MeshPart") :: MeshPart
		sizeX, sizeZ = part.Size.X, part.Size.Z
		folder = Instance.new("Folder")
		folder.Name = "Grass"
		folder.Parent = workspace
		-- the gap between bones, from one patch laid out in the world
		do
			local probe = template:Clone()
			probe.Parent = folder
			local lo, hi, n = math.huge, -math.huge, 0
			for _, b in bonesOf(probe) do
				local x = b.WorldCFrame.Position.X
				lo, hi, n = math.min(lo, x), math.max(hi, x), n + 1
			end
			probe:Destroy()
			local across = math.max(2, math.floor(math.sqrt(n) + 0.5))
			if hi > lo then
				gap = (hi - lo) / (across - 1)
			end
		end
		sim = SkinnedGrass.new({
			RenderDistance = G.Distance,
			CollisionRadiusInner = G.Bend * 0.6,
			CollisionRadiusOuter = G.Bend,
		})
		task.spawn(watchPlots)

		local planClock, folkClock, failures = 0, 0, 0
		local connection: RBXScriptConnection
		connection = RunService.RenderStepped:Connect(function(dt)
			planClock += dt
			if planClock > 0.4 then
				planClock = 0
				plan()
			end
			local next = table.remove(queue, 1)
			if next then
				local made, whyNot = pcall(make, next[1], next[2])
				if not made then
					cells[key(next[1], next[2])] = false
					warn("[Grass] couldn't lay a patch: " .. tostring(whyNot))
				end
			end
			folkClock += dt
			if folkClock > 0.5 then
				folkClock = 0
				gatherFolk()
			end
			local bends: { Vector3 } = {}
			for _, root in folk do
				if root.Parent then
					table.insert(bends, root.Position)
				end
			end
			local stepped, why = pcall(function()
				sim:Step(dt, bends, focus())
			end)
			if not stepped then
				failures += 1
				if failures >= 5 then
					warn("[Grass] the grass stopped moving: " .. tostring(why))
					connection:Disconnect()
				end
			end
		end)
	end)
end

return Grass
