-- The villager creator. Works like a catalog avatar editor: browse or search the whole Roblox
-- catalog by category, click to wear or take off, mix bundles (bodies, heads, animations, shoes),
-- set skin colours and body shape, copy any player's avatar, save outfits, undo and redo.
-- The look is shown on a mannequin on a private stage; then you give them a name and a personality.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local AvatarEditorService = game:GetService("AvatarEditorService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Remotes = require(Shared.Net.Remotes)
local Appearance = require(Shared.Avatar.Appearance)
local Categories = require(Shared.Avatar.Categories)
local Personalities = require(Shared.Data.Personalities)
local Palette = require(Shared.Data.Palette)
local Schema = require(Shared.Sim.Schema)
local Colors = require(Shared.Util.Colors)
local Text = require(Shared.Util.Text)
local Tuning = require(Shared.Config.Tuning)

local Kit = require(script.Parent.Kit)
local Icons = require(script.Parent.Icons)
local Toasts = require(script.Parent.Toasts)
local State = require(script.Parent.Parent.Controllers.State)

local Creator = {}

local T = Kit.Theme
local player = Players.LocalPlayer

local root: Frame? = nil
local isOpen = false
local mode = "new"
local editVid: string? = nil
local app = Appearance.default()
local history: { any } = {}
local future: { any } = {}
local origin = Vector3.zero
local camConn: RBXScriptConnection? = nil
local inputConns: { RBXScriptConnection } = {}
local yaw = 0
local zoom = 11
local focusY = 2.8
local previewToken = 0
local previewPending = false
local openToken = 0
local saving = false

-- browsing
local tabId = "hair"
local filterIndex = 1
local keyword = ""
local sortId = "Relevance"
local pages: any = nil
local searchToken = 0
local itemInfo: { [number]: { name: string, type: string?, bundle: boolean? } } = {}
local resultCache: { [string]: { any } } = {}

-- ui pieces filled in by build()
local grid: ScrollingFrame
local content: Frame
local filterRow: ScrollingFrame
local searchBox: TextBox
local sortButton: TextButton
local loadMore: TextButton
local lookPage: Frame
local profilePage: Frame
local stepButtons: { [string]: TextButton } = {}
local titleHolder: Frame
local titleRibbon: Frame? = nil
local selectTab: (string) -> ()
local markTab: ((string) -> ())? = nil
local profile = { name = "", pers = "sunny", color = "4FA9D9", bday = { s = 1, d = 1 } }

local function thumb(id: number, bundle: boolean?): string
	if bundle then
		return string.format("rbxthumb://type=BundleThumbnail&id=%d&w=150&h=150", id)
	end
	return string.format("rbxthumb://type=Asset&id=%d&w=150&h=150", id)
end

-- Look changes ------------------------------------------------------------------------------------

local refreshWorn: () -> ()

local function sendPreview()
	previewToken += 1
	local token = previewToken
	previewPending = true
	task.delay(0.3, function()
		if token ~= previewToken or not isOpen then
			return
		end
		local cleaned, removed = Remotes.fn("CreatorPreview"):InvokeServer(app)
		previewPending = false
		if token ~= previewToken then
			return
		end
		if cleaned and removed and #removed > 0 then
			app = Appearance.sanitize(cleaned)
			Toasts.show("Some of that can't be worn in that spot, so it came off.", "warn")
			refreshWorn()
		end
	end)
end

local function setApp(newApp: any, record: boolean?)
	if record ~= false then
		table.insert(history, app)
		if #history > 60 then
			table.remove(history, 1)
		end
		future = {}
	end
	app = Appearance.sanitize(newApp)
	sendPreview()
	refreshWorn()
end

local function undo()
	local prev = table.remove(history)
	if prev then
		table.insert(future, app)
		setApp(prev, false)
	end
end

local function redo()
	local nextApp = table.remove(future)
	if nextApp then
		table.insert(history, app)
		setApp(nextApp, false)
	end
end

-- Catalog search ----------------------------------------------------------------------------------

local function currentFilter(): any
	for _, t in Categories.Tabs do
		if t.id == tabId and t.filters then
			return t.filters[math.clamp(filterIndex, 1, #t.filters)]
		end
	end
	return nil
end

local function remember(items: { any })
	for _, item in items do
		local bundle = item.ItemType == "Bundle"
		itemInfo[item.Id] = {
			name = item.Name or "Item",
			type = if bundle then nil else Categories.assetTypeName(item.AssetType),
			bundle = bundle,
		}
	end
end

local function clearGrid()
	for _, c in grid:GetChildren() do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
end

local function wear(item: any)
	local id = item.Id
	if item.ItemType == "Bundle" then
		task.spawn(function()
			local part = Remotes.fn("CreatorBundle"):InvokeServer(id)
			if part then
				setApp(Categories.merge(app, part))
			else
				Toasts.show("Couldn't open that bundle just now.", "warn")
			end
		end)
		return
	end
	local typeName = Categories.assetTypeName(item.AssetType)
	if not typeName or not Categories.slotFor(typeName) then
		Toasts.show("That item can't be worn by villagers.", "warn")
		return
	end
	setApp(Categories.toggle(app, id, typeName))
end

local cards: { [number]: GuiObject } = {}

refreshWorn = function()
	for id, card in cards do
		local stroke = card:FindFirstChildOfClass("UIStroke")
		local worn = Categories.isWorn(app, id)
		if stroke then
			stroke.Color = if worn then T.Green else T.Ink
			stroke.Thickness = if worn then 3.5 else 2
		end
		local badge = card:FindFirstChild("Worn")
		if badge and badge:IsA("GuiObject") then
			badge.Visible = worn
		end
	end
end

local function itemCard(item: any, order: number, onClick: (() -> ())?): GuiObject
	local bundle = item.ItemType == "Bundle"
	local card = Kit.new("TextButton", {
		Text = "",
		AutoButtonColor = true,
		BackgroundColor3 = T.Paper,
		Size = UDim2.fromOffset(112, 140),
		LayoutOrder = order,
		Parent = grid,
	})
	Kit.corner(card, 12)
	Kit.stroke(card, T.Ink, 2)
	local picture = Kit.frame({
		Parent = card,
		Size = UDim2.fromOffset(102, 100),
		Position = UDim2.fromOffset(5, 5),
		Color = T.PaperDark,
		Radius = 10,
	})
	Kit.new("ImageLabel", {
		Image = thumb(item.Id, bundle),
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ScaleType = Enum.ScaleType.Fit,
		Parent = picture,
	})
	if bundle then
		local tag = Kit.frame({
			Parent = picture,
			Size = UDim2.fromOffset(0, 18),
			AutomaticSize = Enum.AutomaticSize.X,
			Position = UDim2.fromOffset(4, 4),
			Color = T.Purple,
			Radius = 9,
		})
		Kit.pad(tag, 6, 0)
		Kit.text("Set", {
			Parent = tag,
			Size = UDim2.fromOffset(0, 18),
			AutomaticSize = Enum.AutomaticSize.X,
			TextSize = 11,
			Font = Kit.Fonts.Bold,
			Color = T.White,
			Wrap = false,
		})
	end
	-- the green tick on what they have on
	local worn = Kit.frame({
		Name = "Worn",
		Parent = card,
		Size = UDim2.fromOffset(24, 24),
		Position = UDim2.new(1, -28, 0, 4),
		Color = T.Green,
		Radius = "circle",
		Visible = false,
	})
	Kit.stroke(worn, T.Ink, 2)
	Icons.make("check", 18, { Parent = worn, Position = UDim2.fromOffset(3, 3) })
	Kit.text(item.Name or "", {
		Parent = card,
		Size = UDim2.new(1, -8, 0, 30),
		Position = UDim2.fromOffset(4, 107),
		TextSize = 12,
		AlignX = Enum.TextXAlignment.Center,
		Font = Kit.Fonts.Bold,
	})
	card.Activated:Connect(function()
		if onClick then
			onClick()
		else
			wear(item)
		end
	end)
	cards[item.Id] = card
	return card
end

local function showItems(items: { any }, append: boolean?)
	if not append then
		clearGrid()
		cards = {}
	end
	remember(items)
	local n = #grid:GetChildren()
	for i, item in items do
		if type(item.Id) == "number" then
			itemCard(item, n + i)
		end
	end
	refreshWorn()
	loadMore.Visible = pages ~= nil and not pages.IsFinished
	if #items == 0 and not append then
		Kit.text(
			"Nothing found. Try another word.",
			{ Parent = grid, Size = UDim2.new(1, 0, 0, 30), TextSize = 17, Color = T.InkSoft }
		)
	end
end

local function buildParams(f: any): CatalogSearchParams
	local params = CatalogSearchParams.new()
	params.SearchKeyword = keyword
	if f.assets then
		local list = {}
		for _, name in f.assets do
			local e = (Enum.AvatarAssetType :: any)[name]
			if e then
				table.insert(list, e)
			end
		end
		params.AssetTypes = list
	end
	if f.bundles then
		local list = {}
		for _, name in f.bundles do
			local e = (Enum.BundleType :: any)[name]
			if e then
				table.insert(list, e)
			end
		end
		params.BundleTypes = list
	end
	local sort = (Enum.CatalogSortType :: any)[sortId]
	if sort then
		params.SortType = sort
	end
	params.Limit = 30
	return params
end

-- Searches the catalog: on the client first, through the server if that fails.
local function fetch(f: any): ({ any }, any)
	local ok, result = pcall(function()
		return AvatarEditorService:SearchCatalogAsync(buildParams(f))
	end)
	if ok and result then
		local okPage, page = pcall(function()
			return result:GetCurrentPage()
		end)
		if okPage then
			return page, result
		end
	end
	local items = Remotes.fn("CreatorSearch")
		:InvokeServer({ keyword = keyword, assets = f.assets, bundles = f.bundles, sort = sortId })
	return items or {}, nil
end

local function search()
	local f = currentFilter()
	if not f then
		return
	end
	searchToken += 1
	local token = searchToken
	clearGrid()
	cards = {}
	loadMore.Visible = false
	Kit.text(
		"Looking through the catalog...",
		{ Parent = grid, Size = UDim2.new(1, 0, 0, 30), TextSize = 17, Color = T.InkSoft }
	)
	task.spawn(function()
		local items, p = fetch(f)
		if token ~= searchToken or not isOpen then
			return
		end
		pages = p
		if keyword == "" then
			resultCache[f.id .. sortId] = items
		end
		showItems(items)
	end)
end

local function more()
	if not pages or pages.IsFinished then
		return
	end
	loadMore.Visible = false
	local token = searchToken
	task.spawn(function()
		local ok = pcall(function()
			pages:AdvanceToNextPageAsync()
		end)
		if not ok or token ~= searchToken then
			return
		end
		showItems(pages:GetCurrentPage(), true)
	end)
end

-- Picks a random outfit from popular items.
local function shuffle()
	task.spawn(function()
		local new = Appearance.sanitize(app)
		local picks = {
			{ filter = { id = "hair", assets = { "HairAccessory" } }, type = "HairAccessory" },
			{ filter = { id = "shirts", assets = { "Shirt" } }, type = "Shirt" },
			{ filter = { id = "pants", assets = { "Pants" } }, type = "Pants" },
			{ filter = { id = "faces", assets = { "Face" } }, type = "Face" },
		}
		local oldKeyword, oldSort = keyword, sortId
		keyword, sortId = "", "Bestselling"
		for _, p in picks do
			local cached = resultCache[p.filter.id .. "Bestselling"]
			if not cached then
				cached = fetch(p.filter)
				resultCache[p.filter.id .. "Bestselling"] = cached
			end
			if cached and #cached > 0 then
				local item = cached[math.random(1, #cached)]
				remember({ item })
				-- clear that slot first so a toggle always puts it on
				if p.type == "HairAccessory" then
					for i = #new.acc, 1, -1 do
						if new.acc[i].t == "Hair" then
							table.remove(new.acc, i)
						end
					end
				end
				if not Categories.isWorn(new, item.Id) then
					new = Categories.toggle(new, item.Id, p.type)
				end
			end
		end
		keyword, sortId = oldKeyword, oldSort
		local skin = Appearance.SkinTones[math.random(1, 10)]
		for _, k in { "head", "la", "ra", "ll", "rl", "torso" } do
			new.colors[k] = skin
		end
		new.scale.height = math.random(90, 110) / 100
		new.scale.width = math.random(80, 100) / 100
		setApp(new)
	end)
end

-- Special pages --------------------------------------------------------------------------------------

local function clearContent()
	for _, c in content:GetChildren() do
		if c ~= grid and c ~= loadMore and c:IsA("GuiObject") then
			c:Destroy()
		end
	end
	grid.Visible = false
	loadMore.Visible = false
end

local function wearingPage()
	grid.Visible = true
	clearGrid()
	cards = {}
	local assets = Appearance.assets(app)
	if #assets == 0 then
		Kit.text(
			"Nothing on yet. Pick something from the other tabs.",
			{ Parent = grid, Size = UDim2.new(1, 0, 0, 30), TextSize = 17, Color = T.InkSoft }
		)
		return
	end
	local unknown = {}
	for i, a in assets do
		local info = itemInfo[a.id]
		if not info then
			table.insert(unknown, a.id)
		end
		itemCard({ Id = a.id, Name = if info then info.name else "Worn item", ItemType = "Asset" }, i, function()
			setApp(Appearance.without(app, a.id))
			task.defer(wearingPage)
		end)
	end
	if #unknown > 0 then
		task.spawn(function()
			local infos = Remotes.fn("CreatorItemInfo"):InvokeServer(unknown)
			if type(infos) == "table" then
				for id, info in infos do
					itemInfo[tonumber(id) :: number] = { name = info.name, type = info.type }
				end
				if isOpen and tabId == "wearing" then
					wearingPage()
				end
			end
		end)
	end
	Kit.text("Click something to take it off.", {
		Parent = content,
		Size = UDim2.new(1, 0, 0, 22),
		Position = UDim2.new(0, 0, 1, -22),
		TextSize = 15,
		Color = T.InkSoft,
	})
end

local SKIN_PARTS = {
	{ id = "all", name = "Everything", keys = { "head", "torso", "la", "ra", "ll", "rl" } },
	{ id = "head", name = "Head", keys = { "head" } },
	{ id = "torso", name = "Body", keys = { "torso" } },
	{ id = "arms", name = "Arms", keys = { "la", "ra" } },
	{ id = "legs", name = "Legs", keys = { "ll", "rl" } },
}

local function skinPage()
	local holder = Kit.box({ Parent = content, Size = UDim2.fromScale(1, 1) })
	Kit.list(holder, 8)
	local part = SKIN_PARTS[1]
	local _, selectPart = Kit.tabs(SKIN_PARTS, function(id)
		for _, p in SKIN_PARTS do
			if p.id == id then
				part = p
			end
		end
	end, { Parent = holder, LayoutOrder = 1 })
	selectPart("all")
	Kit.text("Skin tones", { Parent = holder, TextSize = 16, Font = Kit.Fonts.Bold, LayoutOrder = 2 })
	local function swatches(list: { string }, order: number)
		local g = Kit.box({
			Parent = holder,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			LayoutOrder = order,
		})
		Kit.grid(g, UDim2.fromOffset(36, 36), 6)
		for i, hex in list do
			Kit.swatch(Colors.fromHex(hex), 36, function()
				local new = Appearance.sanitize(app)
				for _, k in part.keys do
					new.colors[k] = hex
				end
				setApp(new)
			end, { Parent = g, LayoutOrder = i })
		end
	end
	swatches(Appearance.SkinTones, 3)
	Kit.text("Any colour", { Parent = holder, TextSize = 16, Font = Kit.Fonts.Bold, LayoutOrder = 4 })
	swatches(Palette.Colors, 5)
end

local function shapePage()
	local holder = Kit.box({ Parent = content, Size = UDim2.fromScale(1, 1) })
	Kit.list(holder, 10)
	local names = {
		height = "Height",
		width = "Width",
		head = "Head size",
		depth = "Depth",
		bodyType = "Body type",
		proportion = "Proportions",
	}
	for i, k in Appearance.ScaleKeys do
		local lim = Appearance.ScaleLimits[k]
		Kit.slider(names[k], lim.Min, lim.Max, app.scale[k], 0.01, function(v)
			-- record one undo step per drag, not per pixel
			local new = Appearance.sanitize(app)
			new.scale[k] = v
			app = new
			sendPreview()
		end, { Parent = holder, LayoutOrder = i })
	end
	Kit.button(
		"Back to normal",
		{ Parent = holder, Size = UDim2.fromOffset(180, 40), Color = T.Yellow, TextColor = T.Ink, LayoutOrder = 20 },
		function()
			local new = Appearance.sanitize(app)
			for _, k in Appearance.ScaleKeys do
				new.scale[k] = Appearance.ScaleLimits[k].Default
			end
			setApp(new)
			selectTab("shape")
		end
	)
end

local function outfitsPage()
	local holder = Kit.box({ Parent = content, Size = UDim2.fromScale(1, 1) })
	local row = Kit.box({ Parent = holder, Size = UDim2.new(1, 0, 0, 44) })
	Kit.list(row, 8, true)
	local nameBox = Kit.textbox("Outfit name", { Parent = row, Size = UDim2.new(1, -170, 0, 40) })
	Kit.button(
		"Save this look",
		{ Parent = row, Size = UDim2.fromOffset(160, 40), Color = T.Green, TextSize = 17 },
		function()
			local name = Text.clean(nameBox.Text)
			if name == "" then
				name = "Outfit " .. (#(State.data.outfits or {}) + 1)
			end
			task.spawn(function()
				local ok, err = Remotes.fn("OutfitSave"):InvokeServer(name, app)
				if ok then
					Toasts.show("Outfit saved.", "good")
					task.wait(0.4)
					if isOpen and tabId == "outfits" then
						selectTab("outfits")
					end
				elseif err then
					Toasts.show(err, "warn")
				end
			end)
		end
	)
	local list = Kit.scroll({ Parent = holder, Size = UDim2.new(1, 0, 1, -54), Position = UDim2.fromOffset(0, 54) })
	Kit.list(list, 6)
	local outfits = State.data.outfits or {}
	if #outfits == 0 then
		Kit.text("No saved outfits yet.", { Parent = list, TextSize = 17, Color = T.InkSoft })
	end
	for i, o in outfits do
		local r = Kit.frame({
			Parent = list,
			Size = UDim2.new(1, -8, 0, 48),
			Color = T.White,
			Stroke = T.Ink,
			StrokeThickness = 2,
			LayoutOrder = i,
		})
		Kit.pad(r, 10, 4)
		Kit.text(o.name, { Parent = r, Size = UDim2.new(1, -200, 1, 0), TextSize = 18, Font = Kit.Fonts.Bold })
		Kit.button("Wear", {
			Parent = r,
			Size = UDim2.fromOffset(84, 36),
			Position = UDim2.new(1, -184, 0, 2),
			Color = T.Blue,
			TextSize = 16,
		}, function()
			setApp(o.app)
		end)
		Kit.button("Delete", {
			Parent = r,
			Size = UDim2.fromOffset(90, 36),
			Position = UDim2.new(1, -92, 0, 2),
			Color = T.Coral,
			TextSize = 16,
		}, function()
			task.spawn(function()
				Remotes.fn("OutfitDelete"):InvokeServer(i)
				task.wait(0.3)
				if isOpen and tabId == "outfits" then
					selectTab("outfits")
				end
			end)
		end)
	end
end

local function showFilters(tab: any)
	for _, c in filterRow:GetChildren() do
		if c:IsA("GuiButton") then
			c:Destroy()
		end
	end
	local filters = tab and tab.filters
	filterRow.Visible = filters ~= nil and #filters > 1
	searchBox.Visible = filters ~= nil
	sortButton.Visible = filters ~= nil
	if not filters then
		return
	end
	for i, f in filters do
		local on = i == filterIndex
		local b = Kit.button(f.name, {
			Parent = filterRow,
			Size = UDim2.fromOffset(0, 30),
			AutomaticSize = Enum.AutomaticSize.X,
			TextSize = 14,
			Color = if on then T.Ink else T.PaperDark,
			TextColor = if on then T.White else T.Ink,
			LayoutOrder = i,
			Radius = 15,
		})
		Kit.pad(b, 12, 0)
		b.Activated:Connect(function()
			filterIndex = i
			showFilters(tab)
			search()
		end)
	end
end

selectTab = function(id: string)
	tabId = id
	if markTab then
		markTab(id)
	end
	local tab
	for _, t in Categories.Tabs do
		if t.id == id then
			tab = t
		end
	end
	clearContent()
	showFilters(tab)
	if tab and tab.filters then
		grid.Visible = true
		search()
	elseif id == "wearing" then
		wearingPage()
	elseif id == "skin" then
		skinPage()
	elseif id == "shape" then
		shapePage()
	elseif id == "outfits" then
		outfitsPage()
	end
end

-- Profile page ---------------------------------------------------------------------------------------

local function buildProfilePage()
	for _, c in profilePage:GetChildren() do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
	local scroll = Kit.scroll({ Parent = profilePage, Size = UDim2.new(1, 0, 1, -60) })
	Kit.list(scroll, 10)
	Kit.text("Name", { Parent = scroll, TextSize = 17, Font = Kit.Fonts.Bold, LayoutOrder = 1 })
	local nameBox = Kit.textbox(
		"What are they called?",
		{ Parent = scroll, Text = profile.name, LayoutOrder = 2, Size = UDim2.new(1, -10, 0, 42) }
	)
	nameBox:GetPropertyChangedSignal("Text"):Connect(function()
		if utf8.len(nameBox.Text) and (utf8.len(nameBox.Text) :: number) > Tuning.Villagers.NameMaxLength then
			nameBox.Text = nameBox.Text:sub(1, Tuning.Villagers.NameMaxLength)
		end
		profile.name = nameBox.Text
	end)
	Kit.text("Personality", { Parent = scroll, TextSize = 17, Font = Kit.Fonts.Bold, LayoutOrder = 3 })
	local persGrid = Kit.box({
		Parent = scroll,
		Size = UDim2.new(1, -10, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = 4,
	})
	Kit.grid(persGrid, UDim2.new(0.5, -6, 0, 70), 8)
	local persButtons = {}
	local function refreshPers()
		for id, b in persButtons do
			local p = Personalities.get(id) :: any
			Kit.setButtonColor(b, if id == profile.pers then Colors.fromHex(p.color) else T.White)
		end
	end
	for i, p in Personalities.list do
		local b = Kit.new(
			"TextButton",
			{ Text = "", AutoButtonColor = true, BackgroundColor3 = T.White, LayoutOrder = i, Parent = persGrid }
		)
		Kit.corner(b, 12)
		Kit.stroke(b, T.Ink, 2)
		Kit.title(
			p.name,
			{ Parent = b, Size = UDim2.new(1, -16, 0, 24), Position = UDim2.fromOffset(8, 4), TextSize = 18 }
		)
		Kit.text(p.blurb, {
			Parent = b,
			Size = UDim2.new(1, -16, 0, 38),
			Position = UDim2.fromOffset(8, 28),
			TextSize = 13,
			AlignY = Enum.TextYAlignment.Top,
		})
		persButtons[p.id] = b
		b.Activated:Connect(function()
			profile.pers = p.id
			refreshPers()
		end)
	end
	refreshPers()
	Kit.text("Favourite colour", { Parent = scroll, TextSize = 17, Font = Kit.Fonts.Bold, LayoutOrder = 5 })
	local colorGrid = Kit.box({
		Parent = scroll,
		Size = UDim2.new(1, -10, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = 6,
	})
	Kit.grid(colorGrid, UDim2.fromOffset(30, 30), 6)
	for i, hex in Palette.Colors do
		Kit.swatch(Colors.fromHex(hex), 30, function()
			profile.color = hex
		end, { Parent = colorGrid, LayoutOrder = i })
	end
	Kit.text("Birthday", { Parent = scroll, TextSize = 17, Font = Kit.Fonts.Bold, LayoutOrder = 7 })
	local seasons = {}
	for i, name in Schema.Seasons do
		table.insert(seasons, { id = tostring(i), name = name })
	end
	local _, selectSeason = Kit.tabs(seasons, function(id)
		profile.bday.s = tonumber(id) :: number
	end, { Parent = scroll, LayoutOrder = 8, Size = UDim2.new(1, -10, 0, 40) })
	selectSeason(tostring(profile.bday.s))
	Kit.slider("Day", 1, Schema.DaysPerSeason, profile.bday.d, 1, function(v)
		profile.bday.d = v
	end, { Parent = scroll, LayoutOrder = 9, Size = UDim2.new(1, -10, 0, 46) })

	local save = Kit.button(if mode == "new" then "Move them in" else "Save changes", {
		Parent = profilePage,
		Size = UDim2.new(1, 0, 0, 50),
		Position = UDim2.new(0, 0, 1, -52),
		Color = T.Green,
		TextSize = 22,
	})
	save.Activated:Connect(function()
		if saving then
			return
		end
		local name = Text.clean(profile.name)
		if name == "" then
			Toasts.show("Give them a name first.", "warn")
			return
		end
		save.Text = "Checking..."
		saving = true
		task.spawn(function()
			local ok, err
			if mode == "new" then
				ok, err = Remotes.fn("VillagerCreate"):InvokeServer({
					name = name,
					pers = profile.pers,
					color = profile.color,
					bday = profile.bday,
					app = app,
				})
			else
				ok, err = Remotes.fn("VillagerUpdate"):InvokeServer(
					editVid,
					{ name = name, pers = profile.pers, color = profile.color, bday = profile.bday, app = app }
				)
			end
			saving = false
			if ok then
				Toasts.show(
					if mode == "new" then Text.fill("{name} is moving in!", { name = name }) else "Saved.",
					"good"
				)
				Creator.close()
			else
				save.Text = if mode == "new" then "Move them in" else "Save changes"
				Toasts.show(err or "That didn't work.", "warn")
			end
		end)
	end)
end

local function showStep(step: string)
	lookPage.Visible = step == "look"
	profilePage.Visible = step == "profile"
	for id, b in stepButtons do
		Kit.setButtonColor(b, if id == step then T.Blue else T.PaperDark, if id == step then T.White else T.Ink)
	end
	if step == "profile" then
		buildProfilePage()
	end
end

-- Camera -----------------------------------------------------------------------------------------------

local function stopCamera()
	if camConn then
		camConn:Disconnect()
		camConn = nil
	end
	for _, c in inputConns do
		c:Disconnect()
	end
	inputConns = {}
	local cam = workspace.CurrentCamera
	cam.CameraType = Enum.CameraType.Custom
	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if hum then
		cam.CameraSubject = hum
	end
end

local function startCamera()
	-- never run two camera loops at once
	if camConn then
		camConn:Disconnect()
		camConn = nil
	end
	for _, c in inputConns do
		c:Disconnect()
	end
	inputConns = {}
	local cam = workspace.CurrentCamera
	cam.CameraType = Enum.CameraType.Scriptable
	local dragging = false
	local last: Vector2? = nil
	camConn = RunService.RenderStepped:Connect(function()
		-- the mannequin stands at the origin; the camera sits to the left so the panel doesn't cover it
		local center = origin + Vector3.new(0, focusY, 0)
		local dir = Vector3.new(math.sin(yaw), 0.18, math.cos(yaw)).Unit
		local right = Vector3.new(math.cos(yaw), 0, -math.sin(yaw))
		local eye = center + dir * zoom
		cam.CFrame = CFrame.lookAt(eye, center) * CFrame.new(zoom * 0.32, 0, 0)
		local _ = right
	end)
	table.insert(
		inputConns,
		UserInputService.InputBegan:Connect(function(input, processed)
			if processed then
				return
			end
			if
				input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.MouseButton2
				or input.UserInputType == Enum.UserInputType.Touch
			then
				if not Kit.overUI(Vector2.new(input.Position.X, input.Position.Y + Kit.topInset())) then
					dragging = true
					last = Vector2.new(input.Position.X, input.Position.Y)
				end
			end
		end)
	)
	table.insert(
		inputConns,
		UserInputService.InputEnded:Connect(function(input)
			if
				input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.MouseButton2
				or input.UserInputType == Enum.UserInputType.Touch
			then
				dragging = false
			end
		end)
	)
	table.insert(
		inputConns,
		UserInputService.InputChanged:Connect(function(input, processed)
			if
				dragging
				and last
				and (
					input.UserInputType == Enum.UserInputType.MouseMovement
					or input.UserInputType == Enum.UserInputType.Touch
				)
			then
				local p = Vector2.new(input.Position.X, input.Position.Y)
				yaw -= (p - last).X * 0.01
				last = p
			elseif input.UserInputType == Enum.UserInputType.MouseWheel and not processed then
				zoom = math.clamp(zoom * (if input.Position.Z > 0 then 0.9 else 1.1), 4, 18)
			end
		end)
	)
end

-- Building the screen ------------------------------------------------------------------------------------

-- The title ribbon is cut to the length of its words, so a new title makes a new ribbon.
local function setTitle(text: string)
	if titleRibbon then
		titleRibbon:Destroy()
	end
	titleRibbon = Kit.ribbon(text, {
		Parent = titleHolder,
		Color = T.Pink,
		TextSize = 28,
		Position = UDim2.new(0.5, 0, 0, 0),
		AnchorPoint = Vector2.new(0.5, 0),
		ZIndex = 3,
	})
	if Icons.has("shirt") and titleRibbon then
		Icons.make("shirt", 50, { Parent = titleRibbon, Position = UDim2.fromOffset(-10, -12), ZIndex = 6 })
	end
end

local function build()
	local gui = Kit.root()
	local frame = Kit.box({ Name = "Creator", Size = UDim2.fromScale(1, 1), Parent = gui })
	frame.ZIndex = 10
	root = frame

	-- the portrait frame round the stage, where the villager stands in the 3D view: a cream mat
	-- with an outline inside and out (each stroke sits just outside its frame)
	local stage = Kit.box({
		Name = "Stage",
		Size = UDim2.new(1, -(660 + 24 + 44), 1, -(60 + 196)),
		Position = UDim2.fromOffset(28, 66),
		Parent = frame,
	})
	local inkIn = Kit.frame({ Name = "InkIn", Size = UDim2.fromScale(1, 1), Transparency = 1, Parent = stage })
	Kit.stroke(inkIn, T.Ink, 2.5)
	local mat = Kit.frame({
		Name = "Mat",
		Size = UDim2.new(1, 5, 1, 5),
		Position = UDim2.fromOffset(-2.5, -2.5),
		Transparency = 1,
		Parent = stage,
	})
	Kit.stroke(mat, T.Paper, 12)
	local inkOut = Kit.frame({
		Name = "InkOut",
		Size = UDim2.new(1, 29, 1, 29),
		Position = UDim2.fromOffset(-14.5, -14.5),
		Transparency = 1,
		Parent = stage,
	})
	Kit.stroke(inkOut, T.Ink, 3)

	local holder = Kit.box({
		Name = "PanelHolder",
		Size = UDim2.new(0, 660, 1, -48),
		Position = UDim2.new(1, -16, 0, 34),
		AnchorPoint = Vector2.new(1, 0),
		Parent = frame,
	})
	Kit.frame({
		Name = "Shadow",
		Size = UDim2.fromScale(1, 1),
		Position = UDim2.fromOffset(7, 8),
		Color = T.Shadow,
		Transparency = 0.5,
		Parent = holder,
	})
	local panel = Kit.frame({
		Name = "Panel",
		Size = UDim2.fromScale(1, 1),
		Color = T.Paper,
		Stroke = T.Ink,
		StrokeThickness = 4,
		Parent = holder,
	})
	-- a pink band along the top edge with the title on a ribbon across it
	local header = Kit.frame({ Name = "Header", Parent = panel, Size = UDim2.new(1, 0, 0, 14), Color = T.Pink })
	Kit.frame({
		Parent = header,
		Size = UDim2.new(1, 0, 0, 3),
		Position = UDim2.new(0, 0, 1, 0),
		Color = T.Ink,
	})
	titleHolder = Kit.box({
		Name = "Title",
		Parent = panel,
		Size = UDim2.new(1, 0, 0, 10),
		Position = UDim2.fromOffset(0, -26),
	})
	titleHolder.ZIndex = 3
	setTitle("Make a villager")
	local inner = Kit.box({ Parent = panel, Size = UDim2.new(1, -28, 1, -70), Position = UDim2.fromOffset(14, 52) })
	Kit.closeButton({
		Parent = panel,
		Size = UDim2.fromOffset(50, 50),
		Position = UDim2.new(1, 12, 0, -12),
		AnchorPoint = Vector2.new(1, 0),
		ZIndex = 3,
	}, function()
		Creator.close()
	end)
	panel = inner
	-- the two steps as one segmented control
	local steps = Kit.frame({
		Parent = panel,
		Size = UDim2.new(1, 0, 0, 48),
		Position = UDim2.fromOffset(0, 0),
		Color = T.PaperDark,
		Stroke = T.Ink,
		StrokeThickness = 2,
	})
	Kit.pad(steps, 4, 4)
	Kit.list(steps, 4, true)
	stepButtons.look = Kit.button(
		"1  Look",
		{ Parent = steps, Size = UDim2.new(0.5, -2, 1, 0), TextSize = 18, Radius = 14, Icon = "shirt" },
		function()
			showStep("look")
		end
	)
	stepButtons.profile = Kit.button(
		"2  Name and personality",
		{ Parent = steps, Size = UDim2.new(0.5, -2, 1, 0), TextSize = 18, Radius = 14, Icon = "person" },
		function()
			showStep("profile")
		end
	)

	lookPage = Kit.box({ Parent = panel, Size = UDim2.new(1, 0, 1, -58), Position = UDim2.fromOffset(0, 58) })
	profilePage =
		Kit.box({ Parent = panel, Size = UDim2.new(1, 0, 1, -58), Position = UDim2.fromOffset(0, 58), Visible = false })

	-- categories down the left, as icon tiles
	local ICONS = {
		wearing = "person",
		hair = "hair",
		heads = "smile",
		accessories = "hat",
		tops = "shirt",
		bottoms = "pants",
		shoes = "shoe",
		bodies = "person",
		moves = "music",
		skin = "brush",
		shape = "ruler",
		outfits = "shirt",
	}
	local rail = Kit.scroll({ Parent = lookPage, Size = UDim2.new(0, 78, 1, 0) })
	rail.ScrollBarThickness = 0
	Kit.list(rail, 6, false, Enum.HorizontalAlignment.Center)
	local railButtons: { [string]: TextButton } = {}
	local function markRail(id: string)
		for bid, b in railButtons do
			local on = bid == id
			Kit.setButtonColor(b, if on then T.Blue else T.Paper, if on then T.White else T.Ink)
		end
	end
	for i, t in Categories.Tabs do
		railButtons[t.id] = Kit.iconButton(
			ICONS[t.id] or "•",
			t.name,
			{ Parent = rail, Size = UDim2.fromOffset(70, 64), LayoutOrder = i, Radius = 12, TextSize = 12 },
			function()
				filterIndex = 1
				markRail(t.id)
				selectTab(t.id)
			end
		)
	end
	markRail(tabId)
	markTab = markRail
	local browse = Kit.box({ Parent = lookPage, Size = UDim2.new(1, -88, 1, 0), Position = UDim2.fromOffset(88, 0) })

	local searchRow = Kit.box({ Parent = browse, Size = UDim2.new(1, 0, 0, 40) })
	searchBox = Kit.textbox("Search the catalog", { Parent = searchRow, Size = UDim2.new(1, -150, 1, 0) })
	searchBox.FocusLost:Connect(function(enter)
		keyword = Text.clean(searchBox.Text):sub(1, 50)
		if enter or true then
			search()
		end
	end)
	sortButton = Kit.button("Best match", {
		Parent = searchRow,
		Size = UDim2.fromOffset(140, 40),
		Position = UDim2.new(1, -140, 0, 0),
		Color = T.Yellow,
		TextColor = T.Ink,
		TextSize = 16,
	})
	sortButton.Activated:Connect(function()
		local i = 1
		for k, s in Categories.Sorts do
			if s.id == sortId then
				i = k
			end
		end
		local nextSort = Categories.Sorts[i % #Categories.Sorts + 1]
		sortId = nextSort.id
		sortButton.Text = nextSort.name
		search()
	end)
	filterRow = Kit.scroll({
		Parent = browse,
		Size = UDim2.new(1, 0, 0, 34),
		Position = UDim2.fromOffset(0, 46),
		Axis = Enum.AutomaticSize.X,
	})
	filterRow.ScrollBarThickness = 3
	Kit.list(filterRow, 6, true)

	content = Kit.box({ Parent = browse, Size = UDim2.new(1, 0, 1, -88), Position = UDim2.fromOffset(0, 86) })
	grid = Kit.scroll({ Parent = content, Size = UDim2.new(1, 0, 1, -46) })
	Kit.grid(grid, UDim2.fromOffset(112, 140), 8)
	loadMore = Kit.button("Show more", {
		Parent = content,
		Size = UDim2.new(1, 0, 0, 40),
		Position = UDim2.new(0, 0, 1, -40),
		Color = T.Blue,
		TextSize = 17,
	}, more)

	-- the tools over the 3D view
	local tools = Kit.glass({
		Name = "Tools",
		Size = UDim2.fromOffset(0, 76),
		AutomaticSize = Enum.AutomaticSize.X,
		Position = UDim2.new(0, 12, 1, -12),
		AnchorPoint = Vector2.new(0, 1),
		Parent = frame,
	})
	Kit.pad(tools, 8, 8)
	Kit.list(tools, 6, true)
	local function tool(icon: string, label: string, fn: () -> (), order: number)
		Kit.iconButton(
			icon,
			label,
			{ Parent = tools, Size = UDim2.fromOffset(64, 60), LayoutOrder = order, Radius = 12, TextSize = 12 },
			fn
		)
	end
	tool("undo", "Undo", undo, 1)
	tool("redo", "Redo", redo, 2)
	tool("dice", "Shuffle", shuffle, 3)
	tool("trash", "Reset", function()
		setApp(Appearance.default())
	end, 4)
	tool("smile", "Face", function()
		if zoom > 6 then
			zoom, focusY = 4.5, 4.2
		else
			zoom, focusY = 11, 2.8
		end
	end, 5)

	local copy = Kit.frame({
		Name = "Copy",
		Size = UDim2.fromOffset(420, 60),
		Position = UDim2.new(0, 12, 1, -98),
		AnchorPoint = Vector2.new(0, 1),
		Color = T.Paper,
		Stroke = T.Ink,
		StrokeThickness = 3,
		Parent = frame,
	})
	Kit.pad(copy, 8, 8)
	local userBox = Kit.textbox("Copy a Roblox username", { Parent = copy, Size = UDim2.new(1, -196, 1, 0) })
	Kit.button("Copy", {
		Parent = copy,
		Size = UDim2.fromOffset(84, 44),
		Position = UDim2.new(1, -188, 0, 0),
		Color = T.Blue,
		TextSize = 16,
	}, function()
		local name = Text.clean(userBox.Text)
		if name == "" then
			return
		end
		task.spawn(function()
			local result, err = Remotes.fn("CreatorFromUser"):InvokeServer(name)
			if result then
				setApp(result)
			else
				Toasts.show(err or "Couldn't copy that avatar.", "warn")
			end
		end)
	end)
	Kit.button("Me", {
		Parent = copy,
		Size = UDim2.fromOffset(96, 44),
		Position = UDim2.new(1, -96, 0, 0),
		Color = T.Green,
		TextSize = 16,
	}, function()
		task.spawn(function()
			local result = Remotes.fn("CreatorFromUser"):InvokeServer("")
			if result then
				setApp(result)
			end
		end)
	end)
	local tip = Kit.glass({
		Parent = frame,
		Size = UDim2.fromOffset(0, 32),
		AutomaticSize = Enum.AutomaticSize.X,
		Position = UDim2.fromOffset(12, 12),
	})
	Kit.pad(tip, 14, 0)
	Kit.text("Drag to turn them round. Scroll to zoom.", {
		Parent = tip,
		Size = UDim2.fromOffset(0, 30),
		AutomaticSize = Enum.AutomaticSize.X,
		TextSize = 15,
		Color = T.White,
		Font = Kit.Fonts.Bold,
		Wrap = false,
	})
end

-- Opening and closing -----------------------------------------------------------------------------------

function Creator.isOpen(): boolean
	return isOpen
end

-- arg: { mode = "new" | "edit", vid?, start? = "me" }
function Creator.open(arg: any)
	if isOpen then
		Creator.close()
	end
	local a = arg or {}
	mode = if a.mode == "edit" then "edit" else "new"
	editVid = a.vid
	if mode == "new" and #(State.data.order or {}) >= Tuning.Villagers.Max then
		Toasts.show(Text.fill("Your town is full ({n} villagers).", { n = Tuning.Villagers.Max }), "warn")
		return
	end
	isOpen = true
	history, future = {}, {}
	if not root then
		build()
	end
	local r = root :: Frame
	r.Visible = true
	local v = editVid and State.villager(editVid)
	if mode == "edit" and v then
		setTitle(Text.fill("{name}'s look", { name = v.name }))
		profile = { name = v.name, pers = v.pers, color = v.color, bday = table.clone(v.bday) }
	else
		setTitle("Make a villager")
		profile = {
			name = if a.start == "me" then player.DisplayName else "",
			pers = "sunny",
			color = "4FA9D9",
			bday = { s = 1, d = 1 },
		}
	end
	showStep("look")
	selectTab(tabId)
	openToken += 1
	local token = openToken
	task.spawn(function()
		local stage = Remotes.fn("CreatorOpen")
			:InvokeServer(if mode == "edit" then editVid elseif a.start == "me" then "me" else nil)
		if not stage or not isOpen or token ~= openToken then
			return
		end
		origin = stage.origin
		app = Appearance.sanitize(stage.app)
		refreshWorn()
		startCamera()
	end)
end

function Creator.close()
	if not isOpen then
		return
	end
	isOpen = false
	searchToken += 1
	previewToken += 1
	if root then
		root.Visible = false
	end
	stopCamera()
	task.spawn(function()
		Remotes.fn("CreatorClose"):InvokeServer()
	end)
	local _ = previewPending
end

return Creator
