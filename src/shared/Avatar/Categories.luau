--!strict
-- The villager creator's tabs, the catalog searches behind them, and how a catalog item is worn.

local Appearance = require(script.Parent.Appearance)

-- A filter is one search inside a tab.
--   assets, bundles  the catalog types it asks for (Enum.AvatarAssetType and Enum.BundleType names)
--   kind             what a bundle found here is worn as (Avatar/Bundles): "body", "head", "shoes", "anim"
--   offSale          also show what isn't sold by itself (single body parts only come inside bodies)
--   browse           the sort to show while nothing has been typed and the sort is still "Best match"
--   inBundles        bundle types to pull these assets out of when the catalog lists none of them singly
--   outfits          for the player's own Roblox avatars: which ones (an Enum.OutfitSource name)
export type Filter = {
	id: string,
	name: string,
	assets: { string }?,
	bundles: { string }?,
	kind: string?,
	offSale: boolean?,
	browse: string?,
	inBundles: { string }?,
	outfits: string?,
}
-- A tab with no filters is a page of its own (Wearing, Skin, Shape, Outfits, Players). `source`
-- says where a tab's cards come from: the catalog (nil), what the player owns on Roblox
-- ("inventory") or the avatars they have saved there ("outfits"); the last two need the player
-- to say yes to Roblox's question first.
export type Tab = { id: string, name: string, filters: { Filter }?, source: string? }

local Categories = {}

local function A(id: string, name: string, assets: { string }): Filter
	return { id = id, name = name, assets = assets }
end

local function B(id: string, name: string, bundles: { string }, kind: string): Filter
	return { id = id, name = name, bundles = bundles, kind = kind }
end

-- every bundle type that is a whole body
local BODIES = { "BodyParts", "DynamicHeadAvatar" }

-- One body part by itself. They are never sold alone, so the search takes in what is off sale,
-- browses by the most liked (the plain order is a wall of nameless test pieces), and falls back
-- on the same part taken out of the bodies that are for sale.
local function P(id: string, name: string, asset: string): Filter
	return { id = id, name = name, assets = { asset }, offSale = true, browse = "MostFavorited", inBundles = BODIES }
end

