--!strict
-- Foods: villagers eat them and cheer up. Every villager secretly has a favourite and a food
-- they can't stand; you find out by feeding them. The shop sells most; a few only turn up in events.
-- `joy` is how much a meal lifts their mood (doubled for their favourite).

export type Food = {
	id: string,
	name: string,
	price: number?, -- shop price; nil when it only drops
	joy: number,
	color: string,
}

local Foods = {}

local list: { Food } = {
	{ id = "apple", name = "Apple", price = 20, joy = 5, color = "E8667A" },
	{ id = "bread", name = "Bread roll", price = 25, joy = 5, color = "E3C08D" },
	{ id = "carrot", name = "Carrot", price = 20, joy = 4, color = "F08A2E" },
	{ id = "cheese", name = "Cheese", price = 35, joy = 5, color = "FFD45C" },
	{ id = "soup", name = "Mushroom soup", price = 45, joy = 6, color = "A8743F" },
	{ id = "skewer", name = "Fish skewer", price = 50, joy = 5, color = "8FD3E8" },
	{ id = "tart", name = "Berry tart", price = 60, joy = 5, color = "9C7AD6" },
	{ id = "honeycake", name = "Honey cake", price = 70, joy = 7, color = "F5B431" },
	{ id = "riceball", name = "Rice ball", price = 30, joy = 5, color = "F7F3EA" },
	{ id = "pancakes", name = "Pancakes", price = 55, joy = 5, color = "D9C7A7" },
	{ id = "curry", name = "Spicy curry", price = 80, joy = 6, color = "D4622B" },
	{ id = "pie", name = "Pumpkin pie", price = 75, joy = 6, color = "F08A2E" },
	{ id = "icecream", name = "Ice cream", price = 40, joy = 5, color = "FFD1DC" },
	{ id = "salad", name = "Garden salad", price = 35, joy = 5, color = "78BF5E" },
	{ id = "chocolate", name = "Chocolate", price = 45, joy = 5, color = "6B4423" },
	{ id = "pudding", name = "Pudding", price = 50, joy = 6, color = "FFE9A8" },
	{ id = "broccoli", name = "Broccoli", price = 15, joy = 5, color = "4E9A44" },
	{ id = "pickles", name = "Pickles", price = 15, joy = 5, color = "A8DB8A" },
	{ id = "stew", name = "Hearty stew", joy = 9, color = "8A5A2E" },
	{ id = "starfruit", name = "Star fruit", joy = 9, color = "FFE9A8" },
	{ id = "dragonchili", name = "Fire chili", joy = 7, color = "C7383F" },
	{
		id = "goldapple",
		name = "Golden apple",
		joy = 17,
		color = "DEB252",
	},
}

Foods.list = list

local byId: { [string]: Food } = {}
for _, f in Foods.list do
	byId[f.id] = f
end

function Foods.get(id: string): Food?
	return byId[id]
end

-- Foods the shop sells.
function Foods.shop(): { Food }
	local out = {}
	for _, f in Foods.list do
		if f.price then
			table.insert(out, f)
		end
	end
	return out
end

return Foods
