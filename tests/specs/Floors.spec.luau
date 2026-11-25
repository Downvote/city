--!nocheck
-- Floors, the basement and land, as the passes have them. The user: "add gamepasses, just like
-- bloxburg ... another for basement, another for more levels, another for bigger plot, (make the
-- biggest size smaller without paying smaller)". A plan holds floor -1 (the basement) up to floor 7;
-- a player builds on the first three, on all eight with Tall Builds and down a floor with Basement
-- (Sim/Floors); an old save keeps what it has on its fourth floor. A basement room is its floor: walls,
-- stairs and furniture stand over it, selling it takes along what only it held up, its dig keeps on
-- the terrain's grid inside the land and clear of the water, and a concrete lining fills its open
-- sides (Build/Basement). Land grows to 320 for everyone and to 400 with Big Plot, and land a save
-- already has stays (Sim/City).

local Shared = "ReplicatedStorage.Shared."
local Tuning = require(Shared .. "Config.Tuning")
local Plan = require(Shared .. "Build.Plan")
local Builder = require(Shared .. "Build.Builder")
local Basement = require(Shared .. "Build.Basement")
local Floors = require(Shared .. "Sim.Floors")
local City = require(Shared .. "Sim.City")
local Schema = require(Shared .. "Sim.Schema")
local StarterHouse = require(Shared .. "Data.StarterHouse")

local P = Tuning.Plot
local X0 = Plan.bounds(Plan.new()) -- the starting land's left edge on the plot
local B = Basement.Level

local function wall(x1, z1, x2, z2, lv)
	return {
		x1 = X0 + x1,
		z1 = z1,
		x2 = X0 + x2,
		z2 = z2,
		lv = lv,
		style = "wall",
		a = { c = "F2E8D5", m = "Plaster" },
		b = { c = "FFFFFF", m = "SmoothPlastic" },
	}
end
local function floor(x1, z1, x2, z2, lv)
	return { x1 = X0 + x1, z1 = z1, x2 = X0 + x2, z2 = z2, lv = lv, c = "C8B49A", m = "WoodPlanks" }
end
local function item(id, x, z, lv, y)
	return { id = id, x = X0 + x, y = y or Plan.levelBase(lv), z = z, r = 0, lv = lv }
end
local function add(kind, obj)
	return { type = "add", kind = kind, obj = obj }
end
local function noPasses()
	return { passes = {} }
end
local function owns(...)
	local p = { passes = {} }
	for _, k in { ... } do
		p.passes[k] = true
	end
	return p
end

