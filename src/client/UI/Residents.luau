-- The villagers screen: everyone in town, how they feel, where they work and sleep, who their
-- friends are, what they wish for. Change their job or bed, restyle them, and when one of them
-- craves something, buy it for them (the user: "when a character gets a craving, allow the
-- player to simply pay to buy it").
--
-- It is laid out as a character screen. The user: "for the villager menu, make the selected
-- villager have the whole avatar standing next to the list to the left, and a transparnet
-- gradient covering them fading to black to the right, where stats and other buttons are shown",
-- and then pointed at another game's character menu for the layout. So: the list down the left,
-- the picked villager standing full height beside it on a stage in their own colour, a fade
-- over them from clear to black toward the right, and on the black their name, their stats or
-- their friends (the tabs at the top right) and round buttons for what you can do. The layout
-- is what is borrowed; the drawing is ours.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Remotes = require(Shared.Net.Remotes)
local Personalities = require(Shared.Data.Personalities)
local Foods = require(Shared.Data.Foods)
local Catalog = require(Shared.Build.Catalog)
local Tuning = require(Shared.Config.Tuning)
local Schema = require(Shared.Sim.Schema)
local City = require(Shared.Sim.City)
local Relationships = require(Shared.Sim.Relationships)
local Life = require(Shared.Sim.Life)
local Flair = require(Shared.Sim.Flair)
local Memory = require(Shared.Sim.Memory)
local Jobs = require(Shared.Data.Jobs)
local Colors = require(Shared.Util.Colors)
local Text = require(Shared.Util.Text)

local Kit = require(script.Parent.Kit)
local Icons = require(script.Parent.Icons)
local MenuParts = require(script.Parent.MenuParts)
local Toasts = require(script.Parent.Toasts)
local ModelPreview = require(script.Parent.ModelPreview)
local GiftPicker = require(script.Parent.GiftPicker)
local State = require(script.Parent.Parent.Controllers.State)

local Residents = {}

local T = Kit.Theme
local panel: any = nil
local selected: string? = nil
local listFrame: ScrollingFrame
local detail: Frame -- the stage the picked villager stands on
local tab = "about"
local unbind: { () -> () } = {}
local popup: Frame? = nil
local count: TextLabel? = nil -- how many live here, over the list
local STAGE_ROUND = 14

local function profileView(): any
	return {
		villagers = State.data.villagers or {},
		plan = State.plan,
		rel = State.data.rel or {},
		coins = State.data.coins or 0,
	}
end

local function moodWord(m: number): string
	if m >= 80 then
		return "delighted"
	elseif m >= 60 then
		return "happy"
	elseif m >= 40 then
		return "okay"
	elseif m >= 20 then
		return "down"
	end
	return "miserable"
end

local function bar(parent: Instance, ratio: number, color: Color3, order: number): Frame
	local track = Kit.bar({ Parent = parent, Size = UDim2.new(1, -4, 0, 14), LayoutOrder = order }, ratio, color)
	return track
end

local function closePopup()
	if popup then
		popup:Destroy()
		popup = nil
	end
end

-- A small list of choices floating over the screen, each a row.
-- An option may name a thing (`item`, with `color` for when it has no picture): its picture
-- goes at the left end of its row.
local function choose(
	title: string,
	options: { { label: string, sub: string?, fn: () -> (), item: string?, color: Color3? } }
)
	closePopup()
	local p = Kit.frame({
		Parent = panel.root,
		Size = UDim2.fromOffset(420, 400),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Color = T.Paper,
		Radius = 26,
	})
	p.ZIndex = 30
	Kit.softShadow(p, 2)
	popup = p
	Kit.pad(p, 16, 14)
	Kit.title(title, { Parent = p, Size = UDim2.new(1, -48, 0, 32), TextSize = 22 })
	Kit.closeButton({
		Parent = p,
		Size = UDim2.fromOffset(38, 38),
		Position = UDim2.new(1, -38, 0, -2),
	}, closePopup)
	local scroll = Kit.scroll({ Parent = p, Size = UDim2.new(1, 0, 1, -44), Position = UDim2.fromOffset(0, 42) })
	Kit.list(scroll, 8)
	if #options == 0 then
		Kit.text("Nothing to pick from yet.", { Parent = scroll, TextSize = 16, Color = T.InkSoft })
	end
	for i, o in options do
		local _, inner = Kit.row({
			Parent = scroll,
			Size = UDim2.new(1, -12, 0, if o.sub then 58 else 48),
			Height = if o.sub then 58 else 48,
			LayoutOrder = i,
			Title = o.label,
			Sub = o.sub,
			TextSize = 17,
			LeftSpace = if o.item then 62 else nil,
		}, function()
			closePopup()
			o.fn()
		end)
		if o.item then
			Icons.item(o.item, 38, o.color or T.Line, {
				Parent = inner,
				Position = UDim2.new(0, 14, 0.5, -19),
				ZIndex = 3,
			})
		end
	end
end

-- A villager's face in a round frame: a close-up of their head in a little viewport. The model
-- is asked for once and kept while the panel is open.
local faceModels: { [string]: Model } = {}

local function portraitInto(holder: GuiObject, vid: string)
	task.spawn(function()
		local model = faceModels[vid]
		if not model or not model.Parent then
			local ok, found = pcall(function()
				return Remotes.fn("VillagerFocus"):InvokeServer(vid)
			end)
			model = if ok and typeof(found) == "Instance" and found:IsA("Model") then found else nil
			if model then
				faceModels[vid] = model
			end
		end
		if model and holder.Parent then
			local vp = ModelPreview.fromModel(model, { Parent = holder, Face = true })
			if vp then
				Kit.rounded(vp)
			end
		end
	end)
end

local function call(remote: string, ...: any)
	local args = table.pack(...)
	task.spawn(function()
		local ok, err = Remotes.fn(remote):InvokeServer(table.unpack(args, 1, args.n))
		if not ok and err then
			Toasts.show(err, "warn")
		end
	end)
end

local function pickJob(vid: string)
	local p = profileView()
	local options = {}
	table.insert(options, {
		label = "No job",
		sub = "Stay home and potter about",
		fn = function()
			call("VillagerJob", vid, nil)
		end,
	})
	for _, w in City.workplaces(State.plan) do
		local worker
		for other, o in p.villagers do
			if o.job == w.key and other ~= vid then
				worker = o.name
			end
		end
		table.insert(options, {
			label = Text.fill("{job} at the {place}", { job = w.job.name, place = w.def.name:lower() }),
			sub = if worker
				then Text.fill("{name} works here. They'll swap jobs.", { name = worker })
				else Text.fill("About {n} coins a day", { n = w.job.income }),
			fn = function()
				call("VillagerJob", vid, w.key)
			end,
		})
	end
	choose("Pick a job", options)
end

local function pickBed(vid: string)
	local p = profileView()
	local options = {}
	for key, item in State.plan.items do
		local def = Catalog.get(item.id)
		if def and Catalog.hasTag(def, "bed") then
			local sleepers = {}
			for other, o in p.villagers do
				if o.bed == key and other ~= vid then
					table.insert(sleepers, o.name)
				end
			end
			table.insert(options, {
				label = def.name,
				sub = if #sleepers > 0 then "Shared with " .. table.concat(sleepers, ", ") else "Free",
				fn = function()
					call("VillagerBed", vid, key)
				end,
			})
		end
	end
	choose("Pick a bed", options)
end

-- where the stats start on the stage: the villager stands to the left of this
local INFO_X = 400

-- How they feel, as a colour: the same green, yellow and coral as the dot by their name.
local wishRow: (Frame, string, any, any, string, number) -> number

local function moodColor(m: number): Color3
	return if m >= 60 then T.Green elseif m >= 40 then T.Yellow else T.Coral
end

-- A fact about them: a small soft label over its value, which may run to two lines.
local function fact(parent: Instance, label: string, value: string, order: number, color: Color3?)
	local cell = Kit.box({ Name = label, Parent = parent, LayoutOrder = order })
	-- the label set wide in small capitals, as on the stat tiles
	Kit.caption(label, { Name = "Label", Parent = cell, Size = UDim2.new(1, 0, 0, 16), TextSize = 11 })
	Kit.text(value, {
		Name = "Value",
		Parent = cell,
		Size = UDim2.new(1, -8, 0, 36),
		Position = UDim2.fromOffset(0, 18),
		TextSize = 16,
		Font = Kit.Fonts.Bold,
		Tint = color,
		AlignY = Enum.TextYAlignment.Top,
	})
end

-- The About tab: how they feel and how close they are to you as two tiles with bars, then where
-- they work and sleep, their birthday and who they're closest to.
local function about(parent: Frame, vid: string, v: any, p: any)
	local tiles = Kit.box({ Name = "Tiles", Parent = parent, Size = UDim2.new(1, 0, 0, 90) })
	Kit.grid(tiles, UDim2.new(0.5, -6, 0, 90), 12)
	local mood = math.floor(v.mood)
	local word = moodWord(mood)
	MenuParts.stat("smile", "Mood", word:sub(1, 1):upper() .. word:sub(2), moodColor(mood), {
		Name = "Mood",
		Parent = tiles,
		LayoutOrder = 1,
		TextSize = 24,
		Sub = Text.fill("{n}%", { n = mood }),
		Bar = mood / 100,
	})
	local level = v.heart or 1
	local need = Life.heartNeed(level)
	MenuParts.stat("heart", "Heart level", tostring(level), T.Pink, {
		Name = "Heart",
		Parent = tiles,
		LayoutOrder = 2,
		TextSize = 24,
		-- (no top level: the bar is the way to the next)
		Bar = (v.hxp or 0) / math.max(1, need),
	})

	local grid = Kit.box({
		Name = "Facts",
		Parent = parent,
		Size = UDim2.new(1, 0, 1, -106),
		Position = UDim2.fromOffset(0, 106),
	})
	Kit.grid(grid, UDim2.new(0.5, -8, 0, 52), 12)
	local w = City.jobOf(p, vid)
	fact(
		grid,
		"Work",
		if w then Text.fill("{job}, {place}", { job = w.job.name, place = w.def.name:lower() }) else "No job yet",
		1
	)
	local bedText, bedColor = "No bed. Build one.", T.Coral
	if v.bed then
		bedText, bedColor = "Has a bed", nil
		local item = State.plan.items[v.bed]
		local def = item and Catalog.get(item.id)
		if def then
			bedText = def.name
		end
	end
	fact(grid, "Sleeps in", bedText, 2, bedColor)
	fact(
		grid,
		"Birthday",
		Text.fill("{season} {day}", { season = Schema.Seasons[v.bday.s] or "Spring", day = v.bday.d }),
		3
	)
	-- who they're closest to in town (the Friends tab has the rest)
	local best, bestScore = nil, -math.huge
	for other, o in p.villagers do
		if other ~= vid then
			local score = Relationships.peek(p, vid, other)
			if score > bestScore then
				best, bestScore = o, score
			end
		end
	end
	local closest = "Nobody yet"
	if best and bestScore >= 10 then
		local _, levelName = Relationships.level(bestScore)
		closest = Text.fill("{name}, {how}", { name = best.name, how = levelName:lower() })
	end
	fact(grid, "Closest to", closest, 4)
end

-- The Friends tab: everyone else in town as a row, closest first: how they get on (their
-- friendship or a quarrel) in its colour and how close they are as a bar. Best friends are as
-- close as two villagers get (there is no romance) and stand out in pink.
local LEVELS = Tuning.Relationships.Levels
local BEST_FRIENDS = LEVELS[#LEVELS].Min
local function friendsOf(parent: Frame, vid: string, p: any)
	local friends = Kit.scroll({ Parent = parent, Size = UDim2.fromScale(1, 1) })
	Kit.list(friends, 6)
	local rows = {}
	for other, o in p.villagers do
		if other ~= vid then
			table.insert(rows, {
				id = other,
				o = o,
				s = Relationships.peek(p, vid, other),
				q = Relationships.quarreling(p, vid, other, os.time()),
			})
		end
	end
	table.sort(rows, function(a, b)
		return a.s > b.s
	end)
	if #rows == 0 then
		MenuParts.empty("people", "Nobody else in town yet", "Friends show up here once someone else moves in.", {
			Parent = friends,
			LayoutOrder = 1,
			Color = T.Pink,
			Height = 200,
		})
	end
	for i, r in rows do
		local _, levelName = Relationships.level(r.s)
		local how = if r.q then "Not speaking" else levelName
		local col = if r.q
			then T.Coral
			elseif r.s >= BEST_FRIENDS then T.Pink
			elseif r.s >= 55 then T.Yellow
			elseif r.s >= 10 then T.Green
			elseif r.s > -10 then T.Blue
			else T.Purple
		local row, inner = Kit.row({
			Name = r.id,
			Parent = friends,
			Size = UDim2.new(1, -12, 0, 52),
			Height = 52,
			LayoutOrder = i,
			Title = r.o.name,
			Sub = how,
			TextSize = 17,
			LeftSpace = 48,
			RightSpace = 128,
		})
		-- their face, in a ring the colour of how they get on
		local lean: number = row:GetAttribute("Lean") or 6
		local face = Kit.portrait({
			Parent = inner,
			Size = 40,
			Position = UDim2.new(0, lean, 0.5, -20),
			Color = Colors.fromHex(r.o.color):Lerp(T.Cream, 0.5),
			Border = col,
			BorderWidth = 2.5,
			ZIndex = 3,
		})
		portraitInto(face, r.id)
		Kit.bar({
			Parent = inner,
			Size = UDim2.fromOffset(96, 8),
			Position = UDim2.new(1, -30, 0.5, 0),
			AnchorPoint = Vector2.new(1, 0.5),
		}, (r.s + 100) / 200, col)
	end
end

-- The Lately tab: what their events left them with for a few days (Sim/Memory), newest first, each
-- with how long it has left. The user: "along with their conversations and events having more
-- impact, such as remembering if they joined a band, started wearing a new accessory (temporarily)".
local LATELY_ICONS = {
	band = "music",
	accessory = "hat",
	hobby = "sparkle",
	haircut = "hair",
	pet = "smile",
	dish = "pot",
	fallout = "anger",
	garden = "plant",
	penpal = "news",
	training = "trophy",
}
local LATELY_COLORS = {
	band = "Purple",
	accessory = "Orange",
	hobby = "Yellow",
	haircut = "Pink",
	pet = "Green",
	dish = "Orange",
	fallout = "Coral",
	garden = "Green",
	penpal = "Blue",
	training = "Blue",
}

local function latelyOf(parent: Frame, vid: string, p: any)
	local rows = Memory.lately(p, vid, os.time())
	local list = Kit.scroll({ Name = "Lately", Parent = parent, Size = UDim2.fromScale(1, 1) })
	Kit.list(list, 6)
	if #rows == 0 then
		MenuParts.empty(
			"sparkle",
			"Nothing new lately",
			"When something in an event sticks with them, a band or a new hat, it shows up here.",
			{
				Parent = list,
				LayoutOrder = 1,
				Color = T.Yellow,
				Height = 200,
			}
		)
		return
	end
	for i, row in rows do
		Kit.row({
			Name = row.kind,
			Parent = list,
			Size = UDim2.new(1, -12, 0, 52),
			Height = 52,
			LayoutOrder = i,
			Title = row.text,
			Sub = if row.days <= 1 then "Ends today" else Text.fill("{n} more days", { n = row.days }),
			TextSize = 16,
			Marker = LATELY_ICONS[row.kind] or "sparkle",
			MarkerColor = (T :: any)[LATELY_COLORS[row.kind] or "Yellow"] or T.Yellow,
		})
	end
end

-- The Quirks tab: the three things the player gives a villager to say, bought with gems (Sim/Flair).
-- The user: "villagers could have a custom saying, thing they add to the end of their sentances
-- sometimes, custom thing they like the most which they will mention ... that can be bought with
-- gems". Each is a row with what they have now and a button with its price; the gems you have are
-- over them, and the editor says when you're short.
local FLAIR_HINTS = {
	phrase = "A sentence they say now and then, in a chat or over their head.",
	ending = "A word or two they put on the end of a sentence now and then.",
	thing = "Something they love, which they bring up when you chat.",
}
local FLAIR_EXAMPLES = { phrase = "Smells like rain to me.", ending = "buddy", thing = "old maps" }

local function gemsText(n: number): string
	return if n == 1 then "1 gem" else Text.fill("{n} gems", { n = n })
end

local function needMore(n: number): string
	return if n == 1 then "You need 1 more gem." else Text.fill("You need {n} more gems.", { n = n })
end

-- what a price is short by, with the gems there are now
local function gemsShort(kind: string): number
	return math.max(0, Flair.price(kind) - (State.data.gems or 0))
end

local saving = false
local function editFlair(vid: string, kind: string)
	local v = State.villager(vid)
	if not v then
		return
	end
	closePopup()
	local now = Flair.get(v, kind)
	local price = Flair.price(kind)
	local short = gemsShort(kind)
	local pop = Kit.frame({
		Name = "FlairEditor",
		Parent = panel.root,
		Size = UDim2.fromOffset(460, 300),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Color = T.Paper,
		Radius = 26,
	})
	pop.ZIndex = 30
	Kit.softShadow(pop, 2)
	popup = pop
	Kit.pad(pop, 18, 16)
	Kit.title(Text.fill("{x}'s {what}", { x = v.name, what = Flair.Names[kind]:lower() }), {
		Parent = pop,
		Size = UDim2.new(1, -48, 0, 32),
		TextSize = 22,
		Wrap = false,
	})
	Kit.closeButton({
		Parent = pop,
		Size = UDim2.fromOffset(38, 38),
		Position = UDim2.new(1, -38, 0, -2),
	}, closePopup)
	Kit.text(FLAIR_HINTS[kind], {
		Name = "Hint",
		Parent = pop,
		Size = UDim2.new(1, 0, 0, 36),
		Position = UDim2.fromOffset(0, 40),
		TextSize = 15,
		Color = T.InkSoft,
		AlignY = Enum.TextYAlignment.Top,
	})
	local box = Kit.textbox(Text.fill("For example: {x}", { x = FLAIR_EXAMPLES[kind] }), {
		Name = "FlairText",
		Parent = pop,
		Text = now or "",
		TextSize = 17,
		Size = UDim2.new(1, 0, 0, 44),
		Position = UDim2.fromOffset(0, 84),
	})
	box.ClearTextOnFocus = false
	pcall(function()
		(box :: any).MaxVisibleGraphemes = Flair.maxLength(kind)
	end)
	-- the price, the gems there are, and what's missing
	Kit.text(
		if short > 0
			then Text.fill("It costs {price}. {more}", { price = gemsText(price), more = needMore(short) })
			else Text.fill("It costs {price}. You have {have}.", {
				price = gemsText(price),
				have = gemsText(State.data.gems or 0),
			}),
		{
			Name = "Price",
			Parent = pop,
			Size = UDim2.new(1, 0, 0, 22),
			Position = UDim2.fromOffset(0, 140),
			TextSize = 15,
			Font = Kit.Fonts.Bold,
			Tint = if short > 0 then T.Coral else nil,
		}
	)
	local save = Kit.button(Text.fill("Save for {n}", { n = price }), {
		Name = "SaveFlair",
		Parent = pop,
		Size = UDim2.fromOffset(190, 46),
		Position = UDim2.new(1, 0, 1, 0),
		AnchorPoint = Vector2.new(1, 1),
		Color = if short > 0 then T.PaperDark else T.Green,
		TextColor = if short > 0 then T.InkSoft else T.White,
		TextSize = 17,
		Icon = "gem",
	}, function()
		if short > 0 then
			Toasts.show(needMore(short), "warn")
			return
		end
		if saving then
			return
		end
		saving = true
		local text = box.Text
		task.spawn(function()
			local sent, ok, msg = pcall(function()
				return Remotes.fn("VillagerFlair"):InvokeServer(vid, kind, text)
			end)
			saving = false
			if sent and ok then
				closePopup()
				Toasts.show(if type(msg) == "string" and msg ~= "" then msg else "Saved.", "good")
			else
				Toasts.show(
					if sent and type(msg) == "string" then msg else "That didn't go through. Try again.",
					"warn"
				)
			end
		end)
	end)
	save:SetAttribute("Disabled", short > 0)
	if now then
		Kit.button("Take it off", {
			Name = "ClearFlair",
			Parent = pop,
			Size = UDim2.fromOffset(160, 46),
			Position = UDim2.new(0, 0, 1, 0),
			AnchorPoint = Vector2.new(0, 1),
			Color = T.Coral,
			TextSize = 17,
		}, function()
			closePopup()
			call("VillagerFlair", vid, kind, false)
		end)
	end
end

local function quirksOf(parent: Frame, vid: string, v: any)
	local list = Kit.scroll({ Name = "Quirks", Parent = parent, Size = UDim2.fromScale(1, 1) })
	Kit.list(list, 8)
	-- the gems there are
	local gems = State.data.gems or 0
	local head = Kit.box({ Name = "Gems", Parent = list, Size = UDim2.new(1, -12, 0, 26), LayoutOrder = 0 })
	Icons.make("gem", 20, { Parent = head, Position = UDim2.new(0, 0, 0.5, -10), Color = T.Blue, Centre = true })
	Kit.text(Text.fill("You have {n}. Each change costs again.", { n = gemsText(gems) }), {
		Name = "Count",
		Parent = head,
		Size = UDim2.new(1, -28, 1, 0),
		Position = UDim2.fromOffset(28, 0),
		TextSize = 14,
		Color = T.InkSoft,
		Wrap = false,
	})
	for i, kind in Flair.Kinds do
		local now = Flair.get(v, kind)
		local price = Flair.price(kind)
		local short = gemsShort(kind)
		local row, inner = Kit.row({
			Name = kind,
			Parent = list,
			Size = UDim2.new(1, -12, 0, 56),
			Height = 56,
			LayoutOrder = i,
			Title = Flair.Names[kind],
			Sub = if now then (if kind == "phrase" then now else Text.fill('"{x}"', { x = now })) else "Not set yet",
			TextSize = 16,
			RightSpace = 124,
		})
		local lean: number = row:GetAttribute("Lean") or 6
		local button = Kit.button(
			if now then Text.fill("Change {n}", { n = price }) else Text.fill("Set {n}", { n = price }),
			{
				Name = "Edit",
				Parent = inner,
				Size = UDim2.fromOffset(112, 38),
				Position = UDim2.new(1, -(lean + 8), 0.5, 0),
				AnchorPoint = Vector2.new(1, 0.5),
				Color = T.Blue,
				TextSize = 15,
				Icon = "gem",
				ZIndex = 3,
			},
			function()
				-- (short of gems, the editor says how many more)
				editFlair(vid, kind)
			end
		)
		button:SetAttribute("Short", short > 0)
	end
end

-- Buying what a villager craves: the coins go and the wish is granted on the server.
local buying = false
local function buyWish(vid: string)
	if buying then
		return
	end
	buying = true
	task.spawn(function()
		local sent, ok, msg = pcall(function()
			return Remotes.fn("WishBuy"):InvokeServer(vid)
		end)
		buying = false
		-- bought: the server says how pleased they are (its own notices) and clears the wish
		if sent and ok then
			if type(msg) == "string" and msg ~= "" then
				Toasts.show(msg, "good")
			end
		elseif sent and type(msg) == "string" then
			Toasts.show(msg, "warn")
		end
	end)
end

-- A villager's wish, as a row above their buttons, with what you can do about it. A craving
-- shows the food's picture and a Buy button with its price; without the coins the button is
-- dim and the row says how many more are needed. Returns the row's height.
wishRow = function(info: Frame, vid: string, v: any, p: any, wishText: string, bottom: number): number
	local kind = v.wish.kind
	local food = if kind == "food" then Foods.get(v.wish.arg) else nil
	local price = if kind == "food" then Life.wishPrice(p, vid) else nil
	local coins = State.data.coins or 0
	local short = if price then math.max(0, price - coins) else 0
	local h = if food then 62 else 56
	local row, inside = Kit.row({
		Name = "Wish",
		Parent = info,
		Size = UDim2.new(1, 0, 0, h),
		Height = h,
		Marker = if food then nil else "heart",
		MarkerColor = T.Orange,
	})
	row.Position = UDim2.new(0, 0, 1, -(bottom + h))
	local lean: number = row:GetAttribute("Lean") or 6
	local textX = lean + h - 2
	if food then
		-- the thing they crave, and (when the coins are short) how many more it takes
		Icons.item(food.id, 44, Colors.fromHex(food.color), {
			Name = "Craving",
			Parent = inside,
			Position = UDim2.new(0, lean + 6, 0.5, -22),
			ZIndex = 3,
		})
		Kit.new("TextLabel", {
			Name = "Title",
			Text = Text.fill("Craving {food}", { food = food.name:lower() }),
			BackgroundTransparency = 1,
			Font = Kit.Fonts.Title,
			TextSize = 17,
			TextColor3 = T.Ink,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Size = UDim2.new(1, -(textX + 160), 0, 22),
			Position = if short > 0 then UDim2.new(0, textX, 0.5, -21) else UDim2.new(0, textX, 0.5, -11),
			ZIndex = 2,
			Parent = inside,
		})
		if short > 0 then
			Kit.new("TextLabel", {
				Name = "Short",
				Text = Text.fill("You need {n} more coins.", { n = Text.commas(short) }),
				BackgroundTransparency = 1,
				Font = Kit.Fonts.Body,
				TextSize = 14,
				TextColor3 = T.InkSoft,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Size = UDim2.new(1, -(textX + 160), 0, 18),
				Position = UDim2.new(0, textX, 0.5, 2),
				ZIndex = 2,
				Parent = inside,
			})
		end
	else
		-- the wish can run to two lines
		Kit.text(wishText, {
			Name = "Title",
			Parent = inside,
			Size = UDim2.new(1, -(textX + 160), 1, -8),
			Position = UDim2.fromOffset(textX, 4),
			TextSize = 15,
			Font = Kit.Fonts.Bold,
			ZIndex = 2,
		})
	end
	local label, fn, color, icon = nil, nil, T.Orange, nil
	if food then
		local afford = short <= 0
		label = Text.fill("Buy for {n}", { n = Text.commas(price or 0) })
		color, icon = if afford then T.Green else T.PaperDark, "coin"
		fn = function()
			if not afford then
				Toasts.show(Text.fill("You need {n} more coins.", { n = Text.commas(short) }), "warn")
				return
			end
			buyWish(vid)
		end
	elseif kind == "friend" then
		label, fn = "Introduce", function()
			call("WishGrant", vid, "friend", v.wish.arg)
		end
	else
		label, fn = "Have a chat", function()
			call("WishGrant", vid, "cheer")
		end
	end
	local button = Kit.button(label, {
		Name = if food then "BuyWish" else "WishAnswer",
		Parent = inside,
		Size = UDim2.fromOffset(142, 40),
		Position = UDim2.new(1, -(lean + 10), 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
		Color = color,
		TextColor = if food and short > 0 then T.InkSoft else T.White,
		TextSize = 15,
		Icon = icon,
		ZIndex = 3,
	}, fn)
	button:SetAttribute("Disabled", food ~= nil and short > 0)
	return h
end

local function showDetail()
	for _, c in detail:GetChildren() do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
	local vid = selected
	local v = vid and State.villager(vid)
	if not vid or not v then
		-- nobody yet: say so in the middle of the stage, with the way to make someone
		local empty =
			MenuParts.empty("people", "Nobody lives here yet", "Make your first villager and they'll move into town.", {
				Parent = detail,
				Height = 250,
				Size = UDim2.fromOffset(540, 250),
				Position = UDim2.fromScale(0.5, 0.5),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Color = T.Green,
			})
		Kit.button("Make a villager", {
			Name = "MakeVillager",
			Parent = empty,
			Size = UDim2.fromOffset(220, 48),
			Position = UDim2.new(0.5, 0, 1, 0),
			AnchorPoint = Vector2.new(0.5, 1),
			Color = T.Green,
			TextSize = 19,
			Icon = "plus",
		}, function()
			local Hud = require(script.Parent.Hud)
			Hud.open("Creator", { mode = "new" })
		end)
		return
	end
	local p = profileView()
	local pers = Personalities.get(v.pers)
	local own = Colors.fromHex(v.color)

	-- the stage: their own colour sinking into the dark, leaning bands of it and shapes sliding
	-- up and to the right behind them (the user: "animate shapes in this screen as well, going
	-- diagonally")
	local backdrop =
		Kit.backdrop(detail, own, #vid * 17 + (string.byte(vid, #vid) or 0), { W = 1300, H = 820, Count = 16 })
	Kit.halo(backdrop, 620, own:Lerp(T.White, 0.25), 0.3)
	Kit.corner(backdrop, STAGE_ROUND)
	local stand = Kit.box({
		Name = "Avatar",
		Parent = detail,
		Size = UDim2.new(0, INFO_X + 40, 1, 10),
		Position = UDim2.fromOffset(-10, 0),
	})
	-- the villager, the whole of them, standing
	task.spawn(function()
		local model = faceModels[vid]
		if not model or not model.Parent then
			local ok, found = pcall(function()
				return Remotes.fn("VillagerFocus"):InvokeServer(vid)
			end)
			model = if ok and typeof(found) == "Instance" and found:IsA("Model") then found else nil
			if model then
				faceModels[vid] = model
			end
		end
		if model and stand.Parent then
			local vp, shade = ModelPreview.fromModel(model, { Parent = stand, Stand = true, Shadow = true })
			if vp then
				vp.ZIndex = 2
			end
			if shade then
				shade.ZIndex = 1
			end
		end
	end)
	-- the fade over them: clear on the left, black by the time it reaches the stats
	local fade = Kit.frame({
		Name = "Fade",
		Parent = detail,
		Size = UDim2.new(1, -150, 1, 0),
		Position = UDim2.fromOffset(150, 0),
		Color = T.Black,
		Radius = STAGE_ROUND,
		ZIndex = 3,
	})
	Kit.new("UIGradient", {
		Name = "Clear",
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.2, 0.62),
			NumberSequenceKeypoint.new(0.36, 0.12),
			NumberSequenceKeypoint.new(0.46, 0),
			NumberSequenceKeypoint.new(1, 0),
		}),
		Parent = fade,
	})

	local info = Kit.box({
		Name = "Info",
		Parent = detail,
		Size = UDim2.new(1, -(INFO_X + 28), 1, -40),
		Position = UDim2.fromOffset(INFO_X, 20),
	})
	info.ZIndex = 4
	-- the name, and what they're like
	Kit.title(v.name .. (if v.isYou then "  (you)" else ""), {
		Name = "Name",
		Parent = info,
		TextSize = 40,
		Size = UDim2.new(1, 0, 0, 48),
		Wrap = false,
	})
	Kit.text(if pers then pers.name .. ". " .. pers.blurb else "", {
		Name = "Personality",
		Parent = info,
		TextSize = 15,
		Color = T.InkSoft,
		Size = UDim2.new(1, 0, 0, 38),
		Position = UDim2.fromOffset(0, 50),
		AlignY = Enum.TextYAlignment.Top,
	})

	-- what you can do, as round buttons along the bottom
	local ACT = 80
	local actions = Kit.box({
		Name = "Actions",
		Parent = info,
		Size = UDim2.new(1, 0, 0, ACT),
		Position = UDim2.new(0, 0, 1, -ACT),
	})
	Kit.list(actions, 9, true, Enum.HorizontalAlignment.Center)
	local function action(icon: string, label: string, color: Color3, order: number, fn: () -> ())
		Kit.iconButton(icon, label, {
			Parent = actions,
			Size = UDim2.fromOffset(76, ACT),
			Color = color,
			LayoutOrder = order,
		}, fn)
	end
	action("briefcase", "Job", T.Blue, 1, function()
		pickJob(vid)
	end)
	action("bed", "Bed", T.Purple, 2, function()
		pickBed(vid)
	end)
	action("shirt", "Look", T.Orange, 3, function()
		local Hud = require(script.Parent.Hud)
		Hud.open("Creator", { mode = "edit", vid = vid })
	end)
	-- a thing from the bag (UI/GiftPicker): what they say comes up as a notice, and over their head
	action("gift", "Gift", T.Pink, 4, function()
		GiftPicker.open(panel.root, vid, function(r: any)
			if type(r) == "table" and type(r.line) == "string" then
				Toasts.show(Text.fill("{x}: {line}", { x = v.name, line = r.line }), "good")
			end
		end)
	end)
	local confirm = false
	action("door", "Move out", T.Coral, 5, function()
		if not confirm then
			confirm = true
			Toasts.show(Text.fill("Press Move out again to say goodbye to {name}.", { name = v.name }), "warn")
			task.delay(4, function()
				confirm = false
			end)
			return
		end
		call("VillagerRemove", vid)
		selected = nil
	end)

	-- their wish, as a row above the buttons, with what you can do about it
	local bottom = ACT + 12
	local wishText = Life.wishText(p, vid)
	if wishText and v.wish then
		bottom += wishRow(info, vid, v, p, wishText, bottom) + 12
	end

	-- the tab's own part, between the name and the buttons
	local TOP = 100
	local content = Kit.box({
		Name = "Content",
		Parent = info,
		Size = UDim2.new(1, 0, 1, -(TOP + bottom)),
		Position = UDim2.fromOffset(0, TOP),
	})
	if tab == "friends" then
		friendsOf(content, vid, p)
	elseif tab == "lately" then
		latelyOf(content, vid, p)
	elseif tab == "quirks" then
		quirksOf(content, vid, v)
	else
		about(content, vid, v, p)
	end
	local _ = Jobs
	local _2 = Tuning
end

local function refreshList()
	if not panel then
		return
	end
	for _, c in listFrame:GetChildren() do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
	local p = profileView()
	local list = State.villagerList()
	if not selected and list[1] then
		selected = list[1].id
	end
	for i, v in list do
		local w = City.jobOf(p, v.id)
		local row, inner = Kit.row({
			Name = v.id,
			Parent = listFrame,
			Size = UDim2.new(1, -10, 0, 62),
			Height = 62,
			LayoutOrder = i,
			Title = v.name,
			Sub = if w then w.job.name else "No job",
			TextSize = 18,
			LeftSpace = 58,
			RightSpace = 30,
			Selected = v.id == selected,
		}, function()
			selected = v.id
			refreshList()
			showDetail()
		end)
		local lean: number = row:GetAttribute("Lean") or 6
		-- the villager's face in a ring of their own colour, at the round end of the row (the
		-- user: "Put the villager portrait in place of the blue lines", and "make portraits a
		-- circle with a border instead of a square")
		local own = Colors.fromHex(v.color)
		local face = Kit.portrait({
			Parent = inner,
			Size = 48,
			Position = UDim2.new(0, lean + 1, 0.5, -24),
			Color = own:Lerp(T.Cream, 0.5),
			Border = own:Lerp(T.White, 0.35),
			BorderWidth = 2,
			ZIndex = 3,
		})
		portraitInto(face, v.id)
		-- how they feel, as a dot at the right end
		Kit.disc({
			Name = "Mood",
			Parent = inner,
			Size = 12,
			Position = UDim2.new(1, -(lean + 18), 0.5, -6),
			Color = moodColor(v.mood),
			ZIndex = 3,
		})
	end
	-- the room left in town, as a dim slot that opens the creator
	-- (the town's level sets how many it may have: City.villagerCap)
	local cap = City.stats(State.data).villagerCap
	local room = cap - #list
	if room > 0 then
		MenuParts.slot("Make a villager", {
			Name = "Room",
			Parent = listFrame,
			LayoutOrder = 998,
			Height = 62,
			Icon = "plus",
			Sub = if room == 1 then "Room for one more" else Text.fill("Room for {n} more", { n = room }),
		}, function()
			local Hud = require(script.Parent.Hud)
			Hud.open("Creator", { mode = "new" })
		end)
	end
	if count then
		count.Text = Text.fill("{n} of {max}", { n = #list, max = cap })
	end
end

function Residents.isOpen(): boolean
	return panel ~= nil
end

function Residents.close()
	closePopup()
	GiftPicker.close()
	for _, u in unbind do
		u()
	end
	unbind = {}
	if panel then
		Kit.closePanel(panel)
		panel = nil
	end
end

function Residents.open(vid: string?)
	Residents.close()
	if vid then
		selected = vid
	end
	tab = "about"
	panel = Kit.panel("Villagers", Kit.MenuSize, Residents.close, "people", Kit.Theme.Green, {
		Caption = "People in town",
		Tabs = {
			{ id = "about", name = "About" },
			{ id = "friends", name = "Friends" },
			{ id = "lately", name = "Lately" },
			{ id = "quirks", name = "Quirks" },
		},
		OnTab = function(id: string)
			tab = id
			showDetail()
		end,
	})
	-- everyone in town, in a well of their own down the left: a dim caption and the count over
	-- the rows
	local well = Kit.frame({
		Name = "Roster",
		Parent = panel.body,
		Size = UDim2.new(0, 262, 1, 0),
		Color = T.PaperDark,
		Cut = 14,
	})
	Kit.caption("In town", {
		Name = "Caption",
		Parent = well,
		Size = UDim2.new(1, -28, 0, 18),
		Position = UDim2.fromOffset(14, 10),
		TextSize = 11,
	})
	count = Kit.text("", {
		Name = "Count",
		Parent = well,
		Size = UDim2.new(1, -28, 0, 18),
		Position = UDim2.fromOffset(14, 10),
		TextSize = 14,
		Font = Kit.Fonts.Bold,
		Color = T.InkSoft,
		AlignX = Enum.TextXAlignment.Right,
		Wrap = false,
	})
	listFrame = Kit.scroll({
		Parent = well,
		Size = UDim2.new(1, -12, 1, -44),
		Position = UDim2.fromOffset(8, 36),
	})
	Kit.list(listFrame, 8)
	-- the stage cuts the villager and the fade to its box. A plain frame: inside a CanvasGroup
	-- the villager's 3D picture comes out pale (the moving backdrop has its own, behind them,
	-- rounded to the stage's corners)
	detail = Kit.frame({
		Name = "Stage",
		Parent = panel.body,
		Size = UDim2.new(1, -278, 1, 0),
		Position = UDim2.fromOffset(278, 0),
		Color = T.PaperDark,
		Radius = false,
		Clips = true,
	})
	Kit.corner(detail, STAGE_ROUND)
	Kit.rim(detail, T.Line, 1, 0.3)
	refreshList()
	showDetail()
	local lastVillagers = nil
	table.insert(
		unbind,
		State.on("villagers", function(v)
			if v ~= lastVillagers then
				lastVillagers = v
				refreshList()
				showDetail()
			end
		end)
	)
	table.insert(
		unbind,
		State.on("rel", function()
			showDetail()
		end)
	)
	-- the Quirks tab's prices follow the gems
	table.insert(
		unbind,
		State.on("gems", function()
			if tab == "quirks" then
				showDetail()
			end
		end)
	)
	-- a craving's Buy button wakes up (or dims) as the coins come and go
	local lastShort: boolean? = nil
	table.insert(
		unbind,
		State.on("coins", function()
			local v = selected and State.villager(selected)
			if not v or not v.wish or v.wish.kind ~= "food" then
				lastShort = nil
				return
			end
			local price = Life.wishPrice(profileView(), selected :: string) or 0
			local short = (State.data.coins or 0) < price
			if lastShort ~= nil and short ~= lastShort then
				showDetail()
			end
			lastShort = short
		end)
	)
end

-- a change of look builds what's open again in the new one: the stage's backdrop keeps its own
-- colours, and a row's shading is made for a look
Kit.onTheme(function()
	if panel then
		refreshList()
		showDetail()
	end
end)

return Residents
