--!nocheck
-- Runs the talk card end to end under Lune: the client's real UI/TalkCard, Hud and EventCard on
-- fake Roblox instances (tests/sim/client.luau sets that up), with the server's side of a talk
-- stood in for here. The server tells the client a villager spoke (the "Talk" remote), the card
-- opens, and its answers and every way it closes are tried. Then events: one nobody watches
-- (only the small prompt, nothing slides in) and one that is watched (the scene, a second and a
-- third villager joining, the one talking lit, an answer sent).
--   lune run tests/sim/talk_card.luau          (from the repository root)

local process = require("@lune/process")
local roblox = require("@lune/roblox")
local Sim = require("./client")

local Vector3, Color3 = roblox.Vector3, roblox.Color3
local Harness, Fake, gui, errors = Sim.Harness, Sim.Fake, Sim.gui, Sim.errors
local frames, advance, press, check, run = Sim.frames, Sim.advance, Sim.press, Sim.check, Sim.run

local Tuning = Harness.require("ReplicatedStorage.Shared.Config.Tuning")
local Schema = Harness.require("ReplicatedStorage.Shared.Sim.Schema")
local Appearance = Harness.require("ReplicatedStorage.Shared.Avatar.Appearance")
local Rng = Harness.require("ReplicatedStorage.Shared.Util.Rng")
local K = Tuning.Talk

-- the town, as the client knows it -------------------------------------------------------------------

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
	stats = {
		events = 0,
		fed = 0,
		made = 2,
		earned = 0,
		paydays = 0,
		wishes = 0,
		hearts = 0,
		couples = 0,
		partners = 0,
	},
	goals = {},
	found = {},
	offers = {},
})
frames(2)

-- the player and the villagers, standing in the world
local function body(name, parent, at)
	local model = Fake.new("Model", parent)
	model.Name = name
	local root = Fake.new("Part", model)
	root.Name = "HumanoidRootPart"
	root.Position = at
	return model, root
end
local me, myRoot = body("Tester", Sim.ws, Vector3.new(0, 3, 0))
Sim.player.Character = me
local folder = Fake.new("Folder", Sim.ws:FindFirstChild("Plots"):FindFirstChild("Plot1"))
folder.Name = "Villagers"
local models = {}
for i, vid in order do
	local model = body(villagers[vid].name, folder, Vector3.new(5, 3, i * 3))
	model:SetAttribute("Vid", vid)
	models[vid] = model
end

-- the server's side of a talk
local asked, busy, count = {}, false, 0
Sim.remoteFn("VillagerTalk").OnServerInvoke = function(_, vid, bye)
	table.insert(asked, { vid = vid, bye = bye })
	if bye then
		return true
	end
	if busy then
		return false, "They're busy right now."
	end
	count += 1
	return true, { vid = vid, text = "Line " .. count, note = "Note " .. count, model = models[vid] }
end
local function heldE(vid, text)
	Sim.remoteEvent("Talk")
		:FireClient(Sim.player, { vid = vid, text = text or "Hello there.", note = "A note.", model = models[vid] })
	frames(2)
end

local Hud = Harness.require(Sim.CLIENT .. "UI.Hud")
Hud.start()
local TalkCard = Harness.require(Sim.CLIENT .. "UI.TalkCard")
TalkCard.start()
frames(3)
advance(2)

local function card()
	local found = gui:FindFirstChild("TalkCard")
	return if found and Fake.shown(found) then found else nil
end
local function words(name)
	local c = card()
	local label = c and c:FindFirstChild(name, true)
	return label and label.Text
end

-- the scenario ---------------------------------------------------------------------------------------------

run("holding E on your own villager", function()
	check(card() == nil and not TalkCard.isOpen(), "no card to begin with")
	heldE("v1", "Hi! Isn't today great?")
	local c = card()
	check(c ~= nil and TalkCard.isOpen(), "the talk card opens")
	local speaker = c and c:FindFirstChild("Speaker", true)
	check(speaker ~= nil and speaker:FindFirstChild("Text", true).Text == "Mara", "her name is on its tab")
	check(words("Line") == "Hi! Isn't today great?", "what she said is on it")
	check(words("Note") == "A note.", "and what the chat did")
	for _, name in { "Chat", "Profile", "Bye" } do
		check(#Sim.buttons(function(b)
			return b.Name == name and b:IsDescendantOf(c)
		end) == 1, "it has the answer " .. name)
	end
	heldE("v1", "Oh good, it's you!")
	check(card() == c, "holding E again keeps the same card")
	check(words("Line") == "Oh good, it's you!", "with her new words on it")
	heldE("v2")
	check(card() ~= nil and card() ~= c, "another villager gets a card of their own")
	check(card():FindFirstChild("Speaker", true):FindFirstChild("Text", true).Text == "Tobin", "in his name")
	check(#gui:GetChildren() > 0 and #Fake.find(gui, function(d)
		return d.Name == "TalkCard"
	end) == 1, "and the old one is gone")
