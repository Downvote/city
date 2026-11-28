-- Lifts players place (Build/Recipes/Travel, Sim/Lifts). The user: "make ways to travel down, like
-- different hole types, and add elevators".
--
-- Every placed lift has an up button on the left of each landing's doors and a down button on the
-- right (hidden parts named LiftUp and LiftDown, each with its landing as `Floor`); this puts a
-- prompt on each. Holding E there sends the car to that landing if it is away, opens its doors, shuts
-- them on whoever is in the car (and the one who pressed, from just outside), carries them a floor up
-- or down and lets them out. The lift's model carries the ride (LiftFrom, LiftCall, LiftTo and
-- LiftStart, the server's clock) and where the car rests (LiftAt): each player's screen moves the
-- car and the doors from them (World/Lifts), and nothing that moves is solid. Here the riders are
-- held still and carried, each where they stood in the car, and each landing's hidden gate in the
-- doorway (LiftGate) lets people through only while its doors are open.
-- Anyone may ride, on any plot; the server checks where they stand, the landing and the lift.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Tuning = require(Shared.Config.Tuning)
local Catalog = require(Shared.Build.Catalog)
local Builder = require(Shared.Build.Builder)
local Plan = require(Shared.Build.Plan)
local LiftsSim = require(Shared.Sim.Lifts)

local Data = require(script.Parent.Data)
local Plots = require(script.Parent.Plots)

local K = Tuning.Lifts

local Lifts = {}

local PROMPT = "LiftPrompt"

local rests: { [string]: number } = {} -- where each lift's car is, by "plot:key"
local busy: { [string]: boolean } = {}
local lastPress: { [Player]: number } = {}

local function now(): number
	return workspace:GetServerTimeNow()
end

-- A lift on plot `i` by its key: the item, its piece and where it stands in the world.
local function liftOf(i: number, key: string): (any?, any?, CFrame?)
	local owner = Plots.owner(i)
	local profile = owner and Data.get(owner)
	local plan = profile and profile.plan
	local item = plan and plan.items[key]
	local def = item and Catalog.get(item.id)
	if not item or not LiftsSim.isLift(def) then
		return nil, nil, nil
	end
	local frame = Plan.itemFrame(plan, item)
	if not frame then
		return nil, nil, nil
	end
	return item, def, Plots.frame(i) * frame
end

local function modelOf(i: number, key: string): Instance?
	local ok, folder = pcall(Plots.buildFolder, i)
	return if ok and folder then folder:FindFirstChild(Builder.modelName("items", key)) else nil
end

-- A landing's hidden gate lets people through (open) or not.
local function gate(model: Instance?, k: number, open: boolean)
	if not model then
		return
	end
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") and d.Name == "LiftGate" and d:GetAttribute("Floor") == k then
			d.CanCollide = not open
		end
	end
end

-- Waits until `t` on the server's clock.
local function waitUntil(t: number)
	local left = t - now()
	if left > 0 then
		task.wait(left)
	end
end

type Rider = { root: BasePart, spot: Vector3, turn: CFrame }

-- One ride, from start to finish (run in its own thread). `riders` is filled as they are taken, so
-- whoever calls it can let them go if it stops part way.
local function run(i: number, key: string, presser: Player, call: number, to: number, riders: { Rider })
	local id = i .. ":" .. key
	local _, def, world = liftOf(i, key)
	local model = modelOf(i, key)
	if not def or not world or not model then
		busy[id] = nil
		return
	end
	local from = rests[id] or 0
	local ride = LiftsSim.ride(from, call, to)
	local t0 = now() + 0.1
	model:SetAttribute("LiftFrom", from)
	model:SetAttribute("LiftCall", call)
	model:SetAttribute("LiftTo", to)
	model:SetAttribute("LiftStart", t0)
	waitUntil(t0 + ride.fetched)
	gate(model, call, true)
	waitUntil(t0 + ride.boarded)
	gate(model, call, false)
	-- who rides: everyone in the car at that landing, and the one who pressed if they are still by
	-- the doors
	local H = Tuning.Plot.LevelHeight
	for _, player in Players:GetPlayers() do
		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") then
			local at = world:PointToObjectSpace(root.Position)
			local foot = at - Vector3.new(0, 3, 0) -- (about where their feet are)
			local here = LiftsSim.landingOf(LiftsSim.spans(def), foot) == call
			local takes = here and (LiftsSim.inCar(at) or (player == presser and LiftsSim.atDoors(at)))
			if takes then
				local spot = LiftsSim.spot(at)
				local turn = (world:ToObjectSpace(root.CFrame)).Rotation
				root.Anchored = true
				table.insert(riders, {
					root = root,
					spot = Vector3.new(spot.X, root.Position.Y - world.Position.Y - call * H, spot.Z),
					turn = turn,
				})
			end
		end
	end
	-- carried with the car
	local function place(level: number)
		for _, rider in riders do
			if rider.root.Parent then
				local cf = world * CFrame.new(rider.spot + Vector3.new(0, level * H, 0)) * rider.turn
				local char = rider.root.Parent
				if char and char:IsA("Model") then
					char:PivotTo(cf * rider.root.CFrame:ToObjectSpace(char:GetPivot()))
				end
			end
		end
	end
	place(call)
	while now() < t0 + ride.arrived do
		place(LiftsSim.carAt(ride, now() - t0))
		RunService.Heartbeat:Wait()
	end
	place(to)
	for _, rider in riders do
		if rider.root.Parent then
			rider.root.Anchored = false
		end
	end
	rests[id] = to
	model = modelOf(i, key) or model -- (drawn again meanwhile: the new one)
	model:SetAttribute("LiftAt", to)
	gate(model, to, true)
	waitUntil(t0 + ride.closing)
	gate(modelOf(i, key), to, false)
	waitUntil(t0 + ride.done)
	busy[id] = nil
