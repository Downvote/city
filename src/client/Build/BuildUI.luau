-- Build mode's interface, laid out the way house builders usually are: the main groups and Done
-- on one bar along the bottom, above it the catalog (the category tiles over the item tray, on one
-- card) from one edge of the screen to the other, the tools on top of it at the left, the floor
-- switcher with the view toggles on top of it at the right, coins top left, and a little action bar
-- over whatever you pick.

local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Tuning = require(Shared.Config.Tuning)
local Plan = require(Shared.Build.Plan)
local Builder = require(Shared.Build.Builder)
local Catalog = require(Shared.Build.Catalog)
local Palette = require(Shared.Data.Palette)
local Colors = require(Shared.Util.Colors)
local Text = require(Shared.Util.Text)
local Keepsakes = require(Shared.Sim.Keepsakes)

local Kit = require(script.Parent.Parent.UI.Kit)
local Presets = require(Shared.Data.Presets)
local Icons = require(script.Parent.Parent.UI.Icons)
local Toasts = require(script.Parent.Parent.UI.Toasts)
local ModelPreview = require(script.Parent.Parent.UI.ModelPreview)
local State = require(script.Parent.Parent.Controllers.State)
local BuildMode = require(script.Parent.BuildMode)

local BuildUI = {}

local T = Kit.Theme
local s = BuildMode.state

