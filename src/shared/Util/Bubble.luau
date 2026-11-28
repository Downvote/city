-- What floats over a villager's head, drawn the same way by the server and the client: a speech
-- card (what they say out loud in the town, Npc.say), a mood badge (Npc.icon) and the frame of a
-- wish bubble (World/Wishes). The user: "improve villager bubbles above their head ... also, they
-- sometimes intersect villager speech bubbles". So they wear the interface's look (the dark glass
-- over the 3D view, a little point at the bottom toward the head), and they all hang from one point
-- over the head, one above the other: World/Bubbles stacks them and keeps two villagers' stacks
-- apart. They have no rim (the user: "could you remove all borders in bubbles and text bubbles?").
--
-- Plain instances and no services, so the server can build them too. Each piece is a CanvasGroup
-- named Fade (World/Bubbles fades it as one and moves it), its bottom edge where the stack puts it.

local Bubble = {}

-- Every head billboard hangs from this point over the head's middle, in studs, and is this many
-- pixels tall with that point in its middle; what is in it is placed in pixels above that point.
Bubble.Anchor = Vector3.new(0, 2.4, 0)
Bubble.Tall = 760
Bubble.Base = 14 -- the bottom of the stack, in pixels over that point (clear of a name tag)
Bubble.Gap = 6 -- between two things in one stack
-- seconds between a piece being marked `Going` and it going: time for its way out (World/Bubbles)
Bubble.Leave = 0.35

-- the glass over the 3D view (UI/Kit's Glass), the same in both looks; solid, so a point laid over
-- a card's edge doesn't show as a darker patch
local GLASS = Color3.fromRGB(12, 12, 15)
Bubble.Glass = GLASS
-- The widest a speech card's words run before they wrap (the user: "make it such that textboxes
-- that appear over the head of villages have a longer max width").
Bubble.SpeechWidth = 340
local INK = Color3.fromRGB(240, 240, 236)
Bubble.Yellow = Color3.fromRGB(255, 210, 64)

-- The little symbols a villager shows over their head, and their colours.
Bubble.Moods = {
	heart = { "♥", Color3.fromRGB(240, 116, 136) },
	anger = { "!!", Color3.fromRGB(232, 66, 60) },
	music = { "♪", Color3.fromRGB(116, 178, 236) },
	sweat = { "...", Color3.fromRGB(150, 176, 220) },
	zzz = { "zzz", Color3.fromRGB(186, 156, 232) },
	idea = { "!", Color3.fromRGB(255, 210, 64) },
	question = { "?", Color3.fromRGB(206, 176, 150) },
	sparkle = { "✦", Color3.fromRGB(255, 196, 80) },
	sad = { "T_T", Color3.fromRGB(120, 160, 220) },
}

-- On a player's screen each symbol is drawn as an icon (UI/Icons) this many pixels across, filling
-- the badge (the user: "the icons within bubbles are too small"; World/Bubbles swaps it in). The
-- symbol in words above stays for a screen that can't draw them.
Bubble.MoodIcons = {
	heart = "heart",
	anger = "anger",
	music = "music",
	sweat = "water",
	zzz = "moon",
	idea = "bulb",
	question = "question",
	sparkle = "sparkle",
	sad = "rain",
}
Bubble.MoodIcon = 28

local function new(class: string, props: { [string]: any }): any
	local inst = Instance.new(class)
	local parent = props.Parent
	for k, v in props do
		if k ~= "Parent" then
			(inst :: any)[k] = v
		end
	end
	if parent then
		inst.Parent = parent
	end
	return inst
end

local function corner(inst: Instance, radius: UDim)
	new("UICorner", { CornerRadius = radius, Parent = inst })
end

-- (a group draws nothing past its edges: a little room all round what is in it)
local EDGE = 2

-- The group a piece is drawn in: as wide and tall as what is in it, its bottom middle on `at`
-- pixels over the stack's point.
local function group(parent: Instance?, at: number): CanvasGroup
	local g = new("CanvasGroup", {
		Name = "Fade",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.fromOffset(0, 0),
		AutomaticSize = Enum.AutomaticSize.XY,
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 0.5, -at),
		Parent = parent,
	})
	new("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 0),
		Parent = g,
	})
	new("UIPadding", {
		PaddingLeft = UDim.new(0, EDGE),
		PaddingRight = UDim.new(0, EDGE),
		PaddingTop = UDim.new(0, EDGE),
		Parent = g,
	})
	return g
end

