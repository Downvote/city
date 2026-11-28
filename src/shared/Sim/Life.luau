--!strict
-- The life sim's progression, as pure data in and out so the specs can run it:
--   hearts   how close each villager is to you. Granted wishes, chats and gifts fill their
--            hearts; each new heart level brings coins they saved and some practice at their work
--            (so they earn more), with a notice. There is no top level (the user: "also, make it
--            such that heart level is uncapped"): each asks a little more than the last.
--            Hobbies and sayings come from random events.
--   wishes   one at a time per villager, shown over their head: a craving, someone they'd like
--            to meet, or a chat to cheer them up (no new look: "remove new look cravings"). Granting one fills hearts and
--            lifts their mood. A craving is bought for them (Life.wishPrice, Life.buyWish); the
--            other wishes cost nothing and they give you a few coins. Unanswered wishes fade
--            after a day. There is no shop and no food to keep: the user asked to "remove the
--            shop, buying of things and food and feeding. when a character gets a craving,
--            allow the player to simply pay to buy it".
--   friends  there is no romance (the user: "remove any romance, just best friends is the
--            highest"): two villagers get no closer than best friends, the top of
--            Sim/Relationships' levels.
--   goals    the town's list of things to work toward (Data/Goals), claimed for coins and, on
--            some, a title, a free Build mode piece or a special thing for the bag (the user: "add
--            more rewards to quests, like titles, special buildings, special gifts, etc.").

local Tuning = require(script.Parent.Parent.Config.Tuning)
local Foods = require(script.Parent.Parent.Data.Foods)
local Goals = require(script.Parent.Parent.Data.Goals)
local Relationships = require(script.Parent.Relationships)
local City = require(script.Parent.City)
local Text = require(script.Parent.Parent.Util.Text)
local Keepsakes = require(script.Parent.Keepsakes)
local Bag = require(script.Parent.Bag)
local Titles = require(script.Parent.Titles)
local Items = require(script.Parent.Parent.Data.Items)
local Catalog = require(script.Parent.Parent.Build.Catalog)
local Needs = require(script.Parent.Needs)

local L = Tuning.Life

local Life = {}

local function name(profile: any, vid: string): string
	local v = profile.villagers[vid]
	return if v then v.name else "?"
end

-- Mood goes through Sim/Needs: a lift counts for less than it says and stops at what their bed,
-- room and friends let them reach (the user: "Villager mood bars should also not be that easy to
-- fill up").
local function mood(profile: any, vid: string, d: number)
	Needs.addMood(profile, vid, d)
end

-- Hearts ---------------------------------------------------------------------------------------------

-- Points from heart level `level` to the next. Levels have no top, and each step is HeartStep
-- longer than the last.
function Life.heartNeed(level: number): number
	return L.HeartBase + L.HeartStep * math.max(1, level)
end

-- What a new heart level brings: the coins they saved up and some practice at their work (skill,
-- which is what their pay goes up with), both at once, with a notice. (It was a choice of three
-- thank yous in a box. The user: "for this, make it a notification instead of a box that the
-- player has to choose from. make it such that it gives you coins and get better effeciency at
-- work". Hobbies come from random events now, and sayings too.)
function Life.heartReward(level: number): (number, number)
	return L.RewardCoinsPerLevel * level, L.RewardSkillPerLevel * level
end

-- Gives villager `v` and the player what heart level `level` brings. Returns the notice.
local function reward(profile: any, v: any, level: number): string
	local coins, practice = Life.heartReward(level)
	profile.coins = math.clamp(profile.coins + coins, 0, Tuning.Economy.MaxCoins)
	local before = v.lv or 1
	City.addSkill(v, practice)
	if (v.lv or 1) > before then
		return Text.fill(
			"Heart level {n} with {x}. They gave you {c} coins, and their work skill is up to {s}.",
			{ n = level, x = v.name, c = Text.commas(coins), s = v.lv }
		)
	end
	return Text.fill(
		"Heart level {n} with {x}. They gave you {c} coins and got a bit better at their job.",
		{ n = level, x = v.name, c = Text.commas(coins) }
	)
end

-- Fills a villager's hearts by `n`. Each new level pays out at once (Life.heartReward) and adds a
-- notice. Returns how many levels they went up.
function Life.addHearts(profile: any, vid: string, n: number, rng: any, notices: { string }?): number
	local v = profile.villagers[vid]
	if not v or n <= 0 then
		return 0
	end
	local _ = rng
	v.heart = v.heart or 1
	v.hxp = (v.hxp or 0) + n
	local gained = 0
	while v.hxp >= Life.heartNeed(v.heart) do
		v.hxp -= Life.heartNeed(v.heart)
		v.heart += 1
		gained += 1
		profile.stats.hearts = (profile.stats.hearts or 0) + 1
		local said = reward(profile, v, v.heart)
		if notices then
			table.insert(notices, said)
		end
	end
	return gained
end

-- An old save's thank yous still waiting to be picked: each is paid out as a heart level is now,
-- and the list emptied. Returns the notices.
function Life.settleOffers(profile: any): { string }
	local out = {}
	for _, offer in profile.offers or {} do
		local v = type(offer) == "table" and profile.villagers[offer.vid]
		if v and type(offer.level) == "number" then
			-- (they were made when heart levels stopped at 20)
			table.insert(out, reward(profile, v, math.clamp(math.floor(offer.level), 1, 20)))
		end
	end
	profile.offers = {}
	return out
end

-- Wishes --------------------------------------------------------------------------------------------

-- (No wish for a new look any more: the user, "remove new look cravings".)
Life.WishIcons = { food = "apple", friend = "people", cheer = "smile" }

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
	-- (The tutorial's last step once waited on a first craving, which came on the hour while it
	-- did. The tutorial ends at the workplace now: Sim/Tutorial.)
	if not rng:chance(L.WishChance) then
		return nil
	end
	local kinds = { "food", "cheer" }
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
		-- their favourite half the time
		wish.arg = if rng:chance(0.5) then v.fav else rng:pick(Foods.list).id
		if not Foods.get(wish.arg) then
			wish.arg = Foods.list[1].id
		end
	elseif kind == "friend" then
		wish.arg = rng:pick(strangers)
	end
	v.wish = wish
	return wish
end

-- Gives a villager a wish to get to know somebody, when they asked for friends (Data/Events/Needs)
-- and have no wish open: the town's cap on open wishes doesn't hold them back, since they asked.
-- `other` must be another villager in town. Returns the wish, or nil.
function Life.wishToMeet(profile: any, vid: any, other: any, now: number): any
	local v = if type(vid) == "string" then profile.villagers[vid] else nil
	if not v or v.wish or type(other) ~= "string" or other == vid or not profile.villagers[other] then
		return nil
	end
	local wish = { kind = "friend", arg = other, untilT = now + L.WishHours * Tuning.Day.Length / 24 }
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
	elseif w.kind == "cheer" then
		return Text.fill("{x} feels a bit down and wants to talk.", { x = v.name })
	end
	return nil
end

-- What it costs to buy a villager a food they are craving: its price in Data/Foods times
-- Tuning.Life.CravingMarkup, rounded to CravingStep coins. Nil for something that is not a food.
function Life.cravingPrice(foodId: any): number?
	local food = if type(foodId) == "string" then Foods.get(foodId) else nil
	if not food then
		return nil
	end
	local step = L.CravingStep
	return math.max(step, math.floor(food.price * L.CravingMarkup / step + 0.5) * step)
end

-- What granting a villager's wish costs. A craving is bought for them; nil when they have no
-- wish or it is not one you pay for (someone to meet, a chat).
function Life.wishPrice(profile: any, vid: string): number?
	local v = profile.villagers[vid]
	local w = v and v.wish
	if type(w) ~= "table" or w.kind ~= "food" then
		return nil
	end
	return Life.cravingPrice(w.arg)
end

-- Grants a villager's wish if `how` (and `arg`) answer it: "food" with the food id, "friend"
-- with the other villager, or "cheer". Returns ok, the coins they gave and notices.
-- A craving gives no coins back (it was paid for: see Life.buyWish), and a little more mood
-- and hearts when it was for their favourite.
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
		mood(profile, arg, 6)
		table.insert(notices, Text.fill("{x} and {y} got talking.", { x = v.name, y = other.name }))
	end
	v.wish = nil
	profile.stats.wishes = (profile.stats.wishes or 0) + 1
	if how == "food" then
		local fav = arg == v.fav
		mood(profile, vid, L.WishMood + (if fav then L.FavWishMood else 0))
		table.insert(
			notices,
			Text.fill(
				if fav then "{x} got their favourite and is so pleased." else "{x} is so pleased.",
				{ x = v.name }
			)
		)
		Life.addHearts(profile, vid, L.WishHearts + (if fav then L.FavWishHearts else 0), rng, notices)
		return true, 0, notices
	end
	mood(profile, vid, L.WishMood)
	local coins = rng:int(L.WishCoinsMin, L.WishCoinsMax)
	profile.coins = math.clamp(profile.coins + coins, 0, Tuning.Economy.MaxCoins)
	table.insert(notices, Text.fill("{x} is so pleased. +{n} coins", { x = v.name, n = coins }))
	Life.addHearts(profile, vid, L.WishHearts, rng, notices)
	return true, coins, notices
end

-- Buys a villager the food they are craving: takes Life.wishPrice from the town's coins and
-- grants the wish. Returns ok, what it cost, the notices and, when it was refused, why.
function Life.buyWish(profile: any, vid: any, rng: any): (boolean, number, { string }, string?)
	local v = if type(vid) == "string" then profile.villagers[vid] else nil
	local w = v and v.wish
	if type(w) ~= "table" then
		return false, 0, {}, "They aren't wishing for anything right now."
	end
	local price = Life.wishPrice(profile, vid)
	if not price then
		return false, 0, {}, "That isn't something you can buy for them."
	end
	if type(profile.coins) ~= "number" or profile.coins < price then
		return false, price, {}, "Not enough coins."
	end
	local granted, _, notices = Life.grantWish(profile, vid, "food", w.arg, rng)
	if not granted then
		return false, 0, {}, "That isn't something you can buy for them."
	end
	profile.coins -= price
	-- how many cravings have been bought, all told (the tutorial's last step waits for the first)
	profile.stats.cravings = (profile.stats.cravings or 0) + 1
	return true, price, notices, nil
end

-- Lets unanswered wishes fade. Returns notices.
function Life.fadeWishes(profile: any, now: number): { string }
	local notices = {}
	for vid, v in profile.villagers do
		if v.wish and v.wish.untilT and now >= v.wish.untilT then
			v.wish = nil
			mood(profile, vid, L.WishFadeMood)
			table.insert(notices, Text.fill("{x} gave up waiting.", { x = v.name }))
		end
	end
	return notices
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

-- What a goal pays besides its coins, as notices: a title to wear, a Build mode piece for free (a
-- keepsake, Sim/Keepsakes) and something special for the bag (Sim/Bag). Gives them to `profile`.
local function extras(profile: any, g: any): { string }
	local out = {}
	if g.title and Titles.give(profile, g.title) then
		local t = Titles.get(g.title)
		table.insert(out, Text.fill("New title: {t}. Wear it from Goals.", { t = if t then t.name else g.title }))
	end
	if g.piece and Keepsakes.give(profile, g.piece) then
		local def = Catalog.get(g.piece)
		table.insert(out, Text.fill("{x} is yours to build, free.", { x = if def then def.name else g.piece }))
	end
	if g.thing then
		local item = Items.get(g.thing)
		if item and Bag.add(profile, g.thing, 1) > 0 then
			table.insert(out, Text.fill("{x} is in your bag.", { x = Items.capital(item) }))
		elseif item then
			-- no room in the bag: it waits there for room (Sim/Bag.owe)
			Bag.owe(profile, g.thing)
			table.insert(out, Text.fill("Your bag is full, so {x} waits for room.", { x = Items.phrase(item) }))
		end
	end
	return out
end

-- Claims a finished goal: its coins and anything else it pays (a title, a free piece, a thing for
-- the bag). Returns ok, the coins and the notices for what else came.
function Life.claimGoal(profile: any, id: any): (boolean, number, { string })
	if type(id) ~= "string" then
		return false, 0, {}
	end
	local g = Goals.get(id)
	if not g or profile.goals[id] then
		return false, 0, {}
	end
	if g.value(profile, City.stats(profile)) < g.need then
		return false, 0, {}
	end
	profile.goals[id] = true
	profile.coins = math.clamp(profile.coins + g.reward, 0, Tuning.Economy.MaxCoins)
	return true, g.reward, extras(profile, g)
end

return Life
