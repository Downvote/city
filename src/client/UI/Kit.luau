-- The UI toolkit: one theme and the pieces every screen is built from, in a bright, cozy look of
-- our own: white rounded cards with soft shadows, titles on bright pill banners, translucent navy
-- pills over the 3D view, rounded buttons that lift off a soft shadow and press down into it,
-- round icon buttons with a white rim and a little caption pill, and drawn icons (UI/Icons).

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

local Icons = require(script.Parent.Icons)

local Kit = {}

Kit.Theme = {
	Paper = Color3.fromRGB(255, 255, 255), -- cards and buttons
	Cream = Color3.fromRGB(255, 250, 240), -- panels
	PaperDark = Color3.fromRGB(239, 243, 247), -- wells, tracks, unpicked tabs
	Ink = Color3.fromRGB(58, 64, 86), -- text and the few outlines: a soft navy
	InkSoft = Color3.fromRGB(122, 130, 150),
	Line = Color3.fromRGB(218, 224, 232),
	Green = Color3.fromRGB(86, 198, 74),
	GreenDark = Color3.fromRGB(56, 156, 52),
	Coral = Color3.fromRGB(255, 108, 98),
	CoralDark = Color3.fromRGB(214, 70, 66),
	Blue = Color3.fromRGB(58, 166, 242),
	BlueDark = Color3.fromRGB(34, 124, 206),
	Yellow = Color3.fromRGB(255, 202, 58),
	YellowDark = Color3.fromRGB(236, 156, 28),
	Purple = Color3.fromRGB(168, 118, 232),
	Orange = Color3.fromRGB(255, 150, 58),
	Pink = Color3.fromRGB(255, 126, 178),
	Teal = Color3.fromRGB(36, 196, 188),
	White = Color3.fromRGB(255, 255, 255),
	Shadow = Color3.fromRGB(30, 40, 80), -- soft shadows, see through
	Glass = Color3.fromRGB(24, 34, 62), -- the dark see-through pills over the 3D view
	GlassAlpha = 0.38,
	Wood = Color3.fromRGB(28, 38, 70),
	WoodLight = Color3.fromRGB(40, 52, 90),
}

local T = Kit.Theme

Kit.Fonts = {
	Title = Enum.Font.FredokaOne,
	Body = Enum.Font.BuilderSansBold,
	Bold = Enum.Font.FredokaOne,
}

local player = Players.LocalPlayer
local root: ScreenGui

function Kit.root(): ScreenGui
	if root then
		return root
	end
	local gui = Instance.new("ScreenGui")
	gui.Name = "Maplewick"
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.IgnoreGuiInset = false
	gui.Parent = player:WaitForChild("PlayerGui")
	local scale = Instance.new("UIScale")
	scale.Name = "Scale"
	scale.Parent = gui
	local function fit()
		local cam = workspace.CurrentCamera
		local size = if cam then cam.ViewportSize else Vector2.new(1280, 720)
		scale.Scale = math.clamp(math.min(size.X / 1280, size.Y / 760), 0.55, 1.25)
	end
	fit()
	if workspace.CurrentCamera then
		workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit)
	end
	root = gui
	return gui
end

-- Generic constructor: Kit.new("Frame", { Size = ... }, { children })
function Kit.new(class: string, props: { [string]: any }?, children: { Instance }?): any
	local inst = Instance.new(class)
	local parent = nil
	local given: { [string]: any } = props or {}
	for k, v in given do
		if k == "Parent" then
			parent = v
		elseif type(k) == "string" then
			(inst :: any)[k] = v
		end
	end
	local kids: { Instance } = children or {}
	for _, c in kids do
		c.Parent = inst
	end
	if parent then
		inst.Parent = parent
	end
	return inst
end

-- Corners are square in this look. Only `"circle"` rounds anything: a square frame becomes a
-- circle. Any other radius is ignored, so old calls simply give square corners.
-- Rounded corners: a radius in pixels, or "circle" / "pill" for fully round ends.
function Kit.corner(inst: Instance, radius: any): UICorner
	local r = if radius == "circle" or radius == "pill" then UDim.new(0.5, 0) else UDim.new(0, radius or 12)
	return Kit.new("UICorner", { CornerRadius = r, Parent = inst })
end

-- An outline. The user asked for no outlines on rounded rectangles, so these are switched off:
-- the stroke is still made (callers keep and tween it) but never shows. Doodles and icons make
-- their own strokes.
function Kit.stroke(inst: Instance, color: Color3?, thickness: number?): UIStroke
	local ink = color == T.Ink
	return Kit.new("UIStroke", {
		Enabled = false,
		Color = color or T.Line,
		Thickness = if ink then math.min(thickness or 1.5, 2) else thickness or 1.5,
		Transparency = if ink then 0.72 else 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		LineJoinMode = Enum.LineJoinMode.Round,
		Parent = inst,
	})
end

-- A dark outline round the letters of a text object.
function Kit.outlineText(label: Instance, color: Color3?, thickness: number?): UIStroke
	local s = label:FindFirstChild("TextOutline") :: UIStroke?
	if not s then
		s = Kit.new(
			"UIStroke",
			{ Name = "TextOutline", ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual, Parent = label }
		)
	end
	local st = s :: UIStroke
	st.Color = color or T.Ink
	st.Thickness = thickness or 2
	st.LineJoinMode = Enum.LineJoinMode.Round
	return st
end

-- A top-to-bottom shading on a frame or button (lighter at the top).
function Kit.gradient(inst: Instance, strength: number?): UIGradient
	-- everything is flat colour now: the gradient is kept (callers hold on to it) but switched off
	local k = 1 - (strength or 0.14)
	return Kit.new("UIGradient", {
		Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.new(k, k, k)),
		Rotation = 90,
		Enabled = false,
		Parent = inst,
	})
end

local function darker(c: Color3, k: number?): Color3
	local m = k or 0.78
	return Color3.new(c.R * m, c.G * m, c.B * m)
end
Kit.darker = darker

local LIP = 4

-- Padding. On a Kit button the face, lip and label stretch back over it, so a padded button
-- still fills edge to edge (the padding only makes an auto-sized button wider).
function Kit.pad(inst: Instance, px: number, py: number?): UIPadding
	local y = py or px
	local pad = Kit.new("UIPadding", {
		PaddingLeft = UDim.new(0, px),
		PaddingRight = UDim.new(0, px),
		PaddingTop = UDim.new(0, y),
		PaddingBottom = UDim.new(0, y),
		Parent = inst,
	})
	if inst:GetAttribute("KitButton") then
		local lip = inst:GetAttribute("Lip") or LIP
		for _, name in { "Face", "Content" } do
			local f = inst:FindFirstChild(name)
			if f and f:IsA("GuiObject") then
				f.Position = UDim2.fromOffset(-px, -y)
				f.Size = UDim2.new(1, px * 2, 1, y * 2 - lip)
			end
		end
	end
	return pad
end

function Kit.list(inst: Instance, gap: number?, horizontal: boolean?, align: Enum.HorizontalAlignment?): UIListLayout
	return Kit.new("UIListLayout", {
		Padding = UDim.new(0, gap or 6),
		FillDirection = if horizontal then Enum.FillDirection.Horizontal else Enum.FillDirection.Vertical,
		SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = align or Enum.HorizontalAlignment.Left,
		VerticalAlignment = if horizontal then Enum.VerticalAlignment.Center else Enum.VerticalAlignment.Top,
		Parent = inst,
	})
end

function Kit.grid(inst: Instance, cell: UDim2, gap: number?): UIGridLayout
	return Kit.new("UIGridLayout", {
		CellSize = cell,
		CellPadding = UDim2.fromOffset(gap or 8, gap or 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = inst,
	})
end

function Kit.frame(props: { [string]: any }?): Frame
	local p = props or {}
	local f = Kit.new("Frame", {
		BackgroundColor3 = p.Color or T.Paper,
		BackgroundTransparency = p.Transparency or 0,
		BorderSizePixel = 0,
		Size = p.Size or UDim2.fromScale(1, 1),
		Position = p.Position or UDim2.new(),
		AnchorPoint = p.AnchorPoint or Vector2.zero,
		Name = p.Name or "Frame",
		LayoutOrder = p.LayoutOrder or 0,
		Visible = if p.Visible == nil then true else p.Visible,
		ZIndex = p.ZIndex or 1,
		AutomaticSize = p.AutomaticSize or Enum.AutomaticSize.None,
		ClipsDescendants = p.Clips or false,
		Parent = p.Parent,
	})
	if p.Radius ~= false then
		Kit.corner(f, p.Radius or 14)
	end
	if p.Stroke then
		-- outlines are light in this look: a thin line, softer than the text
		local color = if typeof(p.Stroke) == "Color3" then p.Stroke else T.Line
		local s = Kit.stroke(f, color, math.min(p.StrokeThickness or 2, 2.5))
		s.Transparency = if color == T.Ink then 0.55 else 0
	end
	return f
end

-- A blank, transparent container.
function Kit.box(props: { [string]: any }?): Frame
	local p = table.clone(props or {})
	p.Transparency = 1
	p.Radius = false
	return Kit.frame(p)
end

-- A card the HUD floats over the 3D view: a cream wobbly bubble with navy words on it. If a list
-- or grid layout is put inside, the bubble's pieces would be lined up too, so it becomes a plain
-- rounded cream back instead.
function Kit.glass(props: { [string]: any }?): Frame
	local p = table.clone(props or {})
	local f = Kit.frame({
		Name = p.Name or "Glass",
		Size = p.Size,
		Position = p.Position,
		AnchorPoint = p.AnchorPoint,
		Parent = p.Parent,
		LayoutOrder = p.LayoutOrder,
		Visible = p.Visible,
		ZIndex = p.ZIndex,
		AutomaticSize = p.AutomaticSize,
		Color = p.Color or T.Paper,
		Transparency = 1,
		Radius = false,
	})
	local info = Kit.blobInto(f, {
		Color = p.Color or T.Paper,
		Radius = p.Radius or 20,
		Base = false,
		ZIndex = f.ZIndex,
	})
	f.ChildAdded:Connect(function(c)
		if (c:IsA("UIListLayout") or c:IsA("UIGridLayout")) and not info.dead then
			info.dead = true
			for _, name in { "Shape", "Base" } do
				local layer = f:FindFirstChild(name)
				if layer then
					layer:Destroy()
				end
			end
			f.BackgroundTransparency = 0
			Kit.corner(f, p.Radius or 20)
			local st = Kit.stroke(f, T.Line, 2)
			st.Transparency = 0.2
		end
	end)
	return f
end

function Kit.text(text: string, props: { [string]: any }?): TextLabel
	local p = props or {}
	local label = Kit.new("TextLabel", {
		Text = text,
		BackgroundTransparency = 1,
		Font = p.Font or Kit.Fonts.Body,
		TextSize = p.TextSize or 18,
		TextColor3 = p.Color or T.Ink,
		TextWrapped = if p.Wrap == nil then true else p.Wrap,
		TextXAlignment = p.AlignX or Enum.TextXAlignment.Left,
		TextYAlignment = p.AlignY or Enum.TextYAlignment.Center,
		Size = p.Size or UDim2.new(1, 0, 0, (p.TextSize or 18) + 6),
		Position = p.Position or UDim2.new(),
		AnchorPoint = p.AnchorPoint or Vector2.zero,
		AutomaticSize = p.AutomaticSize or Enum.AutomaticSize.None,
		RichText = p.Rich or false,
		Name = p.Name or "Text",
		LayoutOrder = p.LayoutOrder or 0,
		ZIndex = p.ZIndex or 1,
		TextScaled = p.Scaled or false,
		Parent = p.Parent,
	})
	if p.Outline then
		Kit.outlineText(label, if typeof(p.Outline) == "Color3" then p.Outline else T.Ink, p.OutlineThickness)
	end
	return label
end

-- A heading in the game's rounded display font. White titles get a dark outline.
function Kit.title(text: string, props: { [string]: any }?): TextLabel
	local p = table.clone(props or {})
	p.Font = Kit.Fonts.Title
	p.TextSize = p.TextSize or 26
	if p.Outline == nil and p.Color == T.White then
		p.Outline = T.Ink
	end
	return Kit.text(text, p)
end

-- Is this object on screen: it and every parent visible, under a ScreenGui that's enabled?
local function onScreen(o: Instance): boolean
	local cur: Instance? = o
	while cur do
		if cur:IsA("GuiObject") and not cur.Visible then
			return false
		end
		if cur:IsA("ScreenGui") then
			return cur.Enabled
		end
		cur = cur.Parent
	end
	return false
end
Kit.onScreen = onScreen

-- The glossy sheen that sweeps across buttons now and then. One loop for the whole interface
-- picks a button on screen every so often and runs the sweep across it.
local sheens: { [any]: number } = setmetatable({}, { __mode = "k" }) :: any
local sheenLoop = false
local function startSheens()
	if sheenLoop then
		return
	end
	sheenLoop = true
	task.spawn(function()
		while true do
			task.wait(0.7)
			local ready = {}
			local now = os.clock()
			for grad, last in sheens do
				local holder = grad.Parent
				if holder and holder.Parent and now - last > 5 and onScreen(holder) then
					table.insert(ready, grad)
				end
			end
			if #ready > 0 then
				local g = ready[math.random(1, #ready)] :: any
				sheens[g] = now
				g.Offset = Vector2.new(-1.3, 0)
				TweenService:Create(g, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					Offset = Vector2.new(1.3, 0),
				}):Play()
			end
		end
	end)
end

local function addSheen(face: GuiObject, radius: any)
	if true then
		return -- flat colours: no sheen sweeping across
	end
	local sheen = Kit.new("Frame", {
		Name = "Sheen",
		BackgroundColor3 = T.White,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		ZIndex = face.ZIndex,
		Parent = face,
	})
	Kit.corner(sheen, radius)
	local g = Kit.new("UIGradient", {
		Rotation = 20,
		Offset = Vector2.new(-1.3, 0),
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.4, 1),
			NumberSequenceKeypoint.new(0.5, 0.45),
			NumberSequenceKeypoint.new(0.6, 1),
			NumberSequenceKeypoint.new(1, 1),
		}),
		Parent = sheen,
	})
	sheens[g] = os.clock() - math.random() * 4
	startSheens()
