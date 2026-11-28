--!nocheck
-- Buying a villager the food they are craving, as the server sees it. The user: "remove the shop,
-- buying of things and food and feeding. when a character gets a craving, allow the player to
-- simply pay to buy it". The Villagers service is run for real here with its neighbours stubbed
-- (the way TalkService.spec does it): the WishBuy remote takes what the craving costs
-- (Life.wishPrice) and grants the wish, refuses in plain words when there is no such wish or not
-- enough coins, and takes nothing a client sends on trust. The shop's own remotes are gone.

local Shared = "ReplicatedStorage.Shared."
local Services = "ServerScriptService.Server.Services."
local Tuning = require(Shared .. "Config.Tuning")
local Schema = require(Shared .. "Sim.Schema")
local Life = require(Shared .. "Sim.Life")
local Needs = require(Shared .. "Sim.Needs")
local Foods = require(Shared .. "Data.Foods")
local Appearance = require(Shared .. "Avatar.Appearance")
local StarterHouse = require(Shared .. "Data.StarterHouse")
local RealRemotes = require(Shared .. "Net.Remotes")
local Rng = require(Shared .. "Util.Rng")

local L = Tuning.Life
local env = Harness.env()
local game = Harness.game()

-- the town: three villagers in the starter house, the first of them the player's own
local profile = Schema.newProfile()
profile.plan = StarterHouse.plan()
for i, name in { "Mara", "Tobin", "Ivy" } do
	local input = Schema.cleanVillagerInput({ name = name, pers = "sunny", app = Appearance.default() })
	profile.villagers["v" .. i] = Schema.newVillager("v" .. i, input, Rng.new(i))
	table.insert(profile.order, "v" .. i)
end

local function person(name, id)
	local p = { Name = name, UserId = id, Parent = game, attributes = {} }
	function p:SetAttribute(key, value)
		self.attributes[key] = value
	end
	function p:GetAttribute(key)
		return self.attributes[key]
	end
	return p
end
local owner = person("Owner", 1)
local stranger = person("Stranger", 2) -- somebody with no town loaded

-- bodies that remember what they were told to do; anything else asked of one does nothing
local bodies = {}
local fakeNpc = {}
fakeNpc.__index = function(_, key)
	return fakeNpc[key] or function() end
end
function fakeNpc.new(model, vid)
	local self = setmetatable({ model = model, vid = vid, said = {}, icons = {}, gestures = {} }, fakeNpc)
	bodies[vid] = self
	return self
end
function fakeNpc:say(text)
	table.insert(self.said, text)
end
function fakeNpc:icon(kind)
	table.insert(self.icons, kind)
end
function fakeNpc:gesture(kind)
	table.insert(self.gestures, kind)
end
function fakeNpc:talkPrompt()
	return { Triggered = Harness.signal() }
end
function fakeNpc:position()
	return Vector3.new(4, 3, 0)
end
function fakeNpc.useSeat() end

