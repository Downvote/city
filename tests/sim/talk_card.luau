--!nocheck
-- Runs the talk card end to end under Lune: the client's real UI/TalkCard, Hud and EventCard on
-- fake Roblox instances (tests/sim/client.luau sets that up), with the server's side of a talk
-- stood in for here. The server tells the client a villager spoke (the "Talk" remote), the card
-- opens, and its answers and every way it closes are tried. Then events: one nobody watches
-- (only the small prompt, nothing slides in) and one that is watched (the scene, a second and a
-- third villager joining, the one talking lit, an answer sent). Then a craving, bought for the
-- villager from the talk card and from the Villagers screen, with and without the coins.
--   lune run tests/sim/talk_card.luau          (from the repository root)

local process = require("@lune/process")
local roblox = require("@lune/roblox")
local Sim = require("./client")

local Vector3, Color3, Enum = roblox.Vector3, roblox.Color3, roblox.Enum
local Harness, Fake, gui, errors = Sim.Harness, Sim.Fake, Sim.gui, Sim.errors
local frames, advance, press, check, run = Sim.frames, Sim.advance, Sim.press, Sim.check, Sim.run

local Tuning = Harness.require("ReplicatedStorage.Shared.Config.Tuning")
local Text = Harness.require("ReplicatedStorage.Shared.Util.Text")
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
-- What the server does as it plays an event: says each line (and the client hears it then), then
-- asks for an answer.
local function line(token, l)
	Sim.remoteEvent("EventLine"):FireClient(Sim.player, { token = token, line = l })
	frames(2)
end
local function askNow(token)
	Sim.remoteEvent("EventLine"):FireClient(Sim.player, { token = token, ask = true })
	frames(2)
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
	local ev = quarrel("e2")
	Sim.remoteEvent("EventShow"):FireClient(Sim.player, ev)
	frames(2)
	check(prompt() ~= nil, "a small prompt comes up")
	check(words(prompt(), "Title") == "A quarrel by the fountain", "with the event's name")
	check(scene() == nil, "and nothing slides in")
	check(Sim.State.data.talking ~= true, "the main screen keeps its place")
	for _, l in ev.lines do
		line("e2", l)
		advance(3)
	end
	askNow("e2")
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
	line("e2", { text = "They shook hands." })
	Sim.remoteEvent("EventEnd"):FireClient(Sim.player, { token = "e2", notices = {} })
	advance(8)
	check(prompt() == nil, "the prompt goes when it ends")
	check(scene() == nil and Sim.State.data.talking ~= true, "and the scene never went up")
	check(#errors == warned, "no warnings from any of it")
end)

