--!nocheck
-- Work and pet crates (Data/Crates, Sim/Crates, Data/Pets, Sim/Pets). The user: "add work crates that
-- can be bought with gems or robux, which give exclusive work spaces which are unique to crates,
-- giving a random one with effectiveness scaling off rarity, some of the rarer jobs even giving gems.
-- Crate workspaces are always better than any money ones ... Some work crates are also given through
-- achievements, goals, daily rewards", then "Add pet crates as well ... You can choose to make
-- villagers own the pet ... Which increase mood, satisfy cravings sometimes for you, and provide
-- more interactions." Here: what is in each crate and how likely, the rolls against those odds,
-- crate jobs always paying more than any coin job, the gems they bring kept rare, owning what came
-- out (and putting it down only as often), pets and their owners, and crates as rewards.

local Shared = "ReplicatedStorage.Shared."
local Tuning = require(Shared .. "Config.Tuning")
local Catalog = require(Shared .. "Build.Catalog")
local Geometry = require(Shared .. "Build.Geometry")
local Jobs = require(Shared .. "Data.Jobs")
local CrateData = require(Shared .. "Data.Crates")
local PetData = require(Shared .. "Data.Pets")
local Personalities = require(Shared .. "Data.Personalities")
local Achievements = require(Shared .. "Data.Achievements")
local Goals = require(Shared .. "Data.Goals")
local Crates = require(Shared .. "Sim.Crates")
local Pets = require(Shared .. "Sim.Pets")
local Rewards = require(Shared .. "Sim.Rewards")
local ClaimAll = require(Shared .. "Sim.ClaimAll")
local Life = require(Shared .. "Sim.Life")
local Schema = require(Shared .. "Sim.Schema")
local Gems = require(Shared .. "Sim.Gems")
local Rng = require(Shared .. "Util.Rng")
local Appearance = require(Shared .. "Avatar.Appearance")

local K = Tuning.Crates

