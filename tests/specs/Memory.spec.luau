--!nocheck
-- What villagers remember from their events (Sim/Memory). The user: "along with their conversations
-- and events having more impact, such as remembering if they joined a band, started wearing a new
-- accessory (temporarily), etc.". Events start a memory that lasts a few town days; while it does,
-- the villager brings it up in their own words and later events can ask for it; when it ends, what
-- it changed goes back: the accessory comes off, a falling out ends.

local Shared = "ReplicatedStorage.Shared."
local Tuning = require(Shared .. "Config.Tuning")
local Schema = require(Shared .. "Sim.Schema")
local Memory = require(Shared .. "Sim.Memory")
local Talk = require(Shared .. "Sim.Talk")
local EventEngine = require(Shared .. "Sim.EventEngine")
local Relationships = require(Shared .. "Sim.Relationships")
local Events = require(Shared .. "Data.Events")
local Personalities = require(Shared .. "Data.Personalities")
local StarterHouse = require(Shared .. "Data.StarterHouse")
local Appearance = require(Shared .. "Avatar.Appearance")
local Rng = require(Shared .. "Util.Rng")

local DAY = Tuning.Day.Length

local function town(names, pers)
	local p = Schema.newProfile()
	p.name = "Robin"
	p.plan = StarterHouse.plan()
	for i, name in names do
		local input = Schema.cleanVillagerInput({ name = name, pers = pers or "sunny", app = Appearance.default() })
		p.villagers["v" .. i] = Schema.newVillager("v" .. i, input, Rng.new(i))
		table.insert(p.order, "v" .. i)
	end
	return p
end

local function context(p, now, seed)
	return EventEngine.context(p, {
		now = now,
		hour = 12,
		season = 1,
		dayOfSeason = 3,
		day = 5,
		weather = "clear",
		rng = Rng.new(seed or 1),
		present = table.clone(p.order),
		freeSlots = 4,
	})
end

-- plays an event with these stars through answer `i` at os time `now`; returns the service's part
local function play(p, id, stars, i, now)
	local ev = EventEngine.stage(context(p, now), Events.get(id), stars)
	local effects = ev.scene.effects or {}
	if ev.scene.choices then
		local _, c = EventEngine.choice(ev.scene, i, 1e6)
		effects = c.effects
	end
	local _, service = EventEngine.apply(p, ev, effects, now)
	return service, ev
end

local function hasDress(service, vid)
	for _, s in service do
		if s.t == "dress" and s.vid == vid then
			return true
		end
	end
	return false
end

local function readable(text)
	return type(text) == "string" and #text > 0 and not text:find("{", 1, true)
end