describe("Floors", function()
	it("lets a player build on the first three floors, all eight with Tall Builds, and the basement with Basement", function()
		local lo, hi = Floors.range(noPasses())
		expect(lo).toBe(0)
		expect(hi).toBe(2)
		lo, hi = Floors.range(owns("floors"))
		expect(hi).toBe(Plan.Highest)
		expect(Plan.Highest).toBe(7)
		lo = Floors.range(owns("basement"))
		expect(lo).toBe(-1)
		expect(Plan.Lowest).toBe(-1)
		-- which pass would let them, for the floor buttons' lock
		expect(Floors.passFor(noPasses(), 3)).toBe("floors")
		expect(Floors.passFor(noPasses(), -1)).toBe("basement")
		expect(Floors.passFor(noPasses(), 2)).toBe(nil)
		expect(Floors.passFor(owns("floors"), 7)).toBe(nil)
	end)

	it("turns down a new piece past the player's floors, and stairs that would lead up into one", function()
		local plan = Plan.new()
		local ok, why = Floors.check(noPasses(), plan, { add("walls", wall(10, 10, 20, 10, 3)) })
		expect(ok).toBe(false)
		expect(why).toBe(Floors.Why.floors)
		ok = Floors.check(owns("floors"), plan, { add("walls", wall(10, 10, 20, 10, 3)) })
		expect(ok).toBe(true)
		ok, why = Floors.check(noPasses(), plan, { add("floors", floor(10, 10, 20, 20, B)) })
		expect(ok).toBe(false)
		expect(why).toBe(Floors.Why.basement)
		expect(Floors.check(owns("basement"), plan, { add("floors", floor(10, 10, 20, 20, B)) })).toBe(true)
		-- stairs on the third floor climb into the fourth
		local stairs = item("stairs_straight", 30, 30, 2)
		ok, why = Floors.check(noPasses(), plan, { add("items", stairs) })
		expect(ok).toBe(false)
		expect(why).toBe(Floors.Why.floors)
		expect(Floors.check(owns("floors"), plan, { add("items", stairs) })).toBe(true)
		-- stairs up out of the basement only need the basement
		expect(Floors.check(owns("basement"), plan, { add("items", item("stairs_straight", 30, 30, B)) })).toBe(true)
	end)

	it("keeps an old save's fourth floor whole, and lets it be repainted, moved down and sold but not added to", function()
		-- a save from when everyone had four floors (0..3)
		local raw = Plan.new()
		raw.floors["1"] = floor(10, 10, 30, 30, 3)
		raw.walls["2"] = wall(10, 10, 30, 10, 3)
		raw.items["3"] = item("chair_wood", 20, 20, 3)
		raw.items["4"] = item("light_ceiling", 20, 24, 3, Plan.levelTop(3)) -- right under the roof, as it was then
		raw.items["5"] = item("bed_single", 16, 16, 3)
		local plan = Plan.sanitize(raw)
		for _, kind in { "floors", "walls" } do
			local n = 0
			for _ in plan[kind] do
				n += 1
			end
			expect(n).toBe(1)
		end
		expect(plan.items["3"] ~= nil and plan.items["5"] ~= nil).toBe(true)
		-- the ceiling light hangs under the ceiling of the floor that can go over it now
		expect(plan.items["4"] ~= nil).toBe(true)
		expect(plan.items["4"].y).toBeNear(Plan.ceilingY(3), 1e-6)
		expect(Plan.ceilingY(3)).toBeNear(Plan.levelTop(3) - 1, 1e-6)
		-- the floors Build mode can show reach it, though the player can't build there
		local lo, hi = Floors.shown(noPasses(), plan)
		expect(lo).toBe(0)
		expect(hi).toBe(3)
		-- repainted where it is
		local painted = table.clone(plan.walls["2"])
		painted.a = { c = "AABBCC", m = "Plaster" }
		expect(Floors.check(noPasses(), plan, { { type = "set", kind = "walls", key = "2", obj = painted } })).toBe(true)
		-- moved along its floor, and down to the second
		local along = table.clone(plan.items["3"])
		along.x += 2
		expect(Floors.check(noPasses(), plan, { { type = "set", kind = "items", key = "3", obj = along } })).toBe(true)
		local down = table.clone(plan.items["3"])
		down.lv, down.y = 1, Plan.levelBase(1)
		expect(Floors.check(noPasses(), plan, { { type = "set", kind = "items", key = "3", obj = down } })).toBe(true)
		-- sold
		expect(Floors.check(noPasses(), plan, { { type = "remove", kind = "items", key = "5" } })).toBe(true)
		-- but nothing new goes up there, nor up from the second floor to there
		local ok, why = Floors.check(noPasses(), plan, { add("items", item("chair_wood", 24, 24, 3)) })
		expect(ok).toBe(false)
		expect(why).toBe(Floors.Why.floors)
		local up = table.clone(plan.items["3"])
		up.lv, up.y = 3, Plan.levelBase(3)
		local fromBelow = table.clone(up)
		plan.items["6"] = item("chair_wood", 24, 24, 1)
		ok = Floors.check(noPasses(), plan, { { type = "set", kind = "items", key = "6", obj = fromBelow } })
		expect(ok).toBe(false)
	end)

	it("holds eight floors in a plan, roofs and ceilings on the top one", function()
		local plan = Plan.new()
		expect(Plan.validate(plan, "floors", floor(10, 10, 20, 20, 7))).toBe(true)
		expect(Plan.validate(plan, "walls", wall(10, 10, 20, 10, 7))).toBe(true)
		local roof = {
			x1 = X0 + 10,
			z1 = 10,
			x2 = X0 + 20,
			z2 = 20,
			lv = 7,
			style = "gable",
			rise = 6,
			dir = 0,
			over = 1,
			c = "A8705E",
			m = "Slate",
			c2 = "F2E8D5",
			m2 = "Plaster",
		}
		expect(Plan.validate(plan, "roofs", roof)).toBe(true)
		local light = item("light_ceiling", 15, 15, 7, Plan.ceilingY(7))
		expect(Plan.ceilingY(7)).toBeNear(Plan.levelTop(7), 1e-6)
		expect(Plan.validItem(plan, light)).toBe(true)
		expect(Plan.validate(plan, "floors", floor(10, 10, 20, 20, 8))).toBe(false)
	end)
end)

