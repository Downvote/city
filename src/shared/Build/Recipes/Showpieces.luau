--!strict
-- The few shapes the showpieces (Data/Buildings/Showpieces) need that nothing else in the
-- catalog has: a windmill's sails, a lighthouse's lantern, a pergola, a stone arch, a great oak to
-- build a treehouse in, a market stall, an observatory's dome, a beacon, a water tank and a few
-- garden things to go round them. Each is sold on its own too. The user: "make much more
-- building types, including decorative ones".
-- c1 is the main colour, c2 the second (a frame, a trim, the flowers).

local Recipe = require(script.Parent.Parent.Recipe)
local Colors = require(script.Parent.Parent.Parent.Util.Colors)
local Geometry = require(script.Parent.Parent.Geometry)

local C = Recipe.Colors

type R = Recipe.Recipe

local function shade(c: Color3, k: number): Color3
	return Colors.shade(c, k)
end

local SUNLIT = Color3.fromRGB(196, 190, 110) -- leaves where the sun catches them lean warm
local STONE = Color3.fromRGB(198, 192, 180)
local IVORY = Color3.fromRGB(236, 228, 210)

-- A round rod from a to b (a cylinder laid along the line).
local function rod(r: R, a: Vector3, b: Vector3, d: number, color: Color3, mat: string?): Recipe.Prim?
	local v = b - a
	local len = v.Magnitude
	if len < 1e-3 then
		return nil
	end
	local x = v / len
	local up = if math.abs(x.Y) > 0.99 then Vector3.zAxis else Vector3.yAxis
	local z = x:Cross(up).Unit
	local y = z:Cross(x).Unit
	return r:add({
		shape = "Cylinder",
		cf = CFrame.fromMatrix((a + b) / 2, x, y, z),
		size = Vector3.new(len, d, d),
		color = color,
		mat = mat or r.mat or "Metal",
	})
end

-- A clump of leaves: a faceted lump squashed and turned its own way.
local function clump(
	r: R,
	x: number,
	y: number,
	z: number,
	w: number,
	h: number,
	d: number,
	turn: number,
	color: Color3
)
	r:lump(CFrame.new(x, y, z) * CFrame.Angles(0.3, turn, -0.25), w, h, d, color, "Grass")
end

-- A climbing rose up a post at (x, z) from y0 to y1: leaves wound round it and a few flowers.
local function climber(r: R, x: number, z: number, y0: number, y1: number, flower: Color3, seed: number)
	local n = math.max(3, math.floor((y1 - y0) / 1.3))
	for i = 0, n - 1 do
		local t = i / (n - 1)
		local a = seed + i * 2.1
		local y = y0 + (y1 - y0) * t
		local ox, oz = math.cos(a) * 0.32, math.sin(a) * 0.32
		clump(r, x + ox, y, z + oz, 0.9, 0.75, 0.8, a, if i % 2 == 0 then C.Leaf else C.DarkLeaf)
		if i % 2 == 1 then
			r:ball(x + ox * 1.9, y + 0.15, z + oz * 1.9, 0.34, flower, "Fabric")
		end
	end
end