-- A turned square of `side`, its middle at `x`, `y` in `parent`.
local function diamond(parent: Instance, name: string, side: number, x: number, y: number, color: Color3, z: number)
	return new("Frame", {
		Name = name,
		BackgroundColor3 = color,
		BorderSizePixel = 0,
		Size = UDim2.fromOffset(side, side),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(x, y),
		Rotation = 45,
		ZIndex = z,
		Parent = parent,
	})
end

-- A little point under a straight edged card, toward the head: a turned square of the glass in a
-- row of its own under the card, its top half over the card's foot. The two are the same solid
-- glass, so they read as one shape with no line where they meet.
local POINT = 10 -- the turned square's side
local function tail(g: Instance, order: number)
	local reach = POINT * 0.7072 -- from its middle to its tip
	local wide = math.ceil(reach * 2) + 2
	local row = new("Frame", {
		Name = "Tail",
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(wide, math.ceil(reach) + 1),
		LayoutOrder = order,
		ZIndex = 2,
		Parent = g,
	})
	diamond(row, "Point", POINT, wide / 2, 0, GLASS, 2)
end

-- The dark card things sit on: glass and round corners, nothing round its edge (the user: "for
-- bubbles and text in rounded rectangles everywhere, remove the borders"; before that, "for text
-- and icon bubbles, remove the two squarish corners inside the bubbles").
function Bubble.card(parent: Instance, props: { [string]: any }?): Frame
	local p = props or {}
	local card = new("Frame", {
		Name = p.Name or "Card",
		BackgroundColor3 = GLASS,
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
		Size = p.Size or UDim2.fromOffset(0, 0),
		AutomaticSize = p.AutomaticSize or Enum.AutomaticSize.None,
		LayoutOrder = 1,
		ZIndex = 1,
		Parent = parent,
	})
	corner(card, UDim.new(0, p.Radius or 12))
	return card
end

-- A speech card's words: their size and face, and the most they take up before they wrap.
Bubble.TextSize = 17
Bubble.Font = Enum.Font.FredokaOne
Bubble.SpeechTall = 240

-- A speech card in `parent` (a billboard): the words in white on the glass, flush at its left (no
-- bar in front of them any more: the user, "remove the bar"), and a point under it. Returns the
-- group and the words' label (named Text).
function Bubble.speech(parent: Instance?, text: string?): (CanvasGroup, TextLabel)
	local g = group(parent, Bubble.Base)
	local card = Bubble.card(g, { AutomaticSize = Enum.AutomaticSize.XY })
	new("UIPadding", {
		PaddingLeft = UDim.new(0, 15),
		PaddingRight = UDim.new(0, 15),
		PaddingTop = UDim.new(0, 7),
		PaddingBottom = UDim.new(0, 11),
		Parent = card,
	})
	local label = new("TextLabel", {
		Name = "Text",
		Text = text or "",
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.XY,
		Size = UDim2.fromOffset(0, 0),
		Font = Bubble.Font,
		TextSize = Bubble.TextSize,
		TextWrapped = true,
		TextColor3 = INK,
		ZIndex = 2,
		Parent = card,
	})
	new("UISizeConstraint", { MaxSize = Vector2.new(Bubble.SpeechWidth, Bubble.SpeechTall), Parent = label })
	tail(g, 2)
	return g, label
end

-- A mood badge in `parent`: a round glass badge with the symbol in its colour and a point under it
-- toward the head. Drawn in one holder: the point, the badge over it, the symbol.
local DISC = 38
function Bubble.mood(parent: Instance?, kind: string): CanvasGroup
	local g = group(parent, Bubble.Base)
	local look = Bubble.Moods[kind]
	local color = if look then look[2] else INK
	local below = DISC - 4 -- the point's middle, a little over the badge's foot
	local reach = POINT * 1.2 * 0.7072
	local holder = new("Frame", {
		Name = "Badge",
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(DISC, math.ceil(below + reach) + 1),
		LayoutOrder = 1,
		Parent = g,
	})
	diamond(holder, "Point", POINT * 1.2, DISC / 2, below, GLASS, 1)
	local disc = new("Frame", {
		Name = "Disc",
		BackgroundColor3 = GLASS,
		BorderSizePixel = 0,
		Size = UDim2.fromOffset(DISC, DISC),
		ZIndex = 2,
		Parent = holder,
	})
	corner(disc, UDim.new(0.5, 0))
	new("TextLabel", {
		Name = "Symbol",
		Text = if look then look[1] else kind,
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(DISC, DISC),
		Font = Enum.Font.FredokaOne,
		-- (a symbol of one letter big, a few small: counted in letters, not bytes, since a heart
		-- is three bytes on its own)
		TextSize = if look and (utf8.len(look[1]) or #look[1]) > 1 then 17 else 27,
		TextColor3 = color,
		ZIndex = 4,
		Parent = holder,
	})
	return g
end

-- A square card for a picture (the wish bubble): `px` across, with a point under it. Returns the
-- group and the card (put the picture in the card).
function Bubble.square(parent: Instance?, px: number): (CanvasGroup, Frame)
	local g = group(parent, Bubble.Base)
	local card = Bubble.card(g, { Size = UDim2.fromOffset(px, px), Radius = 14 })
	tail(g, 2)
	return g, card
end

-- How big a piece is at its full size, worked out from what is in it. World/Bubbles stacks the
-- pieces by these sizes rather than by what the screen last drew: a piece that has only just come
-- (or whose words have just changed) hasn't been laid out yet, and one popping in is drawn smaller
-- than it will be, so its size on the screen would put what is over it too low, into its words
-- (the user: "it seems like bubbles like heart bubbles overlap with text sometimes when they appear
-- at the same time"). `measure(text, size, font, width)` is how big words come out wrapped at
-- `width` (TextService's GetTextSize on a player's screen). Nil when it can't tell.
export type Measure = (text: string, size: number, font: Enum.Font, width: number) -> Vector2
function Bubble.size(fade: Instance, measure: Measure?): Vector2?
	local w, h = 0, 0
	local any = false
	for _, c in fade:GetChildren() do
		if not c:IsA("GuiObject") or not c.Visible then
			continue
		end
		local cw, ch = c.Size.X.Offset, c.Size.Y.Offset
		if c.AutomaticSize ~= Enum.AutomaticSize.None then
			-- a card that sizes itself to its words
			local label = c:FindFirstChild("Text")
			if not (label and label:IsA("TextLabel") and measure) then
				return nil
			end
			local words = measure(label.Text, label.TextSize, label.Font, Bubble.SpeechWidth)
			local pad = c:FindFirstChildOfClass("UIPadding")
			local across = if pad then pad.PaddingLeft.Offset + pad.PaddingRight.Offset else 0
			local down = if pad then pad.PaddingTop.Offset + pad.PaddingBottom.Offset else 0
			cw = math.max(cw, math.min(math.ceil(words.X), Bubble.SpeechWidth) + across)
			ch = math.max(ch, math.min(math.ceil(words.Y), Bubble.SpeechTall) + down)
		end
		any = true
		w = math.max(w, cw)
		h += ch
	end
	if not any then
		return nil
	end
	local pad = fade:FindFirstChildOfClass("UIPadding")
	if pad then
		w += pad.PaddingLeft.Offset + pad.PaddingRight.Offset
		h += pad.PaddingTop.Offset + pad.PaddingBottom.Offset
	end
	return Vector2.new(w, h)
end

-- A rough measure of words for where there are no fonts to ask (the specs, the previews): a letter
-- a little under half the text size across, wrapped by whole words, a line the text size tall.
function Bubble.roughMeasure(text: string, size: number, _font: Enum.Font, width: number): Vector2
	local letter = size * 0.47
	local lines, line, widest = 1, 0, 0
	for word in text:gmatch("%S+") do
		local n = (utf8.len(word) or #word) * letter
		local wanted = if line > 0 then line + letter + n else n
		if line > 0 and wanted > width then
			lines += 1
			widest = math.max(widest, line)
			line = n
		else
			line = wanted
		end
	end
	widest = math.max(widest, line)
	return Vector2.new(math.min(widest, width), lines * math.ceil(size))
end

-- A head billboard to hang pieces in: tall, with the stack's point in its middle. It is drawn on
-- top (AlwaysOnTop: a head or a hat never cuts into it, and it shows over walls); `wide` is how
-- wide its widest piece may get.
function Bubble.billboard(name: string, adornee: BasePart, wide: number, far: number): BillboardGui
	return new("BillboardGui", {
		Name = name,
		Adornee = adornee,
		Size = UDim2.fromOffset(wide, Bubble.Tall),
		StudsOffset = Bubble.Anchor,
		MaxDistance = far,
		AlwaysOnTop = true,
		ResetOnSpawn = false,
		LightInfluence = 0,
	})
end

return Bubble
