--!strict
-- Doors and windows. These sit in a wall and cut a hole in it the size of `opening`
-- (w wide, h tall, its bottom `sill` above the floor). The frame is drawn in the hole's own space:
-- x along the wall, y up from the hole's bottom, z across the wall (+z faces the side chosen).

local Recipe = require(script.Parent.Parent.Recipe)
local Colors = require(script.Parent.Parent.Parent.Util.Colors)

local C = Recipe.Colors

type R = Recipe.Recipe

local function shade(c: Color3, k: number): Color3
	return Colors.shade(c, k)
end

-- A plain frame round a w x h hole. The frame sits just outside the hole, over the wall, so the
-- full width stays clear to walk through.
local function frame(r: R, w: number, h: number, color: Color3, depth: number?, bottom: boolean?)
	local d = depth or 0.9
	local t = 0.3
	r:block(-w / 2 - t, 0, -d / 2, -w / 2, h + t, d / 2, color, "Wood")
	r:block(w / 2, 0, -d / 2, w / 2 + t, h + t, d / 2, color, "Wood")
	r:block(-w / 2 - t, h, -d / 2, w / 2 + t, h + t, d / 2, color, "Wood")
	if bottom then
		r:block(-w / 2 - t, -t, -d / 2, w / 2 + t, 0, d / 2, color, "Wood")
	end
end

-- A swinging leaf with a knob on both faces. Hinge on the left (-x) unless flipped.
local function leaf(r: R, x1: number, x2: number, h: number, color: Color3, mat: string?, flip: boolean?)
	local hinge = if flip then x2 else x1
	local p = r:block(x1, 0.05, -0.1, x2, h - 0.15, 0.1, color, mat or "Wood")
	r:door(p, hinge)
	local kx = if flip then x1 + 0.45 else x2 - 0.45
	for _, z in { -0.2, 0.2 } do
		local k = r:ball(kx, h * 0.47, z, 0.32, C.Gold, "Metal")
		r:door(k, hinge)
	end
	return p
end

local function sill(r: R, w: number, color: Color3)
	r:block(-w / 2 - 0.3, -0.25, -0.6, w / 2 + 0.3, 0.05, 0.6, color, "Wood")
end

-- A slope over the box x1..x2, y1..y2, z1..z2 that is high along z1 and comes down to nothing
-- along z2, as one wedge. With z1 on the wall and z2 out from it, a little roof.
local function slope(
	r: R,
	x1: number,
	y1: number,
	z1: number,
	x2: number,
	y2: number,
	z2: number,
	color: Color3,
	mat: string
)
	-- a wedge is full height at its own back (+Z), so its back is turned to z1
	local turn = if z2 > z1 then CFrame.Angles(0, math.pi, 0) else CFrame.identity
	r:wedge(
		CFrame.new((x1 + x2) / 2, (y1 + y2) / 2, (z1 + z2) / 2) * turn,
		math.abs(x2 - x1),
		math.abs(y2 - y1),
		math.abs(z2 - z1),
		color,
		mat
	)
end

-- A bracket on a wall item's wall (z = 0) under a shelf at height y: a triangle `drop` tall
-- and `out` deep, as one wedge turned upside down.
local function bracket(r: R, x: number, y: number, drop: number, out: number, color: Color3)
	r:wedge(CFrame.new(x, y - drop / 2, 0.02 + out / 2) * CFrame.Angles(math.pi, 0, 0), 0.16, drop, out, color, "Wood")
end

