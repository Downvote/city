--!strict
-- Carrying a thing, on this screen. The server (Services/Bag) puts the little model of a thing in
-- the player's right hand and sets their `Holding` attribute; the model stands up out of the fist
-- the way a tool's handle does (Data/ThingModels). While `Holding` is set this side holds the arm
-- out in front, as Roblox holds it for a tool: the body's own `toolnone` animation from its
-- Animate script (Roblox's own for R15 and R6 when there is none), which only moves the right arm,
-- so walking, running and jumping go on under it. It is played on the player's own character, so
-- everyone else sees it too. A job's motion or an emote (Action) plays over it while it lasts.
-- The user: "some of them are held wrongly, such as the flowers being held upside down".

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Tuning = require(Shared.Config.Tuning)

local Carry = {}

local player = Players.LocalPlayer

-- Roblox's own arm out for a tool, for a body whose Animate script has none.
local HOLD = {
	R15 = "rbxassetid://507768375",
	R6 = "rbxassetid://182393478",
}

local track: AnimationTrack? = nil
local trackFor: Model? = nil
local token = 0 -- a new one every look: a look that waited and is no longer the last stands down

-- The animation the body's Animate script holds a tool with, or Roblox's for its rig.
function Carry.animId(char: Model): string?
	local animate = char:FindFirstChild("Animate")
	local folder = animate and animate:FindFirstChild("toolnone")
	if folder then
		for _, a in folder:GetChildren() do
			if a:IsA("Animation") and a.AnimationId ~= "" then
				return a.AnimationId
			end
		end
	end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum then
		return nil
	end
	return if hum.RigType == Enum.HumanoidRigType.R15 then HOLD.R15 else HOLD.R6
end

local function stop()
	local t = track
	track = nil
	trackFor = nil
	if t then
		t:Stop(Tuning.Carry.Fade)
		task.delay(Tuning.Carry.Fade + 0.1, function()
			t:Destroy()
		end)
	end
end

local function refresh()
	token += 1
	local mine = token
	local char = player.Character
	local holding = player:GetAttribute("Holding") ~= nil
	if not holding or not char then
		stop()
		return
	end
	if track and trackFor == char then
		return
	end
	stop()
	local hum = char:FindFirstChildOfClass("Humanoid")
	local animator = hum and (hum:FindFirstChildOfClass("Animator") or hum:WaitForChild("Animator", 3))
	local id = Carry.animId(char)
	if not animator or not animator:IsA("Animator") or not id then
		return
	end
	local anim = Instance.new("Animation")
	anim.AnimationId = id
	local ok, loaded = pcall(function()
		return (animator :: Animator):LoadAnimation(anim)
	end)
	if not ok or not loaded then
		return
	end
	local t: AnimationTrack = loaded
	-- (the priority a tool's hold has in Roblox's own Animate script: over walking and standing,
	-- under a job's motion and an emote)
	t.Priority = Enum.AnimationPriority.Idle
	t.Looped = true
	t:Play(Tuning.Carry.Fade)
	-- (the attribute may have gone, or another look begun, while it loaded)
	if mine ~= token or player:GetAttribute("Holding") == nil or player.Character ~= char then
		t:Stop(0)
		t:Destroy()
		return
	end
	track = t
	trackFor = char
end

function Carry.isHolding(): boolean
	return track ~= nil
end

function Carry.start()
	player:GetAttributeChangedSignal("Holding"):Connect(function()
		task.spawn(refresh)
	end)
	player.CharacterAdded:Connect(function()
		stop()
		task.defer(refresh)
	end)
	task.spawn(refresh)
end

return Carry
