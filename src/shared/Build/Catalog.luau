--!strict
-- Everything you can place in Build mode, gathered from the modules in Build/Recipes.
-- Each entry:
--   id, name, cat (a tab below), price, place, size (W x H x D footprint box),
--   c1, c2 (default paint, hex), build(r) (draws it with Build/Recipe),
--   optional: tags (what villagers ask for), surface (height of a top you can set things on),
--   opening = { w, h, sill } for doors and windows,
--   job, workSpot, workYaw for workplaces (Recipes/Work).
-- place is one of:
--   "floor"   stands on a floor or the ground
--   "surface" small things that can also stand on a table or counter
--   "ground"  outdoors on the ground floor only (trees, paths)
--   "wall"    hangs on a wall (pictures, shelves, wall lights)
--   "opening" a door or window that cuts the wall
--   "ceiling" hangs from the ceiling
--   "stairs"  climbs one storey and cuts the floor above

local Recipe = require(script.Parent.Recipe)
local Colors = require(script.Parent.Parent.Util.Colors)

export type Def = {
	id: string,
	name: string,
	cat: string,
	price: number,
	place: string,
	size: Vector3,
	c1: string,
	c2: string?,
	tags: { string }?,
	surface: number?,
	opening: { w: number, h: number, sill: number }?,
	job: string?, -- a workplace: the job (Data/Jobs) it opens
	workSpot: Vector3?,
	workYaw: number?,
	build: (r: Recipe.Recipe) -> (),
	order: number?,
}

local Catalog = {}

Catalog.Categories = {
	{ id = "structure", name = "Structure" },
	{ id = "doors", name = "Doors" },
	{ id = "windows", name = "Windows" },
	{ id = "seating", name = "Seating" },
	{ id = "tables", name = "Tables" },
	{ id = "beds", name = "Beds" },
	{ id = "storage", name = "Storage" },
	{ id = "kitchen", name = "Kitchen" },
	{ id = "bath", name = "Bathroom" },
	{ id = "lights", name = "Lights" },
	{ id = "fun", name = "Fun" },
	{ id = "decor", name = "Decor" },
	{ id = "walldecor", name = "On walls" },
	{ id = "garden", name = "Garden" },
	{ id = "work", name = "Work" },
}

Catalog.Places = {
	floor = true,
	surface = true,
	ground = true,
	wall = true,
	opening = true,
	ceiling = true,
	stairs = true,
}

-- Tags villagers can ask for in a room request, with how they say it.
Catalog.Tags = {
	light = "a lamp",
	seat = "somewhere to sit",
	table = "a table",
	plant = "a plant",
	art = "a picture on the wall",
	music = "something that plays music",
	tv = "a TV",
	books = "some books",
	rug = "a rug",
	storage = "a place for their things",
	toy = "something to play with",
	clock = "a clock",
	mirror = "a mirror",
	games = "a game to play",
	desk = "a desk",
}

-- Tags that aren't asked for in requests but mean something.
Catalog.OtherTags = { bed = true, stairs = true, kitchen = true, bath = true, work = true }

local byId: { [string]: Def } = {}
local byCat: { [string]: { Def } } = {}
local all: { Def } = {}

local function load()
	local folder = script.Parent.Recipes
	local modules = folder:GetChildren()
	table.sort(modules, function(a, b)
		return a.Name < b.Name
	end)
	local order = 0
	for _, m in modules do
		if m:IsA("ModuleScript") then
			local list = require(m) :: any
			for _, def in list do
				if byId[def.id] then
					error("catalog id used twice: " .. def.id)
				end
				order += 1
				def.order = order
				byId[def.id] = def
				byCat[def.cat] = byCat[def.cat] or {}
				table.insert(byCat[def.cat], def)
				table.insert(all, def)
			end
		end
	end
end
load()

function Catalog.get(id: string): Def?
	return byId[id]
end

function Catalog.list(cat: string): { Def }
	return byCat[cat] or {}
end

function Catalog.all(): { Def }
	return all
end

-- Items that carry a tag (for room requests).
function Catalog.withTag(tag: string): { Def }
	local out = {}
	for _, def in all do
		if def.tags and table.find(def.tags, tag) then
			table.insert(out, def)
		end
	end
	return out
end

-- Every workplace in the catalog.
function Catalog.workplaces(): { Def }
	local out = {}
	for _, def in all do
		if def.job then
			table.insert(out, def)
		end
	end
	return out
end

function Catalog.hasTag(def: Def, tag: string): boolean
	return def.tags ~= nil and table.find(def.tags, tag) ~= nil
end

-- Draws an item in its own space with the given paint (hex; nil for the defaults).
function Catalog.prims(def: Def, c1: string?, c2: string?): { Recipe.Prim }
	local col1 = Colors.fromHex(c1 or def.c1)
	local col2 = Colors.fromHex(c2 or def.c2 or def.c1)
	local r = Recipe.new(col1, col2)
	def.build(r)
	return r.prims
end

return Catalog
