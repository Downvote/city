--!strict
-- Events that come back later. The user: "make events / conversations have follow up ones, such
-- as, for example, villager asks if they should check if they left the stove on, has a chance of
-- villager burning something and coming to you for help."
--
-- An answer can leave a follow-up waiting (Data/Events' s:follow, the "follow" effect in
-- Sim/EventEngine): another event, with the same villagers, due some town hours later and only by
-- a chance that answer gave it. They wait here, on the profile as `follow`:
--   { id, a, b?, c?, at, from?, w? }
-- id the event to play, a/b/c its stars' villager ids, at the os time it is due, from the event
-- that left it, w the words it carries over ({ dish = "pie" }: the next scene can say {dish}).
-- When one is due and its villagers are about, it is the next event the town plays
-- (EventEngine.pick); one nobody could play for Tuning.FollowUps.Expire seconds is let go. No
-- services, so the specs run it, and nothing here needs the events themselves (Sim/Schema
-- cleans a save with it).

local Tuning = require(script.Parent.Parent.Config.Tuning)

local F = Tuning.FollowUps

local FollowUps = {}

export type Entry = {
	id: string,
	a: string,
	b: string?,
	c: string?,
	at: number,
	from: string?,
	w: { [string]: string }?,
}

local function list(profile: any): { Entry }
	if type(profile.follow) ~= "table" then
		profile.follow = {}
	end
	return profile.follow
end

local function words(raw: any): { [string]: string }?
	if type(raw) ~= "table" then
		return nil
	end
	local out: { [string]: string } = {}
	local n = 0
	for k, v in raw do
		if type(k) == "string" and #k <= 20 and k:match("^%w+$") and type(v) == "string" and #v <= 60 then
			out[k] = v
			n += 1
			if n >= 6 then
				break
			end
		end
	end
	return if n > 0 then out else nil
end

-- One entry as it may be kept, or nil when it can't be (unknown villagers, odd values).
local function valid(raw: any, villagers: any): Entry?
	if type(raw) ~= "table" or type(raw.id) ~= "string" or #raw.id > 40 then
		return nil
	end
	if type(raw.at) ~= "number" or raw.at ~= raw.at or math.abs(raw.at) == math.huge then
		return nil
	end
	local stars = {}
	for _, letter in { "a", "b", "c" } do
		local vid = raw[letter]
		if vid ~= nil then
			if type(vid) ~= "string" or (type(villagers) == "table" and not villagers[vid]) then
				return nil
			end
			stars[letter] = vid
		end
	end
	if not stars.a then
		return nil
	end
	return {
		id = raw.id,
		a = stars.a,
		b = stars.b,
		c = stars.c,
		at = raw.at,
		from = if type(raw.from) == "string" and #raw.from <= 40 then raw.from else nil,
		w = words(raw.w),
	}
end

-- Leaves one waiting. The same event for the same first villager replaces the one before, and past
-- Tuning.FollowUps.Max the oldest goes. Returns the entry kept, or nil.
function FollowUps.add(profile: any, raw: any): Entry?
	if type(profile) ~= "table" then
		return nil
	end
	local e = valid(raw, profile.villagers)
	if not e then
		return nil
	end
	local mine = list(profile)
	for i = #mine, 1, -1 do
		if mine[i].id == e.id and mine[i].a == e.a then
			table.remove(mine, i)
		end
	end
	table.insert(mine, e)
	while #mine > F.Max do
		table.remove(mine, 1)
	end
	return e
end

-- The ones due by os time `now`, oldest first.
function FollowUps.due(profile: any, now: number): { Entry }
	local out = {}
	if type(profile) ~= "table" or type(profile.follow) ~= "table" then
		return out
	end
	for _, e in profile.follow do
		if type(e) == "table" and type(e.at) == "number" and e.at <= now then
			table.insert(out, e)
		end
	end
	table.sort(out, function(x, y)
		return x.at < y.at
	end)
	return out
end

-- Has it waited too long to be played at all?
function FollowUps.stale(e: Entry, now: number): boolean
	return now > e.at + F.Expire
end

function FollowUps.remove(profile: any, e: Entry)
	local mine = type(profile) == "table" and profile.follow
	if type(mine) ~= "table" then
		return
	end
	local at = table.find(mine, e)
	if at then
		table.remove(mine, at)
	end
end

-- The waiting ones, checked again on load (their villagers still in town).
function FollowUps.clean(raw: any, villagers: any): { Entry }
	local out = {}
	if type(raw) ~= "table" then
		return out
	end
	for _, r in raw do
		local e = valid(r, villagers)
		if e then
			table.insert(out, e)
			if #out >= F.Max then
				break
			end
		end
	end
	return out
end

return FollowUps
