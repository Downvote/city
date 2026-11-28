-- Crates in the Store, and opening one (the user: "add work crates that can be bought with gems or
-- robux, which give exclusive work spaces which are unique to crates, giving a random one ...", then
-- "Add pet crates as well"; for a while pets went, then "never mind, keep pets in the game"). The
-- Store's Crates tab (Crates.show) has a card for each kind: its picture, how many are waiting to
-- be opened, what is inside by rarity with each one's chance (shown before buying), and Open, the
-- gem price and the Robux price. Opening (the CrateOpen remote:
-- Services/Crates decides everything) plays the opening over the whole screen (Crates.reveal): the
-- crate drops in, shakes while the light climbs the rarities, bursts, and what came out rises in its
-- place with its rarity and where to find it.
-- Crates.tip is the scene a villager pops up in when the player first has the gems for a crate (the
-- CrateTip event: "A random villager will pop up and tell the player about these crates right when
-- they have enough gems").
-- Scenes: panel:Store:crates, crate:open:<work|pet>[:<rarity>][:drop|:shake|:burst], crate:tip.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Tuning = require(Shared.Config.Tuning)
local Remotes = require(Shared.Net.Remotes)
local CrateData = require(Shared.Data.Crates)
local PetData = require(Shared.Data.Pets)
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

local function accentOf(kind: string): Color3
	return if kind == "pet" then T.Teal else T.Orange
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

function Crates.isOpen(): boolean
	return reveal ~= nil
end

-- The prize's picture: the workplace, or the pet in its coat.
local function prizePrims(result: any): { any }
	if result.kind == "pet" then
		return PetData.prims(result.id, result.coat)
	end
	local def = Catalog.get(result.id)
	return if def then Catalog.prims(def) else {}
end

-- Where to find it, in a line.
local function whereLine(result: any): string
	if result.kind == "pet" then
		return Text.fill("{name} lives in town now. Give them an owner from a villager's page.", {
			name = result.petName or "Your pet",
		})
	end
	return "Free to put down in Build mode, under Work > Crate."
end

-- What it is called: a pet by its name and kind.
local function prizeName(result: any): string
	if result.kind == "pet" and type(result.petName) == "string" then
		return Text.fill("{name} the {kind}", { name = result.petName, kind = string.lower(result.name or "") })
	end
	return result.name or ""
end

-- Opening a crate (the user: "make the opening crate cutscene much more dramatic"). The screen goes
-- dark (all of it: the sunburst fades into that dark at its rim) and the crate drops into the middle with a thud. It rocks, harder and faster, while light
-- gathers behind it and rays turn; the light starts at Common's colour and steps up through the
-- rarities to the prize's own, flaring at each step, so a rarer prize shakes longer and climbs
-- further. Then a flash, a ring and sparks, and the prize rises out of the light, turning, with its
-- rarity, its name and where to find it. A press while it shakes skips to the burst. The beats'
-- lengths are Tuning.Crates.Show. `still` (the previews) shows one beat as it stands: "drop" (the
-- crate landing), "shake" (late in its shaking), "burst" or "prize" (true is "prize").

local Show = Tuning.Crates.Show
local RunService = game:GetService("RunService")

local Z = { dim = 0, rays = 2, halo = 3, ring = 4, crate = 6, spark = 7, info = 8, flash = 10, skip = 12 }

local function round(f: GuiObject)
	Kit.new("UICorner", { CornerRadius = UDim.new(0.5, 0), Parent = f })
end

-- Turning rays round the middle: a sunburst (a circle in the prize's colour, its wedges cut by a
-- conical fade) that fades into the dark at its rim; bars through the middle where the game can't
-- shape a gradient.
local function rays(parent: GuiObject, tone: Color3, size: number): Frame
	local holder = Kit.box({
		Name = "Rays",
		Parent = parent,
		Size = UDim2.fromOffset(size, size),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
	})
	holder.ZIndex = Z.rays
	local burst = Kit.new("Frame", {
		Name = "Burst",
		BackgroundColor3 = tone,
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 1,
		Parent = holder,
	})
	round(burst)
	local wedges = Kit.shapedGradient(burst, "Conical")
	if wedges then
		local keys = {}
		for i = 0, 16 do
			table.insert(keys, NumberSequenceKeypoint.new(i / 16, if i % 2 == 0 then 0.45 else 1))
		end
		wedges.Transparency = NumberSequence.new(keys)
		local edge = Kit.new("Frame", {
			Name = "Edge",
			BackgroundColor3 = T.Black,
			BackgroundTransparency = 0,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 4, 1, 4),
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			ZIndex = 2,
			Parent = holder,
		})
		round(edge)
		local fade = Kit.shapedGradient(edge, "Radial")
		if fade then
			fade.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.3, 1),
				NumberSequenceKeypoint.new(1, 0),
			})
			return holder
		end
		edge:Destroy()
	end
	burst:Destroy()
	for i = 0, 7 do
		local bar = Kit.new("Frame", {
			Name = "Ray",
			BackgroundColor3 = tone,
			BackgroundTransparency = 0,
			BorderSizePixel = 0,
			Size = UDim2.new(0, if i % 2 == 0 then 46 else 26, 1, 0),
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Rotation = i * 22.5,
			ZIndex = 1,
			Parent = holder,
		})
		Kit.new("UIGradient", {
			Rotation = 90,
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.3, 0.8),
				NumberSequenceKeypoint.new(0.5, 0.6),
				NumberSequenceKeypoint.new(0.7, 0.8),
				NumberSequenceKeypoint.new(1, 1),
			}),
			Parent = bar,
		})
	end
	return holder
