--!strict
-- Saved builds (the user: "add loading and saving of plots"). A player keeps their whole plot as a
-- build in a slot and can load it back later, save over it, rename it or delete it.
--
--   profile.saves = { ["1"] = { name, t, plan }, ["2"] = ..., } one to a slot, up to
--   Sim/Passes.saveSlots(profile) slots (two, or eight with More Saves)
--
-- A save is the plan as it stood, `gift` and all: it is written by the server from the player's
-- own plan and never comes from the client, so what of the starting house was given stays given
-- when it is loaded back. Loading replaces the plot (Services/Build: Build.replace): what is the
-- same in both stays where it is, the rest of the plot goes and the rest of the save comes, all
-- checked piece by piece as any change is, charged the difference and taken back by one Undo.
-- The rules here have no services, so the specs run them; Services/Saves answers the client.

local Tuning = require(script.Parent.Parent.Config.Tuning)
local Plan = require(script.Parent.Parent.Build.Plan)
local Water = require(script.Parent.Parent.Build.Water)
local Passes = require(script.Parent.Passes)

local Saves = {}

export type Entry = { name: string, t: number, plan: any }
export type Summary = { slot: number, name: string, t: number, pieces: number }

-- Slots are stored under their number as a string: a list with a gap in it doesn't keep in a
-- DataStore.
local function slotKey(i: number): string
	return tostring(i)
end

-- The most slots anyone has (with More Saves), and how many this player has.
function Saves.maxSlots(): number
	return Tuning.Passes.MoreSlots
end

function Saves.slots(profile: any): number
	return Passes.saveSlots(profile)
end

-- Is this a slot number at all (whether or not the player has it)?
function Saves.validSlot(i: any): boolean
	return type(i) == "number" and i % 1 == 0 and i >= 1 and i <= Saves.maxSlots()
end

