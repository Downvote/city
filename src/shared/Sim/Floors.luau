--!strict
-- Which floors a player may build on. The user: "another [gamepass] for basement, another for more
-- levels". A plan holds the basement (-1) up to floor 7 (Plan.Lowest, Plan.Highest); a player builds
-- on floors 0 to 2 (the first three), up to 7 with Tall Builds, and on -1 with Basement
-- (Sim/Passes.levels, lowestLevel). Everyone had four floors before the passes: what an old save
-- has up there stays and keeps working (villagers sleep and work there), can be repainted, moved
-- about on its floor or down to one the player may build on, and sold, but nothing new goes up
-- there. The server checks every request here (Services/Build) and Build mode asks the same before
-- it sends one and to know which floors its buttons may go to. No services, so the specs run it.

local Tuning = require(script.Parent.Parent.Config.Tuning)
local Plan = require(script.Parent.Parent.Build.Plan)
local Catalog = require(script.Parent.Parent.Build.Catalog)
local Passes = require(script.Parent.Passes)

local Floors = {}

-- The lowest and highest floors this player may build on.
function Floors.range(profile: any): (number, number)
	return Passes.lowestLevel(profile), Passes.levels(profile) - 1
end

-- May this player build on floor lv?
function Floors.allowed(profile: any, lv: number): boolean
	local lo, hi = Floors.range(profile)
	return lv >= lo and lv <= hi
end

-- The lowest and highest floors the plan has anything on (0, 0 for an empty one).
function Floors.used(plan: any): (number, number)
	local lo, hi = 0, 0
	for _, kind in Plan.Kinds do
		for _, obj in (plan and (plan :: any)[kind]) or {} do
			local lv = type(obj) == "table" and obj.lv
			if type(lv) == "number" and lv % 1 == 0 and lv >= Plan.Lowest and lv <= Plan.Highest then
				lo, hi = math.min(lo, lv), math.max(hi, lv)
			end
		end
	end
	return lo, hi
end

-- The floors Build mode can show: the ones the player may build on, and any other the plan already
-- has something on (to sell it or move it down).
function Floors.shown(profile: any, plan: any): (number, number)
	local lo, hi = Floors.range(profile)
	local ulo, uhi = Floors.used(plan)
	return math.min(lo, ulo), math.max(hi, uhi)
end

-- The pass that would let this player build on floor lv, if one would: "floors" above, "basement"
-- below. nil when they may already, or when no pass reaches it.
function Floors.passFor(profile: any, lv: number): string?
	if Floors.allowed(profile, lv) then
		return nil
	end
	if lv < 0 and lv >= Plan.Lowest and not Passes.has(profile, "basement") then
		return "basement"
	elseif lv > 0 and lv < Tuning.Passes.TallLevels and not Passes.has(profile, "floors") then
		return "floors"
	end
	return nil
end

Floors.Why = {
	floors = "building past the third floor needs Tall Builds",
	basement = "digging a basement needs the Basement pass",
	none = "you can't build on that floor",
}

local function refuse(profile: any, lv: number): (boolean, string?)
	local pass = Floors.passFor(profile, lv)
	return false, if pass then Floors.Why[pass] else Floors.Why.none
end

-- Does a piece on floor lv reach a floor the player may not build on? Stairs climb to the floor over
-- theirs, so stairs on the top floor they may build on would lead up into one they may not.
local function reaches(obj: any, kind: string, lv: number): number
	if kind == "items" and type(obj.id) == "string" then
		local def = Catalog.get(obj.id)
		if def and def.place == "stairs" then
			-- (a lift runs up as many floors as it spans: Build/Recipes/Travel)
			return lv + math.max(1, def.spans or 1)
		end
	end
	return lv
end

-- Checks a list of Build requests (Services/Build's: add, remove, set) against the floors this
-- player may build on. Taking something away is always allowed; a change that leaves a piece on
-- the floor it was on is too (a repaint, a move along its floor); anything else has to land on a
-- floor they may build on.
function Floors.check(profile: any, plan: any, requests: { any }): (boolean, string?)
	if type(requests) ~= "table" then
		return true
	end
	for _, req in requests do
		if type(req) == "table" and (req.type == "add" or req.type == "set") and type(req.obj) == "table" then
			local obj = req.obj
			local lv = obj.lv
			if type(lv) == "number" and lv == lv then
				local before = nil
				if req.type == "set" and type(req.kind) == "string" and type(req.key) == "string" then
					local list = plan and (plan :: any)[req.kind]
					before = type(list) == "table" and list[req.key] or nil
				end
				local stays = type(before) == "table" and before.lv == lv
				if not stays then
					if not Floors.allowed(profile, lv) then
						return refuse(profile, lv)
					end
					local top = reaches(obj, req.kind, lv)
					if top ~= lv and top >= 0 and not Floors.allowed(profile, top) then
						return refuse(profile, top)
					end
				end
			end
		end
	end
	return true
end

return Floors
