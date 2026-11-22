-- The dialogue box at the bottom of the screen that tells a random event as it plays out in
-- town, the way life sims do it: the event's name on a banner, the speaker on a name plate, the
-- words typed out, a little arrow when you can click on, and the choices stacked under it.
-- "Watch" points the camera at it.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Remotes = require(Shared.Net.Remotes)
local Text = require(Shared.Util.Text)

local Kit = require(script.Parent.Kit)
local State = require(script.Parent.Parent.Controllers.State)

local EventCard = {}

local T = Kit.Theme
local player = Players.LocalPlayer

local holder: Frame
local card: Frame
local titleLabel: TextLabel
local speakerLabel: TextLabel
local plate: Frame
local bodyLabel: TextLabel
local moreArrow: TextLabel
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
		watchButton.Text = "🎥 Watch"
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
	watchButton.Text = "🎥 Stop"
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
	speakerLabel.Text = name or ""
	plate.Visible = name ~= nil and name ~= ""
end

local function typeOut(text: string)
	bodyLabel.Text = text
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
			label = Text.fill("{text}  (🪙 {cost})", { text = label, cost = Text.commas(c.cost) })
		end
		local b = Kit.button(label, {
			Parent = choiceRow,
			Size = UDim2.new(1, 0, 0, 40),
			TextSize = 17,
			Color = if affordable then (if i == 1 then T.Green else T.Blue) else T.PaperDark,
			TextColor = if affordable then T.White else T.InkSoft,
			LayoutOrder = i,
			Radius = 12,
		})
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
	titleLabel.Text = ev.title or ""
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
		Size = UDim2.fromOffset(660, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Position = UDim2.new(0.5, 0, 1, -18),
		AnchorPoint = Vector2.new(0.5, 1),
		Parent = gui,
		Visible = false,
	})
	holder.ZIndex = 20
	Kit.list(holder, 0, false, Enum.HorizontalAlignment.Center)

	-- the event's name on a banner above the box
	local banner = Kit.frame({
		Parent = holder,
		Size = UDim2.fromOffset(0, 34),
		AutomaticSize = Enum.AutomaticSize.X,
		Color = T.Coral,
		Radius = 17,
		LayoutOrder = 1,
	})
	Kit.gradient(banner, 0.12)
	Kit.pad(banner, 18, 0)
	titleLabel = Kit.title("", {
		Parent = banner,
		Size = UDim2.fromOffset(0, 34),
		AutomaticSize = Enum.AutomaticSize.X,
		TextSize = 19,
		Color = T.White,
		Wrap = false,
	})
	Kit.box({ Parent = holder, Size = UDim2.fromOffset(10, 22), LayoutOrder = 2 })

	card = Kit.frame({
		Name = "Box",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Color = T.White,
		Radius = 18,
		LayoutOrder = 3,
		Parent = holder,
	})
	Kit.stroke(card, T.Ink, 3)
	local inner = Kit.box({ Parent = card, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y })
	Kit.pad(inner, 22, 20)
	Kit.list(inner, 10)

	-- the speaker's name plate sits on the box's top edge
	plate = Kit.frame({
		Parent = card,
		Size = UDim2.fromOffset(0, 32),
		AutomaticSize = Enum.AutomaticSize.X,
		Position = UDim2.fromOffset(22, -18),
		Color = T.Blue,
		Radius = 10,
		Visible = false,
	})
	Kit.stroke(plate, T.Ink, 2.5)
	Kit.pad(plate, 14, 0)
	speakerLabel = Kit.title("", {
		Parent = plate,
		Size = UDim2.fromOffset(0, 32),
		AutomaticSize = Enum.AutomaticSize.X,
		TextSize = 18,
		Color = T.White,
		Wrap = false,
	})

	watchButton = Kit.button("🎥 Watch", {
		Parent = card,
		Size = UDim2.fromOffset(112, 30),
		Position = UDim2.new(1, -124, 0, -16),
		TextSize = 14,
		Color = T.Purple,
		Radius = 15,
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
		TextSize = 21,
		LayoutOrder = 1,
	})
	moreArrow = Kit.title("▼", {
		Parent = card,
		Size = UDim2.fromOffset(20, 20),
		Position = UDim2.new(1, -34, 1, -28),
		TextSize = 16,
		Color = T.Coral,
		AlignX = Enum.TextXAlignment.Center,
	})
	moreArrow.Visible = false
	task.spawn(function()
		local t = 0
		while true do
			t += task.wait(0.05)
			moreArrow.Position = UDim2.new(1, -34, 1, -28 + math.floor(math.sin(t * 6) * 3 + 0.5))
		end
	end)
	choiceRow =
		Kit.box({ Parent = inner, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 2 })
	Kit.list(choiceRow, 8)
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
