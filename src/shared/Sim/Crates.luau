--!strict
-- Crates, as rules (Data/Crates says what is in them). The user: "add work crates that can be bought
-- with gems or robux, which give exclusive work spaces which are unique to crates, giving a random
-- one with effectiveness scaling off rarity, some of the rarer jobs even giving gems ... Some work
-- crates are also given through achievements, goals, daily rewards", then "Add pet crates as well".
--
-- A crate is opened at once when it is bought with gems (Crates.buy); one bought with Robux or won
-- as a reward is held (profile.crates = { work = n, pet = n }) until the player opens it in the
-- Store (Crates.openHeld). Opening rolls a rarity by Tuning.Crates.Odds, then one thing of it:
--   a work crate's workplace is the player's to put down for nothing, as many as they were given
--     (profile.crateItems = { [catalogId] = count }), as keepsakes are: one put away or sold goes
--     down again, and Crates.check holds Build mode to the count (the Build service runs it);
--   a pet crate's pet joins their pets (profile.pets = { [petId] = { kind, name, coat, vid? } },
--     profile.nextPet), and a villager can be made its owner (Crates.assign).
-- Crate jobs pay gems for a day's work (Crates.dayGems), up to Tuning.Crates.GemDayCap a real day
-- (profile.crateGems = { day, n }). `profile.crateTold` is set once a villager has told the player
-- about the crates. Nothing here trusts the client; no services, so the specs run it.

local Tuning = require(script.Parent.Parent.Config.Tuning)
local Catalog = require(script.Parent.Parent.Build.Catalog)
local CrateData = require(script.Parent.Parent.Data.Crates)
local Pets = require(script.Parent.Parent.Data.Pets)
local Jobs = require(script.Parent.Parent.Data.Jobs)
local Gems = require(script.Parent.Gems)

local K = Tuning.Crates

local Crates = {}

local function whole(n: any, most: number): number
	if type(n) ~= "number" or n ~= n or n < 1 then
		return 0
	end
	return math.min(math.floor(n), most)
end

-- Held crates ------------------------------------------------------------------------------------

function Crates.held(profile: any, kind: string): number
	local c = profile and profile.crates
	return whole(if type(c) == "table" then c[kind] else nil, K.Held)
end

-- Gives the player `n` crates of a kind to open later (a reward, a Robux purchase). Returns how
-- many they hold now, or nil for a kind there isn't.
function Crates.give(profile: any, kind: any, n: number?): number?
	if not CrateData.get(kind) then
		return nil
	end
	if type(profile.crates) ~= "table" then
		profile.crates = {}
	end
	local now = math.min(Crates.held(profile, kind) + math.max(1, math.floor(n or 1)), K.Held)
	profile.crates[kind] = now
	return now
end

function Crates.price(kind: string): number?
	return if CrateData.get(kind) then K.Price[kind] else nil
end

-- What is in a crate a player could open now: the rarities and their entries, less what they can
-- keep no more of (a workplace they have MaxOwned of). A pet crate always has its pets, unless the
-- player keeps as many pets as they can.
local function openable(profile: any, kind: string): { CrateData.Odds }
	local out = {}
	for _, o in CrateData.odds(kind) do
		local entries = {}
		for _, e in o.entries do
			if kind ~= "work" or Crates.owned(profile, e.id) < K.MaxOwned then
				table.insert(entries, e)
			end
		end
		if #entries > 0 then
			table.insert(out, { rarity = o.rarity, chance = o.chance, entries = entries })
		end
	end
	return out
end

-- Why a crate of this kind can't be opened for the player now, or nil when it can.
function Crates.blocked(profile: any, kind: string): string?
	if not CrateData.get(kind) then
		return "There's no crate like that."
	end
	if kind == "pet" and Crates.petCount(profile) >= Tuning.Pets.Max then
		return "You have as many pets as you can keep."
	end
	if #openable(profile, kind) == 0 then
		return "You have all you can keep from these."
	end
	return nil
end

