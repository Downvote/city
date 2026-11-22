--!strict
-- Tables, desks and nightstands. `surface` is the height of the top, where small things can stand.
-- c1 is the top and body, c2 the legs or a second wood.
-- Heights for a 5 stud person: coffee tables 1.6, dining tables and desks about 3, nightstands 2.4.

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

-- A top from y1 to y2 with a thin bevel strip under its edge.
local function top(r: R, w: number, d: number, y1: number, y2: number, color: Color3, mat: string)
	r:block(-w / 2, y1, -d / 2, w / 2, y2, d / 2, color, mat)
	r:block(-w / 2 + 0.06, y1 - 0.06, -d / 2 + 0.06, w / 2 - 0.06, y1, d / 2 - 0.06, shade(color, 0.82), mat)
end

-- A splayed mid century leg with a brass foot cap.
local function splayLeg(r: R, x: number, z: number, y: number, splay: number, d: number, color: Color3)
	local sx = if x < 0 then -1 else 1
	local sz = if z < 0 then -1 else 1
	local foot = Vector3.new(x + sx * splay, 0, z + sz * splay)
	local head = Vector3.new(x, y, z)
	rod(r, head, foot, d, color, "Wood")
	rod(r, foot + (head - foot).Unit * 0.18, foot, d + 0.03, C.Gold, "Metal")
end

-- A drawer front on the +z face at z, with a bar pull (or a round knob when it is small).
local function drawer(r: R, x1: number, y1: number, x2: number, y2: number, z: number, color: Color3)
	r:block(x1, y1, z, x2, y2, z + 0.06, color, "Wood")
	local xm, ym = (x1 + x2) / 2, (y1 + y2) / 2
	if x2 - x1 > 1.1 then
		local hw = math.min(0.4, (x2 - x1) * 0.22)
		r:block(xm - hw, ym - 0.04, z + 0.12, xm + hw, ym + 0.04, z + 0.16, C.Gold, "Metal")
		for _, sx in { -1, 1 } do
			r:block(
				xm + sx * hw - 0.04 * sx - 0.03,
				ym - 0.03,
				z + 0.06,
				xm + sx * hw - 0.04 * sx + 0.03,
				ym + 0.03,
				z + 0.12,
				C.Gold,
				"Metal"
			)
		end
	else
		r:ball(xm, ym, z + 0.11, 0.16, C.Gold, "Metal")
	end
end

