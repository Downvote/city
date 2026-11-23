--!strict
-- The library: a sandstone block of two storeys under a big hip roof, with a pediment on four
-- round pillars over the steps and a walled reading garden at the side. Inside, the reading
-- room rises the full two storeys; a gallery of book stacks runs across the back, up a stair,
-- over the librarian's desk and the tall cases.
local Shared = script.Parent.Parent.Parent
local Catalog = require(Shared.Build.Catalog)
local Plan = require(Shared.Build.Plan)
local Tuning = require(Shared.Config.Tuning)

type Finish = { c: string, m: string }

local F = Tuning.Plot.Foundation

-- finishes (Data/Palette's materials; colours from the town's palette)
local SANDSTONE: Finish = { c = "E6D5B4", m = "Sandstone" }
local INSIDE: Finish = { c = "F2E6CC", m = "Plaster" }
local ROOF: Finish = { c = "6A5C5A", m = "Slate" } -- cocoa slate
local PEDIMENT: Finish = { c = "DAD4C8", m = "Limestone" }
local WALNUT_FLOOR: Finish = { c = "9A6B48", m = "WoodPlanks" }
local OAK_FLOOR: Finish = { c = "C49A6C", m = "WoodPlanks" }
local CEILING: Finish = { c = "F6F0E2", m = "Plaster" }
local PORTICO: Finish = { c = "DAD4C8", m = "Marble" }
local RAIL: Finish = { c = "9A6B48", m = "Wood" }
local GARDEN_WALL: Finish = { c = "BDB8AE", m = "Cobblestone" }
-- paint for the pieces
local TRIM = "FAF6EC"
local STONE = "BDB8AE"
local PALE_STONE = "DAD4C8"
local FOREST = "4E7F62" -- the accent: the doors, the lamps' shades
local BERRY = "B8505A"
local MUSTARD = "D9A93F"
local LILAC = "9C86B8"
local WALNUT = "9A6B48"
local DARK = "5A5560"

