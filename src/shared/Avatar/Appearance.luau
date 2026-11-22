--!strict
-- A villager's look as saved data: body colours, scales, body parts, clothes, accessories and
-- animations, all as catalog asset ids. The server turns it into a HumanoidDescription.
--
--   colors = { head, torso, la, ra, ll, rl }            hex
--   scale  = { height, width, head, depth, bodyType, proportion }
--   body   = { head, torso, la, ra, ll, rl }            asset ids, 0 = the default block body
--   face, shirt, pants, tshirt                           asset ids, 0 = none
--   acc    = { { id, t, l, o } }                         accessory id, AccessoryType name, layered, order
--   anim   = { idle, walk, run, jump, fall, climb, swim } animation asset ids, 0 = default

local Tuning = require(script.Parent.Parent.Config.Tuning)
local Colors = require(script.Parent.Parent.Util.Colors)

export type Accessory = { id: number, t: string, l: boolean, o: number? }
export type Appearance = {
	colors: { [string]: string },
	scale: { [string]: number },
	body: { [string]: number },
	face: number,
	shirt: number,
	pants: number,
	tshirt: number,
	acc: { Accessory },
	anim: { [string]: number },
}

local Appearance = {}

Appearance.ColorKeys = { "head", "torso", "la", "ra", "ll", "rl" }
Appearance.BodyKeys = { "head", "torso", "la", "ra", "ll", "rl" }
Appearance.AnimKeys = { "idle", "walk", "run", "jump", "fall", "climb", "swim" }
Appearance.ScaleKeys = { "height", "width", "head", "depth", "bodyType", "proportion" }

local SCALE_TUNING = {
	height = Tuning.Scales.Height,
	width = Tuning.Scales.Width,
	head = Tuning.Scales.Head,
	depth = Tuning.Scales.Depth,
	bodyType = Tuning.Scales.BodyType,
	proportion = Tuning.Scales.Proportion,
}
Appearance.ScaleLimits = SCALE_TUNING

-- Accessory slots: the AccessoryType name and whether it is layered clothing.
Appearance.AccessoryTypes = {
	Hat = false,
	Hair = false,
	Face = false,
	Neck = false,
	Shoulder = false,
	Front = false,
	Back = false,
	Waist = false,
	TShirt = true,
	Shirt = true,
	Pants = true,
	Jacket = true,
	Sweater = true,
	Shorts = true,
	LeftShoe = true,
	RightShoe = true,
	DressSkirt = true,
	Eyebrow = false,
	Eyelash = false,
}

-- Skin tones offered in the Skin tab.
Appearance.SkinTones = {
	"FFE0CC",
	"F8D2B4",
	"F2C9A0",
	"E8B48A",
	"D99E74",
	"C68A5E",
	"AE7148",
	"8E5A37",
	"6E4329",
	"4F2F1E",
	-- playful ones
	"F59EB5",
	"8FD3E8",
	"A8DB8A",
	"C4A8EB",
	"FFD45C",
	"D6D6D6",
}

local MAX_ID = 2 ^ 52

function Appearance.default(): Appearance
	local skin = "F2C9A0"
	return {
		colors = { head = skin, torso = "4FA9D9", la = skin, ra = skin, ll = "45454A", rl = "45454A" },
		scale = { height = 1, width = 1, head = 1, depth = 1, bodyType = 0, proportion = 0 },
		body = { head = 0, torso = 0, la = 0, ra = 0, ll = 0, rl = 0 },
		face = 0,
		shirt = 0,
		pants = 0,
		tshirt = 0,
		acc = {},
		anim = { idle = 0, walk = 0, run = 0, jump = 0, fall = 0, climb = 0, swim = 0 },
	}
end

local function cleanId(v: any): number
	if type(v) ~= "number" or v ~= v or v < 0 or v >= MAX_ID then
		return 0
	end
	return math.floor(v)
end

local function cleanNumber(v: any, lo: number, hi: number, default: number): number
	if type(v) ~= "number" or v ~= v then
		return default
	end
	return math.clamp(v, lo, hi)
end

-- Returns a safe copy of anything that claims to be an appearance.
function Appearance.sanitize(raw: any): Appearance
	local out = Appearance.default()
	if type(raw) ~= "table" then
		return out
	end
	if type(raw.colors) == "table" then
		for _, k in Appearance.ColorKeys do
			if Colors.isHex(raw.colors[k]) then
				out.colors[k] = (raw.colors[k] :: string):upper()
			end
		end
	end
	if type(raw.scale) == "table" then
		for _, k in Appearance.ScaleKeys do
			local lim = SCALE_TUNING[k]
			out.scale[k] = cleanNumber(raw.scale[k], lim.Min, lim.Max, lim.Default)
		end
	end
	if type(raw.body) == "table" then
		for _, k in Appearance.BodyKeys do
			out.body[k] = cleanId(raw.body[k])
		end
	end
	if type(raw.anim) == "table" then
		for _, k in Appearance.AnimKeys do
			out.anim[k] = cleanId(raw.anim[k])
		end
	end
	out.face = cleanId(raw.face)
	out.shirt = cleanId(raw.shirt)
	out.pants = cleanId(raw.pants)
	out.tshirt = cleanId(raw.tshirt)
	if type(raw.acc) == "table" then
		local seen = {}
		for _, a in raw.acc do
			if #out.acc >= Tuning.Villagers.MaxAccessories then
				break
			end
			if type(a) == "table" then
				local id = cleanId(a.id)
				local t = a.t
				if id > 0 and not seen[id] and type(t) == "string" and Appearance.AccessoryTypes[t] ~= nil then
					seen[id] = true
					local layered = Appearance.AccessoryTypes[t] :: boolean
					local order = if type(a.o) == "number" and a.o == a.o
						then math.clamp(math.floor(a.o), 0, 30)
						else nil
					table.insert(out.acc, { id = id, t = t, l = layered, o = order })
				end
			end
		end
	end
	return out
