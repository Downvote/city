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
local Placing = require(Shared.Build.Placing)
local Keepsakes = require(Shared.Sim.Keepsakes)

local Kit = require(script.Parent.Parent.UI.Kit)
local Presets = require(Shared.Data.Presets)
local Icons = require(script.Parent.Parent.UI.Icons)
local Toasts = require(script.Parent.Parent.UI.Toasts)
local ModelPreview = require(script.Parent.Parent.UI.ModelPreview)
local State = require(script.Parent.Parent.Controllers.State)
local Purchase = require(script.Parent.Parent.Controllers.Purchase) -- (VIP pieces: the pass on their cards)
local Floors = require(Shared.Sim.Floors) -- (which floors the player may go to and build on)
local City = require(Shared.Sim.City) -- (grand pieces and buildings wait for the town's level)
local BuildMode = require(script.Parent.BuildMode)
-- (the build mode passes: Free Placing's switch, Fine Grid's, Stretch and Any Colour, Build/Placing;
-- Purchase above asks Roblox to sell one)
local Stretch = require(Shared.Build.Stretch)
local WaterTool = require(script.Parent.WaterTool) -- (water: its tray and a picked water's page)
-- (the Select tool's page, and the Saves page: Build/SelectTool, Build/SavesTray)
local SelectTool = require(script.Parent.SelectTool)
local SavesTray = require(script.Parent.SavesTray)
local ViewTime = require(script.Parent.ViewTime) -- (the time of day the town is shown at, on this screen)

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
			-- columns and posts, a storey tall and shorter (Recipes/Pillars)
			{ id = "pillars", icon = "pillar", name = "Pillars" },
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
			-- small pieces that give off sparkles, smoke, bubbles, snow, a fire's flames (the
			-- user: "particle makers"; Recipes/Effects), indoors or out
			{ id = "effects", icon = "sparkle", name = "Effects" },
			{ id = "fences", icon = "fence", name = "Fences" },
			{ id = "paths", icon = "path", name = "Paths" },
			-- a pool or a pond, dug by dragging, and what goes in it (the user: "also, add ability
			-- to add water, along with things that can go in the water": Build/WaterTool)
			{ id = "water", icon = "water", name = "Water" },
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
	-- the whole plot kept as a build in a slot, and loaded back (the user: "add loading and saving
	-- of plots": Build/SavesTray)
	{
		id = "saves",
		icon = "save",
		name = "Saves",
		subs = { { id = "saves", icon = "save", name = "My builds" } },
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
-- row and the category row are the same height. All of it is kept small (the user: "try to
-- simplify the build mode interface so it dosent take too much of the screen space"), so the plot
-- shows over most of the screen: about half the height it took before is left to the plot.
local EDGE = 10 -- from the screen's edges
local GAP = 6 -- between bars, and between things side by side
local PAD = 6 -- inside a bar, above and below
local SIDE = 10 -- inside a bar, left and right (clear of its round corners)
local CUT = 10
local DOCK_H, TOOLS_H = 46, 60
local TILE_H = 48 -- a category or a tool
local TOOL_W = 54
-- the floors card: five icon buttons in a row (two arrows, then three switches), as tall as the
-- tools row beside it, with a quiet line between the two groups
local VIEW_BTN, VIEW_SPLIT = 48, 11
local FLOORS_W, FLOORS_H = 5 * VIEW_BTN + VIEW_SPLIT + SIDE * 2, TOOLS_H
local LABEL_W = 104 -- the name at the left of a labelled row in the tray
local INNER_H = 136 -- what the tray holds
-- The catalog is one rounded card: the category tiles in a deeper well along one edge of it, and
-- the tray (the cards, or a page of finishes, or a note) along the other. The user, of the cards
-- and the category tiles under them: "the second should move down, shifting the tab below it
-- up", then "move the bottom part up, but make it such that they share the same rectangle
-- background with each other". So the categories are on top and the cards under them. This is
-- the one place that says so: set it to false and the categories go back under the cards.
local CATEGORIES_ON_TOP = true
local WELL_PAD = 4 -- round the tiles in their well
local SEARCH_W = 230 -- the search box, at the well's right end
local SEARCH_H = 34
local WELL_H = TILE_H + WELL_PAD * 2
local CATALOG_H = PAD + WELL_H + PAD + INNER_H + PAD
-- the bars' bottoms, measured up from the bottom of the screen
local CATALOG_AT = EDGE + DOCK_H + GAP
local TOOLS_AT = CATALOG_AT + CATALOG_H + GAP
local HINT_AT = TOOLS_AT + TOOLS_H + GAP
local HINT_H = 28 -- the hint line over the tools, and the grid and turn steps' slab
-- the coins and the camera tip, top left (and the time of day, top right)
local COINS_H, TIP_H = 40, 24
local TOP_LEFT_W, TOP_LEFT_H = 380, EDGE + COINS_H + GAP + TIP_H

-- the cards in the tray: a picture on the upper face, the name and the price on the deeper band
-- along the bottom (a third of the card, as on Kit.tile)
local CARD_W, CARD_H = 104, 132
local CHIP_W, CHIP_H = 84, 40 -- a finish to paint with
local STYLE_W, STYLE_H = 80, 80 -- a kind of wall, fence or roof
local SWATCH = 22 -- a colour to paint with, in a cell this much bigger
local RING = 3

local MATERIAL_NAMES: { [string]: string } = {}
for _, m in Palette.Materials do
	MATERIAL_NAMES[m.id] = m.name
end
local function materialName(id: string): string
	return MATERIAL_NAMES[id] or id
end

local ui: Frame
-- (the build mode passes: their switches and controls, drawn by the functions further down)
local passButtons: { [string]: TextButton } = {}
local stretchCard: Frame? = nil
local stretchFor = "" -- the piece the stretch card was made for
local stretchShow: ((Vector3) -> ())? = nil -- moves its sliders to the piece's stretch
local pickerOpen = false -- Any Colour's picker showing in the Paint tray
local pickerHue, pickerShade = 0, 0.5
-- what one of the passes' switches would do, for the hint (nil for any other button)
local passTip: (string) -> string? = function()
	return nil
end
local refreshPassLooks: () -> () = function() end
local refreshStretchCard: () -> () = function() end
local tray: Frame -- the catalog's lower part, which the tray's pages fill
local trayBody: Frame
local subBar: ScrollingFrame
-- the search box at the well's right end, what it holds, and its clear button (searchTray)
local searchBox: TextBox
local searchClear: TextButton
local searchText = ""
local setSearch: (text: string) -> ()
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
local stepsPill: Frame -- the grid and turn steps (BuildMode.stepGrid, stepTurn)
local gridLabel: TextLabel
local turnLabel: TextLabel
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
	-- (no line round it: the user, "remove the borders around the rectangles")
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
		Kit.box({ Name = "Price", Parent = parent, Size = UDim2.new(1, 0, 0, 16), Position = UDim2.fromOffset(0, y) })
	Kit.list(tag, 3, true, Enum.HorizontalAlignment.Center)
	Icons.make("coin", 14, { Parent = tag, LayoutOrder = 1 })
	Kit.title(Text.commas(price), {
		Name = "Amount",
		Parent = tag,
		Size = UDim2.fromOffset(0, 16),
		AutomaticSize = Enum.AutomaticSize.X,
		TextSize = 14,
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
		Size = UDim2.new(1, -8, 0, 26),
		Position = UDim2.fromOffset(4, foot + 1),
		TextSize = size,
		AlignX = Enum.TextXAlignment.Center,
		ZIndex = 2,
	})
end

-- A catalog item's card: its 3D picture, and its name and price on the band.
local function itemTile(parent: Instance, def: any, order: number, onPick: () -> ()): TextButton
	local b, pic, foot = card(parent, def.id, order, CARD_W, onPick)
	b:SetAttribute("ItemId", def.id)
	-- a flat mark is seen from above (from the side it would show almost nothing)
	local flat = def.place == "mark"
	b:SetAttribute("TopDown", if flat then true else nil)
	task.spawn(function()
		ModelPreview.fromPrims(Catalog.prims(def), {
			Parent = pic,
			Yaw = if flat then 0 else nil,
			Pitch = if flat then 76 else nil,
		})
	end)
	cardName(b, def.name, foot, 12)
	priceTag(b, def.price, CARD_H - 18)
	-- a grand piece says the level it opens at on its picture's corner (Sim/City.unlocked)
	if def.level then
		b:SetAttribute("Level", def.level)
		Kit.leanMark({
			Name = "Level",
			Parent = pic,
			Size = 18,
			Width = 64,
			Text = Text.fill("Level {n}", { n = def.level }),
			Color = if City.unlocked(State.plan, def) then T.Green else T.Coral,
			Position = UDim2.fromOffset(6, 4),
			ZIndex = 3,
		})
	end
	-- a VIP piece says so on its picture's corner (only VIP owners put one down: Sim/Passes)
	if def.vip then
		b:SetAttribute("Vip", true)
		Kit.leanMark({
			Name = "Vip",
			Parent = pic,
			Size = 18,
			Width = 40,
			Text = "VIP",
			Color = T.Purple,
			Position = UDim2.fromOffset(6, 4),
			ZIndex = 3,
		})
	end
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
	cardName(b, def.name, foot, 12)
	Kit.title(if entry.left > 0 then Text.fill("Free, {n} left", { n = entry.left }) else "None left", {
		Name = "Left",
		Parent = b,
		Size = UDim2.new(1, -8, 0, 16),
		Position = UDim2.fromOffset(4, CARD_H - 18),
		TextSize = 13,
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
	local ipx = if sub then 26 else 32
	local top = if sub then 5 else math.floor((foot - ipx) / 2)
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
		Size = UDim2.new(1, -6, 0, STYLE_H - foot - 1),
		Position = UDim2.fromOffset(3, foot),
		TextSize = 12,
		Color = ink,
		AlignX = Enum.TextXAlignment.Center,
		Wrap = true,
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
local openSub: (id: string) -> ()
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
	elseif subTab == "water" then
		if s.tool ~= "water" then
			BuildMode.setTool("water")
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
		local need = Presets.level(preset.id)
		local b, pic, foot = card(row, preset.id, i, 150, function()
			if City.levelOf(State.plan) < need then
				Toasts.show(Text.fill("Opens at Level {n}", { n = need }), "info")
			else
				BuildMode.startPreset(preset.id)
			end
		end)
		b:SetAttribute("PresetId", preset.id)
		-- a grand building says the level it opens at (Presets.level)
		if need > 1 then
			b:SetAttribute("Level", need)
			Kit.leanMark({
				Name = "Level",
				Parent = pic,
				Size = 18,
				Width = 64,
				Text = Text.fill("Level {n}", { n = need }),
				Color = if City.levelOf(State.plan) >= need then T.Green else T.Coral,
				Position = UDim2.fromOffset(6, 4),
				ZIndex = 3,
			})
		end
		task.spawn(function()
			ModelPreview.fromPrims(presetLook(preset.id), { Parent = pic })
		end)
		cardName(b, preset.name, foot, 12)
		if not presetPrices[preset.id] then
			presetPrices[preset.id] = Presets.price(preset.id)
		end
		priceTag(b, presetPrices[preset.id], CARD_H - 18)
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
	elseif draft.state == "current" then
		return "This is the picture on it now. Paste another id to change it.", nil
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
			text = if current then string.format("%d", current) else "",
			id = current,
			state = if current then "current" else "",
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
	-- (an id that isn't a picture shows nothing: its thumbnail could be anything)
	local shown: number? = if draft.state == "bad" then nil else draft.id
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
	local help = "Paste the number from a decal's or an image's Creator Store link."
	Kit.hint(help, { Name = "PictureHelp", Parent = note, Size = UDim2.new(1, -8, 0, 0) })
end

-- A card picked from the tray: the piece is picked up to place. A VIP piece offers the pass
-- instead (the server would turn it down anyway), and a picture piece opens the page for choosing
-- its picture first.
local function pickDef(def: any)
	if def.level and not City.unlocked(State.plan, def) then
		-- a grand piece waits for the town's level (the server would turn it down anyway)
		Toasts.show(Text.fill("Opens at Level {n}", { n = def.level }), "info")
	elseif def.vip and not Purchase.has("vip") then
		Purchase.prompt("vip")
	elseif def.picture then
		pictureDef = def.id
		refreshTray()
	else
		BuildMode.startPlacing(def.id)
	end
end

-- What a search found (Catalog.search): their cards in one row, as a category's are.
local function searchTray()
	if pictureDef and Catalog.get(pictureDef) then
		picturePlaceTray(Catalog.get(pictureDef))
		return
	end
	local list = Catalog.search(searchText)
	if #list == 0 then
		trayNote(trayStack(), "zoom", T.Blue, "Nothing found", { "Try another word." })
		return
	end
	local row = trayRow()
	for i, def in list do
		itemTile(row, def, i, function()
			pickDef(def)
		end)
	end
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
	-- (a picture piece's card, from Pictures or a look, opens the page for choosing its picture)
	if pictureDef and Catalog.get(pictureDef) then
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
			pickDef(def)
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
			local per = Text.fill("{n} a stud", { n = Tuning.Prices.FencePerStud })
			styleTile(fences, def.name, STYLE_ICONS[id], i, s.wallStyle == id, per, function()
				armTool()
				s.wallStyle = id
				refreshTray()
			end)
		end
		Kit.hint("Paint a fence once it's up.", {
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
	end, { Parent = sliders, Size = UDim2.new(1, 0, 0, 39), LayoutOrder = 1 })
	Kit.slider("Overhang", 0, Tuning.Plot.RoofMaxOverhang, get().over, 0.5, function(v)
		set("over", v)
	end, { Parent = sliders, Size = UDim2.new(1, 0, 0, 39), LayoutOrder = 2 })
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

-- the build mode passes in the tray ------------------------------------------------------------------
--
-- The user: "another [gamepass] for x y scaling" and "other gamepasses bloxburg uses for better
-- build mode". Stretch makes a picked piece wider, deeper or taller (Build/Stretch), and Any
-- Colour paints with a colour picked by its hue and shade or typed as a hex code. Without the pass
-- the control shows a padlock, and pressing it asks Roblox to sell it (Controllers/Purchase).

-- A small padlock on the corner of a control whose pass isn't owned (taken off once it is).
local function lockBadge(holder: GuiObject, locked: boolean)
	local had = holder:FindFirstChild("Lock")
	if not locked then
		if had then
			had:Destroy()
		end
		return
	end
	if had then
		return
	end
	local badge = Kit.disc({
		Name = "Lock",
		Parent = holder,
		Size = 22,
		Position = UDim2.new(1, -3, 0, 3),
		AnchorPoint = Vector2.new(1, 0),
		Color = T.Yellow,
		Icon = "lock",
		IconColor = T.Dark,
		ZIndex = holder.ZIndex + 4,
	})
	badge:SetAttribute("KeepColors", true)
end

-- the sides a piece stretches along, as the sliders name them
local STRETCH_SIDES = { "Width", "Height", "Depth" }

-- A slider for each side a piece may stretch along (Build/Stretch.axes), from Tuning.Passes'
-- StretchMin to StretchMax. `scale` is how far it is stretched now; `onSet(scale)` when one moves.
-- Returns a function that moves the sliders to another stretch without calling onSet.
local function stretchSliders(
	parent: Instance,
	def: any,
	scale: Vector3,
	w: number,
	onSet: (Vector3) -> ()
): (Vector3) -> ()
	local allowed = { Stretch.axes(def) }
	local now = { scale.X, scale.Y, scale.Z }
	local setters: { [number]: (number) -> () } = {}
	for i, name in STRETCH_SIDES do
		if allowed[i] then
			local _, set = Kit.slider(
				name,
				Tuning.Passes.StretchMin,
				Tuning.Passes.StretchMax,
				now[i],
				Stretch.Step,
				function(v)
					now[i] = v
					onSet(Vector3.new(now[1], now[2], now[3]))
				end,
				{ Parent = parent, Size = UDim2.fromOffset(w, 44), LayoutOrder = i }
			)
			setters[i] = set
		end
	end
	return function(v: Vector3)
		now = { v.X, v.Y, v.Z }
		for i, set in setters do
			set(now[i])
		end
	end
end

-- The picked piece's stretch, a row in its page of the tray: a slider for each side, or for a
-- player without Stretch a locked button that offers it. Nothing for a piece that keeps its size.
local function stretchRow(parent: Instance, order: number)
	local def, scale = BuildMode.stretchTarget()
	if not def or not scale then
		return
	end
	local row = Kit.box({ Name = "Stretch", Parent = parent, Size = UDim2.new(1, 0, 0, 44), LayoutOrder = order })
	Kit.text("Stretch", {
		Parent = row,
		Size = UDim2.new(0, LABEL_W - GAP, 0, 32),
		TextSize = 15,
		Font = Kit.Fonts.Bold,
		Color = T.InkSoft,
	})
	local inside =
		Kit.box({ Parent = row, Size = UDim2.new(1, -LABEL_W, 1, 0), Position = UDim2.fromOffset(LABEL_W, 0) })
	Kit.list(inside, 16, true).VerticalAlignment = Enum.VerticalAlignment.Top
	if not BuildMode.owns("stretch") then
		local b = Kit.button("Stretch", {
			Name = "StretchLocked",
			Icon = "lock",
			Parent = inside,
			Size = UDim2.fromOffset(132, 32),
			TextSize = 15,
			Color = T.Card,
			TextColor = T.Ink,
			LayoutOrder = 1,
		}, function()
			Purchase.prompt("stretch")
		end)
		b:SetAttribute("Locked", true)
		Kit.text("Make it wider, deeper or taller with the Stretch pass.", {
			Parent = inside,
			Size = UDim2.fromOffset(0, 32),
			AutomaticSize = Enum.AutomaticSize.X,
			TextSize = 15,
			Color = T.InkSoft,
			Wrap = false,
			LayoutOrder = 2,
		})
		return
	end
	stretchSliders(inside, def, scale, 190, function(v)
		-- (sent once the slider settles, not on every step of the drag)
		holdTray = os.clock() + 0.8
		sliderToken += 1
		local token = sliderToken
		task.delay(0.35, function()
			if token == sliderToken then
				BuildMode.setStretch(v)
			end
		end)
	end)
	Kit.button("Reset", {
		Name = "StretchReset",
		Icon = "undo",
		Parent = inside,
		Size = UDim2.fromOffset(108, 32),
		TextSize = 15,
		Color = T.Card,
		TextColor = T.Ink,
		LayoutOrder = 9,
	}, function()
		BuildMode.setStretch(Vector3.one)
	end)
end

-- Any Colour's picker: a bar of hues and a bar of shades of the picked hue (dark to light), and a
-- box for a colour's hex code. What it picks goes on the brush.
local PICK_W = 360

local function hueColour(h: number): Color3
	return Color3.fromHSV(h % 1, 0.8, 0.96)
end

-- the colour at `t` along the shade bar of hue `h`: black, the hue itself at the middle, white
local function shadeColour(h: number, t: number): Color3
	local pure = hueColour(h)
	if t < 0.5 then
		return Color3.new(0, 0, 0):Lerp(pure, t * 2)
	end
	return pure:Lerp(Color3.new(1, 1, 1), (t - 0.5) * 2)
end

-- Puts the two bars' knobs where a colour sits on them (as near as the bars come: a grey or a
-- muted colour is only made exactly by its hex code).
local function placeOnBars(hex: string)
	local h, sat, v = Colors.fromHex(hex):ToHSV()
	pickerHue = h
	-- a strong colour sits on the dark half (black to the hue), a soft one on the light half
	if sat >= 0.6 then
		pickerShade = math.clamp(v / 0.96 / 2, 0, 0.5)
	else
		pickerShade = math.clamp(0.5 + (1 - sat / 0.8) / 2, 0.5, 1)
	end
end

-- One of the picker's bars: a strip of colours (`keys`, spread evenly) with a knob on it, which a
-- click or a drag along it moves. `onPick(t)` as it moves (t from 0 at the left to 1), `onDone`
-- when the drag lets go. Returns the strip, to recolour.
local function pickBar(
	parent: Instance,
	name: string,
	keys: { Color3 },
	value: number,
	onPick: (number) -> (),
	onDone: () -> ()
): Frame
	local hit = Kit.new("TextButton", {
		Name = name,
		Text = "",
		AutoButtonColor = false,
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(PICK_W, 20),
		Parent = parent,
	})
	local strip = Kit.frame({
		Name = "Swatch", -- (a colour to pick from shows its own colours in either look)
		Parent = hit,
		Size = UDim2.new(1, 0, 0, 16),
		Position = UDim2.fromOffset(0, 2),
		Color = Color3.new(1, 1, 1),
		Radius = "pill",
	})
	strip:SetAttribute("KeepColors", true)
	local points = {}
	for i, c in keys do
		table.insert(points, ColorSequenceKeypoint.new((i - 1) / math.max(1, #keys - 1), c))
	end
	Kit.new("UIGradient", { Name = "Hues", Color = ColorSequence.new(points), Parent = strip })
	local knob = Kit.frame({
		Name = "Knob",
		Parent = hit,
		Size = UDim2.fromOffset(18, 18),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(value, 0, 0.5, 0),
		Color = T.White,
		Radius = "round",
		ZIndex = 3,
	})
	knob:SetAttribute("KeepColors", true)
	Kit.rim(knob, T.Dark, 2)
	local dragging = false
	local function at(x: number)
		local t = math.clamp((x - hit.AbsolutePosition.X) / math.max(1, hit.AbsoluteSize.X), 0, 1)
		knob.Position = UDim2.new(t, 0, 0.5, 0)
		onPick(t)
	end
	hit.InputBegan:Connect(function(input)
		local kind = input.UserInputType
		if kind == Enum.UserInputType.MouseButton1 or kind == Enum.UserInputType.Touch then
			dragging = true
			at(input.Position.X)
		end
	end)
	hit.InputChanged:Connect(function(input)
		local kind = input.UserInputType
		if dragging and (kind == Enum.UserInputType.MouseMovement or kind == Enum.UserInputType.Touch) then
			at(input.Position.X)
		end
	end)
	hit.InputEnded:Connect(function(input)
		local kind = input.UserInputType
		if dragging and (kind == Enum.UserInputType.MouseButton1 or kind == Enum.UserInputType.Touch) then
			dragging = false
			onDone()
		end
	end)
	return strip
end

-- The picker's rows in the Paint tray, from `order` on: Hue, Shade and the hex code.
local function colourPicker(stack: Instance, order: number)
	local hues = {}
	for i = 0, 6 do
		table.insert(hues, hueColour(i / 6))
	end
	local hexBox: TextBox
	local chip: Frame
	local shadeStrip: Frame
	local function shown()
		chip.BackgroundColor3 = Colors.fromHex(s.paint.c)
		hexBox.Text = s.paint.c
	end
	local function fromBars()
		s.paint.c = Colors.toHex(shadeColour(pickerHue, pickerShade))
		s.paint.pick = false
		shown()
	end
	local function shades(): ColorSequence
		return ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.new(0, 0, 0)),
			ColorSequenceKeypoint.new(0.5, hueColour(pickerHue)),
			ColorSequenceKeypoint.new(1, Color3.new(1, 1, 1)),
		})
	end
	pickBar(labelledRow(stack, "Hue", 20, order), "Hue", hues, pickerHue, function(t)
		pickerHue = t
		local g = shadeStrip:FindFirstChild("Hues")
		if g and g:IsA("UIGradient") then
			g.Color = shades()
		end
		fromBars()
	end, refreshTray)
	shadeStrip = pickBar(
		labelledRow(stack, "Shade", 20, order + 1),
		"Shade",
		{ Color3.new(0, 0, 0), hueColour(pickerHue), Color3.new(1, 1, 1) },
		pickerShade,
		function(t)
			pickerShade = t
			fromBars()
		end,
		refreshTray
	)
	local hexRow = labelledRow(stack, "Hex code", 26, order + 2)
	hexBox = Kit.textbox("F2E8D5", {
		Name = "Hex",
		Parent = hexRow,
		Size = UDim2.fromOffset(140, 26),
		Text = s.paint.c,
		TextSize = 16,
		LayoutOrder = 1,
	})
	chip = Kit.frame({
		Name = "Swatch",
		Parent = hexRow,
		Size = UDim2.fromOffset(26, 26),
		Color = Colors.fromHex(s.paint.c),
		Radius = "round",
		LayoutOrder = 2,
	})
	Kit.rim(chip, T.Line, 1.5)
	Kit.text("Or type its code.", {
		Parent = hexRow,
		Size = UDim2.fromOffset(0, 26),
		AutomaticSize = Enum.AutomaticSize.X,
		TextSize = 15,
		Color = T.InkSoft,
		Wrap = false,
		LayoutOrder = 3,
	})
	hexBox.FocusLost:Connect(function()
		local hex = string.upper((string.gsub(hexBox.Text, "[^%x]", "")))
		if Colors.isHex(hex) then
			s.paint.c = hex
			s.paint.pick = false
			placeOnBars(hex)
			refreshTray()
		else
			hexBox.Text = s.paint.c
		end
	end)
end

-- The Paint tool: which colour of a piece to paint, the brush, then the finishes, the colours
-- and the materials, each in a row with its name at the left.
local function paintTray()
	local stack = trayStack(4)
	local top = Kit.box({ Parent = stack, Size = UDim2.new(1, 0, 0, 28), LayoutOrder = 1 })
	local left = Kit.box({ Parent = top, Size = UDim2.fromScale(1, 1) })
	Kit.list(left, 12, true)
	local _, pickSlot = Kit.segments({
		{ id = "main", name = "Main colour" },
		{ id = "trim", name = "Second colour" },
	}, function(id)
		s.paint.slot = id
		refreshTray()
	end, { Parent = left, Height = 28, TextSize = 13, LayoutOrder = 1 })
	pickSlot(s.paint.slot)
	Kit.button(if s.paint.pick then "Now click something" else "Copy a colour", {
		Name = "CopyColour",
		Icon = "bucket",
		Parent = left,
		Size = UDim2.fromOffset(176, 28),
		TextSize = 14,
		Color = if s.paint.pick then T.Yellow else T.Card,
		TextColor = if s.paint.pick then T.Dark else T.Ink,
		LayoutOrder = 2,
	}, function()
		s.paint.pick = not s.paint.pick
		refreshTray()
		refreshChrome()
	end)
	-- Any Colour's picker beside the palette (a padlock until the pass is bought)
	local anyOwned = BuildMode.owns("anycolour")
	local open = pickerOpen and anyOwned
	local any = Kit.button(if open then "Back to the palette" else "Any colour", {
		Name = "AnyColour",
		Icon = if anyOwned then "brush" else "lock",
		Parent = left,
		Size = UDim2.fromOffset(if open then 196 else 150, 28),
		TextSize = 14,
		Color = if open then T.Yellow else T.Card,
		TextColor = if open then T.Dark else T.Ink,
		LayoutOrder = 3,
	}, function()
		if not BuildMode.owns("anycolour") then
			Purchase.prompt("anycolour")
			return
		end
		pickerOpen = not pickerOpen
		if pickerOpen then
			placeOnBars(s.paint.c)
		end
		refreshTray()
	end)
	any:SetAttribute("Locked", not anyOwned)
	-- what the brush holds, at the right
	local right = Kit.box({ Parent = top, Size = UDim2.fromScale(1, 1) })
	Kit.list(right, 6, true, Enum.HorizontalAlignment.Right)
	finishChip(right, "Brush", s.paint.c, s.paint.m, 1)
	if open then
		colourPicker(stack, 2)
		materialRow(stack, s.paint.m, function(m)
			s.paint.m = m
			refreshTray()
		end, 6)
		return
	end
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

-- (water: what the water tray is lent to look like the rest of the tray, Build/WaterTool)
local waterKit: WaterTool.TrayKit = {
	trayRow = trayRow,
	trayStack = trayStack,
	styleTile = styleTile,
	itemTile = itemTile,
	refresh = function()
		refreshTray()
	end,
	setTool = BuildMode.setTool,
	tool = function()
		return s.tool
	end,
	startPlacing = function(id: string)
		BuildMode.startPlacing(id)
	end,
	editSelected = BuildMode.editSelected,
	styleW = STYLE_W,
	styleH = STYLE_H,
	gap = GAP,
}

-- (the Select tool's page: what it is lent to look like the rest of the tray, Build/SelectTool)
local selectKit: SelectTool.TrayKit = {
	stack = function()
		return trayStack()
	end,
	note = trayNote,
	swatchRow = swatchRow,
	move = function()
		BuildMode.groupMove()
	end,
	turn = function()
		BuildMode.groupTurn()
	end,
	copy = function()
		BuildMode.groupCopy()
	end,
	sell = function()
		BuildMode.groupSell()
	end,
	paint = function(hex: string)
		BuildMode.groupPaint(hex)
	end,
	clear = function()
		BuildMode.groupClear()
	end,
}

-- (the Saves page: what it is lent, Build/SavesTray)
local savesKit: SavesTray.TrayKit = {
	row = function(height: number?)
		return trayRow(height)
	end,
	stack = function()
		return trayStack()
	end,
	note = trayNote,
	refresh = function()
		if trayMode == "saves" then
			refreshTray()
		end
	end,
	height = INNER_H,
}

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
		-- (wider, deeper or taller with the Stretch pass)
		stretchRow(stack, 3)
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
	elseif kind == "waters" then
		WaterTool.selection(waterKit, stack, obj) -- (water: its edge and depth)
	end
end

local function sellTray()
	local stack = trayStack()
	trayNote(stack, "trash", T.Coral, "Click something to sell it", {
		"You get back what you paid.",
	}, 1)
	Kit.hint("Gifts sell for nothing.", {
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
	elseif tool == "multi" then
		trayMode = "multi" -- (the Select tool's group: Build/SelectTool)
		SelectTool.tray(selectKit)
	elseif searchText ~= "" then
		trayMode = "search" -- (what the search box found: searchTray)
		searchTray()
	elseif subTab == "saves" then
		trayMode = "saves" -- (saved builds: Build/SavesTray)
		SavesTray.tray(savesKit)
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
	elseif subTab == "water" then
		trayMode = "water" -- (water: Build/WaterTool's tray)
		WaterTool.tray(waterKit)
	else
		trayMode = "catalog:" .. subTab
		catalogTray(subTab)
	end
end

-- Searching: what is typed in the box shows what it finds in the tray, with nothing in hand (the
-- tools that keep their own page, Paint and Sell, give way to it); an empty box goes back to the
-- picked category.
setSearch = function(text: string)
	local clean = string.sub(Text.clean(text or ""), 1, Catalog.SearchMax)
	if clean == searchText then
		return
	end
	searchText = clean
	searchClear.Visible = clean ~= ""
	if searchBox.Text ~= text and clean == "" then
		searchBox.Text = ""
	end
	pictureDef = nil
	-- the category tiles step back while the tray shows a search
	for sid, b in subButtons do
		local on = clean == "" and sid == subTab
		Kit.setButtonColor(b, if on then T.Yellow else T.Paper, if on then T.Dark else T.Ink)
	end
	if clean == "" then
		openSub(subTab) -- (back to the picked category, and the tool it uses)
	elseif s.tool ~= "place" or s.placing then
		BuildMode.setTool("place")
		s.placing = nil
		refreshTray()
	else
		refreshTray()
	end
end

-- choosing tabs -------------------------------------------------------------------------------------------

openSub = function(id: string)
	local was = subTab
	subTab = id
	pictureDef = nil
	for sid, b in subButtons do
		Kit.setButtonColor(b, if sid == id then T.Yellow else T.Paper, if sid == id then T.Dark else T.Ink)
	end
	if was and was ~= id and subButtons[was] and subButtons[id] then
		Kit.glide(subButtons[was], subButtons[id])
	end
	-- (a category picked ends a search)
	if searchText ~= "" then
		searchText = ""
		searchBox.Text = ""
		searchClear.Visible = false
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
	elseif id == "water" then
		BuildMode.setTool("water") -- (water: the drag tool, with the pieces in the tray)
	elseif id == "saves" then
		BuildMode.setTool("select") -- (the Saves page: nothing in hand while it shows)
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
			Size = UDim2.fromOffset(80, TILE_H),
			TextSize = 12,
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

-- (with the Select tool in hand, Move, Turn and Copy work on its group: Build/SelectTool)
local function grouping(): boolean
	return s.tool == "multi"
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
	-- many pieces at once: click, Shift-click or drag a box (the user: "add a select tool in
	-- build mode")
	{
		id = "multi",
		icon = "select",
		name = "Select",
		run = function()
			BuildMode.setTool("multi")
		end,
	},
	{
		id = "move",
		icon = "move",
		name = "Move",
		needs = true,
		run = function()
			if grouping() then
				BuildMode.groupMove()
			elseif needSelection() then
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
			if grouping() then
				BuildMode.groupTurn()
			elseif s.placing then
				BuildMode.rotate()
			elseif needSelection() then
				BuildMode.rotate()
			end
		end,
	},
	{
		id = "copy",
		icon = "copy",
		name = "Copy",
		needs = true,
		run = function()
			if grouping() then
				BuildMode.groupCopy()
			elseif needSelection() then
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
	water = "Drag across the ground to dig a pool or a pond.",
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
	-- (Fine Grid's switch: furniture snaps four times finer, a game pass; Build/Placing)
	{ id = "snap", icon = "grid", name = "Fine grid" },
}

local function viewOn(id: string): boolean
	if id == "roofs" then
		return s.roofsHidden == true
	elseif id == "walls" then
		return s.seeThrough == true
	end
	return BuildMode.fineGrid()
end

-- What a switch did, said in the hint for a moment after it changes.
local function viewWords(id: string): string
	local on = viewOn(id)
	if id == "roofs" then
		return if on then "Roofs hidden" else "Roofs shown"
	elseif id == "walls" then
		return if on then "Walls see-through" else "Walls solid"
	end
	if not BuildMode.owns("finegrid") then
		return "Fine Grid is a game pass"
	end
	return if on then "Fine grid on" else "Fine grid off"
end

-- What a floor is called: "Floor 2" (the ground floor is floor 1), or the basement.
local function floorName(lv: number): string
	return if lv < 0 then "Basement" else Text.fill("Floor {n}", { n = lv + 1 })
end

-- What the floor arrows would do from here: "go" to the next floor, "lock" (a pass would open it:
-- the key) or "end" (there is no floor that way). The floors are the ones the player may build on
-- and any their plan already has things on (Sim/Floors): Tall Builds above the third, Basement under
-- the ground floor.
local function floorStep(dir: number): (string, number, string?)
	local lo, hi = Floors.shown(State.data, State.plan)
	local nextLv = s.level + dir
	if nextLv >= lo and nextLv <= hi then
		return "go", nextLv, nil
	end
	local pass = if nextLv >= Plan.Lowest and nextLv <= Plan.Highest then Floors.passFor(State.data, nextLv) else nil
	if pass then
		return "lock", nextLv, pass
	end
	return "end", nextLv, nil
end

-- What a floor arrow says in the hint, for what it would do.
local function floorTip(dir: number): string
	local what, nextLv = floorStep(dir)
	if what == "go" then
		if nextLv < 0 then
			return "Down to the basement"
		elseif s.level < 0 then
			return "Up to the ground floor"
		end
		return Text.fill(if dir > 0 then "Up to floor {n}" else "Down to floor {n}", { n = nextLv + 1 })
	elseif what == "lock" then
		return if dir > 0
			then "Floors past the third come with Tall Builds"
			else "A basement comes with the Basement pass"
	end
	if dir > 0 then
		return "This is the top floor"
	end
	return if s.level < 0 then "This is the basement" else "This is the ground floor"
end

-- What the floors card's button under the mouse would do, for the hint.
-- The grid and turn steps' words: a grid of so many studs, a turn of so many degrees.
local function stepValue(what: string): string
	if what == "grid" then
		return Text.fill("Grid {n}", { n = string.format("%g", BuildMode.gridStep()) })
	end
	return Text.fill("Turn {n}°", { n = string.format("%g", BuildMode.turnAngle()) })
end

-- What a step button would do from here (ids gridDown, gridUp, turnDown, turnUp), for the hint.
local function stepTip(id: string): string?
	local what = if string.sub(id, 1, 4) == "grid" then "grid" elseif string.sub(id, 1, 4) == "turn" then "turn" else nil
	if not what then
		return nil
	end
	local finer = string.sub(id, -4) == "Down"
	local pass = if what == "grid" then "finegrid" else "freeplace"
	local owned = BuildMode.owns(pass)
	local list = if what == "grid" then Placing.grids(owned) else Placing.turns(owned)
	local now = if what == "grid" then BuildMode.gridStep() else BuildMode.turnAngle()
	local nextStep, moves = Placing.stepFrom(list, now, finer)
	if moves then
		return if what == "grid"
			then Text.fill("Snap furniture to {n} studs", { n = string.format("%g", nextStep) })
			else Text.fill("Turn pieces {n}° at a time", { n = string.format("%g", nextStep) })
	end
	if finer and not owned then
		return if what == "grid" then "A finer grid needs Fine Grid" else "Smaller turns need Free Placing"
	end
	if what == "grid" then
		return if finer then "That's the finest grid" else "That's the biggest grid"
	end
	return if finer then "That's the smallest turn" else "That's the biggest turn"
end

-- What the last step press came to, said in the hint for a moment.
local function stepWords(): string?
	local last = BuildMode.lastStep
	if not last then
		return nil
	end
	if last.stop then
		return stepTip(last.what .. (if last.finer then "Down" else "Up"))
	end
	return if last.what == "grid"
		then Text.fill("Furniture snaps to {n} studs", { n = string.format("%g", BuildMode.gridStep()) })
		else Text.fill("R turns pieces {n}°", { n = string.format("%g", BuildMode.turnAngle()) })
end

-- What the time of day's arrows would show, for the hint (Build/ViewTime).
local TIME_TIPS: { [string]: string } = {
	now = "Back to the town's own time",
	morning = "See it in the morning",
	noon = "See it at noon",
	evening = "See it in the evening",
	night = "See it at night",
}

local function viewTip(id: string): string
	-- (the switches of the build mode passes say their own: passTip, further down)
	local own = passTip(id)
	if own then
		return own
	end
	local step = stepTip(id)
	if step then
		return step
	end
	if id == "timeDown" or id == "timeUp" then
		-- (what a press of the time's arrows would show)
		local n = #ViewTime.Options
		local at = (ViewTime.index() - 1 + (if id == "timeDown" then -1 else 1)) % n + 1
		return TIME_TIPS[ViewTime.Options[at].id] or ""
	end
	if id == "down" then
		return floorTip(-1)
	elseif id == "up" then
		return floorTip(1)
	end
	local on = viewOn(id)
	if id == "roofs" then
		return if on then "Show the roofs" else "Hide the roofs"
	elseif id == "walls" then
		return if on then "Make the walls solid again" else "See through the walls"
	end
	if not BuildMode.owns("finegrid") then
		return "Fine Grid snaps furniture four times finer"
	end
	return if on then "Back to the usual grid" else "Snap furniture four times finer"
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

-- Presses a floor arrow: to the next floor, or the pass that opens it.
local function floorPress(dir: number)
	local what, nextLv, pass = floorStep(dir)
	if what == "go" then
		BuildMode.setLevel(nextLv)
	elseif what == "lock" and pass then
		flash(floorTip(dir))
		Purchase.prompt(pass)
	else
		flash(floorTip(dir))
	end
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

-- The floor arrows: dim where there is no floor that way, a small lock on the corner where a pass
-- would open one (pressing it offers the pass).
local function paintFloorButtons()
	for _, pair in { { levelDown, -1 }, { levelUp, 1 } } do
		local b, dir = pair[1] :: GuiButton, pair[2] :: number
		local what = floorStep(dir)
		paintViewButton(b, false, what == "end")
		lockBadge(b, what == "lock") -- (the padlock the passes' other controls wear)
		b:SetAttribute("Locked", what == "lock")
	end
end

refreshChrome = function()
	for _, tool in TOOLS do
		local b = toolButtons[tool.id]
		local on = (tool.id == "select" and s.tool == "select")
			or (tool.id == "multi" and s.tool == "multi")
			or (tool.id == "paint" and s.tool == "paint")
			or (tool.id == "delete" and s.tool == "delete")
			or (tool.id == "move" and s.placing ~= nil and s.placing.moveKey ~= nil)
		-- Move, Turn and Copy need something picked (Turn also turns what you are placing): they
		-- are dimmed until then, and pressing one says so
		local idle = NEEDS[tool.id]
			and not s.selected
			and not (tool.id == "rotate" and s.placing ~= nil)
			and not (s.tool == "multi" and SelectTool.count() > 0)
		Kit.setButtonColor(b, if on then T.Yellow else T.Paper, if on then T.Dark elseif idle then T.InkSoft else T.Ink)
	end
	paintFloorButtons()
	for _, v in VIEW do
		paintViewButton(viewButtons[v.id], viewOn(v.id))
	end
	refreshPassLooks() -- (the passes' switches, and a padlock on those not bought)
	local hint = HINTS[s.tool] or ""
	if s.tool == "wall" then
		hint = if s.wallMode == "room"
			then HINTS.room
			elseif Plan.WallStyles[s.wallStyle] and Plan.WallStyles[s.wallStyle].fence then HINTS.fence
			else HINTS.wall
	elseif s.tool == "paint" and s.paint.pick then
		hint = HINTS.copy
	elseif s.tool == "floor" and s.level < 0 then
		hint = "Drag out a floor to dig a room down here." -- (the basement: Build/Basement)
	elseif s.tool == "place" and not s.placing then
		hint = "Pick something from the tray below."
	elseif s.tool == "multi" then
		hint = SelectTool.hint(Kit.isTouch()) -- (the Select tool: Build/SelectTool)
	elseif subTab == "saves" and s.tool == "select" and not s.selected then
		hint = "Keep your plot as it is in a slot, or load one back."
	end
	if holdingNow and Kit.isTouch() and TOUCH_HINTS[s.tool] then
		hint = TOUCH_HINTS[s.tool]
	end
	-- why the piece in hand can't go where it is ("Bumps into the sofa": Build/Collide)
	if holdingNow and s.blocked and s.blocked ~= "" then
		hint = string.upper(string.sub(s.blocked, 1, 1)) .. string.sub(s.blocked, 2)
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
	-- the grid and turn steps say where they are
	if stepsPill then
		gridLabel.Text = stepValue("grid")
		turnLabel.Text = stepValue("turn")
		stepsPill.Visible = not BuildMode.isDrawing()
	end
end

-- the build mode passes' switches --------------------------------------------------------------------------
--
-- Free Placing's switch sits on a card of its own beside the tools, drawn like the floors card's
-- switches (an icon, no words: the hint names it while the mouse is on it). Fine Grid's is the
-- floors card's grid switch. While a piece is held, Stretch's sliders stand at the bottom right
-- for an owner, as the way back stands beside the hint.

local PASS_W = VIEW_BTN + SIDE * 2

local PASS_SWITCHES = {
	{ id = "free", key = "freeplace", icon = "layers", name = "Free placing" },
}

passTip = function(id: string): string?
	if id ~= "free" then
		return nil
	end
	if not BuildMode.owns("freeplace") then
		return "Free Placing lets pieces overlap and turn any way"
	end
	return if s.freePlace then "Make pieces bump into each other again" else "Let pieces go inside each other"
end

-- One of the passes' switches: a rounded square with an icon, as the floors card's are.
local function passButton(parent: Instance, sw: any, order: number): TextButton
	local b = Kit.new("TextButton", {
		Name = sw.name,
		Text = "",
		AutoButtonColor = false,
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(VIEW_BTN, TILE_H),
		LayoutOrder = order,
		Parent = parent,
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
	local ipx = 24
	Icons.make(sw.icon, ipx, {
		Name = "IconArt",
		Parent = b,
		Position = UDim2.new(0.5, -ipx / 2, 0.5, -ipx / 2),
		Color = T.Ink,
		Hole = T.Card,
		ZIndex = 2,
	})
	hoverable(b)
	b.MouseEnter:Connect(function()
		overView = sw.id
		refreshChrome()
	end)
	b.MouseLeave:Connect(function()
		if overView == sw.id then
			overView = nil
			refreshChrome()
		end
	end)
	b.Activated:Connect(function()
		if sw.id == "free" and BuildMode.toggleFreePlace() then
			flash(if s.freePlace then "Pieces can overlap" else "Pieces bump into each other")
		end
	end)
	return b
end

-- The card with the passes' switches, at the right end of the tools.
local function buildPassCard()
	local toolsW = #TOOLS * TOOL_W + SIDE * 2
	local card = Kit.frame({
		Name = "Placing",
		Size = UDim2.fromOffset(#PASS_SWITCHES * VIEW_BTN + SIDE * 2, TOOLS_H),
		Position = UDim2.new(0, EDGE + toolsW + GAP, 1, -TOOLS_AT),
		AnchorPoint = Vector2.new(0, 1),
		Color = T.Paper,
		Cut = CUT,
		Parent = ui,
	})
	local row = Kit.box({
		Parent = card,
		Size = UDim2.new(1, -SIDE * 2, 1, -PAD * 2),
		Position = UDim2.fromOffset(SIDE, PAD),
	})
	Kit.list(row, 0, true)
	for i, sw in PASS_SWITCHES do
		passButtons[sw.id] = passButton(row, sw, i)
	end
end

refreshPassLooks = function()
	for _, sw in PASS_SWITCHES do
		local b = passButtons[sw.id]
		if b then
			local owned = BuildMode.owns(sw.key)
			paintViewButton(b, owned and s.freePlace, not owned)
			lockBadge(b, not owned)
			b:SetAttribute("Locked", not owned)
		end
	end
	local grid = viewButtons.snap
	if grid then
		local owned = BuildMode.owns("finegrid")
		lockBadge(grid, not owned)
		grid:SetAttribute("Locked", not owned)
	end
end

-- Stretch's sliders for the piece in hand, at the bottom right while it is held (for an owner of
-- the pass, and a piece that stretches). Made again for each piece picked up; a slider's move
-- changes the piece in hand at once.
refreshStretchCard = function()
	local pl = s.placing
	local def = if holdingNow and s.tool == "place" and pl and pl.id then BuildMode.stretchTarget() else nil
	local want = if def and BuildMode.owns("stretch") then def.id else ""
	if want == stretchFor and (want == "") == (stretchCard == nil) then
		return
	end
	stretchFor = want
	if stretchCard then
		stretchCard:Destroy()
		stretchCard = nil
		stretchShow = nil
	end
	if want == "" or not ui then
		return
	end
	local _, scale = BuildMode.stretchTarget()
	local allowed = { Stretch.axes(def) }
	local count = 0
	for _, a in allowed do
		if a then
			count += 1
		end
	end
	local card = Kit.frame({
		Name = "StretchCard",
		Size = UDim2.fromOffset(240, 34 + count * 46 + PAD),
		Position = UDim2.new(1, -EDGE, 1, -EDGE),
		AnchorPoint = Vector2.new(1, 1),
		Color = T.Paper,
		Cut = CUT,
		Parent = ui,
	})
	Kit.title("Stretch", {
		Parent = card,
		Size = UDim2.new(1, -SIDE * 2, 0, 24),
		Position = UDim2.fromOffset(SIDE, PAD),
		TextSize = 17,
		Wrap = false,
	})
	local list = Kit.box({
		Parent = card,
		Size = UDim2.new(1, -SIDE * 2, 0, count * 46),
		Position = UDim2.fromOffset(SIDE, 34),
	})
	Kit.list(list, 2)
	stretchShow = stretchSliders(list, def, scale or Vector3.one, 240 - SIDE * 2, function(v)
		BuildMode.setStretch(v)
	end)
	stretchCard = card
end

-- holding a piece: the interface steps aside --------------------------------------------------------------

-- How far each part goes while a piece is held: the bottom ones down off the screen, the coins
-- and the camera help at the top left up off it.
local AWAY: { [string]: number } = {
	Dock = 460,
	Catalog = 460,
	Tools = 460,
	Floors = 460,
	Placing = 460,
	Pill = -140,
	CameraTip = -140,
	TimeOfDay = -140,
}
local HINT_HOME = UDim2.new(0, EDGE + 12, 1, -HINT_AT)
-- beside the hint while a piece is held: the red way back (it puts the piece away, as a right
-- click does) and, on a touch screen, a round button that turns it
local HOLD_W = 76
local HOLD_H = 38
local TURN_W = 44
-- the grid and turn steps: over the floors card, and while a piece is held beside the way back
-- (a drawing has no furniture to snap or turn: they step aside for it)
local STEPS_W = 296
local STEPS_HOME = UDim2.new(1, -EDGE - STEPS_W, 1, -HINT_AT)
local function stepsShown(): boolean
	return not BuildMode.isDrawing()
end
local function stepsLow(): UDim2
	local turns = Kit.isTouch() and not BuildMode.isDrawing()
	return UDim2.new(0, EDGE + 12 + HOLD_W + GAP + (if turns then TURN_W + GAP else 0), 1, -(EDGE + 12))
end
local function hintLow(): UDim2
	-- (the round turn button stands there on a touch screen, unless a drawing has nothing to turn,
	-- and the steps after it)
	local turns = Kit.isTouch() and not BuildMode.isDrawing()
	local x = EDGE + 12 + HOLD_W + GAP + (if turns then TURN_W + GAP else 0)
	if stepsShown() then
		x += STEPS_W + GAP
	end
	return UDim2.new(0, x, 1, -(EDGE + 12))
end

-- Is a piece in hand, following the pointer to be placed (from a card, or picked up to move or
-- copy), or is something being drawn (a wall, a fence, a room, a floor or path, a roof, a pool:
-- from its first point until it is down or stopped)? The user: "when putting down anything, even
-- the paths, fences and walls, hide the ui just like when putting down buildings and other decor".
local function isHolding(): boolean
	return s.active
		and (
			(s.tool == "place" and s.placing ~= nil)
			or s.tool == "preset"
			or (grouping() and SelectTool.holding())
			or BuildMode.isDrawing()
		)
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
	-- turn the piece and put it away stand beside it), with the grid and turn steps before it
	local stepsTo = if on then stepsLow() else STEPS_HOME
	if instant then
		stepsPill.Position = stepsTo
	else
		TweenService:Create(stepsPill, TweenInfo.new(0.34, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
			Position = stepsTo,
		}):Play()
	end
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
	-- (a drawing has nothing to turn: only the way back stands beside the hint)
	local turns = touch and not BuildMode.isDrawing()
	local turn = touchButtons:FindFirstChild("Turn it")
	if turn and turn:IsA("GuiObject") then
		turn.Visible = turns
	end
	touchButtons.Size = UDim2.fromOffset(HOLD_W + (if turns then TURN_W + GAP else 0), HOLD_H + 6)
	touchButtons.Visible = on
	refreshStretchCard() -- (Stretch's sliders beside it, for the piece in hand)
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
	elseif kind == "waters" then
		name = WaterTool.title(obj) -- (water: "Pond 16 x 12")
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
			BuildMode.rotate()
		end, 2)
		act("copy", "Copy", BuildMode.copySelected, 3)
	elseif kind == "roofs" then
		act("rotate", "Turn", function()
			BuildMode.rotate()
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
	-- (the tools, and the passes' card beside them)
	if left < EDGE + #TOOLS * TOOL_W + SIDE * 2 + GAP + PASS_W then
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

-- the time of day the town is shown at (Build/ViewTime), top right
local TIME_W = 212
local timeShown: Frame
local timeLabel: TextLabel

-- Shows the picked time on its slab: its icon and its name.
local function showTime()
	if not timeShown then
		return
	end
	local now = ViewTime.current()
	timeLabel.Text = now.name
	local old = timeShown:FindFirstChild("TimeIcon")
	if old then
		old:Destroy()
	end
	Icons.make(now.icon, 16, {
		Name = "TimeIcon",
		Parent = timeShown,
		Position = UDim2.new(0, 0, 0.5, -8),
		Color = if now.hour then T.Yellow else T.White,
		Hole = T.Glass,
		Centre = true,
	})
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
	local dockButtonW = 124
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
			TextSize = 16,
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
		Size = UDim2.fromOffset(140, DOCK_H - PAD * 2),
		Position = UDim2.new(1, -SIDE, 0, PAD),
		AnchorPoint = Vector2.new(1, 0),
		TextSize = 18,
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
	subBar = Kit.scroll({
		Name = "Subs",
		Parent = well,
		Size = UDim2.new(1, -WELL_PAD * 2 - SEARCH_W - GAP * 2, 0, TILE_H),
		Position = UDim2.fromOffset(WELL_PAD, WELL_PAD),
		Axis = Enum.AutomaticSize.X,
	})
	-- the search box at the well's right end (the user: "add searching in build mode"): the cards
	-- of every piece whose name, kind, look or tags have the words typed, as they are typed
	local searchRow = Kit.box({
		Name = "BuildSearch", -- (the creator has a "Search" of its own)
		Parent = well,
		Size = UDim2.fromOffset(SEARCH_W, SEARCH_H),
		Position = UDim2.new(1, -WELL_PAD - GAP, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
		ZIndex = 2,
	})
	local searchWell = Kit.frame({ Name = "Well", Parent = searchRow, Color = T.PaperDark, Radius = false, ZIndex = 2 })
	Kit.slant(searchWell, SEARCH_H)
	Icons.make("zoom", 16, {
		Name = "Glass",
		Parent = searchRow,
		Position = UDim2.new(0, 14, 0.5, -8),
		Color = T.InkSoft,
		Hole = T.PaperDark,
		ZIndex = 3,
	})
	searchBox = Kit.textbox("Search", {
		Name = "SearchBox",
		Parent = searchRow,
		Size = UDim2.new(1, -66, 1, 0),
		TextSize = 15,
	})
	searchBox.Position = UDim2.fromOffset(34, 0)
	searchBox.BackgroundTransparency = 1
	searchBox.ClipsDescendants = true
	searchBox.ZIndex = 3
	local boxPad = searchBox:FindFirstChildOfClass("UIPadding")
	if boxPad then
		boxPad.PaddingLeft = UDim.new(0, 2)
	end
	searchClear = Kit.roundButton("close", {
		Name = "ClearSearch",
		Parent = searchRow,
		Size = 22,
		Position = UDim2.new(1, -16, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
	}, function()
		setSearch("")
	end)
	searchClear.ZIndex = 3
	searchClear.Visible = false
	-- the tray follows the words a moment after the last key
	local searchToken = 0
	searchBox:GetPropertyChangedSignal("Text"):Connect(function()
		searchToken += 1
		local token = searchToken
		task.delay(0.15, function()
			if token == searchToken then
				setSearch(searchBox.Text)
			end
		end)
	end)
	searchBox.FocusLost:Connect(function()
		searchToken += 1
		setSearch(searchBox.Text)
	end)
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
			TextSize = 12,
		}, tool.run)
		toolButtons[tool.id] = b
	end

	-- what the tool in hand does, above the tools
	hintPill = Kit.darkPill({
		Name = "Hint",
		Size = UDim2.fromOffset(0, HINT_H),
		Position = UDim2.new(0, EDGE + 12, 1, -HINT_AT),
		AnchorPoint = Vector2.new(0, 1),
		Parent = ui,
	})
	hintPill.AutomaticSize = Enum.AutomaticSize.X
	Kit.pad(hintPill, 6, 0)
	hintLabel = Kit.title("", {
		Parent = hintPill,
		Size = UDim2.fromOffset(0, HINT_H),
		AutomaticSize = Enum.AutomaticSize.X,
		TextSize = 14,
		Color = T.White,
		Wrap = false,
	})
	-- while a piece is held, the way back stands beside the hint for everyone: the red leaning
	-- button every menu has, and it does what a right click does (the user: "add a back button
	-- while having a building being put down that does the same as right click"). A touch screen
	-- has no R either, so a round button beside it turns the piece there.
	touchButtons = Kit.box({
		Name = "Holding",
		Size = UDim2.fromOffset(HOLD_W, HOLD_H + 6),
		Position = UDim2.new(0, EDGE + 12, 1, -(EDGE + 3)),
		AnchorPoint = Vector2.new(0, 1),
		Visible = false,
		Parent = ui,
	})
	Kit.list(touchButtons, GAP, true)
	local putAway = Kit.backButton({ Parent = touchButtons, Size = UDim2.fromOffset(HOLD_W, HOLD_H) }, function()
		BuildMode.putAway()
	end)
	putAway.Name = "Put it away"
	putAway.LayoutOrder = 0
	Kit.roundButton("rotate", { Name = "Turn it", Parent = touchButtons, Size = TURN_W, LayoutOrder = 1 }, function()
		BuildMode.rotate()
	end)

	-- The grid and turn steps (the user: "make options for increasing/decreasing grid size, and
	-- rotation angle, which also can be adjusted while putting down things"): a glass slab with a
	-- minus and a plus for each, over the floors card, and while a piece is held down beside the
	-- way back, where it stays. The keys do the same: [ and ] for the grid, - and = for the turn.
	stepsPill = Kit.darkPill({
		Name = "Steps",
		Size = UDim2.fromOffset(STEPS_W, HINT_H),
		Position = STEPS_HOME,
		AnchorPoint = Vector2.new(0, 1),
		Parent = ui,
	})
	local stepsRow = Kit.box({
		Name = "Row",
		Parent = stepsPill,
		Size = UDim2.new(1, -28, 1, 0),
		Position = UDim2.fromOffset(14, 0),
	})
	Kit.list(stepsRow, 4, true, Enum.HorizontalAlignment.Center)
	local function stepButton(icon: string, name: string, id: string, order: number, run: () -> ())
		local b = Kit.roundButton(icon, { Name = name, Parent = stepsRow, Size = 22, LayoutOrder = order }, run)
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
		return b
	end
	local function stepLabel(name: string, order: number): TextLabel
		return Kit.title("", {
			Name = name,
			Parent = stepsRow,
			Size = UDim2.fromOffset(76, HINT_H),
			TextSize = 13,
			Color = T.White,
			AlignX = Enum.TextXAlignment.Center,
			Wrap = false,
			LayoutOrder = order,
		})
	end
	stepButton("minus", "Smaller grid", "gridDown", 1, function()
		BuildMode.stepGrid(true)
	end)
	gridLabel = stepLabel("GridStep", 2)
	stepButton("plus", "Bigger grid", "gridUp", 3, function()
		BuildMode.stepGrid(false)
	end)
	Kit.box({ Name = "Gap", Parent = stepsRow, Size = UDim2.fromOffset(8, HINT_H), LayoutOrder = 4 })
	stepButton("minus", "Smaller turn", "turnDown", 5, function()
		BuildMode.stepTurn(true)
	end)
	turnLabel = stepLabel("TurnStep", 6)
	stepButton("plus", "Bigger turn", "turnUp", 7, function()
		BuildMode.stepTurn(false)
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
		local ipx = 24
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
		floorPress(-1)
	end)
	levelUp = viewButton("FloorUp", "up", "up", 2, function()
		floorPress(1)
	end)
	-- a pass bought changes where the arrows go (and the lock on an arrow's corner: paintFloorButtons)
	State.on("passes", function()
		refreshChrome()
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
			BuildMode.toggleFineGrid() -- (asks to sell Fine Grid to a player without it)
		end,
	}
	for i, v in ipairs(VIEW) do
		viewButtons[v.id] = viewButton(v.name, v.icon, v.id, 3 + i, function()
			VIEW_RUN[v.id]()
			flash(viewWords(v.id))
		end)
	end

	-- the passes' switches, on a card at the right end of the tools (Free Placing's)
	buildPassCard()
	-- a pass bought (or a refund) shows on the switches and the tray at once
	State.on("passes", function()
		if not ui.Visible then
			return
		end
		refreshChrome()
		refreshStretchCard()
		if trayMode == "paint" or trayMode == "select" then
			refreshTray()
		end
	end)

	-- coins, top left, and under them how to look around
	local coinPill, coinValue = Kit.pill("coin", {
		Parent = ui,
		Size = UDim2.fromOffset(176, COINS_H),
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

	-- The time the town is shown at, on this screen only, top right across from the coins (the
	-- user: "in build mode, allow the player to toggle what time they see their city in"): the
	-- arrows go through Now (the town's own time), Morning, Noon, Evening and Night (Build/ViewTime).
	local timePill = Kit.darkPill({
		Name = "TimeOfDay",
		Size = UDim2.fromOffset(TIME_W, COINS_H),
		Position = UDim2.new(1, -EDGE - 14, 0, EDGE),
		AnchorPoint = Vector2.new(1, 0),
		Parent = ui,
	})
	local timeRow = Kit.box({
		Name = "Row",
		Parent = timePill,
		Size = UDim2.new(1, -28, 1, 0),
		Position = UDim2.fromOffset(14, 0),
	})
	Kit.list(timeRow, 6, true, Enum.HorizontalAlignment.Center).VerticalAlignment = Enum.VerticalAlignment.Center
	local function timeButton(name: string, id: string, order: number, dir: number): TextButton
		local b = Kit.roundButton("back", { Name = name, Parent = timeRow, Size = 26, LayoutOrder = order }, function()
			ViewTime.step(dir)
			showTime()
			local now = ViewTime.current()
			flash(
				if now.hour
					then Text.fill("{when}, on your screen only", { when = now.name })
					else "The town's own time"
			)
		end)
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
		return b
	end
	timeButton("Earlier", "timeDown", 1, -1)
	timeShown =
		Kit.box({ Name = "Shown", Parent = timeRow, Size = UDim2.fromOffset(TIME_W - 96, COINS_H), LayoutOrder = 2 })
	timeLabel = Kit.title("", {
		Name = "TimeName",
		Parent = timeShown,
		Size = UDim2.new(1, -22, 1, 0),
		Position = UDim2.fromOffset(22, 0),
		TextSize = 15,
		Color = T.White,
		Wrap = false,
	})
	local later = timeButton("Later", "timeUp", 3, 1)
	local arrow = later:FindFirstChild("IconArt")
	if arrow and arrow:IsA("GuiObject") then
		arrow.Rotation = 180 -- (the way on: the back arrow turned round)
	end
	showTime()

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
			-- back to the town's own time, and no search, for the next visit
			if ViewTime.index() ~= 1 then
				ViewTime.set(1)
				showTime()
			end
			if searchText ~= "" then
				searchText = ""
				searchBox.Text = ""
				searchClear.Visible = false
			end
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
					elseif name == "Tools" or name == "Hint" or name == "Placing" then
						Kit.slideIn(f, -260, 0, 0.1)
					elseif name == "Floors" then
						Kit.slideIn(f, 260, 0, 0.12)
					elseif name == "Pill" or name == "CameraTip" or name == "TimeOfDay" then
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
			flash(floorName(s.level))
		end
		if what == "steps" then
			local words = stepWords()
			if words then
				flash(words)
			end
		end
		refreshChrome()
		if what == "tool" then
			if s.tool == "preset" then
				if trayMode ~= "buildings" then
					refreshTray()
				end
			elseif s.tool == "place" and s.placing then
				-- keep showing the catalog (or the search) the item came from
				if trayMode:sub(1, 8) ~= "catalog:" and trayMode ~= "search" then
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
			if (s.tool == "select" or s.tool == "multi") and (what == "selected" or os.clock() > holdTray) then
				refreshTray()
			end
			refreshActionBar()
		elseif what == "paint" then
			refreshTray()
		end
		-- (Stretch's sliders follow the piece in hand)
		if what == "tool" or what == "passes" then
			refreshStretchCard()
		elseif what == "stretch" and stretchShow then
			local _, scale = BuildMode.stretchTarget()
			if scale then
				stretchShow(scale)
			end
		end
	end)
end

return BuildUI
