--!strict
-- What a catalog bundle is, and what wearing one changes.
--
-- A bundle is a whole body, a head, a pair of shoes or a set of animations. Roblox labels each
-- with a BundleType and hands over what is in it two ways: as outfits (a look each) and as a list
-- of assets. Neither can be taken at its word:
--   a body carries two outfits, its own and one for its head alone, and the head's comes last;
--   a body sold with an animated head may be labelled "DynamicHeadAvatar", which has "Head" in it.
-- Reading only the last outfit is how picking a body came to change nothing but the head (the
-- user: "bodies only changes the head of the character"), and going by the words in the label
-- would do the same. So the creator says what it is after (the tab it is in), a label is read as
-- a whole body before it is read as a head, and what is in the bundle has the last word: a body
-- is the outfit that brings a torso or a limb.
--
-- Nothing here calls Roblox. The server (Services/Avatar) fetches the details and the outfits and
-- passes them in; the specs pass in made up ones.

local Appearance = require(script.Parent.Appearance)
local Categories = require(script.Parent.Categories)

export type Asset = { id: number, type: string }
export type Details = {
	label: any, -- the BundleType as Roblox gives it: its name, the enum item or its number
	looks: { Appearance.Appearance }, -- the bundle's outfits as looks, in the order they came
	assets: { Asset }, -- the bundle's own assets, each with its AssetType name
}
-- What Categories.merge puts on: only the ids a bundle sets are in it.
export type Part = {
	kind: string,
	body: { [string]: number },
	anim: { [string]: number },
	acc: { Appearance.Accessory },
	face: number?,
	scale: { [string]: number }?,
}

local Bundles = {}

-- What a bundle can be, a whole body first: that is the order its contents are read in.
Bundles.Kinds = { "body", "head", "shoes", "anim" }

function Bundles.isKind(v: any): boolean
	return type(v) == "string" and table.find(Bundles.Kinds, v) ~= nil
end

local LABELS: { [string]: string } = {
	BodyParts = "body",
	DynamicHeadAvatar = "body",
	DynamicHead = "head",
	Shoes = "shoes",
	Animations = "anim",
	AvatarAnimations = "anim",
}
-- Enum.BundleType's numbers
local LABEL_NUMBERS = { "BodyParts", "Animations", "Shoes", "DynamicHead", "DynamicHeadAvatar" }

-- The kind a BundleType label stands for, or nil if it says nothing this knows.
function Bundles.kindOfLabel(label: any): string?
	local name: string? = nil
	if type(label) == "string" then
		name = label
	elseif type(label) == "number" then
		name = LABEL_NUMBERS[label]
	elseif typeof(label) == "EnumItem" then
		name = (label :: EnumItem).Name
	end
	if not name then
		return nil
	end
	local known = LABELS[name]
	if known then
		return known
	end
	-- a label newer than this list: go by the words in it, a whole body before a head
	if name:find("Animation") then
		return "anim"
	elseif name:find("Shoe") then
		return "shoes"
	elseif name:find("Avatar") or name:find("Body") then
		return "body"
	elseif name:find("Head") then
		return "head"
	end
	return nil
end

local LIMBS = { "torso", "la", "ra", "ll", "rl" }

local function limbs(body: { [string]: number }): number
	local n = 0
	for _, k in LIMBS do
		if (body[k] or 0) > 0 then
			n += 1
		end
	end
	return n
end

local function anyAnim(anim: { [string]: number }): boolean
	for _, k in Appearance.AnimKeys do
		if (anim[k] or 0) > 0 then
			return true
		end
	end
	return false
end

local function isShoe(a: Appearance.Accessory): boolean
	return a.t == "LeftShoe" or a.t == "RightShoe"
end

local function isBrow(a: Appearance.Accessory): boolean
	return a.t == "Eyebrow" or a.t == "Eyelash"
end

-- Adds the accessories that pass `test`, one to a slot, the first found winning.
local function take(
	into: { Appearance.Accessory },
	from: { Appearance.Accessory },
	test: (Appearance.Accessory) -> boolean
)
	for _, a in from do
		if test(a) and a.id > 0 then
			local taken = false
			for _, have in into do
				taken = taken or have.t == a.t
			end
			if not taken then
				table.insert(into, { id = a.id, t = a.t, l = a.l, o = a.o })
			end
		end
	end
end

