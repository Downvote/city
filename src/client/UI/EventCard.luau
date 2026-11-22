-- The card at the bottom of the screen that tells a random event as it plays out in town:
-- who says what, the choices you get, and what came of it. "Watch" points the camera at it.

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

local card: Frame
local titleLabel: TextLabel
local speakerLabel: TextLabel
local bodyLabel: TextLabel
local choiceRow: Frame
local watchButton: TextButton
local current: any = nil
local queue: { any } = {}
local playing = false
local watching = false
local watchConn: RBXScriptConnection? = nil

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
	watchButton.Text = "Stop watching"
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

-- Shows lines one after another. Each line waits a moment, or until the card is clicked.
local skip = false
local function showLines(lines: { any })
	for _, l in lines do
		local name = l.who and current and current.names[l.who]
		speakerLabel.Text = name or ""
		speakerLabel.Visible = name ~= nil
		bodyLabel.Text = l.text
		local t = os.clock()
		local wait = math.clamp(#l.text / 18, 2.2, 4.2)
		skip = false
		while os.clock() - t < wait and not skip do
			task.wait(0.05)
		end
	end
end

local function showChoices(ev: any)
	clearChoices()
	for i, c in ev.choices do
		local label = c.text
		local affordable = c.cost == nil or (State.data.coins or 0) >= c.cost
		local b = Kit.button(label, {
			Parent = choiceRow,
			Size = UDim2.fromOffset(0, 40),
			AutomaticSize = Enum.AutomaticSize.X,
			TextSize = 17,
			Color = if affordable then (if i == 1 then T.Green else T.Blue) else T.PaperDark,
			TextColor = if affordable then T.White else T.InkSoft,
			LayoutOrder = i,
		})
		Kit.pad(b, 14, 0)
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
	card.Visible = true
	Kit.popIn(card)
	watchButton.Visible = ev.focus ~= nil
	showLines(ev.lines or {})
	if ev.choices and current == ev then
		speakerLabel.Text = ""
		speakerLabel.Visible = false
		bodyLabel.Text = "What do you do?"
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
		speakerLabel.Visible = false
		bodyLabel.Text = table.concat(ev.notices, "\n")
		task.wait(3)
	end
	card.Visible = false
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

function EventCard.start(_hud: any)
	local gui = Kit.root()
	card = Kit.frame({
		Name = "EventCard",
		Size = UDim2.fromOffset(620, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Position = UDim2.new(0.5, 0, 1, -96),
		AnchorPoint = Vector2.new(0.5, 1),
		Stroke = T.YellowDark,
		Parent = gui,
		Visible = false,
	})
	card.ZIndex = 20
	Kit.pad(card, 16, 12)
	Kit.list(card, 6)
	local top = Kit.box({ Parent = card, Size = UDim2.new(1, 0, 0, 28), LayoutOrder = 1 })
	titleLabel = Kit.title("", { Parent = top, Size = UDim2.new(1, -150, 1, 0), TextSize = 22, Color = T.CoralDark })
	watchButton = Kit.button("Watch", {
		Parent = top,
		Size = UDim2.fromOffset(140, 28),
		Position = UDim2.new(1, -140, 0, 0),
		TextSize = 15,
		Color = T.Purple,
	})
	watchButton.Activated:Connect(function()
		if watching then
			stopWatching()
		else
			startWatching()
		end
	end)
	speakerLabel = Kit.text("", {
		Parent = card,
		Size = UDim2.new(1, 0, 0, 22),
		TextSize = 17,
		Font = Kit.Fonts.Bold,
		Color = T.BlueDark,
		LayoutOrder = 2,
	})
	bodyLabel = Kit.text("", {
		Parent = card,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		TextSize = 20,
		LayoutOrder = 3,
	})
	choiceRow =
		Kit.box({ Parent = card, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 4 })
	local layout = Kit.list(choiceRow, 8, true)
	layout.Wraps = true
	local tap = Kit.new("TextButton", {
		Text = "",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 60),
		Position = UDim2.fromOffset(0, 30),
		Parent = card,
		ZIndex = 0,
	})
	tap.Activated:Connect(function()
		skip = true
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
	local _ = Text
end

return EventCard
