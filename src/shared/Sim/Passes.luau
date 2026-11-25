--!strict
-- What a player's game passes let them do (Data/Passes lists them). The server learns which passes
-- a player owns from Roblox when they join and when they buy one (Services/Store), and keeps it in
-- profile.passes = { [key] = true } for the session (Roblox is asked again each time: a refund
-- takes a pass away). Everything else asks here, the server and the client alike, so the rules for
-- what a pass changes live in one place. No services, so the specs run it.

local Tuning = require(script.Parent.Parent.Config.Tuning)
local Data = require(script.Parent.Parent.Data.Passes)

local Passes = {}

function Passes.has(profile: any, key: string): boolean
	local owned = type(profile) == "table" and profile.passes
	return type(owned) == "table" and owned[key] == true
end

-- Furniture's grid step: Tuning.Plot.ItemSnap, a quarter of it with Fine Grid.
function Passes.itemSnap(profile: any): number
	return if Passes.has(profile, "finegrid") then Tuning.Plot.ItemSnap / 4 else Tuning.Plot.ItemSnap
end

-- How many floors above the ground a player may build (the ground floor is 0).
function Passes.levels(profile: any): number
	return if Passes.has(profile, "floors") then Tuning.Passes.TallLevels else Tuning.Passes.FreeLevels
end

-- The lowest floor a player may build on: -1 with a basement, else 0.
function Passes.lowestLevel(profile: any): number
	return if Passes.has(profile, "basement") then -1 else 0
end

-- The biggest land a player may buy (Tuning.City.Land's Size).
function Passes.maxLand(profile: any): number
	return if Passes.has(profile, "bigplot") then Tuning.Plot.Size else Tuning.Passes.FreeLand
end

-- Do pieces have to keep out of each other? (Free Placing lets them overlap.)
function Passes.collides(profile: any): boolean
	return not Passes.has(profile, "freeplace")
end

-- How many builds a player can keep saved.
function Passes.saveSlots(profile: any): number
	return if Passes.has(profile, "saveslots") then Tuning.Passes.MoreSlots else Tuning.Passes.FreeSlots
end

-- What a villager's pay is multiplied by: Double Pay, VIP and the group's bonus together (the
-- group bonus comes from Services/Store, which checks membership, as `inGroup`).
function Passes.payBoost(profile: any, inGroup: boolean?): number
	local m = 1
	if Passes.has(profile, "doublepay") then
		m *= 2
	end
	if Passes.has(profile, "vip") then
		m *= 1 + Tuning.Passes.VipPay
	end
	if inGroup then
		m *= 1 + Tuning.Group.PayBonus
	end
	return m
end

-- May this player put down a piece of this kind? VIP pieces (Catalog: `vip`) are for VIP owners
-- (Services/Build refuses them to anyone else; Build mode offers the pass on their cards).
function Passes.mayPlace(profile: any, def: any): boolean
	if type(def) == "table" and def.vip == true then
		return Passes.has(profile, "vip")
	end
	return true
end

-- Every pass's key (for the specs and the store).
function Passes.keys(): { string }
	local out = {}
	for _, p in Data.list do
		table.insert(out, p.key)
	end
	return out
end

return Passes
