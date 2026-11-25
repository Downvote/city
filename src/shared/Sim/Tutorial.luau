--!strict
-- The tutorial's steps, as pure data in and out so the specs can run it. The user: "make the
-- tutorial more visual and structured, starting with creating a villager, then building a place
-- for them to sleep, then a place to work. the first time a craving pops up, guide the user how
-- to do it." So four steps, in order:
--   1 villager  somebody lives here (the creator made them)
--   2 bed       a villager has a bed that is on the plot (Services/Villagers gives a new bed to
--               whoever has none)
--   3 work      a villager has a workplace that is on the plot (and a new workplace to whoever
--               has no job)
--   4 craving   a craving has been bought for somebody (Life.buyWish counts them in
--               stats.cravings); it waits for the first one to come along
-- A step is done by what is true of the town, never by a click: the client (UI/Tutorial) reads
-- it off its copy of the state and asks the server to record it (the TutorialStep remote), and
-- the server records it in profile.tutorial only once Tutorial.advance has checked the profile
-- itself. profile.tutorial is how many steps are done (0 to Tutorial.Count), or Tutorial.Skipped
-- for a player who skipped it, which ends it for good. A step once recorded stays done.

local Catalog = require(script.Parent.Parent.Build.Catalog)
local City = require(script.Parent.City)

local Tutorial = {}

-- The steps, in order: what each asks for, its picture (UI/Icons) and, for the two that are built,
-- the piece the tutorial points at in Build mode (the starter plot leaves both out:
-- Data/StarterHouse.newPlot).
export type Step = { id: string, icon: string, piece: string? }
Tutorial.Steps = {
	{ id = "villager", icon = "person" },
	{ id = "bed", icon = "bed", piece = "bed_single" },
	{ id = "work", icon = "store", piece = "work_builder" },
	{ id = "craving", icon = "heart" },
} :: { Step }
Tutorial.Count = #Tutorial.Steps
-- what profile.tutorial holds once the player has skipped it
Tutorial.Skipped = 99

-- A saved value made sane: a whole number of steps done, or Skipped.
function Tutorial.progress(raw: any): number
	if type(raw) ~= "number" or raw ~= raw then
		return 0
	end
	if raw == Tutorial.Skipped then
		return raw
	end
	return math.clamp(math.floor(raw), 0, Tutorial.Count)
end

-- Is it over: every step done, or skipped?
function Tutorial.finished(raw: any): boolean
	return Tutorial.progress(raw) >= Tutorial.Count
end

-- Is that item on the plan a bed?
local function isBed(plan: any, key: any): boolean
	local item = if plan and type(key) == "string" then plan.items[key] else nil
	local def = item and Catalog.get(item.id)
	return def ~= nil and Catalog.hasTag(def, "bed")
end

-- Is step `i` true of the town? `town` is a profile, or the client's copy of one: villagers, the
-- plan and stats.
function Tutorial.met(town: any, i: number): boolean
	local villagers = if type(town.villagers) == "table" then town.villagers else {}
	if i == 1 then
		return next(villagers) ~= nil
	elseif i == 2 then
		for _, v in villagers do
			if v.bed and isBed(town.plan, v.bed) then
				return true
			end
		end
		return false
	elseif i == 3 then
		if not town.plan then
			return false
		end
		for vid in villagers do
			if City.jobOf(town, vid) then
				return true
			end
		end
		return false
	elseif i == 4 then
		local stats = town.stats
		return type(stats) == "table" and type(stats.cravings) == "number" and stats.cravings > 0
	end
	return false
end

-- How many steps are done: the `done` already recorded, and on from there each step the town
-- meets, in order. (Skipped stays skipped.)
function Tutorial.reached(town: any, done: any): number
	local n = Tutorial.progress(done)
	if n >= Tutorial.Count then
		return n
	end
	while n < Tutorial.Count and Tutorial.met(town, n + 1) do
		n += 1
	end
	return n
end

-- The step being worked on (1 to Count), or nil once it is over.
function Tutorial.current(town: any, done: any): number?
	local n = Tutorial.reached(town, done)
	if n >= Tutorial.Count then
		return nil
	end
	return n + 1
end

-- The server's side of the TutorialStep remote: `step` is the step the client says is done, or
-- Skipped. Checks the profile itself and records every step it meets, in order. Returns whether
-- `step` is done (or skipped) now, and the progress recorded.
function Tutorial.advance(profile: any, step: any): (boolean, number)
	local now = Tutorial.progress(profile.tutorial)
	if type(step) ~= "number" or step ~= step or step % 1 ~= 0 then
		return false, now
	end
	if step == Tutorial.Skipped then
		profile.tutorial = Tutorial.Skipped
		return true, Tutorial.Skipped
	end
	if step < 1 or step > Tutorial.Count then
		return false, now
	end
	if now >= Tutorial.Count then
		return true, now -- (over already: done, or skipped)
	end
	local reached = Tutorial.reached(profile, now)
	profile.tutorial = reached
	return reached >= step, reached
end

-- When a profile loads: what the town already has counts, so an old save that has a villager, a
-- bed and a job starts at the craving.
function Tutorial.catchUp(profile: any): number
	local now = Tutorial.progress(profile.tutorial)
	profile.tutorial = Tutorial.reached(profile, now)
	return profile.tutorial
end

return Tutorial
