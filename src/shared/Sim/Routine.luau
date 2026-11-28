--!strict
-- A villager's day, as choices. The user: "villagers seem to stand around doing nothing. they
-- should be at their work stations instead, and taking breaks sometimes to do different things".
-- Nothing here touches the world: given the hour, who they are and how their day has gone so
-- far, `Routine.next` says what they do now, and Services/Villagers (the brain) acts it out and
-- tells `Routine.done` how long it took.
--   work    a villager with a job spends the work day at their workplace, going round the job's
--           own loop of spots (Routine.loop): behind the counter, at the shelf, at the board.
--   break   now and then they leave it for a little while: a sit down, a word with a neighbour,
--           a stroll, a call at somebody else's workplace, a stretch, a go at something near
--           (Sim/Uses: the piano, a swing, the fridge). Who they are decides how often, how long
--           and what (Personalities' lazy, focus, social and mischief).
--   potter  off work, on a day off, or with no job: small things one after another, and hardly
--           ever just standing.
--   sleep   at night, and all day when they are sick.
-- Seconds are real ones. The numbers are Tuning.Routine; tests/specs/Routine.spec.luau runs
-- seeded days against what they promise.

local Tuning = require(script.Parent.Parent.Config.Tuning)
local Personalities = require(script.Parent.Parent.Data.Personalities)
local Jobs = require(script.Parent.Parent.Data.Jobs)
local Rng = require(script.Parent.Parent.Util.Rng)

local K = Tuning.Routine
local D = Tuning.Day

local Routine = {}

-- The loops ------------------------------------------------------------------------------------
--
-- A job's loop is a short round of its workplace (Build/Recipes/Work): where to stand, what to
-- face, how long, and what to do there. Spots are in the workplace's own space (+Z is its front,
-- the customer's side) and name the part of the recipe they are for. A step with no `at` stands
-- on the workplace's own `workSpot`, and with no `look` faces the way `workYaw` says (0 is +Z).
-- Every spot is clear of the workplace's own parts by a villager's width (the spec checks it
-- against the recipe); in a tight room one may still be walled off, and then it is left out.

type Step = {
	name: string,
	at: Vector3?,
	look: Vector3?,
	stay: { number }, -- seconds: least, most
	act: string?, -- one of Npc's animations
	beat: number?, -- seconds between two goes at it, for work that repeats (hammering, writing)
	icon: string?, -- a symbol over their head now and then (Npc.icon)
	say: number?, -- how likely a line from the job's `lines` is here
}

-- A step as the brain gets it: everything filled in.
export type Stop = {
	name: string,
	at: Vector3,
	look: Vector3,
	stay: { number },
	act: string?,
	beat: number?,
	icon: string?,
	say: number,
	home: boolean, -- on the workplace's own workSpot
}

local function V(x: number, y: number, z: number): Vector3
	return Vector3.new(x, y, z)
end

local LOOPS: { [string]: { Step } } = {
	-- Market stall: serve from the middle, see to the crates of fruit at each end of the counter,
	-- then round to the front to look the display over as a customer would.
	shopkeeper = {
		{ name = "till", stay = { 7, 11 }, act = "wave", say = 0.45 },
		{ name = "left crates", at = V(-2.2, 0, -2.6), look = V(-2.9, 3.6, 0), stay = { 4, 7 }, act = "point" },
		{ name = "till", stay = { 5, 8 }, say = 0.3 },
		{ name = "right crates", at = V(2.2, 0, -2.6), look = V(2.9, 3.6, 0), stay = { 4, 7 }, act = "point" },
		{ name = "front", at = V(1, 0, 2.8), look = V(1, 3.6, 0), stay = { 4, 6 }, icon = "sparkle" },
	},
	-- Cafe counter: take the order, make it at the machine, hand it over, see to the cakes.
	barista = {
		{ name = "till", stay = { 6, 9 }, act = "wave", say = 0.4 },
		{
			name = "machine",
			at = V(-2.3, 0, -2.8),
			look = V(-2.3, 4.4, -0.2),
			stay = { 5, 8 },
			act = "point",
			beat = 4,
		},
		{ name = "till", stay = { 4, 6 }, say = 0.5 },
		{ name = "cakes", at = V(2.6, 0, -2.8), look = V(2.6, 4, 0), stay = { 4, 6 } },
	},
	-- Bread oven (the baker stands in front of its mouth): watch the fire, look in from the
	-- side, draw the loaves, then turn round to the room with them.
	baker = {
		{ name = "oven", stay = { 7, 10 }, icon = "sweat" },
		{ name = "side", at = V(-4.4, 0, 0.6), look = V(0, 3, 0.6), stay = { 4, 6 } },
		{ name = "oven", stay = { 4, 7 }, act = "point" },
		{ name = "room", at = V(0, 0, 5.4), look = V(0, 3, 16), stay = { 4, 6 }, act = "cheer", say = 0.7 },
	},
	-- Flower cart: all the way round it, a side at a time, tending the buckets.
	florist = {
		{ name = "back", stay = { 6, 9 }, say = 0.35 },
		{ name = "right end", at = V(4.3, 0, 0), look = V(2, 3.4, 0), stay = { 4, 6 }, act = "point" },
		{ name = "front", at = V(0, 0, 2.7), look = V(0, 3.4, 0), stay = { 4, 6 }, icon = "sparkle", say = 0.3 },
		{ name = "left end", at = V(-4.3, 0, 0), look = V(-2, 3.4, 0), stay = { 4, 6 }, act = "point" },
	},
	-- Easel: paint, step back to look, paint, load the brush at the palette, and lean out past
	-- the canvas for a look at whatever is being painted.
	artist = {
		{ name = "canvas", stay = { 5, 8 }, act = "point", beat = 3 },
		{ name = "step back", at = V(0, 0, -5.4), look = V(0, 4, 0.2), stay = { 3, 5 }, icon = "idea", say = 0.4 },
		{ name = "canvas", stay = { 4, 7 }, act = "point", beat = 3 },
		{ name = "palette", at = V(2.6, 0, -2.2), look = V(1.2, 1.4, -1), stay = { 3, 4 } },
		{ name = "subject", at = V(-2.6, 0, -1.2), look = V(-2.6, 3, 12), stay = { 3, 5 }, say = 0.5 },
	},
	-- Clinic desk: notes at the screen, the patient on the bed (from its head end), notes
	-- again, then along the desk to call the next one in.
	doctor = {
		{ name = "desk", look = V(-0.8, 3.7, -0.1), stay = { 8, 12 }, say = 0.2 },
		{ name = "bed", at = V(3.4, 0, -3.8), look = V(3.4, 2.8, 0), stay = { 5, 8 }, act = "point", say = 0.4 },
		{ name = "desk", look = V(-0.8, 3.7, -0.1), stay = { 5, 8 } },
		{ name = "next", at = V(0.6, 0, -2.6), look = V(0.6, 3, 12), stay = { 3, 5 }, act = "wave", say = 0.6 },
	},
	-- Chalkboard: talk to the class from in front of the desk, write on one half of the board,
	-- talk, write on the other half.
	teacher = {
		{ name = "class", stay = { 6, 9 }, say = 0.6 },
		{
			name = "board left",
			at = V(-2.5, 0, 1.1),
			look = V(-2.5, 4.6, -0.6),
			stay = { 5, 8 },
			act = "point",
			beat = 3,
		},
		{ name = "class", stay = { 4, 6 }, act = "point", say = 0.4 },
		{
			name = "board right",
			at = V(2.5, 0, 1.1),
			look = V(2.5, 4.6, -0.6),
			stay = { 5, 8 },
			act = "point",
			beat = 3,
		},
	},
	-- Little stage: a song at the mic, a turn to each side of the crowd, a bow, and a fiddle
	-- with the speaker before the next one.
	musician = {
		{ name = "mic", stay = { 9, 13 }, act = "dance", icon = "music", say = 0.4 },
		{
			name = "stage left",
			at = V(-1.9, 0.5, 0.5),
			look = V(-5, 0.5, 12),
			stay = { 5, 7 },
			act = "dance2",
			icon = "music",
		},
		{
			name = "stage right",
			at = V(1.9, 0.5, 0.5),
			look = V(5, 0.5, 12),
			stay = { 5, 7 },
			act = "dance2",
			icon = "music",
		},
		{ name = "bow", stay = { 3, 5 }, act = "cheer", say = 0.6 },
		{ name = "speaker", at = V(1.3, 0.5, -1.5), look = V(3.3, 2, -2.2), stay = { 3, 5 } },
	},
	-- Builder's bench (the builder stands in front of it): hammer, fetch a tool, hammer, measure
	-- the planks, then a step back to look the job over.
	builder = {
		{ name = "bench", stay = { 6, 9 }, act = "toolslash", beat = 2.2, say = 0.3 },
		{ name = "tools", at = V(-1.7, 0, 2.8), look = V(-1.7, 3.5, 0.3), stay = { 3, 5 }, act = "point" },
		{ name = "bench", stay = { 5, 8 }, act = "toolslash", beat = 2.2 },
		{ name = "planks", at = V(1.7, 0, 2.8), look = V(1.7, 3.6, -0.4), stay = { 4, 6 }, act = "point", say = 0.3 },
		{ name = "step back", at = V(0.5, 0, 4.8), look = V(0, 3, 0), stay = { 3, 4 }, icon = "idea" },
	},
	-- Post office desk: serve, stamp the parcels, serve, then round the end of the desk to sort
	-- letters into the pigeonholes.
	postie = {
		{ name = "desk", stay = { 6, 9 }, act = "wave", say = 0.4 },
		{ name = "parcels", at = V(-1.4, 0, -2.7), look = V(-1.4, 3.8, 0), stay = { 4, 7 }, act = "point", beat = 3 },
		{ name = "desk", stay = { 4, 6 }, say = 0.3 },
		{ name = "pigeonholes", at = V(4.9, 0, 0), look = V(3.5, 3, 0), stay = { 5, 8 }, act = "point", beat = 2.5 },
	},
	-- Ice cream cart: take the order, a scoop from one tub and the next, hand it over, then out
	-- beside the cart to call people over.
	icecream = {
		{ name = "serve", stay = { 5, 8 }, act = "wave", say = 0.45 },
		{ name = "left tub", at = V(-1.3, 0, -2.8), look = V(-1.3, 3.6, 0), stay = { 3, 5 }, act = "point" },
		{ name = "right tub", at = V(1.3, 0, -2.8), look = V(1.3, 3.6, 0), stay = { 3, 5 }, act = "point" },
		{ name = "serve", stay = { 3, 5 }, say = 0.4 },
		{ name = "call out", at = V(-4, 0, 0.8), look = V(-4, 3, 12), stay = { 4, 6 }, act = "cheer", say = 0.5 },
	},
	-- Library desk: a long quiet spell stamping books, some back on the shelf at the end of the
	-- desk, more stamping, then out on the floor to hush somebody.
	librarian = {
		{ name = "desk", look = V(-1.4, 3.6, 0), stay = { 9, 14 }, say = 0.25 },
		{ name = "shelf", at = V(2.2, 0, -2.6), look = V(3.6, 4, 0), stay = { 5, 8 }, act = "point", beat = 3.5 },
		{ name = "desk", look = V(-1.4, 3.6, 0), stay = { 6, 9 } },
		{ name = "floor", at = V(-1, 0, 3.2), look = V(-1, 3, 12), stay = { 3, 5 }, say = 0.6 },
	},
}

-- How each job looks at work. The user: "let there be animations while a villager works". A step
-- with no gesture of its own takes its job's move, again every `beat` seconds, and so does one
-- with a gesture but no beat: nobody stands still at work. (A villager the player bought an emote
-- for does that at every step instead: Sim/WorkMove.)
local MOVES: { [string]: { act: string, beat: number } } = {
	shopkeeper = { act = "point", beat = 3.5 }, -- setting out the stock
	barista = { act = "point", beat = 3 }, -- at the machine and the cups
	baker = { act = "toollunge", beat = 4 }, -- the peel in and out of the oven
	florist = { act = "point", beat = 3.5 }, -- trimming and tying
	artist = { act = "point", beat = 3 }, -- brush strokes
	doctor = { act = "point", beat = 4 }, -- notes and checks
	teacher = { act = "point", beat = 3.5 }, -- at the board
	musician = { act = "dance", beat = 6 },
	builder = { act = "toolslash", beat = 2.2 }, -- the hammer
	postie = { act = "point", beat = 3 }, -- stamping and sorting
	icecream = { act = "point", beat = 3 }, -- scooping
	librarian = { act = "point", beat = 4 }, -- stamping the cards
}
local PLAIN_MOVE = { act = "point", beat = 4 }

-- The move a job's work looks like at a step with none of its own.
function Routine.move(job: string?): (string, number)
	local m = (job and MOVES[job]) or PLAIN_MOVE
	return m.act, m.beat
end

-- A workplace whose job has no loop of its own yet: its spot, and a step along it to each side.
local function plainLoop(def: any, home: Vector3): { Step }
	local side = math.max(1.5, def.size.X / 4)
	return {
		{ name = "spot", stay = { 6, 10 }, act = "wave", say = 0.35 },
		{ name = "left", at = home + V(-side, 0, 0), look = V(home.X - side, 3, 0), stay = { 4, 7 } },
		{ name = "spot", stay = { 5, 8 }, say = 0.25 },
		{ name = "right", at = home + V(side, 0, 0), look = V(home.X + side, 3, 0), stay = { 4, 7 } },
	}
end

-- Does this job have a loop of its own?
function Routine.has(job: string): boolean
	return LOOPS[job] ~= nil
end

-- Which stop of a loop is the workplace's own spot (where the day's work starts).
function Routine.home(loop: { Stop }): number
	for i, stop in loop do
		if stop.home then
			return i
		end
	end
	return 1