local MAIN = {
	{
		id = "build",
		icon = "blueprint",
		name = "Build",
		subs = {
			{ id = "buildings", icon = "house", name = "Buildings" },
			{ id = "walls", icon = "wall", name = "Walls" },
			{ id = "rooms", icon = "room", name = "Rooms" },
			{ id = "floors", icon = "floor", name = "Floors" },
			{ id = "roofs", icon = "roof", name = "Roofs" },
			{ id = "doors", icon = "door", name = "Doors" },
			{ id = "windows", icon = "window", name = "Windows" },
			{ id = "structure", icon = "stairs", name = "Stairs" },
			-- cubes, cylinders, wedges and the rest, to build anything from (Recipes/Shapes)
			{ id = "shapes", icon = "shapes", name = "Shapes" },
		},
	},
	{
		id = "furniture",
		icon = "sofa",
		name = "Furniture",
		subs = {
			{ id = "seating", icon = "chair", name = "Seating" },
			{ id = "tables", icon = "table", name = "Tables" },
			{ id = "beds", icon = "bed", name = "Beds" },
			{ id = "storage", icon = "cabinet", name = "Storage" },
			{ id = "kitchen", icon = "pot", name = "Kitchen" },
			{ id = "bath", icon = "bath", name = "Bathroom" },
			{ id = "lights", icon = "lamp", name = "Lights" },
			{ id = "fun", icon = "gamepad", name = "Fun" },
			{ id = "decor", icon = "plant", name = "Decor" },
			{ id = "walldecor", icon = "frame", name = "On walls" },
			-- posters, frames and decals showing a picture from the Roblox library (Recipes/Pictures)
			{ id = "pictures", icon = "picture", name = "Pictures" },
			-- what villagers made you in events: free, as many as you were given (Sim/Keepsakes)
			{ id = "keepsakes", icon = "gift", name = "Keepsakes" },
		},
	},
	{
		id = "outdoor",
		icon = "tree",
		name = "Outdoor",
		subs = {
			{ id = "garden", icon = "flower", name = "Garden" },
			{ id = "fences", icon = "fence", name = "Fences" },
			{ id = "paths", icon = "path", name = "Paths" },
			-- flat paint on floors, paths and the ground (the user: "add another section where
			-- players can put down markings, like in bloxburg": Recipes/Markings)
			{ id = "markings", icon = "marking", name = "Markings" },
		},
	},
	-- Every piece of one look across every category (Catalog.Styles; the user: "there should be
	-- many to choose from from different categories, like garden, sci fi, cozy, etc, just like
	-- bloxburg"). Its tiles are filled in from Catalog.Styles below.
	{ id = "styles", icon = "styles", name = "Styles", subs = {} },
	{
		id = "work",
		icon = "store",
		name = "Work",
		subs = { { id = "work", icon = "store", name = "Workplaces" } },
	},
}

-- the tiles of the Styles group, one a look, and the icon each wears
local LOOK_ICONS: { [string]: string } = {
	cozy = "mug",
	modern = "city",
	scifi = "rocket",
	garden = "flower",
	seaside = "anchor",
	rustic = "barrel",
	fancy = "gem",
	playful = "balloon",
}
for _, m in MAIN do
	if m.id == "styles" then
		for _, look in Catalog.Styles do
			table.insert(m.subs, { id = "style:" .. look.id, icon = LOOK_ICONS[look.id] or "layers", name = look.name })
		end
	end
end

local WALL_STYLES = { "wall", "half", "glass" }
-- every kind of fence, in Plan's order
local FENCE_STYLES: { string } = {}
for _, id in Plan.WallStyleOrder do
	if Plan.WallStyles[id].fence then
		table.insert(FENCE_STYLES, id)
	end
end
local STYLE_ICONS = {
	brick = "brickWall",
	rail = "railFence",
	iron = "ironFence",
	bamboo = "bamboo",
	log = "logFence",
	willow = "wovenFence",
	rope = "ropeFence",
	balustrade = "glassRail",
	lightrail = "lightRail",
	wall = "wall",
	half = "wallHalf",
	glass = "wallGlass",
	railing = "railing",
	fence = "fence",
	hedge = "hedge",
	stone = "stoneWall",
	gable = "roof",
	hip = "roofHip",
	pyramid = "roofPyramid",
	shed = "roofShed",
	flat = "roofFlat",
}

-- One rhythm for the whole screen: every bar keeps the same distance from the screen's edges and
-- from the next bar, the same room inside and the same round corners, and the tiles in the tool
-- row and the category row are the same height.
local EDGE = 12 -- from the screen's edges
local GAP = 8 -- between bars, and between things side by side
local PAD = 8 -- inside a bar, above and below
local SIDE = 12 -- inside a bar, left and right (clear of its round corners)
local CUT = 12
local DOCK_H, TOOLS_H = 64, 80
local TILE_H = 64 -- a category or a tool
local TOOL_W = 64
-- the floors card: five icon buttons in a row (two arrows, then three switches), as tall as the
-- tools row beside it, with a quiet line between the two groups
local VIEW_BTN, VIEW_SPLIT = 64, 13
local FLOORS_W, FLOORS_H = 5 * VIEW_BTN + VIEW_SPLIT + SIDE * 2, TOOLS_H
local LABEL_W = 124 -- the name at the left of a labelled row in the tray
local INNER_H = 160 -- what the tray holds
-- The catalog is one rounded card: the category tiles in a deeper well along one edge of it, and
-- the tray (the cards, or a page of finishes, or a note) along the other. The user, of the cards
-- and the category tiles under them: "the second should move down, shifting the tab below it
-- up", then "move the bottom part up, but make it such that they share the same rectangle
-- background with each other". So the categories are on top and the cards under them. This is
-- the one place that says so: set it to false and the categories go back under the cards.
local CATEGORIES_ON_TOP = true
local WELL_PAD = 4 -- round the tiles in their well
local SUB_NOTE = 190 -- kept at the well's right end for the picked category's number and name
local WELL_H = TILE_H + WELL_PAD * 2
local CATALOG_H = PAD + WELL_H + PAD + INNER_H + PAD
-- the bars' bottoms, measured up from the bottom of the screen
local CATALOG_AT = EDGE + DOCK_H + GAP
local TOOLS_AT = CATALOG_AT + CATALOG_H + GAP
local HINT_AT = TOOLS_AT + TOOLS_H + GAP
-- the coins and the camera tip, top left
local COINS_H, TIP_H = 46, 28
local TOP_LEFT_W, TOP_LEFT_H = 380, EDGE + COINS_H + GAP + TIP_H

-- the cards in the tray: a picture on the upper face, the name and the price on the deeper band
-- along the bottom (a third of the card, as on Kit.tile)
local CARD_W, CARD_H = 120, 156
local CHIP_W, CHIP_H = 92, 50 -- a finish to paint with
local STYLE_W, STYLE_H = 92, 92 -- a kind of wall, fence or roof
local SWATCH = 26 -- a colour to paint with, in a cell this much bigger
local RING = 3

local MATERIAL_NAMES: { [string]: string } = {}
for _, m in Palette.Materials do
	MATERIAL_NAMES[m.id] = m.name
end
local function materialName(id: string): string
	return MATERIAL_NAMES[id] or id
end

local ui: Frame
local tray: Frame -- the catalog's lower part, which the tray's pages fill
local trayBody: Frame
local subBar: ScrollingFrame
local subCaption: TextLabel? = nil -- the picked category's number and name, at the well's right end
local subIndex: TextLabel? = nil
local mainButtons: { [string]: TextButton } = {}
local subButtons: { [string]: TextButton } = {}
local toolButtons: { [string]: TextButton } = {}
local hintPill: Frame
local hintLabel: TextLabel
local levelDown: TextButton
local levelUp: TextButton
local coinsLabel: TextLabel
local actionBar: Frame
local actionTitle: TextLabel
local actionValue: Frame
local actionButtons: Frame
local viewButtons: { [string]: TextButton } = {}
local overView: string? = nil -- the floors card's button under the mouse, which the hint names
local flashText: string? = nil -- what just changed on the floors card, in the hint for a moment
local flashToken = 0
local shownLevel = 0
-- While a piece is held to place, the interface slides out of the way and only the hint stays
-- (the user: "when placing down things in build mode, make the whole interface slide down other
-- than this tooltip, then reappear once the player puts it away").
local holdingNow = false
local slideToken = 0
local touchButtons: Frame
local built = false
local mainTab = "build"
local subTab = "walls"
local trayMode = "" -- what the tray shows right now
local onExit: (() -> ())? = nil
local paintSide = "a" -- what the wall tray paints: "a" outside, "b" inside, "floor" a room's floor
local holdTray = 0 -- while a slider is moving, plan updates don't rebuild the tray
local sliderToken = 0
local hovering: string? = nil -- a ready-made building's description in the hint while the mouse is on its card
local coinsNow = 0
-- the picture page: the piece it is for (picked from the Pictures tab, before it is placed), and
-- what was typed and what the server said, kept so a rebuilt tray shows them again
local pictureDef: string? = nil
local draft: { [string]: any } = { owner = "", text = "", id = nil, state = "", why = nil }
-- the price tags on show, to turn coral while a card costs more than you have
local priceTags: { [Frame]: number } = setmetatable({}, { __mode = "k" }) :: any

-- small helpers --------------------------------------------------------------------------------------

local function clear(frame: Instance)
	for _, c in frame:GetChildren() do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
end

-- A row of the tray that scrolls sideways (a whole tray of cards, or a row in a stack).
local function trayRow(height: number?, parent: Instance?, order: number?): ScrollingFrame
	local row = Kit.scroll({
		Parent = parent or trayBody,
		Size = UDim2.new(1, 0, 0, height or INNER_H),
		Axis = Enum.AutomaticSize.X,
		LayoutOrder = order or 0,
	})
	row.ScrollingDirection = Enum.ScrollingDirection.X
	row.ScrollBarThickness = 4
	local layout = Kit.list(row, GAP, true)
	layout.VerticalAlignment = Enum.VerticalAlignment.Top
	return row
end

-- Rows on top of one another, in the middle of the tray's height.
local function trayStack(gap: number?): Frame
	local stack = Kit.box({ Parent = trayBody, Size = UDim2.fromScale(1, 1) })
	Kit.list(stack, gap or GAP).VerticalAlignment = Enum.VerticalAlignment.Center
	return stack
end

-- A row of the tray with its name at the left and what to pick from beside it, scrolling
-- sideways. Returns the part that scrolls.
local function labelledRow(parent: Instance, label: string, height: number, order: number): ScrollingFrame
	local row = Kit.box({ Name = label, Parent = parent, Size = UDim2.new(1, 0, 0, height), LayoutOrder = order })
	Kit.text(label, {
		Parent = row,
		Size = UDim2.new(0, LABEL_W - GAP, 1, 0),
		TextSize = 15,
		Font = Kit.Fonts.Bold,
		Color = T.InkSoft,
	})
	local scroll = Kit.scroll({
		Parent = row,
		Size = UDim2.new(1, -LABEL_W, 1, 0),
		Position = UDim2.fromOffset(LABEL_W, 0),
		Axis = Enum.AutomaticSize.X,
	})
	scroll.ScrollBarThickness = 3
	local layout = Kit.list(scroll, 6, true)
	layout.VerticalAlignment = Enum.VerticalAlignment.Top
	return scroll
end

-- A coin and some words side by side, in the middle of a box (a price on a tile).
local function coinLine(parent: Instance, text: string, props: { [string]: any }): Frame
	local box = Kit.box({
		Name = "Cost",
		Parent = parent,
		Size = props.Size or UDim2.new(1, 0, 0, 16),
		Position = props.Position or UDim2.new(),
		LayoutOrder = props.LayoutOrder or 0,
	})
	local layout = Kit.list(box, 3, true, props.Align or Enum.HorizontalAlignment.Center)
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	local px = props.Coin or 14
	Icons.make("coin", px, { Parent = box, LayoutOrder = 1 })
	Kit.text(text, {
		Parent = box,
		Size = UDim2.fromOffset(0, px),
		AutomaticSize = Enum.AutomaticSize.X,
		TextSize = props.TextSize or 12,
		Font = Kit.Fonts.Bold,
		Color = props.Color or T.InkSoft,
		Wrap = false,
		LayoutOrder = 2,
	})
	return box
end

-- The face of a card or a tile in the tray, drawn as Kit.tile draws its own: a rounded square in
-- `color` with a thin line round it and a deeper band across its bottom third, where the name
-- goes. (Kit.paint recolours it, band and all, and a change of look does too.) Returns the face
-- and where the band starts, in pixels from the top.
local function tileFace(holder: GuiObject, color: Color3, h: number): (Frame, number)
	local face = Kit.new("Frame", {
		Name = "Face",
		BackgroundColor3 = color,
		BorderSizePixel = 0,
		Size = UDim2.new(1, -2, 1, -2),
		Position = UDim2.fromOffset(1, 1),
		Parent = holder,
	})
	Kit.corner(face, 9)
	Kit.new("UIGradient", { Name = "Foot", Rotation = 90, Parent = face })
	Kit.paint(face, color)
	Kit.rim(face, Kit.edgeOf(color), 1):SetAttribute("Follow", true)
	return face, math.floor((h - 2) * 0.66 + 0.5) + 1
end

-- A dark disc with a yellow tick on the corner of what is picked.
local function pickedMark(parent: Instance, x: number, y: number)
	Kit.disc({
		Name = "Picked",
		Parent = parent,
		Size = 18,
		Position = UDim2.fromOffset(x, y),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Color = T.Dark,
		Icon = "check",
		IconColor = T.Yellow,
		Ring = T.Yellow,
		ZIndex = 4,
	})
end

-- The price on a card: the coin and the number, coral while the card costs more than you have.
local function paintTag(tag: Frame, price: number)
	local label = tag:FindFirstChild("Amount")
	if label and label:IsA("TextLabel") then
		local short = price > coinsNow
		label.TextColor3 = if short then Kit.tint(T.Coral) else T.Ink
		label:SetAttribute("Tint", if short then T.Coral:ToHex() else nil)
	end
end

local function priceTag(parent: Instance, price: number, y: number): Frame
	local tag =
		Kit.box({ Name = "Price", Parent = parent, Size = UDim2.new(1, 0, 0, 18), Position = UDim2.fromOffset(0, y) })
	Kit.list(tag, 4, true, Enum.HorizontalAlignment.Center)
	Icons.make("coin", 17, { Parent = tag, LayoutOrder = 1 })
	Kit.title(Text.commas(price), {
		Name = "Amount",
		Parent = tag,
		Size = UDim2.fromOffset(0, 18),
		AutomaticSize = Enum.AutomaticSize.X,
		TextSize = 16,
		Wrap = false,
		LayoutOrder = 2,
	})
	priceTags[tag] = price
	paintTag(tag, price)
	return tag
end

-- What a card does under the mouse: the motion every tile in the interface has (Kit.press): a
-- band of light across its face, corner brackets closing in, a dip and a flash when pressed.
local function hoverable(card: GuiButton): UIScale
	Kit.press(card, { Kind = "tile" })
	return card:FindFirstChild("Press") :: UIScale
end

-- A card in the tray: a picture on the upper face, its name and price on the band under it.
-- Returns the card, the picture's frame and where the band starts.
local function card(
	parent: Instance,
	name: string,
	order: number,
	width: number,
	onPick: () -> ()
): (TextButton, Frame, number)
	local b = Kit.new("TextButton", {
		Name = name,
		Text = "",
		AutoButtonColor = false,
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(width, CARD_H),
		LayoutOrder = order,
		Parent = parent,
	})
	local _, foot = tileFace(b, T.Card, CARD_H)
	local pic = Kit.frame({
		Name = "Picture",
		Parent = b,
		Size = UDim2.new(1, -12, 0, foot - 10),
		Position = UDim2.fromOffset(6, 6),
		Color = T.Picture,
		Radius = 6,
		ZIndex = 2,
	})
	local scale = hoverable(b)
	b.Activated:Connect(onPick)
	-- cards come into the tray one after another, growing the last few hundredths to their size
	scale.Scale = 0.9
	TweenService:Create(
		scale,
		TweenInfo.new(0.26, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, 0, false, math.min(order, 14) * 0.022),
		{ Scale = 1 }
	):Play()
	return b, pic, foot
end

-- A card's name on its band: on two lines if it needs them, over the price.
local function cardName(b: GuiObject, text: string, foot: number, size: number)
	Kit.title(text, {
		Name = "Name",
		Parent = b,
		Size = UDim2.new(1, -12, 0, 30),
		Position = UDim2.fromOffset(6, foot + 2),
		TextSize = size,
		AlignX = Enum.TextXAlignment.Center,
		ZIndex = 2,
	})
end

-- A catalog item's card: its 3D picture, and its name and price on the band.
local function itemTile(parent: Instance, def: any, order: number, onPick: () -> ()): TextButton
	local b, pic, foot = card(parent, def.id, order, CARD_W, onPick)
	b:SetAttribute("ItemId", def.id)
	task.spawn(function()
		ModelPreview.fromPrims(Catalog.prims(def), { Parent = pic })
	end)
	cardName(b, def.name, foot, 13)
	priceTag(b, def.price, CARD_H - 22)
	return b
end

-- A keepsake's card: its picture and name, and on the band "Free" with how many more of it can go
-- down. One with none left (every one given is down) says so and picks nothing.
local function keepsakeTile(parent: Instance, entry: Keepsakes.Entry, order: number): TextButton
	local def = entry.def
	local b, pic, foot = card(parent, def.id, order, CARD_W, function()
		if entry.left > 0 then
			BuildMode.startPlacing(def.id)
		else
			Toasts.show("You've already put all of these down.", "info")
		end
	end)
	b:SetAttribute("ItemId", def.id)
	b:SetAttribute("Left", entry.left)
	task.spawn(function()
		ModelPreview.fromPrims(Catalog.prims(def), { Parent = pic })
	end)
	cardName(b, def.name, foot, 13)
	Kit.title(if entry.left > 0 then Text.fill("Free, {n} left", { n = entry.left }) else "None left", {
		Name = "Left",
		Parent = b,
		Size = UDim2.new(1, -12, 0, 18),
		Position = UDim2.fromOffset(6, CARD_H - 22),
		TextSize = 15,
		AlignX = Enum.TextXAlignment.Center,
		Color = if entry.left > 0 then T.Ink else T.InkSoft,
		Wrap = false,
		ZIndex = 2,
	})
	return b
end

-- A finish (a colour and a material) to build or paint with: a tile with the colour on its upper
-- face and the name on its band. Big (opts.h over 60), the colour carries the material's name and
-- a line goes under the name (opts.sub, with a coin when opts.coin). The picked one is yellow
-- with a tick.
local function finishTile(
	parent: Instance,
	preset: { name: string, c: string, m: string },
	order: number,
	opts: { [string]: any },
	onPick: () -> ()
): TextButton
	local h: number = opts.h or CHIP_H
	-- a long name ("Charcoal shingles") gets a wider chip rather than losing its end
	local w: number = opts.w or (if #preset.name > 13 then CHIP_W + 20 else CHIP_W)
	local big = h > 60
	local picked = opts.selected == true
	local b = Kit.new("TextButton", {
		Name = preset.name,
		Text = "",
		AutoButtonColor = false,
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(w, h),
		LayoutOrder = order,
		Parent = parent,
	})
	local _, foot = tileFace(b, if picked then T.Yellow else T.Card, h)
	local inset = if big then 6 else 4
	local color = Colors.fromHex(preset.c)
	local sw = Kit.frame({
		Name = "Swatch",
		Parent = b,
		Size = UDim2.new(1, -inset * 2, 0, foot - inset - 3),
		Position = UDim2.fromOffset(inset, inset),
		Color = color,
		Radius = if big then 6 else 5,
		ZIndex = 2,
	})
	if big and preset.m and materialName(preset.m) ~= preset.name then
		local light = color.R * 0.3 + color.G * 0.59 + color.B * 0.11 > 0.6
		Kit.text(materialName(preset.m), {
			Parent = sw,
			Size = UDim2.new(1, -10, 0, 16),
			Position = UDim2.new(0, 6, 1, -19),
			TextSize = 12,
			Font = Kit.Fonts.Bold,
			Color = if light then T.Dark else T.White,
			Wrap = false,
		})
	end
	local ink = if picked then T.Dark else T.Ink
	local band = h - foot - 1
	local nameH = if opts.sub then 16 else band
	Kit.title(preset.name, {
		Name = "Name",
		Parent = b,
		Size = UDim2.new(1, -8, 0, nameH),
		Position = UDim2.fromOffset(4, foot + (if opts.sub then 2 else 0)),
		TextSize = if big then 14 else 12,
		Color = ink,
		AlignX = Enum.TextXAlignment.Center,
		Wrap = false,
		ZIndex = 2,
	}).TextTruncate =
		Enum.TextTruncate.AtEnd
	if opts.sub then
		local soft = if picked then T.Dark else T.InkSoft
		if opts.coin then
			coinLine(b, opts.sub, { Position = UDim2.new(0, 0, 1, -19), Color = soft })
		else
			Kit.text(opts.sub, {
				Parent = b,
				Size = UDim2.new(1, -8, 0, 16),
				Position = UDim2.new(0, 4, 1, -19),
				TextSize = 12,
				Font = Kit.Fonts.Bold,
				Color = soft,
				AlignX = Enum.TextXAlignment.Center,
				Wrap = false,
			})
		end
	end
	if picked then
		pickedMark(b, w - 9, 9)
	end
	hoverable(b)
	b.Activated:Connect(onPick)
	return b
end

-- A kind of wall, fence or roof: its icon and its name, and under them what it costs (opts.sub).
local function styleTile(
	parent: Instance,
	label: string,
	icon: string,
	order: number,
	picked: boolean,
	sub: string?,
	onPick: () -> ()
): TextButton
	local b = Kit.new("TextButton", {
		Name = label,
		Text = "",
		AutoButtonColor = false,
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(STYLE_W, STYLE_H),
		LayoutOrder = order,
		Parent = parent,
	})
	local color = if picked then T.Yellow else T.Card
	local _, foot = tileFace(b, color, STYLE_H)
	local ink = if picked then T.Dark else T.Ink
	-- the icon on the upper face (with what it costs under it), the name on the band
	local ipx = if sub then 30 else 36
	local top = if sub then 7 else math.floor((foot - ipx) / 2)
	Icons.make(icon, ipx, {
		Name = "IconArt",
		Parent = b,
		Position = UDim2.new(0.5, -ipx / 2, 0, top),
		Color = ink,
		Hole = color,
		ZIndex = 2,
	})
	if sub then
		local cost = coinLine(
			b,
			sub,
			{ Position = UDim2.fromOffset(0, top + ipx + 3), Color = if picked then T.Dark else T.InkSoft }
		)
		cost.ZIndex = 2
	end
	Kit.title(label, {
		Name = "Name",
		Parent = b,
		Size = UDim2.new(1, -8, 0, STYLE_H - foot - 1),
		Position = UDim2.fromOffset(4, foot),
		TextSize = 14,
		Color = ink,
		AlignX = Enum.TextXAlignment.Center,
		Wrap = false,
		ZIndex = 2,
	})
	if picked then
		pickedMark(b, STYLE_W - 10, 10)
	end
	hoverable(b)
	b.Activated:Connect(onPick)
	return b
end

-- A row of colours to pick from; the picked one stands in a yellow ring.
local function swatchRow(parent: Instance, label: string, current: string?, onPick: (string) -> (), order: number)
	local row = labelledRow(parent, label, SWATCH + RING * 2, order)
	local list = Palette.Colors
	if current and not table.find(list, current) then
		-- a colour of its own (a piece's own wood, one copied): first, so it shows what it has
		list = table.clone(list)
		table.insert(list, 1, current)
	end
	for i, hex in list do
		local cell =
			Kit.box({ Parent = row, Size = UDim2.fromOffset(SWATCH + RING * 2, SWATCH + RING * 2), LayoutOrder = i })
		if hex == current then
			Kit.frame({ Name = "Ring", Parent = cell, Size = UDim2.fromScale(1, 1), Color = T.Yellow, Radius = "round" })
		end
		local b = Kit.swatch(Colors.fromHex(hex), SWATCH, function()
			onPick(hex)
		end, { Parent = cell })
		b.Position = UDim2.fromOffset(RING, RING)
		-- a thin rim, so a white or a charcoal one still shows on the tray in either look (the
		-- swatch's own stroke, switched on: an object draws only one)
		local edge = b:FindFirstChildOfClass("UIStroke")
		if edge then
			edge.Enabled, edge.Color, edge.Thickness, edge.Transparency = true, T.Line, 1, 0
		end
	end
	return row
end

local function materialRow(parent: Instance, current: string?, onPick: (string) -> (), order: number)
	local row = labelledRow(parent, "Material", 28, order)
	for i, m in Palette.Materials do
		local on = m.id == current
		local b = Kit.button(m.name, {
			Parent = row,
			Size = UDim2.fromOffset(0, 28),
			AutomaticSize = Enum.AutomaticSize.X,
			TextSize = 14,
			Color = if on then T.Yellow else T.Card,
			TextColor = if on then T.Dark else T.Ink,
			LayoutOrder = i,
		})
		Kit.pad(b, 12, 0)
		b.Activated:Connect(function()
			onPick(m.id)
		end)
	end
	return row
end

-- What a finish is called: the ready-made one it matches, or else its material.
local function finishName(c: string, m: string): string
	for _, list in { Palette.Presets.walls, Palette.Presets.floors, Palette.Presets.roofs } do
		for _, p in list do
			if p.c == c and p.m == m then
				return p.name
			end
		end
	end
	return Text.fill("{m} finish", { m = materialName(m) })
end

-- What the brush or a wall's side holds, as a chip: the colour and its name.
local function finishChip(parent: Instance, label: string, c: string, m: string, order: number)
	local box = Kit.box({
		Parent = parent,
		Size = UDim2.fromOffset(0, 30),
		AutomaticSize = Enum.AutomaticSize.X,
		LayoutOrder = order,
	})
	Kit.list(box, 6, true)
	Kit.text(label, {
		Parent = box,
		Size = UDim2.fromOffset(0, 30),
		AutomaticSize = Enum.AutomaticSize.X,
		TextSize = 14,
		Font = Kit.Fonts.Bold,
		Color = T.InkSoft,
		Wrap = false,
		LayoutOrder = 1,
	})
	local dot = Kit.frame({
		Name = "Swatch",
		Parent = box,
		Size = UDim2.fromOffset(22, 22),
		Color = Colors.fromHex(c),
		Radius = "round",
		LayoutOrder = 2,
	})
	Kit.rim(dot, T.Line, 1.5)
	Kit.title(finishName(c, m), {
		Parent = box,
		Size = UDim2.fromOffset(0, 30),
		AutomaticSize = Enum.AutomaticSize.X,
		TextSize = 15,
		Wrap = false,
		LayoutOrder = 3,
	})
	return box
end

-- A few words in the tray where there is nothing to pick: a title and a softer line under it.
local function trayNote(parent: Instance, icon: string, color: Color3, title: string, lines: { string }, order: number?)
	local box = Kit.box({
		Name = "Note",
		Parent = parent,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = order or 0,
	})
	-- a leaning marker with the icon on it, at the left
	Kit.disc({ Lean = true, Parent = box, Size = 48, Position = UDim2.fromOffset(4, 0), Color = color, Icon = icon })
	local words = Kit.box({
		Parent = box,
		Size = UDim2.new(1, -68, 0, 0),
		Position = UDim2.fromOffset(68, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
	})
	Kit.list(words, 4)
	Kit.title(title, {
		Parent = words,
		Size = UDim2.new(1, 0, 0, 24),
		TextSize = 20,
		LayoutOrder = 1,
		Wrap = false,
	})
	for i, line in lines do
		Kit.text(line, {
			Parent = words,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			TextSize = 15,
			Color = T.InkSoft,
			LayoutOrder = 1 + i,
		})
	end
	return box
end

-- trays ------------------------------------------------------------------------------------------------

local refreshTray: () -> ()
local refreshChrome: () -> ()

-- Picking a style or a finish in the tray also picks up the tool that uses it.
local function armTool()
	if subTab == "walls" or subTab == "fences" or subTab == "rooms" then
		s.wallMode = if subTab == "rooms" then "room" else "line"
		if s.tool ~= "wall" then
			BuildMode.setTool("wall")
		end
	elseif subTab == "floors" then
		if s.tool ~= "floor" then
			BuildMode.setTool("floor")
		end
	elseif subTab == "roofs" then
		if s.tool ~= "roof" then
			BuildMode.setTool("roof")
		end
	end
end

-- Ready-made buildings: a card each with the outside of the building, its size and its price.
local presetPrices: { [string]: number } = {}
local presetLooks: { [string]: { any } } = {}

local function presetLook(id: string): { any }
	if presetLooks[id] then
		return presetLooks[id]
	end
	local empty = Plan.new(Tuning.Plot.Size)
	empty.size = Tuning.Plot.Size
	local _, _, _, trial, made = Presets.check(empty, Presets.requests(id, 0, 0, 0))
	local prims = {}
	for _, m in made do
		local obj = trial[m.kind][m.key]
		local def = m.kind == "items" and Catalog.get(obj.id)
		-- the outside only: walls, roofs, doors and windows, and the garden
		if m.kind ~= "items" or (def and (def.place == "opening" or def.place == "ground")) then
			local list = Builder.primsFor(trial, m.kind, m.key)
			if list then
				for _, prim in list do
					table.insert(prims, prim)
				end
			end
		end
	end
	presetLooks[id] = prims
	return prims
end

local function presetTray()
	local row = trayRow()
	for i, preset in Presets.list do
		local b, pic, foot = card(row, preset.id, i, 150, function()
			BuildMode.startPreset(preset.id)
		end)
		b:SetAttribute("PresetId", preset.id)
		task.spawn(function()
			ModelPreview.fromPrims(presetLook(preset.id), { Parent = pic })
		end)
		cardName(b, preset.name, foot, 14)
		if not presetPrices[preset.id] then
			presetPrices[preset.id] = Presets.price(preset.id)
		end
		priceTag(b, presetPrices[preset.id], CARD_H - 22)
		-- its size, in a dark pill on the picture's corner
		local size = Kit.frame({
			Name = "Size",
			Parent = pic,
			Size = UDim2.fromOffset(0, 18),
			AutomaticSize = Enum.AutomaticSize.X,
			Position = UDim2.new(1, -4, 0, 4),
			AnchorPoint = Vector2.new(1, 0),
			Color = T.Paper,
			Radius = false,
			ZIndex = 3,
		})
		-- a small leaning tag on the picture's corner (the room round the words is on the words)
		Kit.slant(size, 18, true)
		size.Position = UDim2.new(1, -10, 0, 4)
		local sizeWords = Kit.text(Text.fill("{w} x {d}", { w = preset.w, d = preset.d }), {
			Parent = size,
			Size = UDim2.fromOffset(0, 18),
			AutomaticSize = Enum.AutomaticSize.X,
			TextSize = 12,
			Font = Kit.Fonts.Bold,
			Color = T.InkSoft,
			Wrap = false,
			ZIndex = 3,
		})
		Kit.new("UIPadding", { PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4), Parent = sizeWords })
		-- what is inside, in the hint while the mouse is on it
		b.MouseEnter:Connect(function()
			hovering = preset.desc
			refreshChrome()
		end)
		b.MouseLeave:Connect(function()
			if hovering == preset.desc then
				hovering = nil
				refreshChrome()
			end
		end)
	end
end

-- The page for choosing a picture from the Roblox library, for a piece that shows one (Catalog:
-- `picture`): what it looks like, a box to paste a decal's or an image's id into, a line saying
-- whether that one works, and the buttons. `owner` names what the page is for (a card's piece or
-- a placed one), so what was typed stays while it is the same thing. `current` is the picture
-- already on it; `onUse(id)` puts the checked one on, and `extra` adds buttons after it.
local picturePanel: (
	parent: Instance,
	owner: string,
	title: string,
	current: number?,
	useLabel: string,
	onUse: (number) -> (),
	extra: { { name: string, icon: string?, color: Color3?, run: () -> () } },
	order: number?
) -> Frame

local function pictureWords(): (string, Color3?)
	if draft.state == "checking" then
		return "Checking with Roblox...", nil
	elseif draft.state == "ok" then
		return "That one works.", T.Green
	elseif draft.state == "bad" then
		local why: string = draft.why or "that one won't work"
		return string.upper(why:sub(1, 1)) .. why:sub(2) .. ".", T.Coral
	elseif draft.state == "noid" then
		return "That isn't an id. Copy the number from the picture's Creator Store link.", T.Coral
	end
	return "Paste the id of a decal or an image from the Creator Store.", nil
end

picturePanel = function(parent, owner, title, current, useLabel, onUse, extra, order)
	if draft.owner ~= owner then
		draft = {
			owner = owner,
			text = if current then tostring(current) else "",
			id = current,
			state = if current then "ok" else "",
			why = nil,
		}
	end
	local PREVIEW = 132
	local COLUMN = 452
	local box = Kit.box({
		Name = "PicturePage",
		Parent = parent,
		Size = UDim2.fromOffset(PREVIEW + GAP + 4 + COLUMN, PREVIEW + 12),
		LayoutOrder = order or 0,
	})
	-- the picture as it will look, or an empty frame waiting for one
	local view = Kit.frame({
		Name = "PicturePreview",
		Parent = box,
		Size = UDim2.fromOffset(PREVIEW, PREVIEW),
		Position = UDim2.fromOffset(0, 6),
		Color = T.Picture,
		Radius = 8,
	})
	Kit.rim(view, T.Line, 1)
	local shown: number? = draft.id
	if shown then
		Kit.new("ImageLabel", {
			Name = "Image",
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -12, 1, -12),
			Position = UDim2.fromOffset(6, 6),
			Image = Builder.pictureUri(shown),
			ScaleType = Enum.ScaleType.Fit,
			Parent = view,
		})
	else
		Icons.make("picture", 48, {
			Name = "Empty",
			Parent = view,
			Position = UDim2.new(0.5, -24, 0.5, -24),
			Color = T.InkSoft,
			Hole = T.Picture,
		})
	end
	local column = Kit.box({
		Parent = box,
		Size = UDim2.fromOffset(COLUMN, PREVIEW + 12),
		Position = UDim2.fromOffset(PREVIEW + GAP + 4, 0),
	})
	Kit.list(column, 6).VerticalAlignment = Enum.VerticalAlignment.Center
	Kit.title(title, {
		Parent = column,
		Size = UDim2.new(1, 0, 0, 22),
		TextSize = 19,
		Wrap = false,
		LayoutOrder = 1,
	})
	local words, tint = pictureWords()
	local status = Kit.text(words, {
		Name = "PictureStatus",
		Parent = column,
		Size = UDim2.new(1, 0, 0, 34),
		TextSize = 14,
		Color = T.InkSoft,
		Tint = tint,
		LayoutOrder = 2,
	})
	status.TextYAlignment = Enum.TextYAlignment.Top
	local entry = Kit.box({ Parent = column, Size = UDim2.new(1, 0, 0, 36), LayoutOrder = 3 })
	Kit.list(entry, GAP, true)
	local field = Kit.textbox("Decal or image id", {
		Name = "PictureId",
		Parent = entry,
		Text = draft.text,
		TextSize = 16,
		Size = UDim2.fromOffset(COLUMN - 112 - GAP, 36),
		LayoutOrder = 1,
	})
	local function check()
		draft.text = field.Text
		local id = Plan.pictureId(field.Text)
		if not id then
			draft.id, draft.state, draft.why = nil, if field.Text:match("%S") then "noid" else "", nil
			refreshTray()
			return
		end
		draft.id, draft.state, draft.why = id, "checking", nil
		refreshTray()
		task.spawn(function()
			local ok, why = BuildMode.checkPicture(id)
			-- (only if the page still asks about this one)
			if draft.owner == owner and draft.id == id then
				draft.state = if ok then "ok" else "bad"
				draft.why = why
				refreshTray()
			end
		end)
	end
	field.FocusLost:Connect(function(enter)
		if enter then
			check()
		else
			draft.text = field.Text
		end
	end)
	Kit.button("Check", {
		Name = "CheckPicture",
		Parent = entry,
		Size = UDim2.fromOffset(112, 36),
		TextSize = 16,
		Color = T.Blue,
		LayoutOrder = 2,
	}, check)
	local buttons = Kit.box({ Parent = column, Size = UDim2.new(1, 0, 0, 34), LayoutOrder = 4 })
	Kit.list(buttons, GAP, true)
	local ready = draft.state == "ok" and draft.id ~= nil
	local use = Kit.button(useLabel, {
		Name = "UsePicture",
		Parent = buttons,
		Size = UDim2.fromOffset(0, 34),
		AutomaticSize = Enum.AutomaticSize.X,
		TextSize = 16,
		Icon = "check",
		Color = if ready then T.Green else T.Card,
		TextColor = if ready then T.White else T.InkSoft,
		LayoutOrder = 1,
	}, function()
		if draft.state == "ok" and draft.id then
			onUse(draft.id)
		elseif draft.state == "checking" then
			Toasts.show("Still checking that picture.", "info")
		else
			Toasts.show("Check a picture id first.", "info")
		end
	end)
	use:SetAttribute("Ready", ready)
	Kit.pad(use, 12, 0)
	for i, x in extra do
		local b = Kit.button(x.name, {
			Name = x.name,
			Parent = buttons,
			Size = UDim2.fromOffset(0, 34),
			AutomaticSize = Enum.AutomaticSize.X,
			TextSize = 16,
			Icon = x.icon,
			Color = x.color or T.Card,
			TextColor = if x.color then T.White else T.Ink,
			LayoutOrder = 1 + i,
		}, x.run)
		Kit.pad(b, 12, 0)
	end
	return box
end

-- Placing a piece that shows a picture: the page for choosing one first, then it is picked up
-- with it (or without one, to choose later by picking it).
local function picturePlaceTray(def: any)
	local stack = trayStack()
	local row = Kit.box({ Parent = stack, Size = UDim2.new(1, 0, 0, INNER_H), LayoutOrder = 1 })
	Kit.list(row, GAP * 2, true).VerticalAlignment = Enum.VerticalAlignment.Center
	picturePanel(row, "new:" .. def.id, def.name, nil, "Place it", function(id)
		pictureDef = nil
		BuildMode.startPlacing(def.id, nil, nil, id)
	end, {
		{
			name = "Place it blank",
			run = function()
				pictureDef = nil
				BuildMode.startPlacing(def.id)
			end,
		},
		{
			name = "Back",
			icon = "back",
			run = function()
				pictureDef = nil
				refreshTray()
			end,
		},
	}, 1)
	-- how it works, beside the page
	local note = Kit.box({ Parent = row, Size = UDim2.new(1, -620, 0, INNER_H), LayoutOrder = 2 })
	Kit.list(note, 0).VerticalAlignment = Enum.VerticalAlignment.Center
	Kit.hint("Find a decal or an image in the Creator Store and copy the number in its link. You can change it later by picking the piece.", {
		Name = "PictureHelp",
		Parent = note,
		Size = UDim2.new(1, -8, 0, 0),
	})
end

local function catalogTray(cat: string)
	if cat == "keepsakes" then
		local entries = Keepsakes.list(State.data.keepsakes, State.plan)
		if #entries == 0 then
			trayNote(trayStack(), "gift", T.Pink, "Nothing here yet", {
				"Things your villagers make for you go here.",
				"Keepsakes are free to put down.",
			})
			return
		end
		local row = trayRow()
		for i, entry in entries do
			keepsakeTile(row, entry, i)
		end
		return
	end
	if cat == "pictures" and pictureDef and Catalog.get(pictureDef) then
		picturePlaceTray(Catalog.get(pictureDef))
		return
	end
	local list = Catalog.list(cat)
	if cat == "paths" then
		-- the pieces to walk on (Catalog.isPath), then the floors, which double as paths
		list = Catalog.paths()
	elseif cat:sub(1, 6) == "style:" then
		-- a whole look, across every category (Catalog.withStyle)
		list = Catalog.withStyle(cat:sub(7))
	end
	if #list == 0 and cat ~= "paths" then
		trayNote(trayStack(), "layers", T.Blue, "Nothing here yet", {
			"Pieces of this kind will show up here.",
		})
		return
	end
	local row = trayRow()
	for i, def in list do
		itemTile(row, def, i, function()
			if def.picture then
				-- a picture to choose before it is placed
				pictureDef = def.id
				refreshTray()
			else
				BuildMode.startPlacing(def.id)
			end
		end)
	end
	if cat == "paths" then
		-- floors double as paths and patios outdoors
		local presets = { 11, 12, 13, 14, 15, 16 }
		for j, idx in presets do
			local preset = Palette.Presets.floors[idx]
			if preset then
				finishTile(row, preset, 100 + j, {
					w = CARD_W,
					h = CARD_H,
					sub = Text.fill("{n} a square", { n = Tuning.Prices.FloorPerCell }),
					coin = true,
				}, function()
					s.floorPaint.c, s.floorPaint.m = preset.c, preset.m
					BuildMode.setTool("floor")
					subTab = "paths"
					refreshTray()
				end)
			end
		end
	end
end

-- Walls, fences and rooms: the kinds to pick from at the left, and for walls the finish they go
-- up in beside them, outside and inside (and for a room, its floor).
local function wallTray(styles: { string }, room: boolean)
	local stack = trayStack()
	if styles == FENCE_STYLES then
		-- the fences: many kinds, in a row that scrolls sideways, and how to colour one under it
		local fences = trayRow(STYLE_H + 6, stack, 1)
		for i, id in styles do
			local def = Plan.WallStyles[id]
			styleTile(fences, def.name, STYLE_ICONS[id], i, s.wallStyle == id, Text.fill("{n} a stud", {
				n = Tuning.Prices.FencePerStud,
			}), function()
				armTool()
				s.wallStyle = id
				refreshTray()
			end)
		end
		Kit.hint("To change a fence's colour, use the Paint tool once it's up.", {
			Name = "FenceNote",
			Parent = stack,
			Size = UDim2.new(1, -8, 0, 0),
			LayoutOrder = 2,
		})
		return
	end
	local row = Kit.box({ Parent = stack, Size = UDim2.new(1, 0, 0, STYLE_H), LayoutOrder = 1 })
	Kit.list(row, GAP, true).VerticalAlignment = Enum.VerticalAlignment.Top
	for i, id in styles do
		local def = Plan.WallStyles[id]
		local per = if def.fence then Tuning.Prices.FencePerStud else Tuning.Prices.WallPerStud
		styleTile(row, def.name, STYLE_ICONS[id], i, s.wallStyle == id, Text.fill("{n} a stud", { n = per }), function()
			armTool()
			s.wallStyle = id
			refreshTray()
		end)
	end
	local taken = #styles * (STYLE_W + GAP) + GAP
	-- the finish for new walls: it takes the rest of the row, whatever the screen's width, so a
	-- wide screen shows more finishes at once
	if not room and paintSide == "floor" then
		paintSide = "a"
	end
	local paintBox = Kit.box({ Parent = row, Size = UDim2.new(1, -taken, 0, STYLE_H), LayoutOrder = 20 })
	Kit.list(paintBox, GAP)
	local top = Kit.box({ Parent = paintBox, Size = UDim2.new(1, 0, 0, 32), LayoutOrder = 1 })
	Kit.list(top, 16, true)
	local sides = { { id = "a", name = "Outside" }, { id = "b", name = "Inside" } }
	if room then
		table.insert(sides, { id = "floor", name = "Floor" })
	end
	local _, pickSide = Kit.segments(sides, function(id)
		paintSide = id
		refreshTray()
	end, { Parent = top, Height = 32, TextSize = 15, LayoutOrder = 1 })
	pickSide(paintSide)
	local cur = if paintSide == "floor" then s.floorPaint else s.wallPaint[paintSide]
	finishChip(top, "Finish", cur.c, cur.m, 2)
	local presets = trayRow(CHIP_H, paintBox, 2)
	presets.ScrollBarThickness = 3
	presets:FindFirstChildOfClass("UIListLayout").Padding = UDim.new(0, 6)
	local list = if paintSide == "floor" then Palette.Presets.floors else Palette.Presets.walls
	for i, preset in list do
		finishTile(presets, preset, i, { selected = cur.c == preset.c and cur.m == preset.m }, function()
			armTool()
			if paintSide == "floor" then
				s.floorPaint.c, s.floorPaint.m = preset.c, preset.m
			else
				s.wallPaint[paintSide] = { c = preset.c, m = preset.m }
			end
			refreshTray()
		end)
	end
end

local function floorTray()
	local stack = trayStack()
	local row = trayRow(122, stack, 1)
	for i, preset in Palette.Presets.floors do
		finishTile(row, preset, i, {
			w = 108,
			h = 120,
			selected = s.floorPaint.c == preset.c and s.floorPaint.m == preset.m,
			sub = Text.fill("{n} a square", { n = Tuning.Prices.FloorPerCell }),
			coin = true,
		}, function()
			armTool()
			s.floorPaint.c, s.floorPaint.m = preset.c, preset.m
			refreshTray()
		end)
	end
end

-- Roof controls work on new roofs (s.roof) or on a picked roof.
local function roofControls(parent: Instance, get: () -> any, set: (string, any) -> (), order: number)
	local row = Kit.box({ Parent = parent, Size = UDim2.new(1, 0, 0, STYLE_H), LayoutOrder = order })
	Kit.list(row, GAP, true).VerticalAlignment = Enum.VerticalAlignment.Top
	for i, id in Plan.RoofStyleOrder do
		styleTile(row, Plan.RoofStyles[id].name, STYLE_ICONS[id], i, get().style == id, nil, function()
			set("style", id)
		end)
	end
	local sliders = Kit.box({ Parent = row, Size = UDim2.fromOffset(260, STYLE_H), LayoutOrder = 10 })
	Kit.pad(sliders, 12, 0)
	Kit.list(sliders, 2)
	Kit.slider("Height", 0, Tuning.Plot.RoofMaxRise, get().rise, 1, function(v)
		set("rise", v)
	end, { Parent = sliders, Size = UDim2.new(1, 0, 0, 44), LayoutOrder = 1 })
	Kit.slider("Overhang", 0, Tuning.Plot.RoofMaxOverhang, get().over, 0.5, function(v)
		set("over", v)
	end, { Parent = sliders, Size = UDim2.new(1, 0, 0, 44), LayoutOrder = 2 })
	Kit.button("Turn", {
		Icon = "rotate",
		Parent = row,
		Size = UDim2.fromOffset(108, 40),
		TextSize = 17,
		Color = T.Blue,
		LayoutOrder = 11,
	}, function()
		set("dir", (get().dir + 1) % 4)
	end)
	local presets = labelledRow(parent, "Finish", CHIP_H, order + 1)
	for i, preset in Palette.Presets.roofs do
		local cur = get()
		finishTile(presets, preset, i, { selected = cur.c == preset.c and cur.m == preset.m }, function()
			set("finish", preset)
		end)
	end
end

local function roofTray()
	local stack = trayStack()
	roofControls(stack, function()
		return s.roof
	end, function(k, v)
		armTool()
		if k == "finish" then
			s.roof.c, s.roof.m = v.c, v.m
		else
			s.roof[k] = v
		end
		if k ~= "rise" and k ~= "over" then
			refreshTray()
		end
	end, 1)
end

-- The Paint tool: which colour of a piece to paint, the brush, then the finishes, the colours
-- and the materials, each in a row with its name at the left.
local function paintTray()
	local stack = trayStack(6)
	local top = Kit.box({ Parent = stack, Size = UDim2.new(1, 0, 0, 30), LayoutOrder = 1 })
	local left = Kit.box({ Parent = top, Size = UDim2.fromScale(1, 1) })
	Kit.list(left, 12, true)
	local _, pickSlot = Kit.segments({
		{ id = "main", name = "Main colour" },
		{ id = "trim", name = "Second colour" },
	}, function(id)
		s.paint.slot = id
		refreshTray()
	end, { Parent = left, Height = 30, TextSize = 14, LayoutOrder = 1 })
	pickSlot(s.paint.slot)
	Kit.button(if s.paint.pick then "Now click something" else "Copy a colour", {
		Name = "CopyColour",
		Icon = "bucket",
		Parent = left,
		Size = UDim2.fromOffset(190, 30),
		TextSize = 15,
		Color = if s.paint.pick then T.Yellow else T.Card,
		TextColor = if s.paint.pick then T.Dark else T.Ink,
		LayoutOrder = 2,
	}, function()
		s.paint.pick = not s.paint.pick
		refreshTray()
		refreshChrome()
	end)
	-- what the brush holds, at the right
	local right = Kit.box({ Parent = top, Size = UDim2.fromScale(1, 1) })
	Kit.list(right, 6, true, Enum.HorizontalAlignment.Right)
	finishChip(right, "Brush", s.paint.c, s.paint.m, 1)
	local finishes = labelledRow(stack, "Finishes", CHIP_H, 2)
	local all = {}
	for _, list in { Palette.Presets.walls, Palette.Presets.floors, Palette.Presets.roofs } do
		for _, p in list do
			table.insert(all, p)
		end
	end
	for i, preset in all do
		finishTile(finishes, preset, i, { selected = s.paint.c == preset.c and s.paint.m == preset.m }, function()
			s.paint.c, s.paint.m = preset.c, preset.m
			refreshTray()
		end)
	end
	swatchRow(stack, "Colours", s.paint.c, function(hex)
		s.paint.c = hex
		refreshTray()
	end, 3)
	materialRow(stack, s.paint.m, function(m)
		s.paint.m = m
		refreshTray()
	end, 4)
end

-- What you can do with the picked object.
local function selectionTray()
	local kind, _, obj = BuildMode.selectedObject()
	local stack = trayStack()
	if not kind or not obj then
		trayNote(stack, "pointer", T.Blue, "Click something to pick it", {
			"A wall, a floor, a roof or a piece of furniture.",
		}, 1)
		Kit.hint("R turns what you hold, right click puts it away and Ctrl+Z undoes.", {
			Parent = stack,
			Size = UDim2.new(1, -8, 0, 0),
			LayoutOrder = 2,
		})
		return
	end
	if kind == "items" and Catalog.get(obj.id) and (Catalog.get(obj.id) :: any).picture then
		-- a piece that shows a picture: the page for choosing it, and its colours beside it
		local def = Catalog.get(obj.id) :: any
		local key = s.selected.key
		local row = Kit.box({ Parent = stack, Size = UDim2.new(1, 0, 0, INNER_H), LayoutOrder = 1 })
		local extra = {}
		if obj.img then
			table.insert(extra, {
				name = "Take it off",
				run = function()
					draft.owner = ""
					BuildMode.editSelected({ img = false })
				end,
			})
		end
		picturePanel(row, "item:" .. key, def.name, obj.img, "Use it", function(id)
			BuildMode.editSelected({ img = id })
		end, extra, 1)
		local colours = Kit.box({
			Parent = row,
			Size = UDim2.new(1, -612, 0, 2 * (SWATCH + RING * 2) + GAP),
			Position = UDim2.new(0, 612, 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5),
		})
		Kit.list(colours, GAP)
		for i, slot in { { "c1", "Main colour" }, { "c2", "Second colour" } } do
			local cur = obj[slot[1]] or (if slot[1] == "c1" then def.c1 else (def.c2 or def.c1))
			swatchRow(colours, slot[2], cur, function(hex)
				BuildMode.editSelected({ [slot[1]] = hex })
			end, i)
		end
	elseif kind == "items" then
		local def = Catalog.get(obj.id) :: any
		-- its name, then its two colours
		local head = Kit.box({ Parent = stack, Size = UDim2.new(1, 0, 0, 24), LayoutOrder = 0 })
		Kit.list(head, 12, true)
		Kit.title(def.name, {
			Parent = head,
			Size = UDim2.fromOffset(0, 24),
			AutomaticSize = Enum.AutomaticSize.X,
			TextSize = 19,
			Wrap = false,
			LayoutOrder = 1,
		})
		Kit.text("Click a colour to paint it.", {
			Parent = head,
			Size = UDim2.fromOffset(0, 24),
			AutomaticSize = Enum.AutomaticSize.X,
			TextSize = 15,
			Color = T.InkSoft,
			Wrap = false,
			LayoutOrder = 2,
		})
		for i, slot in { { "c1", "Main colour" }, { "c2", "Second colour" } } do
			local cur = obj[slot[1]] or (if slot[1] == "c1" then def.c1 else (def.c2 or def.c1))
			swatchRow(stack, slot[2], cur, function(hex)
				BuildMode.editSelected({ [slot[1]] = hex })
			end, i)
		end
	elseif kind == "roofs" then
		local shown = table.clone(obj)
		roofControls(stack, function()
			return shown
		end, function(k, v)
			if k == "finish" then
				BuildMode.editSelected({ c = v.c, m = v.m })
			elseif k == "rise" or k == "over" then
				-- sliders send once they settle, not on every step of the drag
				shown[k] = v
				holdTray = os.clock() + 0.8
				sliderToken += 1
				local token = sliderToken
				task.delay(0.35, function()
					if token == sliderToken then
						BuildMode.editSelected({ rise = shown.rise, over = shown.over })
					end
				end)
			else
				BuildMode.editSelected({ [k] = v })
			end
		end, 1)
	elseif kind == "walls" then
		-- every kind of wall and fence it can become, in a row that scrolls sideways
		local row = trayRow(STYLE_H + 6, stack, 1)
		for i, id in Plan.WallStyleOrder do
			styleTile(row, Plan.WallStyles[id].name, STYLE_ICONS[id], i, obj.style == id, nil, function()
				BuildMode.editSelected({ style = id })
			end)
		end
		Kit.hint("Each side of a wall takes its own colour. Use the Paint tool on either side.", {
			Name = "WallNote",
			Parent = stack,
			Size = UDim2.new(1, -8, 0, 0),
			LayoutOrder = 2,
		})
	elseif kind == "floors" then
		local row = labelledRow(stack, "Finish", CHIP_H, 1)
		for i, preset in Palette.Presets.floors do
			finishTile(row, preset, i, { selected = obj.c == preset.c and obj.m == preset.m }, function()
				BuildMode.editSelected({ c = preset.c, m = preset.m })
			end)
		end
	end
end

local function sellTray()
	local stack = trayStack()
	trayNote(stack, "trash", T.Coral, "Click something to sell it", {
		"You get back what you paid. Undo brings it back.",
	}, 1)
	Kit.hint("The starting house was a gift, so its pieces sell for nothing.", {
		Parent = stack,
		Size = UDim2.new(1, -8, 0, 0),
		LayoutOrder = 2,
	})
end

refreshTray = function()
	clear(trayBody)
	local tool = s.tool
	if tool == "paint" then
		trayMode = "paint"
		paintTray()
	elseif tool == "delete" then
		trayMode = "sell"
		sellTray()
	elseif tool == "select" and s.selected then
		trayMode = "select"
		selectionTray()
	elseif subTab == "buildings" then
		trayMode = "buildings"
		presetTray()
	elseif subTab == "walls" then
		trayMode = "walls"
		wallTray(WALL_STYLES, false)
	elseif subTab == "rooms" then
		trayMode = "rooms"
		wallTray(WALL_STYLES, true)
	elseif subTab == "fences" then
		trayMode = "fences"
		wallTray(FENCE_STYLES, false)
	elseif subTab == "floors" then
		trayMode = "floors"
		floorTray()
	elseif subTab == "roofs" then
		trayMode = "roofs"
		roofTray()
	else
		trayMode = "catalog:" .. subTab
		catalogTray(subTab)
	end
end

-- choosing tabs -------------------------------------------------------------------------------------------

local function openSub(id: string)
	local was = subTab
	subTab = id
	pictureDef = nil
	for sid, b in subButtons do
		Kit.setButtonColor(b, if sid == id then T.Yellow else T.Paper, if sid == id then T.Dark else T.Ink)
	end
	if was and was ~= id and subButtons[was] and subButtons[id] then
		Kit.glide(subButtons[was], subButtons[id])
	end
	-- at the right end of the well: which one of how many, and its name set wide
	local main
	for _, m in MAIN do
		if m.id == mainTab then
			main = m
		end
	end
	if main and subCaption and subIndex then
		for i, sub in main.subs do
			if sub.id == id then
				subIndex.Text = Kit.index(i) .. " / " .. Kit.index(#main.subs)
				subCaption.Text = Kit.spaced(sub.name)
			end
		end
	end
	if id == "walls" or id == "fences" then
		s.wallMode = "line"
		if id == "fences" and not Plan.WallStyles[s.wallStyle].fence then
			s.wallStyle = "fence"
		elseif id == "walls" and Plan.WallStyles[s.wallStyle].fence then
			s.wallStyle = "wall"
		end
		BuildMode.setTool("wall")
	elseif id == "rooms" then
		s.wallMode = "room"
		if Plan.WallStyles[s.wallStyle].fence then
			s.wallStyle = "wall"
		end
		BuildMode.setTool("wall")
	elseif id == "floors" then
		BuildMode.setTool("floor")
	elseif id == "roofs" then
		BuildMode.setTool("roof")
	else
		BuildMode.setTool("place")
		s.placing = nil
	end
	refreshTray()
end

local function openMain(id: string)
	local was = mainTab
	mainTab = id
	for mid, b in mainButtons do
		Kit.setButtonColor(b, if mid == id then T.Yellow else T.Paper, if mid == id then T.Dark else T.Ink)
	end
	-- the yellow slides over from the group picked before
	if was and was ~= id and mainButtons[was] and mainButtons[id] then
		Kit.glide(mainButtons[was], mainButtons[id])
	end
	clear(subBar)
	subButtons = {}
	local main
	for _, m in MAIN do
		if m.id == id then
			main = m
		end
	end
	for i, sub in main.subs do
		local b = Kit.tile(sub.icon, sub.name, {
			Parent = subBar,
			Size = UDim2.fromOffset(88, TILE_H),
			LayoutOrder = i,
			Color = T.Paper,
		})
		subButtons[sub.id] = b
		b.Activated:Connect(function()
			openSub(sub.id)
		end)
	end
	openSub(main.subs[1].id)
end

-- tools ---------------------------------------------------------------------------------------------------

local function needSelection(): boolean
	if s.selected then
		return true
	end
	Toasts.show("Pick something first.", "info")
	BuildMode.setTool("select")
	return false
end

local TOOLS = {
	{
		id = "select",
		icon = "pointer",
		name = "Pick",
		run = function()
			BuildMode.setTool("select")
		end,
	},
	{
		id = "move",
		icon = "move",
		name = "Move",
		needs = true,
		run = function()
			if needSelection() then
				BuildMode.moveSelected()
			end
		end,
	},
	{
		id = "rotate",
		icon = "rotate",
		name = "Turn",
		needs = true,
		run = function()
			if s.placing then
				BuildMode.rotate(45)
			elseif needSelection() then
				BuildMode.rotate(45)
			end
		end,
	},
	{
		id = "copy",
		icon = "copy",
		name = "Copy",
		needs = true,
		run = function()
			if needSelection() then
				BuildMode.copySelected()
			end
		end,
	},
	{
		id = "paint",
		icon = "brush",
		name = "Paint",
		run = function()
			BuildMode.setTool("paint")
		end,
	},
	{
		id = "delete",
		icon = "trash",
		name = "Sell",
		run = function()
			BuildMode.setTool("delete")
		end,
	},
	{ id = "undo", icon = "undo", name = "Undo", run = BuildMode.undo },
	{ id = "redo", icon = "redo", name = "Redo", run = BuildMode.redo },
}
local NEEDS: { [string]: boolean } = {}
for _, tool in TOOLS do
	NEEDS[tool.id] = tool.needs == true
end

-- What the tool in hand does, in a line short enough to sit over the tools. (On a touch screen the
-- held piece is placed with a tap and turned or put away with the round buttons beside the hint.)
local TOUCH_HINTS = {
	place = "Tap to place it. The buttons turn it or put it away.",
	preset = "Tap to put it down. The buttons turn it or put it away.",
}
local HINTS = {
	select = "Click something to pick it.",
	wall = "Drag to draw a wall. Right click stops.",
	fence = "Drag to put up a fence. Right click stops.",
	room = "Drag across the ground to make a room.",
	floor = "Drag across the ground to lay a floor.",
	roof = "Drag over the walls to put a roof on.",
	place = "Click to place it. R turns it, right click puts it away.",
	preset = "Click to put it down. R turns it, right click puts it away.",
	paint = "Click a wall, floor, roof or item to paint it.",
	copy = "Click something to copy its colour.",
	delete = "Click something to sell it.",
}

-- The floors card's switches, by icon alone (the user: "change this part to 5 icons, 2 arrows, 3
-- toggleable icons in a row with no need for text"). Their names are what the hint says while the
-- mouse is on them, and what the simulation presses them by.
local VIEW = {
	{ id = "roofs", icon = "roof", name = "Hide roofs" },
	{ id = "walls", icon = "wallGlass", name = "See-through walls" },
	{ id = "snap", icon = "grid", name = "Snap to grid" },
}

local function viewOn(id: string): boolean
	if id == "roofs" then
		return s.roofsHidden == true
	elseif id == "walls" then
		return s.seeThrough == true
	end
	return s.snap == true
end

-- What a switch did, said in the hint for a moment after it changes.
local function viewWords(id: string): string
	local on = viewOn(id)
	if id == "roofs" then
		return if on then "Roofs hidden" else "Roofs shown"
	elseif id == "walls" then
		return if on then "Walls see-through" else "Walls solid"
	end
	return if on then "Snap to grid on" else "Snap to grid off"
end

-- What the floors card's button under the mouse would do, for the hint.
local function viewTip(id: string): string
	local top = Tuning.Plot.Levels - 1
	if id == "down" then
		return if s.level > 0 then Text.fill("Down to floor {n}", { n = s.level }) else "This is the ground floor"
	elseif id == "up" then
		return if s.level < top then Text.fill("Up to floor {n}", { n = s.level + 2 }) else "This is the top floor"
	end
	local on = viewOn(id)
	if id == "roofs" then
		return if on then "Show the roofs" else "Hide the roofs"
	elseif id == "walls" then
		return if on then "Make the walls solid again" else "See through the walls"
	end
	return if on then "Stop snapping to the grid" else "Snap to the grid"
end

-- Says what changed in the hint line over the tools for a moment.
local function flash(text: string)
	flashText = text
	flashToken += 1
	local token = flashToken
	refreshChrome()
	task.delay(1.6, function()
		if token == flashToken then
			flashText = nil
			refreshChrome()
		end
	end)
end

-- One of the floors card's icon buttons: a rounded square in a thin rim, yellow with a dark icon
-- while it is on, the plain dark one with a light icon while it is off (or dim, when it can't be
-- pressed).
local function paintViewButton(b: GuiButton, on: boolean, dim: boolean?)
	local face = b:FindFirstChild("Face")
	local color = if on then T.Yellow else T.Card
	if face and face:IsA("Frame") then
		Kit.paint(face, color)
	end
	local art = b:FindFirstChild("IconArt")
	if art then
		Kit.recolorIcon(art, if on then T.Dark elseif dim then T.InkSoft else T.Ink, color)
	end
	b:SetAttribute("On", on)
end

refreshChrome = function()
	for _, tool in TOOLS do
		local b = toolButtons[tool.id]
		local on = (tool.id == "select" and s.tool == "select")
			or (tool.id == "paint" and s.tool == "paint")
			or (tool.id == "delete" and s.tool == "delete")
			or (tool.id == "move" and s.placing ~= nil and s.placing.moveKey ~= nil)
		-- Move, Turn and Copy need something picked (Turn also turns what you are placing): they
		-- are dimmed until then, and pressing one says so
		local idle = NEEDS[tool.id] and not s.selected and not (tool.id == "rotate" and s.placing ~= nil)
		Kit.setButtonColor(b, if on then T.Yellow else T.Paper, if on then T.Dark elseif idle then T.InkSoft else T.Ink)
	end
	local top = Tuning.Plot.Levels - 1
	paintViewButton(levelDown, false, s.level <= 0)
	paintViewButton(levelUp, false, s.level >= top)
	for _, v in VIEW do
		paintViewButton(viewButtons[v.id], viewOn(v.id))
	end
	local hint = HINTS[s.tool] or ""
	if s.tool == "wall" then
		hint = if s.wallMode == "room"
			then HINTS.room
			elseif Plan.WallStyles[s.wallStyle] and Plan.WallStyles[s.wallStyle].fence then HINTS.fence
			else HINTS.wall
	elseif s.tool == "paint" and s.paint.pick then
		hint = HINTS.copy
	elseif s.tool == "place" and not s.placing then
		hint = "Pick something from the tray below."
	end
	if holdingNow and Kit.isTouch() and TOUCH_HINTS[s.tool] then
		hint = TOUCH_HINTS[s.tool]
	end
	if hovering and (s.tool == "place" or s.tool == "preset") then
		hint = hovering
	end
	-- the floors card's buttons have no words of their own: the hint names the one under the
	-- mouse, and says what just changed
	if overView then
		hint = viewTip(overView)
	end
	if flashText then
		hint = flashText
	end
	hintLabel.Text = hint
	hintPill.Visible = not actionBar.Visible or overView ~= nil or flashText ~= nil
end

-- holding a piece: the interface steps aside --------------------------------------------------------------

-- How far each part goes while a piece is held: the bottom ones down off the screen, the coins
-- and the camera help at the top left up off it.
local AWAY: { [string]: number } =
	{ Dock = 460, Catalog = 460, Tools = 460, Floors = 460, Pill = -140, CameraTip = -140 }
local HINT_HOME = UDim2.new(0, EDGE + 12, 1, -HINT_AT)
-- beside the hint while a piece is held: the red way back (it puts the piece away, as a right
-- click does) and, on a touch screen, a round button that turns it
local HOLD_W = 84
local TURN_W = 52
local function hintLow(): UDim2
	return UDim2.new(0, EDGE + 12 + HOLD_W + GAP + (if Kit.isTouch() then TURN_W + GAP else 0), 1, -(EDGE + 12))
end

-- Is a piece in hand, following the pointer to be placed (from a card, or picked up to move or
-- copy)? The tools that draw keep their trays.
local function isHolding(): boolean
	return s.active and ((s.tool == "place" and s.placing ~= nil) or s.tool == "preset")
end

-- Slides the interface away while a piece is held, and back when it is put away. `instant` puts
-- it straight where it belongs (leaving Build mode). What has gone is hidden as well, so nothing
-- off the screen is ever counted as under the pointer.
local function setHolding(on: boolean, instant: boolean?)
	if on == holdingNow and not instant then
		return
	end
	holdingNow = on
	slideToken += 1
	local token = slideToken
	if on then
		-- a card or a button the mouse was on has gone from under it
		overView, hovering = nil, nil
	end
	for _, f in ui:GetChildren() do
		local dy = AWAY[f.Name]
		if dy and f:IsA("GuiObject") then
			local home = f:GetAttribute("Home")
			if typeof(home) ~= "UDim2" then
				home = f.Position
				f:SetAttribute("Home", home)
			end
			local away = (home :: UDim2) + UDim2.fromOffset(0, dy)
			if instant then
				f.Position = if on then away else home
				f.Visible = not on
			elseif on then
				TweenService:Create(f, TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
					Position = away,
				}):Play()
				task.delay(0.3, function()
					if token == slideToken then
						f.Visible = false
					end
				end)
			else
				-- back from wherever it is, easing out to rest
				f.Visible = true
				TweenService:Create(f, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
					Position = home,
				}):Play()
			end
		end
	end
	-- the hint stays, down where the bars were (and on a touch screen the two round buttons that
	-- turn the piece and put it away stand beside it)
	local target = if on then hintLow() else HINT_HOME
	if instant then
		hintPill.Position = target
	else
		TweenService:Create(hintPill, TweenInfo.new(0.34, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
			Position = target,
		}):Play()
	end
	-- the way back (and on a touch screen the round button that turns the piece) beside it
	local touch = Kit.isTouch()
	local turn = touchButtons:FindFirstChild("Turn it")
	if turn and turn:IsA("GuiObject") then
		turn.Visible = touch
	end
	touchButtons.Size = UDim2.fromOffset(HOLD_W + (if touch then TURN_W + GAP else 0), 52)
	touchButtons.Visible = on
	refreshChrome()
end

-- the action bar over the picked object ---------------------------------------------------------------------

-- What selling the picked thing gives back, and whether any of it was a gift.
local function sellValue(kind: string, key: string): (number, boolean)
	local ops = Plan.removeOps(State.plan, kind, key)
	local gift = false
	for _, op in ops do
		local g = op.obj and op.obj.gift
		if type(g) == "number" and g > 0 then
			gift = true
		end
	end
	return -Plan.changeCost(ops), gift
end

local function refreshActionBar()
	clear(actionButtons)
	clear(actionValue)
	local kind, key, obj = BuildMode.selectedObject()
	if not kind or not obj or s.tool ~= "select" then
		actionBar.Visible = false
		hintPill.Visible = true
		return
	end
	local name = "Wall"
	if kind == "items" then
		local def = Catalog.get(obj.id)
		name = if def then def.name else obj.id
	elseif kind == "walls" then
		name = (Plan.WallStyles[obj.style] or Plan.WallStyles.wall).name
	elseif kind == "floors" then
		name = string.format("Floor %d x %d", obj.x2 - obj.x1, obj.z2 - obj.z1)
	elseif kind == "roofs" then
		name = (Plan.RoofStyles[obj.style] or Plan.RoofStyles.gable).name .. " roof"
	end
	actionTitle.Text = name
	-- what it sells for: coins with the coin, or plainly nothing when it was a gift
	local value, gift = sellValue(kind, key :: string)
	if value > 0 then
		Kit.text("Sells for", {
			Parent = actionValue,
			Size = UDim2.fromOffset(0, 20),
			AutomaticSize = Enum.AutomaticSize.X,
			TextSize = 15,
			Color = T.InkSoft,
			Wrap = false,
			LayoutOrder = 1,
		})
		Icons.make("coin", 18, { Parent = actionValue, LayoutOrder = 2 })
		Kit.title(Text.commas(value), {
			Parent = actionValue,
			Size = UDim2.fromOffset(0, 20),
			AutomaticSize = Enum.AutomaticSize.X,
			TextSize = 16,
			Wrap = false,
			LayoutOrder = 3,
		})
	else
		Kit.text(if gift then "A gift, so it sells for nothing" else "Sells for nothing", {
			Parent = actionValue,
			Size = UDim2.fromOffset(0, 20),
			AutomaticSize = Enum.AutomaticSize.X,
			TextSize = 15,
			Color = T.InkSoft,
			Wrap = false,
			LayoutOrder = 1,
		})
	end
	local function act(icon: string, caption: string, fn: () -> (), order: number)
		local sell = icon == "trash"
		Kit.tile(icon, caption, {
			Parent = actionButtons,
			Size = UDim2.fromOffset(60, 58),
			LayoutOrder = order,
			Color = if sell then T.Coral else T.Card,
			TextColor = if sell then T.Dark else T.Ink,
		}, fn)
	end
	if kind == "items" then
		act("move", "Move", BuildMode.moveSelected, 1)
		act("rotate", "Turn", function()
			BuildMode.rotate(45)
		end, 2)
		act("copy", "Copy", BuildMode.copySelected, 3)
	elseif kind == "roofs" then
		act("rotate", "Turn", function()
			BuildMode.rotate(45)
		end, 2)
	end
	act("trash", "Sell", BuildMode.deleteSelected, 9)
	actionBar.Visible = true
	-- the popup says what to do now, so the hint over the tools steps aside (unless something on
	-- the floors card is being named or just changed)
	hintPill.Visible = overView ~= nil or flashText ~= nil
end

local function followSelection()
	if not actionBar.Visible then
		return
	end
	local model = BuildMode.selectedModel()
	local cam = workspace.CurrentCamera
	if not model or not cam then
		actionBar.Visible = false
		hintPill.Visible = true
		return
	end
	local cf, size = model:GetBoundingBox()
	local top = cf.Position + Vector3.new(0, size.Y / 2 + 1, 0)
	local p, onScreen = cam:WorldToViewportPoint(top)
	if not onScreen then
		actionBar.Position = UDim2.fromOffset(-1000, -1000)
		return
	end
	local inset = GuiService:GetGuiInset()
	local scale = (Kit.root():FindFirstChild("Scale") :: UIScale).Scale
	local view = cam.ViewportSize
	local W, H = view.X / scale, (view.Y - inset.Y) / scale
	local w, h = actionBar.AbsoluteSize.X / scale, actionBar.AbsoluteSize.Y / scale
	-- over the thing, but inside the screen and clear of every bar: above the tray, the tools
	-- and the floors card where it is over them, and below the coins at the top left
	local x = math.clamp((p.X - inset.X) / scale, EDGE + w / 2, math.max(EDGE + w / 2, W - EDGE - w / 2))
	local bottom = (p.Y - inset.Y) / scale - 12
	local left, right = x - w / 2, x + w / 2
	local lowest = H - (CATALOG_AT + CATALOG_H) - GAP
	if left < EDGE + #TOOLS * TOOL_W + SIDE * 2 then
		lowest = math.min(lowest, H - (TOOLS_AT + TOOLS_H) - GAP)
	end
	if right > W - EDGE - FLOORS_W then
		lowest = math.min(lowest, H - (TOOLS_AT + FLOORS_H) - GAP)
	end
	bottom = math.min(bottom, lowest)
	if hintPill.Visible and left < (hintPill.AbsolutePosition.X + hintPill.AbsoluteSize.X) / scale then
		-- the hint is up over the tools (something on the floors card just changed): keep above it
		lowest = math.min(lowest, H - HINT_AT - 34 - GAP)
	end
	local highest = if left < TOP_LEFT_W then TOP_LEFT_H + GAP else EDGE
	bottom = math.max(bottom, highest + h)
	actionBar.Position = UDim2.fromOffset(x, bottom)
end

-- building the screen ----------------------------------------------------------------------------------------

function BuildUI.init(exitCallback: () -> ())
	onExit = exitCallback
	if built then
		return -- built once; a second call only changes what Done does
	end
	built = true
	local gui = Kit.root()
	ui = Kit.box({ Name = "BuildUI", Size = UDim2.fromScale(1, 1), Parent = gui, Visible = false })

	-- Laid out the way the best known house builder on Roblox lays its build mode out (the user:
	-- "The building ui should be exactly like bloxburg instead of what is shown now"): everything
	-- to build with is docked in the bottom left corner, the tools in a row on top, then the
	-- things to place as cards with price tags, then the categories as icon tiles, then the main
	-- groups; the floors and view switches sit at the right, and the way out is one big button
	-- in the bottom right corner. Its layout and flow are what is taken, drawn our own way.
	-- Then the user: "build mode should have the right part with all the decor and details filling
	-- the whole screen horizontally, and the right side should be moved up". So the catalog runs
	-- from one edge of the screen to the other (its width is a share of the screen, never a count
	-- of pixels) and the floors card sits on top of it at the right. And of the bar along the
	-- bottom: "the first screenshot part in the builder should have the background across the
	-- whole strip instead of leaving a gap", so the main groups and Done share one bar as wide
	-- as the screen, the groups at its left end and Done at its right.

	-- the main groups and the way out, on one bar along the bottom
	local dockButtonW = 148
	local dock = Kit.frame({
		Name = "Dock",
		Size = UDim2.new(1, -EDGE * 2, 0, DOCK_H),
		Position = UDim2.new(0, EDGE, 1, -EDGE),
		AnchorPoint = Vector2.new(0, 1),
		Color = T.Paper,
		Cut = CUT,
		Parent = ui,
	})
	local dockRow = Kit.box({
		Parent = dock,
		Size = UDim2.new(1, -SIDE * 2, 1, -PAD * 2),
		Position = UDim2.fromOffset(SIDE, PAD),
	})
	Kit.list(dockRow, GAP, true)
	for i, m in MAIN do
		local b = Kit.button(m.name, {
			Parent = dockRow,
			Size = UDim2.fromOffset(dockButtonW, DOCK_H - PAD * 2),
			TextSize = 20,
			Color = T.Paper,
			TextColor = T.Ink,
			LayoutOrder = i,
			Icon = m.icon,
		})
		mainButtons[m.id] = b
		b.Activated:Connect(function()
			openMain(m.id)
		end)
	end
	-- the way out, at the bar's right end, red as every way out is
	Kit.button("Done", {
		Parent = dock,
		Name = "Done",
		Size = UDim2.fromOffset(196, DOCK_H - PAD * 2),
		Position = UDim2.new(1, -SIDE, 0, PAD),
		AnchorPoint = Vector2.new(1, 0),
		TextSize = 24,
		Color = T.Red,
		Icon = "close",
		ZIndex = 2,
	}, function()
		if onExit then
			onExit()
		end
	end)

	-- the catalog above it: one card holding the category tiles (in a deeper well of their own,
	-- scrolling sideways when there are many) and the tray of things to place and options, whose
	-- rows scroll sideways. Which of the two is on top is CATEGORIES_ON_TOP's to say.
	local catalog = Kit.frame({
		Name = "Catalog",
		Size = UDim2.new(1, -EDGE * 2, 0, CATALOG_H),
		Position = UDim2.new(0, EDGE, 1, -CATALOG_AT),
		AnchorPoint = Vector2.new(0, 1),
		Color = T.Paper,
		Cut = CUT,
		Parent = ui,
	})
	-- a little blue glowing in from its top right, for depth
	Kit.glow(catalog, T.Blue, 0.16)
	local wellY = if CATEGORIES_ON_TOP then PAD else PAD + INNER_H + PAD
	local trayY = if CATEGORIES_ON_TOP then PAD + WELL_H + PAD else PAD
	local well = Kit.frame({
		Name = "SubsBar",
		Parent = catalog,
		Size = UDim2.new(1, -PAD * 2, 0, WELL_H),
		Position = UDim2.fromOffset(PAD, wellY),
		Color = T.Cream,
		Radius = 10,
		ZIndex = 2,
	})
	Kit.rim(well, T.Line, 1)
	subBar = Kit.scroll({
		Name = "Subs",
		Parent = well,
		Size = UDim2.new(1, -WELL_PAD * 2 - SUB_NOTE, 0, TILE_H),
		Position = UDim2.fromOffset(WELL_PAD, WELL_PAD),
		Axis = Enum.AutomaticSize.X,
	})
	-- the picked category at the well's right end: its number in yellow over its name set wide,
	-- with a rule between them that ends in a dot
	local note = Kit.box({
		Name = "SubNote",
		Parent = well,
		Size = UDim2.new(0, SUB_NOTE - 16, 1, 0),
		Position = UDim2.new(1, -12, 0, 0),
		AnchorPoint = Vector2.new(1, 0),
	})
	note.ZIndex = 2
	subIndex = Kit.title("", {
		Name = "Index",
		Parent = note,
		Size = UDim2.new(1, 0, 0, 22),
		Position = UDim2.fromOffset(0, 10),
		TextSize = 20,
		Tint = T.Yellow,
		AlignX = Enum.TextXAlignment.Right,
		Wrap = false,
	})
	Kit.rule({
		Name = "Rule",
		Parent = note,
		Size = UDim2.new(1, 0, 0, 6),
		Position = UDim2.fromOffset(0, 38),
		AnchorPoint = Vector2.new(0, 0.5),
		Color = T.Line,
		Dots = "both",
	})
	subCaption = Kit.caption("", {
		Name = "Caption",
		Parent = note,
		Size = UDim2.new(1, 0, 0, 14),
		Position = UDim2.fromOffset(0, 46),
		AlignX = Enum.TextXAlignment.Right,
	})
	subBar.ScrollBarThickness = 0
	Kit.list(subBar, 0, true)
	tray = Kit.box({
		Name = "Tray",
		Parent = catalog,
		Size = UDim2.new(1, -SIDE * 2, 0, INNER_H),
		Position = UDim2.fromOffset(SIDE, trayY),
		ZIndex = 2,
	})
	trayBody = tray

	-- the tools, in a row on top of the tray
	local strip = Kit.frame({
		Name = "Tools",
		Size = UDim2.fromOffset(#TOOLS * TOOL_W + SIDE * 2, TOOLS_H),
		Position = UDim2.new(0, EDGE, 1, -TOOLS_AT),
		AnchorPoint = Vector2.new(0, 1),
		Color = T.Paper,
		Cut = CUT,
		Parent = ui,
	})
	local stripRow = Kit.box({
		Parent = strip,
		Size = UDim2.new(1, -SIDE * 2, 1, -PAD * 2),
		Position = UDim2.fromOffset(SIDE, PAD),
	})
	Kit.list(stripRow, 0, true)
	for i, tool in TOOLS do
		local b = Kit.tile(tool.icon, tool.name, {
			Parent = stripRow,
			Size = UDim2.fromOffset(TOOL_W, TILE_H),
			LayoutOrder = i,
			Color = T.Paper,
		}, tool.run)
		toolButtons[tool.id] = b
	end

	-- what the tool in hand does, above the tools
	hintPill = Kit.darkPill({
		Name = "Hint",
		Size = UDim2.fromOffset(0, 34),
		Position = UDim2.new(0, EDGE + 12, 1, -HINT_AT),
		AnchorPoint = Vector2.new(0, 1),
		Parent = ui,
	})
	hintPill.AutomaticSize = Enum.AutomaticSize.X
	Kit.pad(hintPill, 6, 0)
	hintLabel = Kit.title("", {
		Parent = hintPill,
		Size = UDim2.fromOffset(0, 34),
		AutomaticSize = Enum.AutomaticSize.X,
		TextSize = 16,
		Color = T.White,
		Wrap = false,
	})
	-- while a piece is held, the way back stands beside the hint for everyone: the red leaning
	-- button every menu has, and it does what a right click does (the user: "add a back button
	-- while having a building being put down that does the same as right click"). A touch screen
	-- has no R either, so a round button beside it turns the piece there.
	touchButtons = Kit.box({
		Name = "Holding",
		Size = UDim2.fromOffset(HOLD_W, 52),
		Position = UDim2.new(0, EDGE + 12, 1, -(EDGE + 3)),
		AnchorPoint = Vector2.new(0, 1),
		Visible = false,
		Parent = ui,
	})
	Kit.list(touchButtons, GAP, true)
	local putAway = Kit.backButton({ Parent = touchButtons, Size = UDim2.fromOffset(HOLD_W, 46) }, function()
		BuildMode.putAway()
	end)
	putAway.Name = "Put it away"
	putAway.LayoutOrder = 0
	Kit.roundButton("rotate", { Name = "Turn it", Parent = touchButtons, Size = TURN_W, LayoutOrder = 1 }, function()
		BuildMode.rotate(45)
	end)

	-- the floors and the view switches, at the right on top of the catalog (level with the tools):
	-- one row of icon buttons, the arrows, a quiet line, then the three switches (the user:
	-- "change this part to 5 icons, 2 arrows, 3 toggleable icons in a row with no need for text")
	local floors = Kit.frame({
		Name = "Floors",
		Size = UDim2.fromOffset(FLOORS_W, FLOORS_H),
		Position = UDim2.new(1, -EDGE, 1, -TOOLS_AT),
		AnchorPoint = Vector2.new(1, 1),
		Color = T.Paper,
		Cut = CUT,
		Parent = ui,
	})
	local floorsRow = Kit.box({
		Parent = floors,
		Size = UDim2.new(1, -SIDE * 2, 1, -PAD * 2),
		Position = UDim2.fromOffset(SIDE, PAD),
	})
	Kit.list(floorsRow, 0, true)
	local function viewButton(name: string, icon: string, id: string, order: number, run: () -> ()): TextButton
		local b = Kit.new("TextButton", {
			Name = name,
			Text = "",
			AutoButtonColor = false,
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(VIEW_BTN, TILE_H),
			LayoutOrder = order,
			Parent = floorsRow,
		})
		local face = Kit.new("Frame", {
			Name = "Face",
			BackgroundColor3 = T.Card,
			BorderSizePixel = 0,
			Size = UDim2.new(1, -4, 1, -2),
			Position = UDim2.fromOffset(2, 1),
			Parent = b,
		})
		Kit.corner(face, 9)
		Kit.rim(face, Kit.edgeOf(T.Card), 1):SetAttribute("Follow", true)
		local ipx = 30
		Icons.make(icon, ipx, {
			Name = "IconArt",
			Parent = b,
			Position = UDim2.new(0.5, -ipx / 2, 0.5, -ipx / 2),
			Color = T.Ink,
			Hole = T.Card,
			ZIndex = 2,
		})
		hoverable(b)
		b.MouseEnter:Connect(function()
			overView = id
			refreshChrome()
		end)
		b.MouseLeave:Connect(function()
			if overView == id then
				overView = nil
				refreshChrome()
			end
		end)
		b.Activated:Connect(run)
		return b
	end
	levelDown = viewButton("FloorDown", "down", "down", 1, function()
		if s.level <= 0 then
			flash(viewTip("down"))
		end
		BuildMode.setLevel(s.level - 1)
	end)
	levelUp = viewButton("FloorUp", "up", "up", 2, function()
		if s.level >= Tuning.Plot.Levels - 1 then
			flash(viewTip("up"))
		end
		BuildMode.setLevel(s.level + 1)
	end)
	-- a quiet line between the arrows and the switches, so they read as two groups
	local split =
		Kit.box({ Name = "Split", Parent = floorsRow, Size = UDim2.fromOffset(VIEW_SPLIT, TILE_H), LayoutOrder = 3 })
	Kit.frame({
		Name = "Divider",
		Parent = split,
		Size = UDim2.new(0, 1, 1, -16),
		Position = UDim2.new(0.5, 0, 0, 8),
		Color = T.Line,
		Radius = false,
	})
	local VIEW_RUN: { [string]: () -> () } = {
		roofs = function()
			BuildMode.setRoofsHidden(not s.roofsHidden)
		end,
		walls = function()
			BuildMode.setSeeThrough(not s.seeThrough)
		end,
		snap = function()
			s.snap = not s.snap
			BuildMode.notify()
		end,
	}
	for i, v in ipairs(VIEW) do
		viewButtons[v.id] = viewButton(v.name, v.icon, v.id, 3 + i, function()
			VIEW_RUN[v.id]()
			flash(viewWords(v.id))
		end)
	end

	-- coins, top left, and under them how to look around
	local coinPill, coinValue = Kit.pill("coin", {
		Parent = ui,
		Size = UDim2.fromOffset(196, COINS_H),
		Position = UDim2.fromOffset(EDGE + 14, EDGE),
	})
	coinsLabel = coinValue
	State.on("coins", function(n)
		local now = n or 0
		local was = coinsNow
		coinsNow = now
		coinsLabel.Text = Text.commas(now)
		if was ~= now and ui.Visible then
			Kit.bump(coinPill, 0.08)
		end
		for tag, price in priceTags do
			if tag.Parent then
				paintTag(tag, price)
			end
		end
	end)
	-- the Keepsakes tray follows what you were given and how many are down
	State.on("keepsakes", function()
		if trayMode == "catalog:keepsakes" then
			refreshTray()
		end
	end)
	State.onPlan(function()
		if trayMode == "catalog:keepsakes" then
			refreshTray()
		end
	end)
	local tip = Kit.darkPill({
		Name = "CameraTip",
		Size = UDim2.fromOffset(0, TIP_H),
		Position = UDim2.fromOffset(EDGE + 9, EDGE + COINS_H + GAP),
		Parent = ui,
	})
	tip.AutomaticSize = Enum.AutomaticSize.X
	Kit.pad(tip, 8, 0)
	Kit.text(
		if Kit.isTouch() then "One finger turns the view, two move it." else "Right drag turns the view, WASD moves it.",
		{
			Parent = tip,
			Size = UDim2.fromOffset(0, TIP_H),
			AutomaticSize = Enum.AutomaticSize.X,
			TextSize = 14,
			Font = Kit.Fonts.Bold,
			Color = T.White,
			Wrap = false,
		}
	)

	-- the floating action bar over what is picked: its name, what it sells for, and what to do
	actionBar = Kit.frame({
		Name = "Action",
		Size = UDim2.fromOffset(0, 0),
		AutomaticSize = Enum.AutomaticSize.XY,
		AnchorPoint = Vector2.new(0.5, 1),
		Color = T.Paper,
		Radius = 12,
		Parent = ui,
		Visible = false,
	})
	Kit.rim(actionBar, T.Line, 1)
	Kit.softShadow(actionBar, 1)
	Kit.pad(actionBar, SIDE, 10)
	Kit.list(actionBar, 4, false, Enum.HorizontalAlignment.Center)
	actionTitle = Kit.title("", {
		Parent = actionBar,
		Size = UDim2.fromOffset(0, 22),
		AutomaticSize = Enum.AutomaticSize.X,
		TextSize = 18,
		Wrap = false,
		LayoutOrder = 1,
	})
	actionValue = Kit.box({
		Name = "Value",
		Parent = actionBar,
		Size = UDim2.fromOffset(0, 20),
		AutomaticSize = Enum.AutomaticSize.X,
		LayoutOrder = 2,
	})
	Kit.list(actionValue, 4, true)
	actionButtons = Kit.box({
		Parent = actionBar,
		Size = UDim2.fromOffset(0, 62),
		AutomaticSize = Enum.AutomaticSize.X,
		LayoutOrder = 3,
	})
	Kit.list(actionButtons, 2, true).VerticalAlignment = Enum.VerticalAlignment.Bottom

	RunService.RenderStepped:Connect(function()
		if ui.Visible then
			followSelection()
			-- (checked once a frame, so the moment between putting one piece down and picking up the
			-- next never brings the interface back)
			local holding = isHolding()
			if holding ~= holdingNow then
				setHolding(holding)
			end
		end
	end)

	BuildMode.Changed:Connect(function(what)
		if not s.active then
			ui.Visible = false
			actionBar.Visible = false
			hovering = nil
			-- everything back where it belongs for the next visit
			setHolding(false, true)
			return
		end
		if what == "active" then
			ui.Visible = true
			openMain(mainTab)
			BuildMode.setTool("select")
			-- the bars slide in from the edges
			for _, f in ui:GetChildren() do
				if f:IsA("GuiObject") then
					local name = f.Name
					if name == "Dock" then
						Kit.slideIn(f, 0, 140, 0)
					elseif name == "Catalog" then
						Kit.slideIn(f, 0, 320, 0.05)
					elseif name == "Tools" or name == "Hint" then
						Kit.slideIn(f, -260, 0, 0.1)
					elseif name == "Floors" then
						Kit.slideIn(f, 260, 0, 0.12)
					elseif name == "Pill" or name == "CameraTip" then
						Kit.slideIn(f, 0, -120, 0.12)
					end
				end
			end
		end
		if what == "tool" then
			hovering = nil
		end
		if what == "level" and s.level ~= shownLevel then
			shownLevel = s.level
			flash(Text.fill("Floor {n}", { n = s.level + 1 }))
		end
		refreshChrome()
		if what == "tool" then
			if s.tool == "preset" then
				if trayMode ~= "buildings" then
					refreshTray()
				end
			elseif s.tool == "place" and s.placing then
				-- keep showing the catalog the item came from
				if trayMode:sub(1, 8) ~= "catalog:" then
					refreshTray()
				end
			elseif s.tool == "wall" or s.tool == "floor" or s.tool == "roof" then
				if trayMode ~= subTab then
					refreshTray()
				end
			else
				refreshTray()
			end
			refreshActionBar()
		elseif what == "selected" or what == "plan" then
			if s.tool == "select" and (what == "selected" or os.clock() > holdTray) then
				refreshTray()
			end
			refreshActionBar()
		elseif what == "paint" then
			refreshTray()
		end
	end)
end

return BuildUI
