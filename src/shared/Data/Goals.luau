--!strict
-- Town goals: a list of things to work toward as the town grows, each paying coins when you claim
-- it. `value` reads how far along you are from the profile (and the city's stats).

local Goals = {}

export type Goal = {
	id: string,
	name: string,
	desc: string,
	need: number,
	reward: number,
	value: (profile: any, city: any) -> number,
}

local function bestHeart(profile: any): number
	local best = 0
	for _, v in profile.villagers do
		best = math.max(best, v.heart or 1)
	end
	return best
end

local function bestFriends(profile: any): number
	local n = 0
	for _, rel in profile.rel do
		if rel.s >= 80 then
			n += 1
		end
	end
	return n
end

local function stat(key: string): (any, any) -> number
	return function(profile: any, _city: any): number
		return profile.stats[key] or 0
	end
end

Goals.list = {
	{
		id = "settlers",
		name = "Neighbours",
		desc = "Have 3 villagers living in town.",
		need = 3,
		reward = 300,
		value = function(_p, city)
			return city.population
		end,
	},
	{
		id = "wishes3",
		name = "Helping hand",
		desc = "Grant 3 wishes.",
		need = 3,
		reward = 300,
		value = stat("wishes"),
	},
	{
		id = "heart5",
		name = "Close to you",
		desc = "Reach heart level 5 with a villager.",
		need = 5,
		reward = 500,
		value = function(p, _city)
			return bestHeart(p)
		end,
	},
	{
		id = "bestfriends",
		name = "Thick as thieves",
		desc = "Have two villagers become best friends.",
		need = 1,
		reward = 400,
		value = function(p, _city)
			return bestFriends(p)
		end,
	},
	{
		id = "couple",
		name = "Sweethearts",
		desc = "See a couple get together.",
		need = 1,
		reward = 600,
		value = stat("couples"),
	},
	{
		id = "town",
		name = "On the map",
		desc = "Grow into a Town.",
		need = 3,
		reward = 800,
		value = function(_p, city)
			return city.level
		end,
	},
	{
		id = "explore5",
		name = "Out and about",
		desc = "Find 5 places round the island.",
		need = 5,
		reward = 400,
		value = stat("found"),
	},
	{
		id = "wishes15",
		name = "Wish granter",
		desc = "Grant 15 wishes.",
		need = 15,
		reward = 1000,
		value = stat("wishes"),
	},
	{
		id = "partners",
		name = "Happily ever after",
		desc = "See a couple become partners for life.",
		need = 1,
		reward = 1200,
		value = stat("partners"),
	},
	{
		id = "full",
		name = "Full house",
		desc = "Have 10 villagers living in town.",
		need = 10,
		reward = 1500,
		value = function(_p, city)
			return city.population
		end,
	},
	{
		id = "heart10",
		name = "Inseparable",
		desc = "Reach heart level 10 with a villager.",
		need = 10,
		reward = 1500,
		value = function(p, _city)
			return bestHeart(p)
		end,
	},
	{
		id = "exploreAll",
		name = "Know every corner",
		desc = "Find every place on the island.",
		need = 16,
		reward = 2000,
		value = stat("found"),
	},
	{
		id = "city",
		name = "Bright lights",
		desc = "Grow into a City.",
		need = 5,
		reward = 3000,
		value = function(_p, city)
			return city.level
		end,
	},
} :: { Goal }

local byId: { [string]: Goal } = {}
for _, g in Goals.list do
	byId[g.id] = g
end

function Goals.get(id: string): Goal?
	return byId[id]
end

return Goals