end

local loops: { [string]: { Stop } } = {}

-- The loop a villager goes round at a workplace (a catalog def with a `job`), in its own space.
function Routine.loop(def: any): { Stop }
	local made = loops[def.id]
	if made then
		return made
	end
	-- (the default spot is the one Services/Villagers has always used)
	local home: Vector3 = def.workSpot or V(0, 0, -(def.size.Z / 2 + 1.5))
	local yaw = math.rad(def.workYaw or 0)
	local ahead = V(math.sin(yaw), 0, math.cos(yaw))
	local steps = LOOPS[def.job] or plainLoop(def, home)
	local moveAct, moveBeat = Routine.move(def.job)
	local out: { Stop } = table.create(#steps)
	for i, s in steps do
		local at = s.at or home
		out[i] = {
			name = s.name,
			at = at,
			look = s.look or (at + ahead * 10 + V(0, 3, 0)),
			stay = s.stay,
			act = s.act or moveAct,
			beat = s.beat or moveBeat,
			icon = s.icon,
			say = s.say or 0,
			home = s.at == nil,
		}
	end
	loops[def.id] = out
	return out
end

-- Who breaks how much ------------------------------------------------------------------------------

-- The seconds in a work day.
function Routine.workDay(): number
	return (D.WorkEnd - D.WorkStart) / 24 * D.Length
end

-- The part of a work day somebody of this personality spends on breaks.
function Routine.breakShare(pers: string): number
	local lazy = Personalities.trait(pers, "lazy")
	local focus = Personalities.trait(pers, "focus")
	return math.clamp(K.BreakShare + K.LazyShare * (lazy - 0.5) - K.FocusShare * (focus - 0.5), K.ShareMin, K.ShareMax)
end

-- How long one of their breaks lasts: the least and the most seconds.
function Routine.breakLength(pers: string): (number, number)
	local k = 1 + K.LazyLonger * Personalities.trait(pers, "lazy")
	return math.min(K.BreakMin * k, K.BreakCap), math.min(K.BreakMax * k, K.BreakCap)
end

-- The seconds they usually work between two breaks.
function Routine.gap(pers: string): number
	local lo, hi = Routine.breakLength(pers)
	local share = Routine.breakShare(pers)
	return (lo + hi) / 2 * (1 - share) / share
end

-- The day so far, and what comes next ------------------------------------------------------------------

-- One villager's day as it has gone. The brain keeps one for each body.
export type Day = {
	day: number, -- the in-game day these counts are for
	atWork: number, -- seconds at the workplace today
	away: number, -- seconds away from it on breaks, the walk back included
	breaks: number, -- breaks taken today
	stretch: number, -- seconds at work since they got there, or since the last break
	due: number, -- the stretch after which the next break is due
	gap: number, -- their usual stretch between two breaks
	onBreak: boolean, -- out on a break, or on the way back from one
	step: number, -- where in the job's loop they are (0 before the first step)
	said: number, -- which of the job's lines they said last (0 when none yet)
	lastBreak: string?, -- the last kind of break, and the last thing done off work, so that
	last: string?, -- neither is done twice running
}

-- What Routine.next is told.
export type Ctx = {
	hour: number, -- the town's clock, 0 to 24
	day: number, -- the in-game day
	pers: string, -- their personality
	job: string?, -- their job, when they have a workplace to go to
	loop: { Stop }?, -- that workplace's loop (Routine.loop)
	sick: boolean?,
	dayOff: boolean?,
	-- what there is to do just now: `sit` (a free seat), `chat` (somebody free), `visit` (a
	-- workplace with its worker at it), `look` (something worth a look), `use` (a piece near to
	-- have a go at: Sim/Uses). Only false rules out.
	can: { [string]: boolean }?,
	-- steps of the loop they found no way to (never the workplace's own spot)
	blocked: { [number]: boolean }?,
	-- kinds made likelier just now, by how much (Tuning.Visits: the player at work near, or sat
	-- down with a free seat beside them)
	boost: { [string]: number }?,
	-- somebody is serving out of work hours (the player at a workplace): a call there is open
	serving: boolean?,
}

-- What they do now.
export type Turn = {
	kind: string, -- "sleep", "work", "break" or "potter"
	what: string?, -- a break: sit, chat, stroll, visit, stretch, use. Pottering: those but stretch, and look, gesture, idle
	-- (a "use" lasts as long as the piece's own stay, or what is left of the break: Sim/Uses)
	step: number?, -- work: which step of the loop
	seconds: number, -- how long: at the spot (work), for the whole break, or at the end of it (pottering)
	say: string?, -- work: a line from the job to say here
	line: number?, -- which of the job's lines that is
}

function Routine.newDay(): Day
	return {
		day = -1,
		atWork = 0,
		away = 0,
		breaks = 0,
		stretch = 0,
		due = math.huge,
		gap = math.huge,
		onBreak = false,
		step = 0,
		said = 0,
		lastBreak = nil,
		last = nil,
	}
end

-- "sleep" at night and when sick, "work" in work hours with a job and no day off, else "free".
function Routine.phase(ctx: Ctx): string
	local h = ctx.hour
	if ctx.sick or h >= D.BedTime or h < D.WakeTime then
		return "sleep"
	end
	if ctx.job and not ctx.dayOff and h >= D.WorkStart and h < D.WorkEnd then
		return "work"
	end
	return "free"
end

-- A new day: the counts start again, and the first break is some way off.
local function dawn(state: Day, ctx: Ctx, rng: Rng.Rng)
	state.day = ctx.day
	state.atWork, state.away, state.breaks, state.stretch = 0, 0, 0, 0
	state.onBreak = false
	state.step = 0
	state.gap = Routine.gap(ctx.pers)
	state.due = state.gap * rng:float(K.FirstBreak, 1)
end

type Weight = { kind: string, base: number, trait: string, per: number }

-- Picks one of `list` by its weights for this personality. `can` rules kinds out, `last` is
-- less likely to come up again, `skip` says which others are out this time.
local function pick(
	list: { Weight },
	ctx: Ctx,
	last: string?,
	rng: Rng.Rng,
	skip: ((kind: string) -> boolean)?
): string?
	local can = ctx.can
	local chosen = rng:weighted(list, function(w: Weight): number
		if (can and can[w.kind] == false) or (skip and skip(w.kind)) then
			return 0
		end
		local weight = math.max(0, w.base + w.per * Personalities.trait(ctx.pers, w.trait))
		local boost = ctx.boost and ctx.boost[w.kind]
		if type(boost) == "number" and boost > 0 and boost < math.huge then
			weight *= boost
		end
		return if w.kind == last then weight * K.Repeat else weight
	end)
	return chosen and chosen.kind
end

-- Is a break due, and is there room for one? Then which, and for how long.
local function breakNow(ctx: Ctx, state: Day, rng: Rng.Rng): Turn?
	if state.stretch < state.due then
		return nil
	end
	local lo, hi = Routine.breakLength(ctx.pers)
	local seconds = rng:float(lo, hi)
	-- not one that would run past the end of the day (they are off soon enough), and none once
	-- breaks have had their part of it: the workplace is not left empty
	local left = (D.WorkEnd - ctx.hour) / 24 * D.Length
	if seconds > left or state.away + seconds > K.AwayCap * Routine.workDay() then
		return nil
	end
	return { kind = "break", what = pick(K.Breaks, ctx, state.lastBreak, rng) or "stretch", seconds = seconds }
end

-- Could Routine.next send them on a break now? The brain looks round for what there is to do
-- (a free seat, somebody to talk to) only then, and in free time.
function Routine.breakDue(ctx: Ctx, state: Day): boolean
	if Routine.phase(ctx) ~= "work" or state.day ~= ctx.day or state.stretch < state.due then
		return false
	end
	local lo = Routine.breakLength(ctx.pers)
	local left = (D.WorkEnd - ctx.hour) / 24 * D.Length
	return lo <= left and state.away + lo <= K.AwayCap * Routine.workDay()
end

-- The next step of their loop.
local function workNow(ctx: Ctx, state: Day, rng: Rng.Rng): Turn
	local loop = ctx.loop
	if not loop or #loop == 0 then
		return { kind = "work", step = 1, seconds = rng:float(6, 10) }
	end
	local n = #loop
	local step = state.step
	for _ = 1, n do
		step = step % n + 1
		if loop[step].home or not (ctx.blocked and ctx.blocked[step]) then
			break
		end
	end
	local stop = loop[step]
	local turn: Turn = { kind = "work", step = step, seconds = rng:float(stop.stay[1], stop.stay[2]) }
	local job = ctx.job and Jobs.get(ctx.job)
	if job and #job.lines > 0 and stop.say > 0 and rng:chance(stop.say) then
		-- not the line they said last, when there is another
		local line = rng:int(1, #job.lines)
		if line == state.said and #job.lines > 1 then
			line = line % #job.lines + 1
		end
		turn.say = job.lines[line]
		turn.line = line
	end
	return turn
end

-- Something to do with free time.
local function potterNow(ctx: Ctx, state: Day, rng: Rng.Rng): Turn
	local open = ctx.hour >= D.WorkStart and ctx.hour < D.WorkEnd
	local what = pick(K.Potter, ctx, state.last, rng, function(kind: string): boolean
		-- workplaces are staffed in work hours only, and nobody stands about twice running
		-- (or by the player, when they are at work out of hours)
		return (kind == "visit" and not open and not ctx.serving) or (kind == "idle" and state.last == "idle")
	end) or "stroll"
	local seconds = 0
	if what == "sit" then
		seconds = rng:float(K.Sit[1], K.Sit[2]) * (1 + K.LazySit * Personalities.trait(ctx.pers, "lazy"))
	elseif what == "look" then
		seconds = rng:float(K.Look[1], K.Look[2])
	elseif what == "stroll" then
		seconds = rng:float(K.Stroll[1], K.Stroll[2])
	elseif what == "gesture" then
		seconds = K.Gesture
	elseif what == "idle" then
		seconds = rng:float(K.Idle[1], K.Idle[2])
	end
	return { kind = "potter", what = what, seconds = seconds }
end

-- What a villager does now. `state` is their day so far (Routine.newDay, then kept).
function Routine.next(ctx: Ctx, state: Day, rng: Rng.Rng): Turn
	if state.day ~= ctx.day then
		dawn(state, ctx, rng)
	end
	local phase = Routine.phase(ctx)
	if phase == "sleep" then
		return { kind = "sleep", seconds = 0 }
	elseif phase == "work" then
		return breakNow(ctx, state, rng) or workNow(ctx, state, rng)
	end
	return potterNow(ctx, state, rng)
end

-- Tells the day what a turn came to: `seconds` is how long it took in all. For work, `walk` is
-- the part of that spent getting to the workplace from somewhere else (none for a hop between
-- two of its spots): on the way back from a break it counts as part of the break. A work turn
-- that came to nothing (no way to the spot) is told with 0 seconds, and the loop moves on.
function Routine.done(state: Day, turn: Turn, seconds: number, rng: Rng.Rng, walk: number?)
	if turn.kind == "work" then
		local walked = math.clamp(walk or 0, 0, seconds)
		if state.onBreak and seconds > 0 then
			state.away += walked
			state.onBreak = false
		end
		state.step = turn.step or state.step
		state.said = turn.line or state.said
		state.atWork += seconds - walked
		state.stretch += seconds - walked
	elseif turn.kind == "break" then
		state.away += seconds
		state.breaks += 1
		state.onBreak = true
		state.lastBreak = turn.what
		state.stretch = 0
		state.due = state.gap * rng:float(1 - K.GapSpread, 1 + K.GapSpread)
	elseif turn.kind == "potter" then
		state.last = turn.what
	end
end

-- What is worth walking up to for a look: a catalog def with one of these tags, or from one of
-- these tabs.
local SIGHT_TAGS = { "plant", "art", "books", "music", "toy", "games", "tv", "clock", "mirror", "work" }
local SIGHT_TABS = { garden = true, fun = true, decor = true, walldecor = true }

function Routine.sight(def: any): boolean
	if SIGHT_TABS[def.cat] then
		return true
	end
	for _, tag in def.tags or {} do
		if table.find(SIGHT_TAGS, tag) then
			return true
		end
	end
	return false
end

return Routine
