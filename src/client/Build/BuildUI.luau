-- The buttons and panels of Build mode: the toolbar, the furniture catalog with 3D pictures,
-- paint swatches and materials, roof settings, and what you can do with the picked object.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Tuning = require(Shared.Config.Tuning)
local Plan = require(Shared.Build.Plan)
local Catalog = require(Shared.Build.Catalog)
local Palette = require(Shared.Data.Palette)
local Colors = require(Shared.Util.Colors)
local Text = require(Shared.Util.Text)

local Kit = require(script.Parent.Parent.UI.Kit)
local ModelPreview = require(script.Parent.Parent.UI.ModelPreview)
local BuildMode = require(script.Parent.BuildMode)

local BuildUI = {}

local T = Kit.Theme
local s = BuildMode.state

local toolbar: Frame
local panel: Frame
local panelBody: Frame
local hintLabel: TextLabel
local levelLabel: TextLabel
local toolButtons: { [string]: TextButton } = {}
local viewButtons: { [string]: TextButton } = {}
local currentPanel = ""
local catalogCat = "seating"
local onExit: (() -> ())? = nil

local function clearBody()
	for _, c in panelBody:GetChildren() do
		c:Destroy()
	end
end

-- A palette of swatches and a row of materials. get() returns { c, m }; set(c, m) applies.
local function paintPicker(parent: Instance, get: () -> any, set: (string, string?) -> (), showMaterials: boolean?)
	local holder = Kit.box({
		Parent = parent,
		Size = UDim2.new(1, 0, 0, if showMaterials == false then 96 else 140),
		Name = "Paint",
	})
	local grid = Kit.scroll({ Parent = holder, Size = UDim2.new(1, 0, 0, 96) })
	Kit.grid(grid, UDim2.fromOffset(26, 26), 5)
	local swatches = {}
	local function refresh()
		local cur = get()
		for hex, b in swatches do
			local stroke = b:FindFirstChildOfClass("UIStroke")
			if stroke then
				stroke.Thickness = if hex == cur.c then 4 else 2
				stroke.Color = if hex == cur.c then T.Ink else Colors.shade(Colors.fromHex(hex), 0.7)
			end
		end
	end
	for i, hex in Palette.Colors do
		local b = Kit.swatch(Colors.fromHex(hex), 26, function()
			set(hex, nil)
			refresh()
		end, { Parent = grid, LayoutOrder = i })
		swatches[hex] = b
	end
	if showMaterials ~= false then
		local mats = Kit.scroll({
			Parent = holder,
			Size = UDim2.new(1, 0, 0, 36),
			Position = UDim2.fromOffset(0, 102),
			Axis = Enum.AutomaticSize.X,
		})
		Kit.list(mats, 4, true)
		local matButtons = {}
		local function refreshMats()
			local cur = get()
			for id, b in matButtons do
				Kit.setButtonColor(
					b,
					if id == cur.m then T.Blue else T.PaperDark,
					if id == cur.m then T.White else T.Ink
				)
			end
		end
		for i, m in Palette.Materials do
			local b = Kit.button(
				m.name,
				{
					Parent = mats,
					Size = UDim2.fromOffset(0, 30),
					AutomaticSize = Enum.AutomaticSize.X,
					TextSize = 14,
					Color = T.PaperDark,
					TextColor = T.Ink,
					LayoutOrder = i,
				}
			)
			Kit.pad(b, 8, 0)
			matButtons[m.id] = b
			b.Activated:Connect(function()
				set(get().c, m.id)
				refreshMats()
			end)
		end
		refreshMats()
	end
	refresh()
	return holder
end

local function row(parent: Instance, height: number?, order: number?): Frame
	local r = Kit.box({ Parent = parent, Size = UDim2.new(1, 0, 0, height or 40), LayoutOrder = order or 0 })
	Kit.list(r, 6, true)
	return r
end

local function choiceRow(
	parent: Instance,
	options: { { id: string, name: string } },
	current: string,
	onPick: (string) -> (),
	order: number?
)
	local r = row(parent, 40, order)
	local buttons = {}
	for i, o in options do
		local b = Kit.button(
			o.name,
			{
				Parent = r,
				Size = UDim2.fromOffset(0, 34),
				AutomaticSize = Enum.AutomaticSize.X,
				TextSize = 15,
				Color = T.PaperDark,
				TextColor = T.Ink,
				LayoutOrder = i,
			}
		)
		Kit.pad(b, 10, 0)
		buttons[o.id] = b
		b.Activated:Connect(function()
			for id, other in buttons do
				Kit.setButtonColor(
					other,
					if id == o.id then T.Blue else T.PaperDark,
					if id == o.id then T.White else T.Ink
				)
			end
			onPick(o.id)
		end)
	end
	for id, b in buttons do
		Kit.setButtonColor(b, if id == current then T.Blue else T.PaperDark, if id == current then T.White else T.Ink)
	end
	return r
