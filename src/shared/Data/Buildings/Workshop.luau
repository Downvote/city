--!strict
-- The builder's yard: a long timber barn with its ridge along the street and big doors under a
-- gable on posts, a stove chimney through its roof, an open timber store leaning on its end and
-- a fenced yard of planks and sawhorses in front of the store.
local Catalog = require(script.Parent.Parent.Parent.Build.Catalog)
local Tuning = require(script.Parent.Parent.Parent.Config.Tuning)

type Finish = { c: string, m: string }

local F = Tuning.Plot.Foundation

-- finishes (the town's palette)
local SAND: Finish = { c = "E6D5B4", m = "WoodPlanks" } -- the barn outside
local BARN_IN: Finish = { c = "DDBE94", m = "WoodPlanks" }
local ROSE: Finish = { c = "B8665C", m = "RoofShingles" }
local OAK_FLOOR: Finish = { c = "C49A6C", m = "WoodPlanks" }
local FLAGS: Finish = { c = "BDB8AE", m = "Cobblestone" }
local CONCRETE: Finish = { c = "D6CCB8", m = "Concrete" } -- the timber store
local GRAVEL: Finish = { c = "D8D0BE", m = "Pebble" } -- the yard
local PAVING: Finish = { c = "EAE6DC", m = "Pavement" }
local PALINGS: Finish = { c = "C49A6C", m = "Wood" } -- the yard fence, in wood colour
-- paint for the pieces
local WHITE = "FAF6EC"
local NAVY = "46608E" -- the accent: the doors
local OAK = "C49A6C"
local WALNUT = "9A6B48"
local PALE = "DDBE94"
local DARK = "5A5560"
local MUSTARD = "D9A93F"
local CORAL = "E08566"

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
		"workshop",
		"Builder's yard",
		"A timber barn with big doors, a store of planks under a lean-to and a fenced yard.",
		"hammer",
		36,
		28,
		function(b: any)
			-- The barn is x 2 to 20 and z 10 to 26, its ridge along the street. A gable on two
			-- posts stands out over its doors (x 6 to 16 from z 6). The timber store leans on its
			-- right end (x 20 to 34, z 12 to 24), open at the front onto the fenced yard.
			b:floor(2, 10, 20, 26, OAK_FLOOR)
			b:floor(6, 6, 16, 10, FLAGS)
			b:floor(8, 0, 14, 6, PAVING)
			b:floor(20, 12, 34, 24, CONCRETE)
			b:floor(20, 0, 36, 12, GRAVEL)

			b:wall("front", 2, 10, 20, 10, SAND, BARN_IN)
			b:wall("right", 20, 10, 20, 26, SAND, BARN_IN)
			b:wall("back", 20, 26, 2, 26, SAND, BARN_IN)
			b:wall("left", 2, 26, 2, 10, SAND, BARN_IN)
			-- the timber store's two walls (its front is open, on posts)
			b:wall("storeright", 34, 12, 34, 24, SAND, BARN_IN)
			b:wall("storeback", 34, 24, 20, 24, SAND, BARN_IN)
			-- the yard's fence, with a gate on the street
			styled(b, "fence1", 20, 0, 26, 0, PALINGS, "fence")
			styled(b, "fence2", 30, 0, 36, 0, PALINGS, "fence")
			styled(b, "fence3", 36, 0, 36, 12, PALINGS, "fence")
			styled(b, "fence4", 36, 12, 34, 12, PALINGS, "fence")
			styled(b, "fence5", 20, 10, 20, 0, PALINGS, "fence")

			b:roof(2, 10, 20, 26, "gable", 9, 0, ROSE, SAND, 0, 1.2)
			b:roof(6, 6, 16, 16, "gable", 5, 1, ROSE, SAND, 0, 0.8)
			b:roof(20, 12, 34, 24, "shed", 1.6, 3, ROSE, SAND, 0, 0.4)

			-- doors and windows
			b:open("door_barn_big", "front", 9)
			paint(b, NAVY, WHITE)
			b:open("win_square", "front", 2.8)
			b:open("win_square", "front", 15.2)
			b:open("door_wood", "right", 8)
			paint(b, NAVY, WHITE)
			b:open("win_wide", "back", 5)
			b:open("win_wide", "back", 13)
			b:open("win_square", "left", 3)
			b:open("win_square", "left", 13)
			b:item("weathervane", 11, 18.8, 0, 1)

			-- outside: the posts under the gable, the sign, lamps, trim at the windows, stone
			-- along the foot of the walls, a drainpipe at each end
			put(b, "pillar_square", 6.6, 6.6, 0, nil, WHITE, WHITE)
			put(b, "pillar_square", 15.4, 6.6, 0, nil, WHITE, WHITE)
			hang(b, "sign_workshop", "right", 1, 8.4, "a", PALE, NAVY)
			b:item("lamp_pendant", 11, 7.6, 0)
			paint(b, MUSTARD)
			for _, t in { 2.8, 15.2 } do
				hang(b, "window_hood", "front", t, 7.78, "a", WHITE, ROSE.c)
				hang(b, "window_box", "front", t, 2.05, "a", WHITE, CORAL)
			end
			for _, t in { 3, 13 } do
				hang(b, "window_hood", "left", t, 7.78, "a", WHITE, ROSE.c)
				hang(b, "window_box", "left", t, 2.05, "a", WHITE, MUSTARD)
			end
			for _, t in { 2, 6, 10, 14 } do
				hang(b, "stone_footing", "left", t, 0, "a")
			end
			for _, t in { 2, 6, 10, 14, 16 } do
				hang(b, "stone_footing", "back", t, 0, "a")
			end
			for _, t in { 2, 6, 10 } do
				hang(b, "stone_footing", "storeback", t, 0, "a")
				hang(b, "stone_footing", "storeright", t, 0, "a")
			end
			for _, t in { 2, 16 } do
				hang(b, "stone_footing", "front", t, 0, "a")
			end
			hang(b, "hanging_basket", "left", 8, 5.4, "a", WALNUT, CORAL)
			hang(b, "downpipe", "back", 0.6, 0, "a")
			hang(b, "downpipe", "back", 17.4, 0, "a")
			hang(b, "downpipe", "storeback", 1.6, 0, "a")
			put(b, "water_butt", 32.4, 25.6, 0, nil, NAVY, WALNUT)
			put(b, "woodpile", 11, 27.05, 0, nil, WALNUT, WALNUT)
			put(b, "crate", 27.6, 25.8, 20, nil, OAK, OAK)
			put(b, "bush", 23.4, 26, 0)
			put(b, "corner_board", 2, 10, 180, 0)
			put(b, "corner_board", 20, 10, 90, 0)
			put(b, "corner_board", 20, 26, 0, 0)
			put(b, "corner_board", 2, 26, 270, 0)
			put(b, "corner_board", 34, 24, 0, 0)

			-- the front: a path in from the street, a bench and planters, the bike, a lamp
			put(b, "lamp_post", 6.6, 1.4, 0)
			put(b, "planter_box", 3.6, 7.4, 0, nil, WALNUT, MUSTARD)
			put(b, "planter_box", 17.8, 7.4, 0, nil, WALNUT, CORAL)
			put(b, "bench_garden", 4.2, 3.2, 0, nil, OAK, DARK)
			put(b, "bicycle", 17.2, 3, 90, nil, NAVY, WALNUT)
			put(b, "woodpile", 1, 18, 90, nil, WALNUT, WALNUT)
			put(b, "doormat", 11, 11.4, 0, nil, PALE, WALNUT)
			put(b, "flower_pot", 6.5, 8.8, 0, nil, nil, CORAL)
			put(b, "flower_pot", 15.5, 8.8, 0, nil, nil, MUSTARD)
			put(b, "mailbox", 14.8, 1.4, 270, nil, NAVY, WALNUT)

			-- the timber store: racks of timber against its walls, planks on the floor
			put(b, "timber_rack", 24.4, 22.5, 180, nil, DARK, PALE)
			put(b, "timber_rack", 32.5, 18.6, 270, nil, DARK, "E2C9A0")
			put(b, "plank_stack", 26.6, 16.6, 0, nil, PALE, WALNUT)
			put(b, "sawhorse", 25.6, 20, 0, nil, OAK, PALE)
			put(b, "plank_stack", 26.6, 16.6, 0, top("plank_stack"), "E2C9A0", WALNUT)
			put(b, "crate", 31.6, 13.6, 0, nil, OAK, OAK)
			put(b, "crate", 31.5, 13.5, 15, top("crate"), OAK, OAK)
			for _, x in { 20.8, 27, 33.2 } do
				put(b, "pillar_square", x, 12.6, 0, nil, WALNUT, WALNUT)
			end
			b:item("lamp_pendant", 27, 18, 0)
			paint(b, MUSTARD)

			-- the yard: planks stacked to season, sawhorses with a board across, crates, a
			-- woodpile against the fence, a pine in the corner
			put(b, "gate_garden", 28, 0.4, 0, 0, OAK, OAK)
			put(b, "path_stones", 28, 2.6, 0, F)
			put(b, "plank_stack", 23.3, 7.4, 0, F, PALE, WALNUT)
			put(b, "plank_stack", 23.3, 4.2, 0, F, "E2C9A0", WALNUT)
			put(b, "crate", 21.4, 1.4, 10, F, OAK, OAK)
			put(b, "sawhorse", 32.4, 9, 0, F, OAK, PALE)
			put(b, "crate", 30.9, 6.7, 0, F, OAK, OAK)
			put(b, "crate", 31, 6.6, 12, top("crate"), OAK, OAK)
			put(b, "woodpile", 35.1, 9, 90, F, WALNUT, WALNUT)
			put(b, "tree_pine", 33.4, 2.6, 0, F)

			-- the barn: the builder's bench out in the room with space all round it, the stove
			-- at the end, a work bench and the timber rack along the back, sawhorses by the door,
			-- and the office corner with its desk, kettle and clock
			put(b, "work_builder", 11, 18.5, 180, nil, OAK, DARK)
			put(b, "chimney_hearth", 3.9, 18, 90, nil, "B8665C", "DAD4C8")
			put(b, "workbench", 5.6, 24.5, 180, nil, OAK, WALNUT)
			put(b, "lamp_desk", 4.4, 24.6, 200, top("workbench"), MUSTARD)
			hang(b, "tool_board", "back", 14.4, 6.2, "b", WALNUT, PALE)
			put(b, "timber_rack", 16, 24.5, 180, nil, DARK, PALE)
			put(b, "sawhorse", 4.8, 13.2, 0, nil, OAK, PALE)
			put(b, "crate", 3.6, 22, 0, nil, OAK, OAK)
			put(b, "crate", 3.7, 21.9, 15, top("crate"), OAK, OAK)
			put(b, "desk", 18.5, 12.8, 270, nil, OAK, WHITE)
			put(b, "lamp_desk", 18.7, 11.6, 250, top("desk"), NAVY)
			put(b, "kettle", 18.6, 14.2, 250, top("desk"), CORAL)
			put(b, "books_stack", 18.4, 12.8, 0, top("desk"))
			put(b, "chair_wood", 16.2, 12.8, 90, nil, OAK, NAVY)
			put(b, "coat_stand", 16.4, 15.2, 0, nil, WALNUT, NAVY)
			put(b, "lamp_pendant", 11, 18.5, 0, nil, MUSTARD)
			put(b, "lamp_pendant", 5.6, 22.6, 0, nil, MUSTARD)
			put(b, "light_ceiling", 16, 21, 0)
			hang(b, "clock_wall", "right", 3, 8, "b", NAVY)
			hang(b, "shelf_wall", "front", 16, 8.6, "b", OAK)
			hang(b, "art_landscape", "right", 13.6, 7.6, "b")
		end
	)
end
