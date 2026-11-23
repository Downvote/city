-- The UI toolkit: one theme and the pieces every screen is built from, in a dark, cozy look of
-- our own: dark rounded cards with soft shadows, light words, pastel accents, dark see-through
-- pills over the 3D view, rounded buttons that lift off a soft shadow and press down into it,
-- round icon buttons with a little caption pill, and drawn icons (UI/Icons).
--
-- The user: "Make every ui element dark mode, with a dark background". So every surface is one
-- of the dark shades below and every word on them is light. The token names are from the light
-- look that came before (Paper, Cream), and they stay so the screens need no renaming.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

local Icons = require(script.Parent.Icons)

local Kit = {}

Kit.Theme = {
	-- surfaces, darkest to lightest: a well sinks into a panel, a card stands up off it
	PaperDark = Color3.fromRGB(20, 22, 31), -- wells, tracks, unpicked tabs
	Cream = Color3.fromRGB(29, 31, 42), -- big panels
	Paper = Color3.fromRGB(37, 40, 54), -- cards and buttons, the bars over the 3D view
	Card = Color3.fromRGB(47, 51, 68), -- a row or a tile on a panel
	Picture = Color3.fromRGB(74, 80, 104), -- behind a catalog picture or a face: light enough that dark hair shows
	Line = Color3.fromRGB(66, 71, 93),
	-- words
	Ink = Color3.fromRGB(236, 238, 246), -- words on any of the surfaces above
	InkSoft = Color3.fromRGB(158, 164, 187),
	White = Color3.fromRGB(255, 255, 255), -- words and icons on a coloured button
	Dark = Color3.fromRGB(16, 18, 26), -- outlines round letters, and words on a bright face
	-- accents: the same pastels as before, they carry the colour now
	Green = Color3.fromRGB(128, 198, 118),
	GreenDark = Color3.fromRGB(92, 164, 92),
	Coral = Color3.fromRGB(250, 140, 128),
	CoralDark = Color3.fromRGB(222, 104, 98),
	Blue = Color3.fromRGB(116, 178, 236),
	BlueDark = Color3.fromRGB(84, 146, 210),
	Yellow = Color3.fromRGB(255, 206, 104),
	YellowDark = Color3.fromRGB(240, 170, 70),
	Purple = Color3.fromRGB(186, 156, 232),
	Orange = Color3.fromRGB(255, 172, 108),
	Pink = Color3.fromRGB(250, 156, 186),
	Teal = Color3.fromRGB(110, 204, 188),
	Shadow = Color3.fromRGB(0, 0, 0),
	Glass = Color3.fromRGB(14, 16, 24), -- the dark see-through pills over the 3D view
	GlassAlpha = 0.26,
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

-- Angular shapes ----------------------------------------------------------------------------------------
--
-- The user: "Use the format in zenless zone zero for buttons and details in ui instead of
-- overusing circles and rounded rectangles". So the interface is cut from straight lines: a
-- button, a tab or a row leans (its two ends are slanted, a parallelogram), a panel or a card has
-- two of its corners cut off, a marker is a diamond, and small details are stripes and ticks.
-- Corners that are left are all but square. The idea of leaning, cut shapes is what is taken;
-- the shapes, colours and type are Maplewick's own.
--
-- A slanted edge is drawn without any picture: a box with a UIGradient laid square across its
-- diagonal whose Transparency steps from clear to solid half way, which leaves a right angled
-- triangle (a "wedge"). A wedge at each end of a rectangle makes it lean; a wedge in a corner cuts
-- the corner.

local CORNER = 3 -- what is left of a rounded corner, in pixels
Kit.Lean = 0.3 -- how far a leaning end runs sideways, as a share of the thing's height

-- Corners are all but square: whatever radius is asked for comes out as a few pixels. Only
-- "round" makes a circle of a square (a progress ring's parts, a glow).
function Kit.corner(inst: Instance, radius: any): UICorner
	local r = if radius == "round" then UDim.new(0.5, 0) else UDim.new(0, CORNER)
	return Kit.new("UICorner", { CornerRadius = r, Parent = inst })
end

-- A right angled triangle: half of its box, the half named by `keep` ("br" the bottom right,
-- "tl", "tr", "bl"). props: Parent, Size, Position, AnchorPoint, Color, Transparency, ZIndex, and
-- W and H (its size in pixels, for before the engine has measured it). Its name says which half
-- it is, which the previews read.
function Kit.wedge(props: { [string]: any }, keep: string): Frame
	local f = Kit.new("Frame", {
		Name = "Wedge_" .. keep,
		BackgroundColor3 = props.Color or T.Paper,
		BackgroundTransparency = props.Transparency or 0,
		BorderSizePixel = 0,
		Size = props.Size or UDim2.fromOffset(10, 10),
		Position = props.Position or UDim2.new(),
		AnchorPoint = props.AnchorPoint or Vector2.zero,
		ZIndex = props.ZIndex or 1,
		Parent = props.Parent,
	})
	local cut = Kit.new("UIGradient", { Name = "Cut", Parent = f })
	local function fit()
		local size = f.AbsoluteSize
		local w = if size.X > 0 then size.X else math.max(1, props.W or f.Size.X.Offset)
		local h = if size.Y > 0 then size.Y else math.max(1, props.H or f.Size.Y.Offset)
		-- the gradient runs square across the diagonal that is the cut, so half way along it is
		-- on the cut whatever the box's shape
		local across = math.deg(math.atan2(w, h))
		local low = keep == "tl" or keep == "bl" -- the kept half is where the gradient starts
		cut.Rotation = if keep == "br" or keep == "tl" then across else -across
		-- a step about a pixel wide, so the edge is smooth
		local reach = 2 * w * h / math.sqrt(w * w + h * h)
		local e = math.clamp(0.6 / reach, 0.001, 0.2)
		cut.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, if low then 0 else 1),
			NumberSequenceKeypoint.new(0.5 - e, if low then 0 else 1),
			NumberSequenceKeypoint.new(0.5 + e, if low then 1 else 0),
			NumberSequenceKeypoint.new(1, if low then 1 else 0),
		})
	end
	fit()
	f:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
	return f
end

-- Makes a plain rectangle lean: it is pulled in at both ends and a wedge put on each, so the
-- whole stays inside the box the rectangle had (or with `outside`, the rectangle keeps its box
-- and the wedges stand out past its ends). `height` is its height in pixels when its Size
-- doesn't say. Returns how far each end runs.
function Kit.slant(face: GuiObject, height: number?, outside: boolean?): number
	local h = height or face.Size.Y.Offset
	if h <= 0 then
		h = 40
	end
	local cap = math.clamp(math.floor(h * Kit.Lean + 0.5), 4, 20)
	if not outside then
		face.Position += UDim2.fromOffset(cap, 0)
		face.Size -= UDim2.fromOffset(cap * 2, 0)
		face:SetAttribute("Inset", cap)
	end
	for _, keep in { "br", "tl" } do
		Kit.wedge({
			Parent = face,
			Color = face.BackgroundColor3,
			Transparency = face.BackgroundTransparency,
			Size = UDim2.new(0, cap, 1, 0),
			Position = if keep == "br" then UDim2.fromOffset(-cap, 0) else UDim2.new(1, 0, 0, 0),
			ZIndex = face.ZIndex,
			W = cap,
			H = h,
		}, keep)
	end
	return cap
end

