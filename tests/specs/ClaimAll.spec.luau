--!nocheck
-- Claim all (Sim/ClaimAll): the user, "make a claim all button in rewards and in goals". One press
-- claims everything waiting through the same claims the single buttons use, so it pays what they
-- would have paid one at a time, never twice, never anything not yet due, and one notice says
-- what came in.

local Shared = "ReplicatedStorage.Shared."
local Tuning = require(Shared .. "Config.Tuning")
local Schema = require(Shared .. "Sim.Schema")
local Rewards = require(Shared .. "Sim.Rewards")
local Life = require(Shared .. "Sim.Life")
local ClaimAll = require(Shared .. "Sim.ClaimAll")
local Achievements = require(Shared .. "Data.Achievements")
local Goals = require(Shared .. "Data.Goals")
local Playtime = require(Shared .. "Data.Playtime")
local Appearance = require(Shared .. "Avatar.Appearance")
local StarterHouse = require(Shared .. "Data.StarterHouse")
local Rng = require(Shared .. "Util.Rng")

local G = Tuning.GemRewards
local E = Tuning.Economy
local DAY = 20000

local function town(count)
	local p = Schema.newProfile()
	p.plan = StarterHouse.newPlot()
	for i = 1, count do
		local input = Schema.cleanVillagerInput({ name = "V" .. i, pers = "sunny", app = Appearance.default() })
		p.villagers["v" .. i] = Schema.newVillager("v" .. i, input, Rng.new(i))
		table.insert(p.order, "v" .. i)
	end
	return p
end

local function deepCopy(t)
	if type(t) ~= "table" then
		return t
	end
	local out = {}
	for k, v in t do
		out[k] = deepCopy(v)
	end
	return out
end

