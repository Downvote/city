-- Pets on each player's own screen (Services/Pets chooses where they go; Data/Pets draws them). The
-- user: "These all have unique interactions with villagers, and roam around the city."
--
-- Every plot's folder `Pets` holds a Configuration a pet, whose attributes say its kind, coat and
-- name and the walk it is on (`From`, `To`, `Start`, `Speed`) and what it does at the end (`Act`,
-- `Look`). Here each one is built from its drawing (Builder) in a folder of this screen's own, and
-- moved along its walk once a frame in one batch (BulkMoveTo), only near the camera: its legs swing
-- as it walks (a bunny hops, a robot vacuum glides with its brushes turning, a penguin waddles, the
-- dragon flies a little off the ground with its wings going), its tail wags, its ears twitch, and
-- at a villager it does its act (happy: a wag and a bounce; play: hops; eat: head down and up;
-- spin: round on the spot). Its height is the ground under it, looked for a few times a second.
-- The owner of a plot can hold E on a pet to give it a pat (a little bounce, on their screen only).

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Tuning = require(Shared.Config.Tuning)
local Builder = require(Shared.Build.Builder)
local PetData = require(Shared.Data.Pets)
local SimPets = require(Shared.Sim.Pets)

local Pets = {}

local P = Tuning.Pets

type Pet = {
	conf: Configuration,
	kind: PetData.Pet,
	model: Model,
	parts: { BasePart },
	rest: { CFrame }, -- each part where it was drawn, in the pet's own space
	bones: { string? }, -- each part's bone (its name, when it is one of the kind's joints)
	y: number, -- the ground under it
	yAt: number, -- os.clock() it last looked
	yaw: number,
	happyUntil: number, -- a pat from this player, until when
	phase: number, -- its own offset in time, so two pets aren't in step
}

local folder: Folder
local pets: { [Configuration]: Pet } = {}
local moveParts: { BasePart } = {}
local moveFrames: { CFrame } = {}

local function ray(): RaycastParams
	local skip: { Instance } = { folder }
	for _, p in Players:GetPlayers() do
		if p.Character then
			table.insert(skip, p.Character)
		end
	end
	local plots = workspace:FindFirstChild("Plots")
	if plots then
		for _, plot in plots:GetChildren() do
			local v = plot:FindFirstChild("Villagers")
			if v then
				table.insert(skip, v)
			end
		end
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = skip
	params.IgnoreWater = true
	return params
end

local params: RaycastParams? = nil
local paramsAt = 0

local function groundAt(at: Vector3, fallback: number): number
	if not params or os.clock() - paramsAt > 2 then
		params = ray()
		paramsAt = os.clock()
	end
	local hit = workspace:Raycast(at + Vector3.new(0, 3, 0), Vector3.new(0, -8, 0), params)
	return if hit then hit.Position.Y else fallback
end

local function build(conf: Configuration): Pet?
	local kind = PetData.get(conf:GetAttribute("Kind"))
	if not kind then
		return nil
	end
	local model = Instance.new("Model")
	model.Name = conf.Name
	local made =
		Builder.instantiate(PetData.prims(kind.id, conf:GetAttribute("Coat") :: number?), model, CFrame.identity)
	local pet: Pet = {
		conf = conf,
		kind = kind,
		model = model,
		parts = {},
		rest = {},
		bones = {},
		y = (conf:GetAttribute("To") :: Vector3? or Vector3.zero).Y,
		yAt = 0,
		yaw = 0,
		happyUntil = 0,
		phase = (string.byte(conf.Name, -1) or 0) * 0.37,
	}
	for i, part in made do
		part.Anchored = true
		part.CanCollide = false
		part.CanTouch = false
		part.CanQuery = false
		part.CastShadow = part.Size.Magnitude > 0.4
		pet.parts[i] = part
		pet.rest[i] = part.CFrame
		pet.bones[i] = if kind.joints[part.Name] then part.Name else nil
	end
	-- a pat: hold E on it (the plot's owner, and anyone visiting: it's only on their screen)
	local body = made[1]
	if body then
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "PatPrompt"
		prompt.ActionText = "Pat"
		prompt.ObjectText = conf:GetAttribute("Name") or kind.name
		prompt.HoldDuration = 0.3
		prompt.MaxActivationDistance = 7
		prompt.RequiresLineOfSight = false
		prompt.Parent = body
		prompt.Triggered:Connect(function()
			pet.happyUntil = os.clock() + 2.5
		end)
	end
	model.Parent = folder
	return pet
