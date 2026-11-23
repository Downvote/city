--!strict
-- Who moves in next when someone turns up at the edge of town. The user: "make the random
-- villagers that move in the player's friends first, then default ones if all of them are
-- already in. no repeats".
--
-- So: the player's Roblox friends come first (the server hands in the list; they arrive with
-- their own avatar and name), one at a time and in no order. Once every friend has moved in, the
-- town's own newcomers below follow, each with a name, a nature and a look of their own. Nobody
-- comes twice: a villager remembers who they came as (`from`), and the profile remembers everyone
-- who has ever arrived (`arrived`). Only when every friend and every newcomer has been does
-- someone who moved out get to come back, friends first again.
--
-- Shared and free of services, so the specs can run it.

local Tuning = require(script.Parent.Parent.Config.Tuning)
local Appearance = require(script.Parent.Parent.Avatar.Appearance)

export type Friend = { id: number, name: string }

-- One of the town's own newcomers. The clothes and hair are free catalog items made by Roblox.
export type Own = {
	id: string,
	name: string,
	pers: string,
	skin: string,
	hair: number, -- a hair accessory, 0 for none
	hat: number, -- a hat, 0 for none
	shirt: number,
	pants: number,
	height: number,
	width: number,
}

-- Who is next: a friend (`userId` set) or one of the town's own (`own` set).
export type Pick = { key: string, name: string, userId: number?, own: Own? }

local Newcomers = {}

-- free hair, hats, shirts and trousers by Roblox
local PAL, BROWN, SPIKED, CHARMER = 63690008, 62234425, 376524487, 376548738
local LONG_RED, STRAIGHT, BLUE, UPDO = 2956239660, 376526888, 451221329, 451220849
local CAP, R_CAP = 607702162, 417457461
local MOTO, PIZZA, JERSEY, DENIM, GUITAR, JACKET = 144076358, 382537085, 382538059, 398633584, 4047884046, 607785314
local PLAID, PASTEL, STRIPED, TEAL, PURPLE, PATTERN = 398635081, 398634295, 144076436, 382537702, 4047886060, 3670737444
local GREEN_JEANS, BLACK_JEANS, WHITE_SHOES, SKATER = 144076760, 382537569, 398633812, 398635338
local BLUE_JEANS, SHORTS, SHORTS_SHOES, SNEAKERS = 398634487, 382537806, 382537950, 382538503

local function own(
	id: string,
	name: string,
	pers: string,
	skin: string,
	hair: number,
	hat: number,
	shirt: number,
	pants: number,
	height: number,
	width: number
): Own
	return {
		id = id,
		name = name,
		pers = pers,
		skin = skin,
		hair = hair,
		hat = hat,
		shirt = shirt,
		pants = pants,
		height = height,
		width = width,
	}
end

-- No two share a name, and no two share hair and clothes.
Newcomers.list = {
	own("pip", "Pip", "sunny", "F2C9A0", PAL, 0, PIZZA, SHORTS_SHOES, 0.9, 0.95),
	own("juno", "Juno", "bold", "AE7148", UPDO, 0, PURPLE, BLACK_JEANS, 1.05, 0.9),
	own("basil", "Basil", "easygoing", "E8B48A", BROWN, 0, PLAID, GREEN_JEANS, 1.1, 1.05),
	own("wren", "Wren", "shy", "FFE0CC", STRAIGHT, 0, PASTEL, BLUE_JEANS, 0.92, 0.85),
	own("otto", "Otto", "proud", "C68A5E", CHARMER, 0, JACKET, WHITE_SHOES, 1.12, 1.1),
	own("mabel", "Mabel", "gentle", "F8D2B4", LONG_RED, 0, STRIPED, BLUE_JEANS, 0.98, 0.95),
	own("rufus", "Rufus", "cheeky", "D99E74", SPIKED, 0, GUITAR, SKATER, 1, 1),
	own("ivy", "Ivy", "dreamy", "8E5A37", BLUE, 0, TEAL, SHORTS, 0.94, 0.88),
	own("hugo", "Hugo", "bold", "F2C9A0", 0, CAP, MOTO, BLACK_JEANS, 1.15, 1.08),
	own("clover", "Clover", "sunny", "6E4329", UPDO, 0, JERSEY, SHORTS_SHOES, 0.96, 0.92),
	own("milo", "Milo", "cheeky", "FFE0CC", BROWN, R_CAP, PATTERN, SNEAKERS, 0.88, 0.95),
	own("hazel", "Hazel", "gentle", "C68A5E", LONG_RED, 0, DENIM, GREEN_JEANS, 1.02, 0.9),
	own("fern", "Fern", "shy", "E8B48A", STRAIGHT, 0, TEAL, WHITE_SHOES, 0.9, 0.85),
	own("toby", "Toby", "easygoing", "AE7148", PAL, 0, STRIPED, SKATER, 1.08, 1.05),
	own("nell", "Nell", "proud", "F8D2B4", BLUE, 0, PURPLE, BLACK_JEANS, 1, 0.88),
	own("ziggy", "Ziggy", "dreamy", "D99E74", SPIKED, 0, PASTEL, SHORTS, 0.95, 1),
	own("poppy", "Poppy", "sunny", "4F2F1E", STRAIGHT, 0, PIZZA, BLUE_JEANS, 0.9, 0.9),
	own("arlo", "Arlo", "easygoing", "8E5A37", CHARMER, 0, JERSEY, SNEAKERS, 1.1, 1),
	own("daisy", "Daisy", "gentle", "F2C9A0", UPDO, 0, PLAID, SHORTS_SHOES, 0.93, 0.9),
	own("remy", "Remy", "cheeky", "E8B48A", 0, R_CAP, GUITAR, GREEN_JEANS, 1.04, 1.02),
} :: { Own }

