--!nocheck
-- A watched event moves only when the player says so. The user: "sometimes, chats suddenly cut to
-- the next dialogue without the player input". The client's real UI/EventCard, Dialogue, TalkCard
-- and Hud run on fake Roblox instances (tests/sim/client.luau), with the server's side played
-- here: it says its lines at its own pace, asks, says what follows, ends. First nobody presses
-- anything, however long the server goes on: the first line stays, the question never comes up,
-- nothing is answered. Then a key, a tap and a click take it one line a press to the question
-- (the time to answer starts only then, and the server is told), lines said meanwhile wait their
-- turn, how it turned out stays until a click, and the last click closes it. A new event that
-- comes while one is on screen waits its turn; the talk card doesn't move on by itself either; a
-- creator an answer asks for waits for the scene to close.
--   lune run tests/sim/event_pace.luau          (from the repository root)

local process = require("@lune/process")
local roblox = require("@lune/roblox")
local Sim = require("./client")

local Vector3, Enum = roblox.Vector3, roblox.Enum
local Harness, Fake, gui, errors = Sim.Harness, Sim.Fake, Sim.gui, Sim.errors
local frames, advance, press, check, run = Sim.frames, Sim.advance, Sim.press, Sim.check, Sim.run

local Tuning = Harness.require("ReplicatedStorage.Shared.Config.Tuning")
local Schema = Harness.require("ReplicatedStorage.Shared.Sim.Schema")
local Appearance = Harness.require("ReplicatedStorage.Shared.Avatar.Appearance")
local Rng = Harness.require("ReplicatedStorage.Shared.Util.Rng")
local CHOICE = Tuning.Events.ChoiceTimeout

-- the keys: ContextActionService keeps what is bound, so a key press can be played to it (before
-- the dialogue scene is loaded, so it takes this one)
local bound = {}
Harness.addService("ContextActionService", {
	BindAction = function() end,
	BindActionAtPriority = function(_, name, fn, _touch, priority, ...)
		bound[name] = { fn = fn, priority = priority, keys = { ... } }
	end,
	UnbindAction = function(_, name)
		bound[name] = nil
	end,
})

-- the town, as the client knows it
local villagers, order = {}, {}
for i, name in { "Mara", "Tobin", "Ivy" } do
	local input = Schema.cleanVillagerInput({ name = name, pers = "sunny", app = Appearance.default() })
	local v = Schema.newVillager("v" .. i, input, Rng.new(i))
	villagers[v.id] = v
	table.insert(order, v.id)
end
Sim.remoteEvent("State"):FireClient(Sim.player, {
	coins = 500,
	villagers = villagers,
	order = order,
	daily = { last = -5, streak = 0 },
	log = {},
	rel = {},
	stats = { events = 0, fed = 0, made = 2, earned = 0, paydays = 0, wishes = 0, hearts = 0 },
	goals = {},
	found = {},
	offers = {},
})
frames(2)
local function body(name, parent, at)
	local model = Fake.new("Model", parent)
	model.Name = name
	local root = Fake.new("Part", model)
	root.Name = "HumanoidRootPart"
	root.Position = at
	return model
end
Sim.player.Character = body("Tester", Sim.ws, Vector3.new(0, 3, 0))
local folder = Fake.new("Folder", Sim.ws:FindFirstChild("Plots"):FindFirstChild("Plot1"))
folder.Name = "Villagers"
local models = {}
for i, vid in order do
	local model = body(villagers[vid].name, folder, Vector3.new(5, 3, i * 3))
	model:SetAttribute("Vid", vid)
	models[vid] = model
end

local Hud = Harness.require(Sim.CLIENT .. "UI.Hud")
Hud.start()
local TalkCard = Harness.require(Sim.CLIENT .. "UI.TalkCard")
TalkCard.start()
local Dialogue = Harness.require(Sim.CLIENT .. "UI.Dialogue")
frames(3)
advance(2)

-- the server's side ---------------------------------------------------------------------------------------

local chosen, watched = {}, {}
Sim.remoteFn("EventChoose").OnServerInvoke = function(_, token, i)
	table.insert(chosen, { token = token, i = i })
	return true
