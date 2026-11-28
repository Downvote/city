--!strict
-- The seaside look (Catalog.Styles): things for a beach garden, a harbour corner or a room by
-- the sea. Loungers and a hooded wicker chair, a hammock, a windbreak, a changing hut and a
-- shower, lobster pots, a drying net, an anchor in its stones, lamps after lighthouses and
-- floats, shells in a bowl. c1 is the main colour and c2 the second, as everywhere.

local Recipe = require(script.Parent.Parent.Recipe)
local Colors = require(script.Parent.Parent.Parent.Util.Colors)

local C = Recipe.Colors

type R = Recipe.Recipe

local STYLE = "seaside"

local function shade(c: Color3, k: number): Color3
	return Colors.shade(c, k)
end

local function V(x: number, y: number, z: number): Vector3
	return Vector3.new(x, y, z)
end

-- A water surface: see-through enough to show what is under it, and you walk into it.
local function water(p: Recipe.Prim, transp: number?): Recipe.Prim
	p.transp = transp or 0.2
	p.collide = false
	return p
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
		mat = mat or r.mat or "Metal",
	})
end

-- A curved runner of straight pieces through the given points, joints closed up.
local function rail(r: R, pts: { Vector3 }, w: number, h: number, color: Color3, mat: string)
	for i = 1, #pts - 1 do
		local a, b = pts[i], pts[i + 1]
		local d = (b - a).Unit * 0.04
		r:beam(if i > 1 then a - d else a, if i < #pts - 1 then b + d else b, w, h, color, mat)
	end
end

-- A ring of n straight pieces round `c` in the plane of u and v (unit vectors), `rad` out, each
-- piece `thick` across; tone(i) colours piece i. A coil of rope, a lifebuoy, a lip.
local function ring(
	r: R,
	c: Vector3,
	u: Vector3,
	v: Vector3,
	rad: number,
	thick: number,
	n: number,
	tone: (i: number) -> Color3,
	mat: string
)
	for i = 0, n - 1 do
		local a1, a2 = i / n * math.pi * 2, (i + 1) / n * math.pi * 2
		local p1 = c + (u * math.cos(a1) + v * math.sin(a1)) * rad
		local p2 = c + (u * math.cos(a2) + v * math.sin(a2)) * rad
		local d = (p2 - p1).Unit * thick * 0.3
		r:beam(p1 - d, p2 + d, thick, thick, tone(i), mat)
	end
end

local function flat(color: Color3): (number) -> Color3
	return function(_i: number): Color3
		return color
	end
end

local X, Y, Z = Vector3.xAxis, Vector3.yAxis, Vector3.zAxis

local WOOD = Color3.fromRGB(142, 112, 82)
local ROPE = Color3.fromRGB(216, 200, 166)
local SAND = Color3.fromRGB(230, 206, 156)
local CORAL = Color3.fromRGB(226, 140, 120)
local SEA = Color3.fromRGB(92, 150, 176)

-- A herring gull on q (a piece) standing at (x, y, z), looking along +x or -x
-- (dir). Its beak is a plain box, so it can start the piece.
local function gull(q: R, x: number, y: number, z: number, dir: number)
	q:box(x + dir * 0.36, y + 0.47, z, 0.14, 0.05, 0.06, C.Yellow, "Plaster")
	q:lump(CFrame.new(x, y + 0.28, z), 0.56, 0.3, 0.3, C.White, "Plaster")
	q:ball(x + dir * 0.22, y + 0.47, z, 0.24, C.White, "Plaster")
	for _, sz in { -1, 1 } do
		q:lump(
			CFrame.new(x - dir * 0.05, y + 0.33, z + sz * 0.14) * CFrame.Angles(sz * 0.3, 0, 0),
			0.5,
			0.1,
			0.16,
			Color3.fromRGB(150, 156, 166),
			"Plaster"
		)
		q:ball(x + dir * 0.29, y + 0.5, z + sz * 0.08, 0.05, C.Black, "Plaster")
		q:box(x + dir * 0.02, y + 0.06, z + sz * 0.07, 0.03, 0.12, 0.03, Color3.fromRGB(222, 170, 120), "Plaster")
	end
	q:lump(
		CFrame.new(x - dir * 0.34, y + 0.33, z) * CFrame.Angles(0, 0, dir * 0.3),
		0.24,
		0.06,
		0.16,
		Color3.fromRGB(60, 60, 66),
		"Plaster"
	)
end

-- One catalog entry (Build/Catalog explains the fields).
type Item = {
	id: string,
	name: string,
	cat: string,
	style: string,
	price: number,
	place: string,
	size: Vector3,
	c1: string,
	c2: string?,
	tags: { string }?,
	surface: number?,
	build: (r: R) -> (),
	gives: string?, -- holding E gives the player something (Data/Items.Sources)
}

local items: { Item } = {
	-- Seats and a hammock ---------------------------------------------------------------------------
	{
		id = "sea_lounger",
		name = "Teak lounger",
		cat = "seating",
		style = STYLE,
		price = 110,
		place = "floor",
		size = Vector3.new(2.4, 2.9, 6.4),
		c1 = "B08A64",
		c2 = "7FA8C0",
		tags = { "seat" },
		build = function(r: R)
			-- a slatted wooden lounger (c1) with its back propped up, two wheels at the head
			-- end, a cushion (c2) along it with a pillow, and a towel rolled at the foot
			local dk = shade(r.c1, 0.86)
			for _, sx in { -1, 1 } do
				r:block(sx * 1.0 - 0.07, 0.88, -3.0, sx * 1.0 + 0.07, 1.04, 3.0, dk, "Wood")
				for _, z in { -2.6, 2.7 } do
					r:block(sx * 0.93 - 0.07, 0, z - 0.08, sx * 0.93 + 0.07, 0.88, z + 0.08, dk, "Wood")
				end
				r:cyl(sx * 1.1, 0.22, -2.6, 0.12, 0.44, "x", C.Black, "Rubber")
				r:cyl(sx * 1.18, 0.22, -2.6, 0.04, 0.16, "x", C.Metal, "Metal")
			end
			for _, z in { -2.6, 0, 2.7 } do
				r:block(-0.93, 0.88, z - 0.06, 0.93, 1.0, z + 0.06, dk, "Wood")
			end
			local back = CFrame.new(0, 1.07, -0.62) * CFrame.Angles(0.7, 0, 0)
			r:piece(function(q: R)
				for k = 0, 11 do
					local z = -0.45 + k * 0.3
					q:block(
						-0.95,
						1.04,
						z - 0.12,
						0.95,
						1.1,
						z + 0.12,
						if k % 2 == 0 then r.c1 else shade(r.c1, 1.05),
						"Wood"
					)
				end
				for k = 0, 7 do
					q:boxAt(back * CFrame.new(0, 0.03, -0.15 - k * 0.3), 1.9, 0.06, 0.24, r.c1, "Wood")
				end
				for _, sx in { -1, 1 } do
					q:boxAt(back * CFrame.new(sx * 0.92, -0.05, -1.2), 0.12, 0.1, 2.4, dk, "Wood")
				end
			end, true)
			for _, sx in { -1, 1 } do
				r:beam(
					V(sx * 0.86, 1.0, -2.0),
					(back * CFrame.new(sx * 0.86, -0.1, -1.75)).Position,
					0.08,
					0.1,
					dk,
					"Wood"
				)
			end
			-- the cushion, its piping, a pillow and the towel
			r:block(-0.9, 1.1, -0.55, 0.9, 1.3, 2.95, r.c2, "Fabric")
			for _, z in { 0.4, 1.5, 2.5 } do
				r:block(-0.93, 1.14, z - 0.04, 0.93, 1.33, z + 0.04, shade(r.c2, 0.85), "Fabric")
			end
			r:boxAt(back * CFrame.new(0, 0.16, -1.15), 1.8, 0.2, 2.2, r.c2, "Fabric")
			r:lump(back * CFrame.new(0, 0.38, -1.9), 1.2, 0.3, 0.62, C.White, "Fabric")
			r:cyl(0, 1.48, 2.55, 1.2, 0.36, "x", CORAL, "Fabric")
			for _, x in { -0.35, 0.35 } do
				r:cyl(x, 1.48, 2.55, 0.1, 0.42, "x", C.White, "Fabric")
			end
			r:seat(0, 1.3, 0.8)
		end,
	},
	{
		id = "sea_basket_chair",
		name = "Hooded beach chair",
		cat = "seating",
		style = STYLE,
		price = 240,
		place = "ground",
		size = Vector3.new(4.2, 5, 3.4),
		c1 = "E6D7B8",
		c2 = "6F9EC0",
		tags = { "seat" },
		build = function(r: R)
			-- a two seater wicker beach chair (c1) with a hood against the wind: a woven chest
			-- to sit on, sides and a back that rise into the hood, striped cushions (c2 and
			-- white) and two footrests pulled out at the front
			local dk = shade(r.c1, 0.86)
			for _, sx in { -1, 1 } do
				for _, sz in { -1, 1 } do
					r:block(
						sx * 1.7 - 0.12,
						0,
						sz * 0.95 - 0.12,
						sx * 1.7 + 0.12,
						0.1,
						sz * 0.95 + 0.12,
						C.Bark,
						"Wood"
					)
				end
			end
			r:block(-1.85, 0.1, -1.0, 1.85, 1.5, 1.1, r.c1, "Fabric")
			r:piece(function(q: R)
				for k = 0, 5 do
					local y = 0.26 + k * 0.22
					q:block(-1.85, y - 0.05, 1.1, 1.85, y + 0.05, 1.14, dk, "Fabric")
					for _, sx in { -1, 1 } do
						q:block(sx * 1.85, y - 0.05, -1.0, sx * 1.89, y + 0.05, 1.1, dk, "Fabric")
					end
				end
			end)
			-- the sides: an arm at the front, rising at the back into the hood
			for _, sx in { -1, 1 } do
				r:block(sx * 1.65, 1.5, -1.0, sx * 1.85, 2.45, 1.1, r.c1, "Fabric")
				r:quad(
					V(sx * 1.75, 2.45, -1.0),
					V(sx * 1.75, 2.45, 0.4),
					V(sx * 1.75, 4.6, -0.2),
					V(sx * 1.75, 4.6, -1.0),
					0.2,
					r.c1,
					"Fabric"
				)
				r:block(sx * 1.6, 2.45, -0.35, sx * 1.92, 2.55, 1.16, C.Bark, "Wood")
			end
			r:block(-1.85, 1.5, -1.0, 1.85, 4.6, -0.8, r.c1, "Fabric")
			r:block(-1.85, 4.6, -1.0, 1.85, 4.78, -0.15, r.c1, "Fabric")
			r:boxAt(CFrame.new(0, 4.6, -0.1) * CFrame.Angles(-0.5, 0, 0), 3.7, 0.12, 0.42, dk, "Fabric")
			r:cyl(0, 4.8, -0.6, 3.8, 0.26, "x", dk, "Fabric")
			-- woven bands round the hood
			r:piece(function(q: R)
				for k = 0, 3 do
					local y = 2.8 + k * 0.45
					q:block(-1.85, y - 0.05, -1.04, 1.85, y + 0.05, -1.0, dk, "Fabric")
				end
			end)
			-- striped cushions: the seat and the back
			for i = 0, 5 do
				local x1, x2 = -1.62 + i * 0.54, -1.62 + (i + 1) * 0.54
				local col = if i % 2 == 0 then r.c2 else C.White
				r:block(x1, 1.5, -0.78, x2, 1.74, 1.05, col, "Fabric")
				r:block(x1, 1.74, -0.8, x2, 3.9, -0.6, col, "Fabric")
			end
			r:block(-1.6, 0.35, 1.1, -0.2, 0.47, 1.62, dk, "Fabric")
			r:block(0.2, 0.35, 1.1, 1.6, 0.47, 1.62, dk, "Fabric")
			r:seat(-0.85, 1.74, 0.2)
			r:seat(0.85, 1.74, 0.2)
		end,
	},
	{
		id = "sea_driftwood_bench",
		name = "Driftwood bench",
		cat = "seating",
		style = STYLE,
		price = 90,
		place = "ground",
		size = Vector3.new(5, 2.8, 1.8),
		c1 = "B8AE9C",
		c2 = "8E8270",
		tags = { "seat" },
		build = function(r: R)
			-- two long boards of silvered driftwood (c1) on crooked branch legs (c2), a bent
			-- branch for a back on three short uprights, and a starfish left on the end
			r:block(-2.3, 1.36, -0.48, 2.18, 1.6, -0.01, r.c1, "Wood")
			r:block(-2.2, 1.37, 0.01, 2.34, 1.6, 0.46, shade(r.c1, 1.05), "Wood")
			for _, sx in { -1, 1 } do
				rail(
					r,
					{ V(sx * 1.55, 0, 0.5), V(sx * 1.78, 0.7, 0.28), V(sx * 1.7, 1.37, 0.12) },
					0.18,
					0.18,
					r.c2,
					"Wood"
				)
				rail(
					r,
					{ V(sx * 2.05, 0, -0.5), V(sx * 1.82, 0.75, -0.26), V(sx * 1.86, 1.37, -0.2) },
					0.16,
					0.16,
					r.c2,
					"Wood"
				)
				r:beam(V(sx * 1.62, 0.35, 0.42), V(sx * 1.98, 0.95, -0.36), 0.1, 0.1, shade(r.c2, 1.1), "Wood")
				r:lump(CFrame.new(sx * 1.55, 0.06, 0.52) * CFrame.Angles(0, sx, 0), 0.34, 0.14, 0.26, r.c2, "Wood")
				r:lump(CFrame.new(sx * 2.05, 0.06, -0.5) * CFrame.Angles(0, -sx, 0), 0.3, 0.12, 0.26, r.c2, "Wood")
			end
			rail(r, { V(0.25, 0, 0.32), V(0.05, 0.7, 0.05), V(0.1, 1.37, -0.05) }, 0.17, 0.17, r.c2, "Wood")
			for _, x in { -1.9, 0.1, 1.95 } do
				r:beam(V(x, 1.6, -0.38), V(x + 0.1, 2.32, -0.55), 0.12, 0.12, r.c2, "Wood")
			end
			rail(r, {
				V(-2.4, 2.22, -0.55),
				V(-1.2, 2.42, -0.6),
				V(0.0, 2.36, -0.57),
				V(1.3, 2.48, -0.62),
				V(2.4, 2.28, -0.55),
			}, 0.2, 0.2, shade(r.c1, 0.92), "Wood")
			r:beam(V(-0.6, 2.4, -0.59), V(-0.4, 2.7, -0.62), 0.07, 0.07, shade(r.c1, 0.92), "Wood")
			r:beam(V(1.6, 2.44, -0.6), V(1.85, 2.66, -0.6), 0.06, 0.06, shade(r.c1, 0.92), "Wood")
			-- knots in the boards' front edge
			for _, x in { -1.4, 0.6, 1.7 } do
				r:lump(CFrame.new(x, 1.48, 0.46), 0.18, 0.12, 0.08, shade(r.c1, 0.75), "Wood")
			end
			r:piece(function(q: R)
				q:box(1.95, 1.64, 0.22, 0.09, 0.04, 0.09, CORAL, "Marble")
				for k = 0, 4 do
					local a = k / 5 * math.pi * 2 + 0.3
					q:beam(
						V(1.95, 1.64, 0.22),
						V(1.95 + math.cos(a) * 0.24, 1.64, 0.22 + math.sin(a) * 0.24),
						0.07,
						0.04,
						CORAL,
						"Marble"
					)
				end
			end, nil, "Marble")
			r:seat(-1.1, 1.6, 0)
			r:seat(1.1, 1.6, 0)
		end,
	},
	{
		id = "sea_hammock",
		name = "Rope hammock",
		cat = "beds",
		style = STYLE,
		price = 160,
		place = "floor",
		size = Vector3.new(9, 4, 2.2),
		c1 = "EADFC8",
		c2 = "7FA8C0",
		tags = { "bed" },
		build = function(r: R)
			-- a rope hammock (c1) slung between two timber posts, held open by wooden spreader
			-- bars and sagging in the middle, a pillow (c2) at one end
			for _, sx in { -1, 1 } do
				local x = sx * 4.2
				r:block(x - 0.16, 0, -0.16, x + 0.16, 3.8, 0.16, WOOD, "Wood")
				r:block(x - 0.22, 3.8, -0.22, x + 0.22, 3.9, 0.22, shade(WOOD, 0.85), "Wood")
				r:block(x - 0.3, 0, -0.9, x + 0.3, 0.2, 0.9, shade(WOOD, 0.85), "Wood")
				for _, sz in { -1, 1 } do
					r:beam(V(x, 0.2, sz * 0.75), V(x, 1.3, sz * 0.16), 0.14, 0.14, shade(WOOD, 0.92), "Wood")
				end
				r:block(x - sx * 0.26, 3.2, -0.05, x - sx * 0.16, 3.3, 0.05, C.DarkMetal, "Metal")
				r:cyl(sx * 2.9, 2.4, 0, 1.6, 0.12, "z", shade(WOOD, 1.15), "Wood")
				for _, z in { -0.7, -0.35, 0, 0.35, 0.7 } do
					rod(r, V(x - sx * 0.26, 3.25, 0), V(sx * 2.95, 2.43, z), 0.04, r.c1, "Fabric")
				end
			end
			-- the bed of the hammock sags between the bars
			local function sag(x: number): number
				return 1.45 + 0.9 * (x / 2.9) ^ 2
			end
			local n = 8
			for i = 0, n - 1 do
				local x1, x2 = -2.9 + i * 5.8 / n, -2.9 + (i + 1) * 5.8 / n
				local d = (V(x2, sag(x2), 0) - V(x1, sag(x1), 0)).Unit * 0.03
				r:beam(V(x1, sag(x1), 0) - d, V(x2, sag(x2), 0) + d, 1.4, 0.06, r.c1, "Fabric")
			end
			r:piece(function(q: R)
				q:box(0, 1.45, 0, 0.1, 0.04, 0.1, shade(r.c1, 0.85), "Fabric")
				for _, z in { -0.68, 0, 0.68 } do
					for i = 0, n - 1 do
						local x1, x2 = -2.9 + i * 5.8 / n, -2.9 + (i + 1) * 5.8 / n
						q:beam(
							V(x1, sag(x1) + 0.05, z),
							V(x2, sag(x2) + 0.05, z),
							0.04,
							0.04,
							shade(r.c1, 0.85),
							"Fabric"
						)
					end
				end
			end)
			r:lump(CFrame.new(-2.0, sag(-2.0) + 0.2, 0) * CFrame.Angles(0, 0, -0.3), 0.7, 0.3, 1.0, r.c2, "Fabric")
			r:sleep(0, 1.48, 0, 90)
		end,
	},

	-- Tables and kitchen ------------------------------------------------------------------------------
	{
		id = "sea_parasol_table",
		name = "Parasol table",
		cat = "tables",
		style = STYLE,
		price = 180,
		place = "floor",
		size = Vector3.new(5.6, 7, 5.6),
		surface = 2.7,
		c1 = "C8A882",
		c2 = "D98C7A",
		tags = { "table" },
		build = function(r: R)
			-- a round slatted table (c1) on four legs with a parasol through the middle: a
			-- square canopy in c2 and white with a scalloped edge, on ribs, and a jug of
			-- lemonade with two glasses
			local dk = shade(r.c1, 0.85)
			r:piece(function(q: R)
				for k = 0, 6 do
					local z = -1.08 + k * 0.36
					local half = math.sqrt(1.3 ^ 2 - z ^ 2) - 0.05
					q:block(
						-half,
						2.6,
						z - 0.16,
						half,
						2.7,
						z + 0.16,
						if k % 2 == 0 then r.c1 else shade(r.c1, 1.05),
						"Wood"
					)
				end
			end, true)
			r:piece(function(q: R)
				for _, s in { -1, 1 } do
					q:block(-0.8, 2.45, s * 0.72, 0.8, 2.6, s * 0.8, dk, "Wood")
					q:block(s * 0.72, 2.45, -0.72, s * 0.8, 2.6, 0.72, dk, "Wood")
				end
				for _, sx in { -1, 1 } do
					for _, sz in { -1, 1 } do
						q:block(
							sx * 0.68 - 0.07,
							0,
							sz * 0.68 - 0.07,
							sx * 0.68 + 0.07,
							2.45,
							sz * 0.68 + 0.07,
							dk,
							"Wood"
						)
					end
				end
			end, true)
			for _, s in { -1, 1 } do
				r:beam(V(-0.68, 0.6, -s * 0.68), V(0.68, 0.6, s * 0.68), 0.1, 0.1, dk, "Wood")
			end
			r:cyl(0, 0.08, 0, 0.16, 0.7, "y", C.DarkMetal, "Metal")
			r:cyl(0, 3.45, 0, 6.7, 0.12, "y", C.White, "Metal")
			-- the canopy: four faces, each in two colours, from the corners up to the top
			local apex = V(0, 6.55, 0)
			local corners = { V(-2.5, 5.55, 2.5), V(2.5, 5.55, 2.5), V(2.5, 5.55, -2.5), V(-2.5, 5.55, -2.5) }
			for i = 1, 4 do
				local a, b = corners[i], corners[i % 4 + 1]
				local m = (a + b) / 2
				r:tri(a, m, apex, 0.06, r.c2, "Fabric")
				r:tri(m, b, apex, 0.06, C.White, "Fabric")
			end
			r:piece(function(q: R)
				q:block(-2.46, 5.3, 2.48, -2.06, 5.55, 2.52, r.c2, "Fabric")
				for side = 0, 3 do
					for k = 0, 5 do
						local t1, t2 = -2.46 + k * 0.82 + 0.01, -2.46 + (k + 1) * 0.82 - 0.01
						local col = if k % 2 == 0 then r.c2 else C.White
						if not (side == 0 and k == 0) then
							if side == 0 then
								q:block(t1, 5.3, 2.48, t2, 5.55, 2.52, col, "Fabric")
							elseif side == 1 then
								q:block(t1, 5.3, -2.52, t2, 5.55, -2.48, col, "Fabric")
							elseif side == 2 then
								q:block(2.48, 5.3, t1, 2.52, 5.55, t2, col, "Fabric")
							else
								q:block(-2.52, 5.3, t1, -2.48, 5.55, t2, col, "Fabric")
							end
						end
					end
				end
			end)
			for _, c in corners do
				rod(r, V(0, 6.45, 0), V(c.X * 0.98, 5.5, c.Z * 0.98), 0.05, C.White, "Metal")
				rod(r, V(0, 5.1, 0), V(c.X * 0.48, 5.98, c.Z * 0.48), 0.04, C.White, "Metal")
			end
			r:ball(0, 6.62, 0, 0.2, C.White, "Metal")
			-- lemonade
			local lemon = Color3.fromRGB(240, 222, 130)
			r:cyl(-0.45, 2.92, 0.3, 0.36, 0.28, "y", lemon, "Marble")
			r:cyl(-0.45, 2.98, 0.3, 0.56, 0.36, "y", C.Glass, "Glass").transp = 0.55
			r:beam(V(-0.27, 3.1, 0.3), V(-0.2, 2.85, 0.3), 0.05, 0.06, C.Glass, "Glass")
			for _, p in { { 0.35, 0.1 }, { 0.1, -0.5 } } do
				r:cyl(p[1], 2.83, p[2], 0.18, 0.16, "y", lemon, "Marble")
				r:cyl(p[1], 2.86, p[2], 0.32, 0.2, "y", C.Glass, "Glass").transp = 0.55
			end
			r:lump(CFrame.new(0.44, 3.0, 0.1) * CFrame.Angles(0, 0, 1.3), 0.14, 0.03, 0.14, C.Yellow, "Marble")
		end,
	},
	{
		id = "sea_cool_box",
		name = "Cool box",
		gives = "fridge", -- holding E gives something (Data/Items.Sources)
		cat = "kitchen",
		style = STYLE,
		price = 45,
		place = "floor",
		size = Vector3.new(2.4, 1.8, 1.8),
		c1 = "6F9EC0",
		c2 = "F2EEE6",
		tags = { "kitchen" },
		build = function(r: R)
			-- a picnic cool box (c1) with a white lid (c2), a groove round it, two catches, a
			-- carry handle over the top and a drain plug, a can on the lid and two bottles by it
			for _, sx in { -1, 1 } do
				for _, sz in { -1, 1 } do
					r:block(
						sx * 0.85 - 0.08,
						0,
						sz * 0.45 - 0.08,
						sx * 0.85 + 0.08,
						0.1,
						sz * 0.45 + 0.08,
						C.Black,
						"Rubber"
					)
				end
			end
			r:block(-1.0, 0.1, -0.6, 1.0, 1.0, 0.6, r.c1, "Metal")
			r:block(-1.03, 0.82, -0.63, 1.03, 0.88, 0.63, shade(r.c1, 0.85), "Metal")
			r:block(-1.05, 1.0, -0.65, 1.05, 1.22, 0.65, r.c2, "Metal")
			r:block(-0.9, 1.22, -0.5, 0.9, 1.26, 0.5, shade(r.c2, 0.94), "Metal")
			for _, x in { -0.55, 0.55 } do
				r:block(x - 0.1, 0.9, 0.6, x + 0.1, 1.1, 0.7, shade(r.c2, 0.85), "Metal")
			end
			r:cyl(0.7, 0.25, 0.63, 0.06, 0.14, "z", C.DarkMetal, "Metal")
			-- the handle swings on pivots at the ends
			for _, sx in { -1, 1 } do
				r:cyl(sx * 1.06, 0.92, 0, 0.06, 0.16, "x", C.DarkMetal, "Metal")
				r:beam(V(sx * 1.08, 0.92, 0), V(sx * 1.08, 1.42, 0), 0.06, 0.1, shade(r.c1, 0.8), "Metal")
			end
			r:block(-1.11, 1.38, -0.06, 1.11, 1.48, 0.06, shade(r.c1, 0.8), "Metal")
			r:block(-0.4, 1.35, -0.09, 0.4, 1.51, 0.09, C.Black, "Rubber")
			-- a can on the lid, and two bottles beside the box
			r:cyl(0.55, 1.42, 0.2, 0.32, 0.18, "y", CORAL, "Metal")
			r:cyl(0.55, 1.59, 0.2, 0.02, 0.14, "y", C.Metal, "Metal")
			for i, x in { 0.75, 1.0 } do
				local glass = if i == 1 then Color3.fromRGB(110, 160, 110) else Color3.fromRGB(150, 110, 70)
				r:cyl(x, 0.3, 0.88, 0.6, 0.2, "y", glass, "Glass")
				r:cyl(x, 0.68, 0.88, 0.16, 0.14, "y", glass, "Glass")
				r:cyl(x, 0.84, 0.88, 0.16, 0.08, "y", glass, "Glass")
				r:cyl(x, 0.94, 0.88, 0.05, 0.1, "y", C.Gold, "Metal")
				r:cyl(x, 0.32, 0.88, 0.2, 0.22, "y", C.Paper, "Cardboard")
			end
		end,
	},

	-- Out on the sand ---------------------------------------------------------------------------------
	{
		id = "sea_windbreak",
		name = "Windbreak",
		cat = "garden",
		style = STYLE,
		price = 45,
		place = "ground",
		size = Vector3.new(6.4, 3.2, 1.4),
		c1 = "6F9EC0",
		c2 = "F2EEE6",
		build = function(r: R)
			-- a striped canvas windbreak: five poles pushed into the ground in a shallow curve,
			-- the cloth between them in stripes of c1 and c2, guy ropes out from the ends
			local xs = { -3.0, -1.5, 0, 1.5, 3.0 }
			local function zAt(x: number): number
				return 0.45 * (x / 3) ^ 2 - 0.2
			end
			for _, x in xs do
				r:cyl(x, 1.5, zAt(x), 3.0, 0.12, "y", C.Bark, "Wood")
				r:ball(x, 3.02, zAt(x), 0.16, shade(C.Bark, 1.2), "Wood")
			end
			for i = 1, 4 do
				local x1, x2 = xs[i], xs[i + 1]
				for k = 0, 2 do
					local a, b = x1 + (x2 - x1) * k / 3, x1 + (x2 - x1) * (k + 1) / 3
					local pa, pb = V(a, 0.25, zAt(a)), V(b, 0.25, zAt(b))
					r:quad(
						pa,
						pb,
						pb + V(0, 2.6, 0),
						pa + V(0, 2.6, 0),
						0.04,
						if (i * 3 + k) % 2 == 0 then r.c1 else r.c2,
						"Fabric"
					)
				end
			end
			for _, sx in { -1, 1 } do
				local top = V(sx * 3.0, 2.8, zAt(3.0))
				local peg = V(sx * 3.12, 0.05, zAt(3.0) - 0.62)
				rod(r, top, peg, 0.03, ROPE, "Fabric")
				r:block(peg.X - 0.05, 0, peg.Z - 0.05, peg.X + 0.05, 0.16, peg.Z + 0.05, C.Bark, "Wood")
			end
		end,
	},
	{
		id = "sea_shade_sail",
		name = "Shade sail",
		cat = "garden",
		style = STYLE,
		price = 160,
		place = "ground",
		size = Vector3.new(7, 5.6, 6),
		c1 = "E8DCC0",
		c2 = "8E7A66",
		build = function(r: R)
			-- a three cornered canvas sail (c1) stretched between three timber posts (c2) set
			-- at different heights, a ring at each corner, a seam down the middle and a guy
			-- rope out from the tallest post
			local posts = { V(-3.1, 4.9, -2.5), V(3.1, 3.8, -2.5), V(0, 4.3, 2.6) }
			for _, p in posts do
				r:cyl(p.X, (p.Y + 0.3) / 2, p.Z, p.Y + 0.3, 0.24, "y", r.c2, "Wood")
				r:cyl(p.X, p.Y + 0.33, p.Z, 0.06, 0.3, "y", shade(r.c2, 0.8), "Wood")
				r:cyl(p.X, 0.07, p.Z, 0.14, 0.5, "y", C.Stone, "Concrete")
				r:cyl(p.X, p.Y - 0.05, p.Z, 0.08, 0.28, "y", C.DarkMetal, "Metal")
			end
			local mid = (posts[1] + posts[2] + posts[3]) / 3
			local sail = {}
			for i, p in posts do
				sail[i] = p + (mid - p) * 0.14 - V(0, 0.08, 0)
			end
			r:tri(sail[1], sail[2], sail[3], 0.06, r.c1, "Fabric")
			-- a seam from the front corner to the middle of the back edge, the hem round it
			r:beam(sail[3], (sail[1] + sail[2]) / 2, 0.12, 0.12, shade(r.c1, 0.9), "Fabric")
			for i = 1, 3 do
				r:beam(sail[i], sail[i % 3 + 1], 0.14, 0.14, shade(r.c1, 0.86), "Fabric")
				rod(r, posts[i] - V(0, 0.05, 0), sail[i], 0.04, C.DarkMetal, "Metal")
				r:ball(sail[i].X, sail[i].Y, sail[i].Z, 0.16, C.Metal, "Metal")
			end
			rod(r, posts[1] + V(0, 0.2, 0), V(-3.4, 0.05, -2.9), 0.03, ROPE, "Fabric")
			r:block(-3.45, 0, -2.95, -3.35, 0.18, -2.85, C.Bark, "Wood")
		end,
	},
	{
		id = "sea_sandcastle",
		name = "Sandcastle",
		cat = "fun",
		style = STYLE,
		price = 40,
		place = "ground",
		size = Vector3.new(3.6, 2.4, 3.6),
		c1 = "E6CC98",
		c2 = "6CA6CC",
		tags = { "toy" },
		build = function(r: R)
			-- a sandcastle (c1) on a mound inside its moat (c2): four turrets with
			-- battlements, a keep with a pointed top and a flag, a gate with a bridge over the
			-- moat, shells pressed into the walls, and the bucket and spade that made it
			r:cyl(0, 0.125, 0, 0.25, 3.2, "y", shade(r.c1, 0.95), "Sand")
			water(r:cyl(0, 0.27, 0, 0.04, 2.9, "y", r.c2, "Glass"), 0.15)
			r:piece(function(q: R)
				q:block(-0.95, 0.25, -0.95, 0.95, 0.65, 0.95, r.c1, "Sand")
				for _, sx in { -1, 1 } do
					for _, sz in { -1, 1 } do
						q:cyl(sx * 0.85, 0.775, sz * 0.85, 1.05, 0.6, "y", shade(r.c1, 1.04), "Sand")
						for k = 0, 3 do
							local a = k * math.pi / 2
							q:box(
								sx * 0.85 + math.cos(a) * 0.2,
								1.36,
								sz * 0.85 + math.sin(a) * 0.2,
								0.12,
								0.12,
								0.12,
								shade(r.c1, 1.04),
								"Sand"
							)
						end
					end
				end
				q:block(-0.45, 0.65, -0.45, 0.45, 1.5, 0.45, r.c1, "Sand")
				q:cone(0, 1.8, 0, 0.6, 0.72, shade(r.c1, 0.95), "Sand")
				q:block(-0.25, 0.25, 0.95, 0.25, 0.32, 1.5, shade(r.c1, 0.95), "Sand")
			end, true)
			r:block(-0.18, 0.32, 0.95, 0.18, 0.56, 0.98, shade(r.c1, 0.6), "Sand")
			-- the outer bank of the moat
			r:piece(function(q: R)
				q:box(1.45, 0.28, 0, 0.12, 0.06, 0.12, shade(r.c1, 0.9), "Sand")
				for i = 0, 15 do
					local a = i / 16 * math.pi * 2
					if math.abs(a - math.pi / 2) > 0.3 then
						q:lump(
							CFrame.new(math.cos(a) * 1.48, 0.28, math.sin(a) * 1.48) * CFrame.Angles(0, -a, 0),
							0.5,
							0.16,
							0.24,
							shade(r.c1, 0.92),
							"Sand"
						)
					end
				end
			end)
			r:piece(function(q: R)
				q:box(0, 0.62, 0.97, 0.06, 0.04, 0.04, C.Pink, "Fabric")
				for _, p in
					{
						{ 0, 0.62, 0.98 },
						{ -0.6, 0.45, 0.98 },
						{ 0.6, 0.45, 0.98 },
						{ 0.46, 0.4, -0.98 },
						{ 0.98, 0.5, 0.2 },
						{ -0.98, 0.42, -0.3 },
					}
				do
					q:lump(
						CFrame.new(p[1], p[2], p[3]) * CFrame.Angles(0.2, p[1], 0),
						0.16,
						0.12,
						0.1,
						if p[1] > 0 then C.Pink else C.White,
						"Fabric"
					)
				end
			end, nil, "Fabric")
			r:block(-0.02, 2.05, -0.02, 0.02, 2.4, 0.02, C.Bark, "Wood")
			r:tri(V(0.02, 2.38, 0), V(0.02, 2.2, 0), V(0.34, 2.29, 0), 0.03, C.Red, "Fabric")
			-- the bucket and spade
			r:cyl(1.35, 0.25, -1.3, 0.5, 0.5, "y", C.Red, "Metal")
			r:cyl(1.35, 0.5, -1.3, 0.06, 0.56, "y", shade(C.Red, 0.85), "Metal")
			r:beam(V(1.1, 0.42, -1.3), V(1.35, 0.72, -1.3), 0.04, 0.04, shade(C.Red, 0.85), "Metal")
			r:beam(V(1.6, 0.42, -1.3), V(1.35, 0.72, -1.3), 0.04, 0.04, shade(C.Red, 0.85), "Metal")
			r:beam(V(-1.2, 0.2, -1.1), V(-1.55, 0.95, -1.4), 0.07, 0.07, C.Yellow, "Metal")
			r:boxAt(CFrame.new(-1.12, 0.16, -1.04) * CFrame.Angles(0.5, 0.7, 0.3), 0.3, 0.32, 0.04, C.Yellow, "Metal")
		end,
	},
	{
		id = "sea_lobster_pots",
		name = "Lobster pots",
		cat = "garden",
		style = STYLE,
		price = 70,
		place = "ground",
		size = Vector3.new(3.4, 2.2, 2.6),
		c1 = "8E7A60",
		c2 = "3F6A78",
		build = function(r: R)
			-- three creels: a wooden base and three bent hoops (c1) under netting (c2) with a
			-- way in on top, two stacked and one beside, with floats tied on and rope coiled
			local R0 = 0.47
			local function pot(cx: number, cy: number, cz: number)
				r:piece(function(q: R)
					for _, s in { -1, 1 } do
						q:block(cx - 0.75, cy, cz + s * 0.4, cx + 0.75, cy + 0.12, cz + s * 0.475, r.c1, "Wood")
						q:block(cx + s * 0.68, cy, cz - 0.4, cx + s * 0.75, cy + 0.12, cz + 0.4, r.c1, "Wood")
					end
					for _, hx in { -0.6, 0, 0.6 } do
						for k = 0, 4 do
							local a1, a2 = k / 5 * math.pi, (k + 1) / 5 * math.pi
							local p1 = V(cx + hx, cy + 0.12 + math.sin(a1) * R0, cz + math.cos(a1) * R0)
							local p2 = V(cx + hx, cy + 0.12 + math.sin(a2) * R0, cz + math.cos(a2) * R0)
							local d = (p2 - p1).Unit * 0.02
							q:beam(p1 - d, p2 + d, 0.06, 0.06, shade(r.c1, 0.9), "Wood")
						end
					end
				end)
				r:piece(function(q: R)
					q:box(cx, cy + 0.08, cz, 0.08, 0.04, 0.08, r.c2, "Fabric")
					for k = 1, 5 do
						local a = k / 6 * math.pi
						local y, z = cy + 0.12 + math.sin(a) * (R0 + 0.02), cz + math.cos(a) * (R0 + 0.02)
						q:beam(V(cx - 0.7, y, z), V(cx + 0.7, y, z), 0.03, 0.03, r.c2, "Fabric")
					end
					for _, s in { -1, 1 } do
						for _, z in { -0.28, 0, 0.28 } do
							local top = cy + 0.12 + math.sqrt(R0 ^ 2 - z ^ 2)
							q:beam(
								V(cx + s * 0.72, cy + 0.12, cz + z),
								V(cx + s * 0.72, top, cz + z),
								0.03,
								0.03,
								r.c2,
								"Fabric"
							)
						end
					end
					q:add({
						shape = "Cone",
						cf = CFrame.new(cx, cy + 0.44, cz) * CFrame.Angles(math.pi, 0, 0),
						size = Vector3.new(0.36, 0.3, 0.36),
						color = shade(r.c2, 1.2),
						mat = "Fabric",
					})
				end)
			end
			pot(-0.8, 0, -0.5)
			pot(-0.7, 0.6, -0.45)
			pot(0.9, 0, 0.55)
			-- floats on lines, and a coil of rope
			for i, p in { { 0.5, 0.18, -0.85 }, { 1.4, 0.18, -0.4 }, { 0.15, 0.18, 1.05 } } do
				local col = if i == 1 then CORAL elseif i == 2 then C.Yellow else C.White
				r:ball(p[1], p[2], p[3], 0.36, col, "Fabric")
				r:cyl(p[1], p[2] + 0.2, p[3], 0.08, 0.1, "y", shade(col, 0.8), "Fabric")
			end
			rod(r, V(0.5, 0.4, -0.85), V(0.0, 0.95, -0.5), 0.03, ROPE, "Fabric")
			rod(r, V(1.4, 0.4, -0.4), V(1.2, 0.5, 0.3), 0.03, ROPE, "Fabric")
			r:piece(function(q: R)
				q:box(-1.1, 0.04, 0.8, 0.1, 0.04, 0.1, ROPE, "Fabric")
				ring(q, V(-1.1, 0.04, 0.8), X, Z, 0.36, 0.07, 8, flat(ROPE), "Fabric")
				ring(q, V(-1.1, 0.1, 0.8), X, Z, 0.26, 0.07, 7, flat(shade(ROPE, 0.94)), "Fabric")
				ring(q, V(-1.1, 0.04, 0.8), X, Z, 0.17, 0.07, 6, flat(ROPE), "Fabric")
			end)
		end,
	},
	{
		id = "sea_drying_net",
		name = "Drying net",
		cat = "garden",
		style = STYLE,
		price = 80,
		place = "ground",
		size = Vector3.new(6, 5, 1.4),
		c1 = "3F6A78",
		c2 = "8E7A66",
		build = function(r: R)
			-- a fishing net (c1) hung out to dry from a rope between two poles (c2), cork
			-- floats along its top, its foot heaped on the ground, a basket beside
			for _, sx in { -1, 1 } do
				r:cyl(sx * 2.8, 2.3, 0, 4.6, 0.2, "y", r.c2, "Wood")
				r:ball(sx * 2.8, 4.65, 0, 0.24, shade(r.c2, 1.15), "Wood")
				r:piece(function(q: R)
					q:box(sx * 2.8, 0.06, 0, 0.3, 0.06, 0.3, C.Stone, "Slate")
					for k = 0, 4 do
						local a = k / 5 * math.pi * 2
						q:lump(
							CFrame.new(sx * 2.8 + math.cos(a) * 0.26, 0.1, math.sin(a) * 0.24) * CFrame.Angles(0, a, 0),
							0.3,
							0.2,
							0.24,
							if k % 2 == 0 then C.Stone else shade(C.Stone, 0.88),
							"Slate"
						)
					end
				end)
			end
			local function top(x: number): number
				return 4.1 + 0.2 * (x / 2.8) ^ 2
			end
			local function foot(x: number): number
				return 0.3 + 1.2 * (x / 2.8) ^ 2
			end
			rail(
				r,
				{ V(-2.8, 4.3, 0), V(-1.4, top(-1.4), 0), V(0, top(0), 0), V(1.4, top(1.4), 0), V(2.8, 4.3, 0) },
				0.05,
				0.05,
				ROPE,
				"Fabric"
			)
			local xs = { -2.7, -1.35, 0, 1.35, 2.7 }
			local function row(q: R, f: number)
				for i = 1, 4 do
					local a, b = xs[i], xs[i + 1]
					local bulge = 0.08 * math.sin(f * math.pi)
					q:beam(
						V(a, top(a) + (foot(a) - top(a)) * f, bulge),
						V(b, top(b) + (foot(b) - top(b)) * f, bulge),
						0.035,
						0.035,
						r.c1,
						"Fabric"
					)
				end
			end
			r:piece(function(q: R)
				q:box(0, top(0) - 0.05, 0, 0.06, 0.06, 0.06, r.c1, "Fabric")
				for i = 0, 8 do
					local x = -2.4 + i * 0.6
					q:beam(V(x, top(x) - 0.02, 0), V(x, foot(x), 0.03), 0.035, 0.035, r.c1, "Fabric")
				end
				row(q, 1 / 6)
				row(q, 2 / 6)
			end)
			r:piece(function(q: R)
				q:box(0, (top(0) + foot(0)) / 2, 0.08, 0.06, 0.06, 0.06, r.c1, "Fabric")
				row(q, 3 / 6)
				row(q, 4 / 6)
				row(q, 5 / 6)
				for i, x in { -0.9, -0.3, 0.35, 0.95 } do
					q:lump(
						CFrame.new(x, 0.14, 0.12 * (i % 2)) * CFrame.Angles(0, i, 0),
						0.7,
						0.28,
						0.6,
						if i % 2 == 0 then r.c1 else shade(r.c1, 1.15),
						"Fabric"
					)
				end
			end)
			r:piece(function(q: R)
				q:box(-2.1, top(-2.1) - 0.06, 0, 0.06, 0.06, 0.06, Color3.fromRGB(200, 150, 96), "Sand")
				for i = 0, 6 do
					local x = -2.1 + i * 0.7
					q:cyl(
						x,
						top(x) - 0.06,
						0,
						0.22,
						0.16,
						"x",
						if i % 2 == 0 then Color3.fromRGB(200, 150, 96) else CORAL,
						"Sand"
					)
				end
			end, nil, "Sand")
			r:cyl(1.7, 0.25, 0.42, 0.5, 0.62, "y", Color3.fromRGB(176, 140, 96), "Fabric")
			r:cyl(1.7, 0.52, 0.42, 0.06, 0.68, "y", shade(Color3.fromRGB(176, 140, 96), 0.85), "Fabric")
			r:lump(
				CFrame.new(1.68, 0.56, 0.42) * CFrame.Angles(0, 0.4, 0.5),
				0.42,
				0.12,
				0.14,
				Color3.fromRGB(176, 186, 196),
				"Metal"
			)
		end,
	},
	{
		id = "sea_anchor",
		name = "Old anchor",
		cat = "garden",
		style = STYLE,
		price = 120,
		place = "ground",
		size = Vector3.new(3.4, 4, 2.2),
		c1 = "4A524F",
		c2 = "8A6A4A",
		tags = { "art" },
		build = function(r: R)
			-- an old iron anchor (c1) stood up in a heap of stones: its shank, the crown and two
			-- curved arms ending in flukes, a wooden stock (c2) bound with iron near the top,
			-- the ring, a chain hung from it down to a coil on the ground, and a little rust
			r:piece(function(q: R)
				q:box(0, 0.2, 0, 0.3, 0.3, 0.3, C.Stone, "Slate")
				for k = 0, 6 do
					local a = k / 7 * math.pi * 2
					local rad = if k % 2 == 0 then 0.55 else 0.75
					q:lump(
						CFrame.new(math.cos(a) * rad, 0.2, math.sin(a) * rad * 0.8) * CFrame.Angles(0, a, 0.2),
						0.6,
						0.42,
						0.5,
						if k % 3 == 0 then C.Stone else shade(C.Stone, 0.88 + (k % 2) * 0.1),
						"Slate"
					)
				end
				q:lump(
					CFrame.new(0.1, 0.42, 0.1) * CFrame.Angles(0, 1, 0),
					0.6,
					0.36,
					0.5,
					shade(C.Stone, 1.05),
					"Slate"
				)
			end)
			r:block(-0.11, 0.4, -0.11, 0.11, 3.35, 0.11, r.c1, "Metal")
			r:ball(0, 0.6, 0, 0.38, r.c1, "Metal")
			for _, s in { -1, 1 } do
				rail(
					r,
					{ V(0, 0.6, 0), V(s * 0.65, 0.72, 0), V(s * 1.05, 1.1, 0), V(s * 1.2, 1.6, 0) },
					0.18,
					0.2,
					r.c1,
					"Metal"
				)
				r:tri(V(s * 0.95, 1.2, 0), V(s * 1.48, 1.45, 0), V(s * 1.26, 2.02, 0), 0.12, r.c1, "Metal")
			end
			r:block(-0.15, 2.82, -0.95, 0.15, 3.08, 0.95, r.c2, "Wood")
			for _, s in { -1, 1 } do
				r:block(-0.19, 2.78, s * 0.55 - 0.05, 0.19, 3.12, s * 0.55 + 0.05, r.c1, "Metal")
			end
			r:piece(function(q: R)
				q:block(-0.08, 3.35, -0.08, 0.08, 3.38, 0.08, r.c1, "Metal")
				ring(q, V(0, 3.62, 0), X, Y, 0.24, 0.08, 8, flat(r.c1), "Metal")
			end)
			-- the chain: links along a line from the ring down to the ground, each turned across
			-- the one before
			local path = {
				V(0.22, 3.45, 0.05),
				V(0.45, 2.6, 0.3),
				V(0.55, 1.6, 0.48),
				V(0.78, 0.6, 0.6),
				V(1.05, 0.1, 0.62),
				V(1.38, 0.07, 0.3),
				V(1.25, 0.07, -0.1),
			}
			r:piece(function(q: R)
				q:box(0.2, 3.42, 0.04, 0.08, 0.08, 0.08, shade(r.c1, 1.2), "Metal")
				local k = 0
				for i = 1, #path - 1 do
					local a, b = path[i], path[i + 1]
					local n = math.max(1, math.floor((b - a).Magnitude / 0.2 + 0.5))
					for j = 0, n - 1 do
						local p1 = a:Lerp(b, j / n)
						local p2 = a:Lerp(b, (j + 1) / n)
						local d = (p2 - p1).Unit * 0.02
						if k % 2 == 0 then
							q:beam(p1 - d, p2 + d, 0.12, 0.04, shade(r.c1, 1.2), "Metal")
						else
							q:beam(p1 - d, p2 + d, 0.04, 0.12, shade(r.c1, 1.2), "Metal")
						end
						k += 1
					end
				end
			end)
			local rust = Color3.fromRGB(150, 92, 64)
			for _, p in { { 0.1, 1.4 }, { -0.1, 2.3 }, { 0.1, 3.2 } } do
				r:lump(CFrame.new(p[1], p[2], 0.1), 0.12, 0.2, 0.06, rust, "Metal")
			end
		end,
	},
	{
		id = "sea_mooring_post",
		name = "Mooring post",
		cat = "garden",
		style = STYLE,
		price = 55,
		place = "ground",
		size = Vector3.new(1.6, 4.8, 1.6),
		c1 = "6E5A48",
		c2 = "D8C8A6",
		build = function(r: R)
			-- a thick old pier post (c1) with iron bands, weed round its foot, a rope (c2)
			-- wound round it with a loop hanging, the end coiled on the ground, and a gull on top
			r:cyl(0, 1.8, 0, 3.6, 0.9, "y", r.c1, "Wood")
			r:cyl(0, 3.625, 0, 0.05, 0.78, "y", shade(r.c1, 1.25), "Wood")
			for _, y in { 1.0, 3.15 } do
				r:cyl(0, y, 0, 0.14, 0.96, "y", C.DarkMetal, "Metal")
			end
			r:piece(function(q: R)
				q:box(0.4, 0.05, 0, 0.1, 0.1, 0.1, Color3.fromRGB(96, 120, 84), "Grass")
				for k = 0, 6 do
					local a = k / 7 * math.pi * 2
					q:lump(
						CFrame.new(math.cos(a) * 0.47, 0.2 + (k % 2) * 0.12, math.sin(a) * 0.47)
							* CFrame.Angles(0, -a, 0.3),
						0.16,
						0.36,
						0.26,
						if k % 2 == 0 then Color3.fromRGB(96, 120, 84) else Color3.fromRGB(120, 140, 92),
						"Grass"
					)
				end
			end)
			r:piece(function(q: R)
				q:box(0.5, 2.3, 0, 0.06, 0.06, 0.06, r.c2, "Fabric")
				ring(q, V(0, 2.25, 0), X, Z, 0.52, 0.12, 10, flat(r.c2), "Fabric")
				ring(q, V(0, 2.4, 0), X, Z, 0.52, 0.12, 10, flat(shade(r.c2, 0.92)), "Fabric")
				q:beam(V(0.52, 2.3, 0.1), V(0.62, 1.7, 0.3), 0.1, 0.1, r.c2, "Fabric")
				q:beam(V(0.62, 1.7, 0.3), V(0.5, 1.4, 0.48), 0.1, 0.1, r.c2, "Fabric")
				q:beam(V(0.5, 1.4, 0.48), V(0.25, 1.55, 0.55), 0.1, 0.1, r.c2, "Fabric")
				q:beam(V(0.25, 1.55, 0.55), V(0.1, 2.25, 0.5), 0.1, 0.1, r.c2, "Fabric")
			end)
			r:piece(function(q: R)
				q:box(-0.5, 0.05, 0.55, 0.06, 0.06, 0.06, r.c2, "Fabric")
				ring(q, V(-0.42, 0.06, 0.48), X, Z, 0.3, 0.1, 8, flat(r.c2), "Fabric")
				ring(q, V(-0.42, 0.15, 0.48), X, Z, 0.22, 0.1, 7, flat(shade(r.c2, 0.92)), "Fabric")
				q:beam(V(-0.12, 0.08, 0.4), V(-0.36, 2.25, 0.42), 0.1, 0.1, r.c2, "Fabric")
			end)
			r:piece(function(q: R)
				gull(q, 0, 3.65, 0, 1)
			end)
		end,
	},

	-- Changing and washing --------------------------------------------------------------------------
	{
		id = "sea_changing_hut",
		name = "Changing hut",
		cat = "bath",
		style = STYLE,
		price = 220,
		place = "ground",
		size = Vector3.new(3.4, 7, 3.8),
		c1 = "7FA8C8",
		c2 = "C98A7A",
		build = function(r: R)
			-- a narrow hut to change in, on a low deck: white boards with stripes (c1) on every
			-- side, a door with its own stripes and a round window, a pitched roof (c2) with
			-- bargeboards and a finial, a step, and a towel on a hook
			local W, top = 1.3, 5.6
			r:block(-1.45, 0, -1.45, 1.45, 0.25, 1.45, WOOD, "WoodPlanks")
			r:block(-W, 0.25, -W, W, top, W, C.White, "WoodPlanks")
			r:piece(function(q: R)
				for i = 0, 3 do
					local t = -W + 0.33 + i * 0.65
					for _, s in { -1, 1 } do
						q:block(s * W, 0.25, t - 0.16, s * (W + 0.04), top, t + 0.16, r.c1, "WoodPlanks")
					end
					q:block(t - 0.16, 0.25, -W - 0.04, t + 0.16, top, -W, r.c1, "WoodPlanks")
				end
				for _, s in { -1, 1 } do
					q:block(s * 1.0 - 0.16, 0.25, W, s * 1.0 + 0.16, top, W + 0.04, r.c1, "WoodPlanks")
				end
			end)
			-- the door, its frame, stripes, window and knob
			r:block(-0.7, 0.28, W, 0.7, 4.7, W + 0.06, shade(C.White, 0.96), "WoodPlanks")
			for _, x in { -0.35, 0.35 } do
				r:block(x - 0.14, 0.28, W + 0.06, x + 0.14, 4.7, W + 0.1, r.c1, "WoodPlanks")
			end
			r:piece(function(q: R)
				q:block(-0.84, 4.7, W, 0.84, 4.86, W + 0.1, shade(r.c2, 0.85), "Wood")
				for _, s in { -1, 1 } do
					q:block(s * 0.7, 0.25, W, s * 0.84, 4.7, W + 0.08, shade(r.c2, 0.85), "Wood")
				end
			end)
			r:cyl(0, 4.0, W + 0.1, 0.06, 0.62, "z", shade(r.c2, 0.85), "Wood")
			r:cyl(0, 4.0, W + 0.13, 0.06, 0.48, "z", Color3.fromRGB(70, 96, 110), "Glass")
			r:ball(0.5, 2.4, W + 0.16, 0.14, C.Gold, "Metal")
			-- the roof
			for _, s in { -1, 1 } do
				r:quad(
					V(s * 1.65, top - 0.3, -1.65),
					V(s * 1.65, top - 0.3, 1.65),
					V(0, top + 0.95, 1.65),
					V(0, top + 0.95, -1.65),
					0.14,
					r.c2,
					"WoodPlanks"
				)
				r:beam(V(s * 1.68, top - 0.36, 1.68), V(0, top + 0.98, 1.68), 0.14, 0.24, shade(r.c2, 0.8), "Wood")
			end
			for _, z in { -W, W } do
				r:tri(V(-W, top, z), V(W, top, z), V(0, top + 0.8, z), 0.06, C.White, "WoodPlanks")
			end
			r:block(-0.1, top + 0.9, -1.72, 0.1, top + 1.1, 1.72, shade(r.c2, 0.8), "Wood")
			r:ball(0, top + 1.2, 1.68, 0.22, shade(r.c2, 0.8), "Wood")
			-- the step and the towel
			r:block(-0.6, 0, 1.45, 0.6, 0.16, 1.85, shade(WOOD, 1.1), "WoodPlanks")
			r:block(W + 0.04, 3.74, 0.36, W + 0.16, 3.82, 0.44, C.DarkMetal, "Metal")
			r:block(W + 0.08, 2.5, 0.1, W + 0.14, 3.75, 0.7, C.Yellow, "Fabric")
			for _, y in { 2.75, 3.4 } do
				r:block(W + 0.14, y - 0.06, 0.1, W + 0.17, y + 0.06, 0.7, C.White, "Fabric")
			end
		end,
	},
	{
		id = "sea_shower",
		name = "Beach shower",
		cat = "bath",
		style = STYLE,
		price = 130,
		place = "ground",
		size = Vector3.new(2.6, 7.4, 2.6),
		c1 = "B08A64",
		c2 = "B8BEC6",
		tags = { "bath" },
		build = function(r: R)
			-- an outdoor shower to rinse the sand off: a timber post (c1) with a steel pipe (c2)
			-- up it to a wide rose, a lever to turn it on, a low tap for feet, a slatted
			-- duckboard to stand on, a towel on a hook and flip flops left on the boards
			local dk = shade(r.c1, 0.82)
			for _, x in { -0.9, 0, 0.9 } do
				r:block(x - 0.08, 0, -1.1, x + 0.08, 0.12, 1.1, dk, "Wood")
			end
			r:piece(function(q: R)
				for k = 0, 6 do
					local z = -0.95 + k * 0.32
					q:block(
						-1.1,
						0.12,
						z - 0.12,
						1.1,
						0.2,
						z + 0.12,
						if k % 2 == 0 then r.c1 else shade(r.c1, 1.06),
						"Wood"
					)
				end
			end, true)
			r:block(-0.17, 0, -1.25, 0.17, 7.0, -0.91, r.c1, "Wood")
			r:block(-0.21, 7.0, -1.29, 0.21, 7.1, -0.87, dk, "Wood")
			r:cyl(0, 3.9, -0.82, 6.2, 0.1, "y", r.c2, "Metal")
			for _, y in { 2.0, 5.0 } do
				r:block(-0.1, y - 0.05, -0.91, 0.1, y + 0.05, -0.74, shade(r.c2, 0.8), "Metal")
			end
			r:ball(0, 7.0, -0.82, 0.14, r.c2, "Metal")
			r:cyl(0, 7.0, -0.34, 0.96, 0.1, "z", r.c2, "Metal")
			r:cyl(0, 6.98, 0.2, 0.14, 0.26, "y", r.c2, "Metal")
			r:cyl(0, 6.86, 0.2, 0.1, 0.8, "y", r.c2, "Metal")
			r:piece(function(q: R)
				q:box(0, 6.795, 0.2, 0.06, 0.03, 0.06, C.DarkMetal, "Metal")
				for k = 0, 5 do
					local a = k / 6 * math.pi * 2
					q:cyl(math.cos(a) * 0.22, 6.795, 0.2 + math.sin(a) * 0.22, 0.03, 0.06, "y", C.DarkMetal, "Metal")
				end
			end)
			-- the lever, and the foot tap low down
			r:block(-0.08, 3.52, -0.8, 0.08, 3.68, -0.66, shade(r.c2, 0.8), "Metal")
			r:beam(V(0, 3.6, -0.66), V(0.3, 3.74, -0.6), 0.06, 0.06, C.Red, "Metal")
			r:beam(V(0, 1.0, -0.78), V(0, 0.9, -0.55), 0.07, 0.07, r.c2, "Metal")
			r:cyl(0, 1.08, -0.7, 0.06, 0.16, "y", C.Blue, "Metal")
			-- the towel on its hook
			r:block(0.17, 5.2, -1.12, 0.25, 5.3, -1.04, C.DarkMetal, "Metal")
			r:block(0.25, 3.9, -1.3, 0.31, 5.25, -0.86, SEA, "Fabric")
			for _, y in { 4.2, 4.9 } do
				r:block(0.31, y - 0.06, -1.3, 0.34, y + 0.06, -0.86, C.White, "Fabric")
			end
			-- flip flops
			for i, p in { { 0.55, 0.55, 0.2 }, { 0.82, 0.62, -0.1 } } do
				local f = CFrame.new(p[1], 0.22, p[2]) * CFrame.Angles(0, p[3], 0)
				r:lump(f, 0.18, 0.05, 0.46, if i == 1 then CORAL else shade(CORAL, 0.9), "Rubber")
				r:beam(
					(f * CFrame.new(0, 0.02, -0.12)).Position,
					(f * CFrame.new(-0.08, 0.06, 0.05)).Position,
					0.03,
					0.03,
					C.White,
					"Rubber"
				)
				r:beam(
					(f * CFrame.new(0, 0.02, -0.12)).Position,
					(f * CFrame.new(0.08, 0.06, 0.05)).Position,
					0.03,
					0.03,
					C.White,
					"Rubber"
				)
			end
		end,
	},

	-- Lights ----------------------------------------------------------------------------------------
	{
		id = "sea_lighthouse_lamp",
		name = "Little lighthouse",
		cat = "lights",
		style = STYLE,
		price = 90,
		place = "floor",
		size = Vector3.new(1.8, 5.4, 1.8),
		c1 = "D46F5E",
		c2 = "F2EEE6",
		tags = { "light" },
		build = function(r: R)
			-- a lamp built like a lighthouse: a tower in bands of white (c2) and red (c1) on a
			-- slate base, a door and two windows, a railed gallery, a glass lantern room with
			-- the lamp in it, and a red cap with a vent
			r:cyl(0, 0.15, 0, 0.3, 1.6, "y", Color3.fromRGB(110, 112, 120), "Slate")
			local bands = { { 0.3, 1.1, 1.2 }, { 1.1, 1.9, 1.08 }, { 1.9, 2.7, 0.96 }, { 2.7, 3.5, 0.84 } }
			for i, b in bands do
				r:cyl(0, (b[1] + b[2]) / 2, 0, b[2] - b[1], b[3], "y", if i % 2 == 1 then r.c2 else r.c1, "Wood")
			end
			r:block(-0.16, 0.3, 0.54, 0.16, 0.85, 0.64, Color3.fromRGB(60, 70, 80), "Wood")
			for _, w in { { 1.5, 0.5 }, { 2.35, 0.45 } } do
				r:block(
					-0.08,
					w[1] - 0.12,
					w[2] - 0.05,
					0.08,
					w[1] + 0.12,
					w[2] + 0.08,
					Color3.fromRGB(60, 70, 80),
					"Glass"
				)
			end
			r:cyl(0, 3.55, 0, 0.1, 1.2, "y", C.DarkMetal, "Metal")
			r:piece(function(q: R)
				q:box(0.55, 3.75, 0, 0.04, 0.3, 0.04, C.DarkMetal, "Metal")
				for k = 1, 7 do
					local a = k / 8 * math.pi * 2
					q:block(
						math.cos(a) * 0.55 - 0.02,
						3.6,
						math.sin(a) * 0.55 - 0.02,
						math.cos(a) * 0.55 + 0.02,
						3.9,
						math.sin(a) * 0.55 + 0.02,
						C.DarkMetal,
						"Metal"
					)
				end
				ring(q, V(0, 3.9, 0), X, Z, 0.55, 0.04, 8, flat(C.DarkMetal), "Metal")
			end)
			r:cyl(0, 4.0, 0, 0.8, 0.64, "y", C.Glass, "Glass").transp = 0.5
			for k = 0, 3 do
				local a = k / 4 * math.pi * 2 + math.pi / 4
				r:block(
					math.cos(a) * 0.31 - 0.03,
					3.6,
					math.sin(a) * 0.31 - 0.03,
					math.cos(a) * 0.31 + 0.03,
					4.4,
					math.sin(a) * 0.31 + 0.03,
					C.DarkMetal,
					"Metal"
				)
			end
			r:glow(r:ball(0, 4.0, 0, 0.36, C.Warm, "Glass"), 18, 1.3)
			r:cyl(0, 4.45, 0, 0.1, 0.8, "y", r.c1, "Wood")
			r:cone(0, 4.72, 0, 0.44, 0.76, r.c1, "Wood")
			r:ball(0, 5.0, 0, 0.16, C.DarkMetal, "Metal")
			r:cyl(0, 5.2, 0, 0.3, 0.04, "y", C.DarkMetal, "Metal")
		end,
	},
	{
		id = "sea_buoy_lamp",
		name = "Buoy lamp",
		cat = "lights",
		style = STYLE,
		price = 85,
		place = "ground",
		size = Vector3.new(1.8, 4.2, 1.8),
		c1 = "E8C46C",
		c2 = "45454A",
		tags = { "light" },
		build = function(r: R)
			-- a marker buoy brought ashore as a garden light: a fat float in bands of yellow
			-- (c1) and black (c2), a lattice tower of four legs up to the light, and two cones
			-- on top for its mark, barnacles round its foot
			r:cyl(0, 0.1, 0, 0.2, 1.3, "y", C.Stone, "Concrete")
			r:cyl(0, 0.4, 0, 0.4, 1.6, "y", r.c2, "Metal")
			r:cyl(0, 0.85, 0, 0.5, 1.6, "y", r.c1, "Metal")
			r:cyl(0, 1.15, 0, 0.1, 1.3, "y", r.c1, "Metal")
			r:cyl(0, 1.25, 0, 0.1, 0.9, "y", shade(r.c1, 0.9), "Metal")
			r:piece(function(q: R)
				q:block(-0.06, 1.3, -0.06, 0.06, 1.36, 0.06, r.c2, "Metal")
				for k = 0, 3 do
					local a = k / 4 * math.pi * 2 + math.pi / 4
					local c, s = math.cos(a), math.sin(a)
					q:beam(V(c * 0.4, 1.3, s * 0.4), V(c * 0.2, 2.5, s * 0.2), 0.06, 0.06, r.c2, "Metal")
					local b = (k + 1) / 4 * math.pi * 2 + math.pi / 4
					q:beam(
						V(c * 0.35, 1.55, s * 0.35),
						V(math.cos(b) * 0.27, 2.2, math.sin(b) * 0.27),
						0.04,
						0.04,
						r.c2,
						"Metal"
					)
				end
				ring(q, V(0, 1.9, 0), X, Z, 0.3, 0.05, 8, flat(r.c2), "Metal")
				ring(q, V(0, 2.5, 0), X, Z, 0.22, 0.06, 8, flat(r.c2), "Metal")
			end)
			r:cyl(0, 2.54, 0, 0.06, 0.5, "y", r.c2, "Metal")
			r:glow(r:cyl(0, 2.77, 0, 0.4, 0.3, "y", C.Warm, "Glass"), 16, 1.2)
			r:cyl(0, 3.0, 0, 0.06, 0.44, "y", r.c2, "Metal")
			r:cyl(0, 3.2, 0, 0.34, 0.05, "y", r.c2, "Metal")
			r:cone(0, 3.5, 0, 0.36, 0.46, r.c2, "Metal")
			r:add({
				shape = "Cone",
				cf = CFrame.new(0, 3.88, 0) * CFrame.Angles(math.pi, 0, 0),
				size = Vector3.new(0.46, 0.36, 0.46),
				color = r.c2,
				mat = "Metal",
			})
			-- a ring to lift it by, and barnacles round the float
			r:piece(function(q: R)
				q:box(0.7, 0.95, 0, 0.08, 0.08, 0.08, r.c2, "Metal")
				ring(q, V(0.82, 0.95, 0), X, Y, 0.12, 0.04, 6, flat(r.c2), "Metal")
			end)
			r:piece(function(q: R)
				q:box(0.65, 0.23, 0.1, 0.06, 0.06, 0.06, Color3.fromRGB(200, 196, 186), "Metal")
				for k = 0, 9 do
					local a = k / 10 * math.pi * 2 + 0.2
					q:cone(
						math.cos(a) * 0.78,
						0.26 + (k % 3) * 0.1,
						math.sin(a) * 0.78,
						0.1,
						0.12,
						if k % 2 == 0 then Color3.fromRGB(200, 196, 186) else Color3.fromRGB(170, 166, 158),
						"Metal"
					)
				end
			end, nil, "Metal")
		end,
	},
	{
		id = "sea_float_lamp",
		name = "Glass float lamp",
		cat = "lights",
		style = STYLE,
		price = 50,
		place = "ceiling",
		size = Vector3.new(1.4, 3, 1.4),
		c1 = "8CC0B4",
		c2 = "D9C9A8",
		tags = { "light" },
		build = function(r: R)
			-- an old glass fishing float (c1) in a knotted rope net (c2), hung from the ceiling
			-- on a rope and glowing from inside
			r:cyl(0, -0.05, 0, 0.1, 0.36, "y", shade(r.c2, 0.85), "Fabric")
			r:cyl(0, -0.9, 0, 1.6, 0.07, "y", r.c2, "Fabric")
			r:ball(0, -1.74, 0, 0.18, r.c2, "Fabric")
			r:glow(r:ball(0, -2.3, 0, 1.0, r.c1, "Glass"), 14, 1.0)
			r:piece(function(q: R)
				q:box(0, -1.82, 0, 0.08, 0.06, 0.08, r.c2, "Fabric")
				ring(q, V(0, -2.05, 0), X, Z, 0.5, 0.07, 8, flat(r.c2), "Fabric")
				ring(q, V(0, -2.55, 0), X, Z, 0.5, 0.07, 8, flat(r.c2), "Fabric")
				for k = 0, 3 do
					local a = k / 4 * math.pi * 2 + math.pi / 8
					local u = V(math.cos(a), 0, math.sin(a))
					q:beam(V(0, -1.8, 0), V(0, -2.05, 0) + u * 0.5, 0.06, 0.06, r.c2, "Fabric")
					q:beam(V(0, -2.05, 0) + u * 0.5, V(0, -2.55, 0) + u * 0.5, 0.06, 0.06, r.c2, "Fabric")
				end
				q:add({
					shape = "Cone",
					cf = CFrame.new(0, -2.9, 0) * CFrame.Angles(math.pi, 0, 0),
					size = Vector3.new(0.14, 0.2, 0.14),
					color = r.c2,
					mat = "Fabric",
				})
			end)
		end,
	},
	{
		id = "sea_bulkhead",
		name = "Bulkhead light",
		cat = "lights",
		style = STYLE,
		price = 35,
		place = "wall",
		size = Vector3.new(1.2, 1.4, 0.6),
		c1 = "4F6F7A",
		c2 = "F2E8C8",
		tags = { "light" },
		build = function(r: R)
			-- a ship's round wall light: a cast body (c1) with a rim held by four screws, a
			-- glass lens (c2) and a cage of bars over it
			r:cyl(0, 0.7, 0.12, 0.24, 1.0, "z", r.c1, "Metal")
			r:cyl(0, 0.7, 0.27, 0.06, 0.86, "z", shade(r.c1, 0.85), "Metal")
			r:glow(r:cyl(0, 0.7, 0.33, 0.14, 0.7, "z", r.c2, "Glass"), 12, 1.0)
			for k = 0, 3 do
				local a = k / 4 * math.pi * 2 + math.pi / 4
				r:cyl(math.cos(a) * 0.39, 0.7 + math.sin(a) * 0.39, 0.32, 0.04, 0.07, "z", C.Metal, "Metal")
			end
			r:piece(function(q: R)
				q:block(-0.04, 0.34, 0.43, 0.04, 1.06, 0.47, r.c1, "Metal")
				for _, b in { { 0.5, 0.29 }, { 0.7, 0.36 }, { 0.9, 0.29 } } do
					q:block(-b[2], b[1] - 0.03, 0.43, b[2], b[1] + 0.03, 0.47, r.c1, "Metal")
				end
				for _, s in { -1, 1 } do
					q:block(s * 0.36 - 0.03, 0.67, 0.3, s * 0.36 + 0.03, 0.73, 0.47, r.c1, "Metal")
				end
			end)
		end,
	},

	-- Keeping things ----------------------------------------------------------------------------------
	{
		id = "sea_rod_stand",
		name = "Fishing rod stand",
		cat = "storage",
		style = STYLE,
		price = 75,
		place = "floor",
		size = Vector3.new(2.6, 6.4, 1.6),
		c1 = "9C7A58",
		c2 = "5C7FA3",
		tags = { "storage" },
		build = function(r: R)
			-- a wooden stand (c1) holding three fishing rods upright by their butts and in
			-- clips, each with a reel and its line, a landing net leaning on it and a tackle
			-- box (c2) at its foot
			local dk = shade(r.c1, 0.85)
			r:block(-1.2, 0, -0.6, 1.2, 0.2, 0.3, r.c1, "Wood")
			for _, sx in { -1, 1 } do
				r:block(sx * 1.1 - 0.08, 0.2, -0.5, sx * 1.1 + 0.08, 3.3, -0.34, dk, "Wood")
			end
			r:block(-1.02, 3.0, -0.47, 1.02, 3.2, -0.37, r.c1, "Wood")
			r:block(-1.1, 0.2, -0.3, 1.1, 0.34, 0.1, dk, "Wood")
			local rods = { -0.6, 0, 0.6 }
			for i, x in rods do
				r:cyl(x, 0.345, -0.1, 0.01, 0.16, "y", C.Black, "Wood")
				local butt = V(x, 0.3, -0.1)
				local clip = V(x - 0.02, 3.1, -0.3)
				local tip = V(x - 0.1 + (i - 2) * 0.12, 6.3, -0.52)
				rod(r, butt, clip, 0.1, C.Black, "Rubber")
				rod(r, clip, tip, 0.04, if i == 2 then shade(r.c2, 1.2) else Color3.fromRGB(60, 64, 70), "Wood")
				rod(r, butt + V(0, 0.15, -0.01), butt:Lerp(clip, 0.36), 0.15, Color3.fromRGB(196, 160, 112), "Wood")
				r:block(x - 0.06, 3.02, -0.32, x + 0.06, 3.2, -0.26, C.DarkMetal, "Metal")
				-- the reel and its line up to the tip
				local reel = butt:Lerp(clip, 0.45) + V(0, 0, 0.18)
				r:cyl(reel.X, reel.Y, reel.Z, 0.14, 0.3, "x", C.Metal, "Metal")
				r:block(
					reel.X - 0.03,
					reel.Y - 0.02,
					reel.Z - 0.16,
					reel.X + 0.03,
					reel.Y + 0.02,
					reel.Z - 0.06,
					C.Metal,
					"Metal"
				)
				r:block(
					reel.X + 0.07,
					reel.Y + 0.05,
					reel.Z - 0.02,
					reel.X + 0.11,
					reel.Y + 0.15,
					reel.Z + 0.02,
					C.Black,
					"Rubber"
				)
				rod(r, reel + V(0, 0.15, 0), tip, 0.015, C.White, "Fabric")
			end
			-- the landing net
			r:beam(V(1.05, 0, 0.55), V(1.0, 3.1, 0.05), 0.07, 0.07, Color3.fromRGB(120, 124, 130), "Metal")
			r:piece(function(q: R)
				q:box(1.0, 3.12, 0.05, 0.06, 0.06, 0.06, C.DarkMetal, "Metal")
				ring(q, V(1.0, 3.42, -0.02), Y, Z, 0.32, 0.05, 8, flat(C.DarkMetal), "Metal")
			end)
			r:lump(CFrame.new(1.04, 3.42, 0.08), 0.3, 0.55, 0.4, Color3.fromRGB(64, 100, 110), "Fabric")
			-- the tackle box
			r:block(-0.9, 0.34, 0.12, 0.0, 0.74, 0.62, r.c2, "Wood")
			r:block(-0.94, 0.66, 0.08, 0.04, 0.8, 0.66, shade(r.c2, 0.85), "Wood")
			r:block(-0.6, 0.8, 0.33, -0.3, 0.9, 0.41, C.DarkMetal, "Metal")
			r:block(-0.5, 0.56, 0.62, -0.4, 0.68, 0.66, C.Gold, "Metal")
		end,
	},
	{
		id = "sea_fish_crates",
		name = "Fish crates",
		cat = "storage",
		style = STYLE,
		price = 70,
		place = "floor",
		size = Vector3.new(3.4, 2.2, 1.4),
		c1 = "A88B6A",
		c2 = "5C7FA3",
		tags = { "storage" },
		build = function(r: R)
			-- three slatted fish boxes (c1) with a painted band (c2), two on the ground and one
			-- on top of them, the top one packed with ice and the day's catch
			local function crate(cx: number, cy: number, cz: number)
				r:piece(function(q: R)
					for _, sx in { -1, 1 } do
						for _, sz in { -1, 1 } do
							q:block(
								cx + sx * 0.68,
								cy,
								cz + sz * 0.43,
								cx + sx * 0.8,
								cy + 0.7,
								cz + sz * 0.55,
								shade(r.c1, 0.85),
								"WoodPlanks"
							)
						end
					end
					for k = 0, 2 do
						local y = cy + 0.04 + k * 0.23
						local tone = if k % 2 == 0 then r.c1 else shade(r.c1, 1.06)
						for _, s in { -1, 1 } do
							q:block(cx - 0.68, y, cz + s * 0.46, cx + 0.68, y + 0.18, cz + s * 0.52, tone, "WoodPlanks")
							q:block(cx + s * 0.71, y, cz - 0.43, cx + s * 0.77, y + 0.18, cz + 0.43, tone, "WoodPlanks")
						end
					end
					q:block(
						cx - 0.68,
						cy + 0.02,
						cz - 0.43,
						cx + 0.68,
						cy + 0.06,
						cz + 0.43,
						shade(r.c1, 0.9),
						"WoodPlanks"
					)
					for _, s in { -1, 1 } do
						q:block(
							cx - 0.3,
							cy + 0.3,
							cz + s * 0.52,
							cx + 0.3,
							cy + 0.4,
							cz + s * 0.56,
							r.c2,
							"WoodPlanks"
						)
					end
				end, true)
			end
			crate(-0.85, 0, 0)
			crate(0.85, 0, 0)
			crate(0, 0.7, 0)
			r:block(-0.68, 0.76, -0.43, 0.68, 1.16, 0.43, Color3.fromRGB(214, 232, 240), "Ice")
			r:piece(function(q: R)
				q:box(0, 1.17, 0, 0.1, 0.03, 0.1, Color3.fromRGB(214, 232, 240), "Marble")
				local silver, back = Color3.fromRGB(188, 196, 204), Color3.fromRGB(92, 110, 130)
				for i, f in
					{
						{ -0.32, -0.22, 0.2 },
						{ 0.3, -0.2, -0.15 },
						{ -0.25, 0.12, -0.1 },
						{ 0.28, 0.16, 0.25 },
						{ 0.0, -0.02, 0.05 },
					}
				do
					local cf = CFrame.new(f[1], 1.24 + (i % 2) * 0.04, f[2]) * CFrame.Angles(0, f[3], 0)
					q:lump(cf, 0.7, 0.16, 0.22, silver, "Marble")
					q:lump(cf * CFrame.new(0, 0.05, 0), 0.6, 0.08, 0.12, back, "Marble")
					q:lump(cf * CFrame.new(-0.4, 0, 0), 0.16, 0.06, 0.2, silver, "Marble")
					q:ball(
						(cf * CFrame.new(0.26, 0.03, 0.08)).Position.X,
						(cf * CFrame.new(0.26, 0.03, 0.08)).Position.Y,
						(cf * CFrame.new(0.26, 0.03, 0.08)).Position.Z,
						0.05,
						C.Black,
						"Marble"
					)
				end
			end, nil, "Marble")
		end,
	},
	{
		id = "sea_rope_shelf",
		name = "Rope shelf",
		cat = "storage",
		style = STYLE,
		price = 50,
		place = "wall",
		size = Vector3.new(3, 3.2, 0.9),
		c1 = "B8AE9C",
		c2 = "D8C8A6",
		tags = { "storage", "books" },
		build = function(r: R)
			-- two driftwood planks (c1) hung on ropes (c2) from a hook, knotted under each
			-- plank: jars of sea glass and a little plant on top, books and a shell below
			r:block(-0.1, 2.95, 0, 0.1, 3.1, 0.16, C.DarkMetal, "Metal")
			r:block(-0.05, 2.95, 0.16, 0.05, 3.1, 0.3, C.DarkMetal, "Metal")
			for _, y in { 1.8, 0.5 } do
				r:block(-1.45, y, 0.06, 1.45, y + 0.12, 0.8, if y > 1 then r.c1 else shade(r.c1, 0.94), "Wood")
			end
			for _, s in { -1, 1 } do
				rod(r, V(0, 2.98, 0.24), V(s * 1.28, 1.92, 0.44), 0.05, r.c2, "Fabric")
				r:cyl(s * 1.28, 1.15, 0.44, 1.5, 0.05, "y", r.c2, "Fabric")
				r:ball(s * 1.28, 1.74, 0.44, 0.13, r.c2, "Fabric")
				r:ball(s * 1.28, 0.44, 0.44, 0.13, r.c2, "Fabric")
				r:cyl(s * 1.28, 0.25, 0.44, 0.3, 0.05, "y", r.c2, "Fabric")
			end
			-- jars of sea glass on the top plank
			local glass =
				{ Color3.fromRGB(140, 196, 176), Color3.fromRGB(120, 164, 200), Color3.fromRGB(196, 214, 200) }
			for i, x in { -0.9, -0.5 } do
				r:cyl(x, 2.15, 0.42, 0.42, 0.32, "y", C.Glass, "Glass").transp = 0.5
				r:cyl(x, 2.39, 0.42, 0.06, 0.26, "y", C.Bark, "Wood")
				for k = 0, 2 do
					r:lump(
						CFrame.new(x + (k - 1) * 0.07, 1.98 + k * 0.05, 0.42) * CFrame.Angles(0, k, 0),
						0.12,
						0.08,
						0.1,
						glass[(i + k) % 3 + 1],
						"Glass"
					)
				end
			end
			r:cyl(0.8, 2.06, 0.42, 0.26, 0.36, "y", Color3.fromRGB(184, 118, 90), "Sand")
			r:lump(CFrame.new(0.8, 2.3, 0.42), 0.42, 0.26, 0.4, Color3.fromRGB(120, 168, 120), "Grass")
			r:lump(
				CFrame.new(0.86, 2.42, 0.4) * CFrame.Angles(0, 1, 0),
				0.22,
				0.2,
				0.22,
				Color3.fromRGB(140, 186, 130),
				"Grass"
			)
			-- books lying flat and a conch on the lower plank
			for _, b in
				{ { y = 0.62, x0 = -1.1, c = Color3.fromRGB(92, 128, 160) }, { y = 0.74, x0 = -1.08, c = CORAL } }
			do
				local y, x0, cover = b.y, b.x0, b.c
				r:block(x0, y, 0.16, x0 + 0.8, y + 0.02, 0.72, cover, "Cardboard")
				r:block(x0, y + 0.1, 0.16, x0 + 0.8, y + 0.12, 0.72, cover, "Cardboard")
				r:block(x0, y + 0.02, 0.16, x0 + 0.04, y + 0.1, 0.72, cover, "Cardboard")
				r:block(x0 + 0.04, y + 0.02, 0.18, x0 + 0.77, y + 0.1, 0.69, C.Paper, "Cardboard")
			end
			-- the conch: a fat body whorl with its spire to one side and the canal to the other
			local conch = CFrame.new(0.55, 0.8, 0.45) * CFrame.Angles(0, 0.4, 0)
			r:lump(conch, 0.5, 0.34, 0.36, Color3.fromRGB(240, 206, 186), "Marble")
			r:lump(conch * CFrame.new(0.02, -0.02, 0.1), 0.3, 0.2, 0.2, Color3.fromRGB(232, 160, 150), "Marble")
			r:add({
				shape = "Cone",
				cf = conch * CFrame.new(0.3, 0.04, 0) * CFrame.Angles(0, 0, -math.pi / 2),
				size = Vector3.new(0.24, 0.24, 0.24),
				color = Color3.fromRGB(226, 190, 168),
				mat = "Marble",
			})
			r:add({
				shape = "Cone",
				cf = conch * CFrame.new(-0.3, -0.03, 0) * CFrame.Angles(0, 0, math.pi / 2),
				size = Vector3.new(0.12, 0.22, 0.12),
				color = Color3.fromRGB(226, 190, 168),
				mat = "Marble",
			})
		end,
	},

	-- Small things and the walls ----------------------------------------------------------------------
	{
		id = "sea_shell_bowl",
		name = "Shell bowl",
		gives = "shells", -- holding E gives something (Data/Items.Sources)
		cat = "decor",
		style = STYLE,
		price = 20,
		place = "surface",
		size = Vector3.new(1.4, 0.7, 1.4),
		c1 = "B08A64",
		c2 = "F0D9C8",
		build = function(r: R)
			-- a turned wooden bowl (c1) on a foot with sand in the bottom and shells (c2 and
			-- others) in it: scallops, whelks, a starfish, cowries and a bit of sea glass
			r:cyl(0, 0.03, 0, 0.06, 0.5, "y", shade(r.c1, 0.85), "Wood")
			r:cyl(0, 0.17, 0, 0.22, 1.1, "y", r.c1, "Wood")
			ring(r, V(0, 0.33, 0), X, Z, 0.52, 0.1, 10, flat(shade(r.c1, 1.06)), "Wood")
			r:cyl(0, 0.295, 0, 0.03, 0.96, "y", SAND, "Sand")
			r:piece(function(q: R)
				q:box(-0.2, 0.34, -0.15, 0.1, 0.04, 0.06, shade(r.c2, 0.85), "Marble")
				for _, s in { { -0.2, -0.05, 0.4 }, { 0.22, 0.15, -0.6 } } do
					q:lump(CFrame.new(s[1], 0.35, s[2]) * CFrame.Angles(0.2, s[3], 0), 0.32, 0.09, 0.28, r.c2, "Marble")
				end
				q:box(0.22, 0.34, 0.27, 0.1, 0.04, 0.06, shade(r.c2, 0.85), "Marble")
				for _, w in { { 0.05, -0.25, 0.3 }, { -0.25, 0.25, 2.1 } } do
					q:add({
						shape = "Cone",
						cf = CFrame.new(w[1], 0.4, w[2]) * CFrame.Angles(0, w[3], math.pi / 2),
						size = Vector3.new(0.16, 0.34, 0.16),
						color = Color3.fromRGB(226, 196, 160),
						mat = "Marble",
					})
				end
				for k = 0, 4 do
					local a = k / 5 * math.pi * 2
					q:beam(
						V(0.3, 0.33, -0.18),
						V(0.3 + math.cos(a) * 0.17, 0.33, -0.18 + math.sin(a) * 0.17),
						0.06,
						0.04,
						CORAL,
						"Marble"
					)
				end
				q:lump(CFrame.new(-0.05, 0.36, 0.25), 0.14, 0.1, 0.1, Color3.fromRGB(240, 226, 206), "Marble")
				q:lump(
					CFrame.new(0.1, 0.35, 0.36) * CFrame.Angles(0, 1, 0),
					0.12,
					0.08,
					0.09,
					Color3.fromRGB(214, 160, 120),
					"Marble"
				)
				q:lump(CFrame.new(-0.36, 0.34, -0.28), 0.12, 0.06, 0.09, Color3.fromRGB(140, 196, 176), "Marble")
			end, nil, "Marble")
		end,
	},
	{
		id = "sea_ship_bottle",
		name = "Ship in a bottle",
		cat = "decor",
		style = STYLE,
		price = 35,
		place = "surface",
		size = Vector3.new(2, 1, 0.8),
		c1 = "A8CCB8",
		c2 = "8E6A4A",
		build = function(r: R)
			-- a green glass bottle (c1) lying in a wooden cradle (c2), corked, with a little
			-- sailing ship inside on a painted sea
			r:block(-0.85, 0, -0.3, 0.85, 0.08, 0.3, r.c2, "Wood")
			for _, x in { -0.45, 0.3 } do
				r:block(x - 0.08, 0.08, -0.3, x + 0.08, 0.2, 0.3, shade(r.c2, 0.88), "Wood")
				for _, s in { -1, 1 } do
					r:block(x - 0.08, 0.2, s * 0.22 - 0.06, x + 0.08, 0.4, s * 0.22 + 0.06, shade(r.c2, 0.88), "Wood")
				end
			end
			-- the sea and the ship, then the glass over them
			r:lump(CFrame.new(-0.15, 0.19, 0), 1.0, 0.1, 0.4, SEA, "Glass")
			r:lump(CFrame.new(-0.15, 0.27, 0), 0.56, 0.12, 0.16, Color3.fromRGB(120, 84, 60), "Wood")
			r:block(-0.36, 0.3, -0.06, 0.06, 0.34, 0.06, Color3.fromRGB(150, 110, 80), "Wood")
			for _, m in { { -0.28, 0.58 }, { -0.04, 0.64 } } do
				r:block(m[1] - 0.012, 0.3, -0.012, m[1] + 0.012, m[2], 0.012, Color3.fromRGB(110, 80, 56), "Wood")
				r:block(m[1] - 0.1, 0.38, -0.003, m[1] + 0.1, m[2] - 0.06, 0.003, C.Paper, "Fabric")
			end
			r:tri(V(0.08, 0.32, 0), V(0.08, 0.52, 0), V(0.22, 0.32, 0), 0.006, C.Paper, "Fabric")
			r:block(-0.04, 0.64, -0.002, 0.06, 0.68, 0.002, C.Red, "Fabric")
			r:cyl(-0.15, 0.39, 0, 1.3, 0.62, "x", r.c1, "Glass").transp = 0.6
			r:cyl(0.58, 0.39, 0, 0.16, 0.42, "x", r.c1, "Glass").transp = 0.6
			r:cyl(0.78, 0.39, 0, 0.26, 0.22, "x", r.c1, "Glass").transp = 0.6
			r:cyl(0.95, 0.39, 0, 0.12, 0.2, "x", C.Bark, "Wood")
		end,
	},
	{
		id = "sea_towel",
		name = "Beach towel",
		cat = "decor",
		style = STYLE,
		price = 25,
		place = "floor",
		size = Vector3.new(2.6, 0.5, 5),
		c1 = "E3907E",
		c2 = "F2EEE6",
		tags = { "rug" },
		build = function(r: R)
			-- a striped towel (c1 and c2) laid out with one end rolled for a pillow and a fringe
			-- at the other, sunglasses, a paperback, sun cream and a pair of flip flops on it
			for k = 0, 6 do
				local z1, z2 = -2.3 + k * 0.63, -2.3 + (k + 1) * 0.63
				r:block(-1.1, 0, z1, 1.1, 0.05, z2, if k % 2 == 0 then r.c1 else r.c2, "Fabric")
			end
			r:cyl(0, 0.18, -2.42, 2.2, 0.36, "x", r.c1, "Fabric")
			r:piece(function(q: R)
				for i = 0, 9 do
					local x = -1.0 + i * 0.222
					q:block(x - 0.03, 0, 2.11, x + 0.03, 0.03, 2.3, shade(r.c1, 0.9), "Fabric")
				end
			end)
			-- sunglasses
			r:piece(function(q: R)
				q:box(0.4, 0.07, -1.4, 0.12, 0.03, 0.03, C.Black, "Metal")
				for _, s in { -1, 1 } do
					q:lump(CFrame.new(0.4 + s * 0.15, 0.08, -1.4), 0.2, 0.04, 0.15, C.Black, "Metal")
					q:block(0.4 + s * 0.24 - 0.015, 0.06, -1.4, 0.4 + s * 0.24 + 0.015, 0.09, -1.1, C.Black, "Metal")
				end
			end, nil, "Metal")
			-- the paperback, lying shut
			r:block(-0.75, 0.05, -0.6, -0.25, 0.08, 0.1, SEA, "Fabric")
			r:block(-0.73, 0.08, -0.58, -0.27, 0.14, 0.08, C.Paper, "Cardboard")
			r:block(-0.75, 0.14, -0.6, -0.25, 0.17, 0.1, SEA, "Fabric")
			-- sun cream
			r:boxAt(CFrame.new(0.55, 0.13, 0.4) * CFrame.Angles(0, 0.5, 0), 0.16, 0.16, 0.5, C.Yellow, "Fabric")
			r:boxAt(
				CFrame.new(0.55, 0.13, 0.4) * CFrame.Angles(0, 0.5, 0) * CFrame.new(0, 0, 0.3),
				0.12,
				0.12,
				0.1,
				C.White,
				"Fabric"
			)
			-- flip flops
			for i, p in { { -0.35, 1.4, 0.15 }, { -0.1, 1.5, -0.1 } } do
				local f = CFrame.new(p[1], 0.075, p[2]) * CFrame.Angles(0, p[3], 0)
				r:lump(f, 0.18, 0.05, 0.46, if i == 1 then SEA else shade(SEA, 0.9), "Rubber")
				r:beam(
					(f * CFrame.new(0, 0.02, -0.12)).Position,
					(f * CFrame.new(-0.08, 0.06, 0.05)).Position,
					0.03,
					0.03,
					C.White,
					"Rubber"
				)
				r:beam(
					(f * CFrame.new(0, 0.02, -0.12)).Position,
					(f * CFrame.new(0.08, 0.06, 0.05)).Position,
					0.03,
					0.03,
					C.White,
					"Rubber"
				)
			end
		end,
	},
	{
		id = "sea_porthole_mirror",
		name = "Porthole mirror",
		cat = "walldecor",
		style = STYLE,
		price = 60,
		place = "wall",
		size = Vector3.new(2.4, 2.2, 0.5),
		c1 = "C9A35E",
		c2 = "D2E4EA",
		tags = { "mirror" },
		build = function(r: R)
			-- a brass porthole (c1) for a mirror: a heavy rim with bolts round it, a raised ring
			-- round the glass (c2), a hinge at the left and a clamp at the right
			local cy = 1.1
			r:cyl(0, cy, 0.125, 0.25, 2.0, "z", r.c1, "Metal")
			r:cyl(0, cy, 0.27, 0.04, 1.5, "z", r.c2, "Glass")
			ring(r, V(0, cy, 0.31), X, Y, 0.78, 0.1, 12, flat(shade(r.c1, 1.08)), "Metal")
			for k = 0, 7 do
				local a = k / 8 * math.pi * 2 + math.pi / 8
				r:cyl(math.cos(a) * 0.9, cy + math.sin(a) * 0.9, 0.28, 0.06, 0.1, "z", shade(r.c1, 0.8), "Metal")
			end
			r:boxAt(CFrame.new(0.2, cy + 0.15, 0.315) * CFrame.Angles(0, 0, -0.6), 0.1, 0.9, 0.03, C.White, "Glass")
			for _, y in { cy - 0.3, cy + 0.3 } do
				r:cyl(-1.06, y, 0.18, 0.2, 0.14, "y", shade(r.c1, 0.9), "Metal")
			end
			r:block(-1.06, cy - 0.4, 0.05, -0.98, cy + 0.4, 0.15, shade(r.c1, 0.9), "Metal")
			r:block(0.98, cy - 0.08, 0.1, 1.12, cy + 0.08, 0.3, shade(r.c1, 0.9), "Metal")
			r:cyl(1.05, cy, 0.34, 0.08, 0.16, "z", shade(r.c1, 0.8), "Metal")
		end,
	},
	{
		id = "sea_tide_clock",
		name = "Tide clock",
		cat = "walldecor",
		style = STYLE,
		price = 40,
		place = "wall",
		size = Vector3.new(1.8, 1.8, 0.4),
		c1 = "4F6F7A",
		c2 = "D8C8A6",
		tags = { "clock" },
		build = function(r: R)
			-- a clock that tells the tide: a painted wooden case (c1) inside a rope ring (c2),
			-- a pale face with marks down each side, a wave at the top for high water and a
			-- line at the bottom for low, and one hand
			local cy = 0.9
			r:cyl(0, cy, 0.09, 0.18, 1.5, "z", r.c1, "Wood")
			r:cyl(0, cy, 0.2, 0.04, 1.26, "z", C.Paper, "Cardboard")
			ring(r, V(0, cy, 0.17), X, Y, 0.76, 0.14, 14, function(i: number): Color3
				return if i % 2 == 0 then r.c2 else shade(r.c2, 0.9)
			end, "Fabric")
			local ink = Color3.fromRGB(52, 60, 70)
			r:piece(function(q: R)
				q:box(0, cy - 0.5, 0.235, 0.24, 0.03, 0.03, ink, "Metal")
				for k = 1, 5 do
					for _, s in { -1, 1 } do
						local a = math.pi / 2 - s * k * math.pi / 6
						q:boxAt(
							CFrame.new(math.cos(a) * 0.5, cy + math.sin(a) * 0.5, 0.235) * CFrame.Angles(0, 0, a),
							0.1,
							0.025,
							0.03,
							ink,
							"Metal"
						)
					end
				end
				for k = 0, 2 do
					q:lump(
						CFrame.new(-0.12 + k * 0.12, cy + 0.48 + (k % 2) * 0.03, 0.235),
						0.12,
						0.05,
						0.03,
						SEA,
						"Metal"
					)
				end
			end, nil, "Metal")
			r:beam(V(0, cy, 0.26), V(0.3, cy + 0.38, 0.26), 0.05, 0.03, ink, "Metal")
			r:cyl(0, cy, 0.27, 0.04, 0.08, "z", C.Gold, "Metal")
		end,
	},
	{
		id = "sea_oars",
		name = "Crossed oars",
		cat = "walldecor",
		style = STYLE,
		price = 55,
		place = "wall",
		size = Vector3.new(4.4, 4.6, 0.5),
		c1 = "B08A64",
		c2 = "5C7FA3",
		tags = { "art" },
		build = function(r: R)
			-- two wooden oars (c1) crossed on the wall, blades up with their tips painted (c2),
			-- on two pegs, tied where they cross
			for i, s in { -1, 1 } do
				local z = if i == 1 then 0.14 else 0.3
				local grip = V(-s * 1.55, 0.25, z)
				local tip = V(s * 1.6, 4.35, z)
				local dir = (tip - grip).Unit
				local ang = math.atan2(dir.Y, dir.X)
				r:beam(grip, tip - dir * 1.2, 0.12, 0.12, r.c1, "Wood")
				r:beam(grip, grip + dir * 0.45, 0.18, 0.18, shade(r.c1, 0.8), "Wood")
				local blade = CFrame.new(tip - dir * 0.65) * CFrame.Angles(0, 0, ang)
				r:boxAt(blade, 1.3, 0.48, 0.06, shade(r.c1, 1.06), "Wood")
				r:boxAt(blade * CFrame.new(0.51, 0, 0), 0.36, 0.54, 0.12, r.c2, "Wood")
				r:boxAt(blade * CFrame.new(-0.72, 0, 0), 0.2, 0.2, 0.18, shade(r.c1, 0.9), "Wood")
			end
			for _, x in { -0.9, 0.9 } do
				r:cyl(x, 1.25, 0.04, 0.08, 0.1, "z", C.DarkMetal, "Metal")
			end
			r:ball(0, 2.3, 0.38, 0.22, ROPE, "Fabric")
			r:boxAt(CFrame.new(0, 2.3, 0.22) * CFrame.Angles(0, 0, 0.8), 0.5, 0.08, 0.36, ROPE, "Fabric")
			r:boxAt(CFrame.new(0, 2.3, 0.22) * CFrame.Angles(0, 0, -0.8), 0.5, 0.08, 0.36, ROPE, "Fabric")
		end,
	},
	-- (end of items)
}

return items
