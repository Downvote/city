-- Crates in the Store, and opening one (the user: "add work crates that can be bought with gems or
-- robux, which give exclusive work spaces which are unique to crates, giving a random one ..."; the
-- work crate is the only kind: "remove pets. the only crate should be work crates"). The Store's
-- Crates tab (Crates.show) has a card for each kind: its picture, how many are waiting to be
-- opened, what is inside by rarity with each one's chance (shown before buying), and Open, the gem
-- price and the Robux price. Opening (the CrateOpen remote:
-- Services/Crates decides everything) brings up a small dialog: the crate shakes and pops, and what
-- came out stands in its place with its rarity and where to find it (Crates.reveal).
-- Crates.tip is the scene a villager pops up in when the player first has the gems for a crate (the
-- CrateTip event: "A random villager will pop up and tell the player about these crates right when
-- they have enough gems").
-- Scenes: panel:Store:crates, crate:open:work, crate:tip.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Tuning = require(Shared.Config.Tuning)
local Remotes = require(Shared.Net.Remotes)
local CrateData = require(Shared.Data.Crates)
local PassData = require(Shared.Data.Passes)
local Catalog = require(Shared.Build.Catalog)
local SimCrates = require(Shared.Sim.Crates)
local Colors = require(Shared.Util.Colors)
local Text = require(Shared.Util.Text)

local Kit = require(script.Parent.Kit)
local ModelPreview = require(script.Parent.ModelPreview)
local Toasts = require(script.Parent.Toasts)
local State = require(script.Parent.Parent.Controllers.State)
local Purchase = require(script.Parent.Parent.Controllers.Purchase)

local Crates = {}

local T = Kit.Theme
local reveal: any = nil
local opening = false

-- A rarity's colour, from the look.
function Crates.tone(rarity: string?): Color3
	local key = rarity and CrateData.Tones[rarity]
	local c = key and (T :: any)[key]
	return if typeof(c) == "Color3" then c else T.Blue
end

local function accentOf(_kind: string): Color3
	return T.Orange
end

-- Asks the server to open one: held ("held") or bought with gems ("gems"). What came out is shown.
function Crates.open(kind: string, how: string)
	if opening then
		return
	end
	opening = true
	task.spawn(function()
		local ok, done, result = pcall(function()
			return Remotes.fn("CrateOpen"):InvokeServer(kind, how)
		end)
		opening = false
		if not ok then
			Toasts.show("That didn't work. Try again.", "warn")
			return
		end
		if done ~= true then
			if type(result) == "string" then
				Toasts.show(result, "info")
			end
			return
		end
		Crates.reveal(result)
	end)
end

-- A card for one kind of crate on the Store's Crates tab. `helpers` are the Store's own: `tag`, a
-- small leaning tag of words, and `price`, a Robux price as it writes it.
local function card(parent: Instance, kind: string, order: number, w: number, h: number, helpers: any)
	local def = CrateData.get(kind) :: CrateData.Kind
	local accent = accentOf(kind)
	local held = SimCrates.held(State.data, kind)
	local f = Kit.frame({
		Name = kind,
		Parent = parent,
		Size = UDim2.fromOffset(w, h),
		LayoutOrder = order,
		Color = T.Paper,
		Cut = 14,
	})
	Kit.glow(f, accent, 0.2, "tr")
	Kit.mark(f)
	-- the crate itself
	local pic = Kit.frame({
		Name = "Picture",
		Parent = f,
		Size = UDim2.fromOffset(170, 150),
		Position = UDim2.fromOffset(16, 16),
		Color = T.Picture,
		Radius = 14,
	})
	pic.ZIndex = 2
	task.spawn(function()
		local vp = ModelPreview.fromPrims(CrateData.prims(kind), { Parent = pic })
		vp.ZIndex = 3
	end)
	Kit.title(def.name, {
		Name = "CrateName",
		Parent = f,
		Size = UDim2.new(1, -220, 0, 32),
		Position = UDim2.fromOffset(204, 18),
		TextSize = 26,
		Color = T.Ink,
		Wrap = false,
		ZIndex = 2,
	})
	-- (room for two lines: the blurb wraps)
	Kit.text(def.blurb, {
		Name = "Blurb",
		Parent = f,
		Size = UDim2.new(1, -220, 0, 42),
		Position = UDim2.fromOffset(204, 52),
		AlignY = Enum.TextYAlignment.Top,
		TextSize = 16,
		Color = T.InkSoft,
		ZIndex = 2,
	})
	if held > 0 then
		helpers.tag("gift", Text.fill("{n} to open", { n = held }), {
			Name = "Held",
			Parent = f,
			Height = 32,
			Position = UDim2.fromOffset(214, 104),
			Color = T.Yellow,
			TextColor = T.Dark,
			TextSize = 16,
		})
	end
	-- what is inside, rarest last, with the chance of each rarity
	local odds = Kit.box({
		Name = "Odds",
		Parent = f,
		Size = UDim2.new(1, -32, 0, h - 260),
		Position = UDim2.fromOffset(16, 180),
	})
	odds.ZIndex = 2
	Kit.list(odds, 4)
	for i, o in CrateData.odds(kind) do
		local row = Kit.box({ Name = o.rarity, Parent = odds, Size = UDim2.new(1, 0, 0, 44), LayoutOrder = i })
		row.ZIndex = 2
		local tone = Crates.tone(o.rarity)
		Kit.disc({
			Name = "Dot",
			Parent = row,
			Size = 12,
			Position = UDim2.fromOffset(2, 6),
			Color = tone,
			Ring = false,
		})
		Kit.title(CrateData.RarityNames[o.rarity] or o.rarity, {
			Name = "Rarity",
			Parent = row,
			Size = UDim2.new(0.5, -24, 0, 22),
			Position = UDim2.fromOffset(22, 0),
			TextSize = 17,
			Tint = tone,
			Wrap = false,
			ZIndex = 2,
		})
		Kit.title(CrateData.percent(o.chance), {
			Name = "Chance",
			Parent = row,
			Size = UDim2.new(0.5, 0, 0, 22),
			Position = UDim2.fromScale(0.5, 0),
			TextSize = 17,
			Color = T.Ink,
			AlignX = Enum.TextXAlignment.Right,
			Wrap = false,
			ZIndex = 2,
		})
		local names = {}
		for _, e in o.entries do
			table.insert(names, e.name)
		end
		Kit.text(table.concat(names, ", "), {
			Name = "Inside",
			Parent = row,
			Size = UDim2.new(1, -22, 0, 20),
			Position = UDim2.fromOffset(22, 22),
			TextSize = 14,
			Color = T.InkSoft,
			Wrap = false,
			ZIndex = 2,
		})
	end
	-- at the foot: open one held, buy one with gems, buy one with Robux
	local foot =
		Kit.box({ Name = "Foot", Parent = f, Size = UDim2.new(1, -32, 0, 48), Position = UDim2.new(0, 16, 1, -64) })
	foot.ZIndex = 2
	Kit.list(foot, 10, true, Enum.HorizontalAlignment.Right)
	local price = Tuning.Crates.Price[kind] or 0
	local gems = if type(State.data.gems) == "number" then State.data.gems else 0
	if held > 0 then
		Kit.button("Open", {
			Name = "Open",
			Parent = foot,
			Size = UDim2.fromOffset(120, 46),
			Color = T.Yellow,
			TextColor = T.Dark,
			TextSize = 19,
			LayoutOrder = 1,
		}, function()
			Crates.open(kind, "held")
		end)
	end
	Kit.button(Text.commas(price), {
		Name = "BuyGems",
		Parent = foot,
		Size = UDim2.fromOffset(120, 46),
		Color = if gems >= price then T.Purple else T.Card,
		TextColor = if gems >= price then T.White else T.InkSoft,
		TextSize = 19,
		Icon = "gem",
		LayoutOrder = 2,
	}, function()
		if gems < price then
			Toasts.show(Text.fill("You need {n} more.", { n = Text.gems(price - gems) }), "info")
			return
		end
		Crates.open(kind, "gems")
	end)
	local product = PassData.crateProduct(def.product)
	local onSale = product ~= nil and product.id ~= 0
	Kit.button(if onSale and product then helpers.price(product.price) else "Soon", {
		Name = "BuyRobux",
		Parent = foot,
		Size = UDim2.fromOffset(120, 46),
		Color = if onSale then T.Green else T.Card,
		TextColor = if onSale then T.Dark else T.InkSoft,
		TextSize = 19,
		LayoutOrder = 3,
	}, function()
		Purchase.crate(def.product)
	end)
end

-- The Store's Crates tab, in its body (1118 by 518).
function Crates.show(body: Frame, helpers: any)
	local row = Kit.box({ Name = "Crates", Parent = body, Size = UDim2.fromScale(1, 1) })
	local list = Kit.list(row, 16, true, Enum.HorizontalAlignment.Center)
	list.VerticalAlignment = Enum.VerticalAlignment.Center
	local w = 540
	for i, kind in CrateData.Order do
		card(row, kind, i, w, 510, helpers)
	end
end

-- Opening ------------------------------------------------------------------------------------------

function Crates.closeReveal()
	if reveal then
		Kit.closePanel(reveal)
		reveal = nil
	end
end

function Crates.isOpen(): boolean
	return reveal ~= nil
end

-- The prize's picture: the workplace.
local function prizePrims(result: any): { any }
	local def = Catalog.get(result.id)
	return if def then Catalog.prims(def) else {}
end

-- Where to find it, in a line.
local WHERE = "Free to put down in Build mode, under Work > Crate."

-- Shows a crate opening: it shakes, pops, and what came out stands in its place. `result` is
-- Sim/Crates.Result as the server sent it. `still` (the previews) shows the prize at once.
function Crates.reveal(result: any, still: boolean?)
	if type(result) ~= "table" or type(result.kind) ~= "string" then
		return
	end
	Crates.closeReveal()
	local def = CrateData.get(result.kind)
	Kit.sound("gift") -- (Controllers/Audio: the music box a gift plays)
	local p = Kit.panel(
		if def then def.name else "Crate",
		UDim2.fromOffset(560, 540),
		Crates.closeReveal,
		nil,
		accentOf(result.kind),
		{ Dialog = true }
	)
	p.root.Name = "CrateReveal"
	reveal = p
	local body: Frame = p.body
	local stage = Kit.frame({
		Name = "Stage",
		Parent = body,
		Size = UDim2.new(1, -40, 0, 210),
		Position = UDim2.fromOffset(20, 0),
		Color = T.Picture,
		Radius = 16,
	})
	Kit.glow(stage, Crates.tone(result.rarity), 0.3, "tr")
	local box = Kit.box({ Name = "Crate", Parent = stage, Size = UDim2.fromScale(1, 1) })
	local function prize()
		if reveal ~= p then
			return
		end
		box:Destroy()
		local holder = Kit.box({ Name = "Prize", Parent = stage, Size = UDim2.fromScale(1, 1) })
		ModelPreview.fromPrims(prizePrims(result), { Parent = holder })
		local tone = Crates.tone(result.rarity)
		local tag = Kit.frame({
			Name = "Rarity",
			Parent = body,
			Size = UDim2.fromOffset(150, 30),
			Position = UDim2.new(0.5, 0, 0, 222),
			AnchorPoint = Vector2.new(0.5, 0),
			Color = tone,
			Radius = false,
		})
		Kit.slant(tag, 30, true)
		local light = tone.R * 0.3 + tone.G * 0.59 + tone.B * 0.11 > 0.5
		local words = Kit.title(CrateData.RarityNames[result.rarity] or "", {
			Name = "Words",
			Parent = tag,
			Size = UDim2.fromScale(1, 1),
			TextSize = 17,
			Color = if light then T.Dark else T.White,
			AlignX = Enum.TextXAlignment.Center,
			Wrap = false,
		})
		words.ZIndex = 3
		Kit.title(result.name, {
			Name = "PrizeName",
			Parent = body,
			Size = UDim2.new(1, -40, 0, 34),
			Position = UDim2.fromOffset(20, 260),
			TextSize = 28,
			Color = T.Ink,
			AlignX = Enum.TextXAlignment.Center,
			Wrap = false,
		})
		Kit.text(WHERE, {
			Name = "Where",
			Parent = body,
			Size = UDim2.new(1, -60, 0, 44),
			Position = UDim2.fromOffset(30, 298),
			TextSize = 16,
			Color = T.InkSoft,
			AlignX = Enum.TextXAlignment.Center,
			AlignY = Enum.TextYAlignment.Top,
		})
		Kit.button("OK", {
			Name = "OK",
			Parent = body,
			Size = UDim2.fromOffset(180, 48),
			Position = UDim2.new(0.5, 0, 1, -4),
			AnchorPoint = Vector2.new(0.5, 1),
			Color = T.Green,
			TextColor = T.Dark,
			TextSize = 20,
		}, Crates.closeReveal)
	end
	if still then
		prize()
		return
	end
	-- the crate, rocking harder and harder, then gone
	local vp = ModelPreview.fromPrims(CrateData.prims(result.kind), { Parent = box })
	task.spawn(function()
		for k = 1, 8 do
			if reveal ~= p then
				return
			end
			box.Rotation = (if k % 2 == 0 then -1 else 1) * (2 + k)
			task.wait(0.1)
		end
		box.Rotation = 0
		vp.ImageTransparency = 0.5
		task.wait(0.1)
		prize()
	end)
end

-- The tip ------------------------------------------------------------------------------------------

-- A villager pops up to say the player can afford a crate now: their bust and their line, with Show
-- me (the Store's Crates tab) and Later. It waits for the screen to be free (no menu, no scene, not
-- Build mode) for up to a minute and a half.
function Crates.tip(msg: any)
	if type(msg) ~= "table" or type(msg.vid) ~= "string" or type(msg.text) ~= "string" then
		return
	end
	task.spawn(function()
		local Dialogue = require(script.Parent.Dialogue) :: any
		local Hud = require(script.Parent.Hud) :: any
		local EventCard = require(script.Parent.EventCard) :: any
		local BuildMode = require(script.Parent.Parent.Build.BuildMode) :: any
		local t = os.clock()
		while os.clock() - t < 90 do
			local busy = Dialogue.isOpen()
				or (Hud.anyOpen and Hud.anyOpen())
				or (BuildMode.isActive and BuildMode.isActive())
				or (EventCard.isWatching and EventCard.isWatching())
			if not busy then
				break
			end
			task.wait(1)
		end
		local v = State.villager(msg.vid)
		if not v then
			return
		end
		local s = Dialogue.open({ Name = "CrateTip" })
		s.join({
			key = msg.vid,
			name = v.name,
			color = Colors.fromHex(v.color, T.Blue),
			model = Dialogue.modelOf(msg.vid),
			vid = msg.vid,
		})
		s.speak(msg.vid)
		s.type(msg.text)
		Dialogue.answer(
			"Show me",
			{ Name = "ShowMe", Parent = s.tools, Size = UDim2.fromOffset(130, 34), LayoutOrder = 1, TextSize = 16 },
			function()
				s.close()
				Hud.open("Store", "crates")
			end
		)
		Dialogue.answer(
			"Later",
			{ Name = "Later", Parent = s.tools, Size = UDim2.fromOffset(110, 34), LayoutOrder = 2, TextSize = 16 },
			function()
				s.close()
			end
		)
	end)
end

function Crates.start()
	Remotes.event("CrateTip").OnClientEvent:Connect(Crates.tip)
end

-- a change of look builds an open reveal again (its words and slabs)
Kit.onTheme(function()
	if reveal then
		Crates.closeReveal()
	end
end)

return Crates
