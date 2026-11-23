-- The villagers screen: everyone in town, how they feel, where they work and sleep, who their
-- friends are, what they like to eat. Change their job or bed, feed them, restyle them.
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
local Jobs = require(Shared.Data.Jobs)
local Colors = require(Shared.Util.Colors)
local Text = require(Shared.Util.Text)

local Kit = require(script.Parent.Kit)
local Icons = require(script.Parent.Icons)
local Toasts = require(script.Parent.Toasts)
local ModelPreview = require(script.Parent.ModelPreview)
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
				then Text.fill("{name} works here now (they'd swap)", { name = worker })
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

local function feed(vid: string)
	local inv = State.data.inv and State.data.inv.food or {}
	local options = {}
	local v = State.villager(vid)
	for _, f in Foods.list do
		local n = inv[f.id]
		if n and n > 0 then
			local known = v and v.known[f.id]
			local sub = Text.fill("You have {n}", { n = n })
			if known == "love" then
				sub ..= ". Their favourite!"
			elseif known == "hate" then
				sub ..= ". They can't stand it."
			end
			table.insert(options, {
				label = f.name,
				sub = sub,
				item = f.id,
				color = Colors.fromHex(f.color),
				fn = function()
					task.spawn(function()
						local ok, result = Remotes.fn("VillagerFeed"):InvokeServer(vid, f.id)
						if ok and v then
							if result.reaction == "love" then
								Toasts.show(
									Text.fill("{name} loves {food}!", { name = v.name, food = f.name:lower() }),
									"good"
								)
							elseif result.reaction == "hate" then
								Toasts.show(
									Text.fill("{name} can't stand {food}.", { name = v.name, food = f.name:lower() }),
									"warn"
								)
							else
								Toasts.show(Text.fill("{name} enjoyed that.", { name = v.name }), "info")
							end
						elseif not ok and result then
							Toasts.show(result, "warn")
						end
					end)
				end,
			})
		end
	end
	if #options == 0 then
		Toasts.show("You have no food. The shop in the plaza sells some.", "info")
		return
	end
	choose("Feed them", options)
end

-- where the stats start on the stage: the villager stands to the left of this
local INFO_X = 400

-- A stat: a small soft label over its value.
local function stat(parent: Instance, label: string, value: string, order: number, color: Color3?)
	local cell = Kit.box({ Parent = parent, LayoutOrder = order })
	Kit.text(label, { Parent = cell, Size = UDim2.new(1, 0, 0, 16), TextSize = 13, Color = T.InkSoft })
	Kit.text(value, {
		Parent = cell,
		Size = UDim2.new(1, -8, 0, 40),
		Position = UDim2.fromOffset(0, 18),
		TextSize = 16,
		Font = Kit.Fonts.Bold,
		Tint = color,
		AlignY = Enum.TextYAlignment.Top,
	})
end

