--!strict
-- Offline earnings (the user: "add offline earnings"). When a player comes back, their town is
-- paid for the time they were away: Tuning.Offline.Share of what its working villagers would have
-- earned at work in that time (a day's wages, City.wages, for every town day of it: a town day is
-- Tuning.Day.Length real seconds), the time counted up to Tuning.Offline.Hours, times the pay
-- boost their passes and the group give (Sim/Passes.payBoost). Nothing on a first visit (no time
-- seen yet), nothing for a quick rejoin, nothing for a town with nobody in work. The server
-- (Services/Store) pays it and the client shows it in a welcome back dialog. No services, so the
-- specs run it.

local Tuning = require(script.Parent.Parent.Config.Tuning)
local City = require(script.Parent.City)

local Offline = {}

local K = Tuning.Offline

export type Away = {
	secs: number, -- how long they were away
	counted: number, -- how much of it was paid for (no more than K.Hours)
	coins: number, -- what the town was paid
	workers: number, -- villagers in work who earned it
	perDay: number, -- a whole day's wages of theirs, before the share
}

-- Seconds away since `seen` (profile.seen: when the profile was last saved with them in the
-- game), or 0 when it was never seen or the clock went backwards.
function Offline.away(seen: any, now: number): number
	if type(seen) ~= "number" or seen ~= seen or seen <= 0 or not (now < math.huge) then
		return 0
	end
	return math.max(0, now - seen)
end

-- What `secs` away earns the town. `boost` is what pay is multiplied by (1 with no passes).
function Offline.earnings(profile: any, secs: number, boost: number?, now: number): Away
	local out: Away = { secs = 0, counted = 0, coins = 0, workers = 0, perDay = 0 }
	if type(secs) ~= "number" or secs ~= secs or secs < K.MinMinutes * 60 or secs == math.huge then
		return out
	end
	out.secs = secs
	if type(profile) ~= "table" or type(profile.villagers) ~= "table" then
		return out
	end
	-- (day -1: nobody has that day off)
	local list, perDay = City.wages(profile, -1, now)
	out.workers = #list
	out.perDay = perDay
	if perDay <= 0 then
		return out
	end
	local m = if type(boost) == "number" and boost == boost and boost >= 1 and boost < math.huge then boost else 1
	out.counted = math.min(secs, K.Hours * 3600)
	local days = out.counted / Tuning.Day.Length
	out.coins = math.floor(perDay * days * K.Share * m + 0.5)
	return out
end

return Offline
