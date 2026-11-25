--!strict
-- Driving a vehicle (Services/Vehicles puts it together; Sim/Vehicles has the rules). The user:
-- "make vehicles, with faster ones with bigger capacities costing more, and gem ones being the
-- fastest". While this player sits at the wheel of their own vehicle, this drives its frame every
-- frame on their own screen (the server hands them the frame to move): the pedal (W/S, the thumb
-- stick) gathers or sheds speed toward the vehicle's top speed, the wheel (A/D) turns it, and it
-- rides at its height over whatever road or ground is under it, upright.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Tuning = require(Shared.Config.Tuning)
local VehicleData = require(Shared.Data.Vehicles)
local SimVehicles = require(Shared.Sim.Vehicles)

local Driving = {}

local K = Tuning.Vehicles

local speed = 0
local yaw: number? = nil
local driving: Model? = nil

local function stop(model: Model?)
	if model then
		local chassis = model:FindFirstChild("Chassis")
		local push = chassis and chassis:FindFirstChild("Push")
		local hold = chassis and chassis:FindFirstChild("Upright")
		if push and push:IsA("LinearVelocity") then
			push.VectorVelocity = Vector3.zero
			push.Enabled = false
		end
		if hold and hold:IsA("AlignOrientation") then
			hold.Enabled = false
		end
	end
	speed, yaw, driving = 0, nil, nil
end

function Driving.start()
	RunService.Heartbeat:Connect(function(dt)
		local char = Players.LocalPlayer.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local seat = hum and hum.SeatPart
		if not seat or not seat:IsA("VehicleSeat") or seat:GetAttribute("Vehicle") == nil then
			if driving then
				stop(driving)
			end
			return
		end
		local model = seat.Parent :: Model
		local v = VehicleData.get(seat:GetAttribute("Vehicle"))
		local chassis = model:FindFirstChild("Chassis")
		local push = chassis and chassis:FindFirstChild("Push")
		local hold = chassis and chassis:FindFirstChild("Upright")
		if not v or not chassis or not chassis:IsA("BasePart") or chassis.Anchored then
			return
		end
		if not push or not push:IsA("LinearVelocity") or not hold or not hold:IsA("AlignOrientation") then
			return
		end
		if driving ~= model then
			driving = model
			speed = 0
			local look = chassis.CFrame.LookVector
			yaw = math.atan2(-look.X, -look.Z)
		end
		push.Enabled, hold.Enabled = true, true
		-- the pedal and the wheel
		speed = SimVehicles.step(speed, seat.ThrottleFloat, v.speed, dt)
		local turn = SimVehicles.turnRate(speed, v.speed)
		yaw = (yaw :: number) - math.rad(turn) * seat.SteerFloat * dt
		local facing = CFrame.Angles(0, yaw :: number, 0)
		-- riding at its height over the ground under it, or falling where there is none
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = { model, char :: Instance }
		local pos = chassis.Position
		local hit = workspace:Raycast(pos + Vector3.new(0, 2, 0), Vector3.new(0, -(v.hover + 8), 0), params)
		local vy
		if hit then
			vy = math.clamp((hit.Position.Y + v.hover - pos.Y) * K.Settle, -40, 40)
		else
			vy = chassis.AssemblyLinearVelocity.Y - workspace.Gravity * dt
		end
		push.VectorVelocity = facing.LookVector * speed + Vector3.new(0, vy, 0)
		hold.CFrame = facing
	end)
end

return Driving
