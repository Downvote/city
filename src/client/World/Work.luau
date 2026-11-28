-- Working at a workplace yourself, on this screen. The user: "also, allow players to interact and
-- work at work areas". The server (Services/Work) puts a prompt at every workplace and stands you
-- at its spot when you hold E at one on your own plot. This side shows those prompts on your own
-- plot only (and not while the place's villager is in for the day, nor in Build mode), words the
-- one you are at "Stop work", plays the job's motion on your body (your own animation for it, so
-- R6 and R15 both work; Roblox's own for R15 when the body has none), puts a small notice at the
-- foot of the screen (where you are working, what you have earned today and how to stop), and
-- asks the server to stop as soon as you move, jump, sit or open Build mode. The camera stays
-- where you have it. The notice also shows the player's skill at the job and its bar (the user:
-- "each skill also has a level/experience bar, which you gain while doing the work"), kept up by
-- the server's `Work` { skill, cap } every second or so (Sim/Skills).

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
local Catalog = require(Shared.Build.Catalog)
local Jobs = require(Shared.Data.Jobs)

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
	toollunge = "rbxassetid://522638767",
}

local W, H = 400, 84 -- the notice
local SHOWN = UDim2.new(0.5, 0, 1, -20)
local HIDDEN = UDim2.new(0.5, 0, 1, H + 40)
local SLIDE = TweenInfo.new(0.24, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

type Skill = { name: string, level: number, into: number, need: number, top: boolean? }
type Job = {
	plot: number,
	key: string,
	name: string,
	act: string,
	beat: number,
	today: number,
	cap: number,
	skill: Skill?,
}

local current: Job? = nil
local token = 0 -- a new one for every start and stop: what belongs to an old one stands down
local asked = false -- a stop was asked of the server for this one
local track: AnimationTrack? = nil
local watch: RBXScriptConnection? = nil
local notice: Frame? = nil
local title: TextLabel? = nil
local line: TextLabel? = nil
local skillText: TextLabel? = nil
local skillFill: Frame? = nil
local prompts: { [ProximityPrompt]: boolean } = {}

-- The notice ------------------------------------------------------------------------------------

-- What it says: where, and the day's pay so far with how to stop.
function Work.words(name: string, today: number, cap: number): (string, string)
	return Text.fill("Working at the {place}", { place = string.lower(name) }),
		Text.fill("{n} of {cap} coins today. Move to stop.", { n = Text.commas(today), cap = Text.commas(cap) })
end

-- What it says about the skill (Sim/PlayerWork.skillLine), and how full its bar is.
function Work.skillWords(skill: Skill): (string, number)
	local ratio = if skill.top then 1 elseif skill.need > 0 then skill.into / skill.need else 0
	return PlayerWork.skillLine(skill.name, skill.level, skill.top), math.clamp(ratio, 0, 1)
end

-- The job's own icon at the notice's left end (Data/Jobs: the user, "for work and news, make
-- different icons for different news and work types"), in white on the glass. Drawn again only
-- when the job changes.
function Work.mark(pill: Frame, icon: string)
	local old = pill:FindFirstChild("Mark")
	if old and old:GetAttribute("Icon") == icon then
		return
	end
	if old then
		old:Destroy()
	end
	local mark = Icons.make(icon, 34, {
		Name = "Mark",
		Parent = pill,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 16, 0.5, 0),
		Color = T.White,
		Centre = true,
		ZIndex = pill.ZIndex + 1,
	})
	mark:SetAttribute("Icon", icon)
end

-- The icon for the workplace at plan key `key` (its job's, a briefcase if it can't be told).
function Work.iconAt(key: string?): string
	local item = key and State.plan and State.plan.items[key]
	local def = item and Catalog.get(item.id)
	return Jobs.icon(def and def.job)
end

-- The notice itself: a slab of the dark glass over the 3D view with the job's icon at its left
-- end, two lines in white (the glass is dark in both looks) and the skill with its bar under them.
-- Returns it, its two lines, the skill's words and the bar's fill.
function Work.card(parent: Instance?, icon: string?): (Frame, TextLabel, TextLabel, TextLabel, Frame)
	local pill = Kit.darkPill({
		Name = "WorkNotice",
		Size = UDim2.fromOffset(W, H),
		AnchorPoint = Vector2.new(0.5, 1),
		Position = HIDDEN,
		Parent = parent,
	})
	Work.mark(pill, icon or "briefcase")
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
	-- the skill: its name and level, then the bar to the next level
	local skill = Kit.text("", {
		Name = "Skill",
		Parent = pill,
		Size = UDim2.fromOffset(170, 18),
		Position = UDim2.fromOffset(62, 56),
		TextSize = 14,
		Color = T.White,
		Font = Kit.Fonts.Bold,
		Wrap = false,
		ZIndex = pill.ZIndex + 1,
	})
	skill.TextTruncate = Enum.TextTruncate.AtEnd
	local track, fill = Kit.bar({
		Name = "SkillBar",
		Parent = pill,
		Size = UDim2.new(1, -(62 + 178 + 22), 0, 8),
		Position = UDim2.fromOffset(62 + 178, 61),
		Track = T.Dark,
	}, 0, T.Yellow)
	track.ZIndex = pill.ZIndex + 1
	fill.ZIndex = pill.ZIndex + 2
	return pill, top, under, skill, fill
end

local function showNotice()
	local job = current
	if not job then
		return
	end
	if not notice or not notice.Parent then
		notice, title, line, skillText, skillFill = Work.card(Kit.root())
	end
	Work.mark(notice :: Frame, Work.iconAt(job.key))
	local a, b = Work.words(job.name, job.today, job.cap)
	if title and line then
		title.Text, line.Text = a, b
	end
	local skill = job.skill
	if skill and skillText and skillFill then
		local words, ratio = Work.skillWords(skill)
		skillText.Text = words
		skillFill.Size = UDim2.fromScale(ratio, 1)
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
		or (
			type(key) == "string"
			and PlayerWork.staffedBy(State.data, key, Lighting.ClockTime, dayIndex(), os.time()) == nil
		)
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

-- The skill as the server sent it, checked.
local function skillFrom(raw: any): Skill?
	if type(raw) ~= "table" or type(raw.name) ~= "string" or type(raw.level) ~= "number" then
		return nil
	end
	return {
		name = raw.name,
		level = raw.level,
		into = if type(raw.into) == "number" then raw.into else 0,
		need = if type(raw.need) == "number" then raw.need else 0,
		top = raw.top == true,
	}
end

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
		skill = skillFrom(msg.skill),
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
		elseif msg.on == nil and msg.skill ~= nil then
			-- the skill's bar as it fills, and the day's cap when a level raised it
			local job = current
			if job then
				job.skill = skillFrom(msg.skill) or job.skill
				if type(msg.cap) == "number" then
					job.cap = msg.cap
				end
				showNotice()
			end
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
