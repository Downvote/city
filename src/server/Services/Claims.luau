-- Claim all (the user: "make a claim all button in rewards and in goals"). One press in the
-- Rewards menu claims everything waiting there (today's gift, the playtime steps reached, finished
-- achievements, the group's gems); one in the town goals claims every finished goal. The claims
-- themselves are Sim/ClaimAll's, which runs each through the same rule its own button uses
-- (Sim/Rewards, Sim/Life.claimGoal), so nothing is paid that a single claim wouldn't pay. The
-- client sends nothing but the press: everything is worked out here from the save. One notice
-- says what came in.

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Remotes = require(Shared.Net.Remotes)
local Passes = require(Shared.Sim.Passes)
local Rewards = require(Shared.Sim.Rewards)
local ClaimAll = require(Shared.Sim.ClaimAll)

local Data = require(script.Parent.Data)
local Store = require(script.Parent.Store)

local Claims = {}

local busy: { [Player]: boolean } = {} -- a press being worked out (the group check can wait on Roblox)

-- Is the player in the group, for the group's gems? As the Group button does it: asked of Roblox
-- afresh, but only when the gems are still owed and the server already took them for a member
-- (the InGroup attribute it set), so a press doesn't wait on Roblox for nothing.
local function member(player: Player, profile: any): boolean
	local known = false
	pcall(function()
		known = player:GetAttribute("InGroup") == true
	end)
	if not Rewards.groupReady(profile, known) then
		return false
	end
	local now = Store.memberNow(player)
	pcall(function()
		player:SetAttribute("InGroup", now)
	end)
	return now
end

function Claims.init() end

function Claims.start()
	Remotes.fn("RewardsClaimAll").OnServerInvoke = function(player)
		if busy[player] then
			return false, "Give it a moment."
		end
		local profile = Data.get(player)
		if not profile then
			return false, "Your save isn't in yet."
		end
		busy[player] = true
		local asked, inGroup = pcall(member, player, profile)
		busy[player] = nil
		-- (the save again: the group check can wait on Roblox, and the player may have gone)
		profile = Data.get(player)
		if not profile then
			return false, "Your save isn't in yet."
		end
		local haul = ClaimAll.rewards(profile, Rewards.today(), Passes.has(profile, "vip"), asked and inGroup == true)
		if haul.count <= 0 then
			return false, "Nothing to claim yet."
		end
		if haul.coins > 0 then
			Data.addCoins(player, haul.coins, true)
		end
		if haul.gems > 0 then
			Data.addGems(player, haul.gems, true)
		end
		Data.push(player, "coins", "gems", "daily", "playtime", "achieved")
		local notice = ClaimAll.rewardsNotice(haul)
		if notice then
			Data.notify(player, notice, "good")
		end
		return true, { count = haul.count, coins = haul.coins, gems = haul.gems }
	end

	Remotes.fn("GoalClaimAll").OnServerInvoke = function(player)
		local profile = Data.get(player)
		if not profile then
			return false, "Your save isn't in yet."
		end
		local count, coins = ClaimAll.goals(profile)
		if count <= 0 then
			return false, "Nothing to claim yet."
		end
		-- (Life.claimGoal put the coins in the save already)
		pcall(function()
			player:SetAttribute("Coins", profile.coins)
		end)
		Data.push(player, "goals", "coins")
		local notice = ClaimAll.goalsNotice(count, coins)
		if notice then
			Data.notify(player, notice, "good")
		end
		return true, { count = count, coins = coins }
	end

	Players.PlayerRemoving:Connect(function(player)
		busy[player] = nil
	end)
end

return Claims
