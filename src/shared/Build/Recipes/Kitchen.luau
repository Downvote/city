--!strict
-- Counters, appliances and small kitchen things. Counters are 3.4 tall with their top at
-- `surface`, so a run of them lines up and small things can stand on top.
-- c1 is the cabinet or appliance body, c2 the worktop or a trim colour.

local Recipe = require(script.Parent.Parent.Recipe)
local Colors = require(script.Parent.Parent.Parent.Util.Colors)

local C = Recipe.Colors

type R = Recipe.Recipe

local TOP = 3.4
local STEEL = Color3.fromRGB(196, 199, 205)

local function shade(c: Color3, k: number): Color3
	return Colors.shade(c, k)
end

-- A round rod from a to b (a cylinder laid along the line).
local function rod(r: R, a: Vector3, b: Vector3, d: number, color: Color3, mat: string?)
	local v = b - a
	local len = v.Magnitude
	if len < 1e-3 then
		return
	end
	local x = v / len
	local up = if math.abs(x.Y) > 0.99 then Vector3.zAxis else Vector3.yAxis
	local z = x:Cross(up).Unit
	local y = z:Cross(x).Unit
	r:add({
		shape = "Cylinder",
		cf = CFrame.fromMatrix((a + b) / 2, x, y, z),
		size = Vector3.new(len, d, d),
		color = color,
		mat = mat or "SmoothPlastic",
	})
end

-- A cabinet body w wide and d deep (front at d / 2) with a recessed kick plinth, up to the worktop.
local function cabinet(r: R, w: number, d: number)
	r:block(-w / 2, 0, -d / 2, w / 2, 0.35, d / 2 - 0.3, shade(r.c1, 0.55), "Wood")
	r:block(-w / 2, 0.35, -d / 2, w / 2, TOP - 0.22, d / 2 - 0.1, r.c1, "Wood")
end

-- A worktop w wide and d deep with a slim front lip.
local function worktop(r: R, w: number, d: number)
	r:block(-w / 2, TOP - 0.22, -d / 2, w / 2, TOP, d / 2, r.c2, "Marble")
	r:block(-w / 2, TOP - 0.26, d / 2 - 0.06, w / 2, TOP - 0.22, d / 2, shade(r.c2, 0.85), "Marble")
end

-- A bar pull: a metal bar on two short posts, along x ("x") or standing up ("y"), standing out
-- from the face at z toward `dir` (1 for a face toward +z, the front; -1 for the back).
local function pull(r: R, x: number, y: number, z: number, len: number, axis: string, dir: number?)
	local s = dir or 1
	r:cyl(x, y, z + s * 0.12, len, 0.07, axis, STEEL, "Metal")
	local za, zb = math.min(z, z + s * 0.12), math.max(z, z + s * 0.12)
	for _, k in { -1, 1 } do
		local o = k * (len / 2 - 0.08)
		if axis == "x" then
			r:block(x + o - 0.03, y - 0.03, za, x + o + 0.03, y + 0.03, zb, STEEL, "Metal")
		else
			r:block(x - 0.03, y + o - 0.03, za, x + 0.03, y + o + 0.03, zb, STEEL, "Metal")
		end
	end
end

-- A shaker front (door or drawer) on the face at z: a flat front with a slightly darker raised
-- panel and a pull at `handle` ("top" for a drawer, "left" or "right" for a door). `dir` is the
-- way the face looks (1, the default, for +z).
local function front(r: R, x1: number, y1: number, x2: number, y2: number, z: number, handle: string, dir: number?)
	local s = dir or 1
	local col = shade(r.c1, 1.05)
	r:block(x1, y1, math.min(z, z + s * 0.06), x2, y2, math.max(z, z + s * 0.06), col, "Wood")
	local inset = math.min(0.16, (y2 - y1) * 0.2)
	local p1, p2 = z + s * 0.06, z + s * 0.09
	r:block(
		x1 + inset,
		y1 + inset,
		math.min(p1, p2),
		x2 - inset,
		y2 - inset,
		math.max(p1, p2),
		shade(r.c1, 0.92),
		"Wood"
	)
	local face = z + s * 0.06
	if handle == "top" then
		pull(r, (x1 + x2) / 2, (y1 + y2) / 2, face, math.min(0.9, (x2 - x1) * 0.5), "x", s)
	elseif handle == "left" then
		pull(r, x1 + 0.22, y2 - 0.55, face, 0.7, "y", s)
	else
		pull(r, x2 - 0.22, y2 - 0.55, face, 0.7, "y", s)
	end
