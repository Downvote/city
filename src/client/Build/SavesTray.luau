-- Build mode's Saves page (the user: "add loading and saving of plots"): a card for each slot in a
-- row across the tray. A save shows its name (type over it to rename it), when it was saved and how
-- many pieces it holds, with Load, Save over and Delete; an empty slot saves the plot as it is,
-- under the name typed into it; the slots past the free ones are locked and offer More Saves.
-- Loading, saving over and deleting each ask first, in a small dialog that says what it will cost
-- and that Undo can take a load back. Everything is asked of the server (Services/Saves, through
-- BuildSaves), which keeps the saves and checks it all again; the page shows its last answer.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Tuning = require(Shared.Config.Tuning)
local Remotes = require(Shared.Net.Remotes)
local Text = require(Shared.Util.Text)

local State = require(script.Parent.Parent.Controllers.State)
local Purchase = require(script.Parent.Parent.Controllers.Purchase)
local Kit = require(script.Parent.Parent.UI.Kit)
local Icons = require(script.Parent.Parent.UI.Icons)
local Toasts = require(script.Parent.Parent.UI.Toasts)

local SavesTray = {}

local T = Kit.Theme

local CARD_W, CARD_H = 270, 152
local DIALOG = UDim2.fromOffset(540, 300)

-- the server's last word on the page: { slots, max, free, saves = { { slot, name, t, pieces } } }
local page: any = nil
local asking = false
local shown: TrayKit? = nil -- the tray that drew the page last, to draw it again when it changes
local typed: { [number]: string } = {} -- names typed into empty slots, kept while the tray redraws

-- What BuildUI lends the page.
export type TrayKit = {
	row: (height: number?) -> ScrollingFrame,
	stack: () -> Frame,
	note: (parent: Instance, icon: string, color: Color3, title: string, lines: { string }, order: number?) -> Frame,
	refresh: () -> (), -- draws the page again, if it is still the one showing
	height: number,
}

local function ask(action: string, slot: number?, name: string?): (boolean, any)
	local called, ok, answer = pcall(function()
		return Remotes.fn("BuildSaves"):InvokeServer(action, slot, name)
	end)
	if not called then
		return false, "Couldn't reach the server. Try again."
	end
	return ok == true, answer
end

-- When something was saved, in a few plain words.
function SavesTray.ago(t: number, now: number?): string
	local d = math.max(0, (now or os.time()) - t)
	if d < 90 then
		return "Saved just now"
	elseif d < 3600 then
		return Text.fill("Saved {n} minutes ago", { n = math.floor(d / 60 + 0.5) })
	elseif d < 7200 then
		return "Saved an hour ago"
	elseif d < 86400 then
		return Text.fill("Saved {n} hours ago", { n = math.floor(d / 3600) })
	elseif d < 172800 then
		return "Saved yesterday"
	end
	return Text.fill("Saved {n} days ago", { n = math.floor(d / 86400) })
end

local function saveIn(slot: number): any?
	for _, e in (page and page.saves) or {} do
		if e.slot == slot then
			return e
		end
	end
	return nil
end

-- Asks the server for the page, then draws it again.
function SavesTray.fetch(kit: TrayKit?)
	task.spawn(function()
		local ok, answer = ask("list")
		if ok and type(answer) == "table" then
			page = answer
		elseif not page then
			page = {
				slots = Tuning.Passes.FreeSlots,
				max = Tuning.Passes.MoreSlots,
				free = Tuning.Passes.FreeSlots,
				saves = {},
			}
		end
		if kit then
			kit.refresh()
		end
	end)
end

-- (for the previews and the simulation: what the page shows now)
function SavesTray.page(): any
	return page
end

-- A small dialog that asks before something big: its title, what will happen, and the button that
-- does it (in `color`) beside the way back.
local function confirm(title: string, lines: { string }, yes: string, color: Color3, onYes: () -> ())
	local p: any
	p = Kit.panel(title, DIALOG, function()
		Kit.closePanel(p)
	end, nil, color, { Dialog = true })
	p.root.Name = "SaveConfirm"
	local words = Kit.box({ Name = "Words", Parent = p.body, Size = UDim2.new(1, 0, 1, -58) })
	Kit.list(words, 10)
	Kit.mark(words)
	for i, line in lines do
		Kit.text(line, {
			Parent = words,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			TextSize = if i == 1 then 18 else 16,
			Color = if i == 1 then T.Ink else T.InkSoft,
			LayoutOrder = i,
		})
	end
	local buttons = Kit.box({
		Name = "Buttons",
		Parent = p.body,
		Size = UDim2.new(1, 0, 0, 44),
		Position = UDim2.new(0, 0, 1, -44),
	})
	Kit.mark(buttons)
	Kit.button("Not now", {
		Name = "Cancel",
		Parent = buttons,
		Size = UDim2.fromOffset(130, 42),
		Position = UDim2.new(1, -170, 0, 0),
		AnchorPoint = Vector2.new(1, 0),
		Color = T.Card,
		TextColor = T.Ink,
		TextSize = 18,
	}, function()
		Kit.closePanel(p)
	end)
	Kit.button(yes, {
		Name = "Confirm",
		Parent = buttons,
		Size = UDim2.fromOffset(150, 42),
		Position = UDim2.new(1, 0, 0, 0),
		AnchorPoint = Vector2.new(1, 0),
		Color = color,
		TextSize = 18,
	}, function()
		Kit.closePanel(p)
		onYes()
	end)
