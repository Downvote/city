--!nocheck
-- Patches of other greens on a player's lawn (Data/LawnPatches). The user asked for "varied
-- grass": the plot was one flat green sheet. Here: the same layout every time for a plot, every
-- box on the land, the patches apart, the layers at their own heights, all of it green.

local Shared = "ReplicatedStorage.Shared."
local LawnPatches = require(Shared .. "Data.LawnPatches")

local function corners(b)
	local a = math.rad(b.yaw)
	local c, s = math.cos(a), math.sin(a)
	local out = {}
	for _, d in { { 1, 1 }, { 1, -1 }, { -1, 1 }, { -1, -1 } } do
		local lx, lz = d[1] * b.sx / 2, d[2] * b.sz / 2
		table.insert(out, { b.x + lx * c + lz * s, b.z - lx * s + lz * c })
	end
	return out
end

describe("LawnPatches", function()
	it("lays the same patches for the same plot", function()
		local a = LawnPatches.layout(42, 100, 0, 300, 200)
		local b = LawnPatches.layout(42, 100, 0, 300, 200)
		expect(#a).toBe(#b)
		for i = 1, #a do
			expect(a[i].x).toBe(b[i].x)
			expect(a[i].yaw).toBe(b[i].yaw)
		end
	end)

	it("keeps every box on the land, and a fair number of patches", function()
		for _, size in { 200, 256, 320, 400 } do
			local x1 = (400 - size) / 2
			local boxes = LawnPatches.layout(size, x1, 0, x1 + size, size)
			expect(#boxes >= 2 * math.min(LawnPatches.Most, size * size / LawnPatches.Every) * 0.6).toBeTruthy()
			expect(#boxes <= 3 * LawnPatches.Most).toBeTruthy()
			for _, b in boxes do
				for _, p in corners(b) do
					expect(p[1] > x1 and p[1] < x1 + size).toBeTruthy()
					expect(p[2] > 0 and p[2] < size).toBeTruthy()
				end
			end
		end
	end)

	it("puts each layer at its own height, over the grass and under a floor", function()
		for _, b in LawnPatches.layout(7, 0, 0, 200, 200) do
			local k = (b.top - LawnPatches.Base) / LawnPatches.Lift
			expect(math.abs(k - math.floor(k + 0.5)) < 1e-6).toBeTruthy()
			expect(b.top > LawnPatches.Base + 0.02).toBeTruthy()
			-- (a ground floor's slab is 0.4 tall, so a patch under one never shows through it)
			expect(b.top < 0.2).toBeTruthy()
		end
	end)

	it("only uses greens", function()
		for _, b in LawnPatches.layout(9, 0, 0, 200, 200) do
			expect(b.color[2] > b.color[1] and b.color[2] > b.color[3]).toBeTruthy()
		end
	end)
end)
