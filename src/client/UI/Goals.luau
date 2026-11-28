-- The town's goals: what to work toward as the town grows, how far along each one is, and a
-- button to claim the coins for each one that's done. A full menu (Kit.panel): the goals as a
-- list of rows down the right, the picked one in full on the left.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Remotes = require(Shared.Net.Remotes)
local Life = require(Shared.Sim.Life)
local Text = require(Shared.Util.Text)

local Kit = require(script.Parent.Kit)
local Icons = require(script.Parent.Icons)
local MenuParts = require(script.Parent.MenuParts)
local Toasts = require(script.Parent.Toasts)
local State = require(script.Parent.Parent.Controllers.State)

local Goals = {}

local T = Kit.Theme
local panel: any = nil
local list: ScrollingFrame? = nil
local detail: Frame? = nil

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
	-- a faint line round the ring, the way a dial is drawn
	local outline = Kit.new("Frame", {
		Name = "Outline",
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(186, 186),
		Position = UDim2.new(0.5, -93, 0, 19),
		Parent = frame,
	})
	Kit.corner(outline, "round")
	Kit.rim(outline, T.Line, 1, 0.3)
	local _, middle = Kit.ring({
		Name = "Ring",
		Parent = frame,
		Size = 168,
		Position = UDim2.new(0.5, -84, 0, 28),
		Thickness = 16,
		Track = T.PaperDark,
		Hole = T.Paper,
	}, ratio, if g.done then T.Green else T.Yellow)
	if g.claimed then
		-- a claimed goal is ticked off in the middle of its ring
		Kit.disc({
			Name = "Tick",
			Parent = middle,
			Size = 72,
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
				TextSize = 34,
				AlignX = Enum.TextXAlignment.Center,
			}
		)
	end
	Kit.title(g.goal.name, {
		Name = "GoalName",
		Parent = frame,
		Size = UDim2.new(1, 0, 0, 36),
		Position = UDim2.fromOffset(0, 216),
		TextSize = 30,
		AlignX = Enum.TextXAlignment.Center,
	})
	Kit.text(g.goal.desc, {
		Name = "Desc",
		Parent = frame,
		Size = UDim2.new(1, -24, 0, 44),
		Position = UDim2.fromOffset(12, 256),
		TextSize = 17,
		Color = T.InkSoft,
		AlignX = Enum.TextXAlignment.Center,
		AlignY = Enum.TextYAlignment.Top,
	})
	-- what it pays
	local pay = Kit.frame({
		Name = "Reward",
		Parent = frame,
		Size = UDim2.fromOffset(0, 40),
		AutomaticSize = Enum.AutomaticSize.X,
		Position = UDim2.new(0.5, 0, 0, 306),
		AnchorPoint = Vector2.new(0.5, 0),
		Color = T.PaperDark,
		Radius = false,
	})
	-- a leaning slab, its slanted ends standing out past the words (which sit in a row of their
	-- own, so the painted slab under them stays put)
	Kit.slant(pay, 40, true)
	local payRow = Kit.box({
		Name = "Row",
		Parent = pay,
		Size = UDim2.fromOffset(0, 40),
		AutomaticSize = Enum.AutomaticSize.X,
	})
	payRow.ZIndex = 2
	Kit.pad(payRow, 12, 3)
	Kit.list(payRow, 8, true, Enum.HorizontalAlignment.Center)
	Kit.text(if g.claimed then "Paid" else "Pays", {
		Parent = payRow,
		Size = UDim2.fromOffset(0, 34),
		AutomaticSize = Enum.AutomaticSize.X,
		TextSize = 17,
		Color = T.InkSoft,
		Wrap = false,
		LayoutOrder = 0,
	})
	Icons.make("coin", 28, { Parent = payRow, LayoutOrder = 1 })
	Kit.title(Text.commas(g.goal.reward), {
		Parent = payRow,
		Size = UDim2.fromOffset(0, 34),
		AutomaticSize = Enum.AutomaticSize.X,
		TextSize = 24,
		Tint = T.YellowDark,
		Wrap = false,
		LayoutOrder = 2,
	})
	-- at the foot: the button to claim it, when it's done (nothing in its place otherwise: the ring
	-- and the row say how far along it is)
	if ready then
		Kit.button(Text.fill("Claim {n}", { n = Text.commas(g.goal.reward) }), {
			Name = "Claim",
			Parent = frame,
			Size = UDim2.fromOffset(260, 54),
			Position = UDim2.new(0.5, 0, 1, 0),
			AnchorPoint = Vector2.new(0.5, 1),
			Color = T.Green,
			TextSize = 22,
			Icon = "coin",
			Radius = "pill",
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
	panel = Kit.panel("Town goals", Kit.MenuSize, function()
		Goals.close()
	end, "trophy", T.Yellow, { Caption = "What to work toward" })
	-- the picked goal on the left, the list down the right
	local _, inside = MenuParts.card(panel.body, T.Yellow)
	detail = inside
	list = MenuParts.list(panel.body)
	fill()
end

for _, key in { "goals", "stats", "villagers", "rel", "coins" } do
	State.on(key, function()
		if panel then
			fill()
		end
	end)
end

-- a change of look builds the list again in the new one (a row's shading is made for a look)
Kit.onTheme(function()
	if panel then
		fill()
	end
end)

return Goals
