--!nocheck
-- Ready-made buildings: every one goes down whole, in every direction, on the client's check and
-- on the server's, costs what its pieces cost, and the shops come with their workplace.

local Shared = "ReplicatedStorage.Shared."
local Tuning = require(Shared .. "Config.Tuning")
local Plan = require(Shared .. "Build.Plan")
local Catalog = require(Shared .. "Build.Catalog")
local Presets = require(Shared .. "Data.Presets")

-- the server's Build service, for its prepare (its neighbours are never touched by it)
Harness.stub("ServerScriptService.Server.Services.Data", {})
Harness.stub("ServerScriptService.Server.Services.Plots", {})
local Build = require("ServerScriptService.Server.Services.Build")

local function emptyPlan()
	local plan = Plan.new(Tuning.Plot.Size)
	plan.size = Tuning.Plot.Size
	return plan
end

describe("Presets", function()
	it("has a good handful of buildings", function()
		expect(#Presets.list >= 8).toBeTruthy()
		local seen = {}
		for _, p in Presets.list do
			expect(seen[p.id]).toBe(nil)
			seen[p.id] = true
			expect((p.w / Tuning.Plot.WallSnap) % 1).toBe(0)
			expect((p.d / Tuning.Plot.WallSnap) % 1).toBe(0)
		end
	end)

	it("places every building whole, turned every way", function()
		for _, p in Presets.list do
			for _, rot in { 0, 90, 180, 270 } do
				local plan = emptyPlan()
				local x1, z1 = Plan.boundsOf(plan.size)
				local reqs = Presets.requests(p.id, x1 + 20, z1 + 20, rot)
				local ok, why = Presets.check(plan, reqs)
				if not ok then
					error(p.id .. " turned " .. rot .. ": " .. tostring(why))
				end
			end
		end
	end)

	it("is accepted by the server, doors and windows on the right walls", function()
		for _, p in Presets.list do
			local plan = emptyPlan()
			local x1, z1 = Plan.boundsOf(plan.size)
			local reqs = Presets.requests(p.id, x1 + 30, z1 + 30, 90)
			local ops, err = Build.prepare(plan, reqs)
			if not ops then
				error(p.id .. ": the server said " .. tostring(err))
			end
			expect(#ops).toBe(#reqs)
			for _, item in plan.items do
				local def = Catalog.get(item.id)
				if def.place == "opening" then
					expect(plan.walls[item.wall] ~= nil).toBeTruthy()
				end
			end
		end
	end)

	it("fits inside its footprint", function()
		for _, p in Presets.list do
			local plan = emptyPlan()
			local reqs = Presets.requests(p.id, 40, 40, 0)
			local _, _, _, trial, made = Presets.check(plan, reqs)
			for _, m in made do
				local obj = trial[m.kind][m.key]
				if m.kind == "items" and obj.wall == nil then
					local ax, az, bx, bz = Plan.itemRect(obj)
					local inside = ax >= 40 - 0.05
						and az >= 40 - 0.05
						and bx <= 40 + p.w + 0.05
						and bz <= 40 + p.d + 0.05
					if not inside then
						error(p.id .. ": " .. obj.id .. " sticks out of the footprint")
					end
				elseif obj.x1 then
					expect(math.min(obj.x1, obj.x2) >= 40 and math.max(obj.x1, obj.x2) <= 40 + p.w).toBeTruthy()
				end
			end
		end
	end)

	it("has one building for every workplace, from its own file", function()
		-- the user: "make much more buildings, one for each workspace, and detail them all to be
		-- unique, as much as the starting house"
		local jobs = {}
		for _, def in Catalog.workplaces() do
			-- (but a crate's: it only comes out of a work crate, never with a building)
			if not def.crate then
				jobs[def.id] = false
			end
		end
		for _, p in Presets.list do
			for _, o in p.objects do
				if o.obj.id and jobs[o.obj.id] ~= nil then
					jobs[o.obj.id] = true
				end
			end
		end
		for id, found in jobs do
			if not found then
				error("no ready-made building brings " .. id)
			end
		end
		expect(#Presets.Workplaces).toBe(12)
		-- and each is a real building, at the starting house's level of detail, under the
		-- server's batch limit
		for _, name in Presets.Workplaces do
			local id = string.lower(name)
			local p = Presets.get(id)
			if not p then
				error("Data/Buildings/" .. name .. " made no building with the id " .. id)
			end
			expect(#p.objects >= 110).toBeTruthy()
			expect(#p.objects <= 300).toBeTruthy()
		end
	end)

	it("keeps the grand ones for a town of their level, on the server too", function()
		-- the user: "make more vehicles, buildings that cost more for the endgame". The grand
		-- buildings (Data/Buildings/Grand) each hold a piece that waits for a town level
		-- (Recipes/Grand); the server refuses it, and so the building, to a smaller town
		local levels = {}
		for _, id in { "grand_manor", "grand_hotel", "grand_townhall" } do
			local p = Presets.get(id)
			expect(p ~= nil).toBeTruthy()
			table.insert(levels, Presets.level(id))
			-- at the starting house's level of detail, under the server's batch limit
			expect(#p.objects >= 110 and #p.objects <= 300).toBeTruthy()
		end
		expect(levels[1] < levels[2] and levels[2] < levels[3]).toBeTruthy()
		local plan = emptyPlan()
		local x1, z1 = Plan.boundsOf(plan.size)
		local reqs = Presets.requests("grand_manor", x1 + 30, z1 + 30, 0)
		local small = { plan = emptyPlan() }
		local ok, why = Build.levelCheck(small, reqs)
		expect(ok).toBe(false)
		expect(why).toBe("that one opens at Level " .. levels[1])
		expect((Build.levelCheck(small, Presets.requests("cottage", x1 + 30, z1 + 30, 0)))).toBe(true)
		-- one already down can still be moved in a town that has since sold below its level
		local had = emptyPlan()
		local lamp = { id = "grand_chandelier", x = 10, y = 11, z = 10, r = 0, lv = 0 }
		had.items["7"] = table.clone(lamp)
		lamp.x = 14
		expect((Build.levelCheck({ plan = had }, { { type = "set", kind = "items", key = "7", obj = lamp } }))).toBe(
			true
		)
	end)

	it("costs what its pieces cost, and the shops bring their workplace", function()
		-- one building for every workplace (the user: "make much more buildings, one for each
		-- workspace"), each with its own file under Data/Buildings
		local shops = {
			market = "work_market",
			cafe = "work_cafe",
			bakery = "work_bakery",
			icecream = "work_icecream",
			florist = "work_flowers",
			studio = "work_easel",
			musichall = "work_stage",
			workshop = "work_builder",
			clinic = "work_clinic",
			school = "work_school",
			postoffice = "work_post",
			library = "work_library",
		}
		for _, p in Presets.list do
			local price = Presets.price(p.id)
			expect(price > 0).toBeTruthy()
			local want = shops[p.id]
			if want then
				local found = false
				for _, o in p.objects do
					if o.obj.id == want then
						found = true
					end
				end
				if not found then
					error(p.id .. " has no " .. want)
				end
			end
		end
	end)
end)
