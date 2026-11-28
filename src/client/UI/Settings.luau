-- Settings: what this player's own screen draws, and the interface's look. The user: "add
-- settings for graphic quality, background blur, bloom, etc.", and the dark or light switch that
-- left the top of the screen comes here (UI/Theme keeps it). A full menu (Kit.panel): the card at
-- the left holds the look and a note on Roblox's own graphics quality, which no script can set;
-- down the right, a row for each choice with its options. Every change is on at once
-- (World/Graphics) and saved with the player (SettingSet, checked on the server).
--
-- On the card under the look, what this player hears (the user: "add sounds where necessary, along
-- with a calm cozy music track in the background"; Controllers/Audio, Sim/Sound): the music's and
-- the effects' volume on a slider each, and the villagers' voices on or off.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Tuning = require(Shared.Config.Tuning)
local Rules = require(Shared.Sim.Graphics)
local SoundRules = require(Shared.Sim.Sound)

local UserInputService = game:GetService("UserInputService")

local Kit = require(script.Parent.Kit)
local MenuParts = require(script.Parent.MenuParts)
local Theme = require(script.Parent.Theme)
local Graphics = require(script.Parent.Parent.World.Graphics)

local Settings = {}

local T = Kit.Theme
local panel: any = nil
local unbind: { () -> () } = {}

local shownKey = "" -- the settings the menu shows, so a change it made itself doesn't draw it again

local function keyOf(settings: { [string]: any }): string
	local out = {}
	for _, k in Rules.Keys do
		table.insert(out, tostring(settings[k]))
	end
	for _, k in SoundRules.Keys do
		table.insert(out, tostring(settings[k]))
	end
	return table.concat(out, ",")
end

local ON_OFF = { { id = "on", name = "On" }, { id = "off", name = "Off" } }

-- The rows down the right: a setting, what its options are called, and which is picked.
type Choice = { key: string, title: string, sub: string?, options: { { id: string, name: string } } }

Settings.Rows = {
	{
		key = "detail",
		title = "Detail",
		sub = "Shadows and effects",
		options = {
			{ id = "low", name = "Low" },
			{ id = "medium", name = "Medium" },
			{ id = "high", name = "High" },
		},
	},
	{ key = "blur", title = "Background blur", options = ON_OFF },
	{
		key = "blurStrength",
		title = "Blur strength",
		options = {
			{ id = "1", name = "Soft" },
			{ id = "2", name = "Medium" },
			{ id = "3", name = "Strong" },
		},
	},
	{ key = "bloom", title = "Bloom", sub = "Glow on lights", options = ON_OFF },
	{ key = "sunRays", title = "Sun rays", options = ON_OFF },
	{ key = "haze", title = "Haze", sub = "Fades what is far off", options = ON_OFF },
} :: { Choice }

-- The sound's lines on the card: two volumes on sliders, and the voices.
Settings.Volumes = {
	{ key = "music", title = "Music" } :: { key: string, title: string, sub: string? },
	{ key = "sfx", title = "Effects" },
}
Settings.Voices = { key = "voices", title = "Voices", options = ON_OFF } :: Choice

-- A volume slider at the right of a line, 0 to 100%: a track, its fill and a knob, the number beside it. While it
-- is dragged the sound follows at once; the value is saved as it moves (World/Graphics.set: only
-- a change is sent).
local VOLUME_W = 210
local function volumeSlider(parent: Instance, key: string, value: number)
	local box = Kit.box({
		Name = "Volume",
		Parent = parent,
		Size = UDim2.fromOffset(VOLUME_W + 64, 40),
		Position = UDim2.new(1, -4, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
	})
	local readout = Kit.text("", {
		Name = "Amount",
		Parent = box,
		Size = UDim2.fromOffset(54, 40),
		TextSize = 16,
		Font = Kit.Fonts.Bold,
		AlignX = Enum.TextXAlignment.Right,
		Color = T.InkSoft,
		Wrap = false,
	})
	local track = Kit.frame({
		Name = "Track",
		Parent = box,
		Size = UDim2.fromOffset(VOLUME_W, 10),
		Position = UDim2.new(1, 0, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
		Color = T.PaperDark,
		Radius = "pill",
	})
	local fill =
		Kit.frame({ Name = "Fill", Parent = track, Size = UDim2.fromScale(0, 1), Color = T.Blue, Radius = "pill" })
	local knob = Kit.frame({
		Name = "Knob",
		Parent = track,
		Size = UDim2.fromOffset(22, 22),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0, 0.5),
		Color = T.Ink, -- (light on the dark card, dark on the light one)
		Radius = "circle",
	})
	local function show(v: number)
		fill.Size = UDim2.fromScale(v, 1)
		knob.Position = UDim2.fromScale(v, 0.5)
		readout.Text = string.format("%d%%", math.floor(v * 100 + 0.5))
	end
	show(value)
	local dragging = false
	local function fromX(x: number)
		local t = math.clamp((x - track.AbsolutePosition.X) / math.max(1, track.AbsoluteSize.X), 0, 1)
		local v = math.floor(t * 20 + 0.5) / 20
		show(v)
		Graphics.set(key, v)
		shownKey = keyOf(Graphics.settings())
	end
	local hit = Kit.new("TextButton", {
		Name = "Hit",
		Text = "",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 16, 0, 40),
		Position = UDim2.new(1, 8, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
		ZIndex = 3,
		Parent = box,
	}) :: TextButton
	hit.Size = UDim2.fromOffset(VOLUME_W + 16, 40)
	hit.InputBegan:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			dragging = true
			fromX(input.Position.X)
		end
	end)
	local moved = UserInputService.InputChanged:Connect(function(input)
		if
			dragging
			and (
				input.UserInputType == Enum.UserInputType.MouseMovement
				or input.UserInputType == Enum.UserInputType.Touch
			)
		then
			fromX(input.Position.X)
		end
	end)
	local ended = UserInputService.InputEnded:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			dragging = false
		end
	end)
	box.Destroying:Connect(function()
		moved:Disconnect()
		ended:Disconnect()
	end)
