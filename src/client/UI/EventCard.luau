-- Tells a random event as it plays out in town: a dialogue card near the bottom of the screen
-- with the event's name on a tab, the speaker on a name plate, the words typed out with the
-- villagers' names picked out in colour, a little arrow when you can click on, and the answers
-- stacked under the words. "Watch" points the camera at it.

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
local topRow: Frame? = nil
-- The strip over the words (who speaks, and Watch) takes no room when it holds nothing.
local function fitTop()
	if topRow then
		topRow.Visible = plate.Visible or watchButton.Visible
	end
end

local function setSpeaker(name: string?)
	local changed = speakerLabel.Text ~= (name or "")
	speakerLabel.Text = name or ""
	plate.Visible = name ~= nil and name ~= ""
	fitTop()
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
			Position = UDim2.new(0, 22, 1, 0),
			AnchorPoint = Vector2.new(0, 1),
			ZIndex = 22,
		})
	end
	if not hidden then
		Kit.popIn(holder)
	end
	watchButton.Visible = ev.focus ~= nil
	fitTop()
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

-- Is an event being told right now? (The talk card, UI/TalkCard, keeps out of its way.)
function EventCard.isPlaying(): boolean
	return playing
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
	-- a dialogue card near the bottom of the screen, the way town builders' advisers talk: the
	-- event's name on a tab over its top edge, the words, and the answers stacked under them.
	-- Everything inside is laid out by lists, so the card is exactly as tall as what's in it.
	holder = Kit.box({
		Name = "EventCard",
		Size = UDim2.fromOffset(600, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Position = UDim2.new(0.5, 0, 1, -124),
		AnchorPoint = Vector2.new(0.5, 1),
		Parent = gui,
		Visible = false,
	})
	holder.ZIndex = 20
	Kit.list(holder, 0, false, Enum.HorizontalAlignment.Center)
	bannerSlot = Kit.box({ Name = "Banner", Parent = holder, Size = UDim2.new(1, 0, 0, 44), LayoutOrder = 1 })
	bannerSlot.ZIndex = 22
	Kit.box({ Parent = holder, Size = UDim2.fromOffset(10, 6), LayoutOrder = 2 })
	card = Kit.frame({
		Name = "Page",
		Parent = holder,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Color = T.Cream,
		Radius = 28,
		LayoutOrder = 3,
	})
	Kit.softShadow(card, 1.4)
	Kit.wash(card, T.Paper, T.Cream, 90)
	-- a warm glow from the top right, as on the menus
	Kit.glow(card, T.Orange, 0.2, "tr")
	Kit.shapes(card, T.Orange, 41, 12, { Transparency = 0.9, Area = { 0.04, 0.1, 0.96, 0.9 } })
	local inner = Kit.box({ Parent = card, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y })
	Kit.pad(inner, 28, 22)
	Kit.list(inner, 12)

	-- who's talking, and the button that points the camera at them
	local top = Kit.box({ Name = "Top", Parent = inner, Size = UDim2.new(1, 0, 0, 30), LayoutOrder = 0 })
	topRow = top
	plate = Kit.frame({
		Parent = top,
		Size = UDim2.fromOffset(0, 30),
		AutomaticSize = Enum.AutomaticSize.X,
		Color = T.Blue,
		Radius = "pill",
		Visible = false,
	})
	Kit.pad(plate, 14, 0)
	speakerLabel = Kit.title("", {
		Parent = plate,
		Size = UDim2.fromOffset(0, 30),
		AutomaticSize = Enum.AutomaticSize.X,
		TextSize = 17,
		Color = T.White,
		Wrap = false,
	})
	watchButton = Kit.button("Watch", {
		Parent = top,
		Size = UDim2.fromOffset(96, 30),
		Position = UDim2.new(1, 0, 0, 0),
		AnchorPoint = Vector2.new(1, 0),
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
		TextSize = 22,
		Font = Kit.Fonts.Title,
		LayoutOrder = 1,
	})
	bodyLabel.RichText = true
	bodyLabel.LineHeight = 1.15
	moreArrow = Icons.make("down", 20, {
		Parent = card,
		Position = UDim2.new(1, -38, 1, -30),
		Color = T.Coral,
	})
	moreArrow.Visible = false
	task.spawn(function()
		local t = 0
		while true do
			t += task.wait(0.05)
			moreArrow.Position = UDim2.new(1, -38, 1, -30 + math.floor(math.sin(t * 6) * 3 + 0.5))
		end
	end)
	-- the answers, stacked under the words
	choiceRow = Kit.box({
		Name = "Choices",
		Parent = inner,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = 2,
	})
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
