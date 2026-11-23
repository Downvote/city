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
--   town               the town's own small models (the news board, the welcome sign, a plot's sign)
--   town:<name>        one of them (board, sign, plotSign)
--   preset:<id>        a ready-made building (cottage, family, townhouse, library, cafe...)
--   presets            all of them in a row (add :inside to leave the roofs off)
--   ambient            the cars and the bus
--   models:<key>,...   city pack kit keys side by side (bank, government_a, tree_03...)
--   map                the whole town: the city pack as Data/CityMap lays it out, the plots, the sea
--   map:x1,z1,x2,z2    a part of it

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
elseif scene:sub(1, 7) == "models:" then
	-- models:<key>,<key>... : city pack kit keys side by side (Data/CityPack), drawn from the
	-- preview cache by tools/preview/citypack.py (as boxes without it)
	local CityMap = R(Shared .. "Data.CityMap")
	local x, z, depth, n = 0, 0, 0, 0
	for key in scene:sub(8):gmatch("[^,]+") do
		local def = CityMap.kit(key)
		assert(def, "no kit key " .. key)
		local c, s = CityMap.keyBox(key)
		local cf = CFrame.new(x + s.X / 2 - c.X, s.Y / 2 - c.Y, z + s.Z / 2 - c.Z)
		table.insert(prims, {
			shape = "Pack",
			key = key,
			cf = cf,
			size = s,
			color = CityMap.StandIn[def.kind] or roblox.Color3.new(0.7, 0.7, 0.7),
			mat = "SmoothPlastic",
		})
		x += s.X + 6
		depth = math.max(depth, s.Z)
		n += 1
		if n % 6 == 0 then
			x = 0
			z += depth + 8
			depth = 0
		end
	end
elseif scene == "map" or scene:sub(1, 4) == "map:" then
	-- map or map:x1,z1,x2,z2: the town as Data/CityMap lays out the city pack, with the plots,
	-- the middle of town's own things and the sea round it (the whole town by default). Pack
	-- objects are written as "Pack" prims that tools/preview/citypack.py draws from the kit.
	local CityMap = R(Shared .. "Data.CityMap")
	local Town = R(Shared .. "Data.Town")
	local TownModels = R(Shared .. "Data.TownModels")
	local Tuning = R(Shared .. "Config.Tuning")
	local C3 = roblox.Color3
	local V3 = roblox.Vector3
	local o = CityMap.Offset
	local rect = CityMap.PackRect
	local region = { rect[1] + o.X - 300, rect[2] + o.Z - 300, rect[3] + o.X + 300, rect[4] + o.Z + 300 }
	if scene:sub(1, 4) == "map:" then
		region = {}
		for n in scene:sub(5):gmatch("[^,]+") do
			table.insert(region, tonumber(n))
		end
		-- the pack's objects are cut to the region when they are drawn (tools/preview/citypack.py)
		local mid = V3.new((region[1] + region[3]) / 2, 0, (region[2] + region[4]) / 2)
		table.insert(prims, {
			shape = "Clip",
			cf = CFrame.new(mid),
			size = V3.new(region[3] - region[1], 1, region[4] - region[2]),
			color = C3.new(1, 1, 1),
			mat = "SmoothPlastic",
			transp = 1,
		})
	end
	local function inside(lo, hi)
		return hi.X >= region[1] and lo.X <= region[3] and hi.Z >= region[2] and lo.Z <= region[4]
	end
	for _, p in CityMap.placements() do
		if inside(p.lo, p.hi) then
			table.insert(prims, {
				shape = "Pack",
				key = p.key,
				scale = p.scale,
				cf = p.cf,
				size = p.hi - p.lo,
				color = CityMap.StandIn[p.kind] or C3.new(0.7, 0.7, 0.7),
				mat = "SmoothPlastic",
			})
		end
	end
	local function clipBox(cf, size)
		local lo, hi = cf.Position - size / 2, cf.Position + size / 2
		local a = V3.new(math.max(lo.X, region[1]), lo.Y, math.max(lo.Z, region[2]))
		local b = V3.new(math.min(hi.X, region[3]), hi.Y, math.min(hi.Z, region[4]))
		if b.X <= a.X or b.Z <= a.Z then
			return nil
		end
		return CFrame.new((a + b) / 2), b - a
	end
	do
		local cf, size = CityMap.filler()
		cf, size = clipBox(cf, size)
		if cf then
			table.insert(
				prims,
				{ shape = "Block", cf = cf, size = size, color = CityMap.StandIn.ground, mat = "SmoothPlastic" }
			)
		end
	end
	for _, s in CityMap.sea() do
		if s.name == "Water" then
			local cf, size = clipBox(s.cf, s.size)
			if cf then
				table.insert(
					prims,
					{ shape = "Block", cf = cf, size = size, color = CityMap.StandIn.water, mat = "SmoothPlastic" }
				)
			end
		end
	end
	local SIZE = Tuning.Plot.Size
	for i = 1, Tuning.Plot.Count do
		local f = Town.plotFrame(i)
		local cf, size = clipBox(f * CFrame.new(SIZE / 2, -0.5, SIZE / 2), V3.new(SIZE, 1, SIZE))
		if cf then
			table.insert(
				prims,
				{ shape = "Block", cf = cf, size = size, color = CityMap.PlotGround, mat = "SmoothPlastic" }
			)
		end
		local at = f * CFrame.new(SIZE / 2, 0, -1.6) * CFrame.Angles(0, math.pi, 0)
		if inside(at.Position, at.Position) then
			addPrims(TownModels.prims("plotSign"), at)
		end
	end
	for _, p in CityMap.Props do
		local at = CFrame.new(p.x, 0, p.z) * CFrame.Angles(0, math.rad(p.yaw), 0)
		if inside(at.Position, at.Position) then
			addPrims(TownModels.prims(p.model), at)
		end
	end
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
		key = p.key, -- a "Pack" prim: its kit key and stretch (tools/preview/citypack.py)
		scale = if p.scale then { p.scale.X, p.scale.Y, p.scale.Z } else nil,
	})
end
local dir = outPath:match("^(.*)/[^/]*$")
if dir and not fs.isDir(dir) then
	fs.writeDir(dir)
end
fs.writeFile(outPath, serde.encode("json", out))
print(string.format("%d prims -> %s", #out, outPath))
local _ = Geometry