-- Recolours a face and the wedges on it (and whether they show).
function Kit.paint(face: GuiObject, color: Color3?, transparency: number?)
	if color then
		face.BackgroundColor3 = color
	end
	if transparency then
		face.BackgroundTransparency = transparency
	end
	for _, c in face:GetChildren() do
		if c:IsA("Frame") and c.Name:sub(1, 6) == "Wedge_" then
			if color then
				c.BackgroundColor3 = color
			end
			if transparency then
				c.BackgroundTransparency = transparency
			end
		end
	end
end

-- Fills `holder` with a rectangle whose top left and bottom right corners are cut off by `cut`
-- pixels, under everything else in it. Returns the layer (Kit.paintCut recolours it).
function Kit.cutInto(holder: GuiObject, color: Color3, cut: number, z: number?): Frame
	local layer = Kit.new("Frame", {
		Name = "Cut",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		ZIndex = z or 0,
		Parent = holder,
	})
	local function piece(name: string, position: UDim2, size: UDim2)
		Kit.new("Frame", {
			Name = name,
			BackgroundColor3 = color,
			BorderSizePixel = 0,
			Position = position,
			Size = size,
			ZIndex = z or 0,
			Parent = layer,
		})
	end
	piece("Top", UDim2.fromOffset(cut, 0), UDim2.new(1, -cut, 0, cut))
	piece("Mid", UDim2.fromOffset(0, cut), UDim2.new(1, 0, 1, -cut * 2))
	piece("Bot", UDim2.new(0, 0, 1, -cut), UDim2.new(1, -cut, 0, cut))
	Kit.wedge(
		{ Parent = layer, Color = color, Size = UDim2.fromOffset(cut, cut), ZIndex = z or 0, W = cut, H = cut },
		"br"
	)
	Kit.wedge({
		Parent = layer,
		Color = color,
		Size = UDim2.fromOffset(cut, cut),
		Position = UDim2.new(1, -cut, 1, -cut),
		ZIndex = z or 0,
		W = cut,
		H = cut,
	}, "tl")
	return layer
end

function Kit.paintCut(holder: Instance, color: Color3)
	local layer = holder:FindFirstChild("Cut")
	if layer then
		for _, c in layer:GetChildren() do
			if c:IsA("Frame") then
				c.BackgroundColor3 = color
			end
		end
	end
end

-- A small block of slanted stripes: a detail for a panel's corner or beside a title. props:
-- Parent, Size, Position, AnchorPoint, Color, Transparency, ZIndex, Count (up to 5).
function Kit.stripes(props: { [string]: any }): Frame
	local f = Kit.new("Frame", {
		Name = "Stripes",
		BackgroundColor3 = props.Color or T.Yellow,
		BackgroundTransparency = props.Transparency or 0,
		BorderSizePixel = 0,
		Size = props.Size or UDim2.fromOffset(64, 14),
		Position = props.Position or UDim2.new(),
		AnchorPoint = props.AnchorPoint or Vector2.zero,
		ZIndex = props.ZIndex or 1,
		Parent = props.Parent,
	})
	local n: number = math.clamp(props.Count or 5, 1, 5)
	local keys = {}
	for i = 0, n - 1 do
		local a, m, b = i / n, (i + 0.5) / n, (i + 1) / n
		table.insert(keys, NumberSequenceKeypoint.new(a, 0))
		table.insert(keys, NumberSequenceKeypoint.new(m - 0.012, 0))
		table.insert(keys, NumberSequenceKeypoint.new(m, 1))
		table.insert(keys, NumberSequenceKeypoint.new(if i == n - 1 then 1 else b - 0.012, 1))
	end
	Kit.new("UIGradient", {
		Name = "Stripes",
		Rotation = -35,
		Transparency = NumberSequence.new(keys),
		Parent = f,
	})
	return f
end

-- An outline. The user asked for no outlines on rounded rectangles, so these are switched off:
-- the stroke is still made (callers keep and tween it) but never shows. Doodles and icons make
-- their own strokes.
function Kit.stroke(inst: Instance, color: Color3?, thickness: number?): UIStroke
	local ink = color == T.Ink or color == T.Dark
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
	st.Color = color or T.Dark
	st.Thickness = thickness or 2
	st.LineJoinMode = Enum.LineJoinMode.Round
	if label:IsA("GuiObject") and not label:FindFirstChild("TextShadow") then
		Kit.textShadow(label, st.Color)
	end
	return st
end

