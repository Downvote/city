--!nocheck
-- Ways between floors (the user: "make ways to travel down, like different hole types, and add
-- elevators"): Build/Recipes/Travel (a loft hatch, a trapdoor, a fire pole, a slide, lifts) and the
-- open stairwell in Recipes/Structure; the holes they cut (Plan.holes), the floors they reach
-- (Plan.validItem, Sim/Floors), what of them is solid, and a lift's ride (Sim/Lifts).

local Shared = "ReplicatedStorage.Shared."
local Tuning = require(Shared .. "Config.Tuning")
local Catalog = require(Shared .. "Build.Catalog")
local Plan = require(Shared .. "Build.Plan")
local Solid = require(Shared .. "Build.Solid")
local Geometry = require(Shared .. "Build.Geometry")
local Floors = require(Shared .. "Sim.Floors")
local Lifts = require(Shared .. "Sim.Lifts")

local H = Tuning.Plot.LevelHeight
local HOLES = { "hole_hatch", "hole_trapdoor", "hole_pole", "hole_slide", "stairwell" }
local LIFTS = { "lift_2", "lift_3", "lift_4", "lift_5" }

local function item(id, x, z, lv, r)
	return { id = id, x = x, y = Plan.levelBase(lv), z = z, r = r or 0, lv = lv }
end

local function solidParts(def)
	return Geometry.flatten(Solid.apply(def, Catalog.prims(def)))
end

describe("Travel", function()
	it("lists every way between floors in Build mode, priced, going down on the floor like stairs", function()
		for _, id in { table.unpack(HOLES), table.unpack(LIFTS) } do
			local def = Catalog.get(id)
			expect(def ~= nil).toBe(true)
			expect(def.cat).toBe("structure")
			expect(def.place).toBe("stairs")
			expect(def.price > 0).toBe(true)
			expect(def.travel ~= nil).toBe(true)
			-- its hole lies inside its footprint
			local h = def.hole
			expect(h ~= nil).toBe(true)
			expect(h[1] >= -def.size.X / 2 - 1e-6 and h[3] <= def.size.X / 2 + 1e-6).toBe(true)
			expect(h[2] >= -def.size.Z / 2 - 1e-6 and h[4] <= def.size.Z / 2 + 1e-6).toBe(true)
			expect(h[3] - h[1] >= 2.8 and h[4] - h[2] >= 2.8).toBe(true) -- room for somebody
		end
		-- the lifts climb one more floor each, and cost more the higher they go
		for i, id in LIFTS do
			local def = Catalog.get(id)
			expect(Lifts.spans(def)).toBe(i)
			expect(def.size.Y >= i * H + Lifts.Car.height).toBe(true)
			if i > 1 then
				expect(def.price > Catalog.get(LIFTS[i - 1]).price).toBe(true)
			end
		end
	end)

	it("cuts its hole, turned as it stands, in the floor over it, and a lift's in every floor it runs up", function()
		local plan = Plan.new(400)
		plan.items["1"] = item("hole_slide", 200, 100, 0, 90)
		local holes = Plan.holes(plan, 1)
		expect(#holes).toBe(1)
		-- the slide's hole is at its top end, its -z, turned a quarter to -x: 7 along x and 4 across
		local h = holes[1]
		expect(h[3] - h[1]).toBeNear(7, 1e-6)
		expect(h[4] - h[2]).toBeNear(4, 1e-6)
		expect(h[1]).toBeNear(200 - 8, 1e-6)
		expect(#Plan.holes(plan, 2)).toBe(0)

		local lift = Plan.new(400)
		lift.items["1"] = item("lift_4", 200, 100, 0)
		for lv = 1, 3 do
			expect(#Plan.holes(lift, lv)).toBe(1)
		end
		expect(#Plan.holes(lift, 4)).toBe(0)
		for lv = 1, 4 do
			lift.floors[tostring(10 + lv)] =
				{ x1 = 190, z1 = 90, x2 = 210, z2 = 110, lv = lv, c = "C8B49A", m = "WoodPlanks" }
		end
		local touched = Plan.affected(lift, { { op = "add", kind = "items", key = "1", obj = lift.items["1"] } })
		expect(touched.floors["11"] and touched.floors["12"] and touched.floors["13"]).toBe(true)
		expect(touched.floors["14"]).toBe(nil)
	end)

	it("needs a floor over every floor it runs up to, and the passes for them", function()
		local plan = Plan.new(400)
		expect((Plan.validItem(plan, item("lift_5", 200, 100, 3)))).toBe(true)
		local ok, why = Plan.validItem(plan, item("lift_5", 200, 100, 4))
		expect(ok).toBe(false)
		expect(why).toBe("no floor above")
		expect((Plan.validItem(plan, item("hole_hatch", 200, 100, Plan.Highest)))).toBe(false)
		-- without Tall Builds the third floor is the top: a lift from the second up two goes past it
		local profile = { passes = {} }
		local add = function(obj)
			return { type = "add", kind = "items", obj = obj }
		end
		expect((Floors.check(profile, plan, { add(item("lift_2", 200, 100, 1)) }))).toBe(true)
		expect((Floors.check(profile, plan, { add(item("lift_3", 200, 100, 1)) }))).toBe(false)
		expect((Floors.check({ passes = { floors = true } }, plan, { add(item("lift_3", 200, 100, 1)) }))).toBe(true)
	end)

	it("gives the ladders rungs a hand's reach apart, all solid, and the slide a slope you can walk", function()
		for _, id in { "hole_hatch", "hole_trapdoor" } do
			local def = Catalog.get(id)
			local ys = {}
			for _, p in solidParts(def) do
				expect(p.collide ~= false).toBe(true)
				if p.shape == "Cylinder" and p.size.X > 2 and p.size.X < 2.6 then
					table.insert(ys, p.cf.Position.Y)
				end
			end
			table.sort(ys)
			expect(#ys >= 13).toBe(true)
			expect(ys[1] < 1).toBe(true)
			expect(ys[#ys] > H).toBe(true) -- up past the floor over it
			for i = 2, #ys do
				expect(ys[i] - ys[i - 1] <= 1).toBe(true)
			end
		end
		-- the slide's chute: no steeper than 50 degrees anywhere, from the hole down to the floor
		local def = Catalog.get("hole_slide")
		local steepest = 0
		for _, p in Catalog.prims(def) do
			if p.mat == "Metal" and p.shape == "Block" and p.size.X > 3 then
				local up = p.cf.UpVector
				steepest = math.max(steepest, math.deg(math.acos(math.clamp(math.abs(up.Y), 0, 1))))
			end
		end
		expect(steepest > 30 and steepest < 50).toBe(true)
	end)

	it("keeps what moves in a lift from being solid, with a hidden floor and gate at every landing", function()
		for _, id in LIFTS do
			local def = Catalog.get(id)
			local spans = Lifts.spans(def)
			local floors, gates, ups, downs, cars, doors = {}, {}, {}, {}, 0, 0
			for _, p in solidParts(def) do
				local f = p.attrs and p.attrs.Floor
				if p.name == "LiftCar" then
					cars += 1
					expect(p.collide).toBe(false)
					-- the car at the top landing still fits in the shaft
					local top = p.cf.Position.Y + p.size.Y / 2 + spans * H
					expect(top <= def.size.Y + 1e-6).toBe(true)
				elseif p.name == "LiftDoor" then
					doors += 1
					expect(p.collide).toBe(false)
					expect(p.attrs.Side == 1 or p.attrs.Side == -1).toBe(true)
				elseif p.name == "LiftFloor" then
					expect(p.collide ~= false and p.transp == 1).toBe(true)
					expect(p.cf.Position.Y + p.size.Y / 2).toBeNear(f * H + 0.19, 1e-4)
					floors[f] = true
				elseif p.name == "LiftGate" then
					expect(p.collide ~= false and p.transp == 1).toBe(true)
					gates[f] = true
				elseif p.name == "LiftUp" then
					expect(p.collide).toBe(false)
					ups[f] = true
				elseif p.name == "LiftDown" then
					expect(p.collide).toBe(false)
					downs[f] = true
				end
			end
			expect(cars > 5 and doors >= 4 * (spans + 1)).toBe(true)
			for k = 0, spans do
				expect(floors[k] and gates[k]).toBe(true)
				expect(ups[k] == (k < spans or nil)).toBe(true)
				expect(downs[k] == (k > 0 or nil)).toBe(true)
			end
		end
	end)

	it("rides a lift: fetched, the doors open and shut, carried, the doors open again", function()
		local ride = Lifts.ride(0, 2, 1)
		-- the car goes from the ground to the second landing, waits there, then down to the first
		expect(Lifts.carAt(ride, 0)).toBe(0)
		expect(Lifts.carAt(ride, ride.fetched)).toBeNear(2, 1e-6)
		expect(Lifts.carAt(ride, ride.done)).toBe(1)
		local last = 0
		for i = 0, 200 do
			local t = ride.done * i / 200
			local at = Lifts.carAt(ride, t)
			expect(math.abs(at - last) < 0.2).toBe(true) -- no jumps
			last = at
			-- the doors are shut whenever the car is between landings
			if at % 1 > 1e-3 and at % 1 < 1 - 1e-3 then
				for k = 0, 2 do
					expect(Lifts.doorsAt(ride, t, k)).toBe(0)
				end
			end
		end
		expect(Lifts.doorsAt(ride, (ride.opened + ride.boarded) / 2, 2)).toBe(1)
		expect(Lifts.doorsAt(ride, (ride.open + ride.closing) / 2, 1)).toBe(1)
		expect(Lifts.doorsAt(ride, (ride.open + ride.closing) / 2, 2)).toBe(0)
		expect(Lifts.doorsAt(ride, ride.done, 1)).toBeNear(0, 1e-6)
		-- a press goes a floor up or down, never past the ends
		expect(Lifts.target(3, 0, 1)).toBe(1)
		expect(Lifts.target(3, 0, -1)).toBe(nil)
		expect(Lifts.target(3, 3, 1)).toBe(nil)
		expect(Lifts.target(3, 3, -1)).toBe(2)
		-- where somebody is: their feet at a landing, in the car or by its doors
		expect(Lifts.landingOf(3, Vector3.new(0, 2 * H + 0.2, 0))).toBe(2)
		expect(Lifts.landingOf(3, Vector3.new(0, 5 * H, 0))).toBe(nil)
		expect(Lifts.inCar(Vector3.new(1, 0, 0))).toBe(true)
		expect(Lifts.inCar(Vector3.new(0, 0, 4))).toBe(false)
		expect(Lifts.atDoors(Vector3.new(0, 0, 4))).toBe(true)
		expect(Lifts.atDoors(Vector3.new(0, 0, 12))).toBe(false)
	end)
end)