end

-- Every asset id an appearance uses, with the slot it sits in (for validation).
function Appearance.assets(app: Appearance): { { id: number, slot: string } }
	local out = {}
	local function add(id: number, slot: string)
		if id > 0 then
			table.insert(out, { id = id, slot = slot })
		end
	end
	for _, k in Appearance.BodyKeys do
		add(app.body[k], "body." .. k)
	end
	for _, k in Appearance.AnimKeys do
		add(app.anim[k], "anim." .. k)
	end
	add(app.face, "face")
	add(app.shirt, "shirt")
	add(app.pants, "pants")
	add(app.tshirt, "tshirt")
	for _, a in app.acc do
		add(a.id, "acc." .. a.t)
	end
	return out
end

-- Is the asset (by its AssetType name) allowed in this slot?
local SLOT_TYPES: { [string]: { string } } = {
	["body.head"] = { "Head", "DynamicHead" },
	["body.torso"] = { "Torso" },
	["body.la"] = { "LeftArm" },
	["body.ra"] = { "RightArm" },
	["body.ll"] = { "LeftLeg" },
	["body.rl"] = { "RightLeg" },
	["anim.idle"] = { "IdleAnimation" },
	["anim.walk"] = { "WalkAnimation" },
	["anim.run"] = { "RunAnimation" },
	["anim.jump"] = { "JumpAnimation" },
	["anim.fall"] = { "FallAnimation" },
	["anim.climb"] = { "ClimbAnimation" },
	["anim.swim"] = { "SwimAnimation" },
	face = { "Face" },
	shirt = { "Shirt" },
	pants = { "Pants" },
	tshirt = { "TShirt" },
	["acc.Hat"] = { "Hat" },
	["acc.Hair"] = { "HairAccessory" },
	["acc.Face"] = { "FaceAccessory" },
	["acc.Neck"] = { "NeckAccessory" },
	["acc.Shoulder"] = { "ShoulderAccessory" },
	["acc.Front"] = { "FrontAccessory" },
	["acc.Back"] = { "BackAccessory" },
	["acc.Waist"] = { "WaistAccessory" },
	["acc.TShirt"] = { "TShirtAccessory" },
	["acc.Shirt"] = { "ShirtAccessory" },
	["acc.Pants"] = { "PantsAccessory" },
	["acc.Jacket"] = { "JacketAccessory" },
	["acc.Sweater"] = { "SweaterAccessory" },
	["acc.Shorts"] = { "ShortsAccessory" },
	["acc.LeftShoe"] = { "LeftShoeAccessory" },
	["acc.RightShoe"] = { "RightShoeAccessory" },
	["acc.DressSkirt"] = { "DressSkirtAccessory" },
	["acc.Eyebrow"] = { "EyebrowAccessory" },
	["acc.Eyelash"] = { "EyelashAccessory" },
}

function Appearance.slotAllows(slot: string, assetTypeName: string): boolean
	local list = SLOT_TYPES[slot]
	return list ~= nil and table.find(list, assetTypeName) ~= nil
end

-- Removes one asset id wherever it is used.
function Appearance.without(app: Appearance, id: number): Appearance
	local out = Appearance.sanitize(app)
	for _, k in Appearance.BodyKeys do
		if out.body[k] == id then
			out.body[k] = 0
		end
	end
	for _, k in Appearance.AnimKeys do
		if out.anim[k] == id then
			out.anim[k] = 0
		end
	end
	for _, k in { "face", "shirt", "pants", "tshirt" } do
		if (out :: any)[k] == id then
			(out :: any)[k] = 0
		end
	end
	for i = #out.acc, 1, -1 do
		if out.acc[i].id == id then
			table.remove(out.acc, i)
		end
	end
	return out
end

function Appearance.equal(a: Appearance, b: Appearance): boolean
	local function same(x: any, y: any): boolean
		if type(x) ~= type(y) then
			return false
		end
		if type(x) ~= "table" then
			return x == y
		end
		for k, v in x do
			if not same(v, y[k]) then
				return false
			end
		end
		for k in y do
			if x[k] == nil then
				return false
			end
		end
		return true
	end
	return same(a, b)
end

return Appearance
