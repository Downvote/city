-- The town news: what's been happening, and what villagers are waiting for. A full menu
-- (Kit.panel) laid out like the town's own paper: the front page on the card at the left (the
-- masthead, the date, the latest story as the headline, today's count) and every story down the
-- right, grouped by day, with what's waiting on you at the top.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Catalog = require(Shared.Build.Catalog)
local Schema = require(Shared.Sim.Schema)
local Tuning = require(Shared.Config.Tuning)
local Text = require(Shared.Util.Text)
local NewsKinds = require(Shared.Data.NewsKinds)

local Kit = require(script.Parent.Kit)
local MenuParts = require(script.Parent.MenuParts)
local State = require(script.Parent.Parent.Controllers.State)

local News = {}

local T = Kit.Theme
local panel: any = nil
local unbind: { () -> () } = {}

local WEATHER = {
	clear = "clear skies",
	cloudy = "cloudy",
	rain = "rain",
	storm = "storms",
	snow = "snow",
	blossom = "falling blossom",
	leaves = "falling leaves",
}

local function ago(t: number): string
	local s = math.max(0, os.time() - t)
	if s < 60 then
		return "just now"
	elseif s < 3600 then
		return Text.fill("{n} min ago", { n = math.floor(s / 60) })
	elseif s < 86400 then
		return Text.fill("{n} h ago", { n = math.floor(s / 3600) })
	end
	local days = math.floor(s / 86400)
	return if days == 1 then "a day ago" else Text.fill("{n} days ago", { n = days })
end

-- Which day a moment fell on, as days before today (0 today, 1 yesterday), by the calendar.
local function daysBack(t: number): number
	local ok, a, b = pcall(function()
		return os.date("*t", t), os.date("*t", os.time())
	end)
	if ok and type(a) == "table" and type(b) == "table" then
		local da = os.time({ year = a.year, month = a.month, day = a.day, hour = 12 })
		local db = os.time({ year = b.year, month = b.month, day = b.day, hour = 12 })
		return math.max(0, math.floor((db - da) / 86400 + 0.5))
	end
	return math.max(0, math.floor((os.time() - t) / 86400))
end

-- When a story happened, for its row: how long ago today, the time of day yesterday.
local function when(t: number, back: number): string
	if back == 1 then
		local ok, d = pcall(function()
			return os.date("*t", t)
		end)
		if ok and type(d) == "table" then
			return Text.fill("yesterday, {t}", { t = Text.clock(d.hour + d.min / 60) })
		end
	end
	return ago(t)
end

