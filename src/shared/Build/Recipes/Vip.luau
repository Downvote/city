--!strict
-- VIP pieces: a small set only VIP owners can put down (`vip = true`; the user: "add gamepasses,
-- just like bloxburg ... vip"). Build mode shows a small VIP tag on their cards and offers the pass
-- when one is picked without it, and the server's Build service refuses them to anyone else
-- (Sim/Passes.mayPlace). Each is a showpiece, most of them moving or giving off something
-- (Build/Lively), drawn at the starting house's level of detail.

local Recipe = require(script.Parent.Parent.Recipe)
local Lively = require(script.Parent.Parent.Lively)
local Colors = require(script.Parent.Parent.Parent.Util.Colors)

local C = Recipe.Colors

type R = Recipe.Recipe
type Prim = Recipe.Prim

local INK = Color3.fromRGB(52, 48, 56)
local GOLD = Color3.fromRGB(218, 182, 98)
local MARBLE = Color3.fromRGB(232, 228, 218)

local function shade(c: Color3, k: number): Color3
	return Colors.shade(c, k)
end

local function mix(a: Color3, b: Color3, t: number): Color3
	return Colors.mix(a, b, t)
end

-- A round rod from a to b.
local function rod(r: R, a: Vector3, b: Vector3, d: number, color: Color3, mat: string?): Prim?
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
		mat = mat or "SmoothPlastic",
	})
end

