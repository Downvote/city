-- The UI toolkit: one theme and the pieces every screen is built from. The look follows what
-- players know from Roblox life sims and builders: clean white cards with soft shadows, bold
-- rounded buttons with a light gradient, icon tiles, stat pills and a dock of big icon buttons.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

local Kit = {}

Kit.Theme = {
	Paper = Color3.fromRGB(250, 251, 253),
	PaperDark = Color3.fromRGB(234, 239, 246),
	Ink = Color3.fromRGB(31, 41, 55),
	InkSoft = Color3.fromRGB(107, 114, 128),
	Line = Color3.fromRGB(213, 220, 230),
	Green = Color3.fromRGB(52, 196, 106),
	GreenDark = Color3.fromRGB(30, 150, 78),
	Coral = Color3.fromRGB(242, 95, 92),
	CoralDark = Color3.fromRGB(194, 64, 62),
	Blue = Color3.fromRGB(59, 130, 246),
	BlueDark = Color3.fromRGB(37, 99, 235),
	Yellow = Color3.fromRGB(255, 201, 60),
	YellowDark = Color3.fromRGB(212, 155, 15),
	Purple = Color3.fromRGB(139, 92, 246),
	White = Color3.fromRGB(255, 255, 255),
	Shadow = Color3.fromRGB(15, 23, 42),
	Glass = Color3.fromRGB(17, 24, 39), -- dark translucent bars over the 3D view
}

local T = Kit.Theme

Kit.Fonts = {
	Title = Enum.Font.BuilderSansExtraBold,
	Body = Enum.Font.BuilderSansMedium,
	Bold = Enum.Font.BuilderSansBold,
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

function Kit.corner(inst: Instance, radius: number?): UICorner
	return Kit.new("UICorner", { CornerRadius = UDim.new(0, radius or 12), Parent = inst })
end

function Kit.stroke(inst: Instance, color: Color3?, thickness: number?): UIStroke
	return Kit.new("UIStroke", {
		Color = color or T.Line,
		Thickness = thickness or 1.5,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = inst,
	})
end

-- A top-to-bottom shading on a frame or button (lighter at the top).
function Kit.gradient(inst: Instance, strength: number?): UIGradient
	local k = 1 - (strength or 0.14)
	return Kit.new("UIGradient", {
		Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.new(k, k, k)),
		Rotation = 90,
		Parent = inst,
	})
end

function Kit.pad(inst: Instance, px: number, py: number?): UIPadding
	local y = py or px
	return Kit.new("UIPadding", {
		PaddingLeft = UDim.new(0, px),
		PaddingRight = UDim.new(0, px),
		PaddingTop = UDim.new(0, y),
		PaddingBottom = UDim.new(0, y),
		Parent = inst,
	})
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
		Kit.corner(f, p.Radius or 12)
	end
	if p.Stroke then
		local s = Kit.stroke(f, if typeof(p.Stroke) == "Color3" then p.Stroke else nil)
		s.Transparency = 0.2
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

