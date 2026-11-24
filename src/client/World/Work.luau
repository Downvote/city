-- Working at a workplace yourself, on this screen. The user: "also, allow players to interact and
-- work at work areas". The server (Services/Work) puts a prompt at every workplace and stands you
-- at its spot when you hold E at one on your own plot. This side shows those prompts on your own
-- plot only (and not while the place's villager is in for the day, nor in Build mode), words the
-- one you are at "Stop work", plays the job's motion on your body (your own animation for it, so
-- R6 and R15 both work; Roblox's own for R15 when the body has none), puts a small notice at the
-- foot of the screen (where you are working, what you have earned today and how to stop), and
-- asks the server to stop as soon as you move, jump, sit or open Build mode. The camera stays
-- where you have it.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Tuning = require(Shared.Config.Tuning)
local Remotes = require(Shared.Net.Remotes)
local Text = require(Shared.Util.Text)
local PlayerWork = require(Shared.Sim.PlayerWork)

local Kit = require(script.Parent.Parent.UI.Kit)
local Icons = require(script.Parent.Parent.UI.Icons)
local State = require(script.Parent.Parent.Controllers.State)
local BuildMode = require(script.Parent.Parent.Build.BuildMode)

local Work = {}

local T = Kit.Theme
local player = Players.LocalPlayer

-- Roblox's own animations for an R15 body with no Animate script to read them from (Npc's).
local R15 = {
	wave = "rbxassetid://507770239",
	point = "rbxassetid://507770453",
	dance = "rbxassetid://507771019",
	dance2 = "rbxassetid://507776043",
	laugh = "rbxassetid://507770818",
	cheer = "rbxassetid://507770677",
	toolslash = "rbxassetid://522635514",
}

local W, H = 400, 60 -- the notice
local SHOWN = UDim2.new(0.5, 0, 1, -20)
local HIDDEN = UDim2.new(0.5, 0, 1, H + 40)
local SLIDE = TweenInfo.new(0.24, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

type Job = { plot: number, key: string, name: string, act: string, beat: number, today: number, cap: number }

local current: Job? = nil
local token = 0 -- a new one for every start and stop: what belongs to an old one stands down
local asked = false -- a stop was asked of the server for this one
local track: AnimationTrack? = nil
local watch: RBXScriptConnection? = nil
local notice: Frame? = nil
local title: TextLabel? = nil
local line: TextLabel? = nil
local prompts: { [ProximityPrompt]: boolean } = {}

-- The notice ------------------------------------------------------------------------------------

-- What it says: where, and the day's pay so far with how to stop.
function Work.words(name: string, today: number, cap: number): (string, string)
	return Text.fill("Working at the {place}", { place = string.lower(name) }),
		Text.fill("{n} of {cap} coins today. Move to stop.", { n = Text.commas(today), cap = Text.commas(cap) })
end

-- The notice itself: a slab of the dark glass over the 3D view with a coin at its left end and
-- two lines in white (the glass is dark in both looks). Returns it and its two lines.
function Work.card(parent: Instance?): (Frame, TextLabel, TextLabel)
	local pill = Kit.darkPill({
		Name = "WorkNotice",
		Size = UDim2.fromOffset(W, H),
		AnchorPoint = Vector2.new(0.5, 1),
		Position = HIDDEN,
		Parent = parent,
	})
	Icons.make("coin", 34, {
		Name = "Coin",
		Parent = pill,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 16, 0.5, 0),
		ZIndex = pill.ZIndex + 1,
	})
	local top = Kit.title("", {
		Name = "Title",
		Parent = pill,
		Size = UDim2.new(1, -74, 0, 24),
		Position = UDim2.fromOffset(62, 7),
		TextSize = 20,
		Color = T.White,
		Outline = T.Glass,
		Wrap = false,
		ZIndex = pill.ZIndex + 1,
	})
	top.TextTruncate = Enum.TextTruncate.AtEnd
	local under = Kit.text("", {
		Name = "Line",
		Parent = pill,
		Size = UDim2.new(1, -74, 0, 20),
		Position = UDim2.fromOffset(62, 32),
		TextSize = 15,
		Color = T.White,
		Wrap = false,
		ZIndex = pill.ZIndex + 1,
	})
	under.TextTruncate = Enum.TextTruncate.AtEnd
	return pill, top, under
end

local function showNotice()
	local job = current
	if not job then
		return
	end
	if not notice or not notice.Parent then
		notice, title, line = Work.card(Kit.root())
	end
	local a, b = Work.words(job.name, job.today, job.cap)
	if title and line then
		title.Text, line.Text = a, b
	end
	-- (out of the way while a scene is up or Build mode has the screen)
	local away = State.data.talking == true or BuildMode.isActive()
	TweenService:Create(notice :: Frame, SLIDE, { Position = if away then HIDDEN else SHOWN }):Play()
end

local function hideNotice()
	local n = notice
	if n and n.Parent then
		TweenService:Create(n, SLIDE, { Position = HIDDEN }):Play()
	end
end

-- The prompts ------------------------------------------------------------------------------------

local function dayIndex(): number
	return math.floor(workspace:GetServerTimeNow() / Tuning.Day.Length)
end

