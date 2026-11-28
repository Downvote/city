--!nocheck
-- Holding E on a villager, as the server sees it. The user: "allow the option to interact/chat
-- with villagers by holding e on them". Two parts are run for real here:
--   the prompt (Npc.talkPrompt) on Lune's own instances, so its property names are checked
--   the Villagers service with its neighbours stubbed and a clock this spec winds on: a villager
--   who is talked to stops, faces whoever asked and says something; their owner gets the talk
--   card and the day's few chats, a visitor only the words; the villager is let go when the time
--   is up, the player walks off or says bye, and never while an event has them.

local Shared = "ReplicatedStorage.Shared."
local Services = "ServerScriptService.Server.Services."
local Tuning = require(Shared .. "Config.Tuning")
local Schema = require(Shared .. "Sim.Schema")
local Appearance = require(Shared .. "Avatar.Appearance")
local StarterHouse = require(Shared .. "Data.StarterHouse")
local Rng = require(Shared .. "Util.Rng")
local Talk = require(Shared .. "Sim.Talk")
local Town = require(Shared .. "Data.Town")

local K = Tuning.Talk
local env = Harness.env()
local game = Harness.game()

-- the prompt -------------------------------------------------------------------------------------

local oldPlayers = game:GetService("Players")
Harness.addService("PathfindingService", {})
Harness.addService("TweenService", {})
local Npc = require("ServerScriptService.Server.Npc.Npc")

