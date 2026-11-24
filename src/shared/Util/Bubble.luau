-- What floats over a villager's head, drawn the same way by the server and the client: a speech
-- card (what they say out loud in the town, Npc.say), a mood badge (Npc.icon) and the frame of a
-- wish bubble (World/Wishes). The user: "improve villager bubbles above their head, and make it
-- such that you cant see the bubbles through walls. also, they sometimes intersect villager speech
-- bubbles". So they wear the interface's look (the dark glass over the 3D view, a thin pale rim,
-- small corner brackets, a short stroke of colour, a little tail pointing down at the head), and
-- they all hang from one point over the head, one above the other: World/Bubbles stacks them, keeps
-- two villagers' stacks apart and hides what a wall is in front of.
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

-- the glass over the 3D view (UI/Kit's Glass), the same in both looks
local GLASS = Color3.fromRGB(12, 12, 15)
local WHITE = Color3.fromRGB(255, 255, 255)
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
	return g
end

-- Two small brackets, on the top left and the bottom right corners of `card`, just inside it.
local function brackets(card: Instance, color: Color3, alpha: number)
	for _, c in { "tl", "br" } do
		local right, bottom = c == "br", c == "br"
		local anchor = Vector2.new(if right then 1 else 0, if bottom then 1 else 0)
		local holder = new("Frame", {
			Name = "Bracket",
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(7, 7),
			AnchorPoint = anchor,
			Position = UDim2.new(anchor.X, if right then -5 else 5, anchor.Y, if bottom then -5 else 5),
			ZIndex = 3,
			Parent = card,
		})
		for _, across in { true, false } do
			local leg = new("Frame", {
				BackgroundColor3 = color,
				BackgroundTransparency = alpha,
				BorderSizePixel = 0,
				Size = if across then UDim2.fromOffset(7, 2) else UDim2.fromOffset(2, 7),
				AnchorPoint = anchor,
				Position = UDim2.fromScale(anchor.X, anchor.Y),
				ZIndex = 3,
				Parent = holder,
			})
			corner(leg, UDim.new(0.5, 0))
		end
	end
end

-- A little point under a card, toward the head: a turned square half cut off by its row.
local function tail(g: Instance, color: Color3, alpha: number, order: number)
	local row = new("Frame", {
		Name = "Tail",
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(16, 7),
		ClipsDescendants = true,
		LayoutOrder = order,
		Parent = g,
	})
	new("Frame", {
		BackgroundColor3 = color,
		BackgroundTransparency = alpha,
		BorderSizePixel = 0,
		Size = UDim2.fromOffset(10, 10),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0, 0),
		Rotation = 45,
		Parent = row,
	})
end

-- The dark card things sit on: glass, round corners, a thin pale rim and the brackets.
function Bubble.card(parent: Instance, props: { [string]: any }?): Frame
	local p = props or {}
	local card = new("Frame", {
		Name = p.Name or "Card",
		BackgroundColor3 = GLASS,
		BackgroundTransparency = 0.08,
		BorderSizePixel = 0,
		Size = p.Size or UDim2.fromOffset(0, 0),
		AutomaticSize = p.AutomaticSize or Enum.AutomaticSize.None,
		LayoutOrder = 1,
		Parent = parent,
	})
	corner(card, UDim.new(0, p.Radius or 12))
	new("UIStroke", {
		Name = "Rim",
		Color = p.Rim or WHITE,
		Transparency = p.RimAlpha or 0.72,
		Thickness = p.RimThickness or 1.5,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = card,
	})
	brackets(card, WHITE, 0.45)
	return card
end

-- A speech card in `parent` (a billboard): the words in white on the glass, a short yellow stroke
-- at its left, and a tail under it. Returns the group and the words' label (named Text).
function Bubble.speech(parent: Instance?, text: string?): (CanvasGroup, TextLabel)
	local g = group(parent, Bubble.Base)
	local card = Bubble.card(g, { AutomaticSize = Enum.AutomaticSize.XY })
	new("UIPadding", {
		PaddingLeft = UDim.new(0, 16),
		PaddingRight = UDim.new(0, 12),
		PaddingTop = UDim.new(0, 7),
		PaddingBottom = UDim.new(0, 8),
		Parent = card,
	})
	local stroke = new("Frame", {
		Name = "Mark",
		BackgroundColor3 = Bubble.Yellow,
		BorderSizePixel = 0,
		Size = UDim2.new(0, 3, 1, -10),
		Position = UDim2.new(0, -9, 0, 5),
		ZIndex = 2,
		Parent = card,
	})
	corner(stroke, UDim.new(0.5, 0))
	local label = new("TextLabel", {
		Name = "Text",
		Text = text or "",
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.XY,
		Size = UDim2.fromOffset(0, 0),
		Font = Enum.Font.FredokaOne,
		TextSize = 17,
		TextWrapped = true,
		TextColor3 = INK,
		ZIndex = 2,
		Parent = card,
	})
	new("UISizeConstraint", { MaxSize = Vector2.new(220, 200), Parent = label })
	tail(g, GLASS, 0.08, 2)
	return g, label
end

-- A mood badge in `parent`: a round glass badge with the symbol in its colour and a ring of it.
function Bubble.mood(parent: Instance?, kind: string): CanvasGroup
	local g = group(parent, Bubble.Base)
	local look = Bubble.Moods[kind]
	local color = if look then look[2] else INK
	local disc = new("Frame", {
		Name = "Badge",
		BackgroundColor3 = GLASS,
		BackgroundTransparency = 0.08,
		BorderSizePixel = 0,
		Size = UDim2.fromOffset(36, 36),
		LayoutOrder = 1,
		Parent = g,
	})
	corner(disc, UDim.new(0.5, 0))
	new("UIStroke", { Color = color, Thickness = 2, Transparency = 0.1, Parent = disc })
	new("TextLabel", {
		Name = "Symbol",
		Text = if look then look[1] else kind,
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Font = Enum.Font.FredokaOne,
		TextSize = if look and #look[1] > 2 then 14 else 20,
		TextColor3 = color,
		Parent = disc,
	})
	tail(g, GLASS, 0.08, 2)
	return g
end

-- A head billboard to hang pieces in: tall, with the stack's point in its middle. It is drawn on
-- top (World/Bubbles hides it when something solid is between it and the camera); `wide` is how
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
