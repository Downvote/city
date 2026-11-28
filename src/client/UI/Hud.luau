-- The always-on screen: coins, gems and city stats, the clock, the main buttons, the rewards,
-- and the wiring that opens panels from buttons, prompts in the world and server notices.

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Remotes = require(Shared.Net.Remotes)
local Text = require(Shared.Util.Text)
local City = require(Shared.Sim.City)
local Schema = require(Shared.Sim.Schema)
local PlotName = require(Shared.Sim.PlotName)

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
-- Hide and Show: the main screen slides away and comes back (set up by Hud.start).
local hiddenNow = false
local setHidden: (boolean) -> () = function(_on: boolean) end

function Hud.setHidden(on: boolean)
	hiddenNow = on
	-- (marked on the root too, for screens of their own that follow the main screen: World/Run's button)
	pcall(function()
		Kit.root():SetAttribute("HudHidden", on)
	end)
	setHidden(on)
end

-- Is the main screen slid away (Hide pressed)?
function Hud.isHidden(): boolean
	return hiddenNow
end

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
	fog = "Fog",
	blossom = "Blossom",
	leaves = "Falling leaves",
}

local WEATHER_ICON = {
	clear = "sun",
	cloudy = "cloud",
	rain = "rain",
	storm = "storm",
	snow = "snow",
	fog = "fog",
	blossom = "blossom",
	leaves = "leaves",
}

-- How far the town is toward its next level: what it's worth is all a level asks for. (The line
-- under the bar that said where it was going went: the user, "remove the "Next: level x"". The
-- detail is in the city hall, a click away.)
local function levelProgress(stats: any): number
	local nextLevel = stats.nextLevel
	if not nextLevel then
		return 1
	end
	local built = if nextLevel.Value > 0 then stats.value / nextLevel.Value else 1
	return math.clamp(built, 0, 1)
end

-- What the main screen calls the plot: its name, or the owner's town until it has one.
local function ownerName(): string
	local me = Players.LocalPlayer
	if not me then
		return ""
	end
	local ok, shown = pcall(function()
		return me.DisplayName
	end)
	if ok and type(shown) == "string" and shown ~= "" then
		return shown
	end
	return me.Name
end

