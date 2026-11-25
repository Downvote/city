--!strict
-- A bandstand: a raised wooden stage on a paved square, a ring of slim white posts with a rail
-- between them, open at the front where the steps come up, under a teal pyramid with a ceiling
-- and lamps. A piano, a drum kit and three chairs for the band; benches and lamps out front for
-- whoever comes to listen, urns by the steps and flowers down both sides.
--
-- The frame: x across, z back from the street. The stage is four decks over x 6..22, z 10..26;
-- the posts stand on the square x 8..20, z 12..24 inside its edge.

local Lay = require(script.Parent.Kit.Lay)

type Finish = Lay.Finish

local PAVING: Finish = { c = "E6DFD0", m = "Pavement" }
local CEILING: Finish = { c = "F7F3EA", m = "WoodPlanks" }
local TEAL: Finish = { c = "7FA39C", m = "RoofShingles" }

local WHITE = "F4F1EA"
local TEAL_PAINT = "5E8C86"
local OAK = "C49A6C"
local WALNUT = "9A6B48"
local CORAL = "E08566"
local LILAC = "9C86B8"

local put = Lay.put

return function(add: any)
	add(
		"show_bandstand",
		"Bandstand",
		"A raised stage under a teal roof, with a piano and drums, and benches out front.",
		"music",
		28,
		30,
		function(b: any)
			b:floor(2, 0, 26, 30, PAVING)
			-- the stage: four decks, steps up at the front
			local stage = Lay.F + 1
			for _, p in { { 10, 14 }, { 18, 14 }, { 10, 22 }, { 18, 22 } } do
				put(b, "deck_platform", p[1], p[2], 0, Lay.F, OAK, WALNUT)
			end
			put(b, "porch_steps", 14, 8.5, 180, Lay.F)
			-- the posts and the rail between them (the rail a hair up, so its own end posts
			-- inside the white ones don't share their feet)
			local posts = {
				{ 8, 12 },
				{ 12, 12 },
				{ 16, 12 },
				{ 20, 12 },
				{ 8, 16 },
				{ 8, 20 },
				{ 20, 16 },
				{ 20, 20 },
				{ 8, 24 },
				{ 12, 24 },
				{ 16, 24 },
				{ 20, 24 },
			}
			for _, p in posts do
				put(b, "pillar_square", p[1], p[2], 0, stage, WHITE, WHITE)
			end
			local rails = {
				{ 10, 12, 0 },
				{ 18, 12, 0 },
				{ 8, 14, 90 },
				{ 8, 18, 90 },
				{ 8, 22, 90 },
				{ 20, 14, 90 },
				{ 20, 18, 90 },
				{ 20, 22, 90 },
				{ 10, 24, 0 },
				{ 14, 24, 0 },
				{ 18, 24, 0 },
			}
			for _, r in rails do
				put(b, "porch_rail", r[1], r[2], r[3], stage + 0.05, WHITE, TEAL_PAINT)
			end
			-- the ceiling and the roof
			b:floor(6, 10, 22, 26, CEILING, 1)
			b:roof(6, 10, 22, 26, "pyramid", 9, 0, TEAL, PAVING, 0, 1.5)
			put(b, "weathervane", 14, 18, 0, nil, "D4AE5E", "2F3B35", 1)

			-- the band
			put(b, "piano", 11, 21.2, 90, stage, WALNUT, WHITE)
			put(b, "stool", 14, 21.2, 0, stage, WALNUT, TEAL_PAINT)
			put(b, "drum_kit", 17, 21.8, 180, stage)
			for _, p in { { 11.4, 15.6 }, { 14, 15 }, { 16.6, 15.6 } } do
				put(b, "chair_wood", p[1], p[2], 180, stage, OAK, TEAL_PAINT)
			end
			put(b, "lamp_pendant", 11, 18, 0, nil, TEAL_PAINT)
			put(b, "lamp_pendant", 17, 18, 0, nil, TEAL_PAINT)
			put(b, "flower_border", 10, 10.8, 0, stage)
			put(b, "flower_border", 18, 10.8, 0, stage)

			-- out front: urns by the steps, benches, lamps
			put(b, "show_urn", 10.2, 8.4, 0, Lay.F, nil, CORAL)
			put(b, "show_urn", 17.8, 8.4, 0, Lay.F, nil, LILAC)
			put(b, "bench_garden", 6, 4.2, 0, Lay.F, OAK, TEAL_PAINT)
			put(b, "bench_garden", 22, 4.2, 0, Lay.F, OAK, TEAL_PAINT)
			put(b, "lamp_post", 3.2, 9, 0, Lay.F)
			put(b, "lamp_post", 24.8, 9, 0, Lay.F)
			put(b, "lamp_post", 3.2, 27, 0, Lay.F)
			put(b, "lamp_post", 24.8, 27, 0, Lay.F)

			-- flowers down both sides, bushes behind
			for _, z in { 6, 11, 16, 21, 26 } do
				put(b, "flower_bed", 1, z, 90)
				put(b, "flower_bed", 27, z, 90)
			end
			put(b, "bush", 8, 28, 0, Lay.F)
			put(b, "bush", 14, 28.2, 0, Lay.F)
			put(b, "bush", 20, 28, 20, Lay.F)
		end
	)
end
