--!strict
-- A player's own work at a workplace. The user: "also, allow players to interact and work at work
-- areas". Every piece with a `job` (a catalog workplace, on its own or inside a ready-made
-- building) carries a prompt (Services/Work): hold E at one on your own plot and your character
-- is stood at its work spot, turned to the work, going at it with the job's own motion. While
-- you stay you earn for your town a little at a time, the way a villager there does, but at a
-- lower rate and only up to a cap each town day (Tuning.Jobs.Player), so a town still lives on
-- its villagers' wages. Walking off, a jump, a seat, a second press, the piece moving or going,
-- Build mode, or the place's own villager coming in for the day ends it.
-- Then: "when players work, make what they earn scale off town level. each skill also has a
-- level/experience bar, which you gain while doing the work. This increases the amount of cash you
-- get doing that particular work as well." So the pay and the day's cap grow with the town's level
-- and with the player's skill at the job (Sim/Skills), both by the same share, so a day's work
-- takes as long as ever and comes to more.
-- Nothing here touches the world: Services/Work asks this who may work where, what it pays and
-- when it stops, and tests/specs/PlayerWork.spec.luau holds it to the economy's bounds.

local Tuning = require(script.Parent.Parent.Config.Tuning)
local Jobs = require(script.Parent.Parent.Data.Jobs)
local Text = require(script.Parent.Parent.Util.Text)
local Routine = require(script.Parent.Routine)
local City = require(script.Parent.City)
local Skills = require(script.Parent.Skills)

local K = Tuning.Jobs.Player
local D = Tuning.Day

local PlayerWork = {}

-- The tag on every work prompt (the client finds them by it), its words, and what a player is
-- told when they can't start or when work stops by itself.
PlayerWork.Tag = "WorkPrompt"
PlayerWork.Action = "Work here"
PlayerWork.StopAction = "Stop work"
PlayerWork.Say = {
	notWork = "That isn't a workplace.",
	notYours = "You can only work in your own town.",
	far = "Come a bit closer to work here.",
	staffed = "{name} works here until {time}.",
	taken = "Someone else is working here.",
	seated = "Stand up first.",
	full = "That's a full day's work. You can work again from {time}.",
	moved = "Your workplace moved, so you stopped work.",
	gone = "Your workplace is gone, so you stopped work.",
	arrived = "{name} is here for work, so you stepped aside.",
	levelUp = "{job} skill is now level {n}.",
}

-- What the work notice says about the skill: the job and its level.
function PlayerWork.skillLine(job: string, level: number, top: boolean?): string
	if top then
		return Text.fill("{job}, top level", { job = job })
	end
	return Text.fill("{job}, level {n}", { job = job, n = level })
end
local Say = PlayerWork.Say

-- Where to stand and what to do ------------------------------------------------------------------

