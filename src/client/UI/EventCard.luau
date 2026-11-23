-- A random event as it plays out in town. The user: "in the case of random villager text events,
-- make this only happen when the player chooses to watch". So an event never takes the screen by
-- itself: a small prompt comes up at the bottom of the screen with the event's name and a Watch
-- button, and the event goes on in the town as it would anyway. Pressing Watch points the camera
-- at it and puts up the dialogue scene (UI/Dialogue): the villagers in it slide in, and the line
-- being said is typed into the textbox, then the lines after it, with the villagers' names picked
-- out in colour. When the event asks what you do, the prompt says so ("They want your say"),
-- Watch becomes Answer and a thin bar runs down the time left; the answers are pills in the
-- scene's textbox. Nobody is made to answer: the server picks the gentle option when the time is
-- up. Stop (or the event ending) takes the scene down and gives the camera back.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Remotes = require(Shared.Net.Remotes)
local Tuning = require(Shared.Config.Tuning)
local Text = require(Shared.Util.Text)
local Colors = require(Shared.Util.Colors)

local Kit = require(script.Parent.Kit)
local Dialogue = require(script.Parent.Dialogue)
local State = require(script.Parent.Parent.Controllers.State)

local EventCard = {}

local T = Kit.Theme
local player = Players.LocalPlayer

local holder: Frame -- the prompt
local titleLabel: TextLabel
local subLabel: TextLabel
local watchButton: TextButton
local timeTrack: Frame
local timeFill: Frame
local scene: any = nil -- the dialogue scene, while you watch
local current: any = nil
local queue: { any } = {}
local playing = false
local watching = false -- the camera is on the event
local watchConn: RBXScriptConnection? = nil
local hidden = false -- while you build or make a villager, the prompt and the scene step aside
local lineNow: any = nil -- the line being said right now: { who, text }
local asking = false -- the event is waiting for your answer
local askedAt = 0
local skip = false
local typing = 0 -- goes up with every line typed, so an old one stops

