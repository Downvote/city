--!nocheck
-- Every part's frame is a real rotation. A mirrored frame (its three axes a left-handed set) draws
-- fine in these tools, but Roblox can't hold one and turns the part some other way instead: that
-- is how the palms' trunks came to lie on their sides, the bandstand's rails to fall about and the
-- fountain's rim to point outward. So: every primitive of every model the game can build, the
-- catalog's, the map's, the ambient ones and whole houses, has a right-handed orthonormal frame.

local Shared = "ReplicatedStorage.Shared."
local TownMap = require(Shared .. "Data.TownMap")
local Catalog = require(Shared .. "Build.Catalog")
local AmbientModels = require(Shared .. "Data.AmbientModels")
local StarterHouse = require(Shared .. "Data.StarterHouse")
local Presets = require(Shared .. "Data.Presets")
local Plan = require(Shared .. "Build.Plan")
local Builder = require(Shared .. "Build.Builder")
local Recipe = require(Shared .. "Build.Recipe")

-- nil when the frame is a proper rotation, else what is wrong with it
local function wrong(cf)
	local _, _, _, r00, r01, r02, r10, r11, r12, r20, r21, r22 = cf:GetComponents()
	local x, y, z = Vector3.new(r00, r10, r20), Vector3.new(r01, r11, r21), Vector3.new(r02, r12, r22)
	if math.abs(x.Magnitude - 1) > 1e-3 or math.abs(y.Magnitude - 1) > 1e-3 or math.abs(z.Magnitude - 1) > 1e-3 then
		return "an axis isn't one long"
	end
	if math.abs(x:Dot(y)) > 1e-3 or math.abs(y:Dot(z)) > 1e-3 or math.abs(x:Dot(z)) > 1e-3 then
		return "axes not square to each other"
	end
	if (x:Cross(y) - z).Magnitude > 1e-3 then
		return "mirrored"
	end
	return nil
end

local function check(name, prims)
	for i, p in prims do
		local why = wrong(p.cf)
		if why then
			error(name .. ": part " .. i .. " (" .. p.shape .. ") is " .. why)
		end
	end
	return #prims
end

local function planPrims(plan)
	local out = {}
	for kind in Plan.KindSet do
		for key in plan[kind] do
			for _, p in Builder.primsFor(plan, kind, key) or {} do
				table.insert(out, p)
			end
		end
	end
	return out
end

describe("Frames", function()
	it("are real rotations on every catalog item", function()
		local n = 0
		for _, def in Catalog.all() do
			n += check("item " .. def.id, Catalog.prims(def))
		end
		expect(n > 1000).toBeTruthy()
	end)

	it("are real rotations on everything on the map", function()
		local seen = {}
		local n = check("the ground", TownMap.ground())
		for _, p in TownMap.placements() do
			expect(wrong(p.cf)).toBe(nil)
			if not seen[p.name] then
				seen[p.name] = true
				n += check(p.name, TownMap.prims(p.name))
			end
		end
		for name, build in AmbientModels.Models do
			local r = Recipe.new(Color3.new(1, 1, 1), Color3.new(1, 1, 1))
			build(r)
			n += check("ambient " .. name, r.prims)
		end
		expect(n > 5000).toBeTruthy()
	end)

	it("are real rotations on a wall's two sides, whichever way it runs", function()
		for _, w in
			{
				{ x1 = 0, z1 = 0, x2 = 20, z2 = 0 },
				{ x1 = 20, z1 = 0, x2 = 0, z2 = 0 },
				{ x1 = 0, z1 = 0, x2 = 0, z2 = 20 },
				{ x1 = 0, z1 = 20, x2 = 0, z2 = 0 },
				{ x1 = 0, z1 = 0, x2 = 14, z2 = 14 },
			}
		do
			w.lv, w.style = 0, "wall"
			for _, side in { "a", "b" } do
				local f = Plan.wallFrame(w, 5, 0, side)
				expect(wrong(f)).toBe(nil)
				-- Z still points out of that side
				local n = Plan.wallNormal(w)
				expect(f.ZVector:Dot(if side == "a" then n else -n) > 0.999).toBeTruthy()
			end
		end
	end)

	it("are real rotations all through the starter house and every ready-made building", function()
		local n = check("the starter house", planPrims(StarterHouse.plan()))
		for _, preset in Presets.list do
			local plan = Plan.new()
			plan.size = 200
			local ok, _why, _price, built = Presets.check(plan, Presets.requests(preset.id, 100, 100, 0))
			expect(ok).toBe(true)
			n += check("preset " .. preset.id, planPrims(built or plan))
		end
		expect(n > 500).toBeTruthy()
	end)
end)