end

-- panels -----------------------------------------------------------------------------------------

local function wallPanel()
	local list = Kit.box({ Parent = panelBody, Size = UDim2.fromScale(1, 1) })
	Kit.list(list, 6)
	local styles = {}
	for _, id in Plan.WallStyleOrder do
		table.insert(styles, { id = id, name = Plan.WallStyles[id].name })
	end
	choiceRow(
		list,
		{ { id = "line", name = "Wall by wall" }, { id = "room", name = "Whole room" } },
		s.wallMode,
		function(id)
			s.wallMode = id
			BuildMode.setTool("wall")
		end,
		1
	)
	choiceRow(list, styles, s.wallStyle, function(id)
		s.wallStyle = id
	end, 2)
	local sideRow = row(list, 34, 3)
	local side = "a"
	local caption = Kit.text(
		"Painting the outside of new walls",
		{ Parent = sideRow, Size = UDim2.new(0, 300, 1, 0), TextSize = 15 }
	)
	local flip = Kit.button(
		"Switch to inside",
		{ Parent = sideRow, Size = UDim2.fromOffset(150, 30), TextSize = 14, Color = T.Yellow, TextColor = T.Ink }
	)
	local pickerHolder = Kit.box({ Parent = list, Size = UDim2.new(1, 0, 0, 140), LayoutOrder = 4 })
	local function draw()
		pickerHolder:ClearAllChildren()
		paintPicker(pickerHolder, function()
			return s.wallPaint[side]
		end, function(c, m)
			s.wallPaint[side].c = c
			if m then
				s.wallPaint[side].m = m
			end
		end)
	end
	flip.Activated:Connect(function()
		side = if side == "a" then "b" else "a"
		caption.Text = if side == "a" then "Painting the outside of new walls" else "Painting the inside of new walls"
		flip.Text = if side == "a" then "Switch to inside" else "Switch to outside"
		draw()
	end)
	draw()
end

local function floorPanel()
	local list = Kit.box({ Parent = panelBody, Size = UDim2.fromScale(1, 1) })
	Kit.list(list, 6)
	Kit.text("New floors use this paint:", { Parent = list, TextSize = 15, LayoutOrder = 1 })
	local holder = Kit.box({ Parent = list, Size = UDim2.new(1, 0, 0, 140), LayoutOrder = 2 })
	paintPicker(holder, function()
		return s.floorPaint
	end, function(c, m)
		s.floorPaint.c = c
		if m then
			s.floorPaint.m = m
		end
	end)
end

local function roofControls(parent: Instance, get: () -> any, set: (string, any) -> (), order: number)
	local styles = {}
	for _, id in Plan.RoofStyleOrder do
		table.insert(styles, { id = id, name = Plan.RoofStyles[id].name })
	end
	choiceRow(parent, styles, get().style, function(id)
		set("style", id)
	end, order)
	local r = row(parent, 50, order + 1)
	local _, _ = Kit.slider("Height", 0, Tuning.Plot.RoofMaxRise, get().rise, 1, function(v)
		set("rise", v)
	end, { Parent = r, Size = UDim2.new(0.4, 0, 0, 46) })
	local _, _ = Kit.slider("Overhang", 0, Tuning.Plot.RoofMaxOverhang, get().over, 0.5, function(v)
		set("over", v)
	end, { Parent = r, Size = UDim2.new(0.4, 0, 0, 46) })
	Kit.button(
		"Turn",
		{ Parent = r, Size = UDim2.fromOffset(90, 36), TextSize = 16, Color = T.Yellow, TextColor = T.Ink },
		function()
			set("dir", (get().dir + 1) % 4)
		end
	)
end

