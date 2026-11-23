-- Pieces the full menus share (City hall, Town goals, the shop, the town news, the map and the
-- villagers), so the six read as one set: the card on the left that shows the picked thing, the
-- list down the right, a list's section headings, stat tiles for the numbers that matter, the
-- note that says what to do when a list is empty, and soft footnotes. Built from UI/Kit, coloured
-- only from Kit.Theme, so both looks work and a switch repaints them.

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

-- A diamond with an icon upright on it: the marker rows, tiles and empty notes share.
function MenuParts.diamond(parent: Instance, icon: string?, color: Color3, px: number, props: { [string]: any }?): Frame
	local p = props or {}
	local z = p.ZIndex or 2
	local holder = Kit.box({
		Name = p.Name or "Diamond",
		Parent = parent,
		Size = UDim2.fromOffset(px, px),
		Position = p.Position,
		AnchorPoint = p.AnchorPoint,
		LayoutOrder = p.LayoutOrder,
	})
	holder.ZIndex = z
	local side = math.floor(px * 0.72)
	local face = Kit.new("Frame", {
		Name = "Face",
		BackgroundColor3 = color,
		BorderSizePixel = 0,
		Rotation = 45,
		Size = UDim2.fromOffset(side, side),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		ZIndex = z,
		Parent = holder,
	})
	Kit.corner(face, 2)
	if icon and Icons.has(icon) then
		local ipx = math.floor(px * 0.56)
		Icons.make(icon, ipx, {
			Name = "IconArt",
			Parent = holder,
			Position = UDim2.new(0.5, -ipx / 2, 0.5, -ipx / 2),
			Color = p.Glyph or T.Dark,
			Hole = color,
			ZIndex = z + 1,
		})
	end
	return holder
end

-- The card on the left of a menu, showing the picked thing: two corners cut, a soft glow of the
-- menu's colour, and a padded box inside to fill. Returns the card and that box: clear and fill
-- the box, never the card (the card's own shape is a child of it). props: Name, Size, Position.
function MenuParts.card(parent: Instance, accent: Color3, props: { [string]: any }?): (Frame, Frame)
	local p = props or {}
	local card = Kit.frame({
		Name = p.Name or "Detail",
		Parent = parent,
		Size = p.Size or UDim2.new(MenuParts.Split, -MenuParts.Gap / 2, 1, 0),
		Position = p.Position or UDim2.new(),
		Color = T.Paper,
		Cut = 22,
	})
	local glow = (Kit :: any).glow
	if type(glow) == "function" then
		pcall(glow, card, accent)
	end
	local pad = p.Pad or MenuParts.Pad
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

-- A heading over part of a list: a short leaning mark in the menu's colour, the words, and
-- optionally a count or a note at the right end.
function MenuParts.heading(parent: Instance, text: string, accent: Color3, order: number, right: string?): Frame
	local h = Kit.box({ Name = "Heading", Parent = parent, Size = UDim2.new(1, -12, 0, 30), LayoutOrder = order })
	local mark = Kit.new("Frame", {
		Name = "Mark",
		BackgroundColor3 = accent,
		BorderSizePixel = 0,
		Size = UDim2.fromOffset(12, 16),
		Position = UDim2.new(0, 2, 0.5, -6),
		Parent = h,
	})
	Kit.slant(mark, 16)
	Kit.title(text, {
		Name = "Title",
		Parent = h,
		Size = UDim2.new(1, -140, 0, 24),
		Position = UDim2.new(0, 22, 0.5, -10),
		TextSize = 18,
		Wrap = false,
	})
	if right then
		Kit.text(right, {
			Name = "Count",
			Parent = h,
			Size = UDim2.new(0, 120, 0, 24),
			Position = UDim2.new(1, -16, 0.5, -10),
			AnchorPoint = Vector2.new(1, 0),
			TextSize = 14,
			Color = T.InkSoft,
			AlignX = Enum.TextXAlignment.Right,
			Wrap = false,
		})
	end
	return h
end

-- A stat tile: a sunk well with a diamond and a small label at the top and the number big under
-- them. props: Parent, Size, Position, LayoutOrder, Sub (a soft word after the number), Tint (the
-- number in an accent), TextSize, Coin (the number is coins: the coin goes in front of it), Bar (a
-- share from 0 to 1: a thin bar in the tile's colour along its foot). Returns the tile and the
-- number's label.
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
		Cut = 10,
	})
	MenuParts.diamond(tile, icon, color, 26, { Position = UDim2.fromOffset(10, 9) })
	Kit.text(label, {
		Name = "Label",
		Parent = tile,
		Size = UDim2.new(1, -48, 0, 18),
		Position = UDim2.fromOffset(42, 13),
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

-- What a list says when there is nothing in it: a big diamond with the icon, a title and a line
-- on what to do. props: Parent, Size, Position, AnchorPoint, LayoutOrder, Color (the diamond's),
-- Height (the box's, its content in the middle: a whole empty list's height centres it).
function MenuParts.empty(icon: string, title: string, hint: string, props: { [string]: any }?): Frame
	local p = props or {}
	-- (with a Height, the box is that tall and what's in it sits in its middle)
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
	MenuParts.diamond(box, icon, p.Color or T.Line, 64, {
		Position = UDim2.new(0.5, 0, 0, top),
		AnchorPoint = Vector2.new(0.5, 0),
		Glyph = T.Ink,
	})
	Kit.title(title, {
		Name = "Title",
		Parent = box,
		Size = UDim2.new(1, -48, 0, 28),
		Position = UDim2.fromOffset(24, top + 78),
		TextSize = 22,
		AlignX = Enum.TextXAlignment.Center,
	})
	Kit.text(hint, {
		Name = "Hint",
		Parent = box,
		Size = UDim2.new(1, -72, 0, 44),
		Position = UDim2.fromOffset(36, top + 110),
		TextSize = 16,
		Color = T.InkSoft,
		AlignX = Enum.TextXAlignment.Center,
		AlignY = Enum.TextYAlignment.Top,
	})
	return box
end

-- A soft footnote: a small diamond in the menu's colour and a line of words. props: Parent,
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
	local dot = Kit.new("Frame", {
		Name = "Dot",
		BackgroundColor3 = accent,
		BorderSizePixel = 0,
		Rotation = 45,
		Size = UDim2.fromOffset(7, 7),
		Position = UDim2.fromOffset(8, 9),
		Parent = box,
	})
	local _ = dot
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
