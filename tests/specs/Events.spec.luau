--!nocheck
-- Random events: every event can happen, every line is filled in, every choice resolves,
-- and the numbers stay in range over thousands of seeded runs.

local Shared = "ReplicatedStorage.Shared."
local Tuning = require(Shared .. "Config.Tuning")
local Events = require(Shared .. "Data.Events")
local EventEngine = require(Shared .. "Sim.EventEngine")
local Schema = require(Shared .. "Sim.Schema")
local Relationships = require(Shared .. "Sim.Relationships")
local Life = require(Shared .. "Sim.Life")
local Personalities = require(Shared .. "Data.Personalities")
local StarterHouse = require(Shared .. "Data.StarterHouse")
local Appearance = require(Shared .. "Avatar.Appearance")
local Rng = require(Shared .. "Util.Rng")

local function makeProfile(rng, count, withBeds)
	local p = Schema.newProfile()
	p.plan = StarterHouse.plan()
	-- the starter house is just a house: give the town a stall to work at
	p.plan.items.stall = { id = "work_market", x = 130, y = 0, z = 12, r = 180, lv = 0 }
	local bedKey, workKey
	for key, item in p.plan.items do
		if item.id:find("bed") then
			bedKey = key
		elseif item.id:find("work_") then
			workKey = key
		end
	end
	if rng:chance(0.5) then
		-- a few more garden pieces, so the inspector has something to look at
		for k = 1, 8 do
			p.plan.items["g" .. k] = { id = "flower_bed", x = 56 + k * 6, y = 0, z = 84, r = 0, lv = 0 }
		end
	end
	for i = 1, count do
		local pers = Personalities.list[(i - 1) % #Personalities.list + 1].id
		local input = Schema.cleanVillagerInput({
			name = "V" .. i,
			pers = pers,
			app = Appearance.default(),
			bday = { s = rng:int(1, 4), d = rng:int(1, 10) },
		})
		local vid = "v" .. i
		local v = Schema.newVillager(vid, input, rng)
		v.lv = rng:int(1, 10)
		if withBeds and i == 1 then
			v.bed = bedKey
		end
		if i == 2 and workKey and rng:chance(0.7) then
			v.job = workKey
		end
		p.villagers[vid] = v
		table.insert(p.order, vid)
	end
	return p
end

local function hasHole(s)
	return type(s) == "string" and s:find("{%w+}") ~= nil
end

local function checkText(scene, where)
	local function check(s)
		if hasHole(s) then
			error(where .. ": unfilled text: " .. s)
		end
		if type(s) == "string" and (s:find("\u{2014}") or s:find("\u{2013}")) then
			error(where .. ": a dash in: " .. s)
		end
	end
	check(scene.title)
	check(scene.log)
	for _, l in scene.lines do
		check(l.text)
		if l.who ~= nil and l.who ~= "a" and l.who ~= "b" and l.who ~= "c" then
			error(where .. ": bad speaker " .. tostring(l.who))
		end
	end
	for _, c in scene.choices or {} do
		check(c.text)
		for _, l in c.lines or {} do
			check(l.text)
		end
	end
end

describe("Event engine", function()
	it("reaches every event and keeps the numbers in range", function()
		local seen = {}
		local weathers = { "clear", "rain", "storm", "snow" }
		for seed = 1, 3000 do
			local rng = Rng.new(seed)
			local count = rng:int(1, 7)
			local p = makeProfile(rng, count, rng:chance(0.6))
			if count >= 2 and rng:chance(0.3) then
				Relationships.quarrel(p, "v1", "v2", 1000, 10)
			end
			if count >= 3 and rng:chance(0.4) then
				Relationships.add(p, "v2", "v3", 60)
			end
			-- a romance under way: a crush, or sweethearts close enough to propose
			if count == 2 and rng:chance(0.8) then
				Relationships.makeUp(p, "v1", "v2")
				Relationships.add(p, "v1", "v2", 85)
				Life.setBond(p, "v1", "v2", rng:pick({ "crush", "sweethearts", "sweethearts" }))
			end
			if rng:chance(0.3) then
				p.inv.items.medicine = 1
			end
			local present = table.clone(p.order)
			local first = p.villagers.v1
			local ctx = EventEngine.context(p, {
				now = 1000,
				hour = rng:float(0, 24),
				season = first.bday.s,
				dayOfSeason = if rng:chance(0.2) then first.bday.d else 99,
				day = 5,
				weather = rng:pick(weathers),
				rng = rng,
				present = present,
				freeSlots = Tuning.Villagers.Max - count,
				merchantActive = false,
				friends = if rng:chance(0.5) then { { id = 77, name = "Sam" } } else {},
			})
			local ev = EventEngine.pick(ctx, {})
			if ev then
				seen[ev.id] = true
				checkText(ev.scene, ev.id)
				local scene = ev.scene
				local effects = scene.effects or {}
				if scene.choices then
					local i, c = EventEngine.choice(scene, rng:int(1, #scene.choices), p.coins)
					expect(i ~= nil).toBeTruthy()
					effects = c.effects
				end
				local notices, service = EventEngine.apply(p, ev, effects, 1000)
				for _, n in notices do
					expect(hasHole(n)).toBeFalsy()
				end
				for _, s in service do
					expect(type(s.t)).toBe("string")
				end
				for _, v in p.villagers do
					expect(v.mood).toBeBetween(0, 100)
					expect(v.lv).toBeBetween(1, Tuning.Jobs.SkillCap)
				end
				for _, rel in p.rel do
					expect(rel.s).toBeBetween(-100, 100)
				end
				expect(p.coins >= 0).toBeTruthy()
			end
		end
		local missing = {}
		for _, def in Events.list do
			if not seen[def.id] then
				table.insert(missing, def.id)
			end
		end
		if #missing > 0 then
			error("never picked: " .. table.concat(missing, ", "))
		end
	end)

	it("never repeats the last few events too often", function()
		local rng = Rng.new(99)
		local p = makeProfile(rng, 5, true)
		local recent = {}
		local repeats = 0
		for _ = 1, 300 do
			local ctx = EventEngine.context(p, {
				now = 1000,
				hour = 12,
				season = 1,
				dayOfSeason = 99,
				day = 5,
				weather = "clear",
				rng = rng,
				present = table.clone(p.order),
				freeSlots = 0,
			})
			local ev = EventEngine.pick(ctx, recent)
			if ev then
				if table.find(recent, ev.id) then
					repeats += 1
				end
				table.insert(recent, 1, ev.id)
				while #recent > Tuning.Events.RecentMemory do
					table.remove(recent)
				end
			end
		end
		expect(repeats < 60).toBeTruthy()
	end)

	it("falls back to a free choice when a costly one can't be paid", function()
		local scene =
			{ choices = { { text = "x", cost = 500, effects = {} }, { text = "y", effects = {} } }, default = 1 }
		local i = EventEngine.choice(scene, 1, 100)
		expect(i).toBe(2)
	end)

	it("levels villagers up from xp", function()
		local v = { name = "Test", lv = 1, xp = 0 }
		local notices = {}
		EventEngine.addXp(v, 1000, notices)
		expect(v.lv > 3).toBeTruthy()
		expect(#notices).toBe(1)
	end)
end)
