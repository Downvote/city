--!strict
-- The music hall: a tall hall with its gable to the street, a stage behind curtains at the far
-- end and rows of seats, entered through a low white foyer whose roof leans on the hall's front.
local Catalog = require(script.Parent.Parent.Parent.Build.Catalog)
local Tuning = require(script.Parent.Parent.Parent.Config.Tuning)

type Finish = { c: string, m: string }

local F = Tuning.Plot.Foundation

-- finishes (the town's palette)
local LAVENDER: Finish = { c = "D8D2E6", m = "Plaster" } -- the hall outside
local FOYER: Finish = { c = "FAF6EC", m = "Plaster" } -- the foyer outside
local HALL_IN: Finish = { c = "F2E6CC", m = "SmoothPlastic" }
local FOYER_IN: Finish = { c = "F6F0E2", m = "SmoothPlastic" }
local PLUM: Finish = { c = "8A6F90", m = "Slate" }
local GABLE: Finish = { c = "D8D2E6", m = "Plaster" }
local WALNUT_FLOOR: Finish = { c = "9A6B48", m = "WoodPlanks" }
local TILES: Finish = { c = "F2E6CC", m = "CeramicTiles" }
local PAVING: Finish = { c = "EAE6DC", m = "Pavement" }
-- paint for the pieces
local WHITE = "FAF6EC"
local BERRY = "B8505A" -- the accent: doors, seats, curtains
local PLUM_C = "8A6F90"
local MUSTARD = "D9A93F"
local WALNUT = "9A6B48"
local OAK = "C49A6C"
local DARK = "5A5560"
local SAGE = "86A886"

local function paint(b: any, c1: string?, c2: string?)
	local o = b.objects[#b.objects].obj
	o.c1 = c1
	o.c2 = c2
end

local function hang(b: any, id: string, wall: string, t: number, y: number, side: string?, c1: string?, c2: string?)
	local w = b.walls[wall]
	assert(w and Catalog.get(id), "bad wall piece " .. id .. " on " .. wall)
	table.insert(b.objects, {
		kind = "items",
		obj = { id = id, x = 0, y = y, z = 0, r = 0, lv = w.lv, t = t, side = side or "a", c1 = c1, c2 = c2 },
		wallName = wall,
	})
end

local function put(b: any, id: string, x: number, z: number, r: number?, y: number?, c1: string?, c2: string?)
	b:item(id, x, z, r or 0, 0, y)
	if c1 or c2 then
		paint(b, c1, c2)
	end
end

local function top(id: string): number
	local def = Catalog.get(id)
	return F + (if def and def.surface then def.surface else 0)
end

return function(add: any)
	add(
		"musichall",
		"Music hall",
		"A small hall with a stage, rows of seats and a foyer with a ticket desk.",
		"music",
		28,
		30,
		function(b: any)
			-- The hall is x 4 to 24 and z 8 to 28, two storeys of wall with no floor between and
			-- the gable to the street. The foyer is x 8 to 20 and z 2 to 8, against its front.
			b:floor(4, 8, 24, 28, WALNUT_FLOOR)
			b:floor(8, 2, 20, 8, TILES)
			b:floor(0, 0, 28, 2, PAVING)
			b:floor(0, 2, 8, 8, PAVING)
			b:floor(20, 2, 28, 8, PAVING)

			-- the hall, its front in three: the foyer's back wall between two bits of outside
			b:wall("hfront1", 4, 8, 8, 8, LAVENDER, HALL_IN)
			b:wall("hfront2", 8, 8, 20, 8, FOYER_IN, HALL_IN)
			b:wall("hfront3", 20, 8, 24, 8, LAVENDER, HALL_IN)
			b:wall("hright", 24, 8, 24, 28, LAVENDER, HALL_IN)
			b:wall("hback", 24, 28, 4, 28, LAVENDER, HALL_IN)
			b:wall("hleft", 4, 28, 4, 8, LAVENDER, HALL_IN)
			b:box("up", 4, 8, 24, 28, LAVENDER, HALL_IN, 1)
			-- the foyer
			b:wall("ffront", 8, 2, 20, 2, FOYER, FOYER_IN)
			b:wall("fright", 20, 2, 20, 8, FOYER, FOYER_IN)
			b:wall("fleft", 8, 8, 8, 2, FOYER, FOYER_IN)

			b:roof(4, 8, 24, 28, "gable", 7, 1, PLUM, GABLE, 1, 1)
			b:roof(8, 2, 20, 8, "shed", 4, 0, PLUM, FOYER, 0, 0.8)

			-- doors and windows: double doors in and through, tall windows down both sides and
			-- high up, three over the foyer's roof (lifted clear of it), a window in the gable
			b:open("door_double", "ffront", 6)
			paint(b, BERRY, WHITE)
			b:open("win_tall", "ffront", 1.5)
			paint(b, WHITE, WHITE)
			b:open("win_tall", "ffront", 10.5)
			paint(b, WHITE, WHITE)
			b:open("win_porthole", "fleft", 3)
			paint(b, MUSTARD, WHITE)
			b:open("win_porthole", "fright", 3)
			paint(b, MUSTARD, WHITE)
			b:open("door_double", "hfront2", 6)
			paint(b, BERRY, WHITE)
			for _, t in { 6, 10, 14 } do
				b:open("win_tall", "hleft", t)
				b:open("win_tall", "hright", t)
				b:open("win_tall", "upleft", t)
				b:open("win_tall", "upright", t)
			end
			for _, t in { 6, 10, 14 } do
				b:open("win_tall", "upfront", t)
				b.objects[#b.objects].obj.y = 5
			end
			b:open("win_porthole", "upback", 10)
			paint(b, MUSTARD, WHITE)
			b:item("window_attic", 14, 8, 180, 2)
			paint(b, WHITE, PLUM_C)
			b:item("weathervane", 14, 10, 0, 2)

			-- outside: the sign out from the foyer's side, posters either side of the foyer with
			-- a lamp over each, lamps on the pavement, trim, stone along the foot of the walls
			hang(b, "sign_music", "fright", 0.9, 8.6, "a")
			hang(b, "art_abstract", "hfront1", 2, 3.4, "a", PLUM_C, WHITE)
			hang(b, "art_landscape", "hfront3", 2, 3.4, "a")
			hang(b, "sconce", "hfront1", 2, 7.6, "a")
			hang(b, "sconce", "hfront3", 2, 7.6, "a")
			hang(b, "bunting", "ffront", 6, 9.6, "a", WHITE)
			hang(b, "art_abstract", "hleft", 17.8, 3.4, "a", BERRY, WHITE)
			hang(b, "art_abstract", "hright", 2.2, 3.4, "a", MUSTARD, PLUM_C)
			for _, t in { 2, 18 } do
				hang(b, "stone_footing", "hleft", t, 0, "a")
				hang(b, "stone_footing", "hright", t, 0, "a")
			end
			for _, t in { 2, 6, 10, 14, 18 } do
				hang(b, "stone_footing", "hback", t, 0, "a")
			end
			hang(b, "trellis", "hback", 6, 1.3, "a", WHITE, BERRY)
			hang(b, "trellis", "hback", 14, 1.3, "a", WHITE, "9C86B8")
			hang(b, "downpipe", "hback", 0.5, 0, "a")
			hang(b, "downpipe", "upback", 0.5, 0, "a")
			hang(b, "downpipe", "hback", 19.5, 0, "a")
			hang(b, "downpipe", "upback", 19.5, 0, "a")
			for _, c in { { 4, 8, 180 }, { 24, 8, 90 }, { 24, 28, 0 }, { 4, 28, 270 } } do
				put(b, "corner_board", c[1], c[2], c[3], 0)
				b:item("corner_board", c[1], c[2], c[3], 1)
			end
			put(b, "corner_board", 8, 2, 180, 0, LAVENDER.c, LAVENDER.c)
			put(b, "corner_board", 20, 2, 90, 0, LAVENDER.c, LAVENDER.c)
			put(b, "lamp_post", 6, 1.1, 0, F)
			put(b, "lamp_post", 22, 1.1, 0, F)
			put(b, "flower_pot", 10.2, 1, 0, F, nil, BERRY)
			put(b, "flower_pot", 17.8, 1, 0, F, nil, MUSTARD)
			put(b, "bench_garden", 3.6, 4.4, 180, F, OAK, DARK)
			put(b, "bench_garden", 24.4, 4.4, 180, F, OAK, DARK)
			put(b, "flower_border", 5.7, 6.8, 180, F, WHITE, BERRY)
			put(b, "flower_border", 22.3, 6.8, 180, F, WHITE, BERRY)
			put(b, "bicycle", 26.4, 13, 0, nil, BERRY, WALNUT)
			put(b, "bush", 2, 11, 0)
			put(b, "bush", 2, 26.4, 0)
			put(b, "bush", 26, 26.4, 0)
			put(b, "flower_border", 2, 18, 270, nil, WHITE, BERRY)
			put(b, "flower_border", 26, 19.6, 90, nil, WHITE, "E9C46A")

			-- the foyer: the ticket desk, a bench to wait on, posters and a clock over the door
			put(b, "desk", 18.5, 5, 270, nil, WALNUT, WHITE)
			put(b, "lamp_table", 18.5, 3.8, 0, top("desk"), WHITE, BERRY)
			put(b, "books_stack", 18.6, 6.1, 20, top("desk"))
			put(b, "vase_flowers", 18.4, 4.9, 0, top("desk"), WHITE, BERRY)
			put(b, "bench_wood", 9.3, 5, 90, nil, OAK, WALNUT)
			put(b, "rug_long", 14, 5, 90, nil, BERRY, MUSTARD)
			put(b, "light_ceiling", 14, 5, 0)
			hang(b, "art_flowers", "hfront2", 1.4, 4.8, "a")
			hang(b, "art_flowers", "hfront2", 10.6, 4.8, "a")
			hang(b, "clock_wall", "ffront", 6, 9.2, "b", BERRY)

			-- the hall: the stage at the far end behind its curtains, a piano to the left, a
			-- corner behind a screen on the right where the players wait, and the rows of seats
			put(b, "work_stage", 14, 24.7, 180, nil, BERRY, DARK)
			put(b, "stage_curtain", 14, 21.1, 0, nil, BERRY, MUSTARD)
			put(b, "piano", 6.4, 24.6, 90, nil, DARK, BERRY)
			put(b, "stool", 9.2, 24.6, 0, nil, WALNUT, BERRY)
			put(b, "screen_folding", 21.5, 22.1, 0, nil, WALNUT, WHITE)
			put(b, "armchair", 22, 25.9, 270, nil, SAGE, WALNUT)
			put(b, "coat_stand", 22.8, 23.3, 0, nil, WALNUT, BERRY)
			put(b, "mirror_floor", 18.9, 23.9, 90, nil, MUSTARD, WALNUT)
			put(b, "table_side", 19.3, 26.6, 0, nil, WHITE, SAGE)
			put(b, "kettle", 19.3, 26.6, 200, top("table_side"), BERRY)
			for _, z in { 11.2, 14.6, 18 } do
				put(b, "seat_row", 8.1, z, 0, nil, BERRY, WALNUT)
				put(b, "seat_row", 19.9, z, 0, nil, BERRY, WALNUT)
			end
			put(b, "rug_long", 14, 14.6, 0, nil, BERRY, MUSTARD)
			b:item("chandelier", 14, 13, 0, 1)
			b:item("chandelier", 14, 19, 0, 1)
			for _, t in { 4, 8, 12 } do
				hang(b, "sconce", "hleft", t, 7.4, "b")
			end
			for _, t in { 4, 8, 12, 16 } do
				hang(b, "sconce", "hright", t, 7.4, "b")
			end
			hang(b, "art_landscape", "hleft", 18, 5, "b")
			for _, t in { 6, 14 } do
				hang(b, "string_lights", "upleft", t, 9.2, "b")
				hang(b, "string_lights", "upright", t, 9.2, "b")
			end
			hang(b, "art_flowers", "hright", 2, 5, "b")
		end
	)
end
