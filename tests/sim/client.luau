--!nocheck
-- The game's client on fake Roblox instances (tests/sim/fake.luau), talking to the real server
-- Build service with its data and plot services stubbed. Requiring this boots it: the client's
-- State, BuildMode and BuildUI are loaded and Build mode can be driven with the helpers it
-- returns (mouse moves over the plot, clicks, drags, pressing buttons by what they show).
-- tests/sim/build_client.luau and tools/preview/ui_dump.luau use it.

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

-- task: spawned threads really wait, and frames() wakes them on the fake clock, so loops like
-- "every second, update the clock" run one step per wake instead of spinning forever
local sleeping = {} -- { co, at }
local ours = setmetatable({}, { __mode = "k" })
local function resume(co, ...)
	local ok, err = coroutine.resume(co, ...)
	if not ok then
		env.warn("task error: " .. tostring(err) .. "\n" .. debug.traceback(co))
	end
end
env.task = {
	spawn = function(f, ...)
		local co = if type(f) == "thread" then f else coroutine.create(f)
		ours[co] = true
		resume(co, ...)
		return co
	end,
	defer = function(f, ...)
		local co = if type(f) == "thread" then f else coroutine.create(f)
		ours[co] = true
		resume(co, ...)
		return co
	end,
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
	cancel = function(co)
		for i, e in sleeping do
			if e.co == co then
				table.remove(sleeping, i)
				break
			end
		end
	end,
}
local function wake()
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
-- Lune's two-value ColorSequence.new(a, b) and NumberSequence.new(a, b) drop the second value
-- (every gradient came out flat); Roblox's don't. Build them from keypoints instead.
env.ColorSequence = setmetatable({
	new = function(a, b)
		if rawTypeof(a) == "Color3" then
			return roblox.ColorSequence.new({
				roblox.ColorSequenceKeypoint.new(0, a),
				roblox.ColorSequenceKeypoint.new(1, b or a),
			})
		end
		return roblox.ColorSequence.new(a)
	end,
}, { __index = roblox.ColorSequence })
env.NumberSequence = setmetatable({
	new = function(a, b)
		if type(a) == "number" then
			return roblox.NumberSequence.new({
				roblox.NumberSequenceKeypoint.new(0, a),
				roblox.NumberSequenceKeypoint.new(1, b or a),
			})
		end
		return roblox.NumberSequence.new(a)
	end,
}, { __index = roblox.NumberSequence })
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
	BulkMoveTo = function(_, parts, frames)
		for i, part in parts do
			part.CFrame = frames[i]
		end
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
-- a real (fake) instance, so the client can look through the effects it holds
local lighting = Fake.new("Folder")
lighting.Name = "Lighting"
Fake.extend(lighting, { ClockTime = 12 })
Harness.addService("Lighting", lighting)
Harness.addService("Debris", { AddItem = function() end })
Harness.addService("ProximityPromptService", { PromptTriggered = Fake.signal() })
-- buying passes and gems (Controllers/Purchase): what the client asked Roblox to sell, in order
local prompted = {}
Harness.addService("MarketplaceService", {
	PromptGamePassPurchase = function(_, _, id)
		table.insert(prompted, { pass = id })
	end,
	PromptProductPurchase = function(_, _, id)
		table.insert(prompted, { product = id })
	end,
	PromptGamePassPurchaseFinished = Fake.signal(),
	PromptProductPurchaseFinished = Fake.signal(),
})

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

-- Runs n frames. `dt` (a sixtieth of a second by default) lets a test run the clock on faster.
local function frames(n, dt)
	local step = dt or 1 / 60
	for _ = 1, n or 2 do
		now += step
		RS.RenderStepped:Fire(step)
		RS.Heartbeat:Fire(step)
		wake()
	end
end

-- lets the fake clock run on: waits and delays come due
local function advance(seconds)
	local steps = math.max(1, math.floor(seconds * 10))
	for _ = 1, steps do
		now += seconds / steps
		wake()
	end
	frames(1)
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
	-- by what the button shows, or failing that by its name
	local found = buttons(function(b)
		return labelOf(b):find(text, 1, true) ~= nil
	end)
	if #found == 0 then
		found = buttons(function(b)
			return b.Name == text
		end)
	end
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

return {
	Harness = Harness,
	Fake = Fake,
	env = env,
	ws = ws,
	cam = cam,
	player = player,
	playerGui = playerGui,
	UIS = UIS,
	RS = RS,
	errors = errors,
	calls = calls,
	profile = profile,
	remoteFn = remoteFn,
	remoteEvent = remoteEvent,
	prompted = prompted, -- what Controllers/Purchase asked Roblox to sell
	buildFolder = buildFolder,
	State = State,
	Kit = Kit,
	Skin = Harness.require(CLIENT .. "UI.Skin"),
	BuildMode = BuildMode,
	BuildUI = BuildUI,
	CLIENT = CLIENT,
	gui = gui,
	frames = frames,
	advance = advance,
	mouseAtPlot = mouseAtPlot,
	input = input,
	click = click,
	drag = drag,
	buttons = buttons,
	labelOf = labelOf,
	press = press,
	count = count,
	clientCount = clientCount,
	check = check,
	run = run,
	failures = function()
		return failures
	end,
	setGuiAt = function(list)
		guiAt = list
	end,
	setMouse = function(v)
		mouse = v
	end,
	getMouse = function()
		return mouse
	end,
}