end)

run("the answers", function()
	heldE("v1")
	press("Chat")
	check(asked[#asked].vid == "v1" and not asked[#asked].bye, "Chat asks the server for one more line")
	check(words("Line") == "Line " .. count and words("Note") == "Note " .. count, "and shows it")
	busy = true
	local line = words("Line")
	press("Chat")
	check(words("Line") == line, "a villager who can't answer keeps their last words up")
	check(words("Note") == "They're busy right now.", "and the reason shows under them")
	busy = false
	local calls = #asked
	press("Bye")
	check(card() == nil and not TalkCard.isOpen(), "Bye closes the card")
	check(#asked == calls + 1 and asked[#asked].bye == true, "and tells the server to let them go")
	heldE("v2")
	press("Profile")
	frames(3)
	check(card() == nil, "Profile closes the card")
	check(asked[#asked].vid == "v2" and asked[#asked].bye == true, "and lets them go")
	local Residents = Hud.panel("Residents")
	check(Residents.isOpen(), "the Villagers menu opens")
	local stage = gui:FindFirstChild("Stage", true)
	local named = stage and Fake.find(stage, function(d)
		return d:IsA("TextLabel") and d.Text == "Tobin"
	end)
	check(named ~= nil and #named > 0, "on the villager you were talking to")
	heldE("v1")
	check(card() == nil, "no card opens over a menu")
	Hud.closeAll()
	frames(2)
	heldE("v1")
	check(card() ~= nil, "it opens again once the menu is shut")
end)

run("every other way it closes", function()
	heldE("v1")
	Hud.open("CityPanel")
	advance(0.5)
	check(card() == nil, "a menu opening closes it")
	Hud.closeAll()
	frames(2)

	heldE("v1")
	myRoot.Position = Vector3.new(K.Range + 30, 3, 0)
	advance(0.5)
	check(card() == nil, "walking off closes it")
	myRoot.Position = Vector3.new(0, 3, 0)

	heldE("v1")
	advance(K.StaySeconds - 3)
	check(card() ~= nil, "it waits for an answer")
	advance(4)
	check(card() == nil, "but not for ever")

	heldE("v1")
	models.v1.Parent = nil
	advance(0.5)
	check(card() == nil, "the villager going away closes it")
	models.v1.Parent = folder

	heldE("v1")
	Sim.BuildMode.enter()
	advance(1)
	check(card() == nil, "Build mode closes it")
	Sim.BuildMode.exit()
	advance(1)
end)

run("an event has the spot", function()
	heldE("v1")
	check(card() ~= nil, "the card is up")
	Sim.remoteEvent("EventShow"):FireClient(Sim.player, {
		token = "e1",
		title = "A parcel",
		names = {},
		lines = { { text = "A parcel came for Mara." } },
	})
	frames(2)
	check(card() == nil, "an event starting closes it")
	local event = gui:FindFirstChild("EventCard")
	check(event ~= nil and Fake.shown(event), "and the event is told in its place")
	heldE("v1")
	check(card() == nil, "no talk card opens over an event")
	Sim.remoteEvent("EventEnd"):FireClient(Sim.player, { token = "e1", notices = {} })
	advance(8)
	check(not Fake.shown(event), "the event ends")
	heldE("v1")
	check(card() ~= nil, "and you can talk again")
	press("Bye")
end)

-- events ---------------------------------------------------------------------------------------------------

local chosen = {}
Sim.remoteFn("EventChoose").OnServerInvoke = function(_, token, i)
	table.insert(chosen, { token = token, i = i })
	return true
end
local function scene()
	local found = gui:FindFirstChild("EventScene")
	return if found and Fake.shown(found) then found else nil
end
local function prompt()
	local found = gui:FindFirstChild("EventCard")
	return if found and Fake.shown(found) then found else nil
end
local function words(root, name)
	local label = root and root:FindFirstChild(name, true)
	return label and label.Text
end
local function quarrel(token)
	return {
		token = token,
		title = "A quarrel by the fountain",
		names = { a = "Mara", b = "Tobin", c = "Ivy" },
		actors = { a = "v1", b = "v2", c = "v3" },
		lines = {
			{ text = "Mara is pacing by the fountain." },
			{ who = "b", text = "I only took one bun." },
			{ who = "c", text = "You took three. I counted." },
		},
		choices = { { text = "Side with Mara" }, { text = "Side with Tobin" } },
	}
end

run("an event nobody watches", function()
	local warned = #errors
	Sim.remoteEvent("EventShow"):FireClient(Sim.player, quarrel("e2"))
	frames(2)
	check(prompt() ~= nil, "a small prompt comes up")
	check(words(prompt(), "Title") == "A quarrel by the fountain", "with the event's name")
	check(scene() == nil, "and nothing slides in")
	check(Sim.State.data.talking ~= true, "the main screen keeps its place")
	advance(14)
	check(scene() == nil, "still nothing while the lines are said")
	check(words(prompt(), "Sub") == "They want your say", "the prompt says when they want your say")
	check(prompt():FindFirstChild("Watch").Text:find("Answer") ~= nil, "Watch turns into Answer")
	check(prompt():FindFirstChild("TimeLeft").Visible, "with the time left running down")
	check(#chosen == 0, "and nothing is answered for you here")
	Hud.open("CityPanel")
	advance(0.5)
	check(prompt() == nil, "a menu opening hides the prompt")
	Hud.closeAll()
	advance(0.5)
	check(prompt() ~= nil, "and it comes back when the menu shuts")
	Sim.remoteEvent("EventLine"):FireClient(Sim.player, { token = "e2", lines = { { text = "They shook hands." } } })
	Sim.remoteEvent("EventEnd"):FireClient(Sim.player, { token = "e2", notices = {} })
	advance(8)
	check(prompt() == nil, "the prompt goes when it ends")
	check(scene() == nil and Sim.State.data.talking ~= true, "and the scene never went up")
	check(#errors == warned, "no warnings from any of it")
end)

run("an event you watch", function()
	local warned = #errors
	Sim.remoteEvent("EventShow"):FireClient(Sim.player, quarrel("e3"))
	frames(2)
	press("Watch")
	local s = scene()
	check(s ~= nil, "Watch puts the scene up")
	check(prompt() == nil, "in place of the prompt")
	check(Sim.State.data.talking == true, "and the main screen steps aside")
	check(s and s:FindFirstChild("Bust_a", true) ~= nil, "the villager in the line slides in")
	local said = (words(s, "Line") or ""):gsub("<[^>]+>", "")
	check(said == "Mara is pacing by the fountain.", "the line being said now is typed")
	check((words(s, "Line") or ""):find('<font color="#F07A3A">Mara</font>', 1, true) ~= nil, "her name in colour")
	check(s and not s:FindFirstChild("Speaker", true).Visible, "a line nobody says has no name up")
	advance(3)
	local a, b = s:FindFirstChild("Bust_a", true), s:FindFirstChild("Bust_b", true)
	check(b ~= nil, "a second villager joins when they speak")
	local function lit(bust)
		local fig = bust and bust:FindFirstChild("Avatar")
		return fig ~= nil and fig.ImageColor3 == Color3.new(1, 1, 1)
	end
	check(lit(b) and not lit(a), "whoever is talking is lit, the other dimmed")
	check(
		a and b and a.Position.X.Scale < 0.5 and b.Position.X.Scale > 0.5,
		"the first at the left, the second at the right"
	)
	check(words(s:FindFirstChild("Other", true), "Text") == "Tobin", "his name on the tag at the right")
	advance(3)
	local c = s:FindFirstChild("Bust_c", true)
	check(c ~= nil, "a third villager joins")
	check(lit(c) and not lit(b) and not lit(a), "and the light moves to her")
	check(c and c.Position.X.Scale > 0.2 and c.Position.X.Scale < 0.8, "further in toward the middle")
	advance(5)
	check(s:FindFirstChild("Choice1", true) ~= nil, "the answers come up in the scene")
	press("Choice2")
	check(#chosen == 1 and chosen[1].token == "e3" and chosen[1].i == 2, "an answer goes to the server")
	check(s:FindFirstChild("Choice1", true) == nil, "and the answers go")
	Sim.remoteEvent("EventLine")
		:FireClient(Sim.player, { token = "e3", lines = { { who = "b", text = "Fine. Sorry." } } })
	advance(1)
	check(words(s, "Line"):find("Fine") ~= nil, "the lines after the answer are said in the scene")
	press("Stop watching")
	check(scene() == nil and prompt() ~= nil, "Stop puts the scene away and leaves the prompt")
	check(Sim.State.data.talking == false, "and the main screen comes back")
	Sim.remoteEvent("EventEnd"):FireClient(Sim.player, { token = "e3", notices = {} })
	advance(8)
	check(prompt() == nil, "the prompt goes when it ends")
	check(#errors == warned, "no warnings from any of it")
end)

run("junk from the server", function()
	Sim.remoteEvent("Talk"):FireClient(Sim.player, nil)
	Sim.remoteEvent("Talk"):FireClient(Sim.player, { vid = 7, text = "x" })
	Sim.remoteEvent("Talk"):FireClient(Sim.player, { vid = "v1" })
	Sim.remoteEvent("Talk"):FireClient(Sim.player, { vid = "nobody", text = "Who?" })
	frames(2)
	check(card() == nil, "opens nothing")
	check(#errors == 0, "no warnings from any of it")
end)

print(
	string.format(
		"\ntalk card sim: %s (%d warnings)",
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
