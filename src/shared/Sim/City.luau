--!strict
-- The city as numbers: how many people, how happy, how much is built, which level that makes it,
-- how much land you can buy next, and what everyone earns on payday. Pure, shared by the server
-- (paydays, buying land) and the interface (the city panel).

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

function City.level(population: number, value: number): number
	local level = 1
	for i, lv in Tuning.City.Levels do
		if population >= lv.Pop and value >= lv.Value then
			level = i
		end
	end
	return level
end

-- What the town's buildings count for toward its next level: their value, with the starting
-- house counted at no more than Tuning.City.StarterWorth. The house every plot starts with was
-- made far bigger (the user: "improve the starting house detail by alot, and add a workspace next
-- to it"), and counting all of it would put a new town most of the way to Town before its owner
-- had built a thing. Old towns, whose houses carry no gift, count as they always did.
function City.worth(plan: any): number
	return Plan.value(plan) - math.max(0, Plan.giftValue(plan) - Tuning.City.StarterWorth)
end

-- Everything the city panel shows.
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
	local level = City.level(population, value)
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

-- What each working villager earns today. Villagers on a day off or sick earn nothing.
function City.payday(profile: any, day: number, now: number): ({ { vid: string, amount: number } }, number)
	local out = {}
	local total = 0
	for vid, v in profile.villagers do
		local w = City.jobOf(profile, vid)
		local off = v.dayOff == day or (v.sick ~= nil and v.sick > now)
		if w and not off then
			local amount = Jobs.pay(w.job, v.lv or 1, v.mood, v.pers)
			table.insert(out, { vid = vid, amount = amount })
			total += amount
		end
	end
	table.sort(out, function(a, b)
		return a.amount > b.amount
	end)
	return out, total
end

return City
