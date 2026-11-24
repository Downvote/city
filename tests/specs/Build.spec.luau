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
local Colors = require(Shared .. "Util.Colors")

local P = Tuning.Plot
-- the starting land sits in the middle of the plot: x from X0, z from 0
local X0 = Plan.bounds(Plan.new())

local function wall(x1, z1, x2, z2, lv, style)
	return {
		x1 = x1 + X0,
		z1 = z1,
		x2 = x2 + X0,
		z2 = z2,
		lv = lv or 0,
		style = style or "wall",
		a = { c = "F2E8D5", m = "Plaster" },
		b = { c = "FFFFFF", m = "SmoothPlastic" },
	}
end

local function roof(style, dir)
	return {
		x1 = 10 + X0,
		z1 = 10,
		x2 = 30 + X0,
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
				if not Catalog.Tags[tag] and not Catalog.OtherTags[tag] then
					error(def.id .. " has an unknown tag " .. tag)
				end
			end
			local prims = Catalog.prims(def)
			expect(#prims > 0).toBeTruthy()
			-- hidden seat and sleep markers can stick out a little; only what you can see must fit
			local visible = {}
			local seats, beds, glows = 0, 0, 0
			for _, p in prims do
				if p.role == "seat" then
					seats += 1
				elseif p.role == "bed" then
					beds += 1
				elseif p.role == "glow" then
					glows += 1
				end
				if not ((p.transp or 0) >= 0.99 and (p.role == "seat" or p.role == "bed")) then
					table.insert(visible, p)
				end
			end
			if not Colors.isHex(def.c1) or (def.c2 ~= nil and not Colors.isHex(def.c2)) then
				error(def.id .. " has a bad default colour")
			end
			if def.cat == "seating" and seats == 0 then
				error(def.id .. " is seating with nowhere to sit")
			end
			if def.tags and table.find(def.tags, "bed") and beds == 0 then
				error(def.id .. " is a bed with nowhere to sleep")
			end
			if def.cat == "lights" and glows == 0 then
				error(def.id .. " is a light that never lights up")
			end
			local lo, hi = Geometry.bounds(visible)
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
		local s = { id = "stairs_straight", x = 20 + X0, y = P.Foundation, z = 20, r = 90, lv = 0 }
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
		local sofa = { id = "stairs_straight", x = X0 + 1, y = P.Foundation, z = 50, r = 0, lv = 0 }
		expect(Plan.validItem(plan, sofa)).toBe(false)
		-- and inside the land they own: past the edge is someone else's grass until they buy it
		local tree = { id = "tree_oak", x = X0 - 10, y = 0, z = 50, r = 0, lv = 0 }
		expect(Plan.validItem(plan, tree)).toBe(false)
		local big = Plan.new(Tuning.City.Land[#Tuning.City.Land].Size)
		expect(Plan.validItem(big, tree)).toBe(true)
	end)

	it("applies, inverts and refunds changes exactly", function()
		local plan = Plan.new()
		local ops = {
			{ op = "add", kind = "walls", key = Plan.newKey(plan), obj = wall(0, 0, 10, 0) },
			{
				op = "add",
				kind = "floors",
				key = Plan.newKey(plan),
				obj = { x1 = X0, z1 = 0, x2 = X0 + 10, z2 = 10, lv = 0, c = "C99A62", m = "WoodPlanks" },
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

	it("keeps only the fields each kind has", function()
		local w = wall(0, 0, 10, 0)
		w.junk = string.rep("x", 1000)
		w.a.extra = 5
		local clean = Plan.clean("walls", w)
		expect(clean.junk).toBe(nil)
		expect(clean.a.extra).toBe(nil)
		expect(clean.x2).toBe(w.x2)
		expect(Plan.validWall(clean)).toBe(true)
		local item = Plan.clean("items", { id = "tree_oak", x = 60, y = 0, z = 50, r = 0, lv = 0, evil = { 1, 2, 3 } })
		expect(item.evil).toBe(nil)
		expect(item.id).toBe("tree_oak")
	end)

	it("drops broken entries when loading saved data", function()
		local raw = {
			nextId = 3,
			walls = { ["1"] = wall(0, 0, 10, 0), ["7"] = { x1 = "x" } },
			floors = {},
			roofs = {},
			items = {
				["2"] = { id = "win_square", x = 0, y = 4, z = 0, r = 0, lv = 0, wall = "1", t = 5, side = "a" },
				["4"] = { id = "no_such_thing", x = X0 + 5, y = 0, z = 5, r = 0, lv = 0 },
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
		-- (the hole is cut 0.04 bigger all round than the 4 x 4 window, so the wall's cut faces
		-- sit inside its trim instead of flickering against it)
		expect(total).toBeNear(2 * (12 * height - 4.08 * 4.08), 1e-3)
	end)

	it("joins walls without any two sharing space, and closes corners", function()
		-- every piece of two walls, as boxes on the ground plan (the walls here run along x or z)
		local function boxes(plan, key)
			local r1, r2 = Shapes.wallReach(plan, key)
			local out = {}
			for _, p in Shapes.wall(plan.walls[key], {}, r1, r2) do
				local right = p.cf.RightVector
				local sx = math.abs(right.X) * p.size.X + math.abs(right.Z) * p.size.Z
				local sz = math.abs(right.Z) * p.size.X + math.abs(right.X) * p.size.Z
				table.insert(out, {
					p.cf.Position.X - sx / 2,
					p.cf.Position.Z - sz / 2,
					p.cf.Position.X + sx / 2,
					p.cf.Position.Z + sz / 2,
				})
			end
			return out
		end
		local function check(plan, corners)
			local all = {}
			for key in plan.walls do
				all[key] = boxes(plan, key)
			end
			for ka, a in all do
				for kb, b in all do
					if ka < kb then
						for _, p in a do
							for _, q in b do
								local ox = math.min(p[3], q[3]) - math.max(p[1], q[1])
								local oz = math.min(p[4], q[4]) - math.max(p[2], q[2])
								if ox > 1e-3 and oz > 1e-3 then
									error("walls " .. ka .. " and " .. kb .. " share space")
								end
							end
						end
					end
				end
			end
			-- every spot just inside a corner's four quarters is filled by something
			for _, c in corners do
				for _, d in { { 1, 1 }, { 1, -1 }, { -1, 1 }, { -1, -1 } } do
					local x = c[1] + X0 + d[1] * P.WallThickness * 0.25
					local z = c[2] + d[2] * P.WallThickness * 0.25
					local filled = false
					for _, list in all do
						for _, p in list do
							if x > p[1] and x < p[3] and z > p[2] and z < p[4] then
								filled = true
							end
						end
					end
					if not filled then
						error("a gap at the corner " .. c[1] .. ", " .. c[2])
					end
				end
			end
		end
		local function two(w)
			return w -- the helper's walls already have two different sides
		end
		local function one(w)
			w.b = table.clone(w.a) -- one colour through and through
			return w
		end
		-- an L, with each wall in turn two sided, and both ways round for who owns the corner
		for _, case in { { false, false }, { true, false }, { false, true }, { true, true } } do
			for _, flip in { false, true } do
				local plan = Plan.new()
				local a, b = wall(0, 0, 10, 0), wall(10, 0, 10, 10)
				if not case[1] then
					one(a)
				end
				if not case[2] then
					one(b)
				end
				plan.walls[if flip then "2" else "1"] = a
				plan.walls[if flip then "1" else "2"] = b
				check(plan, { { 10, 0 } })
			end
		end
		-- a room of two sided walls: four corners
		local room = Plan.new()
		room.walls["1"] = two(wall(0, 0, 10, 0))
		room.walls["2"] = two(wall(10, 0, 10, 10))
		room.walls["3"] = two(wall(10, 10, 0, 10))
		room.walls["4"] = two(wall(0, 10, 0, 0))
		check(room, { { 0, 0 }, { 10, 0 }, { 10, 10 }, { 0, 10 } })
		-- a T (a stem against two walls in line), a cross, and a stem against a wall's middle
		local t = Plan.new()
		t.walls["1"] = wall(0, 0, 10, 0)
		t.walls["2"] = wall(10, 0, 20, 0)
		t.walls["3"] = two(wall(10, 0, 10, 10))
		check(t, {})
		t.walls["4"] = wall(10, 0, 10, -10)
		check(t, {})
		local mid = Plan.new()
		mid.walls["1"] = wall(0, 0, 20, 0)
		mid.walls["2"] = two(wall(10, 0, 10, 10))
		check(mid, {})
		-- a hedge carrying a wall on from a corner: the two walls still close the corner between
		-- them (the wall's outside layer runs on to the far face), and the hedge starts at the
		-- face of the wall across its end
		local carry = Plan.new()
		carry.walls["1"] = two(wall(0, 0, 10, 0))
		carry.walls["2"] = two(wall(10, 0, 10, 10))
		carry.walls["3"] = wall(10, 0, 16, 0, 0, "hedge")
		check(carry, { { 10, 0 } })
		local _, onto = Shapes.wallReach(carry, "1")
		expect(math.max(onto[1], onto[2])).toBeNear(P.WallThickness / 2, 1e-6)
		local from = Shapes.wallReach(carry, "3")
		expect(from[1]).toBeNear(-P.WallThickness / 2, 1e-6)
		-- a straight run doesn't reach at all
		local run = Plan.new()
		run.walls["1"] = wall(0, 0, 10, 0)
		run.walls["2"] = wall(10, 0, 20, 0)
		local r1, r2 = Shapes.wallReach(run, "1")
		expect(r1[1]).toBe(0)
		expect(r2[1]).toBe(0)
		expect(r2[2]).toBe(0)
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

describe("Trim, garden and workshop pieces", function()
	-- the user: "improve the starting house detail by alot". What the starter house is dressed with
	-- are ordinary catalog pieces, so these hold wherever a player puts them too.
	it("hang on the outside of a wall round a window without cutting it", function()
		local plan = Plan.new()
		plan.walls["1"] = wall(0, 0, 12, 0)
		local w = plan.walls["1"]
		local sill = Plan.openingY(w, 3)
		plan.items["2"] = { id = "win_square", x = 0, y = sill, z = 0, r = 0, lv = 0, wall = "1", t = 6, side = "a" }
		local n = Plan.wallNormal(w)
		local heights = {
			shutters = sill - 0.15,
			window_box = sill - 1.35,
			window_hood = sill + 4.38,
			stone_footing = 0,
			downpipe = 0,
			trellis = 1.3,
			hanging_basket = 5,
			lantern_wall = 5.6,
			bunting = 8.8,
			tool_board = 4.6,
			sign_workshop = 8.4,
		}
		for id, y in heights do
			local def = Catalog.get(id)
			if not def then
				error("no catalog piece " .. id)
			end
			expect(def.place).toBe("wall")
			expect(def.opening).toBe(nil)
			local item = { id = id, x = 0, y = y, z = 0, r = 0, lv = 0, wall = "1", t = 6, side = "a" }
			local ok, why = Plan.validItem(plan, item)
			if not ok then
				error(id .. ": " .. tostring(why))
			end
			-- all of it is in front of the wall's face, none of it in the wall or behind it
			plan.items.x = item
			for _, p in Builder.primsFor(plan, "items", "x") do
				for _, c in Geometry.corners(p) do
					local out = (c - Vector3.new(w.x1, 0, w.z1)):Dot(n)
					if out < P.WallThickness / 2 - 0.01 then
						error(id .. " reaches into its wall")
					end
				end
			end
			plan.items.x = nil
		end
		expect(#Plan.openings(plan, "1")).toBe(1)
	end)

	it("give the bay window its hole, and a bay that stands out on the side it was put", function()
		local def = Catalog.get("win_bay")
		expect(def.opening.w).toBe(6)
		for _, side in { "a", "b" } do
			local plan = Plan.new()
			plan.walls["1"] = wall(0, 20, 12, 20)
			local w = plan.walls["1"]
			local item = {
				id = "win_bay",
				x = 0,
				y = Plan.openingY(w, def.opening.sill),
				z = 0,
				r = 0,
				lv = 0,
				wall = "1",
				t = 6,
				side = side,
			}
			expect(Plan.validItem(plan, item)).toBe(true)
			plan.items["2"] = item
			expect(#Plan.openings(plan, "1")).toBe(1)
			local n = Plan.wallNormal(w) * (if side == "a" then 1 else -1)
			local far, back = -math.huge, math.huge
			for _, p in Builder.primsFor(plan, "items", "2") do
				for _, c in Geometry.corners(p) do
					local out = (c - Vector3.new(w.x1, 0, w.z1)):Dot(n)
					far, back = math.max(far, out), math.min(back, out)
				end
			end
			expect(far > 1.5).toBeTruthy() -- the bay, well out from the wall
			expect(back > -0.7).toBeTruthy() -- only a sill on the other side
		end
	end)

	it("swing the garden gate on its own post, and leave its posts standing", function()
		local plan = Plan.new()
		plan.items["1"] = { id = "gate_garden", x = X0 + 30, y = 0, z = 30, r = 90, lv = 0 }
		expect(Plan.validItem(plan, plan.items["1"])).toBe(true)
		local folder = Instance.new("Folder")
		Builder.renderAll(plan, folder, CFrame.new(100, 0, 100))
		local leaves, still = 0, 0
		for _, d in folder:GetDescendants() do
			if d:IsA("BasePart") then
				if d:HasTag(Builder.Tags.DoorLeaf) then
					leaves += 1
					expect(d.CanCollide).toBe(false)
					local open = Builder.doorOpen(d)
					expect(open ~= nil).toBeTruthy()
					-- round its hinge: it ends up within the gate's own length, at the same height
					expect((open.Position - d.CFrame.Position).Magnitude < 5).toBeTruthy()
					expect(math.abs(open.Position.Y - d.CFrame.Position.Y) < 0.01).toBeTruthy()
				else
					still += 1
				end
			end
		end
		expect(leaves >= 5).toBeTruthy()
		expect(still >= 2).toBeTruthy()
	end)

	it("stand a weathervane on the level above, its vane clear of the roof under it", function()
		local def = Catalog.get("weathervane")
		local plan = Plan.new()
		local vane = { id = "weathervane", x = X0 + 30, y = Plan.levelBase(1), z = 30, r = 0, lv = 1 }
		expect(Plan.validItem(plan, vane)).toBe(true)
		-- the pole is long enough to come out of a steep roof on a narrow house
		expect(Plan.levelBase(1) + def.size.Y > Plan.levelTop(0) + 9 + 2).toBeTruthy()
		-- and it isn't something for the ground floor's ceiling
		vane.lv = P.Levels
		expect(Plan.validItem(plan, vane)).toBe(false)
	end)

	it("wrap a corner board round each corner of a room, outside its walls", function()
		-- a room 10 by 10: the board for each corner, turned as the starter house turns them
		local corners = { { 10, 10, 0 }, { 10, 0, 90 }, { 0, 0, 180 }, { 0, 10, 270 } }
		local def = Catalog.get("corner_board")
		for _, c in corners do
			local frame = CFrame.new(c[1], 0, c[2]) * CFrame.Angles(0, math.rad(c[3]), 0)
			for _, p in Catalog.prims(def) do
				local at = frame * p.cf.Position
				-- its middle is outside the room's outer faces
				local outside = at.X < -P.WallThickness / 2
					or at.X > 10 + P.WallThickness / 2
					or at.Z < -P.WallThickness / 2
					or at.Z > 10 + P.WallThickness / 2
				expect(outside).toBe(true)
			end
		end
	end)

	it("give the swing a seat and the crate a top to put things on", function()
		local seats = 0
		for _, p in Catalog.prims(Catalog.get("tree_swing")) do
			if p.role == "seat" then
				seats += 1
			end
		end
		expect(seats).toBe(1)
		expect(Catalog.get("crate").surface).toBe(Catalog.get("crate").size.Y)
		expect(Catalog.get("sawhorse").surface ~= nil).toBeTruthy()
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
		add("floors", { x1 = X0 + 10, z1 = 10, x2 = X0 + 30, z2 = 30, lv = 0, c = "C99A62", m = "WoodPlanks" })
		add("roofs", {
			x1 = X0 + 10,
			z1 = 10,
			x2 = X0 + 30,
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
				local ok, why = Plan.validate(plan, kind, obj, key)
				if not ok then
					error(kind .. " " .. key .. ": " .. tostring(why))
				end
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
		-- an open door stays in its doorway: swung round its own hinge, not round the plot's corner
		for _, d in folder:GetDescendants() do
			if d:IsA("BasePart") and d:HasTag(Builder.Tags.DoorLeaf) then
				local open = Builder.doorOpen(d)
				expect(open ~= nil).toBeTruthy()
				local from = d.CFrame.Position
				expect((open.Position - from).Magnitude < 9).toBeTruthy()
				expect(math.abs(open.Position.Y - from.Y) < 0.01).toBeTruthy()
			end
		end
		-- rebuilding a wall replaces its model
		Builder.render(plan, "walls", w1, folder, CFrame.new(100, 0, 100))
		expect(#folder:GetChildren()).toBe(7)
	end)

	it("draws balls, cylinders and cones with the low poly kit when there is one", function()
		local LowPoly = require(Shared .. "Build.LowPoly")
		expect(LowPoly.shapeFor("Ball", Vector3.new(2, 2, 2))).toBe("Gem")
		expect(LowPoly.shapeFor("Cylinder", Vector3.new(4, 1, 1))).toBe("Prism")
		expect(LowPoly.shapeFor("Cylinder", Vector3.new(0.3, 12, 12))).toBe("Disc")
		expect(LowPoly.shapeFor("Cone", Vector3.new(3, 5, 3))).toBe("Cone")
		expect(LowPoly.shapeFor("Block", Vector3.new(1, 1, 1))).toBe(nil)
		expect(LowPoly.shapeFor("Wedge", Vector3.new(1, 1, 1))).toBe(nil)
		local function prim(shape, size)
			return { shape = shape, cf = CFrame.new(1, 2, 3), size = size, color = Color3.new(1, 0, 0), mat = "Wood" }
		end
		local prims = {
			prim("Ball", Vector3.new(2, 2, 2)),
			prim("Cylinder", Vector3.new(4, 1, 1)),
			prim("Cylinder", Vector3.new(0.3, 12, 12)),
			prim("Cone", Vector3.new(3, 5, 3)),
			prim("Block", Vector3.new(1, 2, 3)),
		}
		-- stand-ins for the shapes the server cuts
		local kit = Instance.new("Folder")
		for _, name in LowPoly.Shapes do
			local shape = Instance.new("Part")
			shape.Name = name
			shape.Parent = kit
		end
		Builder.useKit(kit)
		expect(Builder.hasKit()).toBe(true)
		local holder = Instance.new("Folder")
		local parts = Builder.instantiate(prims, holder)
		local want = { "Gem", "Prism", "Disc", "Cone" }
		for i, name in want do
			expect(parts[i]:GetAttribute("Kit")).toBe(name)
			expect((parts[i].Size - prims[i].size).Magnitude < 1e-3).toBeTruthy()
			expect(parts[i].Material).toBe(Enum.Material.Wood)
			expect(parts[i].Anchored).toBe(true)
		end
		expect(parts[5]:GetAttribute("Kit")).toBe(nil)
		-- a cone keeps its place and its point up; a round gem is turned but stays where it was
		expect((parts[4].CFrame.Position - Vector3.new(1, 2, 3)).Magnitude < 1e-4).toBeTruthy()
		expect(parts[4].CFrame.UpVector.Y > 0.999).toBeTruthy()
		expect((parts[1].CFrame.Position - Vector3.new(1, 2, 3)).Magnitude < 1e-4).toBeTruthy()
		-- and without a kit everything is Roblox's own again
		Builder.useKit(nil)
		expect(Builder.hasKit()).toBe(false)
		local plain = Builder.instantiate(prims, holder)
		for i = 1, 5 do
			expect(plain[i]:GetAttribute("Kit")).toBe(nil)
		end
		expect(plain[1].Shape).toBe(Enum.PartType.Ball)
		expect(plain[4].Shape).toBe(Enum.PartType.Cylinder)
	end)

	it("only offers materials Roblox has", function()
		for _, m in Palette.Materials do
			expect((Enum.Material :: any)[m.id] ~= nil).toBeTruthy()
		end
	end)
end)
