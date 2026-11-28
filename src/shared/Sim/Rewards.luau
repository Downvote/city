--!strict
-- The rewards a player claims (the Rewards menu): the daily gift, gems for time played today,
-- achievements and joining the group. The user: "allow players to buy gems, as a daily reward,
-- certain achievements, playtime rewards, etc. and buying with robux. it should be a rare
-- currency" and "add group rewards". Each says what is due from the profile alone, so the server
-- (Services/Data's DailyClaim, Services/Store's claims) checks everything itself and the client
-- shows the same thing from its copy of the state. Nothing here adds coins or gems: it says what
-- a claim pays and marks it claimed, and the server pays it. No services, so the specs run it.

local Tuning = require(script.Parent.Parent.Config.Tuning)
local Achievements = require(script.Parent.Parent.Data.Achievements)
local Playtime = require(script.Parent.Parent.Data.Playtime)
local City = require(script.Parent.City)
local Crates = require(script.Parent.Crates) -- (crates in the daily gift and achievements: Sim/Crates)
local Shopping = require(script.Parent.Shopping) -- (the track for Robux spent on looks: Sim/Shopping)

local Rewards = {}

local G = Tuning.GemRewards
local E = Tuning.Economy

-- The key in profile.achieved that says the group's gems were paid.
Rewards.GroupKey = "group"

-- The day the daily gift and the playtime count go by: whole days since 1970, as the server's
-- clock has it (UTC).
function Rewards.today(now: number?): number
	return math.floor((now or os.time()) / 86400)
end

local function num(v: any, default: number): number
	return if type(v) == "number" and v == v and v > -math.huge and v < math.huge then v else default
end

-- The daily gift ------------------------------------------------------------------------------------

-- profile.daily, mended: `last` the day it was last claimed, `streak` the days running (capped at
-- Tuning.Economy.DailyStreakCap, what the coins go by) and `run` the days running uncapped (what
-- the gems go by).
function Rewards.daily(profile: any): { last: number, streak: number, run: number }
	local d = profile.daily
	if type(d) ~= "table" then
		d = {}
		profile.daily = d
	end
	d.last = num(d.last, 0)
	d.streak = math.max(0, math.floor(num(d.streak, 0)))
	-- (a save from before the gems has no run: it starts from its streak)
	d.run = math.max(d.streak, math.floor(num(d.run, 0)))
	return d
end

function Rewards.dailyReady(profile: any, today: number): boolean
	return Rewards.daily(profile).last ~= today
end

