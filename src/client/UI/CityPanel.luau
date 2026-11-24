-- The city hall panel: your town's level and what the next one needs, the numbers that matter
-- (people, happiness, worth, a day's wages), buying more land, and the workplaces with who fills
-- them.
-- A full menu (Kit.panel): the town on the card at the left with its level as the headline, the
-- land and the work down the right.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Remotes = require(Shared.Net.Remotes)
local Tuning = require(Shared.Config.Tuning)
local City = require(Shared.Sim.City)
local Text = require(Shared.Util.Text)

local Kit = require(script.Parent.Kit)
local Icons = require(script.Parent.Icons)
local MenuParts = require(script.Parent.MenuParts)
local Toasts = require(script.Parent.Toasts)
local State = require(script.Parent.Parent.Controllers.State)

local CityPanel = {}

local T = Kit.Theme
local panel: any = nil
local unbind: { () -> () } = {}
local draw: () -> () -- (below: everything in the panel, built again)
-- What the coins decide on the panel, as draw() last showed it: whether the next land could be
-- bought, the note under it saying how many more coins it needs, and what work has brought in.
-- Villagers earn as they work (the user: "make it such that villagers earn coins as they work,
-- not after every day"), so the coins move every few seconds: the panel is only built again when
-- the land's button would change, and these numbers are changed where they stand.
local landCan: boolean? = nil
local landNote: Frame? = nil
local earnedLabel: TextLabel? = nil

local function profileView(): any
	return { villagers = State.data.villagers or {}, plan = State.plan, coins = State.data.coins or 0 }
end

-- The land a level opens up, if any.
local function landAt(level: number): any
	for _, land in Tuning.City.Land do
		if land.Level == level and land.Price > 0 then
			return land
		end
	end
	return nil
end

-- The card on the left: the level as the headline, what the next one needs and brings, and the
-- town's numbers as tiles along the bottom.
local function town(inside: Frame, stats: any, wages: number)
	local accent = T.Purple
	-- the level: a round dial with its number, the name big beside it
	MenuParts.dial(tostring(stats.level), "LEVEL", accent, { Name = "Level", Parent = inside, Size = 72 })
	Kit.title(stats.levelName, {
		Name = "LevelName",
		Parent = inside,
		Size = UDim2.new(1, -88, 0, 44),
		Position = UDim2.fromOffset(88, 2),
		TextSize = 40,
		Wrap = false,
	})
	Kit.text(Text.fill("Level {n} of {max}", { n = stats.level, max = #Tuning.City.Levels }), {
		Name = "LevelOf",
		Parent = inside,
		Size = UDim2.new(1, -88, 0, 20),
		Position = UDim2.fromOffset(88, 46),
		TextSize = 15,
		Color = T.InkSoft,
	})

	-- what the next level needs, as a bar for each thing it asks (villagers, worth and, from some
	-- levels on, villagers at work), and what it brings
	local nextLevel = stats.nextLevel
	local STEP = 48
	if nextLevel then
		local name = nextLevel.Name:lower()
		Kit.text(Text.fill("To become {a}", { a = Text.an(name) }), {
			Name = "Next",
			Parent = inside,
			Size = UDim2.new(1, 0, 0, 22),
			Position = UDim2.fromOffset(0, 86),
			TextSize = 17,
			Font = Kit.Fonts.Bold,
		})
		local y = 116
		local pop, need = stats.population, nextLevel.Pop
		MenuParts.progress(
			"Villagers",
			Text.fill("{a} of {b}", { a = math.min(pop, need), b = need }),
			pop / math.max(1, need),
			{ Name = "Villagers", Parent = inside, Position = UDim2.fromOffset(0, y), Color = accent }
		)
		y += STEP
		local worth, wneed = stats.value, nextLevel.Value
		MenuParts.progress(
			"Worth",
			Text.fill("{a} of {b}", { a = Text.commas(math.min(worth, wneed)), b = Text.commas(wneed) }),
			worth / math.max(1, wneed),
			{ Name = "Worth", Parent = inside, Position = UDim2.fromOffset(0, y), Color = accent, Coin = true }
		)
		y += STEP
		local workers = nextLevel.Workers
		if type(workers) == "number" and workers > 0 then
			local at = stats.employed or 0
			MenuParts.progress(
				"At work",
				Text.fill("{a} of {b}", { a = math.min(at, workers), b = workers }),
				at / workers,
				{ Name = "AtWork", Parent = inside, Position = UDim2.fromOffset(0, y), Color = accent }
			)
			y += STEP
		end
		local land = landAt(stats.level + 1)
		MenuParts.note(
			if land
				then Text.fill("{A} can buy more land, up to {n} by {n} studs.", {
					A = (Text.an(name):gsub("^%l", string.upper)),
					n = land.Size,
				})
				else "Worth goes up with everything you build.",
			accent,
			{ Name = "Unlocks", Parent = inside, Position = UDim2.fromOffset(0, y + 4), Height = 24 }
		)
	else
		Kit.text("Your town is as big as towns get.", {
			Name = "Next",
			Parent = inside,
			Size = UDim2.new(1, 0, 0, 22),
			Position = UDim2.fromOffset(0, 86),
			TextSize = 17,
			Font = Kit.Fonts.Bold,
		})
		MenuParts.note(
			"There's no level after this one. Build whatever you like.",
			accent,
			{ Name = "Unlocks", Parent = inside, Position = UDim2.fromOffset(0, 116), Height = 44 }
		)
	end

	-- the town's numbers, two by two along the bottom
	local grid = Kit.box({
		Name = "Stats",
		Parent = inside,
		Size = UDim2.new(1, 0, 0, 76 * 2 + 10),
		Position = UDim2.new(0, 0, 1, -(76 * 2 + 10)),
	})
	Kit.grid(grid, UDim2.new(0.5, -5, 0, 76), 10)
	MenuParts.stat("people", "Villagers", tostring(stats.population), T.Green, {
		Name = "People",
		Parent = grid,
		LayoutOrder = 1,
		Sub = Text.fill("of {n}", { n = Tuning.Villagers.Max }),
	})
	MenuParts.stat("smile", "Happiness", Text.fill("{n}%", { n = stats.happiness }), T.Yellow, {
		Name = "Happiness",
		Parent = grid,
		LayoutOrder = 2,
		Sub = if stats.population == 0
			then "nobody yet"
			elseif stats.happiness >= 60 then "on average"
			else "could be better",
	})
	MenuParts.stat("house", "Town worth", Text.commas(stats.value), T.Orange, {
		Name = "TownWorth",
		Parent = grid,
		LayoutOrder = 3,
		Coin = true,
	})
	-- what everyone in work earns in a whole day there, a little at a time as they work
	MenuParts.stat("briefcase", "A day's wages", Text.commas(wages), T.Blue, {
		Name = "Wages",
		Parent = grid,
		LayoutOrder = 4,
		Coin = true,
		Sub = "while they work",
	})
end

-- Buying the next piece of land: a row with what it is, what it costs and a button that says
-- what's in the way when it can't be bought yet.
local function landRow(list: ScrollingFrame, stats: any, coins: number, order: number)
	local land = stats.nextLand
	landCan, landNote = nil, nil
	if not land then
		Kit.row({
			Name = "Land",
			Parent = list,
			Size = MenuParts.rowSize(),
			LayoutOrder = order,
			Title = "You own all the land there is",
			Sub = Text.fill("{n} by {n} studs to build on", { n = stats.land }),
			Marker = "check",
			MarkerColor = T.Green,
		})
		return
	end
	local needLevel = Tuning.City.Levels[land.Level]
	local short = land.Price - coins
	local can = stats.level >= land.Level and short <= 0
	local why = if stats.level < land.Level
		then Text.fill("Your town needs to be {a} first.", { a = Text.an(needLevel.Name:lower()) })
		elseif short > 0 then Text.fill("You need {n} more coins.", { n = Text.commas(short) })
		else nil
	local row, inner = Kit.row({
		Name = "Land",
		Parent = list,
		Size = MenuParts.rowSize(64),
		Height = 64,
		LayoutOrder = order,
		Title = Text.fill("{n} by {n} studs", { n = land.Size }),
		Sub = " ", -- (the price goes here, with its coin)
		Marker = "ruler",
		MarkerColor = if can then T.Green else T.Purple,
		RightSpace = 200,
	})
	-- what it costs, under the size: the coin and the price
	local lean: number = row:GetAttribute("Lean") or 0
	local left = lean + (64 - 22) + 22
	local cost = Kit.box({
		Name = "Cost",
		Parent = inner,
		Size = UDim2.new(1, -left - 200 - lean, 0, 18),
		Position = UDim2.new(0, left, 0.5, 2),
	})
	cost.ZIndex = 2
	Kit.list(cost, 5, true)
	Kit.text("Costs", {
		Name = "Sub",
		Parent = cost,
		Size = UDim2.fromOffset(0, 18),
		AutomaticSize = Enum.AutomaticSize.X,
		TextSize = 14,
		Color = T.InkSoft,
		Wrap = false,
		LayoutOrder = 1,
		ZIndex = 2,
	})
	Icons.make("coin", 15, { Parent = cost, LayoutOrder = 2, ZIndex = 2 })
	Kit.text(Text.commas(land.Price), {
		Name = "Sub",
		Parent = cost,
		Size = UDim2.fromOffset(0, 18),
		AutomaticSize = Enum.AutomaticSize.X,
		TextSize = 14,
		Font = Kit.Fonts.Bold,
		Color = T.InkSoft,
		Wrap = false,
		LayoutOrder = 3,
		ZIndex = 2,
	})
	local button = Kit.button(
		if can
			then Text.fill("Buy for {n}", { n = Text.commas(land.Price) })
			elseif stats.level < land.Level then Text.fill("Reach {name}", { name = needLevel.Name:lower() })
			else Text.fill("{n} coins", { n = Text.commas(land.Price) }),
		{
			Name = "BuyLand",
			Parent = inner,
			Size = UDim2.fromOffset(176, 42),
			Position = UDim2.new(1, -28, 0.5, 0),
			AnchorPoint = Vector2.new(1, 0.5),
			Color = if can then T.Green else T.PaperDark,
			TextColor = if can then T.White else T.InkSoft,
			TextSize = 17,
			Icon = if can or stats.level >= land.Level then "coin" else nil,
			ZIndex = 3,
		},
		function()
			if not can then
				Toasts.show(why or "", "warn")
				return
			end
			task.spawn(function()
				local ok, err = Remotes.fn("PlotExpand"):InvokeServer()
				if not ok and err then
					Toasts.show(err, "warn")
				end
				task.wait(0.4)
				if panel then
					draw()
				end
			end)
		end
	)
	button:SetAttribute("Disabled", not can)
	landCan = can
	if why then
		-- what's in the way, right under the row
		local note = MenuParts.note(why, T.Red, { Name = "LandWhy", Parent = list, LayoutOrder = order + 1 })
		if stats.level >= land.Level then
			landNote = note
		end
	end
end

function draw()
	if not panel then
		return
	end
	for _, c in panel.body:GetChildren() do
		c:Destroy()
	end
	local p = profileView()
	local stats = City.stats(p)
	local lines, total = City.wages(p, -1, os.time())

	local _, inside = MenuParts.card(panel.body, T.Purple)
	town(inside, stats, total)

	-- the land and the work down the right
	local list = MenuParts.list(panel.body)
	MenuParts.heading(list, "Land", T.Purple, 1, Text.fill("{n} by {n} now", { n = stats.land }))
	landRow(list, stats, p.coins, 2)

	MenuParts.heading(
		list,
		"Work",
		T.Purple,
		10,
		if stats.jobs > 0 then Text.fill("{a} of {b} filled", { a = stats.employed, b = stats.jobs }) else nil
	)
	local workers = {}
	for _, l in lines do
		workers[l.vid] = l.amount
	end
	local i = 11
	for _, w in City.workplaces(State.plan) do
		local who, amount = nil, nil
		for vid, v in p.villagers do
			if v.job == w.key then
				who = v.name
				amount = workers[vid]
			end
		end
		Kit.row({
			Name = "Job",
			Parent = list,
			Size = MenuParts.rowSize(),
			LayoutOrder = i,
			Title = Text.fill("{job}, {place}", { job = w.job.name, place = w.def.name:lower() }),
			Sub = if who
				then Text.fill("{name}, about {n} coins a day", { name = who, n = amount or w.job.income })
				else "Nobody works here yet. Pick someone on the Villagers screen.",
			Marker = "briefcase",
			MarkerColor = if who then T.Purple else T.Line,
		})
		i += 1
	end
	if stats.jobs == 0 then
		MenuParts.empty(
			"briefcase",
			"No workplaces yet",
			"Build one from Work in Build mode, then give a villager the job.",
			{ Parent = list, LayoutOrder = 11 }
		)
	else
		MenuParts.hint(
			"More workplaces are under Work in Build mode. Each one is a job for a villager.",
			{ Name = "More", Parent = list, LayoutOrder = 1000 }
		)
	end
	-- what work has brought in so far, at the foot of the list
	local earned = State.data.stats and State.data.stats.earned or 0
	local foot = Kit.box({ Name = "Earned", Parent = list, Size = UDim2.new(1, -12, 0, 28), LayoutOrder = 999 })
	Kit.pad(foot, 4, 0)
	Kit.list(foot, 6, true)
	Icons.make("coin", 18, { Parent = foot, LayoutOrder = 1 })
	earnedLabel = Kit.title(Text.commas(earned), {
		Name = "Amount",
		Parent = foot,
		Size = UDim2.fromOffset(0, 28),
		AutomaticSize = Enum.AutomaticSize.X,
		TextSize = 17,
		Wrap = false,
		LayoutOrder = 2,
	})
	Kit.text("coins earned from work so far", {
		Parent = foot,
		Size = UDim2.fromOffset(0, 28),
		AutomaticSize = Enum.AutomaticSize.X,
		TextSize = 15,
		Color = T.InkSoft,
		Wrap = false,
		LayoutOrder = 3,
	})
end

-- The coins moved (a pay packet, a purchase): the panel built again only if the land's button
-- would change, else the numbers that follow the coins changed where they are.
local function onCoins()
	if not panel then
		return
	end
	local p = profileView()
	local stats = City.stats(p)
	local land = stats.nextLand
	local can = land ~= nil and stats.level >= land.Level and p.coins >= land.Price
	if landCan ~= nil and can ~= landCan then
		draw()
		return
	end
	local note = landNote
	local words = note and note:FindFirstChild("Text")
	if land and words and words:IsA("TextLabel") and land.Price > p.coins then
		words.Text = Text.fill("You need {n} more coins.", { n = Text.commas(land.Price - p.coins) })
	end
	if earnedLabel and earnedLabel.Parent then
		earnedLabel.Text = Text.commas(State.data.stats and State.data.stats.earned or 0)
	end
end

function CityPanel.isOpen(): boolean
	return panel ~= nil
end

function CityPanel.close()
	for _, u in unbind do
		u()
	end
	unbind = {}
	if panel then
		panel.root:Destroy()
		panel = nil
	end
end

function CityPanel.open()
	CityPanel.close()
	panel = Kit.panel("City hall", Kit.MenuSize, CityPanel.close, "hall", Kit.Theme.Purple)
	Kit.popIn(panel.root)
	draw()
	table.insert(unbind, State.on("coins", onCoins))
	table.insert(unbind, State.on("villagers", draw))
end

-- a change of look builds what's open again in the new one (a row's shading is made for a look)
Kit.onTheme(function()
	if panel then
		draw()
	end
end)

return CityPanel
