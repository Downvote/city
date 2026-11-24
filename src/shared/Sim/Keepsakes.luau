--!strict
-- Keepsakes: things a villager made and gave you in an event (a portrait, a pot, a carved bird,
-- a quilt...). Each is a Build mode piece from Build/Recipes/Keepsakes (the "keepsakes"
-- category, price 0), so it costs nothing to put down, and the save counts how many of each you
-- were given: profile.keepsakes = { [itemId] = count }. You can have as many of one out as you
-- were given; put one away or sell it and it can go down again. Pure data in and out: the events
-- give them (Sim/EventEngine's "keepsake" effect), the Build service checks every placing with
-- Keepsakes.check, and Build mode's Keepsakes tab lists them with Keepsakes.list.

local Catalog = require(script.Parent.Parent.Build.Catalog)
local Tuning = require(script.Parent.Parent.Config.Tuning)

local Keepsakes = {}

Keepsakes.Category = "keepsakes"

function Keepsakes.isKeepsake(id: any): boolean
	if type(id) ~= "string" then
		return false
	end
	local def = Catalog.get(id)
	return def ~= nil and def.cat == Keepsakes.Category
end

-- How many of one a save says you were given (anything odd reads as none).
local function count(owned: any, id: string): number
	local n = if type(owned) == "table" then owned[id] else nil
	if type(n) ~= "number" or n ~= n or n < 1 then
		return 0
	end
	return math.min(math.floor(n), Tuning.Events.KeepsakeMax)
end

function Keepsakes.owned(profile: any, id: string): number
	return count(profile and profile.keepsakes, id)
end

-- How many of one are down in a plan.
function Keepsakes.placed(plan: any, id: string): number
	local n = 0
	if type(plan) == "table" and type(plan.items) == "table" then
		for _, item in plan.items do
			if type(item) == "table" and item.id == id then
				n += 1
			end
		end
	end
	return n
end

function Keepsakes.left(owned: any, plan: any, id: string): number
	return math.max(0, count(owned, id) - Keepsakes.placed(plan, id))
end

-- One more of a keepsake for the player. False for anything that isn't one, or one they have
-- as many of as they can keep.
function Keepsakes.give(profile: any, id: string): boolean
	if not Keepsakes.isKeepsake(id) then
		return false
	end
	if type(profile.keepsakes) ~= "table" then
		profile.keepsakes = {}
	end
	local n = count(profile.keepsakes, id)
	if n >= Tuning.Events.KeepsakeMax then
		return false
	end
	profile.keepsakes[id] = n + 1
	return true
end

export type Entry = { def: Catalog.Def, owned: number, left: number }

-- The keepsakes a player has, in catalog order, with how many more of each can go down.
function Keepsakes.list(owned: any, plan: any): { Entry }
	local out: { Entry } = {}
	for _, def in Catalog.list(Keepsakes.Category) do
		local n = count(owned, def.id)
		if n > 0 then
			table.insert(out, { def = def, owned = n, left = math.max(0, n - Keepsakes.placed(plan, def.id)) })
		end
	end
	return out
end

-- A Build mode change, checked before it is applied: no more of a keepsake may be down than the
-- player was given. Removals in the same change make room first.
function Keepsakes.check(profile: any, requests: any): (boolean, string?)
	if type(requests) ~= "table" then
		return true
	end
	local plan = profile and profile.plan
	local delta: { [string]: number } = {}
	for _, req in requests do
		if type(req) == "table" and req.kind == "items" then
			if req.type == "add" and type(req.obj) == "table" and Keepsakes.isKeepsake(req.obj.id) then
				delta[req.obj.id] = (delta[req.obj.id] or 0) + 1
			elseif
				req.type == "remove"
				and type(req.key) == "string"
				and type(plan) == "table"
				and type(plan.items) == "table"
			then
				local item = plan.items[req.key]
				if type(item) == "table" and Keepsakes.isKeepsake(item.id) then
					delta[item.id] = (delta[item.id] or 0) - 1
				end
			end
		end
	end
	for id, d in delta do
		if d > 0 and Keepsakes.placed(plan, id) + d > Keepsakes.owned(profile, id) then
			if Keepsakes.owned(profile, id) == 0 then
				return false, "Nobody has given you that yet."
			end
			return false, "You've put down every one you were given."
		end
	end
	return true
end

-- What a save holds, cleaned: known keepsakes with whole counts (Sim/Schema).
function Keepsakes.clean(raw: any): { [string]: number }
	local out: { [string]: number } = {}
	if type(raw) ~= "table" then
		return out
	end
	for id, n in raw do
		if Keepsakes.isKeepsake(id) then
			local c = count(raw, id)
			if c > 0 then
				out[id] = c
			end
		end
	end
	return out
end

return Keepsakes
