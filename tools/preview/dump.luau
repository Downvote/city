--!nocheck
-- Dumps the primitives of a preview scene to JSON for tools/preview/render.py.
--   lune run tools/preview/dump.luau <scene> <out.json>
-- Scenes:
--   item:<id>          one catalog item
--   cat:<category>     every item of a Build mode tab in a row
--   all                every catalog item in a grid
--   walls              every wall style
--   roofs              every roof style
--   house              the starter house
--   town               the plaza's own buildings
--   town:<name>        one of them (fountain, board, tailor, shop, hall...)
--   preset:<id>        a ready-made building (cottage, family, townhouse, library, cafe...)
--   presets            all of them in a row (add :inside to leave the roofs off)
--   ambient            the cars and the bus
--   inside:<kind>,...  furnished rooms with the roof off (bakery, grocer, books, clothes, cafe,
--                      toys, flowers, post, lobby, flats, home, library, museum, cinema, station,
--                      school, clinic, department); a kind may carry a size: library=56x28x12
--   map                the middle of town: streets, plaza and street furniture
--   map:x1,z1,x2,z2    another part of town

local fs = require("@lune/fs")
local process = require("@lune/process")
local serde = require("@lune/serde")
local roblox = require("@lune/roblox")
local CFrame = roblox.CFrame
local Harness = require("../../tests/harness")

Harness.init(".")
local R = Harness.require

local Shared = "ReplicatedStorage.Shared."
local Catalog = R(Shared .. "Build.Catalog")
local Plan = R(Shared .. "Build.Plan")
local Shapes = R(Shared .. "Build.Shapes")
local Geometry = R(Shared .. "Build.Geometry")
local Builder = R(Shared .. "Build.Builder")

local scene = process.args[1] or "all"
local outPath = process.args[2] or "out/preview.json"

local prims = {}

local function addPrims(list, frame)
	-- a piece (Geometry.piece) is drawn as the shapes it is made of
	for _, p in Geometry.flatten(list) do
		local q = table.clone(p)
		if frame then
			q.cf = frame * p.cf
		end
		table.insert(prims, q)
	end
end

local function itemRow(defs, perRow)
	perRow = perRow or 8
	local x, z, rowDepth = 0, 0, 0
	local count = 0
	for _, def in defs do
		local s = def.size
		local frame = CFrame.new(x + s.X / 2, 0, z)
		if def.place == "ceiling" then
			frame = CFrame.new(x + s.X / 2, s.Y, z)
		end
		addPrims(Catalog.prims(def), frame)
		x += s.X + 2
		rowDepth = math.max(rowDepth, s.Z)
		count += 1
		if count % perRow == 0 then
			x = 0
			z += rowDepth + 3
			rowDepth = 0
		end
	end
end

local function wall(x1, z1, x2, z2, style, lv)
	return {
		x1 = x1,
		z1 = z1,
		x2 = x2,
		z2 = z2,
		lv = lv or 0,
		style = style,
		a = { c = "F2E8D5", m = "Plaster" },
		b = { c = "D9C7A7", m = "SmoothPlastic" },
	}
end

if scene:sub(1, 5) == "item:" then
	local def = Catalog.get(scene:sub(6))
	assert(def, "no item " .. scene)
	itemRow({ def })
elseif scene:sub(1, 4) == "cat:" then
	itemRow(Catalog.list(scene:sub(5)), 6)
elseif scene == "all" then
	itemRow(Catalog.all(), 12)
elseif scene == "walls" then
	local z = 0
	for _, style in Plan.WallStyleOrder do
		local w = wall(0, z, 12, z, style)
		local s = Shapes.wall(w, {})
		addPrims(s)
		z += 6
	end
elseif scene == "roofs" then
	local x = 0
	for _, style in Plan.RoofStyleOrder do
		local r = {
			x1 = x,
			z1 = 0,
			x2 = x + 16,
			z2 = 12,
			lv = 0,
			style = style,
			rise = 6,
			dir = 0,
			over = 1,
			c = "9C2A2E",
			m = "Slate",
			c2 = "F2E8D5",
			m2 = "Plaster",
		}
		addPrims(Shapes.roof(r))
		x += 22
	end
elseif scene == "house" then
	local StarterHouse = R(Shared .. "Data.StarterHouse")
	local plan = StarterHouse.plan()
	for _, kind in Plan.Kinds do
		for key in plan[kind] do
			addPrims(Builder.primsFor(plan, kind, key))
		end
	end
elseif scene:sub(1, 5) == "town:" then
	local TownModels = R(Shared .. "Data.TownModels")
	addPrims(TownModels.prims(scene:sub(6)))
