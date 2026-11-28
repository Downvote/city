--!strict
-- The player's bag: the things they carry (Data/Items). The user: "make it such that you can pick
-- up items, and interactable items give you things ... add an inventory system to the player."
-- Pure data in and out, so the specs can run it. The save keeps
--   profile.bag     { [itemId] = count }: at most Tuning.Bag.Stack of one thing and
--                   Tuning.Bag.Total things in all
--   profile.owed    { [itemId] = count }: what a town goal gave while the bag was full, put in as
--                   room comes (Bag.settle)
--   profile.gather  { day, n }: how many things the player took from pieces (or made at work) on
--                   that town day, held to Tuning.Bag.Gathers
-- Services/Bag gives things from pieces and work (Bag.gather), holds and drops them; Services/Gifts
-- takes one to give a villager (Bag.take). (An old save's `inv`, the bag of food from when there was
-- a shop, is dropped by Sim/Schema and has nothing to do with this one.)

local Tuning = require(script.Parent.Parent.Config.Tuning)
local Items = require(script.Parent.Parent.Data.Items)

local K = Tuning.Bag

local Bag = {}

local function whole(n: any): number
	if type(n) ~= "number" or n ~= n or n < 1 then
		return 0
	end
	return math.floor(math.min(n, 1e6))
end

local function bagOf(profile: any): { [string]: number }
	if type(profile.bag) ~= "table" then
		profile.bag = {}
	end
	return profile.bag
end

function Bag.count(profile: any, id: string): number
	local bag = profile and profile.bag
	return if type(bag) == "table" then whole(bag[id]) else 0
end

function Bag.total(profile: any): number
	local n = 0
	local bag = profile and profile.bag
	if type(bag) == "table" then
		for _, c in bag do
			n += whole(c)
		end
	end
	return n
end

-- How many more of a thing fit: the room in its stack and in the bag.
function Bag.room(profile: any, id: string): number
	if not Items.get(id) then
		return 0
	end
	return math.max(0, math.min(K.Stack - Bag.count(profile, id), K.Total - Bag.total(profile)))
end

-- Puts up to `n` of a thing in the bag. Returns how many went in.
function Bag.add(profile: any, id: any, n: number?): number
	if not Items.get(id) then
		return 0
	end
	local want = whole(n or 1)
	local fits = math.min(want, Bag.room(profile, id))
	if fits <= 0 then
		return 0
	end
	local bag = bagOf(profile)
	bag[id] = Bag.count(profile, id) + fits
	return fits
end

-- Takes `n` of a thing out. False (and nothing taken) when there aren't that many.
function Bag.take(profile: any, id: any, n: number?): boolean
	local want = whole(n or 1)
	if type(id) ~= "string" or want <= 0 or Bag.count(profile, id) < want then
		return false
	end
	local bag = bagOf(profile)
	local left = Bag.count(profile, id) - want
	if left > 0 then
		bag[id] = left
	else
		bag[id] = nil
	end
	return true
end

-- A thing a town goal gave that didn't fit: kept until there is room.
function Bag.owe(profile: any, id: string)
	if not Items.get(id) then
		return
	end
	if type(profile.owed) ~= "table" then
		profile.owed = {}
	end
	profile.owed[id] = whole(profile.owed[id]) + 1
end

-- Puts in what is owed, as much as fits. Returns the ids that went in (one per thing).
function Bag.settle(profile: any): { string }
	local out = {}
	local owed = profile.owed
	if type(owed) ~= "table" then
		return out
	end
	local ids = {}
	for id in owed do
		table.insert(ids, id)
	end
	table.sort(ids)
	for _, id in ids do
		local n = whole(owed[id])
		local put = Bag.add(profile, id, n)
		for _ = 1, put do
			table.insert(out, id)
		end
		owed[id] = if n - put > 0 then n - put else nil
	end
	return out
end

-- What is in the bag, by category and then in Data/Items' order: { item, n }.
local catOrder: { [string]: number } = {}
for i, c in Items.Categories do
	catOrder[c.id] = i
end
local itemOrder: { [string]: number } = {}
for i, item in Items.list do
	itemOrder[item.id] = i
end

export type Entry = { item: Items.Item, n: number }

function Bag.entries(profile: any): { Entry }
	local out: { Entry } = {}
	local bag = profile and profile.bag
	if type(bag) ~= "table" then
		return out
	end
	for id, n in bag do
		local item = Items.get(id)
		local c = whole(n)
		if item and c > 0 then
			table.insert(out, { item = item, n = c })
		end
	end
	table.sort(out, function(a, b)
		local ca, cb = catOrder[a.item.cat] or 99, catOrder[b.item.cat] or 99
		if ca ~= cb then
			return ca < cb
		end
		return (itemOrder[a.item.id] or 0) < (itemOrder[b.item.id] or 0)
	end)
	return out
end

-- Gathering ----------------------------------------------------------------------------------------

-- How many things the player has taken from pieces (or made at work) on town day `day`.
function Bag.gathered(profile: any, day: number): number
	local g = profile and profile.gather
	if type(g) == "table" and g.day == day then
		return whole(g.n)
	end
	return 0
end

-- Can they take something from a piece today? Ok, or false and why in plain words.
function Bag.canGather(profile: any, day: number): (boolean, string?)
	if Bag.gathered(profile, day) >= K.Gathers then
		return false, "That's all you can gather today."
	end
	if Bag.total(profile) >= K.Total then
		return false, "Your bag is full."
	end
	return true, nil
end

-- Takes one thing from a source (Data/Items.Sources) into the bag, counted against today's cap.
-- Picks again among the source's things when the first pick's stack is full. Returns ok and the
-- thing's id, or false and why.
function Bag.gather(profile: any, day: number, key: any, rng: any): (boolean, string?)
	local source = Items.source(key)
	if not source then
		return false, nil
	end
	local ok, why = Bag.canGather(profile, day)
	if not ok then
		return false, why
	end
	local id = Items.pick(source, rng, K.RareChance)
	if Bag.room(profile, id) <= 0 then
		id = nil :: any
		for _, other in source.things do
			if Bag.room(profile, other) > 0 then
				id = other
				break
			end
		end
	end
	if not id or Bag.add(profile, id, 1) <= 0 then
		return false, "You have as many of those as you can carry."
	end
	profile.gather = { day = day, n = Bag.gathered(profile, day) + 1 }
	-- counted for the town goals (Data/Goals: gathering, cooking)
	if type(profile.stats) == "table" then
		profile.stats.gathered = (profile.stats.gathered or 0) + 1
		if source.cook then
			profile.stats.cooked = (profile.stats.cooked or 0) + 1
		end
	end
	return true, id
end

-- What a save holds, cleaned: known things in whole counts, held to the stack and the total (the
-- first in list order kept), what is owed likewise, and today's count.
function Bag.clean(profile: any)
	local raw = profile.bag
	profile.bag = {}
	if type(raw) == "table" then
		for _, item in Items.list do
			local n = whole(raw[item.id])
			if n > 0 then
				Bag.add(profile, item.id, n)
			end
		end
	end
	local owed = profile.owed
	profile.owed = {}
	if type(owed) == "table" then
		for _, item in Items.list do
			local n = math.min(whole(owed[item.id]), K.Stack)
			if n > 0 then
				profile.owed[item.id] = n
			end
		end
	end
	local g = profile.gather
	if type(g) ~= "table" or type(g.day) ~= "number" or g.day ~= g.day then
		profile.gather = { day = -1, n = 0 }
	else
		profile.gather = { day = g.day, n = whole(g.n) }
	end
end

return Bag
