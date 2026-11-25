--!strict
-- The grocer's, where the shopkeeper works. Two storeys on a wide front: brick below, cream
-- plaster above with green shutters, and the upper floor carried out over an arcade where the
-- market stall stands half in the shade, the shop window behind it. Inside are shelves of tins
-- and jars, crates of fruit and a till by the door; up the stairs a sitting room looks over the
-- street and a stock room fills the back.
--
-- The frame: x across, z back from the street (z = 0). The shop is x 2..26 and z 12..26, the
-- arcade in front of it z 6..12 under the upper floor (x 2..26, z 6..26), the forecourt z 0..6.

local Catalog = require(script.Parent.Parent.Parent.Build.Catalog)
local Tuning = require(script.Parent.Parent.Parent.Config.Tuning)

type Finish = { c: string, m: string }

local F = Tuning.Plot.Foundation
local UP = F + Tuning.Plot.LevelHeight -- the upstairs floor

-- finishes: soft brick and cream plaster under a moss roof, green for the woodwork
local BRICK: Finish = { c = "D69A82", m = "Brick" }
local CREAM: Finish = { c = "F2E6CC", m = "Plaster" }
local SHOP_IN: Finish = { c = "DDE6D3", m = "Plaster" }
local ROOM_IN: Finish = { c = "F5EBD6", m = "Plaster" } -- (a shade apart from the cream outside)
local STOCK_IN: Finish = { c = "E6D5B4", m = "WoodPlanks" }
local RAIL: Finish = { c = "9A6B48", m = "Wood" }
local MOSS: Finish = { c = "6F8F5F", m = "RoofShingles" }
local PAVING: Finish = { c = "EAE6DC", m = "Pavement" }
local FLAGS: Finish = { c = "D8CFC0", m = "Cobblestone" }
local BOARDS: Finish = { c = "DDBE94", m = "WoodPlanks" }
local OAK: Finish = { c = "C49A6C", m = "WoodPlanks" }

-- paint for the pieces
local TRIM = "FAF6EC"
local FOREST = "4E7F62"
local FOREST_DARK = "3B6350"
local WALNUT = "9A6B48"
local CORAL = "E08566"
local STONE = "BDB8AE"
local SAGE = "B9CBAE"

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

-- The top of a piece standing on a floor, for what stands on it.
local function top(id: string, lv: number?): number
	local def = Catalog.get(id)
	return (if lv == 1 then UP else F) + (if def and def.surface then def.surface else 0)
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
				hang(b, "stone_footing", wall, t, 0, "a", STONE)
				t += 4
			end
			hang(b, "stone_footing", wall, e - 2, 0, "a", STONE)
		end
	end
end

