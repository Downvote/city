--!strict
-- The life sim's progression, as pure data in and out so the specs can run it:
--   hearts   how close each villager is to you. Snacks, granted wishes and room requests fill
--            their hearts; each new heart level lets you pick a thank you (coins they saved, a
--            basket of snacks, a new saying, a hobby).
--   wishes   one at a time per villager, shown over their head: a craving, someone they'd like
--            to meet, a new look, or a chat to cheer them up. Granting one fills hearts, lifts
--            their mood and they give you a few coins. Unanswered wishes fade after a day.
--   romance  pairs of good friends can get a crush, become sweethearts, then partners for life
--            (the events in Data/Events play it out; this keeps the bonds).
--   goals    the town's list of things to work toward (Data/Goals), claimed for coins.

local Tuning = require(script.Parent.Parent.Config.Tuning)
local Foods = require(script.Parent.Parent.Data.Foods)
local Sayings = require(script.Parent.Parent.Data.Sayings)
local Goals = require(script.Parent.Parent.Data.Goals)
local Relationships = require(script.Parent.Relationships)
local Schema = require(script.Parent.Schema)
local City = require(script.Parent.City)
local Text = require(script.Parent.Parent.Util.Text)

local L = Tuning.Life

local Life = {}

local function name(profile: any, vid: string): string
	local v = profile.villagers[vid]
	return if v then v.name else "?"
end

local function mood(v: any, d: number)
	v.mood = math.clamp(v.mood + d, Tuning.Villagers.MoodMin, Tuning.Villagers.MoodMax)
end

-- Hearts ---------------------------------------------------------------------------------------------

function Life.heartNeed(level: number): number
	return L.HeartBase + L.HeartStep * level
end

