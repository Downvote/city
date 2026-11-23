--!nocheck
-- The island beyond the old town: the hills rise from nothing at their edges, stay flat where the
-- creator's stage and the farm, lookout and camp stand, and are gentle enough to walk; every place
-- to find is on the island, off the plots, and the explorer goal asks for all of them; nothing
-- stands in any road.

local Shared = "ReplicatedStorage.Shared."
local Tuning = require(Shared .. "Config.Tuning")
local Town = require(Shared .. "Data.Town")
local TownMap = require(Shared .. "Data.TownMap")
local Hills = require(Shared .. "Data.Hills")
local Places = require(Shared .. "Data.Places")
local Goals = require(Shared .. "Data.Goals")
local Geometry = require(Shared .. "Build.Geometry")

describe("Hills", function()
	it("start and end at ground level", function()
		for x = Hills.X1, Hills.X2 - 1, 50 do
			expect(Hills.at(x, Hills.Z1 + 1) < 1.5).toBeTruthy()
			expect(Hills.at(x, Hills.Z2 - 1) < 1).toBeTruthy()
		end
		for z = Hills.Z1, Hills.Z2 - 1, 50 do
			expect(Hills.at(Hills.X1 + 1, z) < 1).toBeTruthy()
			expect(Hills.at(Hills.X2 - 2, z) < 1).toBeTruthy()
		end
		-- nothing south of Hill Road's sidewalk
		expect(Hills.at(0, Town.RingZ + 10)).toBe(0)
	end)

	it("leave the creator's meadow flat", function()
		for slot = 1, 6 do
			local p = Town.CreatorSpot + Vector3.new(-(slot - 1) * Town.CreatorGap, 0, 0)
			for _, d in { Vector3.zero, Vector3.new(10, 0, 0), Vector3.new(0, 0, 14), Vector3.new(-8, 0, -8) } do
				expect(Hills.at(p.X + d.X, p.Z + d.Z)).toBe(0)
			end
		end
	end)

	it("are flat on top where things stand", function()
		for _, pl in Hills.Plateaus do
			local h = Hills.at(pl.x, pl.z)
			for _, a in { 0, 1.6, 3.1, 4.7 } do
				local r = pl.r * 0.6
				expect(math.abs(Hills.at(pl.x + math.cos(a) * r, pl.z + math.sin(a) * r) - h) < 1.5).toBeTruthy()
			end
		end
	end)

	it("are gentle enough to walk up", function()
		local steepest = 0
		for x = Hills.X1 + 5, Hills.X2 - 5, 17 do
			for z = Hills.Z1 + 5, Hills.Z2 - 5, 17 do
				steepest = math.max(steepest, Hills.slope(x, z))
			end
		end
		expect(steepest < 1.1).toBeTruthy()
	end)
end)

