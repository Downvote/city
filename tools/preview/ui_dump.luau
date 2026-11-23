--!nocheck
-- Builds one of the game's screens on the client simulation (tests/sim/client.luau) and writes
-- its GUI tree to JSON for tools/preview/ui_render.py to lay out and draw.
--   lune run tools/preview/ui_dump.luau <scene> <out.json>
-- Scenes:
--   hud                 the main screen
--   build               Build mode on the Furniture tab
--   build:walls         Build mode on Walls
--   build:pick          Build mode with a piece of furniture picked (the action bar)
--   panel:<Name>        a panel over the main screen (Residents, CityPanel, ShopPanel, News, Welcome)
--   event               an event playing in the dialogue box
--   toasts              a few notices
--   icons               every icon, big and small
--   creator             the villager creator on the hair tab

local fs = require("@lune/fs")
local process = require("@lune/process")
local serde = require("@lune/serde")
local roblox = require("@lune/roblox")

local scene = process.args[1] or "hud"
local outPath = process.args[2] or "out/ui.json"

local Sim = require("../../tests/sim/client")
local Harness = Sim.Harness
local Fake = Sim.Fake
local UDim2, Color3, Enum, Instance = roblox.UDim2, roblox.Color3, roblox.Enum, Sim.env.Instance

-- sample town ------------------------------------------------------------------------------------------

local Schema = Harness.require("ReplicatedStorage.Shared.Sim.Schema")
local Appearance = Harness.require("ReplicatedStorage.Shared.Avatar.Appearance")
local Rng = Harness.require("ReplicatedStorage.Shared.Util.Rng")
local City = Harness.require("ReplicatedStorage.Shared.Sim.City")

local villagers, order = {}, {}
local names = { { "Mara", "sunny" }, { "Tobin", "shy" }, { "Ivy", "bold" }, { "Pell", "dreamy" } }
for i, n in names do
	local input = Schema.cleanVillagerInput({ name = n[1], pers = n[2], app = Appearance.default() })
	local v = Schema.newVillager("v" .. i, input, Rng.new(i))
	v.mood = 60 + i * 7
	villagers[v.id] = v
	table.insert(order, v.id)
end
local first = villagers[order[1]]
first.job = City.freeWorkplace({ plan = Sim.State.plan, villagers = villagers })
Sim.profile.villagers = villagers
Sim.profile.order = order
Sim.profile.coins = 12450

local function pushState()
	Sim.remoteEvent("State"):FireClient(Sim.player, {
		coins = Sim.profile.coins,
		villagers = villagers,
		order = order,
		daily = { last = -5, streak = 2 },
		log = {
			{ t = os.time(), text = "Mara and Tobin made up after their quarrel." },
			{ t = os.time(), text = "Ivy found 40 coins by the fountain." },
		},
	})
	Sim.frames(2)
end
pushState()
Sim.ws:SetAttribute("Season", 2)
Sim.ws:SetAttribute("Day", 7)
Sim.ws:SetAttribute("Weather", "clear")

local Hud
local function startHud()
	Hud = Harness.require(Sim.CLIENT .. "UI.Hud")
	Hud.start()
	Sim.frames(3)
	Sim.advance(2)
end

-- scenes -----------------------------------------------------------------------------------------------

if scene == "hud" then
	startHud()
elseif scene:sub(1, 5) == "build" then
	startHud()
	Sim.BuildMode.enter()
	Sim.frames(3)
	if scene == "build" or scene == "build:pick" then
		Sim.press("Furniture")
	end
	if scene == "build:pick" then
		local tray = Sim.gui:FindFirstChild("Tray", true)
		local cards = Fake.find(tray, function(d)
			return d:IsA("TextButton") and Fake.shown(d) and d:GetAttribute("ItemId") ~= nil
		end)
		cards[3].Activated:Fire()
		Sim.frames(2)
		Sim.mouseAtPlot(118, 60)
		Sim.click()
		Sim.press("Pick")
		Sim.mouseAtPlot(118, 60, 1)
		Sim.click()
		Sim.mouseAtPlot(140, 90)
	end
	Sim.frames(3)
elseif scene:sub(1, 6) == "panel:" then
	startHud()
	Hud.open(scene:sub(7))
	Sim.frames(3)
elseif scene == "event" then
	startHud()
	Sim.remoteEvent("EventShow"):FireClient(Sim.player, {
		token = "e1",
		title = "A quarrel by the fountain",
		names = { a = "Mara", b = "Tobin" },
		lines = {
			{ who = "a", text = "You took the last bun from the bakery again." },
		},
		choices = {
			{ text = "Side with Mara" },
			{ text = "Side with Tobin" },
			{ text = "Buy them both a bun", cost = 40 },
		},
	})
	Sim.advance(8)
elseif scene == "toasts" then
	startHud()
	local Toasts = Harness.require(Sim.CLIENT .. "UI.Toasts")
	Toasts.show("Payday: 186 coins from 3 workers.", "good")
	Toasts.show("Not enough coins for that.", "warn")
	Toasts.show("Ivy wants a lamp by her bed.", "event")
	Sim.frames(2)
