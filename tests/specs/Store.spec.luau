--!nocheck
-- The store's server side (Services/Store), run for real with its neighbours stubbed the way
-- WishService.spec does it. The user: "add gamepasses, just like bloxburg", "allow players to buy
-- gems ... and buying with robux", "add offline earnings" and "add group rewards, such as
-- percentage increase of earnings". It learns which passes a player owns from Roblox (keeping
-- what the save said when Roblox can't be asked, dropping a pass with no id yet), grants one bought
-- in the game once Roblox says so, pays a gem pack's receipt once and only grants it once the save
-- has it, works out the pay boost, pays offline earnings once on arriving, and answers the claims.

local Shared = "ReplicatedStorage.Shared."
local Services = "ServerScriptService.Server.Services."
local Tuning = require(Shared .. "Config.Tuning")
local Schema = require(Shared .. "Sim.Schema")
local Gems = require(Shared .. "Sim.Gems")
local City = require(Shared .. "Sim.City")
local Offline = require(Shared .. "Sim.Offline")
local Passes = require(Shared .. "Sim.Passes")
local PassData = require(Shared .. "Data.Passes")
local Playtime = require(Shared .. "Data.Playtime")
local Appearance = require(Shared .. "Avatar.Appearance")
local StarterHouse = require(Shared .. "Data.StarterHouse")
local RealRemotes = require(Shared .. "Net.Remotes")
local Rng = require(Shared .. "Util.Rng")

local env = Harness.env()
local game = Harness.game()
local GRANTED = Enum.ProductPurchaseDecision.PurchaseGranted
local NOT_YET = Enum.ProductPurchaseDecision.NotProcessedYet

-- ids on Roblox for a few passes and a pack, as they would be once made there (put back at the end)
local IDS = { doublepay = 1001, vip = 1002, finegrid = 1003 }
local PACK = "gems25"
local PACK_ID = 2001
local oldIds = {}
for _, pass in PassData.list do
	oldIds[pass.key] = pass.id
	pass.id = IDS[pass.key] or 0
end
local oldPack = {}
for _, pack in PassData.packs do
	oldPack[pack.key] = pack.id
	pack.id = if pack.key == PACK then PACK_ID else 0
end

-- a town with a worker in the starter house's workshop
local function town()
	local profile = Schema.newProfile()
	profile.plan = StarterHouse.plan()
	local input = Schema.cleanVillagerInput({ name = "Mara", pers = "sunny", app = Appearance.default() })
	local v = Schema.newVillager("v1", input, Rng.new(1))
	profile.villagers.v1 = v
	profile.order = { "v1" }
	v.job = City.freeWorkplace(profile)
	return profile
end

local function person(name, id)
	local p = {
		Name = name,
		UserId = id,
		Parent = game,
		attributes = {},
		Character = nil,
		member = false,
		CharacterAdded = Harness.signal(),
	}
	function p:SetAttribute(key, value)
		self.attributes[key] = value
	end
	function p:GetAttribute(key)
		return self.attributes[key]
	end
	function p:IsInGroupAsync()
		return self.member
	end
	return p
end
local owner = person("Owner", 1)
local stranger = person("Stranger", 2) -- somebody with no save loaded
local profiles = { [owner] = town() }

-- Roblox, as the store sees it
local owns = {} -- [passId] = true, or "error" for a check that fails
local market = {
	PromptGamePassPurchaseFinished = Harness.signal(),
}
function market:UserOwnsGamePassAsync(_userId, id)
	if owns[id] == "error" then
		error("Roblox didn't answer")
	end
	return owns[id] == true
end
local studio = false
local saves, saveOk = 0, true
local notices, pushes, logs, coinsAdded = {}, {}, {}, {}
local seen = {} -- what Data.seenBefore says for each player
local remotes = {}

-- Tasks run at once and waits don't wait; a loop that keeps waiting is parked for good.
local realTask = env.task
local waits = setmetatable({}, { __mode = "k" })
env.task = {
	spawn = function(f, ...)
		coroutine.resume(coroutine.create(f), ...)
	end,
	defer = function(f, ...)
		coroutine.resume(coroutine.create(f), ...)
	end,
	delay = function() end,
	wait = function(t)
		local co = coroutine.running()
		waits[co] = (waits[co] or 0) + 1
		if waits[co] > 20 and coroutine.isyieldable() then
			coroutine.yield()
		end
		return t or 0
	end,
	cancel = function() end,
}

