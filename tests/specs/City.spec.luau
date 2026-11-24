--!nocheck
-- The city: the starter town fits its land, levels and land go up in sensible steps, a day's work
-- pays what Data/Jobs says, and the economy stays inside the bounds docs/GAME_DESIGN.md promises.
-- The user: "it seems like money gain from work is too little. balanced it such that progression
-- is much more based on villagers working". So the bounds here are about work: what a day's pay
-- buys, wages against everything else a keen player can collect in a day (played out below over
-- seeded town days), and what each level of the town takes in workers and in days of their pay.
-- Then: "could you make working give much more coins, and make buildings cheaper?" (wages three
-- times what they were, building half) and "make it such that villagers earn coins as they work,
-- not after every day" (Sim/City.earn; the Routine spec holds that a day at work comes to about a
-- day's pay, so a day here is paid that).

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
local Life = require(Shared .. "Sim.Life")
local Talk = require(Shared .. "Sim.Talk")
local EventEngine = require(Shared .. "Sim.EventEngine")
local Personalities = require(Shared .. "Data.Personalities")
local Foods = require(Shared .. "Data.Foods")
local Presets = require(Shared .. "Data.Presets")

local START = Tuning.Villagers.StartMood

-- A day's pay at the mood and skill a villager starts with, in a job that is nothing special to them.
local function startPay(job)
	return Jobs.pay(job, 1, START, "none")
end

local function meanStartPay()
	local sum = 0
	for _, job in Jobs.list do
		sum += startPay(job)
	end
	return sum / #Jobs.list
end

