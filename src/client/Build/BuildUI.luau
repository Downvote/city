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

local ui: Frame
local tray: Frame
local trayBody: Frame
local subBar: ScrollingFrame
local mainButtons: { [string]: TextButton } = {}
local subButtons: { [string]: TextButton } = {}
local toolButtons: { [string]: TextButton } = {}
local hintLabel: TextLabel
local levelLabel: TextLabel
local coinsLabel: TextLabel
local actionBar: Frame
local actionTitle: TextLabel
local actionButtons: Frame
local viewButtons: { [string]: TextButton } = {}
local built = false
local mainTab = "build"
local subTab = "walls"
local trayMode = "" -- what the tray shows right now
local onExit: (() -> ())? = nil
local paintSide = "a"
local holdTray = 0 -- while a slider is moving, plan updates don't rebuild the tray
local sliderToken = 0

-- small helpers --------------------------------------------------------------------------------------

local function clear(frame: Instance)
	for _, c in frame:GetChildren() do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
end

local function trayRow(height: number?): ScrollingFrame
	local row = Kit.scroll({ Parent = trayBody, Size = UDim2.new(1, 0, 0, height or 160), Axis = Enum.AutomaticSize.X })
	row.ScrollingDirection = Enum.ScrollingDirection.X
	row.ScrollBarThickness = 4
	local layout = Kit.list(row, 8, true)
	layout.VerticalAlignment = Enum.VerticalAlignment.Top
	return row
end

local function trayStack(): ScrollingFrame
	local stack = Kit.scroll({ Parent = trayBody, Size = UDim2.fromScale(1, 1) })
	stack.ScrollBarThickness = 4
	Kit.list(stack, 8)
	return stack
end

local function sectionLabel(parent: Instance, text: string, order: number?)
	Kit.text(text, {
		Parent = parent,
		TextSize = 15,
		Font = Kit.Fonts.Bold,
		Color = T.InkSoft,
		LayoutOrder = order or 0,
		Size = UDim2.new(1, 0, 0, 18),
	})
end

-- A card for a catalog item, the way shop grids in Roblox games look: a white card with a dark
-- outline, the item's 3D picture on a soft blue ground, its name and a green price tag.
local function itemTile(parent: Instance, def: any, order: number, onPick: () -> ()): TextButton
	local card = Kit.new("TextButton", {
		Name = def.id,
		Text = "",
		AutoButtonColor = false,
		BackgroundColor3 = T.Card,
		Size = UDim2.fromOffset(118, 152),
		LayoutOrder = order,
		Parent = parent,
	})
	card:SetAttribute("ItemId", def.id)
	Kit.corner(card, 14)
	local stroke = Kit.stroke(card, T.Ink, 2.5)
	local pic = Kit.frame({
		Parent = card,
		Size = UDim2.new(1, -10, 0, 98),
		Position = UDim2.fromOffset(5, 5),
		Color = T.Picture,
		Radius = 10,
	})
	task.spawn(function()
		ModelPreview.fromPrims(Catalog.prims(def), { Parent = pic })
	end)
	Kit.title(def.name, {
		Parent = card,
		Size = UDim2.new(1, -10, 0, 18),
		Position = UDim2.fromOffset(5, 105),
		TextSize = 14,
		AlignX = Enum.TextXAlignment.Center,
		Wrap = false,
	}).TextTruncate =
		Enum.TextTruncate.AtEnd
	local price = Kit.frame({
		Parent = card,
		Size = UDim2.fromOffset(0, 20),
		AutomaticSize = Enum.AutomaticSize.X,
		Position = UDim2.new(0.5, 0, 0, 125),
		AnchorPoint = Vector2.new(0.5, 0),
		Color = T.Green,
		Radius = 10,
		Stroke = T.Ink,
		StrokeThickness = 2,
	})
	Kit.gradient(price, 0.2)
	Kit.pad(price, 6, 0)
	local row = Kit.box({ Parent = price, Size = UDim2.fromOffset(0, 20), AutomaticSize = Enum.AutomaticSize.X })
	Kit.list(row, 3, true)
	Icons.make("coin", 16, { Parent = row, LayoutOrder = 1 })
	Kit.title(Text.commas(def.price), {
		Parent = row,
		Size = UDim2.fromOffset(0, 20),
		AutomaticSize = Enum.AutomaticSize.X,
		TextSize = 14,
		Color = T.White,
		Wrap = false,
		LayoutOrder = 2,
		Outline = Kit.darker(T.Green, 0.42),
	})
	local scale = Kit.new("UIScale", { Parent = card })
	card.MouseEnter:Connect(function()
		stroke.Color = T.Blue
		TweenService:Create(scale, TweenInfo.new(0.15, Enum.EasingStyle.Back), { Scale = 1.07 }):Play()
	end)
	card.MouseLeave:Connect(function()
		stroke.Color = T.Ink
		TweenService:Create(scale, TweenInfo.new(0.15), { Scale = 1 }):Play()
	end)
	card.Activated:Connect(onPick)
	-- cards pop into the tray one after another
	scale.Scale = 0.4
	TweenService:Create(
		scale,
		TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out, 0, false, math.min(order, 14) * 0.025),
		{ Scale = 1 }
	):Play()
	return card
