--!nocheck
-- Hearts, wishes, romance and town goals (Sim/Life): heart levels queue thank yous that pay out
-- once, snacks only count a few times a day, wishes are granted only by the right answer and
-- fade when ignored, bonds count couples once, and goals pay once when they're done.

local Shared = "ReplicatedStorage.Shared."
local Tuning = require(Shared .. "Config.Tuning")
local Schema = require(Shared .. "Sim.Schema")
local Life = require(Shared .. "Sim.Life")
local Relationships = require(Shared .. "Sim.Relationships")
local Appearance = require(Shared .. "Avatar.Appearance")
local Foods = require(Shared .. "Data.Foods")
local Goals = require(Shared .. "Data.Goals")
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
	it("levels hearts up and offers three thank yous each time", function()
		local p = town(1)
		local v = p.villagers.v1
		expect(v.heart).toBe(1)
		local gained = Life.addHearts(p, "v1", Life.heartNeed(1) + Life.heartNeed(2), Rng.new(1))
		expect(gained).toBe(2)
		expect(v.heart).toBe(3)
		expect(#p.offers).toBe(2)
		for _, offer in p.offers do
			expect(#offer.options).toBe(3)
			for _, o in offer.options do
				expect(Life.rewardText(o) ~= "?").toBeTruthy()
			end
		end
	end)

	it("pays a thank you once", function()
		local p = town(1)
		Life.addHearts(p, "v1", Life.heartNeed(1), Rng.new(2))
		local before = p.coins
		local ok = Life.claimReward(p, 1, Rng.new(3)) -- the first option is always coins
		expect(ok).toBe(true)
		expect(p.coins).toBe(before + L.RewardCoinsPerLevel * 2)
		expect(#p.offers).toBe(0)
		expect(Life.claimReward(p, 1, Rng.new(3))).toBe(false)
	end)

	it("only counts the first few snacks a day", function()
		local p = town(1)
		local v = p.villagers.v1
		local food = if Foods.list[1].id == v.hate then Foods.list[2].id else Foods.list[1].id
		local total = 0
		for _ = 1, 5 do
			total += Life.fedHearts(p, "v1", food, 7, Rng.new(4))
		end
		expect(total <= L.FeedsPerDay * L.FavHearts).toBeTruthy()
		expect(Life.fedHearts(p, "v1", food, 8, Rng.new(4)) > 0).toBeTruthy()
	end)

	it("grants a wish only with the right answer", function()
		local p = town(2)
		local v = p.villagers.v1
		v.wish = { kind = "food", arg = v.fav, untilT = 1e9 }
		local other = if v.fav == "apple" then "bread" else "apple"
		expect((Life.grantWish(p, "v1", "food", other, Rng.new(1)))).toBe(false)
		expect((Life.grantWish(p, "v1", "cheer", nil, Rng.new(1)))).toBe(false)
		local coins = p.coins
		local ok, paid = Life.grantWish(p, "v1", "food", v.fav, Rng.new(1))
		expect(ok).toBe(true)
		expect(v.wish).toBe(nil)
		expect(p.coins).toBe(coins + paid)
		expect(p.stats.wishes).toBe(1)
		expect(v.hxp > 0 or v.heart > 1).toBeTruthy()
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

	it("keeps romance bonds and counts couples once", function()
		local p = town(3)
		expect(Life.free(p, "v1")).toBe(true)
		Life.setBond(p, "v1", "v2", "crush")
		expect(Life.free(p, "v1")).toBe(false)
		expect(Life.partnerOf(p, "v1")).toBe(nil)
		Life.setBond(p, "v1", "v2", "sweethearts")
		Life.setBond(p, "v2", "v1", "sweethearts")
		expect(p.stats.couples).toBe(1)
		expect((Life.partnerOf(p, "v2"))).toBe("v1")
		Life.setBond(p, "v1", "v2", "partners")
		expect(p.stats.partners).toBe(1)
		expect(Life.free(p, "v3")).toBe(true)
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

	it("fills in hearts and goals for old saves", function()
		local old = { coins = 50, villagers = { a = { name = "Old", pers = "sunny" } }, order = { "a" } }
		local p = Schema.migrate(old)
		expect(p.villagers.a.heart).toBe(1)
		expect(type(p.offers)).toBe("table")
		expect(type(p.goals)).toBe("table")
		expect(p.stats.wishes).toBe(0)
	end)
end)
