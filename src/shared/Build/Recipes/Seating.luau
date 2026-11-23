--!strict
-- Chairs, sofas and other places to sit. Every spot a person can sit on is marked with r:seat.
-- c1 is the main colour (wood or fabric), c2 the second one (a seat pad, cushions or legs).
-- Sizes follow a 5 stud person: seats about 1.7 to 2 up, sofa backs about 3.2, arms about 2.5.

local Recipe = require(script.Parent.Parent.Recipe)
local Colors = require(script.Parent.Parent.Parent.Util.Colors)

local C = Recipe.Colors

type R = Recipe.Recipe

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

-- A cylinder along the X axis of a frame.
local function cylAt(r: R, cf: CFrame, len: number, d: number, color: Color3, mat: string)
	r:add({ shape = "Cylinder", cf = cf, size = Vector3.new(len, d, d), color = color, mat = mat })
end

-- A cushion from (x1, y1, z1) to (x2, y2, z2) with its front and back edges rounded over.
local function cushion(r: R, x1: number, y1: number, z1: number, x2: number, y2: number, z2: number, color: Color3)
	local h = y2 - y1
	local xm, ym = (x1 + x2) / 2, (y1 + y2) / 2
	r:block(x1, y1, z1 + h / 2, x2, y2, z2 - h / 2, color, "Fabric")
	r:cyl(xm, ym, z1 + h / 2, x2 - x1, h, "x", color, "Fabric")
	r:cyl(xm, ym, z2 - h / 2, x2 - x1, h, "x", color, "Fabric")
end

-- A tapered wooden leg: a rod from the frame down to the floor, splayed out a little.
local function leg(r: R, x: number, z: number, top: number, splay: number, d: number, color: Color3)
	local sx = if x < 0 then -1 else 1
	local sz = if z < 0 then -1 else 1
	rod(r, Vector3.new(x, top, z), Vector3.new(x + sx * splay, 0, z + sz * splay), d, color, "Wood")
end

