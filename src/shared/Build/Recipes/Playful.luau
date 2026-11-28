--!strict
-- Playful: bright and fun, for children and anyone who still likes a slide (the user: "there
-- should be many to choose from from different categories, like garden, sci fi, cozy, etc, just
-- like bloxburg"). Big surfaces stay in soft pastels; the strong colours are kept to small things
-- (knobs, crayons, balls, a train). Each piece names `style = "playful"` so Build mode can list the
-- look together. c1 is the main colour and c2 the second, as in the other modules.

local Recipe = require(script.Parent.Parent.Recipe)
local Colors = require(script.Parent.Parent.Parent.Util.Colors)

local C = Recipe.Colors

type R = Recipe.Recipe

-- soft colours for big surfaces
local PINK = Color3.fromRGB(244, 184, 200)
local MINT = Color3.fromRGB(168, 220, 200)
local LILAC = Color3.fromRGB(200, 184, 232)
local BUTTER = Color3.fromRGB(246, 224, 160)
local SKY = Color3.fromRGB(168, 208, 236)
local PEACH = Color3.fromRGB(246, 196, 160)
local SNOW = Color3.fromRGB(248, 246, 240)
local WOOD = Color3.fromRGB(226, 196, 150)
local INK = Color3.fromRGB(64, 56, 66)
-- brighter colours for small things
local RED = Color3.fromRGB(232, 104, 108)
local YELLOW = Color3.fromRGB(246, 200, 76)
local BLUE = Color3.fromRGB(86, 156, 222)
local GREEN = Color3.fromRGB(104, 190, 118)
local ORANGE = Color3.fromRGB(240, 156, 84)
local SHEET = Color3.fromRGB(250, 248, 243)

local BRIGHTS = { RED, YELLOW, BLUE, GREEN, PINK }
local PASTELS = { PINK, BUTTER, MINT, SKY, LILAC, PEACH }

local function shade(c: Color3, k: number): Color3
	return Colors.shade(c, k)
end

local function mix(a: Color3, b: Color3, t: number): Color3
	return Colors.mix(a, b, t)
end

-- Glows at night without a light of its own (when another part of the item already has one).
local function glowOnly(p: Recipe.Prim)
	p.role = "glow"
end

-- A round rod from a to b (a cylinder laid along the line).
local function rod(r: R, a: Vector3, b: Vector3, d: number, color: Color3, mat: string?): Recipe.Prim?
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
		mat = mat or r.mat or "Wood",
	})
end

