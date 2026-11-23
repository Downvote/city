-- Places to find round the island (Data/Places). The client says when its player reaches one;
-- the server checks they're really standing there, pays the coins once and marks it found. (There
-- was a map to travel back to them from; the user: "remove the map button and the map interface".)

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Places = require(Shared.Data.Places)
local Remotes = require(Shared.Net.Remotes)
local Text = require(Shared.Util.Text)
local Tuning = require(Shared.Config.Tuning)

local Data = require(script.Parent.Data)

local Explore = {}

local function rootOf(player: Player): BasePart?
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root else nil
end

-- Marks a place found for a player if they're standing at it. Returns whether it's newly found.
function Explore.found(player: Player, id: any): boolean
	local profile = Data.get(player)
	local place = Places.get(id)
	local root = rootOf(player)
	if not profile or not place or not root or profile.found[place.id] then
		return false
	end
	if not Places.near(place, root.Position) then
		return false
	end
	profile.found[place.id] = true
	profile.stats.found = (profile.stats.found or 0) + 1
	if place.coins > 0 then
		profile.coins = math.clamp(profile.coins + place.coins, 0, Tuning.Economy.MaxCoins)
		Data.notify(
			player,
			Text.fill("Found {place}. +{n} coins", { place = place.name, n = Text.commas(place.coins) }),
			"good"
		)
	end
	Data.push(player, "found", "coins", "stats")
	return true
end

function Explore.start()
	Remotes.fn("PlaceFound").OnServerInvoke = function(player, id)
		return Explore.found(player, id)
	end
end

return Explore
