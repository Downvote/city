--!strict
-- The rules for vehicles (Data/Vehicles), with no services so the specs can run them: who may buy
-- which, and how one drives (speeding up, braking, turning), which client/World/Driving goes by.
-- The user: "make vehicles, with faster ones with bigger capacities costing more, and gem ones being
-- the fastest".

local Tuning = require(script.Parent.Parent.Config.Tuning)
local VehicleData = require(script.Parent.Parent.Data.Vehicles)
local Gems = require(script.Parent.Gems)

local K = Tuning.Vehicles

local Vehicles = {}

function Vehicles.owns(profile: any, id: string): boolean
	return type(profile) == "table" and type(profile.vehicles) == "table" and profile.vehicles[id] == true
end

-- May this player buy that one now? Returns true, or false and why not.
function Vehicles.canBuy(profile: any, id: any): (boolean, string?)
	local v = VehicleData.get(id)
	if not v then
		return false, "There's no such vehicle."
	end
	if Vehicles.owns(profile, v.id) then
		return false, "You have that one already."
	end
	if v.gems then
		if not Gems.canAfford(profile, v.gems) then
			return false, "Not enough gems."
		end
	elseif (profile.coins or 0) < (v.coins or 0) then
		return false, "Not enough coins."
	end
	return true, nil
end

-- Buys it: takes the price and marks it owned. Returns whether it did (the server's own check
-- comes first: Vehicles.canBuy).
function Vehicles.buy(profile: any, id: string): boolean
	local ok = Vehicles.canBuy(profile, id)
	local v = VehicleData.get(id)
	if not ok or not v then
		return false
	end
	if v.gems then
		if not Gems.spend(profile, v.gems) then
			return false
		end
	else
		profile.coins -= v.coins or 0
	end
	profile.vehicles = profile.vehicles or {}
	profile.vehicles[v.id] = true
	return true
end

-- A profile's vehicles as saved: only ones there are, each true.
function Vehicles.clean(raw: any): { [string]: boolean }
	local out = {}
	if type(raw) == "table" then
		for id, on in raw do
			if on == true and VehicleData.get(id) then
				out[id] = true
			end
		end
	end
	return out
end

-- Driving ------------------------------------------------------------------------------------------

-- The speed after `dt` seconds with the pedal at `throttle` (-1 back to 1 ahead), flat out at `top`:
-- it gathers speed toward where the pedal asks at Accel of its top a second, brakes at Brake (the
-- pedal against the way it's going), and with no pedal rolls to a stop at Coast. Backing up is at
-- most Reverse of its top.
function Vehicles.step(speed: number, throttle: number, top: number, dt: number): number
	local want = if throttle >= 0 then throttle * top else throttle * top * K.Reverse
	local rate
	if throttle == 0 then
		rate = K.Coast
	elseif (throttle > 0 and speed < 0) or (throttle < 0 and speed > 0) then
		rate = K.Brake
	else
		rate = K.Accel
	end
	local d = rate * top * dt
	if speed < want then
		return math.min(want, speed + d)
	end
	return math.max(want, speed - d)
end

-- How fast it turns, in degrees a second with the wheel hard over, at that speed: nothing when
-- standing, Turn soon after it moves, easing to TurnFast flat out. Turning backwards turns the
-- other way, as a car does.
function Vehicles.turnRate(speed: number, top: number): number
	local s = math.abs(speed)
	if s < 0.5 then
		return 0
	end
	local t = math.clamp(s / math.max(top, 1), 0, 1)
	local rate = K.Turn + (K.TurnFast - K.Turn) * t
	return if speed < 0 then -rate else rate
end

return Vehicles
