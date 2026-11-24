--!nocheck
-- Hearts, wishes and town goals (Sim/Life): heart levels queue thank yous that pay out once,
-- wishes are granted only by the right answer and fade when ignored, a craving is bought for them
-- at Life.wishPrice (the user: "remove the shop, buying of things and food and feeding. when a
-- character gets a craving, allow the player to simply pay to buy it"), and goals pay once when
-- they're done. There is no romance (the user: "remove any romance, just best friends is the
-- highest"): best friends is the closest two villagers get, and an old save's crush, sweethearts
-- or partners load as best friends.

local Shared = "ReplicatedStorage.Shared."
local Tuning = require(Shared .. "Config.Tuning")
local Schema = require(Shared .. "Sim.Schema")
local Life = require(Shared .. "Sim.Life")
local Relationships = require(Shared .. "Sim.Relationships")
local Appearance = require(Shared .. "Avatar.Appearance")
local Foods = require(Shared .. "Data.Foods")
local Goals = require(Shared .. "Data.Goals")
local Jobs = require(Shared .. "Data.Jobs")
local Sayings = require(Shared .. "Data.Sayings")
local City = require(Shared .. "Sim.City")
local StarterHouse = require(Shared .. "Data.StarterHouse")
local Rng = require(Shared .. "Util.Rng")

local L = Tuning.Life

local function town(count)
	local p = Schema.newProfile()
	local rng = Rng.new(5)
	for i = 1, count do
		local input = Schema.cleanVillagerInput({ name = "V" .. i, pers = "sunny", app = Appearance.default() })
		p.villagers["v" .. i] = Schema.newVillager("v" .. i, input, rng)
		table.insert(p.order, "v" .. i)
	end
	return p
end

describe("Life", function()
	it("levels hearts up and pays each level out at once, with a notice", function()
		-- (the user: "make it a notification instead of a box that the player has to choose from.
		-- make it such that it gives you coins and get better effeciency at work")
		local p = town(1)
		local v = p.villagers.v1
		expect(v.heart).toBe(1)
		local coins = p.coins
		local notices = {}
		local gained = Life.addHearts(p, "v1", Life.heartNeed(1) + Life.heartNeed(2), Rng.new(1), notices)
		expect(gained).toBe(2)
		expect(v.heart).toBe(3)
		-- nothing waits to be picked
		expect(#p.offers).toBe(0)
		-- the coins for levels 2 and 3
		local c2 = Life.heartReward(2)
		local c3 = Life.heartReward(3)
		expect(p.coins).toBe(coins + c2 + c3)
		-- and the practice for both, in their work skill
		local _, s2 = Life.heartReward(2)
		local _, s3 = Life.heartReward(3)
		local want = { name = "Twin", lv = 1, xp = 0 }
		City.addSkill(want, s2)
		City.addSkill(want, s3)
		expect(v.lv).toBe(want.lv)
		expect(v.xp).toBe(want.xp)
		expect(v.lv > 1 or v.xp > 0).toBeTruthy()
		-- one notice a level, filled in, naming the coins
		expect(#notices).toBe(2)
		for _, n in notices do
			expect(not n:find("{") and n:find(v.name, 1, true) ~= nil and n:find("coins", 1, true) ~= nil).toBeTruthy()
		end
		-- worth about a day's work at a new heart level, not a week's
		expect(L.RewardSkillPerLevel * 2).toBeBetween(Tuning.Jobs.XpPerDay / 2, Tuning.Jobs.XpPerDay * 2)
	end)

	it("pays out an old save's thank yous that were still waiting to be picked, once", function()
		local p = town(1)
		local v = p.villagers.v1
		table.insert(p.offers, {
			vid = "v1",
			level = 4,
			options = { { kind = "coins", n = 1 }, { kind = "saying", id = "tea" } },
		})
		-- junk in a saved offer does nothing and still clears
		table.insert(p.offers, { vid = "nobody", level = 2 })
		table.insert(p.offers, "junk")
		local coins = p.coins
		local notices = Life.settleOffers(p)
		expect(#notices).toBe(1)
		expect(p.coins).toBe(coins + (Life.heartReward(4)))
		expect(v.lv > 1 or v.xp > 0).toBeTruthy()
		expect(#p.offers).toBe(0)
		expect(#Life.settleOffers(p)).toBe(0)
		expect(p.coins).toBe(coins + (Life.heartReward(4)))
		expect(p.inv).toBe(nil)
	end)

	it("prices a craving from the food, and nothing else", function()
		local p = town(2)
		local v = p.villagers.v1
		-- no wish, no price
		expect(Life.wishPrice(p, "v1")).toBe(nil)
		expect(Life.wishPrice(p, "nobody")).toBe(nil)
		-- every food can be craved, and each has its price: the food's own times the markup,
		-- in whole steps, never nothing
		for _, food in Foods.list do
			v.wish = { kind = "food", arg = food.id, untilT = 1e9 }
			local price = Life.wishPrice(p, "v1")
			expect(type(price)).toBe("number")
			expect(price).toBe(Life.cravingPrice(food.id))
			expect(price % L.CravingStep).toBe(0)
			expect(price >= L.CravingStep).toBeTruthy()
			expect(math.abs(price - food.price * L.CravingMarkup) <= L.CravingStep / 2).toBeTruthy()
			expect(price >= food.price).toBeTruthy()
		end
		-- a dearer food is a dearer craving
		expect(Life.cravingPrice("goldapple") > Life.cravingPrice("apple")).toBeTruthy()
		-- the wishes you don't pay for have no price
		for _, wish in { { kind = "friend", arg = "v2" }, { kind = "cheer" } } do
			v.wish = wish
			expect(Life.wishPrice(p, "v1")).toBe(nil)
		end
		-- nor does a craving for something that isn't a food, or a wish that isn't one
		for _, wish in { { kind = "food", arg = "nonsense" }, { kind = "food" }, { kind = "food", arg = 7 }, "food", 3 } do
			v.wish = wish
			expect(Life.wishPrice(p, "v1")).toBe(nil)
		end
		expect(Life.cravingPrice(nil)).toBe(nil)
		expect(Life.cravingPrice({})).toBe(nil)
		-- not free, and never out of reach of a day's work: the dearest craving is less than
		-- the worst paid job brings in at the mood a villager starts with
		local dearest, least = 0, math.huge
		for _, food in Foods.list do
			dearest = math.max(dearest, Life.cravingPrice(food.id))
		end
		for _, job in Jobs.list do
			least = math.min(least, Jobs.pay(job, 1, Tuning.Villagers.StartMood, "none"))
		end
		expect(dearest < least).toBeTruthy()
	end)

	it("buys a craving: takes the coins, grants the wish, gives none back", function()
		local p = town(2)
		local v = p.villagers.v1
		local food = if v.fav == "apple" then "bread" else "apple"
		v.wish = { kind = "food", arg = food, untilT = 1e9 }
		local price = Life.wishPrice(p, "v1")
		p.coins = price + 7
		local mood, wishes = v.mood, p.stats.wishes
		local ok, cost, notices, why = Life.buyWish(p, "v1", Rng.new(1))
		expect(ok).toBe(true)
		expect(cost).toBe(price)
		expect(why).toBe(nil)
		expect(p.coins).toBe(7)
		expect(v.wish).toBe(nil)
		expect(p.stats.wishes).toBe(wishes + 1)
		expect(v.mood).toBe(math.min(Tuning.Villagers.MoodMax, mood + L.WishMood))
		expect(v.hxp + (v.heart - 1) * Life.heartNeed(1)).toBe(L.WishHearts)
		expect(#notices >= 1).toBeTruthy()
		for _, n in notices do
			expect(n:find("{") == nil and n:find("coins") == nil).toBeTruthy()
		end
		expect(p.inv).toBe(nil)
		-- once: there is nothing to buy a second time
		local again, _, _, reason = Life.buyWish(p, "v1", Rng.new(1))
		expect(again).toBe(false)
		expect(type(reason)).toBe("string")
		expect(p.coins).toBe(7)
	end)

	it("gives a little more when the craving was for their favourite", function()
		local p = town(2)
		local a, b = p.villagers.v1, p.villagers.v2
		a.wish = { kind = "food", arg = a.fav, untilT = 1e9 }
		local plain = if b.fav == "apple" then "bread" else "apple"
		b.wish = { kind = "food", arg = plain, untilT = 1e9 }
		p.coins = 1e5
		local moodA, moodB = a.mood, b.mood
		expect((Life.buyWish(p, "v1", Rng.new(1)))).toBe(true)
		expect((Life.buyWish(p, "v2", Rng.new(1)))).toBe(true)
		expect(a.mood - moodA).toBe(L.WishMood + L.FavWishMood)
		expect(b.mood - moodB).toBe(L.WishMood)
		local function points(v)
			local n = v.hxp
			for level = 1, v.heart - 1 do
				n += Life.heartNeed(level)
			end
			return n
		end
		expect(points(a)).toBe(L.WishHearts + L.FavWishHearts)
		expect(points(b)).toBe(L.WishHearts)
	end)

	it("won't buy a craving without the coins, and leaves everything as it was", function()
		local p = town(1)
		local v = p.villagers.v1
		v.wish = { kind = "food", arg = "honeycake", untilT = 1e9 }
		local price = Life.wishPrice(p, "v1")
		for _, coins in { 0, 1, price - 1 } do
			p.coins = coins
			local mood, hxp = v.mood, v.hxp
			local ok, cost, notices, why = Life.buyWish(p, "v1", Rng.new(1))
			expect(ok).toBe(false)
			expect(cost).toBe(price)
			expect(why).toBe("Not enough coins.")
			expect(#notices).toBe(0)
			expect(p.coins).toBe(coins)
			expect(v.wish ~= nil and v.wish.arg == "honeycake").toBeTruthy()
			expect(v.mood).toBe(mood)
			expect(v.hxp).toBe(hxp)
			expect(p.stats.wishes).toBe(0)
		end
		-- exactly enough is enough
		p.coins = price
		expect((Life.buyWish(p, "v1", Rng.new(1)))).toBe(true)
		expect(p.coins).toBe(0)
	end)

	it("won't buy what isn't a craving: no wish, another kind of wish, nobody, junk", function()
		local p = town(2)
		local v = p.villagers.v1
		p.coins = 5000
		local function refused(vid)
			local ok, cost, notices, why = Life.buyWish(p, vid, Rng.new(1))
			expect(ok).toBe(false)
			expect(cost).toBe(0)
			expect(#notices).toBe(0)
			expect(type(why) == "string" and #why > 0).toBeTruthy()
			expect(p.coins).toBe(5000)
			expect(p.stats.wishes).toBe(0)
		end
		refused("v1") -- no wish at all
		for _, wish in
			{
				{ kind = "friend", arg = "v2", untilT = 1e9 },
				{ kind = "cheer", untilT = 1e9 },
			}
		do
			v.wish = wish
			refused("v1")
			-- and the wish is still there to be granted the right way
			expect(v.wish).toBe(wish)
		end
		v.wish = { kind = "food", arg = "nonsense", untilT = 1e9 }
		refused("v1")
		v.wish = { kind = "food", arg = "apple", untilT = 1e9 }
		for _, junk in { "nobody", "", 7, true, {}, 0 / 0 } do
			refused(junk)
		end
		refused(nil)
		expect(v.wish.arg).toBe("apple")
	end)

	it("grants a wish only with the right answer", function()
		local p = town(2)
		local v = p.villagers.v1
		v.wish = { kind = "food", arg = v.fav, untilT = 1e9 }
		local other = if v.fav == "apple" then "bread" else "apple"
		expect((Life.grantWish(p, "v1", "food", other, Rng.new(1)))).toBe(false)
		expect((Life.grantWish(p, "v1", "cheer", nil, Rng.new(1)))).toBe(false)
		local coins = p.coins
		local heartWas = v.heart
		local ok, paid = Life.grantWish(p, "v1", "food", v.fav, Rng.new(1))
		expect(ok).toBe(true)
		expect(v.wish).toBe(nil)
		-- a craving is paid for (Life.buyWish), so it gives no coins back (only a heart level it
		-- brings pays, at once)
		expect(paid).toBe(0)
		local levelled = 0
		for level = heartWas + 1, v.heart do
			levelled += (Life.heartReward(level))
		end
		expect(p.coins).toBe(coins + levelled)
		expect(p.stats.wishes).toBe(1)
		expect(v.hxp > 0 or v.heart > 1).toBeTruthy()
		-- a wish that cost nothing still brings a few coins
		v.wish = { kind = "cheer", untilT = 1e9 }
		local heartThen = v.heart
		local okCheer, gift = Life.grantWish(p, "v1", "cheer", nil, Rng.new(1))
		expect(okCheer).toBe(true)
		expect(gift).toBeBetween(L.WishCoinsMin, L.WishCoinsMax)
		for level = heartThen + 1, v.heart do
			levelled += (Life.heartReward(level))
		end
		expect(p.coins).toBe(coins + levelled + gift)
	end)

	it("never wishes for a new look, and drops one an old save holds", function()
		-- the user: "remove new look cravings"
		expect(Life.WishIcons.look).toBe(nil)
		expect(Schema.WishKinds.look).toBe(nil)
		local p = town(4)
		local rng = Rng.new(9)
		for t = 1, 400 do
			for _, v in p.villagers do
				v.wish = nil
			end
			for vid in p.villagers do
				local w = Life.maybeWish(p, vid, rng, t)
				if w then
					expect(w.kind ~= "look").toBe(true)
				end
			end
		end
		local raw = Schema.newProfile()
		local q = town(1)
		raw.villagers, raw.order = q.villagers, q.order
		raw.villagers.v1.wish = { kind = "look", untilT = 1e12 }
		local loaded = Schema.migrate(raw)
		expect(loaded.villagers.v1.wish).toBe(nil)
	end)

	it("introduces villagers for a friend wish", function()
		local p = town(2)
		p.villagers.v1.wish = { kind = "friend", arg = "v2", untilT = 1e9 }
		local ok = Life.grantWish(p, "v1", "friend", "v2", Rng.new(1))
		expect(ok).toBe(true)
		expect(Relationships.peek(p, "v1", "v2")).toBe(L.IntroduceGain)
	end)

	it("hands out wishes with sensible text and keeps to the cap", function()
		local p = town(6)
		local rng = Rng.new(9)
		for _ = 1, 400 do
			for _, vid in p.order do
				Life.maybeWish(p, vid, rng, 0)
			end
		end
		expect(Life.openWishes(p)).toBe(L.MaxWishes)
		for _, vid in p.order do
			local text = Life.wishText(p, vid)
			if p.villagers[vid].wish then
				expect(type(text) == "string" and not text:find("{")).toBeTruthy()
			end
		end
		-- every craving handed out is for a food there is, so it always has a price, and their
		-- favourite comes up about half the time
		local cravings, favs = 0, 0
		for seed = 1, 3000 do
			local q = town(1)
			local v = q.villagers.v1
			local wish = Life.maybeWish(q, "v1", Rng.new(seed), 0)
			if wish and wish.kind == "food" then
				cravings += 1
				expect(Foods.get(wish.arg) ~= nil).toBeTruthy()
				expect(type(Life.wishPrice(q, "v1"))).toBe("number")
				favs += if wish.arg == v.fav then 1 else 0
			end
		end
		expect(cravings > 50).toBeTruthy()
		expect(favs / cravings).toBeBetween(0.4, 0.65)
	end)

	it("lets ignored wishes fade", function()
		local p = town(1)
		local v = p.villagers.v1
		v.wish = { kind = "cheer", untilT = 100 }
		local mood = v.mood
		expect(#Life.fadeWishes(p, 50)).toBe(0)
		expect(#Life.fadeWishes(p, 150)).toBe(1)
		expect(v.wish).toBe(nil)
		expect(v.mood < mood).toBeTruthy()
	end)

	it("has no romance: best friends is as close as two villagers get", function()
		-- nothing to set or read a bond with, and nothing counted for one
		for _, gone in { "BondNames", "bond", "setBond", "partnerOf", "free" } do
			expect(Life[gone]).toBe(nil)
		end
		local p = town(3)
		expect(p.stats.couples).toBe(nil)
		expect(p.stats.partners).toBe(nil)
		-- the most a friendship can be is best friends
		Relationships.add(p, "v1", "v2", 1000)
		local index, name = Relationships.level(Relationships.peek(p, "v1", "v2"))
		expect(index).toBe(#Tuning.Relationships.Levels)
		expect(name).toBe("Best friends")
		expect(Schema.BestFriends).toBe(Tuning.Relationships.Levels[index].Min)
		expect(p.rel[Schema.pairKey("v1", "v2")].bond).toBe(nil)
		-- and no goal is about a couple; there is one for best friends
		for _, g in Goals.list do
			local words = (g.name .. " " .. g.desc):lower()
			for _, gone in { "couple", "sweetheart", "partner", "crush", "romance", "love" } do
				expect(words:find(gone, 1, true)).toBe(nil)
			end
		end
		expect(Goals.get("couple")).toBe(nil)
		expect(Goals.get("partners")).toBe(nil)
		expect((Life.claimGoal(p, "bestfriends"))).toBe(true)
		expect((Life.claimGoal(p, "bestfriends3"))).toBe(false)
		Relationships.add(p, "v1", "v3", 90)
		Relationships.add(p, "v2", "v3", 90)
		expect((Life.claimGoal(p, "bestfriends3"))).toBe(true)
		-- best friends with someone who has moved away don't count
		local q = town(2)
		Relationships.add(q, "v1", "v9", 90)
		expect((Life.claimGoal(q, "bestfriends"))).toBe(false)
	end)

	it("loads an old save's crush, sweethearts and partners as best friends", function()
		local best = Schema.BestFriends
		local old = {
			coins = 50,
			villagers = {
				a = { name = "A", pers = "sunny" },
				b = { name = "B", pers = "shy" },
				c = { name = "C", pers = "bold" },
				d = { name = "D", pers = "gentle" },
			},
			order = { "a", "b", "c", "d" },
			rel = {
				["a|b"] = { s = 60, n = 5, bond = "crush" },
				["a|c"] = { s = 92, n = 20, bond = "sweethearts" },
				["b|c"] = { s = 70, n = 9, q = 400, bond = "partners" },
				["c|d"] = { s = 12, n = 2 },
				["a|d"] = { s = "lots", n = 1, bond = "partners" },
				["b|d"] = { s = 40, n = 3, bond = "nonsense" },
			},
			stats = { events = 4, wishes = 2, couples = 2, partners = 1 },
			goals = { settlers = true, couple = true, partners = true },
		}
		local p = Schema.migrate(old)
		-- a crush and sweethearts below the mark come up to best friends; one above it keeps its score
		expect(p.rel["a|b"].s).toBe(best)
		expect(p.rel["a|c"].s).toBe(92)
		expect(p.rel["b|c"].s).toBe(best)
		expect(p.rel["a|d"].s).toBe(best)
		-- a quarrel and how often they met are kept; a pair that had no romance is left alone
		expect(p.rel["b|c"].q).toBe(400)
		expect(p.rel["a|c"].n).toBe(20)
		expect(p.rel["c|d"].s).toBe(12)
		-- a bond that was never romance is dropped and leaves the score as it was
		expect(p.rel["b|d"].s).toBe(40)
		for _, rel in p.rel do
			expect(rel.bond).toBe(nil)
		end
		for _, key in { "a|b", "a|c", "b|c", "a|d" } do
			local _, name = Relationships.level(p.rel[key].s)
			expect(name).toBe("Best friends")
		end
		-- the counts and goals that went with romance are gone; the rest stay
		expect(p.stats.couples).toBe(nil)
		expect(p.stats.partners).toBe(nil)
		expect(p.stats.wishes).toBe(2)
		expect(p.goals.couple).toBe(nil)
		expect(p.goals.partners).toBe(nil)
		expect(p.goals.settlers).toBe(true)
		-- and it loads the same the second time
		local again = Schema.migrate(p)
		expect(again.rel["a|b"].s).toBe(best)
		expect(again.rel["c|d"].s).toBe(12)
	end)

	it("pays goals once, and only when they're done", function()
		local p = town(3)
		expect((Life.claimGoal(p, "wishes3"))).toBe(false)
		local ok, coins = Life.claimGoal(p, "settlers")
		expect(ok).toBe(true)
		expect(coins).toBe(Goals.get("settlers").reward)
		expect((Life.claimGoal(p, "settlers"))).toBe(false)
		expect((Life.claimGoal(p, "nonsense"))).toBe(false)
		local list = Life.goals(p)
		expect(#list).toBe(#Goals.list)
		for _, g in list do
			expect(g.goal.desc:find("\u{2014}") == nil).toBeTruthy()
		end
	end)

	it("has goals about villagers working and none about food or a shop", function()
		local ids = {}
		for _, g in Goals.list do
			expect(ids[g.id]).toBe(nil)
			ids[g.id] = true
			local words = (g.name .. " " .. g.desc):lower()
			for _, gone in { "feed", "fed ", "snack", "shop", "food", "buy" } do
				expect(words:find(gone, 1, true)).toBe(nil)
			end
		end
		-- people in a job, at each size of town a level asks for and no more than can be had
		local p = town(3)
		p.plan = StarterHouse.plan()
		p.plan.items.stall = { id = "work_market", x = 130, y = 0, z = 12, r = 180, lv = 0 }
		expect((Life.claimGoal(p, "work2"))).toBe(false)
		p.villagers.v1.job = City.freeWorkplace(p)
		expect((Life.claimGoal(p, "work2"))).toBe(false)
		p.villagers.v2.job = City.freeWorkplace(p)
		local ok, coins = Life.claimGoal(p, "work2")
		expect(ok).toBe(true)
		expect(coins).toBe(Goals.get("work2").reward)
		for _, id in { "work2", "work6", "work10" } do
			expect(Goals.get(id).need <= Tuning.Villagers.Max).toBeTruthy()
		end
		-- wages earned (paydays add to stats.earned) and skill at work
		expect((Life.claimGoal(p, "wages"))).toBe(false)
		p.stats.earned = Goals.get("wages").need
		expect((Life.claimGoal(p, "wages"))).toBe(true)
		expect((Life.claimGoal(p, "skill5"))).toBe(false)
		p.villagers.v3.lv = Goals.get("skill5").need
		expect((Life.claimGoal(p, "skill5"))).toBe(true)
		expect(Goals.get("skill5").need <= Tuning.Jobs.SkillCap).toBeTruthy()
		-- a goal's coins are an extra beside wages: the biggest is a few days of a full town's pay
		local pay = 0
		for _, job in Jobs.list do
			pay += Jobs.pay(job, 1, Tuning.Villagers.StartMood, "none")
		end
		for _, g in Goals.list do
			expect(g.reward <= pay).toBeTruthy()
		end
	end)

	it("fills in hearts and goals for old saves", function()
		local old = { coins = 50, villagers = { a = { name = "Old", pers = "sunny" } }, order = { "a" } }
		local p = Schema.migrate(old)
		expect(p.villagers.a.heart).toBe(1)
		expect(type(p.offers)).toBe("table")
		expect(type(p.goals)).toBe("table")
		expect(p.stats.wishes).toBe(0)
	end)

	it("drops a saved wish it can't make sense of, and keeps the ones it can", function()
		local function load(wish)
			local old =
				{ coins = 50, villagers = { a = { name = "Old", pers = "sunny", wish = wish } }, order = { "a" } }
			return Schema.migrate(old).villagers.a.wish
		end
		expect(load({ kind = "food", arg = "apple", untilT = 9 }).arg).toBe("apple")
		expect(load({ kind = "cheer", untilT = 9 }).kind).toBe("cheer")
		expect(load({ kind = "friend", arg = "b", untilT = 9 }).kind).toBe("friend")
		expect(load({ kind = "food", arg = "medicine", untilT = 9 })).toBe(nil)
		expect(load({ kind = "food", untilT = 9 })).toBe(nil)
		expect(load({ kind = "feast" })).toBe(nil)
		expect(load("food")).toBe(nil)
		expect(load(4)).toBe(nil)
	end)
end)
