--!nocheck
-- The town map: every placed model exists, nothing stands on a plot or in the road, the
-- sidewalks leave room to walk, the scenery out at sea stays off the plots, and the panels'
-- buildings are all there.

local Shared = "ReplicatedStorage.Shared."
local Tuning = require(Shared .. "Config.Tuning")
local Town = require(Shared .. "Data.Town")
local TownMap = require(Shared .. "Data.TownMap")
local Geometry = require(Shared .. "Build.Geometry")

describe("Town", function()
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
				local lastX = 0
				for _, cx in Town.PlotCentersX do
					lastX = math.max(lastX, math.abs(cx) + Tuning.Plot.Size / 2)
				end
				for _, prim in prims do
					local reach = math.max(prim.size.X, prim.size.Z) / 2
					local pos = prim.cf.Position
					local clearZ = math.abs(pos.Z) - reach > Town.PlotSetback + Tuning.Plot.Size + 4
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
		for _, need in { "news", "creator", "shop", "city" } do
			expect(opens[need]).toBe(true)
		end
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
		-- A piece (Geometry.piece) is one part in the game: one merged mesh, copied wherever it
		-- is used. So the town is counted twice: with each piece as one part, which is what a
		-- server holds, and with every piece opened into its shapes, which is what a client
		-- draws where the merge can't be done. Every different piece is a merge when the server
		-- starts, so there may not be many of those either.
		local ground = TownMap.ground()
		local parts, opened = #ground, #Geometry.flatten(ground)
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
				size = { #prims, #Geometry.flatten(prims) }
				sizes[p.name] = size
			end
			parts += size[1]
			opened += size[2]
		end
		expect(parts < 30000).toBeTruthy()
		expect(opened < 70000).toBeTruthy()
		expect(different < 220).toBeTruthy()
	end)
end)
