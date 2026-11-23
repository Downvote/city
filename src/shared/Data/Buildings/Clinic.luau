--!strict
-- The clinic: low, pale and flat roofed, in an L. The waiting hall with the doctor's desk sits
-- back behind a paved court with a canopy over its glass door; the ward wing comes forward on
-- the right, its three beds kept apart by folding screens.
local Shared = script.Parent.Parent.Parent
local Catalog = require(Shared.Build.Catalog)
local Plan = require(Shared.Build.Plan)
local Tuning = require(Shared.Config.Tuning)

type Finish = { c: string, m: string }

local F = Tuning.Plot.Foundation

-- finishes (Data/Palette's materials; colours from the town's palette)
local WALL: Finish = { c = "F6F0E2", m = "Plaster" }
local WAITING: Finish = { c = "CFE2D0", m = "SmoothPlastic" } -- mint inside the hall
local WARD: Finish = { c = "F6F0E2", m = "SmoothPlastic" }
local ROOF: Finish = { c = "4F8A8C", m = "Slate" }
local FLAT: Finish = { c = "DAD4C8", m = "Pebble" } -- the ward's gravel roof
local PARAPET: Finish = { c = "FAF6EC", m = "Plaster" }
local FLOOR: Finish = { c = "F2E6CC", m = "CeramicTiles" }
local WARD_FLOOR: Finish = { c = "CFE2D0", m = "CeramicTiles" }
local PAVING: Finish = { c = "DAD4C8", m = "Pavement" }
-- paint for the pieces
local TRIM = "FAF6EC"
local STONE = "BDB8AE"
local PALE_STONE = "DAD4C8"
local TEAL = "3F8C86" -- the accent: the door, the canopy, the sign
local LILAC = "9C86B8"
local OAK = "C49A6C"
local DARK = "5A5560"

