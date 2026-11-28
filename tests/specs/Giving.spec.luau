--!nocheck
-- Gifts between the player and their villagers (Sim/Gifts), hearts with no top (Sim/Life), and what
-- town goals pay besides coins (titles, prize pieces, treasures). The user: "You can then gift
-- villagers different items to make them happy. Villagers will have a preference to things they like
-- based on personality. Each villager will have a gift limit of 1 per day, and they can gift you
-- things as well. each persoality will have a unique line for recieving or giving gifts", "also,
-- make it such that heart level is uncapped" and "add more rewards to quests, like titles, special
-- buildings, special gifts, etc."

local Shared = "ReplicatedStorage.Shared."
local Tuning = require(Shared .. "Config.Tuning")
local Items = require(Shared .. "Data.Items")
local Personalities = require(Shared .. "Data.Personalities")
local GiftLines = require(Shared .. "Data.GiftLines")
local Goals = require(Shared .. "Data.Goals")
local TitleData = require(Shared .. "Data.Titles")
local Catalog = require(Shared .. "Build.Catalog")
local Schema = require(Shared .. "Sim.Schema")
local Gifts = require(Shared .. "Sim.Gifts")
local Bag = require(Shared .. "Sim.Bag")
local Life = require(Shared .. "Sim.Life")
local Needs = require(Shared .. "Sim.Needs")
local Titles = require(Shared .. "Sim.Titles")
local Keepsakes = require(Shared .. "Sim.Keepsakes")
local Voice = require(Shared .. "Sim.Voice")
local Appearance = require(Shared .. "Avatar.Appearance")
local StarterHouse = require(Shared .. "Data.StarterHouse")
local Rng = require(Shared .. "Util.Rng")

local K = Tuning.Gifts

local function need(cond, what)
	if not cond then
		error(what, 2)
	end
end

local function town(pers)
	local p = Schema.newProfile()
	p.plan = StarterHouse.plan()
	local input = Schema.cleanVillagerInput({ name = "Mara", pers = pers or "sunny", app = Appearance.default() })
	local v = Schema.newVillager("v1", input, Rng.new(1))
	v.fav = "apple"
	p.villagers.v1 = v
	table.insert(p.order, "v1")
	return p, v
end

-- a thing of the first kind a personality likes, dislikes, or neither, that isn't their favourite
local function thingOf(pers, how)
	local p = Personalities.get(pers)
	for _, item in Items.list do
		local liked, disliked = table.find(p.likes, item.cat), table.find(p.dislikes, item.cat)
		if item.id ~= "apple" and not item.special then
			if how == "love" and liked then
				return item.id
			elseif how == "bad" and disliked then
				return item.id
			elseif how == "ok" and not liked and not disliked then
				return item.id
			end
		end
	end
	error("nothing " .. how .. " for " .. pers)
end

