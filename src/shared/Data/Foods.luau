--!strict
-- Foods: villagers eat them to grow stronger. Every villager secretly has a favourite and a food
-- they can't stand; you find out by feeding them. Monsters drop foods, the shop sells some.
-- `boost` is added to the villager's adventure stats (doubled when it's their favourite).

export type Food = {
	id: string,
	name: string,
	price: number?, -- shop price; nil when it only drops
	boost: { [string]: number },
	color: string,
}

local Foods = {}

local list: { Food } = {
	{ id = "apple", name = "Apple", price = 20, boost = { hp = 2 }, color = "E8667A" },
	{ id = "bread", name = "Bread roll", price = 25, boost = { hp = 1, def = 1 }, color = "E3C08D" },
	{ id = "carrot", name = "Carrot", price = 20, boost = { spd = 1 }, color = "F08A2E" },
	{ id = "cheese", name = "Cheese", price = 35, boost = { def = 2 }, color = "FFD45C" },
	{ id = "soup", name = "Mushroom soup", price = 45, boost = { mp = 3 }, color = "A8743F" },
	{ id = "skewer", name = "Fish skewer", price = 50, boost = { atk = 2 }, color = "8FD3E8" },
	{ id = "tart", name = "Berry tart", price = 60, boost = { mag = 2 }, color = "9C7AD6" },
	{ id = "honeycake", name = "Honey cake", price = 70, boost = { hp = 2, mp = 2 }, color = "F5B431" },
	{ id = "riceball", name = "Rice ball", price = 30, boost = { hp = 1, atk = 1 }, color = "F7F3EA" },
	{ id = "pancakes", name = "Pancakes", price = 55, boost = { spd = 1, hp = 1 }, color = "D9C7A7" },
	{ id = "curry", name = "Spicy curry", price = 80, boost = { atk = 3 }, color = "D4622B" },
	{ id = "pie", name = "Pumpkin pie", price = 75, boost = { def = 2, hp = 1 }, color = "F08A2E" },
	{ id = "icecream", name = "Ice cream", price = 40, boost = { mag = 1, spd = 1 }, color = "FFD1DC" },
	{ id = "salad", name = "Garden salad", price = 35, boost = { mp = 2 }, color = "78BF5E" },
	{ id = "chocolate", name = "Chocolate", price = 45, boost = { mag = 2 }, color = "6B4423" },
	{ id = "pudding", name = "Pudding", price = 50, boost = { hp = 2, def = 1 }, color = "FFE9A8" },
	{ id = "broccoli", name = "Broccoli", price = 15, boost = { def = 1, hp = 1 }, color = "4E9A44" },
	{ id = "pickles", name = "Pickles", price = 15, boost = { spd = 2 }, color = "A8DB8A" },
	{ id = "stew", name = "Hearty stew", boost = { hp = 4, def = 2 }, color = "8A5A2E" },
	{ id = "starfruit", name = "Star fruit", boost = { mag = 3, mp = 3 }, color = "FFE9A8" },
	{ id = "dragonchili", name = "Fire chili", boost = { atk = 4 }, color = "C7383F" },
	{
		id = "goldapple",
		name = "Golden apple",
		boost = { hp = 4, atk = 2, mag = 2, def = 2, spd = 2, mp = 2 },
		color = "DEB252",
	},
}

Foods.list = list

Foods.StatCap = 60 -- the most any one stat can grow from food

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