-- A padded sofa or armchair, `n` seats wide: a frame on short wooden legs (c2), rolled arms,
-- leaning back cushions and seat cushions with rounded fronts (c1), and throw pillows.
local function upholstered(r: R, w: number, d: number, n: number)
	local a = 0.62 -- arm width
	local legH = 0.45
	local frame = shade(r.c1, 0.84)
	local zb = -d / 2 + 0.6 -- the front face of the back frame
	local pillow = Colors.mix(r.c1, C.Cream, 0.55)
	-- legs, with a middle pair under a long sofa
	local xs = { -w / 2 + 0.35, w / 2 - 0.35 }
	if n >= 3 then
		table.insert(xs, 0)
	end
	for _, x in xs do
		for _, z in { -d / 2 + 0.35, d / 2 - 0.4 } do
			leg(r, x, z, legH + 0.02, if x == 0 then 0 else 0.05, 0.2, r.c2)
		end
	end
	-- the base under the seat and the back frame with a rolled top
	r:block(-w / 2 + a - 0.02, legH, zb, w / 2 - a + 0.02, 1.12, d / 2 - 0.08, frame, "Fabric")
	r:block(-w / 2, legH, -d / 2, w / 2, 2.85, zb, frame, "Fabric")
	r:cyl(0, 2.85, -d / 2 + 0.3, w, 0.6, "x", frame, "Fabric")
	-- rolled arms with a capped front
	for _, sx in { -1, 1 } do
		local xo, xi = sx * w / 2, sx * (w / 2 - a)
		local xm = sx * (w / 2 - a / 2)
		r:block(math.min(xo, xi), legH, zb, math.max(xo, xi), 2.15, d / 2 - 0.05, frame, "Fabric")
		r:cyl(xm, 2.15, (zb + d / 2 - 0.05) / 2, d / 2 - 0.05 - zb, a, "z", frame, "Fabric")
		r:block(xm - a / 2 + 0.06, legH + 0.1, d / 2 - 0.05, xm + a / 2 - 0.06, 2.1, d / 2, r.c1, "Fabric")
		r:cyl(xm, 2.15, d / 2 - 0.02, 0.06, a - 0.1, "z", r.c1, "Fabric")
	end
	-- seat and back cushions, one per seat, with a gap between them
	local iw = w - 2 * a
	local cw = iw / n
	local zs = zb + 0.48 -- the back edge of the seat cushions
	for i = 1, n do
		local x1 = -iw / 2 + (i - 1) * cw + 0.03
		local x2 = x1 + cw - 0.06
		local xm = (x1 + x2) / 2
		r:block(x1, 1.12, zs, x2, 1.7, d / 2 - 0.29, r.c1, "Fabric")
		r:cyl(xm, 1.41, d / 2 - 0.29, x2 - x1, 0.58, "x", r.c1, "Fabric")
		local back = CFrame.new(xm, 1.12, zb + 0.28) * CFrame.Angles(-0.16, 0, 0)
		r:boxAt(back * CFrame.new(0, 0.82, 0), x2 - x1, 1.64, 0.5, r.c1, "Fabric")
		cylAt(r, back * CFrame.new(0, 1.64, 0), x2 - x1, 0.5, r.c1, "Fabric")
		r:seat(xm, 1.7, (zs + d / 2) / 2)
	end
	-- throw pillows: one by each arm, or a small one in the middle of an armchair
	if n == 1 then
		r:boxAt(CFrame.new(0, 2.15, zb + 0.72) * CFrame.Angles(-0.22, 0, 0), 1.2, 0.7, 0.3, pillow, "Fabric")
	else
		for _, sx in { -1, 1 } do
			local x = sx * (iw / 2 - 0.62)
			r:boxAt(CFrame.new(x, 2.2, zb + 0.75) * CFrame.Angles(-0.25, 0, sx * 0.14), 1.0, 1.0, 0.3, pillow, "Fabric")
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
		id = "chair_wood",
		name = "Wooden chair",
		cat = "seating",
		price = 50,
		place = "floor",
		size = Vector3.new(2, 4.1, 2),
		c1 = "C99A62",
		c2 = "D08A6C",
		tags = { "seat" },
		build = function(r: R)
			local dk = shade(r.c1, 0.86)
			for _, sx in { -1, 1 } do
				local x = sx * 0.76
				-- splayed front legs; the back legs run on up into the back posts
				rod(r, Vector3.new(x, 1.72, 0.7), Vector3.new(sx * 0.82, 0, 0.8), 0.2, dk, "Wood")
				rod(r, Vector3.new(sx * 0.8, 0, -0.86), Vector3.new(x, 1.75, -0.74), 0.22, dk, "Wood")
				rod(r, Vector3.new(x, 1.65, -0.74), Vector3.new(x, 4.02, -0.92), 0.2, dk, "Wood")
				-- side apron and stretcher
				r:block(x - 0.05, 1.42, -0.66, x + 0.05, 1.6, 0.64, dk, "Wood")
				rod(r, Vector3.new(sx * 0.79, 0.55, 0.75), Vector3.new(sx * 0.79, 0.55, -0.81), 0.1, dk, "Wood")
			end
			r:block(-0.7, 1.42, 0.66, 0.7, 1.6, 0.74, dk, "Wood")
			rod(r, Vector3.new(-0.79, 0.42, 0), Vector3.new(0.79, 0.42, 0), 0.1, dk, "Wood")
			-- the seat board with a rounded front edge, and a tied on pad
			r:block(-0.96, 1.6, -0.92, 0.96, 1.82, 0.8, r.c1, "Wood")
			r:cyl(0, 1.71, 0.8, 1.92, 0.22, "x", r.c1, "Wood")
			cushion(r, -0.76, 1.82, -0.74, 0.76, 1.98, 0.78, r.c2)
			-- a bowed top rail, a lower rail and four spindles
			r:boxAt(CFrame.new(0, 3.76, -0.98), 0.8, 0.42, 0.14, r.c1, "Wood")
			for _, sx in { -1, 1 } do
				r:boxAt(
					CFrame.new(sx * 0.55, 3.76, -0.94) * CFrame.Angles(0, -sx * 0.22, 0),
					0.5,
					0.42,
					0.14,
					r.c1,
					"Wood"
				)
			end
			r:block(-0.72, 2.25, -0.86, 0.72, 2.4, -0.74, r.c1, "Wood")
			for _, x in { -0.42, -0.14, 0.14, 0.42 } do
				rod(r, Vector3.new(x, 2.38, -0.8), Vector3.new(x, 3.58, -0.96), 0.09, dk, "Wood")
			end
			r:seat(0, 1.98, 0.05)
		end,
	},
	{
		id = "chair_dining",
		name = "Dining chair",
		cat = "seating",
		price = 80,
		place = "floor",
		size = Vector3.new(2, 4.3, 2),
		c1 = "6E4C34",
		c2 = "E9DCC3",
		tags = { "seat" },
		build = function(r: R)
			for _, sx in { -1, 1 } do
				rod(r, Vector3.new(sx * 0.76, 1.42, 0.72), Vector3.new(sx * 0.8, 0, 0.8), 0.2, r.c1, "Wood")
				rod(r, Vector3.new(sx * 0.8, 0, -0.9), Vector3.new(sx * 0.77, 1.5, -0.76), 0.2, r.c1, "Wood")
				-- the back legs carry on up behind the padded back
				rod(r, Vector3.new(sx * 0.77, 1.4, -0.76), Vector3.new(sx * 0.74, 4.12, -0.93), 0.18, r.c1, "Wood")
				rod(r, Vector3.new(sx * 0.78, 0.5, 0.76), Vector3.new(sx * 0.79, 0.5, -0.84), 0.09, r.c1, "Wood")
			end
			r:block(-0.9, 1.3, -0.86, 0.9, 1.56, 0.86, r.c1, "Wood")
			-- the seat: a padded cushion with a soft rolled front
			r:block(-0.95, 1.56, -0.9, 0.95, 1.96, 0.76, r.c2, "Fabric")
			r:cyl(0, 1.76, 0.76, 1.9, 0.4, "x", r.c2, "Fabric")
			-- a padded back with three buttons, under a wooden top rail
			local back = CFrame.new(0, 2.95, -0.86) * CFrame.Angles(-0.07, 0, 0)
			r:boxAt(back, 1.4, 1.85, 0.26, r.c2, "Fabric")
			cylAt(r, back * CFrame.new(0, 0.92, 0), 1.4, 0.26, r.c2, "Fabric")
			for _, x in { -0.4, 0, 0.4 } do
				r:ball(x, 3.15, -0.71, 0.1, shade(r.c2, 0.78), "Fabric")
			end
			r:boxAt(CFrame.new(0, 4.12, -0.94) * CFrame.Angles(-0.07, 0, 0), 1.66, 0.26, 0.18, r.c1, "Wood")
			r:seat(0, 1.96, 0.1)
		end,
	},
	{
		id = "armchair",
		name = "Armchair",
		cat = "seating",
		price = 140,
		place = "floor",
		size = Vector3.new(3.4, 3.4, 3.2),
		c1 = "D08A6C",
		c2 = "6E4C34",
		tags = { "seat" },
		build = function(r: R)
			upholstered(r, 3.4, 3.2, 1)
		end,
	},
	{
		id = "sofa_two",
		name = "Loveseat",
		cat = "seating",
		price = 200,
		place = "floor",
		size = Vector3.new(5.4, 3.4, 3.2),
		c1 = "8FB39A",
		c2 = "6E4C34",
		tags = { "seat" },
		build = function(r: R)
			upholstered(r, 5.4, 3.2, 2)
		end,
	},
	{
		id = "sofa_three",
		name = "Sofa",
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
		c1 = "B08258",
		c2 = "4A3426",
		tags = { "seat" },
		build = function(r: R)
			-- two leg frames, each a pair of legs with a cleat on top and a rail at the foot
			for _, sx in { -1, 1 } do
				local x = sx * 1.95
				for _, z in { -0.62, 0.62 } do
					r:box(x, 0.82, z, 0.22, 1.64, 0.22, r.c2, "Wood")
				end
				r:block(x - 0.13, 1.45, -0.84, x + 0.13, 1.65, 0.84, r.c2, "Wood")
				r:block(x - 0.12, 0.28, -0.73, x + 0.12, 0.44, 0.73, r.c2, "Wood")
			end
			-- a slatted shelf low down
			for _, z in { -0.48, 0, 0.48 } do
				r:block(-2.08, 0.44, z - 0.19, 2.08, 0.54, z + 0.19, shade(r.c1, 0.9), "Wood")
			end
			-- five seat slats with small gaps between them
			for i = 0, 4 do
				local z = -0.72 + i * 0.36
				r:block(-2.4, 1.65, z - 0.15, 2.4, 1.9, z + 0.15, r.c1, "Wood")
			end
			r:seat(-1.2, 1.9, 0)
			r:seat(1.2, 1.9, 0)
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
		c2 = "D08A6C",
		tags = { "seat" },
		build = function(r: R)
			local dk = shade(r.c1, 0.86)
			for _, sx in { -1, 1 } do
				for _, sz in { -1, 1 } do
					rod(
						r,
						Vector3.new(sx * 0.4, 1.86, sz * 0.4),
						Vector3.new(sx * 0.64, 0, sz * 0.64),
						0.16,
						dk,
						"Wood"
					)
				end
			end
			-- a ring of rungs to rest your feet on
			local k = 0.58
			for _, s in { -1, 1 } do
				rod(r, Vector3.new(-k, 0.62, s * k), Vector3.new(k, 0.62, s * k), 0.08, dk, "Wood")
				rod(r, Vector3.new(s * k, 0.7, -k), Vector3.new(s * k, 0.7, k), 0.08, dk, "Wood")
			end
			-- a round seat with a bevelled underside and a piped cushion
			r:cyl(0, 1.85, 0, 0.1, 1.3, "y", dk, "Wood")
			r:cyl(0, 1.97, 0, 0.16, 1.5, "y", r.c1, "Wood")
			r:cyl(0, 2.065, 0, 0.03, 1.36, "y", shade(r.c2, 0.75), "Fabric")
			r:cyl(0, 2.13, 0, 0.12, 1.3, "y", r.c2, "Fabric")
			r:seat(0, 2.19, 0)
		end,
	},
	{
		id = "beanbag",
		name = "Bean bag",
		cat = "seating",
		price = 70,
		place = "floor",
		size = Vector3.new(2.8, 2.8, 2.8),
		c1 = "D8B062",
		c2 = "F2E8D5",
		tags = { "seat" },
		build = function(r: R)
			-- a soft base, a low lump in front to sit in and a taller one behind
			r:cyl(0, 0.4, 0, 0.8, 2.7, "y", shade(r.c1, 0.92), "Fabric")
			r:cyl(0, 0.8, 0, 0.05, 2.5, "y", shade(r.c1, 0.75), "Fabric")
			r:ball(0, 0.9, 0.22, 2.3, r.c1, "Fabric")
			r:ball(0, 1.55, -0.42, 2.1, shade(r.c1, 1.04), "Fabric")
			-- a sewn on label at the front and a carry loop at the back
			r:block(0.4, 0.3, 1.3, 0.85, 0.6, 1.37, r.c2, "Fabric")
			r:block(-0.25, 2.48, -1.0, 0.25, 2.6, -0.8, shade(r.c1, 0.75), "Fabric")
			r:seat(0, 1.75, 0.3)
		end,
	},
	{
		id = "chair_rocking",
		name = "Rocking chair",
		cat = "seating",
		price = 120,
		place = "floor",
		size = Vector3.new(2.2, 4.5, 3.4),
		c1 = "AD7E55",
		c2 = "C9D8B6",
		tags = { "seat" },
		build = function(r: R)
			local dk = shade(r.c1, 0.82)
			for _, sx in { -1, 1 } do
				local x = sx * 0.9
				local pts = {
					Vector3.new(x, 0.6, -1.62),
					Vector3.new(x, 0.14, -0.6),
					Vector3.new(x, 0.14, 0.6),
					Vector3.new(x, 0.55, 1.6),
				}
				for i = 1, 3 do
					-- stretch each piece a little past its ends so the joints close up
					local a, b = pts[i], pts[i + 1]
					local d = (b - a).Unit * 0.1
					r:beam(if i > 1 then a - d else a, if i < 3 then b + d else b, 0.22, 0.24, dk, "Wood")
				end
				rod(r, Vector3.new(x, 0.2, 0.66), Vector3.new(x, 2.75, 0.7), 0.18, dk, "Wood")
				rod(r, Vector3.new(x, 0.2, -0.66), Vector3.new(x, 1.85, -0.7), 0.18, dk, "Wood")
				-- the back post leans back a little
				rod(r, Vector3.new(x, 1.75, -0.7), Vector3.new(x, 4.35, -1.28), 0.2, r.c1, "Wood")
				-- arm rest with a rounded end
				r:block(x - 0.14, 2.75, -0.95, x + 0.14, 2.92, 0.85, r.c1, "Wood")
				r:cyl(x, 2.835, 0.85, 0.28, 0.17, "y", r.c1, "Wood")
				rod(r, Vector3.new(x, 1.0, 0.68), Vector3.new(x, 1.0, -0.68), 0.08, dk, "Wood")
			end
			r:block(-1.0, 1.75, -0.9, 1.0, 1.95, 0.9, r.c1, "Wood")
			r:cyl(0, 1.85, 0.9, 2.0, 0.2, "x", r.c1, "Wood")
			cushion(r, -0.78, 1.95, -0.72, 0.78, 2.12, 0.84, r.c2)
			r:boxAt(CFrame.new(0, 4.18, -1.24) * CFrame.Angles(-0.22, 0, 0), 2.0, 0.42, 0.18, r.c1, "Wood")
			r:boxAt(CFrame.new(0, 2.35, -0.83) * CFrame.Angles(-0.22, 0, 0), 1.7, 0.18, 0.14, r.c1, "Wood")
			for _, x in { -0.56, -0.28, 0, 0.28, 0.56 } do
				rod(r, Vector3.new(x, 2.3, -0.82), Vector3.new(x, 4.0, -1.2), 0.1, dk, "Wood")
			end
			-- a little pillow tied to the back
			r:boxAt(CFrame.new(0, 2.75, -0.82) * CFrame.Angles(-0.22, 0, 0), 1.2, 0.7, 0.22, r.c2, "Fabric")
			r:seat(0, 2.12, 0.1)
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
		c2 = "8E6440",
		tags = { "seat" },
		build = function(r: R)
			for _, sx in { -1, 1 } do
				for _, z in { -2.1, 2.1 } do
					leg(r, sx * 1.0, z, 0.52, 0.06, 0.2, r.c2)
				end
			end
			r:block(-1.25, 0.5, -2.45, 1.25, 0.95, 2.45, r.c2, "Wood")
			r:block(-1.18, 0.95, -2.4, 1.18, 1.0, 2.4, shade(r.c2, 0.8), "Wood")
			-- the seat cushion, tufted with buttons, and a rounded front
			r:block(-1.15, 1.0, -0.9, 1.15, 1.45, 2.22, r.c1, "Fabric")
			r:cyl(0, 1.225, 2.22, 2.3, 0.45, "x", r.c1, "Fabric")
			for _, x in { -0.5, 0.5 } do
				for _, z in { 0.2, 1.4 } do
					r:ball(x, 1.45, z, 0.1, shade(r.c1, 0.8), "Fabric")
				end
			end
			-- a sloped frame holds the back cushion up, with a bolster on top
			r:ramp(-1.2, 1.0, -2.42, 1.2, 2.7, -0.95, false, r.c2, "Wood")
			r:beam(Vector3.new(0, 1.3, -0.75), Vector3.new(0, 2.95, -2.1), 2.3, 0.5, r.c1, "Fabric")
			r:cyl(0, 3.0, -2.02, 2.1, 0.6, "x", Colors.mix(r.c1, r.c2, 0.25), "Fabric")
			for _, sx in { -1, 1 } do
				r:cyl(sx * 1.06, 3.0, -2.02, 0.04, 0.64, "x", shade(r.c1, 0.8), "Fabric")
			end
			r:seat(0, 1.45, 0)
		end,
	},
}

return items