-- Rods through a list of points, run a little past their inner ends so the joints close.
local function path(r: R, pts: { Vector3 }, d: number, color: Color3, mat: string?)
	for i = 1, #pts - 1 do
		local a, b = pts[i], pts[i + 1]
		local u = (b - a).Unit * (d * 0.45)
		rod(r, if i > 1 then a - u else a, if i < #pts - 1 then b + u else b, d, color, mat)
	end
end

-- A cone with its point down, its middle at (x, y, z).
local function coneDown(r: R, x: number, y: number, z: number, h: number, d: number, color: Color3, mat: string?): Prim
	return r:add({
		shape = "Cone",
		cf = CFrame.new(x, y, z) * CFrame.Angles(math.pi, 0, 0),
		size = Vector3.new(d, h, d),
		color = color,
		mat = mat or "SmoothPlastic",
	})
end

-- A flat star of eight points in the frame's XY plane.
local function flatStar(r: R, cf: CFrame, s: number, thick: number, color: Color3, mat: string?)
	r:boxAt(cf, s, s, thick, color, mat)
	r:boxAt(cf * CFrame.Angles(0, 0, math.pi / 4), s, s, thick, color, mat)
end

-- A five pointed star in the XY plane of `cf`, `out` to its points and `inner` to its dips,
-- `thick` through.
local function starFive(r: R, cf: CFrame, out: number, inner: number, thick: number, color: Color3, mat: string?)
	local pts = {}
	for k = 0, 9 do
		local a = math.pi / 2 + k * math.pi / 5
		local rad = if k % 2 == 0 then out else inner
		table.insert(pts, (cf * CFrame.new(math.cos(a) * rad, math.sin(a) * rad, 0)).Position)
	end
	for k = 1, 10 do
		r:tri(cf.Position, pts[k], pts[k % 10 + 1], thick, color, mat)
	end
end

-- Water spilling over a rim: a thin see-through curtain falling `drop` from (x, y, z).
local function spill(r: R, x: number, y: number, z: number, drop: number, color: Color3)
	local p = r:cyl(x, y - drop / 2, z, drop, 0.14, "y", color, "Glass")
	p.transp = 0.45
	p.collide = false
end

return {
	{
		id = "vip_firework",
		name = "Firework fountain",
		cat = "effects",
		style = "fancy",
		vip = true,
		price = 800,
		place = "ground",
		size = Vector3.new(2, 2.6, 2),
		c1 = "F6D58A",
		c2 = "7A5CA8",
		lively = true,
		build = function(r: R)
			-- a stone pad, a drum banded in gold with stars round it, a cone with its fuse lit
			r:block(-0.95, 0, -0.95, 0.95, 0.15, 0.95, Color3.fromRGB(186, 180, 172), "Slate")
			r:cyl(0, 0.75, 0, 1.2, 1.2, "y", r.c2, "SmoothPlastic")
			for _, y in { 0.28, 1.22 } do
				r:cyl(0, y, 0, 0.1, 1.26, "y", GOLD, "Metal")
			end
			for k = 0, 3 do
				flatStar(r, CFrame.Angles(0, k * math.pi / 2, 0) * CFrame.new(0, 0.75, 0.62), 0.26, 0.03, GOLD, "Metal")
			end
			r:add({ shape = "Cone", cf = CFrame.new(0, 1.8, 0), size = Vector3.new(0.9, 0.9, 0.9), color = Color3.fromRGB(246, 236, 210), mat = "SmoothPlastic" })
			for k = 0, 2 do
				r:cyl(0, 1.5 + k * 0.2, 0, 0.06, 0.78 - k * 0.2, "y", r.c2, "SmoothPlastic")
			end
			local tip = r:ball(0, 2.3, 0, 0.16, C.Warm, "Neon")
			r:glow(tip, 12, 1.0, Color3.fromRGB(255, 200, 120))
			Lively.fx(r, "sparkfall", 0, 2.35, 0, { w = 0.2, d = 0.2 })
			Lively.fx(r, "sparkles", 0, 1.6, 0, { w = 1.4, h = 0.6, d = 1.4, color = C.White })
		end,
	},
	{
		id = "vip_golden_fountain",
		name = "Golden fountain",
		cat = "garden",
		style = "fancy",
		vip = true,
		price = 1500,
		place = "ground",
		size = Vector3.new(7.4, 6.2, 7.4),
		c1 = "E8E2D6",
		c2 = "7FC0D8",
		lively = true,
		build = function(r: R)
			local stone = r.c1
			-- a step round an eight sided basin with a gold coping, water inside
			for k = 0, 7 do
				local f = CFrame.Angles(0, k * math.pi / 4, 0)
				r:boxAt(f * CFrame.new(0, 0.1, 3.28), 2.8, 0.2, 0.5, shade(stone, 0.9), "Marble")
				r:boxAt(f * CFrame.new(0, 0.6, 2.95), 2.5, 1.0, 0.4, stone, "Marble")
				r:boxAt(f * CFrame.new(0, 1.14, 2.95), 2.6, 0.08, 0.52, GOLD, "Metal")
			end
			r:cyl(0, 0.1, 0, 0.2, 6.0, "y", shade(stone, 0.85), "Marble")
			local pool = r:cyl(0, 0.85, 0, 0.1, 5.6, "y", r.c2, "Glass")
			pool.transp = 0.25
			-- a pedestal with gold bands, a wide bowl, a little bowl and a gold ball on top
			r:cyl(0, 1.5, 0, 1.6, 1.0, "y", stone, "Marble")
			for _, y in { 1.0, 2.0 } do
				r:cyl(0, y, 0, 0.1, 1.08, "y", GOLD, "Metal")
			end
			coneDown(r, 0, 2.6, 0, 0.6, 3.0, stone, "Marble")
			r:cyl(0, 2.95, 0, 0.1, 3.0, "y", GOLD, "Metal")
			local bowl = r:cyl(0, 3.02, 0, 0.06, 2.7, "y", r.c2, "Glass")
			bowl.transp = 0.25
			r:cyl(0, 3.5, 0, 1.0, 0.5, "y", stone, "Marble")
			coneDown(r, 0, 4.15, 0, 0.4, 1.6, stone, "Marble")
			r:cyl(0, 4.4, 0, 0.08, 1.6, "y", GOLD, "Metal")
			local top = r:cyl(0, 4.45, 0, 0.04, 1.4, "y", r.c2, "Glass")
			top.transp = 0.25
			r:cyl(0, 4.7, 0, 0.4, 0.22, "y", GOLD, "Metal")
			r:ball(0, 5.0, 0, 0.42, GOLD, "Metal")
			-- water spilling over both bowls
			for k = 0, 5 do
				local a = k * math.pi / 3 + math.pi / 6
				spill(r, math.cos(a) * 1.45, 2.95, math.sin(a) * 1.45, 2.0, r.c2)
				spill(r, math.cos(a + 0.5) * 0.75, 4.4, math.sin(a + 0.5) * 0.75, 1.36, r.c2)
			end
			Lively.fx(r, "splash", 0, 5.25, 0, { w = 0.2, d = 0.2 })
			Lively.fx(r, "sparkles", 0, 4.6, 0, { w = 3.0, h = 1.4, d = 3.0, color = Color3.fromRGB(255, 230, 150) })
			Lively.fx(r, "ripple", 0, 0.92, 0, { w = 3.6, d = 3.6 })
		end,
	},
	{
		id = "vip_hot_tub",
		name = "Hot tub",
		cat = "garden",
		style = "modern",
		vip = true,
		price = 1400,
		place = "floor",
		size = Vector3.new(5.6, 2.6, 6.4),
		c1 = "8A6A50",
		c2 = "7CC8D8",
		tags = { "seat" },
		lively = true,
		build = function(r: R)
			local wood = r.c1
			local rim = Color3.fromRGB(216, 212, 204)
			local shell = Color3.fromRGB(240, 242, 244)
			-- the walls, clad in boards, a rim round the top, a shell inside with benches
			r:block(-2.7, 0, -2.7, 2.7, 2.2, -2.3, wood, "WoodPlanks")
			r:block(-2.7, 0, 2.3, 2.7, 2.2, 2.7, wood, "WoodPlanks")
			r:block(-2.7, 0, -2.3, -2.3, 2.2, 2.3, wood, "WoodPlanks")
			r:block(2.3, 0, -2.3, 2.7, 2.2, 2.3, wood, "WoodPlanks")
			for _, sz in { -1, 1 } do
				r:piece(function(q: R)
					for k = 0, 8 do
						q:box(-2.4 + k * 0.6, 1.1, sz * 2.72, 0.06, 2.0, 0.04, shade(wood, 0.8), "Wood")
					end
				end)
			end
			for _, sx in { -1, 1 } do
				r:piece(function(q: R)
					for k = 0, 8 do
						q:box(sx * 2.72, 1.1, -2.4 + k * 0.6, 0.04, 2.0, 0.06, shade(wood, 0.8), "Wood")
					end
				end)
			end
			r:block(-2.8, 2.2, -2.8, 2.8, 2.35, -2.2, rim, "Concrete")
			r:block(-2.8, 2.2, 2.2, 2.8, 2.35, 2.8, rim, "Concrete")
			r:block(-2.8, 2.2, -2.2, -2.2, 2.35, 2.2, rim, "Concrete")
			r:block(2.2, 2.2, -2.2, 2.8, 2.35, 2.2, rim, "Concrete")
			r:block(-2.3, 0, -2.3, 2.3, 0.5, 2.3, shell, "SmoothPlastic")
			r:block(-2.3, 0.5, -2.3, 2.3, 1.2, -1.6, shell, "SmoothPlastic")
			r:block(-2.3, 0.5, 1.6, 2.3, 1.2, 2.3, shell, "SmoothPlastic")
			r:block(-2.3, 0.5, -1.6, -1.6, 1.2, 1.6, shell, "SmoothPlastic")
			r:block(1.6, 0.5, -1.6, 2.3, 1.2, 1.6, shell, "SmoothPlastic")
			r:seat(0, 1.2, -1.95, 0)
			r:seat(0, 1.2, 1.95, 180)
			r:seat(-1.95, 1.2, 0, 90)
			r:seat(1.95, 1.2, 0, -90)
			-- a light under the water, the water itself, two steps up at the front
			local lamp = r:block(-0.3, 0.5, -1.6, 0.3, 0.8, -1.56, Color3.fromRGB(170, 220, 250), "Neon")
			r:glow(lamp, 12, 0.8, Color3.fromRGB(150, 210, 250))
			local water = r:block(-2.3, 0.5, -2.3, 2.3, 2.0, 2.3, r.c2, "Glass")
			water.transp = 0.4
			water.collide = false
			r:block(-1.0, 0, 2.7, 1.0, 1.1, 3.0, wood, "WoodPlanks")
			r:block(-1.0, 0, 3.0, 1.0, 0.55, 3.2, wood, "WoodPlanks")
			-- a rolled towel and a tray with two glasses on the rim
			r:cyl(2.0, 2.5, 2.5, 0.3, 0.3, "y", Color3.fromRGB(240, 236, 228), "Fabric")
			r:cyl(1.4, 2.5, 2.5, 0.3, 0.3, "y", Color3.fromRGB(150, 190, 220), "Fabric")
			r:block(-2.3, 2.35, 2.25, -1.4, 2.39, 2.65, INK, "SmoothPlastic")
			for _, x in { -2.05, -1.7 } do
				local g = r:cyl(x, 2.53, 2.45, 0.28, 0.16, "y", C.Glass, "Glass")
				g.transp = 0.4
			end
			Lively.fx(r, "bubbles", -0.8, 2.0, 0.2, { w = 1.6, d = 1.6, color = C.White })
			Lively.fx(r, "bubbles", 0.9, 2.0, -0.4, { w = 1.2, d = 1.2, color = C.White })
			Lively.fx(r, "steam", 0, 2.05, 0, { w = 3.0, d = 3.0 })
		end,
	},
	{
		id = "vip_chandelier",
		name = "Starlight chandelier",
		cat = "lights",
		style = "fancy",
		vip = true,
		price = 1200,
		place = "ceiling",
		size = Vector3.new(5, 4.2, 5),
		c1 = "D8B46A",
		c2 = "EAF4FF",
		tags = { "light" },
		lively = true,
		build = function(r: R)
			local brass = r.c1
			-- a rose on the ceiling, a stem of beads, the hub and eight curling arms with candles
			r:cyl(0, -0.08, 0, 0.16, 0.9, "y", brass, "Metal")
			for k = 0, 4 do
				r:ball(0, -0.3 - k * 0.25, 0, 0.2, brass, "Metal")
			end
			r:cyl(0, -1.65, 0, 0.5, 0.6, "y", brass, "Metal")
			local glowing = false
			for k = 0, 7 do
				local a = k * math.pi / 4
				local out = Vector3.new(math.cos(a), 0, math.sin(a))
				path(r, {
					Vector3.new(0, -1.75, 0) + out * 0.25,
					Vector3.new(0, -2.0, 0) + out * 1.0,
					Vector3.new(0, -1.9, 0) + out * 1.7,
					Vector3.new(0, -1.6, 0) + out * 1.9,
				}, 0.08, brass, "Metal")
				local cup = Vector3.new(0, -1.55, 0) + out * 1.9
				r:cyl(cup.X, cup.Y, cup.Z, 0.1, 0.3, "y", brass, "Metal")
				r:cyl(cup.X, cup.Y + 0.25, cup.Z, 0.4, 0.14, "y", C.White, "SmoothPlastic")
				local flame = r:lump(CFrame.new(cup.X, cup.Y + 0.55, cup.Z), 0.12, 0.2, 0.12, C.Warm, "Neon")
				r:glow(flame, if glowing then 0 else 18, 1.4)
				glowing = true
				-- crystal drops under each arm, catching the light
				local drop = r:add({
					shape = "Cone",
					cf = CFrame.new(cup.X, -2.3, cup.Z) * CFrame.Angles(math.pi, 0, 0),
					size = Vector3.new(0.16, 0.34, 0.16),
					color = r.c2,
					mat = "Glass",
				})
				drop.transp = 0.15
				Lively.twinkle(drop)
				rod(r, Vector3.new(cup.X, -1.6, cup.Z), Vector3.new(cup.X, -2.14, cup.Z), 0.02, brass, "Metal")
			end
			local orb = r:ball(0, -2.3, 0, 0.7, r.c2, "Glass")
			orb.transp = 0.2
			r:glow(orb, 0)
			-- a ring of gold stars under it all, turning slowly
			Lively.pivot(r, CFrame.new(0, -2.9, 0), "spin", { speed = 0.35 })
			Lively.moving(r, 1, function()
				rod(r, Vector3.new(0, -2.6, 0), Vector3.new(0, -2.92, 0), 0.04, brass, "Metal")
				for k = 0, 5 do
					local a = k * math.pi / 3
					local p = Vector3.new(math.cos(a) * 1.3, -2.9, math.sin(a) * 1.3)
					rod(r, Vector3.new(0, -2.9, 0), p, 0.03, brass, "Metal")
					rod(r, p, p - Vector3.new(0, 0.5, 0), 0.015, brass, "Metal")
					flatStar(r, CFrame.new(p - Vector3.new(0, 0.62, 0)) * CFrame.Angles(0, -a, 0), 0.24, 0.04, GOLD, "Metal")
				end
			end)
			Lively.fx(r, "sparkles", 0, -3.3, 0, { w = 2.6, h = 0.4, d = 2.6, color = C.White })
		end,
	},
	{
		id = "vip_rainbow",
		name = "Rainbow arch",
		cat = "garden",
		style = "playful",
		vip = true,
		price = 1100,
		place = "ground",
		size = Vector3.new(8, 4.8, 1.6),
		c1 = "F4A6B0",
		c2 = "FFFFFF",
		lively = true,
		build = function(r: R)
			-- six bands in soft colours, each an arch of short beams
			local bands = {
				r.c1,
				Color3.fromRGB(246, 196, 150),
				Color3.fromRGB(246, 226, 150),
				Color3.fromRGB(176, 222, 170),
				Color3.fromRGB(160, 204, 240),
				Color3.fromRGB(198, 180, 234),
			}
			for i, col in bands do
				local rad = 3.3 - (i - 1) * 0.2
				local pts = {}
				for k = 0, 14 do
					local a = k / 14 * math.pi
					table.insert(pts, Vector3.new(math.cos(a) * rad, 0.4 + math.sin(a) * rad, 0))
				end
				for k = 1, 14 do
					r:beam(pts[k], pts[k + 1], 1.1, 0.2, col, "SmoothPlastic")
				end
			end
			-- a cloud at each foot
			for _, sx in { -1, 1 } do
				local puffs = { { 0, 0.55, 0, 1.4 }, { 0.5, 0.45, 0.2, 1.0 }, { -0.5, 0.42, -0.1, 1.0 }, { 0.1, 0.95, 0.1, 0.9 } }
				for i, p in puffs do
					r:lump(CFrame.new(sx * 2.8 + p[1], p[2], p[3]) * CFrame.Angles(0, i, 0), p[4], p[4] * 0.75, p[4] * 0.8, if i % 2 == 0 then r.c2 else mix(r.c2, C.Blue, 0.06), "Fabric")
				end
				Lively.fx(r, "sparkles", sx * 2.8, 1.0, 0, { w = 1.4, h = 0.6, d = 1.0 })
			end
		end,
	},
	{
		id = "vip_red_carpet",
		name = "Red carpet",
		cat = "decor",
		style = "fancy",
		vip = true,
		price = 600,
		place = "floor",
		size = Vector3.new(4.6, 1.5, 10),
		c1 = "B84A56",
		c2 = "D6B46A",
		build = function(r: R)
			-- the runner with a gold edge each side
			r:block(-1.5, 0, -5, 1.5, 0.06, 5, r.c1, "Fabric")
			for _, sx in { -1, 1 } do
				r:block(sx * 1.42 - 0.08, 0.06, -5, sx * 1.42 + 0.08, 0.1, 5, r.c2, "Fabric")
			end
			-- brass posts each side with velvet ropes hanging between them
			local rope = shade(r.c1, 0.75)
			for _, sx in { -1, 1 } do
				local x = sx * 2.0
				for _, z in { -4.5, -1.5, 1.5, 4.5 } do
					r:cyl(x, 0.05, z, 0.1, 0.6, "y", r.c2, "Metal")
					r:cyl(x, 0.65, z, 1.1, 0.14, "y", r.c2, "Metal")
					r:ball(x, 1.3, z, 0.26, r.c2, "Metal")
				end
				for _, z in { -4.5, -1.5, 1.5 } do
					local pts = {}
					for k = 0, 4 do
						local t = k / 4
						table.insert(pts, Vector3.new(x, 1.12 - math.sin(t * math.pi) * 0.35, z + t * 3))
					end
					path(r, pts, 0.1, rope, "Fabric")
				end
			end
		end,
	},
	{
		id = "vip_star_statue",
		name = "Gold star statue",
		cat = "garden",
		style = "fancy",
		vip = true,
		price = 1000,
		place = "ground",
		size = Vector3.new(3, 6.2, 3),
		c1 = "D9B45E",
		c2 = "E8E2D6",
		lively = true,
		build = function(r: R)
			local stone = r.c2
			-- a stepped plinth, a column banded in gold and a capital
			r:block(-1.4, 0, -1.4, 1.4, 0.3, 1.4, shade(stone, 0.9), "Marble")
			r:block(-1.1, 0.3, -1.1, 1.1, 0.6, 1.1, stone, "Marble")
			r:cyl(0, 1.9, 0, 2.6, 1.0, "y", stone, "Marble")
			for _, y in { 0.75, 3.05 } do
				r:cyl(0, y, 0, 0.12, 1.08, "y", GOLD, "Metal")
			end
			r:block(-0.7, 3.2, -0.7, 0.7, 3.45, 0.7, stone, "Marble")
			r:cyl(0, 3.85, 0, 0.8, 0.12, "y", GOLD, "Metal")
			-- the star, turning slowly on its stem
			Lively.pivot(r, CFrame.new(0, 4.7, 0), "spin", { speed = 0.6 })
			Lively.moving(r, 1, function()
				starFive(r, CFrame.new(0, 4.7, 0), 1.25, 0.52, 0.3, r.c1, "Metal")
				r:ball(0, 4.7, 0.16, 0.24, shade(r.c1, 1.1), "Metal")
			end)
			Lively.fx(r, "sparkles", 0, 4.7, 0, { w = 2.6, h = 2.4, d = 1.0, color = Color3.fromRGB(255, 236, 170) })
		end,
	},
	{
		id = "vip_throne",
		name = "Gold throne",
		cat = "seating",
		style = "fancy",
		vip = true,
		price = 900,
		place = "floor",
		size = Vector3.new(3, 5.4, 2.6),
		c1 = "B84A56",
		c2 = "D9B45E",
		tags = { "seat" },
		build = function(r: R)
			local gold = r.c2
			-- turned legs, the seat box and a deep velvet cushion
			for _, sx in { -1, 1 } do
				for _, sz in { -1, 1 } do
					r:cyl(sx * 1.05, 0.4, sz * 0.85, 0.8, 0.22, "y", gold, "Metal")
					r:ball(sx * 1.05, 0.12, sz * 0.85, 0.3, gold, "Metal")
				end
			end
			r:block(-1.2, 0.8, -1.0, 1.2, 1.3, 1.1, gold, "Metal")
			r:block(-1.05, 1.3, -0.8, 1.05, 1.58, 1.0, r.c1, "Fabric")
			r:cyl(0, 1.44, 1.0, 2.1, 0.28, "x", r.c1, "Fabric")
			-- a tall back in velvet, framed in gold, a crest of points with gems on it
			for _, sx in { -1, 1 } do
				r:block(sx * 1.2 - 0.12, 1.3, -1.0, sx * 1.2 + 0.12, 4.6, -0.72, gold, "Metal")
				r:ball(sx * 1.2, 4.72, -0.86, 0.3, gold, "Metal")
			end
			r:block(-1.08, 1.58, -0.96, 1.08, 4.4, -0.78, r.c1, "Fabric")
			r:block(-1.08, 4.4, -1.0, 1.08, 4.6, -0.72, gold, "Metal")
			for k = -2, 2 do
				local h = if k == 0 then 0.7 else if math.abs(k) == 1 then 0.5 else 0.36
				r:tri(Vector3.new(k * 0.42 - 0.2, 4.6, -0.86), Vector3.new(k * 0.42 + 0.2, 4.6, -0.86), Vector3.new(k * 0.42, 4.6 + h, -0.86), 0.18, gold, "Metal")
				r:ball(k * 0.42, 4.75, -0.75, 0.12, if k % 2 == 0 then Color3.fromRGB(150, 196, 240) else Color3.fromRGB(240, 150, 170), "Glass")
			end
			for k = 0, 2 do
				r:ball(0, 2.3 + k * 0.7, -0.76, 0.1, gold, "Metal")
			end
			-- the arms, padded on top, ending in a scroll
			for _, sx in { -1, 1 } do
				r:block(sx * 1.2 - 0.15, 1.3, -0.72, sx * 1.2 + 0.15, 2.1, 1.0, gold, "Metal")
				r:block(sx * 1.2 - 0.13, 2.1, -0.7, sx * 1.2 + 0.13, 2.22, 0.9, r.c1, "Fabric")
				r:cyl(sx * 1.2, 2.0, 1.0, 0.3, 0.36, "x", gold, "Metal")
			end
			r:seat(0, 1.58, 0.15, 0)
		end,
	},
}
