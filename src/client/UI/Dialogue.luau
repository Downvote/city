-- The scene a conversation plays in: the villagers who are in it slide in from the sides as big
-- busts, and what is said is typed into one wide dark textbox across the bottom of the screen.
-- The user, with a picture of another game's dialogue scene: "when text from a villager appears,
-- make the character talking slide into view at the side with a textbox as such. if there are
-- more than one character, slide multiple in". Taken from it: the layout (people from the waist
-- up at the sides, in front of the world, a wide near black box over their lower half, the
-- speaker's name on a pill on the box's top left edge and the other's, dimmed, on its top right).
-- Drawn our own way, with our villagers and our words.
--
-- One scene at a time; the talk card (UI/TalkCard) and a watched event (UI/EventCard) build it.
-- The first villager to join stands at the left, the second at the right, a third and a fourth
-- further in toward the middle, a little smaller and set back, so nobody hides a face. Whoever
-- is talking is in full colour and a touch forward, the others dimmed and a touch back. A line
-- nobody in particular says shows everyone dimmed. While a scene is up, State's "talking" is true
-- (the main screen steps aside for it).
--
-- A watched event that has a cutscene (Data/Cutscenes) opens the same scene with a Stage: the
-- villagers then stand on a set of their own behind the box (UI/Cutscene) instead of sliding in
-- as busts, and each line tells the set what is happening (beat). The box, the tags and the way it
-- closes are the same.
--
-- A scene that goes on (a watched event: OnClick) moves only when the player says so: a click or
-- a tap on the box, or Enter, E or a gamepad's X (the user: "sometimes, chats suddenly cut to the
-- next dialogue without the player input"). Every press counts at once (the user: "sometimes,
-- clicking on dialogue dosent advance it, lagging behind instead"): a press while a line is being
-- typed shows the rest of it, and the next goes on. The scene types its lines itself (scene.type),
-- so it always knows which of the two a press is: a line is all there the moment its last letter
-- shows, never a beat later. Space and a gamepad's A are the character's own: the player can jump
-- while a scene is up (the user: "make it such that the player can jump while in conversation, a
-- bug prevents you from doing it"; the scene used to take Space for itself). The keys it does take
-- are handed back while the answers are up or a text box has the keys. A small arrow at the bottom
-- right of the words says a press goes on (the caller shows it).
--
-- The box and the name tags are dark glass with white words in both looks, like the slabs over
-- the 3D view, with nothing round their edges (the user: "for bubbles and text in rounded
-- rectangles everywhere, remove the borders"). Each bust is a copy of the villager's own model (UI/ModelPreview, the whole of them
-- in a frame cut off at the hips by its holder). A villager whose model can't be found gets no
-- bust, only a round mark in their colour on their name tag.
--
-- What an event puts on a villager (a hat, a scarf: Sim/Memory) shows on their bust from the line
-- they put it on with (the user: "when villagers equip accessories from random event, the
-- conversation showing it should show it"): scene.wear(key, what) makes the bust again once their
-- model has it on (the server lists it in the model's `Worn`), and a scene watched from the start
-- leaves it off their bust until then (an actor's `without`, the accessories the server marked).

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ContextActionService = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")

local Kit = require(script.Parent.Kit)
local Icons = require(script.Parent.Icons)
local ModelPreview = require(script.Parent.ModelPreview)
local Cutscene = require(script.Parent.Cutscene)
local State = require(script.Parent.Parent.Controllers.State)
local Audio = require(script.Parent.Parent.Controllers.Audio)

local Babble = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared").Sim.Babble)

local Dialogue = {}

local T = Kit.Theme
local player = Players.LocalPlayer

-- (`image`: a picture standing in for a model, as a full length avatar picture: the tutorial's
-- greeter when the server couldn't build their look; `voice`: the voice they talk in (Sim/Babble),
-- else a villager's own, found by `vid`)
export type Actor = {
	key: string,
	name: string,
	color: Color3,
	model: Model?,
	vid: string?,
	image: string?,
	without: { [string]: boolean }?, -- what they put on later in the scene, off their bust until then
	voice: Babble.Voice?,
}

-- the layout, in the interface's own pixels (a 1280 by 720 screen is about 1350 by 720 of them)
local BOX_W = 0.74 -- the textbox's share of the screen's width
local BOX_GAP = 20 -- under the box
local SHOW = 470 -- how much of a bust shows: hips to over the head (about 60% of the screen)
local FIGURE = 660 -- the whole of them, head to foot, in the frame the holder cuts off
local WIDE = 340
-- where each of up to four stands: share of the width across, size, which way they face, depth,
-- and how far up the screen (the two further in stand further back, so a little higher)
local SLOTS = {
	{ x = 0.15, size = 1, yaw = -18, z = 4, side = "left", lift = 0 },
	{ x = 0.85, size = 1, yaw = 18, z = 4, side = "right", lift = 0 },
	{ x = 0.33, size = 0.86, yaw = -12, z = 2, side = "left", lift = 44 },
	{ x = 0.67, size = 0.86, yaw = 12, z = 2, side = "right", lift = 44 },
}
local DIM = Color3.fromRGB(112, 112, 122) -- a bust that isn't talking, multiplied in
local BACK = 14 -- how far down a dimmed bust sits

-- The keys that go on as a click does, while a scene that goes on is up (never Space or a gamepad's
-- A: those jump).
Dialogue.Keys = { Enum.KeyCode.Return, Enum.KeyCode.KeypadEnter, Enum.KeyCode.E, Enum.KeyCode.ButtonX }
-- seconds between letters being typed, and how many come at a time
Dialogue.TypeEvery = 0.03
Dialogue.TypeStep = 2
Dialogue.Action = "DialogueNext" -- the ContextActionService action that holds them

-- the glass's own shades, the same in both looks
local function glass(k: number): Color3
	return T.Glass:Lerp(T.White, k)
end

local current: any = nil

-- A name tag: a dark pill on the box's edge with a mark in the villager's colour and their name.
local function tag(parent: Instance, name: string, right: boolean): any
	local pill = Kit.new("Frame", {
		Name = name,
		BackgroundColor3 = T.Shadow,
		BorderSizePixel = 0,
		Size = UDim2.fromOffset(0, 36),
		AutomaticSize = Enum.AutomaticSize.X,
		Position = if right then UDim2.new(1, -28, 0, 0) else UDim2.fromOffset(28, 0),
		AnchorPoint = Vector2.new(if right then 1 else 0, 0.5),
		ZIndex = 6,
		Visible = false,
		Parent = parent,
	})
	-- a leaning tag, its slanted ends standing out past the name (what is on it sits in a row of
	-- its own, so the painted slab under it is left where it is)
	Kit.slant(pill, 36, true)
	local row = Kit.new("Frame", {
		Name = "Row",
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(0, 36),
		AutomaticSize = Enum.AutomaticSize.X,
		ZIndex = 7,
		Parent = pill,
	})
	Kit.new("UIPadding", {
		PaddingLeft = UDim.new(0, 6),
		PaddingRight = UDim.new(0, 10),
		Parent = row,
	})
	Kit.list(row, 8, true)
	local mark = Kit.new("Frame", {
		Name = "Mark",
		BackgroundColor3 = T.Orange,
		BorderSizePixel = 0,
		Size = UDim2.fromOffset(12, 12),
		LayoutOrder = 1,
		ZIndex = 7,
		Parent = row,
	})
	Kit.corner(mark, "round")
	local label = Kit.new("TextLabel", {
		Name = "Text",
		Text = "",
		BackgroundTransparency = 1,
		Font = Kit.Fonts.Title,
		TextSize = 19,
		TextColor3 = T.White,
		Size = UDim2.fromOffset(0, 36),
		AutomaticSize = Enum.AutomaticSize.X,
		LayoutOrder = 2,
		ZIndex = 7,
		Parent = row,
	})
	return { pill = pill, mark = mark, label = label, key = nil }
end

-- Puts `actor` on a tag (or takes it off), bright when they are talking.
local function fillTag(t: any, actor: Actor?, bright: boolean, hasBust: boolean)
	t.pill.Visible = actor ~= nil
	t.key = actor and actor.key
	if not actor then
		return
	end
	t.label.Text = actor.name
	t.mark.BackgroundColor3 = actor.color
	-- with no bust, the mark grows into a bigger round mark of them
	local d = if hasBust then 12 else 22
	t.mark.Size = UDim2.fromOffset(d, d)
	local info = TweenInfo.new(0.18)
	TweenService:Create(t.label, info, { TextColor3 = if bright then T.White else glass(0.5) }):Play()
	-- (the tag is a painted slab: its picture fades, never its own background)
	Kit.fade(t.pill, info, if bright then 0 else 0.25)
end

-- A bust: a holder cut off at the hips, standing at the bottom of the screen in its slot, the
-- villager's copy inside it. Starts off screen at its side; slides in.
local function bust(layer: Frame, actor: Actor, slotIndex: number): any
	local slot = SLOTS[slotIndex]
	local w, show, fig = math.floor(WIDE * slot.size), math.floor(SHOW * slot.size), math.floor(FIGURE * slot.size)
	local off = if slot.side == "left" then -(w + 80) else w + 80
	local holder = Kit.new("Frame", {
		Name = "Bust_" .. actor.key,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Size = UDim2.fromOffset(w, show),
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(if slot.side == "left" then 0 else 1, off, 1, BACK - slot.lift),
		ZIndex = slot.z,
		Parent = layer,
	})
	-- the whole of them, so the holder shows the waist up (named Avatar: the previews draw a
	-- stand-in figure in it, and its tint dims them)
	local figure = Kit.new("ImageLabel", {
		Name = "Avatar",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Image = if actor.model then "" else actor.image or "",
		ScaleType = Enum.ScaleType.Crop,
		Size = UDim2.new(1, 0, 0, fig),
		ZIndex = slot.z,
		Parent = holder,
	})
	local vp: ViewportFrame? = nil
	if actor.model then
		local model = actor.model :: Model
		pcall(function()
			vp =
				ModelPreview.fromModel(model, { Parent = figure, Bust = true, Yaw = slot.yaw, Without = actor.without })
		end)
		if vp then
			vp.ZIndex = slot.z
		end
	end
	return {
		holder = holder,
		figure = figure,
		vp = vp,
		slot = slot,
		x = slot.x,
		lit = nil,
	}
end

-- Moves a bust to where it rests, lit or dimmed.
local function place(b: any, lit: boolean, instant: boolean?)
	local slot = b.slot
	local target = UDim2.new(
		slot.x,
		if lit then 0 else (if slot.side == "left" then -10 else 10),
		1,
		(if lit then 0 else BACK) - slot.lift
	)
	local tint = if lit then T.White else DIM
	local info = TweenInfo.new(if instant then 0 else 0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	if b.lit == nil then
		-- sliding in
		info = TweenInfo.new(0.42, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	end
	b.lit = lit
	TweenService:Create(b.holder, info, { Position = target }):Play()
	TweenService:Create(b.figure, info, { ImageColor3 = tint }):Play()
	if b.vp then
		TweenService:Create(b.vp, info, { ImageColor3 = tint }):Play()
	end
	-- the one talking stands in front
	b.holder.ZIndex = if lit then slot.z + 1 else slot.z
end

-- Finds a villager's model in the player's own plot (the server keeps them there, each marked
-- with its villager's id).
function Dialogue.modelOf(vid: string?): Model?
	if type(vid) ~= "string" then
		return nil
	end
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
	return nil
end

-- Is a scene up?
function Dialogue.isOpen(): boolean
	return current ~= nil
end

-- Opens a scene, putting away any other at once. opts: Name (the root's name), OnClick (a press
-- once the line is all there, by a click, a tap or a key: go on), Caption (dim words at the box's
-- foot, left), Stage (a cutscene to play behind the box: the options UI/Cutscene takes). Returns
-- the scene: { root, box, words (the line, "Line"), note ("Note", at the foot), answers (a box
-- under the words for buttons), tools (a row at the foot's right for small buttons), more (the
-- arrow), stage (the cutscene, if any) } and its methods join(actor), speak(key?), has(key),
-- beat(line), next() (what a press does), close().
function Dialogue.open(opts: { [string]: any }?): any
	local o = opts or {}
	if current then
		current.close(true)
	end
	local gui = Kit.root()
	local root = Kit.box({ Name = o.Name or "Dialogue", Size = UDim2.fromScale(1, 1), Parent = gui })
	root.ZIndex = 20
	root:SetAttribute("KeepColors", true)
	-- a soft dark under the bottom of the screen, so the box and the busts read over any town
	local fade = Kit.new("Frame", {
		Name = "Fade",
		BackgroundColor3 = T.Shadow,
		BackgroundTransparency = 0.35,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 0.5),
		Position = UDim2.fromScale(0, 0.5),
		ZIndex = 0,
		Parent = root,
	})
	Kit.new("UIGradient", {
		Name = "Clear",
		Rotation = 90,
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.6, 0.5),
			NumberSequenceKeypoint.new(1, 0),
		}),
		Parent = fade,
	})
	local layer = Kit.box({ Name = "Cast", Size = UDim2.fromScale(1, 1), Parent = root })
	layer.ZIndex = 1
	-- a cutscene stands the villagers on a set behind the box, over the whole screen
	local stage: any = nil
	if o.Stage then
		local ok, made = pcall(Cutscene.new, root, o.Stage)
		if ok and made then
			stage = made
			fade.Visible = false
		else
			warn("cutscene: " .. tostring(made))
		end
	end
	-- the box
	local box = Kit.new("Frame", {
		Name = "Box",
		BackgroundColor3 = T.Glass,
		BackgroundTransparency = 0.04,
		BorderSizePixel = 0,
		Size = UDim2.new(BOX_W, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -BOX_GAP),
		ZIndex = 5,
		Parent = root,
	})
	box.Active = true
	Kit.corner(box, 16)
	Kit.softShadow(box, 1.2)
	-- a band of hatching in its bottom right corner (no rim, no brackets round its edge)
	Kit.hatch({
		Parent = box,
		Size = UDim2.fromOffset(110, 8),
		Position = UDim2.new(1, -28, 1, -8),
		AnchorPoint = Vector2.new(1, 1),
		Color = T.White,
		Transparency = 0.86,
		Fade = "left",
		ZIndex = 6,
	})
	local inner = Kit.box({ Name = "Inner", Parent = box, Size = UDim2.new(1, 0, 0, 0) })
	inner.AutomaticSize = Enum.AutomaticSize.Y
	inner.ZIndex = 6
	Kit.new("UIPadding", {
		PaddingLeft = UDim.new(0, 30),
		PaddingRight = UDim.new(0, 30),
		PaddingTop = UDim.new(0, 28),
		PaddingBottom = UDim.new(0, 14),
		Parent = inner,
	})
	Kit.list(inner, 10)
	local words = Kit.new("TextLabel", {
		Name = "Line",
		Text = "",
		BackgroundTransparency = 1,
		Font = Kit.Fonts.Title,
		TextSize = 25,
		TextColor3 = T.White,
		TextWrapped = true,
		RichText = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		Size = UDim2.new(1, -24, 0, 62),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = 1,
		ZIndex = 6,
		Parent = inner,
	})
	words.LineHeight = 1.12
	local answers = Kit.box({ Name = "Answers", Parent = inner, Size = UDim2.new(1, 0, 0, 0) })
	answers.AutomaticSize = Enum.AutomaticSize.Y
	answers.LayoutOrder = 2
	answers.ZIndex = 6
	-- the foot: a dim note at the left, small buttons at the right
	local foot = Kit.box({ Name = "Foot", Parent = inner, Size = UDim2.new(1, 0, 0, 36) })
	foot.LayoutOrder = 3
	foot.ZIndex = 6
	-- a hairline over the foot that ends in a dot at each end
	Kit.rule({
		Name = "Rule",
		Parent = foot,
		Size = UDim2.new(1, 0, 0, 6),
		Position = UDim2.fromOffset(0, -4),
		AnchorPoint = Vector2.new(0, 0.5),
		Color = T.White,
		Transparency = 0.84,
		Dots = "both",
		ZIndex = 6,
	})
	local note = Kit.new("TextLabel", {
		Name = "Note",
		Text = o.Caption or "",
		BackgroundTransparency = 1,
		Font = Kit.Fonts.Body,
		TextSize = 15,
		TextColor3 = glass(0.62),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Size = UDim2.new(0.6, 0, 1, 0),
		ZIndex = 6,
		Parent = foot,
	})
	local tools = Kit.box({
		Name = "Tools",
		Parent = foot,
		Size = UDim2.new(0.4, 0, 1, 0),
		Position = UDim2.fromScale(1, 0),
		AnchorPoint = Vector2.new(1, 0),
	})
	tools.ZIndex = 6
	Kit.list(tools, 8, true, Enum.HorizontalAlignment.Right)
	-- the arrow that says a press goes on, at the bottom right corner of the words (in the gap
	-- left at their right)
	local more = Icons.make("down", 18, {
		Name = "More",
		Parent = words,
		Position = UDim2.new(1, 4, 1, -6),
		AnchorPoint = Vector2.new(0, 1),
		Color = T.Yellow,
		ZIndex = 7,
	})
	more.Visible = false
	-- it bobs on the spot, slowly, while it is up
	TweenService:Create(more, TweenInfo.new(0.55, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
		Position = more.Position + UDim2.fromOffset(0, 4),
	}):Play()
	-- the name tags on the box's top edge
	local left = tag(box, "Speaker", false)
	local right = tag(box, "Other", true)
	-- The line being typed: a couple of letters at a time until the last one shows, which is the
	-- moment it is all there (so no press is ever spent on a line that already looks whole).
	-- As a line types, whoever says it babbles in their voice (Controllers/Audio, Sim/Babble: the
	-- user, "Like tomodachi life, can you make it such that villagers have voices"), a syllable
	-- every few letters; a press that shows the rest stops it. A line nobody says is quiet.
	local typing = 0 -- goes up with every line and whenever one is finished, so an old typist stops
	local typingNow = false
	local onTyped: (() -> ())? = nil
	local talker: Audio.Talker? = nil
	local voiceNow: () -> Babble.Voice? = function()
		return nil
	end -- (the speaker's, once the cast is known: below)
	local function finish()
		if talker then
			talker.stop()
			talker = nil
		end
		if not typingNow then
			return
		end
		typing += 1
		typingNow = false
		words.MaxVisibleGraphemes = -1
		local done = onTyped
		onTyped = nil
		if done then
			done()
		end
	end
	-- Types `text` into the box (`plain`: the same words without rich text tags, to count its
	-- letters); `done` runs once it is all there, typed out or shown at a press.
	local function typeOut(text: string, plain: string?, done: (() -> ())?)
		typing += 1
		local mine = typing
		onTyped = nil
		typingNow = false
		words.Text = text
		more.Visible = false
		local count = utf8.len(plain or text) or #(plain or text)
		if count <= 0 then
			words.MaxVisibleGraphemes = -1
			if done then
				done()
			end
			return
		end
		typingNow = true
		onTyped = done
		words.MaxVisibleGraphemes = 0
		if talker then
			talker.stop()
		end
		local voice = Audio.talker(voiceNow(), plain or text)
		talker = voice
		task.spawn(function()
			local shown = 0
			while typing == mine and root.Parent do
				shown += Dialogue.TypeStep
				voice.to(shown) -- (a word too short to type still gets its syllable)
				if shown >= count then
					break
				end
				words.MaxVisibleGraphemes = shown
				task.wait(Dialogue.TypeEvery)
			end
			if typing == mine then
				finish()
			end
		end)
	end
	-- a press shows the rest of a line being typed, or (once it is all there) goes on
	local function press()
		if not root.Parent then
			return
		end
		if typingNow then
			finish()
		elseif o.OnClick then
			o.OnClick()
		end
	end
	-- a click or a tap on the box
	box.InputBegan:Connect(function(input)
		if
			input.UserInputType ~= Enum.UserInputType.MouseButton1
			and input.UserInputType ~= Enum.UserInputType.Touch
		then
			return
		end
		press()
	end)

	local cast: { any } = {} -- { actor, bust? } in the order they joined
	local speaking: string? = nil
	local self: any = {
		root = root,
		box = box,
		words = words,
		note = note,
		answers = answers,
		tools = tools,
		more = more,
		left = left,
		right = right,
		stage = stage,
	}

	local function entryOf(key: string): any
		for _, e in cast do
			if e.actor.key == key then
				return e
			end
		end
		return nil
	end

	-- the voice of whoever is talking now: their own, a villager's saved one, or the one on their
	-- model (a villager in another town)
	voiceNow = function(): Babble.Voice?
		local e = speaking and entryOf(speaking)
		if not e then
			return nil
		end
		local a = e.actor
		if a.voice then
			return a.voice
		end
		local v = if a.vid then State.villager(a.vid) else nil
		if v then
			return Babble.of(v)
		end
		local model = a.model
		return if model then Babble.decode(model:GetAttribute("Voice")) else nil
	end

	-- the tags: the latest to speak on each side, bright if they're the one talking
	local sideOf: { [string]: string } = {}
	local shown: { left: string?, right: string? } = {}
	local function refresh()
		for i, e in cast do
			local lit = speaking ~= nil and e.actor.key == speaking
			if e.bust then
				place(e.bust, lit)
			end
			sideOf[e.actor.key] = SLOTS[math.min(i, #SLOTS)].side
		end
		if speaking and sideOf[speaking] then
			shown[sideOf[speaking]] = speaking
		end
		if not speaking then
			-- a line nobody in particular says: everyone dimmed and no names up
			fillTag(left, nil, false, false)
			fillTag(right, nil, false, false)
			return
		end
		for _, side in { "left", "right" } do
			local key = shown[side]
			if not key then
				-- nobody on that side has spoken yet: the first one standing there
				for i, e in cast do
					if SLOTS[math.min(i, #SLOTS)].side == side then
						key = e.actor.key
						break
					end
				end
			end
			local e = key and entryOf(key)
			local t = if side == "left" then left else right
			local shown = e ~= nil and (e.bust ~= nil or (stage ~= nil and stage.shows(e.actor.key)))
			fillTag(t, e and e.actor, e ~= nil and e.actor.key == speaking, shown)
		end
	end

	function self.has(key: string): boolean
		return entryOf(key) ~= nil
	end

	-- What a click, a tap or a key does.
	self.next = press

	-- Types a line into the box (see typeOut above); is one still being typed?
	self.type = typeOut
	function self.typing(): boolean
		return typingNow
	end

	-- Someone joins the scene: they slide in at the next free place (at most four stand; anyone
	-- after that is on the tags only).
	function self.join(actor: Actor)
		if entryOf(actor.key) or not root.Parent then
			return
		end
		local e: any = { actor = actor, bust = nil }
		table.insert(cast, e)
		local i = #cast
		if stage then
			stage.join(actor)
		elseif (actor.model or actor.image) and i <= #SLOTS then
			e.bust = bust(layer, actor, i)
		end
		refresh()
	end

	-- A model found late (the server was asked for it): their bust slides in then.
	function self.found(key: string, model: Model)
		local e = entryOf(key)
		if not e or e.bust or not root.Parent then
			return
		end
		if stage then
			e.actor.model = model
			stage.found(key, model)
			refresh()
			return
		end
		local i = table.find(cast, e) or 1
		if i <= #SLOTS then
			e.actor.model = model
			e.bust = bust(layer, e.actor, i)
			refresh()
		end
	end

	-- They put `what` on with this line: their bust is made again once their model wears it (the
	-- server dresses it as the line is said, which can take a moment the first time).
	function self.wear(key: string, what: string)
		local e = entryOf(key)
		if not e or not root.Parent then
			return
		end
		if e.actor.without then
			e.actor.without[what] = nil
		end
		local model = e.actor.model
		if not model or not e.bust then
			return
		end
		local function wearing(): boolean
			for w in string.gmatch(tostring(model:GetAttribute("Worn") or ""), "[^,]+") do
				if w == what then
					return true
				end
			end
			return false
		end
		local function again()
			local b = e.bust
			if not b or not root.Parent or current ~= self then
				return
			end
			local made: ViewportFrame? = nil
			pcall(function()
				made = ModelPreview.fromModel(
					model,
					{ Parent = b.figure, Bust = true, Yaw = b.slot.yaw, Without = e.actor.without }
				)
			end)
			if not made then
				return
			end
			local old = b.vp
			made.ZIndex = b.slot.z
			made.ImageColor3 = if b.lit then T.White else DIM
			b.vp = made
			if old then
				old:Destroy()
			end
		end
		if wearing() then
			again()
			return
		end
		local done = false
		local conn: RBXScriptConnection? = nil
		conn = model:GetAttributeChangedSignal("Worn"):Connect(function()
			if not done and wearing() then
				done = true
				if conn then
					conn:Disconnect()
				end
				again()
			end
		end)
		task.delay(12, function()
			done = true
			if conn then
				conn:Disconnect()
			end
		end)
	end

	-- Who is talking now (nil: nobody in particular).
	function self.speak(key: string?)
		speaking = if key and entryOf(key) then key else nil
		refresh()
	end

	-- What is being said now, for the set behind the box (a line, { ask = true } or
	-- { ending = true }): nothing happens without one.
	function self.beat(line: any)
		if stage then
			stage.beat(line)
		end
	end

	-- Takes the scene down: everyone slides out and it goes (at once with `now`).
	function self.close(now: boolean?)
		if talker then
			talker.stop()
			talker = nil
		end
		if current == self then
			current = nil
			State.set("talking", false)
			-- (only the scene up now holds the keys: one put away later must not take them off it)
			if o.OnClick then
				pcall(function()
					ContextActionService:UnbindAction(Dialogue.Action)
				end)
			end
		end
		if not root.Parent then
			return
		end
		root.Name = "Leaving"
		if stage then
			stage.close(now)
		end
		if now then
			root:Destroy()
			return
		end
		local info = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		for _, e in cast do
			if e.bust then
				local slot = e.bust.slot
				local w = e.bust.holder.Size.X.Offset
				TweenService:Create(e.bust.holder, info, {
					Position = UDim2.new(
						if slot.side == "left" then 0 else 1,
						if slot.side == "left" then -(w + 80) else w + 80,
						1,
						BACK - slot.lift
					),
				}):Play()
			end
		end
		TweenService:Create(box, info, { Position = UDim2.new(0.5, 0, 1, 260) }):Play()
		TweenService:Create(fade, info, { BackgroundTransparency = 1 }):Play()
		task.delay(0.35, function()
			root:Destroy()
		end)
	end

	current = self
	State.set("talking", true)
	-- the keys that go on, taken while it is up (none of them is the character's: Space still
	-- jumps) and handed back while the answers are up or the player is typing somewhere
	if o.OnClick then
		pcall(function()
			ContextActionService:BindActionAtPriority(Dialogue.Action, function(_, state: Enum.UserInputState)
				if current ~= self or UserInputService:GetFocusedTextBox() ~= nil then
					return Enum.ContextActionResult.Pass
				end
				for _, c in answers:GetChildren() do
					if c:IsA("GuiButton") then
						return Enum.ContextActionResult.Pass
					end
				end
				if state == Enum.UserInputState.Begin then
					press()
				end
				return Enum.ContextActionResult.Sink
			end, false, Enum.ContextActionPriority.High.Value, table.unpack(Dialogue.Keys))
		end)
	end
	-- the box rises into place
	box.Position = UDim2.new(0.5, 0, 1, 200)
	TweenService:Create(box, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, 0, 1, -BOX_GAP),
	}):Play()
	return self
end

-- A box to type into in the scene (a name an event asks for: UI/EventCard), the glass of the
-- answers with white words in both looks. props: Parent, Name, Size, LayoutOrder, Text,
-- Placeholder, Max (letters).
function Dialogue.field(props: { [string]: any }?): TextBox
	local p = props or {}
	local box = Kit.textbox(p.Placeholder or "", {
		Name = p.Name or "Field",
		Parent = p.Parent,
		Size = p.Size or UDim2.new(1, 0, 0, 44),
		LayoutOrder = p.LayoutOrder or 0,
		Text = p.Text or "",
		TextSize = p.TextSize or 18,
	})
	box.BackgroundColor3 = glass(0.14)
	box.TextColor3 = T.White
	box.PlaceholderColor3 = glass(0.5)
	box.Font = Kit.Fonts.Title
	box.ZIndex = 7
	box.ClearTextOnFocus = false
	if type(p.Max) == "number" then
		local max = p.Max
		box:GetPropertyChangedSignal("Text"):Connect(function()
			local n = utf8.len(box.Text)
			local cut = utf8.offset(box.Text, max + 1)
			if n and n > max and cut then
				box.Text = string.sub(box.Text, 1, cut - 1)
			end
		end)
	end
	return box
end

-- A pill for an answer, dark in both looks; under the pointer it turns the picked yellow. props:
-- Parent, Name, Size, LayoutOrder, TextSize, Rich, Disabled, Icon.
function Dialogue.answer(text: string, props: { [string]: any }?, onClick: (() -> ())?): TextButton
	local p = props or {}
	local rest = if p.Disabled then glass(0.05) else glass(0.14)
	local words = if p.Disabled then glass(0.45) else T.White
	local b = Kit.button(text, {
		Name = p.Name or text,
		Parent = p.Parent,
		Size = p.Size or UDim2.fromOffset(140, 42),
		LayoutOrder = p.LayoutOrder or 0,
		Color = rest,
		TextColor = words,
		TextSize = p.TextSize or 18,
		Radius = "pill",
		Icon = p.Icon,
		ZIndex = 7,
	}, onClick)
	if p.Rich then
		local label = b:FindFirstChild("Label", true)
		if label and label:IsA("TextLabel") then
			label.RichText = true
		end
	end
	if not p.Disabled then
		b.MouseEnter:Connect(function()
			Kit.setButtonColor(b, T.Yellow, T.Dark)
		end)
		b.MouseLeave:Connect(function()
			Kit.setButtonColor(b, rest, words)
		end)
	end
	return b
end

return Dialogue