end

-- What a Kit button does under the pointer: grows when hovered (its icon hops), sinks onto its
-- lip when pressed, and springs back with a little bounce when let go.
-- Wobble: some things sway gently on their own, and every button wiggles when the pointer comes
-- over it. One loop moves them all. Roblox ignores clipping under a turned frame, and some icons
-- are cut out with clipping, so anything holding one breathes (its face grows and shrinks a
-- little) instead of turning.
type Wob = { amount: number, phase: number, kick: number, canTurn: boolean, face: GuiObject?, faceScale: UIScale? }
local wobbles: { [GuiObject]: Wob } = {}
local wobbleLoop = false
local wobbleClock = 0

local function canTurn(g: GuiObject): boolean
	for _, d in g:GetDescendants() do
		if d:IsA("GuiObject") and d.ClipsDescendants then
			return false
		end
	end
	return true
end

local function startWobble()
	if wobbleLoop then
		return
	end
	wobbleLoop = true
	RunService.Heartbeat:Connect(function(dt)
		wobbleClock += dt
		local t = wobbleClock
		for g, w in wobbles do
			if not g.Parent then
				wobbles[g] = nil
				continue
			end
			if not g.Visible then
				continue
			end
			local since = t - w.kick
			local kick = if since < 0.6 then math.sin(since * 28) * (1 - since / 0.6) else 0
			local sway = math.sin(t * 2.1 + w.phase)
			if w.canTurn then
				g.Rotation = math.floor((sway * w.amount + kick * 5) * 10 + 0.5) / 10
			elseif w.face then
				if not w.faceScale then
					w.faceScale = Kit.new("UIScale", { Name = "Wobble", Parent = w.face })
				end
				local fs = w.faceScale :: UIScale
				fs.Scale = 1 + sway * w.amount * 0.018 + kick * 0.06
			end
		end
	end)
end

-- Makes `g` sway on its own by about `amount` degrees (1.6 if not given; 0 only wiggles on hover).
function Kit.wobbly(g: GuiObject, amount: number?)
	local w = wobbles[g]
	if not w then
		local face = g:FindFirstChild("Face")
		w = {
			amount = 0,
			phase = math.random() * math.pi * 2,
			kick = -10,
			canTurn = canTurn(g),
			face = if face and face:IsA("GuiObject") then face else nil,
		}
		wobbles[g] = w
		startWobble()
		-- icons and labels are often added just after the button is made: look again shortly
		task.defer(function()
			local ww = wobbles[g]
			if ww then
				ww.canTurn = canTurn(g)
			end
		end)
	end
	local ww = w :: Wob
	ww.amount = amount or 1.6
end

-- A quick wiggle, as when the pointer comes over a button.
function Kit.wiggle(g: GuiObject)
	if not wobbles[g] then
		Kit.wobbly(g, 0)
	end
	local w = wobbles[g]
	if w then
		w.kick = wobbleClock
	end
end

local function pressable(b: GuiButton)
	local scale = Kit.new("UIScale", { Name = "Press", Parent = b })
	local hovering, pressed = false, false
	local function sink(down: boolean)
		local lip = b:GetAttribute("Lip")
		if type(lip) ~= "number" or lip <= 0 then
			return
		end
		for _, name in { "Face", "Content" } do
			local f = b:FindFirstChild(name)
			if f and f:IsA("GuiObject") then
				local baseY = f:GetAttribute("BaseY")
				if type(baseY) ~= "number" then
					baseY = f.Position.Y.Offset
					f:SetAttribute("BaseY", baseY)
				end
				local p = f.Position
				f.Position =
					UDim2.new(p.X.Scale, p.X.Offset, p.Y.Scale, (baseY :: number) + (if down then lip - 1 else 0))
			end
		end
	end
	local function hop()
		local art = b:FindFirstChild("IconArt", true)
		if art and art:IsA("GuiObject") then
			local baseY = art:GetAttribute("BaseY")
			if type(baseY) ~= "number" then
				baseY = art.Position.Y.Offset
				art:SetAttribute("BaseY", baseY)
			end
			local p = art.Position
			art.Position = UDim2.new(p.X.Scale, p.X.Offset, p.Y.Scale, (baseY :: number) - 4)
			TweenService:Create(art, TweenInfo.new(0.35, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out), {
				Position = UDim2.new(p.X.Scale, p.X.Offset, p.Y.Scale, baseY :: number),
			}):Play()
		end
	end
	b.MouseEnter:Connect(function()
		hovering = true
		TweenService:Create(scale, TweenInfo.new(0.15, Enum.EasingStyle.Back), { Scale = 1.06 }):Play()
		hop()
		Kit.wiggle(b)
	end)
	b.MouseLeave:Connect(function()
		hovering = false
		if pressed then
			pressed = false
			sink(false)
		end
		TweenService:Create(scale, TweenInfo.new(0.15), { Scale = 1 }):Play()
	end)
	b.MouseButton1Down:Connect(function()
		pressed = true
		sink(true)
		TweenService:Create(scale, TweenInfo.new(0.06), { Scale = 0.96 }):Play()
	end)
	b.MouseButton1Up:Connect(function()
		if pressed then
			pressed = false
			sink(false)
		end
	end)
	b.Activated:Connect(function()
		-- a squash and a springy rebound
		scale.Scale = 0.9
		TweenService:Create(scale, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Scale = if hovering then 1.06 else 1,
		}):Play()
	end)
end

-- The chunky look shared by buttons and tiles: the button itself is the darker lip, a "Face"
-- child sits on it with a gradient, a glossy "Shine" and a sweeping "Sheen", and a thick dark
-- outline goes round.
local function chunky(b: GuiButton, color: Color3, radius: any, lip: number, _outline: number?)
	-- a flat face in one colour (the button's own background stays clear)
	b.BackgroundTransparency = 1
	b:SetAttribute("KitButton", true)
	b:SetAttribute("Lip", lip)
	local face = Kit.new("Frame", {
		Name = "Face",
		BackgroundColor3 = color,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 1, -lip),
		ZIndex = b.ZIndex,
		Parent = b,
	})
	Kit.corner(face, radius or 14)
	return face
end