describe("Memory", function()
	it("starts with the events that leave something behind", function()
		-- a band of three: all of them remember it, under the name you picked
		local p = town({ "Mara", "Tobin", "Ivy" })
		play(p, "band", { "v1", "v2", "v3" }, 1, 1000)
		local name
		for _, vid in p.order do
			local m = Memory.has(p.villagers[vid], "band", 1001)
			expect(m ~= nil).toBe(true)
			name = name or m.name
			expect(m.name).toBe(name)
			expect(m.untilT).toBe(1000 + Tuning.Memory.Days.band * DAY)
		end
		-- the yellow hat: worn for a few days, and the service is told to dress them
		local q = town({ "Mara" })
		local service = play(q, "outfit", { "v1" }, 1, 1000)
		local hat = Memory.has(q.villagers.v1, "accessory", 1001)
		expect(hat.what).toBe("yellowhat")
		expect(hasDress(service, "v1")).toBe(true)
		-- a quarrel is a falling out on both sides, and making up ends it
		local r = town({ "Mara", "Tobin" })
		EventEngine.apply(r, { actors = { a = "v1", b = "v2" } }, { { t = "quarrel", a = "a", b = "b" } }, 1000)
		expect(Memory.has(r.villagers.v1, "fallout", 1001).who).toBe("v2")
		expect(Memory.has(r.villagers.v2, "fallout", 1001).who).toBe("v1")
		EventEngine.apply(r, { actors = { a = "v1", b = "v2" } }, { { t = "makeup", a = "a", b = "b" } }, 1100)
		expect(Memory.has(r.villagers.v1, "fallout", 1101)).toBe(nil)
		expect(Memory.has(r.villagers.v2, "fallout", 1101)).toBe(nil)
		-- a new hobby is the talk of the week, and it stays their hobby after
		EventEngine.apply(r, { actors = { a = "v1" } }, { { t = "hobby", who = "a", id = "knitting" } }, 1000)
		expect(Memory.has(r.villagers.v1, "hobby", 1001).what).toBe("knitting")
		expect(r.villagers.v1.hobby).toBe("knitting")
		-- race day ends the training
		Memory.start(r, "v1", "training", nil, 1000)
		play(r, "raceday", { "v1" }, 1, 1200)
		expect(Memory.has(r.villagers.v1, "training", 1201)).toBe(nil)
	end)

	it("lets later events ask for a villager in a band, with a pet, in training", function()
		local p = town({ "Mara", "Tobin" })
		local ctx = context(p, 1000)
		for id, kind in
			{
				gig = "band",
				petnews = "pet",
				firstcrop = "garden",
				dishagain = "dish",
				penletter = "penpal",
				raceday = "training",
			}
		do
			local def = Events.get(id)
			expect(def.weight(ctx, "v1")).toBe(0)
			Memory.start(p, "v1", kind, { name = "Pickle Jar", what = if kind == "pet" then "puppy" else "beans" }, 900)
			expect(def.weight(ctx, "v1") > 0).toBe(true)
			-- and it plays with the memory's words in
			local ev = EventEngine.stage(ctx, def, { "v1" })
			for _, l in ev.scene.lines do
				expect(readable(l.text)).toBe(true)
			end
		end
		-- somebody notices the new hat
		local look = Events.get("newlook")
		expect(look.weight(ctx, "v1", "v2")).toBe(0)
		Memory.start(p, "v1", "accessory", { what = "strawhat" }, 900)
		expect(look.weight(ctx, "v1", "v2") > 0).toBe(true)
		local ev = EventEngine.stage(ctx, look, { "v1", "v2" })
		expect(ev.scene.lines[1].text:find("straw hat", 1, true) ~= nil).toBe(true)
	end)

	it("is talked about in every voice while it lasts", function()
		for _, pers in Personalities.list do
			local p = town({ "Mara", "Tobin" }, pers.id)
			for _, kind in Memory.Order do
				local m = Memory.start(p, "v1", kind, {
					name = "Biscuit",
					what = if kind == "accessory"
						then "scarf"
						elseif kind == "pet" then "kitten"
						elseif kind == "hobby" then "fishing"
						else "beans",
					who = "v2",
				}, 1000)
				expect(m ~= nil).toBe(true)
				-- (the player's name goes in as the line leaves, in Talk.line)
				local text = Talk.mention(p, "v1", m):gsub("{player}", "Robin")
				expect(readable(text)).toBe(true)
			end
		end
		-- and comes up in a chat, in their own hand, until it runs out
		local p = town({ "Mara" }, "gentle")
		local v = p.villagers.v1
		v.mood, v.bed = 60, "1"
		local m = Memory.start(p, "v1", "pet", { what = "puppy", name = "Noodle" }, 1000)
		local line = Talk.line(p, "v1", Rng.new(1), { now = 1000 }) -- (warm up the pool)
		local _ = line
		local said = Talk.mention(p, "v1", m)
		local function count(now)
			local rng, n = Rng.new(3), 0
			for _ = 1, 400 do
				if Talk.line(p, "v1", rng, { now = now }):find("Noodle", 1, true) then
					n += 1
				end
			end
			return n
		end
		expect(said:find("Noodle", 1, true) ~= nil).toBe(true)
		expect(count(1000 + DAY) > 0).toBe(true)
		expect(count(m.untilT + 1)).toBe(0)
	end)

	it("puts the accessory on for real, beside what they wear, until the player takes it off", function()
		-- the user: "accessories that villagers decide to wear on their own seem to remove other
		-- accessories of the same category. can you make it such that it dosent?" and "it gets taken
		-- off only if the player chooses it dosent suit them"
		local p = town({ "Mara" })
		local v = p.villagers.v1
		-- their own look: hair and a hat of their own
		v.app.acc = { { id = 11, t = "Hair", l = false }, { id = 22, t = "Hat", l = false } }
		local own = Appearance.sanitize(v.app)
		local m, dressed = Memory.start(p, "v1", "accessory", { what = "yellowhat" }, 1000)
		expect(dressed).toBe(true)
		-- nothing found in the catalog yet: they look as they always do, and the server is to look
		expect(Memory.unfound(v, 1001)).toBe(m)
		expect(Appearance.equal(Memory.dressed(v, 1001), own)).toBe(true)
		-- what the catalog search found (Services/Villagers.dress keeps it on the memory)
		m.acc = { id = 333, t = "Hat" }
		expect(Memory.unfound(v, 1001)).toBe(nil)
		local today = Memory.dressed(v, 1001)
		local ids = {}
		for _, a in today.acc do
			ids[a.id] = a.t
		end
		expect(ids[333]).toBe("Hat") -- on
		expect(ids[11]).toBe("Hair") -- their hair stays
		expect(ids[22]).toBe("Hat") -- and so does their own hat
		-- their saved look is never changed
		expect(Appearance.equal(v.app, own)).toBe(true)
		-- it doesn't run out: long after its days it's still on, and nothing ends
		local later = m.untilT + 40 * DAY
		local ended, notices = Memory.tick(p, later)
		expect(#ended).toBe(0)
		expect(#notices).toBe(0)
		expect(Memory.has(v, "accessory", later)).toBe(m)
		local rows = Memory.lately(p, "v1", later)
		expect(rows[1].stays).toBe(true)
		expect(rows[1].what).toBe("yellowhat")
		expect(rows[1].text).toBe("Wearing their yellow hat")
		-- a second thing goes on beside it, and the same thing again keeps what was found
		local m2 = Memory.start(p, "v1", "accessory", { what = "scarf" }, 5000)
		m2.acc = { id = 444, t = "Neck" }
		expect(#Memory.all(v, "accessory", 5001)).toBe(2)
		expect(#Memory.dressed(v, 5001).acc).toBe(4)
		local again = Memory.start(p, "v1", "accessory", { what = "yellowhat" }, 6000)
		expect(again.acc.id).toBe(333)
		expect(#Memory.all(v, "accessory", 6001)).toBe(2)
		-- the player says the scarf doesn't suit them: only the scarf comes off
		expect(Memory.forget(p, "v1", "accessory", nil, "scarf")).toBe(true)
		expect(#Memory.dressed(v, 6001).acc).toBe(3)
		expect(Memory.forget(p, "v1", "accessory", nil, "scarf")).toBe(false)
		-- and everything off, as it was
		expect(Memory.forget(p, "v1", "accessory")).toBe(true)
		expect(Appearance.equal(Memory.dressed(v, 6001), own)).toBe(true)
		-- at most Worn at once: the oldest comes off for a new one
		local t = 7000
		for _, what in { "scarf", "strawhat", "glasses", "flowers", "backpack" } do
			Memory.start(p, "v1", "accessory", { what = what }, t)
			t += 10
		end
		local on = Memory.all(v, "accessory", t)
		expect(#on).toBe(Tuning.Memory.Worn)
		expect(on[1].what).toBe("backpack")
		for _, x in on do
			expect(x.what ~= "scarf").toBe(true)
		end
	end)

	it("ends a falling out when its time runs out, quarrel and all", function()
		local p = town({ "Mara", "Tobin" })
		Relationships.quarrel(p, "v1", "v2", 1000, 30)
		Memory.start(p, "v1", "fallout", { who = "v2" }, 1000)
		Memory.start(p, "v2", "fallout", { who = "v1" }, 1000)
		local m = Memory.has(p.villagers.v1, "fallout", 1001)
		expect(m.untilT).toBe(1000 + 30 * 60) -- as long as the quarrel runs
		local _, notices = Memory.tick(p, m.untilT + 1)
		-- said once for the two of them
		expect(#notices).toBe(1)
		expect(notices[1]).toBe("Mara and Tobin are talking again.")
		expect(Relationships.quarreling(p, "v1", "v2", m.untilT + 1)).toBe(false)
		-- a band of three takes its break in one line too
		local q = town({ "Mara", "Tobin", "Ivy" })
		for _, vid in q.order do
			Memory.start(q, vid, "band", { name = "Pickle Jar" }, 0)
		end
		local _, said = Memory.tick(q, Tuning.Memory.Days.band * DAY + 1)
		expect(#said).toBe(1)
		expect(said[1]).toBe("Pickle Jar are taking a break from playing.")
	end)

	it("keeps a few at a time, one of each kind, and lists them under Lately", function()
		local p = town({ "Mara" })
		local v = p.villagers.v1
		Memory.start(p, "v1", "accessory", { what = "scarf" }, 100)
		local _, dressed = Memory.start(p, "v1", "accessory", { what = "glasses" }, 200)
		expect(dressed).toBe(true)
		expect(#v.lately).toBe(2) -- the glasses beside the scarf
		expect(v.lately[2].what).toBe("glasses")
		local t = 300
		for _, kind in { "band", "pet", "garden", "penpal", "training", "haircut" } do
			Memory.start(p, "v1", kind, { name = "Pickle Jar", what = if kind == "pet" then "rabbit" else "peas" }, t)
			t += 100
		end
		-- Max of the rest, and what they wear on top (it doesn't count)
		expect(#v.lately).toBe(Tuning.Memory.Max + 2)
		expect(Memory.has(v, "accessory", t).what).toBe("glasses")
		local lately = Memory.lately(p, "v1", t)
		expect(#lately).toBe(Tuning.Memory.Max + 2)
		expect(lately[1].kind).toBe("haircut") -- newest first
		for _, row in lately do
			expect(readable(row.text)).toBe(true)
			if row.stays then
				expect(row.kind).toBe("accessory")
				expect(type(row.what)).toBe("string")
			else
				expect(row.days >= 1).toBe(true)
			end
		end
		local texts = {}
		for _, row in lately do
			texts[row.text] = true
		end
		expect(texts["Plays in a band called Pickle Jar"]).toBe(nil) -- (the band went too)
		expect(texts["Has a rabbit called Pickle Jar"]).toBe(true)
		expect(texts["Training for the harbour race"]).toBe(true)
		expect(texts["Growing peas in a new garden"]).toBe(true)
		-- what can't be one isn't kept
		expect(Memory.start(p, "v1", "accessory", { what = "crown of the sea" }, t)).toBe(nil)
		expect(Memory.start(p, "v1", "fallout", { who = "v1" }, t)).toBe(nil)
		expect(Memory.start(p, "v1", "romance", nil, t)).toBe(nil)
		expect(Memory.start(p, "nobody", "band", { name = "x" }, t)).toBe(nil)
	end)

	it("loads back from a save, dropping what isn't a memory", function()
		local p = town({ "Mara", "Tobin" })
		Memory.start(p, "v1", "band", { name = "Pickle Jar" }, 100)
		local m = Memory.start(p, "v1", "accessory", { what = "scarf" }, 100)
		m.acc = { id = 55, t = "Neck" }
		table.insert(p.villagers.v1.lately, { kind = "dragon", t = 1, untilT = 2 })
		table.insert(p.villagers.v1.lately, "junk")
		p.villagers.v2.lately = "junk"
		p.villagers.v2.flair = { phrase = "Smells like rain to me.", ending = "pal!!", thing = 7 }
		local loaded = Schema.migrate(p)
		expect(#loaded.villagers.v1.lately).toBe(2)
		expect(loaded.villagers.v1.lately[2].acc.id).toBe(55)
		expect(#loaded.villagers.v2.lately).toBe(0)
		expect(loaded.villagers.v2.flair.phrase).toBe("Smells like rain to me.")
		expect(loaded.villagers.v2.flair.ending).toBe("pal")
		expect(loaded.villagers.v2.flair.thing).toBe(nil)
		-- an accessory that isn't one comes off the memory
		local bad = Memory.sanitize(
			p,
			"v1",
			{ { kind = "accessory", what = "scarf", t = 1, untilT = 9, acc = { id = -4, t = "Hat" } } }
		)
		expect(#bad).toBe(1)
		expect(bad[1].acc).toBe(nil)
		-- an old save has none and loads as before
		local old =
			Schema.migrate({ coins = 5, villagers = { a = { name = "Old", pers = "gentle" } }, order = { "a" } })
		expect(#old.villagers.a.lately).toBe(0)
		expect(next(old.villagers.a.flair)).toBe(nil)
	end)
end)
