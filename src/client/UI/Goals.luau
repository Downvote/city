-- The town's goals: what to work toward as the town grows, how far along each one is, and a
-- button to claim the coins for each one that's done. A full menu (Kit.panel): the goals as a
-- list of rows down the right, the picked one in full on the left. Some pay more than coins (the
-- user: "add more rewards to quests, like titles, special buildings, special gifts, etc."): a title,
-- a piece to build for free, a thing for the bag, said under the pay. The Titles tab lists every
-- title, the ones won to wear (the TitleWear remote; Services/Titles hangs it under the player's
-- name) with how it looks on the card at the left. Scenes: panel:Goals, panel:Goals:titles.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Remotes = require(Shared.Net.Remotes)
local Life = require(Shared.Sim.Life)
local Text = require(Shared.Util.Text)
local CrateData = require(Shared.Data.Crates) -- (a goal's crate)
local Items = require(Shared.Data.Items)
local Catalog = require(Shared.Build.Catalog)
local GoalData = require(Shared.Data.Goals)
local TitleData = require(Shared.Data.Titles)
local Titles = require(Shared.Sim.Titles)
local TitleTag = require(Shared.Util.TitleTag)

local Kit = require(script.Parent.Kit)
local MenuParts = require(script.Parent.MenuParts)
local Toasts = require(script.Parent.Toasts)
local State = require(script.Parent.Parent.Controllers.State)

local Goals = {}

local T = Kit.Theme
local panel: any = nil
local list: ScrollingFrame? = nil
local detail: Frame? = nil
local tab = "goals"

-- A profile-like table from the client state, for Sim/Life.
function Goals.view(): any
	local d = State.data
	return {
		villagers = d.villagers or {},
		rel = d.rel or {},
		stats = d.stats or {},
		goals = d.goals or {},
		plan = State.plan,
		coins = d.coins or 0,
	}
end

-- How many finished goals are waiting to be claimed.
function Goals.ready(): number
	local n = 0
	for _, g in Life.goals(Goals.view()) do
		if g.done and not g.claimed then
			n += 1
		end
	end
	return n
end

-- which goal the left side is showing
local picked: string? = nil

-- The left side: the picked goal, with how far along it is as a big ring, what it pays, and the
-- button to claim it.
local function showDetail(g: any)
	local frame = detail
	if not frame then
		return
	end
	for _, c in frame:GetChildren() do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
	local ready = g.done and not g.claimed
	local ratio = math.clamp(g.value / g.goal.need, 0, 1)
	-- the ring at the left of the band at the card's top, a faint line round it the way a dial is
	-- drawn, what it pays beside it in big numbers, and its name flush left under them
	local HERO = MenuParts.Hero
	local outline = Kit.new("Frame", {
		Name = "Outline",
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(HERO, HERO),
		Parent = frame,
	})
	Kit.corner(outline, "round")
	Kit.rim(outline, T.Line, 1, 0.3)
	local _, middle = Kit.ring({
		Name = "Ring",
		Parent = frame,
		Size = HERO - 16,
		Position = UDim2.fromOffset(8, 8),
		Thickness = 14,
		Track = T.PaperDark,
		Hole = T.Paper,
	}, ratio, if g.done then T.Green else T.Yellow)
	if g.claimed then
		-- a claimed goal is ticked off in the middle of its ring
		Kit.disc({
			Name = "Tick",
			Parent = middle,
			Size = 60,
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Color = T.Green,
			Icon = "check",
			ZIndex = 4,
		})
	else
		local shown = math.min(g.value, g.goal.need)
		Kit.title(
			if g.goal.need >= 100
				then Text.fill("{n}%", { n = math.floor(shown / g.goal.need * 100) })
				else Text.fill("{n}/{need}", { n = shown, need = g.goal.need }),
			{
				Parent = middle,
				Size = UDim2.fromScale(1, 1),
				TextSize = 30,
				AlignX = Enum.TextXAlignment.Center,
			}
		)
	end
	-- what else it pays, in a line under the coins
	local also = {}
	local t = TitleData.get(g.goal.title)
	if t then
		table.insert(also, Text.fill("the title {t}", { t = t.name }))
	end
	local def = if g.goal.piece then Catalog.get(g.goal.piece) else nil
	if def then
		table.insert(also, Text.fill("a {x} to build", { x = def.name:lower() }))
	end
	local item = Items.get(g.goal.thing)
	if item then
		table.insert(also, item.phrase)
	end
	local crate = if g.goal.crate then CrateData.get(g.goal.crate) else nil
	if crate then
		table.insert(also, crate.phrase)
	end
	MenuParts.payout(frame, if g.claimed then "Paid" else "Pays", {
		coins = g.goal.reward,
		line = if #also > 0
			then { text = Text.fill("Also {x}", { x = table.concat(also, ", ") }), tint = T.Orange }
			else nil,
	})
	MenuParts.headline(frame, g.goal.name, g.goal.desc)
	-- at the foot: the button to claim it, when it's done (nothing in its place otherwise: the ring
	-- and the row say how far along it is)
	if ready then
		MenuParts.footButton(frame, Text.fill("Claim {n}", { n = Text.commas(g.goal.reward) }), {
			Name = "Claim",
			Color = T.Green,
			Icon = "coin",
		}, function()
			task.spawn(function()
				Remotes.fn("GoalClaim"):InvokeServer(g.goal.id)
			end)
		end)
	end
