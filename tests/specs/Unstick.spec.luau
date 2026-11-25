--!nocheck
-- Getting unstuck. The user: "villagers and the player can sometimes get stuck in objects".
--   * Sim/Unstick: where to stand somebody who is in something (the nearest spot with room, on
--     their side of any wall, on top of it when there is no room at all)
--   * Build/Solid: only a placed piece's body is solid, never its little parts, what hangs on
--     walls, sits on surfaces or lies flat; the Builder draws plots by it
--   * Npc: a walk that gets nowhere hops, finds a new path, then is moved on; getting up from a
--     seat or a bed stands them beside it; the path agent fits through every door
--   * Services/Unstick: who is moved when a piece goes down, and who is wedged

local Shared = "ReplicatedStorage.Shared."
local Tuning = require(Shared .. "Config.Tuning")
local Unstick = require(Shared .. "Sim.Unstick")
local Solid = require(Shared .. "Build.Solid")
local Catalog = require(Shared .. "Build.Catalog")
local Geometry = require(Shared .. "Build.Geometry")
local Recipe = require(Shared .. "Build.Recipe")
local Plan = require(Shared .. "Build.Plan")
local Builder = require(Shared .. "Build.Builder")

local K = Tuning.Unstick
local game = Harness.game()

-- a box between two corners
local function box(x1, y1, z1, x2, y2, z2)
	return {
		cf = CFrame.new((x1 + x2) / 2, (y1 + y2) / 2, (z1 + z2) / 2),
		size = Vector3.new(math.abs(x2 - x1), math.abs(y2 - y1), math.abs(z2 - z1)),
	}
end

-- a wall along x at z (0.6 thick, a storey tall), from x1 to x2
local function wallX(z, x1, x2)
	return box(x1, 0, z - 0.3, x2, 12, z + 0.3)
end
local function wallZ(x, z1, z2)
	return box(x - 0.3, 0, z1, x + 0.3, 12, z2)
end

local function flat(a, b)
	return Vector3.new(a.X - b.X, 0, a.Z - b.Z).Magnitude
end

