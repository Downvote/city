--!nocheck
-- The city: the starter town fits its land, levels and land go up in sensible steps, paydays pay
-- what Data/Jobs says, and the economy stays inside the bounds docs/GAME_DESIGN.md promises.

local Shared = "ReplicatedStorage.Shared."
local Tuning = require(Shared .. "Config.Tuning")
local Plan = require(Shared .. "Build.Plan")
local Catalog = require(Shared .. "Build.Catalog")
local City = require(Shared .. "Sim.City")
local Jobs = require(Shared .. "Data.Jobs")
local Schema = require(Shared .. "Sim.Schema")
local StarterHouse = require(Shared .. "Data.StarterHouse")
local Appearance = require(Shared .. "Avatar.Appearance")
local Rng = require(Shared .. "Util.Rng")

local function villager(p, i, pers)
	local input = Schema.cleanVillagerInput({ name = "V" .. i, pers = pers or "sunny", app = Appearance.default() })
	local v = Schema.newVillager("v" .. i, input, Rng.new(i))
	p.villagers[v.id] = v
	table.insert(p.order, v.id)
	return v
end

describe("City", function()
	it("starts with a valid town on the starting land, with a bed and a job", function()
		local plan = StarterHouse.plan()
		for kind in Plan.KindSet do
			for key, obj in plan[kind] do
				local ok, why = Plan.validate(plan, kind, obj, key)
				if not ok then
					error(kind .. " " .. key .. " (" .. tostring(obj.id) .. "): " .. tostring(why))
				end
			end
		end
		local p = Schema.newProfile()
		p.plan = plan
		expect(#City.workplaces(plan) >= 1).toBeTruthy()
		expect(City.freeWorkplace(p) ~= nil).toBeTruthy()
	end)

	it("has a workplace in the catalog for every job", function()
		for _, job in Jobs.list do
			local found = false
			for _, def in Catalog.workplaces() do
				if def.job == job.id then
					found = true
				end
			end
			if not found then
				error("no workplace for " .. job.id)
			end
		end
		for _, def in Catalog.workplaces() do
			expect(Jobs.get(def.job) ~= nil).toBeTruthy()
		end
	end)

	it("goes up a level with more people and more built", function()
		expect(City.level(0, 0)).toBe(1)
		local levels = Tuning.City.Levels
		for i = 2, #levels do
			expect(City.level(levels[i].Pop, levels[i].Value)).toBe(i)
			expect(City.level(levels[i].Pop - 1, levels[i].Value)).toBe(i - 1)
			expect(levels[i].Pop > levels[i - 1].Pop).toBeTruthy()
			expect(levels[i].Value > levels[i - 1].Value).toBeTruthy()
		end
		expect(levels[#levels].Pop <= Tuning.Villagers.Max).toBeTruthy()
	end)

	it("sells land in growing steps that fit the plot", function()
		local land = Tuning.City.Land
		expect(land[1].Price).toBe(0)
		for i = 2, #land do
			expect(land[i].Size > land[i - 1].Size).toBeTruthy()
			expect(land[i].Price > land[i - 1].Price).toBeTruthy()
			expect(land[i].Level <= #Tuning.City.Levels).toBeTruthy()
			expect((land[i].Size / Tuning.Plot.WallSnap) % 1).toBe(0)
		end
		expect(land[#land].Size <= Tuning.Plot.Size).toBeTruthy()
		-- land keeps its grid: the bounds land on wall grid points
		for _, l in land do
			local x1, _, x2 = Plan.boundsOf(l.Size)
			expect((x1 / Tuning.Plot.WallSnap) % 1).toBe(0)
			expect((x2 / Tuning.Plot.WallSnap) % 1).toBe(0)
		end
	end)

	it("won't sell land before the town is big enough", function()
		local p = Schema.newProfile()
		p.plan = StarterHouse.plan()
		p.coins = 1e6
		villager(p, 1)
		local land, why = City.canExpand(p)
		expect(land).toBe(nil)
		expect(type(why)).toBe("string")
		for i = 2, 3 do
			villager(p, i)
		end
		-- enough built for a village
		for k = 1, 12 do
			p.plan.items["x" .. k] = { id = "fountain", x = 60 + k * 6, y = 0, z = 90, r = 0, lv = 0 }
		end
		local stats = City.stats(p)
		expect(stats.level >= 2).toBeTruthy()
		expect(City.canExpand(p) ~= nil).toBeTruthy()
	end)

	it("pays workers, but not on a day off or while sick", function()
		local p = Schema.newProfile()
		p.plan = StarterHouse.plan()
		local a = villager(p, 1, "sunny")
		local b = villager(p, 2, "shy")
		a.job = City.freeWorkplace(p)
		local lines, total = City.payday(p, 10, 1000)
		expect(#lines).toBe(1)
		expect(total).toBe(Jobs.pay(City.jobOf(p, a.id).job, a.lv, a.mood, a.pers))
		a.dayOff = 10
		local _, off = City.payday(p, 10, 1000)
		expect(off).toBe(0)
		a.dayOff = nil
		a.sick = 2000
		local _, sick = City.payday(p, 10, 1000)
		expect(sick).toBe(0)
		local _ = b
	end)

	it("keeps the economy in its bounds", function()
		-- a day's pay at a middling mood is worth having but doesn't buy the town outright
		for _, job in Jobs.list do
			local pay = Jobs.pay(job, 1, Tuning.Villagers.StartMood, "none")
			expect(pay).toBeBetween(40, 220)
			local best = Jobs.pay(job, Tuning.Jobs.SkillCap, 100, job.likes[1])
			expect(best).toBeBetween(pay, 700)
		end
		-- the starting coins buy a bed and a workplace for the second villager
		local bed = Catalog.get("bed_single")
		local cheapestWork = math.huge
		for _, def in Catalog.workplaces() do
			cheapestWork = math.min(cheapestWork, def.price)
		end
		expect(bed.price + cheapestWork < Tuning.Economy.StartCoins).toBeTruthy()
		-- three workers save up for the first land in under three weeks of town days
		local job = Jobs.get("shopkeeper")
		local perDay = 3 * Jobs.pay(job, 3, 70, "none")
		local days = Tuning.City.Land[2].Price / perDay
		expect(days).toBeBetween(3, 21)
	end)
end)
