-- Settings: what this player's own screen draws, and the interface's look. The user: "add
-- settings for graphic quality, background blur, bloom, etc.", and the dark or light switch that
-- left the top of the screen comes here (UI/Theme keeps it). A full menu (Kit.panel): the card at
-- the left holds the look and a note on Roblox's own graphics quality, which no script can set;
-- down the right, a row for each choice with its options. Every change is on at once
-- (World/Graphics) and saved with the player (SettingSet, checked on the server).

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Tuning = require(Shared.Config.Tuning)
local Rules = require(Shared.Sim.Graphics)

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
