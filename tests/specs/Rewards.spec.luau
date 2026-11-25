--!nocheck
-- The rewards a player claims (Sim/Rewards): the daily gift's coins and gems, gems for time played
-- today, achievements and the group. The user: "allow players to buy gems, as a daily reward,
-- certain achievements, playtime rewards, etc. and buying with robux. it should be a rare
-- currency". So a day of play brings a few gems at most, each claim pays once, playtime starts
-- again every day and comes in order, and an achievement only pays when the town has done it.

local Shared = "ReplicatedStorage.Shared."
local Tuning = require(Shared .. "Config.Tuning")
local Schema = require(Shared .. "Sim.Schema")
local City = require(Shared .. "Sim.City")
local Rewards = require(Shared .. "Sim.Rewards")
local Achievements = require(Shared .. "Data.Achievements")
local Playtime = require(Shared .. "Data.Playtime")
local Passes = require(Shared .. "Data.Passes")
local Appearance = require(Shared .. "Avatar.Appearance")
local StarterHouse = require(Shared .. "Data.StarterHouse")
local Rng = require(Shared .. "Util.Rng")

local G = Tuning.GemRewards
local E = Tuning.Economy
local DAY = 20000 -- a day index (days since 1970)

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

describe("Rewards", function()
	it("keeps gems rare: a usual day of play brings no more than the day's most", function()
		local playtime = 0
		for _, s in Playtime.steps do
			playtime += s.gems
		end
		-- the daily gift's gem, VIP's and every playtime step
		expect(G.Daily + G.Vip + playtime <= G.DayMax).toBeTruthy()
		-- the seventh day's extra is small too, and the steps get longer
		expect(G.Seventh - G.Daily <= 3).toBeTruthy()
		for i = 2, #Playtime.steps do
			expect(Playtime.steps[i].minutes > Playtime.steps[i - 1].minutes).toBeTruthy()
		end
		-- the cheapest pack is worth more than a week of the gift
		local cheapest = math.huge
		for _, pack in Passes.packs do
			cheapest = math.min(cheapest, pack.gems)
		end
		expect(cheapest >= G.Daily * 7).toBeTruthy()
		-- every achievement pays a few, all of them together a few dozen
		local all = 0
		for _, a in Achievements.list do
			expect(a.gems >= 1 and a.gems <= 10).toBeTruthy()
			all += a.gems
		end
		expect(all <= 60).toBeTruthy()
	end)

	it("pays the daily gift once a day, the streak's coins and a gem", function()
		local p = town(0)
		local ok, coins, gems = Rewards.claimDaily(p, DAY, false)
		expect(ok).toBe(true)
		expect(coins).toBe(E.DailyGift)
		expect(gems).toBe(G.Daily)
		-- not twice in a day
		ok = Rewards.claimDaily(p, DAY, false)
		expect(ok).toBe(false)
		expect(Rewards.dailyReady(p, DAY)).toBe(false)
		-- the next day: the streak grows
		ok, coins = Rewards.claimDaily(p, DAY + 1, false)
		expect(ok).toBe(true)
		expect(coins).toBe(E.DailyGift + E.DailyStreakBonus)
		expect(p.daily.streak).toBe(2)
		-- a day missed: it starts again
		ok, coins = Rewards.claimDaily(p, DAY + 3, false)
		expect(coins).toBe(E.DailyGift)
		expect(p.daily.streak).toBe(1)
		expect(p.daily.run).toBe(1)
	end)

	it("gives more gems on every seventh day running, and a gem more for VIP", function()
		local p = town(0)
		local got = {}
		for d = 1, 15 do
			local ok, coins, gems = Rewards.claimDaily(p, DAY + d, false)
			expect(ok).toBe(true)
			got[d] = gems
			-- the coins stop growing at the streak's cap
			expect(coins <= E.DailyGift + (E.DailyStreakCap - 1) * E.DailyStreakBonus).toBeTruthy()
		end
		expect(got[7]).toBe(G.Seventh)
		expect(got[14]).toBe(G.Seventh)
		expect(got[8]).toBe(G.Daily)
		expect(got[15]).toBe(G.Daily)
		expect(p.daily.streak).toBe(E.DailyStreakCap)
		expect(p.daily.run).toBe(15)
		local _, _, vip = Rewards.claimDaily(p, DAY + 16, true)
		expect(vip).toBe(G.Daily + G.Vip)
	end)

	it("takes an old save's daily gift as it was", function()
		-- (no run: it starts from the streak)
		local p = town(0)
		p.daily = { last = DAY - 1, streak = 6 }
		local ok, coins, gems = Rewards.claimDaily(p, DAY, false)
		expect(ok).toBe(true)
		expect(coins).toBe(E.DailyGift + 6 * E.DailyStreakBonus)
		expect(gems).toBe(G.Seventh)
		-- and broken data mends
		p.daily = "broken"
		expect(Rewards.dailyReady(p, DAY)).toBe(true)
		expect((Rewards.claimDaily(p, DAY, false))).toBe(true)
	end)

	it("counts playtime through the day, and starts again the next", function()
		local p = town(0)
		local first = Playtime.steps[1].minutes * 60
		expect(Rewards.tick(p, first - 10, DAY)).toBe(false)
		expect(Rewards.playtimeReady(p, DAY)).toBe(0)
		-- crossing a step says so
		expect(Rewards.tick(p, 10, DAY)).toBe(true)
		expect(Rewards.playtimeReady(p, DAY)).toBe(1)
		-- a count that isn't time adds nothing
		for _, bad in { 0, -50, 0 / 0, math.huge } do
			expect(Rewards.tick(p, bad, DAY)).toBe(false)
		end
		expect(p.playtime.secs).toBe(first)
		-- a new day: back to nothing
		Rewards.tick(p, 30, DAY + 1)
		expect(p.playtime.secs).toBe(30)
		expect(p.playtime.got).toBe(0)
		expect(p.playtime.day).toBe(DAY + 1)
	end)

	it("pays each playtime step once, in order, only once it's reached", function()
		local p = town(0)
		local ok, gems, why = Rewards.claimPlaytime(p, 1, DAY)
		expect(ok).toBe(false)
		expect(why).toBe("Not yet.")
		Rewards.tick(p, Playtime.steps[#Playtime.steps].minutes * 60, DAY)
		expect(Rewards.playtimeReady(p, DAY)).toBe(#Playtime.steps)
		-- out of order: no
		ok = Rewards.claimPlaytime(p, 2, DAY)
		expect(ok).toBe(false)
		local total = 0
		for i, s in Playtime.steps do
			ok, gems = Rewards.claimPlaytime(p, i, DAY)
			expect(ok).toBe(true)
			expect(gems).toBe(s.gems)
			total += gems
		end
		-- all had: nothing more today, whatever is asked
		ok, gems, why = Rewards.claimPlaytime(p, nil, DAY)
		expect(ok).toBe(false)
		expect(why).toBe("That's all of today's.")
		ok, gems, why = Rewards.claimPlaytime(p, 1, DAY)
		expect(ok).toBe(false)
		expect(why).toBe("You've had that one today.")
		expect(Rewards.playtimeReady(p, DAY)).toBe(0)
		expect(total <= G.DayMax).toBeTruthy()
		-- the next day they come again
		Rewards.tick(p, Playtime.steps[1].minutes * 60, DAY + 1)
		expect((Rewards.claimPlaytime(p, nil, DAY + 1))).toBe(true)
	end)

	it("pays an achievement once, when the town has done it", function()
		local p = town(1)
		expect((Rewards.claimAchievement(p, "villager5"))).toBe(false)
		local ok, gems = Rewards.claimAchievement(p, "villager1")
		expect(ok).toBe(true)
		expect(gems).toBe(Achievements.get("villager1").gems)
		expect(p.achieved.villager1).toBe(true)
		expect((Rewards.claimAchievement(p, "villager1"))).toBe(false)
		-- made up, or not a word
		expect((Rewards.claimAchievement(p, "nope"))).toBe(false)
		expect((Rewards.claimAchievement(p, 5))).toBe(false)
		-- a new plot has no workplace (the tutorial puts the bench down); the full starter house has one
		expect((Rewards.claimAchievement(p, "workplace"))).toBe(false)
		p.plan = StarterHouse.plan()
		expect((Rewards.claimAchievement(p, "workplace"))).toBe(true)
		-- best friends: two villagers who live here
		local q = town(2)
		q.rel[Schema.pairKey("v1", "v2")] = { s = Schema.BestFriends, n = 1 }
		expect((Rewards.claimAchievement(q, "bestfriends"))).toBe(true)
		-- cravings bought
		q.stats.cravings = 9
		expect((Rewards.claimAchievement(q, "cravings"))).toBe(false)
		q.stats.cravings = 10
		expect((Rewards.claimAchievement(q, "cravings"))).toBe(true)
	end)

	it("has an achievement for each town level past the first, and the villager milestones", function()
		for i = 2, #Tuning.City.Levels do
			local a = Achievements.get("level" .. i)
			expect(a ~= nil).toBeTruthy()
			expect(a.need).toBe(i)
		end
		for _, n in { 1, 5, 10 } do
			expect(Achievements.get("villager" .. n).need).toBe(n)
		end
		expect(Achievements.get("villager16").need).toBe(Tuning.Villagers.Start)
		expect(Achievements.get("villager50").need).toBe(Tuning.Villagers.Max)
		-- every one has a name, words and an icon, and the words read as a person would say them
		for _, a in Achievements.list do
			expect(#a.name > 0 and #a.desc > 0 and #a.icon > 0).toBeTruthy()
			expect(string.find(a.desc, "\u{2014}") == nil and string.find(a.desc, "\u{2013}") == nil).toBeTruthy()
			expect(string.find(a.desc, "!") == nil).toBeTruthy()
		end
		local list = Rewards.achievements(town(0))
		expect(#list).toBe(#Achievements.list)
	end)

	it("pays the group's gems once, to a member, when there is a group", function()
		local p = town(0)
		local was = Tuning.Group.Id
		Tuning.Group.Id = 0
		expect(Rewards.groupReady(p, true)).toBe(false)
		expect((Rewards.claimGroup(p, true))).toBe(false)
		Tuning.Group.Id = 777
		expect((Rewards.claimGroup(p, false))).toBe(false)
		local ok, gems = Rewards.claimGroup(p, true)
		expect(ok).toBe(true)
		expect(gems).toBe(G.Group)
		expect(Rewards.groupPaid(p)).toBe(true)
		expect((Rewards.claimGroup(p, true))).toBe(false)
		Tuning.Group.Id = was
	end)

	it("counts what is waiting for the badge", function()
		local p = town(1)
		-- today's gift and the first villager
		expect(Rewards.waiting(p, DAY, false)).toBe(2)
		Rewards.claimDaily(p, DAY, false)
		Rewards.claimAchievement(p, "villager1")
		expect(Rewards.waiting(p, DAY, false)).toBe(0)
		Rewards.tick(p, Playtime.steps[2].minutes * 60, DAY)
		expect(Rewards.waiting(p, DAY, false)).toBe(2)
		-- the next day the gift waits again, and yesterday's playtime is gone
		expect(Rewards.waiting(p, DAY + 1, false)).toBe(1)
		expect(City.stats(p).population).toBe(1)
	end)
end)