-- A gentle top-to-bottom shading on a small thing (a slider's fill, a price tag). The user asked
-- for flat buttons and tabs earlier and then for "more life to the uis, such as gradients", so
-- backgrounds, headers, pills and little fills are shaded and buttons and tabs are not.
function Kit.gradient(inst: Instance, strength: number?): UIGradient
	local k = 1 - (strength or 0.14) * 0.7
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

-- Native shadows, shaped gradients and rounded clipping ---------------------------------------------
--
-- The user: "https://create.roblox.com/docs/learn/more/rounded-corners also, reference this doc an
-- implement as much as possible". That write-up is about three things the engine now draws
-- itself, and the kit uses all three:
--   shadows   a UIShadow under a frame follows its corners, size and turn; no picture, no stroke
--   gradients a UIGradient can be Radial or Conical as well as straight, with a Scale
--   clipping  a CanvasGroup with a UICorner cuts its children to the rounded shape
-- Each is made inside a pcall: where an engine doesn't have one yet, that piece is simply left
-- out and the screen is as flat as before.

-- A soft drop shadow under a card, a pill or a button. Two layers, as the write-up builds them:
-- a tight one close under the edge and a wide faint one behind it (its ZIndex is lower, so it
-- draws first). `depth` scales both: about 0.5 for a button, 1 for a card, 2 for a menu.
function Kit.softShadow(gui: GuiObject, depth: number?, color: Color3?): { Instance }
	local d = depth or 1
	local made: { Instance } = {}
	pcall(function()
		local layers = {
			{ name = "ShadowNear", blur = 5, drop = 2, fade = 0.8, spread = 0, z = -1 },
			{ name = "ShadowFar", blur = 22, drop = 9, fade = 0.86, spread = -3, z = -2 },
		}
		for _, layer in layers do
			local s = Instance.new("UIShadow")
			s.Name = layer.name
			s.Color = color or T.Shadow
			s.Transparency = layer.fade
			s.BlurRadius = UDim.new(0, layer.blur * d)
			s.Offset = UDim2.fromOffset(0, layer.drop * d)
			s.Spread = UDim2.fromOffset(layer.spread * d, layer.spread * d)
			-- a see-through pill mustn't show its own shadow through itself
			s.ShowBehindParent = false
			s.ZIndex = layer.z
			s.Parent = gui
			table.insert(made, s)
		end
	end)
	return made
end

-- A glow in a button's own colour, spreading out from under it.
function Kit.glowShadow(gui: GuiObject, color: Color3, size: number?): Instance?
	local made: Instance? = nil
	pcall(function()
		local s = Instance.new("UIShadow")
		s.Name = "Glow"
		s.Color = color
		s.Transparency = 0.5
		s.BlurRadius = UDim.new(0, size or 18)
		s.Offset = UDim2.fromOffset(0, 4)
		s.Spread = UDim2.fromOffset(2, 2)
		s.ShowBehindParent = false
		s.ZIndex = -3
		s.Parent = gui
		made = s
	end)
	return made
end

-- A soft shadow under the letters themselves, for words drawn straight over the town.
function Kit.textShadow(label: GuiObject, color: Color3?): Instance?
	local made: Instance? = nil
	pcall(function()
		local s = Instance.new("UIShadow")
		s.Name = "TextShadow"
		s.Mode = Enum.ApplyShadowMode.Text
		s.Color = color or T.Shadow
		s.Transparency = 0.5
		s.BlurRadius = UDim.new(0, 3)
		s.Offset = UDim2.fromOffset(0, 2)
		s.Parent = label
		made = s
	end)
	return made
end

-- A gradient of one of the shaped kinds ("Radial", "Conical", "Elliptical"), or nil where the
-- engine only draws straight ones (a straight one in its place would shade the wrong way).
local function shapedGradient(inst: Instance, kind: string, scale: number?): UIGradient?
	local g = Instance.new("UIGradient")
	local ok = pcall(function()
		g.Type = (Enum.GradientType :: any)[kind]
		if scale then
			g.Scale = scale
		end
	end)
	if not ok then
		g:Destroy()
		return nil
	end
	g.Parent = inst
	return g
end
Kit.shapedGradient = shapedGradient

-- Life in the backgrounds ------------------------------------------------------------------------------
--
-- The user: "add more life to the uis, such as gradients and simple shapes dotting the
-- background". So a card or a header is washed from one colour into another, and little shapes
-- (dots, rings, plus signs, diamonds, short dashes) are scattered faintly behind what's on it.

local function mix(a: Color3, b: Color3, t: number): Color3
	return a:Lerp(b, t)
end
Kit.mix = mix

-- An accent sunk most of the way into the dark panel colour: what a header bar or a title
-- ribbon is drawn in, so those are dark too and only tinted with their colour.
function Kit.deep(color: Color3): Color3
	return color:Lerp(T.Cream, 0.58)
end

-- Washes a frame from colour `a` into colour `b` (left to right, or along `rotation` degrees).
function Kit.wash(inst: GuiObject, a: Color3, b: Color3, rotation: number?): UIGradient
	inst.BackgroundColor3 = Color3.new(1, 1, 1)
	local old = inst:FindFirstChild("Wash")
	if old then
		old:Destroy()
	end
	return Kit.new("UIGradient", {
		Name = "Wash",
		Color = ColorSequence.new(a, b),
		Rotation = rotation or 0,
		Parent = inst,
	})
end

-- Scatters simple shapes faintly over `parent`'s background, under everything else on it.
-- opts: Transparency (how faint, 0.86 by default), Area ({ x1, y1, x2, y2 } as shares of the
-- parent, to keep them clear of a header or the edges), Size (a scale for the shapes).
function Kit.shapes(parent: GuiObject, color: Color3, seed: number, count: number?, opts: { [string]: any }?): Frame
	local o = opts or {}
	local rng = Random.new(seed)
	local area = o.Area or { 0.04, 0.06, 0.96, 0.94 }
	local faint = o.Transparency or 0.86
	local scale = o.Size or 1
	local layer = Kit.new("Frame", {
		Name = "Shapes",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 0,
		Parent = parent,
	})
	local function piece(holder: Instance, w: number, h: number, rot: number, round: boolean): Frame
		local f = Kit.new("Frame", {
			BackgroundColor3 = color,
			BackgroundTransparency = faint,
			BorderSizePixel = 0,
			Size = UDim2.fromOffset(w, h),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Rotation = rot,
			ZIndex = 0,
			Parent = holder,
		})
		Kit.new("UICorner", { CornerRadius = if round then UDim.new(0.5, 0) else UDim.new(0, 3), Parent = f })
		return f
	end
	local kinds = { "dot", "ring", "plus", "diamond", "dash", "dot", "ring" }
	for k = 1, count or 14 do
		local kind = kinds[(k - 1) % #kinds + 1]
		local size = math.floor(rng:NextNumber(9, 20) * scale)
		local holder = Kit.new("Frame", {
			Name = kind,
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(size, size),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(rng:NextNumber(area[1], area[3]), rng:NextNumber(area[2], area[4])),
			ZIndex = 0,
			Parent = layer,
		})
		if kind == "dot" then
			piece(holder, size * 0.7, size * 0.7, 0, true)
		elseif kind == "ring" then
			local ring = piece(holder, size, size, 0, true)
			ring.BackgroundTransparency = 1
			Kit.new("UIStroke", {
				Color = color,
				Transparency = faint,
				Thickness = math.max(2, size / 6),
				Parent = ring,
			})
		elseif kind == "plus" then
			local turn = rng:NextInteger(0, 40)
			piece(holder, size, size * 0.28, turn, true)
			piece(holder, size, size * 0.28, turn + 90, true)
		elseif kind == "diamond" then
			piece(holder, size * 0.62, size * 0.62, 45, false)
		else
			piece(holder, size * 1.2, size * 0.32, rng:NextInteger(-50, 50), true)
		end
	end
	return layer
end

-- Dims a backdrop like a vignette: lighter behind the middle of the screen, where the menu sits,
-- and darker toward the edges. `middle` and `edge` are transparencies. `scale` shrinks the
-- gradient when the backdrop is much bigger than the screen.
function Kit.vignette(backdrop: GuiObject, middle: number, edge: number, scale: number?)
	local g = shapedGradient(backdrop, "Radial", scale)
	if g then
		backdrop.BackgroundTransparency = 0
		g.Transparency = NumberSequence.new(middle, edge)
	end
end

-- A soft round glow, brightest in the middle and gone at its rim, to sit behind something worth
-- noticing. It goes into `parent` under everything else there (ZIndex 0). Nil without radial
-- gradients.
function Kit.halo(parent: GuiObject, size: number, color: Color3, strength: number?): Frame?
	local f = Kit.new("Frame", {
		Name = "Halo",
		BackgroundColor3 = color,
		BorderSizePixel = 0,
		Size = UDim2.fromOffset(size, size),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		ZIndex = 0,
		Parent = parent,
	})
	Kit.new("UICorner", { CornerRadius = UDim.new(0.5, 0), Parent = f })
	local g = shapedGradient(f, "Radial")
	if not g then
		f:Destroy()
		return nil
	end
	local k = 1 - (strength or 0.5)
	g.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, k),
		NumberSequenceKeypoint.new(0.55, k + (1 - k) * 0.6),
		NumberSequenceKeypoint.new(1, 1),
	})
	return f
end