-- A rounded button lifted off a darker base (the "lip"); it presses down into it. props: Size, Position, AnchorPoint, Color, TextColor, TextSize, Font,
-- Radius, LayoutOrder, Name, ZIndex, AutomaticSize, Icon (an icon name, drawn left of the text).
-- The returned TextButton's Text and TextColor3 can be set as usual; the label follows them.
function Kit.button(text: string, props: { [string]: any }?, onClick: (() -> ())?): TextButton
	local p = props or {}
	local color = p.Color or T.Green
	local size: UDim2 = p.Size or UDim2.fromOffset(140, 46)
	local textSize = p.TextSize or 20
	local lip = 0 -- flat: no darker base under the face
	local textColor: Color3 = p.TextColor or T.White
	local b = Kit.new("TextButton", {
		Text = text,
		TextTransparency = 1,
		AutoButtonColor = false,
		Font = p.Font or Kit.Fonts.Title,
		TextSize = textSize,
		TextColor3 = textColor,
		BorderSizePixel = 0,
		Size = size,
		Position = p.Position or UDim2.new(),
		AnchorPoint = p.AnchorPoint or Vector2.zero,
		LayoutOrder = p.LayoutOrder or 0,
		Name = p.Name or text,
		ZIndex = p.ZIndex or 1,
		AutomaticSize = p.AutomaticSize or Enum.AutomaticSize.None,
		Parent = p.Parent,
	})
	chunky(b, color, p.Radius or 12, lip)
	local content = Kit.new("Frame", {
		Name = "Content",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, -lip),
		ZIndex = b.ZIndex,
		Parent = b,
	})
	local layout = Kit.list(content, 6, true, Enum.HorizontalAlignment.Center)
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	local iconPx = math.floor(textSize * 1.3)
	if p.Icon then
		if Icons.has(p.Icon) then
			Icons.make(p.Icon, iconPx, { Parent = content, LayoutOrder = 1, ZIndex = b.ZIndex, Color = textColor })
		else
			Kit.new("TextLabel", {
				Name = "Emoji",
				Text = p.Icon,
				BackgroundTransparency = 1,
				TextScaled = true,
				Size = UDim2.fromOffset(iconPx, iconPx),
				LayoutOrder = 1,
				ZIndex = b.ZIndex,
				Parent = content,
			})
		end
	end
	local label = Kit.new("TextLabel", {
		Name = "Label",
		Text = text,
		BackgroundTransparency = 1,
		Font = p.Font or Kit.Fonts.Title,
		TextSize = textSize,
		TextColor3 = textColor,
		Size = UDim2.fromScale(0, 1),
		AutomaticSize = Enum.AutomaticSize.X,
		LayoutOrder = 2,
		ZIndex = b.ZIndex,
		Visible = text ~= "",
		Parent = content,
	})
	-- white words get a dark outline; dark words on a light face read fine as they are
	if textColor == T.White then
		Kit.outlineText(label, darker(color, 0.62), math.max(1, textSize / 13))
	end
	-- the button's own text is invisible and only sizes it; leave room for the icon in it
	local function spaced(s: string): string
		if p.Icon and s ~= "" then
			local spaces = math.ceil((iconPx + 6) / (textSize * 0.27))
			return string.rep(" ", spaces) .. s
		end
		return s
	end
	local syncing = false
	b.Text = spaced(text)
	b:GetPropertyChangedSignal("Text"):Connect(function()
		if syncing then
			return
		end
		syncing = true
		local raw = b.Text:gsub("^%s+", "")
		label.Text = raw
		label.Visible = raw ~= ""
		b.Text = spaced(raw)
		syncing = false
	end)
	b:GetPropertyChangedSignal("TextColor3"):Connect(function()
		label.TextColor3 = b.TextColor3
	end)
	pressable(b)
	if onClick then
		b.Activated:Connect(onClick)
	end
	return b
end

-- Recolours a Kit button or tile (for toggles and selected tabs).
function Kit.setButtonColor(b: GuiButton, color: Color3, textColor: Color3?)
	local face = b:FindFirstChild("Face")
	local lip = b:FindFirstChild("Lip")
	if face and face:GetAttribute("Blob") then
		Kit.setBlobColor(face, color)
		if lip then
			Kit.setBlobColor(lip, darker(color, 0.8))
		end
		local art = face:FindFirstChild("IconArt")
		if art then
			local light = color.R * 0.3 + color.G * 0.59 + color.B * 0.11 > 0.86
			Kit.recolorIcon(art, if light then T.Ink else T.White, color)
		end
	elseif face and face:IsA("Frame") then
		face.BackgroundColor3 = color
		if lip and lip:IsA("Frame") then
			lip.BackgroundColor3 = darker(color, 0.78)
		else
			b.BackgroundColor3 = darker(color, 0.8)
		end
	else
		b.BackgroundColor3 = color
	end
	local tc = textColor or T.White
	if b:IsA("TextButton") then
		b.TextColor3 = tc
	end
	local light = tc ~= T.White
	for _, name in { "Label", "Caption" } do
		local l = b:FindFirstChild(name, true)
		-- a round button's caption sits on its own paper tag and keeps its ink
		if l and l:IsA("TextLabel") and not (l.Parent and l.Parent.Name == "Tag") then
			l.TextColor3 = tc
			local o = l:FindFirstChild("TextOutline")
			if light then
				if o then
					o:Destroy()
				end
			else
				Kit.outlineText(l, darker(color, 0.62), math.max(1, l.TextSize / 13))
			end
		end
	end
end

-- A round button with a big icon, and its caption on a little paper tag under it (docks, tool
-- strips, categories). It fits in the Size it's given. `icon` is an icon name from UI/Icons (or
-- any text, drawn as is). props: Size, Color, TextSize, LayoutOrder, Position, AnchorPoint, Name,
-- ZIndex.
function Kit.iconButton(icon: string, caption: string?, props: { [string]: any }?, onClick: (() -> ())?): TextButton
	local p = props or {}
	local size: UDim2 = p.Size or UDim2.fromOffset(72, 72)
	local color = p.Color or T.Paper
	local hasCaption = caption ~= nil and caption ~= ""
	local textSize = p.TextSize or 14
	local tagH = if hasCaption then textSize + 8 else 0
	local w, h = size.X.Offset, size.Y.Offset
	local lip = 0
	local d = math.max(16, math.min(w, h - math.floor(tagH * 0.6)) - 4)
	local b = Kit.new("TextButton", {
		Text = "",
		AutoButtonColor = false,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = size,
		Position = p.Position or UDim2.new(),
		AnchorPoint = p.AnchorPoint or Vector2.zero,
		LayoutOrder = p.LayoutOrder or 0,
		Name = p.Name or caption or icon,
		ZIndex = p.ZIndex or 1,
		Parent = p.Parent,
	})
	b:SetAttribute("KitButton", true)
	b:SetAttribute("Lip", lip)
	b:SetAttribute("Round", true)
	local z = b.ZIndex
	-- a flat jelly round face
	local face, faceContent = Kit.blob({
		Name = "Face",
		Round = true,
		Color = color,
		Base = false,
		Size = UDim2.fromOffset(d, d),
		Position = UDim2.new(0.5, -d / 2, 0, 0),
		ZIndex = z,
		Parent = b,
	})
	local _2 = faceContent
	local iconPx = math.floor(d * 0.6)
	if Icons.has(icon) then
		-- one colour: white on a coloured button, navy on a white one, details cut out in the face's colour
		local light = color.R * 0.3 + color.G * 0.59 + color.B * 0.11 > 0.86
		Icons.make(icon, iconPx, {
			Name = "IconArt",
			Parent = face,
			Position = UDim2.new(0.5, -iconPx / 2, 0.5, -iconPx / 2),
			ZIndex = z + 1,
			Color = p.IconColor or (if light then T.Ink else T.White),
			Hole = color,
		})
	else
		Kit.new("TextLabel", {
			Name = "Icon",
			Text = icon,
			BackgroundTransparency = 1,
			Font = Enum.Font.BuilderSansBold,
			TextScaled = true,
			Size = UDim2.fromOffset(iconPx, iconPx),
			Position = UDim2.new(0.5, -iconPx / 2, 0.5, -iconPx / 2),
			TextColor3 = p.IconColor or T.Ink,
			ZIndex = z,
			Parent = face,
		})
	end
	if hasCaption then
		local tag = Kit.new("Frame", {
			Name = "Tag",
			BackgroundColor3 = T.Paper,
			BorderSizePixel = 0,
			Size = UDim2.fromOffset(0, tagH),
			AutomaticSize = Enum.AutomaticSize.X,
			Position = UDim2.new(0.5, 0, 0, d + lip - math.floor(tagH * 0.45)),
			AnchorPoint = Vector2.new(0.5, 0),
			ZIndex = z + 1,
			Parent = b,
		})
		Kit.corner(tag, "pill")
		Kit.stroke(tag, T.Line, 1.5)
		Kit.pad(tag, 8, 0)
		Kit.new("TextLabel", {
			Name = "Caption",
			Text = caption,
			BackgroundTransparency = 1,
			Font = Kit.Fonts.Title,
			TextSize = textSize,
			TextWrapped = false,
			Size = UDim2.fromOffset(0, tagH),
			AutomaticSize = Enum.AutomaticSize.X,
			TextColor3 = T.Ink,
			ZIndex = z + 1,
			Parent = tag,
		})
	end
	pressable(b)
	Kit.wobbly(b, if p.Wobble == nil then 2 else p.Wobble)
	if onClick then
		b.Activated:Connect(onClick)
	end
	return b
end