end

-- The option a setting has now, by its id.
function Settings.picked(key: string, settings: { [string]: any }): string
	local v = settings[key]
	if key == "blurStrength" then
		return tostring(Rules.blurStep(settings))
	elseif type(v) == "boolean" then
		return if v then "on" else "off"
	end
	return tostring(v)
end

-- What picking option `id` of a setting saves.
function Settings.value(key: string, id: string): any
	if key == "blurStrength" then
		return Tuning.Graphics.BlurSteps[tonumber(id) or 2] or 0.5
	elseif id == "on" or id == "off" then
		return id == "on"
	end
	return id
end

local draw: () -> ()

draw = function()
	if not panel then
		return
	end
	for _, c in panel.body:GetChildren() do
		c:Destroy()
	end
	local settings = Graphics.settings()
	shownKey = keyOf(settings)

	-- the card: the interface's look, and where Roblox's own quality is set
	local _, inside = MenuParts.card(panel.body, T.Blue)
	Kit.title("Look", {
		Name = "LookTitle",
		Parent = inside,
		Size = UDim2.new(1, 0, 0, 36),
		TextSize = 28,
		Wrap = false,
	})
	local _, pickLook = Kit.segments({
		{ id = "dark", name = "Dark" },
		{ id = "light", name = "Light" },
	}, function(id: string)
		Theme.set(id)
	end, { Parent = inside, Position = UDim2.fromOffset(0, 46), Height = 44, TextSize = 16 })
	pickLook(Theme.name())
	MenuParts.hint("Graphics quality is set in Roblox's menu (Esc, then Settings).", {
		Name = "Quality",
		Parent = inside,
		Size = UDim2.new(1, 0, 0, 0),
		Position = UDim2.fromOffset(0, 108),
	})
	-- friends: Roblox's invite box (UI/Invite; the user: "prompt the player to invite friends")
	local Invite = require(script.Parent.Invite) :: any
	Invite.button("Invite friends", {
		Parent = inside,
		Size = UDim2.new(1, 0, 0, 46),
		Position = UDim2.new(0, 0, 1, -46),
		TextSize = 18,
	})

	-- and under it, what this player hears: a line each, its name at the left and its slider or
	-- switch at the right
	Kit.title("Sound", {
		Name = "SoundTitle",
		Parent = inside,
		Size = UDim2.new(1, 0, 0, 36),
		Position = UDim2.fromOffset(0, 186),
		TextSize = 28,
		Wrap = false,
	})
	local function line(name: string, title: string, y: number): Frame
		local f = Kit.box({
			Name = name,
			Parent = inside,
			Size = UDim2.new(1, 0, 0, 44),
			Position = UDim2.fromOffset(0, y),
		})
		Kit.text(title, {
			Name = "Title",
			Parent = f,
			Size = UDim2.new(0, 120, 1, 0),
			TextSize = 19,
			Font = Kit.Fonts.Bold,
			AlignY = Enum.TextYAlignment.Center,
			Wrap = false,
		})
		return f
	end
	for i, vol in Settings.Volumes do
		local f = line(vol.key, vol.title, 186 + 46 + (i - 1) * 52)
		local v = settings[vol.key]
		volumeSlider(f, vol.key, if type(v) == "number" then v else 0.5)
	end
	local choice = Settings.Voices
	local f = line(choice.key, choice.title, 186 + 46 + #Settings.Volumes * 52)
	local _, pickVoices = Kit.segments(choice.options, function(id: string)
		Graphics.set(choice.key, Settings.value(choice.key, id))
		shownKey = keyOf(Graphics.settings())
	end, {
		Parent = f,
		Position = UDim2.new(1, -4, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
		Height = 40,
		TextSize = 15,
	})
	pickVoices(Settings.picked(choice.key, settings))

	-- the rows: what this screen draws
	local list = MenuParts.list(panel.body)
	MenuParts.heading(list, "Graphics", T.Blue, 1)
	for i, choice in Settings.Rows do
		local _, inner = Kit.row({
			Name = choice.key,
			Parent = list,
			Size = MenuParts.rowSize(64),
			Height = 64,
			LayoutOrder = i + 1,
			Title = choice.title,
			Sub = choice.sub,
			RightSpace = 290,
		})
		local _, pick = Kit.segments(choice.options, function(id: string)
			Graphics.set(choice.key, Settings.value(choice.key, id))
			shownKey = keyOf(Graphics.settings())
			if choice.key == "blur" then
				draw() -- (the strength's row dims with the blur off)
			end
		end, {
			Parent = inner,
			Position = UDim2.new(1, -10, 0.5, 0),
			AnchorPoint = Vector2.new(1, 0.5),
			Height = 42,
			TextSize = 15,
		})
		pick(Settings.picked(choice.key, settings))
		if choice.key == "blurStrength" and not settings.blur then
			inner.Parent:SetAttribute("Off", true)
			local row = inner.Parent :: GuiObject
			for _, d in row:GetDescendants() do
				if d:IsA("TextLabel") then
					d.TextTransparency = 0.55
				end
			end
		end
	end
end

function Settings.isOpen(): boolean
	return panel ~= nil
end

function Settings.close()
	for _, u in unbind do
		u()
	end
	unbind = {}
	if panel then
		Kit.closePanel(panel)
		panel = nil
	end
end

function Settings.open()
	Settings.close()
	panel = Kit.panel("Settings", Kit.MenuSize, Settings.close, "gear", T.Blue, { Caption = "On this screen" })
	draw()
	local conn = Graphics.Changed.Event:Connect(function()
		-- (a change from elsewhere, the saved settings arriving)
		if panel and keyOf(Graphics.settings()) ~= shownKey then
			task.defer(draw)
		end
	end)
	table.insert(unbind, function()
		conn:Disconnect()
	end)
end

Kit.onTheme(function()
	if panel then
		draw()
	end
end)

return Settings
