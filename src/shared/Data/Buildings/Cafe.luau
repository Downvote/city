--!strict
-- The café, where the barista works. One storey of mint boards under a wide hip roof of clay
-- tiles. The roof runs on over the front corner, which is left open as a covered terrace on
-- posts, and the door sits in a short wall across the inside corner, facing the terrace. Inside
-- are booths by the window, little round tables, the coffee counter at the back with a case of
-- cakes beside it, and a table for two in the bay window.
--
-- The frame: x across, z back from the street (z = 0). The café is x 2..28 and z 6..26 under one
-- roof; the terrace is its corner x 16..28, z 6..14, cut off from the room by the wall with the
-- door from (16, 10) to (20, 14).

local Catalog = require(script.Parent.Parent.Parent.Build.Catalog)
local Tuning = require(script.Parent.Parent.Parent.Config.Tuning)

type Finish = { c: string, m: string }

local F = Tuning.Plot.Foundation

-- finishes: mint boards, a warm cream inside, clay tiles over all of it
local MINT: Finish = { c = "CFE2D0", m = "WoodPlanks" }
local INSIDE: Finish = { c = "F4E9D8", m = "Plaster" }
local CLAY: Finish = { c = "C27E63", m = "ClayRoofTiles" }
local TILES: Finish = { c = "E8DDCB", m = "CeramicTiles" }
local OAK: Finish = { c = "C49A6C", m = "WoodPlanks" }
local TERRACOTTA: Finish = { c = "C9957A", m = "CeramicTiles" }
local PAVING: Finish = { c = "EAE6DC", m = "Pavement" }

-- paint for the pieces
local TRIM = "FAF6EC"
local TEAL = "3F8C86"
local WALNUT = "9A6B48"
local CORAL = "E08566"
local STONE = "BDB8AE"
local BUTTER = "F3DFA6"

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
				hang(b, "stone_footing", wall, t, 0, "a", STONE)
				t += 4
			end
			hang(b, "stone_footing", wall, e - 2, 0, "a", STONE)
		end
	end
end