end
Sim.remoteEvent("EventWatch").OnServerEvent:Connect(function(_, token, what)
	table.insert(watched, { token = token, what = what })
end)
Sim.remoteFn("VillagerTalk").OnServerInvoke = function()
	return true
end
local function told(token, what)
	for _, w in watched do
		if w.token == token and w.what == what then
			return true
		end
	end
	return false
end
local function show(ev)
	Sim.remoteEvent("EventShow"):FireClient(Sim.player, ev)
	frames(2)
end
local function line(token, l, last)
	Sim.remoteEvent("EventLine"):FireClient(Sim.player, { token = token, line = table.clone(l), last = last })
	frames(2)
end
local function ask(token, left)
	Sim.remoteEvent("EventLine"):FireClient(Sim.player, { token = token, ask = true, left = left })
	frames(2)
end
local function finish(token, notices)
	Sim.remoteEvent("EventEnd"):FireClient(Sim.player, { token = token, notices = notices or {} })
	frames(2)
end

-- what is on screen ----------------------------------------------------------------------------------------

local function scene()
	local found = gui:FindFirstChild("EventScene")
	return if found and Fake.shown(found) then found else nil
end
local function prompt()
	local found = gui:FindFirstChild("EventCard")
	return if found and Fake.shown(found) then found else nil
end
local function find(name)
	local s = scene()
	return s and s:FindFirstChild(name, true)
end
local function said()
	local label = find("Line")
	return ((label and label.Text) or ""):gsub("<[^>]+>", "")
end
local function typed()
	local label = find("Line")
	return label ~= nil and label.MaxVisibleGraphemes == -1
end
local function arrow()
	local more = find("More")
	return more ~= nil and Fake.shown(more)
end
local function answers()
	return find("Choice1") ~= nil
end
local function bar()
	local box = find("Box")
	local track = box and box:FindFirstChild("TimeLeft")
	return if track and track.Visible then track:FindFirstChild("Fill").Size.X.Scale else nil
end

-- the player ------------------------------------------------------------------------------------------------

local function key(code)
	local action = bound[Dialogue.Action]
	if not action then
		return nil
	end
	local result = action.fn(
		Dialogue.Action,
		Enum.UserInputState.Begin,
		{ KeyCode = code, UserInputState = Enum.UserInputState.Begin }
	)
	action.fn(Dialogue.Action, Enum.UserInputState.End, { KeyCode = code, UserInputState = Enum.UserInputState.End })
	frames(3)
	return result
end
local function touch(kind)
	local box = find("Box")
	if box then
		box.InputBegan:Fire({ UserInputType = kind })
	end
	frames(3)
end
local function click()
	touch(Enum.UserInputType.MouseButton1)
end
local function tap()
	touch(Enum.UserInputType.Touch)
end
-- a second or so at the game's own pace: a line being typed is all there by then
local function settle()
	advance(1)
	frames(60)
end

local LINES = {
	{ text = "Mara is pacing by the fountain." },
	{ who = "b", text = "I only took one bun." },
	{ who = "c", text = "You took three. I counted." },
	{ who = "a", text = "Can someone settle this before I scream?" },
}
local function quarrel(token, choices)
	return {
		token = token,
		title = "A quarrel by the fountain",
		names = { a = "Mara", b = "Tobin", c = "Ivy" },
		actors = { a = "v1", b = "v2", c = "v3" },
		lines = LINES,
		choices = if choices == false then nil else { { text = "Side with Mara" }, { text = "Side with Tobin" } },
	}
end

-- the scenario -----------------------------------------------------------------------------------------------

