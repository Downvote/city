--!nocheck
-- Pieces keep out of each other (the user: "add collisions, and a gamepass should be there to
-- remove it"), and the rest of what the build mode passes change: turning to any angle,
-- stretching and any colour (Build/Collide, Build/Placing, Build/Stretch).

local Shared = "ReplicatedStorage.Shared."
local Catalog = require(Shared .. "Build.Catalog")
local Collide = require(Shared .. "Build.Collide")
local Placing = require(Shared .. "Build.Placing")
local Stretch = require(Shared .. "Build.Stretch")
local Plan = require(Shared .. "Build.Plan")
local Builder = require(Shared .. "Build.Builder")
local Geometry = require(Shared .. "Build.Geometry")
local Presets = require(Shared .. "Data.Presets")
local Tuning = require(Shared .. "Config.Tuning")

local X0 = Plan.bounds(Plan.new())

local function item(id, x, z, extra)
	local def = Catalog.get(id)
	local it = { id = id, x = X0 + x, y = 0, z = z, r = 0, lv = 0 }
	if def.place == "ceiling" then
		it.y = Plan.ceilingY(0)
	end
	for k, v in extra or {} do
		it[k] = v
	end
	return it
end

local function wall(x1, z1, x2, z2)
	return {
		x1 = X0 + x1,
		z1 = z1,
		x2 = X0 + x2,
		z2 = z2,
		lv = 0,
		style = "wall",
		a = { c = "F2E6CC", m = "Plaster" },
		b = { c = "F7F3EA", m = "SmoothPlastic" },
	}
end

-- a plan with these in it, keyed 1, 2, 3 ...
local function planWith(list)
	local plan = Plan.new()
	for _, entry in list do
		local key = Plan.newKey(plan)
		plan[entry[1]][key] = entry[2]
	end
	return plan
end

local free = { passes = { freeplace = true } }
local nobody = { passes = {} }

describe("Collide: what keeps out of what", function()
	it("gives a piece a body of its solid parts, and none to what sits on or in others", function()
		expect(#Collide.body(Catalog.get("fancy_sofa_camel")) > 0).toBeTruthy()
		expect(#Collide.body(Catalog.get("shape_cube_medium"))).toBe(1)
		for _, id in { "cozy_rug_braided", "cozy_candle_jars", "fancy_chandelier_crystal", "cozy_photo_wall" } do
			expect(Collide.passes(Catalog.get(id))).toBe(true)
			expect(#Collide.body(Catalog.get(id))).toBe(0)
		end
		expect(Collide.passes(Catalog.get("door_wood"))).toBe(true)
		expect(Collide.passes(Catalog.get("mark_line"))).toBe(true)
		for _, def in Catalog.paths() do
			expect(Collide.passes(def)).toBe(true)
		end
		-- every body sits inside the piece's own box (with a little give), so a footprint check
		-- and the body agree
		for _, def in Catalog.all() do
			for _, b in Collide.body(def) do
				local h = def.size / 2 + Vector3.new(1, 1, 1)
				local p = b.cf.Position
				expect(math.abs(p.X) <= h.X and math.abs(p.Z) <= h.Z and p.Y >= -1 and p.Y <= def.size.Y + 1).toBeTruthy()
			end
		end
	end)

	it("turns down a piece in another, and lets pieces pushed flush stand together", function()
		local plan = planWith({ { "items", item("shape_cube_medium", 20, 20) } })
		local ok, why = Collide.check(plan, "items", item("shape_cube_medium", 22, 20))
		expect(ok).toBe(false)
		expect(why).toBe("bumps into the medium cube")
		-- side by side, faces touching
		expect((Collide.check(plan, "items", item("shape_cube_medium", 24, 20)))).toBe(true)
		-- counters in a row on the grid
		local row = planWith({ { "items", item("counter", 10, 30) } })
		expect((Collide.check(row, "items", item("counter", 13, 30)))).toBe(true)
		-- turned a quarter, a long piece reaches its neighbour
		local long = planWith({ { "items", item("shape_cube_long", 10, 40) } })
		expect((Collide.check(long, "items", item("shape_cube_long", 10, 43)))).toBe(true)
		expect((Collide.check(long, "items", item("shape_cube_long", 13, 40, { r = 90 })))).toBe(false)
		-- moving a piece never bumps into itself
		local moved = item("shape_cube_medium", 21, 20)
		expect((Collide.check(plan, "items", moved, { ["1"] = true }))).toBe(true)
	end)

	it("lets small things, rugs, marks and ceiling lights share a spot with furniture", function()
		local tablePlan = planWith({ { "items", item("modern_dining_table", 20, 20) } })
		for _, id in { "cozy_candle_jars", "cozy_rug_braided", "mark_line", "fancy_chandelier_crystal" } do
			local ok = Collide.check(tablePlan, "items", item(id, 20, 20))
			expect(ok).toBe(true)
		end
		-- and furniture goes over a rug
		local rugPlan = planWith({ { "items", item("cozy_rug_braided", 20, 20) } })
		expect((Collide.check(rugPlan, "items", item("modern_dining_table", 20, 20)))).toBe(true)
	end)

	it("keeps pieces out of walls but lets one stand in a doorway", function()
		local plan = planWith({ { "walls", wall(10, 50, 30, 50) } })
		local ok, why = Collide.check(plan, "items", item("shape_cube_small", 20, 50))
		expect(ok).toBe(false)
		expect(why).toBe("bumps into a wall")
		-- a door in it: the doorway is clear
		plan.items["9"] = { id = "door_wood", x = 0, y = Plan.openingY(plan.walls["1"], 0), z = 0, r = 0, lv = 0, wall = "1", t = 10, side = "a" }
		expect((Plan.validItem(plan, plan.items["9"], "9"))).toBe(true)
		-- (standing on the floor, over the foot of the wall under the doorway)
		expect((Collide.check(plan, "items", item("shape_cube_small", 20, 50, { y = Tuning.Plot.Foundation })))).toBe(true)
		-- a wall drawn through a piece is turned down too
		local sofa = planWith({ { "items", item("fancy_sofa_camel", 20, 60) } })
		local wok, wwhy = Collide.check(sofa, "walls", wall(10, 60, 30, 60))
		expect(wok).toBe(false)
		expect(wwhy).toBe("bumps into the camelback sofa")
		expect((Collide.check(sofa, "walls", wall(10, 66, 30, 66)))).toBe(true)
	end)

	it("takes stairs as their run and width, so they go down against a wall at either end", function()
		local stairs = Catalog.get("stairs_straight")
		local lo, hi = Vector3.new(1e9, 1e9, 1e9), Vector3.new(-1e9, -1e9, -1e9)
		for _, b in Collide.body(stairs) do
			lo = lo:Min(b.cf.Position - b.size / 2)
			hi = hi:Max(b.cf.Position + b.size / 2)
		end
		expect(hi.Z - lo.Z).toBeNear(stairs.size.Z)
		expect(hi.X - lo.X).toBeNear(stairs.size.X)
		expect(lo.Y).toBeNear(0)
		-- a wall along z = 50; its face toward the stairs at 49.7
		local plan = planWith({ { "walls", wall(4, 50, 40, 50) } })
		local z = 50 - Plan.wallThickness("wall") / 2 - stairs.size.Z / 2
		local function stair(r)
			return { id = "stairs_straight", x = X0 + 20, y = Tuning.Plot.Foundation, z = z, r = r, lv = 0 }
		end
		expect((Plan.validItem(plan, stair(0)))).toBe(true)
		expect((Collide.check(plan, "items", stair(0)))).toBe(true) -- its top end at the wall
		expect((Collide.check(plan, "items", stair(180)))).toBe(true) -- its foot at the wall
		-- one step further in, it is in the wall
		local into = stair(0)
		into.z += 1
		expect((Collide.check(plan, "items", into))).toBe(false)
		-- and things can't go where the stairs climb
		local climbed = planWith({ { "items", stair(0) } })
		expect((Collide.check(climbed, "items", item("shape_cube_small", 20, z)))).toBe(false)
	end)

	it("lets fence panels and porch rails share their posts", function()
		local plan = planWith({ { "items", item("fence_picket", 20, 20) } })
		-- a corner: the next panel turned a quarter, sharing the end post
		local corner = item("fence_picket", 22, 22, { r = 90 })
		expect((Collide.check(plan, "items", corner))).toBe(true)
		-- but not a cube in the fence
		expect((Collide.check(plan, "items", item("shape_cube_small", 20, 20)))).toBe(false)
	end)

	it("counts a stretched piece at the size it stands", function()
		local plan = planWith({ { "items", item("shape_cube_medium", 20, 20) } })
		local beside = item("shape_cube_medium", 25, 20)
		expect((Collide.check(plan, "items", beside))).toBe(true)
		beside.sx = 2 -- 8 wide now, reaching a stud into the cube's side
		expect((Collide.check(plan, "items", beside))).toBe(false)
	end)
end)

describe("Placing: the passes' rules for one change", function()
	it("turns down a piece in another without Free Placing, and lets an owner put it there", function()
		local plan = planWith({ { "items", item("shape_cube_medium", 20, 20) } })
		local req = { type = "add", kind = "items" }
		local inside = item("shape_cube_medium", 21, 20)
		local ok, why = Placing.check(plan, nobody, req, inside, nil, {}, true)
		expect(ok).toBe(false)
		expect(why).toBe("bumps into the medium cube")
		expect((Placing.check(plan, free, req, inside, nil, {}, true))).toBe(true)
	end)

	it("checks only a move: a piece an old save left in another can still be painted", function()
		local a = item("shape_cube_medium", 20, 20)
		local b = item("shape_cube_medium", 21, 20)
		local plan = planWith({ { "items", a }, { "items", b } })
		local painted = table.clone(b)
		painted.c1 = "C27E63"
		local set = { type = "set", kind = "items", key = "2" }
		expect((Placing.check(plan, nobody, set, painted, b, {}, true))).toBe(true)
		local moved = table.clone(b)
		moved.z += 1
		expect((Placing.check(plan, nobody, set, moved, b, {}, true))).toBe(false)
	end)

	it("lets the pieces of one change touch each other, but not what was there", function()
		local plan = planWith({ { "items", item("shape_cube_medium", 20, 20) }, { "items", item("shape_cube_medium", 50, 20) } })
		local req = { type = "add", kind = "items" }
		-- key 2 is a piece the same change put down
		expect((Placing.check(plan, nobody, req, item("shape_cube_medium", 51, 20), nil, { [1] = "2" }, false))).toBe(true)
		expect((Placing.check(plan, nobody, req, item("shape_cube_medium", 21, 20), nil, { [1] = "2" }, false))).toBe(false)
	end)

	it("turns in eighths without Free Placing, and in small steps with it", function()
		expect(Placing.turnStep(false)).toBe(45)
		expect(Placing.turnStep(false, true)).toBe(45)
		expect(Placing.turnStep(true)).toBe(15)
		expect(Placing.turnStep(true, true)).toBe(5)
		local plan = Plan.new()
		local req = { type = "add", kind = "items" }
		expect((Placing.check(plan, nobody, req, item("shape_cube_small", 20, 20, { r = 45 }), nil, {}, true))).toBe(true)
		local ok, why = Placing.check(plan, nobody, req, item("shape_cube_small", 20, 20, { r = 30 }), nil, {}, true)
		expect(ok).toBe(false)
		expect(why).toBe("turning to any angle needs the Free Placing pass")
		expect((Placing.check(plan, free, req, item("shape_cube_small", 20, 20, { r = 30 }), nil, {}, true))).toBe(true)
		-- a ready-made building put down whole keeps its own angles
		expect((Placing.check(plan, nobody, req, item("shape_cube_small", 20, 20, { r = 30 }), nil, {}, false))).toBe(true)
		-- a piece an old save left at 15 degrees still turns by eighths from there
		local old = item("shape_cube_small", 20, 20, { r = 15 })
		local turned = table.clone(old)
		turned.r = 60
		local set = { type = "set", kind = "items", key = "1" }
		expect((Placing.check(planWith({ { "items", old } }), nobody, set, turned, old, {}, true))).toBe(true)
	end)

	it("stretches only with the Stretch pass, and keeps a stretch someone had", function()
		local plan = Plan.new()
		local req = { type = "add", kind = "items" }
		local wide = item("shape_cube_small", 20, 20, { sx = 1.5 })
		local ok, why = Placing.check(plan, nobody, req, wide, nil, {}, true)
		expect(ok).toBe(false)
		expect(why).toBe("stretching needs the Stretch pass")
		expect((Placing.check(plan, { passes = { stretch = true } }, req, wide, nil, {}, true))).toBe(true)
		-- moved without the pass, it keeps the stretch it has
		local plan2 = planWith({ { "items", wide } })
		local moved = table.clone(wide)
		moved.x += 4
		expect((Placing.check(plan2, nobody, { type = "set", kind = "items", key = "1" }, moved, wide, {}, true))).toBe(true)
	end)

	it("paints off the palette only with Any Colour, but any colour on the plot is anyone's", function()
		local cube = item("shape_cube_small", 20, 20)
		local plan = planWith({ { "items", cube } })
		local set = { type = "set", kind = "items", key = "1" }
		local odd = table.clone(cube)
		odd.c1 = "123456"
		local ok, why = Placing.check(plan, nobody, set, odd, cube, {}, true)
		expect(ok).toBe(false)
		expect(why).toBe("that colour needs the Any Colour pass")
		expect((Placing.check(plan, { passes = { anycolour = true } }, set, odd, cube, {}, true))).toBe(true)
		local palette = table.clone(cube)
		palette.c1 = "C27E63"
		expect((Placing.check(plan, nobody, set, palette, cube, {}, true))).toBe(true)
		-- copied off a wall that already wears it
		local w = wall(10, 60, 20, 60)
		w.a.c = "123456"
		plan.walls["5"] = w
		expect((Placing.check(plan, nobody, set, odd, cube, {}, true))).toBe(true)
		-- a wall drawn in the default finish is anyone's
		expect((Placing.check(Plan.new(), nobody, { type = "add", kind = "walls" }, wall(10, 70, 20, 70), nil, {}, true))).toBe(true)
	end)

	it("puts a ready-made building down whole, kept clear of what is there", function()
		local preset = Presets.list[1]
		local plan = Plan.new(Tuning.Plot.Size)
		local x1, z1 = Plan.bounds(plan)
		local requests = Presets.requests(preset.id, x1 + 10, z1 + 10, 0)
		local fits, _, _, trial, made = Presets.check(plan, requests)
		expect(fits).toBe(true)
		expect((Collide.checkMade(plan, trial, made))).toBe(true)
		-- a cube where the building's first wall goes
		local first = trial.walls[made[1].key]
		local cube = {
			id = "shape_cube_small",
			x = (first.x1 + first.x2) / 2,
			y = 0,
			z = (first.z1 + first.z2) / 2,
			r = 0,
			lv = 0,
		}
		plan.items[Plan.newKey(plan)] = cube
		local fits2, _, _, trial2, made2 = Presets.check(plan, requests)
		expect(fits2).toBe(true)
		expect((Collide.checkMade(plan, trial2, made2))).toBe(false)
	end)
end)

describe("Stretch", function()
	it("keeps a stretch within the range and only along the sides a piece stretches", function()
		local cube = Catalog.get("shape_cube_small")
		expect((Stretch.valid(cube, { sx = 2, sy = 0.5, sz = 1.25 }))).toBe(true)
		expect((Stretch.valid(cube, { sx = 2.5 }))).toBe(false)
		expect((Stretch.valid(cube, { sy = 0.2 }))).toBe(false)
		expect((Stretch.valid(Catalog.get("door_wood"), { sx = 1.5 }))).toBe(false)
		expect((Stretch.valid(Catalog.get("mark_line"), { sy = 2 }))).toBe(false)
		expect((Stretch.valid(Catalog.get("mark_line"), { sx = 2 }))).toBe(true)
		local c = Stretch.clamped(cube, { id = "shape_cube_small", sx = 9, sy = 0.01, sz = 1 })
		expect(c.sx).toBe(Tuning.Passes.StretchMax)
		expect(c.sy).toBe(Tuning.Passes.StretchMin)
		expect(c.sz).toBe(nil)
	end)

	it("counts it in the footprint and the plot's edges, and clamps it when a save loads", function()
		local it = item("shape_cube_small", 20, 20, { sx = 2, sz = 1.5 })
		local x1, z1, x2, z2 = Plan.itemRect(it)
		expect(x2 - x1).toBeNear(4)
		expect(z2 - z1).toBeNear(3)
		-- a piece by the plot's edge fits until it is stretched past it
		local plan = Plan.new()
		local bx1, _, bx2 = Plan.bounds(plan)
		local edge = { id = "shape_cube_small", x = bx2 - 1.5, y = 0, z = 20, r = 0, lv = 0 }
		expect((Plan.validItem(plan, edge))).toBe(true)
		edge.sx = 2
		expect((Plan.validItem(plan, edge))).toBe(false)
		local _ = bx1
		-- a broken save: stretched too far comes back at the most, stretched on a door not at all
		local raw = Plan.new()
		raw.items["1"] = item("shape_cube_small", 20, 20, { sx = 7 })
		local clean = Plan.sanitize(raw)
		expect(clean.items["1"].sx).toBe(Tuning.Passes.StretchMax)
		-- and the field survives Plan.clean
		expect(Plan.clean("items", { id = "shape_cube_small", sx = 1.5, junk = 1 }).sx).toBe(1.5)
	end)

	it("draws every part scaled from the piece's foot, merged pieces too", function()
		local plan = Plan.new()
		plan.items["1"] = item("shape_cube_medium", 20, 20)
		plan.items["2"] = item("shape_cube_medium", 40, 20, { sx = 2, sy = 0.5 })
		local lo1, hi1 = Geometry.bounds(Geometry.flatten(Builder.primsFor(plan, "items", "1")))
		local lo2, hi2 = Geometry.bounds(Geometry.flatten(Builder.primsFor(plan, "items", "2")))
		expect((hi2.X - lo2.X) / (hi1.X - lo1.X)).toBeNear(2, 0.01)
		expect((hi2.Y - lo2.Y) / (hi1.Y - lo1.Y)).toBeNear(0.5, 0.01)
		expect((hi2.Z - lo2.Z) / (hi1.Z - lo1.Z)).toBeNear(1, 0.01)
		-- it still stands on the floor
		expect(lo2.Y).toBeNear(lo1.Y, 0.01)
		-- a piece drawn as pieces: every shape inside grows with it
		local withPieces
		for _, def in Catalog.all() do
			if Stretch.can(def) and def.place == "floor" then
				for _, p in Catalog.prims(def) do
					if p.shape == "Piece" then
						withPieces = def
						break
					end
				end
			end
			if withPieces then
				break
			end
		end
		expect(withPieces ~= nil).toBeTruthy()
		local plain = Catalog.prims(withPieces)
		local wide = Stretch.prims(Catalog.prims(withPieces), Vector3.new(1.5, 1, 1))
		local a1, a2 = Geometry.bounds(Geometry.flatten(plain))
		local b1, b2 = Geometry.bounds(Geometry.flatten(wide))
		expect((b2.X - b1.X) / (a2.X - a1.X)).toBeNear(1.5, 0.05)
		for i, p in wide do
			if p.shape == "Piece" then
				expect(p.key ~= plain[i].key).toBeTruthy()
			end
		end
	end)
end)
