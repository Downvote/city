--!strict
-- Beach huts: three little boarded huts in a row on the sand, sky blue, rose and mint, each with
-- its gable to the sea, bunting over the door and a deck in front with a deck chair. Sun
-- umbrellas stand on the sand before them, a rack of surfboards leans on the middle deck, and a
-- ring of stones for a fire waits behind.
--
-- The frame: x across, z back from the street (the sea, as it's drawn). The huts are 8 wide on
-- x 2, 12 and 22, from z 10 to 18, their decks z 6..10; sand fills everything round them.

local Lay = require(script.Parent.Kit.Lay)

type Finish = Lay.Finish

local SAND: Finish = { c = "EADBC0", m = "Sand" }
local DECK: Finish = { c = "C49A6C", m = "WoodPlanks" }
local INSIDE: Finish = { c = "F2E6CC", m = "WoodPlanks" }

local WHITE = "FAF6EC"
local OAK = "C49A6C"
local WALNUT = "9A6B48"

-- each hut: its left edge, walls, roof, door, umbrella
local HUTS = {
	{ x = 2, walls = "CCDDEA", roof = "8CA0B4", door = "5E8CB0", shade = "E8A0B4" },
	{ x = 12, walls = "EBC8C2", roof = "C98466", door = "C9786A", shade = "8FC3D8" },
	{ x = 22, walls = "CFE2D0", roof = "8FA58A", door = "5E8C86", shade = "F3DFA6" },
}

local put, hang = Lay.put, Lay.hang

return function(add: any)
	add(
		"show_beach_huts",
		"Beach huts",
		"Three painted huts on the sand with decks, deck chairs and sun umbrellas.",
		"sun",
		32,
		22,
		function(b: any)
			-- the sand round the huts
			b:floor(0, 0, 32, 6, SAND)
			for _, x in { 0, 10, 20, 30 } do
				b:floor(x, 6, x + 2, 22, SAND)
			end
			for _, h in HUTS do
				b:floor(h.x, 18, h.x + 8, 22, SAND)
			end

			for i, h in HUTS do
				local x0 = h.x
				local n = "hut" .. i
				local boards: Finish = { c = h.walls, m = "WoodPlanks" }
				b:floor(x0, 6, x0 + 8, 18, DECK)
				b:box(n, x0, 10, x0 + 8, 18, boards, INSIDE)
				b:roof(x0, 10, x0 + 8, 18, "gable", 4, 1, { c = h.roof, m = "RoofShingles" }, boards, 0, 0.4)
				Lay.open(b, "door_panel", n .. "front", 4, h.door, WHITE)
				b:open("win_small", n .. "left", 4)
				b:open("win_small", n .. "right", 4)
				hang(b, "bunting", n .. "front", 4, 9.4, "a")
				Lay.corners(b, { { x0, 10, 180 }, { x0 + 8, 10, 90 }, { x0 + 8, 18, 0 }, { x0, 18, 270 } }, WHITE)
				-- the deck and the sand in front
				put(b, "beach_chair", x0 + 2, 8, 200, Lay.F, h.door, WHITE)
				put(b, "umbrella_sun", x0 + 4, 3, 0, Lay.F, h.shade, WHITE)
				b:item("doormat", x0 + 4, 11.2, 0)
			end
			put(b, "show_surfboards", 17.6, 8, 180, Lay.F)

			-- inside: somewhere to sit and change in each
			put(b, "bench_wood", 6, 16.8, 180, nil, WHITE, OAK)
			hang(b, "coat_hooks", "hut1back", 4, 5.4, "b")
			put(b, "towel_rail", 9.2, 13.6, 270)
			put(b, "stool", 14, 16.4, 0, nil, OAK, WHITE)
			put(b, "table_side", 18, 16.6, 0, nil, WHITE, OAK)
			put(b, "lantern", 18, 16.6, 0, Lay.top("table_side"))
			hang(b, "shelf_wall", "hut2back", 4, 7.4, "b", OAK)
			put(b, "chair_rocking", 26, 15.6, 0, nil, WHITE, OAK)
			hang(b, "art_landscape", "hut3back", 4, 6.8, "b")

			-- the fire ring at the back, and stones on the sand
			put(b, "campfire", 16, 20.2, 0, Lay.F)
			put(b, "woodpile", 11, 20.2, 90, Lay.F, WALNUT, WALNUT)
			put(b, "rock", 2.2, 2.2, 40, Lay.F)
			put(b, "rock", 30, 20, 110, Lay.F)
			put(b, "bush", 30.4, 3, 0, Lay.F, "B8C27A")
		end
	)
end
