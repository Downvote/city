--!nocheck
-- Random events: every event can happen, every line is filled in, every choice resolves,
-- and the numbers stay in range over thousands of seeded runs. No event gives, takes, counts or
-- feeds food or shop things (the user: "remove the shop, buying of things and food and feeding"):
-- a craving is paid for there and then, a cold is seen to by the town's doctor or slept off, and
-- the travelling merchant is gone.
--
-- Then the user: "make much much more random events. custom objects, conversations, etc., just
-- like tomodachi life". So there are well over a hundred and fifty more, and this also checks:
-- every one of them comes up in some town and plays through every answer; no line has a dash,
-- one of the stock words or a hole; few lines shout; every prop an event names exists and builds
-- inside its box; every keepsake it gives is a free Build mode piece; two villagers chatting
-- rarely say the same thing twice; the same event sounds different with a shy villager and a
-- loud one; nothing comes round again too soon.

local Shared = "ReplicatedStorage.Shared."
local Tuning = require(Shared .. "Config.Tuning")
local Events = require(Shared .. "Data.Events")
local EventProps = require(Shared .. "Data.EventProps")
local EventEngine = require(Shared .. "Sim.EventEngine")
local Schema = require(Shared .. "Sim.Schema")
local Relationships = require(Shared .. "Sim.Relationships")
local Life = require(Shared .. "Sim.Life")
local Keepsakes = require(Shared .. "Sim.Keepsakes")
local Personalities = require(Shared .. "Data.Personalities")
local Sayings = require(Shared .. "Data.Sayings")
local Foods = require(Shared .. "Data.Foods")
local Catalog = require(Shared .. "Build.Catalog")
local Geometry = require(Shared .. "Build.Geometry")
local StarterHouse = require(Shared .. "Data.StarterHouse")
local Appearance = require(Shared .. "Avatar.Appearance")
local Rng = require(Shared .. "Util.Rng")

local Chatter = require(Shared .. "Data.Events.Chatter")

-- the events there were before the user asked for many more
local FIRST = {}
for _, id in
	{
		"chat",
		"quarrel",
		"makeup",
		"gift",
		"outing",
		"prank",
		"compliment",
		"armwrestle",
		"cook",
		"secret",
		"race",
		"joke",
		"lost",
		"teach",
		"leftout",
		"craving",
		"wish",
		"request",
		"nobed",
		"dream",
		"coins",
		"cold",
		"hobby",
		"newlook",
		"sleepwalk",
		"practice",
		"lonely",
		"birthday",
		"visitor",
		"festival",
		"stars",
		"storm",
		"shopping",
		"bigday",
		"dayoff",
		"jobhunt",
		"tourist",
		"inspector",
		"crush",
		"confess",
		"date",
		"propose",
	}
do
	FIRST[id] = true
end

local WEATHERS = { "clear", "cloudy", "rain", "storm", "snow", "blossom", "leaves" }

-- every workplace in the catalog, so any job can be somebody's
local WORKPLACES = Catalog.workplaces()

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
	-- and, in some towns, a clinic with a doctor at its desk
	local clinic = rng:chance(0.4)
	if clinic then
		p.plan.items.clinic = { id = "work_clinic", x = 140, y = 0, z = 12, r = 180, lv = 0 }
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
		if i == 3 and clinic then
			v.job = "clinic"
		end
		if i >= 4 and rng:chance(0.6) then
			-- a job of any kind
			local def = rng:pick(WORKPLACES)
			local key = "w" .. i
			p.plan.items[key] = { id = def.id, x = 150 + i * 10, y = 0, z = 12, r = 180, lv = 0 }
			v.job = key
		end
		if rng:chance(0.5) then
			v.hobby = rng:pick(Sayings.hobbies).id
		end
		if rng:chance(0.25) then
			v.memo = { text = "I had a good week, all told.", t = 900 }
		end
		if rng:chance(0.2) then
			v.mood = rng:int(5, 40)
		end
		p.villagers[vid] = v
		table.insert(p.order, vid)
	end
	return p
end

