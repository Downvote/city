--!nocheck
-- What a villager needs, and how happy it lets them be (Sim/Needs). The user: "Villager mood bars
-- should also not be that easy to fill up, the factors affecting it should be: amount and
-- relationship of friends, quality of bed, roof over bed, fun objects near bed. Villagers will ask
-- for these if they are not fufilled." and "if a villager dosent have a workspace or bed, they will
-- ask the player for it ... The end of these dialogues should be "Villagers need an x to y. Build
-- it in Build mode > z"". Each factor adds to the most their mood can reach, mood climbs to it
-- slowly, lifts count for less and stop at it, and an old save's moods load and settle.

local Shared = "ReplicatedStorage.Shared."
local Tuning = require(Shared .. "Config.Tuning")
local Schema = require(Shared .. "Sim.Schema")
local Needs = require(Shared .. "Sim.Needs")
local Relationships = require(Shared .. "Sim.Relationships")
local Life = require(Shared .. "Sim.Life")
local Talk = require(Shared .. "Sim.Talk")
local Tutorial = require(Shared .. "Sim.Tutorial")
local EventEngine = require(Shared .. "Sim.EventEngine")
local Events = require(Shared .. "Data.Events")
local Catalog = require(Shared .. "Build.Catalog")
local Plan = require(Shared .. "Build.Plan")
local StarterHouse = require(Shared .. "Data.StarterHouse")
local Appearance = require(Shared .. "Avatar.Appearance")
local Rng = require(Shared .. "Util.Rng")

local N = Tuning.Needs
local V = Tuning.Villagers

-- a town of `count` villagers on an empty plot (land 200 across, x 100 to 300), past the tutorial
local function town(count)
	local p = Schema.newProfile()
	p.plan = Plan.new()
	p.tutorial = Tutorial.Skipped
	for i = 1, count do
		local input = Schema.cleanVillagerInput({ name = "V" .. i, pers = "sunny", app = Appearance.default() })
		p.villagers["v" .. i] = Schema.newVillager("v" .. i, input, Rng.new(i))
		table.insert(p.order, "v" .. i)
	end
	return p
end

local function put(p, key, id, x, z, lv)
	p.plan.items[key] = { id = id, x = x, y = 0, z = z, r = 0, lv = lv or 0 }
end

local function factor(p, vid, id)
	for _, f in Needs.factors(p, vid) do
		if f.id == id then
			return f
		end
	end
	return nil
end

-- a bed for v1 at (150, 150), a plain one unless told
local function bedded(id)
	local p = town(1)
	put(p, "bed", id or "bed_single", 150, 150)
	p.villagers.v1.bed = "bed"
	return p
end