end

-- The rays' faces (the sunburst, or the bars).
local function rayFaces(holder: Instance): { Frame }
	local list = {}
	for _, r in holder:GetChildren() do
		if r:IsA("Frame") and (r.Name == "Burst" or r.Name == "Ray") then
			table.insert(list, r)
		end
	end
	return list
end

local function paintRays(holder: Instance, tone: Color3)
	for _, r in rayFaces(holder) do
		r.BackgroundColor3 = tone
	end
end

-- A ring that grows out of the middle and fades: a step up, and the burst.
local function ring(parent: GuiObject, tone: Color3, from: number, to: number, time: number, width: number)
	local f = Kit.new("Frame", {
		Name = "Ring",
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(from, from),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		ZIndex = Z.ring,
		Parent = parent,
	})
	round(f)
	local stroke = Kit.new("UIStroke", { Color = tone, Thickness = width, Transparency = 0.1, Parent = f })
	local info = TweenInfo.new(time, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	Kit.tween(f, info, { Size = UDim2.fromOffset(to, to) })
	Kit.tween(stroke, info, { Transparency = 1, Thickness = 1 })
	task.delay(time + 0.05, function()
		f:Destroy()
	end)
end

-- Sparks flying out of the middle in the prize's colour, white and yellow.
local function sparks(parent: GuiObject, tone: Color3, count: number, still: boolean)
	local rng = Random.new(7)
	local colours = { tone, tone, T.White, T.Yellow }
	for i = 1, count do
		local angle = (i / count) * math.pi * 2 + rng:NextNumber(-0.12, 0.12)
		local far = rng:NextNumber(170, 400)
		local size = rng:NextInteger(6, 14)
		local dot = Kit.new("Frame", {
			Name = "Spark",
			BackgroundColor3 = colours[rng:NextInteger(1, #colours)],
			BorderSizePixel = 0,
			Size = UDim2.fromOffset(size, size),
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			ZIndex = Z.spark,
			Parent = parent,
		})
		round(dot)
		local to = UDim2.new(0.5, math.cos(angle) * far, 0.5, math.sin(angle) * far)
		if still then
			dot.Position = UDim2.new(0.5, math.cos(angle) * far * 0.6, 0.5, math.sin(angle) * far * 0.6)
		else
			local time = rng:NextNumber(0.6, 0.95)
			Kit.tween(dot, TweenInfo.new(time, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Position = to })
			Kit.tween(
				dot,
				TweenInfo.new(time, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
				{ BackgroundTransparency = 1, Size = UDim2.fromOffset(2, 2) }
			)
			task.delay(time + 0.05, function()
				dot:Destroy()
			end)
		end
	end
end

-- Small glints round the prize that come and go while it is up (more for a rarer one).
local function glints(parent: GuiObject, tone: Color3, count: number, alive: () -> boolean, still: boolean)
	local rng = Random.new(11)
	for i = 1, count do
		local angle = (i / count) * math.pi * 2 + 0.4
		local far = rng:NextNumber(120, 170)
		local size = rng:NextInteger(5, 9)
		local dot = Kit.new("Frame", {
			Name = "Glint",
			BackgroundColor3 = if i % 2 == 0 then T.White else tone,
			BackgroundTransparency = if still then 0.2 else 1,
			BorderSizePixel = 0,
			Size = UDim2.fromOffset(size, size),
			Position = UDim2.new(0.5, math.cos(angle) * far, 0.5, math.sin(angle) * far * 0.8),
			AnchorPoint = Vector2.new(0.5, 0.5),
			ZIndex = Z.spark,
			Parent = parent,
		})
		round(dot)
		if not still then
			task.spawn(function()
				task.wait(rng:NextNumber(0, 1.2))
				while alive() do
					local beat = rng:NextNumber(0.5, 0.9)
					Kit.tween(dot, TweenInfo.new(beat, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						BackgroundTransparency = 0.1,
					})
					task.wait(beat)
					Kit.tween(dot, TweenInfo.new(beat, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
						BackgroundTransparency = 1,
					})
					task.wait(beat + rng:NextNumber(0.2, 1))
				end
			end)
		end
	end
end

-- The prize, its rarity, its name, where to find it and OK, under the light.
local function info(p: any, result: any, tone: Color3): CanvasGroup
	local group = Kit.new("CanvasGroup", {
		Name = "Info",
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(640, 230),
		Position = UDim2.new(0.5, 0, 0.4, 170),
		AnchorPoint = Vector2.new(0.5, 0),
		ZIndex = Z.info,
		Parent = p.root,
	})
	local tag = Kit.frame({
		Name = "Rarity",
		Parent = group,
		Size = UDim2.fromOffset(170, 32),
		Position = UDim2.new(0.5, 0, 0, 0),
		AnchorPoint = Vector2.new(0.5, 0),
		Color = tone,
		Radius = false,
	})
	Kit.slant(tag, 32, true)
	local light = tone.R * 0.3 + tone.G * 0.59 + tone.B * 0.11 > 0.5
	local words = Kit.title(CrateData.RarityNames[result.rarity] or "", {
		Name = "Words",
		Parent = tag,
		Size = UDim2.fromScale(1, 1),
		TextSize = 18,
		Color = if light then T.Dark else T.White,
		AlignX = Enum.TextXAlignment.Center,
		Wrap = false,
	})
	words.ZIndex = 3
	Kit.title(prizeName(result), {
		Name = "PrizeName",
		Parent = group,
		Size = UDim2.new(1, 0, 0, 40),
		Position = UDim2.fromOffset(0, 42),
		TextSize = 34,
		Color = T.Ink,
		AlignX = Enum.TextXAlignment.Center,
		Wrap = false,
	})
	Kit.text(whereLine(result), {
		Name = "Where",
		Parent = group,
		Size = UDim2.new(1, -60, 0, 44),
		Position = UDim2.fromOffset(30, 86),
		TextSize = 17,
		Color = T.InkSoft,
		AlignX = Enum.TextXAlignment.Center,
		AlignY = Enum.TextYAlignment.Top,
	})
	Kit.button("OK", {
		Name = "OK",
		Parent = group,
		Size = UDim2.fromOffset(180, 48),
		Position = UDim2.new(0.5, 0, 0, 140),
		AnchorPoint = Vector2.new(0.5, 0),
		Color = T.Green,
		TextColor = T.Dark,
		TextSize = 20,
	}, Crates.closeReveal)
	return group
end

-- Shows a crate opening; `result` is Sim/Crates.Result as the server sent it.
function Crates.reveal(result: any, still: (boolean | string)?)
	if type(result) ~= "table" or type(result.kind) ~= "string" then
		return
	end
	Crates.closeReveal(true)
	local beat: string? = if still == true then "prize" elseif type(still) == "string" then still else nil
	local rank = math.max(1, CrateData.rank(result.rarity))
	local tone = Crates.tone(result.rarity)
	local first = Crates.tone(CrateData.Rarities[1])

	local root = Kit.box({ Name = "CrateReveal", Parent = Kit.root(), Size = UDim2.fromScale(1, 1) })
	root.ZIndex = 8
	root:SetAttribute("Panel", true)
	local p: any = { root = root }
	reveal = p
	local function alive(): boolean
		return reveal == p and not p.done
	end

	local dim = Kit.frame({
		Name = "Dim",
		Parent = root,
		Size = UDim2.fromOffset(6000, 6000),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Color = T.Black,
		Transparency = if beat then 0 else 1,
		Radius = false,
		ZIndex = Z.dim,
	})
	dim.Active = true
	p.dim = dim
	-- the middle of it all, a little over the screen's middle; shaken as a whole at the thud and the burst
	local stage = Kit.box({
		Name = "Stage",
		Parent = root,
		Size = UDim2.fromOffset(10, 10),
		Position = UDim2.fromScale(0.5, 0.4),
		AnchorPoint = Vector2.new(0.5, 0.5),
	})
	stage.ZIndex = Z.rays
	local home = stage.Position
	local function jolt(strength: number, time: number)
		task.spawn(function()
			local began = os.clock()
			local t = 0
			while t < time and alive() do
				local k = strength * (1 - t / time)
				stage.Position = home
					+ UDim2.fromOffset(math.random(-100, 100) / 100 * k, math.random(-100, 100) / 100 * k)
				task.wait()
				t = os.clock() - began
			end
			stage.Position = home
		end)
	end

	local turning = rays(stage, first, 980)
	-- (the rays come up once the crate has landed and the screen is dark: their rim fades into it)
	turning.Visible = beat ~= nil and beat ~= "drop"
	if not beat then
		for _, r in rayFaces(turning) do
			r.BackgroundTransparency = 1
		end
	end
	local glow = Kit.halo(stage, 560, first, 0.55)
	local core = Kit.halo(stage, 300, first, 0.85)
	for _, h in { glow, core } do
		if h then
			h.ZIndex = Z.halo
		end
	end
	local function tint(c: Color3)
		paintRays(turning, c)
		for _, h in { glow, core } do
			if h then
				h.BackgroundColor3 = c
			end
		end
	end
	-- the rays turn while it lasts, quicker for a rarer prize
	if not beat then
		local conn: RBXScriptConnection? = nil
		conn = RunService.RenderStepped:Connect(function(dt)
			if not alive() then
				if conn then
					conn:Disconnect()
				end
				return
			end
			turning.Rotation = (turning.Rotation + dt * (8 + rank * 4 + (p.spin or 0))) % 360
		end)
	end

	-- the crate
	local crate = Kit.box({
		Name = "Crate",
		Parent = stage,
		Size = UDim2.fromOffset(240, 240),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
	})
	crate.ZIndex = Z.crate
	crate:SetAttribute("ItemId", "crate:" .. result.kind)
	ModelPreview.fromPrims(CrateData.prims(result.kind), { Parent = crate })

	local function showPrize()
		if not alive() then
			return
		end
		crate.Visible = false
		local holder = Kit.box({
			Name = "Prize",
			Parent = stage,
			Size = UDim2.fromOffset(300, 300),
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
		})
		holder.ZIndex = Z.crate
		holder:SetAttribute("ItemId", if result.kind == "pet" then "pets:" .. result.id else result.id)
		local vp = ModelPreview.fromPrims(prizePrims(result), { Parent = holder })
		glints(stage, tone, 4 + rank * 2, alive, beat ~= nil)
		local group = info(p, result, tone)
		if beat then
			return
		end
		-- it rises out of the light and turns slowly
		holder.Size = UDim2.fromOffset(110, 110)
		Kit.tween(
			holder,
			TweenInfo.new(Show.Rise, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
			{ Size = UDim2.fromOffset(300, 300) }
		)
		group.GroupTransparency = 1
		group.Position += UDim2.fromOffset(0, 18)
		Kit.tween(
			group,
			TweenInfo.new(Show.Rise, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, 0, false, Show.Rise * 0.5),
			{ GroupTransparency = 0, Position = group.Position - UDim2.fromOffset(0, 18) }
		)
		local cam = vp.CurrentCamera
		local model = vp:FindFirstChildOfClass("Model")
		if cam and model then
			local middle = model:GetBoundingBox().Position
			local start = cam.CFrame
			local t = 0
			local conn: RBXScriptConnection? = nil
			conn = RunService.RenderStepped:Connect(function(dt)
				if not alive() then
					if conn then
						conn:Disconnect()
					end
					return
				end
				t += dt
				cam.CFrame = CFrame.new(middle) * CFrame.Angles(0, t * Show.Spin, 0) * CFrame.new(-middle) * start
			end)
		end
	end

	local function burst()
		if not alive() then
			return
		end
		if p.hum then
			pcall(function()
				p.hum:Stop()
			end)
			p.hum = nil
		end
		tint(tone)
		if beat then
			sparks(stage, tone, 26, true)
			if beat == "burst" then
				crate.Visible = false
				return
			end
			showPrize()
			return
		end
		Kit.sound("crate_burst")
		if rank >= 4 then
			Kit.sound("levelup")
		end
		local flash = Kit.frame({
			Name = "Flash",
			Parent = root,
			Size = UDim2.fromOffset(6000, 6000),
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Color = T.White,
			Transparency = 0,
			Radius = false,
			ZIndex = Z.flash,
		})
		Kit.tween(flash, TweenInfo.new(Show.Flash, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundTransparency = 1,
		})
		task.delay(Show.Flash + 0.05, function()
			flash:Destroy()
		end)
		ring(stage, tone, 240, 900, 0.7, 10)
		ring(stage, T.White, 160, 620, 0.5, 6)
		sparks(stage, tone, 26 + rank * 4, false)
		jolt(10, 0.3)
		p.spin = 30
		for _, h in { glow, core } do
			if h then
				h.Size = UDim2.fromOffset(h.Size.X.Offset * 1.25, h.Size.Y.Offset * 1.25)
			end
		end
		showPrize()
	end

	if beat == "drop" then
		return
	end
	if beat then
		if beat == "shake" then
			tint(Crates.tone(CrateData.Rarities[math.max(1, rank - 1)]))
			crate.Rotation = 9
			if glow then
				glow.Size = UDim2.fromOffset(640, 640)
			end
			return
		end
		burst()
		return
	end

	-- the beats, played
	local skip = false
	local catcher = Kit.new("TextButton", {
		Name = "Skip",
		Text = "",
		AutoButtonColor = false,
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = Z.skip,
		Parent = root,
	})
	catcher.Activated:Connect(function()
		skip = true
	end)
	Kit.tween(dim, TweenInfo.new(Show.Dark, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		BackgroundTransparency = 0,
	})
	task.spawn(function()
		-- it falls in and lands with a thud
		crate.Position = UDim2.new(0.5, 0, 0.5, -520)
		Kit.tween(
			crate,
			TweenInfo.new(Show.Drop, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ Position = UDim2.fromScale(0.5, 0.5) }
		)
		task.wait(Show.Drop)
		if not alive() then
			return
		end
		Kit.sound("place")
		jolt(7, 0.22)
		crate.Size = UDim2.fromOffset(264, 212)
		Kit.tween(
			crate,
			TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
			{ Size = UDim2.fromOffset(240, 240) }
		)
		turning.Visible = true
		for _, r in rayFaces(turning) do
			Kit.tween(r, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				BackgroundTransparency = 0,
			})
		end
		-- it shakes, harder and faster, and the light climbs the rarities
		p.hum = Kit.sound("crate_hum")
		local long = Show.Shake + Show.ShakeStep * (rank - 1)
		local step = 1
		local began = os.clock()
		local t = 0
		while t < long and alive() and not skip do
			local k = t / long
			local amp = k * k
			local speed = 16 + 34 * k
			crate.Rotation = math.sin(t * speed) * (2 + 12 * amp)
			crate.Position =
				UDim2.new(0.5, math.sin(t * speed * 1.37) * 7 * amp, 0.5, math.cos(t * speed * 0.9) * 3 * amp)
			if glow then
				local s = 520 + 200 * k
				glow.Size = UDim2.fromOffset(s, s)
			end
			if step < rank and t >= long * step / rank then
				step += 1
				local c = Crates.tone(CrateData.Rarities[step])
				tint(c)
				ring(stage, c, 220, 560, 0.45, 8)
				Kit.sound("pickup", { Rate = 0.9 + 0.15 * step })
				jolt(3 + step, 0.15)
			end
			task.wait()
			t = os.clock() - began
		end
		crate.Rotation = 0
		catcher:Destroy()
		burst()
	end)
end

-- Takes the opening down: it fades and is gone (`now`: at once).
function Crates.closeReveal(now: boolean?)
	local p = reveal
	reveal = nil
	if not p then
		return
	end
	p.done = true
	if p.hum then
		pcall(function()
			p.hum:Stop()
		end)
	end
	local root: GuiObject = p.root
	if now or not root.Parent then
		root:Destroy()
		return
	end
	pcall(function()
		(root :: any).Interactable = false
	end)
	Kit.sound("close")
	local out = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	for _, d in root:GetDescendants() do
		if d:IsA("CanvasGroup") then
			Kit.tween(d, out, { GroupTransparency = 1 })
		elseif d:IsA("ViewportFrame") then
			Kit.tween(d, out, { ImageTransparency = 1 })
		elseif d:IsA("Frame") and d.BackgroundTransparency < 1 and not d:FindFirstAncestorOfClass("CanvasGroup") then
			Kit.tween(d, out, { BackgroundTransparency = 1 })
		end
	end
	task.delay(0.2, function()
		root:Destroy()
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