local function roofPanel()
	local list = Kit.box({ Parent = panelBody, Size = UDim2.fromScale(1, 1) })
	Kit.list(list, 4)
	roofControls(list, function()
		return s.roof
	end, function(k, v)
		s.roof[k] = v
	end, 1)
	local slotRow = row(list, 30, 3)
	local slot = "main"
	local caption = Kit.text("Roof colour", { Parent = slotRow, Size = UDim2.new(0, 160, 1, 0), TextSize = 15 })
	local flip = Kit.button(
		"Gable colour",
		{ Parent = slotRow, Size = UDim2.fromOffset(140, 28), TextSize = 14, Color = T.Yellow, TextColor = T.Ink }
	)
	local holder = Kit.box({ Parent = list, Size = UDim2.new(1, 0, 0, 96), LayoutOrder = 4 })
	local function draw()
		holder:ClearAllChildren()
		paintPicker(holder, function()
			return if slot == "main" then { c = s.roof.c, m = s.roof.m } else { c = s.roof.c2, m = s.roof.m2 }
		end, function(c)
			if slot == "main" then
				s.roof.c = c
			else
				s.roof.c2 = c
			end
		end, false)
	end
	flip.Activated:Connect(function()
		slot = if slot == "main" then "trim" else "main"
		caption.Text = if slot == "main" then "Roof colour" else "Gable colour"
		flip.Text = if slot == "main" then "Gable colour" else "Roof colour"
		draw()
	end)
	draw()
end

local function paintPanel()
	local list = Kit.box({ Parent = panelBody, Size = UDim2.fromScale(1, 1) })
	Kit.list(list, 6)
	local r = row(list, 36, 1)
	choiceRow(
		r,
		{ { id = "main", name = "Main colour" }, { id = "trim", name = "Second colour" } },
		s.paint.slot,
		function(id)
			s.paint.slot = id
		end
	)
	local pick = Kit.button(
		"Copy a colour",
		{
			Parent = r,
			Size = UDim2.fromOffset(150, 34),
			TextSize = 15,
			Color = T.Yellow,
			TextColor = T.Ink,
			LayoutOrder = 9,
		}
	)
	pick.Activated:Connect(function()
		s.paint.pick = true
		pick.Text = "Click something..."
	end)
	local holder = Kit.box({ Parent = list, Size = UDim2.new(1, 0, 0, 140), LayoutOrder = 2 })
	local function draw()
		holder:ClearAllChildren()
		paintPicker(holder, function()
			return s.paint
		end, function(c, m)
			s.paint.c = c
			if m then
				s.paint.m = m
			end
		end)
	end
	draw()
	BuildUI._onPaintPicked = function()
		pick.Text = "Copy a colour"
		draw()
	end
end

local function catalogPanel()
	local tabs = {}
	for _, c in Catalog.Categories do
		table.insert(tabs, { id = c.id, name = c.name })
	end
	local grid = Kit.scroll({
		Parent = panelBody,
		Size = UDim2.new(1, 0, 1, -46),
		Position = UDim2.fromOffset(0, 46),
		Axis = Enum.AutomaticSize.X,
	})
	grid.ScrollingDirection = Enum.ScrollingDirection.X
	local layout = Kit.list(grid, 8, true)
	layout.VerticalAlignment = Enum.VerticalAlignment.Top
	local function fill(cat: string)
		catalogCat = cat
		for _, c in grid:GetChildren() do
			if c:IsA("GuiObject") then
				c:Destroy()
			end
		end
		for i, def in Catalog.list(cat) do
			local card = Kit.new("TextButton", {
				Text = "",
				AutoButtonColor = true,
				BackgroundColor3 = T.White,
				Size = UDim2.fromOffset(120, 150),
				LayoutOrder = i,
				Parent = grid,
			})
			Kit.corner(card, 12)
			Kit.stroke(card, T.Line, 2)
			local pic = Kit.box({ Parent = card, Size = UDim2.new(1, -8, 0, 92), Position = UDim2.fromOffset(4, 4) })
			task.spawn(function()
				ModelPreview.fromPrims(Catalog.prims(def), { Parent = pic })
			end)
			Kit.text(
				def.name,
				{
					Parent = card,
					Size = UDim2.new(1, -10, 0, 30),
					Position = UDim2.fromOffset(5, 96),
					TextSize = 14,
					Font = Kit.Fonts.Bold,
					AlignX = Enum.TextXAlignment.Center,
				}
			)
			Kit.text(
				Text.commas(def.price),
				{
					Parent = card,
					Size = UDim2.new(1, -10, 0, 18),
					Position = UDim2.fromOffset(5, 126),
					TextSize = 14,
					Color = T.GreenDark,
					AlignX = Enum.TextXAlignment.Center,
					Font = Kit.Fonts.Bold,
				}
			)
			card.Activated:Connect(function()
				BuildMode.startPlacing(def.id)
			end)
		end
	end
	local bar, select = Kit.tabs(tabs, fill, { Parent = panelBody, Size = UDim2.new(1, 0, 0, 40) })
	local _ = bar
	select(catalogCat)
	fill(catalogCat)
