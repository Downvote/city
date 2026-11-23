-- Pieces the full menus share (City hall, Town goals, the shop, the town news, the map and the
-- villagers), so the six read as one set: the card on the left that shows the picked thing, the
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
	local pad = p.Pad or MenuParts.Pad
	if p.Caption then
		Kit.text(p.Caption, {
			Name = "Caption",
			Parent = card,
			Size = UDim2.new(1, -pad * 2, 0, 16),
			Position = UDim2.fromOffset(pad, 8),
			TextSize = 13,
			Font = Kit.Fonts.Bold,
			Color = T.InkSoft,
			Wrap = false,
		})
	end
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

-- A dim caption over a group of rows, a hairline running on from it, and a count or a note at
-- the right end. (`accent` is kept for callers; a caption is quiet and carries no colour.)
function MenuParts.heading(parent: Instance, text: string, accent: Color3, order: number, right: string?): Frame
	local _ = accent
	local h = Kit.box({ Name = "Heading", Parent = parent, Size = UDim2.new(1, -12, 0, 24), LayoutOrder = order })
	local words = Kit.text(text, {
		Name = "Title",
		Parent = h,
		Size = UDim2.fromOffset(0, 18),
		AutomaticSize = Enum.AutomaticSize.X,
		Position = UDim2.fromOffset(6, 4),
		TextSize = 14,
		Font = Kit.Fonts.Bold,
		Color = T.InkSoft,
		Wrap = false,
	})
	local _2 = words
	-- the hairline, from after the words to before the count
	local line = Kit.new("Frame", {
		Name = "Rule",
		BackgroundColor3 = T.Line,
		BackgroundTransparency = 0.45,
		BorderSizePixel = 0,
		Size = UDim2.new(1, -(#text * 8 + 22) - (if right then 48 else 8), 0, 1),
		Position = UDim2.fromOffset(#text * 8 + 18, 13),
		Parent = h,
	})
	local _3 = line
	if right then
		Kit.text(right, {
			Name = "Count",
			Parent = h,
			Size = UDim2.new(0, 40, 0, 18),
			Position = UDim2.new(1, -6, 0, 4),
			AnchorPoint = Vector2.new(1, 0),
			TextSize = 14,
			Font = Kit.Fonts.Bold,
			Color = T.InkSoft,
			AlignX = Enum.TextXAlignment.Right,
			Wrap = false,
		})
	end
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
	Kit.text(label, {
		Name = "Label",
		Parent = tile,
		Size = UDim2.new(1, -48, 0, 18),
		Position = UDim2.fromOffset(42, 12),
		TextSize = 14,
		Color = T.InkSoft,
		Wrap = false,
	}).TextTruncate =
		Enum.TextTruncate.AtEnd
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
		LeftSpace = h - 2,
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
	return box
end

-- A card that floats over the town (an event being told, a talk with a villager): rounded, in a
-- thin rim, a soft glow of `accent` from its top right, and a darker band across its top for
-- its title, the way a dialog's title sits. What goes under the band goes in the returned box
-- (it is laid out top to bottom and the card grows to fit it). props: Parent, Name, Size,
-- Position, AnchorPoint, ZIndex, Band (the band's height, 44 by default). Returns the card, the
-- band and the box under it.
function MenuParts.sheet(accent: Color3, props: { [string]: any }?): (Frame, Frame, Frame)
	local p = props or {}
	local round = 16
	local card = Kit.frame({
		Name = p.Name or "Page",
		Parent = p.Parent,
		Size = p.Size or UDim2.new(1, 0, 0, 0),
		Position = p.Position,
		AnchorPoint = p.AnchorPoint,
		AutomaticSize = if p.Size then nil else Enum.AutomaticSize.Y,
		LayoutOrder = p.LayoutOrder,
		Color = T.Cream,
		Radius = round,
		ZIndex = p.ZIndex,
	})
	Kit.rim(card, T.Line, 1.5)
	Kit.softShadow(card, 1.4)
	Kit.glow(card, accent, 0.18, "tr")
	local content = Kit.box({
		Name = "Content",
		Parent = card,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
	})
	content.ZIndex = 2
	Kit.list(content, 0)
	local h: number = p.Band or 44
	-- the band: the card's own round top, square where it meets the body, a hairline under it
	local band = Kit.frame({
		Name = "Band",
		Parent = content,
		Size = UDim2.new(1, 0, 0, h),
		Color = T.PaperDark,
		Radius = round,
		LayoutOrder = 0,
	})
	Kit.new("Frame", {
		Name = "Square",
		BackgroundColor3 = T.PaperDark,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, round),
		Position = UDim2.new(0, 0, 1, -round),
		Parent = band,
	})
	Kit.new("Frame", {
		Name = "Rule",
		BackgroundColor3 = T.Line,
		BackgroundTransparency = 0.4,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 1),
		Position = UDim2.new(0, 0, 1, -1),
		ZIndex = 2,
		Parent = band,
	})
	local body = Kit.box({
		Name = "Body",
		Parent = content,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = 1,
	})
	return card, band, body
end

-- A speech bubble: a rounded well lighter than the card, in a thin rim, with a small point on
-- its left near the top (toward whoever speaks). It grows to fit what goes in it (the returned
-- box, padded). props: Parent, Name, Size (its width; its height follows the words),
-- LayoutOrder, Position, Point (false for none).
function MenuParts.speech(props: { [string]: any }?): (Frame, Frame)
	local p = props or {}
	local bubble = Kit.frame({
		Name = p.Name or "Bubble",
		Parent = p.Parent,
		Size = p.Size or UDim2.new(1, 0, 0, 0),
		Position = p.Position,
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = p.LayoutOrder,
		Color = T.Card,
		Radius = 14,
	})
	Kit.rim(bubble, T.Line, 1, 0.35)
	if p.Point ~= false then
		Kit.wedge({
			Parent = bubble,
			Color = T.Card,
			Size = UDim2.fromOffset(10, 12),
			Position = UDim2.fromOffset(-9, 12),
			W = 10,
			H = 12,
		}, "tr")
	end
	local inside = Kit.box({
		Name = "Inside",
		Parent = bubble,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
	})
	inside.ZIndex = 2
	Kit.pad(inside, 14, 10)
	return bubble, inside
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
	}, ratio, if ratio >= 1 then T.Green else p.Color or T.Blue)
	return box
end

return MenuParts