run("nobody presses anything", function()
	local warned = #errors
	show(quarrel("p1"))
	line("p1", LINES[1])
	press("Watch")
	settle()
	check(scene() ~= nil, "Watch puts the scene up")
	check(told("p1", "open"), "and tells the server it is up")
	check(said() == LINES[1].text and typed(), "the first line is typed out")
	check(arrow(), "with the arrow at the corner once it is all there")
	-- the server says the rest at its own pace and asks, and the player does nothing at all
	for i = 2, #LINES do
		line("p1", LINES[i])
		advance(3)
	end
	ask("p1", CHOICE)
	advance(CHOICE * 3)
	check(said() == LINES[1].text, "a long while later the first line is still up")
	check(find("Bust_b") == nil and find("Bust_c") == nil, "nobody who comes in later has come in")
	check(not answers() and bar() == nil, "no answers and no time running down")
	check(not told("p1", "asked") and #chosen == 0, "nothing told to the server, nothing answered")
	check(arrow(), "the arrow still says a press goes on")
	check(#errors == warned, "no warnings from any of it")
end)

run("a press a line, by key, tap and click", function()
	local warned = #errors
	local action = bound[Dialogue.Action]
	check(action ~= nil, "the scene holds the keys while it is up")
	local keys = action and action.keys or {}
	check(
		table.find(keys, Enum.KeyCode.Space) ~= nil
			and table.find(keys, Enum.KeyCode.Return) ~= nil
			and table.find(keys, Enum.KeyCode.ButtonA) ~= nil,
		"Space, Enter and a gamepad's A"
	)
	check(action and action.priority == Enum.ContextActionPriority.High.Value, "over the character's own (no jump)")
	check(key(Enum.KeyCode.Space) == Enum.ContextActionResult.Sink, "Space is taken")
	check(said() == LINES[2].text, "and goes on to the next line")
	check(find("Bust_b") ~= nil, "bringing in who says it")
	check(not typed(), "which is typed out")
	key(Enum.KeyCode.Space)
	check(typed() and said() == LINES[2].text, "a press while it is typed shows the rest of it")
	check(arrow(), "and the arrow comes up")
	key(Enum.KeyCode.Return)
	check(said() == LINES[3].text, "Enter goes on too")
	settle()
	tap()
	check(said() == LINES[4].text, "and a tap")
	settle()
	check(not answers(), "the question waits for the player to get to it")
	click()
	check(said() == "What do you do?", "a click and the question is up")
	check(answers(), "with its answers")
	check(not arrow(), "and no arrow over them")
	check(told("p1", "asked"), "the server is told the question is on screen")
	check(bar() ~= nil and bar() > 0.99, "and the time to answer starts from full")
	check(key(Enum.KeyCode.Space) == Enum.ContextActionResult.Pass, "the keys are handed back over the answers")
	check(said() == "What do you do?", "and do nothing to them")
	-- the server tells how long is left; the bar follows it
	Sim.remoteEvent("EventLine"):FireClient(Sim.player, { token = "p1", left = 30 })
	advance(1)
	local b = bar()
	check(b ~= nil and math.abs(b - 29 / CHOICE) < 0.03, "the bar runs down from the time the server gives")
	advance(10)
	check(answers() and said() == "What do you do?", "the answers stay while there is time")
	press("Choice2")
	check(#chosen == 1 and chosen[1].token == "p1" and chosen[1].i == 2, "an answer goes to the server")
	check(not answers() and bar() == nil, "and the answers and the time go")
	-- what they say to it: the first the moment it comes, the rest in turn
	line("p1", { who = "b", text = "Fine. Sorry, Ivy." })
	line("p1", { who = "c", text = "Thank you." }, true)
	check(said() == "Fine. Sorry, Ivy.", "the first line after the answer shows when it comes")
	finish("p1", { "Tobin and Ivy made up." })
	advance(CHOICE)
	check(said() == "Fine. Sorry, Ivy.", "the next waits for a press, even once the event is over")
	click()
	click()
	check(said() == "Thank you.", "a press, the next")
	click()
	click()
	check(said() == "Tobin and Ivy made up.", "how it turned out")
	advance(60)
	check(scene() ~= nil and said() == "Tobin and Ivy made up.", "stays until a click")
	check(prompt() == nil, "with no prompt behind it")
	click()
	click()
	check(scene() == nil, "the last click closes it")
	check(told("p1", "close"), "and the server is told")
	check(bound[Dialogue.Action] == nil, "the keys go back to the character")
	check(Sim.State.data.talking == false, "and the main screen comes back")
	advance(2)
	check(prompt() == nil, "and the prompt doesn't come back for it")
	check(#errors == warned, "no warnings from any of it")
end)

run("an event that comes while one is on screen waits its turn", function()
	local warned = #errors
	local first = quarrel("p2", false)
	first.title = "Buns again"
	show(first)
	line("p2", LINES[1])
	press("Watch")
	settle()
	local s = scene()
	local second = quarrel("p3", false)
	second.title = "A kite in the tree"
	second.lines = { { text = "Tobin's kite is stuck in the oak." }, { who = "b", text = "Can anyone reach it?" } }
	show(second)
	line("p3", second.lines[1])
	line("p2", LINES[2], true)
	line("p3", second.lines[2], true)
	advance(5)
	check(scene() == s and said() == LINES[1].text, "the scene on screen stays as it was")
	check(find("Note").Text == "Buns again", "on the event it is about")
	check(prompt() == nil, "and the new one's prompt doesn't come up over it")
	finish("p3", {})
	finish("p2", {})
	advance(5)
	click()
	check(said() == LINES[2].text, "the first event's next line")
	advance(30)
	check(scene() == s, "and it stays")
	click()
	click()
	check(scene() == nil, "its last line closed it")
	settle()
	check(prompt() == nil, "the one that ended meanwhile never takes the screen")

	-- one still going when the scene is closed comes up then
	local third = quarrel("p4", false)
	show(third)
	line("p4", LINES[1])
	local fourth = quarrel("p5", false)
	fourth.title = second.title
	fourth.lines = second.lines
	show(fourth)
	line("p5", second.lines[1])
	press("Watch")
	settle()
	check(said() == LINES[1].text, "watching the first")
	finish("p4", {})
	settle()
	click()
	click()
	check(scene() == nil, "closed")
	settle()
	local p = prompt()
	check(
		p ~= nil and p:FindFirstChild("Title", true).Text == "A kite in the tree",
		"the next one's prompt comes up then"
	)
	press("Watch")
	settle()
	check(said() == second.lines[1].text, "and plays from its first line, said while it waited")
	press("Stop watching")
	finish("p5", {})
	advance(2)
	check(scene() == nil and prompt() == nil, "it all goes when it ends")
	check(#errors == warned, "no warnings from any of it")
end)

run("the talk card doesn't move on by itself", function()
	local warned = #errors
	Sim.remoteEvent("Talk")
		:FireClient(Sim.player, { vid = "v1", text = "Have you tried the new bakery?", model = models.v1 })
	frames(2)
	local card = gui:FindFirstChild("TalkCard")
	local function words()
		local label = card and card:FindFirstChild("Line", true)
		return label and label.Text
	end
	check(card ~= nil and Fake.shown(card), "the talk card is up")
	settle()
	show(quarrel("p6", false))
	line("p6", LINES[1])
	advance(Tuning.Talk.StaySeconds - 8)
	check(Fake.shown(card) and words() == "Have you tried the new bakery?", "a long while later it says the same")
	check(TalkCard.isOpen(), "though an event started meanwhile")
	check(prompt() == nil, "whose prompt waits")
	press("Bye")
	settle()
	check(prompt() ~= nil, "and comes up once the card has gone")
	finish("p6", {})
	advance(2)
	check(prompt() == nil, "then goes when it ends")
	check(#errors == warned, "no warnings from any of it")
end)

run("a creator an answer asks for waits for the scene", function()
	local warned = #errors
	local opened = {}
	local open = Hud.open
	Hud.open = function(name, arg)
		table.insert(opened, { name = name, arg = arg })
	end
	show(quarrel("p7", false))
	line("p7", LINES[1], true)
	press("Watch")
	settle()
	Sim.remoteEvent("Notify"):FireClient(Sim.player, "open:creator:v1", "action")
	advance(5)
	check(#opened == 0 and scene() ~= nil, "the scene stays up and the creator waits")
	click()
	check(scene() == nil, "closed")
	settle()
	check(#opened == 1 and opened[1].name == "Creator" and opened[1].arg.vid == "v1", "then the creator opens")
	Hud.open = open
	finish("p7", {})
	advance(2)
	check(#errors == warned, "no warnings from any of it")
end)

print(
	string.format(
		"\nevent pace sim: %s (%d warnings)",
		if Sim.failures() == 0 then "all passed" else Sim.failures() .. " failed",
		#errors
	)
)
for _, e in errors do
	print("  warning: " .. e)
end
if Sim.failures() > 0 then
	process.exit(1)
end
