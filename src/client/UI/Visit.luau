-- Other players' towns. The user: "allow players to like other plots. make a leaderboard for likes
-- with plots. allow players to visit plots searching by name, sort by likes or by recency, allowing
-- them to view a copy of the town they are visiting and like it, even if the player owning the
-- plot is offline."
--
-- The Visit menu (a full menu, Kit.panel): the picked town on the card at the left (its likes, its
-- place, its level and villagers, Visit and Like), and down the right a search box over the list,
-- the towns of this server first, then the leaderboard (Most liked, with places) or the Newest, a
-- page at a time. Everything comes from the server (PlotList, Services/Visit), which checks all of
-- it. While the player looks round someone's town, a bar at the bottom says whose it is, with Like
-- and Home (the `Visiting` event).

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Remotes = require(Shared.Net.Remotes)
local PlotBoard = require(Shared.Sim.PlotBoard)
local Social = require(Shared.Sim.Social) -- (friends playing here: the line about inviting them)
local Text = require(Shared.Util.Text)

local Kit = require(script.Parent.Kit)
local Icons = require(script.Parent.Icons)
local MenuParts = require(script.Parent.MenuParts)
local Toasts = require(script.Parent.Toasts)

local Visit = {}

local T = Kit.Theme
local DAY = 86400
local SEARCH_WAIT = 0.4 -- seconds after the last key before a search goes off

local panel: any = nil
local tab = "likes"
local query = ""
local page = 1
local towns: { any } = {} -- the list's towns, in order
local here: { any } = {} -- this server's other towns
local mine: any = nil
local more = false
local picked: number? = nil
local loading = false
local failed = false
local asked = 0 -- the latest list asked for; an older answer gives way to it
local typedAt = 0

local cardInside: Frame? = nil
local list: ScrollingFrame? = nil

local drawCard: () -> ()
local drawList: () -> ()

local function each(fn: (any) -> ())
	for _, t in towns do
		fn(t)
	end
	for _, t in here do
		fn(t)
	end
	if mine then
		fn(mine)
	end
end

local function find(id: number?): any
	local found = nil
	if id then
		each(function(t)
			if t.id == id and not found then
				found = t
			end
		end)
	end
	return found
end

local function named(t: any): boolean
	return type(t.name) == "string" and t.name ~= ""
end

-- The line under a town's name: whose it is (when it has a name of its own), its level, and that
-- its owner is in this server.
local function subOf(t: any): string
	local line = if t.mine
		then "Your town"
		elseif named(t) and t.who ~= "" then Text.fill("by {who}, level {n}", { who = t.who, n = t.level or 1 })
		else Text.fill("Level {n}", { n = t.level or 1 })
	if t.here and not t.mine then
		line ..= ", here now"
	end
	return line
end

-- When it last changed, in days.
local function changed(at: number): string
	if at <= 0 then
		return "Not yet"
	end
	local days = math.floor(math.max(0, os.time() - at) / DAY)
	if days == 0 then
		return "Today"
	elseif days == 1 then
		return "Yesterday"
	end
	return Text.fill("{n} days ago", { n = days })
end

