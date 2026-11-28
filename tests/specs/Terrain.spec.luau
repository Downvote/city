--!nocheck
-- The island's ground as Roblox terrain (Data/Terrain). The user: "the shoreline should be wavy,
-- with water lapping up to it", then "make the grass and plants like in the image" (Roblox's own
-- long terrain grass). So: the water's edge is a run of smooth curves of different sizes on a
-- gentle slope of sand, inside the shallows; no grass blade grows under anything built (they show
-- through a floor), the plots included; the hills' terrain is Hills.at's height; the voxels are
-- what Roblox takes; what stands at the water's edge stands there, and what stands on the sand
-- is dry; and the place file grows Roblox's grass.

local Shared = "ReplicatedStorage.Shared."
local Tuning = require(Shared .. "Config.Tuning")
local Town = require(Shared .. "Data.Town")
local TownMap = require(Shared .. "Data.TownMap")
local Hills = require(Shared .. "Data.Hills")
local Terrain = require(Shared .. "Data.Terrain")
local Geometry = require(Shared .. "Build.Geometry")

local V = Terrain.Voxel
local cover = TownMap.cover()
local plan = Terrain.plan(cover)
-- (round the island: the south shore is longer than straight across, round the old town's cape)
local AROUND = Terrain.Around

local NAMES = {}
for _, m in Terrain.Materials do
	NAMES[m] = m
end

local function material(x, z)
	local _, m = Terrain.at(plan, x, z)
	return m
end

describe("Terrain", function()
	describe("the shore", function()
		it("waves in and out in smooth curves of different sizes, never a straight edge", function()
			local w = {}
			for s = 0, AROUND, V do
				table.insert(w, Terrain.waterLine(s))
			end
			local lo, hi, turns, straight = math.huge, -math.huge, 0, 0
			for i = 2, #w - 1 do
				lo, hi = math.min(lo, w[i]), math.max(hi, w[i])
				local d2 = w[i + 1] - 2 * w[i] + w[i - 1]
				-- smooth: it bends a little from one voxel to the next, never at a corner
				expect(math.abs(d2) < 0.6).toBeTruthy()
				if math.abs(d2) < 1e-4 then
					straight += 1
				end
				if (w[i] - w[i - 1]) * (w[i + 1] - w[i]) < 0 then
					turns += 1
				end
			end
			-- bays and points all round the island, big and small, and nowhere a polygon's
			-- straight side
			expect(hi - lo > 25).toBeTruthy()
			expect(turns >= 120).toBeTruthy()
			expect(straight / #w < 0.02).toBeTruthy()
			-- it closes on itself where the coast comes round to where it started
			expect(Terrain.waterLine(0)).toBeNear(Terrain.waterLine(AROUND), 1e-6)
		end)

		it("puts the water's edge on a gentle slope of sand, inside the shallows", function()
			for s = 0, AROUND - 1, 37 do
				local g, w = Terrain.grassLine(s), Terrain.waterLine(s)
				-- a beach between the grass and the sea everywhere, and the edge well inside the
				-- hidden walls round the shallows
				expect(w - g >= 14).toBeTruthy()
				expect(w < Terrain.Beach + Terrain.Shallows - 50).toBeTruthy()
				expect(g >= -Terrain.Voxel).toBeTruthy() -- (under the boardwalk's edge on the south)
			end
			-- along a line out from the middle of each shore: grass, then sand that slopes down
			-- through the sea's level, then sand under the water, then the deep
			for _, probe in
				{ { 0, -1, "south" }, { 1, 0, "east" }, { 0, 1, "north" }, { -1, 0, "west" }, { 0, -1, "downtown" } }
			do
				local dx, dz = probe[1], probe[2]
				-- (the south shore out on the old town's cape, and past it in front of downtown)
				local x0 = if dx ~= 0 then dx * Terrain.IslandX elseif probe[3] == "downtown" then 960 else 137
				local z0 = if dz > 0 then Terrain.IslandN elseif dz < 0 then -Terrain.south(x0) else 311
				local _, s = Terrain.coast(x0, z0)
				local w = Terrain.waterLine(s)
				local last = math.huge
				for d = 1, 200, 0.5 do
					local h, m = Terrain.natural(x0 + dx * d, z0 + dz * d)
					expect(h <= last + 1e-9).toBeTruthy() -- never rising toward the sea
					last = h
					if d > Terrain.grassLine(s) + 0.5 and d < w + 60 then
						expect(m).toBe("Sand")
					end
				end
				local hw = Terrain.natural(x0 + dx * w, z0 + dz * w)
				expect(hw).toBeNear(Terrain.WaterY, 0.01)
				-- gentle where the water laps: a twentieth or so, so a small wave runs well up the sand
				local up = Terrain.natural(x0 + dx * (w - 2), z0 + dz * (w - 2))
				local down = Terrain.natural(x0 + dx * (w + 2), z0 + dz * (w + 2))
				local slope = (up - down) / 4
				expect(slope > 0.02 and slope < 0.12).toBeTruthy()
				expect(Terrain.natural(x0 + dx * 260, z0 + dz * 260)).toBeNear(Terrain.Floor, 0.01)
			end
		end)

		it("keeps the shallows shallow out to the hidden walls", function()
			local edge = Terrain.Beach + Terrain.Shallows
			for s = 0, AROUND - 1, 53 do
				expect(Terrain.deepLine(s) > edge).toBeTruthy()
			end
			for x = -Terrain.IslandX, Terrain.IslandX, 97 do
				local h = Terrain.natural(x, -Terrain.south(x) - edge + 1)
				expect(h > -4.5 and h < Terrain.WaterY).toBeTruthy()
			end
		end)

		it("comes round the old town's cape in one smooth curve, with a beach all the way", function()
			-- The plots run 400 back from the main street (the user: "make player plots much
			-- bigger, double the size"), so the south shore stands out past them between the first
			-- avenues and eases back beside them. Harbour Road and the boardwalk stay on land.
			local cape = Terrain.Cape
			expect(Terrain.south(0)).toBe(Terrain.IslandS + cape.out)
			expect(Terrain.south(cape.half + cape.ease)).toBe(Terrain.IslandS)
			expect(Terrain.south(Terrain.IslandX)).toBe(Terrain.IslandS)
			local plotsReach = Town.PlotSetback + Tuning.Plot.Size
			for x = -Town.AvenueX[1] - 17, Town.AvenueX[1] + 17, 13 do
				expect(Terrain.south(x) >= Town.RingZ + 17 + 13).toBeTruthy()
				expect(Terrain.south(x) > plotsReach + 40).toBeTruthy()
			end
			local last = Terrain.south(0)
			for x = 0, Terrain.IslandX, 2 do
				local now = Terrain.south(x)
				expect(now <= last + 1e-9).toBeTruthy()
				-- (no corner: it turns a little from one step to the next)
				local bend = Terrain.south(x + 2) - 2 * now + Terrain.south(x - 2)
				expect(math.abs(bend) < 0.1).toBeTruthy()
				last = now
			end
			-- down the curving sides, straight out to sea: grass, sand sloping down to the water
			-- where Terrain.shore says it is, then the sea floor
			for _, x0 in { -800, -700, -600, 600, 700, 800 } do
				local _, s = Terrain.coast(x0, -Terrain.south(x0))
				local g, w = Terrain.grassLine(s), Terrain.waterLine(s)
				expect(w - g >= 14).toBeTruthy()
				local last = math.huge
				local z0 = -Terrain.south(x0) + 30
				for dz = 0, 260, 0.5 do
					local h, m = Terrain.natural(x0, z0 - dz)
					expect(h <= last + 1e-9).toBeTruthy()
					last = h
					local d = Terrain.coast(x0, z0 - dz)
					if d > g + 0.5 and d < w + 60 then
						expect(m).toBe("Sand")
					end
				end
				local wx, wz = Terrain.shore("south", x0)
				expect(wx).toBe(x0)
				expect(Terrain.natural(wx, wz)).toBeNear(Terrain.WaterY, 0.01)
			end
		end)
	end)

	describe("the grass", function()
		it("never grows under anything built, nor right up to its edge", function()
			local checked = 0
			for _, c in cover do
				local x1, z1, x2, z2 = c.x1, c.z1, c.x2, c.z2
				local m = Terrain.Margin - 0.05
				for _, p in
					{
						{ (x1 + x2) / 2, (z1 + z2) / 2 },
						{ x1 + 0.01, z1 + 0.01 },
						{ x2 - 0.01, z2 - 0.01 },
						{ x1 - m, (z1 + z2) / 2 },
						{ x2 + m, (z1 + z2) / 2 },
						{ (x1 + x2) / 2, z1 - m },
						{ (x1 + x2) / 2, z2 + m },
					}
				do
					local got = material(p[1], p[2])
					if got == "Grass" then
						error(string.format("grass blades under %s ground at %.1f, %.1f", c.kind, p[1], p[2]))
					end
				end
				checked += 1
			end
			expect(checked > 1000).toBeTruthy()
		end)

		it("keeps every road and plot clear of blades", function()
			-- (the pavements are in the ground's parts, checked above: they stop at junctions)
			for _, road in Town.Roads do
				local reach = road[5]
				local horizontal = road[2] == road[4]
				local a1 = if horizontal then math.min(road[1], road[3]) else math.min(road[2], road[4])
				local a2 = if horizontal then math.max(road[1], road[3]) else math.max(road[2], road[4])
				local at = if horizontal then road[2] else road[1]
				for u = a1, a2, 9 do
					for v = -reach + 0.2, reach - 0.2, 2.5 do
						local x, z = if horizontal then u else at + v, if horizontal then at + v else u
						expect(material(x, z) ~= "Grass").toBeTruthy()
					end
				end
			end
			-- the players build their floors on the plots
			local size = Tuning.Plot.Size
			for i = 1, Tuning.Plot.Count do
				local f = Town.plotFrame(i)
				for u = 0.5, size - 0.5, 7 do
					for v = 0.5, size - 0.5, 7 do
						local p = f * Vector3.new(u, 0, v)
						if material(p.X, p.Z) ~= "LeafyGrass" then
							error(
								string.format("plot %d has %s at %.1f, %.1f", i, tostring(material(p.X, p.Z)), p.X, p.Z)
							)
						end
					end
				end
			end
		end)

		it("lies a voxel or more under every plot's floor, away from its edges", function()
			-- Roblox draws far terrain with coarser voxels, which once stood the island's grass up
			-- through a plot's ground in a long strip (the user's picture). Under a plot's inside the
			-- ground lies at Terrain.PlotFloor, a whole voxel under the floor, where the plot's own
			-- ground part reaches down to; within a voxel of the edges it keeps the paved height, so
			-- it steps down out of sight under that part and never dips beside it.
			expect(Terrain.PlotFloor <= -V).toBe(true)
			local size = Tuning.Plot.Size
			local inside, edge = 0, 0
			for i = 1, Tuning.Plot.Count do
				local f = Town.plotFrame(i)
				for u = 1, size - 1, 3 do
					for v = 1, size - 1, 3 do
						local p = f * Vector3.new(u, 0, v)
						local h, m = Terrain.at(plan, p.X, p.Z)
						expect(m).toBe("LeafyGrass")
						local away = math.min(u, v, size - u, size - v)
						if away > 2 * V then
							if h > Terrain.PlotFloor + 1e-6 then
								error(string.format("plot %d's ground at %.1f, %.1f is at %.2f", i, p.X, p.Z, h))
							end
							inside += 1
						end
						-- never above the paved height on it (the column astride its edge, half under
						-- the street, keeps the street's)
						if away > V / 2 then
							expect(h <= Terrain.Ground - Terrain.Sink + 1e-6).toBe(true)
						end
					end
				end
				-- just past its edges, the street's own ground is as it was
				for u = 2, size - 2, 7 do
					for _, at in { Vector3.new(u, 0, -1.5), Vector3.new(-1.5, 0, u), Vector3.new(size + 1.5, 0, u) } do
						local p = f * at
						local h = Terrain.at(plan, p.X, p.Z)
						if h and h < Terrain.Ground - Terrain.Sink - 1e-6 then
							error(string.format("a dip beside plot %d at %.1f, %.1f: %.2f", i, p.X, p.Z, h))
						end
						edge += 1
					end
				end
			end
			expect(inside > 10000).toBe(true)
			expect(edge > 100).toBe(true)
		end)

		it("grows over the open ground: the old town's verges, the hills and the meadow", function()
			local grass, total = 0, 0
			for x = -1090, 1090, 13 do
				for z = 230, 930, 13 do
					-- (the hills: past the old town's stretch of Hill Road, which runs out behind its
					-- plots now, and past the ring's old line in front of downtown and the civic quarter)
					if z > Town.ringAt(x) + 17 then
						total += 1
						local m = material(x, z)
						if m == "Grass" or m == "Rock" then
							grass += 1
						end
					end
				end
			end
			-- most of the hills are open grass (paths, the farm, the camp and the rest are not)
			expect(grass / total > 0.75).toBeTruthy()
			-- between the plots and Hill Road, and the creator's meadow
			expect(material(-300, Town.PlotSetback + Tuning.Plot.Size + 4)).toBe("Grass")
			expect(material(Town.CreatorSpot.X, Town.CreatorSpot.Z - 30)).toBe("Grass")
		end)

		it("follows the hills, a tenth under Hills.at like the flat grass", function()
			for x = Hills.X1 + 2, Hills.X2 - 2, 44 do
				for z = Hills.Z1 + 2, Hills.Z2 - 2, 44 do
					local h, m = Terrain.at(plan, x, z)
					if m == "Grass" or m == "Rock" then
						-- the column's own middle
						local cx = plan.x1 + (math.floor((x - plan.x1) / V) + 0.5) * V
						local cz = plan.z1 + (math.floor((z - plan.z1) / V) + 0.5) * V
						expect(h).toBeNear(Hills.at(cx, cz) + Terrain.Ground, 1e-6)
					end
				end
			end
			-- and between the columns' middles, where Roblox draws the surface from them, it
			-- stays within a few hundredths of the height things are placed at
			local worst = 0
			for x = Hills.X1 + 3.3, Hills.X2 - 3, 31.7 do
				for z = Hills.Z1 + 3.1, Hills.Z2 - 3, 29.3 do
					local fi = (x - plan.x1) / V - 0.5
					local fj = (z - plan.z1) / V - 0.5
					local i, j = math.floor(fi), math.floor(fj)
					local u, v = fi - i, fj - j
					local function hgt(a, b)
						return plan.height[(j + b) * plan.nx + (i + a) + 1],
							plan.material[(j + b) * plan.nx + (i + a) + 1]
					end
					local h00, m00 = hgt(0, 0)
					local h10, m10 = hgt(1, 0)
					local h01, m01 = hgt(0, 1)
					local h11, m11 = hgt(1, 1)
					local open = true
					for _, m in { m00, m10, m01, m11 } do
						open = open and (m == "Grass" or m == "Rock")
					end
					if open then
						local h = (h00 * (1 - u) + h10 * u) * (1 - v) + (h01 * (1 - u) + h11 * u) * v
						worst = math.max(worst, math.abs(h - (Hills.at(x, z) + Terrain.Ground)))
					end
				end
			end
			expect(worst < 0.15).toBeTruthy()
		end)

		it("is rock only on the steepest slopes, a few bits", function()
			local rock, hill = 0, 0
			for k, m in plan.material do
				if m == "Rock" then
					rock += 1
				end
				if m == "Grass" or m == "Rock" then
					hill += 1
				end
				local _ = k
			end
			expect(rock > 0).toBeTruthy()
			expect(rock / hill < 0.05).toBeTruthy()
		end)
	end)

	describe("the voxels", function()
		it("tile the region on the 4 stud grid, inside Roblox's limits", function()
			local seen = table.create(plan.nx * plan.nz, 0)
			for _, tile in Terrain.tiles(plan) do
				local lo, hi, ch = Terrain.voxels(plan, tile, NAMES)
				for _, n in { lo.X, lo.Y, lo.Z, hi.X, hi.Y, hi.Z } do
					expect(n % V).toBe(0)
				end
				local size = (hi - lo) / V
				expect(size.X * size.Y * size.Z <= 4194304).toBeTruthy()
				for _, name in { "SolidMaterial", "SolidOccupancy", "LiquidOccupancy" } do
					local a = ch[name]
					expect(#a).toBe(size.X)
					expect(#a[1]).toBe(size.Y)
					expect(#a[1][1]).toBe(size.Z)
				end
				for j = tile[2], tile[2] + tile[4] - 1 do
					for i = tile[1], tile[1] + tile[3] - 1 do
						seen[j * plan.nx + i + 1] += 1
					end
				end
			end
			for _, n in seen do
				expect(n).toBe(1)
			end
		end)

		it("fill each column to its height, and the sea to its level over the sand", function()
			-- (and only over the sea's own floor: the ground under a plot lies under the sea's
			-- level, and the sea over it once showed as the whole basement, Build/Underground)
			local land, sea, shore, dry = 0, 0, 0, 0
			for _, tile in Terrain.tiles(plan, 48) do
				-- (every fifth tile: they are all made the same way)
				if (tile[1] + tile[2]) % 5 == 0 then
					local lo, _, ch = Terrain.voxels(plan, tile, NAMES)
					for a = 1, tile[3] do
						for c = 1, tile[4] do
							local k = (tile[2] + c - 1) * plan.nx + tile[1] + a
							local h = plan.height[k]
							local filled, water = 0, nil
							for y = 1, #ch.SolidOccupancy[a] do
								local occ = ch.SolidOccupancy[a][y][c]
								filled += occ
								if occ > 0 then
									expect(ch.SolidMaterial[a][y][c]).toBe(plan.material[k])
								else
									expect(ch.SolidMaterial[a][y][c]).toBe("Air")
								end
								local liquid = ch.LiquidOccupancy[a][y][c]
								if liquid > 0 and liquid < 1 then
									water = lo.Y + (y - 1) * V + liquid * V
								end
							end
							expect(lo.Y + filled * V).toBeNear(h, 0.02)
							if h < Terrain.WaterY and Terrain.SeaFloor[plan.material[k]] then
								expect(water).toBeNear(Terrain.WaterY, 1e-6)
								sea += 1
								if h > Terrain.WaterY - 1 then
									shore += 1
								end
							else
								expect(water).toBe(nil)
								land += 1
								if h < Terrain.WaterY then
									for y = 1, #ch.LiquidOccupancy[a] do
										expect(ch.LiquidOccupancy[a][y][c]).toBe(0)
									end
									dry += 1
								end
							end
						end
					end
				end
			end
			expect(land > 1000 and sea > 1000 and shore > 50 and dry > 100).toBeTruthy()
		end)

		it("fill the open sea out to the horizon, round the island's region and not over it", function()
			local R, F = Terrain.Region, Terrain.Far
			local area = 0
			for _, b in Terrain.openSea() do
				local c, size = b.center, b.size
				local x1, x2 = c.X - size.X / 2, c.X + size.X / 2
				local z1, z2 = c.Z - size.Z / 2, c.Z + size.Z / 2
				for _, n in { x1, x2, z1, z2 } do
					expect(n % V).toBe(0)
				end
				expect(x1 >= -F and x2 <= F and z1 >= -F and z2 <= F).toBeTruthy()
				-- outside the region written column by column
				expect(x2 <= R[1] or x1 >= R[3] or z2 <= R[2] or z1 >= R[4]).toBeTruthy()
				expect(size.X <= 1000 and size.Z <= 1000).toBeTruthy()
				if b.material == "Water" then
					area += size.X * size.Z
					expect(c.Y + size.Y / 2).toBeNear(Terrain.WaterY, 1e-6)
				else
					expect(b.material).toBe("Slate")
					expect(c.Y + size.Y / 2).toBeNear(Terrain.Floor, 1e-6)
				end
			end
			expect(area).toBeNear(4 * F * F - (R[3] - R[1]) * (R[4] - R[2]), 1)
		end)
	end)

	describe("the beach", function()
		local placements = TownMap.placements()

		it("has the rowing boats pulled up at the water's edge", function()
			local boats = 0
			for _, p in placements do
				if p.name == "rowboat" then
					boats += 1
					local pos = p.cf.Position
					local d, s = Terrain.coast(pos.X, pos.Z)
					expect(Terrain.waterLine(s) - d).toBeBetween(1, 3)
					expect(pos.Y).toBeNear(Terrain.height(pos.X, pos.Z) - 0.15, 0.01)
				end
			end
			expect(boats).toBe(5)
		end)

		it("keeps what stands on the sand dry, and on it", function()
			local ON_SAND = {
				towel = true,
				towel2 = true,
				sandcastle = true,
				beachBall = true,
				driftwood = true,
				parasol = true,
				palm = true,
				palmTall = true,
				volleyNet = true,
				surfRack = true,
				beachHuts = true,
				lifeguard = true,
			}
			local count = 0
			for _, p in placements do
				local pos = p.cf.Position
				local d = Terrain.coast(pos.X, pos.Z)
				if ON_SAND[p.name] and d > 0 then
					count += 1
					local ground = Terrain.height(pos.X, pos.Z)
					-- stood on the sand, sunk a little at most
					expect(ground - pos.Y).toBeBetween(-0.01, 0.4)
					-- and every corner of its footprint is above the sea
					local lo, hi = Geometry.bounds(Geometry.transform(TownMap.prims(p.name), p.cf))
					for _, c in { { lo.X, lo.Z }, { hi.X, lo.Z }, { lo.X, hi.Z }, { hi.X, hi.Z } } do
						if
							Terrain.height(c[1], c[2]) < Terrain.WaterY + 0.05
							and p.name ~= "palm"
							and p.name ~= "palmTall"
						then
							error(string.format("%s at %.1f, %.1f stands in the sea", p.name, pos.X, pos.Z))
						end
					end
				end
			end
			expect(count > 80).toBeTruthy()
		end)
	end)

	describe("the place file", function()
		it("leaves Roblox's own blades off and sets the sea and the wind as Data/Terrain says", function()
			local project = decodeJson(readFile("default.project.json"))
			local ws = project.tree.Workspace
			local props = ws.Terrain["$properties"]
			-- (Roblox's own blades are off, and there is no long grass: the user, "remove the grass")
			expect(props.Decoration).toBe(false)
			expect(props.ShorelinesUpgraded).toBe(true)
			local water = Terrain.Water
			expect(props.WaterTransparency).toBe(water.Transparency)
			expect(props.WaterReflectance).toBe(water.Reflectance)
			expect(props.WaterWaveSize).toBe(water.WaveSize)
			expect(props.WaterWaveSpeed).toBe(water.WaveSpeed)
			for i = 1, 3 do
				expect(math.floor(props.WaterColor[i] * 255 + 0.5)).toBe(water.Color[i])
				expect(ws["$properties"].GlobalWind[i]).toBe(Terrain.Wind[i])
			end
			-- the terrain's grass wears the soft picture ("change ... the grass texture to a softer one,
			-- which dosent have too high contrast"), the grass under what is built the same one, both
			-- laid organically so no grid of copies shows across the island
			local ms = project.tree.MaterialService
			local names = ms and ms["$properties"]
			expect(names and names.GrassName).toBe("CatalogTownGrass")
			expect(names.LeafyGrassName).toBe("CatalogTownLeafy")
			local grass, leafy = ms.CatalogTownGrass["$properties"], ms.CatalogTownLeafy["$properties"]
			expect(grass.ColorMap).toBe(leafy.ColorMap)
			expect(grass.MaterialPattern).toBe("Organic")
			expect(leafy.MaterialPattern).toBe("Organic")
		end)
	end)
end)
