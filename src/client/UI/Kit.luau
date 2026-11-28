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
local Skin = require(script.Parent.Skin)

local Kit = {}

-- What a control, a menu or a notice sounds like: "click", "tab", "open", "close", "notice",
-- "good", "warn". Controllers/Audio puts its player here when the game starts (the user: "add
-- sounds where necessary"); the previews and the simulations leave it quiet.
Kit.sound = function(_kind: string) end

Kit.Theme = {
	-- what a full menu covers the screen with, and the far end of a fade
	Black = Color3.fromRGB(8, 8, 10),
	-- surfaces, darkest to lightest: a well sinks into a panel, a card stands up off it. They
	-- are charcoal with next to no colour of their own, so the accents carry it
	PaperDark = Color3.fromRGB(15, 15, 18), -- wells, tracks, unpicked tabs
	Cream = Color3.fromRGB(23, 23, 27), -- big panels
	Paper = Color3.fromRGB(31, 31, 36), -- cards and buttons, the bars over the 3D view
	Card = Color3.fromRGB(44, 44, 50), -- a row or a tile on a panel
	Picture = Color3.fromRGB(78, 80, 94), -- behind a catalog picture or a face: light enough that dark hair shows
	Line = Color3.fromRGB(82, 80, 72), -- the thin rim round a card: a warm grey
	-- words
	Ink = Color3.fromRGB(240, 240, 236), -- words on any of the surfaces above
	InkSoft = Color3.fromRGB(158, 158, 164),
	White = Color3.fromRGB(255, 255, 255), -- words and icons on a coloured button
	Dark = Color3.fromRGB(13, 13, 16), -- outlines round letters, and words on a bright face
	-- accents: the same pastels as before, they carry the colour now
	Green = Color3.fromRGB(128, 198, 118),
	GreenDark = Color3.fromRGB(92, 164, 92),
	Coral = Color3.fromRGB(250, 140, 128),
	CoralDark = Color3.fromRGB(222, 104, 98),
	Blue = Color3.fromRGB(116, 178, 236),
	BlueDark = Color3.fromRGB(84, 146, 210),
	Yellow = Color3.fromRGB(255, 210, 64),
	YellowDark = Color3.fromRGB(238, 166, 44),
	Red = Color3.fromRGB(232, 66, 60), -- the way out of a menu
	Purple = Color3.fromRGB(186, 156, 232),
	Orange = Color3.fromRGB(255, 172, 108),
	Pink = Color3.fromRGB(250, 156, 186),
	Teal = Color3.fromRGB(110, 204, 188),
	Shadow = Color3.fromRGB(0, 0, 0),
	Glass = Color3.fromRGB(12, 12, 15), -- the dark see-through slabs over the 3D view
	GlassAlpha = 0.14,
}

local T = Kit.Theme

-- The two looks. The game opens dark (the user: "Make every ui element dark mode, with a dark
-- background"); light is for whoever asks for it ("along with the option to change to light
-- mode"). Only the surfaces and the words on them differ: the accents, white, the dark glass
-- over the 3D view and its words stay. Kit.Theme holds the one that is on, and Kit.setTheme
-- swaps these values into it in place, so code that reads T.Paper as it builds gets the right
-- one. No two tokens of a look may be the same colour: the switch tells them apart by it.
Kit.Themes = {
	dark = {
		Black = T.Black,
		PaperDark = T.PaperDark,
		Cream = T.Cream,
		Paper = T.Paper,
		Card = T.Card,
		Picture = T.Picture,
		Line = T.Line,
		Ink = T.Ink,
		InkSoft = T.InkSoft,
	},
	light = {
		Black = Color3.fromRGB(218, 223, 235),
		PaperDark = Color3.fromRGB(208, 214, 228),
		Cream = Color3.fromRGB(236, 239, 246),
		Paper = Color3.fromRGB(246, 248, 252),
		Card = Color3.fromRGB(253, 253, 255),
		Picture = Color3.fromRGB(222, 228, 242),
		Line = Color3.fromRGB(196, 202, 219),
		Ink = Color3.fromRGB(34, 37, 51),
		InkSoft = Color3.fromRGB(100, 106, 131),
	},
}
Kit.ThemeName = "dark"

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
	gui.Name = "CatalogTown"
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

-- Shapes ---------------------------------------------------------------------------------------------
--
-- The look so far was cut from straight lines (the user: "Use the format in zenless zone zero for
-- buttons and details in ui instead of overusing circles and rounded rectangles"). Two later
-- requests soften it. Of the slabs on the main screen: "could you make these parallelograms
-- textured like these buttons, with other details and buttons shown like this in circles? note
-- that these have smooth points as well". Of the menus, pointing at that game's own guide to its
-- menu screens: "try to replicate the look and feel as much as possible, including the texturing
-- and minute details".
--
-- So: what leans (the slabs over the 3D view, the way back out of a menu, a price tag) still
-- leans, with its four points rounded and a tone of halftone dots on it; a menu is a charcoal
-- card with round corners and a thin rim; rows and tabs are pills, the picked one yellow with dark
-- words; small buttons, markers and details are circles. The feel is what is taken. Every shape,
-- dot and line is drawn here from nothing (UI/Skin), and none of that game's art, icons, type or
-- patterns is used.
--
-- A leaning slab with rounded points can't be cut from boxes, so UI/Skin paints its two ends
-- and an ImageLabel stretches the middle between them. Where the game can't make pictures
-- (Allow Mesh / Image APIs off) the slab is drawn the old way: a box with a sharp wedge on each
-- end, a wedge being a box with a UIGradient laid square across its diagonal whose Transparency
-- steps from clear to solid half way.

local CORNER = 10 -- a corner's radius when none is asked for, in pixels
local CORNER_MAX = 18 -- and the most any corner gets, short of a pill or a circle
Kit.Lean = 0.3 -- how far a leaning end runs sideways, as a share of the thing's height

-- Round corners: `radius` in pixels (kept modest), or "pill" / "round" for ends that are half
-- circles (a pill of a bar, a circle of a square).
function Kit.corner(inst: Instance, radius: any): UICorner
	local r = UDim.new(0, CORNER)
	if radius == "round" or radius == "pill" or radius == "circle" then
		r = UDim.new(0.5, 0)
	elseif type(radius) == "number" then
		r = UDim.new(0, math.clamp(radius, 2, CORNER_MAX))
	end
	return Kit.new("UICorner", { CornerRadius = r, Parent = inst })
end

-- A thin line round a disc or a ring, just inside its edge. `transparency` 0 by default. Rounded
-- rectangles (cards, tiles, rows, wells, notes, bubbles) never get one: the user, "for bubbles
-- and text in rounded rectangles everywhere, remove the borders". A thing that is picked may still
-- be ringed in yellow while it is.
function Kit.rim(inst: Instance, color: Color3?, thickness: number?, transparency: number?): UIStroke
	local old = inst:FindFirstChild("Rim")
	if old then
		old:Destroy()
	end
	return Kit.new("UIStroke", {
		Name = "Rim",
		Color = color or T.Line,
		Thickness = thickness or 1.5,
		Transparency = transparency or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		LineJoinMode = Enum.LineJoinMode.Round,
		Parent = inst,
	})
end

-- A round frame with a border for somebody's face (the user: "make portraits a circle with a
-- border instead of a square"). props: Parent, Size (pixels across), Position, AnchorPoint, Color (what shows
-- behind the face), Border (the ring's colour), BorderWidth, Name, ZIndex, LayoutOrder. Returns
-- the frame. A picture put in it (a ViewportFrame, an ImageLabel) fills it and is cut to the
-- circle with Kit.rounded.
function Kit.portrait(props: { [string]: any }?): Frame
	local p = props or {}
	local px: number = p.Size or 46
	local f = Kit.new("Frame", {
		Name = p.Name or "Portrait",
		BackgroundColor3 = p.Color or T.Picture,
		BorderSizePixel = 0,
		Size = UDim2.fromOffset(px, px),
		Position = p.Position or UDim2.new(),
		AnchorPoint = p.AnchorPoint or Vector2.zero,
		ZIndex = p.ZIndex or 1,
		LayoutOrder = p.LayoutOrder or 0,
		Parent = p.Parent,
	})
	Kit.new("UICorner", { CornerRadius = UDim.new(0.5, 0), Parent = f })
	Kit.new("UIStroke", {
		Name = "Rim",
		Color = p.Border or T.White,
		Thickness = p.BorderWidth or 2,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = f,
	})
	return f
end

-- Cuts a picture to a circle, to sit in a Kit.portrait.
function Kit.rounded(picture: GuiObject): GuiObject
	Kit.new("UICorner", { CornerRadius = UDim.new(0.5, 0), Parent = picture })
	return picture
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

-- How round a leaning slab's points are, for its height.
local function pointOf(h: number): number
	return math.clamp(math.floor(h * 0.17 + 0.5), 3, 9)
end

-- The painted picture under a leaning face, or nil where its plain wedges are showing.
local function bodyOf(face: Instance): ImageLabel?
	local body = face:FindFirstChild("Body")
	return if body and body:IsA("ImageLabel") then body else nil
end

-- The gradient a shaded face is shaded by (on its painted picture when it has one).
local function shadeOf(face: Instance): UIGradient?
	local g = (bodyOf(face) or face):FindFirstChild("Shade")
	return if g and g:IsA("UIGradient") then g else nil
end
Kit.shadeOf = shadeOf

-- A picture of UI/Skin's laid over a leaning face's whole shape (its ends stand `cap` past the
-- face on either side).
local function slabLayer(face: GuiObject, name: string, pic: any, cap: number, z: number): ImageLabel
	local pad = Skin.Pad
	local layer = Kit.new("ImageLabel", {
		Name = name,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(1, (cap + pad) * 2, 1, pad * 2),
		Position = UDim2.fromOffset(-cap - pad, -pad),
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(pic.cap * Skin.Scale, 0, pic.w - pic.cap * Skin.Scale, pic.h),
		SliceScale = 1 / Skin.Scale,
		ZIndex = z,
		Parent = face,
	});
	(layer :: any).ImageContent = pic.content
	return layer
end

-- Makes a plain rectangle lean: it is pulled in at both ends and an end put on each, so the
-- whole stays inside the box the rectangle had (or with `outside`, the rectangle keeps its box
-- and the ends stand out past it). `height` is its height in pixels when its Size doesn't say.
-- Returns how far each end runs.
--
-- The slab is painted, its four points rounded: the face itself goes clear and a picture named
-- Body under everything in it draws the shape, in the face's colour. So recolour a leaning face
-- with Kit.paint and read its colour with Kit.colorOf, never through its BackgroundColor3. (Where
-- the game can't make pictures the face keeps its colour and gets a sharp wedge on each end.)
function Kit.slant(face: GuiObject, height: number?, outside: boolean?, flip: boolean?, sharp: string?): number
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
	if flip then
		face:SetAttribute("Flip", true)
	end
	face:SetAttribute("Cap", cap)
	face:SetAttribute("Tall", h)
	if sharp then
		-- (one end left sharp, where this slab meets another: Skin.paintSlab)
		face:SetAttribute("Sharp", sharp)
	end
	local pic = Skin.slab(h, cap, flip == true, pointOf(h), nil, nil, sharp)
	-- A slab that sizes itself to its words (a caption, a name tag, a size tag): its width is set
	-- from the words instead once they're in, since its painted layer is sized by share of it
	-- (Kit.fitWidth). Only for a slab whose one thing is a line of words.
	if face.AutomaticSize == Enum.AutomaticSize.X or face.AutomaticSize == Enum.AutomaticSize.XY then
		local fitted = false
		local function try()
			if fitted then
				return
			end
			local words: GuiObject? = nil
			for _, c in face:GetChildren() do
				if c:IsA("TextLabel") or c:IsA("TextButton") then
					if words then
						return
					end
					words = c
				elseif c:IsA("GuiObject") and c.Name ~= "Body" and not c:GetAttribute("SlabEnd") then
					return
				end
			end
			if words then
				fitted = true
				Kit.fitWidth(face, words)
			end
		end
		-- (its words go in after the slab is made)
		face.ChildAdded:Connect(try)
		task.defer(try)
	end
	if pic then
		local body = slabLayer(face, "Body", pic, cap, -3)
		body.ImageColor3 = face.BackgroundColor3
		body.ImageTransparency = face.BackgroundTransparency
		face:SetAttribute("Base", face.BackgroundColor3:ToHex())
		face:SetAttribute("Painted", true)
		face.BackgroundTransparency = 1
		return cap
	end
	-- the usual lean is "/" (wider at the bottom on the left, at the top on the right); flipped
	-- it is "\": wider at the top on the left, at the bottom on the right
	local ends = if flip then { "tr", "bl" } else { "br", "tl" }
	for i, keep in ends do
		local wedge = Kit.wedge({
			Parent = face,
			Color = face.BackgroundColor3,
			Transparency = face.BackgroundTransparency,
			Size = UDim2.new(0, cap, 1, 0),
			Position = if i == 1 then UDim2.fromOffset(-cap, 0) else UDim2.new(1, 0, 0, 0),
			ZIndex = face.ZIndex,
			W = cap,
			H = h,
		}, keep)
		wedge:SetAttribute("SlabEnd", true)
	end
	return cap
end

-- The small thing that makes a painted slab look made: a tone of halftone dots that starts at one
-- end of the slab, cut to its shape, and thins out toward the middle. (A thin line ran just
-- inside the slab's edge too. The user, of the stats strip: "remove the borders". So no leaning
-- slab has one now.) opts: Tone (the dots' colour; false for none), ToneAlpha (0.9), Side
-- ("right" or "left": the end the dots start from), ToneWidth (how far in they reach). Does
-- nothing where the slab isn't painted.
function Kit.detail(face: GuiObject, opts: { [string]: any }?)
	local o = opts or {}
	if not bodyOf(face) then
		return
	end
	local h: number = face:GetAttribute("Tall") :: any or 40
	local cap: number = face:GetAttribute("Cap") :: any or 8
	local flip = face:GetAttribute("Flip") == true
	local point = pointOf(h)
	for _, name in { "Line", "Tone" } do
		local old = face:FindFirstChild(name)
		if old then
			old:Destroy()
		end
	end
	if o.Tone ~= false then
		-- the halftone starts at the very end of the slab and is cut to its shape
		local wide = math.clamp(math.floor(o.ToneWidth or 132), 12, 200)
		local pic = Skin.tone(h, cap, flip, point, wide)
		if pic then
			local left = o.Side == "left"
			local pad = Skin.Pad
			local tone = Kit.new("ImageLabel", {
				Name = "Tone",
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Size = UDim2.fromOffset(cap + wide + pad, h + pad * 2),
				AnchorPoint = Vector2.new(if left then 0 else 1, 0),
				Position = if left then UDim2.fromOffset(-cap - pad, -pad) else UDim2.new(1, cap + pad, 0, -pad),
				-- painted for a left end; half way round it is the right end's
				Rotation = if left then 0 else 180,
				ImageColor3 = if typeof(o.Tone) == "Color3" then o.Tone else Color3.new(1, 1, 1),
				ImageTransparency = o.ToneAlpha or 0.9,
				ZIndex = -2,
				Parent = face,
			});
			(tone :: any).ImageContent = pic.content
			tone:SetAttribute("Tinted", true)
		end
	end
end

-- Gradients -----------------------------------------------------------------------------------------
-- The user: "reference zenless zone zero uis, add gradients to menus as well to add more polish".
-- A leaning face (a row, a tab, a button, a tile) is shaded across: its colour at the left,
-- a deeper tone of it at the right, the slanted end on each side in the colour of that side, so
-- the slab reads as one piece. A picked yellow warms toward amber rather than going muddy. The
-- face's own colour is kept in its `Base` attribute (its BackgroundColor3 is white under the
-- gradient); Kit.paint and Kit.setButtonColor keep a shaded face shaded.

local SHADE_TO = Color3.new(0, 0, 0)

-- The right hand end of a face shaded from `color`.
function Kit.shadeEnd(color: Color3): Color3
	if color == T.Yellow then
		return T.Yellow:Lerp(T.YellowDark, 0.75)
	end
	-- a pale surface (the light look's rows and tabs) needs less to show the same depth
	local light = color.R * 0.3 + color.G * 0.59 + color.B * 0.11
	return color:Lerp(SHADE_TO, if light > 0.7 then 0.07 else 0.16)
end

-- What colour a face is, shaded or not, painted or not.
function Kit.colorOf(face: GuiObject): Color3
	local base = face:GetAttribute("Base")
	if type(base) == "string" then
		return Color3.fromHex(base)
	end
	return face.BackgroundColor3
end

-- The colour of the thin line round a face of `color`: a deeper tone of it.
local function edgeOf(color: Color3): Color3
	local light = color.R * 0.3 + color.G * 0.59 + color.B * 0.11
	return color:Lerp(Color3.new(0, 0, 0), if light > 0.7 then 0.2 else 0.34)
end
Kit.edgeOf = edgeOf

-- (After a face is recoloured.) Its thin line follows its colour, where it has one that does.
local function follow(face: GuiObject)
	local rim = face:FindFirstChild("Rim")
	if rim and rim:IsA("UIStroke") and rim:GetAttribute("Follow") then
		rim.Color = edgeOf(Kit.colorOf(face))
	end
end

-- A tile's face: its colour, with a deeper band across the bottom where its name goes (one
-- gradient with a step in it, so the band is cut to the tile's round corners with it).
local FOOT = 0.66
local function footShade(face: GuiObject, color: Color3)
	face:SetAttribute("Base", color:ToHex())
	face.BackgroundColor3 = Color3.new(1, 1, 1)
	local g = face:FindFirstChild("Foot")
	if not (g and g:IsA("UIGradient")) then
		g = Kit.new("UIGradient", { Name = "Foot", Rotation = 90, Parent = face })
	end
	local light = color.R * 0.3 + color.G * 0.59 + color.B * 0.11
	local top = color:Lerp(Color3.new(1, 1, 1), if light > 0.7 then 0 else 0.03)
	local low = color:Lerp(Color3.new(0, 0, 0), if light > 0.7 then 0.1 else 0.3);
	(g :: UIGradient).Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, top),
		ColorSequenceKeypoint.new(FOOT, color),
		ColorSequenceKeypoint.new(FOOT + 0.005, low),
		ColorSequenceKeypoint.new(1, low),
	})
end

-- Shades a face from `color` (its own colour if none) at the left to a deeper tone at the
-- right.
function Kit.shade(face: GuiObject, color: Color3?)
	local a = color or Kit.colorOf(face)
	local b = Kit.shadeEnd(a)
	face:SetAttribute("Base", a:ToHex())
	local body = bodyOf(face)
	local host: Instance = body or face
	if body then
		-- the picture is white under the gradient; the face keeps the colour for whoever reads it
		body.ImageColor3 = Color3.new(1, 1, 1)
		face.BackgroundColor3 = a
	else
		face.BackgroundColor3 = Color3.new(1, 1, 1)
	end
	local g = host:FindFirstChild("Shade")
	if not (g and g:IsA("UIGradient")) then
		g = Kit.new("UIGradient", { Name = "Shade", Parent = host })
	end
	(g :: UIGradient).Color = ColorSequence.new(a, b)
	for _, c in face:GetChildren() do
		if c:IsA("Frame") and c.Name:sub(1, 6) == "Wedge_" then
			-- the slanted end on the left takes the left colour, the one on the right the right's
			c.BackgroundColor3 = if c.Position.X.Scale < 0.5 then a else b
		end
	end
	follow(face)
end

-- A soft glow of `color` laid into a frame from one corner ("tr" the top right by default, or
-- "tl", "bl", "br"), fading out before the middle: depth on a dark card without touching its
-- shape (from the top right it stays clear of a cut card's cut corners). `strength` is how much
-- of the colour shows at the corner, 0.3 by default. Returns the glow, a frame named Glow under
-- whatever else the frame holds.
function Kit.glow(frame: GuiObject, color: Color3, strength: number?, corner: string?): Frame
	local old = frame:FindFirstChild("Glow")
	if old then
		old:Destroy()
	end
	local glow = Kit.new("Frame", {
		Name = "Glow",
		BackgroundColor3 = color,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 0,
		Parent = frame,
	})
	-- the colour itself is the menu's: a change of look leaves it be
	glow:SetAttribute("KeepColors", true)
	local from = 1 - (strength or 0.3)
	local turn = ({ tr = 135, tl = 45, bl = -45, br = -135 })[corner or "tr"] or 135
	Kit.new("UIGradient", {
		Name = "Falloff",
		Rotation = turn,
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, from),
			NumberSequenceKeypoint.new(0.22, from + (1 - from) * 0.55),
			NumberSequenceKeypoint.new(0.44, 1),
			NumberSequenceKeypoint.new(1, 1),
		}),
		Parent = glow,
	})
	return glow
