--!nocheck
-- The town beyond the plots: every place to find is in the town, off the plots, on something you
-- can stand on, and the explorer goal asks for all of them. (The city pack's layout has its own
-- spec, Town.)

local Shared = "ReplicatedStorage.Shared."
local Tuning = require(Shared .. "Config.Tuning")
local Town = require(Shared .. "Data.Town")
local CityMap = require(Shared .. "Data.CityMap")
local Places = require(Shared .. "Data.Places")
local Goals = require(Shared .. "Data.Goals")

describe("The glow", function()
	it("starts above white, and is gentle", function()
		-- the user: "the bloom might be too much". With a threshold under 1 anything pale glowed
		-- (a white wall in the sun), and at nearly full strength a lamp washed the view out
		local bloom = Tuning.Look.Bloom
		expect(bloom.Threshold >= 1.5).toBeTruthy()
		expect(bloom.Threshold <= 2.5).toBeTruthy() -- lamps and signs still glow after dark
		expect(bloom.Intensity > 0 and bloom.Intensity <= 0.5).toBeTruthy()
		expect(bloom.Size >= 8 and bloom.Size <= 24).toBeTruthy()
	end)
end)

describe("Places", function()
	it("are all in the town, off the plots, on something to stand on and out of the buildings", function()
		local seen = {}
		for _, p in Places.list do
			expect(seen[p.id]).toBe(nil)
			seen[p.id] = true
			expect(CityMap.inPack(p.pos)).toBeTruthy()
			expect(p.coins >= 0 and p.radius > 0).toBeTruthy()
			expect(p.name:find("\u{2014}") == nil and p.blurb:find("\u{2014}") == nil).toBeTruthy()
			for i = 1, Tuning.Plot.Count do
				local on, at = Town.toPlot(i, p.pos)
				expect(on and at.Z > 0.5).toBeFalsy()
			end
			expect(Places.near(p, p.pos)).toBeTruthy()
			expect(Places.near(p, p.pos + Vector3.new(p.radius + 5, 0, 0))).toBeFalsy()
			-- something you stand on is under it, about at its height (a road, a lot, the land, a
			-- hill, the bridge), and no building is round it
			local under = false
			for _, q in CityMap.placements() do
				local over = p.pos.X >= q.lo.X and p.pos.X <= q.hi.X and p.pos.Z >= q.lo.Z and p.pos.Z <= q.hi.Z
				if
					over
					and (q.kind == "road" or q.kind == "ground")
					and p.pos.Y >= q.lo.Y - 1
					and p.pos.Y <= q.hi.Y + 1
				then
					under = true
				end
				if over and q.kind == "building" and p.pos.Y < q.hi.Y and p.pos.Y > q.lo.Y + 2 then
					error(p.id .. " is inside " .. q.key)
				end
			end
			if not under then
				error(p.id .. " has nothing to stand on at " .. tostring(p.pos))
			end
		end
	end)

	it("are all counted by the explorer goal", function()
		local all = Goals.get("exploreAll")
		expect(all ~= nil).toBeTruthy()
		-- the green is found where you arrive, so it counts too
		expect(all.need).toBe(#Places.list)
	end)
end)