describe("Unstick", function()
	describe("room to stand", function()
		it("tells boxes that overlap from boxes that don't, turned any way", function()
			local a = box(0, 0, 0, 2, 2, 2)
			expect(Unstick.overlaps(a, box(1, 1, 1, 3, 3, 3))).toBe(true)
			expect(Unstick.overlaps(a, box(2.1, 0, 0, 4, 2, 2))).toBe(false)
			-- a wall turned 45 degrees: its corner box reaches the body, the wall itself doesn't
			local turned =
				{ cf = CFrame.new(4, 1, 4) * CFrame.Angles(0, math.rad(45), 0), size = Vector3.new(6, 2, 0.6) }
			expect(Unstick.overlaps(box(5.4, 0, 5.4, 6.2, 2, 6.2), turned)).toBe(false)
			expect(Unstick.overlaps(box(3.6, 0, 3.6, 4.4, 2, 4.4), turned)).toBe(true)
			-- a line through it and a line past it
			expect(Unstick.crosses(turned, Vector3.new(0, 1, 8), Vector3.new(8, 1, 0))).toBe(true)
			expect(Unstick.crosses(turned, Vector3.new(0, 1, 8), Vector3.new(0, 1, 12))).toBe(false)
		end)

		it("leaves somebody in the open where they are, the floor under them not counted", function()
			local boxes = { box(-50, -1, -50, 50, 0, 50), wallX(5, -10, 10), box(3, 0, -1, 4, 0.4, 1) }
			local spot, how = Unstick.find(boxes, Vector3.new(0, 0, 0))
			expect(how).toBe("here")
			expect(spot).toBe(Vector3.new(0, 0, 0))
			-- a rug, a step or a path under the feet is stood on, not in
			spot, how = Unstick.find(boxes, Vector3.new(3.5, 0, 0))
			expect(how).toBe("here")
		end)

		it("stands somebody a sofa went down on beside it, out its near side", function()
			local sofa = box(-3.5, 0, -1.5, 3.5, 3.2, 1.5)
			local feet = Vector3.new(0.5, 0, 1)
			local spot, how = Unstick.find({ sofa }, feet, { away = Vector3.new(0, 0, 1) })
			expect(how).toBe("beside")
			expect(#Unstick.inside({ sofa }, spot)).toBe(0)
			expect(spot.Z > 1.5).toBeTruthy()
			-- the nearest such spot: out of the front and no further than a ring past it
			expect(flat(spot, feet) <= 1.5 - 1 + K.Width / 2 + K.Ring + 0.01).toBeTruthy()
			expect(spot.Y).toBe(0)
		end)

		it("never puts them through a wall when there is room on their own side", function()
			-- a wardrobe against the inside of a wall; the far side of the wall is nearer
			local boxes = { wallX(10, -20, 20), box(-2, 0, 7.5, 2, 7, 9.7) }
			local feet = Vector3.new(0, 0, 9.2)
			local spot, how = Unstick.find(boxes, feet, { away = Vector3.new(0, 0, 1) })
			expect(how).toBe("beside")
			expect(spot.Z < 9.7).toBeTruthy()
			expect(#Unstick.inside(boxes, spot)).toBe(0)
		end)

		it("goes through only when their side has no room, and on top when nowhere has", function()
			-- the same wardrobe filling a closet: walls all round it but the one outside
			local boxes = {
				wallX(10, -20, 20),
				wallX(7.2, -2.6, 2.6),
				wallZ(-2.3, 7.2, 10),
				wallZ(2.3, 7.2, 10),
				box(-2, 0, 7.5, 2, 7, 9.7),
			}
			local spot, how = Unstick.find(boxes, Vector3.new(0, 0, 9.2))
			expect(how).toBe("through")
			expect(spot.Z > 10.3).toBeTruthy()
			-- buried in something bigger than the search: up on top of it
			spot, how = Unstick.find({ box(-40, 0, -40, 40, 6, 40) }, Vector3.new(1, 0, 2))
			expect(how).toBe("top")
			expect(spot).toBe(Vector3.new(1, 6, 2))
		end)

		it("only stands them where there is floor, at about their own height", function()
			local crate = box(-1, 0, -1, 1, 2, 1)
			local floor = function(p)
				if p.X > 0.5 then
					return nil -- a stairwell to one side
				elseif p.Z > 0.5 then
					return 3 -- a platform too high to step onto
				elseif p.Z < -0.5 then
					return 0.5 -- a step
				end
				return 0
			end
			local spot, how = Unstick.find({ crate }, Vector3.new(0, 0, 0), { floor = floor })
			expect(how).toBe("beside")
			expect(spot.X <= 0.5).toBeTruthy()
			expect(spot.Z <= 0.5).toBeTruthy()
			expect(spot.Y).toBe(floor(spot))
		end)

		it("looks out the way it is told first", function()
			local post = box(-0.5, 0, -0.5, 0.5, 4, 0.5)
			local spot = Unstick.find({ post }, Vector3.new(0, 0, 0), { away = Vector3.new(-1, 0, 0) })
			expect(spot.X < -1).toBeTruthy()
			expect(math.abs(spot.Z) < 0.01).toBeTruthy()
			spot = Unstick.find({ post }, Vector3.new(0, 0, 0), { away = Vector3.new(0, 0, 1) })
			expect(spot.Z > 1).toBeTruthy()
		end)
	end)

	describe("what is solid", function()
		local function solidOf(def)
			local out = {}
			for _, p in Geometry.flatten(Solid.apply(def, Catalog.prims(def))) do
				if p.collide ~= false then
					table.insert(out, p)
				end
			end
			return out
		end

		it("makes nothing solid of what hangs, stands on a surface, lies flat or is a mark", function()
			local n = 0
			for _, def in Catalog.all() do
				if Solid.none(def) then
					n += 1
					if #solidOf(def) > 0 then
						error(def.id .. " has solid parts")
					end
				end
			end
			expect(n > 50).toBeTruthy()
			for _, id in { "pic_frame", "light_ceiling", "vase_flowers", "rug_round", "doormat" } do
				expect(Solid.none(Catalog.get(id))).toBe(true)
			end
		end)

		it("keeps no little part solid, no leaves, and nothing standing on a piece's top", function()
			for _, def in Catalog.all() do
				if not Solid.whole(def) then
					for _, p in solidOf(def) do
						if math.max(p.size.X, p.size.Y, p.size.Z) < K.Tiny then
							error(def.id .. ": a part " .. tostring(p.size) .. " is solid")
						end
						local mat = string.match(p.mat, "^[^:]+")
						if Solid.Foliage[mat] or p.name == "Leaf" then
							error(def.id .. ": leaves are solid")
						end
						if def.surface then
							local lo = Geometry.bounds({ p })
							if lo.Y >= def.surface - K.OnTop then
								error(def.id .. ": what stands on its top is solid")
							end
						end
					end
				end
			end
		end)

		it("still makes the body of furniture solid: no walking through a sofa", function()
			local bodies = {
				"sofa_three",
				"sofa_two",
				"armchair",
				"bed_double",
				"bed_single",
				"table_dining_long",
				"wardrobe",
				"bookcase_tall",
				"counter",
				"fridge",
				"kitchen_island",
				"piano",
				"bathtub",
				"desk",
			}
			for _, id in bodies do
				local def = Catalog.get(id)
				local solid = solidOf(def)
				if #solid == 0 then
					error(id .. " has nothing solid")
				end
				local lo, hi = Geometry.bounds(solid)
				local cover = (hi.X - lo.X) * (hi.Z - lo.Z) / (def.size.X * def.size.Z)
				if cover < 0.8 then
					error(string.format("%s: its solid parts cover %.0f%% of it", id, cover * 100))
				end
				-- solid up to a body's waist at least
				expect(hi.Y >= math.min(def.size.Y, 2.5) - 0.3).toBeTruthy()
			end
		end)

		it("keeps every part of the shapes, the stairs and the paths solid", function()
			local n = 0
			for _, def in Catalog.all() do
				if Solid.whole(def) and not Solid.none(def) then
					n += 1
					local before = 0
					for _, p in Geometry.flatten(Catalog.prims(def)) do
						if p.collide ~= false then
							before += 1
						end
					end
					expect(#solidOf(def)).toBe(before)
				end
			end
			expect(n > 20).toBeTruthy()
			expect(#solidOf(Catalog.get("shape_plank_small")) > 0).toBeTruthy()
		end)

		it("opens a body drawn as pieces, but not a workplace's or a door's", function()
			local function drawn(r)
				r:piece(function(q)
					q:block(-2, 0, -1, 2, 3, 1, r.c1) -- the body
					q:block(-0.1, 3, -0.1, 0.1, 3.3, 0.1, r.c1) -- a knob on it
				end)
			end
			local r = Recipe.new(Color3.new(1, 1, 1), Color3.new(1, 1, 1))
			drawn(r)
			local def = { id = "t", place = "floor", size = Vector3.new(4, 3.3, 2), cat = "decor" }
			local out = Solid.apply(def, r.prims)
			-- still one piece (the same parts are made), now solid, its shapes each saying
			expect(#out).toBe(1)
			expect(out[1].shape).toBe("Piece")
			expect(out[1].collide).toBe(true)
			expect(out[1].parts[1].collide).toBe(nil) -- the body: solid
			expect(out[1].parts[2].collide).toBe(false) -- the knob: too small
			local shapes = Geometry.flatten(out)
			expect(shapes[1].collide).toBe(true)
			expect(shapes[2].collide).toBe(false)
			-- what Catalog.prims drew is left as it was
			expect(r.prims[1].collide).toBe(false)
			expect(r.prims[1].parts[2].collide).toBe(nil)
			-- a workplace and a door keep theirs as drawn
			for _, other in
				{
					{ id = "w", place = "floor", size = def.size, cat = "work", job = "baker" },
					{ id = "d", place = "opening", size = def.size, cat = "doors" },
					{ id = "s", place = "stairs", size = def.size, cat = "structure" },
				}
			do
				local q = Recipe.new(Color3.new(1, 1, 1), Color3.new(1, 1, 1))
				drawn(q)
				local kept = Solid.apply(other, q.prims)
				expect(#kept).toBe(1)
				expect(kept[1].shape).toBe("Piece")
				expect(kept[1].collide).toBe(false)
			end
			-- and one whose drawing is solid by a hidden box (a ramp under stairs' treads)
			local h = Recipe.new(Color3.new(1, 1, 1), Color3.new(1, 1, 1))
			drawn(h)
			h:block(-2, 0, -1, 2, 3, 1, h.c1).transp = 1
			local kept = Solid.apply(def, h.prims)
			expect(kept[1].shape).toBe("Piece")
			expect(kept[2].collide).toBe(nil)
		end)

		it("is how the Builder draws what is placed on a plot", function()
			local plan = Plan.new()
			local x0, z0 = Plan.bounds(plan)
			plan.items["1"] = { id = "sofa_three", x = x0 + 20, y = 0, z = z0 + 20, r = 0, lv = 0 }
			plan.items["2"] = { id = "vase_flowers", x = x0 + 30, y = 0, z = z0 + 20, r = 0, lv = 0 }
			for key, item in plan.items do
				local def = Catalog.get(item.id)
				local want = #solidOf(def)
				local got = 0
				for _, p in Geometry.flatten(Builder.primsFor(plan, "items", key)) do
					if p.collide ~= false then
						got += 1
					end
				end
				expect(got).toBe(want)
			end
			-- and the parts it makes
			local folder = Instance.new("Folder")
			local model = Builder.render(plan, "items", "2", folder, CFrame.new())
			for _, d in model:GetDescendants() do
				if d:IsA("BasePart") then
					expect(d.CanCollide).toBe(false)
					if d.Transparency < 0.99 then
						expect(d.CanQuery).toBe(true) -- still picked in Build mode
					end
				end
			end
		end)

		it("keeps every workplace's spots clear of its solid parts", function()
			local Routine = require(Shared .. "Sim.Routine")
			for _, def in Catalog.workplaces() do
				local solid = solidOf(def)
				for _, stop in Routine.loop(def) do
					local best = math.huge
					for _, p in solid do
						local lo, hi = Geometry.bounds({ p })
						if hi.Y > stop.at.Y + 1.45 and lo.Y < stop.at.Y + 5.2 then
							local dx = math.max(lo.X - stop.at.X, stop.at.X - hi.X, 0)
							local dz = math.max(lo.Z - stop.at.Z, stop.at.Z - hi.Z, 0)
							best = math.min(best, math.sqrt(dx * dx + dz * dz))
						end
					end
					-- a body's half width at least (the Routine spec holds the drawn spots to more)
					if best < 0.9 then
						error(string.format("%s: %s stands %.2f from a solid part", def.id, stop.name, best))
					end
				end
			end
		end)
	end)

	describe("villagers", function()
		local function service(name)
			local ok, have = pcall(function()
				return game:GetService(name)
			end)
			if ok and type(have) == "table" then
				return have
			end
			local made = {}
			Harness.addService(name, made)
			return made
		end
		local paths = service("PathfindingService")
		service("TweenService")
		local Npc = require("ServerScriptService.Server.Npc.Npc")
		local Room = require("ServerScriptService.Server.Npc.Room")

		it("lets the path agent through the narrowest door with room to spare", function()
			local narrowest = math.huge
			for _, def in Catalog.list("doors") do
				if def.opening and def.opening.sill == 0 then
					narrowest = math.min(narrowest, def.opening.w)
				end
			end
			expect(narrowest < math.huge).toBeTruthy()
			expect(2 * K.Agent.Radius + 1 <= narrowest).toBeTruthy()
			-- a body looked for room for is the agent's width, so a spot found is one a path reaches
			expect(K.Width).toBeNear(2 * K.Agent.Radius, 0.01)
			expect(K.Agent.Height <= Tuning.Plot.LevelHeight - 4).toBeTruthy()
			-- and a hop comes before a new path, a new path before being moved
			expect(K.JumpAfter < K.ReplanAfter).toBeTruthy()
		end)

		local function signal()
			local fns = {}
			return {
				Connect = function(_, fn)
					table.insert(fns, fn)
					return {
						Disconnect = function()
							local i = table.find(fns, fn)
							if i then
								table.remove(fns, i)
							end
						end,
					}
				end,
				Fire = function(_, ...)
					for _, fn in table.clone(fns) do
						fn(...)
					end
				end,
			}
		end

		it("hops, then finds a new path, then is moved on when a walk gets nowhere", function()
			local list = {
				{ Position = Vector3.new(0, 0, 0), Action = Enum.PathWaypointAction.Walk },
				{ Position = Vector3.new(3, 0, 0), Action = Enum.PathWaypointAction.Walk },
				{ Position = Vector3.new(6, 0, 0), Action = Enum.PathWaypointAction.Walk },
			}
			local events = {}
			local oldCreate = rawget(paths, "CreatePath")
			paths.CreatePath = function()
				table.insert(events, "path")
				return {
					Status = Enum.PathStatus.Success,
					ComputeAsync = function() end,
					GetWaypoints = function()
						return list
					end,
				}
			end
			local self
			local free = false -- stuck until they are moved on
			local store = { MoveToFinished = signal() }
			function store.MoveTo(_, target)
				if free then
					self.root.Position = target
					store.MoveToFinished:Fire(true)
				end
			end
			local humanoid = setmetatable({}, {
				__index = store,
				__newindex = function(_, k, v)
					if k == "Jump" and v and events[#events] ~= "jump" then
						table.insert(events, "jump")
					end
					store[k] = v
				end,
			})
			self = setmetatable({
				model = { Parent = true },
				root = { Position = Vector3.new(0, 0, 0) },
				humanoid = humanoid,
				moving = 0,
				still = 0,
				sleeping = false,
				tracks = {},
				talkable = true,
			}, Npc)
			local realFree = Npc.free
			local at = nil
			Npc.free = function(npc, waypoint)
				table.insert(events, "free")
				at = waypoint
				npc.root.Position = waypoint
				free = true
				return true
			end
			local saved = { K.JumpAfter, K.ReplanAfter }
			K.JumpAfter, K.ReplanAfter = 0.004, 0.012
			local ok, got = pcall(function()
				return self:walkTo(Vector3.new(6, 0, 0), 5)
			end)
			K.JumpAfter, K.ReplanAfter = saved[1], saved[2]
			Npc.free = realFree
			paths.CreatePath = oldCreate
			if not ok then
				error(got)
			end
			expect(got).toBe(true)
			expect(table.concat(events, ",")).toBe("path,jump,path,jump,free,path")
			-- moved on to the waypoint they were making for
			expect(at).toBe(list[2].Position)
		end)

		it("stands them beside the seat or the bed they get up from", function()
			local beside = {}
			local realBeside = Room.standBeside
			Room.standBeside = function(model, thing)
				table.insert(beside, { model, thing })
				return true
			end
			local function body()
				local hum = {
					Sit = true,
					Jump = false,
					PlatformStand = false,
					ChangeState = function() end,
					MoveTo = function() end,
				}
				return setmetatable({
					model = { Parent = true, PivotTo = function() end },
					root = {
						Position = Vector3.zero,
						Size = Vector3.new(2, 2, 1),
						Anchored = false,
						IsDescendantOf = function()
							return false
						end,
					},
					humanoid = hum,
					moving = 0,
					still = 0,
					sleeping = false,
					tracks = {},
					talkable = true,
				}, Npc)
			end
			local ok, why = pcall(function()
				-- up from a seat they are in
				local seat = { Name = "Seat" }
				local a = body()
				a.seat = seat
				a.humanoid.SeatPart = seat
				a:standUp()
				expect(#beside).toBe(1)
				expect(beside[1][1]).toBe(a.model)
				expect(beside[1][2]).toBe(seat)
				expect(a.seat).toBe(nil)
				expect(a.humanoid.Sit).toBe(false)
				expect(a.humanoid.Jump).toBe(false) -- stood there, no hop off it
				-- a seat moved away under them has let them go already: just a hop
				local b = body()
				b.seat = seat
				b:standUp()
				expect(#beside).toBe(1)
				expect(b.humanoid.Jump).toBe(true)
				-- out of bed, beside it
				local spot = { CFrame = CFrame.new(0, 2, 0), Name = "BedSpot" }
				local c = body()
				c:sleep(spot)
				expect(c.bed).toBe(spot)
				expect(c.root.Anchored).toBe(true)
				c:standUp()
				expect(#beside).toBe(2)
				expect(beside[2][2]).toBe(spot)
				expect(c.bed).toBe(nil)
				expect(c.root.Anchored).toBe(false)
			end)
			Room.standBeside = realBeside
			if not ok then
				error(why)
			end
		end)
	end)

	describe("the service", function()
		local Services = "ServerScriptService.Server.Services."
		local fired = Harness.signal()
		local plan = Plan.new()
		local villagers = {}
		local folderKids = {}
		local folder = {
			FindFirstChild = function(_, name)
				return folderKids[name]
			end,
			GetChildren = function()
				local out = {}
				for _, m in folderKids do
					table.insert(out, m)
				end
				return out
			end,
		}
		Harness.stub(Services .. "Data", {
			get = function()
				return { plan = plan }
			end,
		})
		Harness.stub(Services .. "Plots", {
			indexOf = function()
				return 1
			end,
			buildFolder = function(i)
				return if i == 1 then folder else nil
			end,
			villagerFolder = function(i)
				return {
					GetChildren = function()
						return if i == 1 then villagers else {}
					end,
				}
			end,
		})
		Harness.stub(Services .. "Build", { Changed = fired })
		Harness.stub(Services .. "Unstick", nil)
		local oldPlayers = game:GetService("Players")
		local players = {}
		Harness.addService("Players", {
			GetPlayers = function()
				return players
			end,
		})
		local Service = require(Services .. "Unstick")
		local Room = require("ServerScriptService.Server.Npc.Room")
		local real = { inside = Room.inside, moveOut = Room.moveOut, feet = Room.feet, wedged = Room.wedged }
		local moved = {}
		Room.inside = function(body, within)
			for _, m in within do
				if body.inPiece == m then
					return true
				end
			end
			return false
		end
		Room.moveOut = function(body, opts)
			table.insert(moved, { body = body, away = opts and opts.away })
			return "beside"
		end
		Room.feet = function(body)
			return body.feet
		end
		Room.wedged = function(body)
			return body.wedged == true
		end

		local function piece(name, at)
			local m = {
				Name = name,
				IsA = function(_, c)
					return c == "Model"
				end,
				GetBoundingBox = function()
					return CFrame.new(at), Vector3.new(4, 3, 2)
				end,
			}
			folderKids[name] = m
			return m
		end
		local function person(at, opts)
			opts = opts or {}
			local seat = opts.seat
			local hum = { Health = 100, SeatPart = seat }
			local root = {
				Position = at + Vector3.new(0, 3, 0),
				Anchored = opts.anchored == true,
				IsA = function(_, c)
					return c == "BasePart"
				end,
			}
			return {
				feet = at,
				inPiece = opts.inPiece,
				wedged = opts.wedged,
				IsA = function(_, c)
					return c == "Model"
				end,
				FindFirstChildOfClass = function(_, c)
					return if c == "Humanoid" then hum else nil
				end,
				FindFirstChild = function(_, n)
					return if n == "HumanoidRootPart" then root else nil
				end,
			}
		end

		it("moves whoever a new piece went down on out of it, and nobody else", function()
			local sofa = piece("items_5", Vector3.new(10, 1.5, 10))
			local inIt = person(Vector3.new(10.5, 0, 10.8), { inPiece = sofa })
			local nearBy = person(Vector3.new(14, 0, 10))
			local asleep = person(Vector3.new(10, 0, 10), { inPiece = sofa, anchored = true })
			players = { { Character = inIt } }
			villagers = { nearBy, asleep }
			-- (its watch loop never ends, and the harness's waits don't wait: left out here)
			local realSpawn = task.spawn
			task.spawn = function() end
			Service.start()
			task.spawn = realSpawn
			fired:Fire({ Name = "P" }, {
				{
					op = "add",
					kind = "items",
					key = "5",
					obj = { id = "sofa_three", x = 0, y = 0, z = 0, r = 0, lv = 0 },
				},
			})
			expect(#moved).toBe(1)
			expect(moved[1].body).toBe(inIt)
			-- out from the sofa's middle, the way they were nearest
			expect(moved[1].away.Z > 0).toBeTruthy()
			-- a seat they sit in holds them in its own piece: not moved for that
			table.clear(moved)
			local seat = {
				IsDescendantOf = function(_, x)
					return x == sofa or x == workspace
				end,
			}
			local sitting = person(Vector3.new(10, 0, 10), { inPiece = sofa, seat = seat })
			villagers = { sitting }
			players = {}
			fired:Fire({ Name = "P" }, { { op = "set", kind = "items", key = "5", obj = { id = "sofa_three" } } })
			expect(#moved).toBe(0)
		end)

		it("frees somebody wedged in a placed part once it has lasted a moment", function()
			table.clear(moved)
			piece("items_6", Vector3.new(0, 0, 0))
			local wedged = person(Vector3.new(0, 0, 0), { wedged = true })
			local fine = person(Vector3.new(5, 0, 0))
			players = { { Character = wedged }, { Character = fine } }
			villagers = {}
			Service.look(100)
			expect(#moved).toBe(0)
			Service.look(100 + K.WedgedFor / 2)
			expect(#moved).toBe(0)
			Service.look(100 + K.WedgedFor + 0.01)
			expect(#moved).toBe(1)
			expect(moved[1].body).toBe(wedged)
			-- got out of it in between: the clock starts again
			wedged.wedged = false
			Service.look(200)
			wedged.wedged = true
			Service.look(200.5)
			Service.look(200.5 + K.WedgedFor / 2)
			expect(#moved).toBe(1)
		end)

		-- only this spec's copies keep the stand-ins
		for k, v in real do
			Room[k] = v
		end
		for _, name in { "Data", "Plots", "Build", "Unstick" } do
			Harness.stub(Services .. name, nil)
		end
		Harness.addService("Players", oldPlayers)
	end)
end)
