--!strict
-- Things events bring into the world: while a scene plays, the props it names appear by the
-- villagers in it (Services/Events puts them down and takes them away), and a few stay a while
-- after (a sandcastle, a snowman, a mural). Drawn with Build/Recipe like the catalog, in the
-- same style, and kept to plain parts so a scene costs a few dozen at most. Every prop stands on
-- the ground: the origin is the middle of its footprint, +y up, +z its front, all of it inside
-- its `size`. Look at them with `sh tools/preview/render.sh props <png>` (or props:<id>,<id>).

local Recipe = require(script.Parent.Parent.Build.Recipe)
local Catalog = require(script.Parent.Parent.Build.Catalog)
local Colors = require(script.Parent.Parent.Util.Colors)

local C = Recipe.Colors

type R = Recipe.Recipe

export type Prop = {
	id: string,
	name: string,
	size: Vector3,
	build: (r: R) -> (),
}

local function shade(c: Color3, k: number): Color3
	return Colors.shade(c, k)
end

local INK = Color3.fromRGB(58, 48, 50)
local SNOW = Color3.fromRGB(246, 248, 252)
local SAND = Color3.fromRGB(230, 208, 160)
local STRAW = Color3.fromRGB(222, 190, 110)
local CARD = Color3.fromRGB(196, 156, 108)
local LEMON = Color3.fromRGB(246, 214, 92)

-- A round rod from a to b.
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

-- A path of rods through points, joined at each bend.
local function path(r: R, pts: { Vector3 }, d: number, color: Color3, mat: string?)
	for k = 1, #pts - 1 do
		local dir = (pts[k + 1] - pts[k]).Unit * (d / 2)
		rod(r, pts[k] - dir, pts[k + 1] + dir, d, color, mat)
	end
end

