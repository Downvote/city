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
local Theme = require(script.Parent.Theme)
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

	-- the town's level, top left: a hexagon badge, the level's name and a bar to the next one --------
	local card = Kit.box({
		Name = "CityCard",
		Size = UDim2.fromOffset(340, 80),
		Position = UDim2.fromOffset(14, 10),
		Parent = hud,
	})
	local _, badgeText = Kit.hexBadge("1", { Parent = card, Size = 74, Position = UDim2.fromOffset(0, 2) })
	local cityName = Kit.title("", {
		Parent = card,
		Size = UDim2.new(1, -88, 0, 30),
		Position = UDim2.fromOffset(84, 6),
		TextSize = 29,
		Color = T.White,
		Outline = T.Glass,
		OutlineThickness = 2.5,
	})
	local track = Kit.frame({
		Parent = card,
		Size = UDim2.new(1, -96, 0, 12),
		Position = UDim2.fromOffset(86, 42),
		Color = T.Glass,
		Transparency = 0.35,
		Radius = "pill",
	})
	local fill = Kit.frame({ Parent = track, Size = UDim2.fromScale(0, 1), Color = T.Yellow, Radius = "pill" })
	local nextLine = Kit.text("", {
		Parent = card,
		Size = UDim2.new(1, -96, 0, 16),
		Position = UDim2.fromOffset(86, 58),
		TextSize = 13,
		Font = Kit.Fonts.Bold,
		Color = T.White,
		Wrap = false,
	})
	Kit.outlineText(nextLine, T.Glass, 1.5)
	nextLine.TextTruncate = Enum.TextTruncate.AtEnd
	local cardButton =
		Kit.new("TextButton", { Text = "", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Parent = card })
	cardButton.Activated:Connect(function()
		Hud.open("CityPanel")
	end)

	-- money, people and happiness, top middle -------------------------------------------------------------
	local pills = Kit.box({
		Name = "Pills",
		Size = UDim2.fromOffset(470, 50),
		Position = UDim2.new(0.5, 0, 0, 14),
		AnchorPoint = Vector2.new(0.5, 0),
		Parent = hud,
	})
	Kit.list(pills, 14, true, Enum.HorizontalAlignment.Center)
	local coinPill, coins = Kit.pill("coin", {
		Parent = pills,
		Size = UDim2.fromOffset(200, 50),
		LayoutOrder = 1,
		Plus = function()
			Hud.open("ShopPanel")
		end,
	})
	local _, popLabel = Kit.pill("people", { Parent = pills, Size = UDim2.fromOffset(110, 50), LayoutOrder = 2 })
	local moodPill, moodLabel = Kit.pill("smile", { Parent = pills, Size = UDim2.fromOffset(122, 50), LayoutOrder = 3 })

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
				Outline = T.Dark,
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
			local px = math.floor(h * 0.86)
			moodArt = Icons.make(want, px, {
				Name = "IconArt",
				Parent = moodPill,
				Position = UDim2.new(0, math.floor(h * 0.12) + px / 2, 0.5, 0),
				AnchorPoint = Vector2.new(0.5, 0.5),
				ZIndex = moodPill.ZIndex + 1,
				Color = if want == "heart" then T.Pink else T.Orange,
				Hole = T.Glass,
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
	local clock = Kit.darkPill({
		Name = "Clock",
		Size = UDim2.fromOffset(226, 64),
		Position = UDim2.new(1, -14, 0, 12),
		AnchorPoint = Vector2.new(1, 0),
		Radius = 32,
		Parent = hud,
	})
	-- round buttons under the clock: the city, the shop, the news
	local corner = Kit.box({
		Name = "Corner",
		Size = UDim2.fromOffset(302, 52),
		Position = UDim2.new(1, -14, 0, 86),
		AnchorPoint = Vector2.new(1, 0),
		Parent = hud,
	})
	local cornerList = Kit.list(corner, 10, true, Enum.HorizontalAlignment.Right)
	local _ = cornerList
	for i, e in
		{
			{ "map", "MapPanel" },
			{ "city", "CityPanel" },
			{ "cart", "ShopPanel" },
			{ "news", "News" },
		}
	do
		Kit.roundButton(e[1], { Parent = corner, LayoutOrder = i, Name = e[2] }, function()
			Hud.open(e[2])
		end)
	end
	-- dark or light: the button shows the one you would switch to
	local lookButton: GuiObject? = nil
	local function drawLook()
		if lookButton then
			lookButton:Destroy()
		end
		lookButton = Kit.roundButton(Theme.icon(), { Parent = corner, LayoutOrder = 0, Name = "Look" }, function()
			Theme.toggle()
		end)
	end
	drawLook()
	Kit.onTheme(drawLook)
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
		local art = Icons.make(name, 40, {
			Parent = clock,
			Position = UDim2.new(0, 36, 0.5, 0),
			AnchorPoint = Vector2.new(0.5, 0.5),
			ZIndex = 2,
			Hole = T.Glass,
		})
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
		Size = UDim2.new(1, -78, 0, 28),
		Position = UDim2.fromOffset(64, 6),
		TextSize = 26,
		Color = T.White,
	})
	local dateLabel = Kit.text("", {
		Parent = clock,
		Size = UDim2.new(1, -78, 0, 18),
		Position = UDim2.fromOffset(64, 35),
		TextSize = 14,
		Font = Kit.Fonts.Bold,
		Color = Color3.fromRGB(206, 218, 240),
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
	-- the quick menu, bottom left: a portrait, then the town's people, the creator, goals and the gift --
	local menu = Kit.box({
		Name = "Menu",
		Size = UDim2.fromOffset(470, 108),
		Position = UDim2.new(0, 14, 1, -12),
		AnchorPoint = Vector2.new(0, 1),
		Parent = hud,
	})
	local portrait, portraitInside = Kit.blob({
		Name = "Portrait",
		Parent = menu,
		Round = true,
		Color = T.Paper,
		Border = T.Blue,
		BorderWidth = 4,
		Size = UDim2.fromOffset(98, 98),
		Position = UDim2.fromOffset(0, 5),
	})
	Icons.make("person", 56, {
		Parent = portraitInside,
		Position = UDim2.new(0.5, -28, 0.5, -28),
		Color = T.Blue,
		ZIndex = 3,
	})
	local portraitButton = Kit.new(
		"TextButton",
		{ Text = "", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 4, Parent = portrait }
	)
	portraitButton.Activated:Connect(function()
		Hud.open("Residents")
	end)
	local _bar, barInside = Kit.blob({
		Name = "MenuBar",
		Parent = menu,
		Color = T.Paper,
		Slant = 96,
		Size = UDim2.fromOffset(356, 96),
		Position = UDim2.fromOffset(108, 8),
		Estimate = Vector2.new(356, 96),
	})
	local row = Kit.box({ Parent = barInside, Size = UDim2.fromScale(1, 1) })
	local rowList = Kit.list(row, 2, true, Enum.HorizontalAlignment.Center)
	rowList.VerticalAlignment = Enum.VerticalAlignment.Center
	local tiles = {}
	local function menuButton(icon: string, caption: string, color: Color3, order: number, fn: () -> ()): TextButton
		local b = Kit.menuButton(icon, caption, { Parent = row, LayoutOrder = order, Color = color }, fn)
		table.insert(tiles, b)
		return b
	end
	menuButton("people", "Villagers", T.Blue, 1, function()
		Hud.open("Residents")
	end)
	menuButton("shirt", "Create", T.Pink, 2, function()
		Hud.open("Creator", { mode = "new" })
	end)
	local goalsTile = menuButton("trophy", "Goals", T.Orange, 3, function()
		Hud.open("Goals")
	end)
	local giftReady = false
	local gift = menuButton("gift", "Gift", T.Coral, 4, function()
		if not giftReady then
			Toasts.show("Your next gift comes tomorrow.", "info")
			return
		end
		giftReady = false
		task.spawn(function()
			local ok, amount = Remotes.fn("DailyClaim"):InvokeServer()
			if ok then
				Toasts.show(Text.fill("Daily gift: {n} coins. Come back tomorrow for more.", { n = amount }), "good")
			end
		end)
	end)

	-- the big Build button, bottom right
	local buildButton = Kit.bigButton("Build", "hammer", {
		Parent = hud,
		Size = UDim2.fromOffset(236, 80),
		Position = UDim2.new(1, -20, 1, -18),
		AnchorPoint = Vector2.new(1, 1),
		Color = T.Blue,
		IconColor = T.Yellow,
	}, function()
		Hud.closeAll()
		BuildMode.enter()
	end)

	-- badges: Goals while there's something to claim, the gift while today's is waiting; and the
	-- thank you picker when a villager's heart level goes up
	local goalsBadge = Kit.badge(goalsTile)
	local Goals = Hud.panel("Goals")
	local function refreshGoals()
		goalsBadge.Visible = Goals.ready() > 0
	end
	for _, key in { "goals", "stats", "villagers", "rel", "coins" } do
		State.on(key, refreshGoals)
	end
	refreshGoals()
	State.on("offers", function(offers)
		if type(offers) == "table" and #offers > 0 then
			task.delay(1.5, function()
				local Rewards = Hud.panel("Rewards")
				if not Rewards.isOpen() and not BuildMode.isActive() then
					Hud.open("Rewards")
				end
			end)
		end
	end)
	local giftBadge = Kit.badge(gift)
	State.on("daily", function(daily)
		local today = math.floor(os.time() / 86400)
		giftReady = daily == nil or daily.last ~= today
		giftBadge.Visible = giftReady
	end)

	-- everything slides into place when the game starts, one piece after another
	Kit.slideIn(pills, 0, -90, 0.1)
	Kit.slideIn(card, -360, 0, 0.2)
	Kit.slideIn(clock, 240, 0, 0.15)
	Kit.slideIn(corner, 240, 0, 0.2)
	Kit.slideIn(menu, -480, 0, 0.25)
	Kit.slideIn(buildButton, 260, 0, 0.3)
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

	Theme.start()

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
