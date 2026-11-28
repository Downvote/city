--!strict
-- Gifts between the player and their villagers. The user: "You can then gift villagers different
-- items to make them happy. Villagers will have a preference to things they like based on
-- personality. Each villager will have a gift limit of 1 per day, and they can gift you things as
-- well. each persoality will have a unique line for recieving or giving gifts."
--
-- Pure data in and out, so the specs can run it:
--   taste   how a villager takes a thing: "love" (a kind their personality likes, Data/
--           Personalities' `likes`, their favourite food, the food they crave, a treasure), "bad"
--           (a kind they dislike) or "ok"
--   give    the player gives one from the bag (Sim/Bag): at most Tuning.Gifts.PerDay a town day to
--           each villager (v.giftDay, v.gifts), it lifts their mood and fills their hearts by
--           their taste, and the food they crave grants the craving (Life.grantWish)
--   offer   once a town day, the first time the player talks to them, a villager who is close
--           enough and in a good mood may have something for the player: a thing of a kind they
--           like themselves (v.gaveDay), put in the bag
--   line    what they say about it, in their own words (Data/GiftLines) and hand (Sim/Voice)

local Tuning = require(script.Parent.Parent.Config.Tuning)
local Items = require(script.Parent.Parent.Data.Items)
local Personalities = require(script.Parent.Parent.Data.Personalities)
local GiftLines = require(script.Parent.Parent.Data.GiftLines)
local Text = require(script.Parent.Parent.Util.Text)
local Voice = require(script.Parent.Voice)
local Bag = require(script.Parent.Bag)
local Life = require(script.Parent.Life)
local Needs = require(script.Parent.Needs)

local K = Tuning.Gifts

local Gifts = {}

export type Taste = "love" | "ok" | "bad"

export type Result = {
	taste: string, -- a Taste
	line: string, -- what they say, in their own hand
	hearts: number,
	mood: number,
	wish: boolean, -- it was the food they craved
	notices: { string },
}

-- How a villager takes a thing.
function Gifts.taste(v: any, item: Items.Item): Taste
	if item.special or item.id == v.fav then
		return "love"
	end
	local w = v.wish
	if type(w) == "table" and w.kind == "food" and w.arg == item.id then
		return "love"
	end
	local pers = Personalities.get(v.pers)
	if pers then
		if table.find(pers.likes, item.cat) then
			return "love"
		end
		if table.find(pers.dislikes, item.cat) then
			return "bad"
		end
	end
	return "ok"
end

-- The kinds of thing a personality likes and dislikes, by name ("Flowers", "Sweets").
function Gifts.likes(pers: string?): ({ string }, { string })
	local p = if pers then Personalities.get(pers) else nil
	local likes: { string }, dislikes: { string } = {}, {}
	if p then
		for _, c in p.likes do
			table.insert(likes, Items.categoryName(c))
		end
		for _, c in p.dislikes do
			table.insert(dislikes, Items.categoryName(c))
		end
	end
	return likes, dislikes
end

-- How many gifts a villager has had from the player on town day `day`.
function Gifts.today(v: any, day: number): number
	if type(v) ~= "table" or v.giftDay ~= day or type(v.gifts) ~= "number" then
		return 0
	end
	return math.max(0, math.floor(v.gifts))
end

-- Can the player give this villager this thing today? Ok, or false and why in plain words.
function Gifts.canGive(profile: any, vid: any, id: any, day: number): (boolean, string?)
	local v = if type(vid) == "string" then profile.villagers[vid] else nil
	if not v then
		return false, "Who?"
	end
	if not Items.get(id) then
		return false, "That isn't something you can give."
	end
	if Bag.count(profile, id) < 1 then
		return false, "That isn't in your bag."
	end
	if Gifts.today(v, day) >= K.PerDay then
		return false, Text.fill("{x} has had a gift today. Try again tomorrow.", { x = v.name })
	end
	return true, nil
end

-- What a villager says: a line of `kind` ("love", "ok", "bad" or "give") about `item`, picked by
-- `rng`, in their own hand. `name` is what they call the player ("Mayor" unless told).
function Gifts.line(v: any, kind: string, item: Items.Item, rng: any, name: string?): string
	local own = GiftLines[v.pers] or GiftLines.sunny
	local list = (own :: any)[kind] or own.ok
	local text = Text.fill(rng:pick(list), { thing = item.phrase, player = name or Text.playerName(nil) })
	return Voice.as(v, text)
end

-- (through Sim/Needs: a lift counts for less and stops at what their home and friends let them
-- reach; returns the change made)
local function moodBy(profile: any, vid: string, d: number): number
	return Needs.addMood(profile, vid, d)
end

-- The player gives a villager a thing from the bag. Everything is checked; nothing changes when it
-- is refused. Returns ok and the result, or false and why.
function Gifts.give(profile: any, vid: any, id: any, day: number, rng: any): (boolean, Result | string)
	local ok, why = Gifts.canGive(profile, vid, id, day)
	if not ok then
		return false, why or "Can't give that."
	end
	local v = profile.villagers[vid]
	local item = Items.get(id) :: Items.Item
	local taste = Gifts.taste(v, item)
	Bag.take(profile, id, 1)
	v.gifts = Gifts.today(v, day) + 1
	v.giftDay = day
	profile.stats.gifts = (profile.stats.gifts or 0) + 1
	local notices: { string } = {}
	local w = v.wish
	local craved = type(w) == "table" and w.kind == "food" and w.arg == id
	local hearts, mood = 0, 0
	if craved then
		-- the food they crave: the craving is answered, as a bought one would be (no coins back)
		local beforeMood = v.mood
		local _, _, said = Life.grantWish(profile, vid, "food", id, rng)
		notices = said
		hearts = Tuning.Life.WishHearts
		mood = v.mood - beforeMood
	else
		if taste == "love" then
			hearts, mood = K.LoveHearts, K.LoveMood
		elseif taste == "ok" then
			hearts, mood = K.OkHearts, K.OkMood
		else
			hearts, mood = K.BadHearts, K.BadMood
		end
		mood = moodBy(profile, vid, mood)
		if hearts > 0 then
			Life.addHearts(profile, vid, hearts, rng, notices)
		end
	end
	local result: Result = {
		taste = taste,
		line = Gifts.line(v, taste, item, rng),
		hearts = hearts,
		mood = mood,
		wish = craved,
		notices = notices,
	}
	return true, result
end

-- What the villager does with the player once a town day: maybe gives them something. Only the
-- first time they are asked that day counts (v.gaveDay is set either way), and only when they are
-- close enough, in a good mood and the bag has room. Returns the thing's id and their line, or nil.
function Gifts.offer(profile: any, vid: any, day: number, rng: any): (string?, string?)
	local v = if type(vid) == "string" then profile.villagers[vid] else nil
	if not v or v.isYou or v.gaveDay == day then
		return nil, nil
	end
	v.gaveDay = day
	if (v.heart or 1) < K.GiveHeart or (v.mood or 0) < K.GiveMood or not rng:chance(K.GiveChance) then
		return nil, nil
	end
	-- a thing of a kind they like themselves, never a treasure
	local pers = Personalities.get(v.pers)
	local pool = {}
	local cats: { string } = if pers then pers.likes else { "sweet" }
	for _, cat in cats do
		for _, item in Items.inCategory(cat) do
			if not item.special and Bag.room(profile, item.id) > 0 then
				table.insert(pool, item)
			end
		end
	end
	if #pool == 0 then
		return nil, nil
	end
	local item = rng:pick(pool)
	if Bag.add(profile, item.id, 1) <= 0 then
		return nil, nil
	end
	return item.id, Gifts.line(v, "give", item, rng)
end

return Gifts
