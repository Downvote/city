-- The titles players wear (Sim/Titles). The user: "add more rewards to quests, like titles". A
-- title is won from a town goal (Life.claimGoal) and picked on the Goals menu's Titles tab (the
-- TitleWear remote, checked here). Worn, it hangs under the player's name over their head for
-- everyone to see: the name and the title are drawn together (Util/TitleTag) in a BillboardGui on
-- the head, and Roblox's own name over them is turned off while it does; with none worn, Roblox's
-- name is back.

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Tuning = require(Shared.Config.Tuning)
local Titles = require(Shared.Sim.Titles)
local TitleTag = require(Shared.Util.TitleTag)
local Remotes = require(Shared.Net.Remotes)

local Data = require(script.Parent.Data)

local K = Tuning.Titles

local TitleService = {}

-- Hangs the worn title over a player's head, or takes it down.
function TitleService.show(player: Player)
	local char = player.Character
	local head = char and char:FindFirstChild("Head")
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not char or not head or not head:IsA("BasePart") then
		return
	end
	local old = head:FindFirstChild("NameTag")
	if old then
		old:Destroy()
	end
	local profile = Data.get(player)
	local worn = profile and Titles.worn(profile)
	if hum then
		hum.DisplayDistanceType = if worn
			then Enum.HumanoidDisplayDistanceType.None
			else Enum.HumanoidDisplayDistanceType.Viewer
	end
	if not worn then
		return
	end
	local gui = Instance.new("BillboardGui")
	gui.Name = "NameTag"
	gui.Size = UDim2.fromOffset(TitleTag.Width, TitleTag.Height)
	gui.StudsOffsetWorldSpace = Vector3.new(0, K.Height, 0)
	gui.MaxDistance = K.Distance
	gui.LightInfluence = 0
	gui.Adornee = head
	TitleTag.build(player.DisplayName, worn.name).Parent = gui
	gui.Parent = head
end

function TitleService.start()
	Remotes.fn("TitleWear").OnServerInvoke = function(player, id)
		local profile = Data.get(player)
		if not profile then
			return false, "Not ready yet."
		end
		if id ~= false and type(id) ~= "string" then
			return false, nil
		end
		local ok, why = Titles.wear(profile, id)
		if ok then
			Data.push(player, "title")
			TitleService.show(player)
		end
		return ok, why
	end
	local function watch(player: Player)
		player.CharacterAdded:Connect(function(char)
			char:WaitForChild("Head", 10)
			TitleService.show(player)
		end)
		if player.Character then
			task.spawn(TitleService.show, player)
		end
	end
	Players.PlayerAdded:Connect(watch)
	for _, player in Players:GetPlayers() do
		watch(player)
	end
	Data.Loaded:Connect(function(player)
		TitleService.show(player)
	end)
end

return TitleService
