--!strict
-- The artist's studio: a tall block two storeys high inside, glass up its whole front under a
-- roof that climbs to the street, beside a low flat roofed gallery with a walled yard of
-- sculptures in front of it.
local Catalog = require(script.Parent.Parent.Parent.Build.Catalog)
local Tuning = require(script.Parent.Parent.Parent.Config.Tuning)

type Finish = { c: string, m: string }

local F = Tuning.Plot.Foundation

-- finishes (the town's palette)
local WALLS: Finish = { c = "DAD4C8", m = "Concrete" } -- pale stone, the studio outside
local GALLERY: Finish = { c = "F6F0E2", m = "Plaster" } -- warm white, the gallery outside
local STUDIO_IN: Finish = { c = "F6F0E2", m = "Plaster" }
local GALLERY_IN: Finish = { c = "FAF6EC", m = "Plaster" }
local COCOA: Finish = { c = "6A5C5A", m = "Slate" }
local DECK: Finish = { c = "6A5C5A", m = "Concrete" } -- the gallery's flat roof
local PARAPET: Finish = { c = "FAF6EC", m = "Plaster" }
local CONCRETE: Finish = { c = "DAD4C8", m = "Concrete" } -- the studio floor
local PALE_WOOD: Finish = { c = "DDBE94", m = "WoodPlanks" } -- the gallery floor
local PEBBLES: Finish = { c = "D8D2C4", m = "Pebble" } -- the yard
local PAVING: Finish = { c = "EAE6DC", m = "Pavement" }
local STONE: Finish = { c = "D8CFBF", m = "Cobblestone" }
-- paint for the pieces
local WHITE = "FAF6EC"
local DARK = "5A5560" -- the window frames
local MUSTARD = "D9A93F" -- the accent: the doors
local BLUE = "6E8CA8"
local OAK = "C49A6C"
local WALNUT = "9A6B48"
local PALE = "DDBE94"
local CORAL = "E08566"
local NAVY = "46608E"

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

-- a wall of another style (stone, fence, glass), the same finish both sides
local function styled(b: any, name: string, x1: number, z1: number, x2: number, z2: number, f: Finish, style: string)
	b:wall(name, x1, z1, x2, z2, f, f)
	b.walls[name].style = style
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
		"studio",
		"Artist's studio",
		"A painter's studio with a tall glass front and sculptures in the yard.",
		"brush",
		34,
		24,
		function(b: any)
			-- The studio is x 18 to 32 and z 4 to 22, two storeys of wall with no floor between,
			-- its roof high over the glass at the front.
			-- The gallery is x 2 to 18 and z 10 to 22 under a flat roof, and its yard is in front
			-- of it inside a low stone wall, with a gap where the path comes in.
			b:floor(18, 4, 32, 22, CONCRETE)
			b:floor(2, 10, 18, 22, PALE_WOOD)
			b:floor(2, 2, 18, 10, PEBBLES)
			b:floor(0, 0, 18, 2, PAVING)
			b:floor(18, 0, 34, 4, PAVING)

			b:wall("front", 18, 4, 32, 4, WALLS, STUDIO_IN)
			b:wall("right", 32, 4, 32, 22, WALLS, STUDIO_IN)
			b:wall("back", 32, 22, 18, 22, WALLS, STUDIO_IN)
			b:wall("shared", 18, 22, 18, 10, GALLERY_IN, STUDIO_IN) -- side a is the gallery's
			b:wall("yardside", 18, 10, 18, 4, WALLS, STUDIO_IN)
			b:wall("front1", 18, 4, 32, 4, WALLS, STUDIO_IN, 1)
			b:wall("right1", 32, 4, 32, 22, WALLS, STUDIO_IN, 1)
			b:wall("back1", 32, 22, 18, 22, WALLS, STUDIO_IN, 1)
			b:wall("left1", 18, 22, 18, 4, WALLS, STUDIO_IN, 1)
			b:wall("gfront", 2, 10, 18, 10, GALLERY, GALLERY_IN)
			b:wall("gback", 18, 22, 2, 22, GALLERY, GALLERY_IN)
			b:wall("gleft", 2, 22, 2, 10, GALLERY, GALLERY_IN)
			-- the yard's stone wall
			styled(b, "yard1", 2, 2, 4, 2, STONE, "stone")
			styled(b, "yard2", 8, 2, 18, 2, STONE, "stone")
			styled(b, "yard3", 18, 2, 18, 4, STONE, "stone")
			styled(b, "yard4", 2, 10, 2, 2, STONE, "stone")

			b:roof(18, 4, 32, 22, "shed", 4, 2, COCOA, WALLS, 1, 0.8)
			b:roof(2, 10, 18, 22, "flat", 0, 0, DECK, PARAPET, 0, 0.2)

			-- the tall glass along the studio's front, the gallery's door and window on the yard
			for _, t in { 2.6, 7, 11.4 } do
				b:open("win_floor", "front", t)
				paint(b, DARK, DARK)
				b:open("win_floor", "front1", t)
				paint(b, DARK, DARK)
			end
			b:open("win_tall", "right1", 9)
			paint(b, DARK, DARK)
			b:open("win_tall", "left1", 6)
			paint(b, DARK, DARK)
			b:open("win_tall", "left1", 12.4)
			paint(b, DARK, DARK)
			b:open("win_tall", "right", 6)
			paint(b, DARK, DARK)
			b:open("win_tall", "right", 12)
			paint(b, DARK, DARK)
			b:open("win_small", "back", 3)
			paint(b, DARK, DARK)
			for _, t in { 4, 10 } do
				b:open("win_square", "back1", t)
				paint(b, DARK, DARK)
			end
			b:open("arch_wide", "shared", 6)
			b:open("door_front", "gfront", 4)
			paint(b, MUSTARD, WHITE)
			b:open("win_picture", "gfront", 11.2)
			paint(b, DARK, DARK)
			b:open("win_tall", "gleft", 6)
			paint(b, DARK, DARK)

			-- outside: the sign out over the yard, lamps, trim, stone along the foot of the walls
			hang(b, "sign_palette", "yardside", 5, 8.6, "a")
			hang(b, "hanging_basket", "yardside", 2, 4.6, "a", WALNUT, CORAL)
			hang(b, "trellis", "back", 8, 1.3, "a", WHITE, CORAL)
			hang(b, "trellis", "back", 12, 1.3, "a", WHITE, "E9C46A")
			hang(b, "lantern_wall", "gfront", 1.2, 5.6, "a")
			hang(b, "window_box", "gfront", 8.9, 1.55, "a", WHITE, CORAL)
			hang(b, "window_box", "gfront", 13.5, 1.55, "a", WHITE, "E9C46A")
			hang(b, "lantern_wall", "right", 9, 6.4, "a")
			for _, t in { 2, 6, 10, 14 } do
				hang(b, "stone_footing", "back", t, 0, "a")
				hang(b, "stone_footing", "gback", t, 0, "a")
			end
			for _, t in { 2, 10 } do
				hang(b, "stone_footing", "gleft", t, 0, "a")
			end
			for _, t in { 2, 16 } do
				hang(b, "stone_footing", "right", t, 0, "a")
			end
			hang(b, "trellis", "gback", 4, 1.3, "a", WHITE, CORAL)
			hang(b, "trellis", "gback", 12, 1.3, "a", WHITE, "E9C46A")
			hang(b, "downpipe", "right", 17.3, 0, "a")
			hang(b, "downpipe", "right1", 17.3, 0, "a")
			-- (the upper one over the gallery a hair up off its roof)
			put(b, "corner_board", 18, 4, 180, 0)
			put(b, "corner_board", 32, 4, 90, 0)
			put(b, "corner_board", 32, 22, 0, 0)
			for _, c in { { 18, 4, 180, 0 }, { 32, 4, 90, 0 }, { 32, 22, 0, 0 }, { 18, 22, 270, 0.05 } } do
				b:item("corner_board", c[1], c[2], c[3], 1, F + Tuning.Plot.LevelHeight + c[4])
			end
			put(b, "corner_board", 2, 10, 180, 0)
			put(b, "corner_board", 2, 22, 270, 0)

			-- the yard: the path from the gap to the door, two sculptures on the pebbles, a
			-- bench to look at them from, a lamp, and planting in the corners
			put(b, "path_stones", 6, 3.2, 0, F)
			put(b, "path_stones", 6, 5.6, 10, F)
			put(b, "path_stones", 6, 8, 0, F)
			put(b, "sculpture_ring", 12.4, 7.2, 0, nil, "BDB8AE", "C0784E")
			put(b, "sculpture_form", 16, 4.6, 0, nil, "8E8A86", WHITE)
			put(b, "bench_garden", 11.8, 3.9, 0, F, OAK, DARK)
			put(b, "lamp_post", 8.8, 8.6, 0, F)
			put(b, "flower_pot", 3.3, 8.9, 0, F, nil, "E9C46A")
			put(b, "planter_box", 15.6, 8.8, 0, F, WALNUT, CORAL)
			put(b, "flower_pot", 3.4, 3.6, 0, F, nil, CORAL)
			put(b, "bird_house", 3.5, 5.6, 0, F, WHITE, MUSTARD)
			-- the pavement in front of the studio
			put(b, "bench_garden", 25, 1.4, 0, F, OAK, DARK)
			put(b, "planter_box", 20.6, 1.4, 0, F, WALNUT, "9C86B8")
			put(b, "planter_box", 29.4, 1.4, 0, F, WALNUT, "E9C46A")
			put(b, "bicycle", 33, 9, 0, F, BLUE, WALNUT)
			put(b, "path_stones", 33, 13.4, 0)
			put(b, "path_stones", 33, 16.2, 0)

			-- the studio: the easel in the light from the glass, the sitter's chair in the corner
			-- by the window, a sink for brushes, the work bench and its shelves, canvases stacked
			-- against the back wall, and a stove to keep the painter warm
			put(b, "work_easel", 25, 10, 180, nil, WALNUT, WHITE)
			put(b, "rug_round", 25, 13, 0, nil, "C9B8A0", WHITE)
			put(b, "stool", 28, 13.8, 0, nil, PALE, BLUE)
			put(b, "armchair", 29, 7.4, 320, nil, CORAL, WALNUT)
			put(b, "plant_big", 30.2, 17.6, 0, nil, WHITE)
			put(b, "shelf_cubes", 30.85, 13.8, 270, nil, WHITE, BLUE)
			put(b, "table_side", 30.6, 10.6, 0, nil, WHITE, BLUE)
			put(b, "lamp_table", 30.6, 10.6, 0, top("table_side"), WHITE, MUSTARD)
			put(b, "plant_small", 30.8, 12.9, 0, top("shelf_cubes"))
			put(b, "vase_flowers", 30.8, 14.7, 0, top("shelf_cubes"), NAVY, "E9C46A")
			put(b, "counter_sink", 19.6, 7.2, 90, nil, WHITE, "DAD4C8")
			put(b, "kettle", 19.5, 6.3, 90, top("counter_sink"), MUSTARD)
			put(b, "workbench", 25.4, 20.5, 180, nil, PALE, WALNUT)
			put(b, "lamp_desk", 23.6, 20.8, 160, top("workbench"), MUSTARD)
			put(b, "vase_flowers", 27.2, 20.6, 0, top("workbench"), WHITE, CORAL)
			put(b, "books_stack", 25.6, 20.9, 10, top("workbench"))
			put(b, "canvas_stack", 20.2, 20.72, 180, nil, "8FB3C8", OAK)
			put(b, "canvas_stack", 29.8, 20.7, 180, nil, "C9A27A", OAK)
			put(b, "lamp_floor", 22, 9.2, 0, nil, WHITE, DARK)
			put(b, "coat_stand", 19.4, 10.6, 0, nil, WALNUT, MUSTARD)
			b:item("lamp_pendant", 25, 11, 0, 1)
			paint(b, WHITE)
			b:item("lamp_pendant", 25, 17, 0, 1)
			paint(b, WHITE)
			hang(b, "sconce", "back", 9.2, 7.2, "b")
			hang(b, "sconce", "yardside", 4.4, 7.2, "b")
			hang(b, "tool_board", "back", 6.6, 6.2, "b", PALE, WALNUT)
			hang(b, "shelf_wall", "back", 11.6, 7.4, "b", OAK)
			hang(b, "clock_wall", "right", 2.6, 8.4, "b", DARK)
			hang(b, "art_abstract", "right", 9, 6.6, "b", NAVY, WHITE)
			hang(b, "art_landscape", "right", 15.4, 5.4, "b")

			-- the gallery: pictures round the walls, a sculpture on show, a bench in the middle
			-- and a little desk by the door
			put(b, "sculpture_form", 10, 18.4, 0, nil, DARK, "C8A27A")
			put(b, "bench_wood", 10, 14.2, 0, nil, OAK, WALNUT)
			put(b, "rug_long", 10, 15.4, 90, nil, "C9B8A0", WHITE)
			put(b, "desk", 3.6, 16, 90, nil, OAK, WHITE)
			put(b, "lamp_desk", 3.4, 17.4, 90, top("desk"), MUSTARD)
			put(b, "books_stack", 3.6, 15, 0, top("desk"))
			put(b, "vase_flowers", 3.5, 16.2, 0, top("desk"), WHITE, CORAL)
			put(b, "chair_wood", 5.8, 16, 270, nil, OAK, BLUE)
			put(b, "plant_big", 4, 20, 0, nil, WHITE)
			put(b, "canvas_stack", 15.9, 20.72, 180, nil, "D6B8C8", OAK)
			for _, p in { { 6, 14 }, { 10, 18 }, { 14, 14 } } do
				put(b, "light_ceiling", p[1], p[2], 0)
			end
			hang(b, "art_landscape", "gback", 3.4, 5.4, "b")
			hang(b, "art_abstract", "gback", 8, 5.6, "b", BLUE, WHITE)
			hang(b, "art_flowers", "gback", 12.4, 5.6, "b")
			hang(b, "sconce", "gback", 5.7, 7.6, "b")
			hang(b, "sconce", "gback", 10.2, 7.6, "b")
			hang(b, "art_abstract", "gleft", 2.4, 5.6, "b", CORAL, WHITE)
			hang(b, "art_flowers", "gleft", 9.6, 5.6, "b")

			-- opened up: the studio wider between its tall windows and deeper, the gallery wider
			-- and deeper, the yard with them
			b:spread({ x = { { 8.4, 4 }, { 16.4, 4 }, { 22.8, 4 }, { 27.3, 4 } }, z = { { 8.9, 4 }, { 18.45, 6 } } })
		end
	)
end
