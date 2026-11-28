-- The bag: the things the player carries (Sim/Bag). The user: "add an inventory system to the
-- player", and "make it such that you can pick up items, and interactable items give you things".
-- A full menu (Kit.panel) laid out like the others: the picked thing on the card at the left, big,
-- with its kind, how many there are, who in town would love it, and two buttons, Hold (it goes in
-- the player's hand for everyone to see, or Put away when it is there) and Drop (one is laid on the
-- ground in front of them, to pick up again for a while); every thing in the bag down the right,
-- by kind, with how full the bag is over them. The BagUse remote does both on the server. Things
-- are given to villagers from their talk card or their page (UI/GiftPicker).
-- Scenes: ui.sh panel:Bag (a few things), panel:Bag:empty, panel:Bag:holding.

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Tuning = require(Shared.Config.Tuning)
local Remotes = require(Shared.Net.Remotes)
local Items = require(Shared.Data.Items)
local Bag = require(Shared.Sim.Bag)
local Gifts = require(Shared.Sim.Gifts)
local Colors = require(Shared.Util.Colors)
local Text = require(Shared.Util.Text)

local Kit = require(script.Parent.Kit)
local Icons = require(script.Parent.Icons)
local MenuParts = require(script.Parent.MenuParts)
local Toasts = require(script.Parent.Toasts)
local State = require(script.Parent.Parent.Controllers.State)

local BagMenu = {}

local T = Kit.Theme
local player = Players.LocalPlayer
local panel: any = nil
local list: ScrollingFrame? = nil
local detail: Frame? = nil
local picked: string? = nil
local unbind: { () -> () } = {}

local function view(): any
	return { bag = State.data.bag or {}, owed = State.data.owed or {} }
end

-- Who in town would love a thing, by name.
local function lovers(item: Items.Item): { string }
	local out = {}
	for _, v in State.villagerList() do
		if not v.isYou and Gifts.taste(v, item) == "love" then
			table.insert(out, v.name)
		end
	end
	return out
end

local function call(action: string, id: string?)
	task.spawn(function()
		local ok, done, why = pcall(function()
			return Remotes.fn("BagUse"):InvokeServer(action, id)
		end)
		if ok and not done and type(why) == "string" then
			Toasts.show(why, "warn")
		end
	end)
end

-- The card on the left: the picked thing.
local function showDetail(entry: Bag.Entry?)
	local frame = detail
	if not frame then
		return
	end
	for _, c in frame:GetChildren() do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
	if not entry then
		return
	end
	local item = entry.item
	local own = Colors.fromHex(item.color)
	local disc = Kit.disc({
		Name = "Picture",
		Parent = frame,
		Size = 150,
		Position = UDim2.new(0.5, 0, 0, 14),
		AnchorPoint = Vector2.new(0.5, 0),
		Color = T.Picture,
	})
	Icons.item(item.id, 96, own, {
		Name = "Thing",
		Parent = disc,
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Centre = true,
		ZIndex = 3,
	})
	Kit.title(item.name, {
		Name = "ThingName",
		Parent = frame,
		Size = UDim2.new(1, 0, 0, 36),
		Position = UDim2.fromOffset(0, 176),
		TextSize = 30,
		AlignX = Enum.TextXAlignment.Center,
	})
	Kit.caption(Items.categoryName(item.cat), {
		Name = "Kind",
		Parent = frame,
		Size = UDim2.new(1, 0, 0, 16),
		Position = UDim2.fromOffset(0, 214),
		TextSize = 12,
		AlignX = Enum.TextXAlignment.Center,
	})
	local who = lovers(item)
	local about = Text.fill("{n} in your bag.", { n = entry.n })
	if #who > 0 then
		about ..= " " .. Text.fill("{x} would love it.", { x = table.concat(who, ", ") })
	end
	Kit.text(about, {
		Name = "About",
		Parent = frame,
		Size = UDim2.new(1, -24, 0, 44),
		Position = UDim2.fromOffset(12, 238),
		TextSize = 16,
		Color = T.InkSoft,
		AlignX = Enum.TextXAlignment.Center,
		AlignY = Enum.TextYAlignment.Top,
	})
	-- at the foot: hold it (or put it away) and drop one
	local foot = Kit.box({
		Name = "Actions",
		Parent = frame,
		Size = UDim2.new(1, 0, 0, 50),
		Position = UDim2.new(0, 0, 1, -50),
	})
	Kit.list(foot, 12, true, Enum.HorizontalAlignment.Center)
	local holding = player:GetAttribute("Holding") == item.id
	Kit.button(if holding then "Put away" else "Hold", {
		Name = "Hold",
		Parent = foot,
		Size = UDim2.fromOffset(170, 48),
		Color = T.Blue,
		TextSize = 20,
		LayoutOrder = 1,
	}, function()
		call(if holding then "away" else "hold", item.id)
	end)
	Kit.button("Drop", {
		Name = "Drop",
		Parent = foot,
		Size = UDim2.fromOffset(130, 48),
		Color = T.Coral,
		TextSize = 20,
		LayoutOrder = 2,
	}, function()
		call("drop", item.id)
	end)