end

-- The coins a load comes to, in a line for the dialog.
local function costLine(cost: number): string
	if cost > 0 then
		return Text.fill(
			"It costs {n} coins, which is what this build needs less what yours sells back for.",
			{ n = Text.commas(cost) }
		)
	elseif cost < 0 then
		return Text.fill(
			"You get {n} coins back, since yours sells for more than this one costs.",
			{ n = Text.commas(-cost) }
		)
	end
	return "It costs nothing, since the two come to the same."
end

local function act(kit: TrayKit, action: string, slot: number, name: string?, done: ((any) -> ())?)
	if asking then
		return
	end
	asking = true
	task.spawn(function()
		local ok, answer = ask(action, slot, name)
		asking = false
		if not ok then
			Toasts.show(if type(answer) == "string" then answer else "That didn't work. Try again.", "warn")
			return
		end
		if type(answer) == "table" then
			page = answer.page or (if answer.saves then answer else page)
		end
		if done then
			done(answer)
		end
		kit.refresh()
	end)
end

-- Load: asks the server what it would come to first, then asks the player.
local function load(kit: TrayKit, e: any)
	if asking then
		return
	end
	asking = true
	task.spawn(function()
		local ok, quote = ask("quote", e.slot)
		asking = false
		if not ok or type(quote) ~= "table" then
			Toasts.show(if type(quote) == "string" then quote else "That didn't work. Try again.", "warn")
			return
		end
		local short = quote.cost - (State.data.coins or 0)
		if quote.cost > 0 and short > 0 then
			Toasts.show(Text.fill("You need {n} more coins to load that one.", { n = Text.commas(short) }), "warn")
			return
		end
		local lines = { "Everything on your plot now makes way for this build.", costLine(quote.cost) }
		if quote.skipped == 1 then
			table.insert(lines, "One piece doesn't fit your plot as it is now, so it will be left out.")
		elseif quote.skipped > 1 then
			table.insert(
				lines,
				Text.fill(
					"{n} pieces don't fit your plot as it is now, so they will be left out.",
					{ n = quote.skipped }
				)
			)
		end
		table.insert(lines, "Undo takes the whole load back, as long as you stay in this server.")
		confirm(Text.fill("Load {name}?", { name = e.name }), lines, "Load it", T.Blue, function()
			act(kit, "load", e.slot, nil, function(answer)
				local skipped = if type(answer) == "table" then answer.skipped or 0 else 0
				Toasts.show(
					if skipped > 0
						then Text.fill("Loaded {name}. {n} pieces were left out.", { name = e.name, n = skipped })
						else Text.fill("Loaded {name}.", { name = e.name }),
					"good"
				)
			end)
		end)
	end)
end

