-- What a wish bubble opens. The user: "clicking the bubble that appears above villagers when
-- they have a craving should show a popup what they want and allow the player to satisfy it
-- instead of their whole profile page". So a click on the bubble over a villager's head
-- (World/Wishes) brings up this small dialog (Kit.panel's Dialog kind) and not their page:
--   on the left, what they want on a card: the food they crave, big, in its own colour; the
--     face of the villager they'd like to meet; or a smile, when they want cheering up
--   on the right, their face and the wish in a plain line ("Mara would love a rice ball."),
--     how to help, and the one button that answers it: Buy for a craving, at Life.wishPrice
--     through the WishBuy remote (the talk card buys it the same way), Introduce for someone
--     to meet and Have a chat when they're down (the WishGrant remote, as their page does)
--   under it, how the coins stand (without enough the button is dim and says nothing to the
--     server), and a small button that opens their page in the Villagers menu, as the bubble
--     used to
-- It closes once the wish is answered, on its close button, when the wish goes some other way
-- (it faded, they moved out) and when another menu opens (Hud.open, Hud.closeAll).
--
-- The tutorial points at it: it is the child of the interface's ScreenGui named "WishPopup", and
-- the button that answers the wish is named "Buy" whatever the wish is.

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Remotes = require(Shared.Net.Remotes)
local Colors = require(Shared.Util.Colors)
local Text = require(Shared.Util.Text)
local Foods = require(Shared.Data.Foods)
local Life = require(Shared.Sim.Life)

local Kit = require(script.Parent.Kit)
local Icons = require(script.Parent.Icons)
local Toasts = require(script.Parent.Toasts)
local ModelPreview = require(script.Parent.ModelPreview)
local State = require(script.Parent.Parent.Controllers.State)

local WishPopup = {}

local T = Kit.Theme
local player = Players.LocalPlayer

local SIZE = UDim2.fromOffset(600, 322)
local TILE = 172 -- the card on the left, across
local COLUMN = TILE + 20 -- where the words start

local panel: any = nil
-- what is showing: { vid, kind, arg, food, price, short, action (the box the button and the note
-- sit in), button, note, serial }
local current: any = nil
local serial = 0 -- goes up whenever it opens or closes, so an answer meant for an old one stops
local busy = false -- waiting on the server
local listening = false

function WishPopup.isOpen(): boolean
	return panel ~= nil and panel.root.Parent ~= nil
end

function WishPopup.close()
	serial += 1
	current = nil
	busy = false
	if panel then
		Kit.closePanel(panel)
		panel = nil
	end
end

-- The town as Life reads it.
local function profileView(): any
	return { villagers = State.data.villagers or {}, coins = State.data.coins or 0, plan = State.plan }
end

-- Does something else have the screen: Build mode, the creator or an event being watched?
local function blocked(): boolean
	local BuildMode = require(script.Parent.Parent.Build.BuildMode) :: any
	if BuildMode.isActive() then
		return true
	end
	local EventCard = require(script.Parent.EventCard) :: any
	if EventCard.isPlaying() then
		return true
	end
	local creator = Kit.root():FindFirstChild("Creator")
	return creator ~= nil and creator:IsA("GuiObject") and creator.Visible
end

-- A villager's model: in the player's own plot, or asked of the server.
local function modelOf(vid: string): Model?
	local index = player:GetAttribute("Plot")
	local plots = workspace:FindFirstChild("Plots")
	local plot = plots and index and plots:FindFirstChild("Plot" .. tostring(index))
	local folder = plot and plot:FindFirstChild("Villagers")
	if folder then
		for _, m in folder:GetChildren() do
			if m:IsA("Model") and m:GetAttribute("Vid") == vid then
				return m
			end
		end
	end
	local ok, found = pcall(function()
		return Remotes.fn("VillagerFocus"):InvokeServer(vid)
	end)
	return if ok and typeof(found) == "Instance" and found:IsA("Model") then found else nil
end

-- Their face in a round portrait, the ring in their colour.
local function face(vid: string, v: any, px: number, props: { [string]: any }): Frame
	local color = Colors.fromHex(v.color, T.Blue)
	local p = table.clone(props)
	p.Size = px
	p.Color = color:Lerp(T.Cream, 0.5)
	p.Border = color
	p.BorderWidth = if px > 80 then 3 else 2.5
	local ring = Kit.portrait(p)
	task.spawn(function()
		local model = modelOf(vid)
		if model and ring.Parent then
			local vp = ModelPreview.fromModel(model, { Parent = ring, Face = true })
			if vp then
				Kit.rounded(vp)
			end
		end
	end)
	return ring
end

-- The wish in words: the line, how to help, the button's words.
local function words(v: any, kind: string, food: any, other: any): (string, string, string)
	if kind == "food" then
		local line = Text.fill("{x} would love {food}.", { x = v.name, food = Foods.phrase(food) })
		local how = if food.id == v.fav then "Their favourite food." else "Buy it for them."
		return line, how, ""
	elseif kind == "friend" then
		local line = Text.fill("{x} would like to get to know {y}.", { x = v.name, y = other.name })
		return line, "Introduce them.", "Introduce"
	end
	return Text.fill("{x} feels a bit down.", { x = v.name }), "A chat would help.", "Have a chat"
end

-- The card on the left: what they want, big, with its name under it.
local function wanted(body: Frame, v: any, kind: string, food: any, other: any)
	local tile = Kit.frame({
		Name = "Wanted",
		Parent = body,
		Size = UDim2.fromOffset(TILE, 214),
		Color = T.Card,
		Radius = 16,
	})
	Kit.mark(tile)
	local name, accent
	if food then
		local color = Colors.fromHex(food.color, T.Orange)
		Kit.halo(tile, 150, color, 0.22)
		Icons.item(food.id, 120, color, {
			Name = "Craving",
			Parent = tile,
			Position = UDim2.new(0.5, 0, 0, 22),
			AnchorPoint = Vector2.new(0.5, 0),
			ZIndex = 2,
			Centre = true,
		})
		name, accent = food.name, color
	elseif other then
		face(v.wish.arg, other, 112, {
			Name = "Other",
			Parent = tile,
			Position = UDim2.new(0.5, 0, 0, 26),
			AnchorPoint = Vector2.new(0.5, 0),
			ZIndex = 2,
		})
		name, accent = other.name, Colors.fromHex(other.color, T.Blue)
	else
		Kit.halo(tile, 150, T.Orange, 0.2)
		Icons.make("smile", 104, {
			Name = "Cheer",
			Parent = tile,
			Position = UDim2.new(0.5, 0, 0, 30),
			AnchorPoint = Vector2.new(0.5, 0),
			Color = T.Orange,
			Hole = T.Card,
			ZIndex = 2,
			Centre = true,
		})
		name, accent = "A chat", T.Orange
	end
	Kit.title(name, {
		Name = "Thing",
		Parent = tile,
		Size = UDim2.new(1, -20, 0, 26),
		Position = UDim2.new(0.5, 0, 1, -22),
		AnchorPoint = Vector2.new(0.5, 1),
		TextSize = 19,
		AlignX = Enum.TextXAlignment.Center,
		Color = T.Ink,
		ZIndex = 2,
	})
	-- a short stroke of its colour over the name
	Kit.new("Frame", {
		Name = "Stroke",
		BackgroundColor3 = accent,
		BorderSizePixel = 0,
		Size = UDim2.fromOffset(28, 3),
		Position = UDim2.new(0.5, 0, 1, -54),
		AnchorPoint = Vector2.new(0.5, 0),
		ZIndex = 2,
		Parent = tile,
	}):SetAttribute("KeepColors", true)
	if kind == "food" then
		tile:SetAttribute("Food", food.id)
	end
end

local answer: (number) -> ()

-- The button that answers the wish and the line under it. A craving's says what it costs and is
-- dim without the coins; it is built again when that changes.
local function paintAction(c: any)
	local short = 0
	if c.kind == "food" then
		local price = Life.wishPrice(profileView(), c.vid)
		if not price then
			return
		end
		short = math.max(0, price - (State.data.coins or 0))
		if c.button and c.price == price and (c.short > 0) == (short > 0) then
			-- only the count moved
			c.short = short
			c.note.Text = if short > 0
				then Text.fill("You need {n} more coins.", { n = Text.commas(short) })
				else Text.fill("You have {n} coins.", { n = Text.commas(State.data.coins or 0) })
			return
		end
		c.price = price
	end
	c.short = short
	for _, child in c.action:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
	local food = c.kind == "food"
	local label = if food then Text.fill("Buy for {n}", { n = Text.commas(c.price) }) else c.label
	local mine = c.serial
	c.button = Kit.button(label, {
		Name = "Buy",
		Parent = c.action,
		Size = UDim2.fromOffset(if food then 190 else 170, 46),
		Color = if short > 0 then T.PaperDark elseif food then T.Green else T.Orange,
		TextColor = if short > 0 then T.InkSoft else T.White,
		TextSize = 19,
		Icon = if food then "coin" else nil,
		ZIndex = 2,
	}, function()
		answer(mine)
	end)
	c.button:SetAttribute("Disabled", short > 0)
	c.button:SetAttribute("Kind", c.kind)
	local noteText
	if short > 0 then
		noteText = Text.fill("You need {n} more coins.", { n = Text.commas(short) })
	elseif food then
		noteText = Text.fill("You have {n} coins.", { n = Text.commas(State.data.coins or 0) })
	else
		noteText = "They'll tip you a few coins."
	end
	c.note = Kit.text(noteText, {
		Name = "Note",
		Parent = c.action,
		Size = UDim2.new(1, 0, 0, 22),
		Position = UDim2.fromOffset(0, 60),
		TextSize = 15,
		Wrap = false,
		Color = if short > 0 then nil else T.InkSoft,
		Tint = if short > 0 then T.Coral else nil,
		ZIndex = 2,
	})
	c.note.TextTruncate = Enum.TextTruncate.AtEnd
end

-- The button pressed: buys the craving, or answers the wish, on the server.
answer = function(mine: number)
	local c = current
	if not c or c.serial ~= mine or busy then
		return
	end
	if c.kind == "food" and c.short > 0 then
		-- (nothing goes to the server: the line under the button already says how many more)
		c.note.Text = Text.fill("You need {n} more coins.", { n = Text.commas(c.short) })
		Kit.bump(c.note)
		return
	end
	busy = true
	local vid, kind, arg, food, price = c.vid, c.kind, c.arg, c.food, c.price
	local v = State.villager(vid)
	local name = if v then v.name else ""
	task.spawn(function()
		local sent, ok, msg = pcall(function()
			if kind == "food" then
				return Remotes.fn("WishBuy"):InvokeServer(vid)
			elseif kind == "friend" then
				return Remotes.fn("WishGrant"):InvokeServer(vid, "friend", arg)
			end
			return Remotes.fn("WishGrant"):InvokeServer(vid, "cheer")
		end)
		if serial == mine then
			busy = false
		end
		if sent and ok then
			-- answered: the server tells how pleased they are and they say so over their head;
			-- a craving also says what it cost
			if kind == "food" and food then
				Toasts.show(
					if type(msg) == "string" and msg ~= ""
						then msg
						else Text.fill("You bought {x} {food} for {n} coins.", {
							x = name,
							food = Foods.phrase(food),
							n = Text.commas(price or 0),
						}),
					"good"
				)
			end
			if serial == mine then
				WishPopup.close()
			end
		elseif serial == mine and current then
			local why = if sent and type(msg) == "string" and msg ~= "" then msg else "That didn't work. Try again."
			current.note.Text = why
			current.note.TextColor3 = Kit.tint(T.Coral)
			current.note:SetAttribute("Tint", T.Coral:ToHex())
		end
	end)
end

-- Keeps it true to the town: it goes when the wish does, and a craving's button follows the coins.
local function listen()
	if listening then
		return
	end
	listening = true
	State.on("villagers", function()
		local c = current
		if not c then
			return
		end
		local v = State.villager(c.vid)
		local w = v and v.wish
		if type(w) ~= "table" or w.kind ~= c.kind or w.arg ~= c.arg then
			WishPopup.close()
		elseif c.kind == "friend" and not State.villager(c.arg) then
			WishPopup.close()
		end
	end)
	State.on("coins", function()
		local c = current
		if c and c.kind == "food" and c.action.Parent then
			paintAction(c)
		end
	end)
end

-- Opens the popup for villager `vid`'s wish. Nothing opens when they have none (or Build mode,
-- the creator or an event has the screen).
function WishPopup.open(vid: any)
	if type(vid) ~= "string" then
		return
	end
	local v = State.villager(vid)
	local w = v and v.wish
	if type(w) ~= "table" or blocked() then
		return
	end
	local kind = w.kind
	local food = if kind == "food" then Foods.get(w.arg) else nil
	local other = if kind == "friend" and type(w.arg) == "string" then State.villager(w.arg) else nil
	if (kind == "food" and not food) or (kind == "friend" and not other) or not (food or other or kind == "cheer") then
		return
	end
	listen()
	WishPopup.close()
	serial += 1
	local accent = if food then T.Yellow else T.Orange
	local p = Kit.panel(Text.fill("{x}'s wish", { x = v.name }), SIZE, WishPopup.close, nil, accent, { Dialog = true })
	p.root.Name = "WishPopup"
	panel = p
	local body: Frame = p.body
	local line, how, label = words(v, kind, food, other)
	wanted(body, v, kind, food, other)
	-- who wants it, and what
	local who = Kit.box({
		Name = "Who",
		Parent = body,
		Size = UDim2.new(1, -COLUMN, 0, 112),
		Position = UDim2.fromOffset(COLUMN, 0),
	})
	Kit.mark(who)
	face(vid, v, 64, { Name = "Face", Parent = who, Position = UDim2.fromOffset(0, 2), ZIndex = 2 })
	Kit.title(line, {
		Name = "Line",
		Parent = who,
		Size = UDim2.new(1, -80, 0, 68),
		Position = UDim2.fromOffset(80, 0),
		TextSize = 21,
		Color = T.Ink,
		ZIndex = 2,
	})
	Kit.text(how, {
		Name = "How",
		Parent = who,
		Size = UDim2.new(1, 0, 0, 38),
		Position = UDim2.fromOffset(0, 74),
		TextSize = 16,
		Color = T.InkSoft,
		AlignY = Enum.TextYAlignment.Top,
		ZIndex = 2,
	})
	-- the button that answers it, and the line under it
	local action = Kit.box({
		Name = "Action",
		Parent = body,
		Size = UDim2.new(1, -COLUMN, 0, 86),
		Position = UDim2.new(0, COLUMN, 1, -86),
	})
	Kit.mark(action)
	current = {
		vid = vid,
		kind = kind,
		arg = w.arg,
		food = food,
		label = label,
		action = action,
		serial = serial,
		short = 0,
	}
	paintAction(current)
	-- their page, as the bubble used to open, level with the button
	Kit.button("See their page", {
		Name = "Page",
		Parent = body,
		Size = UDim2.fromOffset(140, 34),
		Position = UDim2.new(1, 0, 1, -86 + 23),
		AnchorPoint = Vector2.new(1, 0.5),
		Color = T.Card,
		TextColor = T.Ink,
		TextSize = 15,
		ZIndex = 2,
	}, function()
		WishPopup.close()
		local Hud = require(script.Parent.Hud) :: any
		Hud.open("Residents", vid)
	end)
end

return WishPopup