-- A town for the days played out below: `pop` villagers with a bed each, the first `workers` of
-- them in a job (the starter's builder, then one workplace of each kind in turn).
local WORK = {
	"work_market",
	"work_cafe",
	"work_flowers",
	"work_bakery",
	"work_post",
	"work_icecream",
	"work_stage",
	"work_library",
	"work_easel",
	"work_school",
	"work_clinic",
}
local function workingTown(pop, workers, seed)
	local rng = Rng.new(seed)
	local p = Schema.newProfile()
	p.plan = StarterHouse.plan()
	local keys = { City.workplaces(p.plan)[1].key }
	for i = 2, workers do
		p.plan.items["w" .. i] = { id = WORK[(i - 2) % #WORK + 1], x = 60 + i * 5, y = 0, z = 20, r = 0, lv = 0 }
		table.insert(keys, "w" .. i)
	end
	for i = 1, pop do
		p.plan.items["b" .. i] = { id = "bed_single", x = 60 + i * 5, y = 0, z = 150, r = 0, lv = 0 }
		local input = Schema.cleanVillagerInput({
			name = "V" .. i,
			pers = Personalities.list[(i - 1) % #Personalities.list + 1].id,
			app = Appearance.default(),
			bday = { s = rng:int(1, 4), d = rng:int(1, Schema.DaysPerSeason) },
		})
		local v = Schema.newVillager("v" .. i, input, rng)
		v.bed = "b" .. i
		v.job = keys[i]
		v.isYou = i == 1 or nil
		p.villagers[v.id] = v
		table.insert(p.order, v.id)
	end
	return p, rng
end

-- Plays `days` town days the way the server does (Services/Villagers and Services/Events), for
-- the keenest player there could be: every wish answered within the hour (a craving bought),
-- three chats a day with everyone, the generous answer to every event, every room request met
-- and paid, and the coins taken at every thank you. Returns what came in, by source.
local function playDays(p, rng, days)
	local got = { wages = 0, events = 0, requests = 0, wishes = 0, thanks = 0, cravings = 0 }
	local hourLength = Tuning.Day.Length / 24
	local now = 100000
	local nextEvent = now + Tuning.Events.FirstDelay
	local recent = {}
	local weathers = { "clear", "clear", "clear", "clear", "clear", "clear", "clear", "rain", "rain", "storm" }
	for day = 1, days do
		local weather = rng:pick(weathers)
		for step = 0, 23 do
			local hour = (Tuning.Day.StartClock + step) % 24
			while nextEvent < now + hourLength do
				local ctx = EventEngine.context(p, {
					now = nextEvent,
					hour = hour + 0.5,
					season = math.floor((day - 1) / Schema.DaysPerSeason) % #Schema.Seasons + 1,
					dayOfSeason = (day - 1) % Schema.DaysPerSeason + 1,
					day = day,
					weather = weather,
					rng = rng,
					present = table.clone(p.order),
					freeSlots = 0,
					friends = {},
				})
				p.calendarDay = day
				local ev = EventEngine.pick(ctx, recent)
				if ev then
					local effects = ev.scene.effects or {}
					if ev.scene.choices then
						local _, c = EventEngine.choice(ev.scene, 1, p.coins)
						effects = c.effects or {}
					end
					for _, e in effects do
						if e.t == "coins" and e.d > 0 then
							got.events += e.d
						elseif e.t == "request" then
							got.requests += Tuning.Rewards.RequestCoins
						end
					end
					EventEngine.apply(p, ev, effects, nextEvent)
					p.requests = {}
					table.insert(recent, 1, ev.id)
					while #recent > Tuning.Events.RecentMemory do
						table.remove(recent)
					end
				end
				nextEvent += rng:int(Tuning.Events.MinGap, Tuning.Events.MaxGap)
			end
			now += hourLength
			Life.fadeWishes(p, now)
			for _, vid in p.order do
				Life.maybeWish(p, vid, rng, now)
			end
			for _, vid in p.order do
				local w = p.villagers[vid].wish
				if w and w.kind == "food" then
					local ok, price = Life.buyWish(p, vid, rng)
					got.cravings += if ok then price else 0
				elseif w and w.kind ~= "cheer" then
					local _, coins = Life.grantWish(p, vid, w.kind, w.arg, rng)
					got.wishes += coins
				end
			end
			if hour == Tuning.Day.WorkEnd then
				-- what the day at work came to (earned through the day; summed here at five)
				local lines, total = City.wages(p, day, now)
				got.wages += total
				for _, l in lines do
					EventEngine.addXp(p.villagers[l.vid], Tuning.Jobs.XpPerDay)
				end
			end
		end
		for _, vid in p.order do
			for _ = 1, Tuning.Talk.ChatsPerDay do
				got.wishes += Talk.chat(p, vid, day, rng).coins
			end
		end
		while #p.offers > 0 do
			got.thanks += p.offers[1].options[1].n
			Life.claimReward(p, 1, rng)
		end
		for _, v in p.villagers do
			v.mood = math.clamp(v.mood + Tuning.Villagers.BedMoodPerNight, 0, Tuning.Villagers.MoodMax)
		end
	end
	got.other = got.events + got.requests + got.wishes + got.thanks
	return got
end

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
		local _, total = City.wages(p, 1, 0)
		expect(total).toBe(Jobs.pay(w.job, 1, Tuning.Villagers.StartMood, v.pers))
		-- which is a day's pay inside the bounds below: one wage gets a new player going (a
		-- ready-made cottage inside two days) and is still no quick way to the first land
		expect(total).toBeBetween(900, 2100)
		expect(Tuning.City.Land[2].Price / total).toBeBetween(2, 5)
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

	it("goes up a level with more people, more of them in work and more built", function()
		expect(City.level(0, 0)).toBe(1)
		expect(City.level(0, 0, 0)).toBe(1)
		local levels = Tuning.City.Levels
		expect(levels[1].Workers).toBe(0)
		for i = 2, #levels do
			local lv = levels[i]
			expect(City.level(lv.Pop, lv.Value)).toBe(i)
			expect(City.level(lv.Pop - 1, lv.Value)).toBe(i - 1)
			expect(lv.Pop > levels[i - 1].Pop).toBeTruthy()
			expect(lv.Value > levels[i - 1].Value).toBeTruthy()
			-- a level asks for villagers in work too: all three, and one short of any of them
			-- is the level below
			expect(City.level(lv.Pop, lv.Value, lv.Workers)).toBe(i)
			expect(City.level(lv.Pop, lv.Value, lv.Workers - 1)).toBe(i - 1)
			expect(City.level(lv.Pop, lv.Value - 1, lv.Workers)).toBe(i - 1)
			expect(City.level(lv.Pop - 1, lv.Value, lv.Workers)).toBe(i - 1)
			expect(lv.Workers > levels[i - 1].Workers).toBeTruthy()
			-- never more workers than villagers, and most of the town at work
			expect(lv.Workers <= lv.Pop).toBeTruthy()
			expect(lv.Workers * 2 >= lv.Pop).toBeTruthy()
		end
		expect(levels[#levels].Pop <= Tuning.Villagers.Max).toBeTruthy()
		-- a full town with nothing built or nobody working is still a hamlet
		expect(City.level(Tuning.Villagers.Max, 1e9, 0)).toBe(1)
	end)

	it("counts who has a job for the city hall, and a town of idlers stays small", function()
		local p = Schema.newProfile()
		p.plan = StarterHouse.plan()
		p.plan.items.stall = { id = "work_market", x = 130, y = 0, z = 12, r = 180, lv = 0 }
		for k = 1, 12 do
			p.plan.items["x" .. k] = { id = "fountain", x = 60 + k * 6, y = 0, z = 90, r = 0, lv = 0 }
		end
		local village = Tuning.City.Levels[2]
		for i = 1, village.Pop do
			villager(p, i)
		end
		local stats = City.stats(p)
		expect(stats.value >= village.Value).toBeTruthy()
		expect(stats.employed).toBe(0)
		expect(City.workers(p)).toBe(0)
		expect(stats.level).toBe(1)
		-- the next level says what it asks for, workers among it
		expect(stats.nextLevel.Workers).toBe(village.Workers)
		expect(stats.nextLevel.Pop).toBe(village.Pop)
		-- one in work is not enough for a village; two are
		p.villagers.v1.job = City.freeWorkplace(p)
		expect(City.stats(p).employed).toBe(1)
		expect(City.stats(p).level).toBe(1)
		p.villagers.v2.job = City.freeWorkplace(p)
		expect(City.stats(p).employed).toBe(2)
		expect(City.workers(p)).toBe(2)
		expect(City.stats(p).level).toBe(2)
		-- a job at a workplace that has been sold is no job
		p.plan.items.stall = nil
		expect(City.stats(p).employed).toBe(1)
		expect(City.stats(p).level).toBe(1)
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
		-- and still no land: a village needs two of them in work
		expect(City.canExpand(p)).toBe(nil)
		p.plan.items.stall = { id = "work_market", x = 130, y = 0, z = 12, r = 180, lv = 0 }
		p.villagers.v1.job = City.freeWorkplace(p)
		p.villagers.v2.job = City.freeWorkplace(p)
		local stats = City.stats(p)
		expect(stats.level >= 2).toBeTruthy()
		expect(City.canExpand(p) ~= nil).toBeTruthy()
	end)

	it("loads an old save without its bag of food, and fills in what is missing", function()
		-- the shop, the food and feeding are gone: a save from before still loads, and the bag
		-- and what it knew of each villager's tastes are dropped
		local p = Schema.newProfile()
		expect(p.inv).toBe(nil)
		p.inv = { food = { apple = 3, bread = 2 }, items = { cake = 1, medicine = 2 } }
		p.stats.fed = 14
		p.settings = nil
		local v = villager(p, 1)
		v.hate, v.known, v.feedDay, v.feeds = "pickles", { apple = "love" }, 4, 2
		local fav = v.fav
		local loaded = Schema.migrate(p)
		expect(loaded.inv).toBe(nil)
		expect(loaded.stats.fed).toBe(nil)
		expect(loaded.settings ~= nil).toBeTruthy()
		expect(loaded.settings.sfx).toBe(Schema.Settings.sfx)
		local lv = loaded.villagers.v1
		expect(lv.hate).toBe(nil)
		expect(lv.known).toBe(nil)
		expect(lv.feedDay).toBe(nil)
		expect(lv.feeds).toBe(nil)
		expect(lv.fav).toBe(fav)
		-- a favourite that is no food any more becomes one that is
		lv.fav = "nonsense"
		expect(Foods.get(Schema.migrate(loaded).villagers.v1.fav) ~= nil).toBeTruthy()
		-- a new villager has a favourite and nothing they can't stand
		expect(Foods.get(villager(Schema.newProfile(), 2).fav) ~= nil).toBeTruthy()
		expect(villager(Schema.newProfile(), 3).hate).toBe(nil)
	end)

	it("pays workers a day's wage, but not on a day off or while sick", function()
		local p = Schema.newProfile()
		p.plan = StarterHouse.plan()
		-- a market stall by the street as well as the workshop the plot comes with: a job is only
		-- paid once somebody has it
		p.plan.items.stall = { id = "work_market", x = 130, y = 0, z = 12, r = 180, lv = 0 }
		local a = villager(p, 1, "sunny")
		local b = villager(p, 2, "shy")
		a.job = City.freeWorkplace(p)
		expect(a.job ~= nil).toBeTruthy()
		local lines, total = City.wages(p, 10, 1000)
		expect(#lines).toBe(1)
		expect(total).toBe(Jobs.pay(City.jobOf(p, a.id).job, a.lv, a.mood, a.pers))
		expect(City.dayPay(p, a.id, 10, 1000)).toBe(total)
		expect(City.dayPay(p, b.id, 10, 1000)).toBe(0)
		expect(City.rate(p, a.id, 10, 1000)).toBeNear(total / City.workSeconds(), 1e-9)
		a.dayOff = 10
		local _, off = City.wages(p, 10, 1000)
		expect(off).toBe(0)
		expect(City.rate(p, a.id, 10, 1000)).toBe(0)
		a.dayOff = nil
		a.sick = 2000
		local _, sick = City.wages(p, 10, 1000)
		expect(sick).toBe(0)
		expect(City.rate(p, a.id, 10, 1000)).toBe(0)
		local _ = b
	end)

	it("pays more for a better mood, more skill and work that suits them", function()
		for _, job in Jobs.list do
			local base = Jobs.pay(job, 1, 50, "none")
			expect(base).toBe(job.income)
			-- mood: half at rock bottom, half as much again when delighted
			expect(Jobs.pay(job, 1, 0, "none")).toBeNear(job.income * 0.5, 0.51)
			expect(Jobs.pay(job, 1, 100, "none")).toBeNear(job.income * 1.5, 0.51)
			-- skill: every level is worth a rise, and ten of them at least half as much again
			local last = base
			for skill = 2, Tuning.Jobs.SkillCap do
				local pay = Jobs.pay(job, skill, 50, "none")
				expect(pay > last).toBeTruthy()
				last = pay
			end
			expect(Jobs.pay(job, 11, 50, "none") >= base * 1.5).toBeTruthy()
			expect(Jobs.pay(job, 1, 50, job.likes[1]) > base).toBeTruthy()
		end
		-- a day's work teaches enough that skill moves in the first days: a level inside two
		-- days, the next inside a week
		expect(Jobs.xpToNext(1) / Tuning.Jobs.XpPerDay <= 2).toBeTruthy()
		expect((Jobs.xpToNext(1) + Jobs.xpToNext(2)) / Tuning.Jobs.XpPerDay <= 7).toBeTruthy()
		local v = { name = "Test", lv = 1, xp = 0 }
		expect(City.addSkill(v, Jobs.xpToNext(1))).toBe(1)
		expect(v.lv).toBe(2)
		expect(v.xp).toBe(0)
		expect(City.addSkill(v, 1e9)).toBe(Tuning.Jobs.SkillCap - 2)
		expect(v.lv).toBe(Tuning.Jobs.SkillCap)
	end)

	it("keeps the economy in its bounds", function()
		-- a day's pay at the mood and skill a villager starts with buys something real (a bed and
		-- a workplace many times over, most of a ready-made house) but not the town, and the best
		-- there is stays in sight of it
		for _, job in Jobs.list do
			local pay = startPay(job)
			expect(pay).toBeBetween(900, 2100)
			local best = Jobs.pay(job, Tuning.Jobs.SkillCap, 100, job.likes[1])
			expect(best).toBeBetween(pay, 9000)
		end
		-- the starting coins buy the second villager a bed and a workplace, and a ready-made
		-- cottage on top
		local bed = Catalog.get("bed_single")
		local cheapestWork, dearestWork = math.huge, 0
		for _, def in Catalog.workplaces() do
			cheapestWork = math.min(cheapestWork, def.price)
			dearestWork = math.max(dearestWork, def.price)
		end
		local cottage = Presets.price("cottage")
		expect(bed.price + cheapestWork + cottage < Tuning.Economy.StartCoins).toBeTruthy()
		-- and from then on the builder's wage from the starting workshop gets a town going: a day
		-- of it buys three of the dearest workplace, a ready-made cottage takes one to two days of
		-- it and the biggest ready-made building under four
		local builder = startPay(Jobs.get("builder"))
		expect(dearestWork * 3 <= builder).toBeTruthy()
		expect(cottage / builder).toBeBetween(1, 2)
		local dearestPreset = 0
		for _, preset in Presets.list do
			dearestPreset = math.max(dearestPreset, Presets.price(preset.id))
		end
		expect(dearestPreset / builder < 4).toBeTruthy()
		-- a workplace pays for itself inside half a day of the job it opens, and a ready-made
		-- building for a trade (the workplace with its shop round it) in 1.5 to 5 days
		for _, def in Catalog.workplaces() do
			expect(def.price / startPay(Jobs.get(def.job))).toBeBetween(0.05, 0.5)
		end
		local shops = 0
		for _, preset in Presets.list do
			for _, o in preset.objects do
				local def = o.kind == "items" and Catalog.get(o.obj.id)
				if def and def.job then
					shops += 1
					expect(Presets.price(preset.id) / startPay(Jobs.get(def.job))).toBeBetween(1.5, 5)
				end
			end
		end
		expect(shops >= #Jobs.list).toBeTruthy()
		-- three workers save up for the first land inside one to two dozen minutes of play (a
		-- town day is 12 minutes); one alone takes two to five town days
		local job = Jobs.get("shopkeeper")
		local perDay = 3 * Jobs.pay(job, 3, START, "none")
		expect(Tuning.City.Land[2].Price / perDay).toBeBetween(0.5, 2)
		expect(Tuning.City.Land[2].Price / Jobs.pay(job, 3, START, "none")).toBeBetween(2, 5)
		-- the daily gift is a welcome, not a wage: the first one is less than the builder's first
		-- day, and at its biggest it is less than two workers earn in a town day
		local E = Tuning.Economy
		expect(E.DailyGift < builder).toBeTruthy()
		expect(E.DailyGift + (E.DailyStreakCap - 1) * E.DailyStreakBonus < 2 * meanStartPay()).toBeTruthy()
		-- what the small things pay stays small beside a day's work: a wish, a find in the
		-- grass, a room request, a customer dropping by, a busy day
		local least = math.huge
		for _, j in Jobs.list do
			least = math.min(least, startPay(j))
		end
		expect(Tuning.Life.WishCoinsMax <= least / 4).toBeTruthy()
		expect(Tuning.Rewards.EventCoinsMax <= least / 2).toBeTruthy()
		expect(Tuning.Rewards.RequestCoins <= least / 1.5).toBeTruthy()
		expect(Tuning.Jobs.VisitCoins * 5 <= least / 4).toBeTruthy()
		expect(Tuning.Jobs.BusyDayShare <= 0.5).toBeTruthy()
	end)

	it("asks of each level what its own workers can earn in a sensible time", function()
		-- What a level takes: the building its worth asks for on top of the level before (saved
		-- up by the workers that level had to have), then the land it unlocks (saved up by the
		-- workers it has to have itself). At starting mood and skill, with no more workers than
		-- the levels ask for, every step is a day or more of work and none is more than a few
		-- hours of play. A town day is 12 minutes; a town that keeps everyone in work, happy and
		-- learning does it in about half. (With wages tripled and building halved the steps took
		-- a quarter of the 3 to 25 days they did.)
		local levels, land = Tuning.City.Levels, Tuning.City.Land
		local pay = meanStartPay()
		local total = 0
		for i = 2, #levels do
			local build = levels[i].Value - math.max(levels[i - 1].Value, Tuning.City.StarterWorth)
			local days = build / (math.max(1, levels[i - 1].Workers) * pay)
			for _, l in land do
				if l.Level == i then
					days += l.Price / (levels[i].Workers * pay)
				end
			end
			expect(days).toBeBetween(1, 8)
			total += days
		end
		-- the whole way from a hamlet to a city, every land bought: an evening's play or two,
		-- not ten minutes and not a week (it was 4 to 15 hours)
		expect(total * Tuning.Day.Length / 3600).toBeBetween(1.5, 5)
	end)

	it("earns four fifths or more of a keen player's coins from wages once two villagers work", function()
		-- Ten town days from the start of each stage, played out for the keenest player there
		-- could be (see playDays), over several seeds. Wages must be four fifths of everything
		-- that comes in at the smallest of them (three villagers, two in work: what a village
		-- asks for), and more as the town grows. Before the first rebalance wages were 29% of it
		-- there and half of it in a city, and the thank yous alone paid more than work did; after
		-- it 72% and 87%. With wages tripled they are 88% and 95%, and these bounds went up with
		-- them (they were two thirds, 72%, 72% and 80%).
		local stages = {
			{ pop = 3, workers = 2, share = 0.8 },
			{ pop = 4, workers = 4, share = 0.85 },
			{ pop = 7, workers = 6, share = 0.85 },
			{ pop = 13, workers = 12, share = 0.9 },
		}
		for _, stage in stages do
			local wages, other = 0, 0
			local seeds = 6
			for seed = 1, seeds do
				local p, rng = workingTown(stage.pop, stage.workers, seed * 31 + stage.pop)
				p.coins = 1e6 -- so that no generous answer is turned down for want of coins
				local got = playDays(p, rng, 10)
				wages += got.wages
				other += got.other
			end
			local share = wages / (wages + other)
			if share < stage.share then
				error(
					string.format(
						"%d villagers, %d in work: wages are %d%% of a keen player's coins (%d a day against %d from everything else); they should be %d%% or more",
						stage.pop,
						stage.workers,
						math.floor(share * 100),
						wages / (seeds * 10),
						other / (seeds * 10),
						math.floor(stage.share * 100)
					)
				)
			end
			-- and a day's wages are real money by then: more than a ready-made cottage
			expect(wages / (seeds * 10) > Presets.price("cottage")).toBeTruthy()
		end
	end)

	it("lets a town with two workers afford the cravings it gets, though they are not free", function()
		-- the user: "when a character gets a craving, allow the player to simply pay to buy it"
		local twoWorkers = 2 * meanStartPay()
		local sum, dearest, cheapest = 0, 0, math.huge
		for _, food in Foods.list do
			local price = Life.cravingPrice(food.id)
			sum += price
			dearest = math.max(dearest, price)
			cheapest = math.min(cheapest, price)
		end
		expect(cheapest >= 20).toBeTruthy()
		-- the usual craving is a small slice of two workers' day, and even the dearest is
		-- less than half of it
		expect(sum / #Foods.list < twoWorkers / 5).toBeTruthy()
		expect(dearest < twoWorkers / 2).toBeTruthy()
		-- over ten keen days in a town of three with two in work, buying every craving takes
		-- a real bite out of the wages (more than a fiftieth) and never most of them
		local wages, spent = 0, 0
		for seed = 1, 6 do
			local p, rng = workingTown(3, 2, seed * 17)
			p.coins = 1e6
			local got = playDays(p, rng, 10)
			wages += got.wages
			spent += got.cravings
		end
		expect(spent > wages / 50).toBeTruthy()
		expect(spent < wages / 4).toBeTruthy()
	end)
end)