end

-- A tile for a style or finish: an icon or swatch, and a name. Small tiles are all swatch with
-- the name across the bottom.
local function choiceTile(
	parent: Instance,
	label: string,
	order: number,
	opts: { [string]: any },
	onPick: () -> ()
): TextButton
	local selected = opts.selected == true
	local size: UDim2 = opts.size or UDim2.fromOffset(96, 96)
	local compact = size.Y.Offset < 80
	local card = Kit.new("TextButton", {
		Text = "",
		AutoButtonColor = false,
		BackgroundColor3 = if selected then Kit.mix(T.Card, T.Yellow, 0.38) else T.Card,
		Size = size,
		LayoutOrder = order,
		Parent = parent,
	})
	Kit.corner(card, 12)
	Kit.stroke(card, if selected then T.Blue else T.Ink, if selected then 3.5 else 2)
	if compact and opts.swatch then
		local sw = Kit.frame({
			Name = "Swatch",
			Parent = card,
			Size = UDim2.new(1, -6, 1, -6),
			Position = UDim2.fromOffset(3, 3),
			Color = opts.swatch,
			Radius = 9,
			Clips = true,
		})
		local light = opts.swatch.R + opts.swatch.G + opts.swatch.B > 1.8
		local band = Kit.frame({
			Parent = sw,
			Size = UDim2.new(1, 0, 0, 18),
			Position = UDim2.new(0, 0, 1, -18),
			Color = if light then T.White else T.Shadow,
			Transparency = 0.35,
			Radius = false,
		})
		Kit.text(label, {
			Parent = band,
			Size = UDim2.fromScale(1, 1),
			TextSize = 11,
			Font = Kit.Fonts.Bold,
			Color = if light then T.Dark else T.White,
			AlignX = Enum.TextXAlignment.Center,
			Wrap = false,
		}).TextTruncate =
			Enum.TextTruncate.AtEnd
		if selected then
			Icons.make("check", 20, { Parent = sw, Position = UDim2.new(1, -22, 0, 2) })
		end
	else
		if opts.swatch then
			local sw = Kit.frame({
				Name = "Swatch",
				Parent = card,
				Size = UDim2.new(1, -16, 0, 52),
				Position = UDim2.fromOffset(8, 8),
				Color = opts.swatch,
				Radius = 8,
			})
			Kit.stroke(sw, Kit.darker(opts.swatch, 0.8), 1)
			if opts.material then
				local light = opts.swatch.R + opts.swatch.G + opts.swatch.B > 1.6
				Kit.text(opts.material, {
					Parent = sw,
					Size = UDim2.new(1, -8, 0, 14),
					Position = UDim2.new(0, 4, 1, -16),
					TextSize = 11,
					Font = Kit.Fonts.Bold,
					Color = if light then T.Dark else T.White,
				})
			end
		elseif opts.icon then
			Icons.make(opts.icon, 46, { Parent = card, Position = UDim2.new(0.5, -23, 0, 8) })
		end
		local bottom = if opts.sub then 30 else 16
		Kit.title(label, {
			Parent = card,
			Size = UDim2.new(1, -8, 0, 16),
			Position = UDim2.new(0, 4, 1, -bottom - 2),
			TextSize = 14,
			AlignX = Enum.TextXAlignment.Center,
			Wrap = false,
		})
		if opts.sub then
			Kit.text(opts.sub, {
				Parent = card,
				Size = UDim2.new(1, -8, 0, 14),
				Position = UDim2.new(0, 4, 1, -16),
				TextSize = 11,
				Color = T.InkSoft,
				AlignX = Enum.TextXAlignment.Center,
				Wrap = false,
			})
		end
		if selected then
			Icons.make("check", 24, { Parent = card, Position = UDim2.new(1, -26, 0, 2) })
		end
	end
	card.Activated:Connect(onPick)
	return card
end

