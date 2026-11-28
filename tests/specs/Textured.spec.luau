--!nocheck
-- Textures on everything players build (the user: "for all buildings and decor, make it such that
-- textures are used, never make them untextured"). No shape you can see on a Build mode piece, or
-- on the walls, fences, floors and roofs Build mode draws, is plain SmoothPlastic or Plastic. What
-- may stay as it is: what glows (Neon, and a lamp's lit part), glass, force fields, hidden parts,
-- flat paint marks lying on the ground, and a part so small (under Tuning.Unstick.Tiny every way)
-- that a texture couldn't show on it. The paint tool offers no untextured finish, and a save that
-- still holds one is drawn in the textured finish that took its place.

local Shared = "ReplicatedStorage.Shared."
local Tuning = require(Shared .. "Config.Tuning")
local Catalog = require(Shared .. "Build.Catalog")
local Plan = require(Shared .. "Build.Plan")
local Shapes = require(Shared .. "Build.Shapes")
local Geometry = require(Shared .. "Build.Geometry")
local Builder = require(Shared .. "Build.Builder")
local Recipe = require(Shared .. "Build.Recipe")
local Palette = require(Shared .. "Data.Palette")

local PLAIN = { SmoothPlastic = true, Plastic = true }

-- Is this shape left untextured where it shows?
local function bare(p, mark: boolean?): boolean
	if not PLAIN[(string.split(p.mat, ":"))[1]] then
		return false
	end
	if (p.transp or 0) >= 0.99 or mark then
		return false
	end
	local s = p.size
	if math.max(s.X, s.Y, s.Z) < Tuning.Unstick.Tiny then
		return false
	end
	return true
end

local X0 = Plan.bounds(Plan.new())

describe("Textured", function()
	it("gives every Build mode piece a texture on everything you can see", function()
		local bad = {}
		for _, def in Catalog.all() do
			local n = 0
			for _, p in Geometry.flatten(Catalog.prims(def)) do
				if bare(p, def.place == "mark") then
					n += 1
				end
			end
			if n > 0 then
				table.insert(bad, def.id .. " (" .. n .. ")")
			end
		end
		if #bad > 0 then
			error("untextured shapes in: " .. table.concat(bad, ", "))
		end
	end)

	it("draws walls, fences, floors and roofs textured in every style", function()
		local out = {}
		for id, def in Plan.WallStyles do
			local side = def.paint or Palette.Defaults.WallOut
			local w = {
				x1 = X0,
				z1 = 0,
				x2 = X0 + 12,
				z2 = 0,
				lv = 0,
				style = id,
				a = table.clone(side),
				b = table.clone(def.paint or Palette.Defaults.WallIn),
			}
			for _, p in Shapes.wall(w, {}) do
				table.insert(out, { p, "wall " .. id })
			end
		end
		for id in Plan.RoofStyles do
			local r = {
				x1 = 10 + X0,
				z1 = 10,
				x2 = 30 + X0,
				z2 = 22,
				lv = 0,
				style = id,
				rise = 6,
				dir = 0,
				over = 1,
				c = Palette.Defaults.Roof.c,
				m = Palette.Defaults.Roof.m,
				c2 = Palette.Defaults.RoofGable.c,
				m2 = Palette.Defaults.RoofGable.m,
			}
			for _, p in Shapes.roof(r) do
				table.insert(out, { p, "roof " .. id })
			end
		end
		local f =
			{ x1 = 0, z1 = 0, x2 = 20, z2 = 20, lv = 1, c = Palette.Defaults.Floor.c, m = Palette.Defaults.Floor.m }
		for _, p in Shapes.floor(f, {}) do
			table.insert(out, { p, "floor" })
		end
		local bad = {}
		for _, e in
			Geometry.flatten((function()
				local l = {}
				for _, e in out do
					table.insert(l, e[1])
				end
				return l
			end)())
		do
			if bare(e) then
				table.insert(bad, e.mat)
			end
		end
		for _, e in out do
			if bare(e[1]) then
				table.insert(bad, e[2])
			end
		end
		expect(#bad).toBe(0)
	end)

	it("offers only textured finishes, and draws an old save's flat paint textured", function()
		for _, m in Palette.Materials do
			expect(PLAIN[m.id]).toBe(nil)
		end
		for old, now in Palette.Retired do
			expect(Palette.MaterialSet[old]).toBe(true) -- (an old save still loads)
			expect(PLAIN[now]).toBe(nil)
			expect(Palette.drawn(old)).toBe(now)
		end
		-- a wall painted flat on one side, a piece painted flat in both slots
		local plan = Plan.new()
		plan.walls.w1 = {
			x1 = X0 + 4,
			z1 = 4,
			x2 = X0 + 16,
			z2 = 4,
			lv = 0,
			style = "wall",
			a = { c = "F2E8D5", m = "SmoothPlastic" },
			b = { c = "FFFFFF", m = "Plastic" },
		}
		plan.items.i1 =
			{ id = "sofa_two", x = X0 + 10, y = 0, z = 12, r = 0, lv = 0, m1 = "SmoothPlastic", m2 = "Plastic" }
		for _, key in { { "walls", "w1" }, { "items", "i1" } } do
			local prims = Builder.primsFor(plan, key[1], key[2])
			expect(prims ~= nil and #prims > 0).toBeTruthy()
			for _, p in Geometry.flatten(prims) do
				expect(PLAIN[p.mat]).toBe(nil)
			end
		end
	end)

	it("textures a shape drawn without a material", function()
		local r = Recipe.new(Color3.new(1, 1, 1), Color3.new(0, 0, 0))
		r:box(0, 0.5, 0, 1, 1, 1, r.c1)
		r:cyl(0, 0.5, 0, 1, 1, "y", r.c1)
		r:ball(0, 0.5, 0, 1, r.c1)
		r:wedge(CFrame.new(), 1, 1, 1, r.c1)
		r:cone(0, 0.5, 0, 1, 1, r.c1)
		r:lump(CFrame.new(), 1, 1, 1, r.c1)
		for _, p in r.prims do
			expect(PLAIN[p.mat]).toBe(nil)
		end
		expect(PLAIN[Geometry.Default]).toBe(nil)
	end)
end)
