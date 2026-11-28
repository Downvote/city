--!strict
-- Crates: what a work crate can give, and how likely each rarity is. The user: "add work crates
-- that can be bought with gems or robux, which give exclusive work spaces which are unique to
-- crates, giving a random one with effectiveness scaling off rarity ... Some work crates are also
-- given through achievements, goals, daily rewards". (Pet crates came and went: "remove pets. the
-- only crate should be work crates".) A work crate gives a workplace from Build/Recipes/CrateWork
-- (the catalog's "crates" category, each with its `crate` rarity and its own job in Data/Jobs'
-- crate list). The odds (Tuning.Crates.Odds) are shown before buying. Sim/Crates opens them.

local Tuning = require(script.Parent.Parent.Config.Tuning)
local Catalog = require(script.Parent.Parent.Build.Catalog)
local Recipe = require(script.Parent.Parent.Build.Recipe)
local Colors = require(script.Parent.Parent.Util.Colors)

type R = Recipe.Recipe

local Crates = {}

-- The rarities, commonest first.
Crates.Rarities = { "common", "uncommon", "rare", "epic", "legendary" }
Crates.RarityNames = {
	common = "Common",
	uncommon = "Uncommon",
	rare = "Rare",
	epic = "Epic",
	legendary = "Legendary",
}
-- Each rarity's colour in the interface: a Kit.Theme key, so it follows the look.
Crates.Tones = { common = "Green", uncommon = "Teal", rare = "Blue", epic = "Purple", legendary = "Orange" }

local rank: { [string]: number } = {}
for i, r in Crates.Rarities do
	rank[r] = i
end
function Crates.rank(rarity: string?): number
	return rarity and rank[rarity] or 0
end

-- The Build mode category the crate workplaces are in.
Crates.Category = "crates"

export type Kind = {
	id: string,
	name: string,
	phrase: string, -- as it reads in a sentence ("a work crate")
	blurb: string,
	icon: string, -- UI/Icons
	product: string, -- its developer product's key in Data/Passes
}

Crates.Order = { "work" }
Crates.Kinds = {
	work = {
		id = "work",
		name = "Work crate",
		phrase = "a work crate",
		blurb = "Crate jobs give special workplaces that pay more than regular ones.",
		icon = "briefcase",
		product = "crate_work",
	},
} :: { [string]: Kind }

function Crates.get(kind: any): Kind?
	return if type(kind) == "string" then Crates.Kinds[kind] else nil
end

export type Entry = { id: string, name: string, rarity: string }

-- What a crate can give, rarest last (then by name).
function Crates.entries(kind: string): { Entry }
	local out: { Entry } = {}
	if kind == "work" then
		for _, def in Catalog.list(Crates.Category) do
			local r = (def :: any).crate
			if type(r) == "string" and rank[r] then
				table.insert(out, { id = def.id, name = def.name, rarity = r })
			end
		end
	end
	table.sort(out, function(a, b)
		if rank[a.rarity] ~= rank[b.rarity] then
			return rank[a.rarity] < rank[b.rarity]
		end
		return a.name < b.name
	end)
	return out
end

export type Odds = { rarity: string, chance: number, entries: { Entry } }

-- The rarities a crate gives, each with its chance (0 to 1, all of them adding to 1) and what is in
-- it. A rarity the crate has nothing of is left out and the rest share its chance.
function Crates.odds(kind: string): { Odds }
	local byRarity: { [string]: { Entry } } = {}
	for _, e in Crates.entries(kind) do
		byRarity[e.rarity] = byRarity[e.rarity] or {}
		table.insert(byRarity[e.rarity], e)
	end
	local total = 0
	for _, r in Crates.Rarities do
		if byRarity[r] then
			total += Tuning.Crates.Odds[r] or 0
		end
	end
	local out: { Odds } = {}
	for _, r in Crates.Rarities do
		local list = byRarity[r]
		local w = Tuning.Crates.Odds[r] or 0
		if list and w > 0 and total > 0 then
			table.insert(out, { rarity = r, chance = w / total, entries = list })
		end
	end
	return out
end

-- A chance as the store writes it: "50%", "2%", "0.5%".
function Crates.percent(chance: number): string
	local p = chance * 100
	if p >= 10 or math.abs(p - math.floor(p + 0.5)) < 0.05 then
		return tostring(math.floor(p + 0.5)) .. "%"
	end
	return string.format("%.1f%%", p)
end

-- The crate itself, for the store and the opening (in its own space, standing on y = 0) ------------

local WOOD = Color3.fromRGB(186, 142, 96)
local IRON = Color3.fromRGB(96, 92, 100)
local BRASS = Color3.fromRGB(212, 172, 98)

-- A work crate: a box of boards with iron corners and bands, a brass hasp, and a tag on a string.
local function workCrate(r: R)
	local s = 2.4
	local h = s / 2
	-- the boards of each side, slightly apart in shade
	for i = 0, 3 do
		local y = 0.06 + i * 0.58
		local col = if i % 2 == 0 then WOOD else Colors.shade(WOOD, 0.9)
		r:block(-h, y, -h, h, y + 0.56, h, col, "Wood")
	end
	r:block(-h + 0.06, s - 0.04, -h + 0.06, h - 0.06, s + 0.1, h - 0.06, Colors.shade(WOOD, 1.06), "Wood")
	-- the iron at the corners and two bands round it
	for _, x in { -1, 1 } do
		for _, z in { -1, 1 } do
			r:block(x * h - 0.1, 0, z * h - 0.1, x * h + 0.1, s + 0.12, z * h + 0.1, IRON, "Metal")
		end
	end
	for _, y in { 0.55, 1.85 } do
		r:block(-h - 0.04, y, -h - 0.04, h + 0.04, y + 0.16, h + 0.04, IRON, "Metal")
	end
	-- the hasp on the front and its lock, and studs along the bands
	r:block(-0.22, 1.5, h + 0.04, 0.22, 2.2, h + 0.1, BRASS, "Metal")
	r:cyl(0, 1.62, h + 0.16, 0.12, 0.3, "z", BRASS, "Metal")
	for _, x in { -0.8, -0.4, 0.4, 0.8 } do
		for _, y in { 0.63, 1.93 } do
			r:cyl(x, y, h + 0.08, 0.06, 0.1, "z", Colors.shade(IRON, 1.3), "Metal")
		end
	end
	-- a paper tag hung from the band
	r:boxAt(
		CFrame.new(0.82, 1.3, h + 0.09) * CFrame.Angles(0, 0, 0.18),
		0.36,
		0.5,
		0.03,
		Color3.fromRGB(236, 226, 200),
		"Fabric"
	)
	r:boxAt(CFrame.new(0.78, 1.66, h + 0.09) * CFrame.Angles(0, 0, 0.1), 0.02, 0.22, 0.02, IRON, "Metal")
end

Crates.Size = { work = Vector3.new(2.7, 2.6, 2.7) }

function Crates.prims(_kind: string): { Recipe.Prim }
	local r = Recipe.new(WOOD, IRON)
	workCrate(r)
	return r.prims
end

return Crates
