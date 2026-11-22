--!strict
-- Beds. The head is at the back (-z) and the foot at the front (+z). Every bed marks where
-- someone sleeps with r:sleep, so villagers can use it at night.
-- c1 is the frame, c2 the blanket.

local Recipe = require(script.Parent.Parent.Recipe)
local Colors = require(script.Parent.Parent.Parent.Util.Colors)

local C = Recipe.Colors

type R = Recipe.Recipe

local function shade(c: Color3, k: number): Color3
	return Colors.shade(c, k)
end

-- A soft pillow `w` wide whose bottom is at y and whose middle is at z.
local function pillow(r: R, x: number, y: number, z: number, w: number)
	r:block(x - w / 2, y, z - 0.35, x + w / 2, y + 0.35, z + 0.35, C.White, "Fabric")
	r:cyl(x, y + 0.175, z - 0.35, w, 0.35, "x", C.White, "Fabric")
	r:cyl(x, y + 0.175, z + 0.35, w, 0.35, "x", C.White, "Fabric")
end

-- A mattress from y0 to y1 with a blanket that starts at zb and hangs over the sides,
-- and the sheet folded back over its top edge.
local function mattress(
	r: R,
	x1: number,
	x2: number,
	z1: number,
	z2: number,
	y0: number,
	y1: number,
	zb: number,
	blanket: Color3
)
	r:block(x1, y0, z1, x2, y1, z2, C.White, "Fabric")
	r:block(x1 - 0.08, y1 - 0.5, zb, x2 + 0.08, y1 + 0.1, z2 + 0.02, blanket, "Fabric")
	r:block(x1 - 0.09, y1 + 0.02, zb, x2 + 0.09, y1 + 0.16, zb + 0.45, C.White, "Fabric")
end

