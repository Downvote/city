--!strict
-- A five storey pagoda in a square of raked gravel, a tall stone lantern at each corner. (The user,
-- with a picture of an old temple in a forest: "Make another for this as well".)
--
-- The frame: x across, z back from the street. The gravel is x 1..23, z 1..23 and the pagoda
-- stands in its middle, its steps to the front.

local Lay = require(script.Parent.Kit.Lay)

type Finish = Lay.Finish

local GRAVEL: Finish = { c = "D2CBBB", m = "Pebble" }

local F = Lay.F
local put = Lay.put

return function(add: any)
	add(
		"show_pagoda",
		"Pagoda square",
		"A pagoda in a square of gravel, a lantern at each corner.",
		"pagoda",
		24,
		24,
		function(b: any)
			b:floor(2, 2, 22, 22, GRAVEL)
			put(b, "temple_pagoda", 12, 12, 180, F)
			for _, p in { { 3.6, 3.6 }, { 20.4, 3.6 }, { 3.6, 20.4 }, { 20.4, 20.4 } } do
				put(b, "temple_lantern", p[1], p[2], 0, F)
			end
		end,
		"temple"
	)
end
