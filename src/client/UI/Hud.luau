-- The always-on screen: coins, gems and city stats, the clock, the main buttons, the rewards,
-- and the wiring that opens panels from buttons, prompts in the world and server notices.

local Lighting = game:GetService("Lighting")
local ProximityPromptService = game:GetService("ProximityPromptService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Remotes = require(Shared.Net.Remotes)
local Text = require(Shared.Util.Text)
local City = require(Shared.Sim.City)
local Schema = require(Shared.Sim.Schema)

local Kit = require(script.Parent.Kit)
local Icons = require(script.Parent.Icons)
local Toasts = require(script.Parent.Toasts)
local Theme = require(script.Parent.Theme)
local Quests = require(script.Parent.Quests)
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

-- Is any panel up? (The welcome back dialog waits for whatever is being read.)
function Hud.anyOpen(): boolean
	for _, p in panels do
		if p.isOpen and p.isOpen() then
			return true
		end
	end
	return false
end

function Hud.closeAll()
	for _, p in panels do
		if p.isOpen and p.isOpen() and p.close then
			p.close()
		end
	end
end

-- Home: back to the player's own plot (the user: "make it such that there is a teleport home
-- button"). The menus shut, the screen dips to black and comes back up on the doorstep.
local goingHome = false
function Hud.goHome()
	if goingHome then
		return
	end
	goingHome = true
	Hud.closeAll()
	local veil = Kit.frame({
		Name = "Veil",
		Size = UDim2.fromScale(1, 1),
		Color = T.Black,
		Transparency = 1,
		Radius = false,
		ZIndex = 50,
		Parent = Kit.root(),
	})
	veil:SetAttribute("KeepColors", true)
	TweenService:Create(veil, TweenInfo.new(0.18), { BackgroundTransparency = 0.05 }):Play()
	task.spawn(function()
		task.wait(0.18)
		local ok, result, err = pcall(function()
			return Remotes.fn("GoHome"):InvokeServer()
		end)
		TweenService:Create(veil, TweenInfo.new(0.32), { BackgroundTransparency = 1 }):Play()
		task.wait(0.34)
		veil:Destroy()
		goingHome = false
		if not ok or not result then
			Toasts.show(if ok and type(err) == "string" then err else "Can't go home right now.", "warn")
		end
	end)
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

-- How far the town is toward its next level: what it's worth is all a level asks for.
local function levelProgress(stats: any): (number, string)
	local nextLevel = stats.nextLevel
	if not nextLevel then
		return 1, "Top level"
	end
	local built = if nextLevel.Value > 0 then stats.value / nextLevel.Value else 1
	-- the detail is in the city hall, a click away: here just where it's going
	return math.clamp(built, 0, 1), Text.fill("Next: {name}", { name = nextLevel.Name })
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
	-- (no notches across it: the user, of the marks on the bar and the strokes between the money,
	-- people and happiness, "No need for borders where i marked red")
	local nextLine = Kit.text("", {
		Parent = card,
		Size = UDim2.new(1, -150, 0, 18),
		Position = UDim2.fromOffset(86, 57),
		TextSize = 15,
		Font = Kit.Fonts.Bold,
		Color = T.White,
		Wrap = false,
	})
	Kit.outlineText(nextLine, T.Glass, 1.5)
	nextLine.TextTruncate = Enum.TextTruncate.AtEnd
	local pctLine = Kit.text("", {
		Name = "Percent",
		Parent = card,
		Size = UDim2.fromOffset(56, 18),
		Position = UDim2.new(1, -66, 0, 57),
		TextSize = 15,
		Font = Kit.Fonts.Title,
		Color = T.Yellow,
		AlignX = Enum.TextXAlignment.Right,
		Wrap = false,
	})
	Kit.outlineText(pctLine, T.Glass, 1.5)
	local cardButton =
		Kit.new("TextButton", { Text = "", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Parent = card })
	cardButton.Activated:Connect(function()
		Hud.open("CityPanel")
	end)

	-- money, people and happiness, in a strip under the level (the user: "put these as a tab
	-- below the level, then add quests below it as well") --------------------------------------------
	-- One leaning tab that comes out of the left edge of the screen (the user: "the quest tab and
	-- currency/stats tab should also be part of the left side edge"), the three side by side in it.
	local pills = Kit.darkPill({
		Name = "Pills",
		-- (wider for the gems beside the coins: 350 before them)
		Size = UDim2.fromOffset(460, 46),
		Position = UDim2.fromOffset(0, 96),
		Parent = hud,
	})
	local pillRow =
		Kit.box({ Name = "Row", Parent = pills, Size = UDim2.new(1, -8, 1, 0), Position = UDim2.fromOffset(8, 0) })
	pillRow.ZIndex = 2
	-- (a little more room between the three now nothing stands between them)
	Kit.list(pillRow, 14, true, Enum.HorizontalAlignment.Left).VerticalAlignment = Enum.VerticalAlignment.Center
	local function cell(icon: string, width: number, order: number, plus: (() -> ())?): (Frame, TextLabel)
		local f, value = Kit.pill(icon, {
			Parent = pillRow,
			Size = UDim2.fromOffset(width, 40),
			LayoutOrder = order,
			Plus = plus,
		})
		-- the strip is the glass: the cells only hold what is on it
		Kit.paint(f, nil, 1)
		return f, value
	end
	-- (the money had a green + beside it that opened the shop. The user: "remove the + button next
	-- to coins". The shop itself went later.)
	local coinPill, coins = cell("coin", 134, 1)
	-- the gems beside the coins: the rare currency (the user: "players can also buy ... with gems,
	-- as another currency"). A press opens the store on its gems.
	local gemPill, gemLabel = Kit.pill("gem", {
		Name = "Gems",
		Parent = pillRow,
		Size = UDim2.fromOffset(96, 40),
		LayoutOrder = 2,
		IconColor = T.Purple,
	})
	Kit.paint(gemPill, nil, 1)
	local gemButton = Kit.new("TextButton", {
		Name = "OpenGems",
		Text = "",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 4,
		Parent = gemPill,
	})
	gemButton.Activated:Connect(function()
		Hud.open("Store", "gems")
	end)
	local _, popLabel = cell("people", 82, 3)
	local moodPill, moodLabel = cell("smile", 98, 5)
	-- and under that, the quests: the town's next goals
	Quests.mount(hud, UDim2.fromOffset(0, 152), function()
		Hud.open("Goals")
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
		-- a pay packet from the villagers at work (World/Earnings) comes every few seconds while
		-- they work: it counts up with a little bump, and the "+N" rises over the villagers instead
		local wages = State.data.wages
		if n > from and from > 0 and type(wages) == "table" and wages.coins == n then
			Kit.bump(coinPill, 0.05)
			return
		end
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
		pctLine.Text = if stats.nextLevel then Text.fill("{n}%", { n = math.floor(t * 100) }) else ""
	end
	State.on("coins", function(n)
		setCoins(n or 0)
	end)
	local gemsShown: number? = nil
	State.on("gems", function(n)
		local now = if type(n) == "number" then n else 0
		gemLabel.Text = Text.commas(now)
		if gemsShown ~= nil and now ~= gemsShown then
			Kit.bump(gemPill, 0.12)
		end
		gemsShown = now
	end)
	if State.data.gems == nil then
		gemLabel.Text = "0"
	end
	State.on("villagers", refreshCity)
	State.onPlan(function()
		refreshCity()
	end)
	refreshCity()

	-- the clock, top right ---------------------------------------------------------------------------------
	-- The user: "these three should be coming out of the corners of the screen instead of floating.
	-- vertically flip the paralleograms of the weather and one of the 4 icons". The clock's glass
	-- hangs from the very corner of the screen, in the free end of the strip Roblox keeps at the
	-- top, leaning the other way from the rest and running off the top and the right edge. What it
	-- shows sits up there in it. (The glass used to run from the corner down through that strip to
	-- a clock placed under it, twice as tall as what it held: "the weather tab is stretched".)
	local inset = Kit.topInset()
	local CLOCK_OVER = 10 -- how far the glass runs off the top, so its upper points are out of sight
	local clockTab = Kit.darkPill({
		Name = "ClockTab",
		Size = UDim2.fromOffset(250, 72 + CLOCK_OVER),
		Position = UDim2.new(1, 0, 0, -inset - CLOCK_OVER),
		AnchorPoint = Vector2.new(1, 0),
		Flip = true,
		Side = "left",
		Parent = hud,
	})
	local clock = Kit.box({
		Name = "Clock",
		Size = UDim2.fromOffset(226, 64),
		Position = UDim2.new(1, -10, 0, 4 - inset),
		AnchorPoint = Vector2.new(1, 0),
		Parent = hud,
	})
	clock.ZIndex = 2
	-- round buttons under the clock, each with its name under it: home, the city hall, the news,
	-- and dark or light. (A Map and a Shop button stood here too. The user: "remove the shop,
	-- buying of things and food and feeding" and "remove the map button and the map interface".)
	local corner = Kit.box({
		Name = "Corner",
		-- (wide enough for five: the Store came in beside the news)
		Size = UDim2.fromOffset(310, 76),
		-- under the clock's glass, which ends 72 from the top of the screen
		Position = UDim2.new(1, -14, 0, 88 - inset),
		AnchorPoint = Vector2.new(1, 0),
		Parent = hud,
	})
	Kit.list(corner, 8, true, Enum.HorizontalAlignment.Right)
	local function cornerButton(icon: string, name: string, caption: string, order: number, fn: () -> ()): Frame
		local cell =
			Kit.box({ Name = name .. "Cell", Parent = corner, Size = UDim2.fromOffset(54, 76), LayoutOrder = order })
		Kit.roundButton(icon, { Parent = cell, Size = 50, Position = UDim2.fromOffset(2, 0), Name = name }, fn)
		local label = Kit.text(caption, {
			Name = "Caption",
			Parent = cell,
			Size = UDim2.new(1, 8, 0, 18),
			Position = UDim2.fromOffset(-4, 54),
			TextSize = 13,
			Font = Kit.Fonts.Title,
			Color = T.White,
			AlignX = Enum.TextXAlignment.Center,
			Wrap = false,
		})
		Kit.outlineText(label, T.Glass, 1.5)
		return cell
	end
	local homeCell = cornerButton("house", "Home", "Home", 1, function()
		Hud.goHome()
	end)
	-- on a keyboard, H does it too: the key shows on the button
	if UserInputService.KeyboardEnabled then
		local key = Kit.new("TextLabel", {
			Name = "Key",
			Text = "H",
			Font = Kit.Fonts.Title,
			TextSize = 12,
			TextColor3 = T.Dark,
			BackgroundColor3 = T.Yellow,
			BorderSizePixel = 0,
			Size = UDim2.fromOffset(16, 16),
			Position = UDim2.fromOffset(42, -4),
			ZIndex = 4,
			Parent = homeCell,
		})
		key:SetAttribute("KeepColors", true)
	end
	for i, e in
		{
			{ "city", "CityPanel", "City" },
			{ "news", "News", "News" },
			-- passes and gems for Robux (the user: "add gamepasses, just like bloxburg")
			{ "store", "Store", "Store" },
			-- vehicles to buy and drive (the user: "make vehicles")
			{ "car", "Garage", "Cars" },
		}
	do
		cornerButton(e[1], e[2], e[3], i + 1, function()
			Hud.open(e[2])
		end)
	end
	-- dark or light: the button shows the one you would switch to
	local lookCell: GuiObject? = nil
	local function drawLook()
		if lookCell then
			lookCell:Destroy()
		end
		lookCell = cornerButton(Theme.icon(), "Look", if Theme.name() == "dark" then "Light" else "Dark", 9, function()
			Theme.toggle()
		end)
	end
	drawLook()
	Kit.onTheme(drawLook)
	UserInputService.InputBegan:Connect(function(input, processed)
		-- not while typing, in Build mode or in the creator (the HUD is hidden then)
		if not processed and input.KeyCode == Enum.KeyCode.H and hud.Visible then
			Hud.goHome()
		end
	end)
	local WEATHER_X = 36 -- where the weather's icon sits on the clock, from its left
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
			Position = UDim2.new(0, WEATHER_X, 0.5, 0),
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
			-- clouds and the moon bob gently: up and down only, on the spot. (The bob used to aim
			-- at a place 21 pixels to the left, left over from an older layout, so the icon slid
			-- across the clock and back. The user: "the weather icon drifts left and right
			-- randomly, fix this".)
			TweenService:Create(
				art,
				TweenInfo.new(1.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
				{ Position = UDim2.new(0, WEATHER_X, 0.5, -3) }
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
	-- the quick menu, bottom left: the town's people, the creator, goals and the rewards ---------------
	-- one bar out of the bottom left corner, leaning the other way so it widens toward the bottom.
	-- (There was a round portrait button at its left end, which opened the villagers as the first
	-- tile does. The user: "remove this button and flush the rest to the left".)
	local menu = Kit.box({
		Name = "Menu",
		Size = UDim2.fromOffset(380, 104),
		Position = UDim2.new(0, 0, 1, 0),
		AnchorPoint = Vector2.new(0, 1),
		Parent = hud,
	})
	local bar, barInside = Kit.blob({
		Name = "MenuBar",
		Parent = menu,
		Color = T.Paper,
		Slant = 104,
		Flip = true,
		Size = UDim2.new(1, 28, 1, 0),
		Position = UDim2.fromOffset(-28, 0),
		Estimate = Vector2.new(408, 104),
	})
	local barCore = bar:FindFirstChild("Core", true)
	if barCore and barCore:IsA("Frame") then
		Kit.shade(barCore, T.Paper)
		-- a run of dots toward its far end
		Kit.detail(barCore, { Tone = T.Ink, ToneAlpha = 0.92, ToneWidth = 96 })
	end
	local _ = barInside
	-- the tiles start at the left edge of the screen
	local row = Kit.box({ Parent = menu, Size = UDim2.new(1, -52, 1, 0), Position = UDim2.fromOffset(10, 0) })
	row.ZIndex = 3
	local rowList = Kit.list(row, 2, true, Enum.HorizontalAlignment.Left)
	rowList.VerticalAlignment = Enum.VerticalAlignment.Center
	local tiles = {}
	local function menuButton(icon: string, caption: string, color: Color3, order: number, fn: () -> ()): TextButton
		local b = Kit.menuButton(icon, caption, { Parent = row, LayoutOrder = order, Color = color }, fn)
		-- a small index number at its top left
		Kit.text(Kit.index(order), {
			Name = "Index",
			Parent = b,
			Size = UDim2.fromOffset(20, 12),
			Position = UDim2.fromOffset(6, 2),
			TextSize = 10,
			Font = Kit.Fonts.Body,
			Color = T.InkSoft,
			Wrap = false,
		})
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
	-- (it was the daily gift alone; the gift is the Rewards menu's first tab now, beside gems for
	-- time played, achievements and the group)
	local rewardsTile = menuButton("gift", "Rewards", T.Coral, 4, function()
		Hud.open("Rewards")
	end)

	-- the big Build button, bottom right
	-- (its right end runs off the screen: it comes out of the corner)
	-- It was blue. The user: "make the build button be black as well": it is the same slab as the
	-- menu bar across from it now, with the hammer still yellow.
	local buildButton = Kit.bigButton("Build", "hammer", {
		Parent = hud,
		Size = UDim2.fromOffset(268, 96),
		Position = UDim2.new(1, 20, 1, 0),
		AnchorPoint = Vector2.new(1, 1),
		Color = T.Paper,
		TextColor = T.Ink,
		IconColor = T.Yellow,
		Detail = { Tone = T.Ink, ToneAlpha = 0.92, Side = "left", ToneWidth = 96 },
	}, function()
		Hud.closeAll()
		BuildMode.enter()
	end)

	-- badges: Goals while there's something to claim, the gift while today's is waiting
	local goalsBadge = Kit.badge(goalsTile)
	local Goals = Hud.panel("Goals")
	local function refreshGoals()
		goalsBadge.Visible = Goals.ready() > 0
	end
	for _, key in { "goals", "stats", "villagers", "rel", "coins" } do
		State.on(key, refreshGoals)
	end
	refreshGoals()
	-- the Rewards tile's while anything there is waiting: today's gift, a playtime step, an
	-- achievement or the group's gems
	local rewardsBadge = Kit.badge(rewardsTile)
	local RewardsPanel = Hud.panel("Rewards")
	local function refreshRewards()
		rewardsBadge.Visible = RewardsPanel.waiting() > 0
	end
	for _, key in { "daily", "playtime", "achieved", "villagers", "rel", "stats" } do
		State.on(key, refreshRewards)
	end
	State.onPlan(function()
		refreshRewards()
	end)
	local me = game:GetService("Players").LocalPlayer
	if me then
		me:GetAttributeChangedSignal("InGroup"):Connect(refreshRewards)
	end
	refreshRewards()
	task.spawn(function()
		-- (a new day brings a new gift with nobody pushing anything)
		while true do
			task.wait(60)
			refreshRewards()
		end
	end)

	-- While somebody is talking in a scene (a villager you stopped, an event you chose to watch:
	-- the user, "when text from a villager appears, make the character talking slide into view
	-- at the side with a textbox"), the bottom of the screen and its left side are theirs. The
	-- menu bar, the Build button and the quests slide out of the way and come back after. The
	-- cards say so with State.set("talking", true / false).
	local aside = false
	local function stepAside(on: boolean)
		if on == aside then
			return
		end
		aside = on
		-- off quickly, back in easing out to rest
		local ease = if on
			then TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			else TweenInfo.new(0.34, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
		TweenService:Create(menu, ease, { Position = UDim2.new(0, if on then -460 else 0, 1, 0) }):Play()
		TweenService:Create(buildButton, ease, { Position = UDim2.new(1, if on then 320 else 20, 1, 0) }):Play()
		local quests = Quests.root()
		if quests then
			TweenService:Create(quests, ease, { Position = UDim2.fromOffset(if on then -440 else 0, 152) }):Play()
		end
	end
	State.on("talking", function(v)
		stepAside(v == true)
	end)

	-- everything slides into place when the game starts, one piece after another
	Kit.slideIn(pills, -500, 0, 0.1)
	Kit.slideIn(card, -360, 0, 0.2)
	Kit.slideIn(clockTab, 260, 0, 0.15)
	Kit.slideIn(clock, 260, 0, 0.15)
	Kit.slideIn(corner, 320, 0, 0.2)
	Kit.slideIn(menu, -480, 0, 0.25)
	Kit.slideIn(buildButton, 260, 0, 0.3)
	-- and the quick menu's tiles rise into it one after another
	for i, tile in tiles do
		for _, name in { "IconArt", "Caption" } do
			local part = tile:FindFirstChild(name)
			if part and part:IsA("GuiObject") then
				local home = part.Position
				part.Position = home + UDim2.fromOffset(0, 18)
				Kit.tween(
					part,
					TweenInfo.new(0.36, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, 0, false, 0.3 + i * 0.05),
					{ Position = home }
				)
			end
		end
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
				TweenService:Create(coinArt, TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
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
				-- (an event's answer can ask for it: it opens once the player has closed the scene
				-- or the talk card they are reading, never over it)
				task.spawn(function()
					local Dialogue = require(script.Parent.Dialogue) :: any
					while Dialogue.isOpen() do
						task.wait(0.25)
					end
					if vid ~= "" then
						Hud.open("Creator", { mode = "edit", vid = vid })
					else
						Hud.open("Creator", { mode = "new" })
					end
				end)
			end
			return
		end
		-- how an event turned out waits while its scene is still being read, so the notice never
		-- gives the ending away (it shows when the scene closes)
		local card = if kind == "event" then Hud.panel("EventCard") else nil
		if card and card.isWatching and card.isWatching() then
			task.spawn(function()
				while card.isWatching() do
					task.wait(0.25)
				end
				Toasts.show(text, kind)
			end)
			return
		end
		Toasts.show(text, kind)
	end)

	-- prompts in the world open panels
	ProximityPromptService.PromptTriggered:Connect(function(prompt)
		local opens = prompt:GetAttribute("Opens")
		if opens == "creator" then
			Hud.open("Creator", { mode = "new" })
		elseif opens == "news" then
			Hud.open("News")
		elseif opens == "city" then
			Hud.open("CityPanel")
		end
	end)

	Theme.start()

	-- events (the weather's rain and snow start on their own, from Main)
	Hud.panel("EventCard").start(Hud)

	-- the tutorial (UI/Tutorial): on a first visit its welcome, then a card at the side for each
	-- step, pointing at what to press next
	Hud.panel("Tutorial").start(Hud)

	-- what the town earned while the player was away (UI/WelcomeBack; Sim/Offline)
	Hud.panel("WelcomeBack").start(Hud)
end

return Hud