local tabs: { Tab } = {
	{ id = "wearing", name = "Wearing" },
	{ id = "hair", name = "Hair", filters = { A("hair", "Hair", { "HairAccessory" }) } },
	{
		id = "heads",
		name = "Heads",
		filters = { A("faces", "Faces", { "Face" }), B("dynheads", "Heads", { "DynamicHead" }, "head") },
	},
	{
		id = "accessories",
		name = "Accessories",
		filters = {
			A("hats", "Hats", { "Hat" }),
			A("faceacc", "Glasses", { "FaceAccessory" }),
			A("neck", "Neck", { "NeckAccessory" }),
			A("shoulder", "Shoulder", { "ShoulderAccessory" }),
			A("front", "Front", { "FrontAccessory" }),
			A("back", "Back", { "BackAccessory" }),
			A("waist", "Waist", { "WaistAccessory" }),
		},
	},
	{
		id = "tops",
		name = "Tops",
		filters = {
			A("shirts", "Shirts", { "Shirt" }),
			A("tshirts", "T-shirts", { "TShirt" }),
			A("layeredtops", "3D tops", { "TShirtAccessory", "ShirtAccessory", "SweaterAccessory", "JacketAccessory" }),
		},
	},
	{
		id = "bottoms",
		name = "Bottoms",
		filters = {
			A("pants", "Pants", { "Pants" }),
			A("layeredbottoms", "3D bottoms", { "PantsAccessory", "ShortsAccessory", "DressSkirtAccessory" }),
		},
	},
	{ id = "shoes", name = "Shoes", filters = { B("shoes", "Shoes", { "Shoes" }, "shoes") } },
	{ id = "bodies", name = "Bodies", filters = { B("bodies", "Bodies", BODIES, "body") } },
	-- the torso, the arms and the legs one at a time, to mix with any head or body
	{
		id = "parts",
		name = "Body parts",
		filters = {
			P("torsos", "Torso", "Torso"),
			P("leftarms", "Left arm", "LeftArm"),
			P("rightarms", "Right arm", "RightArm"),
			P("leftlegs", "Left leg", "LeftLeg"),
			P("rightlegs", "Right leg", "RightLeg"),
		},
	},
	{ id = "moves", name = "Moves", filters = { B("moves", "Moves", { "Animations" }, "anim") } },
	{ id = "skin", name = "Skin" },
	{ id = "shape", name = "Shape" },
	-- what the player owns on Roblox, by kind
	{
		id = "inventory",
		name = "My items",
		source = "inventory",
		filters = {
			A("ownhair", "Hair", { "HairAccessory" }),
			A("ownhats", "Hats", { "Hat" }),
			A("ownextras", "Accessories", {
				"FaceAccessory",
				"NeckAccessory",
				"ShoulderAccessory",
				"FrontAccessory",
				"BackAccessory",
				"WaistAccessory",
			}),
			A("owntops", "Tops", {
				"Shirt",
				"TShirt",
				"TShirtAccessory",
				"ShirtAccessory",
				"SweaterAccessory",
				"JacketAccessory",
			}),
			A("ownbottoms", "Bottoms", { "Pants", "PantsAccessory", "ShortsAccessory", "DressSkirtAccessory" }),
			A("ownshoes", "Shoes", { "LeftShoeAccessory", "RightShoeAccessory" }),
			A("ownheads", "Heads", { "DynamicHead", "Head", "Face", "EyebrowAccessory", "EyelashAccessory" }),
			A("ownparts", "Body parts", { "Torso", "LeftArm", "RightArm", "LeftLeg", "RightLeg" }),
			A("ownmoves", "Moves", {
				"IdleAnimation",
				"WalkAnimation",
				"RunAnimation",
				"JumpAnimation",
				"FallAnimation",
				"ClimbAnimation",
				"SwimAnimation",
			}),
		},
	},
	-- looks saved in this game
	{ id = "outfits", name = "Outfits" },
	-- the avatars the player has saved on Roblox, and the characters they have bought there
	{
		id = "avatars",
		name = "My avatars",
		source = "outfits",
		filters = {
			{ id = "saved", name = "Saved by me", outfits = "Created" },
			{ id = "bought", name = "Bought", outfits = "Purchased" },
		},
	},
	-- avatars made by other players: the people here, your friends, and looks shared from this creator
	{ id = "people", name = "Players" },
}

Categories.Tabs = tabs

function Categories.tab(id: string): Tab?
	for _, t in tabs do
		if t.id == id then
			return t
		end
	end
	return nil
end

Categories.Sorts = {
	{ id = "Relevance", name = "Best match" },
	{ id = "Bestselling", name = "Popular" },
	{ id = "MostFavorited", name = "Most liked" },
	{ id = "RecentlyCreated", name = "Newest" },
	{ id = "PriceLowToHigh", name = "Cheapest" },
	{ id = "PriceHighToLow", name = "Priciest" },
}

