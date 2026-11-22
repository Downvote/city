--!nocheck
-- The build system: catalog entries, plan rules, wall/floor/roof shapes and the Part builder.

local Shared = "ReplicatedStorage.Shared."
local Tuning = require(Shared .. "Config.Tuning")
local Catalog = require(Shared .. "Build.Catalog")
local Plan = require(Shared .. "Build.Plan")
local Shapes = require(Shared .. "Build.Shapes")
local Geometry = require(Shared .. "Build.Geometry")
local Builder = require(Shared .. "Build.Builder")
local Palette = require(Shared .. "Data.Palette")

local P = Tuning.Plot

local function wall(x1, z1, x2, z2, lv, style)
	return {
		x1 = x1,
		z1 = z1,
		x2 = x2,
		z2 = z2,
		lv = lv or 0,
		style = style or "wall",
		a = { c = "F2E8D5", m = "Plaster" },
		b = { c = "FFFFFF", m = "SmoothPlastic" },
	}
end

local function roof(style, dir)
	return {
		x1 = 10,
		z1 = 10,
		x2 = 30,
		z2 = 22,
		lv = 0,
		style = style,
		rise = 6,
		dir = dir or 0,
		over = 1,
		c = "9C2A2E",
		m = "Slate",
		c2 = "F2E8D5",
		m2 = "Plaster",
	}
end