local function profileWith(villagers: number?)
	local p = Schema.newProfile()
	p.plan = { items = {} }
	for i = 1, villagers or 0 do
		local vid = "v" .. i
		local input = Schema.cleanVillagerInput({
			name = "V" .. i,
			pers = Personalities.list[(i - 1) % #Personalities.list + 1].id,
			app = Appearance.default(),
		})
		p.villagers[vid] = Schema.newVillager(vid, input, Rng.new(i))
		table.insert(p.order, vid)
	end
	return p
end

local function plain(text: string): boolean
	return not string.find(text, "[{}]") and not string.find(text, "\u{2014}") and not string.find(text, "\u{2013}")
end

describe("Crates", function()
	it("shows what each crate holds by rarity, the chances adding up", function()
		for _, kind in CrateData.Order do
			local def = CrateData.get(kind)
			expect(def ~= nil).toBeTruthy()
			local odds = CrateData.odds(kind)
			-- something of every rarity, each chance as Tuning says it out of the sum
			expect(#odds).toBe(#CrateData.Rarities)
			local sum, total = 0, 0
			for _, r in CrateData.Rarities do
				total += K.Odds[r]
			end
			for i, o in odds do
				expect(o.rarity).toBe(CrateData.Rarities[i])
				expect(o.chance).toBeNear(K.Odds[o.rarity] / total, 1e-9)
				expect(#o.entries >= 1).toBeTruthy()
				sum += o.chance
			end
			expect(sum).toBeNear(1, 1e-9)
			-- the rarer, the less likely
			for i = 2, #odds do
				expect(odds[i].chance < odds[i - 1].chance).toBeTruthy()
			end
		end
		expect(CrateData.percent(0.5)).toBe("50%")
		expect(CrateData.percent(0.02)).toBe("2%")
		expect(CrateData.percent(0.005)).toBe("0.5%")
	end)

	it("rolls each rarity about as often as it says", function()
		local rng = Rng.new(7)
		for _, kind in CrateData.Order do
			local p = profileWith()
			local seen, n = {}, 20000
			for _ = 1, n do
				local e = Crates.roll(p, kind, rng)
				seen[e.rarity] = (seen[e.rarity] or 0) + 1
			end
			for _, o in CrateData.odds(kind) do
				expect((seen[o.rarity] or 0) / n).toBeNear(o.chance, 0.012)
			end
		end
	end)

	it("gives every crate workplace a crate job of its own rarity, never sold for coins", function()
		local jobs = {}
		for _, def in Catalog.list(CrateData.Category) do
			expect(def.price).toBe(0)
			expect(def.crate ~= nil).toBeTruthy()
			local job = Jobs.get(def.job)
			expect(job ~= nil and job.crate == def.crate).toBeTruthy()
			expect(Catalog.hasTag(def, "work")).toBeTruthy()
			jobs[def.job] = true
			-- textured, never plain SmoothPlastic, and kept out of searching and the looks
			for _, prim in Geometry.flatten(Catalog.prims(def)) do
				if prim.mat == "SmoothPlastic" and (prim.transp or 0) < 1 then
					error(def.id .. ": a part in plain SmoothPlastic")
				end
			end
			for _, found in Catalog.search(def.name) do
				expect(found.id ~= def.id).toBeTruthy()
			end
		end
		for _, job in Jobs.crateList do
			expect(jobs[job.id]).toBe(true)
			-- none of them is a coin job, and each has its own icon
			expect(table.find(Jobs.list, job) == nil).toBeTruthy()
		end
		local icons = {}
		for _, job in Jobs.all do
			local icon = Jobs.icon(job.id)
			if icons[icon] then
				error(job.id .. " shares an icon with " .. icons[icon])
			end
			icons[icon] = job.id
		end
	end)

	it("pays more at any crate job than at any coin job, more the rarer it is", function()
		-- "Crate workspaces are always better than any money ones": for the same villager (skill and
		-- mood), a crate job they don't care for pays more than a coin job they love
		for _, c in Jobs.crateList do
			for _, j in Jobs.list do
				for _, skill in { 1, 10, Tuning.Jobs.SkillCap } do
					for _, mood in { 0, 50, 100 } do
						local crate = Jobs.pay(c, skill, mood, "none")
						local coin = Jobs.pay(j, skill, mood, j.likes[1])
						if crate <= coin then
							error(string.format("%s pays %d, %s pays %d", c.id, crate, j.id, coin))
						end
					end
				end
			end
		end
		-- "effectiveness scaling off rarity"
		for _, a in Jobs.crateList do
			for _, b in Jobs.crateList do
				if CrateData.rank(a.crate) > CrateData.rank(b.crate) then
					expect(a.income > b.income).toBeTruthy()
				end
			end
		end
	end)

	it("pays a few gems for the rarer crate jobs, up to a cap a real day", function()
		-- only rare and better
		for _, job in Jobs.crateList do
			local gems = Crates.jobGems(job.id)
			expect(gems > 0).toBe(CrateData.rank(job.crate) >= CrateData.rank("rare"))
		end
		for _, job in Jobs.list do
			expect(Crates.jobGems(job.id)).toBe(0)
		end
		local p = profileWith()
		local legendary = { job = "keeper", share = 1 }
		-- half a day's work or more counts; less doesn't
		expect(Crates.dayGems(p, { { job = "keeper", share = K.GemShare - 0.01 } }, 100)).toBe(0)
		local first = Crates.dayGems(p, { legendary, { job = "ceo", share = 0.9 } }, 100)
		expect(first).toBe(math.min(K.GemDayCap, K.Gems.legendary + K.Gems.epic))
		-- the rest of the day brings no more than the cap
		local more = Crates.dayGems(p, { legendary, legendary, legendary }, 100)
		expect(first + more).toBe(K.GemDayCap)
		expect(Crates.dayGems(p, { legendary }, 100)).toBe(0)
		-- a new day starts again
		expect(Crates.dayGems(p, { legendary }, 101) > 0).toBeTruthy()
		-- and the cap keeps gems rare: no more than the rewards bring in a usual day
		expect(K.GemDayCap <= Tuning.GemRewards.DayMax).toBeTruthy()
	end)

	it("buys with gems and opens at once, or opens one held", function()
		local rng = Rng.new(3)
		local p = profileWith(1)
		p.gems = K.Price.work - 1
		local r, why = Crates.buy(p, "work", rng)
		expect(r).toBe(nil)
		expect(why).toBe("Not enough gems.")
		p.gems = K.Price.work + 2
		r = Crates.buy(p, "work", rng)
		expect(r ~= nil and r.kind == "work").toBeTruthy()
		expect(Gems.count(p)).toBe(2)
		expect(Crates.owned(p, r.id)).toBe(1)
		expect(p.stats.crates).toBe(1)
		-- nothing held: nothing to open; given one, it opens and is gone
		expect(Crates.openHeld(p, "pet", rng)).toBe(nil)
		expect(Crates.give(p, "pet", 1)).toBe(1)
		local pet = Crates.openHeld(p, "pet", rng)
		expect(pet ~= nil and pet.pet ~= nil).toBeTruthy()
		expect(Crates.held(p, "pet")).toBe(0)
		local owned = p.pets[pet.pet]
		expect(owned.kind).toBe(pet.id)
		expect(table.find(PetData.get(pet.id).names, owned.name) ~= nil).toBeTruthy()
		-- no crate of a kind there isn't, and no more held than the cap
		expect(Crates.give(p, "hat", 1)).toBe(nil)
		expect(Crates.give(p, "work", 999)).toBe(K.Held)
		expect(Crates.openHeld(p, "nonsense", rng)).toBe(nil)
	end)

	it("puts a crate workplace down only as often as crates gave it", function()
		local p = profileWith()
		local add = function(key)
			return { type = "add", kind = "items", obj = { id = "crate_hero", x = 10, y = 0, z = 10, r = 0, lv = 0 } }
		end
		local ok, why = Crates.check(p, { add() })
		expect(ok).toBe(false)
		expect(why).toBe("That one only comes out of a work crate.")
		p.crateItems = { crate_hero = 1 }
		expect((Crates.check(p, { add() }))).toBe(true)
		p.plan.items.a = { id = "crate_hero", x = 10, y = 0, z = 10, r = 0, lv = 0 }
		ok, why = Crates.check(p, { add() })
		expect(ok).toBe(false)
		expect(why).toBe("You've put down every one you have.")
		-- taking the one down away makes room in the same change
		expect((Crates.check(p, { { type = "remove", kind = "items", key = "a" }, add() }))).toBe(true)
		-- the Crate tab lists it, rarest first, with what is left
		p.crateItems.crate_magic = 2
		local list = Crates.pieces(p, p.plan)
		expect(list[1].def.id).toBe("crate_hero")
		expect(list[1].left).toBe(0)
		expect(list[2].def.id).toBe("crate_magic")
		expect(list[2].left).toBe(2)
		-- a workplace kept as often as it can be comes out of no more crates
		local rng = Rng.new(5)
		for _, e in CrateData.entries("work") do
			p.crateItems[e.id] = K.MaxOwned
		end
		expect(Crates.blocked(p, "work")).toBe("You have all you can keep from these.")
		expect(Crates.roll(p, "work", rng)).toBe(nil)
	end)

	it("lets a villager own one pet, and leaves it nobody's when they move out", function()
		local p = profileWith(2)
		p.pets = { p1 = { kind = "cat", name = "Biscuit", coat = 1 }, p2 = { kind = "dog", name = "Bean", coat = 2 } }
		expect((Crates.assign(p, "p1", "v1"))).toBe(true)
		expect((Crates.petOf(p, "v1"))).toBe("p1")
		-- a second pet for the same villager takes the place of the first
		expect((Crates.assign(p, "p2", "v1"))).toBe(true)
		expect(p.pets.p1.vid).toBe(nil)
		expect((Crates.petOf(p, "v1"))).toBe("p2")
		-- nobody, a stranger, a pet that isn't theirs
		expect((Crates.assign(p, "p2", "nobody"))).toBe(false)
		expect((Crates.assign(p, "p9", "v2"))).toBe(false)
		expect((Crates.assign(p, "p2", false))).toBe(true)
		expect((Crates.petOf(p, "v1"))).toBe(nil)
		Crates.assign(p, "p1", "v2")
		Crates.forget(p, "v2")
		expect(p.pets.p1.vid).toBe(nil)
		-- a full house of pets opens no more pet crates
		for i = 3, Tuning.Pets.Max do
			p.pets["p" .. i] = { kind = "bunny", name = "Puff", coat = 1 }
		end
		expect(Crates.blocked(p, "pet")).toBe("You have as many pets as you can keep.")
	end)

	it("cleans what a save holds", function()
		local raw = Schema.newProfile()
		raw.villagers.v1 = Schema.newVillager(
			"v1",
			Schema.cleanVillagerInput({ name = "A", pers = "sunny", app = Appearance.default() }),
			Rng.new(1)
		)
		raw.order = { "v1" }
		raw.crates = { work = 2.7, pet = -1, hat = 4 }
		raw.crateItems = { crate_hero = 3, bed_single = 2, crate_magic = 0 / 0 }
		raw.pets = {
			p1 = { kind = "cat", name = "Biscuit", coat = 2, vid = "v1" },
			p2 = { kind = "unicorn", name = "X" },
			p3 = { kind = "dog", name = "", coat = 99, vid = "gone" },
			bad = { kind = "dog" },
		}
		raw.nextPet = "x"
		local p = Schema.migrate(raw)
		expect(p.crates.work).toBe(2)
		expect(p.crates.pet).toBe(nil)
		expect(p.crates.hat).toBe(nil)
		expect(p.crateItems.crate_hero).toBe(3)
		expect(p.crateItems.bed_single).toBe(nil)
		expect(p.crateItems.crate_magic).toBe(nil)
		expect(p.pets.p1.vid).toBe("v1")
		expect(p.pets.p2).toBe(nil)
		expect(p.pets.bad).toBe(nil)
		expect(p.pets.p3.vid).toBe(nil)
		expect(p.pets.p3.coat).toBe(1)
		expect(p.pets.p3.name).toBe(PetData.get("dog").names[1])
		expect(p.nextPet).toBe(1)
		expect(p.crateTold).toBe(false)
		-- a new save starts with none of it
		local fresh = Schema.newProfile()
		expect(next(fresh.crates)).toBe(nil)
		expect(next(fresh.pets)).toBe(nil)
	end)

	it("hands crates out with the daily gift, some achievements and some goals", function()
		-- the daily gift: a work crate on the seventh day running, a pet crate on the fourteenth
		expect(Rewards.dailyCrate(K.DailyEvery)).toBe("work")
		expect(Rewards.dailyCrate(K.DailyEvery * 2)).toBe("pet")
		expect(Rewards.dailyCrate(K.DailyEvery * 3)).toBe("work")
		expect(Rewards.dailyCrate(1)).toBe(nil)
		local p = profileWith()
		p.daily = { last = 99, streak = 6, run = K.DailyEvery - 1 }
		local ok, _, _, crate = Rewards.claimDaily(p, 100, false)
		expect(ok).toBe(true)
		expect(crate).toBe("work")
		expect(Crates.held(p, "work")).toBe(1)
		-- achievements and goals: some of each, of each kind
		local kinds = {}
		for _, a in Achievements.list do
			if a.crate then
				kinds["a" .. a.crate] = true
			end
		end
		for _, g in Goals.list do
			if g.crate then
				kinds["g" .. g.crate] = true
			end
		end
		expect(kinds.awork and kinds.apet and kinds.gwork and kinds.gpet).toBeTruthy()
		-- an achievement's crate is held once it's claimed, and once only
		local a5 = Achievements.get("villager5")
		local q = profileWith(5)
		local got, _, c = Rewards.claimAchievement(q, "villager5")
		expect(got).toBe(true)
		expect(c).toBe(a5.crate)
		expect(Crates.held(q, a5.crate)).toBe(1)
		expect((Rewards.claimAchievement(q, "villager5"))).toBe(false)
		expect(Crates.held(q, a5.crate)).toBe(1)
	end)

	it("hands them out through Claim all too, achievements and goals alike", function()
		local p = profileWith(10)
		p.daily = { last = 99, streak = 6, run = K.DailyEvery - 1 }
		local haul = ClaimAll.rewards(p, 100, false, false)
		-- the seventh day's work crate, and the crates of every achievement that was done
		local want = { work = 1, pet = 0 }
		for _, id in haul.achievements do
			local a = Achievements.get(id)
			if a.crate then
				want[a.crate] += 1
			end
		end
		expect(#haul.crates).toBe(want.work + want.pet)
		expect(Crates.held(p, "work")).toBe(want.work)
		expect(Crates.held(p, "pet")).toBe(want.pet)
		expect(ClaimAll.cratesNotice({ "work" })).toBe("Your work crate is in the Store.")
		expect(ClaimAll.cratesNotice({ "work", "pet" })).toBe("2 crates are in the Store.")
		expect(ClaimAll.cratesNotice({})).toBe(nil)
		-- a goal's crate comes with its claim
		local goal
		for _, g in Goals.list do
			if g.crate then
				goal = g
				break
			end
		end
		local q = profileWith()
		local old = goal.value
		goal.value = function()
			return goal.need
		end
		local before = Crates.held(q, goal.crate)
		local ok, _, notes = Life.claimGoal(q, goal.id)
		goal.value = old
		expect(ok).toBe(true)
		expect(Crates.held(q, goal.crate)).toBe(before + 1)
		local said = false
		for _, n in notes do
			said = said or string.find(n, "crate is in the Store", 1, true) ~= nil
		end
		expect(said).toBeTruthy()
	end)
end)

describe("Pets", function()
	it("has a pet of every rarity, each drawn with its joints and coats", function()
		local rarities = {}
		for _, pet in PetData.list do
			rarities[pet.rarity] = true
			expect(#pet.names >= 3).toBeTruthy()
			expect(#pet.coats >= 1).toBeTruthy()
			expect(#pet.acts >= 1).toBeTruthy()
			for _, act in pet.acts do
				expect(Pets.Acts[act] ~= nil).toBeTruthy()
			end
			for i = 1, #pet.coats do
				local prims = PetData.prims(pet.id, i)
				expect(#prims >= 12 and #prims <= 80).toBeTruthy()
				local bones = {}
				for _, prim in prims do
					expect(prim.mat ~= "SmoothPlastic").toBeTruthy()
					if prim.name then
						bones[prim.name] = true
						-- every named part turns round a joint the kind knows
						expect(pet.joints[prim.name] ~= nil).toBeTruthy()
					end
				end
				for name in pet.joints do
					expect(bones[name]).toBe(true)
				end
				-- inside its box (a little over for the tail and the wings is fine)
				local lo, hi = Geometry.bounds(prims)
				local size = hi - lo
				expect(size.X <= pet.size.X + 0.3 and size.Y <= pet.size.Y + 0.3 and size.Z <= pet.size.Z + 0.3).toBeTruthy()
			end
		end
		for _, r in CrateData.Rarities do
			expect(rarities[r]).toBe(true)
		end
	end)

	it("says a line for every act in every voice, filled in", function()
		local rng = Rng.new(2)
		for _, pet in PetData.list do
			for _, act in pet.acts do
				for _, pers in Personalities.list do
					for _ = 1, 4 do
						local text = Pets.line(act, pers.id, "Biscuit", pet.id, rng)
						expect(plain(text)).toBeTruthy()
						expect(string.find(text, "Biscuit", 1, true) ~= nil).toBeTruthy()
					end
				end
			end
		end
		for _, pers in Personalities.list do
			local text = Pets.fetchLine(pers.id, "Biscuit", "cat", "an apple", rng)
			expect(plain(text)).toBeTruthy()
			expect(string.find(text, "an apple", 1, true) ~= nil).toBeTruthy()
		end
	end)

	it("cheers its owner up a little each night, more the rarer, and fetches now and then", function()
		local last = 0
		for _, r in CrateData.Rarities do
			expect(Tuning.Pets.Mood[r] >= last).toBeTruthy()
			last = Tuning.Pets.Mood[r]
			expect(Tuning.Pets.Fetch[r] > 0 and Tuning.Pets.Fetch[r] <= 0.5).toBeTruthy()
		end
		-- a little: never more than a good night's sleep in a nice room does
		expect(Tuning.Pets.Mood.legendary <= Tuning.Villagers.BedMoodPerNight).toBeTruthy()
		expect(Pets.nightMood("cat")).toBe(Tuning.Pets.Mood.common)
		expect(Pets.nightMood("dragon")).toBe(Tuning.Pets.Mood.legendary)
		expect(Pets.nightMood("nothing")).toBe(0)
		expect(Pets.fetchChance("dragon")).toBe(Tuning.Pets.Fetch.legendary)
	end)

	it("walks a leg in step on every screen, and stays on its land", function()
		local a, b = Vector3.new(0, 0, 0), Vector3.new(6, 0, 8)
		expect(Pets.legTime(a, b, 5)).toBeNear(2, 1e-9)
		local at, moving, gone = Pets.at(a, b, 100, 5, 101)
		expect(moving).toBe(true)
		expect((at - Vector3.new(3, 0, 4)).Magnitude).toBeNear(0, 1e-6)
		expect(gone).toBeNear(5, 1e-6)
		local done, still = Pets.at(a, b, 100, 5, 200)
		expect(still).toBe(false)
		expect(done).toBe(b)
		-- beside a villager, Gap short of them on the pet's side
		local by = Pets.besidePoint(Vector3.new(10, 0, 0), Vector3.new(0, 0, 0))
		expect(by.X).toBeNear(Tuning.Pets.Gap, 1e-6)
		-- a walk keeps inside the land's sides and back, and only just over its front
		local P = Tuning.Pets
		expect(Pets.stepFrom(Vector3.new(50, 0, 50), 0, 10, 0, 0, 100, 100) ~= nil).toBeTruthy()
		expect(Pets.stepFrom(Vector3.new(95, 0, 50), 0, 10, 0, 0, 100, 100)).toBe(nil)
		expect(Pets.stepFrom(Vector3.new(50, 0, 2), -math.pi / 2, P.Street + 3, 0, 0, 100, 100)).toBe(nil)
		expect(Pets.stepFrom(Vector3.new(50, 0, 2), -math.pi / 2, P.Street, 0, 0, 100, 100) ~= nil).toBeTruthy()
	end)
end)
