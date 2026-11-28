--!nocheck
-- Dumps the primitives of a preview scene to JSON for tools/preview/render.py.
--   lune run tools/preview/dump.luau <scene> <out.json>
-- Scenes:
--   item:<id>          one catalog item
--   cat:<category>     every item of a Build mode tab in a row
--   items:<id>,<id>    those items in a row
--   stretch:<id>       one item plain, then stretched with the Stretch pass (Build/Stretch): twice as
--                      wide, half again as tall, twice as deep, and half its size all round
--   style:<look>       every catalog item of a look (cozy, modern, scifi, garden, seaside, rustic,
--                      fancy, playful), category by category
--   fences             every kind of fence in its own finish
--   all                every catalog item in a grid
--   walls              every wall style
--   roofs              every roof style
--   house              the starter house (house:inside without its roofs)
--   copy               a copy of the starter town on the ground a visitor sees it on (Sim/PlotCopy)
--   town               the plaza's own buildings
--   town:<name>        one of them (fountain, board, tailor, shop, hall...)
--   preset:<id>        a ready-made building (cottage, family, townhouse, library, cafe...)
--   presets            all of them in a row (add :inside to leave the roofs off, or :up1 to leave
--                      the roofs off and keep the floor above the ground storey, to see upstairs)
--   ambient            the cars and the bus (ambient:<name> for one: car, parked, bus)
--   props              what random events bring into the world (props:<id>,<id> for some)
--   inside:<kind>,...  furnished rooms with the roof off (bakery, grocer, books, clothes, cafe,
--                      toys, flowers, post, lobby, flats, home, library, museum, cinema, station,
--                      school, clinic, department); a kind may carry a size: library=56x28x12
--   map                the middle of town: streets, plaza and street furniture, on the terrain
--   vehicles           every vehicle side by side (Data/Vehicles); vehicles:<id>,<id> for some
--   pets               every pet in every coat, and the two crates (Data/Pets, Data/Crates); pets:<id>,<id>
--                      for some, in their first coats
--   map:x1,z1,x2,z2    another part of town (the terrain is drawn as faceted ground of its
--                      materials' colours, finer the smaller the part, with the sea over it)
--   basement           two basement rooms dug under a patch of a plot, half under a ground floor
--                      (basement:open without it; tools/preview/basement_scene.luau)
--   joins              roofs and paths that meet, fitted together (joins:roofs, joins:paths, or one case
--                      such as joins:roofs:L; Z.joins in tools/preview/zfight_lib.luau)
--   water              a tiled pool, a pond and a stone rimmed pool with things in them
--                      (water:pool, water:pond, water:rim for one; tools/preview/water_scene.luau)
-- SEASON=1..4 in the environment draws any scene in that season (Data/Seasons, as the game's
-- client World/Seasons and the server's terrain do): spring blossom, autumn reds and golds, snow on
-- the grass, the trees and the roofs in winter (every roof here: the game asks the sky too).

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
local tris = {} -- the terrain's triangles (Terrain.preview)
local SEASON = tonumber(process.env.SEASON or "")
local Seasons = R(Shared .. "Data.Seasons")

local function addPrims(list, frame)
	-- a fir drawn as one piece is a fir in every one of its shapes (the season's snow)
	if SEASON then
		for _, p in list do
			if p.shape == "Piece" and p.parts and p.name == "Leaf" then
				for _, q in p.parts do
					q.seasonFir = true
				end
			end
		end
	end
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
elseif scene:sub(1, 6) == "items:" then
	-- a few items side by side, by id
	local defs = {}
	for id in scene:sub(7):gmatch("[^,]+") do
		table.insert(defs, (assert(Catalog.get(id), "no item " .. id)))
	end
	itemRow(defs, 8)
elseif scene:sub(1, 8) == "stretch:" then
	-- drawn the way a plot draws it (Builder.primsFor: its solid parts, then the stretch)
	local def = assert(Catalog.get(scene:sub(9)), "no item " .. scene)
	local plan = Plan.new()
	local x = 0
	for i, s in { { 1, 1, 1 }, { 2, 1, 1 }, { 1, 1.5, 1 }, { 1, 1, 2 }, { 0.5, 0.5, 0.5 } } do
		local w = def.size.X * s[1]
		local key = tostring(i)
		plan.items[key] = {
			id = def.id,
			x = x + w / 2,
			y = if def.place == "ceiling" then def.size.Y * s[2] else 0,
			z = 0,
			r = 0,
			lv = 0,
			sx = s[1],
			sy = s[2],
			sz = s[3],
		}
		addPrims(Builder.primsFor(plan, "items", key))
		x += w + 2
	end
elseif scene:sub(1, 4) == "cat:" then
	itemRow(Catalog.list(scene:sub(5)), 6)
elseif scene:sub(1, 6) == "style:" then
	itemRow(Catalog.withStyle(scene:sub(7)), 8)
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
elseif scene == "fences" then
	-- every kind of fence in its own finish (Plan.WallStyles' paint, or the game's defaults), two
	-- rows of them, with a corner in each so the ends show
	local own = { fence = "Fence", railing = "Fence", hedge = "Hedge", stone = "Stone" }
	local i = 0
	for _, style in Plan.WallStyleOrder do
		local def = Plan.WallStyles[style]
		if def.fence then
			local paint = def.paint
			if not paint then
				local Palette = R(Shared .. "Data.Palette")
				paint = Palette.Defaults[own[style] or "Fence"]
			end
			local x, z = (i % 2) * 18, math.floor(i / 2) * 7
			local w = wall(x, z, x + 12, z, style)
			w.a, w.b = paint, paint
			addPrims(Shapes.wall(w, {}))
			i += 1
		end
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
elseif scene == "house" or scene == "house:inside" then
	-- (house:inside leaves off the roofs and what stands up in them, to see in)
	local StarterHouse = R(Shared .. "Data.StarterHouse")
	local plan = StarterHouse.plan()
	for _, kind in Plan.Kinds do
		for key, obj in plan[kind] do
			if scene == "house" or (kind ~= "roofs" and (obj.lv or 0) == 0) then
				addPrims(Builder.primsFor(plan, kind, key))
			end
		end
	end
elseif scene == "copy" then
	-- a copy of a town as a visitor sees it while its owner is away (Services/Visit): the starter
	-- town on its piece of ground floating over the sea (Sim/PlotCopy), a pool dug in its garden
	local StarterHouse = R(Shared .. "Data.StarterHouse")
	local PlotCopy = R(Shared .. "Sim.PlotCopy")
	local Water = R(Shared .. "Build.Water")
	local plan = StarterHouse.plan()
	plan.waters["990"] = { x1 = 262, z1 = 150, x2 = 278, z2 = 166, lv = 0, edge = "tile", depth = "swim" }
	local copy = PlotCopy.plan(plan)
	addPrims(PlotCopy.ground(copy, 16))
	Water.drawSurface = true
	for _, kind in Plan.Kinds do
		for key in copy[kind] do
			addPrims(Builder.primsFor(copy, kind, key))
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
	-- and the ground itself, the terrain (Data/Terrain), a facet every few voxels: finer for a
	-- small part of town, coarser for the whole island
	local Terrain = R(Shared .. "Data.Terrain")
	local reg = region or { -110, -150, 110, 150 }
	local plan = Terrain.plan(TownMap.cover())
	local span = math.max(reg[3] - reg[1], reg[4] - reg[2])
	local step = math.max(4, math.floor(span / 260 / 4) * 4)
	for _, t in Terrain.preview(plan, reg, step) do
		table.insert(tris, t)
	end
elseif scene:sub(1, 7) == "preset:" or scene:sub(1, 7) == "presets" then
	-- preset:<id> one ready-made building; presets all of them in a row
	local Presets = R(Shared .. "Data.Presets")
	local ids = {}
	local inside = scene:sub(-7) == ":inside" -- leave off roofs and upper floors to see in
	local up = scene:sub(-4) == ":up1" -- leave off the roofs, keep the first floor up
	local name = if inside then scene:sub(1, -8) elseif up then scene:sub(1, -5) else scene
	if name == "presets" then
		for _, p in Presets.list do
			table.insert(ids, p.id)
		end
	else
		table.insert(ids, name:sub(8))
	end
	-- (the whole plot is the land here, so the row starts at its corner)
	local full = R(Shared .. "Config.Tuning").Plot.Size
	local plan = Plan.new(full)
	plan.size = full
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
			local keep = if inside
				then m.kind ~= "roofs" and (obj.lv or 0) == 0
				elseif up then m.kind ~= "roofs" and (obj.lv or 0) <= 1
				else true
			if keep then
				addPrims(Builder.primsFor(trial, m.kind, m.key) or {})
			end
		end
		plan = trial
		x += p.w + 6
	end
elseif scene == "vehicles" or scene:sub(1, 9) == "vehicles:" then
	-- vehicles: every vehicle side by side (Data/Vehicles), standing on the ground; vehicles:<id>,<id>
	-- for some of them
	local VehicleData = R(Shared .. "Data.Vehicles")
	local list = VehicleData.list
	if scene ~= "vehicles" then
		list = {}
		for id in scene:sub(10):gmatch("[^,]+") do
			table.insert(list, (assert(VehicleData.get(id), "no vehicle " .. id)))
		end
	end
	local x = 0
	for _, v in list do
		addPrims(VehicleData.prims(v), CFrame.new(x + v.size.X / 2, v.hover, 0))
		x += v.size.X + 3
	end
elseif scene == "pets" or scene:sub(1, 5) == "pets:" then
	-- pets: every pet in each of its coats, a row a kind, then the two crates (Data/Pets, Data/Crates)
	local PetData = R(Shared .. "Data.Pets")
	local CrateData = R(Shared .. "Data.Crates")
	local list = PetData.list
	if scene ~= "pets" then
		list = {}
		for id in scene:sub(6):gmatch("[^,]+") do
			table.insert(list, (assert(PetData.get(id), "no pet " .. id)))
		end
	end
	local z = 0
	for _, p in list do
		local x = 0
		for i = 1, if scene == "pets" then #p.coats else 1 do
			addPrims(PetData.prims(p.id, i), CFrame.new(x + p.size.X / 2, 0, z) * CFrame.Angles(0, math.rad(-35), 0))
			x += p.size.X + 1.2
		end
		z += p.size.Z + 1
	end
	if scene == "pets" then
		local x = 0
		for _, kind in CrateData.Order do
			addPrims(CrateData.prims(kind), CFrame.new(x, 0, z + 2))
			x += 4
		end
	end
elseif scene == "props" or scene:sub(1, 6) == "props:" then
	-- props or props:<id>,<id>... : the things events bring into the world (Data/EventProps)
	local EventProps = R(Shared .. "Data.EventProps")
	local ids = {}
	if scene == "props" then
		for _, p in EventProps.list do
			table.insert(ids, p.id)
		end
	else
		for id in scene:sub(7):gmatch("[^,]+") do
			table.insert(ids, id)
		end
	end
	local x, z, depth, n = 0, 0, 0, 0
	for _, id in ids do
		local p = EventProps.get(id)
		assert(p, "no prop " .. id)
		addPrims(EventProps.prims(id), CFrame.new(x + p.size.X / 2, 0, z))
		x += p.size.X + 2
		depth = math.max(depth, p.size.Z)
		n += 1
		if n % 6 == 0 then
			x, z, depth = 0, z + depth + 3, 0
		end
	end
elseif scene == "basement" or scene == "basement:open" then
	-- (the basement: two rooms dug under the ground, tools/preview/basement_scene.luau)
	addPrims(require("./basement_scene")(R, scene:sub(10)))
elseif scene == "joins" or scene:sub(1, 6) == "joins:" then
	-- (roofs and paths that meet, fitted together: Z.joins in tools/preview/zfight_lib.luau; a name picks one,
	-- joins:roofs:L)
	local want = scene:sub(7)
	local which = if want == "" then nil else want:match("^[^:]+")
	local cases = Harness.loadFile("tools/preview/zfight_lib.luau")().joins(which)
	local col, row = 0, 0
	for _, c in cases do
		if want == "" or want == which or c.name == want then
			local frame = CFrame.new(col * 56 - 100, 0, row * 44 - 100)
			for _, kind in Plan.Kinds do
				for key in c.plan[kind] do
					addPrims(Builder.primsFor(c.plan, kind, key) or {}, frame)
				end
			end
			col += 1
			if col == 4 then
				col, row = 0, row + 1
			end
		end
	end
elseif scene == "water" or scene:sub(1, 6) == "water:" then
	-- (water: pools and ponds with things in them)
	addPrims(require("./water_scene")(R, scene:sub(7)))
elseif scene == "ambient" or scene:sub(1, 8) == "ambient:" then
	-- ambient: the town's cars, the bus and a duck; ambient:<name> one of them (car, parked, bus)
	local AmbientModels = R(Shared .. "Data.AmbientModels")
	if scene == "ambient" then
		addPrims(AmbientModels.preview())
	else
		addPrims(AmbientModels.prims(scene:sub(9)))
	end
elseif scene == "town" then
	local TownModels = R(Shared .. "Data.TownModels")
	addPrims(TownModels.preview())
else
	error("unknown scene " .. scene)
end

-- A prim's colour in SEASON (Data/Seasons).
local function seasonal(p)
	if not SEASON then
		return p.color
	end
	local mat = tostring(p.mat or "Plastic"):match("^[^:]+")
	if p.seasonFir then
		return Seasons.leaf(SEASON, "fir", p.color, 0)
	elseif p.name == "Leaf" then
		local at = p.cf.Position
		local kind = Seasons.leafKind({ material = mat, shape = p.shape })
		return Seasons.leaf(SEASON, kind, p.color, Seasons.seed(at.X, at.Z))
	elseif mat == "Grass" or mat == "LeafyGrass" then
		return Seasons.grass(SEASON, p.color)
	end
	local cf, size = p.cf, p.size
	local function across(axis)
		return math.abs(cf.XVector:Dot(axis)) * size.X
			+ math.abs(cf.YVector:Dot(axis)) * size.Y
			+ math.abs(cf.ZVector:Dot(axis)) * size.Z
	end
	local tall = across(roblox.Vector3.yAxis)
	local info = {
		name = p.name,
		material = mat,
		shape = p.shape,
		top = cf.Position.Y + tall / 2,
		tall = tall,
		area = across(roblox.Vector3.xAxis) * across(roblox.Vector3.zAxis),
	}
	if Seasons.isRoof(info) then
		return Seasons.roof(SEASON, p.color)
	end
	return p.color
end

local out = {}
for _, p in prims do
	local c = { p.cf:GetComponents() }
	local color = seasonal(p)
	table.insert(out, {
		shape = p.shape,
		cf = c,
		size = { p.size.X, p.size.Y, p.size.Z },
		color = { color.R, color.G, color.B },
		transp = p.transp or 0,
		mat = p.mat,
		smooth = p.smooth,
	})
end
for _, t in tris do
	if SEASON and t.mat then
		t.color = Seasons.terrain(SEASON, t.mat, t.color)
	end
	local a, b, c = t.a, t.b, t.c
	local lo, hi = a:Min(b):Min(c), a:Max(b):Max(c)
	local mid = (lo + hi) / 2
	table.insert(out, {
		shape = "Tri",
		verts = { a.X, a.Y, a.Z, b.X, b.Y, b.Z, c.X, c.Y, c.Z },
		cf = { mid.X, mid.Y, mid.Z, 1, 0, 0, 0, 1, 0, 0, 0, 1 },
		size = { hi.X - lo.X, hi.Y - lo.Y, hi.Z - lo.Z },
		color = { t.color.R, t.color.G, t.color.B },
		transp = t.transp,
		mat = t.mat,
	})
end
local dir = outPath:match("^(.*)/[^/]*$")
if dir and not fs.isDir(dir) then
	fs.writeDir(dir)
end
fs.writeFile(outPath, serde.encode("json", out))
print(string.format("%d prims -> %s", #out, outPath))
local _ = Geometry