run("an event you watch", function()
	local warned = #errors
	-- the event names the villager it is about, as the server does
	local ev = quarrel("e3")
	ev.focus = Sim.env.workspace:FindFirstChild("Mara", true)
	Sim.remoteEvent("EventShow"):FireClient(Sim.player, ev)
	line("e3", ev.lines[1])
	local cam = Sim.cam
	local camType, camAt = cam.CameraType, cam.CFrame
	press("Watch")
	local s = scene()
	check(s ~= nil, "Watch puts the scene up")
	-- the user: "no need for the camera to jump after clicking on watch, just make the characters
	-- appear and the dialogue speech appears"
	frames(20)
	check(cam.CameraType == camType and cam.CFrame == camAt, "and the camera stays where the player had it")
	check(prompt() == nil, "in place of the prompt")
	check(Sim.State.data.talking == true, "and the main screen steps aside")
	check(s and s:FindFirstChild("Bust_a", true) ~= nil, "the villager in the line slides in")
	local said = (words(s, "Line") or ""):gsub("<[^>]+>", "")
	check(said == "Mara is pacing by the fountain.", "the line being said now is typed")
	check((words(s, "Line") or ""):find('<font color="#F07A3A">Mara</font>', 1, true) ~= nil, "her name in colour")
	check(s and not s:FindFirstChild("Speaker", true).Visible, "a line nobody says has no name up")
	advance(3)
	check((words(s, "Line") or ""):find("pacing") ~= nil, "the line stays until the villagers say the next")
	line("e3", ev.lines[2])
	advance(1)
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
	line("e3", ev.lines[3])
	advance(1)
	local c = s:FindFirstChild("Bust_c", true)
	check(c ~= nil, "a third villager joins")
	check(lit(c) and not lit(b) and not lit(a), "and the light moves to her")
	check(c and c.Position.X.Scale > 0.2 and c.Position.X.Scale < 0.8, "further in toward the middle")
	askNow("e3")
	advance(1)
	check(s:FindFirstChild("Choice1", true) ~= nil, "the answers come up in the scene")
	press("Choice2")
	check(#chosen == 1 and chosen[1].token == "e3" and chosen[1].i == 2, "an answer goes to the server")
	check(s:FindFirstChild("Choice1", true) == nil, "and the answers go")
	line("e3", { who = "b", text = "Fine. Sorry." })
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

run("watching an event already going", function()
	local warned = #errors
	-- the user: "clicking watch to watch a conversation restarts the conversation from the start"
	local ev = quarrel("e4")
	ev.choices = nil
	Sim.remoteEvent("EventShow"):FireClient(Sim.player, ev)
	line("e4", ev.lines[1])
	advance(3)
	line("e4", ev.lines[2])
	advance(3)
	line("e4", ev.lines[3])
	advance(1)
	press("Watch")
	frames(10)
	local s = scene()
	local said = ((s and words(s, "Line")) or ""):gsub("<[^>]+>", "")
	check(said == "You took three. I counted.", "Watch picks up at the line being said, not the first")
	check(s and s:FindFirstChild("Bust_c", true) ~= nil, "with whoever is saying it")
	check(
		s and s:FindFirstChild("Bust_a", true) ~= nil and s:FindFirstChild("Bust_b", true) ~= nil,
		"and the others in it so far"
	)
	advance(6)
	said = ((s and words(s, "Line")) or ""):gsub("<[^>]+>", "")
	check(said == "You took three. I counted.", "and nothing is said again while the villagers are quiet")
	press("Stop watching")
	advance(2)
	press("Watch")
	frames(10)
	s = scene()
	said = ((s and words(s, "Line")) or ""):gsub("<[^>]+>", "")
	check(said == "You took three. I counted.", "watching again picks up where they are")
	-- the user: "when clicking on the last part of the conversation, the conversation should close"
	local function click()
		local box = scene() and scene():FindFirstChild("Box", true)
		if box then
			box.InputBegan:Fire({ UserInputType = Enum.UserInputType.MouseButton1 })
		end
		frames(3)
	end
	advance(2)
	click()
	check(scene() ~= nil, "a click on a line that isn't the last leaves the scene up")
	Sim.remoteEvent("EventLine")
		:FireClient(Sim.player, { token = "e4", line = { who = "a", text = "Fine, three." }, last = true })
	frames(2)
	advance(2)
	click()
	check(scene() == nil, "a click on the last line closes the scene")
	advance(2)
	check(prompt() == nil, "and the prompt doesn't come back for it")
	Sim.remoteEvent("EventEnd"):FireClient(Sim.player, { token = "e4", notices = {} })
	advance(8)
	check(scene() == nil and prompt() == nil, "and it all goes when it ends")
	check(#errors == warned, "no warnings from any of it")
end)

-- cravings ------------------------------------------------------------------------------------------------

local Life = Harness.require("ReplicatedStorage.Shared.Sim.Life")
local bought = {}
local coins = 500
local function push(t)
	Sim.remoteEvent("State"):FireClient(Sim.player, t)
	frames(2)
end
-- (a fresh table each time, as a remote hands the client one)
local function crave(vid, food)
	villagers[vid].wish = { kind = "food", arg = food, untilT = os.time() + 9999 }
	push({ villagers = table.clone(villagers) })
end
local function onCard(name)
	local c = card()
	local label = c and c:FindFirstChild(name, true)
	return label and label.Text or ""
end
-- the server's side of WishBuy, as the contract has it: the coins go and the wish is granted
Sim.remoteFn("WishBuy").OnServerInvoke = function(_, vid)
	table.insert(bought, vid)
	local price = Life.wishPrice({ villagers = villagers }, vid)
	if not price then
		return false, "They don't want anything right now."
	end
	if coins < price then
		return false, "Not enough coins."
	end
	coins -= price
	villagers[vid].wish = nil
	push({ coins = coins, villagers = table.clone(villagers) })
	return true
end

run("a craving, bought from the talk card", function()
	local warned = #errors
	coins = 500
	push({ coins = coins })
	crave("v1", "curry")
	local price = Life.wishPrice({ villagers = villagers }, "v1")
	check(type(price) == "number" and price > 0, "a craving has a price")
	heldE("v1")
	local c = card()
	local buy = c and c:FindFirstChild("BuyWish", true)
	check(buy ~= nil, "the talk card has an answer that buys it")
	check(buy and buy:GetAttribute("Disabled") ~= true, "lit, with the coins to pay")
	check(buy and Sim.labelOf(buy):find(Text.commas(price), 1, true) ~= nil, "showing the price")
	press("BuyWish")
	check(#bought == 1 and bought[1] == "v1", "it asks the server to buy it for the right villager")
	check(card() and card():FindFirstChild("BuyWish", true) == nil, "and the answer goes once it's bought")
	check(onCard("Note") == "You bought it for " .. Text.commas(price) .. " coins.", "the note says what it did")
	check(onCard("Line"):find("Thank you", 1, true) ~= nil, "and they say thank you")
	press("Bye")

	coins = 10
	push({ coins = coins })
	crave("v1", "curry")
	heldE("v1")
	buy = card() and card():FindFirstChild("BuyWish", true)
	check(buy ~= nil and buy:GetAttribute("Disabled") == true, "without the coins the answer is dim")
	buy.Activated:Fire()
	frames(2)
	check(#bought == 1, "and pressing it asks nothing of the server")
	check(onCard("Note"):find("more coins", 1, true) ~= nil, "the note says how many more it takes")
	press("Bye")
	check(#errors == warned, "no warnings from any of it")
end)

run("a craving, bought from the Villagers screen", function()
	local warned = #errors
	coins = 10
	push({ coins = coins })
	crave("v1", "curry")
	Hud.open("Residents", "v1")
	frames(3)
	local stage = gui:FindFirstChild("Stage", true)
	local function wish()
		return stage and stage:FindFirstChild("Wish", true)
	end
	local buy = wish() and wish():FindFirstChild("BuyWish", true)
	check(buy ~= nil, "the wish row has a Buy button")
	check(wish() and wish():FindFirstChild("Craving", true) ~= nil, "beside the picture of what they crave")
	check(buy and buy:GetAttribute("Disabled") == true, "dim without the coins")
	check(wish() and wish():FindFirstChild("Short", true) ~= nil, "with a line saying how many more it takes")
	buy.Activated:Fire()
	frames(2)
	check(#bought == 1, "pressed, it asks nothing of the server")
	coins = 500
	push({ coins = coins })
	buy = wish() and wish():FindFirstChild("BuyWish", true)
	check(buy and buy:GetAttribute("Disabled") ~= true, "the coins come in and it lights up")
	buy.Activated:Fire()
	frames(3)
	check(#bought == 2 and bought[2] == "v1", "pressed, it buys it for the right villager")
	check(wish() == nil, "and the wish row goes once the craving is granted")
	Hud.closeAll()
	frames(2)
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