local HIDE_ORDER = 100 -- Hide's place in the row under the clock: the last, at the right end
local QUESTS_AT = UDim2.fromOffset(0, 152) -- the quests' place, under the money and the people
-- the main screen sliding away and back: off quickly, back in easing out, a piece just after another
local SLIDE_OFF = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
local SLIDE_BACK_TIME = 0.34
local SLIDE_BACK = TweenInfo.new(SLIDE_BACK_TIME, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local SLIDE_STEP = 0.03
local SLIDE_ENTER = TweenInfo.new(0.42, Enum.EasingStyle.Quint, Enum.EasingDirection.Out) -- when the game starts
local NAME_WIDE = 252 -- room for the plot's name beside the dial
local NAME_SIZE = 29 -- its words' size, smaller for a long name down to NAME_SMALLEST
local NAME_SMALLEST = 18

function Hud.start()
	local gui = Kit.root()
	local hud = Kit.box({ Name = "Hud", Size = UDim2.fromScale(1, 1), Parent = gui })

	-- the town at the top left: the level's round dial, the plot's name and a bar to the next level ---
	-- The name took the big "Level x"'s place (the user: "allow naming of plots, and the name should
	-- appear in place of the big "Level x" at the top left above the level bar"); the level is on
	-- the dial and, small, on the bar.
	local card = Kit.box({
		Name = "CityCard",
		Size = UDim2.fromOffset(340, 80),
		Position = UDim2.fromOffset(14, 10),
		Parent = hud,
	})
	local _, badgeText = Kit.hexBadge("1", { Parent = card, Size = 74, Position = UDim2.fromOffset(0, 2) })
	local cityName = Kit.title("", {
		Name = "PlotName",
		Parent = card,
		Size = UDim2.fromOffset(NAME_WIDE, 32),
		Position = UDim2.fromOffset(84, 4),
		TextSize = NAME_SIZE,
		Color = T.White,
		Outline = T.Glass,
		OutlineThickness = 2.5,
		Wrap = false,
	})
	cityName.TextTruncate = Enum.TextTruncate.AtEnd
	local function setName(words: string)
		-- a long name comes down a size or two before it is cut short
		local size = NAME_SIZE
		while size > NAME_SMALLEST and Kit.textWidth(words, size, Kit.Fonts.Title) > NAME_WIDE do
			size -= 1
		end
		cityName.TextSize = size
		cityName.Text = words
	end
	local function refreshName()
		setName(PlotName.title(State.data.plotName, ownerName()))
	end
	State.on("plotName", refreshName)
	refreshName()
	local track = Kit.frame({
		Name = "LevelBar",
		Parent = card,
		Size = UDim2.new(1, -96, 0, 18),
		Position = UDim2.fromOffset(86, 42),
		Color = T.Glass,
		Transparency = 0.35,
		Radius = "pill",
	})
	local fill = Kit.frame({ Parent = track, Size = UDim2.fromScale(0, 1), Color = T.Yellow, Radius = "pill" })
	-- (no notches across it: the user, of the marks on the bar and the strokes between the money,
	-- people and happiness, "No need for borders where i marked red")
	-- the level, small, on the bar, and how far along it is at its other end
	local levelLine = Kit.text("", {
		Name = "Level",
		Parent = track,
		Size = UDim2.new(1, -20, 1, 0),
		Position = UDim2.fromOffset(10, 0),
		TextSize = 13,
		Font = Kit.Fonts.Title,
		Color = T.White,
		Wrap = false,
		ZIndex = 3,
	})
	Kit.outlineText(levelLine, T.Glass, 1.5)
	local pctLine = Kit.text("", {
		Name = "Percent",
		Parent = track,
		Size = UDim2.fromOffset(56, 18),
		Position = UDim2.new(1, -10, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
		TextSize = 13,
		Font = Kit.Fonts.Title,
		Color = T.White,
		AlignX = Enum.TextXAlignment.Right,
		Wrap = false,
		ZIndex = 3,
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
		-- (wider for the gems beside the coins: 350 before them. The happiness went: the user,
		-- "remove the happiness icon with the percentage on the left side of the main ui")
		Size = UDim2.fromOffset(366, 46),
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
	-- and under that, the quests: the town's next goals
	Quests.mount(hud, QUESTS_AT, function()
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
	local function refreshCity()
		local stats = Hud.cityStats()
		popLabel.Text = tostring(stats.population)
		badgeText.Text = tostring(stats.level)
		local t = levelProgress(stats)
		TweenService:Create(fill, TweenInfo.new(0.4), { Size = UDim2.fromScale(math.max(t, 0.04), 1) }):Play()
		levelLine.Text = stats.levelName
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
	-- and Hide. (A Map and a Shop button stood here too. The user: "remove the shop, buying of
	-- things and food and feeding" and "remove the map button and the map interface".)
	local corner = Kit.box({
		Name = "Corner",
		-- (eight cells of 54 and their gaps: Home, the town, the news, the Store, the Garage, the Bag,
		-- Settings and Hide)
		Size = UDim2.fromOffset(8 * 54 + 7 * 8, 76),
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
			-- the things you carry, to hold, drop and give (the user: "add an inventory system to the player")
			{ "bag", "Bag", "Bag" },
			-- what this screen draws, and the look (the user: "add settings for graphic quality,
			-- background blur, bloom, etc.")
			{ "gear", "Settings", "Settings" },
		}
	do
		cornerButton(e[1], e[2], e[3], i + 1, function()
			Hud.open(e[2])
		end)
	end
	-- Hide, always the last of the row: it slides the whole main screen away and leaves Show in
	-- its place (the user: "The light/dark button at the top of the ui should be changed to
	-- "Hide", which hides all UI elements, sliding them away, leaving a small button "Show" which
	-- reshows the ui elements"). Dark or light is a setting now (UI/Theme keeps it).
	local hideCell = cornerButton("eye", "Hide", "Hide", HIDE_ORDER, function()
		Hud.setHidden(true)
	end)
	-- Show stands on its own where Hide is, so it stays while the row slides away
	local showCell = cornerButton("eye", "Show", "Show", HIDE_ORDER, function()
		Hud.setHidden(false)
	end)
	showCell.Parent = hud
	showCell.AnchorPoint = Vector2.new(1, 0)
	showCell.Position = corner.Position
	showCell.Visible = false
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
		-- (on the tutorial's first step it asks how to make the first villager: UI/Tutorial)
		if Hud.panel("Tutorial").takeCreate() then
			return
		end
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

	-- Every piece of the main screen slides off its own edge and back to where it was. Hide sends
	-- them all (UI/Toasts' notices still come); while somebody is talking in a scene (a villager
	-- you stopped, an event you chose to watch: the user, "when text from a villager appears, make
	-- the character talking slide into view at the side with a textbox") the bottom of the screen
	-- and its left side are theirs, so the menu bar, the Build button and the quests step aside.
	-- The cards say so with State.set("talking", true / false).
	local hidden, aside = false, false
	local slides: { { frame: GuiObject, home: UDim2, away: UDim2, forScenes: boolean, tween: Tween? } } = {}
	local function slide(frame: GuiObject?, dx: number, dy: number, forScenes: boolean)
		if frame then
			table.insert(slides, {
				frame = frame,
				home = frame.Position,
				away = frame.Position + UDim2.fromOffset(dx, dy),
				forScenes = forScenes,
			})
		end
	end
	slide(card, -380, 0, false)
	slide(pills, -(pills.Size.X.Offset + 60), 0, false)
	slide(Quests.root(), -440, 0, true)
	-- the clock's slab and the round buttons under it go up off the top
	slide(clockTab, 0, -(clockTab.Size.Y.Offset + 20), false)
	slide(clock, 0, -(clock.Size.Y.Offset + 30), false)
	slide(corner, 0, -(corner.Position.Y.Offset + corner.Size.Y.Offset + inset + 20), false)
	slide(menu, -460, 0, true)
	slide(buildButton, 320, 0, true)
	local function place()
		for i, s in slides do
			local off = hidden or (aside and s.forScenes)
			-- (a slide still on its way, or waiting its turn, gives way to the new one)
			if s.tween then
				s.tween:Cancel()
			end
			-- off quickly, back in easing out to rest, one just after another
			s.tween = Kit.tween(s.frame, Kit.later(if off then SLIDE_OFF else SLIDE_BACK, (i - 1) * SLIDE_STEP), {
				Position = if off then s.away else s.home,
			})
		end
	end
	State.on("talking", function(v)
		if (v == true) ~= aside then
			aside = v == true
			place()
		end
	end)
	-- Hide leaves Show where it was; Show waits there until the row is back under it
	local function faces(cell: Instance, on: boolean)
		for _, c in cell:GetChildren() do
			if c:IsA("GuiObject") then
				c.Visible = on
			end
		end
	end
	local turn = 0
	setHidden = function(on: boolean)
		if on == hidden then
			return
		end
		hidden = on
		turn += 1
		local mine = turn
		if on then
			faces(hideCell, false)
			showCell.Visible = true
		else
			task.delay(SLIDE_BACK_TIME + #slides * SLIDE_STEP, function()
				if turn == mine then
					showCell.Visible = false
					faces(hideCell, true)
				end
			end)
		end
		place()
	end

	-- everything slides into place when the game starts, one piece after another
	-- (as Kit.slideIn does, kept with the slides so a Hide pressed meanwhile takes over)
	local function enter(frame: GuiObject, dx: number, dy: number, delay: number)
		for _, s in slides do
			if s.frame == frame then
				frame.Position = s.home + UDim2.fromOffset(dx, dy)
				s.tween = Kit.tween(frame, Kit.later(SLIDE_ENTER, delay), { Position = s.home })
			end
		end
	end
	enter(pills, -500, 0, 0.1)
	enter(card, -360, 0, 0.2)
	enter(clockTab, 260, 0, 0.15)
	enter(clock, 260, 0, 0.15)
	enter(corner, 320, 0, 0.2)
	enter(menu, -480, 0, 0.25)
	enter(buildButton, 260, 0, 0.3)
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

	-- the tutorial (UI/Tutorial): a friend says what to do, then the screen darkens round the
	-- one thing to press
	Hud.panel("Tutorial").start(Hud)

	-- what the town earned while the player was away (UI/WelcomeBack; Sim/Offline)
	Hud.panel("WelcomeBack").start(Hud)
end

return Hud