describe("ClaimAll", function()
	it("claims the gift, the playtime reached, the achievements done and the group in one go", function()
		local p = town(1)
		p.plan = StarterHouse.plan() -- (the full starter house has a workplace)
		Rewards.tick(p, Playtime.steps[2].minutes * 60, DAY)
		local was = Tuning.Group.Id
		Tuning.Group.Id = 777
		local waiting = Rewards.waiting(p, DAY, true)
		local haul = ClaimAll.rewards(p, DAY, false, true)
		Tuning.Group.Id = was
		expect(haul.count).toBe(waiting)
		expect(haul.daily).toBe(true)
		expect(haul.playtime).toBe(2)
		expect(haul.group).toBe(true)
		expect(table.find(haul.achievements, "villager1") ~= nil).toBeTruthy()
		expect(table.find(haul.achievements, "workplace") ~= nil).toBeTruthy()
		-- coins from the gift, gems from all of it
		expect(haul.coins).toBe(E.DailyGift)
		local gems = G.Daily + Playtime.steps[1].gems + Playtime.steps[2].gems + G.Group
		for _, id in haul.achievements do
			gems += Achievements.get(id).gems
		end
		expect(haul.gems).toBe(gems)
		-- nothing is left, and nothing more comes of a second press
		expect(Rewards.waiting(p, DAY, true)).toBe(0)
		local again = ClaimAll.rewards(p, DAY, false, true)
		expect(again.count).toBe(0)
		expect(again.coins + again.gems).toBe(0)
		expect(ClaimAll.rewardsNotice(again)).toBe(nil)
	end)

	it("pays just what the single claims would have, one at a time", function()
		local p = town(1)
		p.plan = StarterHouse.plan()
		p.daily = { last = DAY - 1, streak = 6, run = 6 }
		Rewards.tick(p, Playtime.steps[#Playtime.steps].minutes * 60, DAY)
		local q = deepCopy(p)
		local haul = ClaimAll.rewards(p, DAY, true, false)
		-- the same, one button at a time
		local coins, gems = 0, 0
		local ok, c, g = Rewards.claimDaily(q, DAY, true)
		expect(ok).toBe(true)
		coins += c
		gems += g
		while true do
			local got, pg = Rewards.claimPlaytime(q, nil, DAY)
			if not got then
				break
			end
			gems += pg
		end
		for _, s in Rewards.achievements(q) do
			if s.done and not s.claimed then
				local got, ag = Rewards.claimAchievement(q, s.a.id)
				expect(got).toBe(true)
				gems += ag
			end
		end
		expect(haul.coins).toBe(coins)
		expect(haul.gems).toBe(gems)
		expect(p.daily.streak).toBe(q.daily.streak)
		expect(p.playtime.got).toBe(q.playtime.got)
		-- a seventh day and VIP: more gems with the gift
		expect(G.Seventh + G.Vip <= gems).toBeTruthy()
	end)

	it("leaves what isn't due: playtime not reached, an achievement not done, the group for a non-member", function()
		local p = town(0)
		Rewards.claimDaily(p, DAY, false)
		Rewards.tick(p, Playtime.steps[1].minutes * 60 - 5, DAY)
		local was = Tuning.Group.Id
		Tuning.Group.Id = 777
		local haul = ClaimAll.rewards(p, DAY, false, false)
		Tuning.Group.Id = was
		expect(haul.count).toBe(0)
		expect(haul.daily).toBe(false)
		expect(haul.playtime).toBe(0)
		expect(#haul.achievements).toBe(0)
		expect(haul.group).toBe(false)
		expect(Rewards.groupPaid(p)).toBe(false)
		expect(p.playtime.got).toBe(0)
		-- with no group made yet, a member gets nothing either
		local q = town(0)
		Tuning.Group.Id = 0
		expect(ClaimAll.rewards(q, DAY, false, true).group).toBe(false)
		Tuning.Group.Id = was
	end)

	it("claims every finished goal once, and their coins", function()
		local p = town(3)
		p.stats.wishes = 3
		local coins0 = p.coins
		local ready = {}
		for _, g in Life.goals(p) do
			if g.done and not g.claimed then
				table.insert(ready, g.goal.id)
			end
		end
		expect(#ready >= 2).toBeTruthy()
		local count, coins, ids = ClaimAll.goals(p)
		expect(count).toBe(#ready)
		expect(#ids).toBe(#ready)
		local sum = 0
		for _, id in ready do
			expect(p.goals[id]).toBe(true)
			expect(table.find(ids, id) ~= nil).toBeTruthy()
			sum += Goals.get(id).reward
		end
		expect(coins).toBe(sum)
		expect(p.coins).toBe(math.min(coins0 + sum, E.MaxCoins))
		-- the rest stay to do, and a second press finds nothing
		for _, g in Life.goals(p) do
			if not table.find(ready, g.goal.id) then
				expect(p.goals[g.goal.id] == true).toBe(false)
			end
		end
		local again, more = ClaimAll.goals(p)
		expect(again).toBe(0)
		expect(more).toBe(0)
		expect(ClaimAll.goalsNotice(again, more)).toBe(nil)
	end)

	it("says what came in, in one short notice", function()
		local both = { count = 4, coins = 450, gems = 6, daily = true, playtime = 1, achievements = {}, group = false }
		expect(ClaimAll.rewardsNotice(both)).toBe("4 rewards claimed. +450 coins, +6 gems")
		local gemsOnly =
			{ count = 1, coins = 0, gems = 1, daily = false, playtime = 1, achievements = {}, group = false }
		expect(ClaimAll.rewardsNotice(gemsOnly)).toBe("Reward claimed. +1 gem")
		local coinsOnly =
			{ count = 1, coins = 2500, gems = 0, daily = true, playtime = 0, achievements = {}, group = false }
		expect(ClaimAll.rewardsNotice(coinsOnly)).toBe("Reward claimed. +2,500 coins")
		expect(ClaimAll.goalsNotice(1, 300)).toBe("Goal done. +300 coins")
		expect(ClaimAll.goalsNotice(3, 1100)).toBe("3 goals done. +1,100 coins")
		for _, line in { ClaimAll.rewardsNotice(both), ClaimAll.goalsNotice(3, 1100) } do
			expect(line:find("\u{2014}") == nil and line:find("\u{2013}") == nil and line:find("!") == nil).toBeTruthy()
		end
	end)
end)
