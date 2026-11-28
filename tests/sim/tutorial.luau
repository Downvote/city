--!nocheck
-- The tutorial end to end under Lune: the client's real UI/Tutorial on the main screen and in
-- Build mode (tests/sim/client.luau), with the server's side of TutorialStep run by the real
-- Sim/Tutorial, the greeter the server would send, and the parts of the server it waits on (a
-- villager made, a bed and a job given) done by hand the way Services/Villagers does them. The
-- user: "for the tutorial, remove the box in the right and the creation text that appears on
-- join. first, darken the screen and highlight only "create" in the bottom menu ... once a
-- villager is created, do the same, darkning the screen and pointing to build mode ... After
-- this, the tutorial ends", and "at the start of the tutorial, make one of the player's friends
-- (most interacted with if possible) greet the player".
--   lune run tests/sim/tutorial.luau          (from the repository root)

local process = require("@lune/process")
local roblox = require("@lune/roblox")
local Sim = require("./client")

local Harness, Fake, gui, errors = Sim.Harness, Sim.Fake, Sim.gui, Sim.errors
local frames, press, check, run = Sim.frames, Sim.press, Sim.check, Sim.run
local State = Sim.State
local Enum = roblox.Enum

local Tutorial = Harness.require("ReplicatedStorage.Shared.Sim.Tutorial")
local Schema = Harness.require("ReplicatedStorage.Shared.Sim.Schema")
local City = Harness.require("ReplicatedStorage.Shared.Sim.City")
local StarterHouse = Harness.require("ReplicatedStorage.Shared.Data.StarterHouse")
local Appearance = Harness.require("ReplicatedStorage.Shared.Avatar.Appearance")
local Rng = Harness.require("ReplicatedStorage.Shared.Util.Rng")

-- the town as a new player has it: the plot less its bed and bench (StarterHouse.newPlot)
local profile = Sim.profile
for key, item in profile.plan.items do
	if table.find(StarterHouse.Held, item.id) then
		profile.plan.items[key] = nil
		Sim.State.plan.items[key] = nil
	end
end
profile.villagers, profile.order = {}, {}
profile.stats = { cravings = 0, wishes = 0, hearts = 0 }
profile.tutorial = 0
profile.coins = Schema.newProfile().coins

local function push(...)
	local patch = {}
	for _, k in { ... } do
		patch[k] = profile[k]
	end
	Sim.remoteEvent("State"):FireClient(Sim.player, patch)
	frames(2)
end

-- the server's side: Data's TutorialStep, and the friend Services/Avatar would send (their look
-- built, in a folder the client can see)
local asked = {}
Sim.remoteFn("TutorialStep").OnServerInvoke = function(_, step)
	table.insert(asked, step)
	local before = profile.tutorial
	local ok, now = Tutorial.advance(profile, step)
	if now ~= before then
		Sim.remoteEvent("State"):FireClient(Sim.player, { tutorial = profile.tutorial })
	end
	return ok, now
end
local greeterAsks = 0
local friendModel = Fake.new("Model")
friendModel.Name = "Greeter1"
do
	local root = Fake.new("Part", friendModel)
	root.Name = "HumanoidRootPart"
	local head = Fake.new("Part", friendModel)
	head.Name = "Head"
	head.Position = roblox.Vector3.new(0, 1.5, 0)
end
Sim.remoteFn("TutorialGreeter").OnServerInvoke = function()
	greeterAsks += 1
	return { name = "Robin", id = 77, friend = true, model = friendModel }
end

-- the creator, stood in for: it opens the way the popup picked (UI/Creator.openFor and
-- Creator.Created have their own sim: creator_sections)
local opened = {}
Harness.stub(Sim.CLIENT .. "UI.Creator", {
	openFor = function(kind)
		table.insert(opened, kind)
	end,
	Created = Fake.signal(),
	isOpen = function()
		return false
	end,
	close = function() end,
})

local function villager(i, name)
	local input = Schema.cleanVillagerInput({ name = name, pers = "sunny", app = Appearance.default() })
	local v = Schema.newVillager("v" .. i, input, Rng.new(i))
	v.isYou = #profile.order == 0 or nil
	profile.villagers[v.id] = v
	table.insert(profile.order, v.id)
	return v
end

local function layer()
	return gui:FindFirstChild("Tutorial")
end
local function dim()
	local l = layer()
	return l and l:FindFirstChild("TutorialDim")
end
local function dimmed()
	local d = dim()
	return d ~= nil and d.Visible
end
local function promptText()
	local d = dim()
	local line = d and d:FindFirstChild("TutorialPrompt") and d.TutorialPrompt:FindFirstChild("Line")
	return line and line.Text or ""
