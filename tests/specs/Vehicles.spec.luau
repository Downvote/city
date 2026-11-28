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
		-- (more for the endgame: the user, "make more vehicles, buildings that cost more for the
		-- endgame")
		expect(#coins >= 9 and #gems >= 4).toBeTruthy()
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

	it("is drawn in detail, in textured materials, round where it is round", function()
		-- the user: "make cars and vechicles more detailed, especially player bought ones. the
		-- scooter dosent look like a scooter" and "You are allowed to use spheres, curves or circles
		-- where necessary": every vehicle is a few hundred parts at most, none of them plain
		-- SmoothPlastic, every frame a real rotation, and what is drawn smooth keeps a round size
		for _, v in VehicleData.list do
			local prims = Geometry.flatten(VehicleData.prims(v))
			expect(#prims >= 100 and #prims <= 400).toBeTruthy()
			local round = 0
			for _, p in prims do
				if p.mat == "SmoothPlastic" then
					error(v.id .. ": a part in plain SmoothPlastic")
				end
				local _, _, _, r00, r01, r02, r10, r11, r12, r20, r21, r22 = p.cf:GetComponents()
				local x, y, z = Vector3.new(r00, r10, r20), Vector3.new(r01, r11, r21), Vector3.new(r02, r12, r22)
				expect((x:Cross(y) - z).Magnitude < 1e-3).toBeTruthy()
				if p.smooth then
					round += 1
					if p.shape == "Ball" then
						expect(math.abs(p.size.X - p.size.Y) < 1e-6 and math.abs(p.size.Y - p.size.Z) < 1e-6).toBeTruthy()
					else
						expect(p.shape).toBe("Cylinder")
						expect(math.abs(p.size.Y - p.size.Z) < 1e-6).toBeTruthy()
					end
				end
			end
			expect(round >= 8).toBeTruthy()
		end
		-- a seat under everyone: a cushion in fabric or leather just under where each one sits
		for _, v in VehicleData.list do
			local prims = Geometry.flatten(VehicleData.prims(v))
			for _, at in { v.driver, table.unpack(v.passengers) } do
				local found = false
				for _, p in prims do
					if (p.mat == "Fabric" or p.mat == "Leather") and p.shape == "Block" then
						local lo, hi = Geometry.bounds({ p })
						if
							at.X >= lo.X
							and at.X <= hi.X
							and at.Z >= lo.Z
							and at.Z <= hi.Z
							and math.abs(hi.Y - (at.Y + 0.2)) < 0.3
						then
							found = true
							break
						end
					end
				end
				if not found then
					error(v.id .. ": nothing to sit on at " .. tostring(at))
				end
			end
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
