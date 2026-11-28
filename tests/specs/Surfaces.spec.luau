--!nocheck
-- Nothing in the town is flat plastic where it shows (the user: "for all buildings and decor, make
-- it such that textures are used, never make them untextured"): Data/Surfaces gives whatever a
-- model left plain a texture by its look, and the ready-made buildings and the starting house
-- have none in their finishes. `lune run tools/preview/untextured.luau` lists what is left.

local Shared = "ReplicatedStorage.Shared."
local Geometry = require(Shared .. "Build.Geometry")
local Recipe = require(Shared .. "Build.Recipe")
local Surfaces = require(Shared .. "Data.Surfaces")
local TownMap = require(Shared .. "Data.TownMap")
local Presets = require(Shared .. "Data.Presets")
local StarterHouse = require(Shared .. "Data.StarterHouse")

local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end

local function describePrim(p)
	return string.format("%s %s #%s %s", p.shape, tostring(p.size), p.color:ToHex(), p.mat)
end

describe("Surfaces", function()
	it("picks a texture by what a thing looks like", function()
		expect(Surfaces.pick(rgb(82, 126, 70), "Ball")).toBe("Grass") -- a clump of leaves
		expect(Surfaces.pick(rgb(84, 192, 70), "Block")).toBe("LeafyGrass") -- leaves drawn as boxes
		expect(Surfaces.pick(rgb(154, 107, 72), "Block")).toBe("Wood") -- stained timber
		expect(Surfaces.pick(rgb(250, 246, 236), "Block")).toBe("Concrete:Stucco") -- pale paint
		expect(Surfaces.pick(rgb(64, 70, 86), "Block")).toBe("Metal") -- dark paint
		expect(Surfaces.pick(rgb(60, 112, 98), "Block")).toBe("Metal") -- a painted green door is no hedge
		for _, c in { rgb(250, 246, 236), rgb(64, 70, 86), rgb(154, 107, 72), rgb(220, 122, 112) } do
			expect(Surfaces.plain(Surfaces.pick(c, "Block"))).toBe(false)
		end
	end)

	it("leaves light, glass, water and what is hidden as they are", function()
		local r = Recipe.new(rgb(255, 255, 255), rgb(255, 255, 255))
		local lamp = r:glow(r:ball(0, 3, 0, 1, rgb(255, 236, 190)), 0)
		local pane = r:box(0, 1, 0, 2, 2, 0.1, rgb(150, 206, 240), "Glass")
		local pond = r:box(0, 0.1, 0, 8, 0.2, 8, rgb(84, 168, 236))
		pond.transp = 0.25
		local wall = r:box(0, 1, 0, 4, 2, 1, rgb(84, 168, 236))
		wall.transp = 1
		local neon = r:box(0, 1, 0, 2, 0.2, 0.2, rgb(255, 120, 120), "Neon")
		local board = r:box(0, 1, 0, 4, 2, 0.2, rgb(220, 122, 112))
		Surfaces.dress(r.prims)
		-- (drawn naming no material: they keep the kit's default, Geometry.Default)
		expect(lamp.mat).toBe(Geometry.Default)
		expect(pane.mat).toBe("Glass")
		expect(pond.mat).toBe(Geometry.Default)
		expect(wall.mat).toBe(Geometry.Default)
		expect(neon.mat).toBe("Neon")
		expect(board.mat).toBe("Metal")
		expect(#Surfaces.untextured(r.prims)).toBe(0)
	end)

	it("keeps a piece in one material and writes its key again", function()
		local q = Recipe.new(rgb(255, 255, 255), rgb(255, 255, 255))
		q:box(0, 1, 0, 4, 2, 0.2, rgb(154, 107, 72)) -- the biggest: timber
		q:box(0, 2.2, 0, 4.4, 0.2, 0.4, rgb(250, 246, 236))
		local p = Geometry.piece(q.prims)
		local copy = table.clone(p)
		Surfaces.dress({ p, copy })
		expect(p.mat).toBe("Wood")
		expect(copy.mat).toBe("Wood")
		for _, s in p.parts do
			expect(s.mat).toBe("Wood")
		end
		expect(string.sub(p.key, 1, 4)).toBe("Wood")
		expect(p.key).toBe(copy.key)
		-- a piece drawn in a material keeps it
		local stone =
			Geometry.piece({ Geometry.box(CFrame.new(), Vector3.new(2, 2, 2), rgb(200, 200, 200), "Concrete") })
		Surfaces.dress({ stone })
		expect(stone.mat).toBe("Concrete")
	end)

	it("leaves nothing in the town untextured", function()
		local bad = {}
		local function look(name, prims)
			for _, p in Surfaces.untextured(prims) do
				table.insert(bad, name .. ": " .. describePrim(p))
				if #bad > 12 then
					error("flat plastic in the town:\n" .. table.concat(bad, "\n"))
				end
			end
		end
		look("ground", TownMap.ground())
		local seen = {}
		for _, p in TownMap.placements() do
			if not seen[p.name] then
				seen[p.name] = true
				look(p.name, TownMap.prims(p.name))
			end
		end
		if #bad > 0 then
			error("flat plastic in the town:\n" .. table.concat(bad, "\n"))
		end
	end)

	it("gives the ready-made buildings and the starting house no plain finishes", function()
		-- (a wall's two sides, a roof's tiles and its gables, a floor, a path)
		local function plainIn(obj)
			for _, side in { obj, obj.a, obj.b } do
				if type(side) == "table" then
					for _, key in { "m", "m2" } do
						local m = side[key]
						if type(m) == "string" and Surfaces.plain(m) then
							return m
						end
					end
				end
			end
			return nil
		end
		local function finishes(name, objects)
			for _, o in objects do
				local m = plainIn(o.obj)
				if m then
					error(name .. ": a " .. o.kind .. " finished in " .. m)
				end
			end
		end
		for _, p in Presets.list do
			finishes(p.id, p.objects)
		end
		local plan = StarterHouse.plan()
		for _, kind in { "walls", "floors", "roofs", "paths", "fences" } do
			for key, obj in plan[kind] or {} do
				local m = plainIn(obj)
				if m then
					error("the starting house: " .. kind .. " " .. tostring(key) .. " finished in " .. m)
				end
			end
		end
	end)
end)
