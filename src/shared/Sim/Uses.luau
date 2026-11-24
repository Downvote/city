--!strict
-- Using things: which piece a villager goes and uses, and how a go turns out. The user: "just like
-- tomodachi life, make it such that some obejcts have a random chance of having unique
-- interactions with it". What there is to use and what can happen is Data/Interactions; this only
-- chooses, from a seeded rng, and touches nothing in the world. Services/Villagers asks it on a
-- break or while pottering (Routine's "use"), Services/Interact when a player holds E on a piece.
--   Uses.around    the pieces on a plan within reach of a villager that they could use now
--   Uses.choose    one of those, by what their personality likes and how near it is, and seldom
--                  the one they used last
--   Uses.outcome   how this go turns out: mostly the usual way, now and then not, once in a long
--                  while something rare. Weighted by Data/Interactions, coloured by personality,
--                  and never the same unusual outcome twice running for one villager or player.
-- tests/specs/Uses.spec.luau holds the data and the chances to what they say.

local Tuning = require(script.Parent.Parent.Config.Tuning)
local Personalities = require(script.Parent.Parent.Data.Personalities)
local Interactions = require(script.Parent.Parent.Data.Interactions)
local Catalog = require(script.Parent.Parent.Build.Catalog)
local Plan = require(script.Parent.Parent.Build.Plan)
local Text = require(script.Parent.Parent.Util.Text)
local Rng = require(script.Parent.Parent.Util.Rng)

local K = Tuning.Uses

export type Use = Interactions.Use
export type Outcome = Interactions.Outcome
export type Spot = Interactions.Spot

-- A piece someone could go and use: its key on the plan, its frame in plot space, where to stand.
export type Candidate = {
	key: string,
	id: string,
	use: Use,
	frame: CFrame,
	spots: { Spot },
	dist: number,
}

-- What decides which outcomes can happen this time.
export type Opts = {
	pair: boolean?, -- two are at it together
	hour: number?, -- the town's clock
	needs: { [string]: boolean }?, -- what the town has that an outcome may need ("villager")
}

local Uses = {}

local byItem: { [string]: Use } = {}
for _, use in Interactions.uses do
	for id in use.items do
		byItem[id] = use
	end
end

-- The use of a catalog piece, if it has one.
function Uses.of(id: string): Use?
	return byItem[id]
end

local spotCache: { [string]: { Spot } } = {}

-- Where a villager stands to use a piece, in the piece's own space (with "sit", where they walk
-- up to before sitting down). None when only a player can use it.
function Uses.spots(id: string): { Spot }
	local cached = spotCache[id]
	if cached then
		return cached
	end
	local use = byItem[id]
	local def = Catalog.get(id)
	local place: any = use and use.items[id]
	local out: { Spot } = {}
	if use and def and place ~= false and place ~= nil then
		if place == true or place.spots == nil then
			-- in front of it, facing its middle
			local front = def.size.Z / 2 + (use.front or K.Front)
			out = { { at = Vector3.new(0, 0, front), look = Vector3.new(0, math.min(def.size.Y * 0.6, 3.5), 0) } }
		else
			out = place.spots
		end
	end
	spotCache[id] = out
	return out
end

-- Where a trace a go leaves lands, in the piece's own space: on the floor in front of it, to one
-- side of where its user stands, unless the piece says.
function Uses.drop(id: string): Vector3
	local use = byItem[id]
	local def = Catalog.get(id)
	local place: any = use and use.items[id]
	if type(place) == "table" and place.drop then
		return place.drop
	end
	local depth = if def then def.size.Z / 2 else 1
	return Vector3.new(0.8, 0, depth + 0.55)
end

-- Where a player's prompt hangs on a piece, in its own space: the middle of its front.
function Uses.promptAt(id: string): Vector3
	local use = byItem[id]
	local def = Catalog.get(id)
	if use and use.player and use.player.at then
		return use.player.at
	end
	local size = if def then def.size else Vector3.one
	return Vector3.new(0, math.min(size.Y * 0.65, 4), size.Z / 2)
