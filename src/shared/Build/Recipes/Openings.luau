--!strict
-- Doors and windows. These sit in a wall and cut a hole in it the size of `opening`
-- (w wide, h tall, its bottom `sill` above the floor). The frame is drawn in the hole's own space:
-- x along the wall, y up from the hole's bottom, z across the wall (+z faces the side chosen).

local Recipe = require(script.Parent.Parent.Recipe)

local C = Recipe.Colors

type R = Recipe.Recipe

-- A plain frame round a w x h hole.
local function frame(r: R, w: number, h: number, color: Color3, depth: number?, bottom: boolean?)
	local d = depth or 0.9
	local t = 0.3
	r:block(-w / 2 - t / 2, 0, -d / 2, -w / 2 + t / 2, h + t / 2, d / 2, color, "Wood")
	r:block(w / 2 - t / 2, 0, -d / 2, w / 2 + t / 2, h + t / 2, d / 2, color, "Wood")
	r:block(-w / 2 - t / 2, h - t / 2, -d / 2, w / 2 + t / 2, h + t / 2, d / 2, color, "Wood")
	if bottom then
		r:block(-w / 2 - t / 2, -t / 2, -d / 2, w / 2 + t / 2, t / 2, d / 2, color, "Wood")
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

local items: { any } = {
	{
		id = "door_wood",
		name = "Wooden door",
		cat = "doors",
		price = 120,
		place = "opening",
		size = Vector3.new(4.6, 8.2, 1),
		opening = { w = 4, h = 8, sill = 0 },
		c1 = "A8743F",
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
		c1 = "FFFFFF",
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
		c1 = "2F7BBF",
		c2 = "FFFFFF",
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
		c1 = "8A5A2E",
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
		c1 = "9C2A2E",
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
		c1 = "FFFFFF",
		c2 = "FFFFFF",
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
		c1 = "FFFFFF",
		c2 = "FFFFFF",
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
		c1 = "FFFFFF",
		c2 = "FFFFFF",
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
		c1 = "FFFFFF",
		c2 = "FFFFFF",
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
		c1 = "4E9A44",
		c2 = "FFFFFF",
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
		c1 = "DEB252",
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
}

return items
