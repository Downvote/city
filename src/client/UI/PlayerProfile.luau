-- Another player's profile (opened from their card, UI/PlayerMenu). The user: "Allow clicking on
-- other players to open an interface to view their profile and like their plot, add trusted". A
-- full menu (Kit.panel): them standing on the card at the left, their name and their town's
-- numbers under them; down the right, their town with Like and Visit, building (trusting them on
-- your plot with a budget, and whether they trust you on theirs) and their closest villagers with
-- their faces. All of it is the server's (PlayerCard, Services/Social); a press goes back through
-- PlotLike, PlotVisit and TrustSet, which check it.

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Tuning = require(Shared.Config.Tuning)
local Remotes = require(Shared.Net.Remotes)
local Text = require(Shared.Util.Text)
local Colors = require(Shared.Util.Colors)
local TrustSim = require(Shared.Sim.Trust)
local Personalities = require(Shared.Data.Personalities)

local Kit = require(script.Parent.Kit)
local MenuParts = require(script.Parent.MenuParts)
local ModelPreview = require(script.Parent.ModelPreview)
local Toasts = require(script.Parent.Toasts)

local PlayerProfile = {}

local T = Kit.Theme
local ACCENT = T.Teal

local panel: any = nil
local info: any = nil
local current: number? = nil
local budget = Tuning.Trust.Start
local serial = 0

local draw: () -> ()

function PlayerProfile.isOpen(): boolean
	return panel ~= nil
end

function PlayerProfile.close()
	serial += 1
	if panel then
		Kit.closePanel(panel)
		panel = nil
	end
	info, current = nil, nil
end

local function fetch()
	local id = current
	if not id then
		return
	end
	local mine = serial
	task.spawn(function()
		local ok, got = pcall(function()
			return Remotes.fn("PlayerCard"):InvokeServer(id)
		end)
		if serial ~= mine or not panel then
			return
		end
		if ok and type(got) == "table" then
			info = got
			if got.trusted then
				budget = TrustSim.budget(got.trusted.budget)
			end
		end
		draw()
	end)
end

local function call(remote: string, ...: any)
	local args = table.pack(...)
	task.spawn(function()
		local ok, res, why = pcall(function()
			return Remotes.fn(remote):InvokeServer(table.unpack(args, 1, args.n))
		end)
		if ok and res then
			if remote == "PlotVisit" then
				PlayerProfile.close()
				return
			end
			fetch()
		else
			Toasts.show(if ok and type(why) == "string" then why else "Couldn't do that.", "warn")
		end
	end)
end

-- Their character, standing, on the card.
local function stand(inside: Frame, id: number)
	local holder = Kit.box({
		Name = "Avatar",
		Parent = inside,
		Size = UDim2.new(1, 0, 1, -150),
	})
	local found, other = pcall(function()
		return Players:GetPlayerByUserId(id)
	end)
	local char = if found and other then other.Character else nil
	if char and char:IsA("Model") then
		local vp, shade = ModelPreview.fromModel(char, { Parent = holder, Stand = true, Shadow = true })
		if vp then
			vp.ZIndex = 3
		end
		if shade then
			shade.ZIndex = 2
		end
	end
end

-- A villager's face from their body in the owner's plot, if it is about (Services/Plots draws them).
local function face(holder: GuiObject, plot: number?, vid: string)
	local plots = workspace:FindFirstChild("Plots")
	local p = plots and plot and plots:FindFirstChild("Plot" .. tostring(plot))
	local folder = p and p:FindFirstChild("Villagers")
	if not folder then
		return
	end
	for _, model in folder:GetChildren() do
		if model:IsA("Model") and model:GetAttribute("Vid") == vid then
			local vp = ModelPreview.fromModel(model, { Parent = holder, Face = true })
			if vp then
				Kit.rounded(vp)
			end
			return
		end
	end
end

