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
-- The box and the name tags are dark glass with white words in both looks, like the slabs over
-- the 3D view. Each bust is a copy of the villager's own model (UI/ModelPreview, the whole of them
-- in a frame cut off at the hips by its holder). A villager whose model can't be found gets no
-- bust, only a round mark in their colour on their name tag.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Kit = require(script.Parent.Kit)
local Icons = require(script.Parent.Icons)
local ModelPreview = require(script.Parent.ModelPreview)
local Cutscene = require(script.Parent.Cutscene)
local State = require(script.Parent.Parent.Controllers.State)

local Dialogue = {}

local T = Kit.Theme
local player = Players.LocalPlayer

export type Actor = { key: string, name: string, color: Color3, model: Model?, vid: string? }

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
	Kit.corner(pill, "pill")
	local rim = Kit.rim(pill, T.White, 1.5, 0.3)
	Kit.new("UIPadding", {
		PaddingLeft = UDim.new(0, 8),
		PaddingRight = UDim.new(0, 18),
		Parent = pill,
	})
	Kit.list(pill, 8, true)
	local mark = Kit.new("Frame", {
		Name = "Mark",
		BackgroundColor3 = T.Orange,
		BorderSizePixel = 0,
		Size = UDim2.fromOffset(12, 12),
		LayoutOrder = 1,
		ZIndex = 7,
		Parent = pill,
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
		Parent = pill,
	})
	return { pill = pill, rim = rim, mark = mark, label = label, key = nil }
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
	-- with no bust, the mark grows into a round mark of them in a ring
	local d = if hasBust then 12 else 24
	t.mark.Size = UDim2.fromOffset(d, d)
	local ring = t.mark:FindFirstChild("Ring")
	if not hasBust and not ring then
		Kit.rim(t.mark, T.White, 1.5, 0.35).Name = "Ring"
	elseif hasBust and ring then
		ring:Destroy()
	end
	local info = TweenInfo.new(0.18)
	TweenService:Create(t.label, info, { TextColor3 = if bright then T.White else glass(0.5) }):Play()
	TweenService:Create(t.rim, info, { Transparency = if bright then 0.3 else 0.82 }):Play()
	TweenService:Create(t.pill, info, { BackgroundTransparency = if bright then 0 else 0.25 }):Play()
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
		Image = "",
		Size = UDim2.new(1, 0, 0, fig),
		ZIndex = slot.z,
		Parent = holder,
	})
	local vp: ViewportFrame? = nil
	if actor.model then
		local model = actor.model :: Model
		pcall(function()
			vp = ModelPreview.fromModel(model, { Parent = figure, Bust = true, Yaw = slot.yaw })
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

-- Opens a scene, putting away any other at once. opts: Name (the root's name), OnClick (a click
-- on the box once the line is all there: move on), Caption (dim words at the box's foot, left),
-- Stage (a cutscene to play behind the box: the options UI/Cutscene takes). Returns the
-- scene: { root, box, words (the line, "Line"), note ("Note", at the foot), answers (a box under
-- the words for buttons), tools (a row at the foot's right for small buttons), more (the arrow),
-- stage (the cutscene, if any) } and its methods join(actor), speak(key?), has(key), beat(line),
-- close().
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
	Kit.rim(box, T.White, 1.5, 0.78)
	Kit.softShadow(box, 1.2)
	-- brackets on its four corners, just inside the edge, and a band of hatching in its bottom
	-- right corner
	Kit.brackets(box, {
		Corners = { "tl", "tr", "bl", "br" },
		Arm = 14,
		Thick = 2,
		Inset = 7,
		Color = T.White,
		Transparency = 0.55,
		ZIndex = 6,
	})
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
	-- the arrow that says a click moves on
	local more = Icons.make("down", 18, {
		Name = "More",
		Parent = box,
		Position = UDim2.new(1, -22, 0, 30),
		AnchorPoint = Vector2.new(1, 0),
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
	-- a click on the box shows the rest of a line being typed, or (once it is all there) moves on
	box.InputBegan:Connect(function(input)
		if
			input.UserInputType ~= Enum.UserInputType.MouseButton1
			and input.UserInputType ~= Enum.UserInputType.Touch
		then
			return
		end
		if words.MaxVisibleGraphemes ~= -1 then
			words.MaxVisibleGraphemes = -1
		elseif o.OnClick then
			o.OnClick()
		end
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
		elseif actor.model and i <= #SLOTS then
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
		if current == self then
			current = nil
			State.set("talking", false)
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
	-- the box rises into place
	box.Position = UDim2.new(0.5, 0, 1, 200)
	TweenService:Create(box, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, 0, 1, -BOX_GAP),
	}):Play()
	return self
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