return function(add: any)
	add(
		"cafe",
		"Café",
		"Coffee at the counter, booths by the window and tables out on the covered terrace.",
		"pot",
		30,
		28,
		function(b: any)
			-- the floors: tiles in the café, boards in the lounge, terracotta on the terrace
			b:floor(2, 6, 16, 26, TILES)
			b:floor(16, 14, 28, 26, OAK)
			b:floor(16, 6, 28, 14, TERRACOTTA)
			b:floor(16, 0, 28, 6, PAVING)

			-- the walls, clockwise from the front left corner; "corner" is the short one with the door
			b:wall("front", 2, 6, 16, 6, MINT, INSIDE)
			b:wall("terside", 16, 6, 16, 10, MINT, INSIDE)
			b:wall("corner", 16, 10, 20, 14, MINT, INSIDE)
			b:wall("terback", 20, 14, 28, 14, MINT, INSIDE)
			b:wall("right", 28, 14, 28, 26, MINT, INSIDE)
			b:wall("back", 28, 26, 2, 26, MINT, INSIDE)
			b:wall("left", 2, 26, 2, 6, MINT, INSIDE)
			b:roof(2, 6, 28, 26, "hip", 7, 0, CLAY, MINT, 0, 1.2)

			-- doors and windows
			b:open("door_glass", "corner", 2.83)
			paint(b, TEAL, TEAL)
			b:open("win_wide", "front", 3.6)
			b:open("win_wide", "front", 10.4)
			b:open("win_square", "left", 6)
			b:open("win_square", "left", 14)
			b:open("win_bay", "right", 4)
			paint(b, TRIM, CLAY.c)
			b:open("win_square", "terback", 5.4)
			b:open("win_wide", "back", 19)
			b:open("door_wood", "back", 9.6)
			paint(b, TEAL, TRIM)
			b:open("win_small", "back", 3.4)

			-- outside -----------------------------------------------------------------------------
			-- the café's sign over the door, awnings over the front windows, hoods over the others,
			-- flowers under all of them
			hang(b, "sign_cafe", "corner", 2.83, 8.8, "a", "F2E6CC", TEAL)
			for _, t in { 3.6, 10.4 } do
				hang(b, "awning", "front", t, 7.6, "a", TEAL, TRIM)
				hang(b, "window_box", "front", t, F + 1.65, "a", WALNUT, CORAL)
			end
			for _, w in { { w = "left", t = 6 }, { w = "left", t = 14 }, { w = "terback", t = 5.4 } } do
				hang(b, "window_hood", w.w, w.t, F + 7.38, "a", TRIM, CLAY.c)
				hang(b, "window_box", w.w, w.t, F + 1.65, "a", WALNUT, "9C86B8")
			end
			hang(b, "window_hood", "back", 3.4, F + 7.38, "a", TRIM, CLAY.c)
			footing(b, "front", 14)
			footing(b, "left", 20)
			footing(b, "right", 12, { { 0.8, 7.2 } })
			footing(b, "back", 26, { { 7.4, 11.8 } })
			footing(b, "terback", 8)
			footing(b, "terside", 4)
			for _, c in { { 2, 6, 180 }, { 16, 6, 90 }, { 28, 14, 90 }, { 28, 26, 0 }, { 2, 26, 270 } } do
				b:item("corner_board", c[1], c[2], c[3], 0, 0)
				paint(b, TRIM, TRIM)
			end
			hang(b, "downpipe", "right", 11.5, 0, "a")
			hang(b, "downpipe", "left", 0.5, 0, "a")
			hang(b, "downpipe", "left", 19.5, 0, "a")
			hang(b, "trellis", "left", 10, 1.3, "a")

			-- the terrace: posts at the corner and along the front, rails between them, two tables,
			-- lights strung along the wall and a lantern by the door
			b:item("porch_post", 27.3, 6.6, 0)
			paint(b, TRIM, TRIM)
			b:item("porch_post", 22.4, 6.6, 0)
			paint(b, TRIM, TRIM)
			b:item("porch_post", 27.3, 10.4, 90)
			paint(b, TRIM, TRIM)
			b:item("porch_rail", 24.85, 6.6, 0)
			paint(b, TRIM, TEAL)
			b:item("porch_rail", 27.3, 8.5, 90)
			paint(b, TRIM, TEAL)
			b:item("porch_rail", 27.3, 12.1, 90)
			paint(b, TRIM, TEAL)
			b:item("table_round", 24.2, 10.4, 0)
			b:item("chair_wood", 22, 10.4, 90)
			b:item("chair_wood", 24.2, 12.6, 180)
			b:item("chair_wood", 26.2, 10.4, 270)
			b:item("vase_flowers", 24.2, 10.4, 0, 0, top("table_round"))
			b:item("flower_pot", 26.6, 7.6, 0)
			b:item("flower_pot", 16.9, 6.9, 0)
			hang(b, "string_lights", "terback", 4, 10.3, "a")
			hang(b, "lantern_wall", "terside", 2, 5.6, "a")
			b:item("doormat", 18.9, 10.9, 315)

			-- out front: the board on the pavement, a lamp, a bench in the garden under the
			-- windows, flowers along the street
			b:item("menu_board", 19.4, 3.4, 200)
			b:item("planter_box", 26, 1, 0, 0, F)
			b:item("lamp_post", 16.9, 1.1, 0, 0, F)
			b:item("bench_garden", 9, 3.2, 180)
			b:item("lamp_post", 1.2, 1.2, 0)
			for _, x in { 4, 14 } do
				b:item("flower_border", x, 0.9, 0)
			end
			b:item("bush", 1.5, 4.4, 0)
			b:item("bicycle", 29, 18, 0)
			b:item("path_stones", 18.4, 27, 0)

			-- the café ----------------------------------------------------------------------------
			-- the counter across the back, the barista's things on the wall behind, the cakes
			b:item("work_cafe", 9, 21.6, 180)
			paint(b, WALNUT, TRIM)
			b:item("fridge", 3.8, 24.4, 180)
			b:item("counter_sink", 14.6, 24.4, 180)
			b:item("kettle", 14.9, 24.6, 180, 0, top("counter_sink"))
			b:item("display_case", 18.4, 21.8, 180)
			b:item("plant_small", 13.6, 24.6, 0, 0, top("counter_sink"))
			hang(b, "shelf_wall", "back", 14.6, 7.8, "b")
			hang(b, "shelf_wall", "back", 23.4, 7.8, "b")
			hang(b, "clock_wall", "back", 19, 9.2, "b")
			hang(b, "coat_hooks", "terside", 2, 5.8, "b")
			-- a booth bay in the front corner
			b:item("booth_seat", 4.6, 7.5, 0)
			paint(b, TEAL, TRIM)
			b:item("table_round", 4.6, 10.5, 0)
			paint(b, TRIM, WALNUT)
			b:item("booth_seat", 4.6, 13.5, 180)
			paint(b, TEAL, TRIM)
			b:item("vase_flowers", 4.6, 10.5, 0, 0, top("table_round"))
			-- little round tables down the middle
			for _, z in { 9.4, 15.2 } do
				b:item("table_round", 12, z, 0)
				paint(b, TRIM, WALNUT)
				b:item("chair_wood", 9.8, z, 90)
				b:item("chair_wood", 14.2, z, 270)
				b:item("lamp_pendant", 12, z, 0)
			end
			b:item("lamp_pendant", 4.6, 10.5, 0)
			b:item("light_ceiling", 9, 21, 0)
			b:item("plant_big", 3.9, 17.4, 0)
			hang(b, "sconce", "left", 19.8, 6.2, "b")
			hang(b, "art_landscape", "left", 10.4, 7, "b")
			hang(b, "art_flowers", "front", 7, 8.6, "b")
			hang(b, "string_lights", "front", 7, 10.4, "b")
			-- the lounge round the corner: a table for two in the bay, a sofa, a rug, a lamp
			b:item("doormat", 17.4, 12.6, 315)
			b:item("table_round", 24.9, 18, 0)
			paint(b, TRIM, WALNUT)
			b:item("chair_dining", 22.7, 18, 90)
			b:item("chair_dining", 24.9, 15.8, 0)
			b:item("lamp_pendant", 24.9, 18, 0)
			b:item("rug_round", 23.6, 22.4, 0)
			b:item("sofa_two", 23.6, 24.1, 180)
			paint(b, BUTTER, WALNUT)
			b:item("table_coffee", 23.6, 21.6, 0)
			b:item("books_stack", 23, 21.6, 30, 0, top("table_coffee"))
			b:item("lamp_floor", 27, 24.7, 0)
			b:item("light_ceiling", 22, 20, 0)
			hang(b, "art_abstract", "right", 9.6, 6.6, "b")
			hang(b, "curtains", "terback", 5.4, F + 2.2, "b", TEAL, WALNUT)
		end
	)
end