local oldPlayers = game:GetService("Players")
Harness.addService("Players", {
	PlayerAdded = Harness.signal(),
	PlayerRemoving = Harness.signal(),
	GetPlayers = function()
		return { owner, stranger }
	end,
	GetPlayerByUserId = function(_, id)
		return if id == 1 then owner elseif id == 2 then stranger else nil
	end,
})
Harness.addService("MarketplaceService", market)
Harness.addService("RunService", {
	IsStudio = function()
		return studio
	end,
})
local loaded = Harness.signal()
Harness.stub(Services .. "Data", {
	Loaded = loaded,
	get = function(player)
		return profiles[player]
	end,
	push = function(player, ...)
		table.insert(pushes, { to = player, keys = { ... } })
	end,
	notify = function(player, text, kind)
		table.insert(notices, { to = player, text = text, kind = kind })
	end,
	log = function(player, text)
		table.insert(logs, { to = player, text = text })
	end,
	addGems = function(player, n)
		local p = profiles[player]
		if not p then
			return false
		end
		Gems.add(p, n)
		return true
	end,
	addCoins = function(player, n)
		local p = profiles[player]
		if not p then
			return false
		end
		p.coins += n
		table.insert(coinsAdded, n)
		return true
	end,
	save = function()
		saves += 1
		return saveOk
	end,
	isUnsaved = function()
		return false
	end,
	seenBefore = function(player)
		return seen[player] or 0
	end,
})
Harness.stub(Shared .. "Net.Remotes", {
	fn = function(name)
		remotes[name] = remotes[name] or {}
		return remotes[name]
	end,
	event = function()
		return { FireClient = function() end }
	end,
})
Harness.stub(Services .. "Store", nil)
local Store = require(Services .. "Store")
Store.start()

-- only this spec's copy of the service keeps the stand-ins
env.task = realTask
Harness.stub(Services .. "Data", nil)
Harness.stub(Shared .. "Net.Remotes", nil)
Harness.stub(Services .. "Store", nil)
Harness.addService("Players", oldPlayers)

local function reset()
	table.clear(notices)
	table.clear(pushes)
	table.clear(logs)
	table.clear(coinsAdded)
	table.clear(owns)
	saves, saveOk, studio = 0, true, false
	owner.attributes = {}
	owner.member = false
	Tuning.Group.Id = 0
end

local function pushed(key)
	for _, p in pushes do
		if p.to == owner and table.find(p.keys, key) then
			return true
		end
	end
	return false
end

local function receipt(id, product)
	return { PlayerId = 1, ProductId = product or PACK_ID, PurchaseId = id, CurrencySpent = 99 }
end

