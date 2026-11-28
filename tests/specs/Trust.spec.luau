--!nocheck
-- Trusted builders (Sim/Trust, Services/Trust, Services/Build). The user: "add trusted (allow
-- building on your plot, player will have to set build budget). Building on another player's plot
-- will use their money, up to the set budget." The Build and Trust services run for real with their
-- data, plot and remote neighbours stubbed: a trusted player's changes go on the owner's plot, are
-- paid from the owner's coins and counted against the budget, a sale or an undo pays the owner back
-- and gives the budget back (never past it), and what isn't theirs to do is turned down.

local Shared = "ReplicatedStorage.Shared."
local Services = "ServerScriptService.Server.Services."
local Tuning = require(Shared .. "Config.Tuning")
local Plan = require(Shared .. "Build.Plan")
local StarterHouse = require(Shared .. "Data.StarterHouse")
local Town = require(Shared .. "Data.Town")
local TrustSim = require(Shared .. "Sim.Trust")

local K = Tuning.Trust
local game = Harness.game()

-- two players, each with a plot
local function person(name, id, plot)
	local root = { Position = Town.plotCenter(plot) + Vector3.new(0, 3, 0) }
	function root.IsA(_, class)
		return class == "BasePart"
	end
	local p = { Name = name, DisplayName = name, UserId = id, Parent = game, root = root }
	p.Character = {
		FindFirstChild = function(_, child)
			return if child == "HumanoidRootPart" then root else nil
		end,
	}
	return p
end
local owner = person("Sam", 1, 1)
local guest = person("Lee", 2, 2)
local stranger = person("Kit", 3, 3)
local here = { owner, guest, stranger }

local profiles = {
	[owner] = { coins = 5000, plan = StarterHouse.plan(), passes = {}, gemItems = {}, keepsakes = {} },
	[guest] = { coins = 300, plan = StarterHouse.plan(), passes = {}, gemItems = {}, keepsakes = {} },
	[stranger] = { coins = 300, plan = StarterHouse.plan(), passes = {}, gemItems = {}, keepsakes = {} },
}
local plots = { [owner] = 1, [guest] = 2, [stranger] = 3 }
local fired, notices = {}, {}

local oldPlayers = game:GetService("Players")
Harness.addService("Players", {
	PlayerRemoving = Harness.signal(),
	GetPlayers = function()
		return here
	end,
	GetPlayerByUserId = function(_, id)
		for _, p in here do
			if p.UserId == id then
				return p
			end
		end
		return nil
	end,
})
Harness.stub(Services .. "Data", {
	get = function(player)
		return profiles[player]
	end,
	canAfford = function(player, n)
		return profiles[player] ~= nil and profiles[player].coins >= n
	end,
	addCoins = function(player, n)
		profiles[player].coins += n
		return true
	end,
	push = function() end,
	notify = function(player, text)
		table.insert(notices, { to = player, text = text })
	end,
})
local folders = {}
Harness.stub(Services .. "Plots", {
	indexOf = function(player)
		return plots[player]
	end,
	buildFolder = function(i)
		folders[i] = folders[i] or Instance.new("Folder")
		return folders[i]
	end,
	frame = function(i)
		return Town.plotFrame(i)
	end,
})
Harness.stub(Shared .. "Net.Remotes", {
	event = function(name)
		return {
			FireClient = function(_, player, a, b)
				table.insert(fired, { name = name, to = player, a = a, b = b })
			end,
		}
	end,
	fn = function()
		return {}
	end,
})
-- fresh copies of the two services, on these stand-ins
Harness.stub(Services .. "Trust", nil)
Harness.stub(Services .. "Build", nil)
local Trust = require(Services .. "Trust")
local Build = require(Services .. "Build")
-- (and put back for the specs after this one)
for _, name in { "Data", "Plots", "Trust", "Build" } do
	Harness.stub(Services .. name, nil)
end
Harness.stub(Shared .. "Net.Remotes", nil)
Harness.addService("Players", oldPlayers)

local changedFor = {}
Build.Changed:Connect(function(player)
	table.insert(changedFor, player)
end)

-- the service turns away calls closer than 0.05 s apart
local function pause()
	local t = os.clock()
	while os.clock() - t < 0.06 do
	end
end
local function apply(who, requests)
	pause()
	return Build.apply(who, requests)
end
-- a tree on the owner's land, a few studs apart each time
local spot = 0
local function tree()
	spot += 1
	local x1, z1 = Plan.bounds(profiles[owner].plan)
	return {
		{
			type = "add",
			kind = "items",
			obj = { id = "tree_oak", x = x1 + 30 + spot * 9, y = 0.01, z = z1 + 150, r = 0, lv = 0 },
		},
	}
end
local function keyOf(plan, id, x)
	for k, it in plan.items do
		if it.id == id and math.abs(it.x - x) < 0.01 then
			return k
		end
	end
	return nil
