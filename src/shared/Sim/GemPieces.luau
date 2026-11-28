--!strict
-- Build mode pieces bought with gems (the user: "also, add a fog machine that players can place
-- with gems"). A piece with `gems = n` in the catalog costs no coins: the first time one goes down
-- the server takes n gems and the player owns it, and the save counts how many of each they own
-- (profile.gemItems = { [itemId] = count }), as keepsakes are counted. So one put away, sold or
-- undone is still theirs and goes down again for nothing; another one alongside it is bought
-- again. A saved build loaded onto the plot only brings back as many as are owned (nothing is
-- bought on a load). The Build service asks GemPieces.need before a change and GemPieces.buy after
-- it; nothing here trusts the client. No services, so the specs run it.

local Catalog = require(script.Parent.Parent.Build.Catalog)
local Tuning = require(script.Parent.Parent.Config.Tuning)

local GemPieces = {}

-- The gems a piece costs, or nil for one bought with coins.
function GemPieces.price(id: any): number?
	if type(id) ~= "string" then
		return nil
	end
	local def = Catalog.get(id)
	local g = def and (def :: any).gems
	return if type(g) == "number" and g > 0 then math.floor(g) else nil
end

local function count(owned: any, id: string): number
	local n = if type(owned) == "table" then owned[id] else nil
	if type(n) ~= "number" or n ~= n or n < 1 then
		return 0
	end
	return math.min(math.floor(n), Tuning.GemPieces.MaxOwned)
end

-- How many of one a save says the player owns.
function GemPieces.owned(profile: any, id: string): number
	return count(profile and profile.gemItems, id)
end

-- How many of one are down in a plan.
function GemPieces.placed(plan: any, id: string): number
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

-- How many more of one could go down without buying another.
function GemPieces.left(profile: any, id: string): number
	return math.max(0, GemPieces.owned(profile, id) - GemPieces.placed(profile and profile.plan, id))
end

-- What a Build mode change asks of the player's gems before it is applied: the gems it costs and
-- how many of each piece that is (the ones that go down past what they own). Removals in the same
-- change make room first. Nil and why when the change would take them past what can be owned.
function GemPieces.need(profile: any, requests: any): (number?, { [string]: number }, string?)
	local buys: { [string]: number } = {}
	if type(requests) ~= "table" then
		return 0, buys
	end
	local plan = profile and profile.plan
	local delta: { [string]: number } = {}
	for _, req in requests do
		if type(req) == "table" and req.kind == "items" then
			if req.type == "add" and type(req.obj) == "table" and GemPieces.price(req.obj.id) then
				delta[req.obj.id] = (delta[req.obj.id] or 0) + 1
			elseif
				req.type == "remove"
				and type(req.key) == "string"
				and type(plan) == "table"
				and type(plan.items) == "table"
			then
				local item = plan.items[req.key]
				if type(item) == "table" and GemPieces.price(item.id) then
					delta[item.id] = (delta[item.id] or 0) - 1
				end
			end
		end
	end
	local total = 0
	for id, d in delta do
		local short = GemPieces.placed(plan, id) + d - GemPieces.owned(profile, id)
		if short > 0 then
			if GemPieces.owned(profile, id) + short > Tuning.GemPieces.MaxOwned then
				return nil, {}, "You have as many of those as you can keep."
			end
			buys[id] = short
			total += short * (GemPieces.price(id) :: number)
		end
	end
	return total, buys
end

-- The player owns these now (the gems were taken).
function GemPieces.buy(profile: any, buys: { [string]: number })
	if type(profile.gemItems) ~= "table" then
		profile.gemItems = {}
	end
	for id, n in buys do
		if GemPieces.price(id) and n > 0 then
			profile.gemItems[id] = math.min(count(profile.gemItems, id) + math.floor(n), Tuning.GemPieces.MaxOwned)
		end
	end
end

-- A saved build's load, checked: no more of a gem piece down than are owned (none are bought on a
-- load). True when the change fits.
function GemPieces.fits(profile: any, plan: any, requests: any): boolean
	local view = { gemItems = profile and profile.gemItems, plan = plan }
	local gems = GemPieces.need(view, requests)
	return gems == 0
end

-- What a save holds, cleaned: known gem pieces with whole counts (Sim/Schema).
function GemPieces.clean(raw: any): { [string]: number }
	local out: { [string]: number } = {}
	if type(raw) ~= "table" then
		return out
	end
	for id, _ in raw do
		if GemPieces.price(id) then
			local c = count(raw, id)
			if c > 0 then
				out[id] = c
			end
		end
	end
	return out
end

return GemPieces
