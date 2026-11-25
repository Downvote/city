--!strict
-- A pergola walk: a brick path under two long pergolas hung with roses, flowers all along both
-- sides, and half way a paved square with a sundial between two benches and a lamp in each
-- corner. A last bench waits at the far end.
--
-- The frame: x across, z back from the street; the walk runs straight back up the middle (x 8).
-- The path is x 4..12; the square at its middle is x 0..16, z 18..26.

local Lay = require(script.Parent.Kit.Lay)

type Finish = Lay.Finish

local BRICK_PATH: Finish = { c = "C88A6E", m = "Brick" }
local PAVING: Finish = { c = "EAE6DC", m = "Pavement" }

local WHITE = "F4F1EA"
local ROSE = "E8A0B4"
local OAK = "C49A6C"
local IRON = "2F3B35"

local put = Lay.put

return function(add: any)
	add(
		"show_pergola_walk",
		"Pergola walk",
		"A brick path under two rose pergolas, with a sundial and benches half way along.",
		"flower",
		16,
		44,
		function(b: any)
			b:floor(4, 0, 12, 18, BRICK_PATH)
			b:floor(0, 18, 16, 26, PAVING)
			b:floor(4, 26, 12, 44, BRICK_PATH)
			put(b, "show_pergola", 8, 9, 0, Lay.F, WHITE, ROSE)
			put(b, "show_pergola", 8, 35, 0, Lay.F, WHITE, ROSE)

			-- flowers down both sides of the path, urns at its mouth and bushes where it opens out
			for _, z in { 5, 9, 13, 31, 35, 39 } do
				put(b, "flower_border", 3.2, z, 90)
				put(b, "flower_border", 12.8, z, 90)
			end
			put(b, "show_urn", 2.4, 1.5, 0, nil, nil, ROSE)
			put(b, "show_urn", 13.6, 1.5, 0, nil, nil, ROSE)
			for _, z in { 16.3, 27.6, 42.4 } do
				put(b, "bush", 1.8, z, 0)
				put(b, "bush", 14.2, z, 0)
			end

			-- the square half way: a sundial, two benches facing it, a lamp in each corner
			put(b, "show_sundial", 8, 22, 0, Lay.F)
			put(b, "bench_garden", 2, 22, 90, Lay.F, OAK, IRON)
			put(b, "bench_garden", 14, 22, 270, Lay.F, OAK, IRON)
			for _, p in { { 1.2, 18.8 }, { 14.8, 18.8 }, { 1.2, 25.2 }, { 14.8, 25.2 } } do
				put(b, "lamp_post", p[1], p[2], 0, Lay.F)
			end
			for _, p in { { 5.4, 19.2 }, { 10.6, 19.2 }, { 5.4, 24.8 }, { 10.6, 24.8 } } do
				put(b, "flower_pot", p[1], p[2], 0, Lay.F, nil, ROSE)
			end

			-- and a bench at the far end
			put(b, "bench_garden", 8, 42.4, 180, Lay.F, OAK, IRON)
		end
	)
end