-- A chunky progress bar: a dark outlined track with a shaded fill. props: Parent, Size, Position,
-- LayoutOrder, Track (the empty part's colour). Returns the track and the fill.
function Kit.bar(props: { [string]: any }, ratio: number, color: Color3): (Frame, Frame)
	local size: UDim2 = props.Size or UDim2.new(1, 0, 0, 14)
	local h = math.max(6, size.Y.Offset)
	local track = Kit.frame({
		Name = "Bar",
		Parent = props.Parent,
		Size = size,
		Position = props.Position,
		AnchorPoint = props.AnchorPoint,
		LayoutOrder = props.LayoutOrder,
		Color = props.Track or T.PaperDark,
		Radius = "pill",
	})
	local _ = h
	local fill = Kit.frame({
		Name = "Fill",
		Parent = track,
		Size = UDim2.fromScale(math.clamp(ratio, 0, 1), 1),
		Color = color,
		Radius = "pill",
	})
	Kit.gradient(fill, 0.3)
	return track, fill
end

-- A small red bubble with a number or a "!" on a corner, for things waiting to be seen.
function Kit.badge(parent: GuiObject, text: string): Frame
	local f = Kit.frame({
		Name = "Badge",
		Parent = parent,
		Size = UDim2.fromOffset(24, 24),
		AutomaticSize = Enum.AutomaticSize.X,
		Position = UDim2.new(1, 4, 0, -6),
		AnchorPoint = Vector2.new(1, 0),
		Color = T.Coral,
		Radius = "circle",
		ZIndex = (parent.ZIndex or 1) + 5,
		Stroke = T.Ink,
		StrokeThickness = 2,
	})
	Kit.pad(f, 6, 0)
	Kit.title(text, {
		Parent = f,
		Size = UDim2.new(0, 0, 1, 0),
		AutomaticSize = Enum.AutomaticSize.X,
		TextSize = 15,
		Color = T.White,
		Wrap = false,
		ZIndex = f.ZIndex,
	})
	-- a gentle pulse so it gets noticed
	local pulse = Kit.new("UIScale", { Name = "Pulse", Parent = f })
	TweenService
		:Create(
			pulse,
			TweenInfo.new(0.55, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
			{ Scale = 1.18 }
		)
		:Play()
	return f
end

-- A dark see-through pill for the HUD over the 3D view (white words read on it). No outline.
function Kit.darkPill(props: { [string]: any }?): Frame
	local p = props or {}
	local f = Kit.frame({
		Name = p.Name or "DarkPill",
		Size = p.Size,
		Position = p.Position,
		AnchorPoint = p.AnchorPoint,
		Parent = p.Parent,
		LayoutOrder = p.LayoutOrder,
		ZIndex = p.ZIndex,
		Color = T.Glass,
		Transparency = T.GlassAlpha,
		Radius = p.Radius or "pill",
	})
	return f
end

-- A rounded stat pill: a dark glass bar with a big icon over its left end and the value in white.
-- props: Size, Position, AnchorPoint, LayoutOrder, Name, TextSize, Plus (a function: draws a
-- green + button on the right). Returns the frame and the value label.
function Kit.pill(icon: string, props: { [string]: any }?): (Frame, TextLabel)
	local p = props or {}
	local size: UDim2 = p.Size or UDim2.fromOffset(150, 40)
	local h = size.Y.Offset
	local f = Kit.darkPill({
		Name = p.Name or "Pill",
		Size = size,
		Position = p.Position,
		AnchorPoint = p.AnchorPoint,
		Parent = p.Parent,
		LayoutOrder = p.LayoutOrder,
	})
	local iconPx = math.floor(h * 0.86)
	if Icons.has(icon) then
		-- one colour, the stat's own
		local tints = { people = Color3.fromRGB(120, 196, 255), smile = T.Orange }
		Icons.make(icon, iconPx, {
			Name = "IconArt",
			Parent = f,
			Position = UDim2.new(0, math.floor(h * 0.12) + iconPx / 2, 0.5, 0),
			AnchorPoint = Vector2.new(0.5, 0.5),
			ZIndex = f.ZIndex + 1,
			Color = p.IconColor or tints[icon],
			Hole = T.Glass,
		})
	else
		Kit.new("TextLabel", {
			Name = "Icon",
			Text = icon,
			BackgroundTransparency = 1,
			TextScaled = true,
			Font = Enum.Font.BuilderSansBold,
			Size = UDim2.fromOffset(h - 8, h - 8),
			Position = UDim2.new(0, 6, 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5),
			Parent = f,
		})
	end
	local left = math.floor(h * 1.08)
	local right = if p.Plus then h + 4 else 12
	local value = Kit.new("TextLabel", {
		Name = "Value",
		Text = "",
		BackgroundTransparency = 1,
		Font = Kit.Fonts.Title,
		TextSize = p.TextSize or math.floor(h * 0.52),
		TextColor3 = p.TextColor or T.White,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, -left - right, 1, 0),
		Position = UDim2.fromOffset(left, 0),
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = f.ZIndex + 1,
		Parent = f,
	})
	if p.Plus then
		Kit.iconButton("plus", nil, {
			Name = "Plus",
			Parent = f,
			Size = UDim2.fromOffset(h - 4, h - 2),
			Position = UDim2.new(1, 2, 0.5, 0),
			AnchorPoint = Vector2.new(1, 0.5),
			Color = T.Green,
		}, p.Plus)
	end
	return f, value
end

-- A solid drop shadow behind a card, down and to the right: a sibling just under it (children
-- always draw above their parent).
function Kit.shadow(card: GuiObject, radius: any): Frame
	local s = Kit.frame({
		Name = card.Name .. "Shadow",
		Size = card.Size,
		Position = card.Position + UDim2.fromOffset(0, 6),
		AnchorPoint = card.AnchorPoint,
		Color = T.Shadow,
		Transparency = 0.82,
		Radius = radius or 14,
		ZIndex = math.max(0, card.ZIndex - 1),
		Parent = card.Parent,
	})
	card:GetPropertyChangedSignal("Visible"):Connect(function()
		s.Visible = card.Visible
	end)
	card:GetPropertyChangedSignal("Position"):Connect(function()
		s.Position = card.Position + UDim2.fromOffset(0, 6)
	end)
	card.Destroying:Connect(function()
		s:Destroy()
	end)
	return s
end

-- The round close button that sits on a panel's corner: white, with a soft navy cross.
function Kit.closeButton(props: { [string]: any }, onClick: (() -> ())?): TextButton
	local p = table.clone(props)
	p.Color = T.White
	p.TextSize = nil
	return Kit.iconButton("close", nil, p, onClick)
end

-- Draws flat pieces with one shared outline: every piece's dark copy (grown by the outline)
-- first, then every fill, so no outline crosses another piece. Pieces, in pixels:
--   { "rect", x, y, w, h, colour }    { "tri", x, y, base, dir, colour } (dir up/down/left/right;
--   its height is half the base)
local function pieces(parent: GuiObject, list: { any }, thick: number, z: number)
	local function draw(piece: any, ink: boolean)
		local color = if ink then T.Ink else piece[6]
		local g = if ink then thick else 0
		if piece[1] == "rect" then
			local f = Kit.new("Frame", {
				Name = if ink then "Ink" else "Fill",
				BackgroundColor3 = color,
				BorderSizePixel = 0,
				Position = UDim2.fromOffset(piece[2] - g, piece[3] - g),
				Size = UDim2.fromOffset(piece[4] + g * 2, piece[5] + g * 2),
				ZIndex = z,
				Parent = parent,
			})
			if not ink then
				Kit.gradient(f, 0.12)
			end
		else
			local x, y, base, dir = piece[2], piece[3], piece[4], piece[5]
			local horizontal = dir == "up" or dir == "down"
			local w = if horizontal then base else base / 2
			local h = if horizontal then base / 2 else base
			local cx, cy
			if dir == "up" then
				cx, cy = x + w / 2, y + h
			elseif dir == "down" then
				cx, cy = x + w / 2, y
			elseif dir == "left" then
				cx, cy = x + w, y + h / 2
			else
				cx, cy = x, y + h / 2
			end
			local bx, by, bw, bh = x - g, y - g, w + g * 2, h + g * 2
			local clip = Kit.new("Frame", {
				Name = if ink then "Ink" else "Fill",
				BackgroundTransparency = 1,
				ClipsDescendants = true,
				Position = UDim2.fromOffset(bx, by),
				Size = UDim2.fromOffset(bw, bh),
				ZIndex = z,
				Parent = parent,
			})
			local side = base / math.sqrt(2) + g * 2
			local sq = Kit.new("Frame", {
				BackgroundColor3 = color,
				BorderSizePixel = 0,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Rotation = 45,
				Size = UDim2.fromOffset(side, side),
				Position = UDim2.fromOffset(cx - bx, cy - by),
				ZIndex = z,
				Parent = clip,
			})
			local _ = sq
		end
	end
	for _, piece in list do
		draw(piece, true)
	end
	for _, piece in list do
		draw(piece, false)
	end
end
Kit.pieces = pieces

-- A title banner: a bright pill with the words on it in white and a soft shadow under it. (Named
-- ribbon from an earlier look; callers pass the same props.) props: Parent, Position, AnchorPoint,
-- Color, TextSize, LayoutOrder, ZIndex, Name. It sizes itself to the text. Returns the frame and
-- the text label.
function Kit.ribbon(text: string, props: { [string]: any }?): (Frame, TextLabel)
	local p = props or {}
	local color: Color3 = p.Color or T.Green
	local textSize = p.TextSize or 26
	local h = math.floor(textSize * 1.7)
	local W = math.floor((utf8.len(text) or #text) * textSize * 0.56 + textSize * 1.6)
	local z = p.ZIndex or 3
	local holder = Kit.new("Frame", {
		Name = p.Name or "Ribbon",
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(W, h),
		Position = p.Position or UDim2.new(),
		AnchorPoint = p.AnchorPoint or Vector2.zero,
		LayoutOrder = p.LayoutOrder or 0,
		ZIndex = z,
		Parent = p.Parent,
	})
	local band = Kit.new("Frame", {
		Name = "Band",
		BackgroundColor3 = color,
		BorderSizePixel = 0,
		Size = UDim2.fromOffset(W, h),
		ZIndex = z,
		Parent = holder,
	})
	Kit.corner(band, "pill")
	Kit.gradient(band, 0.08)
	local label = Kit.new("TextLabel", {
		Name = "Text",
		Text = text,
		BackgroundTransparency = 1,
		Font = Kit.Fonts.Title,
		TextSize = textSize,
		TextColor3 = T.White,
		Size = UDim2.fromScale(1, 1),
		ZIndex = z + 1,
		Parent = band,
	})
	Kit.outlineText(label, darker(color, 0.62), math.max(1, textSize / 14))
	return holder, label
end

-- Doodles: simple line drawings scattered faintly over a big bubble's background (squiggles,
-- rings, little bar charts, stars made of two crossed lines), in `color`. Give it the bubble's
-- holder (not its content frame), so they sit over the shape and under the content.
function Kit.doodles(parent: GuiObject, color: Color3, seed: number, count: number?, area: { number }?)
	local rng = Random.new(seed)
	local a = area or { 0.08, 0.14, 0.92, 0.92 }
	local z = parent.ZIndex
	local layer = Kit.new("Frame", {
		Name = "Doodles",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = z,
		Parent = parent,
	})
	local function line(holder: Instance, x: number, y: number, len: number, rot: number)
		local f = Kit.new("Frame", {
			BackgroundColor3 = color,
			BorderSizePixel = 0,
			Size = UDim2.fromOffset(len, 4),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromOffset(x, y),
			Rotation = rot,
			ZIndex = z,
			Parent = holder,
		})
		Kit.corner(f, "pill")
	end
	local kinds = { "squiggle", "ring", "chart", "star", "squiggle", "ring" }
	for k = 1, count or 8 do
		local kind = kinds[(k - 1) % #kinds + 1]
		local holder = Kit.new("Frame", {
			Name = kind,
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(60, 40),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(rng:NextNumber(a[1], a[3]), rng:NextNumber(a[2], a[4])),
			Rotation = rng:NextInteger(-30, 30),
			ZIndex = z,
			Parent = layer,
		})
		if kind == "squiggle" then
			-- a zigzag of short rounded strokes
			for n = 0, 3 do
				line(holder, 8 + n * 14, 20, 18, if n % 2 == 0 then 38 else -38)
			end
		elseif kind == "ring" then
			local r = Kit.new("Frame", {
				BackgroundTransparency = 1,
				Size = UDim2.fromOffset(26, 26),
				Position = UDim2.fromOffset(17, 7),
				ZIndex = z,
				Parent = holder,
			})
			Kit.corner(r, "circle")
			Kit.new("UIStroke", { Color = color, Thickness = 4, Parent = r })
		elseif kind == "chart" then
			-- three bars standing on a line
			line(holder, 30, 36, 40, 0)
			for n, h in { 12, 22, 16 } do
				local bar = Kit.new("Frame", {
					BackgroundColor3 = color,
					BorderSizePixel = 0,
					Size = UDim2.fromOffset(8, h),
					AnchorPoint = Vector2.new(0.5, 1),
					Position = UDim2.fromOffset(16 + (n - 1) * 14, 32),
					ZIndex = z,
					Parent = holder,
				})
				Kit.corner(bar, 3)
			end
		else
			line(holder, 30, 20, 22, 45)
			line(holder, 30, 20, 22, -45)
		end
	end
	return layer
end

-- A hexagon badge with a small word over a big number (the town's level). It's three rounded
-- bars turned 60 degrees apart, on a white one a little bigger. props: Parent, Position, Size (px),
-- Color, Label, ZIndex. Returns the badge and its number label.
function Kit.hexBadge(value: string, props: { [string]: any }?): (Frame, TextLabel)
	local p = props or {}
	local px = p.Size or 68
	local z = p.ZIndex or 2
	local holder = Kit.box({
		Name = p.Name or "HexBadge",
		Size = UDim2.fromOffset(px, px),
		Position = p.Position,
		AnchorPoint = p.AnchorPoint,
		Parent = p.Parent,
	})
	holder.ZIndex = z
	local function hex(color: Color3, w: number)
		for _, rot in { 0, 60, 120 } do
			local f = Kit.new("Frame", {
				BackgroundColor3 = color,
				BorderSizePixel = 0,
				Size = UDim2.fromOffset(w, w * 0.577),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Rotation = rot + 90,
				ZIndex = z,
				Parent = holder,
			})
			Kit.corner(f, math.floor(w * 0.08))
		end
	end
	hex(T.White, px)
	hex(p.Color or T.Blue, px - 10)
	Kit.new("TextLabel", {
		Name = "Label",
		Text = p.Label or "LEVEL",
		BackgroundTransparency = 1,
		Font = Kit.Fonts.Title,
		TextSize = math.floor(px * 0.16),
		TextColor3 = T.White,
		Size = UDim2.new(1, 0, 0, px * 0.2),
		Position = UDim2.fromScale(0, 0.18),
		ZIndex = z + 1,
		Parent = holder,
	})
	local number = Kit.new("TextLabel", {
		Name = "Value",
		Text = value,
		BackgroundTransparency = 1,
		Font = Kit.Fonts.Title,
		TextSize = math.floor(px * 0.44),
		TextColor3 = T.White,
		Size = UDim2.new(1, 0, 0, px * 0.46),
		Position = UDim2.fromScale(0, 0.36),
		ZIndex = z + 1,
		Parent = holder,
	})
	return holder, number
end

-- A button in a quick menu: a flat icon in its own colour over its name, no background. props:
-- Parent, LayoutOrder, Size, Color (the icon's), TextSize.
function Kit.menuButton(icon: string, caption: string, props: { [string]: any }?, onClick: (() -> ())?): TextButton
	local p = props or {}
	local b = Kit.new("TextButton", {
		Name = caption,
		Text = "",
		AutoButtonColor = false,
		BackgroundTransparency = 1,
		Size = p.Size or UDim2.fromOffset(78, 82),
		LayoutOrder = p.LayoutOrder or 0,
		Parent = p.Parent,
	})
	b:SetAttribute("KitButton", true)
	local px = math.floor(b.Size.Y.Offset * 0.56)
	Icons.make(icon, px, {
		Name = "IconArt",
		Parent = b,
		Position = UDim2.new(0.5, -px / 2, 0, 4),
		Color = p.Color,
		Hole = T.White,
	})
	Kit.new("TextLabel", {
		Name = "Caption",
		Text = caption,
		BackgroundTransparency = 1,
		Font = Kit.Fonts.Title,
		TextSize = p.TextSize or 15,
		TextColor3 = T.Ink,
		Size = UDim2.new(1, 0, 0, 20),
		Position = UDim2.new(0, 0, 1, -22),
		Parent = b,
	})
	pressable(b)
	if onClick then
		b.Activated:Connect(onClick)
	end
	return b
end

-- A round utility button: a white icon on a dark see-through circle. props: Parent, Size (px),
-- Position, AnchorPoint, LayoutOrder, Name.
function Kit.roundButton(icon: string, props: { [string]: any }?, onClick: (() -> ())?): TextButton
	local p = props or {}
	local px = p.Size or 50
	local b = Kit.new("TextButton", {
		Name = p.Name or icon,
		Text = "",
		AutoButtonColor = false,
		BackgroundColor3 = T.Glass,
		BackgroundTransparency = T.GlassAlpha,
		Size = UDim2.fromOffset(px, px),
		Position = p.Position or UDim2.new(),
		AnchorPoint = p.AnchorPoint or Vector2.zero,
		LayoutOrder = p.LayoutOrder or 0,
		Parent = p.Parent,
	})
	b:SetAttribute("KitButton", true)
	Kit.corner(b, "circle")
	local ipx = math.floor(px * 0.56)
	Icons.make(icon, ipx, {
		Name = "IconArt",
		Parent = b,
		Position = UDim2.new(0.5, -ipx / 2, 0.5, -ipx / 2),
		Color = T.White,
		Hole = T.Glass,
	})
	pressable(b)
	if onClick then
		b.Activated:Connect(onClick)
	end
	return b
end

-- The big main action button: a bright wobbly pill with a big icon in its own colour and bold
-- white words (Build). props: Parent, Size, Position, AnchorPoint, Color, IconColor, TextSize.
function Kit.bigButton(text: string, icon: string, props: { [string]: any }?, onClick: (() -> ())?): TextButton
	local p = props or {}
	local size: UDim2 = p.Size or UDim2.fromOffset(230, 76)
	local color: Color3 = p.Color or T.Blue
	local b = Kit.new("TextButton", {
		Name = text,
		Text = "",
		AutoButtonColor = false,
		BackgroundTransparency = 1,
		Size = size,
		Position = p.Position or UDim2.new(),
		AnchorPoint = p.AnchorPoint or Vector2.zero,
		Parent = p.Parent,
	})
	b:SetAttribute("KitButton", true)
	local face = Kit.blob({
		Name = "Face",
		Parent = b,
		Size = UDim2.fromScale(1, 1),
		Color = color,
		Radius = "pill",
		Border = T.White,
		BorderWidth = 4,
		Estimate = Vector2.new(size.X.Offset, size.Y.Offset),
	})
	local _ = face
	local h = size.Y.Offset
	local ipx = math.floor(h * 0.7)
	Icons.make(icon, ipx, {
		Name = "IconArt",
		Parent = b,
		Position = UDim2.new(0, math.floor(h * 0.36), 0.5, -ipx / 2),
		Color = p.IconColor or T.Yellow,
		Hole = color,
		ZIndex = 3,
	})
	local label = Kit.new("TextLabel", {
		Name = "Label",
		Text = text,
		BackgroundTransparency = 1,
		Font = Kit.Fonts.Title,
		TextSize = p.TextSize or math.floor(h * 0.44),
		TextColor3 = T.White,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, -(ipx + h * 0.5), 1, 0),
		Position = UDim2.fromOffset(ipx + math.floor(h * 0.5), 0),
		ZIndex = 3,
		Parent = b,
	})
	Kit.outlineText(label, darker(color, 0.62), 1.5)
	pressable(b)
	if onClick then
		b.Activated:Connect(onClick)
	end
	return b
end

-- A modal panel: a cream paper card with a thick outline and a solid shadow, its title on a
-- ribbon across the top edge, and a red round close button on the top right corner. Returns
-- { root, card, body, close, title, header }. `root` holds the card and its shadow, so hiding or
-- destroying it takes both.
function Kit.panel(titleText: string, size: UDim2, onClose: (() -> ())?, icon: string?, color: Color3?): any
	local gui = Kit.root()
	local headColor = color or T.Blue
	local holder = Kit.box({
		Name = titleText,
		Size = size,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Parent = gui,
	})
	holder.ZIndex = 5
	-- a cream wobbly card on its darker copy
	local _, frame = Kit.blob({
		Name = "Card",
		Size = UDim2.fromScale(1, 1),
		Color = T.Cream,
		Border = headColor:Lerp(T.White, 0.3),
		BorderWidth = 5,
		Radius = 64,
		Bulge = 8,
		Waves = 3,
		Estimate = Vector2.new(size.X.Offset, size.Y.Offset),
		ZIndex = holder.ZIndex,
		Parent = holder,
	})
	-- faint doodles in the background, a little darker than the card
	Kit.doodles(frame.Parent :: Frame, T.Cream:Lerp(headColor, 0.16), #titleText * 31, 9)
	-- (kept for callers that place things by it: a clear strip where the banner sits)
	local header = Kit.box({
		Name = "Header",
		Size = UDim2.new(1, 0, 0, 56),
		Parent = frame,
	})
	-- the title on a flat pill banner over the top left edge (no icon: the user asked for plain titles)
	local _ = icon
	local _ribbon, title = Kit.ribbon(titleText, {
		Parent = frame,
		Color = headColor,
		TextSize = 28,
		Position = UDim2.new(0, 30, 0, -20),
		ZIndex = 3,
	})
	local close = Kit.closeButton({
		Size = UDim2.fromOffset(50, 50),
		Position = UDim2.new(1, 14, 0, -16),
		AnchorPoint = Vector2.new(1, 0),
		Parent = frame,
		ZIndex = 4,
	})
	local body = Kit.box({
		Name = "Body",
		Size = UDim2.new(1, -40, 1, -84),
		Position = UDim2.fromOffset(20, 68),
		Parent = frame,
	})
	local self = { root = holder, card = frame, body = body, close = close, title = title, header = header }
	close.Activated:Connect(function()
		if onClose then
			onClose()
		else
			holder.Visible = false
		end
	end)
	return self
end

-- Wobbly blobs ---------------------------------------------------------------------------------------
-- A blob's outline is one smooth curve: a rounded rectangle whose edge drifts in and out in a few
-- slow waves running round the whole shape. It's drawn as many small circles, overlapping so much
-- that the steps between them are under a pixel, threaded along that curve round a filled core;
-- the border is the same circles a little bigger, behind. Round blobs are smooth circles that
-- squash and stretch like jelly. One loop moves every blob on screen, on the frame clock.
type Dot = { frames: { Frame }, base: UDim2, nx: number, ny: number, u: number }
type BlobInfo = {
	holder: Frame,
	dots: { Dot },
	amp: number,
	waves: number,
	phase: number,
	jelly: { Frame }?,
	dead: boolean?,
}
local blobs: { BlobInfo } = {}
local blobLoop = false
local blobClock = 0

local function stepBlob(info: BlobInfo, t: number)
	if info.jelly then
		local k = math.sin(t * 2.6 + info.phase) * 0.045
		local k2 = math.sin(t * 1.7 + info.phase * 2) * 0.02
		for _, f in info.jelly do
			local grow = f:GetAttribute("Grow")
			local g = if type(grow) == "number" then grow else 0
			f.Size = UDim2.new(1 + k + k2, g * 2, 1 - k + k2, g * 2)
		end
		return
	end
	local a, n = info.amp, info.waves
	for _, d in info.dots do
		-- two slow waves round the shape, drifting opposite ways
		local w = a
			* (
				0.62 * math.sin(2 * math.pi * n * d.u + t * 0.9 + info.phase)
				+ 0.38 * math.sin(2 * math.pi * (n + 2) * d.u - t * 0.6 + info.phase * 1.7)
			)
		local pos = d.base + UDim2.fromOffset(d.nx * w, d.ny * w)
		for _, f in d.frames do
			f.Position = pos
		end
	end
end

local function startBlobs()
	if blobLoop then
		return
	end
	blobLoop = true
	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		blobClock += dt
		acc += dt
		if acc < 1 / 20 then
			return
		end
		acc = 0
		local i = 1
		while i <= #blobs do
			local info = blobs[i]
			if info.dead or not info.holder.Parent then
				table.remove(blobs, i)
				continue
			end
			if info.holder.Visible and onScreen(info.holder) then
				stepBlob(info, blobClock)
			end
			i += 1
		end
	end)
end

-- The points of a rounded rectangle path inset `inset` px from the holder's edges with corners of
-- radius `r` px, about `spacing` px apart for a holder of about `w` x `h` px: each as a UDim2
-- (scale for the straight runs, so it fits any size), its outward normal and how far round the
-- whole path it is (0..1).
local function pathPoints(w: number, h: number, inset: number, r: number, spacing: number): { any }
	local pts = {}
	local e = inset + r
	local straightX = math.max(0, w - 2 * e)
	local straightY = math.max(0, h - 2 * e)
	local arc = math.pi * r / 2
	local total = 2 * straightX + 2 * straightY + 4 * arc
	local walked = 0
	local function add(pos: UDim2, nx: number, ny: number, step: number)
		table.insert(pts, { pos = pos, nx = nx, ny = ny, u = walked / math.max(total, 1) })
		walked += step
	end
	local function run(length: number, at: (number) -> UDim2, nx: number, ny: number)
		local n = math.max(1, math.ceil(length / spacing))
		for k = 0, n - 1 do
			add(at(k / n), nx, ny, length / n)
		end
	end
	local function corner(cx: UDim, cy: UDim, from: number)
		local n = math.max(2, math.ceil(arc / spacing))
		for k = 0, n - 1 do
			local a = from + (k / n) * math.pi / 2
			local c, sn = math.cos(a), math.sin(a)
			add(UDim2.new(cx.Scale, cx.Offset + c * r, cy.Scale, cy.Offset + sn * r), c, sn, arc / n)
		end
	end
	-- clockwise from the top left corner's end
	run(straightX, function(t)
		return UDim2.new(t, (1 - 2 * t) * e, 0, inset)
	end, 0, -1)
	corner(UDim.new(1, -e), UDim.new(0, e), -math.pi / 2)
	run(straightY, function(t)
		return UDim2.new(1, -inset, t, (1 - 2 * t) * e)
	end, 1, 0)
	corner(UDim.new(1, -e), UDim.new(1, -e), 0)
	run(straightX, function(t)
		return UDim2.new(1 - t, -(1 - 2 * t) * e, 1, -inset)
	end, 0, 1)
	corner(UDim.new(0, e), UDim.new(1, -e), math.pi / 2)
	run(straightY, function(t)
		return UDim2.new(0, inset, 1 - t, -(1 - 2 * t) * e)
	end, -1, 0)
	corner(UDim.new(0, e), UDim.new(0, e), math.pi)
	return pts
end

-- Puts a blob's shape (with its border and darker copy) inside an existing frame, behind its other
-- children. props as Kit.blob. Returns the blob's record (set `dead` to stop it moving).
function Kit.blobInto(holder: Frame, p: { [string]: any }): BlobInfo
	local color: Color3 = p.Color or T.Paper
	local z = p.ZIndex or holder.ZIndex
	holder:SetAttribute("Blob", true)
	local rng = Random.new(p.Seed or math.random(1, 1e6))
	local border: Color3? = p.Border
	local bw = if border then (p.BorderWidth or 4) else 0
	local baseColor: any = p.Base or false -- flat: no darker copy unless asked for
	local info: BlobInfo = { holder = holder, dots = {}, amp = 0, waves = 3, phase = rng:NextNumber(0, 6.28) }

	local function layer(name: string): Frame
		return Kit.new("Frame", {
			Name = name,
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			ZIndex = z,
			Parent = holder,
		})
	end

	if p.Round then
		-- a smooth circle that squashes and stretches
		info.jelly = {}
		local function circle(parent: Frame, c: Color3, grow: number): Frame
			local f = Kit.new("Frame", {
				Name = "Circle",
				BackgroundColor3 = c,
				BorderSizePixel = 0,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.new(1, grow * 2, 1, grow * 2),
				ZIndex = z,
				Parent = parent,
			})
			f:SetAttribute("Grow", grow)
			Kit.corner(f, "circle")
			table.insert(info.jelly :: { Frame }, f)
			return f
		end
		if baseColor then
			local base = layer("Base")
			base.Position = UDim2.fromScale(0, 0.06)
			circle(base, baseColor, bw)
		end
		if border then
			circle(layer("Border"), border, bw)
		end
		circle(layer("Shape"), color, 0)
	else
		-- the size it will roughly be (for how many circles to use)
		local est: Vector2 = p.Estimate
			or Vector2.new(
				if holder.Size.X.Scale == 0 then holder.Size.X.Offset else 320,
				if holder.Size.Y.Scale == 0 and holder.Size.Y.Offset > 0 then holder.Size.Y.Offset else 120
			)
		local small = math.min(est.X, est.Y)
		local amp = p.Bulge or math.clamp(small * 0.035, 2.5, 9)
		local dot = math.clamp(small * 0.62, 30, 120) -- each circle's diameter: big, for a smooth curve
		local inset = dot / 2 + amp
		local radius = if p.Radius == "pill"
			then math.max(0, small / 2 - inset)
			else math.max(0, (if type(p.Radius) == "number" then p.Radius else 34) - dot / 2)
		local spacing = math.max(4, dot * 0.11)
		info.amp = amp
		info.waves = p.Waves or (if small < 90 then 2 else 3)
		local pts = pathPoints(est.X, est.Y, inset, radius, spacing)
		-- the filled middle, always inside the curve
		local coreInset = 2 * amp + 2
		local coreRadius = radius + dot / 2 - amp - 2
		local layers: { { name: string, color: Color3, grow: number, dy: number } } = {}
		if baseColor then
			table.insert(layers, { name = "Base", color = baseColor, grow = bw, dy = 6 })
		end
		if border then
			table.insert(layers, { name = "Border", color = border, grow = bw, dy = 0 })
		end
		table.insert(layers, { name = "Shape", color = color, grow = 0, dy = 0 })
		for _, pt in pts do
			table.insert(info.dots, { frames = {}, base = pt.pos, nx = pt.nx, ny = pt.ny, u = pt.u })
		end
		for _, spec in layers do
			local l = layer(spec.name)
			l.Position = UDim2.fromOffset(0, spec.dy)
			local core = Kit.new("Frame", {
				Name = "Core",
				BackgroundColor3 = spec.color,
				BorderSizePixel = 0,
				Size = UDim2.new(1, -2 * (coreInset - spec.grow), 1, -2 * (coreInset - spec.grow)),
				Position = UDim2.fromOffset(coreInset - spec.grow, coreInset - spec.grow),
				ZIndex = z,
				Parent = l,
			})
			Kit.corner(core, coreRadius + spec.grow)
			local d = dot + spec.grow * 2
			for k, pt in pts do
				local f = Kit.new("Frame", {
					Name = "Dot",
					BackgroundColor3 = spec.color,
					BorderSizePixel = 0,
					AnchorPoint = Vector2.new(0.5, 0.5),
					Size = UDim2.fromOffset(d, d),
					Position = pt.pos,
					ZIndex = z,
					Parent = l,
				})
				Kit.corner(f, "circle")
				table.insert(info.dots[k].frames, f)
			end
		end
	end

	if p.Tail then
		local size = p.TailSize or 20
		local at = p.TailAt or 0.5
		local tail = p.Tail
		local inset = size * 0.2
		local pos = if tail == "down"
			then UDim2.new(at, 0, 1, -inset)
			elseif tail == "up" then UDim2.new(at, 0, 0, inset)
			elseif tail == "left" then UDim2.new(0, inset, at, 0)
			else UDim2.new(1, -inset, at, 0)
		local function tailIn(layerName: string, c: Color3, grow: number)
			local l = holder:FindFirstChild(layerName)
			if l then
				Kit.new("Frame", {
					Name = "Tail",
					BackgroundColor3 = c,
					BorderSizePixel = 0,
					Rotation = 45,
					Size = UDim2.fromOffset(size + grow * 2, size + grow * 2),
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = pos,
					ZIndex = z,
					Parent = l,
				})
			end
		end
		if border then
			tailIn("Border", border, bw)
		end
		tailIn("Shape", color, 0)
	end

	stepBlob(info, 0)
	if p.Wobble ~= false then
		table.insert(blobs, info)
		startBlobs()
	end
	return info
end

-- A wobbly bubble. Returns the holder (size and place it) and its content frame (put things in
-- it; it fills the holder and, with AutomaticSize, sizes it). props: Parent, Size, Position,
-- AnchorPoint, AutomaticSize, LayoutOrder, Name, ZIndex, Color, Border and BorderWidth (an outline
-- that follows the wobbly edge), Base (the darker copy under it: a colour, or false; none by
-- default when there's a border), Radius (px or "pill"), Bulge (how far the edge drifts, px), Waves
-- (how many slow waves run round it), Estimate (its rough size in px when Size is in scale), Round
-- (a jelly circle), Wobble (false to keep still), Tail ("down", "up", "left", "right"), TailAt
-- (0..1 along that side), TailSize, Seed.
function Kit.blob(props: { [string]: any }?): (Frame, Frame)
	local p = props or {}
	local z = p.ZIndex or 1
	local auto = p.AutomaticSize or Enum.AutomaticSize.None
	local holder = Kit.box({
		Name = p.Name or "Blob",
		Size = p.Size or UDim2.fromOffset(240, 80),
		Position = p.Position,
		AnchorPoint = p.AnchorPoint,
		AutomaticSize = auto,
		LayoutOrder = p.LayoutOrder,
		Parent = p.Parent,
	})
	holder.ZIndex = z
	Kit.blobInto(holder, p)
	local content = Kit.box({
		Name = "Content",
		Size = if auto == Enum.AutomaticSize.Y
			then UDim2.new(1, 0, 0, 0)
			elseif auto == Enum.AutomaticSize.X then UDim2.new(0, 0, 1, 0)
			elseif auto == Enum.AutomaticSize.XY then UDim2.new()
			else UDim2.fromScale(1, 1),
		AutomaticSize = auto,
		Parent = holder,
	})
	content.ZIndex = z + 1
	return holder, content
end

-- Recolours a blob (its face, tail and darker copy).
function Kit.setBlobColor(holder: Instance, color: Color3)
	for _, layerName in { "Shape", "Base" } do
		local layer = holder:FindFirstChild(layerName)
		if layer then
			local c = if layerName == "Base" then darker(color, 0.86) else color
			for _, f in layer:GetChildren() do
				if f:IsA("Frame") then
					f.BackgroundColor3 = c
				end
			end
		end
	end
end

-- Recolours a flat icon drawn by Icons.make: its glyph and its cut out details.
function Kit.recolorIcon(icon: Instance, glyph: Color3, hole: Color3)
	local was = icon:GetAttribute("Glyph")
	local wasHole = icon:GetAttribute("Hole")
	for _, d in icon:GetDescendants() do
		if d:IsA("Frame") and d.BackgroundTransparency < 1 then
			local hex = d.BackgroundColor3:ToHex()
			d.BackgroundColor3 = if hex == wasHole then hole else glyph
		elseif d:IsA("UIStroke") then
			d.Color = if d.Color:ToHex() == wasHole then hole else glyph
		end
	end
	icon:SetAttribute("Glyph", glyph:ToHex())
	icon:SetAttribute("Hole", hole:ToHex())
	local _ = was
end

-- A speech bubble: a white rounded card with a little tail and a soft shadow under it. Returns
-- the holder (size and place it) and the body (put things in it). props: Parent, Size,
-- Position, AnchorPoint, AutomaticSize, LayoutOrder, Name, ZIndex, Color, Radius, Shadow
-- (default true), Tail ("down", "up", "left", "right" or false), TailAt (0..1 along that side),
-- TailSize.
function Kit.bubble(props: { [string]: any }?): (Frame, Frame)
	local p = props or {}
	local tail = p.Tail
	if tail == nil then
		tail = "down"
	end
	local color: Color3 = p.Color or T.White
	if p.Radius == "pill" then
		-- a small pill: a plain smooth pill with its tail (and a darker copy under it)
		local z = p.ZIndex or 1
		local holder = Kit.box({
			Name = p.Name or "Bubble",
			Parent = p.Parent,
			Size = p.Size or UDim2.fromOffset(240, 54),
			Position = p.Position,
			AnchorPoint = p.AnchorPoint,
			LayoutOrder = p.LayoutOrder,
		})
		holder.ZIndex = z
		holder:SetAttribute("Blob", true)
		for _, spec in { { "Base", darker(color, 0.86), 5 }, { "Shape", color, 0 } } do
			if spec[1] == "Base" and p.Shadow ~= true then
				continue
			end
			local l = Kit.new("Frame", {
				Name = spec[1],
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1),
				Position = UDim2.fromOffset(0, spec[3]),
				ZIndex = z,
				Parent = holder,
			})
			local core = Kit.frame({ Name = "Core", Parent = l, Color = spec[2], Radius = "pill", ZIndex = z })
			local _ = core
			if tail then
				local size = p.TailSize or 16
				local at = p.TailAt or 0.5
				Kit.new("Frame", {
					Name = "Tail",
					BackgroundColor3 = spec[2],
					BorderSizePixel = 0,
					Rotation = 45,
					Size = UDim2.fromOffset(size, size),
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = if tail == "down"
						then UDim2.new(at, 0, 1, -size * 0.2)
						elseif tail == "up" then UDim2.new(at, 0, 0, size * 0.2)
						elseif tail == "left" then UDim2.new(0, size * 0.2, at, 0)
						else UDim2.new(1, -size * 0.2, at, 0),
					ZIndex = z,
					Parent = l,
				})
			end
		end
		local content = Kit.box({ Name = "Content", Parent = holder, Size = UDim2.fromScale(1, 1) })
		content.ZIndex = z + 1
		return holder, content
	end
	return Kit.blob({
		Name = p.Name or "Bubble",
		Parent = p.Parent,
		Size = p.Size or UDim2.fromOffset(240, 64),
		Position = p.Position,
		AnchorPoint = p.AnchorPoint,
		AutomaticSize = p.AutomaticSize,
		LayoutOrder = p.LayoutOrder,
		ZIndex = p.ZIndex,
		Color = color,
		Base = if p.Shadow == false then false else nil,
		Border = p.Border,
		BorderWidth = p.BorderWidth,
		Radius = p.Radius or 40,
		Bulge = p.Bulge,
		Estimate = p.Estimate,
		Tail = tail or nil,
		TailAt = p.TailAt,
		TailSize = p.TailSize,
	})
end

-- Recolours a bubble made by Kit.bubble (its body and tail).
function Kit.setBubbleColor(holder: Instance, color: Color3)
	Kit.setBlobColor(holder, color)
end

-- An answer to pick, as a speech bubble: white with navy words, swaying a little; under the
-- pointer it turns sunny yellow with soft stripes. props: Parent, Size, LayoutOrder, TextSize,
-- Name, ZIndex, Disabled (greyed words, no yellow), Icon (an icon left of the words), Rich (the
-- text is rich text, for coloured names).
function Kit.choice(text: string, props: { [string]: any }?, onClick: (() -> ())?): TextButton
	local p = props or {}
	local z = p.ZIndex or 1
	local b = Kit.new("TextButton", {
		Text = "",
		AutoButtonColor = false,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = p.Size or UDim2.new(1, 0, 0, 54),
		LayoutOrder = p.LayoutOrder or 0,
		Name = p.Name or "Choice",
		ZIndex = z,
		Parent = p.Parent,
	})
	b:SetAttribute("KitButton", true)
	local holder, body = Kit.bubble({
		Parent = b,
		Size = UDim2.fromScale(1, 1),
		Radius = "pill",
		Tail = "right",
		TailAt = 0.72,
		TailSize = 14,
		ZIndex = z,
	})
	local core = holder:FindFirstChild("Shape") and (holder :: any).Shape:FindFirstChild("Core")
	local stripes = Kit.new("UIGradient", {
		Name = "Stripes",
		Enabled = false,
		Rotation = 24,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
			ColorSequenceKeypoint.new(0.12, Color3.new(0.93, 0.9, 0.84)),
			ColorSequenceKeypoint.new(0.25, Color3.new(1, 1, 1)),
			ColorSequenceKeypoint.new(0.37, Color3.new(0.93, 0.9, 0.84)),
			ColorSequenceKeypoint.new(0.5, Color3.new(1, 1, 1)),
			ColorSequenceKeypoint.new(0.62, Color3.new(0.93, 0.9, 0.84)),
			ColorSequenceKeypoint.new(0.75, Color3.new(1, 1, 1)),
			ColorSequenceKeypoint.new(0.87, Color3.new(0.93, 0.9, 0.84)),
			ColorSequenceKeypoint.new(1, Color3.new(1, 1, 1)),
		}),
		Parent = core or body,
	})
	local row = Kit.box({ Name = "Content", Parent = body, Size = UDim2.fromScale(1, 1) })
	row.ZIndex = z + 1
	local list = Kit.list(row, 8, true, Enum.HorizontalAlignment.Center)
	list.VerticalAlignment = Enum.VerticalAlignment.Center
	if p.Icon and Icons.has(p.Icon) then
		Icons.make(p.Icon, 26, { Name = "IconArt", Parent = row, ZIndex = z + 1, LayoutOrder = 1 })
	end
	local label = Kit.new("TextLabel", {
		Name = "Label",
		Text = text,
		BackgroundTransparency = 1,
		Font = Kit.Fonts.Title,
		TextSize = p.TextSize or 20,
		TextColor3 = if p.Disabled then T.InkSoft else T.Ink,
		Size = UDim2.fromOffset(0, 30),
		AutomaticSize = Enum.AutomaticSize.X,
		LayoutOrder = 2,
		ZIndex = z + 1,
		RichText = p.Rich == true,
		Parent = row,
	})
	local _ = label
	local function lit(on: boolean)
		Kit.setBubbleColor(holder, if on and not p.Disabled then Color3.fromRGB(255, 214, 72) else T.White)
		stripes.Enabled = on and not p.Disabled
	end
	b.MouseEnter:Connect(function()
		lit(true)
	end)
	b.MouseLeave:Connect(function()
		lit(false)
	end)
	pressable(b)
	Kit.wobbly(b, 0.9)
	if onClick then
		b.Activated:Connect(onClick)
	end
	return b
end

-- A friendship tag shaped like an arrow: the words on a coloured band ending in a point.
-- `dir` is "right" (default) or "left". Returns the frame; it sizes itself to the words.
function Kit.arrowTag(text: string, color: Color3?, props: { [string]: any }?): Frame
	local p = props or {}
	local col = color or Color3.fromRGB(255, 214, 72)
	local h = p.Height or 26
	local left = p.Dir == "left"
	local z = p.ZIndex or 1
	local holder = Kit.box({
		Name = p.Name or "ArrowTag",
		Size = UDim2.fromOffset(0, h),
		AutomaticSize = Enum.AutomaticSize.X,
		Position = p.Position,
		AnchorPoint = p.AnchorPoint,
		LayoutOrder = p.LayoutOrder,
		Parent = p.Parent,
	})
	holder.ZIndex = z
	local band = Kit.frame({
		Name = "Band",
		Size = UDim2.fromOffset(0, h),
		AutomaticSize = Enum.AutomaticSize.X,
		Color = col,
		Radius = 6,
		ZIndex = z,
		Parent = holder,
	})
	local pad = Kit.pad(band, 12, 0)
	if left then
		pad.PaddingLeft = UDim.new(0, h * 0.5 + 8)
	else
		pad.PaddingRight = UDim.new(0, h * 0.5 + 8)
	end
	Kit.new("TextLabel", {
		Name = "Label",
		Text = text,
		BackgroundTransparency = 1,
		Font = Kit.Fonts.Title,
		TextSize = math.floor(h * 0.6),
		TextColor3 = T.Ink,
		Size = UDim2.fromOffset(0, h),
		AutomaticSize = Enum.AutomaticSize.X,
		ZIndex = z + 1,
		Parent = band,
	})
	-- the point: a turned square half out of the band's end
	local side = h / math.sqrt(2)
	Kit.new("Frame", {
		Name = "Point",
		BackgroundColor3 = col,
		BorderSizePixel = 0,
		Rotation = 45,
		Size = UDim2.fromOffset(side, side),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = if left then UDim2.new(0, 2, 0.5, 0) else UDim2.new(1, -2, 0.5, 0),
		ZIndex = z,
		Parent = band,
	})
	return holder
end

function Kit.scroll(props: { [string]: any }?): ScrollingFrame
	local p = props or {}
	return Kit.new("ScrollingFrame", {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = p.Size or UDim2.fromScale(1, 1),
		Position = p.Position or UDim2.new(),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = p.Axis or Enum.AutomaticSize.Y,
		ScrollBarThickness = 8,
		ScrollBarImageColor3 = T.Ink,
		ScrollBarImageTransparency = 0.55,
		ScrollingDirection = if p.Axis == Enum.AutomaticSize.X
			then Enum.ScrollingDirection.X
			else Enum.ScrollingDirection.Y,
		Name = p.Name or "Scroll",
		LayoutOrder = p.LayoutOrder or 0,
		Parent = p.Parent,
	})
end

function Kit.textbox(placeholder: string, props: { [string]: any }?): TextBox
	local p = props or {}
	local box = Kit.new("TextBox", {
		PlaceholderText = placeholder,
		Text = p.Text or "",
		Font = Kit.Fonts.Body,
		TextSize = p.TextSize or 18,
		TextColor3 = T.Ink,
		PlaceholderColor3 = T.InkSoft,
		BackgroundColor3 = T.PaperDark,
		BorderSizePixel = 0,
		ClearTextOnFocus = false,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = p.Size or UDim2.new(1, 0, 0, 40),
		Position = p.Position or UDim2.new(),
		LayoutOrder = p.LayoutOrder or 0,
		Name = p.Name or "TextBox",
		Parent = p.Parent,
	})
	Kit.corner(box, "pill")
	Kit.pad(box, 16, 0)
	return box
end

-- A horizontal slider. onChange(value) fires while dragging. Returns the frame and a setter.
function Kit.slider(
	label: string,
	min: number,
	max: number,
	value: number,
	step: number?,
	onChange: ((number) -> ())?,
	props: { [string]: any }?
): (Frame, (number) -> ())
	local p = props or {}
	local holder = Kit.box({
		Size = p.Size or UDim2.new(1, 0, 0, 46),
		LayoutOrder = p.LayoutOrder or 0,
		Parent = p.Parent,
		Name = label,
	})
	Kit.text(label, { Parent = holder, Size = UDim2.new(1, -60, 0, 20), TextSize = 16, Font = Kit.Fonts.Bold })
	local readout = Kit.text("", {
		Parent = holder,
		Size = UDim2.new(0, 60, 0, 20),
		Position = UDim2.new(1, -60, 0, 0),
		TextSize = 16,
		Font = Kit.Fonts.Bold,
		AlignX = Enum.TextXAlignment.Right,
		Color = T.InkSoft,
	})
	local track = Kit.frame({
		Parent = holder,
		Size = UDim2.new(1, -14, 0, 12),
		Position = UDim2.new(0, 7, 0, 28),
		Color = T.PaperDark,
		Radius = 6,
		Stroke = T.Ink,
		StrokeThickness = 2,
	})
	local fill = Kit.frame({ Parent = track, Size = UDim2.fromScale(0, 1), Color = T.Blue, Radius = 6 })
	Kit.gradient(fill, 0.25)
	local knob = Kit.frame({
		Parent = track,
		Size = UDim2.fromOffset(24, 24),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0, 0.5),
		Color = T.White,
		Radius = "circle",
		Stroke = T.Ink,
		StrokeThickness = 2.5,
	})
	Kit.gradient(knob, 0.15)
	local current = value
	local function show(v: number)
		local t = if max > min then (v - min) / (max - min) else 0
		fill.Size = UDim2.fromScale(t, 1)
		knob.Position = UDim2.fromScale(t, 0.5)
		readout.Text = if (step or 0) >= 1 then tostring(math.floor(v + 0.5)) else string.format("%.2f", v)
	end
	local function set(v: number)
		if step and step > 0 then
			v = math.floor((v - min) / step + 0.5) * step + min
		end
		v = math.clamp(v, min, max)
		current = v
		show(v)
	end
	set(value)
	local dragging = false
	local function fromX(x: number)
		local t = math.clamp((x - track.AbsolutePosition.X) / math.max(1, track.AbsoluteSize.X), 0, 1)
		local before = current
		set(min + (max - min) * t)
		if onChange and current ~= before then
			onChange(current)
		end
	end
	local hit = Kit.new("TextButton", {
		Text = "",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 30),
		Position = UDim2.fromOffset(0, 18),
		Parent = holder,
	})
	hit.InputBegan:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			dragging = true
			fromX(input.Position.X)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if
			dragging
			and (
				input.UserInputType == Enum.UserInputType.MouseMovement
				or input.UserInputType == Enum.UserInputType.Touch
			)
		then
			fromX(input.Position.X)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			dragging = false
		end
	end)
	return holder, set