end

-- The list down the right: how full the bag is, then the things by kind.
local function fill()
	local frame = list
	if not frame then
		return
	end
	for _, c in frame:GetChildren() do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
	local p = view()
	local entries = Bag.entries(p)
	local total = Bag.total(p)
	MenuParts.progress(
		"Room in your bag",
		Text.fill("{a} of {b}", { a = total, b = Tuning.Bag.Total }),
		total / Tuning.Bag.Total,
		{ Name = "Room", Parent = frame, Size = MenuParts.rowSize(44), LayoutOrder = 0, Color = T.Orange }
	)
	local waiting = 0
	for _, n in p.owed do
		waiting += if type(n) == "number" then n else 0
	end
	if waiting > 0 then
		MenuParts.note(
			if waiting == 1
				then "1 thing from a goal waits for room."
				else Text.fill("{n} things from goals wait for room.", { n = waiting }),
			T.Orange,
			{ Parent = frame, Size = MenuParts.rowSize(24), LayoutOrder = 1 }
		)
	end
	if #entries == 0 then
		showDetail(nil)
		MenuParts.empty("bag", "Your bag is empty", "Hold E on bookshelves, flower beds and stoves round your town.", {
			Parent = frame,
			Size = MenuParts.rowSize(250),
			Height = 250,
			LayoutOrder = 2,
			Color = T.Orange,
		})
		return
	end
	local show: Bag.Entry? = nil
	for _, e in entries do
		if e.item.id == picked then
			show = e
		end
	end
	show = show or entries[1]
	local rows: { [string]: GuiObject } = {}
	local order, cat = 1, nil
	for _, e in entries do
		if e.item.cat ~= cat then
			cat = e.item.cat
			local n = 0
			for _, other in entries do
				n += if other.item.cat == cat then other.n else 0
			end
			order += 1
			MenuParts.heading(frame, Items.categoryName(cat), T.Orange, order, tostring(n))
		end
		order += 1
		local row, inner = Kit.row({
			Name = e.item.id,
			Parent = frame,
			Size = MenuParts.rowSize(),
			LayoutOrder = order,
			Title = e.item.name,
			Right = Text.fill("x{n}", { n = e.n }),
			LeftSpace = 62,
		}, function()
			picked = e.item.id
			for id, r in rows do
				Kit.setRowSelected(r, id == picked)
			end
			showDetail(e)
		end)
		Icons.item(e.item.id, 38, Colors.fromHex(e.item.color), {
			Parent = inner,
			Position = UDim2.new(0, 16, 0.5, -19),
			Centre = true,
			ZIndex = 3,
		})
		rows[e.item.id] = row
	end
	if show then
		picked = show.item.id
		Kit.setRowSelected(rows[show.item.id], true)
		showDetail(show)
	end
end

function BagMenu.isOpen(): boolean
	return panel ~= nil
end

function BagMenu.close()
	for _, u in unbind do
		u()
	end
	unbind = {}
	if panel then
		Kit.closePanel(panel)
		panel = nil
		list = nil
		detail = nil
	end
end

function BagMenu.open()
	BagMenu.close()
	panel = Kit.panel("Bag", Kit.MenuSize, BagMenu.close, "bag", T.Orange, { Caption = "Things you carry" })
	local _, inside = MenuParts.card(panel.body, T.Orange)
	detail = inside
	list = MenuParts.list(panel.body)
	fill()
	for _, key in { "bag", "owed", "villagers" } do
		table.insert(unbind, State.on(key, fill))
	end
	local held = player:GetAttributeChangedSignal("Holding"):Connect(fill)
	table.insert(unbind, function()
		held:Disconnect()
	end)
end

-- a change of look builds it again in the new one
Kit.onTheme(function()
	if panel then
		fill()
	end
end)

return BagMenu
