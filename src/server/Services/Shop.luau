-- The market stall in the plaza: food for villagers, medicine, and party cakes. Prices drop
-- while a travelling merchant is in town.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Tuning = require(Shared.Config.Tuning)
local Foods = require(Shared.Data.Foods)
local Items = require(Shared.Data.Items)
local Remotes = require(Shared.Net.Remotes)
local Text = require(Shared.Util.Text)

local Data = require(script.Parent.Data)
local Events = require(script.Parent.Events)

local Shop = {}

function Shop.price(player: Player, base: number): number
	if Events.merchantActive(player) then
		return math.max(1, math.floor(base * Tuning.Rewards.MerchantDiscount))
	end
	return base
end

local function buy(player: Player, kind: any, id: any, count: any): (boolean, string?)
	local profile = Data.get(player)
	if not profile then
		return false, "Still loading."
	end
	if type(id) ~= "string" then
		return false, "Buy what?"
	end
	local n = if type(count) == "number" then math.clamp(math.floor(count), 1, 20) else 1
	if kind == "food" then
		local food = Foods.get(id)
		if not food or not food.price then
			return false, "The shop doesn't sell that."
		end
		local cost = Shop.price(player, food.price) * n
		if not Data.canAfford(player, cost) then
			return false, "Not enough coins."
		end
		Data.addCoins(player, -cost)
		profile.inv.food[id] = (profile.inv.food[id] or 0) + n
		Data.push(player, "inv")
		return true
	elseif kind == "item" then
		local item = Items.get(id)
		if not item then
			return false, "The shop doesn't sell that."
		end
		local cost = Shop.price(player, item.price) * n
		if not Data.canAfford(player, cost) then
			return false, "Not enough coins."
		end
		Data.addCoins(player, -cost)
		if id == "cake" then
			-- a cake starts a party straight away
			if not Events.party(player) then
				profile.inv.items.cake = (profile.inv.items.cake or 0) + n
			end
		else
			profile.inv.items[id] = (profile.inv.items[id] or 0) + n
		end
		Data.push(player, "inv")
		return true, Text.fill("Bought {item}.", { item = item.name:lower() })
	end
	return false, "Buy what?"
end

function Shop.start()
	Remotes.fn("ShopBuy").OnServerInvoke = buy
end

return Shop
