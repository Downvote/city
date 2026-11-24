--!strict
-- Foods: what a villager can crave. Every villager has a favourite, which they crave half the
-- time. There is no shop and nothing is kept in a bag: a craving is a wish (Sim/Life), and its
-- Buy button pays for the food there and then. `price` is the food's own price; what the player
-- pays is Life.cravingPrice (this times Tuning.Life.CravingMarkup). The pictures are in the
-- client's UI/ItemArt, by id.

export type Food = {
	id: string,
	name: string,
	price: number,
	color: string,
}

local Foods = {}

local list: { Food } = {
	{ id = "apple", name = "Apple", price = 20, color = "E5414B" },
	{ id = "bread", name = "Bread roll", price = 25, color = "C98A4A" },
	{ id = "carrot", name = "Carrot", price = 20, color = "F2842B" },
	{ id = "cheese", name = "Cheese", price = 35, color = "F2BE2E" },
	{ id = "soup", name = "Mushroom soup", price = 45, color = "C99260" },
	{ id = "skewer", name = "Fish skewer", price = 50, color = "4FAEE6" },
	{ id = "tart", name = "Berry tart", price = 60, color = "9F78E6" },
	{ id = "honeycake", name = "Honey cake", price = 70, color = "ECA22C" },
	{ id = "riceball", name = "Rice ball", price = 30, color = "B8C0CC" },
	{ id = "pancakes", name = "Pancakes", price = 55, color = "DDA058" },
	{ id = "curry", name = "Spicy curry", price = 80, color = "E07A2E" },
	{ id = "pie", name = "Pumpkin pie", price = 75, color = "EB8C3C" },
	{ id = "icecream", name = "Ice cream", price = 40, color = "FF85B4" },
	{ id = "salad", name = "Garden salad", price = 35, color = "6CC25A" },
	{ id = "chocolate", name = "Chocolate", price = 45, color = "A8683C" },
	{ id = "pudding", name = "Pudding", price = 50, color = "E3A445" },
	{ id = "broccoli", name = "Broccoli", price = 15, color = "4FAA4E" },
	{ id = "pickles", name = "Pickles", price = 15, color = "98C95A" },
	{ id = "stew", name = "Hearty stew", price = 85, color = "D2583F" },
	{ id = "starfruit", name = "Star fruit", price = 90, color = "E6C83A" },
	{ id = "dragonchili", name = "Fire chili", price = 65, color = "EB3F3F" },
	{ id = "goldapple", name = "Golden apple", price = 120, color = "F0B02A" },
}

Foods.list = list

local byId: { [string]: Food } = {}
for _, f in Foods.list do
	byId[f.id] = f
end

function Foods.get(id: string): Food?
	return byId[id]
end

return Foods