describe("Catalog", function()
	it("has items in every category", function()
		for _, cat in Catalog.Categories do
			expect(#Catalog.list(cat.id) > 0).toBeTruthy()
		end
	end)

	it("gives every item sane fields and a drawing that fits its box", function()
		for _, def in Catalog.all() do
			expect(type(def.name)).toBe("string")
			expect(def.price > 0).toBeTruthy()
			expect(Catalog.Places[def.place]).toBe(true)
			expect(def.size.X > 0 and def.size.Y > 0 and def.size.Z > 0).toBeTruthy()
			local found = false
			for _, cat in Catalog.Categories do
				if cat.id == def.cat then
					found = true
				end
			end
			if not found then
				error(def.id .. " has an unknown category " .. tostring(def.cat))
			end
			if def.place == "opening" then
				expect(def.opening ~= nil).toBeTruthy()
			end
			for _, tag in def.tags or {} do
				if
					not Catalog.Tags[tag]
					and tag ~= "bed"
					and tag ~= "stairs"
					and tag ~= "kitchen"
					and tag ~= "bath"
				then
					error(def.id .. " has an unknown tag " .. tag)
				end
			end
			local prims = Catalog.prims(def)
			expect(#prims > 0).toBeTruthy()
			local lo, hi = Geometry.bounds(prims)
			local s = def.size
			local slack = 0.6
			local yLo, yHi = -slack, s.Y + slack
			if def.place == "ceiling" then
				yLo, yHi = -s.Y - slack, slack
			end
			local zLo, zHi = -s.Z / 2 - slack, s.Z / 2 + slack
			if def.place == "wall" then
				zLo, zHi = -slack, s.Z + slack
			end
			if
				lo.X < -s.X / 2 - slack
				or hi.X > s.X / 2 + slack
				or lo.Y < yLo
				or hi.Y > yHi
				or lo.Z < zLo
				or hi.Z > zHi
			then
				error(
					string.format(
						"%s draws outside its size: bounds %s .. %s for size %s",
						def.id,
						tostring(lo),
						tostring(hi),
						tostring(s)
					)
				)
			end
			for _, p in prims do
				if not (Enum.Material :: any)[p.mat] then
					error(def.id .. " uses an unknown material " .. tostring(p.mat))
				end
			end
		end
	end)
end)

describe("Plan rules", function()
	it("accepts a normal wall and refuses bad ones", function()
		expect(Plan.validWall(wall(0, 0, 10, 0))).toBe(true)
		expect(Plan.validWall(wall(0, 0, 10, 10))).toBe(true) -- diagonals are fine
		expect(Plan.validWall(wall(0, 0, 1, 0))).toBe(false) -- off grid
		expect(Plan.validWall(wall(0, 0, 0, 0))).toBe(false)
		expect(Plan.validWall(wall(-2, 0, 10, 0))).toBe(false)
		expect(Plan.validWall(wall(0, 0, 100, 0))).toBe(false) -- too long
		expect(Plan.validWall(wall(0, 0, 10, 0, 9))).toBe(false)
		expect(Plan.validWall(wall(0, 0, 10, 0, 0, "lava"))).toBe(false)
		local w = wall(0, 0, 10, 0)
		w.a.m = "ForceField"
		expect(Plan.validWall(w)).toBe(false)
		local nanWall = wall(0, 0, 10, 0)
		nanWall.x2 = 0 / 0
		expect(Plan.validWall(nanWall)).toBe(false)
	end)

	it("fits doors on walls and keeps them apart", function()
		local plan = Plan.new()
		plan.walls["1"] = wall(0, 0, 12, 0)
		local w = plan.walls["1"]
		local door =
			{ id = "door_wood", x = 0, y = Plan.openingY(w, 0), z = 0, r = 0, lv = 0, wall = "1", t = 3, side = "a" }
		expect(Plan.validItem(plan, door)).toBe(true)
		plan.items["2"] = door
		local near = table.clone(door)
		near.t = 5
		expect(Plan.validItem(plan, near)).toBe(false)
		local far = table.clone(door)
		far.t = 9
		expect(Plan.validItem(plan, far)).toBe(true)
		local off = table.clone(door)
		off.t = 1
		expect(Plan.validItem(plan, off)).toBe(false)
		local missing = table.clone(door)
		missing.wall = "99"
		expect(Plan.validItem(plan, missing)).toBe(false)
		-- the door's hole shows up in the wall's openings
		local ops = Plan.openings(plan, "1")
		expect(#ops).toBe(1)
		expect(ops[1][3]).toBe(P.Foundation)
	end)

	it("keeps stairs on quarter turns and on the floor", function()
		local plan = Plan.new()
		local s = { id = "stairs_straight", x = 20, y = P.Foundation, z = 20, r = 90, lv = 0 }
		expect(Plan.validItem(plan, s)).toBe(true)
		s.r = 45
		expect(Plan.validItem(plan, s)).toBe(false)
		s.r = 0
		s.y = 5
		expect(Plan.validItem(plan, s)).toBe(false)
		s.y = Plan.levelBase(3)
		s.lv = 3
		expect(Plan.validItem(plan, s)).toBe(false)
	end)

	it("keeps items inside the plot", function()
		local plan = Plan.new()
		local sofa = { id = "stairs_straight", x = 1, y = P.Foundation, z = 50, r = 0, lv = 0 }
		expect(Plan.validItem(plan, sofa)).toBe(false)
	end)

	it("applies, inverts and refunds changes exactly", function()
		local plan = Plan.new()
		local ops = {
			{ op = "add", kind = "walls", key = Plan.newKey(plan), obj = wall(0, 0, 10, 0) },
			{
				op = "add",
				kind = "floors",
				key = Plan.newKey(plan),
				obj = { x1 = 0, z1 = 0, x2 = 10, z2 = 10, lv = 0, c = "C99A62", m = "WoodPlanks" },
			},
		}
		expect(Plan.apply(plan, ops)).toBe(true)
		local cost = Plan.changeCost(ops)
		expect(cost).toBe(10 * Tuning.Prices.WallPerStud + 25 * Tuning.Prices.FloorPerCell)
		local undo = Plan.invert(ops)
		expect(Plan.changeCost(undo)).toBe(-cost)
		expect(Plan.apply(plan, undo)).toBe(true)
		expect(Plan.count(plan, "walls")).toBe(0)
		expect(Plan.count(plan, "floors")).toBe(0)
		-- redo puts the same keys back
		expect(Plan.apply(plan, ops)).toBe(true)
		expect(plan.walls["1"] ~= nil).toBeTruthy()
	end)

	it("rolls back a change that fails halfway", function()
		local plan = Plan.new()
		local ops = {
			{ op = "add", kind = "walls", key = "1", obj = wall(0, 0, 10, 0) },
			{ op = "remove", kind = "walls", key = "50", obj = wall(0, 0, 10, 0) },
		}
		expect(Plan.apply(plan, ops)).toBe(false)
		expect(Plan.count(plan, "walls")).toBe(0)
	end)

	it("takes a wall's doors and windows with it", function()
		local plan = Plan.new()
		plan.walls["1"] = wall(0, 0, 12, 0)
		plan.items["2"] = { id = "win_square", x = 0, y = 4, z = 0, r = 0, lv = 0, wall = "1", t = 6, side = "b" }
		local ops = Plan.removeOps(plan, "walls", "1")
		expect(#ops).toBe(2)
		expect(Plan.apply(plan, ops)).toBe(true)
		expect(Plan.count(plan, "items")).toBe(0)
	end)

	it("drops broken entries when loading saved data", function()
		local raw = {
			nextId = 3,
			walls = { ["1"] = wall(0, 0, 10, 0), ["7"] = { x1 = "x" } },
			floors = {},
			roofs = {},
			items = {
				["2"] = { id = "win_square", x = 0, y = 4, z = 0, r = 0, lv = 0, wall = "1", t = 5, side = "a" },
				["4"] = { id = "no_such_thing", x = 5, y = 0, z = 5, r = 0, lv = 0 },
				["5"] = { id = "win_square", x = 0, y = 4, z = 0, r = 0, lv = 0, wall = "9", t = 5, side = "a" },
			},
		}
		local plan = Plan.sanitize(raw)
		expect(Plan.count(plan, "walls")).toBe(1)
		expect(Plan.count(plan, "items")).toBe(1)
		expect(plan.nextId >= 3).toBeTruthy()
	end)
end)

describe("Shapes", function()
	it("cuts doors and windows out of a wall", function()
		local w = wall(0, 0, 12, 0)
		local plain = Shapes.wall(w, {})
		local cut = Shapes.wall(w, { { 6, 4, 3, 7 } })
		-- two sides with different paint: 2 slabs plain; with a window: left, right, below, above x 2
		expect(#plain).toBe(2)
		expect(#cut).toBe(8)
		local total = 0
		for _, p in cut do
			total += p.size.X * p.size.Y
		end
		local _, height = Plan.wallSpan("wall", 0)
		expect(total).toBeNear(2 * (12 * height - 16), 1e-3)
	end)

	it("closes corners but not straight runs", function()
		local plan = Plan.new()
		plan.walls["1"] = wall(0, 0, 10, 0)
		plan.walls["2"] = wall(10, 0, 10, 10)
		plan.walls["3"] = wall(10, 10, 20, 10)
		plan.walls["4"] = wall(20, 10, 30, 10)
		local a1, a2 = Shapes.wallReach(plan, "1")
		expect(a1).toBe(0)
		expect(a2).toBeNear(P.WallThickness / 2)
		local c1, c2 = Shapes.wallReach(plan, "3")
		expect(c1).toBeNear(P.WallThickness / 2)
		expect(c2).toBe(0)
	end)

	it("draws every wall style", function()
		for style in Plan.WallStyles do
			local prims = Shapes.wall(wall(0, 0, 12, 0, 0, style), {})
			expect(#prims > 0).toBeTruthy()
		end
	end)

	it("cuts stairwells out of floors", function()
		local rects = Shapes.subtract({ { 0, 0, 20, 20 } }, { 5, 5, 9, 19 })
		local area = 0
		for _, r in rects do
			area += (r[3] - r[1]) * (r[4] - r[2])
		end
		expect(area).toBeNear(400 - 56)
		local f = { x1 = 0, z1 = 0, x2 = 20, z2 = 20, lv = 1, c = "C99A62", m = "WoodPlanks" }
		expect(#Shapes.floor(f, {}) > 0).toBeTruthy()
	end)

	it("draws every roof style in every direction, resting on the walls", function()
		for style in Plan.RoofStyles do
			for dir = 0, 3 do
				local r = roof(style, dir)
				local prims = Shapes.roof(r)
				expect(#prims > 0).toBeTruthy()
				local lo, hi = Geometry.bounds(prims)
				local y0 = Plan.levelTop(0)
				expect(lo.Y > y0 - 3).toBeTruthy()
				expect(hi.Y < y0 + r.rise + 3).toBeTruthy()
				expect(lo.X > r.x1 - r.over - 1).toBeTruthy()
				expect(hi.X < r.x2 + r.over + 1).toBeTruthy()
			end
		end
	end)

	it("makes triangles from two wedges covering the right area", function()
		local tri = Geometry.triangle(
			Vector3.new(0, 0, 0),
			Vector3.new(4, 0, 0),
			Vector3.new(1, 3, 0),
			0.2,
			Color3.new(1, 1, 1)
		)
		expect(#tri).toBe(2)
		local area = 0
		for _, w in tri do
			area += w.size.Y * w.size.Z / 2
		end
		expect(area).toBeNear(6, 1e-3)
	end)
end)

describe("Builder", function()
	it("builds parts for a small house", function()
		local plan = Plan.new()
		local function add(kind, obj)
			local key = Plan.newKey(plan)
			plan[kind][key] = obj
			return key
		end
		local w1 = add("walls", wall(10, 10, 30, 10))
		add("walls", wall(30, 10, 30, 30))
		add("walls", wall(30, 30, 10, 30))
		add("walls", wall(10, 30, 10, 10))
		add("floors", { x1 = 10, z1 = 10, x2 = 30, z2 = 30, lv = 0, c = "C99A62", m = "WoodPlanks" })
		add("roofs", {
			x1 = 10,
			z1 = 10,
			x2 = 30,
			z2 = 30,
			lv = 0,
			style = "gable",
			rise = 7,
			dir = 0,
			over = 1,
			c = "9C2A2E",
			m = "Slate",
			c2 = "F2E8D5",
			m2 = "Plaster",
		})
		local w = plan.walls[w1]
		add(
			"items",
			{ id = "door_front", x = 0, y = Plan.openingY(w, 0), z = 0, r = 0, lv = 0, wall = w1, t = 10, side = "b" }
		)
		for kind in Plan.KindSet do
			for key, obj in plan[kind] do
				expect(Plan.validate(plan, kind, obj, key)).toBe(true)
			end
		end
		local folder = Instance.new("Folder")
		Builder.renderAll(plan, folder, CFrame.new(100, 0, 100))
		expect(#folder:GetChildren()).toBe(7)
		local parts = 0
		local doors = 0
		for _, d in folder:GetDescendants() do
			if d:IsA("BasePart") then
				parts += 1
				if d:HasTag(Builder.Tags.DoorLeaf) then
					doors += 1
				end
			end
		end
		expect(parts > 20).toBeTruthy()
		expect(doors > 0).toBeTruthy()
		-- rebuilding a wall replaces its model
		Builder.render(plan, "walls", w1, folder, CFrame.new(100, 0, 100))
		expect(#folder:GetChildren()).toBe(7)
	end)

	it("only offers materials Roblox has", function()
		for _, m in Palette.Materials do
			expect((Enum.Material :: any)[m.id] ~= nil).toBeTruthy()
		end
	end)
end)
