--!strict
-- The creator's Shuffle (the user: "for shuffle the whole look, make it such that it chooses from
-- the ones roblox recommends to the player the most"). For each slot it shuffles, the client asks
-- Roblox for its recommendations (AvatarEditorService:GetRecommendedAssets, seeded by what is worn
-- there or, failing that, by what the player wears on Roblox), and picks among the first few it
-- gives, the first ones likelier. Where Roblox gives nothing, the popular catalog page stands in.
-- This file has the plain rules: reading what Roblox returns, the seed, the pick, wearing it.

local Appearance = require(script.Parent.Appearance)
local Categories = require(script.Parent.Categories)

local Shuffle = {}

-- The slots Shuffle changes, in order. `chance` is how often a slot is changed at all (a hat
-- only now and then); `clear` is the accessory slot emptied first, so the pick replaces what is
-- there.
export type Slot = { type: string, chance: number?, clear: string? }
Shuffle.Slots = {
	{ type = "HairAccessory", clear = "Hair" },
	{ type = "Shirt" },
	{ type = "Pants" },
	{ type = "Face" },
	{ type = "Hat", chance = 0.4, clear = "Hat" },
} :: { Slot }

-- The id worn in the slot for that asset type, or nil.
function Shuffle.wornIn(app: any, typeName: string): number?
	local slot = Categories.slotFor(typeName)
	if not slot or type(app) ~= "table" then
		return nil
	end
	local id: any = nil
	if slot.kind == "acc" then
		for _, a in if type(app.acc) == "table" then app.acc else {} do
			if type(a) == "table" and a.t == slot.key then
				id = a.id
				break
			end
		end
	elseif slot.kind == "face" then
		id = app.face
	elseif slot.kind == "field" then
		id = app[slot.key]
	elseif slot.kind == "body" then
		id = type(app.body) == "table" and app.body[slot.key]
	elseif slot.kind == "anim" then
		id = type(app.anim) == "table" and app.anim[slot.key]
	end
	return if type(id) == "number" and id > 0 then id else nil
end

-- What Roblox's recommendations are seeded with: what is worn in that slot, else what the player
-- wears there on Roblox (`own`, their own avatar as a look), else nothing.
function Shuffle.seed(app: any, own: any, typeName: string): number?
	return Shuffle.wornIn(app, typeName) or Shuffle.wornIn(own, typeName)
end

-- The rows of GetRecommendedAssets ({ Item = { AssetId, Name }, ... }; flatter shapes are read
-- too) as cards' rows: { Id, Name, ItemType = "Asset", AssetType }.
function Shuffle.rows(result: any, typeName: string): { any }
	local out = {}
	local seen = {}
	for _, row in if type(result) == "table" then result else {} do
		if type(row) == "table" then
			local item = if type(row.Item) == "table" then row.Item else row
			local id = item.AssetId or item.Id or row.AssetId or row.Id
			if type(id) == "number" and id > 0 and id % 1 == 0 and not seen[id] then
				seen[id] = true
				local name = item.Name or row.Name
				table.insert(out, {
					Id = id,
					Name = if type(name) == "string" and name ~= "" then name else "Item",
					ItemType = "Asset",
					AssetType = typeName,
				})
			end
		end
	end
	return out
end

-- The rows of GetRecommendedBundles ({ Id, Name, ... }, or with the bundle under `Item`).
function Shuffle.bundleRows(result: any): { any }
	local out = {}
	local seen = {}
	for _, row in if type(result) == "table" then result else {} do
		if type(row) == "table" then
			local item = if type(row.Item) == "table" then row.Item else row
			local id = item.Id or item.BundleId or row.Id
			if type(id) == "number" and id > 0 and id % 1 == 0 and not seen[id] then
				seen[id] = true
				local name = item.Name or row.Name
				table.insert(out, {
					Id = id,
					Name = if type(name) == "string" and name ~= "" then name else "Set",
					ItemType = "Bundle",
				})
			end
		end
	end
	return out
end

-- Picks one of the first `top` rows (Roblox lists its strongest recommendations first, so the
-- first is likeliest: weights top, top - 1, ... 1), leaving out ids in `avoid` (what is worn now,
-- so a shuffle changes something). `roll` is a number from 0 to 1. Nil when there is nothing.
function Shuffle.pick(rows: { any }, roll: number, top: number, avoid: { [number]: boolean }?): any?
	local pool = {}
	for _, row in rows do
		if #pool >= top then
			break
		end
		if not (avoid and avoid[row.Id]) then
			table.insert(pool, row)
		end
	end
	local n = #pool
	if n == 0 then
		return nil
	end
	local total = n * (n + 1) / 2
	local at = math.clamp(roll, 0, 0.999999) * total
	for i, row in pool do
		at -= n - i + 1
		if at < 0 then
			return row
		end
	end
	return pool[n]
end

-- Puts a picked asset on in its slot, in place of what was there.
function Shuffle.wear(app: any, row: any, slot: Slot): Appearance.Appearance
	local out = Appearance.sanitize(app)
	if slot.clear then
		for i = #out.acc, 1, -1 do
			if out.acc[i].t == slot.clear then
				table.remove(out.acc, i)
			end
		end
	end
	if not Categories.isWorn(out, row.Id) then
		out = Categories.toggle(out, row.Id, slot.type)
	end
	return out
end

return Shuffle