-- The front page, on the card at the left.
local function frontPage(inside: Frame, log: { any }, today: number, waiting: number)
	local accent = T.Teal
	local function rule(y: number, thick: number)
		Kit.new("Frame", {
			Name = "Rule",
			BackgroundColor3 = if thick > 1 then T.InkSoft else T.Line,
			BackgroundTransparency = 0,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, thick),
			Position = UDim2.fromOffset(0, y),
			Parent = inside,
		})
	end
	rule(0, 3)
	Kit.title(Text.fill("The {town} Post", { town = Tuning.Game.Name }), {
		Name = "Masthead",
		Parent = inside,
		Size = UDim2.new(1, 0, 0, 44),
		Position = UDim2.fromOffset(0, 8),
		TextSize = 34,
		AlignX = Enum.TextXAlignment.Center,
		Wrap = false,
	})
	rule(56, 1)
	local season = workspace:GetAttribute("Season")
	local day = workspace:GetAttribute("Day")
	local weather = workspace:GetAttribute("Weather")
	Kit.text(
		Text.fill("{season} {day}", {
			season = Schema.Seasons[if type(season) == "number" then season else 1] or "Spring",
			day = if type(day) == "number" then day else 1,
		}),
		{
			Name = "Date",
			Parent = inside,
			Size = UDim2.new(0.5, 0, 0, 24),
			Position = UDim2.fromOffset(0, 60),
			TextSize = 15,
			Font = Kit.Fonts.Bold,
		}
	)
	Kit.text(WEATHER[weather :: any] or "clear skies", {
		Name = "Weather",
		Parent = inside,
		Size = UDim2.new(0.5, 0, 0, 24),
		Position = UDim2.fromScale(0.5, 0) + UDim2.fromOffset(0, 60),
		TextSize = 15,
		Color = T.InkSoft,
		AlignX = Enum.TextXAlignment.Right,
	})
	rule(88, 1)

	-- the latest story as the headline, the next two under it
	local latest = log[1]
	local story = Kit.box({
		Name = "Story",
		Parent = inside,
		Size = UDim2.new(1, 0, 1, -(104 + 82 + 16)),
		Position = UDim2.fromOffset(0, 104),
	})
	Kit.list(story, 6)
	Kit.text(if latest then "Latest" else "Front page", {
		Name = "Kicker",
		Parent = story,
		Size = UDim2.new(1, 0, 0, 20),
		TextSize = 15,
		Font = Kit.Fonts.Bold,
		Tint = accent,
		LayoutOrder = 1,
	})
	Kit.title(if latest then latest.text else "Nothing to report yet.", {
		Name = "Headline",
		Parent = story,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		TextSize = 28,
		AlignY = Enum.TextYAlignment.Top,
		LayoutOrder = 2,
	})
	Kit.text(if latest then ago(latest.t) else "Check back in a while.", {
		Name = "Byline",
		Parent = story,
		Size = UDim2.new(1, 0, 0, 20),
		TextSize = 15,
		Color = T.InkSoft,
		LayoutOrder = 3,
	})
	if log[2] then
		Kit.new("Frame", {
			Name = "Rule",
			BackgroundColor3 = T.Line,
			BackgroundTransparency = 0,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 1),
			LayoutOrder = 4,
			Parent = story,
		})
		Kit.text("Also in the paper", {
			Name = "Also",
			Parent = story,
			Size = UDim2.new(1, 0, 0, 20),
			TextSize = 15,
			Font = Kit.Fonts.Bold,
			Tint = accent,
			LayoutOrder = 5,
		})
		for i = 2, math.min(3, #log) do
			Kit.text(log[i].text, {
				Name = "More",
				Parent = story,
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				TextSize = 16,
				Font = Kit.Fonts.Bold,
				LayoutOrder = 4 + i,
			})
		end
	end

	-- today's count and what's waiting, as tiles along the bottom
	local tiles = Kit.box({
		Name = "Stats",
		Parent = inside,
		Size = UDim2.new(1, 0, 0, 82),
		Position = UDim2.new(0, 0, 1, -82),
	})
	Kit.grid(tiles, UDim2.new(0.5, -6, 0, 82), 12)
	MenuParts.stat("news", "Today", tostring(today), accent, {
		Name = "Today",
		Parent = tiles,
		LayoutOrder = 1,
		Sub = if today == 1 then "story" else "stories",
	})
	MenuParts.stat("alert", "Waiting on you", tostring(waiting), if waiting > 0 then T.Coral else T.Line, {
		Name = "Waiting",
		Parent = tiles,
		LayoutOrder = 2,
		Sub = if waiting == 1 then "request" else "requests",
	})
end

-- One story: the news marker, the words (two lines if they need them) and when, at the right.
local function story(list: ScrollingFrame, text: string, at: string, order: number, marker: string, color: Color3)
	local _, inner = Kit.row({
		Name = "Story",
		Parent = list,
		Size = MenuParts.rowSize(),
		LayoutOrder = order,
		Marker = marker,
		MarkerColor = color,
	})
	local lean = 17
	Kit.text(text, {
		Name = "Title",
		Parent = inner,
		Size = UDim2.new(1, -(lean + 58 + 132), 1, -8),
		Position = UDim2.fromOffset(lean + 58, 4),
		TextSize = 16,
		Font = Kit.Fonts.Bold,
		ZIndex = 2,
	})
	Kit.text(at, {
		Name = "When",
		Parent = inner,
		Size = UDim2.new(0, 116, 1, 0),
		Position = UDim2.new(1, -(116 + lean + 16), 0, 0),
		TextSize = 14,
		Color = T.InkSoft,
		AlignX = Enum.TextXAlignment.Right,
		ZIndex = 2,
	})
end

local function draw()
	if not panel then
		return
	end
	for _, c in panel.body:GetChildren() do
		c:Destroy()
	end
	local requests = State.data.requests or {}
	local log = State.data.log or {}
	local groups = { {}, {}, {} } :: { { any } }
	for _, entry in log do
		local back = daysBack(entry.t)
		table.insert(groups[math.min(3, back + 1)], { entry = entry, back = back })
	end
	local waiting = 0
	for _, r in requests do
		if State.villager(r.vid) then
			waiting += 1
		end
	end

	local _, inside = MenuParts.card(panel.body, T.Teal)
	frontPage(inside, log, #groups[1], waiting)

	local list = MenuParts.list(panel.body)
	local order = 0
	if waiting > 0 then
		order += 1
		MenuParts.heading(list, "Waiting on you", T.Coral, order, tostring(waiting))
		for _, r in requests do
			local v = State.villager(r.vid)
			if v then
				order += 1
				Kit.row({
					Name = "Request",
					Parent = list,
					Size = MenuParts.rowSize(),
					LayoutOrder = order,
					Title = Text.fill(
						"{name} wants {thing} by their bed",
						{ name = v.name, thing = Catalog.Tags[r.tag] or r.tag }
					),
					Sub = "Put one by their bed in Build mode.",
					Marker = "alert",
					MarkerColor = T.Coral,
				})
			end
		end
	end
	for k, group in groups do
		if #group > 0 then
			order += 1
			MenuParts.heading(
				list,
				if k == 1 then "Today" elseif k == 2 then "Yesterday" else "Earlier",
				T.Teal,
				order,
				tostring(#group)
			)
			for _, s in group do
				order += 1
				-- each kind of story by its own icon (Data/NewsKinds)
				story(list, s.entry.text, when(s.entry.t, s.back), order, NewsKinds.icon(s.entry.kind), T.Teal)
			end
		end
	end
	if #log == 0 then
		order += 1
		MenuParts.empty("news", "No news yet", "Things that happen in town show up here.", {
			Parent = list,
			LayoutOrder = order,
			Color = T.Teal,
			Height = 440,
		})
	end
end

function News.isOpen(): boolean
	return panel ~= nil
end

function News.close()
	for _, u in unbind do
		u()
	end
	unbind = {}
	if panel then
		Kit.closePanel(panel)
		panel = nil
	end
end

function News.open()
	News.close()
	panel = Kit.panel("Town news", Kit.MenuSize, News.close, "news", Kit.Theme.Teal, { Caption = "Today in town" })
	draw()
	table.insert(unbind, State.on("log", draw))
	table.insert(unbind, State.on("requests", draw))
end

-- a change of look builds what's open again in the new one (a row's shading is made for a look)
Kit.onTheme(function()
	if panel then
		draw()
	end
end)

return News