end

-- Recolours a face (and whether it shows): its painted picture or its wedges follow, and its
-- thin line.
function Kit.paint(face: GuiObject, color: Color3?, transparency: number?)
	if color and shadeOf(face) then
		Kit.shade(face, color)
		color = nil
	elseif color and face:FindFirstChild("Foot") then
		footShade(face, color)
		color = nil
	end
	local rim = face:FindFirstChild("Rim")
	if transparency and rim and rim:IsA("UIStroke") and rim:GetAttribute("Follow") then
		rim.Transparency = transparency
	end
	local body = bodyOf(face)
	if body then
		if color then
			body.ImageColor3 = color
			face.BackgroundColor3 = color
			face:SetAttribute("Base", color:ToHex())
		end
		if transparency then
			body.ImageTransparency = transparency
			-- its line and its dots go when it does
			for _, name in { "Line", "Tone" } do
				local detail = face:FindFirstChild(name)
				if detail and detail:IsA("GuiObject") then
					detail.Visible = transparency < 1
				end
			end
		end
		return
	end
	if color then
		face.BackgroundColor3 = color
		if face:GetAttribute("Base") ~= nil then
			face:SetAttribute("Base", color:ToHex())
		end
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
	follow(face)
end

-- Fades a face in or out (to `transparency`) with a tween: a leaning face's painted picture, or a
-- plain face and its slanted ends. (A leaning face's own BackgroundTransparency stays clear.)
function Kit.fade(face: GuiObject, info: TweenInfo, transparency: number)
	local body = bodyOf(face)
	if body then
		TweenService:Create(body, info, { ImageTransparency = transparency }):Play()
		return
	end
	TweenService:Create(face, info, { BackgroundTransparency = transparency }):Play()
	for _, c in face:GetChildren() do
		if c:IsA("Frame") and c.Name:sub(1, 6) == "Wedge_" then
			TweenService:Create(c, info, { BackgroundTransparency = transparency }):Play()
		end
	end
end

-- Fills `holder` with a card's shape, under everything else in it: a rounded rectangle (its
-- corners `cut` round, which was how much of two corners got cut off in the look before, and
-- the name has stayed). Returns the layer (Kit.paintCut recolours it).
function Kit.cutInto(holder: GuiObject, color: Color3, cut: number, z: number?): Frame
	local layer = Kit.new("Frame", {
		Name = "Cut",
		BackgroundColor3 = color,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		ZIndex = z or 0,
		Parent = holder,
	})
	Kit.corner(layer, math.clamp(cut, 6, 14))
	return layer
end

function Kit.paintCut(holder: Instance, color: Color3)
	local layer = holder:FindFirstChild("Cut")
	if layer and layer:IsA("Frame") then
		layer.BackgroundColor3 = color
	end
end

-- A halftone tone over a card: the fine grid of dots this look's surfaces carry. It is cut to
-- `radius` (the card's own corners) and fades toward the bottom left unless `even`. Returns
-- the layer, or nil where the game can't make pictures.
function Kit.dots(card: GuiObject, color: Color3?, alpha: number?, radius: any, even: boolean?): ImageLabel?
	local old = card:FindFirstChild("Dots")
	if old then
		old:Destroy()
	end
	local pic = Skin.texture("dots")
	if not pic then
		return nil
	end
	local tile = Skin.DotPitch * 2
	local dots = Kit.new("ImageLabel", {
		Name = "Dots",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		ImageColor3 = color or T.Ink,
		ImageTransparency = alpha or 0.94,
		ScaleType = Enum.ScaleType.Tile,
		TileSize = UDim2.fromOffset(tile, tile),
		ZIndex = 0,
		Parent = card,
	});
	(dots :: any).ImageContent = pic.content
	dots:SetAttribute("Tinted", true)
	if radius ~= false then
		Kit.corner(dots, radius)
	end
	if not even then
		Kit.new("UIGradient", {
			Name = "Falloff",
			Rotation = 150,
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0),
				NumberSequenceKeypoint.new(0.5, 0.45),
				NumberSequenceKeypoint.new(1, 1),
			}),
			Parent = dots,
		})
	end
	return dots
end

-- A band of diagonal hatching: a detail for a header or the end of a bar. props: Parent, Size,
-- Position, AnchorPoint, Color, Transparency, ZIndex, Fade ("left" or "right": the end it fades
-- out toward). Returns nil where the game can't make pictures.
function Kit.hatch(props: { [string]: any }): ImageLabel?
	local pic = Skin.texture("hatch")
	if not pic then
		return nil
	end
	local band = Kit.new("ImageLabel", {
		Name = "Hatch",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = props.Size or UDim2.fromOffset(80, 16),
		Position = props.Position or UDim2.new(),
		AnchorPoint = props.AnchorPoint or Vector2.zero,
		ImageColor3 = props.Color or T.Ink,
		ImageTransparency = props.Transparency or 0.85,
		ScaleType = Enum.ScaleType.Tile,
		TileSize = UDim2.fromOffset(Skin.HatchPitch, Skin.HatchPitch),
		ZIndex = props.ZIndex or 1,
		Parent = props.Parent,
	});
	(band :: any).ImageContent = pic.content
	band:SetAttribute("Tinted", true)
	if props.Fade then
		local left = props.Fade == "left"
		Kit.new("UIGradient", {
			Name = "Falloff",
			Transparency = NumberSequence.new(if left then 1 else 0, if left then 0 else 1),
			Parent = band,
		})
	end
	return band
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

-- Fine detail ----------------------------------------------------------------------------------------
-- The same request asked for the menus to be polished "much further", in the feel of that game's
-- menu screens: small careful marks that make a card look made. Corner brackets, thin rules that
-- end in a dot, small captions set wide in capitals, index numbers, a faint large word behind a
-- title and ticks round a dial. All of it is plain frames and words drawn here, in our colours.

-- Words set wide for a small caption: capitals with a space between the letters and three between
-- the words ("Ready to claim" becomes "R E A D Y   T O   C L A I M").
function Kit.spaced(text: string): string
	local words = {}
	for word in string.gmatch(string.upper(text), "%S+") do
		local letters = {}
		for _, code in utf8.codes(word) do
			table.insert(letters, utf8.char(code))
		end
		table.insert(words, table.concat(letters, " "))
	end
	return table.concat(words, "   ")
end

-- A number as an index: two digits ("03").
function Kit.index(n: number): string
	return string.format("%02d", math.max(0, math.floor(n)))
end

-- A small caption set wide in capitals. props: Parent, Size (it is as wide as its words unless
-- given), Position, AnchorPoint, LayoutOrder, Name, TextSize (11), Color (InkSoft) or Tint, AlignX,
-- ZIndex. Returns the label.
function Kit.caption(text: string, props: { [string]: any }?): TextLabel
	local p = props or {}
	local size: number = p.TextSize or 11
	local label = Kit.text(Kit.spaced(text), {
		Name = p.Name or "Caption",
		Parent = p.Parent,
		Size = p.Size or UDim2.fromOffset(0, size + 4),
		AutomaticSize = if p.Size then Enum.AutomaticSize.None else Enum.AutomaticSize.X,
		Position = p.Position,
		AnchorPoint = p.AnchorPoint,
		LayoutOrder = p.LayoutOrder,
		TextSize = size,
		Font = Kit.Fonts.Body,
		Color = if p.Tint then nil else p.Color or T.InkSoft,
		Tint = p.Tint,
		AlignX = p.AlignX,
		Wrap = false,
		ZIndex = p.ZIndex,
	})
	label.TextTruncate = Enum.TextTruncate.AtEnd
	return label
end

-- Corner brackets: an L at each corner named in `Corners` ("tl", "tr", "bl", "br"; the top left
-- and the bottom right by default), so a card or a box looks framed. props: Color (T.Line), Arm
-- (how long each leg is, 10), Thick (2), Inset (from the corner inward; less than 0 sits outside
-- the frame), Transparency, ZIndex, Name. Returns the layer that holds them (a frame filling
-- `frame`, under the name Brackets).
function Kit.brackets(frame: GuiObject, props: { [string]: any }?): Frame
	local p = props or {}
	local arm: number = p.Arm or 10
	local thick: number = p.Thick or 2
	local inset: number = p.Inset or 4
	local color: Color3 = p.Color or T.Line
	local z: number = p.ZIndex or 3
	local layer = Kit.new("Frame", {
		Name = p.Name or "Brackets",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = z,
		Parent = frame,
	})
	for _, corner in p.Corners or { "tl", "br" } do
		local right = corner:sub(2, 2) == "r"
		local bottom = corner:sub(1, 1) == "b"
		local anchor = Vector2.new(if right then 1 else 0, if bottom then 1 else 0)
		local holder = Kit.new("Frame", {
			Name = corner,
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(arm, arm),
			AnchorPoint = anchor,
			Position = UDim2.new(anchor.X, if right then -inset else inset, anchor.Y, if bottom then -inset else inset),
			ZIndex = z,
			Parent = layer,
		})
		for _, across in { true, false } do
			local leg = Kit.new("Frame", {
				Name = if across then "Across" else "Down",
				BackgroundColor3 = color,
				BackgroundTransparency = p.Transparency or 0,
				BorderSizePixel = 0,
				Size = if across then UDim2.fromOffset(arm, thick) else UDim2.fromOffset(thick, arm),
				AnchorPoint = anchor,
				Position = UDim2.fromScale(anchor.X, anchor.Y),
				ZIndex = z,
				Parent = holder,
			})
			Kit.corner(leg, "pill")
		end
	end
	return layer
end