-- Four short legs under the corners.
local function feet(r: R, x: number, z: number, h: number, color: Color3)
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			r:box(sx * x, h / 2, sz * z, 0.36, h, 0.36, color, "Wood")
		end
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
		id = "bed_single",
		name = "Single bed",
		cat = "beds",
		price = 180,
		place = "floor",
		size = Vector3.new(3.6, 3.6, 7.2),
		c1 = "C99A62",
		c2 = "7A9CC6",
		tags = { "bed" },
		build = function(r: R)
			feet(r, 1.62, 3.42, 0.6, shade(r.c1, 0.85))
			r:block(-1.8, 0.6, -3.35, 1.8, 1.1, 3.35, r.c1, "Wood")
			mattress(r, -1.65, 1.65, -3.35, 3.3, 1.1, 1.8, -0.9, r.c2)
			pillow(r, 0, 1.8, -2.6, 2.2)
			r:block(-1.8, 0.6, -3.6, 1.8, 3.4, -3.35, r.c1, "Wood")
			r:cyl(0, 3.4, -3.475, 3.6, 0.4, "x", shade(r.c1, 0.9), "Wood")
			r:block(-1.8, 0.6, 3.35, 1.8, 2.3, 3.6, r.c1, "Wood")
			r:cyl(0, 2.3, 3.475, 3.6, 0.4, "x", shade(r.c1, 0.9), "Wood")
			r:sleep(0, 1.9, 0.1)
		end,
	},
	{
		id = "bed_double",
		name = "Double bed",
		cat = "beds",
		price = 320,
		place = "floor",
		size = Vector3.new(6, 4.3, 7.6),
		c1 = "6B4423",
		c2 = "8FB39A",
		tags = { "bed" },
		build = function(r: R)
			feet(r, 2.8, 3.6, 0.6, r.c1)
			r:block(-3, 0.6, -3.55, 3, 1.2, 3.55, r.c1, "Wood")
			mattress(r, -2.85, 2.85, -3.55, 3.5, 1.2, 1.95, -0.9, r.c2)
			-- a folded throw across the foot
			r:block(-2.95, 1.95, 2.0, 2.95, 2.2, 3.0, shade(r.c2, 0.75), "Fabric")
			pillow(r, -1.35, 1.95, -2.8, 2.3)
			pillow(r, 1.35, 1.95, -2.8, 2.3)
			-- a tall headboard with three raised panels and a cap
			r:block(-3, 0.6, -3.8, 3, 4.0, -3.55, r.c1, "Wood")
			for _, x in { -1.9, 0, 1.9 } do
				r:block(x - 0.75, 2.2, -3.55, x + 0.75, 3.7, -3.48, shade(r.c1, 1.2), "Wood")
			end
			r:block(-3, 4.0, -3.8, 3, 4.3, -3.45, shade(r.c1, 0.85), "Wood")
			r:block(-3, 0.6, 3.55, 3, 1.9, 3.8, r.c1, "Wood")
			r:sleep(-1.35, 2.05, 0.1)
			r:sleep(1.35, 2.05, 0.1)
		end,
	},
	{
		id = "bed_bunk",
		name = "Bunk bed",
		cat = "beds",
		price = 380,
		place = "floor",
		size = Vector3.new(4.2, 7.2, 7.2),
		c1 = "A8743F",
		c2 = "D9805F",
		tags = { "bed" },
		build = function(r: R)
			-- corner posts
			for _, sx in { -1, 1 } do
				for _, sz in { -1, 1 } do
					r:box(sx * 1.7, 3.6, sz * 3.4, 0.4, 7.2, 0.4, r.c1, "Wood")
				end
			end
			for _, y in { 0.6, 4.3 } do
				r:block(-1.9, y, -3.4, 1.9, y + 0.5, 3.4, r.c1, "Wood")
				mattress(r, -1.6, 1.6, -3.2, 3.2, y + 0.5, y + 1.1, -0.9, r.c2)
				pillow(r, 0, y + 1.1, -2.5, 2.0)
			end
			-- head and foot boards for both bunks
			r:block(-1.5, 1.1, -3.5, 1.5, 2.6, -3.3, r.c1, "Wood")
			r:block(-1.5, 4.8, -3.5, 1.5, 6.8, -3.3, r.c1, "Wood")
			r:block(-1.5, 1.1, 3.3, 1.5, 2.0, 3.5, r.c1, "Wood")
			r:block(-1.5, 4.8, 3.3, 1.5, 6.3, 3.5, r.c1, "Wood")
			-- guard rails round the top bunk, with a gap for the ladder
			r:block(-1.9, 6.2, -3.2, -1.6, 6.5, 3.2, r.c1, "Wood")
			r:block(1.6, 6.2, -3.2, 1.9, 6.5, 1.6, r.c1, "Wood")
			-- the ladder on the right, by the foot
			for _, z in { 1.75, 3.15 } do
				r:block(1.9, 0, z - 0.1, 2.1, 6.5, z + 0.1, shade(r.c1, 0.85), "Wood")
			end
			for i = 1, 5 do
				local y = 0.9 + (i - 1) * 1.05
				r:block(1.92, y, 1.85, 2.08, y + 0.15, 3.05, shade(r.c1, 0.85), "Wood")
			end
			r:sleep(0, 1.7, 0.1)
			r:sleep(0, 5.4, 0.1)
		end,
	},
	{
		id = "futon",
		name = "Futon",
		cat = "beds",
		price = 150,
		place = "floor",
		size = Vector3.new(4.2, 1.8, 7),
		c1 = "C99A62",
		c2 = "D9805F",
		tags = { "bed" },
		build = function(r: R)
			feet(r, 1.8, 3.2, 0.2, shade(r.c1, 0.8))
			r:block(-2.1, 0.2, -3.5, 2.1, 0.45, 3.5, r.c1, "Wood")
			r:block(-1.95, 0.45, -3.35, 1.95, 1.15, 3.35, r.c2, "Fabric")
			-- tufts on the mattress
			for _, z in { -0.4, 1.2, 2.6 } do
				for _, x in { -0.9, 0.9 } do
					r:ball(x, 1.15, z, 0.18, shade(r.c2, 0.75), "Fabric")
				end
			end
			r:block(-1.75, 1.15, 1.8, 1.75, 1.45, 3.0, C.Cream, "Fabric")
			pillow(r, 0, 1.15, -2.6, 2.2)
			r:sleep(0, 1.2, 0)
		end,
	},
	{
		id = "bed_canopy",
		name = "Canopy bed",
		cat = "beds",
		price = 600,
		place = "floor",
		size = Vector3.new(6.2, 9, 7.8),
		c1 = "F7F3EA",
		c2 = "D99AA4",
		tags = { "bed" },
		build = function(r: R)
			local cloth = Colors.mix(r.c2, C.White, 0.45)
			for _, sx in { -1, 1 } do
				for _, sz in { -1, 1 } do
					r:box(sx * 2.9, 4.4, sz * 3.7, 0.4, 8.8, 0.4, r.c1, "Wood")
					r:ball(sx * 2.9, 8.85, sz * 3.7, 0.5, r.c1, "Wood")
					-- a curtain at each corner, tied back to the post
					local x1, x2 = sx * 2.72, sx * 2.86
					local zp = sz * 3.5
					r:block(x1, 4.0, zp, x2, 8.2, zp - sz * 1.1, r.c2, "Fabric")
					r:block(x1, 1.3, zp, x2, 3.7, zp - sz * 0.6, r.c2, "Fabric")
					r:block(sx * 2.68, 3.65, zp, sx * 2.9, 4.05, zp - sz * 0.45, C.Gold, "Fabric")
				end
			end
			-- the top frame and a frilled valance round it
			for _, sz in { -1, 1 } do
				r:block(-2.9, 8.2, sz * 3.7 - 0.15, 2.9, 8.6, sz * 3.7 + 0.15, r.c1, "Wood")
				r:block(-2.7, 7.4, sz * 3.6 - 0.08, 2.7, 8.2, sz * 3.6 + 0.08, r.c2, "Fabric")
			end
			for _, sx in { -1, 1 } do
				r:block(sx * 2.9 - 0.15, 8.2, -3.7, sx * 2.9 + 0.15, 8.6, 3.7, r.c1, "Wood")
				r:block(sx * 2.8 - 0.08, 7.4, -3.5, sx * 2.8 + 0.08, 8.2, 3.5, r.c2, "Fabric")
			end
			r:block(-2.75, 8.5, -3.55, 2.75, 8.6, 3.55, cloth, "Fabric")
			-- the bed itself
			r:block(-2.8, 0.5, -3.5, 2.8, 1.2, 3.5, r.c1, "Wood")
			mattress(r, -2.65, 2.65, -3.45, 3.4, 1.2, 1.95, -0.9, cloth)
			pillow(r, -1.3, 1.95, -2.75, 2.2)
			pillow(r, 1.3, 1.95, -2.75, 2.2)
			r:block(-2.7, 1.2, -3.75, 2.7, 4.4, -3.5, r.c1, "Wood")
			r:block(-1.8, 4.4, -3.72, 1.8, 4.9, -3.53, r.c1, "Wood")
			r:sleep(-1.3, 2.05, 0.1)
			r:sleep(1.3, 2.05, 0.1)
		end,
	},
	{
		id = "bed_kids",
		name = "Kids' house bed",
		cat = "beds",
		price = 240,
		place = "floor",
		size = Vector3.new(3.8, 6.4, 6.8),
		c1 = "F7F3EA",
		c2 = "7FB8D9",
		tags = { "bed" },
		build = function(r: R)
			feet(r, 1.5, 3.0, 0.2, r.c1)
			r:block(-1.7, 0.2, -3.2, 1.7, 0.7, 3.2, r.c1, "Wood")
			mattress(r, -1.55, 1.55, -3.1, 3.1, 0.7, 1.3, -0.7, r.c2)
			-- stars on the blanket
			for _, p in { { -0.7, 0.4 }, { 0.5, 1.3 }, { -0.2, 2.3 }, { 0.8, -0.2 } } do
				r:block(p[1] - 0.15, 1.4, p[2] - 0.15, p[1] + 0.15, 1.44, p[2] + 0.15, C.Yellow, "Fabric")
			end
			pillow(r, 0, 1.3, -2.45, 2.0)
			-- a frame shaped like a little house
			for _, sz in { -1, 1 } do
				local z = sz * 3.25
				for _, sx in { -1, 1 } do
					r:box(sx * 1.75, 2.1, z, 0.3, 4.2, 0.3, r.c1, "Wood")
					r:beam(Vector3.new(sx * 1.85, 4.1, z), Vector3.new(0, 6.15, z), 0.3, 0.3, r.c1, "Wood")
				end
			end
			for _, sx in { -1, 1 } do
				r:block(sx * 1.75 - 0.15, 3.95, -3.25, sx * 1.75 + 0.15, 4.25, 3.25, r.c1, "Wood")
			end
			r:block(-0.15, 6.0, -3.4, 0.15, 6.3, 3.4, r.c1, "Wood")
			r:sleep(0, 1.4, 0.2)
		end,
	},
}

return items