describe("Tastes", function()
	it("gives every personality kinds it likes and one it doesn't, never both", function()
		for _, p in Personalities.list do
			need(#p.likes >= 2 and #p.dislikes >= 1, p.id .. " needs likes and a dislike")
			for _, c in p.likes do
				need(Items.categoryName(c) ~= c and c ~= "treasure", p.id .. " likes " .. c)
				need(not table.find(p.dislikes, c), p.id .. " likes and dislikes " .. c)
			end
			for _, c in p.dislikes do
				need(Items.categoryName(c) ~= c and c ~= "treasure", p.id .. " dislikes " .. c)
			end
		end
	end)

	it("loves what they like, their favourite, what they crave and a treasure; minds what they dislike", function()
		local _, v = town("cool")
		expect(Gifts.taste(v, Items.get(thingOf("cool", "love")))).toBe("love")
		expect(Gifts.taste(v, Items.get(thingOf("cool", "bad")))).toBe("bad")
		expect(Gifts.taste(v, Items.get(thingOf("cool", "ok")))).toBe("ok")
		expect(Gifts.taste(v, Items.get("apple"))).toBe("love") -- their favourite
		expect(Gifts.taste(v, Items.get("musicbox"))).toBe("love")
		v.wish = { kind = "food", arg = "curry", untilT = 1e9 }
		expect(Gifts.taste(v, Items.get("curry"))).toBe("love")
		local likes, dislikes = Gifts.likes("cool")
		expect(likes[1]).toBe("Drinks")
		expect(dislikes[1]).toBe("Sweets")
	end)
end)

describe("Giving", function()
	it("takes one gift a day from the bag and fills hearts by taste", function()
		local p, v = town("sunny")
		local loved, bad = thingOf("sunny", "love"), thingOf("sunny", "bad")
		Bag.add(p, loved, 2)
		Bag.add(p, bad, 1)
		v.mood = 0 -- (low, so the lift shows under what they can reach: Sim/Needs)
		local mood = v.mood
		local ok, r = Gifts.give(p, "v1", loved, 3, Rng.new(2))
		expect(ok).toBe(true)
		expect(r.taste).toBe("love")
		expect(r.hearts).toBe(K.LoveHearts)
		expect(v.mood).toBe(math.min(Needs.cap(p, "v1"), mood + Needs.lift(K.LoveMood)))
		expect(r.mood).toBe(v.mood - mood)
		expect(v.hxp + (v.heart - 1) * Life.heartNeed(1)).toBe(K.LoveHearts)
		expect(Bag.count(p, loved)).toBe(1)
		expect(p.stats.gifts).toBe(1)
		-- one a day: the second is refused and nothing changes
		local before = { v.mood, v.hxp, Bag.count(p, loved), p.stats.gifts }
		local again, why = Gifts.give(p, "v1", loved, 3, Rng.new(2))
		expect(again).toBe(false)
		expect(why).toBe("Mara has had a gift today. Try again tomorrow.")
		expect({ v.mood, v.hxp, Bag.count(p, loved), p.stats.gifts }).toEqual(before)
		-- the next day they take another, and a disliked one sours them a little
		mood = v.mood
		local ok2, r2 = Gifts.give(p, "v1", bad, 4, Rng.new(2))
		expect(ok2).toBe(true)
		expect(r2.taste).toBe("bad")
		expect(v.mood).toBe(math.max(Tuning.Villagers.MoodMin, mood + K.BadMood))
		expect(K.LoveHearts <= Tuning.Life.WishHearts).toBeTruthy()
	end)

	it("refuses what isn't in the bag, isn't a thing, or goes to nobody, and changes nothing", function()
		local p, v = town("bold")
		Bag.add(p, "tea", 1)
		local snapshot = { v.mood, v.hxp, Bag.total(p), p.stats.gifts or 0 }
		for _, case in
			{
				{ "v1", "apple", "That isn't in your bag." },
				{ "v1", "sofa_two", "That isn't something you can give." },
				{ "v1", 99, "That isn't something you can give." },
				{ "v9", "tea", "Who?" },
				{ {}, "tea", "Who?" },
			}
		do
			local ok, why = Gifts.give(p, case[1], case[2], 1, Rng.new(1))
			expect(ok).toBe(false)
			expect(why).toBe(case[3])
		end
		expect({ v.mood, v.hxp, Bag.total(p), p.stats.gifts or 0 }).toEqual(snapshot)
	end)

	it("answers a craving with the food it is for", function()
		local p, v = town("gloomy")
		v.wish = { kind = "food", arg = "curry", untilT = 1e9 }
		Bag.add(p, "curry", 1)
		local ok, r = Gifts.give(p, "v1", "curry", 1, Rng.new(4))
		expect(ok).toBe(true)
		expect(r.wish).toBe(true)
		expect(v.wish).toBe(nil)
		expect(p.stats.wishes).toBe(1)
		expect(#r.notices > 0).toBeTruthy()
	end)

	it("says something in their own words and hand for every kind of gift", function()
		local rng = Rng.new(9)
		local stock = { "delve", "embark", "unleash", "vibrant", "bustling", "journey", "realm", "tapestry" }
		local bang, all = 0, 0
		for _, pers in Personalities.list do
			local own = GiftLines[pers.id]
			need(own ~= nil, pers.id .. " has no gift lines")
			for _, kind in { "love", "ok", "bad", "give" } do
				need(#own[kind] >= 3, pers.id .. " has too few " .. kind .. " lines")
				for _, text in own[kind] do
					all += 1
					bang += if text:find("!", 1, true) then 1 else 0
					local where = pers.id .. "." .. kind .. ": " .. text
					need(not text:find("\u{2014}", 1, true) and not text:find("\u{2013}", 1, true), where)
					need(not text:find(" - ", 1, true), where)
					for _, w in stock do
						need(not text:lower():find(w, 1, true), where)
					end
					for key in text:gmatch("{(%w+)}") do
						need(key == "thing" or key == "player", where)
					end
					need(not text:lower():find("mayor", 1, true), where)
					-- a thing reads in lower case, so it never starts a line but a cheeky one's
					need(pers.id == "cheeky" or text:sub(1, 7) ~= "{thing}", where)
					-- no mark another personality owns
					need(pers.id == "gentle" or not text:find("~", 1, true), where)
					need(pers.id == "dreamy" or not text:find("♪", 1, true), where)
					if pers.id == "cool" or pers.id == "gloomy" then
						need(not text:find("!", 1, true), where)
					end
					if pers.id == "cool" then
						local words = 0
						for _ in text:gmatch("%S+") do
							words += 1
						end
						need(words <= 12 and not text:find("%.%.%.$"), where)
					end
					if pers.id == "polite" then
						need(not text:find("%a'%a"), where)
					end
				end
			end
			-- and what comes out has the thing in and their hand on
			local _, v = town(pers.id)
			local said = Gifts.line(v, "love", Items.get("tea"), rng)
			need(not said:find("{", 1, true), said)
			expect(Voice.as(v, said)).toBe(said)
		end
		-- no shouting on every line
		need(bang / all < 0.3, bang .. " of " .. all .. " gift lines shout")
	end)
end)

describe("A villager's gift", function()
	it("comes at most once a day, from someone close and happy, and is a thing they'd like", function()
		local p, v = town("foodie")
		v.heart, v.mood = 1, 90
		expect((Gifts.offer(p, "v1", 1, Rng.new(1)))).toBe(nil) -- not close enough yet
		v.heart = K.GiveHeart
		local given, days = 0, 0
		for day = 2, 400 do
			local id, line = Gifts.offer(p, "v1", day, Rng.new(day))
			days += 1
			-- asked again the same day: nothing more
			expect((Gifts.offer(p, "v1", day, Rng.new(day + 1000)))).toBe(nil)
			if id then
				given += 1
				local item = Items.get(id)
				need(table.find(Personalities.get("foodie").likes, item.cat) and not item.special, id)
				need(type(line) == "string" and not line:find("{", 1, true), tostring(line))
				Bag.take(p, id) -- (so the bag never fills)
			end
		end
		local share = given / days
		need(share > K.GiveChance * 0.6 and share < K.GiveChance * 1.4, "gave on " .. share .. " of days")
		-- not in a bad mood, and not with a full bag
		v.mood = K.GiveMood - 1
		for day = 500, 560 do
			expect((Gifts.offer(p, "v1", day, Rng.new(day)))).toBe(nil)
		end
	end)
end)

describe("Hearts", function()
	it("have no top level, and each step asks a little more", function()
		local p, v = town("sunny")
		Life.addHearts(p, "v1", 100000, Rng.new(1), {})
		expect(v.heart > 60).toBeTruthy()
		expect(Life.heartNeed(v.heart) > Life.heartNeed(v.heart - 1)).toBeTruthy()
		expect(v.hxp < Life.heartNeed(v.heart)).toBeTruthy()
		-- and an old save at the old top of 20 keeps going
		local q, w = town("shy")
		w.heart, w.hxp = 20, Life.heartNeed(20) - 1
		Life.addHearts(q, "v1", 1, Rng.new(1), {})
		expect(w.heart).toBe(21)
	end)
end)

describe("Goal rewards", function()
	it("name titles, pieces and things there are, a few of each", function()
		local titles, pieces, things = 0, 0, 0
		local titleUsed = {}
		for _, g in Goals.list do
			if g.title then
				need(TitleData.get(g.title) ~= nil, g.id .. " gives a title there isn't")
				need(not titleUsed[g.title], g.title .. " comes from two goals")
				titleUsed[g.title] = true
				titles += 1
			end
			if g.piece then
				need(Keepsakes.isKeepsake(g.piece) and Catalog.get(g.piece).prize, g.id .. " gives " .. g.piece)
				pieces += 1
			end
			if g.thing then
				need(Items.get(g.thing) ~= nil, g.id .. " gives " .. g.thing)
				things += 1
			end
		end
		expect(titles >= 8 and pieces >= 3 and things >= 4).toBeTruthy()
		for _, t in TitleData.list do
			need(titleUsed[t.id], "no goal gives " .. t.id)
		end
		for _, def in Catalog.list("keepsakes") do
			if def.prize then
				local given = false
				for _, g in Goals.list do
					given = given or g.piece == def.id
				end
				need(given, "no goal gives " .. def.id)
			end
		end
	end)

	it("pays a title, a piece and a thing with the coins, once", function()
		local p = town("sunny")
		p.villagers.v1.heart = 10
		p.goals = {}
		local ok, coins, notices = Life.claimGoal(p, "heart5")
		expect(ok).toBe(true)
		expect(coins).toBe(Goals.get("heart5").reward)
		expect(Titles.has(p, "kind")).toBe(true)
		expect(Bag.count(p, "musicbox")).toBe(1)
		expect(#notices).toBe(2)
		local ok2, _, n2 = Life.claimGoal(p, "heart10")
		expect(ok2).toBe(true)
		expect(Keepsakes.owned(p, "prize_wishtree")).toBe(1)
		-- (and a work crate, held in the Store: Sim/Crates)
		expect(p.crates.work).toBe(1)
		expect(#n2).toBe(2)
		-- never twice
		local again, c2, n3 = Life.claimGoal(p, "heart5")
		expect(again).toBe(false)
		expect(c2).toBe(0)
		expect(#n3).toBe(0)
		expect(Bag.count(p, "musicbox")).toBe(1)
	end)
end)

describe("Titles", function()
	it("are worn only once won, taken off freely, and cleaned on load", function()
		local p = Schema.newProfile()
		expect((Titles.wear(p, "kind"))).toBe(false)
		expect(Titles.give(p, "kind")).toBe(true)
		expect(Titles.give(p, "kind")).toBe(false)
		expect(Titles.give(p, "nothing")).toBe(false)
		expect((Titles.wear(p, "kind"))).toBe(true)
		expect(Titles.worn(p).name).toBe("Kind Heart")
		expect((Titles.wear(p, false))).toBe(true)
		expect(Titles.worn(p)).toBe(nil)
		local raw = Schema.newProfile()
		raw.titles = { kind = true, junk = true, boss = 1 }
		raw.title = "boss"
		local q = Schema.migrate(raw)
		expect(q.titles.kind).toBe(true)
		expect(q.titles.junk).toBe(nil)
		expect(q.titles.boss).toBe(nil)
		expect(q.title).toBe(nil)
		local list = Titles.list(q)
		expect(#list).toBe(#TitleData.list)
	end)
end)