-- Tasks run at once and waits don't wait: nothing here needs the clock. A task that keeps
-- waiting (a villager's day, should it ever run here) is parked for good after a few rounds.
local realTask = env.task
local waits = setmetatable({}, { __mode = "k" })
local function run(f, ...)
	coroutine.resume(coroutine.create(f), ...)
end
env.task = {
	spawn = run,
	defer = run,
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
local notices, pushes, remotes = {}, {}, {}
Harness.addService("Players", {
	PlayerRemoving = Harness.signal(),
	GetPlayers = function()
		return { owner, stranger }
	end,
})
Harness.addService("CollectionService", {
	GetTagged = function()
		return {}
	end,
	GetInstanceAddedSignal = function()
		return Harness.signal()
	end,
})
Harness.addService("PathfindingService", {})
Harness.addService("TweenService", {})
local stubbed = { "Data", "Plots", "Build", "World", "Avatar" }
Harness.stub(Services .. "Data", {
	get = function(player)
		return if player == owner then profile else nil
	end,
	notify = function(player, text, kind)
		table.insert(notices, { to = player, text = text, kind = kind })
	end,
	push = function(player, ...)
		table.insert(pushes, { to = player, keys = { ... } })
	end,
	addCoins = function()
		error("a craving is charged by Life.buyWish, on the profile")
	end,
	canAfford = function()
		error("a craving is charged by Life.buyWish, on the profile")
	end,
	log = function() end,
})
Harness.stub(Services .. "Plots", {
	Ready = Harness.signal(),
	indexOf = function(player)
		return if player == owner then 1 else nil
	end,
	villagerFolder = function()
		return {}
	end,
	buildFolder = function()
		return nil
	end,
})
Harness.stub(Services .. "Build", { Changed = Harness.signal() })
Harness.stub(Services .. "World", {
	ClockChanged = { Event = Harness.signal() },
	NewDay = { Event = Harness.signal() },
	dayIndex = function()
		return 12
	end,
	hour = function()
		return 23
	end,
})
Harness.stub(Services .. "Avatar", {
	buildModel = function()
		local model = { attributes = {} }
		function model.PivotTo() end
		function model.FindFirstChild()
			return nil
		end
		function model:SetAttribute(key, value)
			self.attributes[key] = value
		end
		function model.Destroy() end
		return model
	end,
})
Harness.stub("ServerScriptService.Server.Npc.Npc", fakeNpc)
Harness.stub(Shared .. "Net.Remotes", {
	event = function()
		return { FireClient = function() end }
	end,
	fn = function(name)
		remotes[name] = remotes[name] or {}
		return remotes[name]
	end,
})
Harness.stub(Services .. "Villagers", nil)
local Villagers = require(Services .. "Villagers")
-- their days are another spec's business: here they only stand where they are put
Villagers.brain = function() end
Villagers.start()

-- only this spec's copy of the service keeps the stand-ins
env.task = realTask
for _, name in stubbed do
	Harness.stub(Services .. name, nil)
end
Harness.stub("ServerScriptService.Server.Npc.Npc", nil)
Harness.stub(Shared .. "Net.Remotes", nil)
Harness.stub(Services .. "Villagers", nil)
Harness.addService("Players", oldPlayers)

local function buy(who, ...)
	return remotes.WishBuy.OnServerInvoke(who, ...)
end

-- a plain food that is not this villager's favourite
local function plainFood(v)
	return if v.fav == "soup" then "tart" else "soup"
end

-- puts the town back where a test starts from
local function reset(coins)
	profile.coins = coins
	profile.stats.wishes = 0
	profile.offers = {}
	for vid, v in profile.villagers do
		v.wish, v.mood, v.heart, v.hxp = nil, Tuning.Villagers.StartMood, 1, 0
		table.clear(bodies[vid].said)
		table.clear(bodies[vid].icons)
		bodies[vid].model.attributes.Wish = nil
	end
	table.clear(notices)
	table.clear(pushes)
	owner.attributes.Coins = nil
end

local function pushed(key)
	for _, p in pushes do
		if p.to == owner and table.find(p.keys, key) then
			return true
		end
	end
	return false
end

-- what one refusal must leave alone
local function untouched(coins, vid, wish)
	expect(profile.coins).toBe(coins)
	expect(profile.villagers[vid].wish).toBe(wish)
	expect(profile.stats.wishes).toBe(0)
	expect(#profile.offers).toBe(0)
	expect(#notices).toBe(0)
	expect(#bodies[vid].said).toBe(0)
	expect(owner.attributes.Coins).toBe(nil)
end

describe("Wish service", function()
	it("has a remote for buying a craving, and none for a shop or for feeding", function()
		expect(table.find(RealRemotes.Functions, "WishBuy") ~= nil).toBeTruthy()
		expect(table.find(RealRemotes.Functions, "ShopBuy")).toBe(nil)
		expect(table.find(RealRemotes.Functions, "VillagerFeed")).toBe(nil)
		expect(type(remotes.WishBuy.OnServerInvoke)).toBe("function")
		expect(remotes.ShopBuy).toBe(nil)
		expect(remotes.VillagerFeed).toBe(nil)
		expect(Villagers.feed).toBe(nil)
		-- every villager walked in
		for vid in profile.villagers do
			expect(bodies[vid] ~= nil).toBeTruthy()
		end
	end)

	it("takes the craving's price and grants it, with the hearts, the mood and a word of thanks", function()
		reset(1000)
		local v = profile.villagers.v2
		v.mood = 0 -- (low, so the lift shows under what they can reach: Sim/Needs)
		local food = Foods.get(plainFood(v))
		v.wish = { kind = "food", arg = food.id, untilT = 1e12 }
		Villagers.syncWishes(owner)
		expect(bodies.v2.model.attributes.Wish).toBe(Life.WishIcons.food)
		local price = Life.wishPrice(profile, "v2")
		expect(price).toBe(Life.cravingPrice(food.id))
		local ok, message = buy(owner, "v2")
		expect(ok).toBe(true)
		expect(message).toBe(nil)
		-- charged once, exactly the price
		expect(profile.coins).toBe(1000 - price)
		expect(owner.attributes.Coins).toBe(1000 - price)
		-- the wish is granted: gone from them and from over their head, counted, and felt
		expect(v.wish).toBe(nil)
		expect(bodies.v2.model.attributes.Wish).toBe(nil)
		expect(profile.stats.wishes).toBe(1)
		expect(v.mood).toBe(math.min(Needs.cap(profile, "v2"), Needs.lift(L.WishMood)))
		expect(v.hxp).toBe(L.WishHearts)
		-- they say so, naming what they got, and the player is told
		expect(#bodies.v2.said).toBe(1)
		expect(bodies.v2.said[1]:find(food.name, 1, true) ~= nil).toBeTruthy()
		expect(#notices >= 1).toBeTruthy()
		for _, n in notices do
			expect(n.to).toBe(owner)
			expect(n.text:find(v.name, 1, true) ~= nil).toBeTruthy()
			expect(n.text:find("{") == nil).toBeTruthy()
		end
		-- and the client hears of everything that changed, the bag of food not among it
		for _, key in { "villagers", "coins", "stats" } do
			expect(pushed(key)).toBe(true)
		end
		expect(pushed("inv")).toBe(false)
		expect(profile.inv).toBe(nil)
	end)

	it("makes more of their favourite, and pays the heart level it fills at once, with a notice", function()
		reset(1000)
		local v = profile.villagers.v3
		v.mood = 0
		v.wish = { kind = "food", arg = v.fav, untilT = 1e12 }
		v.hxp = Life.heartNeed(1) - 1
		local price = Life.wishPrice(profile, "v3")
		expect(buy(owner, "v3")).toBe(true)
		expect(profile.coins).toBe(1000 - price + (Life.heartReward(2)))
		expect(v.mood).toBe(math.min(Needs.cap(profile, "v3"), Needs.lift(L.WishMood + L.FavWishMood)))
		expect(v.mood > Needs.lift(L.WishMood)).toBeTruthy()
		expect(v.heart).toBe(2)
		expect(#profile.offers).toBe(0)
		local told = false
		for _, n in notices do
			if n.text:find("Heart level 2", 1, true) then
				told = true
			end
		end
		expect(told).toBe(true)
		expect(bodies.v3.said[1]:find("favourite", 1, true) ~= nil).toBeTruthy()
		expect(table.find(bodies.v3.icons, "heart") ~= nil).toBeTruthy()
	end)

	it("refuses without enough coins and leaves the wish open", function()
		local v = profile.villagers.v2
		local wish = { kind = "food", arg = "goldapple", untilT = 1e12 }
		local price = Life.cravingPrice("goldapple")
		for _, coins in { 0, price - 1 } do
			reset(coins)
			v.wish = wish
			local ok, message = buy(owner, "v2")
			expect(ok).toBe(false)
			expect(message).toBe("Not enough coins.")
			untouched(coins, "v2", wish)
		end
		-- exactly the price is enough, and leaves nothing
		reset(price)
		v.wish = wish
		expect(buy(owner, "v2")).toBe(true)
		expect(profile.coins).toBe(0)
	end)

	it("refuses when they aren't wishing for anything", function()
		reset(1000)
		local ok, message = buy(owner, "v2")
		expect(ok).toBe(false)
		expect(type(message) == "string" and #message > 0).toBeTruthy()
		untouched(1000, "v2", nil)
		-- and a craving can't be bought twice
		profile.villagers.v2.wish = { kind = "food", arg = "apple", untilT = 1e12 }
		expect(buy(owner, "v2")).toBe(true)
		local coins = profile.coins
		expect(buy(owner, "v2")).toBe(false)
		expect(profile.coins).toBe(coins)
		expect(profile.stats.wishes).toBe(1)
	end)

	it("refuses a wish that is not a craving, and doesn't grant it for coins", function()
		for _, wish in
			{
				{ kind = "friend", arg = "v3", untilT = 1e12 },
				{ kind = "cheer", untilT = 1e12 },
			}
		do
			reset(1000)
			profile.villagers.v2.wish = wish
			local ok, message = buy(owner, "v2")
			expect(ok).toBe(false)
			expect(type(message) == "string" and #message > 0).toBeTruthy()
			untouched(1000, "v2", wish)
		end
		-- a craving for something that is no food has no price, so it is not for sale either
		reset(1000)
		local odd = { kind = "food", arg = "medicine", untilT = 1e12 }
		profile.villagers.v2.wish = odd
		expect(buy(owner, "v2")).toBe(false)
		untouched(1000, "v2", odd)
	end)

	it("takes nothing a client sends on trust", function()
		reset(1000)
		local v = profile.villagers.v2
		local wish = { kind = "food", arg = plainFood(v), untilT = 1e12 }
		v.wish = wish
		-- not a villager's id at all
		for _, junk in { 7, true, {}, { "v2" }, 0 / 0, "", "v99", "V2", " v2", "villagers" } do
			local ok, message = buy(owner, junk)
			expect(ok).toBe(false)
			expect(type(message)).toBe("string")
			untouched(1000, "v2", wish)
		end
		local ok = buy(owner)
		expect(ok).toBe(false)
		untouched(1000, "v2", wish)
		-- somebody whose town isn't loaded, asking after another player's villager
		local okStranger, why = buy(stranger, "v2")
		expect(okStranger).toBe(false)
		expect(type(why)).toBe("string")
		untouched(1000, "v2", wish)
		expect(stranger.attributes.Coins).toBe(nil)
		-- a price, a food or a kind of wish of the client's own choosing changes nothing: the
		-- server charges its own price for the food they are really craving
		local price = Life.wishPrice(profile, "v2")
		expect(buy(owner, "v2", 0, "goldapple", "cheer", { price = 0 })).toBe(true)
		expect(profile.coins).toBe(1000 - price)
		expect(v.wish).toBe(nil)
	end)

	it("gives no coins back for a craving, whatever the heart level", function()
		for seed = 1, 40 do
			reset(500)
			local v = profile.villagers["v" .. (seed % 3 + 1)]
			local food = Foods.list[seed % #Foods.list + 1]
			v.wish = { kind = "food", arg = food.id, untilT = 1e12 }
			local price = Life.cravingPrice(food.id)
			local heartWas = v.heart or 1
			expect(buy(owner, v.id)).toBe(true)
			-- (only a heart level it brings pays, at once)
			local levelled = 0
			for level = heartWas + 1, v.heart do
				levelled += (Life.heartReward(level))
			end
			expect(profile.coins).toBe(500 - price + levelled)
			expect(price > 0).toBeTruthy()
		end
	end)
end)
