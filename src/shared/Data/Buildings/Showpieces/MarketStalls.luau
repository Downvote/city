--!strict
-- Market stalls: four striped stalls in a row on a cobbled pitch with a hedge behind them, each
-- set out with its own goods: fruit and vegetables, flowers, books and old things, toys and
-- lamps. Crates and lamps stand in the gaps between them.
--
-- The frame: x across, z back from the street. The stalls face the street along z 9.6, their
-- counters to the front; the hedge runs along z 14.

local Lay = require(script.Parent.Kit.Lay)

type Finish = Lay.Finish

local COBBLES: Finish = { c = "BDB8AE", m = "Cobblestone" }
local HEDGE: Finish = { c = "6EAA62", m = "Grass" }

local OAK = "C49A6C"
local WALNUT = "9A6B48"
local CORAL = "D98B7A"
local SAGE = "8FB59A"
local SKY = "8FB3D0"
local BUTTER = "E8C66E"
local HERB = "6EA460"

local put = Lay.put

return function(add: any)
	add(
		"show_market_stalls",
		"Market stalls",
		"Four striped stalls selling fruit, flowers, books and toys, on a cobbled pitch.",
		"store",
		36,
		16,
		function(b: any)
			b:floor(0, 0, 36, 16, COBBLES)
			Lay.styled(b, "hedge", 0, 14, 36, 14, HEDGE, "hedge")
			local z = 9.6
			local counter = Lay.top("show_stall")
			local cz = z - 1.3 -- the middle of a counter's top
			local xs = { 4.6, 13.4, 22.2, 31 }
			for i, x in xs do
				put(b, "show_stall", x, z, 180, Lay.F, ({ CORAL, SAGE, SKY, BUTTER })[i], OAK)
			end

			-- fruit and vegetables
			put(b, "produce_stand", 4.6, 4.2, 180, Lay.F)
			put(b, "flower_pot", 3.2, cz, 0, counter, nil, HERB)
			put(b, "flower_pot", 6.0, cz, 0, counter, nil, HERB)
			put(b, "crate", 1.4, 1.6, 10, Lay.F, OAK, OAK)
			-- flowers
			put(b, "flower_stand", 13.4, 4.2, 180, Lay.F)
			for k, x in { 11.6, 13.4, 15.2 } do
				put(b, "vase_flowers", x, cz, k * 50, counter)
			end
			-- books and old things
			put(b, "books_stack", 20.6, cz, 20, counter)
			put(b, "books_stack", 21.8, cz, 80, counter)
			put(b, "globe", 23.2, cz, 200, counter)
			put(b, "candles", 24.4, cz, 0, counter)
			put(b, "menu_board", 25.8, 3.4, 200, Lay.F)
			-- toys and lamps
			put(b, "teddy", 29.6, cz, 180, counter)
			put(b, "lantern", 31, cz, 0, counter)
			put(b, "teddy", 32.4, cz, 160, counter, "E8C66E")
			put(b, "rocking_horse", 31, 4.4, 90, Lay.F)

			-- in the gaps: crates and a lamp each
			for _, x in { 9, 17.8, 26.6 } do
				put(b, "crate", x, 10.4, 10, Lay.F, OAK, OAK)
				put(b, "crate", x + 0.1, 10.3, 30, Lay.top("crate"), OAK, OAK)
				put(b, "lamp_post", x, 12.6, 0, Lay.F)
			end
			put(b, "water_butt", 34.6, 4.4, 0, Lay.F, SAGE, WALNUT)
		end
	)
end
