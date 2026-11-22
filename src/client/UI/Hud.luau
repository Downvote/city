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

local function buildBuildButton(bar: Instance, order: number)
	local BuildMode = require(script.Parent.Parent.Build.BuildMode)
	local BuildUI = require(script.Parent.Parent.Build.BuildUI)
	BuildUI.init(function()
		BuildMode.exit()
	end)
	BuildMode.Changed:Connect(function(what)
		if what == "active" and bar:IsA("GuiObject") then
			bar.Visible = not BuildMode.isActive()
		end
	end)
	return Kit.button(
		"Build",
		{ Parent = bar, Size = UDim2.fromOffset(104, 52), Color = T.Blue, LayoutOrder = order },
		function()
			Hud.closeAll()
			BuildMode.enter()
		end
	)
end

function Hud.start()
	local gui = Kit.root()

	-- coins and city -------------------------------------------------------------------------------
	local info = Kit.frame({
		Name = "Info",
		Size = UDim2.fromOffset(260, 96),
		Position = UDim2.fromOffset(12, 12),
		Stroke = T.Line,
		Parent = gui,
	})
	Kit.pad(info, 12, 8)
	local coins = Kit.title("0", { Parent = info, Size = UDim2.new(1, 0, 0, 34), TextSize = 30, Color = T.YellowDark })
	local cityLine = Kit.text("", {
		Parent = info,
		Size = UDim2.new(1, 0, 0, 22),
		Position = UDim2.fromOffset(0, 36),
		TextSize = 17,
		Font = Kit.Fonts.Bold,
	})
	local popLine = Kit.text("", {
		Parent = info,
		Size = UDim2.new(1, 0, 0, 20),
		Position = UDim2.fromOffset(0, 58),
		TextSize = 15,
		Color = T.InkSoft,
	})
	local shown = 0
	local function setCoins(n: number)
		local from = shown
		shown = n
		local value = Instance.new("NumberValue")
		value.Value = from
		value.Changed:Connect(function(v)
			coins.Text = Text.commas(v) .. " coins"
		end)
		TweenService:Create(value, TweenInfo.new(0.6), { Value = n }):Play()
		task.delay(0.7, function()
			value:Destroy()
		end)
		if n > from and from > 0 then
			local pop = Kit.title("+" .. Text.commas(n - from), {
				Parent = info,
				Size = UDim2.fromOffset(120, 24),
				Position = UDim2.new(1, -110, 0, 6),
				TextSize = 20,
				Color = T.GreenDark,
			})
			TweenService
				:Create(pop, TweenInfo.new(1.2), { Position = UDim2.new(1, -110, 0, -24), TextTransparency = 1 })
				:Play()
			task.delay(1.3, function()
				pop:Destroy()
			end)
		end
	end
	local function refreshCity()
		local stats = Hud.cityStats()
		cityLine.Text = Text.fill("{level} (level {n})", { level = stats.levelName, n = stats.level })
		popLine.Text = Text.fill("{pop} villagers, {mood}% happy, {jobs}/{all} jobs filled", {
			pop = stats.population,
			mood = stats.happiness,
			jobs = stats.employed,
			all = stats.jobs,
		})
	end
	State.on("coins", function(n)
		setCoins(n or 0)
	end)
	State.on("villagers", refreshCity)
	State.onPlan(function()
		refreshCity()
	end)

	-- clock --------------------------------------------------------------------------------------------
	local clock = Kit.frame({
		Name = "Clock",
		Size = UDim2.fromOffset(210, 70),
		Position = UDim2.new(1, -222, 0, 12),
		Stroke = T.Line,
		Parent = gui,
	})
	Kit.pad(clock, 12, 6)
	local timeLabel = Kit.title(
		"",
		{ Parent = clock, Size = UDim2.new(1, 0, 0, 30), TextSize = 24, AlignX = Enum.TextXAlignment.Right }
	)
	local dateLabel = Kit.text("", {
		Parent = clock,
		Size = UDim2.new(1, 0, 0, 20),
		Position = UDim2.fromOffset(0, 32),
		TextSize = 15,
		Color = T.InkSoft,
		AlignX = Enum.TextXAlignment.Right,
	})
	task.spawn(function()
		while true do
			local h = Lighting.ClockTime
			timeLabel.Text = Text.clock(h)
			local season = workspace:GetAttribute("Season")
			local day = workspace:GetAttribute("Day")
			local weather = workspace:GetAttribute("Weather")
			dateLabel.Text = Text.fill("{season} {day}, {weather}", {
				season = SEASONS[if type(season) == "number" then season else 1],
				day = if type(day) == "number" then day else 1,
				weather = (WEATHER[weather :: any] or "Clear"):lower(),
			})
			task.wait(1)
		end
	end)

	-- main buttons ------------------------------------------------------------------------------------
	local bar = Kit.frame({
		Name = "MainBar",
		Size = UDim2.fromOffset(0, 68),
		AutomaticSize = Enum.AutomaticSize.X,
		Position = UDim2.new(0.5, 0, 1, -12),
		AnchorPoint = Vector2.new(0.5, 1),
		Stroke = T.Line,
		Parent = gui,
	})
	Kit.pad(bar, 8, 8)
	Kit.list(bar, 8, true)
	buildBuildButton(bar, 1)
	Kit.button(
		"Villagers",
		{ Parent = bar, Size = UDim2.fromOffset(112, 52), Color = T.Green, LayoutOrder = 2 },
		function()
			Hud.open("Residents")
		end
	)
	Kit.button(
		"New villager",
		{ Parent = bar, Size = UDim2.fromOffset(132, 52), Color = T.Coral, LayoutOrder = 3 },
		function()
			Hud.open("Creator", { mode = "new" })
		end
	)
	Kit.button("City", { Parent = bar, Size = UDim2.fromOffset(90, 52), Color = T.Purple, LayoutOrder = 4 }, function()
		Hud.open("CityPanel")
	end)
	Kit.button(
		"Shop",
		{ Parent = bar, Size = UDim2.fromOffset(90, 52), Color = T.Yellow, TextColor = T.Ink, LayoutOrder = 5 },
		function()
			Hud.open("ShopPanel")
		end
	)
	Kit.button(
		"News",
		{ Parent = bar, Size = UDim2.fromOffset(90, 52), Color = T.PaperDark, TextColor = T.Ink, LayoutOrder = 6 },
		function()
			Hud.open("News")
		end
	)

	-- daily gift ---------------------------------------------------------------------------------------
	local gift = Kit.button("Daily gift", {
		Parent = gui,
		Size = UDim2.fromOffset(130, 44),
		Position = UDim2.fromOffset(12, 118),
		Color = T.Yellow,
		TextColor = T.Ink,
		TextSize = 18,
	})
	gift.Visible = false
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
