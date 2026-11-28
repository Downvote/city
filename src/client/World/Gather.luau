--!strict
-- The prompts on pieces that give a player something (Services/Bag: a book from a bookshelf, a
-- dish from a stove, a flower from a flower bed). The server puts one on every such piece; this
-- side shows them on this player's own plot only, and not in Build mode. The server says no to
-- anyone else's press anyway. (As World/LightSwitch does for the lights.)

local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")

local BuildMode = require(script.Parent.Parent.Build.BuildMode)

local Gather = {}

Gather.Tag = "GatherPrompt" -- (Services/Bag.Tag)

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

function Gather.start()
	local function seen(prompt: Instance)
		if prompt:IsA("ProximityPrompt") then
			prompts[prompt] = true
			refresh(prompt)
		end
	end
	CollectionService:GetInstanceAddedSignal(Gather.Tag):Connect(seen)
	CollectionService:GetInstanceRemovedSignal(Gather.Tag):Connect(function(prompt)
		prompts[prompt :: any] = nil
	end)
	for _, prompt in CollectionService:GetTagged(Gather.Tag) do
		seen(prompt)
	end
	BuildMode.Changed:Connect(function(what)
		if what == "active" then
			refreshAll()
		end
	end)
	player:GetAttributeChangedSignal("Plot"):Connect(refreshAll)
end

return Gather