end

local function selectPanel()
	local kind, key, obj = BuildMode.selectedObject()
	local list = Kit.box({ Parent = panelBody, Size = UDim2.fromScale(1, 1) })
	Kit.list(list, 6)
	if not kind or not obj then
		Kit.text(
			"Click a wall, floor, roof or piece of furniture to pick it.",
			{ Parent = list, TextSize = 17, LayoutOrder = 1 }
		)
		Kit.text(
			"Tips: R turns things, Ctrl+Z undoes, PageUp and PageDown change floor, right click cancels.",
			{ Parent = list, TextSize = 15, Color = T.InkSoft, LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 44) }
		)
		return
	end
	local name = "Wall"
	if kind == "items" then
		local def = Catalog.get(obj.id)
		name = if def then def.name else obj.id
	elseif kind == "walls" then
		name = (Plan.WallStyles[obj.style] or Plan.WallStyles.wall).name
	elseif kind == "floors" then
		name = string.format("Floor, %d x %d", obj.x2 - obj.x1, obj.z2 - obj.z1)
	elseif kind == "roofs" then
		name = (Plan.RoofStyles[obj.style] or Plan.RoofStyles.gable).name .. " roof"
	end
	local value =
		-Plan.changeCost(Plan.removeOps(require(script.Parent.Parent.Controllers.State).plan, kind, key :: string))
	local header = row(list, 34, 1)
	Kit.title(name, { Parent = header, Size = UDim2.new(0, 360, 1, 0), TextSize = 22 })
	Kit.text(
		"Worth " .. Text.commas(value),
		{ Parent = header, Size = UDim2.new(0, 160, 1, 0), TextSize = 15, Color = T.InkSoft }
	)
	local actions = row(list, 40, 2)
	local function action(label: string, color: Color3, fn: () -> ())
		local b = Kit.button(
			label,
			{
				Parent = actions,
				Size = UDim2.fromOffset(0, 36),
				AutomaticSize = Enum.AutomaticSize.X,
				TextSize = 16,
				Color = color,
			}
		)
		Kit.pad(b, 12, 0)
		b.Activated:Connect(fn)
	end
	if kind == "items" then
		local def = Catalog.get(obj.id)
		local onWall = def and (def.place == "wall" or def.place == "opening")
		action("Move", T.Blue, BuildMode.moveSelected)
		action(if onWall then "Flip side" else "Turn", T.Yellow, function()
			BuildMode.rotate(45)
		end)
		action("Copy", T.Purple, BuildMode.copySelected)
		action("Sell", T.Coral, BuildMode.deleteSelected)
		local slotRow = row(list, 30, 3)
		local slot = "c1"
		local caption = Kit.text("Main colour", { Parent = slotRow, Size = UDim2.new(0, 150, 1, 0), TextSize = 15 })
		local flip = Kit.button(
			"Second colour",
			{ Parent = slotRow, Size = UDim2.fromOffset(150, 28), TextSize = 14, Color = T.PaperDark, TextColor = T.Ink }
		)
		local holder = Kit.box({ Parent = list, Size = UDim2.new(1, 0, 0, 96), LayoutOrder = 4 })
		local function draw()
			holder:ClearAllChildren()
			paintPicker(holder, function()
				local d = def :: any
				return { c = obj[slot] or (if slot == "c1" then d.c1 else (d.c2 or d.c1)), m = "" }
			end, function(c)
				BuildMode.editSelected({ [slot] = c })
			end, false)
		end
		flip.Activated:Connect(function()
			slot = if slot == "c1" then "c2" else "c1"
			caption.Text = if slot == "c1" then "Main colour" else "Second colour"
			flip.Text = if slot == "c1" then "Second colour" else "Main colour"
			draw()
		end)
		draw()
	elseif kind == "roofs" then
		action("Sell", T.Coral, BuildMode.deleteSelected)
		roofControls(list, function()
			return obj
		end, function(k, v)
			BuildMode.editSelected({ [k] = v })
		end, 3)
	elseif kind == "walls" then
		action("Sell", T.Coral, BuildMode.deleteSelected)
		local styles = {}
		for _, id in Plan.WallStyleOrder do
			table.insert(styles, { id = id, name = Plan.WallStyles[id].name })
		end
		choiceRow(list, styles, obj.style, function(id)
			BuildMode.editSelected({ style = id })
		end, 3)
		Kit.text(
			"Use the Paint tool to colour each side.",
			{ Parent = list, TextSize = 15, Color = T.InkSoft, LayoutOrder = 4 }
		)
	else
		action("Sell", T.Coral, BuildMode.deleteSelected)
	end
