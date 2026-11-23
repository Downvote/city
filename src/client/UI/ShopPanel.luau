-- The plaza shop: food for villagers, medicine and party cakes. A full menu (Kit.panel) with a
-- tab for each shelf: the things as a list of rows down the right, each with its picture and
-- price, and the picked one big on the left with the buttons to buy it.

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Remotes = require(Shared.Net.Remotes)
local Foods = require(Shared.Data.Foods)
local Items = require(Shared.Data.Items)
local Tuning = require(Shared.Config.Tuning)
local Colors = require(Shared.Util.Colors)
local Text = require(Shared.Util.Text)

local Kit = require(script.Parent.Kit)
local Icons = require(script.Parent.Icons)
local MenuParts = require(script.Parent.MenuParts)
local Toasts = require(script.Parent.Toasts)
local State = require(script.Parent.Parent.Controllers.State)

local ShopPanel = {}

local T = Kit.Theme
local player = Players.LocalPlayer
local panel: any = nil
local unbind: { () -> () } = {}

local function sale(): boolean
	local untilT = player:GetAttribute("MerchantUntil")
	return type(untilT) == "number" and untilT > os.time()
end

local function price(base: number): number
	if sale() then
		return math.max(1, math.floor(base * Tuning.Rewards.MerchantDiscount))
	end
	return base
end

local function buy(kind: string, id: string, n: number)
	task.spawn(function()
		local ok, msg = Remotes.fn("ShopBuy"):InvokeServer(kind, id, n)
		if ok then
			Toasts.show(msg or "Bought.", "good")
		elseif msg then
			Toasts.show(msg, "warn")
		end
	end)
end

-- what is being looked at: which shelf, and which thing on it
local shelf = "food"
local picked: { [string]: string } = {}

type Ware = { kind: string, id: string, name: string, blurb: string, cost: number, have: number, color: Color3 }

local function wares(): { Ware }
	local inv = State.data.inv or { food = {}, items = {} }
	local out: { Ware } = {}
	if shelf == "things" then
		for _, item in Items.list do
			table.insert(out, {
				kind = "item",
				id = item.id,
				name = item.name,
				blurb = item.blurb,
				cost = price(item.price),
				have = inv.items[item.id] or 0,
				color = if item.id == "cake" then T.Coral else T.Blue,
			})
		end
	else
		for _, f in Foods.shop() do
			table.insert(out, {
				kind = "food",
				id = f.id,
				name = f.name,
				blurb = "Cheers someone up.",
				cost = price(f.price :: number),
				have = inv.food[f.id] or 0,
				color = Colors.fromHex(f.color),
			})
		end
	end
	return out
end

-- The left side: the picked thing, big, with what it does, how many you have and the buttons.
-- `frame` is the padded box inside the card.
local function showDetail(frame: Frame, w: Ware)
	for _, c in frame:GetChildren() do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
	local stage = Kit.box({ Name = "Picture", Parent = frame, Size = UDim2.new(1, 0, 0, 200) })
	Kit.halo(stage, 250, w.color, 0.3)
	Icons.item(w.id, 168, w.color, {
		Parent = stage,
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		ZIndex = 2,
	})
	Kit.title(w.name, {
		Name = "WareName",
		Parent = frame,
		Size = UDim2.new(1, 0, 0, 36),
		Position = UDim2.fromOffset(0, 206),
		TextSize = 30,
		AlignX = Enum.TextXAlignment.Center,
	})
	Kit.text(w.blurb, {
		Name = "Blurb",
		Parent = frame,
		Size = UDim2.new(1, -24, 0, 24),
		Position = UDim2.fromOffset(12, 244),
		TextSize = 17,
		Color = T.InkSoft,
		AlignX = Enum.TextXAlignment.Center,
	})
	-- how many you have, on a little tag
	local have = Kit.frame({
		Name = "Have",
		Parent = frame,
		Size = UDim2.fromOffset(150, 30),
		Position = UDim2.new(0.5, 0, 0, 282),
		AnchorPoint = Vector2.new(0.5, 0),
		Color = T.PaperDark,
		Cut = 8,
	})
	Kit.text(Text.fill("You have {n}", { n = w.have }), {
		Parent = have,
		Size = UDim2.fromScale(1, 1),
		TextSize = 15,
		Font = Kit.Fonts.Bold,
		AlignX = Enum.TextXAlignment.Center,
		Wrap = false,
	})
	-- the buttons at the foot, and what stands in the way if anything does
	local coins = State.data.coins or 0
	local party = w.id == "cake" -- a cake is eaten at the party it starts, so one at a time
	local foot = if party
		then "Buying one starts a party straight away."
		elseif coins < w.cost then Text.fill("You need {n} more coins.", { n = Text.commas(w.cost - coins) })
		else nil
	if foot then
		Kit.text(foot, {
			Name = "Why",
			Parent = frame,
			Size = UDim2.new(1, 0, 0, 20),
			Position = UDim2.new(0, 0, 1, -82),
			TextSize = 15,
			Color = T.InkSoft,
			AlignX = Enum.TextXAlignment.Center,
		})
	end
	local buttons = Kit.box({
		Name = "Buttons",
		Parent = frame,
		Size = UDim2.new(1, 0, 0, 54),
		Position = UDim2.new(0, 0, 1, -54),
	})
	Kit.list(buttons, 12, true, Enum.HorizontalAlignment.Center)
	local function buyButton(text: string, n: number, color: Color3, width: number, order: number)
		local afford = coins >= w.cost * n
		Kit.button(text, {
			Name = if n == 1 then "BuyOne" else "BuyFive",
			Parent = buttons,
			Size = UDim2.fromOffset(width, 54),
			Color = if afford then color else T.Card,
			TextColor = if afford then T.White else T.InkSoft,
			TextSize = 20,
			Radius = "pill",
			Icon = "coin",
			LayoutOrder = order,
		}, function()
			if not afford then
				Toasts.show(Text.fill("You need {n} more coins.", { n = Text.commas(w.cost * n - coins) }), "warn")
				return
			end
			buy(w.kind, w.id, n)
		end)
	end
	buyButton(Text.fill("Buy for {n}", { n = Text.commas(w.cost) }), 1, T.Green, 236, 1)
	if not party then
		buyButton(Text.fill("5 for {n}", { n = Text.commas(w.cost * 5) }), 5, T.Blue, 196, 2)
	end