-- A progress ring: `ratio` of the way round, clockwise from the top, drawn with a conical
-- gradient. props: Parent, Size (pixels across), Position, AnchorPoint, LayoutOrder, Name,
-- Thickness, Track (the empty ring's colour), Hole (the colour inside, false for none).
-- Returns the holder, the middle (put a number or an icon in it) and a function to set it.
function Kit.ring(props: { [string]: any }, ratio: number, color: Color3): (Frame, Frame, (number) -> ())
	local size: number = props.Size or 44
	local thick: number = props.Thickness or math.max(4, math.floor(size / 8))
	local holder = Kit.new("Frame", {
		Name = props.Name or "Ring",
		BackgroundColor3 = props.Track or T.PaperDark,
		BorderSizePixel = 0,
		Size = UDim2.fromOffset(size, size),
		Position = props.Position or UDim2.new(),
		AnchorPoint = props.AnchorPoint or Vector2.zero,
		LayoutOrder = props.LayoutOrder or 0,
		Parent = props.Parent,
	})
	Kit.new("UICorner", { CornerRadius = UDim.new(0.5, 0), Parent = holder })
	local sweep = Kit.new("Frame", {
		Name = "Sweep",
		BackgroundColor3 = color,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		Parent = holder,
	})
	Kit.new("UICorner", { CornerRadius = UDim.new(0.5, 0), Parent = sweep })
	local g = shapedGradient(sweep, "Conical")
	if g then
		g.Rotation = -90 -- start at the top
	end
	local middle = Kit.new("Frame", {
		Name = "Middle",
		BackgroundColor3 = if props.Hole == nil or props.Hole == false then T.Paper else props.Hole,
		BackgroundTransparency = if props.Hole == false then 1 else 0,
		BorderSizePixel = 0,
		Size = UDim2.new(1, -2 * thick, 1, -2 * thick),
		Position = UDim2.fromOffset(thick, thick),
		ZIndex = 2,
		Parent = holder,
	})
	Kit.new("UICorner", { CornerRadius = UDim.new(0.5, 0), Parent = middle })
	local function set(r: number)
		local v = math.clamp(r, 0, 1)
		holder:SetAttribute("Ratio", v)
		if not g then
			-- no conical gradients here: the ring only fills once it's complete
			sweep.Visible = v >= 1
		elseif v <= 0.002 then
			sweep.Visible = false
		elseif v >= 0.998 then
			sweep.Visible = true
			g.Transparency = NumberSequence.new(0)
		else
			sweep.Visible = true
			g.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0),
				NumberSequenceKeypoint.new(v, 0),
				NumberSequenceKeypoint.new(math.min(v + 0.001, 1), 1),
				NumberSequenceKeypoint.new(1, 1),
			})
		end
	end
	set(ratio)
	return holder, middle, set
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
				-- a leaning face stays pulled in by its slanted ends
				local inset = f:GetAttribute("Inset")
				local k: number = if type(inset) == "number" then inset else 0
				f.Position = UDim2.fromOffset(-px + k, -y)
				f.Size = UDim2.new(1, px * 2 - k * 2, 1, y * 2 - lip)
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
	-- a frame that clips and has round corners is a CanvasGroup: with a UICorner it cuts its
	-- children to the rounded shape, where a plain frame only clips to its box
	local class = if p.Clips and p.Radius ~= false then "CanvasGroup" else "Frame"
	local f = Kit.new(class, {
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
	if p.Cut then
		-- two corners cut off: the frame itself is clear and the shape is laid under what is in it
		f.BackgroundTransparency = 1
		Kit.cutInto(f, p.Color or T.Paper, p.Cut)
	elseif p.Radius ~= false then
		Kit.corner(f, p.Radius or 14)
	end
	if p.Stroke then
		-- outlines are light in this look: a thin line, softer than the text
		local color = if typeof(p.Stroke) == "Color3" then p.Stroke else T.Line
		local s = Kit.stroke(f, color, math.min(p.StrokeThickness or 2, 2.5))
		s.Transparency = if color == T.Ink or color == T.Dark then 0.55 else 0
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

-- A dark rounded card that floats over the 3D view (Build mode's bars, the creator's tools).
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
		Radius = p.Radius or 20,
	})
	Kit.softShadow(f, 1)
	if p.Color == nil then
		-- a touch lighter at the top
		Kit.wash(f, mix(T.Paper, T.White, 0.06), T.Paper, 90)
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
		Kit.outlineText(label, if typeof(p.Outline) == "Color3" then p.Outline else T.Dark, p.OutlineThickness)
	end
	return label
end

-- A heading in the game's rounded display font. White titles get a dark outline.
function Kit.title(text: string, props: { [string]: any }?): TextLabel
	local p = table.clone(props or {})
	p.Font = Kit.Fonts.Title
	p.TextSize = p.TextSize or 26
	if p.Outline == nil and p.Color == T.White then
		p.Outline = T.Dark
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
			local sway = 0 -- nothing sways on its own any more; buttons still wiggle under the pointer
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
	local _ = radius
	-- a button leans: its ends are slanted
	Kit.slant(face, b.Size.Y.Offset - lip)
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
			Kit.recolorIcon(art, if light then T.Dark else T.White, color)
		end
	elseif face and face:IsA("Frame") then
		Kit.paint(face, color)
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
	-- an icon beside the words takes their colour
	local content = b:FindFirstChild("Content")
	if content then
		for _, c in content:GetChildren() do
			if c:GetAttribute("Glyph") ~= nil then
				Kit.recolorIcon(c, tc, color)
			end
		end
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
		-- one colour: white on a dark or coloured button, dark on a bright one, details cut out in the face's colour
		local light = color.R * 0.3 + color.G * 0.59 + color.B * 0.11 > 0.86
		Icons.make(icon, iconPx, {
			Name = "IconArt",
			Parent = face,
			Position = UDim2.new(0.5, -iconPx / 2, 0.5, -iconPx / 2),
			ZIndex = z + 1,
			Color = p.IconColor or (if light then T.Dark else T.White),
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
		-- rounded clipping: the track cuts the fill to its own round ends, so a nearly empty
		-- bar is a sliver of the pill and not a squashed dot
		Clips = true,
	})
	local _ = h
	local fill = Kit.frame({
		Name = "Fill",
		Parent = track,
		Size = UDim2.fromScale(math.clamp(ratio, 0, 1), 1),
		Color = color,
		Radius = false,
	})
	return track, fill
end

-- A red diamond on a button's corner, for something waiting to be seen. The user: "Remove the ! In
-- the alert, just the red dot is enough. Make the red dot pulse slowly". So no mark, no number
-- and no rim.
function Kit.badge(parent: GuiObject): Frame
	local f = Kit.frame({
		Name = "Badge",
		Parent = parent,
		Size = UDim2.fromOffset(14, 14),
		Position = UDim2.new(1, -8, 0, 6),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Color = Color3.fromRGB(240, 72, 78), -- redder than the coral buttons, so it shows on the gift
		Radius = 2,
		ZIndex = (parent.ZIndex or 1) + 5,
	})
	f.Rotation = 45 -- a diamond
	-- a slow pulse about its middle: it swells and settles, a couple of seconds a beat
	local pulse = Kit.new("UIScale", { Name = "Pulse", Parent = f })
	TweenService
		:Create(pulse, TweenInfo.new(1.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Scale = 1.3 })
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
		Radius = false,
	})
	-- a leaning slab: its slanted ends stand out past the box, so what is in it keeps its room
	local h = if p.Size then (p.Size :: UDim2).Y.Offset else 40
	Kit.slant(f, h, true)
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

-- The round close button that sits on a panel's corner: a dark disc with a white cross.
function Kit.closeButton(props: { [string]: any }, onClick: (() -> ())?): TextButton
	local p = table.clone(props)
	p.Color = T.Card
	p.TextSize = nil
	return Kit.iconButton("close", nil, p, onClick)
end

-- Draws flat pieces with one shared outline: every piece's dark copy (grown by the outline)
-- first, then every fill, so no outline crosses another piece. Pieces, in pixels:
--   { "rect", x, y, w, h, colour }    { "tri", x, y, base, dir, colour } (dir up/down/left/right;
--   its height is half the base)
local function pieces(parent: GuiObject, list: { any }, thick: number, z: number)
	local function draw(piece: any, ink: boolean)
		local color = if ink then T.Dark else piece[6]
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
	local color: Color3 = Kit.deep(p.Color or T.Green)
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
	-- a title's band leans
	Kit.slant(band, h)
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
-- bars turned 60 degrees apart in the dark surface colour, on one a little bigger in the accent
-- (its rim). props: Parent, Position, Size (px),
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
	-- a soft glow behind the badge (a radial gradient), so the town's level catches the eye
	Kit.halo(holder, math.floor(px * 1.7), p.Glow or T.Yellow, 0.5)
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
	hex(p.Color or T.Blue, px)
	hex(T.Paper, px - 10)
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
		Hole = T.Paper,
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
	Kit.blob({
		Name = "Face",
		Parent = b,
		Size = UDim2.fromScale(1, 1),
		Color = color,
		Slant = size.Y.Offset,
		Estimate = Vector2.new(size.X.Offset, size.Y.Offset),
	})
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

