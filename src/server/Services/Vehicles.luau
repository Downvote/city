--!strict
-- Vehicles: buying them, bringing one out and putting it away. The user: "make vehicles, with faster
-- ones with bigger capacities costing more, and gem ones being the fastest". Each player owns what
-- they bought (profile.vehicles, Sim/Vehicles) and has one out at a time, put together here from its
-- drawing (Data/Vehicles): an invisible frame part with every visible part welded to it, a driver's
-- seat (a VehicleSeat only its owner may take) and a seat for each passenger. While its owner
-- drives, the frame is theirs to move (network ownership) and client/World/Driving drives it; with
-- nobody at the wheel it is anchored where it stopped.

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Tuning = require(Shared.Config.Tuning)
local Remotes = require(Shared.Net.Remotes)
local Builder = require(Shared.Build.Builder)
local VehicleData = require(Shared.Data.Vehicles)
local SimVehicles = require(Shared.Sim.Vehicles)

local Data = require(script.Parent.Data)

local Vehicles = {}

local K = Tuning.Vehicles
local folder: Folder? = nil
local out: { [Player]: Model } = {}

local function holder(): Folder
	if not folder or not folder.Parent then
		local f = Instance.new("Folder")
		f.Name = "Vehicles"
		f.Parent = workspace
		folder = f
	end
	return folder :: Folder
end

-- Puts a player's vehicle away, if one is out.
function Vehicles.away(player: Player)
	local m = out[player]
	out[player] = nil
	player:SetAttribute("VehicleOut", nil)
	if m then
		m:Destroy()
	end
end

local function weld(a: BasePart, b: BasePart)
	local w = Instance.new("WeldConstraint")
	w.Part0, w.Part1 = a, b
	w.Parent = a
end

-- Where to bring it out: on the ground OutRange studs ahead of them, facing the way they face.
local function spotFor(root: BasePart, v: VehicleData.Vehicle): CFrame
	local look = root.CFrame.LookVector
	local flat = Vector3.new(look.X, 0, look.Z)
	flat = if flat.Magnitude > 0.01 then flat.Unit else Vector3.new(0, 0, -1)
	local at = root.Position + flat * (K.OutRange + v.size.Z / 2)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { holder(), root.Parent :: Instance }
	local hit = workspace:Raycast(at + Vector3.new(0, 12, 0), Vector3.new(0, -60, 0), params)
	local y = if hit then hit.Position.Y else root.Position.Y - 3
	return CFrame.lookAt(Vector3.new(at.X, y + v.hover, at.Z), Vector3.new(at.X, y + v.hover, at.Z) + flat)
end