-- Where a player stands at a workplace (a catalog def with a `job`) and what they do there, in
-- the workplace's own space: its work spot, the point they face, and the motion (one of the
-- body's own animations, played again every `beat` seconds). It is what a villager does at the
-- same spot (Sim/Routine's loop): the first step there with something to do, a repeating one
-- (hammering, painting) first. A job with nothing to do at its spot gets Tuning's plain motion.
export type Stance = { at: Vector3, look: Vector3, act: string, beat: number }

function PlayerWork.stance(def: any): Stance
	local loop = Routine.loop(def)
	local pick: Routine.Stop? = nil
	for _, stop in loop do
		if stop.home and stop.act and stop.beat then
			pick = stop
			break
		end
	end
	if not pick then
		for _, stop in loop do
			if stop.home and stop.act then
				pick = stop
				break
			end
		end
	end
	local s = pick or loop[Routine.home(loop)]
	return {
		at = s.at,
		look = s.look,
		act = if pick and pick.act then pick.act else K.Act,
		beat = if pick and pick.beat then pick.beat else K.Beat,
	}
end

-- Where the body's root goes, in the world: the stance's spot under a workplace standing at
-- `frame`, `lift` studs up (the root's height over the feet), turned flat to what they face.
function PlayerWork.standFrame(frame: CFrame, stance: Stance, lift: number): CFrame
	local at = frame * stance.at + Vector3.new(0, lift, 0)
	local look = frame * stance.look
	local ahead = Vector3.new(look.X - at.X, 0, look.Z - at.Z)
	if ahead.Magnitude < 1e-3 then
		ahead = Vector3.new(frame.LookVector.X, 0, frame.LookVector.Z)
	end
	-- (turned by its yaw: CFrame.Angles(0, a, 0) looks along (-sin a, 0, -cos a))
	return CFrame.new(at) * CFrame.Angles(0, math.atan2(-ahead.X, -ahead.Z), 0)
end

-- How far a body's root at `root` is from where it was stood (`target`): across the ground, and
-- up or down.
function PlayerWork.offset(target: Vector3, root: Vector3): (number, number)
	local flat = Vector3.new(root.X - target.X, 0, root.Z - target.Z)
	return flat.Magnitude, root.Y - target.Y
end

-- Pay --------------------------------------------------------------------------------------------

-- What the town's level and the player's skill at the job make of the pay and the day's cap: a
-- share more for each (Sim/Skills.townK and payK). 1 for a new player in a new town.
function PlayerWork.boost(townLevel: number?, skill: number?): number
	return Skills.townK(townLevel or 1) * Skills.payK(skill or 1)
end

-- Coins a second for a player at this workplace: Tuning.Jobs.Player.Share of what a villager new
-- to the job earns there (skill 1, a middling mood, work that is nothing special to them), over
-- the seconds of a work day a villager's pay is spread over (City.workSeconds), grown by the
-- town's level and the player's own skill at the job (PlayerWork.boost).
function PlayerWork.rate(def: any, townLevel: number?, skill: number?): number
	local job = def and def.job and Jobs.get(def.job)
	if not job then
		return 0
	end
	return Jobs.pay(job, 1, 50, "none") * K.Share / City.workSeconds() * PlayerWork.boost(townLevel, skill)
end

-- The most a player can earn at work in a town day: Tuning.Jobs.Player.DayCap, grown the same way.
function PlayerWork.dayCap(townLevel: number?, skill: number?): number
	return math.floor(K.DayCap * PlayerWork.boost(townLevel, skill) + 0.5)
end

-- The player's own purse for town day `day` (World.dayIndex), kept on their profile as `work`
-- so that leaving and coming back doesn't fill it again. A new day starts it again, and a
-- broken one starts fresh.
function PlayerWork.purse(profile: any, day: number): City.Purse
	local p = profile.work
	local ok = type(p) == "table"
		and type(p.day) == "number"
		and type(p.owed) == "number"
		and type(p.paid) == "number"
		and p.owed == p.owed
		and p.paid == p.paid
		and p.owed >= 0
		and p.paid >= 0
	if not ok then
		p = City.newPurse()
		profile.work = p
	end
	if p.day ~= day then
		p.day, p.owed, p.paid = day, 0, 0
	end
	return p
end

-- Has the player earned all they can today? `cap` is the day's (PlayerWork.dayCap; the plain one
-- when not given).
function PlayerWork.full(purse: City.Purse, cap: number?): boolean
	return purse.paid >= (cap or K.DayCap)
end

-- Pays `seconds` of work at `rate` coins a second into the purse for `day`, never past the day's
-- cap (`cap`, PlayerWork.dayCap; the plain one when not given), and takes out the whole coins in
-- it: those go to the town now, the rest waits.
function PlayerWork.earn(purse: City.Purse, day: number, rate: number, seconds: number, cap: number?): number
	if purse.day ~= day then
		purse.day, purse.owed, purse.paid = day, 0, 0
	end
	-- (no rate or time, or one that is not a number at all: nothing)
	if not (rate > 0 and rate < math.huge and seconds > 0 and seconds < math.huge) then
		return 0
	end
	local most = cap or K.DayCap
	if not (most >= 0 and most < math.huge) then
		most = K.DayCap
	end
	local room = math.max(0, most - purse.paid - purse.owed)
	purse.owed += math.min(rate * seconds, room)
	local whole = math.floor(purse.owed + 1e-6)
	purse.owed = math.max(0, purse.owed - whole)
	purse.paid += whole
	return whole
end

-- Who may work where -----------------------------------------------------------------------------

-- Whose working day it is at this workplace (`key` on the plan), by name, or nil: a villager
-- whose job it is, in work hours, not on their day off and not sick. A break doesn't free it:
-- the place is still theirs for the day (as Services/Villagers.working counts it), and they
-- would walk back into whoever was there. `profile` needs `order` and `villagers` (the client's
-- State.data does too).
function PlayerWork.staffedBy(profile: any, key: string, hour: number, day: number, now: number): string?
	if hour < D.WorkStart or hour >= D.WorkEnd then
		return nil
	end
	local villagers = profile.villagers or {}
	for _, vid in profile.order or {} do
		local v = villagers[vid]
		if v and v.job == key and v.dayOff ~= day and not (type(v.sick) == "number" and v.sick > now) then
			return if type(v.name) == "string" then v.name else "?"
		end
	end
	return nil
end

-- What the server knows when a player asks to start: the piece is a workplace (`job`), on their
-- own plot (`own`), how far they stand from its work spot, whose working day it is there
-- (`staff`, PlayerWork.staffedBy), whether another player is at it (`taken`), whether they sit,
-- and whether their day's pay is all earned (`full`).
export type Ask = {
	job: boolean,
	own: boolean,
	distance: number,
	staff: string?,
	taken: boolean?,
	seated: boolean?,
	full: boolean?,
}

-- May they start? False and what they are told when not.
function PlayerWork.canStart(ask: Ask): (boolean, string?)
	if not ask.job then
		return false, Say.notWork
	end
	if not ask.own then
		return false, Say.notYours
	end
	if not (ask.distance <= K.Reach) then
		return false, Say.far
	end
	if ask.staff then
		return false, Text.fill(Say.staffed, { name = ask.staff, time = Text.clock(D.WorkEnd) })
	end
	if ask.taken then
		return false, Say.taken
	end
	if ask.full then
		return false, Text.fill(Say.full, { time = Text.clock(D.StartClock) })
	end
	if ask.seated then
		return false, Say.seated
	end
	return true, nil
end

-- What the server sees of a player at work, every Tuning.Jobs.Player.Check seconds: still in the
-- game in the same body and alive (`here`), how far their root is from where it was stood
-- (PlayerWork.offset: `off` across, `rise` up), whether they sit, whether they were stood there
-- only a moment ago (`settling`: the body may not have caught up yet), the piece ("same",
-- "moved" or "gone"), whose working day has started there (`staff`) and whether the day's pay
-- is all earned (`full`).
export type Watch = {
	here: boolean,
	off: number,
	rise: number,
	seated: boolean?,
	settling: boolean?,
	piece: string,
	staff: string?,
	full: boolean?,
}

-- Why work stops now, or nil to go on: a reason ("left", "gone", "moved", "seated", "walked",
-- "staffed", "full") and what the player is told, if anything (nothing when it was their own
-- doing: they know they walked off).
function PlayerWork.stopWhy(w: Watch): (string?, string?)
	if not w.here then
		return "left", nil
	end
	if w.piece == "gone" then
		return "gone", Say.gone
	end
	if w.piece ~= "same" then
		return "moved", Say.moved
	end
	if w.seated then
		return "seated", nil
	end
	if not w.settling and not (w.off <= K.Leave and math.abs(w.rise) <= K.Rise) then
		return "walked", nil
	end
	if w.staff then
		return "staffed", Text.fill(Say.arrived, { name = w.staff })
	end
	if w.full then
		return "full", Text.fill(Say.full, { time = Text.clock(D.StartClock) })
	end
	return nil, nil
end

return PlayerWork
