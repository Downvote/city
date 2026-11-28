--!nocheck
-- Shopping for looks (Sim/Shopping): the user, "make it such that spending robux on accessories
-- give you gems, and make a reward track based on how much you spend on accessories, giving
-- different types of crates, pets and coin rewards". Gems back for Robux spent, the part of a gem
-- kept for the next buy, each item counted once and nothing for what is free; a track of tiers
-- claimed once each, through Claim all too; an old save loading with nothing spent.

local Shared = "ReplicatedStorage.Shared."
local Tuning = require(Shared .. "Config.Tuning")
local Schema = require(Shared .. "Sim.Schema")
local Shopping = require(Shared .. "Sim.Shopping")
local Crates = require(Shared .. "Sim.Crates")
local Rewards = require(Shared .. "Sim.Rewards")
local ClaimAll = require(Shared .. "Sim.ClaimAll")
local CrateData = require(Shared .. "Data.Crates")
local PetData = require(Shared .. "Data.Pets")
local Passes = require(Shared .. "Data.Passes")
local Goals = require(Shared .. "Data.Goals")
local Shop = require(Shared .. "Avatar.Shop")
local Rng = require(Shared .. "Util.Rng")

local K = Tuning.Shopping
local DAY = 20000

local function fresh()
	local p = Schema.newProfile()
	-- (today's gift had, so Claim all finds only the track)
	p.daily = { last = DAY, streak = 1, run = 1 }
	return p
end

local function clean(line)
	return line:find("\u{2014}") == nil and line:find("\u{2013}") == nil and line:find("!") == nil
end

describe("Shopping", function()
	it("gives a gem for every 10 Robux, keeping the part of a gem for the next buy", function()
		expect(K.Gems).toBe(0.1)
		local p = fresh()
		local got = Shopping.record(p, "asset", 101, 75)
		expect(got.gems).toBe(7)
		expect(got.robux).toBe(75)
		expect(p.shopping.carry).toBeNear(0.5, 1e-6)
		-- the half gem left joins the next one
		got = Shopping.record(p, "asset", 102, 5)
		expect(got.gems).toBe(1)
		expect(p.shopping.carry).toBeNear(0, 1e-6)
		-- small buys add up
		local total = 0
		for i = 1, 30 do
			total += Shopping.record(p, "asset", 200 + i, 3).gems
		end
		expect(total).toBe(9)
		expect(p.shopping.spent).toBe(75 + 5 + 90)
		-- a bundle too
		expect(Shopping.record(p, "bundle", 101, 400).gems).toBe(40)
		expect(p.shopping.spent).toBe(570)
	end)

	it("sits with the gem packs: a gem costs more bought as a look than bought as gems", function()
		-- (Roblox sells the item, and the game gets a cut of it: Tuning.Shopping)
		for _, pack in Passes.packs do
			expect(K.Gems < pack.gems / pack.price).toBeTruthy()
		end
		expect(K.Gems > 0).toBeTruthy()
	end)

	it("counts an item once, ever", function()
		local p = fresh()
		expect(Shopping.counted(p, "asset", 55)).toBe(false)
		local first = Shopping.record(p, "asset", 55, 100)
		expect(first.gems).toBe(10)
		expect(Shopping.counted(p, "asset", 55)).toBe(true)
		local again, why = Shopping.record(p, "asset", 55, 100)
		expect(again).toBe(nil)
		expect(why).toBe("counted")
		expect(p.shopping.spent).toBe(100)
		-- an asset and a bundle with the same number are two things
		expect(Shopping.record(p, "bundle", 55, 100) ~= nil).toBeTruthy()
		-- the list keeps the newest Kept
		for i = 1, K.Kept + 10 do
			Shopping.record(p, "asset", 10000 + i, 1)
		end
		expect(#p.shopping.counted).toBe(K.Kept)
		expect(Shopping.counted(p, "asset", 10000 + K.Kept + 10)).toBe(true)
	end)

	it("counts nothing for what is free, and refuses what isn't an item", function()
		local p = fresh()
		for _, price in { 0, -5, 0 / 0, math.huge, "50", nil } do
			local got = Shopping.record(p, "asset", 77, price)
			expect(got).toBe(nil)
		end
		local _, why = Shopping.record(p, "asset", 77, 0)
		expect(why).toBe("free")
		expect(p.shopping.spent).toBe(0)
		expect(Shopping.counted(p, "asset", 77)).toBe(false)
		-- (bought later at a price, it still counts)
		expect(Shopping.record(p, "asset", 77, 20).gems).toBe(2)
		for _, bad in { { "hat", 1 }, { "asset", 0 }, { "asset", 1.5 }, { "asset", -3 }, { "bundle", "9" } } do
			local got, w = Shopping.record(p, bad[1], bad[2], 100)
			expect(got).toBe(nil)
			expect(w).toBe("bad")
		end
		-- one item counts for ItemMax at most
		expect(Shopping.record(p, "asset", 78, 10 ^ 9).robux).toBe(K.ItemMax)
	end)

	it("has tiers that rise, each with a reward there is", function()
		local last = 0
		local seen = {}
		local kinds = { coins = 0, crate = 0, pet = 0 }
		for _, t in Shopping.Tiers do
			expect(t.spend > last).toBeTruthy()
			last = t.spend
			expect(seen[t.id]).toBe(nil)
			seen[t.id] = true
			expect(Shopping.tier(t.id)).toBe(t)
			local n = (if t.coins then 1 else 0) + (if t.crate then 1 else 0) + (if t.pet then 1 else 0)
			expect(n).toBe(1)
			if t.coins then
				expect(t.coins > 0 and t.coins % 1 == 0).toBeTruthy()
				kinds.coins += 1
			end
			if t.crate then
				expect(CrateData.get(t.crate) ~= nil).toBeTruthy()
				expect((t.n or 1) >= 1 and (t.n or 1) <= Tuning.Crates.Held).toBeTruthy()
				kinds.crate += 1
			end
			if t.pet then
				expect(PetData.get(t.pet) ~= nil).toBeTruthy()
				kinds.pet += 1
			end
			local name = Shopping.rewardName(t)
			expect(#name > 0 and clean(name)).toBeTruthy()
			expect(type(Shopping.icon(t))).toBe("string")
		end
		expect(#Shopping.Tiers >= 10 and #Shopping.Tiers <= 14).toBeTruthy()
		expect(Shopping.Tiers[1].spend <= 50).toBeTruthy()
		expect(last >= 2500).toBeTruthy()
		expect(kinds.coins >= 3 and kinds.crate >= 3 and kinds.pet >= 3).toBeTruthy()
		-- both kinds of crate
		local crateKinds = {}
		for _, t in Shopping.Tiers do
			if t.crate then
				crateKinds[t.crate] = true
			end
		end
		for _, kind in CrateData.Order do
			expect(crateKinds[kind]).toBe(true)
		end
		-- each reward bigger than the one of its kind before: coins grow, pets climb the rarities
		local coins, rank = 0, 0
		for _, t in Shopping.Tiers do
			if t.coins then
				expect(t.coins > coins).toBeTruthy()
				coins = t.coins
			elseif t.pet then
				local r = CrateData.rank(PetData.get(t.pet).rarity)
				expect(r > rank).toBeTruthy()
				rank = r
			end
		end
		-- the top coins worth more than the best town goal, the first no more than a few daily gifts
		local bestGoal = 0
		for _, g in Goals.list do
			bestGoal = math.max(bestGoal, g.reward)
		end
		expect(coins > bestGoal).toBeTruthy()
		local firstCoins = nil
		for _, t in Shopping.Tiers do
			firstCoins = firstCoins or t.coins
		end
		expect(firstCoins <= 4 * Tuning.Economy.DailyGift).toBeTruthy()
	end)

	it("reaches tiers as Robux add up, and says so", function()
		local p = fresh()
		expect(Shopping.ready(p)).toBe(0)
		expect(Shopping.next(p)).toBe(Shopping.Tiers[1])
		local got = Shopping.record(p, "asset", 1, Shopping.Tiers[1].spend - 1)
		expect(got.reached).toBe(0)
		got = Shopping.record(p, "asset", 2, Shopping.Tiers[2].spend)
		expect(got.reached).toBe(2)
		expect(Shopping.ready(p)).toBe(2)
		expect(Shopping.next(p)).toBe(Shopping.Tiers[3])
		expect(Rewards.waiting(p, DAY, false)).toBe(2)
		-- the notices
		expect(Shopping.boughtNotice(12, 0)).toBe("+12 gems for your new look.")
		expect(Shopping.boughtNotice(1, 1)).toBe("+1 gem for your new look. A shopping reward is ready.")
		expect(clean(Shopping.boughtNotice(0, 0))).toBeTruthy()
	end)

	it("claims a tier once, when reached, with its coins, crates or pet", function()
		local p = fresh()
		local rng = Rng.new(4)
		local ok, why = Shopping.claim(p, "s1", rng)
		expect(ok).toBe(false)
		expect(why).toBe("Not yet.")
		expect(Shopping.claim(p, "nope", rng)).toBe(false)
		p.shopping.spent = 10000
		expect(Shopping.ready(p)).toBe(#Shopping.Tiers)
		local coins, crates, pets = 0, { work = 0, pet = 0 }, {}
		for _, t in Shopping.Tiers do
			local done, got = Shopping.claim(p, t.id, rng)
			expect(done).toBe(true)
			expect(got.tier).toBe(t)
			expect(got.coins).toBe(t.coins or 0)
			coins += got.coins
			expect(#got.crates).toBe(if t.crate then t.n or 1 else 0)
			for _, kind in got.crates do
				crates[kind] += 1
			end
			if t.pet then
				expect(got.pet.id).toBe(t.pet)
				expect(type(got.pet.petName)).toBe("string")
				expect(p.pets[got.pet.pet].kind).toBe(t.pet)
				table.insert(pets, got.pet.pet)
				expect(clean(Shopping.petLine(got.pet))).toBeTruthy()
			else
				expect(got.pet).toBe(nil)
			end
			expect(clean(Shopping.claimNotice(got))).toBeTruthy()
			-- once
			local again, why2 = Shopping.claim(p, t.id, rng)
			expect(again).toBe(false)
			expect(why2).toBe("You've had that one.")
		end
		expect(Crates.held(p, "work")).toBe(crates.work)
		expect(Crates.held(p, "pet")).toBe(crates.pet)
		expect(Crates.petCount(p)).toBe(#pets)
		expect(Shopping.ready(p)).toBe(0)
		-- (no crate was opened for it)
		expect(p.stats.crates or 0).toBe(0)
		local sum = 0
		for _, t in Shopping.Tiers do
			sum += t.coins or 0
		end
		expect(coins).toBe(sum)
	end)

	it("waits on a tier with no room for its pet or its crates", function()
		local p = fresh()
		p.shopping.spent = 10000
		for i = 1, Tuning.Pets.Max do
			p.pets["p" .. i] = { kind = "cat", name = "C" .. i, coat = 1 }
		end
		p.crates = { work = Tuning.Crates.Held }
		local petTier, workTier
		for _, t in Shopping.Tiers do
			petTier = petTier or (if t.pet then t else nil)
			workTier = workTier or (if t.crate == "work" then t else nil)
		end
		local ok, why = Shopping.claim(p, petTier.id, Rng.new(1))
		expect(ok).toBe(false)
		expect(why).toBe("You have as many pets as you can keep.")
		ok = Shopping.claim(p, workTier.id, Rng.new(1))
		expect(ok).toBe(false)
		expect(p.shopping.got[petTier.id]).toBe(nil)
		expect(p.shopping.got[workTier.id]).toBe(nil)
		-- the badge doesn't count what can't be had, and Claim all leaves it
		local blocked = 0
		for _, st in Shopping.status(p) do
			if st.blocked then
				blocked += 1
			end
		end
		expect(blocked > 0).toBeTruthy()
		expect(Shopping.ready(p)).toBe(#Shopping.Tiers - blocked)
		local haul = ClaimAll.rewards(p, DAY, false, false, Rng.new(2))
		expect(haul.shopping).toBe(#Shopping.Tiers - blocked)
		expect(p.shopping.got[petTier.id]).toBe(nil)
		-- room made, it comes
		p.pets.p1 = nil
		expect(Shopping.claim(p, petTier.id, Rng.new(3))).toBe(true)
	end)

	it("comes with Claim all, paying what the single claims would", function()
		local p = fresh()
		p.shopping.spent = Shopping.Tiers[6].spend
		local q = Schema.migrate(Schema.newProfile())
		q.daily = { last = DAY, streak = 1, run = 1 }
		q.shopping.spent = p.shopping.spent
		local waiting = Rewards.waiting(p, DAY, false)
		expect(waiting).toBe(6)
		local haul = ClaimAll.rewards(p, DAY, false, false, Rng.new(9))
		expect(haul.count).toBe(6)
		expect(haul.shopping).toBe(6)
		local coins, crates, pets = 0, 0, 0
		for i = 1, 6 do
			local ok, got = Shopping.claim(q, Shopping.Tiers[i].id, Rng.new(i))
			expect(ok).toBe(true)
			coins += got.coins
			crates += #got.crates
			pets += if got.pet then 1 else 0
		end
		expect(haul.coins).toBe(coins)
		expect(haul.gems).toBe(0)
		expect(#haul.crates).toBe(crates)
		expect(#haul.pets).toBe(pets)
		expect(Crates.petCount(p)).toBe(pets)
		expect(Rewards.waiting(p, DAY, false)).toBe(0)
		expect(ClaimAll.rewards(p, DAY, false, false).count).toBe(0)
		-- the notices
		expect(ClaimAll.petsNotice({})).toBe(nil)
		local one = ClaimAll.petsNotice(haul.pets)
		expect(one ~= nil and clean(one) and one:find("came to live in town") ~= nil).toBeTruthy()
		expect(ClaimAll.petsNotice({ haul.pets[1], haul.pets[1] })).toBe("2 pets came to live in town.")
	end)

	it("starts an old save with nothing spent, and cleans a broken one", function()
		local old = Schema.newProfile()
		old.shopping = nil
		local p = Schema.migrate(old)
		expect(p.shopping.spent).toBe(0)
		expect(p.shopping.carry).toBe(0)
		expect(#p.shopping.counted).toBe(0)
		expect(next(p.shopping.got)).toBe(nil)
		local broken = Schema.newProfile()
		broken.shopping = {
			spent = -4,
			carry = 3,
			counted = { "a12", "a12", "x9", 5, "b7" },
			got = { s1 = true, s99 = true, s2 = "yes" },
		}
		local q = Schema.migrate(broken)
		expect(q.shopping.spent).toBe(0)
		expect(q.shopping.carry).toBe(0)
		expect(#q.shopping.counted).toBe(2)
		expect(q.shopping.got.s1).toBe(true)
		expect(q.shopping.got.s99).toBe(nil)
		expect(q.shopping.got.s2).toBe(nil)
		local kept = Schema.newProfile()
		kept.shopping = { spent = 120.7, carry = 0.25, counted = { "a1", "b2" }, got = { s1 = true } }
		local r = Schema.migrate(kept)
		expect(r.shopping.spent).toBe(120)
		expect(r.shopping.carry).toBe(0.25)
		expect(Shopping.counted(r, "bundle", 2)).toBe(true)
		expect(r.shopping.got.s1).toBe(true)
	end)

	it("reads what a whole look's prompt says was bought", function()
		local asked = { { kind = "asset", id = 1 }, { kind = "bundle", id = 2 } }
		local status = Enum.MarketplaceItemPurchaseStatus
		local types = Enum.MarketplaceProductType
		local bought = Shop.bought({
			RobuxSpent = 50,
			Items = {
				{ type = types.AvatarAsset, id = "1", status = status.Success },
				{ type = types.AvatarBundle, id = "2", status = status.Success },
				{ type = types.AvatarAsset, id = "3", status = status.AlreadyOwned },
				{ type = types.AvatarAsset, id = "x", status = status.Success },
			},
		}, asked)
		expect(#bought).toBe(2)
		expect(bought[1].kind).toBe("asset")
		expect(bought[1].id).toBe(1)
		expect(bought[2].kind).toBe("bundle")
		expect(bought[2].id).toBe(2)
		-- results it can't read: every line asked for (the server asks Roblox about each)
		expect(Shop.bought(nil, asked)).toBe(asked)
		expect(#Shop.bought({}, nil)).toBe(0)
	end)
end)