return function(add: any)
	add(
		"market",
		"Grocer's",
		"A grocer's with fruit and veg out under the arcade, and rooms upstairs.",
		"cart",
		28,
		28,
		function(b: any)
			-- the ground floor ------------------------------------------------------------------
			b:floor(0, 0, 28, 6, PAVING)
			b:floor(2, 6, 26, 12, FLAGS)
			b:floor(2, 12, 26, 26, BOARDS)
			b:wall("front", 2, 12, 26, 12, BRICK, SHOP_IN)
			b:wall("right", 26, 12, 26, 26, BRICK, SHOP_IN)
			b:wall("back", 26, 26, 2, 26, BRICK, SHOP_IN)
			b:wall("left", 2, 26, 2, 12, BRICK, SHOP_IN)
			-- the arcade's two ends
			b:wall("arcright", 26, 6, 26, 12, BRICK, BRICK)
			b:wall("arcleft", 2, 12, 2, 6, BRICK, BRICK)

			-- upstairs: a sitting room over the arcade, the stock room behind, the stairwell
			-- fenced off along the back
			b:floor(2, 6, 26, 16, OAK, 1)
			b:floor(2, 16, 26, 26, BOARDS, 1)
			b:box("up", 2, 6, 26, 26, CREAM, ROOM_IN, 1)
			b:wall("upmid", 2, 16, 26, 16, ROOM_IN, STOCK_IN, 1)
			b:wall("rail", 6, 22, 20, 22, RAIL, RAIL, 1)
			b.walls.rail.style = "railing"
			b:wall("railend", 20, 22, 20, 26, RAIL, RAIL, 1)
			b.walls.railend.style = "railing"
			b:roof(2, 6, 26, 26, "gable", 8, 0, MOSS, CREAM, 1, 1.2)

			-- doors and windows
			b:open("win_picture", "front", 6.6)
			paint(b, FOREST, FOREST)
			b:open("door_double", "front", 18.2)
			paint(b, FOREST, TRIM)
			b:open("arch_open", "arcleft", 3)
			b:open("win_square", "left", 11)
			b:open("win_square", "right", 3)
			b:open("win_small", "back", 3)
			b:open("win_small", "back", 21)
			b:open("win_square", "upfront", 4)
			b:open("win_square", "upfront", 20)
			b:open("win_square", "upright", 5)
			b:open("win_square", "upright", 15)
			b:open("win_square", "upback", 3.4) -- (its frame clear of the railing's end post)
			b:open("win_square", "upback", 16)
			b:open("win_square", "upleft", 5)
			b:open("win_square", "upleft", 15)
			b:open("door_wood", "upmid", 3)
			paint(b, OAK.c, TRIM)

			-- outside -----------------------------------------------------------------------------
			-- every upstairs window in green shutters over a box of flowers, awnings on the shop's
			-- side windows, the grocer's sign between the two front windows
			for _, w in
				{
					{ w = "upfront", t = 4 },
					{ w = "upfront", t = 20 },
					{ w = "upright", t = 5 },
					{ w = "upright", t = 15 },
				}
			do
				hang(b, "shutters", w.w, w.t, 2.85, "a", FOREST, FOREST_DARK)
				hang(b, "window_box", w.w, w.t, 1.65, "a", WALNUT, CORAL)
			end
			for _, w in
				{
					{ w = "upleft", t = 5 },
					{ w = "upleft", t = 15 },
					{ w = "upback", t = 3.4 },
					{ w = "upback", t = 16 },
				}
			do
				hang(b, "shutters", w.w, w.t, 2.85, "a", FOREST, FOREST_DARK)
				hang(b, "window_box", w.w, w.t, 1.65, "a", WALNUT, "9C86B8")
			end
			for _, w in { { w = "left", t = 11 }, { w = "right", t = 3 } } do
				hang(b, "awning", w.w, w.t, 7.6, "a", FOREST, TRIM)
				hang(b, "window_box", w.w, w.t, F + 1.65, "a", WALNUT, CORAL)
			end
			-- the brick stands on a stone course; boards up the plaster's corners; four drainpipes
			footing(b, "front", 24, { { 15, 21.4 } })
			footing(b, "left", 14)
			footing(b, "right", 14)
			footing(b, "back", 24)
			for _, c in { { 2, 6, 180 }, { 26, 6, 90 }, { 26, 26, 0 }, { 2, 26, 270 } } do
				b:item("corner_board", c[1], c[2], c[3], 1)
				paint(b, TRIM, TRIM)
			end
			hang(b, "downpipe", "right", 13.4, 0, "a")
			hang(b, "downpipe", "upright", 19.4, 0, "a")
			hang(b, "downpipe", "left", 0.6, 0, "a")
			hang(b, "downpipe", "upleft", 0.6, 0, "a")
			-- roses up the bare brick at the back of each side
			hang(b, "trellis", "left", 4.6, 1.3, "a")
			hang(b, "trellis", "right", 9.6, 1.3, "a")

			-- the arcade: the stall half out in the light, one green post in the middle, a bench
			-- at the end, lights strung along the shop front
			b:item("work_market", 8.6, 7.2, 180)
			paint(b, FOREST, TRIM)
			b:item("porch_post", 15.6, 6.45, 0, 0, F - 0.04) -- (its top just under the floor above)
			paint(b, FOREST, TRIM)
			b:item("bench_garden", 24.7, 9.2, 270, 0, F)
			hang(b, "lantern_wall", "arcright", 3, 6.2, "b")
			hang(b, "string_lights", "front", 12, 10.5, "a")
			hang(b, "lantern_wall", "front", 14.2, 5.6, "a")
			hang(b, "lantern_wall", "front", 22.2, 5.6, "a")
			hang(b, "hanging_basket", "front", 1, 7.4, "a")
			b:item("doormat", 20.2, 11, 0)
			b:item("crate", 25, 7.6, 0)
			b:item("crate", 24.9, 7.5, 15, 0, top("crate"))

			-- the forecourt: a second stand of fruit by the door, the pavement board, a lamp, a
			-- bicycle against the arcade, planters along the kerb
			b:item("produce_stand", 25.4, 3.2, 180)
			b:item("menu_board", 16.6, 2.4, 165)
			b:item("lamp_post", 1.2, 3.4, 0, 0, F)
			b:item("bicycle", 13.6, 3.6, 12, 0, F)
			b:item("planter_box", 4.4, 0.9, 0, 0, F)
			b:item("flower_pot", 13.2, 0.9, 0)
			-- the sides, on the grass
			for _, z in { 15, 21 } do
				b:item("flower_border", 1, z, 90)
				b:item("flower_border", 27, z, 270)
			end

			-- the shop ----------------------------------------------------------------------------
			-- by the door: the till on two counters, the bread on a rack
			b:item("doormat", 20.2, 13.4, 0)
			b:item("counter", 24.3, 14.25, 270)
			b:item("counter", 24.3, 17.2, 270)
			b:item("books_stack", 24.3, 13.65, 80, 0, top("counter"))
			b:item("plant_small", 24.5, 18.1, 0, 0, top("counter"))
			b:item("lantern", 24.2, 16.4, 0, 0, top("counter"))
			b:item("bread_rack", 15.2, 13.2, 0)
			b:item("coat_stand", 2.3 + 1.1, 13.6, 0)
			-- shelves along both side walls, a pantry and an aisle down the middle
			b:item("shop_shelves", 3.1, 19.2, 90)
			b:item("shop_shelves", 3.1, 23.4, 90)
			b:item("shop_shelves", 24.9, 20.6, 270)
			b:item("pantry", 24.5, 24.26, 270)
			b:item("shop_shelves", 17, 16.6, 180)
			b:item("shop_shelves", 17, 18.2, 0)
			-- crates of fruit and veg in the window, back to back
			b:item("produce_stand", 9.6, 15.8, 180)
			b:item("produce_stand", 9.6, 18.8, 0)
			-- the stairs up along the back wall, and under their high end more crates
			b:item("stairs_straight", 13.5, 23.61, 90)
			paint(b, OAK.c, TRIM)
			b:item("crate", 8.2, 24.4, 0)
			b:item("crate", 10.6, 24.5, 10)
			b:item("crate", 8.3, 24.3, 348, 0, top("crate"))
			for _, p in { { 6, 15.6 }, { 14, 15.2 }, { 21.4, 16 }, { 13, 20.4 } } do
				b:item("light_ceiling", p[1], p[2])
			end
			hang(b, "clock_wall", "front", 6.6, 9, "b")
			hang(b, "art_landscape", "left", 4.6, 8.4, "b")
			hang(b, "shelf_wall", "right", 9.8, 8.2, "b")

			-- upstairs: the sitting room over the street -----------------------------------------
			b:item("rug_long", 14, 10.8, 90, 1)
			b:item("sofa_two", 14, 14, 180, 1)
			paint(b, SAGE, WALNUT)
			b:item("table_coffee", 14, 10.8, 0, 1)
			b:item("vase_flowers", 14.6, 10.8, 0, 1, top("table_coffee", 1))
			b:item("armchair", 9.4, 10.6, 90, 1)
			b:item("armchair", 18.6, 10.6, 270, 1)
			b:item("lamp_floor", 10.2, 14.6, 0, 1)
			b:item("bookshelf", 24.8, 12.4, 270, 1)
			b:item("plant_big", 6, 7.9, 0, 1)
			b:item("cabinet", 3.3, 11, 90, 1)
			b:item("kettle", 3.3, 12.2, 90, 1, top("cabinet", 1))
			b:item("plant_small", 3.3, 9.8, 0, 1, top("cabinet", 1))
			-- the shopkeeper's desk under the window, for the accounts
			b:item("desk", 22, 7.8, 0, 1)
			b:item("chair_wood", 22, 9.9, 180, 1)
			b:item("lamp_desk", 23.6, 7.85, 200, 1, top("desk", 1))
			b:item("books_stack", 20.8, 7.5, 0, 1, top("desk", 1))
			b:item("coat_stand", 8.4, 14.8, 0, 1)
			b:item("light_ceiling", 8, 11, 0, 1)
			b:item("light_ceiling", 19, 11, 0, 1)
			hang(b, "curtains", "upfront", 4, 1.8, "b", SAGE, WALNUT)
			hang(b, "curtains", "upfront", 20, 1.8, "b", SAGE, WALNUT)
			hang(b, "art_flowers", "upmid", 12, 5.6, "a")
			hang(b, "clock_wall", "upmid", 19, 7.6, "a")
			hang(b, "mirror_wall", "upleft", 10, 4.2, "b")

			-- the stock room behind it
			b:item("shop_shelves", 11, 17.1, 0, 1)
			b:item("shop_shelves", 15.2, 17.1, 0, 1)
			b:item("cabinet", 24.65, 18.8, 270, 1)
			b:item("crate", 22.2, 24.4, 0, 1)
			b:item("crate", 24.5, 24.5, 20, 1)
			b:item("crate", 22.3, 24.3, 350, 1, UP + 2)
			b:item("crate", 24.6, 21.6, 5, 1)
			b:item("stool", 19.6, 18.8, 0, 1)
			b:item("light_ceiling", 13, 19.4, 0, 1)
			b:item("light_ceiling", 23, 21.4, 0, 1)
			hang(b, "coat_hooks", "upmid", 19, 5.2, "b")
			hang(b, "shelf_wall", "upback", 2.3, 6.9, "b")

			-- opened up: the shop wider at both ends and deeper behind the aisle, the stock room
			-- deeper over it (the stairs and their railing keep together)
			b:spread({ x = { { 4.6, 4 }, { 20.7, 6 } }, z = { { 20, 6 } } })
			-- the sign between the two front windows, a window up in each gable, and shelves
			-- along the walls the shop gained
			hang(b, "sign_grocer", "upfront", 19, 3.3, "a", "F2E6CC", FOREST)
			for _, x in { 2, 36 } do
				b:item("window_attic", x, 19, if x < 19 then 270 else 90, 2)
				paint(b, TRIM, FOREST)
			end
			b:item("shop_shelves", 3.1, 24.3, 90)
			b:item("shop_shelves", 34.9, 21.4, 270)
			b:item("crate", 30.6, 24.6, 0)
			b:item("crate", 30.5, 24.5, 12, 0, top("crate"))
		end
	)
end