-- A prompt shows on this player's own plot only, not in Build mode, and not where it is a
-- villager's working day (PlayerWork.staffedBy, from the town as the client has it): the
-- server says no to those anyway. The one they are at says "Stop work".
local function refresh(prompt: ProximityPrompt)
	local plot = prompt:GetAttribute("Plot")
	local key = prompt:GetAttribute("BuildKey")
	local own = plot ~= nil and plot == player:GetAttribute("Plot")
	local job = current
	local here = job ~= nil and job.plot == plot and job.key == key
	prompt.ActionText = if here then PlayerWork.StopAction else PlayerWork.Action
	local free = here
		or (type(key) == "string" and PlayerWork.staffedBy(State.data, key, Lighting.ClockTime, dayIndex(), os.time()) == nil)
	prompt.Enabled = own and free and not BuildMode.isActive()
end

local function refreshAll()
	for prompt in prompts do
		if prompt.Parent then
			refresh(prompt)
		else
			prompts[prompt] = nil
		end
	end
end

-- The motion ------------------------------------------------------------------------------------

-- The animation id the body's own Animate script has for an action, or Roblox's for an R15 body.
local function animId(char: Model, act: string): string?
	local animate = char:FindFirstChild("Animate")
	local folder = animate and animate:FindFirstChild(act)
	if folder then
		for _, a in folder:GetChildren() do
			if a:IsA("Animation") and a.AnimationId ~= "" then
				return a.AnimationId
			end
		end
	end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if hum and hum.RigType == Enum.HumanoidRigType.R15 then
		return R15[act]
	end
	return nil
end

-- Goes at the work: the motion, and again every `beat` seconds once it has played through.
local function playMotion(mine: number, act: string, beat: number)
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local animator = hum and hum:FindFirstChildOfClass("Animator")
	local id = char and animId(char, act)
	if not animator or not id then
		return
	end
	local anim = Instance.new("Animation")
	anim.AnimationId = id
	local ok, loaded = pcall(function()
		return animator:LoadAnimation(anim)
	end)
	if not ok or not loaded then
		return
	end
	local t: AnimationTrack = loaded
	t.Priority = Enum.AnimationPriority.Action
	track = t
	task.spawn(function()
		while token == mine do
			if not t.IsPlaying then
				t:Play(0.15)
			end
			task.wait(math.max(0.5, beat))
		end
	end)
end

local function stopMotion()
	local t = track
	track = nil
	if t then
		t:Stop(0.2)
		task.delay(0.3, function()
			t:Destroy()
		end)
	end
end

-- Starting and stopping ----------------------------------------------------------------------------

local function finish()
	if not current then
		return
	end
	current = nil
	token += 1
	if watch then
		watch:Disconnect()
		watch = nil
	end
	stopMotion()
	hideNotice()
	refreshAll()
end

-- Stops at once on this screen and asks the server to stop paying (it checks for itself too).
local function askStop()
	if not current or asked then
		return
	end
	asked = true
	finish()
	task.spawn(function()
		pcall(function()
			Remotes.fn("WorkStop"):InvokeServer()
		end)
	end)
end

local function begin(msg: any)
	finish()
	current = {
		plot = msg.plot,
		key = msg.key,
		name = if type(msg.name) == "string" then msg.name else "",
		act = if type(msg.act) == "string" then msg.act else Tuning.Jobs.Player.Act,
		beat = if type(msg.beat) == "number" then msg.beat else Tuning.Jobs.Player.Beat,
		today = if type(msg.today) == "number" then msg.today else 0,
		cap = if type(msg.cap) == "number" then msg.cap else Tuning.Jobs.Player.DayCap,
	}
	token += 1
	asked = false
	local mine = token
	local job = current :: Job
	playMotion(mine, job.act, job.beat)
	-- moving, a jump or a seat stops it (the server sees a walk off for itself as well)
	watch = RunService.Heartbeat:Connect(function()
		local char = player.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if not hum or hum.Health <= 0 or hum.MoveDirection.Magnitude > 0.1 or hum.Jump or hum.Sit then
			askStop()
		end
	end)
	showNotice()
	refreshAll()
end

function Work.isWorking(): boolean
	return current ~= nil
end

function Work.start()
	Remotes.event("Work").OnClientEvent:Connect(function(msg: any)
		if type(msg) ~= "table" then
			return
		end
		if msg.on == true and type(msg.plot) == "number" and type(msg.key) == "string" then
			begin(msg)
		else
			finish()
		end
	end)
	-- what you have earned today comes with the pay packets (World/Earnings shows the coin)
	Remotes.event("Earned").OnClientEvent:Connect(function(msg: any)
		local job = current
		if not job or type(msg) ~= "table" or type(msg.lines) ~= "table" then
			return
		end
		for _, l in msg.lines do
			if type(l) == "table" and l.you == true and type(l.today) == "number" then
				job.today = l.today
				showNotice()
			end
		end
	end)
	BuildMode.Changed:Connect(function(what)
		if what == "active" then
			if BuildMode.isActive() then
				askStop()
			end
			refreshAll()
		end
	end)
	State.on("talking", function()
		if current then
			showNotice()
		end
	end)
	player.CharacterAdded:Connect(finish)
	local function seen(prompt: Instance)
		if prompt:IsA("ProximityPrompt") then
			prompts[prompt] = true
			refresh(prompt)
		end
	end
	CollectionService:GetInstanceAddedSignal(PlayerWork.Tag):Connect(seen)
	CollectionService:GetInstanceRemovedSignal(PlayerWork.Tag):Connect(function(prompt)
		prompts[prompt :: any] = nil
	end)
	for _, prompt in CollectionService:GetTagged(PlayerWork.Tag) do
		seen(prompt)
	end
	-- the hour and the villagers' days move on: a look at every prompt each second
	task.spawn(function()
		while true do
			task.wait(1)
			refreshAll()
		end
	end)
end

return Work
