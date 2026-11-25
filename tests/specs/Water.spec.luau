--!nocheck
-- Water on a plot (Build/Water): a pool or a pond dragged out in Build mode, and what may stand
-- in it. The user: "also, add ability to add water, along with things that can go in the water".
-- In the game it is terrain water (Services/Water), so its edges have to lie on the terrain's
-- grid on every plot; nothing is built over it; pieces made for water go only in it, and nothing
-- else does unless it stands up on something over it.

local Shared = "ReplicatedStorage.Shared."
local Tuning = require(Shared .. "Config.Tuning")
local Plan = require(Shared .. "Build.Plan")
local Water = require(Shared .. "Build.Water")
local Catalog = require(Shared .. "Build.Catalog")
local Geometry = require(Shared .. "Build.Geometry")
local Town = require(Shared .. "Data.Town")

-- the starting land: x from X0, z from 0, on the plot's own grid; a water's edges are 2 past it
local X0 = Plan.bounds(Plan.new())

local function water(x1, z1, x2, z2, edge, depth)
	return { x1 = X0 + x1, z1 = z1, x2 = X0 + x2, z2 = z2, lv = 0, edge = edge or "tile", depth = depth or "swim" }
end

local function wall(x1, z1, x2, z2, style)
	return {
		x1 = X0 + x1,
		z1 = z1,
		x2 = X0 + x2,
		z2 = z2,
		lv = 0,
		style = style or "wall",
		a = { c = "F2E8D5", m = "Plaster" },
		b = { c = "FFFFFF", m = "SmoothPlastic" },
	}
end

-- a plan with one tiled pool 16 by 12, deep enough to swim in, at x 22..38, z 150..162
local function withPool(edge, depth)
	local plan = Plan.new()
	assert(Plan.apply(plan, { { op = "add", kind = "waters", key = "1", obj = water(22, 150, 38, 162, edge, depth) } }))
	return plan
end

local function piece(id, x, z, r, y)
	local def = Catalog.get(id)
	assert(def, "no piece " .. id)
	return { id = id, x = X0 + x, y = y or Water.pieceY(def), z = z, r = r or 0, lv = 0 }
end