-- The About tab: how they feel, where they work and sleep, their birthday, what they eat.
local function about(parent: Frame, vid: string, v: any, p: any)
	Kit.text(
		Text.fill("Feeling {word} ({n}%)", { word = moodWord(v.mood), n = math.floor(v.mood) }),
		{ Parent = parent, Size = UDim2.new(1, 0, 0, 22), TextSize = 17, Font = Kit.Fonts.Bold }
	)
	Kit.bar({
		Parent = parent,
		Size = UDim2.new(1, -4, 0, 14),
		Position = UDim2.fromOffset(0, 28),
	}, v.mood / 100, if v.mood >= 50 then T.Green else T.Coral)
	local grid = Kit.box({ Parent = parent, Size = UDim2.new(1, 0, 1, -58), Position = UDim2.fromOffset(0, 58) })
	Kit.grid(grid, UDim2.new(0.5, -8, 0, 62), 8)
	local w = City.jobOf(p, vid)
	stat(
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
	stat(grid, "Sleeps in", bedText, 2, bedColor)
	stat(
		grid,
		"Birthday",
		Text.fill("{season} {day}", { season = Schema.Seasons[v.bday.s] or "Spring", day = v.bday.d }),
		3
	)
	local likes = {}
	for food, r in v.known or {} do
		local f = Foods.get(food)
		if f and r == "love" then
			table.insert(likes, "loves " .. f.name:lower())
		elseif f and r == "hate" then
			table.insert(likes, "can't stand " .. f.name:lower())
		end
	end
	stat(grid, "Food", if #likes > 0 then table.concat(likes, ", ") else "Feed them to find out", 4)
end

-- The Friends tab: each friendship as an arrow tag (how close they are, or their romance), the
-- other villager's name and a bar.
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
		Kit.text("Nobody else lives here yet.", { Parent = friends, TextSize = 16, Color = T.InkSoft, LayoutOrder = 1 })
	end
	for i, r in rows do
		local _, levelName = Relationships.level(r.s)
		local bond = Life.bond(p, vid, r.id)
		local row = Kit.box({ Parent = friends, Size = UDim2.new(1, -12, 0, 34), LayoutOrder = i })
		local tagText = if r.q then "Not speaking" elseif bond then Life.BondNames[bond] else levelName
		local col = if r.q
			then Color3.fromRGB(255, 176, 166)
			elseif bond then Color3.fromRGB(255, 168, 204)
			elseif r.s >= 55 then Color3.fromRGB(255, 214, 72)
			elseif r.s >= 10 then Color3.fromRGB(176, 228, 146)
			elseif r.s > -10 then Color3.fromRGB(214, 226, 240)
			else Color3.fromRGB(204, 192, 240)
		Kit.arrowTag(tagText, col, {
			Parent = row,
			Height = 26,
			Position = UDim2.new(0, 0, 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5),
		})
		Kit.text(r.o.name, {
			Parent = row,
			Size = UDim2.new(0.3, 0, 1, 0),
			Position = UDim2.fromScale(0.42, 0),
			TextSize = 17,
			Font = Kit.Fonts.Bold,
		})
		Kit.bar({
			Parent = row,
			Size = UDim2.new(0.28, -8, 0, 12),
			Position = UDim2.new(0.72, 0, 0.5, -6),
		}, (r.s + 100) / 200, if r.s >= 0 then T.Pink else T.BlueDark)
	end
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
		Kit.text("Nobody lives here yet. Press Create to make someone.", {
			Parent = detail,
			TextSize = 20,
			Color = T.InkSoft,
			Size = UDim2.new(1, -80, 0, 60),
			Position = UDim2.fromOffset(40, 40),
		})
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
		Radius = false,
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
	-- the name, and how close they are to you
	Kit.title(v.name .. (if v.isYou then "  (you)" else ""), {
		Parent = info,
		TextSize = 40,
		Size = UDim2.new(1, -140, 0, 48),
		Wrap = false,
	})
	local heart = Kit.frame({
		Name = "Heart",
		Parent = info,
		Size = UDim2.fromOffset(132, 32),
		Position = UDim2.new(1, 0, 0, 8),
		AnchorPoint = Vector2.new(1, 0),
		Color = T.Pink,
		Radius = "pill",
	})
	Kit.title(Text.fill("Heart level {n}", { n = v.heart or 1 }), {
		Parent = heart,
		Size = UDim2.fromScale(1, 1),
		TextSize = 15,
		Color = T.White,
		AlignX = Enum.TextXAlignment.Center,
	})
	Kit.text(if pers then pers.name .. ". " .. pers.blurb else "", {
		Parent = info,
		TextSize = 16,
		Color = T.InkSoft,
		Size = UDim2.new(1, 0, 0, 22),
		Position = UDim2.fromOffset(0, 50),
		Wrap = false,
	}).TextTruncate =
		Enum.TextTruncate.AtEnd

	-- what you can do, as round buttons along the bottom
	local actions = Kit.box({
		Name = "Actions",
		Parent = info,
		Size = UDim2.new(1, 0, 0, 88),
		Position = UDim2.new(0, 0, 1, -88),
	})
	Kit.list(actions, 10, true)
	local function action(icon: string, label: string, color: Color3, order: number, fn: () -> ())
		Kit.iconButton(icon, label, {
			Parent = actions,
			Size = UDim2.fromOffset(78, 86),
			Color = color,
			LayoutOrder = order,
			Wobble = 0,
		}, fn)
	end
	action("pot", "Feed", T.Green, 1, function()
		feed(vid)
	end)
	action("briefcase", "Job", T.Blue, 2, function()
		pickJob(vid)
	end)
	action("bed", "Bed", T.Purple, 3, function()
		pickBed(vid)
	end)
	action("shirt", "Look", T.Orange, 4, function()
		local Hud = require(script.Parent.Hud)
		Hud.open("Creator", { mode = "edit", vid = vid })
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
	local bottom = 100
	local wishText = Life.wishText(p, vid)
	if wishText and v.wish then
		local _, wishInside = Kit.row({
			Name = "Wish",
			Parent = info,
			Size = UDim2.new(1, 0, 0, 56),
			Height = 56,
			Marker = "heart",
			MarkerColor = T.Orange,
		})
		-- the wish can run to two lines
		Kit.text(wishText, {
			Name = "Title",
			Parent = wishInside,
			Size = UDim2.new(1, -(76 + 170), 1, -8),
			Position = UDim2.fromOffset(76, 4),
			TextSize = 15,
			Font = Kit.Fonts.Bold,
			ZIndex = 2,
		})
		local wishRow = wishInside.Parent :: GuiObject
		wishRow.Position = UDim2.new(0, 0, 1, -(bottom + 56))
		local kind = v.wish.kind
		local label, fn
		if kind == "food" then
			label, fn = "Feed", function()
				feed(vid)
			end
		elseif kind == "friend" then
			label, fn = "Introduce", function()
				call("WishGrant", vid, "friend", v.wish.arg)
			end
		elseif kind == "look" then
			label, fn =
				"New look", function()
					local Hud = require(script.Parent.Hud)
					Hud.open("Creator", { mode = "edit", vid = vid })
				end
		else
			label, fn = "Have a chat", function()
				call("WishGrant", vid, "cheer")
			end
		end
		Kit.button(label, {
			Parent = wishInside,
			Size = UDim2.fromOffset(132, 38),
			Position = UDim2.new(1, -26, 0.5, 0),
			AnchorPoint = Vector2.new(1, 0.5),
			Color = T.Orange,
			TextSize = 15,
			ZIndex = 3,
		}, fn)
		bottom += 66
	end

	-- the tab's own part, between the name and the buttons
	local content = Kit.box({
		Name = "Content",
		Parent = info,
		Size = UDim2.new(1, 0, 1, -(86 + bottom + 8)),
		Position = UDim2.fromOffset(0, 86),
	})
	if tab == "friends" then
		friendsOf(content, vid, p)
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
			LeftSpace = 64,
			RightSpace = 46,
			Selected = v.id == selected,
		}, function()
			selected = v.id
			refreshList()
			showDetail()
		end)
		local _ = row
		-- the villager's face, on a disc of their own colour (the user: "Put the villager
		-- portrait in place of the blue lines")
		-- (a circle with a border: "make portraits a circle with a border instead of a square")
		local own = Colors.fromHex(v.color)
		local face = Kit.portrait({
			Parent = inner,
			Size = 46,
			Position = UDim2.new(0, 26, 0.5, -23),
			Color = own:Lerp(T.Cream, 0.5),
			Border = own:Lerp(T.White, 0.35),
			BorderWidth = 2,
			ZIndex = 3,
		})
		portraitInto(face, v.id)
		-- how they feel, as a dot at the right end
		Kit.frame({
			Name = "Mood",
			Parent = inner,
			Size = UDim2.fromOffset(14, 14),
			Position = UDim2.new(1, -40, 0.5, -7),
			Color = if v.mood >= 60 then T.Green elseif v.mood >= 40 then T.Yellow else T.Coral,
			Radius = 2,
			ZIndex = 3,
		}).Rotation =
			45 -- a diamond
	end
	Kit.text(
		Text.fill("{n} of {max}", { n = #list, max = Tuning.Villagers.Max }),
		{ Parent = listFrame, TextSize = 14, Color = T.InkSoft, LayoutOrder = 999, AlignX = Enum.TextXAlignment.Center }
	)
end

function Residents.isOpen(): boolean
	return panel ~= nil
end

function Residents.close()
	closePopup()
	for _, u in unbind do
		u()
	end
	unbind = {}
	if panel then
		panel.root:Destroy()
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
		Tabs = { { id = "about", name = "About" }, { id = "friends", name = "Friends" } },
		OnTab = function(id: string)
			tab = id
			showDetail()
		end,
	})
	listFrame = Kit.scroll({ Parent = panel.body, Size = UDim2.new(0, 262, 1, 0) })
	Kit.list(listFrame, 8)
	-- the stage cuts the villager and the fade to its box. A plain frame: inside a CanvasGroup
	-- the villager's 3D picture comes out pale (the moving backdrop has its own, behind them)
	detail = Kit.frame({
		Name = "Stage",
		Parent = panel.body,
		Size = UDim2.new(1, -278, 1, 0),
		Position = UDim2.fromOffset(278, 0),
		Color = T.PaperDark,
		Radius = false,
		Clips = true,
	})
	Kit.popIn(panel.root)
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
end

return Residents