end

local function draw()
	if not panel then
		return
	end
	for _, c in panel.body:GetChildren() do
		c:Destroy()
	end
	-- the picked thing on the left, the shelf down the right
	local _, detail = MenuParts.card(panel.body, T.Orange)
	local scroll = MenuParts.list(panel.body)
	if sale() then
		Kit.row({
			Name = "Sale",
			Parent = scroll,
			Size = MenuParts.rowSize(),
			LayoutOrder = 0,
			Title = "A travelling merchant is in town",
			Sub = "Everything's cheaper for a little while.",
			Marker = "coins",
			MarkerColor = T.Green,
		})
	end
	local list = wares()
	local show: Ware? = nil
	for _, w in list do
		if w.id == picked[shelf] then
			show = w
		end
	end
	show = show or list[1]
	local rows: { [string]: GuiObject } = {}
	for i, w in list do
		local row, inner = Kit.row({
			Name = w.id,
			Parent = scroll,
			Size = MenuParts.rowSize(),
			LayoutOrder = i,
			Title = w.name,
			Sub = Text.fill("You have {n}", { n = w.have }),
			LeftSpace = 70,
			RightSpace = 120,
		}, function()
			picked[shelf] = w.id
			for id, r in rows do
				Kit.setRowSelected(r, id == w.id)
			end
			showDetail(detail, w)
		end)
		Icons.item(w.id, 40, w.color, {
			Parent = inner,
			Position = UDim2.new(0, 18, 0.5, -20),
			ZIndex = 3,
		})
		-- the price, at the right end
		local tag = Kit.box({
			Parent = inner,
			Size = UDim2.fromOffset(0, 30),
			AutomaticSize = Enum.AutomaticSize.X,
			Position = UDim2.new(1, -22, 0.5, 0),
			AnchorPoint = Vector2.new(1, 0.5),
		})
		tag.ZIndex = 2
		Kit.list(tag, 6, true, Enum.HorizontalAlignment.Right)
		Icons.make("coin", 22, { Parent = tag, LayoutOrder = 1, ZIndex = 3 })
		Kit.new("TextLabel", {
			Name = "Right",
			Text = Text.commas(w.cost),
			BackgroundTransparency = 1,
			Font = Kit.Fonts.Title,
			TextSize = 19,
			TextColor3 = T.Ink,
			Size = UDim2.fromOffset(0, 30),
			AutomaticSize = Enum.AutomaticSize.X,
			LayoutOrder = 2,
			ZIndex = 3,
			Parent = tag,
		})
		rows[w.id] = row
	end
	if #list == 0 then
		MenuParts.empty("cart", "Nothing on this shelf", "Try the other shelf.", { Parent = scroll, LayoutOrder = 1 })
	end
	-- a word on what to do with them, under the shelf
	if shelf == "things" then
		MenuParts.heading(scroll, "What they do", T.Orange, 900)
		MenuParts.note(
			"A party cake cheers the whole town up and brings everyone a little closer. The party starts the moment you buy it.",
			T.Orange,
			{ Name = "Cake", Parent = scroll, LayoutOrder = 901, Height = 44 }
		)
		MenuParts.note(
			"When someone catches a cold you can give them medicine. A villager who's ill misses their pay.",
			T.Orange,
			{ Name = "Medicine", Parent = scroll, LayoutOrder = 902, Height = 44 }
		)
	else
		MenuParts.note(
			"Everyone has a favourite food. Feed them on the Villagers screen to find out what it is.",
			T.Orange,
			{ Name = "Hint", Parent = scroll, LayoutOrder = 999, Height = 44 }
		)
	end
	if show then
		picked[shelf] = show.id
		Kit.setRowSelected(rows[show.id], true)
		showDetail(detail, show)
	end
end

function ShopPanel.isOpen(): boolean
	return panel ~= nil
end

function ShopPanel.close()
	for _, u in unbind do
		u()
	end
	unbind = {}
	if panel then
		panel.root:Destroy()
		panel = nil
	end
end

function ShopPanel.open()
	ShopPanel.close()
	shelf = "food"
	panel = Kit.panel("Shop", Kit.MenuSize, ShopPanel.close, "cart", Kit.Theme.Orange, {
		Tabs = { { id = "food", name = "Food" }, { id = "things", name = "Things" } },
		OnTab = function(id: string)
			shelf = id
			draw()
		end,
	})
	Kit.popIn(panel.root)
	draw()
	table.insert(unbind, State.on("inv", draw))
end

-- a change of look builds what's open again in the new one (a row's shading is made for a look)
Kit.onTheme(function()
	if panel then
		draw()
	end
end)

return ShopPanel
