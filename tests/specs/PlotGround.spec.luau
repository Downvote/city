--!nocheck
-- A plot's ground (Sim/PlotGround): Roblox's long grass on the land the player owns, never under
-- anything built (the user: "can you use realistic grass?"; blades come up through a floor).

local Shared = "ReplicatedStorage.Shared."
local Tuning = require(Shared .. "Config.Tuning")
local Town = require(Shared .. "Data.Town")
local StarterHouse = require(Shared .. "Data.StarterHouse")
local PlotGround = require(Shared .. "Sim.PlotGround")

local size = Tuning.Plot.Size

local function overlaps(a, b)
	return a[1] < b[3] and a[3] > b[1] and a[2] < b[4] and a[4] > b[2]
end

describe("PlotGround", function()
	for _, i in { 1, 2 } do
		local frame = Town.plotFrame(i)
		local plan = StarterHouse.plan()
		local runs = PlotGround.grass(plan, frame, size)

		it("grows long grass on a good part of plot " .. i .. "'s land", function()
			local area = 0
			for _, r in runs do
				area += (r[3] - r[1]) * (r[4] - r[2])
			end
			expect(#runs > 0).toBeTruthy()
			expect(area > 400).toBeTruthy()
		end)

		it("keeps it on whole voxels inside plot " .. i, function()
			local sq = PlotGround.square(frame, size)
			for _, r in runs do
				for _, v in r do
					expect(v % PlotGround.Voxel).toBe(0)
				end
				expect(r[1] >= sq[1] and r[3] <= sq[3] and r[2] >= sq[2] and r[4] <= sq[4]).toBeTruthy()
			end
		end)

		it("never under anything built on plot " .. i, function()
			for _, b in PlotGround.built(plan, frame) do
				for _, r in runs do
					expect(overlaps(r, b)).toBe(false)
				end
			end
		end)
	end

	it("grows none on a plot with no land bought", function()
		local plan = StarterHouse.plan()
		plan.size = 0
		local runs = PlotGround.grass(plan, Town.plotFrame(1), size)
		expect(#runs).toBe(0)
	end)
end)
