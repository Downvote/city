--!nocheck
-- The city: the starter town fits its land, levels and land go up in sensible steps, paydays pay
-- what Data/Jobs says, and the economy stays inside the bounds docs/GAME_DESIGN.md promises.

local Shared = "ReplicatedStorage.Shared."
local Tuning = require(Shared .. "Config.Tuning")
local Plan = require(Shared .. "Build.Plan")
local Catalog = require(Shared .. "Build.Catalog")
local Builder = require(Shared .. "Build.Builder")
local Geometry = require(Shared .. "Build.Geometry")
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
	it("starts with one valid house and its workshop, with a bed, in the middle of the starting land", function()
		-- the user: "players should spawn at their plot, which starts out with a single house in
		-- the middle", and later "improve the starting house detail by alot, and add a workspace
		-- next to it"
		local plan = StarterHouse.plan()
		for kind in Plan.KindSet do
			for key, obj in plan[kind] do
				local ok, why = Plan.validate(plan, kind, obj, key)
				if not ok then
					error(kind .. " " .. key .. " (" .. tostring(obj.id) .. "): " .. tostring(why))
				end
			end
		end
		local x1, z1, x2, z2 = Plan.bounds(plan)
		local lo, hi = Vector3.new(1e9, 0, 1e9), Vector3.new(-1e9, 0, -1e9)
		local walls = 0
		for _, w in plan.walls do
			walls += 1
			-- the house's walls and the workshop's: nothing is drawn with the fence tools
			expect(w.style).toBe("wall")
			for _, p in { Vector3.new(w.x1, 0, w.z1), Vector3.new(w.x2, 0, w.z2) } do
				lo, hi = lo:Min(p), hi:Max(p)
			end
		end
		expect(walls >= 4).toBeTruthy()
		-- the middle of the two buildings is the land's middle
		expect(math.abs((lo.X + hi.X) / 2 - (x1 + x2) / 2) < 0.01).toBeTruthy()
		expect(math.abs((lo.Z + hi.Z) / 2 - (z1 + z2) / 2) < 0.01).toBeTruthy()
		-- and everything it starts with keeps to them (a bed among them): nothing further out
		-- than the front garden, nothing beside or behind the two buildings
		local beds = 0
		for _, item in plan.items do
			if item.id:find("bed") then
				beds += 1
			end
			if not item.wall then
				expect(item.x >= lo.X and item.x <= hi.X + 0.01).toBeTruthy()
				expect(item.z >= lo.Z - 6.5 and item.z <= hi.Z + 0.01).toBeTruthy() -- the fence and the porch
			end
		end
		-- one bed: an id with "bed" in it is how the other specs find it, so nothing else may
		expect(beds).toBe(1)
		-- and it leaves most of the land empty, the street side and the back both
		expect((hi.X - lo.X) * (hi.Z - lo.Z + 6.5) < 0.2 * (x2 - x1) * (z2 - z1)).toBeTruthy()
		expect(lo.Z - 6.5 - z1 >= 24).toBeTruthy()
		expect(z2 - hi.Z >= 24).toBeTruthy()
	end)

	it("starts with one workplace, in the workshop beside the house, that the first villager takes", function()
		-- the user: "add a workspace next to it"
		local p = Schema.newProfile()
		p.plan = StarterHouse.plan()
		local work = City.workplaces(p.plan)
		expect(#work).toBe(1)
		local w = work[1]
		expect(Jobs.get(w.def.job) ~= nil).toBeTruthy()
		local bench = p.plan.items[w.key]
		-- it stands on the ground floor, on a floor of its own, under a roof of its own
		expect(bench.lv).toBe(0)
		local function over(list)
			for _, f in list do
				if f.lv == 0 and bench.x > f.x1 and bench.x < f.x2 and bench.z > f.z1 and bench.z < f.z2 then
					return f
				end
			end
			return nil
		end
		local shopRoof = over(p.plan.roofs)
		expect(over(p.plan.floors) ~= nil).toBeTruthy()
		expect(shopRoof ~= nil).toBeTruthy()
		-- beside the house, not in it: the bed is under another roof, a short walk away
		local bed
		for _, item in p.plan.items do
			if item.id:find("bed") then
				bed = item
			end
		end
		expect(bed.x > shopRoof.x1 and bed.x < shopRoof.x2 and bed.z > shopRoof.z1 and bed.z < shopRoof.z2).toBe(false)
		local walk = math.sqrt((bed.x - bench.x) ^ 2 + (bed.z - bench.z) ^ 2)
		expect(walk).toBeBetween(12, 48)
		-- the worker's spot and the spot a customer stands on are both clear of every wall
		local frame = Plan.itemFrame(p.plan, bench)
		local spot = w.def.workSpot
		local customer = Vector3.new(spot.X, 0, if spot.Z < 0 then w.def.size.Z / 2 + 2 else -(w.def.size.Z / 2 + 2))
		for _, at in { frame * spot, frame * customer } do
			for _, wall in p.plan.walls do
				local a, b = Vector3.new(wall.x1, 0, wall.z1), Vector3.new(wall.x2, 0, wall.z2)
				local t = math.clamp((Vector3.new(at.X, 0, at.Z) - a):Dot(b - a) / (b - a):Dot(b - a), 0, 1)
				local gap = (Vector3.new(at.X, 0, at.Z) - (a + (b - a) * t)).Magnitude
				expect(gap > 1.3).toBeTruthy() -- a villager is this wide (Npc's AgentRadius)
			end
		end
		-- the first villager made takes it (Services/Villagers gives a new villager the free
		-- workplace), so a new town earns one builder's pay a day from the start
		local v = villager(p, 1, "sunny")
		v.job = City.freeWorkplace(p)
		expect(v.job).toBe(w.key)
		expect(City.freeWorkplace(p)).toBe(nil)
		expect(v.mood).toBe(Tuning.Villagers.StartMood)
		local _, total = City.payday(p, 1, 0)
		expect(total).toBe(Jobs.pay(w.job, 1, Tuning.Villagers.StartMood, v.pers))
		-- which is a day's pay inside the bounds below, and no way to the first land on its own
		-- in under three weeks of town days
		expect(total).toBeBetween(40, 220)
		expect(Tuning.City.Land[2].Price / total > 21).toBeTruthy()
	end)

	it("lets a villager walk from the street into every room, to the bed and to the workbench", function()
		-- Nothing here runs Roblox's pathfinding, so this is the same question on a grid: a disc
		-- as wide as a villager (Npc's AgentRadius), everything solid between knee and head
		-- height in its way, door leaves and the gate open to it as they are in the game.
		local plan = StarterHouse.plan()
		local RADIUS, STEP = 1.3, 0.5
		local x1, z1, x2, z2 = Plan.bounds(plan)
		local nx, nz = math.floor((x2 - x1) / STEP), math.floor((z2 - z1) / STEP)
		local blocked = {}
		for _, kind in Plan.Kinds do
			for key in plan[kind] do
				for _, p in Geometry.flatten(Builder.primsFor(plan, kind, key) or {}) do
					local lo, hi = Geometry.bounds({ p })
					if p.collide ~= false and p.role ~= "door" and hi.Y > 1.45 and lo.Y < 5.2 then
						local upright = p.cf.UpVector.Y > 0.999
						for i = math.floor((lo.X - RADIUS - x1) / STEP), math.ceil((hi.X + RADIUS - x1) / STEP) do
							for k = math.floor((lo.Z - RADIUS - z1) / STEP), math.ceil((hi.Z + RADIUS - z1) / STEP) do
								local x, z = x1 + i * STEP, z1 + k * STEP
								local dx, dz
								if upright then
									-- a box standing square, however it is turned: measured in its own frame
									local l = p.cf:PointToObjectSpace(Vector3.new(x, p.cf.Position.Y, z))
									dx = math.max(math.abs(l.X) - p.size.X / 2, 0)
									dz = math.max(math.abs(l.Z) - p.size.Z / 2, 0)
								else
									dx = math.max(lo.X - x, x - hi.X, 0)
									dz = math.max(lo.Z - z, z - hi.Z, 0)
								end
								if dx * dx + dz * dz < RADIUS * RADIUS then
									blocked[i * 1000 + k] = true
								end
							end
						end
					end
				end
			end
		end
		-- flood out from the street, where villagers and players arrive, in the middle of the land
		local reached = {}
		local start = math.floor(((x1 + x2) / 2 - x1) / STEP) * 1000 + 2
		expect(blocked[start]).toBe(nil)
		reached[start] = true
		local queue, head = { start }, 1
		while head <= #queue do
			local c = queue[head]
			head += 1
			local i, k = math.floor(c / 1000), c % 1000
			for _, d in { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } } do
				local a, b = i + d[1], k + d[2]
				local n = a * 1000 + b
				if a >= 0 and a <= nx and b >= 0 and b <= nz and not blocked[n] and not reached[n] then
					reached[n] = true
					table.insert(queue, n)
				end
			end
		end
		-- how far the nearest spot they can stand on is from a point
		local function near(x: number, z: number): number
			local best = math.huge
			local ci, ck = math.floor((x - x1) / STEP + 0.5), math.floor((z - z1) / STEP + 0.5)
			for i = ci - 6, ci + 6 do
				for k = ck - 6, ck + 6 do
					if reached[i * 1000 + k] then
						best = math.min(best, math.sqrt((x1 + i * STEP - x) ^ 2 + (z1 + k * STEP - z) ^ 2))
					end
				end
			end
			return best
		end
		-- every floor they wander onto (Services/Villagers picks floors at least 4 by 4): the
		-- rooms, the porch, the workshop and its yard, the path
		local floors = 0
		for _, f in plan.floors do
			if f.lv == 0 and f.x2 - f.x1 >= 4 and f.z2 - f.z1 >= 4 then
				floors += 1
				local inside = false
				for x = f.x1 + 1.5, f.x2 - 1.5, STEP do
					for z = f.z1 + 1.5, f.z2 - 1.5, STEP do
						if near(x, z) < 0.01 then
							inside = true
						end
					end
				end
				if not inside then
					error(string.format("nobody can walk onto the floor at %d, %d", f.x1, f.z1))
				end
			end
		end
		expect(floors >= 6).toBeTruthy()
		-- the bed: beside it or at its foot, the three spots a villager tries at bedtime
		for _, item in plan.items do
			local def = Catalog.get(item.id)
			if Catalog.hasTag(def, "bed") then
				local frame = Plan.itemFrame(plan, item)
				for _, p in Catalog.prims(def) do
					if p.role == "bed" then
						local spot = frame * p.cf
						local best = math.huge
						for _, side in { spot.RightVector * 2.6, -spot.RightVector * 2.6, spot.LookVector * -3.4 } do
							local at = spot.Position + side
							best = math.min(best, near(at.X, at.Z))
						end
						expect(best < 1.25).toBeTruthy()
					end
				end
			end
		end
		-- the workshop: where the worker stands and where whoever drops by stands
		local w = City.workplaces(plan)[1]
		local frame = Plan.itemFrame(plan, plan.items[w.key])
		local spot = w.def.workSpot
		local customer = Vector3.new(spot.X, 0, if spot.Z < 0 then w.def.size.Z / 2 + 2 else -(w.def.size.Z / 2 + 2))
		for _, at in { frame * spot, frame * customer } do
			if near(at.X, at.Z) >= 1.25 then
				error(
					string.format(
						"nobody can stand at %.1f, %.1f by the workbench (nearest %.2f)",
						at.X,
						at.Z,
						near(at.X, at.Z)
					)
				)
			end
		end
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

	it("doesn't refill food that ran out when a save loads", function()
		local p = Schema.newProfile()
		p.inv.food = {}
		p.settings = nil
		local loaded = Schema.migrate(p)
		expect(next(loaded.inv.food)).toBe(nil)
		expect(loaded.settings ~= nil).toBeTruthy()
		expect(loaded.settings.sfx).toBe(Schema.Settings.sfx)
	end)

	it("pays workers, but not on a day off or while sick", function()
		local p = Schema.newProfile()
		p.plan = StarterHouse.plan()
		-- a market stall by the street as well as the workshop the plot comes with: a job is only
		-- paid once somebody has it
		p.plan.items.stall = { id = "work_market", x = 130, y = 0, z = 12, r = 180, lv = 0 }
		local a = villager(p, 1, "sunny")
		local b = villager(p, 2, "shy")
		a.job = City.freeWorkplace(p)
		expect(a.job ~= nil).toBeTruthy()
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
