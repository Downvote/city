--!strict
-- Stairs, pillars and other pieces of the house itself.
-- Stairs climb one storey (Plot.LevelHeight) from the front (+z, bottom) to the back (-z, top)
-- and cut their footprint out of the floor above.

local Recipe = require(script.Parent.Parent.Recipe)
local Tuning = require(script.Parent.Parent.Parent.Config.Tuning)
local Colors = require(script.Parent.Parent.Parent.Util.Colors)

local C = Recipe.Colors
local H = Tuning.Plot.LevelHeight
local F = Tuning.Plot.Foundation -- a ground floor stands this high
local WALL = Tuning.Plot.WallThickness / 2 -- from a wall's middle line to its face

type R = Recipe.Recipe

local function shade(c: Color3, k: number): Color3
	return Colors.shade(c, k)
end

-- Straight stairs `w` wide and `d` deep rising H, in twelve steps. Each tread (c1) has a nosing
-- over the riser (c2) below it. Closed stairs are housed between two sloping strings (c2) with a
-- handrail on balusters and a newel post at each end; open stairs have no risers and sit on two
-- steel strings set in from the sides. People walk up a hidden ramp, so none of it needs to collide.
local function stairs(r: R, w: number, d: number, rails: boolean)
	local steps = 12
	local run = d / steps
	local rise = H / steps
	local slope = run / rise -- how far back one stud up the stairs goes
	local ramp = r:ramp(-w / 2, 0, -d / 2, w / 2, H, d / 2, false, r.c1, "Wood")
	for _, p in ramp do
		p.transp = 1
	end
	local open = not rails
	local sw = 0.3 -- a string's thickness
	local x0 = if open then w / 2 - 0.08 else w / 2 - sw
	for half = 0, 1 do
		r:piece(function(q: R)
			for i = half * 6 + 1, half * 6 + 6 do
				local top = i * rise
				local zFront = d / 2 - (i - 1) * run
				local zBack = zFront - run
				q:block(-x0, top - (if open then 0.22 else 0.3), zBack, x0, top, zFront + 0.06, r.c1, "Wood")
				if not open then
					q:block(-x0, top - rise, zFront - 0.12, x0, top - 0.3, zFront, r.c2, "Wood")
				end
			end
		end)
	end
	-- the strings: a board along each side, its top a little over the corners of the steps
	r:piece(function(q: R)
		for _, sx in { -1, 1 } do
			if open then
				local x = sx * (w / 2 - 0.7)
				local zt = d / 2 - 0.2 * slope -- where the strings' top edge meets the floor
				q:block(x - 0.12, 0, zt - 1.0, x + 0.12, 0.05, zt + 0.05, r.c2, "Metal")
				q:quad(
					Vector3.new(x, 0, zt),
					Vector3.new(x, H - 0.2, -d / 2 + 0.05),
					Vector3.new(x, H - 1.0, -d / 2 + 0.05),
					Vector3.new(x, 0, zt - 0.8 * slope),
					0.2,
					r.c2,
					"Metal"
				)
			else
				local x = sx * (w / 2 - sw / 2)
				local zc = d / 2 - (H - 1.3) * slope -- where the top edge reaches the floor above
				local zl = d / 2 - 0.5 * slope -- where the bottom edge meets the floor
				q:block(x - sw / 2, 0, d / 2 - 0.4, x + sw / 2, 0.3, d / 2, r.c2, "Wood")
				q:quad(
					Vector3.new(x, 0, d / 2),
					Vector3.new(x, 1.3, d / 2),
					Vector3.new(x, H, zc),
					Vector3.new(x, H, -d / 2),
					sw,
					r.c2,
					"Wood"
				)
				q:quad(
					Vector3.new(x, 0, d / 2),
					Vector3.new(x, H, -d / 2),
					Vector3.new(x, H - 0.5, -d / 2),
					Vector3.new(x, 0, zl),
					sw,
					r.c2,
					"Wood"
				)
			end
		end
	end)
	if rails then
		-- a newel at each end, a baluster on every tread and the rail over them, on both sides
		for _, sx in { -1, 1 } do
			local x = sx * (w / 2 - sw / 2)
			r:piece(function(q: R)
				local zb, zt = d / 2 - 0.3, -d / 2 + 0.3
				q:block(x - 0.22, 0, zb - 0.22, x + 0.22, 4.5, zb + 0.22, r.c2, "Wood")
				q:block(x - 0.27, 4.5, zb - 0.27, x + 0.27, 4.64, zb + 0.27, r.c2, "Wood")
				q:ball(x, 4.78, zb, 0.3, r.c2, "Wood")
				q:block(x - 0.22, H, zt - 0.22, x + 0.22, H + 3.36, zt + 0.22, r.c2, "Wood")
				q:block(x - 0.27, H + 3.36, zt - 0.27, x + 0.27, H + 3.48, zt + 0.27, r.c2, "Wood")
				for i = 1, steps do
					local z = d / 2 - (i - 0.5) * run
					q:block(x - 0.07, i * rise, z - 0.07, x + 0.07, i * rise + 3.2, z + 0.07, r.c2, "Wood")
				end
				local function railY(z: number): number
					return rise + (d / 2 - z) / slope + 2.75
				end
				q:beam(
					Vector3.new(x, railY(zb - 0.22), zb - 0.22),
					Vector3.new(x, railY(zt + 0.22), zt + 0.22),
					0.24,
					0.2,
					r.c2,
					"Wood"
				)
			end)
		end
	end