end
local function last(name, to)
	for i = #fired, 1, -1 do
		local f = fired[i]
		if f.name == name and (to == nil or f.to == to) then
			return f
		end
	end
	return nil
end

describe("Trusted builders", function()
	it("picks budgets from a short list and never gives back more than was spent", function()
		expect(TrustSim.budget(990)).toBe(1000)
		expect(TrustSim.budget("lots")).toBe(K.Start)
		expect(TrustSim.budget(0 / 0)).toBe(K.Start)
		expect(TrustSim.budget(-5)).toBe(K.Budgets[1])
		expect(TrustSim.budget(1e12)).toBe(K.Budgets[#K.Budgets])
		expect(TrustSim.step(1000, 1)).toBe(2500)
		expect(TrustSim.step(1000, -1)).toBe(500)
		expect(TrustSim.step(K.Budgets[1], -1)).toBe(K.Budgets[1])
		local e = TrustSim.new("Lee", 500)
		expect(TrustSim.left(e)).toBe(500)
		expect(TrustSim.allows(e, 600)).toBe(false)
		expect(TrustSim.allows(e, -600)).toBe(true)
		TrustSim.spend(e, 200)
		expect(TrustSim.left(e)).toBe(300)
		-- a sale of something they never paid for gives back no more than the whole budget
		TrustSim.spend(e, -1000)
		expect(TrustSim.left(e)).toBe(500)
		TrustSim.spend(e, 0 / 0)
		expect(TrustSim.left(e)).toBe(500)
		expect(TrustSim.line(e, "Sam")).toBe("500 left of Sam's 500")
	end)

	it("keeps a player nobody trusts on their own plot", function()
		local ok, why = Trust.build(guest, owner.UserId)
		expect(ok).toBe(false)
		expect(type(why)).toBe("string")
		expect(Build.siteOf(guest)).toBe(guest)
		-- their change goes on their own plot, from their own coins
		local before, mine = profiles[owner].coins, profiles[guest].coins
		local x1, z1 = Plan.bounds(profiles[guest].plan)
		local done = apply(guest, {
			{
				type = "add",
				kind = "items",
				obj = { id = "tree_oak", x = x1 + 30, y = 0.01, z = z1 + 150, r = 0, lv = 0 },
			},
		})
		expect(done).toBe(true)
		expect(profiles[owner].coins).toBe(before)
		expect(profiles[guest].coins < mine).toBeTruthy()
	end)

	it("lets a trusted player build on the owner's plot, paid from the owner's coins up to the budget", function()
		expect((Trust.set(owner, guest, true, 1000))).toBe(true)
		expect(Trust.trusts(owner, guest)).toBe(true)
		expect(Trust.left(owner, guest)).toBe(1000)
		-- both are told: the owner's list, and the guest's (with the plot to stand on)
		expect(last("State", owner).a.trusted[1].name).toBe("Lee")
		expect(last("State", guest).a.trustedBy[1].plot).toBe(1)
		-- standing somewhere else won't do
		local at = guest.root.Position
		guest.root.Position = Town.plotCenter(3) + Vector3.new(0, 3, 0)
		expect((Trust.build(guest, owner.UserId))).toBe(false)
		guest.root.Position = Town.plotCenter(1) + Vector3.new(0, 3, 0)
		local ok, got = Trust.build(guest, owner.UserId)
		expect(ok).toBe(true)
		expect(got.plot).toBe(1)
		expect(got.plan).toBe(profiles[owner].plan)
		expect(got.left).toBe(1000)
		expect(Build.siteOf(guest)).toBe(owner)
		expect(Trust.builders(owner)[1]).toBe(guest)

		local coins, theirs = profiles[owner].coins, profiles[guest].coins
		table.clear(changedFor)
		local req = tree()
		local done, why = apply(guest, req)
		if not done then
			error(tostring(why))
		end
		local key = keyOf(profiles[owner].plan, "tree_oak", req[1].obj.x)
		expect(key ~= nil).toBeTruthy()
		local cost = coins - profiles[owner].coins
		expect(cost > 0).toBeTruthy()
		expect(profiles[guest].coins).toBe(theirs)
		expect(Trust.left(owner, guest)).toBe(1000 - cost)
		-- the plot's owner hears the change as their own plan's, the builder as the plot's
		expect(last("PlanSync", owner) ~= nil).toBeTruthy()
		local site = last("SitePlan", guest)
		expect(site.a).toBe(owner.UserId)
		expect(type(site.b.ops)).toBe("table")
		expect(changedFor[1]).toBe(owner)
		-- and it went in the owner's plot's folder
		expect(#folders[1]:GetChildren() > 0).toBeTruthy()
	end)

	it("pays the owner back for a sale or an undo, and gives the budget back", function()
		local coins, left = profiles[owner].coins, Trust.left(owner, guest)
		local req = tree()
		expect((apply(guest, req))).toBe(true)
		local cost = coins - profiles[owner].coins
		expect(Trust.left(owner, guest)).toBe(left - cost)
		pause()
		expect(Build.undo(guest)).toBe(true)
		expect(profiles[owner].coins).toBe(coins)
		expect(Trust.left(owner, guest)).toBe(left)
		pause()
		expect(Build.redo(guest)).toBe(true)
		expect(Trust.left(owner, guest)).toBe(left - cost)
		-- sold: back to the owner, and to the budget
		local key = keyOf(profiles[owner].plan, "tree_oak", req[1].obj.x)
		local sold, why = apply(guest, { { type = "remove", kind = "items", key = key } })
		if not sold then
			error(tostring(why))
		end
		expect(profiles[owner].coins > coins - cost).toBeTruthy()
		expect(Trust.left(owner, guest) > left - cost).toBeTruthy()
		-- selling what the owner put down gives the budget back only up to what it was set to
		local own = tree()
		expect((apply(owner, own))).toBe(true)
		local ownKey = keyOf(profiles[owner].plan, "tree_oak", own[1].obj.x)
		local paid = profiles[owner].coins
		expect((apply(guest, { { type = "remove", kind = "items", key = ownKey } }))).toBe(true)
		expect(profiles[owner].coins > paid).toBeTruthy()
		expect(Trust.left(owner, guest) <= 1000).toBeTruthy()
	end)

	it("turns down what is past the budget, gem pieces and saved builds", function()
		Trust.set(owner, guest, true, 0)
		expect(Trust.left(owner, guest)).toBe(0)
		local coins = profiles[owner].coins
		local count = 0
		for _ in profiles[owner].plan.items do
			count += 1
		end
		local done, why = apply(guest, tree())
		expect(done).toBe(false)
		expect(why).toBe(TrustSim.Why.budget)
		expect(profiles[owner].coins).toBe(coins)
		local after = 0
		for _ in profiles[owner].plan.items do
			after += 1
		end
		expect(after).toBe(count)
		-- a gem piece, whatever the budget
		Trust.set(owner, guest, true, 50000)
		local x1, z1 = Plan.bounds(profiles[owner].plan)
		local fog = apply(guest, {
			{
				type = "add",
				kind = "items",
				obj = { id = "anim_fog_machine", x = x1 + 60, y = 0.01, z = z1 + 190, r = 0, lv = 0 },
			},
		})
		expect(fog).toBe(false)
		-- a saved build never loads onto a plot you're only trusted on
		local loaded, no = Build.replace(guest, { walls = {}, items = {} })
		expect(loaded).toBe(false)
		expect(no).toBe(TrustSim.Why.saves)
	end)

	it("says so when the owner hasn't the coins", function()
		local coins = profiles[owner].coins
		profiles[owner].coins = 0
		local done, why = apply(guest, tree())
		expect(done).toBe(false)
		expect(why).toBe("Sam doesn't have the coins for that.")
		profiles[owner].coins = coins
	end)

	it("ends when the owner takes it back or either of them leaves", function()
		expect((Trust.set(owner, guest, false))).toBe(true)
		expect(Trust.trusts(owner, guest)).toBe(false)
		expect(Build.siteOf(guest)).toBe(guest)
		expect(#last("State", guest).a.trustedBy).toBe(0)
		-- their next change is on their own plot, from their own coins
		local coins, mine = profiles[owner].coins, profiles[guest].coins
		local x1, z1 = Plan.bounds(profiles[guest].plan)
		expect((apply(guest, {
			{
				type = "add",
				kind = "items",
				obj = { id = "tree_oak", x = x1 + 60, y = 0.01, z = z1 + 150, r = 0, lv = 0 },
			},
		}))).toBe(true)
		expect(profiles[owner].coins).toBe(coins)
		expect(profiles[guest].coins < mine).toBeTruthy()
		-- trusted again, then the owner leaves
		Trust.set(owner, guest, true, 1000)
		expect((Trust.build(guest, owner.UserId))).toBe(true)
		Trust.forget(owner)
		expect(Trust.trusts(owner, guest)).toBe(false)
		expect(Build.siteOf(guest)).toBe(guest)
		-- nobody can trust themselves, or somebody who isn't here
		expect((Trust.set(owner, owner, true, 500))).toBe(false)
		expect((Trust.set(owner, nil, true, 500))).toBe(false)
		-- and there's a limit to how many one owner trusts at once
		local many = {}
		for i = 1, K.Most + 1 do
			local p = person("P" .. i, 100 + i, 2)
			table.insert(here, p)
			table.insert(many, (Trust.set(owner, p, true, 250)))
		end
		expect(many[K.Most]).toBe(true)
		expect(many[K.Most + 1]).toBe(false)
	end)
end)
