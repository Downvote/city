--!strict
-- Everything you can place in Build mode, gathered from the modules in Build/Recipes.
-- Each entry:
--   id, name, cat (a tab below), price, place, size (W x H x D footprint box),
--   (price is what it costs: the recipe's own price times Tuning.Prices.Items, set at load)
--   c1, c2 (default paint, hex), build(r) (draws it with Build/Recipe),
--   optional: tags (what villagers ask for), surface (height of a top you can set things on),
--   opening = { w, h, sill } for doors and windows,
--   job, workSpot, workYaw for workplaces (Recipes/Work),
--   lively = true for a piece that moves or gives off an effect (Build/Lively: the client looks
--   inside those), vip = true for one only VIP owners can place (Services/Build refuses it to
--   anyone else, Sim/Passes; Build mode tags its card), level = n for one only a town of level n
--   or more can place (Recipes/Grand; Services/Build refuses it below, Sim/City.unlocked).
-- place is one of:
--   "floor"   stands on a floor or the ground
--   "surface" small things that can also stand on a table or counter
--   "ground"  outdoors on the ground floor only (trees, paths)
--   "wall"    hangs on a wall (pictures, shelves, wall lights)
--   "opening" a door or window that cuts the wall
--   "ceiling" hangs from the ceiling
--   "stairs"  climbs one storey and cuts the floor above
--   "mark"    flat paint lying on a floor, a path or the ground, on any level (Recipes/Markings):
--             it never stops anything standing over it, and another mark can go over it
-- Two more optional fields:
--   stack = true      stands on top of other pieces as well as on floors (the basic shapes)
--   picture = true    shows a picture the player picks from the Roblox library (Recipes/Pictures):
--                     the part it shows on carries attrs.Picture (the face, a NormalId name), the
--                     placeholder drawn until there is one is named "Placeholder", and the
--                     placed item keeps the picture's id as `img` (Plan)
-- (Water: a piece of place "water" goes only on a pool or a pond, Recipes/Water. Its `water` says
-- how it sits, "float", "bottom" or "edge", and `draft` how far its frame's floor is under that:
-- Build/Water has the rules.)

local Recipe = require(script.Parent.Recipe)
local Colors = require(script.Parent.Parent.Util.Colors)
local Tuning = require(script.Parent.Parent.Config.Tuning)

export type Def = {
	id: string,
	name: string,
	cat: string,
	price: number,
	listed: number?, -- the recipe's own price, before Tuning.Prices.Items
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
	style: string?, -- the look it belongs to (Catalog.Styles): Build mode can list a whole style together
	stack: boolean?, -- stands on other pieces too (see above)
	picture: boolean?, -- takes a picture from the library (see above)
	water: string?, -- (water) how a piece of place "water" sits: "float", "bottom" or "edge"
	draft: number?, -- (water) how far its frame's floor is under the surface, or under the ground
	lively: boolean?, -- moves or gives off an effect (Build/Lively, client World/Lively)
	vip: boolean?, -- only for VIP owners (Sim/Passes.has(profile, "vip"))
	level: number?, -- only for a town of this level or more (Sim/City.unlocked; Recipes/Grand)
}

local Catalog = {}

Catalog.Categories = {
	{ id = "structure", name = "Structure" },
	-- columns and posts a storey tall (and shorter), in the Build group (the user: "add pillars to
	-- building as well")
	{ id = "pillars", name = "Pillars" },
	-- cubes, cylinders, balls, wedges and the rest, in a few sizes, to build anything from (the
	-- user: "there should also be basic shapes, like cube, cylinder, etc")
	{ id = "shapes", name = "Shapes" },
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
	-- posters, frames, signs and decals showing a picture the player picks from the Roblox library
	-- (the user: "allow the player to use custom decal in the roblox library")
	{ id = "pictures", name = "Pictures" },
	{ id = "garden", name = "Garden" },
	-- small pieces that give off an effect: sparkles, smoke, bubbles, confetti, falling leaves,
	-- snow, a fire pit's flames (the user: "particle makers"; Recipes/Effects, Data/Effects)
	{ id = "effects", name = "Effects" },
	-- what goes on a pool or a pond: boats, floats, lily pads, a jetty (the user: "also, add
	-- ability to add water, along with things that can go in the water"; Recipes/Water)
	{ id = "water", name = "Water" },
	-- flat paint on floors, paths and the ground: lines, arrows, crossings, court lines, chalk (the
	-- user: "add another section where players can put down markings, like in bloxburg")
	{ id = "markings", name = "Markings" },
	{ id = "work", name = "Work" },
	-- things villagers made you in events: free, and only as many as you were given (Sim/Keepsakes)
	{ id = "keepsakes", name = "Keepsakes" },
}

-- The looks a piece can belong to, besides what it is (a chair is Seating and maybe Cozy). The
-- user: "there should be many to choose from from different categories, like garden, sci fi,
-- cozy, etc, just like bloxburg". A piece names one with `style`; Build mode lists each style
-- across every category.
Catalog.Styles = {
	{ id = "cozy", name = "Cozy" },
	{ id = "modern", name = "Modern" },
	{ id = "scifi", name = "Sci-fi" },
	{ id = "garden", name = "Garden" },
	{ id = "seaside", name = "Seaside" },
	{ id = "rustic", name = "Rustic" },
	{ id = "fancy", name = "Fancy" },
	{ id = "playful", name = "Playful" },
}

Catalog.Places = {
	floor = true,
	surface = true,
	ground = true,
	wall = true,
	opening = true,
	ceiling = true,
	stairs = true,
	mark = true,
	water = true, -- on a pool or a pond (Build/Water)
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
-- (`path`: a piece to walk on outdoors, listed on Build mode's Paths tab: Catalog.isPath)
Catalog.OtherTags =
	{ bed = true, stairs = true, kitchen = true, bath = true, work = true, keepsake = true, path = true }

local byId: { [string]: Def } = {}
local byCat: { [string]: { Def } } = {}
local all: { Def } = {}

-- What a piece sells for, from its recipe's price. The user: "make buildings cheaper", so it is
-- that price times Tuning.Prices.Items, to a whole coin, and to 5 coins from 50 up so the
-- catalog's prices stay round.
function Catalog.priceOf(listed: number): number
	if listed <= 0 then
		return 0 -- a gift stays free (a keepsake)
	end
	local p = listed * Tuning.Prices.Items
	local step = if p >= 50 then 5 else 1
	return math.max(1, math.floor(p / step + 0.5) * step)
end

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
				-- (the recipe's own price is kept, so loading twice never halves it twice)
				def.listed = def.listed or def.price
				def.price = Catalog.priceOf(def.listed :: number)
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

-- Where a category comes in Catalog.Categories (one not listed goes last).
local catOrder: { [string]: number } = {}
for i, cat in Catalog.Categories do
	catOrder[cat.id] = i
end
function Catalog.categoryOrder(cat: string): number
	return catOrder[cat] or #Catalog.Categories + 1
end

-- Every piece of one style (Catalog.Styles), across every category: by category in the order
-- Build mode shows them, then in catalog order. Keepsakes are left out (they are gifts).
function Catalog.withStyle(style: string): { Def }
	local out = {}
	for _, def in all do
		if def.style == style and def.cat ~= "keepsakes" then
			table.insert(out, def)
		end
	end
	table.sort(out, function(a, b)
		local ca, cb = Catalog.categoryOrder(a.cat), Catalog.categoryOrder(b.cat)
		if ca ~= cb then
			return ca < cb
		end
		return (a.order or 0) < (b.order or 0)
	end)
	return out
end

-- A piece to walk on outdoors (stepping stones, a boardwalk, paving): tagged `path`, or a low
-- flat piece that goes on the ground, or one named as a path. Build mode's Paths tab lists them.
local PATH_WORDS = { "path", "boardwalk", "stepping", "paving", "walkway", "flagstone", "gravel" }
function Catalog.isPath(def: Def): boolean
	if Catalog.hasTag(def, "path") then
		return true
	end
	if def.cat == "keepsakes" or def.place == "mark" then
		return false
	end
	if def.place == "ground" and def.size.Y <= 0.6 then
		return true
	end
	for _, word in PATH_WORDS do
		if string.find(def.id, word, 1, true) then
			return true
		end
	end
	return false
end

function Catalog.paths(): { Def }
	local out = {}
	for _, def in all do
		if Catalog.isPath(def) then
			table.insert(out, def)
		end
	end
	return out
end

-- Can a piece of `def` stand on top of a placed piece of `below`? Small things go on any top
-- (a table, a counter, a shape), the basic shapes stack on each other and on tops, and a mark
-- lies on a path or a low platform (a deck). A mark never holds anything up: what is put over
-- one stands on whatever the mark lies on (a mark over a mark is laid over it by Plan.markY).
function Catalog.standsOn(def: Def, below: Def): boolean
	if below.place == "mark" then
		return false
	end
	if def.place == "mark" then
		if Catalog.isPath(below) then
			return true
		end
		return below.surface ~= nil
			and below.surface <= 1.2
			and (below.place == "floor" or below.place == "ground" or below.place == "surface")
	end
	return def.place == "surface" or def.stack == true
end

-- Draws an item in its own space with the given paint (hex; nil for the defaults). A piece that
-- takes a picture is drawn with `img` (a library id, Plan) showing on it, or with its
-- placeholder when there is none. A mark is never solid: people and pieces go over it.
-- `m1` and `m2` are what the paint tool painted the slots in (a piece never painted keeps its
-- recipe's own materials).
function Catalog.prims(def: Def, c1: string?, c2: string?, img: number?, m1: string?, m2: string?): { Recipe.Prim }
	local col1 = Colors.fromHex(c1 or def.c1)
	local col2 = Colors.fromHex(c2 or def.c2 or def.c1)
	local r = Recipe.new(col1, col2)
	local ra: any = r
	ra.m1, ra.m2 = m1, m2
	def.build(r)
	local prims = r.prims
	if def.picture then
		local shown = {}
		for _, p in prims do
			if img and p.name == "Placeholder" then
				continue
			end
			if img and p.attrs and p.attrs.Picture then
				local attrs = table.clone(p.attrs)
				attrs.PictureId = img
				p.attrs = attrs
			end
			table.insert(shown, p)
		end
		prims = shown
	end
	if def.place == "mark" then
		for _, p in prims do
			p.collide = false
		end
	end
	return prims
end

return Catalog
