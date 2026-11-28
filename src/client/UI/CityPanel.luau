-- The city hall panel: your town's level and what the next one needs, the numbers that matter
-- (people, happiness, worth, a day's wages), buying more land, the workplaces with who fills
-- them, and the player's own skills at the jobs they have worked themselves (Sim/Skills: the
-- user, "each skill also has a level/experience bar, which you gain while doing the work").
-- A full menu (Kit.panel): the town on the card at the left with its level as the headline, the
-- land and the work down the right.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Remotes = require(Shared.Net.Remotes)
local Tuning = require(Shared.Config.Tuning)
local City = require(Shared.Sim.City)
local Skills = require(Shared.Sim.Skills)
local PlayerWork = require(Shared.Sim.PlayerWork)
local Jobs = require(Shared.Data.Jobs)
local Text = require(Shared.Util.Text)

local Kit = require(script.Parent.Kit)
local Icons = require(script.Parent.Icons)
local MenuParts = require(script.Parent.MenuParts)
local Toasts = require(script.Parent.Toasts)
local State = require(script.Parent.Parent.Controllers.State)
local Purchase = require(script.Parent.Parent.Controllers.Purchase) -- (Big Plot, past the free land)
local Social = require(Shared.Sim.Social) -- (friends playing here: the boost to wages)
local Invite = require(script.Parent.Invite)

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
-- The name box: what is typed in it and not saved yet, kept through the panel being built again
-- (the villagers' changes build it again often), and the box itself.
local nameDraft: string? = nil
local nameBox: TextBox? = nil

local function profileView(): any
	return {
		villagers = State.data.villagers or {},
		plan = State.plan,
		coins = State.data.coins or 0,
		passes = State.data.passes, -- (Big Plot: City.landCap)
	}
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
	-- (no top level now: the line under it says how many villagers the town has room for)
	Kit.text(Text.fill("Room for {n} villagers", { n = stats.villagerCap }), {
		Name = "LevelOf",
		Parent = inside,
		Size = UDim2.new(1, -88, 0, 20),
		Position = UDim2.fromOffset(88, 46),
		TextSize = 15,
		Color = T.InkSoft,
	})

	-- what the next level needs: worth, and nothing else ("make the only requirements for growing
	-- towns worth instead of villagers or work requirement"), and what it brings
	local nextLevel = stats.nextLevel
	local STEP = 48
	if nextLevel then
		local milestone = stats.nextMilestone
		Kit.text(
			if milestone and milestone.Level == stats.level + 1
				then Text.fill("To reach level {n} (room for {v})", { n = stats.level + 1, v = milestone.Villagers })
				else Text.fill("To reach level {n}", { n = stats.level + 1 }),
			{
				Name = "Next",
				Parent = inside,
				Size = UDim2.new(1, 0, 0, 22),
				Position = UDim2.fromOffset(0, 86),
				TextSize = 17,
				Font = Kit.Fonts.Bold,
			}
		)
		local y = 116
		local worth, wneed = stats.value, nextLevel.Value
		MenuParts.progress(
			"Worth",
			Text.fill("{a} of {b}", { a = Text.commas(math.min(worth, wneed)), b = Text.commas(wneed) }),
			worth / math.max(1, wneed),
			{ Name = "Worth", Parent = inside, Position = UDim2.fromOffset(0, y), Color = accent, Coin = true }
		)
		y += STEP
		local land = landAt(stats.level + 1)
		-- (land past what is free comes with Big Plot: City.landCap)
		local locked = land ~= nil and stats.landCap ~= nil and land.Size > stats.landCap
		MenuParts.note(
			if land
				then Text.fill(
					if locked then "Unlocks land up to {n} by {n} with Big Plot." else "Unlocks land up to {n} by {n}.",
					{
						lv = stats.level + 1,
						n = land.Size,
					}
				)
				else "Building raises worth.",
			accent,
			{ Name = "Unlocks", Parent = inside, Position = UDim2.fromOffset(0, y + 4), Height = 24 }
		)
	else
		Kit.text("Top level", {
			Name = "Next",
			Parent = inside,
			Size = UDim2.new(1, 0, 0, 22),
			Position = UDim2.fromOffset(0, 86),
			TextSize = 17,
			Font = Kit.Fonts.Bold,
		})
		MenuParts.note(
			"No more levels.",
			accent,
			{ Name = "Unlocks", Parent = inside, Position = UDim2.fromOffset(0, 116), Height = 24 }
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
		Sub = Text.fill("of {n}", { n = stats.villagerCap }),
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

-- The town's name (the user: "allow naming of plots, and the name should appear in place of the big
-- "Level x" at the top left above the level bar"): a box to type it in and Save, or Enter. The
-- server filters it and keeps it (PlotRename, Services/Visit); an empty box takes the name off.
local function nameRow(list: ScrollingFrame, order: number)
	local holder = Kit.box({ Name = "Naming", Parent = list, Size = MenuParts.rowSize(46), LayoutOrder = order })
	local box = MenuParts.input("Name your town", {
		Name = "PlotName",
		Parent = holder,
		Size = UDim2.new(1, -134, 0, 44),
		Text = nameDraft or State.data.plotName or "",
	})
	nameBox = box
	box:GetPropertyChangedSignal("Text"):Connect(function()
		if nameBox == box then
			nameDraft = box.Text
		end
	end)
	local saving = false
	local function save()
		if saving then
			return
		end
		saving = true
		local typed = box.Text
		task.spawn(function()
			local ok, done, words = pcall(function()
				return Remotes.fn("PlotRename"):InvokeServer(typed)
			end)
			saving = false
			if ok and done then
				nameDraft = nil
				Toasts.show(
					if type(words) == "string" and words ~= ""
						then Text.fill("Your town is {name} now.", { name = words })
						else "Your town has no name now.",
					"good"
				)
			else
				Toasts.show(if ok and type(words) == "string" then words else "Couldn't save the name.", "warn")
			end
		end)
	end
	box.FocusLost:Connect(function(enter)
		if enter then
			save()
		end
	end)
	Kit.button("Save", {
		Name = "SaveName",
		Parent = holder,
		Size = UDim2.fromOffset(122, 42),
		Position = UDim2.new(1, 0, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
		Color = T.Green,
		TextSize = 17,
		ZIndex = 3,
	}, save)
end

-- Land past what is free (Tuning.Passes.FreeLand): the row offers Big Plot, with a lock on its
-- button (the user: "another [gamepass] for bigger plot, (make the biggest size smaller without
-- paying smaller)").
local function lockedLandRow(list: ScrollingFrame, land: any, order: number)
	local _, inner = Kit.row({
		Name = "Land",
		Parent = list,
		Size = MenuParts.rowSize(64),
		Height = 64,
		LayoutOrder = order,
		Title = Text.fill("{n} by {n} studs", { n = land.Size }),
		Sub = Text.fill("Past {n} needs Big Plot", { n = Tuning.Passes.FreeLand }),
		Marker = "ruler",
		MarkerColor = T.Purple,
		RightSpace = 200,
	})
	local button = Kit.button("Big Plot", {
		Name = "BuyLand",
		Parent = inner,
		Size = UDim2.fromOffset(176, 42),
		Position = UDim2.new(1, -28, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
		Color = T.Yellow,
		TextColor = T.Dark,
		TextSize = 17,
		Icon = "lock",
		ZIndex = 3,
	}, function()
		Purchase.prompt("bigplot")
	end)
	button:SetAttribute("Locked", true)
	landCan = false
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
			Title = "All the land is yours",
			Sub = Text.fill("{n} by {n} studs", { n = stats.land }),
			Marker = "check",
			MarkerColor = T.Green,
		})
		return
	end
	if stats.landLocked then
		lockedLandRow(list, land, order)
		return
	end
	local short = land.Price - coins
	local can = stats.level >= land.Level and short <= 0
	local why = if stats.level < land.Level
		then Text.fill("Needs level {n}.", { n = land.Level })
		elseif short > 0 then Text.fill("{n} more coins needed.", { n = Text.commas(short) })
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
			elseif stats.level < land.Level then Text.fill("Reach level {n}", { n = land.Level })
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

-- Friends playing here, a tenth more wages each (the user: "add a 10% income boosy per friend
-- playing, and prompt the player to invite friends"), and the players you trust to build on your
-- plot with what is left of each one's budget (Services/Trust; a player's card changes it).
local function friendRows(list: ScrollingFrame, order: number)
	local me = game:GetService("Players").LocalPlayer
	local here = Social.count(if me then me:GetAttribute("FriendsHere") else 0)
	MenuParts.heading(
		list,
		"Friends",
		T.Purple,
		order,
		if here > 0 then Text.fill("+{n}%", { n = Social.percent(here) }) else nil
	)
	local _, inner = Kit.row({
		Name = "FriendsHere",
		Parent = list,
		Size = MenuParts.rowSize(64),
		Height = 64,
		LayoutOrder = order + 1,
		Title = Social.line(here),
		Sub = Text.fill("Up to +{n}% with {m} friends", {
			n = Social.percent(Tuning.Friends.Most),
			m = Tuning.Friends.Most,
		}),
		Marker = "people",
		MarkerColor = if here > 0 then T.Green else T.Purple,
		RightSpace = 170,
	})
	Invite.button("Invite", {
		Parent = inner,
		Size = UDim2.fromOffset(146, 42),
		Position = UDim2.new(1, -28, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
		TextSize = 17,
		ZIndex = 3,
	})
	local trusted = State.data.trusted
	local rows = if type(trusted) == "table" then trusted else {}
	MenuParts.heading(list, "Trusted builders", T.Purple, order + 2, if #rows > 0 then tostring(#rows) else nil)
	if #rows == 0 then
		MenuParts.note(
			"Click another player to let them build here.",
			T.Purple,
			{ Name = "NoTrusted", Parent = list, LayoutOrder = order + 3 }
		)
		return
	end
	for i, row in rows do
		local _, rowInner = Kit.row({
			Name = "Trusted",
			Parent = list,
			Size = MenuParts.rowSize(64),
			Height = 64,
			LayoutOrder = order + 2 + i,
			Title = tostring(row.name),
			Sub = Text.fill(
				"{left} of {budget} coins left",
				{ left = Text.commas(row.left or 0), budget = Text.commas(row.budget or 0) }
			),
			Marker = "hammer",
			MarkerColor = T.Purple,
			RightSpace = 130,
		})
		Kit.button("Stop", {
			Name = "Untrust",
			Parent = rowInner,
			Size = UDim2.fromOffset(104, 42),
			Position = UDim2.new(1, -28, 0.5, 0),
			AnchorPoint = Vector2.new(1, 0.5),
			Color = T.Red,
			TextSize = 17,
			ZIndex = 3,
		}, function()
			task.spawn(function()
				local ok, done, why = pcall(function()
					return Remotes.fn("TrustSet"):InvokeServer(row.id, false)
				end)
				if not (ok and done) then
					Toasts.show(if ok and type(why) == "string" then why else "Couldn't do that.", "warn")
				end
			end)
		end)
	end
end

function draw()
	if not panel then
		return
	end
	-- (someone typing a name keeps typing in the box built again)
	local typing = false
	if nameBox then
		local box = nameBox
		pcall(function()
			typing = box:IsFocused()
		end)
	end
	nameBox = nil
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
	MenuParts.heading(list, "Name", T.Purple, -2, nil)
	nameRow(list, -1)
	if typing and nameBox then
		local box = nameBox
		pcall(function()
			box:CaptureFocus()
		end)
	end
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
				else "Nobody works here yet",
			Marker = Jobs.icon(w.job.id),
			MarkerColor = if who then T.Purple else T.Line,
		})
		i += 1
	end
	if stats.jobs == 0 then
		MenuParts.empty(
			"briefcase",
			"No workplaces yet",
			"Build one in Build mode.",
			{ Parent = list, LayoutOrder = 11 }
		)
	else
		MenuParts.hint("More workplaces are in Build mode.", { Name = "More", Parent = list, LayoutOrder = 1000 })
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
	Kit.text("coins from work", {
		Parent = foot,
		Size = UDim2.fromOffset(0, 28),
		AutomaticSize = Enum.AutomaticSize.X,
		TextSize = 15,
		Color = T.InkSoft,
		Wrap = false,
		LayoutOrder = 3,
	})
	friendRows(list, 2000)
	-- the player's own skills: each job they have worked, its level and its bar
	local skills = Skills.list({ skills = State.data.skills })
	MenuParts.heading(list, "Your skills", T.Purple, 1010, nil)
	if #skills == 0 then
		MenuParts.note(
			"Work at a workplace to learn its job.",
			T.Purple,
			{ Name = "NoSkills", Parent = list, LayoutOrder = 1011 }
		)
	end
	for n, info in skills do
		MenuParts.progress(
			PlayerWork.skillLine(info.name, info.level, info.top),
			if info.top then "" else Text.fill("{a} of {b}", { a = info.into, b = info.need }),
			if info.top then 1 elseif info.need > 0 then info.into / info.need else 0,
			{ Name = "Skill", Parent = list, Size = UDim2.new(1, -12, 0, 44), LayoutOrder = 1010 + n, Color = T.Purple }
		)
	end
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
	local can = land ~= nil and not stats.landLocked and stats.level >= land.Level and p.coins >= land.Price
	if landCan ~= nil and can ~= landCan then
		draw()
		return
	end
	local note = landNote
	local words = note and note:FindFirstChild("Text")
	if land and words and words:IsA("TextLabel") and land.Price > p.coins then
		words.Text = Text.fill("{n} more coins needed.", { n = Text.commas(land.Price - p.coins) })
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
		Kit.closePanel(panel)
		panel = nil
	end
	nameBox = nil
end

-- arg: { rename = true } (the name on the main screen was tapped) puts the cursor in the name box.
function CityPanel.open(arg: any?)
	CityPanel.close()
	nameDraft = nil
	panel = Kit.panel("City hall", Kit.MenuSize, CityPanel.close, "hall", Kit.Theme.Purple, { Caption = "Your town" })
	draw()
	if type(arg) == "table" and arg.rename and nameBox then
		local box = nameBox
		task.defer(function()
			pcall(function()
				box:CaptureFocus()
			end)
		end)
	end
	table.insert(unbind, State.on("plotName", draw)) -- (named: the box shows it)
	table.insert(unbind, State.on("coins", onCoins))
	table.insert(unbind, State.on("villagers", draw))
	table.insert(unbind, State.on("passes", draw)) -- (Big Plot bought: the land row opens)
	table.insert(unbind, State.on("skills", draw)) -- (work done: the skills grew)
	table.insert(unbind, State.on("trusted", draw)) -- (a player trusted, or their budget spent)
	local me = game:GetService("Players").LocalPlayer
	if me then
		local friends = me:GetAttributeChangedSignal("FriendsHere"):Connect(draw)
		table.insert(unbind, function()
			friends:Disconnect()
		end)
	end
end

-- a change of look builds what's open again in the new one (a row's shading is made for a look)
Kit.onTheme(function()
	if panel then
		draw()
	end
end)

return CityPanel
