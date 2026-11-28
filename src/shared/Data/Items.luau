--!strict
-- The things a player can carry in their bag (Sim/Bag) and give to villagers (Sim/Gifts). The
-- user: "make it such that you can pick up items, and interactable items give you things, such as a
-- bookshelf giving you a book, you can work on stoves to make food, flower beds giving you
-- flowers, etc. You can then gift villagers different items to make them happy."
--
-- Every food a villager can crave (Data/Foods) is a thing too, under its own id, so the food in a
-- craving and the food in the bag are the same. The rest are books, flowers, drinks, fruit, crafts
-- and small finds, and a few treasures only town goals give (Data/Goals' `thing`). Each has a
-- category, which is what a personality likes or dislikes (Data/Personalities' `likes` and
-- `dislikes`); treasures are loved by everyone.
--
-- `color` is what its icon is drawn in (UI/ItemArt draws every thing by its id, a silhouette like
-- the interface's icons), one that reads on the dark glass and on a card in either look (the Bag
-- spec checks, as the Icons spec does for the foods). `phrase` is how it reads in a sentence ("a
-- cup of tea", "a tulip").
--
-- Sources: what a piece gives when a player holds E on it (Build/Catalog's `gives` names one of
-- these). `verb` words the prompt, `things` are what it gives, `rare` now and then instead
-- (Tuning.Bag.RareChance), `cook` makes the prompt a longer hold (a stove, a grill), and `work`
-- marks a workplace's: those are made while the player works there (Services/Bag, every
-- Tuning.Bag.WorkEvery seconds), with no prompt of their own.

local Foods = require(script.Parent.Foods)

export type Item = {
	id: string,
	name: string,
	cat: string,
	color: string,
	phrase: string,
	special: boolean?, -- a treasure: only town goals give one
}

export type Source = {
	verb: string,
	things: { string },
	rare: { string }?,
	cook: boolean?,
	work: boolean?,
}

local Items = {}

-- What a thing can be. A personality likes some of these and dislikes one (Data/Personalities).
Items.Categories = {
	{ id = "fruit", name = "Fruit" },
	{ id = "greens", name = "Greens" },
	{ id = "sweet", name = "Sweets" },
	{ id = "meal", name = "Meals" },
	{ id = "drink", name = "Drinks" },
	{ id = "book", name = "Books" },
	{ id = "flower", name = "Flowers" },
	{ id = "craft", name = "Crafts" },
	{ id = "trinket", name = "Trinkets" },
	{ id = "treasure", name = "Treasures" },
}

local catName: { [string]: string } = {}
for _, c in Items.Categories do
	catName[c.id] = c.name
end

function Items.categoryName(id: string): string
	return catName[id] or id
end

-- The foods' categories.
local FOOD_CAT: { [string]: string } = {
	apple = "fruit",
	starfruit = "fruit",
	goldapple = "fruit",
	carrot = "greens",
	broccoli = "greens",
	salad = "greens",
	pickles = "greens",
	tart = "sweet",
	honeycake = "sweet",
	icecream = "sweet",
	chocolate = "sweet",
	pudding = "sweet",
	pancakes = "sweet",
	pie = "sweet",
	bread = "meal",
	cheese = "meal",
	soup = "meal",
	skewer = "meal",
	riceball = "meal",
	curry = "meal",
	stew = "meal",
	dragonchili = "meal",
}
Items.FoodCategories = FOOD_CAT

-- The rest, each drawn in UI/ItemArt.
local OWN: { Item } = {
	{ id = "strawberry", name = "Strawberry", cat = "fruit", color = "F0506E", phrase = "a strawberry" },
	{ id = "herbs", name = "Bunch of herbs", cat = "greens", color = "6CC25A", phrase = "a bunch of herbs" },
	{ id = "cookie", name = "Cookies", cat = "sweet", color = "D39552", phrase = "some cookies" },
	{ id = "honey", name = "Jar of honey", cat = "sweet", color = "ECA22C", phrase = "a jar of honey" },
	{ id = "tea", name = "Cup of tea", cat = "drink", color = "D08A58", phrase = "a cup of tea" },
	{ id = "juice", name = "Orange juice", cat = "drink", color = "F59234", phrase = "a glass of orange juice" },
	{ id = "storybook", name = "Storybook", cat = "book", color = "4FA9D9", phrase = "a storybook" },
	{ id = "poems", name = "Book of poems", cat = "book", color = "A486E8", phrase = "a book of poems" },
	{ id = "tulip", name = "Tulip", cat = "flower", color = "FF6F91", phrase = "a tulip" },
	{ id = "daisy", name = "Daisy", cat = "flower", color = "C3CCE0", phrase = "a daisy" },
	{ id = "sunflower", name = "Sunflower", cat = "flower", color = "F2BE2E", phrase = "a sunflower" },
	{ id = "bouquet", name = "Bouquet", cat = "flower", color = "F07FA8", phrase = "a bouquet" },
	{ id = "drawing", name = "Drawing", cat = "craft", color = "5FB3E8", phrase = "a drawing" },
	{ id = "toyboat", name = "Toy boat", cat = "craft", color = "D69A5C", phrase = "a toy boat" },
	{ id = "letter", name = "Letter", cat = "trinket", color = "D9B878", phrase = "a letter" },
	{ id = "seashell", name = "Seashell", cat = "trinket", color = "F2A07B", phrase = "a seashell" },
	{ id = "pebble", name = "Smooth pebble", cat = "trinket", color = "A7B1C0", phrase = "a smooth pebble" },
	{ id = "acorn", name = "Acorn", cat = "trinket", color = "C08850", phrase = "an acorn" },
	{ id = "luckycoin", name = "Lucky coin", cat = "trinket", color = "E6C83A", phrase = "a lucky coin" },
	-- treasures: only town goals give these, and every villager loves one
	{
		id = "musicbox",
		name = "Music box",
		cat = "treasure",
		color = "E07062",
		phrase = "a music box",
		special = true,
	},
	{
		id = "snowglobe",
		name = "Snow globe",
		cat = "treasure",
		color = "7FC8F0",
		phrase = "a snow globe",
		special = true,
	},
	{
		id = "goldacorn",
		name = "Golden acorn",
		cat = "treasure",
		color = "F0B02A",
		phrase = "a golden acorn",
		special = true,
	},
}

local list: { Item } = {}
for _, f in Foods.list do
	table.insert(list, {
		id = f.id,
		name = f.name,
		cat = FOOD_CAT[f.id] or "meal",
		color = f.color,
		phrase = Foods.phrase(f),
	})
end
for _, item in OWN do
	table.insert(list, item)
end
Items.list = list

local byId: { [string]: Item } = {}
for _, item in list do
	byId[item.id] = item
end

function Items.get(id: any): Item?
	return if type(id) == "string" then byId[id] else nil
end

-- How a thing reads at the start of a sentence: "A cup of tea", "Mushroom soup".
function Items.capital(item: Item): string
	return item.phrase:sub(1, 1):upper() .. item.phrase:sub(2)
end

function Items.phrase(item: Item): string
	return item.phrase
end

-- Every thing of a category, in list order.
function Items.inCategory(cat: string): { Item }
	local out = {}
	for _, item in list do
		if item.cat == cat then
			table.insert(out, item)
		end
	end
	return out
end

-- Sources ------------------------------------------------------------------------------------------

Items.Sources = {
	books = { verb = "Take a book", things = { "storybook", "poems" } },
	flowers = { verb = "Pick a flower", things = { "tulip", "daisy", "sunflower" } },
	bunches = { verb = "Take a bunch", things = { "bouquet", "tulip", "sunflower" } },
	veg = { verb = "Pick vegetables", things = { "carrot", "broccoli", "salad" }, rare = { "pickles" } },
	herbs = { verb = "Pick herbs", things = { "herbs" } },
	fruit = { verb = "Pick fruit", things = { "apple", "strawberry" }, rare = { "starfruit" } },
	acorns = { verb = "Look for acorns", things = { "acorn" } },
	honey = { verb = "Take honey", things = { "honey" } },
	fridge = { verb = "Take a snack", things = { "cheese", "pudding", "pickles", "juice", "apple" } },
	pantry = { verb = "Take a snack", things = { "bread", "cookie", "honey", "riceball" } },
	cook = {
		verb = "Cook",
		things = { "soup", "pancakes", "curry", "stew", "riceball" },
		rare = { "pie" },
		cook = true,
	},
	grill = { verb = "Grill", things = { "skewer", "dragonchili" }, cook = true },
	tea = { verb = "Make tea", things = { "tea" } },
	shells = { verb = "Take a shell", things = { "seashell", "pebble" } },
	sand = { verb = "Dig", things = { "seashell", "pebble" }, rare = { "luckycoin" } },
	wish = { verb = "Look in the well", things = { "pebble" }, rare = { "luckycoin" } },
	toys = { verb = "Take a toy", things = { "toyboat" } },
	mail = { verb = "Check for letters", things = { "letter" } },
	draw = { verb = "Draw something", things = { "drawing" } },
	-- made while working at a workplace (Services/Bag): no prompt of their own
	bakery = { verb = "Bake", things = { "bread", "honeycake", "tart", "cookie" }, rare = { "pie" }, work = true },
	cafe = { verb = "Brew", things = { "tea", "cookie", "honeycake" }, work = true },
	icecream = { verb = "Scoop", things = { "icecream" }, work = true },
	florist = { verb = "Tie a bunch", things = { "bouquet", "tulip", "sunflower" }, work = true },
	library = { verb = "Sort books", things = { "storybook", "poems" }, work = true },
	artist = { verb = "Paint", things = { "drawing" }, work = true },
	builder = { verb = "Whittle", things = { "toyboat" }, work = true },
	market = { verb = "Stack produce", things = { "apple", "carrot", "cheese", "strawberry" }, work = true },
	post = { verb = "Sort the post", things = { "letter" }, work = true },
} :: { [string]: Source }

function Items.source(key: any): Source?
	return if type(key) == "string" then Items.Sources[key] else nil
end

-- One thing from a source: a usual one, or now and then its rare one. `rng` is a Util/Rng.
function Items.pick(source: Source, rng: any, rareChance: number): string
	if source.rare and #source.rare > 0 and rng:chance(rareChance) then
		return rng:pick(source.rare)
	end
	return rng:pick(source.things)
end

return Items
