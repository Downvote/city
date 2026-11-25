--!strict
-- A clock tower: three storeys of brick and a cream top storey with a clock on every side, under
-- a tall slate spire with a weathervane. The room at its foot has a bench and a grandfather clock.
-- It stands on a paved square with benches, a lamp at each corner and flowers.
--
-- The frame: x across, z back from the street. The tower is x 6..14, z 8..16, all the way up.

local Lay = require(script.Parent.Kit.Lay)

type Finish = Lay.Finish

local BRICK: Finish = { c = "C98A72", m = "Brick" }
local CREAM: Finish = { c = "F2E6CC", m = "WoodPlanks" }
local INSIDE: Finish = { c = "F4E9D8", m = "WoodPlanks" }
local FLAGS: Finish = { c = "BDB8AE", m = "Cobblestone" }
local OAK_FLOOR: Finish = { c = "C49A6C", m = "WoodPlanks" }
local PAVING: Finish = { c = "E6DFD0", m = "Pavement" }
local SLATE: Finish = { c = "6E8CA8", m = "Slate" }

local STONE = "D6CCB8"
local NAVY = "46608E"
local WHITE = "FAF6EC"
local OAK = "C49A6C"
local WALNUT = "9A6B48"
local CORAL = "E08566"
local LILAC = "9C86B8"

local put, hang = Lay.put, Lay.hang

return function(add: any)
	add(
		"show_clocktower",
		"Clock tower",
		"A brick tower with a clock on all four sides and a slate spire, on a little square.",
		"clock",
		20,
		24,
		function(b: any)
			-- the square round it
			b:floor(0, 0, 20, 8, PAVING)
			b:floor(0, 16, 20, 24, PAVING)
			b:floor(0, 8, 6, 16, PAVING)
			b:floor(14, 8, 20, 16, PAVING)

			-- the tower: two storeys of brick, the clock storey, the spire
			b:floor(6, 8, 14, 16, FLAGS)
			b:box("", 6, 8, 14, 16, BRICK, INSIDE)
			b:floor(6, 8, 14, 16, OAK_FLOOR, 1)
			b:box("mid", 6, 8, 14, 16, BRICK, INSIDE, 1)
			b:floor(6, 8, 14, 16, OAK_FLOOR, 2)
			b:box("top", 6, 8, 14, 16, CREAM, INSIDE, 2)
			b:roof(6, 8, 14, 16, "pyramid", 9, 0, SLATE, CREAM, 2, 1)
			put(b, "weathervane", 10, 12, 0, nil, nil, nil, 3)
			local clockY = Lay.level(2) + 3.2
			put(b, "gable_clock", 10, 8, 180, clockY, WHITE, NAVY, 2)
			put(b, "gable_clock", 14, 12, 90, clockY, WHITE, NAVY, 2)
			put(b, "gable_clock", 10, 16, 0, clockY, WHITE, NAVY, 2)
			put(b, "gable_clock", 6, 12, 270, clockY, WHITE, NAVY, 2)

			-- doors and windows, with stone over them
			Lay.open(b, "door_front", "front", 4, NAVY, WHITE)
			b:open("win_tall", "left", 4)
			b:open("win_tall", "right", 4)
			for _, w in { "midfront", "midright", "midback", "midleft" } do
				b:open("win_tall", w, 4)
				hang(b, "window_hood", w, 4, 8.38, "a", STONE, STONE)
			end
			hang(b, "window_hood", "front", 4, 8.78, "a", STONE, STONE)
			hang(b, "lantern_wall", "front", 0.9, 5.6, "a")
			hang(b, "lantern_wall", "front", 7.1, 5.6, "a")
			Lay.footing(b, "front", 8, { { 1.6, 6.4 } }, STONE)
			Lay.footing(b, "left", 8, nil, STONE)
			Lay.footing(b, "right", 8, nil, STONE)
			Lay.footing(b, "back", 8, nil, STONE)
			for _, y in { 0, 11.9 } do
				Lay.corners(b, { { 6, 8, 180 }, { 14, 8, 90 }, { 14, 16, 0 }, { 6, 16, 270 } }, STONE, y)
			end

			-- the room at the foot of the tower
			b:item("doormat", 10, 9.2, 0)
			put(b, "clock_grandfather", 10, 15, 180, nil, WALNUT, "D4AE5E")
			put(b, "bench_wood", 7.3, 12.4, 90, nil, NAVY, OAK)
			put(b, "lamp_pendant", 10, 12, 0)
			hang(b, "art_landscape", "back", 4, 8.7, "b")

			-- the square: a bench each side, lamps at the corners, flowers at the back
			put(b, "flower_pot", 6.9, 7.0, 0, nil, nil, CORAL)
			put(b, "flower_pot", 13.1, 7.0, 0, nil, nil, LILAC)
			put(b, "bench_garden", 3.4, 12, 270, Lay.F, OAK, NAVY)
			put(b, "bench_garden", 16.6, 12, 90, Lay.F, OAK, NAVY)
			for _, p in { { 1.2, 1.2 }, { 18.8, 1.2 }, { 1.2, 22.8 }, { 18.8, 22.8 } } do
				put(b, "lamp_post", p[1], p[2], 0, Lay.F)
			end
			put(b, "postbox", 17.6, 4.4, 270, Lay.F)
			put(b, "bicycle", 3.0, 4.6, 20, Lay.F, NAVY, WALNUT)
			put(b, "flower_bed", 7, 18.4, 0, Lay.F)
			put(b, "flower_bed", 13, 18.4, 0, Lay.F)
			put(b, "show_urn", 3.6, 19.6, 0, Lay.F, nil, CORAL)
			put(b, "show_urn", 16.4, 19.6, 0, Lay.F, nil, LILAC)
			put(b, "bush", 10, 22.2, 0, Lay.F)
		end
	)
end
