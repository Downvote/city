--!nocheck
-- Dumps the primitives of a preview scene to JSON for tools/preview/render.py.
--   lune run tools/preview/dump.luau <scene> <out.json>
-- Scenes:
--   item:<id>          one catalog item
--   cat:<category>     every item of a Build mode tab in a row
--   items:<id>,<id>    those items in a row
--   style:<look>       every catalog item of a look (cozy, modern, scifi, garden, seaside, rustic,
--                      fancy, playful), category by category
--   fences             every kind of fence in its own finish
--   all                every catalog item in a grid
--   walls              every wall style
--   roofs              every roof style
--   house              the starter house (house:inside without its roofs)
--   town               the plaza's own buildings
--   town:<name>        one of them (fountain, board, tailor, shop, hall...)
--   preset:<id>        a ready-made building (cottage, family, townhouse, library, cafe...)
--   presets            all of them in a row (add :inside to leave the roofs off, or :up1 to leave
--                      the roofs off and keep the floor above the ground storey, to see upstairs)
--   ambient            the cars and the bus
--   props              what random events bring into the world (props:<id>,<id> for some)
--   inside:<kind>,...  furnished rooms with the roof off (bakery, grocer, books, clothes, cafe,
--                      toys, flowers, post, lobby, flats, home, library, museum, cinema, station,
--                      school, clinic, department); a kind may carry a size: library=56x28x12
--   map                the middle of town: streets, plaza and street furniture, on the terrain
--   map:x1,z1,x2,z2    another part of town (the terrain is drawn as faceted ground of its
--                      materials' colours, finer the smaller the part, with the sea over it)
--   stage:<id>         a cutscene's set (Data/Stages); tools/preview/stage.sh draws it from its shots
--   basement           two basement rooms dug under a patch of a plot, half under a ground floor
--                      (basement:open without it; tools/preview/basement_scene.luau)
--   water              a tiled pool, a pond and a stone rimmed pool with things in them
--                      (water:pool, water:pond, water:rim for one; tools/preview/water_scene.luau)

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
elseif scene:sub(1, 6) == "items:" then
	-- a few items side by side, by id
	local defs = {}
	for id in scene:sub(7):gmatch("[^,]+") do
		table.insert(defs, (assert(Catalog.get(id), "no item " .. id)))
	end
	itemRow(defs, 8)
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
elseif scene == "water" or scene:sub(1, 6) == "water:" then
	-- (water: pools and ponds with things in them)
	addPrims(require("./water_scene")(R, scene:sub(7)))
elseif scene == "ambient" then
	local AmbientModels = R(Shared .. "Data.AmbientModels")
	addPrims(AmbientModels.preview())
elseif scene == "town" then
	local TownModels = R(Shared .. "Data.TownModels")
	addPrims(TownModels.preview())
elseif scene:sub(1, 6) == "stage:" then
	-- stage:<id> a cutscene's set (Data/Stages). Its light, sky, shots and a stand-in figure on
	-- each mark go beside the JSON (<out>.stage.json) for tools/preview/stage.py, which draws the
	-- set from its shots as the game's viewport lights it (tools/preview/stage.sh does both)
	local Stages = R(Shared .. "Data.Stages")
	local s = assert(Stages.get(scene:sub(7)), "no stage " .. scene:sub(7))
	addPrims(Stages.prims(s.id))
	local function v(x)
		return { x.X, x.Y, x.Z }
	end
	local function c(x)
		return { x.R, x.G, x.B }
	end
	local function shot(sh)
		return { eye = v(sh.eye), look = v(sh.look), fov = sh.fov, sky = sh.sky }
	end
	local shots = {}
	for _, e in Stages.allShots(s) do
		shots[e.name] = shot(e.shot)
	end
	for name, sh in s.shots do
		if sh.to then
			shots[name .. ":mid"] =
				shot({ eye = sh.eye:Lerp(sh.to.eye, 0.5), look = sh.look:Lerp(sh.to.look, 0.5), fov = sh.fov })
		end
	end
	-- a stand-in on each mark: legs, body, arms and a head with two eyes on the side it faces
	local figures = {}
	local SHIRTS = {
		roblox.Color3.fromRGB(232, 120, 110),
		roblox.Color3.fromRGB(110, 156, 222),
		roblox.Color3.fromRGB(240, 196, 92),
	}
	for i, m in s.marks do
		local cf = CFrame.new(m.at) * CFrame.Angles(0, math.rad(m.yaw) + math.pi, 0)
		local skin, legs = roblox.Color3.fromRGB(236, 196, 160), roblox.Color3.fromRGB(70, 78, 110)
		local parts = {}
		local function box(x, y, z, sx, sy, sz, col)
			table.insert(parts, { cf = cf * CFrame.new(x, y, z), size = roblox.Vector3.new(sx, sy, sz), color = col })
		end
		if m.sit then
			for _, sx in { -0.5, 0.5 } do
				box(sx, 0.3, -0.9, 0.9, 0.7, 2.0, legs)
				box(sx, -0.6, -1.75, 0.9, 1.6, 0.8, legs)
			end
		else
			for _, sx in { -0.5, 0.5 } do
				box(sx, 1.0, 0, 0.9, 2.0, 0.9, legs)
			end
		end
		local t = if m.sit then 0.3 else 2.0
		box(0, t + 1.0, 0, 2.0, 2.0, 1.0, SHIRTS[i] or SHIRTS[1])
		for _, sx in { -1.45, 1.45 } do
			box(sx, t + 1.0, 0, 0.9, 2.0, 0.9, SHIRTS[i] or SHIRTS[1])
		end
		box(0, t + 2.6, 0, 1.2, 1.2, 1.2, skin)
		box(0, t + 3.3, 0.05, 1.3, 0.35, 1.3, roblox.Color3.fromRGB(96, 70, 60))
		for _, sx in { -0.25, 0.25 } do
			box(sx, t + 2.65, -0.62, 0.16, 0.22, 0.06, roblox.Color3.fromRGB(40, 36, 44))
		end
		for _, p in parts do
			table.insert(figures, {
				shape = "Block",
				cf = { p.cf:GetComponents() },
				size = { p.size.X, p.size.Y, p.size.Z },
				color = { p.color.R, p.color.G, p.color.B },
				transp = 0,
				mat = "SmoothPlastic",
			})
		end
	end
	local sky = {}
	for k, x in s.sky do
		if typeof(x) == "Color3" then
			sky[k] = c(x)
		elseif type(x) == "table" then
			sky[k] = { dir = v(x.dir), size = x.size, color = c(x.color), glow = x.glow and c(x.glow), phase = x.phase }
		else
			sky[k] = x
		end
	end
	fs.writeFile(
		outPath .. ".stage.json",
		serde.encode("json", {
			id = s.id,
			light = { ambient = c(s.light.ambient), color = c(s.light.color), dir = v(s.light.dir) },
			sky = sky,
			shots = shots,
			bounds = { lo = v(s.bounds.lo), hi = v(s.bounds.hi) },
			figures = figures,
		})
	)
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
for _, t in tris do
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
