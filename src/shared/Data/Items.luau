--!strict
-- Things the shop sells besides food.

export type Item = { id: string, name: string, price: number, blurb: string }

local Items = {}

local list: { Item } = {
	{ id = "cake", name = "Party cake", price = 150, blurb = "Throw a party in town whenever you like." },
	{ id = "medicine", name = "Medicine", price = 60, blurb = "Cures a cold straight away." },
}

Items.list = list

local byId: { [string]: Item } = {}
for _, i in list do
	byId[i.id] = i
end

function Items.get(id: string): Item?
	return byId[id]
end

return Items