local items: { any } = {
	{
		id = "show_mill_sails",
		name = "Windmill sails",
		cat = "decor",
		style = "rustic",
		price = 600,
		place = "floor",
		size = Vector3.new(18, 18, 3),
		c1 = "F2E6CC",
		c2 = "8A6446",
		build = function(r: R)
			-- Four sails on a hub, set across like an X as a mill stands when it rests. Stand it
			-- on the floor of the storey under the cap, its back (-z) on the tower's wall: the
			-- shaft goes into the wall. Each sail is a lattice of bars (c2) on its stock with the
			-- cloth (c1) spread behind it, all four the same way round.
			local hubY, zs = 9, 0.45
			local wood = r.c2
			-- the windshaft, out of the wall to the hub, and the hub's boss with its cap
			r:cyl(0, hubY, -0.6, 1.8, 1.0, "z", shade(wood, 0.8), "Wood")
			r:block(-0.75, hubY - 0.75, zs - 0.45, 0.75, hubY + 0.75, zs + 0.45, shade(wood, 0.85), "Wood")
			r:cyl(0, hubY, zs + 0.6, 0.5, 1.2, "z", C.DarkMetal, "Metal")
			r:ball(0, hubY, zs + 0.85, 0.7, C.DarkMetal, "Metal")
			for i = 0, 3 do
				local turn = CFrame.new(0, hubY, zs) * CFrame.Angles(0, 0, math.rad(45 + 90 * i))
				-- one sail drawn along +x from the hub, its lattice to the +y side of the stock
				local sail = r:piece(function(q: R)
					q:block(0.6, -0.18, -0.18, 9.9, 0.18, 0.18, wood, "Wood")
					q:block(2.6, 2.1, -0.12, 9.9, 2.36, 0.12, wood, "Wood")
					q:block(2.6, 1.08, -0.08, 9.9, 1.22, 0.08, wood, "Wood")
					for k = 0, 9 do
						local x = 2.7 + k * 0.79
						q:block(x - 0.07, 0.18, -0.1, x + 0.07, 2.1, 0.1, wood, "Wood")
					end
				end)
				sail.cf = turn * sail.cf
				local cloth = r:block(2.7, 0.24, -0.32, 9.8, 2.06, -0.2, r.c1, "Fabric")
				cloth.cf = turn * cloth.cf
			end
		end,
	},
	{
		id = "show_lantern",
		name = "Lighthouse lantern",
		cat = "lights",
		style = "seaside",
		price = 700,
		place = "floor",
		size = Vector3.new(9, 10, 9),
		c1 = "F7F3EA",
		c2 = "A85A50",
		tags = { "light" },
		build = function(r: R)
			-- The lamp room for the top of a tower: a round gallery with a rail, the lantern's
			-- low wall (c1), its glazing between iron bars round a big lamp, and the cap (c2)
			-- with a vent ball and a rod on top.
			local iron = C.DarkMetal
			r:cyl(0, 0.25, 0, 0.5, 9, "y", shade(r.c1, 0.9), "Metal")
			-- the rail: twelve stanchions, a top rail and a middle one between them
			local n = 12
			local function at(i: number, rad: number, y: number): Vector3
				local a = i / n * math.pi * 2
				return Vector3.new(math.cos(a) * rad, y, math.sin(a) * rad)
			end
			r:piece(function(q: R)
				for i = 0, n - 1 do
					local p = at(i, 4.15, 0)
					q:block(p.X - 0.07, 0.5, p.Z - 0.07, p.X + 0.07, 3.5, p.Z + 0.07, iron, "Metal")
				end
				for i = 0, n - 1 do
					q:beam(at(i, 4.15, 3.5), at(i + 1, 4.15, 3.5), 0.16, 0.12, iron, "Metal")
				end
			end)
			r:piece(function(q: R)
				local p = at(0, 4.15, 0)
				q:block(p.X - 0.07, 1.8, p.Z - 0.07, p.X + 0.07, 2.2, p.Z + 0.07, iron, "Metal")
				for i = 0, n - 1 do
					q:beam(at(i, 4.15, 2.0), at(i + 1, 4.15, 2.0), 0.1, 0.1, iron, "Metal")
				end
			end)
			-- the lantern's wall and the door through it
			r:cyl(0, 1.25, 0, 1.5, 5.8, "y", r.c1, "Metal")
			r:block(-0.6, 0.5, 2.6, 0.6, 1.9, 2.95, shade(r.c2, 0.85), "Metal")
			-- the glazing, its bars, and the lamp inside it
			local glass = r:cyl(0, 3.8, 0, 3.6, 5.2, "y", C.Glass, "Glass")
			glass.transp = 0.5
			local lamp = r:cyl(0, 3.6, 0, 2.0, 1.6, "y", C.Warm, "Glass")
			r:glow(lamp, 48, 2.2)
			r:cyl(0, 2.3, 0, 0.6, 0.8, "y", iron, "Metal")
			r:piece(function(q: R)
				for i = 0, 7 do
					local a = (i + 0.5) / 8 * math.pi * 2
					local cf = CFrame.new(math.cos(a) * 2.66, 3.8, math.sin(a) * 2.66) * CFrame.Angles(0, -a, 0)
					q:boxAt(cf, 0.16, 3.6, 0.2, iron, "Metal")
				end
				q:block(-0.1, 2.0, -0.1, 0.1, 2.1, 0.1, iron, "Metal")
			end)
			-- the cap
			r:cyl(0, 5.8, 0, 0.4, 6.0, "y", r.c2, "Metal")
			r:cone(0, 7.2, 0, 2.4, 6.4, r.c2, "Metal")
			r:ball(0, 8.6, 0, 0.9, shade(r.c2, 0.85), "Metal")
			r:cyl(0, 9.5, 0, 1.0, 0.1, "y", iron, "Metal")
		end,
	},
	{
		id = "show_pergola",
		name = "Pergola",
		cat = "garden",
		style = "garden",
		price = 360,
		place = "ground",
		size = Vector3.new(8.4, 10, 16),
		c1 = "F4F1EA",
		c2 = "E8A0B4",
		build = function(r: R)
			-- Three pairs of posts on stone pads carry a beam down each side and rafters across
			-- them (c1), with roses (c2) climbing three of the posts and leaves along the beams.
			local zs = { -7.4, 0, 7.4 }
			r:piece(function(q: R)
				for _, x in { -3.6, 3.6 } do
					for _, z in zs do
						q:block(x - 0.5, 0, z - 0.5, x + 0.5, 0.4, z + 0.5, STONE, "Concrete")
					end
				end
			end)
			r:piece(function(q: R)
				for _, x in { -3.6, 3.6 } do
					for _, z in zs do
						q:block(x - 0.28, 0.4, z - 0.28, x + 0.28, 8.4, z + 0.28, r.c1, "Wood")
						-- knee braces into the beam
						for _, dz in { -1, 1 } do
							if math.abs(z + dz * 1.3) < 8 then
								q:beam(
									Vector3.new(x, 7.0, z + dz * 0.2),
									Vector3.new(x, 8.45, z + dz * 1.4),
									0.2,
									0.2,
									r.c1,
									"Wood"
								)
							end
						end
					end
					q:block(x - 0.22, 8.4, -8, x + 0.22, 9.05, 8, r.c1, "Wood")
				end
			end)
			r:piece(function(q: R)
				for k = 0, 9 do
					local z = -7.2 + k * 1.6
					q:block(-4.2, 8.95, z - 0.13, 4.2, 9.45, z + 0.13, r.c1, "Wood")
				end
			end)
			-- roses grown over the top, across the rafters
			for i, p in
				{
					{ -2.2, -6.0 },
					{ 1.4, -4.4 },
					{ 2.4, -2.4 },
					{ -0.6, -1.2 },
					{ 2.6, 1.0 },
					{ -2.8, 3.4 },
					{ 0.8, 5.2 },
					{ -1.4, 6.8 },
				}
			do
				clump(r, p[1], 9.5, p[2], 1.7, 0.7, 1.5, i * 0.9, if i % 2 == 0 then C.Leaf else C.DarkLeaf)
				if i % 3 ~= 0 then
					r:ball(p[1] + 0.4, 9.75, p[2] - 0.3, 0.32, r.c2, "Fabric")
				end
			end
			-- roses up three posts, leaves trailing along the beams
			climber(r, -3.6, -7.4, 1.0, 8.2, r.c2, 0.3)
			climber(r, 3.6, 0, 1.0, 8.2, r.c2, 1.7)
			climber(r, -3.6, 7.4, 1.0, 8.2, r.c2, 2.9)
			for i, z in { -6.4, -4.2, -1.6, 2.4, 4.6, 6.6 } do
				local x = if i % 2 == 0 then 3.6 else -3.6
				clump(r, x, 9.0, z, 1.2, 0.8, 1.6, i, if i % 3 == 0 then C.DarkLeaf else C.Leaf)
				if i % 2 == 1 then
					r:ball(x + 0.3, 8.75, z + 0.4, 0.32, r.c2, "Fabric")
				end
			end
		end,
	},
	{
		id = "show_arch",
		name = "Stone archway",
		cat = "garden",
		style = "rustic",
		price = 420,
		place = "floor",
		size = Vector3.new(10.4, 11.8, 2.6),
		c1 = "D6CCB8",
		c2 = "B4AA98",
		build = function(r: R)
			-- Two piers on plinths carry a round arch of wedge stones (c1) with a keystone, the
			-- walling over it in rubble, and a coping stone (c2) along the top. Ivy climbs the
			-- left pier and over the arch. Walk through it: the opening is 6 wide.
			local dressed = r.c1
			local cy = 7.0 -- the arch springs from here
			local rIn, rOut = 3.0, 4.2
			r:piece(function(q: R)
				for _, s in { -1, 1 } do
					local x0 = s * 3.0
					local x1 = s * 4.9
					local lo, hi = math.min(x0, x1), math.max(x0, x1)
					q:block(lo - 0.15, 0, -1.15, hi + 0.15, 0.8, 1.15, shade(dressed, 0.92), "Limestone")
					q:block(lo, 0.8, -1.0, hi, 6.6, 1.0, dressed, "Limestone")
					q:block(lo - 0.12, 6.6, -1.12, hi + 0.12, cy, 1.12, shade(dressed, 0.92), "Limestone")
				end
			end)
			-- the arch: nine wedge stones between the springings, the middle one the keystone
			local function polar(rad: number, a: number, z: number): Vector3
				return Vector3.new(math.cos(a) * rad, cy + math.sin(a) * rad, z)
			end
			for half = 0, 1 do
				r:piece(function(q: R)
					for i = half * 5, math.min(8, half * 5 + 4) do
						local a0, a1 = i / 9 * math.pi, (i + 1) / 9 * math.pi
						local key = i == 4
						local outR = if key then rOut + 0.35 else rOut
						local tone = if key
							then shade(dressed, 1.05)
							elseif i % 2 == 0 then dressed
							else shade(dressed, 0.93)
						q:quad(
							polar(rIn, a0, 0),
							polar(rIn, a1, 0),
							polar(outR, a1, 0),
							polar(outR, a0, 0),
							2.1,
							tone,
							"Limestone"
						)
					end
					-- (the piece's upright anchor, inside its first stone)
					local a = (half * 5 + 0.5) / 9 * math.pi
					local m = polar(3.6, a, 0)
					q:block(m.X - 0.1, m.Y - 0.1, -0.1, m.X + 0.1, m.Y + 0.1, 0.1, dressed, "Limestone")
				end)
			end
			-- the walling in the spandrels: from each stone's outer edge out to the pier's line or
			-- up to the coping
			local top = 11.2
			local function toFrame(p: Vector3): Vector3
				local dx, dy = p.X, p.Y - cy
				if math.abs(dx) >= dy then
					return Vector3.new(if dx > 0 then 4.9 else -4.9, p.Y, p.Z)
				end
				return Vector3.new(p.X, top, p.Z)
			end
			for half = 0, 1 do
				r:piece(function(q: R)
					for i = half * 5, half * 5 + 3 do
						local a0, a1 = i / 9 * math.pi, (i + 1) / 9 * math.pi
						local p0, p1 = polar(rOut, a0, 0), polar(rOut, a1, 0)
						local f0, f1 = toFrame(p0), toFrame(p1)
						if i == 2 or i == 6 then
							-- (the corner of the frame is between this stone's ends)
							local corner = Vector3.new(if p0.X > 0 then 4.9 else -4.9, top, 0)
							q:tri(p0, p1, corner, 1.8, shade(r.c2, 1.06), "Limestone")
							q:tri(p0, corner, f0, 1.8, shade(r.c2, 1.06), "Limestone")
							q:tri(p1, corner, f1, 1.8, shade(r.c2, 1.06), "Limestone")
						else
							q:quad(p0, p1, f1, f0, 1.8, shade(r.c2, 1.06), "Limestone")
						end
					end
					local m = Vector3.new(if half == 0 then 4.6 else -4.6, top - 0.3, 0)
					q:block(m.X - 0.1, m.Y - 0.1, -0.1, m.X + 0.1, m.Y + 0.1, 0.1, shade(r.c2, 1.06), "Limestone")
				end)
			end
			-- the coping along the top
			r:block(-5.15, top, -1.25, 5.15, top + 0.55, 1.25, r.c2, "Limestone")
			r:block(-4.9, top + 0.55, -1.0, 4.9, top + 0.6, 1.0, shade(r.c2, 0.9), "Limestone")
			-- ivy up the left pier and over the arch
			for i, p in
				{
					{ -4.95, 0.9, 0.6 },
					{ -5.0, 2.2, 0.2 },
					{ -4.9, 3.5, 0.7 },
					{ -5.0, 4.8, 0.1 },
					{ -4.6, 6.1, 0.8 },
					{ -4.2, 7.6, 1.0 },
					{ -3.5, 9.0, 1.05 },
					{ -2.3, 10.2, 1.05 },
					{ -1.0, 10.9, 1.0 },
				}
			do
				clump(r, p[1], p[2], p[3], 1.1, 1.0, 0.7, i * 1.3, if i % 2 == 0 then C.DarkLeaf else C.Leaf)
			end
		end,
	},
	{
		id = "show_great_oak",
		name = "Great oak",
		cat = "garden",
		style = "garden",
		price = 480,
		place = "ground",
		size = Vector3.new(26, 43, 26),
		c1 = "6EA460",
		c2 = "6E4C30",
		tags = { "plant" },
		build = function(r: R)
			-- A huge old oak to build a treehouse round: a broad trunk (c2) on flaring roots
			-- runs up past a platform at the first floor's height, boughs leave it above the
			-- second and hold a wide crown (c1) high over a house's roof. No bough leans out to
			-- the front (-z), so a hut can stand on that side of the trunk; three lower ones
			-- with leaves of their own reach out behind and to the right, over a deck's rail.
			local bark = r.c2
			for i = 0, 5 do
				local a = i / 6 * math.pi * 2 + 0.3
				r:beam(
					Vector3.new(0, 1.6, 0),
					Vector3.new(math.cos(a) * 3.4, 0.1, math.sin(a) * 3.4),
					1.0,
					0.8,
					bark,
					"Wood"
				)
			end
			r:cyl(0, 2, 0, 4, 4.0, "y", bark, "Wood")
			r:cyl(0, 15, 0, 22, 3.3, "y", bark, "Wood")
			r:cyl(0, 27.5, 0, 3, 2.8, "y", shade(bark, 1.05), "Wood")
			-- a few knots and a hollow on the trunk
			r:lump(CFrame.new(1.4, 6.5, 0.9) * CFrame.Angles(0, 0.6, 0), 0.9, 1.1, 0.7, shade(bark, 0.85), "Wood")
			r:lump(CFrame.new(-1.3, 9.5, -1.0) * CFrame.Angles(0, 2.2, 0), 0.8, 0.9, 0.7, shade(bark, 0.85), "Wood")
			r:lump(CFrame.new(0.2, 4.2, 1.72) * CFrame.Angles(0, 0, 0), 0.8, 1.2, 0.3, shade(bark, 0.5), "Wood")
			-- the boughs, rising steeply out to the crown
			local boughs = {
				{ 23, 0.3, 7.6, 33, 1.3 },
				{ 24, 1.5, 7.2, 34, 1.2 },
				{ 25, 2.6, 7.4, 33.5, 1.2 },
				{ 26, 3.5, 6.4, 35, 1.0 },
				{ 27, 6.0, 5.0, 37, 0.9 },
			}
			for _, b in boughs do
				local a = b[2]
				rod(
					r,
					Vector3.new(0, b[1], 0),
					Vector3.new(math.cos(a) * b[3], b[4], math.sin(a) * b[3]),
					b[5],
					bark,
					"Wood"
				)
			end
			-- two lower boughs out to the back and one to the side, each with its own clump of leaves
			for _, lb in { { 1.2, 5.6, 16, 21 }, { 2.1, 5.0, 17, 22 }, { 0.3, 6.0, 18, 23 } } do
				local a, reach = lb[1], lb[2]
				local tip = Vector3.new(math.cos(a) * reach, lb[4], math.sin(a) * reach)
				rod(r, Vector3.new(0, lb[3], 0), tip, 0.7, bark, "Wood")
				clump(r, tip.X, tip.Y + 0.6, tip.Z, 4.6, 3.4, 4.2, a, shade(r.c1, 0.86))
			end
			-- the crown: a ring of clumps low down, a ring above it and a top, darker underneath
			local under = shade(r.c1, 0.74)
			local lit = Colors.mix(r.c1, SUNLIT, 0.3)
			for i = 0, 7 do
				local a = i / 8 * math.pi * 2 + 0.2
				local rad = 7.8 + (i % 2) * 1.0
				clump(r, math.cos(a) * rad, 32.8 + (i % 3) * 0.6, math.sin(a) * rad, 7.4, 5.2, 7.0, a, under)
			end
			for i = 0, 5 do
				local a = i / 6 * math.pi * 2 + 0.7
				clump(r, math.cos(a) * 5.4, 37.2, math.sin(a) * 5.4, 7.6, 5.6, 7.2, a * 1.3, r.c1)
			end
			clump(r, 0, 35.3, 0, 10, 6.5, 10, 0.4, shade(r.c1, 0.9))
			clump(r, 0.6, 40.0, -0.4, 7.4, 5.0, 7.0, 1.1, lit)
		end,
	},
	{
		id = "show_stall",
		name = "Market stall",
		cat = "decor",
		style = "rustic",
		price = 280,
		place = "floor",
		size = Vector3.new(6.6, 8.4, 4.8),
		c1 = "D98B7A",
		c2 = "C49A6C",
		surface = 3.3,
		build = function(r: R)
			-- A wooden stall (c2) with a counter across the front (+z) to set things out on,
			-- a shelf behind with two baskets of apples, and a striped canopy (c1 and cream)
			-- sloping down to a scalloped edge over the counter.
			local wood = r.c2
			local dk = shade(wood, 0.82)
			r:piece(function(q: R)
				for _, x in { -3.0, 3.0 } do
					q:block(x - 0.15, 0, -2.05, x + 0.15, 8.0, -1.75, wood, "Wood")
					q:block(x - 0.15, 0, 1.75, x + 0.15, 7.0, 2.05, wood, "Wood")
					q:block(x - 0.12, 6.9, -1.9, x + 0.12, 7.1, 1.9, dk, "Wood")
				end
				-- the counter: its front boards, the top and a foot rail
				for k = 0, 5 do
					local x0 = -2.85 + k * 0.95
					q:block(x0, 0.3, 1.55, x0 + 0.9, 3.1, 1.75, if k % 2 == 0 then wood else shade(wood, 0.94), "Wood")
				end
				q:block(-2.85, 0.3, 0.6, 2.85, 3.1, 1.55, dk, "Wood")
				q:block(-3.22, 3.1, 0.5, 3.22, 3.3, 2.15, shade(wood, 1.06), "Wood")
				q:block(-2.85, 0, 0.6, 2.85, 0.3, 1.8, dk, "Wood")
				-- the shelf at the back on its brackets
				q:block(-2.85, 2.2, -1.75, 2.85, 2.4, -0.85, wood, "Wood")
				for _, x in { -2.4, 0, 2.4 } do
					q:block(x - 0.1, 0, -1.65, x + 0.1, 2.2, -1.45, dk, "Wood")
				end
				q:block(-2.85, 3.6, -1.95, 2.85, 3.8, -1.75, dk, "Wood")
			end)
			-- two baskets of apples on the shelf
			for i, x in { -1.4, 1.3 } do
				r:cyl(x, 2.75, -1.3, 0.7, 1.3, "y", Color3.fromRGB(180, 140, 92), "Fabric")
				for k = 0, 3 do
					local a = k * 1.6 + i
					r:ball(
						x + math.cos(a) * 0.3,
						3.15,
						-1.3 + math.sin(a) * 0.3,
						0.42,
						if i == 1 then C.Red else Color3.fromRGB(150, 186, 92),
						"Fabric"
					)
				end
			end
			-- the canopy: eight stripes sloping from the back down to the front
			local function slope(z: number): number
				return 8.15 - (z + 2.3) * (1.15 / 4.6)
			end
			for k = 0, 7 do
				local x0 = -3.3 + k * 0.825
				local col = if k % 2 == 0 then r.c1 else IVORY
				r:quad(
					Vector3.new(x0, slope(-2.3), -2.3),
					Vector3.new(x0 + 0.825, slope(-2.3), -2.3),
					Vector3.new(x0 + 0.825, slope(2.3), 2.3),
					Vector3.new(x0, slope(2.3), 2.3),
					0.12,
					col,
					"Fabric"
				)
				-- the scalloped edge hanging over the front
				local front = slope(2.3)
				r:block(x0 + 0.03, front - 0.5, 2.28, x0 + 0.795, front - 0.02, 2.36, col, "Fabric")
				r:tri(
					Vector3.new(x0 + 0.03, front - 0.5, 2.32),
					Vector3.new(x0 + 0.795, front - 0.5, 2.32),
					Vector3.new(x0 + 0.4125, front - 0.85, 2.32),
					0.08,
					col,
					"Fabric"
				)
			end
		end,
	},
	{
		id = "show_dome",
		name = "Observatory dome",
		cat = "decor",
		style = "scifi",
		price = 900,
		place = "floor",
		size = Vector3.new(12, 9.2, 12),
		c1 = "E4E6EA",
		c2 = "46608E",
		build = function(r: R)
			-- A round dome of metal panels (c1) on a low drum, its slit open to the front (+z)
			-- with a big telescope (c2) looking out of it. Stand it on a flat roof.
			local R0 = 5.6
			local cy = 1.0
			local segs = 12
			local rings = { 0, math.rad(32), math.rad(62) }
			local function pt(ring: number, k: number): Vector3
				local el = if ring > #rings then math.pi / 2 else rings[ring]
				local az = math.rad(-15 + 30 * k)
				return Vector3.new(
					math.cos(el) * math.sin(az) * R0,
					cy + math.sin(el) * R0,
					math.cos(el) * math.cos(az) * R0
				)
			end
			r:cyl(0, 0.3, 0, 0.6, 11.8, "y", shade(r.c1, 0.8), "Metal")
			r:cyl(0, 0.8, 0, 0.4, 11.4, "y", shade(r.c1, 0.9), "Metal")
			local apex = Vector3.new(0, cy + R0, 0)
			local out = Vector3.new(0, 1, 0)
			for k = 1, segs - 1, 2 do
				r:piece(function(q: R)
					for kk = k, math.min(k + 1, segs - 1) do
						local tone = if kk % 2 == 0 then r.c1 else shade(r.c1, 0.95)
						for ring = 1, 2 do
							local p1, p2 = pt(ring, kk), pt(ring, kk + 1)
							local p3, p4 = pt(ring + 1, kk + 1), pt(ring + 1, kk)
							local mid = (p1 + p2 + p3 + p4) / 4 - Vector3.new(0, cy, 0)
							for _, w in Geometry.quad(p1, p2, p3, p4, 0.28, tone, "Metal", mid) do
								q:add(w)
							end
						end
						local p1, p2 = pt(3, kk), pt(3, kk + 1)
						for _, w in Geometry.tri(p1, p2, apex, 0.28, tone, "Metal", out) do
							q:add(w)
						end
					end
					q:block(-0.1, 0.4, -0.1, 0.1, 0.6, 0.1, r.c1, "Metal")
				end)
			end
			-- ribs down the seams and round the slit, darker
			for half = 0, 1 do
				r:piece(function(q: R)
					for k = 1 + half * 6, math.min(segs - 1, 6 + half * 6) do
						for ring = 1, 3 do
							local a = pt(ring, k)
							local b = if ring == 3 then apex else pt(ring + 1, k)
							local n = ((a + b) / 2 - Vector3.new(0, cy, 0)).Unit * 0.16
							q:beam(a + n, b + n, 0.14, 0.12, shade(r.c1, 0.72), "Metal")
						end
					end
					q:block(-0.1, 0.4, -0.1, 0.1, 0.6, 0.1, r.c1, "Metal")
				end)
			end
			-- the telescope on its pier, its tube out of the slit
			r:cyl(0, 1.6, 0, 1.2, 1.4, "y", shade(r.c1, 0.7), "Metal")
			r:block(-0.5, 2.2, -0.5, 0.5, 2.8, 0.5, C.DarkMetal, "Metal")
			local up = math.rad(48)
			local dir = Vector3.new(0, math.sin(up), math.cos(up))
			local pivot = Vector3.new(0, 3.0, 0)
			rod(r, pivot - dir * 1.6, pivot + dir * 6.6, 1.1, r.c2, "Metal")
			rod(r, pivot + dir * 5.6, pivot + dir * 7.0, 1.3, shade(r.c2, 0.8), "Metal")
			rod(r, pivot - dir * 1.9, pivot - dir * 1.5, 1.2, C.DarkMetal, "Metal")
			local lens = rod(r, pivot + dir * 6.98, pivot + dir * 7.04, 1.0, C.Glass, "Glass")
			if lens then
				lens.transp = 0.3
			end
		end,
	},
	{
		id = "show_telescope",
		name = "Telescope",
		cat = "fun",
		style = "fancy",
		price = 260,
		place = "floor",
		size = Vector3.new(2.8, 5.4, 4.2),
		c1 = "D4AE5E",
		c2 = "9A6B48",
		build = function(r: R)
			-- A brass telescope (c1) on a wooden tripod (c2), looking up over the garden to the
			-- front: the tube with its dew cap, a little finder on top and the eyepiece behind.
			local head = Vector3.new(0, 3.7, 0)
			for i = 0, 2 do
				local a = i / 3 * math.pi * 2 + math.pi / 2
				local foot = Vector3.new(math.cos(a) * 1.2, 0, math.sin(a) * 1.2)
				r:beam(head - Vector3.new(0, 0.2, 0), foot, 0.2, 0.2, r.c2, "Wood")
				r:block(foot.X - 0.14, 0, foot.Z - 0.14, foot.X + 0.14, 0.08, foot.Z + 0.14, C.DarkMetal, "Metal")
			end
			r:cyl(0, 3.7, 0, 0.4, 0.7, "y", C.DarkMetal, "Metal")
			r:block(-0.25, 3.9, -0.25, 0.25, 4.2, 0.25, C.DarkMetal, "Metal")
			local up = math.rad(28)
			local dir = Vector3.new(0, math.sin(up), math.cos(up))
			local pivot = Vector3.new(0, 4.45, 0.1)
			rod(r, pivot - dir * 1.3, pivot + dir * 1.9, 0.5, r.c1, "Metal")
			rod(r, pivot + dir * 1.5, pivot + dir * 2.2, 0.62, shade(r.c1, 0.85), "Metal")
			rod(r, pivot - dir * 1.5, pivot - dir * 1.25, 0.56, shade(r.c1, 0.85), "Metal")
			rod(r, pivot - dir * 1.9, pivot - dir * 1.45, 0.22, C.DarkMetal, "Metal")
			local lift = Vector3.new(0, math.cos(up), -math.sin(up)) * 0.42
			rod(r, pivot + lift, pivot + lift + dir * 0.8, 0.16, C.DarkMetal, "Metal")
			r:beam(pivot + lift * 0.4, pivot + lift * 0.9, 0.1, 0.1, C.DarkMetal, "Metal")
		end,
	},
	{
		id = "show_beacon",
		name = "Signal beacon",
		cat = "lights",
		style = "scifi",
		price = 650,
		place = "floor",
		size = Vector3.new(6, 16, 6),
		c1 = "E8ECEF",
		c2 = "7FD8F0",
		tags = { "light" },
		build = function(r: R)
			-- A white lattice mast (c1) on a round plinth with glowing collars and a lit orb
			-- (c2) at the top, a dish half way up and a red light on its very tip.
			r:cyl(0, 0.3, 0, 0.6, 5.8, "y", shade(r.c1, 0.85), "Metal")
			r:cyl(0, 0.75, 0, 0.3, 4.6, "y", r.c1, "Metal")
			local band = r:cyl(0, 0.45, 0, 0.1, 5.96, "y", r.c2, "Neon")
			r:glow(band, 0)
			local function leg(sx: number, sz: number, y: number): Vector3
				local t = (y - 0.9) / 11.1
				local s = 1.6 - 1.05 * t
				return Vector3.new(sx * s, y, sz * s)
			end
			local corners = { { 1, 1 }, { -1, 1 }, { -1, -1 }, { 1, -1 } }
			r:piece(function(q: R)
				q:block(-0.15, 0.85, -0.15, 0.15, 0.95, 0.15, r.c1, "Metal")
				for _, c in corners do
					q:beam(leg(c[1], c[2], 0.9), leg(c[1], c[2], 12), 0.28, 0.28, r.c1, "Metal")
				end
				for _, y in { 4, 7, 10 } do
					for i = 1, 4 do
						local a, b = corners[i], corners[i % 4 + 1]
						q:beam(leg(a[1], a[2], y), leg(b[1], b[2], y), 0.16, 0.16, r.c1, "Metal")
					end
				end
			end)
			r:piece(function(q: R)
				q:block(-0.15, 0.85, -0.15, 0.15, 0.95, 0.15, r.c1, "Metal")
				for _, span in { { 1, 4 }, { 4, 7 }, { 7, 10 } } do
					for i = 1, 4 do
						local a, b = corners[i], corners[i % 4 + 1]
						q:beam(leg(a[1], a[2], span[1]), leg(b[1], b[2], span[2]), 0.1, 0.1, shade(r.c1, 0.9), "Metal")
					end
				end
			end)
			-- glowing collars round the mast
			for _, y in { 5.5, 8.5 } do
				local s = 1.6 - 1.05 * (y - 0.9) / 11.1
				local collar = r:cyl(0, y, 0, 0.18, s * 2 + 0.9, "y", r.c2, "Neon")
				r:glow(collar, 0)
			end
			-- the dish, turned out to the front and up
			local dishCf = CFrame.new(0, 9.2, 1.0) * CFrame.Angles(math.rad(-60), 0, 0)
			r:add({ shape = "Cone", cf = dishCf, size = Vector3.new(2.6, 0.7, 2.6), color = r.c1, mat = "Metal" })
			r:boxAt(dishCf * CFrame.new(0, 0.7, 0), 0.08, 1.0, 0.08, C.DarkMetal, "Metal")
			-- the top: a pod, the lit orb, the aerial and its red tip
			r:cyl(0, 12.4, 0, 0.8, 1.6, "y", r.c1, "Metal")
			r:cyl(0, 12.85, 0, 0.1, 1.9, "y", shade(r.c1, 0.8), "Metal")
			local orb = r:ball(0, 13.75, 0, 1.6, r.c2, "Neon")
			r:glow(orb, 36, 2, r.c2)
			r:cyl(0, 14.6, 0, 0.3, 0.6, "y", shade(r.c1, 0.8), "Metal")
			r:cyl(0, 15.2, 0, 1.0, 0.1, "y", C.DarkMetal, "Metal")
			local tip = r:ball(0, 15.75, 0, 0.3, C.Red, "Neon")
			r:glow(tip, 0)
		end,
	},
	{
		id = "show_water_tank",
		name = "Water tank",
		cat = "garden",
		style = "rustic",
		price = 520,
		place = "floor",
		size = Vector3.new(10.4, 10.8, 10.4),
		c1 = "B98E62",
		c2 = "7A8C7A",
		build = function(r: R)
			-- A wooden tank (c1) on three sleepers, held in by iron hoops, under a pointed lid
			-- (c2) with a finial. A ladder runs up its side to the lid and a pipe with a spout
			-- comes out at the foot.
			local iron = C.DarkMetal
			r:piece(function(q: R)
				for _, z in { -3, 0, 3 } do
					q:block(-4.4, 0, z - 0.35, 4.4, 0.4, z + 0.35, shade(r.c1, 0.7), "Wood")
				end
			end)
			r:cyl(0, 3.9, 0, 7.0, 9.0, "y", r.c1, "Wood")
			for _, y in { 1.4, 3.9, 6.4 } do
				r:cyl(0, y, 0, 0.24, 9.25, "y", iron, "Metal")
			end
			r:cyl(0, 7.5, 0, 0.2, 9.6, "y", shade(r.c1, 0.8), "Wood")
			r:cone(0, 8.9, 0, 2.6, 9.8, r.c2, "Wood")
			r:ball(0, 10.4, 0, 0.6, shade(r.c2, 0.8), "Wood")
			-- the ladder up the right side to the lid
			r:piece(function(q: R)
				for _, z in { -0.55, 0.55 } do
					q:block(4.75, 0.4, z - 0.08, 4.91, 8.2, z + 0.08, iron, "Metal")
				end
				for k = 0, 9 do
					local y = 1.0 + k * 0.75
					q:block(4.77, y - 0.04, -0.55, 4.89, y + 0.04, 0.55, iron, "Metal")
				end
				q:block(4.5, 7.6, -0.6, 4.75, 7.7, 0.6, iron, "Metal")
			end)
			-- the pipe out of the foot, with its spout turned down
			r:cyl(-4.6, 0.95, 1.6, 0.8, 0.5, "x", iron, "Metal")
			r:cyl(-5.0, 0.7, 1.6, 0.6, 0.45, "y", iron, "Metal")
			r:block(-5.15, 0.6, 1.4, -4.85, 1.2, 1.8, iron, "Metal")
		end,
	},
	{
		id = "show_urn",
		name = "Garden urn",
		cat = "garden",
		style = "fancy",
		price = 90,
		place = "ground",
		size = Vector3.new(2.6, 4.8, 2.6),
		c1 = "D6CCB8",
		c2 = "E08566",
		tags = { "plant" },
		build = function(r: R)
			-- A stone urn (c1) on a pedestal, planted with flowers (c2) and ivy over its lip.
			local s = r.c1
			r:block(-1.0, 0, -1.0, 1.0, 0.3, 1.0, shade(s, 0.9), "Limestone")
			r:block(-0.8, 0.3, -0.8, 0.8, 1.9, 0.8, s, "Limestone")
			r:block(-0.95, 1.9, -0.95, 0.95, 2.15, 0.95, shade(s, 0.92), "Limestone")
			r:cyl(0, 2.3, 0, 0.3, 0.9, "y", s, "Limestone")
			r:cyl(0, 2.6, 0, 0.3, 0.55, "y", shade(s, 0.95), "Limestone")
			r:lump(CFrame.new(0, 3.3, 0), 2.0, 1.4, 2.0, s, "Limestone")
			r:cyl(0, 3.92, 0, 0.2, 2.1, "y", shade(s, 0.92), "Limestone")
			r:cyl(0, 4.04, 0, 0.06, 1.8, "y", C.Soil, "Grass")
			for i = 0, 4 do
				local a = i / 5 * math.pi * 2
				clump(
					r,
					math.cos(a) * 0.5,
					4.2,
					math.sin(a) * 0.5,
					0.7,
					0.5,
					0.7,
					a,
					if i % 2 == 0 then C.Leaf else C.DarkLeaf
				)
				r:ball(math.cos(a + 0.6) * 0.45, 4.5, math.sin(a + 0.6) * 0.45, 0.36, r.c2, "Fabric")
			end
			r:ball(0, 4.6, 0, 0.36, shade(r.c2, 1.1), "Fabric")
			for _, a in { 0.4, 2.5, 4.4 } do
				r:lump(
					CFrame.new(math.cos(a) * 1.08, 3.55, math.sin(a) * 1.08) * CFrame.Angles(0, -a, 0.15),
					0.22,
					0.9,
					0.45,
					C.Leaf,
					"Grass"
				)
			end
		end,
	},
	{
		id = "show_sundial",
		name = "Sundial",
		cat = "garden",
		style = "fancy",
		price = 80,
		place = "ground",
		size = Vector3.new(2.2, 3.8, 2.2),
		c1 = "D6CCB8",
		c2 = "B0894F",
		build = function(r: R)
			-- A stone column (c1) on a step with a bronze dial (c2) on its cap: twelve marks and
			-- the gnomon pointing north (-z).
			local s = r.c1
			r:cyl(0, 0.15, 0, 0.3, 2.2, "y", shade(s, 0.9), "Limestone")
			r:cyl(0, 0.45, 0, 0.3, 1.5, "y", s, "Limestone")
			r:cyl(0, 1.75, 0, 2.3, 0.9, "y", s, "Limestone")
			r:cyl(0, 0.75, 0, 0.2, 1.15, "y", shade(s, 0.95), "Limestone")
			r:cyl(0, 2.85, 0, 0.2, 1.15, "y", shade(s, 0.95), "Limestone")
			r:cyl(0, 3.05, 0, 0.2, 1.7, "y", shade(s, 0.92), "Limestone")
			r:cyl(0, 3.18, 0, 0.06, 1.44, "y", r.c2, "Metal")
			r:piece(function(q: R)
				for i = 0, 11 do
					local a = i / 12 * math.pi * 2
					local cf = CFrame.new(math.cos(a) * 0.6, 3.225, math.sin(a) * 0.6) * CFrame.Angles(0, -a, 0)
					q:boxAt(cf, 0.18, 0.03, 0.05, shade(r.c2, 0.6), "Metal")
				end
				q:block(-0.05, 3.21, -0.05, 0.05, 3.24, 0.05, shade(r.c2, 0.6), "Metal")
			end)
			r:wedge(CFrame.new(0, 3.51, -0.2) * CFrame.Angles(0, math.pi, 0), 0.06, 0.6, 0.6, shade(r.c2, 0.8), "Metal")
		end,
	},
	{
		id = "show_surfboards",
		name = "Surfboard rack",
		cat = "fun",
		style = "seaside",
		price = 140,
		place = "floor",
		size = Vector3.new(4.8, 6.4, 2.6),
		c1 = "8FC3D8",
		c2 = "C49A6C",
		build = function(r: R)
			-- A wooden rack (c2) with three boards leaning on its rail: one in c1, one coral and
			-- one sand, each with a stripe down it and a fin.
			local wood = r.c2
			r:piece(function(q: R)
				for _, x in { -2.1, 2.1 } do
					q:block(x - 0.15, 0, -1.2, x + 0.15, 0.2, 1.2, shade(wood, 0.85), "Wood")
					q:block(x - 0.12, 0.2, -0.95, x + 0.12, 4.2, -0.71, wood, "Wood")
				end
				q:block(-2.3, 4.2, -1.0, 2.3, 4.45, -0.66, wood, "Wood")
				q:block(-2.3, 1.0, -0.95, 2.3, 1.2, -0.71, wood, "Wood")
			end)
			local boards = {
				{ x = -1.4, color = r.c1, tilt = 0.2 },
				{ x = 0, color = Color3.fromRGB(224, 133, 102), tilt = -0.05 },
				{ x = 1.4, color = Color3.fromRGB(240, 220, 170), tilt = 0.15 },
			}
			for _, b in boards do
				local lean = CFrame.new(b.x, 3.05, 0.25) * CFrame.Angles(math.rad(-14), 0, b.tilt)
				r:lump(lean, 1.2, 6.0, 0.22, b.color, "Metal")
				r:lump(lean * CFrame.new(0, 0, 0.15), 0.18, 5.2, 0.06, IVORY, "Metal")
				r:wedge(
					lean * CFrame.new(0, -2.2, 0.32) * CFrame.Angles(0, math.pi / 2, 0),
					0.4,
					0.45,
					0.06,
					shade(b.color, 0.7),
					"Metal"
				)
			end
		end,
	},
	{
		id = "show_glass_roof",
		name = "Glass roof",
		cat = "structure",
		style = "garden",
		price = 420,
		place = "floor",
		size = Vector3.new(17.2, 6.6, 17.2),
		c1 = "F4F1EA",
		c2 = "F4F1EA",
		build = function(r: R)
			-- A glasshouse roof for a room 16 by 16: stand it on the floor above, in the middle
			-- of the room, its ridge running front to back. Two slopes of glass on white glazing
			-- bars (c1), glass gables with their bars over the end walls, a ridge board (c2) with
			-- a finial at each end and a gutter along each eave.
			local eaveY, ridgeY, half = -0.25, 6.0, 8.6
			local function glass(list: { Recipe.Prim })
				for _, p in list do
					p.transp = 0.5
					p.collide = true
				end
			end
			for _, s in { -1, 1 } do
				glass(
					r:quad(
						Vector3.new(s * half, eaveY, -half),
						Vector3.new(s * half, eaveY, half),
						Vector3.new(0, ridgeY, half),
						Vector3.new(0, ridgeY, -half),
						0.12,
						C.Glass,
						"Glass"
					)
				)
				r:piece(function(q: R)
					q:block(s * half - 0.12, eaveY - 0.3, -half, s * half + 0.12, eaveY + 0.05, half, r.c1, "Metal")
					for k = 0, 10 do
						local z = -half + 0.1 + k * (2 * half - 0.2) / 10
						q:beam(
							Vector3.new(s * (half - 0.05), eaveY + 0.12, z),
							Vector3.new(0, ridgeY + 0.12, z),
							0.14,
							0.16,
							r.c1,
							"Metal"
						)
					end
				end, nil, "Metal")
			end
			-- the gables, over the end walls
			local function slopeY(x: number): number
				return ridgeY - (ridgeY - eaveY) * math.abs(x) / half
			end
			for _, zs in { -1, 1 } do
				local z = zs * 8
				glass(
					r:tri(
						Vector3.new(-8.25, 0, z),
						Vector3.new(8.25, 0, z),
						Vector3.new(0, ridgeY - 0.1, z),
						0.1,
						C.Glass,
						"Glass"
					)
				)
				r:piece(function(q: R)
					q:block(-8.3, 0, z - 0.1, 8.3, 0.2, z + 0.1, r.c1, "Metal")
					for _, x in { -6, -3, 0, 3, 6 } do
						q:block(x - 0.07, 0.2, z - 0.08, x + 0.07, slopeY(x) - 0.05, z + 0.08, r.c1, "Metal")
					end
					q:block(-5.4, 2.4, z - 0.08, 5.4, 2.54, z + 0.08, r.c1, "Metal")
				end, nil, "Metal")
			end
			-- the ridge and its finials
			r:block(-0.2, ridgeY, -half - 0.1, 0.2, ridgeY + 0.3, half + 0.1, r.c2, "Metal")
			for _, zs in { -1, 1 } do
				r:ball(0, ridgeY + 0.45, zs * (half - 0.1), 0.36, r.c2, "Metal")
			end
		end,
	},
	{
		id = "show_ladder",
		name = "Ladder",
		cat = "structure",
		style = "rustic",
		price = 40,
		place = "floor",
		size = Vector3.new(2, 12, 1),
		c1 = "9A6B48",
		c2 = "9A6B48",
		build = function(r: R)
			-- A wooden ladder a storey tall, for the side of a platform or a wall: two rails (c1)
			-- with a rung (c2) every foot of the way, its back (-z) against what it climbs.
			r:piece(function(q: R)
				for _, x in { -0.8, 0.8 } do
					q:block(x - 0.12, 0, -0.3, x + 0.12, 12, 0.1, r.c1, "Wood")
				end
				for k = 0, 10 do
					local y = 0.9 + k * 1.05
					q:block(-0.68, y - 0.08, -0.2, 0.68, y + 0.08, 0.0, r.c2, "Wood")
				end
			end)
		end,
	},
}

return items