end

local PANELS = {
	select = selectPanel,
	wall = wallPanel,
	floor = floorPanel,
	roof = roofPanel,
	place = catalogPanel,
	catalog = catalogPanel,
	paint = paintPanel,
}

local function showPanel(name: string, force: boolean?)
	if name == currentPanel and not force then
		return
	end
	currentPanel = name
	clearBody()
	local build = PANELS[name]
	if build then
		panel.Visible = true
		build()
	else
		panel.Visible = false
	end
end

local function refreshTools()
	for id, b in toolButtons do
		local on = s.tool == id or (id == "catalog" and s.tool == "place")
		Kit.setButtonColor(b, if on then T.Blue else T.Paper, if on then T.White else T.Ink)
	end
	levelLabel.Text = "Floor " .. (s.level + 1)
	hintLabel.Text = s.hint
	Kit.setButtonColor(
		viewButtons.roofs,
		if s.roofsHidden then T.PaperDark else T.Blue,
		if s.roofsHidden then T.Ink else T.White
	)
	viewButtons.roofs.Text = if s.roofsHidden then "Roofs hidden" else "Roofs shown"
	Kit.setButtonColor(
		viewButtons.walls,
		if s.seeThrough then T.Blue else T.PaperDark,
		if s.seeThrough then T.White else T.Ink
	)
	Kit.setButtonColor(viewButtons.snap, if s.snap then T.Blue else T.PaperDark, if s.snap then T.White else T.Ink)
	viewButtons.snap.Text = if s.snap then "Grid on" else "Grid fine"
end