describe("Water", function()
	it("lies on the terrain's grid on every plot, so it fills whole voxels", function()
		for i = 1, Tuning.Plot.Count do
			local frame = Town.plotFrame(i)
			for _, depth in Water.DepthOrder do
				local w = { x1 = 102, z1 = 6, x2 = 118, z2 = 30, lv = 0, edge = "tile", depth = depth }
				local lo, hi, fill = Water.voxels(w)
				for _, corner in { frame * lo, frame * hi } do
					for _, n in { corner.X, corner.Y, corner.Z } do
						expect(math.abs(n / Water.Voxel - math.floor(n / Water.Voxel + 0.5)) < 1e-3).toBeTruthy()
					end
				end
				-- full under the top layer, which is filled to the surface
				expect(#fill).toBe(Water.Depths[depth].layers)
				for k = 1, #fill - 1 do
					expect(fill[k]).toBe(1)
				end
				expect(fill[#fill]).toBeNear((Water.Surface + Water.Voxel) / Water.Voxel)
			end
		end
		-- the drag snaps to the same lines, inside the land
		expect(Water.snap(X0 + 13.1, X0, X0 + 200)).toBe(X0 + 14)
		expect(Water.snap(X0 - 30, X0, X0 + 200)).toBe(X0 + 2)
		expect(Water.snap(X0 + 260, X0, X0 + 200)).toBe(X0 + 198)
	end)

	it("has solid sides all the way down: the plot's ground part, then the terrain under it", function()
		-- the terrain under a plot lies a voxel down (Data/Terrain's PlotFloor) and the plot's own
		-- ground part (World's Base, which the Water service cuts round a pool, its pieces as deep)
		-- reaches down to it, so every depth of water is dug at least that deep: no gap of air is
		-- left between the part's sides and the water, and under it the terrain is solid
		local Terrain = require("ReplicatedStorage.Shared.Data.Terrain")
		for _, depth in Water.DepthOrder do
			local w = { x1 = 102, z1 = 6, x2 = 118, z2 = 30, lv = 0, edge = "tile", depth = depth }
			local lo = Water.voxels(w)
			expect(lo.Y <= Terrain.PlotFloor + 1e-6).toBe(true)
			-- and its floor is above the bottom of what is dug, so it stands in the water
			expect(Water.Depths[depth].floor > lo.Y).toBe(true)
		end
		expect((Terrain.PlotFloor / Water.Voxel) % 1).toBe(0)
	end)

	it("takes a good pool and refuses one off the grid, off the land, too small, too big or upstairs", function()
		local plan = Plan.new()
		expect(Plan.validate(plan, "waters", water(22, 150, 38, 162))).toBe(true)
		expect(Plan.validate(plan, "waters", water(22, 150, 38, 162, "pond", "shallow"))).toBe(true)
		local function refused(w, why)
			local ok, err = Plan.validate(plan, "waters", w)
			expect(ok).toBe(false)
			if why then
				expect(err).toBe(why)
			end
		end
		refused(water(20, 150, 38, 162), "off the grid")
		refused(water(-6, 150, 10, 162), "outside your land")
		refused(water(22, 190, 38, 202), "outside your land")
		refused(water(22, 150, 26, 162), "too small")
		refused(water(22, 2, 22 + Tuning.Water.MaxSide + 4, 30), "too big")
		local up = water(22, 150, 38, 162)
		up.lv = 1
		refused(up, "water goes on the ground floor")
		local odd = water(22, 150, 38, 162)
		odd.edge = "lava"
		refused(odd, "bad edge")
		local deep = water(22, 150, 38, 162)
		deep.depth = "abyss"
		refused(deep, "bad depth")
		refused({ x1 = 0 / 0 }, "bad number")
		refused("a lake")
		expect(Plan.limit("waters")).toBe(Tuning.Water.Max)
	end)

	it("keeps clear of walls, floors, roofs and other water, whichever went first", function()
		local plan = withPool()
		local function ok(kind, obj)
			return (Plan.validate(plan, kind, obj))
		end
		-- another pool over it, or touching it
		expect(ok("waters", water(30, 158, 46, 170))).toBe(false)
		expect(ok("waters", water(38, 150, 50, 162))).toBe(true)
		-- a wall across it is refused; one along its edge (a fence round a pool) is fine
		expect(ok("walls", wall(20, 156, 40, 156))).toBe(false)
		expect(ok("walls", wall(18, 150, 42, 150, "fence"))).toBe(true)
		-- floors and roofs over it, but a deck beside it is fine
		local floor = { x1 = X0 + 24, z1 = 140, x2 = X0 + 30, z2 = 154, lv = 0, c = "C8B49A", m = "WoodPlanks" }
		expect(ok("floors", floor)).toBe(false)
		floor.z2 = 150
		expect(ok("floors", floor)).toBe(true)
		local roof = {
			x1 = X0 + 30,
			z1 = 156,
			x2 = X0 + 50,
			z2 = 170,
			lv = 0,
			style = "gable",
			rise = 6,
			dir = 0,
			over = 1,
			c = "9C2A2E",
			m = "Slate",
			c2 = "F2E8D5",
			m2 = "Plaster",
		}
		expect(ok("roofs", roof)).toBe(false)
		-- and the other way round: no water where they already are
		local built = Plan.new()
		assert(Plan.apply(built, { { op = "add", kind = "floors", key = "1", obj = floor } }))
		floor.z2 = 154
		Plan.apply(built, { { op = "set", kind = "floors", key = "1", obj = floor } })
		expect(Plan.validate(built, "waters", water(22, 150, 38, 162))).toBe(false)
		assert(Plan.apply(built, { { op = "add", kind = "walls", key = "2", obj = wall(10, 156, 30, 156) } }))
		local ok2, why = Plan.validate(built, "waters", water(2, 162, 18, 174))
		expect(ok2).toBe(true)
		ok2, why = Plan.validate(built, "waters", water(14, 150, 22, 162))
		expect(ok2).toBe(false)
		expect(why).toBe("there's a wall in the way")
	end)

	it("lets pieces made for water go only in it, at their own height", function()
		local plan = withPool()
		local function ok(item)
			return (Plan.validItem(plan, item))
		end
		-- floating in the middle
		expect(ok(piece("water_lilies", 30, 156))).toBe(true)
		expect(ok(piece("water_boat", 30, 156, 90))).toBe(true)
		-- on dry ground, at the wrong height, upstairs, or over the coping
		expect(ok(piece("water_lilies", 60, 120))).toBe(false)
		expect(ok(piece("water_lilies", 30, 156, 0, 0))).toBe(false)
		local up = piece("water_lilies", 30, 156)
		up.lv = 1
		expect(ok(up)).toBe(false)
		local _, why = Plan.validItem(plan, piece("water_lilies", 24, 156))
		expect(why).toBe("too close to the edge")
		-- standing on the bottom only where it's shallow
		local _, deep = Plan.validItem(plan, piece("water_reeds", 30, 156))
		expect(deep).toBe("that needs shallow water")
		local pond = withPool("pond", "shallow")
		expect((Plan.validItem(pond, piece("water_reeds", 30, 156)))).toBe(true)
		expect((Plan.validItem(pond, piece("water_stones", 30, 156)))).toBe(true)
		-- at the edge: half over the water, half on the side
		expect(ok(piece("water_ladder", 30, 150))).toBe(true)
		expect(ok(piece("water_jetty", 30, 148))).toBe(true)
		expect(ok(piece("water_ladder", 30, 156))).toBe(false)
		local _, dry = Plan.validItem(plan, piece("water_ladder", 30, 130))
		expect(dry).toBe("that goes at the edge of a pool or a pond")
		-- the lifebuoy stand goes beside it, on the ground
		expect(ok(piece("water_buoy", 30, 146, 0, 0))).toBe(true)
		expect(ok(piece("water_buoy", 30, 156, 0, 0))).toBe(false)
	end)

	it("keeps everything else out of the water unless it stands on something over it", function()
		local plan = withPool()
		local tree = { id = "tree_oak", x = X0 + 30, y = 0.01, z = 156, r = 0, lv = 0 }
		local ok, why = Plan.validItem(plan, tree)
		expect(ok).toBe(false)
		expect(why).toBe("that can't go in the water")
		-- on the water itself (where the pointer meets it), still no
		tree.y = Water.Surface
		expect((Plan.validItem(plan, tree))).toBe(false)
		-- up on a raft or the rim it's fine, and upstairs nothing is in the water
		tree.y = 0.3
		expect((Plan.validItem(plan, tree))).toBe(true)
		-- beside the pool it's the usual rules
		local beside = { id = "tree_oak", x = X0 + 30, y = 0.01, z = 140, r = 0, lv = 0 }
		expect((Plan.validItem(plan, beside))).toBe(true)
		-- and a pool can't be dug where something stands
		local garden = Plan.new()
		assert(Plan.apply(garden, { { op = "add", kind = "items", key = "1", obj = beside } }))
		local dug, said = Plan.validate(garden, "waters", water(22, 134, 38, 146))
		expect(dug).toBe(false)
		expect(said).toBe("move what's standing there first")
		-- nor made shallow under a boat that floats, or deep under reeds
		local pond = withPool("pond", "shallow")
		assert(Plan.apply(pond, { { op = "add", kind = "items", key = "9", obj = piece("water_reeds", 30, 156) } }))
		local deeper = table.clone(pond.waters["1"])
		deeper.depth = "swim"
		local deepened, reason = Plan.validate(pond, "waters", deeper, "1")
		expect(deepened).toBe(false)
		expect(reason).toBe("take out what's in the water first")
		deeper.depth = "shallow"
		deeper.edge = "stone"
		expect((Plan.validate(pond, "waters", deeper, "1"))).toBe(true)
	end)

	it("costs more the bigger and the deeper it is", function()
		local s = Tuning.Plot.WallSnap
		local cells = (16 / s) * (12 / s)
		expect(Plan.cost("waters", water(22, 150, 38, 162))).toBe(cells * Tuning.Water.PerCell.swim)
		expect(Plan.cost("waters", water(22, 150, 38, 162, "pond", "shallow"))).toBe(
			cells * Tuning.Water.PerCell.shallow
		)
		expect(Tuning.Water.PerCell.swim > Tuning.Water.PerCell.shallow).toBeTruthy()
	end)

	it("takes what is in it along when it is sold, and undo puts it all back", function()
		local plan = withPool()
		assert(Plan.apply(plan, {
			{ op = "add", kind = "items", key = "2", obj = piece("water_lilies", 30, 156) },
			{ op = "add", kind = "items", key = "3", obj = piece("water_ladder", 30, 150) },
			{
				op = "add",
				kind = "items",
				key = "4",
				obj = { id = "tree_oak", x = X0 + 30, y = 0.01, z = 140, r = 0, lv = 0 },
			},
		}))
		local ops = Plan.removeOps(plan, "waters", "1")
		expect(#ops).toBe(3)
		expect(ops[#ops].kind).toBe("waters")
		local refund = -Plan.changeCost(ops)
		expect(refund).toBe(
			Plan.cost("waters", plan.waters["1"])
				+ Catalog.get("water_lilies").price
				+ Catalog.get("water_ladder").price
		)
		assert(Plan.apply(plan, ops))
		expect(next(plan.waters)).toBe(nil)
		expect(plan.items["4"] ~= nil).toBeTruthy()
		assert(Plan.apply(plan, Plan.invert(ops)))
		expect(plan.waters["1"] ~= nil and plan.items["2"] ~= nil and plan.items["3"] ~= nil).toBeTruthy()
		-- and it is drawn again when it changes
		local affected = Plan.affected(plan, ops)
		expect(affected.waters["1"]).toBe(true)
	end)

	it("keeps only a water's own fields, and loads only what still fits", function()
		local junk = water(22, 150, 38, 162)
		junk.extra = "x"
		junk.edge = string.rep("e", 40)
		local clean = Plan.clean("waters", junk)
		expect(clean.extra).toBe(nil)
		expect(clean.edge).toBe(nil)
		expect(clean.x1).toBe(junk.x1)
		-- a save: a good pool with a lily on it, a pool over it, a lily with no water and a boat
		-- in the good pool
		local raw = {
			v = Plan.Version,
			size = 200,
			nextId = 1,
			walls = {},
			floors = {},
			roofs = {},
			waters = { ["1"] = water(22, 150, 38, 162), ["2"] = water(30, 154, 46, 166) },
			items = {
				["3"] = piece("water_lilies", 30, 156),
				["4"] = piece("water_lilies", 70, 40),
			},
		}
		local plan = Plan.sanitize(raw)
		local n = 0
		for _ in plan.waters do
			n += 1
		end
		expect(n).toBe(1)
		expect(plan.items["4"]).toBe(nil)
		-- the lily is in whichever pool was kept, or dropped with the other
		local kept = next(plan.waters)
		expect(kept == "1" or kept == "2").toBeTruthy()
		-- a save from before there was water loads with none
		local old =
			Plan.sanitize({ v = Plan.Version, size = 200, nextId = 1, walls = {}, floors = {}, roofs = {}, items = {} })
		expect(type(old.waters)).toBe("table")
		expect(next(old.waters)).toBe(nil)
		expect(Plan.count({ walls = {} }, "waters")).toBe(0)
	end)

	it("draws its rim and lining inside its rectangle, and the water only where asked", function()
		for _, edge in Water.EdgeOrder do
			for _, depth in Water.DepthOrder do
				local w = water(22, 150, 38, 162, edge, depth)
				local prims = Water.prims(w)
				expect(#prims > 8).toBeTruthy()
				local lo, hi = Geometry.bounds(prims)
				-- reeds lean a little past the bank; everything else keeps inside
				expect(lo.X >= w.x1 - 0.6 and hi.X <= w.x2 + 0.6).toBeTruthy()
				expect(lo.Z >= w.z1 - 0.6 and hi.Z <= w.z2 + 0.6).toBeTruthy()
				expect(lo.Y >= -Water.Depths[depth].layers * Water.Voxel - 1e-3).toBeTruthy()
				local surface = 0
				for _, p in prims do
					if p.name == "WaterSurface" then
						surface += 1
						expect(p.collide).toBe(false)
						expect(p.transp > 0.2).toBeTruthy()
					end
					expect((Enum.Material :: any)[p.mat] ~= nil).toBeTruthy()
				end
				expect(surface).toBe(1)
			end
		end
		-- the server turns the slab off: there the terrain is the water
		Water.drawSurface = false
		for _, p in Water.prims(water(22, 150, 38, 162)) do
			expect(p.name ~= "WaterSurface").toBeTruthy()
		end
		Water.drawSurface = true
	end)

	it("cuts the ground round the water and leaves the rest whole", function()
		local holes = { { 22, 150, 38, 162 }, { 50, 10, 58, 30 } }
		local pieces = Water.cutRects({ 0, 0, 200, 200 }, holes)
		local area = 0
		for i, r in pieces do
			expect(r[3] > r[1] and r[4] > r[2]).toBeTruthy()
			area += (r[3] - r[1]) * (r[4] - r[2])
			for _, h in holes do
				local over = r[1] < h[3] and h[1] < r[3] and r[2] < h[4] and h[2] < r[4]
				expect(over).toBe(false)
			end
			for j, q in pieces do
				if i ~= j then
					local over = r[1] < q[3] and q[1] < r[3] and r[2] < q[4] and q[2] < r[4]
					expect(over).toBe(false)
				end
			end
		end
		expect(area).toBeNear(200 * 200 - 16 * 12 - 8 * 20)
		local holesOf = Water.holes(withPool())
		expect(#holesOf).toBe(1)
	end)
end)
