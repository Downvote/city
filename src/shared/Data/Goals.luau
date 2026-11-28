--!strict
-- Town goals: a list of things to work toward as the town grows, each paying coins when you claim
-- it. `value` reads how far along you are from the profile (and the city's stats). None is about
-- a shop: there is none. Nor romance: best friends is as close as two villagers get.
-- Some pay more than coins (the user: "add more rewards to quests, like titles, special buildings,
-- special gifts, etc."): `title` a title to wear under your name (Data/Titles), `piece` a Build mode
-- piece that is yours to put down for free (a keepsake from Build/Recipes/Prizes, Sim/Keepsakes) and
-- `thing` something for the bag (Data/Items, a treasure most often). Life.claimGoal pays them all.

local Tuning = require(script.Parent.Parent.Config.Tuning)

local Goals = {}

local LEVELS = Tuning.Relationships.Levels
local BEST_FRIENDS = LEVELS[#LEVELS].Min

export type Goal = {
	id: string,
	name: string,
	desc: string,
	need: number,
	reward: number,
	title: string?,
	piece: string?,
	thing: string?,
	value: (profile: any, city: any) -> number,
}

local function bestHeart(profile: any): number
	local best = 0
	for _, v in profile.villagers do
		best = math.max(best, v.heart or 1)
	end
	return best
end

-- Pairs of villagers living in town who are best friends.
local function bestFriends(profile: any): number
	local n = 0
	for key, rel in profile.rel do
		local a, b = key:match("^(.-)|(.*)$")
		if rel.s >= BEST_FRIENDS and profile.villagers[a] and profile.villagers[b] then
			n += 1
		end
	end
	return n
end

local function bestSkill(profile: any): number
	local best = 0
	for _, v in profile.villagers do
		best = math.max(best, v.lv or 1)
	end
	return best
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
		title = "neighbour",
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
	-- the bag and gifts (Sim/Bag, Sim/Gifts)
	{
		id = "gifts5",
		name = "Thoughtful",
		desc = "Give villagers 5 gifts.",
		need = 5,
		reward = 300,
		title = "giver",
		value = stat("gifts"),
	},
	{
		id = "gather20",
		name = "Forager",
		desc = "Gather 20 things round your town.",
		need = 20,
		reward = 300,
		title = "forager",
		thing = "luckycoin",
		value = stat("gathered"),
	},
	-- Work is what a town lives on (the user: "progression is much more based on villagers
	-- working"), so its goals run through the list: people in a job, wages earned, skill.
	{
		id = "work2",
		name = "Off to work",
		desc = "Have 2 villagers in a job.",
		need = 2,
		reward = 300,
		value = function(_p, city)
			return city.employed
		end,
	},
	{
		id = "cook10",
		name = "Home cooking",
		desc = "Cook 10 dishes at a stove or a grill.",
		need = 10,
		reward = 400,
		title = "cook",
		value = stat("cooked"),
	},
	{
		id = "heart5",
		name = "Close to you",
		desc = "Reach heart level 5 with a villager.",
		need = 5,
		reward = 500,
		title = "kind",
		thing = "musicbox",
		value = function(p, _city)
			return bestHeart(p)
		end,
	},
	{
		id = "bestfriends",
		name = "Thick as thieves",
		desc = "Make two villagers best friends.",
		need = 1,
		reward = 400,
		title = "friendmaker",
		value = function(p, _city)
			return bestFriends(p)
		end,
	},
	{
		id = "wages",
		name = "Pay packets",
		-- (it was 5,000 when a day's work paid a third of what it does now)
		desc = "Earn 15,000 coins in wages.",
		need = 15000,
		reward = 500,
		thing = "goldacorn",
		value = stat("earned"),
	},
	{
		id = "town",
		name = "On the map",
		desc = "Grow into a Town.",
		need = 3,
		reward = 800,
		title = "founder",
		piece = "prize_clock",
		value = function(_p, city)
			return city.level
		end,
	},
	{
		id = "work6",
		name = "All hands",
		desc = "Have 6 villagers in a job.",
		need = 6,
		reward = 800,
		value = function(_p, city)
			return city.employed
		end,
	},
	{
		id = "skill5",
		name = "Knows the ropes",
		desc = "Reach skill 5 in any job.",
		need = 5,
		reward = 700,
		title = "foreman",
		value = function(p, _city)
			return bestSkill(p)
		end,
	},
	{
		id = "explore5",
		name = "Out and about",
		desc = "Find 5 places round the island.",
		need = 5,
		reward = 400,
		title = "wanderer",
		value = stat("found"),
	},
	{
		id = "wishes15",
		name = "Wish granter",
		desc = "Grant 15 wishes.",
		need = 15,
		reward = 1000,
		title = "wishgranter",
		value = stat("wishes"),
	},
	{
		id = "gifts30",
		name = "Generous",
		desc = "Give villagers 30 gifts.",
		need = 30,
		reward = 1200,
		thing = "musicbox",
		value = stat("gifts"),
	},
	-- (two goals about romance stood here, the first couple and partners for life; the user:
	-- "remove any romance, just best friends is the highest")
	{
		id = "bestfriends3",
		name = "Close knit",
		desc = "Have three pairs of best friends.",
		need = 3,
		reward = 1200,
		piece = "prize_bandstand",
		value = function(p, _city)
			return bestFriends(p)
		end,
	},
	{
		id = "full",
		name = "Full house",
		desc = "Have 10 villagers living in town.",
		need = 10,
		reward = 1500,
		title = "host",
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
		piece = "prize_wishtree",
		value = function(p, _city)
			return bestHeart(p)
		end,
	},
	{
		id = "work10",
		name = "A working town",
		desc = "Have 10 villagers in a job.",
		need = 10,
		reward = 2000,
		title = "boss",
		value = function(_p, city)
			return city.employed
		end,
	},
	{
		id = "heart20",
		name = "Like family",
		desc = "Reach heart level 20 with a villager.",
		need = 20,
		reward = 3000,
		title = "bigheart",
		thing = "goldacorn",
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
		title = "explorer",
		thing = "snowglobe",
		value = stat("found"),
	},
	{
		id = "city",
		name = "Bright lights",
		desc = "Grow into a City.",
		need = 5,
		reward = 3000,
		title = "bigshot",
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