end

-- A row of tab buttons. onSelect(id) when one is picked. Returns the frame and select(id).
-- Entries may carry an `icon` (an icon name).
function Kit.tabs(
	list: { { id: string, name: string, icon: string? } },
	onSelect: (string) -> (),
	props: { [string]: any }?
): (ScrollingFrame, (string) -> ())
	local p = props or {}
	local bar = Kit.scroll({
		Parent = p.Parent,
		Size = p.Size or UDim2.new(1, 0, 0, 44),
		Axis = Enum.AutomaticSize.X,
		Name = "Tabs",
		LayoutOrder = p.LayoutOrder or 0,
	})
	bar.Position = p.Position or UDim2.new()
	bar.ScrollBarThickness = 0
	Kit.list(bar, 6, true)
	local buttons = {}
	local function select(id: string)
		for bid, b in buttons do
			if bid == id then
				Kit.setButtonColor(b, p.Active or T.Blue, T.White)
			else
				Kit.setButtonColor(b, T.PaperDark, T.Ink)
			end
		end
	end
	for i, t in list do
		local b = Kit.button(t.name, {
			Parent = bar,
			Size = UDim2.fromOffset(0, p.Height or 38),
			AutomaticSize = Enum.AutomaticSize.X,
			TextSize = p.TextSize or 17,
			Color = T.PaperDark,
			TextColor = T.Ink,
			LayoutOrder = i,
			Radius = 12,
			Icon = t.icon,
		})
		Kit.pad(b, 12, 0)
		buttons[t.id] = b
		b.Activated:Connect(function()
			select(t.id)
			onSelect(t.id)
		end)
	end
	return bar, select