end

local items: { any } = {
	{
		id = "stairs_straight",
		name = "Stairs",
		cat = "structure",
		price = 300,
		place = "stairs",
		size = Vector3.new(4, H + 3.5, 14),
		c1 = "C99A62",
		c2 = "F7F3EA",
		tags = { "stairs" },
		build = function(r: R)
			stairs(r, 4, 14, true)
		end,
	},
	{
		id = "stairs_wide",
		name = "Wide stairs",
		cat = "structure",
		price = 420,
		place = "stairs",
		size = Vector3.new(6, H + 3.5, 14),
		c1 = "8E6440",
		c2 = "FAF6EC",
		tags = { "stairs" },
		build = function(r: R)
			stairs(r, 6, 14, true)
		end,
	},
	{
		id = "stairs_open",
		name = "Open stairs",
		cat = "structure",
		price = 260,
		place = "stairs",
		size = Vector3.new(4, H, 14),
		c1 = "45454A",
		c2 = "45454A",
		tags = { "stairs" },
		build = function(r: R)
			stairs(r, 4, 14, false)
		end,
	},
	{
		id = "porch_steps",
		name = "Porch steps",
		cat = "structure",
		price = 45,
		place = "floor",
		size = Vector3.new(4, 1, 3),
		c1 = "B4B4B8",
		c2 = "B4B4B8",
		build = function(r: R)
			-- three steps of concrete (c1), each with a slab tread (c2) that overhangs its riser
			for i, s in { { -1.5, -0.44, 0.92 }, { -0.5, 0.56, 0.58 }, { 0.5, 1.5, 0.25 } } do
				r:block(-1.94, 0, s[1], 1.94, s[3], s[2] - 0.06, shade(r.c1, 0.96 + i * 0.02), "Concrete")
				r:block(-2, s[3], s[1], 2, s[3] + 0.08, s[2], r.c2, "Concrete")
			end
		end,
	},
	{
		id = "pillar_round",
		name = "Round pillar",
		cat = "structure",
		price = 80,
		place = "floor",
		size = Vector3.new(2, H, 2),
		c1 = "F7F3EA",
		c2 = "F7F3EA",
		build = function(r: R)
			-- a column: a square plinth, a round base, a shaft (c1) a little narrower at the top
			-- than the bottom, a neck ring, a flared capital and a square top (c2)
			local mid, neck = H * 0.55, H - 1.05
			r:piece(function(q: R)
				q:block(-1, 0, -1, 1, 0.35, 1, r.c2, "Marble")
				q:cyl(0, 0.48, 0, 0.26, 1.76, "y", r.c2, "Marble")
				q:cyl(0, 0.68, 0, 0.14, 1.56, "y", r.c2, "Marble")
				q:cyl(0, (0.75 + mid) / 2, 0, mid - 0.75, 1.4, "y", r.c1, "Marble")
				q:cyl(0, (mid + neck) / 2, 0, neck - mid, 1.32, "y", r.c1, "Marble")
				q:cyl(0, neck + 0.075, 0, 0.15, 1.5, "y", r.c2, "Marble")
				q:cyl(0, neck + 0.4, 0, 0.5, 1.86, "y", r.c2, "Marble")
				q:block(-1, H - 0.4, -1, 1, H, 1, r.c2, "Marble")
			end, true)
		end,
	},
	{
		id = "pillar_square",
		name = "Square post",
		cat = "structure",
		price = 50,
		place = "floor",
		size = Vector3.new(1, H, 1),
		c1 = "AD7E55",
		c2 = "AD7E55",
		build = function(r: R)
			-- a square post on a block foot, with a moulding at each end and a cap
			r:piece(function(q: R)
				q:block(-0.5, 0, -0.5, 0.5, 0.5, 0.5, shade(r.c1, 0.9), "Wood")
				q:block(-0.45, 0.5, -0.45, 0.45, 0.62, 0.45, r.c2, "Wood")
				q:block(-0.38, 0.62, -0.38, 0.38, H - 0.62, 0.38, r.c1, "Wood")
				q:block(-0.45, H - 0.62, -0.45, 0.45, H - 0.5, 0.45, r.c2, "Wood")
				q:block(-0.5, H - 0.5, -0.5, 0.5, H, 0.5, shade(r.c1, 0.9), "Wood")
			end, true)
		end,
	},
	{
		id = "chimney",
		name = "Chimney",
		cat = "structure",
		price = 220,
		place = "floor",
		size = Vector3.new(4, 30, 3),
		c1 = "B8505A",
		c2 = "68686E",
		build = function(r: R)
			-- a brick stack (c1) on a wider foot, with string courses up it, the top stepped out
			-- in two courses under a stone cap (c2), and two clay pots, one of them smoking
			r:block(-2, 0.9, -1.5, 2, 28, 1.5, r.c1, "Brick")
			r:piece(function(q: R)
				q:block(-2.1, 0, -1.6, 2.1, 0.9, 1.6, shade(r.c1, 0.9), "Brick")
				for _, y in { 9.0, 18.0, 25.4 } do
					q:block(-2.08, y, -1.58, 2.08, y + 0.3, 1.58, shade(r.c1, 0.92), "Brick")
				end
				q:block(-2.12, 27.4, -1.62, 2.12, 27.9, 1.62, shade(r.c1, 0.95), "Brick")
				q:block(-2.24, 27.9, -1.74, 2.24, 28.4, 1.74, shade(r.c1, 0.92), "Brick")
			end, true)
			r:block(-2.32, 28.4, -1.82, 2.32, 28.8, 1.82, r.c2, "Concrete")
			r:piece(function(q: R)
				local clay = Color3.fromRGB(196, 116, 84)
				q:block(-1.5, 28.8, -0.6, 1.5, 28.92, 0.6, shade(r.c2, 0.9), "Brick")
				for _, x in { -0.75, 0.75 } do
					q:cyl(x, 29.38, 0, 0.92, 0.64, "y", clay, "Brick")
					q:cyl(x, 29.88, 0, 0.12, 0.8, "y", shade(clay, 0.9), "Brick")
					q:cyl(x, 29.96, 0, 0.06, 0.46, "y", Color3.fromRGB(56, 46, 46), "Brick")
				end
			end)
			local smoke = r:block(0.62, 29.995, -0.12, 0.88, 30.04, 0.12, Color3.fromRGB(56, 46, 46), "SmoothPlastic")
			smoke.effect = "smoke"
		end,
	},
	{
		id = "deck_platform",
		name = "Deck",
		cat = "structure",
		price = 90,
		place = "floor",
		size = Vector3.new(8, 1, 8),
		c1 = "AD7E55",
		c2 = "6E4C34",
		build = function(r: R)
			-- boards (c1) with gaps between them, on joists and posts (c2), with a facing board
			-- round the edge under their ends
			r:piece(function(q: R)
				for _, x in { -3.5, 3.5 } do
					for _, z in { -3.5, 3.5 } do
						q:block(x - 0.4, 0, z - 0.4, x + 0.4, 0.6, z + 0.4, r.c2, "Wood")
					end
				end
				for _, z in { -3.5, 0, 3.5 } do
					q:block(-3.9, 0.25, z - 0.15, 3.9, 0.6, z + 0.15, r.c2, "Wood")
				end
				for _, s in { -1, 1 } do
					q:block(-4, 0.28, s * 3.95 - 0.05, 4, 0.6, s * 3.95 + 0.05, shade(r.c1, 0.85), "Wood")
					q:block(s * 3.95 - 0.05, 0.28, -3.9, s * 3.95 + 0.05, 0.6, 3.9, shade(r.c1, 0.85), "Wood")
				end
			end, true)
			r:piece(function(q: R)
				for i = 0, 7 do
					local x = -4 + i
					q:block(
						x + 0.05,
						0.6,
						-4,
						x + 0.95,
						1,
						4,
						if i % 3 == 1 then shade(r.c1, 0.94) else r.c1,
						"WoodPlanks"
					)
				end
			end, true)
		end,
	},
	{
		id = "porch_post",
		name = "Porch post",
		cat = "structure",
		price = 50,
		place = "floor",
		size = Vector3.new(2.6, H, 1.2),
		c1 = "F7F3EA",
		c2 = "F7F3EA",
		build = function(r: R)
			-- a slim post on a boxed foot, with a collar, a cap and a brace out to each side
			-- under the beam it carries: c1 the post, c2 the foot, the cap and the braces
			r:block(-0.55, 0, -0.55, 0.55, 1.3, 0.55, r.c2, "Wood")
			r:block(-0.62, 1.3, -0.62, 0.62, 1.45, 0.62, shade(r.c2, 0.9), "Wood")
			r:block(-0.35, 1.45, -0.35, 0.35, H - 0.8, 0.35, r.c1, "Wood")
			r:block(-0.45, H - 2.5, -0.45, 0.45, H - 2.35, 0.45, shade(r.c1, 0.9), "Wood")
			r:block(-0.58, H - 0.8, -0.58, 0.58, H - 0.5, 0.58, r.c2, "Wood")
			r:block(-1.3, H - 0.5, -0.4, 1.3, H, 0.4, r.c2, "Wood")
			for _, sx in { -1, 1 } do
				r:beam(Vector3.new(sx * 0.3, H - 2.3, 0), Vector3.new(sx * 1.2, H - 0.55, 0), 0.24, 0.24, r.c2, "Wood")
			end
		end,
	},
	{
		id = "porch_rail",
		name = "Porch rail",
		cat = "structure",
		price = 12,
		place = "floor",
		size = Vector3.new(4, 3.2, 0.5),
		c1 = "F7F3EA",
		c2 = "F7F3EA",
		build = function(r: R)
			-- one length of rail, four studs long: c1 the uprights, c2 the hand rail
			for _, sx in { -1, 1 } do
				r:block(sx * 1.85 - 0.15, 0, -0.15, sx * 1.85 + 0.15, 2.95, 0.15, r.c1, "Wood")
			end
			r:block(-2, 2.95, -0.25, 2, 3.2, 0.25, r.c2, "Wood")
			r:block(-1.7, 0.35, -0.1, 1.7, 0.55, 0.1, r.c1, "Wood")
			for i = 0, 5 do
				local x = -1.4 + i * 0.56
				r:block(x - 0.08, 0.55, -0.08, x + 0.08, 2.95, 0.08, r.c1, "Wood")
			end
		end,
	},
	{
		id = "chimney_hearth",
		name = "Chimney with a fireplace",
		cat = "structure",
		price = 420,
		place = "floor",
		size = Vector3.new(4.4, 23, 3.2),
		c1 = "B0624E",
		c2 = "D6D6D6",
		build = function(r: R)
			-- For a house of one storey. It stands inside against a wall (its back is -z) and goes
			-- up through the roof: a brick breast with an open fire, shoulders, a slimmer stack,
			-- a stone cap and two pots. c1 is the brick, c2 the mantel and the cap.
			local zb, zf, zs = -1.6, 0.9, 0.4 -- the back, the front of the breast, the front of the stack
			r:block(-2, 0, zb, -1.25, 3.7, zf, r.c1, "Brick")
			r:block(1.25, 0, zb, 2, 3.7, zf, r.c1, "Brick")
			r:block(-2, 3.7, zb, 2, 7.2, zf, r.c1, "Brick")
			r:block(-1.25, 0.3, zb, 1.25, 3.7, zb + 0.25, Color3.fromRGB(40, 36, 38), "Slate")
			r:block(-2.2, 0, zf, 2.2, 0.3, 1.6, C.Stone, "Slate")
			r:block(-1.25, 0, zb + 0.25, 1.25, 0.3, zf, shade(C.Stone, 0.75), "Slate")
			r:block(-2.2, 4.4, zf - 0.1, 2.2, 4.75, zf + 0.6, r.c2, "Concrete")
			for _, sx in { -1, 1 } do
				r:tri(
					Vector3.new(sx * 2, 7.2, (zb + zf) / 2),
					Vector3.new(sx * 1.3, 7.2, (zb + zf) / 2),
					Vector3.new(sx * 1.3, 8.4, (zb + zf) / 2),
					zf - zb,
					r.c1,
					"Brick"
				)
			end
			r:wedge(CFrame.new(0, 7.6, (zs + zf) / 2) * CFrame.Angles(0, math.pi, 0), 2.6, 0.8, zf - zs, r.c1, "Brick")
			r:block(-1.3, 7.2, zb, 1.3, 21.4, zs, r.c1, "Brick")
			r:block(-1.42, 21.4, zb - 0.1, 1.42, 21.8, zs + 0.12, shade(r.c1, 0.86), "Brick")
			r:block(-1.55, 21.8, zb - 0.15, 1.55, 22.2, zs + 0.2, r.c2, "Concrete")
			r:piece(function(q: R)
				q:block(-1.1, 22.2, zb + 0.3, 1.1, 22.32, zs - 0.3, Color3.fromRGB(150, 146, 140), "Brick")
				for _, x in { -0.55, 0.55 } do
					q:cyl(x, 22.66, -0.6, 0.68, 0.62, "y", Color3.fromRGB(196, 104, 70), "Brick")
				end
			end)
			local soot = r:block(0.38, 22.97, -0.75, 0.72, 23.04, -0.45, C.Black, "SmoothPlastic")
			soot.effect = "smoke"
			-- the fire: irons, embers that glow after dark and two logs
			r:piece(function(q: R)
				q:block(-0.9, 0.3, -0.9, -0.8, 0.7, 0.5, C.DarkMetal, "Metal")
				q:block(0.8, 0.3, -0.9, 0.9, 0.7, 0.5, C.DarkMetal, "Metal")
				q:block(-0.9, 0.55, -0.2, 0.9, 0.62, -0.1, C.DarkMetal, "Metal")
			end)
			local ember = r:block(-0.8, 0.3, -1.1, 0.8, 0.42, 0.3, Color3.fromRGB(255, 120, 50), "SmoothPlastic")
			r:glow(ember, 16, 1.3, Color3.fromRGB(255, 160, 90))
			r:cyl(0, 0.86, -0.6, 1.6, 0.42, "x", C.Bark, "Wood")
			local top = r:cyl(0, 0.84, -0.12, 1.5, 0.38, "x", shade(C.Bark, 1.15), "Wood")
			r:fire(top)
		end,
	},
	{
		id = "corner_board",
		name = "Corner board",
		cat = "structure",
		price = 12,
		place = "floor",
		size = Vector3.new(1.2, H + F, 1.2),
		c1 = "F7F3EA",
		c2 = "F7F3EA",
		build = function(r: R)
			-- Two boards that wrap the outside corner of a house, from the ground to the eaves.
			-- The corner is the middle of the footprint and the house is behind it and to its
			-- left (-x, -z); turn it for the other corners. c1 the boards, c2 the foot.
			local top = H + F
			r:block(WALL, 0, -0.6, WALL + 0.18, top, WALL + 0.18, r.c1, "Wood")
			r:block(-0.6, 0, WALL, WALL, top, WALL + 0.18, r.c1, "Wood")
			r:block(WALL, 0, -0.68, WALL + 0.34, 1.5, WALL + 0.34, r.c2, "Wood")
			r:block(-0.68, 0, WALL, WALL, 1.5, WALL + 0.34, r.c2, "Wood")
		end,
	},
	{
		id = "stone_footing",
		name = "Stone footing",
		cat = "structure",
		price = 6,
		place = "wall",
		size = Vector3.new(4, 1.3, 0.3),
		c1 = "B4B4B8",
		c2 = "D6D6D6",
		build = function(r: R)
			-- four studs of stone course for the foot of a wall: c1 the stones, laid in two
			-- rows with mortar between them, c2 the ledge on top. Each row is one shade, so two
			-- footings that overlap along a wall still agree where they meet.
			r:piece(function(q: R)
				q:block(-1.94, 0, 0, 1.94, 1.1, 0.12, shade(r.c1, 0.72), "Slate")
				local rows =
					{ { 0.04, 0.54, { -2, -1.05, -0.1, 0.95, 2 } }, { 0.58, 1.05, { -2, -1.5, -0.55, 0.45, 1.4, 2 } } }
				for k, row in rows do
					local xs = row[3]
					for i = 1, #xs - 1 do
						local a = xs[i] + (if i == 1 then 0.02 else 0.03)
						local b = xs[i + 1] - (if i == #xs - 1 then 0.02 else 0.03)
						q:block(a, row[1], 0.05, b, row[2], 0.23, shade(r.c1, if k == 1 then 0.94 else 1.03), "Slate")
					end
				end
			end, true)
			r:block(-2, 1.1, 0, 2, 1.26, 0.27, r.c2, "Concrete")
		end,
	},
	{
		id = "downpipe",
		name = "Drainpipe",
		cat = "structure",
		price = 20,
		place = "wall",
		size = Vector3.new(0.9, 11.8, 0.8),
		c1 = "2F3B35",
		c2 = "2F3B35",
		build = function(r: R)
			-- a rainwater pipe down a wall: a box head under the eaves, the pipe on three
			-- brackets and a shoe that turns out at the foot
			r:block(-0.4, 10.9, 0.02, 0.4, 11.6, 0.62, r.c1, "Metal")
			r:block(-0.46, 11.6, 0, 0.46, 11.72, 0.68, r.c2, "Metal")
			r:cyl(0, 5.85, 0.32, 10.1, 0.34, "y", r.c1, "Metal")
			r:beam(Vector3.new(0, 0.86, 0.3), Vector3.new(0, 0.26, 0.76), 0.34, 0.34, r.c1, "Metal")
			r:piece(function(q: R)
				for _, y in { 2.4, 5.9, 9.4 } do
					q:block(-0.3, y, 0.02, 0.3, y + 0.14, 0.52, C.DarkMetal, "Metal")
				end
			end)
		end,
	},
	{
		id = "doorstep",
		name = "Doorstep",
		cat = "structure",
		price = 20,
		place = "floor",
		size = Vector3.new(6, 1, 2.4),
		c1 = "B4B4B8",
		c2 = "D6D6D6",
		build = function(r: R)
			-- Two low stone steps up to a porch or a door (its back, -z, against the floor it
			-- leads to), with a cheek block either side. c1 the treads, c2 the cheeks.
			r:block(-2.2, 0, -1.2, 2.2, F, 0, r.c1, "Concrete")
			r:block(-2.2, 0, 0, 2.2, F / 2, 1.2, r.c1, "Concrete")
			for _, sx in { -1, 1 } do
				local x1, x2 = math.min(sx * 2.2, sx * 3), math.max(sx * 2.2, sx * 3)
				r:block(x1, 0, -1.2, x2, 0.86, 1.2, r.c2, "Cobblestone")
				r:block(x1 - 0.06, 0.86, -1.26, x2 + 0.06, 1, 1.26, shade(r.c2, 0.9), "Concrete")
			end
		end,
	},
	{
		id = "weathervane",
		name = "Weathervane",
		cat = "structure",
		price = 60,
		place = "floor",
		size = Vector3.new(2.4, 13.4, 2.4),
		c1 = "D4AE5E",
		c2 = "2F3B35",
		build = function(r: R)
			-- For the ridge of a roof: stand it on the floor above the top storey, where the ridge
			-- runs, and the pole (c2) goes up through the roof. Four arms for the winds, an arrow
			-- and a cockerel (c1) that looks along +x.
			r:cyl(0, 6, 0, 12, 0.16, "y", r.c2, "Metal")
			r:piece(function(q: R)
				q:box(0, 11.6, 0, 0.26, 0.26, 0.26, C.DarkMetal, "Metal")
				q:block(-1, 11.57, -0.04, 1, 11.63, 0.04, C.DarkMetal, "Metal")
				q:block(-0.04, 11.57, -1, 0.04, 11.63, 1, C.DarkMetal, "Metal")
				for _, p in { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } } do
					q:box(p[1], 11.75, p[2], 0.16, 0.3, 0.16, C.DarkMetal, "Metal")
				end
			end)
			r:block(-1.1, 12.3, -0.03, 1.0, 12.38, 0.03, r.c1, "Metal")
			r:wedge(
				CFrame.new(1.2, 12.34, 0) * CFrame.Angles(0, math.pi / 2, math.pi / 2),
				0.06,
				0.4,
				0.46,
				r.c1,
				"Metal"
			)
			r:block(-1.1, 12.16, -0.03, -0.8, 12.52, 0.03, r.c1, "Metal")
			r:block(-0.4, 12.38, -0.04, 0.35, 12.86, 0.04, r.c1, "Metal")
			r:block(0.15, 12.8, -0.04, 0.42, 13.25, 0.04, r.c1, "Metal")
			r:block(-0.62, 12.7, -0.04, -0.34, 13.2, 0.04, r.c1, "Metal")
			r:block(0.42, 13.02, -0.03, 0.62, 13.1, 0.03, C.Red, "Metal")
			r:ball(0, 12.1, 0, 0.3, r.c1, "Metal")
		end,
	},
}

return items
