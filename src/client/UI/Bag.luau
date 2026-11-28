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
	-- the thing on its disc at the left of the card's top, how many you have beside it in a big
	-- number, who would love it under that, and its name flush left under them
	local disc = Kit.disc({
		Name = "Picture",
		Parent = frame,
		Size = MenuParts.Hero,
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
	local who = lovers(item)
	MenuParts.payout(frame, "In your bag", {
		number = { text = Text.commas(entry.n) },
		line = if #who > 0
			then {
				text = Text.fill("{x} would love it.", { x = table.concat(who, ", ") }),
				icon = "heart",
				tint = T.Pink,
			}
			else nil,
	}, { Name = "Count" })
	MenuParts.headline(frame, item.name, Items.categoryName(item.cat))
	-- at the foot: hold it (or put it away) and drop one
	local holding = player:GetAttribute("Holding") == item.id
	MenuParts.footButton(frame, if holding then "Put away" else "Hold", {
		Name = "Hold",
		Share = 0.6,
		Color = T.Blue,
		TextSize = 20,
	}, function()
		call(if holding then "away" else "hold", item.id)
	end)
	MenuParts.footButton(frame, "Drop", {
		Name = "Drop",
		Share = 0.4,
		At = "right",
		Color = T.Coral,
		TextSize = 20,
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
