--!strict
-- Shopping for looks, as rules. The user: "make it such that spending robux on accessories give you
-- gems, and make a reward track based on how much you spend on accessories, giving different types
-- of crates, pets and coin rewards".
--
-- Roblox sells the avatar items the creator shows (UI/BuyLook, Services/Avatar's BuyLook); the
-- server hears what was really bought and what Roblox prices it at (Services/Shopping) and records
-- it here: Shopping.record counts each asset or bundle once per player, ever, and gives back gems,
-- Tuning.Shopping.Gems for each Robux, the part of a gem left over kept for the next buy. What is
-- free counts nothing.
--
-- The Robux counted add up to the track (Shopping.Tiers): each tier, once that much has been spent
-- in all, gives coins, crates held in the Store (Sim/Crates.give), or a pet of its own
-- (Sim/Crates.givePet), claimed once each from the Rewards menu's Shopping tab or its Claim all.
-- As with Sim/Rewards, nothing here pays coins or gems out: a claim says what it came to and the
-- server pays it. Crates and pets go straight into the save, as the daily gift's crates do.
--
-- Saved as profile.shopping = { spent, carry, counted, got }:
--   spent    whole Robux counted, in all
--   carry    the part of a gem not paid yet (0 up to 1)
--   counted  the items counted, as keys ("a<asset id>", "b<bundle id>"), oldest first, at most
--            Tuning.Shopping.Kept
--   got      the tiers claimed, by id
-- No services, so the specs run it.

local Tuning = require(script.Parent.Parent.Config.Tuning)
local CrateData = require(script.Parent.Parent.Data.Crates)
local PetData = require(script.Parent.Parent.Data.Pets)
local Text = require(script.Parent.Parent.Util.Text)
local Rng = require(script.Parent.Parent.Util.Rng)
local Crates = require(script.Parent.Crates)

local K = Tuning.Shopping

local Shopping = {}

export type Tier = {
	id: string, -- what profile.shopping.got keeps; never change one once players have claimed it
	spend: number, -- the Robux spent on looks in all that reaches it
	coins: number?, -- coins
	crate: string?, -- crates to open in the Store (a Data/Crates kind)...
	n: number?, -- ...this many (1 when nil)
	pet: string?, -- a pet of this kind (Data/Pets), named and coated as a crate's are
}

-- The track, a reward a tier, each worth more than the one of its kind before. Coins next to the
-- daily gift (250 to 550) and the town goals (300 to 3,000); the pets climb the rarities.
Shopping.Tiers = {
	{ id = "s1", spend = 25, coins = 500 },
	{ id = "s2", spend = 60, crate = "work" },
	{ id = "s3", spend = 120, crate = "pet" },
	{ id = "s4", spend = 200, coins = 1500 },
	{ id = "s5", spend = 320, pet = "hedgehog" },
	{ id = "s6", spend = 480, crate = "work", n = 2 },
	{ id = "s7", spend = 700, coins = 4000 },
	{ id = "s8", spend = 1000, pet = "penguin" },
	{ id = "s9", spend = 1400, crate = "pet", n = 2 },
	{ id = "s10", spend = 2000, coins = 10000 },
	{ id = "s11", spend = 2800, pet = "capybara" },
	{ id = "s12", spend = 3800, crate = "work", n = 3 },
	{ id = "s13", spend = 5000, pet = "dragon" },
} :: { Tier }

local byId: { [string]: Tier } = {}
for _, t in Shopping.Tiers do
	byId[t.id] = t
end

function Shopping.tier(id: any): Tier?
	return if type(id) == "string" then byId[id] else nil
end

local function whole(v: any): number
	if type(v) ~= "number" or v ~= v or v < 0 or v >= math.huge then
		return 0
	end
	return math.floor(v)
end

-- The key an item is counted under: "a123" for an asset, "b123" for a bundle (nil for neither).
function Shopping.key(kind: any, id: any): string?
	if (kind ~= "asset" and kind ~= "bundle") or type(id) ~= "number" then
		return nil
	end
	if id ~= id or id < 1 or id % 1 ~= 0 or id >= 2 ^ 53 then
		return nil
	end
	return (if kind == "asset" then "a" else "b") .. string.format("%d", id)
end

export type State = { spent: number, carry: number, counted: { string }, got: { [string]: boolean } }

-- profile.shopping, made whole if it isn't (a missing or broken field starts empty).
function Shopping.state(profile: any): State
	local s = profile.shopping
	if type(s) ~= "table" then
		s = {}
		profile.shopping = s
	end
	s.spent = whole(s.spent)
	if type(s.carry) ~= "number" or s.carry ~= s.carry or s.carry < 0 or s.carry >= 1 then
		s.carry = 0
	end
	if type(s.counted) ~= "table" then
		s.counted = {}
	end
	if type(s.got) ~= "table" then
		s.got = {}
	end
	return s
end

-- Has this item been counted for the player already?
function Shopping.counted(profile: any, kind: any, id: any): boolean
	local key = Shopping.key(kind, id)
	return key ~= nil and table.find(Shopping.state(profile).counted, key) ~= nil
end

-- What `robux` spent comes to in whole gems, with `carry` (a part of a gem from before). Returns the
-- gems and the part of a gem left.
function Shopping.gems(robux: number, carry: number?): (number, number)
	local total = math.max(0, robux) * K.Gems + (carry or 0)
	local gems = math.floor(total + 1e-9)
	return gems, math.clamp(total - gems, 0, 0.999999)
end

-- How many tiers `spent` Robux reaches.
function Shopping.reached(spent: number): number
	local n = 0
	for i, t in Shopping.Tiers do
		if spent >= t.spend then
			n = i
		end
	end
	return n
end

export type Bought = { gems: number, robux: number, reached: number }

-- Counts an item the player bought at `price` Robux (as Roblox prices it, asked by the server).
-- Returns what it came to (the gems to pay, the Robux counted, how many tiers it newly reached),
-- or nil and why: "counted" (it was already), "free" (nothing to count) or "bad".
function Shopping.record(profile: any, kind: any, id: any, price: any): (Bought?, string?)
	local key = Shopping.key(kind, id)
	if not key then
		return nil, "bad"
	end
	local s = Shopping.state(profile)
	if table.find(s.counted, key) then
		return nil, "counted"
	end
	local robux = math.min(whole(price), K.ItemMax)
	if robux <= 0 then
		return nil, "free"
	end
	table.insert(s.counted, key)
	while #s.counted > K.Kept do
		table.remove(s.counted, 1)
	end
	local before = Shopping.reached(s.spent)
	s.spent += robux
	local gems, carry = Shopping.gems(robux, s.carry)
	s.carry = carry
	return { gems = gems, robux = robux, reached = Shopping.reached(s.spent) - before }, nil
end

-- The tier after the last one reached, or nil when every one is.
function Shopping.next(profile: any): Tier?
	return Shopping.Tiers[Shopping.reached(Shopping.state(profile).spent) + 1]
end

-- Why a tier's reward can't go to the player now (nil when it can): no room for another pet, or
-- for that many more crates of its kind.
function Shopping.blocked(profile: any, t: Tier): string?
	if t.pet and Crates.petCount(profile) >= Tuning.Pets.Max then
		return "You have as many pets as you can keep."
	end
	if t.crate and Crates.held(profile, t.crate) + (t.n or 1) > Tuning.Crates.Held then
		return "Open some crates in the Store first."
	end
	return nil
end

export type Status = { tier: Tier, reached: boolean, claimed: boolean, blocked: string? }

-- Every tier and where the player is with it.
function Shopping.status(profile: any): { Status }
	local s = Shopping.state(profile)
	local out = {}
	for _, t in Shopping.Tiers do
		local reached = s.spent >= t.spend
		local claimed = s.got[t.id] == true
		table.insert(out, {
			tier = t,
			reached = reached,
			claimed = claimed,
			blocked = if reached and not claimed then Shopping.blocked(profile, t) else nil,
		})
	end
	return out
end

-- How many tiers are reached and can be claimed now (for the Rewards tile's badge).
function Shopping.ready(profile: any): number
	local n = 0
	for _, st in Shopping.status(profile) do
		if st.reached and not st.claimed and not st.blocked then
			n += 1
		end
	end
	return n
end

export type Got = {
	tier: Tier,
	coins: number, -- for the server to pay
	crates: { string }, -- the crates now held, a kind each
	pet: Crates.Result?, -- the pet that came
}

local defaultRng: any = nil

-- Claims a tier's reward once, when it is reached: its crates and its pet go into the save at
-- once, its coins are for the server to pay. `rng` (Util/Rng) names the pet. Returns ok and what it
-- came to, or false and why.
function Shopping.claim(profile: any, id: any, rng: any?): (boolean, Got | string)
	local t = Shopping.tier(id)
	if not t then
		return false, "There's no reward like that."
	end
	local s = Shopping.state(profile)
	if s.got[t.id] then
		return false, "You've had that one."
	end
	if s.spent < t.spend then
		return false, "Not yet."
	end
	local why = Shopping.blocked(profile, t)
	if why then
		return false, why
	end
	local got: Got = { tier = t, coins = 0, crates = {} }
	if t.pet then
		if not rng then
			defaultRng = defaultRng or Rng.new()
		end
		local pet, petWhy = Crates.givePet(profile, t.pet, rng or defaultRng)
		if not pet then
			return false, petWhy or "That didn't work."
		end
		got.pet = pet
	end
	if t.crate then
		for _ = 1, t.n or 1 do
			Crates.give(profile, t.crate, 1)
			table.insert(got.crates, t.crate)
		end
	end
	got.coins = t.coins or 0
	s.got[t.id] = true
	return true, got
end

-- Words ---------------------------------------------------------------------------------------------

-- What a tier gives, in a few words: "500 coins", "Work crate", "2 work crates", "Hedgehog".
function Shopping.rewardName(t: Tier): string
	if t.pet then
		local p = PetData.get(t.pet)
		return if p then p.name else "A pet"
	elseif t.crate then
		local kind = CrateData.get(t.crate)
		local name = if kind then kind.name else "Crate"
		local n = t.n or 1
		return if n == 1 then name else Text.fill("{n} {name}s", { n = n, name = string.lower(name) })
	end
	return Text.coins(t.coins or 0)
end

-- What a tier gives, as UI/Icons draws it: the coins, the crate's own icon, a paw for a pet.
function Shopping.icon(t: Tier): string
	if t.pet then
		return "paw"
	elseif t.crate then
		local kind = CrateData.get(t.crate)
		return if kind then kind.icon else "gift"
	end
	return "coins"
end

-- A pet that came to live in town, as the news and a notice say it.
function Shopping.petLine(pet: Crates.Result): string
	return Text.fill("{name} the {kind} came to live in town.", {
		name = pet.petName or pet.name,
		kind = string.lower(pet.name),
	})
end

-- The notice a claim brings.
function Shopping.claimNotice(got: Got): string
	if got.pet then
		return Shopping.petLine(got.pet)
	elseif #got.crates > 0 then
		local kind = CrateData.get(got.crates[1])
		local name = if kind then string.lower(kind.name) else "crate"
		if #got.crates == 1 then
			return Text.fill("Your {x} is in the Store.", { x = name })
		end
		return Text.fill("Your {n} {x}s are in the Store.", { n = #got.crates, x = name })
	end
	return Text.fill("Reward claimed. +{c} coins", { c = Text.commas(got.coins) })
end

-- The notice once what was bought is counted: the gems, and a word when a reward came due.
function Shopping.boughtNotice(gems: number, reached: number): string
	local head = if gems > 0
		then Text.fill("+{g} for your new look.", { g = Text.gems(gems) })
		else "Counted toward your shopping rewards."
	if reached > 0 then
		return head .. " A shopping reward is ready."
	end
	return head
end

-- A save's shopping, cleaned (Sim/Schema): whole Robux, a part of a gem under one, counted keys
-- well formed and once each (the newest Kept), and only tiers there are.
function Shopping.clean(profile: any)
	local s = profile.shopping
	if type(s) ~= "table" then
		s = {}
	end
	local carry = s.carry
	if type(carry) ~= "number" or carry ~= carry or carry < 0 or carry >= 1 then
		carry = 0
	end
	local counted = {}
	local seen: { [string]: boolean } = {}
	for _, key in if type(s.counted) == "table" then s.counted else {} do
		if type(key) == "string" and string.match(key, "^[ab]%d+$") and #key <= 20 and not seen[key] then
			seen[key] = true
			table.insert(counted, key)
		end
	end
	while #counted > K.Kept do
		table.remove(counted, 1)
	end
	local got = {}
	for id, on in if type(s.got) == "table" then s.got else {} do
		if on == true and byId[id] then
			got[id] = true
		end
	end
	profile.shopping = { spent = whole(s.spent), carry = carry, counted = counted, got = got }
end

return Shopping
