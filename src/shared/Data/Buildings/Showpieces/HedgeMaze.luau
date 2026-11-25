--!strict
-- A hedge maze: tall hedges on gravel paths round a paved courtyard with a fountain, two benches
-- and a pair of urns. The way in is at the front; the way to the middle goes right, up the side
-- past a kink and round the back, and the left hand way ends at a gnome.
--
-- The frame: x across, z back from the street. The hedges run on the lines x 2, 8, 14, 20, 26 and
-- z 6, 12, 18, 24, 30; the courtyard is x 8..20, z 12..24, its way in at x 8..14 on its back side.

local Lay = require(script.Parent.Kit.Lay)

type Finish = Lay.Finish

local HEDGE: Finish = { c = "6EAA62", m = "Grass" }
local GRAVEL: Finish = { c = "D8D0BE", m = "Pebble" }
local PAVING: Finish = { c = "EAE6DC", m = "Pavement" }

local OAK = "C49A6C"
local IRON = "2F3B35"
local CORAL = "E08566"
local LILAC = "9C86B8"

local put = Lay.put

local HEDGES = {
	-- the outside, open at the front between x 14 and 20
	{ 2, 6, 14, 6 },
	{ 20, 6, 26, 6 },
	{ 26, 6, 26, 30 },
	{ 26, 30, 2, 30 },
	{ 2, 30, 2, 6 },
	-- round the courtyard, open on its back side between x 8 and 14
	{ 8, 12, 20, 12 },
	{ 20, 12, 20, 24 },
	{ 20, 24, 14, 24 },
	{ 8, 24, 8, 12 },
	-- the left hand way's dead end, and a kink in the right hand way
	{ 2, 24, 8, 24 },
	{ 26, 18, 24, 18 },
}

return function(add: any)
	add(
		"show_hedge_maze",
		"Hedge maze",
		"Tall hedges round a little courtyard with a fountain, and one way in to find it.",
		"hedge",
		28,
		32,
		function(b: any)
			b:floor(2, 6, 26, 12, GRAVEL)
			b:floor(2, 24, 26, 30, GRAVEL)
			b:floor(2, 12, 8, 24, GRAVEL)
			b:floor(20, 12, 26, 24, GRAVEL)
			b:floor(8, 12, 20, 24, PAVING)
			for i, h in HEDGES do
				Lay.styled(b, "hedge" .. i, h[1], h[2], h[3], h[4], HEDGE, "hedge")
			end

			-- the courtyard
			put(b, "fountain", 14, 18, 0, Lay.F)
			put(b, "bench_garden", 10, 17.6, 90, Lay.F, OAK, IRON)
			put(b, "bench_garden", 18, 17.6, 270, Lay.F, OAK, IRON)
			put(b, "show_urn", 10.4, 21.7, 0, Lay.F, nil, CORAL)
			put(b, "show_urn", 17.6, 21.7, 0, Lay.F, nil, LILAC)
			put(b, "lamp_post", 11, 26.4, 0, Lay.F)

			-- the gnome at the end of the wrong way
			put(b, "gnome", 5, 21.6, 180, Lay.F)
			put(b, "flower_pot", 6.2, 22.4, 0, Lay.F, nil, CORAL)

			-- the way in
			for _, z in { 1, 3, 5 } do
				put(b, "path_stones", 17, z, 0)
			end
			put(b, "show_urn", 12, 3.6, 0, nil, nil, CORAL)
			put(b, "show_urn", 22, 3.6, 0, nil, nil, LILAC)
			put(b, "lamp_post", 9, 2, 0)
			put(b, "lamp_post", 25, 2, 0)
			put(b, "flower_border", 5, 3.6, 0)
		end
	)
end