-- Everything the bundle's own asset list holds, sorted into slots.
local function sorted(assets: { Asset }): Part
	local out: Part = { kind = "", body = {}, anim = {}, acc = {} }
	for _, a in assets do
		local slot = if type(a.type) == "string" then Categories.slotFor(a.type) else nil
		if slot and type(a.id) == "number" and a.id > 0 then
			if slot.kind == "body" then
				-- a head that can move its face is the one a new body is drawn with
				if (out.body[slot.key] or 0) == 0 or a.type == "DynamicHead" then
					out.body[slot.key] = a.id
				end
			elseif slot.kind == "anim" then
				if (out.anim[slot.key] or 0) == 0 then
					out.anim[slot.key] = a.id
				end
			elseif slot.kind == "acc" then
				table.insert(out.acc, { id = a.id, t = slot.key, l = Appearance.AccessoryTypes[slot.key] == true })
			elseif slot.kind == "face" and not out.face then
				out.face = a.id
			end
		end
	end
	return out
end

-- Has wearing this anything to change?
function Bundles.isEmpty(part: any): boolean
	if type(part) ~= "table" then
		return true
	end
	if type(part.body) == "table" and next(part.body) ~= nil then
		return false
	end
	if type(part.anim) == "table" and next(part.anim) ~= nil then
		return false
	end
	if type(part.acc) == "table" and #part.acc > 0 then
		return false
	end
	return not (type(part.face) == "number" and part.face > 0)
end

-- What wearing the bundle changes. `wanted` is the kind the player was browsing for (the tab),
-- or nil to go by the label. If the bundle holds nothing of that kind it is worn as what it
-- does hold, so a head found among the bodies changes the head and leaves the rest alone.
function Bundles.part(details: Details, wanted: string?): Part
	local loose = sorted(details.assets)
	-- the outfit with the most of a body in it, and the one nearest to a head by itself
	local bodyLook: Appearance.Appearance? = nil
	local most = 0
	local headLook: Appearance.Appearance? = nil
	local fewest = math.huge
	for _, look in details.looks do
		local n = limbs(look.body)
		if n > most then
			bodyLook, most = look, n
		end
		if look.body.head > 0 and n < fewest then
			headLook, fewest = look, n
		end
	end

	local function holds(kind: string): boolean
		if kind == "body" then
			return most > 0 or limbs(loose.body) > 0
		elseif kind == "head" then
			return headLook ~= nil or (loose.body.head or 0) > 0
		elseif kind == "anim" then
			for _, look in details.looks do
				if anyAnim(look.anim) then
					return true
				end
			end
			return anyAnim(loose.anim)
		end
		for _, look in details.looks do
			for _, a in look.acc do
				if isShoe(a) then
					return true
				end
			end
		end
		for _, a in loose.acc do
			if isShoe(a) then
				return true
			end
		end
		return false
	end

	local kind: string? = if Bundles.isKind(wanted) then wanted else Bundles.kindOfLabel(details.label)
	if not kind or not holds(kind) then
		local found: string? = nil
		for _, k in Bundles.Kinds do
			if not found and holds(k) then
				found = k
			end
		end
		kind = found or kind or "body"
	end

	local part: Part = { kind = kind :: string, body = {}, anim = {}, acc = {} }
	if kind == "body" then
		if bodyLook then
			for _, k in Appearance.BodyKeys do
				if bodyLook.body[k] > 0 then
					part.body[k] = bodyLook.body[k]
				end
			end
			if bodyLook.face > 0 then
				part.face = bodyLook.face
			end
			-- the build that goes with the body (how tall and wide stays the player's choice)
			part.scale = { bodyType = bodyLook.scale.bodyType, proportion = bodyLook.scale.proportion }
		end
		-- whatever the outfit left out, from the bundle's own list
		for _, k in Appearance.BodyKeys do
			if (part.body[k] or 0) == 0 and (loose.body[k] or 0) > 0 then
				part.body[k] = loose.body[k]
			end
		end
		if (part.body.head or 0) == 0 and headLook then
			part.body.head = headLook.body.head
		end
		if not part.face and loose.face then
			part.face = loose.face
		end
	elseif kind == "head" then
		local head = if headLook then headLook.body.head else (loose.body.head or 0)
		if head > 0 then
			part.body.head = head
		end
	elseif kind == "shoes" then
		for _, look in details.looks do
			take(part.acc, look.acc, isShoe)
		end
		take(part.acc, loose.acc, isShoe)
	else
		for _, k in Appearance.AnimKeys do
			for _, look in details.looks do
				if (part.anim[k] or 0) == 0 and look.anim[k] > 0 then
					part.anim[k] = look.anim[k]
				end
			end
			if (part.anim[k] or 0) == 0 and (loose.anim[k] or 0) > 0 then
				part.anim[k] = loose.anim[k]
			end
		end
	end
	if (part.body.head or 0) > 0 then
		-- a head comes with its brows and lashes
		for _, look in details.looks do
			if look.body.head == part.body.head then
				take(part.acc, look.acc, isBrow)
			end
		end
		take(part.acc, loose.acc, isBrow)
	end
	return part
end

return Bundles
