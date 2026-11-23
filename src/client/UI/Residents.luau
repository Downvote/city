-- The villagers panel: everyone in town, how they feel, where they work and sleep, who their
-- friends are, what they like to eat. Change their job or bed, feed them, restyle them.

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
local Toasts = require(script.Parent.Toasts)
local ModelPreview = require(script.Parent.ModelPreview)
local State = require(script.Parent.Parent.Controllers.State)

local Residents = {}

local T = Kit.Theme
local panel: any = nil
local selected: string? = nil
local listFrame: ScrollingFrame
local detail: Frame
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

-- A small list of choices floating over the panel.
local function choose(title: string, options: { { label: string, sub: string?, fn: () -> () } })
	closePopup()
	local p = Kit.frame({
		Parent = panel.root,
		Size = UDim2.fromOffset(360, 360),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Stroke = T.YellowDark,
		Radius = 14,
	})
	p.ZIndex = 30
	popup = p
	Kit.pad(p, 12, 10)
	Kit.title(title, { Parent = p, Size = UDim2.new(1, -40, 0, 28), TextSize = 20 })
	Kit.button("X", {
		Parent = p,
		Size = UDim2.fromOffset(30, 30),
		Position = UDim2.new(1, -30, 0, 0),
		Color = T.Coral,
		TextSize = 16,
	}, closePopup)
	local scroll = Kit.scroll({ Parent = p, Size = UDim2.new(1, 0, 1, -38), Position = UDim2.fromOffset(0, 36) })
	Kit.list(scroll, 6)
	if #options == 0 then
		Kit.text("Nothing to pick from yet.", { Parent = scroll, TextSize = 16, Color = T.InkSoft })
	end
	for i, o in options do
		local b = Kit.new("TextButton", {
			Text = "",
			AutoButtonColor = true,
			BackgroundColor3 = T.White,
			Size = UDim2.new(1, -8, 0, if o.sub then 52 else 38),
			LayoutOrder = i,
			Parent = scroll,
		})
		Kit.corner(b, 10)
		Kit.stroke(b, T.Ink, 2)
		Kit.text(o.label, {
			Parent = b,
			Size = UDim2.new(1, -16, 0, 22),
			Position = UDim2.fromOffset(8, 6),
			TextSize = 17,
			Font = Kit.Fonts.Bold,
		})
		if o.sub then
			Kit.text(o.sub, {
				Parent = b,
				Size = UDim2.new(1, -16, 0, 18),
				Position = UDim2.fromOffset(8, 28),
				TextSize = 14,
				Color = T.InkSoft,
			})
		end
		b.Activated:Connect(function()
			closePopup()
			o.fn()
		end)
	end
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