-- Menus ----------------------------------------------------------------------------------------------
--
-- The user showed another game's menus as the direction ("Other menus should also have a style
-- like this"): a menu takes the whole screen over a black backdrop, the way out is a button at
-- the top left, its sections are tabs at the top right with the picked one in yellow, and what
-- is in it sits in one big rounded panel, as rows shaped like pills. Those are the layout and
-- the parts, and they are what is taken; the drawing is Maplewick's own (its font, its colours,
-- its plain rounded shapes), with none of that game's art, slanted tabs or patterns.

-- The rim round a panel, a row or a tab bar: the same shape a few pixels bigger in another
-- shade behind it, so the thing sits in a bezel. (A second shape, not a stroke.)
local RIM = 3

local function rimColor(): Color3
	return mix(T.PaperDark, T.Line, 0.6)
end

-- A row for lists: a leaning slab in a rim. props: Parent, Size, LayoutOrder, Name, Title, Sub (a
-- smaller line under the title), Marker (an icon name: a diamond badge at the left end),
-- MarkerColor, Right (words at the right end), Selected, Sunk (a row that is over and done
-- with), Height, LeftSpace and RightSpace (room kept clear of the words at either end, for
-- something of your own). With onClick it is a button. Returns the row and the box inside it
-- (put more in it: it fills the row).
function Kit.row(props: { [string]: any }, onClick: (() -> ())?): (GuiObject, Frame)
	local p = props
	local h: number = p.Height or 58
	local row: GuiObject = Kit.new(if onClick then "TextButton" else "Frame", {
		Name = p.Name or "Row",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = p.Size or UDim2.new(1, 0, 0, h),
		LayoutOrder = p.LayoutOrder or 0,
		Parent = p.Parent,
	})
	if row:IsA("TextButton") then
		row.Text = ""
		row.AutoButtonColor = false
	end
	local rim = Kit.new("Frame", {
		Name = "Rim",
		BackgroundColor3 = rimColor(),
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		Parent = row,
	})
	local lean = Kit.slant(rim, h)
	local face = Kit.new("Frame", {
		Name = "Fill",
		BackgroundColor3 = T.PaperDark,
		BorderSizePixel = 0,
		Size = UDim2.new(1, -RIM * 2 - 4, 1, -RIM * 2),
		Position = UDim2.fromOffset(RIM + 2, RIM),
		Parent = row,
	})
	Kit.slant(face, h - RIM * 2)
	local inner = Kit.new("Frame", {
		Name = "Inside",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 2,
		Parent = row,
	})
	local left = lean + 16
	if p.Marker then
		-- a diamond badge with the icon upright on it
		local d = h - 22
		local side = math.floor(d * 0.72)
		local badge = Kit.new("Frame", {
			Name = "Marker",
			BackgroundColor3 = p.MarkerColor or T.Yellow,
			BorderSizePixel = 0,
			Rotation = 45,
			Size = UDim2.fromOffset(side, side),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0, lean + 8 + d / 2, 0.5, 0),
			ZIndex = 2,
			Parent = inner,
		})
		Kit.corner(badge, 2)
		if Icons.has(p.Marker) then
			local ipx = math.floor(d * 0.56)
			Icons.make(p.Marker, ipx, {
				Name = "IconArt",
				Parent = inner,
				Position = UDim2.new(0, lean + 8 + d / 2 - ipx / 2, 0.5, -ipx / 2),
				Color = T.Dark,
				Hole = p.MarkerColor or T.Yellow,
				ZIndex = 3,
			})
		end
		left = lean + d + 22
	end
	if p.LeftSpace then
		left = p.LeftSpace + lean
	end
	local right = (if p.Right then 150 else 16) + lean
	if p.RightSpace then
		right = p.RightSpace + lean
	end
	if p.Title then
		Kit.new("TextLabel", {
			Name = "Title",
			Text = p.Title,
			BackgroundTransparency = 1,
			Font = Kit.Fonts.Title,
			TextSize = p.TextSize or 19,
			TextColor3 = if p.Sunk then T.InkSoft else T.Ink,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Size = UDim2.new(1, -left - right, 0, 24),
			Position = if p.Sub then UDim2.new(0, left, 0.5, -22) else UDim2.new(0, left, 0.5, -12),
			ZIndex = 2,
			Parent = inner,
		})
	end
	if p.Sub then
		Kit.new("TextLabel", {
			Name = "Sub",
			Text = p.Sub,
			BackgroundTransparency = 1,
			Font = Kit.Fonts.Body,
			TextSize = 14,
			TextColor3 = T.InkSoft,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Size = UDim2.new(1, -left - right, 0, 18),
			Position = UDim2.new(0, left, 0.5, 2),
			ZIndex = 2,
			Parent = inner,
		})
	end
	if p.Right then
		Kit.new("TextLabel", {
			Name = "Right",
			Text = p.Right,
			BackgroundTransparency = 1,
			Font = Kit.Fonts.Title,
			TextSize = 16,
			TextColor3 = p.RightColor or T.InkSoft,
			TextXAlignment = Enum.TextXAlignment.Right,
			Size = UDim2.new(0, 130, 1, 0),
			Position = UDim2.new(1, -(134 + lean + 12), 0, 0),
			ZIndex = 2,
			Parent = inner,
		})
	end
	row:SetAttribute("Lean", lean)
	if p.Selected then
		Kit.setRowSelected(row, true)
	end
	if onClick and row:IsA("TextButton") then
		row.Activated:Connect(onClick)
		local scale = Kit.new("UIScale", { Parent = row })
		row.MouseEnter:Connect(function()
			TweenService:Create(scale, TweenInfo.new(0.12), { Scale = 1.02 }):Play()
		end)
		row.MouseLeave:Connect(function()
			TweenService:Create(scale, TweenInfo.new(0.12), { Scale = 1 }):Play()
		end)
	end
	return row, inner
end

-- The picked row of a list is yellow, with dark words (and the others go back to dark).
function Kit.setRowSelected(row: GuiObject, on: boolean)
	local face = row:FindFirstChild("Fill")
	if face and face:IsA("Frame") then
		Kit.paint(face, if on then T.Yellow else T.PaperDark)
	end
	local rim = row:FindFirstChild("Rim")
	if rim and rim:IsA("Frame") then
		Kit.paint(rim, if on then mix(T.Yellow, T.White, 0.45) else rimColor())
	end
	row:SetAttribute("Selected", on)
	for _, d in row:GetDescendants() do
		if d:IsA("TextLabel") and (d.Name == "Title" or d.Name == "Sub" or d.Name == "Right") then
			if d:GetAttribute("Plain") == nil then
				d:SetAttribute("Plain", d.TextColor3:ToHex())
			end
			d.TextColor3 = if on then T.Dark else Color3.fromHex(d:GetAttribute("Plain") :: string)
		end
	end
