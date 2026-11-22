--!strict
-- Chairs, sofas and other places to sit. Every spot a person can sit on is marked with r:seat.
-- c1 is the main colour (wood or fabric), c2 the second one (a seat pad, cushions or legs).

local Recipe = require(script.Parent.Parent.Recipe)
local Colors = require(script.Parent.Parent.Parent.Util.Colors)

type R = Recipe.Recipe

local function shade(c: Color3, k: number): Color3
	return Colors.shade(c, k)
end

-- A padded piece with rolled arms and a back, `n` cushions wide. Fabric in c1, short legs in c2.
local function upholstered(r: R, w: number, d: number, n: number)
	local a = 0.7 -- arm thickness
	local frame = shade(r.c1, 0.86)
	local zb = -d / 2 + 0.7 -- the front face of the back
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			r:box(sx * (w / 2 - 0.35), 0.2, sz * (d / 2 - 0.35), 0.35, 0.4, 0.35, r.c2, "Wood")
		end
	end
	-- the back runs the full width and has a rolled top
	r:block(-w / 2, 0.4, -d / 2, w / 2, 3.0, zb, frame, "Fabric")
	r:cyl(0, 3.0, -d / 2 + 0.35, w, 0.7, "x", frame, "Fabric")
	for _, sx in { -1, 1 } do
		local xo, xi = sx * w / 2, sx * (w / 2 - a)
		r:block(math.min(xo, xi), 0.4, zb, math.max(xo, xi), 2.3, d / 2, frame, "Fabric")
		r:cyl(sx * (w / 2 - a / 2), 2.3, (zb + d / 2) / 2, d / 2 - zb, a, "z", frame, "Fabric")
	end
	r:block(-w / 2 + a, 0.4, zb, w / 2 - a, 1.2, d / 2, frame, "Fabric")
	local iw = w - 2 * a
	local cw = iw / n
	local zs = zb + 0.55 -- the back edge of the seat cushions
	for i = 1, n do
		local x1 = -iw / 2 + (i - 1) * cw + 0.04
		local x2 = x1 + cw - 0.08
		local xm = (x1 + x2) / 2
		r:block(x1, 1.2, zs, x2, 1.75, d / 2 - 0.275, r.c1, "Fabric")
		r:cyl(xm, 1.475, d / 2 - 0.275, x2 - x1, 0.55, "x", r.c1, "Fabric")
		r:block(x1, 1.2, zb, x2, 2.85, zs, r.c1, "Fabric")
		r:cyl(xm, 2.85, zb + 0.275, x2 - x1, 0.55, "x", r.c1, "Fabric")
		r:seat(xm, 1.75, (zs + d / 2) / 2)
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
		id = "chair_wood",
		name = "Wooden chair",
		cat = "seating",
		price = 50,
		place = "floor",
		size = Vector3.new(2, 4.1, 2),
		c1 = "C99A62",
		c2 = "E8A0A8",
		tags = { "seat" },
		build = function(r: R)
			local leg = shade(r.c1, 0.85)
			for _, sx in { -1, 1 } do
				local x = sx * 0.85
				r:block(x - 0.13, 0, 0.72, x + 0.13, 1.6, 0.98, leg, "Wood")
				-- the back legs carry on up into the backrest
				r:block(x - 0.13, 0, -0.98, x + 0.13, 4.0, -0.72, leg, "Wood")
				r:block(x - 0.07, 0.45, -0.72, x + 0.07, 0.6, 0.72, leg, "Wood")
			end
			r:block(-1, 1.6, -1, 1, 1.85, 1, r.c1, "Wood")
			r:block(-0.8, 1.85, -0.7, 0.8, 2.0, 0.85, r.c2, "Fabric")
			r:block(-1, 3.55, -0.98, 1, 4.05, -0.72, r.c1, "Wood")
			r:block(-0.72, 2.35, -0.92, 0.72, 2.55, -0.78, r.c1, "Wood")
			for _, x in { -0.4, 0, 0.4 } do
				r:block(x - 0.07, 1.85, -0.9, x + 0.07, 3.55, -0.8, leg, "Wood")
			end
			r:seat(0, 2.0, 0.1)
		end,
	},
	{
		id = "chair_dining",
		name = "Dining chair",
		cat = "seating",
		price = 80,
		place = "floor",
		size = Vector3.new(2, 4.3, 2),
		c1 = "6B4423",
		c2 = "E9DCC3",
		tags = { "seat" },
		build = function(r: R)
			for _, sx in { -1, 1 } do
				local x = sx * 0.82
				r:block(x - 0.14, 0, 0.66, x + 0.14, 1.45, 0.94, r.c1, "Wood")
				r:block(x - 0.14, 0, -0.96, x + 0.14, 4.3, -0.68, r.c1, "Wood")
			end
			r:block(-0.98, 1.4, -0.98, 0.98, 1.7, 0.98, r.c1, "Wood")
			r:block(-0.94, 1.7, -0.7, 0.94, 2.05, 0.8, r.c2, "Fabric")
			r:cyl(0, 1.875, 0.8, 1.88, 0.35, "x", r.c2, "Fabric")
			-- a padded back under a wooden top rail, with two buttons
			r:block(-0.68, 2.3, -0.92, 0.68, 3.85, -0.72, r.c2, "Fabric")
			r:block(-0.96, 3.85, -0.98, 0.96, 4.3, -0.66, r.c1, "Wood")
			r:block(-0.68, 2.15, -0.9, 0.68, 2.3, -0.74, r.c1, "Wood")
			for _, x in { -0.3, 0.3 } do
				r:ball(x, 3.1, -0.72, 0.14, shade(r.c2, 0.8), "Fabric")
			end
			r:seat(0, 2.05, 0.1)
		end,
	},
	{
		id = "armchair",
		name = "Armchair",
		cat = "seating",
		price = 140,
		place = "floor",
		size = Vector3.new(3.4, 3.4, 3.2),
		c1 = "D9805F",
		c2 = "6B4423",
		tags = { "seat" },
		build = function(r: R)
			upholstered(r, 3.4, 3.2, 1)
		end,
	},
	{
		id = "sofa_two",
		name = "Two seat sofa",
		cat = "seating",
		price = 200,
		place = "floor",
		size = Vector3.new(5.4, 3.4, 3.2),
		c1 = "8FB39A",
		c2 = "6B4423",
		tags = { "seat" },
		build = function(r: R)
			upholstered(r, 5.4, 3.2, 2)
		end,
	},
	{
		id = "sofa_three",
		name = "Three seat sofa",
		cat = "seating",
		price = 280,
		place = "floor",
		size = Vector3.new(7.4, 3.4, 3.2),
		c1 = "7A9CC6",
		c2 = "4A3426",
		tags = { "seat" },
		build = function(r: R)
			upholstered(r, 7.4, 3.2, 3)
		end,
	},
	{
		id = "bench_wood",
		name = "Bench",
		cat = "seating",
		price = 60,
		place = "floor",
		size = Vector3.new(4.8, 2, 1.8),
		c1 = "B07A45",
		c2 = "7A5230",
		tags = { "seat" },
		build = function(r: R)
			for _, sx in { -1, 1 } do
				local x = sx * 1.85
				r:block(x - 0.18, 0, -0.75, x + 0.18, 1.65, 0.75, r.c2, "Wood")
				r:block(x - 0.24, 0, -0.85, x + 0.24, 0.25, 0.85, r.c2, "Wood")
			end
			r:block(-1.7, 0.55, -0.12, 1.7, 0.8, 0.12, r.c2, "Wood")
			for _, z in { -0.6, 0, 0.6 } do
				r:block(-2.4, 1.65, z - 0.27, 2.4, 1.95, z + 0.27, r.c1, "WoodPlanks")
			end
			r:seat(-1.2, 1.95, 0)
			r:seat(1.2, 1.95, 0)
		end,
	},
	{
		id = "stool",
		name = "Stool",
		cat = "seating",
		price = 40,
		place = "floor",
		size = Vector3.new(1.6, 2.2, 1.6),
		c1 = "C99A62",
		c2 = "D9805F",
		tags = { "seat" },
		build = function(r: R)
			local leg = shade(r.c1, 0.85)
			for _, sx in { -1, 1 } do
				for _, sz in { -1, 1 } do
					r:beam(
						Vector3.new(sx * 0.4, 1.8, sz * 0.4),
						Vector3.new(sx * 0.62, 0, sz * 0.62),
						0.2,
						0.2,
						leg,
						"Wood"
					)
				end
			end
			-- a ring of rails to rest your feet on
			for _, s in { -1, 1 } do
				r:block(-0.55, 0.6, s * 0.55 - 0.06, 0.55, 0.72, s * 0.55 + 0.06, leg, "Wood")
				r:block(s * 0.55 - 0.06, 0.6, -0.55, s * 0.55 + 0.06, 0.72, 0.55, leg, "Wood")
			end
			r:cyl(0, 1.875, 0, 0.25, 1.6, "y", r.c1, "Wood")
			r:cyl(0, 2.075, 0, 0.15, 1.35, "y", r.c2, "Fabric")
			r:seat(0, 2.15, 0)
		end,
	},
	{
		id = "beanbag",
		name = "Bean bag",
		cat = "seating",
		price = 70,
		place = "floor",
		size = Vector3.new(2.8, 2.8, 2.8),
		c1 = "E0B04A",
		c2 = "F2E8D5",
		tags = { "seat" },
		build = function(r: R)
			r:cyl(0, 0.175, 0, 0.35, 2.7, "y", shade(r.c1, 0.9), "Fabric")
			r:ball(0, 1.05, 0.05, 2.5, r.c1, "Fabric")
			r:ball(0, 1.8, -0.5, 1.8, r.c1, "Fabric")
			-- a little sewn on label
			r:block(0.35, 0.45, 1.12, 0.75, 0.75, 1.3, r.c2, "Fabric")
			r:seat(0, 1.7, 0.35)
		end,
	},
	{
		id = "chair_rocking",
		name = "Rocking chair",
		cat = "seating",
		price = 120,
		place = "floor",
		size = Vector3.new(2.2, 4.5, 3.4),
		c1 = "A8743F",
		c2 = "C9D8B6",
		tags = { "seat" },
		build = function(r: R)
			local dk = shade(r.c1, 0.82)
			for _, sx in { -1, 1 } do
				local x = sx * 0.9
				local pts = {
					Vector3.new(x, 0.6, -1.6),
					Vector3.new(x, 0.14, -0.6),
					Vector3.new(x, 0.14, 0.6),
					Vector3.new(x, 0.6, 1.6),
				}
				for i = 1, 3 do
					-- stretch each piece a little past its ends so the joints close up
					local a, b = pts[i], pts[i + 1]
					local d = (b - a).Unit * 0.1
					r:beam(if i > 1 then a - d else a, if i < 3 then b + d else b, 0.24, 0.24, dk, "Wood")
				end
				r:block(x - 0.11, 0.14, 0.55, x + 0.11, 1.75, 0.77, dk, "Wood")
				r:block(x - 0.11, 0.14, -0.77, x + 0.11, 1.75, -0.55, dk, "Wood")
				-- the back post leans back a little
				r:beam(Vector3.new(x, 1.75, -0.7), Vector3.new(x, 4.3, -1.25), 0.24, 0.24, r.c1, "Wood")
				r:block(x - 0.15, 2.75, -1.0, x + 0.15, 2.95, 0.95, r.c1, "Wood")
				r:block(x - 0.08, 1.95, 0.62, x + 0.08, 2.75, 0.78, dk, "Wood")
			end
			r:block(-1.02, 1.75, -0.9, 1.02, 1.95, 0.95, r.c1, "Wood")
			r:block(-0.8, 1.95, -0.75, 0.8, 2.1, 0.85, r.c2, "Fabric")
			r:boxAt(CFrame.new(0, 4.15, -1.22) * CFrame.Angles(-0.21, 0, 0), 2.0, 0.45, 0.24, r.c1, "Wood")
			for _, x in { -0.5, -0.17, 0.17, 0.5 } do
				r:beam(Vector3.new(x, 1.95, -0.78), Vector3.new(x, 3.95, -1.2), 0.13, 0.13, dk, "Wood")
			end
			r:seat(0, 2.1, 0.1)
		end,
	},
	{
		id = "chair_lounge",
		name = "Lounge chair",
		cat = "seating",
		price = 150,
		place = "floor",
		size = Vector3.new(2.6, 3.4, 5),
		c1 = "F2E8D5",
		c2 = "8A5A2E",
		tags = { "seat" },
		build = function(r: R)
			for _, sx in { -1, 1 } do
				for _, sz in { -1, 1 } do
					r:box(sx * 1.0, 0.3, sz * 2.2, 0.3, 0.6, 0.3, r.c2, "Wood")
				end
			end
			r:block(-1.25, 0.6, -2.5, 1.25, 1.0, 2.5, r.c2, "Wood")
			-- the seat cushion with a rounded front
			r:block(-1.15, 1.0, -0.9, 1.15, 1.45, 2.27, r.c1, "Fabric")
			r:cyl(0, 1.225, 2.27, 2.3, 0.45, "x", r.c1, "Fabric")
			-- a sloped frame holds the back up
			r:ramp(-1.2, 1.0, -2.45, 1.2, 2.7, -0.95, false, r.c2, "Wood")
			r:beam(Vector3.new(0, 1.3, -0.75), Vector3.new(0, 3.0, -2.15), 2.3, 0.5, r.c1, "Fabric")
			r:cyl(0, 3.0, -2.05, 2.0, 0.6, "x", shade(r.c1, 0.88), "Fabric")
			r:seat(0, 1.45, 0)
		end,
	},
}

return items