local function slotCard(kit: TrayKit, row: Instance, i: number, more: number?)
	local e = saveIn(i)
	local locked = i > ((page and page.slots) or Tuning.Passes.FreeSlots)
	local card = Kit.frame({
		Name = "Slot" .. i,
		Parent = row,
		Size = UDim2.fromOffset(CARD_W, CARD_H),
		Color = T.Card,
		Radius = 10,
		LayoutOrder = i,
	})
	Kit.rim(card, Kit.edgeOf(T.Card), 1)
	card:SetAttribute("Slot", i)
	-- the slot's number in yellow, and when it was saved at the right
	Kit.title(Kit.index(i), {
		Name = "Index",
		Parent = card,
		Size = UDim2.fromOffset(40, 20),
		Position = UDim2.fromOffset(12, 8),
		TextSize = 18,
		Tint = T.Yellow,
		Wrap = false,
	})
	if locked and not e then
		-- the slots that come with More Saves, on one card
		Icons.make("lock", 30, {
			Name = "Lock",
			Parent = card,
			Position = UDim2.new(0.5, -15, 0, 16),
			Color = T.InkSoft,
			Hole = T.Card,
		})
		Kit.title("More Saves", {
			Parent = card,
			Size = UDim2.new(1, -24, 0, 22),
			Position = UDim2.fromOffset(12, 52),
			TextSize = 18,
			AlignX = Enum.TextXAlignment.Center,
			Wrap = false,
		})
		Kit.text(
			Text.fill("{n} more slots, for {all} builds in all.", {
				n = more or 1,
				all = Tuning.Passes.MoreSlots,
			}),
			{
				Parent = card,
				Size = UDim2.new(1, -24, 0, 18),
				Position = UDim2.fromOffset(12, 76),
				TextSize = 14,
				Color = T.InkSoft,
				AlignX = Enum.TextXAlignment.Center,
				Wrap = false,
			}
		)
		Kit.button("Unlock", {
			Name = "Unlock",
			Parent = card,
			Size = UDim2.new(1, -24, 0, 34),
			Position = UDim2.new(0, 12, 1, -46),
			Color = T.Yellow,
			TextColor = T.Dark,
			TextSize = 17,
		}, function()
			Purchase.prompt("saveslots")
		end)
		return
	end
	if e then
		Kit.text(SavesTray.ago(e.t), {
			Name = "When",
			Parent = card,
			Size = UDim2.new(1, -64, 0, 18),
			Position = UDim2.new(1, -12, 0, 9),
			AnchorPoint = Vector2.new(1, 0),
			TextSize = 13,
			Font = Kit.Fonts.Bold,
			Color = T.InkSoft,
			AlignX = Enum.TextXAlignment.Right,
			Wrap = false,
		})
	end
	-- the name: type over it to rename a save, or to name the build an empty slot will keep
	local box = Kit.textbox(if e then "Name this build" else Text.fill("Build {n}", { n = i }), {
		Name = "SaveName",
		Parent = card,
		Text = if e then e.name else (typed[i] or ""),
		TextSize = 17,
		Size = UDim2.new(1, -24, 0, 32),
		Position = UDim2.fromOffset(12, 34),
	})
	box.FocusLost:Connect(function()
		local text = box.Text
		if e then
			if text ~= "" and text ~= e.name then
				act(kit, "rename", i, text)
			end
		else
			typed[i] = text
		end
	end)
	Kit.text(
		if e
			then (if e.pieces == 1 then "1 piece" else Text.fill("{n} pieces", { n = Text.commas(e.pieces) }))
			else "Empty",
		{
			Name = "Pieces",
			Parent = card,
			Size = UDim2.new(1, -24, 0, 18),
			Position = UDim2.fromOffset(14, 72),
			TextSize = 15,
			Color = T.InkSoft,
			Wrap = false,
		}
	)
	local buttons = Kit.box({
		Name = "Buttons",
		Parent = card,
		Size = UDim2.new(1, -24, 0, 34),
		Position = UDim2.new(0, 12, 1, -46),
	})
	Kit.list(buttons, 6, true)
	local function button(
		name: string,
		text: string,
		w: number,
		color: Color3,
		ink: Color3?,
		order: number,
		fn: () -> ()
	)
		Kit.button(text, {
			Name = name,
			Parent = buttons,
			Size = UDim2.fromOffset(w, 34),
			Color = color,
			TextColor = ink,
			TextSize = 16,
			LayoutOrder = order,
		}, fn)
	end
	if not e then
		button("SaveHere", "Save here", CARD_W - 24, T.Green, nil, 1, function()
			act(kit, "save", i, typed[i] or "", function(answer)
				typed[i] = nil
				local saved = nil
				for _, s in (type(answer) == "table" and answer.saves) or {} do
					if s.slot == i then
						saved = s
					end
				end
				Toasts.show(Text.fill("Saved as {name}.", { name = if saved then saved.name else "a build" }), "good")
			end)
		end)
		return
	end
	button("Load", "Load", 66, T.Blue, nil, 1, function()
		load(kit, e)
	end)
	if not locked then
		button("SaveOver", "Save over", 100, T.Orange, T.Dark, 2, function()
			confirm(
				Text.fill("Save over {name}?", { name = e.name }),
				{
					"Your plot as it is now takes this slot.",
					"The build saved here can't be brought back after.",
				},
				"Save over",
				T.Orange,
				function()
					act(kit, "save", i, nil, function()
						Toasts.show(Text.fill("Saved over {name}.", { name = e.name }), "good")
					end)
				end
			)
		end)
	end
	button("Delete", "Delete", 68, T.Coral, T.Dark, 3, function()
		confirm(
			Text.fill("Delete {name}?", { name = e.name }),
			{
				"This build goes for good.",
				"Your plot stays just as it is.",
			},
			"Delete",
			T.Red,
			function()
				act(kit, "delete", i, nil, function()
					Toasts.show(Text.fill("Deleted {name}.", { name = e.name }), "info")
				end)
			end
		)
	end)
end

-- The page: a card a slot, the free ones first, then the ones More Saves unlocks.
function SavesTray.tray(kit: TrayKit)
	shown = kit
	if not page then
		local stack = kit.stack()
		kit.note(stack, "save", T.Blue, "Your saved builds", { "Looking them up." }, 1)
		SavesTray.fetch(kit)
		return
	end
	local row = kit.row(kit.height)
	-- the player's slots, and any save kept in a slot they no longer have; then one card for the
	-- empty slots More Saves would open
	local slots = page.slots or Tuning.Passes.FreeSlots
	local lockedAt, more = nil :: number?, 0
	for i = 1, page.max or Tuning.Passes.MoreSlots do
		if i <= slots or saveIn(i) then
			slotCard(kit, row, i)
		else
			lockedAt = lockedAt or i
			more += 1
		end
	end
	if lockedAt then
		slotCard(kit, row, lockedAt, more)
	end
end

-- The passes changed (More Saves bought): the page is asked for again.
State.on("passes", function()
	if page then
		SavesTray.fetch(shown)
	end
end)

return SavesTray
