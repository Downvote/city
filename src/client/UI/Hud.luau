-- The always-on screen: coins and city stats, the clock, the main buttons, the daily gift,
-- and the wiring that opens panels from buttons, prompts in the world and server notices.

local Lighting = game:GetService("Lighting")
local ProximityPromptService = game:GetService("ProximityPromptService")
local TweenService = game:GetService("TweenService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Remotes = require(Shared.Net.Remotes)
local Text = require(Shared.Util.Text)
local City = require(Shared.Sim.City)
local Schema = require(Shared.Sim.Schema)

local Kit = require(script.Parent.Kit)
local Toasts = require(script.Parent.Toasts)
local State = require(script.Parent.Parent.Controllers.State)

local Hud = {}

local T = Kit.Theme

local panels: { [string]: any } = {}

-- Panels open one at a time.
function Hud.panel(name: string): any
	if not panels[name] then
		local module = script.Parent:FindFirstChild(name)
		if module then
			panels[name] = require(module) :: any
		end
	end
	return panels[name]
end

function Hud.open(name: string, arg: any?)
	for other, p in panels do
		if other ~= name and p.isOpen and p.isOpen() and p.close then
			p.close()
		end
	end
	local p = Hud.panel(name)
	if p and p.open then
		p.open(arg)
	end
end

function Hud.closeAll()
	for _, p in panels do
		if p.isOpen and p.isOpen() and p.close then
			p.close()
		end
	end
end

-- A profile-like table from the client state, for Sim/City.
function Hud.cityStats(): any
	local d = State.data
	return City.stats({ villagers = d.villagers or {}, plan = State.plan, coins = d.coins or 0 })
end

local SEASONS = Schema.Seasons
local WEATHER = {
	clear = "Clear",
	cloudy = "Cloudy",
	rain = "Rain",
	storm = "Storm",
	snow = "Snow",
	blossom = "Blossom",
	leaves = "Falling leaves",
}

local WEATHER_ICON = {
	clear = "☀️",
	cloudy = "☁️",
	rain = "🌧️",
	storm = "⛈️",
	snow = "❄️",
	blossom = "🌸",
	leaves = "🍂",
}

-- How far the town is toward its next level: both people and what's built count, so the
-- slower of the two sets the bar.
local function levelProgress(stats: any): (number, string)
	local nextLevel = stats.nextLevel
	if not nextLevel then
		return 1, "Top level"
	end
	local pop = if nextLevel.Pop > 0 then stats.population / nextLevel.Pop else 1
	local built = if nextLevel.Value > 0 then stats.value / nextLevel.Value else 1
	return math.clamp(math.min(pop, built), 0, 1),
		Text.fill("Next: {name}. {pop}/{needPop} people, {built}/{needBuilt} built", {
			name = nextLevel.Name,
			pop = stats.population,
			needPop = nextLevel.Pop,
			built = Text.commas(math.min(stats.value, nextLevel.Value)),
			needBuilt = Text.commas(nextLevel.Value),
		})
end

function Hud.start()
	local gui = Kit.root()
	local hud = Kit.box({ Name = "Hud", Size = UDim2.fromScale(1, 1), Parent = gui })

	-- stat pills, top left ----------------------------------------------------------------------------
	local pills =
		Kit.box({ Name = "Pills", Size = UDim2.fromOffset(460, 44), Position = UDim2.fromOffset(12, 12), Parent = hud })
	Kit.list(pills, 8, true)
	local coinPill, coins =
		Kit.pill("🪙", { Parent = pills, Size = UDim2.fromOffset(190, 44), LayoutOrder = 1, TextSize = 22 })
	local _, popLabel = Kit.pill("👥", { Parent = pills, Size = UDim2.fromOffset(100, 44), LayoutOrder = 2 })
	local _, moodLabel = Kit.pill("😊", { Parent = pills, Size = UDim2.fromOffset(110, 44), LayoutOrder = 3 })
	local moodIcon = (moodLabel.Parent :: Instance):FindFirstChild("Icon") :: TextLabel

	-- the town's level card under the pills
	local card = Kit.frame({
		Name = "CityCard",
		Size = UDim2.fromOffset(300, 66),
		Position = UDim2.fromOffset(12, 64),
		Stroke = T.Line,
		Radius = 16,
		Parent = hud,
	})
	local badge = Kit.frame({
		Parent = card,
		Size = UDim2.fromOffset(46, 46),
		Position = UDim2.new(0, 10, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		Color = T.Purple,
		Radius = 23,
	})
	Kit.gradient(badge, 0.12)
	local badgeText = Kit.title("1", {
		Parent = badge,
		Size = UDim2.fromScale(1, 1),
		TextSize = 24,
		Color = T.White,
		AlignX = Enum.TextXAlignment.Center,
	})
	local cityName = Kit.title(
		"",
		{ Parent = card, Size = UDim2.new(1, -78, 0, 24), Position = UDim2.fromOffset(66, 6), TextSize = 20 }
	)
	local track = Kit.frame({
		Parent = card,
		Size = UDim2.new(1, -80, 0, 10),
		Position = UDim2.fromOffset(66, 32),
		Color = T.PaperDark,
		Radius = 5,
	})
	local fill = Kit.frame({ Parent = track, Size = UDim2.fromScale(0, 1), Color = T.Purple, Radius = 5 })
	Kit.gradient(fill, 0.15)
	local nextLine = Kit.text("", {
		Parent = card,
		Size = UDim2.new(1, -78, 0, 16),
		Position = UDim2.fromOffset(66, 45),
		TextSize = 12,
		Color = T.InkSoft,
		Wrap = false,
	})
	nextLine.TextTruncate = Enum.TextTruncate.AtEnd
	local cardButton =
		Kit.new("TextButton", { Text = "", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Parent = card })
	cardButton.Activated:Connect(function()
		Hud.open("CityPanel")
	end)

	local shown = 0
	local function setCoins(n: number)
		local from = shown
		shown = n
		local value = Instance.new("NumberValue")
		value.Value = from
		value.Changed:Connect(function(v)
			coins.Text = Text.commas(math.floor(v + 0.5))
		end)
		TweenService:Create(value, TweenInfo.new(0.6), { Value = n }):Play()
		task.delay(0.7, function()
			value:Destroy()
		end)
		if n ~= from and from > 0 then
			local gain = n > from
			local pop = Kit.title((if gain then "+" else "-") .. Text.commas(math.abs(n - from)), {
				Parent = coinPill,
				Size = UDim2.fromOffset(120, 24),
				Position = UDim2.new(1, -100, 1, 4),
				TextSize = 20,
				Color = if gain then T.GreenDark else T.CoralDark,
			})
			TweenService:Create(pop, TweenInfo.new(1.2), { Position = UDim2.new(1, -100, 1, 28), TextTransparency = 1 })
				:Play()
			task.delay(1.3, function()
				pop:Destroy()
			end)
		end
	end
	local function refreshCity()
		local stats = Hud.cityStats()
		popLabel.Text = tostring(stats.population)
		moodLabel.Text = stats.happiness .. "%"
		if moodIcon then
			moodIcon.Text = if stats.population == 0
				then "😶"
				elseif stats.happiness >= 70 then "😊"
				elseif stats.happiness >= 40 then "🙂"
				else "😟"
		end
		badgeText.Text = tostring(stats.level)
		cityName.Text = stats.levelName
		local t, line = levelProgress(stats)
		TweenService:Create(fill, TweenInfo.new(0.4), { Size = UDim2.fromScale(math.max(t, 0.02), 1) }):Play()
		nextLine.Text = line
	end
	State.on("coins", function(n)
		setCoins(n or 0)
	end)
	State.on("villagers", refreshCity)
	State.onPlan(function()
		refreshCity()
	end)
	refreshCity()

	-- clock, top right ------------------------------------------------------------------------------------
	local clock = Kit.frame({
		Name = "Clock",
		Size = UDim2.fromOffset(220, 60),
		Position = UDim2.new(1, -12, 0, 12),
		AnchorPoint = Vector2.new(1, 0),
		Stroke = T.Line,
		Radius = 16,
		Parent = hud,
	})
	local weatherIcon = Kit.new("TextLabel", {
		Text = "☀️",
		BackgroundTransparency = 1,
		TextScaled = true,
		Font = Enum.Font.BuilderSansBold,
		Size = UDim2.fromOffset(38, 38),
		Position = UDim2.new(0, 12, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		Parent = clock,
	})
	local timeLabel = Kit.title(
		"",
		{ Parent = clock, Size = UDim2.new(1, -70, 0, 28), Position = UDim2.fromOffset(58, 6), TextSize = 24 }
	)
	local dateLabel = Kit.text("", {
		Parent = clock,
		Size = UDim2.new(1, -70, 0, 18),
		Position = UDim2.fromOffset(58, 34),
		TextSize = 14,
		Color = T.InkSoft,
		Wrap = false,
	})
	task.spawn(function()
		while true do
			local h = Lighting.ClockTime
			timeLabel.Text = Text.clock(h)
			local season = workspace:GetAttribute("Season")
			local day = workspace:GetAttribute("Day")
			local weather = workspace:GetAttribute("Weather")
			local night = h < 6 or h >= 19.5
			weatherIcon.Text = if (weather == nil or weather == "clear") and night
				then "🌙"
				else (WEATHER_ICON[weather :: any] or "☀️")
			dateLabel.Text = Text.fill("{season} {day}, {weather}", {
				season = SEASONS[if type(season) == "number" then season else 1],
				day = if type(day) == "number" then day else 1,
				weather = (WEATHER[weather :: any] or "Clear"):lower(),
			})
			task.wait(1)
		end
	end)

	-- the dock down the left ------------------------------------------------------------------------------
	local dock = Kit.frame({
		Name = "Dock",
		Size = UDim2.fromOffset(92, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Position = UDim2.new(0, 12, 0.5, 30),
		AnchorPoint = Vector2.new(0, 0.5),
		Color = T.Glass,
		Transparency = 0.25,
		Radius = 20,
		Parent = hud,
	})
	Kit.pad(dock, 8, 8)
	Kit.list(dock, 8, false, Enum.HorizontalAlignment.Center)
	local BuildMode = require(script.Parent.Parent.Build.BuildMode)
	local BuildUI = require(script.Parent.Parent.Build.BuildUI)
	BuildUI.init(function()
		BuildMode.exit()
	end)
	-- the HUD steps aside in Build mode and while the creator fills the screen
	local function refreshVisible()
		local creator = panels.Creator
		local creating = creator ~= nil and creator.isOpen ~= nil and creator.isOpen()
		hud.Visible = not BuildMode.isActive() and not creating
		local card = panels.EventCard
		if card and card.setHidden then
			card.setHidden(not hud.Visible)
		end
	end
	BuildMode.Changed:Connect(function(what)
		if what == "active" then
			refreshVisible()
		end
	end)
	task.spawn(function()
		while true do
			task.wait(0.25)
			refreshVisible()
		end
	end)
	local entries = {
		{
			"🔨",
			"Build",
			T.Blue,
			function()
				Hud.closeAll()
				BuildMode.enter()
			end,
		},
		{
			"👥",
			"Villagers",
			T.Green,
			function()
				Hud.open("Residents")
			end,
		},
		{
			"✂️",
			"Create",
			T.Coral,
			function()
				Hud.open("Creator", { mode = "new" })
			end,
		},
		{
			"🏛️",
			"City",
			T.Purple,
			function()
				Hud.open("CityPanel")
			end,
		},
		{
			"🛒",
			"Shop",
			T.YellowDark,
			function()
				Hud.open("ShopPanel")
			end,
		},
		{
			"📰",
			"News",
			T.InkSoft,
			function()
				Hud.open("News")
			end,
		},
	}
	for i, e in entries do
		local b = Kit.iconButton(
			e[1],
			e[2],
			{ Parent = dock, Size = UDim2.fromOffset(76, 72), LayoutOrder = i, Radius = 14 },
			e[4]
		)
		-- a coloured strip along the bottom tells the buttons apart at a glance
		local strip = Kit.frame({
			Parent = b,
			Size = UDim2.new(1, -24, 0, 4),
			Position = UDim2.new(0.5, 0, 1, -6),
			AnchorPoint = Vector2.new(0.5, 0),
			Color = e[3],
			Radius = 2,
		})
		strip.ZIndex = 3
	end

	-- daily gift ---------------------------------------------------------------------------------------
	local gift = Kit.iconButton(
		"🎁",
		"Gift",
		{ Parent = dock, Size = UDim2.fromOffset(76, 72), LayoutOrder = 20, Radius = 14, Color = T.Yellow }
	)
	gift.Visible = false
	local giftScale = Instance.new("UIScale")
	giftScale.Parent = gift:FindFirstChild("Icon")
	TweenService:Create(
		giftScale,
		TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{ Scale = 1.15 }
	):Play()
	State.on("daily", function(daily)
		local today = math.floor(os.time() / 86400)
		gift.Visible = daily == nil or daily.last ~= today
	end)
	gift.Activated:Connect(function()
		gift.Visible = false
		local ok, amount = Remotes.fn("DailyClaim"):InvokeServer()
		if ok then
			Toasts.show(Text.fill("Daily gift: {n} coins. Come back tomorrow for more.", { n = amount }), "good")
		end
	end)

	-- the unsaved warning
	State.on("unsaved", function(v)
		if v then
			Toasts.show("This server can't save, so nothing here will be kept.", "warn")
		end
	end)

	-- notices from the server --------------------------------------------------------------------------
	Remotes.event("Notify").OnClientEvent:Connect(function(text, kind)
		if kind == "action" then
			local vid = text:match("^open:creator:(.*)$")
			if vid ~= nil then
				if vid ~= "" then
					Hud.open("Creator", { mode = "edit", vid = vid })
				else
					Hud.open("Creator", { mode = "new" })
				end
			end
			return
		end
		Toasts.show(text, kind)
	end)

	-- prompts in the world open panels
	ProximityPromptService.PromptTriggered:Connect(function(prompt)
		local opens = prompt:GetAttribute("Opens")
		if opens == "creator" then
			Hud.open("Creator", { mode = "new" })
		elseif opens == "shop" then
			Hud.open("ShopPanel")
		elseif opens == "news" then
			Hud.open("News")
		elseif opens == "city" then
			Hud.open("CityPanel")
		end
	end)

	-- events, weather
	Hud.panel("EventCard").start(Hud)
	Hud.panel("Weather").start()

	-- the first visit: make yourself first
	task.spawn(function()
		while State.data.order == nil do
			task.wait(0.3)
		end
		task.wait(1.5)
		if #State.data.order == 0 then
			Hud.panel("Welcome").open(Hud)
		end
	end)
end

return Hud
