--!strict
-- The life sim's progression, as pure data in and out so the specs can run it:
--   hearts   how close each villager is to you. Granted wishes and chats fill their hearts;
--            each new heart level lets you pick a thank you (coins they saved, some practice
--            at their work, a new saying, a hobby).
--   wishes   one at a time per villager, shown over their head: a craving, someone they'd like
--            to meet, a new look, or a chat to cheer them up. Granting one fills hearts and
--            lifts their mood. A craving is bought for them (Life.wishPrice, Life.buyWish); the
--            other wishes cost nothing and they give you a few coins. Unanswered wishes fade
--            after a day. There is no shop and no food to keep: the user asked to "remove the
--            shop, buying of things and food and feeding. when a character gets a craving,
--            allow the player to simply pay to buy it".
--   friends  there is no romance (the user: "remove any romance, just best friends is the
--            highest"): two villagers get no closer than best friends, the top of
--            Sim/Relationships' levels.
--   goals    the town's list of things to work toward (Data/Goals), claimed for coins.

local Tuning = require(script.Parent.Parent.Config.Tuning)
local Foods = require(script.Parent.Parent.Data.Foods)
local Sayings = require(script.Parent.Parent.Data.Sayings)
local Goals = require(script.Parent.Parent.Data.Goals)
local Relationships = require(script.Parent.Relationships)
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
	-- (a basket of snacks stood here until the food went; some practice at work needs no bag)
	local pool: { any } = { { kind = "practice", n = L.RewardSkillPerLevel * level } }
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
	elseif option.kind == "practice" then
		return "Some extra practice at their work"
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
	elseif option.kind == "practice" and type(option.n) == "number" then
		local gained = City.addSkill(v, option.n)
		if gained > 0 then
			return true, Text.fill("{x} put in the practice. Skill {n} now.", { x = v.name, n = v.lv })
		end
		return true, Text.fill("{x} put in the practice.", { x = v.name })
	elseif option.kind == "saying" and Sayings.get(option.id) then
		v.saying = option.id
		return true, Text.fill("{x} has a new saying.", { x = v.name })
	elseif option.kind == "hobby" and Sayings.hobby(option.id) then
		v.hobby = option.id
		return true, Text.fill("{x} took up {h}.", { x = v.name, h = Sayings.hobby(option.id).name })
	end
	return false, "That thank you is gone."
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
-- wish or it is not one you pay for (someone to meet, a new look, a chat).
function Life.wishPrice(profile: any, vid: string): number?
	local v = profile.villagers[vid]
	local w = v and v.wish
	if type(w) ~= "table" or w.kind ~= "food" then
		return nil
	end
	return Life.cravingPrice(w.arg)
end

-- Grants a villager's wish if `how` (and `arg`) answer it: "food" with the food id, "friend"
-- with the other villager, "look", or "cheer". Returns ok, the coins they gave and notices.
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
		mood(other, 6)
		table.insert(notices, Text.fill("{x} and {y} got talking.", { x = v.name, y = other.name }))
	end
	v.wish = nil
	profile.stats.wishes = (profile.stats.wishes or 0) + 1
	if how == "food" then
		local fav = arg == v.fav
		mood(v, L.WishMood + (if fav then L.FavWishMood else 0))
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
	mood(v, L.WishMood)
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
	return true, price, notices, nil
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
