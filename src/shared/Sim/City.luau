--!strict
-- The city as numbers: how many people, how happy, how much is built, which level that makes it,
-- how much land you can buy next, and what everyone earns at work. Pure, shared by the server
-- (wages, buying land) and the interface (the city panel).

local Tuning = require(script.Parent.Parent.Config.Tuning)
local Plan = require(script.Parent.Parent.Build.Plan)
local Catalog = require(script.Parent.Parent.Build.Catalog)
local Jobs = require(script.Parent.Parent.Data.Jobs)

local City = {}

-- Workplaces on the plot, as { key, def, job }.
function City.workplaces(plan: any): { any }
	local out = {}
	if not plan then
		return out
	end
	local keys = {}
	for key in plan.items do
		table.insert(keys, key)
	end
	table.sort(keys, function(a, b)
		return (tonumber(a) or 0) < (tonumber(b) or 0)
	end)
	for _, key in keys do
		local def = Catalog.get(plan.items[key].id)
		local job = def and def.job and Jobs.get(def.job)
		if def and job then
			table.insert(out, { key = key, def = def, job = job })
		end
	end
	return out
end

-- The workplace key a villager works at, if it still exists.
function City.jobOf(profile: any, vid: string): any
	local v = profile.villagers[vid]
	if not v or not v.job then
		return nil
	end
	local item = profile.plan and profile.plan.items[v.job]
	local def = item and Catalog.get(item.id)
	local job = def and def.job and Jobs.get(def.job)
	if not job then
		return nil
	end
	return { key = v.job, def = def, job = job, item = item }
end

-- A workplace nobody works at yet (the oldest first).
function City.freeWorkplace(profile: any): string?
	local taken = {}
	for _, v in profile.villagers do
		if v.job then
			taken[v.job] = true
		end
	end
	for _, w in City.workplaces(profile.plan) do
		if not taken[w.key] then
			return w.key
		end
	end
	return nil
end