-- A thin rule with a dot at its end: a hairline that runs across and stops in a small round dot
-- (Dots = "both" puts one at the start too), with a short heavier stroke of Accent at its start
-- when given. props: Parent, Size (its height is the dot's room: 6), Position, AnchorPoint,
-- LayoutOrder, Name, Color (T.Line), Transparency, Accent, AccentLength (26), ZIndex. Returns it.
function Kit.rule(props: { [string]: any }): Frame
	local p = props
	local z: number = p.ZIndex or 1
	local color: Color3 = p.Color or T.Line
	local holder = Kit.new("Frame", {
		Name = p.Name or "Rule",
		BackgroundTransparency = 1,
		Size = p.Size or UDim2.new(1, 0, 0, 6),
		Position = p.Position or UDim2.new(),
		AnchorPoint = p.AnchorPoint or Vector2.zero,
		LayoutOrder = p.LayoutOrder or 0,
		ZIndex = z,
		Parent = p.Parent,
	})
	local both = p.Dots == "both"
	Kit.new("Frame", {
		Name = "Line",
		BackgroundColor3 = color,
		BackgroundTransparency = p.Transparency or 0,
		BorderSizePixel = 0,
		Size = UDim2.new(1, if both then -12 else -6, 0, 1),
		Position = UDim2.new(0, if both then 6 else 0, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		ZIndex = z,
		Parent = holder,
	})
	local ends: { number } = if both then { 0, 1 } else { 1 }
	for _, at in ends do
		local dot = Kit.new("Frame", {
			Name = "Dot",
			BackgroundColor3 = color,
			BackgroundTransparency = p.Transparency or 0,
			BorderSizePixel = 0,
			Size = UDim2.fromOffset(5, 5),
			Position = UDim2.fromScale(at, 0.5),
			AnchorPoint = Vector2.new(at, 0.5),
			ZIndex = z,
			Parent = holder,
		})
		Kit.corner(dot, "round")
	end
	if p.Accent then
		local stroke = Kit.new("Frame", {
			Name = "Accent",
			BackgroundColor3 = p.Accent,
			BorderSizePixel = 0,
			Size = UDim2.fromOffset(p.AccentLength or 26, 3),
			Position = UDim2.new(0, if both then 6 else 0, 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5),
			ZIndex = z + 1,
			Parent = holder,
		})
		stroke:SetAttribute("KeepColors", true)
		Kit.corner(stroke, "pill")
	end
	return holder
end

-- A faint large word behind a title. props: Parent, Position, AnchorPoint, Size (its box: the
-- word is as big as TextSize says and may run past it), TextSize (72), Color (T.Ink), Transparency
-- (0.94), AlignX, ZIndex. Returns the label.
function Kit.ghost(word: string, props: { [string]: any }): TextLabel
	local p = props
	local label = Kit.new("TextLabel", {
		Name = p.Name or "Ghost",
		Text = string.upper(word),
		BackgroundTransparency = 1,
		Font = Kit.Fonts.Title,
		TextSize = p.TextSize or 72,
		TextColor3 = p.Color or T.Ink,
		TextTransparency = p.Transparency or 0.94,
		TextXAlignment = p.AlignX or Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		TextWrapped = false,
		Size = p.Size or UDim2.fromOffset(600, (p.TextSize or 72) + 8),
		Position = p.Position or UDim2.new(),
		AnchorPoint = p.AnchorPoint or Vector2.zero,
		ZIndex = p.ZIndex or 0,
		Parent = p.Parent,
	})
	return label
end

-- Ticks round the inside of a round frame, like the marks on a dial: `count` short strokes,
-- every `major`th one longer. props: Color (T.White), Transparency (0.6), Length (4), Major,
-- Inset (from the rim, 3), Thick (2), ZIndex. Returns the layer.
function Kit.ticks(frame: GuiObject, count: number, props: { [string]: any }?): Frame
	local p = props or {}
	local z: number = p.ZIndex or frame.ZIndex
	local layer = Kit.new("Frame", {
		Name = "Ticks",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = z,
		Parent = frame,
	})
	local len: number = p.Length or 4
	for i = 0, count - 1 do
		-- a spoke as wide as the frame, turned; its stroke sits at the top end
		local spoke = Kit.new("Frame", {
			Name = "Spoke",
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Rotation = i * 360 / count,
			ZIndex = z,
			Parent = layer,
		})
		local major = p.Major and i % p.Major == 0
		local l = if major then len * 1.8 else len
		Kit.new("Frame", {
			Name = "Tick",
			BackgroundColor3 = p.Color or T.White,
			BackgroundTransparency = if major
				then math.max(0, (p.Transparency or 0.6) - 0.3)
				else p.Transparency or 0.6,
			BorderSizePixel = 0,
			Size = UDim2.fromOffset(p.Thick or 2, l),
			Position = UDim2.new(0.5, 0, 0, p.Inset or 3),
			AnchorPoint = Vector2.new(0.5, 0),
			ZIndex = z,
			Parent = spoke,
		})
	end
	return layer
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
local deepMade: { [string]: Color3 } = {}

function Kit.deep(color: Color3): Color3
	-- in the dark look the colour sinks into the panel; in the light one it gets a shade deeper,
	-- so white words still read on it
	local out = if Kit.ThemeName == "light" then color:Lerp(T.Dark, 0.26) else color:Lerp(T.Cream, 0.58)
	deepMade[out:ToHex()] = color
	return out
end

-- An accent as a colour for words on a surface: itself in the dark look, a shade deeper in the
-- light one, where a pastel would fade into the paper. Kit.text and Kit.title take it as Tint.
function Kit.tint(color: Color3): Color3
	return if Kit.ThemeName == "light" then color:Lerp(T.Dark, 0.36) else color
end

-- Switching looks -----------------------------------------------------------------------------------
-- Screens are built from T as they open, so a menu opened after the switch is simply right. What
-- is already up (the HUD, Build mode, whatever is open) is repainted: every colour on it that is
-- one of the old look's tokens becomes the new look's, a ribbon made by Kit.deep is made again,
-- and a grey nobody named (a mix of two tokens, say) has its lightness turned over. Colours
-- with some life in them (the accents, a villager's own colour) are left alone, and so is
-- anything named Swatch, a picture, and whatever sits under something marked KeepColors.

local themeHooks: { (string) -> () } = {}
local turnedBack: { [string]: Color3 } = {}

-- Calls fn(name) after every switch (for what paints itself: the creator's backdrop).
function Kit.onTheme(fn: (string) -> ())
	table.insert(themeHooks, fn)
end

-- Lightness turned over, hue and colourfulness kept: every channel moves by the same amount.
local function turnOver(c: Color3): Color3
	local r, g, b = c.R, c.G, c.B
	local k = 1 - (math.max(r, g, b) + math.min(r, g, b))
	return Color3.new(math.clamp(r + k, 0, 1), math.clamp(g + k, 0, 1), math.clamp(b + k, 0, 1))
end

local function repaint(inst: Instance, map: (Color3) -> Color3)
	if inst.Name == "Swatch" then
		-- a colour chip keeps its colour; only the thin line round it follows the look
		local rim = inst:FindFirstChild("Rim")
		if rim and rim:IsA("UIStroke") and not rim:GetAttribute("Follow") then
			rim.Color = map(rim.Color)
		end
		return
	end
	if inst:GetAttribute("KeepColors") or inst:IsA("ViewportFrame") then
		return
	end
	local any = inst :: any
	if inst:IsA("GuiObject") then
		inst.BackgroundColor3 = map(inst.BackgroundColor3)
		-- a shaded face is shaded again from its own colour in the new look (its two ends and
		-- slanted ends follow), rather than each end mapped on its own
		local base = inst:GetAttribute("Base")
		if type(base) == "string" then
			-- (a painted slab's colour is on its picture, a tile's in its two tones)
			Kit.paint(inst, map(Color3.fromHex(base)))
		else
			-- a plain face's thin line takes a deeper tone of its new colour
			follow(inst)
		end
		-- a row remembers the colour its words go back to when it is no longer picked
		local plain = inst:GetAttribute("Plain")
		if type(plain) == "string" then
			inst:SetAttribute("Plain", map(Color3.fromHex(plain)):ToHex())
		end
		-- and the colour it lies in when it isn't
		local rest = inst:GetAttribute("Rest")
		if type(rest) == "string" then
			inst:SetAttribute("Rest", map(Color3.fromHex(rest)):ToHex())
		end
		-- words in an accent (Kit.tint) are made again for the new look
		local tint = inst:GetAttribute("Tint")
		if type(tint) == "string" and (inst:IsA("TextLabel") or inst:IsA("TextButton")) then
			any.TextColor3 = Kit.tint(Color3.fromHex(tint))
			any.TextStrokeColor3 = map(any.TextStrokeColor3)
		elseif inst:IsA("TextLabel") or inst:IsA("TextButton") or inst:IsA("TextBox") then
			any.TextColor3 = map(any.TextColor3)
			any.TextStrokeColor3 = map(any.TextStrokeColor3)
			if inst:IsA("TextBox") then
				inst.PlaceholderColor3 = map(inst.PlaceholderColor3)
			end
		elseif inst:IsA("ImageLabel") or inst:IsA("ImageButton") then
			-- a line icon is one colour laid over its sheet; a picture keeps its own
			-- (Icons marks the icon's frame Mono; the picture in it is its child)
			-- and so is a painted line or texture (UI/Skin), marked Tinted
			if
				inst:GetAttribute("Mono")
				or inst:GetAttribute("Tinted")
				or (inst.Parent and inst.Parent:GetAttribute("Mono"))
			then
				any.ImageColor3 = map(any.ImageColor3)
			end
		elseif inst:IsA("ScrollingFrame") then
			inst.ScrollBarImageColor3 = map(inst.ScrollBarImageColor3)
		end
	elseif inst:IsA("UIStroke") then
		inst.Color = map(inst.Color)
	elseif inst:IsA("UIGradient") and inst.Name == "Wash" then
		local keys = {}
		for _, k in inst.Color.Keypoints do
			table.insert(keys, ColorSequenceKeypoint.new(k.Time, map(k.Value)))
		end
		inst.Color = ColorSequence.new(keys)
	end
	local shaded = inst:GetAttribute("Base") ~= nil and shadeOf(inst) ~= nil
	local painted = inst:GetAttribute("Painted") == true
	for _, c in inst:GetChildren() do
		-- a shaded face's gradient and slanted ends were just made again, and so was a painted
		-- slab's picture
		local done = (shaded and (c.Name == "Shade" or c.Name:sub(1, 6) == "Wedge_"))
			or (painted and c.Name == "Body")
			or (c:IsA("UIStroke") and c:GetAttribute("Follow") == true)
		if not done then
			repaint(c, map)
		end
	end
end

-- Puts the look called `name` ("dark" or "light") on: new screens build in it and what is up
-- is repainted. Returns false for a name it doesn't know.
function Kit.setTheme(name: string): boolean
	local to = Kit.Themes[name]
	if not to then
		return false
	end
	if name == Kit.ThemeName then
		return true
	end
	local exact: { [string]: Color3 } = {}
	for _, v in T :: { [string]: any } do
		if typeof(v) == "Color3" then
			exact[v:ToHex()] = v
		end
	end
	for key, color in to :: { [string]: Color3 } do
		exact[((T :: any)[key] :: Color3):ToHex()] = color
	end
	local deeps = deepMade
	deepMade = {}
	for key, color in to :: { [string]: Color3 } do
		(T :: any)[key] = color
	end
	Kit.ThemeName = name
	Icons.Glyph = T.Ink
	Icons.Hole = T.Paper
	for was, accent in deeps do
		exact[was] = Kit.deep(accent)
	end
	local back = turnedBack
	local made: { [string]: Color3 } = {}
	-- what this pass has already given out: a button hands its words' colour on to its label
	-- the moment it changes, and the label must not be turned a second time when its turn comes
	local given: { [string]: boolean } = {}
	local function map(c: Color3): Color3
		local key = c:ToHex()
		if given[key] then
			return c
		end
		local out = exact[key] or back[key]
		if not out then
			if math.max(c.R, c.G, c.B) - math.min(c.R, c.G, c.B) > 0.17 then
				return c
			end
			out = turnOver(c)
			made[out:ToHex()] = c
		end
		given[out:ToHex()] = true
		return out
	end
	turnedBack = made
	local home = if root then root.Parent else nil
	if home then
		for _, gui in home:GetChildren() do
			if gui:IsA("LayerCollector") then
				repaint(gui, map)
			end
		end
	end
	for _, fn in themeHooks do
		task.spawn(fn, name)
	end
	return true
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
			-- one bar across and the two arms of the other up to its edges, so no part of the sign
			-- is drawn twice and it's the one see-through colour all over (the user: "make this
			-- shape the same color around instead of having an intersecting color")
			local turn = rng:NextInteger(0, 40)
			local thick = size * 0.28
			piece(holder, size, thick, turn, true)
			local arm = (size - thick) / 2
			local along = math.rad(turn + 90)
			local reach = (thick + arm) / 2
			for _, side in { -1, 1 } do
				local a = piece(holder, arm, thick, turn + 90, false)
				a.Position = UDim2.new(0.5, side * math.cos(along) * reach, 0.5, side * math.sin(along) * reach)
			end
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
	-- a button with a leaning face keeps its words clear of the slanted ends: half an end more
	local face = inst:FindFirstChild("Face")
	local cap = if inst:GetAttribute("KitButton") and face then face:GetAttribute("Inset") else nil
	local x = px + (if type(cap) == "number" then math.ceil(cap / 2) else 0)
	local pad = Kit.new("UIPadding", {
		PaddingLeft = UDim.new(0, x),
		PaddingRight = UDim.new(0, x),
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
				f.Position = UDim2.fromOffset(-x + k, -y)
				f.Size = UDim2.new(1, x * 2 - k * 2, 1, y * 2 - lip)
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
		-- (no line round it: "for bubbles and text in rounded rectangles everywhere, remove the
		-- borders")
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
		TextColor3 = if p.Tint then Kit.tint(p.Tint) else p.Color or T.Ink,
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
	if p.Tint then
		label:SetAttribute("Tint", (p.Tint :: Color3):ToHex())
	end
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

-- Motion ---------------------------------------------------------------------------------------------
--
-- The user: "polish the ui and menu everywhere much further, along with button animations to be
-- more suitable, referencing zenless zone zero menus". Buttons used to grow on a spring, hop their
-- icon and wiggle, which read like a cartoon. Now they move the way that game's menus feel: quick
-- and exact. Under the pointer a light band sweeps once across the face (cut to its shape), a
-- small marker slides in at the leading edge, the face brightens a touch and grows by two or three
-- hundredths. A press dips it to 0.97 with a short flash; letting go settles it back with no
-- bounce. Nothing turns, wiggles or springs. It is all tweens, one per change and no loop per
-- button, and the layers a hover needs are only made the first time the pointer comes over. On a
-- touch screen nothing hovers, so a tap gets the dip and the flash.

Kit.Motion = {
	Hover = TweenInfo.new(0.16, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
	Leave = TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	Press = TweenInfo.new(0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	Settle = TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
	Flash = TweenInfo.new(0.26, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	Sweep = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	Glide = TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
	In = TweenInfo.new(0.32, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
	Out = TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
}
local M = Kit.Motion

-- Plays a tween at once and hands it back.
local function tween(inst: Instance, info: TweenInfo, goals: { [string]: any }): Tween
	local t = TweenService:Create(inst, info, goals)
	t:Play()
	return t
end
Kit.tween = tween

-- The same easing as `info`, starting `delay` seconds later.
local function later(info: TweenInfo, delay: number): TweenInfo
	local i = info :: any
	if type(i) == "table" then
		-- (the simulation's stand-in keeps what it was made with as a list)
		return TweenInfo.new(i[1], i[2], i[3], 0, false, delay)
	end
	return TweenInfo.new(info.Time, info.EasingStyle, info.EasingDirection, 0, false, delay)
end
Kit.later = later

local WHITE = Color3.new(1, 1, 1)
local HOVER_GLOW = 0.07 -- how much white a face takes under the pointer
local FLASH = 0.24 -- and in the moment it is pressed

local function touchOnly(): boolean
	return UserInputService.TouchEnabled and not UserInputService.MouseEnabled
end

-- Where a face's colour is drawn: a blob's Core, a card's Cut, or the face itself.
local function shapeOf(face: GuiObject): GuiObject
	if face:GetAttribute("Blob") then
		local core = face:FindFirstChild("Core", true)
		if core and core:IsA("GuiObject") then
			return core
		end
	end
	local cut = face:FindFirstChild("Cut")
	if cut and cut:IsA("GuiObject") then
		return cut
	end
	return face
end

local function alphaKey(layer: GuiObject): string
	return if layer:IsA("ImageLabel") then "ImageTransparency" else "BackgroundTransparency"
end

-- A white layer over a face's whole shape, under what is in it: the slab's painted picture again
-- for a leaning face, or a frame with the face's own corners. Made the first time and kept. Nil
-- where a slab fell back to plain wedges (a layer there would show the box).
local function layerOver(face: GuiObject, name: string): GuiObject?
	local host = shapeOf(face)
	local old = host:FindFirstChild(name)
	if old and old:IsA("GuiObject") then
		return old
	end
	local body = bodyOf(host)
	local layer: GuiObject
	if body then
		local img = Kit.new("ImageLabel", {
			Name = name,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Size = body.Size,
			Position = body.Position,
			ScaleType = body.ScaleType,
			SliceCenter = body.SliceCenter,
			SliceScale = body.SliceScale,
			ImageColor3 = WHITE,
			ImageTransparency = 1,
			ZIndex = -1,
			Parent = host,
		});
		(img :: any).ImageContent = (body :: any).ImageContent
		layer = img
	elseif host:FindFirstChild("Wedge_br") or host:FindFirstChild("Wedge_tr") then
		return nil
	else
		local f = Kit.new("Frame", {
			Name = name,
			BackgroundColor3 = WHITE,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Size = UDim2.fromScale(1, 1),
			ZIndex = 0,
			Parent = host,
		})
		local corner = host:FindFirstChildOfClass("UICorner")
		if corner then
			Kit.new("UICorner", { CornerRadius = corner.CornerRadius, Parent = f })
		end
		layer = f
	end
	-- a light laid over whatever colour is under it, in both looks
	layer:SetAttribute("KeepColors", true)
	return layer
end

-- A band of light runs once across a face, cut to its shape.
local function sweepOnce(face: GuiObject)
	local band = layerOver(face, "Sweep")
	if not band then
		return
	end
	local g = band:FindFirstChild("Band") :: UIGradient?
	if not g then
		g = Kit.new("UIGradient", {
			Name = "Band",
			Rotation = 16,
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.36, 1),
				NumberSequenceKeypoint.new(0.5, 0),
				NumberSequenceKeypoint.new(0.64, 1),
				NumberSequenceKeypoint.new(1, 1),
			}),
			Parent = band,
		})
	end
	local grad = g :: UIGradient;
	(band :: any)[alphaKey(band)] = 0.8
	grad.Offset = Vector2.new(-1, 0)
	tween(grad, M.Sweep, { Offset = Vector2.new(1, 0) })
end

-- A small chevron (">") of two rounded strokes, for the leading edge of a button. Its strokes
-- start clear; `px` is its height.
local function chevron(parent: Instance, color: Color3, px: number, z: number): Frame
	local holder = Kit.new("Frame", {
		Name = "Chevron",
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(px, px),
		AnchorPoint = Vector2.new(0.5, 0.5),
		ZIndex = z,
		Parent = parent,
	})
	holder:SetAttribute("KeepColors", true)
	local len = math.max(5, px * 0.7)
	local thick = math.max(2, math.floor(px * 0.2 + 0.5))
	for i, turn in { 45, -45 } do
		local stroke = Kit.new("Frame", {
			Name = "Stroke",
			BackgroundColor3 = color,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Size = UDim2.fromOffset(len, thick),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, (if i == 1 then -1 else 1) * len * 0.33),
			Rotation = turn,
			ZIndex = z,
			Parent = holder,
		})
		Kit.corner(stroke, "pill")
	end
	return holder
end
Kit.chevron = chevron

local function fadeKids(holder: Instance, info: TweenInfo, to: number)
	for _, c in holder:GetChildren() do
		if c:IsA("Frame") then
			tween(c, info, { BackgroundTransparency = to })
		end
	end
end

-- Corner brackets that close in on a tile under the pointer (made the first time).
local function focusBrackets(b: GuiObject, color: Color3): Frame
	local old = b:FindFirstChild("Focus")
	if old and old:IsA("Frame") then
		return old
	end
	local layer =
		Kit.brackets(b, { Name = "Focus", Corners = { "tl", "br" }, Arm = 9, Thick = 2, Inset = 0, Color = color })
	layer:SetAttribute("KeepColors", true)
	layer.ZIndex = 6
	for _, corner in layer:GetChildren() do
		if corner:IsA("Frame") then
			corner:SetAttribute("Home", corner.Position)
			-- they start a little in from the corners and clear, and close in from there
			local inward = if corner.Name == "tl" then 4 else -4
			corner.Position += UDim2.fromOffset(inward, inward)
			for _, arm in corner:GetChildren() do
				if arm:IsA("Frame") then
					arm.BackgroundTransparency = 1
				end
			end
		end
	end
	return layer
end

-- A ring that opens out round a round button under the pointer (made the first time).
local function focusRing(host: GuiObject, color: Color3): (Frame, UIStroke)
	local old = host:FindFirstChild("Focus")
	if old and old:IsA("Frame") then
		return old, old:FindFirstChildOfClass("UIStroke") :: UIStroke
	end
	local ring = Kit.new("Frame", {
		Name = "Focus",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		ZIndex = 0,
		Parent = host,
	})
	ring:SetAttribute("KeepColors", true)
	Kit.corner(ring, "round")
	local stroke = Kit.new("UIStroke", {
		Color = color,
		Thickness = 1.5,
		Transparency = 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = ring,
	})
	return ring, stroke
end

-- Gives a button the interface's motion. opts:
--   Kind    "pill" (a button with words: a chevron slides in at its left end), "slab" (a leaning
--           face: what is on it nudges along), "round" (a ring opens round it), "tile" (corner
--           brackets close in), "row" (the content nudges
--           right), "flat" (an icon over its name: the icon lifts and a short line grows under
--           the name), "plain" (no marker: a tab)
--   Face    what lights up and what the band sweeps across (found by name when not given:
--           Face, then Fill, then the button itself); false for nothing
--   Grow    how big it gets under the pointer (1.025; 1 for a row)
--   Dip     how small a press makes it (0.97)
--   Nudge   a list of things that move along under the pointer, NudgeX pixels (4)
--   Accent  the colour of the marker (yellow; the icon's own for "flat"), Ring for "round"
--   Sweep   false for no band
-- Touch players get the press and the flash, with nothing that needs a hover.
function Kit.press(b: GuiButton, opts: { [string]: any }?)
	if b:GetAttribute("Pressable") then
		return
	end
	b:SetAttribute("Pressable", true)
	local o = opts or {}
	local kind: string = o.Kind or "pill"
	local grow: number = o.Grow or (if kind == "row" or kind == "flat" then 1 else 1.025)
	local dip: number = o.Dip or (if kind == "row" then 0.985 else 0.97)
	local scale = b:FindFirstChild("Press")
	if not (scale and scale:IsA("UIScale")) then
		scale = Kit.new("UIScale", { Name = "Press", Parent = b })
	end
	local press = scale :: UIScale
	local over, down = false, false
	local function face(): GuiObject?
		if o.Face == false then
			return nil
		end
		local f = o.Face or b:FindFirstChild("Face") or b:FindFirstChild("Fill")
		if f and f:IsA("GuiObject") then
			return f
		end
		return b
	end
	local lit: GuiObject? = nil
	local function litLayer(): GuiObject?
		if lit and lit.Parent then
			return lit
		end
		local f = face()
		lit = if f then layerOver(f, "Lit") else nil
		return lit
	end
	-- what is nudged along, and where each rests
	local nudged: { [GuiObject]: UDim2 } = {}
	local function nudge(on: boolean)
		local list: { any } = o.Nudge or {}
		local dx: number = o.NudgeX or 4
		for _, g in list do
			if typeof(g) == "Instance" and g:IsA("GuiObject") then
				local home = nudged[g]
				if not home then
					home = g.Position
					nudged[g] = home
				end
				tween(g, if on then M.Hover else M.Leave, {
					Position = if on then (home :: UDim2) + UDim2.fromOffset(dx, o.NudgeY or 0) else home,
				})
			end
		end
	end
	local function marker(on: boolean)
		local info = if on then M.Hover else M.Leave
		if kind == "pill" then
			local mark = b:FindFirstChild("Chevron") :: Frame?
			if on and not mark then
				-- only where the words leave room at the round end
				local h = b.AbsoluteSize.Y
				local content = b:FindFirstChild("Content")
				local list = content and content:FindFirstChildOfClass("UIListLayout")
				local used = if list then list.AbsoluteContentSize.X else b.AbsoluteSize.X
				if h <= 0 or (b.AbsoluteSize.X - used) / 2 < h * 0.62 + 4 then
					return
				end
				local color: Color3 = if b:IsA("TextButton") then b.TextColor3 else T.White
				mark = chevron(b, color, math.floor(h * 0.3), b.ZIndex + 2)
				local m = mark :: Frame
				m:SetAttribute("Home", h * 0.42)
				m.Position = UDim2.new(0, h * 0.42 - 6, 0.5, 0)
			end
			if mark then
				local m = mark :: Frame
				local x: number = m:GetAttribute("Home") :: any or 12
				if b:IsA("TextButton") then
					for _, s in m:GetChildren() do
						if s:IsA("Frame") then
							s.BackgroundColor3 = b.TextColor3
						end
					end
				end
				tween(m, info, { Position = UDim2.new(0, if on then x else x - 6, 0.5, 0) })
				fadeKids(m, info, if on then 0 else 1)
			end
		elseif kind == "tile" then
			local layer = focusBrackets(b, o.Accent or T.Yellow)
			for _, corner in layer:GetChildren() do
				if corner:IsA("Frame") then
					local home = corner:GetAttribute("Home")
					if typeof(home) == "UDim2" then
						local inward = if corner.Name == "tl" then 4 else -4
						tween(corner, info, {
							Position = if on then home else home + UDim2.fromOffset(inward, inward),
						})
					end
					fadeKids(corner, info, if on then 0 else 1)
				end
			end
		elseif kind == "round" then
			local host = face() or b
			local ring, stroke = focusRing(host, o.Ring or T.Ink)
			tween(ring, info, { Size = if on then UDim2.new(1, 8, 1, 8) else UDim2.fromScale(1, 1) })
			tween(stroke, info, { Transparency = if on then 0.35 else 1 })
		elseif kind == "row" then
			-- (a row's hover is its nudge and its lift: no bar comes in at its left end any more,
			-- the user: "remove every bar behind text design like this")
			local _ = info
		elseif kind == "flat" then
			local line = b:FindFirstChild("Underline") :: Frame?
			if not line then
				local made = Kit.new("Frame", {
					Name = "Underline",
					BackgroundColor3 = o.Accent or T.Yellow,
					BorderSizePixel = 0,
					Size = UDim2.fromOffset(0, 3),
					-- a few pixels clear of the name, not touching it (the user: "make the bar
					-- lower when hovering")
					Position = UDim2.new(0.5, 0, 1, 5),
					AnchorPoint = Vector2.new(0.5, 1),
					ZIndex = 3,
					Parent = b,
				})
				made:SetAttribute("KeepColors", true)
				Kit.corner(made, "pill")
				line = made
			end
			tween(line :: Frame, info, { Size = UDim2.fromOffset(if on then 22 else 0, 3) })
		end
		nudge(on)
	end
	local function hover(on: boolean)
		over = on
		tween(press, if on then M.Hover else M.Leave, { Scale = if on then grow else 1 })
		local l = if on then litLayer() else lit
		if l then
			tween(l, if on then M.Hover else M.Leave, { [alphaKey(l)] = if on then 1 - HOVER_GLOW else 1 })
		end
		if on and o.Sweep ~= false and kind ~= "row" and kind ~= "flat" then
			local f = face()
			if f then
				sweepOnce(f)
			end
		end
		marker(on)
	end
	b.MouseEnter:Connect(function()
		if touchOnly() or over then
			return
		end
		hover(true)
	end)
	b.MouseLeave:Connect(function()
		down = false
		if over then
			hover(false)
		else
			tween(press, M.Leave, { Scale = 1 })
		end
	end)
	b.MouseButton1Down:Connect(function()
		down = true
		tween(press, M.Press, { Scale = dip })
		-- a short flash that fades
		local l = litLayer()
		if l then
			local key = alphaKey(l);
			(l :: any)[key] = 1 - FLASH
			tween(l, M.Flash, { [key] = if over then 1 - HOVER_GLOW else 1 })
		end
	end)
	local function settle()
		down = false
		tween(press, M.Settle, { Scale = if over then grow else 1 })
	end
	b.MouseButton1Up:Connect(settle)
	b.Activated:Connect(function()
		if down then
			settle()
		end
		-- a soft click (a tab's is smaller); `Sound` names another, false for none
		if o.Sound ~= false then
			Kit.sound(o.Sound or (if kind == "plain" then "tab" else "click"))
		end
	end)
end
local pressable = Kit.press

-- Things that come in one after another. A row, a card or a tile marks itself as it is made
-- (Kit.mark), and when a menu opens or its tab changes, what was made since then comes in: each
-- fades up out of what is behind it and slides a few pixels in from the side, a few hundredths of
-- a second after the one before.
local made = 0

-- Marks `g` as something that comes in with its menu.
function Kit.mark(g: GuiObject)
	made += 1
	g:SetAttribute("Born", made)
end

-- How many things have been marked so far (pass it to Kit.revealIn later).
function Kit.born(): number
	return made
end

-- The colour behind `g`: the nearest card or surface it lies on.
local function behindOf(g: Instance): Color3
	local cur = g.Parent
	while cur and not cur:IsA("LayerCollector") do
		if cur:IsA("GuiObject") then
			local cut = cur:FindFirstChild("Cut")
			if cut and cut:IsA("GuiObject") and cut.BackgroundTransparency < 0.5 then
				return cut.BackgroundColor3
			end
			if cur:IsA("Frame") and cur.BackgroundTransparency < 0.5 and cur.Name ~= "Dim" then
				return Kit.colorOf(cur)
			end
		end
		cur = cur.Parent
	end
	return T.Cream
end

-- The round corners `g` is drawn with (its own, its face's or its card's).
local function cornerOf(g: Instance): UDim?
	for _, name in { "Fill", "Face", "Cut" } do
		local f = g:FindFirstChild(name)
		local c = f and f:FindFirstChildOfClass("UICorner")
		if c then
			return c.CornerRadius
		end
	end
	local own = g:FindFirstChildOfClass("UICorner")
	return if own then own.CornerRadius else nil
end

-- Brings `items` in one after another. opts: Delay (before the first, 0), Step (between them,
-- 0.035), DX and DY (where they come from: 18 pixels to the right), Max (how many get it: 18; the
-- rest just show), Behind (the colour they fade up out of; found when not given).
function Kit.reveal(items: { GuiObject }, opts: { [string]: any }?)
	local o = opts or {}
	local step: number = o.Step or 0.035
	local first: number = o.Delay or 0
	local dx: number, dy: number = o.DX or 18, o.DY or 0
	for i, g in items do
		if i > (o.Max or 18) or not g.Parent then
			break
		end
		local at = first + (i - 1) * step
		local info = later(TweenInfo.new(0.26, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), at)
		-- what moves: the thing itself, or what is in it when a layout places it
		local laid = g.Parent:FindFirstChildOfClass("UIListLayout") or g.Parent:FindFirstChildOfClass("UIGridLayout")
		local movers: { GuiObject } = {}
		if laid then
			for _, c in g:GetChildren() do
				if c:IsA("GuiObject") then
					table.insert(movers, c)
				end
			end
		else
			table.insert(movers, g)
		end
		-- a veil in the colour behind it, over all of it, that clears
		local veil = Kit.new("Frame", {
			Name = "Veil",
			BackgroundColor3 = o.Behind or behindOf(g),
			BorderSizePixel = 0,
			Size = UDim2.fromScale(1, 1),
			ZIndex = 40,
			Parent = g,
		})
		veil:SetAttribute("KeepColors", true)
		local corner = cornerOf(g)
		if corner then
			Kit.new("UICorner", { CornerRadius = corner, Parent = veil })
		end
		if laid then
			table.insert(movers, veil)
		end
		for _, m in movers do
			local home = m.Position
			m.Position = home + UDim2.fromOffset(dx, dy)
			tween(m, info, { Position = home })
		end
		tween(veil, info, { BackgroundTransparency = 1 })
		task.delay(at + 0.3, function()
			veil:Destroy()
		end)
	end
end

-- Brings in what was marked inside `container` after `since` (Kit.born()), in the order it is
-- laid out: down a list, across a grid.
function Kit.revealIn(container: Instance, since: number, opts: { [string]: any }?)
	local found: { GuiObject } = {}
	local function walk(inst: Instance)
		local kids = inst:GetChildren()
		if inst:FindFirstChildOfClass("UIListLayout") or inst:FindFirstChildOfClass("UIGridLayout") then
			table.sort(kids, function(a, b)
				local la = if a:IsA("GuiObject") then a.LayoutOrder else 0
				local lb = if b:IsA("GuiObject") then b.LayoutOrder else 0
				return la < lb
			end)
		end
		for _, c in kids do
			if c:IsA("GuiObject") and c.Visible then
				local born = c:GetAttribute("Born")
				if type(born) == "number" and born > since then
					table.insert(found, c)
				end
				walk(c)
			end
		end
	end
	walk(container)
	Kit.reveal(found, opts)
end

-- Slides a picked pill over from one button to another: `to`'s face (named Face unless `name`
-- says) starts where `from` is and runs over to its own place. The buttons it passes are lifted
-- over it while it runs, so their words stay on top. Does nothing before the buttons are laid out.
function Kit.glide(from: GuiObject?, to: GuiObject, name: string?)
	local face = to:FindFirstChild(name or "Face")
	if not from or from == to or not (face and face:IsA("GuiObject")) then
		return
	end
	local w = from.AbsoluteSize.X
	if w <= 0 or to.AbsoluteSize.X <= 0 then
		return
	end
	local homePos = face:GetAttribute("GlidePos")
	local homeSize = face:GetAttribute("GlideSize")
	if typeof(homePos) ~= "UDim2" or typeof(homeSize) ~= "UDim2" then
		homePos, homeSize = face.Position, face.Size
		face:SetAttribute("GlidePos", homePos)
		face:SetAttribute("GlideSize", homeSize)
	end
	local pos, size = homePos :: UDim2, homeSize :: UDim2
	-- the picked one under the rest, so the pill runs under their words
	local parent = to.Parent
	if parent then
		local base = to:GetAttribute("GlideZ")
		if type(base) ~= "number" then
			base = to.ZIndex
		end
		for _, c in parent:GetChildren() do
			if c:IsA("GuiObject") and c ~= to and c.ZIndex == base then
				c:SetAttribute("GlideZ", base)
				c.ZIndex = (base :: number) + 1
			end
		end
		to:SetAttribute("GlideZ", base)
		to.ZIndex = base :: number
	end
	-- (what is measured on the screen is in its pixels; the face is placed in the interface's own,
	-- which differ by the screen's scale: a phone's is about half)
	local tall = to.Size.Y.Offset
	local ratio = if tall > 0 and to.AbsoluteSize.Y > 0 then to.AbsoluteSize.Y / tall else 1
	local dx = (from.AbsolutePosition.X - to.AbsolutePosition.X) / ratio
	-- (a leaning face is pulled in from its button's edges by its slanted ends)
	local inset = face:GetAttribute("Inset")
	local k: number = if type(inset) == "number" then inset else 0
	local fromFace = from:FindFirstChild(name or "Face")
	local span = if fromFace
			and fromFace:IsA("GuiObject")
			and fromFace.AbsoluteSize.X > 0
		then fromFace.AbsoluteSize.X / ratio
		else w / ratio - k * 2
	face.Position = UDim2.new(pos.X.Scale, pos.X.Offset + dx, pos.Y.Scale, pos.Y.Offset)
	face.Size = UDim2.new(0, span, size.Y.Scale, size.Y.Offset)
	tween(face, M.Glide, { Position = pos, Size = size })
end

-- Where a menu goes while it closes: a screen of its own beside the interface, at the same scale,
-- so what is closing is out of the way of anything that looks for the menu by name.
local leaving: ScreenGui? = nil
local function leavingGui(): ScreenGui
	if leaving and leaving.Parent then
		return leaving
	end
	local gui = Kit.root()
	local g = Instance.new("ScreenGui")
	g.Name = "CatalogTownClosing"
	g.ResetOnSpawn = false
	g.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	g.IgnoreGuiInset = gui.IgnoreGuiInset
	g.DisplayOrder = gui.DisplayOrder + 1
	local scale = Instance.new("UIScale")
	scale.Name = "Scale"
	scale.Parent = g
	local main = gui:FindFirstChild("Scale")
	if main and main:IsA("UIScale") then
		scale.Scale = main.Scale
		main:GetPropertyChangedSignal("Scale"):Connect(function()
			scale.Scale = main.Scale
		end)
	end
	g.Parent = gui.Parent
	leaving = g
	return g
end

-- A button's face: a leaning slab in one colour with its four points rounded, shaded across (the
-- user, of the pill shaped Claim button: "make these type of shapes everywhere parallograms instead
-- of rounded rectangles"). The button's own background stays clear; `height` is its height in
-- pixels when its Size doesn't say (a button sized by scale).
local function chunky(b: GuiButton, color: Color3, _radius: any, lip: number, height: number?, sharp: string?)
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
	Kit.slant(face, if height and height > 0 then height - lip else nil, nil, nil, sharp)
	Kit.shade(face)
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
	chunky(b, color, p.Radius or 12, lip, size.Y.Offset, p.Sharp)
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
	pressable(b, p.Press) -- (Press: options for Kit.press, e.g. { Grow = 1 } for a button set flush in a slab)
	if onClick then
		b.Activated:Connect(onClick)
	end
	-- a button that sizes itself to its words gets its width set from them instead (Kit.fitWidth:
	-- its face and content are sized by share of it)
	if b.AutomaticSize == Enum.AutomaticSize.X or b.AutomaticSize == Enum.AutomaticSize.XY then
		Kit.fitWidth(b, b)
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
			Centre = true,
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
		-- a small leaning tag, its slanted ends standing out past the words (the room round the
		-- words is on the words, so the painted slab under them stays put)
		Kit.slant(tag, tagH, true)
		local words = Kit.new("TextLabel", {
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
		Kit.new("UIPadding", { PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6), Parent = words })
	end
	pressable(b, { Kind = "round", Ring = p.Ring })
	if onClick then
		b.Activated:Connect(onClick)
	end
	return b
end

-- A chunky progress bar: a dark outlined track with a shaded fill. props: Parent, Size, Position,
-- LayoutOrder, Track (the empty part's colour), Ticks (notches cutting it into that many even
-- parts). Returns the track and the fill.
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
	-- Ticks = n cuts it into n even parts with thin notches across it
	local n: number = props.Ticks or 0
	for i = 1, n - 1 do
		Kit.new("Frame", {
			Name = "Notch",
			BackgroundColor3 = T.Black,
			BackgroundTransparency = 0.45,
			BorderSizePixel = 0,
			Size = UDim2.new(0, 2, 1, 0),
			Position = UDim2.fromScale(i / n, 0),
			AnchorPoint = Vector2.new(0.5, 0),
			ZIndex = 3,
			Parent = track,
		})
	end
	return track, fill
end

-- A red dot on a button's corner, for something waiting to be seen. The user: "Remove the ! In
-- the alert, just the red dot is enough. Make the red dot pulse slowly". So no mark and no
-- number, only a thin dark ring so it shows on any colour.
function Kit.badge(parent: GuiObject): Frame
	local f = Kit.frame({
		Name = "Badge",
		Parent = parent,
		Size = UDim2.fromOffset(13, 13),
		Position = UDim2.new(1, -8, 0, 6),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Color = T.Red,
		Radius = "round",
		ZIndex = (parent.ZIndex or 1) + 5,
	})
	f:SetAttribute("KeepColors", true)
	Kit.rim(f, T.Dark, 2)
	-- a slow pulse about its middle: it swells and settles, a couple of seconds a beat
	local pulse = Kit.new("UIScale", { Name = "Pulse", Parent = f })
	TweenService
		:Create(pulse, TweenInfo.new(1.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Scale = 1.3 })
		:Play()
	return f
end

-- A leaning marker: a small slab in one colour, leaning as every slab does, its points softly
-- rounded, with an icon on it. It is what sits at the left end of a bar (a quest, a list row, a
-- notice, the event prompt, a hint) in place of a round one. The user, with a picture of a small
-- purple leaning square with a case on it: "make it such that all icons that are at the left of
-- every bar becomes like this instead of a circle. this includes the quest bars too". props:
-- Parent, Size (its height in pixels), Width (its box's width; about square if left out),
-- Sharp ("right": that end a clean cut, for a marker set flush into a bar's end, as the quests'
-- Claim button is: "make them fill it up with no gaps, just like the claim button"), Position,
-- AnchorPoint, Color, Icon, IconColor, Text (a letter or two in place of an icon), TextColor,
-- Name, ZIndex, LayoutOrder. Returns its frame, whose box is the whole shape, ends and all.
function Kit.leanMark(props: { [string]: any }?): Frame
	local p = props or {}
	local px: number = p.Size or 28
	local color: Color3 = p.Color or T.Yellow
	local z: number = p.ZIndex or 1
	local cap = math.clamp(math.floor(px * Kit.Lean + 0.5), 4, 20)
	-- about as wide across its middle as it is tall, so it reads as a leaning square
	local w: number = p.Width or (math.floor(px * 0.86 + 0.5) + cap)
	local holder = Kit.new("Frame", {
		Name = p.Name or "Marker",
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(w, px),
		Position = p.Position or UDim2.new(),
		AnchorPoint = p.AnchorPoint or Vector2.zero,
		ZIndex = z,
		LayoutOrder = p.LayoutOrder or 0,
		Parent = p.Parent,
	})
	local face = Kit.new("Frame", {
		Name = "Face",
		BackgroundColor3 = color,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		ZIndex = z,
		Parent = holder,
	})
	face:SetAttribute("KeepColors", true)
	Kit.slant(face, px, nil, nil, p.Sharp)
	Kit.shade(face, color)
	local light = color.R * 0.3 + color.G * 0.59 + color.B * 0.11 > 0.5
	if p.Icon and Icons.has(p.Icon) then
		local ipx = math.floor(px * 0.58)
		Icons.make(p.Icon, ipx, {
			Name = "IconArt",
			Parent = holder,
			Position = UDim2.new(0.5, -ipx / 2 + (p.IconX or 0), 0.5, -ipx / 2),
			Color = p.IconColor or (if light then T.Dark else T.White),
			Hole = color,
			-- (in one colour, the coin too: its gold doesn't read on a yellow block)
			Mono = true,
			Centre = true,
			ZIndex = z + 1,
		})
	elseif p.Text then
		Kit.new("TextLabel", {
			Name = "Mark",
			Text = p.Text,
			BackgroundTransparency = 1,
			Font = Kit.Fonts.Title,
			TextSize = math.floor(px * 0.7),
			TextColor3 = p.TextColor or (if light then T.Dark else T.White),
			Size = UDim2.fromScale(1, 1),
			ZIndex = z + 1,
			Parent = holder,
		})
	end
	return holder
end

-- A marker that fills the left end of a leaning bar, flush with it: as tall as the bar, its
-- slanted left edge on the bar's own and its right end a clean cut into the bar (the user: "Make
-- them fill it up with no gaps, just like the claim button"). `bar` is the slab's face (made by
-- Kit.slant), `outside` whether its ends stand out past its box (Kit.darkPill's do) or sit inside
-- it (a row's, a button's). The marker goes in `parent` (the bar's frame or a sibling covering
-- the same box) at `X` across, where the bar's face box starts. props as Kit.leanMark, less Size
-- and Position, and Hidden: how much of the bar's left end is off the screen (the quests come out
-- of the screen's left edge, their whole slanted end out of sight), so the marker reaches that
-- much further in and its icon sits in the middle of what shows. Returns the marker and how far in
-- from the bar's box its right end reaches at the middle of its height (where words after it may
-- start, plus a gap).
function Kit.flushMark(
	parent: GuiObject,
	bar: GuiObject,
	tall: number,
	outside: boolean,
	props: { [string]: any }
): (Frame, number)
	local cap: number = bar:GetAttribute("Cap") :: any or math.clamp(math.floor(tall * Kit.Lean + 0.5), 4, 20)
	local p = table.clone(props)
	local hidden: number = p.Hidden or 0
	local w = math.floor(tall * 0.8 + 0.5) + cap + hidden
	local x0: number = p.X or 0
	p.X, p.Hidden = nil, nil
	p.IconX = hidden * 0.25
	p.Size = tall
	p.Width = w
	p.Sharp = "right"
	-- a bar whose ends stand out past its box starts one end further left
	local left = if outside then x0 - cap else x0
	p.Position = UDim2.new(0, left, 0.5, 0)
	p.AnchorPoint = Vector2.new(0, 0.5)
	local mark = Kit.leanMark(p)
	mark.Parent = parent
	return mark, left + w - cap / 2
end

-- A round marker: a disc in one colour with an icon on it, in a thin dark ring (what a diamond
-- was in the look before: a stat's mark, a tick in a ring, a pin on the map). props: Parent, Size
-- (pixels across), Position, AnchorPoint, Color, Icon (an icon name), IconColor, Ring (false for
-- no ring, or its colour), Name, ZIndex, LayoutOrder, Lean (true: the leaning marker at the left
-- end of a bar instead, Kit.leanMark). Returns the disc.
function Kit.disc(props: { [string]: any }?): Frame
	local p = props or {}
	if p.Lean then
		return Kit.leanMark(p)
	end
	local px: number = p.Size or 28
	local color: Color3 = p.Color or T.Yellow
	local z: number = p.ZIndex or 1
	local f = Kit.new("Frame", {
		Name = p.Name or "Marker",
		BackgroundColor3 = color,
		BorderSizePixel = 0,
		Size = UDim2.fromOffset(px, px),
		Position = p.Position or UDim2.new(),
		AnchorPoint = p.AnchorPoint or Vector2.zero,
		ZIndex = z,
		LayoutOrder = p.LayoutOrder or 0,
		Parent = p.Parent,
	})
	Kit.corner(f, "round")
	if p.Ring ~= false then
		Kit.rim(f, if typeof(p.Ring) == "Color3" then p.Ring else T.Dark, math.max(1.5, px / 16), 0.5)
	end
	if p.Icon and Icons.has(p.Icon) then
		local ipx = math.floor(px * 0.6)
		local light = color.R * 0.3 + color.G * 0.59 + color.B * 0.11 > 0.5
		Icons.make(p.Icon, ipx, {
			Name = "IconArt",
			Parent = f,
			Position = UDim2.new(0.5, -ipx / 2, 0.5, -ipx / 2),
			Color = p.IconColor or (if light then T.Dark else T.White),
			Hole = color,
			Mono = true,
			Centre = true,
			ZIndex = z + 1,
		})
	end
	return f
end

-- A hint: a strip in a dull khaki with a dark round badge at its left end and dark words (a
-- note under a panel on how something works). props: Parent, Size, Position, AnchorPoint,
-- LayoutOrder, Name, TextSize, ZIndex. It is as tall as its words need. Returns the strip and
-- its label.
function Kit.hint(text: string, props: { [string]: any }?): (Frame, TextLabel)
	local p = props or {}
	local z: number = p.ZIndex or 1
	local strip = Kit.new("Frame", {
		Name = p.Name or "Hint",
		BackgroundColor3 = Color3.fromRGB(132, 126, 96),
		BackgroundTransparency = 0.12,
		BorderSizePixel = 0,
		Size = p.Size or UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Position = p.Position or UDim2.new(),
		AnchorPoint = p.AnchorPoint or Vector2.zero,
		LayoutOrder = p.LayoutOrder or 0,
		ZIndex = z,
		Parent = p.Parent,
	})
	-- khaki with dark words in both looks
	strip:SetAttribute("KeepColors", true)
	Kit.corner(strip, 10)
	Kit.new("UIPadding", {
		PaddingLeft = UDim.new(0, 44),
		PaddingRight = UDim.new(0, 14),
		PaddingTop = UDim.new(0, 8),
		PaddingBottom = UDim.new(0, 8),
		Parent = strip,
	})
	-- a dark leaning marker with a "!" at its left end
	Kit.leanMark({
		Name = "Badge",
		Parent = strip,
		Size = 22,
		Position = UDim2.new(0, -34, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		Color = T.Dark,
		Text = "!",
		TextColor = Color3.fromRGB(190, 184, 150),
		ZIndex = z + 1,
	})
	local label = Kit.new("TextLabel", {
		Name = "Text",
		Text = text,
		BackgroundTransparency = 1,
		Font = Kit.Fonts.Body,
		TextSize = p.TextSize or 15,
		TextColor3 = T.Dark,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		ZIndex = z + 1,
		Parent = strip,
	})
	return strip, label
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
	-- the glass is dark in both looks, so what is on it keeps its colours through a switch
	f:SetAttribute("KeepColors", true)
	-- a leaning slab: its slanted ends stand out past the box, so what is in it keeps its room
	-- (Flip leans it the other way: "\\" in place of "/")
	local h = if p.Size then (p.Size :: UDim2).Y.Offset else 40
	Kit.slant(f, h, true, p.Flip == true)
	-- dots growing toward one end (Tone = false for none, Side = "left" to turn them round)
	local w = if p.Size then (p.Size :: UDim2).X.Offset else 0
	Kit.detail(f, {
		Tone = if p.Tone == false then false else nil,
		Side = p.Side,
		ToneWidth = p.ToneWidth or (if w > 0 then math.min(132, math.floor(w * 0.45)) else nil),
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

-- A round badge with a small word over a big number (the town's level): a dark disc in a ring
-- of the accent with a thin line inside it. (It was a hexagon, and the name has stayed.) props:
-- Parent, Position, Size (px), Color, Label, ZIndex. Returns the badge and its number label.
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
	-- it sits over the 3D view, dark in both looks
	holder:SetAttribute("KeepColors", true)
	-- a soft glow behind the badge (a radial gradient), so the town's level catches the eye
	Kit.halo(holder, math.floor(px * 1.7), p.Glow or T.Yellow, 0.5)
	-- a dark disc in a ring of the colour, with a thin line inside the ring
	local disc = Kit.new("Frame", {
		Name = "Disc",
		BackgroundColor3 = T.Glass,
		BorderSizePixel = 0,
		Size = UDim2.fromOffset(px - 8, px - 8),
		Position = UDim2.fromOffset(4, 4),
		ZIndex = z,
		Parent = holder,
	})
	Kit.corner(disc, "round")
	Kit.rim(disc, p.Color or T.Blue, 4)
	local inner = Kit.new("Frame", {
		Name = "Inner",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -8, 1, -8),
		Position = UDim2.fromOffset(4, 4),
		ZIndex = z,
		Parent = disc,
	})
	Kit.corner(inner, "round")
	Kit.rim(inner, T.White, 1, 0.82)
	-- the marks of a dial round the inside of the ring, a longer one at each quarter
	Kit.ticks(inner, 24, { Major = 6, Length = 3, Inset = 3, Thick = 2, Transparency = 0.72, ZIndex = z })
	Kit.new("TextLabel", {
		Name = "Label",
		Text = p.Label or "LEVEL",
		BackgroundTransparency = 1,
		Font = Kit.Fonts.Title,
		TextSize = math.floor(px * 0.15),
		TextColor3 = Color3.fromRGB(206, 206, 210),
		Size = UDim2.new(1, 0, 0, px * 0.2),
		Position = UDim2.fromScale(0, 0.2),
		ZIndex = z + 1,
		Parent = holder,
	})
	local number = Kit.new("TextLabel", {
		Name = "Value",
		Text = value,
		BackgroundTransparency = 1,
		Font = Kit.Fonts.Title,
		TextSize = math.floor(px * 0.42),
		TextColor3 = T.White,
		Size = UDim2.new(1, 0, 0, px * 0.46),
		Position = UDim2.fromScale(0, 0.35),
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
	local art = Icons.make(icon, px, {
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
	-- the icon lifts and a short line in its colour grows under the name
	pressable(b, { Kind = "flat", Face = false, Nudge = { art }, NudgeX = 0, NudgeY = -3, Accent = p.Color })
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
	b:SetAttribute("KeepColors", true)
	Kit.corner(b, "circle")
	Kit.rim(b, T.White, 1.5, 0.8)
	local ipx = math.floor(px * 0.56)
	Icons.make(icon, ipx, {
		Name = "IconArt",
		Parent = b,
		Position = UDim2.new(0.5, -ipx / 2, 0.5, -ipx / 2),
		Color = T.White,
		Hole = T.Glass,
		Centre = true,
	})
	-- (the dark glass is the same in both looks, so its ring is white in both)
	pressable(b, { Kind = "round", Ring = T.White })
	if onClick then
		b.Activated:Connect(onClick)
	end
	return b
end

-- The big main action button: a leaning slab with a big icon in its own colour and bold words
-- (Build). props: Parent, Size, Position, AnchorPoint, Color, IconColor, TextSize, TextColor
-- (white with an outline by default; give the words' own colour for a slab in a surface colour,
-- and they get no outline), Detail (what Kit.detail puts on the slab).
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
		Slant = size.Y.Offset,
		Estimate = Vector2.new(size.X.Offset, size.Y.Offset),
	})
	local core = face:FindFirstChild("Core", true)
	if core and core:IsA("Frame") then
		-- shaded across, with dots toward its far end
		Kit.shade(core, color)
		Kit.detail(core, p.Detail or { Tone = T.Dark, ToneAlpha = 0.86, ToneWidth = 150 })
	end
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
		TextColor3 = p.TextColor or T.White,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, -(ipx + h * 0.5), 1, 0),
		Position = UDim2.fromOffset(ipx + math.floor(h * 0.5), 0),
		ZIndex = 3,
		Parent = b,
	})
	if not p.TextColor then
		Kit.outlineText(label, darker(color, 0.62), 1.5)
	end
	-- under the pointer the band sweeps along the slab and the icon and words move on a little
	pressable(b, { Kind = "slab", Grow = 1.02, Nudge = { label }, NudgeX = 5 })
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
-- the parts, and they are what is taken; the drawing is Catalog Town's own (its font, its colours,
-- its plain rounded shapes), with none of that game's art, slanted tabs or patterns.

-- The rim round a panel, a row or a tab bar: the same shape a few pixels bigger in another
-- shade behind it, so the thing sits in a bezel. (A second shape, not a stroke.)
local RIM = 3

-- A row for lists: a pill, lighter than the panel it lies on, with a thin line round it. props:
-- Parent, Size, LayoutOrder, Name, Title, Sub (a smaller line under the title), Marker (an icon
-- name: a round badge at the left end), MarkerColor, Right (words at the right end), Selected,
-- Sunk (a row that is over and done with), Height, LeftSpace and RightSpace (room kept clear of
-- the words at either end, for something of your own). With onClick it is a button. Returns the
-- row and the box inside it (put more in it: it fills the row).
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
	local rest = if p.Sunk then T.PaperDark else T.Card
	-- a leaning slab, its points rounded, like every other control with words on it
	local face = Kit.new("Frame", {
		Name = "Fill",
		BackgroundColor3 = rest,
		BorderSizePixel = 0,
		Size = UDim2.new(1, -2, 1, -2),
		Position = UDim2.fromOffset(1, 1),
		Parent = row,
	})
	local cap = Kit.slant(face, h - 2)
	Kit.shade(face)
	row:SetAttribute("Cap", cap)
	local inner = Kit.new("Frame", {
		Name = "Inside",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 2,
		Parent = row,
	})
	-- how far in its slanted end pushes what is on it (at the middle of its height, half an end)
	local lean = math.ceil(cap / 2) + 2
	local left = lean + 14
	if p.Marker then
		-- a marker filling the bar's left end, flush with its slanted edge (in the row itself,
		-- not on what nudges under the pointer, so it never leaves its edge)
		local _, reach = Kit.flushMark(row, face, h - 2, false, {
			Name = "Marker",
			X = 1,
			Color = p.MarkerColor or T.Yellow,
			Icon = if Icons.has(p.Marker) then p.Marker else nil,
			IconColor = T.Dark,
			ZIndex = 2,
		})
		left = math.ceil(reach) + 12
	end
	if p.LeftSpace then
		left = p.LeftSpace + lean
	end
	local right = (if p.Right then 150 else 10) + lean
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
		local right = Kit.new("TextLabel", {
			Name = "Right",
			Text = p.Right,
			BackgroundTransparency = 1,
			Font = Kit.Fonts.Title,
			TextSize = 16,
			TextColor3 = if p.RightColor then Kit.tint(p.RightColor) else T.InkSoft,
			TextXAlignment = Enum.TextXAlignment.Right,
			Size = UDim2.new(0, 130, 1, 0),
			Position = UDim2.new(1, -(134 + lean + 12), 0, 0),
			ZIndex = 2,
			Parent = inner,
		})
		if p.RightColor then
			right:SetAttribute("Tint", (p.RightColor :: Color3):ToHex())
		end
	end
	row:SetAttribute("Lean", lean)
	row:SetAttribute("Rest", rest:ToHex())
	if p.Selected then
		Kit.setRowSelected(row, true)
	end
	if onClick and row:IsA("TextButton") then
		row.Activated:Connect(onClick)
		-- under the pointer: what is on it moves right a little
		pressable(row, { Kind = "row", Face = face, Nudge = { inner }, NudgeX = 4 })
	end
	-- it comes in with its menu
	Kit.mark(row)
	return row, inner
end

-- The picked row of a list is yellow, with dark words (and the others go back to their own).
function Kit.setRowSelected(row: GuiObject, on: boolean)
	local face = row:FindFirstChild("Fill")
	if face and face:IsA("Frame") then
		local rest = row:GetAttribute("Rest")
		Kit.paint(face, if on then T.Yellow elseif type(rest) == "string" then Color3.fromHex(rest) else T.Card)
		-- the picked row carries a band of dark hatching toward its right end, fading out to the
		-- left, inside its straight part
		local band = face:FindFirstChild("PickedHatch")
		if on and not band then
			local h = if row.Size.Y.Offset > 0 then row.Size.Y.Offset else 58
			local made = Kit.hatch({
				Name = "PickedHatch",
				Parent = face,
				Size = UDim2.fromOffset(96, math.max(8, h - 16)),
				Position = UDim2.new(1, -4, 0.5, 0),
				AnchorPoint = Vector2.new(1, 0.5),
				Color = T.Dark,
				Transparency = 0.86,
				Fade = "left",
				ZIndex = 1,
			})
			if made then
				made:SetAttribute("KeepColors", true)
			end
		elseif not on and band then
			band:Destroy()
		end
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

-- How wide a line of words is, as the engine measures it, or nil where it can't (the previews).
function Kit.measure(text: string, size: number, font: Enum.Font?): number?
	if text == "" then
		return 0
	end
	local ok, bounds = pcall(function()
		return game:GetService("TextService"):GetTextSize(text, size, font or Kit.Fonts.Title, Vector2.new(4000, 400))
	end)
	if ok and typeof(bounds) == "Vector2" and bounds.X > 0 then
		return math.ceil(bounds.X)
	end
	return nil
end

-- How wide a line of words is (a reckoning by its letters where the engine can't measure it). For
-- sizing things by their words without AutomaticSize.
function Kit.textWidth(text: string, size: number, font: Enum.Font?): number
	return Kit.measure(text, size, font) or math.ceil(#text * size * 0.56)
end

-- Stops `frame` sizing itself across and sets its width from the words of `label` (measured), the
-- paddings on the two of them and `extra`, again whenever the words change. In the game a frame that
-- sizes itself, laid out in a list, with something in it sized by share of it, grows to the size
-- of the list (the Villagers menu's tabs ran its whole width, a notice came out half the screen
-- tall). Where the words can't be measured (the previews) it is left to size itself.
function Kit.fitWidth(frame: GuiObject, label: GuiObject, extra: number?)
	local function padOf(inst: Instance): number
		local pad = inst:FindFirstChildOfClass("UIPadding")
		return if pad then pad.PaddingLeft.Offset + pad.PaddingRight.Offset else 0
	end
	local function fit()
		local l = label :: any
		local w = Kit.measure(l.Text, l.TextSize, l.Font)
		if not w then
			return
		end
		local total = w + padOf(frame) + (if label ~= frame then padOf(label) else 0) + (extra or 0)
		if frame.AutomaticSize == Enum.AutomaticSize.XY then
			frame.AutomaticSize = Enum.AutomaticSize.Y
		elseif frame.AutomaticSize == Enum.AutomaticSize.X then
			frame.AutomaticSize = Enum.AutomaticSize.None
		end
		frame.Size = UDim2.new(0, math.ceil(total), frame.Size.Y.Scale, frame.Size.Y.Offset)
	end
	(label :: any):GetPropertyChangedSignal("Text"):Connect(fit)
	-- (once whoever made it has put its paddings on)
	task.defer(fit)
end

-- Tabs in one bar: a dark well shaped like a pill with a thin line round it, the picked tab a
-- yellow pill with dark words. `list` is { { id, name } }; onSelect(id) when one is picked.
-- props: Parent, Position, AnchorPoint, Height, TextSize. Returns the bar and select(id).
function Kit.segments(
	list: { { id: string, name: string } },
	onSelect: (string) -> (),
	props: { [string]: any }?
): (Frame, (string) -> ())
	local p = props or {}
	local h: number = p.Height or 46
	-- Nothing in the bar sizes itself: every width is worked out from the words here. (A tab sized
	-- round its words with its yellow slab sized by share of it grew into the slab in the game,
	-- until the two tabs ran the menu's whole width, under its way back: the user, "the abouts and
	-- friends tabs seem to overlap the back button".)
	local textSize: number = p.TextSize or 18
	local inner = RIM + 2 -- (and the slanted ends' share, below)
	local bar = Kit.new("Frame", {
		Name = "Tabs",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.fromOffset(0, h),
		Position = p.Position or UDim2.new(),
		AnchorPoint = p.AnchorPoint or Vector2.zero,
		LayoutOrder = p.LayoutOrder or 0,
		Parent = p.Parent,
	})
	local well = Kit.new("Frame", {
		Name = "Well",
		BackgroundColor3 = T.PaperDark,
		BorderSizePixel = 0,
		Size = UDim2.new(1, -2, 1, -2),
		Position = UDim2.fromOffset(1, 1),
		Parent = bar,
	})
	-- a leaning well, the picked tab a leaning slab in it
	local wellCap = Kit.slant(well, h - 2)
	local side = inner + math.ceil(wellCap / 3)
	local holder = Kit.new("Frame", {
		Name = "Row",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 2,
		Parent = bar,
	})
	Kit.new("UIPadding", {
		PaddingLeft = UDim.new(0, side),
		PaddingRight = UDim.new(0, side),
		PaddingTop = UDim.new(0, inner),
		PaddingBottom = UDim.new(0, inner),
		Parent = holder,
	})
	Kit.list(holder, 2, true)
	local buttons: { [string]: TextButton } = {}
	local faces: { [string]: Frame } = {}
	local labels: { [string]: TextLabel } = {}
	local picked: string? = nil
	-- the yellow pill slides over from the tab that was picked to the new one
	local function select(id: string)
		local was = picked
		picked = id
		for bid, b in buttons do
			local on = bid == id
			Kit.paint(faces[bid], nil, if on then 0 else 1)
			local hover = b:FindFirstChild("Hover")
			if hover and hover:IsA("Frame") then
				Kit.paint(hover, nil, 1)
			end
			tween(labels[bid], M.Hover, { TextColor3 = if on then T.Dark else T.Ink })
			b:SetAttribute("Selected", on)
		end
		if was and was ~= id and buttons[was] and buttons[id] then
			Kit.glide(buttons[was], buttons[id])
		end
	end
	local th = h - RIM * 2 - 4
	local across = side * 2 + 2 * math.max(0, #list - 1)
	for i, t in list do
		local tw = Kit.textWidth(t.name, textSize, Kit.Fonts.Title) + 44
		across += tw
		local b = Kit.new("TextButton", {
			Name = t.name,
			Text = "",
			AutoButtonColor = false,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Size = UDim2.fromOffset(tw, th),
			LayoutOrder = i,
			ZIndex = 2,
			Parent = holder,
		})
		Kit.new("UIPadding", { PaddingLeft = UDim.new(0, 22), PaddingRight = UDim.new(0, 22), Parent = b })
		labels[t.id] = Kit.new("TextLabel", {
			Name = "Label",
			Text = t.name,
			Font = Kit.Fonts.Title,
			TextSize = textSize,
			TextColor3 = T.Ink,
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			ZIndex = 4,
			Parent = b,
		})
		-- the yellow slab behind the picked tab's words (it reaches back over the padding)
		local face = Kit.new("Frame", {
			Name = "Face",
			BackgroundColor3 = T.Yellow,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 44, 1, 0),
			Position = UDim2.fromOffset(-22, 0),
			ZIndex = 3,
			Parent = b,
		})
		Kit.slant(face, th)
		Kit.shade(face)
		buttons[t.id] = b
		faces[t.id] = face
		-- under the pointer a tab that isn't picked lifts a faint pill of its own, and a press
		-- dips it
		local hover = Kit.new("Frame", {
			Name = "Hover",
			BackgroundColor3 = T.Ink,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 44, 1, 0),
			Position = UDim2.fromOffset(-22, 0),
			ZIndex = 2,
			Parent = b,
		})
		Kit.slant(hover, th)
		b.MouseEnter:Connect(function()
			if picked ~= t.id and not touchOnly() then
				Kit.fade(hover, M.Hover, 0.9)
			end
		end)
		b.MouseLeave:Connect(function()
			Kit.fade(hover, M.Leave, 1)
		end)
		pressable(b, { Kind = "plain", Face = false, Grow = 1, Dip = 0.96 })
		b.Activated:Connect(function()
			select(t.id)
			onSelect(t.id)
		end)
	end
	bar.Size = UDim2.fromOffset(across, h)
	if list[1] then
		select(list[1].id)
	end
	return bar, select
end

-- A tile: an icon over its name on a rounded square, the name on a deeper band across the
-- bottom (a category, a tool). props: Parent, Size, LayoutOrder, Name, Color, TextColor,
-- TextSize. Kit.setButtonColor recolours it.
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
		Size = UDim2.new(1, -4, 1, -2),
		Position = UDim2.fromOffset(2, 1),
		Parent = b,
	})
	Kit.corner(face, 9)
	footShade(face, color)
	-- (no line round it: the user, of a tile with one, "remove the borders around the rectangles")
	local content = Kit.new("Frame", {
		Name = "Content",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 2,
		Parent = b,
	})
	local h = size.Y.Offset
	local foot = math.floor((h - 2) * (1 - FOOT) + 0.5)
	local ipx = math.floor(h * 0.4)
	if Icons.has(icon) then
		Icons.make(icon, ipx, {
			Name = "IconArt",
			Parent = content,
			Position = UDim2.new(0.5, -ipx / 2, 0, math.floor((h - foot - ipx) / 2)),
			Color = textColor,
			Hole = color,
			Centre = true,
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
		Size = UDim2.new(1, -12, 0, foot),
		Position = UDim2.new(0, 6, 1, -foot - 1),
		ZIndex = 2,
		Parent = b,
	})
	pressable(b, { Kind = "tile" })
	if onClick then
		b.Activated:Connect(onClick)
	end
	return b
end

-- The way out of a menu: a red slab that leans, its points rounded, with a dark arrow (or a
-- cross, on a dialog) and a thin dark line just inside its edge. props: Parent, Position,
-- AnchorPoint, ZIndex, Icon ("back" by default), Size.
function Kit.backButton(props: { [string]: any }, onClick: (() -> ())?): TextButton
	local z: number = props.ZIndex or 2
	local size: UDim2 = props.Size or UDim2.fromOffset(84, 46)
	local h = size.Y.Offset
	local b = Kit.new("TextButton", {
		Name = "Close",
		Text = "",
		AutoButtonColor = false,
		BackgroundTransparency = 1,
		Size = size,
		Position = props.Position or UDim2.new(),
		AnchorPoint = props.AnchorPoint or Vector2.zero,
		ZIndex = z,
		Parent = props.Parent,
	})
	-- red means the way out in both looks
	b:SetAttribute("KeepColors", true)
	local face = Kit.new("Frame", {
		Name = "Fill",
		BackgroundColor3 = T.Red,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		ZIndex = z,
		Parent = b,
	})
	Kit.slant(face, h)
	Kit.shade(face)
	Kit.detail(face, { Tone = T.Dark, ToneAlpha = 0.88, ToneWidth = 34 })
	local ipx = math.floor(h * 0.56)
	local art = Icons.make(props.Icon or "back", ipx, {
		Name = "IconArt",
		Parent = b,
		Position = UDim2.new(0.5, -ipx / 2, 0.5, -ipx / 2),
		Color = T.Dark,
		Hole = T.Red,
		ZIndex = z + 1,
	})
	b:SetAttribute("KitButton", true)
	-- under the pointer the band runs along the slab and the arrow leans the way out
	pressable(b, { Kind = "slab", Nudge = { art }, NudgeX = if props.Icon == "close" then 0 else -4 })
	if onClick then
		b.Activated:Connect(onClick)
	end
	return b
end

-- Shapes drifting slowly across the black behind a menu. The user: "make an animated
-- background with shapes like it in the menus". Leaning bars, triangles, hollow rings, plus
-- signs and rows of ticks, faint, in the menu's colour and white, all sliding the same way at
-- their own speeds and coming round again. One loop moves them, and it stops when the menu goes.
-- opts: W, H (the layer's size), Count, Faint ({ from, to } transparency), Second (the colour of
-- every third shape, the words' colour by default), Sizes ({ from, to } pixels), Speed (a scale),
-- Bands (true or a number: long leaning strips of the colour drifting sideways behind the shapes).
function Kit.motion(parent: GuiObject, accent: Color3, seed: number, opts: { [string]: any }?): Frame
	local o: { [string]: any } = opts or {}
	local W: number, H: number = o.W or 2600, o.H or 1500
	local count: number = o.Count or 30
	local faintLo: number, faintHi: number = 0.86, 0.94
	if o.Faint then
		faintLo, faintHi = o.Faint[1], o.Faint[2]
	end
	local second: Color3 = o.Second or T.Ink
	local sizeLo: number, sizeHi: number = 34, 96
	if o.Sizes then
		sizeLo, sizeHi = o.Sizes[1], o.Sizes[2]
	end
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
	-- everything slides up and to the right, and comes back in at the far edge
	local dx, dy = 0.91, -0.41
	-- leaning bands of the colour, long enough to cross the whole layer, drifting slowly sideways
	type Band = { gui: GuiObject, at: number, speed: number }
	local bands: { Band } = {}
	local span = 0.41 * W + 0.91 * H
	if o.Bands then
		local reach = math.sqrt(W * W + H * H) * 1.1
		for b = 1, if type(o.Bands) == "number" then o.Bands else 3 do
			local thick = rng:NextNumber(0.05, 0.13) * H
			local band = block(layer, reach, thick, -24, accent, rng:NextNumber(faintLo - 0.08, faintLo + 0.02))
			band.Name = "Band"
			table.insert(
				bands,
				{ gui = band, at = (b - 0.5) / 3 + rng:NextNumber(-0.1, 0.1), speed = rng:NextNumber(0.006, 0.013) }
			)
		end
	end
	local kinds = { "bar", "tri", "diamond", "bar", "plus", "ticks", "tri", "bar", "diamond" }
	for k = 1, count do
		local kind = kinds[(k - 1) % #kinds + 1]
		local color = if k % 3 == 0 then second else accent
		local faint = rng:NextNumber(faintLo, faintHi)
		local size = rng:NextNumber(sizeLo, sizeHi)
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
			-- a hollow ring (it was a hollow diamond when the look was cut from straight lines)
			local d = block(holder, size * 0.7, size * 0.7, 0, color, 1)
			Kit.new("UICorner", { CornerRadius = UDim.new(0.5, 0), Parent = d })
			Kit.new("UIStroke", { Color = color, Transparency = faint, Thickness = math.max(3, size / 14), Parent = d })
		elseif kind == "plus" then
			-- the bar across, then the upright's two arms up to its edges: nothing drawn twice, so
			-- the sign is one colour all over
			local thick = size * 0.2
			block(holder, size, thick, 0, color, faint)
			local arm = (size - thick) / 2
			for _, side in { -1, 1 } do
				local a = block(holder, thick, arm, 0, color, faint)
				a.Position = UDim2.new(0.5, 0, 0.5, side * (thick + arm) / 2)
			end
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
			speed = rng:NextNumber(10, 34) * (o.Speed or 1),
			spin = spin,
		})
	end
	local function place(dt: number)
		for _, m in movers do
			m.x = (m.x + dx * m.speed * dt) % W
			m.y = (m.y + dy * m.speed * dt) % H
			m.gui.Position = UDim2.fromOffset(m.x, m.y)
			if m.spin ~= 0 then
				m.gui.Rotation += m.spin * dt
			end
		end
		for _, b in bands do
			b.at = (b.at + b.speed * dt) % 1
			local d = (b.at - 0.5) * span
			b.gui.Position = UDim2.fromOffset(W / 2 + 0.41 * d, H / 2 + 0.91 * d)
		end
	end
	place(0)
	local beat = RunService.Heartbeat:Connect(place)
	layer.Destroying:Connect(function()
		beat:Disconnect()
	end)
	return layer
end

-- A moving backdrop to stand somebody in front of: `accent` sinking into the look's backdrop,
-- leaning bands of it, and shapes sliding up and to the right (the user: "animate shapes in this
-- screen as well, going diagonally"). It cuts what it holds to its own box, so the turned
-- shapes never hang over the edge. Whoever stands on it goes beside it, not in it: a 3D picture
-- inside a CanvasGroup comes out pale. opts: W, H (the box's size in pixels, so the shapes cover
-- it), Count, Sink (how far the colour sinks, 0.5 by default), Name, ZIndex, Plain.
function Kit.backdrop(parent: Instance, accent: Color3, seed: number, opts: { [string]: any }?): GuiObject
	local o: { [string]: any } = opts or {}
	local sink: number = o.Sink or 0.5
	-- Plain: an ordinary frame, for where the edge is cut some other way (a SurfaceGui's own)
	local group = Kit.new(if o.Plain then "Frame" else "CanvasGroup", {
		Name = o.Name or "Backdrop",
		BorderSizePixel = 0,
		Size = o.Size or UDim2.fromScale(1, 1),
		ZIndex = o.ZIndex or 0,
		Parent = parent,
	})
	group:SetAttribute("KeepColors", true)
	Kit.wash(group, accent:Lerp(T.Black, sink), accent:Lerp(T.Black, math.min(1, sink + 0.36)), o.Rotation or 18)
	Kit.motion(group, accent:Lerp(T.White, 0.35), seed, {
		W = o.W or 1400,
		H = o.H or 900,
		Count = o.Count or 18,
		Bands = if o.Bands == nil then 3 else o.Bands,
		Faint = o.Faint or { 0.7, 0.87 },
		Second = T.White,
		Sizes = o.Sizes,
		Speed = o.Speed,
	})
	return group
end

-- The size every full menu's panel is, so they all sit in the same place.
Kit.MenuSize = UDim2.fromOffset(1180, 580)

-- A menu. Two kinds:
--   a full menu (the default) takes the screen: a black backdrop with shapes drifting across
--     it, a back button and the title across the top left, tabs at the top right (opts.Tabs,
--     opts.OnTab), and the panel under them
--   a dialog (opts.Dialog) is a small panel in the middle with its title inside and a close
--     button, over a lighter dim: a question, a welcome
-- The panel is a charcoal card with round corners, a thin line round it a few pixels out with
-- brackets in the menu's colour on its corners, a tone of halftone dots across it and a band of
-- hatching in its corner. A full menu's title has its name again, large and faint, behind it,
-- and a rule under it that ends in a dot, with opts.Caption (a few words) set wide after it. A
-- dialog's title sits on a darker band across its top, with the red way out at the right.
-- `color` is the menu's own colour: the drifting shapes, the hatching, the brackets and the mark
-- beside the title.
-- It comes in by itself: the black fades up, the card slides in a little from the right while
-- the title and the way back come from the left, and then the rows and cards in it come in one
-- after another (whatever was marked with Kit.mark while the menu was being filled). A change of
-- tab brings in what the tab made the same way. Kit.closePanel takes it away, quicker and the
-- other way round.
-- Returns { root, card, body, close, title, header, selectTab }. `root` holds everything, so
-- hiding or destroying it takes the lot.
-- Where a full menu's tabs go: a strip along the right half of its header that lines what is in it
-- up against its right end. The tab bar sizes itself to its tabs; placed by the strip's layout,
-- not by its own anchor, it can't end up anywhere but the header's right end (on a phone it once
-- stood off to the left of the menu, behind its way back).
local function tabsDock(header: GuiObject): Frame
	local dock = Kit.new("Frame", {
		Name = "TabsDock",
		BackgroundTransparency = 1,
		Size = UDim2.new(0.5, 0, 0, 50),
		Position = UDim2.new(1, -2, 0, 2),
		AnchorPoint = Vector2.new(1, 0),
		Parent = header,
	})
	Kit.new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		VerticalAlignment = Enum.VerticalAlignment.Top,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = dock,
	})
	return dock
end

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
	local since = Kit.born()
	local holder = Kit.box({
		Name = titleText,
		Size = UDim2.fromOffset(size.X.Offset, size.Y.Offset + BAR),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Parent = gui,
	})
	holder.ZIndex = 5
	holder:SetAttribute("Panel", true)
	-- the rest of the screen goes dark behind a menu, and clicks don't go through it
	local dimTo = if dialog then 0.45 else 0.06
	local dim = Kit.frame({
		Name = "Dim",
		Size = UDim2.fromOffset(6000, 6000),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Color = T.Black,
		Transparency = dimTo,
		Radius = false,
		ZIndex = 0,
		Parent = holder,
	})
	dim.Active = true
	local seed = #titleText * 31 + string.byte(titleText, 1)
	local glows: { GuiObject } = {}
	if dialog then
		-- lighter behind the dialog, darker toward the screen's edges
		Kit.vignette(dim, 0.6, 0.3, 0.3)
	else
		-- the menu's colour glowing up out of the black from the top left, and a little from
		-- the bottom right, behind the drifting shapes
		local wide = Kit.new("Frame", {
			Name = "Backglow",
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			ZIndex = 0,
			Parent = holder,
		})
		local screenGlow = Kit.box({
			Name = "Screen",
			Size = UDim2.fromOffset(2400, 1400),
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Parent = wide,
		})
		screenGlow.ZIndex = 0
		table.insert(glows, Kit.glow(screenGlow, accent, 0.26, "tl"))
		-- and a faint tone of dots over the whole backdrop
		Kit.dots(screenGlow, T.Ink, 0.965, false, true)
		local low = Kit.box({
			Name = "Low",
			Size = UDim2.fromOffset(2400, 1400),
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Parent = wide,
		})
		low.ZIndex = 0
		table.insert(glows, Kit.glow(low, accent, 0.14, "br"))
		Kit.motion(holder, accent, seed)
	end
	local _ = icon
	-- the panel: the card a few pixels inside its box, with no line round it (the user: "for
	-- bubbles and text in rounded rectangles everywhere, remove the borders"; it had a thin line
	-- round it a few pixels out, and one of its own)
	local ROUND = if dialog then 16 else 18
	local GAP = 5
	local HEAD = 60 -- a dialog's band
	local rim = Kit.box({
		Name = "Rim",
		Size = UDim2.new(1, 0, 1, -BAR),
		Position = UDim2.fromOffset(0, BAR),
		Parent = holder,
	})
	-- brackets in the menu's colour on the box's corners, just outside it
	local marks = Kit.brackets(rim, {
		Name = "Corners",
		Corners = { "tl", "tr", "bl", "br" },
		Arm = if dialog then 12 else 16,
		Thick = 2,
		Inset = -6,
		Color = accent,
		Transparency = 0.1,
		ZIndex = 1,
	})
	marks:SetAttribute("KeepColors", true)
	local frame = Kit.box({
		Name = "Card",
		Size = UDim2.new(1, -GAP * 2, 1, -GAP * 2),
		Position = UDim2.fromOffset(GAP, GAP),
		Parent = rim,
	})
	local shape = Kit.cutInto(frame, T.Cream, ROUND - GAP)
	if dialog then
		-- the band its title sits on: the card's own shape in two tones, so the band keeps the
		-- card's round corners
		local tall = size.Y.Offset - GAP * 2
		local at = math.clamp(HEAD / math.max(1, tall), 0.05, 0.9)
		shape.BackgroundColor3 = Color3.new(1, 1, 1)
		Kit.new("UIGradient", {
			Name = "Wash",
			Rotation = 90,
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, T.Black),
				ColorSequenceKeypoint.new(at, T.PaperDark),
				ColorSequenceKeypoint.new(math.min(0.99, at + 0.004), T.Cream),
				ColorSequenceKeypoint.new(1, T.Cream),
			}),
			Parent = shape,
		})
	end
	-- the menu's colour glowing softly into the panel from its top right corner
	Kit.glow(frame, accent, if dialog then 0.16 else 0.14, "tr")
	-- a tone of dots over the card, thinning out toward the bottom left
	Kit.dots(frame, T.Ink, 0.93, ROUND - GAP)
	-- details: a band of hatching in the bottom right corner, ticks along the top
	local hatch = Kit.hatch({
		Parent = frame,
		Size = UDim2.fromOffset(120, 12),
		Position = UDim2.new(1, -ROUND - 126, 1, -24),
		Color = accent,
		Transparency = 0.35,
		Fade = "left",
	})
	if hatch then
		hatch:SetAttribute("KeepColors", true)
	end
	if not dialog then
		for t = 0, 5 do
			Kit.new("Frame", {
				Name = "Tick",
				BackgroundColor3 = accent,
				BackgroundTransparency = 0.45,
				BorderSizePixel = 0,
				Size = UDim2.fromOffset(if t == 0 then 26 else 5, 3),
				Position = UDim2.fromOffset(ROUND + 10 + (if t == 0 then 0 else 24 + t * 10), 9),
				Parent = frame,
			})
		end
	end
	local title: TextLabel
	local close: TextButton
	local header: Frame
	local selectTab: ((string) -> ())? = nil
	if dialog then
		header = Kit.box({ Name = "Header", Parent = frame, Size = UDim2.new(1, 0, 0, HEAD) })
		-- its name, flush at the left (no coloured bar in front of it: the user, "remove every bar
		-- behind text design like this, and flush the text back")
		title = Kit.title(titleText, {
			Parent = header,
			Size = UDim2.new(1, -122, 1, 0),
			Position = UDim2.fromOffset(24, 0),
			TextSize = 25,
			Color = T.Ink,
		})
		-- a band of hatching across the band's far end, fading toward the title
		local band = Kit.hatch({
			Name = "BandHatch",
			Parent = header,
			Size = UDim2.fromOffset(110, HEAD - 28),
			Position = UDim2.new(1, -92, 0.5, 0),
			AnchorPoint = Vector2.new(1, 0.5),
			Color = accent,
			Transparency = 0.6,
			Fade = "left",
		})
		if band then
			band:SetAttribute("KeepColors", true)
		end
		close = Kit.backButton({
			Parent = frame,
			Icon = "close",
			Size = UDim2.fromOffset(58, 34),
			Position = UDim2.new(1, -18, 0, HEAD / 2),
			AnchorPoint = Vector2.new(1, 0.5),
			ZIndex = 2,
		})
	else
		header = Kit.box({ Name = "Header", Parent = holder, Size = UDim2.new(1, 0, 0, BAR - 10) })
		-- the menu's name again, large and faint, behind its title
		Kit.ghost(titleText, {
			Parent = header,
			Position = UDim2.fromOffset(88, -30),
			TextSize = 80,
			Transparency = 0.962,
		})
		-- the way back, at the top left
		close = Kit.backButton({ Parent = header, Position = UDim2.fromOffset(2, 2) })
		-- its name right after the way back (no coloured bar in front of it)
		title = Kit.title(titleText, {
			Parent = header,
			Size = UDim2.new(0.5, -100, 0, 46),
			Position = UDim2.fromOffset(100, 2),
			TextSize = 30,
			Color = T.Ink,
		})
		-- under the name a rule that ends in a dot, a short stroke of the menu's colour at its
		-- start, and a few words set wide after it
		Kit.rule({
			Name = "Rule",
			Parent = header,
			Size = UDim2.fromOffset(250, 6),
			Position = UDim2.fromOffset(100, 49),
			AnchorPoint = Vector2.new(0, 0.5),
			Color = T.Line,
			Accent = accent,
			AccentLength = 30,
		})
		if o.Caption then
			Kit.caption(o.Caption, {
				Name = "Caption",
				Parent = header,
				Position = UDim2.fromOffset(362, 49),
				AnchorPoint = Vector2.new(0, 0.5),
				TextSize = 11,
			})
		end
		if o.Tabs then
			local _bar, select = Kit.segments(o.Tabs, function(id: string)
				local mark = Kit.born()
				if o.OnTab then
					o.OnTab(id)
				end
				-- what the tab made comes in the way a menu's rows do, a little quicker
				task.defer(function()
					if holder.Parent then
						Kit.revealIn(holder, mark, { DX = 14, Step = 0.025 })
					end
				end)
			end, { Parent = tabsDock(header) })
			selectTab = select
		end
	end
	title.ZIndex = 2
	local top = if dialog then HEAD + 10 else 26
	local body = Kit.box({
		Name = "Body",
		Size = UDim2.new(1, -52, 1, -top - 26),
		Position = UDim2.fromOffset(26, top),
		Parent = frame,
	})
	-- what covers the card while it comes in and goes out: the backdrop's own black
	local veil = Kit.new("Frame", {
		Name = "Veil",
		BackgroundColor3 = T.Black,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 30,
		Parent = rim,
	})
	Kit.corner(veil, ROUND)
	local self: any = {
		root = holder,
		card = frame,
		body = body,
		close = close,
		title = title,
		header = header,
		selectTab = selectTab,
		dialog = dialog,
		dim = dim,
		dimTo = dimTo,
		rim = rim,
		veil = veil,
		glows = glows,
	}
	close.Activated:Connect(function()
		if onClose then
			onClose()
		else
			Kit.closePanel(self)
		end
	end)
	-- in it comes
	dim.BackgroundTransparency = 1
	tween(dim, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = dimTo })
	for _, g in glows do
		g.BackgroundTransparency = 1
		tween(g, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 0 })
	end
	local rimHome = rim.Position
	rim.Position = rimHome + (if dialog then UDim2.fromOffset(0, 18) else UDim2.fromOffset(40, 0))
	tween(rim, M.In, { Position = rimHome })
	veil.BackgroundTransparency = 0
	tween(veil, TweenInfo.new(0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 1 })
	if not dialog then
		local headHome = header.Position
		header.Position = headHome - UDim2.fromOffset(30, 0)
		tween(header, later(M.In, 0.03), { Position = headHome })
		title.TextTransparency = 1
		tween(title, later(M.In, 0.05), { TextTransparency = 0 })
	end
	-- and what the menu was filled with comes in after it, once it has been filled
	task.defer(function()
		if holder.Parent then
			Kit.revealIn(holder, since, { Delay = 0.1 })
		end
	end)
	Kit.sound("open")
	return self
end

-- Takes a menu made by Kit.panel away: the card slides back the way it came under the black,
-- the title goes off the other way and the black clears, quicker than it came in. What is
-- closing moves to a screen of its own at once and nothing on it can be pressed, so the menu is
-- gone for everything else straight away. `now` drops it without the motion.
function Kit.closePanel(p: any, now: boolean?)
	local root: GuiObject? = p and p.root
	if not root or not root.Parent then
		return
	end
	if now then
		root:Destroy()
		return
	end
	pcall(function()
		(root :: any).Interactable = false
	end)
	if p.dim then
		p.dim.Active = false
	end
	Kit.sound("close")
	root.Parent = leavingGui()
	if p.dim then
		tween(p.dim, M.Out, { BackgroundTransparency = 1 })
	end
	for _, g in p.glows or {} do
		tween(g, M.Out, { BackgroundTransparency = 1 })
	end
	local motion = root:FindFirstChild("Motion")
	if motion and motion:IsA("GuiObject") then
		motion.Visible = false
	end
	local dots = root:FindFirstChild("Dots", true)
	if dots and dots:IsA("ImageLabel") and dots.Parent and dots.Parent.Name == "Screen" then
		dots.Visible = false
	end
	if p.rim then
		tween(p.rim, M.Out, {
			Position = p.rim.Position + (if p.dialog then UDim2.fromOffset(0, 12) else UDim2.fromOffset(28, 0)),
		})
	end
	if p.veil then
		tween(p.veil, M.Out, { BackgroundTransparency = 0 })
	end
	if not p.dialog and p.header then
		tween(p.header, M.Out, { Position = p.header.Position - UDim2.fromOffset(24, 0) })
		if p.title then
			tween(p.title, M.Out, { TextTransparency = 1 })
		end
		for _, d in p.header:GetDescendants() do
			if d:IsA("TextLabel") and d ~= p.title then
				tween(d, M.Out, { TextTransparency = 1 })
			end
		end
	end
	task.delay(0.16, function()
		root:Destroy()
	end)
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
		Kit.slant(core, if type(p.Slant) == "number" then p.Slant else nil, nil, p.Flip == true)
	else
		Kit.corner(core, if p.Round then "round" else p.Radius or 14)
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
			-- a plain pill, with no line round it
			Kit.frame({ Name = "Core", Parent = l, Color = spec[2], Radius = "pill", ZIndex = z })
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

-- An answer to pick: a leaning slab in the row colour with the words on it; under the pointer it
-- turns a shade lighter. props: Parent, Size, LayoutOrder, TextSize, Name, ZIndex, Disabled (greyed
-- words, nothing lights), Icon (an icon left of the words), Rich (the text is rich text, for
-- coloured names).
function Kit.choice(text: string, props: { [string]: any }?, onClick: (() -> ())?): TextButton
	local p = props or {}
	local z = p.ZIndex or 1
	local size: UDim2 = p.Size or UDim2.new(1, 0, 0, 54)
	local b = Kit.new("TextButton", {
		Text = "",
		AutoButtonColor = false,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = size,
		LayoutOrder = p.LayoutOrder or 0,
		Name = p.Name or "Choice",
		ZIndex = z,
		Parent = p.Parent,
	})
	b:SetAttribute("KitButton", true)
	local face = Kit.new("Frame", {
		Name = "Face",
		BackgroundColor3 = T.Card,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		ZIndex = z,
		Parent = b,
	})
	Kit.slant(face, if size.Y.Offset > 0 then size.Y.Offset else 54)
	Kit.shade(face)
	local row = Kit.box({ Name = "Content", Parent = b, Size = UDim2.fromScale(1, 1) })
	row.ZIndex = z + 1
	local list = Kit.list(row, 8, true, Enum.HorizontalAlignment.Center)
	list.VerticalAlignment = Enum.VerticalAlignment.Center
	if p.Icon and Icons.has(p.Icon) then
		Icons.make(p.Icon, 26, { Name = "IconArt", Parent = row, ZIndex = z + 1, LayoutOrder = 1 })
	end
	Kit.new("TextLabel", {
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
	if not p.Disabled then
		b.MouseEnter:Connect(function()
			Kit.paint(face, T.Line)
		end)
		b.MouseLeave:Connect(function()
			Kit.paint(face, T.Card)
		end)
	end
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
	local picked: string? = nil
	local function select(id: string)
		local was = picked
		picked = id
		for bid, b in buttons do
			if bid == id then
				-- the picked tab is yellow with dark words
				Kit.setButtonColor(b, p.Active or T.Yellow, T.Dark)
			else
				Kit.setButtonColor(b, T.PaperDark, T.Ink)
			end
		end
		-- and its yellow slides over from the one picked before
		if was and was ~= id and buttons[was] and buttons[id] then
			Kit.glide(buttons[was], buttons[id])
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

-- A card comes into view: it grows the last few hundredths to its size, quick and with no bounce.
-- (A full menu or a dialog from Kit.panel brings itself in.)
function Kit.popIn(frame: GuiObject)
	frame.Visible = true
	if frame:GetAttribute("Panel") then
		return
	end
	local s = frame:FindFirstChild("PopScale") or Kit.new("UIScale", { Name = "PopScale", Parent = frame })
	s.Scale = 0.94
	tween(s, M.In, { Scale = 1 })
end

-- Shrinks a frame away, then runs `done` (which usually hides or destroys it).
function Kit.popOut(frame: GuiObject, done: (() -> ())?)
	local s = frame:FindFirstChild("PopScale") or Kit.new("UIScale", { Name = "PopScale", Parent = frame })
	tween(s, M.Out, { Scale = 0.94 })
	task.delay(0.15, function()
		if done then
			done()
		end
	end)
end

-- Slides a frame in from (dx, dy) pixels away, after `delay` seconds, easing out to rest (no
-- overshoot).
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
	tween(frame, later(TweenInfo.new(0.42, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), delay or 0), {
		Position = target,
	})
end

-- A quick swell, for a number that just changed: it settles back with no bounce.
function Kit.bump(frame: GuiObject, amount: number?)
	local s = frame:FindFirstChild("Bump") or Kit.new("UIScale", { Name = "Bump", Parent = frame })
	s.Scale = 1 + (amount or 0.12)
	tween(s, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Scale = 1 })
end

-- Coins that fly from a point on screen into a counter, the way games show money coming in.
-- `from` is in screen pixels (or nil for the middle of the screen); `to` is the counter.
function Kit.flyCoins(from: Vector2?, to: GuiObject, count: number?)
	Kit.sound("coins")
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
		-- a picture on a part in the world (the creator's backdrop is one, kept in PlayerGui) is
		-- scenery, not interface, though the engine reports what is on it as under the pointer
		if cur:IsA("SurfaceGui") or cur:IsA("BillboardGui") then
			return false
		end
		cur = cur.Parent
	end
	return true
end

-- Is the pointer over any of our interface (so world clicks should be ignored)? Takes a viewport
-- position (like GetMouseLocation); defaults to the mouse. Only what is on the screen counts:
-- GetGuiObjectsAtPosition also returns what is drawn on a SurfaceGui that lives in PlayerGui.
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
