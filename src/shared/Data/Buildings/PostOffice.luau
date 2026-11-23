--!strict
-- The post office: a tall gable to the street with a clock in it, and a lean-to that runs down
-- the right side under one long slope, over the sorting room at the back and an open bay at the
-- front where the bicycle and the parcels wait. Inside, a counter hall with the postie's desk
-- across it and pigeonholes behind.
local Shared = script.Parent.Parent.Parent
local Catalog = require(Shared.Build.Catalog)
local Plan = require(Shared.Build.Plan)
local Tuning = require(Shared.Config.Tuning)

type Finish = { c: string, m: string }

local F = Tuning.Plot.Foundation

-- finishes (Data/Palette's materials; colours from the town's palette)
local BOARDS: Finish = { c = "CCDDEA", m = "WoodPlanks" } -- sky blue weatherboards
local HALL: Finish = { c = "F2E6CC", m = "Plaster" }
local SORTING: Finish = { c = "DDBE94", m = "WoodPlanks" }
local CLAY: Finish = { c = "C27E63", m = "ClayRoofTiles" }
local OAK: Finish = { c = "C49A6C", m = "WoodPlanks" }
local BOARD_FLOOR: Finish = { c = "9A6B48", m = "WoodPlanks" }
local COBBLES: Finish = { c = "BDB8AE", m = "Cobblestone" }
local PAVING: Finish = { c = "DAD4C8", m = "Pavement" }
-- paint for the pieces
local TRIM = "FAF6EC"
local STONE = "BDB8AE"
local PALE_STONE = "DAD4C8"
local BERRY = "B8505A" -- the accent: the door, the awnings, the pillar box
local NAVY = "46608E"
local MUSTARD = "D9A93F"
local CORAL = "E08566"
local WALNUT = "9A6B48"
local OAK_PAINT = "C49A6C"
local DARK = "5A5560"

