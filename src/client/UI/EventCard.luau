-- Tells a random event as it plays out in town, the way life sims do it: the event's name on a
-- banner, the words typed out in a big speech bubble near the top of the screen with the
-- villagers' names picked out in colour, the speaker on a name plate, a little arrow when you
-- can click on, and the choices as speech bubbles down the right. "Watch" points the camera at it.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Remotes = require(Shared.Net.Remotes)
local Text = require(Shared.Util.Text)

local Kit = require(script.Parent.Kit)
local Icons = require(script.Parent.Icons)
local State = require(script.Parent.Parent.Controllers.State)

local EventCard = {}

local T = Kit.Theme
local player = Players.LocalPlayer

local holder: Frame
local card: Frame
local bannerSlot: Frame
local ribbon: Frame? = nil
local speakerLabel: TextLabel
local plate: Frame
local bodyLabel: TextLabel
local moreArrow: Frame
local choiceRow: Frame
local watchButton: TextButton
local current: any = nil
local queue: { any } = {}
local playing = false
local watching = false
local watchConn: RBXScriptConnection? = nil
local hidden = false -- while you build or make a villager, the box steps aside and comes back after

local function stopWatching()
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
	if watchButton then
		watchButton.Text = "Watch"
	end
end

local function startWatching()
	local focus = current and current.focus
	if not focus or not focus.Parent then
		return
	end
	local BuildMode = require(script.Parent.Parent.Build.BuildMode)
	if BuildMode.isActive() then
		return
	end
	watching = true
	watchButton.Text = "Stop"
	local cam = workspace.CurrentCamera
	cam.CameraType = Enum.CameraType.Scriptable
	local angle = 0
	watchConn = RunService.RenderStepped:Connect(function(dt)
		if not focus.Parent then
			stopWatching()
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

local function clearChoices()
	for _, c in choiceRow:GetChildren() do
		if c:IsA("GuiButton") then
			c:Destroy()
		end
	end
end

-- Shows lines one after another, typed out. A click finishes the line; another moves on.
local skip = false
local typing = false
local function setSpeaker(name: string?)
	local changed = speakerLabel.Text ~= (name or "")
	speakerLabel.Text = name or ""
	plate.Visible = name ~= nil and name ~= ""
	if changed and plate.Visible then
		Kit.bump(plate, 0.25)
	end
end

-- The line as rich text, with the villagers' names in a warm colour.
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

local function typeOut(text: string)
	bodyLabel.Text = richify(text)
	bodyLabel.MaxVisibleGraphemes = 0
	moreArrow.Visible = false
	typing = true
	skip = false
	local count = utf8.len(text) or #text
	local shown = 0
	while shown < count and not skip do
		shown = math.min(count, shown + 2)
		bodyLabel.MaxVisibleGraphemes = shown
		task.wait(0.03)
	end
	bodyLabel.MaxVisibleGraphemes = -1
	typing = false
	skip = false
end

local function showLines(lines: { any })
	for _, l in lines do
		local name = l.who and current and current.names[l.who]
		setSpeaker(name)
		typeOut(l.text)
		moreArrow.Visible = true
		local t = os.clock()
		local wait = math.clamp(#l.text / 18, 2.2, 4.2)
		while os.clock() - t < wait and not skip do
			task.wait(0.05)
		end
		skip = false
		moreArrow.Visible = false
	end
end

local function showChoices(ev: any)
	clearChoices()
	for i, c in ev.choices do
		local label = c.text
		local affordable = c.cost == nil or (State.data.coins or 0) >= c.cost
		if c.cost then
			label = Text.fill("{text} ({cost} coins)", { text = label, cost = Text.commas(c.cost) })
		end
		local b = Kit.choice(richify(label), {
			Rich = true,
			Parent = choiceRow,
			LayoutOrder = i,
			Disabled = not affordable,
		})
		-- the choices pop up one after another
		local pop = b:FindFirstChild("Press") :: UIScale
		pop.Scale = 0.5
		TweenService:Create(
			pop,
			TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out, 0, false, i * 0.07),
			{ Scale = 1 }
		):Play()
		b.Activated:Connect(function()
			if not affordable then
				return
			end
			clearChoices()
			task.spawn(function()
				local ok, err = Remotes.fn("EventChoose"):InvokeServer(ev.token, i)
				if not ok and err then
					bodyLabel.Text = err
				end
			end)
		end)
	end
end

local function play(ev: any)
	playing = true
	current = ev
	clearChoices()
	-- a fresh ribbon each time: it's cut to the length of the event's name
	if ribbon then
		ribbon:Destroy()
		ribbon = nil
	end
	if ev.title and ev.title ~= "" then
		ribbon = Kit.ribbon(ev.title, {
			Parent = bannerSlot,
			Color = T.Coral,
			TextSize = 22,
			Position = UDim2.new(0.5, 0, 1, 0),
			AnchorPoint = Vector2.new(0.5, 1),
			ZIndex = 21,
		})
	end
	if not hidden then
		Kit.popIn(holder)
	end
	watchButton.Visible = ev.focus ~= nil
	showLines(ev.lines or {})
	if ev.choices and current == ev then
		setSpeaker(nil)
		typeOut("What do you do?")
		showChoices(ev)
	end
	while current == ev and not ev.ended do
		if ev.after then
			local lines = ev.after
			ev.after = nil
			clearChoices()
			showLines(lines)
		end
		task.wait(0.1)
	end
	if ev.after then
		clearChoices()
		showLines(ev.after)
		ev.after = nil
	end
	if ev.notices and #ev.notices > 0 then
		setSpeaker(nil)
		typeOut(table.concat(ev.notices, "\n"))
		task.wait(3)
	end
	holder.Visible = false
	if watching then
		stopWatching()
	end
	current = nil
	playing = false
	local nextEv = table.remove(queue, 1)
	if nextEv then
		task.spawn(play, nextEv)
	end
end

function EventCard.setHidden(v: boolean)
	if v == hidden then
		return
	end
	hidden = v
	if holder then
		holder.Visible = playing and not hidden
	end
end

function EventCard.start(_hud: any)
	local gui = Kit.root()
	holder = Kit.box({
		Name = "EventCard",
		Size = UDim2.fromOffset(620, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Position = UDim2.new(0.5, 0, 0, 96),
		AnchorPoint = Vector2.new(0.5, 0),
		Parent = gui,
		Visible = false,
	})
	holder.ZIndex = 20
	Kit.list(holder, 0, false, Enum.HorizontalAlignment.Center)

	-- the event's name on a banner above the bubble (made in play)
	bannerSlot = Kit.box({ Name = "Banner", Parent = holder, Size = UDim2.new(1, 0, 0, 50), LayoutOrder = 1 })
	Kit.box({ Parent = holder, Size = UDim2.fromOffset(10, 14), LayoutOrder = 2 })

	-- the speech bubble, its tail pointing down at the town
	local page
	page, card = Kit.bubble({
		Name = "Page",
		Parent = holder,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Radius = 38,
		Tail = "down",
		TailAt = 0.5,
		TailSize = 28,
		Border = Color3.fromRGB(255, 196, 150),
		BorderWidth = 4,
		Estimate = Vector2.new(620, 150),
		LayoutOrder = 3,
	})
	local _ = page
	local inner = Kit.box({ Parent = card, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y })
	Kit.pad(inner, 34, 26)
	Kit.list(inner, 10)

	-- the speaker's name plate sits on the bubble's top edge
	plate = Kit.frame({
		Parent = card,
		Size = UDim2.fromOffset(0, 32),
		AutomaticSize = Enum.AutomaticSize.X,
		Position = UDim2.fromOffset(30, -16),
		Color = T.Blue,
		Radius = "pill",
		Visible = false,
		ZIndex = 2,
	})
	Kit.pad(plate, 14, 0)
	speakerLabel = Kit.title("", {
		Parent = plate,
		Size = UDim2.fromOffset(0, 32),
		AutomaticSize = Enum.AutomaticSize.X,
		TextSize = 18,
		Color = T.White,
		Wrap = false,
	})

	watchButton = Kit.button("Watch", {
		Icon = "camera",
		Parent = card,
		Size = UDim2.fromOffset(112, 32),
		Position = UDim2.new(1, -130, 0, -16),
		TextSize = 14,
		Color = T.Purple,
		Radius = "pill",
	})
	watchButton.Activated:Connect(function()
		if watching then
			stopWatching()
		else
			startWatching()
		end
	end)

	bodyLabel = Kit.text("", {
		Parent = inner,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		TextSize = 24,
		Font = Kit.Fonts.Title,
		LayoutOrder = 1,
	})
	bodyLabel.RichText = true
	bodyLabel.LineHeight = 1.15
	moreArrow = Icons.make("down", 22, { Parent = card, Position = UDim2.new(1, -44, 1, -32), Tint = T.Coral })
	moreArrow.Visible = false
	task.spawn(function()
		local t = 0
		while true do
			t += task.wait(0.05)
			moreArrow.Position = UDim2.new(1, -42, 1, -30 + math.floor(math.sin(t * 6) * 3 + 0.5))
		end
	end)
	-- the answers, as speech bubbles down the right side of the screen
	choiceRow = Kit.box({
		Name = "Choices",
		Parent = gui,
		Size = UDim2.fromOffset(380, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Position = UDim2.new(1, -30, 0.5, 40),
		AnchorPoint = Vector2.new(1, 0.5),
		Visible = false,
	})
	choiceRow.ZIndex = 21
	Kit.list(choiceRow, 12)
	holder:GetPropertyChangedSignal("Visible"):Connect(function()
		choiceRow.Visible = holder.Visible
	end)
	-- a click on the box finishes the line, or skips to the next one
	card.InputBegan:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			skip = true
		end
	end)

	Remotes.event("EventShow").OnClientEvent:Connect(function(ev)
		ev.names = ev.names or {}
		if playing then
			table.insert(queue, ev)
		else
			task.spawn(play, ev)
		end
	end)
	Remotes.event("EventLine").OnClientEvent:Connect(function(msg)
		if current and current.token == msg.token then
			current.after = msg.lines
		end
	end)
	Remotes.event("EventEnd").OnClientEvent:Connect(function(msg)
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
	local _ = typing
end

return EventCard
