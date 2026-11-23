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

-- Straight stairs `w` wide and `d` deep rising H.
local function stairs(r: R, w: number, d: number, rails: boolean)
	local steps = 12
	local run = d / steps
	local rise = H / steps
	-- one smooth hidden ramp to walk on
	local ramp = r:ramp(-w / 2, 0, -d / 2, w / 2, H, d / 2, false, r.c1, "Wood")
	for _, p in ramp do
		p.transp = 1
	end
	for i = 1, steps do
		local top = i * rise
		local zFront = d / 2 - (i - 1) * run
		local zBack = zFront - run
		local tread = r:block(-w / 2 + 0.3, top - 0.35, zBack, w / 2 - 0.3, top, zFront, r.c1, "WoodPlanks")
		tread.collide = false
		local riser = r:block(-w / 2 + 0.3, top - rise, zFront - 0.15, w / 2 - 0.3, top - 0.35, zFront, r.c2, "Wood")
		riser.collide = false
	end
	-- side boards follow the slope
	for _, sx in { -1, 1 } do
		local x = sx * (w / 2 - 0.15)
		r:tri(Vector3.new(x, 0, d / 2), Vector3.new(x, 0, -d / 2), Vector3.new(x, H, -d / 2), 0.3, r.c2, "Wood")
		if rails then
			local bottom = Vector3.new(x, 3.2, d / 2 - 0.4)
			local top = Vector3.new(x, H + 3.2, -d / 2 + 0.2)
			r:beam(bottom, top, 0.25, 0.25, r.c2, "Wood")
			for i = 0, 4 do
				local f = i / 4
				local z = d / 2 - 0.4 - f * (d - 0.6)
				local y = f * H
				r:block(x - 0.1, y, z - 0.1, x + 0.1, y + 3.2, z + 0.1, r.c2, "Wood")
			end
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
		c1 = "8A5A2E",
		c2 = "FFFFFF",
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
			r:block(-2, 0, -1.5, 2, 1, -0.5, r.c1, "Concrete")
			r:block(-2, 0, -0.5, 2, 0.66, 0.5, r.c1, "Concrete")
			r:block(-2, 0, 0.5, 2, 0.33, 1.5, r.c1, "Concrete")
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
			r:block(-1, 0, -1, 1, 0.6, 1, r.c2, "Marble")
			r:cyl(0, H / 2, 0, H - 1.2, 1.4, "y", r.c1, "Marble")
			r:block(-1, H - 0.6, -1, 1, H, 1, r.c2, "Marble")
		end,
	},
	{
		id = "pillar_square",
		name = "Square post",
		cat = "structure",
		price = 50,
		place = "floor",
		size = Vector3.new(1, H, 1),
		c1 = "A8743F",
		c2 = "A8743F",
		build = function(r: R)
			r:block(-0.5, 0, -0.5, 0.5, H, 0.5, r.c1, "Wood")
		end,
	},
	{
		id = "chimney",
		name = "Chimney",
		cat = "structure",
		price = 220,
		place = "floor",
		size = Vector3.new(4, 30, 3),
		c1 = "C7383F",
		c2 = "68686E",
		build = function(r: R)
			r:block(-2, 0, -1.5, 2, 28.5, 1.5, r.c1, "Brick")
			r:block(-2.3, 28.5, -1.8, 2.3, 29.3, 1.8, r.c2, "Concrete")
			r:block(-1.4, 29.3, -0.9, 1.4, 30, 0.9, r.c2, "Concrete")
			local smoke = r:block(-0.8, 29.6, -0.5, 0.8, 30, 0.5, C.Black, "SmoothPlastic")
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
		c1 = "A8743F",
		c2 = "6B4423",
		build = function(r: R)
			for _, x in { -3.6, 3.6 } do
				for _, z in { -3.6, 3.6 } do
					r:block(x - 0.4, 0, z - 0.4, x + 0.4, 0.6, z + 0.4, r.c2, "Wood")
				end
			end
			for i = 0, 7 do
				local x = -4 + i
				r:block(x + 0.05, 0.6, -4, x + 0.95, 1, 4, r.c1, "WoodPlanks")
			end
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
		c1 = "B5523B",
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
			local soot = r:block(0.3, 22.9, -0.82, 0.8, 23, -0.38, C.Black, "SmoothPlastic")
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
			r:block(WALL, 0, -0.6, WALL + 0.14, top, WALL + 0.14, r.c1, "Wood")
			r:block(-0.6, 0, WALL, WALL, top, WALL + 0.14, r.c1, "Wood")
			r:block(WALL, 0, -0.66, WALL + 0.22, 1.5, WALL + 0.22, r.c2, "Wood")
			r:block(-0.66, 0, WALL, WALL, 1.5, WALL + 0.22, r.c2, "Wood")
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
			-- four studs of stone course for the foot of a wall: c1 the stone, c2 the ledge on top
			r:block(-2, 0, 0, 2, 1.1, 0.2, r.c1, "Cobblestone")
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
		c1 = "DEB252",
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