function BuildUI.init(exitCallback: () -> ())
	onExit = exitCallback
	local gui = Kit.root()
	toolbar = Kit.frame({
		Name = "BuildBar",
		Size = UDim2.new(0, 1040, 0, 56),
		Position = UDim2.new(0.5, 0, 0, 8),
		AnchorPoint = Vector2.new(0.5, 0),
		Stroke = T.Line,
		Parent = gui,
		Visible = false,
	})
	Kit.pad(toolbar, 8, 6)
	Kit.list(toolbar, 6, true)
	local tools = {
		{ "select", "Pick" },
		{ "wall", "Walls" },
		{ "floor", "Floors" },
		{ "roof", "Roofs" },
		{ "catalog", "Furniture" },
		{ "paint", "Paint" },
		{ "delete", "Sell" },
	}
	for i, t in tools do
		local b = Kit.button(
			t[2],
			{
				Parent = toolbar,
				Size = UDim2.fromOffset(92, 42),
				TextSize = 17,
				Color = T.Paper,
				TextColor = T.Ink,
				LayoutOrder = i,
			}
		)
		toolButtons[t[1]] = b
		b.Activated:Connect(function()
			if t[1] == "catalog" then
				BuildMode.setTool("place")
				s.placing = nil
				showPanel("catalog", true)
			else
				BuildMode.setTool(t[1])
			end
		end)
	end
	local spacer = Kit.box({ Parent = toolbar, Size = UDim2.fromOffset(6, 40), LayoutOrder = 20 })
	local _ = spacer
	Kit.button(
		"Undo",
		{
			Parent = toolbar,
			Size = UDim2.fromOffset(64, 42),
			TextSize = 16,
			Color = T.Yellow,
			TextColor = T.Ink,
			LayoutOrder = 21,
		},
		BuildMode.undo
	)
	Kit.button(
		"Redo",
		{
			Parent = toolbar,
			Size = UDim2.fromOffset(64, 42),
			TextSize = 16,
			Color = T.Yellow,
			TextColor = T.Ink,
			LayoutOrder = 22,
		},
		BuildMode.redo
	)
	Kit.button(
		"Done",
		{ Parent = toolbar, Size = UDim2.fromOffset(80, 42), TextSize = 17, Color = T.Green, LayoutOrder = 30 },
		function()
			if onExit then
				onExit()
			end
		end
	)

	-- the level and view controls sit on the left
	local side = Kit.frame({
		Name = "BuildSide",
		Size = UDim2.fromOffset(150, 250),
		Position = UDim2.new(0, 10, 0.5, -125),
		Stroke = T.Line,
		Parent = gui,
		Visible = false,
	})
	Kit.pad(side, 8, 8)
	Kit.list(side, 6, false, Enum.HorizontalAlignment.Center)
	Kit.button(
		"Up",
		{ Parent = side, Size = UDim2.new(1, 0, 0, 34), TextSize = 16, Color = T.Blue, LayoutOrder = 1 },
		function()
			BuildMode.setLevel(s.level + 1)
		end
	)
	levelLabel = Kit.title(
		"Floor 1",
		{
			Parent = side,
			Size = UDim2.new(1, 0, 0, 28),
			TextSize = 20,
			AlignX = Enum.TextXAlignment.Center,
			LayoutOrder = 2,
		}
	)
	Kit.button(
		"Down",
		{ Parent = side, Size = UDim2.new(1, 0, 0, 34), TextSize = 16, Color = T.Blue, LayoutOrder = 3 },
		function()
			BuildMode.setLevel(s.level - 1)
		end
	)
	viewButtons.roofs = Kit.button(
		"Roofs hidden",
		{
			Parent = side,
			Size = UDim2.new(1, 0, 0, 32),
			TextSize = 14,
			Color = T.PaperDark,
			TextColor = T.Ink,
			LayoutOrder = 4,
		},
		function()
			BuildMode.setRoofsHidden(not s.roofsHidden)
		end
	)
	viewButtons.walls = Kit.button(
		"See-through walls",
		{
			Parent = side,
			Size = UDim2.new(1, 0, 0, 32),
			TextSize = 14,
			Color = T.PaperDark,
			TextColor = T.Ink,
			LayoutOrder = 5,
		},
		function()
			BuildMode.setSeeThrough(not s.seeThrough)
		end
	)
	viewButtons.snap = Kit.button(
		"Grid on",
		{
			Parent = side,
			Size = UDim2.new(1, 0, 0, 32),
			TextSize = 14,
			Color = T.PaperDark,
			TextColor = T.Ink,
			LayoutOrder = 6,
		},
		function()
			s.snap = not s.snap
			BuildMode.notify()
		end
	)
	if Kit.isTouch() then
		Kit.button(
			"Turn",
			{
				Parent = side,
				Size = UDim2.new(1, 0, 0, 32),
				TextSize = 14,
				Color = T.Yellow,
				TextColor = T.Ink,
				LayoutOrder = 7,
			},
			function()
				BuildMode.rotate(45)
			end
		)
	end

	panel = Kit.frame({
		Name = "BuildPanel",
		Size = UDim2.new(0, 820, 0, 250),
		Position = UDim2.new(0.5, 0, 1, -10),
		AnchorPoint = Vector2.new(0.5, 1),
		Stroke = T.Line,
		Parent = gui,
		Visible = false,
	})
	hintLabel = Kit.text(
		"",
		{
			Parent = panel,
			Size = UDim2.new(1, -24, 0, 22),
			Position = UDim2.fromOffset(12, 6),
			TextSize = 15,
			Color = T.InkSoft,
		}
	)
	panelBody = Kit.box({ Parent = panel, Size = UDim2.new(1, -24, 1, -36), Position = UDim2.fromOffset(12, 30) })

	BuildMode.Changed:Connect(function(what)
		if not s.active then
			toolbar.Visible = false
			side.Visible = false
			panel.Visible = false
			currentPanel = ""
			return
		end
		toolbar.Visible = true
		side.Visible = true
		refreshTools()
		if what == "tool" or what == "active" then
			local name = s.tool
			if s.tool == "place" and currentPanel == "catalog" then
				name = "catalog"
			end
			showPanel(name, what == "active")
		elseif what == "selected" or (what == "plan" and s.tool == "select") then
			if s.tool == "select" then
				showPanel("select", true)
			end
		elseif what == "paint" then
			if BuildUI._onPaintPicked then
				BuildUI._onPaintPicked()
			end
		end
	end)
end

return BuildUI