elseif scene == "creator" then
	Harness.addService("AvatarEditorService", {
		SearchCatalogAsync = function()
			error("no catalog in the preview")
		end,
	})
	Sim.env.CatalogSearchParams = {
		new = function()
			return {}
		end,
	}
	local names =
		{ "Messy bun", "Short curls", "Long waves", "Side part", "Braids", "Spiky top", "Bob cut", "Ponytail" }
	Sim.remoteFn("CreatorSearch").OnServerInvoke = function()
		local items = {}
		for i, n in names do
			table.insert(items, { Id = 1000 + i, Name = n, ItemType = "Asset", AssetType = "HairAccessory" })
		end
		return items
	end
	startHud()
	Hud.open("Creator", { mode = "new" })
	Sim.frames(3)
	Sim.advance(1)
elseif scene == "icons" then
	local Icons = Harness.require(Sim.CLIENT .. "UI.Icons")
	local Kit = Sim.Kit
	local sheet = Kit.frame({
		Parent = Sim.gui,
		Size = UDim2.fromScale(1, 1),
		Color = Color3.fromRGB(236, 241, 248),
		Radius = false,
	})
	local grid = Instance.new("UIGridLayout")
	grid.CellSize = UDim2.fromOffset(104, 104)
	grid.CellPadding = UDim2.fromOffset(4, 4)
	grid.Parent = sheet
	for i, name in Icons.names() do
		local cell = Kit.box({ Parent = sheet, LayoutOrder = i })
		Icons.make(name, 60, { Parent = cell, Position = UDim2.new(0.5, -30, 0, 4) })
		Icons.make(name, 24, { Parent = cell, Position = UDim2.new(0, 2, 0, 2) })
		Kit.text(name, {
			Parent = cell,
			Size = UDim2.new(1, 0, 0, 16),
			Position = UDim2.new(0, 0, 1, -18),
			TextSize = 13,
			AlignX = Enum.TextXAlignment.Center,
		})
	end
else
	error("unknown scene " .. scene)
end

-- dumping ----------------------------------------------------------------------------------------------

local PROPS = {
	"Size",
	"Position",
	"AnchorPoint",
	"Visible",
	"BackgroundColor3",
	"BackgroundTransparency",
	"ZIndex",
	"LayoutOrder",
	"AutomaticSize",
	"ClipsDescendants",
	"Rotation",
	"Text",
	"TextColor3",
	"TextSize",
	"Font",
	"TextXAlignment",
	"TextYAlignment",
	"TextWrapped",
	"TextScaled",
	"TextTransparency",
	"TextStrokeTransparency",
	"TextStrokeColor3",
	"TextTruncate",
	"MaxVisibleGraphemes",
	"Image",
	"ImageColor3",
	"ImageTransparency",
	"CanvasSize",
	"AutomaticCanvasSize",
	"ScrollingDirection",
	"ScrollBarThickness",
	"CornerRadius",
	"Color",
	"Thickness",
	"Transparency",
	"ApplyStrokeMode",
	"Enabled",
	"Offset",
	"PaddingLeft",
	"PaddingRight",
	"PaddingTop",
	"PaddingBottom",
	"Padding",
	"FillDirection",
	"HorizontalAlignment",
	"VerticalAlignment",
	"SortOrder",
	"Wraps",
	"CellSize",
	"CellPadding",
	"Scale",
	"AspectRatio",
	"MaxSize",
	"MinSize",
	"IgnoreGuiInset",
	"MaxTextSize",
	"MinTextSize",
}

local function encode(v)
	local t = typeof(v)
	if t == "UDim2" then
		return { v.X.Scale, v.X.Offset, v.Y.Scale, v.Y.Offset }
	elseif t == "UDim" then
		return { v.Scale, v.Offset }
	elseif t == "Vector2" then
		return { v.X, v.Y }
	elseif t == "Color3" then
		return { v.R, v.G, v.B }
	elseif t == "EnumItem" then
		return v.Name
	elseif t == "ColorSequence" then
		local out = {}
		for _, k in v.Keypoints do
			table.insert(out, { k.Time, k.Value.R, k.Value.G, k.Value.B })
		end
		return out
	elseif t == "NumberSequence" then
		local out = {}
		for _, k in v.Keypoints do
			table.insert(out, { k.Time, k.Value })
		end
		return out
	elseif t == "number" or t == "string" or t == "boolean" then
		return v
	end
	return nil
end

local function dump(inst)
	local node = { class = inst.ClassName, name = inst.Name, props = {}, children = {} }
	for _, prop in PROPS do
		local ok, v = pcall(function()
			return rawget(inst, "_real")[prop]
		end)
		if ok and v ~= nil then
			node.props[prop] = encode(v)
		end
	end
	local itemId = inst:GetAttribute("ItemId")
	if itemId then
		node.itemId = itemId
	end
	for _, c in rawget(inst, "_children") do
		table.insert(node.children, dump(c))
	end
	return node
end

local root = dump(Sim.gui)
local dir = outPath:match("^(.*)/[^/]*$")
if dir and not fs.isDir(dir) then
	fs.writeDir(dir)
end
fs.writeFile(outPath, serde.encode("json", { viewport = { 1280, 720 }, inset = 36, root = root }))
print(string.format("ui %s -> %s (%d warnings)", scene, outPath, #Sim.errors))
for _, e in Sim.errors do
	print("  warning: " .. e:sub(1, 300))
end