end

function Kit.swatch(color: Color3, size: number?, onClick: (() -> ())?, props: { [string]: any }?): TextButton
	local p = props or {}
	local b = Kit.new("TextButton", {
		Text = "",
		AutoButtonColor = true,
		BackgroundColor3 = color,
		BorderSizePixel = 0,
		Size = UDim2.fromOffset(size or 28, size or 28),
		LayoutOrder = p.LayoutOrder or 0,
		Parent = p.Parent,
	})
	Kit.corner(b, "circle")
	Kit.stroke(b, T.Ink, 2)
	Kit.gradient(b, 0.12)
	if onClick then
		b.Activated:Connect(onClick)
	end
	return b
end

-- A panel or card springs into view.
function Kit.popIn(frame: GuiObject)
	local s = frame:FindFirstChild("PopScale") or Kit.new("UIScale", { Name = "PopScale", Parent = frame })
	s.Scale = 0.6
	frame.Visible = true
	TweenService:Create(s, TweenInfo.new(0.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
end

-- Shrinks a frame away, then runs `done` (which usually hides or destroys it).
function Kit.popOut(frame: GuiObject, done: (() -> ())?)
	local s = frame:FindFirstChild("PopScale") or Kit.new("UIScale", { Name = "PopScale", Parent = frame })
	TweenService:Create(s, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Scale = 0.7 }):Play()
	task.delay(0.15, function()
		if done then
			done()
		end
	end)
end

-- Slides a frame in from (dx, dy) pixels away, after `delay` seconds.
function Kit.slideIn(frame: GuiObject, dx: number, dy: number, delay: number?)
	local home = frame:GetAttribute("Home")
	local target: UDim2
	if typeof(home) == "UDim2" then
		target = home
	else
		target = frame.Position
		frame:SetAttribute("Home", target)
	end
	frame.Position = target + UDim2.fromOffset(dx, dy)
	local tween = TweenService:Create(
		frame,
		TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out, 0, false, delay or 0),
		{ Position = target }
	)
	tween:Play()
