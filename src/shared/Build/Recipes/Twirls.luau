--!strict
-- More pieces that move, for the garden and the street side (the user: "Add much more decor and
-- make animated pieces, such as a swarm of fireflies that produce light, and models that have
-- moving pieces"): fireflies drifting over long grass and lighting it, a wind turbine, chimes
-- that sway, a pot on the boil, a flag that ripples, a weather station, a bird feeder with birds
-- pecking, a lighthouse whose lamp goes round, a street clock on the town's time, a bee skep and a
-- roundabout. Each names its moving parts and their pivots (Build/Lively); every player's own
-- screen moves them near the camera (client World/Lively). Nothing that moves is solid. Drawn at
-- the starting house's level of detail, in textured materials, round where the real thing is round
-- (Geometry's `smooth`: the user, "You are allowed to use spheres, curves or circles where
-- necessary"). Indoor ones are in Recipes/TwirlsIndoor.

local Recipe = require(script.Parent.Parent.Recipe)
local Lively = require(script.Parent.Parent.Lively)
local K = require(script.Parent.Parent.RecipeKit)
local Colors = require(script.Parent.Parent.Parent.Util.Colors)

local C = Recipe.Colors

type R = Recipe.Recipe
type Prim = Recipe.Prim

local IRON = Color3.fromRGB(70, 68, 76)
local STONE = Color3.fromRGB(150, 146, 140)
local TWINE = Color3.fromRGB(196, 172, 128)
local CREAM = Color3.fromRGB(246, 240, 226)
local INK = Color3.fromRGB(52, 48, 56)
local EMBER = Color3.fromRGB(255, 150, 70)

local function shade(c: Color3, k: number): Color3
	return Colors.shade(c, k)
end

local function mix(a: Color3, b: Color3, t: number): Color3
	return Colors.mix(a, b, t)
end

-- A blade of long grass from its foot, leaning out along the angle `a`, in two parts.
local function blade(r: R, x: number, z: number, h: number, a: number, lean: number, col: Color3)
	local out = Vector3.new(math.cos(a), 0, math.sin(a))
	local foot = Vector3.new(x, 0.05, z)
	local mid = foot + out * (lean * h * 0.35) + Vector3.new(0, h * 0.55, 0)
	local top = foot + out * (lean * h) + Vector3.new(0, h, 0)
	local b1 = r:beam(foot, mid, 0.12, 0.04, col, "Grass")
	local b2 = r:beam(mid - (mid - foot).Unit * 0.04, top, 0.07, 0.03, mix(col, C.Yellow, 0.2), "Grass")
	if b1 then
		b1.collide = false
	end
	if b2 then
		b2.collide = false
	end
end

-- A small bird facing +Z at (x, y, z), its feet at y: a body, a head, a beak, a tail and an eye
-- each side. `col` the body, `breast` its front.
local function bird(r: R, x: number, y: number, z: number, col: Color3, breast: Color3, s: number?)
	local k = s or 1
	r:lump(CFrame.new(x, y + 0.2 * k, z) * CFrame.Angles(-0.35, 0, 0), 0.24 * k, 0.26 * k, 0.36 * k, col, "Fabric")
	r:lump(CFrame.new(x, y + 0.17 * k, z + 0.08 * k), 0.18 * k, 0.18 * k, 0.16 * k, breast, "Fabric")
	r:ball(x, y + 0.36 * k, z + 0.1 * k, 0.18 * k, col, "Fabric")
	r:cone(x, y + 0.36 * k, z + 0.22 * k, 0.1 * k, 0.06 * k, C.Gold, "Wood").cf = CFrame.new(
		x,
		y + 0.36 * k,
		z + 0.22 * k
	) * CFrame.Angles(math.pi / 2, 0, 0)
	r:tri(
		Vector3.new(x, y + 0.22 * k, z - 0.12 * k),
		Vector3.new(x - 0.08 * k, y + 0.3 * k, z - 0.34 * k),
		Vector3.new(x + 0.08 * k, y + 0.3 * k, z - 0.34 * k),
		0.02,
		shade(col, 0.8),
		"Fabric"
	)
	for _, sx in { -1, 1 } do
		r:ball(x + sx * 0.07 * k, y + 0.39 * k, z + 0.15 * k, 0.035 * k, INK, "Metal")
	end
	for _, sx in { -1, 1 } do
		r:block(x + sx * 0.05 * k - 0.01, y, z - 0.01, x + sx * 0.05 * k + 0.01, y + 0.1 * k, z + 0.01, C.Gold, "Metal")
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
	gives: string?,
	build: (r: R) -> (),
}

local items: { Item } = {
	{
		id = "anim_firefly_swarm",
		name = "Firefly swarm",
		cat = "garden",
		style = "garden",
		price = 180,
		place = "ground",
		size = Vector3.new(4.4, 4.2, 4.4),
		c1 = "6FA05E",
		c2 = "DEF480",
		tags = { "light" },
		lively = true,
		build = function(r: R)
			local grass = r.c1
			local glowC = r.c2
			-- a low grassy mound, a mossy log lying across it and toadstools by the log
			r:lump(CFrame.new(0, 0.12, 0), 3.6, 0.36, 3.4, shade(grass, 0.85), "Grass")
			local log = r:cyl(-0.3, 0.42, 0.5, 2.4, 0.5, "x", C.Bark, "Wood")
			log.cf = log.cf * CFrame.Angles(0, 0.35, 0)
			r:cyl(-1.42, 0.38, 0.92, 0.04, 0.44, "x", Color3.fromRGB(196, 160, 116), "Wood").cf = CFrame.new(
				-1.42,
				0.45,
				0.94
			) * CFrame.Angles(0, 0.35, 0)
			for i, p in { { -0.8, 0.7 }, { 0.1, 0.45 }, { 0.6, 0.2 } } do
				r:lump(CFrame.new(p[1], 0.66, p[2]) * CFrame.Angles(0, i, 0.1), 0.5, 0.16, 0.36, C.DarkLeaf, "Grass")
			end
			-- glowing toadstools by the log (the piece's switch: Services/Lights puts it here)
			for i, p in { { 0.9, 1.1, 0.3 }, { 1.2, 0.9, 0.22 }, { 1.05, 1.35, 0.18 } } do
				r:cyl(p[1], p[3] / 2 + 0.1, p[2], p[3], 0.07, "y", CREAM, "Fabric")
				local cap =
					r:lump(CFrame.new(p[1], p[3] + 0.12, p[2]), 0.26, 0.12, 0.26, mix(glowC, CREAM, 0.4), "Glass")
				r:glow(cap, if i == 1 then 6 else 0, 0.6, glowC)
			end
			-- long grass and reeds in clumps, some with seed heads
			local clumps = { { -1.4, -1.1 }, { 1.3, -1.2 }, { -1.5, 1.4 }, { 0.2, -1.5 }, { 1.6, 0.4 }, { -0.4, 1.6 } }
			for c, p in clumps do
				for k = 0, 5 do
					local a = k * 1.05 + c
					local h = 1.2 + ((k * 7 + c * 3) % 5) * 0.22
					blade(r, p[1] + math.cos(a) * 0.16, p[2] + math.sin(a) * 0.16, h, a, 0.18, grass)
				end
				local reed = r:cyl(p[1], 0.9, p[2], 1.8, 0.05, "y", shade(grass, 0.8), "Grass")
				reed.collide = false
				r:noCollide(r:cyl(p[1], 1.9, p[2], 0.4, 0.13, "y", Color3.fromRGB(124, 88, 60), "Fabric"))
			end
			-- a few flowers in the grass
			for i, p in { { -0.9, -0.5 }, { 0.6, -0.9 }, { -0.2, -0.2 } } do
				r:noCollide(r:cyl(p[1], 0.35, p[2], 0.6, 0.04, "y", C.DarkLeaf, "Grass"))
				for k = 0, 4 do
					local a = k * math.pi * 2 / 5
					r:lump(
						CFrame.new(p[1] + math.cos(a) * 0.08, 0.66, p[2] + math.sin(a) * 0.08)
							* CFrame.Angles(0, -a, 0.3),
						0.12,
						0.04,
						0.08,
						if i == 2 then C.Pink else CREAM,
						"Fabric"
					)
				end
				r:ball(p[1], 0.68, p[2], 0.07, C.Yellow, "Fabric")
			end
			-- four clouds of fireflies, each wandering its own slow loop, each speck blinking on
			-- its own; one in each cloud carries a little light that goes with it
			local clouds = {
				{ at = Vector3.new(-0.7, 1.9, -0.4), n = 4, amt = 1.1, spd = 0.45 },
				{ at = Vector3.new(0.8, 2.6, 0.3), n = 4, amt = 1.2, spd = 0.35 },
				{ at = Vector3.new(-0.2, 3.1, 0.7), n = 3, amt = 0.9, spd = 0.55 },
				{ at = Vector3.new(0.4, 1.5, -0.8), n = 3, amt = 0.8, spd = 0.5 },
			}
			for g, cl in clouds do
				Lively.pivot(
					r,
					CFrame.new(cl.at),
					"drift",
					{ speed = cl.spd, amount = cl.amt, group = g, phase = g * 1.7 }
				)
				Lively.moving(r, g, function()
					for k = 1, cl.n do
						local a = k * 2.4 + g
						local off = Vector3.new(math.cos(a) * 0.35, ((k * 5) % 3 - 1) * 0.18, math.sin(a) * 0.35)
						local p = cl.at + off
						local speck = K.sphere(r, p.X, p.Y, p.Z, 0.12, glowC, "Glass")
						r:glow(speck, if k == 1 then 9 else 0, 0.7, glowC)
						Lively.blink(speck)
						local halo = K.sphere(r, p.X, p.Y, p.Z, 0.34, glowC, "Glass")
						halo.transp = 0.78
						Lively.blink(halo)
					end
				end)
			end
			-- and more of them in the air as specks, on each player's screen
			Lively.fx(r, "fireflies", 0, 1.4, 0, { w = 3.2, h = 1.6, d = 3.2, color = glowC, switch = true })
		end,
	},
	{
		id = "anim_wind_turbine",
		name = "Wind turbine",
		cat = "garden",
		style = "modern",
		price = 640,
		place = "ground",
		size = Vector3.new(5, 13, 2.6),
		c1 = "EEF0EE",
		c2 = "6E9FC2",
		lively = true,
		build = function(r: R)
			local white = r.c1
			local edge = shade(white, 0.9)
			-- a concrete pad with a step and a little door in the tower's foot
			r:cyl(0, 0.15, 0, 0.3, 2.4, "y", STONE, "Concrete").smooth = true
			r:block(-0.45, 0, 1.0, 0.45, 0.22, 1.3, STONE, "Concrete")
			-- the tower, narrowing as it goes up in four sections, a band at each joint
			local h0 = 0.3
			for i = 0, 3 do
				local d = 1.1 - i * 0.16
				local len = 2.4
				K.disc(r, 0, h0 + len / 2, 0, len, d, white, "Metal").size = Vector3.new(len, d, d)
				K.disc(r, 0, h0 + len, 0, 0.08, d + 0.06, edge, "Metal")
				h0 += len
			end
			r:block(-0.28, 0.3, 0.5, 0.28, 1.5, 0.6, shade(white, 0.8), "Metal")
			r:block(-0.26, 0.32, 0.6, 0.26, 1.48, 0.64, edge, "Metal")
			r:ball(0.18, 0.9, 0.66, 0.06, IRON, "Metal")
			-- the nacelle: a long rounded housing, its tail and a stripe of the second paint
			local top = h0 + 0.35
			r:block(-0.36, top - 0.32, -1.0, 0.36, top + 0.32, 0.6, white, "Metal")
			r:lump(CFrame.new(0, top, -1.0), 0.72, 0.64, 0.5, white, "Metal")
			r:block(-0.4, top - 0.06, -0.98, 0.4, top + 0.06, 0.58, r.c2, "Metal")
			r:block(-0.08, top + 0.32, -0.7, 0.08, top + 0.44, -0.4, edge, "Metal")
			r:cyl(0, top + 0.5, -0.55, 0.12, 0.06, "y", IRON, "Metal")
			-- the rotor: a rounded nose and three long blades, going round slowly
			local hub = CFrame.new(0, top, 0.85)
			Lively.pivot(r, hub, "spin", { speed = 0.9, axis = "Z" })
			Lively.moving(r, 1, function()
				r:cyl(0, top, 0.7, 0.3, 0.5, "z", white, "Metal")
				r:lump(CFrame.new(0, top, 0.95), 0.56, 0.56, 0.5, white, "Metal")
				for k = 0, 2 do
					local f = hub * CFrame.Angles(0, 0, k * math.pi * 2 / 3)
					-- a blade narrows out to its tip, turned a little into the wind
					r:boxAt(f * CFrame.new(0, 0.75, -0.04) * CFrame.Angles(0, 0.25, 0), 0.34, 0.8, 0.07, white, "Metal")
					r:boxAt(
						f * CFrame.new(0.02, 1.55, -0.04) * CFrame.Angles(0, 0.18, 0),
						0.28,
						0.85,
						0.06,
						white,
						"Metal"
					)
					r:boxAt(f * CFrame.new(0.03, 2.25, -0.04) * CFrame.Angles(0, 0.1, 0), 0.2, 0.6, 0.05, edge, "Metal")
					r:boxAt(
						f * CFrame.new(0.03, 2.45, -0.01) * CFrame.Angles(0, 0.1, 0),
						0.2,
						0.18,
						0.06,
						r.c2,
						"Metal"
					)
				end
			end)
		end,
	},
	{
		id = "anim_wind_chimes",
		name = "Wind chimes",
		cat = "garden",
		style = "garden",
		price = 70,
		place = "ground",
		size = Vector3.new(1.8, 5.4, 1.2),
		c1 = "B89870",
		c2 = "A9B8C2",
		lively = true,
		build = function(r: R)
			-- a shepherd's hook pushed into the grass, curling over at the top
			K.path(r, {
				Vector3.new(-0.55, 0, 0),
				Vector3.new(-0.55, 4.6, 0),
				Vector3.new(-0.45, 5.0, 0),
				Vector3.new(-0.15, 5.15, 0),
				Vector3.new(0.12, 5.05, 0),
				Vector3.new(0.2, 4.85, 0),
			}, 0.08, IRON, "Metal")
			r:cone(-0.55, 0.05, 0, 0.1, 0.12, IRON, "Metal")
			r:ball(0.2, 4.84, 0, 0.1, IRON, "Metal")
			-- the hanger: a ring under the hook, and a wooden top with its five strings
			K.ring(r, CFrame.new(0.2, 4.68, 0), 0.08, 8, 0.025, IRON, "Metal")
			r:noCollide(r:cyl(0.2, 4.42, 0, 0.4, 0.02, "y", TWINE, "Fabric"))
			K.disc(r, 0.2, 4.18, 0, 0.1, 0.7, r.c1, "Wood")
			K.disc(r, 0.2, 4.25, 0, 0.04, 0.5, shade(r.c1, 0.85), "Wood")
			-- five tubes of different lengths hanging round the top, in three groups that sway
			-- out of step; the striker and its sail in the middle swing further
			local tubes = { 1.5, 1.25, 1.05, 0.9, 1.35 }
			for i, len in tubes do
				local a = i / #tubes * math.pi * 2
				local x, z = 0.2 + math.cos(a) * 0.24, math.sin(a) * 0.24
				local g = 2 + (i - 1) % 3
				if i <= 3 then
					Lively.pivot(r, CFrame.new(0.2, 4.13, 0), "swing", {
						speed = 1.6 + i * 0.3,
						amount = 0.07,
						axis = if i % 2 == 0 then "X" else "Z",
						phase = i * 1.3,
						group = g,
					})
				end
				Lively.moving(r, g, function()
					r:cyl(x, 4.0, z, 0.26, 0.02, "y", TWINE, "Fabric")
					r:cyl(x, 3.85 - len / 2, z, len, 0.1, "y", r.c2, "Metal")
					K.disc(r, x, 3.85, z, 0.03, 0.11, shade(r.c2, 0.8), "Metal")
				end)
			end
			Lively.pivot(r, CFrame.new(0.2, 4.13, 0), "flutter", { speed = 1.2, amount = 0.16, axis = "X" })
			Lively.moving(r, 1, function()
				r:cyl(0.2, 3.3, 0, 1.66, 0.02, "y", TWINE, "Fabric")
				K.face(r, 0.2, 3.1, 0, 0.06, 0.36, shade(r.c1, 0.9), "Wood").cf = CFrame.new(0.2, 3.1, 0)
					* CFrame.Angles(math.pi / 2, 0, 0)
				r:cyl(0.2, 2.2, 0, 1.6, 0.02, "y", TWINE, "Fabric")
				r:block(0.0, 0.9, -0.02, 0.4, 1.4, 0.02, r.c1, "Wood")
				r:block(0.06, 1.02, 0.02, 0.34, 1.06, 0.035, shade(r.c1, 0.8), "Wood")
			end)
		end,
	},
	{
		id = "anim_cauldron",
		name = "Bubbling pot",
		cat = "garden",
		style = "rustic",
		price = 260,
		place = "ground",
		size = Vector3.new(3.2, 3.8, 3.2),
		c1 = "4A4850",
		c2 = "8FB06A",
		lively = true,
		gives = "cook",
		build = function(r: R)
			-- a ring of stones round a bed of ash, two logs crossed and glowing under the pot
			for i = 0, 10 do
				local a = i / 11 * math.pi * 2
				local s = 0.42 + (i * 31 % 4) * 0.05
				r:lump(
					CFrame.new(math.cos(a) * 1.15, s * 0.32, math.sin(a) * 1.15) * CFrame.Angles(0, a + i, 0.2),
					s * 1.2,
					s * 0.8,
					s,
					shade(STONE, 0.86 + (i % 3) * 0.07),
					"Rock"
				)
			end
			K.disc(r, 0, 0.04, 0, 0.08, 2.0, Color3.fromRGB(90, 84, 80), "Ground")
			for _, a in { 0.5, -0.6 } do
				local log = r:cyl(0, 0.26, 0, 1.7, 0.3, "x", C.Bark, "Wood")
				log.cf = CFrame.new(0, 0.26, 0) * CFrame.Angles(0, a, 0)
			end
			for i, p in { { 0.2, 0.1 }, { -0.25, -0.15 }, { 0.05, -0.3 } } do
				local ember =
					r:lump(CFrame.new(p[1], 0.36, p[2]) * CFrame.Angles(0, i, 0), 0.26, 0.12, 0.2, EMBER, "Glass")
				r:glow(ember, if i == 1 then 12 else 0, 1.2, EMBER)
			end
			Lively.fx(r, "flames", 0, 0.45, 0, { w = 0.5, d = 0.5 })
			Lively.fx(r, "embers", 0, 0.5, 0, { w = 0.6, d = 0.6 })
			-- a tripod of three iron legs, and a chain down to the pot's handle
			local top = Vector3.new(0, 3.55, 0)
			for k = 0, 2 do
				local a = k * math.pi * 2 / 3 + 0.3
				K.rod(r, Vector3.new(math.cos(a) * 1.4, 0.02, math.sin(a) * 1.4), top, 0.1, IRON, "Metal")
			end
			r:ball(0, 3.58, 0, 0.18, IRON, "Metal")
			for i = 0, 4 do
				K.ring(
					r,
					CFrame.new(0, 3.38 - i * 0.16, 0) * CFrame.Angles(0, if i % 2 == 0 then 0 else math.pi / 2, 0),
					0.06,
					6,
					0.025,
					IRON,
					"Metal"
				)
			end
			-- the handle, and the pot: round, black iron, a rim, two lugs and three short feet
			K.path(r, {
				Vector3.new(-0.78, 1.95, 0),
				Vector3.new(-0.6, 2.4, 0),
				Vector3.new(0, 2.62, 0),
				Vector3.new(0.6, 2.4, 0),
				Vector3.new(0.78, 1.95, 0),
			}, 0.05, IRON, "Metal")
			local pot = r:ball(0, 1.45, 0, 1.7, r.c1, "Metal")
			pot.size = Vector3.new(1.7, 1.4, 1.7)
			pot.smooth = true
			K.hoop(r, 0, 1.98, 0, 0.66, 16, 0.12, shade(r.c1, 1.15), "Metal")
			for _, sx in { -1, 1 } do
				r:block(sx * 0.82 - 0.06, 1.85, -0.08, sx * 0.82 + 0.06, 2.0, 0.08, r.c1, "Metal")
			end
			-- the soup, its bubbles bobbing in two lots out of step, steam over it
			K.roundSurface(r, 0, 1.96, 0, 1.24, r.c2)
			for g = 1, 2 do
				Lively.pivot(
					r,
					CFrame.new(0, 1.96, 0),
					"bob",
					{ speed = 3.2 + g, amount = 0.04, phase = g * 2.1, group = g }
				)
				Lively.moving(r, g, function()
					for k = 0, 2 do
						local a = k * 2.1 + g * 1.1
						local d = 0.12 + (k % 2) * 0.06
						K.sphere(r, math.cos(a) * 0.36, 1.98, math.sin(a) * 0.36, d, mix(r.c2, CREAM, 0.35), "Glass").transp =
							0.25
					end
				end)
			end
			Lively.fx(r, "simmer", 0, 1.98, 0, { w = 0.9, d = 0.9 })
			Lively.fx(r, "steam", 0, 2.05, 0, { w = 0.6, d = 0.6 })
			-- a ladle resting on the rim
			K.rod(r, Vector3.new(0.3, 1.9, 0.1), Vector3.new(0.85, 2.45, 0.35), 0.06, C.Bark, "Wood")
		end,
	},
	{
		id = "anim_flagpole",
		name = "Flagpole",
		cat = "garden",
		style = "modern",
		price = 300,
		place = "ground",
		size = Vector3.new(4, 12.6, 1.4),
		c1 = "6E9FC2",
		c2 = "F2EEE2",
		lively = true,
		build = function(r: R)
			local x0 = -1.5
			-- a round plinth of stone with a brass plate, the pole set in it
			K.disc(r, x0, 0.2, 0, 0.4, 1.3, STONE, "Concrete")
			K.disc(r, x0, 0.45, 0, 0.1, 0.9, shade(STONE, 0.9), "Concrete")
			r:block(x0 - 0.25, 0.1, 0.63, x0 + 0.25, 0.3, 0.69, C.Gold, "Metal")
			r:cyl(x0, 3.0, 0, 5.1, 0.24, "y", C.Metal, "Metal").smooth = true
			r:cyl(x0, 8.5, 0, 5.9, 0.18, "y", C.Metal, "Metal").smooth = true
			K.sphere(r, x0, 11.62, 0, 0.36, C.Gold, "Metal")
			K.disc(r, x0, 11.42, 0, 0.12, 0.3, C.DarkMetal, "Metal")
			-- the halyard down to a cleat on the pole
			r:noCollide(r:cyl(x0 - 0.16, 6.9, 0, 9.0, 0.03, "y", CREAM, "Fabric"))
			r:block(x0 - 0.24, 2.3, -0.05, x0 - 0.1, 2.6, 0.05, C.DarkMetal, "Metal")
			-- the flag in three strips, each swinging a little further than the one nearer the
			-- pole and a moment later, so it ripples: the paint in a field, a band of the second
			local strips = { { 0.12, 1.0 }, { 1.0, 1.9 }, { 1.9, 2.8 } }
			for g, s in strips do
				Lively.pivot(r, CFrame.new(x0, 10.4, 0), "flutter", {
					speed = 2.2,
					amount = 0.08 + g * 0.06,
					phase = -g * 0.7,
					group = g,
				})
				Lively.moving(r, g, function()
					r:block(x0 + s[1], 9.3, -0.02, x0 + s[2], 11.3, 0.02, r.c1, "Fabric")
					r:block(x0 + s[1], 10.05, -0.05, x0 + s[2], 10.55, 0.05, r.c2, "Fabric")
				end)
			end
			-- the flag's toggle and its clips on the halyard
			for _, y in { 9.4, 11.2 } do
				r:block(x0 + 0.02, y - 0.04, -0.06, x0 + 0.1, y + 0.04, 0.06, C.DarkMetal, "Metal")
			end
		end,
	},
	{
		id = "anim_weather_station",
		name = "Weather station",
		cat = "garden",
		style = "scifi",
		price = 340,
		place = "ground",
		size = Vector3.new(2.4, 6.2, 2.4),
		c1 = "F2F2EE",
		c2 = "6FA8C8",
		lively = true,
		build = function(r: R)
			-- a mast on three splayed feet, guy wires to pegs
			for k = 0, 2 do
				local a = k * math.pi * 2 / 3
				K.rod(
					r,
					Vector3.new(math.cos(a) * 0.9, 0.04, math.sin(a) * 0.9),
					Vector3.new(0, 1.2, 0),
					0.07,
					C.Metal,
					"Metal"
				)
				K.rod(
					r,
					Vector3.new(math.cos(a) * 1.1, 0.02, math.sin(a) * 1.1),
					Vector3.new(0, 3.6, 0),
					0.015,
					C.DarkMetal,
					"Metal"
				)
				r:cyl(math.cos(a) * 1.1, 0.06, math.sin(a) * 1.1, 0.12, 0.08, "y", C.DarkMetal, "Metal")
			end
			r:cyl(0, 2.6, 0, 5.2, 0.12, "y", C.Metal, "Metal").smooth = true
			-- a louvred box for the thermometers, on an arm, with its little roof
			r:block(0.08, 2.15, -0.04, 0.6, 2.25, 0.04, C.Metal, "Metal")
			r:block(0.4, 1.7, -0.32, 1.0, 2.4, 0.32, r.c1, "WoodPlanks")
			for y = 1.78, 2.32, 0.09 do
				r:block(0.98, y, -0.3, 1.03, y + 0.04, 0.3, shade(r.c1, 0.9), "Wood")
			end
			r:block(0.34, 2.4, -0.38, 1.06, 2.48, 0.38, shade(r.c1, 0.85), "WoodPlanks")
			-- a small solar panel facing the sun, and a box of electrics with a blinking light
			local panel = r:block(-0.75, 3.2, -0.3, -0.15, 3.24, 0.3, Color3.fromRGB(46, 70, 110), "Glass")
			panel.cf = CFrame.new(-0.45, 3.22, 0) * CFrame.Angles(0, 0, 0.6)
			r:block(-0.3, 2.9, -0.04, -0.06, 3.0, 0.04, C.Metal, "Metal")
			r:block(-0.36, 1.2, 0.06, 0.0, 1.6, 0.3, C.Metal, "Metal")
			Lively.twinkle(r:glow(r:ball(-0.18, 1.52, 0.31, 0.06, Color3.fromRGB(120, 230, 140), "Glass"), 0))
			-- the wind vane: an arrow with a tail, swinging round with the wind
			local vane = CFrame.new(0, 4.6, 0)
			r:cyl(0, 4.55, 0, 0.2, 0.18, "y", C.DarkMetal, "Metal")
			Lively.pivot(r, vane, "flutter", { speed = 0.6, amount = 0.6, group = 2 })
			Lively.moving(r, 2, function()
				r:block(-0.7, 4.66, -0.02, 0.6, 4.7, 0.02, C.DarkMetal, "Metal")
				r:cone(0.7, 4.68, 0, 0.24, 0.14, r.c2, "Metal").cf = CFrame.new(0.7, 4.68, 0)
					* CFrame.Angles(0, 0, -math.pi / 2)
				r:tri(
					Vector3.new(-0.5, 4.68, 0),
					Vector3.new(-0.9, 4.95, 0),
					Vector3.new(-0.9, 4.42, 0),
					0.03,
					r.c2,
					"Metal"
				)
			end)
			-- the cups on their arms, going round on top
			r:cyl(0, 5.3, 0, 1.2, 0.07, "y", C.Metal, "Metal")
			local cups = CFrame.new(0, 5.9, 0)
			Lively.pivot(r, cups, "spin", { speed = 3.4 })
			Lively.moving(r, 1, function()
				K.disc(r, 0, 5.9, 0, 0.1, 0.16, C.DarkMetal, "Metal")
				for k = 0, 2 do
					local f = cups * CFrame.Angles(0, k * math.pi * 2 / 3, 0)
					r:boxAt(f * CFrame.new(0.3, 0, 0), 0.6, 0.03, 0.03, C.Metal, "Metal")
					local cup = r:ball(0, 0, 0, 0.28, r.c1, "Metal")
					cup.cf = f * CFrame.new(0.62, 0, 0.08)
					cup.size = Vector3.new(0.28, 0.28, 0.2)
					cup.smooth = true
				end
			end)
		end,
	},
	{
		id = "anim_bird_feeder",
		name = "Bird feeder",
		cat = "garden",
		style = "garden",
		price = 90,
		place = "ground",
		size = Vector3.new(2.2, 5.2, 1.6),
		c1 = "A07A54",
		c2 = "7FA6C4",
		lively = true,
		build = function(r: R)
			local wood = r.c1
			-- a post with an arm, the feeder hanging from it on a chain
			r:block(-0.85, 0, -0.12, -0.61, 4.6, 0.12, wood, "Wood")
			r:block(-0.89, 0, -0.16, -0.57, 0.3, 0.16, shade(wood, 0.85), "Wood")
			r:block(-0.9, 4.5, -0.1, 0.5, 4.66, 0.1, wood, "Wood")
			K.rod(r, Vector3.new(-0.73, 3.9, 0), Vector3.new(-0.2, 4.5, 0), 0.08, shade(wood, 0.9), "Wood")
			r:noCollide(r:cyl(0.3, 4.2, 0, 0.6, 0.025, "y", IRON, "Metal"))
			-- a little house: a tray with a lip, four posts, a pitched roof and seed in the tray
			r:block(-0.3, 2.8, -0.55, 0.9, 2.88, 0.55, wood, "WoodPlanks")
			for _, sz in { -1, 1 } do
				r:block(
					-0.3,
					2.88,
					sz * 0.55 - (if sz > 0 then 0.05 else 0),
					0.9,
					2.96,
					sz * 0.55 + (if sz < 0 then 0.05 else 0),
					shade(wood, 0.85),
					"Wood"
				)
			end
			for _, sx in { -0.24, 0.84 } do
				for _, sz in { -0.48, 0.48 } do
					r:cyl(sx, 3.22, sz, 0.66, 0.06, "y", shade(wood, 0.85), "Wood")
				end
			end
			r:block(-0.16, 2.88, -0.4, 0.76, 2.94, 0.4, Color3.fromRGB(196, 166, 110), "Sand")
			for _, sz in { -1, 1 } do
				local roof = r:block(-0.4, 3.55, 0, 1.0, 3.62, 0.72, r.c2, "WoodPlanks")
				roof.cf = CFrame.new(0.3, 3.73, sz * 0.32) * CFrame.Angles(sz * 0.55, 0, 0)
				roof.size = Vector3.new(1.4, 0.07, 0.78)
			end
			r:block(0.25, 3.94, -0.05, 0.35, 4.0, 0.05, IRON, "Metal")
			-- two birds on the tray's edge, each pecking at the seed in its own time
			for g, b in
				{
					{
						x = -0.05,
						z = 0.45,
						col = Color3.fromRGB(110, 140, 190),
						breast = Color3.fromRGB(232, 150, 110),
					},
					{ x = 0.6, z = -0.45, col = Color3.fromRGB(150, 124, 96), breast = CREAM },
				}
			do
				local foot = CFrame.new(b.x, 2.96, b.z) * CFrame.Angles(0, if b.z > 0 then math.pi else 0, 0)
				Lively.pivot(r, foot, "swing", { speed = 3.4 + g, amount = 0.35, axis = "X", phase = g * 2, group = g })
				Lively.moving(r, g, function()
					local from = #r.prims + 1
					bird(r, 0, 0, 0, b.col, b.breast, 0.9)
					for i = from, #r.prims do
						r.prims[i].cf = foot * r.prims[i].cf
					end
				end)
			end
		end,
	},
	{
		id = "anim_lighthouse",
		name = "Garden lighthouse",
		cat = "garden",
		style = "seaside",
		price = 420,
		place = "ground",
		size = Vector3.new(2.6, 7.2, 2.6),
		c1 = "D9666A",
		c2 = "F4F0E6",
		tags = { "light" },
		lively = true,
		build = function(r: R)
			-- rocks round its foot
			for i = 0, 7 do
				local a = i / 8 * math.pi * 2
				local s = 0.5 + (i * 17 % 3) * 0.08
				r:lump(
					CFrame.new(math.cos(a) * 1.0, s * 0.3, math.sin(a) * 1.0) * CFrame.Angles(0, a * 2, 0.2),
					s * 1.3,
					s * 0.8,
					s,
					shade(STONE, 0.85 + (i % 3) * 0.06),
					"Rock"
				)
			end
			-- the tower in bands of the two paints, narrowing up, with a door and two windows
			local y = 0.2
			for i = 0, 4 do
				local d = 1.5 - i * 0.12
				local len = 0.9
				local band = K.disc(r, 0, y + len / 2, 0, len, d, if i % 2 == 0 then r.c2 else r.c1, "Plaster")
				band.size = Vector3.new(len, d, d)
				y += len
			end
			r:block(-0.2, 0.24, 0.66, 0.2, 0.95, 0.8, C.Bark, "WoodPlanks")
			r:block(-0.26, 0.95, 0.64, 0.26, 1.02, 0.84, shade(r.c2, 0.85), "Wood")
			for _, w in { { 2.15, 0.58, 0.67 }, { 3.35, 0.52, 0.61 } } do
				r:block(-0.1, w[1], w[2], 0.1, w[1] + 0.3, w[3], INK, "Glass")
			end
			-- the gallery: a deck, a railing of posts and a rail round it
			K.disc(r, 0, y + 0.06, 0, 0.12, 1.5, shade(r.c2, 0.9), "Metal")
			for k = 0, 11 do
				local a = k / 12 * math.pi * 2
				r:cyl(math.cos(a) * 0.68, y + 0.3, math.sin(a) * 0.68, 0.36, 0.04, "y", IRON, "Metal")
			end
			K.hoop(r, 0, y + 0.48, 0, 0.68, 16, 0.05, IRON, "Metal")
			-- the lamp room: a glass drum between two rims, and a domed cap with a vent
			K.disc(r, 0, y + 0.18, 0, 0.12, 1.0, r.c1, "Metal")
			local glass = K.disc(r, 0, y + 0.65, 0, 0.8, 0.9, C.Glass, "Glass")
			glass.transp = 0.55
			glass.collide = false
			K.disc(r, 0, y + 1.1, 0, 0.1, 1.0, r.c1, "Metal")
			local dome = r:ball(0, y + 1.15, 0, 1.0, r.c1, "Metal")
			dome.size = Vector3.new(1.0, 0.8, 1.0)
			dome.smooth = true
			r:cyl(0, y + 1.6, 0, 0.2, 0.12, "y", IRON, "Metal")
			K.sphere(r, 0, y + 1.75, 0, 0.14, C.Gold, "Metal")
			-- the lamp and its two lenses going round, each throwing a beam out across the garden
			local mid = CFrame.new(0, y + 0.65, 0)
			Lively.pivot(r, mid, "spin", { speed = 1.1 })
			Lively.moving(r, 1, function()
				K.disc(r, 0, y + 0.3, 0, 0.1, 0.36, C.DarkMetal, "Metal")
				local bulb = K.sphere(r, 0, y + 0.65, 0, 0.3, C.Warm, "Glass")
				r:glow(bulb, 8, 0.8)
				for _, sz in { -1, 1 } do
					local lens = r:cyl(0, y + 0.65, sz * 0.26, 0.06, 0.34, "z", Color3.fromRGB(255, 236, 190), "Glass")
					lens.smooth = true
					r:glow(lens, 22, 1.4)
					local light = lens.light :: any
					light.kind = "spot"
					light.face = if sz > 0 then "Left" else "Right" -- (the lens runs along its own X, which points to -Z)
				end
			end)
		end,
	},
	{
		id = "anim_street_clock",
		name = "Street clock",
		cat = "garden",
		style = "fancy",
		price = 520,
		place = "ground",
		size = Vector3.new(2, 9.2, 1.6),
		c1 = "3E5A4E",
		c2 = "F4EEDC",
		tags = { "clock" },
		lively = true,
		build = function(r: R)
			local iron = r.c1
			local trim = C.Gold
			-- a stepped base, a fluted column with collars, and a capital the clock sits on
			r:bevel(-0.6, 0, -0.6, 0.6, 0.3, 0.6, 0.08, STONE, "Granite", { wear = 0.94 })
			r:bevel(-0.45, 0.3, -0.45, 0.45, 0.7, 0.45, 0.08, iron, "Metal", { wear = 1.06 })
			r:bevel(-0.5, 0.7, -0.5, 0.5, 0.8, 0.5, 0.035, shade(iron, 1.15), "Metal", { wear = 1.06 })
			r:cyl(0, 3.6, 0, 5.6, 0.36, "y", iron, "Metal").smooth = true
			for k = 0, 7 do
				local a = k * math.pi / 4
				r:block(
					math.cos(a) * 0.19 - 0.025,
					1.4,
					math.sin(a) * 0.19 - 0.025,
					math.cos(a) * 0.19 + 0.025,
					5.8,
					math.sin(a) * 0.19 + 0.025,
					shade(iron, 0.85),
					"Metal"
				)
			end
			for _, h in { 1.2, 3.6, 6.2 } do
				K.disc(r, 0, h, 0, 0.14, 0.5, trim, "Metal")
			end
			K.disc(r, 0, 6.55, 0, 0.5, 0.6, iron, "Metal")
			-- the drum: a round case with a face front and back, rims of gold and a finial
			local cy = 7.55
			local case = K.face(r, 0, cy, 0, 0.6, 1.8, iron, "Metal")
			case.size = Vector3.new(0.6, 1.8, 1.8)
			for _, sz in { -1, 1 } do
				K.face(r, 0, cy, sz * 0.32, 0.04, 1.66, trim, "Metal")
				K.face(r, 0, cy, sz * 0.37, 0.03, 1.5, r.c2, "Marble")
				local zz = sz * 0.405
				for i = 0, 11 do
					local a = i * math.pi / 6
					local long = i % 3 == 0
					r:boxAt(
						CFrame.new(0, cy, zz) * CFrame.Angles(0, 0, -a) * CFrame.new(0, 0.6, 0),
						if long then 0.06 else 0.035,
						if long then 0.16 else 0.1,
						0.02,
						INK,
						"Metal"
					)
				end
			end
			K.sphere(r, 0, cy + 1.0, 0, 0.28, trim, "Metal")
			r:cone(0, cy + 1.3, 0, 0.36, 0.12, trim, "Metal")
			-- the hands: the front's turn the usual way, the back's (seen from behind) the other
			K.hands(r, 0, cy, 0.43, 0.62, INK, { 1, 2 })
			local back = CFrame.new(0, cy, -0.43) * CFrame.Angles(0, math.pi, 0)
			Lively.pivot(r, back, "hour", { axis = "Z", speed = -1, group = 3 })
			Lively.moving(r, 3, function()
				r:boxAt(back * CFrame.new(0, 0.19, 0.02), 0.056, 0.38, 0.025, INK, "Metal")
			end)
			Lively.pivot(r, back, "minute", { axis = "Z", speed = -1, group = 4 })
			Lively.moving(r, 4, function()
				r:boxAt(back * CFrame.new(0, 0.26, 0.045), 0.037, 0.56, 0.025, INK, "Metal")
			end)
		end,
	},
	{
		id = "anim_bee_skep",
		name = "Bee skep",
		cat = "garden",
		style = "garden",
		price = 140,
		place = "ground",
		size = Vector3.new(2.4, 3.2, 2.4),
		c1 = "D6B878",
		c2 = "8C6A4A",
		lively = true,
		gives = "honey",
		build = function(r: R)
			-- a little stool of a stand, and the skep of coiled straw on it, narrowing to the top
			local stand = r.c2
			r:bevel(-0.6, 0.9, -0.6, 0.6, 1.02, 0.6, 0.042, stand, "WoodPlanks", { wear = 1.06 })
			for _, sx in { -1, 1 } do
				for _, sz in { -1, 1 } do
					r:block(
						sx * 0.48 - 0.06,
						0,
						sz * 0.48 - 0.06,
						sx * 0.48 + 0.06,
						0.9,
						sz * 0.48 + 0.06,
						shade(stand, 0.85),
						"Wood"
					)
				end
			end
			for k = 0, 6 do
				local rad = 0.5 - (k / 6) ^ 2 * 0.36
				K.hoop(r, 0, 1.1 + k * 0.17, 0, rad, 14, 0.2, if k % 2 == 0 then r.c1 else shade(r.c1, 0.9), "Fabric")
				local fill = K.disc(r, 0, 1.1 + k * 0.17, 0, 0.17, rad * 2, shade(r.c1, 0.85), "Fabric")
				fill.collide = false
			end
			K.sphere(r, 0, 2.2, 0, 0.24, shade(r.c1, 0.9), "Fabric")
			-- its doorway and a little landing board
			r:block(-0.14, 1.04, 0.36, 0.14, 1.2, 0.5, INK, "Wood")
			r:block(-0.2, 1.02, 0.44, 0.2, 1.06, 0.66, stand, "Wood")
			-- flowers round the stand for them
			for i, p in { { -0.95, 0.7 }, { 0.9, 0.8 }, { -0.8, -0.85 }, { 0.95, -0.7 } } do
				r:noCollide(r:cyl(p[1], 0.3, p[2], 0.6, 0.05, "y", C.DarkLeaf, "Grass"))
				r:lump(CFrame.new(p[1], 0.18, p[2]) * CFrame.Angles(0, i, 0), 0.4, 0.26, 0.4, C.Leaf, "Grass")
				for k = 0, 4 do
					local a = k * math.pi * 2 / 5 + i
					r:lump(
						CFrame.new(p[1] + math.cos(a) * 0.08, 0.62, p[2] + math.sin(a) * 0.08)
							* CFrame.Angles(0, -a, 0.3),
						0.12,
						0.04,
						0.08,
						if i % 2 == 0 then Color3.fromRGB(190, 160, 230) else CREAM,
						"Fabric"
					)
				end
				r:ball(p[1], 0.64, p[2], 0.06, C.Yellow, "Fabric")
			end
			-- bees in two little clouds, wandering between the skep and the flowers
			for g, at in { Vector3.new(0.5, 1.6, 0.6), Vector3.new(-0.5, 1.4, -0.3) } do
				Lively.pivot(r, CFrame.new(at), "drift", { speed = 0.9 + g * 0.2, amount = 0.9, group = g, phase = g })
				Lively.moving(r, g, function()
					for k = 1, 3 do
						local a = k * 2.2 + g
						local p = at + Vector3.new(math.cos(a) * 0.25, (k % 2) * 0.15, math.sin(a) * 0.25)
						local body =
							r:lump(CFrame.new(p) * CFrame.Angles(0, a, 0), 0.07, 0.07, 0.11, C.Yellow, "Fabric")
						body.collide = false
						r:block(
							p.X - 0.036,
							p.Y - 0.036,
							p.Z - 0.012,
							p.X + 0.036,
							p.Y + 0.036,
							p.Z + 0.012,
							INK,
							"Fabric"
						).cf = CFrame.new(
							p
						) * CFrame.Angles(0, a, 0)
						local wing = r:block(
							p.X - 0.06,
							p.Y + 0.04,
							p.Z - 0.02,
							p.X + 0.06,
							p.Y + 0.05,
							p.Z + 0.02,
							CREAM,
							"Glass"
						)
						wing.transp = 0.4
						wing.cf = CFrame.new(p + Vector3.new(0, 0.045, 0)) * CFrame.Angles(0, a + math.pi / 2, 0)
					end
				end)
			end
		end,
	},
	{
		id = "anim_roundabout",
		name = "Roundabout",
		cat = "fun",
		style = "playful",
		price = 380,
		place = "ground",
		size = Vector3.new(5.6, 2.2, 5.6),
		c1 = "E57C6E",
		c2 = "F4CD5C",
		tags = { "toy" },
		lively = true,
		build = function(r: R)
			-- a rubber ring of ground round a low iron drum it turns on
			K.disc(r, 0, 0.04, 0, 0.08, 5.6, Color3.fromRGB(96, 102, 108), "Rubber")
			K.disc(r, 0, 0.16, 0, 0.24, 1.2, IRON, "Metal")
			-- a hidden step, so what turns has something solid to stand on
			local stand = r:cyl(0, 0.33, 0, 0.18, 4.6, "y", C.White, "Metal")
			stand.transp = 1
			-- the deck in painted sectors, the grab bars and the wheel in the middle, going round
			Lively.pivot(r, CFrame.new(0, 0.4, 0), "spin", { speed = 0.6 })
			Lively.moving(r, 1, function()
				K.disc(r, 0, 0.35, 0, 0.12, 4.8, shade(r.c1, 0.85), "Metal")
				for k = 0, 5 do
					local a = k * math.pi / 3
					local sector =
						r:block(-0.42, 0.42, 0.4, 0.42, 0.44, 2.25, if k % 2 == 0 then r.c1 else r.c2, "DiamondPlate")
					-- (every other one a little higher, where two overlap near the middle)
					sector.cf = CFrame.Angles(0, a, 0) * CFrame.new(0, if k % 2 == 0 then 0.43 else 0.465, 1.32)
					sector.size = Vector3.new(1.35, 0.02, 1.85)
					-- a bar from the rim up and in to the wheel
					local rim = CFrame.Angles(0, a + math.pi / 6, 0) * Vector3.new(0, 0.4, 2.2)
					local inner = CFrame.Angles(0, a + math.pi / 6, 0) * Vector3.new(0, 1.5, 0.5)
					K.path(r, { rim, rim + Vector3.new(0, 0.9, 0) - rim.Unit * 0.2, inner }, 0.08, C.Metal, "Metal")
				end
				K.hoop(r, 0, 1.5, 0, 0.5, 12, 0.1, r.c2, "Metal")
				r:cyl(0, 1.05, 0, 1.3, 0.16, "y", C.Metal, "Metal")
				K.sphere(r, 0, 1.75, 0, 0.26, r.c1, "Metal")
			end)
		end,
	},
}

return items
