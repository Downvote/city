--!strict
-- The schoolhouse: a red brick hall with its ridge across, a bell tower over the door with an
-- open belfry and a slate spire, and a fenced playground beside it. Inside, two rows of desks
-- face the chalkboard, with a stove, the teacher's desk and the children's paintings.
local Shared = script.Parent.Parent.Parent
local Catalog = require(Shared.Build.Catalog)
local Plan = require(Shared.Build.Plan)
local Tuning = require(Shared.Config.Tuning)

type Finish = { c: string, m: string }

local F = Tuning.Plot.Foundation

-- finishes (Data/Palette's materials; colours from the town's palette)
local BRICK: Finish = { c = "D69A82", m = "Brick" }
local PLASTER: Finish = { c = "F2E6CC", m = "Plaster" }
local LOBBY: Finish = { c = "F6F0E2", m = "Plaster" }
local BOARDS: Finish = { c = "FAF6EC", m = "WoodPlanks" } -- the belfry
local SLATE: Finish = { c = "4F6488", m = "Slate" }
local OAK: Finish = { c = "C49A6C", m = "WoodPlanks" }
local TILES: Finish = { c = "E6D5B4", m = "CeramicTiles" }
local PAVING: Finish = { c = "DAD4C8", m = "Pavement" }
-- paint for the pieces
local TRIM = "FAF6EC"
local STONE = "BDB8AE"
local PALE_STONE = "DAD4C8"
local FOREST = "4E7F62" -- the doors
local MUSTARD = "D9A93F"
local CORAL = "E08566"
local OAK_PAINT = "C49A6C"
local WALNUT = "9A6B48"

