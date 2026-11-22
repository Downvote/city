--!strict
-- Friendship between two villagers: a score from -100 to 100, a named level, and quarrels.
-- Stored in profile.rel["a|b"] = { s = score, q = quarrel ends (os time) or nil, n = times met }.

local Tuning = require(script.Parent.Parent.Config.Tuning)
local Schema = require(script.Parent.Schema)

local R = Tuning.Relationships

local Relationships = {}

export type Rel = { s: number, q: number?, n: number }

function Relationships.get(profile: any, a: string, b: string): Rel
	local key = Schema.pairKey(a, b)
	local rel = profile.rel[key]
	if not rel then
		rel = { s = 0, n = 0 }
		profile.rel[key] = rel
	end
	return rel
end

function Relationships.peek(profile: any, a: string, b: string): number
	local rel = profile.rel[Schema.pairKey(a, b)]
	return if rel then rel.s else 0
end

-- Index into Tuning.Relationships.Levels and its name.
function Relationships.level(score: number): (number, string)
	local index, name = 1, R.Levels[1].Name
	for i, lv in R.Levels do
		if score >= lv.Min then
			index, name = i, lv.Name
		end
	end
	return index, name
end

-- Changes a score. Returns the new score and the level change (old, new) if there was one.
function Relationships.add(profile: any, a: string, b: string, delta: number): (number, number?, number?)
	local rel = Relationships.get(profile, a, b)
	local before = Relationships.level(rel.s)
	rel.s = math.clamp(rel.s + delta, R.Min, R.Max)
	rel.n += 1
	local after = Relationships.level(rel.s)
	if after ~= before then
		return rel.s, before, after
	end
	return rel.s, nil, nil
end

function Relationships.quarrel(profile: any, a: string, b: string, now: number, minutes: number?)
	local rel = Relationships.get(profile, a, b)
	rel.q = now + (minutes or R.QuarrelMinutes) * 60
end

function Relationships.makeUp(profile: any, a: string, b: string)
	local rel = Relationships.get(profile, a, b)
	rel.q = nil
end

function Relationships.quarreling(profile: any, a: string, b: string, now: number): boolean
	local rel = profile.rel[Schema.pairKey(a, b)]
	return rel ~= nil and rel.q ~= nil and rel.q > now
end

-- Every pair that is quarreling right now.
function Relationships.quarrels(profile: any, now: number): { { string } }
	local out = {}
	for key, rel in profile.rel do
		if rel.q and rel.q > now then
			local a, b = Schema.splitPair(key)
			if profile.villagers[a] and profile.villagers[b] then
				table.insert(out, { a, b })
			end
		end
	end
	return out
end

-- Friends of a villager at or above a score, best first.
function Relationships.friendsOf(profile: any, vid: string, minScore: number): { string }
	local out = {}
	for other in profile.villagers do
		if other ~= vid and Relationships.peek(profile, vid, other) >= minScore then
			table.insert(out, other)
		end
	end
	table.sort(out, function(x, y)
		return Relationships.peek(profile, vid, x) > Relationships.peek(profile, vid, y)
	end)
	return out
end

-- The best friend of a villager, if anyone is at least Friends with them.
function Relationships.bestFriend(profile: any, vid: string): string?
	local list = Relationships.friendsOf(profile, vid, R.Levels[5].Min)
	return list[1]
end

-- Scores slowly drift back toward zero when nothing happens.
function Relationships.drift(profile: any)
	for _, rel in profile.rel do
		if rel.s > 0 then
			rel.s = math.max(0, rel.s - R.DailyDrift)
		elseif rel.s < 0 then
			rel.s = math.min(0, rel.s + R.DailyDrift)
		end
	end
end

return Relationships