local items: { any } = {
	{
		id = "door_wood",
		name = "Wooden door",
		cat = "doors",
		price = 120,
		place = "opening",
		size = Vector3.new(4.6, 8.2, 1),
		opening = { w = 4, h = 8, sill = 0 },
		c1 = "AD7E55",
		c2 = "F7F3EA",
		build = function(r: R)
			frame(r, 4, 8, r.c2)
			leaf(r, -1.85, 1.85, 8, r.c1)
		end,
	},
	{
		id = "door_panel",
		name = "Panel door",
		cat = "doors",
		price = 160,
		place = "opening",
		size = Vector3.new(4.6, 8.2, 1),
		opening = { w = 4, h = 8, sill = 0 },
		c1 = "FAF6EC",
		c2 = "F7F3EA",
		build = function(r: R)
			frame(r, 4, 8, r.c2)
			local hinge = -1.85
			local p = r:block(-1.85, 0.05, -0.1, 1.85, 7.85, 0.1, r.c1, "SmoothPlastic")
			r:door(p, hinge)
			-- raised panels on both faces
			for _, z in { -0.13, 0.13 } do
				for _, y in { 1.2, 5.3 } do
					local panel = r:block(-1.3, y - 0.9, z - 0.04, 1.3, y + 1.6, z + 0.04, r.c1, "SmoothPlastic")
					r:door(panel, hinge)
				end
				local k = r:ball(1.4, 3.8, z * 1.6, 0.32, C.Gold, "Metal")
				r:door(k, hinge)
			end
		end,
	},
	{
		id = "door_glass",
		name = "Glass door",
		cat = "doors",
		price = 220,
		place = "opening",
		size = Vector3.new(4.6, 8.2, 1),
		opening = { w = 4, h = 8, sill = 0 },
		c1 = "45454A",
		c2 = "45454A",
		build = function(r: R)
			frame(r, 4, 8, r.c2)
			local hinge = -1.85
			for _, part in
				{
					r:block(-1.85, 0.05, -0.1, -1.45, 7.85, 0.1, r.c1, "Metal"),
					r:block(1.45, 0.05, -0.1, 1.85, 7.85, 0.1, r.c1, "Metal"),
					r:block(-1.45, 0.05, -0.1, 1.45, 0.6, 0.1, r.c1, "Metal"),
					r:block(-1.45, 7.45, -0.1, 1.45, 7.85, 0.1, r.c1, "Metal"),
					r:glass(-1.45, 0.6, -0.05, 1.45, 7.45, 0.05),
					r:block(1.1, 3, -0.25, 1.25, 4.6, 0.25, C.Metal, "Metal"),
				}
			do
				r:door(part, hinge)
			end
		end,
	},
	{
		id = "door_front",
		name = "Front door with window",
		cat = "doors",
		price = 260,
		place = "opening",
		size = Vector3.new(4.6, 8.2, 1),
		opening = { w = 4, h = 8, sill = 0 },
		c1 = "46608E",
		c2 = "FAF6EC",
		build = function(r: R)
			frame(r, 4, 8, r.c2)
			local hinge = -1.85
			for _, part in
				{
					r:block(-1.85, 0.05, -0.1, 1.85, 4.6, 0.1, r.c1, "SmoothPlastic"),
					r:block(-1.85, 6.9, -0.1, 1.85, 7.85, 0.1, r.c1, "SmoothPlastic"),
					r:block(-1.85, 4.6, -0.1, -1.1, 6.9, 0.1, r.c1, "SmoothPlastic"),
					r:block(1.1, 4.6, -0.1, 1.85, 6.9, 0.1, r.c1, "SmoothPlastic"),
					r:glass(-1.1, 4.6, -0.05, 1.1, 6.9, 0.05),
					r:block(-0.05, 4.6, -0.07, 0.05, 6.9, 0.07, r.c2, "Wood"),
					r:ball(1.35, 3.6, 0.2, 0.32, C.Gold, "Metal"),
					r:ball(1.35, 3.6, -0.2, 0.32, C.Gold, "Metal"),
				}
			do
				r:door(part, hinge)
			end
		end,
	},
	{
		id = "door_double",
		name = "Double doors",
		cat = "doors",
		price = 340,
		place = "opening",
		size = Vector3.new(6.6, 8.2, 1),
		opening = { w = 6, h = 8, sill = 0 },
		c1 = "8E6440",
		c2 = "F7F3EA",
		build = function(r: R)
			frame(r, 6, 8, r.c2)
			leaf(r, -2.85, -0.02, 8, r.c1)
			leaf(r, 0.02, 2.85, 8, r.c1, nil, true)
		end,
	},
	{
		id = "door_barn",
		name = "Sliding barn door",
		cat = "doors",
		price = 280,
		place = "opening",
		size = Vector3.new(8.4, 8.8, 1.2),
		opening = { w = 4, h = 8, sill = 0 },
		c1 = "8E4048",
		c2 = "45454A",
		build = function(r: R)
			frame(r, 4, 8, C.Cream)
			-- rail above the hole on the chosen side
			r:block(-4.2, 8.3, 0.45, 4.2, 8.6, 0.6, r.c2, "Metal")
			local p = r:block(-2.2, 0.1, 0.5, 2.2, 8.3, 0.75, r.c1, "WoodPlanks")
			p.role = "door"
			p.collide = false
			p.attrs = { Slide = 4.2 }
			for _, y in { 1.5, 6.9 } do
				local brace = r:block(-2.1, y - 0.2, 0.75, 2.1, y + 0.2, 0.85, C.White, "Wood")
				brace.role = "door"
				brace.collide = false
				brace.attrs = { Slide = 4.2 }
			end
		end,
	},
	{
		id = "door_garage",
		name = "Garage door",
		cat = "doors",
		price = 420,
		place = "opening",
		size = Vector3.new(8.6, 8.2, 1),
		opening = { w = 8, h = 8, sill = 0 },
		c1 = "F7F3EA",
		c2 = "D6D6D6",
		build = function(r: R)
			frame(r, 8, 8, r.c2)
			for i = 0, 3 do
				local y = 0.1 + i * 1.95
				local p = r:block(-3.85, y, -0.12, 3.85, y + 1.9, 0.12, r.c1, "Metal")
				p.role = "door"
				p.collide = false
				p.attrs = { Lift = 7.6 }
			end
		end,
	},
	{
		id = "arch_open",
		name = "Open doorway",
		cat = "doors",
		price = 40,
		place = "opening",
		size = Vector3.new(4.6, 8.2, 1),
		opening = { w = 4, h = 8, sill = 0 },
		c1 = "F7F3EA",
		c2 = "F7F3EA",
		build = function(r: R)
			frame(r, 4, 8, r.c1)
		end,
	},
	{
		id = "arch_wide",
		name = "Wide doorway",
		cat = "doors",
		price = 70,
		place = "opening",
		size = Vector3.new(8.6, 9.2, 1),
		opening = { w = 8, h = 9, sill = 0 },
		c1 = "F7F3EA",
		c2 = "F7F3EA",
		build = function(r: R)
			frame(r, 8, 9, r.c1)
		end,
	},
	-- windows ------------------------------------------------------------------------------
	{
		id = "win_small",
		name = "Small window",
		cat = "windows",
		price = 50,
		place = "opening",
		size = Vector3.new(2.6, 2.6, 1.2),
		opening = { w = 2, h = 2, sill = 5 },
		c1 = "FAF6EC",
		c2 = "FAF6EC",
		build = function(r: R)
			frame(r, 2, 2, r.c1, nil, true)
			r:glass(-1, 0, -0.05, 1, 2, 0.05)
			r:block(-0.05, 0, -0.08, 0.05, 2, 0.08, r.c1, "Wood")
			r:block(-1, 0.95, -0.08, 1, 1.05, 0.08, r.c1, "Wood")
		end,
	},
	{
		id = "win_square",
		name = "Window",
		cat = "windows",
		price = 90,
		place = "opening",
		size = Vector3.new(4.6, 4.6, 1.2),
		opening = { w = 4, h = 4, sill = 3 },
		c1 = "FAF6EC",
		c2 = "FAF6EC",
		build = function(r: R)
			frame(r, 4, 4, r.c1, nil, true)
			sill(r, 4, r.c2)
			r:glass(-2, 0, -0.05, 2, 4, 0.05)
			r:block(-0.08, 0, -0.08, 0.08, 4, 0.08, r.c1, "Wood")
			r:block(-2, 1.92, -0.08, 2, 2.08, 0.08, r.c1, "Wood")
		end,
	},
	{
		id = "win_wide",
		name = "Wide window",
		cat = "windows",
		price = 140,
		place = "opening",
		size = Vector3.new(6.6, 4.6, 1.2),
		opening = { w = 6, h = 4, sill = 3 },
		c1 = "FAF6EC",
		c2 = "FAF6EC",
		build = function(r: R)
			frame(r, 6, 4, r.c1, nil, true)
			sill(r, 6, r.c2)
			r:glass(-3, 0, -0.05, 3, 4, 0.05)
			for _, x in { -1, 1 } do
				r:block(x - 0.08, 0, -0.08, x + 0.08, 4, 0.08, r.c1, "Wood")
			end
		end,
	},
	{
		id = "win_tall",
		name = "Tall window",
		cat = "windows",
		price = 110,
		place = "opening",
		size = Vector3.new(2.6, 6.6, 1.2),
		opening = { w = 2, h = 6, sill = 2 },
		c1 = "FAF6EC",
		c2 = "FAF6EC",
		build = function(r: R)
			frame(r, 2, 6, r.c1, nil, true)
			r:glass(-1, 0, -0.05, 1, 6, 0.05)
			for _, y in { 2, 4 } do
				r:block(-1, y - 0.07, -0.08, 1, y + 0.07, 0.08, r.c1, "Wood")
			end
		end,
	},
	{
		id = "win_picture",
		name = "Picture window",
		cat = "windows",
		price = 240,
		place = "opening",
		size = Vector3.new(8.6, 5.6, 1.2),
		opening = { w = 8, h = 5, sill = 2.5 },
		c1 = "45454A",
		c2 = "45454A",
		build = function(r: R)
			frame(r, 8, 5, r.c1, nil, true)
			r:glass(-4, 0, -0.05, 4, 5, 0.05)
		end,
	},
	{
		id = "win_shutters",
		name = "Window with shutters",
		cat = "windows",
		price = 170,
		place = "opening",
		size = Vector3.new(8.2, 4.6, 1.4),
		opening = { w = 4, h = 4, sill = 3 },
		c1 = "5E8E5A",
		c2 = "FAF6EC",
		build = function(r: R)
			frame(r, 4, 4, r.c2, nil, true)
			sill(r, 4, r.c2)
			r:glass(-2, 0, -0.05, 2, 4, 0.05)
			r:block(-0.08, 0, -0.08, 0.08, 4, 0.08, r.c2, "Wood")
			for _, sx in { -1, 1 } do
				local x1 = sx * 2.25
				local x2 = sx * 4.05
				r:block(math.min(x1, x2), 0, 0.42, math.max(x1, x2), 4, 0.62, r.c1, "Wood")
				for i = 1, 5 do
					local y = i * 0.66
					r:block(
						math.min(x1, x2) + 0.15,
						y - 0.05,
						0.62,
						math.max(x1, x2) - 0.15,
						y + 0.05,
						0.68,
						r.c1,
						"Wood"
					)
				end
			end
		end,
	},
	{
		id = "win_floor",
		name = "Floor to ceiling glass",
		cat = "windows",
		price = 260,
		place = "opening",
		size = Vector3.new(4.6, 10.6, 1.2),
		opening = { w = 4, h = 10, sill = 0.5 },
		c1 = "2A2A2E",
		c2 = "2A2A2E",
		build = function(r: R)
			frame(r, 4, 10, r.c1, nil, true)
			r:glass(-2, 0, -0.05, 2, 10, 0.05)
		end,
	},
	{
		id = "win_porthole",
		name = "Porthole window",
		cat = "windows",
		price = 130,
		place = "opening",
		size = Vector3.new(3.4, 3.4, 1.2),
		opening = { w = 3, h = 3, sill = 4 },
		c1 = "D4AE5E",
		c2 = "F7F3EA",
		build = function(r: R)
			-- a square hole with its corners filled, so the glass reads as round, and a brass ring
			frame(r, 3, 3, r.c2, nil, true)
			r:glass(-1.5, 0, -0.05, 1.5, 3, 0.05)
			local k = 1.0
			for _, c in { { -1.5, 0, 1, 1 }, { 1.5, 0, -1, 1 }, { -1.5, 3, 1, -1 }, { 1.5, 3, -1, -1 } } do
				local x, y, sx, sy = c[1], c[2], c[3], c[4]
				r:tri(
					Vector3.new(x, y, 0),
					Vector3.new(x + sx * k, y, 0),
					Vector3.new(x, y + sy * k, 0),
					0.5,
					r.c2,
					"Wood"
				)
			end
			-- the ring: twelve short brass segments round the glass, on both faces
			local n = 12
			for _, z in { -0.3, 0.3 } do
				for i = 0, n - 1 do
					local a1 = i / n * math.pi * 2
					local a2 = (i + 1) / n * math.pi * 2
					local rad = 1.3
					r:beam(
						Vector3.new(math.cos(a1) * rad, 1.5 + math.sin(a1) * rad, z),
						Vector3.new(math.cos(a2) * rad, 1.5 + math.sin(a2) * rad, z),
						0.2,
						0.25,
						r.c1,
						"Metal"
					)
				end
			end
		end,
	},
	{
		id = "win_bay",
		name = "Bay window",
		cat = "windows",
		price = 250,
		place = "opening",
		size = Vector3.new(6.8, 7.4, 4.4),
		opening = { w = 6, h = 6, sill = 2 },
		c1 = "FAF6EC",
		c2 = "B8505A",
		build = function(r: R)
			-- the hole's own frame, then a bay with slanted sides standing out of the wall on the
			-- side chosen: a seat board, three panes and a little roof of its own (c2)
			frame(r, 6, 6, r.c1, nil, true)
			local W, F = 3, 1.5 -- half the hole's width, half the front pane's
			local Z0, Z1 = 0.3, 1.9 -- the wall's face, the bay's front
			r:block(-W, -0.3, -0.5, W, 0, Z0, r.c1, "Wood")
			r:block(-F, -0.3, Z0, F, 0, Z1, r.c1, "Wood")
			r:block(-F + 0.2, -0.5, Z0, F - 0.2, -0.3, Z1 - 0.35, shade(r.c1, 0.88), "Wood")
			r:block(-F, 4.2, Z1 - 0.26, F, 4.36, Z1 - 0.04, r.c1, "Wood")
			r:block(-0.07, 0, Z1 - 0.24, 0.07, 4.2, Z1 - 0.06, r.c1, "Wood")
			r:block(-F - 0.1, 5.8, Z1 - 0.3, F + 0.1, 6.3, Z1 + 0.05, r.c1, "Wood")
			local front = r:block(-F + 0.14, 0, Z1 - 0.2, F - 0.14, 5.8, Z1 - 0.1, C.Glass, "Glass")
			front.transp = 0.55
			for _, sx in { -1, 1 } do
				r:tri(
					Vector3.new(sx * F, -0.15, Z0),
					Vector3.new(sx * W, -0.15, Z0),
					Vector3.new(sx * F, -0.15, Z1),
					0.3,
					r.c1,
					"Wood"
				)
				r:block(sx * F - 0.14, 0, Z1 - 0.28, sx * F + 0.14, 5.8, Z1, r.c1, "Wood")
				-- the slanted side: a pane, its bar and the board over it, all along the slant
				local along = Vector3.new(sx * (F - W), 0, Z1 - Z0)
				local len = along.Magnitude
				local side =
					CFrame.fromMatrix(Vector3.new(sx * (W + F) / 2, 0, (Z0 + Z1) / 2), along.Unit, Vector3.yAxis)
				local pane = r:boxAt(side * CFrame.new(0, 2.9, 0), len - 0.1, 5.8, 0.1, C.Glass, "Glass")
				pane.transp = 0.55
				r:boxAt(side * CFrame.new(0, 4.28, 0), len, 0.16, 0.2, r.c1, "Wood")
				r:boxAt(side * CFrame.new(0, 6.05, 0), len + 0.25, 0.5, 0.3, r.c1, "Wood")
				r:tri(
					Vector3.new(sx * F, 7.4, Z0),
					Vector3.new(sx * (W + 0.25), 6.3, Z0),
					Vector3.new(sx * F, 6.3, Z1 + 0.25),
					0.2,
					shade(r.c2, 0.9),
					"ClayRoofTiles"
				)
			end
			slope(r, -F, 6.3, Z0, F, 7.4, Z1 + 0.25, r.c2, "ClayRoofTiles")
		end,
	},
	-- things that hang on the wall round a window --------------------------------------------
	{
		id = "shutters",
		name = "Shutters",
		cat = "windows",
		price = 40,
		place = "wall",
		size = Vector3.new(8.2, 4.4, 0.4),
		c1 = "5E8E5A",
		c2 = "3D6650",
		build = function(r: R)
			-- a pair of leaves either side of a window four studs wide: c1 the boards, c2 the slats
			for _, sx in { -1, 1 } do
				local x1, x2 = math.min(sx * 2.4, sx * 4.05), math.max(sx * 2.4, sx * 4.05)
				r:block(x1, 0, 0.02, x2, 4.3, 0.2, r.c1, "Wood")
				for i = 1, 5 do
					local y = i * 0.72 - 0.01
					r:block(x1 + 0.15, y - 0.07, 0.2, x2 - 0.15, y + 0.07, 0.28, r.c2, "Wood")
				end
				-- two iron hinges on the window's side
				local hx = sx * 2.5
				r:piece(function(q: R)
					q:box(hx, 0.7, 0.25, 0.34, 0.2, 0.1, C.DarkMetal, "Metal")
					q:box(hx, 3.6, 0.25, 0.34, 0.2, 0.1, C.DarkMetal, "Metal")
				end)
			end
		end,
	},
	{
		id = "window_box",
		name = "Window box",
		cat = "windows",
		price = 35,
		place = "wall",
		size = Vector3.new(4.6, 2.1, 1.2),
		c1 = "8E6440",
		c2 = "D9707F",
		tags = { "plant" },
		build = function(r: R)
			-- a planted box on two brackets, to hang under a window: c1 the box, c2 the flowers
			for _, x in { -1.6, 1.6 } do
				bracket(r, x, 0.5, 0.5, 0.83, shade(r.c1, 0.75))
			end
			r:block(-2.2, 0.5, 0.02, 2.2, 1.2, 1.05, r.c1, "WoodPlanks")
			r:block(-2.28, 1.2, 0, 2.28, 1.32, 1.12, shade(r.c1, 0.85), "Wood")
			r:piece(function(q: R)
				q:block(-2.0, 1.25, 0.15, 2.0, 1.5, 0.95, C.DarkLeaf, "Grass")
				for i, x in { -1.5, -0.5, 0.5, 1.5 } do
					q:ball(x, 1.55, if i % 2 == 0 then 0.45 else 0.65, 0.72, C.Leaf, "Grass")
				end
				-- a few stems trailing over the front
				q:ball(-1.8, 1.05, 1.08, 0.45, C.Leaf, "Grass")
				q:ball(-0.2, 1.12, 1.1, 0.38, C.DarkLeaf, "Grass")
				q:ball(1.25, 0.98, 1.08, 0.5, C.Leaf, "Grass")
			end)
			for i, x in { -1.7, -0.9, -0.05, 0.85, 1.65 } do
				r:noCollide(
					r:ball(x, 1.86 + (i % 3) * 0.08, if i % 2 == 0 then 0.72 else 0.4, 0.42, r.c2, "SmoothPlastic")
				)
			end
			r:piece(function(q: R)
				q:box(-1.25, 1.82, 0.8, 0.2, 0.2, 0.2, C.Yellow, "SmoothPlastic")
				q:ball(0.4, 1.9, 0.82, 0.3, C.White, "SmoothPlastic")
				q:ball(1.2, 1.8, 0.3, 0.28, C.White, "SmoothPlastic")
				q:ball(-0.5, 1.84, 0.32, 0.26, C.Yellow, "SmoothPlastic")
			end)
		end,
	},
	{
		id = "window_hood",
		name = "Window hood",
		cat = "windows",
		price = 15,
		place = "wall",
		size = Vector3.new(5, 1, 1),
		c1 = "FAF6EC",
		c2 = "B8505A",
		build = function(r: R)
			-- a little pent roof on two brackets, to hang over a window or a door: c1 the
			-- woodwork, c2 the roof
			for _, x in { -2.1, 2.1 } do
				bracket(r, x, 0.45, 0.45, 0.7, r.c1)
			end
			r:block(-2.45, 0.45, 0.02, 2.45, 0.6, 0.8, r.c1, "Wood")
			slope(r, -2.5, 0.6, 0, 2.5, 1, 0.92, r.c2, "ClayRoofTiles")
		end,
	},
	{
		id = "window_attic",
		name = "Attic window",
		cat = "windows",
		price = 60,
		place = "floor",
		size = Vector3.new(4, 4.8, 1.4),
		c1 = "FAF6EC",
		c2 = "5E8E5A",
		build = function(r: R)
			-- A window for a gable end, where a wall's own windows can't go: stand it on the
			-- floor above, the middle of its footprint on the wall's line and its back to the
			-- gable. It cuts no hole, so the glass is dark. c1 the frame, c2 its two shutters.
			local z0 = 0.3 -- the gable's face
			local y0 = 1.4 -- the sill, above the top of the wall below
			local pane = r:block(-1.2, y0, z0, 1.2, y0 + 3, z0 + 0.1, Color3.fromRGB(72, 98, 122), "Glass")
			pane.collide = false
			r:block(-1.4, y0 - 0.22, z0, 1.4, y0, z0 + 0.42, r.c1, "Wood")
			r:block(-1.4, y0 + 3, z0, 1.4, y0 + 3.24, z0 + 0.34, r.c1, "Wood")
			for _, sx in { -1, 1 } do
				local x1, x2 = math.min(sx * 1.2, sx * 1.4), math.max(sx * 1.2, sx * 1.4)
				r:block(x1, y0, z0, x2, y0 + 3, z0 + 0.26, r.c1, "Wood")
				local s1, s2 = math.min(sx * 1.45, sx * 1.98), math.max(sx * 1.45, sx * 1.98)
				r:block(s1, y0, z0, s2, y0 + 3, z0 + 0.14, r.c2, "Wood")
			end
			r:block(-0.06, y0, z0 + 0.1, 0.06, y0 + 3, z0 + 0.18, r.c1, "Wood")
			r:block(-1.2, y0 + 1.44, z0 + 0.1, 1.2, y0 + 1.56, z0 + 0.18, r.c1, "Wood")
		end,
	},
}

return items