describe("Places", function()
	it("are all on the island and off the plots", function()
		local seen = {}
		for _, p in Places.list do
			expect(seen[p.id]).toBe(nil)
			seen[p.id] = true
			expect(math.abs(p.pos.X) <= TownMap.IslandX + TownMap.Beach).toBeTruthy()
			expect(p.pos.Z >= -TownMap.IslandS - 140 and p.pos.Z <= TownMap.IslandN + TownMap.Beach).toBeTruthy()
			expect(p.coins >= 0 and p.radius > 0).toBeTruthy()
			expect(p.name:find("\u{2014}") == nil and p.blurb:find("\u{2014}") == nil).toBeTruthy()
			for i = 1, Tuning.Plot.Count do
				local on, at = Town.toPlot(i, p.pos)
				expect(on and at.Z > 0.5).toBeFalsy()
			end
			expect(Places.near(p, p.pos)).toBeTruthy()
			expect(Places.near(p, p.pos + Vector3.new(p.radius + 5, 0, 0))).toBeFalsy()
		end
	end)

	it("are all counted by the explorer goal", function()
		local all = Goals.get("exploreAll")
		expect(all ~= nil).toBeTruthy()
		-- the town square is found where you arrive, so it counts too
		expect(all.need).toBe(#Places.list)
	end)
end)

describe("Roads", function()
	it("are clear of everything placed", function()
		for _, p in TownMap.placements() do
			-- (cars parked at the kerb are meant to be in the road's edge)
			if p.tag ~= "backdrop" and p.tag ~= "parked" then
				local pos = p.cf.Position
				for _, road in Town.Roads do
					local hw = road[5] - 1
					local x1, x2 = math.min(road[1], road[3]) - hw, math.max(road[1], road[3]) + hw
					local z1, z2 = math.min(road[2], road[4]) - hw, math.max(road[2], road[4]) + hw
					if pos.X > x1 and pos.X < x2 and pos.Z > z1 and pos.Z < z2 then
						error(p.name .. " stands in a road at " .. tostring(pos))
					end
				end
			end
		end
	end)

	it("have no trees beside them", function()
		-- the user: "remove the trees near the road". Trees keep to the parks, the hills, the
		-- market square and the beach: none within 18 studs of a sidewalk's outer edge.
		local TREES = {
			lowTree = true,
			lowTreeBig = true,
			lowPine = true,
			lowPineBig = true,
			streetTree = true,
			streetTreeLow = true,
			palm = true,
			palmTall = true,
			tree = true,
			pine = true,
		}
		local trees = 0
		for _, p in TownMap.placements() do
			if TREES[p.name] then
				trees += 1
				local pos = p.cf.Position
				for _, road in Town.Roads do
					local reach = road[5] + road[6]
					local x1, x2 = math.min(road[1], road[3]) - reach, math.max(road[1], road[3]) + reach
					local z1, z2 = math.min(road[2], road[4]) - reach, math.max(road[2], road[4]) + reach
					local dx = math.max(x1 - pos.X, 0, pos.X - x2)
					local dz = math.max(z1 - pos.Z, 0, pos.Z - z2)
					if math.sqrt(dx * dx + dz * dz) < 18 then
						error(p.name .. " stands by a road at " .. tostring(pos))
					end
				end
			end
		end
		expect(trees > 100).toBeTruthy()
	end)

	it("fill the gaps between buildings with little places, clear of everything else", function()
		local pockets = {}
		for _, p in TownMap.placements() do
			if p.name:sub(1, 6) == "pocket" then
				table.insert(pockets, p.cf.Position)
			end
		end
		expect(#pockets >= 24).toBeTruthy()
		for i, a in pockets do
			for j, b in pockets do
				if i < j then
					expect(math.abs(a.X - b.X) >= 30 or math.abs(a.Z - b.Z) >= 30).toBeTruthy()
				end
			end
		end
	end)

	it("have buildings all along every downtown block's edges", function()
		-- The user asked for a dense town, buildings shoulder to shoulder along the pavement. So
		-- along each edge of each downtown block, most of the way is built: nearly all of it in
		-- the market quarter (what is left is alleys, the lanes' mouths and the square), and well
		-- over half round the towers in the far blocks. What counts is anything a storey or more
		-- high and more than ten studs each way, standing within 24 studs of the edge.
		local built = {}
		for _, p in TownMap.placements() do
			if p.cf.Position.X > 550 and p.cf.Position.Z > -250 and p.cf.Position.Z < 250 then
				local lo, hi = Geometry.bounds(Geometry.transform(TownMap.prims(p.name), p.cf))
				if hi.Y - p.cf.Y > 12 and hi.X - lo.X > 10 and hi.Z - lo.Z > 10 then
					table.insert(built, { lo.X, lo.Z, hi.X, hi.Z })
				end
			end
		end
		expect(#built > 120).toBeTruthy()
		for _, b in TownMap.blocks("east") do
			local market = b[1] < Town.AvenueX[2]
			local edges = {
				{ "south", b[1], b[3], b[2], b[2] + 24, true },
				{ "north", b[1], b[3], b[4] - 24, b[4], true },
				{ "west", b[2], b[4], b[1], b[1] + 24, false },
				{ "east", b[2], b[4], b[3] - 24, b[3], false },
			}
			for _, e in edges do
				local covered, total = 0, 0
				for u = e[2] + 6, e[3] - 7 do
					total += 1
					for _, r in built do
						local hit
						if e[6] then
							hit = r[1] < u + 1 and r[3] > u and r[2] < e[5] and r[4] > e[4]
						else
							hit = r[2] < u + 1 and r[4] > u and r[1] < e[5] and r[3] > e[4]
						end
						if hit then
							covered += 1
							break
						end
					end
				end
				if covered / total < (if market then 0.8 else 0.65) then
					error(
						string.format(
							"the %s edge of the block at %d, %d is only %d%% built",
							e[1],
							b[1],
							b[2],
							covered / total * 100
						)
					)
				end
			end
		end
	end)

	it("keep downtown and the civic quarter's buildings inside their blocks", function()
		local blocks = {}
		for _, b in TownMap.blocks("east") do
			table.insert(blocks, b)
		end
		for _, b in TownMap.blocks("west") do
			table.insert(blocks, b)
		end
		local checked = 0
		for _, p in TownMap.placements() do
			local pos = p.cf.Position
			local home = nil
			for _, b in blocks do
				if pos.X > b[1] and pos.X < b[3] and pos.Z > b[2] and pos.Z < b[4] then
					home = b
				end
			end
			if home then
				local lo, hi = Geometry.bounds(Geometry.transform(TownMap.prims(p.name), p.cf))
				local inside = false
				for _, b in blocks do
					if lo.X >= b[1] - 4 and hi.X <= b[3] + 4 and lo.Z >= b[2] - 4 and hi.Z <= b[4] + 4 then
						inside = true
					end
				end
				if not inside then
					error(p.name .. " spills out of its block at " .. tostring(pos))
				end
				checked += 1
			end
		end
		expect(checked > 20).toBeTruthy()
	end)
end)