end

-- A tea towel hung over a bar at (x, y, z) on a face looking toward +z: a fold behind the bar and
-- a longer drop in front, with two stripes.
local function teaTowel(r: R, x: number, y: number, z: number, w: number, drop: number, color: Color3)
	r:cyl(x, y, z, w, 0.12, "x", color, "Fabric")
	r:block(x - w / 2, y - drop, z + 0.03, x + w / 2, y, z + 0.07, color, "Fabric")
	for _, k in { 0.22, 0.32 } do
		r:block(
			x - w / 2 - 0.03,
			y - drop * (1 - k) - 0.025,
			z,
			x + w / 2 + 0.03,
			y - drop * (1 - k) + 0.025,
			z + 0.1,
			C.Red,
			"Fabric"
		)
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
	style: string?, -- the look it belongs to (Catalog.Styles)
	build: (r: R) -> (),
	gives: string?, -- holding E gives the player something (Data/Items.Sources)
}

local items: { Item } = {
	{
		id = "counter",
		name = "Counter",
		cat = "kitchen",
		style = "modern",
		price = 90,
		place = "floor",
		size = Vector3.new(3, 3.4, 2.6),
		surface = TOP,
		c1 = "F7F3EA",
		c2 = "D6D3CC",
		tags = { "kitchen" },
		build = function(r: R)
			cabinet(r, 3, 2.6)
			worktop(r, 3, 2.6)
			front(r, -1.44, 2.5, 1.44, 3.1, 1.2, "top")
			front(r, -1.44, 0.42, -0.03, 2.42, 1.2, "right")
			front(r, 0.03, 0.42, 1.44, 2.42, 1.2, "left")
		end,
	},
	{
		id = "counter_corner",
		name = "Corner counter",
		cat = "kitchen",
		style = "modern",
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
			local kick = shade(r.c1, 0.55)
			r:block(-1.3, 0, -1.3, 1.3, 0.35, -0.2, kick, "Wood")
			r:block(-1.3, 0, -0.2, -0.2, 0.35, 1.3, kick, "Wood")
			r:tri(
				Vector3.new(-0.2, 0.175, -0.2),
				Vector3.new(1.0, 0.175, -0.2),
				Vector3.new(-0.2, 0.175, 1.0),
				0.35,
				kick,
				"Wood"
			)
			r:block(-1.3, 0.35, -1.3, 1.3, TOP - 0.22, 0, r.c1, "Wood")
			r:block(-1.3, 0.35, 0, 0, TOP - 0.22, 1.3, r.c1, "Wood")
			local mid = (0.35 + TOP - 0.22) / 2
			r:tri(Vector3.new(0, mid, 0), Vector3.new(1.3, mid, 0), Vector3.new(0, mid, 1.3), TOP - 0.57, r.c1, "Wood")
			local diag = CFrame.new(0.67, mid, 0.67) * CFrame.Angles(0, math.pi / 4, 0)
			r:boxAt(diag * CFrame.new(0, 0.04, 0.03), 1.6, 2.7, 0.06, shade(r.c1, 1.05), "Wood")
			r:boxAt(diag * CFrame.new(0, 0.04, 0.075), 1.28, 2.38, 0.03, shade(r.c1, 0.92), "Wood")
			r:boxAt(diag * CFrame.new(0.56, 0.8, 0.14), 0.07, 0.7, 0.07, STEEL, "Metal")
			r:block(-1.3, TOP - 0.22, -1.3, 1.3, TOP, 1.3, r.c2, "Marble")
		end,
	},
	{
		id = "counter_sink",
		name = "Sink counter",
		cat = "kitchen",
		style = "modern",
		price = 180,
		place = "floor",
		size = Vector3.new(3, 4.4, 2.6),
		surface = TOP,
		c1 = "F7F3EA",
		c2 = "D6D3CC",
		tags = { "kitchen" },
		build = function(r: R)
			-- the cabinet is solid below the basin and built round it above, so the basin is a
			-- real well in the worktop: steel sides, a floor and a plug hole
			local y1, y2 = TOP - 0.22, TOP
			local yb = y1 - 0.5
			r:block(-1.5, 0, -1.3, 1.5, 0.35, 1.0, shade(r.c1, 0.55), "Wood")
			r:block(-1.5, 0.35, -1.3, 1.5, yb, 1.2, r.c1, "Wood")
			r:block(-1.5, yb, 0.72, 1.5, y1, 1.2, r.c1, "Wood")
			r:block(-1.5, yb, -1.3, 1.5, y1, -0.78, r.c1, "Wood")
			r:block(-1.5, yb, -0.78, -0.98, y1, 0.72, r.c1, "Wood")
			r:block(0.98, yb, -0.78, 1.5, y1, 0.72, r.c1, "Wood")
			r:block(-1.5, y1, 0.72, 1.5, y2, 1.3, r.c2, "Marble")
			r:block(-1.5, y1, -1.3, 1.5, y2, -0.78, r.c2, "Marble")
			r:block(-1.5, y1, -0.78, -0.98, y2, 0.72, r.c2, "Marble")
			r:block(0.98, y1, -0.78, 1.5, y2, 0.72, r.c2, "Marble")
			r:block(-1.5, TOP - 0.26, 1.24, 1.5, TOP - 0.22, 1.3, shade(r.c2, 0.85), "Marble")
			r:block(-0.98, yb, -0.78, 0.98, yb + 0.06, 0.72, STEEL, "Metal")
			r:block(-0.98, yb + 0.06, -0.78, 0.98, y2 - 0.04, -0.74, shade(STEEL, 0.8), "Metal")
			r:block(-0.98, yb + 0.06, 0.68, 0.98, y2 - 0.04, 0.72, shade(STEEL, 0.86), "Metal")
			r:block(-0.98, yb + 0.06, -0.74, -0.94, y2 - 0.04, 0.68, shade(STEEL, 0.9), "Metal")
			r:block(0.94, yb + 0.06, -0.74, 0.98, y2 - 0.04, 0.68, shade(STEEL, 0.9), "Metal")
			r:cyl(0, yb + 0.08, 0, 0.04, 0.24, "y", C.DarkMetal, "Metal")
			-- a gooseneck tap with a lever, a soap bottle and a sponge
			r:cyl(0, TOP + 0.05, -1.02, 0.1, 0.34, "y", STEEL, "Metal")
			rod(r, Vector3.new(0, TOP, -1.02), Vector3.new(0, TOP + 0.85, -1.02), 0.14, STEEL, "Metal")
			rod(r, Vector3.new(0, TOP + 0.82, -1.02), Vector3.new(0, TOP + 0.98, -0.82), 0.13, STEEL, "Metal")
			rod(r, Vector3.new(0, TOP + 0.97, -0.84), Vector3.new(0, TOP + 0.9, -0.55), 0.13, STEEL, "Metal")
			rod(r, Vector3.new(0, TOP + 0.92, -0.56), Vector3.new(0, TOP + 0.66, -0.5), 0.13, STEEL, "Metal")
			rod(r, Vector3.new(0.08, TOP + 0.5, -1.02), Vector3.new(0.35, TOP + 0.62, -1.02), 0.06, STEEL, "Metal")
			r:cyl(0.65, TOP + 0.22, -1.0, 0.44, 0.24, "y", Color3.fromRGB(143, 179, 154), "SmoothPlastic")
			r:cyl(0.65, TOP + 0.5, -1.0, 0.12, 0.06, "y", C.White, "SmoothPlastic")
			r:block(-0.85, TOP, -1.12, -0.45, TOP + 0.08, -0.9, C.Yellow, "Fabric")
			r:block(-0.85, TOP + 0.08, -1.12, -0.45, TOP + 0.12, -0.9, Color3.fromRGB(126, 154, 122), "Fabric")
			-- a false drawer front over two doors, a tea towel over one door's handle
			r:block(-1.44, 2.58, 1.2, 1.44, 3.08, 1.26, shade(r.c1, 1.05), "Wood")
			r:block(-1.3, 2.68, 1.26, 1.3, 2.98, 1.29, shade(r.c1, 0.92), "Wood")
			front(r, -1.44, 0.42, -0.03, 2.5, 1.2, "right")
			front(r, 0.03, 0.42, 1.44, 2.5, 1.2, "left")
			teaTowel(r, 0.25, 1.95, 1.38, 0.5, 0.75, C.Cream)
		end,
	},
	{
		id = "stove",
		name = "Stove",
		gives = "cook", -- holding E gives something (Data/Items.Sources)
		cat = "kitchen",
		style = "modern",
		price = 260,
		place = "floor",
		size = Vector3.new(3, 4.2, 2.6),
		surface = TOP,
		c1 = "E6E6E8",
		c2 = "2E2E33",
		tags = { "kitchen" },
		build = function(r: R)
			r:block(-1.45, 0, -1.25, 1.45, 0.15, 1.1, C.Black, "SmoothPlastic")
			r:block(-1.5, 0.15, -1.3, 1.5, TOP - 0.1, 1.2, r.c1, "Metal")
			-- a black glass cooktop with four rings
			r:block(-1.5, TOP - 0.1, -1.3, 1.5, TOP, 1.25, C.Black, "Glass")
			for _, x in { -0.7, 0.7 } do
				for _, z in { -0.5, 0.55 } do
					local d = if z > 0 then 0.75 else 0.95
					r:cyl(x, TOP + 0.015, z, 0.03, d, "y", Color3.fromRGB(90, 70, 70), "SmoothPlastic")
					r:cyl(x, TOP + 0.045, z, 0.03, d - 0.12, "y", C.Black, "Glass")
				end
			end
			-- a control strip with five knobs
			r:block(-1.5, 2.75, 1.2, 1.5, TOP - 0.1, 1.24, shade(r.c1, 0.92), "Metal")
			for _, x in { -1.1, -0.55, 0, 0.55, 1.1 } do
				r:cyl(x, 3.02, 1.29, 0.1, 0.26, "z", r.c2, "SmoothPlastic")
				r:block(x - 0.02, 3.05, 1.34, x + 0.02, 3.13, 1.37, STEEL, "Metal")
			end
			-- the oven door with a big window and a bar handle, and a drawer under it
			r:block(-1.42, 0.68, 1.2, 1.42, 2.65, 1.27, r.c2, "Metal")
			r:block(-1.1, 0.95, 1.27, 1.1, 2.15, 1.3, Color3.fromRGB(60, 52, 50), "Glass")
			r:block(-0.9, 1.05, 1.3, 0.9, 1.15, 1.33, Color3.fromRGB(110, 90, 80), "SmoothPlastic")
			r:cyl(0, 2.42, 1.42, 2.3, 0.1, "x", STEEL, "Metal")
			for _, x in { -1.0, 1.0 } do
				r:block(x - 0.04, 2.38, 1.27, x + 0.04, 2.46, 1.42, STEEL, "Metal")
			end
			r:block(-1.42, 0.2, 1.2, 1.42, 0.6, 1.26, shade(r.c1, 0.9), "Metal")
			r:block(-0.4, 0.36, 1.26, 0.4, 0.44, 1.31, STEEL, "Metal")
			-- a back guard with a little clock, and a pot on a ring
			r:block(-1.5, TOP, -1.3, 1.5, TOP + 0.65, -1.1, r.c1, "Metal")
			r:block(-0.35, TOP + 0.2, -1.1, 0.35, TOP + 0.45, -1.07, C.Black, "Glass")
			r:block(-0.22, TOP + 0.28, -1.07, 0.12, TOP + 0.37, -1.04, Color3.fromRGB(120, 220, 160), "Neon")
			r:cyl(-0.7, TOP + 0.36, -0.5, 0.6, 0.8, "y", C.Red, "Metal")
			r:cyl(-0.7, TOP + 0.69, -0.5, 0.06, 0.86, "y", shade(C.Red, 0.85), "Metal")
			r:ball(-0.7, TOP + 0.76, -0.5, 0.14, C.Black, "SmoothPlastic")
			for _, sx in { -1, 1 } do
				r:block(
					-0.7 + sx * 0.4,
					TOP + 0.51,
					-0.56,
					-0.7 + sx * 0.52,
					TOP + 0.58,
					-0.44,
					C.Black,
					"SmoothPlastic"
				)
			end
		end,
	},
	{
		id = "fridge",
		name = "Fridge",
		gives = "fridge", -- holding E gives something (Data/Items.Sources)
		cat = "kitchen",
		style = "modern",
		price = 320,
		place = "floor",
		size = Vector3.new(3, 7, 2.6),
		c1 = "A8D5C2",
		c2 = "C9CCD3",
		tags = { "kitchen" },
		build = function(r: R)
			r:block(-1.4, 0, -1.2, 1.4, 0.3, 1.0, C.DarkMetal, "Metal")
			r:block(-1.5, 0.3, -1.3, 1.5, 6.6, 1.0, r.c1, "Metal")
			-- a rounded top, like an old fridge
			r:block(-1.5, 6.6, -1.3, 1.5, 6.95, 0.65, r.c1, "Metal")
			r:cyl(0, 6.6, 0.65, 3.0, 0.7, "x", r.c1, "Metal")
			-- a short freezer door over a tall fridge door, each on a dark rubber seal that shows
			-- as a line round it, with long chrome handles
			local door = shade(r.c1, 1.05)
			local seal = Color3.fromRGB(70, 72, 78)
			r:block(-1.42, 5.03, 1.0, 1.42, 6.57, 1.03, seal, "Rubber")
			r:block(-1.42, 0.43, 1.0, 1.42, 4.87, 1.03, seal, "Rubber")
			r:block(-1.45, 5.0, 1.03, 1.45, 6.6, 1.13, door, "Metal")
			r:cyl(0, 6.6, 1.03, 2.9, 0.2, "x", door, "Metal")
			r:block(-1.45, 0.4, 1.03, 1.45, 4.9, 1.13, door, "Metal")
			r:block(-1.5, 4.9, 0.98, 1.5, 5.0, 1.04, shade(r.c1, 0.75), "Metal")
			r:cyl(1.12, 5.85, 1.31, 0.9, 0.12, "y", r.c2, "Metal")
			r:cyl(1.12, 3.5, 1.31, 2.1, 0.12, "y", r.c2, "Metal")
			for _, y in { 5.48, 6.22, 2.55, 4.45 } do
				r:block(1.08, y - 0.04, 1.13, 1.16, y + 0.04, 1.31, r.c2, "Metal")
			end
			-- a badge, a vent at the foot, and a child's drawing held up by magnets
			r:block(-0.4, 4.6, 1.13, 0.4, 4.72, 1.16, r.c2, "Metal")
			for _, y in { 0.12, 0.2 } do
				r:block(-1.2, y, 1.0, 1.2, y + 0.04, 1.03, C.Black, "SmoothPlastic")
			end
			local note = CFrame.new(-0.6, 3.4, 1.145) * CFrame.Angles(0, 0, 0.08)
			r:boxAt(note, 0.6, 0.75, 0.03, C.Paper, "SmoothPlastic")
			r:boxAt(note * CFrame.new(0, -0.18, 0.03), 0.44, 0.14, 0.03, Color3.fromRGB(126, 160, 120), "SmoothPlastic")
			r:boxAt(
				note * CFrame.new(-0.08, 0.02, 0.03),
				0.22,
				0.2,
				0.03,
				Color3.fromRGB(184, 102, 92),
				"SmoothPlastic"
			)
			r:boxAt(note * CFrame.new(0.16, 0.2, 0.03), 0.12, 0.12, 0.03, C.Yellow, "SmoothPlastic")
			r:cyl(-0.6, 3.72, 1.19, 0.06, 0.16, "z", C.Red, "SmoothPlastic")
			r:cyl(0.2, 2.6, 1.155, 0.05, 0.18, "z", C.Yellow, "SmoothPlastic")
			r:cyl(-0.9, 5.7, 1.155, 0.05, 0.16, "z", Color3.fromRGB(94, 122, 150), "SmoothPlastic")
		end,
	},
	{
		id = "kitchen_island",
		name = "Kitchen island",
		cat = "kitchen",
		style = "modern",
		price = 260,
		place = "floor",
		size = Vector3.new(6, 3.4, 3.6),
		surface = TOP,
		c1 = "5C7FA3",
		c2 = "F2EFE8",
		tags = { "kitchen" },
		build = function(r: R)
			-- a stone top that runs down both ends to the floor
			r:block(-3, TOP - 0.25, -1.8, 3, TOP, 1.8, r.c2, "Marble")
			for _, sx in { -1, 1 } do
				local xa, xb = sx * 2.75, sx * 3
				r:block(math.min(xa, xb), 0, -1.8, math.max(xa, xb), TOP - 0.25, 1.8, r.c2, "Marble")
			end
			-- the cabinet on the cooking side (the back), its drawers and doors facing out that way
			r:block(-2.75, 0, -1.55, 2.75, 0.35, 0.55, shade(r.c1, 0.55), "Wood")
			r:block(-2.75, 0.35, -1.62, 2.75, TOP - 0.25, 0.6, r.c1, "Wood")
			for _, x in { -1.83, 1.83 } do
				front(r, x - 0.86, 2.55, x + 0.86, 3.05, -1.62, "top", -1)
				front(r, x - 0.86, 1.5, x + 0.86, 2.47, -1.62, "top", -1)
				front(r, x - 0.86, 0.42, x + 0.86, 1.42, -1.62, "top", -1)
			end
			front(r, -0.88, 0.42, -0.02, 3.05, -1.62, "right", -1)
			front(r, 0.02, 0.42, 0.88, 3.05, -1.62, "left", -1)
			-- the seating side: framed panels, brackets under the overhang and a foot rail
			for _, x in { -1.8, 0, 1.8 } do
				r:block(x - 0.78, 0.5, 0.6, x + 0.78, 2.95, 0.64, shade(r.c1, 1.05), "Wood")
				r:block(x - 0.6, 0.68, 0.64, x + 0.6, 2.77, 0.67, shade(r.c1, 0.9), "Wood")
			end
			for _, x in { -0.9, 0.9 } do
				r:tri(
					Vector3.new(x, TOP - 0.25, 0.6),
					Vector3.new(x, TOP - 0.25, 1.25),
					Vector3.new(x, 2.3, 0.6),
					0.16,
					shade(r.c1, 0.85),
					"Wood"
				)
			end
			r:cyl(0, 0.7, 1.2, 5.5, 0.1, "x", STEEL, "Metal")
			for _, x in { -2.0, 2.0 } do
				r:block(x - 0.04, 0.66, 0.64, x + 0.04, 0.74, 1.2, STEEL, "Metal")
			end
		end,
	},
	{
		id = "stool_bar",
		name = "Bar stool",
		cat = "kitchen",
		style = "modern",
		price = 60,
		place = "floor",
		size = Vector3.new(1.6, 3.6, 1.6),
		c1 = "D08A6C",
		c2 = "45454A",
		tags = { "kitchen", "seat" },
		build = function(r: R)
			for _, sx in { -1, 1 } do
				for _, sz in { -1, 1 } do
					rod(
						r,
						Vector3.new(sx * 0.42, 2.5, sz * 0.42),
						Vector3.new(sx * 0.66, 0, sz * 0.66),
						0.12,
						r.c2,
						"Metal"
					)
					r:cyl(sx * 0.66, 0.03, sz * 0.66, 0.06, 0.18, "y", C.Black, "Rubber")
				end
			end
			-- a ring to rest your feet on
			local k = 0.57
			for _, s in { -1, 1 } do
				rod(r, Vector3.new(-k, 0.95, s * k), Vector3.new(k, 0.95, s * k), 0.08, r.c2, "Metal")
				rod(r, Vector3.new(s * k, 0.95, -k), Vector3.new(s * k, 0.95, k), 0.08, r.c2, "Metal")
			end
			r:block(-0.55, 2.45, -0.55, 0.55, 2.55, 0.55, r.c2, "Metal")
			-- a padded seat with a low curved back
			r:cyl(0, 2.68, 0, 0.26, 1.5, "y", r.c1, "Fabric")
			r:cyl(0, 2.6, 0, 0.05, 1.58, "y", shade(r.c1, 0.7), "Fabric")
			for i = -1, 1 do
				r:boxAt(
					CFrame.new(i * 0.42, 3.15, -0.62 + math.abs(i) * 0.12) * CFrame.Angles(-0.12, -i * 0.5, 0),
					0.5,
					0.6,
					0.16,
					r.c1,
					"Fabric"
				)
			end
			for _, x in { -0.35, 0.35 } do
				rod(r, Vector3.new(x, 2.55, -0.55), Vector3.new(x, 2.95, -0.62), 0.06, r.c2, "Metal")
			end
			r:seat(0, 2.81, 0)
		end,
	},
	{
		id = "pantry",
		name = "Pantry",
		gives = "pantry", -- holding E gives something (Data/Items.Sources)
		cat = "kitchen",
		style = "rustic",
		price = 200,
		place = "floor",
		size = Vector3.new(3, 7, 2.2),
		c1 = "F7F3EA",
		c2 = "C99A62",
		tags = { "kitchen", "storage" },
		build = function(r: R)
			local inside = shade(r.c1, 0.8)
			r:block(-1.5, 0, -1.1, 1.5, 0.35, 0.8, shade(r.c1, 0.55), "Wood")
			-- solid below; above, an open case (back, sides, shelves) behind glass doors
			r:block(-1.5, 0.35, -1.1, 1.5, 3.9, 0.98, r.c1, "Wood")
			r:block(-1.5, 3.9, -1.1, 1.5, 6.7, -0.92, inside, "Wood")
			for _, sx in { -1, 1 } do
				local xa, xb = sx * 1.5, sx * 1.38
				r:block(math.min(xa, xb), 3.9, -0.92, math.max(xa, xb), 6.7, 0.98, r.c1, "Wood")
			end
			r:block(-1.38, 6.58, -0.92, 1.38, 6.7, 0.98, r.c1, "Wood")
			r:block(-1.55, 6.7, -1.1, 1.55, 6.85, 1.06, r.c1, "Wood")
			r:block(-1.6, 6.85, -1.1, 1.6, 7, 1.1, r.c2, "Wood")
			-- two shelves of jars, tins and a bag of flour
			local jars = { C.Yellow, Color3.fromRGB(192, 122, 96), C.Cream, Color3.fromRGB(143, 179, 154) }
			for row, y in { 3.9, 5.25 } do
				r:block(-1.38, y, -0.92, 1.38, y + 0.08, 0.82, r.c2, "Wood")
				for i, col in jars do
					local x = -1.0 + (i - 1) * 0.62
					local h = if (i + row) % 2 == 0 then 0.7 else 0.5
					r:cyl(x, y + 0.08 + h * 0.36, 0.2, h * 0.72, 0.42, "y", col, "SmoothPlastic")
					r:cyl(x, y + 0.08 + h * 0.86, 0.2, h * 0.28, 0.42, "y", Color3.fromRGB(214, 232, 236), "Glass")
					r:cyl(x, y + 0.08 + h + 0.05, 0.2, 0.1, 0.46, "y", if i % 2 == 0 then r.c2 else C.Red, "Wood")
				end
			end
			r:block(-1.3, 3.98, -0.75, -0.7, 4.6, -0.4, C.Paper, "Fabric")
			-- doors: solid shaker panels below, glass in a frame above with a bar across it
			for _, sx in { -1, 1 } do
				local xa, xb = sx * 0.03, sx * 1.45
				local x1, x2 = math.min(xa, xb), math.max(xa, xb)
				r:block(x1, 0.45, 0.98, x2, 3.9, 1.04, shade(r.c1, 1.04), "Wood")
				r:block(x1 + 0.18, 0.65, 1.04, x2 - 0.18, 3.7, 1.07, shade(r.c1, 0.92), "Wood")
				r:piece(function(q: R)
					q:block(x1, 3.9, 0.98, x2, 4.06, 1.04, shade(r.c1, 1.04), "Wood")
					q:block(x1, 6.44, 0.98, x2, 6.58, 1.04, shade(r.c1, 1.04), "Wood")
					q:block(x1, 4.06, 0.98, x1 + 0.16, 6.44, 1.04, shade(r.c1, 1.04), "Wood")
					q:block(x2 - 0.16, 4.06, 0.98, x2, 6.44, 1.04, shade(r.c1, 1.04), "Wood")
					q:block(x1 + 0.16, 5.2, 0.98, x2 - 0.16, 5.28, 1.04, shade(r.c1, 1.04), "Wood")
				end)
				r:glass(x1 + 0.16, 4.06, 1.0, x2 - 0.16, 5.2, 1.02)
				r:glass(x1 + 0.16, 5.28, 1.0, x2 - 0.16, 6.44, 1.02)
				r:block(sx * 0.18 - 0.04, 3.4, 1.04, sx * 0.18 + 0.04, 4.4, 1.1, r.c2, "Metal")
			end
		end,
	},
	{
		id = "microwave",
		name = "Microwave",
		cat = "kitchen",
		style = "modern",
		price = 120,
		place = "surface",
		size = Vector3.new(1.8, 1.1, 1.3),
		c1 = "F7F3EA",
		c2 = "45454A",
		tags = { "kitchen" },
		build = function(r: R)
			for _, x in { -0.72, 0.72 } do
				r:block(x - 0.1, 0, -0.5, x + 0.1, 0.05, 0.5, C.Black, "SmoothPlastic")
			end
			r:block(-0.9, 0.05, -0.65, 0.9, 1.05, 0.58, r.c1, "Metal")
			r:block(-0.86, 1.05, -0.61, 0.86, 1.1, 0.54, shade(r.c1, 0.92), "Metal")
			-- the door with a dark window and a recessed handle
			r:block(-0.84, 0.11, 0.58, 0.4, 1.02, 0.63, r.c2, "Metal")
			r:block(-0.72, 0.24, 0.63, 0.16, 0.9, 0.66, Color3.fromRGB(56, 64, 62), "Glass")
			r:block(0.26, 0.24, 0.63, 0.34, 0.9, 0.7, C.Metal, "Metal")
			-- a control panel with a display and buttons
			r:block(0.44, 0.11, 0.58, 0.84, 1.02, 0.62, shade(r.c1, 0.85), "Metal")
			r:block(0.5, 0.82, 0.62, 0.78, 0.95, 0.65, C.Black, "Glass")
			r:block(0.54, 0.85, 0.65, 0.72, 0.92, 0.68, Color3.fromRGB(120, 220, 160), "Neon")
			for _, y in { 0.3, 0.45, 0.6 } do
				for _, x in { 0.55, 0.72 } do
					r:block(x - 0.05, y, 0.62, x + 0.05, y + 0.08, 0.65, C.DarkMetal, "SmoothPlastic")
				end
			end
		end,
	},
	{
		id = "kettle",
		name = "Kettle",
		gives = "tea", -- holding E gives something (Data/Items.Sources)
		cat = "kitchen",
		style = "cozy",
		price = 40,
		place = "surface",
		size = Vector3.new(1.2, 1.3, 0.9),
		c1 = "D08A6C",
		c2 = "45454A",
		tags = { "kitchen" },
		build = function(r: R)
			r:cyl(0, 0.04, 0, 0.08, 0.84, "y", r.c2, "SmoothPlastic")
			r:cyl(0, 0.32, 0, 0.48, 0.82, "y", r.c1, "Metal")
			r:cyl(0, 0.68, 0, 0.26, 0.72, "y", r.c1, "Metal")
			r:cyl(0, 0.83, 0, 0.06, 0.56, "y", shade(r.c1, 0.8), "Metal")
			r:cyl(0, 0.88, 0, 0.06, 0.5, "y", r.c1, "Metal")
			r:ball(0, 0.95, 0, 0.16, r.c2, "SmoothPlastic")
			rod(r, Vector3.new(0.3, 0.42, 0), Vector3.new(0.56, 0.76, 0), 0.12, r.c1, "Metal")
			-- the handle over the back
			rod(r, Vector3.new(-0.3, 0.75, 0), Vector3.new(-0.5, 0.95, 0), 0.1, r.c2, "SmoothPlastic")
			rod(r, Vector3.new(-0.5, 0.95, 0), Vector3.new(-0.5, 0.35, 0), 0.1, r.c2, "SmoothPlastic")
			rod(r, Vector3.new(-0.5, 0.38, 0), Vector3.new(-0.36, 0.25, 0), 0.1, r.c2, "SmoothPlastic")
		end,
	},
	{
		id = "toaster",
		name = "Toaster",
		cat = "kitchen",
		style = "modern",
		price = 35,
		place = "surface",
		size = Vector3.new(1.2, 1.0, 0.8),
		c1 = "8FB39A",
		c2 = "D9A86C",
		tags = { "kitchen" },
		build = function(r: R)
			r:block(-0.52, 0, -0.32, 0.52, 0.06, 0.32, C.Black, "SmoothPlastic")
			-- a rounded body with two slots and a chrome band round the middle
			r:block(-0.5, 0.06, -0.35, 0.5, 0.5, 0.35, r.c1, "Metal")
			r:block(-0.5, 0.5, -0.2, 0.5, 0.65, 0.2, r.c1, "Metal")
			for _, z in { -0.2, 0.2 } do
				r:cyl(0, 0.5, z, 1.0, 0.3, "x", r.c1, "Metal")
			end
			r:block(-0.53, 0.26, -0.38, 0.53, 0.32, 0.38, C.Metal, "Metal")
			for _, z in { -0.12, 0.12 } do
				r:block(-0.36, 0.65, z - 0.065, 0.36, 0.68, z + 0.065, C.Black, "SmoothPlastic")
			end
			-- two slices of toast popping up, golden with a darker crust on the top
			for _, z in { -0.12, 0.12 } do
				r:block(-0.3, 0.5, z - 0.035, 0.3, 0.88, z + 0.035, r.c2, "SmoothPlastic")
				r:lump(CFrame.new(0, 0.88, z), 0.64, 0.16, 0.09, shade(r.c2, 0.72), "SmoothPlastic")
			end
			-- the lever and a dial on the side
			r:block(0.53, 0.38, -0.05, 0.6, 0.46, 0.05, C.Black, "SmoothPlastic")
			r:cyl(0.55, 0.16, 0.18, 0.06, 0.12, "x", C.Metal, "Metal")
		end,
	},
}

return items
