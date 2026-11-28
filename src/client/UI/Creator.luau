-- The villager creator. Works like a catalog avatar editor: browse or search the whole Roblox
-- catalog by category, click to wear or take off, mix bundles (bodies, heads, animations, shoes)
-- and single body parts, wear what you own on Roblox or an avatar you saved there, set skin
-- colours and body shape, copy any player's avatar, save outfits, undo and redo.
-- The look is shown on a mannequin on a private stage; then you give them a name and a personality.
-- The You tab edits the player's own look the same way, worn on their character in this game.

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
local ColorWords = require(Shared.Avatar.ColorWords)
local Shuffle = require(Shared.Avatar.Shuffle)
local Shop = require(Shared.Avatar.Shop)
local Likes = require(Shared.Avatar.Likes)
local Personalities = require(Shared.Data.Personalities)
local Palette = require(Shared.Data.Palette)
local Colors = require(Shared.Util.Colors)
local Text = require(Shared.Util.Text)
local City = require(Shared.Sim.City)
local Tuning = require(Shared.Config.Tuning)

local Kit = require(script.Parent.Kit)
local Icons = require(script.Parent.Icons)
local Toasts = require(script.Parent.Toasts)
local Theme = require(script.Parent.Theme)
local ColorWheel = require(script.Parent.ColorWheel)
local BuyLook = require(script.Parent.BuyLook)
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
-- "new", "edit" or "self": your own look (the user: "add another tab to edit self in the catalog
-- just like editing villagers"). While you are on yourself, the villager you were making waits here.
local stash: any = nil
local markMode: ((string) -> ())? = nil
-- The colour searched for, from the colour wheel (the user: "allow players to search things in the
-- creator by color, with a color picker wheel"), and the colour word the catalog is searched with.
local colorPick: Color3? = nil
local colorWord: string? = nil
local sharedSort = "new" -- the Shared tab's order: "new" or "likes" (Avatar/Likes)
local ownLook: any = nil -- the player's own Roblox avatar as a look, which seeds Shuffle
local createdEvent = Instance.new("BindableEvent")
Creator.Created = createdEvent.Event -- (vid, name): a villager made in the creator has moved in

-- browsing
local tabId = "hair"
local filterIndex = 1
local keyword = ""
-- The tabs of your own things and other players' looks search them by name as you type (the
-- user: "allow for search in friends, shared outfits, my items, and outfits"), in the same box
-- the catalog is searched in; what is typed there is `find`, and each says what it looks through.
local FIND = {
	people = "Search players",
	shared = "Search looks",
	outfits = "Search outfits",
	inventory = "Search items",
	avatars = "Search avatars",
}
local find = ""
local findToken = 0
-- where the colour wheel searches nothing (the colour stays picked for the other tabs)
local NO_COLOUR = { wearing = true, shape = true, people = true }
local function colourHere(): boolean
	return colorPick ~= nil and not NO_COLOUR[tabId]
end
-- What the catalog is searched for: what was typed and the picked colour's word.
local function searchWords(): string
	if colorWord then
		return Text.clean(keyword .. " " .. colorWord)
	end
	return keyword
end
-- every row My items or My avatars has had so far, for its search to look through
local loaded: { any } = {}
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
local colourButton: TextButton? = nil -- the round colour button at the search box's end
local colourTag: TextButton? = nil -- the picked colour's word, under it, with a cross to clear it
local colourPop: Instance? = nil -- the colour wheel, while it is open
local lookPage: Frame
local profilePage: Frame
local stepButtons: { [string]: TextButton } = {}
local titleLabel: TextLabel? = nil
local titleGhost: TextLabel? = nil -- the title again, large and faint, behind it
local stepCaption: TextLabel? = nil -- which step this is, set wide under the title
local selectTab: (string) -> ()
local switchMode: (string) -> ()
local markTab: ((string) -> ())? = nil
local profile = { name = "", pers = "sunny", color = "4FA9D9", bday = { s = 1, d = 1 } }
local nameField: TextBox? = nil -- the name box on the second step, once that step has been built

-- A villager made to look like somebody takes their name too, ready to change on the next step.
-- The user: "when selecting friend, also add their name to the name field". One who is being
-- edited and already has a name keeps it: picking a friend's look must not rename them unseen.
local function takeName(name: string)
	if mode == "edit" and Text.clean(profile.name) ~= "" then
		return
	end
	local short = Text.clean(name)
	local cut = utf8.offset(short, Tuning.Villagers.NameMaxLength + 1)
	if cut then
		short = short:sub(1, cut - 1)
	end
	if short == "" then
		return
	end
	profile.name = short
	local box = nameField
	if box and box.Parent then
		box.Text = short
	end
end
local paintStudio: () -> ()
local panelFrame: Frame? = nil -- the panel on the right, which glows in their favourite colour
local PANEL_W, PANEL_PAD = 720, 12 -- what the panel holds is this wide, inside this margin
local ROW_H = 36 -- the boxes to type in on the pages are this tall
-- the Look step: the search box and the row of sections, the row of kinds under them, the copy
-- box and the tools along the bottom
local SEARCH_W, SECTION_H, FILTER_H = 236, 36, 28
local SORT_W = 168
local ARROW = 26 -- the round arrows at each end of the row of sections
local WORD_PAD = 12 -- room each side of a word in the rows
local BOTTOM_H, CAPTION_H, TOOL_SQ = 40, 16, 40

-- How wide a line of words is in the title font, for laying the row of sections out. (The engine
-- measures it; a reckoning by its letters stands in where it can't.)
local function textWidth(text: string, size: number): number
	local ok, bounds = pcall(function()
		return game:GetService("TextService"):GetTextSize(text, size, Kit.Fonts.Title, Vector2.new(2000, 200))
	end)
	if ok and typeof(bounds) == "Vector2" and bounds.X > 0 then
		return math.ceil(bounds.X)
	end
	return math.ceil(#text * size * 0.56)
end

-- The sort button's words on the Shared tab.
local function sharedSortWords(): string
	local name = Likes.Sorts[1].name
	for _, sort in Likes.Sorts do
		if sort.id == sharedSort then
			name = sort.name
		end
	end
	return Text.fill("Sort: {name}", { name = name })
end

-- The sort button's words.
local function sortWords(id: string): string
	local name = Categories.Sorts[1].name
	for _, sort in Categories.Sorts do
		if sort.id == id then
			name = sort.name
		end
	end
	return Text.fill("Sort: {name}", { name = name })
end

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
local buyable: (any) -> boolean

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
			Toasts.show("Some of that can't be worn there, so it came off.", "warn")
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
				Toasts.show("Couldn't open that set just now.", "warn")
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
		Toasts.show("That can't be worn.", "warn")
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

-- What a card's small line says it is.
local KINDS: { [string]: string } = {
	HairAccessory = "Hair",
	Hat = "Hat",
	FaceAccessory = "Glasses",
	NeckAccessory = "Neck",
	ShoulderAccessory = "Shoulder",
	FrontAccessory = "Front",
	BackAccessory = "Back",
	WaistAccessory = "Waist",
	Shirt = "Shirt",
	TShirt = "T-shirt",
	TShirtAccessory = "3D top",
	ShirtAccessory = "3D top",
	SweaterAccessory = "3D top",
	JacketAccessory = "3D top",
	Pants = "Pants",
	PantsAccessory = "3D bottom",
	ShortsAccessory = "3D bottom",
	DressSkirtAccessory = "3D bottom",
	LeftShoeAccessory = "Shoe",
	RightShoeAccessory = "Shoe",
	Face = "Face",
	Head = "Head",
	DynamicHead = "Head",
	EyebrowAccessory = "Brows",
	EyelashAccessory = "Lashes",
	Torso = "Torso",
	LeftArm = "Left arm",
	RightArm = "Right arm",
	LeftLeg = "Left leg",
	RightLeg = "Right leg",
}
local SET_KINDS: { [string]: string } =
	{ body = "Whole body", head = "Head set", shoes = "Pair of shoes", anim = "Set of moves" }

local function kindOf(item: any, kind: string?): string
	if item.ItemType == "Outfit" then
		return "Saved avatar"
	elseif item.ItemType == "Bundle" then
		return SET_KINDS[kind or ""] or "Set"
	end
	local typeName = Categories.assetTypeName(item.AssetType)
	if typeName and KINDS[typeName] then
		return KINDS[typeName]
	elseif typeName and typeName:find("Animation") then
		return "Move"
	end
	return "Item"
end

-- Can a card's thing be bought by itself on Roblox? A set can; an asset can unless the row says
-- it is off sale, or it is a body part or a move (only ever sold inside a set).
local NOT_SOLD = {
	Head = true,
	DynamicHead = true,
	Torso = true,
	LeftArm = true,
	RightArm = true,
	LeftLeg = true,
	RightLeg = true,
}
function buyable(item: any): boolean
	if item.ItemType == "Bundle" then
		return Shop.forSale(item) ~= false
	elseif item.ItemType ~= "Asset" then
		return false
	end
	local typeName = Categories.assetTypeName(item.AssetType)
	if typeName and (NOT_SOLD[typeName] or typeName:find("Animation")) then
		return false
	end
	return Shop.forSale(item) ~= false
end

-- What they have on is picked, so its picture's square is yellow with a tick on its corner and
-- its small line says "Wearing" (on Wearing everything is on, so there only the tick shows).
refreshWorn = function()
	for id, card in cards do
		local worn = isOn(id)
		local lit = worn and tabId ~= "wearing"
		local face = card:FindFirstChild("Square")
		if face and face:IsA("Frame") then
			face.BackgroundColor3 = if lit then T.Yellow else T.Card
		end
		local sub = card:FindFirstChild("Sub", true)
		if sub and sub:IsA("TextLabel") then
			local plain = card:GetAttribute("Kind")
			sub.Text = if worn and tabId ~= "wearing"
				then "Wearing"
				else (if type(plain) == "string" then plain else "")
			sub.TextColor3 = if worn and tabId ~= "wearing" then Kit.tint(T.Yellow) else T.InkSoft
		end
		local badge = card:FindFirstChild("Worn")
		if badge and badge:IsA("GuiObject") then
			badge.Visible = worn
		end
		local buy = card:FindFirstChild("Buy")
		if buy and buy:IsA("GuiObject") then
			buy.Visible = worn
		end
	end
end

-- A card for something to wear, laid out as catalog screens lay theirs: the picture on a rounded
-- dark square in a thin rim, under it the name in bold on up to two lines, and under that one
-- small line saying what it is ("Hat", "Whole body", "Wearing" for what they have on). What they
-- have on has its square yellow and a tick on its corner. Five to a row.
local CARD_W, CARD_PIC = 136, 136
local CARD_H = CARD_PIC + 4 + 34 + 16
local function itemCard(item: any, order: number, onClick: (() -> ())?, kind: string?): GuiObject
	local card = Kit.new("TextButton", {
		Name = "Item",
		Text = "",
		AutoButtonColor = false,
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(CARD_W, CARD_H),
		LayoutOrder = order,
		Parent = grid,
	})
	card:SetAttribute("ItemCard", true)
	card:SetAttribute("Kind", kindOf(item, kind))
	local face = Kit.frame({
		Name = "Square",
		Parent = card,
		Size = UDim2.fromOffset(CARD_W, CARD_PIC),
		Color = T.Card,
		Radius = 12,
	})
	local picture = Kit.frame({
		Name = "Picture",
		Parent = face,
		Size = UDim2.new(1, -16, 1, -16),
		Position = UDim2.fromOffset(8, 8),
		Color = T.Picture,
		Radius = 8,
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
	-- the tick on what they have on: a dark disc with a yellow check, on the square's corner
	local worn = Kit.disc({
		Name = "Worn",
		Parent = card,
		Size = 24,
		Position = UDim2.fromOffset(CARD_W - 6, 6),
		AnchorPoint = Vector2.new(1, 0),
		Color = T.Dark,
		Icon = "check",
		IconColor = T.Yellow,
		Ring = T.Yellow,
		ZIndex = 4,
	})
	worn.Visible = false
	-- Buy, on what they have on (the user: "allow players to buy items they select from the
	-- villager customization screen"): Roblox's own prompt for that item
	if buyable(item) then
		local buy = Kit.new("TextButton", {
			Name = "Buy",
			Text = "",
			AutoButtonColor = false,
			BackgroundColor3 = T.Green,
			Size = UDim2.fromOffset(30, 30),
			Position = UDim2.fromOffset(CARD_W - 6, CARD_PIC - 6),
			AnchorPoint = Vector2.new(1, 1),
			ZIndex = 5,
			Visible = false,
			Parent = card,
		})
		Kit.corner(buy, "round")
		Icons.make("cart", 18, {
			Name = "IconArt",
			Parent = buy,
			Position = UDim2.new(0.5, -9, 0.5, -9),
			Color = T.White,
			Hole = T.Green,
			ZIndex = 6,
			Centre = true,
		})
		Kit.press(buy, { Kind = "round" })
		buy.Activated:Connect(function()
			BuyLook.item(item.Id, item.ItemType == "Bundle")
		end)
	end
	-- the name in bold on up to two lines, the small line straight under it
	local words = Kit.box({
		Name = "Words",
		Parent = card,
		Size = UDim2.new(1, -4, 0, 50),
		Position = UDim2.fromOffset(2, CARD_PIC + 5),
	})
	Kit.list(words, 1)
	local name = Kit.title(item.Name or "", {
		Name = "Name",
		Parent = words,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		TextSize = 15,
		AlignY = Enum.TextYAlignment.Top,
		LayoutOrder = 1,
		ZIndex = 2,
	})
	name.TextTruncate = Enum.TextTruncate.AtEnd
	Kit.new("UISizeConstraint", { MaxSize = Vector2.new(math.huge, 34), Parent = name })
	Kit.text(card:GetAttribute("Kind") :: string, {
		Name = "Sub",
		Parent = words,
		Size = UDim2.new(1, 0, 0, 16),
		TextSize = 13,
		Font = Kit.Fonts.Bold,
		Color = T.InkSoft,
		Wrap = false,
		LayoutOrder = 2,
		ZIndex = 2,
	})
	-- the interface's own motion: a band of light across the square, brackets closing in on the
	-- card, a dip and a flash when pressed
	Kit.press(card, { Kind = "tile", Face = face })
	card.Activated:Connect(function()
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
		return "You don't own any."
	elseif tab and tab.source == "outfits" then
		return if f and f.outfits == "Purchased" then "None bought yet." else "None saved yet."
	end
	return "Nothing found."
end

-- `again` shows the rows already had once more (the search on My items or My avatars changed).
local function showItems(items: { any }, append: boolean?, again: boolean?)
	if not append then
		clearGrid()
		forgetCards()
	end
	note(nil)
	if not again then
		if not append then
			loaded = {}
		end
		for _, item in items do
			table.insert(loaded, item)
		end
		remember(items)
	end
	local tab = currentTab()
	-- (only your own things are searched here, by name and by the colour's word: the catalog is
	-- searched by Roblox)
	local own = tab ~= nil and tab.source ~= nil
	local filtering = own and (find ~= "" or colourHere())
	local f = currentFilter()
	local kind = if f then f.kind else nil
	local n = #grid:GetChildren()
	for i, item in items do
		local fits = not filtering
			or (Text.matches(find, item.Name) and (not colourHere() or ColorWords.named(item.Name, colorWord)))
		if type(item.Id) == "number" and fits then
			itemCard(item, n + i, nil, kind)
		end
	end
	refreshWorn()
	loadMore.Visible = pages ~= nil and not pages.IsFinished
	if next(cards) == nil then
		if filtering then
			note(if loadMore.Visible then "None yet. Load more to look further." else "None found.")
		else
			note(nothingText(tab, f))
		end
	end
end

-- The sort a search runs in. With nothing typed and no sort picked, a filter may have a better
-- order to browse in than the catalog's own.
local function sortFor(f: any): string
	if f.browse and searchWords() == "" and sortId == "Relevance" then
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
	params.SearchKeyword = searchWords()
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
		keyword = searchWords(),
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
	inventory = "Loading your items...",
	outfits = "Loading your avatars...",
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
	note(LOOKING[tab.source] or "Searching...")
	task.spawn(function()
		local items, p, rows = fetch(tab, f)
		if token ~= searchToken or not isOpen then
			return
		end
		if not items then
			note("Roblox didn't answer.", "Try again", search)
			return
		end
		pages, pageRows = p, rows
		if searchWords() == "" and not tab.source then
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

-- Shuffle (the user: "for shuffle the whole look, make it such that it chooses from the ones
-- roblox recommends to the player the most"): for each slot in Avatar/Shuffle, Roblox's
-- recommendations seeded by what is worn there or by what the player wears on Roblox, a pick among
-- the first few; where Roblox recommends nothing, the catalog's most popular page stands in. A
-- body set worn is swapped for one Roblox recommends after it. One undo step for all of it.

-- Roblox's recommendations of one asset type (seeded by an asset of that type), as card rows.
local function recommended(typeName: string, seed: number?): { any }
	local kind = (Enum.AvatarAssetType :: any)[typeName]
	if not kind then
		return {}
	end
	for _, method in { "GetRecommendedAssetsAsync", "GetRecommendedAssets" } do
		local ok, result = pcall(function()
			return (AvatarEditorService :: any)[method](AvatarEditorService, kind, seed)
		end)
		if ok then
			return Shuffle.rows(result, typeName)
		end
	end
	return {}
end

local function recommendedSets(bundleId: number): { any }
	for _, method in { "GetRecommendedBundlesAsync", "GetRecommendedBundles" } do
		local ok, result = pcall(function()
			return (AvatarEditorService :: any)[method](AvatarEditorService, bundleId)
		end)
		if ok then
			return Shuffle.bundleRows(result)
		end
	end
	return {}
end

-- The catalog's popular page of one asset type (kept for the session), when Roblox recommends
-- nothing.
local function popular(typeName: string): { any }
	local key = "shuffle:" .. typeName
	local cached = resultCache[key]
	if not cached then
		local oldKeyword, oldWord, oldSort = keyword, colorWord, sortId
		keyword, colorWord, sortId = "", nil, "Bestselling"
		cached = searchCatalog({ id = key, assets = { typeName } })
		keyword, colorWord, sortId = oldKeyword, oldWord, oldSort
		resultCache[key] = cached
	end
	return cached or {}
end

-- The bundles worn now that the creator has looked up: { id, part }.
local function wornSets(look: any): { any }
	local out = {}
	local seen = {}
	for key, part in bundleParts do
		local id = tonumber(key:match(":(%d+)$"))
		if id and not seen[id] and Categories.bundleWorn(look, part) then
			seen[id] = true
			table.insert(out, { id = id, part = part, kind = key:match("^(%a*):") })
		end
	end
	return out
end

local shuffling = false
local function shuffle()
	if shuffling then
		return
	end
	shuffling = true
	task.spawn(function()
		if not ownLook then
			local ok, look = pcall(function()
				return Remotes.fn("CreatorFromUser"):InvokeServer("")
			end)
			ownLook = if ok and look then Appearance.sanitize(look) else Appearance.default()
		end
		local new = Appearance.sanitize(app)
		local top = Tuning.CreatorMore.ShuffleTop
		-- a body set: one Roblox recommends after the one worn
		for _, set in wornSets(new) do
			if set.kind == "body" then
				local rows = recommendedSets(set.id)
				local pick = Shuffle.pick(rows, math.random(), top, { [set.id] = true })
				local part = pick and Remotes.fn("CreatorBundle"):InvokeServer(pick.Id, "body")
				if pick and part then
					bundleParts[bundleKey(pick.Id, "body")] = part
					new = Categories.merge(new, part)
				end
				break
			end
		end
		for _, slot in Shuffle.Slots do
			if slot.chance and math.random() > slot.chance then
				continue
			end
			local seed = Shuffle.seed(new, ownLook, slot.type)
			local rows = recommended(slot.type, seed)
			if #rows == 0 and slot.type ~= "Face" then
				-- (no faces are on sale any more: none popular to fall back on)
				rows = popular(slot.type)
			end
			local worn = Shuffle.wornIn(new, slot.type)
			local pick = Shuffle.pick(rows, math.random(), top, if worn then { [worn] = true } else nil)
			if pick then
				remember({ pick })
				new = Shuffle.wear(new, pick, slot)
			end
		end
		local skin = Appearance.SkinTones[math.random(1, 10)]
		for _, k in { "head", "la", "ra", "ll", "rl", "torso" } do
			new.colors[k] = skin
		end
		new.scale.height = math.random(90, 110) / 100
		new.scale.width = math.random(80, 100) / 100
		shuffling = false
		if isOpen then
			setApp(new)
		end
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
		note("Nothing on yet.")
		return
	end
	note(nil)
	local unknown = {}
	for i, a in assets do
		local info = itemInfo[a.id]
		if not info then
			table.insert(unknown, a.id)
		end
		local item = {
			Id = a.id,
			Name = if info then info.name else "Worn item",
			ItemType = "Asset",
			AssetType = if info then info.type else nil,
		}
		itemCard(item, i, function()
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
		local hint = Kit.hint("Click to take it off.", { Parent = content })
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
	-- a leaning well, the words kept clear of its slanted ends
	local well = Kit.frame({ Name = "Well", Parent = holder, Color = T.PaperDark, Radius = false })
	local lean = Kit.slant(well, h) + 2
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
-- whatever is clicked. Returns the grid and a function that rings a colour. The swatches have no
-- border (the user: "remove the borders around the rectangles ... eveywhere").
local function colourGrid(
	parent: Instance,
	list: { string },
	px: number,
	current: string?,
	onPick: (string) -> (),
	order: number,
	across: number? -- (so many to a row, filling it: the favourite colours' grid)
): (Frame, (string?) -> ())
	local ring = 3
	local gap = 4
	local g = Kit.box({
		Parent = parent,
		Size = UDim2.new(1, -10, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = order,
	})
	local layout = Kit.grid(g, UDim2.fromOffset(px + ring * 2, px + ring * 2), gap)
	if across then
		-- that many to a row, stretched across the whole of it with no gap left at the right (the
		-- user: "for the color, make it fill horizontally instead of leaving a gap at the right")
		layout.FillDirectionMaxCells = across
		layout.CellSize = UDim2.new(1 / across, -math.ceil(gap * (across - 1) / across), 0, px + ring * 2)
		layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	end
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
			Radius = if across then 7 else "round",
			Visible = false,
		})
		local b = Kit.swatch(Colors.fromHex(hex), px, function()
			mark(hex)
			onPick(hex)
		end, { Parent = cell })
		b.Position = UDim2.fromOffset(ring, ring)
		if across then
			-- (little rounded rectangles, as wide as the row lets them be)
			b.Size = UDim2.new(1, -ring * 2, 1, -ring * 2)
			local corner = b:FindFirstChildOfClass("UICorner")
			if corner then
				corner.CornerRadius = UDim.new(0, 4)
			end
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
	local function heading(text: string, order: number)
		Kit.text(
			text,
			{ Parent = holder, TextSize = 15, Font = Kit.Fonts.Bold, Color = T.InkSoft, LayoutOrder = order }
		)
	end
	if colorPick then
		-- the colour from the wheel itself, then the tones and colours near it, nearest first
		local near = Tuning.CreatorMore.ColorNear
		local most = Tuning.CreatorMore.ColorShown
		heading("Picked colour", 2)
		local _, exact = colourGrid(holder, { Colors.toHex(colorPick) }, 36, now(), pick, 3)
		marks = { exact }
		local tones = ColorWords.near(Appearance.SkinTones, colorPick, near, most)
		if #tones > 0 then
			heading("Skin tones", 4)
			local _, a = colourGrid(holder, tones, 36, now(), pick, 5)
			table.insert(marks, a)
		end
		local any = ColorWords.near(Palette.Colors, colorPick, near, most)
		if #any > 0 then
			heading("Any colour", 6)
			local _, b = colourGrid(holder, any, 30, now(), pick, 7)
			table.insert(marks, b)
		end
		if #tones == 0 and #any == 0 then
			heading("Nothing else is close to it.", 8)
		end
		return
	end
	heading("Skin tones", 2)
	local _, a = colourGrid(holder, Appearance.SkinTones, 36, now(), pick, 3)
	heading("Any colour", 4)
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
		note("No outfits yet.")
		local n = content:FindFirstChild("Note")
		if n and n:IsA("GuiObject") then
			n.Position = UDim2.fromOffset(0, ROW_H + 12)
		end
	end
	local matching = 0
	for i, o in outfits do
		if not Text.matches(find, o.name) then
			continue
		end
		-- (and with a colour picked, only what goes with it: its name, or its own colours)
		if colourHere() and not ColorWords.lookMatches(o.name, o.app, colorPick, Tuning.CreatorMore.ColorNear) then
			continue
		end
		matching += 1
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
	if #outfits > 0 and matching == 0 then
		Kit.text("None found.", {
			Parent = list,
			Size = UDim2.new(1, -8, 0, 22),
			TextSize = 15,
			Color = T.InkSoft,
		})
	end
end

-- A "Show more" at the foot of a list on the Players or Shared tab, as the catalog tabs have
-- (the user: "add show more like the other tabs"). `fetch(page)` asks the server for that page
-- and returns whether there is another after it; the button hides while it asks, and stays
-- hidden when there is nothing more.
local function showMore(holder: Instance, order: number, fetch: (number) -> boolean?)
	local page = 1
	local busy = false
	local button: GuiButton
	button = Kit.button("Show more", {
		Name = "ShowMore",
		Parent = holder,
		Size = UDim2.new(1, -12, 0, 40),
		Color = T.Blue,
		TextSize = 17,
		Icon = "down",
		LayoutOrder = order,
	}, function()
		if busy then
			return
		end
		busy = true
		button.Visible = false
		task.spawn(function()
			local more = fetch(page + 1)
			busy = false
			if more == nil then
				button.Visible = holder.Parent ~= nil -- (it failed: left to press again)
				return
			end
			page += 1
			button.Visible = more
		end)
	end)
	button.Visible = false
	return function(more: boolean)
		button.Visible = more
	end
end

-- The Players tab: the people in this server and your friends as they look on Roblox (click
-- one and the villager wears it, and a new villager takes their name), a page at a time.
local function peoplePage()
	local holder = Kit.scroll({ Parent = content, Size = UDim2.fromScale(1, 1) })
	holder.ScrollBarThickness = 4
	Kit.list(holder, 8)
	Kit.text("People here and friends", {
		Name = "Caption",
		Parent = holder,
		Size = UDim2.new(1, -12, 0, 20),
		TextSize = 15,
		Font = Kit.Fonts.Bold,
		Color = T.InkSoft,
		LayoutOrder = 1,
	})
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
	local KINDS = { you = "You", here = "Here now", friend = "Friend" }
	local shown = 0
	local function add(person: any)
		shown += 1
		local card = Kit.new("TextButton", {
			Name = "Person",
			Text = "",
			AutoButtonColor = true,
			BackgroundColor3 = T.Card,
			LayoutOrder = shown,
			Parent = faces,
		})
		Kit.corner(card, 12)
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
					takeName(person.name)
				else
					Toasts.show("Couldn't load that avatar just now.", "warn")
				end
			end)
		end)
	end
	-- a page of people: true or false for whether there are more, nil if it couldn't be had
	local function fetch(page: number): boolean?
		local ok, data = pcall(function()
			return Remotes.fn("CreatorPeople"):InvokeServer(page, find)
		end)
		if not holder.Parent or not ok or type(data) ~= "table" then
			return nil
		end
		for _, person in data.people or {} do
			if type(person) == "table" and type(person.id) == "number" and type(person.name) == "string" then
				add(person)
			end
		end
		return data.more == true
	end
	local setMore = showMore(holder, 4, fetch)
	task.spawn(function()
		local more = fetch(1)
		if not holder.Parent then
			return
		end
		waiting:Destroy()
		if more == nil then
			Kit.text("Couldn't load anyone just now.", { Parent = faces, TextSize = 15, Color = T.InkSoft })
			return
		end
		if shown == 0 and find ~= "" then
			Kit.text("Nobody by that name.", {
				Parent = faces,
				TextSize = 15,
				Color = T.InkSoft,
			})
		end
		setMore(more)
	end)
end

-- The Shared tab: looks players of this game have shared from this creator, newest first or most
-- liked first (the sort pill), with a box to share the one you are making. A page at a time, like
-- the Players tab. Each has a like (the user: "for shared avatars, could there be a liking system
-- for it as well?"): one a player, pressed again to take it back, never on your own.
local function sharedPage()
	local holder = Kit.scroll({ Parent = content, Size = UDim2.fromScale(1, 1) })
	holder.ScrollBarThickness = 4
	Kit.list(holder, 8)
	local row = Kit.box({ Parent = holder, Size = UDim2.new(1, -12, 0, ROW_H), LayoutOrder = 1 })
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
					Toasts.show("Shared.", "good")
					task.wait(0.4)
					if isOpen and tabId == "shared" then
						selectTab("shared")
					end
				elseif err then
					Toasts.show(err, "warn")
				end
			end)
		end
	)
	Kit.text("Shared by players", {
		Name = "Caption",
		Parent = holder,
		Size = UDim2.new(1, -12, 0, 20),
		TextSize = 15,
		Font = Kit.Fonts.Bold,
		Color = T.InkSoft,
		LayoutOrder = 2,
	})
	local looks = Kit.box({
		Name = "Looks",
		Parent = holder,
		Size = UDim2.new(1, -12, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = 3,
	})
	Kit.list(looks, 6)
	local shown = 0
	local function add(look: any)
		shown += 1
		-- a pill row each: who made it in a round portrait, its name, and a way to wear it
		local _, inner = Kit.row({
			Name = "Look",
			Parent = looks,
			Height = 56,
			Title = look.name,
			Sub = Text.fill("by {who}", { who = look.who or "" }),
			TextSize = 17,
			LeftSpace = 58,
			RightSpace = 196,
			LayoutOrder = shown,
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
		-- the like: a heart and how many, pink once you have liked it
		local mine = look.by == player.UserId
		local liked = look.liked == true
		local likes = if type(look.likes) == "number" then look.likes else 0
		local heart: TextButton
		local function paint()
			heart.Text = tostring(likes)
			Kit.setButtonColor(heart, if liked then T.Pink else T.PaperDark, if liked then T.White else T.Ink)
		end
		local asking = false
		heart = Kit.button(tostring(likes), {
			Name = "Like",
			Parent = inner,
			Size = UDim2.fromOffset(80, 36),
			Position = UDim2.new(1, -104, 0.5, 0),
			AnchorPoint = Vector2.new(1, 0.5),
			Color = T.PaperDark,
			TextColor = T.Ink,
			TextSize = 16,
			Icon = "heart",
			ZIndex = 3,
		}, function()
			if mine then
				Toasts.show("That one's yours.", "info")
				return
			end
			if asking then
				return
			end
			asking = true
			task.spawn(function()
				local ok, result, why = pcall(function()
					return Remotes.fn("LookLike"):InvokeServer(look.by, look.at)
				end)
				asking = false
				if ok and type(result) == "table" then
					liked = result.liked == true
					likes = if type(result.likes) == "number" then result.likes else likes
					if heart.Parent then
						paint()
					end
				elseif ok and type(why) == "string" then
					Toasts.show(why, "warn")
				end
			end)
		end)
		heart:SetAttribute("Liked", liked)
		paint()
	end
	local function fetch(page: number): boolean?
		local ok, data = pcall(function()
			return Remotes.fn("CreatorShared"):InvokeServer(
				page,
				find,
				sharedSort,
				if colourHere() then Colors.toHex(colorPick :: Color3) else nil
			)
		end)
		if not holder.Parent or not ok or type(data) ~= "table" then
			return nil
		end
		for _, look in data.looks or {} do
			if type(look) == "table" and type(look.name) == "string" and type(look.by) == "number" then
				add(look)
			end
		end
		return data.more == true
	end
	local setMore = showMore(holder, 4, fetch)
	task.spawn(function()
		local more = fetch(1)
		if not holder.Parent then
			return
		end
		if more == nil then
			Kit.text("Couldn't load them just now.", { Parent = looks, TextSize = 15, Color = T.InkSoft })
			return
		end
		if shown == 0 and (find ~= "" or colourHere()) then
			Kit.text("None found.", {
				Parent = looks,
				TextSize = 15,
				Color = T.InkSoft,
			})
		elseif shown == 0 then
			Kit.hint("Nothing shared yet.", {
				Parent = looks,
			})
		end
		setMore(more)
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
		unasked = "Wear what you own on Roblox. Roblox asks you first.",
		no = "You said no, so your items stay hidden.",
		button = "Show my items",
	},
	outfits = {
		unasked = "Wear an avatar you saved on Roblox. Roblox asks you first.",
		no = "You said no, so your avatars stay hidden.",
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
		text = "Roblox is asking you now."
	elseif access == "no" then
		text, button = words.no, "Ask me again"
	elseif access == "failed" then
		text, button = "Roblox couldn't be asked just now.", "Try again"
	else
		text, button = words.unasked, words.button
	end
	note(text, button, if button then askAccess else nil)
end

-- Shows what the header offers for the section you are in: the search box and the sort only
-- where the catalog is searched (dimmed, and taking no words, where it isn't), the row of kinds
-- only where there is more than one.
-- A tab of your own things searches by name (`placeholder` says what) and has no sort.
local function layoutBrowse(showSearch: boolean, showFilterRow: boolean, placeholder: string?)
	searchBox.TextEditable = showSearch
	searchBox.PlaceholderText = if showSearch then placeholder or "Search" else "No search here"
	searchRow:SetAttribute("Off", not showSearch)
	local glass = searchRow:FindFirstChild("Glass")
	if glass then
		Kit.recolorIcon(glass, if showSearch then T.InkSoft else T.Line, T.PaperDark)
	end
	-- the Shared tab has a sort of its own: newest or most liked
	local sort = (showSearch and placeholder == nil) or tabId == "shared"
	sortButton.Visible = sort
	sortButton.Text = if tabId == "shared" then sharedSortWords() else sortWords(sortId)
	-- the colour button where a colour can be searched for, and the picked colour's word
	local colours = not NO_COLOUR[tabId] and (showSearch or tabId == "skin")
	local tagW = 0
	if colourButton then
		colourButton.Visible = colours
	end
	local tag = colourTag
	if tag then
		tag.Visible = colours and colorPick ~= nil
		tag.Position = UDim2.new(1, if sort then -(SORT_W + 8) else 0, 0, SECTION_H + 6)
		if tag.Visible then
			tagW = tag.Size.X.Offset + 8
		end
	end
	filterRow.Visible = showFilterRow
	filterRow.Size = UDim2.new(1, -((if sort then SORT_W + 8 else 0) + tagW), 0, FILTER_H)
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
	-- (your own things are searched by name, once Roblox has said this game may see them)
	local findWords = if FIND[tabId] and (not own or access == "yes") then FIND[tabId] else nil
	layoutBrowse((filters ~= nil and not own) or findWords ~= nil, open and #filters > 1, findWords)
	if not filters or not open then
		return
	end
	-- smaller words than the sections', the picked one underlined
	for i, f in filters do
		local on = i == filterIndex
		local b = Kit.new("TextButton", {
			Name = f.name,
			Text = f.name,
			Font = Kit.Fonts.Title,
			TextSize = 15,
			TextColor3 = if on then T.Ink else T.InkSoft,
			AutoButtonColor = false,
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(textWidth(f.name, 15) + WORD_PAD * 2, FILTER_H),
			LayoutOrder = i,
			Parent = filterRow,
		})
		Kit.frame({
			Name = "Underline",
			Parent = b,
			Size = UDim2.new(1, -WORD_PAD * 2 + 6, 0, 2),
			Position = UDim2.new(0, WORD_PAD - 3, 1, -3),
			Color = T.Yellow,
			Radius = "pill",
			Visible = on,
		})
		b.Activated:Connect(function()
			filterIndex = i
			showFilters(tab)
			search()
		end)
	end
end

-- The colour search ---------------------------------------------------------------------------------

-- The colour button and the tag show the colour picked (or the paint bucket, with none).
local function paintColour()
	local b = colourButton
	if b then
		local dot = b:FindFirstChild("Swatch")
		local art = b:FindFirstChild("IconArt")
		if dot and dot:IsA("GuiObject") then
			dot.Visible = colorPick ~= nil
			if colorPick then
				dot.BackgroundColor3 = colorPick
			end
		end
		if art and art:IsA("GuiObject") then
			art.Visible = colorPick == nil
		end
	end
	local tag = colourTag
	if tag and colorPick and colorWord then
		local word = colorWord:sub(1, 1):upper() .. colorWord:sub(2)
		local label = tag:FindFirstChild("Word")
		if label and label:IsA("TextLabel") then
			label.Text = word
		end
		local dot = tag:FindFirstChild("Swatch")
		if dot and dot:IsA("GuiObject") then
			dot.BackgroundColor3 = colorPick
		end
		tag.Size = UDim2.fromOffset(textWidth(word, 14) + 58, FILTER_H)
	end
end

local refreshPage: () -> ()

-- Picks a colour to search by (nil: none), and shows the tab again with it: the catalog searched
-- for its word (only when the word changes), your own things by their names, saved and shared
-- looks by their names and their own colours, the skin's colours by colour.
local function setColour(c: Color3?)
	local was = colorWord
	colorPick = c
	colorWord = if c then ColorWords.nearest(c).word else nil
	paintColour()
	local tab = currentTab()
	showFilters(tab)
	if not isOpen or NO_COLOUR[tabId] then
		return
	end
	if tab and tab.filters and not tab.source then
		if colorWord ~= was then
			search()
		end
	elseif tab and tab.source then
		if access == "yes" and grid.Visible then
			showItems(loaded, false, true)
		end
	else
		refreshPage()
	end
end

local function closeColour()
	local pop = colourPop
	if pop then
		pop:Destroy()
		colourPop = nil
	end
end

-- The colour wheel, dropped down over the cards from the colour button. It searches as soon as a
-- press on it is let go; Clear takes the colour away, and a click off it puts it away.
local function openColour()
	if colourPop then
		closeColour()
		return
	end
	local catcher = Kit.new("TextButton", {
		Name = "ColourCatcher",
		Text = "",
		AutoButtonColor = false,
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 40,
		Parent = lookPage,
	})
	catcher.Activated:Connect(closeColour)
	colourPop = catcher
	local R = 80
	local wheelW = R * 2 + math.floor(R / 4 * 0.94)
	local W = wheelW + 28
	local card = Kit.new("TextButton", {
		Name = "ColourCard",
		Text = "",
		AutoButtonColor = false,
		BackgroundColor3 = T.Paper,
		Size = UDim2.fromOffset(W, wheelW + 30 + 118),
		Position = UDim2.fromOffset(0, SECTION_H + 6),
		ZIndex = 41,
		Parent = catcher,
	})
	Kit.corner(card, 14)
	Kit.softShadow(card, 1)
	Kit.caption("Colour", { Parent = card, Position = UDim2.fromOffset(14, 12), ZIndex = 42 })
	local word = Kit.title("", {
		Name = "Word",
		Parent = card,
		Size = UDim2.new(1, -28, 0, 24),
		Position = UDim2.fromOffset(14, 28),
		TextSize = 19,
		Color = T.Ink,
		Wrap = false,
		ZIndex = 42,
	})
	local function say(c: Color3?)
		local w = if c then ColorWords.nearest(c).word else nil
		word.Text = if w then w:sub(1, 1):upper() .. w:sub(2) else "Pick a colour"
	end
	local wheel = ColorWheel.new({ Parent = card, Position = UDim2.fromOffset(14, 60), Radius = R, ZIndex = 42 })
	wheel.set(colorPick)
	say(colorPick)
	wheel.onChange = say
	wheel.onPick = function(c: Color3)
		setColour(c)
	end
	local half = math.floor((W - 28 - 8) / 2)
	Kit.button("Clear", {
		Parent = card,
		Size = UDim2.fromOffset(half, 34),
		Position = UDim2.new(0, 14, 1, -46),
		Color = T.Coral,
		TextSize = 16,
		ZIndex = 42,
	}, function()
		closeColour()
		setColour(nil)
	end)
	Kit.button("Done", {
		Parent = card,
		Size = UDim2.fromOffset(half, 34),
		Position = UDim2.new(1, -14, 1, -46),
		AnchorPoint = Vector2.new(1, 0),
		Color = T.Green,
		TextSize = 16,
		ZIndex = 42,
	}, closeColour)
end

selectTab = function(id: string)
	tabId = id
	if markTab then
		markTab(id)
	end
	local tab = Categories.tab(id)
	-- a tab of your own things starts with nothing typed; the catalog keeps its last search
	find = ""
	findToken += 1
	if searchBox then
		searchBox.Text = if FIND[id] then "" else keyword
	end
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
	elseif id == "shared" then
		sharedPage()
	end
end

-- The tab's own page built again where it is (a page with no cards: skin, outfits, shared...).
refreshPage = function()
	clearContent()
	forgetCards()
	if tabId == "people" then
		peoplePage()
	elseif tabId == "shared" then
		sharedPage()
	elseif tabId == "outfits" then
		outfitsPage()
	elseif tabId == "skin" then
		skinPage()
	end
end

-- What is typed in the search box on a tab of your own things: its page again, or the rows already
-- had again, with only what holds the words. (Players and Shared ask the server, which looks
-- through everybody and every look, not only the pages shown.)
local function applyFind()
	if not FIND[tabId] then
		return
	end
	local words = Text.clean(searchBox.Text):sub(1, 40)
	if words == find then
		return
	end
	find = words
	local tab = currentTab()
	if tab and tab.source then
		if access == "yes" and grid.Visible then
			showItems(loaded, false, true)
		end
	elseif tabId == "people" or tabId == "shared" or tabId == "outfits" then
		refreshPage()
	end
end

-- Profile page ---------------------------------------------------------------------------------------

-- Follows a press on `hit` and a drag that starts there, calling `at(t)` with how far along it is
-- (0 at the left end, 1 at the right) until the button or finger is let go.
local function dragAlong(hit: GuiButton, at: (number) -> ())
	local dragging = false
	local function fromX(x: number)
		local w = math.max(1, hit.AbsoluteSize.X)
		at(math.clamp((x - hit.AbsolutePosition.X) / w, 0, 1))
	end
	hit.InputBegan:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			dragging = true
			fromX(input.Position.X)
		end
	end)
	local moved, ended
	moved = UserInputService.InputChanged:Connect(function(input)
		if not hit.Parent then
			moved:Disconnect()
			return
		end
		if
			dragging
			and (
				input.UserInputType == Enum.UserInputType.MouseMovement
				or input.UserInputType == Enum.UserInputType.Touch
			)
		then
			fromX(input.Position.X)
		end
	end)
	ended = UserInputService.InputEnded:Connect(function(input)
		if not hit.Parent then
			ended:Disconnect()
			return
		end
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			dragging = false
		end
	end)
end

-- How many rows the names under a stop slider's stops take: one, or two when there are too many
-- stops for their names to sit side by side (the sixteen personalities).
local function stopNameRows(count: number): number
	return if count > 8 then 2 else 1
end

-- A slider with `count` stops along one track, each marked by a small disc in its own colour, a
-- knob on the picked one and the track filled up to it. A click or a tap anywhere on it picks the
-- nearest stop; dragging slides the knob from stop to stop. `y` is where the track runs, in the
-- holder (leave 30 under it for the names, 44 when stopNameRows is 2). Returns { set(i), onPick(i) }.
local function stopSlider(
	holder: Frame,
	count: number,
	y: number,
	colorOf: (number) -> Color3,
	nameOf: (number) -> string
): { set: (number) -> (), onPick: (number) -> () }
	local api = { onPick = function(_: number) end } :: any
	local inset = 14 -- the first and last stop stand this far in from the ends
	local track = Kit.frame({
		Name = "Track",
		Parent = holder,
		Size = UDim2.new(1, -inset * 2, 0, 8),
		Position = UDim2.fromOffset(inset, y - 4),
		Color = T.PaperDark,
		Radius = "pill",
	})
	Kit.rim(track, T.Line, 1)
	-- no fill up to the knob: the stops are kinds, not amounts, and a fill would read as "more"
	for i = 1, count do
		local t = (i - 1) / (count - 1)
		local stop = Kit.disc({
			Name = "Swatch",
			Parent = holder,
			Size = 14,
			Position = UDim2.new(t, inset - 7 - math.floor(inset * 2 * t), 0, y - 7),
			Color = colorOf(i),
			Ring = T.Dark,
			ZIndex = 2,
		})
		stop:SetAttribute("Stop", nameOf(i))
		-- its name under it (the two at the ends kept inside the row); with more stops than one row
		-- of names has room for, every other name sits on a second row under the first
		local ends = if i == 1
			then Enum.TextXAlignment.Left
			elseif i == count then Enum.TextXAlignment.Right
			else Enum.TextXAlignment.Center
		local nameX = if i == 1 then -inset + 2 elseif i == count then -88 + inset - 2 else -45
		local row = (i - 1) % stopNameRows(count)
		Kit.text(nameOf(i), {
			Name = "StopName",
			Parent = holder,
			Size = UDim2.fromOffset(if i == 1 or i == count then 88 else 90, 16),
			Position = UDim2.new(t, inset + nameX - math.floor(inset * 2 * t), 0, y + 14 + row * 14),
			TextSize = 12,
			Font = Kit.Fonts.Bold,
			Color = T.InkSoft,
			AlignX = ends,
			Wrap = false,
		})
	end
	local knob = Kit.frame({
		Name = "Knob",
		Parent = holder,
		Size = UDim2.fromOffset(26, 26),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Color = T.Yellow,
		Radius = "round",
		ZIndex = 3,
	})
	Kit.rim(knob, T.Dark, 2.5)
	local hit = Kit.new("TextButton", {
		Name = "Slide",
		Text = "",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 44),
		Position = UDim2.fromOffset(0, y - 22),
		ZIndex = 4,
		Parent = holder,
	})
	local current = 0
	function api.set(i: number)
		current = i
		local t = (i - 1) / (count - 1)
		knob.Position = UDim2.new(t, inset - math.floor(inset * 2 * t), 0, y)
		holder:SetAttribute("Picked", i)
	end
	dragAlong(hit, function(t)
		-- the stops stand `inset` in from each end: measure along the run between them
		local w = math.max(1, hit.AbsoluteSize.X)
		local run = (t * w - inset) / math.max(1, w - inset * 2)
		local i = math.clamp(math.floor(run * (count - 1) + 0.5) + 1, 1, count)
		if i ~= current then
			api.onPick(i)
		end
	end)
	return api
end

-- The palette as one bar of colours side by side, a knob on the picked one. A click picks the
-- colour under it; dragging slides along. Returns { set(i), onPick(i) }.
local function paletteBar(holder: Frame, size: UDim2): { set: (number) -> (), onPick: (number) -> () }
	local api = { onPick = function(_: number) end } :: any
	local n = #Palette.Colors
	local bar = Kit.frame({
		Name = "Palette",
		Parent = holder,
		Size = size,
		Color = T.PaperDark,
		Radius = 10,
		Clips = true,
	})
	Kit.rim(bar, T.Line, 1)
	local strip = Kit.box({ Parent = bar, Size = UDim2.fromScale(1, 1) })
	Kit.list(strip, 0, true)
	for i, hex in Palette.Colors do
		Kit.frame({
			Name = "Swatch",
			Parent = strip,
			Size = UDim2.new(1 / n, 0, 1, 0),
			Color = Colors.fromHex(hex),
			Radius = false,
			LayoutOrder = i,
		})
	end
	-- the knob: a ring round the picked colour, standing a little proud of the bar
	local knob = Kit.frame({
		Name = "Knob",
		Parent = holder,
		Size = UDim2.new(0, 16, 0, size.Y.Offset + 8),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Color = T.White,
		Transparency = 1,
		Radius = 6,
		ZIndex = 3,
	})
	Kit.rim(knob, T.Dark, 4)
	local inner = Kit.frame({ Name = "Knob", Parent = knob, Color = T.White, Transparency = 1, Radius = 5 })
	Kit.rim(inner, T.White, 2)
	local hit = Kit.new("TextButton", {
		Name = "Slide",
		Text = "",
		BackgroundTransparency = 1,
		Size = size,
		ZIndex = 4,
		Parent = holder,
	})
	function api.set(i: number)
		local scaleW = size.X.Scale
		local offW = size.X.Offset
		local t = (i - 0.5) / n
		knob.Position = UDim2.new(scaleW * t, offW * t, 0, size.Y.Offset / 2)
		holder:SetAttribute("Picked", i)
	end
	dragAlong(hit, function(t)
		local i = math.clamp(math.floor(t * n) + 1, 1, n)
		api.onPick(i)
	end)
	return api
end

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
	-- in a leaning well like the search box
	local nameBox = inputWell(
		"What are they called?",
		{ Parent = scroll, Text = profile.name, LayoutOrder = 2, Size = UDim2.new(1, -10, 0, 42) }
	)
	nameBox.Font = Kit.Fonts.Title
	nameBox.TextSize = 20
	nameField = nameBox
	nameBox:GetPropertyChangedSignal("Text"):Connect(function()
		if utf8.len(nameBox.Text) and (utf8.len(nameBox.Text) :: number) > Tuning.Villagers.NameMaxLength then
			nameBox.Text = nameBox.Text:sub(1, Tuning.Villagers.NameMaxLength)
		end
		profile.name = nameBox.Text
	end)
	heading("Personality", 3)
	-- A face for each personality with its name under it (the user: "for personality, make it
	-- diferent faces to select from with their personality name below each face"), the one picked
	-- ringed in yellow, and its line under them in its own colour.
	local list = Personalities.list
	local pers = Kit.box({
		Name = "Personality",
		Parent = scroll,
		Size = UDim2.new(1, -10, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = 4,
	})
	Kit.list(pers, 6)
	local faces = Kit.box({
		Name = "Faces",
		Parent = pers,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = 1,
	})
	-- eight to a row, stretched across all of it
	local faceGrid = Kit.grid(faces, UDim2.new(1 / 8, -6, 0, 90), 6)
	faceGrid.FillDirectionMaxCells = 8
	faceGrid.HorizontalAlignment = Enum.HorizontalAlignment.Center
	local persBlurb = Kit.text("", {
		Name = "Blurb",
		Parent = pers,
		Size = UDim2.new(1, 0, 0, 20),
		TextSize = 15,
		Wrap = false,
		LayoutOrder = 2,
	})
	local rims: { UIStroke } = {}
	local names: { TextLabel } = {}
	local function showPers(i: number)
		local p = list[i]
		profile.pers = p.id
		-- (in a few words: the user, "under personalities, shorten them")
		persBlurb.Text = Personalities.short(p)
		persBlurb.TextColor3 = Kit.tint(Colors.fromHex(p.color))
		persBlurb:SetAttribute("Tint", p.color)
		-- no border round a tile (the user: "remove the borders around the rectangles"): only the
		-- picked one is ringed, in yellow
		for j, rim in rims do
			local on = j == i
			rim.Enabled = on
			names[j].TextColor3 = if on then T.Ink else T.InkSoft
		end
	end
	for i, p in list do
		local tile = Kit.new("TextButton", {
			Name = p.name,
			Text = "",
			AutoButtonColor = false,
			BackgroundColor3 = T.Card,
			LayoutOrder = i,
			Parent = faces,
		})
		Kit.corner(tile, 12)
		local rim = Kit.new("UIStroke", { Color = T.Yellow, Thickness = 3, Enabled = false, Parent = tile }) :: UIStroke
		rim.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		rims[i] = rim
		Icons.make("face_" .. p.id, 46, {
			Name = "Face",
			Parent = tile,
			Position = UDim2.new(0.5, -23, 0, 8),
			Color = Colors.fromHex(p.color),
			Hole = T.Card,
			Centre = true,
		})
		local label = Kit.text(p.name, {
			Name = "Name",
			Parent = tile,
			Size = UDim2.new(1, -4, 0, 18),
			Position = UDim2.fromOffset(2, 62),
			TextSize = 13,
			Font = Kit.Fonts.Bold,
			AlignX = Enum.TextXAlignment.Center,
			Wrap = false,
		})
		names[i] = label
		tile.Activated:Connect(function()
			showPers(i)
		end)
	end
	local at = 1
	for i, p in list do
		if p.id == profile.pers then
			at = i
		end
	end
	showPers(at)

	heading("Favourite colour", 5)
	-- A grid of little swatches, twelve colours across in four shades (the user: "make the color
	-- selection like this for villager creation"), the one picked ringed.
	local current = (profile.color or ""):upper()
	if not table.find(Palette.Favourites, current) and not table.find(Palette.Colors, current) then
		current = Palette.Favourites[31]
		profile.color = current
	end
	colourGrid(scroll, Palette.Favourites, 28, current, function(hex: string)
		profile.color = hex
		paintStudio()
	end, 6, 12)
	-- (no birthday to pick: a villager's birthday is the day they move in, set by the server;
	-- the user, "remove birthday and day from customization, these will always be the date the
	-- villager is created")

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
					if mode == "new" then Text.fill("{name} is moving in.", { name = name }) else "Saved.",
					"good"
				)
				local made = mode == "new"
				Creator.close()
				if made then
					-- (err is the new villager's id: the tutorial listens for this)
					createdEvent:Fire(err, name)
				end
			else
				save.Text = if mode == "new" then "Move them in" else "Save changes"
				Toasts.show(err or "Couldn't save that. Try again.", "warn")
			end
		end)
	end)
end

-- The second step on yourself: wear the look in town, or go back to your Roblox avatar.
local function buildSelfPage()
	for _, c in profilePage:GetChildren() do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
	local body = Kit.box({ Name = "Self", Parent = profilePage, Size = UDim2.new(1, 0, 1, -64) })
	Kit.list(body, 10)
	Kit.text("Your look", {
		Parent = body,
		Size = UDim2.new(1, -10, 0, 22),
		TextSize = 15,
		Font = Kit.Fonts.Bold,
		Color = T.InkSoft,
		LayoutOrder = 1,
	})
	Kit.text("You wear it in this game.", {
		Name = "About",
		Parent = body,
		Size = UDim2.new(1, -10, 0, 24),
		TextSize = 17,
		LayoutOrder = 2,
	})
	local function send(look: any)
		if saving then
			return
		end
		saving = true
		task.spawn(function()
			local ok, err = Remotes.fn("LookSave"):InvokeServer(look)
			saving = false
			if ok then
				Toasts.show(if look then "Your look is on." else "Back to your Roblox avatar.", "good")
				Creator.close()
			else
				Toasts.show(err or "Couldn't save that. Try again.", "warn")
			end
		end)
	end
	if State.data.look then
		Kit.button("Back to my Roblox avatar", {
			Name = "Roblox avatar",
			Parent = body,
			Size = UDim2.fromOffset(280, 42),
			Color = T.Blue,
			TextSize = 17,
			Icon = "person",
			LayoutOrder = 3,
		}, function()
			send(false)
		end)
	end
	Kit.button("Wear it", {
		Parent = profilePage,
		Size = UDim2.new(1, 0, 0, 52),
		Position = UDim2.new(0, 0, 1, -52),
		Color = T.Green,
		TextSize = 22,
		Icon = "check",
	}, function()
		send(app)
	end)
end

local stepNow = "look"

local function showStep(step: string)
	local was = stepNow
	stepNow = step
	lookPage.Visible = step == "look"
	profilePage.Visible = step == "profile"
	for id, b in stepButtons do
		-- the picked step is yellow with dark words, like a picked tab on any menu
		Kit.setButtonColor(b, if id == step then T.Yellow else T.PaperDark, if id == step then T.Dark else T.Ink)
	end
	-- its yellow slides over from the other step
	if was and was ~= step and stepButtons[was] and stepButtons[step] then
		Kit.glide(stepButtons[was], stepButtons[step])
	end
	if stepCaption then
		stepCaption.Text = Kit.spaced(if step == "look" then "Step 1 of 2" else "Step 2 of 2")
	end
	if step == "profile" then
		if mode == "self" then
			buildSelfPage()
		else
			buildProfilePage()
		end
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
	-- scenery: it takes no clicks or drags (the user: "you cant drag to rotate in the avatar
	-- creator": it filled the view and every press counted as a press on the interface)
	gui.Active = false
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
	if titleGhost then
		titleGhost.Text = string.upper(text)
	end
end

-- The title, the steps' words and the tab at the top for who is being dressed.
local function applyMode()
	local v = editVid and State.villager(editVid)
	if mode == "self" then
		setTitle("Your look")
	elseif mode == "edit" and v then
		setTitle(Text.fill("{name}'s look", { name = v.name }))
	else
		setTitle("Make a villager")
	end
	local second = stepButtons.profile
	if second then
		second.Text = if mode == "self" then "2  Save" else "2  Name and personality"
	end
	if markMode then
		markMode(if mode == "self" then "self" else "villager")
	end
end

local startStage: (string?) -> ()

-- From a villager to yourself and back. The villager being made (or edited) waits, look, undo and
-- all, while you dress yourself.
function switchMode(to: string)
	if not isOpen then
		return
	end
	if to == "self" and mode ~= "self" then
		stash = { mode = mode, editVid = editVid, app = app, history = history, future = future, profile = profile }
		mode, editVid = "self", nil
		history, future = {}, {}
		applyMode()
		showStep("look")
		startStage("self")
	elseif to == "villager" and mode == "self" then
		local back = stash
		stash = nil
		if back then
			mode, editVid, history, future, profile = back.mode, back.editVid, back.history, back.future, back.profile
			app = back.app
		else
			-- opened on yourself: a new villager, if the town has room
			if City.villagerRoom(State.data) <= 0 then
				Toasts.show("Your town is full. Grow it to make room.", "warn")
				applyMode()
				return
			end
			mode, editVid = "new", nil
			history, future = {}, {}
			profile = { name = "", pers = "sunny", color = "4FA9D9", bday = { s = 1, d = 1 } }
			app = Appearance.default()
		end
		applyMode()
		showStep("look")
		sendPreview()
		refreshWorn()
		paintStudio()
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
	-- the title again, large and faint, behind it (as on every menu)
	titleGhost = Kit.ghost("Make a villager", {
		Parent = frame,
		Position = UDim2.fromOffset(92, -18),
		TextSize = 72,
		Transparency = 0.95,
		ZIndex = 0,
	})
	titleLabel = Kit.title("Make a villager", {
		Parent = frame,
		Size = UDim2.fromOffset(520, 46),
		Position = UDim2.fromOffset(104, 12),
		TextSize = 30,
		Color = T.Ink,
		Wrap = false,
	})
	-- a rule under it that ends in a dot, and which step this is set wide after it
	Kit.rule({
		Name = "Rule",
		Parent = frame,
		Size = UDim2.fromOffset(230, 6),
		Position = UDim2.fromOffset(100, 61),
		AnchorPoint = Vector2.new(0, 0.5),
		Accent = T.Pink,
		AccentLength = 30,
	})
	stepCaption = Kit.caption("Step 1 of 2", {
		Name = "Step",
		Parent = frame,
		Position = UDim2.fromOffset(342, 61),
		AnchorPoint = Vector2.new(0, 0.5),
	})
	-- who is being dressed: a villager, or you (the user: "add another tab to edit self in the
	-- catalog just like editing villagers")
	local _, pickMode = Kit.segments({
		{ id = "villager", name = "Villager" },
		{ id = "self", name = "You" },
	}, function(id)
		switchMode(id)
	end, { Parent = frame, Position = UDim2.fromOffset(100, 80), Height = 38, TextSize = 16 })
	markMode = pickMode

	-- Everything to choose from is one panel on the right, a rounded card, its villager's
	-- favourite colour glowing in from the top right (paintStudio). The villager's side of the
	-- screen stays clear (the user: "remove this tooltip in character creation": dragging turns
	-- them and the wheel or a pinch zooms, as before, without a line saying so).
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
	-- brackets on its corners, just outside it
	Kit.brackets(holder, {
		Name = "Corners",
		Corners = { "tl", "tr", "bl", "br" },
		Arm = 16,
		Thick = 2,
		Inset = -6,
		Color = T.Line,
		ZIndex = 1,
	})
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
		Radius = false,
	})
	-- a leaning well with the two steps as leaning slabs in it (in a row of their own, so the
	-- painted well under them stays put)
	local stepsCap = Kit.slant(steps, 46)
	local stepRow = Kit.box({ Name = "Steps", Parent = steps, Size = UDim2.fromScale(1, 1) })
	stepRow.ZIndex = 2
	Kit.pad(stepRow, 4 - stepsCap + math.ceil(stepsCap / 3), 4)
	Kit.list(stepRow, 4, true)
	stepButtons.look = Kit.button(
		"1  Look",
		{ Parent = stepRow, Size = UDim2.new(0.5, -2, 1, 0), TextSize = 18, Radius = "pill" },
		function()
			showStep("look")
		end
	)
	stepButtons.profile = Kit.button(
		"2  Name and personality",
		{ Parent = stepRow, Size = UDim2.new(0.5, -2, 1, 0), TextSize = 18, Radius = "pill" },
		function()
			showStep("profile")
		end
	)

	lookPage = Kit.box({ Parent = panel, Size = UDim2.new(1, 0, 1, -58), Position = UDim2.fromOffset(0, 58) })
	profilePage =
		Kit.box({ Parent = panel, Size = UDim2.new(1, 0, 1, -58), Position = UDim2.fromOffset(0, 58), Visible = false })

	-- The Look step is laid out the way avatar catalog screens are (the user, with a picture of
	-- one: "for the left side, the interface for look should be like the second image"): the
	-- search box at the top left, the sections as a row of words beside it with the one you are in
	-- underlined, the kinds inside that section as a second row of smaller words, the cards five
	-- to a row, and along the bottom the box to copy someone's avatar at the left and a row of
	-- square icon buttons at the right. Drawn our own way.
	local HEAD_H = SECTION_H + 6 + FILTER_H
	local header = Kit.box({ Name = "Header", Parent = lookPage, Size = UDim2.new(1, 0, 0, HEAD_H) })

	-- the search box, at the top left (what was typed is kept when the screen is built again)
	searchRow = Kit.box({ Name = "Search", Parent = header, Size = UDim2.fromOffset(SEARCH_W, SECTION_H) })
	local well = Kit.frame({
		Name = "Well",
		Parent = searchRow,
		Color = T.PaperDark,
		Radius = false,
	})
	Kit.slant(well, SECTION_H)
	Icons.make("zoom", 18, {
		Name = "Glass",
		Parent = searchRow,
		Position = UDim2.new(0, 14, 0.5, -9),
		Color = T.InkSoft,
		Hole = T.PaperDark,
		ZIndex = 2,
	})
	searchBox = Kit.textbox("Search", {
		Parent = searchRow,
		Size = UDim2.new(1, -84, 1, 0),
		Text = keyword,
		TextSize = 16,
	})
	-- the colour to search by: a round button at the box's end that opens the colour wheel, filled
	-- with the colour once one is picked
	local cb = Kit.new("TextButton", {
		Name = "Colour",
		Text = "",
		AutoButtonColor = false,
		BackgroundColor3 = T.Card,
		Size = UDim2.fromOffset(26, 26),
		Position = UDim2.new(1, -40, 0.5, -13),
		ZIndex = 3,
		Parent = searchRow,
	})
	Kit.corner(cb, "round")
	Icons.make("bucket", 16, {
		Name = "IconArt",
		Parent = cb,
		Position = UDim2.new(0.5, -8, 0.5, -8),
		Color = T.InkSoft,
		Hole = T.Card,
		ZIndex = 4,
		Centre = true,
	})
	Kit.frame({
		Name = "Swatch",
		Parent = cb,
		Size = UDim2.new(1, -6, 1, -6),
		Position = UDim2.fromOffset(3, 3),
		Color = T.Card,
		Radius = "round",
		ZIndex = 4,
		Visible = false,
	})
	Kit.press(cb, { Kind = "round" })
	cb.Activated:Connect(openColour)
	colourButton = cb
	searchBox.Position = UDim2.fromOffset(38, 0)
	searchBox.BackgroundTransparency = 1
	searchBox.ClipsDescendants = true
	searchBox.ZIndex = 2
	local boxPad = searchBox:FindFirstChildOfClass("UIPadding")
	if boxPad then
		boxPad.PaddingLeft = UDim.new(0, 2)
	end
	searchBox.FocusLost:Connect(function()
		if not searchBox.TextEditable then
			return
		end
		if FIND[tabId] then
			findToken += 1
			applyFind()
			return
		end
		keyword = Text.clean(searchBox.Text):sub(1, 50)
		search()
	end)
	-- on a tab of your own things the list follows the words as they are typed, a moment after
	-- the last key
	searchBox:GetPropertyChangedSignal("Text"):Connect(function()
		if not FIND[tabId] or not searchBox.TextEditable then
			return
		end
		findToken += 1
		local token = findToken
		task.delay(0.3, function()
			if token == findToken and isOpen then
				applyFind()
			end
		end)
	end)

	-- the sections, as a row of words beside it: more than fit, so it scrolls sideways, with an
	-- arrow at each end (and the wheel) to bring the rest into view
	local sectionsW = PANEL_W - SEARCH_W - 12
	local strip = Kit.box({
		Name = "SectionsStrip",
		Parent = header,
		Size = UDim2.fromOffset(sectionsW, SECTION_H),
		Position = UDim2.fromOffset(SEARCH_W + 12, 0),
	})
	local viewW = sectionsW - ARROW * 2 - 8
	-- (a window onto the row, which slides along behind it)
	local sections = Kit.new("Frame", {
		Name = "Sections",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Size = UDim2.fromOffset(viewW, SECTION_H),
		Position = UDim2.fromOffset(ARROW + 4, 0),
		Parent = strip,
	})
	local slide = Kit.box({ Name = "Row", Parent = sections, Size = UDim2.fromScale(1, 1) })
	local words: { TextButton } = {}
	local wordAt: { number } = {}
	local wordW: { number } = {}
	local wordIndex: { [string]: number } = {}
	local x = 0
	for i, t in Categories.Tabs do
		local w = textWidth(t.name, 17) + WORD_PAD * 2
		local b = Kit.new("TextButton", {
			Name = t.name,
			Text = t.name,
			Font = Kit.Fonts.Title,
			TextSize = 17,
			TextColor3 = T.InkSoft,
			AutoButtonColor = false,
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(w, SECTION_H),
			Position = UDim2.fromOffset(x, 0),
			Parent = slide,
		})
		-- the line under the one you are in
		Kit.frame({
			Name = "Underline",
			Parent = b,
			Size = UDim2.new(1, -WORD_PAD * 2 + 8, 0, 3),
			Position = UDim2.new(0, WORD_PAD - 4, 1, -4),
			Color = T.Yellow,
			Radius = "pill",
			Visible = false,
		})
		b.Activated:Connect(function()
			filterIndex = 1
			selectTab(t.id)
		end)
		words[i], wordAt[i], wordW[i], wordIndex[t.id] = b, x, w, i
		x += w
	end
	local total = x
	slide.Size = UDim2.fromOffset(total, SECTION_H)
	-- the first word in view; the row starts at it
	local first = 1
	local function lastShown(from: number): number
		local last = from
		for i = from, #words do
			if wordAt[i] + wordW[i] - wordAt[from] <= viewW + 0.5 then
				last = i
			end
		end
		return last
	end
	-- the furthest the row can go: the start that still ends with the last word in view
	local maxFirst = #words
	for i = #words, 1, -1 do
		if total - wordAt[i] <= viewW then
			maxFirst = i
		end
	end
	local back, ahead
	local function scrollTo(i: number)
		first = math.clamp(i, 1, maxFirst)
		TweenService:Create(slide, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = UDim2.fromOffset(-wordAt[first], 0),
		}):Play()
		sections:SetAttribute("First", first)
		sections:SetAttribute("LastShown", lastShown(first))
		-- an arrow is dim when there is nothing more that way
		for _, pair in { { back, first > 1 }, { ahead, first < maxFirst } } do
			local art = pair[1]:FindFirstChild("IconArt", true)
			if art then
				Kit.recolorIcon(art, if pair[2] then T.Ink else T.Line, T.Card)
			end
		end
	end
	local function arrow(name: string, flip: boolean, onClick: () -> ()): TextButton
		local b = Kit.new("TextButton", {
			Name = name,
			Text = "",
			AutoButtonColor = false,
			BackgroundColor3 = T.Card,
			Size = UDim2.fromOffset(ARROW, ARROW),
			Position = if flip then UDim2.new(1, -ARROW, 0.5, -ARROW / 2) else UDim2.new(0, 0, 0.5, -ARROW / 2),
			Parent = strip,
		})
		Kit.corner(b, "round")
		local art = Icons.make("back", 16, {
			Name = "IconArt",
			Parent = b,
			Position = UDim2.new(0.5, -8, 0.5, -8),
			Color = T.Ink,
			Hole = T.Card,
		})
		if flip then
			art.Rotation = 180
		end
		b.Activated:Connect(onClick)
		return b
	end
	back = arrow("Earlier sections", false, function()
		-- back a page: the earliest start that still shows the word now first
		local i = first
		while i > 1 and wordAt[first] + wordW[first] - wordAt[i - 1] <= viewW do
			i -= 1
		end
		scrollTo(if i == first then first - 1 else i)
	end)
	ahead = arrow("More sections", true, function()
		-- on a page: the first word not wholly in view starts the next one
		scrollTo(lastShown(first) + 1)
	end)
	-- the wheel over the row moves it a word at a time
	sections.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseWheel then
			scrollTo(first + (if input.Position.Z < 0 then 1 else -1))
		end
	end)
	local function markSection(id: string)
		for i, b in words do
			local on = Categories.Tabs[i].id == id
			b.TextColor3 = if on then T.Ink else T.InkSoft
			local line = b:FindFirstChild("Underline")
			if line and line:IsA("GuiObject") then
				line.Visible = on
			end
		end
		-- the one you are in is always in view
		local i = wordIndex[id]
		if i and (i < first or i > lastShown(first)) then
			local start = i
			while start > 1 and wordAt[i] + wordW[i] - wordAt[start - 1] <= viewW do
				start -= 1
			end
			scrollTo(if i < first then i else start)
		end
	end
	scrollTo(1)
	markSection(tabId)
	markTab = markSection

	-- the kinds inside the section, as a second row of smaller words under it, and the sort at
	-- the row's end
	sortButton = Kit.button(sortWords(sortId), {
		Name = "Sort",
		Parent = header,
		Size = UDim2.fromOffset(SORT_W, FILTER_H),
		Position = UDim2.new(1, -SORT_W, 0, SECTION_H + 6),
		Color = T.Card,
		TextColor = T.Ink,
		TextSize = 14,
		Icon = "layers",
	})
	-- the picked colour's word, with a cross: pressed, the colour goes
	local tag = Kit.new("TextButton", {
		Name = "ColourTag",
		Text = "",
		AutoButtonColor = false,
		BackgroundColor3 = T.Card,
		Size = UDim2.fromOffset(110, FILTER_H),
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -(SORT_W + 8), 0, SECTION_H + 6),
		Visible = false,
		Parent = header,
	})
	Kit.corner(tag, "pill")
	Kit.frame({
		Name = "Swatch",
		Parent = tag,
		Size = UDim2.fromOffset(14, 14),
		Position = UDim2.new(0, 10, 0.5, -7),
		Color = T.Card,
		Radius = "round",
	})
	Kit.text("", {
		Name = "Word",
		Parent = tag,
		Size = UDim2.new(1, -54, 1, 0),
		Position = UDim2.fromOffset(30, 0),
		TextSize = 14,
		Font = Kit.Fonts.Bold,
		Wrap = false,
	})
	Icons.make("close", 12, {
		Name = "IconArt",
		Parent = tag,
		Position = UDim2.new(1, -20, 0.5, -6),
		Color = T.InkSoft,
		Hole = T.Card,
	})
	Kit.press(tag, { Kind = "pill" })
	tag.Activated:Connect(function()
		closeColour()
		setColour(nil)
	end)
	colourTag = tag
	paintColour()
	sortButton.Activated:Connect(function()
		if tabId == "shared" then
			-- newest first, or the most liked first
			sharedSort = if sharedSort == "new" then "likes" else "new"
			sortButton.Text = sharedSortWords()
			refreshPage()
			return
		end
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
		Parent = header,
		Size = UDim2.new(1, -(SORT_W + 8), 0, FILTER_H),
		Position = UDim2.fromOffset(0, SECTION_H + 6),
		Axis = Enum.AutomaticSize.X,
	})
	filterRow.ScrollBarThickness = 0
	Kit.list(filterRow, 0, true)
	-- a quiet line under the two rows
	Kit.frame({
		Name = "Divider",
		Parent = lookPage,
		Size = UDim2.new(1, 0, 0, 1),
		Position = UDim2.fromOffset(0, HEAD_H + 6),
		Color = T.Line,
		Radius = false,
	})

	-- the cards, or the page the section is (skin, shape, outfits, players...)
	local top = HEAD_H + 14
	local bottom = BOTTOM_H + 6 + CAPTION_H
	content = Kit.box({
		Name = "Content",
		Parent = lookPage,
		Size = UDim2.new(1, 0, 1, -(top + bottom + 6)),
		Position = UDim2.fromOffset(0, top),
	})
	grid = Kit.scroll({ Parent = content, Size = UDim2.new(1, 0, 1, -48) })
	grid.ScrollBarThickness = 4
	grid.VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar
	-- five cards to a row, spaced to fill the panel's width
	local cardGrid = Kit.grid(grid, UDim2.fromOffset(CARD_W, CARD_H), 12)
	cardGrid.CellPadding = UDim2.fromOffset(math.floor((PANEL_W - 4 - 5 * CARD_W) / 4), 14)
	loadMore = Kit.button("Show more", {
		Parent = content,
		Size = UDim2.new(1, 0, 0, 40),
		Position = UDim2.new(0, 0, 1, -40),
		Color = T.Blue,
		TextSize = 17,
		Icon = "down",
	}, more)

	-- along the bottom: copy somebody's avatar at the left, and the tools at the right as square
	-- icon buttons; what the one under the pointer does is said in a small line over them
	local foot = Kit.box({
		Name = "Footer",
		Parent = lookPage,
		Size = UDim2.new(1, 0, 0, BOTTOM_H),
		Position = UDim2.new(0, 0, 1, -BOTTOM_H),
	})
	local toolList = {
		{ "undo", "Undo", "Undo", undo },
		{ "redo", "Redo", "Redo", redo },
		{ "dice", "Shuffle", "Shuffle", shuffle },
		{
			"trash",
			"Reset",
			"Reset",
			function()
				setApp(Appearance.default())
			end,
		},
		-- the whole look from Roblox (the user: "allow players to buy the outfit of the villager")
		{
			"cart",
			"Buy outfit",
			"Buy outfit",
			function()
				local sets = {}
				for _, set in wornSets(app) do
					table.insert(sets, { id = set.id, part = set.part })
				end
				BuyLook.look(app, sets)
			end,
		},
		-- one button steps through the three distances, for whoever has no wheel and no second finger
		{
			"zoom",
			"Zoom",
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
		-- screen: "along with the option to change to light mode"); it is named for the look you
		-- would get
		{
			Theme.icon(),
			if Theme.name() == "dark" then "Light" else "Dark",
			if Theme.name() == "dark" then "Light mode" else "Dark mode",
			Theme.toggle,
		},
	}
	local toolsW = #toolList * TOOL_SQ + (#toolList - 1) * 6
	local tools = Kit.box({
		Name = "Tools",
		Parent = foot,
		Size = UDim2.fromOffset(toolsW, BOTTOM_H),
		Position = UDim2.new(1, -toolsW, 0, 0),
	})
	Kit.list(tools, 6, true)
	local caption = Kit.text("", {
		Name = "ToolCaption",
		Parent = lookPage,
		Size = UDim2.new(0, 360, 0, CAPTION_H),
		Position = UDim2.new(1, -360, 1, -(BOTTOM_H + 4 + CAPTION_H)),
		TextSize = 13,
		Font = Kit.Fonts.Bold,
		Color = T.InkSoft,
		AlignX = Enum.TextXAlignment.Right,
		Wrap = false,
	})
	local captionToken = 0
	for i, t in toolList do
		local b = Kit.new("TextButton", {
			Name = t[2],
			Text = "",
			AutoButtonColor = false,
			BackgroundColor3 = T.Card,
			Size = UDim2.fromOffset(TOOL_SQ, TOOL_SQ),
			LayoutOrder = i,
			Parent = tools,
		})
		b:SetAttribute("Caption", t[3])
		Kit.corner(b, 10)
		Icons.make(t[1], 22, {
			Name = "IconArt",
			Parent = b,
			Position = UDim2.new(0.5, -11, 0.5, -11),
			Color = T.Ink,
			Hole = T.Card,
		})
		Kit.press(b, { Kind = "tile" })
		b.MouseEnter:Connect(function()
			captionToken += 1
			caption.Text = t[3]
		end)
		b.MouseLeave:Connect(function()
			if caption.Text == t[3] then
				caption.Text = ""
			end
		end)
		b.Activated:Connect(function()
			-- (said on a press too, for a touch screen, where nothing hovers)
			captionToken += 1
			local token = captionToken
			caption.Text = t[3]
			task.delay(1.6, function()
				if token == captionToken and caption.Parent then
					caption.Text = ""
				end
			end)
			t[4]()
		end)
	end
	local copy = Kit.box({
		Name = "Copy",
		Parent = foot,
		Size = UDim2.new(1, -(toolsW + 16), 1, 0),
	})
	local userBox =
		inputWell("Username to copy", { Parent = copy, Size = UDim2.new(1, -156, 0, BOTTOM_H), TextSize = 15 })
	Kit.button("Copy", {
		Parent = copy,
		Size = UDim2.fromOffset(80, BOTTOM_H),
		Position = UDim2.new(1, -148, 0, 0),
		Color = T.Blue,
		TextSize = 16,
	}, function()
		local name = Text.clean(userBox.Text)
		if name == "" then
			Toasts.show("Type a username first.", "info")
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
		Size = UDim2.fromOffset(64, BOTTOM_H),
		Position = UDim2.new(1, -64, 0, 0),
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
end

-- Opening and closing -----------------------------------------------------------------------------------

function Creator.isOpen(): boolean
	return isOpen
end

-- arg: { mode = "new" | "edit" | "self", vid?, start? = "me", tab? }: "self" is your own look,
-- start "me" a new villager that starts as you (your avatar and your name), tab the section to
-- open on.
function Creator.open(arg: any)
	if isOpen then
		Creator.close()
	end
	local a = arg or {}
	mode = if a.mode == "edit" or a.mode == "self" then a.mode else "new"
	editVid = if mode == "edit" then a.vid else nil
	stash = nil
	if mode == "new" and City.villagerRoom(State.data) <= 0 then
		local cap = City.stats(State.data).villagerCap
		Toasts.show(
			Text.fill("Your town has room for {n} villagers. Grow it to make room for more.", { n = cap }),
			"warn"
		)
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
		profile = { name = v.name, pers = v.pers, color = v.color, bday = table.clone(v.bday) }
	else
		profile = {
			name = if a.start == "me" then player.DisplayName or "" else "",
			pers = "sunny",
			color = "4FA9D9",
			bday = { s = 1, d = 1 },
		}
	end
	applyMode()
	showStep("look")
	if type(a.tab) == "string" and Categories.tab(a.tab) then
		tabId = a.tab
		filterIndex = 1
	end
	selectTab(tabId)
	startStage(
		if mode == "edit" then editVid elseif mode == "self" then "self" elseif a.start == "me" then "me" else nil
	)
end

-- Asks the server for the stage with the look to start from (a villager's id, "me", "self" or
-- nil for a plain one) and starts the camera on it.
startStage = function(what: string?)
	openToken += 1
	local token = openToken
	task.spawn(function()
		local stage = Remotes.fn("CreatorOpen"):InvokeServer(what)
		if not stage or not isOpen or token ~= openToken then
			return
		end
		origin = stage.origin
		app = Appearance.sanitize(stage.app)
		refreshWorn()
		if not camConn then
			startCamera()
		end
	end)
end

-- For the tutorial and anywhere else that wants a villager made a certain way:
--   "yourself"  a new villager that starts as the player's own avatar, with their name
--   "friend"    a new villager, opened on the Players tab (a friend's look and name in one click)
--   "custom"    a new villager from the plain start
--   "self"      the player's own look (the You tab)
-- Creator.Created fires (vid, name) when a new villager moves in.
function Creator.openFor(kind: string)
	local Hud = require(script.Parent.Hud) :: any
	if kind == "yourself" then
		Hud.open("Creator", { mode = "new", start = "me" })
	elseif kind == "friend" then
		Hud.open("Creator", { mode = "new", tab = "people" })
	elseif kind == "self" then
		Hud.open("Creator", { mode = "self" })
	else
		Hud.open("Creator", { mode = "new" })
	end
end

function Creator.close()
	if not isOpen then
		return
	end
	isOpen = false
	searchToken += 1
	previewToken += 1
	closeColour()
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
	old:Destroy()
	root = nil
	titleLabel = nil
	colourPop, colourButton, colourTag, markMode = nil, nil, nil, nil
	if not isOpen then
		return
	end
	build()
	applyMode()
	showStep(stepNow)
	selectTab(tabId)
	refreshWorn()
	paintStudio()
end)

return Creator
