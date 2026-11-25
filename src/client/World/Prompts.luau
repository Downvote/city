--!strict
-- No prompt shows while the player is already using something. The user, with a picture of a
-- "Sit" prompt over the seat they were sitting on: "interaction bubbles shouldnt appear when you
-- are interacting with objects". So while they sit, work at a workplace (World/Work) or are in a
-- conversation scene (State's `talking`), every prompt on their screen is off; they come back the
-- moment that ends. Getting up is a jump and stopping work is a step, as before.

local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")

local State = require(script.Parent.Parent.Controllers.State)
local Work = require(script.Parent.Work)

local Prompts = {}

local CHECK = 0.25 -- seconds between looks, for what has no signal (work starting and stopping)

-- Is the player using something now? `hum` is their Humanoid, if they have one.
function Prompts.busy(hum: Humanoid?, working: boolean, talking: boolean): boolean
	if working or talking then
		return true
	end
	return hum ~= nil and (hum.Sit or hum.SeatPart ~= nil)
end

local function humanoid(): Humanoid?
	local char = Players.LocalPlayer.Character
	return if char then char:FindFirstChildOfClass("Humanoid") else nil
end

local function refresh()
	local off = Prompts.busy(humanoid(), Work.isWorking(), State.data.talking == true)
	if ProximityPromptService.Enabled == off then
		ProximityPromptService.Enabled = not off
	end
end

local function watch(char: Model)
	local hum = char:WaitForChild("Humanoid", 10)
	if hum and hum:IsA("Humanoid") then
		hum:GetPropertyChangedSignal("Sit"):Connect(refresh)
		hum:GetPropertyChangedSignal("SeatPart"):Connect(refresh)
	end
	refresh()
end

function Prompts.start()
	local player = Players.LocalPlayer
	player.CharacterAdded:Connect(watch)
	if player.Character then
		task.spawn(watch, player.Character)
	end
	State.on("talking", refresh)
	task.spawn(function()
		while true do
			task.wait(CHECK)
			refresh()
		end
	end)
end

return Prompts
