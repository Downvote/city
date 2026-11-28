--!nocheck
-- Events that come back later, events that need a piece in town, names the player types, and what
-- an event puts on a villager. The user, this round:
--   "make events / conversations have follow up ones, such as, for example, villager asks if they
--   should check if they left the stove on, has a chance of villager burning something and coming
--   to you for help" (Sim/FollowUps, Kit's s:follow)
--   "Make more interactions, such as events, conversations and chats that only happen when certain
--   work places are present, like ice cream trucks, whiteboards, etc. things like mailboxes,
--   fridges, etc. can also be present" (Sim/PlotHas, Kit's W{ has }, Data/Events/Things, Sim/Talk's
--   PIECES, Chatter's topics with a `need`)
--   "when things happens that requires mayors to input names like band names or pet names, allow
--   the player to type in what they desire instead of fixed inputs" (Kit's s:askName, Sim/Naming,
--   EventEngine.named)
--   "when villagers equip accessories from random event, the conversation showing it should show
--   it, and it gets taken off only if the player chooses it dosent suit them" (Kit's s:wear and
--   s:takeOff, the suitme event)

local Shared = "ReplicatedStorage.Shared."
local Tuning = require(Shared .. "Config.Tuning")
local Events = require(Shared .. "Data.Events")
local EventEngine = require(Shared .. "Sim.EventEngine")
local FollowUps = require(Shared .. "Sim.FollowUps")
local PlotHas = require(Shared .. "Sim.PlotHas")
local Naming = require(Shared .. "Sim.Naming")
local Memory = require(Shared .. "Sim.Memory")
local Talk = require(Shared .. "Sim.Talk")
local Schema = require(Shared .. "Sim.Schema")
local Relationships = require(Shared .. "Sim.Relationships")
local Catalog = require(Shared .. "Build.Catalog")
local Jobs = require(Shared .. "Data.Jobs")
local Personalities = require(Shared .. "Data.Personalities")
local StarterHouse = require(Shared .. "Data.StarterHouse")
local Appearance = require(Shared .. "Avatar.Appearance")
local Rng = require(Shared .. "Util.Rng")
local Chatter = require(Shared .. "Data.Events.Chatter")

local HOUR = Tuning.Day.Length / 24

