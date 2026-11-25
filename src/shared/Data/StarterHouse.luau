--!strict
-- What every new plot starts with: a cottage and its little workshop, side by side in the middle
-- of the land, with a bedroom for the first villager and a workshop to work in. The street runs
-- along the plot's front edge (z = 0).
--
-- The user: "players should spawn at their plot, which starts out with a single house in the
-- middle", then "redo our map, and our starting house as well", then "improve the starting house
-- detail by alot, and add a workspace next to it". So: one small house somebody loved (a tall
-- gabled front with a bay window, a lower wing whose roof comes down over a porch, a chimney
-- with a fire, shutters, flowers and trim at every window, a front garden behind a picket
-- fence), and beside it an open fronted workshop with the builder's bench. The rest of the land
-- stays empty for the player.
--
-- Every piece of it is an ordinary plan object (walls, floors, roofs, catalog items), so the
-- player can move, repaint or sell any of it in Build mode.
--
-- A new plot gets it less two pieces: the bed and the builder's bench (StarterHouse.newPlot). The
-- user: "make the tutorial more visual and structured, starting with creating a villager, then
-- building a place for them to sleep, then a place to work". So the bedroom and the workshop
-- stand ready and the tutorial (Sim/Tutorial, UI/Tutorial) has the player put the two down
-- themselves; a new player's coins cover both. StarterHouse.plan() is the whole of it, bed and
-- bench too, for the specs and previews that want a town that already works.

local Plan = require(script.Parent.Parent.Build.Plan)
local Catalog = require(script.Parent.Parent.Build.Catalog)
local Spread = require(script.Parent.Parent.Build.Spread)
local Tuning = require(script.Parent.Parent.Config.Tuning)

local StarterHouse = {}

-- What a new plot leaves out, for the tutorial's second and third steps to put down.
StarterHouse.Held = { "bed_single", "work_builder" }

type Finish = { c: string, m: string }

local F = Tuning.Plot.Foundation

