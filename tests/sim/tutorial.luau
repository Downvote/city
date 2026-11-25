--!nocheck
-- The tutorial end to end under Lune: the client's real UI/Tutorial on the main screen and in
-- Build mode (tests/sim/client.luau), with the server's side of TutorialStep run by the real
-- Sim/Tutorial and the parts of the server it waits on (a villager made, a bed and a job given,
-- a craving bought) done by hand the way Services/Villagers does them. The user: "make the
-- tutorial more visual and structured, starting with creating a villager, then building a place
-- for them to sleep, then a place to work. the first time a craving pops up, guide the user how
-- to do it."
--   lune run tests/sim/tutorial.luau          (from the repository root)

local process = require("@lune/process")
local roblox = require("@lune/roblox")
local Sim = require("./client")

local Harness, Fake, gui, errors = Sim.Harness, Sim.Fake, Sim.gui, Sim.errors
local frames, press, check, run = Sim.frames, Sim.press, Sim.check, Sim.run
local State = Sim.State
local UDim2 = roblox.UDim2

local Tutorial = Harness.require("ReplicatedStorage.Shared.Sim.Tutorial")
local Schema = Harness.require("ReplicatedStorage.Shared.Sim.Schema")
local Life = Harness.require("ReplicatedStorage.Shared.Sim.Life")
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

-- the server's side: Data's TutorialStep, Villagers' WishBuy
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
Sim.remoteFn("WishBuy").OnServerInvoke = function(_, vid)
	local ok, _, _, why = Life.buyWish(profile, vid, Rng.new(3))
	if ok then
		Sim.remoteEvent("State")
			:FireClient(Sim.player, { villagers = profile.villagers, coins = profile.coins, stats = profile.stats })
	end
	return ok, why
end

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
local function cardOf()
	local l = layer()
	return l and l:FindFirstChild("TutorialCard")
end
local function textIn(root, name)
	local label = root and root:FindFirstChild(name, true)
	return label and label.Text or ""
end
-- is the card on the screen (not slid off past the right edge)?
local function cardIn()
	local c = cardOf()
	return c ~= nil and c.Position.X.Scale == 1 and c.Position.X.Offset < 100
end
local function ringOn(target)
	return target ~= nil and target:FindFirstChild("TutorialRing") ~= nil
end
local function arrowOn(target)
	return target ~= nil and target:FindFirstChild("TutorialArrow") ~= nil
end
local function rings()
	local n = 0
	for _, d in Sim.playerGui:GetDescendants() do
		if d.Name == "TutorialRing" or d.Name == "TutorialArrow" then
			n += 1
		end
	end
	return n
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

-- Picks a card from the tray and puts it down on the plot, then puts the next copy away.
local function placeCard(id, x, z)
	local card = buildPart("Tray", id)
	card.Activated:Fire()
	frames(2)
	Sim.mouseAtPlot(x, z)
	Sim.click()
	Sim.input(roblox.Enum.UserInputType.MouseButton2, true)
	Sim.input(roblox.Enum.UserInputType.MouseButton2, false)
	frames(2)
end

push("coins")
State.set("tutorial", nil)
local Hud = Harness.require(Sim.CLIENT .. "UI.Hud")
Hud.start()
frames(3)
Sim.advance(1)

run("nothing shows before the server says how far the player is", function()
	check(layer() ~= nil, "the tutorial's layer is there")
	check(not cardIn(), "but no card yet")
	check(rings() == 0, "and nothing pointed at")
end)