elseif scene:sub(1, 7) == "inside:" then
	-- inside:<kind>,<kind>... : furnished rooms with the roof off (Data/Interiors). A kind may
	-- give its own size as kind=WxDxH.
	local Interiors = R(Shared .. "Data.Interiors")
	local Recipe = R(Shared .. "Build.Recipe")
	local x = 0
	for entry in scene:sub(8):gmatch("[^,]+") do
		local kind, w, d, h = entry:match("^(%a+)=(%d+)x(%d+)x(%d+)$")
		kind = kind or entry
		local W, D, H = tonumber(w) or 28, tonumber(d) or 22, tonumber(h) or 8.4
		local C3 = roblox.Color3
		local r = Recipe.new(C3.new(1, 1, 1), C3.new(1, 1, 1))
		local box = Interiors.shell(r, { w = W, d = D, h = H, wall = C3.fromRGB(250, 214, 170), mat = "Brick" })
		Interiors.fill(r, kind, box, C3.fromRGB(110, 160, 230))
		addPrims(r.prims, CFrame.new(x + W / 2, 0, 0))
		x += W + 6
	end
elseif scene:sub(1, 7) == "models:" then
	-- models:<name>,<name>... : the map's own models side by side, by the names placements use
	local TownMap = R(Shared .. "Data.TownMap")
	local Geometry = R(Shared .. "Build.Geometry")
	local x, z, depth, n = 0, 0, 0, 0
	for name in scene:sub(8):gmatch("[^,]+") do
		local list = TownMap.prims(name)
		local lo, hi = Geometry.bounds(list)
		addPrims(list, CFrame.new(x - lo.X, 0, z - lo.Z))
		x += (hi.X - lo.X) + 4
		depth = math.max(depth, hi.Z - lo.Z)
		n += 1
		if n % 6 == 0 then
			x = 0
			z += depth + 5
			depth = 0
		end
	end
elseif scene == "map" or scene:sub(1, 4) == "map:" then
	-- map or map:x1,z1,x2,z2 (the middle of town by default)
	local TownMap = R(Shared .. "Data.TownMap")
	local region = nil
	if scene:sub(1, 4) == "map:" then
		region = {}
		for n in scene:sub(5):gmatch("[^,]+") do
			table.insert(region, tonumber(n))
		end
	end
	addPrims(TownMap.preview(region))
elseif scene:sub(1, 7) == "preset:" or scene:sub(1, 7) == "presets" then
	-- preset:<id> one ready-made building; presets all of them in a row
	local Presets = R(Shared .. "Data.Presets")
	local ids = {}
	local inside = scene:sub(-7) == ":inside" -- leave off roofs and upper floors to see in
	local name = if inside then scene:sub(1, -8) else scene
	if name == "presets" then
		for _, p in Presets.list do
			table.insert(ids, p.id)
		end
	else
		table.insert(ids, name:sub(8))
	end
	local plan = Plan.new(200)
	plan.size = 200
	local x, z, rowDepth = 0, 0, 0
	for _, id in ids do
		local p = Presets.get(id)
		assert(p, "no preset " .. id)
		if x + p.w > 200 then -- start a new row
			x, z, rowDepth = 0, z + rowDepth + 8, 0
		end
		rowDepth = math.max(rowDepth, p.d)
		local _, why, _, trial, made = Presets.check(plan, Presets.requests(id, x, z, 0))
		assert(why == nil, id .. ": " .. tostring(why))
		for _, m in made do
			local obj = trial[m.kind][m.key]
			if not inside or (m.kind ~= "roofs" and (obj.lv or 0) == 0) then
				addPrims(Builder.primsFor(trial, m.kind, m.key) or {})
			end
		end
		plan = trial
		x += p.w + 6
	end
elseif scene == "ambient" then
	local AmbientModels = R(Shared .. "Data.AmbientModels")
	addPrims(AmbientModels.preview())
elseif scene == "town" then
	local TownModels = R(Shared .. "Data.TownModels")
	addPrims(TownModels.preview())
else
	error("unknown scene " .. scene)
end

local out = {}
for _, p in prims do
	local c = { p.cf:GetComponents() }
	table.insert(out, {
		shape = p.shape,
		cf = c,
		size = { p.size.X, p.size.Y, p.size.Z },
		color = { p.color.R, p.color.G, p.color.B },
		transp = p.transp or 0,
		mat = p.mat,
	})
end
local dir = outPath:match("^(.*)/[^/]*$")
if dir and not fs.isDir(dir) then
	fs.writeDir(dir)
end
fs.writeFile(outPath, serde.encode("json", out))
print(string.format("%d prims -> %s", #out, outPath))
local _ = Geometry