local byId: { [string]: Own } = {}
for _, e in Newcomers.list do
	byId[e.id] = e
end

function Newcomers.friendKey(userId: number): string
	return "u" .. string.format("%d", userId)
end

function Newcomers.ownKey(id: string): string
	return "d:" .. id
end

-- The user id behind a friend's key, if it is one.
function Newcomers.userId(key: any): number?
	if type(key) ~= "string" then
		return nil
	end
	local digits = key:match("^u(%d+)$")
	return if digits then tonumber(digits) else nil
end

-- One of the town's own newcomers by key.
function Newcomers.own(key: any): Own?
	if type(key) ~= "string" then
		return nil
	end
	local id = key:match("^d:(.+)$")
	return if id then byId[id] else nil
end

-- A name that fits on a villager, or nil when it can't be one.
function Newcomers.cleanName(name: any): string?
	if type(name) ~= "string" then
		return nil
	end
	local s = name:gsub("[%c]", ""):gsub("^%s+", ""):gsub("%s+$", "")
	local length = utf8.len(s)
	if #s < 1 or length == nil or length > Tuning.Villagers.NameMaxLength then
		return nil
	end
	return s
end

-- The look one of the town's own newcomers arrives in.
function Newcomers.look(e: Own): Appearance.Appearance
	local app = Appearance.default()
	for _, k in { "head", "la", "ra", "ll", "rl", "torso" } do
		app.colors[k] = e.skin
	end
	app.shirt = e.shirt
	app.pants = e.pants
	if e.hair > 0 then
		table.insert(app.acc, { id = e.hair, t = "Hair", l = false })
	end
	if e.hat > 0 then
		table.insert(app.acc, { id = e.hat, t = "Hat", l = false })
	end
	app.scale.height = e.height
	app.scale.width = e.width
	return Appearance.sanitize(app)
end

-- Is whoever this key stands for living in town now?
function Newcomers.inTown(profile: any, key: string): boolean
	for _, vid in profile.order do
		local v = profile.villagers[vid]
		if v and v.from == key then
			return true
		end
	end
	return false
end

-- Who moves in next, or nil when there is nobody left to come. `friends` is the player's
-- Roblox friends; `rng` only picks among people who are equally due.
function Newcomers.next(profile: any, friends: { Friend }, rng: any): Pick?
	local here: { [string]: boolean } = {}
	local names: { [string]: boolean } = {}
	for _, vid in profile.order do
		local v = profile.villagers[vid]
		if v then
			if type(v.from) == "string" then
				here[v.from] = true
			end
			if type(v.name) == "string" then
				names[string.lower(v.name)] = true
			end
		end
	end
	local arrived: { [string]: boolean } = if type(profile.arrived) == "table" then profile.arrived else {}

	local new: { Pick }, back: { Pick } = {}, {}
	local listed: { [string]: boolean } = {}
	for _, f in friends do
		if type(f) == "table" and type(f.id) == "number" and f.id > 0 then
			local key = Newcomers.friendKey(f.id)
			local name = Newcomers.cleanName(f.name)
			if name and not here[key] and not listed[key] then
				listed[key] = true
				table.insert(if arrived[key] then back else new, { key = key, name = name, userId = f.id })
			end
		end
	end
	if #new > 0 then
		return rng:pick(new)
	end

	local ownNew: { Pick }, ownBack: { Pick } = {}, {}
	for _, e in Newcomers.list do
		local key = Newcomers.ownKey(e.id)
		-- a villager the player made and gave the same name counts as that name being taken
		if not here[key] and not names[string.lower(e.name)] then
			table.insert(if arrived[key] then ownBack else ownNew, { key = key, name = e.name, own = e })
		end
	end
	if #ownNew > 0 then
		return rng:pick(ownNew)
	end
	-- everyone has been once: someone who moved out may come back
	if #back > 0 then
		return rng:pick(back)
	end
	if #ownBack > 0 then
		return rng:pick(ownBack)
	end
	return nil
end

-- Notes that a villager came as `key`, so they never come again while they live here, and not
-- before everyone else has had a turn if they leave.
function Newcomers.arrive(profile: any, villager: any, key: string)
	villager.from = key
	if type(profile.arrived) ~= "table" then
		profile.arrived = {}
	end
	profile.arrived[key] = true
end

return Newcomers
