--!strict
-- Picks the next random event and works out what it does. Pure data in, data out, so the specs
-- can run thousands of events from fixed seeds. Services/Events plays the scenes in the world.
--
-- Effects an event can have ({a}/{b}/{c} name the event's stars; *v forms take villager ids):
--   rel a b d | relv a b d       friendship change
--   mood who d | moodv vid d     mood change
--   coins d                      coins (negative spends)
--   food id n | item id n        inventory
--   quarrel a b | makeup a b     start or end a quarrel
--   request who tag              wants furniture with that tag near their bed
--   sick who minutes             stays in bed
--   xp who d (skill at their job) | known who food r | bday who
-- Handled by the service (returned in `service`):
--   eat who food | away who seconds | visitor name | merchant | festival | creator who? | dayoff who

local Tuning = require(script.Parent.Parent.Config.Tuning)
local Events = require(script.Parent.Parent.Data.Events)
local Relationships = require(script.Parent.Relationships)
local Jobs = require(script.Parent.Parent.Data.Jobs)
local City = require(script.Parent.City)
local Foods = require(script.Parent.Parent.Data.Foods)
local Catalog = require(script.Parent.Parent.Build.Catalog)
local Plan = require(script.Parent.Parent.Build.Plan)
local Text = require(script.Parent.Parent.Util.Text)

local EventEngine = {}

local LETTERS = { "a", "b", "c" }

-- What tags of furniture are within reach of a villager's bed.
function EventEngine.roomTags(profile: any, vid: string): { [string]: boolean }
	local out = {}
	local v = profile.villagers[vid]
	local bed = v and v.bed and profile.plan and profile.plan.items[v.bed]
	if not bed then
		return out
	end
	local radius = Tuning.Villagers.RoomRadius
	for key, item in profile.plan.items do
		if key ~= v.bed then
			local x, z, lv = item.x, item.z, item.lv
			if item.wall then
				local frame = Plan.itemFrame(profile.plan, item)
				if frame then
					x, z = frame.X, frame.Z
				end
			end
			if lv == bed.lv and math.sqrt((x - bed.x) ^ 2 + (z - bed.z) ^ 2) <= radius then
				local def = Catalog.get(item.id)
				if def and def.tags then
					for _, t in def.tags do
						out[t] = true
					end
				end
			end
		end
	end
	return out
end

export type Options = {
	now: number,
	hour: number,
	season: number,
	dayOfSeason: number,
	day: number,
	weather: string,
	rng: any,
	present: { string },
	freeSlots: number,
	merchantActive: boolean?,
}

function EventEngine.context(profile: any, o: Options): any
	local ctx: any = {
		profile = profile,
		now = o.now,
		hour = o.hour,
		season = o.season,
		dayOfSeason = o.dayOfSeason,
		day = o.day,
		weather = o.weather,
		rng = o.rng,
		present = o.present,
		freeSlots = o.freeSlots,
		merchantActive = o.merchantActive == true,
		names = {},
	}
	function ctx.v(vid: string)
		return profile.villagers[vid]
	end
	function ctx.rel(a: string, b: string): number
		return Relationships.peek(profile, a, b)
	end
	function ctx.quarreling(a: string, b: string): boolean
		return Relationships.quarreling(profile, a, b, o.now)
	end
	function ctx.count(foodId: string): number
		return profile.inv.food[foodId] or 0
	end
	function ctx.itemCount(id: string): number
		return profile.inv.items[id] or 0
	end
	function ctx.requests(vid: string): number
		local n = 0
		for _, r in profile.requests do
			if r.vid == vid then
				n += 1
			end
		end
		return n
	end
	function ctx.requestCount(): number
		return #profile.requests
	end
	function ctx.roomHas(vid: string, tag: string): boolean
		return EventEngine.roomTags(profile, vid)[tag] == true
	end
	function ctx.bestScore(vid: string): number
		local best = -100
		for other in profile.villagers do
			if other ~= vid then
				best = math.max(best, Relationships.peek(profile, vid, other))
			end
		end
		return best
	end
	-- the job a villager has, if any: { key, def, job }
	function ctx.job(vid: string): any
		return City.jobOf(profile, vid)
	end
	function ctx.city(): any
		return City.stats(profile)
	end
	function ctx.bdayDone(vid: string): number?
		return profile.bdays and profile.bdays[vid]
	end
	-- fills {a} {b} {c} with the stars' names and any extra words
	function ctx.f(template: string, vars: { [string]: any }?): string
		local all = table.clone(ctx.names)
		local extra: { [string]: any } = vars or {}
		for k, v in extra do
			all[k] = v
		end
		return Text.fill(template, all)
	end
	return ctx
end

function EventEngine.allowedNow(def: any, hour: number): boolean
	local night = hour >= Tuning.Day.NightStart or hour < Tuning.Day.NightEnd
	if def.when == "night" then
		return night
	elseif def.when == "day" then
		return not night
	end
	return true
end

local function setNames(ctx: any, actors: { string })
	ctx.names = {}
	for i, vid in actors do
		local v = ctx.v(vid)
		ctx.names[LETTERS[i]] = if v then v.name else "?"
	end
end

-- Chooses an event and its stars. Returns { id, actors = { a = vid, ... }, scene } or nil.
function EventEngine.pick(ctx: any, recent: { string }?): any
	local rng = ctx.rng
	local present = ctx.present
	local candidates = {}
	for _, def in Events.list do
		if EventEngine.allowedNow(def, ctx.hour) then
			local penalty = if recent and table.find(recent, def.id) then 0.12 else 1
			local tries: { { string } } = {}
			if def.actors == 0 then
				tries = { {} }
			elseif def.actors == 1 then
				for _, vid in present do
					table.insert(tries, { vid })
				end
			elseif def.actors == 2 and #present >= 2 then
				for _ = 1, math.min(14, #present * (#present - 1)) do
					local x = rng:pick(present)
					local y = rng:pick(present)
					if x ~= y then
						table.insert(tries, { x, y })
					end
				end
			elseif def.actors == 3 and #present >= 3 then
				for _ = 1, 10 do
					local s = rng:shuffle(present)
					table.insert(tries, { s[1], s[2], s[3] })
				end
			end
			for _, actors in tries do
				local ok, w = pcall(def.weight, ctx, actors[1], actors[2], actors[3])
				if ok and type(w) == "number" and w > 0 then
					-- spread one event's weight over its tries so events with many pairs don't crowd out the rest
					table.insert(candidates, { def = def, actors = actors, w = w * penalty / #tries })
				end
			end
		end
	end
	local choice = rng:weighted(candidates, function(c)
		return c.w
	end)
	if not choice then
		return nil
	end
	setNames(ctx, choice.actors)
	local scene = choice.def.scene(ctx, choice.actors[1], choice.actors[2], choice.actors[3])
	local actors = {}
	for i, vid in choice.actors do
		actors[LETTERS[i]] = vid
	end
	return { id = choice.def.id, actors = actors, order = choice.actors, scene = scene }
end

-- Applies effects to the profile. Returns notices (strings for the player) and effects the service
-- has to carry out itself.
function EventEngine.apply(profile: any, ev: any, effects: { any }, now: number): ({ string }, { any })
	local notices = {}
	local service = {}
	local function vid(letter: any): string?
		if type(letter) ~= "string" then
			return nil
		end
		return ev.actors[letter]
	end
	local function name(id: string): string
		local v = profile.villagers[id]
		return if v then v.name else "?"
	end
	local function relChange(a: string?, b: string?, d: number)
		if not a or not b or a == b or not profile.villagers[a] or not profile.villagers[b] then
			return
		end
		local _, before, after = Relationships.add(profile, a, b, d)
		if before and after then
			local levelName = Tuning.Relationships.Levels[after].Name
			if after > before then
				table.insert(
					notices,
					Text.fill("{x} and {y} are now {level}.", { x = name(a), y = name(b), level = levelName:lower() })
				)
			else
				table.insert(
					notices,
					Text.fill(
						"{x} and {y} grew apart. They're {level} now.",
						{ x = name(a), y = name(b), level = levelName:lower() }
					)
				)
			end
		end
	end
	local function mood(id: string?, d: number)
		local v = id and profile.villagers[id]
		if v then
			v.mood = math.clamp(v.mood + d, Tuning.Villagers.MoodMin, Tuning.Villagers.MoodMax)
		end
	end
	for _, e in effects do
		local t = e.t
		if t == "rel" then
			relChange(vid(e.a), vid(e.b), e.d)
		elseif t == "relv" then
			relChange(e.a, e.b, e.d)
		elseif t == "mood" then
			mood(vid(e.who), e.d)
		elseif t == "moodv" then
			mood(e.vid, e.d)
		elseif t == "coins" then
			profile.coins = math.clamp(profile.coins + e.d, 0, Tuning.Economy.MaxCoins)
			if e.d > 0 then
				table.insert(notices, Text.fill("+{n} coins", { n = Text.commas(e.d) }))
			end
		elseif t == "food" then
			local f = Foods.get(e.id)
			if f then
				profile.inv.food[e.id] = math.max(0, (profile.inv.food[e.id] or 0) + e.n)
				if profile.inv.food[e.id] == 0 then
					profile.inv.food[e.id] = nil
				end
				if e.n > 0 then
					table.insert(notices, Text.fill("Got {food}", { food = f.name:lower() }))
				end
			end
		elseif t == "item" then
			profile.inv.items[e.id] = math.max(0, (profile.inv.items[e.id] or 0) + e.n)
			if profile.inv.items[e.id] == 0 then
				profile.inv.items[e.id] = nil
			end
		elseif t == "quarrel" then
			local a, b = vid(e.a), vid(e.b)
			if a and b then
				Relationships.quarrel(profile, a, b, now, e.min)
			end
		elseif t == "makeup" then
			local a, b = vid(e.a), vid(e.b)
			if a and b then
				Relationships.makeUp(profile, a, b)
			end
		elseif t == "request" then
			local who = vid(e.who)
			if who then
				local seconds = Tuning.Events.RequestHours * Tuning.Day.Length / 24
				table.insert(profile.requests, { vid = who, tag = e.tag, untilT = now + seconds })
			end
		elseif t == "sick" then
			local v = profile.villagers[vid(e.who) or ""]
			if v then
				v.sick = now + (e.minutes or 5) * 60
			end
		elseif t == "xp" then
			local v = profile.villagers[vid(e.who) or ""]
			if v then
				EventEngine.addXp(v, e.d, notices)
			end
		elseif t == "known" then
			local v = profile.villagers[vid(e.who) or ""]
			if v then
				v.known[e.food] = e.r
			end
		elseif t == "bday" then
			local who = vid(e.who)
			if who then
				profile.bdays = profile.bdays or {}
				profile.bdays[who] = profile.calendarDay or 0
			end
		else
			-- eat, away, visitor, merchant, festival, creator
			local copy = table.clone(e)
			if type(e.who) == "string" then
				copy.vid = vid(e.who)
			elseif type(e.who) == "table" then
				local ids = {}
				for _, letter in e.who do
					local id = vid(letter)
					if id then
						table.insert(ids, id)
					end
				end
				copy.vids = ids
			end
			table.insert(service, copy)
		end
	end
	return notices, service
end

-- Adds XP and handles level ups. Returns how many levels were gained.
function EventEngine.addXp(v: any, amount: number, notices: { string }?): number
	local gained = 0
	v.xp = (v.xp or 0) + amount
	while v.lv < Tuning.Jobs.SkillCap and v.xp >= Jobs.xpToNext(v.lv) do
		v.xp -= Jobs.xpToNext(v.lv)
		v.lv += 1
		gained += 1
	end
	if v.lv >= Tuning.Jobs.SkillCap then
		v.xp = 0
	end
	if gained > 0 and notices then
		table.insert(notices, Text.fill("{x} got better at their work (skill {n}).", { x = v.name, n = v.lv }))
	end
	return gained
end

-- Which choice a timed out event takes, and whether a choice can be afforded.
function EventEngine.choice(scene: any, index: number?, coins: number): (number?, any)
	local choices = scene.choices
	if not choices then
		return nil, nil
	end
	local i = index or scene.default or #choices
	local c = choices[i]
	if not c then
		i = scene.default or #choices
		c = choices[i]
	end
	if c and c.cost and c.cost > coins then
		-- can't afford it: fall back to the last (always free) option
		i = #choices
		c = choices[i]
	end
	return i, c
end

return EventEngine