-- The save in a slot, or nil (anything that isn't one reads as an empty slot).
function Saves.get(profile: any, i: number): Entry?
	local saves = type(profile) == "table" and profile.saves
	local e = if type(saves) == "table" then saves[slotKey(i)] else nil
	if type(e) == "table" and type(e.name) == "string" and type(e.t) == "number" and type(e.plan) == "table" then
		return e :: any
	end
	return nil
end

function Saves.set(profile: any, i: number, entry: Entry?)
	if type(profile.saves) ~= "table" then
		profile.saves = {}
	end
	profile.saves[slotKey(i)] = entry
end

-- How many pieces a plan holds.
function Saves.pieces(plan: any): number
	local n = 0
	if type(plan) ~= "table" then
		return 0
	end
	for _, kind in Plan.Kinds do
		local list = plan[kind]
		if type(list) == "table" then
			for _ in list do
				n += 1
			end
		end
	end
	return n
end

-- About how many bytes a value takes written out as JSON, as the DataStore writes it (never less:
-- every string counts its quotes, a number as Luau prints it).
function Saves.bytes(v: any): number
	local t = type(v)
	if t == "string" then
		return #v + 2
	elseif t == "number" then
		return #tostring(v)
	elseif t == "boolean" then
		return if v then 4 else 5
	elseif t ~= "table" then
		return 4
	end
	local n = 2
	local count = 0
	for k, x in v do
		count += 1
		n += Saves.bytes(x) + 1
		if type(k) == "string" then
			n += #k + 3
		end
	end
	return n + math.max(0, count - 1)
end

-- A player's name for a save, tidied: no control characters, no spaces at the ends, at most
-- Tuning.Saves.NameLength long. Empty, it is "Build <slot>".
function Saves.cleanName(text: any, slot: number): string
	local s = if type(text) == "string" then text else ""
	s = string.gsub(s, "%c", "")
	s = string.gsub(s, "^%s+", "")
	s = string.gsub(s, "%s+$", "")
	if utf8.len(s) == nil then
		s = ""
	end
	if #s > Tuning.Saves.NameLength then
		-- cut on a whole character
		local cut = utf8.offset(s, Tuning.Saves.NameLength + 1)
		s = string.sub(s, 1, (cut or (Tuning.Saves.NameLength + 1)) - 1)
	end
	if s == "" then
		return "Build " .. slot
	end
	return s
end

-- What a slot keeps of a plan: a copy of it as it stands.
function Saves.snapshot(plan: any): any
	return Plan.copy(plan)
end

-- Can this plan be saved in slot `i` of the profile? Not when it is too big for one save, or would
-- take every save together past what a profile can hold.
function Saves.fits(profile: any, i: number, plan: any): (boolean, string?)
	local size = Saves.bytes(plan)
	if size > Tuning.Saves.MaxBytes then
		return false, "This build is too big to save. Sell a few things first."
	end
	local total = size
	for j = 1, Saves.maxSlots() do
		local e = if j ~= i then Saves.get(profile, j) else nil
		if e then
			total += Saves.bytes(e.plan)
		end
	end
	if total > Tuning.Saves.MaxTotal then
		return false, "Your saves are full of big builds. Delete one to make room."
	end
	return true
end

-- What the Saves page shows: how many slots the player has and, for each save, its name, when it
-- was saved and how many pieces it holds (never the plans themselves: they stay on the server).
function Saves.summary(profile: any): { slots: number, max: number, free: number, saves: { Summary } }
	local list: { Summary } = {}
	for i = 1, Saves.maxSlots() do
		local e = Saves.get(profile, i)
		if e then
			table.insert(list, { slot = i, name = e.name, t = e.t, pieces = Saves.pieces(e.plan) })
		end
	end
	return { slots = Saves.slots(profile), max = Saves.maxSlots(), free = Tuning.Passes.FreeSlots, saves = list }
end

-- The plan a save loads as, checked against today's rules for the plot it goes on: its land
-- (`size`, what the player has now), and every piece checked again (Plan.sanitize). Returns it and
-- how many pieces of the save were left out.
function Saves.target(saved: any, size: number): (any, number)
	local raw = Plan.copy(saved)
	if type(raw) ~= "table" then
		raw = {}
	end
	raw.size = size
	local plan = Plan.sanitize(raw)
	plan.size = size
	return plan, math.max(0, Saves.pieces(saved) - Saves.pieces(plan))
end

local function same(a: any, b: any): boolean
	if type(a) ~= type(b) then
		return false
	end
	if type(a) ~= "table" then
		return a == b
	end
	for k, v in a do
		if not same(v, b[k]) then
			return false
		end
	end
	for k in b do
		if a[k] == nil then
			return false
		end
	end
	return true
end

local function sortedKeys(list: any): { string }
	local out: { string } = {}
	if type(list) == "table" then
		for key in list do
			table.insert(out, key)
		end
	end
	table.sort(out, function(a, b)
		local na, nb = tonumber(a), tonumber(b)
		if na and nb and na ~= nb then
			return na < nb
		end
		return a < b
	end)
	return out
end

local function giftOf(obj: any): number
	local g = if type(obj) == "table" then obj.gift else nil
	return if type(g) == "number" and g == g and g > 0 and g < math.huge then g else 0
end

-- What loading `target` over `current` takes: the requests for the Build service and, by request,
-- the coins of each new piece that were given (its `gift`, kept as the save had it).
--   A piece the same in both, under the same key, stays: nothing is sold or bought for it, and a
--   villager's bed or job there stays theirs. What hangs on a wall stays only with its wall, and
--   what is in a pool only with its pool.
--   The rest of the plot goes, pieces first (so nothing is left hanging on a wall or standing in
--   water that went), then walls, water, floors and roofs.
--   The rest of the save comes, walls first (so doors and windows have them: "@n" names the
--   request that made the wall), then floors, roofs, water and the pieces.
function Saves.requests(current: any, target: any): ({ any }, { [number]: number })
	local kept: { [string]: { [string]: boolean } } = {}
	for _, kind in Plan.Kinds do
		kept[kind] = {}
		local mine, theirs = current[kind], target[kind]
		if type(mine) == "table" and type(theirs) == "table" then
			for key, obj in mine do
				if theirs[key] ~= nil and same(obj, theirs[key]) then
					kept[kind][key] = true
				end
			end
		end
	end
	for key, item in current.items do
		if kept.items[key] and type(item.wall) == "string" and not kept.walls[item.wall] then
			kept.items[key] = nil
		end
	end
	for key in current.waters or {} do
		if not kept.waters[key] then
			for _, itemKey in Water.piecesIn(current, key) do
				kept.items[itemKey] = nil
			end
		end
	end
	local requests: { any } = {}
	local gifts: { [number]: number } = {}
	for _, kind in { "items", "walls", "waters", "floors", "roofs" } do
		for _, key in sortedKeys(current[kind]) do
			if not kept[kind][key] then
				table.insert(requests, { type = "remove", kind = kind, key = key })
			end
		end
	end
	local wallAt: { [string]: number } = {}
	for _, kind in { "walls", "floors", "roofs", "waters", "items" } do
		for _, key in sortedKeys(target[kind]) do
			if not kept[kind][key] then
				local obj = Plan.copy(target[kind][key])
				local ok = true
				if kind == "items" and type(obj.wall) == "string" then
					if kept.walls[obj.wall] then
						ok = true -- (a wall that stays keeps its key)
					elseif wallAt[obj.wall] then
						obj.wall = "@" .. wallAt[obj.wall]
					else
						ok = false
					end
				end
				if ok then
					obj.gift = nil
					table.insert(requests, { type = "add", kind = kind, obj = obj })
					local g = giftOf(target[kind][key])
					if g > 0 then
						gifts[#requests] = g
					end
					if kind == "walls" then
						wallAt[key] = #requests
					end
				end
			end
		end
	end
	return requests, gifts
end

return Saves