return function(add: any)
	add(
		"postoffice",
		"Post office",
		"A counter for letters and parcels, a sorting room at the back and a yard for the bicycle.",
		"gift",
		32,
		28,
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
			-- a white board up an outside corner (180 front left, 90 front right, 0 back
			-- right, 270 back left)
			local function corner(x: number, z: number, r: number)
				putAt("corner_board", x, z, r, 0, 0, TRIM, PALE_STONE)
			end
			-- a square window with a hood over it and a box of flowers under it
			local function window(wall: string, p: number, flowers: string)
				open("win_square", wall, p, TRIM, TRIM)
				hang("window_hood", wall, p, 3.4 + 4 + 0.38, "a", TRIM, CLAY.c)
				hang("window_box", wall, p, 3.4 - 1.35, "a", TRIM, flowers)
			end

			-- the shell ----------------------------------------------------------------------
			-- the counter hall x 2..20, z 6..26 under a steep gable; the sorting room x 20..30,
			-- z 14..24 and the open bay in front of it, both under the lean-to
			b:floor(2, 6, 20, 26, OAK)
			b:floor(20, 14, 30, 24, BOARD_FLOOR)
			b:floor(20, 2, 30, 14, COBBLES)
			b:floor(8, 0, 14, 4, PAVING)
			b:floor(2, 6, 20, 26, OAK, 1) -- the hall's ceiling
			b:floor(20, 14, 30, 24, OAK, 1)
			b:wall("front", 2, 6, 20, 6, BOARDS, HALL)
			b:wall("right1", 20, 6, 20, 14, BOARDS, HALL)
			b:wall("right2", 20, 14, 20, 24, SORTING, HALL)
			b:wall("right3", 20, 24, 20, 26, BOARDS, HALL)
			b:wall("back", 20, 26, 2, 26, BOARDS, HALL)
			b:wall("left", 2, 26, 2, 6, BOARDS, HALL)
			b:wall("sback", 30, 24, 20, 24, BOARDS, SORTING)
			b:wall("sfront", 20, 14, 30, 14, BOARDS, SORTING)
			b:wall("sright", 30, 14, 30, 24, BOARDS, SORTING)
			b:roof(2, 6, 20, 26, "gable", 9, 1, CLAY, BOARDS, 0, 0.8)
			-- the lean-to leaves the hall's right slope at x 16 and runs on down, shallower,
			-- to x 30; the hall runs on two studs past its back
			b:roof(16, 8, 30, 24, "shed", 4, 3, CLAY, BOARDS, 0, 0.6)

			-- doors and windows
			open("door_double", "front", 11, BERRY, TRIM)
			window("front", 4.8, CORAL)
			window("front", 17.2, MUSTARD)
			hang("awning", "front", 4.8, 7.6, "a", BERRY, TRIM)
			hang("awning", "front", 17.2, 7.6, "a", BERRY, TRIM)
			window("left", 10.4, CORAL)
			window("left", 21, MUSTARD)
			window("back", 15, CORAL)
			window("right1", 10, MUSTARD)
			open("door_wood", "right2", 19.6, OAK_PAINT, TRIM)
			open("door_garage", "sfront", 25, TRIM, PALE_STONE)
			window("sright", 19, CORAL)

			-- outside: stone at the feet of the walls, boards up the corners, drainpipes, the
			-- clock in the gable, the sign
			for _, wall in { "front", "left", "back", "right1", "sright", "sback" } do
				footing(wall)
			end
			corner(2, 6, 180)
			corner(20, 6, 90)
			corner(2, 26, 270)
			corner(20, 26, 0)
			corner(30, 24, 0)
			corner(30, 14, 90)
			hang("downpipe", "front", 2.7, 0, "a", DARK, DARK)
			hang("downpipe", "back", 3, 0, "a", DARK, DARK)
			hang("downpipe", "sback", 21, 0, "a", DARK, DARK)
			hang("downpipe", "sright", 23.3, 0, "a", DARK, DARK)
			putAt("gable_clock", 11, 6, 180, Plan.levelBase(1), 1, TRIM, NAVY)
			putAt("window_attic", 11, 26, 0, Plan.levelBase(1), 1, TRIM, BERRY)
			putAt("weathervane", 11, 16, 0, Plan.levelBase(1), 1)
			hang("sign_post", "front", 19.4, 8.8, "a", NAVY, TRIM)
			hang("lantern_wall", "front", 7.4, 5.8, "a")
			hang("lantern_wall", "front", 14.6, 5.8, "a")
			hang("trellis", "left", 15, 1.3, "a")
			hang("bunting", "sfront", 25, 9.6, "a")
			hang("lantern_wall", "right1", 12.9, 5.8, "a")

			-- the street side: steps, the pillar box, a bench, lamps
			put("doorstep", 11, 4.5, 180, PALE_STONE, STONE)
			put("postbox", 16.6, 2.4, 180, BERRY, DARK)
			put("bench_garden", 4.8, 3.2, 180)
			put("lamp_post", 7, 1, 0)
			put("flower_bed", 18.4, 4.4, 0)
			put("planter_box", 25, 1.2, 0, WALNUT, CORAL)

			-- the bay: posts under the lean-to, a rail, the bicycle and the parcels
			for _, x in { 22.6, 25.8, 29.2 } do
				putAt("porch_post", x, 8.5, 0, F, 0, TRIM, TRIM)
			end
			putAt("porch_rail", 27.5, 8.5, 0, F, 0, TRIM, TRIM)
			putAt("porch_rail", 29.2, 11.3, 90, F, 0, TRIM, TRIM)
			putAt("bicycle", 21.1, 11.2, 0, F, 0, NAVY, WALNUT)
			putAt("crate", 27.6, 12.4, 0, F)
			putAt("crate", 27.5, 12.5, 15, F + 2)
			putAt("crate", 25.3, 12.6, 0, F)
			putAt("parcel_cart", 23.7, 12.1, 200, F)

			-- the counter hall ------------------------------------------------------------
			-- the postie's desk and two counters across the hall, the staff's way through at
			-- the left end; pigeonholes, a desk and a cupboard behind
			put("work_post", 10.2, 16.4, 180, BERRY, TRIM)
			put("counter", 15.2, 16.4, 180, WALNUT)
			put("counter", 18.2, 16.4, 180, WALNUT)
			putAt("plant_small", 18.6, 16.2, 0, top("counter"))
			putAt("books_stack", 15.4, 16.1, 80, top("counter"))
			put("sorting_shelves", 4.6, 24.8, 180)
			put("sorting_shelves", 9.1, 24.8, 180)
			put("desk", 15, 24.4, 180, WALNUT)
			putAt("lamp_desk", 16.6, 24.8, 200, top("desk"))
			putAt("books_stack", 13.8, 24.6, 0, top("desk"))
			put("chair_wood", 15, 22.1, 0, WALNUT)
			put("coat_stand", 18.6, 24.8, 0)
			put("cabinet", 3.2, 21, 90, OAK_PAINT)
			putAt("kettle", 3.2, 20, 100, top("cabinet"))
			putAt("vase_flowers", 3.2, 22, 0, top("cabinet"))
			-- the public side: a writing desk, a bench, the queue on a runner
			put("desk", 3.5, 11, 90, OAK_PAINT)
			putAt("lamp_desk", 3.3, 12.6, 90, top("desk"))
			put("chair_wood", 5.9, 11, 270, OAK_PAINT)
			put("bench_wood", 18.8, 10.2, 270, OAK_PAINT, WALNUT)
			put("rug_long", 11, 10.1, 0, NAVY, MUSTARD)
			put("plant_big", 16.2, 7.9, 0)
			hang("clock_wall", "front", 11, 9.3, "b")
			hang("art_landscape", "left", 16, 6.4, "b")
			hang("shelf_wall", "back", 6.9, 8.4, "b")
			hang("art_flowers", "right1", 7.6, 6, "b")
			put("light_ceiling", 11, 9.6, 0)
			put("lamp_pendant", 10.2, 16.4, 0)
			put("lamp_pendant", 16.7, 16.4, 0)
			put("light_ceiling", 6, 21.4, 0)
			put("light_ceiling", 15, 21.4, 0)

			-- the sorting room ------------------------------------------------------------
			put("sorting_shelves", 23, 22.8, 180)
			put("sorting_shelves", 27.4, 22.8, 180)
			put("table_dining_small", 27.4, 18.6, 0, OAK_PAINT)
			putAt("books_stack", 27, 18.4, 30, top("table_dining_small"))
			putAt("crate", 27.9, 18.9, 10, top("table_dining_small"))
			put("parcel_cart", 22.3, 16.2, 0)
			put("crate", 28.6, 15.6, 0)
			put("stool", 25, 18.4, 0)
			put("light_ceiling", 25, 19, 0)
			hang("clock_wall", "right2", 16.4, 7.2, "a")
		end
	)
end
