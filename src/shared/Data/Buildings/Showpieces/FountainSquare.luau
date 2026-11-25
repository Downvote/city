--!strict
-- A fountain square: four paved paths meet at a fountain in a paler square, with benches round it
-- turned to face the water. In each corner a raised bed behind a low stone wall holds a blossom
-- tree with flowers under it and an urn on the corner of its wall; lamps stand at the ends of the
-- paths.
--
-- The frame: x across, z back from the street. The paths are 10 wide on the middle lines, the
-- square where they meet x 10..20, z 10..20; the beds fill the corners from 2 to 10 in, each
-- with its own lawn inside the wall.

local Lay = require(script.Parent.Kit.Lay)

type Finish = Lay.Finish

local WARM: Finish = { c = "D9C7A7", m = "Pavement" }
local PALE: Finish = { c = "EAE6DC", m = "Pavement" }
local STONE: Finish = { c = "C8C0B0", m = "Cobblestone" }
local LAWN: Finish = { c = "8AC070", m = "Grass" }

local OAK = "C49A6C"
local IRON = "2F3B35"
local CORAL = "E08566"
local LILAC = "9C86B8"
local BUTTER = "F3DFA6"
local ROSE = "E8A0B4"

local put = Lay.put

return function(add: any)
	add(
		"show_fountain_square",
		"Fountain square",
		"Four paths meet at a fountain, with benches round it and a blossom tree in each corner.",
		"tree",
		30,
		30,
		function(b: any)
			-- the paths and the square
			b:floor(10, 0, 20, 10, WARM)
			b:floor(10, 20, 20, 30, WARM)
			b:floor(0, 10, 10, 20, WARM)
			b:floor(20, 10, 30, 20, WARM)
			b:floor(10, 10, 20, 20, PALE)
			put(b, "fountain", 15, 15, 0, Lay.F)
			for _, s in { { 11.8, 11.8, 45 }, { 18.2, 11.8, 315 }, { 11.8, 18.2, 135 }, { 18.2, 18.2, 225 } } do
				put(b, "bench_garden", s[1], s[2], s[3], Lay.F, OAK, IRON)
			end

			-- the four beds, each with its inner corner (by the square) and its flowers' colour
			local beds = {
				{ x0 = 2, z0 = 2, x1 = 10, z1 = 10, ix = 10, iz = 10, flowers = CORAL },
				{ x0 = 20, z0 = 2, x1 = 28, z1 = 10, ix = 20, iz = 10, flowers = LILAC },
				{ x0 = 2, z0 = 20, x1 = 10, z1 = 28, ix = 10, iz = 20, flowers = BUTTER },
				{ x0 = 20, z0 = 20, x1 = 28, z1 = 28, ix = 20, iz = 20, flowers = ROSE },
			}
			for i, bed in beds do
				local x0, z0, x1, z1 = bed.x0, bed.z0, bed.x1, bed.z1
				local n = "bed" .. i
				b:floor(x0, z0, x1, z1, LAWN)
				Lay.styled(b, n .. "f", x0, z0, x1, z0, STONE, "stone")
				Lay.styled(b, n .. "r", x1, z0, x1, z1, STONE, "stone")
				Lay.styled(b, n .. "b", x1, z1, x0, z1, STONE, "stone")
				Lay.styled(b, n .. "l", x0, z1, x0, z0, STONE, "stone")
				local cx, cz = (x0 + x1) / 2, (z0 + z1) / 2
				put(b, "tree_blossom", cx, cz, i * 40, Lay.F)
				-- flowers along the two inner sides, by the paths
				local ix, iz = bed.ix, bed.iz
				local inX = if ix > cx then ix - 1.6 else ix + 1.6
				local inZ = if iz > cz then iz - 1.6 else iz + 1.6
				-- (each kept back from the corner, so the two don't overlap there)
				put(b, "flower_border", if ix > cx then cx - 0.5 else cx + 0.5, inZ, 0, Lay.F)
				put(b, "flower_border", inX, if iz > cz then cz - 0.5 else cz + 0.5, 90, Lay.F)
				-- an urn on the corner of the wall by the square
				put(b, "show_urn", ix, iz, 0, 3, nil, bed.flowers)
			end

			-- lamps at the ends of the paths
			for _, p in
				{
					{ 11.4, 1.2 },
					{ 18.6, 1.2 },
					{ 11.4, 28.8 },
					{ 18.6, 28.8 },
					{ 1.2, 11.4 },
					{ 1.2, 18.6 },
					{ 28.8, 11.4 },
					{ 28.8, 18.6 },
				}
			do
				put(b, "lamp_post", p[1], p[2], 0, Lay.F)
			end
		end
	)
end