-- Builds one in the world at `cf` (its frame: the wheels' middle), owned by `player`.
local function build(player: Player, v: VehicleData.Vehicle, cf: CFrame): Model
	local model = Instance.new("Model")
	model.Name = player.Name .. "'s " .. v.name
	model:SetAttribute("Vehicle", v.id)
	model:SetAttribute("Owner", player.UserId)
	local chassis = Instance.new("Part")
	chassis.Name = "Chassis"
	chassis.Size = Vector3.new(v.size.X - 0.4, 1, v.size.Z - 0.4)
	chassis.CFrame = cf
	chassis.Transparency = 1
	chassis.CanCollide = true
	chassis.Anchored = true
	chassis.Parent = model
	model.PrimaryPart = chassis
	for _, part in Builder.instantiate(VehicleData.prims(v), model, cf) do
		part.Anchored = false
		part.CanCollide = false
		part.Massless = true
		weld(chassis, part)
	end
	local function seat(class: string, at: Vector3, name: string): Seat | VehicleSeat
		local s = Instance.new(class) :: any
		s.Name = name
		s.Size = Vector3.new(1.6, 0.4, 1.6)
		s.Transparency = 1
		s.CanCollide = false
		s.Massless = true
		s.CFrame = cf * CFrame.new(at)
		s.Anchored = false
		s.Parent = model
		weld(chassis, s)
		return s
	end
	local driver = seat("VehicleSeat", v.driver, "Driver") :: VehicleSeat
	-- (the controller reads the pedal and the wheel from it and drives the frame itself)
	driver.MaxSpeed = v.speed
	driver.Torque = 0
	driver.HeadsUpDisplay = false
	driver:SetAttribute("Vehicle", v.id)
	for i, at in v.passengers do
		seat("Seat", at, "Passenger" .. i)
	end
	-- what drives it, off until somebody does (client/World/Driving switches them on)
	local att = Instance.new("Attachment")
	att.Name = "Drive"
	att.Parent = chassis
	local push = Instance.new("LinearVelocity")
	push.Name = "Push"
	push.Attachment0 = att
	push.RelativeTo = Enum.ActuatorRelativeTo.World
	push.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
	push.MaxForce = 1e7
	push.Enabled = false
	push.Parent = chassis
	local hold = Instance.new("AlignOrientation")
	hold.Name = "Upright"
	hold.Mode = Enum.OrientationAlignmentMode.OneAttachment
	hold.Attachment0 = att
	hold.MaxTorque = 1e7
	hold.Responsiveness = 30
	hold.CFrame = cf.Rotation
	hold.Enabled = false
	hold.Parent = chassis
	-- only its owner drives it; a driver who gets out leaves it standing where it is
	local stopToken = 0
	driver:GetPropertyChangedSignal("Occupant"):Connect(function()
		local hum = driver.Occupant
		if hum then
			local who = Players:GetPlayerFromCharacter(hum.Parent)
			if who ~= player then
				hum.Sit = false
				hum.Jump = true
				return
			end
			stopToken += 1
			chassis.Anchored = false
			pcall(function()
				chassis:SetNetworkOwner(player)
			end)
		else
			stopToken += 1
			local token = stopToken
			task.delay(1.5, function()
				if token == stopToken and chassis.Parent then
					chassis.Anchored = true
				end
			end)
		end
	end)
	model.Parent = holder()
	return model
end

-- Buys `id` for the player. Returns whether it did, and why not.
function Vehicles.buy(player: Player, id: any): (boolean, string?)
	local profile = Data.get(player)
	if not profile then
		return false, "Still loading."
	end
	local ok, why = SimVehicles.canBuy(profile, id)
	if not ok then
		return false, why
	end
	if not SimVehicles.buy(profile, id) then
		return false, "That didn't go through."
	end
	player:SetAttribute("Coins", profile.coins)
	Data.push(player, "coins", "gems", "vehicles")
	return true, nil
end

-- Brings one they own out in front of them (putting away any other first).
function Vehicles.bringOut(player: Player, id: any): (boolean, string?)
	local profile = Data.get(player)
	local v = VehicleData.get(id)
	if not profile or not v then
		return false, "There's no such vehicle."
	end
	if not SimVehicles.owns(profile, v.id) then
		return false, "You don't have that one yet."
	end
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return false, "Not just now."
	end
	Vehicles.away(player)
	out[player] = build(player, v, spotFor(root, v))
	player:SetAttribute("VehicleOut", v.id)
	return true, nil
end

function Vehicles.init() end

function Vehicles.start()
	Remotes.fn("VehicleBuy").OnServerInvoke = function(player: Player, id: any)
		local ok, a, b = pcall(Vehicles.buy, player, id)
		if not ok then
			return false, "That didn't go through."
		end
		return a, b
	end
	Remotes.fn("VehicleOut").OnServerInvoke = function(player: Player, id: any)
		local ok, a, b = pcall(Vehicles.bringOut, player, id)
		if not ok then
			return false, "That didn't go through."
		end
		return a, b
	end
	Remotes.fn("VehicleAway").OnServerInvoke = function(player: Player)
		Vehicles.away(player)
		return true
	end
	Players.PlayerRemoving:Connect(Vehicles.away)
	-- a profile's vehicles as saved: only ones there are
	Data.Loaded:Connect(function(_player: Player, profile: any)
		profile.vehicles = SimVehicles.clean(profile.vehicles)
	end)
end

return Vehicles
