--!nocheck
-- Vehicles (Data/Vehicles, Sim/Vehicles). The user: "make vehicles, with faster ones with bigger
-- capacities costing more, and gem ones being the fastest". Here: the list keeps that order, every
-- vehicle fits its box with a seat for everyone, buying takes the price once, and driving gathers
-- speed, brakes, coasts and turns as it should.

local Shared = "ReplicatedStorage.Shared."
local Tuning = require(Shared .. "Config.Tuning")
local Geometry = require(Shared .. "Build.Geometry")
local VehicleData = require(Shared .. "Data.Vehicles")
local Vehicles = require(Shared .. "Sim.Vehicles")
local Schema = require(Shared .. "Sim.Schema")

describe("Vehicles", function()
	it("costs more as it gets faster and roomier, and the gem ones are the fastest", function()
		local coins, gems = {}, {}
		for _, v in VehicleData.list do
			expect((v.coins ~= nil) ~= (v.gems ~= nil)).toBeTruthy() -- (one price, in one money)
			table.insert(if v.gems then gems else coins, v)
		end
		expect(#coins >= 4 and #gems >= 1).toBeTruthy()
		for i = 2, #coins do
			local a, b = coins[i - 1], coins[i]
			expect(b.coins > a.coins).toBeTruthy()
			expect(b.speed > a.speed).toBeTruthy()
			expect(b.seats > a.seats).toBeTruthy()
		end
		local fastestCoin = coins[#coins].speed
		for i, g in gems do
			expect(g.speed > fastestCoin).toBeTruthy()
			if i > 1 then
				expect(g.gems > gems[i - 1].gems and g.speed > gems[i - 1].speed).toBeTruthy()
			end
		end
	end)

	it("draws each inside its box, with a seat for the driver and every passenger", function()
		for _, v in VehicleData.list do
			expect(v.seats).toBe(1 + #v.passengers)
			local lo, hi = Geometry.bounds(Geometry.flatten(VehicleData.prims(v)))
			local half = v.size / 2
			-- (its frame is the wheels' middle: the box sits from the ground, hover under it)
			expect(lo.X >= -half.X - 0.05 and hi.X <= half.X + 0.05).toBeTruthy()
			expect(lo.Z >= -half.Z - 0.05 and hi.Z <= half.Z + 0.05).toBeTruthy()
			expect(lo.Y >= -v.hover - 0.05 and hi.Y <= v.size.Y - v.hover + 0.05).toBeTruthy()
			for _, at in { v.driver, table.unpack(v.passengers) } do
				expect(math.abs(at.X) <= half.X and math.abs(at.Z) <= half.Z).toBeTruthy()
			end
			-- and its words read as a person's
			expect(string.find(v.blurb, "\u{2014}") == nil and string.find(v.blurb, "!") == nil).toBeTruthy()
		end
	end)

	it("buys once, for its price in coins or in gems", function()
		local p = Schema.newProfile()
		p.coins = 5000
		p.gems = 100
		local ok, why = Vehicles.canBuy(p, "family")
		expect(ok == false and why == "Not enough coins.").toBeTruthy()
		expect(Vehicles.buy(p, "hatch")).toBe(true)
		expect(p.coins).toBe(1000)
		expect(Vehicles.owns(p, "hatch")).toBe(true)
		local again = Vehicles.canBuy(p, "hatch")
		expect(again).toBe(false)
		expect(Vehicles.buy(p, "sports")).toBe(true)
		expect(p.gems).toBe(10)
		expect(p.coins).toBe(1000)
		expect(Vehicles.canBuy(p, "cruiser")).toBe(false)
		expect(Vehicles.canBuy(p, "rocket")).toBe(false)
		-- what is saved keeps only real ones
		local clean = Vehicles.clean({ hatch = true, rocket = true, family = "yes" })
		expect(clean.hatch == true and clean.rocket == nil and clean.family == nil).toBeTruthy()
	end)

	it("gathers speed to its top, brakes harder than it speeds up, rolls to a stop", function()
		local top, dt = 40, 1 / 30
		local s = 0
		for _ = 1, 30 * 10 do
			s = Vehicles.step(s, 1, top, dt)
		end
		expect(s).toBe(top)
		-- braking from flat out stops sooner than speeding up took
		local brake, t = top, 0
		while brake > 0 and t < 100 do
			brake = Vehicles.step(brake, -1, top, dt)
			t += 1
		end
		local up, t2 = 0, 0
		while up < top and t2 < 1000 do
			up = Vehicles.step(up, 1, top, dt)
			t2 += 1
		end
		expect(t < t2).toBeTruthy()
		-- no pedal: it rolls to a stop
		local roll = top
		for _ = 1, 30 * 10 do
			roll = Vehicles.step(roll, 0, top, dt)
		end
		expect(roll).toBe(0)
		-- backing up is slower
		local back = 0
		for _ = 1, 30 * 10 do
			back = Vehicles.step(back, -1, top, dt)
		end
		expect(back).toBe(-top * Tuning.Vehicles.Reverse)
	end)

	it("turns only while moving, the other way backing up, and less flat out", function()
		expect(Vehicles.turnRate(0, 40)).toBe(0)
		local slow, fast = Vehicles.turnRate(5, 40), Vehicles.turnRate(40, 40)
		expect(slow > fast and fast > 0).toBeTruthy()
		expect(Vehicles.turnRate(-5, 40) < 0).toBeTruthy()
	end)
end)
