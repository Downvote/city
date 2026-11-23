-- The plaza shop: food for villagers, medicine and party cakes.

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Remotes = require(Shared.Net.Remotes)
local Foods = require(Shared.Data.Foods)
local Items = require(Shared.Data.Items)
local Tuning = require(Shared.Config.Tuning)
local Colors = require(Shared.Util.Colors)
local Text = require(Shared.Util.Text)

local Kit = require(script.Parent.Kit)
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

local function card(
	parent: Instance,
	name: string,
	sub: string,
	color: Color3,
	cost: number,
	have: number,
	kind: string,
	id: string,
	order: number
)
	local c = Kit.frame({
		Parent = parent,
		Size = UDim2.new(1, -8, 0, 60),
		Color = T.White,
		Stroke = T.Ink,
		StrokeThickness = 2,
		LayoutOrder = order,
	})
	Kit.pad(c, 10, 6)
	Kit.frame({
		Parent = c,
		Size = UDim2.fromOffset(40, 40),
		Position = UDim2.fromOffset(0, 4),
		Color = color,
		Radius = 20,
	})
	Kit.text(name, {
		Parent = c,
		Size = UDim2.new(1, -240, 0, 22),
		Position = UDim2.fromOffset(50, 2),
		TextSize = 17,
		Font = Kit.Fonts.Bold,
	})
	Kit.text(Text.fill("{sub} You have {n}.", { sub = sub, n = have }), {
		Parent = c,
		Size = UDim2.new(1, -240, 0, 22),
		Position = UDim2.fromOffset(50, 24),
		TextSize = 13,
		Color = T.InkSoft,
	})
	Kit.button(Text.commas(cost), {
		Parent = c,
		Size = UDim2.fromOffset(84, 40),
		Position = UDim2.new(1, -176, 0, 4),
		Color = T.Green,
		TextSize = 16,
	}, function()
		buy(kind, id, 1)
	end)
	Kit.button("x5", {
		Parent = c,
		Size = UDim2.fromOffset(80, 40),
		Position = UDim2.new(1, -84, 0, 4),
		Color = T.Blue,
		TextSize = 16,
	}, function()
		buy(kind, id, 5)
	end)
end

local function draw()
	if not panel then
		return
	end
	for _, c in panel.body:GetChildren() do
		c:Destroy()
	end
	local scroll = Kit.scroll({ Parent = panel.body, Size = UDim2.fromScale(1, 1) })
	Kit.list(scroll, 6)
	if sale() then
		Kit.text("A travelling merchant is in town. Everything's cheaper for a little while.", {
			Parent = scroll,
			TextSize = 16,
			Color = T.GreenDark,
			Font = Kit.Fonts.Bold,
			LayoutOrder = 0,
			Size = UDim2.new(1, 0, 0, 24),
		})
	end
	local inv = State.data.inv or { food = {}, items = {} }
	local order = 1
	Kit.title("Things", { Parent = scroll, TextSize = 20, LayoutOrder = order })
	for _, item in Items.list do
		order += 1
		card(
			scroll,
			item.name,
			item.blurb,
			if item.id == "cake" then T.Coral else T.Blue,
			price(item.price),
			inv.items[item.id] or 0,
			"item",
			item.id,
			order
		)
	end
	order += 1
	Kit.title("Food", { Parent = scroll, TextSize = 20, LayoutOrder = order })
	for _, f in Foods.shop() do
		order += 1
		card(
			scroll,
			f.name,
			"Cheers someone up.",
			Colors.fromHex(f.color),
			price(f.price :: number),
			inv.food[f.id] or 0,
			"food",
			f.id,
			order
		)
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
	panel = Kit.panel("Shop", UDim2.fromOffset(620, 560), ShopPanel.close, "cart", Kit.Theme.Orange)
	Kit.popIn(panel.root)
	draw()
	table.insert(unbind, State.on("inv", draw))
end

return ShopPanel