end

-- Tabs in one leaning bar: the picked one a yellow slab with dark words. `list` is
-- { { id, name } }; onSelect(id) when one is picked. props: Parent, Position, AnchorPoint,
-- Height, TextSize. Returns the bar and select(id).
function Kit.segments(
	list: { { id: string, name: string } },
	onSelect: (string) -> (),
	props: { [string]: any }?
): (Frame, (string) -> ())
	local p = props or {}
	local h: number = p.Height or 46
	local bar = Kit.new("Frame", {
		Name = "Tabs",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.fromOffset(0, h),
		AutomaticSize = Enum.AutomaticSize.X,
		Position = p.Position or UDim2.new(),
		AnchorPoint = p.AnchorPoint or Vector2.zero,
		LayoutOrder = p.LayoutOrder or 0,
		Parent = p.Parent,
	})
	local rim = Kit.new("Frame", {
		Name = "Rim",
		BackgroundColor3 = rimColor(),
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		Parent = bar,
	})
	local lean = Kit.slant(rim, h)
	local well = Kit.new("Frame", {
		Name = "Well",
		BackgroundColor3 = T.PaperDark,
		BorderSizePixel = 0,
		Size = UDim2.new(1, -RIM * 2 - 4, 1, -RIM * 2),
		Position = UDim2.fromOffset(RIM + 2, RIM),
		Parent = bar,
	})
	Kit.slant(well, h - RIM * 2)
	local holder = Kit.new("Frame", {
		Name = "Row",
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(0, h),
		AutomaticSize = Enum.AutomaticSize.X,
		ZIndex = 2,
		Parent = bar,
	})
	Kit.new("UIPadding", {
		PaddingLeft = UDim.new(0, RIM + 3),
		PaddingRight = UDim.new(0, RIM + 3),
		PaddingTop = UDim.new(0, RIM + 1),
		PaddingBottom = UDim.new(0, RIM + 1),
		Parent = holder,
	})
	-- the tabs sit a little into each other, so their slanted ends run side by side
	Kit.list(holder, -lean + 3, true)
	local buttons: { [string]: TextButton } = {}
	local faces: { [string]: Frame } = {}
	local labels: { [string]: TextLabel } = {}
	local function select(id: string)
		for bid, b in buttons do
			local on = bid == id
			Kit.paint(faces[bid], nil, if on then 0 else 1)
			labels[bid].TextColor3 = if on then T.Dark else T.Ink
			b:SetAttribute("Selected", on)
		end
	end
	local th = h - RIM * 2 - 2
	for i, t in list do
		local b = Kit.new("TextButton", {
			Name = t.name,
			Text = "",
			AutoButtonColor = false,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Size = UDim2.fromOffset(0, th),
			AutomaticSize = Enum.AutomaticSize.X,
			LayoutOrder = i,
			ZIndex = 2,
			Parent = holder,
		})
		Kit.new("UIPadding", { PaddingLeft = UDim.new(0, 24), PaddingRight = UDim.new(0, 24), Parent = b })
		labels[t.id] = Kit.new("TextLabel", {
			Name = "Label",
			Text = t.name,
			Font = Kit.Fonts.Title,
			TextSize = p.TextSize or 18,
			TextColor3 = T.Ink,
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(0, th),
			AutomaticSize = Enum.AutomaticSize.X,
			ZIndex = 4,
			Parent = b,
		})
		-- the yellow slab behind the picked tab's words (it reaches back over the padding)
		local face = Kit.new("Frame", {
			Name = "Face",
			BackgroundColor3 = T.Yellow,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 48, 1, 0),
			Position = UDim2.fromOffset(-24, 0),
			ZIndex = 3,
			Parent = b,
		})
		Kit.slant(face, th)
		buttons[t.id] = b
		faces[t.id] = face
		b.Activated:Connect(function()
			select(t.id)
			onSelect(t.id)
		end)
	end
	if list[1] then
		select(list[1].id)
	end
	return bar, select
end

-- A tile: an icon over its name on a small leaning slab (a category, a tool). props: Parent,
-- Size, LayoutOrder, Name, Color, TextColor, TextSize. Kit.setButtonColor recolours it.
function Kit.tile(icon: string, caption: string, props: { [string]: any }?, onClick: (() -> ())?): TextButton
	local p = props or {}
	local size: UDim2 = p.Size or UDim2.fromOffset(84, 68)
	local color: Color3 = p.Color or T.Card
	local textColor: Color3 = p.TextColor or T.Ink
	local b = Kit.new("TextButton", {
		Name = p.Name or caption,
		Text = "",
		AutoButtonColor = false,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = size,
		LayoutOrder = p.LayoutOrder or 0,
		Parent = p.Parent,
	})
	b:SetAttribute("KitButton", true)
	b:SetAttribute("Lip", 0)
	local face = Kit.new("Frame", {
		Name = "Face",
		BackgroundColor3 = color,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		Parent = b,
	})
	-- a slight lean, so tiles in a row sit side by side like tabs
	Kit.slant(face, 26)
	local content = Kit.new("Frame", {
		Name = "Content",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 2,
		Parent = b,
	})
	local h = size.Y.Offset
	local ipx = math.floor(h * 0.42)
	if Icons.has(icon) then
		Icons.make(icon, ipx, {
			Name = "IconArt",
			Parent = content,
			Position = UDim2.new(0.5, -ipx / 2, 0, math.floor(h * 0.12)),
			Color = textColor,
			Hole = color,
			ZIndex = 2,
		})
	end
	Kit.new("TextLabel", {
		Name = "Label",
		Text = caption,
		BackgroundTransparency = 1,
		Font = Kit.Fonts.Title,
		TextSize = p.TextSize or 13,
		TextColor3 = textColor,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Size = UDim2.new(1, -12, 0, 18),
		Position = UDim2.new(0, 6, 1, -22),
		ZIndex = 2,
		Parent = b,
	})
	pressable(b)
	if onClick then
		b.Activated:Connect(onClick)
	end
	return b
end

-- The way back out of a menu: a leaning slab with an arrow, in a coral rim. props: Parent,
-- Position, AnchorPoint, ZIndex.
function Kit.backButton(props: { [string]: any }, onClick: (() -> ())?): TextButton
	local z: number = props.ZIndex or 2
	local b = Kit.new("TextButton", {
		Name = "Close",
		Text = "",
		AutoButtonColor = false,
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(84, 46),
		Position = props.Position or UDim2.new(),
		AnchorPoint = props.AnchorPoint or Vector2.zero,
		ZIndex = z,
		Parent = props.Parent,
	})
	local rim = Kit.new("Frame", {
		Name = "Rim",
		BackgroundColor3 = T.Coral,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		ZIndex = z,
		Parent = b,
	})
	Kit.slant(rim, 46)
	local face = Kit.new("Frame", {
		Name = "Fill",
		BackgroundColor3 = T.PaperDark,
		BorderSizePixel = 0,
		Size = UDim2.new(1, -RIM * 2 - 4, 1, -RIM * 2),
		Position = UDim2.fromOffset(RIM + 2, RIM),
		ZIndex = z,
		Parent = b,
	})
	Kit.slant(face, 46 - RIM * 2)
	Icons.make("back", 26, {
		Name = "IconArt",
		Parent = b,
		Position = UDim2.new(0.5, -13, 0.5, -13),
		Color = T.Coral,
		Hole = T.PaperDark,
		ZIndex = z + 1,
	})
	b:SetAttribute("KitButton", true)
	pressable(b)
	if onClick then
		b.Activated:Connect(onClick)
	end
	return b
