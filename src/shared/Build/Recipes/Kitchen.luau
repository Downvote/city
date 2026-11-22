--!strict
-- Counters, appliances and small kitchen things. Counters are 3.4 tall with their top at
-- `surface`, so a run of them lines up and small things can stand on top.
-- c1 is the cabinet or appliance body, c2 the worktop or a trim colour.

local Recipe = require(script.Parent.Parent.Recipe)
local Colors = require(script.Parent.Parent.Parent.Util.Colors)

local C = Recipe.Colors

type R = Recipe.Recipe

local TOP = 3.4

local function shade(c: Color3, k: number): Color3
	return Colors.shade(c, k)
end

-- A cabinet body w wide and d deep with a recessed kick plinth, up to the worktop.
local function cabinet(r: R, w: number, d: number)
	r:block(-w / 2, 0, -d / 2, w / 2, 0.3, d / 2 - 0.2, shade(r.c1, 0.6), "Wood")
	r:block(-w / 2, 0.3, -d / 2, w / 2, TOP - 0.3, d / 2 - 0.1, r.c1, "Wood")
end

-- A cabinet door (or drawer) on the front face at z, with a bar handle.
local function front(r: R, x1: number, y1: number, x2: number, y2: number, z: number, handle: string)
	r:block(x1, y1, z, x2, y2, z + 0.06, shade(r.c1, 1.06), "Wood")
	if handle == "top" then
		local xm = (x1 + x2) / 2
		r:block(xm - 0.3, y2 - 0.22, z + 0.06, xm + 0.3, y2 - 0.12, z + 0.14, C.Metal, "Metal")
	elseif handle == "left" then
		r:block(x1 + 0.15, y2 - 0.75, z + 0.06, x1 + 0.25, y2 - 0.15, z + 0.14, C.Metal, "Metal")
	else
		r:block(x2 - 0.25, y2 - 0.75, z + 0.06, x2 - 0.15, y2 - 0.15, z + 0.14, C.Metal, "Metal")
	end
end

-- One catalog entry (Build/Catalog explains the fields).
type Item = {
	id: string,
	name: string,
	cat: string,
	price: number,
	place: string,
	size: Vector3,
	c1: string,
	c2: string?,
	tags: { string }?,
	surface: number?,
	build: (r: R) -> (),
}