-- Three thank yous to pick from at a new heart level, drawn with `rng`.
function Life.rewardOptions(profile: any, vid: string, level: number, rng: any): { any }
	local v = profile.villagers[vid]
	local options: { any } = { { kind = "coins", n = L.RewardCoinsPerLevel * level } }
	local pool: { any } = { { kind = "basket" } }
	local saying = rng:pick(Sayings.list)
	if v and saying.id ~= v.saying then
		table.insert(pool, { kind = "saying", id = saying.id })
	end
	local hobby = rng:pick(Sayings.hobbies)
	if v and hobby.id ~= v.hobby then
		table.insert(pool, { kind = "hobby", id = hobby.id })
	end
	while #options < 3 and #pool > 0 do
		table.insert(options, table.remove(pool, rng:int(1, #pool)))
	end
	return options
end

-- What a thank you says on its card.
function Life.rewardText(option: any): string
	if option.kind == "coins" then
		return Text.fill("{n} coins they saved up", { n = Text.commas(option.n) })
	elseif option.kind == "basket" then
		return "A basket of snacks"
	elseif option.kind == "saying" then
		local s = Sayings.get(option.id)
		return Text.fill('A new saying: "{s}"', { s = if s then s.text else "?" })
	elseif option.kind == "hobby" then
		local h = Sayings.hobby(option.id)
		return Text.fill("Take up {h}", { h = if h then h.name else "?" })
	end
	return "?"
end

-- Fills a villager's hearts by `n`. Each new level queues a choice of thank yous in
-- profile.offers. Returns how many levels they went up.
function Life.addHearts(profile: any, vid: string, n: number, rng: any, notices: { string }?): number
	local v = profile.villagers[vid]
	if not v or n <= 0 then
		return 0
	end
	v.heart = v.heart or 1
	v.hxp = (v.hxp or 0) + n
	local gained = 0
	while v.heart < L.HeartMax and v.hxp >= Life.heartNeed(v.heart) do
		v.hxp -= Life.heartNeed(v.heart)
		v.heart += 1
		gained += 1
		profile.stats.hearts = (profile.stats.hearts or 0) + 1
		table.insert(
			profile.offers,
			{ vid = vid, level = v.heart, options = Life.rewardOptions(profile, vid, v.heart, rng) }
		)
		if notices then
			table.insert(notices, Text.fill("{x} feels closer to you. Heart level {n}.", { x = v.name, n = v.heart }))
		end
	end
	if v.heart >= L.HeartMax then
		v.hxp = 0
	end
	return gained
end

-- Picks thank you `choice` (1..3) from the oldest offer. Returns ok and a notice.
function Life.claimReward(profile: any, choice: any, rng: any): (boolean, string?)
	local offer = profile.offers[1]
	if not offer or type(choice) ~= "number" then
		return false, "Nothing to pick right now."
	end
	local option = offer.options[math.floor(choice)]
	local v = profile.villagers[offer.vid]
	table.remove(profile.offers, 1)
	if not option or not v then
		return false, "That thank you is gone."
	end
	if option.kind == "coins" then
		profile.coins = math.clamp(profile.coins + option.n, 0, Tuning.Economy.MaxCoins)
		return true, Text.fill("{x} gave you {n} coins.", { x = v.name, n = Text.commas(option.n) })
	elseif option.kind == "basket" then
		-- their favourite and a few others
		local got = { v.fav }
		for _ = 2, L.BasketSize do
			table.insert(got, rng:pick(Foods.list).id)
		end
		for _, id in got do
			if Foods.get(id) then
				profile.inv.food[id] = (profile.inv.food[id] or 0) + 1
			end
		end
		return true, Text.fill("{x} packed you a basket of snacks.", { x = v.name })
	elseif option.kind == "saying" and Sayings.get(option.id) then
		v.saying = option.id
		return true, Text.fill("{x} has a new saying.", { x = v.name })
	elseif option.kind == "hobby" and Sayings.hobby(option.id) then
		v.hobby = option.id
		return true, Text.fill("{x} took up {h}.", { x = v.name, h = Sayings.hobby(option.id).name })
	end
	return false, "That thank you is gone."
end

-- Hearts for a snack: only the first few a day count, more for their favourite.
function Life.fedHearts(profile: any, vid: string, foodId: string, day: number, rng: any): number
	local v = profile.villagers[vid]
	if not v then
		return 0
	end
	if v.feedDay ~= day then
		v.feedDay = day
		v.feeds = 0
	end
	if (v.feeds or 0) >= L.FeedsPerDay or foodId == v.hate then
		return 0
	end
	v.feeds = (v.feeds or 0) + 1
	local n = if foodId == v.fav then L.FavHearts else L.FeedHearts
	Life.addHearts(profile, vid, n, rng)
	return n
end

-- Wishes --------------------------------------------------------------------------------------------

Life.WishIcons = { food = "apple", friend = "people", look = "shirt", cheer = "smile" }

function Life.openWishes(profile: any): number
	local n = 0
	for _, v in profile.villagers do
		if v.wish then
			n += 1
		end
	end
	return n
end

-- Maybe gives a villager a wish. Returns it, or nil.
function Life.maybeWish(profile: any, vid: string, rng: any, now: number): any
	local v = profile.villagers[vid]
	if not v or v.wish or v.isYou or Life.openWishes(profile) >= L.MaxWishes then
		return nil
	end
	if not rng:chance(L.WishChance) then
		return nil
	end
	local kinds = { "food", "look", "cheer" }
	-- someone they hardly know yet
	local strangers = {}
	for other in profile.villagers do
		if other ~= vid and Relationships.peek(profile, vid, other) < 30 then
			table.insert(strangers, other)
		end
	end
	table.sort(strangers)
	if #strangers > 0 then
		table.insert(kinds, "friend")
	end
	local kind = rng:pick(kinds)
	local wish: any = { kind = kind, untilT = now + L.WishHours * Tuning.Day.Length / 24 }
	if kind == "food" then
		wish.arg = if rng:chance(0.5) then v.fav else rng:pick(Foods.list).id
		if wish.arg == v.hate then
			wish.arg = v.fav
		end
	elseif kind == "friend" then
		wish.arg = rng:pick(strangers)
	end
	v.wish = wish
	return wish
end

-- What a villager's wish says.
function Life.wishText(profile: any, vid: string): string?
	local v = profile.villagers[vid]
	local w = v and v.wish
	if not w then
		return nil
	end
	if w.kind == "food" then
		local f = Foods.get(w.arg)
		return Text.fill("{x} is craving {food}.", { x = v.name, food = if f then f.name:lower() else "a snack" })
	elseif w.kind == "friend" then
		return Text.fill("{x} would like to get to know {y}.", { x = v.name, y = name(profile, w.arg) })
	elseif w.kind == "look" then
		return Text.fill("{x} wants a new look.", { x = v.name })
	elseif w.kind == "cheer" then
		return Text.fill("{x} feels a bit down and wants to talk.", { x = v.name })
	end
	return nil
end

-- Grants a villager's wish if `how` (and `arg`) answer it: "food" with the food id, "friend"
-- with the other villager, "look", or "cheer". Returns ok, the coins they gave and notices.
function Life.grantWish(profile: any, vid: string, how: string, arg: any, rng: any): (boolean, number, { string })
	local notices = {}
	local v = profile.villagers[vid]
	local w = v and v.wish
	if not w or w.kind ~= how then
		return false, 0, notices
	end
	if (how == "food" or how == "friend") and w.arg ~= arg then
		return false, 0, notices
	end
	if how == "friend" then
		local other = profile.villagers[arg]
		if not other then
			v.wish = nil
			return false, 0, notices
		end
		Relationships.add(profile, vid, arg, L.IntroduceGain)
		mood(other, 6)
		table.insert(notices, Text.fill("{x} and {y} got talking.", { x = v.name, y = other.name }))
	end
	v.wish = nil
	mood(v, L.WishMood)
	local coins = rng:int(L.WishCoinsMin, L.WishCoinsMax)
	profile.coins = math.clamp(profile.coins + coins, 0, Tuning.Economy.MaxCoins)
	profile.stats.wishes = (profile.stats.wishes or 0) + 1
	table.insert(notices, Text.fill("{x} is so pleased. +{n} coins", { x = v.name, n = coins }))
	Life.addHearts(profile, vid, L.WishHearts, rng, notices)
	return true, coins, notices
end

-- Lets unanswered wishes fade. Returns notices.
function Life.fadeWishes(profile: any, now: number): { string }
	local notices = {}
	for _, v in profile.villagers do
		if v.wish and v.wish.untilT and now >= v.wish.untilT then
			v.wish = nil
			mood(v, L.WishFadeMood)
			table.insert(notices, Text.fill("{x} gave up waiting.", { x = v.name }))
		end
	end
	return notices
end

-- Romance -------------------------------------------------------------------------------------------

Life.BondNames = { crush = "Has a crush", sweethearts = "Sweethearts", partners = "Partners" }

function Life.bond(profile: any, a: string, b: string): string?
	local rel = profile.rel[Schema.pairKey(a, b)]
	return rel and rel.bond
end

function Life.setBond(profile: any, a: string, b: string, bond: string?)
	local rel: any = Relationships.get(profile, a, b)
	local before = rel.bond
	rel.bond = bond
	if bond == "sweethearts" and before ~= "sweethearts" and before ~= "partners" then
		profile.stats.couples = (profile.stats.couples or 0) + 1
	elseif bond == "partners" and before ~= "partners" then
		profile.stats.partners = (profile.stats.partners or 0) + 1
	end
end

-- Who a villager is with (sweethearts or partners), if anyone, and how.
function Life.partnerOf(profile: any, vid: string): (string?, string?)
	for key, rel in profile.rel do
		local bond = (rel :: any).bond
		if bond == "sweethearts" or bond == "partners" then
			local a, b = Schema.splitPair(key)
			if a == vid and profile.villagers[b] then
				return b, bond
			elseif b == vid and profile.villagers[a] then
				return a, bond
			end
		end
	end
	return nil, nil
end

-- Is either of them already taken, or carrying a crush on someone?
function Life.free(profile: any, vid: string): boolean
	for key, rel in profile.rel do
		local bond = (rel :: any).bond
		if bond then
			local a, b = Schema.splitPair(key)
			if a == vid or b == vid then
				return false
			end
		end
	end
	return true
end

-- Goals ---------------------------------------------------------------------------------------------

-- Every goal with how far along it is: { goal, value, done, claimed }.
function Life.goals(profile: any): { any }
	local city = City.stats(profile)
	local out = {}
	for _, g in Goals.list do
		local value = g.value(profile, city)
		table.insert(out, {
			goal = g,
			value = math.min(value, g.need),
			done = value >= g.need,
			claimed = profile.goals[g.id] == true,
		})
	end
	return out
end

-- Claims a finished goal's coins. Returns ok and the coins.
function Life.claimGoal(profile: any, id: any): (boolean, number)
	if type(id) ~= "string" then
		return false, 0
	end
	local g = Goals.get(id)
	if not g or profile.goals[id] then
		return false, 0
	end
	if g.value(profile, City.stats(profile)) < g.need then
		return false, 0
	end
	profile.goals[id] = true
	profile.coins = math.clamp(profile.coins + g.reward, 0, Tuning.Economy.MaxCoins)
	return true, g.reward
end

return Life