run("a first visit opens on the welcome, the tutorial's first page", function()
	push("villagers", "order", "stats", "tutorial")
	Sim.advance(2.5)
	frames(3)
	local welcome = gui:FindFirstChild("Welcome to Catalog Town")
	check(welcome ~= nil, "the welcome is up")
	check(welcome and welcome:FindFirstChild("Steps", true) ~= nil, "with the four steps in a row")
	local steps = welcome and welcome:FindFirstChild("Steps", true)
	local chips = 0
	for _, c in steps and steps:GetChildren() or {} do
		if c.Name:sub(1, 4) == "Step" then
			chips += 1
		end
	end
	check(chips == 4, "four of them")
	check(
		welcome
			and welcome:FindFirstChild("Make me", true) ~= nil
			and welcome:FindFirstChild("Start from scratch", true),
		"and the two ways to make the first villager"
	)
	check(Hud.panel("Welcome") == nil, "the old welcome is gone")
	check(cardIn(), "the step card is at the side under it")
	check(textIn(cardOf(), "Title") == "Make your first villager", "on step one")
	check(ringOn(hudPart("Create")) and arrowOn(hudPart("Create")), "the Create tile is pointed at")
	Hud.closeAll()
	settle()
	check(gui:FindFirstChild("Welcome to Catalog Town") == nil, "closing the welcome leaves the card")
	check(cardIn() and ringOn(hudPart("Create")), "and the pointer")
end)

