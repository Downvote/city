--!strict
-- The bakery, where the baker works. Two gables to the street side by side: the shop, butter
-- yellow plaster under a steep slate roof with a window in the gable, and beside it, set back a
-- little and lower, the stone bakehouse with a serving hatch in its front and a tall chimney up
-- its side. The oven stands against that wall with its mouth to the room. In the shop, cakes
-- under glass, racks of loaves behind the counter and a table by the window.
--
-- The frame: x across, z back from the street (z = 0). The shop is x 2..18 and z 6..24, the
-- bakehouse x 18..28 and z 8..24, the chimney outside it at x 28..31.

local Catalog = require(script.Parent.Parent.Parent.Build.Catalog)
local Tuning = require(script.Parent.Parent.Parent.Config.Tuning)

type Finish = { c: string, m: string }

local F = Tuning.Plot.Foundation

-- finishes: butter plaster and pale stone under slate blue
local BUTTER: Finish = { c = "F3DFA6", m = "Plaster" }
local STONE: Finish = { c = "DAD4C8", m = "Limestone" }
local SHOP_IN: Finish = { c = "F6EBD6", m = "Plaster" }
local BAKE_IN: Finish = { c = "F6F0E2", m = "Plaster" }
local SLATE: Finish = { c = "6E8CA8", m = "Slate" }
local OAK: Finish = { c = "C49A6C", m = "WoodPlanks" }
local BRICK_FLOOR: Finish = { c = "C8A894", m = "Brick" }
local PAVING: Finish = { c = "EAE6DC", m = "Pavement" }

-- paint for the pieces
local TRIM = "FAF6EC"
local NAVY = "46608E"
local NAVY_DARK = "37496C"
local WALNUT = "9A6B48"
local CORAL = "E08566"
local FOOTING = "BDB8AE"
local ROSE_BRICK = "B8665C"

-- The last piece laid, painted.
local function paint(b: any, c1: string?, c2: string?)
	local obj = b.objects[#b.objects].obj
	obj.c1 = c1
	obj.c2 = c2
end

-- Something hung on a named wall: `t` along it, its bottom `y` above the wall's foot (the ground
-- on the ground floor), on side "a" (outside) or "b".
local function hang(b: any, id: string, wall: string, t: number, y: number, side: string, c1: string?, c2: string?)
	table.insert(b.objects, {
		kind = "items",
		obj = { id = id, x = 0, y = y, z = 0, r = 0, lv = b.walls[wall].lv, t = t, side = side, c1 = c1, c2 = c2 },
		wallName = wall,
	})
end

-- The top of a piece standing on the floor, for what stands on it.
local function top(id: string): number
	local def = Catalog.get(id)
	return F + (if def and def.surface then def.surface else 0)
end

-- A stone course along the foot of a wall `len` long, four studs a piece, round the doors
-- (spans of t to leave clear).
local function footing(b: any, wall: string, len: number, skip: { { number } }?)
	local spans = { { 0, len } }
	local cuts: { { number } } = skip or {}
	for _, s in cuts do
		local out = {}
		for _, span in spans do
			if s[2] <= span[1] or s[1] >= span[2] then
				table.insert(out, span)
			else
				table.insert(out, { span[1], s[1] })
				table.insert(out, { s[2], span[2] })
			end
		end
		spans = out
	end
	for _, span in spans do
		local a, e = span[1], span[2]
		if e - a >= 4 then
			local t = a + 2
			while t + 2 < e - 0.01 do
				hang(b, "stone_footing", wall, t, 0, "a", FOOTING)
				t += 4
			end
			hang(b, "stone_footing", wall, e - 2, 0, "a", FOOTING)
		end
	end
end