end
local function scene()
	return gui:FindFirstChild("TutorialScene")
end
local function sceneLine()
	local s = scene()
	local line = s and s:FindFirstChild("Line", true)
	return line and line.Text or ""
end
local function ringOn(target)
	return target ~= nil and target:FindFirstChild("TutorialRing") ~= nil
end
local function arrowUp()
	local d = dim()
	local a = d and d:FindFirstChild("TutorialArrow")
	return a ~= nil and a.Visible
end
local function rings()
	local n = 0
	for _, d in Sim.playerGui:GetDescendants() do
		if d.Name == "TutorialRing" then
			n += 1
		end
	end
	return n
end
local function aimedAt(target)
	return target ~= nil and target:GetAttribute("TutorialTarget") == true
end
local function hudPart(name)
	local hud = gui:FindFirstChild("Hud")
	return if name == "Build" then hud:FindFirstChild("Build") else hud:FindFirstChild(name, true)
end
local function buildPart(where, name)
	local ui = gui:FindFirstChild("BuildUI")
	local box = ui and ui:FindFirstChild(where, true)
	return box and box:FindFirstChild(name, true)
end
local function settle()
	Sim.advance(0.6)
	frames(3)
end
-- A click on the friend's box: the first shows the rest of a line being typed, the next goes on.
local function goOn()
	local box = scene() and scene():FindFirstChild("Box", true)
	local typed = box and box:FindFirstChild("Line", true)
	local click = { UserInputType = Enum.UserInputType.MouseButton1 }
	if box and typed and typed.MaxVisibleGraphemes ~= -1 then
		box.InputBegan:Fire(click)
		frames(1)
	end
	if box then
		box.InputBegan:Fire(click)
	end
	frames(3)
	settle()
end

-- What Build mode's server side leaves on the plan when a piece goes down, and what
-- Services/Villagers does then: a free bed or workplace goes to whoever has none.
local function assign()
	for _, vid in profile.order do
		local v = profile.villagers[vid]
		if not v.job then
			v.job = City.freeWorkplace(profile)
		end
		if not v.bed then
			for key, item in profile.plan.items do
				if item.id == "bed_single" then
					v.bed = key
				end
			end
		end
	end
	push("villagers")
end

-- Picks a card from the tray and puts it down on the plot (the next copy stays in hand).
local function placeCard(id, x, z)
	buildPart("Tray", id).Activated:Fire()
	frames(2)
	Sim.mouseAtPlot(x, z)
	Sim.click()
	frames(2)
end
local function putAway()
	Sim.input(Enum.UserInputType.MouseButton2, true)
	Sim.input(Enum.UserInputType.MouseButton2, false)
	frames(2)
end

push("coins")
State.set("tutorial", nil)
local Hud = Harness.require(Sim.CLIENT .. "UI.Hud")
Hud.start()
local UITutorial = Hud.panel("Tutorial")
frames(3)
Sim.advance(1)

run("the darkened screen's pieces meet round the hole and never overlap", function()
	local p = UITutorial.cut(1000, 600, 100, 450, 80, 60)
	check(p.Top[4] == 450 and p.Top[3] == 1000, "the top runs the whole width down to the hole")
	check(p.Bottom[2] == 510 and p.Bottom[4] == 90, "the bottom from under it to the foot")
	check(p.Left[1] == 0 and p.Left[3] == 100 and p.Left[2] == 450 and p.Left[4] == 60, "the left beside it")
	check(p.Right[1] == 180 and p.Right[3] == 820, "the right beside it to the edge")
	local area = 0
	for _, r in p do
		area += r[3] * r[4]
	end
	check(area + 80 * 60 == 1000 * 600, "together with the hole, the screen once over")
	-- a hole running off the screen (the Build button does) is kept on it
	local off = UITutorial.cut(1000, 600, 900, 520, 140, 100)
	check(off.Right[3] == 0 and off.Bottom[4] == 0, "a hole off the edge leaves no piece past it")
	local x, y, side = UITutorial.promptAt(1000, 600, { 900, 520, 140, 100 }, 300, 70, 40)
	check(side == "above" and x == 1000 - 16 - 300 and y == 520 - 40 - 70, "the prompt goes over a low hole, on screen")
	local _, y2, side2 = UITutorial.promptAt(1000, 600, { 100, 20, 50, 40 }, 300, 70, 12)
	check(side2 == "below" and y2 == 72, "and under a high one")
end)

run("nothing shows before the server says how far the player is", function()
	check(layer() ~= nil, "the tutorial's layer is there")
	check(not dimmed() and scene() == nil, "but nothing on it yet")
	check(rings() == 0, "and nothing pointed at")
end)

