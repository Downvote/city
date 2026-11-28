--!strict
-- Lifts between floors (the user: "make ways to travel down, like different hole types, and add
-- elevators"). A lift is a Build mode piece (Build/Recipes/Travel, `travel = "lift"`) standing on
-- one floor and running up `spans` floors, with a landing on each. Holding E at a landing's up or
-- down button (Services/Lifts) sends the car there if it is away, opens the doors to let people
-- in, shuts them, carries everyone in the car a floor up or down and opens the doors again. The
-- server moves the riders; each player's screen moves the car and the doors (World/Lifts), from
-- the same timeline worked out here, so the two keep together. No services, so the specs run it.

local Tuning = require(script.Parent.Parent.Config.Tuning)

local K = Tuning.Lifts
local H = Tuning.Plot.LevelHeight

local Lifts = {}

Lifts.Tag = "LiftPrompt" -- the buttons' prompts (the client hides them in Build mode)
Lifts.DoorSlide = 1.5 -- how far each door leaf slides open
Lifts.Car = { x = 2.9, zBack = -2.45, zFront = 2.35, height = 9 } -- the car's inside, in the piece's space
Lifts.Front = 7 -- how far out from the shaft a caller may stand

-- Is the piece a lift, and how many floors does it climb?
function Lifts.isLift(def: any): boolean
	return type(def) == "table" and def.travel == "lift"
end
function Lifts.spans(def: any): number
	if Lifts.isLift(def) then
		return math.max(1, def.spans or 1)
	end
	return 0
end

-- Where landing k's floor is, in the piece's own space (its own floor is landing 0).
function Lifts.landingY(k: number): number
	return k * H
end

-- The landing a press goes to: a floor up (dir 1) or down (-1) from `at`, if there is one.
function Lifts.target(spans: number, at: number, dir: number): number?
	local to = at + (if dir > 0 then 1 else -1)
	if to < 0 or to > spans or at % 1 ~= 0 then
		return nil
	end
	return to
end

-- A ride: the car fetched from `from` to `call`, its doors open there and shut, it goes to `to`, and
-- the doors open, stand open and shut. Times are seconds from its start.
export type Ride = {
	from: number,
	call: number,
	to: number,
	fetched: number, -- the car is at `call`
	opened: number, -- the doors there are open
	boarded: number, -- they start to shut: the riders are taken
	shut: number, -- shut: the car goes
	arrived: number, -- at `to`: the doors open, the riders are let go
	open: number, -- open there
	closing: number, -- they start to shut
	done: number,
}

function Lifts.ride(from: number, call: number, to: number): Ride
	local fetched = math.abs(call - from) * K.PerFloor
	local opened = fetched + K.Doors
	local boarded = opened + K.Board
	local shut = boarded + K.Doors
	local arrived = shut + math.abs(to - call) * K.PerFloor
	local open = arrived + K.Doors
	local closing = open + K.Open
	return {
		from = from,
		call = call,
		to = to,
		fetched = fetched,
		opened = opened,
		boarded = boarded,
		shut = shut,
		arrived = arrived,
		open = open,
		closing = closing,
		done = closing + K.Doors,
	}
end

local function ease(t: number): number
	t = math.clamp(t, 0, 1)
	return t * t * (3 - 2 * t)
end

-- Where the car is `t` seconds into a ride, in landings (2.5 is halfway between the 2nd and 3rd).
function Lifts.carAt(ride: Ride, t: number): number
	if t <= 0 then
		return ride.from
	elseif t < ride.fetched then
		return ride.from + (ride.call - ride.from) * ease(t / ride.fetched)
	elseif t < ride.shut then
		return ride.call
	elseif t < ride.arrived then
		return ride.call + (ride.to - ride.call) * ease((t - ride.shut) / (ride.arrived - ride.shut))
	end
	return ride.to
end

-- How far open landing k's doors are `t` seconds into a ride (0 shut, 1 open).
function Lifts.doorsAt(ride: Ride, t: number, k: number): number
	if k == ride.call and t >= ride.fetched and t < ride.shut then
		if t < ride.opened then
			return ease((t - ride.fetched) / K.Doors)
		elseif t < ride.boarded then
			return 1
		end
		return 1 - ease((t - ride.boarded) / K.Doors)
	end
	if k == ride.to and t >= ride.arrived and t < ride.done then
		if t < ride.open then
			return ease((t - ride.arrived) / K.Doors)
		elseif t < ride.closing then
			return 1
		end
		return 1 - ease((t - ride.closing) / K.Doors)
	end
	return 0
end

-- A point in the piece's own space: which landing it is at (from just under its floor to the
-- car's roof), if any.
function Lifts.landingOf(spans: number, p: Vector3): number?
	local k = math.floor((p.Y + 1) / H)
	if k < 0 or k > spans then
		return nil
	end
	local up = p.Y - k * H
	if up < -1 or up > Lifts.Car.height then
		return nil
	end
	return k
end

-- Is it inside the car (at a landing, across the shaft)?
function Lifts.inCar(p: Vector3): boolean
	local c = Lifts.Car
	return math.abs(p.X) <= c.x and p.Z >= c.zBack and p.Z <= c.zFront
end

-- Is it in the car or close in front of the doors, where the buttons are pressed from?
function Lifts.atDoors(p: Vector3): boolean
	local c = Lifts.Car
	return math.abs(p.X) <= c.x + 1 and p.Z >= c.zBack and p.Z <= c.zFront + Lifts.Front
end

-- Where a rider stands in the car: where they were, inside its walls.
function Lifts.spot(p: Vector3): Vector3
	local c = Lifts.Car
	return Vector3.new(math.clamp(p.X, -c.x + 1, c.x - 1), 0, math.clamp(p.Z, c.zBack + 1, c.zFront - 1))
end

return Lifts
