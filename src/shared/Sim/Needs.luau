--!strict
-- What a villager needs, and how happy it lets them be. Pure data in and out, so the specs can run
-- it; the server's Services/Villagers moves mood with it every town hour, the events and the talk
-- card lift it through it, and the villager page shows its list (UI/Residents' Mood tab).
--
-- The user: "Villager mood bars should also not be that easy to fill up, the factors affecting it
-- should be: amount and relationship of friends, quality of bed, roof over bed, fun objects near
-- bed. Villagers will ask for these if they are not fufilled." So mood is earned. Each thing they
-- have adds its points to the most their mood can reach (Needs.cap), and the points add up to
-- Tuning.Villagers.MoodMax with everything in place (Tuning.Needs):
--   (Base)   a little anybody has
--   bed      a bed of their own
--   comfy    how good that bed is, by its price in Build mode
--   roof     a roof over the bed, or a floor above it
--   fun      fun pieces near the bed: the Fun tab's, or anything for games, toys, music or a TV
--   friends  how many friends they have and how close, each other villager counted by level
-- Mood climbs to the cap a little each town hour and sinks to it when it is over (the bed sold, a
-- friend fallen out): Needs.drift. What happens to them (events, gifts, granted wishes, chats)
-- still moves it, but a lift counts for less than it says and never goes past the cap; a knock
-- counts in full (Needs.addMood).
--
-- They ask for what they lack (the user: "if a villager dosent have a workspace or bed, they will
-- ask the player for it ... The end of these dialogues should be "Villagers need an x to y. Build it
-- in Build mode > z""): Needs.ask says what a villager would ask for first, Needs.line the line the
-- ask ends on (Data/Events/Needs plays the asks).

local Tuning = require(script.Parent.Parent.Config.Tuning)
local Catalog = require(script.Parent.Parent.Build.Catalog)
local Plan = require(script.Parent.Parent.Build.Plan)
local Relationships = require(script.Parent.Relationships)
local City = require(script.Parent.City)
local Tutorial = require(script.Parent.Tutorial)

local N = Tuning.Needs
local V = Tuning.Villagers

local Needs = {}

-- The factors, in the order the villager page lists them.
Needs.Factors = { "bed", "comfy", "roof", "fun", "friends" }

-- What a villager may ask for, in the order they ask: a bed and work first, then what their mood
-- lacks.
Needs.Asks = { "bed", "work", "roof", "comfy", "fun", "friends" }

-- How each ask ends, and where to get it. The paths are Build mode's own groups and tabs
-- (client Build/BuildUI's GROUPS) and the quick menu's tiles (UI/Hud); the Needs spec checks them.
local LINES = {
	bed = "Villagers need a bed to sleep in. Build it in Build mode > Furniture > Beds",
	work = "Villagers need a workplace to earn coins. Build it in Build mode > Work",
	roof = "Villagers need a roof over their bed to sleep well. Build it in Build mode > Build > Roofs",
	comfy = "Villagers need a comfy bed to sleep well. Build it in Build mode > Furniture > Beds",
	fun = "Villagers need something fun near their bed to relax. Build it in Build mode > Furniture > Fun",
	friends = "Villagers need friends to be happy. Make more villagers in Create",
	introduce = "Villagers need friends to be happy. Introduce them in Villagers",
}
Needs.Lines = LINES

-- What a fun piece is for: these tags, or a piece on the Fun tab.
local FUN_TAGS = { games = true, toy = true, music = true, tv = true }

-- The bed a villager sleeps in, on the plan: its key, the item and its piece. Nil without one.
function Needs.bedOf(profile: any, vid: string): (string?, any, any)
	local v = profile.villagers and profile.villagers[vid]
	local key = v and v.bed
	local plan = profile.plan
	local item = if type(key) == "string"
			and type(plan) == "table"
			and type(plan.items) == "table"
		then plan.items[key]
		else nil
	local def = item and Catalog.get(item.id)
	if not def or not Catalog.hasTag(def, "bed") then
		return nil, nil, nil
	end
	return key, item, def
end

-- How comfy a bed is: the step of Tuning.Needs.Comfy its price reaches (1 is plain) and its points.
function Needs.comfy(def: any): (number, number)
	local step, points = 1, 0
	local price = if def and type(def.price) == "number" then def.price else 0
	for i, s in N.Comfy do
		if price >= s.Price then
			step, points = i, s.Points
		end
	end
	return step, points
end

local function inside(x: number, z: number, o: any): boolean
	if type(o.x1) ~= "number" or type(o.x2) ~= "number" or type(o.z1) ~= "number" or type(o.z2) ~= "number" then
		return false
	end
	return x >= math.min(o.x1, o.x2)
		and x <= math.max(o.x1, o.x2)
		and z >= math.min(o.z1, o.z2)
		and z <= math.max(o.z1, o.z2)
end

-- Is there a roof over this item (one on its own storey or higher), or a floor on a storey above
-- it, over the middle of it?
function Needs.covered(plan: any, item: any): boolean
	if type(plan) ~= "table" or type(item) ~= "table" or type(item.x) ~= "number" or type(item.z) ~= "number" then
		return false
	end
	local lv = if type(item.lv) == "number" then item.lv else 0
	for _, r in plan.roofs or {} do
		if type(r) == "table" and type(r.lv) == "number" and r.lv >= lv and inside(item.x, item.z, r) then
			return true
		end
	end
	for _, f in plan.floors or {} do
		if type(f) == "table" and type(f.lv) == "number" and f.lv > lv and inside(item.x, item.z, f) then
			return true
		end
	end
	return false
end

-- Is this piece a fun one?
function Needs.isFun(def: any): boolean
	if not def then
		return false
	end
	if def.cat == "fun" then
		return true
	end
	for _, t in def.tags or {} do
		if FUN_TAGS[t] then
			return true
		end
	end
	return false
end

-- How many fun pieces stand near a villager's bed: on its storey, within Tuning.Villagers.RoomRadius
-- (what hangs on a wall by where it hangs).
function Needs.funNear(profile: any, vid: string): number
	local key, bed = Needs.bedOf(profile, vid)
	if not key or not bed then
		return 0
	end
	local n = 0
	for other, item in profile.plan.items do
		if other ~= key and type(item) == "table" then
			local def = Catalog.get(item.id)
			if def and Needs.isFun(def) then
				local x, z = item.x, item.z
				if item.wall then
					local frame = Plan.itemFrame(profile.plan, item)
					if frame then
						x, z = frame.X, frame.Z
					end
				end
				if
					item.lv == bed.lv
					and type(x) == "number"
					and type(z) == "number"
					and math.sqrt((x - bed.x) ^ 2 + (z - bed.z) ^ 2) <= V.RoomRadius
				then
					n += 1
				end
			end
		end
	end
	return n
end

-- A villager's friends: the points they come to (each other villager by how close they are, up to
-- FriendsMax), how many are friends or closer, and how many they only know to say hello to.
function Needs.friends(profile: any, vid: string): (number, number, number)
	local points, friends, known = 0, 0, 0
	if type(profile.rel) ~= "table" then
		return points, friends, known
	end
	for other in profile.villagers or {} do
		if other ~= vid then
			local level = Relationships.level(Relationships.peek(profile, vid, other))
			points += N.FriendPoints[level] or 0
			if level >= 5 then
				friends += 1
			elseif level == 4 then
				known += 1
			end
		end
	end
	return math.min(points, N.FriendsMax), friends, known
end

-- Every factor as the villager page shows it: { id, points, max, have } in Needs.Factors' order,
-- with what it is in words (`text`: "Single bed", "2 friends") and, for the bed, its comfort step.
export type Factor = { id: string, points: number, max: number, have: boolean, text: string, step: number? }
function Needs.factors(profile: any, vid: string): { Factor }
	local key, bed, def = Needs.bedOf(profile, vid)
	local out: { Factor } = {}
	table.insert(out, {
		id = "bed",
		points = if key then N.Bed else 0,
		max = N.Bed,
		have = key ~= nil,
		text = if def then def.name else "No bed",
	})
	local step, comfy = Needs.comfy(def)
	local maxComfy = N.Comfy[#N.Comfy].Points
	table.insert(out, {
		id = "comfy",
		points = if key then comfy else 0,
		max = maxComfy,
		have = key ~= nil and comfy >= N.ComfyWant,
		text = if not key then "No bed" else ({ "Plain", "Comfy", "Very comfy", "Luxury" })[step] or "Comfy",
		step = if key then step else nil,
	})
	local roofed = key ~= nil and Needs.covered(profile.plan, bed)
	table.insert(out, {
		id = "roof",
		points = if roofed then N.Roof else 0,
		max = N.Roof,
		have = roofed,
		text = if roofed then "Roof over it" elseif key then "Out in the open" else "No bed",
	})
	local fun = Needs.funNear(profile, vid)
	table.insert(out, {
		id = "fun",
		points = math.min(fun * N.FunEach, N.FunMax),
		max = N.FunMax,
		have = fun >= N.FunWant,
		text = if not key
			then "No bed"
			elseif fun == 1 then "1 thing"
			elseif fun > 1 then fun .. " things"
			else "Nothing yet",
	})
	local points, friends, known = Needs.friends(profile, vid)
	local words = "Nobody yet"
	if friends == 1 then
		words = "1 friend"
	elseif friends > 1 then
		words = friends .. " friends"
	elseif known > 0 then
		words = "Getting to know people"
	end
	table.insert(out, {
		id = "friends",
		points = points,
		max = N.FriendsMax,
		have = points >= N.FriendsWant,
		text = words,
	})
	return out
end

-- The most a villager's mood can reach with what they have: Base and every factor's points.
function Needs.cap(profile: any, vid: string): number
	local total = N.Base
	for _, f in Needs.factors(profile, vid) do
		total += f.points
	end
	return math.clamp(total, V.MoodMin, V.MoodMax)
end

-- What a lift of `d` counts for now: BoostShare of it, at least 1. A knock (d < 0) counts in full.
function Needs.lift(d: number): number
	if d <= 0 then
		return d
	end
	return math.max(1, math.floor(d * N.BoostShare + 0.5))
end

-- Moves a villager's mood by `d` for something that happened (an event, a gift, a wish, a chat):
-- a lift counts for Needs.lift(d) and stops at their cap (one already over it gains nothing), a
-- knock counts in full down to MoodMin. Returns the change made.
function Needs.addMood(profile: any, vid: string, d: number): number
	local v = profile.villagers and profile.villagers[vid]
	if not v or type(d) ~= "number" or d ~= d or d == 0 then
		return 0
	end
	local before = if type(v.mood) == "number" and v.mood == v.mood then v.mood else V.StartMood
	local after = before
	if d > 0 then
		local cap = Needs.cap(profile, vid)
		if before < cap then
			after = math.min(cap, before + Needs.lift(d))
		end
	else
		after = before + d
	end
	v.mood = math.clamp(after, V.MoodMin, V.MoodMax)
	return v.mood - before
end

-- An hour or `hours` of town life: each villager's mood climbs toward their cap (Rise an hour) or
-- sinks to it (Fall an hour). Returns whether anyone's mood changed.
function Needs.drift(profile: any, hours: number?): boolean
	local h = hours or 1
	local changed = false
	for vid, v in profile.villagers or {} do
		local mood = if type(v.mood) == "number" and v.mood == v.mood then v.mood else V.StartMood
		local cap = Needs.cap(profile, vid)
		local after = mood
		if mood < cap then
			after = math.min(cap, mood + N.Rise * h)
		elseif mood > cap then
			after = math.max(cap, mood - N.Fall * h)
		end
		after = math.clamp(after, V.MoodMin, V.MoodMax)
		if after ~= v.mood then
			v.mood = after
			changed = true
		end
	end
	return changed
end

-- Everything a villager would ask for, in Needs.Asks' order: "bed" with no bed, "work" with no
-- workplace, then "roof", "comfy", "fun" and "friends" while their factor is short of what is
-- wanted (the last three only once they have a bed).
function Needs.missing(profile: any, vid: string): { string }
	local v = profile.villagers and profile.villagers[vid]
	if not v then
		return {}
	end
	local out = {}
	local key = Needs.bedOf(profile, vid)
	if not key then
		table.insert(out, "bed")
	end
	if not City.jobOf(profile, vid) then
		table.insert(out, "work")
	end
	if key then
		local have = {}
		for _, f in Needs.factors(profile, vid) do
			have[f.id] = f.have
		end
		for _, id in { "roof", "comfy", "fun", "friends" } do
			if not have[id] then
				table.insert(out, id)
			end
		end
	end
	return out
end

-- What a villager would ask for first, or nil when they have all they want.
function Needs.ask(profile: any, vid: string): string?
	return Needs.missing(profile, vid)[1]
end

-- Somebody in town this villager hardly knows yet, to be introduced to (the first of them by id),
-- or nil.
function Needs.stranger(profile: any, vid: string): string?
	local list = {}
	for other in profile.villagers or {} do
		local score = if type(profile.rel) == "table" then Relationships.peek(profile, vid, other) else 0
		if other ~= vid and score < Tuning.Relationships.Levels[5].Min then
			table.insert(list, other)
		end
	end
	table.sort(list)
	return list[1]
end

-- The line an ask ends on. For friends: "introduce" when there is somebody to introduce them to
-- (the ask hands them a wish to meet them), else make more villagers.
function Needs.line(kind: string): string
	return LINES[kind] or LINES.bed
end

-- Is the tutorial still teaching the first steps (making somebody, a bed, a workplace)? Then it
-- does the asking itself, and the villagers wait.
function Needs.teaching(profile: any): boolean
	local at = Tutorial.current(profile, profile.tutorial)
	local step = at and Tutorial.Steps[at]
	return step ~= nil and (step.id == "villager" or step.id == "bed" or step.id == "work")
end

return Needs
