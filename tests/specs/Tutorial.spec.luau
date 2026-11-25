--!nocheck
-- The tutorial's steps (Sim/Tutorial). The user: "make the tutorial more visual and structured,
-- starting with creating a villager, then building a place for them to sleep, then a place to
-- work. the first time a craving pops up, guide the user how to do it." A step is done by what
-- is true of the town, in order; the server records only what the profile itself shows; Skip
-- ends it for good; an old save that already has a villager, a bed and a job starts at the
-- craving. And a new plot leaves the bed and the workbench for the player to put down
-- (Data/StarterHouse.newPlot), with the coins to do it.

local Shared = "ReplicatedStorage.Shared."
local Tuning = require(Shared .. "Config.Tuning")
local Plan = require(Shared .. "Build.Plan")
local Catalog = require(Shared .. "Build.Catalog")
local City = require(Shared .. "Sim.City")
local Life = require(Shared .. "Sim.Life")
local Schema = require(Shared .. "Sim.Schema")
local Tutorial = require(Shared .. "Sim.Tutorial")
local StarterHouse = require(Shared .. "Data.StarterHouse")
local Foods = require(Shared .. "Data.Foods")
local Appearance = require(Shared .. "Avatar.Appearance")
local Rng = require(Shared .. "Util.Rng")

-- A new player's profile on a new plot.
local function fresh()
	local p = Schema.newProfile()
	p.plan = StarterHouse.newPlot()
	return p
end

local function addVillager(p, i)
	local input = Schema.cleanVillagerInput({ name = "V" .. i, pers = "sunny", app = Appearance.default() })
	local v = Schema.newVillager("v" .. i, input, Rng.new(i))
	if #p.order == 0 then
		v.isYou = true
	end
	p.villagers[v.id] = v
	table.insert(p.order, v.id)
	return v
end

-- Puts a catalog piece on the plan, as Build mode would. Returns its key.
local function put(p, id, x, z)
	local key = "t" .. id
	p.plan.items[key] = { id = id, x = x or 200, y = 0, z = z or 150, r = 0, lv = 0 }
	return key
end

local function idsOf(plan)
	local out = {}
	for _, item in plan.items do
		out[item.id] = (out[item.id] or 0) + 1
	end
	return out
end

