--!strict
-- More pieces that move, for indoors and the porch (the user: "Add much more decor and make
-- animated pieces ... and models that have moving pieces"): fans that turn, a rocking chair, a
-- mobile of paper birds, chimes of shells, a lantern that sways, a tabletop water wheel, a music
-- box with a dancer, an orrery, a plasma globe, a bird on a swing in its cage, a robot dog, and
-- the fog machine, bought with gems (the user: "also, add a fog machine that players can place
-- with gems": Sim/GemPieces), whose fog follows its switch. As in Recipes/Animated, each names
-- its moving parts and pivots (Build/Lively), nothing that moves is solid, and every surface is a
-- textured material.

local Recipe = require(script.Parent.Parent.Recipe)
local Lively = require(script.Parent.Parent.Lively)
local K = require(script.Parent.Parent.RecipeKit)
local Colors = require(script.Parent.Parent.Parent.Util.Colors)

local C = Recipe.Colors

type R = Recipe.Recipe
type Prim = Recipe.Prim

local BRASS = Color3.fromRGB(206, 168, 92)
local TWINE = Color3.fromRGB(196, 172, 128)
local CREAM = Color3.fromRGB(246, 240, 226)
local INK = Color3.fromRGB(52, 48, 56)

local function shade(c: Color3, k: number): Color3
	return Colors.shade(c, k)
end

local function mix(a: Color3, b: Color3, t: number): Color3
	return Colors.mix(a, b, t)
end

-- Moves every prim drawn by `draw` by the frame `cf` (draw in a little space of its own).
local function placed(r: R, cf: CFrame, draw: () -> ())
	local from = #r.prims + 1
	draw()
	for i = from, #r.prims do
		r.prims[i].cf = cf * r.prims[i].cf
	end
end

type Item = {
	id: string,
	name: string,
	cat: string,
	style: string?,
	price: number,
	gems: number?,
	place: string,
	size: Vector3,
	c1: string,
	c2: string?,
	tags: { string }?,
	surface: number?,
	lively: boolean?,
	build: (r: R) -> (),
}

local items: { Item } = {
	{
		id = "anim_palm_fan",
		name = "Palm leaf fan",
		cat = "lights",
		style = "seaside",
		price = 150,
		place = "ceiling",
		size = Vector3.new(6.4, 2, 6.4),
		c1 = "B08A5E",
		c2 = "7FA868",
		tags = { "light" },
		lively = true,
		build = function(r: R)
			local cane = r.c1
			-- a woven canopy, a cane rod and a lamp of woven cane under it all
			K.disc(r, 0, -0.1, 0, 0.2, 0.8, cane, "Fabric")
			r:cyl(0, -0.55, 0, 0.7, 0.12, "y", shade(cane, 0.85), "Wood")
			local shade1 = r:ball(0, -1.55, 0, 0.7, mix(cane, CREAM, 0.3), "Fabric")
			shade1.size = Vector3.new(0.7, 0.5, 0.7)
			shade1.smooth = true
			for k = 0, 5 do
				local a = k * math.pi / 3
				K.rod(
					r,
					Vector3.new(math.cos(a) * 0.36, -1.45, math.sin(a) * 0.36),
					Vector3.new(math.cos(a) * 0.2, -1.78, math.sin(a) * 0.2),
					0.03,
					shade(cane, 0.8),
					"Wood"
				)
			end
			local bulb = K.sphere(r, 0, -1.62, 0, 0.3, C.Warm, "Glass")
			r:glow(bulb, 14, 1.0)
			-- the motor in a wrapped cane drum, and five blades shaped like palm leaves, going round
			Lively.pivot(r, CFrame.new(0, -1.05, 0), "spin", { speed = 3.6 })
			Lively.moving(r, 1, function()
				local drum = r:cyl(0, -1.05, 0, 0.36, 0.9, "y", cane, "Fabric")
				drum.smooth = true
				K.hoop(r, 0, -0.9, 0, 0.45, 14, 0.05, shade(cane, 0.75), "Wood")
				K.hoop(r, 0, -1.2, 0, 0.45, 14, 0.05, shade(cane, 0.75), "Wood")
				for k = 0, 4 do
					local f = CFrame.Angles(0, k * math.pi * 2 / 5, 0) * CFrame.new(0, -1.12, 0)
					r:boxAt(f * CFrame.new(0.65, 0, 0), 0.45, 0.05, 0.12, BRASS, "Metal")
					-- a leaf: a rib along it, and narrow lobes either side, wider in the middle
					r:boxAt(
						f * CFrame.new(1.85, -0.02, 0) * CFrame.Angles(0.12, 0, 0),
						2.1,
						0.04,
						0.06,
						shade(r.c2, 0.8),
						"Wood"
					)
					for j = 0, 6 do
						local t = j / 6
						local w = 0.12 + math.sin(t * math.pi) * 0.3
						for _, sz in { -1, 1 } do
							r:boxAt(
								f
									* CFrame.new(1.0 + t * 1.8, -0.03, sz * (w / 2 + 0.02))
									* CFrame.Angles(0.12 * sz, 0, sz * 0.35),
								0.26,
								0.03,
								w,
								if j % 2 == 0 then r.c2 else shade(r.c2, 0.92),
								"Wood"
							)
						end
					end
				end
			end)
		end,
	},
	{
		id = "anim_desk_fan",
		name = "Desk fan",
		cat = "decor",
		style = "modern",
		price = 60,
		place = "surface",
		size = Vector3.new(1.3, 1.7, 1.0),
		c1 = "8FC4BA",
		c2 = "F2EEE6",
		lively = true,
		build = function(r: R)
			-- a round foot with two buttons, a neck and a yoke holding the motor
			K.disc(r, 0, 0.05, 0, 0.1, 0.8, r.c1, "Metal")
			K.disc(r, 0, 0.12, 0, 0.04, 0.6, shade(r.c1, 0.9), "Metal")
			for i, x in { -0.08, 0.08 } do
				r:block(x - 0.05, 0.1, 0.24, x + 0.05, 0.16, 0.32, if i == 1 then r.c2 else shade(r.c2, 0.8), "Rubber")
			end
			r:cyl(0, 0.45, -0.05, 0.6, 0.09, "y", C.Metal, "Metal").smooth = true
			r:block(-0.22, 0.72, -0.08, 0.22, 0.76, 0.0, C.Metal, "Metal")
			for _, sx in { -1, 1 } do
				r:block(sx * 0.22 - 0.02, 0.74, -0.08, sx * 0.22 + 0.02, 0.95, 0.0, C.Metal, "Metal")
			end
			local motor = r:cyl(0, 0.95, -0.12, 0.34, 0.36, "z", r.c1, "Metal")
			motor.smooth = true
			K.sphere(r, 0, 0.95, -0.3, 0.3, r.c1, "Metal")
			-- the guard: a ring at the back and at the front, joined, and a badge in its middle
			for _, z in { 0.08, 0.32 } do
				K.ring(r, CFrame.new(0, 0.95, z), 0.58 - math.abs(z - 0.2) * 0.4, 20, 0.025, C.Metal, "Metal")
			end
			for k = 0, 11 do
				local a = k * math.pi / 6
				K.rod(
					r,
					Vector3.new(math.cos(a) * 0.53, 0.95 + math.sin(a) * 0.53, 0.08),
					Vector3.new(math.cos(a) * 0.53, 0.95 + math.sin(a) * 0.53, 0.32),
					0.02,
					C.Metal,
					"Metal"
				)
			end
			K.face(r, 0, 0.95, 0.33, 0.03, 0.16, r.c2, "Metal")
			-- three blades going round fast, each turned to the air
			Lively.pivot(r, CFrame.new(0, 0.95, 0.18), "spin", { speed = 14, axis = "Z" })
			Lively.moving(r, 1, function()
				K.face(r, 0, 0.95, 0.18, 0.1, 0.14, r.c2, "Metal")
				for k = 0, 2 do
					local blade = r:ball(0, 0, 0, 1, mix(r.c2, r.c1, 0.3), "Metal")
					blade.cf = CFrame.new(0, 0.95, 0.18)
						* CFrame.Angles(0, 0, k * math.pi * 2 / 3)
						* CFrame.new(0, 0.27, 0)
						* CFrame.Angles(0, 0.4, 0)
					blade.size = Vector3.new(0.3, 0.42, 0.04)
				end
			end)
		end,
	},
	{
		id = "anim_porch_rocker",
		name = "Porch rocker",
		cat = "seating",
		style = "cozy",
		price = 160,
		place = "floor",
		size = Vector3.new(2.4, 3.8, 3.0),
		c1 = "9C7452",
		c2 = "C46E5E",
		tags = { "seat" },
		lively = true,
		build = function(r: R)
			local wood = r.c1
			-- a hidden body to bump into (what rocks is never solid) and the place to sit
			local body = r:block(-1.0, 0, -1.0, 1.0, 1.4, 1.0, C.White, "Wood")
			body.transp = 1
			r:seat(0, 1.48, 0.1, 0)
			-- the whole chair rocks on its runners, round the middle of their curve
			local R0 = 3.2
			Lively.pivot(r, CFrame.new(0, R0, 0.1), "swing", { speed = 1.3, amount = 0.07, axis = "X" })
			Lively.moving(r, 1, function()
				-- two curved runners
				for _, sx in { -1, 1 } do
					local pts = {}
					for i = 0, 8 do
						local a = (i / 8 - 0.5) * 0.9
						table.insert(pts, Vector3.new(sx * 0.95, R0 - math.cos(a) * R0 + 0.08, 0.1 + math.sin(a) * R0))
					end
					for i = 1, 8 do
						r:beam(pts[i], pts[i + 1], 0.12, 0.14, shade(wood, 0.9), "Wood")
					end
				end
				-- legs up from the runners to the seat, and stretchers between them
				for _, sx in { -1, 1 } do
					for _, z in { -0.75, 0.85 } do
						r:block(sx * 0.95 - 0.07, 0.15, z - 0.07, sx * 0.95 + 0.07, 1.4, z + 0.07, wood, "Wood")
					end
					r:block(sx * 0.95 - 0.04, 0.6, -0.75, sx * 0.95 + 0.04, 0.68, 0.85, shade(wood, 0.9), "Wood")
				end
				r:block(-0.95, 0.6, 0.81, 0.95, 0.68, 0.89, shade(wood, 0.9), "Wood")
				-- the seat of slats, and a cushion on it in the second paint, tied on
				for i = 0, 5 do
					local z = -0.8 + i * 0.32
					r:block(-1.0, 1.32, z, 1.0, 1.4, z + 0.28, wood, "WoodPlanks")
				end
				local cushion = r:lump(CFrame.new(0, 1.5, 0.1), 1.8, 0.22, 1.6, r.c2, "Fabric")
				cushion.collide = false
				for _, sx in { -1, 1 } do
					r:block(sx * 0.6 - 0.03, 1.42, -0.62, sx * 0.6 + 0.03, 1.58, -0.56, CREAM, "Fabric")
				end
				-- a tall back of spindles between two posts and a curved top rail
				for _, sx in { -1, 1 } do
					local post = r:block(sx * 0.95 - 0.08, 1.4, -0.92, sx * 0.95 + 0.08, 3.6, -0.76, wood, "Wood")
					post.cf = post.cf * CFrame.Angles(-0.12, 0, 0)
					r:ball(sx * 0.95, 3.72, -1.08, 0.18, wood, "Wood")
				end
				for i = 0, 6 do
					local x = -0.66 + i * 0.22
					local sp = r:cyl(x, 2.45, -0.96, 1.9, 0.06, "y", wood, "Wood")
					sp.cf = CFrame.new(x, 2.45, -0.96) * CFrame.Angles(-0.12, 0, 0) * CFrame.Angles(0, 0, math.pi / 2)
				end
				local rail = r:block(-0.95, 3.32, -1.12, 0.95, 3.52, -0.98, wood, "Wood")
				rail.cf = rail.cf * CFrame.Angles(-0.12, 0, 0)
				-- arms on turned posts
				for _, sx in { -1, 1 } do
					r:block(sx * 1.0 - 0.1, 2.18, -0.8, sx * 1.0 + 0.1, 2.26, 0.95, wood, "Wood")
					r:cyl(sx * 1.0, 1.8, 0.82, 0.8, 0.1, "y", wood, "Wood")
				end
			end)
		end,
	},
	{
		id = "anim_bird_mobile",
		name = "Paper bird mobile",
		cat = "decor",
		style = "cozy",
		price = 55,
		place = "ceiling",
		size = Vector3.new(2.4, 2.8, 2.4),
		c1 = "E9B9A8",
		c2 = "9CC4D8",
		lively = true,
		build = function(r: R)
			-- a hook on the ceiling, a thread down to a wooden hoop with its cross threads
			K.disc(r, 0, -0.04, 0, 0.08, 0.24, BRASS, "Metal")
			r:noCollide(r:cyl(0, -0.55, 0, 0.9, 0.02, "y", TWINE, "Fabric"))
			Lively.pivot(r, CFrame.new(0, -1.0, 0), "spin", { speed = 0.25 })
			Lively.moving(r, 1, function()
				K.hoop(r, 0, -1.0, 0, 0.8, 18, 0.06, C.Bark, "Wood")
				for k = 0, 2 do
					local a = k * math.pi * 2 / 3
					K.rod(
						r,
						Vector3.new(0, -1.0 + 0.0, 0),
						Vector3.new(math.cos(a) * 0.8, -1.0, math.sin(a) * 0.8),
						0.015,
						TWINE,
						"Fabric"
					)
					K.rod(
						r,
						Vector3.new(0, -1.0, 0),
						Vector3.new(0, -1.0, 0) + Vector3.new(math.cos(a) * 0.01, 0.45, 0),
						0.015,
						TWINE,
						"Fabric"
					)
				end
				K.sphere(r, 0, -1.0, 0, 0.08, BRASS, "Wood")
				-- five folded paper birds on threads of different lengths, flying round
				for k = 0, 4 do
					local a = k * math.pi * 2 / 5 + 0.3
					local x, z = math.cos(a) * 0.8, math.sin(a) * 0.8
					local drop = 0.5 + (k % 3) * 0.35
					r:cyl(x, -1.0 - drop / 2, z, drop, 0.015, "y", TWINE, "Fabric")
					local y = -1.0 - drop - 0.08
					local col = if k % 2 == 0 then r.c1 else r.c2
					placed(r, CFrame.new(x, y, z) * CFrame.Angles(0, -a, 0), function()
						-- a body folded to a point, two wings lifted, a tail
						r:tri(
							Vector3.new(0, 0, 0.3),
							Vector3.new(0, 0.08, -0.25),
							Vector3.new(0, -0.06, -0.2),
							0.03,
							col,
							"Fabric"
						)
						for _, sx in { -1, 1 } do
							r:tri(
								Vector3.new(0, 0.02, 0.12),
								Vector3.new(sx * 0.36, 0.16, -0.02),
								Vector3.new(0, 0.02, -0.12),
								0.02,
								shade(col, 0.92),
								"Fabric"
							)
						end
						r:tri(
							Vector3.new(0, 0.04, -0.2),
							Vector3.new(0, 0.18, -0.36),
							Vector3.new(0, 0.02, -0.32),
							0.02,
							shade(col, 0.85),
							"Fabric"
						)
					end)
				end
			end)
		end,
	},
	{
		id = "anim_shell_chimes",
		name = "Shell chimes",
		cat = "decor",
		style = "seaside",
		price = 45,
		place = "ceiling",
		size = Vector3.new(1.8, 2.8, 0.6),
		c1 = "C8B496",
		c2 = "F0C8C0",
		lively = true,
		build = function(r: R)
			-- a length of driftwood hung on two threads from a hook
			K.disc(r, 0, -0.04, 0, 0.08, 0.22, BRASS, "Metal")
			for _, sx in { -1, 1 } do
				K.rod(r, Vector3.new(0, -0.08, 0), Vector3.new(sx * 0.6, -0.5, 0), 0.02, TWINE, "Fabric")
			end
			local bar = r:lump(CFrame.new(0, -0.55, 0) * CFrame.Angles(0, 0, 0.05), 1.7, 0.14, 0.16, r.c1, "Wood")
			bar.collide = false
			r:lump(
				CFrame.new(0.55, -0.52, 0.02) * CFrame.Angles(0, 0, -0.4),
				0.3,
				0.07,
				0.08,
				shade(r.c1, 0.85),
				"Wood"
			)
			-- five strings of shells and sea glass, swaying out of step in three lots
			for i = 1, 5 do
				local x = -0.64 + (i - 1) * 0.32
				local g = 1 + (i - 1) % 3
				if i <= 3 then
					Lively.pivot(r, CFrame.new(x, -0.6, 0), "swing", {
						speed = 1.4 + i * 0.25,
						amount = 0.12,
						axis = if i == 2 then "Z" else "X",
						phase = i * 1.4,
						group = g,
					})
				end
				Lively.moving(r, g, function()
					local len = 1.2 + ((i * 7) % 4) * 0.2
					r:cyl(x, -0.6 - len / 2, 0, len, 0.015, "y", TWINE, "Fabric")
					for j = 0, 2 do
						local y = -0.85 - j * len * 0.34
						local shell = r:lump(
							CFrame.new(x, y, 0) * CFrame.Angles(0, (i + j) * 0.7, 0.3),
							0.18,
							0.16,
							0.06,
							if (i + j) % 2 == 0 then r.c2 else CREAM,
							"Marble"
						)
						shell.collide = false
						for k = -1, 1 do
							r:block(
								x + k * 0.05 - 0.008,
								y - 0.06,
								-0.035,
								x + k * 0.05 + 0.008,
								y + 0.06,
								-0.03,
								shade(r.c2, 0.85),
								"Marble"
							)
						end
					end
					K.sphere(r, x, -0.62 - len, 0, 0.1, Color3.fromRGB(150, 210, 200), "Glass").transp = 0.25
				end)
			end
		end,
	},
	{
		id = "anim_swing_lantern",
		name = "Swinging lantern",
		cat = "lights",
		style = "rustic",
		price = 80,
		place = "ceiling",
		size = Vector3.new(1.2, 3.0, 1.2),
		c1 = "3E3C42",
		c2 = "F2C46E",
		tags = { "light" },
		lively = true,
		build = function(r: R)
			-- a plate and a hook on the ceiling; the chain and the lantern sway from the hook
			K.disc(r, 0, -0.05, 0, 0.1, 0.4, r.c1, "Metal")
			r:cyl(0, -0.2, 0, 0.2, 0.06, "y", r.c1, "Metal")
			Lively.pivot(r, CFrame.new(0, -0.3, 0), "swing", { speed = 1.1, amount = 0.07, axis = "X" })
			Lively.moving(r, 1, function()
				for i = 0, 6 do
					K.ring(
						r,
						CFrame.new(0, -0.38 - i * 0.14, 0) * CFrame.Angles(0, if i % 2 == 0 then 0 else math.pi / 2, 0),
						0.05,
						6,
						0.022,
						r.c1,
						"Metal"
					)
				end
				-- a ring on top, a pointed cap, the glass case in a frame, a base and a drip
				K.ring(r, CFrame.new(0, -1.42, 0), 0.08, 8, 0.03, r.c1, "Metal")
				r:cone(0, -1.68, 0, 0.36, 0.72, r.c1, "Metal")
				K.disc(r, 0, -1.88, 0, 0.06, 0.78, r.c1, "Metal")
				for _, sx in { -1, 1 } do
					for _, sz in { -1, 1 } do
						r:block(
							sx * 0.3 - 0.03,
							-2.6,
							sz * 0.3 - 0.03,
							sx * 0.3 + 0.03,
							-1.9,
							sz * 0.3 + 0.03,
							r.c1,
							"Metal"
						)
					end
				end
				local glass = r:block(-0.27, -2.58, -0.27, 0.27, -1.92, 0.27, mix(r.c2, C.White, 0.6), "Glass")
				glass.transp = 0.55
				r:block(-0.36, -2.7, -0.36, 0.36, -2.6, 0.36, r.c1, "Metal")
				r:cone(0, -2.8, 0, 0.18, 0.3, r.c1, "Metal").cf = CFrame.new(0, -2.8, 0) * CFrame.Angles(math.pi, 0, 0)
				-- a candle inside, lit
				r:cyl(0, -2.45, 0, 0.26, 0.16, "y", CREAM, "Plaster")
				local flame = r:lump(CFrame.new(0, -2.24, 0), 0.08, 0.16, 0.08, r.c2, "Glass")
				r:glow(flame, 14, 1.1)
			end)
		end,
	},
	{
		id = "anim_tabletop_fountain",
		name = "Tabletop water wheel",
		cat = "decor",
		style = "cozy",
		price = 95,
		place = "surface",
		size = Vector3.new(1.6, 1.5, 1.2),
		c1 = "8E8A82",
		c2 = "5C8C6A",
		lively = true,
		build = function(r: R)
			-- a glazed round dish of water, with stones heaped at the back
			local glaze = Color3.fromRGB(188, 160, 130)
			local dish = K.disc(r, 0, 0.06, 0.1, 0.12, 1.5, glaze, "CeramicTiles")
			dish.size = Vector3.new(0.12, 1.5, 1.05)
			for k = 0, 17 do
				local a0, a1 = k / 18 * math.pi * 2, (k + 1) / 18 * math.pi * 2
				K.rod(
					r,
					Vector3.new(math.cos(a0) * 0.7, 0.18, 0.1 + math.sin(a0) * 0.47),
					Vector3.new(math.cos(a1) * 0.7, 0.18, 0.1 + math.sin(a1) * 0.47),
					0.12,
					shade(glaze, 1.05),
					"CeramicTiles"
				)
			end
			K.roundSurface(r, 0, 0.21, 0.1, 1.3).size = Vector3.new(0.06, 1.32, 0.88)
			for i, p in
				{
					{ -0.4, 0.4, -0.2, 0.5 },
					{ 0.05, 0.62, -0.28, 0.46 },
					{ 0.42, 0.42, -0.2, 0.42 },
					{ -0.15, 0.82, -0.3, 0.3 },
				}
			do
				r:lump(
					CFrame.new(p[1], p[2], p[3]) * CFrame.Angles(0, i, 0.15),
					p[4] * 1.2,
					p[4],
					p[4],
					shade(r.c1, 0.88 + (i % 3) * 0.06),
					"Rock"
				)
			end
			for i, p in { { -0.5, 0.66, -0.1 }, { 0.36, 0.66, -0.12 } } do
				r:lump(CFrame.new(p[1], p[2], p[3]) * CFrame.Angles(0, i, 0), 0.22, 0.1, 0.18, r.c2, "Grass")
			end
			-- a bamboo spout off the top stone, and the water running from it onto the wheel
			r:cyl(0.1, 1.0, -0.12, 0.5, 0.08, "x", Color3.fromRGB(196, 184, 120), "Wood").cf = CFrame.new(
				0.15,
				0.98,
				-0.1
			) * CFrame.Angles(0, 0, -0.25)
			K.sheet(r, Vector3.new(0.38, 0.92, -0.08), Vector3.new(0.4, 0.62, -0.06), 0.07, { speed = 2 })
			-- the little wheel on a forked stick, turning as the water falls on it
			for _, sz in { -1, 1 } do
				r:block(
					0.36 - 0.02,
					0.22,
					sz * 0.14 - 0.06 - 0.02,
					0.36 + 0.02,
					0.46,
					sz * 0.14 - 0.06 + 0.02,
					C.Bark,
					"Wood"
				)
			end
			Lively.pivot(r, CFrame.new(0.36, 0.44, -0.06), "spin", { speed = -1.5, axis = "Z" })
			Lively.moving(r, 1, function()
				r:cyl(0.36, 0.44, -0.06, 0.3, 0.04, "z", C.Bark, "Wood")
				K.ring(r, CFrame.new(0.36, 0.44, -0.12), 0.18, 10, 0.025, C.Bark, "Wood")
				K.ring(r, CFrame.new(0.36, 0.44, 0.0), 0.18, 10, 0.025, C.Bark, "Wood")
				for k = 0, 7 do
					r:boxAt(
						CFrame.new(0.36, 0.44, -0.06) * CFrame.Angles(0, 0, k * math.pi / 4) * CFrame.new(0, 0.17, 0),
						0.02,
						0.1,
						0.13,
						shade(C.Bark, 1.2),
						"Wood"
					)
				end
			end)
			Lively.fx(r, "ripple", 0.3, 0.24, 0.1, { w = 0.3, d = 0.3 })
		end,
	},
	{
		id = "anim_music_box",
		name = "Music box",
		cat = "decor",
		style = "fancy",
		price = 110,
		place = "surface",
		size = Vector3.new(1.2, 1.3, 1.0),
		c1 = "8A4E5E",
		c2 = "F2D2D8",
		tags = { "music" },
		lively = true,
		build = function(r: R)
			-- a lacquered box on little feet, gold lines round it, and its lid open at the back with
			-- a mirror inside
			r:block(-0.55, 0.06, -0.35, 0.55, 0.46, 0.4, r.c1, "Wood")
			for _, sx in { -1, 1 } do
				for _, sz in { -1, 1 } do
					K.sphere(r, sx * 0.48, 0.04, sz * 0.3, 0.08, BRASS, "Metal")
				end
			end
			r:block(-0.58, 0.4, -0.38, 0.58, 0.43, 0.43, BRASS, "Metal")
			r:block(-0.56, 0.12, 0.4, 0.56, 0.14, 0.43, BRASS, "Metal")
			r:block(-0.12, 0.2, 0.4, 0.12, 0.34, 0.44, BRASS, "Metal")
			r:block(-0.46, 0.46, -0.25, 0.46, 0.49, 0.3, r.c2, "Fabric")
			local lid = r:block(-0.55, 0.46, -0.41, 0.55, 1.18, -0.33, r.c1, "Wood")
			lid.cf = CFrame.new(0, 0.82, -0.4) * CFrame.Angles(-0.12, 0, 0)
			local mirror = r:block(-0.4, 0.55, -0.32, 0.4, 1.08, -0.3, Color3.fromRGB(200, 214, 220), "Glass")
			mirror.cf = CFrame.new(0, 0.82, -0.33) * CFrame.Angles(-0.12, 0, 0)
			mirror.size = Vector3.new(0.8, 0.56, 0.02)
			-- the key on its side, turning slowly
			Lively.pivot(r, CFrame.new(0.6, 0.26, 0.05), "spin", { speed = 0.8, axis = "X", group = 2 })
			Lively.moving(r, 2, function()
				r:cyl(0.6, 0.26, 0.05, 0.1, 0.04, "x", BRASS, "Metal")
				r:block(0.64, 0.16, 0.03, 0.66, 0.36, 0.07, BRASS, "Metal")
			end)
			-- the dancer on her stand, going round
			K.disc(r, 0, 0.51, 0.05, 0.04, 0.24, BRASS, "Metal")
			Lively.pivot(r, CFrame.new(0, 0.5, 0.05), "spin", { speed = 1.4 })
			Lively.moving(r, 1, function()
				r:cyl(0, 0.54, 0.05, 0.06, 0.03, "y", BRASS, "Metal")
				r:cone(0, 0.66, 0.05, 0.16, 0.26, r.c2, "Fabric")
				r:lump(CFrame.new(0, 0.79, 0.05), 0.08, 0.14, 0.07, r.c2, "Fabric")
				K.sphere(r, 0, 0.9, 0.05, 0.08, Color3.fromRGB(240, 214, 196), "Plaster")
				K.sphere(r, 0, 0.94, 0.03, 0.06, Color3.fromRGB(110, 78, 60), "Fabric")
				K.rod(
					r,
					Vector3.new(0, 0.84, 0.05),
					Vector3.new(-0.1, 0.98, 0.05),
					0.02,
					Color3.fromRGB(240, 214, 196),
					"Plaster"
				)
				K.rod(
					r,
					Vector3.new(0, 0.84, 0.05),
					Vector3.new(0.1, 0.98, 0.05),
					0.02,
					Color3.fromRGB(240, 214, 196),
					"Plaster"
				)
				K.rod(
					r,
					Vector3.new(0, 0.58, 0.05),
					Vector3.new(0.02, 0.5, 0.12),
					0.02,
					Color3.fromRGB(240, 214, 196),
					"Plaster"
				)
			end)
			Lively.fx(r, "notes", 0, 1.0, 0.05, { w = 0.2, d = 0.2 })
		end,
	},
	{
		id = "anim_orrery",
		name = "Orrery",
		cat = "decor",
		style = "fancy",
		price = 240,
		place = "surface",
		size = Vector3.new(1.8, 1.6, 1.8),
		c1 = "6E4A36",
		c2 = "D6B064",
		tags = { "light" },
		lively = true,
		build = function(r: R)
			local brass = r.c2
			-- a round wooden base with a brass ring of the months, and the column
			K.disc(r, 0, 0.06, 0, 0.12, 1.1, r.c1, "Wood")
			K.disc(r, 0, 0.14, 0, 0.04, 0.96, shade(r.c1, 1.15), "Wood")
			K.hoop(r, 0, 0.17, 0, 0.42, 20, 0.03, brass, "Metal")
			for k = 0, 11 do
				local a = k * math.pi / 6
				r:block(
					math.cos(a) * 0.42 - 0.01,
					0.16,
					math.sin(a) * 0.42 - 0.01,
					math.cos(a) * 0.42 + 0.01,
					0.2,
					math.sin(a) * 0.42 + 0.01,
					INK,
					"Metal"
				)
			end
			r:cyl(0, 0.6, 0, 0.9, 0.08, "y", brass, "Metal").smooth = true
			-- the sun on top, lit
			local sun = K.sphere(r, 0, 1.15, 0, 0.26, Color3.fromRGB(255, 214, 120), "Glass")
			r:glow(sun, 8, 0.8, Color3.fromRGB(255, 214, 140))
			-- four worlds on arms at four heights, each going round at its own pace
			local worlds = {
				{ y = 0.6, rad = 0.36, d = 0.09, col = Color3.fromRGB(170, 160, 150), spd = 1.0 },
				{ y = 0.75, rad = 0.52, d = 0.13, col = Color3.fromRGB(96, 150, 200), spd = 0.6, moon = true },
				{ y = 0.9, rad = 0.66, d = 0.11, col = Color3.fromRGB(200, 110, 80), spd = 0.4 },
				{ y = 0.45, rad = 0.8, d = 0.17, col = Color3.fromRGB(214, 190, 140), spd = 0.24, rings = true },
			}
			for g, w in worlds do
				Lively.pivot(r, CFrame.new(0, w.y, 0), "spin", { speed = w.spd, group = g, phase = g * 1.6 })
				Lively.moving(r, g, function()
					K.disc(r, 0, w.y, 0, 0.04, 0.12, brass, "Metal")
					r:block(0, w.y - 0.012, -0.012, w.rad, w.y + 0.012, 0.012, brass, "Metal")
					r:cyl(w.rad, w.y + 0.08, 0, 0.16, 0.02, "y", brass, "Metal")
					K.sphere(r, w.rad, w.y + 0.16 + w.d / 2, 0, w.d, w.col, "Marble")
					if w.moon then
						r:block(w.rad, w.y + 0.22, -0.006, w.rad + 0.14, w.y + 0.232, 0.006, brass, "Metal")
						K.sphere(r, w.rad + 0.15, w.y + 0.25, 0, 0.05, CREAM, "Marble")
					end
					if w.rings then
						local ring =
							K.disc(r, w.rad, w.y + 0.16 + w.d / 2, 0, 0.01, w.d * 2, shade(w.col, 0.85), "Metal")
						ring.cf = ring.cf * CFrame.Angles(0.3, 0, 0)
					end
				end)
			end
		end,
	},
	{
		id = "anim_plasma_globe",
		name = "Plasma globe",
		cat = "decor",
		style = "scifi",
		price = 90,
		place = "surface",
		size = Vector3.new(0.9, 1.25, 0.9),
		c1 = "2E2C34",
		c2 = "C49AF4",
		tags = { "light" },
		lively = true,
		build = function(r: R)
			-- a black base with a switch, a clear glass ball on it and the glowing core
			K.disc(r, 0, 0.12, 0, 0.24, 0.6, r.c1, "Metal")
			local foot = r:cone(0, 0.32, 0, 0.18, 0.5, r.c1, "Metal")
			foot.smooth = nil
			r:block(-0.06, 0.1, 0.27, 0.06, 0.16, 0.31, shade(r.c1, 1.6), "Rubber")
			r:cyl(0, 0.45, 0, 0.14, 0.08, "y", C.DarkMetal, "Metal")
			local core = K.sphere(r, 0, 0.75, 0, 0.16, r.c2, "Glass")
			r:glow(core, 7, 0.8, r.c2)
			-- streamers out from the core to the glass, turning slowly and flickering
			Lively.pivot(r, CFrame.new(0, 0.75, 0), "spin", { speed = 0.7 })
			Lively.moving(r, 1, function()
				for k = 0, 6 do
					local a = k * 0.9
					local tip = Vector3.new(math.cos(a) * 0.3, 0.75 + math.sin(k * 1.7) * 0.22, math.sin(a) * 0.3)
					local mid = (Vector3.new(0, 0.75, 0) + tip) / 2
						+ Vector3.new(math.sin(k) * 0.04, 0.03, math.cos(k) * 0.04)
					for _, seg in { { Vector3.new(0, 0.75, 0), mid }, { mid, tip } } do
						local s = r:beam(seg[1], seg[2], 0.025, 0.025, mix(r.c2, C.White, 0.3), "Glass")
						if s then
							s.transp = 0.2
							r:glow(s, 0)
							Lively.blink(s)
						end
					end
				end
			end)
			local ball = K.sphere(r, 0, 0.75, 0, 0.8, Color3.fromRGB(220, 226, 240), "Glass")
			ball.transp = 0.7
		end,
	},
	{
		id = "anim_birdcage",
		name = "Gilded birdcage",
		cat = "decor",
		style = "fancy",
		price = 260,
		place = "floor",
		size = Vector3.new(1.8, 5.6, 1.8),
		c1 = "D6B064",
		c2 = "F2D04E",
		lively = true,
		build = function(r: R)
			local gold = r.c1
			-- a stand: three curled feet, a turned column and a round dish the cage sits on
			for k = 0, 2 do
				local a = k * math.pi * 2 / 3
				K.path(r, {
					Vector3.new(0, 0.9, 0),
					Vector3.new(math.cos(a) * 0.5, 0.25, math.sin(a) * 0.5),
					Vector3.new(math.cos(a) * 0.75, 0.06, math.sin(a) * 0.75),
				}, 0.08, gold, "Metal")
				K.sphere(r, math.cos(a) * 0.8, 0.06, math.sin(a) * 0.8, 0.12, gold, "Metal")
			end
			r:cyl(0, 1.9, 0, 2.0, 0.12, "y", gold, "Metal").smooth = true
			for _, h in { 1.0, 1.9, 2.8 } do
				K.sphere(r, 0, h, 0, 0.2, gold, "Metal")
			end
			K.disc(r, 0, 3.0, 0, 0.1, 1.5, gold, "Metal")
			K.disc(r, 0, 3.06, 0, 0.03, 1.36, Color3.fromRGB(214, 196, 160), "Sand")
			-- the cage: sixteen bars up and over into a dome, rings round it, a finial and hook
			local n = 16
			for k = 0, n - 1 do
				local a = k / n * math.pi * 2
				local c, s = math.cos(a), math.sin(a)
				K.path(r, {
					Vector3.new(c * 0.68, 3.05, s * 0.68),
					Vector3.new(c * 0.68, 4.5, s * 0.68),
					Vector3.new(c * 0.55, 4.95, s * 0.55),
					Vector3.new(c * 0.28, 5.2, s * 0.28),
					Vector3.new(0, 5.26, 0),
				}, 0.025, gold, "Metal")
			end
			for _, h in { 3.12, 3.8, 4.5 } do
				K.hoop(r, 0, h, 0, 0.68, 24, 0.04, gold, "Metal")
			end
			K.sphere(r, 0, 5.3, 0, 0.16, gold, "Metal")
			K.ring(r, CFrame.new(0, 5.47, 0), 0.1, 10, 0.035, gold, "Metal")
			-- a fixed perch and a seed cup, and the bird on a little swing, swinging
			r:cyl(0, 3.55, 0, 1.3, 0.04, "x", C.Bark, "Wood")
			K.disc(r, 0.45, 3.3, 0.45, 0.16, 0.22, CREAM, "Plaster")
			Lively.pivot(r, CFrame.new(0, 4.9, 0), "swing", { speed = 1.4, amount = 0.22, axis = "X" })
			Lively.moving(r, 1, function()
				for _, sx in { -1, 1 } do
					r:cyl(sx * 0.2, 4.45, 0, 0.9, 0.015, "y", gold, "Metal")
				end
				r:cyl(0, 4.0, 0, 0.44, 0.04, "x", gold, "Metal")
				-- the bird: a body, a head with a crest, a beak, a long tail and its eyes
				r:lump(CFrame.new(0, 4.22, 0) * CFrame.Angles(-0.3, 0, 0), 0.22, 0.3, 0.26, r.c2, "Fabric")
				K.sphere(r, 0, 4.42, 0.06, 0.18, r.c2, "Fabric")
				r:cone(0, 4.55, 0.04, 0.1, 0.06, shade(r.c2, 0.85), "Fabric")
				r:cone(0, 4.41, 0.18, 0.08, 0.06, Color3.fromRGB(232, 150, 80), "Wood").cf = CFrame.new(0, 4.41, 0.18)
					* CFrame.Angles(math.pi / 2, 0, 0)
				r:tri(
					Vector3.new(0, 4.16, -0.1),
					Vector3.new(-0.06, 3.9, -0.32),
					Vector3.new(0.06, 3.9, -0.32),
					0.02,
					shade(r.c2, 0.8),
					"Fabric"
				)
				for _, sx in { -1, 1 } do
					K.sphere(r, sx * 0.07, 4.45, 0.12, 0.035, INK, "Metal")
					r:lump(
						CFrame.new(sx * 0.11, 4.22, -0.02) * CFrame.Angles(-0.3, 0, sx * 0.2),
						0.04,
						0.2,
						0.18,
						shade(r.c2, 0.88),
						"Fabric"
					)
				end
			end)
		end,
	},
	{
		id = "anim_robot_dog",
		name = "Robot dog",
		cat = "fun",
		style = "scifi",
		price = 280,
		place = "floor",
		size = Vector3.new(1.2, 1.7, 2.2),
		c1 = "D8DCE2",
		c2 = "6EC8D8",
		tags = { "toy" },
		lively = true,
		build = function(r: R)
			local shell = r.c1
			-- a body with a panel down its back, four jointed legs and round feet
			r:block(-0.4, 0.62, -0.7, 0.4, 1.12, 0.6, shell, "Metal")
			r:block(-0.3, 1.12, -0.5, 0.3, 1.16, 0.4, shade(shell, 0.85), "Metal")
			r:block(-0.43, 0.8, -0.55, 0.43, 0.86, 0.45, r.c2, "Metal")
			for _, sx in { -1, 1 } do
				for _, z in { -0.5, 0.42 } do
					K.sphere(r, sx * 0.32, 0.62, z, 0.2, C.DarkMetal, "Metal")
					r:cyl(sx * 0.32, 0.4, z, 0.4, 0.13, "y", shell, "Metal")
					K.sphere(r, sx * 0.32, 0.2, z, 0.16, C.DarkMetal, "Metal")
					local foot = K.disc(r, sx * 0.32, 0.05, z + 0.04, 0.1, 0.24, C.DarkMetal, "Rubber")
					foot.size = Vector3.new(0.1, 0.24, 0.3)
				end
			end
			-- the head on a neck, tilting now and then; a visor with eyes that blink, two ears
			r:cyl(0, 1.18, 0.55, 0.2, 0.16, "y", C.DarkMetal, "Metal")
			Lively.pivot(r, CFrame.new(0, 1.3, 0.62), "swing", { speed = 0.7, amount = 0.18, axis = "Z", group = 2 })
			Lively.moving(r, 2, function()
				r:block(-0.3, 1.22, 0.42, 0.3, 1.66, 0.98, shell, "Metal")
				r:block(-0.24, 1.32, 0.98, 0.24, 1.58, 1.01, Color3.fromRGB(40, 46, 60), "Glass")
				for _, sx in { -1, 1 } do
					local eye = K.sphere(r, sx * 0.1, 1.46, 1.0, 0.09, r.c2, "Glass")
					r:glow(eye, 0)
					Lively.blink(eye)
					r:block(sx * 0.22 - 0.05, 1.66, 0.56, sx * 0.22 + 0.05, 1.8, 0.7, shade(shell, 0.85), "Metal")
					K.sphere(r, sx * 0.22, 1.82, 0.63, 0.06, r.c2, "Metal")
				end
				r:block(-0.12, 1.24, 0.98, 0.12, 1.28, 1.01, C.DarkMetal, "Metal")
			end)
			-- the tail, an aerial with a light on its end, wagging
			Lively.pivot(r, CFrame.new(0, 1.05, -0.7), "swing", { speed = 6, amount = 0.45, axis = "Y" })
			Lively.moving(r, 1, function()
				K.rod(r, Vector3.new(0, 1.05, -0.7), Vector3.new(0, 1.35, -1.0), 0.05, C.DarkMetal, "Metal")
				K.sphere(r, 0, 1.37, -1.02, 0.1, r.c2, "Metal")
			end)
		end,
	},
	{
		id = "anim_fog_machine",
		name = "Fog machine",
		cat = "effects",
		style = "playful",
		price = 0,
		gems = 20,
		place = "floor",
		size = Vector3.new(2.2, 1.4, 1.8),
		c1 = "3A3A42",
		c2 = "E8ECF4",
		lively = true,
		build = function(r: R)
			local body = r.c1
			local edge = shade(body, 1.3)
			-- a metal case on rubber feet, its edges rounded, vents along each side
			r:block(-0.85, 0.1, -0.7, 0.85, 0.9, 0.7, body, "Metal")
			for _, sx in { -1, 1 } do
				for _, sz in { -1, 1 } do
					local rim = r:cyl(sx * 0.85, 0.5, sz * 0.7, 0.8, 0.08, "y", edge, "Metal")
					rim.smooth = true
					K.disc(r, sx * 0.7, 0.05, sz * 0.55, 0.1, 0.16, INK, "Rubber")
				end
			end
			for _, sx in { -1, 1 } do
				for i = 0, 4 do
					local y = 0.28 + i * 0.12
					r:block(
						sx * 0.85 - (if sx > 0 then 0 else 0.03),
						y,
						-0.5,
						sx * 0.85 + (if sx > 0 then 0.03 else 0),
						y + 0.05,
						0.5,
						INK,
						"Metal"
					)
				end
			end
			-- a carrying handle over the top, the tank of fog juice behind it and its cap
			for _, sx in { -1, 1 } do
				r:block(sx * 0.6 - 0.05, 0.9, -0.05, sx * 0.6 + 0.05, 1.2, 0.05, edge, "Metal")
			end
			r:cyl(0, 1.24, 0, 1.3, 0.1, "x", edge, "Metal").smooth = true
			local tank = r:block(-0.55, 0.9, -0.62, 0.15, 1.3, -0.3, Color3.fromRGB(200, 220, 236), "Glass")
			tank.transp = 0.45
			r:block(-0.52, 0.92, -0.59, 0.12, 1.1, -0.33, mix(r.c2, Color3.fromRGB(140, 190, 230), 0.4), "Glass").transp =
				0.3
			K.disc(r, -0.2, 1.34, -0.46, 0.08, 0.16, INK, "Rubber")
			-- the front: a round nozzle in a collar, a dial and a little lamp that shows it's on
			r:block(-0.6, 0.15, 0.7, 0.6, 0.85, 0.73, shade(body, 1.15), "Metal")
			K.face(r, 0, 0.5, 0.78, 0.12, 0.44, edge, "Metal")
			K.face(r, 0, 0.5, 0.86, 0.1, 0.3, INK, "Metal")
			K.face(r, -0.42, 0.68, 0.75, 0.06, 0.14, C.Metal, "Metal")
			local lamp = K.sphere(r, 0.42, 0.68, 0.75, 0.09, Color3.fromRGB(130, 230, 150), "Glass")
			r:glow(lamp, 4, 0.4, Color3.fromRGB(130, 230, 150))
			-- a coiled cable at the back
			for k = 0, 2 do
				K.hoop(r, -0.6 + k * 0.06, 0.05 + k * 0.035, -0.9, 0.18, 10, 0.04, INK, "Rubber")
			end
			-- the fog: puffs out of the nozzle, and a low bank round its feet, while it's switched on
			Lively.fx(r, "fog", 0, 0.5, 0.88, { w = 0.2, h = 0.2, d = 0.1, color = r.c2, switch = true })
			Lively.fx(r, "fogbank", 0, 0.15, 0, { w = 2.0, h = 0.1, d = 1.6, color = r.c2, switch = true })
		end,
	},
}

return items
