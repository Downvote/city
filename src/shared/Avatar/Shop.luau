--!strict
-- Buying what a villager wears on Roblox (the user: "allow players to buy items they select from
-- the villager customization screen, and allow players to buy the outfit of the villager,
-- including from the profile of the villager"). Roblox sells the items, not this game: Roblox's own
-- purchase prompt goes up, one for the whole look from the server (Services/Avatar's BuyLook:
-- Roblox lets only server scripts ask for MarketplaceService:PromptBulkPurchase), one thing at a
-- time from the client where that fails (UI/BuyLook). This file works out what a look is made of
-- as things Roblox sells.
--
-- A look holds asset ids. Clothes, faces and accessories are sold one by one. Body parts and
-- animation sets are only sold inside bundles, so they are bought as the bundle they came in when
-- the creator knows it (`bundles`: the bundles worn, as { id, part }), and left out otherwise.

local Appearance = require(script.Parent.Appearance)
local Categories = require(script.Parent.Categories)

local Shop = {}

export type Line = { kind: string, id: number } -- kind "asset" or "bundle"

-- What to ask Roblox to sell for a look, at most `most` things: the bundles worn first, then
-- clothes, the face and the accessories. Body parts and animations no bundle accounts for are
-- left out (Roblox doesn't sell them by themselves).
function Shop.lines(app: any, bundles: { { id: number, part: any } }?, most: number): { Line }
	local look = Appearance.sanitize(app)
	local out: { Line } = {}
	local taken: { [number]: boolean } = {}
	local function add(kind: string, id: number)
		if #out < most and id > 0 and not taken[id] then
			taken[id] = true
			table.insert(out, { kind = kind, id = id })
		end
	end
	local covered: { [number]: boolean } = {}
	local sets: { { id: number, part: any } } = bundles or {}
	for _, b in sets do
		if type(b.id) == "number" and Categories.bundleWorn(look, b.part) then
			add("bundle", b.id)
			local part = b.part
			for _, k in Appearance.BodyKeys do
				local id = type(part.body) == "table" and part.body[k]
				if type(id) == "number" then
					covered[id] = true
				end
			end
			for _, k in Appearance.AnimKeys do
				local id = type(part.anim) == "table" and part.anim[k]
				if type(id) == "number" then
					covered[id] = true
				end
			end
			for _, a in if type(part.acc) == "table" then part.acc else {} do
				if type(a) == "table" and type(a.id) == "number" then
					covered[a.id] = true
				end
			end
		end
	end
	for _, id in { look.shirt, look.pants, look.tshirt, look.face } do
		if not covered[id] then
			add("asset", id)
		end
	end
	for _, a in look.acc do
		if not covered[a.id] then
			add("asset", a.id)
		end
	end
	return out
end

-- The lines a client asks the server to put up as one prompt, made safe: each { kind "asset" or
-- "bundle", a whole positive id }, no id twice, at most `most` (Roblox takes 20 in one prompt).
-- Nil when there is nothing usable.
function Shop.clean(raw: any, most: number): { Line }?
	if type(raw) ~= "table" then
		return nil
	end
	local out: { Line } = {}
	local seen: { [string]: boolean } = {}
	for _, line in raw do
		if #out >= most then
			break
		end
		if type(line) == "table" and (line.kind == "asset" or line.kind == "bundle") then
			local id = line.id
			if type(id) == "number" and id == id and id > 0 and id % 1 == 0 and id < 2 ^ 53 then
				local key = line.kind .. ":" .. string.format("%d", id)
				if not seen[key] then
					seen[key] = true
					local kind: string = line.kind
					table.insert(out, { kind = kind, id = id })
				end
			end
		end
	end
	return if #out > 0 then out else nil
end

-- Is a catalog row for sale, as far as the row says? false when it says it isn't (off sale, or
-- not sold by itself), true when it gives a price, nil when it doesn't say.
function Shop.forSale(item: any): boolean?
	if type(item) ~= "table" then
		return nil
	end
	if item.ItemType == "Outfit" then
		return false
	end
	if item.IsOffSale == true or item.IsForSale == false then
		return false
	end
	local status = item.PriceStatus
	if type(status) == "string" then
		local s = string.lower(status)
		if s:find("off") or s:find("not for sale") or s:find("no resellers") then
			return false
		end
	end
	if type(item.Price) == "number" or type(item.LowestPrice) == "number" then
		return true
	end
	return nil
end

return Shop
