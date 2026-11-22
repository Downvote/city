--!nocheck
-- Runs the real Build mode end to end under Lune: the client's BuildUI and BuildMode on fake
-- Roblox instances (tests/sim/fake.luau), talking to the real server Build service with its data
-- and plot services stubbed. It opens Build mode, picks things from the tray, moves the mouse
-- over the plot and clicks, then checks the server's plan and the client's copy both changed.
--   lune run tests/sim/build_client.luau          (from the repository root)

local process = require("@lune/process")
local roblox = require("@lune/roblox")
local Harness = require("../harness")
local Fake = require("./fake")

Harness.init(".")
local env = Harness.env()

local Vector2, Vector3, CFrame, Enum = roblox.Vector2, roblox.Vector3, roblox.CFrame, roblox.Enum

-- a fake clock, so the server's throttle sees time pass between actions
local now = 1000
env.os = setmetatable({
	clock = function()
		return now
	end,
	time = function()
		return math.floor(now)
	end,
}, { __index = os })

-- the client's world ------------------------------------------------------------------------------

env.Instance = {
	new = function(class, parent)
		return Fake.new(class, parent)
	end,
}
local rawTypeof = typeof
env.typeof = function(v)
	if Fake.isFake(v) then
		return "Instance"
	end
	return rawTypeof(v)
end
-- Lune's CFrame.lookAt flips the Z axis (it looks away from the target); Roblox's doesn't. The
-- camera code relies on it, so give the game a correct one built from fromMatrix.
env.CFrame = setmetatable({
	lookAt = function(eye, target, upHint)
		local look = (target - eye).Unit
		local right = look:Cross(upHint or Vector3.yAxis)
		if right.Magnitude < 1e-6 then
			right = look:Cross(Vector3.xAxis)
		end
		right = right.Unit
		return CFrame.fromMatrix(eye, right, right:Cross(look))
	end,
}, { __index = CFrame })
env.TweenInfo = {
	new = function(...)
		return { ... }
	end,
}
env.RaycastParams = { new = Fake.raycastParams }
env.OverlapParams = { new = Fake.raycastParams }
local errors = {}
env.warn = function(...)
	local parts = {}
	for _, v in { ... } do
		table.insert(parts, tostring(v))
	end
	local msg = table.concat(parts, " ")
	table.insert(errors, msg)
	print("[warn] " .. msg)
end

local ws = Fake.new("Model")
ws.Name = "Workspace"
local cam = Fake.camera(Vector2.new(1280, 720), 36)
cam.Parent = ws
Fake.extend(ws, {
	CurrentCamera = cam,
	Raycast = function(_, origin, direction, params)
		return Fake.raycastIn(ws, origin, direction, params)
	end,
})
env.workspace = ws
Harness.addService("Workspace", ws)

local plots = Fake.new("Folder", ws)
plots.Name = "Plots"
local plotModel = Fake.new("Model", plots)
plotModel.Name = "Plot1"
local buildFolder = Fake.new("Folder", plotModel)
buildFolder.Name = "Build"

local player = Fake.new("Player")
player.Name = "Tester"
player:SetAttribute("Plot", 1)
local playerGui = Fake.new("PlayerGui", player)
playerGui.Name = "PlayerGui"
local guiAt = {} -- what GetGuiObjectsAtPosition reports under the mouse
Fake.extend(playerGui, {
	GetGuiObjectsAtPosition = function()
		return guiAt
	end,
})

