--!nocheck
-- Gifts (Build/Plan) and what the starting house counts for (Sim/City.worth). The user asked for
-- a far bigger, more detailed starting house with a workshop ("improve the starting house detail
-- by alot, and add a workspace next to it"). It is a gift: selling it must not turn into coins,
-- and it must not carry a new town most of the way to its next level.

local Shared = "ReplicatedStorage.Shared."
local Plan = require(Shared .. "Build.Plan")
local StarterHouse = require(Shared .. "Data.StarterHouse")
local City = require(Shared .. "Sim.City")
local Tuning = require(Shared .. "Config.Tuning")

describe("Gifts", function()
	it("make every piece of the starting house sell for nothing", function()
		local plan = StarterHouse.plan()
		local pieces = 0
		for _, kind in Plan.Kinds do
			for key, obj in plan[kind] do
				pieces += 1
				expect(obj.gift).toBe(Plan.cost(kind, obj))
				expect(Plan.price(kind, obj)).toBe(0)
				-- selling it (and whatever hangs on it) refunds nothing
				expect(Plan.changeCost(Plan.removeOps(plan, kind, key))).toBe(0)
			end
		end
		expect(pieces > 100).toBeTruthy()
		expect(Plan.giftValue(plan)).toBe(Plan.value(plan))
	end)

	it("refund what was paid on top, and undo for free", function()
		local item = { id = "tree_oak", x = 10, y = 0, z = 10, r = 0, lv = 0 }
		local full = Plan.cost("items", item)
		expect(full > 0).toBeTruthy()
		local given = table.clone(item)
		given.gift = full - 5
		expect(Plan.price("items", given)).toBe(5)
		expect(Plan.changeCost({ { op = "remove", kind = "items", key = "1", obj = given } })).toBe(-5)
		-- putting it back (undo) costs only that much too
		expect(Plan.changeCost({ { op = "add", kind = "items", key = "1", obj = given } })).toBe(5)
		-- a gift is never worth more than the piece
		given.gift = full * 10
		expect(Plan.price("items", given)).toBe(0)
	end)

	it("come through a save only as a plain number of coins, and never from a client", function()
		local plan = StarterHouse.plan()
		local raw = Plan.copy(plan)
		for _, obj in raw.items do
			obj.gift = "lots"
			break
		end
		local back = Plan.sanitize(raw)
		local strings = 0
		for _, obj in back.items do
			if type(obj.gift) ~= "number" and obj.gift ~= nil then
				strings += 1
			end
		end
		expect(strings).toBe(0)
		expect(Plan.giftValue(back) > 0).toBeTruthy()
		-- what a client sends is cleaned of it
		expect(Plan.clean("items", { id = "tree_oak", x = 1, y = 0, z = 1, r = 0, lv = 0, gift = 999 }).gift).toBe(nil)
	end)

	it("count the starting house toward the town's level at the old cottage's worth", function()
		local plan = StarterHouse.plan()
		expect(Plan.value(plan) > Tuning.City.StarterWorth).toBeTruthy()
		expect(City.worth(plan)).toBe(Tuning.City.StarterWorth)
		-- three villagers in the starting house alone are still a hamlet, as before
		local villagers = {}
		for i = 1, 3 do
			villagers["v" .. i] = { mood = 50 }
		end
		local stats = City.stats({ plan = plan, villagers = villagers, coins = 0 })
		expect(stats.level).toBe(1)
		expect(stats.value).toBe(Tuning.City.StarterWorth)
		-- what the owner builds on top counts in full
		plan.items["900"] = { id = "tree_oak", x = 5, y = 0, z = 90, r = 0, lv = 0 }
		expect(City.worth(plan)).toBe(Tuning.City.StarterWorth + Plan.cost("items", plan.items["900"]))
		-- an old town, whose house carries no gift, counts all of its value as it always did
		local old = Plan.copy(StarterHouse.plan())
		for _, kind in Plan.Kinds do
			for _, obj in old[kind] do
				obj.gift = nil
			end
		end
		expect(City.worth(old)).toBe(Plan.value(old))
	end)
end)
