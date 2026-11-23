--!strict
-- The shape of a player's saved profile and of a villager, with defaults and upgrades.

local Tuning = require(script.Parent.Parent.Config.Tuning)
local Plan = require(script.Parent.Parent.Build.Plan)
local Appearance = require(script.Parent.Parent.Avatar.Appearance)
local Personalities = require(script.Parent.Parent.Data.Personalities)
local Foods = require(script.Parent.Parent.Data.Foods)
local Colors = require(script.Parent.Parent.Util.Colors)

local Schema = {}

Schema.Version = 1

Schema.Settings = {
	music = 0.5,
	sfx = 0.8,
	bubbles = true,
	eventCamera = true,
	theme = "dark", -- the interface's look: "dark" or "light"
}

-- What a setting that is a word may be.
Schema.SettingChoices = {
	theme = { dark = true, light = true },
}

Schema.Seasons = { "Spring", "Summer", "Autumn", "Winter" }
Schema.DaysPerSeason = 10

export type Villager = {
	id: string,
	name: string,
	pers: string,
	app: Appearance.Appearance,
	color: string,
	bday: { s: number, d: number },
	fav: string,
	hate: string,
	known: { [string]: string },
	mood: number,
	job: string?, -- the plan key of their workplace
	lv: number, -- skill at their job
	xp: number,
	bed: string?,
	sick: number?,
	dayOff: number?, -- the day index they have off
	isYou: boolean?,
	born: number,
	heart: number, -- how close they are to you (Sim/Life)
	hxp: number,
	wish: any?, -- { kind, arg?, untilT }
	saying: string?, -- a Data/Sayings id
	hobby: string?,
	feedDay: number?,
	feeds: number?,
	chatDay: number?, -- the day index of their last chat with you, and how many that day (Sim/Talk)
	chats: number?,
	from: string?, -- who they came as when they moved in from the road (Sim/Newcomers)
}

function Schema.newProfile(): any
	return {
		v = Schema.Version,
		coins = Tuning.Economy.StartCoins,
		plan = nil, -- filled with the starter house on first visit to a plot
		villagers = {},
		order = {},
		nextVid = 1,
		rel = {},
		inv = { food = { apple = 3, bread = 2 }, items = {} },
		requests = {},
		log = {},
		outfits = {},
		settings = table.clone(Schema.Settings),
		tutorial = 0,
		daily = { last = 0, streak = 0 },
		stats = {
			events = 0,
			fed = 0,
			made = 0,
			earned = 0,
			paydays = 0,
			wishes = 0,
			hearts = 0,
			couples = 0,
			partners = 0,
			found = 0,
		},
		offers = {}, -- heart level thank yous waiting to be picked (Sim/Life)
		found = {}, -- places on the island found, by id (Data/Places)
		goals = {}, -- town goals claimed, by id
		arrived = {}, -- everyone who has ever moved in from the road, by key (Sim/Newcomers)
		recent = {},
		calendar = { s = 1, d = 1, y = 1 },
	}
end

-- Puts back missing keys. Goes one level into tables (settings, stats...) but no deeper, so
-- inventory counts that ran out aren't refilled with the starting food.
local function fill(target: any, defaults: any, deep: boolean?)
	for k, v in defaults do
		if target[k] == nil then
			if type(v) ~= "table" then
				target[k] = v
			elseif deep then
				target[k] = table.clone(v)
			else
				target[k] = {}
			end
		elseif deep and type(v) == "table" and type(target[k]) == "table" and next(v) ~= nil and #v == 0 then
			fill(target[k], v, false)
		end
	end
end

-- Brings saved data up to the current shape. Unknown or broken data starts fresh.
function Schema.migrate(raw: any): any
	if type(raw) ~= "table" then
		return Schema.newProfile()
	end
	local profile = raw
	fill(profile, Schema.newProfile(), true)
	if type(profile.coins) ~= "number" or profile.coins ~= profile.coins then
		profile.coins = Tuning.Economy.StartCoins
	end
	-- villagers: drop anything that isn't one, re-check looks
	local clean = {}
	for vid, v in profile.villagers do
		if type(vid) == "string" and type(v) == "table" and type(v.name) == "string" then
			v.app = Appearance.sanitize(v.app)
			fill(v, Schema.villagerDefaults(v.pers), true)
			clean[vid] = v
		end
	end
	profile.villagers = clean
	local order = {}
	for _, vid in profile.order do
		if clean[vid] and not table.find(order, vid) then
			table.insert(order, vid)
		end
	end
	for vid in clean do
		if not table.find(order, vid) then
			table.insert(order, vid)
		end
	end
	profile.order = order
	profile.adv = nil
	if profile.plan ~= nil then
		profile.plan = Plan.sanitize(profile.plan)
	end
	profile.v = Schema.Version
	return profile
end

function Schema.villagerDefaults(_pers: string?): any
	return {
		color = "4FA9D9",
		bday = { s = 1, d = 1 },
		fav = "apple",
		hate = "pickles",
		known = {},
		mood = Tuning.Villagers.StartMood,
		lv = 1,
		xp = 0,
		born = 0,
		heart = 1,
		hxp = 0,
	}
end

-- Checks what the creator sends for a new villager. Returns a clean table or nil and a reason.
-- The name still has to go through the text filter on the server.
function Schema.cleanVillagerInput(raw: any): (any?, string?)
	if type(raw) ~= "table" then
		return nil, "nothing sent"
	end
	if type(raw.name) ~= "string" then
		return nil, "needs a name"
	end
	local name = raw.name:gsub("[%c]", ""):gsub("^%s+", ""):gsub("%s+$", "")
	if #name < 1 then
		return nil, "needs a name"
	end
	if utf8.len(name) == nil or (utf8.len(name) :: number) > Tuning.Villagers.NameMaxLength then
		return nil, "that name is too long"
	end
	if type(raw.pers) ~= "string" or not Personalities.get(raw.pers) then
		return nil, "pick a personality"
	end
	local color = if Colors.isHex(raw.color) then (raw.color :: string):upper() else "4FA9D9"
	local s, d = 1, 1
	if type(raw.bday) == "table" then
		s = if type(raw.bday.s) == "number" then math.clamp(math.floor(raw.bday.s), 1, #Schema.Seasons) else 1
		d = if type(raw.bday.d) == "number" then math.clamp(math.floor(raw.bday.d), 1, Schema.DaysPerSeason) else 1
	end
	return {
		name = name,
		pers = raw.pers,
		color = color,
		bday = { s = s, d = d },
		app = Appearance.sanitize(raw.app),
	}
end

-- Makes a new villager from clean input. `rng` decides their secret food likes.
function Schema.newVillager(id: string, input: any, rng: any): Villager
	local v = Schema.villagerDefaults(input.pers)
	v.id = id
	v.name = input.name
	v.pers = input.pers
	v.app = input.app
	v.color = input.color
	v.bday = input.bday
	local foods = Foods.list
	local fav = rng:pick(foods)
	local hate = rng:pick(foods)
	local tries = 0
	while hate.id == fav.id and tries < 10 do
		hate = rng:pick(foods)
		tries += 1
	end
	v.fav = fav.id
	v.hate = hate.id
	v.born = os.time()
	return v :: any
end

-- Relationship keys: the two ids in sorted order, so a|b and b|a are the same pair.
function Schema.pairKey(a: string, b: string): string
	if a < b then
		return a .. "|" .. b
	end
	return b .. "|" .. a
end

function Schema.splitPair(key: string): (string, string)
	local a, b = key:match("^(.-)|(.*)$")
	return a :: string, b :: string
end

return Schema
