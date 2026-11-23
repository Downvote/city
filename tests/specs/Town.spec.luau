--!nocheck
-- The town map: every placed model exists, nothing stands on a plot or in the road, the
-- sidewalks leave room to walk, and the panels' buildings are all there.

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
				-- a hill: only the dome above the ground counts, and it must stay clear of every plot
				for _, prim in prims do
					local radius = prim.size.X / 2
					local depth = -prim.cf.Position.Y
					local footprint = math.sqrt(math.max(0, radius * radius - depth * depth))
					local nearest = math.abs(prim.cf.Position.Z) - footprint
					if nearest < Town.PlotSetback + Tuning.Plot.Size + 4 then
						error(p.name .. " reaches the plots at z " .. tostring(prim.cf.Position.Z))
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
		expect(#TownMap.ground()).toBeBetween(100, 2500)
	end)
end)