-- The streak and the run a claim on `today` makes (today's own, when it is claimed already).
function Rewards.nextDaily(profile: any, today: number): (number, number)
	local d = Rewards.daily(profile)
	if d.last == today then
		return math.max(1, d.streak), math.max(1, d.run)
	elseif d.last == today - 1 then
		return math.min(d.streak + 1, E.DailyStreakCap), d.run + 1
	end
	return 1, 1
end

-- What the gift is on a streak of `streak` days (coins) and a run of `run` (gems: one a day, more
-- on every seventh day running, one more for VIP).
function Rewards.dailyGift(streak: number, run: number, vip: boolean?): (number, number)
	local coins = E.DailyGift + (math.max(1, streak) - 1) * E.DailyStreakBonus
	local gems = if run > 0 and run % G.Week == 0 then G.Seventh else G.Daily
	if vip then
		gems += G.Vip
	end
	return coins, gems
end

-- The crate a day of the run brings with the daily gift, or nil: every Tuning.Crates.DailyEvery
-- days running, a work crate, then a pet crate the next time, and so on.
function Rewards.dailyCrate(run: number): string?
	local every = Tuning.Crates.DailyEvery
	if run <= 0 or run % every ~= 0 then
		return nil
	end
	return if (run // every) % 2 == 1 then "work" else "pet"
end

-- Claims today's gift: moves the streak on. Returns whether it did, the coins and gems it pays and
-- the crate it gave (now held in the save), if any.
function Rewards.claimDaily(profile: any, today: number, vip: boolean?): (boolean, number, number, string?)
	local d = Rewards.daily(profile)
	if d.last == today then
		return false, 0, 0, nil
	end
	local streak, run = Rewards.nextDaily(profile, today)
	d.last, d.streak, d.run = today, streak, run
	local coins, gems = Rewards.dailyGift(streak, run, vip)
	local crate = Rewards.dailyCrate(run)
	if crate then
		Crates.give(profile, crate, 1)
	end
	return true, coins, gems, crate
end

-- Playtime ------------------------------------------------------------------------------------------

export type Played = { day: number, secs: number, got: number }

-- profile.playtime for `today`: started again on a new day, mended if broken.
function Rewards.playtime(profile: any, today: number): Played
	local p = profile.playtime
	if type(p) ~= "table" then
		p = {}
		profile.playtime = p
	end
	p.day = num(p.day, -1)
	p.secs = math.max(0, num(p.secs, 0))
	p.got = math.max(0, math.floor(num(p.got, 0)))
	if p.day ~= today then
		p.day, p.secs, p.got = today, 0, 0
	end
	return p
end

-- How many of the steps `secs` of play has reached.
function Rewards.reached(secs: number): number
	local n = 0
	for i, s in Playtime.steps do
		if secs >= s.minutes * 60 then
			n = i
		else
			break
		end
	end
	return n
end

-- Counts `secs` more of play today. Returns whether a step came due with it.
function Rewards.tick(profile: any, secs: number, today: number): boolean
	local p = Rewards.playtime(profile, today)
	if not (secs > 0 and secs < math.huge) then
		return false
	end
	local before = Rewards.reached(p.secs)
	p.secs = math.min(p.secs + secs, 86400)
	return Rewards.reached(p.secs) > before
end

-- Steps reached today and not claimed yet.
function Rewards.playtimeReady(profile: any, today: number): number
	local p = Rewards.playtime(profile, today)
	return math.max(0, Rewards.reached(p.secs) - p.got)
end

-- Claims a playtime step. They go in order, so `index` must be the next one (nil means it).
-- Returns whether it did, its gems, and if not why, in plain words.
function Rewards.claimPlaytime(profile: any, index: any, today: number): (boolean, number, string?)
	local p = Rewards.playtime(profile, today)
	local nextOne = p.got + 1
	if index ~= nil and index ~= nextOne then
		return false, 0, if type(index) == "number" and index <= p.got then "You've had that one today." else "Not yet."
	end
	local step = Playtime.steps[nextOne]
	if not step then
		return false, 0, "That's all of today's."
	end
	if p.secs < step.minutes * 60 then
		return false, 0, "Not yet."
	end
	p.got = nextOne
	return true, step.gems, nil
end

-- Achievements --------------------------------------------------------------------------------------

export type Status = { a: Achievements.Achievement, value: number, done: boolean, claimed: boolean }

local function achieved(profile: any): { [string]: boolean }
	local a = profile.achieved
	if type(a) ~= "table" then
		a = {}
		profile.achieved = a
	end
	return a
end

-- Every achievement and how far along it is. `profile` needs villagers, plan, rel, stats and
-- achieved (the client's State.data with its plan does).
function Rewards.achievements(profile: any): { Status }
	local city = City.stats(profile)
	local got = achieved(profile)
	local out = {}
	for _, a in Achievements.list do
		local value = a.value(profile, city)
		table.insert(out, {
			a = a,
			value = math.min(value, a.need),
			done = value >= a.need,
			claimed = got[a.id] == true,
		})
	end
	return out
end

-- Claims a finished achievement's gems once. Returns whether it did, the gems and the crate it gave
-- (now held in the save), if any.
function Rewards.claimAchievement(profile: any, id: any): (boolean, number, string?)
	if type(id) ~= "string" then
		return false, 0, nil
	end
	local a = Achievements.get(id)
	local got = achieved(profile)
	if not a or got[id] then
		return false, 0, nil
	end
	if a.value(profile, City.stats(profile)) < a.need then
		return false, 0, nil
	end
	got[id] = true
	if a.crate then
		Crates.give(profile, a.crate, 1)
	end
	return true, a.gems, a.crate
end

-- The group -----------------------------------------------------------------------------------------

-- Is there a group to join at all? (Tuning.Group.Id is 0 until it is made on Roblox.)
function Rewards.hasGroup(): boolean
	return Tuning.Group.Id ~= 0
end

function Rewards.groupPaid(profile: any): boolean
	return achieved(profile)[Rewards.GroupKey] == true
end

function Rewards.groupReady(profile: any, inGroup: boolean?): boolean
	return Rewards.hasGroup() and inGroup == true and not Rewards.groupPaid(profile)
end

-- Pays the group's gems once, to a member. Returns whether it did and the gems.
function Rewards.claimGroup(profile: any, inGroup: boolean?): (boolean, number)
	if not Rewards.groupReady(profile, inGroup) then
		return false, 0
	end
	achieved(profile)[Rewards.GroupKey] = true
	return true, G.Group
end

-- All of it ------------------------------------------------------------------------------------------

-- How many things are waiting to be claimed (the badge on the Rewards tile).
function Rewards.waiting(profile: any, today: number, inGroup: boolean?): number
	local n = if Rewards.dailyReady(profile, today) then 1 else 0
	n += Rewards.playtimeReady(profile, today)
	for _, s in Rewards.achievements(profile) do
		if s.done and not s.claimed then
			n += 1
		end
	end
	if Rewards.groupReady(profile, inGroup) then
		n += 1
	end
	-- and the shopping track's tiers reached (Sim/Shopping)
	n += Shopping.ready(profile)
	return n
end

return Rewards