end

-- A quick swell, for a number that just changed.
function Kit.bump(frame: GuiObject, amount: number?)
	local s = frame:FindFirstChild("Bump") or Kit.new("UIScale", { Name = "Bump", Parent = frame })
	s.Scale = 1 + (amount or 0.15)
	TweenService:Create(s, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
end

-- Coins that fly from a point on screen into a counter, the way games show money coming in.
-- `from` is in screen pixels (or nil for the middle of the screen); `to` is the counter.
function Kit.flyCoins(from: Vector2?, to: GuiObject, count: number?)
	local gui = Kit.root()
	local scale = gui:FindFirstChild("Scale") :: UIScale?
	local k = if scale then scale.Scale else 1
	local cam = workspace.CurrentCamera
	local view = if cam then cam.ViewportSize else Vector2.new(1280, 720)
	local start = (from or Vector2.new(view.X / 2, view.Y / 2 - 40)) / k
	local goal = (to.AbsolutePosition + Vector2.new(24, to.AbsoluteSize.Y / 2)) / k
	for i = 1, count or 6 do
		local coin = Icons.make("coin", 34, {
			Parent = gui,
			Position = UDim2.fromOffset(start.X - 17, start.Y - 17),
			ZIndex = 60,
		})
		local spread = Vector2.new(math.random(-70, 70), math.random(-60, 10))
		local mid = start + spread
		TweenService
			:Create(coin, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, i * 0.05), {
				Position = UDim2.fromOffset(mid.X - 17, mid.Y - 17),
			})
			:Play()
		task.delay(0.3 + i * 0.05, function()
			TweenService:Create(coin, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				Position = UDim2.fromOffset(goal.X - 17, goal.Y - 17),
			}):Play()
			task.delay(0.46, function()
				coin:Destroy()
				Kit.bump(to, 0.08)
			end)
		end)
	end
