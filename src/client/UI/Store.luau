-- The store: the game passes and the gem packs, bought with Robux (the user: "add gamepasses, just
-- like bloxburg" and "allow players to buy gems ... and buying with robux"). A full menu
-- (Kit.panel) with two tabs. Passes: each a card with its icon, its name, what it does, its price
-- and Buy (or Owned). Gems: what the player has and the packs. Buying asks Roblox
-- (Controllers/Purchase); the server says what is owned (State's `passes` and `gems`).
-- It opens from the round Store button under the clock, and from the gems on the main screen.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local PassData = require(Shared.Data.Passes)
local Text = require(Shared.Util.Text)

local Kit = require(script.Parent.Kit)
local Icons = require(script.Parent.Icons)
local MenuParts = require(script.Parent.MenuParts)
local State = require(script.Parent.Parent.Controllers.State)
local Purchase = require(script.Parent.Parent.Controllers.Purchase)

local Store = {}

local T = Kit.Theme
local panel: any = nil
local tab = "passes"
local unbind: { () -> () } = {}

-- Each pass's colour, by its place in the list (VIP is gold).
local function accentOf(i: number, key: string): Color3
	if key == "vip" then
		return T.Yellow
	end
	local ring = { T.Blue, T.Teal, T.Orange, T.Green, T.Pink, T.Purple, T.Coral }
	return ring[(i - 1) % #ring + 1]
end

-- A Robux price as the store writes it.
function Store.price(robux: number): string
	return Text.fill("R$ {n}", { n = Text.commas(robux) })
end

-- A small leaning tag with an icon and words (Owned, a pack's gems): a slab whose slanted ends
-- stand out past its words, which sit in a row of their own so the painted slab stays put.
-- props: Parent, Position, AnchorPoint, Height, Color (the slab's), TextColor, IconColor, Name,
-- LayoutOrder, TextSize. Returns the tag.
function Store.tag(icon: string?, words: string, props: { [string]: any }): Frame
	local h: number = props.Height or 34
	local tag = Kit.frame({
		Name = props.Name or "Tag",
		Parent = props.Parent,
		Size = UDim2.fromOffset(0, h),
		AutomaticSize = Enum.AutomaticSize.X,
		Position = props.Position,
		AnchorPoint = props.AnchorPoint,
		LayoutOrder = props.LayoutOrder,
		Color = props.Color or T.PaperDark,
		Radius = false,
	})
	Kit.slant(tag, h, true)
	local row =
		Kit.box({ Name = "Row", Parent = tag, Size = UDim2.fromOffset(0, h), AutomaticSize = Enum.AutomaticSize.X })
	row.ZIndex = 2
	Kit.pad(row, 10, 2)
	Kit.list(row, 6, true, Enum.HorizontalAlignment.Center)
	local textColor: Color3 = props.TextColor or T.Ink
	if icon then
		Icons.make(icon, math.floor(h * 0.62), {
			Name = "IconArt",
			Parent = row,
			LayoutOrder = 1,
			Color = props.IconColor or textColor,
			Hole = props.Color or T.PaperDark,
			Mono = icon == "coin",
			Centre = true,
		})
	end
	Kit.title(words, {
		Name = "Words",
		Parent = row,
		Size = UDim2.fromOffset(0, h - 4),
		AutomaticSize = Enum.AutomaticSize.X,
		TextSize = props.TextSize or 17,
		Color = textColor,
		Wrap = false,
		LayoutOrder = 2,
	})
	return tag
end

local function clear()
	if not panel then
		return
	end
	for _, c in panel.body:GetChildren() do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
end

-- Passes -----------------------------------------------------------------------------------------

-- five across and two down fill a menu's body (1118 by 518) with no scrolling
local CARD_W, CARD_H, GAP = 206, 250, 12

local function passCard(parent: Instance, pass: PassData.Pass, i: number)
	local accent = accentOf(i, pass.key)
	local owned = Purchase.has(pass.key)
	local card = Kit.frame({
		Name = pass.key,
		Parent = parent,
		LayoutOrder = i,
		Color = T.Paper,
		Cut = 14,
	})
	Kit.glow(card, accent, if owned then 0.12 else 0.2, "tr")
	Kit.brackets(card, { Corners = { "tl", "br" }, Arm = 10, Inset = 6, Color = T.Line, ZIndex = 1 })
	Kit.mark(card)
	Kit.disc({
		Name = "Mark",
		Parent = card,
		Size = 52,
		Position = UDim2.fromOffset(16, 16),
		Color = accent,
		Icon = pass.icon,
		ZIndex = 2,
	})
	Kit.caption(Kit.index(i), {
		Name = "Index",
		Parent = card,
		Size = UDim2.fromOffset(40, 16),
		Position = UDim2.new(1, -16, 0, 18),
		AnchorPoint = Vector2.new(1, 0),
		TextSize = 11,
		AlignX = Enum.TextXAlignment.Right,
	})
	Kit.title(pass.name, {
		Name = "PassName",
		Parent = card,
		Size = UDim2.new(1, -32, 0, 28),
		Position = UDim2.fromOffset(16, 78),
		TextSize = 21,
		Color = T.Ink,
		Wrap = false,
		ZIndex = 2,
	})
	Kit.text(pass.blurb, {
		Name = "Blurb",
		Parent = card,
		Size = UDim2.new(1, -32, 0, 84),
		Position = UDim2.fromOffset(16, 108),
		TextSize = 15,
		Color = T.InkSoft,
		AlignY = Enum.TextYAlignment.Top,
		ZIndex = 2,
	})
	-- at its foot: the price and Buy, or that it is theirs
	local foot = Kit.box({
		Name = "Foot",
		Parent = card,
		Size = UDim2.new(1, -32, 0, 42),
		Position = UDim2.new(0, 16, 1, -56),
	})
	foot.ZIndex = 2
	if owned then
		Store.tag("check", "Owned", {
			Name = "Owned",
			Parent = foot,
			Height = 36,
			Position = UDim2.new(0, 10, 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5),
			Color = T.Green,
			TextColor = T.Dark,
		})
		return
	end
	Kit.title(Store.price(pass.price), {
		Name = "Price",
		Parent = foot,
		Size = UDim2.new(0.5, 0, 1, 0),
		TextSize = 20,
		Tint = T.YellowDark,
		Wrap = false,
	})
	local onSale = pass.id ~= 0
	Kit.button(if onSale then "Buy" else "Soon", {
		Name = "Buy",
		Parent = foot,
		Size = UDim2.fromOffset(92, 40),
		Position = UDim2.new(1, -6, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
		Color = if onSale then T.Green else T.Card,
		TextColor = if onSale then T.Dark else T.InkSoft,
		TextSize = 18,
	}, function()
		Purchase.prompt(pass.key)
	end)
end

local function showPasses()
	local body = panel.body
	local scroll = Kit.scroll({ Name = "Passes", Parent = body, Size = UDim2.fromScale(1, 1) })
	local grid = Kit.grid(scroll, UDim2.fromOffset(CARD_W, CARD_H), GAP)
	grid.HorizontalAlignment = Enum.HorizontalAlignment.Center
	for i, pass in PassData.list do
		passCard(scroll, pass, i)
	end
end

-- Gems -----------------------------------------------------------------------------------------------

local function showGems()
	local body = panel.body
	local gems = if type(State.data.gems) == "number" then State.data.gems else 0
	local top = Kit.box({ Name = "Top", Parent = body, Size = UDim2.new(1, 0, 0, 78) })
	MenuParts.stat("gem", "Your gems", Text.commas(gems), T.Purple, {
		Name = "Have",
		Parent = top,
		Size = UDim2.fromOffset(230, 78),
		Tint = T.Purple,
	})
	MenuParts.hint(
		"Gems are rare. A few come each day from the daily gift and time played, and more from achievements and the group.",
		{
			Parent = top,
			Size = UDim2.new(1, -250, 0, 0),
			Position = UDim2.new(0, 250, 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5),
		}
	)
	local row = Kit.box({
		Name = "Packs",
		Parent = body,
		Size = UDim2.new(1, 0, 1, -98),
		Position = UDim2.fromOffset(0, 98),
	})
	-- (the packs in the middle of the room under the strip)
	local list = Kit.list(row, GAP, true, Enum.HorizontalAlignment.Center)
	list.VerticalAlignment = Enum.VerticalAlignment.Center
	for i, pack in PassData.packs do
		local card = Kit.frame({
			Name = pack.key,
			Parent = row,
			Size = UDim2.fromOffset(CARD_W, 320),
			LayoutOrder = i,
			Color = T.Paper,
			Cut = 14,
		})
		Kit.glow(card, T.Purple, 0.12 + i * 0.03, "tr")
		Kit.brackets(card, { Corners = { "tl", "br" }, Arm = 10, Inset = 6, Color = T.Line, ZIndex = 1 })
		Kit.mark(card)
		-- the bigger the pack, the more gems in its picture
		local pile = Kit.box({
			Name = "Pile",
			Parent = card,
			Size = UDim2.new(1, 0, 0, 120),
			Position = UDim2.fromOffset(0, 22),
		})
		pile.ZIndex = 2
		local count = math.min(i, 3)
		for k = 1, count do
			local px = if k == 1 then 64 else 44
			local dx = if k == 1 then 0 elseif k == 2 then -46 else 46
			Kit.disc({
				Name = "Gem" .. k,
				Parent = pile,
				Size = px,
				Position = UDim2.new(0.5, dx, 0, if k == 1 then 10 else 34),
				AnchorPoint = Vector2.new(0.5, 0),
				Color = T.Purple,
				Icon = "gem",
				ZIndex = if k == 1 then 4 else 3,
			})
		end
		Kit.title(Text.commas(pack.gems), {
			Name = "Count",
			Parent = card,
			Size = UDim2.new(1, -24, 0, 40),
			Position = UDim2.fromOffset(12, 130),
			TextSize = 38,
			Tint = T.Purple,
			AlignX = Enum.TextXAlignment.Center,
			Wrap = false,
		})
		Kit.caption("gems", {
			Name = "Unit",
			Parent = card,
			Size = UDim2.new(1, -24, 0, 16),
			Position = UDim2.fromOffset(12, 172),
			TextSize = 11,
			AlignX = Enum.TextXAlignment.Center,
		})
		Kit.text(pack.name, {
			Name = "PackName",
			Parent = card,
			Size = UDim2.new(1, -24, 0, 22),
			Position = UDim2.fromOffset(12, 196),
			TextSize = 16,
			Color = T.InkSoft,
			AlignX = Enum.TextXAlignment.Center,
			Wrap = false,
		})
		Kit.button(Store.price(pack.price), {
			Name = "Buy",
			Parent = card,
			Size = UDim2.new(1, -40, 0, 44),
			Position = UDim2.new(0.5, 0, 1, -18),
			AnchorPoint = Vector2.new(0.5, 1),
			Color = if pack.id ~= 0 then T.Green else T.Card,
			TextColor = if pack.id ~= 0 then T.Dark else T.InkSoft,
			TextSize = 19,
		}, function()
			Purchase.gems(pack.key)
		end)
	end
end

local function fill()
	if not panel then
		return
	end
	clear()
	if tab == "gems" then
		showGems()
	else
		showPasses()
	end
end

function Store.isOpen(): boolean
	return panel ~= nil
end

function Store.close()
	for _, u in unbind do
		u()
	end
	unbind = {}
	if panel then
		Kit.closePanel(panel)
		panel = nil
	end
end

-- Opens the store: on its Gems tab with `arg` "gems", else on the passes.
function Store.open(arg: any?)
	Store.close()
	tab = if arg == "gems" then "gems" else "passes"
	panel = Kit.panel("Store", Kit.MenuSize, Store.close, "store", T.Purple, {
		Caption = "Passes and gems",
		Tabs = { { id = "passes", name = "Passes" }, { id = "gems", name = "Gems" } },
		OnTab = function(id: string)
			tab = id
			fill()
		end,
	})
	if tab == "gems" and panel.selectTab then
		panel.selectTab("gems")
	end
	fill()
	-- what Roblox says was bought shows at once
	for _, key in { "passes", "gems" } do
		-- (State.on calls at once with what is there already: that one is drawn)
		local skip = State.data[key] ~= nil
		table.insert(
			unbind,
			State.on(key, function()
				if skip then
					skip = false
					return
				end
				if panel then
					fill()
				end
			end)
		)
	end
end

-- a change of look builds it again in the new one
Kit.onTheme(function()
	if panel then
		fill()
	end
end)

return Store
