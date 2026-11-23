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
	for _, c in pills:GetChildren() do
		if c:IsA("GuiObject") then
			table.insert(names, c.Name)
		end
	end
	check(#names == 3, "money, people and happiness")
	check(pills:FindFirstChild("Plus", true) ~= nil, "and the money's + to the shop")
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