-- A town with these villagers and every kind of piece the events look for, or none of them.
local function town(names, opts)
	local o = opts or {}
	local p = Schema.newProfile()
	p.plan = if o.bare then { items = {}, walls = {}, floors = {}, roofs = {}, waters = {} } else StarterHouse.plan()
	if o.everything then
		local k = 0
		for _, need in PlotHas.Kinds do
			local ns = PlotHas.names(need)
			for _, id in ns.ids do
				k += 1
				p.plan.items["e" .. k] = { id = id, x = 10 + k, y = 0, z = 150, r = 0, lv = 0 }
			end
			for _, tag in ns.tags do
				k += 1
				p.plan.items["e" .. k] = { id = Catalog.withTag(tag)[1].id, x = 10 + k, y = 0, z = 140, r = 0, lv = 0 }
			end
			for _, job in ns.jobs do
				for _, def in Catalog.workplaces() do
					if def.job == job then
						k += 1
						p.plan.items["e" .. k] = { id = def.id, x = 10 + k, y = 0, z = 160, r = 0, lv = 0 }
					end
				end
			end
		end
	end
	for i, name in names do
		local pers = (o.pers and o.pers[i]) or Personalities.list[(i - 1) % #Personalities.list + 1].id
		local input = Schema.cleanVillagerInput({ name = name, pers = pers, app = Appearance.default() })
		local vid = "v" .. i
		p.villagers[vid] = Schema.newVillager(vid, input, Rng.new(i))
		table.insert(p.order, vid)
	end
	return p
end

local function context(p, rng, opts)
	local o = opts or {}
	return EventEngine.context(p, {
		now = o.now or 1000,
		hour = o.hour or 12,
		season = o.season or 2,
		dayOfSeason = 3,
		day = 5,
		weather = o.weather or "clear",
		rng = rng,
		present = o.present or table.clone(p.order),
		freeSlots = 5,
	})
end

local function linesOf(scene, c)
	local out = {}
	for _, l in scene.lines do
		table.insert(out, l)
	end
	for _, l in (c and c.lines) or {} do
		table.insert(out, l)
	end
	return out
end

local function hasHole(s)
	return type(s) == "string" and s:find("{%w+}") ~= nil
end

local function findEffect(effects, t, id)
	for _, e in effects or {} do
		if e.t == t and (id == nil or e.id == id) then
			return e
		end
	end
	return nil
end

-- Stages `id` with these stars on fresh seeds until answer `i` leaves `want` waiting. Returns the
-- event and that answer, or nil.
local function untilFollow(p, id, stars, i, want, opts)
	local def = Events.get(id)
	for seed = 1, 400 do
		local ctx = context(p, Rng.new(seed), opts)
		local ok, w = pcall(def.weight, ctx, stars[1], stars[2], stars[3])
		if ok and w > 0 then
			local ev = EventEngine.stage(ctx, def, stars)
			local c = ev.scene.choices and ev.scene.choices[i]
			local effects = if c then c.effects else ev.scene.effects
			if findEffect(effects, "follow", want) then
				return ev, c, effects
			end
		end
	end
	return nil
end

describe("Follow-ups", function()
	it("keep a list of what's waiting, cleaned and capped", function()
		local p = town({ "Mara", "Tobin" })
		expect(FollowUps.add(p, { id = "burntpan", a = "v1", at = 500 }) ~= nil).toBe(true)
		-- the same event for the same villager replaces the one before
		FollowUps.add(p, { id = "burntpan", a = "v1", at = 600 })
		expect(#p.follow).toBe(1)
		expect(p.follow[1].at).toBe(600)
		-- junk isn't kept
		expect(FollowUps.add(p, { id = "x", a = "nobody", at = 1 })).toBe(nil)
		expect(FollowUps.add(p, { id = "x", at = 1 })).toBe(nil)
		expect(FollowUps.add(p, { id = "x", a = "v1", at = 0 / 0 })).toBe(nil)
		expect(FollowUps.add(p, { id = 7, a = "v1", at = 1 })).toBe(nil)
		-- past Max the oldest goes
		for i = 1, Tuning.FollowUps.Max + 2 do
			FollowUps.add(p, { id = "e" .. i, a = "v2", at = 700 + i })
		end
		expect(#p.follow).toBe(Tuning.FollowUps.Max)
		expect(p.follow[#p.follow].id).toBe("e" .. (Tuning.FollowUps.Max + 2))
		-- due ones, oldest first
		local due = FollowUps.due(p, 703.5)
		for k = 2, #due do
			expect(due[k - 1].at <= due[k].at).toBe(true)
		end
		for _, e in due do
			expect(e.at <= 703.5).toBe(true)
		end
		-- and a save keeps them, dropping what can't be one
		table.insert(p.follow, { id = "bad", a = "gone", at = 5 })
		table.insert(p.follow, "junk")
		p.follow[1].w = { dish = "pie", ["no good"] = "x", long = string.rep("a", 99) }
		local loaded = Schema.migrate(p)
		expect(#loaded.follow).toBe(Tuning.FollowUps.Max)
		expect(loaded.follow[1].w.dish).toBe("pie")
		expect(loaded.follow[1].w["no good"]).toBe(nil)
		expect(loaded.follow[1].w.long).toBe(nil)
		local old =
			Schema.migrate({ coins = 5, villagers = { a = { name = "Old", pers = "gentle" } }, order = { "a" } })
		expect(#old.follow).toBe(0)
	end)

	it("plays the stove left on, burnt, with the same villager, when it's due", function()
		-- the user's own example
		local p = town({ "Mara", "Tobin" })
		local ev, c, effects = untilFollow(p, "stoveon", { "v1" }, 2, "burntpan")
		expect(ev ~= nil).toBe(true)
		expect(c.text).toBe("I'm sure it's off.")
		-- going to check leaves nothing
		for _, e in ev.scene.choices[1].effects do
			expect(e.t ~= "follow").toBe(true)
		end
		EventEngine.apply(p, ev, effects, 1000)
		expect(#p.follow).toBe(1)
		local f = p.follow[1]
		expect(f.id).toBe("burntpan")
		expect(f.a).toBe("v1")
		expect(f.from).toBe("stoveon")
		expect(f.at).toBeNear(1000 + 2 * HOUR, 0.01)
		-- not before it's due: whatever comes is something else, and it stays waiting
		local early = EventEngine.pick(context(p, Rng.new(3), { now = 1001 }), {})
		expect(early == nil or early.id ~= "burntpan").toBe(true)
		expect(#p.follow).toBe(1)
		-- due, but Mara isn't about: it waits
		local away = EventEngine.pick(context(p, Rng.new(4), { now = f.at + 1, present = { "v2" } }), {})
		expect(away == nil or away.id ~= "burntpan").toBe(true)
		expect(#p.follow).toBe(1)
		-- due and she's here: it comes first, with her, and is off the list
		local due = EventEngine.pick(context(p, Rng.new(5), { now = f.at + 1 }), {})
		expect(due.id).toBe("burntpan")
		expect(due.actors.a).toBe("v1")
		expect(due.from).toBe("stoveon")
		expect(#p.follow).toBe(0)
		-- and one nobody could play is let go in the end
		FollowUps.add(p, { id = "burntpan", a = "v1", at = 2000 })
		EventEngine.pick(context(p, Rng.new(6), { now = 2000 + Tuning.FollowUps.Expire + 1, present = { "v2" } }), {})
		expect(#p.follow).toBe(0)
	end)

	it("never picks an event that only comes as a follow-up by chance", function()
		local p = town({ "Mara", "Tobin", "Ivy" }, { everything = true })
		for seed = 1, 400 do
			local ev = EventEngine.pick(context(p, Rng.new(seed), { hour = 12 + (seed % 10) }), {})
			if ev then
				expect(Events.get(ev.id).followup).toBe(nil)
			end
		end
	end)

	it("has at least ten chains, each playing with the same villagers and the words it carries", function()
		local chains = {
			{ "stoveon", 2, "burntpan" },
			{ "fridgepudding", 1, "puddingback", 2 },
			{ "mailboxwait", 1, "parcelcame" },
			{ "pianotune", 1, "pianoshow" },
			{ "arcadescore", 1, "arcadebeaten" },
			{ "beesting", 1, "honeycake" },
			{ "bikeflat", 1, "bikeride" },
			{ "wishingwell", 1, "wishcame" },
			{ "outfit", 1, "suitme" },
			{ "haircut", 2, "hatoff" },
			{ "spider", 1, "spiderback" },
			{ "nameplant", 1, "ferngrows" },
			{ "pigeon", 1, "pigeonback" },
			{ "band", 1, "gig", 3 },
			{ "stray", 1, "petnews" },
		}
		expect(#chains >= 10).toBe(true)
		for _, chain in chains do
			local first, answer, next, actors = chain[1], chain[2], chain[3], chain[4] or 1
			local names = { "Mara", "Tobin", "Ivy" }
			local p = town(names, { everything = true })
			if first == "fridgepudding" or first == "band" then
				Relationships.add(p, "v1", "v2", 30)
			end
			local stars = {}
			for i = 1, actors do
				stars[i] = "v" .. i
			end
			local hour = if Events.get(first).when == "night" then 22 else 12
			local ev, _, effects = untilFollow(p, first, stars, answer, next, { hour = hour, season = 1 })
			if not ev then
				error(first .. " never leaves " .. next .. " waiting")
			end
			local notices = EventEngine.apply(p, ev, effects, 1000)
			for _, n in notices do
				expect(hasHole(n)).toBe(false)
			end
			local f = nil
			for _, e in p.follow do
				if e.id == next then
					f = e
				end
			end
			expect(f ~= nil).toBe(true)
			local laterHour = if Events.get(next).when == "night" then 22 else 12
			local due = nil
			for seed = 1, 30 do
				due = EventEngine.pick(context(p, Rng.new(seed), { now = f.at + 1, hour = laterHour, season = 1 }), {})
				if due and due.id == next then
					break
				end
				-- (it stays waiting when the time isn't right for it)
				FollowUps.add(p, f)
			end
			if not due or due.id ~= next then
				error(first .. " -> " .. next .. " never came")
			end
			expect(due.actors.a).toBe(ev.actors.a)
			-- every line filled, the carried words too
			for _, l in linesOf(due.scene) do
				if hasHole(l.text) then
					error(next .. ": a hole in " .. l.text)
				end
			end
			for _, c in due.scene.choices or {} do
				for _, l in c.lines do
					if hasHole(l.text) then
						error(next .. ": a hole in " .. l.text)
					end
				end
			end
		end
	end)

	it("carries the name typed in the first event into the next", function()
		local p = town({ "Mara" })
		local ev = EventEngine.stage(context(p, Rng.new(2)), Events.get("nameplant"), { "v1" })
		EventEngine.named(ev, "Frondella")
		local c = ev.scene.choices[1]
		local f = findEffect(c.effects, "follow", "ferngrows")
		for seed = 3, 80 do
			if f then
				break
			end
			ev = EventEngine.stage(context(p, Rng.new(seed)), Events.get("nameplant"), { "v1" })
			EventEngine.named(ev, "Frondella")
			c = ev.scene.choices[1]
			f = findEffect(c.effects, "follow", "ferngrows")
		end
		expect(f.w.plant).toBe("Frondella")
		EventEngine.apply(p, ev, c.effects, 1000)
		local due = EventEngine.pick(context(p, Rng.new(1), { now = p.follow[1].at + 1 }), {})
		expect(due.id).toBe("ferngrows")
		local text = ""
		for _, l in due.scene.lines do
			text ..= l.text .. " "
		end
		expect(text:find("Frondella", 1, true) ~= nil).toBe(true)
	end)
end)

describe("Events that need a piece in town", function()
	local function needOf(def)
		return def.need
	end

	it("are at least twenty, each naming pieces that exist", function()
		local n = 0
		for _, def in Events.list do
			local need = needOf(def)
			if need then
				n += 1
				local names = PlotHas.names(need)
				for _, id in names.ids do
					if not Catalog.get(id) then
						error(def.id .. " needs a piece that isn't in the catalog: " .. id)
					end
				end
				for _, tag in names.tags do
					expect(#Catalog.withTag(tag) > 0).toBe(true)
				end
				for _, job in names.jobs do
					expect(Jobs.get(job) ~= nil).toBe(true)
				end
			end
		end
		expect(n >= 20).toBe(true)
		-- every named kind is real too
		for kind, need in PlotHas.Kinds do
			local names = PlotHas.names(need)
			for _, id in names.ids do
				if not Catalog.get(id) then
					error("PlotHas.Kinds." .. kind .. " names a piece that isn't in the catalog: " .. id)
				end
			end
			for _, job in names.jobs do
				expect(Jobs.get(job) ~= nil).toBe(true)
			end
		end
	end)

	it("never happen without their piece, and can with it", function()
		local names = { "Mara", "Tobin", "Ivy" }
		local bare = town(names, { bare = true })
		local full = town(names, { everything = true })
		-- the second and third have every job, for the events about someone at work
		local workKeys = {}
		for key, item in full.plan.items do
			local def = Catalog.get(item.id)
			if def and def.job then
				workKeys[def.job] = key
			end
		end
		local orders = { { "v1", "v2", "v3" }, { "v2", "v1", "v3" }, { "v3", "v2", "v1" } }
		for _, def in Events.list do
			if needOf(def) then
				local played = false
				for seed = 1, 60 do
					local rng = Rng.new(seed)
					for _, vid in full.order do
						full.villagers[vid].job = nil
					end
					local jobs = {}
					for job in workKeys do
						table.insert(jobs, job)
					end
					table.sort(jobs)
					full.villagers.v1.job = workKeys[jobs[(seed % #jobs) + 1]]
					full.villagers.v2.job = workKeys[jobs[((seed + 3) % #jobs) + 1]]
					local hour = if def.when == "night" then 22 else 12
					local cf = context(full, rng, { hour = hour, season = (seed % 4) + 1 })
					local cb = context(bare, rng, { hour = hour, season = (seed % 4) + 1 })
					for _, o in orders do
						local wb = def.weight(cb, o[1], o[2], o[3])
						if wb ~= 0 then
							error(def.id .. " can happen with no " .. tostring(def.id) .. " piece in town")
						end
						if def.weight(cf, o[1], o[2], o[3]) > 0 then
							played = true
						end
					end
				end
				if not played then
					error(def.id .. " never happens even with its piece in town")
				end
			end
		end
	end)

	it("give the talk card lines about a piece only where there is one", function()
		local kinds = 0
		for kind, map in Talk.Pieces do
			kinds += 1
			expect(PlotHas.Kinds[kind] ~= nil).toBe(true)
			expect(type(map._)).toBe("string")
			for pers, text in map do
				expect(pers == "_" or Personalities.get(pers) ~= nil).toBe(true)
				expect(text:find("\u{2014}") == nil and text:find(" %- ") == nil).toBe(true)
				expect(text:find("{", 1, true)).toBe(nil)
			end
		end
		expect(kinds >= 15).toBe(true)
		-- what they say in a town with nothing, and in one with everything
		local function heard(p)
			local out = {}
			for seed = 1, 300 do
				out[Talk.line(p, "v1", Rng.new(seed), { now = 1000 })] = true
			end
			return out
		end
		local all = {}
		for _, map in Talk.Pieces do
			for _, text in map do
				all[text] = true
			end
		end
		local function about(said)
			local n = 0
			for text in said do
				for line in all do
					-- (said in their own hand: compare the words)
					if text:lower():gsub("[^%a]", "") == line:lower():gsub("[^%a]", "") then
						n += 1
					end
				end
			end
			return n
		end
		expect(about(heard(town({ "Mara" }, { bare = true })))).toBe(0)
		expect(about(heard(town({ "Mara" }, { everything = true }))) > 3).toBe(true)
	end)

	it("give two neighbours things to talk about only where there's something there", function()
		local needing = 0
		for _, t in Chatter.Topics do
			if t.need then
				needing += 1
				expect(PlotHas.Kinds[t.need] ~= nil).toBe(true)
			end
		end
		expect(needing >= 5).toBe(true)
		local bare = town({ "Mara", "Tobin" }, { bare = true })
		local full = town({ "Mara", "Tobin" }, { everything = true })
		for _, t in Chatter.topics(context(bare, Rng.new(1))) do
			expect(t.need).toBe(nil)
		end
		expect(#Chatter.topics(context(full, Rng.new(1)))).toBe(#Chatter.Topics)
		-- the street's chats, with a `has` of their own
		local streetCtx = {
			rng = Rng.new(2),
			v = function(id)
				return full.villagers[id]
			end,
			rel = function()
				return 10
			end,
			has = function(need)
				return PlotHas.has(full, need)
			end,
		}
		expect(#Chatter.topics(streetCtx)).toBe(#Chatter.Topics)
		streetCtx.has = nil
		for _, t in Chatter.topics(streetCtx) do
			expect(t.need).toBe(nil)
		end
	end)
end)

describe("Names the player types", function()
	it("cleans what was typed, and says why when it won't do", function()
		expect(Naming.clean("  pickle   jar  ")).toBe("Pickle jar")
		expect(Naming.clean("Mr Fins")).toBe("Mr Fins")
		expect(Naming.clean("O'Malley")).toBe("O'Malley")
		expect(Naming.clean("Café Noir")).toBe("Café Noir")
		for _, bad in
			{
				"",
				"   ",
				"a",
				"{a}",
				"x|y",
				"<b>Bold</b>",
				"###",
				"aaaaaaa",
				"www.site.com",
				"Big!",
				string.rep("long", 8),
				"zero\u{200B}width",
				7,
				nil,
			}
		do
			local ok, why = Naming.clean(bad)
			expect(ok).toBe(nil)
			expect(type(why)).toBe("string")
		end
		local long = string.sub(string.rep("Bo", Tuning.Naming.Max), 1, Tuning.Naming.Max)
		expect(Naming.clean(long)).toBe(long)
		expect(Naming.clean(long .. "x")).toBe(nil)
	end)

	it("asks for a name with a box where the band, the pets and the fern are named", function()
		local naming = { band = 3, stray = 1, foundpet = 1, pigeon = 1, nameplant = 1, pondfish = 1 }
		for id, actors in naming do
			local def = Events.get(id)
			local p = town({ "Mara", "Tobin", "Ivy" }, { everything = true })
			local stars = {}
			for i = 1, actors do
				stars[i] = "v" .. i
			end
			local ev = nil
			for seed = 1, 200 do
				local ctx = context(p, Rng.new(seed))
				if def.weight(ctx, stars[1], stars[2], stars[3]) > 0 then
					ev = EventEngine.stage(ctx, def, stars)
					break
				end
			end
			if not ev then
				error(id .. " never staged")
			end
			local ask = ev.scene.name
			expect(type(ask)).toBe("table")
			expect(#ev.scene.choices).toBe(1)
			expect(ev.scene.choices[1].text).toBe(ask.suggest)
			expect(ask.ask:find("?", 1, true) ~= nil).toBe(true)
			-- the suggestion is in what follows
			local function said(c)
				local out = ""
				for _, l in c.lines do
					out ..= l.text .. " "
				end
				for _, e in c.effects do
					out ..= (e.text or "") .. (e.name or "") .. " "
				end
				return out
			end
			local before = ev.scene.choices[1]
			expect(said(before):lower():find(ask.suggest:lower(), 1, true) ~= nil).toBe(true)
			-- and what was typed takes its place, everywhere it went
			local c = EventEngine.named(ev, "Zebedee")
			expect(ev.scene.choices[1]).toBe(c)
			expect(c.text).toBe("Zebedee")
			local text = said(c)
			expect(text:lower():find("zebedee", 1, true) ~= nil).toBe(true)
			expect(text:find(ask.suggest, 1, true)).toBe(nil)
			for _, l in c.lines do
				expect(hasHole(l.text)).toBe(false)
			end
			-- what every answer does comes with it, the same as before
			expect(#c.effects).toBe(#before.effects)
			EventEngine.apply(p, ev, c.effects, 1000)
			local v = p.villagers.v1
			local m = Memory.has(v, "band", 1001) or Memory.has(v, "pet", 1001)
			if id == "band" then
				expect(m.name).toBe("Zebedee")
				expect(Memory.has(p.villagers.v3, "band", 1001).name).toBe("Zebedee")
			elseif id ~= "pigeon" and id ~= "nameplant" then
				expect(m.name).toBe("Zebedee")
			end
		end
		-- a scene that asks no name can't be given one
		local p = town({ "Mara" })
		local ev = EventEngine.stage(context(p, Rng.new(1)), Events.get("spider"), { "v1" })
		expect(EventEngine.named(ev, "Zebedee")).toBe(nil)
	end)

	it("says the typed name in the villager's own hand", function()
		local p = town({ "Mara" }, { pers = { "cheeky" }, everything = true })
		local ev = nil
		for seed = 1, 100 do
			local ctx = context(p, Rng.new(seed))
			if Events.get("pondfish").weight(ctx, "v1") > 0 then
				ev = EventEngine.stage(ctx, Events.get("pondfish"), { "v1" })
				break
			end
		end
		local c = EventEngine.named(ev, "Captain Bob")
		for _, l in c.lines do
			-- cheeky writes all in lower case (Sim/Voice), the name too
			expect(l.text).toBe(l.text:lower())
		end
	end)
end)

describe("What an event puts on them", function()
	it("goes on with the first message they put it on with, and stays", function()
		local p = town({ "Mara" })
		local ev = EventEngine.stage(context(p, Rng.new(1)), Events.get("outfit"), { "v1" })
		local c = ev.scene.choices[1]
		local wearing = {}
		for i, l in c.lines do
			if l.wear then
				table.insert(wearing, i)
				expect(l.who).toBe("a")
				expect(l.wear).toBe("yellowhat")
			end
		end
		expect(#wearing).toBe(1)
		expect(wearing[1]).toBe(1)
		EventEngine.apply(p, ev, c.effects, 1000)
		local m = Memory.has(p.villagers.v1, "accessory", 1000 + 100 * Tuning.Day.Length)
		expect(m.what).toBe("yellowhat")
	end)

	it("comes off only when the player says it doesn't suit them", function()
		local p = town({ "Mara" })
		Memory.start(p, "v1", "accessory", { what = "scarf" }, 900)
		Memory.start(p, "v1", "accessory", { what = "strawhat" }, 950)
		local def = Events.get("suitme")
		local ctx = context(p, Rng.new(1))
		expect(def.weight(ctx, "v1") > 0).toBe(true)
		-- as a follow-up it asks about the one the earlier event put on
		ctx.carried = { worn = "scarf" }
		local ev = EventEngine.stage(ctx, def, { "v1" })
		ctx.carried = nil
		expect(ev.scene.title).toBe("Does it suit me?")
		local text = ""
		for _, l in ev.scene.lines do
			text ..= l.text
		end
		expect(text:find("stripy scarf", 1, true) ~= nil).toBe(true)
		-- it suits them: nothing comes off
		local _, service = EventEngine.apply(p, ev, ev.scene.choices[1].effects, 1000)
		expect(#Memory.all(p.villagers.v1, "accessory", 1001)).toBe(2)
		expect(#service).toBe(0)
		-- it doesn't: that one comes off, the hat stays, and the server is told to dress them
		local _, service2 = EventEngine.apply(p, ev, ev.scene.choices[2].effects, 1000)
		local on = Memory.all(p.villagers.v1, "accessory", 1001)
		expect(#on).toBe(1)
		expect(on[1].what).toBe("strawhat")
		expect(findEffect(service2, "dress") ~= nil).toBe(true)
		-- with nothing on, it can't come up
		Memory.forget(p, "v1", "accessory")
		expect(def.weight(context(p, Rng.new(2)), "v1")).toBe(0)
	end)
end)