return function(add: any)
	add(
		"bakery",
		"Bakery",
		"A bread oven in the stone bakehouse, a hatch to the street and cakes in the shop.",
		"store",
		32,
		26,
		function(b: any)
			-- the floors
			b:floor(2, 6, 18, 24, OAK)
			b:floor(18, 8, 28, 24, BRICK_FLOOR)
			b:floor(0, 0, 30, 6, PAVING)
			b:floor(18, 6, 28, 8, PAVING)

			-- the shop's walls, then the bakehouse's; "mid" is the wall between them
			b:wall("front", 2, 6, 18, 6, BUTTER, SHOP_IN)
			b:wall("step", 18, 6, 18, 8, BUTTER, SHOP_IN)
			b:wall("mid", 18, 8, 18, 24, BAKE_IN, SHOP_IN)
			b:wall("back", 18, 24, 2, 24, BUTTER, SHOP_IN)
			b:wall("left", 2, 24, 2, 6, BUTTER, SHOP_IN)
			b:wall("bhfront", 18, 8, 28, 8, STONE, BAKE_IN)
			b:wall("bhright", 28, 8, 28, 24, STONE, BAKE_IN)
			b:wall("bhback", 28, 24, 18, 24, STONE, BAKE_IN)
			-- a steep gable over the shop and a lower one over the bakehouse, both to the street
			b:roof(2, 6, 18, 24, "gable", 10, 1, SLATE, BUTTER, 0, 1.2)
			b:roof(18, 8, 28, 24, "gable", 6, 1, SLATE, STONE, 0, 0.8)

			-- doors and windows
			b:open("door_front", "front", 3.6)
			paint(b, NAVY, TRIM)
			b:open("win_picture", "front", 11.4)
			paint(b, TRIM, TRIM)
			b:open("win_square", "left", 5.6)
			b:open("win_square", "left", 13.4)
			b:open("win_square", "back", 2.6)
			b:open("arch_open", "mid", 10)
			b:open("hatch_serving", "bhfront", 5)
			paint(b, "C49A6C", TRIM)
			b:open("win_square", "bhright", 2.5)
			b:open("win_square", "bhright", 13)
			b:open("win_small", "bhback", 5)

			-- outside -----------------------------------------------------------------------------
			-- the bakery's sign over the door, an awning over the shop window, shutters on the
			-- shop's side, a window up in each gable
			hang(b, "sign_bakery", "front", 3.6, 8.8, "a", "F2E6CC", WALNUT)
			hang(b, "awning", "front", 11.4, F + 7.75, "a", NAVY, TRIM)
			hang(b, "window_box", "front", 11.4, F + 1.1, "a", WALNUT, CORAL)
			for _, t in { 5.6, 13.4 } do
				hang(b, "shutters", "left", t, F + 2.85, "a", NAVY, NAVY_DARK)
				hang(b, "window_box", "left", t, F + 1.65, "a", WALNUT, CORAL)
			end
			hang(b, "window_hood", "back", 2.6, F + 7.38, "a", TRIM, SLATE.c)
			for _, t in { 2.5, 13 } do
				hang(b, "window_hood", "bhright", t, F + 7.38, "a", TRIM, SLATE.c)
				hang(b, "window_box", "bhright", t, F + 1.65, "a", WALNUT, "9C86B8")
			end
			hang(b, "bunting", "front", 8.6, 10.2, "a")
			hang(b, "hanging_basket", "front", 15.4, 8.4, "a")
			b:item("window_attic", 10, 6, 180, 1)
			paint(b, TRIM, NAVY)
			b:item("window_attic", 10, 24, 0, 1)
			paint(b, TRIM, NAVY)
			b:item("weathervane", 10, 15, 0, 1)
			-- the bakehouse chimney, up the outside of the wall the oven stands against
			b:item("chimney", 29.8, 16, 90, 0, 0)
			paint(b, ROSE_BRICK, FOOTING)
			footing(b, "front", 16, { { 1.4, 5.8 } })
			footing(b, "left", 18)
			footing(b, "back", 16)
			for _, c in { { 2, 6, 180 }, { 18, 6, 90 }, { 2, 24, 270 } } do
				b:item("corner_board", c[1], c[2], c[3], 0, 0)
				paint(b, TRIM, TRIM)
			end
			hang(b, "downpipe", "left", 0.5, 0, "a")
			hang(b, "downpipe", "left", 17.5, 0, "a")
			hang(b, "downpipe", "bhright", 15.5, 0, "a")
			hang(b, "lantern_wall", "front", 6.4, 5.6, "a")
			hang(b, "lantern_wall", "bhfront", 1.2, 5.6, "a")
			hang(b, "hanging_basket", "step", 1, 7.4, "a")
			hang(b, "trellis", "back", 11, 1.3, "a")

			-- out front: the step and the mat at the door, a bench under the window, the board
			-- and flower pots by the hatch, a lamp, flowers along the street
			b:item("bench_garden", 13.4, 3.8, 180, 0, F)
			b:item("menu_board", 18.6, 3.2, 200)
			b:item("flower_pot", 19.2, 7, 0)
			b:item("flower_pot", 27, 7, 0)
			b:item("lamp_post", 1.2, 1.4, 0, 0, F)
			b:item("planter_box", 9, 0.9, 0, 0, F)
			b:item("planter_box", 27, 0.9, 0, 0, F)
			b:item("bicycle", 31, 3.6, 0)
			b:item("water_butt", 30.6, 21.4, 90)
			b:item("woodpile", 30.4, 11.8, 90)
			for _, z in { 10, 16, 21 } do
				b:item("flower_border", 1, z, 90)
			end
			b:item("bird_house", 31, 24, 200)

			-- the shop ------------------------------------------------------------------------------
			-- cakes under glass across the room, a counter with the till, the way behind at the end
			b:item("doormat", 5.6, 7.4, 0)
			b:item("display_case", 5.4, 14.6, 180)
			b:item("display_case", 9.4, 14.6, 180)
			b:item("counter", 12.9, 14.6, 180)
			b:item("books_stack", 13.4, 14.6, 20, 0, top("counter"))
			b:item("vase_flowers", 12.2, 14.4, 0, 0, top("counter"))
			-- loaves on racks along the back and the side, the baker's sink, a pantry
			b:item("bread_rack", 6.6, 22.8, 180)
			b:item("bread_rack", 10.8, 22.8, 180)
			b:item("counter_sink", 15.4, 22.4, 180)
			b:item("kettle", 16.5, 22.5, 180, 0, top("counter_sink"))
			b:item("pantry", 3.5, 22.2, 90)
			-- a table by the window for whoever can't wait
			b:item("table_round", 13.6, 9.6, 0)
			paint(b, TRIM, WALNUT)
			b:item("chair_wood", 11.4, 9.6, 90)
			b:item("chair_wood", 15.8, 9.6, 270)
			b:item("vase_flowers", 13.6, 9.6, 0, 0, top("table_round"))
			b:item("lamp_pendant", 7.4, 14.6, 0)
			b:item("lamp_pendant", 13.6, 9.6, 0)
			b:item("light_ceiling", 10, 19.6, 0)
			hang(b, "clock_wall", "front", 11.4, 9.2, "b")
			hang(b, "art_landscape", "left", 9.5, 8, "b")
			hang(b, "shelf_wall", "mid", 4.4, 7.2, "b")
			hang(b, "coat_hooks", "back", 8.8, 7.6, "b")
			hang(b, "art_flowers", "mid", 1.6, 6, "b")
			for _, t in { 5.6, 13.4 } do
				hang(b, "curtains", "left", t, F + 2.2, "b", "F2E6CC", WALNUT)
			end
			b:item("bench_wood", 3.3, 11, 90)

			-- the bakehouse -------------------------------------------------------------------------
			-- the oven against the chimney wall, its mouth to the room; a table to knead on between
			-- it and the hatch; racks of loaves cooling along the back
			b:item("work_bakery", 25.7, 16, 270)
			paint(b, ROSE_BRICK, "8C8A90")
			b:item("kitchen_island", 21.4, 11.4, 0)
			b:item("bread_rack", 21.4, 22.8, 180)
			b:item("bread_rack", 25.6, 22.8, 180)
			b:item("crate", 26.5, 9.5, 0)
			b:item("crate", 26.5, 9.5, 8, 0, top("crate"))
			b:item("crate", 26.4, 20.6, 0)
			b:item("crate", 26.5, 20.5, 340, 0, top("crate"))
			b:item("crate", 24.2, 20.7, 10)
			b:item("light_ceiling", 22, 12, 0)
			b:item("light_ceiling", 22, 20, 0)
			hang(b, "shelf_wall", "bhright", 9, 8.4, "b")
			hang(b, "tool_board", "mid", 3.6, 6.4, "a")
			hang(b, "clock_wall", "bhback", 5, 9, "b")
			hang(b, "coat_hooks", "bhback", 8.6, 7.6, "b")
			hang(b, "sconce", "bhfront", 8.8, 6.2, "b")
		end
	)
end
