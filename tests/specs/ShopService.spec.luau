--!nocheck
-- The market stall as the server sees it (Services/Shop), with its neighbours stubbed. Food and
-- things are bought in any number and charged for each. A party cake is different: it is eaten
-- at the party it starts, so one is bought at a time and only when a party can start. Buying five
-- used to charge for five and throw one party, and a cake bought while an event was running sat
-- in the bag for good with no way to use it.

local Shared = "ReplicatedStorage.Shared."
local Services = "ServerScriptService.Server.Services."
local Tuning = require(Shared .. "Config.Tuning")
local Foods = require(Shared .. "Data.Foods")
local Items = require(Shared .. "Data.Items")

local player = { Name = "Owner" }
local coins, profile, merchant, canParty, parties, pushes

local function reset(money)
	coins = money
	profile = { inv = { food = {}, items = {} } }
	merchant, canParty, parties, pushes = false, true, 0, 0
end

Harness.stub(Services .. "Data", {
	get = function(who)
		return if who == player then profile else nil
	end,
	canAfford = function(_, cost)
		return coins >= cost
	end,
	addCoins = function(_, by)
		coins += by
	end,
	push = function()
		pushes += 1
	end,
})
Harness.stub(Services .. "Events", {
	merchantActive = function()
		return merchant
	end,
	party = function()
		if not canParty then
			return false
		end
		parties += 1
		return true
	end,
})
local handlers = {}
Harness.stub(Shared .. "Net.Remotes", {
	fn = function(name)
		handlers[name] = handlers[name] or {}
		return handlers[name]
	end,
})

local Shop = require(Services .. "Shop")
Shop.start()
local buy = handlers.ShopBuy.OnServerInvoke

for _, name in { "Data", "Events" } do
	Harness.stub(Services .. name, nil)
end
Harness.stub(Shared .. "Net.Remotes", nil)

local apple = Foods.get("apple")
local cake = Items.get("cake")
local medicine = Items.get("medicine")

describe("Shop", function()
	it("sells food by the number asked for, at its price each", function()
		reset(1000)
		local ok = buy(player, "food", "apple", 5)
		expect(ok).toBe(true)
		expect(profile.inv.food.apple).toBe(5)
		expect(coins).toBe(1000 - apple.price * 5)
		expect(pushes > 0).toBeTruthy()
	end)

	it("sells things the same way", function()
		reset(1000)
		local ok = buy(player, "item", "medicine", 2)
		expect(ok).toBe(true)
		expect(profile.inv.items.medicine).toBe(2)
		expect(coins).toBe(1000 - medicine.price * 2)
	end)

	it("takes less while the merchant is in town", function()
		reset(1000)
		merchant = true
		buy(player, "food", "apple", 1)
		local cut = math.max(1, math.floor(apple.price * Tuning.Rewards.MerchantDiscount))
		expect(coins).toBe(1000 - cut)
		expect(cut < apple.price).toBeTruthy()
	end)

	it("refuses what can't be paid for, and takes nothing", function()
		reset(apple.price * 2)
		local ok, why = buy(player, "food", "apple", 3)
		expect(ok).toBe(false)
		expect(type(why)).toBe("string")
		expect(coins).toBe(apple.price * 2)
		expect(profile.inv.food.apple).toBe(nil)
	end)

	it("starts one party for one cake's price, however many were asked for", function()
		reset(5000)
		local ok = buy(player, "item", "cake", 5)
		expect(ok).toBe(true)
		expect(parties).toBe(1)
		expect(coins).toBe(5000 - cake.price)
		-- eaten at the party: none goes in the bag
		expect(profile.inv.items.cake or 0).toBe(0)
	end)

	it("sells no cake while something else is going on, and charges nothing", function()
		reset(5000)
		canParty = false
		local ok, why = buy(player, "item", "cake", 1)
		expect(ok).toBe(false)
		expect(type(why)).toBe("string")
		expect(parties).toBe(0)
		expect(coins).toBe(5000)
		expect(profile.inv.items.cake or 0).toBe(0)
	end)

	it("lets a cake left in the bag from before pay for the party", function()
		reset(0)
		profile.inv.items.cake = 2
		local ok = buy(player, "item", "cake", 1)
		expect(ok).toBe(true)
		expect(parties).toBe(1)
		expect(coins).toBe(0)
		expect(profile.inv.items.cake).toBe(1)
	end)

	it("starts no party it can't be paid for", function()
		reset(cake.price - 1)
		local ok = buy(player, "item", "cake", 1)
		expect(ok).toBe(false)
		expect(parties).toBe(0)
		expect(coins).toBe(cake.price - 1)
	end)

	it("treats what a client sends as untrusted", function()
		reset(1000)
		expect((buy(player, "food", 12, 1))).toBe(false)
		expect((buy(player, "food", "no such food", 1))).toBe(false)
		expect((buy(player, "item", "no such thing", 1))).toBe(false)
		expect((buy(player, "nonsense", "apple", 1))).toBe(false)
		expect(coins).toBe(1000)
		-- a number that isn't one buys one; a huge one is capped
		expect((buy(player, "food", "apple", "lots"))).toBe(true)
		expect(profile.inv.food.apple).toBe(1)
		reset(1000000)
		buy(player, "food", "apple", 1e9)
		expect(profile.inv.food.apple).toBe(20)
		-- nobody with no profile buys anything
		expect((buy({ Name = "Stranger" }, "food", "apple", 1))).toBe(false)
	end)
end)
