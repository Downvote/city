-- The garage: every vehicle there is, to buy and to drive. The user: "make vehicles, with faster
-- ones with bigger capacities costing more, and gem ones being the fastest". A full menu (Kit.panel):
-- the card at the left shows the one out now and puts it away; down the right, a row for each
-- vehicle with its speed and seats, and Buy (in coins or gems) or Drive. Services/Vehicles does the
-- buying and the bringing out.

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Remotes = require(Shared.Net.Remotes)
local Text = require(Shared.Util.Text)
local VehicleData = require(Shared.Data.Vehicles)
local SimVehicles = require(Shared.Sim.Vehicles)

local Kit = require(script.Parent.Kit)
local MenuParts = require(script.Parent.MenuParts)
local Toasts = require(script.Parent.Toasts)
local State = require(script.Parent.Parent.Controllers.State)

local Garage = {}

local T = Kit.Theme
local panel: any = nil
local unbind: { () -> () } = {}
local busy = false

-- What a vehicle's row says under its name.
function Garage.line(v: VehicleData.Vehicle): string
	local seats = if v.seats == 1 then "1 seat" else Text.fill("{n} seats", { n = v.seats })
	return Text.fill("Top speed {s}, {seats}", { s = v.speed, seats = seats })
end

-- Its price, as a button says it.
function Garage.price(v: VehicleData.Vehicle): string
	if v.gems then
		return Text.fill("{n} gems", { n = Text.commas(v.gems) })
	end
	return Text.fill("{n} coins", { n = Text.commas(v.coins or 0) })
end

local draw: () -> ()

local function ask(name: string, id: string?, done: string?)
	if busy then
		return
	end
	busy = true
	task.spawn(function()
		local ok, a, b = pcall(function()
			return Remotes.fn(name):InvokeServer(id)
		end)
		busy = false
		if ok and a then
			if done then
				Toasts.show(done, "good")
			end
		else
			Toasts.show(if ok and type(b) == "string" then b else "That didn't go through.", "warn")
		end
		draw()
	end)
end

draw = function()
	if not panel then
		return
	end
	for _, c in panel.body:GetChildren() do
		c:Destroy()
	end
	local profile = State.data
	local outId = Players.LocalPlayer:GetAttribute("VehicleOut")
	local current = VehicleData.get(outId)

	-- the card: the one out now
	local _, inside = MenuParts.card(panel.body, T.Orange)
	Kit.title(if current then current.name else "Nothing out", {
		Name = "OutName",
		Parent = inside,
		Size = UDim2.new(1, 0, 0, 40),
		TextSize = 32,
		Wrap = false,
	})
	Kit.text(
		if current
			then Text.fill("{line}. Sit at the wheel to drive, W and S for the pedal, A and D to turn.", {
				line = Garage.line(current),
			})
			else "Pick one on the right and press Drive, and it waits in front of you.",
		{
			Name = "OutLine",
			Parent = inside,
			Size = UDim2.new(1, 0, 0, 60),
			Position = UDim2.fromOffset(0, 44),
			TextSize = 15,
			Color = T.InkSoft,
		}
	)
	if current then
		Kit.button("Put it away", {
			Name = "PutAway",
			Parent = inside,
			Size = UDim2.fromOffset(180, 44),
			Position = UDim2.fromOffset(0, 112),
			Color = T.Coral,
			TextSize = 17,
		}, function()
			ask("VehicleAway", nil, nil)
		end)
	end

	-- the rows: coins first, cheapest to dearest, then the gem ones
	local list = MenuParts.list(panel.body)
	local order = 0
	local function section(title: string, color: Color3, gems: boolean)
		order += 1
		MenuParts.heading(list, title, color, order)
		for _, v in VehicleData.list do
			if (v.gems ~= nil) == gems then
				order += 1
				local owned = SimVehicles.owns(profile, v.id)
				local _, inner = Kit.row({
					Name = v.name,
					Parent = list,
					Size = MenuParts.rowSize(60),
					Height = 60,
					LayoutOrder = order,
					Title = v.name,
					Sub = Garage.line(v),
					Marker = "car",
					MarkerColor = Color3.fromHex(v.color),
					RightSpace = 170,
				})
				local label = if owned
					then (if outId == v.id then "Out now" else "Drive")
					else Text.fill("Buy for {p}", { p = Garage.price(v) })
				local b = Kit.button(label, {
					Name = if owned then "Drive" else "Buy",
					Parent = inner,
					Size = UDim2.fromOffset(160, 38),
					Position = UDim2.new(1, -166, 0.5, -19),
					Color = if owned then T.Blue elseif v.gems then T.Purple else T.Green,
					TextSize = 15,
				}, function()
					if owned then
						if outId ~= v.id then
							ask("VehicleOut", v.id, nil)
						end
					else
						ask("VehicleBuy", v.id, Text.fill("The {name} is yours.", { name = string.lower(v.name) }))
					end
				end)
				b:SetAttribute("Vehicle", v.id)
			end
		end
	end
	section("For coins", T.Orange, false)
	section("For gems, the fastest", T.Purple, true)
end

function Garage.isOpen(): boolean
	return panel ~= nil
end

function Garage.close()
	for _, u in unbind do
		u()
	end
	unbind = {}
	if panel then
		Kit.closePanel(panel)
		panel = nil
	end
end

function Garage.open()
	Garage.close()
	panel = Kit.panel("Garage", Kit.MenuSize, Garage.close, "car", T.Orange, { Caption = "Cars to buy and drive" })
	draw()
	table.insert(unbind, State.on("vehicles", draw))
	table.insert(unbind, State.on("coins", draw))
	table.insert(unbind, State.on("gems", draw))
	local conn = Players.LocalPlayer:GetAttributeChangedSignal("VehicleOut"):Connect(draw)
	table.insert(unbind, function()
		conn:Disconnect()
	end)
end

Kit.onTheme(function()
	if panel then
		draw()
	end
end)

return Garage