-- A dining table: a top with a bevelled edge, an open apron of four boards, and turned legs.
local function diningTable(r: R, w: number, d: number, mat: string)
	local h = 3.1
	top(r, w, d, h - 0.2, h, r.c1, mat)
	local ax, az = w / 2 - 0.3, d / 2 - 0.3
	local apron = shade(r.c2, 0.92)
	for _, s in { -1, 1 } do
		r:block(-ax, h - 0.62, s * az - 0.06, ax, h - 0.26, s * az + 0.06, apron, "Wood")
		r:block(s * ax - 0.06, h - 0.62, -az, s * ax + 0.06, h - 0.26, az, apron, "Wood")
	end
	local lx, lz = w / 2 - 0.36, d / 2 - 0.36
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			local x, z = sx * lx, sz * lz
			r:box(x, h - 0.48, z, 0.32, 0.44, 0.32, r.c2, "Wood")
			r:cyl(x, 1.5, z, 2.2, 0.26, "y", r.c2, "Wood")
			r:cyl(x, 2.05, z, 0.16, 0.34, "y", shade(r.c2, 0.9), "Wood")
			r:cyl(x, 0.22, z, 0.44, 0.3, "y", shade(r.c2, 0.9), "Wood")
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
		id = "table_coffee",
		name = "Coffee table",
		cat = "tables",
		price = 80,
		place = "floor",
		size = Vector3.new(4, 1.6, 2.4),
		surface = 1.6,
		c1 = "C99A62",
		c2 = "6B4423",
		tags = { "table" },
		build = function(r: R)
			top(r, 4, 2.4, 1.42, 1.6, r.c1, "Wood")
			-- a shallow drawer box under the top
			r:block(-1.62, 1.14, -0.86, 1.62, 1.36, 0.86, shade(r.c1, 0.86), "Wood")
			r:block(-0.8, 1.17, 0.86, 0.8, 1.33, 0.9, shade(r.c1, 1.06), "Wood")
			r:block(-0.3, 1.22, 0.9, 0.3, 1.28, 0.95, C.Gold, "Metal")
			for _, sx in { -1, 1 } do
				for _, sz in { -1, 1 } do
					splayLeg(r, sx * 1.55, sz * 0.78, 1.36, 0.16, 0.2, r.c2)
				end
			end
			-- a shelf low down with a couple of magazines
			r:block(-1.6, 0.4, -0.78, 1.6, 0.5, 0.78, r.c2, "Wood")
			r:boxAt(CFrame.new(0.7, 0.535, -0.1) * CFrame.Angles(0, 0.12, 0), 0.95, 0.07, 0.7, C.Paper, "SmoothPlastic")
			r:boxAt(
				CFrame.new(0.75, 0.595, -0.08) * CFrame.Angles(0, -0.1, 0),
				0.85,
				0.05,
				0.62,
				C.Blue,
				"SmoothPlastic"
			)
		end,
	},
	{
		id = "table_dining_small",
		name = "Small dining table",
		cat = "tables",
		price = 120,
		place = "floor",
		size = Vector3.new(3.6, 3.1, 3.6),
		surface = 3.1,
		c1 = "C99A62",
		c2 = "A8743F",
		tags = { "table" },
		build = function(r: R)
			diningTable(r, 3.6, 3.6, "Wood")
		end,
	},
	{
		id = "table_dining_long",
		name = "Long dining table",
		cat = "tables",
		price = 200,
		place = "floor",
		size = Vector3.new(7.2, 3.15, 3.6),
		surface = 3.1,
		c1 = "8A5A2E",
		c2 = "6B4423",
		tags = { "table" },
		build = function(r: R)
			diningTable(r, 7.2, 3.6, "WoodPlanks")
			-- a stretcher between the end legs, and a cloth runner down the middle
			r:block(-3.0, 0.75, -0.08, 3.0, 0.95, 0.08, r.c2, "Wood")
			for _, sx in { -1, 1 } do
				r:block(sx * 3.24 - 0.08, 0.7, -1.4, sx * 3.24 + 0.08, 0.9, 1.4, r.c2, "Wood")
			end
			r:block(-3.6, 3.1, -0.55, 3.6, 3.13, 0.55, C.Cream, "Fabric")
			for _, sx in { -1, 1 } do
				r:block(sx * 3.62 - 0.03, 2.65, -0.55, sx * 3.62 + 0.03, 3.13, 0.55, C.Cream, "Fabric")
			end
		end,
	},
	{
		id = "table_round",
		name = "Round table",
		cat = "tables",
		price = 140,
		place = "floor",
		size = Vector3.new(3.6, 3.1, 3.6),
		surface = 3.1,
		c1 = "F7F3EA",
		c2 = "A8743F",
		tags = { "table" },
		build = function(r: R)
			r:cyl(0, 3.0, 0, 0.2, 3.6, "y", r.c1, "Wood")
			r:cyl(0, 2.87, 0, 0.06, 3.48, "y", shade(r.c1, 0.82), "Wood")
			r:cyl(0, 2.74, 0, 0.2, 2.2, "y", r.c2, "Wood")
			-- a turned pedestal
			r:cyl(0, 1.6, 0, 2.2, 0.5, "y", r.c2, "Wood")
			r:cyl(0, 2.4, 0, 0.18, 0.7, "y", shade(r.c2, 0.9), "Wood")
			r:cyl(0, 0.85, 0, 0.5, 0.8, "y", r.c2, "Wood")
			r:cyl(0, 1.15, 0, 0.12, 0.66, "y", shade(r.c2, 0.9), "Wood")
			r:cyl(0, 0.42, 0, 0.36, 1.0, "y", shade(r.c2, 0.9), "Wood")
			-- four curved feet
			for i = 0, 3 do
				local a = i * math.pi / 2 + math.pi / 4
				local dx, dz = math.cos(a), math.sin(a)
				r:beam(
					Vector3.new(dx * 0.3, 0.5, dz * 0.3),
					Vector3.new(dx * 1.0, 0.18, dz * 1.0),
					0.24,
					0.26,
					r.c2,
					"Wood"
				)
				r:beam(
					Vector3.new(dx * 0.95, 0.18, dz * 0.95),
					Vector3.new(dx * 1.32, 0.1, dz * 1.32),
					0.24,
					0.2,
					r.c2,
					"Wood"
				)
				r:cyl(dx * 1.32, 0.06, dz * 1.32, 0.12, 0.26, "y", shade(r.c2, 0.8), "Wood")
			end
		end,
	},
	{
		id = "table_side",
		name = "Side table",
		cat = "tables",
		price = 60,
		place = "floor",
		size = Vector3.new(1.8, 2.4, 1.8),
		surface = 2.4,
		c1 = "F7F3EA",
		c2 = "8FB39A",
		tags = { "table" },
		build = function(r: R)
			top(r, 1.8, 1.8, 2.24, 2.4, r.c1, "Wood")
			r:block(-0.72, 1.7, -0.72, 0.72, 2.18, 0.72, shade(r.c1, 0.93), "Wood")
			drawer(r, -0.62, 1.76, 0.62, 2.12, 0.72, r.c2)
			for _, sx in { -1, 1 } do
				for _, sz in { -1, 1 } do
					splayLeg(r, sx * 0.62, sz * 0.62, 1.72, 0.1, 0.16, shade(r.c1, 0.93))
				end
			end
			r:block(-0.62, 0.5, -0.62, 0.62, 0.6, 0.62, shade(r.c1, 0.93), "Wood")
		end,
	},
	{
		id = "nightstand",
		name = "Nightstand",
		cat = "tables",
		price = 70,
		place = "floor",
		size = Vector3.new(2, 2.4, 1.8),
		surface = 2.4,
		c1 = "F7F3EA",
		c2 = "C99A62",
		tags = { "table", "storage" },
		build = function(r: R)
			for _, sx in { -1, 1 } do
				for _, sz in { -1, 1 } do
					splayLeg(r, sx * 0.72, sz * 0.62, 0.42, 0.06, 0.16, r.c2)
				end
			end
			r:block(-0.92, 0.4, -0.82, 0.92, 2.24, 0.82, r.c1, "Wood")
			top(r, 2, 1.8, 2.24, 2.4, r.c2, "Wood")
			-- two drawers with a gap between them
			local front = shade(r.c1, 1.04)
			drawer(r, -0.82, 0.5, 0.82, 1.3, 0.82, front)
			drawer(r, -0.82, 1.38, 0.82, 2.16, 0.82, front)
		end,
	},
	{
		id = "desk",
		name = "Desk",
		cat = "tables",
		price = 150,
		place = "floor",
		size = Vector3.new(4.6, 3, 2.4),
		surface = 3,
		c1 = "C99A62",
		c2 = "F7F3EA",
		tags = { "desk", "table" },
		build = function(r: R)
			top(r, 4.6, 2.4, 2.82, 3.0, r.c1, "Wood")
			-- a drawer pedestal on the right, standing on a recessed plinth
			r:block(0.92, 0, -1.0, 2.12, 0.18, 0.95, shade(r.c2, 0.7), "Wood")
			r:block(0.88, 0.18, -1.1, 2.18, 2.76, 1.08, r.c2, "Wood")
			local front = shade(r.c2, 0.95)
			drawer(r, 0.98, 0.28, 2.08, 1.1, 1.08, front)
			drawer(r, 0.98, 1.18, 2.08, 1.94, 1.08, front)
			drawer(r, 0.98, 2.02, 2.08, 2.7, 1.08, front)
			-- a slim pencil drawer in the middle, and legs on the left
			r:block(-1.85, 2.56, -1.0, 0.88, 2.76, 1.0, shade(r.c2, 0.92), "Wood")
			r:block(-1.0, 2.6, 1.0, 0.4, 2.73, 1.04, front, "Wood")
			r:block(-0.45, 2.64, 1.04, -0.15, 2.69, 1.08, C.Gold, "Metal")
			for _, z in { -0.92, 0.92 } do
				splayLeg(r, -2.0, z, 2.78, 0.1, 0.22, r.c2)
			end
			r:block(-1.95, 1.3, -1.06, 0.88, 2.56, -0.98, shade(r.c2, 0.92), "Wood")
		end,
	},
	{
		id = "workbench",
		name = "Work bench",
		cat = "tables",
		price = 180,
		place = "floor",
		size = Vector3.new(5, 5.2, 2.4),
		surface = 3.2,
		c1 = "C99A62",
		c2 = "6B4423",
		tags = { "table" },
		build = function(r: R)
			-- a butcher block top made of strips
			for i = 0, 5 do
				local z = -1.2 + i * 0.4
				r:block(-2.5, 2.85, z, 2.5, 3.2, z + 0.4, if i % 2 == 0 then r.c1 else shade(r.c1, 0.92), "Wood")
			end
			for _, sx in { -1, 1 } do
				for _, sz in { -1, 1 } do
					r:box(sx * 2.18, 1.42, sz * 0.92, 0.34, 2.85, 0.34, r.c2, "Wood")
				end
				r:block(sx * 2.18 - 0.1, 0.35, -0.8, sx * 2.18 + 0.1, 0.55, 0.8, r.c2, "Wood")
			end
			-- a slatted shelf with a toolbox, and a drawer under the top
			for _, z in { -0.6, 0, 0.6 } do
				r:block(-2.01, 0.55, z - 0.26, 2.01, 0.65, z + 0.26, shade(r.c1, 0.9), "Wood")
			end
			r:block(-1.7, 0.65, -0.45, -0.5, 1.25, 0.4, C.Red, "Metal")
			r:block(-1.4, 1.25, -0.04, -0.8, 1.45, 0.04, C.DarkMetal, "Metal")
			r:block(-1.0, 2.4, 1.02, 1.0, 2.8, 1.08, shade(r.c1, 0.86), "Wood")
			r:block(-0.3, 2.56, 1.08, 0.3, 2.64, 1.14, C.DarkMetal, "Metal")
			r:block(-2.01, 2.35, -0.95, 2.01, 2.85, 1.02, shade(r.c2, 0.85), "Wood")
			-- a framed pegboard with tools hung on it
			r:block(-2.4, 3.2, -1.2, 2.4, 5.2, -1.08, r.c2, "Wood")
			r:block(-2.25, 3.35, -1.08, 2.25, 5.05, -1.04, Color3.fromRGB(214, 190, 150), "Wood")
			r:block(-1.65, 3.75, -1.04, -1.53, 4.75, -0.96, C.Bark, "Wood")
			r:block(-1.88, 4.6, -1.04, -1.3, 4.84, -0.92, C.DarkMetal, "Metal")
			r:block(-0.9, 3.7, -1.04, 0.4, 4.35, -1.0, C.Metal, "Metal")
			r:block(0.4, 3.75, -1.04, 0.8, 4.3, -0.94, C.Red, "SmoothPlastic")
			r:block(1.3, 3.6, -1.04, 1.4, 4.45, -0.96, C.Metal, "Metal")
			r:cyl(1.35, 4.62, -1.0, 0.08, 0.36, "z", C.Metal, "Metal")
			r:block(1.8, 3.9, -1.04, 1.92, 4.7, -0.96, C.Yellow, "SmoothPlastic")
			r:block(1.82, 3.55, -1.04, 1.9, 3.9, -0.98, C.Metal, "Metal")
			-- a vice on the front corner
			r:block(1.6, 3.2, 0.62, 2.2, 3.62, 1.0, C.DarkMetal, "Metal")
			r:block(1.62, 3.25, 1.0, 2.18, 3.6, 1.12, C.Blue, "Metal")
			r:cyl(1.9, 3.38, 1.18, 0.14, 0.1, "z", C.Metal, "Metal")
			r:cyl(1.9, 3.38, 1.24, 0.06, 0.6, "x", C.Metal, "Metal")
		end,
	},
}

return items
