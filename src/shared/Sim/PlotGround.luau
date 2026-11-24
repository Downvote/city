--!strict
-- The ground of a player's plot, as terrain: Roblox's own long grass (Grass, with Terrain.Decoration on)
-- on the land the player owns, and the short leafy kind (LeafyGrass, which grows no blades) on land
-- not yet bought and under everything built, so no blade comes up through a floor, a wall or a
-- sofa. The user, with a picture of tall grass from Roblox's announcement of it: "can you use
-- realistic grass?" The plot's own grass parts are invisible floors over it (Services/Plots).
--
-- Terrain is in voxels of 4 studs, on the world's grid. This works out, for a plot and its plan,
-- which voxel columns get the long grass, as runs along x: { x1, z1, x2, z2 } in world studs, each
-- a whole number of voxels. Everything else in the plot is leafy.

local Plan = require(script.Parent.Parent.Build.Plan)
local Builder = require(script.Parent.Parent.Build.Builder)
local Geometry = require(script.Parent.Parent.Build.Geometry)

local PlotGround = {}

PlotGround.Voxel = 4
PlotGround.Margin = 1 -- no blades within this of anything built (they lean)
PlotGround.Touch = 1.5 -- a shape whose bottom is lower than this (plot local) stands on the ground

type Rect = { number } -- x1, z1, x2, z2

-- What stands on the ground in a plan: a rect in the world for every shape low enough to touch it.
function PlotGround.built(plan: Plan.PlanData, frame: CFrame): { Rect }
	local out: { Rect } = {}
	for _, kind in Plan.Kinds do
		for key in (plan :: any)[kind] do
			local prims = Builder.primsFor(plan, kind, key)
			if prims then
				for _, p in Geometry.flatten(prims) do
					local lo, hi = Geometry.bounds({ p })
					if lo.Y < PlotGround.Touch and (p.transp or 0) < 0.99 then
						local x1, z1, x2, z2 = math.huge, math.huge, -math.huge, -math.huge
						for _, c in { Vector3.new(lo.X, 0, lo.Z), Vector3.new(hi.X, 0, hi.Z) } do
							local w = frame * c
							x1, z1 = math.min(x1, w.X), math.min(z1, w.Z)
							x2, z2 = math.max(x2, w.X), math.max(z2, w.Z)
						end
						table.insert(out, { x1, z1, x2, z2 })
					end
				end
			end
		end
	end
	return out
end

-- The plot's whole square in the world, shrunk to whole voxels (so nothing outside it is touched).
function PlotGround.square(frame: CFrame, size: number): Rect
	local V = PlotGround.Voxel
	local a, b = frame * Vector3.zero, frame * Vector3.new(size, 0, size)
	local x1, x2 = math.min(a.X, b.X), math.max(a.X, b.X)
	local z1, z2 = math.min(a.Z, b.Z), math.max(a.Z, b.Z)
	return { math.ceil(x1 / V) * V, math.ceil(z1 / V) * V, math.floor(x2 / V) * V, math.floor(z2 / V) * V }
end

-- The runs of long grass: voxel columns inside the owned land (wholly) and clear of anything
-- built (with the margin).
function PlotGround.grass(plan: Plan.PlanData, frame: CFrame, size: number): { Rect }
	local V, m = PlotGround.Voxel, PlotGround.Margin
	local sq = PlotGround.square(frame, size)
	-- the owned land in the world
	local lx1, lz1, lx2, lz2 = Plan.bounds(plan)
	local a, b = frame * Vector3.new(lx1, 0, lz1), frame * Vector3.new(lx2, 0, lz2)
	local ox1, ox2 = math.min(a.X, b.X), math.max(a.X, b.X)
	local oz1, oz2 = math.min(a.Z, b.Z), math.max(a.Z, b.Z)
	local nx, nz = (sq[3] - sq[1]) // V, (sq[4] - sq[2]) // V
	if nx <= 0 or nz <= 0 then
		return {}
	end
	-- which columns are covered
	local covered: { boolean } = table.create(nx * nz, false)
	for _, r in PlotGround.built(plan, frame) do
		local i1 = math.max(0, math.floor((r[1] - m - sq[1]) / V))
		local i2 = math.min(nx - 1, math.ceil((r[3] + m - sq[1]) / V) - 1)
		local j1 = math.max(0, math.floor((r[2] - m - sq[2]) / V))
		local j2 = math.min(nz - 1, math.ceil((r[4] + m - sq[2]) / V) - 1)
		for j = j1, j2 do
			for i = i1, i2 do
				covered[j * nx + i + 1] = true
			end
		end
	end
	local out: { Rect } = {}
	for j = 0, nz - 1 do
		local z1 = sq[2] + j * V
		local start: number? = nil
		for i = 0, nx do
			local x1 = sq[1] + i * V
			local ok = i < nx
				and not covered[j * nx + i + 1]
				and x1 >= ox1
				and x1 + V <= ox2
				and z1 >= oz1
				and z1 + V <= oz2
			if ok and not start then
				start = x1
			elseif not ok and start then
				table.insert(out, { start, z1, x1, z1 + V })
				start = nil
			end
		end
	end
	return out
end

return PlotGround