local function swatchRow(parent: Instance, current: string?, onPick: (string) -> (), order: number?)
	local row = Kit.scroll({
		Parent = parent,
		Size = UDim2.new(1, 0, 0, 40),
		Axis = Enum.AutomaticSize.X,
		LayoutOrder = order or 0,
	})
	row.ScrollBarThickness = 3
	Kit.list(row, 5, true)
	for i, hex in Palette.Colors do
		local b = Kit.swatch(Colors.fromHex(hex), 30, function()
			onPick(hex)
		end, { Parent = row, LayoutOrder = i })
		if hex == current then
			local st = b:FindFirstChildOfClass("UIStroke")
			if st then
				st.Thickness = 3
				st.Color = T.Ink
			end
		end
	end
	return row
end

local function materialRow(parent: Instance, current: string?, onPick: (string) -> (), order: number?)
	local row = Kit.scroll({
		Parent = parent,
		Size = UDim2.new(1, 0, 0, 34),
		Axis = Enum.AutomaticSize.X,
		LayoutOrder = order or 0,
	})
	row.ScrollBarThickness = 3
	Kit.list(row, 5, true)
	for i, m in Palette.Materials do
		local on = m.id == current
		local b = Kit.button(m.name, {
			Parent = row,
			Size = UDim2.fromOffset(0, 30),
			AutomaticSize = Enum.AutomaticSize.X,
			TextSize = 13,
			Color = if on then T.Yellow else T.PaperDark,
			TextColor = if on then T.Dark else T.Ink,
			LayoutOrder = i,
			Radius = 15,
		})
		Kit.pad(b, 10, 0)
		b.Activated:Connect(function()
			onPick(m.id)
		end)
	end
	return row
end

-- trays ------------------------------------------------------------------------------------------------

