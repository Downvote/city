-- The island's long grass. The user, after Roblox's terrain grass didn't show for them: "you
-- should use this for grass", with SkinnedGrass, xander_z22's interactive grass from the Roblox
-- developer forum ("SkinnedGrass: performant interactive foliage"; its author: "feel free to
-- modify and use it in your own projects"). Then, of the first try: "the grass works, but they
-- are too shiny and too big, and only at some areas. make them everywhere where grassy ground is".
--
-- The pack ships in the place file as it came (vendor/SkinnedGrass.rbxm); the server hands its
-- module and meshes to the clients without the pack's sample scripts (World.shareGrass).
--
-- A patch is one skinned mesh of 100 tufts, every tuft (23 blades) held by one bone and drawn
-- where that bone is. The pack's bones sit far closer together than its mesh is wide, so its
-- tufts came out as one tall clump in the middle of each square. Here every patch's bones are
-- laid out again on a fine grid of our own (`Tuning.Grass.Pitch` apart, turned and nudged a
-- little so no rows show), the mesh is shrunk to knee high blades, and it is drawn matte.
--
-- Then: "could you make the colors of grass random? and dense enough to cover all the floor?" A
-- mesh takes one colour, so a square of ground has a few patches over it at once (layers), each
-- its own green, their tufts scattered in among each other: every tuft takes the colour of its
-- layer, so the colours fall at random, and the ground under them is three times as full.
--
-- Patches cover the ground round the camera, a few a frame, and go again when it moves on. Each
-- tuft stands on the ground under it where that ground is grass all round it (the terrain's
-- Grass, which Data/Terrain keeps off everything built, or a grass part lying on the ground: a
-- plot's lawn, a lawn in town) and sinks out of sight anywhere else: roads, paths, sand, rock,
-- water, floors. A ray looks past things standing on the ground (a bench, a tree's crown) to the
-- ground under them. When something is built or taken down on a plot, the patches over it look
-- again. The module sways the bones in the wind (Workspace.GlobalWind, stronger in a storm) and
-- bends them away from anyone walking through. All of it is on each player's own screen.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Tuning = require(Shared.Config.Tuning)
local Hills = require(Shared.Data.Hills)
local Rng = require(Shared.Util.Rng)

local Grass = {}

local G = Tuning.Grass

-- One tuft of a patch: its bone, where it stands across the ground, how it's turned and leans,
-- how far into the ground it sits (a shorter tuft) and whether it's left out (a bare spot).
type Tuft = { bone: Bone, x: number, z: number, turn: CFrame, drop: number, bare: boolean, node: any }
-- One patch over a square of ground, in one of the greens.
type Layer = { model: Model, part: MeshPart, origin: Bone?, tufts: { Tuft }, meshNode: any }
-- A square of ground: its patches.
type Cell = { i: number, j: number, layers: { Layer } }

local cells: { [string]: Cell | false } = {}
local queue: { { number } } = {}
local folder: Folder
local templates: { Model } = {} -- the pack's patch in each of the greens
local sim: any = nil -- the SkinnedGrass object
local across = 10 -- tufts along a patch's side (the pack has 100 bones)
local side = 16 -- a patch's side in studs
local SINK = CFrame.new(0, -G.Sink, 0)
local HIDDEN = CFrame.new(0, -G.HiddenDepth, 0)

local function key(i: number, j: number): string
	return i .. "," .. j
end

-- What the rays may land on: the terrain, the town, and each plot's floor, land and buildings.
local function rayParams(): RaycastParams
	local list: { Instance } = { workspace.Terrain }
	local town = workspace:FindFirstChild("Town")
	if town then
		table.insert(list, town)
	end
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

-- The ground's height at x, z, and whether grass grows there. Terrain says by its material; a part
-- lying on the ground (no higher than `Lawn` over it) is the ground there, grass if it's a grass
-- part; past anything standing higher the ray goes on down.
local function ground(x: number, z: number, params: RaycastParams): (number?, boolean)
	local floor = Hills.at(x, z) - 0.1
	local top = G.Top
	for _ = 1, 6 do
		local hit = workspace:Raycast(Vector3.new(x, top, z), Vector3.new(0, floor - top - 40, 0), params)
		if not hit then
			return nil, false
		end
		local y = hit.Position.Y
		local grassy = hit.Material == Enum.Material.Grass and hit.Normal.Y >= G.Flat
		if hit.Instance:IsA("Terrain") or y <= floor + G.Lawn then
			return y, grassy
		end
		top = y - 0.05
	end
	return nil, false
end

-- The ground on a patch's grid of tufts, one point round its edge too: { y or false } by
-- (column, row), from 0 to across + 1.
type Rows = { { number | false } }
local function survey(i: number, j: number, params: RaycastParams): Rows
	local x0 = i * side + G.Pitch / 2
	local z0 = j * side + G.Pitch / 2
	local rows = {}
	for a = 0, across + 1 do
		local row = {}
		for b = 0, across + 1 do
			local y, ok = ground(x0 + (a - 1) * G.Pitch, z0 + (b - 1) * G.Pitch, params)
			row[b] = if ok and y then y else false
		end
		rows[a] = row
	end
	return rows
end

-- Stands each tuft of a patch on the grass under it, or sinks it. Returns how many stand. A tuft
-- stands where its point and the four round it are grass, level within `Rise`.
local function conform(cell: Layer, rows: Rows): number
	local shown = 0
	-- (the bones are placed against the patch at rest: a patch the module has sunk out of sight,
	-- or is raising, would otherwise put them that much too high when it comes back up)
	local origin = cell.origin
	local was = if origin then origin.Transform else nil
	if origin then
		origin.Transform = CFrame.identity
	end
	for k, tuft in cell.tufts do
		local a, b = (k - 1) % across + 1, (k - 1) // across + 1
		local y = rows[a][b]
		local ok = y ~= false and not tuft.bare
		if ok then
			for _, o in { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } } do
				local n = rows[a + o[1]][b + o[2]]
				if n == false or math.abs((n :: number) - (y :: number)) > G.Rise then
					ok = false
					break
				end
			end
		end
		local at = CFrame.new(tuft.x, if ok then (y :: number) - tuft.drop else cell.part.Position.Y, tuft.z)
			* tuft.turn
		tuft.bone.WorldCFrame = if ok then at else at * SINK
		if ok then
			shown += 1
		end
		if tuft.node then
			tuft.node:SetPosition(tuft.bone.WorldCFrame.Position)
		end
	end
	if origin and was then
		origin.Transform = was
	end
	return shown
end

-- Takes a laid patch into the module, as its AddMeshes does, keeping the octree's nodes so the
-- patch can be let go again (forget).
local function attach(cell: Layer)
	local part = cell.part
	local origin = Instance.new("Bone")
	origin.Name = "SkinnedGrass_Origin"
	origin.Parent = part
	origin.WorldCFrame = part.CFrame
	cell.origin = origin
	for _, tuft in cell.tufts do
		tuft.node = sim.BoneOctree:CreateNode(tuft.bone.WorldCFrame.Position, tuft.bone)
		tuft.bone.Parent = origin
	end
	origin.Transform = HIDDEN
	cell.meshNode = sim.MeshOctree:CreateNode(part.Position, part)
	sim.MeshParents[cell.model] = folder
	cell.model.Parent = nil -- (the module brings it in when the camera is near)
end

local function forget(cell: Layer)
	for _, tuft in cell.tufts do
		if tuft.node then
			tuft.node:Destroy()
		end
		sim.DisplaceBones[tuft.bone] = nil
		sim.ReturnBones[tuft.bone] = nil
	end
	if cell.meshNode then
		cell.meshNode:Destroy()
	end
	sim.MeshParents[cell.model] = nil
	local shown = table.find(sim.SkinnedMeshesRenderedIn, cell.part)
	if shown then
		table.remove(sim.SkinnedMeshesRenderedIn, shown)
	end
	local fading = cell.origin and table.find(sim.MeshTweenOuts, cell.origin)
	if fading then
		table.remove(sim.MeshTweenOuts, fading)
	end
	cell.model:Destroy()
end

-- Lays one patch of the square i, j in green number `k`, on the ground `rows`; nil if no tuft of
-- it stands.
local function lay(i: number, j: number, k: number, rows: Rows, mid: number): Layer?
	local model = templates[k]:Clone()
	local part = model:FindFirstChildOfClass("MeshPart") :: MeshPart
	local layer: Layer = { model = model, part = part, tufts = {}, meshNode = nil }
	-- (the patch sits at the middle height of its ground, so its box is round its blades)
	part.CFrame = CFrame.new((i + 0.5) * side, mid, (j + 0.5) * side)
	model.Parent = folder -- (bones are only worked out in the world)
	-- the tufts on our own grid, each nudged and turned its own way (the same every time)
	local rng = Rng.new(i * 7919 + j * 104729 + k * 15485863)
	local bones: { Bone } = {}
	for _, d in part:GetChildren() do
		if d:IsA("Bone") then
			table.insert(bones, d)
		end
	end
	local nudge = G.Pitch * G.Jitter
	local lean = math.rad(G.Lean)
	local tall = G.Native[2] * G.Height -- the tallest blades
	for n, bone in bones do
		if n > across * across then
			bone.WorldCFrame = part.CFrame * SINK -- (a bone past the square: out of sight)
			continue
		end
		local a, b = (n - 1) % across, (n - 1) // across
		local x = i * side + (a + 0.5) * G.Pitch + rng:float(-nudge, nudge)
		local z = j * side + (b + 0.5) * G.Pitch + rng:float(-nudge, nudge)
		-- Not an even carpet: the grass runs taller and shorter in drifts across the ground, every
		-- tuft a little different, with a bare spot now and then. A shorter tuft is one sitting
		-- further into the ground (a bone can't be scaled).
		local drift = math.noise(x / G.Drifts, z / G.Drifts, 0.31)
		local height = math.clamp(0.78 + drift * 0.5 + rng:float(-0.16, 0.16), G.Shortest, 1)
		local gap = math.noise(x / G.BareSize, z / G.BareSize, 7.7)
		table.insert(layer.tufts, {
			bone = bone,
			x = x,
			z = z,
			turn = CFrame.Angles(0, rng:float(0, math.pi * 2), 0)
				* CFrame.Angles(rng:float(-lean, lean), 0, rng:float(-lean, lean)),
			drop = (1 - height) * tall,
			bare = gap > G.Bare or rng:float(0, 1) < G.Gaps,
			node = nil,
		})
	end
	if conform(layer, rows) == 0 then
		model:Destroy()
		return nil
	end
	attach(layer)
	return layer
end

-- Lays the patches for grid square i, j: none if no grass grows in it.
local function make(i: number, j: number)
	local k = key(i, j)
	if cells[k] ~= nil then
		return
	end
	local params = rayParams()
	local rows = survey(i, j, params)
	local mid = ground((i + 0.5) * side, (j + 0.5) * side, params) or Hills.at((i + 0.5) * side, (j + 0.5) * side)
	local cell: Cell = { i = i, j = j, layers = {} }
	for n = 1, #templates do
		local layer = lay(i, j, n, rows, mid)
		if layer then
			table.insert(cell.layers, layer)
		end
	end
	cells[k] = if #cell.layers > 0 then cell else false
end

-- The camera's focus: where the player is looking (their character, or Build mode's spot).
local function focus(): Vector3
	local cam = workspace.CurrentCamera
	return if cam then cam.Focus.Position else Vector3.zero
end

-- Queues the grid squares near the focus that have no patch yet, nearest first, and lets go of
-- patches left far behind.
local far: { Cell } = {}
local function plan()
	local at = focus()
	local reach = G.Distance + G.Ahead
	local ci, cj = math.floor(at.X / side), math.floor(at.Z / side)
	local n = math.ceil(reach / side)
	table.clear(queue)
	for i = ci - n, ci + n do
		for j = cj - n, cj + n do
			if cells[key(i, j)] == nil then
				local dx, dz = (i + 0.5) * side - at.X, (j + 0.5) * side - at.Z
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
	table.clear(far)
	local gone = reach + side * 3
	for k, cell in cells do
		if cell then
			local dx, dz = (cell.i + 0.5) * side - at.X, (cell.j + 0.5) * side - at.Z
			if dx * dx + dz * dz > gone * gone then
				table.insert(far, cell)
			end
		elseif cell == false then
			local i, j = string.match(k, "^(-?%d+),(-?%d+)$")
			local dx, dz = (tonumber(i) :: number + 0.5) * side - at.X, (tonumber(j) :: number + 0.5) * side - at.Z
			if dx * dx + dz * dz > gone * gone then
				cells[k] = nil
			end
		end
	end
end

-- Looks again at every patch over a rectangle of the world (after a change on a plot). A patch
-- the module has put away (out of reach) is brought into the world for the moment it takes.
local function refresh(x1: number, z1: number, x2: number, z2: number)
	local params = rayParams()
	for i = math.floor(x1 / side), math.floor(x2 / side) do
		for j = math.floor(z1 / side), math.floor(z2 / side) do
			local cell = cells[key(i, j)]
			if cell then
				local rows = survey(i, j, params)
				for _, layer in cell.layers do
					local was = layer.model.Parent
					if was ~= folder then
						layer.model.Parent = folder
					end
					conform(layer, rows)
					if was ~= folder then
						layer.model.Parent = was
					end
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

-- The pack's patch made ready: shrunk to our blades and matt.
local function prepare(model: Model): boolean
	local part = model:FindFirstChildOfClass("MeshPart")
	if not part then
		return false
	end
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = G.Shadows
	part.Reflectance = 0
	-- slightly see-through (the user: "could you make it such that the grass is slightly
	-- transparent?"): the mesh and the pack's decals that shade the blades' foot alike
	part.Transparency = G.Transparency
	for _, d in part:GetChildren() do
		if d:IsA("Decal") then
			d.Transparency = G.Transparency
		end
	end
	-- the mesh's own size (Roblox knows it; the pack's numbers if it won't say)
	local native = Vector3.new(G.Native[1], G.Native[2], G.Native[3])
	pcall(function()
		local size = (part :: any).MeshSize
		if typeof(size) == "Vector3" and size.X > 0 then
			native = size
		end
	end)
	part.Size = Vector3.new(native.X * G.Scale, native.Y * G.Height, native.Z * G.Scale)
	-- smooth and matt: the plain look made for the blades (Data/Textures' Blade, a MaterialVariant
	-- in the place); without it the material is still smooth
	pcall(function()
		part.Material = (Enum.Material :: any)[G.Material]
		part.MaterialVariant = G.Look
	end)
	return true
end

-- A copy of the made ready patch in one of the greens: the terrain grass's colour times its
-- numbers, so every green sits in the ground it grows on (the pack's decals shade the blades from
-- their foot, fading out up them, so the mesh's own colour is their tips).
local function painted(model: Model, green: { Base: { number }, Tip: { number } }): Model
	local copy = model:Clone()
	local ok, base = pcall(function()
		return workspace.Terrain:GetMaterialColor(Enum.Material.Grass)
	end)
	if not ok then
		base = Color3.fromRGB(136, 172, 86)
	end
	local function scaled(r: { number }): Color3
		return Color3.new(math.min(1, base.R * r[1]), math.min(1, base.G * r[2]), math.min(1, base.B * r[3]))
	end
	local part = copy:FindFirstChildOfClass("MeshPart") :: MeshPart
	part.Color = scaled(green.Tip)
	for _, d in part:GetChildren() do
		if d:IsA("Decal") then
			d.Color3 = scaled(green.Base)
		end
	end
	return copy
end

-- Puts right what the pack's bookkeeping can get wrong (the user: "it seems like the grass dosent
-- render sometimes after going out of menus"). A patch that leaves the camera's reach starts
-- sinking and is put on a list to be taken out of the world when it's down; if it comes back
-- before then, it stays on that list, and the next time it's raised the list takes it straight
-- back out while the pack still counts it as shown, so it never shows again. After every step:
-- whatever the pack counts as shown is in the world, and nothing shown is waiting to go.
local function heal()
	local shown: { [Instance]: boolean } = {}
	for _, part in sim.SkinnedMeshesRenderedIn do
		shown[part] = true
		local model = part.Parent
		if model and model:IsA("Model") and model.Parent ~= folder and sim.MeshParents[model] then
			model.Parent = folder
		end
	end
	local leaving = sim.MeshTweenOuts
	for n = #leaving, 1, -1 do
		local origin = leaving[n]
		local part = origin and origin.Parent
		if not part or shown[part] then
			table.remove(leaving, n)
		end
	end
end

-- Starts the grass over: every patch let go, a fresh pack object, the ground surveyed again.
-- (After a run of steps that went wrong, rather than leaving the island bare.)
local SkinnedGrassModule: any = nil
local function newSim(): any
	return SkinnedGrassModule.new({
		RenderDistance = G.Distance,
		RenderOutOffset = HIDDEN,
		CollisionRadiusInner = G.Bend * 0.55,
		CollisionRadiusOuter = G.Bend,
		CollisionAngle = G.BendAngle,
		WindDistanceOuter = G.WindReach,
	})
end
local function reset()
	for _, cell in cells do
		if cell then
			for _, layer in cell.layers do
				pcall(forget, layer)
				pcall(function()
					layer.model:Destroy()
				end)
			end
		end
	end
	table.clear(cells)
	table.clear(queue)
	table.clear(far)
	sim = newSim()
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
		local template = first:Clone()
		if not prepare(template) then
			warn("[Grass] the pack's patch has no mesh")
			return
		end
		for n = 1, math.min(G.Layers, #G.Greens) do
			table.insert(templates, painted(template, G.Greens[n]))
		end
		local count = 0
		for _, d in (template:FindFirstChildOfClass("MeshPart") :: MeshPart):GetChildren() do
			if d:IsA("Bone") then
				count += 1
			end
		end
		across = math.max(1, math.floor(math.sqrt(count)))
		side = across * G.Pitch
		folder = Instance.new("Folder")
		folder.Name = "Grass"
		folder.Parent = workspace
		SkinnedGrassModule = SkinnedGrass
		sim = newSim()
		task.spawn(watchPlots)

		local planClock, folkClock, failures, said = 0, 0, 0, -math.huge
		local last = focus()
		RunService.RenderStepped:Connect(function(dt)
			planClock += dt
			-- (a camera that has jumped, as when a menu or the creator gives it back, gets its
			-- grass planned at once rather than in a moment)
			local at = focus()
			local jumped = (at - last).Magnitude > G.Distance * 0.5
			last = at
			if planClock > 0.4 or jumped then
				planClock = 0
				plan()
			end
			for _ = 1, G.PerFrame do
				local next = table.remove(queue, 1)
				if not next then
					break
				end
				local made, whyNot = pcall(make, next[1], next[2])
				if not made then
					cells[key(next[1], next[2])] = false
					warn("[Grass] couldn't lay a patch: " .. tostring(whyNot))
				end
			end
			local old = table.remove(far)
			if old then
				cells[key(old.i, old.j)] = nil
				for _, layer in old.layers do
					pcall(forget, layer)
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
				sim:Step(dt, bends, at)
				heal()
			end)
			if stepped then
				failures = 0
			else
				-- never give up on it: say what went wrong now and then, and after a run of
				-- failures start the grass over
				failures += 1
				if os.clock() - said > 30 then
					said = os.clock()
					warn("[Grass] a step went wrong: " .. tostring(why))
				end
				if failures >= 20 then
					failures = 0
					pcall(reset)
				end
			end
		end)
	end)
end

return Grass