describe("Talk prompt", function()
	it("is a hold E prompt on the body's root part, in the villager's name", function()
		local root = Instance.new("Part")
		local body = setmetatable({ root = root, talkable = true, sleeping = false }, Npc)
		local prompt = body:talkPrompt("Mara")
		expect(prompt.ClassName).toBe("ProximityPrompt")
		expect(prompt.Parent).toBe(root)
		expect(prompt.ActionText).toBe("Talk")
		expect(prompt.ObjectText).toBe("Mara")
		expect(prompt.KeyboardKeyCode).toBe(Enum.KeyCode.E)
		expect(prompt.HoldDuration).toBeNear(K.HoldSeconds)
		expect(prompt.HoldDuration > 0).toBeTruthy()
		expect(prompt.MaxActivationDistance).toBeNear(K.Distance)
		expect(prompt.RequiresLineOfSight).toBe(false)
		expect(prompt.Enabled).toBe(true)
		-- the client's Hud opens a panel for any prompt that carries Opens: this one must not
		expect(prompt:GetAttribute("Opens")).toBe(nil)
		-- you can walk off further than the prompt reaches before the talk is over
		expect(K.Range > K.Distance).toBeTruthy()
		-- and a held key answers no faster than it can be held
		expect(K.Cooldown <= K.HoldSeconds).toBeTruthy()
	end)

	it("goes off while they sleep or something else has them, and a new one replaces the old", function()
		local root = Instance.new("Part")
		local body = setmetatable({ root = root, talkable = true, sleeping = false }, Npc)
		local prompt = body:talkPrompt("Tobin")
		body:setTalkable(false)
		expect(prompt.Enabled).toBe(false)
		body:setTalkable(true)
		expect(prompt.Enabled).toBe(true)
		body.sleeping = true
		body:setTalkable(body.talkable)
		expect(prompt.Enabled).toBe(false)
		local again = body:talkPrompt("Tobin")
		expect(again.Enabled).toBe(false)
		expect(prompt.Parent).toBe(nil)
		expect(#root:GetChildren()).toBe(1)
	end)
end)

-- the service ------------------------------------------------------------------------------------

-- a clock this spec winds on, and tasks that wait on it
local now = 5000
local sleeping, ours, errors = {}, setmetatable({}, { __mode = "k" }), {}
local function resume(co, ...)
	local ok, err = coroutine.resume(co, ...)
	if not ok then
		table.insert(errors, tostring(err) .. "\n" .. debug.traceback(co))
	end
end
local function start(f, ...)
	local co = coroutine.create(f)
	ours[co] = true
	resume(co, ...)
	return co
end
local realTask, realOs = env.task, env.os
env.task = {
	spawn = start,
	defer = start,
	delay = function(t, f, ...)
		local co = coroutine.create(f)
		ours[co] = true
		table.insert(sleeping, { co = co, at = now + (t or 0), args = { ... } })
		return co
	end,
	wait = function(t)
		local co = coroutine.running()
		if ours[co] then
			table.insert(sleeping, { co = co, at = now + (t or 0.03) })
			coroutine.yield()
		end
		return t or 0.03
	end,
	cancel = function() end,
}
env.os = setmetatable({
	clock = function()
		return now
	end,
	time = function()
		return math.floor(now)
	end,
}, { __index = os })
local function advance(seconds)
	for _ = 1, math.floor(seconds * 10 + 0.5) do
		now += 0.1
		local due = {}
		for i = #sleeping, 1, -1 do
			if sleeping[i].at <= now then
				table.insert(due, 1, table.remove(sleeping, i))
			end
		end
		for _, e in due do
			if coroutine.status(e.co) == "suspended" then
				resume(e.co, table.unpack(e.args or {}))
			end
		end
	end
end

-- the town: three villagers in the starter house
local profile = Schema.newProfile()
profile.plan = StarterHouse.plan()
for i, name in { "Mara", "Tobin", "Ivy" } do
	local input = Schema.cleanVillagerInput({ name = name, pers = "sunny", app = Appearance.default() })
	profile.villagers["v" .. i] = Schema.newVillager("v" .. i, input, Rng.new(i))
	table.insert(profile.order, "v" .. i)
end

local function person(name, id)
	local root = { Position = Vector3.new(0, 3, 0) }
	function root.IsA(_, class)
		return class == "BasePart"
	end
	local p = { Name = name, UserId = id, Parent = game, root = root }
	p.Character = {
		FindFirstChild = function(_, child)
			return if child == "HumanoidRootPart" then root else nil
		end,
	}
	function p.SetAttribute() end
	return p
end
local owner = person("Owner", 1)
local visitor = person("Visitor", 2)

-- bodies that remember what they were told to do
local bodies = {}
local fakeNpc = {}
fakeNpc.__index = fakeNpc
function fakeNpc.new(model, vid)
	local self = setmetatable({
		model = model,
		vid = vid,
		pos = Vector3.new(4, 3, 0),
		sleeping = false,
		seat = nil,
		canTalk = true,
		said = {},
		walks = 0,
		halts = 0,
		icons = {},
		gestures = {},
		triggered = Harness.signal(),
	}, fakeNpc)
	bodies[vid] = self
	return self
end
function fakeNpc:position()
	return self.pos
end
function fakeNpc:walkTo()
	self.walks += 1
	return true
end
function fakeNpc:halt()
	self.halts += 1
end
function fakeNpc:face(point)
	self.faced = point
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
function fakeNpc:setTalkable(on)
	self.canTalk = on
end
function fakeNpc:talkPrompt(name)
	self.promptName = name
	return { Triggered = self.triggered }
end
function fakeNpc:destroy()
	self.model.Parent = nil
end
for _, name in { "setName", "play", "stop", "standUp", "sleep", "sit", "claim" } do
	fakeNpc[name] = function() end
end
function fakeNpc.useSeat() end

local notices, pushes, fired, remotes = {}, {}, {}, {}
local leaving = Harness.signal()
Harness.addService("Players", {
	PlayerRemoving = leaving,
	GetPlayers = function()
		return { owner, visitor }
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
local stubbed = { "Data", "Plots", "Build", "World", "Avatar" }
Harness.stub(Services .. "Data", {
	get = function(player)
		return if player == owner then profile else nil
	end,
	notify = function(_, text)
		table.insert(notices, text)
	end,
	push = function(_, ...)
		table.insert(pushes, { ... })
	end,
	addCoins = function() end,
	log = function() end,
})
local folder = {}
Harness.stub(Services .. "Plots", {
	Ready = Harness.signal(),
	indexOf = function(player)
		return if player == owner then 1 else nil
	end,
	villagerFolder = function()
		return folder
	end,
	buildFolder = function()
		return nil
	end,
})
Harness.stub(Services .. "Build", { Changed = Harness.signal() })
-- late evening, so nobody is at work and the villagers only potter about
Harness.stub(Services .. "World", {
	ClockChanged = { Event = Harness.signal() },
	NewDay = { Event = Harness.signal() },
	dayIndex = function()
		return 12
	end,
	hour = function()
		return 23
	end,
	-- a snowy winter's evening, for what they say about the season and the weather
	calendar = function()
		return { s = 4, d = 3, y = 1 }
	end,
	weather = function()
		return "snow"
	end,
})
Harness.stub(Services .. "Avatar", {
	buildModel = function()
		local model = {}
		function model.PivotTo() end
		function model.FindFirstChild()
			return nil
		end
		function model.SetAttribute() end
		function model.Destroy() end
		return model
	end,
})
Harness.stub("ServerScriptService.Server.Npc.Npc", fakeNpc)
Harness.stub(Shared .. "Net.Remotes", {
	event = function(name)
		return {
			FireClient = function(_, player, msg)
				table.insert(fired, { name = name, to = player, msg = msg })
			end,
		}
	end,
	fn = function(name)
		remotes[name] = remotes[name] or {}
		return remotes[name]
	end,
})
Harness.stub(Services .. "Villagers", nil)
local Villagers = require(Services .. "Villagers")
Villagers.start()
advance(3) -- everyone walks in

-- only this spec's copy of the service keeps the stand-ins and the wound clock
env.task, env.os = realTask, realOs
for _, name in stubbed do
	Harness.stub(Services .. name, nil)
end
Harness.stub("ServerScriptService.Server.Npc.Npc", nil)
Harness.stub(Shared .. "Net.Remotes", nil)
Harness.stub(Services .. "Villagers", nil)
Harness.addService("Players", oldPlayers)

local function holdE(who, vid)
	bodies[vid].triggered:Fire(who)
end
local function ask(who, vid, bye)
	return remotes.VillagerTalk.OnServerInvoke(who, vid, bye)
end
local function cards()
	local list = {}
	for _, f in fired do
		if f.name == "Talk" then
			table.insert(list, f)
		end
	end
	return list
end
-- puts everyone back where a test starts from: by their villagers, free, a new day's chats
local function reset()
	advance(K.StaySeconds + 2)
	owner.root.Position = Vector3.new(0, 3, 0)
	visitor.root.Position = Vector3.new(0, 3, 0)
	for vid, v in profile.villagers do
		v.chatDay, v.chats, v.wish = nil, nil, nil
		bodies[vid].sleeping = false
		Villagers.setControl(owner, vid, nil)
	end
	table.clear(fired)
	table.clear(notices)
	table.clear(pushes)
end

describe("Talk service", function()
	it("gives every villager a prompt in their name", function()
		for vid, v in profile.villagers do
			expect(bodies[vid] ~= nil).toBeTruthy()
			expect(bodies[vid].promptName).toBe(v.name)
			expect(bodies[vid].canTalk).toBe(true)
		end
	end)

	it("stops them, turns them to their owner and opens the talk card", function()
		reset()
		local body, v = bodies.v1, profile.villagers.v1
		local said, walks = #body.said, body.walks
		holdE(owner, "v1")
		expect(Villagers.control(owner, "v1")).toBe("talk")
		expect(#body.said).toBe(said + 1)
		expect(body.faced).toBe(owner.root.Position)
		local shown = cards()
		expect(#shown).toBe(1)
		expect(shown[1].to).toBe(owner)
		expect(shown[1].msg.vid).toBe("v1")
		expect(shown[1].msg.text).toBe(body.said[#body.said])
		expect(shown[1].msg.model).toBe(body.model)
		expect(type(shown[1].msg.note)).toBe("string")
		-- the chat counted: a heart point, a little mood, and the interface is told
		expect(v.chats).toBe(1)
		expect(v.chatDay).toBe(12)
		expect(v.hxp).toBe(K.ChatHearts)
		expect(#pushes > 0).toBeTruthy()
		expect(body.icons[#body.icons]).toBe("heart")
		-- they wait for an answer and don't wander off meanwhile
		advance(K.StaySeconds - 2)
		expect(Villagers.control(owner, "v1")).toBe("talk")
		expect(body.walks).toBe(walks)
		-- kept waiting too long, they go back to their day
		advance(4)
		expect(Villagers.control(owner, "v1")).toBe(nil)
		advance(20)
		expect(body.walks > walks).toBeTruthy()
	end)

	it("answers Chat with something else, and stays for it", function()
		reset()
		local body = bodies.v1
		holdE(owner, "v1")
		local first = body.said[#body.said]
		advance(K.StaySeconds - 5)
		local ok, more = ask(owner, "v1")
		expect(ok).toBe(true)
		expect(more.vid).toBe("v1")
		expect(more.text ~= first).toBeTruthy()
		expect(more.text).toBe(body.said[#body.said])
		expect(profile.villagers.v1.chats).toBe(2)
		-- the wait starts again from the new line
		advance(K.StaySeconds - 5)
		expect(Villagers.control(owner, "v1")).toBe("talk")
		advance(8)
		expect(Villagers.control(owner, "v1")).toBe(nil)
	end)

	it("still answers after the day's chats, with nothing more gained", function()
		reset()
		local v = profile.villagers.v2
		for _ = 1, K.ChatsPerDay do
			holdE(owner, "v2")
			advance(1)
		end
		expect(v.chats).toBe(K.ChatsPerDay)
		local hxp, heart, mood, coins = v.hxp, v.heart, v.mood, profile.coins
		table.clear(pushes)
		for _ = 1, 30 do
			local ok, more = ask(owner, "v2")
			expect(ok).toBe(true)
			expect(type(more.text)).toBe("string")
			advance(1)
		end
		expect(v.chats).toBe(K.ChatsPerDay)
		expect(v.hxp).toBe(hxp)
		expect(v.heart).toBe(heart)
		expect(v.mood).toBe(mood)
		expect(profile.coins).toBe(coins)
		expect(#pushes).toBe(0)
	end)

	it("doesn't answer faster than the key can be held", function()
		reset()
		holdE(owner, "v1")
		local ok, why = ask(owner, "v1")
		expect(ok).toBe(false)
		expect(why).toBe(nil)
		expect(profile.villagers.v1.chats).toBe(1)
		expect(#bodies.v1.said > 0).toBeTruthy()
	end)

	it("lets a visitor chat, for the words alone", function()
		reset()
		local body, v = bodies.v3, profile.villagers.v3
		local before = { v.hxp, v.mood, profile.coins }
		local said = #body.said
		holdE(visitor, "v3")
		expect(#body.said).toBe(said + 1)
		expect(body.faced).toBe(visitor.root.Position)
		expect(Villagers.control(owner, "v3")).toBe("talk")
		expect(#cards()).toBe(0)
		expect(v.chats).toBe(nil)
		expect({ v.hxp, v.mood, profile.coins }).toEqual(before)
		expect(#pushes).toBe(0)
		-- they don't keep a visitor's villager standing about for long
		advance(K.VisitorSeconds + 1)
		expect(Villagers.control(owner, "v3")).toBe(nil)
		-- and the card's remote is for your own villagers
		local ok = ask(visitor, "v3")
		expect(ok).toBe(false)
	end)

	-- the user: "Create dialogue for villagers interacting with players that arent their mayor"
	it("talks to a visitor as a guest, by their own name, a few times a day in each town", function()
		reset()
		local GuestTalk = require(Shared .. "Sim.GuestTalk")
		visitor.DisplayName = "Sam"
		local body = bodies.v2
		local lines = {}
		for _, list in GuestTalk.Lines.sunny do
			for _, text in list do
				lines[GuestTalk.fill(profile, text, { name = "Sam", town = "", home = "" })] = true
			end
		end
		local said = #body.said
		holdE(visitor, "v2")
		expect(#body.said).toBe(said + 1)
		local text = body.said[#body.said]
		-- a guest's line (a hello), with their name in, and nobody called "the Sam"
		expect(text:find("Sam", 1, true) ~= nil).toBe(true)
		expect(text:find("the Sam", 1, true)).toBe(nil)
		local mine = false
		for line in lines do
			local Voice = require(Shared .. "Sim.Voice")
			mine = mine or Voice.speak("sunny", line) == text
		end
		expect(mine).toBe(true)
		-- past the day's cap in this town the villager has things to do, and doesn't stop
		for _ = 1, Tuning.Guests.ChatsPerDay + 2 do
			advance(K.VisitorSeconds + 1)
			holdE(visitor, "v2")
		end
		advance(K.VisitorSeconds + 1)
		local before = #body.said
		holdE(visitor, "v2")
		expect(#body.said).toBe(before + 1)
		expect(Villagers.control(owner, "v2")).toBe(nil)
		expect(body.said[#body.said]:lower():find("promised", 1, true) ~= nil).toBe(true)
		-- the owner still chats as ever
		holdE(owner, "v2")
		expect(Villagers.control(owner, "v2")).toBe("talk")
		visitor.DisplayName = nil
	end)

	it("needs you to stand by them", function()
		reset()
		local body = bodies.v1
		local said = #body.said
		owner.root.Position = Vector3.new(K.Range + 5, 3, 0) + Vector3.new(4, 0, 0)
		holdE(owner, "v1")
		local ok, why = ask(owner, "v1")
		expect(ok).toBe(false)
		expect(type(why)).toBe("string")
		expect(#body.said).toBe(said)
		expect(Villagers.control(owner, "v1")).toBe(nil)
		expect(profile.villagers.v1.chats).toBe(nil)
	end)

	it("lets them go when you walk off, or say bye", function()
		reset()
		holdE(owner, "v1")
		owner.root.Position = Vector3.new(200, 3, 0)
		advance(1)
		expect(Villagers.control(owner, "v1")).toBe(nil)
		reset()
		holdE(owner, "v2")
		expect(Villagers.control(owner, "v2")).toBe("talk")
		expect(ask(owner, "v2", true)).toBe(true)
		expect(Villagers.control(owner, "v2")).toBe(nil)
		-- bye to someone you aren't talking to does nothing
		Villagers.setControl(owner, "v3", "event")
		expect(ask(owner, "v3", true)).toBe(true)
		expect(Villagers.control(owner, "v3")).toBe("event")
	end)

	-- the user: "allow players to click on villagers anywhere to either open their profile or chat
	-- with them"
	it("starts a chat from a click anywhere on your own plot, and ends it when you walk off", function()
		reset()
		local body = bodies.v1
		local said = #body.said
		-- far from them, but on the plot
		local spot = Town.plotFrame(1) * CFrame.new(200, 3, 200)
		owner.root.Position = spot.Position
		expect((owner.root.Position - body:position()).Magnitude > K.Range).toBeTruthy()
		-- (holding E from out here is still too far)
		expect((ask(owner, "v1"))).toBe(false)
		local ok, card = ask(owner, "v1", "click")
		expect(ok).toBe(true)
		expect(card.vid).toBe("v1")
		expect(card.far).toBe(true)
		expect(#body.said).toBe(said + 1)
		expect(Villagers.control(owner, "v1")).toBe("talk")
		expect(profile.villagers.v1.chats).toBe(1)
		-- Chat goes on from where they stand, a step or two is fine
		owner.root.Position = spot.Position + Vector3.new(3, 0, 0)
		advance(1)
		local more, again = ask(owner, "v1")
		expect(more).toBe(true)
		expect(type(again.text)).toBe("string")
		-- walking off from there ends it, and they can't be talked to from afar any more
		owner.root.Position = spot.Position + Vector3.new(K.Range + 4, 0, 0)
		advance(1)
		expect(Villagers.control(owner, "v1")).toBe(nil)
		expect((ask(owner, "v1"))).toBe(false)
		-- off the plot it is refused, and a visitor can't start one
		reset()
		owner.root.Position = (Town.plotFrame(1) * CFrame.new(-200, 3, 200)).Position
		local off, why = ask(owner, "v1", "click")
		expect(off).toBe(false)
		expect(type(why)).toBe("string")
		expect(Villagers.control(owner, "v1")).toBe(nil)
		visitor.root.Position = spot.Position
		local theirs = remotes.VillagerTalk.OnServerInvoke(visitor, "v1", "click")
		expect(theirs).toBe(false)
		expect(Villagers.control(owner, "v1")).toBe(nil)
		-- and bye ends one at once
		owner.root.Position = spot.Position
		expect((ask(owner, "v2", "click"))).toBe(true)
		expect(ask(owner, "v2", true)).toBe(true)
		expect(Villagers.control(owner, "v2")).toBe(nil)
	end)

	it("leaves a villager alone in an event, away or asleep", function()
		reset()
		local body = bodies.v3
		local said = #body.said
		for _, mode in { "event", "away" } do
			Villagers.setControl(owner, "v3", mode)
			body.model.Parent = folder -- (an outing takes the body out of the world; not the point here)
			expect(body.canTalk).toBe(false)
			holdE(owner, "v3")
			local ok, why = ask(owner, "v3")
			expect(ok).toBe(false)
			expect(type(why)).toBe("string")
			expect(Villagers.control(owner, "v3")).toBe(mode)
		end
		Villagers.setControl(owner, "v3", nil)
		body.model.Parent = folder
		expect(body.canTalk).toBe(true)
		body.sleeping = true
		holdE(owner, "v3")
		expect(#body.said).toBe(said)
		expect(#cards()).toBe(0)
		expect(profile.villagers.v3.chats).toBe(nil)
	end)

	it("hands them over when an event starts mid talk", function()
		reset()
		holdE(owner, "v2")
		Villagers.setControl(owner, "v2", "event")
		advance(K.StaySeconds + 5)
		expect(Villagers.control(owner, "v2")).toBe("event")
		Villagers.setControl(owner, "v2", nil)
	end)

	it("answers a wish for a talk", function()
		reset()
		local v = profile.villagers.v1
		v.wish = { kind = "cheer", untilT = now + 1e6 }
		local coins = profile.coins
		holdE(owner, "v1")
		expect(v.wish).toBe(nil)
		expect(profile.coins > coins).toBeTruthy()
		expect(#notices > 0).toBeTruthy()
		expect(#cards()).toBe(1)
	end)

	it("talks about the season and the weather out there", function()
		reset()
		local body = bodies.v2
		profile.villagers.v2.mood = 60
		holdE(owner, "v2")
		local heard = {}
		-- (over several town days: a day holds only so many chats, and the season comes up among
		-- many other topics, so one day's handful could miss it by chance)
		for i = 1, 400 do
			local ok, more = ask(owner, "v2")
			if ok then
				heard[more.text] = true
			end
			advance(if i % 40 == 0 then Tuning.Day.Length else 1)
		end
		-- something about winter or the snow (Sim/Talk's lines for them)
		local wintry = false
		for _, list in { Talk.Shared.SEASON[4], Talk.Shared.WEATHER.snow } do
			for _, text in list do
				wintry = wintry or heard[text] == true
			end
		end
		expect(wintry).toBe(true)
		expect(#body.said > 0).toBeTruthy()
	end)

	it("turns away junk from the card's remote", function()
		reset()
		expect((ask(owner, 42))).toBe(false)
		expect((ask(owner, nil))).toBe(false)
		expect((ask(owner, "nobody"))).toBe(false)
		expect((ask(owner, "nobody", true))).toBe(true)
		expect((ask(owner, { "v1" }))).toBe(false)
	end)

	it("tidies up when the owner leaves mid talk", function()
		reset()
		holdE(owner, "v1")
		owner.Parent = nil
		leaving:Fire(owner)
		advance(K.StaySeconds + 5)
		expect(Villagers.get(owner, "v1")).toBe(nil)
		expect(Villagers.control(owner, "v1")).toBe(nil)
	end)

	it("ran without a single error in the background", function()
		for _, e in errors do
			print(e)
		end
		expect(#errors).toBe(0)
	end)
end)
