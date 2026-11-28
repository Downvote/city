--!strict
-- The shape of a player's saved profile and of a villager, with defaults and upgrades.

local Tuning = require(script.Parent.Parent.Config.Tuning)
local Plan = require(script.Parent.Parent.Build.Plan)
local Appearance = require(script.Parent.Parent.Avatar.Appearance)
local Likes = require(script.Parent.Parent.Avatar.Likes)
local Personalities = require(script.Parent.Parent.Data.Personalities)
local Foods = require(script.Parent.Parent.Data.Foods)
local Colors = require(script.Parent.Parent.Util.Colors)
local Keepsakes = require(script.Parent.Keepsakes)
local GemPieces = require(script.Parent.GemPieces) -- (pieces bought with gems: profile.gemItems)
local City = require(script.Parent.City) -- (the land a save already has stays theirs: City.keepLand)
local Flair = require(script.Parent.Flair)
local Memory = require(script.Parent.Memory)
local PlotName = require(script.Parent.PlotName)
local Skills = require(script.Parent.Skills)
local WorkMove = require(script.Parent.WorkMove)
local Bag = require(script.Parent.Bag)
local Titles = require(script.Parent.Titles)
local PlotLikes = require(script.Parent.PlotLikes)
local PlotBoard = require(script.Parent.PlotBoard)
local FollowUps = require(script.Parent.FollowUps) -- (events left waiting for later: profile.follow)
local Babble = require(script.Parent.Babble)
local Crates = require(script.Parent.Crates) -- (crates held, crate workplaces and pets: Sim/Crates)

local Schema = {}

Schema.Version = 1

Schema.Settings = {
	-- what this player hears (Settings; client Controllers/Audio, Sim/Sound, Tuning.Audio): the
	-- music's and the effects' volume, and the villagers' voices on or off
	music = 0.5,
	sfx = 0.8,
	voices = true,
	bubbles = true,
	eventCamera = true,
	theme = "dark", -- the interface's look: "dark" or "light"
	inviteTip = true, -- the one-time nudge to invite friends may still come up (false once put away: Sim/Social)
	-- what this player's own screen draws (Settings; client World/Graphics, Tuning.Graphics)
	detail = "high", -- "low", "medium" or "high": shadows, how far things move, particles, outlines
	blur = true, -- the background blur
	blurStrength = 0.5, -- and how strong (Tuning.Graphics.BlurSteps)
	bloom = true, -- the glow round lamps, neon and lit signs
	sunRays = true,
	haze = true, -- the air that fades what is far off
}

-- What a setting that is a word may be.
Schema.SettingChoices = {
	theme = { dark = true, light = true },
	detail = { low = true, medium = true, high = true },
}

-- What a villager can wish for (Sim/Life): a craving, someone to meet, a chat. (A wish for a new
-- look went: "remove new look cravings"; one in an old save is dropped when it loads.)
Schema.WishKinds = { food = true, friend = true, cheer = true }