-- A town with everything going on: a quarrel, close friends, a crush, sweethearts and partners.
local function busyTown(rng, count)
	local p = makeProfile(rng, count, rng:chance(0.6))
	if count >= 2 and rng:chance(0.3) then
		Relationships.quarrel(p, "v1", "v2", 1000, 10)
	end
	if count >= 3 and rng:chance(0.4) then
		Relationships.add(p, "v2", "v3", 60)
	end
	if count >= 4 and rng:chance(0.5) then
		Relationships.add(p, "v3", "v4", 85)
		Life.setBond(p, "v3", "v4", rng:pick({ "sweethearts", "partners" }))
	end
	if count >= 6 and rng:chance(0.5) then
		Relationships.add(p, "v5", "v6", 85)
		Life.setBond(p, "v5", "v6", rng:pick({ "sweethearts", "partners" }))
	end
	-- a romance under way: a crush, or sweethearts close enough to propose
	if count == 2 and rng:chance(0.8) then
		Relationships.makeUp(p, "v1", "v2")
		Relationships.add(p, "v1", "v2", 85)
		Life.setBond(p, "v1", "v2", rng:pick({ "crush", "sweethearts", "sweethearts", "partners" }))
	end
	if count >= 3 and rng:chance(0.3) then
		for i = 1, count do
			for j = i + 1, count do
				if rng:chance(0.5) then
					Relationships.add(p, "v" .. i, "v" .. j, rng:int(-30, 70))
				end
			end
		end
	end
	return p
end

local function context(p, rng, opts)
	local first = p.villagers.v1
	return EventEngine.context(p, {
		now = 1000,
		hour = opts.hour or rng:float(0, 24),
		season = opts.season or (if rng:chance(0.5) then first.bday.s else rng:int(1, 4)),
		dayOfSeason = opts.dayOfSeason or (if rng:chance(0.2) then first.bday.d else rng:int(1, 10)),
		day = 5,
		weather = opts.weather or rng:pick(WEATHERS),
		rng = rng,
		present = table.clone(p.order),
		freeSlots = Tuning.Villagers.Max - #p.order,
		friends = if rng:chance(0.5) then { { id = 77, name = "Sam" } } else {},
	})
end