end

-- Claim all, at the right end of the menu's top: every finished goal at once (the user: "make a
-- claim all button in rewards and in goals"), claimed and paid on the server (Services/Claims),
-- which sends the one notice of what came in.
local function claimAll()
	task.spawn(function()
		local called, ok, why = pcall(function()
			return Remotes.fn("GoalClaimAll"):InvokeServer()
		end)
		if not called then
			Toasts.show("That didn't go through. Try again in a moment.", "warn")
		elseif not ok and type(why) == "string" then
			Toasts.show(why, "info")
		end
	end)
end

-- The right side: every goal as a row, in three groups: ready to claim (green), under way
-- (yellow) and done (sitting back). Picking a row shows it on the left.
local function fill()
	local frame = list
	if not frame then
		return
	end
	MenuParts.claimAll(panel, Goals.ready(), claimAll)
	for _, c in frame:GetChildren() do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
	local goals = Life.goals(Goals.view())
	local groups = { {}, {}, {} } :: { { any } }
	for _, g in goals do
		table.insert(groups[if g.claimed then 3 elseif g.done then 1 else 2], g)
	end
	-- keep showing the one that was picked; otherwise the first to claim, or the first not done
	local show: any = nil
	for _, g in goals do
		if g.goal.id == picked then
			show = g
		end
	end
	show = show or groups[1][1] or groups[2][1] or goals[1]
	local rows: { [string]: GuiObject } = {}
	local order = 0
	for k, group in groups do
		if #group > 0 then
			order += 1
			MenuParts.heading(
				frame,
				if k == 1 then "Ready to claim" elseif k == 2 then "Under way" else "Done",
				T.Yellow,
				order,
				tostring(#group)
			)
		end
		for _, g in group do
			order += 1
			local ready = k == 1
			local row = Kit.row({
				Name = g.goal.id,
				Parent = frame,
				Size = MenuParts.rowSize(),
				LayoutOrder = order,
				Title = g.goal.name,
				Marker = if g.done then "check" else "trophy",
				MarkerColor = if g.claimed then T.Line elseif ready then T.Green else T.Yellow,
				Right = if g.claimed
					then "Claimed"
					elseif ready then "Claim"
					else Text.fill("{a} of {b}", { a = Text.commas(g.value), b = Text.commas(g.goal.need) }),
				RightColor = if ready then T.Green else nil,
				Sunk = g.claimed,
			}, function()
				picked = g.goal.id
				for id, r in rows do
					Kit.setRowSelected(r, id == picked)
				end
				showDetail(g)
			end)
			rows[g.goal.id] = row
		end
	end
	if show then
		picked = show.goal.id
		Kit.setRowSelected(rows[show.goal.id], true)
		showDetail(show)
	end
end

-- Titles ------------------------------------------------------------------------------------------

-- The goal a title comes from.
local function goalFor(id: string): any
	for _, g in GoalData.list do
		if g.title == id then
			return g
		end
	end
	return nil
end

local function wear(id: string | false)
	task.spawn(function()
		pcall(function()
			Remotes.fn("TitleWear"):InvokeServer(id)
		end)
	end)
end

-- The card on the left: how the worn title (or the one under the pointer) looks over your head.
local function showTitle(name: string?)
	local frame = detail
	if not frame then
		return
	end
	for _, c in frame:GetChildren() do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
	Kit.caption("Over your head", {
		Name = "Caption",
		Parent = frame,
		Size = UDim2.new(1, 0, 0, 16),
		TextSize = 12,
	})
	local stage = Kit.frame({
		Name = "Preview",
		Parent = frame,
		Size = UDim2.new(1, 0, 0, 120),
		Position = UDim2.fromOffset(0, 28),
		-- (the dark glass in both looks: the tag is white words, as over the town)
		Color = T.Glass,
		Radius = 14,
	})
	local players = game:GetService("Players")
	local me = players.LocalPlayer
	local shown = name or "No title"
	local tag = TitleTag.build(if me and me.DisplayName then me.DisplayName else "You", shown)
	tag.AnchorPoint = Vector2.new(0.5, 0.5)
	tag.Position = UDim2.fromScale(0.5, 0.5)
	tag.ZIndex = 3
	tag.Parent = stage
	MenuParts.headline(
		frame,
		name or "No title",
		if name then "Everyone sees it under your name." else "Win titles from goals and wear one here.",
		164
	)
	if name then
		MenuParts.footButton(frame, "Take it off", {
			Name = "TakeOff",
			Color = T.Coral,
			TextSize = 20,
		}, function()
			wear(false)
		end)
	end
end

-- The list down the right: every title, the ones won first, the rest with the goal that gives them.
local function fillTitles()
	local frame = list
	if not frame then
		return
	end
	for _, c in frame:GetChildren() do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
	local p = { titles = State.data.titles or {}, title = State.data.title or nil }
	local entries = Titles.list(p)
	local won, locked = {}, {}
	for _, e in entries do
		table.insert(if e.owned then won else locked, e)
	end
	local worn = Titles.worn(p)
	local order = 1
	MenuParts.heading(frame, "Won", T.Yellow, order, tostring(#won))
	if #won == 0 then
		order += 1
		MenuParts.note("Goals with a title give it when you claim them.", T.Yellow, {
			Parent = frame,
			Size = MenuParts.rowSize(24),
			LayoutOrder = order,
		})
	end
	for _, e in won do
		order += 1
		local row = Kit.row({
			Name = e.title.id,
			Parent = frame,
			Size = MenuParts.rowSize(),
			LayoutOrder = order,
			Title = e.title.name,
			Marker = if e.worn then "check" else "medal",
			MarkerColor = if e.worn then T.Green else T.Yellow,
			Right = if e.worn then "Worn" else "Wear",
			RightColor = if e.worn then T.Green else nil,
		}, function()
			if not e.worn then
				wear(e.title.id)
			end
		end)
		Kit.setRowSelected(row, e.worn)
	end
	if #locked > 0 then
		order += 1
		MenuParts.heading(frame, "Still to win", T.Yellow, order, tostring(#locked))
	end
	for _, e in locked do
		order += 1
		local g = goalFor(e.title.id)
		Kit.row({
			Name = e.title.id,
			Parent = frame,
			Size = MenuParts.rowSize(),
			LayoutOrder = order,
			Title = e.title.name,
			Sub = if g then Text.fill("Goal: {x}", { x = g.name }) else nil,
			Marker = "lock",
			MarkerColor = T.Line,
			Sunk = true,
		})
	end
	showTitle(if worn then worn.name else nil)
end

local function refresh()
	if not panel then
		return
	end
	if tab == "titles" then
		fillTitles()
	else
		fill()
	end
end

function Goals.isOpen(): boolean
	return panel ~= nil
end

function Goals.close()
	if panel then
		Kit.closePanel(panel)
		panel = nil
		list = nil
		detail = nil
	end
end

function Goals.open()
	Goals.close()
	tab = "goals"
	panel = Kit.panel(
		"Town goals",
		Kit.MenuSize,
		function()
			Goals.close()
		end,
		"trophy",
		T.Yellow,
		{
			Caption = "What to work toward",
			Tabs = {
				{ id = "goals", name = "Goals" },
				{ id = "titles", name = "Titles" },
			},
			OnTab = function(id: string)
				tab = id
				refresh()
			end,
		}
	)
	-- the picked goal on the left, the list down the right
	local _, inside = MenuParts.card(panel.body, T.Yellow)
	detail = inside
	list = MenuParts.list(panel.body)
	fill()
end

for _, key in { "goals", "stats", "villagers", "rel", "coins", "titles", "title" } do
	State.on(key, function()
		refresh()
	end)
end

-- a change of look builds the list again in the new one (a row's shading is made for a look)
Kit.onTheme(function()
	refresh()
end)

return Goals