-- The romance there was, as an old save keeps it on a pair (rel.bond). There is none now (the
-- user: "remove any romance, just best friends is the highest"), so a pair who had one loads as
-- best friends: the top of Tuning.Relationships.Levels.
Schema.OldBonds = { crush = true, sweethearts = true, partners = true }
local LEVELS = Tuning.Relationships.Levels
Schema.BestFriends = LEVELS[#LEVELS].Min

Schema.Seasons = { "Spring", "Summer", "Autumn", "Winter" }
Schema.DaysPerSeason = 10

export type Villager = {
	id: string,
	name: string,
	pers: string,
	app: Appearance.Appearance,
	color: string,
	bday: { s: number, d: number },
	fav: string, -- the food (Data/Foods) they crave half the time
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
	chatDay: number?, -- the day index of their last chat with you, and how many that day (Sim/Talk)
	chats: number?,
	from: string?, -- who they came as when they moved in from the road (nobody does any more; old saves keep it)
	memo: { text: string, t: number }?, -- the last event they were in, as they'd tell it (Sim/Talk)
	-- what the player gave them to say, bought with gems (Sim/Flair): a catchphrase, an ending for
	-- their sentences and a favourite thing
	flair: { phrase: string?, ending: string?, thing: string? }?,
	lately: { Memory.Memory }?, -- what their events left them with for a few days (Sim/Memory)
	move: string?, -- the emote they work to, bought with gems (Sim/WorkMove), or nil for the job's own
	giftDay: number?, -- the town day they last had a gift from you, and how many that day (Sim/Gifts)
	gifts: number?,
	gaveDay: number?, -- the town day they last thought about giving you something (Gifts.offer)
	-- how they sound as they talk, set in the creator (Sim/Babble); nil in an old save: their
	-- personality's voice (Babble.of)
	voice: Babble.Voice?,
}

function Schema.newProfile(): any
	return {
		v = Schema.Version,
		coins = Tuning.Economy.StartCoins,
		name = "", -- the player's display name, set each time they join (villagers call them by it)
		plan = nil, -- filled with the starter house on first visit to a plot
		villagers = {},
		order = {},
		nextVid = 1,
		rel = {},
		requests = {},
		log = {},
		outfits = {},
		-- (`look`, the player's own look in this game, is nil until they save one in the creator)
		likedLooks = {}, -- shared looks liked: the sharer's user id -> the look's `at` (Avatar/Likes)
		settings = table.clone(Schema.Settings),
		tutorial = 0, -- steps of the tutorial done, or Sim/Tutorial.Skipped (Tutorial.advance records it)
		-- the daily gift: the day it was last claimed, the days running (capped: the coins) and the
		-- days running uncapped (the gems: more on every seventh, Sim/Rewards)
		daily = { last = 0, streak = 0, run = 0 },
		stats = {
			events = 0,
			made = 0,
			earned = 0,
			paydays = 0,
			wishes = 0,
			cravings = 0, -- cravings bought (Life.buyWish)
			hearts = 0,
			found = 0,
			gifts = 0, -- gifts given to villagers (Sim/Gifts)
			gathered = 0, -- things taken from pieces or made at work (Sim/Bag)
			cooked = 0, -- of them, dishes cooked at a stove or a grill
		},
		offers = {}, -- (old saves: heart level thank yous left to pick, paid out on load by Life.settleOffers)
		found = {}, -- places on the island found, by id (Data/Places)
		goals = {}, -- town goals claimed, by id
		arrived = {}, -- who moved in from the road, by key, back when villagers could (kept for old saves)
		keepsakes = {}, -- things villagers made you, by catalog id: how many of each (Sim/Keepsakes)
		gemItems = {}, -- Build mode pieces bought with gems, by catalog id: how many of each (Sim/GemPieces)
		-- what the player has earned at a workplace with their own hands today (Sim/PlayerWork):
		-- the town day it is for, the part of a coin not handed over yet, the whole coins that were
		work = { day = -1, owed = 0, paid = 0 },
		skills = {}, -- the player's own experience at each job, by Data/Jobs id (Sim/Skills)
		recent = {},
		follow = {}, -- events an answer left waiting for later, with the same villagers (Sim/FollowUps)
		calendar = { s = 1, d = 1, y = 1 },
		gems = Tuning.Gems.Start, -- the rare currency (Sim/Gems)
		passes = {}, -- the game passes owned, by key, as Roblox said this session (Sim/Passes; Services/Store fills it)
		receipts = {}, -- gem packs already paid out, by purchase id, so a receipt Roblox sends twice pays once
		seen = 0, -- os.time() when the profile was last saved with the player in the game (offline earnings)
		saves = {}, -- saved builds: { name, t, plan } (Build mode's Saves; Sim/Passes.saveSlots how many)
		vehicles = {}, -- the vehicles bought, by id (Data/Vehicles, Sim/Vehicles)
		achieved = {}, -- achievements claimed, by id
		playtime = { day = -1, secs = 0, got = 0 }, -- today's play in seconds and the rewards taken for it
		ownLand = 0, -- the biggest land bought before Big Plot was a pass, kept without it
		plotName = "", -- the plot's name, over the level bar on the main screen ("" until named: Sim/PlotName)
		-- the bag (Sim/Bag): things by id and how many, what a goal gave while it was full, and how
		-- many things were taken from pieces on which town day
		bag = {},
		owed = {},
		gather = { day = -1, n = 0 },
		titles = {}, -- titles won from town goals, by id (Sim/Titles); `title` is the one worn, or nil
		-- other towns (Services/Visit): those liked (the owner's user id -> when, Sim/PlotLikes), the
		-- keys the name search finds this town by (Sim/PlotBoard), and when it last changed as the
		-- directory's Newest knows it (0 until it is built on or named)
		likedPlots = {},
		plotKeys = {},
		plotAt = 0,
		-- crates (Sim/Crates): the ones held to open later, by kind; the crate workplaces given, by
		-- catalog id; the pets, by id ("p1"...), and the next pet's number; the gems crate jobs paid
		-- on which real day; whether a villager has told the player about the crates
		crates = {},
		crateItems = {},
		pets = {},
		nextPet = 1,
		crateGems = { day = -1, n = 0 },
		crateTold = false,
	}
end

-- Puts back missing keys. Goes one level into tables (settings, stats...) but no deeper.
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
	-- The shop, the bag of food and feeding are gone (the user: "remove the shop, buying of things
	-- and food and feeding"): an old save's bag and what it had learnt of each villager's tastes
	-- are dropped here.
	profile.inv = nil
	if type(profile.stats) == "table" then
		profile.stats.fed = nil
		-- and the romance went too: its counts and its goals
		profile.stats.couples, profile.stats.partners = nil, nil
	end
	if type(profile.goals) == "table" then
		profile.goals.couple, profile.goals.partners = nil, nil
	end
	-- a crush, sweethearts or partners from before: best friends now, and no bond kept
	for _, rel in if type(profile.rel) == "table" then profile.rel else {} do
		if type(rel) == "table" and rel.bond ~= nil then
			if Schema.OldBonds[rel.bond] then
				local s = if type(rel.s) == "number" and rel.s == rel.s then rel.s else 0
				rel.s = math.clamp(math.max(s, Schema.BestFriends), Tuning.Relationships.Min, Tuning.Relationships.Max)
			end
			rel.bond = nil
		end
	end
	-- villagers: drop anything that isn't one, re-check looks
	local clean = {}
	for vid, v in profile.villagers do
		if type(vid) == "string" and type(v) == "table" and type(v.name) == "string" then
			v.app = Appearance.sanitize(v.app)
			fill(v, Schema.villagerDefaults(v.pers), true)
			v.hate, v.known, v.feedDay, v.feeds = nil, nil, nil, nil
			-- a mood in range (it climbs or sinks to what their home gives them from here: Sim/Needs)
			if type(v.mood) ~= "number" or v.mood ~= v.mood then
				v.mood = Tuning.Villagers.StartMood
			end
			v.mood = math.clamp(v.mood, Tuning.Villagers.MoodMin, Tuning.Villagers.MoodMax)
			-- what they'd say about their last event: a line and when, or nothing
			local memo = v.memo
			if memo ~= nil and (type(memo) ~= "table" or type(memo.text) ~= "string" or type(memo.t) ~= "number") then
				v.memo = nil
			end
			-- their flair and their memories, each checked again (Sim/Flair, Sim/Memory)
			v.flair = Flair.sanitize(v.flair)
			v.lately = Memory.sanitize(raw, vid, v.lately)
			v.move = WorkMove.sanitize(v.move)
			v.voice = Babble.clean(v.voice)
			if type(v.fav) ~= "string" or not Foods.get(v.fav) then
				v.fav = Foods.list[1].id
			end
			-- a wish must be a table of a kind we know; a craving must be for a food there is
			local w = v.wish
			if w ~= nil then
				local known = type(w) == "table" and Schema.WishKinds[w.kind] == true
				if not known or (w.kind == "food" and (type(w.arg) ~= "string" or not Foods.get(w.arg))) then
					v.wish = nil
				end
			end
			clean[vid] = v
		end
	end
	profile.villagers = clean
	profile.keepsakes = Keepsakes.clean(profile.keepsakes)
	profile.follow = FollowUps.clean(profile.follow, clean)
	profile.gemItems = GemPieces.clean(profile.gemItems)
	profile.plotName = PlotName.clean(profile.plotName)
	profile.likedPlots = PlotLikes.clean(profile.likedPlots, Tuning.Visit.LikesKept)
	profile.plotKeys = PlotBoard.cleanKeys(profile.plotKeys, Tuning.Visit.NameWords + 1)
	if type(profile.plotAt) ~= "number" or profile.plotAt ~= profile.plotAt or profile.plotAt < 0 then
		profile.plotAt = 0
	end
	-- the player's own look and the shared looks they liked (Services/Avatar, Avatar/Likes)
	profile.look = if type(profile.look) == "table" then Appearance.sanitize(profile.look) else nil
	profile.likedLooks = Likes.clean(profile.likedLooks, Tuning.CreatorMore.LikedKept)
	profile.skills = Skills.clean(profile.skills)
	Bag.clean(profile)
	Titles.clean(profile)
	Crates.clean(profile)
	-- (only true marks: Services/Vehicles also drops any vehicle there no longer is)
	if type(profile.vehicles) ~= "table" then
		profile.vehicles = {}
	end
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
	-- land bought past what is free stays theirs without Big Plot (Sim/City: Land and Big Plot)
	City.keepLand(profile)
	profile.v = Schema.Version
	return profile
end

function Schema.villagerDefaults(_pers: string?): any
	return {
		color = "4FA9D9",
		bday = { s = 1, d = 1 },
		fav = "apple",
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
		voice = Babble.clean(raw.voice), -- (nil: their personality's voice)
	}
end

-- Makes a new villager from clean input. `rng` decides the food they like best.
function Schema.newVillager(id: string, input: any, rng: any): Villager
	local v = Schema.villagerDefaults(input.pers)
	v.id = id
	v.name = input.name
	v.pers = input.pers
	v.app = input.app
	v.color = input.color
	v.bday = input.bday
	v.voice = input.voice
	v.fav = rng:pick(Foods.list).id
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