-- Where a worn asset goes, by its AssetType name.
local SLOTS: { [string]: { kind: string, key: string } } = {
	Hat = { kind = "acc", key = "Hat" },
	HairAccessory = { kind = "acc", key = "Hair" },
	FaceAccessory = { kind = "acc", key = "Face" },
	NeckAccessory = { kind = "acc", key = "Neck" },
	ShoulderAccessory = { kind = "acc", key = "Shoulder" },
	FrontAccessory = { kind = "acc", key = "Front" },
	BackAccessory = { kind = "acc", key = "Back" },
	WaistAccessory = { kind = "acc", key = "Waist" },
	TShirtAccessory = { kind = "acc", key = "TShirt" },
	ShirtAccessory = { kind = "acc", key = "Shirt" },
	PantsAccessory = { kind = "acc", key = "Pants" },
	JacketAccessory = { kind = "acc", key = "Jacket" },
	SweaterAccessory = { kind = "acc", key = "Sweater" },
	ShortsAccessory = { kind = "acc", key = "Shorts" },
	LeftShoeAccessory = { kind = "acc", key = "LeftShoe" },
	RightShoeAccessory = { kind = "acc", key = "RightShoe" },
	DressSkirtAccessory = { kind = "acc", key = "DressSkirt" },
	EyebrowAccessory = { kind = "acc", key = "Eyebrow" },
	EyelashAccessory = { kind = "acc", key = "Eyelash" },
	Face = { kind = "face", key = "face" },
	Shirt = { kind = "field", key = "shirt" },
	Pants = { kind = "field", key = "pants" },
	TShirt = { kind = "field", key = "tshirt" },
	Head = { kind = "body", key = "head" },
	DynamicHead = { kind = "body", key = "head" },
	Torso = { kind = "body", key = "torso" },
	LeftArm = { kind = "body", key = "la" },
	RightArm = { kind = "body", key = "ra" },
	LeftLeg = { kind = "body", key = "ll" },
	RightLeg = { kind = "body", key = "rl" },
	IdleAnimation = { kind = "anim", key = "idle" },
	WalkAnimation = { kind = "anim", key = "walk" },
	RunAnimation = { kind = "anim", key = "run" },
	JumpAnimation = { kind = "anim", key = "jump" },
	FallAnimation = { kind = "anim", key = "fall" },
	ClimbAnimation = { kind = "anim", key = "climb" },
	SwimAnimation = { kind = "anim", key = "swim" },
}

-- How many of each accessory slot a villager may wear at once (others replace the oldest).
local SLOT_LIMIT = {
	Hat = 3,
	Hair = 3,
	Face = 2,
	Neck = 1,
	Shoulder = 2,
	Front = 1,
	Back = 1,
	Waist = 1,
	TShirt = 1,
	Shirt = 1,
	Pants = 1,
	Jacket = 1,
	Sweater = 1,
	Shorts = 1,
	LeftShoe = 1,
	RightShoe = 1,
	DressSkirt = 1,
}

-- Layering order for 3D clothing, inner to outer.
local LAYER_ORDER = {
	TShirt = 1,
	Shirt = 2,
	Pants = 3,
	Shorts = 4,
	DressSkirt = 5,
	Sweater = 6,
	Jacket = 7,
	LeftShoe = 8,
	RightShoe = 8,
}

function Categories.slotFor(assetTypeName: string): { kind: string, key: string }?
	return SLOTS[assetTypeName]
end

-- Catalog results give the asset type as a name or as Enum.AssetType's number. Returns the name.
function Categories.assetTypeName(v: any): string?
	if type(v) == "string" then
		return v
	end
	if type(v) == "number" then
		for _, item in Enum.AssetType:GetEnumItems() do
			if item.Value == v then
				return item.Name
			end
		end
	end
	if typeof(v) == "EnumItem" then
		return (v :: EnumItem).Name
	end
	return nil
end

-- Is this asset worn in the appearance?
function Categories.isWorn(app: Appearance.Appearance, id: number): boolean
	if id <= 0 then
		return false
	end
	for _, k in Appearance.BodyKeys do
		if app.body[k] == id then
			return true
		end
	end
	for _, k in Appearance.AnimKeys do
		if app.anim[k] == id then
			return true
		end
	end
	if app.face == id or app.shirt == id or app.pants == id or app.tshirt == id then
		return true
	end
	for _, a in app.acc do
		if a.id == id then
			return true
		end
	end
	return false
end