-- The villagers' names in a warm colour.
local NAME_COLOR = "#F07A3A"
local function escape(s: string): string
	return (s:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"))
end
local function richify(text: string): string
	local out = escape(text)
	local names = {}
	if current and current.names then
		for _, n in current.names do
			if type(n) == "string" and n ~= "" then
				table.insert(names, escape(n))
			end
		end
	end
	table.sort(names, function(a, b)
		return #a > #b
	end)
	for _, n in names do
		local pattern = n:gsub("%p", "%%%0")
		local replacement = ('<font color="' .. NAME_COLOR .. '">' .. n .. "</font>"):gsub("%%", "%%%%")
		out = out:gsub(pattern, replacement)
	end
	return out
end

-- The camera ---------------------------------------------------------------------------------------------

local function stopCamera()
	watching = false
	if watchConn then
		watchConn:Disconnect()
		watchConn = nil
	end
	local cam = workspace.CurrentCamera
	local BuildMode = require(script.Parent.Parent.Build.BuildMode)
	if cam and not BuildMode.isActive() then
		cam.CameraType = Enum.CameraType.Custom
		local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if hum then
			cam.CameraSubject = hum
		end
	end
end

local function startCamera()
	local focus = current and current.focus
	if not focus or not focus.Parent then
		return
	end
	local BuildMode = require(script.Parent.Parent.Build.BuildMode)
	if BuildMode.isActive() then
		return
	end
	watching = true
	local cam = workspace.CurrentCamera
	cam.CameraType = Enum.CameraType.Scriptable
	local angle = 0
	watchConn = RunService.RenderStepped:Connect(function(dt)
		if not focus.Parent then
			stopCamera()
			return
		end
		angle += dt * 0.15
		local root = focus:FindFirstChild("HumanoidRootPart")
		local center = if root and root:IsA("BasePart") then root.Position else focus:GetPivot().Position
		local offset = Vector3.new(math.sin(angle) * 16, 8, math.cos(angle) * 16)
		cam.CFrame =
			cam.CFrame:Lerp(CFrame.lookAt(center + offset, center + Vector3.new(0, 1.5, 0)), math.min(1, dt * 4))
	end)
end

-- The prompt ---------------------------------------------------------------------------------------------

-- Is a menu or a dialog up (a Kit.panel dims the screen behind it)? The prompt and the scene
-- make way for it.
local function menuUp(): boolean
	for _, child in Kit.root():GetChildren() do
		if child:IsA("GuiObject") and child.Visible and child:FindFirstChild("Dim") then
			return true
		end
	end
	return false
end

-- What the prompt says: what's going on, or that they want your say (with the time left).
local function updatePrompt()
	if not holder then
		return
	end
	holder.Visible = playing and not hidden and scene == nil and not menuUp()
	if not current then
		return
	end
	titleLabel.Text = if type(current.title) == "string" and current.title ~= ""
		then current.title
		else "Something's up"
	if asking then
		subLabel.Text = "They want your say"
		watchButton.Text = "Answer"
		Kit.setButtonColor(watchButton, T.Yellow, T.Dark)
	else
		subLabel.Text = "Going on in town now"
		watchButton.Text = "Watch"
		Kit.setButtonColor(watchButton, T.Purple, T.White)
	end
	timeTrack.Visible = asking
end

-- The scene ----------------------------------------------------------------------------------------------

local function actorOf(letter: string): any
	local ev = current
	if not ev then
		return nil
	end
	local name = ev.names and ev.names[letter]
	if type(name) ~= "string" then
		return nil
	end
	local vid = ev.actors and ev.actors[letter]
	local v = if type(vid) == "string" then State.villager(vid) else nil
	local model = Dialogue.modelOf(vid)
	if not model and ev.focus and ev.focus.Parent and ev.focus:GetAttribute("Vid") == vid then
		model = ev.focus
	end
	return {
		key = letter,
		name = name,
		color = Colors.fromHex(v and v.color, T.Orange),
		model = model,
		vid = vid,
	}
end

-- The letters of everyone a line brings in: who says it, and anyone it names.
local function cast(l: any): { string }
	local out = {}
	local ev = current
	if not ev or not l then
		return out
	end
	if type(l.who) == "string" and ev.names[l.who] then
		table.insert(out, l.who)
	end
	local letters = {}
	for letter in ev.names do
		table.insert(letters, letter)
	end
	table.sort(letters)
	for _, letter in letters do
		local name = ev.names[letter]
		if type(name) == "string" and name ~= "" and letter ~= l.who and string.find(l.text, name, 1, true) then
			table.insert(out, letter)
		end
	end
	return out
end

-- Everyone the event has brought in so far, in order, watched or not.
local seen: { string } = {}
local function note(l: any)
	for _, letter in cast(l) do
		if not table.find(seen, letter) then
			table.insert(seen, letter)
		end
	end
end

-- Brings in whoever a line needs (and, the first time, whoever came before it), and asks the
-- server for a model the client can't find.
local function bring(l: any)
	local s = scene
	if not s then
		return
	end
	local need = table.clone(seen)
	for _, letter in cast(l) do
		if not table.find(need, letter) then
			table.insert(need, letter)
		end
	end
	for _, letter in need do
		if not s.has(letter) then
			local actor = actorOf(letter)
			if actor then
				s.join(actor)
				if not actor.model and actor.vid then
					task.spawn(function()
						local ok, found = pcall(function()
							return Remotes.fn("VillagerFocus"):InvokeServer(actor.vid)
						end)
						if ok and typeof(found) == "Instance" and found:IsA("Model") and scene == s then
							s.found(letter, found)
						end
					end)
				end
			end
		end
	end
end

-- Types a line into the scene's box, a couple of letters at a time.
local function typeOut(text: string)
	local s = scene
	if not s then
		return
	end
	typing += 1
	local mine = typing
	local label: TextLabel = s.words
	label.Text = richify(text)
	label.MaxVisibleGraphemes = 0
	s.more.Visible = false
	task.spawn(function()
		local count = utf8.len(text) or #text
		local shown = 0
		while shown < count and typing == mine and label.Parent and label.MaxVisibleGraphemes ~= -1 do
			shown = math.min(count, shown + 2)
			label.MaxVisibleGraphemes = shown
			task.wait(0.03)
		end
		if typing == mine then
			label.MaxVisibleGraphemes = -1
			typing += 1
			if scene == s then
				s.more.Visible = not asking
			end
		end
	end)
end

-- Shows a line in the scene: who is in it, who is talking, the words.
local function showLine(l: any)
	local s = scene
	if not s or not l then
		return
	end
	bring(l)
	s.speak(if type(l.who) == "string" then l.who else nil)
	typeOut(l.text)
end

local function clearAnswers()
	local s = scene
	if not s then
		return
	end
	for _, c in s.answers:GetChildren() do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
end

-- The answers, as pills in the box under the words.
local function showAnswers()
	local s = scene
	local ev = current
	if not s or not ev or not ev.choices then
		return
	end
	clearAnswers()
	s.speak(nil)
	typeOut("What do you do?")
	local n = #ev.choices
	local grid = Kit.grid(s.answers, UDim2.new(1 / math.max(1, math.min(n, 3)), -8, 0, 44), 8)
	grid.FillDirectionMaxCells = 3
	for i, c in ev.choices do
		local label = c.text
		local affordable = c.cost == nil or (State.data.coins or 0) >= c.cost
		if c.cost then
			label = Text.fill("{text} ({cost} coins)", { text = label, cost = Text.commas(c.cost) })
		end
		Dialogue.answer(richify(label), {
			Name = "Choice" .. i,
			Parent = s.answers,
			LayoutOrder = i,
			TextSize = 17,
			Rich = true,
			Disabled = not affordable,
		}, function()
			if not affordable or not asking then
				return
			end
			asking = false
			clearAnswers()
			updatePrompt()
			task.spawn(function()
				local ok, err = Remotes.fn("EventChoose"):InvokeServer(ev.token, i)
				if not ok and err and scene then
					typeOut(err)
				end
			end)
		end)
	end
end

local function closeScene(now: boolean?)
	if scene then
		local s = scene
		scene = nil
		typing += 1
		s.close(now)
	end
	if watching then
		stopCamera()
	end
	updatePrompt()
end

-- Puts the scene up: the camera goes to the event, the villagers slide in and the line being said
-- now is typed out (the lines before it are not said again).
local function openScene()
	if scene or not current or hidden then
		return
	end
	local ev = current
	scene = Dialogue.open({
		Name = "EventScene",
		Caption = if type(ev.title) == "string" then ev.title else nil,
		OnClick = function()
			skip = true
		end,
	})
	Dialogue.answer("Stop watching", {
		Name = "Stop",
		Parent = scene.tools,
		Size = UDim2.fromOffset(150, 32),
		TextSize = 15,
		Icon = "close",
	}, function()
		closeScene()
	end)
	updatePrompt()
	startCamera()
	if asking then
		bring(lineNow)
		showAnswers()
	elseif lineNow then
		showLine(lineNow)
	end
end

-- The lines -----------------------------------------------------------------------------------------------

-- Says a line: in the scene if it is up, and in any case it takes its time, so the line that is
-- "now" moves on whether or not anyone watches. A click on the box moves on sooner.
local function say(l: any)
	lineNow = l
	note(l)
	if scene then
		showLine(l)
	end
	local t = os.clock()
	local wait = math.clamp(#l.text / 18, 2.2, 4.2)
	skip = false
	while os.clock() - t < wait and not skip do
		task.wait(0.05)
	end
	skip = false
end

local function sayAll(lines: { any })
	for _, l in lines do
		if type(l) == "table" and type(l.text) == "string" then
			say(l)
		end
	end
end

local function play(ev: any)
	playing = true
	current = ev
	asking = false
	lineNow = nil
	seen = {}
	updatePrompt()
	if not hidden then
		Kit.popIn(holder)
	end
	sayAll(ev.lines or {})
	if ev.choices and current == ev and not ev.ended and not ev.after then
		asking = true
		askedAt = os.clock()
		lineNow = { text = "What do you do?" }
		updatePrompt()
		if scene then
			showAnswers()
		end
	end
	while current == ev and not ev.ended do
		if ev.after then
			local lines = ev.after
			ev.after = nil
			asking = false
			clearAnswers()
			updatePrompt()
			sayAll(lines)
		end
		task.wait(0.1)
	end
	asking = false
	clearAnswers()
	if ev.after then
		local lines = ev.after
		ev.after = nil
		sayAll(lines)
	end
	if ev.notices and #ev.notices > 0 and scene then
		-- how it turned out, a moment, before the scene goes
		scene.speak(nil)
		typeOut(table.concat(ev.notices, "\n"))
		task.wait(3)
	end
	closeScene()
	holder.Visible = false
	current = nil
	lineNow = nil
	playing = false
	local nextEv = table.remove(queue, 1)
	if nextEv then
		task.spawn(play, nextEv)
	end
end

-- Is an event going on right now (watched or not)? The talk card (UI/TalkCard) keeps out of its
-- way.
function EventCard.isPlaying(): boolean
	return playing
end

-- Is the scene of an event up (the player is watching it)?
function EventCard.isWatching(): boolean
	return scene ~= nil
end

function EventCard.setHidden(v: boolean)
	if v == hidden then
		return
	end
	hidden = v
	if hidden then
		closeScene(true)
	end
	updatePrompt()
end

function EventCard.start(_hud: any)
	local gui = Kit.root()
	-- the prompt: dark glass over the town at the bottom middle, its name and the Watch button
	holder = Kit.new("Frame", {
		Name = "EventCard",
		BackgroundColor3 = T.Glass,
		BackgroundTransparency = T.GlassAlpha,
		BorderSizePixel = 0,
		Size = UDim2.fromOffset(400, 60),
		Position = UDim2.new(0.5, 0, 1, -18),
		AnchorPoint = Vector2.new(0.5, 1),
		Visible = false,
		ZIndex = 20,
		Parent = gui,
	})
	holder:SetAttribute("KeepColors", true)
	Kit.corner(holder, "pill")
	Kit.rim(holder, T.White, 1.5, 0.78)
	Kit.softShadow(holder, 1)
	Kit.disc({
		Name = "Mark",
		Parent = holder,
		Size = 38,
		Position = UDim2.new(0, 11, 0.5, -19),
		Color = T.Orange,
		Icon = "people",
		ZIndex = 21,
	})
	titleLabel = Kit.new("TextLabel", {
		Name = "Title",
		Text = "",
		BackgroundTransparency = 1,
		Font = Kit.Fonts.Title,
		TextSize = 17,
		TextColor3 = T.White,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Size = UDim2.new(1, -184, 0, 22),
		Position = UDim2.fromOffset(60, 9),
		ZIndex = 21,
		Parent = holder,
	})
	subLabel = Kit.new("TextLabel", {
		Name = "Sub",
		Text = "",
		BackgroundTransparency = 1,
		Font = Kit.Fonts.Body,
		TextSize = 14,
		TextColor3 = T.Glass:Lerp(T.White, 0.62),
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, -184, 0, 18),
		Position = UDim2.fromOffset(60, 31),
		ZIndex = 21,
		Parent = holder,
	})
	watchButton = Kit.button("Watch", {
		Name = "Watch",
		Parent = holder,
		Size = UDim2.fromOffset(108, 40),
		Position = UDim2.new(1, -10, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
		TextSize = 16,
		Color = T.Purple,
		Radius = "pill",
		Icon = "eye",
		ZIndex = 21,
	}, function()
		openScene()
	end)
	-- the time left to answer, a thin bar along the prompt's foot
	timeTrack = Kit.new("Frame", {
		Name = "TimeLeft",
		BackgroundColor3 = T.Glass:Lerp(T.White, 0.16),
		BorderSizePixel = 0,
		Size = UDim2.new(1, -60, 0, 3),
		Position = UDim2.new(0, 30, 1, -5),
		Visible = false,
		ZIndex = 21,
		Parent = holder,
	})
	Kit.corner(timeTrack, "pill")
	timeFill = Kit.new("Frame", {
		Name = "Fill",
		BackgroundColor3 = T.Yellow,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 22,
		Parent = timeTrack,
	})
	Kit.corner(timeFill, "pill")
	task.spawn(function()
		while true do
			task.wait(0.2)
			if playing then
				-- a menu opening puts the scene away; the prompt waits under it
				if scene and menuUp() then
					closeScene()
				end
				local show = not hidden and scene == nil and not menuUp()
				if holder.Visible ~= show then
					updatePrompt()
				end
			end
			if asking then
				local left = 1 - (os.clock() - askedAt) / Tuning.Events.ChoiceTimeout
				timeFill.Size = UDim2.fromScale(math.clamp(left, 0, 1), 1)
			end
		end
	end)

	Remotes.event("EventShow").OnClientEvent:Connect(function(ev)
		if type(ev) ~= "table" then
			return
		end
		ev.names = if type(ev.names) == "table" then ev.names else {}
		if playing then
			table.insert(queue, ev)
		else
			task.spawn(play, ev)
		end
	end)
	Remotes.event("EventLine").OnClientEvent:Connect(function(msg)
		if current and type(msg) == "table" and current.token == msg.token then
			current.after = msg.lines
		end
	end)
	Remotes.event("EventEnd").OnClientEvent:Connect(function(msg)
		if type(msg) ~= "table" then
			return
		end
		local target = current
		if not target or target.token ~= msg.token then
			for _, q in queue do
				if q.token == msg.token then
					target = q
				end
			end
		end
		if target then
			target.notices = msg.notices
			target.ended = true
		end
	end)
end

return EventCard