local refreshTray: () -> ()

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
		local card = Kit.new("TextButton", {
			Name = preset.id,
			Text = "",
			AutoButtonColor = false,
			BackgroundColor3 = T.Card,
			Size = UDim2.fromOffset(150, 152),
			LayoutOrder = i,
			Parent = row,
		})
		card:SetAttribute("PresetId", preset.id)
		local stroke = Kit.stroke(card, T.Ink, 2.5)
		local pic = Kit.frame({
			Parent = card,
			Size = UDim2.new(1, -10, 0, 98),
			Position = UDim2.fromOffset(5, 5),
			Color = T.Picture,
			Radius = false,
		})
		task.spawn(function()
			ModelPreview.fromPrims(presetLook(preset.id), { Parent = pic })
		end)
		Kit.title(preset.name, {
			Parent = card,
			Size = UDim2.new(1, -10, 0, 18),
			Position = UDim2.fromOffset(5, 105),
			TextSize = 15,
			AlignX = Enum.TextXAlignment.Center,
			Wrap = false,
		})
		if not presetPrices[preset.id] then
			presetPrices[preset.id] = Presets.price(preset.id)
		end
		local tag = Kit.frame({
			Parent = card,
			Size = UDim2.fromOffset(0, 20),
			AutomaticSize = Enum.AutomaticSize.X,
			Position = UDim2.new(0.5, 0, 0, 126),
			AnchorPoint = Vector2.new(0.5, 0),
			Color = T.Green,
			Radius = false,
			Stroke = T.Ink,
			StrokeThickness = 2,
		})
		Kit.pad(tag, 6, 0)
		local tagRow = Kit.box({ Parent = tag, Size = UDim2.fromOffset(0, 20), AutomaticSize = Enum.AutomaticSize.X })
		Kit.list(tagRow, 3, true)
		Icons.make("coin", 16, { Parent = tagRow, LayoutOrder = 1 })
		Kit.title(Text.commas(presetPrices[preset.id]), {
			Parent = tagRow,
			Size = UDim2.fromOffset(0, 20),
			AutomaticSize = Enum.AutomaticSize.X,
			TextSize = 14,
			Color = T.White,
			Wrap = false,
			LayoutOrder = 2,
			Outline = Kit.darker(T.Green, 0.42),
		})
		Kit.text(Text.fill("{w} x {d}", { w = preset.w, d = preset.d }), {
			Parent = pic,
			Size = UDim2.fromOffset(60, 16),
			Position = UDim2.new(1, -64, 0, 4),
			TextSize = 12,
			Font = Kit.Fonts.Bold,
			AlignX = Enum.TextXAlignment.Right,
			Color = T.InkSoft,
		})
		local scale = Kit.new("UIScale", { Parent = card })
		card.MouseEnter:Connect(function()
			stroke.Color = T.Blue
			hintLabel.Text = preset.desc
			TweenService:Create(scale, TweenInfo.new(0.15, Enum.EasingStyle.Back), { Scale = 1.05 }):Play()
		end)
		card.MouseLeave:Connect(function()
			stroke.Color = T.Ink
			TweenService:Create(scale, TweenInfo.new(0.15), { Scale = 1 }):Play()
		end)
		card.Activated:Connect(function()
			BuildMode.startPreset(preset.id)
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
				choiceTile(row, preset.name, 100 + j, {
					swatch = Colors.fromHex(preset.c),
					material = preset.m,
					size = UDim2.fromOffset(112, 126),
					sub = "Drag to lay",
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

local function wallTray(styles: { string }, room: boolean)
	local stack = trayStack()
	local row = Kit.box({ Parent = stack, Size = UDim2.new(1, 0, 0, 96), LayoutOrder = 1 })
	Kit.list(row, 8, true).VerticalAlignment = Enum.VerticalAlignment.Top
	for i, id in styles do
		local def = Plan.WallStyles[id]
		local per = if def.fence then Tuning.Prices.FencePerStud else Tuning.Prices.WallPerStud
		choiceTile(
			row,
			def.name,
			i,
			{ icon = STYLE_ICONS[id], selected = s.wallStyle == id, sub = Text.fill("{n} a stud", { n = per }) },
			function()
				armTool()
				s.wallStyle = id
				refreshTray()
			end
		)
	end
	if not Plan.WallStyles[s.wallStyle].fence then
		-- the paint for new walls, outside and inside: it takes the rest of the row, whatever the
		-- screen's width, so a wide screen shows more finishes at once
		local taken = #styles * (96 + 8)
		local paintBox = Kit.box({ Parent = row, Size = UDim2.new(1, -taken, 0, 96), LayoutOrder = 20 })
		Kit.list(paintBox, 4)
		local toggles = Kit.box({ Parent = paintBox, Size = UDim2.new(1, 0, 0, 30) })
		Kit.list(toggles, 6, true)
		for _, side in { "a", "b" } do
			local on = paintSide == side
			local label = if side == "a" then "Outside" else "Inside"
			local finish = s.wallPaint[side]
			local b = Kit.button(label, {
				Parent = toggles,
				Size = UDim2.fromOffset(110, 28),
				TextSize = 14,
				Color = if on then T.Yellow else T.PaperDark,
				TextColor = if on then T.Dark else T.Ink,
				Radius = 14,
			})
			Kit.frame({
				Parent = b,
				Size = UDim2.fromOffset(16, 16),
				Position = UDim2.new(1, -22, 0.5, -8),
				Color = Colors.fromHex(finish.c),
				Radius = 8,
			})
			b.Activated:Connect(function()
				paintSide = side
				refreshTray()
			end)
		end
		local presets = Kit.scroll({ Parent = paintBox, Size = UDim2.new(1, 0, 0, 58), Axis = Enum.AutomaticSize.X })
		presets.ScrollBarThickness = 3
		Kit.list(presets, 5, true)
		for i, preset in Palette.Presets.walls do
			local cur = s.wallPaint[paintSide]
			choiceTile(presets, preset.name, i, {
				swatch = Colors.fromHex(preset.c),
				selected = cur.c == preset.c and cur.m == preset.m,
				size = UDim2.fromOffset(74, 54),
			}, function()
				armTool()
				s.wallPaint[paintSide] = { c = preset.c, m = preset.m }
				refreshTray()
			end)
		end
	end
	if room then
		sectionLabel(stack, "The room's floor:", 2)
		local floors = trayRow(60)
		floors.LayoutOrder = 3
		floors.Parent = stack
		for i, preset in Palette.Presets.floors do
			choiceTile(floors, preset.name, i, {
				swatch = Colors.fromHex(preset.c),
				selected = s.floorPaint.c == preset.c and s.floorPaint.m == preset.m,
				size = UDim2.fromOffset(74, 54),
			}, function()
				armTool()
				s.floorPaint.c, s.floorPaint.m = preset.c, preset.m
				refreshTray()
			end)
		end
	end
end

local function floorTray()
	local row = trayRow(110)
	for i, preset in Palette.Presets.floors do
		choiceTile(row, preset.name, i, {
			swatch = Colors.fromHex(preset.c),
			material = preset.m,
			selected = s.floorPaint.c == preset.c and s.floorPaint.m == preset.m,
			sub = Text.fill("{n} a square", { n = Tuning.Prices.FloorPerCell }),
		}, function()
			armTool()
			s.floorPaint.c, s.floorPaint.m = preset.c, preset.m
			refreshTray()
		end)
	end
end

-- Roof controls work on new roofs (s.roof) or on a picked roof.
local function roofControls(parent: Instance, get: () -> any, set: (string, any) -> (), order: number)
	local row = Kit.box({ Parent = parent, Size = UDim2.new(1, 0, 0, 96), LayoutOrder = order })
	Kit.list(row, 8, true).VerticalAlignment = Enum.VerticalAlignment.Top
	for i, id in Plan.RoofStyleOrder do
		choiceTile(
			row,
			Plan.RoofStyles[id].name,
			i,
			{ icon = STYLE_ICONS[id], selected = get().style == id },
			function()
				set("style", id)
			end
		)
	end
	local sliders = Kit.box({ Parent = row, Size = UDim2.fromOffset(250, 96), LayoutOrder = 10 })
	Kit.list(sliders, 2)
	Kit.slider("Height", 0, Tuning.Plot.RoofMaxRise, get().rise, 1, function(v)
		set("rise", v)
	end, { Parent = sliders, Size = UDim2.new(1, 0, 0, 44) })
	Kit.slider("Overhang", 0, Tuning.Plot.RoofMaxOverhang, get().over, 0.5, function(v)
		set("over", v)
	end, { Parent = sliders, Size = UDim2.new(1, 0, 0, 44) })
	Kit.button("Turn", {
		Icon = "rotate",
		Parent = row,
		Size = UDim2.fromOffset(90, 40),
		TextSize = 16,
		Color = T.Yellow,
		TextColor = T.Dark,
		LayoutOrder = 11,
	}, function()
		set("dir", (get().dir + 1) % 4)
	end)
	local presets = trayRow(60)
	presets.Parent = parent
	presets.LayoutOrder = order + 1
	for i, preset in Palette.Presets.roofs do
		local cur = get()
		choiceTile(presets, preset.name, i, {
			swatch = Colors.fromHex(preset.c),
			selected = cur.c == preset.c and cur.m == preset.m,
			size = UDim2.fromOffset(84, 54),
		}, function()
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

local function paintTray()
	local stack = trayStack()
	local top = Kit.box({ Parent = stack, Size = UDim2.new(1, 0, 0, 32), LayoutOrder = 1 })
	Kit.list(top, 6, true)
	for _, slot in { { "main", "Main colour" }, { "trim", "Second colour" } } do
		local on = s.paint.slot == slot[1]
		Kit.button(slot[2], {
			Parent = top,
			Size = UDim2.fromOffset(130, 30),
			TextSize = 14,
			Color = if on then T.Yellow else T.PaperDark,
			TextColor = if on then T.Dark else T.Ink,
			Radius = 15,
		}, function()
			s.paint.slot = slot[1]
			refreshTray()
		end)
	end
	Kit.button(if s.paint.pick then "Click something..." else "Copy a colour", {
		Icon = "bucket",
		Parent = top,
		Size = UDim2.fromOffset(160, 30),
		TextSize = 14,
		Color = T.Yellow,
		TextColor = T.Dark,
		Radius = 15,
	}, function()
		s.paint.pick = true
		refreshTray()
	end)
	local current = Kit.frame({
		Name = "Swatch",
		Parent = top,
		Size = UDim2.fromOffset(30, 30),
		Color = Colors.fromHex(s.paint.c),
		Radius = 15,
	})
	Kit.stroke(current, T.Ink, 2)
	sectionLabel(stack, "Finishes", 2)
	local presets = trayRow(60)
	presets.Parent = stack
	presets.LayoutOrder = 3
	local all = {}
	for _, list in { Palette.Presets.walls, Palette.Presets.floors, Palette.Presets.roofs } do
		for _, p in list do
			table.insert(all, p)
		end
	end
	for i, preset in all do
		choiceTile(presets, preset.name, i, {
			swatch = Colors.fromHex(preset.c),
			selected = s.paint.c == preset.c and s.paint.m == preset.m,
			size = UDim2.fromOffset(78, 54),
		}, function()
			s.paint.c, s.paint.m = preset.c, preset.m
			refreshTray()
		end)
	end
	swatchRow(stack, s.paint.c, function(hex)
		s.paint.c = hex
		refreshTray()
	end, 4)
	materialRow(stack, s.paint.m, function(m)
		s.paint.m = m
		refreshTray()
	end, 5)
end

-- What you can do with the picked object.
local function selectionTray()
	local kind, _, obj = BuildMode.selectedObject()
	local stack = trayStack()
	if not kind or not obj then
		Kit.text(
			"Click a wall, floor, roof or piece of furniture to pick it.",
			{ Parent = stack, TextSize = 17, LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 24) }
		)
		Kit.text(
			"Tip: R turns things, Ctrl+Z undoes, PageUp and PageDown change floor, right click cancels.",
			{ Parent = stack, TextSize = 14, Color = T.InkSoft, LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 20) }
		)
		return
	end
	if kind == "items" then
		local def = Catalog.get(obj.id) :: any
		for i, slot in { { "c1", "Main colour" }, { "c2", "Second colour" } } do
			sectionLabel(stack, slot[2], i * 2 - 1)
			local cur = obj[slot[1]] or (if slot[1] == "c1" then def.c1 else (def.c2 or def.c1))
			swatchRow(stack, cur, function(hex)
				BuildMode.editSelected({ [slot[1]] = hex })
			end, i * 2)
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
		local row = Kit.box({ Parent = stack, Size = UDim2.new(1, 0, 0, 96), LayoutOrder = 1 })
		Kit.list(row, 8, true).VerticalAlignment = Enum.VerticalAlignment.Top
		for i, id in Plan.WallStyleOrder do
			choiceTile(
				row,
				Plan.WallStyles[id].name,
				i,
				{ icon = STYLE_ICONS[id], selected = obj.style == id },
				function()
					BuildMode.editSelected({ style = id })
				end
			)
		end
		Kit.text(
			"Use the Paint tool to colour each side.",
			{ Parent = stack, TextSize = 14, Color = T.InkSoft, LayoutOrder = 2 }
		)
	elseif kind == "floors" then
		local row = trayRow(70)
		row.Parent = stack
		row.LayoutOrder = 1
		for i, preset in Palette.Presets.floors do
			choiceTile(row, preset.name, i, {
				swatch = Colors.fromHex(preset.c),
				selected = obj.c == preset.c and obj.m == preset.m,
				size = UDim2.fromOffset(78, 62),
			}, function()
				BuildMode.editSelected({ c = preset.c, m = preset.m })
			end)
		end
	end
end

refreshTray = function()
	clear(trayBody)
	local tool = s.tool
	if tool == "paint" then
		trayMode = "paint"
		paintTray()
	elseif tool == "delete" then
		trayMode = "sell"
		Kit.text(
			"Click anything to sell it back for what you paid.",
			{ Parent = trayBody, TextSize = 18, Size = UDim2.new(1, 0, 0, 30) }
		)
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
			Size = UDim2.fromOffset(88, 70),
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

local HINTS = {
	select = "Click something to pick it. Drag with the right mouse button to look around, WASD to move.",
	wall = "Drag to draw a wall, or click point by point. Right click stops.",
	room = "Drag across the ground to make a whole room with a floor.",
	floor = "Drag across the ground to lay a floor.",
	roof = "Drag over the walls to put a roof on.",
	place = "Click to place. R turns it. Right click puts it away.",
	preset = "Click to put the building down. R turns it. Right click puts it away.",
	paint = "Click a wall side, floor, roof or item to paint it.",
	delete = "Click something to sell it back for what you paid.",
}

local function refreshChrome()
	for id, b in toolButtons do
		local on = (id == "select" and s.tool == "select")
			or (id == "paint" and s.tool == "paint")
			or (id == "delete" and s.tool == "delete")
			or (id == "move" and s.placing ~= nil and s.placing.moveKey ~= nil)
		Kit.setButtonColor(b, if on then T.Yellow else T.Paper, if on then T.Dark else T.Ink)
		local icon = b:FindFirstChild("Icon")
		if icon and icon:IsA("TextLabel") then
			icon.TextColor3 = if on then T.Dark else T.Ink
		end
	end
	levelLabel.Text = "Floor " .. (s.level + 1)
	local hint = HINTS[s.tool] or ""
	if s.tool == "wall" and s.wallMode == "room" then
		hint = HINTS.room
	end
	if s.tool == "place" and not s.placing then
		hint = "Pick something from the tray below."
	end
	hintLabel.Text = hint
	viewButtons.roofs.Text = if s.roofsHidden then "Roofs off" else "Roofs on"
	viewButtons.walls.Text = if s.seeThrough then "Walls clear" else "Walls solid"
	viewButtons.snap.Text = if s.snap then "Grid 1 stud" else "Grid fine"
end

-- the action bar over the picked object ---------------------------------------------------------------------

local function refreshActionBar()
	clear(actionButtons)
	local kind, key, obj = BuildMode.selectedObject()
	if not kind or not obj or s.tool ~= "select" then
		actionBar.Visible = false
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
	local value = -Plan.changeCost(Plan.removeOps(State.plan, kind, key :: string))
	actionTitle.Text = Text.fill("{name}, sells for {value}", { name = name, value = Text.commas(value) })
	local function act(icon: string, fn: () -> (), order: number)
		Kit.iconButton(icon, nil, {
			Parent = actionButtons,
			Size = UDim2.fromOffset(46, 46),
			LayoutOrder = order,
			Radius = 12,
			Color = if icon == "trash" then T.Coral else T.Card,
		}, fn)
	end
	if kind == "items" then
		act("move", BuildMode.moveSelected, 1)
		act("rotate", function()
			BuildMode.rotate(45)
		end, 2)
		act("copy", BuildMode.copySelected, 3)
	elseif kind == "roofs" then
		act("rotate", function()
			BuildMode.rotate(45)
		end, 2)
	end
	act("trash", BuildMode.deleteSelected, 9)
	actionBar.Visible = true
end

local function followSelection()
	if not actionBar.Visible then
		return
	end
	local model = BuildMode.selectedModel()
	local cam = workspace.CurrentCamera
	if not model or not cam then
		actionBar.Visible = false
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
	actionBar.Position = UDim2.fromOffset((p.X - inset.X) / scale, (p.Y - inset.Y) / scale - 12)
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
	local LEFT = 14 -- the margin at each side of the screen

	-- the main groups, along the bottom
	local dock = Kit.frame({
		Name = "Dock",
		Size = UDim2.fromOffset(648, 60),
		Position = UDim2.new(0, LEFT, 1, -12),
		AnchorPoint = Vector2.new(0, 1),
		Color = T.Paper,
		Cut = 12,
		Parent = ui,
	})
	local dockRow = Kit.box({ Parent = dock, Size = UDim2.new(1, -16, 1, -12), Position = UDim2.fromOffset(8, 6) })
	Kit.list(dockRow, 8, true)
	for i, m in MAIN do
		local b = Kit.button(m.name, {
			Parent = dockRow,
			Size = UDim2.fromOffset(152, 48),
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
		Size = UDim2.fromOffset(196, 60),
		Position = UDim2.new(1, -LEFT, 1, -12),
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
		Size = UDim2.new(1, -LEFT * 2, 0, 84),
		Position = UDim2.new(0, LEFT, 1, -78),
		AnchorPoint = Vector2.new(0, 1),
		Color = T.Paper,
		Cut = 12,
		Parent = ui,
	})
	subBar = Kit.scroll({
		Name = "Subs",
		Parent = subHolder,
		Size = UDim2.new(1, -20, 1, -14),
		Position = UDim2.fromOffset(10, 7),
		Axis = Enum.AutomaticSize.X,
	})
	subBar.ScrollBarThickness = 0
	Kit.list(subBar, 0, true)

	-- the tray of things to place and options, as wide as the screen: its rows scroll sideways
	tray = Kit.frame({
		Name = "Tray",
		Size = UDim2.new(1, -LEFT * 2, 0, 182),
		Position = UDim2.new(0, LEFT, 1, -168),
		AnchorPoint = Vector2.new(0, 1),
		Color = T.Paper,
		Cut = 14,
		Parent = ui,
	})
	trayBody = Kit.box({ Parent = tray, Size = UDim2.new(1, -28, 1, -18), Position = UDim2.fromOffset(14, 9) })

	-- the tools, in a row on top of the tray
	local strip = Kit.frame({
		Name = "Tools",
		Size = UDim2.fromOffset(#TOOLS * 66 + 20, 74),
		Position = UDim2.new(0, LEFT, 1, -356),
		AnchorPoint = Vector2.new(0, 1),
		Color = T.Paper,
		Cut = 12,
		Parent = ui,
	})
	local stripRow = Kit.box({ Parent = strip, Size = UDim2.new(1, -20, 1, -12), Position = UDim2.fromOffset(10, 6) })
	Kit.list(stripRow, 0, true)
	for i, tool in TOOLS do
		local b = Kit.tile(tool.icon, tool.name, {
			Parent = stripRow,
			Size = UDim2.fromOffset(66, 62),
			LayoutOrder = i,
			Color = T.Paper,
		}, tool.run)
		toolButtons[tool.id] = b
	end

	-- what the tool in hand does, above the tools
	local hint = Kit.darkPill({
		Name = "Hint",
		Size = UDim2.fromOffset(0, 34),
		Position = UDim2.new(0, LEFT + 12, 1, -436),
		AnchorPoint = Vector2.new(0, 1),
		Parent = ui,
	})
	hint.AutomaticSize = Enum.AutomaticSize.X
	Kit.pad(hint, 12, 0)
	hintLabel = Kit.title("", {
		Parent = hint,
		Size = UDim2.fromOffset(0, 34),
		AutomaticSize = Enum.AutomaticSize.X,
		TextSize = 16,
		Color = T.White,
		Wrap = false,
	})

	-- the floors and the view switches, at the right on top of the tray (level with the tools)
	local floors = Kit.frame({
		Name = "Floors",
		Size = UDim2.fromOffset(196, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Position = UDim2.new(1, -LEFT, 1, -356),
		AnchorPoint = Vector2.new(1, 1),
		Color = T.Paper,
		Parent = ui,
	})
	Kit.pad(floors, 10, 10)
	Kit.list(floors, 8, false, Enum.HorizontalAlignment.Center)
	local levelRow = Kit.box({ Parent = floors, Size = UDim2.new(1, 0, 0, 44), LayoutOrder = 1 })
	Kit.button("", {
		Name = "FloorDown",
		Parent = levelRow,
		Size = UDim2.fromOffset(48, 44),
		TextSize = 22,
		Color = T.Blue,
		Icon = "down",
	}, function()
		BuildMode.setLevel(s.level - 1)
	end)
	levelLabel = Kit.title("Floor 1", {
		Parent = levelRow,
		Size = UDim2.new(1, -100, 1, 0),
		Position = UDim2.fromOffset(50, 0),
		TextSize = 20,
		Color = T.Ink,
		AlignX = Enum.TextXAlignment.Center,
	})
	Kit.button("", {
		Name = "FloorUp",
		Parent = levelRow,
		Size = UDim2.fromOffset(48, 44),
		Position = UDim2.new(1, -48, 0, 0),
		TextSize = 22,
		Color = T.Blue,
		Icon = "up",
	}, function()
		BuildMode.setLevel(s.level + 1)
	end)
	local function toggle(id: string, icon: string, order: number, fn: () -> ())
		local b = Kit.button("", {
			Name = id,
			Parent = floors,
			Size = UDim2.new(1, 0, 0, 36),
			TextSize = 15,
			Color = T.Card,
			TextColor = T.Ink,
			LayoutOrder = order,
			Icon = icon,
		}, fn)
		viewButtons[id] = b
	end
	toggle("roofs", "roof", 2, function()
		BuildMode.setRoofsHidden(not s.roofsHidden)
	end)
	toggle("walls", "wall", 3, function()
		BuildMode.setSeeThrough(not s.seeThrough)
	end)
	toggle("snap", "grid", 4, function()
		s.snap = not s.snap
		BuildMode.notify()
	end)

	-- coins, top left
	local coinPill, coinValue = Kit.pill("coin", {
		Parent = ui,
		Size = UDim2.fromOffset(196, 46),
		Position = UDim2.fromOffset(LEFT + 14, 14),
	})
	local _ = coinPill
	coinsLabel = coinValue
	State.on("coins", function(n)
		coinsLabel.Text = Text.commas(n or 0)
	end)

	-- the floating action bar
	actionBar = Kit.frame({
		Name = "Action",
		Size = UDim2.fromOffset(0, 0),
		AutomaticSize = Enum.AutomaticSize.XY,
		AnchorPoint = Vector2.new(0.5, 1),
		Color = T.Paper,
		Radius = 16,
		Stroke = T.Ink,
		StrokeThickness = 3,
		Parent = ui,
		Visible = false,
	})
	Kit.pad(actionBar, 10, 8)
	Kit.list(actionBar, 6, false, Enum.HorizontalAlignment.Center)
	actionTitle = Kit.title("", {
		Parent = actionBar,
		Size = UDim2.fromOffset(0, 22),
		AutomaticSize = Enum.AutomaticSize.X,
		TextSize = 17,
		Wrap = false,
		LayoutOrder = 1,
	})
	actionButtons = Kit.box({
		Parent = actionBar,
		Size = UDim2.fromOffset(0, 46),
		AutomaticSize = Enum.AutomaticSize.X,
		LayoutOrder = 2,
	})
	Kit.list(actionButtons, 6, true)

	RunService.RenderStepped:Connect(function()
		if ui.Visible then
			followSelection()
		end
	end)

	BuildMode.Changed:Connect(function(what)
		if not s.active then
			ui.Visible = false
			actionBar.Visible = false
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
					elseif name == "Pill" then
						Kit.slideIn(f, 0, -120, 0.12)
					end
				end
			end
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
