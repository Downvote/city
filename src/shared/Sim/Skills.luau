--!strict
-- A player's own skill at each job. The user: "when players work, make what they earn scale off
-- town level. each skill also has a level/experience bar, which you gain while doing the work.
-- This increases the amount of cash you get doing that particular work as well."
-- Experience comes while the player works at a workplace themselves (Services/Work: a little every
-- second, and a bit more for each villager they serve there) and is kept per job, by Data/Jobs' id
-- (two ice cream carts are one skill): profile.skills = { [jobId] = experience in all }. The level
-- is worked out from that total, each level asking more than the last (Skills.toNext), up to
-- Tuning.Skills.Top. What a level is worth in pay is Skills.payK; the town's level adds its own
-- share (Skills.townK), and Sim/PlayerWork puts the two together. No services, so the specs run it.

local Tuning = require(script.Parent.Parent.Config.Tuning)
local Jobs = require(script.Parent.Parent.Data.Jobs)

local K = Tuning.Skills

local Skills = {}

-- What one skill looks like on a bar: the job, its name, the level, how far into the level the
-- experience is and how much the level asks (0 at the top), and the total.
export type Info = {
	job: string,
	name: string,
	level: number,
	into: number,
	need: number,
	xp: number,
	top: boolean,
}

-- Experience from `level` to the next one: more for every level.
function Skills.toNext(level: number): number
	return math.floor(K.Base * math.max(1, level) ^ K.Grow + 0.5)
end

-- The experience a level starts at (level 1 starts at none).
local starts: { number } = { 0 }
for level = 2, K.Top do
	starts[level] = starts[level - 1] + Skills.toNext(level - 1)
end

function Skills.startOf(level: number): number
	return starts[math.clamp(math.floor(level), 1, K.Top)]
end

-- The most experience a skill holds: the top level's start.
function Skills.most(): number
	return starts[K.Top]
end

-- The level for a total, how far into it, and what it asks (0 at the top).
function Skills.levelOf(xp: number): (number, number, number)
	if not (xp == xp) or xp < 0 then
		xp = 0
	end
	local level = 1
	while level < K.Top and xp >= starts[level + 1] do
		level += 1
	end
	if level >= K.Top then
		return K.Top, 0, 0
	end
	return level, xp - starts[level], Skills.toNext(level)
end

local function total(profile: any, job: string): number
	local s = type(profile) == "table" and profile.skills
	local n = type(s) == "table" and s[job]
	if type(n) ~= "number" or n ~= n or n < 0 then
		return 0
	end
	return math.min(n, Skills.most())
end

-- The player's skill at a job, as the bar shows it.
function Skills.info(profile: any, job: string): Info
	local xp = total(profile, job)
	local level, into, need = Skills.levelOf(xp)
	local j = Jobs.get(job)
	return {
		job = job,
		name = if j then j.name else job,
		level = level,
		into = math.floor(into),
		need = need,
		xp = math.floor(xp),
		top = level >= K.Top,
	}
end

-- Just the level.
function Skills.level(profile: any, job: string): number
	return (Skills.levelOf(total(profile, job)))
end

-- Adds experience to a job's skill (whole points; nothing for a job there isn't, or for a number
-- that isn't one). Returns the level before and after.
function Skills.add(profile: any, job: string, xp: number): (number, number)
	local before = Skills.level(profile, job)
	if not Jobs.get(job) or not (xp > 0 and xp < math.huge) then
		return before, before
	end
	if type(profile.skills) ~= "table" then
		profile.skills = {}
	end
	profile.skills[job] = math.min(Skills.most(), math.floor(total(profile, job) + xp))
	return before, Skills.level(profile, job)
end

-- The skills the player has any experience in, best first (then by name).
function Skills.list(profile: any): { Info }
	local out = {}
	for _, j in Jobs.all do -- (the crate jobs too)
		if total(profile, j.id) > 0 then
			table.insert(out, Skills.info(profile, j.id))
		end
	end
	table.sort(out, function(a, b)
		if a.xp ~= b.xp then
			return a.xp > b.xp
		end
		return a.name < b.name
	end)
	return out
end

-- What a skill level does to the pay and the day's cap: a share more for every level past the first.
function Skills.payK(level: number): number
	return 1 + K.Pay * (math.clamp(math.floor(level), 1, K.Top) - 1)
end

-- And what the town's level does, up to Tuning.Skills.TownTop.
function Skills.townK(level: number): number
	if not (level == level) then
		level = 1
	end
	return 1 + K.TownPay * (math.clamp(math.floor(level), 1, K.TownTop) - 1)
end

-- A saved profile's skills, checked: known jobs, whole numbers from none to the most a skill holds.
function Skills.clean(raw: any): { [string]: number }
	local out = {}
	if type(raw) ~= "table" then
		return out
	end
	for job, n in raw do
		if type(job) == "string" and Jobs.get(job) and type(n) == "number" and n == n and n > 0 then
			out[job] = math.min(Skills.most(), math.floor(n))
		end
	end
	return out
end

return Skills