run("a first visit opens on a friend's welcome, then the screen darkens round Create", function()
	push("villagers", "order", "stats", "tutorial")
	check(scene() == nil, "it waits a moment after the town loads")
	Sim.advance(2.5)
	frames(3)
	check(greeterAsks == 1, "the server was asked who greets them, once")
	check(scene() ~= nil, "a friend's scene is up")
	local tag = scene() and scene():FindFirstChild("Speaker", true)
	check(tag and tag:FindFirstChild("Text", true).Text == "Robin", "the friend the server picked")
	check(scene() and scene():FindFirstChild("Bust_greeter", true) ~= nil, "in their own look")
	Sim.advance(3)
	frames(3)
	check(sceneLine() == Tutorial.Lines[1], "saying the user's welcome")
	check(sceneLine():find("Welcome to Catalog Town!", 1, true) == 1, "word for word")
	check(gui:FindFirstChild("Welcome to Catalog Town") == nil, "the old welcome panel is gone")
	check(layer():FindFirstChild("TutorialCard") == nil, "and the card at the right")
	check(not dimmed(), "nothing is darkened while the friend talks")
	goOn()
	check(scene() == nil, "a click on the box closes the scene")
	check(dimmed(), "and the screen darkens")
	local d = dim()
	local pieces = 0
	for _, side in { "Top", "Bottom", "Left", "Right" } do
		local f = d:FindFirstChild(side)
		if f and f.Active and f.BackgroundTransparency < 1 then
			pieces += 1
		end
	end
	check(pieces == 4, "four dark pieces round the hole, each taking the clicks")
	check(aimedAt(hudPart("Create")), "the hole over the Create tile")
	check(ringOn(hudPart("Create")) and arrowUp(), "ringed, with the arrow over it")
	check(promptText() == "Create your first villager!", "the prompt says so")
	check(not aimedAt(hudPart("Build")), "and nothing else is let through")
	check(rings() == 1, "one ring")
end)

