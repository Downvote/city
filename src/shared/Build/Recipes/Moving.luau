--!strict
-- Pieces that move (the user: "make animated decor ... and more enticing types of things"): sails
-- that turn, a fan, clocks that keep the town's time, a pendulum, a flag and a wind sock in the
-- breeze, fish that swim, a carousel and a Ferris wheel that go round, lava that rises and falls,
-- a cat that waves. Each one names its moving parts and their pivots (Build/Lively), and every
-- player's own screen moves them near the camera (client World/Lively). The server keeps them
-- still, as drawn, and never solid. Drawn at the starting house's level of detail, in a look from
-- Catalog.Styles where one fits.

local Recipe = require(script.Parent.Parent.Recipe)
local Lively = require(script.Parent.Parent.Lively)
local Colors = require(script.Parent.Parent.Parent.Util.Colors)

local C = Recipe.Colors

type R = Recipe.Recipe
type Prim = Recipe.Prim

local STONE = Color3.fromRGB(170, 166, 160)
local IRON = Color3.fromRGB(84, 82, 92)
local CREAM = Color3.fromRGB(246, 240, 226)
local INK = Color3.fromRGB(52, 48, 56)
local GLASS = Color3.fromRGB(206, 232, 240)

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

-- A ring of `n` rods round the Z axis of `cf`, `radius` out (in its XY plane).
local function ring(r: R, cf: CFrame, radius: number, n: number, d: number, color: Color3, mat: string?)
	local pts = {}
	for i = 0, n do
		local a = i / n * math.pi * 2
		table.insert(pts, (cf * CFrame.new(math.cos(a) * radius, math.sin(a) * radius, 0)).Position)
	end
	for i = 1, n do
		local a, b = pts[i], pts[i + 1]
		local u = (b - a).Unit * (d * 0.45)
		rod(r, a - u, b + u, d, color, mat)
	end
end

-- A cylinder at a frame, running along the frame's own X axis.
local function cylAt(r: R, cf: CFrame, length: number, d: number, color: Color3, mat: string?): Prim
	return r:add({
		shape = "Cylinder",
		cf = cf,
		size = Vector3.new(length, d, d),
		color = color,
		mat = mat or "SmoothPlastic",
	})
end