local function showDetail()
	for _, c in detail:GetChildren() do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
	local vid = selected
	local v = vid and State.villager(vid)
	if not vid or not v then
		Kit.text(
			"Nobody lives here yet. Press New villager to make someone.",
			{ Parent = detail, TextSize = 18, Color = T.InkSoft, Size = UDim2.new(1, 0, 0, 50) }
		)
		return
	end
	local p = profileView()
	local pers = Personalities.get(v.pers)
	local portrait = Kit.frame({
		Parent = detail,
		Size = UDim2.fromOffset(170, 220),
		Color = Colors.fromHex(v.color),
		Transparency = 0.6,
		Radius = 18,
		-- rounded clipping: the villager's picture is cut to the card's round corners
		Clips = true,
	})
	task.spawn(function()
		local model = Remotes.fn("VillagerFocus"):InvokeServer(vid)
		if model and portrait.Parent then
			ModelPreview.fromModel(model, { Parent = portrait })
		end
	end)
	local info = Kit.box({ Parent = detail, Size = UDim2.new(1, -186, 0, 220), Position = UDim2.fromOffset(186, 0) })
	Kit.list(info, 4)
	-- the name, and how close they are to you
	local nameRow = Kit.box({ Parent = info, Size = UDim2.new(1, 0, 0, 34), LayoutOrder = 1 })
	Kit.title(
		v.name .. (if v.isYou then "  (you)" else ""),
		{ Parent = nameRow, TextSize = 28, Size = UDim2.new(1, -124, 1, 0) }
	)
	local heart = Kit.frame({
		Name = "Heart",
		Parent = nameRow,
		Size = UDim2.fromOffset(124, 30),
		Position = UDim2.new(1, 0, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
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
	Kit.text(
		if pers then pers.name .. ". " .. pers.blurb else "",
		{ Parent = info, TextSize = 15, Color = T.InkSoft, LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 36) }
	)
	Kit.text(
		Text.fill("Feeling {word} ({n}%)", { word = moodWord(v.mood), n = math.floor(v.mood) }),
		{ Parent = info, TextSize = 16, Font = Kit.Fonts.Bold, LayoutOrder = 3 }
	)
	bar(info, v.mood / 100, if v.mood >= 50 then T.Green else T.Coral, 4)
	local w = City.jobOf(p, vid)
	local jobText = if w
		then Text.fill("{job} at the {place}, skill {n}", { job = w.job.name, place = w.def.name:lower(), n = v.lv })
		else "No job yet"
	Kit.text(jobText, { Parent = info, TextSize = 16, LayoutOrder = 5 })
	local bedText = if v.bed and State.plan.items[v.bed] then "Has a bed" else "No bed! Build one."
	Kit.text(bedText, { Parent = info, TextSize = 16, LayoutOrder = 6, Color = if v.bed then T.Ink else T.CoralDark })
	Kit.text(
		Text.fill("Birthday: {season} {day}", { season = Schema.Seasons[v.bday.s] or "Spring", day = v.bday.d }),
		{ Parent = info, TextSize = 15, Color = T.InkSoft, LayoutOrder = 7 }
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
	Kit.text(
		if #likes > 0 then "Food: " .. table.concat(likes, ", ") else "Food: feed them to find out what they like",
		{ Parent = info, TextSize = 15, Color = T.InkSoft, LayoutOrder = 8 }
	)

	local actions = Kit.box({ Parent = detail, Size = UDim2.new(1, 0, 0, 44), Position = UDim2.fromOffset(0, 230) })
	Kit.list(actions, 6, true)
	local function action(label: string, color: Color3, fn: () -> (), textColor: Color3?)
		local b = Kit.button(label, {
			Parent = actions,
			Size = UDim2.fromOffset(0, 40),
			AutomaticSize = Enum.AutomaticSize.X,
			TextSize = 16,
			Color = color,
			TextColor = textColor,
		})
		Kit.pad(b, 12, 0)
		b.Activated:Connect(fn)
	end
	action("Feed", T.Green, function()
		feed(vid)
	end)
	action("Job", T.Blue, function()
		pickJob(vid)
	end)
	action("Bed", T.Purple, function()
		pickBed(vid)
	end)
	action("Change look", T.Yellow, function()
		local Hud = require(script.Parent.Hud)
		Hud.open("Creator", { mode = "edit", vid = vid })
	end, T.Ink)
	local confirm = false
	action("Move out", T.Coral, function()
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

	-- their wish, in a speech bubble, with what you can do about it
	local friendsTop = 284
	local wishText = Life.wishText(p, vid)
	if wishText and v.wish then
		local _, wishBody = Kit.bubble({
			Name = "Wish",
			Parent = detail,
			Size = UDim2.new(1, -8, 0, 58),
			Position = UDim2.fromOffset(4, 286),
			Tail = "up",
			TailAt = 0.12,
			TailSize = 16,
			Radius = "pill",
		})
		local row = Kit.box({ Parent = wishBody, Size = UDim2.fromScale(1, 1) })
		Kit.pad(row, 20, 0)
		local kind = v.wish.kind
		local wishLabel = Kit.text(wishText, {
			Parent = row,
			Size = UDim2.new(1, -146, 1, 0),
			Position = UDim2.fromOffset(4, 0),
			TextSize = 16,
			Font = Kit.Fonts.Bold,
		})
		wishLabel.TextYAlignment = Enum.TextYAlignment.Center
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
			Parent = row,
			Size = UDim2.fromOffset(132, 38),
			Position = UDim2.new(1, 0, 0.5, 0),
			AnchorPoint = Vector2.new(1, 0.5),
			Color = T.Orange,
			TextSize = 15,
			Radius = "pill",
		}, fn)
		friendsTop = 356
	end

	-- friends and quarrels
	local friends = Kit.scroll({
		Parent = detail,
		Size = UDim2.new(1, 0, 1, -(friendsTop + 2)),
		Position = UDim2.fromOffset(0, friendsTop),
	})
	Kit.list(friends, 4)
	Kit.title("Friends", { Parent = friends, TextSize = 20, LayoutOrder = 0, Size = UDim2.new(1, 0, 0, 26) })
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
		Kit.text("Nobody else lives here yet.", { Parent = friends, TextSize = 15, Color = T.InkSoft, LayoutOrder = 1 })
	end
	-- each friendship as an arrow tag pointing at them: how close they are, or their romance
	for i, r in rows do
		local _, levelName = Relationships.level(r.s)
		local bond = Life.bond(p, vid, r.id)
		local row = Kit.box({ Parent = friends, Size = UDim2.new(1, -8, 0, 32), LayoutOrder = i })
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
			Size = UDim2.new(0.34, 0, 1, 0),
			Position = UDim2.fromScale(0.44, 0),
			TextSize = 16,
			Font = Kit.Fonts.Bold,
		})
		Kit.bar({
			Parent = row,
			Size = UDim2.new(0.22, -8, 0, 12),
			Position = UDim2.new(0.78, 0, 0.5, -6),
		}, (r.s + 100) / 200, if r.s >= 0 then T.Pink else T.BlueDark)
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
		local on = v.id == selected
		local card = Kit.new("TextButton", {
			Text = "",
			AutoButtonColor = true,
			BackgroundColor3 = if on then T.PaperDark else T.White,
			Size = UDim2.new(1, -8, 0, 62),
			LayoutOrder = i,
			Parent = listFrame,
		})
		Kit.corner(card, 12)
		Kit.stroke(card, if on then T.Blue else T.Ink, if on then 3 else 2)
		Kit.frame({
			Parent = card,
			Size = UDim2.fromOffset(10, 46),
			Position = UDim2.fromOffset(8, 8),
			Color = Colors.fromHex(v.color),
			Radius = 5,
		})
		Kit.text(v.name, {
			Parent = card,
			Size = UDim2.new(1, -30, 0, 22),
			Position = UDim2.fromOffset(26, 6),
			TextSize = 17,
			Font = Kit.Fonts.Bold,
		})
		local w = City.jobOf(p, v.id)
		Kit.text(if w then w.job.name else "No job", {
			Parent = card,
			Size = UDim2.new(1, -30, 0, 16),
			Position = UDim2.fromOffset(26, 28),
			TextSize = 13,
			Color = T.InkSoft,
		})
		Kit.bar({
			Parent = card,
			Size = UDim2.new(1, -44, 0, 10),
			Position = UDim2.fromOffset(26, 47),
		}, v.mood / 100, if v.mood >= 50 then T.Green else T.Coral)
		card.Activated:Connect(function()
			selected = v.id
			refreshList()
			showDetail()
		end)
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
	panel = Kit.panel("Villagers", UDim2.fromOffset(920, 600), Residents.close, "people", Kit.Theme.Green)
	listFrame = Kit.scroll({ Parent = panel.body, Size = UDim2.new(0, 250, 1, 0) })
	Kit.list(listFrame, 6)
	detail = Kit.box({ Parent = panel.body, Size = UDim2.new(1, -266, 1, 0), Position = UDim2.fromOffset(266, 0) })
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