-- what a line may not have (CLAUDE.md, Writing: the user's standing rule)
local BANNED =
	{ "delve", "embark", "unleash", "vibrant", "bustling", "journey", "realm", "tapestry", "seamless", "elevate" }

local function hasHole(s)
	return type(s) == "string" and s:find("{%w+}") ~= nil
end

local shouts, said = 0, 0

local function checkString(s, where)
	if type(s) ~= "string" then
		return
	end
	if hasHole(s) then
		error(where .. ": unfilled text: " .. s)
	end
	if s:find("\u{2014}") or s:find("\u{2013}") or s:find(" %- ") then
		error(where .. ": a dash in: " .. s)
	end
	local lower = s:lower()
	for _, word in BANNED do
		if lower:find("%f[%a]" .. word) then
			error(where .. ": a stock word (" .. word .. ") in: " .. s)
		end
	end
end

local function checkLine(l, where)
	checkString(l.text, where)
	if type(l.text) ~= "string" or #l.text == 0 then
		error(where .. ": an empty line")
	end
	said += 1
	if l.text:find("!") then
		shouts += 1
	end
	if l.who ~= nil and l.who ~= "a" and l.who ~= "b" and l.who ~= "c" then
		error(where .. ": bad speaker " .. tostring(l.who))
	end
end

local function checkText(scene, where)
	checkString(scene.title, where)
	checkString(scene.log, where)
	for _, l in scene.lines do
		checkLine(l, where)
	end
	for _, c in scene.choices or {} do
		checkString(c.text, where)
		if type(c.text) ~= "string" or #c.text == 0 then
			error(where .. ": a choice with no text")
		end
		for _, l in c.lines or {} do
			checkLine(l, where)
		end
	end
end

-- Every effect an event may have (Sim/EventEngine). Nothing here touches a bag of food or things:
-- "food", "item", "eat", "known" and "merchant" went with the shop.
local OPS = {}
for _, t in
	{
		"rel",
		"relv",
		"mood",
		"moodv",
		"coins",
		"quarrel",
		"makeup",
		"request",
		"sick",
		"xp",
		"xpv",
		"bond",
		"hearts",
		"bday",
		"away",
		"visitor",
		"festival",
		"creator",
		"dayoff",
		"keepsake",
		"memo",
		"saying",
		"hobby",
		"leave",
	}
do
	OPS[t] = true
end

local propsSeen, keepsakesSeen = {}, {}

local function checkProps(list, where)
	for _, p in list or {} do
		if not EventProps.get(p.id) then
			error(where .. ": a prop that doesn't exist: " .. tostring(p.id))
		end
		if p.by ~= nil and p.by ~= "a" and p.by ~= "b" and p.by ~= "c" then
			error(where .. ": a prop by nobody: " .. tostring(p.by))
		end
		propsSeen[p.id] = true
	end
end

local function checkOps(scene, where)
	local lists = { scene.effects or {} }
	checkProps(scene.props, where)
	for _, c in scene.choices or {} do
		table.insert(lists, c.effects or {})
		checkProps(c.props, where)
	end
	for _, list in lists do
		for _, e in list do
			if not OPS[e.t] then
				error(where .. ": an effect the game no longer has: " .. tostring(e.t))
			end
			if e.t == "keepsake" then
				if not Keepsakes.isKeepsake(e.item) then
					error(where .. ": a keepsake that isn't one: " .. tostring(e.item))
				end
				keepsakesSeen[e.item] = true
			elseif e.t == "leave" then
				if not EventProps.get(e.prop) or type(e.hours) ~= "number" or e.hours <= 0 then
					error(where .. ": a bad thing to leave about: " .. tostring(e.prop))
				end
				propsSeen[e.prop] = true
			elseif e.t == "memo" then
				checkString(e.text, where)
				expect(#e.text <= 200).toBeTruthy()
			elseif e.t == "saying" then
				expect(Sayings.get(e.id) ~= nil).toBeTruthy()
			elseif e.t == "hobby" then
				expect(Sayings.hobby(e.id) ~= nil).toBeTruthy()
			end
		end
	end
end

local function hasOp(effects, t)
	for _, e in effects or {} do
		if e.t == t then
			return e
		end
	end
	return nil
end

-- plays one answer (or the scene's effects) into the profile and checks what it left
local function settle(p, ev, effects)
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

local cravingPrices = {}
for _, food in Foods.list do
	cravingPrices[Life.cravingPrice(food.id)] = true
end

describe("Event engine", function()
	it("has many more events than it had, each with its own id", function()
		local ids, new = {}, 0
		for _, def in Events.list do
			expect(ids[def.id]).toBe(nil)
			ids[def.id] = true
			if not FIRST[def.id] then
				new += 1
			end
			expect(def.actors).toBeBetween(0, 3)
			expect(def.when == "day" or def.when == "night" or def.when == "any").toBeTruthy()
		end
		for id in FIRST do
			expect(ids[id]).toBe(true)
		end
		expect(new >= 150).toBeTruthy()
	end)

	it("keeps the numbers in range over thousands of random towns", function()
		local seen = {}
		local cravings, coldsSeen, coldsSlept = 0, 0, 0
		for seed = 1, 3000 do
			local rng = Rng.new(seed)
			local count = rng:int(1, 7)
			local p = busyTown(rng, count)
			local ctx = context(p, rng, {})
			local ev = EventEngine.pick(ctx, {})
			if ev then
				seen[ev.id] = true
				checkText(ev.scene, ev.id)
				checkOps(ev.scene, ev.id)
				local scene = ev.scene
				if ev.id == "craving" then
					-- "when a character gets a craving, allow the player to simply pay to buy
					-- it": one answer pays what a craving costs and does a granted wish's good,
					-- the other costs nothing and they sulk. Nothing is given from a bag.
					cravings += 1
					expect(#scene.choices).toBe(2)
					local buy, no = scene.choices[1], scene.choices[2]
					expect(cravingPrices[buy.cost]).toBe(true)
					expect(buy.text:find(tostring(buy.cost), 1, true) ~= nil).toBeTruthy()
					expect(hasOp(buy.effects, "coins").d).toBe(-buy.cost)
					expect(hasOp(buy.effects, "mood").d >= Tuning.Life.WishMood).toBeTruthy()
					expect(hasOp(buy.effects, "hearts").n >= Tuning.Life.WishHearts).toBeTruthy()
					expect(no.cost).toBe(nil)
					expect(hasOp(no.effects, "mood").d < 0).toBeTruthy()
					expect(scene.default).toBe(2)
					-- and never while their craving is already up as a wish
					local wish = p.villagers[ev.actors.a].wish
					expect(wish == nil or wish.kind ~= "food").toBeTruthy()
				elseif ev.id == "cold" then
					-- no medicine to buy: the town's doctor sees to it, or it is slept off
					for _, c in scene.choices do
						expect(c.cost).toBe(nil)
						expect(hasOp(c.effects, "coins")).toBe(nil)
					end
					local doctor = hasOp(scene.choices[1].effects, "xpv")
					if doctor then
						coldsSeen += 1
						expect(doctor.vid ~= ev.actors.a).toBeTruthy()
						expect(p.villagers[doctor.vid].job ~= nil).toBeTruthy()
						expect(hasOp(scene.choices[1].effects, "sick")).toBe(nil)
					else
						coldsSlept += 1
					end
					expect(hasOp(scene.choices[scene.default].effects, "sick") ~= nil).toBeTruthy()
				end
				local effects = scene.effects or {}
				if scene.choices then
					local i, c = EventEngine.choice(scene, rng:int(1, #scene.choices), p.coins)
					expect(i ~= nil).toBeTruthy()
					effects = c.effects
				end
				settle(p, ev, effects)
			end
		end
		-- the rewritten ones came up, a cold both with a doctor in town and without
		expect(cravings > 5).toBeTruthy()
		expect(coldsSeen > 0).toBeTruthy()
		expect(coldsSlept > 0).toBeTruthy()
		-- plenty of different ones came up
		local n = 0
		for _ in seen do
			n += 1
		end
		expect(n >= 120).toBeTruthy()
		-- and the travelling merchant, who made the shop cheaper, is gone with it
		expect(seen.merchant).toBe(nil)
		for _, def in Events.list do
			expect(def.id ~= "merchant").toBeTruthy()
		end
	end)

	it("can play every event, through every answer, in some town", function()
		local missing = {}
		for _, def in Events.list do
			local played = false
			for seed = 1, 600 do
				local rng = Rng.new(seed * 7919 + #def.id)
				local count = if def.actors >= 3 then rng:int(3, 7) else rng:int(math.max(1, def.actors), 7)
				local p = busyTown(rng, count)
				local opts = {}
				-- the hour that suits it
				if def.when == "night" then
					opts.hour = rng:float(Tuning.Day.NightStart, 24)
				elseif def.when == "day" then
					opts.hour = rng:float(Tuning.Day.NightEnd + 0.1, Tuning.Day.NightStart - 0.1)
				end
				local ctx = context(p, rng, opts)
				if EventEngine.allowedNow(def, ctx.hour) then
					local order = rng:shuffle(p.order)
					local stars = {}
					for i = 1, def.actors do
						stars[i] = order[i]
					end
					local ok, w = pcall(def.weight, ctx, stars[1], stars[2], stars[3])
					if not ok then
						error(def.id .. ": its weight failed: " .. tostring(w))
					end
					if w > 0 then
						local ev = EventEngine.stage(ctx, def, stars)
						checkText(ev.scene, def.id)
						checkOps(ev.scene, def.id)
						if ev.scene.choices then
							expect(ev.scene.default).toBeBetween(1, #ev.scene.choices)
							for i in ev.scene.choices do
								-- each answer on a copy of the town
								local copy = busyTown(Rng.new(seed * 7919 + #def.id), count)
								local _, c = EventEngine.choice(ev.scene, i, 1e6)
								settle(copy, ev, c.effects)
							end
						else
							settle(p, ev, ev.scene.effects or {})
						end
						played = true
						break
					end
				end
			end
			if not played then
				table.insert(missing, def.id)
			end
		end
		if #missing > 0 then
			error("never playable: " .. table.concat(missing, ", "))
		end
		-- and hardly anyone shouts (CLAUDE.md: "no exclamation on every line")
		if shouts / said >= 0.12 then
			error(string.format("%d of %d lines shout", shouts, said))
		end
	end)

	it("puts down props that exist, build inside their boxes and turn the right way", function()
		for _, prop in EventProps.list do
			local prims = EventProps.prims(prop.id)
			expect(#prims > 0).toBeTruthy()
			local flat = Geometry.flatten(prims)
			local lo, hi = Geometry.bounds(flat)
			local s, slack = prop.size, 0.6
			if
				lo.X < -s.X / 2 - slack
				or hi.X > s.X / 2 + slack
				or lo.Y < -slack
				or hi.Y > s.Y + slack
				or lo.Z < -s.Z / 2 - slack
				or hi.Z > s.Z / 2 + slack
			then
				error(
					string.format(
						"%s draws outside its size: %s .. %s for %s",
						prop.id,
						tostring(lo),
						tostring(hi),
						tostring(s)
					)
				)
			end
			for _, q in flat do
				local cf = q.cf
				expect(cf.XVector:Cross(cf.YVector):Dot(cf.ZVector) > 0).toBeTruthy()
			end
		end
		-- a Build mode piece can stand in as a prop (the thing they made, before they give it)
		for _, def in Catalog.list("keepsakes") do
			expect(#EventProps.prims("item:" .. def.id) > 0).toBeTruthy()
		end
		expect(EventProps.get("item:nothing")).toBe(nil)
		expect(EventProps.get("nothing")).toBe(nil)
		-- the events between them use most of the props, and give every keepsake
		local used = 0
		for _, prop in EventProps.list do
			if propsSeen[prop.id] then
				used += 1
			end
		end
		expect(used >= #EventProps.list - 2).toBeTruthy()
		for _, def in Catalog.list("keepsakes") do
			if not keepsakesSeen[def.id] then
				-- every keepsake is made in some event
				local made = false
				for _, ev in Events.list do
					if ev.id == def.id:gsub("keep_", "") then
						made = true
					end
				end
				if not made then
					error("no event gives " .. def.id)
				end
			end
		end
	end)

	it("leaves no z-fighting on any prop", function()
		-- (CLAUDE.md, Rules: "No z-fighting"; tools/preview/zfight_lib.luau does the looking)
		local Z = Harness.loadFile("tools/preview/zfight_lib.luau")()
		Z.tag()
		local found = {}
		for _, prop in EventProps.list do
			local out = Z.run({
				scope = "props",
				name = "prop:" .. prop.id,
				build = function()
					return Z.open(EventProps.prims(prop.id)), { supports = {}, group = {} }
				end,
			})
			for _, r in out do
				if r.cls == "near" then
					table.insert(found, prop.id .. ": " .. r.a .. " | " .. r.b)
				end
			end
		end
		Z.untag()
		if #found > 0 then
			error("z-fighting:\n" .. table.concat(found, "\n"))
		end
	end)

	it("lets two neighbours chat without saying the same thing twice", function()
		local rng = Rng.new(42)
		local p = makeProfile(rng, 2, true)
		local scripts, topics = {}, {}
		local runs = 300
		for _ = 1, runs do
			local ctx = context(p, rng, { hour = 12, weather = "clear" })
			local ev = EventEngine.stage(ctx, Events.get("chat"), { "v1", "v2" })
			checkText(ev.scene, "chat")
			local texts = {}
			for _, l in ev.scene.lines do
				table.insert(texts, l.text)
			end
			scripts[table.concat(texts, "|")] = true
			topics[ev.scene.log] = true
		end
		local distinct = 0
		for _ in scripts do
			distinct += 1
		end
		expect(distinct >= runs * 0.9).toBeTruthy()
		-- and a word in passing in the street is made the same way
		local ctx = context(p, rng, { hour = 12 })
		for _ = 1, 50 do
			local small = Chatter.small(ctx, "v1", "v2")
			expect(#small >= 2).toBeTruthy()
			for _, l in small do
				checkString(l.text, "small")
				expect(l.who == "a" or l.who == "b").toBeTruthy()
			end
		end
	end)

	it("plays the same event differently with a shy villager and a loud one", function()
		local function heard(pers)
			local p = Schema.newProfile()
			p.plan = StarterHouse.plan()
			local input = Schema.cleanVillagerInput({ name = "Mo", pers = pers, app = Appearance.default() })
			p.villagers.v1 = Schema.newVillager("v1", input, Rng.new(1))
			p.order = { "v1" }
			local out = {}
			for seed = 1, 20 do
				local ctx = context(p, Rng.new(seed), { hour = 12 })
				local ev = EventEngine.stage(ctx, Events.get("spider"), { "v1" })
				out[ev.scene.lines[2].text] = true
			end
			return out
		end
		local shy, bold = heard("shy"), heard("bold")
		for text in shy do
			expect(bold[text]).toBe(nil)
		end
		-- and every personality has a voice for every kind of reaction the events reach for
		for _, p in Personalities.list do
			for _, kind in
				{
					"hello",
					"happy",
					"sad",
					"angry",
					"thanks",
					"wow",
					"scared",
					"sorry",
					"yes",
					"no",
					"bye",
					"tease",
					"brag",
					"worry",
					"hmm",
					"excited",
					"tired",
					"laugh",
				}
			do
				expect(#(p.lines[kind] or {}) >= 3).toBeTruthy()
				for _, text in p.lines[kind] do
					checkString(text, p.id .. "." .. kind)
				end
			end
		end
	end)

	it("skips a craving for someone whose craving is already up as a wish", function()
		local rng = Rng.new(7)
		local p = makeProfile(rng, 1, true)
		p.villagers.v1.wish = { kind = "food", arg = "apple", untilT = 1e9 }
		for _ = 1, 400 do
			local ctx = EventEngine.context(p, {
				now = 1000,
				hour = 12,
				season = 1,
				dayOfSeason = 99,
				day = 5,
				weather = "clear",
				rng = rng,
				present = { "v1" },
				freeSlots = 0,
			})
			local ev = EventEngine.pick(ctx, {})
			expect(ev == nil or ev.id ~= "craving").toBeTruthy()
		end
	end)

	it("gives skill to a villager by id, for the doctor who saw to a cold", function()
		local rng = Rng.new(3)
		local p = makeProfile(rng, 3, true)
		local v = p.villagers.v3
		v.lv, v.xp = 1, 0
		local notices = EventEngine.apply(p, { actors = { a = "v1" } }, { { t = "xpv", vid = "v3", d = 10 } }, 1000)
		expect(v.xp).toBe(10)
		expect(#notices).toBe(0)
		-- somebody who isn't there is nobody's problem
		EventEngine.apply(p, { actors = { a = "v1" } }, { { t = "xpv", vid = "gone", d = 10 } }, 1000)
		EventEngine.apply(p, { actors = { a = "v1" } }, { { t = "xpv", d = 10 } }, 1000)
	end)

	it("gives keepsakes, memories, sayings and hobbies, and nothing that isn't one", function()
		local rng = Rng.new(5)
		local p = makeProfile(rng, 2, true)
		local ev = { actors = { a = "v1", b = "v2" } }
		local notices = EventEngine.apply(p, ev, { { t = "keepsake", item = "keep_pot", who = "a" } }, 1000)
		expect(p.keepsakes.keep_pot).toBe(1)
		expect(#notices).toBe(1)
		expect(notices[1]:find("V1", 1, true) ~= nil).toBeTruthy()
		-- junk is refused
		EventEngine.apply(p, ev, { { t = "keepsake", item = "sofa_basic", who = "a" } }, 1000)
		EventEngine.apply(p, ev, { { t = "keepsake", item = 42 } }, 1000)
		expect(p.keepsakes.sofa_basic).toBe(nil)
		-- as many as Tuning allows, no more
		for _ = 1, Tuning.Events.KeepsakeMax + 5 do
			EventEngine.apply(p, ev, { { t = "keepsake", item = "keep_bird" } }, 1000)
		end
		expect(p.keepsakes.keep_bird).toBe(Tuning.Events.KeepsakeMax)
		-- a memory to tell, a saying and a hobby of their own
		EventEngine.apply(p, ev, {
			{ t = "memo", who = "b", text = "I won the race." },
			{ t = "saying", who = "a", id = "tea" },
			{ t = "hobby", who = "a", id = "fishing" },
		}, 1000)
		expect(p.villagers.v2.memo.text).toBe("I won the race.")
		expect(p.villagers.v2.memo.t).toBe(1000)
		expect(p.villagers.v1.saying).toBe("tea")
		expect(p.villagers.v1.hobby).toBe("fishing")
		EventEngine.apply(p, ev, {
			{ t = "memo", who = "b", text = string.rep("x", 400) },
			{ t = "saying", who = "a", id = "nonsense" },
			{ t = "hobby", who = "a", id = "nonsense" },
		}, 1000)
		expect(p.villagers.v2.memo.text).toBe("I won the race.")
		expect(p.villagers.v1.saying).toBe("tea")
		expect(p.villagers.v1.hobby).toBe("fishing")
		-- leaving a prop about is the server's to do, with its maker's id
		local _, service = EventEngine.apply(p, ev, { { t = "leave", prop = "snowman", hours = 12, by = "b" } }, 1000)
		expect(service[1].t).toBe("leave")
		expect(service[1].byVid).toBe("v2")
	end)

	it("never brings the same event round again too soon", function()
		local rng = Rng.new(99)
		local p = makeProfile(rng, 5, true)
		local recent = {}
		local soon, kinds = 0, {}
		local picks = 400
		for _ = 1, picks do
			local ctx = context(p, rng, { hour = 12, weather = "clear", season = 2, dayOfSeason = 99 })
			local ev = EventEngine.pick(ctx, recent)
			if ev then
				local at = table.find(recent, ev.id)
				if at and at <= 6 then
					soon += 1
				end
				kinds[ev.id] = true
				table.insert(recent, 1, ev.id)
				while #recent > Tuning.Events.RecentMemory do
					table.remove(recent)
				end
			end
		end
		expect(soon < picks * 0.05).toBeTruthy()
		local n = 0
		for _ in kinds do
			n += 1
		end
		expect(n >= 80).toBeTruthy()
		-- the penalty eases off the further back an event was
		local list = {}
		for i = 1, Tuning.Events.RecentMemory do
			list[i] = "e" .. i
		end
		local last = 0
		for i = 1, Tuning.Events.RecentMemory do
			local w = EventEngine.recentPenalty(list, "e" .. i)
			expect(w >= last).toBeTruthy()
			expect(w).toBeBetween(Tuning.Events.RecentFloor, 1)
			last = w
		end
		expect(EventEngine.recentPenalty(list, "e1")).toBe(Tuning.Events.RecentFloor)
		expect(EventEngine.recentPenalty(list, "other")).toBe(1)
		expect(EventEngine.recentPenalty(nil, "e1")).toBe(1)
	end)

	it("still asks for beds, rooms and jobs often enough among all the new ones", function()
		local rng = Rng.new(11)
		local counts, total = {}, 0
		for seed = 1, 1500 do
			local r = Rng.new(seed)
			local p = makeProfile(r, r:int(2, 6), r:chance(0.5))
			local ctx = context(p, r, { hour = 12 })
			local ev = EventEngine.pick(ctx, {})
			if ev then
				counts[ev.id] = (counts[ev.id] or 0) + 1
				total += 1
			end
		end
		local function share(...)
			local n = 0
			for _, id in { ... } do
				n += counts[id] or 0
			end
			return n / total
		end
		-- the ones that tie into building and work still turn up (a few in a hundred)
		expect(share("request", "nobed", "jobhunt", "craving") > 0.04).toBeTruthy()
		local _ = rng
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

describe("Keepsakes", function()
	it("are free Build mode pieces in their own set", function()
		local list = Catalog.list("keepsakes")
		expect(#list >= 12).toBeTruthy()
		for _, def in list do
			expect(def.price).toBe(0)
			expect(def.tags ~= nil and table.find(def.tags, "keepsake") ~= nil).toBeTruthy()
			expect(Keepsakes.isKeepsake(def.id)).toBe(true)
		end
		expect(Keepsakes.isKeepsake("work_market")).toBe(false)
		expect(Keepsakes.isKeepsake(nil)).toBe(false)
	end)

	it("go down only as many times as they were given, and come back when taken up", function()
		local p = Schema.newProfile()
		p.plan = StarterHouse.plan()
		local add = { type = "add", kind = "items", obj = { id = "keep_pot", x = 10, y = 0, z = 10, r = 0, lv = 0 } }
		-- not given yet
		local ok, why = Keepsakes.check(p, { add })
		expect(ok).toBe(false)
		expect(type(why)).toBe("string")
		expect(#Keepsakes.list(p.keepsakes, p.plan)).toBe(0)
		Keepsakes.give(p, "keep_pot")
		expect((Keepsakes.check(p, { add }))).toBe(true)
		expect((Keepsakes.check(p, { add, add }))).toBe(false)
		-- one down: none left to place
		p.plan.items.k1 = { id = "keep_pot", x = 10, y = 0, z = 10, r = 0, lv = 0 }
		expect(Keepsakes.left(p.keepsakes, p.plan, "keep_pot")).toBe(0)
		expect((Keepsakes.check(p, { add }))).toBe(false)
		local entry = Keepsakes.list(p.keepsakes, p.plan)[1]
		expect(entry.def.id).toBe("keep_pot")
		expect(entry.owned).toBe(1)
		expect(entry.left).toBe(0)
		-- moved in one change (taken up and put down again): fine
		expect((Keepsakes.check(p, { { type = "remove", kind = "items", key = "k1" }, add }))).toBe(true)
		-- taken up or sold: it can go down again
		p.plan.items.k1 = nil
		expect(Keepsakes.left(p.keepsakes, p.plan, "keep_pot")).toBe(1)
		expect((Keepsakes.check(p, { add }))).toBe(true)
		-- other pieces are none of its business, and junk is let through to the Build service's checks
		expect((Keepsakes.check(p, { { type = "add", kind = "items", obj = { id = "sofa_basic" } } }))).toBe(true)
		expect((Keepsakes.check(p, "junk"))).toBe(true)
		expect((Keepsakes.check(p, { 1, 2, { type = "add" } }))).toBe(true)
	end)

	it("load from old saves, and junk in a save is dropped", function()
		local old =
			Schema.migrate({ coins = 50, villagers = { a = { name = "Old", pers = "gentle" } }, order = { "a" } })
		expect(type(old.keepsakes)).toBe("table")
		expect(next(old.keepsakes)).toBe(nil)
		local messy = Schema.migrate({
			coins = 50,
			villagers = {
				a = { name = "Old", pers = "gentle", memo = "not a table" },
				b = { name = "B", pers = "shy", memo = { text = "Hi.", t = 5 } },
			},
			order = { "a", "b" },
			keepsakes = { keep_pot = 2, keep_bird = "lots", sofa_basic = 3, keep_mug = 1e9, keep_quilt = -1 },
		})
		expect(messy.keepsakes.keep_pot).toBe(2)
		expect(messy.keepsakes.keep_bird).toBe(nil)
		expect(messy.keepsakes.sofa_basic).toBe(nil)
		expect(messy.keepsakes.keep_mug).toBe(Tuning.Events.KeepsakeMax)
		expect(messy.keepsakes.keep_quilt).toBe(nil)
		expect(messy.villagers.a.memo).toBe(nil)
		expect(messy.villagers.b.memo.text).toBe("Hi.")
		local broken = Schema.migrate({ coins = 1, villagers = {}, order = {}, keepsakes = "nope" })
		expect(type(broken.keepsakes)).toBe("table")
	end)
end)