describe("Basement", function()
	-- a room 20 by 16 under the ground, well inside the land
	local function room()
		local plan = Plan.new()
		plan.floors["1"] = floor(20, 20, 40, 36, B)
		plan.nextId = 2
		return plan
	end

	it("takes a room under the ground: its floor, walls round it, a door, stairs up and furniture", function()
		local plan = Plan.new()
		expect(Plan.validate(plan, "floors", floor(20, 20, 40, 36, B))).toBe(true)
		plan = room()
		-- its walls stand on it, along its edges and across it
		expect(Plan.validate(plan, "walls", wall(20, 20, 40, 20, B))).toBe(true)
		expect(Plan.validate(plan, "walls", wall(30, 20, 30, 36, B))).toBe(true)
		-- full walls run from its floor up to the ground, under the ground floor's slab
		local bottom, height = Plan.wallSpan("wall", B)
		expect(bottom).toBeNear(Plan.levelBase(B), 1e-6)
		expect(bottom + height).toBeNear(0, 1e-6)
		expect(Plan.levelBase(B)).toBeNear(P.Foundation - P.LevelHeight, 1e-6)
		plan.walls["2"] = wall(20, 20, 40, 20, B)
		local door = { id = "door_wood", x = 0, y = Plan.openingY(plan.walls["2"], 0), z = 0, r = 0, lv = B, wall = "2", t = 5, side = "a" }
		expect(Plan.validItem(plan, door)).toBe(true)
		-- furniture and a lamp on the ceiling
		expect(Plan.validItem(plan, item("bed_single", 30, 28, B))).toBe(true)
		expect(Plan.ceilingY(B)).toBeNear(0, 1e-6)
		expect(Plan.validItem(plan, item("light_ceiling", 26, 26, B, Plan.ceilingY(B)))).toBe(true)
		-- stairs up to the ground floor, cut out of the ground floor's slab
		local stairs = item("stairs_straight", 36, 28, B)
		expect(Plan.validItem(plan, stairs)).toBe(true)
		plan.items["9"] = stairs
		expect(#Plan.holes(plan, 0)).toBe(1)
		expect(#Plan.holes(plan, B)).toBe(0)
	end)

	it("keeps everything down there over a basement floor, and roofs out of it", function()
		local plan = room()
		local ok, why = Plan.validate(plan, "walls", wall(20, 50, 40, 50, B))
		expect(ok).toBe(false)
		expect(why).toBe(Basement.Why.noFloor)
		-- a wall that runs off the floor partway
		expect(Plan.validate(plan, "walls", wall(30, 30, 30, 44, B))).toBe(false)
		ok, why = Plan.validItem(plan, item("chair_wood", 60, 60, B))
		expect(ok).toBe(false)
		expect(why).toBe(Basement.Why.noFloor)
		-- half over the edge
		expect(Plan.validItem(plan, item("bed_single", 40, 28, B))).toBe(false)
		local roof = {
			x1 = X0 + 20,
			z1 = 20,
			x2 = X0 + 40,
			z2 = 36,
			lv = B,
			style = "flat",
			rise = 0,
			dir = 0,
			over = 0,
			c = "A8705E",
			m = "Slate",
			c2 = "F2E8D5",
			m2 = "Plaster",
		}
		ok, why = Plan.validate(plan, "roofs", roof)
		expect(ok).toBe(false)
		expect(why).toBe(Basement.Why.roof)
		-- nothing goes below the basement
		expect(Plan.validate(plan, "floors", floor(20, 20, 40, 36, -2))).toBe(false)
	end)

	it("keeps its dig on the terrain's grid, inside the land and clear of the water", function()
		-- a floor whose edges are off the 4 stud grid digs out to it, never more than 2 past
		for _, r in { { X0 + 22, 22, X0 + 40, 38 }, { X0 + 24, 20, X0 + 46, 34 } } do
			local block = Basement.block(r)
			for n = 1, 4 do
				expect((block[n] - Basement.Offset) % Basement.Voxel).toBeNear(0, 1e-6)
				expect(math.abs(block[n] - r[n]) <= 2 + 1e-6).toBe(true)
			end
			expect(block[1] <= r[1] and block[2] <= r[2] and block[3] >= r[3] and block[4] >= r[4]).toBe(true)
		end
		-- a floor right at the land's edge would dig past it
		local x1, z1, x2, z2 = Plan.bounds(Plan.new())
		local plan = Plan.new()
		local ok, why = Plan.validate(plan, "floors", { x1 = x1, z1 = 20, x2 = x1 + 10, z2 = 30, lv = B, c = "C8B49A", m = "WoodPlanks" })
		expect(ok).toBe(false)
		expect(why).toBe(Basement.Why.edge)
		local m = Tuning.Basement.Margin
		ok = Plan.validate(plan, "floors", { x1 = x1 + m, z1 = z1 + m, x2 = x2 - m, z2 = z2 - m, lv = B, c = "C8B49A", m = "WoodPlanks" })
		expect(ok).toBe(true)
		-- every land's margin puts the dig's edge on the grid
		for _, land in Tuning.City.Land do
			local a, b, c, d = Plan.boundsOf(land.Size)
			for _, n in { a + m, b + m, c - m, d - m } do
				expect((n - Basement.Offset) % Basement.Voxel).toBeNear(0, 1e-6)
			end
		end
		-- a pool beside a basement: their digs never share the ground. Both lie on the terrain's
		-- grid, so a floor that keeps off the water digs no further than the water's edge
		local wet = Plan.new()
		wet.waters = { ["1"] = { x1 = X0 + 42, z1 = 22, x2 = X0 + 54, z2 = 34, lv = 0, edge = "tile", depth = "swim" } }
		ok, why = Plan.validate(wet, "floors", floor(20, 20, 44, 36, B))
		expect(ok).toBe(false)
		expect(why).toBe(Basement.Why.water)
		expect(Plan.validate(wet, "floors", floor(20, 20, 40, 36, B))).toBe(true)
		expect(Basement.block({ X0 + 20, 20, X0 + 40, 36 })[3] <= X0 + 42).toBe(true)
		local dry = room()
		ok = Plan.validate(dry, "waters", { x1 = X0 + 38, z1 = 22, x2 = X0 + 50, z2 = 34, lv = 0, edge = "tile", depth = "swim" })
		expect(ok).toBe(false)
		expect(Plan.validate(dry, "waters", { x1 = X0 + 42, z1 = 22, x2 = X0 + 54, z2 = 34, lv = 0, edge = "tile", depth = "swim" })).toBe(true)
		-- (and should a dig ever reach a water, the water is turned down)
		dry.floors["1"] = floor(20, 20, 43, 36, B)
		ok, why = Basement.clearOfWater(dry, { x1 = X0 + 42, z1 = 22, x2 = X0 + 54, z2 = 34 })
		expect(ok).toBe(false)
		expect(why).toBe(Basement.Why.basement)
	end)

	it("sells a basement floor with what only it held up, and won't shrink one out from under things", function()
		local plan = room()
		plan.floors["2"] = floor(40, 20, 56, 36, B) -- a second room beside the first
		plan.walls["3"] = wall(20, 20, 40, 20, B)
		plan.items["4"] = { id = "door_wood", x = 0, y = 0, z = 0, r = 0, lv = B, wall = "3", t = 5, side = "a" }
		plan.items["5"] = item("bed_single", 30, 28, B)
		plan.items["6"] = item("chair_wood", 48, 28, B) -- in the second room
		plan.walls["7"] = wall(40, 20, 40, 36, B) -- on the line the two share
		plan.nextId = 8
		local ops = Plan.removeOps(plan, "floors", "1")
		local gone = {}
		for _, op in ops do
			gone[op.kind .. op.key] = true
		end
		expect(gone.floors1 and gone.walls3 and gone.items4 and gone.items5).toBeTruthy()
		expect(gone.items6 == nil and gone.walls7 == nil and gone.floors2 == nil).toBe(true)
		-- what went with it costs back, and undo puts all of it back
		expect(Plan.apply(plan, ops)).toBe(true)
		expect(plan.walls["3"] == nil and plan.items["4"] == nil).toBe(true)
		expect(Plan.apply(plan, Plan.invert(ops))).toBe(true)
		expect(plan.items["5"] ~= nil).toBe(true)
		-- made smaller with the bed on the part that would go
		local smaller = table.clone(plan.floors["1"])
		smaller.x2 = X0 + 26
		local ok, why = Plan.validate(plan, "floors", smaller, "1")
		expect(ok).toBe(false)
		expect(why).toBe(Basement.Why.stranded)
	end)

	it("draws its slab under the ground and a lining round its open sides, none where two rooms meet", function()
		local plan = room()
		local prims = Builder.primsFor(plan, "floors", "1")
		local slab, lining = 0, 0
		for _, p in prims do
			local top = p.cf.Position.Y + p.size.Y / 2
			local bottom = p.cf.Position.Y - p.size.Y / 2
			if p.color == Basement.LiningColor then
				lining += 1
				expect(bottom).toBeNear(Basement.Bottom, 1e-6)
				expect(top < -0.03).toBe(true) -- under the ground's own edge
			else
				slab += 1
				expect(top).toBeNear(Plan.levelBase(B), 1e-6)
				expect(bottom).toBeNear(Basement.Bottom, 1e-6)
			end
		end
		expect(slab).toBe(1)
		expect(lining).toBe(4)
		-- a second room along its east side: no lining on the side they share, and the drawing
		-- of both changes with it
		plan.floors["2"] = floor(40, 20, 56, 36, B)
		local touched = Plan.affected(plan, { { op = "add", kind = "floors", key = "2", obj = plan.floors["2"] } })
		expect(touched.floors["1"]).toBe(true)
		local count = 0
		for _, p in Builder.primsFor(plan, "floors", "1") do
			if p.color == Basement.LiningColor then
				count += 1
				-- none stands on the shared line
				local cx = p.cf.Position.X
				expect(math.abs(cx - (X0 + 40)) > 0.5).toBe(true)
			end
		end
		expect(count).toBe(3)
	end)
end)

describe("Land and Big Plot", function()
	it("grows land to 320 for everyone and to 400 with Big Plot", function()
		local p = Schema.newProfile()
		p.plan = StarterHouse.plan()
		p.plan.size = 320
		p.coins = 1e7
		p.passes = {}
		expect(City.landCap(p)).toBe(Tuning.Passes.FreeLand)
		local stats = City.stats(p)
		expect(stats.nextLand.Size).toBe(400)
		expect(stats.landLocked).toBe(true)
		local land, why = City.canExpand(p)
		expect(land).toBe(nil)
		expect(why:find("Big Plot", 1, true) ~= nil).toBe(true)
		p.passes = { bigplot = true }
		expect(City.landCap(p)).toBe(400)
		expect(City.stats(p).landLocked).toBe(false)
		-- below 320 the pass changes nothing
		p.plan.size = 256
		p.passes = {}
		expect(City.stats(p).landLocked).toBe(false)
	end)

	it("keeps the land an old save already has, without the pass", function()
		local raw = Schema.newProfile()
		raw.ownLand = nil -- a save from before Big Plot
		raw.passes = nil
		raw.plan = Plan.new(400)
		raw.plan.items["1"] = { id = "tree_oak", x = 390, y = 0, z = 390, r = 0, lv = 0 }
		local p = Schema.migrate(raw)
		expect(p.plan.size).toBe(400)
		expect(p.ownLand).toBe(400)
		expect(p.plan.items["1"] ~= nil).toBe(true)
		expect(City.landCap(p)).toBe(400)
		expect(City.stats(p).nextLand).toBe(nil)
		-- a new player owns nothing past what is free
		local fresh = Schema.migrate(Schema.newProfile())
		expect(fresh.ownLand).toBe(0)
		local mid = Schema.newProfile()
		mid.plan = Plan.new(256)
		expect(Schema.migrate(mid).ownLand).toBe(0)
	end)
end)
