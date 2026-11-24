-- The free camera of Build mode: orbit with the right mouse button (or one finger), pan with the
-- middle button, WASD or two fingers, zoom with the wheel or a pinch. It stays over your plot.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Tuning = require(Shared.Config.Tuning)

local BuildCamera = {}

local player = Players.LocalPlayer
local SIZE = Tuning.Plot.Size
-- how far out the camera may pull: far enough to see the whole plot (it was 220 on a plot of 200)
local FARTHEST = SIZE * 1.1

local active = false
local plotFrame = CFrame.identity
local focus = Vector3.zero -- plot-local
local focusHeight = 0
local yaw = math.rad(200)
local pitch = math.rad(50)
local distance = 90
local goalDistance = 90
local orbiting = false
local panning = false
local lastPos: Vector2? = nil
local connections: { RBXScriptConnection } = {}
local touchStart: { [InputObject]: Vector2 } = {}

BuildCamera.dragged = false -- true while a touch drag is moving the camera (so it isn't a tap)

local function clampFocus()
	focus = Vector3.new(math.clamp(focus.X, -20, SIZE + 20), 0, math.clamp(focus.Z, -20, SIZE + 20))
end

local function pan(dx: number, dy: number)
	-- move along the ground relative to where the camera faces
	local forward = Vector3.new(-math.sin(yaw), 0, -math.cos(yaw))
	local right = Vector3.new(math.cos(yaw), 0, -math.sin(yaw))
	local k = distance / 600
	focus += right * (-dx * k) + forward * (dy * k)
	clampFocus()
end

local function update(dt: number)
	local cam = workspace.CurrentCamera
	if not cam then
		return
	end
	-- keyboard panning
	if not UserInputService:GetFocusedTextBox() then
		local move = Vector3.zero
		local forward = Vector3.new(-math.sin(yaw), 0, -math.cos(yaw))
		local right = Vector3.new(math.cos(yaw), 0, -math.sin(yaw))
		if UserInputService:IsKeyDown(Enum.KeyCode.W) or UserInputService:IsKeyDown(Enum.KeyCode.Up) then
			move += forward
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.S) or UserInputService:IsKeyDown(Enum.KeyCode.Down) then
			move -= forward
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.D) or UserInputService:IsKeyDown(Enum.KeyCode.Right) then
			move += right
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.A) or UserInputService:IsKeyDown(Enum.KeyCode.Left) then
			move -= right
		end
		if move.Magnitude > 0 then
			focus += move.Unit * dt * (30 + distance * 0.5)
			clampFocus()
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.Q) then
			yaw += dt * 1.6
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.E) then
			yaw -= dt * 1.6
		end
	end
	distance += (goalDistance - distance) * math.min(1, dt * 10)
	local offset = Vector3.new(math.sin(yaw) * math.cos(pitch), math.sin(pitch), math.cos(yaw) * math.cos(pitch))
		* distance
	local target = plotFrame * (focus + Vector3.new(0, focusHeight, 0))
	local worldOffset = plotFrame:VectorToWorldSpace(offset)
	cam.CFrame = CFrame.lookAt(target + worldOffset, target)
	cam.Focus = CFrame.new(target)
end

function BuildCamera.setHeight(h: number)
	focusHeight = h
end

function BuildCamera.enable(frame: CFrame)
	if active then
		return
	end
	active = true
	plotFrame = frame
	focus = Vector3.new(SIZE / 2, 0, SIZE * 0.35)
	local cam = workspace.CurrentCamera
	cam.CameraType = Enum.CameraType.Scriptable
	table.insert(connections, RunService.RenderStepped:Connect(update))
	table.insert(
		connections,
		UserInputService.InputBegan:Connect(function(input, processed)
			if input.UserInputType == Enum.UserInputType.MouseButton2 then
				orbiting = true
				lastPos = Vector2.new(input.Position.X, input.Position.Y)
			elseif input.UserInputType == Enum.UserInputType.MouseButton3 then
				panning = true
				lastPos = Vector2.new(input.Position.X, input.Position.Y)
			elseif input.UserInputType == Enum.UserInputType.Touch and not processed then
				touchStart[input] = Vector2.new(input.Position.X, input.Position.Y)
				BuildCamera.dragged = false
			end
		end)
	)
	table.insert(
		connections,
		UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton2 then
				orbiting = false
			elseif input.UserInputType == Enum.UserInputType.MouseButton3 then
				panning = false
			elseif input.UserInputType == Enum.UserInputType.Touch then
				touchStart[input] = nil
			end
		end)
	)
	table.insert(
		connections,
		UserInputService.InputChanged:Connect(function(input, processed)
			if input.UserInputType == Enum.UserInputType.MouseMovement and lastPos then
				local p = Vector2.new(input.Position.X, input.Position.Y)
				local d = p - lastPos
				lastPos = p
				if orbiting then
					yaw -= d.X * 0.008
					pitch = math.clamp(pitch + d.Y * 0.006, math.rad(12), math.rad(85))
				elseif panning then
					pan(d.X, d.Y)
				end
			elseif input.UserInputType == Enum.UserInputType.MouseWheel and not processed then
				goalDistance = math.clamp(goalDistance * (if input.Position.Z > 0 then 0.88 else 1.14), 14, FARTHEST)
			elseif input.UserInputType == Enum.UserInputType.Touch and touchStart[input] then
				-- one finger drags orbit the camera once they move far enough
				local count = 0
				for _ in touchStart do
					count += 1
				end
				local start = touchStart[input]
				local p = Vector2.new(input.Position.X, input.Position.Y)
				if (p - start).Magnitude > 14 then
					BuildCamera.dragged = true
				end
				if count == 1 and BuildCamera.dragged then
					yaw -= input.Delta.X * 0.008
					pitch = math.clamp(pitch + input.Delta.Y * 0.006, math.rad(12), math.rad(85))
				end
			end
		end)
	)
	table.insert(
		connections,
		UserInputService.TouchPinch:Connect(function(_, scale, _, state)
			if state == Enum.UserInputState.Change then
				goalDistance = math.clamp(goalDistance / math.max(0.5, scale ^ 0.08), 14, FARTHEST)
			end
		end)
	)
	table.insert(
		connections,
		UserInputService.TouchPan:Connect(function(touches, translation, _, state)
			if #touches >= 2 and state == Enum.UserInputState.Change then
				BuildCamera.dragged = true
				pan(translation.X * 0.05, translation.Y * 0.05)
			end
		end)
	)
end

function BuildCamera.disable()
	if not active then
		return
	end
	active = false
	for _, c in connections do
		c:Disconnect()
	end
	connections = {}
	orbiting, panning, lastPos = false, false, nil
	local cam = workspace.CurrentCamera
	cam.CameraType = Enum.CameraType.Custom
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hum then
		cam.CameraSubject = hum
	end
end

function BuildCamera.isActive(): boolean
	return active
end

-- Looks at a plot-local point (used by the "find my villager" style jumps).
function BuildCamera.lookAt(p: Vector3)
	focus = Vector3.new(p.X, 0, p.Z)
	clampFocus()
end

return BuildCamera