run("Create opens the popup with the three ways, and each opens the creator its way", function()
	hudPart("Create").Activated:Fire()
	settle()
	local popup = gui:FindFirstChild("Your first villager")
	check(popup ~= nil, "the popup is up in place of the creator")
	check(#opened == 0, "the creator waits for the answer")
	local ask = popup and popup:FindFirstChild("Ask", true)
	check(ask and ask.Text == Tutorial.Ask, "asking how")
	check(
		popup
			and popup:FindFirstChild("Yourself", true)
			and popup:FindFirstChild("A friend", true)
			and popup:FindFirstChild("Custom", true),
		"Yourself, A friend and Custom"
	)
	check(not dimmed(), "the dark steps aside for it")
	popup:FindFirstChild("A friend", true).Activated:Fire()
	settle()
	check(opened[1] == "friend", "A friend opens the creator on the Players tab")
	check(gui:FindFirstChild("Your first villager") == nil, "the popup goes")
	for _, way in { { "Yourself", "yourself" }, { "Custom", "custom" } } do
		hudPart("Create").Activated:Fire()
		settle()
		gui:FindFirstChild("Your first villager"):FindFirstChild(way[1], true).Activated:Fire()
		settle()
		check(opened[#opened] == way[2], way[1] .. " opens it as " .. way[2])
	end
	-- the cross puts it away and the dark comes back round Create
	hudPart("Create").Activated:Fire()
	settle()
	Hud.closeAll()
	settle()
	check(dimmed() and aimedAt(hudPart("Create")), "closed, the dark is back round Create")
end)

run("a villager moves in: the friend says so, then the dark is round Build", function()
	local v = villager(1, "Mara")
	push("villagers", "order")
	settle()
	check(asked[#asked] == 1 and profile.tutorial == 1, "step one recorded, the server having looked")
	check(not dimmed(), "the dark goes while the friend talks")
	Sim.advance(3)
	frames(3)
	check(sceneLine() == Tutorial.Lines[2], "the user's line about the bed")
	goOn()
	check(dimmed() and aimedAt(hudPart("Build")), "then the hole is over the Build button")
	check(arrowUp() and not ringOn(hudPart("Create")), "with the arrow, and Create let go")
	check(promptText() == "Build a bed for your villager to sleep in!", "and the prompt for the bed")
	press("Build")
	settle()
	local furniture = buildPart("Dock", "Furniture")
	check(dimmed() and aimedAt(furniture) and ringOn(furniture), "in Build mode, Furniture first")
	furniture.Activated:Fire()
	settle()
	check(aimedAt(buildPart("Subs", "Beds")), "then Beds")
	buildPart("Subs", "Beds").Activated:Fire()
	settle()
	check(aimedAt(buildPart("Tray", "bed_single")), "then the single bed's card")
	check(promptText() == "Build a bed for your villager to sleep in!", "the prompt stays")
	-- held, the dark steps aside so the world can be clicked
	buildPart("Tray", "bed_single").Activated:Fire()
	settle()
	check(not dimmed() and rings() == 0, "nothing darkened while a piece is held")
	Sim.mouseAtPlot(118, 60)
	Sim.click()
	putAway()
	settle()
	check(dimmed(), "and back once it is put away")
	local beds = 0
	for _, item in profile.plan.items do
		if item.id == "bed_single" then
			beds += 1
		end
	end
	check(beds == 1, "the bed is on the plot")
	check(profile.tutorial == 1, "the step waits for the bed to be theirs")
	-- the bed is theirs with another one still in hand: it is put away for the friend to talk
	buildPart("Tray", "bed_single").Activated:Fire()
	settle()
	assign()
	settle()
	check(v.bed ~= nil and profile.tutorial == 2, "theirs: the server records it")
	check(Sim.BuildMode.state.placing == nil, "what was in hand is put away")
	Sim.advance(3)
	frames(3)
	check(sceneLine() == Tutorial.Lines[3], "and the friend asks for a workplace")
end)

run("a workplace, through Work, and the friend's last line", function()
	goOn()
	local work = buildPart("Dock", "Work")
	check(dimmed() and aimedAt(work), "the hole is over Work")
	check(promptText() == "Build a workplace for your villager to work in!", "with the prompt for it")
	work.Activated:Fire()
	settle()
	check(aimedAt(buildPart("Tray", "work_builder")), "its only category opens with it: the bench's card")
	placeCard("work_builder", 124, 64)
	putAway()
	settle()
	assign()
	settle()
	check(profile.tutorial == 3, "the job counts once they have it")
	check(not dimmed() and rings() == 0, "nothing darkened")
	Sim.advance(3)
	frames(3)
	check(sceneLine() == Tutorial.Lines.done, "the friend's last line")
	check(sceneLine() == "Grow your town and create more villagers!", "in the user's words")
	check(scene():FindFirstChild("Skip", true) == nil, "with nothing to skip")
	goOn()
	check(scene() == nil and not dimmed(), "a click and it is over")
	Sim.advance(5)
	frames(3)
	check(scene() == nil and not dimmed() and rings() == 0, "for good")
	press("Done")
	settle()
	check(not dimmed() and scene() == nil, "and nothing comes back on the main screen")
end)

run("a villager made some other way takes the popup down", function()
	-- back to a town with nobody in it (as a new save would load), the popup up
	local keep = profile.villagers
	profile.villagers, profile.order = {}, {}
	profile.tutorial = 0
	State.set("tutorial", 0)
	push("villagers", "order")
	settle()
	check(dimmed() and aimedAt(hudPart("Create")), "the dark round Create (its line was said already)")
	hudPart("Create").Activated:Fire()
	settle()
	check(gui:FindFirstChild("Your first villager") ~= nil, "the popup is up")
	profile.villagers = keep
	profile.order = { "v1" }
	push("villagers", "order")
	settle()
	check(gui:FindFirstChild("Your first villager") == nil, "and goes once somebody lives here")
end)

run("the look switches with the dark up, and Skip ends it for good", function()
	-- part way through again (as an old save would load), to see the dark again
	profile.tutorial = 1
	State.set("tutorial", 1)
	profile.villagers.v1.bed = nil
	push("villagers")
	Sim.BuildMode.exit()
	settle()
	check(dimmed() and aimedAt(hudPart("Build")), "the dark is round Build (its line was said already)")
	Sim.Kit.setTheme("light")
	settle()
	check(dimmed() and promptText() == "Build a bed for your villager to sleep in!", "drawn again in the light look")
	Sim.Kit.setTheme("dark")
	settle()
	-- Hide slides the main screen away: nothing is darkened, so Show can be pressed
	Hud.setHidden(true)
	settle()
	check(not dimmed(), "Hide takes the dark away with the main screen")
	Hud.setHidden(false)
	settle()
	check(dimmed() and aimedAt(hudPart("Build")), "and Show brings it back")
	dim():FindFirstChild("TutorialPrompt"):FindFirstChild("Skip").Activated:Fire()
	settle()
	check(asked[#asked] == Tutorial.Skipped and profile.tutorial == Tutorial.Skipped, "Skip is recorded")
	check(not dimmed() and rings() == 0 and scene() == nil, "and the dark and the pointer are gone")
	assign()
	settle()
	check(not dimmed() and scene() == nil, "for good")
	check(not UITutorial.takeCreate(), "and Create opens the creator again")
	check(#errors == 0, "no warnings from any of it")
end)

print(
	string.format(
		"\ntutorial sim: %s (%d warnings)",
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