run("step two: a bed, through Build, Furniture and Beds", function()
	local v = villager(1, "Mara")
	push("villagers", "order")
	settle()
	check(asked[#asked] == 1, "the client asked the server to record step one")
	check(profile.tutorial == 1, "which the server did, having looked itself")
	check(textIn(cardOf(), "Title") == "Give them a bed", "the card moves on to the bed")
	check(not ringOn(hudPart("Create")), "the Create tile is let go")
	check(arrowOn(hudPart("Build")), "and the Build button pointed at")
	press("Build")
	settle()
	check(cardIn(), "the card stays in Build mode")
	check(cardOf().Position.Y.Offset < 60, "up at the top right, clear of the bars")
	local furniture = buildPart("Dock", "Furniture")
	check(ringOn(furniture), "the Furniture group is ringed")
	furniture.Activated:Fire()
	settle()
	check(not ringOn(furniture), "then let go")
	check(ringOn(buildPart("Subs", "Beds")), "and the Beds tile ringed")
	check(textIn(cardOf(), "Line") == "Now open Beds.", "the line says so")
	buildPart("Subs", "Beds").Activated:Fire()
	settle()
	check(ringOn(buildPart("Tray", "bed_single")), "then the single bed's card")
	-- held, everything slides away and the card with it
	buildPart("Tray", "bed_single").Activated:Fire()
	settle()
	check(not cardIn(), "the card goes while a piece is held")
	Sim.mouseAtPlot(118, 60)
	Sim.click()
	Sim.input(roblox.Enum.UserInputType.MouseButton2, true)
	Sim.input(roblox.Enum.UserInputType.MouseButton2, false)
	settle()
	check(cardIn(), "and comes back once it is put down")
	local beds = 0
	for _, item in profile.plan.items do
		if item.id == "bed_single" then
			beds += 1
		end
	end
	check(beds == 1, "the bed is on the plot")
	check(textIn(cardOf(), "Title") == "Give them a bed", "the step waits for the bed to be theirs")
	assign()
	settle()
	check(v.bed ~= nil and profile.tutorial >= 2, "theirs: the server records it")
end)

run("step three: a job, through Work, then back out", function()
	check(textIn(cardOf(), "Title") == "Give them a job", "the card is on the job")
	local work = buildPart("Dock", "Work")
	check(ringOn(work), "the Work group is ringed")
	work.Activated:Fire()
	settle()
	check(ringOn(buildPart("Tray", "work_builder")), "its only category opens with it: the bench's card")
	placeCard("work_builder", 124, 64)
	settle()
	assign()
	settle()
	check(profile.tutorial == 3, "the job counts once they have it")
	check(textIn(cardOf(), "Title") == "Buy them a craving", "on to the craving")
	check(textIn(cardOf(), "Line"):find("yourself") ~= nil, "only you live here: make somebody else")
	press("Done")
	settle()
	check(ringOn(hudPart("Create")), "pointing at Create on the main screen")
end)

run("step four waits for a craving, points at the bubble, then at Buy", function()
	local v = villager(2, "Tobin")
	push("villagers", "order")
	settle()
	check(textIn(cardOf(), "Line"):find("Wait") ~= nil, "it waits for one")
	check(rings() == 0, "with nothing pointed at")
	check(profile.tutorial == 3, "and nothing recorded")
	-- tucked to the edge, it stays out of the way
	cardOf():FindFirstChild("Tuck", true).Activated:Fire()
	settle()
	check(cardOf().Position.X.Offset > 200, "tucked, only its picture shows")
	-- a craving turns up, and the bubble over Tobin's head
	local Wishes = Harness.require(Sim.CLIENT .. "World.Wishes")
	Wishes.start()
	local plot = Sim.ws:FindFirstChild("Plots"):FindFirstChild("Plot1")
	local folder = plot:FindFirstChild("Villagers") or Fake.new("Folder", plot)
	folder.Name = "Villagers"
	local model = Fake.new("Model", folder)
	model.Name = "Tobin"
	model:SetAttribute("Vid", v.id)
	local head = Fake.new("Part", model)
	head.Name = "Head"
	local cam = Sim.ws.CurrentCamera
	head.Position = cam.CFrame.Position + cam.CFrame.LookVector * 30
	v.wish = { kind = "food", arg = "curry", untilT = os.time() + 9999 }
	model:SetAttribute("Wish", "apple")
	push("villagers")
	Sim.advance(2)
	settle()
	local bubble = Sim.playerGui:FindFirstChild("WishBubble")
	check(bubble ~= nil, "the bubble is up")
	local fade = bubble and bubble:FindFirstChild("Fade")
	check(arrowOn(fade), "with an arrow over it, in its stack")
	check(fade and fade:FindFirstChild("TutorialArrow").LayoutOrder == 0, "on top of the bubble")
	check(cardOf().Position.X.Offset < 100, "the card comes back out")
	check(textIn(cardOf(), "Line"):find("Tobin is craving") ~= nil, "saying who wants what")
	-- the bubble opens the popup with the Buy button
	Harness.require(Sim.CLIENT .. "UI.WishPopup").open(v.id)
	settle()
	local buy = gui:FindFirstChild("WishPopup") and gui:FindFirstChild("WishPopup"):FindFirstChild("Buy", true)
	check(buy ~= nil, "the popup is up")
	check(ringOn(buy), "Buy is ringed")
	check(not arrowOn(fade), "and the bubble let go")
	buy.Activated:Fire()
	settle()
	check(profile.stats.cravings == 1, "the craving is bought")
	check(profile.tutorial == 4, "the last step recorded")
	check(textIn(cardOf(), "Title") == "That's the tutorial", "a short card closes it")
	check(rings() == 0, "nothing pointed at")
	Sim.advance(16)
	settle()
	check(not cardIn(), "and it goes by itself")
	folder:Destroy()
end)

run("the look switches with the card up, and Skip ends it for good", function()
	-- back to a town part way through (as an old save would load), to see the card again
	State.set("tutorial", 1)
	profile.tutorial = 1
	profile.villagers.v1.bed = nil
	push("villagers")
	settle()
	-- (the closing card has been and gone this session; a step shows again)
	check(cardIn() and textIn(cardOf(), "Title") == "Give them a bed", "a step card is up")
	Sim.Kit.setTheme("light")
	settle()
	check(cardIn() and textIn(cardOf(), "Title") == "Give them a bed", "drawn again in the light look")
	Sim.Kit.setTheme("dark")
	settle()
	cardOf():FindFirstChild("Skip", true).Activated:Fire()
	settle()
	check(asked[#asked] == Tutorial.Skipped and profile.tutorial == Tutorial.Skipped, "Skip is recorded")
	check(not cardIn() and rings() == 0, "and the card and the pointer are gone")
	-- a bed now changes nothing
	assign()
	settle()
	check(not cardIn(), "for good")
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
