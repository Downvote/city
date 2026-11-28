-- Pieces the full menus share (City hall, Town goals, the town news and the villagers), so they
-- read as one set: the card on the left that shows the picked thing, the
-- list down the right, a dim caption over a group of rows, stat tiles for the numbers that
-- matter, a round dial, what a list says when it is empty, a dim slot for something not there
-- yet, hint strips and soft one line notes. Built from UI/Kit in the menus' look (charcoal
-- rounded cards in a thin rim, pills, round markers), coloured only from Kit.Theme, so both
-- looks work and a switch repaints them.

local Kit = require(script.Parent.Kit)
local Icons = require(script.Parent.Icons)

local MenuParts = {}

local T = Kit.Theme

-- The rhythm every menu keeps inside its panel.
MenuParts.Split = 0.46 -- the left card's share of the panel's body
MenuParts.Gap = 20 -- between the card and the list
MenuParts.Pad = 24 -- inside the card, on every side
MenuParts.Row = 58 -- a row in a list
MenuParts.RowGap = 8 -- between rows

-- The card on the left of a menu, showing the picked thing: a rounded card in a thin rim, a soft
-- glow of the menu's colour from its top right, and a padded box inside to fill. Returns the card
-- and that box: clear and fill the box, never the card (the card's own shape is a child of it).
-- props: Name, Size, Position, Pad, Caption (a dim word or two at its top left, over the box).
function MenuParts.card(parent: Instance, accent: Color3, props: { [string]: any }?): (Frame, Frame)
	local p = props or {}
	local card = Kit.frame({
		Name = p.Name or "Detail",
		Parent = parent,
		Size = p.Size or UDim2.new(MenuParts.Split, -MenuParts.Gap / 2, 1, 0),
		Position = p.Position or UDim2.new(),
		Color = T.Paper,
		Cut = 16,
	})
	Kit.glow(card, accent, 0.22, "tr")
	-- brackets on two of its corners, just inside its edge
	Kit.brackets(card, { Corners = { "tl", "br" }, Arm = 12, Inset = 7, Color = T.Line, ZIndex = 1 })
	local pad = p.Pad or MenuParts.Pad
	if p.Caption then
		Kit.caption(p.Caption, {
			Name = "Caption",
			Parent = card,
			Size = UDim2.new(1, -pad * 2, 0, 16),
			Position = UDim2.fromOffset(pad, 8),
			TextSize = 11,
		})
	end
	Kit.mark(card)
	local inside = Kit.box({
		Name = "Inside",
		Parent = card,
		Size = UDim2.new(1, -pad * 2, 1, -pad * 2),
		Position = UDim2.fromOffset(pad, pad),
	})
	inside.ZIndex = 2
	return card, inside
end

-- The list down the right of a menu, beside the card. Returns the scrolling frame (rows go in it
-- at full width less 12 for the scroll bar: MenuParts.rowSize()).
function MenuParts.list(parent: Instance, props: { [string]: any }?): ScrollingFrame
	local p = props or {}
	local split = p.Split or MenuParts.Split
	local scroll = Kit.scroll({
		Name = p.Name or "List",
		Parent = parent,
		Size = p.Size or UDim2.new(1 - split, -MenuParts.Gap / 2, 1, 0),
		Position = p.Position or UDim2.new(split, MenuParts.Gap / 2, 0, 0),
	})
	Kit.list(scroll, MenuParts.RowGap)
	return scroll
end

function MenuParts.rowSize(height: number?): UDim2
	return UDim2.new(1, -12, 0, height or MenuParts.Row)
end

-- A caption over a group of rows: its number in the group's colour, the words set wide in
-- capitals, a count or a note at the right end, and under them a hairline that ends in a dot.
-- The groups in one list are numbered 01, 02 and on in the order they are made.
function MenuParts.heading(parent: Instance, text: string, accent: Color3, order: number, right: string?): Frame
	local n = 1
	for _, c in parent:GetChildren() do
		if c.Name == "Heading" then
			n += 1
		end
	end
	local h = Kit.box({ Name = "Heading", Parent = parent, Size = UDim2.new(1, -12, 0, 28), LayoutOrder = order })
	Kit.title(Kit.index(n), {
		Name = "Index",
		Parent = h,
		Size = UDim2.fromOffset(24, 16),
		Position = UDim2.fromOffset(6, 3),
		TextSize = 14,
		Tint = accent,
		Wrap = false,
	})
	Kit.caption(text, {
		Name = "Title",
		Parent = h,
		Size = UDim2.new(1, -(if right then 96 else 40), 0, 16),
		Position = UDim2.fromOffset(32, 3),
		TextSize = 11,
	})
	if right then
		Kit.text(right, {
			Name = "Count",
			Parent = h,
			Size = UDim2.new(0, 60, 0, 16),
			Position = UDim2.new(1, -6, 0, 3),
			AnchorPoint = Vector2.new(1, 0),
			TextSize = 14,
			Font = Kit.Fonts.Title,
			Color = T.InkSoft,
			AlignX = Enum.TextXAlignment.Right,
			Wrap = false,
		})
	end
	Kit.rule({
		Name = "Rule",
		Parent = h,
		Size = UDim2.new(1, -6, 0, 6),
		Position = UDim2.fromOffset(6, 23),
		AnchorPoint = Vector2.new(0, 0.5),
		Color = T.Line,
		Transparency = 0.35,
	})
	Kit.mark(h)
	return h
end

-- A stat tile: a sunk rounded well with a round mark and a small label at the top and the number
-- big under them. props: Parent, Size, Position, LayoutOrder, Sub (a soft word after the number),
-- Tint (the number in an accent), TextSize, Coin (the number is coins: the coin goes in front of
-- it), Bar (a share from 0 to 1: a thin bar in the tile's colour along its foot). Returns the
-- tile and the number's label.
function MenuParts.stat(
	icon: string,
	label: string,
	value: string,
	color: Color3,
	props: { [string]: any }?
): (Frame, TextLabel)
	local p = props or {}
	local tile = Kit.frame({
		Name = p.Name or "Stat",
		Parent = p.Parent,
		Size = p.Size or UDim2.fromOffset(120, 78),
		Position = p.Position or UDim2.new(),
		LayoutOrder = p.LayoutOrder or 0,
		Color = T.PaperDark,
		Cut = 12,
	})
	Kit.disc({ Name = "Mark", Parent = tile, Size = 24, Position = UDim2.fromOffset(10, 9), Color = color, Icon = icon })
	Kit.caption(label, {
		Name = "Label",
		Parent = tile,
		Size = UDim2.new(1, -52, 0, 16),
		Position = UDim2.fromOffset(42, 13),
		TextSize = 11,
	})
	-- a bracket in its colour on the top right corner
	Kit.brackets(tile, { Corners = { "tr" }, Arm = 8, Inset = 6, Color = color, Transparency = 0.25, ZIndex = 2 })
		:SetAttribute("KeepColors", true)
	Kit.mark(tile)
	local row = Kit.box({
		Name = "Value",
		Parent = tile,
		Size = UDim2.new(1, -24, 0, 32),
		Position = UDim2.fromOffset(12, 38),
	})
	Kit.list(row, 6, true)
	if p.Coin then
		Icons.make("coin", 22, { Name = "Coin", Parent = row, LayoutOrder = 0 })
	end
	local number = Kit.title(value, {
		Name = "Number",
		Parent = row,
		Size = UDim2.fromOffset(0, 32),
		AutomaticSize = Enum.AutomaticSize.X,
		TextSize = p.TextSize or 26,
		Tint = p.Tint,
		Wrap = false,
		LayoutOrder = 1,
	})
	if p.Sub then
		Kit.text(p.Sub, {
			Name = "Sub",
			Parent = row,
			Size = UDim2.fromOffset(0, 26),
			AutomaticSize = Enum.AutomaticSize.X,
			TextSize = 14,
			Color = T.InkSoft,
			Wrap = false,
			LayoutOrder = 2,
		})
	end
	if p.Bar then
		Kit.bar({
			Parent = tile,
			Size = UDim2.new(1, -24, 0, 6),
			Position = UDim2.new(0, 12, 1, -16),
			Track = T.Card,
		}, p.Bar, color)
	end
	return tile, number
end

-- A round dial: a dark disc in a thick ring of the colour with a thin line inside the ring, a
-- small word over a big number (a town's level). props: Parent, Size, Position, AnchorPoint,
-- Name. Returns the dial and the number.
function MenuParts.dial(value: string, label: string, color: Color3, props: { [string]: any }?): (Frame, TextLabel)
	local p = props or {}
	local px: number = p.Size or 72
	local dial = Kit.new("Frame", {
		Name = p.Name or "Dial",
		BackgroundColor3 = T.PaperDark,
		BorderSizePixel = 0,
		Size = UDim2.fromOffset(px, px),
		Position = p.Position or UDim2.new(),
		AnchorPoint = p.AnchorPoint or Vector2.zero,
		Parent = p.Parent,
	})
	Kit.corner(dial, "round")
	Kit.rim(dial, color, 4)
	local inner = Kit.new("Frame", {
		Name = "Inner",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -10, 1, -10),
		Position = UDim2.fromOffset(5, 5),
		Parent = dial,
	})
	Kit.corner(inner, "round")
	Kit.rim(inner, T.Line, 1, 0.3)
	Kit.ticks(inner, 24, { Major = 6, Length = 3, Inset = 3, Color = T.Line, Transparency = 0.2 })
	Kit.text(label, {
		Name = "Label",
		Parent = dial,
		Size = UDim2.new(1, 0, 0, 14),
		Position = UDim2.fromScale(0, 0.2),
		TextSize = math.floor(px * 0.15),
		Font = Kit.Fonts.Title,
		Color = T.InkSoft,
		AlignX = Enum.TextXAlignment.Center,
		Wrap = false,
	})
	local number = Kit.title(value, {
		Name = "Value",
		Parent = dial,
		Size = UDim2.new(1, 0, 0, math.floor(px * 0.46)),
		Position = UDim2.fromScale(0, 0.36),
		TextSize = math.floor(px * 0.42),
		AlignX = Enum.TextXAlignment.Center,
		Wrap = false,
	})
	return dial, number
end

-- What a list says when there is nothing in it: a big round mark with the icon in a faint ring, a
-- title and a line on what to do. props: Parent, Size, Position, AnchorPoint, LayoutOrder, Color
-- (the mark's), Height (the box's, its content in the middle: a whole empty list's height
-- centres it).
function MenuParts.empty(icon: string, title: string, hint: string, props: { [string]: any }?): Frame
	local p = props or {}
	local h: number = p.Height or 190
	local top = math.max(12, math.floor((h - 166) / 2))
	local box = Kit.box({
		Name = p.Name or "Empty",
		Parent = p.Parent,
		Size = p.Size or UDim2.new(1, -12, 0, h),
		Position = p.Position,
		AnchorPoint = p.AnchorPoint,
		LayoutOrder = p.LayoutOrder,
	})
	-- a faint ring round the mark, the way an empty slot is drawn
	local ring = Kit.new("Frame", {
		Name = "Ring",
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(76, 76),
		Position = UDim2.new(0.5, 0, 0, top - 6),
		AnchorPoint = Vector2.new(0.5, 0),
		Parent = box,
	})
	Kit.corner(ring, "round")
	Kit.rim(ring, T.Line, 1.5, 0.35)
	Kit.disc({
		Name = "Mark",
		Parent = box,
		Size = 60,
		Position = UDim2.new(0.5, 0, 0, top + 2),
		AnchorPoint = Vector2.new(0.5, 0),
		Color = p.Color or T.Line,
		Icon = icon,
	})
	Kit.title(title, {
		Name = "Title",
		Parent = box,
		Size = UDim2.new(1, -48, 0, 28),
		Position = UDim2.fromOffset(24, top + 80),
		TextSize = 22,
		AlignX = Enum.TextXAlignment.Center,
	})
	Kit.text(hint, {
		Name = "Hint",
		Parent = box,
		Size = UDim2.new(1, -72, 0, 44),
		Position = UDim2.fromOffset(36, top + 112),
		TextSize = 16,
		Color = T.InkSoft,
		AlignX = Enum.TextXAlignment.Center,
		AlignY = Enum.TextYAlignment.Top,
	})
	Kit.mark(box)
	return box
end

-- A dim slot in a list for something that isn't there yet: a sunk pill with a faint round mark
-- and dim words. With onClick it is a button (a slot that opens the way to fill it). props:
-- Parent, LayoutOrder, Height, Name, Icon (on the mark; a cross by default), Sub.
function MenuParts.slot(text: string, props: { [string]: any }?, onClick: (() -> ())?): GuiObject
	local p = props or {}
	local h: number = p.Height or MenuParts.Row
	local row, inner = Kit.row({
		Name = p.Name or "Slot",
		Parent = p.Parent,
		Size = MenuParts.rowSize(h),
		Height = h,
		LayoutOrder = p.LayoutOrder or 0,
		Title = text,
		Sub = p.Sub,
		Sunk = true,
		LeftSpace = h - 6,
	}, onClick)
	local lean: number = row:GetAttribute("Lean") or 6
	local d = h - 18
	local mark = Kit.new("Frame", {
		Name = "Mark",
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(d, d),
		Position = UDim2.new(0, lean + 4, 0.5, -d / 2),
		ZIndex = 2,
		Parent = inner,
	})
	Kit.corner(mark, "round")
	Kit.rim(mark, T.Line, 1.5, 0.2)
	local ipx = math.floor(d * 0.5)
	Icons.make(p.Icon or "close", ipx, {
		Name = "IconArt",
		Parent = mark,
		Position = UDim2.new(0.5, -ipx / 2, 0.5, -ipx / 2),
		Color = T.Line,
		ZIndex = 3,
	})
	return row
end

-- A hint strip in a list or on a card: how something works, in the khaki strip with its round
-- badge (Kit.hint). props: Parent, LayoutOrder, Size, Position, Name.
function MenuParts.hint(text: string, props: { [string]: any }?): Frame
	local p = props or {}
	local strip = Kit.hint(text, {
		Name = p.Name or "Hint",
		Parent = p.Parent,
		Size = p.Size or UDim2.new(1, -12, 0, 0),
		Position = p.Position,
		AnchorPoint = p.AnchorPoint,
		LayoutOrder = p.LayoutOrder,
	})
	Kit.mark(strip)
	return strip
end

-- A soft one line note: a small round dot in the menu's colour and the words. props: Parent,
-- Size, Position, LayoutOrder, Height (for two lines).
function MenuParts.note(text: string, accent: Color3, props: { [string]: any }?): Frame
	local p = props or {}
	local h = p.Height or 24
	local box = Kit.box({
		Name = p.Name or "Note",
		Parent = p.Parent,
		Size = p.Size or UDim2.new(1, -12, 0, h),
		Position = p.Position,
		LayoutOrder = p.LayoutOrder,
	})
	Kit.disc({ Name = "Dot", Parent = box, Size = 8, Position = UDim2.fromOffset(8, 7), Color = accent, Ring = false })
	Kit.text(text, {
		Name = "Text",
		Parent = box,
		Size = UDim2.new(1, -26, 1, 0),
		Position = UDim2.fromOffset(24, 0),
		TextSize = 15,
		Color = T.InkSoft,
		AlignY = Enum.TextYAlignment.Top,
	})
	Kit.mark(box)
	return box
end

-- Claim all: a leaning button in a full menu's header, just left of its tabs (or at its right end
-- with none), that claims everything waiting in the menu at once (the user: "make a claim all
-- button in rewards and in goals"). Green with something waiting, dim and inert with nothing.
-- Made again on each call (the one before goes), so a menu calls it whenever it fills. Returns the
-- button, or nil for a menu with no header.
function MenuParts.claimAll(panel: any, waiting: number, onClick: () -> ()): TextButton?
	local header: Instance? = panel and panel.header
	if not header or panel.dialog then
		return nil
	end
	local old = header:FindFirstChild("ClaimAll")
	if old then
		old:Destroy()
	end
	local dock = header:FindFirstChild("TabsDock")
	local tabs = dock and dock:FindFirstChild("Tabs")
	local tabsWide = if tabs and tabs:IsA("GuiObject") then tabs.Size.X.Offset else 0
	local on = waiting > 0
	local words = "Claim all"
	local b = Kit.button(words, {
		Name = "ClaimAll",
		Parent = header,
		Size = UDim2.fromOffset(Kit.textWidth(words, 18) + 56, 42),
		-- (the tabs' bar sits 2 in from the right and runs 2 down, 46 tall)
		Position = UDim2.new(1, -(2 + tabsWide + (if tabsWide > 0 then 12 else 0)), 0, 25),
		AnchorPoint = Vector2.new(1, 0.5),
		Color = if on then T.Green else T.PaperDark,
		TextColor = if on then T.Dark else T.InkSoft,
		TextSize = 18,
		ZIndex = 2,
	}, function()
		if on then
			onClick()
		end
	end)
	b:SetAttribute("Disabled", not on)
	b:SetAttribute("Waiting", waiting)
	return b
end

-- A progress line: a label at the left, the numbers at the right, the bar under them (green once
-- it's full). props: Parent, Size, Position, LayoutOrder, Color (the fill's), Coin (the numbers
-- are coins).
function MenuParts.progress(label: string, numbers: string, ratio: number, props: { [string]: any }?): Frame
	local p = props or {}
	local box = Kit.box({
		Name = p.Name or "Progress",
		Parent = p.Parent,
		Size = p.Size or UDim2.new(1, 0, 0, 44),
		Position = p.Position,
		LayoutOrder = p.LayoutOrder,
	})
	Kit.text(label, {
		Name = "Label",
		Parent = box,
		Size = UDim2.new(0.5, 0, 0, 20),
		TextSize = 15,
		Font = Kit.Fonts.Bold,
		Wrap = false,
	})
	-- the numbers at the right end, coins with the coin in front of them
	local right = Kit.box({
		Name = "Numbers",
		Parent = box,
		Size = UDim2.new(0.6, 0, 0, 20),
		Position = UDim2.fromScale(0.4, 0),
	})
	Kit.list(right, 5, true, Enum.HorizontalAlignment.Right)
	if p.Coin then
		Icons.make("coin", 16, { Name = "Coin", Parent = right, LayoutOrder = 1 })
	end
	Kit.text(numbers, {
		Name = "Text",
		Parent = right,
		Size = UDim2.fromOffset(0, 20),
		AutomaticSize = Enum.AutomaticSize.X,
		TextSize = 15,
		Color = T.InkSoft,
		Wrap = false,
		LayoutOrder = 2,
	})
	Kit.bar({
		Parent = box,
		Size = UDim2.new(1, 0, 0, 12),
		Position = UDim2.fromOffset(0, 26),
		Ticks = 4,
	}, ratio, if ratio >= 1 then T.Green else p.Color or T.Blue)
	Kit.mark(box)
	return box
end

-- A box to type in, in a menu: a dark leaning well with the words kept clear of its slanted ends,
-- and an icon at its left if asked (Icon: the magnifier on a search). props: Parent, Size (its
-- height must be in pixels), Position, AnchorPoint, LayoutOrder, Name, Text, TextSize, Icon.
-- Returns the text box and its holder.
function MenuParts.input(placeholder: string, props: { [string]: any }): (TextBox, Frame)
	local size: UDim2 = props.Size or UDim2.new(1, -12, 0, 44)
	local h = size.Y.Offset
	local holder = Kit.box({
		Name = props.Name or "Input",
		Parent = props.Parent,
		Size = size,
		Position = props.Position,
		AnchorPoint = props.AnchorPoint,
		LayoutOrder = props.LayoutOrder,
	})
	local well = Kit.frame({ Name = "Well", Parent = holder, Color = T.PaperDark, Radius = false })
	local lean = Kit.slant(well, h) + 2
	local left = lean
	if props.Icon then
		local px = math.floor(h * 0.42)
		Icons.make(props.Icon, px, {
			Name = "Glass",
			Parent = holder,
			Position = UDim2.new(0, lean + 4, 0.5, -px / 2),
			Color = T.InkSoft,
			Hole = T.PaperDark,
			ZIndex = 2,
		})
		left = lean + px + 8
	end
	local box = Kit.textbox(placeholder, {
		Parent = holder,
		Size = UDim2.new(1, -left - lean, 1, 0),
		Text = props.Text,
		TextSize = props.TextSize or 16,
	})
	box.Position = UDim2.fromOffset(left, 0)
	box.BackgroundTransparency = 1
	box.ZIndex = 2
	local pad = box:FindFirstChildOfClass("UIPadding")
	if pad then
		pad.PaddingLeft = UDim.new(0, 6)
	end
	Kit.mark(holder)
	return box, holder
end

return MenuParts