local mouse = Vector2.new(640, 400)
local UIS = {
	InputBegan = Fake.signal(),
	InputEnded = Fake.signal(),
	InputChanged = Fake.signal(),
	TouchTapInWorld = Fake.signal(),
	TouchPinch = Fake.signal(),
	TouchPan = Fake.signal(),
	TouchStarted = Fake.signal(),
	TouchEnded = Fake.signal(),
	TouchEnabled = false,
	MouseEnabled = true,
	KeyboardEnabled = true,
	GamepadEnabled = false,
	GetMouseLocation = function()
		return mouse
	end,
	IsKeyDown = function()
		return false
	end,
	GetFocusedTextBox = function()
		return nil
	end,
}
Harness.addService("UserInputService", UIS)
local RS = {
	RenderStepped = Fake.signal(),
	Heartbeat = Fake.signal(),
	Stepped = Fake.signal(),
	IsServer = function()
		return false
	end,
	IsClient = function()
		return true
	end,
	IsStudio = function()
		return true
	end,
}
Harness.addService("RunService", RS)
Harness.addService("Players", {
	LocalPlayer = player,
	PlayerAdded = Fake.signal(),
	PlayerRemoving = Fake.signal(),
	GetPlayers = function()
		return { player }
	end,
})
Harness.addService("GuiService", {
	GetGuiInset = function()
		return Vector2.new(0, 36), Vector2.zero
	end,
})
Harness.addService("TweenService", {
	Create = function(_, inst, _, goals)
		return {
			Play = function()
				for k, v in goals do
					inst[k] = v
				end
			end,
			Cancel = function() end,
			Pause = function() end,
			Completed = Fake.signal(),
		}
	end,
})
Harness.addService("ContextActionService", {
	BindAction = function() end,
	BindActionAtPriority = function() end,
	UnbindAction = function() end,
})
Harness.addService("Lighting", { ClockTime = 12 })
Harness.addService("ProximityPromptService", { PromptTriggered = Fake.signal() })

-- remotes: client calls go straight to the server's handlers -------------------------------------------

local remoteEvents = {}
local function remoteEvent(name)
	if not remoteEvents[name] then
		local ev = { OnClientEvent = Fake.signal(), OnServerEvent = Fake.signal() }
		function ev.FireClient(_, _, ...)
			ev.OnClientEvent:Fire(...)
		end
		function ev.FireAllClients(_, ...)
			ev.OnClientEvent:Fire(...)
		end
		function ev.FireServer(_, ...)
			ev.OnServerEvent:Fire(player, ...)
		end
		remoteEvents[name] = ev
	end
	return remoteEvents[name]
end
local remoteFns = {}
local calls = {}
local function remoteFn(name)
	if not remoteFns[name] then
		local f = {}
		function f.InvokeServer(_, ...)
			now += 1
			table.insert(calls, name)
			if not f.OnServerInvoke then
				return nil
			end
			return f.OnServerInvoke(player, ...)
		end
		remoteFns[name] = f
	end
	return remoteFns[name]
end
Harness.stub("ReplicatedStorage.Shared.Net.Remotes", {
	fn = remoteFn,
	event = remoteEvent,
	create = function() end,
	Functions = {},
	Events = {},
})

-- the server: the real Build service, its neighbours stubbed ----------------------------------------------

local Town = Harness.require("ReplicatedStorage.Shared.Data.Town")
local StarterHouse = Harness.require("ReplicatedStorage.Shared.Data.StarterHouse")
local Plan = Harness.require("ReplicatedStorage.Shared.Build.Plan")
local Builder = Harness.require("ReplicatedStorage.Shared.Build.Builder")

local profile = { coins = 20000, plan = StarterHouse.plan(), villagers = {}, order = {} }
Harness.stub("ServerScriptService.Server.Services.Data", {
	get = function()
		return profile
	end,
	canAfford = function(_, n)
		return profile.coins >= n
	end,
	addCoins = function(_, n)
		profile.coins += n
		remoteEvent("State"):FireClient(player, { coins = profile.coins })
		return true
	end,
})
Harness.stub("ServerScriptService.Server.Services.Plots", {
	indexOf = function()
		return 1
	end,
	buildFolder = function()
		return buildFolder
	end,
	frame = function()
		return Town.plotFrame(1)
	end,
})
local Build = Harness.require("ServerScriptService.Server.Services.Build")
Build.start()
remoteFn("GetState").OnServerInvoke = function()
	return { coins = profile.coins, villagers = {}, order = {}, plan = Plan.copy(profile.plan) }
end
-- the plot's models, as Plots draws them when a player joins
local all = {}
for _, kind in Plan.Kinds do
	all[kind] = {}
	for key in profile.plan[kind] do
		all[kind][key] = true
	end
end
Builder.update(profile.plan, all, buildFolder, Town.plotFrame(1))

-- the client ---------------------------------------------------------------------------------------------

