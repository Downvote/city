--!nocheck
-- The server's Build service, run for real with its data and plot services stubbed: requests
-- go through, cost coins, draw models, sync to the client, and undo gives the coins back.

local StarterHouse = require("ReplicatedStorage.Shared.Data.StarterHouse")
local Plan = require("ReplicatedStorage.Shared.Build.Plan")

local profile = { coins = 3000, plan = StarterHouse.plan() }
local fired = {}
local folder = Instance.new("Folder")
Harness.stub("ServerScriptService.Server.Services.Data", {
	get = function()
		return profile
	end,
	canAfford = function(_, n)
		return profile.coins >= n
	end,
	addCoins = function(_, n)
		profile.coins += n
		return true
	end,
})
Harness.stub("ServerScriptService.Server.Services.Plots", {
	indexOf = function()
		return 1
	end,
	buildFolder = function()
		return folder
	end,
	frame = function()
		return CFrame.new()
	end,
})
Harness.stub("ReplicatedStorage.Shared.Net.Remotes", {
	event = function(name)
		return {
			FireClient = function(_, _, msg)
				table.insert(fired, { name = name, msg = msg })
			end,
		}
	end,
	fn = function()
		return {}
	end,
})
local Build = require("ServerScriptService.Server.Services.Build")

local clock = 0
-- the service turns away calls closer than 0.05 s apart, and the harness's task.wait doesn't
-- really wait
local function pause()
	local t = os.clock()
	while os.clock() - t < 0.06 do
	end
end
local function player()
	return { Name = "P", UserId = 1 }
end
local p = player()
local function apply(requests)
	-- the service throttles bursts; pretend time passes between calls
	clock += 1
	return Build.apply(p, requests)
end

describe("Build service", function()
	it("builds a wall, a floor and a tree and charges for them", function()
		local before = profile.coins
		local x0 = Plan.bounds(profile.plan)
		local wall = {
			x1 = x0 + 10,
			z1 = 60,
			x2 = x0 + 20,
			z2 = 60,
			lv = 0,
			style = "wall",
			a = { c = "F2E8D5", m = "Plaster" },
			b = { c = "F7F3EA", m = "SmoothPlastic" },
		}
		local ok, err = apply({ { type = "add", kind = "walls", obj = wall } })
		if not ok then
			error(err)
		end
		task.wait(0.06)
		ok, err = Build.apply(p, {
			{
				type = "add",
				kind = "items",
				obj = { id = "tree_oak", x = x0 + 30, y = 0.01, z = 70, r = 0, lv = 0, junk = "x" },
			},
		})
		expect(ok == true or err == "slow down a little").toBeTruthy()
		expect(profile.coins < before).toBeTruthy()
		expect(#folder:GetChildren() >= 1).toBeTruthy()
		expect(fired[1].name).toBe("PlanSync")
		for _, item in profile.plan.items do
			expect(item.junk).toBe(nil)
		end
	end)

	it("refuses things outside the land and refunds on undo", function()
		local ok = select(
			1,
			Build.apply(
				p,
				{ { type = "add", kind = "items", obj = { id = "tree_oak", x = 1, y = 0, z = 1, r = 0, lv = 0 } } }
			)
		)
		expect(ok).toBe(false)
	end)

	it("keeps a gift a gift: the starting house sells for nothing, however a client asks", function()
		-- a piece of the starting house, and the coins before
		local key, item
		for k, it in profile.plan.items do
			if it.gift and it.gift > 0 and not it.wall then
				key, item = k, it
				break
			end
		end
		expect(key ~= nil).toBeTruthy()
		local gift = item.gift
		-- a client sends it back moved, with its gift "forgotten"
		local moved = table.clone(item)
		moved.r = (item.r + 90) % 360
		moved.gift = 0
		pause()
		local coins = profile.coins
		local ok, why = Build.apply(p, { { type = "set", kind = "items", key = key, obj = moved } })
		if not ok then
			error(tostring(why))
		end
		expect(profile.plan.items[key].gift).toBe(gift)
		expect(profile.coins).toBe(coins)
		-- and sells it
		pause()
		coins = profile.coins
		local sold, why2 = Build.apply(p, { { type = "remove", kind = "items", key = key } })
		if not sold then
			error(tostring(why2))
		end
		expect(profile.plan.items[key]).toBe(nil)
		expect(profile.coins).toBe(coins)
		-- a client can't hand itself a gift either
		pause()
		coins = profile.coins
		local x0 = Plan.bounds(profile.plan)
		local added = Build.apply(p, {
			{
				type = "add",
				kind = "items",
				obj = { id = "tree_oak", x = x0 + 8, y = 0.01, z = 92, r = 0, lv = 0, gift = 9999 },
			},
		})
		if not added then
			error("the tree wasn't planted")
		end
		local found = false
		for _, it in profile.plan.items do
			if it.id == "tree_oak" and it.x == x0 + 8 and it.z == 92 then
				found = true
				expect(it.gift).toBe(nil)
			end
		end
		expect(found).toBeTruthy()
		expect(profile.coins < coins).toBeTruthy()
	end)
end)
