-- Build mode's interface, laid out the way house builders usually are: the main groups and Done
-- along the bottom, the categories and the item tray above them from one edge of the screen to the
-- other, the tools on top of the tray at the left, the floor switcher with the view toggles on top
-- of it at the right, coins top left, and a little action bar over whatever you pick.

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
		},
	},
	{
		id = "work",
		icon = "store",
		name = "Work",
		subs = { { id = "work", icon = "store", name = "Workplaces" } },
	},
}

local WALL_STYLES = { "wall", "half", "glass" }
local FENCE_STYLES = { "fence", "railing", "hedge", "stone" }
local STYLE_ICONS = {
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
-- from the next bar, the same room inside and the same cut corners, and the tiles in the tool row
-- and the category row are the same height.
local EDGE = 12 -- from the screen's edges
local GAP = 8 -- between bars, and between things side by side
local PAD = 8 -- inside a bar, above and below
local SIDE = 12 -- inside a bar, left and right (clear of its cut corners)
local CUT = 12
local DOCK_H, SUBS_H, TRAY_H, TOOLS_H = 60, 80, 176, 80
local TILE_H = SUBS_H - PAD * 2 -- a category or a tool
local TOOL_W = 64
local FLOORS_W, FLOORS_H = 248, 194
local LABEL_W = 124 -- the name at the left of a labelled row in the tray
local INNER_H = TRAY_H - PAD * 2 -- what the tray holds
-- the bars' bottoms, measured up from the bottom of the screen
local SUBS_AT = EDGE + DOCK_H + GAP
local TRAY_AT = SUBS_AT + SUBS_H + GAP
local TOOLS_AT = TRAY_AT + TRAY_H + GAP
local HINT_AT = TOOLS_AT + TOOLS_H + GAP
-- the coins and the camera tip, top left
local COINS_H, TIP_H = 46, 28
local TOP_LEFT_W, TOP_LEFT_H = 380, EDGE + COINS_H + GAP + TIP_H

-- the cards in the tray
local CARD_W, CARD_H, CARD_CUT = 120, 152, 8
local PIC_H = 80
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
local tray: Frame
local trayBody: Frame
local subBar: ScrollingFrame
local mainButtons: { [string]: TextButton } = {}
local subButtons: { [string]: TextButton } = {}
local toolButtons: { [string]: TextButton } = {}
local hintPill: Frame
local hintLabel: TextLabel
local levelLabel: TextLabel
local levelDown: TextButton
local levelUp: TextButton
local coinsLabel: TextLabel
local actionBar: Frame
local actionTitle: TextLabel
local actionValue: Frame
local actionButtons: Frame
local viewRows: { [string]: GuiObject } = {}
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

-- The price on a card: a leaning green tag with the coin and the number, coral while the card
-- costs more than you have.
local function paintTag(tag: Frame, price: number)
	local short = price > coinsNow
	local color = if short then T.Coral else T.Green
	Kit.paint(tag, color)
	local label = tag:FindFirstChild("Amount", true)
	if label and label:IsA("TextLabel") then
		Kit.outlineText(label, Kit.darker(color, 0.42), 1.5)
	end
end

local function priceTag(parent: Instance, price: number, y: number): Frame
	local tag = Kit.frame({
		Name = "Price",
		Parent = parent,
		Size = UDim2.fromOffset(0, 24),
		AutomaticSize = Enum.AutomaticSize.X,
		Position = UDim2.new(0.5, 0, 0, y),
		AnchorPoint = Vector2.new(0.5, 0),
		Color = T.Green,
		Radius = false,
	})
	Kit.slant(tag, 24, true)
	Kit.shade(tag)
	Kit.pad(tag, 2, 0)
	local row = Kit.box({ Parent = tag, Size = UDim2.fromOffset(0, 24), AutomaticSize = Enum.AutomaticSize.X })
	Kit.list(row, 4, true)
	Icons.make("coin", 18, { Parent = row, LayoutOrder = 1 })
	Kit.title(Text.commas(price), {
		Name = "Amount",
		Parent = row,
		Size = UDim2.fromOffset(0, 24),
		AutomaticSize = Enum.AutomaticSize.X,
		TextSize = 17,
		Color = T.White,
		Wrap = false,
		LayoutOrder = 2,
		Outline = Kit.darker(T.Green, 0.42),
	})
	priceTags[tag] = price
	paintTag(tag, price)
	return tag
end

-- A small dark diamond with a yellow tick, on the corner of what is picked.
local function pickedMark(parent: Instance, x: number, y: number)
	local mark = Kit.frame({
		Name = "Picked",
		Parent = parent,
		Size = UDim2.fromOffset(14, 14),
		Position = UDim2.fromOffset(x, y),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Color = T.Dark,
		Radius = false,
		ZIndex = 3,
	})
	mark.Rotation = 45
	Icons.make("check", 12, {
		Parent = parent,
		Position = UDim2.fromOffset(x - 6, y - 6),
		Color = T.Yellow,
		Hole = T.Dark,
		ZIndex = 4,
	})
end

-- What a card does under the mouse: it lifts a little and sinks when pressed. With `rest` (the
-- colour it has when the mouse is away) its colour cools toward blue as well.
local function hoverable(card: GuiButton, rest: (() -> Color3)?): UIScale
	local scale = Kit.new("UIScale", { Parent = card })
	local over = false
	card.MouseEnter:Connect(function()
		over = true
		if rest then
			Kit.paintCut(card, Kit.mix(rest(), T.Blue, 0.22))
		end
		TweenService:Create(scale, TweenInfo.new(0.15, Enum.EasingStyle.Back), { Scale = 1.05 }):Play()
	end)
	card.MouseLeave:Connect(function()
		over = false
		if rest then
			Kit.paintCut(card, rest())
		end
		TweenService:Create(scale, TweenInfo.new(0.15), { Scale = 1 }):Play()
	end)
	card.MouseButton1Down:Connect(function()
		TweenService:Create(scale, TweenInfo.new(0.06), { Scale = 0.96 }):Play()
	end)
	card.MouseButton1Up:Connect(function()
		TweenService:Create(scale, TweenInfo.new(0.2, Enum.EasingStyle.Back), { Scale = if over then 1.05 else 1 })
			:Play()
	end)
	return scale
end

-- A card in the tray: a dark slab with two corners cut, a picture at the top, the name and the
-- price under it. Returns the card and the picture's frame.
local function card(parent: Instance, name: string, order: number, width: number, onPick: () -> ()): (TextButton, Frame)
	local b = Kit.new("TextButton", {
		Name = name,
		Text = "",
		AutoButtonColor = false,
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(width, CARD_H),
		LayoutOrder = order,
		Parent = parent,
	})
	Kit.cutInto(b, T.Card, CARD_CUT)
	local pic = Kit.frame({
		Name = "Picture",
		Parent = b,
		Size = UDim2.new(1, -12, 0, PIC_H),
		Position = UDim2.fromOffset(6, 6),
		Color = T.Picture,
		Radius = false,
	})
	local scale = hoverable(b, function()
		return T.Card
	end)
	b.Activated:Connect(onPick)
	-- cards pop into the tray one after another
	scale.Scale = 0.4
	TweenService:Create(
		scale,
		TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out, 0, false, math.min(order, 14) * 0.025),
		{ Scale = 1 }
	):Play()
	return b, pic