describe("Tutorial", function()
	it("has the four steps the user asked for, in their order", function()
		expect(Tutorial.Count).toBe(4)
		local ids = {}
		for _, s in Tutorial.Steps do
			table.insert(ids, s.id)
		end
		expect(table.concat(ids, " ")).toBe("villager bed work craving")
		-- the two built steps name a real bed and a real workplace
		local bed = Catalog.get(Tutorial.Steps[2].piece)
		local bench = Catalog.get(Tutorial.Steps[3].piece)
		expect(bed ~= nil and Catalog.hasTag(bed, "bed")).toBeTruthy()
		expect(bench ~= nil and bench.job ~= nil).toBeTruthy()
		-- and they are the two pieces a new plot leaves out
		expect(table.concat(StarterHouse.Held, " ")).toBe(bed.id .. " " .. bench.id)
	end)

	it("leaves the new plot's bedroom without its bed and the workshop without its bench", function()
		local whole = StarterHouse.plan()
		local plot = StarterHouse.newPlot()
		local all, now = idsOf(whole), idsOf(plot)
		-- the furnished version is still there for the specs and previews that want it
		expect(all.bed_single).toBe(1)
		expect(#City.workplaces(whole)).toBe(1)
		-- the new plot has no bed and no workplace, and everything else
		for _, item in plot.items do
			expect(item.id:find("bed")).toBe(nil)
			local def = Catalog.get(item.id)
			expect(def ~= nil and Catalog.hasTag(def, "bed")).toBe(false)
		end
		expect(#City.workplaces(plot)).toBe(0)
		for id, n in all do
			local held = table.find(StarterHouse.Held, id) ~= nil
			expect(now[id] or 0).toBe(if held then 0 else n)
		end
		for _, kind in { "walls", "floors", "roofs" } do
			local a, b = 0, 0
			for _ in whole[kind] do
				a += 1
			end
			for _ in plot[kind] do
				b += 1
			end
			expect(b).toBe(a)
		end
		-- every piece of it is valid and still a gift, counted at the old cottage's worth
		for kind in Plan.KindSet do
			for key, obj in plot[kind] do
				local ok, why = Plan.validate(plot, kind, obj, key)
				if not ok then
					error(kind .. " " .. key .. ": " .. tostring(why))
				end
				expect(Plan.price(kind, obj)).toBe(0)
			end
		end
		expect(City.worth(plot)).toBe(Tuning.City.StarterWorth)
	end)

	it("gives a new player the coins for the single bed and the bench, with plenty left", function()
		local p = fresh()
		local bed = Plan.cost("items", { id = Tutorial.Steps[2].piece })
		local bench = Plan.cost("items", { id = Tutorial.Steps[3].piece })
		expect(bed > 0 and bench > 0).toBeTruthy()
		expect(p.coins).toBe(Tuning.Economy.StartCoins)
		-- both, and still most of what they started with for building
		expect(p.coins - bed - bench >= p.coins * 0.75).toBeTruthy()
	end)

	it("counts each step from the town itself, in order", function()
		local p = fresh()
		expect(Tutorial.reached(p, 0)).toBe(0)
		expect(Tutorial.current(p, 0)).toBe(1)
		-- 1: somebody lives here
		local v = addVillager(p, 1)
		expect(Tutorial.reached(p, 0)).toBe(1)
		-- a job before a bed is not the bed: the steps go in order
		local benchKey = put(p, "work_builder", 220, 60)
		v.job = City.freeWorkplace(p)
		expect(v.job).toBe(benchKey)
		expect(Tutorial.met(p, 3)).toBe(true)
		expect(Tutorial.reached(p, 0)).toBe(1)
		-- 2: a bed is theirs only when it is a bed and still on the plot
		v.bed = benchKey
		expect(Tutorial.met(p, 2)).toBe(false)
		v.bed = "gone"
		expect(Tutorial.met(p, 2)).toBe(false)
		local bedKey = put(p, "bed_single", 200, 120)
		v.bed = bedKey
		expect(Tutorial.met(p, 2)).toBe(true)
		-- 3 was already true, so both count
		expect(Tutorial.reached(p, 0)).toBe(3)
		expect(Tutorial.current(p, 0)).toBe(4)
		-- the workplace gone, the job is no job
		p.plan.items[benchKey] = nil
		expect(Tutorial.met(p, 3)).toBe(false)
		expect(Tutorial.reached(p, 0)).toBe(2)
		-- but a step once recorded stays done
		expect(Tutorial.reached(p, 3)).toBe(3)
		-- 4: a craving bought for somebody
		expect(Tutorial.met(p, 4)).toBe(false)
		p.stats.cravings = 1
		expect(Tutorial.reached(p, 3)).toBe(4)
		expect(Tutorial.current(p, 3)).toBe(nil)
		expect(Tutorial.finished(4)).toBe(true)
	end)

	it("lets the server record only what the profile shows", function()
		local p = fresh()
		-- the client says it is at the bed: nobody lives here yet
		local ok, now = Tutorial.advance(p, 2)
		expect(ok).toBe(false)
		expect(now).toBe(0)
		expect(p.tutorial).toBe(0)
		local v = addVillager(p, 1)
		ok, now = Tutorial.advance(p, 2)
		expect(ok).toBe(false)
		expect(p.tutorial).toBe(1) -- (what it does show is kept)
		v.bed = put(p, "bed_single")
		ok = Tutorial.advance(p, 2)
		expect(ok).toBe(true)
		expect(p.tutorial).toBe(2)
		-- nothing a client sends moves it on its own
		for _, junk in { "3", 2.5, 0 / 0, math.huge, -1, 0, 5, 98, true, {} } do
			local was = p.tutorial
			expect((Tutorial.advance(p, junk))).toBe(false)
			expect(p.tutorial).toBe(was)
		end
		-- a step already done is still done
		expect((Tutorial.advance(p, 1))).toBe(true)
		expect(p.tutorial).toBe(2)
	end)

	it("ends for good when skipped", function()
		local p = fresh()
		local ok, now = Tutorial.advance(p, Tutorial.Skipped)
		expect(ok).toBe(true)
		expect(now).toBe(Tutorial.Skipped)
		expect(Tutorial.finished(p.tutorial)).toBe(true)
		expect(Tutorial.current(p, p.tutorial)).toBe(nil)
		-- the town catching up doesn't bring it back
		addVillager(p, 1).bed = put(p, "bed_single")
		Tutorial.advance(p, 1)
		Tutorial.catchUp(p)
		expect(p.tutorial).toBe(Tutorial.Skipped)
		-- and a broken saved value reads as the start
		expect(Tutorial.progress("lots")).toBe(0)
		expect(Tutorial.progress(-3)).toBe(0)
		expect(Tutorial.progress(7)).toBe(Tutorial.Count)
		expect(Tutorial.progress(0 / 0)).toBe(0)
	end)

	it("starts an old save that has a villager, a bed and a job at the craving", function()
		-- a town from before the tutorial: the whole cottage (bed and bench), a villager in it,
		-- nothing recorded and no count of cravings
		local old = Schema.newProfile()
		old.plan = StarterHouse.plan()
		local v = addVillager(old, 1)
		for key, item in old.plan.items do
			if item.id == "bed_single" then
				v.bed = key
			end
		end
		v.job = City.freeWorkplace(old)
		old.tutorial = nil
		old.stats.cravings = nil
		local p = Schema.migrate(old)
		expect(p.stats.cravings).toBe(0)
		expect(Tutorial.catchUp(p)).toBe(3)
		expect(Tutorial.current(p, p.tutorial)).toBe(4)
		-- an old save with nobody in it starts at the beginning
		local empty = Schema.migrate({ coins = 50, plan = StarterHouse.plan() })
		expect(Tutorial.catchUp(empty)).toBe(0)
		-- a new player too
		expect(Tutorial.catchUp(fresh())).toBe(0)
	end)

	it("counts a bought craving, and no other wish, for the last step", function()
		local p = fresh()
		local you = addVillager(p, 1)
		local v = addVillager(p, 2)
		local rng = Rng.new(5)
		-- a wish to meet somebody, granted: not a craving
		v.wish = { kind = "friend", arg = you.id, untilT = 1e9 }
		expect((Life.grantWish(p, v.id, "friend", you.id, rng))).toBe(true)
		expect(p.stats.cravings or 0).toBe(0)
		-- a craving bought: it counts
		v.wish = { kind = "food", arg = Foods.list[1].id, untilT = 1e9 }
		p.coins = 1000
		local ok = Life.buyWish(p, v.id, rng)
		expect(ok).toBe(true)
		expect(p.stats.cravings).toBe(1)
		expect(Tutorial.met(p, 4)).toBe(true)
		-- one refused (no coins) doesn't
		v.wish = { kind = "food", arg = Foods.list[1].id, untilT = 1e9 }
		p.coins = 0
		expect((Life.buyWish(p, v.id, rng))).toBe(false)
		expect(p.stats.cravings).toBe(1)
	end)
end)