-- The level a town of that worth has reached. Worth is all a level asks for (the user: "make
-- the only requirements for growing towns worth instead of villagers or work requirement"); the
-- coins to build it still come mostly from villagers working.
function City.level(value: number): number
	local level = 1
	for i, lv in Tuning.City.Levels do
		if value >= lv.Value then
			level = i
		else
			break
		end
	end
	return level
end

-- How many villagers have a job at a workplace that still stands.
function City.workers(profile: any): number
	local n = 0
	for vid in profile.villagers do
		if City.jobOf(profile, vid) then
			n += 1
		end
	end
	return n
end

-- Adds skill points to a villager and takes them up a level for every Jobs.xpToNext they
-- fill. Returns how many levels they gained. (A day's work, events and a thank you of practice.)
function City.addSkill(v: any, amount: number): number
	local gained = 0
	v.lv = v.lv or 1
	v.xp = (v.xp or 0) + amount
	while v.lv < Tuning.Jobs.SkillCap and v.xp >= Jobs.xpToNext(v.lv) do
		v.xp -= Jobs.xpToNext(v.lv)
		v.lv += 1
		gained += 1
	end
	if v.lv >= Tuning.Jobs.SkillCap then
		v.xp = 0
	end
	return gained
end

-- What the town's buildings count for toward its next level: their value, with the starting
-- house counted at no more than Tuning.City.StarterWorth. The house every plot starts with was
-- made far bigger (the user: "improve the starting house detail by alot, and add a workspace next
-- to it"), and counting all of it would put a new town most of the way to Town before its owner
-- had built a thing. Old towns, whose houses carry no gift, count as they always did.
function City.worth(plan: any): number
	return Plan.value(plan) - math.max(0, Plan.giftValue(plan) - Tuning.City.StarterWorth)
end

-- Everything the city panel shows. The next level asks for `nextLevel.Value` of worth alone;
-- `population` and `employed` (how many villagers have a job) are there to show.
function City.stats(profile: any): any
	local population = 0
	local moodTotal = 0
	local employed = 0
	for vid, v in profile.villagers do
		population += 1
		moodTotal += v.mood
		if City.jobOf(profile, vid) then
			employed += 1
		end
	end
	local value = if profile.plan then City.worth(profile.plan) else 0
	local level = City.level(value)
	local nextLevel = Tuning.City.Levels[level + 1]
	local size = Plan.size(profile.plan)
	local nextLand = nil
	for _, land in Tuning.City.Land do
		if land.Size > size then
			nextLand = land
			break
		end
	end
	return {
		population = population,
		happiness = if population > 0 then math.floor(moodTotal / population + 0.5) else 0,
		value = value,
		jobs = #City.workplaces(profile.plan),
		employed = employed,
		level = level,
		levelName = Tuning.City.Levels[level].Name,
		nextLevel = nextLevel,
		land = size,
		nextLand = nextLand,
	}
end

-- Can the city buy its next piece of land? Returns the land entry or nil and a reason.
function City.canExpand(profile: any): (any?, string?)
	local stats = City.stats(profile)
	local land = stats.nextLand
	if not land then
		return nil, "Your land can't get any bigger."
	end
	if stats.level < land.Level then
		return nil, "Your town needs to grow first: reach " .. Tuning.City.Levels[land.Level].Name:lower() .. "."
	end
	if profile.coins < land.Price then
		return nil, "Not enough coins."
	end
	return land, nil
end

-- Wages --------------------------------------------------------------------------------------------
--
-- The user: "make it such that villagers earn coins as they work, not after every day". A day's
-- pay (Jobs.pay: the job's income for their skill, mood and liking) comes in a little at a time
-- while they are at their workplace in work hours: City.rate coins a second, the day's pay spread
-- over the seconds a worker usually spends there (City.workSeconds). Services/Villagers looks
-- every Tuning.Jobs.EarnStep seconds at who is at work and pays them through City.earn.

-- The seconds of a work day, nine to five on the town's clock.
function City.workDay(): number
	return (Tuning.Day.WorkEnd - Tuning.Day.WorkStart) / 24 * Tuning.Day.Length
end

-- The seconds of it a day's pay is spread over: the part a worker is usually at their workplace
-- (Tuning.Jobs.AtWork; the rest is the walk there and breaks).
function City.workSeconds(): number
	return City.workDay() * Tuning.Jobs.AtWork
end

-- What a villager earns for a whole day at work, or 0: no job (or its workplace is gone), their
-- day off, or sick.
function City.dayPay(profile: any, vid: string, day: number, now: number): number
	local v = profile.villagers[vid]
	local w = v and City.jobOf(profile, vid)
	if not w or v.dayOff == day or (v.sick ~= nil and v.sick > now) then
		return 0
	end
	return Jobs.pay(w.job, v.lv or 1, v.mood, v.pers)
end

-- Coins a second for being at their workplace.
function City.rate(profile: any, vid: string, day: number, now: number): number
	return City.dayPay(profile, vid, day, now) / City.workSeconds()
end

-- What each working villager earns in a whole day at work, the most first, and the sum (the city
-- panel's "a day's wages"). Villagers on a day off or sick earn nothing.
function City.wages(profile: any, day: number, now: number): ({ { vid: string, amount: number } }, number)
	local out = {}
	local total = 0
	for vid in profile.villagers do
		local amount = City.dayPay(profile, vid, day, now)
		if amount > 0 then
			table.insert(out, { vid = vid, amount = amount })
			total += amount
		end
	end
	table.sort(out, function(a, b)
		return a.amount > b.amount
	end)
	return out, total
end

-- One villager's earnings on one day, kept by the server while their body is about: `owed` is the
-- part of a coin not handed over yet, `paid` the whole coins that have been.
export type Purse = { day: number, owed: number, paid: number }

function City.newPurse(): Purse
	return { day = -1, owed = 0, paid = 0 }
end

-- Pays `seconds` at work at `rate` coins a second into a villager's purse for `day`, and takes
-- out the whole coins in it: those go to the town now, the rest waits for the next bit of work.
-- A new day starts the purse again, and nobody is paid more in a day than a whole work day at
-- their workplace would come to (the clock already sees to that; this is in case it jumps).
function City.earn(purse: Purse, day: number, rate: number, seconds: number): number
	if purse.day ~= day then
		purse.day, purse.owed, purse.paid = day, 0, 0
	end
	-- (no rate or time, or one that is not a number at all: nothing)
	if not (rate > 0 and rate < math.huge and seconds > 0 and seconds < math.huge) then
		return 0
	end
	local room = math.max(0, rate * City.workDay() - purse.paid - purse.owed)
	purse.owed += math.min(rate * seconds, room)
	local whole = math.floor(purse.owed + 1e-6)
	purse.owed = math.max(0, purse.owed - whole)
	purse.paid += whole
	return whole
end

-- The skill points a day's work is worth to a villager who was paid `paid` of a day's pay of
-- `full`: Tuning.Jobs.XpPerDay for a whole day, a share of it for part of one.
function City.dayXp(paid: number, full: number): number
	if paid <= 0 then
		return 0
	end
	local share = if full > 0 then math.min(1, paid / full) else 1
	return math.max(1, math.floor(Tuning.Jobs.XpPerDay * share + 0.5))
end

return City