return function(add: any)
	add(
		"library",
		"Library",
		"A tall reading room with a gallery of books, the librarian's desk, and a garden to read in.",
		"news",
		36,
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
			-- quoins of pale stone up a corner (180 front left, 90 front right, 0 back right,
			-- 270 back left), on both storeys
			local function corner(x: number, z: number, r: number)
				putAt("corner_board", x, z, r, 0, 0, PALE_STONE, STONE)
				putAt("corner_board", x, z, r, Plan.levelBase(1), 1, PALE_STONE, STONE)
			end
			-- a tall window with a hood over it, on either storey
			local function window(wall: string, p: number)
				open("win_tall", wall, p, TRIM, TRIM)
				local sill = Plan.openingY(b.walls[wall], 2)
				hang("window_hood", wall, p, sill + 6 + 0.38, "a", TRIM, ROOF.c)
			end
			-- a low wall of another style (the garden's), free of the building's corners
			local function lowWall(name: string, x1: number, z1: number, x2: number, z2: number)
				local w = {
					x1 = x1,
					z1 = z1,
					x2 = x2,
					z2 = z2,
					lv = 0,
					style = "stone",
					a = { c = GARDEN_WALL.c, m = GARDEN_WALL.m },
					b = { c = GARDEN_WALL.c, m = GARDEN_WALL.m },
				}
				b.walls[name] = w
				table.insert(b.objects, { kind = "walls", obj = w, name = name })
			end

			-- the shell ----------------------------------------------------------------------
			-- the block x 2..22, z 8..26 on two storeys; the reading room rises through both at
			-- the front, the gallery's floor covers z 18..26 upstairs
			b:floor(2, 8, 22, 26, WALNUT_FLOOR)
			b:floor(2, 18, 22, 26, OAK_FLOOR, 1)
			b:floor(2, 8, 22, 26, CEILING, 2) -- the reading room's ceiling
			b:floor(4, 2, 20, 8, PORTICO)
			b:box("", 2, 8, 22, 26, SANDSTONE, INSIDE)
			b:box("up", 2, 8, 22, 26, SANDSTONE, INSIDE, 1)
			table.insert(b.objects, {
				kind = "walls",
				obj = {
					x1 = 6,
					z1 = 18,
					x2 = 22,
					z2 = 18,
					lv = 1,
					style = "railing",
					a = { c = RAIL.c, m = RAIL.m },
					b = { c = RAIL.c, m = RAIL.m },
				},
				name = "rail",
			})
			b:roof(2, 8, 22, 26, "hip", 7, 0, ROOF, SANDSTONE, 1, 1)
			-- the pediment: a gable to the street on the pillars, dying into the upper wall
			b:roof(4, 2, 20, 8, "gable", 4, 1, ROOF, PEDIMENT, 0, 0.3)
			for _, x in { 5.2, 9.2, 14.8, 18.8 } do
				putAt("pillar_round", x, 3.4, 0, F, 0, PALE_STONE, PALE_STONE)
			end

			-- doors and windows
			open("door_double", "front", 12, FOREST, TRIM)
			open("win_tall", "front", 7, TRIM, TRIM)
			open("win_tall", "front", 17, TRIM, TRIM)
			for _, x in { 4.6, 7.4, 16.6, 19.4 } do
				open("win_tall", "upfront", x, TRIM, TRIM)
			end
			open("win_porthole", "upfront", 12, TRIM, TRIM)
			open("door_glass", "right", 17, FOREST, FOREST)
			window("right", 12)
			window("right", 23)
			for _, z in { 11, 17, 23 } do
				window("upright", z)
			end
			for _, z in { 12, 20 } do
				window("left", z)
				window("upleft", z)
			end
			open("win_small", "back", 4.3, TRIM, TRIM)
			for _, x in { 4.3, 13.4, 20 } do
				window("upback", x)
			end
			hang("trellis", "back", 9, 1.3, "a")
			hang("trellis", "back", 16.6, 1.3, "a")

			-- outside: stone at the feet of the walls, quoins, drainpipes, the sign
			for _, wall in { "front", "right", "back", "left" } do
				footing(wall)
			end
			corner(2, 8, 180)
			corner(22, 8, 90)
			corner(22, 26, 0)
			corner(2, 26, 270)
			hang("downpipe", "back", 21.3, 0, "a", DARK, DARK)
			hang("downpipe", "back", 2.7, 0, "a", DARK, DARK)
			hang("sign_library", "right", 9, 8.4, "a", PALE_STONE, BERRY)
			hang("lantern_wall", "front", 3.2, 5.8, "a")
			hang("lantern_wall", "front", 20.8, 5.8, "a")

			-- the steps and the front
			put("doorstep", 12, 1.2, 180, PALE_STONE, STONE)
			putAt("bench_garden", 6.6, 6.7, 180, F)
			putAt("bench_garden", 17.5, 6.7, 180, F)
			put("planter_box", 6, 1, 0, PALE_STONE, LILAC)
			put("planter_box", 18, 1, 0, PALE_STONE, MUSTARD)
			put("lamp_post", 2.4, 1.6, 0)
			put("lamp_post", 21.6, 1.6, 0)
			put("flower_border", 0.8, 13.5, 90, PALE_STONE, LILAC)
			put("flower_border", 0.8, 18.5, 90, PALE_STONE, BERRY)
			put("flower_border", 0.8, 23.5, 90, PALE_STONE, MUSTARD)

			-- the reading garden: low stone walls off the side wall, a gate, a tree, benches
			lowWall("gf1", 22, 10, 26, 10)
			lowWall("gf2", 30, 10, 34, 10)
			lowWall("gr", 34, 10, 34, 22)
			lowWall("gb", 34, 22, 22, 22)
			put("gate_garden", 28, 10, 0, TRIM, TRIM)
			put("tree_blossom", 30.4, 17.6, 0)
			put("bench_garden", 32.3, 13.2, 270)
			put("bench_garden", 26, 20.3, 180)
			for _, p in { { 28, 12.2, 0 }, { 26.8, 14.3, 30 }, { 25, 16, 70 }, { 23.4, 17, 90 } } do
				put("path_stones", p[1], p[2], p[3])
			end
			put("flower_border", 24.4, 11.4, 0, STONE, LILAC)
			put("bird_house", 32.4, 20.4, 0)
			put("lamp_post", 23.1, 13.2, 0)
			put("bush", 33.4, 25.6, 0)
			put("bush", 27, 24.4, 0)

			-- the reading room ----------------------------------------------------------------
			-- the stair up the left wall, a long reading table with green lamps, armchairs
			-- by the window, the desk under the gallery's edge
			putAt("stairs_straight", 4.3, 16.3, 180, F, 0, WALNUT, WALNUT)
			put("work_library", 13, 18.9, 180, WALNUT, "F2E6CC")
			put("table_dining_long", 17.6, 11.4, 0, WALNUT)
			for _, x in { 15.2, 17.6, 20 } do
				put("chair_dining", x, 13.9, 180, WALNUT)
			end
			for _, x in { 15.6, 19.6 } do
				putAt("lamp_desk", x, 11, 180, top("table_dining_long"), 0, FOREST)
			end
			putAt("books_stack", 17.6, 11.8, 20, top("table_dining_long"))
			hang("clock_wall", "right", 9.6, 7, "b")
			put("armchair", 8.1, 12.8, 90, BERRY)
			put("table_side", 7.6, 15.6, 0, WALNUT)
			putAt("globe", 7.6, 15.6, 0, top("table_side"))
			put("lamp_floor", 7.4, 17.6, 0)
			put("rug_long", 12, 12.4, 0, BERRY, MUSTARD)
			hang("art_landscape", "front", 12, 9.4, "b")
			for _, x in { 9, 16 } do
				putAt("chandelier", x, 13, 0, Plan.levelTop(1) - 1, 1)
			end

			-- under the gallery: the tall cases along the back wall, the librarian's corner
			for _, x in { 9, 14, 19 } do
				put("bookcase_tall", x, 24.4, 180)
			end
			put("table_side", 20.8, 22.2, 0, WALNUT)
			putAt("kettle", 20.8, 22.2, 200, top("table_side"))
			for _, x in { 8, 13, 19 } do
				put("light_ceiling", x, 22, 0)
			end

			-- the gallery: stacks of shelves end on to the back wall, a chair by the window
			for _, x in { 9.4, 15.8 } do
				putAt("bookshelf", x, 23.9, 270, Plan.levelBase(1), 1, WALNUT)
				putAt("bookshelf", x + 1.6, 23.9, 90, Plan.levelBase(1), 1, WALNUT)
			end
			putAt("chair_wood", 13.4, 23, 0, Plan.levelBase(1), 1, WALNUT)
			putAt("armchair", 20, 20.8, 270, Plan.levelBase(1), 1, FOREST)
			putAt("lamp_floor", 20.6, 24.4, 0, Plan.levelBase(1), 1)
			for _, x in { 7, 13.4, 19 } do
				putAt("light_ceiling", x, 22, 0, Plan.levelTop(1) - 1, 1)
			end
		end
	)
end