end

-- The pieces on `plan` a villager at `from` (plot space) could go and use: within `reach` of
-- them, not `taken` (keyed by item key), and with somewhere for a villager to stand.
function Uses.around(plan: any, from: Vector3, reach: number, taken: { [string]: any }?): { Candidate }
	local keys = {}
	for key in plan.items do
		table.insert(keys, key)
	end
	table.sort(keys, function(a, b)
		return (tonumber(a) or 0) < (tonumber(b) or 0)
	end)
	local out: { Candidate } = {}
	for _, key in keys do
		local item = plan.items[key]
		local use = byItem[item.id]
		local spots = if use then Uses.spots(item.id) else {}
		if use and #spots > 0 and not (taken and taken[key]) then
			local frame = Plan.itemFrame(plan, item)
			if frame then
				local dist = (frame.Position - from).Magnitude
				if dist <= reach then
					table.insert(out, { key = key, id = item.id, use = use, frame = frame, spots = spots, dist = dist })
				end
			end
		end
	end
	return out
end

-- How much somebody of this personality wants a go at it.
function Uses.want(use: Use, pers: string): number
	return math.max(0, use.base + use.per * Personalities.trait(pers, use.trait))
end

-- Which of `list` they go and use: by what they like and how near it is, and the piece they used
-- last (`last`, its key) is less likely.
function Uses.choose(list: { Candidate }, pers: string, last: string?, rng: Rng.Rng): Candidate?
	return rng:weighted(list, function(c: Candidate): number
		local w = Uses.want(c.use, pers) * K.Near / (K.Near + c.dist)
		return if c.key == last then w * K.Repeat else w
	end)
end

-- Can this outcome happen now?
local function open(o: Outcome, opts: Opts?): boolean
	local pair = opts ~= nil and opts.pair == true
	if o.pair ~= nil and o.pair ~= pair then
		return false
	end
	if o.late and (opts == nil or opts.hour == nil or opts.hour < K.LateHour) then
		return false
	end
	if o.needs and not (opts and opts.needs and opts.needs[o.needs]) then
		return false
	end
	return true
end

-- How much likelier who they are makes an outcome (1 for a player, or an outcome with no trait).
function Uses.factor(o: Outcome, pers: string?): number
	if not pers or not o.trait then
		return 1
	end
	return math.max(0, 1 + (o.per or 0) * (Personalities.trait(pers, o.trait) - 0.5))
end

-- The chance of each of `list` this go, in order: its weight, coloured by personality, among
-- those that can happen now, and none for the unusual one that came up last time (`last`).
function Uses.chances(list: { Outcome }, pers: string?, last: Outcome?, opts: Opts?): { number }
	local out = table.create(#list, 0)
	local total = 0
	for i, o in list do
		local w = 0
		if open(o, opts) and not (o == last and o.rarity ~= "usual") then
			w = math.max(0, o.weight) * Uses.factor(o, pers)
		end
		out[i] = w
		total += w
	end
	if total > 0 then
		for i in out do
			out[i] /= total
		end
	end
	return out
end

-- How this go turns out. Nil only for a list with nothing in it.
function Uses.outcome(list: { Outcome }, pers: string?, last: Outcome?, rng: Rng.Rng, opts: Opts?): Outcome?
	local chances = Uses.chances(list, pers, last, opts)
	local index = 0
	local roll = rng:float()
	for i, p in chances do
		if p > 0 then
			index = i
			roll -= p
			if roll <= 0 then
				break
			end
		end
	end
	return list[index]
end

-- A line, filled: {name} who used it, {other} who was with them, {piece} the piece, {who} one of
-- the town's villagers.
function Uses.fill(text: string, vars: { [string]: any }): string
	return Text.fill(text, vars)
end

-- What is said when it turns out this way (one of its lines), or nil when it says nothing.
function Uses.say(o: Outcome, vars: { [string]: any }, rng: Rng.Rng): string?
	if not o.say or #o.say == 0 then
		return nil
	end
	return Text.fill(rng:pick(o.say), vars)
end

return Uses
