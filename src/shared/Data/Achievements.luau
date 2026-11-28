--!strict
-- Achievements: one-off milestones that pay gems once, when the player claims them (the user:
-- "allow players to buy gems, as a daily reward, certain achievements, playtime rewards, etc. ...
-- it should be a rare currency"). Like the town goals (Data/Goals), each reads how far along the
-- town is from the profile and the city's stats; Sim/Rewards says which are done and pays them.
-- Gems stay rare: these come to a few dozen over the whole of a town's growth, and each is paid
-- once (profile.achieved).

local Tuning = require(script.Parent.Parent.Config.Tuning)
local Text = require(script.Parent.Parent.Util.Text)

local Achievements = {}

export type Achievement = {
	id: string,
	name: string,
	desc: string,
	icon: string, -- UI/Icons
	need: number,
	gems: number,
	crate: string?, -- a crate it gives too, to open in the Store (Data/Crates: "work" or "pet")
	value: (profile: any, city: any) -> number,
}

local LEVELS = Tuning.Relationships.Levels
local BEST_FRIENDS = LEVELS[#LEVELS].Min

-- Pairs of villagers living in town who are best friends.
local function bestFriends(profile: any): number
	local n = 0
	for key, rel in if type(profile.rel) == "table" then profile.rel else {} do
		local a, b = string.match(key, "^(.-)|(.*)$")
		if type(rel) == "table" and type(rel.s) == "number" and rel.s >= BEST_FRIENDS then
			if a and b and profile.villagers[a] and profile.villagers[b] then
				n += 1
			end
		end
	end
	return n
end

local function population(_p: any, city: any): number
	return city.population
end

local function level(_p: any, city: any): number
	return city.level
end

local function townLevel(i: number, gems: number): Achievement
	-- (levels have numbers, not names: the user, "no need for level names, like city, etc.")
	return {
		id = "level" .. i,
		name = Text.fill("Level {n}", { n = i }),
		desc = Text.fill("Reach level {n}.", { n = i }),
		icon = "city",
		need = i,
		gems = gems,
		value = level,
	}
end

Achievements.list = {
	{
		id = "villager1",
		name = "First face",
		desc = "Make your first villager.",
		icon = "person",
		need = 1,
		gems = 2,
		value = population,
	},
	{
		id = "workplace",
		name = "Open for work",
		desc = "Put down a workplace.",
		icon = "briefcase",
		need = 1,
		gems = 2,
		value = function(_p, city)
			return city.jobs
		end,
	},
	{
		id = "villager5",
		name = "Five in town",
		desc = "5 villagers in town.",
		icon = "people",
		need = 5,
		gems = 3,
		value = population,
	},
	townLevel(2, 2),
	{
		id = "bestfriends",
		name = "Best friends",
		desc = "Two villagers become best friends.",
		icon = "heart",
		need = 1,
		gems = 3,
		value = function(p, _city)
			return bestFriends(p)
		end,
	},
	{
		id = "cravings",
		name = "Treats",
		desc = "Buy 10 cravings.",
		icon = "gift",
		need = 10,
		gems = 3,
		value = function(p, _city)
			local stats = p.stats
			return if type(stats) == "table" and type(stats.cravings) == "number" then stats.cravings else 0
		end,
	},
	townLevel(3, 3),
	{
		id = "villager10",
		name = "Ten in town",
		desc = "10 villagers in town.",
		icon = "people",
		need = 10,
		gems = 5,
		value = population,
	},
	townLevel(4, 5),
	{
		id = "villager16",
		name = "Every bed taken",
		desc = "16 villagers in town.",
		icon = "house",
		need = Tuning.Villagers.Start,
		gems = 8,
		value = population,
	},
	townLevel(5, 8),
	-- (levels have no top now, and the milestones give room for more villagers)
	townLevel(10, 3),
	{
		id = "villager30",
		name = "A full street",
		desc = "30 villagers in town.",
		icon = "people",
		need = 30,
		gems = 3,
		value = population,
	},
	townLevel(20, 4),
	{
		id = "villager50",
		name = "Fifty neighbours",
		desc = Text.fill("{n} villagers in town.", { n = Tuning.Villagers.Max }),
		icon = "house",
		need = Tuning.Villagers.Max,
		gems = 4,
		value = population,
	},
} :: { Achievement }

-- Some give a crate as well (the user: "Some work crates are also given through achievements,
-- goals, daily rewards"; pet crates come the same ways).
local CRATES: { [string]: string } = {
	villager5 = "pet",
	villager10 = "work",
	level5 = "work",
	villager30 = "pet",
	level10 = "work",
}

local byId: { [string]: Achievement } = {}
for _, a in Achievements.list do
	byId[a.id] = a
	a.crate = CRATES[a.id]
end

function Achievements.get(id: string): Achievement?
	return byId[id]
end

return Achievements
