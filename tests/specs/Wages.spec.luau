--!nocheck
-- Wages as villagers work (Sim/City). The user: "make it such that villagers earn coins as they
-- work, not after every day", after "could you make working give much more coins, and make
-- buildings cheaper?". A day's pay comes in a little at a time while a villager is at their
-- workplace: City.rate coins a second into their purse (City.earn), the whole coins handed over
-- as they come. Here the purse on its own: what a day comes to, what a few seconds come to, and
-- what it refuses. The Routine spec runs the real brain and its pay packets through work days.

local Shared = "ReplicatedStorage.Shared."
local Tuning = require(Shared .. "Config.Tuning")
local City = require(Shared .. "Sim.City")
local Jobs = require(Shared .. "Data.Jobs")
local Schema = require(Shared .. "Sim.Schema")
local StarterHouse = require(Shared .. "Data.StarterHouse")
local Appearance = require(Shared .. "Avatar.Appearance")
local Rng = require(Shared .. "Util.Rng")

local D, J = Tuning.Day, Tuning.Jobs

-- the starting house, its builder's bench taken by a villager at starting mood and skill
local function town()
	local p = Schema.newProfile()
	p.plan = StarterHouse.plan()
	local input = Schema.cleanVillagerInput({ name = "Mara", pers = "sunny", app = Appearance.default() })
	local v = Schema.newVillager("v1", input, Rng.new(1))
	v.job = City.workplaces(p.plan)[1].key
	v.dayOff = nil
	p.villagers.v1 = v
	table.insert(p.order, "v1")
	return p, v
end