-- Puts on (or takes off, if already worn) one asset. Returns the new appearance.
function Categories.toggle(app: Appearance.Appearance, id: number, assetTypeName: string): Appearance.Appearance
	local out = Appearance.sanitize(app)
	if Categories.isWorn(out, id) then
		return Appearance.without(out, id)
	end
	local slot = SLOTS[assetTypeName]
	if not slot then
		return out
	end
	if slot.kind == "acc" then
		local limit = SLOT_LIMIT[slot.key] or 1
		local same = {}
		for i, a in out.acc do
			if a.t == slot.key then
				table.insert(same, i)
			end
		end
		while #same >= limit do
			table.remove(out.acc, same[1])
			table.remove(same, 1)
			for j = 1, #same do
				same[j] -= 1
			end
		end
		local layered = Appearance.AccessoryTypes[slot.key] == true
		table.insert(
			out.acc,
			{ id = id, t = slot.key, l = layered, o = if layered then LAYER_ORDER[slot.key] else nil }
		)
	elseif slot.kind == "face" then
		out.face = id
	elseif slot.kind == "field" then
		(out :: any)[slot.key] = id
	elseif slot.kind == "body" then
		out.body[slot.key] = id
	elseif slot.kind == "anim" then
		out.anim[slot.key] = id
	end
	return Appearance.sanitize(out)
end

local LIMBS = { "torso", "la", "ra", "ll", "rl" }

local function bringsLimbs(part: any): boolean
	if type(part.body) ~= "table" then
		return false
	end
	for _, k in LIMBS do
		if type(part.body[k]) == "number" and part.body[k] > 0 then
			return true
		end
	end
	return false
end

-- Merges part of an appearance (from a bundle) over a full one.
function Categories.merge(app: Appearance.Appearance, part: any): Appearance.Appearance
	local out = Appearance.sanitize(app)
	if type(part) ~= "table" then
		return out
	end
	if part.kind == "body" and bringsLimbs(part) then
		-- a whole body replaces the last one: nothing of the old torso and limbs stays behind
		-- (the head stays unless the new body brings its own). Only a body that has a torso or a
		-- limb to give does this: one that came through with a head and nothing else must not
		-- strip the villager down to that head.
		for _, k in LIMBS do
			out.body[k] = 0
		end
	end
	if type(part.body) == "table" then
		for _, k in Appearance.BodyKeys do
			if type(part.body[k]) == "number" and part.body[k] > 0 then
				out.body[k] = part.body[k]
			end
		end
	end
	if type(part.anim) == "table" then
		for _, k in Appearance.AnimKeys do
			if type(part.anim[k]) == "number" and part.anim[k] > 0 then
				out.anim[k] = part.anim[k]
			end
		end
	end
	if type(part.face) == "number" and part.face > 0 then
		out.face = part.face
	end
	if type(part.acc) == "table" then
		for _, a in part.acc do
			if type(a) == "table" and type(a.id) == "number" and type(a.t) == "string" then
				-- replace whatever sat in that slot
				for i = #out.acc, 1, -1 do
					if out.acc[i].t == a.t then
						table.remove(out.acc, i)
					end
				end
				table.insert(out.acc, { id = a.id, t = a.t, l = a.l == true, o = a.o })
			end
		end
	end
	if type(part.scale) == "table" then
		for _, k in Appearance.ScaleKeys do
			if type(part.scale[k]) == "number" then
				out.scale[k] = part.scale[k]
			end
		end
	end
	return Appearance.sanitize(out)
end

-- Is everything a bundle sets being worn? (A bundle has no id of its own in a look.)
function Categories.bundleWorn(app: Appearance.Appearance, part: any): boolean
	if type(part) ~= "table" then
		return false
	end
	local any = false
	for _, k in Appearance.BodyKeys do
		local id = type(part.body) == "table" and part.body[k]
		if type(id) == "number" and id > 0 then
			any = true
			if app.body[k] ~= id then
				return false
			end
		end
	end
	for _, k in Appearance.AnimKeys do
		local id = type(part.anim) == "table" and part.anim[k]
		if type(id) == "number" and id > 0 then
			any = true
			if app.anim[k] ~= id then
				return false
			end
		end
	end
	for _, a in if type(part.acc) == "table" then part.acc else {} do
		any = true
		if not Categories.isWorn(app, a.id) then
			return false
		end
	end
	return any
end

