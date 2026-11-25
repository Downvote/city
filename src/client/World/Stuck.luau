--!strict
-- Getting out of a tight spot. The user: "some areas cause you to get stuck, make it such that if
-- players being stuck is detected, allow them to clip out of it". A player who keeps pushing one
-- way and gets nowhere for a moment (Sim/Unstick.pushedNowhere) is offered a button; pressing it
-- asks the server to slip them out a few studs the way they were pushing, onto the nearest spot
-- with room (Services/Unstick, `SlipOut`). Pushing into a plain wall shows it too, which does no
-- harm: it is only an offer, and it goes as soon as they move again.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Remotes = require(Shared.Net.Remotes)
local UnstickSim = require(Shared.Sim.Unstick)

local Kit = require(script.Parent.Parent.UI.Kit)
local State = require(script.Parent.Parent.Controllers.State)
local BuildMode = require(script.Parent.Parent.Build.BuildMode)

local T = Kit.Theme

local Stuck = {}

local W, H = 210, 48
local SHOWN = UDim2.new(0.5, 0, 1, -96)
local HIDDEN = UDim2.new(0.5, 0, 1, H + 40)
local SLIDE = TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

local button: TextButton? = nil
local shown = false
local lastPush = Vector3.zero
local busy = false
local shownAt = 0

-- Is the player walking (not sitting, climbing, swimming or in Build mode)?
local function walking(hum: Humanoid): boolean
	if hum.Sit or hum.Health <= 0 or BuildMode.isActive() or State.data.talking == true then
		return false
	end
	local state = hum:GetState()
	return state == Enum.HumanoidStateType.Running or state == Enum.HumanoidStateType.RunningNoPhysics
end

local function show(on: boolean)
	if on == shown then
		return
	end
	shown = on
	local b = button
	if not b or not b.Parent then
		if not on then
			return
		end
		b = Kit.button("Stuck? Slip out", {
			Name = "SlipOut",
			Size = UDim2.fromOffset(W, H),
			AnchorPoint = Vector2.new(0.5, 1),
			Position = HIDDEN,
			Color = T.Blue,
			TextSize = 18,
			Parent = Kit.root(),
		}, function()
			if busy then
				return
			end
			busy = true
			task.spawn(function()
				local ok, moved = pcall(function()
					return Remotes.fn("SlipOut"):InvokeServer(lastPush)
				end)
				busy = false
				if ok and moved then
					show(false)
				end
			end)
		end)
		button = b
	end
	TweenService:Create(b :: TextButton, SLIDE, { Position = if on then SHOWN else HIDDEN }):Play()
end

function Stuck.start()
	local trail: { { any } } = {}
	local since = 0
	RunService.Heartbeat:Connect(function(dt)
		since += dt
		if since < 0.25 then
			return
		end
		since = 0
		local char = Players.LocalPlayer.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if not hum or not root or not root:IsA("BasePart") then
			show(false)
			return
		end
		local push = hum.MoveDirection
		local pushing = push.Magnitude > 0.3 and walking(hum)
		if pushing then
			lastPush = push
		end
		local now = os.clock()
		local stuck = UnstickSim.pushedNowhere(trail, now, root.Position, pushing)
		if stuck then
			shownAt = now
			show(true)
		elseif pushing then
			-- (walking again: it goes)
			show(false)
		elseif shown and now - shownAt > 8 then
			-- (left up while they reach for the button, then gone if they don't)
			show(false)
		end
	end)
end

return Stuck
