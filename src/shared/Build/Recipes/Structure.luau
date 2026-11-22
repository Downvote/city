--!strict
-- Stairs, pillars and other pieces of the house itself.
-- Stairs climb one storey (Plot.LevelHeight) from the front (+z, bottom) to the back (-z, top)
-- and cut their footprint out of the floor above.

local Recipe = require(script.Parent.Parent.Recipe)
local Tuning = require(script.Parent.Parent.Parent.Config.Tuning)

local C = Recipe.Colors
local H = Tuning.Plot.LevelHeight

type R = Recipe.Recipe

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

local items = {
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
}

return items