-- A cone at a frame (point along the frame's Y).
local function coneAt(r: R, cf: CFrame, h: number, d: number, color: Color3, mat: string?): Prim
	return r:add({ shape = "Cone", cf = cf, size = Vector3.new(d, h, d), color = color, mat = mat or "SmoothPlastic" })
end

-- A frame at `pos` whose Y axis points along `dir`.
local function alongY(pos: Vector3, dir: Vector3): CFrame
	local up = dir.Unit
	local h = if math.abs(up.X) < 0.9 then Vector3.xAxis else Vector3.zAxis
	local right = up:Cross(h).Unit
	return CFrame.fromMatrix(pos, right, up)
end

-- And one whose Z axis points along `dir` (a ring round it, Recipe's discs facing it).
local function alongZ(pos: Vector3, dir: Vector3): CFrame
	return alongY(pos, dir) * CFrame.Angles(-math.pi / 2, 0, 0)
end

-- A flat star of eight points: two squares, one turned an eighth, in the frame's XY plane.
local function star(r: R, cf: CFrame, s: number, thick: number, color: Color3, mat: string?)
	r:boxAt(cf, s, s, thick, color, mat)
	r:boxAt(cf * CFrame.Angles(0, 0, math.pi / 4), s, s, thick, color, mat)
end

-- A clock's face marks: twelve small bars round (cx, cy) on the plane z, `radius` out.
local function hourMarks(r: R, cx: number, cy: number, z: number, radius: number, big: number, color: Color3)
	for i = 0, 11 do
		local a = i * math.pi / 6
		local long = i % 3 == 0
		r:boxAt(
			CFrame.new(cx, cy, z) * CFrame.Angles(0, 0, -a) * CFrame.new(0, radius, 0),
			if long then big * 0.4 else big * 0.25,
			if long then big else big * 0.6,
			0.03,
			color,
			"SmoothPlastic"
		)
	end
end

-- A little fish facing +X (for pace) or -Z (for swim going the usual way round, `alongZ`): a body, a tail, fins and an eye
-- each side. `at` is its middle.
local function fish(r: R, at: CFrame, len: number, col: Color3, alongZ: boolean?)
	local f = if alongZ then at * CFrame.Angles(0, math.pi / 2, 0) else at
	r:lump(f, len, len * 0.5, len * 0.32, col, "SmoothPlastic")
	local tail = f * CFrame.new(-len * 0.5, 0, 0)
	r:tri(
		tail.Position,
		(tail * CFrame.new(-len * 0.32, len * 0.24, 0)).Position,
		(tail * CFrame.new(-len * 0.32, -len * 0.24, 0)).Position,
		0.03,
		shade(col, 0.88),
		"SmoothPlastic"
	)
	r:tri(
		(f * CFrame.new(-len * 0.1, len * 0.2, 0)).Position,
		(f * CFrame.new(len * 0.12, len * 0.2, 0)).Position,
		(f * CFrame.new(-len * 0.16, len * 0.36, 0)).Position,
		0.02,
		shade(col, 0.88),
		"SmoothPlastic"
	)
	for _, s in { -1, 1 } do
		r:ball(
			(f * CFrame.new(len * 0.3, len * 0.06, s * len * 0.13)).X,
			(f * CFrame.new(len * 0.3, len * 0.06, s * len * 0.13)).Y,
			(f * CFrame.new(len * 0.3, len * 0.06, s * len * 0.13)).Z,
			len * 0.09,
			INK,
			"SmoothPlastic"
		)
	end
end

type Item = {
	id: string,
	name: string,
	cat: string,
	style: string?,
	price: number,
	place: string,
	size: Vector3,
	c1: string,
	c2: string?,
	tags: { string }?,
	lively: boolean?,
	vip: boolean?,
	build: (r: R) -> (),
}

local items: { Item } = {
	------------------------------------------------------------------------------------------
	-- Garden
	{
		id = "move_windmill",
		name = "Little windmill",
		cat = "garden",
		style = "rustic",
		price = 520,
		place = "ground",
		size = Vector3.new(5, 9, 4.6),
		c1 = "EFE6D3",
		c2 = "9C6B50",
		lively = true,
		build = function(r: R)
			local wood = r.c2
			local dark = shade(r.c2, 0.72)
			local cloth = Color3.fromRGB(244, 238, 222)
			-- a stone footing, then the tower in three courses that narrow upward, banded in wood
			r:cyl(0, 0.25, 0, 0.5, 3.4, "y", STONE, "Slate")
			r:cyl(0, 1.75, 0, 2.5, 3.0, "y", r.c1, "Plaster")
			r:cyl(0, 3.75, 0, 1.5, 2.75, "y", r.c1, "Plaster")
			r:cyl(0, 5.15, 0, 1.3, 2.5, "y", r.c1, "Plaster")
			r:cyl(0, 3.0, 0, 0.14, 3.08, "y", wood, "Wood")
			r:cyl(0, 4.5, 0, 0.14, 2.83, "y", wood, "Wood")
			-- the cap: a gallery rim, a cone of boards and a ball on top
			r:cyl(0, 5.9, 0, 0.2, 2.9, "y", dark, "Wood")
			r:cone(0, 6.85, 0, 1.7, 2.8, wood, "WoodPlanks")
			r:cyl(0, 7.72, 0, 0.12, 0.16, "y", dark, "Wood")
			r:ball(0, 7.9, 0, 0.3, C.Gold, "Metal")
			-- a plank door with a frame, a step and a knob
			r:block(-0.42, 0.5, 1.34, 0.42, 1.95, 1.58, dark, "WoodPlanks")
			for _, x in { -0.14, 0.14 } do
				r:block(x - 0.02, 0.55, 1.58, x + 0.02, 1.9, 1.61, shade(dark, 0.8), "Wood")
			end
			r:block(-0.54, 1.95, 1.32, 0.54, 2.1, 1.64, wood, "Wood")
			for _, sx in { -1, 1 } do
				r:block(sx * 0.42 - 0.06, 0.5, 1.32, sx * 0.42 + 0.06, 1.95, 1.62, wood, "Wood")
			end
			r:ball(0.28, 1.2, 1.63, 0.08, C.Gold, "Metal")
			r:block(-0.62, 0, 1.45, 0.62, 0.22, 2.0, STONE, "Slate")
			-- two small windows on the sides of the middle course, with sills
			for _, sx in { -1, 1 } do
				r:block(sx * 1.24, 3.4, -0.26, sx * 1.44, 4.0, 0.26, INK, "SmoothPlastic")
				r:block(sx * 1.2, 3.32, -0.34, sx * 1.48, 3.4, 0.34, wood, "Wood")
				r:block(sx * 1.2, 4.0, -0.34, sx * 1.48, 4.08, 0.34, wood, "Wood")
				r:block(sx * 1.44, 3.67, -0.26, sx * 1.47, 3.73, 0.26, wood, "Wood")
			end
			-- moss and a few flowers round its foot
			for i, p in { { -1.4, 0.9 }, { 1.3, 1.0 }, { -1.1, -1.3 }, { 1.5, -0.6 } } do
				r:lump(CFrame.new(p[1], 0.55, p[2]) * CFrame.Angles(0, i, 0), 0.7, 0.5, 0.6, C.Leaf, "Grass")
				r:ball(p[1] + 0.15, 0.82, p[2] + 0.1, 0.16, if i % 2 == 0 then C.Pink else C.Yellow, "SmoothPlastic")
			end
			-- the sails: four lattices on their stocks, round a hub on a shaft out of the cap
			local hub = CFrame.new(0, 6.0, 1.95)
			Lively.pivot(r, hub, "spin", { speed = 0.8, axis = "Z" })
			Lively.moving(r, 1, function()
				r:cyl(0, 6.0, 1.45, 1.1, 0.3, "z", dark, "Wood")
				r:cyl(0, 6.0, 2.0, 0.2, 0.6, "z", wood, "Wood")
				r:cyl(0, 6.0, 2.12, 0.06, 0.3, "z", C.Gold, "Metal")
				for k = 0, 3 do
					local sf = hub * CFrame.Angles(0, 0, k * math.pi / 2)
					r:boxAt(sf * CFrame.new(0, 1.35, 0), 0.14, 2.3, 0.14, wood, "Wood")
					r:boxAt(sf * CFrame.new(0.64, 1.5, 0.02), 0.06, 1.8, 0.08, wood, "Wood")
					for j = 0, 4 do
						r:boxAt(sf * CFrame.new(0.34, 0.66 + j * 0.42, 0.02), 0.6, 0.05, 0.06, wood, "Wood")
					end
					r:boxAt(sf * CFrame.new(0.35, 1.5, -0.05), 0.54, 1.72, 0.03, cloth, "Fabric")
				end
			end)
		end,
	},
	{
		id = "move_pinwheel",
		name = "Pinwheel",
		cat = "garden",
		style = "playful",
		price = 30,
		place = "ground",
		size = Vector3.new(1.8, 3.7, 0.6),
		c1 = "F2A6B8",
		c2 = "A8D4EC",
		lively = true,
		build = function(r: R)
			-- a striped stick pushed into the grass
			r:cyl(0, 1.38, 0, 2.76, 0.1, "y", C.White, "SmoothPlastic")
			for i = 0, 3 do
				r:cyl(0, 0.45 + i * 0.6, 0, 0.2, 0.12, "y", r.c2, "SmoothPlastic")
			end
			r:cone(0, 0.08, 0, 0.16, 0.12, C.White, "SmoothPlastic")
			r:cyl(0, 2.75, 0.06, 0.16, 0.06, "z", C.Metal, "Metal")
			-- four vanes, each a corner folded in to the pin, in two colours
			local hub = CFrame.new(0, 2.75, 0.16)
			Lively.pivot(r, hub, "spin", { speed = 3.2, axis = "Z" })
			Lively.moving(r, 1, function()
				for k = 0, 3 do
					local f = hub * CFrame.Angles(0, 0, k * math.pi / 2)
					local col = if k % 2 == 0 then r.c1 else r.c2
					r:tri(
						(f * CFrame.new(0.05, 0.02, 0)).Position,
						(f * CFrame.new(0.62, 0.08, 0)).Position,
						(f * CFrame.new(0.62, 0.62, 0)).Position,
						0.03,
						col,
						"SmoothPlastic"
					)
					r:tri(
						(f * CFrame.new(0.05, 0.05, 0.02)).Position,
						(f * CFrame.new(0.62, 0.62, 0)).Position,
						(f * CFrame.new(0.1, 0.55, 0.07)).Position,
						0.03,
						shade(col, 1.12),
						"SmoothPlastic"
					)
				end
				r:ball(0, 2.75, 0.24, 0.16, C.Yellow, "SmoothPlastic")
			end)
		end,
	},
	{
		id = "move_wind_spinner",
		name = "Wind spinner",
		cat = "garden",
		style = "garden",
		price = 120,
		place = "ground",
		size = Vector3.new(2.2, 5.6, 0.8),
		c1 = "6A9FC2",
		c2 = "E6B066",
		lively = true,
		build = function(r: R)
			-- a pole on a spike, with a little bearing at the top
			r:cyl(0, 2.2, 0, 4.4, 0.1, "y", IRON, "Metal")
			r:cone(0, 0.1, 0, 0.2, 0.14, IRON, "Metal")
			r:cyl(0, 0.62, 0, 0.06, 0.3, "y", IRON, "Metal")
			r:ball(0, 4.45, 0, 0.18, IRON, "Metal")
			r:cyl(0, 4.4, 0.1, 0.2, 0.12, "z", C.Metal, "Metal")
			local hub = CFrame.new(0, 4.4, 0.2)
			-- the big ring: eight twisted vanes inside a hoop, turning one way
			Lively.pivot(r, hub, "spin", { speed = 1.3, axis = "Z" })
			Lively.moving(r, 1, function()
				for k = 0, 7 do
					local f = hub * CFrame.Angles(0, 0, k * math.pi / 4)
					r:boxAt(
						f * CFrame.new(0, 0.6, 0) * CFrame.Angles(0, math.rad(38), 0),
						0.22,
						0.72,
						0.03,
						r.c1,
						"Metal"
					)
					rod(r, f.Position, (f * CFrame.new(0, 0.98, 0)).Position, 0.03, shade(r.c1, 0.8), "Metal")
				end
				ring(r, hub, 1.0, 16, 0.05, shade(r.c1, 0.8), "Metal")
			end)
			-- the small star in front, turning the other way
			local front = hub * CFrame.new(0, 0, 0.12)
			Lively.pivot(r, front, "spin", { speed = -2.2, axis = "Z", group = 2 })
			Lively.moving(r, 2, function()
				r:cyl(0, 4.4, 0.32, 0.06, 0.24, "z", r.c2, "Metal")
				for k = 0, 5 do
					local f = front * CFrame.Angles(0, 0, k * math.pi / 3) * CFrame.new(0, 0.28, 0)
					r:lump(f * CFrame.Angles(0.5, 0, 0), 0.16, 0.24, 0.1, r.c2, "Metal")
				end
			end)
		end,
	},
	{
		id = "move_water_wheel",
		name = "Water wheel",
		cat = "garden",
		style = "rustic",
		price = 480,
		place = "ground",
		size = Vector3.new(3.2, 6.6, 6.2),
		c1 = "9C7452",
		c2 = "86BCD6",
		lively = true,
		build = function(r: R)
			local wood = r.c1
			local dark = shade(r.c1, 0.75)
			-- a stone pit with water in it, under the wheel
			r:block(-1.45, 0, -2.2, 1.45, 0.15, 2.2, STONE, "Slate")
			for _, sx in { -1, 1 } do
				r:block(sx * 1.45 - 0.3, 0.15, -2.2, sx * 1.45, 0.75, 2.2, STONE, "Slate")
			end
			for _, sz in { -1, 1 } do
				r:block(-1.15, 0.15, sz * 2.2 - 0.3, 1.15, 0.75, sz * 2.2, STONE, "Slate")
			end
			local pool = r:block(-1.15, 0.15, -1.9, 1.15, 0.6, 1.9, r.c2, "Glass")
			pool.transp = 0.25
			-- two A frames holding the axle, a bearing block on each
			for _, sx in { -1, 1 } do
				local x = sx * 0.95
				r:beam(Vector3.new(x, 0.75, -1.5), Vector3.new(x, 3.15, -0.1), 0.18, 0.18, dark, "Wood")
				r:beam(Vector3.new(x, 0.75, 1.5), Vector3.new(x, 3.15, 0.1), 0.18, 0.18, dark, "Wood")
				r:beam(Vector3.new(x, 1.7, -0.95), Vector3.new(x, 1.7, 0.95), 0.12, 0.14, dark, "Wood")
				r:block(x - 0.14, 2.8, -0.24, x + 0.14, 3.25, 0.24, IRON, "Metal")
			end
			-- the flume on two posts, bringing water over the top of the wheel
			for _, sx in { -1, 1 } do
				r:block(sx * 0.45 - 0.08, 0, -3.0, sx * 0.45 + 0.08, 5.8, -2.84, dark, "Wood")
			end
			r:block(-0.4, 5.7, -3.1, 0.4, 5.8, -0.7, wood, "WoodPlanks")
			for _, sx in { -1, 1 } do
				r:block(
					sx * 0.4 - (if sx > 0 then 0.08 else 0),
					5.8,
					-3.1,
					sx * 0.4 + (if sx > 0 then 0 else 0.08),
					6.2,
					-0.7,
					wood,
					"WoodPlanks"
				)
			end
			local runs = r:block(-0.32, 5.8, -3.1, 0.32, 5.98, -0.72, r.c2, "Glass")
			runs.transp = 0.2
			Lively.fx(r, "trickle", 0, 5.86, -0.68, { w = 0.5, h = 0.1, d = 0.1 })
			Lively.fx(r, "ripple", 0, 0.62, -1.0, { w = 0.8, d = 0.6 })
			-- the wheel: two rims on spokes, paddles between them, turning on its axle
			local centre = CFrame.new(0, 3.0, 0)
			Lively.pivot(r, centre, "spin", { speed = -0.7, axis = "X" })
			Lively.moving(r, 1, function()
				r:cyl(0, 3.0, 0, 2.2, 0.3, "x", IRON, "Metal")
				for _, x in { -0.48, 0.48 } do
					r:cyl(x, 3.0, 0, 0.2, 0.7, "x", wood, "Wood")
					local pts = {}
					for i = 0, 16 do
						local a = i / 16 * math.pi * 2
						table.insert(pts, Vector3.new(x, 3.0 + math.cos(a) * 2.38, math.sin(a) * 2.38))
					end
					for i = 1, 16 do
						r:beam(pts[i], pts[i + 1], 0.12, 0.22, wood, "Wood")
					end
					for i = 0, 7 do
						local a = i / 8 * math.pi * 2 + math.pi / 16
						r:beam(
							Vector3.new(x, 3.0 + math.cos(a) * 0.3, math.sin(a) * 0.3),
							Vector3.new(x, 3.0 + math.cos(a) * 2.3, math.sin(a) * 2.3),
							0.1,
							0.14,
							dark,
							"Wood"
						)
					end
				end
				for i = 0, 15 do
					local a = i / 16 * math.pi * 2
					r:boxAt(
						centre * CFrame.Angles(a, 0, 0) * CFrame.new(0, 2.36, 0),
						1.04,
						0.5,
						0.08,
						shade(wood, 0.9),
						"WoodPlanks"
					)
				end
			end)
		end,
	},
	{
		id = "move_ferris_wheel",
		name = "Little Ferris wheel",
		cat = "fun",
		style = "playful",
		price = 950,
		place = "ground",
		size = Vector3.new(6.6, 8.0, 3.0),
		c1 = "A8D0EC",
		c2 = "F4B8C8",
		lively = true,
		build = function(r: R)
			local frame = Color3.fromRGB(240, 238, 232)
			-- a paved base with a step, and the two A frames holding the axle
			r:block(-3.1, 0, -1.4, 3.1, 0.3, 1.4, STONE, "Concrete")
			r:block(-1.0, 0, 1.4, 1.0, 0.15, 1.5, STONE, "Concrete")
			for _, z in { -0.9, 0.9 } do
				r:beam(Vector3.new(-2.3, 0.3, z), Vector3.new(0, 4.6, z), 0.18, 0.18, frame, "Metal")
				r:beam(Vector3.new(2.3, 0.3, z), Vector3.new(0, 4.6, z), 0.18, 0.18, frame, "Metal")
				r:beam(Vector3.new(-1.2, 2.0, z), Vector3.new(1.2, 2.0, z), 0.12, 0.12, frame, "Metal")
				r:block(-2.5, 0.3, z - 0.18, -2.1, 0.45, z + 0.18, IRON, "Metal")
				r:block(2.1, 0.3, z - 0.18, 2.5, 0.45, z + 0.18, IRON, "Metal")
			end
			r:cyl(0, 4.6, 0, 2.2, 0.24, "z", IRON, "Metal")
			-- the wheel: two rims on spokes, tied across where the cabins hang
			local hub = CFrame.new(0, 4.6, 0)
			Lively.pivot(r, hub, "spin", { speed = 0.25, axis = "Z" })
			Lively.moving(r, 1, function()
				for _, z in { -0.55, 0.55 } do
					r:cyl(0, 4.6, z, 0.16, 0.8, "z", r.c1, "Metal")
					ring(r, CFrame.new(0, 4.6, z), 3.0, 16, 0.12, r.c1, "Metal")
					for k = 0, 7 do
						local a = k * math.pi / 4
						rod(
							r,
							Vector3.new(math.cos(a) * 0.35, 4.6 + math.sin(a) * 0.35, z),
							Vector3.new(math.cos(a) * 2.95, 4.6 + math.sin(a) * 2.95, z),
							0.07,
							frame,
							"Metal"
						)
					end
				end
				for k = 0, 7 do
					local a = k * math.pi / 4
					local x, y = math.cos(a) * 3.0, 4.6 + math.sin(a) * 3.0
					rod(r, Vector3.new(x, y, -0.6), Vector3.new(x, y, 0.6), 0.08, IRON, "Metal")
				end
			end)
			-- eight little cabins, hanging upright from the ties as the wheel goes round
			for k = 0, 7 do
				local a = k * math.pi / 4
				local x, y = math.cos(a) * 3.0, 4.6 + math.sin(a) * 3.0
				local col = if k % 2 == 0 then r.c2 else Color3.fromRGB(246, 222, 150)
				Lively.cabin(r, y, function()
					r:block(x - 0.03, y - 0.28, -0.03, x + 0.03, y, 0.03, IRON, "Metal")
					r:block(x - 0.46, y - 0.34, -0.38, x + 0.46, y - 0.28, 0.38, col, "SmoothPlastic")
					for _, sx in { -1, 1 } do
						r:block(
							x + sx * 0.4 - 0.03,
							y - 0.8,
							-0.03,
							x + sx * 0.4 + 0.03,
							y - 0.34,
							0.03,
							frame,
							"Metal"
						)
					end
					r:block(x - 0.42, y - 1.2, -0.34, x + 0.42, y - 0.8, 0.34, col, "SmoothPlastic")
					r:block(x - 0.44, y - 0.8, -0.36, x + 0.44, y - 0.74, 0.36, frame, "SmoothPlastic")
					r:block(x - 0.3, y - 1.12, 0.34, x + 0.3, y - 0.92, 0.37, shade(col, 0.85), "SmoothPlastic")
				end)
			end
		end,
	},
	{
		id = "move_koi_pond",
		name = "Koi pond",
		cat = "garden",
		style = "garden",
		price = 380,
		place = "ground",
		size = Vector3.new(6, 1.0, 6),
		c1 = "A8A49C",
		c2 = "6FA6B8",
		lively = true,
		build = function(r: R)
			-- a dark bed, the water over it and a ring of rocks round the edge
			r:cyl(0, 0.1, 0, 0.2, 4.9, "y", Color3.fromRGB(70, 82, 70), "Mud")
			local water = r:cyl(0, 0.3, 0, 0.1, 4.8, "y", r.c2, "Glass")
			water.transp = 0.35
			for i = 0, 13 do
				local a = i / 14 * math.pi * 2
				local big = 0.62 + (i * 37 % 5) * 0.06
				r:lump(
					CFrame.new(math.cos(a) * 2.55, 0.28, math.sin(a) * 2.55) * CFrame.Angles(0, a + i, 0.15),
					big * 1.2,
					big * 0.9,
					big,
					shade(r.c1, 0.9 + (i % 3) * 0.06),
					"Slate"
				)
			end
			-- reeds by the rocks, and lily pads with a flower
			for _, p in { { -1.9, -1.4 }, { 2.1, 0.9 }, { 0.3, 2.2 } } do
				for k = 0, 3 do
					r:beam(
						Vector3.new(p[1] + k * 0.06, 0.3, p[2] + (k % 2) * 0.06),
						Vector3.new(p[1] + k * 0.12 - 0.1, 0.95 - k * 0.07, p[2] + (k % 2) * 0.1),
						0.05,
						0.05,
						C.DarkLeaf,
						"Grass"
					)
				end
			end
			for _, p in { { -1.2, 0.9, 0.7 }, { 1.0, -1.2, 0.55 }, { 0.6, 1.4, 0.45 } } do
				r:cyl(p[1], 0.37, p[2], 0.04, p[3], "y", C.Leaf, "Grass")
			end
			r:lump(CFrame.new(-1.2, 0.45, 0.9), 0.22, 0.14, 0.22, C.Pink, "SmoothPlastic")
			r:ball(-1.2, 0.5, 0.9, 0.08, C.Yellow, "SmoothPlastic")
			-- the koi: three circling wide one way, two closer in the other way
			local koi = { C.White, Color3.fromRGB(238, 140, 70), Color3.fromRGB(246, 236, 224) }
			local mid = CFrame.new(0, 0.3, 0)
			Lively.pivot(r, mid, "swim", { speed = 0.35, amount = 0.015 })
			Lively.moving(r, 1, function()
				for k = 0, 2 do
					local f = mid * CFrame.Angles(0, k * math.pi * 2 / 3, 0) * CFrame.new(1.55, 0, 0)
					fish(r, f, 0.7, koi[k + 1], true)
					r:lump(
						f * CFrame.new(0, 0.05, -0.12),
						0.18,
						0.06,
						0.24,
						Color3.fromRGB(230, 96, 64),
						"SmoothPlastic"
					)
				end
			end)
			Lively.pivot(r, mid, "swim", { speed = -0.5, amount = 0.015, group = 2, phase = 1 })
			Lively.moving(r, 2, function()
				for k = 0, 1 do
					local f = mid
						* CFrame.Angles(0, k * math.pi, 0)
						* CFrame.new(0.8, 0, 0)
						* CFrame.Angles(0, math.pi, 0)
					fish(r, f, 0.6, koi[3 - k], true)
				end
			end)
		end,
	},
	{
		id = "move_garden_flag",
		name = "Garden flag",
		cat = "garden",
		style = "garden",
		price = 40,
		place = "ground",
		size = Vector3.new(2, 4.6, 0.6),
		c1 = "E7A58C",
		c2 = "F4E6B8",
		lively = true,
		build = function(r: R)
			-- a slim iron stand with a hook arm and a ball on top
			r:cyl(-0.8, 2.15, 0, 4.3, 0.1, "y", IRON, "Metal")
			r:ball(-0.8, 4.36, 0, 0.18, IRON, "Metal")
			r:cyl(-0.8, 0.12, 0, 0.06, 0.4, "y", IRON, "Metal")
			r:cyl(-0.15, 4.0, 0, 1.36, 0.06, "x", IRON, "Metal")
			r:ball(0.52, 4.0, 0, 0.1, IRON, "Metal")
			-- the banner, swinging in the breeze on its arm: a pointed hem, a band and a flower
			local arm = CFrame.new(-0.15, 4.0, 0)
			Lively.pivot(r, arm, "flutter", { speed = 2.0, amount = 0.14, axis = "X" })
			Lively.moving(r, 1, function()
				r:block(-0.66, 2.45, -0.02, 0.36, 3.92, 0.02, r.c1, "Fabric")
				r:tri(
					Vector3.new(-0.66, 2.45, 0),
					Vector3.new(0.36, 2.45, 0),
					Vector3.new(-0.15, 2.05, 0),
					0.04,
					r.c1,
					"Fabric"
				)
				r:block(-0.66, 3.7, -0.05, 0.36, 3.84, 0.05, r.c2, "Fabric")
				for k = 0, 4 do
					local a = k * math.pi * 2 / 5
					r:lump(
						CFrame.new(-0.15 + math.cos(a) * 0.17, 3.0 + math.sin(a) * 0.17, 0.05) * CFrame.Angles(0, 0, a),
						0.22,
						0.14,
						0.06,
						r.c2,
						"Fabric"
					)
				end
				r:ball(-0.15, 3.0, 0.07, 0.12, C.Yellow, "Fabric")
				r:block(-0.17, 2.4, 0.03, -0.13, 2.86, 0.07, C.Leaf, "Fabric")
				for _, x in { -0.55, 0.25 } do
					r:cyl(x, 3.96, 0, 0.08, 0.1, "y", IRON, "Metal")
				end
			end)
		end,
	},
	{
		id = "move_wind_sock",
		name = "Wind sock",
		cat = "garden",
		style = "seaside",
		price = 60,
		place = "ground",
		size = Vector3.new(3.4, 4.8, 1.0),
		c1 = "E9826A",
		c2 = "F7F3EA",
		lively = true,
		build = function(r: R)
			-- a pole on a base plate, a collar it swivels on
			r:block(-1.75, 0, -0.3, -1.15, 0.1, 0.3, IRON, "Metal")
			r:cyl(-1.45, 2.2, 0, 4.2, 0.12, "y", C.Metal, "Metal")
			r:ball(-1.45, 4.35, 0, 0.18, r.c1, "SmoothPlastic")
			r:cyl(-1.45, 4.1, 0, 0.14, 0.2, "y", IRON, "Metal")
			-- the sock, striped, narrowing and drooping a little, swinging round with the wind
			local pin = CFrame.new(-1.45, 4.0, 0)
			Lively.pivot(r, pin, "flutter", { speed = 1.1, amount = 0.32, axis = "Y" })
			Lively.moving(r, 1, function()
				rod(r, Vector3.new(-1.45, 4.0, 0), Vector3.new(-1.2, 4.0, 0), 0.05, IRON, "Metal")
				ring(r, CFrame.new(-1.14, 3.9, 0) * CFrame.Angles(0, math.pi / 2, 0), 0.36, 12, 0.05, IRON, "Metal")
				for i = 0, 4 do
					local d = 0.68 - i * 0.07
					local x = -0.9 + i * 0.5
					r:add({
						shape = "Cylinder",
						cf = CFrame.new(x, 3.9 - i * 0.07, 0) * CFrame.Angles(0, 0, -0.06),
						size = Vector3.new(0.5, d, d),
						color = if i % 2 == 0 then r.c1 else r.c2,
						mat = "Fabric",
					})
				end
			end)
		end,
	},
	{
		id = "move_sprinkler",
		name = "Sprinkler",
		cat = "garden",
		style = "garden",
		price = 35,
		place = "ground",
		size = Vector3.new(1.6, 1.1, 1.4),
		c1 = "5FA06A",
		c2 = "F0C24E",
		lively = true,
		build = function(r: R)
			-- a little sled, a riser and a hose coming in at the side
			for _, z in { -0.4, 0.4 } do
				r:cyl(0, 0.06, z, 1.0, 0.12, "x", r.c1, "SmoothPlastic")
			end
			r:block(-0.25, 0.06, -0.4, 0.25, 0.14, 0.4, r.c1, "SmoothPlastic")
			r:cyl(0, 0.35, 0, 0.42, 0.14, "y", r.c1, "SmoothPlastic")
			r:cyl(0.32, 0.12, 0, 0.36, 0.1, "x", r.c2, "SmoothPlastic")
			path(
				r,
				{ Vector3.new(0.5, 0.12, 0), Vector3.new(0.7, 0.06, 0.15), Vector3.new(0.78, 0.06, 0.6) },
				0.12,
				C.Leaf,
				"SmoothPlastic"
			)
			-- the head going round, two arms bent up at the ends
			local head = CFrame.new(0, 0.62, 0)
			Lively.pivot(r, head, "spin", { speed = 2.2 })
			Lively.moving(r, 1, function()
				r:cyl(0, 0.62, 0, 0.14, 0.22, "y", r.c2, "SmoothPlastic")
				for _, sx in { -1, 1 } do
					rod(r, Vector3.new(0, 0.66, 0), Vector3.new(sx * 0.48, 0.66, 0), 0.07, r.c2, "SmoothPlastic")
					rod(
						r,
						Vector3.new(sx * 0.48, 0.64, 0),
						Vector3.new(sx * 0.56, 0.8, 0.06 * sx),
						0.07,
						r.c2,
						"SmoothPlastic"
					)
				end
			end)
			Lively.fx(r, "spray", 0, 0.82, 0, { w = 0.4, d = 0.4 })
		end,
	},
	------------------------------------------------------------------------------------------
	-- Inside
	{
		id = "move_ceiling_fan",
		name = "Ceiling fan",
		cat = "lights",
		style = "modern",
		price = 120,
		place = "ceiling",
		size = Vector3.new(6, 1.9, 6),
		c1 = "B48A60",
		c2 = "EEEAE2",
		tags = { "light" },
		lively = true,
		build = function(r: R)
			-- the canopy on the ceiling, a rod down, the light bowl under it all
			r:cyl(0, -0.12, 0, 0.24, 0.7, "y", r.c2, "Metal")
			r:cyl(0, -0.55, 0, 0.66, 0.12, "y", r.c2, "Metal")
			r:cyl(0, -1.3, 0, 0.18, 0.5, "y", r.c2, "Metal")
			local bowl = r:lump(CFrame.new(0, -1.55, 0), 0.72, 0.48, 0.72, CREAM, "SmoothPlastic")
			r:glow(bowl, 14, 1.0)
			rod(r, Vector3.new(0.16, -1.6, 0), Vector3.new(0.16, -1.82, 0), 0.03, C.Gold, "Metal")
			r:ball(0.16, -1.84, 0, 0.06, C.Gold, "Metal")
			-- the motor and five pitched wooden blades on their irons, going round
			local centre = CFrame.new(0, -1.0, 0)
			Lively.pivot(r, centre, "spin", { speed = 4.5 })
			Lively.moving(r, 1, function()
				r:cyl(0, -1.0, 0, 0.32, 0.9, "y", r.c2, "Metal")
				r:cyl(0, -1.18, 0, 0.06, 0.96, "y", shade(r.c2, 0.85), "Metal")
				for k = 0, 4 do
					local f = CFrame.Angles(0, k * math.pi * 2 / 5, 0)
					r:boxAt(f * CFrame.new(0.72, -1.08, 0), 0.75, 0.06, 0.18, IRON, "Metal")
					r:boxAt(
						f * CFrame.new(1.92, -1.12, 0) * CFrame.Angles(math.rad(8), 0, 0),
						2.0,
						0.05,
						0.6,
						r.c1,
						"Wood"
					)
				end
			end)
		end,
	},
	{
		id = "move_lava_lamp",
		name = "Lava lamp",
		cat = "decor",
		style = "playful",
		price = 45,
		place = "surface",
		size = Vector3.new(0.8, 2.3, 0.8),
		c1 = "F29A7E",
		c2 = "7C6E9A",
		lively = true,
		build = function(r: R)
			-- a drum base, a neck, the glass in three steps and a cap
			r:cyl(0, 0.22, 0, 0.44, 0.72, "y", r.c2, "Metal")
			r:cyl(0, 0.47, 0, 0.06, 0.6, "y", shade(r.c2, 0.8), "Metal")
			r:cyl(0, 0.55, 0, 0.1, 0.46, "y", r.c2, "Metal")
			local liquid = mix(r.c1, C.White, 0.62)
			local low = r:cyl(0, 0.95, 0, 0.7, 0.52, "y", liquid, "Glass")
			low.transp = 0.35
			r:glow(low, 6, 0.6, mix(r.c1, C.Warm, 0.5))
			local mid = r:cyl(0, 1.55, 0, 0.5, 0.44, "y", liquid, "Glass")
			mid.transp = 0.35
			local top = r:cyl(0, 1.95, 0, 0.3, 0.36, "y", liquid, "Glass")
			top.transp = 0.35
			r:cyl(0, 2.16, 0, 0.12, 0.38, "y", r.c2, "Metal")
			r:cyl(0, 2.26, 0, 0.08, 0.2, "y", shade(r.c2, 0.8), "Metal")
			-- three blobs of wax, rising and sinking at their own pace
			local blobs = {
				{ y = 0.95, d = 0.3, amount = 0.28, speed = 0.7, phase = 0 },
				{ y = 1.5, d = 0.22, amount = 0.24, speed = 0.55, phase = 2 },
				{ y = 1.22, d = 0.26, amount = 0.34, speed = 0.42, phase = 4 },
			}
			for g, b in blobs do
				Lively.pivot(r, CFrame.new(0, b.y, 0), "bob", {
					speed = b.speed,
					amount = b.amount,
					phase = b.phase,
					group = g,
				})
				Lively.moving(r, g, function()
					r:glow(r:lump(CFrame.new((g - 2) * 0.06, b.y, 0), b.d, b.d * 1.25, b.d, r.c1, "SmoothPlastic"), 0)
				end)
			end
		end,
	},
	{
		id = "move_goldfish_bowl",
		name = "Goldfish bowl",
		cat = "decor",
		style = "seaside",
		price = 60,
		place = "surface",
		size = Vector3.new(1.4, 1.5, 1.4),
		c1 = "F4A040",
		c2 = "7DC0D8",
		lively = true,
		build = function(r: R)
			-- a glass bowl on a foot ring, water, pebbles, weed and a stone arch
			r:cyl(0, 0.04, 0, 0.08, 0.62, "y", GLASS, "Glass").transp = 0.4
			r:cyl(0, 0.22, 0, 0.14, 0.86, "y", Color3.fromRGB(214, 190, 150), "Pebble")
			local pebbles = {
				{ x = -0.2, z = 0.1, col = C.Pink },
				{ x = 0.18, z = -0.16, col = C.Blue },
				{ x = 0.05, z = 0.25, col = C.Yellow },
			}
			for i, p in pebbles do
				r:ball(p.x, 0.31, p.z, 0.08 + i * 0.01, p.col, "SmoothPlastic")
			end
			for k = 0, 2 do
				r:beam(
					Vector3.new(-0.25 + k * 0.08, 0.28, -0.2),
					Vector3.new(-0.3 + k * 0.12, 0.85 - k * 0.1, -0.18),
					0.05,
					0.1,
					C.Leaf,
					"Grass"
				)
			end
			r:block(0.12, 0.28, -0.3, 0.2, 0.52, -0.16, STONE, "Slate")
			r:block(0.36, 0.28, -0.3, 0.44, 0.52, -0.16, STONE, "Slate")
			r:block(0.1, 0.52, -0.3, 0.46, 0.6, -0.16, STONE, "Slate")
			local water = r:lump(CFrame.new(0, 0.6, 0), 1.18, 0.96, 1.18, r.c2, "Glass")
			water.transp = 0.5
			local bowl = r:ball(0, 0.7, 0, 1.3, GLASS, "Glass")
			bowl.transp = 0.65
			r:cyl(0, 1.3, 0, 0.06, 0.8, "y", GLASS, "Glass").transp = 0.4
			-- the goldfish, going round and round
			local mid = CFrame.new(0, 0.68, 0)
			Lively.pivot(r, mid, "swim", { speed = 0.8, amount = 0.06 })
			Lively.moving(r, 1, function()
				fish(r, mid * CFrame.new(0.32, 0, 0), 0.32, r.c1, true)
			end)
		end,
	},
	{
		id = "move_crib",
		name = "Crib with a mobile",
		cat = "decor",
		style = "cozy",
		price = 220,
		place = "floor",
		size = Vector3.new(4.6, 5.6, 2.6),
		c1 = "F4EEE4",
		c2 = "B8D4E8",
		lively = true,
		build = function(r: R)
			local wood = r.c1
			-- four posts on little castors, rails top and bottom, slats between
			for _, sx in { -1, 1 } do
				for _, sz in { -1, 1 } do
					r:block(
						sx * 2.12 - 0.09,
						0.14,
						sz * 1.12 - 0.09,
						sx * 2.12 + 0.09,
						3.0,
						sz * 1.12 + 0.09,
						wood,
						"Wood"
					)
					r:ball(sx * 2.12, 3.08, sz * 1.12, 0.2, wood, "Wood")
					r:cyl(sx * 2.12, 0.07, sz * 1.12, 0.14, 0.14, "z", IRON, "Metal")
				end
			end
			for _, sz in { -1, 1 } do
				r:block(-2.03, 2.7, sz * 1.12 - 0.07, 2.03, 2.86, sz * 1.12 + 0.07, wood, "Wood")
				r:block(-2.03, 0.9, sz * 1.12 - 0.07, 2.03, 1.02, sz * 1.12 + 0.07, wood, "Wood")
				r:piece(function(q: R)
					for i = 1, 13 do
						q:box(-2.0 + i * 0.286, 1.86, sz * 1.12, 0.08, 1.68, 0.08, wood, "Wood")
					end
				end)
			end
			for _, sx in { -1, 1 } do
				r:block(sx * 2.12 - 0.05, 0.9, -1.03, sx * 2.12 + 0.05, 2.86, 1.03, wood, "Wood")
				-- a little heart painted on each end
				r:lump(CFrame.new(sx * 2.18, 2.1, 0), 0.04, 0.34, 0.5, r.c2, "SmoothPlastic")
			end
			-- the mattress, a quilt, a pillow and a bear
			r:block(-2.03, 1.02, -1.03, 2.03, 1.4, 1.03, C.White, "Fabric")
			r:block(-0.4, 1.4, -1.0, 2.0, 1.5, 1.0, r.c2, "Fabric")
			r:block(-0.4, 1.5, -0.6, -0.2, 1.53, 0.6, shade(r.c2, 0.9), "Fabric")
			r:lump(CFrame.new(-1.5, 1.55, 0), 0.7, 0.3, 1.1, C.White, "Fabric")
			r:ball(-0.9, 1.62, 0.4, 0.42, Color3.fromRGB(196, 150, 110), "Fabric")
			r:ball(-0.9, 1.98, 0.4, 0.32, Color3.fromRGB(196, 150, 110), "Fabric")
			-- the mobile's arm, up from the back post and over the bed
			path(r, {
				Vector3.new(2.12, 3.0, -1.12),
				Vector3.new(2.12, 4.9, -1.12),
				Vector3.new(1.9, 5.3, -0.8),
				Vector3.new(1.4, 5.45, -0.32),
				Vector3.new(1.0, 5.36, 0),
			}, 0.09, wood, "Wood")
			r:cyl(1.0, 5.25, 0, 0.18, 0.08, "y", wood, "Wood")
			-- the mobile, turning slowly: a cross, strings, a star, a moon, a cloud and a bird
			local hub = CFrame.new(1.0, 5.15, 0)
			Lively.pivot(r, hub, "spin", { speed = 0.45 })
			Lively.moving(r, 1, function()
				local cord = Color3.fromRGB(226, 220, 210)
				rod(r, Vector3.new(0.4, 5.15, 0), Vector3.new(1.6, 5.15, 0), 0.05, wood, "Wood")
				rod(r, Vector3.new(1.0, 5.15, -0.6), Vector3.new(1.0, 5.15, 0.6), 0.05, wood, "Wood")
				local hang = {
					{ x = 0.45, z = 0, y = 4.45, kind = "star", col = C.Yellow },
					{ x = 1.55, z = 0, y = 4.6, kind = "cloud", col = C.White },
					{ x = 1.0, z = -0.55, y = 4.35, kind = "moon", col = Color3.fromRGB(246, 226, 160) },
					{ x = 1.0, z = 0.55, y = 4.5, kind = "bird", col = Color3.fromRGB(244, 184, 200) },
				}
				for _, h in hang do
					local x, z, y = h.x, h.z, h.y
					rod(r, Vector3.new(x, 5.12, z), Vector3.new(x, y + 0.18, z), 0.02, cord, "Fabric")
					local cf = CFrame.new(x, y, z)
					local col = h.col
					if h.kind == "star" then
						star(r, cf, 0.3, 0.06, col, "SmoothPlastic")
					elseif h.kind == "cloud" then
						r:lump(cf * CFrame.new(-0.12, 0, 0), 0.26, 0.2, 0.14, col, "Fabric")
						r:lump(cf * CFrame.new(0.04, 0.05, 0), 0.32, 0.26, 0.16, col, "Fabric")
						r:lump(cf * CFrame.new(0.17, -0.02, 0), 0.22, 0.18, 0.14, col, "Fabric")
					elseif h.kind == "moon" then
						for k = 0, 4 do
							local t = math.rad(70 + k * 50)
							r:ball(x + math.cos(t) * 0.16, y + math.sin(t) * 0.16, z, 0.12, col, "SmoothPlastic")
						end
					else
						r:lump(cf, 0.3, 0.18, 0.16, col, "Fabric")
						r:ball(x + 0.15, y + 0.06, z, 0.13, col, "Fabric")
						r:tri(
							Vector3.new(x - 0.05, y + 0.05, z),
							Vector3.new(x + 0.08, y + 0.05, z),
							Vector3.new(x - 0.02, y + 0.25, z),
							0.03,
							shade(col, 0.9),
							"Fabric"
						)
					end
				end
			end)
		end,
	},
	{
		id = "move_gramophone",
		name = "Gramophone",
		cat = "fun",
		style = "fancy",
		price = 160,
		place = "surface",
		size = Vector3.new(1.6, 2.6, 2.0),
		c1 = "8A5A3C",
		c2 = "D9B36A",
		tags = { "music" },
		lively = true,
		build = function(r: R)
			local dk = shade(r.c1, 0.8)
			-- a wooden box on little feet, a moulded lip round the top
			for _, sx in { -1, 1 } do
				for _, sz in { -1, 1 } do
					r:cyl(sx * 0.6, 0.04, sz * 0.6, 0.08, 0.14, "y", dk, "Wood")
				end
			end
			r:block(-0.7, 0.08, -0.7, 0.7, 0.6, 0.7, r.c1, "Wood")
			r:block(-0.76, 0.6, -0.76, 0.76, 0.66, 0.76, dk, "Wood")
			r:block(-0.5, 0.2, 0.7, 0.5, 0.48, 0.73, dk, "Wood")
			-- the crank at the side
			r:cyl(0.76, 0.35, 0, 0.1, 0.12, "x", C.Gold, "Metal")
			path(
				r,
				{ Vector3.new(0.8, 0.35, 0), Vector3.new(0.86, 0.35, 0), Vector3.new(0.86, 0.15, 0.08) },
				0.04,
				C.Gold,
				"Metal"
			)
			r:cyl(0.94, 0.15, 0.08, 0.14, 0.07, "x", INK, "Wood")
			-- the tone arm from the back corner, its sound box on the record
			r:cyl(0.5, 0.72, -0.5, 0.12, 0.18, "y", r.c2, "Metal")
			path(
				r,
				{ Vector3.new(0.5, 0.78, -0.5), Vector3.new(0.5, 0.86, -0.46), Vector3.new(0.3, 0.86, 0.05) },
				0.05,
				r.c2,
				"Metal"
			)
			r:cyl(0.28, 0.82, 0.12, 0.06, 0.18, "y", r.c2, "Metal")
			-- the horn: a neck up from the back, then a wide bell facing the room
			path(r, {
				Vector3.new(0.5, 0.86, -0.5),
				Vector3.new(0.45, 1.25, -0.6),
				Vector3.new(0.25, 1.55, -0.45),
			}, 0.12, r.c2, "Metal")
			local mouth = Vector3.new(0.0, 2.0, 0.25)
			local axis = (mouth - Vector3.new(0.25, 1.55, -0.45)).Unit
			coneAt(r, alongY(mouth - axis * 0.5, -axis), 1.0, 1.25, r.c2, "Metal")
			ring(r, alongZ(mouth + axis * 0.02, axis), 0.6, 16, 0.06, shade(r.c2, 1.1), "Metal")
			cylAt(r, alongY(mouth + axis * 0.02, axis) * CFrame.Angles(0, 0, math.pi / 2), 0.03, 1.05, dk, "Metal")
			-- the record, going round on its felt platter
			Lively.pivot(r, CFrame.new(0, 0.68, 0.05), "spin", { speed = 3.4 })
			Lively.moving(r, 1, function()
				r:cyl(0, 0.68, 0.05, 0.04, 1.1, "y", Color3.fromRGB(70, 104, 82), "Fabric")
				r:cyl(0, 0.715, 0.05, 0.03, 1.0, "y", INK, "SmoothPlastic")
				r:cyl(0, 0.745, 0.05, 0.03, 0.34, "y", Color3.fromRGB(190, 86, 86), "SmoothPlastic")
			end)
			Lively.fx(r, "notes", 0, 2.05, 0.3, { w = 0.4, d = 0.3, color = CREAM })
		end,
	},
	{
		id = "move_waving_cat",
		name = "Waving cat",
		cat = "decor",
		style = "playful",
		price = 50,
		place = "surface",
		size = Vector3.new(0.9, 1.4, 0.8),
		c1 = "F6F1E8",
		c2 = "D86A6A",
		lively = true,
		build = function(r: R)
			-- a cushion, the body, the head with its ears
			r:block(-0.42, 0, -0.36, 0.42, 0.1, 0.36, r.c2, "Fabric")
			r:lump(CFrame.new(0, 0.44, 0), 0.62, 0.7, 0.5, r.c1, "SmoothPlastic")
			r:lump(CFrame.new(0, 0.98, 0.03), 0.62, 0.5, 0.5, r.c1, "SmoothPlastic")
			for _, sx in { -1, 1 } do
				r:tri(
					Vector3.new(sx * 0.12, 1.16, 0.04),
					Vector3.new(sx * 0.3, 1.14, 0.04),
					Vector3.new(sx * 0.26, 1.34, 0.04),
					0.1,
					r.c1,
					"SmoothPlastic"
				)
				r:tri(
					Vector3.new(sx * 0.16, 1.17, 0.1),
					Vector3.new(sx * 0.27, 1.16, 0.1),
					Vector3.new(sx * 0.25, 1.28, 0.1),
					0.02,
					Color3.fromRGB(240, 170, 176),
					"SmoothPlastic"
				)
				-- happy shut eyes and three whiskers
				r:boxAt(
					CFrame.new(sx * 0.12, 1.02, 0.27) * CFrame.Angles(0, 0, sx * 0.3),
					0.12,
					0.025,
					0.03,
					INK,
					"SmoothPlastic"
				)
				for k = -1, 1 do
					r:boxAt(
						CFrame.new(sx * 0.27, 0.92 + k * 0.035, 0.25) * CFrame.Angles(0, 0, sx * k * 0.15),
						0.18,
						0.012,
						0.012,
						INK,
						"SmoothPlastic"
					)
				end
			end
			r:ball(0, 0.94, 0.28, 0.06, Color3.fromRGB(240, 150, 160), "SmoothPlastic")
			-- a red collar with a bell, and a gold coin held up in the other paw
			r:lump(CFrame.new(0, 0.75, 0.02), 0.5, 0.08, 0.42, r.c2, "Fabric")
			r:ball(0, 0.69, 0.23, 0.1, C.Gold, "Metal")
			r:lump(CFrame.new(-0.2, 0.55, 0.22), 0.16, 0.3, 0.14, r.c1, "SmoothPlastic")
			r:cyl(-0.16, 0.48, 0.28, 0.04, 0.24, "z", C.Gold, "Metal")
			r:lump(CFrame.new(0.05, 0.2, -0.3) * CFrame.Angles(0.6, 0, 0.4), 0.12, 0.34, 0.12, r.c1, "SmoothPlastic")
			-- the raised paw, beckoning
			local shoulder = CFrame.new(0.24, 0.72, 0.06)
			Lively.pivot(r, shoulder, "swing", { speed = 4, amount = 0.35, axis = "X" })
			Lively.moving(r, 1, function()
				r:lump(CFrame.new(0.28, 0.9, 0.1), 0.17, 0.4, 0.17, r.c1, "SmoothPlastic")
				r:ball(0.29, 1.07, 0.17, 0.08, Color3.fromRGB(240, 170, 176), "SmoothPlastic")
			end)
		end,
	},
	{
		id = "move_hamster",
		name = "Hamster cage",
		cat = "decor",
		style = "playful",
		price = 120,
		place = "surface",
		size = Vector3.new(2.4, 1.8, 1.4),
		c1 = "8FCFB4",
		c2 = "F2C46E",
		lively = true,
		build = function(r: R)
			-- a plastic tray with wood shavings in it
			r:block(-1.15, 0, -0.65, 1.15, 0.35, 0.65, r.c1, "SmoothPlastic")
			r:block(-1.08, 0.35, -0.58, 1.08, 0.38, 0.58, Color3.fromRGB(232, 214, 170), "Sand")
			-- the wire top: bars all round, a rim and bars across the roof
			local wire = Color3.fromRGB(236, 236, 232)
			r:piece(function(q: R)
				q:box(0, 1.64, 0.62, 2.24, 0.04, 0.04, wire, "Metal")
				q:box(0, 1.64, -0.62, 2.24, 0.04, 0.04, wire, "Metal")
				q:box(1.12, 1.64, 0, 0.04, 0.04, 1.2, wire, "Metal")
				q:box(-1.12, 1.64, 0, 0.04, 0.04, 1.2, wire, "Metal")
				for i = 0, 10 do
					q:box(-1.0 + i * 0.2, 1.66, 0, 0.03, 0.03, 1.2, wire, "Metal")
				end
			end)
			for _, z in { -0.62, 0.62 } do
				r:piece(function(q: R)
					for i = 0, 10 do
						q:box(-1.0 + i * 0.2, 1.0, z, 0.03, 1.24, 0.03, wire, "Metal")
					end
				end)
			end
			r:piece(function(q: R)
				for i = 0, 4 do
					local z = -0.4 + i * 0.2
					q:box(1.12, 1.0, z, 0.03, 1.24, 0.03, wire, "Metal")
					q:box(-1.12, 1.0, z, 0.03, 1.24, 0.03, wire, "Metal")
				end
			end)
			-- a little house with a round door, a bowl of seeds and a water bottle
			r:block(-0.95, 0.38, -0.5, -0.4, 0.7, -0.05, Color3.fromRGB(240, 170, 150), "SmoothPlastic")
			r:wedge(CFrame.new(-0.675, 0.8, -0.39), 0.6, 0.2, 0.22, r.c2, "SmoothPlastic")
			r:wedge(
				CFrame.new(-0.675, 0.8, -0.16) * CFrame.Angles(0, math.pi, 0),
				0.6,
				0.2,
				0.22,
				r.c2,
				"SmoothPlastic"
			)
			r:cyl(-0.675, 0.52, -0.03, 0.04, 0.2, "z", INK, "SmoothPlastic")
			r:cyl(-0.2, 0.42, 0.3, 0.08, 0.3, "y", C.Blue, "SmoothPlastic")
			r:cyl(-0.2, 0.47, 0.3, 0.03, 0.24, "y", Color3.fromRGB(214, 176, 110), "Sand")
			local bottle = r:cyl(-1.2, 1.1, 0.25, 0.6, 0.16, "y", GLASS, "Glass")
			bottle.transp = 0.4
			rod(r, Vector3.new(-1.2, 0.8, 0.25), Vector3.new(-1.05, 0.66, 0.25), 0.03, C.Metal, "Metal")
			-- the wheel on its stand, going round under a hamster who is in no hurry
			r:beam(Vector3.new(0.55, 0.38, -0.2), Vector3.new(0.55, 0.85, -0.2), 0.06, 0.06, r.c2, "SmoothPlastic")
			r:ball(0.55, 0.62, 0.1, 0.3, Color3.fromRGB(222, 170, 116), "Fabric")
			r:ball(0.55, 0.6, 0.22, 0.2, C.White, "Fabric")
			r:ball(0.62, 0.66, 0.28, 0.05, INK, "SmoothPlastic")
			for _, sx in { -1, 1 } do
				r:ball(0.55 + sx * 0.1, 0.78, 0.06, 0.08, Color3.fromRGB(240, 170, 176), "Fabric")
			end
			local hub = CFrame.new(0.55, 0.85, 0.05)
			Lively.pivot(r, hub, "spin", { speed = -3, axis = "Z" })
			Lively.moving(r, 1, function()
				r:cyl(0.55, 0.85, -0.16, 0.06, 0.16, "z", r.c2, "SmoothPlastic")
				for _, z in { -0.12, 0.26 } do
					ring(r, CFrame.new(0.55, 0.85, z), 0.42, 12, 0.04, r.c2, "SmoothPlastic")
				end
				for k = 0, 11 do
					local a = k / 12 * math.pi * 2
					local x, y = 0.55 + math.cos(a) * 0.42, 0.85 + math.sin(a) * 0.42
					rod(r, Vector3.new(x, y, -0.12), Vector3.new(x, y, 0.26), 0.025, shade(r.c2, 0.85), "SmoothPlastic")
				end
				for k = 0, 3 do
					local a = k * math.pi / 2
					rod(
						r,
						Vector3.new(0.55, 0.85, -0.12),
						Vector3.new(0.55 + math.cos(a) * 0.42, 0.85 + math.sin(a) * 0.42, -0.12),
						0.03,
						r.c2,
						"SmoothPlastic"
					)
				end
			end)
		end,
	},
	{
		id = "move_carousel",
		name = "Toy carousel",
		cat = "fun",
		style = "playful",
		price = 900,
		place = "ground",
		size = Vector3.new(7, 7.4, 7),
		c1 = "F3BFCB",
		c2 = "F7E3A6",
		lively = true,
		build = function(r: R)
			r:cyl(0, 0.1, 0, 0.2, 7.0, "y", Color3.fromRGB(216, 208, 196), "Concrete")
			-- everything above the base goes round: the deck, the column, the canopy and the horses
			Lively.pivot(r, CFrame.new(0, 0.3, 0), "spin", { speed = 0.5 })
			Lively.moving(r, 1, function()
				r:cyl(0, 0.27, 0, 0.14, 6.7, "y", r.c2, "SmoothPlastic")
				r:cyl(0, 0.35, 0, 0.3, 6.6, "y", Color3.fromRGB(200, 154, 106), "WoodPlanks")
				r:cyl(0, 3.0, 0, 5.0, 1.0, "y", r.c2, "SmoothPlastic")
				for k = 0, 5 do
					r:boxAt(
						CFrame.Angles(0, k * math.pi / 3, 0) * CFrame.new(0, 3.0, 0.5),
						0.36,
						2.4,
						0.06,
						GLASS,
						"Glass"
					)
				end
				r:cyl(0, 5.45, 0, 0.1, 7.0, "y", r.c1, "Fabric")
				r:cone(0, 6.0, 0, 1.0, 7.0, r.c1, "Fabric")
				for i = 0, 15 do
					r:boxAt(
						CFrame.Angles(0, i * math.pi / 8, 0) * CFrame.new(0, 5.2, 3.43),
						1.3,
						0.42,
						0.06,
						if i % 2 == 0 then r.c2 else r.c1,
						"Fabric"
					)
				end
				r:cyl(0, 6.8, 0, 0.6, 0.08, "y", C.Gold, "Metal")
				r:ball(0, 7.15, 0, 0.24, C.Gold, "Metal")
				r:tri(
					Vector3.new(0, 6.95, 0),
					Vector3.new(0.5, 6.85, 0),
					Vector3.new(0, 6.75, 0),
					0.03,
					C.Pink,
					"Fabric"
				)
				local manes = { C.Pink, C.Blue, C.Yellow }
				for k = 0, 5 do
					local hf = CFrame.Angles(0, k * math.pi / 3 + math.pi / 6, 0) * CFrame.new(2.4, 0, 0)
					local body = if k % 2 == 0 then C.White else Color3.fromRGB(240, 226, 206)
					local trim = manes[k % 3 + 1]
					r:cyl(hf.X, 2.95, hf.Z, 4.9, 0.1, "y", C.Gold, "Metal")
					r:lump(hf * CFrame.new(0, 1.8, 0), 0.4, 0.5, 1.05, body, "SmoothPlastic")
					r:boxAt(
						hf * CFrame.new(0, 2.15, -0.45) * CFrame.Angles(-0.6, 0, 0),
						0.24,
						0.6,
						0.28,
						body,
						"SmoothPlastic"
					)
					r:lump(
						hf * CFrame.new(0, 2.42, -0.72) * CFrame.Angles(0.5, 0, 0),
						0.26,
						0.28,
						0.5,
						body,
						"SmoothPlastic"
					)
					r:boxAt(
						hf * CFrame.new(0, 2.24, -0.36) * CFrame.Angles(-0.6, 0, 0),
						0.1,
						0.62,
						0.12,
						trim,
						"Fabric"
					)
					for _, sx in { -1, 1 } do
						r:boxAt(hf * CFrame.new(sx * 0.07, 2.6, -0.66), 0.06, 0.16, 0.08, body, "SmoothPlastic")
						r:boxAt(
							hf * CFrame.new(sx * 0.1, 1.45, -0.35) * CFrame.Angles(0.6, 0, 0),
							0.1,
							0.55,
							0.1,
							body,
							"SmoothPlastic"
						)
						r:boxAt(hf * CFrame.new(sx * 0.1, 1.35, 0.35), 0.1, 0.6, 0.1, body, "SmoothPlastic")
					end
					r:boxAt(hf * CFrame.new(0, 1.75, 0.6) * CFrame.Angles(-0.5, 0, 0), 0.1, 0.5, 0.12, trim, "Fabric")
					r:boxAt(hf * CFrame.new(0, 2.05, 0.05), 0.44, 0.08, 0.36, trim, "Fabric")
				end
			end)
		end,
	},
	------------------------------------------------------------------------------------------
	-- On walls
	{
		id = "move_station_clock",
		name = "Station clock",
		cat = "walldecor",
		style = "modern",
		price = 90,
		place = "wall",
		size = Vector3.new(2.4, 2.4, 0.5),
		c1 = "445262",
		c2 = "F6F1E6",
		tags = { "clock" },
		lively = true,
		build = function(r: R)
			-- a plate on the wall, the rim and the face proud of it, the marks round the face
			r:block(-0.3, 1.0, 0, 0.3, 1.4, 0.04, r.c1, "Metal")
			r:cyl(0, 1.2, 0.15, 0.26, 2.4, "z", r.c1, "Metal")
			r:cyl(0, 1.2, 0.185, 0.29, 2.16, "z", r.c2, "SmoothPlastic")
			hourMarks(r, 0, 1.2, 0.345, 0.88, 0.22, INK)
			r:cyl(0, 1.2, 0.47, 0.04, 0.12, "z", INK, "Metal")
			-- the hands: the town's own hour and minute, and a red second hand sweeping round
			local at = CFrame.new(0, 1.2, 0.4)
			Lively.pivot(r, at, "minute", { speed = -1, axis = "Z" })
			Lively.moving(r, 1, function()
				r:boxAt(CFrame.new(0, 1.2 + 0.36, 0.405), 0.06, 0.86, 0.03, INK, "SmoothPlastic")
			end)
			Lively.pivot(r, at, "hour", { speed = -1, axis = "Z", group = 2 })
			Lively.moving(r, 2, function()
				r:boxAt(CFrame.new(0, 1.2 + 0.24, 0.375), 0.09, 0.6, 0.03, INK, "SmoothPlastic")
			end)
			Lively.pivot(r, at, "spin", { speed = -math.pi * 2 / 60, axis = "Z", group = 3 })
			Lively.moving(r, 3, function()
				r:boxAt(CFrame.new(0, 1.2 + 0.3, 0.45), 0.03, 0.95, 0.02, C.Red, "SmoothPlastic")
				r:cyl(0, 1.2 + 0.62, 0.45, 0.02, 0.1, "z", C.Red, "SmoothPlastic")
			end)
		end,
	},
	{
		id = "move_pendulum_clock",
		name = "Pendulum clock",
		cat = "walldecor",
		style = "cozy",
		price = 140,
		place = "wall",
		size = Vector3.new(1.6, 3.7, 0.8),
		c1 = "8E6446",
		c2 = "F3E8CF",
		tags = { "clock" },
		lively = true,
		build = function(r: R)
			local dk = shade(r.c1, 0.78)
			-- the case: back, sides, a base and a pediment with a brass knob
			r:block(-0.7, 0.2, 0, 0.7, 3.2, 0.06, dk, "Wood")
			for _, sx in { -1, 1 } do
				r:block(
					sx * 0.62 - (if sx > 0 then 0 else 0.13),
					0.2,
					0.06,
					sx * 0.62 + (if sx > 0 then 0.13 else 0),
					3.2,
					0.62,
					r.c1,
					"Wood"
				)
			end
			r:block(-0.8, 0.0, 0.04, 0.8, 0.12, 0.68, dk, "Wood")
			r:block(-0.75, 0.12, 0.06, 0.75, 0.3, 0.64, r.c1, "Wood")
			r:block(-0.62, 2.2, 0.06, 0.62, 3.2, 0.62, r.c1, "Wood")
			r:block(-0.62, 2.1, 0.5, 0.62, 2.2, 0.62, r.c1, "Wood")
			r:block(-0.62, 0.3, 0.5, 0.62, 0.4, 0.62, r.c1, "Wood")
			r:tri(
				Vector3.new(-0.8, 3.2, 0.35),
				Vector3.new(0.8, 3.2, 0.35),
				Vector3.new(0, 3.55, 0.35),
				0.56,
				r.c1,
				"Wood"
			)
			r:block(-0.8, 3.2, 0.04, 0.8, 3.26, 0.66, dk, "Wood")
			r:ball(0, 3.62, 0.35, 0.16, C.Gold, "Metal")
			-- the dial, its marks, a glass door with brass weights behind it
			r:cyl(0, 2.7, 0.64, 0.04, 0.96, "z", r.c2, "SmoothPlastic")
			hourMarks(r, 0, 2.7, 0.675, 0.42, 0.1, INK)
			r:cyl(0, 2.7, 0.73, 0.04, 0.08, "z", C.Gold, "Metal")
			for _, x in { -0.36, 0.36 } do
				rod(r, Vector3.new(x, 2.2, 0.3), Vector3.new(x, 1.5, 0.3), 0.02, C.Gold, "Metal")
				r:cyl(x, 1.25, 0.3, 0.5, 0.16, "y", C.Gold, "Metal")
			end
			local door = r:glass(-0.55, 0.4, 0.55, 0.55, 2.1, 0.58)
			door.transp = 0.6
			r:block(-0.62, 0.4, 0.58, -0.55, 2.1, 0.62, dk, "Wood")
			r:block(0.55, 0.4, 0.58, 0.62, 2.1, 0.62, dk, "Wood")
			-- the hands at the town's hour, and the pendulum swinging under them
			local at = CFrame.new(0, 2.7, 0.69)
			Lively.pivot(r, at, "minute", { speed = -1, axis = "Z" })
			Lively.moving(r, 1, function()
				r:boxAt(CFrame.new(0, 2.7 + 0.17, 0.705), 0.035, 0.42, 0.03, INK, "SmoothPlastic")
			end)
			Lively.pivot(r, at, "hour", { speed = -1, axis = "Z", group = 2 })
			Lively.moving(r, 2, function()
				r:boxAt(CFrame.new(0, 2.7 + 0.12, 0.675), 0.05, 0.3, 0.03, INK, "SmoothPlastic")
			end)
			Lively.pivot(r, CFrame.new(0, 2.15, 0.3), "swing", { speed = 2.4, amount = 0.2, axis = "Z", group = 3 })
			Lively.moving(r, 3, function()
				r:boxAt(CFrame.new(0, 1.47, 0.3), 0.05, 1.3, 0.03, C.Gold, "Metal")
				r:cyl(0, 0.8, 0.3, 0.06, 0.38, "z", C.Gold, "Metal")
			end)
		end,
	},
	{
		id = "move_wall_fountain",
		name = "Wall fountain",
		cat = "walldecor",
		style = "garden",
		price = 240,
		place = "wall",
		size = Vector3.new(2.6, 4.0, 1.6),
		c1 = "C9C1B2",
		c2 = "86BFD8",
		lively = true,
		build = function(r: R)
			local dk = shade(r.c1, 0.86)
			-- an arched stone back with a shell over the spout
			r:block(-1.1, 0.9, 0, 1.1, 2.8, 0.2, r.c1, "Slate")
			r:cyl(0, 2.8, 0.1, 0.2, 2.2, "z", r.c1, "Slate")
			r:block(-1.18, 0.9, 0, -1.02, 2.8, 0.26, dk, "Slate")
			r:block(1.02, 0.9, 0, 1.18, 2.8, 0.26, dk, "Slate")
			for k = 0, 4 do
				local a = math.rad(25 + k * 32.5)
				r:boxAt(
					CFrame.new(0, 2.55, 0.24) * CFrame.Angles(0, 0, a - math.pi / 2) * CFrame.new(0, 0.28, 0),
					0.16,
					0.52,
					0.06,
					shade(r.c1, 1.06),
					"Marble"
				)
			end
			r:cyl(0, 2.55, 0.26, 0.06, 0.24, "z", dk, "Marble")
			-- the spout and its stream
			r:cyl(0, 2.25, 0.4, 0.4, 0.14, "z", C.Gold, "Metal")
			local stream = r:cyl(0, 1.55, 0.6, 1.3, 0.1, "y", r.c2, "Glass")
			stream.transp = 0.45
			-- the basin: walls round a pool of water, on a plinth
			r:block(-1.25, 0, 0.0, 1.25, 0.3, 1.55, dk, "Slate")
			r:block(-1.2, 0.3, 1.3, 1.2, 0.92, 1.5, r.c1, "Slate")
			for _, sx in { -1, 1 } do
				r:block(
					sx * 1.2 - (if sx > 0 then 0.2 else 0),
					0.3,
					0.2,
					sx * 1.2 + (if sx > 0 then 0 else 0.2),
					0.92,
					1.5,
					r.c1,
					"Slate"
				)
			end
			r:block(-1.24, 0.92, 1.26, 1.24, 1.0, 1.54, dk, "Slate")
			local pool = r:block(-1.0, 0.3, 0.2, 1.0, 0.8, 1.3, r.c2, "Glass")
			pool.transp = 0.25
			-- ivy over one corner
			for i, p in { { -1.0, 2.9, 0.26 }, { -0.75, 3.15, 0.24 }, { -1.1, 2.5, 0.28 }, { -0.5, 3.4, 0.2 } } do
				r:lump(CFrame.new(p[1], p[2], p[3]) * CFrame.Angles(0, 0, i), 0.42, 0.3, 0.14, C.Leaf, "Grass")
			end
			Lively.fx(r, "trickle", 0, 2.25, 0.62, { w = 0.12, h = 0.12, d = 0.1 })
			Lively.fx(r, "ripple", 0, 0.82, 0.65, { w = 0.6, d = 0.5 })
		end,
	},
}

return items
