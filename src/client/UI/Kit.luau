-- The UI toolkit: one theme and the pieces every screen is built from, in the style players know
-- from the big Roblox games: chunky buttons with a darker 3D lip, a glossy top and a thick dark
-- outline; bold rounded Fredoka text with an outline; drawn icons (UI/Icons); dark glass bars
-- over the 3D view; white panels with a coloured header and a red close button on the corner.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

local Icons = require(script.Parent.Icons)

local Kit = {}

Kit.Theme = {
	Paper = Color3.fromRGB(255, 255, 255),
	PaperDark = Color3.fromRGB(228, 236, 248),
	Ink = Color3.fromRGB(38, 32, 52), -- every outline
	InkSoft = Color3.fromRGB(104, 98, 126),
	Line = Color3.fromRGB(206, 214, 230),
	Green = Color3.fromRGB(86, 204, 70),
	GreenDark = Color3.fromRGB(44, 150, 54),
	Coral = Color3.fromRGB(250, 82, 86),
	CoralDark = Color3.fromRGB(196, 46, 60),
	Blue = Color3.fromRGB(52, 152, 255),
	BlueDark = Color3.fromRGB(28, 100, 218),
	Yellow = Color3.fromRGB(255, 202, 46),
	YellowDark = Color3.fromRGB(226, 144, 18),
	Purple = Color3.fromRGB(158, 98, 250),
	Orange = Color3.fromRGB(255, 146, 44),
	Pink = Color3.fromRGB(255, 108, 170),
	Teal = Color3.fromRGB(36, 196, 196),
	White = Color3.fromRGB(255, 255, 255),
	Shadow = Color3.fromRGB(20, 14, 36),
	Glass = Color3.fromRGB(30, 26, 50), -- dark bars over the 3D view
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

function Kit.corner(inst: Instance, radius: number?): UICorner
	return Kit.new("UICorner", { CornerRadius = UDim.new(0, radius or 12), Parent = inst })
end

function Kit.stroke(inst: Instance, color: Color3?, thickness: number?): UIStroke
	return Kit.new("UIStroke", {
		Color = color or T.Line,
		Thickness = thickness or 1.5,
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
	local k = 1 - (strength or 0.14)
	return Kit.new("UIGradient", {
		Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.new(k, k, k)),
		Rotation = 90,
		Parent = inst,
	})
end

local function darker(c: Color3, k: number?): Color3
	local m = k or 0.78
	return Color3.new(c.R * m, c.G * m, c.B * m)
end
Kit.darker = darker

local function isLight(c: Color3): boolean
	return c.R * 0.3 + c.G * 0.59 + c.B * 0.11 > 0.82
end

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
		Kit.corner(f, p.Radius or 12)
	end
	if p.Stroke then
		local color = if typeof(p.Stroke) == "Color3" then p.Stroke else T.Ink
		local s = Kit.stroke(f, color, p.StrokeThickness or (if color == T.Ink then 3 else 1.5))
		s.Transparency = if color == T.Ink then 0 else 0.2
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

-- A dark glass bar or card, the kind HUDs float over the 3D view.
function Kit.glass(props: { [string]: any }?): Frame
	local p = table.clone(props or {})
	p.Color = p.Color or T.Glass
	p.Transparency = p.Transparency or 0.18
	p.Stroke = p.Stroke or T.Ink
	p.StrokeThickness = p.StrokeThickness or 3
	local f = Kit.frame(p)
	local s = f:FindFirstChildOfClass("UIStroke")
	if s then
		s.Transparency = 0
	end
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

local function addSheen(face: GuiObject, radius: number)
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
local function pressable(b: GuiButton)
	local scale = Kit.new("UIScale", { Name = "Press", Parent = b })
	local hovering, pressed = false, false
	local function sink(down: boolean)
		local lip = b:GetAttribute("Lip")
		if type(lip) ~= "number" then
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
local function chunky(b: GuiButton, color: Color3, radius: number, lip: number, outline: number?)
	b.BackgroundColor3 = darker(color, 0.7)
	b:SetAttribute("KitButton", true)
	b:SetAttribute("Lip", lip)
	Kit.corner(b, radius)
	local st = Kit.stroke(b, T.Ink, outline or 2.5)
	st.Name = "Outline"
	local face = Kit.new("Frame", {
		Name = "Face",
		BackgroundColor3 = color,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 1, -lip),
		ZIndex = b.ZIndex,
		Parent = b,
	})
	Kit.corner(face, radius)
	Kit.gradient(face, 0.2)
	local shine = Kit.new("Frame", {
		Name = "Shine",
		BackgroundColor3 = T.White,
		BackgroundTransparency = 0.72,
		BorderSizePixel = 0,
		Size = UDim2.new(1, -radius, 0.36, 0),
		Position = UDim2.new(0, radius / 2, 0, 3),
		ZIndex = b.ZIndex,
		Parent = face,
	})
	Kit.corner(shine, math.max(2, radius - 4))
	addSheen(face, radius)
	return face
end

-- A chunky rounded button. props: Size, Position, AnchorPoint, Color, TextColor, TextSize, Font,
-- Radius, LayoutOrder, Name, ZIndex, AutomaticSize, Icon (an icon name, drawn left of the text).
-- The returned TextButton's Text and TextColor3 can be set as usual; the label follows them.
function Kit.button(text: string, props: { [string]: any }?, onClick: (() -> ())?): TextButton
	local p = props or {}
	local color = p.Color or T.Green
	local size: UDim2 = p.Size or UDim2.fromOffset(140, 46)
	local textSize = p.TextSize or 20
	local lip = if size.Y.Offset > 0 and size.Y.Offset < 34 then 3 else LIP
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
			Icons.make(p.Icon, iconPx, { Parent = content, LayoutOrder = 1, ZIndex = b.ZIndex })
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
	if not isLight(color) or textColor == T.White then
		Kit.outlineText(label, darker(color, 0.42), math.max(1.5, textSize / 9))
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
	if face and face:IsA("Frame") then
		face.BackgroundColor3 = color
		b.BackgroundColor3 = darker(color, 0.7)
	else
		b.BackgroundColor3 = color
	end
	local tc = textColor or T.White
	if b:IsA("TextButton") then
		b.TextColor3 = tc
	end
	local light = isLight(color) and tc ~= T.White
	for _, name in { "Label", "Caption" } do
		local l = b:FindFirstChild(name, true)
		if l and l:IsA("TextLabel") then
			l.TextColor3 = tc
			local o = l:FindFirstChild("TextOutline")
			if light then
				if o then
					o:Destroy()
				end
			else
				Kit.outlineText(l, darker(color, 0.42), math.max(1.5, l.TextSize / 9))
			end
		end
	end
end

-- A square tile with a big icon and a caption under it (docks, tool strips, categories).
-- `icon` is an icon name from UI/Icons (or any text, drawn as is). props: Size, Color, TextSize,
-- TextColor, Radius, LayoutOrder, Position, AnchorPoint, Name, ZIndex.
function Kit.iconButton(icon: string, caption: string?, props: { [string]: any }?, onClick: (() -> ())?): TextButton
	local p = props or {}
	local size: UDim2 = p.Size or UDim2.fromOffset(72, 72)
	local color = p.Color or T.Paper
	local lip = if size.Y.Offset > 0 and size.Y.Offset < 46 then 3 else LIP
	local b = Kit.new("TextButton", {
		Text = "",
		AutoButtonColor = false,
		BorderSizePixel = 0,
		Size = size,
		Position = p.Position or UDim2.new(),
		AnchorPoint = p.AnchorPoint or Vector2.zero,
		LayoutOrder = p.LayoutOrder or 0,
		Name = p.Name or caption or icon,
		ZIndex = p.ZIndex or 1,
		Parent = p.Parent,
	})
	local face = chunky(b, color, p.Radius or 14, lip)
	local hasCaption = caption ~= nil and caption ~= ""
	local w, h = size.X.Offset, size.Y.Offset - lip
	local iconPx = math.floor(math.min(w, h) * (if hasCaption then 0.54 else 0.66))
	local iconY = if hasCaption then math.floor(h * 0.08) else math.floor((h - iconPx) / 2)
	if Icons.has(icon) then
		Icons.make(icon, iconPx, {
			Name = "IconArt",
			Parent = face,
			Position = UDim2.new(0.5, -iconPx / 2, 0, iconY),
			ZIndex = b.ZIndex,
		})
	else
		Kit.new("TextLabel", {
			Name = "Icon",
			Text = icon,
			BackgroundTransparency = 1,
			Font = Enum.Font.BuilderSansBold,
			TextScaled = true,
			Size = UDim2.fromOffset(iconPx, iconPx),
			Position = UDim2.new(0.5, -iconPx / 2, 0, iconY),
			TextColor3 = p.IconColor or T.Ink,
			ZIndex = b.ZIndex,
			Parent = face,
		})
	end
	if hasCaption then
		local textColor = p.TextColor or (if isLight(color) then T.Ink else T.White)
		local cap = Kit.new("TextLabel", {
			Name = "Caption",
			Text = caption,
			BackgroundTransparency = 1,
			Font = Kit.Fonts.Title,
			TextSize = p.TextSize or 14,
			TextWrapped = false,
			Size = UDim2.new(1, 0, 0, (p.TextSize or 14) + 4),
			Position = UDim2.new(0.5, 0, 1, -((p.TextSize or 14) + 4) - math.floor(h * 0.04)),
			AnchorPoint = Vector2.new(0.5, 0),
			TextColor3 = textColor,
			ZIndex = b.ZIndex,
			Parent = face,
		})
		if textColor == T.White then
			Kit.outlineText(cap, darker(color, 0.42), 2)
		end
	end
	pressable(b)
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
		Radius = math.floor(h / 2),
		Stroke = T.Ink,
		StrokeThickness = 2,
	})
	local fill = Kit.frame({
		Name = "Fill",
		Parent = track,
		Size = UDim2.fromScale(math.clamp(ratio, 0, 1), 1),
		Color = color,
		Radius = math.floor(h / 2),
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
		Radius = 12,
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

-- A rounded stat pill: a dark glass bar with a big icon over its left end and the value in white.
-- props: Size, Position, AnchorPoint, LayoutOrder, Name, TextSize, Plus (a function: draws a
-- green + button on the right). Returns the frame and the value label.
function Kit.pill(icon: string, props: { [string]: any }?): (Frame, TextLabel)
	local p = props or {}
	local size: UDim2 = p.Size or UDim2.fromOffset(150, 40)
	local h = size.Y.Offset
	local f = Kit.glass({
		Name = p.Name or "Pill",
		Size = size,
		Position = p.Position,
		AnchorPoint = p.AnchorPoint,
		Radius = math.floor(h / 2),
		Parent = p.Parent,
		LayoutOrder = p.LayoutOrder,
	})
	local iconPx = math.floor(h * 1.12)
	if Icons.has(icon) then
		Icons.make(icon, iconPx, {
			Name = "IconArt",
			Parent = f,
			Position = UDim2.new(0, -math.floor(h * 0.3) + iconPx / 2, 0.5, 0),
			AnchorPoint = Vector2.new(0.5, 0.5),
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
	local left = math.floor(h * 0.86)
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
		Parent = f,
	})
	Kit.outlineText(value, T.Ink, 2)
	if p.Plus then
		Kit.button("", {
			Name = "Plus",
			Parent = f,
			Size = UDim2.fromOffset(h - 8, h - 6),
			Position = UDim2.new(1, -4, 0.5, -1),
			AnchorPoint = Vector2.new(1, 0.5),
			Color = T.Green,
			Radius = 10,
			Icon = "plus",
			TextSize = math.floor(h * 0.4),
		}, p.Plus)
	end
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
		Transparency = 0.7,
		Radius = radius or 18,
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

-- The red close button that sits on a panel's corner.
function Kit.closeButton(props: { [string]: any }, onClick: (() -> ())?): TextButton
	local p = table.clone(props)
	p.Color = T.Coral
	p.Icon = "close"
	p.Radius = p.Radius or 12
	p.TextSize = p.TextSize or 24
	return Kit.button("", p, onClick)
end

-- A modal panel: a white card with a thick outline, a coloured header with an icon and a title,
-- and a red close button on the top right corner. Returns { root, card, body, close, title,
-- header }. `root` holds the card and its shadow, so hiding or destroying it takes both.
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
	Kit.frame({
		Name = "Shadow",
		Size = UDim2.fromScale(1, 1),
		Position = UDim2.fromOffset(0, 8),
		Color = T.Shadow,
		Transparency = 0.6,
		Radius = 20,
		Parent = holder,
	})
	local frame = Kit.frame({
		Name = "Card",
		Size = UDim2.fromScale(1, 1),
		Stroke = T.Ink,
		StrokeThickness = 4,
		Parent = holder,
		Radius = 20,
	})
	local header =
		Kit.frame({ Name = "Header", Size = UDim2.new(1, 0, 0, 60), Color = headColor, Radius = 20, Parent = frame })
	Kit.gradient(header, 0.22)
	-- square off the header's bottom corners
	local filler = Kit.frame({
		Name = "Square",
		Size = UDim2.new(1, 0, 0, 20),
		Position = UDim2.new(0, 0, 1, -20),
		Color = headColor,
		Radius = false,
		Parent = header,
	})
	Kit.new("UIGradient", {
		Color = ColorSequence.new(Color3.new(0.88, 0.88, 0.88), Color3.new(0.78, 0.78, 0.78)),
		Rotation = 90,
		Parent = filler,
	})
	Kit.frame({
		Name = "Rule",
		Size = UDim2.new(1, 0, 0, 3),
		Position = UDim2.new(0, 0, 1, 0),
		Color = T.Ink,
		Radius = false,
		Parent = header,
	})
	local x = 20
	if icon then
		if Icons.has(icon) then
			Icons.make(icon, 46, { Parent = header, Position = UDim2.new(0, 14, 0.5, -24) })
		else
			Kit.new("TextLabel", {
				Text = icon,
				BackgroundTransparency = 1,
				TextScaled = true,
				Size = UDim2.fromOffset(38, 38),
				Position = UDim2.new(0, 16, 0.5, -19),
				Font = Enum.Font.BuilderSansBold,
				Parent = header,
			})
		end
		x = 70
	end
	local title = Kit.title(titleText, {
		Parent = header,
		Size = UDim2.new(1, -x - 70, 1, 0),
		Position = UDim2.fromOffset(x, 0),
		TextSize = 30,
		Color = T.White,
		Outline = darker(headColor, 0.4),
		OutlineThickness = 3,
	})
	local close = Kit.closeButton({
		Size = UDim2.fromOffset(52, 52),
		Position = UDim2.new(1, 14, 0, -14),
		AnchorPoint = Vector2.new(1, 0),
		Parent = frame,
		ZIndex = 3,
	})
	local body = Kit.box({
		Name = "Body",
		Size = UDim2.new(1, -36, 1, -86),
		Position = UDim2.fromOffset(18, 74),
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
	Kit.corner(box, 12)
	Kit.stroke(box, T.Ink, 2.5)
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
		Radius = 12,
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
	Kit.corner(b, math.floor((size or 28) / 2))
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