end

-- A bone's turn this moment, round its joint: how far and about which axis.
local function boneTurn(pet: Pet, bone: string, t: number, moving: boolean, act: string): CFrame
	local gait = pet.kind.gait
	local stride = t * (if moving then 9 else 0)
	if string.sub(bone, 1, 3) == "Leg" then
		if not moving or gait == "hop" or gait == "fly" then
			return if gait == "fly" then CFrame.Angles(0.35, 0, 0) else CFrame.identity
		end
		local diag = if bone == "LegFL" or bone == "LegBR" then 1 else -1
		return CFrame.Angles(math.sin(stride) * 0.55 * diag, 0, 0)
	elseif bone == "Tail" then
		local fast = act == "happy" or act == "play"
		return CFrame.Angles(0, math.sin(t * (if fast then 14 else 3)) * (if fast then 0.55 else 0.25), 0)
	elseif bone == "Head" then
		if act == "eat" then
			return CFrame.Angles(0.35 + math.sin(t * 5) * 0.2, 0, 0)
		elseif act == "happy" then
			return CFrame.Angles(-0.15, 0, math.sin(t * 4) * 0.15)
		end
		return CFrame.Angles(0, math.sin(t * 0.6) * 0.2, math.sin(t * 0.4) * 0.05)
	elseif bone == "EarL" or bone == "EarR" then
		local twitch = if math.sin(t * 1.3) > 0.94 then 0.35 else 0
		return CFrame.Angles(0, 0, (if bone == "EarL" then 1 else -1) * twitch)
	elseif bone == "WingL" or bone == "WingR" then
		local s = if bone == "WingL" then 1 else -1
		if gait == "fly" then
			return CFrame.Angles(0, 0, s * math.sin(t * 9) * 0.6)
		end
		return CFrame.Angles(0, 0, s * (if moving or act == "happy" then math.sin(t * 7) * 0.3 else 0))
	elseif bone == "BrushL" or bone == "BrushR" then
		return CFrame.Angles(0, t * (if bone == "BrushL" then 12 else -12), 0)
	end
	return CFrame.identity
end