end

-- A catalog item's card: its 3D picture, its name (on two lines if it needs them) and its price.
local function itemTile(parent: Instance, def: any, order: number, onPick: () -> ()): TextButton
	local b, pic = card(parent, def.id, order, CARD_W, onPick)
	b:SetAttribute("ItemId", def.id)
	task.spawn(function()
		ModelPreview.fromPrims(Catalog.prims(def), { Parent = pic })
	end)
	Kit.title(def.name, {
		Name = "Name",
		Parent = b,
		Size = UDim2.new(1, -12, 0, 32),
		Position = UDim2.fromOffset(6, PIC_H + 8),
		TextSize = 14,
		AlignX = Enum.TextXAlignment.Center,
	})
	priceTag(b, def.price, CARD_H - 30)
	return b
end

-- A finish (a colour and a material) to build or paint with. Small, it is a swatch with the name
-- under it; big (opts.h over 60), the swatch carries the material's name and a line goes under the
-- name (opts.sub, with a coin when opts.coin). The picked one is yellow with a tick.
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
	local function rest(): Color3
		return if picked then T.Yellow else T.Card
	end
	Kit.cutInto(b, rest(), if big then CARD_CUT else 6)
	local swH = if big then h - (if opts.sub then 50 else 32) else h - 24
	local color = Colors.fromHex(preset.c)
	local sw = Kit.frame({
		Name = "Swatch",
		Parent = b,
		Size = UDim2.new(1, -8, 0, swH),
		Position = UDim2.fromOffset(4, 4),
		Color = color,
		Radius = false,
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
	Kit.title(preset.name, {
		Name = "Name",
		Parent = b,
		Size = UDim2.new(1, -8, 0, if big then 18 else 16),
		Position = UDim2.fromOffset(4, swH + (if big then 8 else 5)),
		TextSize = if big then 14 else 12,
		Color = ink,
		AlignX = Enum.TextXAlignment.Center,
		Wrap = false,
	}).TextTruncate =
		Enum.TextTruncate.AtEnd
	if opts.sub then
		local soft = if picked then T.Dark else T.InkSoft
		if opts.coin then
			coinLine(b, opts.sub, { Position = UDim2.new(0, 0, 1, -22), Color = soft })
		else
			Kit.text(opts.sub, {
				Parent = b,
				Size = UDim2.new(1, -8, 0, 16),
				Position = UDim2.new(0, 4, 1, -22),
				TextSize = 12,
				Font = Kit.Fonts.Bold,
				Color = soft,
				AlignX = Enum.TextXAlignment.Center,
				Wrap = false,
			})
		end
	end
	if picked then
		pickedMark(b, w - 10, 10)
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
	local function rest(): Color3
		return if picked then T.Yellow else T.Card
	end
	Kit.cutInto(b, rest(), CARD_CUT)
	local ink = if picked then T.Dark else T.Ink
	local top = if sub then 8 else 14
	Icons.make(icon, 40, {
		Name = "IconArt",
		Parent = b,
		Position = UDim2.new(0.5, -20, 0, top),
		Color = ink,
		Hole = rest(),
	})
	Kit.title(label, {
		Name = "Name",
		Parent = b,
		Size = UDim2.new(1, -8, 0, 18),
		Position = UDim2.fromOffset(4, top + 46),
		TextSize = 14,
		Color = ink,
		AlignX = Enum.TextXAlignment.Center,
		Wrap = false,
	})
	if sub then
		coinLine(b, sub, { Position = UDim2.fromOffset(0, top + 66), Color = if picked then T.Dark else T.InkSoft })
	end
	if picked then
		pickedMark(b, STYLE_W - 12, 12)
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
			Kit.frame({ Name = "Ring", Parent = cell, Size = UDim2.fromScale(1, 1), Color = T.Yellow, Radius = false })
		end
		local b = Kit.swatch(Colors.fromHex(hex), SWATCH, function()
			onPick(hex)
		end, { Parent = cell })
		b.Position = UDim2.fromOffset(RING, RING)
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
	Kit.frame({
		Name = "Swatch",
		Parent = box,
		Size = UDim2.fromOffset(22, 22),
		Color = Colors.fromHex(c),
		Radius = false,
		LayoutOrder = 2,
	})
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
	-- a diamond with the icon upright on it, at the left
	local d = 44
	local badge = Kit.frame({
		Name = "Marker",
		Parent = box,
		Size = UDim2.fromOffset(d, d),
		Position = UDim2.fromOffset(10, 6),
		Color = color,
		Radius = false,
	})
	badge.Rotation = 45
	Icons.make(icon, 30, {
		Name = "IconArt",
		Parent = box,
		Position = UDim2.fromOffset(10 + (d - 30) / 2, 6 + (d - 30) / 2),
		Color = T.Dark,
		Hole = color,
		ZIndex = 2,
	})
	local words = Kit.box({
		Parent = box,
		Size = UDim2.new(1, -84, 0, 0),
		Position = UDim2.fromOffset(84, 0),
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
		local b, pic = card(row, preset.id, i, 150, function()
			BuildMode.startPreset(preset.id)
		end)
		b:SetAttribute("PresetId", preset.id)
		task.spawn(function()
			ModelPreview.fromPrims(presetLook(preset.id), { Parent = pic })
		end)
		Kit.title(preset.name, {
			Name = "Name",
			Parent = b,
			Size = UDim2.new(1, -12, 0, 32),
			Position = UDim2.fromOffset(6, PIC_H + 8),
			TextSize = 15,
			AlignX = Enum.TextXAlignment.Center,
		})
		if not presetPrices[preset.id] then
			presetPrices[preset.id] = Presets.price(preset.id)
		end
		priceTag(b, presetPrices[preset.id], CARD_H - 30)
		-- its size, in a dark chip on the picture's corner
		local size = Kit.frame({
			Name = "Size",
			Parent = pic,
			Size = UDim2.fromOffset(0, 18),
			AutomaticSize = Enum.AutomaticSize.X,
			Position = UDim2.new(1, -4, 0, 4),
			AnchorPoint = Vector2.new(1, 0),
			Color = T.Paper,
			Radius = false,
		})
		Kit.pad(size, 6, 0)
		Kit.text(Text.fill("{w} x {d}", { w = preset.w, d = preset.d }), {
			Parent = size,
			Size = UDim2.fromOffset(0, 18),
			AutomaticSize = Enum.AutomaticSize.X,
			TextSize = 12,
			Font = Kit.Fonts.Bold,
			Color = T.InkSoft,
			Wrap = false,
		})
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

local function catalogTray(cat: string)
	local row = trayRow()
	local list = Catalog.list(cat)
	if cat == "paths" then
		list = {}
		for _, def in Catalog.list("garden") do
			if def.id:find("path") or def.id:find("stone") then
				table.insert(list, def)
			end
		end
	end
	for i, def in list do
		itemTile(row, def, i, function()
			BuildMode.startPlacing(def.id)
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
	if Plan.WallStyles[s.wallStyle].fence then
		local note = Kit.box({ Parent = row, Size = UDim2.new(1, -taken, 0, STYLE_H), LayoutOrder = 20 })
		trayNote(note, "brush", T.Yellow, "Fences come in their own colours", {
			"Paint one with the Paint tool once it is up.",
		}).Position =
			UDim2.fromOffset(0, 18)
		return
	end
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
	local row = trayRow(112, stack, 1)
	for i, preset in Palette.Presets.floors do
		finishTile(row, preset, i, {
			w = 108,
			h = 108,
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
			"A wall, a floor, a roof or a piece of furniture. R turns what you hold, Ctrl+Z undoes.",
		}, 1)
		return
	end
	if kind == "items" then
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
		local row = Kit.box({ Parent = stack, Size = UDim2.new(1, 0, 0, STYLE_H), LayoutOrder = 1 })
		Kit.list(row, GAP, true).VerticalAlignment = Enum.VerticalAlignment.Top
		for i, id in Plan.WallStyleOrder do
			styleTile(row, Plan.WallStyles[id].name, STYLE_ICONS[id], i, obj.style == id, nil, function()
				BuildMode.editSelected({ style = id })
			end)
		end
		local taken = #Plan.WallStyleOrder * (STYLE_W + GAP) + GAP
		local note = Kit.box({ Parent = row, Size = UDim2.new(1, -taken, 0, STYLE_H), LayoutOrder = 20 })
		trayNote(note, "brush", T.Yellow, "Each side has its own paint", {
			"Use the Paint tool to colour the inside and the outside.",
		}).Position =
			UDim2.fromOffset(0, 18)
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
		"You get back what you paid for it. The starting house was a gift, so its pieces sell for nothing.",
		"Sold the wrong thing? Undo puts it back.",
	}, 1)
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
	subTab = id
	for sid, b in subButtons do
		Kit.setButtonColor(b, if sid == id then T.Yellow else T.Paper, if sid == id then T.Dark else T.Ink)
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
	mainTab = id
	for mid, b in mainButtons do
		Kit.setButtonColor(b, if mid == id then T.Yellow else T.Paper, if mid == id then T.Dark else T.Ink)
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

-- What the tool in hand does, in a line short enough to sit over the tools.
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

local VIEW = {
	{ id = "roofs", icon = "roof", name = "Hide roofs" },
	{ id = "walls", icon = "wall", name = "See-through walls" },
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

-- A view toggle shows its state at a glance: yellow with "On" while it is on.
local function paintToggle(id: string)
	local row = viewRows[id]
	if not row then
		return
	end
	local on = viewOn(id)
	Kit.setRowSelected(row, on)
	local art = row:FindFirstChild("IconArt", true)
	if art then
		Kit.recolorIcon(art, if on then T.Dark else T.Ink, if on then T.Yellow else T.PaperDark)
	end
	local chip = row:FindFirstChild("State", true)
	if chip and chip:IsA("Frame") then
		Kit.paint(chip, if on then T.Dark else T.Card)
		local word = chip:FindFirstChild("Word")
		if word and word:IsA("TextLabel") then
			word.Text = if on then "On" else "Off"
			word.TextColor3 = if on then T.Yellow else T.InkSoft
		end
	end
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
	levelLabel.Text = "Floor " .. (s.level + 1)
	local top = Tuning.Plot.Levels - 1
	Kit.setButtonColor(levelDown, if s.level > 0 then T.Blue else T.Card, if s.level > 0 then T.White else T.InkSoft)
	Kit.setButtonColor(levelUp, if s.level < top then T.Blue else T.Card, if s.level < top then T.White else T.InkSoft)
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
	if hovering and (s.tool == "place" or s.tool == "preset") then
		hint = hovering
	end
	hintLabel.Text = hint
	for _, v in VIEW do
		paintToggle(v.id)
	end
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
		Kit.text(if gift then "A gift: sells for nothing" else "Sells for nothing", {
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
	-- the popup says what to do now, so the hint over the tools steps aside
	hintPill.Visible = false
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
	local lowest = H - (TRAY_AT + TRAY_H) - GAP
	if left < EDGE + #TOOLS * TOOL_W + SIDE * 2 then
		lowest = math.min(lowest, H - (TOOLS_AT + TOOLS_H) - GAP)
	end
	if right > W - EDGE - FLOORS_W then
		lowest = math.min(lowest, H - (TOOLS_AT + FLOORS_H) - GAP)
	end
	bottom = math.min(bottom, lowest)
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
	-- the whole screen horizontally, and the right side should be moved up". So the tray and the
	-- categories run from one edge of the screen to the other (their widths are a share of the
	-- screen, never a count of pixels), the floors card sits on top of the tray at the right, and
	-- Done shares the bottom row with the main groups.

	-- the main groups, along the bottom
	local dockButtonW = 148
	local dock = Kit.frame({
		Name = "Dock",
		Size = UDim2.fromOffset(#MAIN * dockButtonW + (#MAIN - 1) * GAP + SIDE * 2, DOCK_H),
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

	-- the way out: one big button in the bottom right corner, as tall as the main groups' bar
	-- beside it so it stays clear of the categories above
	Kit.button("Done", {
		Parent = ui,
		Name = "Done",
		Size = UDim2.fromOffset(196, DOCK_H),
		Position = UDim2.new(1, -EDGE, 1, -EDGE),
		AnchorPoint = Vector2.new(1, 1),
		TextSize = 26,
		Color = T.Coral,
		Icon = "close",
	}, function()
		if onExit then
			onExit()
		end
	end)

	-- the categories just above, as icon tiles, scrolling sideways when there are many
	local subHolder = Kit.frame({
		Name = "SubsBar",
		Size = UDim2.new(1, -EDGE * 2, 0, SUBS_H),
		Position = UDim2.new(0, EDGE, 1, -SUBS_AT),
		AnchorPoint = Vector2.new(0, 1),
		Color = T.Paper,
		Cut = CUT,
		Parent = ui,
	})
	subBar = Kit.scroll({
		Name = "Subs",
		Parent = subHolder,
		Size = UDim2.new(1, -SIDE * 2, 1, -PAD * 2),
		Position = UDim2.fromOffset(SIDE, PAD),
		Axis = Enum.AutomaticSize.X,
	})
	subBar.ScrollBarThickness = 0
	Kit.list(subBar, 0, true)

	-- the tray of things to place and options, as wide as the screen: its rows scroll sideways
	tray = Kit.frame({
		Name = "Tray",
		Size = UDim2.new(1, -EDGE * 2, 0, TRAY_H),
		Position = UDim2.new(0, EDGE, 1, -TRAY_AT),
		AnchorPoint = Vector2.new(0, 1),
		Color = T.Paper,
		Cut = CUT,
		Parent = ui,
	})
	-- a little of the tray's own blue glowing in from its top right, for depth
	Kit.glow(tray, T.Blue, 0.16)
	trayBody = Kit.box({
		Parent = tray,
		Size = UDim2.new(1, -SIDE * 2, 1, -PAD * 2),
		Position = UDim2.fromOffset(SIDE, PAD),
		ZIndex = 2,
	})

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

	-- the floors and the view switches, at the right on top of the tray (level with the tools)
	local floors = Kit.frame({
		Name = "Floors",
		Size = UDim2.fromOffset(FLOORS_W, FLOORS_H),
		Position = UDim2.new(1, -EDGE, 1, -TOOLS_AT),
		AnchorPoint = Vector2.new(1, 1),
		Color = T.Paper,
		Cut = CUT,
		Parent = ui,
	})
	local floorsBody = Kit.box({
		Parent = floors,
		Size = UDim2.new(1, -SIDE * 2, 1, -SIDE * 2),
		Position = UDim2.fromOffset(SIDE, SIDE),
	})
	Kit.list(floorsBody, 6, false, Enum.HorizontalAlignment.Center)
	local levelRow = Kit.box({ Parent = floorsBody, Size = UDim2.new(1, 0, 0, 44), LayoutOrder = 1 })
	levelDown = Kit.button("", {
		Name = "FloorDown",
		Parent = levelRow,
		Size = UDim2.fromOffset(52, 44),
		TextSize = 22,
		Color = T.Blue,
		Icon = "down",
	}, function()
		BuildMode.setLevel(s.level - 1)
	end)
	levelLabel = Kit.title("Floor 1", {
		Parent = levelRow,
		Size = UDim2.new(1, -108, 1, 0),
		Position = UDim2.fromOffset(54, 0),
		TextSize = 21,
		Color = T.Ink,
		AlignX = Enum.TextXAlignment.Center,
	})
	levelUp = Kit.button("", {
		Name = "FloorUp",
		Parent = levelRow,
		Size = UDim2.fromOffset(52, 44),
		Position = UDim2.new(1, -52, 0, 0),
		TextSize = 22,
		Color = T.Blue,
		Icon = "up",
	}, function()
		BuildMode.setLevel(s.level + 1)
	end)
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
		local row, inner = Kit.row({
			Name = v.name,
			Parent = floorsBody,
			Height = 36,
			Title = v.name,
			TextSize = 14,
			LayoutOrder = 1 + i,
			LeftSpace = 32,
			RightSpace = 42,
		}, VIEW_RUN[v.id])
		local lean = row:GetAttribute("Lean") or 0
		Icons.make(v.icon, 18, {
			Name = "IconArt",
			Parent = inner,
			Position = UDim2.new(0, lean + 8, 0.5, -9),
			Color = T.Ink,
			Hole = T.PaperDark,
			ZIndex = 3,
		})
		local chip = Kit.frame({
			Name = "State",
			Parent = inner,
			Size = UDim2.fromOffset(32, 20),
			Position = UDim2.new(1, -(lean + 38), 0.5, -10),
			Color = T.Card,
			Radius = false,
			ZIndex = 3,
		})
		Kit.text("Off", {
			Name = "Word",
			Parent = chip,
			Size = UDim2.fromScale(1, 1),
			TextSize = 13,
			Font = Kit.Fonts.Bold,
			Color = T.InkSoft,
			AlignX = Enum.TextXAlignment.Center,
			ZIndex = 4,
		})
		viewRows[v.id] = row
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
		Radius = false,
		Parent = ui,
		Visible = false,
	})
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
		end
	end)

	BuildMode.Changed:Connect(function(what)
		if not s.active then
			ui.Visible = false
			actionBar.Visible = false
			hovering = nil
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
					elseif name == "SubsBar" then
						Kit.slideIn(f, 0, 160, 0.04)
					elseif name == "Tray" then
						Kit.slideIn(f, 0, 260, 0.08)
					elseif name == "Tools" or name == "Hint" then
						Kit.slideIn(f, -260, 0, 0.1)
					elseif name == "Floors" or name == "Done" then
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