end

function Kit.isTouch(): boolean
	return UserInputService.TouchEnabled and not UserInputService.MouseEnabled
end

function Kit.topInset(): number
	local inset = GuiService:GetGuiInset()
	return inset.Y
end

-- Is this object actually on screen: it and every parent visible, its ScreenGui enabled?
local function shown(o: Instance): boolean
	local cur: Instance? = o
	while cur and not cur:IsA("PlayerGui") do
		if cur:IsA("GuiObject") and not cur.Visible then
			return false
		end
		if cur:IsA("ScreenGui") and not cur.Enabled then
			return false
		end
		cur = cur.Parent
	end
	return true
end

-- Is the pointer over any of our interface (so world clicks should be ignored)? Takes a viewport
-- position (like GetMouseLocation); defaults to the mouse.
function Kit.overUI(pos: Vector2?): boolean
	local p = pos or UserInputService:GetMouseLocation()
	local inset = GuiService:GetGuiInset()
	local gui = player:FindFirstChild("PlayerGui")
	if not gui then
		return false
	end
	local objects = (gui :: PlayerGui):GetGuiObjectsAtPosition(p.X - inset.X, p.Y - inset.Y)
	for _, o in objects do
		if
			(o:IsA("GuiButton") or o:IsA("TextBox") or o:IsA("ScrollingFrame") or o.BackgroundTransparency < 0.95)
			and shown(o)
		then
			return true
		end
	end
	return false
end

return Kit