local CLIENT = "StarterPlayer.StarterPlayerScripts.Client."
local State = Harness.require(CLIENT .. "Controllers.State")
State.start()
local Kit = Harness.require(CLIENT .. "UI.Kit")
local BuildMode = Harness.require(CLIENT .. "Build.BuildMode")
local BuildUI = Harness.require(CLIENT .. "Build.BuildUI")
BuildUI.init(function()
	BuildMode.exit()
end)

-- driving it -----------------------------------------------------------------------------------------------

local failures = 0
local function check(cond, what)
	if cond then
		print("  ok   " .. what)
	else
		failures += 1
		print("  FAIL " .. what)
	end
end

local function frames(n)
	for _ = 1, n or 2 do
		now += 1 / 60
		RS.RenderStepped:Fire(1 / 60)
		RS.Heartbeat:Fire(1 / 60)
	end
end

local plotFrame = Town.plotFrame(1)
local function mouseAtPlot(x, z, y)
	local v, on = cam:WorldToViewportPoint(plotFrame * Vector3.new(x, y or Plan.levelBase(BuildMode.state.level), z))
	mouse = Vector2.new(v.X, v.Y)
	UIS.InputChanged:Fire({
		UserInputType = Enum.UserInputType.MouseMovement,
		Position = Vector3.new(v.X, v.Y - 36, 0),
		Delta = Vector3.zero,
	}, false)
	frames(2)
	return on
end

local function input(kind, began)
	local obj = {
		UserInputType = kind,
		Position = Vector3.new(mouse.X, mouse.Y - 36, 0),
		KeyCode = Enum.KeyCode.Unknown,
		Delta = Vector3.zero,
		UserInputState = if began then Enum.UserInputState.Begin else Enum.UserInputState.End,
	}
	if began then
		UIS.InputBegan:Fire(obj, false)
	else
		UIS.InputEnded:Fire(obj, false)
	end
	frames(1)
end

local function click()
	input(Enum.UserInputType.MouseButton1, true)
	input(Enum.UserInputType.MouseButton1, false)
	frames(2)
end

local function drag(x1, z1, x2, z2)
	mouseAtPlot(x1, z1)
	input(Enum.UserInputType.MouseButton1, true)
	mouseAtPlot(x2, z2)
	input(Enum.UserInputType.MouseButton1, false)
	frames(2)
end

local gui = Kit.root()
local function buttons(test)
	return Fake.find(gui, function(d)
		return d:IsA("GuiButton") and Fake.shown(d) and test(d)
	end)
end
local function labelOf(b)
	local parts = { b:IsA("TextButton") and b.Text or "" }
	for _, d in b:GetDescendants() do
		if d:IsA("TextLabel") then
			table.insert(parts, d.Text)
		end
	end
	return table.concat(parts, " ")
end
local function press(text)
	local found = buttons(function(b)
		return labelOf(b):find(text, 1, true) ~= nil
	end)
	if #found == 0 then
		error("no button showing " .. text)
	end
	found[1].Activated:Fire()
	frames(2)
	return found[1]
end

local function count(kind)
	local n = 0
	for _ in profile.plan[kind] do
		n += 1
	end
	return n
end
local function clientCount(kind)
	local n = 0
	for _ in State.plan[kind] do
		n += 1
	end
	return n
end

local function run(name, fn)
	print(name)
	local ok, err = xpcall(fn, debug.traceback)
	if not ok then
		failures += 1
		print("  FAIL (error) " .. tostring(err))
	end
end

-- the scenario ---------------------------------------------------------------------------------------------

frames(3)

