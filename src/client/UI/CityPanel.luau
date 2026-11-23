-- The city hall panel: your town's level and what the next one needs, happiness, jobs and who
-- fills them, what a payday brings in, and buying more land.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Remotes = require(Shared.Net.Remotes)
local Tuning = require(Shared.Config.Tuning)
local City = require(Shared.Sim.City)
local Text = require(Shared.Util.Text)

local Kit = require(script.Parent.Kit)
local Toasts = require(script.Parent.Toasts)
local State = require(script.Parent.Parent.Controllers.State)

local CityPanel = {}

local T = Kit.Theme
local panel: any = nil
local unbind: { () -> () } = {}

local function profileView(): any
	return { villagers = State.data.villagers or {}, plan = State.plan, coins = State.data.coins or 0 }
end

local function progress(parent: Instance, label: string, have: number, need: number, order: number)
	local row = Kit.box({ Parent = parent, Size = UDim2.new(1, 0, 0, 40), LayoutOrder = order })
	Kit.text(
		Text.fill("{label}: {have} of {need}", { label = label, have = Text.commas(have), need = Text.commas(need) }),
		{ Parent = row, TextSize = 16, Size = UDim2.new(1, 0, 0, 20) }
	)
	Kit.bar(
		{ Parent = row, Size = UDim2.new(1, -4, 0, 14), Position = UDim2.fromOffset(2, 23) },
		have / math.max(1, need),
		if have >= need then T.Green else T.Blue
	)
end

local function draw()
	if not panel then
		return
	end
	for _, c in panel.body:GetChildren() do
		c:Destroy()
	end
	local p = profileView()
	local stats = City.stats(p)
	-- the town itself on a card on the left, the workplaces as rows down the right
	local card = Kit.frame({
		Name = "Detail",
		Parent = panel.body,
		Size = UDim2.new(0.46, -10, 1, 0),
		Color = T.Paper,
		Radius = 24,
	})
	local left = Kit.scroll({ Parent = card, Size = UDim2.new(1, -44, 1, -40), Position = UDim2.fromOffset(24, 20) })
	Kit.list(left, 8)
	Kit.title(
		Text.fill("{name}, level {n}", { name = stats.levelName, n = stats.level }),
		{ Parent = left, TextSize = 26, LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 32) }
	)
	Kit.text(
		Text.fill("{pop} villagers, {mood}% happy on average. Your town is worth {value} coins.", {
			pop = stats.population,
			mood = stats.happiness,
			value = Text.commas(stats.value),
		}),
		{ Parent = left, TextSize = 16, LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 44) }
	)
	if stats.nextLevel then
		Kit.text(
			Text.fill("To become {name}:", { name = stats.nextLevel.Name:lower() }),
			{ Parent = left, TextSize = 17, Font = Kit.Fonts.Bold, LayoutOrder = 3 }
		)
		progress(left, "Villagers", stats.population, stats.nextLevel.Pop, 4)
		progress(left, "Worth", stats.value, stats.nextLevel.Value, 5)
	else
		Kit.text("Your town is as big as towns get. Well done.", { Parent = left, TextSize = 17, LayoutOrder = 3 })
	end

	Kit.title("Land", { Parent = left, TextSize = 22, LayoutOrder = 10, Size = UDim2.new(1, 0, 0, 30) })
	Kit.text(
		Text.fill("You can build on {n} by {n} studs.", { n = stats.land }),
		{ Parent = left, TextSize = 16, LayoutOrder = 11 }
	)
	local land = stats.nextLand
	if land then
		local needLevel = Tuning.City.Levels[land.Level]
		local can = stats.level >= land.Level and p.coins >= land.Price
		local why = if stats.level < land.Level
			then Text.fill("Needs your town to be {name} first.", { name = needLevel.Name:lower() })
			elseif p.coins < land.Price then Text.fill(
				"You need {n} more coins.",
				{ n = Text.commas(land.Price - p.coins) }
			)
			else "Ready to buy."
		Kit.text(
			Text.fill(
				"Next: {n} by {n} for {price} coins. {why}",
				{ n = land.Size, price = Text.commas(land.Price), why = why }
			),
			{
				Parent = left,
				TextSize = 16,
				LayoutOrder = 12,
				Size = UDim2.new(1, 0, 0, 44),
			}
		)
		Kit.button("Buy more land", {
			Parent = left,
			Size = UDim2.fromOffset(200, 44),
			Color = if can then T.Green else T.PaperDark,
			TextColor = if can then T.White else T.InkSoft,
			LayoutOrder = 13,
			Radius = "pill",
		}, function()
			if not can then
				Toasts.show(why, "warn")
				return
			end
			task.spawn(function()
				local ok, err = Remotes.fn("PlotExpand"):InvokeServer()
				if not ok and err then
					Toasts.show(err, "warn")
				end
				task.wait(0.4)
				draw()
			end)
		end)
	else
		Kit.text("You own all the land there is.", { Parent = left, TextSize = 16, LayoutOrder = 12 })
	end

	-- jobs on the right
	local right =
		Kit.scroll({ Parent = panel.body, Size = UDim2.new(0.54, -10, 1, 0), Position = UDim2.new(0.46, 10, 0, 0) })
	Kit.list(right, 8)
	Kit.title("Work", { Parent = right, TextSize = 22, LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 30) })
	local lines, total = City.payday(p, -1, os.time())
	Kit.text(
		Text.fill("{jobs}, {employed} filled. A payday at 5 PM brings in about {total} coins.", {
			jobs = if stats.jobs == 1 then "1 workplace" else stats.jobs .. " workplaces",
			employed = stats.employed,
			total = Text.commas(total),
		}),
		{ Parent = right, TextSize = 16, LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 44) }
	)
	local workers = {}
	for _, l in lines do
		workers[l.vid] = l.amount
	end
	local i = 3
	for _, w in City.workplaces(State.plan) do
		local who, amount = nil, nil
		for vid, v in p.villagers do
			if v.job == w.key then
				who = v.name
				amount = workers[vid]
			end
		end
		Kit.row({
			Parent = right,
			Size = UDim2.new(1, -12, 0, 60),
			Height = 60,
			LayoutOrder = i,
			Title = Text.fill("{job}, {place}", { job = w.job.name, place = w.def.name:lower() }),
			Sub = if who
				then Text.fill("{name}, about {n} coins a day", { name = who, n = amount or w.job.income })
				else "Nobody works here yet",
			Marker = "briefcase",
			MarkerColor = if who then T.Purple else T.Line,
		})
		i += 1
	end
	if stats.jobs == 0 then
		Kit.text(
			"No workplaces yet. Find them under Work in Build mode.",
			{ Parent = right, TextSize = 16, Color = T.InkSoft, LayoutOrder = 3 }
		)
	end
	local earned = State.data.stats and State.data.stats.earned or 0
	Kit.text(
		Text.fill("Earned from work so far: {n} coins.", { n = Text.commas(earned) }),
		{ Parent = right, TextSize = 15, Color = T.InkSoft, LayoutOrder = 999 }
	)
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
	table.insert(unbind, State.on("coins", draw))
	table.insert(unbind, State.on("villagers", draw))
end

return CityPanel