end

-- Someone held E at a lift's button on plot `i`: landing `floor`, up (dir 1) or down (-1).
function Lifts.pressed(player: Player, i: number, key: string, floor: any, dir: number)
	local t = os.clock()
	if t - (lastPress[player] or -math.huge) < K.Cooldown then
		return
	end
	local id = i .. ":" .. key
	if busy[id] then
		return
	end
	local _, def, world = liftOf(i, key)
	if not def or not world or type(floor) ~= "number" or floor % 1 ~= 0 then
		return
	end
	local spans = LiftsSim.spans(def)
	if floor < 0 or floor > spans then
		return
	end
	local to = LiftsSim.target(spans, floor, dir)
	if not to then
		return
	end
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return
	end
	local at = world:PointToObjectSpace(root.Position)
	if LiftsSim.landingOf(spans, at - Vector3.new(0, 3, 0)) ~= floor or not LiftsSim.atDoors(at) then
		return
	end
	lastPress[player] = t
	busy[id] = true
	task.spawn(function()
		local riders: { Rider } = {}
		local ok, why = pcall(run, i, key, player, floor, to, riders)
		if not ok then
			warn("[Lifts] " .. tostring(why))
			busy[id] = nil
			for _, rider in riders do
				if rider.root.Parent then
					rider.root.Anchored = false
				end
			end
		end
	end)
end

-- Where a prompt's signal is listened to (a seam for a spec).
function Lifts.listen(prompt: ProximityPrompt, fn: (Player) -> ())
	prompt.Triggered:Connect(fn)
end

-- A piece was just drawn on plot `i`: a lift gets its buttons, and its car where it was.
function Lifts.drawn(i: number, model: Instance)
	local key = model:GetAttribute("BuildKey")
	local id = model:GetAttribute("ItemId")
	if model:GetAttribute("BuildKind") ~= "items" or type(key) ~= "string" or type(id) ~= "string" then
		return
	end
	local def = Catalog.get(id)
	if not LiftsSim.isLift(def) then
		return
	end
	local spans = LiftsSim.spans(def)
	local at = math.clamp(rests[i .. ":" .. key] or 0, 0, spans)
	rests[i .. ":" .. key] = at
	model:SetAttribute("LiftAt", at)
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") and (d.Name == "LiftUp" or d.Name == "LiftDown") and not d:FindFirstChild(PROMPT) then
			local up = d.Name == "LiftUp"
			local floor = d:GetAttribute("Floor")
			local prompt = Instance.new("ProximityPrompt")
			prompt.Name = PROMPT
			prompt.ActionText = if up then "Up" else "Down"
			prompt.ObjectText = "Elevator"
			prompt.KeyboardKeyCode = Enum.KeyCode.E
			prompt.HoldDuration = K.Hold
			prompt.MaxActivationDistance = K.Reach
			prompt.RequiresLineOfSight = false
			prompt:SetAttribute("Plot", i)
			prompt:AddTag(LiftsSim.Tag)
			prompt.Parent = d
			Lifts.listen(prompt, function(who: Player)
				Lifts.pressed(who, i, key :: string, floor, if up then 1 else -1)
			end)
		end
	end
end

function Lifts.start()
	for i = 1, Tuning.Plot.Count do
		local ok, folder = pcall(Plots.buildFolder, i)
		if ok and folder then
			folder.ChildAdded:Connect(function(model)
				Lifts.drawn(i, model)
			end)
			for _, model in folder:GetChildren() do
				Lifts.drawn(i, model)
			end
		end
	end
	Players.PlayerRemoving:Connect(function(player)
		lastPress[player] = nil
	end)
end

return Lifts