-- Rolls what a crate gives: a rarity by its odds, then one of it. `rng` is Util/Rng's. Nil when
-- nothing is left to give.
function Crates.roll(profile: any, kind: string, rng: any): CrateData.Entry?
	local odds = openable(profile, kind)
	local total = 0
	for _, o in odds do
		total += o.chance
	end
	if total <= 0 then
		return nil
	end
	local x = rng:float(0, total)
	for _, o in odds do
		x -= o.chance
		if x < 0 then
			return rng:pick(o.entries)
		end
	end
	local last = odds[#odds]
	return rng:pick(last.entries)
end

export type Result = {
	kind: string,
	id: string, -- the catalog id of the workplace, or the pet's kind
	name: string,
	rarity: string,
	pet: string?, -- the new pet's id in profile.pets
	petName: string?,
	coat: number?,
}

-- A new pet of kind `p` joins the player's pets, with a name nobody else in town has (if one is
-- left) and a coat at random. Returns its id, name and coat.
local function addPet(profile: any, p: Pets.Pet, rng: any): (string, string, number)
	if type(profile.pets) ~= "table" then
		profile.pets = {}
	end
	local n = if type(profile.nextPet) == "number" and profile.nextPet >= 1 then math.floor(profile.nextPet) else 1
	while profile.pets["p" .. n] ~= nil do
		n += 1
	end
	local pid = "p" .. n
	profile.nextPet = n + 1
	local used = {}
	for _, other in profile.pets do
		if type(other) == "table" and type(other.name) == "string" then
			used[other.name] = true
		end
	end
	local free = {}
	for _, nm in p.names do
		if not used[nm] then
			table.insert(free, nm)
		end
	end
	local name = rng:pick(if #free > 0 then free else p.names)
	local coat = rng:int(1, #p.coats)
	profile.pets[pid] = { kind = p.id, name = name, coat = coat }
	return pid, name, coat
end

-- Gives what was rolled.
local function grant(profile: any, kind: string, e: CrateData.Entry, rng: any): Result
	local result: Result = { kind = kind, id = e.id, name = e.name, rarity = e.rarity }
	if kind == "work" then
		if type(profile.crateItems) ~= "table" then
			profile.crateItems = {}
		end
		profile.crateItems[e.id] = math.min(Crates.owned(profile, e.id) + 1, K.MaxOwned)
	else
		result.pet, result.petName, result.coat = addPet(profile, Pets.get(e.id) :: Pets.Pet, rng)
	end
	if type(profile.stats) == "table" then
		profile.stats.crates = (profile.stats.crates or 0) + 1
	end
	return result
end

-- Opens a crate the player holds. Returns what it gave, or nil and why.
function Crates.openHeld(profile: any, kind: any, rng: any): (Result?, string?)
	if not CrateData.get(kind) then
		return nil, "There's no crate like that."
	end
	if Crates.held(profile, kind) < 1 then
		return nil, "You don't have one of those to open."
	end
	local why = Crates.blocked(profile, kind)
	if why then
		return nil, why
	end
	local e = Crates.roll(profile, kind, rng)
	if not e then
		return nil, "You have all you can keep from these."
	end
	profile.crates[kind] = Crates.held(profile, kind) - 1
	return grant(profile, kind, e, rng), nil
end

-- Gives the player a pet of a given kind outright, no crate (a reward: Sim/Shopping's track), named
-- and coated as a crate's pet is. Returns what it gave, or nil and why.
function Crates.givePet(profile: any, kind: any, rng: any): (Result?, string?)
	local p = Pets.get(kind)
	if not p then
		return nil, "There's no pet like that."
	end
	if Crates.petCount(profile) >= Tuning.Pets.Max then
		return nil, "You have as many pets as you can keep."
	end
	local pid, name, coat = addPet(profile, p, rng)
	return { kind = "pet", id = p.id, name = p.name, rarity = p.rarity, pet = pid, petName = name, coat = coat }, nil
end

-- Buys a crate with gems and opens it. Returns what it gave, or nil and why.
function Crates.buy(profile: any, kind: any, rng: any): (Result?, string?)
	local price = Crates.price(kind)
	if not price then
		return nil, "There's no crate like that."
	end
	local why = Crates.blocked(profile, kind)
	if why then
		return nil, why
	end
	if not Gems.canAfford(profile, price) then
		return nil, "Not enough gems."
	end
	local e = Crates.roll(profile, kind, rng)
	if not e then
		return nil, "You have all you can keep from these."
	end
	Gems.spend(profile, price)
	return grant(profile, kind, e, rng), nil
end

-- Does the player have the gems for a crate (the cheaper one)?
function Crates.canAffordOne(profile: any): boolean
	local least = math.huge
	for _, kind in CrateData.Order do
		least = math.min(least, K.Price[kind] or math.huge)
	end
	return Gems.count(profile) >= least
end

-- Crate workplaces (Build mode) -------------------------------------------------------------------

function Crates.isCratePiece(id: any): boolean
	if type(id) ~= "string" then
		return false
	end
	local def = Catalog.get(id)
	return def ~= nil and def.cat == CrateData.Category
end

function Crates.owned(profile: any, id: string): number
	local owned = profile and profile.crateItems
	return whole(if type(owned) == "table" then owned[id] else nil, K.MaxOwned)
end

function Crates.placed(plan: any, id: string): number
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

export type Piece = { def: Catalog.Def, owned: number, left: number }

-- The crate workplaces a player has, rarest first, with how many more of each can go down.
function Crates.pieces(profile: any, plan: any): { Piece }
	local out: { Piece } = {}
	for _, def in Catalog.list(CrateData.Category) do
		local n = Crates.owned(profile, def.id)
		if n > 0 then
			table.insert(out, { def = def, owned = n, left = math.max(0, n - Crates.placed(plan, def.id)) })
		end
	end
	table.sort(out, function(a, b)
		local ra, rb = CrateData.rank((a.def :: any).crate), CrateData.rank((b.def :: any).crate)
		if ra ~= rb then
			return ra > rb
		end
		return (a.def.order or 0) < (b.def.order or 0)
	end)
	return out
end

-- A Build mode change, checked before it is applied: no more of a crate workplace may be down than
-- the player was given. Removals in the same change make room first. (`profile` needs `plan` and
-- `crateItems`.)
function Crates.check(profile: any, requests: any): (boolean, string?)
	if type(requests) ~= "table" then
		return true
	end
	local plan = profile and profile.plan
	local delta: { [string]: number } = {}
	for _, req in requests do
		if type(req) == "table" and req.kind == "items" then
			if req.type == "add" and type(req.obj) == "table" and Crates.isCratePiece(req.obj.id) then
				delta[req.obj.id] = (delta[req.obj.id] or 0) + 1
			elseif
				req.type == "remove"
				and type(req.key) == "string"
				and type(plan) == "table"
				and type(plan.items) == "table"
			then
				local item = plan.items[req.key]
				if type(item) == "table" and Crates.isCratePiece(item.id) then
					delta[item.id] = (delta[item.id] or 0) - 1
				end
			end
		end
	end
	for id, d in delta do
		if d > 0 and Crates.placed(plan, id) + d > Crates.owned(profile, id) then
			if Crates.owned(profile, id) == 0 then
				return false, "That one only comes out of a work crate."
			end
			return false, "You've put down every one you have."
		end
	end
	return true
end

-- Gems from crate jobs -----------------------------------------------------------------------------

-- The gems a day's work at this job brings in (0 for most).
function Crates.jobGems(jobId: string?): number
	local j = jobId and Jobs.get(jobId)
	return if j and j.crate then K.Gems[j.crate] or 0 else 0
end

-- Five o'clock: what the crate jobs worked today bring in, up to the day's cap. `worked` lists
-- { job, share } (the share of a full day's pay each villager earned). `today` is the real day
-- (Sim/Rewards.today). Returns the gems to pay and marks them paid.
function Crates.dayGems(profile: any, worked: { { job: string, share: number } }, today: number): number
	local due = 0
	for _, w in worked do
		if type(w.share) == "number" and w.share >= K.GemShare then
			due += Crates.jobGems(w.job)
		end
	end
	if due <= 0 then
		return 0
	end
	local g = profile.crateGems
	if type(g) ~= "table" or g.day ~= today then
		g = { day = today, n = 0 }
		profile.crateGems = g
	end
	local paid = whole(g.n, K.GemDayCap)
	local pay = math.max(0, math.min(due, K.GemDayCap - paid))
	g.n = paid + pay
	return pay
end

-- Pets -----------------------------------------------------------------------------------------------

export type OwnedPet = { kind: string, name: string, coat: number, vid: string? }

function Crates.petCount(profile: any): number
	local n = 0
	for _, p in if type(profile and profile.pets) == "table" then profile.pets else {} do
		if type(p) == "table" then
			n += 1
		end
	end
	return n
end

-- The player's pets in the order they came, each with its id.
function Crates.petList(profile: any): { { id: string, pet: OwnedPet } }
	local out = {}
	for pid, p in if type(profile and profile.pets) == "table" then profile.pets else {} do
		if type(pid) == "string" and type(p) == "table" then
			table.insert(out, { id = pid, pet = p })
		end
	end
	table.sort(out, function(a, b)
		local na, nb = tonumber(string.sub(a.id, 2)) or 0, tonumber(string.sub(b.id, 2)) or 0
		return na < nb
	end)
	return out
end

-- The pet a villager owns, or nil.
function Crates.petOf(profile: any, vid: string): (string?, OwnedPet?)
	for pid, p in if type(profile and profile.pets) == "table" then profile.pets else {} do
		if type(p) == "table" and p.vid == vid then
			return pid, p
		end
	end
	return nil, nil
end

-- Makes a villager the owner of a pet (false: nobody's). A villager has one pet at most: one they
-- had already is nobody's now. Returns ok, or false and why.
function Crates.assign(profile: any, pid: any, vid: any): (boolean, string?)
	local pets = profile.pets
	local pet = if type(pid) == "string" and type(pets) == "table" then pets[pid] else nil
	if type(pet) ~= "table" then
		return false, "That pet isn't yours."
	end
	if vid == false or vid == nil then
		pet.vid = nil
		return true
	end
	if type(vid) ~= "string" or type(profile.villagers) ~= "table" or not profile.villagers[vid] then
		return false, "Who?"
	end
	for other, p in pets do
		if other ~= pid and type(p) == "table" and p.vid == vid then
			p.vid = nil
		end
	end
	pet.vid = vid
	return true
end

-- A villager who moved out leaves their pet with nobody.
function Crates.forget(profile: any, vid: string)
	for _, p in if type(profile.pets) == "table" then profile.pets else {} do
		if type(p) == "table" and p.vid == vid then
			p.vid = nil
		end
	end
end

-- What a save holds, cleaned (Sim/Schema): held crates of known kinds, known crate workplaces with
-- whole counts, pets of known kinds with a name and a coat, owners who still live in town.
function Crates.clean(profile: any)
	local held = {}
	for _, kind in CrateData.Order do
		local n = Crates.held(profile, kind)
		if n > 0 then
			held[kind] = n
		end
	end
	profile.crates = held
	local items = {}
	for id in if type(profile.crateItems) == "table" then profile.crateItems else {} do
		if Crates.isCratePiece(id) then
			local n = Crates.owned(profile, id)
			if n > 0 then
				items[id] = n
			end
		end
	end
	profile.crateItems = items
	local pets = {}
	local count = 0
	local villagers = if type(profile.villagers) == "table" then profile.villagers else {}
	for _, e in Crates.petList(profile) do
		local p = e.pet
		local kind = Pets.get(p.kind)
		if kind and count < Tuning.Pets.Max and string.match(e.id, "^p%d+$") then
			local name = if type(p.name) == "string"
					and #p.name > 0
					and #p.name <= Tuning.Pets.NameLength * 4
				then p.name
				else kind.names[1]
			local coat = if type(p.coat) == "number" and kind.coats[math.floor(p.coat)] then math.floor(p.coat) else 1
			local vid = if type(p.vid) == "string" and villagers[p.vid] then p.vid else nil
			pets[e.id] = { kind = kind.id, name = name, coat = coat, vid = vid }
			count += 1
		end
	end
	profile.pets = pets
	if type(profile.nextPet) ~= "number" or profile.nextPet ~= profile.nextPet or profile.nextPet < 1 then
		profile.nextPet = 1
	end
	profile.nextPet = math.floor(profile.nextPet)
	if type(profile.crateGems) ~= "table" or type(profile.crateGems.day) ~= "number" then
		profile.crateGems = { day = -1, n = 0 }
	end
	profile.crateTold = profile.crateTold == true
end

return Crates
