--!strict
-- The villager creator's tabs, the catalog searches behind them, and how a catalog item is worn.

local Appearance = require(script.Parent.Appearance)

export type Filter = { id: string, name: string, assets: { string }?, bundles: { string }? }
export type Tab = { id: string, name: string, filters: { Filter }? }

local Categories = {}

local function A(id: string, name: string, assets: { string }): Filter
	return { id = id, name = name, assets = assets }
end

local function B(id: string, name: string, bundles: { string }): Filter
	return { id = id, name = name, bundles = bundles }
end

local tabs: { Tab } = {
	{ id = "wearing", name = "Wearing" },
	{ id = "hair", name = "Hair", filters = { A("hair", "Hair", { "HairAccessory" }) } },
	{
		id = "heads",
		name = "Heads",
		filters = { A("faces", "Faces", { "Face" }), B("dynheads", "Heads", { "DynamicHead" }) },
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
	{ id = "shoes", name = "Shoes", filters = { B("shoes", "Shoes", { "Shoes" }) } },
	{ id = "bodies", name = "Bodies", filters = { B("bodies", "Bodies", { "BodyParts" }) } },
	{ id = "moves", name = "Moves", filters = { B("moves", "Moves", { "Animations" }) } },
	{ id = "skin", name = "Skin" },
	{ id = "shape", name = "Shape" },
	{ id = "outfits", name = "Outfits" },
	-- avatars made by players: the people here, your friends, and looks shared from this creator
	{ id = "people", name = "Players" },
}

Categories.Tabs = tabs

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

-- Merges part of an appearance (from a bundle) over a full one.
function Categories.merge(app: Appearance.Appearance, part: any): Appearance.Appearance
	local out = Appearance.sanitize(app)
	if type(part) ~= "table" then
		return out
	end
	if part.kind == "body" then
		-- a whole body replaces the last one: nothing of the old torso and limbs stays behind
		-- (the head stays unless the new body brings its own)
		for _, k in { "torso", "la", "ra", "ll", "rl" } do
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
	if part.kind == "body" and type(part.scale) == "table" then
		out.scale.bodyType = 0
		out.scale.proportion = 0
	end
	return Appearance.sanitize(out)
end

return Categories
