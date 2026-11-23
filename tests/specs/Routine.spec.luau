--!nocheck
-- A villager's day. The user: "villagers seem to stand around doing nothing. they should be at
-- their work stations instead, and taking breaks sometimes to do different things". Two parts:
--   Sim/Routine, the choosing, run through many seeded days with walking times made up the way
--   the game's come out: a worker is at their workplace two thirds of the work day or more,
--   takes a break on most days and never a long one, every job goes round a loop of its own,
--   who they are decides how often they break and what they do, a villager with no job keeps
--   busy, and nobody works at night, when sick or on a day off.
--   The brain in Services/Villagers acting it out, with its neighbours stubbed, stand-in bodies
--   that walk at walking pace and a clock this spec winds on (as TalkService.spec does).

local Shared = "ReplicatedStorage.Shared."
local Services = "ServerScriptService.Server.Services."
local Tuning = require(Shared .. "Config.Tuning")
local Routine = require(Shared .. "Sim.Routine")
local Catalog = require(Shared .. "Build.Catalog")
local Geometry = require(Shared .. "Build.Geometry")
local Jobs = require(Shared .. "Data.Jobs")
local Personalities = require(Shared .. "Data.Personalities")
local Rng = require(Shared .. "Util.Rng")

local D = Tuning.Day
local K = Tuning.Routine
local WALK = Tuning.Villagers.WalkSpeed
local workDay = Routine.workDay()

local function workplace(job)
	for _, def in Catalog.workplaces() do
		if def.job == job then
			return def
		end
	end
	return nil
end

-- the town's clock, as Services/World keeps it: a day starts at StartClock (nine)
local function hourAt(t)
	return (D.StartClock + (t % D.Length) / D.Length * 24) % 24
end

local function flat(a, b)
	return Vector3.new(a.X - b.X, 0, a.Z - b.Z).Magnitude
end

-- the model ---------------------------------------------------------------------------------------

local function ctxAt(o, loop, t)
	local day = math.floor(t / D.Length)
	return {
		hour = hourAt(t),
		day = day,
		pers = o.pers,
		job = o.job,
		loop = loop,
		sick = if o.sick then o.sick(day) else nil,
		dayOff = if o.dayOff then o.dayOff(day) else nil,
		can = o.can,
		blocked = o.blocked,
	}
end

-- How much of `seconds` from `t` passes before the part of the day changes (the brain's waits
-- stop there: work starts, work ends, bedtime).
local function before(o, loop, t, phase, seconds)
	local s = 0
	while s < seconds do
		local step = math.min(0.5, seconds - s)
		if Routine.phase(ctxAt(o, loop, t + s + step)) ~= phase then
			return s + step
		end
		s += step
	end
	return seconds
end

-- One villager's days through Routine, lived the way the brain lives them. Walking is made up
-- the way the game's comes out: a hop between two spots of the loop at walking pace, the walk to
-- work a few seconds from anywhere on the plot, a break's walk there and back no further than
-- BreakReach. Days start at nine, as the town's do. Returns a record for each day.
local function simulate(o)
	local rng = Rng.new(o.seed)
	local def = o.job and workplace(o.job)
	local loop = def and Routine.loop(def)
	local state = Routine.newDay()
	local t, at, back = 0, nil, nil
	local days = {}
	while t < o.days * D.Length do
		local ctx = ctxAt(o, loop, t)
		local r = days[ctx.day + 1]
		if not r then
			r = { station = 0, breaks = {}, turns = {} }
			days[ctx.day + 1] = r
		end
		local turn = Routine.next(ctx, state, rng)
		turn.hour = ctx.hour
		table.insert(r.turns, turn)
		if turn.kind == "sleep" then
			at, back = nil, nil
			t += 4
		elseif turn.kind == "work" then
			local walk, hop = 0, 0
			if at == nil then
				walk = back or rng:float(3, 12)
				back = nil
			else
				hop = flat(loop[at].at, loop[turn.step].at) / WALK + 0.3
			end
			local stay = before(o, loop, t + walk + hop, "work", turn.seconds)
			r.station += hop + stay
			turn.stop = loop[turn.step]
			Routine.done(state, turn, walk + hop + stay, rng, walk)
			at = turn.step
			t += walk + hop + stay
		elseif turn.kind == "break" then
			local there = rng:float(1, K.BreakReach / WALK)
			local stay = math.max(K.BreakStay, turn.seconds - 2 * there)
			table.insert(r.breaks, { what = turn.what, seconds = turn.seconds, away = 2 * there + stay })
			Routine.done(state, turn, there + stay, rng)
			at, back = nil, there
			t += there + stay
		else
			at, back = nil, nil
			local walk = if turn.what == "idle" or turn.what == "gesture" then 0 else rng:float(1, 5)
			local extra = if turn.what == "chat" then 5 elseif turn.what == "visit" then 4 else 0
			local rest = before(o, loop, t + walk, "free", turn.seconds + extra)
			Routine.done(state, turn, walk + rest, rng)
			t += walk + rest + rng:float(K.Pause[1], K.Pause[2])
		end
	end
	return days
