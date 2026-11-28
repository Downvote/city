--!strict
-- A picnic shelter: a green shingle roof on six timber posts over a concrete pad with two picnic
-- tables and lanterns on them, a barbecue at its side with a water butt. Round it a ring of stones
-- for a fire with benches and a woodpile, an oak to sit under and a pine.
--
-- The frame: x across, z back from the street. The pad and the roof are x 6..22, z 6..16, the
-- ridge running across.

local Lay = require(script.Parent.Kit.Lay)

type Finish = Lay.Finish

local PAD: Finish = { c = "D6CCB8", m = "Concrete" }
local GREEN: Finish = { c = "6F8F5F", m = "RoofShingles" }
local TIMBER: Finish = { c = "B98E62", m = "WoodPlanks" }

local OAK = "C49A6C"
local WALNUT = "9A6B48"
local SAGE = "6F8F6A"

local put = Lay.put

return function(add: any)
	add(
		"show_picnic_shelter",
		"Picnic shelter",
		"A timber roof over two picnic tables and a barbecue, with a fire ring and benches nearby.",
		"table",
		28,
		24,
		function(b: any)
			b:floor(6, 6, 22, 16, PAD)
			b:roof(6, 6, 22, 16, "gable", 5, 0, GREEN, TIMBER, 0, 1.2)
			for _, z in { 6.6, 15.4 } do
				for _, x in { 7, 14, 21 } do
					put(b, "porch_post", x, z, 0, nil, WALNUT, WALNUT)
				end
			end

			-- under the roof: the tables, lanterns on them, the barbecue at the end
			for _, x in { 10.5, 17.5 } do
				put(b, "picnic_table", x, 11, 0, Lay.F, OAK, WALNUT)
				put(b, "lantern", x + 0.6, 11.2, 0, Lay.F + 2.8)
			end
			put(b, "bbq", 24.4, 11, 270)
			put(b, "path_stones", 14, 1, 0)
			put(b, "path_stones", 14, 3, 0)
			put(b, "path_stones", 14, 5, 0)

			-- the fire ring with benches round it and the woodpile
			put(b, "campfire", 22.4, 20.4, 0)
			put(b, "bench_garden", 17.6, 20.4, 90, nil, OAK, SAGE)
			put(b, "bench_garden", 25.6, 20.6, 270, nil, OAK, SAGE)
			put(b, "woodpile", 22.4, 23, 0, nil, WALNUT, WALNUT)

			-- an oak to sit under and a pine, a lamp by the path, flowers and a bush at the back
			put(b, "tree_oak", 4.4, 4.4, 0)
			put(b, "tree_pine", 25, 3, 0)
			put(b, "lamp_post", 11.6, 2, 0)
			put(b, "flower_bed", 10, 17.8, 0)
			put(b, "bush", 2.4, 20, 0)
			put(b, "rock", 6.6, 21, 50)
			-- by the barbecue a water butt and a crate of logs, a lantern by the path and a gnome
			-- watching the fire
			put(b, "water_butt", 24.6, 7, 0, nil, SAGE, WALNUT)
			put(b, "crate", 26.6, 14.2, 10, nil, OAK, OAK)
			put(b, "lantern_garden", 16.4, 1.6, 0)
			put(b, "gnome", 6.6, 18, 120)
		end
	)
end
