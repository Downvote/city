--!nocheck
-- The main screen end to end under Lune: the client's real UI/Hud and UI/Quests on fake Roblox
-- instances (tests/sim/client.luau). The money, people and happiness strip sits under the town's
-- level, the quests under it (the user: "put these as a tab below the level, then add quests
-- below it as well"), a finished quest is claimed from there, and the Home button and the H key
-- ask the server to take you home (the user: "make it such that there is a teleport home button").
--   lune run tests/sim/hud.luau          (from the repository root)

local process = require("@lune/process")
local roblox = require("@lune/roblox")
local Sim = require("./client")

local Harness, gui, errors = Sim.Harness, Sim.gui, Sim.errors
local frames, press, check, run = Sim.frames, Sim.press, Sim.check, Sim.run
local State = Sim.State

local claimed, homes, homeAnswer = {}, 0, { true }
Sim.remoteFn("GoalClaim").OnServerInvoke = function(_, id)
	table.insert(claimed, id)
	return true, 300
end
Sim.remoteFn("GoHome").OnServerInvoke = function()
	homes += 1
	return table.unpack(homeAnswer)
end

local Hud = Harness.require(Sim.CLIENT .. "UI.Hud")
Hud.start()
frames(3)
Sim.advance(1)

run("the stats sit in a strip under the town's level", function()
	local card = gui:FindFirstChild("CityCard", true)
	local pills = gui:FindFirstChild("Pills", true)
	check(card ~= nil and pills ~= nil, "both are there")
	check(pills.Position.X.Scale == 0 and pills.AnchorPoint.X == 0, "at the left, not the middle")
	check(pills.Position.Y.Offset >= card.Position.Y.Offset + card.Size.Y.Offset, "below the level card, not beside it")
	local names = {}
	for _, c in pills:FindFirstChild("Row"):GetChildren() do
		if c:IsA("GuiObject") and c.Name ~= "Divider" then
			table.insert(names, c.Name)
		end
	end
	check(#names == 3, "money, people and happiness")
	check(
		pills:FindFirstChild("Body") ~= nil and pills:FindFirstChild("Tone") ~= nil,
		"on one painted slab with a tone of dots on it"
	)
	check(pills:FindFirstChild("Plus", true) == nil, "with no + beside the money any more")
end)

run("the quests sit under the strip, the next few goals", function()
	State.set("stats", { wishes = 3 })
	State.set("goals", {})
	Sim.advance(1)
	frames(2)
	local quests = gui:FindFirstChild("Quests", true)
	local pills = gui:FindFirstChild("Pills", true)
	check(quests ~= nil, "there is a quest list")
	check(quests.Position.Y.Offset >= pills.Position.Y.Offset + pills.Size.Y.Offset, "under the strip")
	local list = quests:FindFirstChild("List")
	local shown = {}
	for _, c in list:GetChildren() do
		if c:IsA("GuiObject") then
			table.insert(shown, c)
		end
	end
	check(#shown >= 1 and #shown <= 3, "one to three quests at a time")
	local wishes = list:FindFirstChild("wishes3")
	check(wishes ~= nil and wishes.LayoutOrder == 1, "a finished one comes first")
	local claim = wishes and wishes:FindFirstChild("Claim")
	check(claim ~= nil, "with its Claim button right there")
	claim.Activated:Fire()
	frames(2)
	check(claimed[1] == "wishes3", "which claims it from the server")
	-- once claimed it makes way for the next
	State.set("goals", { wishes3 = true })
	Sim.advance(1)
	frames(2)
	check(list:FindFirstChild("wishes3") == nil, "and a claimed one makes way")
	-- the header folds it
	quests:FindFirstChild("Header").Activated:Fire()
	frames(1)
	check(list.Visible == false, "the header folds the list away")
	quests:FindFirstChild("Header").Activated:Fire()
	frames(1)
	check(list.Visible == true, "and back")
end)

run("Home takes you home: the button and the H key", function()
	local warned = #errors
	press("Home")
	Sim.advance(1)
	check(homes == 1, "the Home button asks the server")
	check(gui:FindFirstChild("Veil", true) == nil, "and the screen comes back up")
	Sim.UIS.InputBegan:Fire(
		{ KeyCode = roblox.Enum.KeyCode.H, UserInputType = roblox.Enum.UserInputType.Keyboard },
		false
	)
	Sim.advance(1)
	check(homes == 2, "H does the same")
	Sim.UIS.InputBegan:Fire(
		{ KeyCode = roblox.Enum.KeyCode.H, UserInputType = roblox.Enum.UserInputType.Keyboard },
		true
	)
	Sim.advance(1)
	check(homes == 2, "but not while typing")
	homeAnswer = { false, "Hang on a moment." }
	press("Home")
	Sim.advance(1)
	local said = false
	for _, d in gui:GetDescendants() do
		if d:IsA("TextLabel") and d.Text == "Hang on a moment." then
			said = true
		end
	end
	check(said, "a refusal is said plainly")
	check(#errors == warned, "no warnings from any of it")
end)

run("the quick menu comes out of the bottom left corner, its tiles from the left edge", function()
	local menu = gui:FindFirstChild("Menu", true)
	check(
		menu ~= nil and menu.Position.X.Scale == 0 and menu.Position.X.Offset == 0 and menu.AnchorPoint.Y == 1,
		"the bar is in the bottom left corner"
	)
	-- the user: "remove this button and flush the rest to the left"
	check(menu:FindFirstChild("Portrait", true) == nil, "the round portrait button is gone")
	local names, row = {}, nil
	for _, name in { "Villagers", "Create", "Goals", "Gift" } do
		local b = menu:FindFirstChild(name, true)
		if b and b:IsA("TextButton") then
			table.insert(names, name)
			row = b.Parent
		end
	end
	check(#names == 4, "the four tiles are still there: villagers, the creator, goals and the gift")
	check(row ~= nil and row.Position.X.Scale == 0 and row.Position.X.Offset <= 16, "starting at the left edge")
	local list = row and row:FindFirstChildOfClass("UIListLayout")
	check(
		list ~= nil and list.HorizontalAlignment == roblox.Enum.HorizontalAlignment.Left,
		"and packed to the left, not spread across the bar"
	)
	local first = menu:FindFirstChild("Villagers", true)
	check(first.LayoutOrder == 1, "villagers first")
	-- the bar is no longer than its tiles need
	local wide = 0
	for _, name in names do
		wide += menu:FindFirstChild(name, true).Size.X.Offset
	end
	check(menu.Size.X.Offset < wide + 80, "and the bar is no longer than they need")
end)

run("the main screen steps aside while somebody is talking in a scene", function()
	local menu = gui:FindFirstChild("Menu", true)
	-- (the main screen's own Build button: Build mode has a tab of the same name)
	local build = menu.Parent:FindFirstChild("Build")
	local quests = gui:FindFirstChild("Quests", true)
	local pills = gui:FindFirstChild("Pills", true)
	check(menu ~= nil and build ~= nil and quests ~= nil, "the pieces are there")
	local homeMenu, homeBuild, homeQuests = menu.Position, build.Position, quests.Position
	State.set("talking", true)
	Sim.advance(1)
	check(menu.Position.X.Offset <= -menu.Size.X.Offset, "the menu bar slides off the left")
	check(build.Position.X.Offset >= build.Size.X.Offset, "the Build button off the right")
	check(quests.Position.X.Offset <= -quests.Size.X.Offset, "and the quests off the left")
	check(pills.Position.X.Offset == 0, "the stats stay")
	State.set("talking", false)
	Sim.advance(1)
	check(
		menu.Position == homeMenu and build.Position == homeBuild and quests.Position == homeQuests,
		"and they all come back where they were when the talk is over"
	)
end)

run("the weather's icon keeps its place on the clock", function()
	local clock = gui:FindFirstChild("Clock", true)
	local function icon()
		for _, c in clock:GetChildren() do
			if c:GetAttribute("Vector") ~= nil or c.Name == "Icon" then
				return c
			end
		end
		return nil
	end
	local function inPlace(art)
		-- wholly on the clock, left of the time, and no more than a few pixels off its middle line
		local half = art.Size.X.Offset / 2
		return art.Position.X.Scale == 0
			and art.Position.X.Offset - half >= 0
			and art.Position.X.Offset + half <= 64
			and math.abs(art.Position.Y.Offset) <= 4
	end
	Sim.env.workspace:SetAttribute("Weather", "clear")
	Sim.advance(2)
	local fair = icon()
	check(fair ~= nil and inPlace(fair), "the icon is on the clock, left of the time")
	local home = fair.Position.X.Offset
	-- rain: a cloud, which bobs. It bobs on the spot: up and down a few pixels, never sideways
	-- (it used to aim 21 pixels to the left and slide across the clock and back)
	for _, weather in { "rain", "storm", "snow", "cloudy" } do
		Sim.env.workspace:SetAttribute("Weather", weather)
		Sim.advance(2)
		local art = icon()
		check(
			art ~= nil and inPlace(art) and art.Position.X.Offset == home,
			weather .. ": its icon stays put, left to right"
		)
	end
	Sim.env.workspace:SetAttribute("Weather", "clear")
	Sim.advance(2)
end)

print(
	string.format(
		"\nhud sim: %s (%d warnings)",
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
