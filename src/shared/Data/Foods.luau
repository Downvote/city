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
	{ id = "apple", name = "Apple", price = 20, color = "E8667A" },
	{ id = "bread", name = "Bread roll", price = 25, color = "E3C08D" },
	{ id = "carrot", name = "Carrot", price = 20, color = "F08A2E" },
	{ id = "cheese", name = "Cheese", price = 35, color = "FFD45C" },
	{ id = "soup", name = "Mushroom soup", price = 45, color = "A8743F" },
	{ id = "skewer", name = "Fish skewer", price = 50, color = "8FD3E8" },
	{ id = "tart", name = "Berry tart", price = 60, color = "9C7AD6" },
	{ id = "honeycake", name = "Honey cake", price = 70, color = "F5B431" },
	{ id = "riceball", name = "Rice ball", price = 30, color = "F7F3EA" },
	{ id = "pancakes", name = "Pancakes", price = 55, color = "D9C7A7" },
	{ id = "curry", name = "Spicy curry", price = 80, color = "D4622B" },
	{ id = "pie", name = "Pumpkin pie", price = 75, color = "F08A2E" },
	{ id = "icecream", name = "Ice cream", price = 40, color = "FFD1DC" },
	{ id = "salad", name = "Garden salad", price = 35, color = "78BF5E" },
	{ id = "chocolate", name = "Chocolate", price = 45, color = "6B4423" },
	{ id = "pudding", name = "Pudding", price = 50, color = "FFE9A8" },
	{ id = "broccoli", name = "Broccoli", price = 15, color = "4E9A44" },
	{ id = "pickles", name = "Pickles", price = 15, color = "A8DB8A" },
	{ id = "stew", name = "Hearty stew", price = 85, color = "8A5A2E" },
	{ id = "starfruit", name = "Star fruit", price = 90, color = "FFE9A8" },
	{ id = "dragonchili", name = "Fire chili", price = 65, color = "C7383F" },
	{ id = "goldapple", name = "Golden apple", price = 120, color = "DEB252" },
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
