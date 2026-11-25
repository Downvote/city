-- The tutorial. The user: "make the tutorial more visual and structured, starting with creating a
-- villager, then building a place for them to sleep, then a place to work. the first time a
-- craving pops up, guide the user how to do it."
--
-- Four steps (Sim/Tutorial says what each asks of the town and when it is done):
--   1 make your first villager       the Create tile on the quick menu
--   2 give them a bed                the Build button, then in Build mode Furniture, Beds and the
--                                    single bed's card (the new plot's bedroom is empty:
--                                    Data/StarterHouse.newPlot)
--   3 give them a job                the Build button, then Work and the builder's bench's card
--                                    (the workshop is empty too), and Done to go back out
--   4 buy them a craving             it waits for the first villager who craves a snack, points
--                                    at the bubble over their head (World/Wishes), then at Buy
--                                    in the popup it opens (UI/WishPopup)
-- On a first visit the welcome comes first, as the tutorial's opening page: what the game is in
-- two lines, the four steps in a row, and the two ways to make the first villager. After that a
-- step card sits at the right edge of the screen (it comes out of the edge, as the clock and the
-- Build button do): which step of four with a dot for each, a picture drawn from the icons, a
-- short title, one line saying what to do now, and Skip. A yellow ring round the thing to press
-- next pulses, with an arrow over it where there is room. The ring and the arrow are made inside
-- that thing, so they move with it, slide off with it and hide with it. A short card closes it
-- once all four are done.
--
-- A step is done when the town shows it, never on a click: this reads State, asks the server to
-- record it (TutorialStep), and the server checks the profile itself. Skip ends it for good.
-- Until the server has said how far the player is (State's `tutorial`), nothing shows.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Remotes = require(Shared.Net.Remotes)
local Steps = require(Shared.Sim.Tutorial)
local Foods = require(Shared.Data.Foods)
local Colors = require(Shared.Util.Colors)
local Text = require(Shared.Util.Text)

local Kit = require(script.Parent.Kit)
local Icons = require(script.Parent.Icons)
local State = require(script.Parent.Parent.Controllers.State)

local Tutorial = {}

local T = Kit.Theme
local player = Players.LocalPlayer

-- the card at the side
local W, H = 384, 150
local OVER = 18 -- how far it runs off the right edge of the screen
local PAD = 16
local PIC = 64 -- the picture
local TUCKED = PAD + PIC + PAD -- what still shows of it tucked away: the picture
local AT_HUD = 142 -- its top on the main screen: under the round buttons at the top right
local AT_BUILD = 14 -- and in Build mode, where the top right is clear
local EVERY = 0.25 -- seconds between looks at the screen

-- What each step is called and what its picture is: the step's own icon in its colour, and a
-- small round badge with what you do it with.
local LOOK = {
	{ title = "Make your first villager", color = T.Pink, badge = "shirt", short = "A villager" },
	{ title = "Give them a bed", color = T.Blue, badge = "hammer", short = "A bed" },
	{ title = "Give them a job", color = T.Orange, badge = "hammer", short = "A job" },
	{ title = "Buy them a craving", color = T.Coral, badge = "coin", short = "A craving" },
}
-- Build mode's names for where each built step's piece is: the group on the bar along the
-- bottom, the category tile and the piece's card (Build/BuildUI names them so)
local WHERE = {
	[2] = { group = "Furniture", category = "Beds", piece = Steps.Steps[2].piece :: string },
	[3] = { group = "Work", category = "Workplaces", piece = Steps.Steps[3].piece :: string },
}

local hudApi: any = nil
local started = false
local layer: Frame? = nil
local card: Frame? = nil
local content: Frame? = nil
local showHit: TextButton? = nil
local painted = "" -- what the card shows now, as a key
local cardAt: UDim2? = nil
local tucked = false
local skipped = false
local asked = 0 -- the furthest step asked of the server
local sawSteps = false -- a step card was up this session (the closing card follows only then)
local closing: number? = nil -- when the closing card went up
local closed = false
local welcomed = false
local panel: any = nil -- the welcome
local pointer: { target: Instance?, how: string?, parts: { Instance } } = { parts = {} }

-- Is it on screen: it and everything it is in visible?
local function shown(o: Instance?): boolean
	local cur: Instance? = o
	while cur and not cur:IsA("PlayerGui") do
		if cur:IsA("GuiObject") and not cur.Visible then
			return false
		end
		if cur:IsA("LayerCollector") and not cur.Enabled then
			return false
		end
		cur = cur.Parent
	end
	return cur ~= nil
end

-- The town as Sim/Tutorial reads it, from the client's copy.
local function town(): any
	local d = State.data
	return { villagers = d.villagers or {}, order = d.order or {}, plan = State.plan, stats = d.stats or {} }
end

-- Build mode, and whether a piece is in hand (the bars have slid away then: Build/BuildUI).
local function building(): (boolean, boolean)
	local BuildMode = require(script.Parent.Parent.Build.BuildMode) :: any
	if not BuildMode.isActive() then
		return false, false
	end
	local s = BuildMode.state
	return true, (s.tool == "place" and s.placing ~= nil) or s.tool == "preset"
end

-- Does the creator have the screen?
local function creating(): boolean
	local c = Kit.root():FindFirstChild("Creator")
	return c ~= nil and c:IsA("GuiObject") and c.Visible
end

-- the pointer ----------------------------------------------------------------------------------------

local function unpoint()
	for _, part in pointer.parts do
		part:Destroy()
	end
	pointer.parts = {}
	pointer.target = nil
	pointer.how = nil
end

local PULSE = TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, -1, true)
local BOB = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, -1, true)