return function(add: any)
	add(
		"school",
		"Schoolhouse",
		"A classroom of desks round a chalkboard, a bell tower over the door and a playground.",
		"blueprint",
		36,
		30,
		function(b: any)
			-- the little helpers -------------------------------------------------------------
			local function paint(c1: string?, c2: string?)
				local o = b.objects[#b.objects].obj
				o.c1, o.c2 = c1, c2
			end
			-- how far along a wall a point on its line is
			local function along(name: string, p: number): number
				local w = b.walls[name]
				if w.z1 == w.z2 then
					return math.abs(p - w.x1)
				end
				return math.abs(p - w.z1)
			end
			local function open(id: string, wall: string, p: number, c1: string?, c2: string?)
				b:open(id, wall, along(wall, p))
				paint(c1, c2)
			end
			-- something hung on a wall `t` along it, its foot `y` above the wall's foot, on side
			-- a (out) or b (in)
			local function hangT(id: string, wall: string, t: number, y: number, side: string, c1: string?, c2: string?)
				table.insert(b.objects, {
					kind = "items",
					obj = {
						id = id,
						x = 0,
						y = y,
						z = 0,
						r = 0,
						lv = b.walls[wall].lv,
						t = t,
						side = side,
						c1 = c1,
						c2 = c2,
					},
					wallName = wall,
				})
			end
			local function hang(id: string, wall: string, p: number, y: number, side: string, c1: string?, c2: string?)
				hangT(id, wall, along(wall, p), y, side, c1, c2)
			end
			local function put(id: string, x: number, z: number, r: number, c1: string?, c2: string?)
				b:item(id, x, z, r)
				paint(c1, c2)
			end
			local function putAt(
				id: string,
				x: number,
				z: number,
				r: number,
				y: number,
				lv: number?,
				c1: string?,
				c2: string?
			)
				b:item(id, x, z, r, lv or 0, y)
				paint(c1, c2)
			end
			-- the top of a piece standing on the ground floor
			local function top(id: string): number
				local def = Catalog.get(id)
				return F + (if def and def.surface then def.surface else 0)
			end
			-- a stone course along the foot of a wall, round its doors
			local function footing(wall: string)
				local w = b.walls[wall]
				local len = Plan.wallLength(w)
				local cuts = {}
				for _, o in b.objects do
					if o.wallName == wall then
						local def = Catalog.get(o.obj.id)
						if def and def.opening and def.opening.sill < 1 then
							table.insert(cuts, { o.obj.t - def.opening.w / 2 - 0.3, o.obj.t + def.opening.w / 2 + 0.3 })
						end
					end
				end
				table.sort(cuts, function(p, q)
					return p[1] < q[1]
				end)
				local s = 0
				table.insert(cuts, { len, len })
				for _, c in cuts do
					local run = c[1] - s
					if run >= 3.9 then
						local n = math.ceil(run / 4 - 1e-6)
						for i = 0, n - 1 do
							local t = s + 2 + (if n > 1 then i * (run - 4) / (n - 1) else (run - 4) / 2)
							hangT("stone_footing", wall, t, 0, "a", STONE, PALE_STONE)
						end
					end
					s = c[2]
				end
			end
			-- quoins of pale stone up a brick corner (corner_board: 180 front left, 90 front
			-- right, 0 back right, 270 back left)
			local function corner(x: number, z: number, r: number, lv: number?)
				putAt(
					"corner_board",
					x,
					z,
					r,
					if (lv or 0) == 0 then 0 else Plan.levelBase(lv :: number),
					lv,
					PALE_STONE,
					STONE
				)
			end
			-- a pair of tall windows under one hood, with one box of flowers
			local function pair(wall: string, p: number)
				open("win_tall", wall, p - 1.4, TRIM, TRIM)
				open("win_tall", wall, p + 1.4, TRIM, TRIM)
				hang("window_hood", wall, p, 2.4 + 6 + 0.38, "a", TRIM, SLATE.c)
				hang("window_box", wall, p, 2.4 - 1.35, "a", TRIM, CORAL)
			end

			-- the shell ----------------------------------------------------------------------
			-- the hall: x 2..26, z 12..28, its front split round the tower
			b:floor(2, 12, 26, 28, OAK)
			b:floor(10, 6, 18, 12, TILES)
			b:wall("fl", 2, 12, 10, 12, BRICK, PLASTER)
			b:wall("mid", 10, 12, 18, 12, LOBBY, PLASTER)
			b:wall("fr", 18, 12, 26, 12, BRICK, PLASTER)
			b:wall("right", 26, 12, 26, 28, BRICK, PLASTER)
			b:wall("back", 26, 28, 2, 28, BRICK, PLASTER)
			b:wall("left", 2, 28, 2, 12, BRICK, PLASTER)
			-- the tower: a brick porch below, an open belfry of white boards above
			b:wall("tfront", 10, 6, 18, 6, BRICK, LOBBY)
			b:wall("tright", 18, 6, 18, 12, BRICK, LOBBY)
			b:wall("tleft", 10, 12, 10, 6, BRICK, LOBBY)
			b:floor(10, 6, 18, 12, OAK, 1)
			b:box("bel", 10, 6, 18, 12, BOARDS, BOARDS, 1)
			b:roof(2, 12, 26, 28, "gable", 8, 0, SLATE, BRICK, 0, 1)
			b:roof(10, 6, 18, 12, "pyramid", 7, 0, SLATE, BOARDS, 1, 0.8)

			-- doors and windows
			open("door_double", "tfront", 14, FOREST, TRIM)
			open("arch_open", "mid", 14, TRIM, TRIM)
			open("door_front", "right", 14.4, FOREST, TRIM)
			pair("fl", 6)
			pair("fr", 22)
			pair("left", 15)
			pair("right", 20.6)
			pair("back", 6)
			pair("back", 22)
			for _, wall in { "belfront", "belright", "belleft" } do
				b:open("arch_open", wall, 4 - (if wall == "belfront" then 0 else 1))
				paint(TRIM, TRIM)
			end

			-- outside the walls: stone at their feet, quoins, drainpipes, lamps
			for _, wall in { "fl", "fr", "right", "back", "left", "tfront", "tright", "tleft" } do
				footing(wall)
			end
			corner(2, 12, 180)
			corner(26, 12, 90)
			corner(26, 28, 0)
			corner(2, 28, 270)
			corner(10, 6, 180)
			corner(18, 6, 90)
			for _, c in { { 10, 6, 180 }, { 18, 6, 90 }, { 18, 12, 0 }, { 10, 12, 270 } } do
				putAt("corner_board", c[1], c[2], c[3], Plan.levelBase(1), 1, TRIM, TRIM)
			end
			hang("downpipe", "fl", 2.7, 0, "a", "5A5560", "5A5560")
			hang("downpipe", "fr", 25.3, 0, "a", "5A5560", "5A5560")
			hang("downpipe", "back", 13, 0, "a", "5A5560", "5A5560")
			hang("clock_wall", "tfront", 14, 9.3, "a")
			hang("lantern_wall", "tleft", 7, 5.6, "a")
			hang("lantern_wall", "tright", 11, 5.6, "a")
			hang("trellis", "left", 25, 1.3, "a")
			hang("trellis", "back", 14, 1.3, "a")
			-- up in the gables and the tower
			putAt("window_attic", 2, 20, 270, Plan.levelBase(1), 1, TRIM, FOREST)
			putAt("window_attic", 26, 20, 90, Plan.levelBase(1), 1, TRIM, FOREST)
			putAt("school_bell", 14, 9, 0, Plan.levelBase(1), 1)
			putAt("weathervane", 14, 9, 0, Plan.levelBase(2), 2)

			-- the porch under the tower -------------------------------------------------------
			put("doorstep", 14, 4.45, 180, PALE_STONE, STONE)
			put("doormat", 14, 7.6, 0)
			for _, x in { 11.2, 16.8 } do
				put("bench_wood", x, 9.1, if x < 14 then 90 else 270, OAK_PAINT, WALNUT) -- (clear of the arch)
			end
			hang("coat_hooks", "tleft", 9.1, 5.2, "b")
			hang("coat_hooks", "tright", 9.1, 5.2, "b")
			put("light_ceiling", 14, 9, 0)

			-- the classroom -------------------------------------------------------------------
			-- the board on the back wall and the teacher in front of it, two rows of desks
			-- either side of the aisle facing it, the stove on the left wall
			put("work_school", 14, 26.3, 180)
			for _, x in { 8, 20 } do
				for _, z in { 16, 20 } do
					put("school_desk", x, z, 180, OAK_PAINT, "5A5560")
				end
			end
			put("rug_long", 14, 18, 0, "B8665C", MUSTARD)
			put("chimney_hearth", 3.9, 20, 90, "C8785A", PALE_STONE)
			put("bookshelf", 3.1, 25, 90, WALNUT)
			putAt("globe", 3.1, 25.2, 0, F + 6.4)
			-- the teacher's corner: desk, chair and a cupboard with the kettle on it
			put("desk", 21.6, 24.2, 180, WALNUT)
			putAt("lamp_desk", 23, 24.4, 200, top("desk"))
			putAt("books_stack", 20.4, 24.3, 10, top("desk"))
			putAt("vase_flowers", 21.8, 24.6, 0, top("desk"))
			put("chair_wood", 21.6, 26.4, 180, WALNUT)
			put("cabinet", 24.8, 24.6, 270, OAK_PAINT)
			putAt("kettle", 24.9, 23.6, 250, top("cabinet"))
			putAt("plant_small", 24.9, 25.8, 0, top("cabinet"))
			hang("clock_wall", "back", 14, 8.6, "b")
			hang("art_abstract", "right", 24.6, 4.6, "b")
			hang("art_flowers", "right", 25.9, 7.8, "b") -- (hung above the other, not over it)
			hang("art_landscape", "fl", 6, 8.9, "b")
			hang("shelf_wall", "fr", 22, 9.4, "b")
			hang("curtains", "left", 15.05, 2.25, "b")
			hang("bunting", "mid", 14, 10.2, "b")
			for _, x in { 8, 20 } do
				put("lamp_pendant", x, 18, 0)
			end
			put("lamp_pendant", 14, 23.4, 0)
			put("plant_big", 3.9, 13.9, 0)

			-- the front garden ----------------------------------------------------------------
			b:floor(12, 0, 16, 4, PAVING)
			put("lamp_post", 10.2, 2, 0)
			put("lamp_post", 17.8, 2, 0)
			put("flower_border", 6, 11, 0, PALE_STONE, CORAL)
			put("flower_border", 22, 11, 0, PALE_STONE, MUSTARD)
			put("tree_blossom", 5, 4.5, 0)
			put("bench_garden", 22, 3.2, 180)
			put("bush", 2.6, 10.1, 0)
			put("bush", 25.4, 9.4, 0)
			put("bicycle", 21.2, 9, 90)

			-- the playground ------------------------------------------------------------------
			-- picket fence round it, the gate by the side door
			put("gate_garden", 28.6, 12, 0, TRIM, TRIM)
			put("fence_picket", 32.8, 12, 0, TRIM)
			for _, z in { 14, 18, 22, 26 } do
				put("fence_picket", 34.6, z, 90, TRIM)
			end
			put("fence_picket", 28.4, 27.8, 0, TRIM)
			put("fence_picket", 32.4, 27.8, 0, TRIM)
			put("swing_set", 30.8, 24.4, 0)
			put("sandbox", 28.8, 19, 0)
			put("slide", 32.8, 16.4, 180)
			put("tree_oak", 31, 5, 0)
		end
	)
end