local function step(dt: number)
	local cam = workspace.CurrentCamera
	if not cam then
		return
	end
	local camAt = cam.CFrame.Position
	local now = workspace:GetServerTimeNow()
	local clock = os.clock()
	table.clear(moveParts)
	table.clear(moveFrames)
	for conf, pet in pets do
		local from = conf:GetAttribute("From") :: Vector3?
		local to = conf:GetAttribute("To") :: Vector3?
		local start = conf:GetAttribute("Start") :: number?
		local speed = conf:GetAttribute("Speed") :: number?
		if not (from and to and start and speed) then
			continue
		end
		local at, moving, gone = SimPets.at(from, to, start, speed, now)
		if (at - camAt).Magnitude > P.Range then
			continue
		end
		local act = conf:GetAttribute("Act") :: string? or "rest"
		if clock < pet.happyUntil then
			act = "happy"
		end
		local t = clock + pet.phase
		-- which way it faces: where it is going, or what it looks at when it gets there
		local want = pet.yaw
		local look = conf:GetAttribute("Look") :: Vector3?
		local dir = if moving then to - from elseif look then look - at else nil
		if dir and Vector3.new(dir.X, 0, dir.Z).Magnitude > 0.05 then
			want = math.atan2(dir.X, dir.Z)
		end
		if act == "spin" then
			want = pet.yaw + dt * 3
		end
		local diff = (want - pet.yaw + math.pi) % (math.pi * 2) - math.pi
		pet.yaw += diff * math.min(1, dt * 8)
		-- the ground under it
		if clock - pet.yAt > P.GroundEvery then
			pet.yAt = clock
			pet.y = groundAt(at, to.Y)
		end
		-- how it gets along: a bob, a hop, a waddle, a hover
		local gait = pet.kind.gait
		local lift, roll = 0, 0
		if gait == "hop" and moving then
			lift = math.abs(math.sin(gone * 1.6)) * 0.45
		elseif gait == "waddle" then
			roll = math.sin(t * (if moving then 8 else 1.5)) * (if moving then 0.18 else 0.04)
		elseif gait == "fly" then
			lift = 0.7 + math.sin(t * 2) * 0.12
		elseif gait == "walk" and moving then
			lift = math.abs(math.sin(gone * 2.2)) * 0.05
		end
		if act == "happy" or act == "play" then
			lift += math.abs(math.sin(t * (if act == "play" then 6 else 4))) * (if act == "play" then 0.45 else 0.15)
		end
		local root = CFrame.new(at.X, pet.y + lift, at.Z) * CFrame.Angles(0, pet.yaw, 0) * CFrame.Angles(0, 0, roll)
		for i, part in pet.parts do
			local bone = pet.bones[i]
			local cf = pet.rest[i]
			if bone then
				local j = pet.kind.joints[bone]
				cf = CFrame.new(j) * boneTurn(pet, bone, t, moving, act) * CFrame.new(-j) * cf
			end
			table.insert(moveParts, part)
			table.insert(moveFrames, root * cf)
		end
	end
	if #moveParts > 0 then
		workspace:BulkMoveTo(moveParts, moveFrames, Enum.BulkMoveMode.FireCFrameChanged)
	end
end

local function watch(conf: Instance)
	if not conf:IsA("Configuration") or pets[conf] then
		return
	end
	-- (its attributes may come a moment after it: wait for its kind)
	if conf:GetAttribute("Kind") == nil then
		conf:GetAttributeChangedSignal("Kind"):Wait()
	end
	if not conf.Parent or pets[conf] then
		return
	end
	local pet = build(conf)
	if pet then
		pets[conf] = pet
		-- a new coat or a new kind is a new model
		local function rebuild()
			local old = pets[conf]
			if old then
				old.model:Destroy()
				pets[conf] = nil
			end
			if conf.Parent then
				local again = build(conf)
				if again then
					pets[conf] = again
				end
			end
		end
		conf:GetAttributeChangedSignal("Coat"):Connect(rebuild)
		conf:GetAttributeChangedSignal("Kind"):Connect(rebuild)
		conf:GetAttributeChangedSignal("Name"):Connect(function()
			local p = pets[conf]
			local prompt = p and p.model:FindFirstChild("PatPrompt", true)
			if prompt and prompt:IsA("ProximityPrompt") then
				prompt.ObjectText = conf:GetAttribute("Name") or ""
			end
		end)
	end
end

local function unwatch(conf: Instance)
	local pet = pets[conf :: any]
	if pet then
		pet.model:Destroy()
		pets[conf :: any] = nil
	end
end

local function watchPlot(plot: Instance)
	local function hook(f: Instance)
		if f.Name ~= "Pets" or not f:IsA("Folder") then
			return
		end
		f.ChildAdded:Connect(function(c)
			task.spawn(watch, c)
		end)
		f.ChildRemoved:Connect(unwatch)
		for _, c in f:GetChildren() do
			task.spawn(watch, c)
		end
	end
	plot.ChildAdded:Connect(hook)
	for _, c in plot:GetChildren() do
		hook(c)
	end
end

function Pets.start()
	folder = Instance.new("Folder")
	folder.Name = "PetModels"
	folder.Parent = workspace
	task.spawn(function()
		local plots = workspace:WaitForChild("Plots", 60)
		if not plots then
			return
		end
		plots.ChildAdded:Connect(watchPlot)
		for _, plot in plots:GetChildren() do
			watchPlot(plot)
		end
	end)
	RunService.Heartbeat:Connect(function(dt)
		local ok, why = pcall(step, dt)
		if not ok then
			warn("[Pets] a frame went wrong:", why)
		end
	end)
end

return Pets
