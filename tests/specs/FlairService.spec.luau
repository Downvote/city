--!nocheck
-- Buying a villager their flair with gems, as the server sees it. The user: "make it such that
-- villagers could have a custom saying, thing they add to the end of their sentances sometimes,
-- custom thing they like the most which they will mention ... players can also buy the before
-- mentioned customization for villagers ... with gems, as another currency". The Villagers service
-- is run for real here with its neighbours stubbed (the way WishService.spec does it): the
-- VillagerFlair remote checks what was typed, runs it through the filter, charges the price in gems
-- the first time and for every change, refuses in plain words (not enough gems, odd text, filtered
-- text, the same again) without taking anything, takes one off for free, and takes nothing a client
-- sends on trust.

local Shared = "ReplicatedStorage.Shared."
local Services = "ServerScriptService.Server.Services."
local Tuning = require(Shared .. "Config.Tuning")
local Schema = require(Shared .. "Sim.Schema")
local Flair = require(Shared .. "Sim.Flair")
local Voice = require(Shared .. "Sim.Voice")
local Appearance = require(Shared .. "Avatar.Appearance")
local StarterHouse = require(Shared .. "Data.StarterHouse")
local RealRemotes = require(Shared .. "Net.Remotes")
local Rng = require(Shared .. "Util.Rng")

local F = Tuning.Flair
local env = Harness.env()
local game = Harness.game()

-- the town: two villagers in the starter house
local profile = Schema.newProfile()
profile.plan = StarterHouse.plan()
for i, name in { "Mara", "Tobin" } do
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
	local self = setmetatable({ model = model, vid = vid, said = {}, icons = {} }, fakeNpc)
	bodies[vid] = self
	return self
end
function fakeNpc:say(text)
	-- (as Npc.say does: in their own hand, with their ending)
	table.insert(self.said, Voice.speak(rawget(self, "pers"), text, rawget(self, "ending")))
end
function fakeNpc:icon(kind)
	table.insert(self.icons, kind)
end
function fakeNpc:talkPrompt()
	return { Triggered = Harness.signal() }
end
function fakeNpc:position()
	return Vector3.new(4, 3, 0)
end
function fakeNpc.useSeat() end

-- what the text filter does to what it is sent (set by each test), and how often it was asked
local filter = function(text)
	return text
end
local filtered = 0