return function(add: any)
	add(
		"clinic",
		"Clinic",
		"A waiting room and the doctor's desk, a ward of three beds behind screens, a canopy at the door.",
		"heart",
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
			-- a white board up an outside corner (180 front left, 90 front right, 0 back
			-- right, 270 back left)
			local function corner(x: number, z: number, r: number)
				putAt("corner_board", x, z, r, 0, 0, TRIM, PALE_STONE)
			end
			-- a square window with a hood over it and a box of flowers under it
			local function window(wall: string, p: number)
				open("win_square", wall, p, TRIM, TRIM)
				hang("window_hood", wall, p, 3.4 + 4 + 0.38, "a", TRIM, TEAL)
				hang("window_box", wall, p, 3.4 - 1.35, "a", TRIM, LILAC)
			end

			-- the shell ----------------------------------------------------------------------
			-- the hall x 2..22, z 10..24; the ward wing x 22..34, z 4..24; the court in the
			-- corner between them
			b:floor(2, 10, 22, 24, FLOOR)
			b:floor(22, 4, 34, 24, WARD_FLOOR)
			b:floor(2, 4, 22, 10, PAVING)
			b:floor(10, 0, 14, 4, PAVING)
			b:wall("front", 2, 10, 22, 10, WALL, WAITING)
			b:wall("court", 22, 10, 22, 4, WALL, WARD)
			b:wall("wfront", 22, 4, 34, 4, WALL, WARD)
			b:wall("wright", 34, 4, 34, 24, WALL, WARD)
			b:wall("back", 34, 24, 2, 24, WALL, WAITING)
			b:wall("left", 2, 24, 2, 10, WALL, WAITING)
			b:wall("divide", 22, 10, 22, 24, WARD, WAITING)
			b:roof(2, 10, 22, 24, "hip", 5, 0, ROOF, PARAPET, 0, 0.8)
			b:roof(22, 4, 34, 24, "flat", 0, 0, FLAT, PARAPET, 0, 0)

			-- doors and windows
			open("door_glass", "front", 12, TEAL, TEAL)
			open("win_tall", "front", 8.6, TRIM, TRIM)
			open("win_tall", "front", 15.4, TRIM, TRIM)
			window("front", 4.4)
			window("front", 19.6)
			window("left", 14)
			window("back", 8)
			window("back", 27)
			window("back", 31.4)
			open("win_small", "back", 20, TRIM, TRIM)
			open("win_square", "court", 7, TRIM, TRIM)
			open("win_wide", "wfront", 28, TRIM, TRIM)
			hang("awning", "wfront", 28, 7.5, "a", TEAL, TRIM)
			window("wright", 10.2)
			window("wright", 16.2)
			open("arch_wide", "divide", 18, TRIM, TRIM)

			-- outside: stone at the feet of the walls, boards up the corners, drainpipes, the
			-- canopy and the sign
			for _, wall in { "front", "court", "wfront", "wright", "back", "left" } do
				footing(wall)
			end
			corner(2, 10, 180)
			corner(22, 4, 180)
			corner(34, 4, 90)
			corner(34, 24, 0)
			corner(2, 24, 270)
			hang("downpipe", "front", 2.7, 0, "a", DARK, DARK)
			hang("downpipe", "wfront", 33.3, 0, "a", DARK, DARK)
			hang("downpipe", "back", 21, 0, "a", DARK, DARK)
			putAt("canopy_door", 12, 7.5, 180, F, 0, TRIM, TEAL)
			hang("sign_clinic", "court", 5, 8.4, "a", TRIM, TEAL)
			hang("lantern_wall", "court", 8.6, 5.6, "a")
			hang("trellis", "left", 20, 1.3, "a")
			hang("trellis", "wright", 22, 1.3, "a")

			-- the court and the front garden
			putAt("doormat", 12, 9, 0, F)
			putAt("bench_garden", 5, 6.8, 180, F)
			putAt("planter_box", 4.4, 4.8, 0, F, 0, PALE_STONE)
			putAt("planter_box", 19.4, 4.8, 0, F, 0, PALE_STONE)
			putAt("flower_pot", 7.6, 8.8, 0, F)
			putAt("flower_pot", 16.4, 8.8, 0, F)
			put("lamp_post", 8.6, 1.6, 0)
			put("lamp_post", 15.4, 1.6, 0)
			put("flower_border", 24.4, 2.9, 0, PALE_STONE, LILAC)
			put("flower_border", 28.4, 2.9, 0, PALE_STONE, "E08566")
			put("flower_border", 32.4, 2.9, 0, PALE_STONE, LILAC)
			put("bush", 4, 2, 0)
			put("bush", 19.8, 2, 0)
			put("bush", 33.8, 26.2, 0)
			put("bicycle", 3.4, 26, 95)
			put("water_butt", 14, 25.6, 0)
			put("bench_garden", 9.4, 25.9, 0)
			hang("trellis", "back", 23.2, 1.3, "a")

			-- the waiting hall --------------------------------------------------------------
			-- the doctor's desk across the middle, its exam bed to the left, the patients'
			-- chairs in front, the cupboards behind
			put("work_clinic", 12, 17, 180, TRIM, TEAL)
			put("sofa_two", 5, 11.9, 0, "9CCFC4")
			put("table_coffee", 5, 15.2, 0, OAK)
			putAt("books_stack", 4.2, 15.1, 15, top("table_coffee"))
			putAt("plant_small", 5.8, 15.3, 0, top("table_coffee"))
			put("aquarium", 3.2, 19.4, 90)
			put("chair_wood", 18.4, 11.5, 0, OAK)
			put("chair_wood", 20.5, 11.5, 0, OAK)
			put("plant_big", 15.8, 11.9, 0)
			-- behind the desk, clear of the doctor's way round it: the medicines, a basin with
			-- the kettle by it, a cupboard, the coat stand
			put("medicine_cabinet", 15.5, 22.9, 180)
			put("cabinet", 19.5, 22.8, 180, TRIM)
			putAt("plant_small", 20.6, 22.8, 0, top("cabinet"))
			put("counter_sink", 5.6, 22.4, 180, TRIM)
			putAt("kettle", 6.5, 22.6, 160, top("counter_sink"))
			put("coat_stand", 3.2, 22.8, 0)
			put("rug_round", 12, 12.6, 0, "9CCFC4", TEAL)
			hang("clock_wall", "front", 12, 9.2, "b")
			hang("art_landscape", "left", 14, 8.6, "b")
			hang("art_flowers", "back", 12.4, 6.4, "b")
			hang("shelf_wall", "back", 15.5, 8.6, "b")
			hang("mirror_wall", "divide", 12, 4.6, "b")
			for _, p in { { 6, 13.4 }, { 18, 14 }, { 12, 21.2 } } do
				put("light_ceiling", p[1], p[2], 0)
			end

			-- the ward ----------------------------------------------------------------------
			-- three beds with their heads to the end wall, a screen and a nightstand between
			-- each, the linen and a basin at the back
			for _, z in { 7.2, 13.2, 19.2 } do
				put("bed_ward", 29.9, z, 270)
				put("light_ceiling", 29, z, 0)
			end
			for _, z in { 10.2, 16.2 } do
				put("screen_folding", 29.6, z, 0, TRIM, "A9D4CC")
				put("nightstand", 32.8, z, 270, TRIM)
			end
			put("nightstand", 32.8, 22.2, 270, TRIM)
			putAt("lamp_table", 32.8, 10.2, 0, top("nightstand"))
			putAt("vase_flowers", 32.8, 16.2, 0, top("nightstand"))
			putAt("books_stack", 32.8, 22.2, 0, top("nightstand"))
			put("cabinet", 28, 22.8, 180, TRIM)
			putAt("plant_small", 28, 22.8, 0, top("cabinet"))
			put("sink_vanity", 24.2, 22.7, 180)
			put("armchair", 24.1, 6.8, 90, "9CCFC4")
			put("table_side", 24.1, 9.6, 0, OAK)
			putAt("vase_flowers", 24.1, 9.6, 0, top("table_side"))
			hang("curtains", "wright", 10.2, 2.2, "b")
			hang("curtains", "wright", 16.2, 2.2, "b")
			hang("art_flowers", "wfront", 23.6, 5.4, "b")
			hang("clock_wall", "divide", 11.6, 7.4, "a")
		end
	)
end
