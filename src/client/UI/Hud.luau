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
local Icons = require(script.Parent.Icons)
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
	clear = "sun",
	cloudy = "cloud",
	rain = "rain",
	storm = "storm",
	snow = "snow",
	blossom = "blossom",
	leaves = "leaves",
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

	-- money and stats, top left: dark glass pills with a big icon over one end -------------------------
	local pills =
		Kit.box({ Name = "Pills", Size = UDim2.fromOffset(520, 46), Position = UDim2.fromOffset(26, 14), Parent = hud })
	Kit.list(pills, 26, true)
	local coinPill, coins = Kit.pill("coin", {
		Parent = pills,
		Size = UDim2.fromOffset(196, 46),
		LayoutOrder = 1,
		Plus = function()
			Hud.open("ShopPanel")
		end,
	})
	local _, popLabel = Kit.pill("people", { Parent = pills, Size = UDim2.fromOffset(104, 46), LayoutOrder = 2 })
	local moodPill, moodLabel = Kit.pill("smile", { Parent = pills, Size = UDim2.fromOffset(116, 46), LayoutOrder = 3 })

	-- the town's level under them: a medal, the level's name and a bar to the next one
	local card = Kit.glass({
		Name = "CityCard",
		Size = UDim2.fromOffset(318, 64),
		Position = UDim2.fromOffset(26, 72),
		Radius = 18,
		Parent = hud,
	})
	Icons.make("medal", 64, { Parent = card, Position = UDim2.new(0, -18, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5) })
	local badgeText = Kit.title("1", {
		Parent = card,
		Size = UDim2.fromOffset(30, 30),
		Position = UDim2.new(0, -1, 0.5, 9),
		AnchorPoint = Vector2.new(0, 0.5),
		TextSize = 20,
		Color = T.White,
		AlignX = Enum.TextXAlignment.Center,
		Outline = Kit.darker(T.YellowDark, 0.5),
	})
	local cityName = Kit.title("", {
		Parent = card,
		Size = UDim2.new(1, -70, 0, 24),
		Position = UDim2.fromOffset(54, 5),
		TextSize = 22,
		Color = T.White,
	})
	local track = Kit.frame({
		Parent = card,
		Size = UDim2.new(1, -66, 0, 14),
		Position = UDim2.fromOffset(54, 31),
		Color = T.Shadow,
		Radius = 7,
		Stroke = T.Ink,
		StrokeThickness = 2,
	})
	local fill = Kit.frame({ Parent = track, Size = UDim2.fromScale(0, 1), Color = T.Purple, Radius = 7 })
	Kit.gradient(fill, 0.3)
	local nextLine = Kit.text("", {
		Parent = card,
		Size = UDim2.new(1, -66, 0, 14),
		Position = UDim2.fromOffset(54, 47),
		TextSize = 12,
		Font = Kit.Fonts.Bold,
		Color = Color3.fromRGB(214, 208, 236),
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
			Kit.bump(coinPill, 0.12)
			if gain and n - from >= 10 then
				Kit.flyCoins(nil, coinPill, math.clamp(math.floor((n - from) / 25), 3, 10))
			end
			local pop = Kit.title((if gain then "+" else "-") .. Text.commas(math.abs(n - from)), {
				Parent = coinPill,
				Size = UDim2.fromOffset(120, 26),
				Position = UDim2.new(0, 40, 1, 4),
				TextSize = 22,
				Color = if gain then T.Green else T.Coral,
				Outline = T.Ink,
			})
			TweenService:Create(pop, TweenInfo.new(1.2), { Position = UDim2.new(0, 40, 1, 30), TextTransparency = 1 })
				:Play()
			task.delay(1.3, function()
				pop:Destroy()
			end)
		end
	end
	local moodArt = moodPill:FindFirstChild("IconArt")
	local moodNow = "smile"
	local function refreshCity()
		local stats = Hud.cityStats()
		popLabel.Text = tostring(stats.population)
		moodLabel.Text = stats.happiness .. "%"
		local want = if stats.population > 0 and stats.happiness < 40 then "heart" else "smile"
		if want ~= moodNow and moodArt then
			moodNow = want
			local h = moodPill.Size.Y.Offset
			moodArt:Destroy()
			local px = math.floor(h * 1.12)
			moodArt = Icons.make(want, px, {
				Name = "IconArt",
				Parent = moodPill,
				Position = UDim2.new(0, -math.floor(h * 0.3) + px / 2, 0.5, 0),
				AnchorPoint = Vector2.new(0.5, 0.5),
			})
		end
		badgeText.Text = tostring(stats.level)
		cityName.Text = stats.levelName
		local t, line = levelProgress(stats)
		TweenService:Create(fill, TweenInfo.new(0.4), { Size = UDim2.fromScale(math.max(t, 0.04), 1) }):Play()
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

	-- the clock, top right ---------------------------------------------------------------------------------
	local clock = Kit.glass({
		Name = "Clock",
		Size = UDim2.fromOffset(212, 60),
		Position = UDim2.new(1, -14, 0, 14),
		AnchorPoint = Vector2.new(1, 0),
		Radius = 18,
		Parent = hud,
	})
	local weatherArt: Frame? = nil
	local weatherNow = ""
	local function setWeatherIcon(name: string)
		if name == weatherNow then
			return
		end
		weatherNow = name
		if weatherArt then
			weatherArt:Destroy()
		end
		local art = Icons.make(
			name,
			62,
			{ Parent = clock, Position = UDim2.new(0, 15, 0.5, 0), AnchorPoint = Vector2.new(0.5, 0.5) }
		)
		weatherArt = art
		if name == "sun" then
			-- the sun turns slowly (it has no clipped parts, so turning it is safe)
			TweenService:Create(art, TweenInfo.new(24, Enum.EasingStyle.Linear, Enum.EasingDirection.In, -1), {
				Rotation = 360,
			}):Play()
		else
			-- clouds and the moon bob gently
			TweenService:Create(
				art,
				TweenInfo.new(1.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
				{ Position = UDim2.new(0, 15, 0.5, -3) }
			):Play()
		end
	end
	local timeLabel = Kit.title("", {
		Parent = clock,
		Size = UDim2.new(1, -66, 0, 28),
		Position = UDim2.fromOffset(54, 5),
		TextSize = 26,
		Color = T.White,
	})
	local dateLabel = Kit.text("", {
		Parent = clock,
		Size = UDim2.new(1, -66, 0, 18),
		Position = UDim2.fromOffset(54, 34),
		TextSize = 14,
		Font = Kit.Fonts.Bold,
		Color = Color3.fromRGB(214, 208, 236),
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
			setWeatherIcon(
				if (weather == nil or weather == "clear") and night
					then "moon"
					else (WEATHER_ICON[weather :: any] or "sun")
			)
			dateLabel.Text = Text.fill("{season} {day}, {weather}", {
				season = SEASONS[if type(season) == "number" then season else 1],
				day = if type(day) == "number" then day else 1,
				weather = (WEATHER[weather :: any] or "Clear"):lower(),
			})
			task.wait(1)
		end
	end)

	-- the dock down the left: big coloured tiles -----------------------------------------------------------
	local dock = Kit.box({
		Name = "Dock",
		Size = UDim2.fromOffset(84, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Position = UDim2.fromOffset(18, 154),
		Parent = hud,
	})
	Kit.list(dock, 7, false, Enum.HorizontalAlignment.Center)
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
		local eventCard = panels.EventCard
		if eventCard and eventCard.setHidden then
			eventCard.setHidden(not hud.Visible)
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
			"crane",
			"Build",
			T.Blue,
			function()
				Hud.closeAll()
				BuildMode.enter()
			end,
		},
		{
			"people",
			"Villagers",
			T.Green,
			function()
				Hud.open("Residents")
			end,
		},
		{
			"shirt",
			"Create",
			T.Pink,
			function()
				Hud.open("Creator", { mode = "new" })
			end,
		},
		{
			"city",
			"City",
			T.Purple,
			function()
				Hud.open("CityPanel")
			end,
		},
		{
			"cart",
			"Shop",
			T.Orange,
			function()
				Hud.open("ShopPanel")
			end,
		},
		{
			"news",
			"News",
			T.Teal,
			function()
				Hud.open("News")
			end,
		},
	}
	local tiles = {}
	for i, e in entries do
		table.insert(
			tiles,
			Kit.iconButton(e[1], e[2], {
				Parent = dock,
				Size = UDim2.fromOffset(74, 68),
				LayoutOrder = i,
				Radius = 16,
				Color = e[3],
				TextSize = 15,
			}, e[4])
		)
	end

	-- daily gift ---------------------------------------------------------------------------------------
	local gift = Kit.iconButton("gift", "Gift", {
		Parent = dock,
		Size = UDim2.fromOffset(74, 68),
		LayoutOrder = 20,
		Radius = 16,
		Color = T.Yellow,
		TextColor = T.White,
		TextSize = 15,
	})
	Kit.badge(gift, "!")
	gift.Visible = false
	local giftArt = gift:FindFirstChild("IconArt", true)
	if giftArt then
		local giftScale = Instance.new("UIScale")
		giftScale.Parent = giftArt
		TweenService:Create(
			giftScale,
			TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
			{ Scale = 1.15 }
		):Play()
	end
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

	-- everything slides into place when the game starts, one piece after another
	Kit.slideIn(pills, 0, -90, 0.1)
	Kit.slideIn(card, -360, 0, 0.2)
	Kit.slideIn(clock, 240, 0, 0.15)
	for i, tile in tiles do
		local bounce = Kit.new("UIScale", { Name = "Intro", Parent = tile })
		bounce.Scale = 0
		TweenService:Create(
			bounce,
			TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out, 0, false, 0.25 + i * 0.06),
			{ Scale = 1 }
		):Play()
	end

	-- now and then the coin on the money pill flips over
	local coinArt = coinPill:FindFirstChild("IconArt")
	if coinArt and coinArt:IsA("GuiObject") then
		task.spawn(function()
			local full = coinArt.Size
			while coinArt.Parent do
				task.wait(6 + math.random() * 4)
				TweenService:Create(coinArt, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
					Size = UDim2.fromOffset(2, full.Y.Offset),
				}):Play()
				task.wait(0.15)
				TweenService:Create(coinArt, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
					Size = full,
				}):Play()
			end
		end)
	end

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
