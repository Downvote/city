--!strict
-- Ready-made buildings for Build mode's Buildings tab: houses and a little park here, and one
-- building for every workplace in a file of its own under Data/Buildings (loaded at the bottom). Each is made of ordinary plan pieces (walls, floors,
-- roofs, doors, windows, furniture), so once it's down it can be repainted, moved, added to or
-- sold piece by piece like anything else. Shops and public buildings come with their workplace,
-- so they open a job as soon as they're built.
--
-- A preset is laid out in its own frame: x across, z from the front (z = 0, the side that faces
-- the street when it isn't turned) to the back, everything on the 2 stud wall grid.
-- Presets.requests turns one into Build requests at a spot on the plot, turned by 0, 90, 180 or
-- 270 degrees. Doors and windows name their wall as "@n": the n-th request in the same batch
-- (the server fills in the wall's real key once it has made it).

local Plan = require(script.Parent.Parent.Build.Plan)
local Catalog = require(script.Parent.Parent.Build.Catalog)
local Tuning = require(script.Parent.Parent.Config.Tuning)

local Presets = {}

local F = Tuning.Plot.Foundation

type Finish = { c: string, m: string }
type Obj = { kind: string, obj: any, name: string?, wallName: string? }
export type Preset = {
	id: string,
	name: string,
	desc: string,
	icon: string,
	w: number,
	d: number,
	objects: { Obj },
}

-- finishes, from the town's palette: light walls, roofs a few steps darker and only gently
-- coloured, the same trim white on every house
local PLASTER = { c = "F6F0E2", m = "Plaster" } -- warm white
local WHITE = { c = "F7F3EA", m = "SmoothPlastic" }
local CREAM = { c = "F2E6CC", m = "SmoothPlastic" }
local BRICK = { c = "D8A48E", m = "Brick" } -- soft brick
local SIDING_BLUE = { c = "B4CFEA", m = "WoodPlanks" } -- sky
local OAK = { c = "C49A6C", m = "WoodPlanks" }
local WALNUT = { c = "9A6B48", m = "WoodPlanks" }
local TILES = { c = "F7F3EA", m = "CeramicTiles" }
local CARPET_BLUE = { c = "8AA8C8", m = "Carpet" }
local PAVING = { c = "EAE6DC", m = "Pavement" }
local SAGE_TILE = { c = "8CAC8A", m = "ClayRoofTiles" }
local SLATE = { c = "6E8CA8", m = "Slate" } -- slate blue
local SHINGLE_BROWN = { c = "B87C64", m = "RoofShingles" } -- a clay brown

-- A little builder for laying a preset out.
local Blueprint = {}
Blueprint.__index = Blueprint

type Blueprint = typeof(setmetatable({} :: { objects: { Obj }, walls: { [string]: any } }, Blueprint))

local function blueprint(): Blueprint
	return setmetatable({ objects = {}, walls = {} }, Blueprint)
end

function Blueprint.floor(self: Blueprint, x1: number, z1: number, x2: number, z2: number, finish: Finish, lv: number?)
	table.insert(self.objects, {
		kind = "floors",
		obj = { x1 = x1, z1 = z1, x2 = x2, z2 = z2, lv = lv or 0, c = finish.c, m = finish.m },
	})
end

function Blueprint.wall(
	self: Blueprint,
	name: string,
	x1: number,
	z1: number,
	x2: number,
	z2: number,
	outside: Finish,
	inside: Finish,
	lv: number?
)
	local w = {
		x1 = x1,
		z1 = z1,
		x2 = x2,
		z2 = z2,
		lv = lv or 0,
		style = "wall",
		a = { c = outside.c, m = outside.m },
		b = { c = inside.c, m = inside.m },
	}
	self.walls[name] = w
	table.insert(self.objects, { kind = "walls", obj = w, name = name })
end

-- Four walls round a rectangle, named <prefix>front, right, back and left. They run the way
-- the starter house's do, so side "a" is the outside.
function Blueprint.box(
	self: Blueprint,
	prefix: string,
	x1: number,
	z1: number,
	x2: number,
	z2: number,
	outside: Finish,
	inside: Finish,
	lv: number?
)
	self:wall(prefix .. "front", x1, z1, x2, z1, outside, inside, lv)
	self:wall(prefix .. "right", x2, z1, x2, z2, outside, inside, lv)
	self:wall(prefix .. "back", x2, z2, x1, z2, outside, inside, lv)
	self:wall(prefix .. "left", x1, z2, x1, z1, outside, inside, lv)
end

function Blueprint.roof(
	self: Blueprint,
	x1: number,
	z1: number,
	x2: number,
	z2: number,
	style: string,
	rise: number,
	dir: number,
	finish: Finish,
	gable: Finish,
	lv: number?,
	over: number?
)
	table.insert(self.objects, {
		kind = "roofs",
		obj = {
			x1 = x1,
			z1 = z1,
			x2 = x2,
			z2 = z2,
			lv = lv or 0,
			style = style,
			rise = rise,
			dir = dir,
			over = over or 1,
			c = finish.c,
			m = finish.m,
			c2 = gable.c,
			m2 = gable.m,
		},
	})
end

-- A door or window `t` studs along a wall.
function Blueprint.open(self: Blueprint, id: string, wallName: string, t: number, side: string?)
	local def = Catalog.get(id)
	local w = self.walls[wallName]
	assert(def and def.opening and w, "bad opening " .. id .. " on " .. wallName)
	table.insert(self.objects, {
		kind = "items",
		obj = {
			id = id,
			x = 0,
			y = Plan.openingY(w, (def.opening :: any).sill),
			z = 0,
			r = 0,
			lv = w.lv,
			t = t,
			side = side or "a",
		},
		wallName = wallName,
	})
end

-- A free-standing piece. Indoors it stands on the floor; `ground` pieces go on the grass.
function Blueprint.item(self: Blueprint, id: string, x: number, z: number, r: number?, lv: number?, y: number?)
	local def = Catalog.get(id)
	assert(def, "no catalog item " .. id)
	local level = lv or 0
	local height = y
	if height == nil then
		if def.place == "ceiling" then
			height = Plan.levelTop(level) - (if level < Tuning.Plot.Levels - 1 then 1 else 0)
		elseif def.place == "ground" then
			height = 0
		else
			height = if level == 0 then F else Plan.levelBase(level)
		end
	end
	table.insert(self.objects, {
		kind = "items",
		obj = { id = id, x = x, y = height, z = z, r = r or 0, lv = level },
	})
end

-- the buildings ------------------------------------------------------------------------------------

local list: { Preset } = {}

local function add(id: string, name: string, desc: string, icon: string, w: number, d: number, build: (Blueprint) -> ())
	local b = blueprint()
	build(b)
	local made = { id = id, name = name, desc = desc, icon = icon, w = w, d = d, objects = b.objects }
	-- a building defined again takes the place of the one before it
	for i, old in list do
		if old.id == id then
			list[i] = made
			return
		end
	end
	table.insert(list, made)
end

add("cottage", "Garden cottage", "One room to live in, a bedroom and a kitchen corner.", "house", 24, 24, function(b)
	b:floor(2, 6, 22, 22, OAK)
	b:box("", 2, 6, 22, 22, PLASTER, WHITE)
	b:wall("inner", 12, 22, 12, 14, WHITE, WHITE)
	b:roof(2, 6, 22, 22, "gable", 6, 0, SAGE_TILE, PLASTER)
	b:open("door_front", "front", 10)
	b:open("win_shutters", "front", 4)
	b:open("win_shutters", "front", 16)
	b:open("win_square", "right", 5)
	b:open("win_square", "right", 12)
	b:open("win_square", "back", 5)
	b:open("win_square", "back", 15)
	b:open("win_square", "left", 5)
	b:open("win_square", "left", 12)
	b:open("arch_open", "inner", 4)
	-- the bedroom, back left
	b:item("bed_single", 5, 18, 180)
	b:item("nightstand", 8.6, 20.6, 180)
	b:item("lamp_floor", 10.6, 15.6)
	-- the kitchen corner, back right
	b:item("counter", 14, 20.4, 180)
	b:item("stove", 17, 20.4, 180)
	b:item("fridge", 20.2, 20.4, 180)
	b:item("table_dining_small", 17, 15.6)
	b:item("chair_dining", 17, 13.4)
	b:item("chair_dining", 19.4, 15.6, 270)
	-- the front room
	b:item("rug_round", 7, 10.6)
	b:item("sofa_two", 7, 8.2)
	b:item("table_coffee", 7, 11)
	b:item("armchair", 4, 11.6, 90)
	b:item("plant_big", 20, 8.4)
	b:item("light_ceiling", 7, 10)
	b:item("light_ceiling", 16, 17)
	-- the front garden
	b:item("path_stones", 12, 4)
	b:item("path_stones", 12, 1.6)
	b:item("flower_bed", 5, 3)
	b:item("flower_bed", 19, 3)
	b:item("bush", 8.4, 2.6)
	b:item("mailbox", 22.6, 1.6)
end)

add("family", "Family house", "A living room, a kitchen, two bedrooms and a bathroom.", "house", 32, 28, function(b)
	b:floor(2, 6, 30, 16, OAK)
	b:floor(2, 16, 12, 26, CARPET_BLUE)
	b:floor(12, 16, 20, 26, TILES)
	b:floor(20, 16, 30, 26, WALNUT)
	b:box("", 2, 6, 30, 26, SIDING_BLUE, WHITE)
	b:wall("hall", 2, 16, 30, 16, WHITE, WHITE)
	b:wall("bath1", 12, 16, 12, 26, WHITE, WHITE)
	b:wall("bath2", 20, 16, 20, 26, WHITE, WHITE)
	b:roof(2, 6, 30, 26, "hip", 7, 0, SHINGLE_BROWN, WHITE)
	b:open("door_front", "front", 14)
	b:open("win_wide", "front", 6)
	b:open("win_wide", "front", 22)
	b:open("win_square", "right", 5)
	b:open("win_square", "right", 15)
	b:open("win_square", "back", 5)
	b:open("win_small", "back", 14)
	b:open("win_square", "back", 23)
	b:open("win_square", "left", 5)
	b:open("win_square", "left", 15)
	b:open("door_wood", "hall", 7)
	b:open("door_wood", "hall", 15)
	b:open("door_wood", "hall", 25)
	-- the living room
	b:item("rug_long", 9, 11, 90)
	b:item("sofa_three", 9, 8.2)
	b:item("table_coffee", 9, 11)
	b:item("tv_stand", 9, 14.6, 180)
	b:item("armchair", 4, 11.6, 90)
	b:item("lamp_floor", 3.6, 8)
	-- the kitchen
	b:item("counter_sink", 22, 14.4, 180)
	b:item("stove", 25, 14.4, 180)
	b:item("fridge", 28.2, 14.4, 180)
	b:item("kitchen_island", 24, 10)
	b:item("stool_bar", 22.4, 7.4)
	b:item("stool_bar", 25.6, 7.4)
	-- the bedrooms and the bathroom
	b:item("bed_double", 7, 22, 180)
	b:item("nightstand", 3.4, 24.6, 180)
	b:item("nightstand", 10.6, 24.6, 180)
	b:item("dresser", 4.6, 17.2)
	b:item("bathtub", 17.9, 22.6)
	b:item("toilet", 13.8, 24.5, 90)
	b:item("sink_vanity", 14, 18.4)
	b:item("bed_single", 27, 22, 180)
	b:item("desk", 22.6, 24.4, 180)
	b:item("chair_wood", 22.6, 21.6)
	for _, p in { { 9, 11 }, { 24, 11 }, { 7, 21 }, { 16, 21 }, { 25, 21 } } do
		b:item("light_ceiling", p[1], p[2])
	end
	-- the front yard
	b:item("path_stones", 16, 4)
	b:item("path_stones", 16, 1.6)
	b:item("flower_bed", 6, 3)
	b:item("flower_bed", 26, 3)
	b:item("bush", 10, 3)
	b:item("bush", 22, 3)
	b:item("mailbox", 30.8, 1.6)
end)

add(
	"townhouse",
	"Townhouse",
	"Two floors: a living room and kitchen downstairs, bedrooms upstairs.",
	"house",
	24,
	26,
	function(b)
		b:floor(2, 8, 22, 24, OAK)
		b:floor(2, 8, 22, 24, WALNUT, 1)
		b:box("", 2, 8, 22, 24, BRICK, CREAM)
		b:box("up", 2, 8, 22, 24, BRICK, CREAM, 1)
		b:wall("upinner", 12, 24, 12, 12, CREAM, CREAM, 1)
		b:roof(2, 8, 22, 24, "gable", 6, 0, SLATE, BRICK, 1)
		b:open("door_front", "front", 14)
		b:open("win_square", "front", 5)
		b:open("win_square", "front", 9.5)
		b:open("win_square", "left", 5)
		b:open("win_square", "left", 11)
		b:open("win_square", "back", 6)
		b:open("win_square", "back", 14)
		b:open("win_square", "upfront", 5)
		b:open("win_square", "upfront", 15)
		b:open("win_square", "upback", 5)
		b:open("win_square", "upback", 15)
		b:open("win_square", "upleft", 8)
		b:open("door_wood", "upinner", 9)
		-- the stairs up the right hand side
		b:item("stairs_straight", 19.6, 15.6, 0, 0, F)
		-- downstairs
		b:item("sofa_two", 7, 21.6, 180)
		b:item("table_coffee", 7, 18.6)
		b:item("rug_round", 7, 18.6)
		b:item("armchair", 3.8, 15.6, 90)
		b:item("counter", 4, 10, 0)
		b:item("stove", 7, 10, 0)
		b:item("fridge", 10.2, 10, 0)
		b:item("table_round", 12, 14)
		b:item("chair_dining", 12, 16.2, 180)
		b:item("chair_dining", 9.8, 14, 90)
		b:item("light_ceiling", 7, 18)
		b:item("light_ceiling", 9, 12)
		-- upstairs
		b:item("bed_double", 7, 19.6, 180, 1)
		b:item("nightstand", 3.4, 22.6, 180, 1)
		b:item("wardrobe", 7, 9.6, 0, 1)
		b:item("bed_single", 14.6, 19.6, 180, 1)
		b:item("desk", 14.8, 13.6, 0, 1)
		b:item("light_ceiling", 7, 16, 1)
		b:item("light_ceiling", 15, 17, 1)
		-- the front step
		b:item("planter_box", 6, 6.6)
		b:item("planter_box", 20.4, 6.6)
		b:item("path_stones", 16, 5.6)
		b:item("path_stones", 16, 3.4)
		b:item("lamp_post", 3, 5.4)
	end
)

add(
	"park",
	"Little park",
	"A fountain, benches, trees and flower beds round a paved square.",
	"tree",
	24,
	24,
	function(b)
		b:floor(6, 6, 18, 18, PAVING)
		b:item("fountain", 12, 12, 0, 0, F)
		b:item("bench_garden", 12, 7.4, 0, 0, F)
		b:item("bench_garden", 12, 16.6, 180, 0, F)
		b:item("bench_garden", 7.4, 12, 90, 0, F)
		b:item("bench_garden", 16.6, 12, 270, 0, F)
		for _, p in { { 3, 3 }, { 21, 3 }, { 3, 21 }, { 21, 21 } } do
			b:item(
				if p[2] < 12 then "tree_blossom" else "tree_oak",
				p[1] + (if p[1] < 12 then 1 else -1),
				p[2] + (if p[2] < 12 then 1 else -1)
			)
		end
		for _, p in { { 12, 2.6 }, { 12, 21.4 } } do
			b:item("flower_bed", p[1], p[2])
		end
		for _, p in { { 2.6, 12 }, { 21.4, 12 } } do
			b:item("flower_bed", p[1], p[2], 90)
		end
	end
)

-- One building for every workplace, each in a file of its own under Data/Buildings. The user:
-- "for buildings, make much more buildings, one for each workspace, and detail them all to be
-- unique, as much as the starting house". A file returns a function that is handed `add` and
-- lays its building out with the blueprint, like the ones above.
Presets.Workplaces = {
	"Market", -- the shopkeeper's
	"Cafe", -- the barista's
	"Bakery", -- the baker's
	"IceCream", -- the ice cream seller's
	"Florist",
	"Studio", -- the artist's
	"MusicHall", -- the musician's
	"Workshop", -- the builder's
	"Clinic", -- the doctor's
	"School", -- the teacher's
	"PostOffice", -- the postie's
	"Library", -- the librarian's
}
local buildings = script.Parent:FindFirstChild("Buildings")
if buildings then
	for _, name in Presets.Workplaces do
		local module = buildings:FindFirstChild(name)
		if module then
			(require(module) :: any)(add)
		end
	end
end

Presets.list = list
local byId: { [string]: Preset } = {}
for _, p in list do
	byId[p.id] = p
end

function Presets.get(id: string): Preset?
	return byId[id]
end

-- placing -------------------------------------------------------------------------------------------

-- The preset's footprint once turned (w, d along the plot's x and z).
function Presets.footprint(p: Preset, rot: number): (number, number)
	if rot % 180 == 90 then
		return p.d, p.w
	end
	return p.w, p.d
end

-- Turns a point of the preset by `rot` and moves it to the spot (ox, oz).
local function turn(p: Preset, rot: number, x: number, z: number, ox: number, oz: number): (number, number)
	local r = rot % 360
	if r == 90 then
		return ox + z, oz + p.w - x
	elseif r == 180 then
		return ox + p.w - x, oz + p.d - z
	elseif r == 270 then
		return ox + p.d - z, oz + x
	end
	return ox + x, oz + z
end

local function copy(t: any): any
	if type(t) ~= "table" then
		return t
	end
	local out = {}
	for k, v in t do
		out[k] = copy(v)
	end
	return out
end

-- Build requests for preset `id` with its corner at (ox, oz), turned by rot (0, 90, 180, 270).
-- Walls go first, then floors, roofs, free-standing items, and last the doors and windows,
-- which name their wall by its place in the batch.
function Presets.requests(id: string, ox: number, oz: number, rot: number): { any }
	local p = byId[id]
	if not p then
		return {}
	end
	local r = (math.floor(rot / 90 + 0.5) * 90) % 360
	local requests = {}
	local wallIndex: { [string]: number } = {}
	local order = { "walls", "floors", "roofs", "items" }
	for pass = 1, 5 do
		for _, o in p.objects do
			local kind = order[math.min(pass, 4)]
			local isOpening = o.wallName ~= nil
			local wanted = o.kind == kind and ((pass == 4 and not isOpening) or (pass == 5 and isOpening) or pass < 4)
			if wanted then
				local obj = copy(o.obj)
				if o.kind == "walls" then
					obj.x1, obj.z1 = turn(p, r, obj.x1, obj.z1, ox, oz)
					obj.x2, obj.z2 = turn(p, r, obj.x2, obj.z2, ox, oz)
				elseif o.kind == "floors" or o.kind == "roofs" then
					local ax, az = turn(p, r, obj.x1, obj.z1, ox, oz)
					local bx, bz = turn(p, r, obj.x2, obj.z2, ox, oz)
					obj.x1, obj.x2 = math.min(ax, bx), math.max(ax, bx)
					obj.z1, obj.z2 = math.min(az, bz), math.max(az, bz)
					if o.kind == "roofs" then
						obj.dir = (obj.dir - r / 90) % 4
					end
				elseif isOpening then
					obj.wall = "@" .. tostring(wallIndex[o.wallName :: string])
				else
					obj.x, obj.z = turn(p, r, obj.x, obj.z, ox, oz)
					obj.r = (obj.r + r) % 360
				end
				table.insert(requests, { type = "add", kind = o.kind, obj = obj })
				if o.kind == "walls" and o.name then
					wallIndex[o.name] = #requests
				end
			end
		end
	end
	return requests
end

-- Tries the requests on a copy of `plan`, the way the server will. Returns whether they all fit,
-- why not if they don't, what they cost, and the copy with them in (for drawing a ghost) along
-- with the keys they took.
function Presets.check(plan: any, requests: { any }): (boolean, string?, number, any, { { kind: string, key: string } })
	local trial = Plan.copy(plan)
	local keys: { [number]: string } = {}
	local made = {}
	local cost = 0
	for i, req in requests do
		local obj = Plan.clean(req.kind, copy(req.obj))
		if req.kind == "items" and type(req.obj.wall) == "string" and req.obj.wall:sub(1, 1) == "@" then
			obj.wall = keys[tonumber(req.obj.wall:sub(2)) or 0]
		end
		local ok, why = Plan.validate(trial, req.kind, obj)
		if not ok then
			return false, why, cost, trial, made
		end
		local key = Plan.newKey(trial)
		local applied, err = Plan.apply(trial, { { op = "add", kind = req.kind, key = key, obj = obj } })
		if not applied then
			return false, err, cost, trial, made
		end
		keys[i] = key
		cost += Plan.cost(req.kind, obj)
		table.insert(made, { kind = req.kind, key = key })
	end
	return true, nil, cost, trial, made
end

-- What a preset costs, worked out on an empty plan.
function Presets.price(id: string): number
	local p = byId[id]
	if not p then
		return 0
	end
	local plan = Plan.new(Tuning.Plot.Size)
	local x1, z1 = Plan.boundsOf(Tuning.Plot.Size)
	local _, _, cost = Presets.check(plan, Presets.requests(id, x1 + 10, z1 + 10, 0))
	return cost
end

return Presets