-- The colour of a place on the leaderboard: the top three stand out (not in yellow, which is the
-- picked row's).
local function rankColour(rank: number): Color3
	if rank == 1 then
		return T.Orange
	elseif rank == 2 then
		return T.Blue
	elseif rank == 3 then
		return T.Coral
	end
	return T.Teal
end

-- Asking the server -----------------------------------------------------------------------------

local function fetch(fresh: boolean)
	asked += 1
	local ask = asked
	if fresh then
		page = 1
		towns = {}
	end
	loading, failed = true, false
	if fresh then
		drawList()
	end
	task.spawn(function()
		local ok, res = pcall(function()
			return Remotes.fn("PlotList"):InvokeServer(tab, query, page)
		end)
		if ask ~= asked or not panel then
			return
		end
		loading = false
		if ok and type(res) == "table" then
			if fresh then
				towns = {}
			end
			for _, t in if type(res.plots) == "table" then res.plots else {} do
				table.insert(towns, t)
			end
			here = if type(res.here) == "table" then res.here else {}
			mine = res.mine
			more = res.more == true
			if not find(picked) then
				picked = if towns[1] then towns[1].id elseif here[1] then here[1].id elseif mine then mine.id else nil
			end
		else
			failed = true
		end
		drawList()
		drawCard()
	end)
end

local function setLiked(id: number, liked: boolean, likes: number)
	each(function(t)
		if t.id == id then
			t.liked, t.likes = liked, likes
		end
	end)
end

local function like(id: number)
	task.spawn(function()
		local ok, res, why = pcall(function()
			return Remotes.fn("PlotLike"):InvokeServer(id)
		end)
		if ok and type(res) == "table" then
			setLiked(id, res.liked == true, tonumber(res.likes) or 0)
			Visit.likedElsewhere(id, res.liked == true, tonumber(res.likes) or 0)
			if panel then
				drawCard()
				drawList()
			end
		elseif ok and type(why) == "string" then
			Toasts.show(why, "warn")
		end
	end)
end

local function go(id: number)
	task.spawn(function()
		local ok, res, why = pcall(function()
			return Remotes.fn("PlotVisit"):InvokeServer(id)
		end)
		if ok and res then
			Visit.close()
		else
			Toasts.show(if ok and type(why) == "string" then why else "Couldn't go there.", "warn")
		end
	end)
end

-- The card on the left --------------------------------------------------------------------------

function drawCard()
	local inside = cardInside
	if not panel or not inside then
		return
	end
	for _, c in inside:GetChildren() do
		c:Destroy()
	end
	local t = find(picked) or mine
	if not t then
		MenuParts.empty(
			"map",
			"No town picked",
			"Pick one from the list.",
			{ Parent = inside, Size = UDim2.fromScale(1, 1) }
		)
		return
	end
	local title = Kit.title(PlotBoard.title(t), {
		Name = "TownName",
		Parent = inside,
		Size = UDim2.new(1, 0, 0, 44),
		TextSize = 34,
		Wrap = false,
	})
	title.TextTruncate = Enum.TextTruncate.AtEnd
	Kit.text(subOf(t), {
		Name = "Whose",
		Parent = inside,
		Size = UDim2.new(1, 0, 0, 20),
		Position = UDim2.fromOffset(0, 46),
		TextSize = 15,
		Color = T.InkSoft,
		Wrap = false,
	})
	-- its numbers, two by two
	local grid = Kit.box({
		Name = "Stats",
		Parent = inside,
		Size = UDim2.new(1, 0, 0, 76 * 2 + 10),
		Position = UDim2.fromOffset(0, 84),
	})
	Kit.grid(grid, UDim2.new(0.5, -5, 0, 76), 10)
	MenuParts.stat(
		"heart",
		"Likes",
		Text.commas(t.likes or 0),
		T.Pink,
		{ Name = "Likes", Parent = grid, LayoutOrder = 1 }
	)
	if t.rank then
		MenuParts.stat("trophy", "Place", Text.fill("#{n}", { n = t.rank }), T.Yellow, {
			Name = "Place",
			Parent = grid,
			LayoutOrder = 2,
		})
	else
		MenuParts.stat(
			"clock",
			"Changed",
			changed(t.at or 0),
			T.Yellow,
			{ Name = "Changed", Parent = grid, LayoutOrder = 2 }
		)
	end
	MenuParts.stat(
		"city",
		"Level",
		tostring(t.level or 1),
		T.Purple,
		{ Name = "Level", Parent = grid, LayoutOrder = 3 }
	)
	MenuParts.stat("people", "Villagers", tostring(t.people or 0), T.Green, {
		Name = "People",
		Parent = grid,
		LayoutOrder = 4,
	})
	-- when it last changed, under them, when its place took the tile
	if t.rank and (t.at or 0) > 0 then
		MenuParts.note(Text.fill("Changed {when}", { when = changed(t.at):lower() }), T.Teal, {
			Name = "Changed",
			Parent = inside,
			Position = UDim2.fromOffset(0, 84 + 76 * 2 + 22),
		})
	end
	-- what to do with it, at the foot of the card
	local foot = Kit.box({
		Name = "Actions",
		Parent = inside,
		Size = UDim2.new(1, 0, 0, 48),
		Position = UDim2.new(0, 0, 1, -48),
	})
	if t.mine then
		Kit.button(if named(t) then "Rename" else "Name it", {
			Name = "NameIt",
			Parent = foot,
			Size = UDim2.new(0.5, -6, 1, 0),
			Color = T.Purple,
			TextSize = 18,
			Icon = "hall",
		}, function()
			Visit.close()
			require(script.Parent.CityPanel).open({ rename = true })
		end)
		return
	end
	Kit.button("Visit", {
		Name = "Go",
		Parent = foot,
		Size = UDim2.new(0.5, -6, 1, 0),
		Color = T.Green,
		TextSize = 18,
		Icon = "map",
	}, function()
		go(t.id)
	end)
	Kit.button(if t.liked then "Liked" else "Like", {
		Name = "Like",
		Parent = foot,
		Size = UDim2.new(0.5, -6, 1, 0),
		Position = UDim2.fromScale(0.5, 0) + UDim2.fromOffset(6, 0),
		Color = if t.liked then T.Pink else T.PaperDark,
		TextColor = if t.liked then T.White else T.Ink,
		TextSize = 18,
		Icon = "heart",
	}, function()
		like(t.id)
	end)
end

-- The list on the right -------------------------------------------------------------------------

local function townRow(parent: ScrollingFrame, t: any, order: number)
	local row, inner = Kit.row({
		Name = "Town",
		Parent = parent,
		Size = MenuParts.rowSize(64),
		Height = 64,
		LayoutOrder = order,
		Title = PlotBoard.title(t),
		Sub = subOf(t),
		Marker = if t.rank then "rank" else "house",
		MarkerColor = if t.rank then rankColour(t.rank) elseif t.mine then T.Purple else T.Teal,
		RightSpace = 214,
		Selected = picked == t.id,
	}, function()
		picked = t.id
		drawCard()
		for _, r in parent:GetChildren() do
			if r:IsA("GuiObject") and r.Name == "Town" then
				Kit.setRowSelected(r, r:GetAttribute("Town") == t.id)
			end
		end
	end)
	row:SetAttribute("Town", t.id)
	-- its place, on the marker at its left end
	local marker = row:FindFirstChild("Marker")
	if t.rank and marker then
		local n = Kit.title(tostring(t.rank), {
			Name = "Place",
			Parent = marker,
			Size = UDim2.new(1, -6, 1, 0),
			TextSize = if t.rank < 100 then 20 else 16,
			Color = T.Dark,
			AlignX = Enum.TextXAlignment.Center,
			Wrap = false,
			ZIndex = 4,
		})
		n:SetAttribute("KeepColors", true)
	end
	local lean: number = row:GetAttribute("Lean") or 0
	-- how many like it, and the way there
	local likes = Kit.box({
		Name = "Likes",
		Parent = inner,
		Size = UDim2.fromOffset(84, 24),
		Position = UDim2.new(1, -(lean + 124), 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
	})
	likes.ZIndex = 2
	Kit.list(likes, 5, true, Enum.HorizontalAlignment.Right).VerticalAlignment = Enum.VerticalAlignment.Center
	Icons.make("heart", 16, {
		Name = "Heart",
		Parent = likes,
		Color = if t.liked then T.Pink else T.InkSoft,
		LayoutOrder = 1,
		ZIndex = 2,
	})
	-- (named as a row's own words at its right end, so a picked row's turn dark: Kit.setRowSelected)
	Kit.text(Text.commas(t.likes or 0), {
		Name = "Right",
		Parent = likes,
		Size = UDim2.fromOffset(0, 24),
		AutomaticSize = Enum.AutomaticSize.X,
		TextSize = 16,
		Font = Kit.Fonts.Bold,
		Color = T.Ink,
		Wrap = false,
		LayoutOrder = 2,
		ZIndex = 2,
	})
	if not t.mine then
		-- dark on every row, so the list reads as towns and not as a column of green buttons (the
		-- card's own Visit is the green one)
		Kit.button("Visit", {
			Name = "Go",
			Parent = inner,
			Size = UDim2.fromOffset(104, 38),
			Position = UDim2.new(1, -(lean + 8), 0.5, 0),
			AnchorPoint = Vector2.new(1, 0.5),
			Color = T.PaperDark,
			TextColor = T.Ink,
			TextSize = 16,
			ZIndex = 3,
		}, function()
			go(t.id)
		end)
	end
	if picked == t.id then
		Kit.setRowSelected(row, true)
	end
end

function drawList()
	local scroll = list
	if not panel or not scroll then
		return
	end
	for _, c in scroll:GetChildren() do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
	local order = 1
	local accent = T.Teal
	-- friends to play with: a tenth more wages each while they're here (UI/Invite, Sim/Social)
	if query == "" then
		local _, inner = Kit.row({
			Name = "Friends",
			Parent = scroll,
			Size = MenuParts.rowSize(56),
			Height = 56,
			LayoutOrder = order,
			Title = "Play with friends",
			Sub = Text.fill("Each one here adds {n}% to wages", { n = Social.percent(1) }),
			Marker = "people",
			MarkerColor = accent,
			RightSpace = 150,
		})
		require(script.Parent.Invite).button("Invite", {
			Parent = inner,
			Size = UDim2.fromOffset(120, 38),
			Position = UDim2.new(1, -8, 0.5, 0),
			AnchorPoint = Vector2.new(1, 0.5),
			TextSize = 16,
			ZIndex = 3,
		})
		order += 1
	end
	if #here > 0 and query == "" then
		MenuParts.heading(scroll, "In this server", accent, order, tostring(#here))
		order += 1
		for _, t in here do
			townRow(scroll, t, order)
			order += 1
		end
	end
	local heading = if query ~= "" then "Found" elseif tab == "new" then "Newest" else "Most liked"
	MenuParts.heading(scroll, heading, accent, order, nil)
	order += 1
	if loading and #towns == 0 then
		MenuParts.note("Looking...", accent, { Name = "Looking", Parent = scroll, LayoutOrder = order })
		return
	end
	if failed and #towns == 0 then
		MenuParts.note(
			"Couldn't get the towns. Try again soon.",
			T.Red,
			{ Name = "Failed", Parent = scroll, LayoutOrder = order }
		)
		return
	end
	if #towns == 0 then
		if query ~= "" then
			MenuParts.empty("map", "No town by that name", "Try the start of a word.", {
				Name = "Empty",
				Parent = scroll,
				LayoutOrder = order,
			})
		else
			MenuParts.empty("map", "No towns yet", "Towns show up here once they're saved.", {
				Name = "Empty",
				Parent = scroll,
				LayoutOrder = order,
			})
		end
		return
	end
	for _, t in towns do
		townRow(scroll, t, order)
		order += 1
	end
	if more then
		local holder = Kit.box({ Name = "More", Parent = scroll, Size = MenuParts.rowSize(48), LayoutOrder = order })
		Kit.button(if loading then "Looking..." else "Show more", {
			Name = "ShowMore",
			Parent = holder,
			Size = UDim2.fromOffset(200, 42),
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Color = T.Teal,
			TextSize = 17,
		}, function()
			if loading then
				return
			end
			page += 1
			fetch(false)
			drawList()
		end)
	end
end

-- The menu --------------------------------------------------------------------------------------

function Visit.isOpen(): boolean
	return panel ~= nil
end

function Visit.close()
	if panel then
		Kit.closePanel(panel)
		panel = nil
	end
	cardInside, list = nil, nil
	asked += 1
end

local function build()
	local body = panel.body
	local _, inside = MenuParts.card(body, T.Teal)
	cardInside = inside
	local split, gap = MenuParts.Split, MenuParts.Gap
	local box = MenuParts.input("Search towns or owners", {
		Name = "Search",
		Parent = body,
		Size = UDim2.new(1 - split, -gap / 2 - 12, 0, 44),
		Position = UDim2.new(split, gap / 2, 0, 0),
		Text = query,
		Icon = "zoom",
	})
	box:GetPropertyChangedSignal("Text"):Connect(function()
		local typed = Text.clean(box.Text):sub(1, 40)
		if typed == query then
			return
		end
		query = typed
		typedAt = os.clock()
		local mark = typedAt
		task.delay(SEARCH_WAIT, function()
			if panel and mark == typedAt then
				fetch(true)
			end
		end)
	end)
	list = MenuParts.list(body, {
		Size = UDim2.new(1 - split, -gap / 2, 1, -56),
		Position = UDim2.new(split, gap / 2, 0, 56),
	})
	drawCard()
	drawList()
end

-- arg: { sort = "new" } to open on Newest, { search = "..." } with something typed.
function Visit.open(arg: any?)
	Visit.close()
	if type(arg) == "table" then
		if arg.sort then
			tab = PlotBoard.sortOf(arg.sort)
		end
		if type(arg.search) == "string" then
			query = Text.clean(arg.search):sub(1, 40)
		end
	end
	panel = Kit.panel("Visit", Kit.MenuSize, Visit.close, "map", T.Teal, {
		Caption = "Other towns",
		Tabs = {
			{ id = "likes", name = "Most liked" },
			{ id = "new", name = "Newest" },
		},
		OnTab = function(id: string)
			tab = PlotBoard.sortOf(id)
			fetch(true)
		end,
	})
	if panel.selectTab then
		panel.selectTab(tab)
	end
	build()
	fetch(true)
end

-- a change of look builds it again in the new one
Kit.onTheme(function()
	if panel then
		for _, c in panel.body:GetChildren() do
			c:Destroy()
		end
		build()
	end
end)

-- The bar while visiting ------------------------------------------------------------------------

local current: any = nil -- what the server last said of the town being looked round
local bar: Frame? = nil

-- How far up from the bottom the bar sits: over an event's prompt while one is up (UI/EventCard
-- puts it in the same place: the player's own town goes on while they look round another).
local function barLift(): number
	local prompt = Kit.root():FindFirstChild("EventCard")
	return if prompt and prompt:IsA("GuiObject") and prompt.Visible then -88 else -16
end

local function drawBar()
	if bar then
		bar:Destroy()
		bar = nil
	end
	local now = current
	if not now or not now.on then
		return
	end
	local root = Kit.root()
	local parent = root:FindFirstChild("Hud") or root
	local W, H = 520, 64
	local f = Kit.darkPill({
		Name = "VisitBar",
		Parent = parent,
		Size = UDim2.fromOffset(W, H),
		Position = UDim2.new(0.5, 0, 1, barLift()),
		AnchorPoint = Vector2.new(0.5, 1),
	})
	bar = f
	-- (what sits on a slab goes in a frame of its own)
	local holder =
		Kit.box({ Name = "Holder", Parent = f, Size = UDim2.new(1, -36, 1, 0), Position = UDim2.fromOffset(18, 0) })
	holder.ZIndex = 2
	Icons.make("map", 26, {
		Name = "Pin",
		Parent = holder,
		Position = UDim2.new(0, 2, 0.5, -13),
		Color = T.White,
		Hole = T.Glass,
		ZIndex = 3,
	})
	local title = Kit.title(PlotBoard.title(now), {
		Name = "Town",
		Parent = holder,
		Size = UDim2.new(1, -278, 0, 26),
		Position = UDim2.fromOffset(38, 7),
		TextSize = 21,
		Color = T.White,
		Wrap = false,
		ZIndex = 3,
	})
	title.TextTruncate = Enum.TextTruncate.AtEnd
	local likes = tonumber(now.likes) or 0
	local words = if likes == 1 then "1 like" else Text.fill("{n} likes", { n = Text.commas(likes) })
	if named(now) and now.who ~= "" then
		words = Text.fill("{who}'s town, {likes}", { who = now.who, likes = words })
	end
	local sub = Kit.text(words, {
		Name = "Whose",
		Parent = holder,
		Size = UDim2.new(1, -278, 0, 18),
		Position = UDim2.fromOffset(38, 35),
		TextSize = 14,
		Color = T.White,
		Wrap = false,
		ZIndex = 3,
	})
	sub.TextTransparency = 0.25
	Kit.button(if now.liked then "Liked" else "Like", {
		Name = "Like",
		Parent = holder,
		Size = UDim2.fromOffset(112, 42),
		Position = UDim2.new(1, -124, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
		Color = if now.liked then T.Pink else T.Paper,
		TextColor = if now.liked then T.White else T.Ink,
		TextSize = 16,
		Icon = "heart",
		ZIndex = 3,
	}, function()
		like(now.id)
	end)
	Kit.button("Home", {
		Name = "Home",
		Parent = holder,
		Size = UDim2.fromOffset(112, 42),
		Position = UDim2.new(1, 0, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
		Color = T.Red,
		TextColor = T.White,
		TextSize = 16,
		Icon = "house",
		ZIndex = 3,
	}, function()
		task.spawn(function()
			pcall(function()
				Remotes.fn("PlotLeave"):InvokeServer()
			end)
		end)
	end)
	-- it goes with the rest of the main screen when Hide is pressed
	f.Visible = root:GetAttribute("HudHidden") ~= true
	Kit.slideIn(f, 0, 90)
end

-- A like made in the menu shows on the bar too, and the other way round.
function Visit.likedElsewhere(id: number, liked: boolean, likes: number)
	if current and current.on and current.id == id then
		current.liked, current.likes = liked, likes
		drawBar()
	end
end

-- Whose town the player is looking round, if anyone's (the server says: `Visiting`).
function Visit.visiting(): number?
	return if current and current.on then current.id else nil
end

function Visit.start()
	Remotes.event("Visiting").OnClientEvent:Connect(function(info)
		current = if type(info) == "table" and info.on then info else nil
		drawBar()
	end)
	local root = Kit.root()
	root:GetAttributeChangedSignal("HudHidden"):Connect(function()
		if bar then
			bar.Visible = root:GetAttribute("HudHidden") ~= true
		end
	end)
	Kit.onTheme(function()
		if bar then
			drawBar()
		end
	end)
	-- up out of the way of an event's prompt, and back down after it
	task.spawn(function()
		while true do
			task.wait(0.5)
			local f = bar
			if f and f.Parent then
				local y = barLift()
				if f.Position.Y.Offset ~= y then
					f.Position = UDim2.new(0.5, 0, 1, y)
					f:SetAttribute("Home", f.Position)
				end
			end
		end
	end)
end

return Visit