-- Rods through a list of points, each run a little past its inner ends so the joints close up.
local function path(r: R, pts: { Vector3 }, d: number, color: Color3, mat: string?)
	for i = 1, #pts - 1 do
		local a, b = pts[i], pts[i + 1]
		local u = (b - a).Unit * (d * 0.45)
		rod(r, if i > 1 then a - u else a, if i < #pts - 1 then b + u else b, d, color, mat)
	end
end

-- A flat bar lying in an upright plane facing +z, from p1 to p2 (both at the same z, its
-- middle): `t` across in the plane and `depth` out of it.
local function bar(r: R, p1: Vector3, p2: Vector3, t: number, depth: number, color: Color3, mat: string?)
	local v = p2 - p1
	local len = v.Magnitude
	if len < 1e-3 then
		return
	end
	local x = v / len
	local y = Vector3.zAxis:Cross(x)
	r:boxAt(CFrame.fromMatrix((p1 + p2) / 2, x, y, Vector3.zAxis), len, t, depth, color, mat)
end

-- A filled polygon as a fan of triangles from a middle point (each `thick` through).
local function fan(r: R, mid: Vector3, pts: { Vector3 }, thick: number, color: Color3, mat: string?)
	for i = 1, #pts - 1 do
		r:tri(mid, pts[i], pts[i + 1], thick, color, mat)
	end
end

-- A flat eight pointed star: two squares, one turned a quarter, in the frame's xy plane.
local function star(r: R, cf: CFrame, s: number, thick: number, color: Color3, mat: string?)
	r:boxAt(cf, s, s, thick, color, mat)
	r:boxAt(cf * CFrame.Angles(0, 0, math.pi / 4), s, s, thick, color, mat)
end

-- A cone with its point down.
local function coneDown(r: R, x: number, y: number, z: number, h: number, d: number, color: Color3, mat: string?)
	r:add({
		shape = "Cone",
		cf = CFrame.new(x, y, z) * CFrame.Angles(math.pi, 0, 0),
		size = Vector3.new(d, h, d),
		color = color,
		mat = mat or r.mat or "Wood",
	})
end

-- A cushion from (x1, y1, z1) to (x2, y2, z2) with its front and back edges rounded over.
local function cushion(r: R, x1: number, y1: number, z1: number, x2: number, y2: number, z2: number, color: Color3)
	local h = y2 - y1
	local xm, ym = (x1 + x2) / 2, (y1 + y2) / 2
	r:bevel(x1, y1, z1 + h / 2, x2, y2, z2 - h / 2, 0.1, color, "Fabric", { round = true })
	r:cyl(xm, ym, z1 + h / 2, x2 - x1, h, "x", color, "Fabric")
	r:cyl(xm, ym, z2 - h / 2, x2 - x1, h, "x", color, "Fabric")
end

-- A soft pillow `w` wide whose bottom is at y and whose middle is at z, leaning back a little.
local function pillow(r: R, x: number, y: number, z: number, w: number, color: Color3?)
	local col = color or SHEET
	local cf = CFrame.new(x, y + 0.22, z) * CFrame.Angles(-0.18, 0, 0)
	r:boxAt(cf, w, 0.44, 0.62, col, "Fabric")
	for _, s in { -1, 1 } do
		r:add({
			shape = "Cylinder",
			cf = cf * CFrame.new(0, 0, s * 0.31),
			size = Vector3.new(w, 0.44, 0.44),
			color = col,
			mat = "Fabric",
		})
	end
end

-- A mattress from y0 to y1 with a piped edge, and a duvet from zb that hangs over the sides and
-- the foot, its top folded back over the sheet.
local function mattress(
	r: R,
	x1: number,
	x2: number,
	z1: number,
	z2: number,
	y0: number,
	y1: number,
	zb: number,
	blanket: Color3
)
	r:block(x1, y0, z1, x2, y1, z2, SHEET, "Fabric")
	r:block(x1 - 0.03, y1 - 0.1, z1 - 0.03, x2 + 0.03, y1 - 0.05, z2 + 0.03, shade(SHEET, 0.86), "Fabric")
	local fold = mix(blanket, C.White, 0.3)
	r:block(x1 - 0.08, y1 - 0.5, zb + 0.3, x2 + 0.08, y1 + 0.12, z2 + 0.08, blanket, "Fabric")
	r:block(x1 - 0.12, y1 - 0.46, zb, x2 + 0.12, y1 + 0.2, zb + 0.4, fold, "Fabric")
	r:cyl((x1 + x2) / 2, y1 + 0.05, zb, x2 - x1 + 0.24, 0.3, "x", fold, "Fabric")
end

-- Little stars scattered on a duvet whose top is at y.
local function starsOn(r: R, y: number, pts: { { number } })
	for _, p in pts do
		r:boxAt(CFrame.new(p[1], y + 0.015, p[2]) * CFrame.Angles(0, 0.6, 0), 0.28, 0.03, 0.28, YELLOW, "Fabric")
	end
end

-- One catalog entry (Build/Catalog explains the fields).
type Item = {
	id: string,
	name: string,
	cat: string,
	style: string,
	price: number,
	place: string,
	size: Vector3,
	c1: string,
	c2: string?,
	tags: { string }?,
	surface: number?,
	build: (r: R) -> (),
	gives: string?, -- holding E gives the player something (Data/Items.Sources)
}

local items: { Item } = {
	------------------------------------------------------------------------------------------
	-- Seating
	{
		id = "play_stool_toadstool",
		name = "Toadstool stool",
		cat = "seating",
		style = "playful",
		price = 50,
		place = "floor",
		size = Vector3.new(1.8, 1.9, 1.8),
		c1 = "E88A8A",
		c2 = "F4ECDD",
		tags = { "seat" },
		build = function(r: R)
			-- a stem with a little door and a round window, a frill under the cap
			r:cyl(0, 0.08, 0, 0.16, 1.0, "y", shade(r.c2, 0.92), "Wood")
			r:cyl(0, 0.78, 0, 1.24, 0.8, "y", r.c2, "Wood")
			r:cyl(0, 1.08, 0, 0.08, 0.96, "y", shade(r.c2, 0.95), "Wood")
			r:block(-0.14, 0.16, 0.4, 0.14, 0.5, 0.44, WOOD, "Wood")
			r:cyl(0, 0.5, 0.42, 0.04, 0.28, "z", WOOD, "Wood")
			r:ball(0.08, 0.34, 0.45, 0.05, YELLOW, "Metal")
			r:cyl(0, 0.78, 0.42, 0.04, 0.2, "z", SKY, "Glass")
			-- the cap: gills underneath, a band and a dome with white spots
			r:cyl(0, 1.42, 0, 0.04, 1.5, "y", Color3.fromRGB(236, 214, 190), "Wood")
			r:cyl(0, 1.54, 0, 0.2, 1.74, "y", r.c1, "Wood")
			r:lump(CFrame.new(0, 1.64, 0), 1.7, 0.5, 1.7, r.c1, "Wood")
			r:ball(0, 1.88, 0, 0.24, SNOW, "Wood")
			for i = 0, 4 do
				local a = i * math.pi * 2 / 5 + 0.4
				r:ball(math.cos(a) * 0.55, 1.83, math.sin(a) * 0.55, 0.2, SNOW, "Wood")
			end
			for i = 0, 3 do
				local a = i * math.pi / 2 + 0.9
				r:lump(CFrame.new(math.cos(a) * 0.86, 1.56, math.sin(a) * 0.86), 0.14, 0.14, 0.14, SNOW, "Wood")
			end
			-- a few blades of grass round the foot
			r:piece(function(q: R)
				q:box(0.5, 0.1, 0.2, 0.06, 0.2, 0.06, C.Leaf, "Grass")
				for i, a in { 0.3, 1.9, 3.4, 4.6 } do
					local x, z = math.cos(a) * 0.55, math.sin(a) * 0.55
					q:boxAt(
						CFrame.new(x, 0.14, z) * CFrame.Angles(0, -a, 0.3 * (i % 2 * 2 - 1)),
						0.06,
						0.26,
						0.06,
						C.Leaf,
						"Grass"
					)
				end
			end, nil, "Grass")
			r:seat(0, 1.88, 0)
		end,
	},
	{
		id = "play_beanbag_bear",
		name = "Bear bean bag",
		cat = "seating",
		style = "playful",
		price = 90,
		place = "floor",
		size = Vector3.new(3.2, 3.2, 3.0),
		c1 = "D9B48C",
		c2 = "F4E2CC",
		tags = { "seat", "toy" },
		build = function(r: R)
			-- a soft base, a low lump to sit in and the bear's head behind
			r:cyl(0, 0.35, 0, 0.7, 2.9, "y", shade(r.c1, 0.92), "Fabric")
			r:lump(CFrame.new(0, 0.85, 0.3), 2.6, 1.0, 2.2, r.c1, "Fabric")
			r:lump(CFrame.new(0, 1.85, -0.6), 2.4, 2.2, 1.6, shade(r.c1, 1.03), "Fabric")
			-- round ears with pale insides
			for _, sx in { -1, 1 } do
				r:ball(sx * 0.85, 2.85, -0.7, 0.7, r.c1, "Fabric")
				r:cyl(sx * 0.85, 2.85, -0.33, 0.05, 0.4, "z", r.c2, "Fabric")
			end
			-- the face: a muzzle, a nose, eyes and pink cheeks
			r:lump(CFrame.new(0, 1.72, 0.18), 0.8, 0.55, 0.3, r.c2, "Fabric")
			r:ball(0, 1.86, 0.32, 0.2, INK, "Fabric")
			r:block(-0.02, 1.58, 0.3, 0.02, 1.74, 0.34, INK, "Fabric")
			for _, sx in { -1, 1 } do
				r:ball(sx * 0.38, 2.15, 0.13, 0.16, INK, "Fabric")
				r:lump(CFrame.new(sx * 0.62, 1.82, 0.03), 0.24, 0.14, 0.1, PINK, "Fabric")
			end
			-- two paws in front with pads
			for _, sx in { -1, 1 } do
				r:lump(CFrame.new(sx * 0.9, 0.55, 1.15), 0.6, 0.4, 0.7, r.c1, "Fabric")
				r:cyl(sx * 0.9, 0.55, 1.51, 0.04, 0.34, "z", r.c2, "Fabric")
			end
			r:seat(0, 1.35, 0.4)
		end,
	},
	{
		id = "play_swing_seat",
		name = "Hoop swing seat",
		cat = "seating",
		style = "playful",
		price = 160,
		place = "floor",
		size = Vector3.new(3.4, 6.4, 3.4),
		c1 = "A8D0EC",
		c2 = "F4ECDD",
		tags = { "seat" },
		build = function(r: R)
			local metal = shade(r.c2, 0.9)
			-- a round foot and a pole that curves over to hang the seat
			r:cyl(0, 0.06, 0, 0.12, 2.8, "y", metal, "Metal")
			path(r, {
				Vector3.new(0, 0.12, -1.2),
				Vector3.new(0, 2.5, -1.45),
				Vector3.new(0, 5.0, -1.4),
				Vector3.new(0, 5.9, -1.0),
				Vector3.new(0, 6.2, -0.35),
				Vector3.new(0, 6.15, 0),
			}, 0.16, metal, "Metal")
			rod(r, Vector3.new(0, 6.08, 0), Vector3.new(0, 5.2, 0), 0.05, C.DarkMetal, "Metal")
			r:ball(0, 5.18, 0, 0.14, C.DarkMetal, "Metal")
			-- the seat hoop and the back hoop over it, on three ropes
			local ring: { Vector3 } = {}
			for i = 0, 12 do
				local a = i * math.pi / 6
				table.insert(ring, Vector3.new(math.cos(a) * 1.1, 1.4, math.sin(a) * 1.1))
			end
			path(r, ring, 0.12, r.c2, "Wood")
			local hoop: { Vector3 } = {}
			for i = 0, 8 do
				local t = i * math.pi / 8
				table.insert(hoop, Vector3.new(math.cos(t) * 1.1, 1.4 + math.sin(t) * 1.5, -math.sin(t) * 0.72))
			end
			path(r, hoop, 0.1, r.c2, "Wood")
			local rope = Color3.fromRGB(222, 206, 178)
			rod(r, Vector3.new(0, 5.18, 0), Vector3.new(0, 2.9, -0.72), 0.04, rope, "Fabric")
			for _, sx in { -1, 1 } do
				rod(r, Vector3.new(0, 5.18, 0), Vector3.new(sx * 0.75, 1.42, 0.8), 0.04, rope, "Fabric")
			end
			-- a woven bottom, a round cushion, a back cushion and a little pillow
			r:cyl(0, 1.38, 0, 0.08, 2.1, "y", WOOD, "Fabric")
			r:cyl(0, 1.52, 0, 0.2, 1.9, "y", r.c1, "Fabric")
			r:lump(CFrame.new(0, 1.62, 0), 1.86, 0.22, 1.86, r.c1, "Fabric")
			r:lump(
				CFrame.new(0, 2.35, -0.5) * CFrame.Angles(-0.35, 0, 0),
				1.6,
				1.3,
				0.4,
				mix(r.c1, C.White, 0.4),
				"Fabric"
			)
			r:cyl(0.45, 2.0, -0.18, 0.26, 0.6, "z", PINK, "Fabric")
			r:ball(0.45, 2.0, -0.04, 0.12, shade(PINK, 0.85), "Fabric")
			-- tassels round the hoop
			for i = 0, 5 do
				local a = i * math.pi / 3 + math.pi / 6
				local x, z = math.cos(a) * 1.1, math.sin(a) * 1.1
				rod(r, Vector3.new(x, 1.36, z), Vector3.new(x, 1.18, z), 0.03, rope, "Fabric")
				r:ball(x, 1.12, z, 0.14, PASTELS[i % #PASTELS + 1], "Fabric")
			end
			r:seat(0, 1.73, 0.15)
		end,
	},
	{
		id = "play_sofa_cloud",
		name = "Cloud sofa",
		cat = "seating",
		style = "playful",
		price = 300,
		place = "floor",
		size = Vector3.new(6.8, 3.6, 3.0),
		c1 = "F2EEF8",
		c2 = "C8B8E8",
		tags = { "seat" },
		build = function(r: R)
			-- round feet under a soft base
			for _, x in { -2.5, 2.5 } do
				for _, z in { -0.95, 0.95 } do
					r:cyl(x, 0.16, z, 0.32, 0.4, "y", r.c2, "Fabric")
				end
			end
			cushion(r, -2.8, 0.32, -1.2, 2.8, 1.0, 1.25, r.c1)
			-- three soft seat cushions
			for _, x in { -1.85, 0, 1.85 } do
				cushion(r, x - 0.9, 1.0, -0.75, x + 0.9, 1.47, 1.2, shade(r.c1, 1.02))
			end
			-- the back is a cloud of round puffs, the arms smaller ones
			for _, b in
				{
					{ -2.35, 1.95, -0.92, 1.5 },
					{ -1.25, 2.35, -0.95, 1.8 },
					{ 0, 2.55, -1.0, 2.0 },
					{ 1.25, 2.3, -0.95, 1.8 },
					{ 2.35, 1.9, -0.92, 1.5 },
					{ -0.7, 3.0, -1.05, 1.1 },
					{ 0.72, 2.95, -1.05, 1.05 },
				}
			do
				r:cyl(b[1], b[2], b[3], 0.9, b[4], "z", r.c1, "Fabric")
			end
			for _, sx in { -1, 1 } do
				r:cyl(sx * 2.85, 1.5, 0.1, 2.1, 1.1, "z", r.c1, "Fabric")
				r:cyl(sx * 2.78, 1.55, 0.9, 0.7, 0.9, "z", r.c1, "Fabric")
			end
			-- a star cushion and a round one
			star(r, CFrame.new(-1.3, 1.95, -0.25) * CFrame.Angles(-0.3, 0, 0.2), 0.7, 0.24, BUTTER, "Fabric")
			r:cyl(1.4, 1.9, -0.25, 0.3, 0.8, "z", PINK, "Fabric")
			r:cyl(1.4, 1.9, -0.08, 0.05, 0.3, "z", shade(PINK, 0.85), "Fabric")
			for _, x in { -1.85, 0, 1.85 } do
				r:seat(x, 1.47, 0.3)
			end
		end,
	},

	------------------------------------------------------------------------------------------
	-- Beds
	{
		id = "play_bed_rocket",
		name = "Rocket bed",
		cat = "beds",
		style = "playful",
		price = 420,
		place = "floor",
		size = Vector3.new(4.4, 4.0, 8.8),
		c1 = "E8ECF0",
		c2 = "F09A9A",
		tags = { "bed", "toy" },
		build = function(r: R)
			-- the body: a base, side panels with a rounded foot, a stripe and portholes
			r:block(-1.7, 0.25, -3.6, 1.7, 1.0, 2.9, shade(r.c1, 0.9), "Wood")
			for _, sx in { -1, 1 } do
				local x1, x2 = sx * 1.7, sx * 1.9
				r:block(math.min(x1, x2), 0.3, -3.6, math.max(x1, x2), 2.1, 2.9, r.c1, "Wood")
				r:cyl(sx * 1.78, 0.42, -0.35, 6.6, 0.46, "z", r.c1, "Wood")
				r:cyl(sx * 1.8, 2.12, -0.35, 6.6, 0.26, "z", r.c2, "Wood")
				local s1, s2 = sx * 1.9, sx * 1.93
				r:block(math.min(s1, s2), 0.75, -3.4, math.max(s1, s2), 0.97, 2.7, r.c2, "Wood")
				for _, z in { -1.7, 0.7 } do
					r:cyl(sx * 1.93, 1.5, z, 0.06, 0.8, "x", C.Metal, "Metal")
					r:cyl(sx * 1.96, 1.5, z, 0.06, 0.56, "x", SKY, "Glass")
				end
				-- fins at the tail end
				r:tri(
					Vector3.new(sx * 2.05, 0.05, -3.9),
					Vector3.new(sx * 2.05, 0.05, -2.2),
					Vector3.new(sx * 2.05, 2.4, -3.75),
					0.18,
					r.c2,
					"Wood"
				)
			end
			-- the tail is the headboard: a round plate in rings with a window, engines behind
			r:cyl(0, 1.95, -3.75, 0.3, 3.9, "z", r.c1, "Wood")
			r:cyl(0, 1.95, -3.57, 0.06, 3.3, "z", r.c2, "Wood")
			r:cyl(0, 1.95, -3.525, 0.05, 2.8, "z", shade(r.c1, 1.02), "Wood")
			r:cyl(0, 2.6, -3.48, 0.05, 1.1, "z", C.Metal, "Metal")
			r:cyl(0, 2.6, -3.45, 0.05, 0.8, "z", SKY, "Glass")
			for _, x in { -0.8, 0.8 } do
				r:add({
					shape = "Cone",
					cf = CFrame.new(x, 0.95, -4.15) * CFrame.Angles(math.pi / 2, 0, 0),
					size = Vector3.new(0.9, 0.5, 0.9),
					color = C.Metal,
					mat = "Metal",
				})
				r:cyl(x, 0.95, -3.95, 0.12, 0.5, "z", C.DarkMetal, "Metal")
			end
			-- the nose is the footboard
			r:cyl(0, 1.4, 3.0, 0.2, 3.1, "z", r.c1, "Wood")
			r:add({
				shape = "Cone",
				cf = CFrame.new(0, 1.4, 3.85) * CFrame.Angles(math.pi / 2, 0, 0),
				size = Vector3.new(2.8, 1.5, 2.8),
				color = r.c2,
				mat = "Wood",
			})
			-- the bed: a starry duvet and a pillow
			mattress(r, -1.65, 1.65, -3.45, 2.85, 1.0, 1.65, -1.6, Color3.fromRGB(150, 172, 222))
			starsOn(r, 1.77, { { -0.8, -0.4 }, { 0.6, 0.3 }, { -0.3, 1.2 }, { 0.9, 1.9 }, { -0.9, 2.3 } })
			pillow(r, 0, 1.65, -3.0, 2.4)
			r:sleep(0, 1.65, -0.2)
		end,
	},
	{
		id = "play_bunk_tent",
		name = "Tent bunk bed",
		cat = "beds",
		style = "playful",
		price = 520,
		place = "floor",
		size = Vector3.new(4.0, 7.8, 7.2),
		c1 = "F4ECDD",
		c2 = "A8DCC8",
		tags = { "bed" },
		build = function(r: R)
			-- four posts up to the eaves
			for _, sx in { -1, 1 } do
				for _, sz in { -1, 1 } do
					r:box(sx * 1.8, 2.6, sz * 3.35, 0.3, 5.2, 0.3, r.c1, "Wood")
				end
			end
			-- two bunks, each with a base, rails and panels at the ends
			for k, y in { 0.5, 3.6 } do
				r:bevel(-1.7, y + 0.1, -3.25, 1.7, y + 0.25, 3.25, 0.052, shade(r.c1, 0.9), "Wood", { wear = 1.06 })
				for _, sx in { -1, 1 } do
					local x1, x2 = sx * 1.68, sx * 1.9
					r:block(math.min(x1, x2), y, -3.2, math.max(x1, x2), y + 0.35, 3.2, r.c1, "Wood")
				end
				for _, sz in { -1, 1 } do
					local z1, z2 = sz * 3.28, sz * 3.42
					r:block(-1.65, y, math.min(z1, z2), 1.65, y + 1.0, math.max(z1, z2), r.c1, "Wood")
				end
				local blanket = if k == 1 then PINK else LILAC
				mattress(r, -1.6, 1.6, -3.2, 3.2, y + 0.25, y + 0.85, -1.4, blanket)
				pillow(r, 0, y + 0.85, -2.65, 2.2)
				r:sleep(0, y + 0.85, 0.2)
			end
			starsOn(r, 1.47, { { -0.7, 0.2 }, { 0.6, 1.5 }, { -0.2, 2.4 } })
			-- guard rails round the top bunk, open where the ladder comes up
			r:block(-1.9, 4.6, -3.2, -1.7, 4.78, 3.2, r.c1, "Wood")
			r:block(1.7, 4.6, -3.2, 1.9, 4.78, 1.5, r.c1, "Wood")
			r:block(1.7, 4.6, 2.7, 1.9, 4.78, 3.2, r.c1, "Wood")
			for _, z in { -2.0, -0.6, 0.8 } do
				r:block(1.74, 3.95, z - 0.08, 1.86, 4.6, z + 0.08, r.c1, "Wood")
				r:block(-1.86, 3.95, z - 0.08, -1.74, 4.6, z + 0.08, r.c1, "Wood")
			end
			-- the ladder
			for _, z in { 1.62, 2.58 } do
				r:block(1.92, 0, z - 0.07, 2.04, 4.9, z + 0.07, r.c1, "Wood")
			end
			for i = 1, 5 do
				rod(
					r,
					Vector3.new(1.98, i * 0.85, 1.62),
					Vector3.new(1.98, i * 0.85, 2.58),
					0.1,
					shade(r.c1, 0.9),
					"Wood"
				)
			end
			-- a tent over the top: a ridge pole, striped sides, a window at the head, door flaps
			-- tied back at the foot
			rod(r, Vector3.new(0, 7.58, -3.5), Vector3.new(0, 7.58, 3.5), 0.14, r.c1, "Wood")
			for _, sx in { -1, 1 } do
				r:quad(
					Vector3.new(sx * 1.92, 5.15, -3.45),
					Vector3.new(sx * 1.92, 5.15, 3.45),
					Vector3.new(0, 7.52, 3.45),
					Vector3.new(0, 7.52, -3.45),
					0.06,
					r.c2,
					"Fabric"
				)
				local n = Vector3.new(sx * 2.37, 1.92, 0).Unit
				local mid = Vector3.new(sx * 0.96, 6.335, 0) + n * 0.08
				for _, z in { -2.6, -0.9, 0.8, 2.5 } do
					r:boxAt(
						CFrame.fromMatrix(mid + Vector3.new(0, 0, z), Vector3.zAxis, n, Vector3.zAxis:Cross(n)),
						0.75,
						0.04,
						2.9,
						SNOW,
						"Fabric"
					)
				end
				-- door flaps
				r:tri(
					Vector3.new(sx * 1.92, 5.15, 3.45),
					Vector3.new(sx * 0.9, 5.15, 3.45),
					Vector3.new(0, 7.52, 3.45),
					0.06,
					shade(r.c2, 0.92),
					"Fabric"
				)
				r:ball(sx * 0.62, 5.75, 3.5, 0.16, PINK, "Fabric")
				-- bunting along the eaves
				if sx > 0 then
					for i = 0, 6 do
						local z = -2.85 + i * 0.95
						r:tri(
							Vector3.new(1.97, 5.12, z - 0.26),
							Vector3.new(1.97, 5.12, z + 0.26),
							Vector3.new(1.97, 4.72, z),
							0.03,
							PASTELS[i % #PASTELS + 1],
							"Fabric"
						)
					end
				end
			end
			r:tri(
				Vector3.new(-1.92, 5.15, -3.45),
				Vector3.new(1.92, 5.15, -3.45),
				Vector3.new(0, 7.52, -3.45),
				0.06,
				shade(r.c2, 0.92),
				"Fabric"
			)
			r:cyl(0, 6.0, -3.5, 0.04, 0.7, "z", SNOW, "Fabric")
			r:cyl(0, 6.0, -3.53, 0.04, 0.5, "z", SKY, "Fabric")
			-- a pennant on the ridge
			rod(r, Vector3.new(0, 7.58, 3.4), Vector3.new(0, 7.75, 3.4), 0.05, r.c1, "Wood")
		end,
	},

	------------------------------------------------------------------------------------------
	-- Storage
	{
		id = "play_shelf_rainbow",
		name = "Rainbow shelf",
		cat = "storage",
		style = "playful",
		price = 120,
		place = "floor",
		size = Vector3.new(4.4, 2.6, 1.2),
		c1 = "F4B8C8",
		c2 = "F4ECDD",
		tags = { "books", "storage" },
		build = function(r: R)
			r:bevel(-2.2, 0, -0.55, 2.2, 0.15, 0.55, 0.052, r.c2, "Wood", { wear = 1.06 })
			-- three bands of the rainbow, each an arch of short bars
			local bands: { { rad: number, n: number, col: Color3 } } = {
				{ rad = 1.9, n = 8, col = r.c1 },
				{ rad = 1.25, n = 6, col = BUTTER },
				{ rad = 0.6, n = 4, col = MINT },
			}
			for k, band in bands do
				local R0, n, col = band.rad, band.n, band.col
				local pts: { Vector3 } = {}
				for i = 0, n do
					local a = i * math.pi / n
					table.insert(pts, Vector3.new(math.cos(a) * R0, 0.15 + math.sin(a) * R0, 0))
				end
				for i = 1, n do
					local a, b = pts[i], pts[i + 1]
					local u = (b - a).Unit * 0.13
					bar(
						r,
						if i > 1 then a - u else a - u * 0.01,
						if i < n then b + u else b,
						0.26,
						1.0 - k * 0.02,
						col,
						"Wood"
					)
				end
			end
			-- books standing in the gaps, a ball and blocks under the little arch
			r:piece(function(q: R)
				local cols = { BLUE, RED, GREEN, YELLOW }
				local i = 0
				for _, gap in { { 1.42, 1.72 }, { 0.77, 1.07 } } do
					for _, sx in { -1, 1 } do
						i += 1
						local x1, x2 = sx * gap[1], sx * gap[2]
						local xa = math.min(x1, x2)
						q:block(xa + 0.02, 0.15, -0.3, xa + 0.13, 0.75 - gap[1] * 0.1, 0.28, cols[i % 4 + 1], "Wood")
						q:block(
							xa + 0.15,
							0.15,
							-0.3,
							xa + 0.27,
							0.68 - gap[1] * 0.1,
							0.28,
							cols[(i + 1) % 4 + 1],
							"Wood"
						)
					end
				end
			end, nil, "Wood")
			r:ball(-0.15, 0.37, 0.1, 0.44, RED, "Wood")
			r:block(0.12, 0.15, -0.15, 0.36, 0.39, 0.09, YELLOW, "Wood")
			r:boxAt(CFrame.new(0.24, 0.51, -0.03) * CFrame.Angles(0, 0.5, 0), 0.22, 0.22, 0.22, BLUE, "Wood")
			-- clouds at the two feet
			for _, sx in { -1, 1 } do
				r:lump(CFrame.new(sx * 2.0, 0.42, 0.42), 0.7, 0.5, 0.36, SNOW, "Wood")
				r:lump(CFrame.new(sx * 1.75, 0.36, 0.45), 0.5, 0.4, 0.3, SNOW, "Wood")
			end
		end,
	},
	{
		id = "play_toy_rack",
		name = "Toy bin rack",
		cat = "storage",
		style = "playful",
		price = 110,
		place = "floor",
		size = Vector3.new(3.6, 3.0, 1.6),
		c1 = "F4ECDD",
		c2 = "A8D0EC",
		tags = { "toy", "storage" },
		build = function(r: R)
			-- two side panels with round tops
			for _, sx in { -1, 1 } do
				local x1, x2 = sx * 1.65, sx * 1.75
				r:block(math.min(x1, x2), 0, -0.7, math.max(x1, x2), 2.3, 0.7, r.c1, "Wood")
				r:cyl(sx * 1.7, 2.3, 0, 0.1, 1.4, "x", r.c1, "Wood")
			end
			-- three tiers of bins leaning forward on rails
			type Bin = { x: number, w: number, col: Color3 }
			local tiers: { { y: number, bins: { Bin } } } = {
				{ y = 0.12, bins = { { x = -0.8, w = 1.5, col = r.c2 }, { x = 0.8, w = 1.5, col = PINK } } },
				{ y = 0.98, bins = { { x = -0.8, w = 1.5, col = MINT }, { x = 0.8, w = 1.5, col = BUTTER } } },
				{
					y = 1.84,
					bins = {
						{ x = -1.08, w = 0.98, col = LILAC },
						{ x = 0, w = 0.98, col = PEACH },
						{ x = 1.08, w = 0.98, col = r.c2 },
					},
				},
			}
			local tops: { CFrame } = {}
			for _, t in tiers do
				local y = t.y
				r:block(-1.65, y, -0.62, 1.65, y + 0.1, -0.5, shade(r.c1, 0.9), "Wood")
				r:block(-1.65, y + 0.12, 0.5, 1.65, y + 0.22, 0.6, shade(r.c1, 0.9), "Wood")
				for _, b in t.bins do
					local x, w, col = b.x, b.w, b.col
					local cf = CFrame.new(x, y + 0.45, -0.02) * CFrame.Angles(0.25, 0, 0)
					r:boxAt(cf, w, 0.62, 1.04, col, "Wood")
					r:boxAt(cf * CFrame.new(0, 0.3, 0.51), w + 0.08, 0.08, 0.1, shade(col, 0.85), "Wood")
					r:add({
						shape = "Cylinder",
						cf = cf * CFrame.new(0, -0.05, 0.53) * CFrame.Angles(0, math.pi / 2, 0),
						size = Vector3.new(0.04, 0.3, 0.3),
						color = SNOW,
						mat = "Wood",
					})
					table.insert(tops, cf * CFrame.new(0, 0.31, 0))
				end
			end
			-- toys poking out of the bins
			local function at(i: number, dx: number, dy: number, dz: number): Vector3
				return (tops[i] * CFrame.new(dx, dy, dz)).Position
			end
			local p = at(1, -0.3, 0.12, 0)
			r:ball(p.X, p.Y, p.Z, 0.5, RED, "Wood")
			p = at(1, 0.35, 0.05, -0.1)
			r:boxAt(CFrame.new(p) * CFrame.Angles(0.3, 0.5, 0), 0.3, 0.3, 0.3, YELLOW, "Wood")
			p = at(2, 0, 0.12, 0)
			r:block(p.X - 0.35, p.Y - 0.1, p.Z - 0.18, p.X + 0.35, p.Y + 0.1, p.Z + 0.18, BLUE, "Wood")
			r:block(p.X - 0.15, p.Y + 0.1, p.Z - 0.15, p.X + 0.15, p.Y + 0.25, p.Z + 0.15, SKY, "Glass")
			for _, dx in { -0.22, 0.22 } do
				r:cyl(p.X + dx, p.Y - 0.1, p.Z, 0.44, 0.16, "z", INK, "Rubber")
			end
			p = at(3, -0.2, 0.15, 0)
			r:ball(p.X, p.Y, p.Z, 0.36, YELLOW, "Wood")
			r:ball(p.X + 0.12, p.Y + 0.24, p.Z + 0.06, 0.24, YELLOW, "Wood")
			r:block(p.X + 0.2, p.Y + 0.2, p.Z + 0.15, p.X + 0.3, p.Y + 0.26, p.Z + 0.25, ORANGE, "Wood")
			p = at(4, 0, 0.1, 0)
			for i, c in { GREEN, RED, BLUE } do
				r:block(
					p.X - 0.45 + i * 0.25,
					p.Y - 0.1,
					p.Z - 0.12,
					p.X - 0.25 + i * 0.25,
					p.Y + 0.1,
					p.Z + 0.08,
					c,
					"Wood"
				)
			end
			p = at(5, 0, 0.08, 0)
			for i, c in { RED, YELLOW, BLUE, GREEN } do
				rod(
					r,
					p + Vector3.new(-0.2 + i * 0.08, -0.1, -0.1),
					p + Vector3.new(-0.22 + i * 0.09, 0.28, 0.05),
					0.07,
					c
				)
			end
			p = at(6, 0, 0.12, 0)
			star(r, CFrame.new(p) * CFrame.Angles(0, 0.4, 0), 0.34, 0.1, YELLOW, "Wood")
			p = at(7, 0, 0.12, 0)
			r:ball(p.X, p.Y, p.Z, 0.36, GREEN, "Wood")
		end,
	},

	------------------------------------------------------------------------------------------
	-- Tables
	{
		id = "play_table_crayon",
		name = "Crayon table",
		cat = "tables",
		style = "playful",
		price = 100,
		place = "floor",
		size = Vector3.new(3.6, 2.2, 2.6),
		c1 = "F6E0A0",
		c2 = "A8D0EC",
		tags = { "table" },
		surface = 1.95,
		build = function(r: R)
			-- four crayon legs standing on their points
			local legs: { { x: number, z: number, col: Color3 } } = {
				{ x = -1.45, z = -0.9, col = RED },
				{ x = 1.45, z = -0.9, col = BLUE },
				{ x = -1.45, z = 0.9, col = GREEN },
				{ x = 1.45, z = 0.9, col = YELLOW },
			}
			for _, l in legs do
				local x, z, col = l.x, l.z, l.col
				coneDown(r, x, 0.15, z, 0.3, 0.3, col)
				r:cyl(x, 0.34, z, 0.08, 0.3, "y", shade(col, 0.9), "Wood")
				r:cyl(x, 0.9, z, 1.04, 0.34, "y", mix(col, C.White, 0.6), "Wood")
				for _, y in { 0.55, 1.28 } do
					r:cyl(x, y, z, 0.06, 0.42, "y", shade(col, 0.8), "Wood")
				end
				r:cyl(x, 1.58, z, 0.34, 0.32, "y", col, "Wood")
			end
			-- the top with a coloured rim standing just proud of it
			r:bevel(-1.75, 1.75, -1.0, 1.75, 1.95, 1.0, 0.07, r.c1, "Wood", { wear = 1.06 })
			r:block(-1.83, 1.72, 1.0, 1.83, 1.98, 1.08, r.c2, "Wood")
			r:block(-1.83, 1.72, -1.08, 1.83, 1.98, -1.0, r.c2, "Wood")
			r:block(-1.83, 1.72, -1.0, -1.75, 1.98, 1.0, r.c2, "Wood")
			r:block(1.75, 1.72, -1.0, 1.83, 1.98, 1.0, r.c2, "Wood")
			-- a drawing on a sheet of paper: a sun, a house and grass
			local y = 1.95
			r:boxAt(CFrame.new(-0.4, y + 0.015, 0.05) * CFrame.Angles(0, 0.12, 0), 1.3, 0.03, 0.95, SNOW, "Wood")
			local sheet = CFrame.new(-0.4, y + 0.045, 0.05) * CFrame.Angles(0, 0.12, 0)
			r:add({
				shape = "Cylinder",
				cf = sheet * CFrame.new(0.38, 0, -0.22) * CFrame.Angles(0, 0, math.pi / 2),
				size = Vector3.new(0.03, 0.26, 0.26),
				color = YELLOW,
				mat = "Wood",
			})
			r:boxAt(sheet * CFrame.new(-0.2, 0, 0.12), 0.32, 0.03, 0.26, RED, "Wood")
			r:tri(
				(sheet * CFrame.new(-0.4, 0, -0.01)).Position,
				(sheet * CFrame.new(0.0, 0, -0.01)).Position,
				(sheet * CFrame.new(-0.2, 0, -0.2)).Position,
				0.03,
				ORANGE,
				"Wood"
			)
			r:boxAt(sheet * CFrame.new(0, 0, 0.36), 1.1, 0.03, 0.08, GREEN, "Wood")
			-- a box of crayons and a few lying out
			r:block(0.65, y, -0.55, 1.15, y + 0.28, -0.3, r.c2, "Wood")
			for i, c in BRIGHTS do
				r:cyl(0.68 + i * 0.08, y + 0.33, -0.42, 0.14, 0.06, "y", c, "Wood")
			end
			for i, p in { { 0.75, 0.3, 0.4 }, { 1.0, 0.55, -0.6 }, { 0.4, 0.65, 1.2 } } do
				local cf = CFrame.new(p[1], y + 0.04, p[2]) * CFrame.Angles(0, p[3], 0)
				r:add({
					shape = "Cylinder",
					cf = cf,
					size = Vector3.new(0.4, 0.08, 0.08),
					color = BRIGHTS[i],
					mat = "Wood",
				})
				r:add({
					shape = "Cone",
					cf = cf * CFrame.new(0.25, 0, 0) * CFrame.Angles(0, 0, -math.pi / 2),
					size = Vector3.new(0.08, 0.1, 0.08),
					color = BRIGHTS[i],
					mat = "Wood",
				})
			end
		end,
	},
	{
		id = "play_table_train",
		name = "Train table",
		cat = "tables",
		style = "playful",
		price = 220,
		place = "floor",
		size = Vector3.new(5.0, 2.6, 3.4),
		c1 = "F4ECDD",
		c2 = "A8DCC8",
		tags = { "table", "toy" },
		build = function(r: R)
			-- the table: legs, a deep top with grass on it and a rim round the edge
			for _, sx in { -1, 1 } do
				for _, sz in { -1, 1 } do
					r:box(sx * 2.2, 0.8, sz * 1.35, 0.3, 1.6, 0.3, r.c1, "Wood")
				end
			end
			r:bevel(-2.4, 1.4, -1.55, 2.4, 1.7, 1.55, 0.08, r.c1, "Wood", { wear = 1.06 })
			r:block(-2.3, 1.7, -1.45, 2.3, 1.74, 1.45, r.c2, "Grass")
			r:block(-2.4, 1.7, 1.45, 2.4, 1.82, 1.55, r.c1, "Wood")
			r:block(-2.4, 1.7, -1.55, 2.4, 1.82, -1.45, r.c1, "Wood")
			r:block(-2.4, 1.7, -1.45, -2.3, 1.82, 1.45, r.c1, "Wood")
			r:block(2.3, 1.7, -1.45, 2.4, 1.82, 1.45, r.c1, "Wood")
			-- a wooden track in a loop, with its two grooves
			local y = 1.77
			local segs: { { Vector3 } } = {}
			for _, sz in { -1, 1 } do
				table.insert(segs, { Vector3.new(-1.1, y, sz * 0.75), Vector3.new(1.1, y, sz * 0.75) })
			end
			for _, sx in { -1, 1 } do
				for i = 0, 5 do
					local a1 = -math.pi / 2 + i * math.pi / 6
					local a2 = a1 + math.pi / 6
					table.insert(segs, {
						Vector3.new(sx * (1.1 + math.cos(a1) * 0.75), y, math.sin(a1) * 0.75),
						Vector3.new(sx * (1.1 + math.cos(a2) * 0.75), y, math.sin(a2) * 0.75),
					})
				end
			end
			r:piece(function(q: R)
				for i, s in segs do
					if i <= 2 then
						q:block(-1.1, y - 0.03, s[1].Z - 0.16, 1.1, y + 0.03, s[1].Z + 0.16, WOOD, "Wood")
					else
						local u = (s[2] - s[1]).Unit * 0.05
						q:beam(s[1] - u, s[2] + u, 0.32, 0.06, WOOD, "Wood")
					end
				end
			end)
			r:piece(function(q: R)
				for i, s in segs do
					if i <= 2 then
						for _, o in { -0.07, 0.07 } do
							q:block(
								-1.1,
								y + 0.03,
								s[1].Z + o - 0.015,
								1.1,
								y + 0.06,
								s[1].Z + o + 0.015,
								shade(WOOD, 0.7),
								"Wood"
							)
						end
					else
						local d = (s[2] - s[1]).Unit
						local side = Vector3.new(-d.Z, 0, d.X)
						for _, o in { -0.07, 0.07 } do
							local lift = Vector3.new(0, 0.045, 0) + side * o
							q:beam(s[1] + lift - d * 0.02, s[2] + lift + d * 0.02, 0.03, 0.03, shade(WOOD, 0.7), "Wood")
						end
					end
				end
			end)
			-- a little engine and two carriages on the front straight
			local ty = y + 0.06
			local z = 0.75
			r:block(0.25, ty + 0.06, z - 0.15, 1.05, ty + 0.16, z + 0.15, INK, "Metal")
			r:cyl(0.83, ty + 0.33, z, 0.5, 0.32, "x", RED, "Wood")
			r:block(0.25, ty + 0.16, z - 0.17, 0.6, ty + 0.58, z + 0.17, BLUE, "Wood")
			r:block(0.2, ty + 0.58, z - 0.2, 0.65, ty + 0.64, z + 0.2, INK, "Metal")
			r:cyl(0.95, ty + 0.58, z, 0.22, 0.12, "y", INK, "Metal")
			for _, x in { 0.4, 0.85, -0.12, -0.48, -0.82, -1.18 } do
				r:cyl(x, ty + 0.1, z, 0.38, 0.2, "z", INK, "Metal")
			end
			for i, x in { -0.3, -1.0 } do
				local col = if i == 1 then YELLOW else GREEN
				r:block(x - 0.3, ty + 0.12, z - 0.15, x + 0.3, ty + 0.42, z + 0.15, col, "Wood")
				r:block(x + 0.3, ty + 0.12, z - 0.03, x + 0.4, ty + 0.18, z + 0.03, INK, "Metal")
			end
			-- a hill with a tunnel over the back straight, trees and a house in the middle
			r:lump(CFrame.new(0, 1.74, -0.75), 1.4, 0.9, 0.9, shade(r.c2, 0.85), "Grass")
			for _, sx in { -1, 1 } do
				r:cyl(sx * 0.72, 1.8, -0.75, 0.05, 0.42, "x", INK, "Metal")
			end
			for _, p in { { -1.9, -1.1 }, { 1.95, 1.1 }, { -0.45, 0.0 }, { 2.0, -1.15 } } do
				r:cyl(p[1], y + 0.08, p[2], 0.16, 0.06, "y", C.Bark, "Wood")
				r:cone(p[1], y + 0.4, p[2], 0.5, 0.36, C.DarkLeaf, "Wood")
			end
			r:block(0.2, y - 0.03, -0.12, 0.6, y + 0.27, 0.18, BUTTER, "Wood")
			r:ramp(0.16, y + 0.27, -0.16, 0.64, y + 0.45, 0.03, true, RED, "Wood")
			r:ramp(0.16, y + 0.27, 0.03, 0.64, y + 0.45, 0.22, false, RED, "Wood")
		end,
	},

	------------------------------------------------------------------------------------------
	-- Kitchen
	{
		id = "play_kitchen",
		name = "Play kitchen",
		cat = "kitchen",
		style = "playful",
		price = 180,
		place = "floor",
		size = Vector3.new(3.4, 4.2, 1.5),
		c1 = "F4ECDD",
		c2 = "A8DCC8",
		tags = { "kitchen", "toy" },
		build = function(r: R)
			for _, sx in { -1, 1 } do
				for _, sz in { -1, 1 } do
					r:cyl(sx * 1.45, 0.05, sz * 0.48, 0.1, 0.18, "y", shade(r.c1, 0.8), "Wood")
				end
			end
			r:block(-1.6, 0.1, -0.6, 1.6, 1.9, 0.6, r.c1, "Wood")
			-- an oven with a round window, a cupboard, knobs and a drawer
			r:block(-1.5, 0.25, 0.6, -0.1, 1.3, 0.64, r.c2, "Wood")
			r:cyl(-0.8, 0.78, 0.66, 0.04, 0.6, "z", INK, "Glass")
			rod(r, Vector3.new(-1.25, 1.18, 0.72), Vector3.new(-0.35, 1.18, 0.72), 0.07, RED)
			for _, x in { -1.25, -0.35 } do
				rod(r, Vector3.new(x, 1.18, 0.64), Vector3.new(x, 1.18, 0.72), 0.05, RED)
			end
			r:block(0.1, 0.25, 0.6, 1.5, 1.3, 0.64, PINK, "Wood")
			r:ball(0.3, 0.8, 0.67, 0.12, YELLOW, "Wood")
			r:block(-1.5, 1.4, 0.6, -0.1, 1.8, 0.64, shade(r.c1, 0.92), "Wood")
			for i, c in { RED, YELLOW, BLUE } do
				local x = -1.45 + i * 0.35
				r:cyl(x, 1.6, 0.7, 0.1, 0.2, "z", c, "Wood")
			end
			r:block(0.1, 1.4, 0.6, 1.5, 1.8, 0.64, BUTTER, "Wood")
			r:ball(0.8, 1.6, 0.67, 0.12, BLUE, "Wood")
			-- the counter: two burners, a pot, a sink with a tap
			r:bevel(-1.65, 1.9, -0.65, 1.65, 2.0, 0.65, 0.035, WOOD, "Wood", { wear = 1.06 })
			for _, x in { -1.15, -0.45 } do
				r:cyl(x, 2.015, 0.15, 0.03, 0.5, "y", INK, "Metal")
				r:cyl(x, 2.045, 0.15, 0.03, 0.3, "y", RED, "Wood")
			end
			r:cyl(-1.15, 2.24, 0.15, 0.4, 0.5, "y", SKY, "Metal")
			r:cyl(-1.15, 2.45, 0.15, 0.03, 0.54, "y", shade(SKY, 0.9), "Metal")
			r:ball(-1.15, 2.5, 0.15, 0.1, RED, "Wood")
			rod(r, Vector3.new(-0.92, 2.36, 0.15), Vector3.new(-0.6, 2.4, 0.15), 0.06, INK)
			r:cyl(0.8, 2.015, 0.05, 0.03, 0.7, "y", C.Metal, "Metal")
			r:cyl(0.8, 2.04, 0.05, 0.03, 0.5, "y", SKY, "Glass")
			path(r, {
				Vector3.new(0.8, 2.0, -0.45),
				Vector3.new(0.8, 2.45, -0.45),
				Vector3.new(0.8, 2.45, -0.15),
				Vector3.new(0.8, 2.32, -0.1),
			}, 0.08, C.Metal, "Metal")
			-- a back with a window, a shelf of cups, a clock in an arch and things on hooks
			r:block(-1.6, 2.0, -0.6, 1.6, 3.6, -0.5, r.c1, "Wood")
			r:cyl(0, 3.6, -0.55, 0.1, 1.0, "z", r.c1, "Wood")
			r:block(-0.45, 2.2, -0.5, 0.45, 2.75, -0.47, SKY, "Glass")
			r:piece(function(q: R)
				q:block(-0.5, 2.15, -0.47, 0.5, 2.2, -0.44, SNOW, "Wood")
				q:block(-0.5, 2.75, -0.47, 0.5, 2.8, -0.44, SNOW, "Wood")
				q:block(-0.5, 2.2, -0.47, -0.45, 2.75, -0.44, SNOW, "Wood")
				q:block(0.45, 2.2, -0.47, 0.5, 2.75, -0.44, SNOW, "Wood")
				q:block(-0.025, 2.2, -0.47, 0.025, 2.75, -0.44, SNOW, "Wood")
			end)
			for _, sx in { -1, 1 } do
				r:block(sx * 0.5, 2.25, -0.49, sx * 0.72, 2.85, -0.43, PINK, "Fabric")
			end
			r:block(-1.55, 3.0, -0.5, 1.55, 3.08, -0.22, r.c2, "Wood")
			for i, c in { PINK, BUTTER, SKY, MINT } do
				local x = -1.35 + (i - 1) * 0.3
				r:cyl(x, 3.17, -0.36, 0.18, 0.16, "y", c, "Wood")
			end
			r:cyl(0, 3.68, -0.47, 0.04, 0.5, "z", SNOW, "Wood")
			r:boxAt(CFrame.new(0, 3.73, -0.43), 0.03, 0.12, 0.03, INK, "Metal")
			r:boxAt(CFrame.new(0.04, 3.68, -0.43) * CFrame.Angles(0, 0, math.pi / 2), 0.03, 0.1, 0.03, INK, "Metal")
			r:cyl(1.25, 3.4, -0.47, 0.05, 0.08, "z", C.Metal, "Metal")
			rod(r, Vector3.new(1.25, 3.38, -0.45), Vector3.new(1.25, 2.8, -0.45), 0.05, YELLOW)
			r:block(1.15, 2.55, -0.47, 1.35, 2.82, -0.43, YELLOW, "Wood")
			r:cyl(1.0, 3.4, -0.47, 0.05, 0.08, "z", C.Metal, "Metal")
			r:cyl(1.0, 3.1, -0.46, 0.05, 0.4, "z", INK, "Metal")
			rod(r, Vector3.new(1.0, 3.3, -0.45), Vector3.new(1.0, 3.39, -0.45), 0.04, INK)
		end,
	},

	------------------------------------------------------------------------------------------
	-- Decor
	{
		id = "play_teddy_big",
		name = "Big teddy bear",
		cat = "decor",
		style = "playful",
		price = 70,
		place = "floor",
		size = Vector3.new(3.0, 3.6, 2.6),
		c1 = "D9B48C",
		c2 = "F4B8C8",
		tags = { "toy" },
		build = function(r: R)
			local pale = mix(r.c1, C.White, 0.45)
			-- sitting: a round body with a pale tummy, legs out in front with paw pads
			r:lump(CFrame.new(0, 1.2, -0.15), 1.9, 2.1, 1.6, r.c1, "Fabric")
			r:lump(CFrame.new(0, 1.05, 0.55), 1.1, 1.3, 0.4, pale, "Fabric")
			for _, sx in { -1, 1 } do
				r:lump(CFrame.new(sx * 0.6, 0.35, 0.6), 0.75, 0.6, 1.2, r.c1, "Fabric")
				r:cyl(sx * 0.6, 0.38, 1.22, 0.05, 0.5, "z", pale, "Fabric")
				r:lump(
					CFrame.new(sx * 0.95, 1.45, 0.25) * CFrame.Angles(0.3, 0, sx * 0.5),
					0.55,
					1.1,
					0.55,
					r.c1,
					"Fabric"
				)
			end
			-- the head: ears, a muzzle, a nose and eyes
			r:lump(CFrame.new(0, 2.75, -0.05), 1.6, 1.45, 1.4, r.c1, "Fabric")
			for _, sx in { -1, 1 } do
				r:ball(sx * 0.6, 3.35, -0.15, 0.55, r.c1, "Fabric")
				r:cyl(sx * 0.6, 3.35, 0.15, 0.05, 0.3, "z", pale, "Fabric")
				r:ball(sx * 0.3, 2.95, 0.58, 0.14, INK, "Fabric")
			end
			r:lump(CFrame.new(0, 2.6, 0.62), 0.65, 0.45, 0.4, pale, "Fabric")
			r:ball(0, 2.72, 0.82, 0.18, INK, "Fabric")
			r:block(-0.02, 2.48, 0.8, 0.02, 2.62, 0.84, INK, "Fabric")
			-- a bow at the neck
			r:ball(0, 2.12, 0.6, 0.25, r.c2, "Fabric")
			for _, sx in { -1, 1 } do
				r:lump(
					CFrame.new(sx * 0.28, 2.14, 0.56) * CFrame.Angles(0, 0, sx * 0.2),
					0.45,
					0.3,
					0.15,
					r.c2,
					"Fabric"
				)
				r:boxAt(
					CFrame.new(sx * 0.12, 1.92, 0.62) * CFrame.Angles(0, 0, sx * 0.35),
					0.1,
					0.3,
					0.05,
					r.c2,
					"Fabric"
				)
			end
		end,
	},
	{
		id = "play_rug_hopscotch",
		name = "Hopscotch rug",
		cat = "decor",
		style = "playful",
		price = 80,
		place = "floor",
		size = Vector3.new(3.4, 0.1, 8.0),
		c1 = "F4ECDD",
		c2 = "A8D0EC",
		tags = { "rug", "toy" },
		build = function(r: R)
			-- a pale base, rounded at the far end
			r:block(-1.6, 0, -1.95, 1.6, 0.025, 3.95, r.c1, "Carpet")
			local back: { Vector3 } = {}
			for i = 0, 6 do
				local a = math.pi + i * math.pi / 6
				table.insert(back, Vector3.new(math.cos(a) * 1.6, 0.0125, -1.95 + math.sin(a) * 1.6))
			end
			fan(r, Vector3.new(0, 0.0125, -1.95), back, 0.025, r.c1, "Carpet")
			-- the squares in soft colours, and a round home at the end
			local cells = {
				{ 0, 3.35 },
				{ 0, 2.2 },
				{ -0.75, 1.05 },
				{ 0.75, 1.05 },
				{ 0, -0.1 },
				{ -0.75, -1.25 },
				{ 0.75, -1.25 },
			}
			local cols = { r.c2, PINK, BUTTER, MINT, LILAC, PEACH, r.c2 }
			for i, c in cells do
				local w = if c[1] == 0 then 0.65 else 0.67
				r:block(c[1] - w, 0.025, c[2] - 0.5, c[1] + w, 0.05, c[2] + 0.5, cols[i], "Carpet")
			end
			local home: { Vector3 } = {}
			for i = 0, 6 do
				local a = math.pi + i * math.pi / 6
				table.insert(home, Vector3.new(math.cos(a) * 1.4, 0.0375, -1.95 + math.sin(a) * 1.4))
			end
			fan(r, Vector3.new(0, 0.0375, -1.95), home, 0.025, BUTTER, "Carpet")
			star(r, CFrame.new(0, 0.0625, -2.6) * CFrame.Angles(-math.pi / 2, 0, 0), 0.5, 0.025, ORANGE, "Carpet")
			-- the numbers as dots, like dice
			local pips = {
				{ { 0, 0 } },
				{ { -1, -1 }, { 1, 1 } },
				{ { -1, -1 }, { 0, 0 }, { 1, 1 } },
				{ { -1, -1 }, { 1, -1 }, { -1, 1 }, { 1, 1 } },
				{ { -1, -1 }, { 1, -1 }, { 0, 0 }, { -1, 1 }, { 1, 1 } },
				{ { -1, -1 }, { 1, -1 }, { -1, 0 }, { 1, 0 }, { -1, 1 }, { 1, 1 } },
				{ { -1, -1 }, { 1, -1 }, { -1, 0 }, { 0, 0 }, { 1, 0 }, { -1, 1 }, { 1, 1 } },
			}
			for half = 0, 1 do
				r:piece(function(q: R)
					for i = 1 + half * 4, if half == 0 then 4 else 7 do
						local c = cells[i]
						for _, p in pips[i] do
							local x, z = c[1] + p[1] * 0.28, c[2] - p[2] * 0.28
							q:block(x - 0.08, 0.05, z - 0.08, x + 0.08, 0.075, z + 0.08, SNOW, "Carpet")
						end
					end
				end)
			end
			for _, p in r.prims do
				p.collide = false
			end
		end,
	},
	{
		id = "play_balloons",
		name = "Balloon bunch",
		cat = "decor",
		style = "playful",
		price = 30,
		place = "floor",
		size = Vector3.new(2.6, 6.0, 2.6),
		c1 = "F4B8C8",
		c2 = "A8D0EC",
		build = function(r: R)
			-- a little parcel holds them down
			r:block(-0.25, 0, -0.25, 0.25, 0.4, 0.25, BUTTER, "Wood")
			r:block(-0.28, 0, -0.05, 0.28, 0.43, 0.05, r.c1, "Fabric")
			r:block(-0.05, 0, -0.28, 0.05, 0.43, 0.28, r.c1, "Fabric")
			for _, sx in { -1, 1 } do
				r:lump(CFrame.new(sx * 0.12, 0.49, 0) * CFrame.Angles(0, 0, sx * 0.5), 0.2, 0.12, 0.1, r.c1, "Fabric")
			end
			local string = Color3.fromRGB(220, 214, 206)
			local balloons: { { p: Vector3, col: Color3 } } = {
				{ p = Vector3.new(0, 5.4, 0), col = r.c1 },
				{ p = Vector3.new(-0.75, 4.9, 0.3), col = r.c2 },
				{ p = Vector3.new(0.7, 5.0, -0.25), col = BUTTER },
				{ p = Vector3.new(-0.35, 4.3, -0.6), col = MINT },
				{ p = Vector3.new(0.45, 4.2, 0.55), col = LILAC },
				{ p = Vector3.new(-0.85, 3.85, -0.15), col = PEACH },
			}
			for _, b in balloons do
				local x, y, z, col = b.p.X, b.p.Y, b.p.Z, b.col
				r:lump(CFrame.new(x, y, z), 0.9, 1.05, 0.9, col, "Rubber")
				coneDown(r, x, y - 0.56, z, 0.12, 0.14, shade(col, 0.9))
				rod(r, Vector3.new(x, y - 0.62, z), Vector3.new(0, 0.48, 0), 0.025, string, "Fabric")
			end
			-- and one foil heart
			local hx, hy, hz = 0.8, 4.0, -0.55
			for _, sx in { -1, 1 } do
				r:lump(CFrame.new(hx + sx * 0.2, hy + 0.12, hz), 0.5, 0.5, 0.26, RED, "Foil")
			end
			r:add({
				shape = "Cone",
				cf = CFrame.new(hx, hy - 0.26, hz) * CFrame.Angles(math.pi, 0, 0),
				size = Vector3.new(0.86, 0.66, 0.26),
				color = RED,
				mat = "Foil",
			})
			rod(r, Vector3.new(hx, hy - 0.6, hz), Vector3.new(0, 0.48, 0), 0.025, string, "Fabric")
		end,
	},
	{
		id = "play_mobile",
		name = "Star mobile",
		cat = "decor",
		style = "playful",
		price = 40,
		place = "ceiling",
		size = Vector3.new(3.0, 3.4, 3.0),
		c1 = "F6E0A0",
		c2 = "A8D0EC",
		build = function(r: R)
			local cord = Color3.fromRGB(220, 214, 206)
			r:cyl(0, -0.04, 0, 0.08, 0.3, "y", SNOW, "Wood")
			rod(r, Vector3.new(0, -0.08, 0), Vector3.new(0, -1.0, 0), 0.03, cord, "Fabric")
			-- a wrapped hoop on four cords
			local ring: { Vector3 } = {}
			for i = 0, 12 do
				local a = i * math.pi / 6
				table.insert(ring, Vector3.new(math.cos(a) * 1.1, -1.4, math.sin(a) * 1.1))
			end
			path(r, ring, 0.08, r.c2, "Fabric")
			for i = 0, 3 do
				local a = i * math.pi / 2 + math.pi / 4
				rod(
					r,
					Vector3.new(0, -1.0, 0),
					Vector3.new(math.cos(a) * 1.1, -1.4, math.sin(a) * 1.1),
					0.025,
					cord,
					"Fabric"
				)
			end
			-- things hanging from it at different lengths: stars, clouds and a moon
			local hang: { { kind: string, drop: number } } = {
				{ kind = "star", drop = 2.3 },
				{ kind = "cloud", drop = 2.0 },
				{ kind = "star", drop = 2.7 },
				{ kind = "moon", drop = 2.2 },
				{ kind = "star", drop = 2.5 },
				{ kind = "cloud", drop = 2.6 },
			}
			for i, h in hang do
				local a = (i - 1) * math.pi / 3
				local x, z = math.cos(a) * 1.1, math.sin(a) * 1.1
				local y = -h.drop
				rod(r, Vector3.new(x, -1.42, z), Vector3.new(x, y + 0.2, z), 0.02, cord, "Fabric")
				local cf = CFrame.new(x, y, z) * CFrame.Angles(0, -a + math.pi / 2, 0)
				if h.kind == "star" then
					star(r, cf, 0.38, 0.08, r.c1, "Wood")
				elseif h.kind == "cloud" then
					r:lump(cf * CFrame.new(-0.16, 0, 0), 0.34, 0.26, 0.18, SNOW, "Wood")
					r:lump(cf * CFrame.new(0.02, 0.06, 0), 0.42, 0.36, 0.2, SNOW, "Wood")
					r:lump(cf * CFrame.new(0.2, -0.02, 0), 0.3, 0.24, 0.18, SNOW, "Wood")
				else
					local pts: { Vector3 } = {}
					for k = 0, 5 do
						local t = math.rad(70 + k * 44)
						table.insert(pts, (cf * CFrame.new(math.cos(t) * 0.24, math.sin(t) * 0.24, 0)).Position)
					end
					path(r, pts, 0.1, shade(r.c1, 0.95), "Wood")
				end
			end
			rod(r, Vector3.new(0, -1.0, 0), Vector3.new(0, -2.7, 0), 0.02, cord, "Fabric")
			star(r, CFrame.new(0, -2.9, 0) * CFrame.Angles(0, 0.4, 0), 0.5, 0.1, r.c1, "Wood")
		end,
	},

	------------------------------------------------------------------------------------------
	-- On walls
	{
		id = "play_growth_chart",
		name = "Giraffe height chart",
		cat = "walldecor",
		style = "playful",
		price = 40,
		place = "wall",
		size = Vector3.new(2.4, 6.2, 0.4),
		c1 = "F6E0A0",
		c2 = "A8DCC8",
		build = function(r: R)
			-- the board with a mark every half stud
			r:block(-0.4, 0.3, 0, 0.4, 5.5, 0.08, r.c2, "Wood")
			r:cyl(0, 5.5, 0.04, 0.08, 0.8, "z", r.c2, "Wood")
			r:piece(function(q: R)
				for i = 1, 10 do
					local y = 0.3 + i * 0.5
					local w = if i % 2 == 0 then 0.36 else 0.2
					q:block(-0.4, y - 0.02, 0.08, -0.4 + w, y + 0.02, 0.11, SNOW, "Wood")
				end
			end)
			-- two heights marked with little flags
			local flags: { { y: number, col: Color3 } } = { { y = 2.55, col = RED }, { y = 3.4, col = BLUE } }
			for i, f in flags do
				local y, col = f.y, f.col
				r:tri(
					Vector3.new(-0.1, y, 0.12),
					Vector3.new(0.3, y + 0.12, 0.12),
					Vector3.new(-0.1, y + 0.24, 0.12),
					0.04,
					col,
					"Wood"
				)
				r:ball(-0.12, y + 0.12, 0.13, 0.08 + i * 0.01, SNOW, "Wood")
			end
			-- a giraffe climbing up beside it, its head over the top
			local dk = shade(r.c1, 0.7)
			bar(r, Vector3.new(0.75, 1.25, 0.06), Vector3.new(0.7, 5.2, 0.06), 0.24, 0.08, r.c1, "Wood")
			r:block(0.42, 0.8, 0.02, 1.05, 1.35, 0.1, r.c1, "Wood")
			for _, x in { 0.5, 0.95 } do
				r:block(x - 0.06, 0.3, 0.02, x + 0.06, 0.85, 0.1, r.c1, "Wood")
				r:block(x - 0.07, 0.3, 0.1, x + 0.07, 0.38, 0.13, dk, "Wood")
			end
			r:block(0.4, 5.2, 0.1, 0.95, 5.55, 0.18, r.c1, "Wood")
			r:block(0.32, 5.24, 0.1, 0.42, 5.42, 0.18, shade(r.c1, 0.9), "Wood")
			for _, x in { 0.62, 0.82 } do
				rod(r, Vector3.new(x, 5.55, 0.14), Vector3.new(x, 5.75, 0.14), 0.05, dk, "Wood")
				r:ball(x, 5.78, 0.14, 0.09, dk, "Wood")
			end
			r:block(0.95, 5.38, 0.1, 1.1, 5.48, 0.16, r.c1, "Wood")
			r:ball(0.55, 5.42, 0.18, 0.07, INK, "Metal")
			r:piece(function(q: R)
				for i, p in
					{
						{ 0.72, 1.7 },
						{ 0.68, 2.4 },
						{ 0.74, 3.1 },
						{ 0.69, 3.8 },
						{ 0.72, 4.5 },
						{ 0.6, 1.05 },
						{ 0.88, 1.1 },
					}
				do
					local s = if i > 5 then 0.16 else 0.12
					q:block(p[1] - s / 2, p[2] - s / 2, 0.1, p[1] + s / 2, p[2] + s / 2, 0.13, dk, "Wood")
				end
			end)
		end,
	},

	------------------------------------------------------------------------------------------
	-- Lights
	{
		id = "play_lamp_moon",
		name = "Moon lamp",
		cat = "lights",
		style = "playful",
		price = 45,
		place = "surface",
		size = Vector3.new(1.4, 1.8, 0.8),
		c1 = "F6E0A0",
		c2 = "A8D0EC",
		tags = { "light" },
		build = function(r: R)
			-- a cloud to stand on
			r:lump(CFrame.new(0, 0.2, 0), 1.0, 0.4, 0.6, r.c2, "Wood")
			for _, sx in { -1, 1 } do
				r:lump(CFrame.new(sx * 0.38, 0.16, 0.02), 0.5, 0.32, 0.5, r.c2, "Wood")
			end
			rod(r, Vector3.new(0, 0.3, 0), Vector3.new(0, 0.55, 0), 0.08, shade(r.c2, 0.85))
			-- a crescent moon, fat in the middle and thin at the tips
			local cx, cy, rad = 0, 1.08, 0.55
			local n = 6
			for i = 0, n - 1 do
				local a1 = math.rad(50 + i * 260 / n)
				local a2 = math.rad(50 + (i + 1) * 260 / n)
				local d = 0.12 + 0.24 * math.sin((i + 0.5) / n * math.pi)
				local p1 = Vector3.new(cx + math.cos(a1) * rad, cy + math.sin(a1) * rad, 0)
				local p2 = Vector3.new(cx + math.cos(a2) * rad, cy + math.sin(a2) * rad, 0)
				local u = (p2 - p1).Unit * 0.04
				local p = rod(r, p1 - u, p2 + u, d, r.c1, "Glass")
				if p then
					if i == 2 then
						r:glow(p, 8, 0.7)
					else
						glowOnly(p)
					end
				end
			end
			-- a star hanging inside it
			local tip = Vector3.new(cx + math.cos(math.rad(50)) * rad, cy + math.sin(math.rad(50)) * rad, 0)
			rod(r, tip, Vector3.new(tip.X, 1.0, 0), 0.02, C.Metal)
			star(r, CFrame.new(tip.X, 0.9, 0), 0.2, 0.06, r.c1, "Glass")
		end,
	},
	{
		id = "play_lamp_balloon",
		name = "Balloon lamp",
		cat = "lights",
		style = "playful",
		price = 70,
		place = "ceiling",
		size = Vector3.new(2.0, 3.4, 2.0),
		c1 = "F4B8C8",
		c2 = "F4ECDD",
		tags = { "light" },
		build = function(r: R)
			r:cyl(0, -0.05, 0, 0.1, 0.4, "y", r.c2, "Rubber")
			rod(r, Vector3.new(0, -0.1, 0), Vector3.new(0, -0.56, 0), 0.04, INK)
			-- a striped balloon made of bands, glowing from inside
			local bands = {
				{ -0.62, 0.9, 0.14 },
				{ -0.78, 1.4, 0.18 },
				{ -0.98, 1.7, 0.22 },
				{ -1.22, 1.85, 0.26 },
				{ -1.48, 1.78, 0.26 },
				{ -1.72, 1.56, 0.22 },
				{ -1.92, 1.26, 0.18 },
			}
			for i, b in bands do
				local p = r:cyl(0, b[1], 0, b[3], b[2], "y", if i % 2 == 1 then r.c1 else r.c2, "Fabric")
				if i == 4 then
					r:glow(p, 14, 1.0)
				else
					glowOnly(p)
				end
			end
			coneDown(r, 0, -2.22, 0, 0.42, 1.08, r.c1, "Fabric")
			-- ropes down to a basket with a sandbag hanging off it
			for i = 0, 3 do
				local a = i * math.pi / 2 + math.pi / 4
				rod(
					r,
					Vector3.new(math.cos(a) * 0.3, -2.3, math.sin(a) * 0.3),
					Vector3.new(math.cos(a) * 0.3, -2.86, math.sin(a) * 0.3),
					0.03,
					INK
				)
			end
			r:block(-0.25, -3.25, -0.25, 0.25, -2.9, 0.25, WOOD, "Wood")
			r:block(-0.28, -2.92, -0.28, 0.28, -2.86, 0.28, shade(WOOD, 0.85), "Wood")
			rod(r, Vector3.new(0.28, -2.92, 0), Vector3.new(0.34, -3.1, 0), 0.02, INK)
			r:lump(CFrame.new(0.34, -3.17, 0), 0.12, 0.16, 0.12, PEACH, "Fabric")
		end,
	},

	------------------------------------------------------------------------------------------
	-- Fun
	{
		id = "play_tent",
		name = "Play tent",
		cat = "fun",
		style = "playful",
		price = 160,
		place = "floor",
		size = Vector3.new(4.0, 6.0, 4.0),
		c1 = "F4ECDD",
		c2 = "F4B8C8",
		tags = { "toy" },
		build = function(r: R)
			r:noCollide(r:cyl(0, 0.025, 0, 0.05, 3.4, "y", mix(r.c2, C.White, 0.4), "Fabric"))
			-- five poles crossing at the top
			local apex = Vector3.new(0, 4.9, 0)
			local feet: { Vector3 } = {}
			for i = 0, 4 do
				local a = math.rad(126 + i * 72)
				local base = Vector3.new(math.cos(a) * 1.75, 0, math.sin(a) * 1.75)
				table.insert(feet, base)
				rod(r, base, base + (apex - base) * 1.17, 0.1, WOOD, "Wood")
			end
			-- canvas between them, the front pulled back into two flaps
			local function edge(i: number): Vector3
				local f = feet[i]
				return Vector3.new(f.X * 0.97, 0.05, f.Z * 0.97)
			end
			local top = Vector3.new(0, 4.85, 0)
			for i = 1, 4 do
				r:tri(top, edge(i), edge(i + 1), 0.05, r.c1, "Fabric")
			end
			local a, b = edge(5), edge(1)
			r:tri(top, a, a + (b - a) * 0.28, 0.05, shade(r.c1, 0.95), "Fabric")
			r:tri(top, b, b + (a - b) * 0.28, 0.05, shade(r.c1, 0.95), "Fabric")
			for _, p in { a + (b - a) * 0.2, b + (a - b) * 0.2 } do
				r:ball(p.X * 0.62, 1.9, p.Z * 0.62, 0.14, r.c2, "Fabric")
			end
			-- a trim of little flags round the bottom
			for i = 1, 4 do
				local p1, p2 = edge(i), edge(i + 1)
				for k = 0, 2 do
					local t = (k + 0.5) / 3
					local m = p1:Lerp(p2, t)
					local out = Vector3.new(m.X, 0, m.Z).Unit * 0.04
					local along = (p2 - p1).Unit * 0.15
					local y = 0.9
					local q = Vector3.new(m.X, 0, m.Z) * (1 - y / 4.9) + out
					r:tri(
						q + Vector3.new(0, y, 0) - along,
						q + Vector3.new(0, y, 0) + along,
						q + Vector3.new(0, y - 0.28, 0) + out * 0.5,
						0.03,
						if k % 2 == 0 then r.c2 else BUTTER,
						"Fabric"
					)
				end
			end
			-- fairy lights round it
			local yl = 2.6
			local k = 1 - yl / 4.9
			local bulbs: { Vector3 } = {}
			for i = 1, 5 do
				local p1 = feet[i] * k * 1.06
				local p2 = feet[i % 5 + 1] * k * 1.06
				rod(r, p1 + Vector3.new(0, yl, 0), p2 + Vector3.new(0, yl, 0), 0.025, INK)
				for t = 1, 2 do
					local m = p1:Lerp(p2, t / 3)
					table.insert(bulbs, m + Vector3.new(0, yl - 0.08, 0))
				end
			end
			for i, p in bulbs do
				local bulb = r:ball(p.X, p.Y, p.Z, 0.13, C.Warm, "Glass")
				if i == 1 then
					r:glow(bulb, 10, 0.8)
				else
					glowOnly(bulb)
				end
			end
			-- cushions inside and a pennant on top
			r:lump(CFrame.new(-0.3, 0.25, 0.1), 0.9, 0.4, 0.9, BUTTER, "Fabric")
			r:lump(CFrame.new(0.35, 0.3, -0.35) * CFrame.Angles(0.3, 0, 0), 0.8, 0.6, 0.35, MINT, "Fabric")
			local pole = feet[1] + (apex - feet[1]) * 1.17
			r:tri(pole, pole + Vector3.new(0.35, -0.1, 0), pole + Vector3.new(0, -0.22, 0), 0.03, r.c2, "Fabric")
		end,
	},
	{
		id = "play_claw_machine",
		name = "Claw machine",
		cat = "fun",
		style = "playful",
		price = 420,
		place = "floor",
		size = Vector3.new(2.6, 6.2, 2.6),
		c1 = "A8D0EC",
		c2 = "F4B8C8",
		tags = { "games", "toy" },
		build = function(r: R)
			-- the cabinet: a kick plate, a prize door, a coin panel
			r:block(-1.2, 0, -1.2, 1.2, 2.6, 1.2, r.c1, "Metal")
			r:block(-1.15, 0, 1.2, 1.15, 0.2, 1.23, INK, "Metal")
			r:block(0.2, 0.45, 1.2, 0.9, 1.05, 1.24, C.DarkMetal, "Metal")
			r:block(0.15, 1.05, 1.2, 0.95, 1.15, 1.32, r.c2, "Metal")
			r:block(-0.9, 0.9, 1.2, -0.4, 1.6, 1.24, C.Metal, "Metal")
			r:block(-0.7, 1.2, 1.24, -0.6, 1.4, 1.27, INK, "Metal")
			r:block(-0.75, 1.0, 1.24, -0.55, 1.1, 1.27, RED, "Wood")
			-- a ledge with a joystick and a big button
			r:bevel(-1.2, 2.6, -1.2, 1.2, 2.75, 1.45, 0.052, r.c2, "Metal", { wear = 1.06 })
			r:cyl(-0.5, 2.765, 1.1, 0.03, 0.32, "y", INK, "Metal")
			rod(r, Vector3.new(-0.5, 2.75, 1.1), Vector3.new(-0.5, 3.05, 1.1), 0.06, INK)
			r:ball(-0.5, 3.08, 1.1, 0.2, RED, "Wood")
			r:cyl(0.4, 2.77, 1.1, 0.04, 0.38, "y", INK, "Metal")
			r:cyl(0.4, 2.82, 1.1, 0.08, 0.3, "y", YELLOW, "Wood")
			-- the glass case: corner posts and four panes
			for _, sx in { -1, 1 } do
				for _, sz in { -1, 1 } do
					r:box(sx * 1.14, 4.0, sz * 1.14, 0.12, 2.5, 0.12, r.c2, "Metal")
				end
				r:glass(sx * 1.08, 2.75, -1.08, sx * 1.11, 5.25, 1.08)
				r:glass(-1.08, 2.75, sx * 1.08, 1.08, 5.25, sx * 1.11)
			end
			-- prizes in a heap, a chute in the corner
			r:bevel(-1.08, 2.75, -1.08, 1.08, 2.92, 1.08, 0.059, shade(r.c1, 0.8), "Metal", { wear = 1.06 })
			r:block(0.45, 2.92, 0.45, 1.05, 3.35, 1.05, shade(r.c2, 0.9), "Metal")
			r:block(0.52, 3.35, 0.52, 0.98, 3.38, 0.98, INK, "Metal")
			for i, p in
				{
					{ -0.7, -0.6 },
					{ -0.25, -0.75 },
					{ 0.25, -0.6 },
					{ 0.7, -0.7 },
					{ -0.6, -0.1 },
					{ -0.15, 0.05 },
					{ 0.3, -0.1 },
					{ -0.7, 0.5 },
					{ -0.2, 0.6 },
				}
			do
				r:ball(p[1], 3.1 + (i % 3) * 0.05, p[2], 0.42, PASTELS[i % #PASTELS + 1], "Fabric")
			end
			r:ball(0.6, 3.25, -0.2, 0.36, PEACH, "Fabric")
			r:ball(0.6, 3.56, -0.2, 0.28, PEACH, "Fabric")
			for _, sx in { -1, 1 } do
				r:ball(0.6 + sx * 0.12, 3.7, -0.2, 0.1, PEACH, "Fabric")
			end
			-- the gantry and the claw on its cord
			for _, sx in { -1, 1 } do
				rod(r, Vector3.new(sx * 1.0, 5.1, -1.05), Vector3.new(sx * 1.0, 5.1, 1.05), 0.06, C.Metal, "Metal")
			end
			rod(r, Vector3.new(-1.0, 5.05, -0.2), Vector3.new(1.0, 5.05, -0.2), 0.06, C.Metal, "Metal")
			r:block(-0.05, 4.92, -0.35, 0.25, 5.08, -0.05, C.DarkMetal, "Metal")
			rod(r, Vector3.new(0.1, 4.92, -0.2), Vector3.new(0.1, 4.25, -0.2), 0.03, INK)
			r:cyl(0.1, 4.18, -0.2, 0.15, 0.22, "y", C.Metal, "Metal")
			for i = 0, 2 do
				local a = i * math.pi * 2 / 3
				local dx, dz = math.cos(a), math.sin(a)
				path(r, {
					Vector3.new(0.1 + dx * 0.08, 4.12, -0.2 + dz * 0.08),
					Vector3.new(0.1 + dx * 0.24, 3.9, -0.2 + dz * 0.24),
					Vector3.new(0.1 + dx * 0.12, 3.72, -0.2 + dz * 0.12),
				}, 0.04, C.Metal, "Metal")
			end
			-- a lit sign box on top with a star on it
			r:block(-1.25, 5.25, -1.25, 1.25, 6.0, 1.25, r.c2, "Metal")
			local sign = r:block(-1.0, 5.38, 1.25, 1.0, 5.88, 1.28, Color3.fromRGB(255, 244, 220), "Metal")
			r:glow(sign, 10, 0.8)
			star(r, CFrame.new(0, 5.63, 1.3), 0.36, 0.04, YELLOW, "Wood")
			r:block(-1.3, 6.0, -1.3, 1.3, 6.1, 1.3, r.c1, "Metal")
		end,
	},
	{
		id = "play_slide_indoor",
		name = "Indoor slide",
		cat = "fun",
		style = "playful",
		price = 200,
		place = "floor",
		size = Vector3.new(2.4, 3.6, 6.0),
		c1 = "A8DCC8",
		c2 = "F6E0A0",
		tags = { "toy" },
		build = function(r: R)
			-- chunky side panels round the steps, steps and the platform
			for _, sx in { -1, 1 } do
				r:quad(
					Vector3.new(sx * 1.0, 0, -2.9),
					Vector3.new(sx * 1.0, 0, -0.8),
					Vector3.new(sx * 1.0, 2.95, -0.8),
					Vector3.new(sx * 1.0, 2.95, -1.75),
					0.16,
					r.c1,
					"Metal"
				)
				-- handles over the platform
				path(r, {
					Vector3.new(sx * 1.0, 2.9, -1.7),
					Vector3.new(sx * 1.0, 3.45, -1.55),
					Vector3.new(sx * 1.0, 3.45, -1.0),
					Vector3.new(sx * 1.0, 2.9, -0.88),
				}, 0.12, r.c1, "Metal")
				star(r, CFrame.new(sx * 1.1, 1.3, -1.5) * CFrame.Angles(0, math.pi / 2, 0), 0.4, 0.04, YELLOW, "Wood")
			end
			for _, y in { 0.75, 1.5, 2.25 } do
				local z = -2.9 + y / 2.95 * 0.95
				r:block(-0.92, y - 0.12, z, 0.92, y, z + 0.5, r.c2, "Metal")
			end
			r:block(-0.92, 2.8, -1.65, 0.92, 2.95, -0.8, r.c2, "Metal")
			-- the chute: a bed with raised sides and rolled rims, and a flat run out at the foot
			local top, low = Vector3.new(0, 2.85, -0.8), Vector3.new(0, 0.35, 2.4)
			local dir = (low - top).Unit
			local n = Vector3.new(0, -dir.Z, dir.Y) * (if dir.Z > 0 then -1 else 1)
			if n.Y < 0 then
				n = -n
			end
			r:beam(top, low, 1.5, 0.12, r.c1, "Metal")
			for _, sx in { -1, 1 } do
				local o = Vector3.new(sx * 0.83, 0, 0)
				r:beam(top + o + n * 0.15, low + o + n * 0.15, 0.16, 0.45, r.c1, "Metal")
				rod(r, top + o + n * 0.4, low + o + n * 0.4, 0.24, shade(r.c1, 1.06), "Metal")
				local x1, x2 = sx * 0.75, sx * 0.91
				r:block(math.min(x1, x2), 0.2, 2.3, math.max(x1, x2), 0.65, 3.0, r.c1, "Metal")
				rod(
					r,
					Vector3.new(sx * 0.83, 0.68, 2.3),
					Vector3.new(sx * 0.83, 0.68, 3.0),
					0.24,
					shade(r.c1, 1.06),
					"Metal"
				)
			end
			r:block(-0.75, 0.2, 2.3, 0.75, 0.35, 3.0, r.c1, "Metal")
			r:block(-0.9, 0, 2.35, 0.9, 0.2, 2.95, shade(r.c1, 0.85), "Metal")
			-- a leg under the middle of the chute
			r:block(-0.6, 0, 0.9, 0.6, 1.35, 1.1, shade(r.c1, 0.85), "Metal")
		end,
	},
	{
		id = "play_ball_pit",
		name = "Ball pit",
		cat = "fun",
		style = "playful",
		price = 240,
		place = "floor",
		size = Vector3.new(5.0, 1.8, 5.0),
		c1 = "F4ECDD",
		c2 = "A8D0EC",
		tags = { "toy" },
		build = function(r: R)
			-- a round padded wall in twelve panels, alternating colours, with a padded rim
			for i = 0, 11 do
				local a = i * math.pi / 6
				local h = if i % 2 == 0 then 1.22 else 1.25
				r:boxAt(
					CFrame.new(math.cos(a) * 2.2, h / 2, math.sin(a) * 2.2) * CFrame.Angles(0, -a + math.pi / 2, 0),
					1.18,
					h,
					0.4,
					if i % 2 == 0 then r.c1 else r.c2,
					"Fabric"
				)
			end
			local rim: { Vector3 } = {}
			for i = 0, 12 do
				local a = i * math.pi / 6 + math.pi / 12
				table.insert(rim, Vector3.new(math.cos(a) * 2.27, 1.32, math.sin(a) * 2.27))
			end
			path(r, rim, 0.34, shade(r.c1, 0.95), "Fabric")
			-- full of balls
			r:cyl(0, 0.55, 0, 1.1, 4.1, "y", Color3.fromRGB(226, 214, 236), "Rubber")
			local cols = { RED, YELLOW, BLUE, GREEN, PINK }
			local k = 0
			for _, ring in { { 0.55, 6 }, { 1.1, 9 }, { 1.62, 11 } } do
				for i = 0, ring[2] - 1 do
					k += 1
					local a = i * math.pi * 2 / ring[2] + ring[1]
					r:ball(
						math.cos(a) * ring[1],
						1.12 + (k % 3) * 0.04,
						math.sin(a) * ring[1],
						0.45,
						cols[k % 5 + 1],
						"Rubber"
					)
				end
			end
			r:ball(0, 1.16, 0, 0.45, cols[1], "Rubber")
			-- a step to climb in by, and two balls that got out
			r:block(-0.55, 0, 2.35, 0.55, 0.45, 2.8, r.c2, "Fabric")
			r:ball(1.2, 0.2, 2.3, 0.4, YELLOW, "Rubber")
			r:ball(-1.5, 0.2, 2.0, 0.4, BLUE, "Rubber")
		end,
	},
	{
		id = "play_easel",
		name = "Kids' easel",
		gives = "draw", -- holding E gives something (Data/Items.Sources)
		cat = "fun",
		style = "playful",
		price = 90,
		place = "floor",
		size = Vector3.new(2.4, 4.4, 2.0),
		c1 = "E2C496",
		c2 = "F4B8C8",
		tags = { "toy" },
		build = function(r: R)
			-- an A frame: two legs in front, two behind, braced at the sides, a shelf low down
			for _, sx in { -1, 1 } do
				rod(r, Vector3.new(sx * 1.0, 0, 0.78), Vector3.new(sx * 0.95, 4.0, -0.02), 0.14, r.c1, "Wood")
				rod(r, Vector3.new(sx * 1.0, 0, -0.82), Vector3.new(sx * 0.95, 4.0, -0.18), 0.14, r.c1, "Wood")
				rod(r, Vector3.new(sx * 0.99, 0.8, 0.62), Vector3.new(sx * 0.99, 0.8, -0.69), 0.08, r.c1, "Wood")
			end
			r:block(-0.92, 0.72, -0.5, 0.92, 0.8, 0.4, r.c1, "Wood")
			-- the front: a white board with a picture on it, a tray with paints and a brush
			local tilt = math.atan2(0.8, 4.0)
			local function face(sz: number, y: number): CFrame
				local z = if sz > 0 then 0.78 - 0.8 * (y / 4.0) + 0.1 else -0.82 + 0.64 * (y / 4.0) - 0.1
				return CFrame.new(0, y, z) * CFrame.Angles(if sz > 0 then -tilt else tilt * 0.8, 0, 0)
			end
			local front = face(1, 2.45)
			r:boxAt(front, 1.8, 2.5, 0.06, SNOW, "Wood")
			r:add({
				shape = "Cylinder",
				cf = front * CFrame.new(0.45, 0.7, 0.045) * CFrame.Angles(0, math.pi / 2, 0),
				size = Vector3.new(0.03, 0.4, 0.4),
				color = YELLOW,
				mat = "Wood",
			})
			r:boxAt(front * CFrame.new(-0.3, -0.35, 0.045), 0.55, 0.5, 0.03, RED, "Wood")
			r:boxAt(front * CFrame.new(-0.3, -0.35, 0.075), 0.16, 0.3, 0.03, SKY, "Wood")
			r:boxAt(front * CFrame.new(0, -0.95, 0.045), 1.6, 0.18, 0.03, GREEN, "Wood")
			local tray = face(1, 1.12)
			r:boxAt(tray * CFrame.new(0, 0, 0.18), 1.9, 0.08, 0.36, r.c2, "Wood")
			r:boxAt(tray * CFrame.new(0, 0.07, 0.35), 1.9, 0.14, 0.04, r.c2, "Wood")
			for i, c in { RED, BLUE, YELLOW } do
				local p = (tray * CFrame.new(-0.6 + i * 0.25, 0.13, 0.18)).Position
				r:cyl(p.X, p.Y, p.Z, 0.18, 0.18, "y", c, "Wood")
			end
			local bp = (tray * CFrame.new(0.55, 0.08, 0.2)).Position
			rod(r, bp + Vector3.new(-0.2, 0, 0), bp + Vector3.new(0.2, 0, 0.05), 0.04, WOOD, "Wood")
			r:ball(bp.X + 0.23, bp.Y, bp.Z + 0.06, 0.07, BLUE, "Wood")
			-- the back: a chalkboard with chalk marks and a tray of chalk
			local back = face(-1, 2.45) * CFrame.Angles(0, math.pi, 0)
			r:boxAt(back, 1.8, 2.5, 0.06, Color3.fromRGB(70, 92, 82), "Wood")
			for i, p in { { -0.4, 0.5, 0.3 }, { 0.2, 0.2, -0.5 }, { 0.1, -0.5, 0.1 } } do
				r:boxAt(
					back * CFrame.new(p[1], p[2], 0.045) * CFrame.Angles(0, 0, p[3]),
					0.6 - i * 0.1,
					0.04,
					0.03,
					SNOW,
					"Wood"
				)
			end
			local btray = face(-1, 1.12) * CFrame.Angles(0, math.pi, 0)
			r:boxAt(btray * CFrame.new(0, 0, 0.18), 1.9, 0.08, 0.36, r.c2, "Wood")
			for i = 0, 2 do
				local p = (btray * CFrame.new(-0.3 + i * 0.3, 0.08, 0.18)).Position
				r:cyl(p.X, p.Y, p.Z, 0.25, 0.06, "x", if i == 1 then PINK else SNOW, "Wood")
			end
			-- a roll of paper across the top
			r:cyl(0, 4.02, -0.1, 1.7, 0.34, "x", SNOW, "Wood")
			for _, sx in { -1, 1 } do
				r:cyl(sx * 0.88, 4.02, -0.1, 0.06, 0.2, "x", r.c1, "Wood")
			end
		end,
	},

	------------------------------------------------------------------------------------------
	-- Garden
	{
		id = "play_trampoline",
		name = "Trampoline",
		cat = "garden",
		style = "playful",
		price = 380,
		place = "ground",
		size = Vector3.new(6.0, 4.8, 6.0),
		c1 = "A8D0EC",
		c2 = "F4ECDD",
		tags = { "toy" },
		build = function(r: R)
			local metal = C.Metal
			-- the frame and its U shaped legs
			local ring: { Vector3 } = {}
			for i = 0, 12 do
				local a = i * math.pi / 6
				table.insert(ring, Vector3.new(math.cos(a) * 2.6, 1.5, math.sin(a) * 2.6))
			end
			path(r, ring, 0.12, metal, "Metal")
			local poles: { Vector3 } = {}
			for i = 0, 5 do
				local a = math.rad(120 + i * 60)
				local dx, dz = math.cos(a), math.sin(a)
				local side = Vector3.new(-dz, 0, dx) * 0.28
				local p = Vector3.new(dx * 2.6, 0, dz * 2.6)
				for _, s in { -1, 1 } do
					rod(
						r,
						p + side * s + Vector3.new(0, 1.5, 0),
						p + side * s + Vector3.new(0, 0.05, 0),
						0.1,
						metal,
						"Metal"
					)
				end
				rod(r, p - side + Vector3.new(0, 0.05, 0), p + side + Vector3.new(0, 0.05, 0), 0.1, metal, "Metal")
				-- a padded net pole above each leg
				local pp = Vector3.new(dx * 2.64, 0, dz * 2.64)
				rod(r, pp + Vector3.new(0, 1.5, 0), pp + Vector3.new(0, 4.5, 0), 0.14, metal, "Metal")
				rod(r, pp + Vector3.new(0, 1.75, 0), pp + Vector3.new(0, 4.3, 0), 0.26, r.c2, "Fabric")
				r:ball(pp.X, 4.55, pp.Z, 0.22, r.c2, "Fabric")
				table.insert(poles, pp)
			end
			-- the pad over the springs and the dark mat to jump on
			r:cyl(0, 1.58, 0, 0.1, 5.5, "y", r.c1, "Fabric")
			r:cyl(0, 1.625, 0, 0.11, 4.4, "y", Color3.fromRGB(60, 60, 66), "Fabric")
			-- the net between the poles, open at the front where the ladder is
			for i = 1, 6 do
				local a, b = poles[i], poles[i % 6 + 1]
				rod(
					r,
					a + Vector3.new(0, 4.42, 0),
					b + Vector3.new(0, 4.42, 0),
					0.06,
					Color3.fromRGB(60, 60, 66),
					"Fabric"
				)
				if i ~= 6 then
					local m = (a + b) / 2
					local d = (b - a)
					local x = d.Unit
					local cf = CFrame.fromMatrix(m + Vector3.new(0, 3.06, 0), x, Vector3.yAxis, x:Cross(Vector3.yAxis))
					local net = r:boxAt(cf, d.Magnitude - 0.2, 2.72, 0.03, Color3.fromRGB(60, 60, 66), "Fabric")
					net.transp = 0.7
				end
			end
			-- a little ladder
			for _, sx in { -1, 1 } do
				rod(r, Vector3.new(sx * 0.35, 0, 3.0), Vector3.new(sx * 0.35, 1.5, 2.55), 0.1, metal, "Metal")
			end
			for i = 1, 3 do
				local t = i / 4
				rod(
					r,
					Vector3.new(-0.35, 1.5 * t, 3.0 - 0.45 * t),
					Vector3.new(0.35, 1.5 * t, 3.0 - 0.45 * t),
					0.12,
					r.c2,
					"Metal"
				)
			end
		end,
	},
	{
		id = "play_seesaw",
		name = "Seesaw",
		cat = "garden",
		style = "playful",
		price = 140,
		place = "ground",
		size = Vector3.new(8.0, 2.6, 1.8),
		c1 = "F4B8C8",
		c2 = "A8D0EC",
		tags = { "toy", "seat" },
		build = function(r: R)
			-- a frame of two triangles on a foot, an axle through them
			r:bevel(-0.7, 0, -0.6, 0.7, 0.1, 0.6, 0.035, shade(r.c2, 0.85), "Metal", { wear = 1.06 })
			for _, z in { -0.45, 0.45 } do
				r:tri(Vector3.new(-0.6, 0.1, z), Vector3.new(0.6, 0.1, z), Vector3.new(0, 1.05, z), 0.16, r.c2, "Metal")
			end
			r:cyl(0, 1.0, 0, 1.2, 0.22, "z", C.Metal, "Metal")
			-- a tyre half sunk in the ground under the low end
			r:cyl(-3.5, 0.1, 0, 0.5, 0.5, "z", INK, "Rubber")
			-- the board, tipped one way, with a pad, a handle and a tyre under each end
			local board = CFrame.new(0, 1.15, 0) * CFrame.Angles(0, 0, 0.16)
			r:boxAt(board, 7.6, 0.16, 0.9, r.c1, "Wood")
			r:boxAt(board * CFrame.new(0, -0.12, 0), 0.5, 0.08, 0.7, C.Metal, "Metal")
			for _, sx in { -1, 1 } do
				r:boxAt(board * CFrame.new(sx * 3.2, 0.13, 0), 0.9, 0.1, 0.86, mix(r.c2, C.White, 0.3), "Fabric")
				local h1 = board:PointToWorldSpace(Vector3.new(sx * 2.6, 0.08, -0.3))
				local h2 = board:PointToWorldSpace(Vector3.new(sx * 2.6, 0.75, -0.3))
				local h3 = board:PointToWorldSpace(Vector3.new(sx * 2.6, 0.75, 0.3))
				local h4 = board:PointToWorldSpace(Vector3.new(sx * 2.6, 0.08, 0.3))
				path(r, { h1, h2, h3, h4 }, 0.08, if sx < 0 then YELLOW else BLUE, "Metal")
				r:boxAt(board * CFrame.new(sx * 3.5, -0.14, 0), 0.3, 0.12, 0.6, INK, "Rubber")
				local s = board:PointToWorldSpace(Vector3.new(sx * 3.2, 0.18, 0))
				r:seat(s.X, s.Y, s.Z, if sx < 0 then 90 else -90)
			end
		end,
	},

	------------------------------------------------------------------------------------------
	-- Bathroom
	{
		id = "play_sink_step",
		name = "Kids' sink",
		cat = "bath",
		style = "playful",
		price = 160,
		place = "floor",
		size = Vector3.new(2.8, 4.4, 2.6),
		c1 = "A8DCC8",
		c2 = "F6E0A0",
		tags = { "bath" },
		build = function(r: R)
			-- a low cupboard with two doors and round knobs
			r:bevel(-1.05, 0, -1.05, 1.05, 0.1, -0.15, 0.035, shade(r.c1, 0.8), "Wood", { wear = 1.06 })
			r:block(-1.1, 0.1, -1.1, 1.1, 2.2, -0.1, r.c1, "Wood")
			for i, sx in { -1, 1 } do
				local x1, x2 = sx * 0.03, sx * 1.0
				r:block(math.min(x1, x2), 0.3, -0.1, math.max(x1, x2), 2.0, -0.06, shade(r.c1, 1.06), "Wood")
				r:ball(sx * 0.18, 1.2, -0.03, 0.14, if i == 1 then RED else YELLOW, "Wood")
				r:cyl(sx * 0.52, 1.5, -0.04, 0.04, 0.4, "z", if i == 1 then BUTTER else PINK, "Wood")
			end
			-- the top, a round basin and a tap with a red and a blue handle
			r:bevel(-1.2, 2.2, -1.2, 1.2, 2.32, 0.0, 0.042, SNOW, "Wood", { wear = 1.06 })
			r:cyl(0, 2.41, -0.55, 0.18, 1.0, "y", SNOW, "Wood")
			r:cyl(0, 2.52, -0.55, 0.04, 1.08, "y", shade(SNOW, 0.95), "Wood")
			r:cyl(0, 2.555, -0.55, 0.03, 0.8, "y", SKY, "Glass")
			path(r, {
				Vector3.new(0, 2.32, -1.0),
				Vector3.new(0, 2.85, -1.0),
				Vector3.new(0, 2.85, -0.75),
				Vector3.new(0, 2.72, -0.68),
			}, 0.1, C.Metal, "Metal")
			r:ball(-0.3, 2.42, -1.0, 0.18, RED, "Wood")
			r:ball(0.3, 2.42, -1.0, 0.18, BLUE, "Wood")
			-- a cup of toothbrushes and a bar of soap
			r:cyl(0.85, 2.445, -0.85, 0.25, 0.22, "y", PINK, "Wood")
			rod(r, Vector3.new(0.83, 2.4, -0.85), Vector3.new(0.75, 2.85, -0.82), 0.05, GREEN)
			rod(r, Vector3.new(0.88, 2.4, -0.86), Vector3.new(0.96, 2.82, -0.9), 0.05, BLUE)
			r:block(-1.0, 2.32, -0.4, -0.7, 2.42, -0.2, PEACH, "Wood")
			-- a tiled splashback and a round mirror in a cloud frame
			r:block(-1.2, 2.32, -1.2, 1.2, 2.7, -1.08, SNOW, "Wood")
			r:piece(function(q: R)
				for i = 0, 6 do
					local x = -0.96 + i * 0.32
					q:block(x - 0.12, 2.42, -1.08, x + 0.12, 2.62, -1.05, PASTELS[i % #PASTELS + 1], "Wood")
				end
			end, nil, "Wood")
			r:block(-0.7, 2.7, -1.2, 0.7, 4.2, -1.1, r.c1, "Wood")
			r:cyl(0, 3.45, -1.07, 0.04, 1.0, "z", Color3.fromRGB(214, 228, 234), "Glass")
			for i = 0, 7 do
				local a = i * math.pi / 4
				r:ball(math.cos(a) * 0.6, 3.45 + math.sin(a) * 0.6, -1.06, 0.36, SNOW, "Wood")
			end
			-- a step stool in front to reach it
			r:block(-0.7, 0, 0.4, 0.7, 0.45, 1.25, r.c2, "Wood")
			r:block(-0.7, 0.45, 0.4, 0.7, 0.9, 0.8, r.c2, "Wood")
			for _, s in { { 0.45, 0.85, 1.2 }, { 0.9, 0.45, 0.75 } } do
				r:block(-0.55, s[1], s[2], 0.55, s[1] + 0.03, s[3], PINK, "Rubber")
			end
		end,
	},
}

return items