describe("Needs", function()
	it("adds up to the most a mood can reach, everything in place", function()
		local total = N.Base + N.Bed + N.Comfy[#N.Comfy].Points + N.Roof + N.FunMax + N.FriendsMax
		expect(total).toBe(V.MoodMax)
		-- (a pet is on top of that, to make up for something missing)
		expect(N.Pet > 0).toBeTruthy()
		-- with nothing at all, a villager reaches only Base
		local p = town(1)
		expect(Needs.cap(p, "v1")).toBe(N.Base)
		for _, f in Needs.factors(p, "v1") do
			expect(f.points).toBe(0)
			expect(f.have).toBe(false)
			expect(type(f.text)).toBe("string")
		end
		-- steps that only go up, comfort by price
		for i = 2, #N.Comfy do
			expect(N.Comfy[i].Price > N.Comfy[i - 1].Price).toBeTruthy()
			expect(N.Comfy[i].Points > N.Comfy[i - 1].Points).toBeTruthy()
		end
		-- and mood fills slowly: from nothing to everything takes more than a town day
		expect((V.MoodMax - N.Base) / N.Rise > 24).toBeTruthy()
	end)

	it("counts a bed, and how comfy it is by its price", function()
		local p = bedded("bed_single")
		expect(factor(p, "v1", "bed").points).toBe(N.Bed)
		expect(factor(p, "v1", "bed").text).toBe(Catalog.get("bed_single").name)
		local plain = factor(p, "v1", "comfy")
		expect(plain.points).toBe(0)
		expect(plain.have).toBe(false)
		-- every bed in the catalog is on a step, and the dearest beds are on the top one
		local top = 0
		for _, def in Catalog.withTag("bed") do
			local step, points = Needs.comfy(def)
			expect(step).toBeBetween(1, #N.Comfy)
			expect(points).toBe(N.Comfy[step].Points)
			top = math.max(top, step)
		end
		expect(top).toBe(#N.Comfy)
		-- a canopy bed is comfier than a single, and asked for no more
		p.plan.items.bed.id = "bed_canopy"
		local canopy = factor(p, "v1", "comfy")
		expect(canopy.points > plain.points).toBeTruthy()
		expect(canopy.have).toBe(true)
		-- a bed that is gone, or isn't a bed, counts for nothing
		p.plan.items.bed.id = "armchair"
		expect(factor(p, "v1", "bed").points).toBe(0)
		p.plan.items.bed = nil
		expect(Needs.cap(p, "v1")).toBe(N.Base)
	end)

	it("counts a roof over the bed, or a floor above it, and nothing beside it", function()
		local p = bedded()
		expect(factor(p, "v1", "roof").points).toBe(0)
		expect(Needs.covered(p.plan, p.plan.items.bed)).toBe(false)
		-- a roof beside it
		p.plan.roofs.r1 = {
			x1 = 160,
			z1 = 140,
			x2 = 180,
			z2 = 160,
			lv = 0,
			style = "gable",
			rise = 4,
			dir = 0,
			over = 1,
			c = "FFFFFF",
			m = "Slate",
		}
		expect(factor(p, "v1", "roof").points).toBe(0)
		-- over it
		p.plan.roofs.r1.x1 = 140
		expect(factor(p, "v1", "roof").points).toBe(N.Roof)
		expect(factor(p, "v1", "roof").have).toBe(true)
		-- a roof under the storey the bed is on doesn't cover it
		p.plan.items.bed.lv = 1
		expect(factor(p, "v1", "roof").points).toBe(0)
		-- a floor on the storey above does
		p.plan.items.bed.lv = 0
		p.plan.roofs.r1 = nil
		p.plan.floors.f1 = { x1 = 140, z1 = 140, x2 = 160, z2 = 160, lv = 1, c = "FFFFFF", m = "WoodPlanks" }
		expect(factor(p, "v1", "roof").points).toBe(N.Roof)
		-- and its own floor doesn't
		p.plan.floors.f1.lv = 0
		expect(factor(p, "v1", "roof").points).toBe(0)
		-- the starting house's bed is under its roof
		local home = town(1)
		home.plan = StarterHouse.plan()
		for key, item in home.plan.items do
			if item.id == "bed_single" then
				home.villagers.v1.bed = key
			end
		end
		expect(factor(home, "v1", "roof").have).toBe(true)
	end)

	it("counts fun pieces near the bed, on its storey, up to a few", function()
		local p = bedded()
		expect(factor(p, "v1", "fun").points).toBe(0)
		put(p, "arcade", "arcade", 158, 150)
		expect(factor(p, "v1", "fun").points).toBe(N.FunEach)
		expect(factor(p, "v1", "fun").have).toBe(true)
		-- a lamp is no fun, a far off piano doesn't count, nor one upstairs
		put(p, "lamp", "lamp_floor", 152, 150)
		put(p, "far", "piano", 150 + V.RoomRadius + 6, 150)
		put(p, "up", "drum_kit", 150, 156, 1)
		expect(factor(p, "v1", "fun").points).toBe(N.FunEach)
		-- the Fun tab's pieces and anything for games, toys, music or a TV are fun
		expect(Needs.isFun(Catalog.get("piano"))).toBe(true)
		expect(Needs.isFun(Catalog.get("record_player"))).toBe(true)
		expect(Needs.isFun(Catalog.get("armchair"))).toBe(false)
		for i = 1, 6 do
			put(p, "toy" .. i, "rocking_horse", 146, 140 + i * 2)
		end
		expect(factor(p, "v1", "fun").points).toBe(N.FunMax)
	end)

	it("counts friends by how many and how close", function()
		local p = town(5)
		expect(factor(p, "v1", "friends").points).toBe(0)
		expect(factor(p, "v1", "friends").text).toBe("Nobody yet")
		Relationships.add(p, "v1", "v2", 12) -- acquainted
		local known = factor(p, "v1", "friends")
		expect(known.points).toBe(N.FriendPoints[4])
		Relationships.add(p, "v1", "v3", 35) -- friends
		Relationships.add(p, "v1", "v4", 85) -- best friends
		local f = factor(p, "v1", "friends")
		expect(f.points).toBe(N.FriendPoints[4] + N.FriendPoints[5] + N.FriendPoints[7])
		expect(f.text).toBe("2 friends")
		-- closer counts for more
		expect(N.FriendPoints[7] > N.FriendPoints[6]).toBeTruthy()
		expect(N.FriendPoints[6] > N.FriendPoints[5]).toBeTruthy()
		-- rivals count for nothing, and it stops at FriendsMax
		Relationships.add(p, "v1", "v5", -80)
		expect(factor(p, "v1", "friends").points).toBe(f.points)
		local crowd = town(12)
		for i = 2, 12 do
			Relationships.add(crowd, "v1", "v" .. i, 90)
		end
		expect(factor(crowd, "v1", "friends").points).toBe(N.FriendsMax)
	end)

	it("reaches the top only with everything in place", function()
		local p = town(6)
		put(p, "bed", "fancy_bed_crown", 150, 150)
		p.villagers.v1.bed = "bed"
		p.plan.roofs.r1 = {
			x1 = 130,
			z1 = 130,
			x2 = 170,
			z2 = 170,
			lv = 0,
			style = "flat",
			rise = 0,
			dir = 0,
			over = 1,
			c = "FFFFFF",
			m = "Slate",
		}
		for i = 1, 3 do
			put(p, "fun" .. i, "arcade", 156, 140 + i * 4)
		end
		for i = 2, 6 do
			Relationships.add(p, "v1", "v" .. i, 90)
		end
		expect(Needs.cap(p, "v1")).toBe(V.MoodMax)
		expect(#Needs.missing(p, "v1")).toBe(1) -- (only work: it isn't a mood factor)
		expect(Needs.ask(p, "v1")).toBe("work")
	end)

	it("lets mood climb to what they can reach, slowly, and sink to it from over", function()
		local p = bedded()
		local v = p.villagers.v1
		local cap = Needs.cap(p, "v1")
		v.mood = 0
		Needs.drift(p, 1)
		expect(v.mood).toBe(N.Rise)
		for _ = 1, 200 do
			Needs.drift(p, 1)
		end
		expect(v.mood).toBe(cap)
		-- over it (a mood from before, the roof sold): it sinks Fall an hour and stops there
		v.mood = cap + 10
		Needs.drift(p, 1)
		expect(v.mood).toBe(cap + 10 - N.Fall)
		for _ = 1, 50 do
			Needs.drift(p, 1)
		end
		expect(v.mood).toBe(cap)
		expect(Needs.drift(p, 1)).toBe(false)
	end)

	it("makes a lift count for less and stop at what they can reach; a knock counts in full", function()
		local p = bedded()
		local v = p.villagers.v1
		local cap = Needs.cap(p, "v1")
		v.mood = 0
		expect(Needs.addMood(p, "v1", 12)).toBe(Needs.lift(12))
		expect(Needs.lift(12) < 12).toBeTruthy()
		expect(Needs.lift(1)).toBe(1)
		v.mood = cap - 2
		expect(Needs.addMood(p, "v1", 40)).toBe(2)
		expect(v.mood).toBe(cap)
		expect(Needs.addMood(p, "v1", 40)).toBe(0)
		v.mood = 5
		expect(Needs.addMood(p, "v1", -12)).toBe(-5)
		expect(v.mood).toBe(V.MoodMin)
		-- nothing for junk or nobody
		expect(Needs.addMood(p, "v1", 0 / 0)).toBe(0)
		expect(Needs.addMood(p, "nobody", 5)).toBe(0)
		-- a chat, a wish and a gift all go through it
		v.mood = 0
		local chat = Talk.chat(p, "v1", 3, Rng.new(1))
		expect(chat.mood).toBe(Needs.lift(Tuning.Talk.ChatMood))
	end)

	it("loads an old save's moods, and settles them to what each villager has", function()
		-- a save from before: one villager at the top, one with a broken mood, and no plan
		local raw = Schema.newProfile()
		raw.villagers = {
			v1 = { name = "Old", pers = "sunny", mood = 100, bed = "gone" },
			v2 = { name = "Odd", pers = "shy", mood = 0 / 0 },
			v3 = { name = "Big", pers = "bold", mood = 500 },
		}
		raw.order = { "v1", "v2", "v3" }
		local p = Schema.migrate(raw)
		expect(p.villagers.v1.mood).toBe(100)
		expect(p.villagers.v2.mood).toBe(V.StartMood)
		expect(p.villagers.v3.mood).toBe(V.MoodMax)
		-- no plan and a bed that is gone: they reach Base, and sink to it an hour at a time
		expect(Needs.cap(p, "v1")).toBe(N.Base)
		expect(#Needs.factors(p, "v1")).toBe(#Needs.Factors)
		Needs.drift(p, 1)
		expect(p.villagers.v1.mood).toBe(100 - N.Fall)
		for _ = 1, 100 do
			Needs.drift(p, 1)
		end
		for _, v in p.villagers do
			expect(v.mood).toBe(N.Base)
		end
	end)

	it("asks for a bed and work first, then what their mood lacks", function()
		local p = town(2)
		expect(Needs.missing(p, "v1")).toEqual({ "bed", "work" })
		expect(Needs.ask(p, "v1")).toBe("bed")
		put(p, "bed", "bed_single", 150, 150)
		p.villagers.v1.bed = "bed"
		expect(Needs.missing(p, "v1")).toEqual({ "work", "roof", "comfy", "fun", "friends" })
		put(p, "work", "work_market", 200, 20)
		p.villagers.v1.job = "work"
		expect(Needs.ask(p, "v1")).toBe("roof")
		expect(Needs.ask(p, "nobody")).toBe(nil)
		-- somebody to be introduced to
		expect(Needs.stranger(p, "v1")).toBe("v2")
		Relationships.add(p, "v1", "v2", 40)
		expect(Needs.stranger(p, "v1")).toBe(nil)
		-- while the tutorial teaches the bed and the workplace, it does the asking
		p.tutorial = 0
		local fresh = town(1)
		fresh.tutorial = 0
		expect(Needs.teaching(fresh)).toBe(true)
		fresh.tutorial = Tutorial.Skipped
		expect(Needs.teaching(fresh)).toBe(false)
	end)

	it("ends every ask on the plain line, with Build mode's real tabs", function()
		-- the user: "The end of these dialogues should be "Villagers need an x to y. Build it in
		-- Build mode > z""
		local ui = readFile("src/client/Build/BuildUI.luau")
		local hud = readFile("src/client/UI/Hud.luau")
		expect(ui ~= nil and hud ~= nil).toBeTruthy()
		for _, kind in Needs.Asks do
			local text = Needs.line(kind)
			expect(text:sub(1, 15)).toBe("Villagers need ")
			expect(text:find("—", 1, true) == nil and text:find("–", 1, true) == nil).toBeTruthy()
			local path = text:match("Build it in Build mode > (.+)$")
			if path then
				for name in path:gmatch("[^>]+") do
					name = name:gsub("^%s+", ""):gsub("%s+$", "")
					expect(ui:find('name = "' .. name .. '"', 1, true) ~= nil).toBeTruthy()
				end
			else
				expect(kind).toBe("friends")
				expect(hud:find('"Create"', 1, true) ~= nil).toBeTruthy()
			end
		end
		expect(hud:find('"Villagers"', 1, true) ~= nil).toBeTruthy()
		expect(Needs.line("introduce"):find("Villagers need friends", 1, true) ~= nil).toBeTruthy()
	end)

	it("plays every ask as a short burst in their voice, ending on its line", function()
		local function staged(p, id)
			local ctx = EventEngine.context(p, {
				now = 1000,
				hour = 12,
				season = 1,
				dayOfSeason = 1,
				day = 3,
				weather = "clear",
				rng = Rng.new(4),
				present = table.clone(p.order),
				freeSlots = 10,
			})
			local def = Events.get(id)
			expect(def ~= nil).toBeTruthy()
			if def.weight(ctx, "v1") <= 0 then
				return nil
			end
			return EventEngine.stage(ctx, def, { "v1" })
		end
		local p = town(3)
		local kinds = { nobed = "bed", jobhunt = "work" }
		for id, kind in kinds do
			local ev = staged(p, id)
			local lines = ev.scene.lines
			expect(#lines >= 2).toBeTruthy()
			expect(lines[1].who).toBe("a")
			expect(lines[#lines].who).toBe(nil)
			expect(lines[#lines].text).toBe(Needs.line(kind))
		end
		-- with a plain bed out in the open, nothing fun by it and a stranger in town
		put(p, "bed", "bed_single", 150, 150)
		p.villagers.v1.bed = "bed"
		expect(staged(p, "nobed")).toBe(nil)
		for id, kind in { needroof = "roof", needcomfy = "comfy", needfun = "fun" } do
			local ev = staged(p, id)
			expect(ev.scene.lines[#ev.scene.lines].text).toBe(Needs.line(kind))
		end
		-- friends: a wish to meet somebody they hardly know, and where to introduce them
		local ev = staged(p, "needfriends")
		expect(ev.scene.lines[#ev.scene.lines].text).toBe(Needs.line("introduce"))
		local _, service = EventEngine.apply(p, ev, ev.scene.effects, 1000)
		local w = p.villagers.v1.wish
		expect(w ~= nil and w.kind == "friend" and p.villagers[w.arg] ~= nil).toBeTruthy()
		expect(Life.wishText(p, "v1") ~= nil).toBeTruthy()
		expect(service[1].t).toBe("wishes")
		-- with a wish open already, or nobody to meet, more villagers instead
		ev = staged(p, "needfriends")
		expect(ev.scene.lines[#ev.scene.lines].text).toBe(Needs.line("friends"))
		local alone = town(1)
		put(alone, "bed", "bed_single", 150, 150)
		alone.villagers.v1.bed = "bed"
		ev = staged(alone, "needfriends")
		expect(ev.scene.lines[#ev.scene.lines].text).toBe(Needs.line("friends"))
		-- nothing asked for what they have
		alone.plan.roofs.r1 = {
			x1 = 140,
			z1 = 140,
			x2 = 160,
			z2 = 160,
			lv = 0,
			style = "flat",
			rise = 0,
			dir = 0,
			over = 1,
			c = "FFFFFF",
			m = "Slate",
		}
		expect(staged(alone, "needroof")).toBe(nil)
	end)

	it("counts a pet of their own on top, never past the most a mood can be", function()
		-- the user: pets "raise mood"
		local p = town(1)
		local before = Needs.cap(p, "v1")
		p.pets = { p1 = { kind = "cat", name = "Biscuit", coat = 1, vid = "v1" } }
		expect(Needs.cap(p, "v1")).toBe(before + N.Pet)
		local f = factor(p, "v1", "pet")
		expect(f.have).toBe(true)
		expect(f.text).toBe("Biscuit")
		-- somebody else's pet counts for nothing here, and nobody asks for a pet
		p.pets.p1.vid = "v2"
		expect(Needs.cap(p, "v1")).toBe(before)
		expect(table.find(Needs.missing(p, "v1"), "pet")).toBe(nil)
		-- and the cap still stops at the top
		expect(Needs.cap(p, "v1") <= V.MoodMax).toBeTruthy()
	end)
end)