end

-- Shapes drifting slowly across the black behind a menu. The user: "make an animated
-- background with shapes like it in the menus". Leaning bars, triangles, hollow diamonds, plus
-- signs and rows of ticks, faint, in the menu's colour and white, all sliding the same way at
-- their own speeds and coming round again. One loop moves them, and it stops when the menu goes.
function Kit.motion(parent: GuiObject, accent: Color3, seed: number): Frame
	local W, H = 2600, 1500
	local layer = Kit.new("Frame", {
		Name = "Motion",
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(W, H),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		ZIndex = 0,
		Parent = parent,
	})
	local rng = Random.new(seed)
	type Mover = { gui: GuiObject, x: number, y: number, speed: number, spin: number }
	local movers: { Mover } = {}
	local function block(holder: Instance, w: number, h: number, rot: number, color: Color3, faint: number): Frame
		return Kit.new("Frame", {
			BackgroundColor3 = color,
			BackgroundTransparency = faint,
			BorderSizePixel = 0,
			Size = UDim2.fromOffset(w, h),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Rotation = rot,
			ZIndex = 0,
			Parent = holder,
		})
	end
	local kinds = { "bar", "tri", "diamond", "bar", "plus", "ticks", "tri", "bar", "diamond" }
	for k = 1, 30 do
		local kind = kinds[(k - 1) % #kinds + 1]
		local color = if k % 3 == 0 then T.White else accent
		local faint = rng:NextNumber(0.86, 0.94)
		local size = rng:NextNumber(34, 96)
		local holder = Kit.new("Frame", {
			Name = kind,
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(size, size),
			AnchorPoint = Vector2.new(0.5, 0.5),
			ZIndex = 0,
			Parent = layer,
		})
		local spin = 0
		if kind == "bar" then
			block(holder, size * 2.6, math.max(6, size * 0.16), -24, color, faint)
		elseif kind == "tri" then
			Kit.wedge({
				Parent = holder,
				Color = color,
				Transparency = faint,
				Size = UDim2.fromScale(1, 1),
				ZIndex = 0,
				W = size,
				H = size,
			}, if k % 2 == 0 then "br" else "tl")
		elseif kind == "diamond" then
			local d = block(holder, size * 0.7, size * 0.7, 45, color, 1)
			Kit.new("UIStroke", { Color = color, Transparency = faint, Thickness = math.max(3, size / 14), Parent = d })
			spin = rng:NextNumber(-10, 10)
		elseif kind == "plus" then
			block(holder, size, size * 0.2, 0, color, faint)
			block(holder, size * 0.2, size, 0, color, faint)
			spin = rng:NextNumber(-14, 14)
		else
			for t = 0, 3 do
				local tick = block(holder, size * 0.14, size * 0.5, 24, color, faint)
				tick.Position = UDim2.new(0.2 + t * 0.2, 0, 0.5, 0)
			end
		end
		table.insert(movers, {
			gui = holder,
			x = rng:NextNumber(0, W),
			y = rng:NextNumber(0, H),
			speed = rng:NextNumber(10, 34),
			spin = spin,
		})
	end
	-- everything slides up and to the right, and comes back in at the far edge
	local dx, dy = 0.91, -0.41
	local function place(dt: number)
		for _, m in movers do
			m.x = (m.x + dx * m.speed * dt) % W
			m.y = (m.y + dy * m.speed * dt) % H
			m.gui.Position = UDim2.fromOffset(m.x, m.y)
			if m.spin ~= 0 then
				m.gui.Rotation += m.spin * dt
			end
		end
	end
	place(0)
	local beat = RunService.Heartbeat:Connect(place)
	layer.Destroying:Connect(function()
		beat:Disconnect()
	end)
	return layer
end

-- The size every full menu's panel is, so they all sit in the same place.
Kit.MenuSize = UDim2.fromOffset(1180, 580)

-- A menu. Two kinds:
--   a full menu (the default) takes the screen: a black backdrop with shapes drifting across
--     it, a back button and the title across the top left, tabs at the top right (opts.Tabs,
--     opts.OnTab), and the panel under them
--   a dialog (opts.Dialog) is a small panel in the middle with its title inside and a close
--     button, over a lighter dim: a question, a welcome
-- The panel has its top left and bottom right corners cut off, and sits in a rim. `color` is
-- the menu's own colour: the drifting shapes, the stripes and the mark beside the title.
-- Returns { root, card, body, close, title, header, selectTab }. `root` holds everything, so
-- hiding or destroying it takes the lot.
function Kit.panel(
	titleText: string,
	size: UDim2,
	onClose: (() -> ())?,
	icon: string?,
	color: Color3?,
	opts: { [string]: any }?
): any
	local gui = Kit.root()
	local o: { [string]: any } = opts or {}
	local accent = color or T.Blue
	local dialog = o.Dialog == true
	local BAR = if dialog then 0 else 62 -- the strip above a full menu's panel
	local holder = Kit.box({
		Name = titleText,
		Size = UDim2.fromOffset(size.X.Offset, size.Y.Offset + BAR),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Parent = gui,
	})
	holder.ZIndex = 5
	-- the rest of the screen goes dark behind a menu, and clicks don't go through it
	local dim = Kit.frame({
		Name = "Dim",
		Size = UDim2.fromOffset(6000, 6000),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Color = Color3.fromRGB(6, 7, 12),
		Transparency = if dialog then 0.45 else 0.06,
		Radius = false,
		ZIndex = 0,
		Parent = holder,
	})
	dim.Active = true
	local seed = #titleText * 31 + string.byte(titleText, 1)
	if dialog then
		-- lighter behind the dialog, darker toward the screen's edges
		Kit.vignette(dim, 0.6, 0.3, 0.3)
	else
		Kit.motion(holder, accent, seed)
	end
	local _ = icon
	-- the panel in its rim, two corners cut
	local CUT = if dialog then 22 else 30
	local rim = Kit.box({
		Name = "Rim",
		Size = UDim2.new(1, 0, 1, -BAR),
		Position = UDim2.fromOffset(0, BAR),
		Parent = holder,
	})
	Kit.cutInto(rim, rimColor(), CUT + 2)
	local frame = Kit.box({
		Name = "Card",
		Size = UDim2.new(1, -RIM * 2, 1, -RIM * 2),
		Position = UDim2.fromOffset(RIM, RIM),
		Parent = rim,
	})
	Kit.cutInto(frame, T.Cream, CUT)
	-- details: a block of stripes inside the cut corner at the bottom right, ticks along the top
	Kit.stripes({
		Parent = frame,
		Size = UDim2.fromOffset(86, 12),
		Position = UDim2.new(1, -CUT - 96, 1, -22),
		Color = accent,
		Transparency = 0.25,
	})
	for t = 0, 5 do
		Kit.new("Frame", {
			Name = "Tick",
			BackgroundColor3 = accent,
			BackgroundTransparency = 0.45,
			BorderSizePixel = 0,
			Size = UDim2.fromOffset(if t == 0 then 26 else 5, 4),
			Position = UDim2.fromOffset(CUT + 12 + (if t == 0 then 0 else 24 + t * 10), 9),
			Parent = frame,
		})
	end

	local title: TextLabel
	local close: TextButton
	local header: Frame
	local selectTab: ((string) -> ())? = nil
	if dialog then
		header = Kit.box({ Name = "Header", Parent = frame, Size = UDim2.new(1, 0, 0, 62) })
		title = Kit.title(titleText, {
			Parent = header,
			Size = UDim2.new(1, -110, 1, 0),
			Position = UDim2.fromOffset(34, 6),
			TextSize = 26,
			Color = T.Ink,
		})
		close = Kit.new("TextButton", {
			Name = "Close",
			Text = "",
			AutoButtonColor = false,
			BackgroundColor3 = T.Card,
			Size = UDim2.fromOffset(40, 40),
			Position = UDim2.new(1, -14, 0, 14),
			AnchorPoint = Vector2.new(1, 0),
			ZIndex = 2,
			Parent = frame,
		})
		Kit.corner(close, 3)
		Icons.make("close", 20, {
			Name = "IconArt",
			Parent = close,
			Position = UDim2.new(0.5, -10, 0.5, -10),
			Color = T.Ink,
			Hole = T.Card,
			ZIndex = 3,
		})
	else
		header = Kit.box({ Name = "Header", Parent = holder, Size = UDim2.new(1, 0, 0, BAR - 10) })
		-- the way back, at the top left
		close = Kit.backButton({ Parent = header, Position = UDim2.fromOffset(2, 2) })
		-- a leaning mark in the menu's colour, then its name
		local mark = Kit.new("Frame", {
			Name = "Mark",
			BackgroundColor3 = accent,
			BorderSizePixel = 0,
			Size = UDim2.fromOffset(22, 34),
			Position = UDim2.fromOffset(98, 8),
			Parent = header,
		})
		Kit.slant(mark, 34)
		title = Kit.title(titleText, {
			Parent = header,
			Size = UDim2.new(0.5, -130, 0, 46),
			Position = UDim2.fromOffset(130, 2),
			TextSize = 30,
			Color = T.White,
		})
		if o.Tabs then
			local _bar, select = Kit.segments(o.Tabs, function(id: string)
				if o.OnTab then
					o.OnTab(id)
				end
			end, { Parent = header, Position = UDim2.new(1, -2, 0, 2), AnchorPoint = Vector2.new(1, 0) })
			selectTab = select
		end
	end
	title.ZIndex = 2
	if dialog then
		close:SetAttribute("KitButton", true)
		pressable(close)
	end
	local top = if dialog then 62 else 26
	local body = Kit.box({
		Name = "Body",
		Size = UDim2.new(1, -52, 1, -top - 26),
		Position = UDim2.fromOffset(26, top),
		Parent = frame,
	})
	local self = {
		root = holder,
		card = frame,
		body = body,
		close = close,
		title = title,
		header = header,
		selectTab = selectTab,
	}
	close.Activated:Connect(function()
		if onClose then
			onClose()
		else
			holder.Visible = false
		end
	end)
	return self
end

-- Shapes ---------------------------------------------------------------------------------------------
-- (These were wobbly bubbles in an earlier look, and the names stayed.) A "blob" is a plain shape
-- in one flat colour: a rounded rectangle, a pill or a circle, with an optional little tail. It
-- never moves and nothing in it reaches past the holder's edges, so a holder that sizes itself to
-- its content stays the right size.
type BlobInfo = { holder: Frame, dead: boolean? }

function Kit.blobInto(holder: Frame, p: { [string]: any }): BlobInfo
	local color: Color3 = p.Color or T.Paper
	local z = p.ZIndex or holder.ZIndex
	holder:SetAttribute("Blob", true)
	local layer = Kit.new("Frame", {
		Name = "Shape",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = z,
		Parent = holder,
	})
	local core = Kit.new("Frame", {
		Name = "Core",
		BackgroundColor3 = color,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		ZIndex = z,
		Parent = layer,
	})
	if p.Slant then
		-- a leaning shape: slanted ends and no rounding at all
		Kit.slant(core, if type(p.Slant) == "number" then p.Slant else nil)
	else
		Kit.corner(core, p.Radius or 20)
		-- a soft shadow under the shape (Lift = false for none, or how deep)
		if p.Lift ~= false then
			Kit.softShadow(core, if type(p.Lift) == "number" then p.Lift else 0.6)
		end
	end
	if p.Tail then
		local size = p.TailSize or 20
		local at = p.TailAt or 0.5
		local tail = p.Tail
		local inset = size * 0.2
		Kit.new("Frame", {
			Name = "Tail",
			BackgroundColor3 = color,
			BorderSizePixel = 0,
			Rotation = 45,
			Size = UDim2.fromOffset(size, size),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = if tail == "down"
				then UDim2.new(at, 0, 1, -inset)
				elseif tail == "up" then UDim2.new(at, 0, 0, inset)
				elseif tail == "left" then UDim2.new(0, inset, at, 0)
				else UDim2.new(1, -inset, at, 0),
			ZIndex = z,
			Parent = layer,
		})
	end
	return { holder = holder }
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
					Kit.paint(f, c)
				end
			end
		end
	end
end

-- Recolours a flat icon drawn by Icons.make: its glyph and its cut out details.
function Kit.recolorIcon(icon: Instance, glyph: Color3, hole: Color3)
	if icon:GetAttribute("Vector") then
		-- a drawn icon is one picture: tint it (art with its own colours keeps them)
		local art = icon:FindFirstChild("Art")
		if art and art:IsA("ImageLabel") and icon:GetAttribute("Mono") then
			art.ImageColor3 = glyph
		end
		icon:SetAttribute("Glyph", glyph:ToHex())
		return
	end
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
	local color: Color3 = p.Color or T.Paper
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
			-- what was a pill is a leaning slab
			local core = Kit.frame({ Name = "Core", Parent = l, Color = spec[2], Radius = false, ZIndex = z })
			Kit.slant(core, if p.Size then (p.Size :: UDim2).Y.Offset else 54)
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
		Tail = false,
		Color = T.PaperDark,
		ZIndex = z,
	})
	local core = holder:FindFirstChild("Shape") and (holder :: any).Shape:FindFirstChild("Core")
	local stripes = Kit.new("UIGradient", {
		Name = "Stripes",
		Enabled = false,
		Rotation = 24,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
			ColorSequenceKeypoint.new(0.12, Color3.new(0.9, 0.9, 0.93)),
			ColorSequenceKeypoint.new(0.25, Color3.new(1, 1, 1)),
			ColorSequenceKeypoint.new(0.37, Color3.new(0.9, 0.9, 0.93)),
			ColorSequenceKeypoint.new(0.5, Color3.new(1, 1, 1)),
			ColorSequenceKeypoint.new(0.62, Color3.new(0.9, 0.9, 0.93)),
			ColorSequenceKeypoint.new(0.75, Color3.new(1, 1, 1)),
			ColorSequenceKeypoint.new(0.87, Color3.new(0.9, 0.9, 0.93)),
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
		Kit.setBubbleColor(holder, if on and not p.Disabled then T.Line else T.PaperDark)
		stripes.Enabled = on and not p.Disabled
	end
	b.MouseEnter:Connect(function()
		lit(true)
	end)
	b.MouseLeave:Connect(function()
		lit(false)
	end)
	pressable(b)
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
		TextColor3 = T.Dark,
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
				-- the picked tab is yellow with dark words
				Kit.setButtonColor(b, p.Active or T.Yellow, T.Dark)
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
		Name = "Swatch", -- a colour to pick: the one kind of thing that may be light (tools/preview/ui_audit.py)
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