-- Everything is laid out in one frame: x across from the house's left corner, z back from the
-- workshop's front, on the 2 stud wall grid. The rooms are drawn tight first, the walls inside a
-- box 40 by 28, with the house at (0, HOUSE_Z) in it and the workshop at (SHOP_X, 0), and the
-- fence FRONT studs in front of the box. Then floor is let in along the lines in CUTS (Build/
-- Spread; the user: "make the houses and other buildings bigger such that the interior feels
-- much more spacious"), which leaves the box W wide: every room half as wide and deep again,
-- the furniture against the walls it was against. OX puts the box's middle on the middle of the
-- plot's width, OZ keeps it near the street, a lawn in front of the garden fence.
local CUTS: Spread.Cuts = {
	-- through the bedroom and the kitchen, the front room and the porch, the workshop
	x = { { 9.5, 6 }, { 13.6, 8 }, { 35.6, 6 } },
	-- across the front of the bedroom and the workshop, and the front of the kitchen and the
	-- front room
	z = { { 4.5, 4 }, { 14.4, 6 } },
}
local TIGHT_W = 40 -- the box's width before it is opened up
local W = Spread.size(CUTS, TIGHT_W, 28)
local OX = Tuning.Plot.Size / 2 - W / 2
local OZ = 36
local HOUSE_Z = 4
local SHOP_X = 28
local FRONT = 6

-- Finishes. A wall, floor or roof in a plan is painted with a colour and one of Palette's
-- materials, nothing else (Plan.validate turns away anything more), so these are Roblox's own
-- materials and take whatever texture the town gives them.
-- The colours follow the town's palette (the user: "make the colors of the buildings, such as the
-- roof of the buildings, more pleasing to look at"): light walls, a roof a few steps darker and
-- only gently coloured, white trim, and the strong colour kept for the door and the shutters.
local CREAM: Finish = { c = "F3E7CF", m = "Plaster" } -- the house outside
local BOARDS: Finish = { c = "B9CFB2", m = "WoodPlanks" } -- the gable ends and the workshop: sage
local TILE: Finish = { c = "C27E63", m = "ClayRoofTiles" } -- a soft clay
local FRONT_ROOM: Finish = { c = "F7F3EA", m = "Plaster" }
local BEDROOM: Finish = { c = "E3ECEF", m = "Plaster" }
local KITCHEN: Finish = { c = "F6ECCF", m = "Plaster" }
local SHOP_IN: Finish = { c = "DDBE94", m = "WoodPlanks" }
local OAK: Finish = { c = "C49A6C", m = "WoodPlanks" }
local WALNUT: Finish = { c = "9A6B48", m = "WoodPlanks" }
local KITCHEN_TILES: Finish = { c = "EADBC0", m = "CeramicTiles" }
local DECK: Finish = { c = "B48C64", m = "WoodPlanks" }
local PAVING: Finish = { c = "E2D6BE", m = "Pavement" }
local FLAGS: Finish = { c = "C2BDB2", m = "Cobblestone" }
local DRIVE: Finish = { c = "BDB8AE", m = "Pavement" } -- the driveway: pale grey paving
-- paint for the pieces that take it
local GREEN = "3F8C86" -- the door and the shutters: teal
local GREEN_DARK = "2E6B67"
local WHITE = "FAF6EC"
local ROSE = "D9707F"

function StarterHouse.plan(): Plan.PlanData
	local plan = Plan.new()
	local walls: { [string]: string } = {} -- a wall's name here to its key in the plan
	local ox, oz = OX, OZ -- where the part being laid out stands on the plot

	local function add(kind: string, obj: any): string
		local key = Plan.newKey(plan)
		local list = (plan :: any)[kind]
		-- all of it is given: selling a piece of it refunds nothing (Plan: Gifts)
		obj.gift = Plan.cost(kind, obj)
		list[key] = obj
		return key
	end

	local function floor(x1: number, z1: number, x2: number, z2: number, finish: Finish)
		add("floors", { x1 = x1 + ox, z1 = z1 + oz, x2 = x2 + ox, z2 = z2 + oz, lv = 0, c = finish.c, m = finish.m })
	end

	-- A wall from one point to the next. Going round a building clockwise seen from above (front,
	-- right, back, left) puts side "a" outside.
	local function wall(name: string, x1: number, z1: number, x2: number, z2: number, a: Finish, b: Finish)
		walls[name] = add("walls", {
			x1 = x1 + ox,
			z1 = z1 + oz,
			x2 = x2 + ox,
			z2 = z2 + oz,
			lv = 0,
			style = "wall",
			a = { c = a.c, m = a.m },
			b = { c = b.c, m = b.m },
		})
	end

	local function roof(x1: number, z1: number, x2: number, z2: number, rise: number, dir: number)
		add("roofs", {
			x1 = x1 + ox,
			z1 = z1 + oz,
			x2 = x2 + ox,
			z2 = z2 + oz,
			lv = 0,
			style = "gable",
			rise = rise,
			dir = dir,
			over = 1.2,
			c = TILE.c,
			m = TILE.m,
			c2 = BOARDS.c,
			m2 = BOARDS.m,
		})
	end

	-- A door or window `t` studs along a wall, from the wall's first point.
	local function opening(id: string, name: string, t: number, c1: string?, c2: string?)
		local def = Catalog.get(id)
		local key = walls[name]
		if not def or not def.opening or not key then
			return -- the starter plan only uses what the catalog has
		end
		add("items", {
			id = id,
			x = 0,
			y = Plan.openingY(plan.walls[key], def.opening.sill),
			z = 0,
			r = 0,
			lv = 0,
			wall = key,
			t = t,
			side = "a",
			c1 = c1,
			c2 = c2,
		})
	end

	-- Something hung on a wall: its bottom edge `y` above the ground, on side "a" (outside) or "b".
	local function hang(id: string, name: string, t: number, y: number, side: string, c1: string?, c2: string?)
		local key = walls[name]
		if not Catalog.get(id) or not key then
			return
		end
		add("items", { id = id, x = 0, y = y, z = 0, r = 0, lv = 0, wall = key, t = t, side = side, c1 = c1, c2 = c2 })
	end

	-- A free-standing piece: on the floor, or on the grass for a garden piece, unless `y` says
	-- otherwise (on a table, or a garden piece on the porch boards).
	local function item(id: string, x: number, z: number, r: number, y: number?, c1: string?, c2: string?)
		local def = Catalog.get(id)
		if not def then
			return
		end
		local height = y
		if height == nil then
			if def.place == "ceiling" then
				height = Plan.levelTop(0) - 1
			elseif def.place == "ground" then
				height = 0
			else
				height = F
			end
		end
		add("items", { id = id, x = x + ox, y = height, z = z + oz, r = r, lv = 0, c1 = c1, c2 = c2 })
	end

	-- A piece that stands on the level above the house's one storey: what goes on the roof or in
	-- a gable.
	local function upstairs(id: string, x: number, z: number, r: number, c1: string?, c2: string?)
		if Catalog.get(id) then
			add("items", { id = id, x = x + ox, y = Plan.levelBase(1), z = z + oz, r = r, lv = 1, c1 = c1, c2 = c2 })
		end
	end

	-- The top of a piece of furniture standing on the floor, for what stands on it.
	local function top(id: string): number
		local def = Catalog.get(id)
		return F + (if def and def.surface then def.surface else 0)
	end

	-- Trim for an ordinary window (four studs wide, its sill three studs up) from outside: a hood
	-- over it, a box of flowers under it and, on the house, shutters.
	local function dress(name: string, t: number, shutters: boolean)
		local sill = F + 3
		if shutters then
			hang("shutters", name, t, sill - 0.15, "a", GREEN, GREEN_DARK)
		end
		hang("window_hood", name, t, sill + 4.38, "a", WHITE, TILE.c)
		hang("window_box", name, t, sill - 1.35, "a", WHITE, ROSE)
	end

	-- the house ------------------------------------------------------------------------------------
	-- Its own frame: the gabled part is x 0 to 12 and z 0 to 24, the wing x 12 to 24 and z 8 to
	-- 22, the porch in front of the wing.
	ox, oz = OX, OZ + HOUSE_Z

	floor(12, 8, 24, 22, OAK) -- the front room
	floor(0, 0, 12, 10, WALNUT) -- the bedroom
	floor(0, 10, 12, 24, KITCHEN_TILES)
	floor(12, 2, 24, 8, DECK) -- the porch

	-- the outside walls, clockwise from the gable's front
	wall("gable", 0, 0, 12, 0, CREAM, BEDROOM)
	wall("side", 12, 0, 12, 8, CREAM, BEDROOM)
	wall("porch", 12, 8, 24, 8, CREAM, FRONT_ROOM)
	wall("end", 24, 8, 24, 22, CREAM, FRONT_ROOM)
	wall("wingback", 24, 22, 12, 22, CREAM, FRONT_ROOM)
	wall("step", 12, 22, 12, 24, CREAM, KITCHEN)
	wall("back", 12, 24, 0, 24, CREAM, KITCHEN)
	wall("leftback", 0, 24, 0, 10, CREAM, KITCHEN)
	wall("leftfront", 0, 10, 0, 0, CREAM, BEDROOM)
	-- the inside ones: the bedroom's back wall, and the wall between the front room and the kitchen
	wall("nook", 12, 8, 12, 10, FRONT_ROOM, BEDROOM)
	wall("bedroom", 0, 10, 12, 10, BEDROOM, KITCHEN)
	wall("middle", 12, 10, 12, 22, FRONT_ROOM, KITCHEN)

	-- Two roofs. The gabled part's is steep and runs front to back. The wing's is lower, runs
	-- across, comes down over the porch and dies into the other one's slope.
	roof(0, 0, 12, 24, 10, 1)
	roof(8, 2, 24, 22, 9, 0)

	-- doors and windows
	opening("door_front", "porch", 6, GREEN, WHITE)
	opening("win_tall", "porch", 1.8)
	opening("win_tall", "porch", 10.2)
	opening("win_square", "leftfront", 5)
	opening("win_square", "leftback", 10)
	opening("win_small", "back", 4.6)
	opening("win_square", "wingback", 4.5)
	opening("win_square", "end", 9.5)
	opening("door_wood", "bedroom", 9.6)
	opening("arch_wide", "middle", 5)

	-- the outside: every ordinary window dressed, baskets by the bay, a lantern and bunting on
	-- the porch, a stone course round the foot of the walls, boards up the corners, two drainpipes
	dress("leftfront", 5, true)
	dress("leftback", 10, true)
	dress("wingback", 4.5, true)
	dress("end", 9.5, true)
	hang("hanging_basket", "back", 1.6, 5, "a")
	hang("trellis", "back", 9.4, 1.3, "a")
	hang("trellis", "end", 2.6, 1.3, "a")
	hang("lantern_wall", "porch", 8.6, 5.6, "a")
	hang("bunting", "porch", 6, 8.8, "a")
	for _, t in { 2, 6, 10 } do
		hang("stone_footing", "gable", t, 0, "a")
		hang("stone_footing", "back", t, 0, "a")
		hang("stone_footing", "wingback", t, 0, "a")
		hang("stone_footing", "end", t, 0, "a")
		hang("stone_footing", "leftback", t, 0, "a")
	end
	for _, t in { 0, 4, 8 } do
		hang("stone_footing", "leftfront", t, 0, "a")
	end
	item("corner_board", 0, 0, 180, 0)
	item("corner_board", 12, 0, 90, 0)
	item("corner_board", 24, 8, 90, 0)
	item("corner_board", 24, 22, 0, 0)
	item("corner_board", 12, 24, 0, 0)
	item("corner_board", 0, 24, 270, 0)
	hang("downpipe", "end", 12.7, 0, "a")
	hang("downpipe", "leftback", 1, 0, "a")
	item("water_butt", 25.5, 20.7, 90) -- (a hair off the downpipe's side)

	-- the porch: four posts under the eave (the one against the gabled part is turned, so its
	-- beam keeps out of the bedroom wall), rails between them, steps up from the path, and what a
	-- porch collects
	item("porch_post", 12.9, 2.5, 90)
	for _, x in { 15.6, 20.4, 23.5 } do
		item("porch_post", x, 2.5, 0)
	end
	item("porch_rail", 14.2, 2.5, 0)
	item("porch_rail", 21.95, 2.5, 0)
	item("porch_rail", 23.5, 5.2, 90)
	item("doorstep", 18, 0.8, 180, 0)
	item("flower_pot", 15.4, 0.7, 0, 1)
	item("flower_pot", 20.6, 0.7, 0, 1)
	item("doormat", 18, 6.8, 0)
	item("flower_pot", 15.45, 7.2, 0)
	item("flower_pot", 20.55, 7.2, 0)
	item("chair_rocking", 21.4, 5.6, 195)
	item("woodpile", 13.05, 5.3, 90, F)

	-- the front room: the fire on the end wall under the wing's ridge, a sofa under the window
	item("chimney_hearth", 22.1, 12, 270)
	item("sofa_two", 22.05, 17.2, 270)
	item("rug_long", 17.8, 17, 0)
	item("table_coffee", 16.4, 17.2, 90)
	item("books_stack", 16.4, 16.5, 20, top("table_coffee"))
	item("lamp_floor", 22.7, 20.75, 0)
	item("bookshelf", 14.7, 20.9, 180)
	item("coat_stand", 13.3, 9.4, 0)
	item("light_ceiling", 18, 15, 0)
	hang("curtains", "end", 9.5, 2.2, "b")
	hang("art_abstract", "wingback", 9.3, 7.6, "b")

	-- the bedroom, behind the bay window
	-- (clear of the curtains at the window beside it)
	item("bed_single", 3, 6.1, 180)
	item("nightstand", 5.95, 8.75, 180)
	item("lamp_table", 5.95, 8.75, 180, top("nightstand"))
	item("rug_round", 6.8, 4.8, 0)
	item("wardrobe", 10.6, 4, 270)
	item("light_ceiling", 6.5, 5, 0)
	hang("curtains", "leftfront", 5, 2.2, "b")
	hang("art_flowers", "bedroom", 5, 5.8, "a")

	-- the kitchen: a run along the back wall, the fridge round the corner, a table by the window
	item("counter_sink", 7.4, 22.4, 180)
	item("stove", 4.4, 22.4, 180)
	item("counter_corner", 1.6, 22.4, 90)
	item("kettle", 1.5, 22.5, 135, top("counter_corner"))
	item("fridge", 1.6, 19.6, 90)
	item("table_dining_small", 3.4, 14, 0)
	item("vase_flowers", 3.4, 14, 0, top("table_dining_small"))
	item("chair_wood", 6, 14, 270)
	item("chair_wood", 3.4, 11.4, 0)
	item("plant_big", 10.1, 22, 0)
	item("lamp_pendant", 3.4, 14, 0)
	hang("shelf_wall", "back", 7.6, 6.6, "b")
	hang("curtains", "leftback", 10, 2.2, "b")
	hang("art_landscape", "bedroom", 3.4, 6, "b")

	-- the workshop ---------------------------------------------------------------------------------
	-- Three boarded walls and a roof, open to the front, 12 by 8. The builder's bench stands across
	-- the opening with its tools to the street: the worker stands at it on the threshold, whoever
	-- drops by walks in at the right and round behind it.
	ox, oz = OX + SHOP_X, OZ

	floor(0, 0, 12, 8, FLAGS)
	floor(0, -4, 12, 0, PAVING)
	wall("shopright", 12, 0, 12, 8, BOARDS, SHOP_IN)
	wall("shopback", 12, 8, 0, 8, BOARDS, SHOP_IN)
	wall("shopleft", 0, 8, 0, 0, BOARDS, SHOP_IN)
	roof(0, 0, 12, 8, 5, 0)
	opening("win_small", "shopback", 2.5)
	for _, t in { 2, 6 } do
		hang("stone_footing", "shopright", t, 0, "a")
		hang("stone_footing", "shopleft", t, 0, "a")
	end
	for _, t in { 2, 6, 10 } do
		hang("stone_footing", "shopback", t, 0, "a")
	end
	item("corner_board", 0, 0, 180, 0)
	item("corner_board", 12, 0, 90, 0)
	item("corner_board", 12, 8, 0, 0)
	item("corner_board", 0, 8, 270, 0)
	hang("lantern_wall", "shopleft", 7, 5.6, "a")
	hang("sign_workshop", "shopleft", 7.5, 8.4, "a")
	hang("trellis", "shopback", 8, 1.3, "a")

	item("work_builder", 4.2, 2.6, 180)
	hang("tool_board", "shopback", 7.8, 5.9, "b") -- over the heads of whoever stands at the back
	hang("string_lights", "shopback", 6, 9.6, "b")
	item("crate", 1.5, 6.6, 0)
	item("crate", 1.6, 6.5, 20, top("crate"))
	item("stool", 10.85, 6.85, 0)
	item("lamp_pendant", 4.2, 3.6, 0)
	-- out on the flags, clear of the way in
	item("sawhorse", 9.8, -3.9, 0, 0)
	item("crate", 1.4, -4.7, 15, 0)

	-- the garden -----------------------------------------------------------------------------------
	-- A picket fence along the front with a gate on the path, flowers inside it, a bench under
	-- the bay. Round the back, out of the way of the street: two beds of vegetables and a tree
	-- with a swing.
	ox, oz = OX, OZ

	for _, x in { 2, 6, 10, 14, 22, 26, 30, 34, 38 } do
		item("fence_picket", x, -FRONT, 0)
	end
	item("fence_picket", 0, -FRONT + 2, 90)
	item("fence_picket", 0, -FRONT + 6, 90)
	item("fence_picket", TIGHT_W, -FRONT + 2, 90)
	item("gate_garden", 18, -FRONT, 0, F)
	item("lamp_post", 14.9, -FRONT + 1.2, 0)
	item("mailbox", 21, -3, 270)
	for _, x in { 2.5, 6.5, 10.5, 23.5 } do
		item("flower_border", x, -FRONT + 1, 0)
	end
	item("bench_garden", 6, -2.2, 180)
	item("bird_house", 1.6, -2.8, 200)
	item("bicycle", 13.3, -0.8, 10)
	item("planter_box", 6, HOUSE_Z - 2.9, 180)
	item("bush", 1.6, HOUSE_Z - 1.5, 0)
	item("bush", 10.4, HOUSE_Z - 1.5, 0)
	item("bush", 13.5, HOUSE_Z + 0.9, 0)
	item("bush", 22.6, HOUSE_Z + 0.9, 0)
	-- stepping stones from the gate to the porch steps, and across to the workshop
	item("path_stones", 17.8, -2.8, 0)
	item("path_stones", 18.3, -0.5, 90)
	item("path_stones", 17.7, 1.8, 200)
	item("path_stones", 23, -2.5, 0)
	item("path_stones", 25.5, -1.7, 40)

	item("veg_patch", 31, 13, 0)
	item("veg_patch", 35.5, 13, 90)
	item("tree_swing", 30, 22.5, 0)

	-- a paved path from the street to just inside the gate
	floor(16, -OZ, 20, -FRONT + 2, PAVING)

	-- opened up -------------------------------------------------------------------------------
	-- Floor let in along the lines in CUTS, on the plot. The stones at the walls' feet, the
	-- fence and the borders close up over the gaps; everything is a gift at its new size.
	local function onPlot(list: { Spread.Cut }?, o: number): { Spread.Cut }
		local out = {}
		for _, c in list or {} :: { Spread.Cut } do
			table.insert(out, { c[1] + o, c[2] })
		end
		return out
	end
	local cuts: Spread.Cuts = { x = onPlot(CUTS.x, OX), z = onPlot(CUTS.z, OZ) }
	local entries: { Spread.Entry } = {}
	for _, kind in Plan.Kinds do
		local keys = {}
		for key in (plan :: any)[kind] do
			table.insert(keys, key)
		end
		table.sort(keys, function(a, b)
			return (tonumber(a) or 0) < (tonumber(b) or 0)
		end)
		for _, key in keys do
			local obj = (plan :: any)[kind][key]
			local on = if kind == "items" and obj.wall then plan.walls[obj.wall] else nil
			table.insert(entries, { kind = kind, obj = obj, wall = on })
		end
	end
	for _, f in Spread.apply(cuts, entries) do
		add(f.kind, f.obj)
	end
	for _, kind in Plan.Kinds do
		for _, obj in (plan :: any)[kind] do
			obj.gift = Plan.cost(kind, obj)
		end
	end

	-- What goes on the opened up house, in its frame: the gabled part is now x 0 to 18 and z 0
	-- to 34, the wing x 18 to 38 and z 12 to 32, the porch in front of it from z 6.
	ox, oz = OX, OZ + HOUSE_Z
	-- the bay window in the middle of the gabled front with a basket either side, a window up
	-- in each gable and the weathervane on the ridge
	opening("win_bay", "gable", 9, WHITE, TILE.c)
	hang("hanging_basket", "gable", 4.4, 5, "a")
	hang("hanging_basket", "gable", 13.6, 5, "a")
	upstairs("window_attic", 9, 0, 180, WHITE, GREEN)
	upstairs("window_attic", 9, 34, 0, WHITE, GREEN)
	upstairs("weathervane", 9, 0.8, 0)
	-- the porch rail on from the post against the gabled part
	item("porch_rail", 21.5, 6.5, 0)
	item("porch_rail", 24.5, 6.5, 0)
	-- a dresser in the bedroom, the kitchen's counter on past the sink, and a chair and a lamp
	-- by the fire in the front room
	item("dresser", 10.6, 12.9, 180)
	item("counter", 10.4, 32.4, 180)
	item("armchair", 27.2, 27.2, 90)
	item("table_side", 27.2, 24.6, 0)
	item("lamp_table", 27.2, 24.6, 0, top("table_side"))
	-- the workshop's side windows in the middle of its longer walls
	ox, oz = OX + Spread.axis(CUTS.x, SHOP_X), OZ
	opening("win_square", "shopleft", 6)
	opening("win_square", "shopright", 6)
	dress("shopleft", 6, false)
	dress("shopright", 6, false)

	-- a driveway from the street up the right of the workshop, laid in the grass with an edging
	-- course (Shapes.laid: the user's "curbs, sidewalks, driveways" round a house on its own)
	ox, oz = OX + W + 4, 0
	floor(0, 0, 10, OZ + 16, DRIVE)

	return plan
end

-- What a new plot starts with: the whole of it but the pieces in Held (the bedroom without its
-- bed, the workshop without its bench). A saved plan is never changed: this is only for a player
-- who has none.
function StarterHouse.newPlot(): Plan.PlanData
	local plan = StarterHouse.plan()
	for key, item in plan.items do
		if table.find(StarterHouse.Held, item.id) then
			plan.items[key] = nil
		end
	end
	return plan
end

return StarterHouse