local function trustRows(list: ScrollingFrame, t: any, order: number)
	if t.trusted then
		local _, inner = Kit.row({
			Name = "Trusted",
			Parent = list,
			Size = MenuParts.rowSize(64),
			Height = 64,
			LayoutOrder = order,
			Title = "Builds on your plot",
			Sub = Text.fill(
				"{left} of {budget} coins left",
				{ left = Text.commas(t.trusted.left or 0), budget = Text.commas(t.trusted.budget or 0) }
			),
			Marker = "hammer",
			MarkerColor = T.Purple,
			RightSpace = 124,
		})
		Kit.button("Stop", {
			Name = "Untrust",
			Parent = inner,
			Size = UDim2.fromOffset(104, 40),
			Position = UDim2.new(1, -20, 0.5, 0),
			AnchorPoint = Vector2.new(1, 0.5),
			Color = T.Red,
			TextSize = 16,
			ZIndex = 3,
		}, function()
			call("TrustSet", t.id, false)
		end)
	end
	-- the budget: down, the amount, up, and Trust (or Save)
	local _, inner = Kit.row({
		Name = "Budget",
		Parent = list,
		Size = MenuParts.rowSize(64),
		Height = 64,
		LayoutOrder = order + 1,
		Title = if t.trusted then "Change their budget" else "Let them build",
		Sub = "Paid from your coins",
		Marker = "coin",
		MarkerColor = T.Yellow,
		RightSpace = 300,
	})
	local steps = Kit.box({
		Name = "Steps",
		Parent = inner,
		Size = UDim2.fromOffset(290, 40),
		Position = UDim2.new(1, -20, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
	})
	steps.ZIndex = 3
	Kit.list(steps, 8, true, Enum.HorizontalAlignment.Right).VerticalAlignment = Enum.VerticalAlignment.Center
	Kit.iconButton("minus", nil, {
		Name = "Less",
		Parent = steps,
		Size = UDim2.fromOffset(40, 40),
		Color = T.PaperDark,
		LayoutOrder = 1,
		ZIndex = 4,
	}, function()
		budget = TrustSim.step(budget, -1)
		draw()
	end)
	Kit.title(Text.commas(budget), {
		Name = "Amount",
		Parent = steps,
		Size = UDim2.fromOffset(76, 40),
		TextSize = 18,
		Color = T.Ink,
		AlignX = Enum.TextXAlignment.Center,
		Wrap = false,
		LayoutOrder = 2,
		ZIndex = 4,
	})
	Kit.iconButton("plus", nil, {
		Name = "More",
		Parent = steps,
		Size = UDim2.fromOffset(40, 40),
		Color = T.PaperDark,
		LayoutOrder = 3,
		ZIndex = 4,
	}, function()
		budget = TrustSim.step(budget, 1)
		draw()
	end)
	Kit.button(if t.trusted then "Save" else "Trust", {
		Name = "Confirm",
		Parent = steps,
		Size = UDim2.fromOffset(104, 40),
		Color = T.Green,
		TextSize = 16,
		LayoutOrder = 4,
		ZIndex = 4,
	}, function()
		call("TrustSet", t.id, true, budget)
	end)
	if t.trustsYou then
		MenuParts.note(
			Text.fill(
				"You can build on their plot, {n} coins left. Stand on it and press Build.",
				{ n = Text.commas(t.trustsYou.left or 0) }
			),
			T.Teal,
			{ Name = "TrustsYou", Parent = list, LayoutOrder = order + 2 }
		)
	end
end

function draw()
	if not panel then
		return
	end
	for _, c in panel.body:GetChildren() do
		c:Destroy()
	end
	local t = info
	local _, inside = MenuParts.card(panel.body, ACCENT)
	if not t then
		MenuParts.note("Looking...", ACCENT, { Name = "Looking", Parent = inside })
		return
	end
	stand(inside, t.id)
	Kit.title(t.name, {
		Name = "Name",
		Parent = inside,
		Size = UDim2.new(1, 0, 0, 40),
		Position = UDim2.new(0, 0, 1, -142),
		TextSize = 32,
		Wrap = false,
		ZIndex = 4,
	}).TextTruncate =
		Enum.TextTruncate.AtEnd
	Kit.text(if t.friend then "@" .. tostring(t.user) .. ", your friend" else "@" .. tostring(t.user), {
		Name = "User",
		Parent = inside,
		Size = UDim2.new(1, 0, 0, 18),
		Position = UDim2.new(0, 0, 1, -102),
		TextSize = 14,
		Color = T.InkSoft,
		Wrap = false,
		ZIndex = 4,
	})
	local grid = Kit.box({
		Name = "Stats",
		Parent = inside,
		Size = UDim2.new(1, 0, 0, 76),
		Position = UDim2.new(0, 0, 1, -76),
	})
	grid.ZIndex = 4
	Kit.grid(grid, UDim2.new(1 / 3, -7, 0, 76), 10)
	MenuParts.stat(
		"city",
		"Level",
		tostring(t.level or 1),
		T.Purple,
		{ Name = "Level", Parent = grid, LayoutOrder = 1 }
	)
	MenuParts.stat("people", "Villagers", tostring(t.people or 0), T.Green, {
		Name = "People",
		Parent = grid,
		LayoutOrder = 2,
	})
	MenuParts.stat(
		"heart",
		"Likes",
		Text.commas(t.likes or 0),
		T.Pink,
		{ Name = "Likes", Parent = grid, LayoutOrder = 3 }
	)

	local list = MenuParts.list(panel.body)
	MenuParts.heading(list, "Town", ACCENT, 1, nil)
	local _, inner = Kit.row({
		Name = "Town",
		Parent = list,
		Size = MenuParts.rowSize(64),
		Height = 64,
		LayoutOrder = 2,
		Title = t.town,
		Sub = Text.fill("Level {n}, {v} villagers", { n = t.level or 1, v = t.people or 0 }),
		Marker = "house",
		MarkerColor = ACCENT,
		RightSpace = 236,
	})
	Kit.button(Text.commas(t.likes or 0), {
		Name = "Like",
		Parent = inner,
		Size = UDim2.fromOffset(96, 40),
		Position = UDim2.new(1, -132, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
		Color = if t.liked then T.Pink else T.PaperDark,
		TextColor = if t.liked then T.White else T.Ink,
		TextSize = 16,
		Icon = "heart",
		ZIndex = 3,
	}, function()
		call("PlotLike", t.id)
	end)
	Kit.button("Visit", {
		Name = "Visit",
		Parent = inner,
		Size = UDim2.fromOffset(100, 40),
		Position = UDim2.new(1, -20, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
		Color = ACCENT,
		TextSize = 16,
		ZIndex = 3,
	}, function()
		call("PlotVisit", t.id)
	end)

	MenuParts.heading(list, "Building", ACCENT, 10, nil)
	trustRows(list, t, 11)

	local top = if type(t.top) == "table" then t.top else {}
	MenuParts.heading(list, "Their villagers", ACCENT, 20, tostring(#top))
	if #top == 0 then
		MenuParts.note("No villagers yet.", ACCENT, { Name = "Nobody", Parent = list, LayoutOrder = 21 })
	end
	for i, v in top do
		local pers = Personalities.get(v.pers)
		local row, rowInner = Kit.row({
			Name = "Villager",
			Parent = list,
			Size = MenuParts.rowSize(64),
			Height = 64,
			LayoutOrder = 20 + i,
			Title = v.name,
			Sub = Text.fill("{pers}, {hearts} hearts with their mayor", {
				pers = if pers then pers.name else "Villager",
				hearts = v.heart or 0,
			}),
			LeftSpace = 66,
		})
		local lean: number = row:GetAttribute("Lean") or 6
		local own = Colors.fromHex(v.color)
		local portrait = Kit.portrait({
			Parent = rowInner,
			Size = 48,
			Position = UDim2.new(0, lean + 1, 0.5, -24),
			Color = own:Lerp(T.Cream, 0.5),
			Border = own:Lerp(T.White, 0.35),
			BorderWidth = 2,
			ZIndex = 3,
		})
		face(portrait, t.plot, v.vid)
	end
end

-- arg: { id = userId } (and { card = ... } from the previews, with what the server would say)
function PlayerProfile.open(arg: any)
	PlayerProfile.close()
	local id = type(arg) == "table" and arg.id
	if type(id) ~= "number" then
		return
	end
	current = id
	budget = Tuning.Trust.Start
	local found, other = pcall(function()
		return Players:GetPlayerByUserId(id)
	end)
	other = if found then other else nil
	local title = if other then other.DisplayName elseif type(arg.card) == "table" then arg.card.name else "Player"
	panel = Kit.panel(tostring(title), Kit.MenuSize, PlayerProfile.close, "person", ACCENT, {
		Caption = "Another player",
	})
	if type(arg.card) == "table" then
		info = arg.card
		if info.trusted then
			budget = TrustSim.budget(info.trusted.budget)
		end
		draw()
		return
	end
	draw()
	fetch()
end

-- a change of look builds it again in the new one
Kit.onTheme(function()
	if panel then
		draw()
	end
end)

return PlayerProfile
