-- The villager creator. Works like a catalog avatar editor: browse or search the whole Roblox
-- catalog by category, click to wear or take off, mix bundles (bodies, heads, animations, shoes)
-- and single body parts, wear what you own on Roblox or an avatar you saved there, set skin
-- colours and body shape, copy any player's avatar, save outfits, undo and redo.
-- The look is shown on a mannequin on a private stage; then you give them a name and a personality.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
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
local Theme = require(script.Parent.Theme)
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
-- How far the camera stands off, in studs, through a long lens (FOV). At ZOOM_HOME they fill the
-- screen from the knees up (the user: "zoom in more in the character creation screen. players
-- can also zoom out"); ZOOM_FACE is a close look at the head, ZOOM_WHOLE the whole of them.
local FOV = 40
local ZOOM_FACE, ZOOM_HOME, ZOOM_WHOLE = 3.1, 7.2, 12.5
local ZOOM_MIN, ZOOM_MAX = 2.6, 20
local zoom = ZOOM_HOME
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
-- turns a later page of `pages` into rows for cards, where a page isn't catalog results already
local pageRows: ((any) -> { any })? = nil
local searchToken = 0
local itemInfo: { [number]: { name: string, type: string?, bundle: boolean? } } = {}
local resultCache: { [string]: { any } } = {}
-- May this game see what the player owns on Roblox and the avatars they saved there? Roblox asks
-- them, once a session, when they press the button on My items or My avatars:
-- "unasked", "asking", "yes", "no", or "failed" (the question couldn't be put).
local access = "unasked"
local accessConn: RBXScriptConnection? = nil
-- the looks of the saved avatars that have been worn, so their cards can show a tick
local outfitLooks: { [number]: any } = {}

-- ui pieces filled in by build()
local grid: ScrollingFrame
local content: Frame
local filterRow: ScrollingFrame
local searchRow: Frame
local searchBox: TextBox
local sortButton: TextButton
local loadMore: TextButton
local lookPage: Frame
local profilePage: Frame
local stepButtons: { [string]: TextButton } = {}
local titleLabel: TextLabel? = nil
local selectTab: (string) -> ()
local markTab: ((string) -> ())? = nil
local profile = { name = "", pers = "sunny", color = "4FA9D9", bday = { s = 1, d = 1 } }
local paintStudio: () -> ()
local panelFrame: Frame? = nil -- the panel on the right, which glows in their favourite colour
local PANEL_W, PANEL_PAD = 720, 12 -- what the panel holds is this wide, inside this margin
local ROW_H = 36 -- the search box, the sort, the filters and the copy box are this tall

-- The picture of a card's item: an asset, a bundle, or one of the player's saved avatars.
local function thumb(id: number, itemType: string?): string
	if itemType == "Bundle" then
		return string.format("rbxthumb://type=BundleThumbnail&id=%d&w=150&h=150", id)
	elseif itemType == "Outfit" then
		return string.format("rbxthumb://type=Outfit&id=%d&w=150&h=150", id)
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

local function currentTab(): any
	return Categories.tab(tabId)
end

local function currentFilter(): any
	local t = currentTab()
	if t and t.filters then
		return t.filters[math.clamp(filterIndex, 1, #t.filters)]
	end
	return nil
end

local function remember(items: { any })
	for _, item in items do
		if type(item.Id) == "number" and item.ItemType ~= "Outfit" then
			local bundle = item.ItemType == "Bundle"
			itemInfo[item.Id] = {
				name = item.Name or "Item",
				type = if bundle then nil else Categories.assetTypeName(item.AssetType),
				bundle = bundle,
			}
		end
	end
end

local function clearGrid()
	for _, c in grid:GetChildren() do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
end

-- One line over the cards, for when there are none: what is being fetched, that nothing was
-- found, or that it went wrong (with a button to try again). No text takes it away.
local function note(text: string?, buttonText: string?, onClick: (() -> ())?)
	local old = content:FindFirstChild("Note")
	if old then
		old:Destroy()
	end
	if not text then
		return
	end
	-- on a rounded card of its own on the panel, in a thin rim
	local holder = Kit.frame({
		Name = "Note",
		Parent = content,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Color = T.Card,
		Radius = 12,
	})
	Kit.rim(holder, T.Line, 1)
	Kit.pad(holder, 16, 14)
	Kit.list(holder, 10)
	Kit.text(text, {
		Parent = holder,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		TextSize = 17,
		LayoutOrder = 1,
	})
	if buttonText and onClick then
		Kit.button(
			buttonText,
			{ Parent = holder, Size = UDim2.fromOffset(220, 42), Color = T.Blue, TextSize = 17, LayoutOrder = 2 },
			onClick
		)
	end
end

-- What each bundle sets, once it has been looked up: this is how a bundle's card knows it is
-- being worn, and how clicking it again takes it off. A bundle is looked up as what its tab is
-- for (a whole body, a head, shoes, animations), so the answer is kept under both.
local bundleParts: { [string]: any } = {}

local function bundleKey(id: number, kind: string?): string
	return (kind or "") .. ":" .. string.format("%d", id)
end

local function wear(item: any, kind: string?)
	local id = item.Id
	if item.ItemType == "Bundle" then
		local key = bundleKey(id, kind)
		local known = bundleParts[key]
		if known and Categories.bundleWorn(app, known) then
			setApp(Categories.unmerge(app, known))
			return
		end
		task.spawn(function()
			local part = known or Remotes.fn("CreatorBundle"):InvokeServer(id, kind)
			if part then
				bundleParts[key] = part
				setApp(Categories.merge(app, part))
			else
				Toasts.show("Couldn't open that bundle just now.", "warn")
			end
		end)
		return
	end
	if item.ItemType == "Outfit" then
		-- one of the player's saved avatars: the whole look goes on (Undo brings the old one back)
		task.spawn(function()
			local look = outfitLooks[id] or Remotes.fn("CreatorFromOutfit"):InvokeServer(id)
			if not look then
				Toasts.show("Couldn't load that avatar just now.", "warn")
				return
			end
			look = Appearance.sanitize(look)
			outfitLooks[id] = look
			if not Appearance.equal(app, look) then
				setApp(look)
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

-- the cards on show, and what each one is (its item, and the kind its bundle is worn as)
local cards: { [number]: GuiObject } = {}
local cardItems: { [number]: { item: any, kind: string? } } = {}

local function forgetCards()
	cards = {}
	cardItems = {}
end

local function isOn(id: number): boolean
	local c = cardItems[id]
	if c and c.item.ItemType == "Bundle" then
		local part = bundleParts[bundleKey(id, c.kind)]
		return part ~= nil and Categories.bundleWorn(app, part)
	elseif c and c.item.ItemType == "Outfit" then
		return outfitLooks[id] ~= nil and Appearance.equal(app, outfitLooks[id])
	end
	return Categories.isWorn(app, id)
end

-- What they have on is picked, so its card is yellow with dark words and a tick on its corner
-- (on Wearing everything is on, so there only the tick shows).
refreshWorn = function()
	for id, card in cards do
		local worn = isOn(id)
		local lit = worn and tabId ~= "wearing"
		local face = card:FindFirstChild("Face")
		if face and face:IsA("Frame") then
			Kit.paint(face, if lit then T.Yellow else T.Card)
		end
		local name = card:FindFirstChild("Name")
		if name and name:IsA("TextLabel") then
			name.TextColor3 = if lit then T.Dark else T.Ink
		end
		local badge = card:FindFirstChild("Worn")
		if badge and badge:IsA("GuiObject") then
			badge.Visible = worn
		end
	end
end

-- A card for something to wear, drawn as the toolkit's tiles are: a rounded square in a thin rim,
-- the picture on its upper face and the name on the deeper band along the bottom (on one or two
-- lines). A set (a bundle) says so on a tag; what they have on is yellow and ticked.
local CARD_W, CARD_H = 128, 160
local CARD_FOOT = math.floor((CARD_H - 2) * 0.66 + 0.5) + 1 -- where the band starts (Kit.tile's third)
local function itemCard(item: any, order: number, onClick: (() -> ())?, kind: string?): GuiObject
	local bundle = item.ItemType == "Bundle"
	local card = Kit.new("TextButton", {
		Text = "",
		AutoButtonColor = false,
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(CARD_W, CARD_H),
		LayoutOrder = order,
		Parent = grid,
	})
	local face = Kit.new("Frame", {
		Name = "Face",
		BackgroundColor3 = T.Card,
		BorderSizePixel = 0,
		Size = UDim2.new(1, -2, 1, -2),
		Position = UDim2.fromOffset(1, 1),
		Parent = card,
	})
	Kit.corner(face, 9)
	-- (a face with a Foot gradient is a tile's: Kit.paint gives it its band)
	Kit.new("UIGradient", { Name = "Foot", Rotation = 90, Parent = face })
	Kit.paint(face, T.Card)
	Kit.rim(face, Kit.edgeOf(T.Card), 1):SetAttribute("Follow", true)
	local picture = Kit.frame({
		Name = "Picture",
		Parent = card,
		Size = UDim2.fromOffset(CARD_W - 12, CARD_FOOT - 11),
		Position = UDim2.fromOffset(6, 6),
		Color = T.Picture,
		Radius = 6,
		Clips = true,
		ZIndex = 2,
	})
	Kit.new("ImageLabel", {
		Image = thumb(item.Id, item.ItemType),
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ScaleType = Enum.ScaleType.Fit,
		Parent = picture,
	})
	if bundle then
		local tag = Kit.frame({
			Name = "Set",
			Parent = picture,
			Size = UDim2.fromOffset(0, 18),
			AutomaticSize = Enum.AutomaticSize.X,
			Position = UDim2.fromOffset(5, 5),
			Color = T.Purple,
			Radius = "pill",
		})
		Kit.pad(tag, 8, 0)
		Kit.text("Set", {
			Parent = tag,
			Size = UDim2.fromOffset(0, 18),
			AutomaticSize = Enum.AutomaticSize.X,
			TextSize = 12,
			Font = Kit.Fonts.Bold,
			Color = T.Dark,
			Wrap = false,
		})
	end
	-- the tick on what they have on: a dark disc with a yellow check, on the picture's corner
	local worn = Kit.disc({
		Name = "Worn",
		Parent = card,
		Size = 24,
		Position = UDim2.new(1, -9, 0, 9),
		AnchorPoint = Vector2.new(1, 0),
		Color = T.Dark,
		Icon = "check",
		IconColor = T.Yellow,
		Ring = T.Yellow,
		ZIndex = 4,
	})
	worn.Visible = false
	Kit.title(item.Name or "", {
		Name = "Name",
		Parent = card,
		Size = UDim2.new(1, -12, 0, 38),
		Position = UDim2.fromOffset(6, CARD_FOOT + math.floor((CARD_H - CARD_FOOT - 38) / 2)),
		TextSize = 15,
		AlignX = Enum.TextXAlignment.Center,
		ZIndex = 2,
	}).TextTruncate =
		Enum.TextTruncate.AtEnd
	local scale = Kit.new("UIScale", { Parent = card })
	card.MouseEnter:Connect(function()
		TweenService:Create(scale, TweenInfo.new(0.15, Enum.EasingStyle.Back), { Scale = 1.05 }):Play()
	end)
	card.MouseLeave:Connect(function()
		TweenService:Create(scale, TweenInfo.new(0.15), { Scale = 1 }):Play()
	end)
	card.MouseButton1Down:Connect(function()
		TweenService:Create(scale, TweenInfo.new(0.06), { Scale = 0.96 }):Play()
	end)
	card.Activated:Connect(function()
		scale.Scale = 0.94
		TweenService:Create(scale, TweenInfo.new(0.3, Enum.EasingStyle.Back), { Scale = 1 }):Play()
		if onClick then
			onClick()
		else
			wear(item, kind)
		end
	end)
	cards[item.Id] = card
	cardItems[item.Id] = { item = item, kind = kind }
	return card
end

-- What to say when a search comes back with nothing, by where the cards come from.
local function nothingText(tab: any, f: any): string
	if tab and tab.source == "inventory" then
		return "You don't own any of these on Roblox."
	elseif tab and tab.source == "outfits" then
		return if f and f.outfits == "Purchased"
			then "You haven't bought a character on Roblox."
			else "You haven't saved an avatar on Roblox yet."
	end
	return "Nothing found. Try another word."
end

local function showItems(items: { any }, append: boolean?)
	if not append then
		clearGrid()
		forgetCards()
	end
	note(nil)
	remember(items)
	local f = currentFilter()
	local kind = if f then f.kind else nil
	local n = #grid:GetChildren()
	for i, item in items do
		if type(item.Id) == "number" then
			itemCard(item, n + i, nil, kind)
		end
	end
	refreshWorn()
	loadMore.Visible = pages ~= nil and not pages.IsFinished
	if next(cards) == nil then
		note(nothingText(currentTab(), f))
	end
end

-- The sort a search runs in. With nothing typed and no sort picked, a filter may have a better
-- order to browse in than the catalog's own.
local function sortFor(f: any): string
	if f.browse and keyword == "" and sortId == "Relevance" then
		return f.browse
	end
	return sortId
end

local function enumList(enum: any, names: { string }?): { any }
	local list = {}
	local from: { string } = names or {}
	for _, name in from do
		local e = enum[name]
		if e then
			table.insert(list, e)
		end
	end
	return list
end

local function buildParams(f: any, bundles: { string }?): CatalogSearchParams
	local params = CatalogSearchParams.new()
	params.SearchKeyword = keyword
	if f.assets then
		params.AssetTypes = enumList(Enum.AvatarAssetType, f.assets)
	end
	if bundles then
		params.BundleTypes = enumList(Enum.BundleType, bundles)
	end
	if f.offSale then
		params.IncludeOffSale = true
	end
	local sort = (Enum.CatalogSortType :: any)[sortFor(f)]
	if sort then
		params.SortType = sort
	end
	params.Limit = 30
	return params
end

-- Searches the catalog: on the client first, through the server if that fails. Returns the
-- first page and, from a search made here, the pages to go on with.
local function searchCatalog(f: any): ({ any }, any)
	local function try(bundles: { string }?): ({ any }?, any)
		local ok, result = pcall(function()
			return AvatarEditorService:SearchCatalogAsync(buildParams(f, bundles))
		end)
		if ok and result then
			local okPage, page = pcall(function()
				return result:GetCurrentPage()
			end)
			if okPage and type(page) == "table" then
				return page, result
			end
		end
		return nil, nil
	end
	local page, result = try(f.bundles)
	if not page and f.bundles and #f.bundles > 1 then
		-- the search may not take every bundle type there is: ask again for the first alone
		page, result = try({ f.bundles[1] })
	end
	if page then
		return page, result
	end
	local items = Remotes.fn("CreatorSearch"):InvokeServer({
		keyword = keyword,
		assets = f.assets,
		bundles = f.bundles,
		sort = sortFor(f),
		offSale = f.offSale,
		inside = f.inside,
	})
	return items or {}, nil
end

-- A page of something only the player's own screen may ask Roblox for (what they own, the
-- avatars they saved), as rows for cards. Nil rows mean Roblox didn't answer.
local function ownPage(call: () -> any, rows: (any) -> { any }): ({ any }?, any, ((any) -> { any })?)
	local ok, result = pcall(call)
	if not ok or not result then
		return nil, nil, nil
	end
	local okPage, page = pcall(function()
		return result:GetCurrentPage()
	end)
	if not okPage or type(page) ~= "table" then
		return nil, nil, nil
	end
	return rows(page), result, rows
end

-- Fetches a filter's first page: the rows for its cards, the pages to go on with (if any), and
-- what turns a later page into rows (if they aren't rows already). Nil rows: it couldn't be read.
local function fetch(tab: any, f: any): ({ any }?, any, ((any) -> { any })?)
	if tab.source == "inventory" then
		-- AvatarEditorService:GetInventoryAsync(assetTypes) -> InventoryPages of
		-- { AssetId, AssetType, Name, ... }; only after the player has said yes
		local only = if f.assets and #f.assets == 1 then f.assets[1] else nil
		return ownPage(function()
			return AvatarEditorService:GetInventoryAsync(enumList(Enum.AvatarAssetType, f.assets))
		end, function(page)
			return Categories.ownedItems(page, only)
		end)
	elseif tab.source == "outfits" then
		-- AvatarEditorService:GetOutfitsAsync(source, type) -> OutfitPages of { Id, Name, IsEditable };
		-- the same yes covers it. Whole avatars only: a head or a pair of shoes saved by itself
		-- isn't a look to put on.
		return ownPage(function()
			return AvatarEditorService:GetOutfitsAsync(
				(Enum.OutfitSource :: any)[f.outfits or "All"],
				Enum.OutfitType.Avatar
			)
		end, Categories.outfitItems)
	end
	local items, result = searchCatalog(f)
	if #items == 0 and f.inBundles then
		-- none listed singly: take the same part out of the bodies that are for sale
		local rows = function(page: any): { any }
			return Categories.partsIn(page, f.assets)
		end
		local found, more = searchCatalog({ id = f.id, bundles = f.inBundles, inside = true })
		return rows(found), more, rows
	end
	return items, result, nil
end

local LOOKING = {
	inventory = "Looking through your items...",
	outfits = "Looking for your avatars...",
}

local function search()
	local tab, f = currentTab(), currentFilter()
	if not tab or not f then
		return
	end
	searchToken += 1
	local token = searchToken
	clearGrid()
	forgetCards()
	pages, pageRows = nil, nil
	loadMore.Visible = false
	note(LOOKING[tab.source] or "Looking through the catalog...")
	task.spawn(function()
		local items, p, rows = fetch(tab, f)
		if token ~= searchToken or not isOpen then
			return
		end
		if not items then
			note("Roblox didn't answer. Give it a moment and try again.", "Try again", search)
			return
		end
		pages, pageRows = p, rows
		if keyword == "" and not tab.source then
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
		local ok, page = pcall(function()
			pages:AdvanceToNextPageAsync()
			return pages:GetCurrentPage()
		end)
		if token ~= searchToken then
			return
		end
		if not ok or type(page) ~= "table" then
			-- left where it was, to press again
			loadMore.Visible = true
			return
		end
		showItems(if pageRows then pageRows(page) else page, true)
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
				cached = searchCatalog(p.filter)
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
	forgetCards()
	local assets = Appearance.assets(app)
	if #assets == 0 then
		note("Nothing on yet. Pick something from the other tabs.")
		return
	end
	note(nil)
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
	if not content:FindFirstChild("Hint") then
		-- how this page works, in a hint strip under the cards
		local hint = Kit.hint("Click something to take it off. Undo puts it back on.", { Parent = content })
		hint.Position = UDim2.fromScale(0, 1)
		hint.AnchorPoint = Vector2.new(0, 1)
	end
end

-- A box to type in, drawn like the search box: a dark pill in a thin rim with the words on it. props:
-- Parent, Size, Position, LayoutOrder, Name, TextSize, Text. Returns the text box (in a holder of
-- its own, sized and placed by props).
local function inputWell(placeholder: string, props: { [string]: any }): TextBox
	local h: number = (props.Size :: UDim2).Y.Offset
	local holder = Kit.box({
		Name = props.Name or "Input",
		Parent = props.Parent,
		Size = props.Size,
		Position = props.Position,
		LayoutOrder = props.LayoutOrder,
	})
	local well = Kit.frame({ Name = "Well", Parent = holder, Color = T.PaperDark, Radius = "pill" })
	Kit.rim(well, T.Line, 1)
	local lean = math.floor(h / 2) - 6 -- clear of its round ends
	local box = Kit.textbox(placeholder, {
		Parent = holder,
		Size = UDim2.new(1, -lean * 2, 1, 0),
		Text = props.Text,
		TextSize = props.TextSize or 16,
	})
	box.Position = UDim2.fromOffset(lean, 0)
	box.BackgroundTransparency = 1
	box.ZIndex = 2
	local pad = box:FindFirstChildOfClass("UIPadding")
	if pad then
		pad.PaddingLeft = UDim.new(0, 6)
	end
	return box
end

-- A grid of colours to pick from; the one they have stands in a yellow ring, which moves to
-- whatever is clicked. Returns the grid and a function that rings a colour.
local function colourGrid(
	parent: Instance,
	list: { string },
	px: number,
	current: string?,
	onPick: (string) -> (),
	order: number
): (Frame, (string?) -> ())
	local ring = 3
	local g = Kit.box({
		Parent = parent,
		Size = UDim2.new(1, -10, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = order,
	})
	Kit.grid(g, UDim2.fromOffset(px + ring * 2, px + ring * 2), 4)
	local rings: { [string]: Frame } = {}
	local function mark(hex: string?)
		for h, r in rings do
			r.Visible = h == hex
		end
	end
	for i, hex in list do
		local cell = Kit.box({ Parent = g, LayoutOrder = i })
		rings[hex] = Kit.frame({
			Name = "Ring",
			Parent = cell,
			Size = UDim2.fromScale(1, 1),
			Color = T.Yellow,
			Radius = "round",
			Visible = false,
		})
		local b = Kit.swatch(Colors.fromHex(hex), px, function()
			mark(hex)
			onPick(hex)
		end, { Parent = cell })
		b.Position = UDim2.fromOffset(ring, ring)
		-- a thin rim, so a white or a charcoal one still shows on the panel in either look (the
		-- swatch's own stroke, switched on: an object draws only one)
		local edge = b:FindFirstChildOfClass("UIStroke")
		if edge then
			edge.Enabled, edge.Color, edge.Thickness, edge.Transparency = true, T.Line, 1, 0
		end
	end
	mark(current)
	return g, mark
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
	Kit.list(holder, 10)
	local part = SKIN_PARTS[1]
	local marks: { (string?) -> () } = {}
	-- the colour of the part being painted (its first piece), ringed in both grids
	local function now(): string?
		return app.colors and app.colors[part.keys[1]]
	end
	local function ring()
		for _, mark in marks do
			mark(now())
		end
	end
	local _, selectPart = Kit.tabs(SKIN_PARTS, function(id)
		for _, p in SKIN_PARTS do
			if p.id == id then
				part = p
			end
		end
		ring()
	end, { Parent = holder, LayoutOrder = 1, Height = 34, TextSize = 15 })
	selectPart("all")
	local function pick(hex: string)
		local new = Appearance.sanitize(app)
		for _, k in part.keys do
			new.colors[k] = hex
		end
		setApp(new)
		ring()
	end
	Kit.text(
		"Skin tones",
		{ Parent = holder, TextSize = 15, Font = Kit.Fonts.Bold, Color = T.InkSoft, LayoutOrder = 2 }
	)
	local _, a = colourGrid(holder, Appearance.SkinTones, 36, now(), pick, 3)
	Kit.text(
		"Any colour",
		{ Parent = holder, TextSize = 15, Font = Kit.Fonts.Bold, Color = T.InkSoft, LayoutOrder = 4 }
	)
	local _, b = colourGrid(holder, Palette.Colors, 30, now(), pick, 5)
	marks = { a, b }
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
	Kit.button("Back to normal", {
		Parent = holder,
		Size = UDim2.fromOffset(200, 40),
		Color = T.Blue,
		TextSize = 18,
		Icon = "undo",
		LayoutOrder = 20,
	}, function()
		local new = Appearance.sanitize(app)
		for _, k in Appearance.ScaleKeys do
			new.scale[k] = Appearance.ScaleLimits[k].Default
		end
		setApp(new)
		selectTab("shape")
	end)
end

local function outfitsPage()
	local holder = Kit.box({ Parent = content, Size = UDim2.fromScale(1, 1) })
	local row = Kit.box({ Parent = holder, Size = UDim2.new(1, 0, 0, ROW_H) })
	Kit.list(row, 8, true)
	local nameBox = inputWell("Name this outfit", { Parent = row, Size = UDim2.new(1, -196, 0, ROW_H) })
	Kit.button(
		"Save this look",
		{ Parent = row, Size = UDim2.fromOffset(188, ROW_H), Color = T.Green, TextSize = 17, Icon = "hanger" },
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
	local list = Kit.scroll({
		Parent = holder,
		Size = UDim2.new(1, 0, 1, -(ROW_H + 12)),
		Position = UDim2.fromOffset(0, ROW_H + 12),
	})
	list.ScrollBarThickness = 4
	Kit.list(list, 6)
	local outfits = State.data.outfits or {}
	if #outfits == 0 then
		-- nothing saved: say how, on a card of its own (the note under the cards)
		note("No outfits saved yet. Give this look a name and save it, and it will wait here to be worn again.")
		local n = content:FindFirstChild("Note")
		if n and n:IsA("GuiObject") then
			n.Position = UDim2.fromOffset(0, ROW_H + 12)
		end
	end
	for i, o in outfits do
		local r, inner = Kit.row({
			Parent = list,
			Size = UDim2.new(1, -8, 0, 52),
			Height = 52,
			Title = o.name,
			TextSize = 18,
			Marker = "hanger",
			RightSpace = 200,
			LayoutOrder = i,
		})
		local _ = r
		Kit.button("Wear", {
			Parent = inner,
			Size = UDim2.fromOffset(84, 36),
			Position = UDim2.new(1, -200, 0.5, -18),
			Color = T.Blue,
			TextSize = 16,
		}, function()
			setApp(o.app)
		end)
		Kit.button("Delete", {
			Parent = inner,
			Size = UDim2.fromOffset(96, 36),
			Position = UDim2.new(1, -110, 0.5, -18),
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

-- The Players tab: avatars made by players. The people in this server and your friends as they
-- look on Roblox (click one and the villager wears it), then looks players have shared from this
-- creator, with a box to share the one you are making.
local function peoplePage()
	local holder = Kit.scroll({ Parent = content, Size = UDim2.fromScale(1, 1) })
	holder.ScrollBarThickness = 4
	Kit.list(holder, 8)
	-- each group under a dim caption, as the rows in menus are
	local function caption(text: string, order: number)
		Kit.text(text, {
			Name = "Caption",
			Parent = holder,
			Size = UDim2.new(1, -12, 0, 20),
			TextSize = 15,
			Font = Kit.Fonts.Bold,
			Color = T.InkSoft,
			LayoutOrder = order,
		})
	end
	caption("People here and your friends", 1)
	local faces = Kit.box({
		Name = "Faces",
		Parent = holder,
		Size = UDim2.new(1, -12, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = 2,
	})
	Kit.grid(faces, UDim2.fromOffset(104, 128), 8)
	local waiting = Kit.text("Looking for people...", {
		Parent = holder,
		Size = UDim2.new(1, -12, 0, 22),
		TextSize = 15,
		Color = T.InkSoft,
		LayoutOrder = 3,
	})
	caption("Shared by players", 4)
	local row = Kit.box({ Parent = holder, Size = UDim2.new(1, -12, 0, ROW_H), LayoutOrder = 5 })
	Kit.list(row, 8, true)
	local nameBox = inputWell("Name this look", { Parent = row, Size = UDim2.new(1, -192, 0, ROW_H) })
	Kit.button(
		"Share this look",
		{ Parent = row, Size = UDim2.fromOffset(184, ROW_H), Color = T.Green, TextSize = 17 },
		function()
			local name = Text.clean(nameBox.Text)
			if name == "" then
				Toasts.show("Give it a name first.", "warn")
				return
			end
			task.spawn(function()
				local ok, err = Remotes.fn("LookShare"):InvokeServer(name, app)
				if ok then
					Toasts.show("Shared. Other players can wear it now.", "good")
					task.wait(0.4)
					if isOpen and tabId == "people" then
						selectTab("people")
					end
				elseif err then
					Toasts.show(err, "warn")
				end
			end)
		end
	)
	local looks = Kit.box({
		Name = "Looks",
		Parent = holder,
		Size = UDim2.new(1, -12, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = 6,
	})
	Kit.list(looks, 6)

	task.spawn(function()
		local ok, data = pcall(function()
			return Remotes.fn("CreatorPeople"):InvokeServer()
		end)
		if not holder.Parent then
			return
		end
		waiting:Destroy()
		if not ok or type(data) ~= "table" then
			Kit.text("Couldn't look anyone up just now.", { Parent = faces, TextSize = 15, Color = T.InkSoft })
			return
		end
		local KINDS = { you = "You", here = "Here now", friend = "Friend" }
		for i, person in data.people or {} do
			local card = Kit.new("TextButton", {
				Name = "Person",
				Text = "",
				AutoButtonColor = true,
				BackgroundColor3 = T.Card,
				LayoutOrder = i,
				Parent = faces,
			})
			Kit.corner(card, 12)
			Kit.rim(card, T.Line, 1)
			-- a circle with a border ("make portraits a circle with a border instead of a square")
			local face = Kit.portrait({
				Parent = card,
				Size = 76,
				Position = UDim2.new(0.5, -38, 0, 8),
				Color = T.Picture,
				Border = T.Line,
				BorderWidth = 3,
			})
			Kit.rounded(Kit.new("ImageLabel", {
				Image = string.format("rbxthumb://type=AvatarHeadShot&id=%d&w=150&h=150", person.id),
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1),
				Parent = face,
			}))
			Kit.text(person.name, {
				Parent = card,
				Size = UDim2.new(1, -8, 0, 18),
				Position = UDim2.fromOffset(4, 88),
				TextSize = 13,
				Font = Kit.Fonts.Bold,
				AlignX = Enum.TextXAlignment.Center,
				Wrap = false,
			}).TextTruncate =
				Enum.TextTruncate.AtEnd
			Kit.text(KINDS[person.kind] or "", {
				Parent = card,
				Size = UDim2.new(1, -8, 0, 14),
				Position = UDim2.fromOffset(4, 107),
				TextSize = 11,
				Color = T.InkSoft,
				AlignX = Enum.TextXAlignment.Center,
				Wrap = false,
			})
			card.Activated:Connect(function()
				task.spawn(function()
					local look = Remotes.fn("CreatorFromUserId"):InvokeServer(person.id)
					if look then
						setApp(look)
					else
						Toasts.show("Couldn't load that avatar just now.", "warn")
					end
				end)
			end)
		end
		local shared = data.looks or {}
		if #shared == 0 then
			Kit.hint("Nobody has shared a look yet. Name yours above and share it, and other players can wear it.", {
				Parent = looks,
			})
		end
		for i, look in shared do
			-- a pill row each: who made it in a round portrait, its name, and a way to wear it
			local _, inner = Kit.row({
				Name = "Look",
				Parent = looks,
				Height = 56,
				Title = look.name,
				Sub = Text.fill("by {who}", { who = look.who or "" }),
				TextSize = 17,
				LeftSpace = 58,
				RightSpace = 104,
				LayoutOrder = i,
			})
			local face = Kit.portrait({
				Parent = inner,
				Size = 42,
				Position = UDim2.fromOffset(9, 7),
				Color = T.Picture,
				Border = T.Line,
				BorderWidth = 2,
				ZIndex = 2,
			})
			Kit.rounded(Kit.new("ImageLabel", {
				Image = string.format("rbxthumb://type=AvatarHeadShot&id=%d&w=150&h=150", look.by),
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1),
				ZIndex = 2,
				Parent = face,
			}))
			Kit.button("Wear", {
				Parent = inner,
				Size = UDim2.fromOffset(84, 36),
				Position = UDim2.new(1, -12, 0.5, 0),
				AnchorPoint = Vector2.new(1, 0.5),
				Color = T.Blue,
				TextSize = 16,
				ZIndex = 3,
			}, function()
				setApp(look.app)
			end)
		end
	end)
end

-- Roblox's question -----------------------------------------------------------------------------------
--
-- What a player owns and the avatars they have saved are theirs to show. Roblox asks them
-- (AvatarEditorService:PromptAllowInventoryReadAccess, answered through
-- PromptAllowInventoryReadAccessCompleted) and only after a yes does it answer GetInventoryAsync
-- and GetOutfitsAsync, on their own screen only, until they leave the game. So nothing is asked
-- until they press the button on My items or My avatars, and a no is said plainly, with a
-- button to be asked again.

local OWN = {
	inventory = {
		unasked = "Put what you own on Roblox on your villager. Roblox will ask you first if this game may see your items.",
		no = "You said no, so nothing was read. Your items stay hidden from this game.",
		button = "Show my items",
	},
	outfits = {
		unasked = "Dress your villager in an avatar you saved on Roblox. Roblox will ask you first if this game may see them.",
		no = "You said no, so nothing was read. Your saved avatars stay hidden from this game.",
		button = "Show my avatars",
	},
}

local asks = 0

-- Shows the answer (or the wait for it) on whichever of the two tabs is open.
local function showAccess()
	local tab = currentTab()
	if isOpen and tab and tab.source then
		selectTab(tabId)
	end
end

local function askAccess()
	if access == "asking" then
		return
	end
	if not accessConn then
		local ok, conn = pcall(function()
			return AvatarEditorService.PromptAllowInventoryReadAccessCompleted:Connect(function(result)
				access = if result == Enum.AvatarPromptResult.Success then "yes" else "no"
				showAccess()
			end)
		end)
		accessConn = if ok then conn else nil
	end
	-- set before the call: the answer may come back while it runs
	asks += 1
	local ask = asks
	access = "asking"
	local asked = accessConn ~= nil and pcall(function()
		AvatarEditorService:PromptAllowInventoryReadAccess()
	end)
	if not asked then
		access = "failed"
	end
	if access == "asking" or access == "failed" then
		showAccess()
	end
	-- a question put away without an answer must not leave the page waiting for ever
	task.delay(45, function()
		if access == "asking" and ask == asks then
			access = "unasked"
			showAccess()
		end
	end)
end

-- The page shown on My items and My avatars until the player has said yes.
local function askPage(tab: any)
	local words = OWN[tab.source]
	local text, button
	if access == "asking" then
		text = "Roblox is asking you now. Answer it to carry on."
	elseif access == "no" then
		text, button = words.no, "Ask me again"
	elseif access == "failed" then
		text, button = "Roblox couldn't be asked just now.", "Try again"
	else
		text, button = words.unasked, words.button
	end
	note(text, button, if button then askAccess else nil)
end

-- Lays the search row, the filter row and the cards out under one another, leaving no gap for a
-- row that isn't there.
local function layoutBrowse(showSearch: boolean, showFilterRow: boolean)
	searchRow.Visible = showSearch
	filterRow.Visible = showFilterRow
	local y = 0
	if showSearch then
		y += ROW_H + 8
	end
	filterRow.Position = UDim2.fromOffset(0, y)
	if showFilterRow then
		y += ROW_H + 8
	end
	content.Position = UDim2.fromOffset(0, y)
	content.Size = UDim2.new(1, 0, 1, -y)
end

local function showFilters(tab: any)
	for _, c in filterRow:GetChildren() do
		if c:IsA("GuiButton") then
			c:Destroy()
		end
	end
	local filters = tab and tab.filters
	-- what the player owns isn't searched by word or sorted: Roblox lists it as it is. And its
	-- filters wait for their yes.
	local own = tab ~= nil and tab.source ~= nil
	local open = filters ~= nil and (not own or access == "yes")
	layoutBrowse(filters ~= nil and not own, open and #filters > 1)
	if not filters or not open then
		return
	end
	for i, f in filters do
		local on = i == filterIndex
		local b = Kit.button(f.name, {
			Parent = filterRow,
			Size = UDim2.fromOffset(0, ROW_H),
			AutomaticSize = Enum.AutomaticSize.X,
			TextSize = 14,
			Color = if on then T.Yellow else T.Card,
			TextColor = if on then T.Dark else T.Ink,
			LayoutOrder = i,
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
	local tab = Categories.tab(id)
	-- whatever was being fetched for the last tab is no longer wanted
	searchToken += 1
	pages, pageRows = nil, nil
	clearContent()
	forgetCards()
	showFilters(tab)
	if tab and tab.filters then
		if tab.source and access ~= "yes" then
			askPage(tab)
		else
			grid.Visible = true
			search()
		end
	elseif id == "wearing" then
		wearingPage()
	elseif id == "skin" then
		skinPage()
	elseif id == "shape" then
		shapePage()
	elseif id == "outfits" then
		outfitsPage()
	elseif id == "people" then
		peoplePage()
	end
end

-- Profile page ---------------------------------------------------------------------------------------

local function buildProfilePage()
	for _, c in profilePage:GetChildren() do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
	local scroll = Kit.scroll({ Parent = profilePage, Size = UDim2.new(1, 0, 1, -64) })
	scroll.ScrollBarThickness = 4
	Kit.list(scroll, 8)
	local function heading(text: string, order: number)
		Kit.text(text, {
			Parent = scroll,
			Size = UDim2.new(1, -10, 0, 22),
			TextSize = 15,
			Font = Kit.Fonts.Bold,
			Color = T.InkSoft,
			LayoutOrder = order,
		})
	end
	heading("Name", 1)
	local nameBox = Kit.textbox(
		"What are they called?",
		{ Parent = scroll, Text = profile.name, LayoutOrder = 2, Size = UDim2.new(1, -10, 0, 42) }
	)
	nameBox.Font = Kit.Fonts.Title
	nameBox.TextSize = 20
	Kit.rim(nameBox, T.Line, 1)
	nameBox:GetPropertyChangedSignal("Text"):Connect(function()
		if utf8.len(nameBox.Text) and (utf8.len(nameBox.Text) :: number) > Tuning.Villagers.NameMaxLength then
			nameBox.Text = nameBox.Text:sub(1, Tuning.Villagers.NameMaxLength)
		end
		profile.name = nameBox.Text
	end)
	heading("Personality", 3)
	local persGrid = Kit.box({
		Parent = scroll,
		Size = UDim2.new(1, -10, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = 4,
	})
	Kit.grid(persGrid, UDim2.new(0.5, -4, 0, 64), 8)
	-- a card each: a disc in the personality's own colour, its name and what they are like; the
	-- one they are is yellow with dark words, like anything picked
	local persButtons: { [string]: TextButton } = {}
	local function refreshPers()
		for id, b in persButtons do
			local on = id == profile.pers
			Kit.paintCut(b, if on then T.Yellow else T.Card)
			for _, l in b:GetChildren() do
				if l:IsA("TextLabel") then
					l.TextColor3 = if on then T.Dark elseif l.Name == "Blurb" then T.InkSoft else T.Ink
				end
			end
		end
	end
	for i, p in Personalities.list do
		local b = Kit.new("TextButton", {
			Name = p.name,
			Text = "",
			AutoButtonColor = false,
			BackgroundTransparency = 1,
			LayoutOrder = i,
			Parent = persGrid,
		})
		local shape = Kit.cutInto(b, T.Card, 12)
		Kit.rim(shape, T.Line, 1)
		-- its colour as a round mark in a dark ring (so a yellow one still shows on the yellow card)
		Kit.disc({
			Name = "Swatch",
			Parent = b,
			Size = 28,
			Position = UDim2.fromOffset(10, 18),
			Color = Colors.fromHex(p.color),
			Ring = T.Dark,
		})
		Kit.title(p.name, {
			Name = "Title",
			Parent = b,
			Size = UDim2.new(1, -60, 0, 24),
			Position = UDim2.fromOffset(48, 6),
			TextSize = 18,
			Wrap = false,
		})
		Kit.text(p.blurb, {
			Name = "Blurb",
			Parent = b,
			Size = UDim2.new(1, -60, 0, 32),
			Position = UDim2.fromOffset(48, 29),
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
	heading("Favourite colour", 5)
	colourGrid(scroll, Palette.Colors, 26, profile.color, function(hex)
		profile.color = hex
		paintStudio()
	end, 6)
	heading("Birthday", 7)
	local seasons = {}
	for i, name in Schema.Seasons do
		table.insert(seasons, { id = tostring(i), name = name })
	end
	local _, selectSeason = Kit.tabs(seasons, function(id)
		profile.bday.s = tonumber(id) :: number
	end, { Parent = scroll, LayoutOrder = 8, Size = UDim2.new(1, -10, 0, 38), Height = 34, TextSize = 15 })
	selectSeason(tostring(profile.bday.s))
	Kit.slider("Day", 1, Schema.DaysPerSeason, profile.bday.d, 1, function(v)
		profile.bday.d = v
	end, { Parent = scroll, LayoutOrder = 9, Size = UDim2.new(1, -10, 0, 46) })

	local save = Kit.button(if mode == "new" then "Move them in" else "Save changes", {
		Parent = profilePage,
		Size = UDim2.new(1, 0, 0, 52),
		Position = UDim2.new(0, 0, 1, -52),
		Color = T.Green,
		TextSize = 22,
		Icon = if mode == "new" then "house" else "check",
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

local stepNow = "look"

local function showStep(step: string)
	stepNow = step
	lookPage.Visible = step == "look"
	profilePage.Visible = step == "profile"
	for id, b in stepButtons do
		-- the picked step is yellow with dark words, like a picked tab on any menu
		Kit.setButtonColor(b, if id == step then T.Yellow else T.PaperDark, if id == step then T.Dark else T.Ink)
	end
	if step == "profile" then
		buildProfilePage()
	end
end

-- Camera -----------------------------------------------------------------------------------------------

-- The height the camera looks at: the head from close up, the chest at the usual distance, the
-- middle of them from far off.
local function focusAt(z: number): number
	if z <= ZOOM_HOME then
		local t = math.clamp((z - ZOOM_FACE) / (ZOOM_HOME - ZOOM_FACE), 0, 1)
		return 5 + (3.6 - 5) * t
	end
	local t = math.clamp((z - ZOOM_HOME) / (ZOOM_WHOLE - ZOOM_HOME), 0, 1)
	return 3.6 + (3.15 - 3.6) * t
end

-- The studio: what stands behind them in place of the town (the user: "no need for the gradient
-- background or the city background, make an animated menu like in the screenshot"). The stage
-- is up in the sky, so there is no ground to hide; a flat part stands square to the camera a
-- little way behind the mannequin, wide enough to fill the view, and carries the same moving
-- backdrop as the villagers' screen. It follows the camera, so turning the view turns the
-- villager and the backdrop stays put. A lamp by the camera keeps them lit at night. All of it
-- is on this player's own screen only.
type Studio = {
	part: Part,
	gui: SurfaceGui,
	lamp: Part,
	light: PointLight,
	w: number,
	h: number,
	-- their shadow on the backdrop: a copy of the mannequin in a picture of its own, all black
	shade: ViewportFrame?,
	shadeCam: Camera?,
	twin: Model?,
	source: Model?,
	mark: number,
	motors: { { Motor6D } },
	roots: { BasePart },
	nextLook: number,
}
local studio: Studio? = nil
local fovBefore: number? = nil

local function studioColor(): Color3
	local ok, c = pcall(Colors.fromHex, profile.color)
	return if ok and typeof(c) == "Color3" then c else T.Blue
end

function paintStudio()
	if panelFrame and panelFrame.Parent then
		Kit.glow(panelFrame, studioColor(), 0.22)
	end
	local s = studio
	if not s then
		return
	end
	for _, c in s.gui:GetChildren() do
		c:Destroy()
	end
	local size = s.gui.CanvasSize
	Kit.backdrop(s.gui, studioColor(), 77, {
		Plain = true,
		W = size.X + 200,
		H = size.Y + 200,
		Count = 26,
		Sink = 0.6,
		Sizes = { 40, 120 },
	})
	-- The shadow they cast on it (the user: "there should also be a shadow cast on the
	-- background in the character customization and character select screen"). The backdrop is
	-- a flat picture, so no real shadow falls on it: a second picture on it shows a copy of the
	-- mannequin through the same camera, all in black and see-through, a little bigger and off
	-- to one side. The backdrop is 1.06 of the screen, so the picture is the screen's size.
	local shade = Instance.new("ViewportFrame")
	shade.Name = "Shade"
	shade.BackgroundTransparency = 1
	shade.ImageColor3 = Color3.new(0, 0, 0)
	shade.ImageTransparency = 0.68
	shade.AnchorPoint = Vector2.new(0.5, 0.5)
	shade.Size = UDim2.fromScale(1.07 / 1.06, 1.07 / 1.06)
	shade.Position = UDim2.fromScale(0.5 + 0.07, 0.5 + 0.012)
	shade.ZIndex = 2
	local world = Instance.new("WorldModel")
	world.Name = "World"
	world.Parent = shade
	local shadeCam = Instance.new("Camera")
	shadeCam.Parent = shade
	shade.CurrentCamera = shadeCam
	shade.Parent = s.gui
	s.shade, s.shadeCam = shade, shadeCam
	s.twin, s.source, s.mark, s.motors, s.roots, s.nextLook = nil, nil, 0, {}, {}, 0
end

-- The mannequin on this player's stage (the server swaps it for a new one now and then).
local function findMannequin(): Model?
	for _, c in workspace:GetChildren() do
		if c:IsA("Model") and c.Name:sub(1, 12) == "CreatorStage" and c:GetAttribute("Origin") == origin then
			for _, m in c:GetChildren() do
				if m:IsA("Model") and m:FindFirstChildOfClass("Humanoid") then
					return m
				end
			end
		end
	end
	return nil
end

-- A number that changes when the mannequin's shape does: how many pieces, and how big.
local function shapeMark(model: Model): number
	local mark = 0
	for _, d in model:GetDescendants() do
		mark += 1
		if d:IsA("BasePart") then
			mark += d.Size.X + d.Size.Y * 3 + d.Size.Z * 7
		end
	end
	return mark
end

-- Keeps the shadow's copy the mannequin's shape, in its pose, seen as the camera sees it.
local function syncShadow(cam: Camera)
	local s = studio
	local shade, shadeCam = s and s.shade, s and s.shadeCam
	if not s or not shade or not shadeCam then
		return
	end
	shadeCam.CFrame = cam.CFrame
	shadeCam.FieldOfView = cam.FieldOfView
	local now = os.clock()
	if now >= s.nextLook then
		s.nextLook = now + 0.4
		local model = findMannequin()
		local mark = if model then shapeMark(model) else 0
		if model ~= s.source or mark ~= s.mark then
			if s.twin then
				s.twin:Destroy()
			end
			s.twin, s.source, s.mark, s.motors, s.roots = nil, model, mark, {}, {}
			local world = shade:FindFirstChild("World")
			local ok, copy = pcall(function()
				if not model then
					return nil
				end
				model.Archivable = true
				return model:Clone()
			end)
			if ok and copy and model and world then
				-- the copy's pieces come in the mannequin's order: pair the joints up by it
				local from, to = model:GetDescendants(), copy:GetDescendants()
				for i, d in from do
					local t = to[i]
					if d:IsA("Motor6D") and t and t:IsA("Motor6D") then
						table.insert(s.motors, { d, t })
					end
				end
				local a, b = model:FindFirstChild("HumanoidRootPart"), copy:FindFirstChild("HumanoidRootPart")
				if a and a:IsA("BasePart") and b and b:IsA("BasePart") then
					b.Anchored = true
					s.roots = { a, b }
				end
				for _, d in to do
					if d:IsA("Script") or d:IsA("LocalScript") or d:IsA("BillboardGui") then
						d:Destroy()
					end
				end
				copy.Parent = world
				s.twin = copy
			end
		end
	end
	for _, pair in s.motors do
		pair[2].Transform = pair[1].Transform
	end
	if s.roots[1] and s.roots[2] then
		s.roots[2].CFrame = s.roots[1].CFrame
	end
end

-- The town's bloom is what makes lit signs glow after dark. On the studio's flat, bright
-- backdrop and on a pale outfit it is far too much (the user: "the bloom is also too heavy in the
-- character creation screen"), so while the creator is open the bloom and the sun's rays are
-- switched off, on this player's own screen only, and put back when it closes.
local calmed: { [Instance]: boolean } = {}
local function calmLight(on: boolean)
	if on then
		for _, e in Lighting:GetChildren() do
			if (e:IsA("BloomEffect") or e:IsA("SunRaysEffect")) and e.Enabled then
				calmed[e] = true
				e.Enabled = false
			end
		end
	else
		for e in calmed do
			if e.Parent then
				(e :: any).Enabled = true
			end
		end
		table.clear(calmed)
	end
end

local function closeStudio()
	calmLight(false)
	local s = studio
	if s then
		s.gui:Destroy()
		s.part:Destroy()
		s.lamp:Destroy()
		studio = nil
	end
end

local function openStudio()
	closeStudio()
	local function ghost(name: string): Part
		local p = Instance.new("Part")
		p.Name = name
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = false
		p.Material = Enum.Material.SmoothPlastic
		p.Color = T.Black
		p.Size = Vector3.new(4, 4, 0.2)
		p.Parent = workspace
		return p
	end
	local part = ghost("CreatorBackdrop")
	local lamp = ghost("CreatorLamp")
	lamp.Transparency = 1
	lamp.Size = Vector3.new(0.2, 0.2, 0.2)
	local light = Instance.new("PointLight")
	light.Range = 30
	light.Shadows = false
	light.Color = Color3.fromRGB(255, 244, 232)
	light.Parent = lamp
	local gui = Instance.new("SurfaceGui")
	gui.Name = "CreatorBackdrop"
	gui.Face = Enum.NormalId.Back
	gui.LightInfluence = 0
	gui.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
	gui.CanvasSize = Vector2.new(1600, 900)
	gui.ClipsDescendants = true
	gui.ResetOnSpawn = false
	gui.Adornee = part
	gui.Parent = Kit.root().Parent
	calmLight(true)
	studio = {
		part = part,
		gui = gui,
		lamp = lamp,
		light = light,
		w = 0,
		h = 0,
		mark = 0,
		motors = {},
		roots = {},
		nextLook = 0,
	}
	paintStudio()
end

-- Stands the backdrop square to the camera, filling the view, `depth` studs off.
local function placeStudio(cam: Camera, depth: number)
	local s = studio
	if not s then
		return
	end
	local view = cam.ViewportSize
	local aspect = if view.Y > 0 then view.X / view.Y else 16 / 9
	local h = 2 * depth * math.tan(math.rad(cam.FieldOfView / 2)) * 1.06
	local w = h * aspect
	if math.abs(w - s.w) > 0.01 or math.abs(h - s.h) > 0.01 then
		s.w, s.h = w, h
		s.part.Size = Vector3.new(w, h, 0.2)
		-- keep the picture's shape the screen's, so nothing on it is stretched
		local wide = math.clamp(math.floor(900 * aspect + 0.5), 900, 2400)
		if math.abs(wide - s.gui.CanvasSize.X) > 8 then
			s.gui.CanvasSize = Vector2.new(wide, 900)
			paintStudio()
		end
	end
	s.part.CFrame = cam.CFrame * CFrame.new(0, 0, -depth - 0.1)
	s.lamp.CFrame = cam.CFrame * CFrame.new(-2, 1.5, 0)
	-- a soft fill by day, the main light at night
	local hour = Lighting.ClockTime
	local dark = math.clamp((math.abs(hour - 12.5) - 5.2) / 1.4, 0, 1)
	s.light.Brightness = 0.2 + 1.5 * dark
end

local function stopCamera()
	if camConn then
		camConn:Disconnect()
		camConn = nil
	end
	for _, c in inputConns do
		c:Disconnect()
	end
	inputConns = {}
	closeStudio()
	local cam = workspace.CurrentCamera
	cam.CameraType = Enum.CameraType.Custom
	if fovBefore then
		cam.FieldOfView = fovBefore
		fovBefore = nil
	end
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
	fovBefore = fovBefore or cam.FieldOfView
	cam.FieldOfView = FOV
	openStudio()
	local dragging = false
	local last: Vector2? = nil
	local pinchFrom: number? = nil
	local function frame()
		-- the mannequin stands at the origin; the camera sits off to one side of it, so they
		-- stand in the left half of the screen and the panel on the right doesn't cover them
		local center = origin + Vector3.new(0, focusAt(zoom), 0)
		local dir = Vector3.new(math.sin(yaw), 0.1, math.cos(yaw)).Unit
		local view = cam.ViewportSize
		local aspect = if view.Y > 0 then view.X / view.Y else 16 / 9
		local half = zoom * math.tan(math.rad(FOV / 2)) * aspect
		cam.CFrame = CFrame.lookAt(center + dir * zoom, center) * CFrame.new(half * 0.5, 0, 0)
		placeStudio(cam, zoom + 9)
		syncShadow(cam)
	end
	frame()
	camConn = RunService.RenderStepped:Connect(frame)
	-- two fingers pinch to zoom
	table.insert(
		inputConns,
		UserInputService.TouchPinch:Connect(function(_touches, scale, _velocity, state, processed)
			if processed then
				return
			end
			if state == Enum.UserInputState.Begin or not pinchFrom then
				pinchFrom = zoom
			end
			if scale > 0 then
				zoom = math.clamp((pinchFrom :: number) / scale, ZOOM_MIN, ZOOM_MAX)
			end
			if state == Enum.UserInputState.End or state == Enum.UserInputState.Cancel then
				pinchFrom = nil
			end
		end)
	)
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
				zoom = math.clamp(zoom * (if input.Position.Z > 0 then 0.9 else 1.1), ZOOM_MIN, ZOOM_MAX)
			end
		end)
	)
end

-- Building the screen ------------------------------------------------------------------------------------

-- The title sits at the top left beside the way back, as on every menu.
local function setTitle(text: string)
	if titleLabel then
		titleLabel.Text = text
	end
end

local function build()
	local gui = Kit.root()
	local frame = Kit.box({ Name = "Creator", Size = UDim2.fromScale(1, 1), Parent = gui })
	frame.ZIndex = 10
	root = frame

	-- Laid out as a character screen, like the villagers' one (the user pointed at another
	-- game's character menu for both): the villager stands on the left in front of the studio's
	-- moving backdrop (startCamera), and everything to choose from sits in a panel on the right.
	-- the way back and the title, at the top left
	local back = Kit.backButton({ Parent = frame, Position = UDim2.fromOffset(16, 12) }, function()
		Creator.close()
	end)
	local _back = back
	titleLabel = Kit.title("Make a villager", {
		Parent = frame,
		Size = UDim2.fromOffset(520, 46),
		Position = UDim2.fromOffset(104, 12),
		TextSize = 30,
		Color = T.Ink,
		Wrap = false,
	})

	-- Everything to choose from is one panel on the right, a slab with two corners cut, its
	-- villager's favourite colour glowing in from the top right (paintStudio). The villager's
	-- side of the screen stays clear but for the tools in one card at the bottom left.
	local holder = Kit.frame({
		Name = "PanelHolder",
		Size = UDim2.new(0, PANEL_W + PANEL_PAD * 2, 1, -28),
		Position = UDim2.new(1, -16, 0, 14),
		AnchorPoint = Vector2.new(1, 0),
		Color = T.Cream,
		Cut = 14,
		Parent = frame,
	})
	Kit.softShadow(holder, 1)
	panelFrame = holder
	Kit.glow(holder, studioColor(), 0.22)
	local panel = Kit.box({
		Name = "Panel",
		Parent = holder,
		Size = UDim2.new(1, -PANEL_PAD * 2, 1, -PANEL_PAD * 2),
		Position = UDim2.fromOffset(PANEL_PAD, PANEL_PAD),
		ZIndex = 2,
	})
	-- the two steps as one segmented control: a dark pill well in a thin rim, the step you are on
	-- a yellow pill in it
	local steps = Kit.frame({
		Parent = panel,
		Size = UDim2.new(1, 0, 0, 46),
		Position = UDim2.fromOffset(0, 0),
		Color = T.PaperDark,
		Radius = "pill",
	})
	Kit.rim(steps, T.Line, 1)
	Kit.pad(steps, 4, 4)
	Kit.list(steps, 4, true)
	stepButtons.look = Kit.button(
		"1  Look",
		{ Parent = steps, Size = UDim2.new(0.5, -2, 1, 0), TextSize = 18, Radius = "pill" },
		function()
			showStep("look")
		end
	)
	stepButtons.profile = Kit.button(
		"2  Name and personality",
		{ Parent = steps, Size = UDim2.new(0.5, -2, 1, 0), TextSize = 18, Radius = "pill" },
		function()
			showStep("profile")
		end
	)

	lookPage = Kit.box({ Parent = panel, Size = UDim2.new(1, 0, 1, -58), Position = UDim2.fromOffset(0, 58) })
	profilePage =
		Kit.box({ Parent = panel, Size = UDim2.new(1, 0, 1, -58), Position = UDim2.fromOffset(0, 58), Visible = false })

	-- The sections, as a block of tiles in a dark well of their own (an icon over a name on the
	-- tile's band; the picked one yellow with dark words, as in Build mode's categories). There
	-- are more of them than fit across, and a row that scrolled sideways hid the last ones from
	-- anyone without a touch screen, so they wrap: eight to a row, every one in reach.
	local ICONS = {
		wearing = "person",
		hair = "hair",
		heads = "smile",
		accessories = "hat",
		tops = "shirt",
		bottoms = "pants",
		shoes = "shoe",
		bodies = "figure",
		parts = "limbs",
		moves = "music",
		skin = "brush",
		shape = "ruler",
		inventory = "backpack",
		outfits = "hanger",
		avatars = "idcard",
		people = "people",
	}
	local PER_ROW, CELL_W, CELL_H, GAP_X, GAP_Y, WELL = 8, 87, 60, 2, 4, 5
	local railRows = math.ceil(#Categories.Tabs / PER_ROW)
	local railH = railRows * CELL_H + (railRows - 1) * GAP_Y
	local railWell = Kit.frame({
		Name = "RailWell",
		Parent = lookPage,
		Size = UDim2.new(1, 0, 0, railH + WELL * 2),
		Color = T.PaperDark,
		Radius = 14,
	})
	Kit.rim(railWell, T.Line, 1)
	local rail = Kit.box({
		Name = "Rail",
		Parent = railWell,
		Size = UDim2.new(1, -WELL * 2, 0, railH),
		Position = UDim2.fromOffset(WELL, WELL),
	})
	local railGrid = Kit.grid(rail, UDim2.fromOffset(CELL_W, CELL_H), GAP_X)
	railGrid.CellPadding = UDim2.fromOffset(GAP_X, GAP_Y)
	railGrid.FillDirectionMaxCells = PER_ROW
	local railButtons: { [string]: TextButton } = {}
	local function markRail(id: string)
		for bid, b in railButtons do
			local on = bid == id
			Kit.setButtonColor(b, if on then T.Yellow else T.Card, if on then T.Dark else T.Ink)
		end
	end
	for i, t in Categories.Tabs do
		local b = Kit.tile(ICONS[t.id] or "person", t.name, {
			Parent = rail,
			LayoutOrder = i,
			Size = UDim2.fromOffset(CELL_W, CELL_H),
			Color = T.Card,
			TextSize = 13,
		}, function()
			filterIndex = 1
			markRail(t.id)
			selectTab(t.id)
		end)
		railButtons[t.id] = b
	end
	markRail(tabId)
	markTab = markRail
	local browse = Kit.box({
		Parent = lookPage,
		Size = UDim2.new(1, 0, 1, -(railH + WELL * 2 + 12)),
		Position = UDim2.fromOffset(0, railH + WELL * 2 + 12),
	})

	-- the search box and the sort, one row the width of the panel, as tall as the filters under
	-- it (what was typed and the sort picked are kept when the screen is built again)
	local SORT_W = 170
	searchRow = Kit.box({ Name = "Search", Parent = browse, Size = UDim2.new(1, 0, 0, ROW_H) })
	local well = Kit.frame({
		Name = "Well",
		Parent = searchRow,
		Size = UDim2.new(1, -(SORT_W + 8), 1, 0),
		Color = T.PaperDark,
		Radius = "pill",
	})
	Kit.rim(well, T.Line, 1)
	local lean = 6 -- clear of its round end
	Icons.make("zoom", 18, {
		Parent = searchRow,
		Position = UDim2.new(0, lean + 8, 0.5, -9),
		Color = T.InkSoft,
		Hole = T.PaperDark,
		ZIndex = 2,
	})
	searchBox = Kit.textbox("Search the catalog", {
		Parent = searchRow,
		Size = UDim2.new(1, -(SORT_W + 8 + lean * 2 + 32), 1, 0),
		Text = keyword,
		TextSize = 16,
	})
	searchBox.Position = UDim2.fromOffset(lean + 32, 0)
	searchBox.BackgroundTransparency = 1
	searchBox.ZIndex = 2
	local boxPad = searchBox:FindFirstChildOfClass("UIPadding")
	if boxPad then
		boxPad.PaddingLeft = UDim.new(0, 4)
	end
	searchBox.FocusLost:Connect(function()
		keyword = Text.clean(searchBox.Text):sub(1, 50)
		search()
	end)
	local function sortWords(id: string): string
		local name = Categories.Sorts[1].name
		for _, sort in Categories.Sorts do
			if sort.id == id then
				name = sort.name
			end
		end
		return Text.fill("Sort: {name}", { name = name })
	end
	sortButton = Kit.button(sortWords(sortId), {
		Name = "Sort",
		Parent = searchRow,
		Size = UDim2.fromOffset(SORT_W, ROW_H),
		Position = UDim2.new(1, -SORT_W, 0, 0),
		Color = T.Card,
		TextColor = T.Ink,
		TextSize = 15,
	})
	sortButton.Activated:Connect(function()
		local i = 1
		for k, sort in Categories.Sorts do
			if sort.id == sortId then
				i = k
			end
		end
		local nextSort = Categories.Sorts[i % #Categories.Sorts + 1]
		sortId = nextSort.id
		sortButton.Text = sortWords(sortId)
		search()
	end)
	filterRow = Kit.scroll({
		Name = "Filters",
		Parent = browse,
		Size = UDim2.new(1, 0, 0, ROW_H),
		Position = UDim2.fromOffset(0, ROW_H + 8),
		Axis = Enum.AutomaticSize.X,
	})
	filterRow.ScrollBarThickness = 3
	Kit.list(filterRow, 4, true)

	content = Kit.box({
		Parent = browse,
		Size = UDim2.new(1, 0, 1, -(ROW_H + 8) * 2),
		Position = UDim2.fromOffset(0, (ROW_H + 8) * 2),
	})
	grid = Kit.scroll({ Parent = content, Size = UDim2.new(1, 0, 1, -48) })
	grid.ScrollBarThickness = 4
	grid.VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar
	-- five cards to a row, spaced to fill the panel's width
	local cardGrid = Kit.grid(grid, UDim2.fromOffset(128, 160), 12)
	cardGrid.CellPadding = UDim2.fromOffset(math.floor((PANEL_W - 4 - 5 * 128) / 4), 12)
	loadMore = Kit.button("Show more", {
		Parent = content,
		Size = UDim2.new(1, 0, 0, 40),
		Position = UDim2.new(0, 0, 1, -40),
		Color = T.Blue,
		TextSize = 17,
		Icon = "down",
	}, more)

	-- the tools under the villager, in one card at the bottom left: copy someone's avatar, then
	-- a row of tiles (an icon over its name, as in Build mode's tools), each part under a dim
	-- caption of its own
	local TOOL_W, TOOL_H, CARD_PAD, CAP_H = 64, 60, 12, 20
	local toolList = {
		{ "undo", "Undo", undo },
		{ "redo", "Redo", redo },
		{ "dice", "Shuffle", shuffle },
		{
			"trash",
			"Reset",
			function()
				setApp(Appearance.default())
			end,
		},
		-- one button steps through the three distances, for whoever has no wheel and no second finger
		{
			"zoom",
			"Zoom",
			function()
				if zoom > (ZOOM_HOME + ZOOM_WHOLE) / 2 then
					zoom = ZOOM_FACE
				elseif zoom > (ZOOM_FACE + ZOOM_HOME) / 2 then
					zoom = ZOOM_WHOLE
				else
					zoom = ZOOM_HOME
				end
			end,
		},
		-- dark or light, here as well as on the main screen (the user asked for it with this
		-- screen: "along with the option to change to light mode"); it names the look you would get
		{ Theme.icon(), if Theme.name() == "dark" then "Light" else "Dark", Theme.toggle },
	}
	local cardW = #toolList * TOOL_W + CARD_PAD * 2
	local toolCard = Kit.frame({
		Name = "Tools",
		Size = UDim2.fromOffset(cardW, CARD_PAD * 2 + CAP_H * 2 + ROW_H + 12 + TOOL_H),
		Position = UDim2.new(0, 16, 1, -14),
		AnchorPoint = Vector2.new(0, 1),
		Color = T.Paper,
		Cut = 12,
		Parent = frame,
	})
	Kit.softShadow(toolCard, 1)
	local function caption(text: string, y: number)
		Kit.text(text, {
			Name = "Caption",
			Parent = toolCard,
			Size = UDim2.new(1, -CARD_PAD * 2 - 8, 0, CAP_H - 4),
			Position = UDim2.fromOffset(CARD_PAD + 4, y),
			TextSize = 13,
			Font = Kit.Fonts.Bold,
			Color = T.InkSoft,
		})
	end
	caption("Copy an avatar", CARD_PAD - 2)
	local copy = Kit.box({
		Name = "Copy",
		Parent = toolCard,
		Size = UDim2.new(1, -CARD_PAD * 2, 0, ROW_H),
		Position = UDim2.fromOffset(CARD_PAD, CARD_PAD + CAP_H),
	})
	local userBox =
		inputWell("A Roblox username", { Parent = copy, Size = UDim2.new(1, -168, 0, ROW_H), TextSize = 15 })
	Kit.button("Copy", {
		Parent = copy,
		Size = UDim2.fromOffset(84, ROW_H),
		Position = UDim2.new(1, -164, 0, 0),
		Color = T.Blue,
		TextSize = 16,
	}, function()
		local name = Text.clean(userBox.Text)
		if name == "" then
			Toasts.show("Type a Roblox username to copy their avatar.", "info")
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
		Size = UDim2.fromOffset(76, ROW_H),
		Position = UDim2.new(1, -76, 0, 0),
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
	-- a quiet line between the two parts
	Kit.frame({
		Name = "Divider",
		Parent = toolCard,
		Size = UDim2.new(1, -CARD_PAD * 2, 0, 1),
		Position = UDim2.fromOffset(CARD_PAD, CARD_PAD + CAP_H + ROW_H + 6),
		Color = T.Line,
		Radius = false,
	})
	caption("Tools", CARD_PAD + CAP_H + ROW_H + 10)
	local toolRow = Kit.box({
		Parent = toolCard,
		Size = UDim2.new(1, -CARD_PAD * 2, 0, TOOL_H),
		Position = UDim2.fromOffset(CARD_PAD, CARD_PAD + CAP_H * 2 + ROW_H + 12),
	})
	Kit.list(toolRow, 0, true)
	for i, t in toolList do
		Kit.tile(t[1], t[2], {
			Parent = toolRow,
			Size = UDim2.fromOffset(TOOL_W, TOOL_H),
			LayoutOrder = i,
			Color = T.Paper,
		}, t[3])
	end
	local tip = Kit.darkPill({
		Parent = frame,
		Size = UDim2.fromOffset(0, 34),
		Position = UDim2.fromOffset(16, 68),
	})
	tip.AutomaticSize = Enum.AutomaticSize.X
	Kit.pad(tip, 8, 0)
	Kit.text("Drag to turn them round. Scroll or pinch to zoom.", {
		Parent = tip,
		Size = UDim2.fromOffset(0, 34),
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
	if access == "asking" then
		-- a question left unanswered the last time: it can be put again
		access = "unasked"
	end
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

-- The screen is built once and kept. After a change of look it is built again where it was (the
-- step, the tab and what they wear are kept); shut, it is simply built afresh the next time.
Kit.onTheme(function()
	local old = root
	if not old then
		return
	end
	local title = if titleLabel then titleLabel.Text else nil
	old:Destroy()
	root = nil
	titleLabel = nil
	if not isOpen then
		return
	end
	build()
	if title then
		setTitle(title)
	end
	showStep(stepNow)
	selectTab(tabId)
	refreshWorn()
	paintStudio()
end)

return Creator
