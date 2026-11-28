--!strict
-- Claim all (the user: "make a claim all button in rewards and in goals"): one press claims
-- everything waiting in the Rewards menu (today's gift, the playtime steps reached, finished
-- achievements, the group's gems) or every finished town goal. Each goes through the same claim
-- its own button uses (Sim/Rewards, Sim/Life.claimGoal), one after another, so the rules are the
-- same and nothing is paid twice. Like those, nothing here pays coins or gems out: it marks what
-- was claimed and says what it came to, and the server (Services/Claims) pays it. No services, so
-- the specs run it.

local Achievements = require(script.Parent.Parent.Data.Achievements)
local Goals = require(script.Parent.Parent.Data.Goals)
local Playtime = require(script.Parent.Parent.Data.Playtime)
local Text = require(script.Parent.Parent.Util.Text)
local Rewards = require(script.Parent.Rewards)
local Life = require(script.Parent.Life)
local CrateData = require(script.Parent.Parent.Data.Crates)

local ClaimAll = {}

-- What a press of Claim all in the Rewards menu came to.
export type Haul = {
	count: number, -- how many things were claimed
	coins: number,
	gems: number,
	daily: boolean, -- today's gift was among them
	playtime: number, -- how many playtime steps
	achievements: { string }, -- the ids of the achievements
	group: boolean, -- the group's gems
	crates: { string }, -- the crates the gift and the achievements gave, by kind (now held: Sim/Crates)
}

-- Claims everything waiting in the Rewards menu on `today`. `vip` and `inGroup` are what the
-- server knows of the player (Sim/Passes, the InGroup attribute). Returns what it came to.
function ClaimAll.rewards(profile: any, today: number, vip: boolean?, inGroup: boolean?): Haul
	local haul: Haul = {
		count = 0,
		coins = 0,
		gems = 0,
		daily = false,
		playtime = 0,
		achievements = {},
		group = false,
		crates = {},
	}
	local ok, coins, gems, crate = Rewards.claimDaily(profile, today, vip)
	if ok then
		haul.daily = true
		haul.count += 1
		haul.coins += coins
		haul.gems += gems
		if crate then
			table.insert(haul.crates, crate)
		end
	end
	-- the playtime steps go in order, the next one each time, until one isn't reached
	for _ = 1, #Playtime.steps do
		local got, stepGems = Rewards.claimPlaytime(profile, nil, today)
		if not got then
			break
		end
		haul.playtime += 1
		haul.count += 1
		haul.gems += stepGems
	end
	for _, a in Achievements.list do
		local got, aGems, aCrate = Rewards.claimAchievement(profile, a.id)
		if got then
			table.insert(haul.achievements, a.id)
			haul.count += 1
			haul.gems += aGems
			if aCrate then
				table.insert(haul.crates, aCrate)
			end
		end
	end
	local got, groupGems = Rewards.claimGroup(profile, inGroup)
	if got then
		haul.group = true
		haul.count += 1
		haul.gems += groupGems
	end
	return haul
end

-- Claims every finished town goal (Life.claimGoal adds its coins to the profile). Returns how
-- many, the coins they paid and their ids.
function ClaimAll.goals(profile: any): (number, number, { string })
	local count, coins, ids = 0, 0, {}
	for _, g in Goals.list do
		local ok, paid = Life.claimGoal(profile, g.id)
		if ok then
			count += 1
			coins += paid
			table.insert(ids, g.id)
		end
	end
	return count, coins, ids
end

-- What crates a claim brought, said once: "A work crate is in the Store.", "2 crates are in the
-- Store." (nil for none).
function ClaimAll.cratesNotice(kinds: { string }): string?
	if #kinds == 0 then
		return nil
	elseif #kinds == 1 then
		local kind = CrateData.get(kinds[1])
		return Text.fill("Your {x} is in the Store.", { x = if kind then string.lower(kind.name) else "crate" })
	end
	return Text.fill("{n} crates are in the Store.", { n = #kinds })
end

-- The one notice that says what a press brought in (nil when it brought nothing).
function ClaimAll.rewardsNotice(haul: Haul): string?
	if haul.count <= 0 then
		return nil
	end
	local head = if haul.count == 1 then "Reward claimed." else Text.fill("{n} rewards claimed.", { n = haul.count })
	if haul.coins > 0 and haul.gems > 0 then
		return Text.fill(
			"{head} +{c} coins, +{g}",
			{ head = head, c = Text.commas(haul.coins), g = Text.gems(haul.gems) }
		)
	elseif haul.coins > 0 then
		return Text.fill("{head} +{c} coins", { head = head, c = Text.commas(haul.coins) })
	elseif haul.gems > 0 then
		return Text.fill("{head} +{g}", { head = head, g = Text.gems(haul.gems) })
	end
	return head
end

function ClaimAll.goalsNotice(count: number, coins: number): string?
	if count <= 0 then
		return nil
	elseif count == 1 then
		return Text.fill("Goal done. +{n} coins", { n = Text.commas(coins) })
	end
	return Text.fill("{k} goals done. +{n} coins", { k = count, n = Text.commas(coins) })
end

return ClaimAll