-- Tasks run at once and waits don't wait; the clock is ours, so the one second between two
-- requests can be stepped over
-- (a task that keeps waiting, the wages' loop, is parked for good after a few rounds)
local realTask, realOs = env.task, env.os
local clock = 1000
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
env.os = setmetatable({
	clock = function()
		return clock
	end,
}, { __index = realOs or os })

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
		function model.FindFirstChildOfClass()
			return nil
		end
		function model:SetAttribute(key, value)
			self.attributes[key] = value
		end
		function model.Destroy() end
		return model
	end,
	filterText = function(_player, text)
		filtered += 1
		return filter(text)
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
Villagers.brain = function() end
Villagers.start()

-- only this spec's copy of the service keeps the stand-ins
env.task, env.os = realTask, realOs
for _, name in stubbed do
	Harness.stub(Services .. name, nil)
end
Harness.stub("ServerScriptService.Server.Npc.Npc", nil)
Harness.stub(Shared .. "Net.Remotes", nil)
Harness.stub(Services .. "Villagers", nil)
Harness.addService("Players", oldPlayers)

local function set(who, ...)
	clock += 2 -- (a while after the last one)
	return remotes.VillagerFlair.OnServerInvoke(who, ...)
end

local function reset(gems)
	profile.gems = gems
	for vid, v in profile.villagers do
		v.flair = nil
		table.clear(bodies[vid].said)
		table.clear(bodies[vid].icons)
		bodies[vid].ending = nil
	end
	table.clear(notices)
	table.clear(pushes)
	filtered = 0
	filter = function(text)
		return text
	end
end

local function pushed(key)
	for _, p in pushes do
		if p.to == owner and table.find(p.keys, key) then
			return true
		end
	end
	return false
end

describe("Flair service", function()
	it("has a remote for it, and prices in gems, a few apiece", function()
		expect(table.find(RealRemotes.Functions, "VillagerFlair") ~= nil).toBe(true)
		expect(type(remotes.VillagerFlair.OnServerInvoke)).toBe("function")
		for _, kind in Flair.Kinds do
			local price = Flair.price(kind)
			-- rare: more than nothing, never more than a usual day of play brings
			expect(price >= 1 and price <= Tuning.GemRewards.DayMax).toBe(true)
		end
	end)

	it("sets a catchphrase for its price, filtered, and they try it out", function()
		reset(20)
		filter = function(text)
			return text .. "" -- (the filter's answer, which is what is kept)
		end
		local ok, message = set(owner, "v1", "phrase", "  smells like   rain to me ")
		expect(ok).toBe(true)
		expect(message).toBe("Mara has it now. It cost " .. F.Prices.phrase .. " gems.")
		expect(filtered).toBe(1)
		expect(profile.gems).toBe(20 - F.Prices.phrase)
		-- tidied into a sentence
		expect(profile.villagers.v1.flair.phrase).toBe("Smells like rain to me.")
		expect(pushed("villagers") and pushed("gems")).toBe(true)
		-- they say it straight away
		expect(bodies.v1.said[1]).toBe(Voice.speak("sunny", "Smells like rain to me."))
		-- each change costs again; the same again costs nothing and is refused
		local same, why = set(owner, "v1", "phrase", "Smells like rain to me.")
		expect(same).toBe(false)
		expect(why).toBe("That's what they have already.")
		expect(profile.gems).toBe(20 - F.Prices.phrase)
		expect(set(owner, "v1", "phrase", "Never trust a gull.")).toBe(true)
		expect(profile.gems).toBe(20 - 2 * F.Prices.phrase)
		expect(profile.villagers.v1.flair.phrase).toBe("Never trust a gull.")
	end)

	it("puts the ending on their body, so what they say over their head ends that way too", function()
		reset(20)
		expect(set(owner, "v2", "ending", "buddy!!")).toBe(true)
		expect(profile.villagers.v2.flair.ending).toBe("buddy")
		expect(bodies.v2.ending).toBe("buddy")
		expect(profile.gems).toBe(20 - F.Prices.ending)
		expect(set(owner, "v2", "thing", "old maps")).toBe(true)
		expect(profile.villagers.v2.flair.thing).toBe("old maps")
		expect(profile.gems).toBe(20 - F.Prices.ending - F.Prices.thing)
		-- taking one off is free
		local before = profile.gems
		expect(set(owner, "v2", "ending", false)).toBe(true)
		expect(profile.villagers.v2.flair.ending).toBe(nil)
		expect(rawget(bodies.v2, "ending")).toBe(nil)
		expect(profile.gems).toBe(before)
		local again, why = set(owner, "v2", "ending", false)
		expect(again).toBe(false)
		expect(why).toBe("There's nothing to take off.")
	end)

	it("refuses without enough gems, before it asks the filter, and takes nothing", function()
		for _, gems in { 0, F.Prices.phrase - 1 } do
			reset(gems)
			local ok, why = set(owner, "v1", "phrase", "Smells like rain to me.")
			expect(ok).toBe(false)
			local short = F.Prices.phrase - gems
			expect(why).toBe(if short == 1 then "You need 1 more gem." else "You need " .. short .. " more gems.")
			expect(profile.gems).toBe(gems)
			expect(profile.villagers.v1.flair).toBe(nil)
			expect(filtered).toBe(0)
			expect(#bodies.v1.said).toBe(0)
		end
	end)

	it("refuses odd or empty text in plain words", function()
		reset(50)
		for _, case in
			{
				{ "phrase", "" },
				{ "phrase", "    " },
				{ "phrase", "Hi" },
				{ "phrase", "Hello {player}" },
				{ "phrase", "aaaaaaaa" },
				{ "phrase", "!!!!" },
				{ "phrase", "see www.example.com" },
				{ "phrase", string.rep("word ", 20) },
				{ "ending", "you know what I mean" },
				{ "ending", "pal. ok" },
				{ "ending", "a|b" },
				{ "thing", "Pancakes. And jam." },
				{ "thing", "<b>maps</b>" },
				{ "thing", 42 },
				{ "thing", { "maps" } },
			}
		do
			local ok, why = set(owner, "v1", case[1], case[2])
			expect(ok).toBe(false)
			expect(type(why) == "string" and #why > 0 and not why:find("{", 1, true)).toBe(true)
		end
		expect(profile.gems).toBe(50)
		expect(filtered).toBe(0)
		expect(profile.villagers.v1.flair).toBe(nil)
	end)

	it("keeps nothing the filter caught, and charges nothing when it can't ask", function()
		reset(50)
		filter = function(text)
			return (text:gsub("%a", "#"))
		end
		local ok, why = set(owner, "v1", "thing", "old maps")
		expect(ok).toBe(false)
		expect(why).toBe("That got filtered. Try something else.")
		filter = function()
			return nil
		end
		ok, why = set(owner, "v1", "thing", "old maps")
		expect(ok).toBe(false)
		expect(why).toBe("Couldn't check that just now. Try again in a moment.")
		expect(profile.gems).toBe(50)
		expect(profile.villagers.v1.flair).toBe(nil)
	end)

	it("takes nothing a client sends on trust", function()
		reset(50)
		for _, args in
			{
				{ nil, "phrase", "Hello there." },
				{ 5, "phrase", "Hello there." },
				{ "v9", "phrase", "Hello there." },
				{ "v1", "price", "Hello there." },
				{ "v1", nil, "Hello there." },
				{ "v1", "gems", 1 },
			}
		do
			local ok = set(owner, args[1], args[2], args[3])
			expect(ok).toBe(false)
		end
		-- somebody with no town loaded
		local ok, why = set(stranger, "v1", "phrase", "Hello there.")
		expect(ok).toBe(false)
		expect(why).toBe("Not ready yet.")
		expect(profile.gems).toBe(50)
		expect(filtered).toBe(0)
		-- and a flood is turned away while the filter is busy
		clock += 2
		expect(remotes.VillagerFlair.OnServerInvoke(owner, "v1", "thing", "old maps")).toBe(true)
		local ok2, why2 = remotes.VillagerFlair.OnServerInvoke(owner, "v1", "thing", "new maps")
		expect(ok2).toBe(false)
		expect(why2).toBe("One moment.")
		expect(profile.gems).toBe(50 - F.Prices.thing)
	end)
end)
