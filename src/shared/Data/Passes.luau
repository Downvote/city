--!strict
-- What can be bought with Robux: the game passes and the gem packs. The user: "add gamepasses,
-- just like bloxburg. add collisions, and a gamepass should be there to remove it, another for
-- basement, another for more levels, another for bigger plot, (make the biggest size smaller
-- without paying smaller) another for double income, another for smaller grid size placement,
-- another for x y scaling, vip, and other gamepasses bloxburg uses for better build mode", and of
-- gems: "allow players to buy gems ... and buying with robux. it should be a rare currency".
--
-- The names and what each does are our own. Each pass and pack needs its id from the Roblox
-- website (Creations > the experience > Monetization > Passes / Developer Products) pasted into
-- `id` below; one left at 0 can't be bought (the store shows it as coming soon), and in Studio
-- `Passes.StudioOwnsAll` lets the owner try every pass without buying it.

local Passes = {}

export type Pass = {
	key: string, -- what the code asks for: Sim/Passes.has(profile, key)
	id: number, -- the game pass id on Roblox (0 until it is made there)
	name: string,
	blurb: string, -- what it does, in as few plain words as will say it
	icon: string, -- UI/Icons
	price: number, -- in Robux, what the store shows (Roblox charges what the pass is set to on the site)
}

-- In order of the store's list.
Passes.list = {
	{
		key = "freeplace",
		id = 0,
		name = "Free Placing",
		blurb = "Place anything anywhere, at any angle.",
		icon = "move",
		price = 250,
	},
	{
		key = "finegrid",
		id = 0,
		name = "Fine Grid",
		blurb = "A grid four times finer.",
		icon = "grid",
		price = 100,
	},
	{
		key = "stretch",
		id = 0,
		name = "Stretch",
		blurb = "Resize any piece.",
		icon = "ruler",
		price = 200,
	},
	{
		key = "basement",
		id = 0,
		name = "Basement",
		blurb = "A floor under your house.",
		icon = "stairs",
		price = 150,
	},
	{
		key = "floors",
		id = 0,
		name = "Tall Builds",
		blurb = "Up to eight floors.",
		icon = "layers",
		price = 150,
	},
	{
		key = "bigplot",
		id = 0,
		name = "Big Plot",
		blurb = "Land up to 400 a side.",
		icon = "map",
		price = 300,
	},
	{
		key = "doublepay",
		id = 0,
		name = "Double Pay",
		blurb = "Double pay from work.",
		icon = "coins",
		price = 400,
	},
	{
		key = "anycolour",
		id = 0,
		name = "Any Colour",
		blurb = "Paint in any colour.",
		icon = "brush",
		price = 100,
	},
	{
		key = "saveslots",
		id = 0,
		name = "More Saves",
		blurb = "Eight saved builds.",
		icon = "blueprint",
		price = 75,
	},
	{
		key = "vip",
		id = 0,
		name = "VIP",
		blurb = "A gold name tag, a daily gem, VIP pieces and 10% more pay.",
		icon = "gem",
		price = 350,
	},
} :: { Pass }

Passes.byKey = {} :: { [string]: Pass }
Passes.byId = {} :: { [number]: Pass }
for _, p in Passes.list do
	Passes.byKey[p.key] = p
	if p.id ~= 0 then
		Passes.byId[p.id] = p
	end
end

-- Gem packs: developer products, bought as often as a player likes. Gems are rare: a day's
-- reward is one or two.
export type Pack = { key: string, id: number, gems: number, price: number, name: string }

Passes.packs = {
	{ key = "gems10", id = 0, gems = 10, price = 49, name = "Pouch of gems" },
	{ key = "gems25", id = 0, gems = 25, price = 99, name = "Bag of gems" },
	{ key = "gems70", id = 0, gems = 70, price = 249, name = "Box of gems" },
	{ key = "gems150", id = 0, gems = 150, price = 499, name = "Chest of gems" },
	{ key = "gems400", id = 0, gems = 400, price = 1199, name = "Vault of gems" },
} :: { Pack }

Passes.packById = {} :: { [number]: Pack }
for _, p in Passes.packs do
	if p.id ~= 0 then
		Passes.packById[p.id] = p
	end
end

-- Crates bought with Robux: developer products, as the gem packs are (the user: "add work crates
-- that can be bought with gems or robux"). One bought waits in the Store's Crates tab to be opened
-- (Sim/Crates.give; Services/Store pays the receipt once). The ids are 0 until the products are
-- made on Roblox (Creations > the experience > Monetization > Developer Products): paste each
-- one's id here. One left at 0 can't be bought (its button says Soon).
export type CrateProduct = { key: string, id: number, kind: string, price: number, name: string }

Passes.crates = {
	{ key = "crate_work", id = 0, kind = "work", price = 99, name = "Work crate" },
} :: { CrateProduct }

function Passes.crateProduct(key: string): CrateProduct?
	for _, c in Passes.crates do
		if c.key == key then
			return c
		end
	end
	return nil
end

-- In Studio (never on a live server), does the game's owner own every pass to try them out?
Passes.StudioOwnsAll = true

function Passes.get(key: string): Pass?
	return Passes.byKey[key]
end

return Passes