local items: { Item } = {
	{
		id = "counter",
		name = "Counter",
		cat = "kitchen",
		price = 90,
		place = "floor",
		size = Vector3.new(3, 3.4, 2.6),
		surface = TOP,
		c1 = "F7F3EA",
		c2 = "D6D3CC",
		tags = { "kitchen" },
		build = function(r: R)
			cabinet(r, 3, 2.6)
			r:block(-1.5, TOP - 0.3, -1.3, 1.5, TOP, 1.3, r.c2, "Marble")
			front(r, -1.4, 2.45, 1.4, 2.98, 1.2, "top")
			front(r, -1.4, 0.4, 1.4, 2.35, 1.2, "right")
		end,
	},
	{
		id = "counter_corner",
		name = "Corner counter",
		cat = "kitchen",
		price = 90,
		place = "floor",
		size = Vector3.new(2.6, 3.4, 2.6),
		surface = TOP,
		c1 = "F7F3EA",
		c2 = "D6D3CC",
		tags = { "kitchen" },
		build = function(r: R)
			-- fits in the corner of a run: neighbours join on its right and front,
			-- and a slanted door faces the room across the inside corner
			local kick = shade(r.c1, 0.6)
			r:block(-1.3, 0, -1.3, 1.3, 0.3, -0.15, kick, "Wood")
			r:block(-1.3, 0, -0.15, -0.15, 0.3, 1.3, kick, "Wood")
			r:tri(
				Vector3.new(-0.15, 0.15, -0.15),
				Vector3.new(1.24, 0.15, -0.15),
				Vector3.new(-0.15, 0.15, 1.24),
				0.3,
				kick,
				"Wood"
			)
			r:block(-1.3, 0.3, -1.3, 1.3, TOP - 0.3, 0, r.c1, "Wood")
			r:block(-1.3, 0.3, 0, 0, TOP - 0.3, 1.3, r.c1, "Wood")
			local mid = (0.3 + TOP - 0.3) / 2
			r:tri(Vector3.new(0, mid, 0), Vector3.new(1.3, mid, 0), Vector3.new(0, mid, 1.3), TOP - 0.6, r.c1, "Wood")
			local diag = CFrame.new(0.67, mid, 0.67) * CFrame.Angles(0, math.pi / 4, 0)
			r:boxAt(diag * CFrame.new(0, 0.05, 0), 1.5, 2.55, 0.06, shade(r.c1, 1.06), "Wood")
			r:boxAt(diag * CFrame.new(0.5, 0.6, 0.07), 0.1, 0.6, 0.08, C.Metal, "Metal")
			r:block(-1.3, TOP - 0.3, -1.3, 1.3, TOP, 1.3, r.c2, "Marble")
		end,
	},
	{
		id = "counter_sink",
		name = "Sink counter",
		cat = "kitchen",
		price = 180,
		place = "floor",
		size = Vector3.new(3, 4.2, 2.6),
		surface = TOP,
		c1 = "F7F3EA",
		c2 = "D6D3CC",
		tags = { "kitchen" },
		build = function(r: R)
			cabinet(r, 3, 2.6)
			-- the worktop goes round the basin
			local y1, y2 = TOP - 0.3, TOP
			r:block(-1.5, y1, 0.75, 1.5, y2, 1.3, r.c2, "Marble")
			r:block(-1.5, y1, -1.3, 1.5, y2, -0.85, r.c2, "Marble")
			r:block(-1.5, y1, -0.85, -0.95, y2, 0.75, r.c2, "Marble")
			r:block(0.95, y1, -0.85, 1.5, y2, 0.75, r.c2, "Marble")
			r:block(-0.95, y1, -0.85, 0.95, y1 + 0.03, 0.75, C.Metal, "Metal")
			r:cyl(0, y1 + 0.04, -0.05, 0.02, 0.2, "y", C.DarkMetal, "Metal")
			for _, s in { -1, 1 } do
				r:block(-0.95, y1, s > 0 and 0.7 or -0.85, 0.95, y2 + 0.02, s > 0 and 0.75 or -0.8, C.Metal, "Metal")
				r:block(s * 0.95 - 0.05, y1, -0.85, s * 0.95 + 0.05, y2 + 0.02, 0.75, C.Metal, "Metal")
			end
			-- the tap
			r:cyl(0, TOP + 0.35, -1.05, 0.7, 0.18, "y", C.Metal, "Metal")
			r:beam(Vector3.new(0, TOP + 0.65, -1.05), Vector3.new(0, TOP + 0.65, -0.5), 0.14, 0.14, C.Metal, "Metal")
			r:cyl(0, TOP + 0.55, -0.5, 0.2, 0.14, "y", C.Metal, "Metal")
			for _, x in { -0.35, 0.35 } do
				r:cyl(x, TOP + 0.1, -1.05, 0.2, 0.2, "y", C.Metal, "Metal")
			end
			front(r, -1.4, 0.4, -0.03, 2.98, 1.2, "right")
			front(r, 0.03, 0.4, 1.4, 2.98, 1.2, "left")
		end,
	},
	{
		id = "stove",
		name = "Stove",
		cat = "kitchen",
		price = 260,
		place = "floor",
		size = Vector3.new(3, 4, 2.6),
		surface = TOP,
		c1 = "F7F3EA",
		c2 = "45454A",
		tags = { "kitchen" },
		build = function(r: R)
			r:block(-1.5, 0, -1.3, 1.5, TOP - 0.1, 1.2, r.c1, "Metal")
			r:block(-1.5, TOP - 0.1, -1.3, 1.5, TOP, 1.25, r.c2, "Metal")
			for _, x in { -0.68, 0.68 } do
				for _, z in { -0.55, 0.5 } do
					r:cyl(x, TOP + 0.02, z, 0.05, 0.8, "y", C.Black, "Metal")
					r:cyl(x, TOP + 0.04, z, 0.05, 0.4, "y", C.DarkMetal, "Metal")
				end
			end
			-- oven door with a window, a handle and a drawer under it
			r:block(-1.35, 0.55, 1.2, 1.35, 2.5, 1.26, r.c2, "Metal")
			r:block(-0.9, 1.0, 1.26, 0.9, 2.0, 1.28, C.Black, "Glass")
			r:cyl(0, 2.3, 1.38, 2.2, 0.12, "x", C.Metal, "Metal")
			for _, x in { -0.95, 0.95 } do
				r:block(x - 0.05, 2.25, 1.26, x + 0.05, 2.35, 1.38, C.Metal, "Metal")
			end
			r:block(-1.35, 0.12, 1.2, 1.35, 0.45, 1.25, shade(r.c1, 0.9), "Metal")
			for _, x in { -1.05, -0.4, 0.4, 1.05 } do
				r:cyl(x, 2.9, 1.25, 0.1, 0.24, "z", C.Black, "SmoothPlastic")
			end
			-- a back panel with a clock, and a pot on the stove
			r:block(-1.5, TOP, -1.3, 1.5, TOP + 0.55, -1.08, r.c1, "Metal")
			r:block(-0.3, TOP + 0.15, -1.08, 0.3, TOP + 0.4, -1.05, C.Black, "SmoothPlastic")
			r:cyl(-0.68, TOP + 0.31, -0.55, 0.5, 0.72, "y", C.Red, "Metal")
			r:block(-0.15, TOP + 0.45, -0.6, 0.1, TOP + 0.52, -0.5, C.DarkMetal, "Metal")
		end,
	},
	{
		id = "fridge",
		name = "Fridge",
		cat = "kitchen",
		price = 320,
		place = "floor",
		size = Vector3.new(3, 7, 2.6),
		c1 = "A8D5C2",
		c2 = "C9CCD3",
		tags = { "kitchen" },
		build = function(r: R)
			r:block(-1.4, 0, -1.2, 1.4, 0.2, 1.0, C.DarkMetal, "Metal")
			r:block(-1.5, 0.2, -1.3, 1.5, 6.6, 1.1, r.c1, "Metal")
			-- a rounded top, like an old fridge
			r:block(-1.5, 6.6, -1.3, 1.5, 6.95, 0.75, r.c1, "Metal")
			r:cyl(0, 6.6, 0.75, 3.0, 0.7, "x", r.c1, "Metal")
			r:block(-1.42, 4.95, 1.1, 1.42, 6.55, 1.16, shade(r.c1, 1.05), "Metal")
			r:block(-1.42, 0.35, 1.1, 1.42, 4.85, 1.16, shade(r.c1, 1.05), "Metal")
			r:block(0.95, 5.15, 1.16, 1.1, 5.95, 1.3, r.c2, "Metal")
			r:block(0.95, 3.4, 1.16, 1.1, 4.6, 1.3, r.c2, "Metal")
			-- a note held up by a magnet
			r:block(-0.9, 3.2, 1.16, -0.3, 3.9, 1.18, C.Paper, "SmoothPlastic")
			r:cyl(-0.6, 3.8, 1.2, 0.05, 0.16, "z", C.Red, "SmoothPlastic")
		end,
	},
	{
		id = "kitchen_island",
		name = "Kitchen island",
		cat = "kitchen",
		price = 260,
		place = "floor",
		size = Vector3.new(6, 3.4, 3.6),
		surface = TOP,
		c1 = "5C7FA3",
		c2 = "F2EFE8",
		tags = { "kitchen" },
		build = function(r: R)
			r:block(-2.8, 0, -1.5, 2.8, 0.3, 0.5, shade(r.c1, 0.6), "Wood")
			r:block(-2.8, 0.3, -1.6, 2.8, TOP - 0.3, 0.6, r.c1, "Wood")
			r:block(-3, TOP - 0.3, -1.8, 3, TOP, 1.8, r.c2, "Marble")
			-- doors on the cooking side, brackets under the overhang on the seating side
			for _, x in { -1.83, 0, 1.83 } do
				r:block(x - 0.85, 0.4, -1.66, x + 0.85, 2.98, -1.6, shade(r.c1, 1.06), "Wood")
				r:block(x - 0.3, 2.65, -1.74, x + 0.3, 2.75, -1.66, C.Metal, "Metal")
			end
			for _, x in { -2.6, 0, 2.6 } do
				r:block(x - 0.12, 2.2, 0.6, x + 0.12, TOP - 0.3, 1.5, shade(r.c1, 0.85), "Wood")
			end
			r:block(-2.8, 0.3, 0.6, 2.8, 0.5, 0.75, shade(r.c1, 0.85), "Wood")
		end,
	},
	{
		id = "stool_bar",
		name = "Bar stool",
		cat = "kitchen",
		price = 60,
		place = "floor",
		size = Vector3.new(1.6, 3.6, 1.6),
		c1 = "D9805F",
		c2 = "45454A",
		tags = { "kitchen", "seat" },
		build = function(r: R)
			for _, sx in { -1, 1 } do
				for _, sz in { -1, 1 } do
					r:beam(
						Vector3.new(sx * 0.42, 2.5, sz * 0.42),
						Vector3.new(sx * 0.65, 0, sz * 0.65),
						0.16,
						0.16,
						r.c2,
						"Metal"
					)
				end
			end
			for _, s in { -1, 1 } do
				r:block(-0.6, 0.9, s * 0.6 - 0.05, 0.6, 1.0, s * 0.6 + 0.05, r.c2, "Metal")
				r:block(s * 0.6 - 0.05, 0.9, -0.6, s * 0.6 + 0.05, 1.0, 0.6, r.c2, "Metal")
			end
			r:cyl(0, 2.5, 0, 0.1, 1.4, "y", r.c2, "Metal")
			r:cyl(0, 2.65, 0, 0.2, 1.5, "y", r.c1, "Fabric")
			for _, x in { -0.45, 0.45 } do
				r:block(x - 0.05, 2.7, -0.7, x + 0.05, 3.1, -0.6, r.c2, "Metal")
			end
			r:block(-0.65, 3.1, -0.75, 0.65, 3.55, -0.58, r.c1, "Fabric")
			r:seat(0, 2.75, 0)
		end,
	},
	{
		id = "pantry",
		name = "Pantry",
		cat = "kitchen",
		price = 200,
		place = "floor",
		size = Vector3.new(3, 7, 2.2),
		c1 = "F7F3EA",
		c2 = "C99A62",
		tags = { "kitchen", "storage" },
		build = function(r: R)
			r:block(-1.5, 0, -1.1, 1.5, 0.3, 0.9, shade(r.c1, 0.6), "Wood")
			r:block(-1.5, 0.3, -1.1, 1.5, 6.7, 1.0, r.c1, "Wood")
			r:block(-1.55, 6.7, -1.1, 1.55, 7, 1.1, r.c2, "Wood")
			-- two slatted doors
			for _, sx in { -1, 1 } do
				local xa, xb = sx * 0.03, sx * 1.42
				local x1, x2 = math.min(xa, xb), math.max(xa, xb)
				r:block(x1, 0.4, 1.0, x2, 6.6, 1.05, shade(r.c1, 1.04), "Wood")
				for i = 0, 6 do
					local y = 3.7 + i * 0.38
					r:block(x1 + 0.15, y, 1.05, x2 - 0.15, y + 0.16, 1.1, shade(r.c1, 0.9), "Wood")
				end
				r:ball(sx * 0.25, 3.3, 1.12, 0.18, r.c2, "Wood")
			end
		end,
	},
	{
		id = "microwave",
		name = "Microwave",
		cat = "kitchen",
		price = 120,
		place = "surface",
		size = Vector3.new(1.8, 1.1, 1.3),
		c1 = "F7F3EA",
		c2 = "45454A",
		tags = { "kitchen" },
		build = function(r: R)
			for _, x in { -0.75, 0.75 } do
				r:block(x - 0.08, 0, -0.5, x + 0.08, 0.05, 0.5, C.Black, "SmoothPlastic")
			end
			r:block(-0.9, 0.05, -0.65, 0.9, 1.1, 0.6, r.c1, "Metal")
			r:block(-0.82, 0.13, 0.6, 0.38, 1.02, 0.64, r.c2, "Metal")
			r:block(-0.7, 0.25, 0.64, 0.15, 0.9, 0.65, Color3.fromRGB(60, 70, 66), "Glass")
			r:block(0.24, 0.25, 0.64, 0.32, 0.9, 0.7, C.Metal, "Metal")
			r:block(0.45, 0.13, 0.6, 0.82, 1.02, 0.63, shade(r.c1, 0.85), "Metal")
			r:block(0.52, 0.8, 0.63, 0.75, 0.93, 0.65, Color3.fromRGB(120, 200, 140), "Neon")
			for _, y in { 0.3, 0.45, 0.6 } do
				r:block(0.52, y, 0.63, 0.75, y + 0.08, 0.66, C.DarkMetal, "SmoothPlastic")
			end
		end,
	},
	{
		id = "kettle",
		name = "Kettle",
		cat = "kitchen",
		price = 40,
		place = "surface",
		size = Vector3.new(1.2, 1.3, 0.9),
		c1 = "D9805F",
		c2 = "45454A",
		tags = { "kitchen" },
		build = function(r: R)
			r:cyl(0, 0.05, 0, 0.1, 0.75, "y", r.c1, "Metal")
			r:cyl(0, 0.45, 0, 0.7, 0.85, "y", r.c1, "Metal")
			r:cyl(0, 0.85, 0, 0.1, 0.6, "y", r.c1, "Metal")
			r:ball(0, 0.95, 0, 0.18, r.c2, "SmoothPlastic")
			r:beam(Vector3.new(0.3, 0.35, 0), Vector3.new(0.58, 0.72, 0), 0.13, 0.13, r.c1, "Metal")
			-- the handle over the top
			r:beam(Vector3.new(-0.28, 0.8, 0), Vector3.new(-0.2, 1.22, 0), 0.1, 0.1, r.c2, "SmoothPlastic")
			r:beam(Vector3.new(0.28, 0.8, 0), Vector3.new(0.2, 1.22, 0), 0.1, 0.1, r.c2, "SmoothPlastic")
			r:block(-0.25, 1.17, -0.06, 0.25, 1.28, 0.06, r.c2, "SmoothPlastic")
		end,
	},
	{
		id = "toaster",
		name = "Toaster",
		cat = "kitchen",
		price = 35,
		place = "surface",
		size = Vector3.new(1.2, 1.0, 0.8),
		c1 = "8FB39A",
		c2 = "D9A86C",
		tags = { "kitchen" },
		build = function(r: R)
			r:block(-0.55, 0, -0.35, 0.55, 0.5, 0.35, r.c1, "Metal")
			r:block(-0.55, 0.5, -0.2, 0.55, 0.7, 0.2, r.c1, "Metal")
			for _, z in { -0.2, 0.2 } do
				r:cyl(0, 0.5, z, 1.1, 0.4, "x", r.c1, "Metal")
			end
			-- two slices of toast popping up
			for _, z in { -0.13, 0.13 } do
				r:block(-0.35, 0.45, z - 0.04, 0.35, 0.95, z + 0.04, r.c2, "SmoothPlastic")
			end
			r:block(0.55, 0.3, -0.05, 0.62, 0.42, 0.05, C.Black, "SmoothPlastic")
		end,
	},
}

return items