-- Takes a bundle off again: its body parts, animations and accessories go back to none.
function Categories.unmerge(app: Appearance.Appearance, part: any): Appearance.Appearance
	local out = Appearance.sanitize(app)
	if type(part) ~= "table" then
		return out
	end
	for _, k in Appearance.BodyKeys do
		if type(part.body) == "table" and part.body[k] == out.body[k] then
			out.body[k] = 0
		end
	end
	for _, k in Appearance.AnimKeys do
		if type(part.anim) == "table" and part.anim[k] == out.anim[k] then
			out.anim[k] = 0
		end
	end
	for _, a in if type(part.acc) == "table" then part.acc else {} do
		out = Appearance.without(out, a.id)
	end
	if type(part.face) == "number" and part.face > 0 and out.face == part.face then
		out.face = 0
	end
	if part.kind == "body" and type(part.scale) == "table" then
		out.scale.bodyType = 0
		out.scale.proportion = 0
	end
	return Appearance.sanitize(out)
end

-- Cards --------------------------------------------------------------------------------------------
--
-- Everything the creator shows as a card is a row shaped like a catalog result: { Id, Name,
-- ItemType = "Asset" | "Bundle" | "Outfit", AssetType }. These turn what Roblox returns elsewhere
-- into such rows.

-- A wearable asset type's name as this file spells it, however it was written ("Hair Accessory",
-- "hairaccessory"), or nil if it isn't one.
local SPELLED: { [string]: string } = {}
for name in SLOTS do
	SPELLED[name:lower()] = name
end

local function wearable(typeName: string?): string?
	if not typeName then
		return nil
	elseif SLOTS[typeName] then
		return typeName
	end
	return SPELLED[(typeName:gsub("[%s_%-]", "")):lower()]
end

-- What the player owns (rows of AvatarEditorService:GetInventoryAsync: AssetId, AssetType, Name).
-- `only` is the one asset type the page was asked for, if it was asked for one: a row that
-- doesn't say what it is, or says it in words this doesn't know, is that.
function Categories.ownedItems(rows: any, only: string?): { any }
	local out = {}
	local seen = {}
	for _, row in if type(rows) == "table" then rows else {} do
		local id = type(row) == "table" and row.AssetId
		if type(id) == "number" and id > 0 and not seen[id] then
			seen[id] = true
			local typeName = wearable(Categories.assetTypeName(row.AssetType)) or only
			table.insert(out, {
				Id = id,
				Name = if type(row.Name) == "string" and row.Name ~= "" then row.Name else "Item",
				ItemType = "Asset",
				AssetType = typeName,
			})
		end
	end
	return out
end

-- The player's saved avatars (rows of AvatarEditorService:GetOutfitsAsync: Id, Name, IsEditable).
function Categories.outfitItems(rows: any): { any }
	local out = {}
	local seen = {}
	for _, row in if type(rows) == "table" then rows else {} do
		local id = type(row) == "table" and row.Id
		if type(id) == "number" and id > 0 and not seen[id] then
			seen[id] = true
			table.insert(out, {
				Id = id,
				Name = if type(row.Name) == "string" and row.Name ~= "" then row.Name else "Avatar",
				ItemType = "Outfit",
			})
		end
	end
	return out
end

-- The parts of the given asset types inside catalog results that are bundles (each result lists
-- what is in it under BundledItems: Id, Name, Type, AssetType). One card a part, in the bundles'
-- order.
function Categories.partsIn(results: any, assetTypes: { string }): { any }
	local out = {}
	local seen = {}
	for _, result in if type(results) == "table" then results else {} do
		local inside = if type(result) == "table" then result.BundledItems else nil
		for _, item in if type(inside) == "table" then inside else {} do
			if type(item) == "table" and type(item.Id) == "number" and item.Id > 0 and not seen[item.Id] then
				local typeName = Categories.assetTypeName(item.AssetType)
				if typeName and table.find(assetTypes, typeName) then
					seen[item.Id] = true
					table.insert(out, {
						Id = item.Id,
						Name = if type(item.Name) == "string" and item.Name ~= "" then item.Name else "Item",
						ItemType = "Asset",
						AssetType = typeName,
					})
				end
			end
		end
	end
	return out
end

return Categories
