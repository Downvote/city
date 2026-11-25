--!nocheck
-- The "basement" preview scene (tools/preview/dump.luau): a basement of two rooms dug under a patch
-- of a plot, as Build mode and the server make it (the user: "another [gamepass] for basement").
-- The plot's ground part (World's Base, down to Terrain.PlotFloor) is cut round the basement's
-- floors as Services/Water cuts it; the ground under it, which the server digs out of the terrain,
-- is drawn as a block of earth with the dig taken out (the previews have no terrain). One room has
-- walls, a door through to the other, stairs up, a bed, lamps and a chair; the other is left open,
-- showing the concrete lining round its sides. A ground floor covers half of the first room, with
-- the stairwell cut in it.
--   sh tools/preview/render.sh basement <png>         (basement:open without the ground floor)

local roblox = require("@lune/roblox")
local Vector3, Color3 = roblox.Vector3, roblox.Color3

return function(R, which: string?)
	local Plan = R("ReplicatedStorage.Shared.Build.Plan")
	local Builder = R("ReplicatedStorage.Shared.Build.Builder")
	local Basement = R("ReplicatedStorage.Shared.Build.Basement")
	local Water = R("ReplicatedStorage.Shared.Build.Water")
	local Geometry = R("ReplicatedStorage.Shared.Build.Geometry")
	local Terrain = R("ReplicatedStorage.Shared.Data.Terrain")

	local B = Basement.Level
	local X = 20 -- where the rooms start on the patch (on the terrain's grid: 2 past a multiple of 4)
	local Z = 20
	local plan = Plan.new(400)
	plan.size = 400
	local n = 0
	local function add(kind, obj)
		n += 1
		local key = tostring(n)
		plan[kind][key] = obj
		return key
	end
	local function wall(x1, z1, x2, z2, lv, a, b)
		return add("walls", {
			x1 = X + x1,
			z1 = Z + z1,
			x2 = X + x2,
			z2 = Z + z2,
			lv = lv,
			style = "wall",
			a = { c = a or "E9E1D3", m = "Plaster" },
			b = { c = b or "F2EADC", m = "Plaster" },
		})
	end
	local function item(id, x, z, r, lv, y, extra)
		local obj = { id = id, x = X + x, y = y or Plan.levelBase(lv), z = Z + z, r = r or 0, lv = lv }
		for k, v in extra or {} do
			obj[k] = v
		end
		return add("items", obj)
	end

	-- the basement: a room with walls, and an open one beside it
	add("floors", { x1 = X, z1 = Z, x2 = X + 24, z2 = Z + 18, lv = B, c = "B89A78", m = "WoodPlanks" })
	add("floors", { x1 = X + 24, z1 = Z + 4, x2 = X + 38, z2 = Z + 14, lv = B, c = "9C968C", m = "Concrete" })
	wall(0, 0, 24, 0, B)
	wall(0, 0, 0, 18, B)
	wall(0, 18, 24, 18, B)
	local between = wall(24, 0, 24, 18, B, "D8CBB6", "E9E1D3")
	item("door_wood", 0, 0, 0, B, Plan.openingY(plan.walls[between], 0), { wall = between, t = 9, side = "a" })
	item("stairs_straight", 3, 10, 180, B)
	item("bed_single", 17, 4, 0, B)
	item("lamp_floor", 21.5, 2, 0, B)
	item("chair_wood", 12, 14, 180, B)
	item("light_ceiling", 12, 9, 0, B, Plan.ceilingY(B))
	item("light_ceiling", 31, 9, 0, B, Plan.ceilingY(B))

	-- the ground floor over half of the first room, the stairwell cut in it
	if which ~= "open" then
		add("floors", { x1 = X - 2, z1 = Z, x2 = X + 12, z2 = Z + 18, lv = 0, c = "C8B49A", m = "WoodPlanks" })
		wall(-2, 0, -2, 18, 0, "D7C4A8", "F2EADC")
		wall(-2, 18, 12, 18, 0, "D7C4A8", "F2EADC")
	end

	local out = {}
	for _, kind in Plan.Kinds do
		for key in plan[kind] do
			Geometry.append(out, Builder.primsFor(plan, kind, key) or {})
		end
	end

	-- the plot's ground part, cut round the basement's floors as the Water service cuts it
	local patch = { X - 14, Z - 12, X + 52, Z + 32 }
	local holes = Basement.rects(plan)
	local grass = Color3.fromRGB(138, 192, 112)
	for _, r in Water.cutRects(patch, holes) do
		table.insert(
			out,
			Geometry.span(Vector3.new(r[1], Terrain.PlotFloor, r[2]), Vector3.new(r[3], 0, r[4]), grass, "Grass")
		)
	end
	-- the earth under it, with what the server digs out of it taken away
	local earth = Color3.fromRGB(122, 104, 82)
	local dug = Basement.blocks(plan)
	for _, r in Water.cutRects(patch, dug) do
		table.insert(
			out,
			Geometry.span(Vector3.new(r[1], Basement.Bottom, r[2]), Vector3.new(r[3], Terrain.PlotFloor, r[4]), earth, "Ground")
		)
	end
	table.insert(
		out,
		Geometry.span(Vector3.new(patch[1], Basement.Bottom - 2, patch[2]), Vector3.new(patch[3], Basement.Bottom, patch[4]), earth, "Ground")
	)
	return out
end