-- An arrow pointing down, in yellow over a dark copy of itself, bobbing in its own box.
local function arrow(parent: Instance, px: number): Frame
	local holder = Kit.new("Frame", {
		Name = "TutorialArrow",
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(px + 4, px + 8),
		ZIndex = 40,
		Parent = parent,
	})
	holder:SetAttribute("KeepColors", true)
	local bob = Kit.new("Frame", {
		Name = "Bob",
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(px + 4, px + 4),
		ZIndex = 40,
		Parent = holder,
	})
	Icons.make(
		"down",
		px,
		{ Name = "Shade", Parent = bob, Position = UDim2.fromOffset(3, 3), Color = T.Dark, ZIndex = 40 }
	)
	Icons.make(
		"down",
		px,
		{ Name = "IconArt", Parent = bob, Position = UDim2.fromOffset(1, 1), Color = T.Yellow, ZIndex = 41 }
	)
	TweenService:Create(bob, BOB, { Position = UDim2.fromOffset(0, 4) }):Play()
	return holder
end

-- Points at `target`. how: "out" (a ring just outside it and an arrow over it), "ring" (the ring
-- only: it sits where something else would cover an arrow), "in" (the ring just inside its edge:
-- it is in a row that cuts off what reaches past it), "arrow" (the arrow only), "stack" (a wish
-- bubble's group: the arrow goes in over the bubble, in the stack).
local function point(target: GuiObject?, how: string?)
	if target == pointer.target and how == pointer.how and #pointer.parts > 0 then
		local alive = true
		for _, part in pointer.parts do
			if part.Parent == nil then
				alive = false
			end
		end
		if alive then
			return
		end
	end
	unpoint()
	if not target or not how then
		return
	end
	pointer.target, pointer.how = target, how
	if how == "stack" then
		local a = arrow(target, 30)
		a.LayoutOrder = 0
		table.insert(pointer.parts, a)
		return
	end
	if how ~= "arrow" and target.AutomaticSize == Enum.AutomaticSize.None then
		local m = if how == "in" then -3 else 4
		local ring = Kit.new("Frame", {
			Name = "TutorialRing",
			BackgroundTransparency = 1,
			Size = UDim2.new(1, m * 2, 1, m * 2),
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			ZIndex = 40,
			Parent = target,
		})
		ring:SetAttribute("KeepColors", true)
		Kit.corner(ring, if how == "in" then 9 else 14)
		local stroke = Kit.new("UIStroke", {
			Name = "Rim",
			Color = T.Yellow,
			Thickness = 3,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Parent = ring,
		})
		TweenService:Create(stroke, PULSE, { Transparency = 0.65 }):Play()
		table.insert(pointer.parts, ring)
	end
	if how == "out" or how == "arrow" then
		local a = arrow(target, 30)
		a.AnchorPoint = Vector2.new(0.5, 1)
		-- (a slab that runs off the right edge of the screen: over the part of it that shows)
		local off = if target.AnchorPoint.X == 1 and target.Position.X.Scale == 1 then target.Position.X.Offset else 0
		a.Position = UDim2.new(0.5, -off / 2, 0, -2)
		table.insert(pointer.parts, a)
	end
end

-- the things pointed at, by the names they are made with ---------------------------------------------

local function hudPart(name: string): GuiObject?
	local hud = Kit.root():FindFirstChild("Hud")
	if not hud then
		return nil
	end
	local found = if name == "Build" then hud:FindFirstChild("Build") else hud:FindFirstChild(name, true)
	return if found and found:IsA("GuiObject") then found else nil
end

local function buildPart(where: string, name: string): GuiObject?
	local ui = Kit.root():FindFirstChild("BuildUI")
	local box = ui and ui:FindFirstChild(where, true)
	local found = box and box:FindFirstChild(name, true)
	return if found and found:IsA("GuiObject") and shown(found) then found else nil
end

-- The way to a step's piece in Build mode: its card when its category is open, the category's
-- tile when its group is, or else the group. Returns the target, how to point and where it is.
local function buildWay(step: number): (GuiObject?, string, string)
	local w = WHERE[step]
	local piece = buildPart("Tray", w.piece)
	if piece then
		return piece, "in", "card"
	end
	local tile = buildPart("Subs", w.category)
	if tile then
		return tile, "in", "tile"
	end
	return buildPart("Dock", w.group), "ring", "group"
end

-- The villagers on this player's own plot, by id.
local function models(): { [string]: Model }
	local out = {}
	local index = player:GetAttribute("Plot")
	local plots = workspace:FindFirstChild("Plots")
	local plot = plots and index and plots:FindFirstChild("Plot" .. tostring(index))
	local folder = plot and plot:FindFirstChild("Villagers")
	for _, m in if folder then folder:GetChildren() else {} do
		local vid = m:GetAttribute("Vid")
		if m:IsA("Model") and type(vid) == "string" then
			out[vid] = m
		end
	end
	return out
end

-- The bubble over a villager's head (World/Wishes), as the group it is drawn in.
local function bubbleOf(model: Model): GuiObject?
	local gui = player:FindFirstChild("PlayerGui")
	for _, b in if gui then gui:GetChildren() else {} do
		if b.Name == "WishBubble" and b:IsA("BillboardGui") then
			local on = b.Adornee
			if on and on:IsDescendantOf(model) then
				local fade = b:FindFirstChild("Fade")
				return if fade and fade:IsA("GuiObject") then fade else nil
			end
		end
	end
	return nil
end

-- The popup's button that buys a craving (UI/WishPopup), while it is up for one.
local function buyButton(): GuiObject?
	local popup = Kit.root():FindFirstChild("WishPopup")
	local buy = popup and popup:FindFirstChild("Buy", true)
	if not buy or not buy:IsA("GuiObject") or not shown(buy) then
		return nil
	end
	local kind = buy:GetAttribute("Kind")
	return if kind == nil or kind == "food" then buy else nil
end

-- what to show ---------------------------------------------------------------------------------------

-- The card's words and what to point at, for step `step` as things are now.
local function now(step: number, t: any): any
	local look = LOOK[step]
	local view = {
		step = step,
		title = look.title,
		color = look.color,
		icon = Steps.Steps[step].icon,
		badge = look.badge,
		line = "",
		target = nil :: GuiObject?,
		how = nil :: string?,
		phase = "",
	}
	local inBuild = building()
	if step == 1 then
		if inBuild then
			view.line = "Press Done, then Create at the bottom left."
			view.target, view.how, view.phase = buildPart("Dock", "Done"), "ring", "done"
		else
			view.line = "Press Create at the bottom left and dress them up."
			view.target, view.how, view.phase = hudPart("Create"), "out", "create"
		end
	elseif step == 2 or step == 3 then
		if inBuild then
			local target, how, where = buildWay(step)
			view.target, view.how, view.phase = target, how, where
			if step == 2 then
				view.line = if where == "card"
					then "Pick the single bed and put it in the empty bedroom."
					elseif where == "tile" then "Now open Beds."
					else "Open Furniture on the bar at the bottom."
			else
				view.line = if where == "card"
					then "Pick the builder's bench and put it in the workshop."
					elseif where == "tile" then "Now open Workplaces."
					else "Open Work on the bar at the bottom."
			end
		else
			view.line = if step == 2
				then "Press Build and put a bed in the cottage's empty bedroom."
				else "Press Build and put a workbench in the empty workshop."
			view.target, view.how, view.phase = hudPart("Build"), "arrow", "build"
		end
	else
		-- the first craving: who has one, and whether anybody but you can have one
		local craving, others = nil, 0
		for _, vid in t.order do
			local v = t.villagers[vid]
			if v and not v.isYou then
				others += 1
			end
			local w = v and v.wish
			if not craving and type(w) == "table" and w.kind == "food" and Foods.get(w.arg) then
				craving = { vid = vid, v = v, food = Foods.get(w.arg) }
			end
		end
		local buy = buyButton()
		if buy then
			view.line = "Press Buy to get it for them."
			view.target, view.how, view.phase = buy, "out", "buy"
		elseif craving then
			view.food = craving.food
			local what = Text.fill("{x} is craving {food}.", { x = craving.v.name, food = Foods.phrase(craving.food) })
			local model = models()[craving.vid]
			local bubble = model and not inBuild and bubbleOf(model)
			if inBuild then
				view.line = what .. " Press Done to go and get it."
				view.target, view.how, view.phase = buildPart("Dock", "Done"), "ring", "done"
			elseif bubble then
				view.line = what .. " Press the bubble over their head."
				view.target, view.how, view.phase = bubble, "stack", "bubble"
			else
				view.line = what .. " Find them and press the bubble over their head."
				view.phase = "find"
			end
			view.phase ..= ":" .. craving.vid .. ":" .. craving.food.id
		elseif others == 0 then
			view.line = "You don't get cravings yourself. Make a second villager with Create."
			if not inBuild then
				view.target, view.how = hudPart("Create"), "out"
			end
			view.phase = "another"
		else
			view.line = "Wait for a villager to crave a snack. A bubble pops up over their head."
			view.phase = "wait"
		end
	end
	return view
end

-- the card -------------------------------------------------------------------------------------------

local function homeOf(): UDim2
	local inBuild = building()
	return UDim2.new(1, OVER, 0, if inBuild then AT_BUILD else AT_HUD)
end

-- Slides the card where it belongs now: home, tucked to the edge, or off the screen.
local function place(away: boolean)
	if not card then
		return
	end
	local home = homeOf()
	local want = if away
		then home + UDim2.fromOffset(W + 40, 0)
		elseif tucked then home + UDim2.fromOffset(W - TUCKED - OVER, 0)
		else home
	if cardAt == want then
		return
	end
	local first = cardAt == nil
	cardAt = want
	if showHit then
		showHit.Visible = tucked and not away
	end
	if first then
		card.Position = want + UDim2.fromOffset(W + 40, 0)
	end
	TweenService:Create(
		card,
		if away
			then TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			else TweenInfo.new(0.42, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
		{ Position = want }
	):Play()
end

local refresh: () -> ()

local function skip()
	skipped = true
	unpoint()
	Tutorial.close()
	place(true)
	task.spawn(function()
		pcall(function()
			Remotes.fn("TutorialStep"):InvokeServer(Steps.Skipped)
		end)
	end)
end

local function clearContent()
	if content then
		for _, c in content:GetChildren() do
			c:Destroy()
		end
	end
end

-- A dot for each step: done ones green, this one a yellow pill, the rest dim.
local function dots(parent: Instance, step: number)
	local row = Kit.box({
		Name = "Dots",
		Parent = parent,
		Size = UDim2.fromOffset(60, 8),
		Position = UDim2.new(1, -(OVER + PAD + 34), 0, 17),
		AnchorPoint = Vector2.new(1, 0),
	})
	row.ZIndex = 3
	Kit.list(row, 5, true, Enum.HorizontalAlignment.Right).VerticalAlignment = Enum.VerticalAlignment.Center
	for i = 1, Steps.Count do
		local here = i == step
		local dot = Kit.frame({
			Name = "Dot" .. i,
			Parent = row,
			Size = UDim2.fromOffset(if here then 18 else 8, 8),
			Color = if i < step then T.Green elseif here then T.Yellow else T.PaperDark,
			Radius = "pill",
			LayoutOrder = i,
			ZIndex = 3,
		})
		if i > step then
			Kit.rim(dot, T.Line, 1)
		end
	end
end

-- The picture: the step's icon big in its colour on a tile, a badge with what it is done with.
local function picture(parent: Instance, view: any)
	local pic = Kit.frame({
		Name = "Picture",
		Parent = parent,
		Size = UDim2.fromOffset(PIC, PIC),
		Position = UDim2.fromOffset(PAD, 38),
		Color = T.Card,
		Radius = 14,
		ZIndex = 2,
	})
	Kit.rim(pic, T.Line, 1)
	Kit.halo(pic, PIC + 10, view.color, 0.22)
	if view.food then
		Icons.item(view.food.id, 40, Colors.fromHex(view.food.color, view.color), {
			Name = "IconArt",
			Parent = pic,
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			ZIndex = 3,
		})
	else
		Icons.make(view.icon, 38, {
			Name = "IconArt",
			Parent = pic,
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Color = view.color,
			Hole = T.Card,
			ZIndex = 3,
		})
	end
	if view.badge then
		Kit.disc({
			Name = "Badge",
			Parent = pic,
			Size = 24,
			Position = UDim2.new(1, 6, 1, 6),
			AnchorPoint = Vector2.new(1, 1),
			Color = T.Yellow,
			Icon = view.badge,
			IconColor = T.Dark,
			ZIndex = 4,
		})
	end
end

-- Draws what the card says.
local function paint(view: any)
	if not content then
		return
	end
	clearContent()
	local box = content :: Frame
	local glow = Kit.glow(box, view.color, 0.16, "tl")
	glow:SetAttribute("KeepColors", true)
	local done = view.step > Steps.Count
	Kit.caption(
		if done then "All done" else Text.fill("Step {n} of {all}", { n = view.step, all = Steps.Count }),
		{ Name = "Step", Parent = box, Position = UDim2.fromOffset(PAD, 12), Tint = view.color, ZIndex = 3 }
	)
	if not done then
		dots(box, view.step)
	end
	picture(box, view)
	local x = PAD + PIC + 14
	local wide = W - x - OVER - PAD
	local title = Kit.title(view.title, {
		Name = "Title",
		Parent = box,
		Size = UDim2.fromOffset(wide, 24),
		Position = UDim2.fromOffset(x, 38),
		TextSize = 20,
		Color = T.Ink,
		Wrap = false,
		ZIndex = 3,
	})
	title.TextTruncate = Enum.TextTruncate.AtEnd
	Kit.text(view.line, {
		Name = "Line",
		Parent = box,
		Size = UDim2.fromOffset(wide, 54),
		Position = UDim2.fromOffset(x, 64),
		TextSize = 15,
		Color = T.Ink,
		AlignY = Enum.TextYAlignment.Top,
		ZIndex = 3,
	})
	-- at the bottom right: Skip (Close on the last card), and at the top right the round button
	-- that tucks it to the edge
	local link = Kit.new("TextButton", {
		Name = if done then "Close" else "Skip",
		Text = if done then "Close" else "Skip",
		Font = Kit.Fonts.Body,
		TextSize = 14,
		TextColor3 = T.InkSoft,
		TextXAlignment = Enum.TextXAlignment.Right,
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Size = UDim2.fromOffset(70, 22),
		Position = UDim2.new(1, -(OVER + PAD - 4), 1, -8),
		AnchorPoint = Vector2.new(1, 1),
		ZIndex = 4,
		Parent = box,
	})
	Kit.press(link, { Kind = "plain", Face = false })
	link.Activated:Connect(function()
		if done then
			closed = true
			place(true)
		else
			skip()
		end
	end)
	local tuck = Kit.roundButton("back", {
		Name = "Tuck",
		Parent = box,
		Size = 26,
		Position = UDim2.new(1, -(OVER + PAD - 6), 0, 8),
		AnchorPoint = Vector2.new(1, 0),
	}, function()
		tucked = true
		place(false)
	end)
	tuck.ZIndex = 4
	local art = tuck:FindFirstChild("IconArt")
	if art and art:IsA("GuiObject") then
		art.Rotation = 180 -- toward the edge it goes to
	end
end

local function makeCard()
	if card then
		card:Destroy()
	end
	painted = ""
	cardAt = nil
	local c = Kit.frame({
		Name = "TutorialCard",
		Parent = layer,
		Size = UDim2.fromOffset(W, H),
		Position = homeOf() + UDim2.fromOffset(W + 40, 0),
		AnchorPoint = Vector2.new(1, 0),
		Color = T.Paper,
		Radius = 16,
	})
	Kit.rim(c, T.Line, 1)
	Kit.softShadow(c, 1)
	Kit.dots(c, T.Ink, 0.94, 16)
	content = Kit.box({ Name = "Content", Parent = c, Size = UDim2.fromScale(1, 1) })
	-- tucked, what still shows of it brings it back
	showHit = Kit.new("TextButton", {
		Name = "Show",
		Text = "",
		BackgroundTransparency = 1,
		Size = UDim2.new(0, TUCKED, 1, 0),
		ZIndex = 6,
		Visible = false,
		Parent = c,
	})
	local hit = showHit :: TextButton
	hit.Activated:Connect(function()
		tucked = false
		place(false)
	end)
	card = c
end

-- the welcome: the tutorial's first page -------------------------------------------------------------

function Tutorial.isOpen(): boolean
	return panel ~= nil and panel.root.Parent ~= nil
end

function Tutorial.close()
	if panel then
		Kit.closePanel(panel)
		panel = nil
	end
end

local function openCreator(start: string?)
	Tutorial.close()
	if hudApi then
		hudApi.open("Creator", { mode = "new", start = start })
	end
end

-- The four steps in a row, the first picked.
local function stepRow(parent: Instance, order: number)
	local row = Kit.box({ Name = "Steps", Parent = parent, Size = UDim2.new(1, 0, 0, 76), LayoutOrder = order })
	Kit.list(row, 10, true)
	for i, look in LOOK do
		local here = i == 1
		local chip = Kit.frame({
			Name = "Step" .. i,
			Parent = row,
			Size = UDim2.new(0.25, -8, 1, 0),
			Color = if here then T.Yellow else T.Card,
			Radius = 12,
			LayoutOrder = i,
		})
		if here then
			chip:SetAttribute("KeepColors", true)
		else
			Kit.rim(chip, T.Line, 1)
		end
		Icons.make(Steps.Steps[i].icon, 28, {
			Name = "IconArt",
			Parent = chip,
			Position = UDim2.new(0.5, 0, 0, 10),
			AnchorPoint = Vector2.new(0.5, 0),
			Color = if here then T.Dark else look.color,
			Hole = if here then T.Yellow else T.Card,
			ZIndex = 2,
		})
		Kit.text(Kit.index(i) .. "  " .. look.short, {
			Name = "Name",
			Parent = chip,
			Size = UDim2.new(1, -8, 0, 20),
			Position = UDim2.new(0.5, 0, 1, -8),
			AnchorPoint = Vector2.new(0.5, 1),
			TextSize = 14,
			Font = Kit.Fonts.Bold,
			Color = if here then T.Dark else T.Ink,
			AlignX = Enum.TextXAlignment.Center,
			Wrap = false,
			ZIndex = 2,
		})
	end
end

function Tutorial.open(_arg: any?)
	Tutorial.close()
	panel = Kit.panel("Welcome to Catalog Town", UDim2.fromOffset(620, 540), function()
		Tutorial.close()
	end, "house", T.Pink, { Dialog = true })
	local body = panel.body
	Kit.list(body, 10)
	for i, l in
		{
			"This plot is yours to build on, and you make the villagers who live here.",
			"They work in town for coins, and now and then one of them asks you for something.",
		}
	do
		Kit.text(l, {
			Name = "About",
			Parent = body,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			TextSize = 17,
			LayoutOrder = i,
		})
	end
	Kit.caption("Four steps to get going", { Parent = body, LayoutOrder = 3, Size = UDim2.new(1, 0, 0, 18) })
	stepRow(body, 4)
	local first = Kit.box({ Name = "First", Parent = body, Size = UDim2.new(1, 0, 0, 48), LayoutOrder = 5 })
	Kit.caption(Text.fill("Step 1 of {all}", { all = Steps.Count }), {
		Name = "Step",
		Parent = first,
		Position = UDim2.fromOffset(0, 2),
		Tint = LOOK[1].color,
	})
	Kit.title(LOOK[1].title, {
		Name = "Title",
		Parent = first,
		Size = UDim2.new(1, 0, 0, 28),
		Position = UDim2.fromOffset(0, 20),
		TextSize = 21,
		Color = T.Ink,
	})
	local ways = Kit.box({ Name = "Ways", Parent = body, Size = UDim2.new(1, 0, 0, 112), LayoutOrder = 6 })
	Kit.list(ways, 12, true)
	Kit.tile("person", "Make me", {
		Name = "Make me",
		Parent = ways,
		Size = UDim2.new(0.5, -6, 0, 112),
		Color = T.Green,
		TextColor = T.Dark,
		TextSize = 16,
		LayoutOrder = 1,
	}, function()
		openCreator("me")
	end)
	Kit.tile("shirt", "Start from scratch", {
		Name = "Start from scratch",
		Parent = ways,
		Size = UDim2.new(0.5, -6, 0, 112),
		TextSize = 16,
		LayoutOrder = 2,
	}, function()
		openCreator(nil)
	end)
	local foot = Kit.box({ Name = "Foot", Parent = body, Size = UDim2.new(1, 0, 0, 24), LayoutOrder = 7 })
	Kit.text("A card at the right shows the next step.", {
		Name = "Note",
		Parent = foot,
		Size = UDim2.new(1, -150, 1, 0),
		TextSize = 14,
		Color = T.InkSoft,
		Wrap = false,
	})
	local link = Kit.new("TextButton", {
		Name = "Skip",
		Text = "Skip the tutorial",
		Font = Kit.Fonts.Body,
		TextSize = 14,
		TextColor3 = T.InkSoft,
		TextXAlignment = Enum.TextXAlignment.Right,
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Size = UDim2.new(0, 140, 1, 0),
		Position = UDim2.new(1, 0, 0, 0),
		AnchorPoint = Vector2.new(1, 0),
		Parent = foot,
	})
	Kit.press(link, { Kind = "plain", Face = false })
	link.Activated:Connect(skip)
end

-- keeping it up to date --------------------------------------------------------------------------------

-- The key of what a view shows, so the card is only drawn again when that changes.
local function keyOf(view: any): string
	return table.concat({ view.step, view.phase, view.title, view.line, Kit.ThemeName }, "|")
end

refresh = function()
	if not layer then
		return
	end
	local d = State.data
	if d.tutorial == nil or d.villagers == nil or skipped then
		unpoint()
		place(true)
		return
	end
	local done = Steps.progress(d.tutorial)
	if done == Steps.Skipped then
		unpoint()
		place(true)
		return
	end
	local t = town()
	local reached = Steps.reached(t, done)
	-- what the town shows goes to the server, which looks for itself
	if reached > done and reached > asked and reached <= Steps.Count then
		asked = reached
		task.spawn(function()
			local ok, recorded = pcall(function()
				return Remotes.fn("TutorialStep"):InvokeServer(reached)
			end)
			if not ok or not recorded then
				-- (asked again on a later look)
				task.delay(3, function()
					if asked == reached then
						asked = done
					end
				end)
			end
		end)
	end
	-- the welcome, once, on a first visit
	if not welcomed and done == 0 and #(d.order or {}) == 0 then
		welcomed = true
		task.delay(1.5, function()
			local dd = State.data
			if not skipped and #(dd.order or {}) == 0 and not creating() then
				Tutorial.open()
			end
		end)
	end
	if not card then
		makeCard()
	end
	local view
	if reached >= Steps.Count then
		unpoint()
		if not sawSteps or closed then
			place(true)
			return
		end
		closing = closing or os.clock()
		if os.clock() - (closing :: number) > 14 then
			closed = true
			place(true)
			return
		end
		view = {
			step = Steps.Count + 1,
			title = "That's the tutorial",
			line = "You know the basics now. The rest of the plot is yours to build on.",
			color = T.Green,
			icon = "check",
			phase = "done",
		}
	else
		sawSteps = true
		view = now(reached + 1, t)
	end
	local key = keyOf(view)
	if key ~= painted then
		-- a new step brings a tucked card back out
		if painted:match("^(%d+)") ~= tostring(view.step) then
			tucked = false
		end
		painted = key
		paint(view)
	end
	local _, holding = building()
	local away = holding or creating() or d.talking == true
	-- a craving turning up brings a tucked card back out
	if tucked and (view.phase:sub(1, 6) == "bubble" or view.phase == "buy") then
		tucked = false
	end
	place(away)
	point(view.target, view.how)
end

function Tutorial.start(hud: any)
	if started then
		return
	end
	started = true
	hudApi = hud
	local l = Kit.box({ Name = "Tutorial", Parent = Kit.root(), Size = UDim2.fromScale(1, 1) })
	-- over the main screen and Build mode, under the menus (a menu's holder is 5)
	l.ZIndex = 4
	layer = l
	local function soon()
		task.defer(function()
			local ok, err = pcall(refresh)
			if not ok then
				warn("[Tutorial] " .. tostring(err))
			end
		end)
	end
	for _, key in { "tutorial", "villagers", "order", "stats", "talking" } do
		State.on(key, soon)
	end
	State.onPlan(soon)
	Kit.onTheme(function()
		-- drawn again in the new look
		if card then
			makeCard()
			soon()
		end
	end)
	task.spawn(function()
		while true do
			local ok, err = pcall(refresh)
			if not ok then
				warn("[Tutorial] " .. tostring(err))
			end
			task.wait(EVERY)
		end
	end)
end

return Tutorial
