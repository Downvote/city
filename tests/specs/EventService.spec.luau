--!nocheck
-- An event's time to answer, as the server keeps it. The user: "sometimes, chats suddenly cut to
-- the next dialogue without the player input". The Events service is run for real here with its
-- neighbours stubbed and a clock this spec winds on (the way TalkService.spec does it), playing
-- "spider" (one villager, a question). With nobody watching it plays out on its own as it always
-- has: the gentle option ChoiceTimeout after it asks. Watching, the time doesn't run while the
-- owner reads up to the question; it runs from when the question reached their screen (the
-- client's EventWatch "asked"), starts again when the scene is put away, and never runs past
-- ChoiceCap whatever a client says. An answer counts only while it asks, and only once. The next
-- event waits while the owner still has the last one's scene up (ReadHold at most).

local Shared = "ReplicatedStorage.Shared."
local Services = "ServerScriptService.Server.Services."
local Tuning = require(Shared .. "Config.Tuning")
local Schema = require(Shared .. "Sim.Schema")
local Appearance = require(Shared .. "Avatar.Appearance")
local StarterHouse = require(Shared .. "Data.StarterHouse")
local Rng = require(Shared .. "Util.Rng")

local E = Tuning.Events
local env = Harness.env()
local game = Harness.game()

-- a clock this spec winds on, and tasks that wait on it
local now = 9000
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

-- the town: one villager, at home at noon
local profile = Schema.newProfile()
profile.plan = StarterHouse.plan()
do
	local input = Schema.cleanVillagerInput({ name = "Mara", pers = "sunny", app = Appearance.default() })
	profile.villagers.v1 = Schema.newVillager("v1", input, Rng.new(1))
	table.insert(profile.order, "v1")
end

local owner = { Name = "Owner", UserId = 1, Parent = game, attributes = {} }
function owner:SetAttribute(key, value)
	self.attributes[key] = value
end
local stranger = { Name = "Stranger", UserId = 2, Parent = game }

-- a body that does what it is told and remembers what it said
local folder = { Name = "Villagers" }
local body = { model = { Parent = folder }, sleeping = false, said = {} }
function body:say(text)
	table.insert(self.said, text)
end
function body:position()
	return Vector3.new(4, 3, 0)
end
for _, name in { "icon", "gesture", "standUp", "halt", "face", "walkTo" } do
	body[name] = function() end
end

local controls = {}
local listed = {} -- who the scheduler sees in the server (nobody, until the last test)
local fired, notices = {}, {}
local remoteEvents, remoteFns = {}, {}
local leaving = Harness.signal()
Harness.addService("Players", {
	PlayerRemoving = leaving,
	GetPlayers = function()
		return listed
	end,
})
local stubbed = { "Data", "Plots", "World", "Villagers" }
Harness.stub(Services .. "Data", {
	get = function(player)
		return if player == owner then profile else nil
	end,
	notify = function(_, text)
		table.insert(notices, text)
	end,
	log = function() end,
	push = function() end,
	addCoins = function() end,
})
Harness.stub(Services .. "Plots", {
	indexOf = function(player)
		return if player == owner then 1 else nil
	end,
	villagerFolder = function()
		return folder
	end,
	frame = function()
		return CFrame.new()
	end,
})
Harness.stub(Services .. "World", {
	NewDay = { Event = Harness.signal() },
	hour = function()
		return 12
	end,
	isNight = function()
		return false
	end,
	dayIndex = function()
		return 5
	end,
	calendar = function()
		return { s = 2, d = 3, y = 1 }
	end,
	weather = function()
		return "clear"
	end,
})
Harness.stub(Services .. "Villagers", {
	Met = Harness.signal(),
	Created = Harness.signal(),
	list = function()
		return { "v1" }
	end,
	get = function(_, vid)
		return if vid == "v1" then body else nil
	end,
	control = function(_, vid)
		return controls[vid]
	end,
	setControl = function(_, vid, mode)
		controls[vid] = mode
	end,
	data = function(_, vid)
		return profile.villagers[vid]
	end,
})
Harness.stub(Shared .. "Net.Remotes", {
	event = function(name)
		if not remoteEvents[name] then
			remoteEvents[name] = {
				OnServerEvent = Harness.signal(),
				FireClient = function(_, player, msg)
					table.insert(fired, { name = name, to = player, msg = msg })
				end,
			}
		end
		return remoteEvents[name]
	end,
	fn = function(name)
		remoteFns[name] = remoteFns[name] or {}
		return remoteFns[name]
	end,
})
Harness.stub(Services .. "Events", nil)
local Events = require(Services .. "Events")
Events.start()

-- only this spec's copy of the service keeps the stand-ins and the wound clock
env.task, env.os = realTask, realOs
for _, name in stubbed do
	Harness.stub(Services .. name, nil)
end
Harness.stub(Shared .. "Net.Remotes", nil)
Harness.stub(Services .. "Events", nil)

-- what the owner's client hears, from the n-th message on
local function heard(kind, from)
	local out = {}
	for i = from or 1, #fired do
		local f = fired[i]
		if f.name == kind and f.to == owner then
			table.insert(out, f.msg)
		end
	end
	return out
end
local function lastOf(kind, test)
	for i = #fired, 1, -1 do
		local f = fired[i]
		if f.name == kind and (test == nil or test(f.msg)) then
			return f.msg
		end
	end
	return nil
end
local function watch(token, what, who)
	remoteEvents.EventWatch.OnServerEvent:Fire(who or owner, token, what)
end
local function choose(token, index, who)
	return remoteFns.EventChoose.OnServerInvoke(who or owner, token, index)
end

-- Starts "spider" and plays it up to its question. Returns its token and where its messages start.
local function toQuestion(opts)
	local o = opts or {}
	expect(Events.busy(owner)).toBe(false)
	local from = #fired + 1
	expect(Events.trigger(owner, "spider")).toBe(true)
	local show = heard("EventShow", from)[1]
	expect(show ~= nil).toBeTruthy()
	local token = show.token
	if o.watch then
		watch(token, "open")
	end
	for _ = 1, 600 do
		if lastOf("EventLine", function(m)
			return m.token == token and m.ask == true
		end) then
			break
		end
		advance(0.1)
	end
	local ask = lastOf("EventLine", function(m)
		return m.token == token and m.ask == true
	end)
	expect(ask ~= nil).toBeTruthy()
	return token, from, ask
end
-- Has the event moved on past its question (the gentle option taken, or the answer given)?
local function movedOn(token, from)
	if lastOf("EventEnd", function(m)
		return m.token == token
	end) then
		return true
	end
	local asked = false
	for _, m in heard("EventLine", from) do
		if m.token == token and m.ask then
			asked = true
		elseif asked and m.token == token and m.line then
			return true
		end
	end
	return false
end
-- Lets the event play out to its end.
local function toEnd()
	for _ = 1, 600 do
		if not Events.busy(owner) then
			return
		end
		advance(0.5)
	end
end
-- the latest time to answer the client was told
local function told(token)
	local m = lastOf("EventLine", function(m)
		return m.token == token and (m.ask == true or m.left ~= nil) and m.line == nil
	end)
	return m and m.left
end

describe("Event service: the time to answer", function()
	it("with nobody watching, takes the gentle option ChoiceTimeout after it asks", function()
		local token, from, ask = toQuestion()
		expect(ask.left).toBeNear(E.ChoiceTimeout)
		advance(E.ChoiceTimeout - 2)
		expect(movedOn(token, from)).toBe(false)
		advance(2 + E.ChoiceGrace + 1)
		expect(movedOn(token, from)).toBe(true)
		toEnd()
		expect(Events.busy(owner)).toBe(false)
		expect(controls.v1).toBe(nil)
	end)

	it("holds it while the owner is still reading up to the question", function()
		local token, from, ask = toQuestion({ watch = true })
		-- watching: no time is given (it doesn't run yet)
		expect(ask.left).toBe(nil)
		advance(E.ChoiceTimeout * 2)
		expect(movedOn(token, from)).toBe(false)
		-- the question reaches their screen: the time runs from now, and the client is told
		watch(token, "asked")
		advance(0.5)
		expect(told(token)).toBeBetween(E.ChoiceTimeout - 1, E.ChoiceTimeout)
		advance(E.ChoiceTimeout - 2)
		expect(movedOn(token, from)).toBe(false)
		-- (a second "asked" gives no more time)
		watch(token, "asked")
		advance(2 + E.ChoiceGrace + 1)
		expect(movedOn(token, from)).toBe(true)
		toEnd()
	end)

	it("waits for the answer the owner gives, and plays what follows", function()
		local token, from = toQuestion({ watch = true })
		watch(token, "asked")
		advance(10)
		expect(choose(token, 1)).toBe(true)
		advance(0.5)
		expect(movedOn(token, from)).toBe(true)
		local after = lastOf("EventLine", function(m)
			return m.token == token and m.line ~= nil
		end)
		expect(after.line.text:find("cup", 1, true) ~= nil).toBeTruthy()
		toEnd()
	end)

	it("counts an answer only while it asks, and only once", function()
		local from = #fired + 1
		expect(Events.trigger(owner, "spider")).toBe(true)
		local token = heard("EventShow", from)[1].token
		-- before the question
		expect(choose(token, 1)).toBe(false)
		advance(30)
		expect(lastOf("EventLine", function(m)
			return m.token == token and m.ask == true
		end) ~= nil).toBeTruthy()
		-- junk, and somebody else
		expect(choose("nope", 1)).toBe(false)
		expect(choose(token, "1")).toBe(false)
		expect(choose(token, 99)).toBe(false)
		expect(choose(token, 0 / 0)).toBe(false)
		expect(choose(token, 1, stranger)).toBe(false)
		expect(choose(token, 2)).toBe(true)
		expect(choose(token, 1)).toBe(false)
		toEnd()
		-- and after it is all over
		expect(choose(token, 1)).toBe(false)
	end)

	it("starts the time again when the scene is put away before the question", function()
		local token, from = toQuestion({ watch = true })
		advance(100)
		expect(movedOn(token, from)).toBe(false)
		watch(token, "close")
		advance(0.5)
		expect(told(token)).toBeBetween(E.ChoiceTimeout - 1, E.ChoiceTimeout)
		advance(E.ChoiceTimeout - 2)
		expect(movedOn(token, from)).toBe(false)
		advance(2 + E.ChoiceGrace + 1)
		expect(movedOn(token, from)).toBe(true)
		toEnd()
	end)

	it("holds it again when the scene is watched again from the start", function()
		local token, from = toQuestion({ watch = true })
		watch(token, "asked")
		advance(20)
		watch(token, "close")
		watch(token, "open")
		advance(E.ChoiceTimeout + 5)
		expect(movedOn(token, from)).toBe(false)
		watch(token, "asked")
		advance(E.ChoiceTimeout - 2)
		expect(movedOn(token, from)).toBe(false)
		advance(2 + E.ChoiceGrace + 1)
		expect(movedOn(token, from)).toBe(true)
		toEnd()
	end)

	it("never waits past ChoiceCap, whatever the client says", function()
		expect(E.ChoiceCap > E.ChoiceTimeout * 2).toBeTruthy()
		local token, from = toQuestion({ watch = true })
		advance(E.ChoiceCap - E.ChoiceTimeout / 2)
		-- (the question reaches the screen late: the time left is what the cap leaves)
		watch(token, "asked")
		advance(0.5)
		expect(told(token) < E.ChoiceTimeout / 2 + 0.5).toBeTruthy()
		for _ = 1, math.ceil(E.ChoiceTimeout / 2 + E.ChoiceGrace) + 2 do
			watch(token, "open")
			advance(1)
		end
		expect(movedOn(token, from)).toBe(true)
		toEnd()
	end)

	it("turns away junk and other players' word", function()
		local token, from = toQuestion()
		watch(nil, "open")
		watch(42, "open")
		watch(token, "shut")
		watch(token, { "open" })
		watch("someone else's", "open")
		watch(token, "open", stranger)
		advance(E.ChoiceTimeout - 2)
		expect(movedOn(token, from)).toBe(false)
		advance(2 + E.ChoiceGrace + 1)
		expect(movedOn(token, from)).toBe(true)
		toEnd()
	end)

	it("says the next line at once when the watching owner has read all there is", function()
		-- the user: "sometimes, clicking on dialogue dosent advance it, lagging behind instead"
		expect(Events.busy(owner)).toBe(false)
		local from = #fired + 1
		expect(Events.trigger(owner, "spider")).toBe(true)
		local token = heard("EventShow", from)[1].token
		local function lines()
			local n = 0
			for _, m in heard("EventLine", from) do
				if m.token == token and m.line then
					n += 1
				end
			end
			return n
		end
		expect(lines()).toBe(1)
		-- nobody watching: the lines keep the town's pace
		watch(token, "next")
		advance(0.5)
		expect(lines()).toBe(1)
		-- watching, and caught up: the next line comes now, and only that one
		watch(token, "open")
		watch(token, "next")
		advance(0.3)
		expect(lines()).toBe(2)
		advance(1)
		expect(lines()).toBe(2)
		-- another player's word changes nothing
		watch(token, "next", stranger)
		advance(0.5)
		expect(lines()).toBe(2)
		watch(token, "close")
		toEnd()
		expect(Events.busy(owner)).toBe(false)
	end)

	it("starts the next event only once the owner has put the last one's scene away", function()
		local token = toQuestion({ watch = true })
		watch(token, "asked")
		expect(choose(token, 1)).toBe(true)
		toEnd()
		expect(Events.reading(owner)).toBe(true)
		-- the scheduler's own events, made "spider" here (it calls Events.trigger)
		local trigger, tries = Events.trigger, 0
		Events.trigger = function(player)
			tries += 1
			return trigger(player, "spider")
		end
		local from = #fired + 1
		listed = { owner }
		-- (the first event would come FirstDelay after the scheduler first sees them)
		expect(E.FirstDelay < E.ReadHold - 10).toBeTruthy()
		advance(E.ReadHold - 5)
		expect(tries).toBe(0)
		expect(#heard("EventShow", from)).toBe(0)
		watch(token, "close")
		expect(Events.reading(owner)).toBe(false)
		advance(5)
		expect(tries).toBe(1)
		expect(#heard("EventShow", from)).toBe(1)
		toEnd()
		-- and a scene left up holds it back only so long
		local again = heard("EventShow", from)
		local last = again[#again].token
		watch(last, "open")
		expect(Events.reading(owner)).toBe(true)
		advance(E.ReadHold + 1)
		expect(Events.reading(owner)).toBe(false)
		listed = {}
		toEnd()
		Events.trigger = trigger
	end)

	it("forgets an owner who leaves", function()
		leaving:Fire(owner)
		expect(Events.reading(owner)).toBe(false)
		expect(Events.busy(owner)).toBe(false)
	end)

	it("ran without a single error in the background", function()
		for _, e in errors do
			print(e)
		end
		expect(#errors).toBe(0)
	end)
end)
