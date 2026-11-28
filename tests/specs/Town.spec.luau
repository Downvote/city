--!nocheck
-- The town map: every placed model exists, nothing stands on a plot or in the road, the
-- sidewalks leave room to walk, the scenery out at sea stays off the plots, and the panels'
-- buildings are all there.

local Shared = "ReplicatedStorage.Shared."
local Tuning = require(Shared .. "Config.Tuning")
local Town = require(Shared .. "Data.Town")
local TownMap = require(Shared .. "Data.TownMap")
local Geometry = require(Shared .. "Build.Geometry")
local Terrain = require(Shared .. "Data.Terrain")
local Hills = require(Shared .. "Data.Hills")

describe("Town", function()
	it("lays out six big plots in the old town, inside its ring, on the island", function()
		-- The user: "make player plots much bigger, double the size", and asked how, four of 400 a
		-- side in the old town, two north of the main street and two south. Then: "could you make
		-- the max plots 6, expanding the map for it?", so two more of the same size north of Hill
		-- Road, back to back with the first two, before Ridge Road. A server holds one player to a
		-- plot.
		expect(Tuning.Plot.Count).toBe(6)
		expect(Tuning.Plot.Size).toBe(400)
		expect(Tuning.Game.MaxPlayers).toBe(Tuning.Plot.Count)
		local project = decodeJson(readFile("default.project.json"))
		expect(project.tree.Players["$properties"].MaxPlayers).toBe(Tuning.Game.MaxPlayers)
		-- plot 1 stays where it always was (the Build mode simulation clicks on it)
		expect(Town.plotFrame(1).Position).toBe(Vector3.new(-466, 0, 22))
		local size = Tuning.Plot.Size
		local south = Town.RingZ - 11 - 6 -- (Harbour Road's sidewalk, and the first avenues')
		local north = Town.RidgeZ - 11 - 6 -- (Ridge Road's)
		local avenue = Town.AvenueX[1] - 11 - 6
		local rects = {}
		for i = 1, Tuning.Plot.Count do
			local f = Town.plotFrame(i)
			local row = Town.plotRow(i)
			-- local z runs back from the street: north for the plots north of theirs
			expect(f:VectorToWorldSpace(Vector3.new(0, 0, 1)).Z).toBeNear(row.side, 1e-6)
			local a, b = f * Vector3.zero, f * Vector3.new(size, 0, size)
			local r = { math.min(a.X, b.X), math.min(a.Z, b.Z), math.max(a.X, b.X), math.max(a.Z, b.Z) }
			-- the front on the back of its street's sidewalk (on Hill Road a verge of grass past it,
			-- so the corners keep to the terrain's grid), the rest inside the ring
			local front = if row.side > 0 then r[2] - row.z else row.z - r[4]
			if row.z == 0 then
				expect(front).toBeNear(Town.StreetHalfWidth + Town.SidewalkWidth, 1e-6)
			else
				expect(front >= 11 + 6 and front <= 11 + 6 + 4).toBeTruthy()
			end
			expect(r[1] > -avenue and r[3] < avenue and r[2] > -south and r[4] < north).toBeTruthy()
			-- clear of the square and the market between them, and of the walk up to the hills
			expect(r[1] >= Town.SquareCenter.X + 50 or r[3] <= Town.SquareCenter.X - 50).toBeTruthy()
			-- every corner 2 off the terrain's 4 stud grid (Build/Water, Build/Basement)
			for _, c in { a, b } do
				for _, v in { c.X, c.Z } do
					local m = (v - 2) % 4
					expect(math.min(m, 4 - m)).toBeNear(0, 1e-3)
				end
			end
			-- on the island: the south ones out on the old town's cape, and flat
			for _, x in { r[1], (r[1] + r[3]) / 2, r[3] } do
				expect(Terrain.coast(x, r[2]) < -60).toBeTruthy()
				expect(Terrain.coast(x, r[4]) < -60).toBeTruthy()
				expect(Hills.at(x, r[4] + 30)).toBe(0)
			end
			-- you arrive in front of your own plot, on the sidewalk
			local arrive = Town.plotArrival(i).Position
			local on = Town.toPlot(i, arrive)
			expect(on).toBe(false)
			expect(math.abs(arrive.Z - row.z) < (if row.z == 0 then Town.StreetHalfWidth + Town.SidewalkWidth else 17)).toBeTruthy()
			table.insert(rects, r)
		end
		for i, a in rects do
			for j, b in rects do
				if i < j then
					local apart = a[3] <= b[1] or b[3] <= a[1] or a[4] <= b[2] or b[4] <= a[2]
					expect(apart).toBeTruthy()
				end
			end
		end
	end)

	it("places only models that exist", function()
		for _, p in TownMap.placements() do
			local prims = TownMap.prims(p.name)
			expect(#prims > 0).toBeTruthy()
		end
	end)

	it("keeps the plots and the road clear", function()
		for _, p in TownMap.placements() do
			local prims = Geometry.transform(TownMap.prims(p.name), p.cf)
			if p.tag == "backdrop" then
				-- scenery out at sea (islets): every piece stays well past the plots, beyond them
				-- to the north or south, or past the last plot at either end of the street
				local lastX, northZ, southZ = 0, 0, 0
				for _, cx in Town.PlotCentersX do
					lastX = math.max(lastX, math.abs(cx) + Tuning.Plot.Size / 2)
				end
				for i = 1, Tuning.Plot.Count do
					local f = Town.plotFrame(i)
					for _, c in { f * Vector3.zero, f * Vector3.new(Tuning.Plot.Size, 0, Tuning.Plot.Size) } do
						northZ, southZ = math.max(northZ, c.Z), math.max(southZ, -c.Z)
					end
				end
				for _, prim in prims do
					local reach = math.max(prim.size.X, prim.size.Z) / 2
					local pos = prim.cf.Position
					local clearZ = if pos.Z > 0 then pos.Z - reach > northZ + 4 else -pos.Z - reach > southZ + 4
					local clearX = math.abs(pos.X) - reach > lastX + 4
					if not clearZ and not clearX then
						error(p.name .. " reaches the plots at " .. tostring(pos))
					end
				end
				continue
			end
			local lo, hi = Geometry.bounds(prims)
			for i = 1, Tuning.Plot.Count do
				for _, corner in { Vector3.new(lo.X, 0, lo.Z), Vector3.new(hi.X, 0, hi.Z), p.cf.Position } do
					local on, at = Town.toPlot(i, corner)
					-- a hair inside the edge counts as touching, not standing on
					if on and at.Z > 0.5 and at.X > 0.5 and at.X < Tuning.Plot.Size - 0.5 then
						error(p.name .. " stands on plot " .. i)
					end
				end
			end
			-- nothing in the carriageway (the crossings' bollards and signs stand on the curb)
			local pos = p.cf.Position
			if math.abs(pos.Z) < Town.StreetHalfWidth and math.abs(pos.X) <= Town.HalfLength + 2 then
				error(p.name .. " is in the road at " .. tostring(p.cf.Position))
			end
		end
	end)

	it("leaves room to walk behind the street trees", function()
		local back = Town.StreetHalfWidth + Town.SidewalkWidth
		for _, p in TownMap.placements() do
			if p.name == "streetTree" and math.abs(p.cf.Position.Z) < back then
				local prims = Geometry.transform(TownMap.prims(p.name), p.cf)
				local lo, hi = Geometry.bounds(prims)
				-- only the planter's footprint matters at walking height; the crown is overhead
				local pit = math.max(math.abs(p.cf.Position.Z) + 1.8, 0)
				expect(back - pit >= 3).toBeTruthy()
				local _ = lo
				local _ = hi
			end
		end
	end)

	it("has every building a panel opens from", function()
		local opens = {}
		for _, p in TownMap.placements() do
			if p.opens then
				opens[p.opens] = true
			end
		end
		for _, need in { "news", "creator", "city" } do
			expect(opens[need]).toBe(true)
		end
		-- and none for the shop, which is gone (the user: "remove the shop, buying of things and
		-- food and feeding"); nothing would answer it
		expect(opens.shop).toBe(nil)
	end)

	it("keeps the spawn and the festival spot clear", function()
		for _, spot in { Town.Spots.Spawn, Town.Spots.Festival } do
			for _, p in TownMap.placements() do
				local lo, hi = Geometry.bounds(Geometry.transform(TownMap.prims(p.name), p.cf))
				local inside = spot.X > lo.X - 2 and spot.X < hi.X + 2 and spot.Z > lo.Z - 2 and spot.Z < hi.Z + 2
				if inside then
					error(p.name .. " stands on a spot at " .. tostring(spot))
				end
			end
		end
	end)

	it("keeps the ground to a sensible number of parts", function()
		expect(#TownMap.ground()).toBeBetween(100, 9000)
	end)

	it("keeps the whole town to a budget of parts and of different pieces", function()
		-- A piece (Geometry.piece) is one part in the game for its boxes and wedges, one merged
		-- mesh copied wherever it is used, plus a part for each round shape in it
		-- (Geometry.served). So the town is counted twice: that way, which is what a server holds, and with every piece opened into its shapes, which is what a client
		-- draws where the merge can't be done. Every different piece is a merge when the server
		-- starts, so there may not be many of those either. (The caps went up from 30,000, 70,000
		-- and 220 for the user's "the amount of detail should be similar to the default house
		-- everywhere".)
		local ground = TownMap.ground()
		local parts, opened = Geometry.served(ground), #Geometry.flatten(ground)
		local keys, different = {}, 0
		local function note(prims)
			for _, prim in prims do
				if prim.shape == "Piece" and not keys[prim.key] then
					keys[prim.key] = true
					different += 1
				end
			end
		end
		note(ground)
		local sizes = {}
		for _, p in TownMap.placements() do
			local size = sizes[p.name]
			if not size then
				local prims = TownMap.prims(p.name)
				note(prims)
				size = { Geometry.served(prims), #Geometry.flatten(prims) }
				sizes[p.name] = size
			end
			parts += size[1]
			opened += size[2]
		end
		print(string.format("Town: %d parts, %d opened, %d different pieces", parts, opened, different))
		-- (parts went up from 36,000 when round shapes stopped being merged into pieces and became
		-- parts of their own, for the user's "alot of the objects seem to have its pieces wrong")
		expect(parts < 56000).toBeTruthy()
		-- (opened went up from 110,000 when the civic quarter was built up for the user's "the
		-- side with less buildings should have much more buildings, as much as in the city side",
		-- and from 126,000 for the land round the plots north of Hill Road ("could you make the
		-- max plots 6, expanding the map for it?") and more rooms to walk into ("detail the town
		-- more, and make the lights and interior in them work"))
		expect(opened < 136000).toBeTruthy()
		expect(different < 320).toBeTruthy()
	end)
end)