describe("Store service", function()
	it("listens for receipts and passes bought, and answers the claims", function()
		expect(market.ProcessReceipt).toBe(Store.processReceipt)
		for _, name in { "WelcomeBack", "PlaytimeClaim", "AchievementClaim", "GroupClaim" } do
			expect(table.find(RealRemotes.Functions, name) ~= nil).toBeTruthy()
			expect(type(remotes[name].OnServerInvoke)).toBe("function")
		end
	end)

	it("learns the passes from Roblox, keeping what the save said when Roblox can't be asked", function()
		reset()
		local p = profiles[owner]
		-- the save says Fine Grid and Basement; Basement has no id yet, so nobody can own it
		p.passes = { finegrid = true, basement = true, vip = true }
		owns[IDS.doublepay] = true
		owns[IDS.finegrid] = "error"
		Store.refreshPasses(owner, p)
		expect(p.passes.doublepay).toBe(true)
		expect(p.passes.finegrid).toBe(true) -- (Roblox didn't answer: kept)
		expect(p.passes.basement).toBe(nil) -- (no id: nobody owns it)
		expect(p.passes.vip).toBe(nil) -- (Roblox says no: a refund takes it away)
		expect(pushed("passes")).toBeTruthy()
		expect(owner.attributes.VIP).toBe(false)
	end)

	it("in Studio, every pass is the owner's to try", function()
		reset()
		studio = true
		local p = profiles[owner]
		p.passes = {}
		Store.refreshPasses(owner, p)
		for _, key in Passes.keys() do
			expect(p.passes[key]).toBe(true)
		end
		expect(owner.attributes.VIP).toBe(true)
	end)

	it("grants a pass bought in the game once Roblox says so, and only then", function()
		reset()
		local p = profiles[owner]
		p.passes = {}
		-- not bought, or a pass the game doesn't sell: nothing
		Store.passBought(owner, IDS.vip, false)
		Store.passBought(owner, 999, true)
		expect(p.passes.vip).toBe(nil)
		-- Roblox's check says no after all: nothing
		Store.passBought(owner, IDS.vip, true)
		expect(p.passes.vip).toBe(nil)
		-- bought and owned: it's theirs, with a word of thanks
		owns[IDS.vip] = true
		Store.passBought(owner, IDS.vip, true)
		expect(p.passes.vip).toBe(true)
		expect(owner.attributes.VIP).toBe(true)
		expect(pushed("passes")).toBeTruthy()
		expect(notices[#notices].text).toBe("Thank you. VIP is yours now.")
		-- the check can't be made just now: Roblox's own word that it was bought stands
		owns[IDS.doublepay] = "error"
		Store.passBought(owner, IDS.doublepay, true)
		expect(p.passes.doublepay).toBe(true)
		-- somebody with no save loaded gets nothing (and nothing breaks)
		Store.passBought(stranger, IDS.vip, true)
		expect(profiles[stranger]).toBe(nil)
	end)

	it("pays a gem pack once per purchase, and grants it once the save has it", function()
		reset()
		local p = profiles[owner]
		p.gems, p.receipts = 5, {}
		expect(Store.processReceipt(receipt("r1"))).toBe(GRANTED)
		expect(p.gems).toBe(30)
		expect(saves).toBe(1)
		expect(table.find(p.receipts, "r1") ~= nil).toBeTruthy()
		expect(notices[#notices].text).toBe("Thank you. 25 gems added.")
		-- Roblox sends the same receipt again: granted, and not paid twice
		expect(Store.processReceipt(receipt("r1"))).toBe(GRANTED)
		expect(p.gems).toBe(30)
		expect(#notices).toBe(1)
		-- a second purchase pays again
		expect(Store.processReceipt(receipt("r2"))).toBe(GRANTED)
		expect(p.gems).toBe(55)
	end)

	it("says not yet when the save fails, the save isn't in, or the product isn't ours", function()
		reset()
		local p = profiles[owner]
		p.gems, p.receipts = 0, {}
		saveOk = false
		expect(Store.processReceipt(receipt("r3"))).toBe(NOT_YET)
		expect(saves >= 1).toBeTruthy()
		-- Roblox asks again once the save works: granted, with no second payment
		saveOk = true
		expect(Store.processReceipt(receipt("r3"))).toBe(GRANTED)
		expect(p.gems).toBe(25)
		-- somebody whose save isn't in, or who left
		local before = p.gems
		expect(Store.processReceipt({ PlayerId = 2, ProductId = PACK_ID, PurchaseId = "r4" })).toBe(NOT_YET)
		expect(Store.processReceipt({ PlayerId = 77, ProductId = PACK_ID, PurchaseId = "r5" })).toBe(NOT_YET)
		-- a product the game doesn't sell (and junk)
		expect(Store.processReceipt(receipt("r6", 424242))).toBe(NOT_YET)
		expect(Store.processReceipt(nil)).toBe(NOT_YET)
		expect(p.gems).toBe(before)
	end)

	it("keeps only the latest purchase ids", function()
		reset()
		local p = profiles[owner]
		p.gems, p.receipts = 0, {}
		for i = 1, Tuning.Store.Receipts + 10 do
			Store.processReceipt(receipt("k" .. i))
		end
		expect(#p.receipts).toBe(Tuning.Store.Receipts)
		expect(p.receipts[#p.receipts]).toBe("k" .. (Tuning.Store.Receipts + 10))
		expect(table.find(p.receipts, "k1")).toBe(nil)
		expect(p.gems).toBe(25 * (Tuning.Store.Receipts + 10))
	end)

	it("works out the pay boost from the passes and the group", function()
		reset()
		local p = profiles[owner]
		p.passes = {}
		expect(Store.payBoost(owner)).toBe(1)
		p.passes = { doublepay = true }
		expect(Store.payBoost(owner)).toBe(2)
		p.passes = { vip = true }
		expect(math.abs(Store.payBoost(owner) - (1 + Tuning.Passes.VipPay)) < 1e-9).toBeTruthy()
		p.passes = { doublepay = true, vip = true }
		owner.attributes.InGroup = true
		local want = 2 * (1 + Tuning.Passes.VipPay) * (1 + Tuning.Group.PayBonus)
		expect(math.abs(Store.payBoost(owner) - want) < 1e-9).toBeTruthy()
		-- nobody's save: no passes, so the group alone
		stranger.attributes.InGroup = true
		expect(math.abs(Store.payBoost(stranger) - (1 + Tuning.Group.PayBonus)) < 1e-9).toBeTruthy()
		stranger.attributes = {}
		p.passes = {}
	end)

	it("pays the time away once on arriving, and the welcome back says so once", function()
		reset()
		local p = profiles[owner]
		p.passes = {}
		local coins = p.coins
		-- back after three hours
		seen[owner] = os.time() - 3 * 3600
		Store.arrive(owner, p)
		local want = Offline.earnings(p, 3 * 3600, 1, os.time()).coins
		expect(want > 0).toBeTruthy()
		expect(math.abs(p.coins - coins - want) <= 1).toBeTruthy()
		expect(#logs).toBe(1)
		local info = remotes.WelcomeBack.OnServerInvoke(owner)
		expect(type(info)).toBe("table")
		expect(math.abs(info.coins - want) <= 1).toBeTruthy()
		expect(info.workers).toBe(1)
		expect(remotes.WelcomeBack.OnServerInvoke(owner)).toBe(nil)
		-- with Double Pay it comes to twice as much
		reset()
		studio = false
		owns[IDS.doublepay] = true
		coins = p.coins
		Store.arrive(owner, p)
		local doubled = Offline.earnings(p, 3 * 3600, 2, os.time()).coins
		expect(math.abs(p.coins - coins - doubled) <= 2).toBeTruthy()
		expect(math.abs(doubled - want * 2) <= 2).toBeTruthy()
		remotes.WelcomeBack.OnServerInvoke(owner)
		-- a first visit, and a quick rejoin: nothing
		reset()
		for _, s in { 0, os.time() - 60 } do
			seen[owner] = s
			coins = p.coins
			Store.arrive(owner, p)
			expect(p.coins).toBe(coins)
			expect(remotes.WelcomeBack.OnServerInvoke(owner)).toBe(nil)
		end
		expect(#logs).toBe(0)
		seen[owner] = 0
	end)

	it("knows a member of the group when there is one, and pays its gems once", function()
		reset()
		local p = profiles[owner]
		p.achieved = {}
		p.gems = 0
		Store.arrive(owner, p)
		expect(owner.attributes.InGroup).toBe(false)
		local ok, why = remotes.GroupClaim.OnServerInvoke(owner)
		expect(ok).toBe(false)
		expect(why).toBe("The town's group isn't open yet.")
		-- a group, and the player in it
		Tuning.Group.Id = 4242
		owner.member = true
		Store.arrive(owner, p)
		expect(owner.attributes.InGroup).toBe(true)
		ok = remotes.GroupClaim.OnServerInvoke(owner)
		expect(ok).toBe(true)
		expect(p.gems).toBe(Tuning.GemRewards.Group)
		expect(pushed("achieved")).toBeTruthy()
		ok, why = remotes.GroupClaim.OnServerInvoke(owner)
		expect(ok).toBe(false)
		expect(why).toBe("You've had the group's gems already.")
		expect(p.gems).toBe(Tuning.GemRewards.Group)
		Tuning.Group.Id = 0
	end)

	it("answers the playtime and achievement claims from the save alone", function()
		reset()
		local p = profiles[owner]
		p.gems, p.achieved = 0, {}
		local today = math.floor(os.time() / 86400)
		p.playtime = { day = today, secs = 0, got = 0 }
		-- not played long enough: nothing
		local ok, why = remotes.PlaytimeClaim.OnServerInvoke(owner, 1)
		expect(ok).toBe(false)
		expect(why).toBe("Not yet.")
		p.playtime.secs = Playtime.steps[1].minutes * 60
		ok = remotes.PlaytimeClaim.OnServerInvoke(owner, 1)
		expect(ok).toBe(true)
		expect(p.gems).toBe(Playtime.steps[1].gems)
		-- twice, or junk: nothing more
		expect((remotes.PlaytimeClaim.OnServerInvoke(owner, 1))).toBe(false)
		expect((remotes.PlaytimeClaim.OnServerInvoke(owner, "1"))).toBe(false)
		expect((remotes.PlaytimeClaim.OnServerInvoke(owner, 0 / 0))).toBe(false)
		expect(p.gems).toBe(Playtime.steps[1].gems)
		-- the first villager is there: that achievement pays once
		local before = p.gems
		ok = remotes.AchievementClaim.OnServerInvoke(owner, "villager1")
		expect(ok).toBe(true)
		expect(p.gems > before).toBeTruthy()
		expect((remotes.AchievementClaim.OnServerInvoke(owner, "villager1"))).toBe(false)
		-- not done yet, made up, or not a word at all
		expect((remotes.AchievementClaim.OnServerInvoke(owner, "villager16"))).toBe(false)
		expect((remotes.AchievementClaim.OnServerInvoke(owner, "nope"))).toBe(false)
		expect((remotes.AchievementClaim.OnServerInvoke(owner, { "villager5" }))).toBe(false)
		-- nobody's save: nothing
		expect((remotes.AchievementClaim.OnServerInvoke(stranger, "villager1"))).toBe(false)
		expect((remotes.PlaytimeClaim.OnServerInvoke(stranger))).toBe(false)
	end)

	it("puts the ids back", function()
		for _, pass in PassData.list do
			pass.id = oldIds[pass.key]
		end
		for _, pack in PassData.packs do
			pack.id = oldPack[pack.key]
		end
		expect(true).toBeTruthy()
	end)
end)
