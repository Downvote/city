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
--   anyone else, Sim/Passes; Build mode tags its card), gives = a source in Data/Items.Sources for
--   a piece that gives the player something when they hold E on it (a bookshelf a book, a stove a
--   dish; a workplace's are made while they work there: Services/Bag).
--   level = n for one only a town of level n or more can place (Recipes/Grand; Services/Build
--   refuses it below, Sim/City.unlocked).
--   gems = n for one bought with gems instead of coins (price 0; the fog machine): Services/Build
--   takes them the first time one goes down, and it stays the player's (Sim/GemPieces).
-- place is one of:
--   "floor"   stands on a floor or the ground
--   "surface" small things that can also stand on a table or counter
--   "ground"  outdoors on the ground floor only (trees, paths)
--   "wall"    hangs on a wall (pictures, shelves, wall lights)
--   "opening" a door or window that cuts the wall
--   "ceiling" hangs from the ceiling
--   "stairs"  climbs one storey and cuts the floor above (and the ways between floors, Recipes/Travel:
--             `travel` says which, `hole` what it cuts if less than all of it, `spans` how many
--             floors a lift runs up)
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
	gives: string?, -- holding E on it gives the player a thing: a source in Data/Items.Sources (Services/Bag)
	prize: boolean?, -- a keepsake a town goal gives, not a villager (Build/Recipes/Prizes, Data/Goals' `piece`)
	level: number?, -- only for a town of this level or more (Sim/City.unlocked; Recipes/Grand)
	-- (a way between floors, place "stairs": Build/Recipes/Travel)
	travel: string?, -- "stairs", "ladder", "pole", "slide" or "lift" (Sim/Lifts)
	hole: { number }?, -- the hole it cuts in the floor above, x1, z1, x2, z2 in its own space (all of it if nil)
	spans: number?, -- how many floors up it runs (1 if nil): a lift's floors less one
	gems: number?, -- bought with gems, not coins (its `price` is 0): one bought stays the player's (Sim/GemPieces)
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
-- (a table, a counter, a shape) and the basic shapes stack on each other and on tops. Then the
-- user: "make it such that you are able to put objects on top of each other or on each other,
-- respecting their collision". So anything else that stands on a floor or the ground stands on
-- another standing piece too: a lamp on a cupboard, a crate on a crate, a chair on a deck or a
-- raft. Build/Collide keeps it out of the body of what it stands on, and Build mode stands it
-- only on a part that is solid (Build/Solid). What hangs, sits in a wall or a ceiling, lies flat as
-- a rug, or is a small thing on a surface holds nothing bigger than itself up. A mark lies on a
-- path or a low platform (a deck). A mark never holds anything up: what is put over one stands on
-- whatever the mark lies on (a mark over a mark is laid over it by Plan.markY).
local HOLDS = { floor = true, ground = true, stairs = true, water = true }
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
	if def.place == "surface" or def.stack == true then
		return true
	end
	if def.place ~= "floor" and def.place ~= "ground" then
		return false
	end
	if not HOLDS[below.place] or Catalog.hasTag(below, "rug") then
		return false
	end
	-- (a rug or a mat lying flat is stood on through, as Build/Solid walks through it)
	local flat = below.place == "floor" and below.size.Y <= Tuning.Unstick.Flat
	return not flat or below.stack == true or Catalog.isPath(below)
end

-- Searching the catalog --------------------------------------------------------------------------
--
-- The user: "add searching in build mode". Build mode's box looks through every piece as the
-- player types: a piece is found when each word typed is in its name, its kind (Seating, Garden),
-- its look (Cozy, Sci-fi), its tags or what a villager calls them ("somewhere to sit"), or "path"
-- for a path. A word ending in s is also tried without it (chairs, lamps). Keepsakes are left out
-- (they are gifts, on their own tab).

local catNames: { [string]: string } = {}
for _, cat in Catalog.Categories do
	catNames[cat.id] = cat.name
end
local styleNames: { [string]: string } = {}
for _, look in Catalog.Styles do
	styleNames[look.id] = look.name
end

local searchText: { [string]: string } = {}
-- Everything a search looks through for one piece, in lower case.
function Catalog.searchWords(def: Def): string
	local known = searchText[def.id]
	if known then
		return known
	end
	local parts = { def.name, catNames[def.cat] or def.cat }
	if def.style then
		table.insert(parts, styleNames[def.style] or def.style)
	end
	local tags: { string } = def.tags or {}
	for _, tag in tags do
		table.insert(parts, tag)
		local said = (Catalog.Tags :: { [string]: string })[tag]
		if said then
			table.insert(parts, said)
		end
	end
	if Catalog.isPath(def) then
		table.insert(parts, "path")
	end
	local text = string.lower(table.concat(parts, " "))
	searchText[def.id] = text
	return text
end

Catalog.SearchMax = 60 -- characters of a search looked at

-- The words of a search, in lower case (at most six).
function Catalog.searchTerms(query: string?): { string }
	local out = {}
	local q = string.lower(string.sub(if type(query) == "string" then query else "", 1, Catalog.SearchMax))
	for word in string.gmatch(q, "[^%s,]+") do
		if #out < 6 then
			table.insert(out, word)
		end
	end
	return out
end

local function hasWord(text: string, word: string): boolean
	if string.find(text, word, 1, true) then
		return true
	end
	-- (chairs, lamps, benches: the word without its s)
	if #word > 3 and string.sub(word, -1) == "s" then
		local stem = string.sub(word, 1, -2)
		if string.find(text, stem, 1, true) then
			return true
		end
		if string.sub(stem, -1) == "e" and string.find(text, string.sub(stem, 1, -2), 1, true) then
			return true
		end
	end
	return false
end

-- The pieces a search finds: first those whose name starts with what was typed, then those whose
-- name has it, then the rest, each in the order Build mode lists them. Nothing for an empty search.
function Catalog.search(query: string?): { Def }
	local terms = Catalog.searchTerms(query)
	if #terms == 0 then
		return {}
	end
	local whole = table.concat(terms, " ")
	local found: { { def: Def, rank: number } } = {}
	for _, def in all do
		if def.cat ~= "keepsakes" then
			local text = Catalog.searchWords(def)
			local every = true
			for _, word in terms do
				if not hasWord(text, word) then
					every = false
					break
				end
			end
			if every then
				local name = string.lower(def.name)
				local at = string.find(name, whole, 1, true)
				local rank = if at == 1 then 1 elseif at then 2 else 3
				table.insert(found, { def = def, rank = rank })
			end
		end
	end
	table.sort(found, function(a, b)
		if a.rank ~= b.rank then
			return a.rank < b.rank
		end
		local ca, cb = Catalog.categoryOrder(a.def.cat), Catalog.categoryOrder(b.def.cat)
		if ca ~= cb then
			return ca < cb
		end
		return (a.def.order or 0) < (b.def.order or 0)
	end)
	local out = table.create(#found)
	for _, f in found do
		table.insert(out, f.def)
	end
	return out
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