end

-- Every job with every personality, so many days each.
local function everyone(days)
	local out = {}
	for ji, job in Jobs.list do
		for pi, p in Personalities.list do
			for d, r in simulate({ job = job.id, pers = p.id, days = days, seed = ji * 100 + pi }) do
				r.job, r.pers, r.day = job.id, p.id, d
				table.insert(out, r)
			end
		end
	end
	return out
end

local all = everyone(25)

-- Is a body standing clear of a workplace's own parts, between knee and head height? Returns how
-- far it is from the nearest (the City spec's grid does the same for the map).
local function clearance(def, at)
	local best = math.huge
	for _, p in Geometry.flatten(Catalog.prims(def)) do
		local lo, hi = Geometry.bounds({ p })
		if p.collide ~= false and hi.Y > at.Y + 1.45 and lo.Y < at.Y + 5.2 then
			local dx, dz
			if p.shape == "Block" and p.cf.UpVector.Y > 0.999 then
				local l = p.cf:PointToObjectSpace(Vector3.new(at.X, p.cf.Position.Y, at.Z))
				dx = math.max(math.abs(l.X) - p.size.X / 2, 0)
				dz = math.max(math.abs(l.Z) - p.size.Z / 2, 0)
			else
				dx = math.max(lo.X - at.X, at.X - hi.X, 0)
				dz = math.max(lo.Z - at.Z, at.Z - hi.Z, 0)
			end
			best = math.min(best, math.sqrt(dx * dx + dz * dz))
		end
	end
	return best
end

describe("Routine", function()
	it("gives every job a loop of its own round its workplace, and no two alike", function()
		local seen = {}
		for _, job in Jobs.list do
			expect(Routine.has(job.id)).toBe(true)
			local def = workplace(job.id)
			expect(def ~= nil).toBeTruthy()
			local loop = Routine.loop(def)
			expect(#loop >= 4).toBeTruthy()
			-- three places to stand at least, and something done with the hands somewhere
			local spots, acts = {}, 0
			for _, stop in loop do
				spots[string.format("%.1f,%.1f", stop.at.X, stop.at.Z)] = true
				if stop.act then
					acts += 1
				end
				expect(stop.stay[1] > 0 and stop.stay[2] >= stop.stay[1]).toBeTruthy()
				expect(stop.say).toBeBetween(0, 1)
			end
			local n = 0
			for _ in spots do
				n += 1
			end
			expect(n >= 3).toBeTruthy()
			expect(acts >= 1).toBeTruthy()
			-- the same round twice is the same job twice
			local sig = {}
			for _, stop in loop do
				table.insert(sig, string.format("%.1f,%.1f,%s", stop.at.X, stop.at.Z, stop.act or "-"))
			end
			local key = table.concat(sig, "|")
			expect(seen[key]).toBe(nil)
			seen[key] = job.id
		end
	end)

	it("starts each loop on the recipe's own spot, facing the way the recipe says", function()
		for _, def in Catalog.workplaces() do
			local loop = Routine.loop(def)
			local home = loop[Routine.home(loop)]
			expect(home.home).toBe(true)
			expect(Routine.home(loop)).toBe(1)
			local spot = def.workSpot or Vector3.new(0, 0, -(def.size.Z / 2 + 1.5))
			expect(flat(home.at, spot)).toBeNear(0)
			local yaw = math.rad(def.workYaw or 0)
			for _, stop in loop do
				if stop.home then
					expect(flat(stop.at, spot)).toBeNear(0)
					local look = Vector3.new(stop.look.X - stop.at.X, 0, stop.look.Z - stop.at.Z).Unit
					expect(look:Dot(Vector3.new(math.sin(yaw), 0, math.cos(yaw))) > 0.5).toBeTruthy()
				end
			end
		end
	end)

	it("keeps every spot clear of the workplace's own parts", function()
		for _, def in Catalog.workplaces() do
			for _, stop in Routine.loop(def) do
				local gap = clearance(def, stop.at)
				-- the recipes' own spots stand up to the counter; ours leave a body's width
				local need = if stop.home then 1.05 else 1.3
				if gap < need then
					error(string.format("%s: %s stands %.2f from its parts", def.id, stop.name, gap))
				end
				-- and the spot faces what it is for, not off across the room through itself
				expect(flat(stop.look, stop.at) > 0.5).toBeTruthy()
			end
		end
	end)

	it("keeps a worker at the workplace two thirds of the work day or more, every day", function()
		local worst, sum = 1, 0
		for _, r in all do
			local share = r.station / workDay
			sum += share
			if share < worst then
				worst = share
			end
			if share < 2 / 3 then
				error(string.format("%s, %s, day %d: at work %.2f of the day", r.job, r.pers, r.day, share))
			end
		end
		expect(sum / #all > 0.8).toBeTruthy()
		-- and nobody works the whole day through without a break
		expect(worst < 0.8).toBeTruthy()
	end)

	it("sends a worker on a break most days, and never on a long one", function()
		local withBreak, byPers = 0, {}
		for _, r in all do
			local b = byPers[r.pers] or { days = 0, with = 0 }
			byPers[r.pers] = b
			b.days += 1
			if #r.breaks > 0 then
				withBreak += 1
				b.with += 1
			end
			local spent = 0
			for _, br in r.breaks do
				expect(br.seconds <= K.BreakCap).toBeTruthy()
				spent += br.seconds
				-- gone for less than two of the town's hours, the walk back included
				expect(br.away < 2 / 24 * D.Length).toBeTruthy()
			end
			-- breaks together take no more than their part of the day
			expect(spent <= K.AwayCap * workDay + 1e-6).toBeTruthy()
		end
		expect(withBreak / #all > 0.75).toBeTruthy()
		for pers, b in byPers do
			if b.with / b.days < 0.5 then
				error(string.format("%s takes a break on only %.2f of days", pers, b.with / b.days))
			end
		end
	end)

	it("lets the lazy break more and longer than the focused, and the social go for a chat", function()
		local stats = {}
		for _, r in all do
			local s = stats[r.pers] or { days = 0, breaks = 0, seconds = 0, kinds = {} }
			stats[r.pers] = s
			s.days += 1
			for _, b in r.breaks do
				s.breaks += 1
				s.seconds += b.seconds
				s.kinds[b.what] = (s.kinds[b.what] or 0) + 1
			end
		end
		local function perDay(p)
			return stats[p].breaks / stats[p].days
		end
		local function length(p)
			return stats[p].seconds / stats[p].breaks
		end
		local function commonest(p)
			local best, n = nil, -1
			for kind, c in stats[p].kinds do
				if c > n then
					best, n = kind, c
				end
			end
			return best
		end
		-- easygoing is the laziest, proud the most focused, sunny the most social
		expect(perDay("easygoing") > 2 * perDay("proud")).toBeTruthy()
		expect(perDay("easygoing") >= 1.5).toBeTruthy()
		expect(length("easygoing") > length("proud") + 5).toBeTruthy()
		expect(commonest("sunny")).toBe("chat")
		expect(commonest("easygoing")).toBe("sit")
		-- the order holds across all of them
		local list = {}
		for _, p in Personalities.list do
			table.insert(list, p.id)
		end
		for _, a in list do
			for _, b in list do
				if Routine.breakShare(a) > Routine.breakShare(b) + 0.05 then
					expect(perDay(a) > perDay(b)).toBeTruthy()
				end
			end
		end
		-- and every kind of break turns up
		local kinds = {}
		for _, s in stats do
			for kind in s.kinds do
				kinds[kind] = true
			end
		end
		for _, w in K.Breaks do
			expect(kinds[w.kind]).toBe(true)
		end
	end)

	it("goes round the loop at work, saying the job's own lines and never one twice running", function()
		for _, job in Jobs.list do
			local days = simulate({ job = job.id, pers = "sunny", days = 4, seed = 9 })
			local steps, lastLine = {}, nil
			for _, r in days do
				for _, turn in r.turns do
					if turn.kind == "work" then
						steps[turn.step] = true
						if turn.say then
							expect(table.find(job.lines, turn.say) ~= nil).toBeTruthy()
							expect(turn.say ~= lastLine).toBeTruthy()
							lastLine = turn.say
						end
					end
				end
			end
			for i in Routine.loop(workplace(job.id)) do
				expect(steps[i]).toBe(true)
			end
			expect(lastLine ~= nil).toBeTruthy()
		end
	end)

	it("counts the walk back from a break as part of it, and the walk to work as neither", function()
		local rng = Rng.new(3)
		local state = Routine.newDay()
		local loop = Routine.loop(workplace("builder"))
		local ctx = { hour = 9.1, day = 40, pers = "sunny", job = "builder", loop = loop }
		local first = Routine.next(ctx, state, rng)
		expect(first.kind).toBe("work")
		expect(first.step).toBe(1)
		Routine.done(state, first, 10, rng, 4)
		expect(state.atWork).toBeNear(6)
		expect(state.away).toBeNear(0)
		Routine.done(state, { kind = "break", what = "sit", seconds = 20 }, 15, rng)
		expect(state.away).toBeNear(15)
		expect(state.breaks).toBe(1)
		expect(state.stretch).toBeNear(0)
		Routine.done(state, { kind = "work", step = 2, seconds = 5 }, 9, rng, 3)
		expect(state.away).toBeNear(18)
		expect(state.atWork).toBeNear(12)
		-- the next walk to a spot is a hop, and counts as work
		Routine.done(state, { kind = "work", step = 3, seconds = 5 }, 6, rng, 0)
		expect(state.away).toBeNear(18)
		expect(state.atWork).toBeNear(18)
		-- a new day starts the counts again
		ctx.day = 41
		Routine.next(ctx, state, rng)
		expect(state.atWork).toBe(0)
		expect(state.breaks).toBe(0)
	end)

	it("keeps a villager with no job busy, and seldom just standing", function()
		for pi, p in Personalities.list do
			local days = simulate({ pers = p.id, days = 12, seed = 50 + pi })
			local kinds, total, idle, last = {}, 0, 0, nil
			local visits = 0
			for _, r in days do
				for _, turn in r.turns do
					expect(turn.kind == "work" or turn.kind == "break").toBe(false)
					if turn.kind == "potter" then
						total += 1
						kinds[turn.what] = true
						if turn.what == "idle" then
							idle += 1
							expect(last ~= "idle").toBeTruthy()
							expect(turn.seconds <= K.Idle[2]).toBeTruthy()
						elseif turn.what == "visit" then
							-- workplaces are open in work hours only
							expect(turn.hour >= D.WorkStart and turn.hour < D.WorkEnd).toBeTruthy()
							visits += 1
						end
						last = turn.what
					end
				end
			end
			local n = 0
			for _ in kinds do
				n += 1
			end
			expect(n).toBe(#K.Potter)
			expect(idle / total < 0.06).toBeTruthy()
			-- about two calls at a workplace a day each, as before (the town earns from them)
			expect(visits / 12).toBeBetween(1, 4)
		end
	end)

	it("has nobody at work at night, when sick or on a day off", function()
		local loop = Routine.loop(workplace("baker"))
		for h = 0, 23.75, 0.25 do
			local ctx = { hour = h, day = 3, pers = "proud", job = "baker", loop = loop }
			local phase = Routine.phase(ctx)
			expect(phase == "work").toBe(h >= D.WorkStart and h < D.WorkEnd)
			expect(phase == "sleep").toBe(h >= D.BedTime or h < D.WakeTime)
			ctx.sick = true
			expect(Routine.phase(ctx)).toBe("sleep")
			ctx.sick, ctx.dayOff = nil, true
			expect(Routine.phase(ctx) ~= "work").toBeTruthy()
			ctx.dayOff, ctx.job = nil, nil
			expect(Routine.phase(ctx) ~= "work").toBeTruthy()
		end
		local cases = {
			{
				sick = function()
					return true
				end,
			},
			{
				dayOff = function(day)
					return day % 2 == 1
				end,
			},
		}
		for _, case in cases do
			local days = simulate({
				job = "baker",
				pers = "proud",
				days = 6,
				seed = 2,
				sick = case.sick,
				dayOff = case.dayOff,
			})
			for d, r in days do
				local off = case.sick ~= nil or case.dayOff(d - 1)
				for _, turn in r.turns do
					if off then
						expect(turn.kind == "work" or turn.kind == "break").toBe(false)
					end
					if case.sick then
						expect(turn.kind).toBe("sleep")
					end
				end
			end
		end
	end)

	it("leaves out a spot with no way to it, but never the workplace's own", function()
		local rng = Rng.new(5)
		for _, job in Jobs.list do
			local loop = Routine.loop(workplace(job.id))
			-- every spot said to be walled off, the workplace's own too: that one never is left out
			local blocked = {}
			for i in loop do
				blocked[i] = true
			end
			local state = Routine.newDay()
			local ctx = { hour = 10, day = 1, pers = "proud", job = job.id, loop = loop, blocked = blocked }
			for _ = 1, 30 do
				local turn = Routine.next(ctx, state, rng)
				if turn.kind == "work" then
					expect(loop[turn.step].home).toBe(true)
				end
				Routine.done(state, turn, 0, rng)
			end
			-- one walled off: the rest are still gone round
			local one = nil
			for i, stop in loop do
				if not stop.home then
					one = i
					break
				end
			end
			ctx.blocked = { [one] = true }
			local seen = {}
			for _ = 1, 40 do
				local turn = Routine.next(ctx, state, rng)
				if turn.kind == "work" then
					expect(turn.step ~= one).toBeTruthy()
					seen[turn.step] = true
				end
				Routine.done(state, turn, 1, rng)
			end
			for i in loop do
				expect(seen[i] == true).toBe(i ~= one)
			end
		end
	end)

	it("only does what there is something to do it with", function()
		local rng = Rng.new(8)
		local state = Routine.newDay()
		local can = { sit = false, chat = false, visit = false }
		for _, h in { 8, 12, 19 } do
			for _ = 1, 200 do
				local turn = Routine.next({ hour = h, day = 2, pers = "sunny", can = can }, state, rng)
				expect(turn.kind).toBe("potter")
				expect(can[turn.what] == nil).toBeTruthy()
				Routine.done(state, turn, 1, rng)
			end
		end
		-- and on a break: only what needs nobody and nothing (a stroll, a stretch)
		local days = simulate({ job = "teacher", pers = "sunny", days = 8, seed = 4, can = can })
		local any = 0
		for _, r in days do
			for _, b in r.breaks do
				any += 1
				expect(b.what == "stroll" or b.what == "stretch").toBeTruthy()
			end
		end
		expect(any > 0).toBeTruthy()
	end)

	it("says what is worth a look", function()
		local plant, sofa
		for _, def in Catalog.all() do
			if not plant and Catalog.hasTag(def, "plant") then
				plant = def
			end
		end
		expect(plant ~= nil).toBeTruthy()
		expect(Routine.sight(plant)).toBe(true)
		expect(Routine.sight(workplace("baker"))).toBe(true)
		sofa = { cat = "seating", tags = { "seat" } }
		expect(Routine.sight(sofa)).toBe(false)
	end)
end)

-- the brain ---------------------------------------------------------------------------------------

local Schema = require(Shared .. "Sim.Schema")
local Appearance = require(Shared .. "Avatar.Appearance")
local StarterHouse = require(Shared .. "Data.StarterHouse")
local Town = require(Shared .. "Data.Town")
local Plan = require(Shared .. "Build.Plan")

local env = Harness.env()
local game = Harness.game()

-- a clock this spec winds on, and tasks that wait on it. It starts at eight on day 100 (the
-- town's day starts at nine, as in Services/World).
local now = 100 * D.Length - D.Length / 24
local sleeping, ours, errors = {}, setmetatable({}, { __mode = "k" }), {}
local function resume(co, ...)
	local ok, err = coroutine.resume(co, ...)
	if not ok then
		table.insert(errors, tostring(err) .. "\n" .. debug.traceback(co))
	end
end
local function start(f, ...)
	local co = coroutine.create(f)
	ours[co] = true
	resume(co, ...)
	return co
end
local realTask, realOs = env.task, env.os
-- (the service's copy reads these from its own globals; the stand-in bodies below use `wound`,
-- since this file's own `task` is the harness's, which never waits)
local wound
wound = {
	spawn = start,
	defer = start,
	delay = function(t, f, ...)
		local co = coroutine.create(f)
		ours[co] = true
		table.insert(sleeping, { co = co, at = now + (t or 0), args = { ... } })
		return co
	end,
	wait = function(t)
		local co = coroutine.running()
		if ours[co] then
			table.insert(sleeping, { co = co, at = now + (t or 0.03) })
			coroutine.yield()
		end
		return t or 0.03
	end,
	cancel = function() end,
}
env.task = wound
env.os = setmetatable({
	clock = function()
		return now
	end,
	time = function()
		return math.floor(now)
	end,
}, { __index = os })
local watch = nil -- called every tenth of a second
local function advance(seconds)
	for _ = 1, math.floor(seconds * 10 + 0.5) do
		now += 0.1
		local due = {}
		for i = #sleeping, 1, -1 do
			if sleeping[i].at <= now then
				table.insert(due, 1, table.remove(sleeping, i))
			end
		end
		for _, e in due do
			if coroutine.status(e.co) == "suspended" then
				resume(e.co, table.unpack(e.args or {}))
			end
		end
		if watch then
			watch()
		end
	end
end
local function dayIndex()
	return math.floor(now / D.Length)
end
-- the clock wound on to an hour of the day (today's, or the next day's when that hour is past)
local function until_(h)
	local wait = ((h - hourAt(now)) % 24) / 24 * D.Length
	advance(wait)
end

-- the town: the starting house and its workshop, the builder's bench in it; a builder who is
-- the laziest sort, and two villagers with no job
local profile = Schema.newProfile()
profile.plan = StarterHouse.plan()
local benchKey
for key, item in profile.plan.items do
	if item.id == "work_builder" then
		benchKey = key
	end
end
for i, who in { { "Mara", "easygoing" }, { "Tobin", "sunny" }, { "Ivy", "shy" } } do
	local input = Schema.cleanVillagerInput({ name = who[1], pers = who[2], app = Appearance.default() })
	profile.villagers["v" .. i] = Schema.newVillager("v" .. i, input, Rng.new(i))
	profile.villagers["v" .. i].dayOff = nil
	table.insert(profile.order, "v" .. i)
end
local worker = profile.villagers.v1
worker.job = benchKey
for _, vid in { "v2", "v3" } do
	profile.villagers[vid].job = nil
end

-- the builder's loop in the world, as the brain works it out
local bench = profile.plan.items[benchKey]
local benchFrame = Town.plotFrame(1) * Plan.itemFrame(profile.plan, bench)
local loop = Routine.loop(Catalog.get("work_builder"))
local spots = {}
for i, stop in loop do
	spots[i] = benchFrame * stop.at
end
local walls = {} -- points no walk reaches (a spot walled off)
local function walled(p)
	for _, w in walls do
		if flat(p, w) < 0.5 then
			return true
		end
	end
	return false
end
-- which of the loop's spots a body stands on, if any
local function spotOf(pos)
	for i, s in spots do
		if flat(pos, s) < 0.5 then
			return i
		end
	end
	return nil
end

local function person(name, id)
	local root = { Position = Vector3.new(0, 3, 0) }
	function root.IsA(_, class)
		return class == "BasePart"
	end
	local p = { Name = name, UserId = id, Parent = game, root = root }
	p.Character = {
		FindFirstChild = function(_, child)
			return if child == "HumanoidRootPart" then root else nil
		end,
	}
	function p.SetAttribute() end
	return p
end
local owner = person("Owner", 1)

-- bodies that walk at walking pace and remember what they were told to do
local bodies = {}
local fakeNpc = {}
fakeNpc.__index = fakeNpc
function fakeNpc.new(model, vid)
	local self = setmetatable({
		model = model,
		vid = vid,
		pos = Town.plotArrival(1).Position + Vector3.new(0, 3, 0),
		token = 0,
		sleeping = false,
		seat = nil,
		walks = 0,
		walkedAt = now,
		said = {},
		icons = {},
		gestures = {},
		faced = {},
		triggered = Harness.signal(),
	}, fakeNpc)
	bodies[vid] = self
	return self
end
function fakeNpc:position()
	return self.pos
end
function fakeNpc:walkTo(target, _, maxPath)
	self.token += 1
	local token = self.token
	if walled(target) then
		return false, "noroute"
	end
	local d = flat(self.pos, target)
	if maxPath and d > maxPath then
		return false, "far"
	end
	self.walks += 1
	self.walkedAt = now
	wound.wait(d / WALK + 0.1)
	if self.token ~= token then
		return false, "cancelled"
	end
	self.pos = target
	self.walkedAt = now
	return true
end
function fakeNpc:routeLength(target)
	return if walled(target) then nil else flat(self.pos, target)
end
function fakeNpc:halt()
	self.token += 1
end
function fakeNpc:face(point)
	self.token += 1
	table.insert(self.faced, point)
end
function fakeNpc:say(text)
	table.insert(self.said, text)
end
function fakeNpc:icon(kind)
	table.insert(self.icons, kind)
end
function fakeNpc:gesture(kind)
	table.insert(self.gestures, kind)
end
function fakeNpc:setTalkable(on)
	self.canTalk = on
end
function fakeNpc:talkPrompt()
	return { Triggered = self.triggered }
end
function fakeNpc:destroy()
	self.model.Parent = nil
end
for _, name in { "setName", "play", "stop", "standUp", "sleep", "claim" } do
	fakeNpc[name] = function() end
end
function fakeNpc:sit()
	return false
end
function fakeNpc.useSeat() end

local coins = 0
local leaving = Harness.signal()
local oldPlayers = game:GetService("Players")
Harness.addService("Players", {
	PlayerRemoving = leaving,
	GetPlayers = function()
		return { owner }
	end,
})
Harness.addService("CollectionService", {
	GetTagged = function()
		return {}
	end,
	GetInstanceAddedSignal = function()
		return Harness.signal()
	end,
})
local stubbed = { "Data", "Plots", "Build", "World", "Avatar" }
Harness.stub(Services .. "Data", {
	get = function(player)
		return if player == owner then profile else nil
	end,
	notify = function() end,
	push = function() end,
	addCoins = function(_, n)
		coins += n
	end,
	log = function() end,
})
local folder = {}
Harness.stub(Services .. "Plots", {
	Ready = Harness.signal(),
	indexOf = function(player)
		return if player == owner then 1 else nil
	end,
	villagerFolder = function()
		return folder
	end,
	buildFolder = function()
		return nil
	end,
})
Harness.stub(Services .. "Build", { Changed = Harness.signal() })
Harness.stub(Services .. "World", {
	ClockChanged = { Event = Harness.signal() },
	NewDay = { Event = Harness.signal() },
	dayIndex = dayIndex,
	hour = function()
		return hourAt(now)
	end,
})
Harness.stub(Services .. "Avatar", {
	buildModel = function()
		local model = {}
		function model.PivotTo() end
		function model.FindFirstChild()
			return nil
		end
		function model.SetAttribute() end
		function model.Destroy() end
		return model
	end,
})
Harness.stub("ServerScriptService.Server.Npc.Npc", fakeNpc)
Harness.stub(Shared .. "Net.Remotes", {
	event = function()
		return { FireClient = function() end }
	end,
	fn = function()
		return {}
	end,
})
-- the same choices every run
Harness.stub(Shared .. "Util.Rng", {
	new = function(seed)
		return Rng.new(seed or 1234)
	end,
})
Harness.stub(Services .. "Villagers", nil)
local Villagers = require(Services .. "Villagers")
-- the breaks the brain takes, as it tells Routine (put back at the end of this spec)
local realDone, breaks = Routine.done, {}
Routine.done = function(state, turn, seconds, rng, walk)
	if turn.kind == "break" then
		table.insert(breaks, { what = turn.what, planned = turn.seconds, took = seconds })
	end
	return realDone(state, turn, seconds, rng, walk)
end
Villagers.start()

-- only this spec's copy of the service keeps the stand-ins and the wound clock
env.task, env.os = realTask, realOs
for _, name in stubbed do
	Harness.stub(Services .. name, nil)
end
Harness.stub("ServerScriptService.Server.Npc.Npc", nil)
Harness.stub(Shared .. "Net.Remotes", nil)
Harness.stub(Shared .. "Util.Rng", Rng)
Harness.stub(Services .. "Villagers", nil)
Harness.addService("Players", oldPlayers)

-- What one work day comes to: wound from nine to five, a look at everyone every tenth of a
-- second. `during` is called once, a third of the way through.
local function workday(during)
	until_(D.WorkStart)
	table.clear(breaks)
	local log = { samples = 0, atSpot = 0, names = {}, away = 0, stillest = {}, atWorkAway = 0, breaks = breaks }
	for _, vid in { "v2", "v3" } do
		bodies[vid].walkedAt = now
		log.stillest[vid] = 0
	end
	local w = bodies.v1
	watch = function()
		log.samples += 1
		local i = spotOf(w.pos)
		if i then
			log.atSpot += 1
			log.names[loop[i].name] = true
		elseif flat(w.pos, spots[1]) > 3 then
			log.away += 1
			if w.atWork then
				log.atWorkAway += 1
			end
		end
		for _, vid in { "v2", "v3" } do
			local b = bodies[vid]
			if Villagers.control(owner, vid) then
				b.walkedAt = now
			end
			log.stillest[vid] = math.max(log.stillest[vid], now - b.walkedAt)
		end
	end
	local third = workDay / 3
	advance(third)
	if during then
		during()
	end
	advance(workDay - third - 0.2)
	watch = nil
	log.breaks = table.clone(breaks)
	return log
end

describe("Villager routine", function()
	local first, gestures, said, walks, coinsBefore
	it("keeps the builder at the bench two thirds of the work day or more", function()
		until_(8.5)
		walks = { v2 = bodies.v2.walks, v3 = bodies.v3.walks }
		coinsBefore = coins
		table.clear(bodies.v1.gestures)
		table.clear(bodies.v1.said)
		first = workday()
		gestures, said = bodies.v1.gestures, bodies.v1.said
		expect(first.atSpot / first.samples > 2 / 3).toBeTruthy()
	end)

	it("goes round the bench's loop, hammering and talking about the work", function()
		for _, stop in loop do
			expect(first.names[stop.name]).toBe(true)
		end
		local hammer = 0
		for _, g in gestures do
			if g == "toolslash" then
				hammer += 1
			end
		end
		expect(hammer >= 20).toBeTruthy()
		local job = Jobs.get("builder")
		local lines = 0
		for _, s in said do
			if table.find(job.lines, s) then
				lines += 1
			end
		end
		expect(lines >= 2).toBeTruthy()
		-- turned to the bench at its spot, not with their back to it
		local faced = bodies.v1.faced
		expect(#faced > 10).toBeTruthy()
	end)

	it("takes a break away from the bench, and is not at work while on it", function()
		-- the laziest sort: a break or two a day, each one short
		expect(#first.breaks >= 1).toBeTruthy()
		for _, b in first.breaks do
			expect(b.planned <= K.BreakCap).toBeTruthy()
			expect(b.took <= K.BreakCap + 10).toBeTruthy()
		end
		expect(first.away > 0).toBeTruthy()
		-- away for a while, but nowhere near most of the day
		expect(first.away / first.samples < 1 / 3).toBeTruthy()
		expect(first.atWorkAway).toBe(0)
	end)

	it("keeps the villagers with no job on the move", function()
		for _, vid in { "v2", "v3" } do
			expect(bodies[vid].walks - walks[vid] >= 10).toBeTruthy()
			if first.stillest[vid] >= 30 then
				error(string.format("%s stood still for %.1f seconds", vid, first.stillest[vid]))
			end
		end
	end)

	it("has them call at the workplace now and then, and the town earns from it", function()
		expect(coins - coinsBefore >= Tuning.Jobs.VisitCoins).toBeTruthy()
		expect((coins - coinsBefore) % Tuning.Jobs.VisitCoins).toBe(0)
	end)

	it("sends them home at five", function()
		until_(17.5)
		expect(bodies.v1.atWork).toBe(false)
		expect(Villagers.working(owner, "v1")).toBe(false)
	end)

	it("stops for a talk where they stand, then goes back to work", function()
		local log = workday(function()
			local w = bodies.v1
			-- at the bench, stood still for a moment
			for _ = 1, 200 do
				if spotOf(w.pos) and w.atWork then
					break
				end
				advance(0.2)
			end
			expect(w.atWork).toBe(true)
			owner.root.Position = w.pos
			local at, walks0 = w.pos, w.walks
			w.triggered:Fire(owner)
			expect(Villagers.control(owner, "v1")).toBe("talk")
			advance(Tuning.Talk.StaySeconds - 1)
			expect(w.walks).toBe(walks0)
			expect(w.pos).toBe(at)
			advance(12)
			-- (somebody may be in the middle of buying something from them by now)
			expect(Villagers.control(owner, "v1") ~= "talk").toBeTruthy()
			advance(6)
			expect(spotOf(w.pos) ~= nil).toBeTruthy()
		end)
		expect(log.atSpot / log.samples > 0.6).toBeTruthy()
	end)

	it("walks back to work after an event takes them off", function()
		workday(function()
			local w = bodies.v1
			Villagers.setControl(owner, "v1", "event")
			w.pos = w.pos + Vector3.new(40, 0, 25)
			advance(10)
			expect(w.walks >= 0).toBeTruthy()
			Villagers.setControl(owner, "v1", nil)
			advance(20)
			expect(spotOf(w.pos) ~= nil).toBeTruthy()
			expect(w.atWork).toBe(true)
		end)
	end)

	it("leaves out a spot walled off from the bench, and works the rest", function()
		local planks
		for i, stop in loop do
			if stop.name == "planks" then
				planks = i
			end
		end
		walls = { spots[planks] + Vector3.new(0, 3, 0) }
		local log = workday()
		walls = {}
		expect(log.names.planks).toBe(nil)
		expect(log.names.tools).toBe(true)
		expect(log.atSpot / log.samples > 2 / 3).toBeTruthy()
	end)

	it("has a day off on their day off, and stays in bed when sick", function()
		until_(8.9)
		worker.dayOff = dayIndex() + 1
		local log = workday()
		expect(log.atSpot / log.samples < 0.2).toBeTruthy()
		expect(log.atWorkAway).toBe(0)
		worker.dayOff = nil
		until_(8.9)
		worker.sick = math.floor(now) + 2 * D.Length
		local sickWalks = bodies.v1.walks
		log = workday()
		expect(bodies.v1.atWork).toBe(false)
		expect(log.atSpot / log.samples < 0.2).toBeTruthy()
		-- (no bed in this town: they mope about a little, as they always have)
		expect(bodies.v1.walks - sickWalks < 40).toBeTruthy()
		worker.sick = nil
	end)

	it("is nobody at work at night", function()
		until_(23)
		for vid in profile.villagers do
			expect(bodies[vid].atWork == true).toBe(false)
		end
	end)

	it("ran without a single error in the background", function()
		Routine.done = realDone
		for _, e in errors do
			print(e)
		end
		expect(#errors).toBe(0)
	end)
end)
