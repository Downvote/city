-- The tutorial. The user: "for the tutorial, remove the box in the right and the creation text
-- that appears on join. first, darken the screen and highlight only "create" in the bottom menu,
-- and a prompt saying "Create your first villager!" upon click, this opens a pop up which asks:
-- Would you like to create yourself, a friend, or a custom villager as the first villager?
-- Clicking yourself creates yourself, a friend moves you to the players tab, and custom leaves the
-- player to it. once a villager is created, do the same, darkning the screen and pointing to
-- build mode, prompting: Build a bed for your villager to sleep in! The step continues to prompt:
-- Build a work place for your villager to work in! After this, the tutorial ends, stating: Grow
-- your town and create more villagers!" And then: "at the start of the tutorial, make one of the
-- player's friends (most interacted with if possible) greet the player, saying "Welcome to Catalog
-- Town! To get started, lets create our first villager!", then clicking the dialogue points to
-- the create icon as usual. Then, once created, they state: "You made your first villager! They
-- need a place to sleep in. Build a bed for them!". This continues for the work step, and then
-- for ending the tutorial as well."
--
-- Three steps (Sim/Tutorial says what each asks of the town and when it is done, and holds the
-- words). As each comes up, the friend (asked of the server: TutorialGreeter) slides in in the
-- game's own dialogue scene (UI/Dialogue) and says its line. A click closes the scene, and then
-- the screen darkens everywhere but the one thing to press, which stays pressable, with a yellow
-- ring round it (and an arrow over it where there is room) and the step's prompt beside it:
--   1 a villager   the Create tile on the quick menu, which opens a small popup instead of the
--                  creator: Yourself, A friend or Custom (UI/Creator.openFor)
--   2 a bed        the Build button, then in Build mode Furniture, Beds and the single bed's card
--                  (the new plot's bedroom is empty: Data/StarterHouse.newPlot)
--   3 a workplace  the Build button, then Work and the builder's bench's card (the workshop is
--                  empty too)
-- Once the workplace is down the friend says the last line and it is over. The darkened screen
-- is four dark pieces round a hole over the thing to press; they catch every click that isn't on
-- it. It steps aside while a menu, the creator or another scene is up, and while a piece is held
-- in Build mode (the world must be pressable then); a step done with a piece in hand puts it away
-- so the friend can talk.
--
-- A step is done when the town shows it, never on a click: this reads State, asks the server to
-- record it (TutorialStep), and the server checks the profile itself. Skip ends it for good.
-- Until the server has said how far the player is (State's `tutorial`), nothing shows.

local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Remotes = require(Shared.Net.Remotes)
local Steps = require(Shared.Sim.Tutorial)
local Tuning = require(Shared.Config.Tuning)

local Kit = require(script.Parent.Kit)
local Icons = require(script.Parent.Icons)
local Dialogue = require(script.Parent.Dialogue)
local State = require(script.Parent.Parent.Controllers.State)

local Tutorial = {}

local T = Kit.Theme
local K = Tuning.Tutorial
local EVERY = 0.25 -- seconds between looks at the screen

-- Build mode's names for where each built step's piece is: the group on the bar along the
-- bottom, the category tile and the piece's card (Build/BuildUI names them so)
local WHERE = {
	[2] = { group = "Furniture", category = "Beds", piece = Steps.Steps[2].piece :: string },
	[3] = { group = "Work", category = "Workplaces", piece = Steps.Steps[3].piece :: string },
}
local SIDES = { "Top", "Bottom", "Left", "Right" }

local hudApi: any = nil
local started = false
local knownAt: number? = nil -- when the server first said how far the player is
local layer: Frame? = nil
local dim: Frame? = nil -- the darkened screen: the four pieces and the prompt
local aimed: { target: GuiObject, how: string }? = nil -- what the hole is over
local holeConn: RBXScriptConnection? = nil
local skipped = false
local asked = 0 -- the furthest step asked of the server
local sawSteps = false -- a step was shown this session (the last line follows only then)
local said: { [any]: boolean } = {} -- the friend's lines said this session: by step, and "done"
local putAway: { [any]: boolean } = {} -- the steps a piece in hand was put away for
local scene: any = nil -- the friend's scene, while it is up
local greeter: any = nil -- { name, id?, friend, model? } once the server has said
local greeterAskedAt: number? = nil
local panel: any = nil -- the popup that asks how to make the first villager
local hookedCreator = false
local pointer: { target: GuiObject?, how: string?, parts: { Instance } } = { parts = {} }

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
	return { villagers = d.villagers or {}, order = d.order or {}, plan = State.plan }
end

-- Build mode, and whether a piece is in hand or something is being drawn (the bars have slid
-- away then, and the world must take the clicks: Build/BuildUI).
local function building(): (boolean, boolean)
	local BuildMode = require(script.Parent.Parent.Build.BuildMode) :: any
	if not BuildMode.isActive() then
		return false, false
	end
	local s = BuildMode.state
	return true, (s.tool == "place" and s.placing ~= nil) or s.tool == "preset" or BuildMode.isDrawing()
end

-- Does the creator have the screen?
local function creating(): boolean
	local c = Kit.root():FindFirstChild("Creator")
	return c ~= nil and c:IsA("GuiObject") and c.Visible
end

-- Is a menu up (this popup among them)?
local function menuUp(): boolean
	return hudApi ~= nil and hudApi.anyOpen ~= nil and hudApi.anyOpen()
end

-- The step being worked on, or nil when there is none (not known yet, over or skipped).
local function currentStep(): number?
	local d = State.data
	if skipped or d.tutorial == nil or d.villagers == nil then
		return nil
	end
	local done = Steps.progress(d.tutorial)
	if done >= Steps.Count then
		return nil
	end
	return Steps.current(town(), done)
end

-- the pointer ----------------------------------------------------------------------------------------

local function unpoint()
	for _, part in pointer.parts do
		part:Destroy()
	end
	pointer.parts = {}
	if pointer.target then
		pointer.target:SetAttribute("TutorialTarget", nil)
	end
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
-- it is in a row that cuts off what reaches past it), "arrow" (the arrow only). The ring is made
-- inside the target, so it moves with it; the arrow stands over the hole (placeHole).
local function point(target: GuiObject, how: string)
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
	pointer.target, pointer.how = target, how
	-- (what the darkened screen is cut round: the previews cut it from their own layout by this)
	target:SetAttribute("TutorialTarget", true)
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
		TweenService:Create(stroke, PULSE, { Transparency = 0.45 }):Play()
		table.insert(pointer.parts, ring)
	end
	-- (the arrow is the darkened screen's: over the hole, where nothing dims it)
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
-- tile when its group is, or else the group.
local function buildWay(step: number): (GuiObject?, string)
	local w = WHERE[step]
	local piece = buildPart("Tray", w.piece)
	if piece then
		return piece, "in"
	end
	local tile = buildPart("Subs", w.category)
	if tile then
		return tile, "in"
	end
	return buildPart("Dock", w.group), "ring"
end

-- What to press for step `step` as things are now, and how to point at it.
local function targetFor(step: number): (GuiObject?, string)
	local inBuild = building()
	if step == 1 then
		if inBuild then
			-- (out of Build mode first: Create is on the main screen)
			return buildPart("Dock", "Done"), "ring"
		end
		return hudPart("Create"), "out"
	end
	if inBuild then
		return buildWay(step)
	end
	return hudPart("Build"), "arrow"
end

-- the darkened screen --------------------------------------------------------------------------------

-- The four dark pieces round a hole at (x, y, w, h) on a screen `sw` by `sh` (the layer's own
-- pixels), each { x, y, w, h }: the top and bottom run the whole width, the sides fill between
-- them, so they meet without overlapping. The hole is kept on the screen.
function Tutorial.cut(sw: number, sh: number, x: number, y: number, w: number, h: number): { [string]: { number } }
	local x0 = math.clamp(math.floor(x), 0, sw)
	local y0 = math.clamp(math.floor(y), 0, sh)
	local x1 = math.clamp(math.ceil(x + w), x0, sw)
	local y1 = math.clamp(math.ceil(y + h), y0, sh)
	return {
		Top = { 0, 0, sw, y0 },
		Bottom = { 0, y1, sw, sh - y1 },
		Left = { 0, y0, x0, y1 - y0 },
		Right = { x1, y0, sw - x1, y1 - y0 },
	}
end

-- Where the prompt goes beside a hole: centred over it (or under it, for a hole in the top half),
-- `gap` clear of it, kept 16 from the screen's edges. Returns x, y and which side.
function Tutorial.promptAt(
	sw: number,
	sh: number,
	hole: { number },
	w: number,
	h: number,
	gap: number
): (number, number, string)
	local hx, hy, hw, hh = hole[1], hole[2], hole[3], hole[4]
	local x = math.clamp(math.floor(hx + hw / 2 - w / 2), 16, math.max(16, sw - 16 - w))
	if hy + hh / 2 > sh / 2 then
		return x, math.max(8, math.floor(hy - gap - h)), "above"
	end
	return x, math.min(sh - 8 - h, math.floor(hy + hh + gap)), "below"
end

local function skip()
	skipped = true
	said.done = true
	task.spawn(function()
		pcall(function()
			Remotes.fn("TutorialStep"):InvokeServer(Steps.Skipped)
		end)
	end)
	Tutorial.stop()
end

local PROMPT_H = 72
local PROMPT_SIZE = 20

local function makeDim(): Frame
	local d = Kit.box({ Name = "TutorialDim", Parent = layer, Size = UDim2.fromScale(1, 1) })
	d.Visible = false
	d:SetAttribute("HolePad", K.Pad)
	-- black in both looks: it darkens the screen, as the user asked, light look or not
	d:SetAttribute("KeepColors", true)
	for _, side in SIDES do
		local f = Kit.new("Frame", {
			Name = side,
			BackgroundColor3 = T.Shadow,
			BackgroundTransparency = K.Dim,
			BorderSizePixel = 0,
			Size = UDim2.new(),
			ZIndex = 1,
			Parent = d,
		})
		-- (it takes the clicks, so only the thing in the hole can be pressed)
		f.Active = true
		f:SetAttribute("Hole", side)
	end
	-- the arrow over the hole, where there is room for one
	local a = arrow(d, 30)
	a.Visible = false
	a.ZIndex = 2
	a:SetAttribute("HoleArrow", true)
	-- the prompt: dark glass with white words, the same in both looks, and Skip under the words
	local card = Kit.frame({
		Name = "TutorialPrompt",
		Parent = d,
		Size = UDim2.fromOffset(300, PROMPT_H),
		Color = T.Glass,
		Transparency = T.GlassAlpha,
		Radius = 12,
		ZIndex = 3,
	})
	card.Active = true
	Kit.softShadow(card, 1)
	Kit.new("TextLabel", {
		Name = "Line",
		Text = "",
		BackgroundTransparency = 1,
		Font = Kit.Fonts.Title,
		TextSize = PROMPT_SIZE,
		TextColor3 = T.White,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, -36, 0, 26),
		Position = UDim2.fromOffset(18, 12),
		ZIndex = 4,
		Parent = card,
	})
	local link = Kit.new("TextButton", {
		Name = "Skip",
		Text = "Skip tutorial",
		Font = Kit.Fonts.Body,
		TextSize = 14,
		TextColor3 = T.Glass:Lerp(T.White, 0.62),
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Size = UDim2.fromOffset(110, 20),
		Position = UDim2.fromOffset(18, 42),
		ZIndex = 4,
		Parent = card,
	})
	Kit.press(link, { Kind = "plain", Face = false })
	link.Activated:Connect(skip)
	return d
end

local function uiScale(): number
	local s = Kit.root():FindFirstChildOfClass("UIScale")
	return if s and s.Scale > 0 then s.Scale else 1
end

-- Cuts the darkened screen round what it is aimed at, where the engine has it now (every frame
-- while it is up: what is in the hole can slide). It reaches up through the strip Roblox keeps at
-- the top of the screen too, where the clock's slab hangs.
local function placeHole()
	local d, a = dim, aimed
	if not d or not a then
		return
	end
	local k = uiScale()
	local inset = Kit.topInset() / k
	d.Position = UDim2.fromOffset(0, -inset)
	d.Size = UDim2.new(1, 0, 1, inset)
	local screen = d.AbsoluteSize / k
	local at = (a.target.AbsolutePosition - d.AbsolutePosition) / k
	local size = a.target.AbsoluteSize / k
	local pad = K.Pad
	local hole = { at.X - pad, at.Y - pad, size.X + pad * 2, size.Y + pad * 2 }
	local arrowF = d:FindFirstChild("TutorialArrow")
	if arrowF and arrowF:IsA("GuiObject") then
		arrowF.Visible = a.how == "out" or a.how == "arrow"
		local aw, ah = arrowF.Size.X.Offset, arrowF.Size.Y.Offset
		-- (a slab that runs off the screen's edge: over the part of it that shows)
		local x0 = math.max(hole[1], 0)
		local x1 = math.min(hole[1] + hole[3], screen.X)
		arrowF.Position = UDim2.fromOffset(math.floor((x0 + x1) / 2 - aw / 2), math.floor(hole[2] + pad - 2 - ah))
	end
	local pieces = Tutorial.cut(screen.X, screen.Y, hole[1], hole[2], hole[3], hole[4])
	for side, r in pieces do
		local f = d:FindFirstChild(side)
		if f and f:IsA("GuiObject") then
			f.Position = UDim2.fromOffset(r[1], r[2])
			f.Size = UDim2.fromOffset(r[3], r[4])
		end
	end
	local card = d:FindFirstChild("TutorialPrompt")
	if card and card:IsA("GuiObject") then
		local gap = if a.how == "out" or a.how == "arrow" then 46 else 12
		card:SetAttribute("HoleGap", gap)
		local x, y, side = Tutorial.promptAt(screen.X, screen.Y, hole, card.Size.X.Offset, PROMPT_H, gap)
		card:SetAttribute("HoleNear", side)
		card.Position = UDim2.fromOffset(x, y)
	end
end

local function undim()
	unpoint()
	aimed = nil
	if dim then
		dim.Visible = false
	end
	if holeConn then
		holeConn:Disconnect()
		holeConn = nil
	end
end

-- Darkens the screen round `target` with the step's prompt beside it.
local function dimAt(step: number, target: GuiObject, how: string)
	if not dim then
		dim = makeDim()
	end
	local d = dim :: Frame
	local text = Steps.Prompts[step]
	local card = d:FindFirstChild("TutorialPrompt")
	local line = card and card:FindFirstChild("Line")
	if card and card:IsA("GuiObject") and line and line:IsA("TextLabel") and line.Text ~= text then
		line.Text = text
		card.Size = UDim2.fromOffset(math.max(220, Kit.textWidth(text, PROMPT_SIZE, Kit.Fonts.Title) + 36), PROMPT_H)
	end
	point(target, how)
	aimed = { target = target, how = how }
	if not d.Visible then
		d.Visible = true
		-- the dark comes up
		for _, side in SIDES do
			local f = d:FindFirstChild(side)
			if f and f:IsA("GuiObject") then
				f.BackgroundTransparency = 1
				TweenService:Create(f, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
					BackgroundTransparency = K.Dim,
				}):Play()
			end
		end
	end
	placeHole()
	if not holeConn then
		holeConn = RunService.RenderStepped:Connect(placeHole)
	end
end

-- the friend -----------------------------------------------------------------------------------------

-- Who greets them, once the server has said (or the stand-in, once it has had long enough).
local function greeterReady(): boolean
	if greeter then
		return true
	end
	if not greeterAskedAt then
		greeterAskedAt = os.clock()
		task.spawn(function()
			local ok, got = pcall(function()
				return Remotes.fn("TutorialGreeter"):InvokeServer()
			end)
			-- (an answer after the stand-in has spoken is too late: one friend talks them through it)
			if not greeter and ok and type(got) == "table" and type(got.name) == "string" and got.name ~= "" then
				greeter = {
					name = got.name,
					id = if type(got.id) == "number" then got.id else nil,
					friend = got.friend == true,
					model = if typeof(got.model) == "Instance" and got.model:IsA("Model") then got.model else nil,
				}
			end
		end)
		return false
	end
	if os.clock() - (greeterAskedAt :: number) >= K.GreeterWait then
		greeter = { name = Steps.StandIn.name, friend = false }
		return true
	end
	return false
end

-- The friend says `line` in the dialogue scene; a press once it is all there closes it, and then
-- the step's darkened screen comes.
local function sayLine(key: any, line: string)
	local g = greeter or { name = Steps.StandIn.name }
	local s
	s = Dialogue.open({
		Name = "TutorialScene",
		OnClick = function()
			said[key] = true
			if scene == s then
				scene = nil
			end
			s.close()
			task.defer(function()
				pcall(Tutorial.refresh)
			end)
		end,
	})
	scene = s
	s.join({
		key = "greeter",
		name = g.name,
		color = T.Pink,
		model = g.model,
		-- (their picture from Roblox when the server couldn't build their look)
		image = if not g.model and g.id then string.format("rbxthumb://type=Avatar&id=%d&w=420&h=420", g.id) else nil,
	})
	s.speak("greeter")
	s.type(line, nil, function()
		s.more.Visible = true
	end)
	if key ~= "done" then
		Dialogue.answer("Skip tutorial", {
			Name = "Skip",
			Parent = s.tools,
			Size = UDim2.fromOffset(132, 32),
			TextSize = 15,
		}, skip)
	end
end

-- the popup the Create tile opens on the first step ---------------------------------------------------

function Tutorial.isOpen(): boolean
	return panel ~= nil and panel.root.Parent ~= nil
end

function Tutorial.close()
	if panel then
		Kit.closePanel(panel)
		panel = nil
	end
end

-- Opens the creator the way picked (UI/Creator.openFor: "yourself", "friend" or "custom").
local function choose(kind: string)
	Tutorial.close()
	said[1] = true
	local Creator = hudApi and hudApi.panel("Creator")
	if not Creator then
		return
	end
	if not hookedCreator and Creator.Created then
		hookedCreator = true
		Creator.Created:Connect(function()
			task.defer(function()
				pcall(Tutorial.refresh)
			end)
		end)
	end
	Creator.openFor(kind)
end

function Tutorial.open(_arg: any?)
	Tutorial.close()
	panel = Kit.panel("Your first villager", UDim2.fromOffset(600, 290), function()
		Tutorial.close()
	end, "person", T.Pink, { Dialog = true })
	local body = panel.body
	Kit.list(body, 16)
	Kit.text(Steps.Ask, {
		Name = "Ask",
		Parent = body,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		TextSize = 18,
		LayoutOrder = 1,
	})
	local ways = Kit.box({ Name = "Ways", Parent = body, Size = UDim2.new(1, 0, 0, 120), LayoutOrder = 2 })
	Kit.list(ways, 12, true)
	local colors = { T.Green, T.Blue, T.Pink }
	for i, way in Steps.Ways do
		local tile = Kit.tile(way.icon, way.text, {
			Name = way.text,
			Parent = ways,
			Size = UDim2.new(1 / 3, -8, 0, 120),
			Color = colors[i],
			TextColor = T.Dark,
			TextSize = 17,
			LayoutOrder = i,
		}, function()
			choose(way.kind)
		end)
		tile:SetAttribute("Way", way.kind)
		Kit.mark(tile)
	end
end

-- The Create tile on the quick menu asks this first (UI/Hud): on the first step it opens the
-- popup in place of the creator, and says so.
function Tutorial.takeCreate(): boolean
	if currentStep() ~= 1 then
		return false
	end
	said[1] = true
	if scene then
		scene.close(true)
		scene = nil
	end
	if hudApi then
		hudApi.open("Tutorial")
	else
		Tutorial.open()
	end
	return true
end

-- keeping it up to date --------------------------------------------------------------------------------

-- Takes everything down: the darkened screen, the friend's scene and the popup.
function Tutorial.stop()
	undim()
	if scene then
		scene.close()
		scene = nil
	end
	Tutorial.close()
end

-- Puts away a piece in hand, once for `key` (a step just done with the piece still held).
local function putAwayFor(key: any)
	if putAway[key] then
		return
	end
	putAway[key] = true
	local BuildMode = require(script.Parent.Parent.Build.BuildMode) :: any
	if BuildMode.putAway then
		BuildMode.putAway()
	end
end

function Tutorial.refresh()
	if not layer then
		return
	end
	if scene and (scene.root.Parent == nil or scene.root.Name ~= "TutorialScene") then
		-- (put away by another scene: it says its line again later)
		scene = nil
	end
	local d = State.data
	if d.tutorial == nil or d.villagers == nil or skipped then
		Tutorial.stop()
		return
	end
	local done = Steps.progress(d.tutorial)
	if done == Steps.Skipped then
		Tutorial.stop()
		return
	end
	knownAt = knownAt or os.clock()
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
	local step: number? = if reached >= Steps.Count then nil else reached + 1
	if step ~= 1 and panel then
		Tutorial.close()
	end
	if step or (sawSteps and not said.done) then
		-- (the server is asked who greets them as soon as there is anything to say)
		greeterReady()
	end
	local inBuild, holding = building()
	local busy = creating() or menuUp() or Dialogue.isOpen() or d.talking == true
	if not step then
		-- all done: the last line, if a step was shown this session
		undim()
		if sawSteps and not said.done then
			if holding then
				putAwayFor("done")
			elseif not busy and greeterReady() then
				sayLine("done", Steps.Lines.done)
			end
		end
		return
	end
	local here = step :: number
	if not said[here] then
		-- the friend says what this step is first
		undim()
		if here == 1 and os.clock() - (knownAt :: number) < K.FirstAfter then
			return
		end
		if holding and here > 1 then
			putAwayFor(here)
		elseif not busy and not holding and greeterReady() then
			sawSteps = true
			sayLine(here, Steps.Lines[here])
		end
		return
	end
	sawSteps = true
	-- (with the main screen slid away by Hide, nothing is darkened: Show must stay pressable)
	local hidden = not inBuild and hudApi ~= nil and hudApi.isHidden ~= nil and hudApi.isHidden()
	if busy or holding or hidden then
		undim()
		return
	end
	local target, how = targetFor(here)
	if not target or not shown(target) then
		undim()
		return
	end
	dimAt(here, target, how)
end

function Tutorial.start(hud: any)
	if started then
		return
	end
	started = true
	hudApi = hud
	local l = Kit.box({ Name = "Tutorial", Parent = Kit.root(), Size = UDim2.fromScale(1, 1) })
	-- over the main screen and Build mode, under the menus (a menu's holder is 5) and the scenes
	l.ZIndex = 4
	layer = l
	local function soon()
		task.defer(function()
			local ok, err = pcall(Tutorial.refresh)
			if not ok then
				warn("[Tutorial] " .. tostring(err))
			end
		end)
	end
	for _, key in { "tutorial", "villagers", "order", "talking" } do
		State.on(key, soon)
	end
	State.onPlan(soon)
	Kit.onTheme(function()
		-- drawn again in the new look
		if dim then
			undim()
			dim:Destroy()
			dim = nil
			soon()
		end
	end)
	task.spawn(function()
		while true do
			local ok, err = pcall(Tutorial.refresh)
			if not ok then
				warn("[Tutorial] " .. tostring(err))
			end
			task.wait(EVERY)
		end
	end)
end

return Tutorial