function Kit.text(text: string, props: { [string]: any }?): TextLabel
	local p = props or {}
	return Kit.new("TextLabel", {
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
end

function Kit.title(text: string, props: { [string]: any }?): TextLabel
	local p = table.clone(props or {})
	p.Font = Kit.Fonts.Title
	p.TextSize = p.TextSize or 26
	return Kit.text(text, p)
end

local function darker(c: Color3, k: number?): Color3
	local m = k or 0.78
	return Color3.new(c.R * m, c.G * m, c.B * m)
end
Kit.darker = darker

local function pressable(b: GuiButton)
	local scale = Kit.new("UIScale", { Parent = b })
	b.MouseEnter:Connect(function()
		TweenService:Create(scale, TweenInfo.new(0.1), { Scale = 1.04 }):Play()
	end)
	b.MouseLeave:Connect(function()
		TweenService:Create(scale, TweenInfo.new(0.1), { Scale = 1 }):Play()
	end)
	b.MouseButton1Down:Connect(function()
		TweenService:Create(scale, TweenInfo.new(0.06), { Scale = 0.94 }):Play()
	end)
	b.MouseButton1Up:Connect(function()
		TweenService:Create(scale, TweenInfo.new(0.08), { Scale = 1 }):Play()
	end)
end

-- A bold rounded button. Returns the TextButton; `onClick` runs on activation.
function Kit.button(text: string, props: { [string]: any }?, onClick: (() -> ())?): TextButton
	local p = props or {}
	local color = p.Color or T.Green
	local b = Kit.new("TextButton", {
		Text = text,
		AutoButtonColor = false,
		Font = p.Font or Kit.Fonts.Title,
		TextSize = p.TextSize or 20,
		TextColor3 = p.TextColor or T.White,
		BackgroundColor3 = color,
		BorderSizePixel = 0,
		Size = p.Size or UDim2.fromOffset(140, 44),
		Position = p.Position or UDim2.new(),
		AnchorPoint = p.AnchorPoint or Vector2.zero,
		LayoutOrder = p.LayoutOrder or 0,
		Name = p.Name or text,
		ZIndex = p.ZIndex or 1,
		TextWrapped = true,
		AutomaticSize = p.AutomaticSize or Enum.AutomaticSize.None,
		Parent = p.Parent,
	})
	Kit.corner(b, p.Radius or 10)
	local stroke = Kit.stroke(b, p.StrokeColor or darker(color), 1.5)
	stroke.Transparency = 0.25
	Kit.gradient(b)
	pressable(b)
	if onClick then
		b.Activated:Connect(onClick)
	end
	return b
end

-- Recolours a Kit button (for toggles and selected tabs).
function Kit.setButtonColor(b: GuiButton, color: Color3, textColor: Color3?)
	b.BackgroundColor3 = color
	local s = b:FindFirstChildOfClass("UIStroke")
	if s then
		s.Color = darker(color)
	end
	if textColor and b:IsA("TextButton") then
		b.TextColor3 = textColor
	end
	local label = b:FindFirstChild("Caption")
	if textColor and label and label:IsA("TextLabel") then
		label.TextColor3 = textColor
	end
end

-- A square tile with a big icon and a caption under it (docks, tool strips, categories).
function Kit.iconButton(icon: string, caption: string?, props: { [string]: any }?, onClick: (() -> ())?): TextButton
	local p = props or {}
	local size = p.Size or UDim2.fromOffset(72, 72)
	local color = p.Color or T.Paper
	local b = Kit.new("TextButton", {
		Text = "",
		AutoButtonColor = false,
		BackgroundColor3 = color,
		BorderSizePixel = 0,
		Size = size,
		Position = p.Position or UDim2.new(),
		AnchorPoint = p.AnchorPoint or Vector2.zero,
		LayoutOrder = p.LayoutOrder or 0,
		Name = p.Name or caption or icon,
		ZIndex = p.ZIndex or 1,
		Parent = p.Parent,
	})
	Kit.corner(b, p.Radius or 14)
	local stroke = Kit.stroke(b, darker(color, 0.85), 1.5)
	stroke.Transparency = 0.3
	Kit.gradient(b, 0.08)
	local hasCaption = caption ~= nil and caption ~= ""
	Kit.new("TextLabel", {
		Name = "Icon",
		Text = icon,
		BackgroundTransparency = 1,
		Font = Enum.Font.BuilderSansBold,
		TextScaled = true,
		Size = if hasCaption then UDim2.new(0.62, 0, 0.5, 0) else UDim2.fromScale(0.62, 0.62),
		Position = if hasCaption then UDim2.new(0.5, 0, 0.1, 0) else UDim2.fromScale(0.5, 0.19),
		AnchorPoint = Vector2.new(0.5, 0),
		TextColor3 = p.IconColor or T.Ink,
		ZIndex = (p.ZIndex or 1) + 1,
		Parent = b,
	})
	if hasCaption then
		Kit.new("TextLabel", {
			Name = "Caption",
			Text = caption,
			BackgroundTransparency = 1,
			Font = Kit.Fonts.Bold,
			TextSize = p.TextSize or 13,
			TextWrapped = true,
			Size = UDim2.new(1, -6, 0.32, 0),
			Position = UDim2.new(0.5, 0, 0.64, 0),
			AnchorPoint = Vector2.new(0.5, 0),
			TextColor3 = p.TextColor or T.Ink,
			ZIndex = (p.ZIndex or 1) + 1,
			Parent = b,
		})
	end
	pressable(b)
	if onClick then
		b.Activated:Connect(onClick)
	end
	return b
end

-- A rounded stat pill: an icon and a value. Returns the frame and the value label.
function Kit.pill(icon: string, props: { [string]: any }?): (Frame, TextLabel)
	local p = props or {}
	local f = Kit.frame({
		Name = p.Name or "Pill",
		Size = p.Size or UDim2.fromOffset(150, 40),
		Position = p.Position,
		AnchorPoint = p.AnchorPoint,
		Color = p.Color or T.Paper,
		Radius = 20,
		Parent = p.Parent,
		LayoutOrder = p.LayoutOrder,
	})
	local s = Kit.stroke(f, T.Line, 1.5)
	s.Transparency = 0.2
	Kit.new("TextLabel", {
		Name = "Icon",
		Text = icon,
		BackgroundTransparency = 1,
		TextScaled = true,
		Font = Enum.Font.BuilderSansBold,
		Size = UDim2.fromOffset(28, 28),
		Position = UDim2.new(0, 8, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		Parent = f,
	})
	local value = Kit.new("TextLabel", {
		Name = "Value",
		Text = "",
		BackgroundTransparency = 1,
		Font = Kit.Fonts.Title,
		TextSize = p.TextSize or 20,
		TextColor3 = p.TextColor or T.Ink,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, -46, 1, 0),
		Position = UDim2.fromOffset(40, 0),
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = f,
	})
	return f, value
end

-- A drop shadow behind a card: a sibling just under it (children always draw above parents).
function Kit.shadow(card: GuiObject, radius: number?): Frame
	local s = Kit.frame({
		Name = card.Name .. "Shadow",
		Size = card.Size,
		Position = card.Position + UDim2.fromOffset(0, 6),
		AnchorPoint = card.AnchorPoint,
		Color = T.Shadow,
		Transparency = 0.86,
		Radius = radius or 16,
		ZIndex = math.max(0, card.ZIndex - 1),
		Parent = card.Parent,
	})
	card:GetPropertyChangedSignal("Visible"):Connect(function()
		s.Visible = card.Visible
	end)
	card.Destroying:Connect(function()
		s:Destroy()
	end)
	return s
end

-- A modal card with an icon, a title and a close button. Returns { root, body, close, title }.
-- `root` holds the card and its shadow, so hiding or destroying it takes both.
function Kit.panel(titleText: string, size: UDim2, onClose: (() -> ())?, icon: string?): any
	local gui = Kit.root()
	local holder = Kit.box({
		Name = titleText,
		Size = size,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Parent = gui,
	})
	holder.ZIndex = 5
	Kit.frame({
		Name = "Shadow",
		Size = UDim2.fromScale(1, 1),
		Position = UDim2.fromOffset(0, 8),
		Color = T.Shadow,
		Transparency = 0.82,
		Radius = 18,
		Parent = holder,
	})
	local frame =
		Kit.frame({ Name = "Card", Size = UDim2.fromScale(1, 1), Stroke = T.Line, Parent = holder, Radius = 18 })
	local header = Kit.box({ Name = "Header", Size = UDim2.new(1, 0, 0, 58), Parent = frame })
	local x = 20
	if icon then
		local badge = Kit.frame({
			Parent = header,
			Size = UDim2.fromOffset(38, 38),
			Position = UDim2.new(0, 16, 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5),
			Color = T.PaperDark,
			Radius = 12,
		})
		Kit.new("TextLabel", {
			Text = icon,
			BackgroundTransparency = 1,
			TextScaled = true,
			Size = UDim2.fromScale(0.7, 0.7),
			Position = UDim2.fromScale(0.15, 0.15),
			Font = Enum.Font.BuilderSansBold,
			Parent = badge,
		})
		x = 64
	end
	local title = Kit.title(
		titleText,
		{ Parent = header, Size = UDim2.new(1, -x - 60, 1, 0), Position = UDim2.fromOffset(x, 0), TextSize = 26 }
	)
	local close = Kit.button("✕", {
		Size = UDim2.fromOffset(38, 38),
		Position = UDim2.new(1, -50, 0, 10),
		Color = T.Coral,
		TextSize = 18,
		Radius = 19,
		Parent = header,
	})
	Kit.frame({
		Parent = frame,
		Size = UDim2.new(1, -32, 0, 1),
		Position = UDim2.fromOffset(16, 58),
		Color = T.Line,
		Radius = false,
	})
	local body = Kit.box({
		Name = "Body",
		Size = UDim2.new(1, -32, 1, -76),
		Position = UDim2.fromOffset(16, 66),
		Parent = frame,
	})
	local self = { root = holder, card = frame, body = body, close = close, title = title }
	close.Activated:Connect(function()
		if onClose then
			onClose()
		else
			holder.Visible = false
		end
	end)
	return self
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
		ScrollBarThickness = 6,
		ScrollBarImageColor3 = T.InkSoft,
		ScrollBarImageTransparency = 0.5,
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
		BackgroundColor3 = T.White,
		BorderSizePixel = 0,
		ClearTextOnFocus = false,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = p.Size or UDim2.new(1, 0, 0, 40),
		Position = p.Position or UDim2.new(),
		LayoutOrder = p.LayoutOrder or 0,
		Name = p.Name or "TextBox",
		Parent = p.Parent,
	})
	Kit.corner(box, 10)
	Kit.stroke(box, T.Line, 1.5)
	Kit.pad(box, 12, 0)
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
		AlignX = Enum.TextXAlignment.Right,
		Color = T.InkSoft,
	})
	local track = Kit.frame({
		Parent = holder,
		Size = UDim2.new(1, -12, 0, 8),
		Position = UDim2.new(0, 6, 0, 30),
		Color = T.PaperDark,
		Radius = 4,
	})
	local fill = Kit.frame({ Parent = track, Size = UDim2.fromScale(0, 1), Color = T.Blue, Radius = 4 })
	local knob = Kit.frame({
		Parent = track,
		Size = UDim2.fromOffset(20, 20),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0, 0.5),
		Color = T.White,
		Radius = 10,
		Stroke = T.BlueDark,
	})
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
		Position = UDim2.fromOffset(0, 20),
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
-- Entries may carry an `icon`.
function Kit.tabs(
	list: { { id: string, name: string, icon: string? } },
	onSelect: (string) -> (),
	props: { [string]: any }?
): (ScrollingFrame, (string) -> ())
	local p = props or {}
	local bar = Kit.scroll({
		Parent = p.Parent,
		Size = p.Size or UDim2.new(1, 0, 0, 40),
		Axis = Enum.AutomaticSize.X,
		Name = "Tabs",
		LayoutOrder = p.LayoutOrder or 0,
	})
	bar.Position = p.Position or UDim2.new()
	bar.ScrollBarThickness = 3
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
		local label = if t.icon then t.icon .. "  " .. t.name else t.name
		local b = Kit.button(label, {
			Parent = bar,
			Size = UDim2.fromOffset(0, (p.Height or 34)),
			AutomaticSize = Enum.AutomaticSize.X,
			TextSize = p.TextSize or 16,
			Color = T.PaperDark,
			TextColor = T.Ink,
			LayoutOrder = i,
			Radius = 17,
		})
		Kit.pad(b, 14, 0)
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
	Kit.corner(b, math.floor((size or 28) / 2))
	Kit.stroke(b, Color3.new(color.R * 0.7, color.G * 0.7, color.B * 0.7), 1.5)
	if onClick then
		b.Activated:Connect(onClick)
	end
	return b
end

-- Brief pop-in for panels.
function Kit.popIn(frame: GuiObject)
	local s = frame:FindFirstChild("PopScale") or Kit.new("UIScale", { Name = "PopScale", Parent = frame })
	s.Scale = 0.9
	frame.Visible = true
	TweenService:Create(s, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
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