describe("Wages", function()
	it("spreads a day's pay over the part of the work day a worker is at the workplace", function()
		expect(City.workDay()).toBeNear((D.WorkEnd - D.WorkStart) / 24 * D.Length, 1e-9)
		expect(City.workSeconds()).toBeNear(City.workDay() * J.AtWork, 1e-9)
		-- most of the day, never all of it: there is the walk there and a break or two
		expect(J.AtWork).toBeBetween(0.7, 0.95)
		local p, v = town()
		local full = City.dayPay(p, "v1", 1, 0)
		expect(full).toBe(Jobs.pay(City.jobOf(p, "v1").job, v.lv, v.mood, v.pers))
		expect(City.rate(p, "v1", 1, 0) * City.workSeconds()).toBeNear(full, 1e-6)
		-- nothing without a job, on their day off or while sick
		v.dayOff = 1
		expect(City.rate(p, "v1", 1, 0)).toBe(0)
		v.dayOff = nil
		v.sick = 100
		expect(City.rate(p, "v1", 1, 0)).toBe(0)
		expect(City.rate(p, "v1", 1, 200) > 0).toBeTruthy()
		v.sick = nil
		v.job = nil
		expect(City.rate(p, "v1", 1, 0)).toBe(0)
		expect(City.rate(p, "nobody", 1, 0)).toBe(0)
	end)

	it("pays every bit of work, a second at a time, and loses nothing between coins", function()
		local p = town()
		local rate = City.rate(p, "v1", 1, 0)
		local purse = City.newPurse()
		local got, coins = 0, 0
		-- a day at the workplace, looked at every EarnStep seconds
		local looks = math.floor(City.workSeconds() / J.EarnStep)
		for _ = 1, looks do
			local n = City.earn(purse, 1, rate, J.EarnStep)
			expect(n >= 0 and n % 1 == 0).toBeTruthy()
			if n > 0 then
				coins += 1
			end
			got += n
		end
		-- the whole of a day's pay, give or take the coin still in the purse
		expect(math.abs(got - City.dayPay(p, "v1", 1, 0)) <= rate * J.EarnStep + 1).toBeTruthy()
		expect(got + purse.owed).toBeNear(rate * looks * J.EarnStep, 1e-6)
		expect(purse.paid).toBe(got)
		-- a coin or more nearly every look, so the coins come in as they work
		expect(coins >= looks * 0.9).toBeTruthy()
		-- what a pay packet (PayEvery seconds) comes to at starting mood and skill is a handful
		-- of coins, and with the best of everything still no flood
		for _, job in Jobs.list do
			local start = Jobs.pay(job, 1, Tuning.Villagers.StartMood, "none") / City.workSeconds()
			expect(start * J.PayEvery).toBeBetween(10, 60)
			local best = Jobs.pay(job, J.SkillCap, 100, job.likes[1]) / City.workSeconds()
			expect(best * J.PayEvery <= 200).toBeTruthy()
		end
		expect(J.PayEvery >= J.EarnStep and J.PayEvery <= 10).toBeTruthy()
	end)

	it("starts again each day, and never pays more in one than a whole work day there", function()
		local purse = City.newPurse()
		local rate = 7.25
		expect(City.earn(purse, 4, rate, 10)).toBe(72)
		expect(purse.owed).toBeNear(0.5, 1e-9)
		-- a new day: the purse starts again (the half coin was the day before's)
		expect(City.earn(purse, 5, rate, 2)).toBe(14)
		expect(purse.day).toBe(5)
		expect(purse.paid).toBe(14)
		-- however long the clock says, a day comes to no more than the work day at that rate
		local most = rate * City.workDay()
		local got = 14 + City.earn(purse, 5, rate, 1e6)
		expect(got <= most + 1e-6).toBeTruthy()
		expect(got >= most - 1).toBeTruthy()
		expect(City.earn(purse, 5, rate, 60)).toBe(0)
	end)

	it("pays nothing for nothing, and nothing for nonsense", function()
		local purse = City.newPurse()
		expect(City.earn(purse, 1, 0, 10)).toBe(0)
		expect(City.earn(purse, 1, 5, 0)).toBe(0)
		expect(City.earn(purse, 1, 5, -10)).toBe(0)
		expect(City.earn(purse, 1, -5, 10)).toBe(0)
		expect(City.earn(purse, 1, 0 / 0, 10)).toBe(0)
		expect(City.earn(purse, 1, 5, 0 / 0)).toBe(0)
		expect(City.earn(purse, 1, 5, math.huge)).toBe(0)
		expect(City.earn(purse, 1, math.huge, 1)).toBe(0)
		expect(purse.paid).toBe(0)
		expect(purse.owed).toBe(0)
	end)

	it("teaches a whole day's skill for a whole day's work, and some for part of one", function()
		expect(City.dayXp(0, 1000)).toBe(0)
		expect(City.dayXp(1000, 1000)).toBe(J.XpPerDay)
		expect(City.dayXp(1180, 1000)).toBe(J.XpPerDay)
		expect(City.dayXp(500, 1000)).toBeNear(J.XpPerDay / 2, 0.51)
		expect(City.dayXp(3, 1000)).toBe(1)
		-- paid while they were well, sick by five: the day still counts
		expect(City.dayXp(400, 0)).toBe(J.XpPerDay)
	end)

	it("pays about one and a half times what a day of work did before both changes", function()
		-- the user: "could you make working give much more coins" (three times what it was), then
		-- "Also, halve money gain from work." A day's pay at starting mood and skill was 360 to 660
		-- (462 on average) before the first; a working villager earns five town days' pay in a
		-- real hour
		local sum = 0
		for _, job in Jobs.list do
			sum += Jobs.pay(job, 1, Tuning.Villagers.StartMood, "none")
		end
		local mean = sum / #Jobs.list
		expect(mean / 462.5).toBeBetween(1.35, 1.65)
		expect(J.Pay).toBe(0.5)
		-- the halving is on what the day pays, not on the incomes as written
		for _, job in Jobs.list do
			expect(job.income).toBe(math.floor(job.listed * J.Pay / 5 + 0.5) * 5)
		end
		expect(3600 / D.Length).toBe(5)
	end)
end)
