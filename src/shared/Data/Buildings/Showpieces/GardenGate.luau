--!strict
-- A garden gate: a stone archway with ivy over it in a low stone wall, an urn on each end of the
-- wall and flowers along its foot, lamps either side of the cobbles in front. Through the arch a
-- path goes on into a garden with an oak, a blossom tree and a bench.
--
-- The frame: x across, z back from the street. The wall runs across on z 6 with the arch in the
-- middle (x 10..20); the cobbles are x 8..22 in front of it and the path x 12..18 behind.

local Lay = require(script.Parent.Kit.Lay)

type Finish = Lay.Finish

local COBBLES: Finish = { c = "C8C0B0", m = "Cobblestone" }
local PATH: Finish = { c = "D9C7A7", m = "Pavement" }
local STONE: Finish = { c = "D6CCB8", m = "Cobblestone" }

local OAK = "C49A6C"
local IRON = "2F3B35"
local CORAL = "E08566"
local LILAC = "9C86B8"

local put = Lay.put

return function(add: any)
	add(
		"show_garden_gate",
		"Garden gate",
		"A stone archway with ivy in a low wall, and a garden with a bench behind it.",
		"path",
		30,
		16,
		function(b: any)
			b:floor(8, 0, 22, 8, COBBLES)
			b:floor(12, 8, 18, 16, PATH)
			-- the arch (its ivy to the street) and the wall either side of it
			put(b, "show_arch", 15, 6, 180, Lay.F)
			Lay.styled(b, "wallleft", 0, 6, 10, 6, STONE, "stone")
			Lay.styled(b, "wallright", 20, 6, 30, 6, STONE, "stone")
			put(b, "show_urn", 1.3, 6, 0, 3, nil, CORAL)
			put(b, "show_urn", 28.7, 6, 0, 3, nil, LILAC)

			-- in front: flowers along the wall and a lamp each side of the cobbles
			for _, x in { 2, 6, 24, 28 } do
				put(b, "flower_border", x, 4.4, 0)
			end
			put(b, "lamp_post", 9.2, 1.6, 0, Lay.F)
			put(b, "lamp_post", 20.8, 1.6, 0, Lay.F)

			-- behind: the garden
			put(b, "tree_oak", 4.5, 12, 0)
			put(b, "tree_blossom", 25.5, 12, 0)
			put(b, "bush", 9.6, 9.2, 0)
			put(b, "bush", 19.6, 14.2, 0)
			put(b, "bench_garden", 22.4, 11, 270, nil, OAK, IRON)
			put(b, "flower_bed", 10, 14, 90)
			put(b, "bird_house", 8.4, 15, 20)
		end
	)
end