-- A cone pointing along a direction (Recipe's cone points up).
local function coneAlong(r: R, at: Vector3, dir: Vector3, length: number, d: number, color: Color3, mat: string?)
	local y = dir.Unit
	local side = if math.abs(y.Y) > 0.99 then Vector3.xAxis else Vector3.yAxis
	local x = side:Cross(y).Unit
	r:add({
		shape = "Cone",
		cf = CFrame.fromMatrix(at + y * (length / 2), x, y, x:Cross(y)),
		size = Vector3.new(d, length, d),
		color = color,
		mat = mat or "SmoothPlastic",
	})
end

-- A flat disc lying on the ground or on a top at height y.
local function disc(r: R, x: number, y: number, z: number, h: number, d: number, color: Color3, mat: string?)
	r:cyl(x, y + h / 2, z, h, d, "y", color, mat or "SmoothPlastic")
end

-- A little bow (two loops and a knot) facing +z at a point.
local function bow(r: R, at: Vector3, size: number, color: Color3)
	for _, s in { -1, 1 } do
		r:lump(
			CFrame.new(at + Vector3.new(s * size * 0.6, 0, 0)) * CFrame.Angles(0, 0, s * 0.5),
			size,
			size * 0.55,
			size * 0.3,
			color,
			"Fabric"
		)
	end
	r:ball(at.X, at.Y, at.Z + 0.01, size * 0.4, shade(color, 0.85), "Fabric")
end

local list: { Prop } = {
	{
		id = "picnic",
		name = "Picnic",
		size = Vector3.new(4, 1.4, 3),
		build = function(r: R)
			-- a checked rug, a wicker basket with its lid up, a plate of sandwiches, two cups,
			-- a jug of lemonade and an apple
			local red, cream = Color3.fromRGB(214, 96, 96), Color3.fromRGB(246, 238, 220)
			r:noCollide(r:block(-1.9, 0, -1.4, 1.9, 0.03, 1.4, cream, "Fabric"))
			for i = 0, 5 do
				for j = 0, 3 do
					if (i + j) % 2 == 0 then
						r:noCollide(
							r:block(
								-1.9 + i * 0.633,
								0.03,
								-1.4 + j * 0.7,
								-1.9 + (i + 1) * 0.633,
								0.06,
								-1.4 + (j + 1) * 0.7,
								red,
								"Fabric"
							)
						)
					end
				end
			end
			local wicker = Color3.fromRGB(196, 150, 92)
			r:block(-1.6, 0.06, -1.1, -0.7, 0.66, -0.5, wicker, "Fabric")
			for k = 0, 3 do
				r:block(-1.63, 0.16 + k * 0.14, -1.13, -0.67, 0.2 + k * 0.14, -0.47, shade(wicker, 0.82), "Fabric")
			end
			r:boxAt(
				CFrame.new(-1.15, 0.86, -1.18) * CFrame.Angles(math.rad(70), 0, 0),
				0.92,
				0.04,
				0.42,
				shade(wicker, 1.1),
				"Fabric"
			)
			path(
				r,
				{
					Vector3.new(-1.5, 0.66, -0.8),
					Vector3.new(-1.4, 1.1, -0.8),
					Vector3.new(-0.9, 1.1, -0.8),
					Vector3.new(-0.8, 0.66, -0.8),
				},
				0.06,
				shade(wicker, 0.7)
			)
			disc(r, 0.2, 0.06, 0.2, 0.04, 0.9, C.White)
			for k = 0, 2 do
				local a = k * 2.1
				r:tri(
					Vector3.new(0.2 + math.cos(a) * 0.05, 0.13, 0.2 + math.sin(a) * 0.05),
					Vector3.new(0.2 + math.cos(a) * 0.36, 0.13, 0.2 + math.sin(a) * 0.36),
					Vector3.new(0.2 + math.cos(a + 0.8) * 0.36, 0.13, 0.2 + math.sin(a + 0.8) * 0.36),
					0.12,
					Color3.fromRGB(240, 220, 170)
				)
			end
			for _, p in { Vector3.new(1.1, 0, -0.6), Vector3.new(1.4, 0, 0.5) } do
				r:cyl(p.X, 0.2, p.Z, 0.28, 0.2, "y", C.White, "SmoothPlastic")
				r:cyl(p.X, 0.355, p.Z, 0.03, 0.16, "y", LEMON, "SmoothPlastic")
			end
			r:cyl(0.9, 0.35, 0.9, 0.58, 0.36, "y", C.Glass, "Glass").transp = 0.5
			r:cyl(0.9, 0.3, 0.9, 0.46, 0.3, "y", LEMON, "SmoothPlastic")
			r:ball(-0.5, 0.18, 0.8, 0.24, C.Red, "SmoothPlastic")
			r:cyl(-0.5, 0.33, 0.8, 0.08, 0.03, "y", C.Bark, "Wood")
		end,
	},
	{
		id = "cake",
		name = "Birthday cake",
		size = Vector3.new(1.8, 2.6, 1.8),
		build = function(r: R)
			-- a little round table with a cloth, a cake stand, a cake in two tiers with icing
			-- running down, strawberries on top and five lit candles
			local wood = Color3.fromRGB(150, 110, 76)
			r:cyl(0, 0.04, 0, 0.08, 0.9, "y", wood, "Wood")
			r:cyl(0, 0.6, 0, 1.1, 0.14, "y", wood, "Wood")
			r:cyl(0, 1.19, 0, 0.08, 1.6, "y", Color3.fromRGB(246, 238, 220), "Fabric")
			r:cyl(0, 1.1, 0, 0.12, 1.66, "y", Color3.fromRGB(236, 150, 160), "Fabric")
			r:cyl(0, 1.28, 0, 0.1, 0.14, "y", C.White, "SmoothPlastic")
			r:cyl(0, 1.35, 0, 0.04, 1.0, "y", C.White, "SmoothPlastic")
			local sponge, icing = Color3.fromRGB(232, 196, 140), Color3.fromRGB(250, 236, 240)
			r:cyl(0, 1.55, 0, 0.36, 0.86, "y", sponge, "SmoothPlastic")
			r:cyl(0, 1.75, 0, 0.06, 0.9, "y", icing, "SmoothPlastic")
			for i = 0, 7 do
				local a = i * math.pi / 4
				r:boxAt(
					CFrame.new(math.cos(a) * 0.44, 1.64 - (i % 2) * 0.04, math.sin(a) * 0.44) * CFrame.Angles(0, -a, 0),
					0.05,
					0.18 + (i % 2) * 0.08,
					0.1,
					icing,
					"SmoothPlastic"
				)
			end
			r:cyl(0, 1.92, 0, 0.3, 0.56, "y", sponge, "SmoothPlastic")
			r:cyl(0, 2.09, 0, 0.05, 0.6, "y", icing, "SmoothPlastic")
			for i = 0, 4 do
				local a = i * math.pi * 2 / 5
				local x, z = math.cos(a) * 0.18, math.sin(a) * 0.18
				r:cyl(x, 2.24, z, 0.24, 0.04, "y", if i % 2 == 0 then C.Pink else C.Blue, "SmoothPlastic")
				r:glow(
					r:lump(CFrame.new(x, 2.4, z), 0.06, 0.1, 0.06, Color3.fromRGB(255, 200, 90), "Neon"),
					if i == 0 then 8 else 0
				)
				r:lump(
					CFrame.new(math.cos(a + 0.6) * 0.38, 1.82, math.sin(a + 0.6) * 0.38),
					0.1,
					0.1,
					0.1,
					C.Red,
					"SmoothPlastic"
				)
			end
		end,
	},
	{
		id = "guitar",
		name = "Guitar",
		size = Vector3.new(1.4, 3.6, 1.2),
		build = function(r: R)
			-- an acoustic guitar leaning back on its stand: a body of two rounds, a dark sound
			-- hole with a ring, a bridge, six strings up the neck to the head and its pegs
			local stand = C.DarkMetal
			path(
				r,
				{ Vector3.new(-0.5, 0, 0.4), Vector3.new(0, 0.5, 0.1), Vector3.new(0.5, 0, 0.4) },
				0.05,
				stand,
				"Metal"
			)
			rod(r, Vector3.new(0, 0, -0.45), Vector3.new(0, 1.9, -0.2), 0.05, stand, "Metal")
			local wood, dark = Color3.fromRGB(214, 160, 98), Color3.fromRGB(110, 70, 48)
			local tilt = CFrame.new(0, 0, 0.1) * CFrame.Angles(math.rad(-12), 0, 0)
			local function at(x: number, y: number, z: number): CFrame
				return tilt * CFrame.new(x, y, z)
			end
			r:add({
				shape = "Cylinder",
				cf = at(0, 0.85, 0) * CFrame.Angles(0, math.pi / 2, 0),
				size = Vector3.new(0.3, 1.1, 1.1),
				color = wood,
				mat = "Wood",
			})
			r:add({
				shape = "Cylinder",
				cf = at(0, 1.5, 0) * CFrame.Angles(0, math.pi / 2, 0),
				size = Vector3.new(0.3, 0.86, 0.86),
				color = wood,
				mat = "Wood",
			})
			r:add({
				shape = "Cylinder",
				cf = at(0, 1.3, 0.17) * CFrame.Angles(0, math.pi / 2, 0),
				size = Vector3.new(0.03, 0.36, 0.36),
				color = shade(wood, 0.8),
				mat = "Wood",
			})
			r:add({
				shape = "Cylinder",
				cf = at(0, 1.3, 0.2) * CFrame.Angles(0, math.pi / 2, 0),
				size = Vector3.new(0.03, 0.28, 0.28),
				color = INK,
				mat = "SmoothPlastic",
			})
			r:boxAt(at(0, 0.72, 0.17), 0.4, 0.08, 0.05, dark, "Wood")
			r:boxAt(at(0, 2.35, 0.12), 0.16, 1.5, 0.12, dark, "Wood")
			r:boxAt(at(0, 3.22, 0.08), 0.26, 0.36, 0.1, dark, "Wood")
			for _, s in { -1, 1 } do
				for k = 0, 2 do
					r:add({
						shape = "Cylinder",
						cf = at(s * 0.17, 3.1 + k * 0.1, 0.08),
						size = Vector3.new(0.08, 0.05, 0.05),
						color = C.Metal,
						mat = "Metal",
					})
				end
			end
			for k = -2.5, 2.5 do
				r:boxAt(at(k * 0.025, 1.85, 0.25), 0.008, 2.3, 0.008, C.Metal, "Metal")
			end
		end,
	},
	{
		id = "easel",
		name = "Easel",
		size = Vector3.new(3, 4.8, 2.2),
		build = function(r: R)
			-- a three legged easel holding a canvas painted halfway (sky, sea and a hill on the
			-- left, pencil lines on bare white on the right), and a stool by it with a palette
			-- of paint dabs and a jar of brushes
			local wood = Color3.fromRGB(176, 130, 86)
			rod(r, Vector3.new(-0.7, 0, 0.3), Vector3.new(-0.1, 4.5, 0), 0.1, wood, "Wood")
			rod(r, Vector3.new(0.7, 0, 0.3), Vector3.new(0.1, 4.5, 0), 0.1, wood, "Wood")
			rod(r, Vector3.new(0, 0, -0.9), Vector3.new(0, 4.3, -0.05), 0.1, wood, "Wood")
			r:block(-0.85, 1.55, 0.06, 0.85, 1.65, 0.36, wood, "Wood")
			r:block(-0.8, 1.65, 0.12, 0.8, 3.75, 0.2, C.White, "Fabric")
			local sky, sea, hill =
				Color3.fromRGB(150, 196, 226), Color3.fromRGB(90, 150, 196), Color3.fromRGB(120, 170, 100)
			r:block(-0.8, 2.8, 0.2, 0.05, 3.75, 0.23, sky, "SmoothPlastic")
			r:block(-0.8, 2.2, 0.2, 0.05, 2.8, 0.23, sea, "SmoothPlastic")
			r:tri(
				Vector3.new(-0.8, 1.65, 0.245),
				Vector3.new(0.05, 1.65, 0.245),
				Vector3.new(-0.5, 2.6, 0.245),
				0.03,
				hill
			)
			r:block(-0.8, 1.65, 0.2, 0.05, 2.2, 0.23, hill, "SmoothPlastic")
			r:cyl(-0.45, 3.4, 0.245, 0.03, 0.3, "z", LEMON, "SmoothPlastic")
			for _, line in { { 0.15, 2.4, 0.7, 2.6 }, { 0.2, 2.0, 0.65, 1.9 }, { 0.3, 3.1, 0.6, 3.3 } } do
				r:beam(
					Vector3.new(line[1], line[2], 0.225),
					Vector3.new(line[3], line[4], 0.225),
					0.025,
					0.02,
					Color3.fromRGB(150, 150, 160)
				)
			end
			-- the stool, palette and brushes
			local sx, sz = 1.05, 0.5
			disc(r, sx, 1.1, sz, 0.1, 0.8, wood, "Wood")
			for i = 0, 2 do
				local a = i * math.pi * 2 / 3
				rod(
					r,
					Vector3.new(sx + math.cos(a) * 0.38, 0, sz + math.sin(a) * 0.38),
					Vector3.new(sx + math.cos(a) * 0.25, 1.1, sz + math.sin(a) * 0.25),
					0.07,
					shade(wood, 0.85),
					"Wood"
				)
			end
			r:lump(CFrame.new(sx - 0.05, 1.23, sz), 0.6, 0.04, 0.44, Color3.fromRGB(196, 150, 100), "Wood")
			for i, col in { C.Red, LEMON, C.Blue, C.White, Color3.fromRGB(120, 170, 100) } do
				local a = i * 1.1
				r:ball(sx - 0.05 + math.cos(a) * 0.18, 1.26, sz + math.sin(a) * 0.13, 0.08, col)
			end
			r:cyl(sx + 0.22, 1.3, sz + 0.12, 0.3, 0.16, "y", C.Glass, "Glass").transp = 0.5
			for k = 0, 2 do
				rod(
					r,
					Vector3.new(sx + 0.22, 1.2, sz + 0.12),
					Vector3.new(sx + 0.15 + k * 0.07, 1.68, sz + 0.12 + (k - 1) * 0.05),
					0.03,
					wood,
					"Wood"
				)
			end
		end,
	},
	{
		id = "kite",
		name = "Kite",
		size = Vector3.new(3, 10, 3),
		build = function(r: R)
			-- a kite up in the wind: a diamond in two colours on its crossed sticks, a tail of
			-- bows, and its string down to a stake in the ground with a winder
			r:cyl(0, 0.3, 0, 0.6, 0.08, "y", C.Bark, "Wood")
			r:block(-0.2, 0.3, -0.06, 0.2, 0.5, 0.06, Color3.fromRGB(196, 150, 100), "Wood")
			local top = Vector3.new(0.6, 8.8, 0.4)
			rod(r, Vector3.new(0, 0.45, 0), top, 0.02, C.White, "Fabric")
			local cf = CFrame.new(top) * CFrame.Angles(math.rad(-20), math.rad(15), 0)
			local function p(x: number, y: number): Vector3
				return (cf * CFrame.new(x, y, 0)).Position
			end
			r:tri(p(0, 0.9), p(-0.6, 0), p(0, 0), 0.03, Color3.fromRGB(226, 96, 96))
			r:tri(p(0, 0.9), p(0.6, 0), p(0, 0), 0.03, LEMON)
			r:tri(p(0, -1.2), p(-0.6, 0), p(0, 0), 0.03, LEMON)
			r:tri(p(0, -1.2), p(0.6, 0), p(0, 0), 0.03, Color3.fromRGB(226, 96, 96))
			rod(r, p(0, 0.9), p(0, -1.2), 0.04, C.Bark, "Wood")
			rod(r, p(-0.6, 0), p(0.6, 0), 0.04, C.Bark, "Wood")
			local tail = { p(0, -1.2), p(0.15, -1.9), p(-0.05, -2.6), p(0.2, -3.3) }
			path(r, tail, 0.02, C.White, "Fabric")
			for k = 2, #tail do
				bow(r, tail[k], 0.14, if k % 2 == 0 then C.Blue else C.Pink)
			end
		end,
	},
	{
		id = "snowman",
		name = "Snowman",
		size = Vector3.new(2.4, 4.6, 2.4),
		build = function(r: R)
			-- three rolled balls of snow, coal eyes, a smile and buttons, a carrot nose, a hat
			-- with a band, a scarf with its end hanging down and stick arms with twigs
			r:ball(0, 0.9, 0, 2.0, SNOW, "Snow")
			r:ball(0, 2.35, 0, 1.4, SNOW, "Snow")
			r:ball(0, 3.4, 0, 1.0, SNOW, "Snow")
			for _, s in { -1, 1 } do
				r:ball(s * 0.17, 3.52, 0.43, 0.1, INK, "Slate")
			end
			for k = -2, 2 do
				r:ball(k * 0.08, 3.22 + math.abs(k) * 0.03, 0.46 - math.abs(k) * 0.02, 0.06, INK, "Slate")
			end
			for k = 0, 2 do
				r:ball(0, 2.1 + k * 0.28, 0.69 - k * 0.04, 0.12, INK, "Slate")
			end
			coneAlong(r, Vector3.new(0, 3.4, 0.46), Vector3.new(0, -0.1, 1), 0.5, 0.14, Color3.fromRGB(240, 140, 60))
			r:cyl(0, 3.86, 0, 0.06, 0.95, "y", INK, "Fabric")
			r:cyl(0, 4.12, 0, 0.5, 0.62, "y", INK, "Fabric")
			r:cyl(0, 3.95, 0, 0.1, 0.66, "y", Color3.fromRGB(200, 80, 80), "Fabric")
			local scarf = Color3.fromRGB(96, 150, 200)
			r:cyl(0, 2.98, 0, 0.2, 1.08, "y", scarf, "Fabric")
			r:boxAt(
				CFrame.new(0.3, 2.7, 0.48) * CFrame.Angles(math.rad(-10), 0, math.rad(8)),
				0.24,
				0.6,
				0.08,
				scarf,
				"Fabric"
			)
			for _, s in { -1, 1 } do
				local hand = Vector3.new(s * 1.2, 2.95, 0.1)
				rod(r, Vector3.new(s * 0.55, 2.45, 0), hand, 0.07, C.Bark, "Wood")
				rod(
					r,
					hand:Lerp(Vector3.new(s * 0.55, 2.45, 0), 0.25),
					hand + Vector3.new(0, 0.25, 0.05),
					0.04,
					C.Bark,
					"Wood"
				)
			end
		end,
	},
	{
		id = "leaves",
		name = "Pile of leaves",
		size = Vector3.new(3.2, 1.6, 3),
		build = function(r: R)
			-- a heap of autumn leaves in four colours, a few blown loose, and the rake that
			-- gathered them leaning on it
			local colours = {
				Color3.fromRGB(222, 128, 60),
				Color3.fromRGB(200, 80, 60),
				Color3.fromRGB(236, 186, 80),
				Color3.fromRGB(168, 110, 70),
			}
			local n = 0
			for ring = 0, 3 do
				local count = 10 - ring * 2
				local rad = 1.1 - ring * 0.3
				for i = 0, count - 1 do
					n += 1
					local a = i * math.pi * 2 / count + ring * 0.4
					r:lump(
						CFrame.new(math.cos(a) * rad, 0.2 + ring * 0.28, math.sin(a) * rad) * CFrame.Angles(0, a, 0.3),
						0.7,
						0.36,
						0.55,
						colours[n % #colours + 1],
						"Grass"
					)
				end
			end
			r:lump(CFrame.new(0, 1.2, 0), 0.6, 0.34, 0.5, colours[3], "Grass")
			for i, p in { Vector3.new(1.4, 0, 0.9), Vector3.new(-1.3, 0, 1.1), Vector3.new(0.6, 0, -1.35) } do
				r:noCollide(
					r:boxAt(CFrame.new(p.X, 0.02, p.Z) * CFrame.Angles(0, i, 0), 0.2, 0.03, 0.12, colours[i], "Grass")
				)
			end
			local wood = Color3.fromRGB(176, 130, 86)
			rod(r, Vector3.new(1.5, 0.05, -1.3), Vector3.new(0.4, 1.5, 0.2), 0.08, wood, "Wood")
			local head = Vector3.new(1.5, 0.1, -1.3)
			r:boxAt(
				CFrame.lookAt(head, head + Vector3.new(-1.1, 1.45, 1.5)) * CFrame.Angles(0, math.pi / 2, 0),
				0.06,
				0.06,
				0.7,
				C.DarkMetal,
				"Metal"
			)
		end,
	},
	{
		id = "telescope",
		name = "Telescope",
		size = Vector3.new(1.8, 3.2, 1.8),
		build = function(r: R)
			-- a brass telescope on a wooden tripod, tilted up at the sky, with its eyepiece,
			-- the lens ring and a little finder scope on its side
			local wood = Color3.fromRGB(150, 110, 76)
			local head = Vector3.new(0, 2.0, 0)
			for i = 0, 2 do
				local a = i * math.pi * 2 / 3 + 0.5
				rod(r, Vector3.new(math.cos(a) * 0.75, 0, math.sin(a) * 0.75), head, 0.08, wood, "Wood")
			end
			r:cyl(0, 2.05, 0, 0.14, 0.24, "y", C.DarkMetal, "Metal")
			local dir = Vector3.new(0, 0.62, 0.78).Unit
			local brass = Color3.fromRGB(206, 170, 96)
			rod(
				r,
				head + Vector3.new(0, 0.12, 0) - dir * 0.7,
				head + Vector3.new(0, 0.12, 0) + dir * 0.9,
				0.24,
				brass,
				"Metal"
			)
			rod(
				r,
				head + Vector3.new(0, 0.12, 0) + dir * 0.85,
				head + Vector3.new(0, 0.12, 0) + dir * 0.98,
				0.3,
				shade(brass, 0.8),
				"Metal"
			)
			rod(
				r,
				head + Vector3.new(0, 0.12, 0) - dir * 0.95,
				head + Vector3.new(0, 0.12, 0) - dir * 0.7,
				0.1,
				C.DarkMetal,
				"Metal"
			)
			local side = Vector3.new(0.17, 0.22, 0)
			rod(r, head + side - dir * 0.2, head + side + dir * 0.3, 0.07, C.DarkMetal, "Metal")
		end,
	},
	{
		id = "box",
		name = "Mystery box",
		size = Vector3.new(1.6, 1.4, 1.6),
		build = function(r: R)
			-- a cardboard box tied up with string in a bow, brown tape on its seams, a tag with a
			-- question mark, and a little hole punched in the side
			r:block(-0.7, 0, -0.7, 0.7, 1.1, 0.7, CARD, "Fabric")
			r:block(-0.72, 1.1, -0.72, 0.72, 1.16, 0.72, shade(CARD, 1.08), "Fabric")
			r:block(-0.12, 1.16, -0.72, 0.12, 1.19, 0.72, Color3.fromRGB(150, 110, 70), "Fabric")
			local string = Color3.fromRGB(240, 232, 214)
			r:block(-0.74, 0.04, -0.04, 0.74, 1.23, 0.04, string, "Fabric")
			r:block(-0.04, 0.04, -0.74, 0.04, 1.23, 0.74, string, "Fabric")
			bow(r, Vector3.new(0, 1.26, 0.05), 0.2, string)
			r:block(0.2, 0.55, 0.72, 0.6, 0.85, 0.75, C.Paper, "SmoothPlastic")
			r:block(0.36, 0.6, 0.75, 0.42, 0.65, 0.78, INK, "SmoothPlastic")
			r:block(0.36, 0.68, 0.75, 0.42, 0.72, 0.78, INK, "SmoothPlastic")
			r:block(0.42, 0.72, 0.75, 0.48, 0.8, 0.78, INK, "SmoothPlastic")
			r:block(0.3, 0.78, 0.75, 0.46, 0.82, 0.78, INK, "SmoothPlastic")
			r:cyl(-0.72, 0.6, 0.3, 0.04, 0.1, "x", INK, "SmoothPlastic")
		end,
	},
	{
		id = "marrow",
		name = "Giant marrow",
		size = Vector3.new(3.8, 1.6, 2.2),
		build = function(r: R)
			-- an enormous striped marrow on a bed of straw with its stalk and a curl of leaf,
			-- and the watering can that did it
			for i = 0, 6 do
				local a = i * 0.9
				r:lump(
					CFrame.new(math.cos(a) * 0.8, 0.05, math.sin(a) * 0.5) * CFrame.Angles(0, a, 0),
					1.0,
					0.1,
					0.5,
					STRAW,
					"Grass"
				)
			end
			local green = Color3.fromRGB(90, 136, 76)
			local cf = CFrame.new(-0.2, 0.62, 0) * CFrame.Angles(0, 0.1, math.rad(4))
			r:lump(cf, 2.8, 1.1, 1.1, green, "SmoothPlastic")
			for k = -2, 2 do
				r:lump(cf * CFrame.new(k * 0.42, 0, 0), 0.12, 1.16, 1.16, shade(green, 1.35), "SmoothPlastic")
			end
			rod(
				r,
				(cf * CFrame.new(1.35, 0.05, 0)).Position,
				(cf * CFrame.new(1.6, 0.2, 0)).Position,
				0.14,
				C.Bark,
				"Wood"
			)
			r:lump(CFrame.new(1.3, 0.75, 0.3) * CFrame.Angles(0.4, 0.3, 0.2), 0.5, 0.04, 0.4, C.Leaf, "Grass")
			local can = Color3.fromRGB(120, 170, 160)
			r:cyl(1.4, 0.3, -0.6, 0.6, 0.5, "y", can, "Metal")
			rod(r, Vector3.new(1.6, 0.25, -0.6), Vector3.new(1.85, 0.6, -0.6), 0.08, can, "Metal")
			disc(r, 1.87, 0.58, -0.6, 0.06, 0.14, shade(can, 0.8), "Metal")
			path(
				r,
				{
					Vector3.new(1.2, 0.5, -0.6),
					Vector3.new(1.25, 0.8, -0.6),
					Vector3.new(1.55, 0.8, -0.6),
					Vector3.new(1.6, 0.55, -0.6),
				},
				0.05,
				shade(can, 0.8),
				"Metal"
			)
		end,
	},
	{
		id = "trophy",
		name = "Prize podium",
		size = Vector3.new(3, 3.6, 1.4),
		build = function(r: R)
			-- a three step podium (first in the middle, painted numbers on the fronts) with a
			-- big gold cup on the top step
			local steps: { { any } } = {
				{ -1.5, -0.5, 0.6, Color3.fromRGB(200, 200, 210) },
				{ -0.5, 0.5, 1.0, Color3.fromRGB(240, 200, 100) },
				{ 0.5, 1.5, 0.4, Color3.fromRGB(210, 150, 110) },
			}
			for i, st in steps do
				r:block(st[1], 0, -0.6, st[2], st[3], 0.6, st[4], "Wood")
				r:block(st[1] + 0.05, st[3] - 0.05, -0.64, st[2] - 0.05, st[3] + 0.04, 0.64, shade(st[4], 1.1), "Wood")
				local num = if i == 2 then 1 elseif i == 1 then 2 else 3
				for k = 1, num do
					r:block(
						(st[1] + st[2]) / 2 - 0.05 + (k - (num + 1) / 2) * 0.16,
						st[3] / 2 - 0.15,
						0.6,
						(st[1] + st[2]) / 2 + 0.05 + (k - (num + 1) / 2) * 0.16,
						st[3] / 2 + 0.15,
						0.63,
						C.White,
						"SmoothPlastic"
					)
				end
			end
			local gold = C.Gold
			r:cyl(0, 1.1, 0, 0.2, 0.5, "y", gold, "Metal")
			r:cyl(0, 1.4, 0, 0.4, 0.14, "y", gold, "Metal")
			r:ball(0, 1.6, 0, 0.26, gold, "Metal")
			r:cyl(0, 1.8, 0, 0.2, 0.5, "y", gold, "Metal")
			r:cyl(0, 2.05, 0, 0.3, 0.8, "y", gold, "Metal")
			r:cyl(0, 2.35, 0, 0.3, 0.94, "y", gold, "Metal")
			r:cyl(0, 2.53, 0, 0.06, 1.0, "y", shade(gold, 1.12), "Metal")
			for _, s in { -1, 1 } do
				path(
					r,
					{
						Vector3.new(s * 0.44, 2.4, 0),
						Vector3.new(s * 0.68, 2.3, 0),
						Vector3.new(s * 0.66, 2.0, 0),
						Vector3.new(s * 0.36, 1.92, 0),
					},
					0.08,
					gold,
					"Metal"
				)
			end
		end,
	},
	{
		id = "sandcastle",
		name = "Sandcastle",
		size = Vector3.new(3.2, 2.2, 3.2),
		build = function(r: R)
			-- a keep with four round towers and their battlements, a gate, shells pressed into
			-- the walls, a flag on top, a moat of sea water, and the bucket and spade
			disc(r, 0, 0, 0, 0.08, 3.0, Color3.fromRGB(110, 176, 206), "SmoothPlastic")
			disc(r, 0, 0.04, 0, 0.1, 2.5, SAND, "Sand")
			r:block(-0.7, 0.14, -0.7, 0.7, 1.0, 0.7, SAND, "Sand")
			for _, x in { -0.7, 0.7 } do
				for _, z in { -0.7, 0.7 } do
					r:cyl(x, 0.75, z, 1.2, 0.56, "y", shade(SAND, 0.95), "Sand")
					for i = 0, 3 do
						local a = i * math.pi / 2 + math.pi / 4
						r:block(
							x + math.cos(a) * 0.2 - 0.07,
							1.35,
							z + math.sin(a) * 0.2 - 0.07,
							x + math.cos(a) * 0.2 + 0.07,
							1.5,
							z + math.sin(a) * 0.2 + 0.07,
							SAND,
							"Sand"
						)
					end
				end
			end
			r:block(-0.2, 0.14, 0.7, 0.2, 0.6, 0.73, Color3.fromRGB(150, 120, 90), "Sand")
			for _, p in { Vector3.new(-0.4, 0.7, 0.71), Vector3.new(0.4, 0.75, 0.71), Vector3.new(0, 0.85, 0.71) } do
				r:lump(CFrame.new(p), 0.12, 0.1, 0.05, Color3.fromRGB(246, 200, 190), "SmoothPlastic")
			end
			rod(r, Vector3.new(0, 1.0, 0), Vector3.new(0, 1.9, 0), 0.04, C.Bark, "Wood")
			r:tri(
				Vector3.new(0, 1.9, 0),
				Vector3.new(0, 1.62, 0),
				Vector3.new(0.42, 1.76, 0),
				0.03,
				Color3.fromRGB(226, 96, 96)
			)
			local bucket = Color3.fromRGB(240, 120, 110)
			r:cyl(1.25, 0.3, 0.9, 0.5, 0.44, "y", bucket, "SmoothPlastic")
			r:cyl(1.25, 0.56, 0.9, 0.04, 0.5, "y", shade(bucket, 1.1), "SmoothPlastic")
			rod(r, Vector3.new(-1.2, 0.05, 1.0), Vector3.new(-0.9, 0.9, 1.25), 0.06, LEMON, "SmoothPlastic")
			r:boxAt(CFrame.new(-1.25, 0.12, 0.95) * CFrame.Angles(0, 0.7, 0), 0.3, 0.04, 0.36, LEMON, "SmoothPlastic")
		end,
	},
	{
		id = "mural",
		name = "Mural",
		size = Vector3.new(6, 4.4, 1.6),
		build = function(r: R)
			-- a long board on two posts, painted by the town: a blue sky with a big sun, the sea,
			-- the island with three little houses and a tree, and everybody's handprints along
			-- the bottom; pots of paint and brushes on the ground
			local wood = Color3.fromRGB(150, 110, 76)
			for _, x in { -2.7, 2.7 } do
				r:block(x - 0.12, 0, -0.12, x + 0.12, 4.2, 0.12, wood, "Wood")
			end
			r:block(-2.9, 1.0, 0.12, 2.9, 4.0, 0.2, Color3.fromRGB(246, 240, 226), "Wood")
			local z1, z2 = 0.2, 0.23
			r:block(-2.8, 2.6, z1, 2.8, 3.9, z2, Color3.fromRGB(150, 196, 226), "SmoothPlastic")
			r:block(-2.8, 1.8, z1, 2.8, 2.6, z2, Color3.fromRGB(90, 150, 196), "SmoothPlastic")
			r:cyl(1.9, 3.35, z2 + 0.015, 0.03, 0.8, "z", LEMON, "SmoothPlastic")
			r:tri(
				Vector3.new(-2.2, 1.8, z2 + 0.015),
				Vector3.new(1.0, 1.8, z2 + 0.015),
				Vector3.new(-0.6, 2.9, z2 + 0.015),
				0.03,
				Color3.fromRGB(120, 170, 100)
			)
			local houses: { { any } } = { { -1.4, C.Red }, { -0.8, C.Blue }, { -0.2, LEMON } }
			for _, h in houses do
				r:block(h[1] - 0.2, 1.9, z2 + 0.03, h[1] + 0.2, 2.3, z2 + 0.06, C.White, "SmoothPlastic")
				r:tri(
					Vector3.new(h[1] - 0.26, 2.3, z2 + 0.045),
					Vector3.new(h[1] + 0.26, 2.3, z2 + 0.045),
					Vector3.new(h[1], 2.55, z2 + 0.045),
					0.03,
					h[2]
				)
			end
			r:cyl(0.5, 2.5, z2 + 0.03, 0.03, 0.5, "z", C.DarkLeaf, "SmoothPlastic")
			r:block(0.47, 2.0, z2 + 0.015, 0.53, 2.3, z2 + 0.045, C.Bark, "SmoothPlastic")
			r:block(-2.8, 1.1, z1, 2.8, 1.8, z2, Color3.fromRGB(240, 226, 190), "SmoothPlastic")
			local hands = { C.Red, C.Blue, LEMON, C.Pink, Color3.fromRGB(120, 170, 100), Color3.fromRGB(196, 140, 230) }
			for i, col in hands do
				local x = -2.4 + (i - 1) * 0.95
				r:cyl(x, 1.42, z2 + 0.015, 0.03, 0.3, "z", col, "SmoothPlastic")
				for k = -1.5, 1.5 do
					r:block(x + k * 0.07 - 0.025, 1.55, z2, x + k * 0.07 + 0.025, 1.7, z2 + 0.03, col, "SmoothPlastic")
				end
			end
			for i, col in { C.Red, C.Blue, LEMON } do
				local x = -1.6 + i * 0.7
				r:cyl(x, 0.2, 0.9, 0.4, 0.36, "y", C.Metal, "Metal")
				r:cyl(x, 0.42, 0.9, 0.04, 0.32, "y", col, "SmoothPlastic")
			end
			rod(r, Vector3.new(0.9, 0.42, 0.9), Vector3.new(1.2, 0.03, 1.3), 0.05, Color3.fromRGB(176, 130, 86), "Wood")
		end,
	},
	{
		id = "sculpture",
		name = "Stone snail",
		size = Vector3.new(2.6, 3.6, 2.2),
		build = function(r: R)
			-- a big stone snail on a plinth, the kind of thing nobody admits to making: a coiled
			-- shell in rings getting smaller, a long body and two eye stalks
			local stone, pale = Color3.fromRGB(176, 172, 166), Color3.fromRGB(206, 202, 196)
			r:block(-1.2, 0, -1.0, 1.2, 0.3, 1.0, shade(stone, 0.85), "Slate")
			r:block(-1.1, 0.3, -0.9, 1.1, 1.0, 0.9, stone, "Slate")
			r:block(-1.15, 1.0, -0.95, 1.15, 1.1, 0.95, pale, "Slate")
			r:lump(CFrame.new(0.1, 1.3, 0), 2.1, 0.45, 0.8, pale, "Marble")
			r:lump(CFrame.new(0.95, 1.6, 0) * CFrame.Angles(0, 0, 0.6), 0.6, 0.45, 0.55, pale, "Marble")
			for k = 0, 4 do
				local d = 1.5 - k * 0.27
				r:add({
					shape = "Cylinder",
					cf = CFrame.new(-0.25 + k * 0.05, 2.15 + k * 0.1, 0) * CFrame.Angles(0, math.pi / 2, 0),
					size = Vector3.new(0.7 - k * 0.08, d, d),
					color = if k % 2 == 0 then stone else pale,
					mat = "Marble",
				})
			end
			for _, s in { -1, 1 } do
				rod(r, Vector3.new(1.05, 1.8, s * 0.12), Vector3.new(1.2, 2.4, s * 0.25), 0.07, pale, "Marble")
				r:ball(1.2, 2.45, s * 0.25, 0.16, stone, "Marble")
			end
		end,
	},
	{
		id = "boardgame",
		name = "Board game",
		size = Vector3.new(3, 1.6, 3),
		build = function(r: R)
			-- a crate for a table with a chequered board on it, red and white pieces mid game,
			-- a bowl of crisps, and a cushion either side to sit on
			local crate = Color3.fromRGB(196, 156, 104)
			r:block(-0.6, 0, -0.6, 0.6, 0.9, 0.6, crate, "Wood")
			for _, y in { 0.3, 0.6 } do
				r:block(-0.63, y - 0.02, -0.63, 0.63, y + 0.02, 0.63, shade(crate, 0.8), "Wood")
			end
			r:block(-0.5, 0.9, -0.5, 0.5, 0.95, 0.5, C.Bark, "Wood")
			for i = 0, 5 do
				for j = 0, 5 do
					local col = if (i + j) % 2 == 0 then Color3.fromRGB(240, 230, 210) else Color3.fromRGB(70, 60, 60)
					r:block(
						-0.45 + i * 0.15,
						0.95,
						-0.45 + j * 0.15,
						-0.3 + i * 0.15,
						0.98,
						-0.3 + j * 0.15,
						col,
						"SmoothPlastic"
					)
				end
			end
			local pieces: { { any } } = {
				{ 0, 0, C.Red },
				{ 2, 0, C.Red },
				{ 1, 1, C.Red },
				{ 4, 5, C.White },
				{ 3, 4, C.White },
				{ 5, 4, C.White },
				{ 2, 3, C.Red },
			}
			for _, p in pieces do
				r:cyl(-0.375 + p[1] * 0.15, 1.0, -0.375 + p[2] * 0.15, 0.06, 0.12, "y", p[3], "SmoothPlastic")
			end
			r:cyl(0.4, 1.03, 0.4, 0.1, 0.3, "y", C.White, "SmoothPlastic")
			for k = 0, 4 do
				r:lump(
					CFrame.new(0.4 + math.cos(k) * 0.06, 1.1, 0.4 + math.sin(k) * 0.06) * CFrame.Angles(k, k, 0),
					0.08,
					0.02,
					0.06,
					LEMON
				)
			end
			for _, s in { -1, 1 } do
				r:lump(CFrame.new(s * 1.1, 0.15, 0), 0.9, 0.3, 0.9, if s < 0 then C.Pink else C.Blue, "Fabric")
			end
		end,
	},
	{
		id = "umbrella",
		name = "Big umbrella",
		size = Vector3.new(3.4, 3.6, 3.4),
		build = function(r: R)
			-- a big umbrella standing open on its handle in the rain: a canopy in two colours, a
			-- tip, a pole with a curved handle, and puddles round it
			local apex = Vector3.new(0, 3.4, 0)
			for k = 0, 7 do
				local a1, a2 = k * math.pi / 4, (k + 1) * math.pi / 4
				r:tri(
					apex,
					Vector3.new(math.cos(a1) * 1.6, 2.6, math.sin(a1) * 1.6),
					Vector3.new(math.cos(a2) * 1.6, 2.6, math.sin(a2) * 1.6),
					0.04,
					if k % 2 == 0 then Color3.fromRGB(226, 96, 110) else C.White,
					"Fabric"
				)
			end
			r:cyl(0, 3.48, 0, 0.16, 0.06, "y", C.DarkMetal, "Metal")
			rod(r, Vector3.new(0, 0.3, 0), Vector3.new(0, 2.7, 0), 0.06, C.DarkMetal, "Metal")
			path(
				r,
				{
					Vector3.new(0, 0.32, 0),
					Vector3.new(0, 0.12, 0.05),
					Vector3.new(0, 0.1, 0.25),
					Vector3.new(0, 0.25, 0.3),
				},
				0.08,
				C.Bark,
				"Wood"
			)
			for _, p in { { -1.0, 0.6, 1.1 }, { 0.9, -0.8, 0.8 }, { 1.2, 1.0, 0.6 } } do
				r:noCollide(r:cyl(p[1], 0.01, p[2], 0.02, p[3], "y", Color3.fromRGB(130, 170, 200), "Glass"))
			end
		end,
	},
	{
		id = "bouquet",
		name = "Bucket of flowers",
		size = Vector3.new(1.6, 2.6, 1.6),
		build = function(r: R)
			-- a zinc bucket with a handle, full of long stemmed flowers in five colours and
			-- their leaves, tied with a ribbon
			r:cyl(0, 0.4, 0, 0.8, 0.8, "y", C.Metal, "Metal")
			r:cyl(0, 0.8, 0, 0.06, 0.86, "y", shade(C.Metal, 1.1), "Metal")
			r:cyl(0, 0.3, 0, 0.06, 0.84, "y", shade(C.Metal, 0.85), "Metal")
			path(
				r,
				{
					Vector3.new(-0.42, 0.75, 0),
					Vector3.new(-0.3, 1.0, 0.1),
					Vector3.new(0.3, 1.0, 0.1),
					Vector3.new(0.42, 0.75, 0),
				},
				0.03,
				C.DarkMetal,
				"Metal"
			)
			local colours = { C.Red, C.Pink, LEMON, C.White, Color3.fromRGB(196, 140, 230) }
			for i = 0, 10 do
				local a = i * 2.4
				local rad = 0.12 + (i % 3) * 0.1
				local top = Vector3.new(math.cos(a) * (rad + 0.2), 1.7 + (i % 4) * 0.2, math.sin(a) * (rad + 0.2))
				rod(
					r,
					Vector3.new(math.cos(a) * rad * 0.5, 0.8, math.sin(a) * rad * 0.5),
					top,
					0.04,
					C.DarkLeaf,
					"Grass"
				)
				local col = colours[i % #colours + 1]
				for k = 0, 4 do
					local b = k * math.pi * 2 / 5
					r:lump(
						CFrame.new(top + Vector3.new(math.cos(b) * 0.08, 0, math.sin(b) * 0.08)),
						0.12,
						0.06,
						0.12,
						col
					)
				end
				r:ball(top.X, top.Y + 0.03, top.Z, 0.07, if col == LEMON then C.White else LEMON)
				if i % 2 == 0 then
					r:lump(
						CFrame.new(top:Lerp(Vector3.new(0, 0.8, 0), 0.5)) * CFrame.Angles(0, a, 0.6),
						0.22,
						0.04,
						0.1,
						C.Leaf,
						"Grass"
					)
				end
			end
			r:cyl(0, 1.0, 0, 0.08, 0.3, "y", Color3.fromRGB(226, 96, 110), "Fabric")
		end,
	},
	{
		id = "campfire",
		name = "Campfire",
		size = Vector3.new(2.6, 2.2, 2.6),
		build = function(r: R)
			-- a ring of stones round crossed logs and glowing embers with a fire going, and two
			-- toasting sticks with marshmallows stuck in the ground
			for i = 0, 9 do
				local a = i * math.pi / 5
				r:lump(
					CFrame.new(math.cos(a) * 0.85, 0.12, math.sin(a) * 0.85) * CFrame.Angles(0, a, 0),
					0.4,
					0.26,
					0.34,
					shade(C.Stone, 0.85 + (i % 3) * 0.08),
					"Slate"
				)
			end
			for i = 0, 3 do
				local a = i * math.pi / 2 + 0.4
				rod(
					r,
					Vector3.new(math.cos(a) * 0.6, 0.1, math.sin(a) * 0.6),
					Vector3.new(math.cos(a) * 0.05, 0.5, math.sin(a) * 0.05),
					0.16,
					C.Bark,
					"Wood"
				)
			end
			local embers = r:lump(CFrame.new(0, 0.12, 0), 0.6, 0.16, 0.6, Color3.fromRGB(255, 140, 60), "Neon")
			r:glow(embers, 18, 1.6, Color3.fromRGB(255, 170, 90))
			local flame =
				r:noCollide(r:block(-0.1, 0.2, -0.1, 0.1, 0.4, 0.1, Color3.fromRGB(255, 160, 60), "SmoothPlastic"))
			flame.transp = 1
			r:fire(flame)
			for _, s in { -1, 1 } do
				local tip = Vector3.new(s * 0.5, 1.0, 0.35)
				rod(r, Vector3.new(s * 1.2, 0, 0.9), tip, 0.04, Color3.fromRGB(176, 130, 86), "Wood")
				r:cyl(tip.X, tip.Y, tip.Z, 0.14, 0.12, "y", C.White, "SmoothPlastic")
			end
		end,
	},
	{
		id = "fishing",
		name = "Fishing gear",
		size = Vector3.new(2.2, 3.4, 1.6),
		build = function(r: R)
			-- a bucket of water with a fish's tail sticking out, a rod leaning on it with a reel
			-- and its line, and an old boot that came up first
			r:cyl(0, 0.35, 0, 0.7, 0.7, "y", Color3.fromRGB(110, 150, 170), "Metal")
			r:cyl(0, 0.715, 0, 0.03, 0.6, "y", C.Water, "SmoothPlastic")
			local fish = Color3.fromRGB(150, 176, 190)
			r:tri(Vector3.new(0.05, 0.73, 0), Vector3.new(-0.1, 1.02, 0), Vector3.new(0.2, 1.02, 0), 0.04, fish)
			local wood = Color3.fromRGB(176, 130, 86)
			rod(r, Vector3.new(0.4, 0, -0.5), Vector3.new(-0.6, 3.2, 0.3), 0.06, wood, "Wood")
			r:cyl(0.25, 0.55, -0.38, 0.14, 0.22, "x", C.DarkMetal, "Metal")
			rod(r, Vector3.new(-0.6, 3.2, 0.3), Vector3.new(-0.9, 0.05, 0.6), 0.015, C.White, "Fabric")
			local boot = Color3.fromRGB(90, 70, 60)
			r:block(0.6, 0, 0.2, 1.0, 0.6, 0.55, boot, "Fabric")
			r:block(0.6, 0, 0.55, 1.0, 0.25, 0.85, boot, "Fabric")
			r:block(0.58, 0.58, 0.18, 1.02, 0.64, 0.57, shade(boot, 1.2), "Fabric")
		end,
	},
	{
		id = "stall",
		name = "Lemonade stand",
		size = Vector3.new(3, 3.4, 1.8),
		build = function(r: R)
			-- a little stand: a table with a painted sign on its front, a striped awning on two
			-- poles, a jug of lemonade, cups in a row and a bowl of lemons
			local wood = Color3.fromRGB(214, 180, 130)
			r:block(-1.3, 1.0, -0.7, 1.3, 1.1, 0.7, wood, "Wood")
			r:block(-1.25, 0.1, 0.6, 1.25, 1.0, 0.66, shade(wood, 1.08), "Wood")
			for _, x in { -1.2, 1.2 } do
				r:block(x - 0.06, 0, -0.65, x + 0.06, 1.0, -0.53, wood, "Wood")
				r:block(x - 0.05, 1.1, -0.65, x + 0.05, 3.1, -0.55, wood, "Wood")
			end
			r:cyl(0, 0.55, 0.675, 0.03, 0.6, "z", LEMON, "SmoothPlastic")
			r:block(-0.9, 0.2, 0.66, 0.9, 0.3, 0.69, C.Red, "SmoothPlastic")
			for i = 0, 5 do
				local x = -1.3 + i * 0.433
				r:boxAt(
					CFrame.new(x + 0.216, 3.0, -0.2) * CFrame.Angles(math.rad(-18), 0, 0),
					0.433,
					0.06,
					1.0,
					if i % 2 == 0 then C.White else Color3.fromRGB(226, 110, 110),
					"Fabric"
				)
			end
			r:cyl(-0.6, 1.4, 0, 0.6, 0.36, "y", C.Glass, "Glass").transp = 0.45
			r:cyl(-0.6, 1.33, 0, 0.42, 0.3, "y", LEMON, "SmoothPlastic")
			for k = 0, 3 do
				r:cyl(-0.1 + k * 0.24, 1.22, 0.3, 0.24, 0.16, "y", C.White, "SmoothPlastic")
			end
			r:cyl(0.8, 1.18, -0.1, 0.16, 0.5, "y", C.Blue, "SmoothPlastic")
			for k = 0, 3 do
				r:lump(
					CFrame.new(0.72 + (k % 2) * 0.16, 1.3 + math.floor(k / 2) * 0.08, -0.16 + (k % 2) * 0.1),
					0.18,
					0.13,
					0.13,
					LEMON
				)
			end
		end,
	},
	{
		id = "balloons",
		name = "Balloons",
		size = Vector3.new(2, 6, 2),
		build = function(r: R)
			-- a bunch of balloons in five colours on strings, each with its knot, tied to a
			-- little weight
			r:cyl(0, 0.15, 0, 0.3, 0.3, "y", C.DarkMetal, "Metal")
			local colours = { C.Red, LEMON, C.Blue, C.Pink, Color3.fromRGB(120, 190, 120) }
			local tops = {
				Vector3.new(-0.5, 5.0, 0.1),
				Vector3.new(0.4, 5.3, -0.2),
				Vector3.new(0.0, 5.6, 0.4),
				Vector3.new(0.6, 4.6, 0.4),
				Vector3.new(-0.3, 4.5, -0.5),
			}
			for i, t in tops do
				rod(r, Vector3.new(0, 0.3, 0), t - Vector3.new(0, 0.55, 0), 0.015, C.White, "Fabric")
				r:lump(CFrame.new(t), 0.8, 0.95, 0.8, colours[i], "SmoothPlastic")
				r:cone(t.X, t.Y - 0.52, t.Z, 0.1, 0.1, shade(colours[i], 0.8), "SmoothPlastic")
			end
		end,
	},
	{
		id = "bricks",
		name = "Tower of bricks",
		size = Vector3.new(2.4, 6, 2.4),
		build = function(r: R)
			-- the builder's tower: bricks two to a course, each course turned a little more than
			-- the last so the whole thing leans, a hard hat and a trowel at its foot
			local brick = Color3.fromRGB(184, 96, 76)
			for k = 0, 15 do
				local cf = CFrame.new(0.004 * k * k, 0.17 + k * 0.34, 0) * CFrame.Angles(0, k * 0.22, 0)
				for _, s in { -1, 1 } do
					r:boxAt(
						cf * CFrame.new(s * 0.26, 0, 0),
						0.5,
						0.3,
						0.92,
						if (k + s) % 3 == 0 then shade(brick, 0.9) else brick,
						"Brick"
					)
				end
			end
			local hat = LEMON
			r:cyl(1.0, 0.06, 0.8, 0.12, 0.7, "y", hat, "SmoothPlastic")
			r:lump(CFrame.new(1.0, 0.22, 0.8), 0.56, 0.4, 0.56, hat, "SmoothPlastic")
			r:boxAt(CFrame.new(-0.9, 0.03, 0.8) * CFrame.Angles(0, 0.6, 0), 0.4, 0.04, 0.3, C.Metal, "Metal")
			rod(r, Vector3.new(-0.9, 0.06, 0.8), Vector3.new(-1.1, 0.25, 1.05), 0.06, C.Bark, "Wood")
		end,
	},
	{
		id = "bakes",
		name = "Big order",
		size = Vector3.new(2.6, 2.8, 1.8),
		build = function(r: R)
			-- a trolley on four wheels piled with cake boxes tied with string, and a tray of buns
			-- on top
			r:block(-1.1, 0.35, -0.7, 1.1, 0.45, 0.7, C.Metal, "Metal")
			for _, x in { -0.9, 0.9 } do
				for _, z in { -0.55, 0.55 } do
					r:cyl(x, 0.17, z, 0.08, 0.3, "z", INK, "Rubber")
				end
			end
			path(
				r,
				{
					Vector3.new(1.1, 0.45, -0.6),
					Vector3.new(1.25, 1.4, -0.6),
					Vector3.new(1.25, 1.4, 0.6),
					Vector3.new(1.1, 0.45, 0.6),
				},
				0.06,
				C.DarkMetal,
				"Metal"
			)
			local boxes: { { any } } = {
				{ -0.5, 0.45, 0, 0.9, 0.5, 1.0, Color3.fromRGB(246, 210, 220) },
				{ 0.45, 0.45, 0, 0.9, 0.5, 1.0, C.White },
				{ -0.45, 0.95, 0.05, 0.8, 0.45, 0.9, C.White },
				{ 0.4, 0.95, -0.05, 0.8, 0.45, 0.9, Color3.fromRGB(246, 210, 220) },
				{ 0, 1.4, 0, 0.8, 0.45, 0.9, Color3.fromRGB(246, 210, 220) },
			}
			for _, b in boxes do
				r:block(
					b[1] - b[4] / 2,
					b[2],
					b[3] - b[6] / 2,
					b[1] + b[4] / 2,
					b[2] + b[5],
					b[3] + b[6] / 2,
					b[7],
					"Fabric"
				)
				r:block(
					b[1] - 0.03,
					b[2] + 0.04,
					b[3] - b[6] / 2 - 0.03,
					b[1] + 0.03,
					b[2] + b[5] + 0.03,
					b[3] + b[6] / 2 + 0.03,
					C.Red,
					"Fabric"
				)
			end
			r:block(-0.5, 1.89, -0.4, 0.5, 1.94, 0.4, C.Metal, "Metal")
			for i = 0, 5 do
				r:lump(
					CFrame.new(-0.3 + (i % 3) * 0.3, 2.02, -0.15 + math.floor(i / 3) * 0.3),
					0.26,
					0.16,
					0.26,
					Color3.fromRGB(214, 160, 90)
				)
			end
		end,
	},
	{
		id = "microphone",
		name = "Microphone",
		size = Vector3.new(2, 3.4, 1.6),
		build = function(r: R)
			-- a microphone on a stand with its boom, and a little amplifier with a speaker, two
			-- knobs and a cable to the mic
			r:cyl(0, 0.04, 0, 0.08, 0.6, "y", INK, "Metal")
			rod(r, Vector3.new(0, 0.08, 0), Vector3.new(0, 2.6, 0), 0.06, C.DarkMetal, "Metal")
			rod(r, Vector3.new(0, 2.55, 0), Vector3.new(0, 2.85, 0.35), 0.05, C.DarkMetal, "Metal")
			r:ball(0, 2.92, 0.42, 0.2, C.Metal, "Metal")
			r:block(0.6, 0, -0.4, 1.4, 0.9, 0.3, INK, "Fabric")
			r:cyl(1.0, 0.45, 0.315, 0.03, 0.5, "z", Color3.fromRGB(90, 90, 96), "Fabric")
			r:cyl(1.0, 0.45, 0.345, 0.03, 0.16, "z", INK, "Metal")
			for _, x in { 0.8, 1.2 } do
				r:cyl(x, 0.8, 0.32, 0.04, 0.08, "z", C.Metal, "Metal")
			end
			path(
				r,
				{
					Vector3.new(0.7, 0.2, 0.32),
					Vector3.new(0.3, 0.02, 0.6),
					Vector3.new(0.05, 0.02, 0.1),
					Vector3.new(0.03, 0.5, 0.03),
				},
				0.03,
				INK,
				"Rubber"
			)
		end,
	},
	{
		id = "parcels",
		name = "Heap of parcels",
		size = Vector3.new(2.6, 1.8, 2.2),
		build = function(r: R)
			-- parcels of every size tied with string, letters spilled round them, and the
			-- postbag with its strap and flap
			local parcels = {
				{ -0.6, 0, -0.3, 0.8, 0.6, 0.7 },
				{ 0.3, 0, -0.4, 0.7, 0.5, 0.6 },
				{ -0.4, 0.6, -0.3, 0.6, 0.4, 0.5 },
				{ 0.4, 0.5, -0.4, 0.5, 0.35, 0.5 },
				{ -0.2, 1.0, -0.25, 0.4, 0.3, 0.4 },
			}
			for i, p in parcels do
				local col = if i % 2 == 0 then CARD else shade(CARD, 1.12)
				r:block(
					p[1] - p[4] / 2,
					p[2],
					p[3] - p[6] / 2,
					p[1] + p[4] / 2,
					p[2] + p[5],
					p[3] + p[6] / 2,
					col,
					"Fabric"
				)
				r:block(
					p[1] - 0.025,
					p[2] + 0.04,
					p[3] - p[6] / 2 - 0.03,
					p[1] + 0.025,
					p[2] + p[5] + 0.03,
					p[3] + p[6] / 2 + 0.03,
					C.Paper,
					"Fabric"
				)
			end
			for i = 0, 5 do
				r:noCollide(
					r:boxAt(
						CFrame.new(-0.9 + i * 0.36, 0.02, 0.55 + (i % 2) * 0.25) * CFrame.Angles(0, i * 0.5, 0),
						0.4,
						0.03,
						0.26,
						C.White,
						"SmoothPlastic"
					)
				)
			end
			local bag = Color3.fromRGB(140, 90, 60)
			r:lump(CFrame.new(1.0, 0.45, 0.4), 0.8, 0.9, 0.5, bag, "Fabric")
			r:boxAt(
				CFrame.new(1.0, 0.7, 0.62) * CFrame.Angles(math.rad(-10), 0, 0),
				0.7,
				0.4,
				0.05,
				shade(bag, 1.15),
				"Fabric"
			)
			path(
				r,
				{
					Vector3.new(0.65, 0.7, 0.4),
					Vector3.new(0.75, 1.5, 0.4),
					Vector3.new(1.25, 1.5, 0.4),
					Vector3.new(1.35, 0.7, 0.4),
				},
				0.06,
				shade(bag, 0.7),
				"Fabric"
			)
		end,
	},
	{
		id = "pillowfort",
		name = "Pillow fort",
		size = Vector3.new(3.6, 2, 3.2),
		build = function(r: R)
			-- walls of cushions, a blanket over the top on two broom handles, a lantern glowing
			-- inside and a sign on the door flap
			local colours = { C.Pink, C.Blue, LEMON, Color3.fromRGB(160, 200, 150), C.White }
			local n = 0
			for _, s in { -1, 1 } do
				for k = 0, 2 do
					n += 1
					r:lump(
						CFrame.new(s * 1.3, 0.35, -1.0 + k * 1.0),
						0.6,
						0.7,
						0.9,
						colours[n % #colours + 1],
						"Fabric"
					)
					r:lump(
						CFrame.new(s * 1.3, 0.95, -0.9 + k * 0.9),
						0.55,
						0.6,
						0.85,
						colours[(n + 2) % #colours + 1],
						"Fabric"
					)
				end
			end
			for k = 0, 2 do
				r:lump(CFrame.new(-0.8 + k * 0.8, 0.4, -1.3), 0.85, 0.8, 0.55, colours[k + 1], "Fabric")
			end
			for _, x in { -1.3, 1.3 } do
				r:cyl(x, 0.85, 1.3, 1.7, 0.08, "y", Color3.fromRGB(176, 130, 86), "Wood")
			end
			local blanket = Color3.fromRGB(150, 120, 196)
			local hem = shade(blanket, 0.8)
			local top = 1.7
			r:block(-1.7, top, -1.55, 1.7, top + 0.1, 1.45, blanket, "Fabric")
			for _, s in { -1, 1 } do
				r:block(s * 1.7 - 0.05, 0.5, -1.55, s * 1.7 + 0.05, top, 1.45, blanket, "Fabric")
				r:block(s * 1.7 - 0.08, 0.47, -1.58, s * 1.7 + 0.08, 0.57, 1.48, hem, "Fabric")
			end
			r:block(-1.65, 0.3, -1.6, 1.65, top, -1.5, blanket, "Fabric")
			r:block(-1.6, 0.95, 1.4, -0.25, top, 1.5, blanket, "Fabric")
			r:block(0.25, 0.95, 1.4, 1.6, top, 1.5, blanket, "Fabric")
			r:boxAt(CFrame.new(-0.42, 1.3, 1.52) * CFrame.Angles(0, 0, -0.25), 0.3, 0.8, 0.04, hem, "Fabric")
			r:block(0.4, 1.3, 1.5, 1.0, 1.6, 1.53, C.Paper, "SmoothPlastic")
			r:block(0.5, 1.41, 1.53, 0.9, 1.45, 1.56, INK, "SmoothPlastic")
			r:glow(r:ball(0, 0.3, 0, 0.3, Color3.fromRGB(255, 214, 150), "Neon"), 10, 1)
		end,
	},
	{
		id = "camera",
		name = "Camera",
		size = Vector3.new(1.6, 2.6, 1.6),
		build = function(r: R)
			-- a camera on a tripod: its body, the lens and its hood, a flash on top and a strap
			-- hanging down
			local head = Vector3.new(0, 1.7, 0)
			for i = 0, 2 do
				local a = i * math.pi * 2 / 3 + 0.3
				rod(r, Vector3.new(math.cos(a) * 0.6, 0, math.sin(a) * 0.6), head, 0.05, C.DarkMetal, "Metal")
			end
			r:block(-0.35, 1.72, -0.2, 0.35, 2.15, 0.2, INK, "Metal")
			r:block(-0.33, 2.15, -0.15, -0.1, 2.25, 0.1, C.Metal, "Metal")
			r:cyl(0, 1.93, 0.3, 0.2, 0.32, "z", C.DarkMetal, "Metal")
			r:cyl(0, 1.93, 0.43, 0.06, 0.38, "z", INK, "Metal")
			r:cyl(0, 1.93, 0.475, 0.03, 0.22, "z", Color3.fromRGB(110, 150, 190), "Glass")
			r:block(0.15, 2.15, -0.1, 0.3, 2.3, 0.05, C.White, "SmoothPlastic")
			path(
				r,
				{
					Vector3.new(-0.36, 2.05, 0),
					Vector3.new(-0.42, 1.5, 0.05),
					Vector3.new(0.36, 1.5, 0.05),
					Vector3.new(0.36, 2.05, 0),
				},
				0.03,
				C.Red,
				"Fabric"
			)
		end,
	},
	{
		id = "dog",
		name = "Dog",
		size = Vector3.new(1.4, 1.8, 1.4),
		build = function(r: R)
			-- a scruffy dog sitting: a brown coat with a pale chest, floppy ears, a snout with a
			-- black nose, a red collar with a tag, front legs and a tail
			local coat, pale = Color3.fromRGB(170, 120, 80), Color3.fromRGB(240, 224, 196)
			r:lump(CFrame.new(0, 0.55, -0.15) * CFrame.Angles(math.rad(25), 0, 0), 0.7, 1.0, 0.8, coat, "Fabric")
			r:lump(CFrame.new(0, 0.7, 0.12), 0.46, 0.6, 0.3, pale, "Fabric")
			for _, s in { -1, 1 } do
				r:cyl(s * 0.17, 0.3, 0.22, 0.6, 0.15, "y", coat, "Fabric")
				r:ball(s * 0.17, 0.04, 0.27, 0.18, pale, "Fabric")
				r:lump(CFrame.new(s * 0.3, 0.15, -0.3), 0.3, 0.3, 0.55, coat, "Fabric")
				r:lump(
					CFrame.new(s * 0.27, 1.25, 0.18) * CFrame.Angles(0, 0, s * 0.3),
					0.14,
					0.4,
					0.24,
					shade(coat, 0.75),
					"Fabric"
				)
				r:ball(s * 0.11, 1.38, 0.46, 0.08, INK, "SmoothPlastic")
			end
			r:ball(0, 1.32, 0.25, 0.56, coat, "Fabric")
			r:lump(CFrame.new(0, 1.2, 0.52), 0.3, 0.22, 0.3, pale, "Fabric")
			r:ball(0, 1.26, 0.68, 0.1, INK, "SmoothPlastic")
			r:cyl(0, 1.0, 0.1, 0.08, 0.5, "y", C.Red, "Fabric")
			r:cyl(0, 0.9, 0.36, 0.02, 0.1, "z", C.Gold, "Metal")
			rod(r, Vector3.new(0, 0.2, -0.5), Vector3.new(0.15, 0.5, -0.68), 0.1, coat, "Fabric")
		end,
	},
	{
		id = "cat",
		name = "Cat",
		size = Vector3.new(1.0, 1.3, 1.0),
		build = function(r: R)
			-- a ginger cat sitting up: darker stripes, pointed ears, green eyes, a pink nose,
			-- white paws, and its tail curled round them
			local fur, stripe = Color3.fromRGB(226, 150, 80), Color3.fromRGB(190, 110, 56)
			r:lump(CFrame.new(0, 0.38, -0.05), 0.55, 0.72, 0.6, fur, "Fabric")
			for k = 0, 2 do
				r:lump(CFrame.new(0, 0.3 + k * 0.17, -0.12), 0.57, 0.05, 0.5, stripe, "Fabric")
			end
			r:ball(0, 0.88, 0.06, 0.44, fur, "Fabric")
			for _, s in { -1, 1 } do
				r:wedge(
					CFrame.new(s * 0.13, 1.12, 0.04) * CFrame.Angles(0, 0, s * 0.2),
					0.12,
					0.16,
					0.08,
					stripe,
					"Fabric"
				)
				r:ball(s * 0.09, 0.92, 0.25, 0.07, Color3.fromRGB(110, 170, 90), "SmoothPlastic")
				r:ball(s * 0.11, 0.06, 0.2, 0.14, C.White, "Fabric")
			end
			r:ball(0, 0.83, 0.28, 0.05, C.Pink, "SmoothPlastic")
			path(
				r,
				{
					Vector3.new(0, 0.1, -0.35),
					Vector3.new(0.3, 0.06, -0.2),
					Vector3.new(0.35, 0.06, 0.15),
					Vector3.new(0.15, 0.08, 0.32),
				},
				0.09,
				stripe,
				"Fabric"
			)
		end,
	},
	{
		id = "rope",
		name = "Tug of war rope",
		size = Vector3.new(8, 0.6, 1.4),
		build = function(r: R)
			-- a long rope on the grass with a red rag tied at its middle, coils at both ends, and
			-- a marker flag stuck in the ground under the middle
			local rope = Color3.fromRGB(206, 180, 130)
			path(
				r,
				{
					Vector3.new(-3.6, 0.06, 0.1),
					Vector3.new(-1.5, 0.06, -0.1),
					Vector3.new(1.5, 0.06, 0.1),
					Vector3.new(3.6, 0.06, -0.05),
				},
				0.12,
				rope,
				"Fabric"
			)
			for _, s in { -1, 1 } do
				for k = 0, 1 do
					r:cyl(
						s * (3.6 + k * 0.05),
						0.06 + k * 0.1,
						0.35,
						0.1,
						0.6 - k * 0.15,
						"y",
						shade(rope, 0.9 + k * 0.1),
						"Fabric"
					)
				end
			end
			r:lump(CFrame.new(0, 0.1, 0), 0.2, 0.2, 0.3, C.Red, "Fabric")
			rod(r, Vector3.new(0, 0, -0.5), Vector3.new(0, 0.55, -0.5), 0.03, C.Bark, "Wood")
			r:tri(Vector3.new(0, 0.55, -0.5), Vector3.new(0, 0.35, -0.5), Vector3.new(0.25, 0.45, -0.5), 0.02, LEMON)
		end,
	},
}

local EventProps = {}

EventProps.list = list

local byId: { [string]: Prop } = {}
for _, p in list do
	byId[p.id] = p
end

-- A prop by id. "item:<catalog id>" is a Build mode piece shown as a prop (the thing a
-- villager has just made, before it's given to you as a keepsake).
function EventProps.get(id: string?): Prop?
	if not id then
		return nil
	end
	local found = byId[id]
	if found then
		return found
	end
	local item = string.match(id, "^item:(.+)$")
	local def = item and Catalog.get(item)
	if not def or def.place == "opening" then
		return nil
	end
	-- a wall piece stands on its bottom edge, a hanging one is lifted to hang from its top
	local lift = if def.place == "ceiling" then def.size.Y else 0
	return {
		id = id,
		name = def.name,
		size = def.size,
		build = function(r: R)
			for _, p in Catalog.prims(def) do
				local q = table.clone(p)
				q.cf = CFrame.new(0, lift, 0) * p.cf
				r:add(q)
			end
		end,
	}
end

-- A prop's primitives in its own space.
function EventProps.prims(id: string): { Recipe.Prim }
	local p = EventProps.get(id)
	if not p then
		return {}
	end
	local r = Recipe.new(C.White, C.Cream)
	p.build(r)
	return r.prims
end

return EventProps
