--!strict
-- The switch on the lights a player places (Sim/Lights). The server (Services/Lights) puts a prompt
-- on every placed light and words it "Turn off" or "Turn on" as the light is; this side shows
-- those prompts on this player's own plot only, and not in Build mode. The server says no to
-- anyone else's press anyway.

local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local LightsSim = require(Shared.Sim.Lights)

local BuildMode = require(script.Parent.Parent.Build.BuildMode)

local LightSwitch = {}

local player = Players.LocalPlayer
local prompts: { [ProximityPrompt]: boolean } = {}

local function refresh(prompt: ProximityPrompt)
	local plot = prompt:GetAttribute("Plot")
	local own = plot ~= nil and plot == player:GetAttribute("Plot")
	prompt.Enabled = own and not BuildMode.isActive()
end

local function refreshAll()
	for prompt in prompts do
		if prompt.Parent then
			refresh(prompt)
		else
			prompts[prompt] = nil
		end
	end
end

function LightSwitch.start()
	local function seen(prompt: Instance)
		if prompt:IsA("ProximityPrompt") then
			prompts[prompt] = true
			refresh(prompt)
		end
	end
	CollectionService:GetInstanceAddedSignal(LightsSim.Tag):Connect(seen)
	CollectionService:GetInstanceRemovedSignal(LightsSim.Tag):Connect(function(prompt)
		prompts[prompt :: any] = nil
	end)
	for _, prompt in CollectionService:GetTagged(LightsSim.Tag) do
		seen(prompt)
	end
	BuildMode.Changed:Connect(function(what)
		if what == "active" then
			refreshAll()
		end
	end)
	player:GetAttributeChangedSignal("Plot"):Connect(refreshAll)
end

return LightSwitch