run("opening Build mode", function()
	check(BuildMode.enter(), "BuildMode.enter() returns true")
	frames(3)
	check(BuildMode.isActive(), "Build mode is on")
	local ui = gui:FindFirstChild("BuildUI")
	check(ui ~= nil and ui.Visible, "the Build screen is showing")
	check(BuildMode.state.tool == "select", "it starts on the pick tool")
	check(#errors == 0, "no warnings so far")
	local marks = ws:FindFirstChild("BuildMarkers")
	check(
		marks ~= nil and marks:FindFirstChild("BillboardGui", true) ~= nil,
		"the cursor label survives the grid being drawn"
	)
	check(marks ~= nil and marks:FindFirstChildOfClass("Highlight") ~= nil, "so does the selection highlight")
end)

run("placing a piece of furniture from the tray", function()
	press("Furniture")
	local before, coinsBefore = count("items"), profile.coins
	-- the first card in the tray
	local tray = gui:FindFirstChild("Tray", true)
	local cards = Fake.find(tray, function(d)
		return d:IsA("TextButton") and Fake.shown(d) and labelOf(d):find("🪙", 1, true) ~= nil
	end)
	check(#cards > 0, "the tray shows item cards (" .. #cards .. ")")
	cards[1].Activated:Fire()
	frames(2)
	check(BuildMode.state.tool == "place" and BuildMode.state.placing ~= nil, "clicking a card picks the item up")
	check(mouseAtPlot(124, 64), "the spot is on screen")
	local ghost = ws:FindFirstChild("BuildGhost")
	check(ghost ~= nil and #ghost:GetChildren() > 0, "a ghost follows the mouse")
	click()
	check(count("items") == before + 1, "the server's plan has one more item")
	check(clientCount("items") == count("items"), "the client's copy matches")
	check(profile.coins < coinsBefore, "it cost coins")
end)

run("drawing a wall by dragging", function()
	press("Build")
	press("Walls")
	check(BuildMode.state.tool == "wall", "the wall tool is on")
	local before = count("walls")
	drag(112, 52, 132, 52)
	check(count("walls") == before + 1, "a dragged wall is built")
end)

run("drawing a wall click by click", function()
	local before = count("walls")
	mouseAtPlot(112, 80)
	click()
	mouseAtPlot(132, 80)
	click()
	check(count("walls") == before + 1, "two clicks build a wall")
	input(Enum.UserInputType.MouseButton2, true)
	input(Enum.UserInputType.MouseButton2, false)
end)

run("dragging out a room", function()
	press("Rooms")
	local walls, floors = count("walls"), count("floors")
	drag(60, 56, 72, 68)
	check(count("walls") == walls + 4, "a room makes four walls")
	check(count("floors") == floors + 1, "and a floor")
end)

run("laying a floor", function()
	press("Floors")
	local before = count("floors")
	drag(120, 84, 132, 94)
	check(count("floors") == before + 1, "a dragged floor is laid")
end)

run("putting a roof on", function()
	press("Roofs")
	local before = count("roofs")
	drag(60, 56, 72, 68)
	check(count("roofs") == before + 1, "a dragged roof is built")
end)

run("selling with the Sell tool", function()
	press("Sell")
	local before = count("items")
	mouseAtPlot(124, 64, 1)
	click()
	check(count("items") == before - 1, "clicking the item sells it")
end)

run("undo puts it back", function()
	local before = count("items")
	press("Undo")
	check(count("items") == before + 1, "undo brings the item back")
end)

run("picking, turning, copying and moving a piece of furniture", function()
	press("Pick")
	check(BuildMode.state.tool == "select", "the pick tool is on")
	mouseAtPlot(124, 64, 1)
	click()
	local kind, key = BuildMode.selectedObject()
	check(kind == "items" and key ~= nil, "clicking the item picks it")
	local action = gui:FindFirstChild("Action", true)
	check(action ~= nil and action.Visible, "the action bar shows over it")
	local r0 = profile.plan.items[key].r
	press("Turn")
	check(profile.plan.items[key] ~= nil and profile.plan.items[key].r ~= r0, "Turn turns it")
	local before = count("items")
	press("Copy")
	check(BuildMode.state.tool == "place", "Copy picks up a copy")
	mouseAtPlot(130, 72)
	click()
	check(count("items") == before + 1, "and places it")
	press("Pick")
	mouseAtPlot(124, 64, 1)
	click()
	local _, key2 = BuildMode.selectedObject()
	press("Move")
	check(BuildMode.state.placing ~= nil and BuildMode.state.placing.moveKey == key2, "Move picks it up")
	mouseAtPlot(118, 76)
	click()
	local moved = profile.plan.items[key2]
	check(moved ~= nil and math.abs(moved.z - 76) < 2, "and puts it down somewhere else")
	check(count("items") == before + 1, "without making a new one")
end)

run("painting a wall", function()
	press("Paint")
	check(BuildMode.state.tool == "paint", "the paint tool is on")
	local finish = buttons(function(b)
		return labelOf(b):find("Red brick", 1, true) ~= nil
	end)[1]
	check(finish ~= nil, "the finishes show as tiles")
	finish.Activated:Fire()
	frames(2)
	-- the dragged wall from earlier runs along z = 52 from x = 112 to 132; aim at its middle
	local target
	for key, w in profile.plan.walls do
		if w.z1 == 52 and w.z2 == 52 then
			target = key
		end
	end
	mouseAtPlot(122, 51, 4)
	click()
	local w = profile.plan.walls[target]
	check(w ~= nil and (w.a.m == "Brick" or w.b.m == "Brick"), "clicking the wall paints a side brick")
end)

run("putting a door in a wall", function()
	press("Build")
	press("Doors")
	local tray = gui:FindFirstChild("Tray", true)
	local cards = Fake.find(tray, function(d)
		return d:IsA("TextButton") and Fake.shown(d) and labelOf(d):find("🪙", 1, true) ~= nil
	end)
	cards[1].Activated:Fire()
	frames(2)
	local before = count("items")
	mouseAtPlot(122, 51.5, 4)
	click()
	check(count("items") == before + 1, "clicking the wall puts the door in")
	local door
	for _, it in profile.plan.items do
		if it.wall ~= nil and it.id == BuildMode.state.placing.id then
			door = it
		end
	end
	check(door ~= nil, "the door hangs on the wall")
	input(Enum.UserInputType.MouseButton2, true)
	input(Enum.UserInputType.MouseButton2, false)
end)

run("every tab and tool opens without an error", function()
	local warned = #errors
	local mains = { "Build", "Furniture", "Outdoor", "Work" }
	for _, main in mains do
		press(main)
		local subs = Fake.find(gui:FindFirstChild("Subs", true), function(d)
			return d:IsA("TextButton") and Fake.shown(d)
		end)
		check(#subs > 0, main .. " has sub categories (" .. #subs .. ")")
		for _, b in subs do
			b.Activated:Fire()
			frames(2)
			local tray = gui:FindFirstChild("Tray", true)
			local shown = Fake.find(tray, function(d)
				return d:IsA("GuiButton") and Fake.shown(d)
			end)
			check(#shown > 0, main .. " / " .. labelOf(b):gsub("^%s+", "") .. " fills the tray")
			mouseAtPlot(120, 60)
		end
	end
	for _, tool in { "Pick", "Paint", "Sell", "Pick" } do
		press(tool)
		mouseAtPlot(90, 30, 2)
		frames(2)
	end
	press("Roofs off")
	press("Walls solid")
	press("Grid 1 stud")
	press("▲")
	check(BuildMode.state.level == 1, "the floor switcher goes up")
	mouseAtPlot(120, 60)
	press("▼")
	check(BuildMode.state.level == 0, "and down")
	check(#errors == warned, "no warnings from any of it")
end)

run("leaving Build mode", function()
	press("Done")
	check(not BuildMode.isActive(), "Done leaves Build mode")
	check(ws:FindFirstChild("BuildGhost") == nil and ws:FindFirstChild("BuildMarkers") == nil, "and tidies up")
	check(BuildMode.enter(), "and it opens again")
	frames(2)
	press("Furniture")
	local tray = gui:FindFirstChild("Tray", true)
	local cards = Fake.find(tray, function(d)
		return d:IsA("TextButton") and Fake.shown(d) and labelOf(d):find("🪙", 1, true) ~= nil
	end)
	cards[2].Activated:Fire()
	frames(2)
	local before = count("items")
	mouseAtPlot(136, 88)
	click()
	check(count("items") == before + 1, "placing still works the second time round")
end)

print(
	string.format(
		"\nbuild client sim: %s (%d warnings)",
		if failures == 0 then "all passed" else failures .. " failed",
		#errors
	)
)
for _, e in errors do
	print("  warning: " .. e)
end
if failures > 0 then
	process.exit(1)
end
