--!strict
-- Beds. The head is at the back (-z) and the foot at the front (+z). Every bed marks where
-- someone sleeps with r:sleep, so villagers can use it at night.
-- c1 is the frame, c2 the blanket. Mattress tops sit about 2 studs up.

local Recipe = require(script.Parent.Parent.Recipe)
local Colors = require(script.Parent.Parent.Parent.Util.Colors)

local C = Recipe.Colors

type R = Recipe.Recipe

local function shade(c: Color3, k: number): Color3
	return Colors.shade(c, k)
end

local SHEET = Color3.fromRGB(250, 248, 243)

-- A round rod from a to b (a cylinder laid along the line).
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
		mat = mat or r.mat or "Metal",
	})
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

-- A small square cushion standing up against the pillows.
local function cushion(r: R, x: number, y: number, z: number, s: number, tilt: number, color: Color3)
	r:boxAt(CFrame.new(x, y + s / 2, z) * CFrame.Angles(-0.3, 0, tilt), s, s, 0.26, color, "Fabric")
end

-- A mattress from y0 to y1 with a piped edge, a duvet that starts at zb and hangs over the sides
-- and foot, and its top folded back over the sheet.
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
	r:bevel(x1, y0, z1, x2, y1, z2, 0.1, SHEET, "Fabric", { round = true })
	r:block(x1 - 0.03, y1 - 0.1, z1 - 0.03, x2 + 0.03, y1 - 0.05, z2 + 0.03, shade(SHEET, 0.86), "Fabric")
	local fold = Colors.mix(blanket, C.White, 0.3)
	r:block(x1 - 0.08, y1 - 0.5, zb + 0.3, x2 + 0.08, y1 + 0.12, z2 + 0.08, blanket, "Fabric")
	r:block(x1 - 0.12, y1 - 0.46, zb, x2 + 0.12, y1 + 0.2, zb + 0.4, fold, "Fabric")
	r:cyl((x1 + x2) / 2, y1 + 0.05, zb, x2 - x1 + 0.24, 0.3, "x", fold, "Fabric")
end

-- Four short tapered legs under the corners.
local function feet(r: R, x: number, z: number, h: number, color: Color3)
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			rod(
				r,
				Vector3.new(sx * x, h + 0.02, sz * z),
				Vector3.new(sx * (x + 0.04), 0, sz * (z + 0.04)),
				0.3,
				color,
				"Wood"
			)
		end
	end
end

-- One catalog entry (Build/Catalog explains the fields).
type Item = {
	id: string,
	name: string,
	cat: string,
	price: number,
	place: string,
	size: Vector3,
	c1: string,
	c2: string?,
	tags: { string }?,
	surface: number?,
	style: string?, -- the look it belongs to (Catalog.Styles)
	build: (r: R) -> (),
}

local items: { Item } = {
	{
		id = "bed_single",
		name = "Single bed",
		cat = "beds",
		style = "cozy",
		price = 180,
		place = "floor",
		size = Vector3.new(3.6, 3.6, 7.2),
		c1 = "C99A62",
		c2 = "7A9CC6",
		tags = { "bed" },
		build = function(r: R)
			local dk = shade(r.c1, 0.85)
			feet(r, 1.6, 3.3, 0.5, dk)
			for _, sx in { -1, 1 } do
				r:block(sx * 1.7 - 0.1, 0.5, -3.38, sx * 1.7 + 0.1, 1.2, 3.38, r.c1, "Wood")
			end
			mattress(r, -1.6, 1.6, -3.38, 3.36, 1.15, 1.88, -0.9, r.c2)
			pillow(r, 0, 1.88, -2.75, 2.3)
			cushion(r, 0.5, 1.95, -2.3, 0.85, 0.12, Colors.mix(r.c2, C.Cream, 0.4))
			-- a panelled headboard between two posts, and a low footboard
			for _, sx in { -1, 1 } do
				r:box(sx * 1.68, 1.8, -3.48, 0.24, 3.6, 0.24, r.c1, "Wood")
				r:box(sx * 1.68, 0.85, 3.48, 0.24, 1.7, 0.24, r.c1, "Wood")
			end
			r:block(-1.56, 0.6, -3.56, 1.56, 3.25, -3.42, r.c1, "Wood")
			r:block(-1.3, 1.95, -3.42, 1.3, 3.0, -3.38, shade(r.c1, 1.08), "Wood")
			r:block(-1.84, 3.25, -3.64, 1.84, 3.4, -3.32, dk, "Wood")
			r:block(-1.56, 0.6, 3.42, 1.56, 1.5, 3.56, r.c1, "Wood")
			r:block(-1.84, 1.5, 3.32, 1.84, 1.62, 3.64, dk, "Wood")
			-- a knitted throw folded across the foot, hanging over both sides, with two stripes
			local throw = Colors.mix(r.c2, C.Cream, 0.55)
			r:block(-1.74, 1.58, 2.2, 1.74, 2.14, 2.9, throw, "Fabric")
			for _, z in { 2.38, 2.72 } do
				r:block(-1.77, 1.58, z - 0.05, 1.77, 2.17, z + 0.05, shade(r.c2, 0.85), "Fabric")
			end
			r:sleep(0, 1.95, 0.1)
		end,
	},
	{
		id = "bed_double",
		name = "Double bed",
		cat = "beds",
		style = "cozy",
		price = 320,
		place = "floor",
		size = Vector3.new(6, 4.3, 7.6),
		c1 = "8E8E94",
		c2 = "8FB39A",
		tags = { "bed" },
		build = function(r: R)
			feet(r, 2.7, 3.5, 0.4, Color3.fromRGB(110, 76, 52))
			-- a padded platform with a recessed base
			r:bevel(-2.9, 0.4, -3.6, 2.9, 0.55, 3.6, 0.068, shade(r.c1, 0.7), "Fabric", { round = true })
			r:block(-3, 0.55, -3.6, 3, 1.25, 3.8, r.c1, "Fabric")
			mattress(r, -2.85, 2.85, -3.38, 3.55, 1.25, 1.98, -0.9, r.c2)
			-- a folded throw across the foot
			r:bevel(
				-2.98,
				1.6,
				2.05,
				2.98,
				2.18,
				3.05,
				0.1,
				Colors.mix(r.c2, C.Black, 0.35),
				"Fabric",
				{ round = true }
			)
			pillow(r, -1.35, 1.98, -2.85, 2.3)
			pillow(r, 1.35, 1.98, -2.85, 2.3)
			local accent = Colors.mix(r.c2, C.Cream, 0.45)
			cushion(r, -0.8, 2.05, -2.32, 0.95, -0.1, accent)
			cushion(r, 0.8, 2.05, -2.32, 0.95, 0.1, accent)
			-- a tall headboard padded in vertical channels
			r:block(-3, 0.55, -3.8, 3, 3.95, -3.62, shade(r.c1, 0.8), "Fabric")
			local n = 6
			for i = 0, n - 1 do
				local x1 = -2.9 + i * 5.8 / n + 0.03
				local x2 = x1 + 5.8 / n - 0.06
				r:block(x1, 1.25, -3.62, x2, 3.85, -3.4, r.c1, "Fabric")
				r:cyl((x1 + x2) / 2, 3.85, -3.51, 0.22, x2 - x1, "z", r.c1, "Fabric")
			end
			r:sleep(-1.35, 2.05, 0.1)
			r:sleep(1.35, 2.05, 0.1)
		end,
	},
	{
		id = "bed_bunk",
		name = "Bunk bed",
		cat = "beds",
		style = "playful",
		price = 380,
		place = "floor",
		size = Vector3.new(4.2, 7.2, 7.2),
		c1 = "AD7E55",
		c2 = "D08A6C",
		tags = { "bed" },
		build = function(r: R)
			local dk = shade(r.c1, 0.85)
			-- corner posts with rounded caps
			for _, sx in { -1, 1 } do
				for _, sz in { -1, 1 } do
					r:box(sx * 1.7, 3.5, sz * 3.4, 0.4, 7.0, 0.4, r.c1, "Wood")
					r:cyl(sx * 1.7, 7.1, sz * 3.4, 0.2, 0.42, "y", dk, "Wood")
				end
			end
			for _, y in { 0.6, 4.3 } do
				for _, sx in { -1, 1 } do
					r:block(sx * 1.7 - 0.12, y, -3.2, sx * 1.7 + 0.12, y + 0.55, 3.2, r.c1, "Wood")
				end
				mattress(r, -1.55, 1.55, -3.2, 3.2, y + 0.45, y + 1.05, -0.9, r.c2)
				pillow(r, 0, y + 1.05, -2.6, 2.0)
			end
			-- head and foot boards for both bunks
			r:block(-1.5, 1.1, -3.48, 1.5, 2.7, -3.32, r.c1, "Wood")
			r:block(-1.5, 4.8, -3.48, 1.5, 6.9, -3.32, r.c1, "Wood")
			r:block(-1.5, 1.1, 3.32, 1.5, 2.1, 3.48, r.c1, "Wood")
			r:block(-1.5, 4.8, 3.32, 1.5, 6.4, 3.48, r.c1, "Wood")
			-- guard rails round the top bunk, with a gap for the ladder
			r:block(-1.82, 6.15, -3.2, -1.62, 6.45, 3.2, r.c1, "Wood")
			r:block(1.62, 6.15, -3.2, 1.82, 6.45, 1.55, r.c1, "Wood")
			r:block(1.64, 5.21, -3.2, 1.8, 5.4, 1.55, dk, "Wood")
			r:block(-1.8, 5.21, -3.2, -1.64, 5.4, 3.2, dk, "Wood")
			-- the ladder on the right, by the foot
			for _, z in { 1.75, 3.15 } do
				r:block(1.9, 0, z - 0.1, 2.1, 6.5, z + 0.1, dk, "Wood")
			end
			for i = 1, 5 do
				local y = 0.9 + (i - 1) * 1.05
				r:cyl(2.0, y, 2.45, 1.3, 0.14, "z", dk, "Wood")
			end
			-- a teddy sitting up by the top pillow
			local bear = Color3.fromRGB(176, 130, 88)
			r:ball(0.9, 5.82, -1.9, 0.5, bear, "Fabric")
			r:ball(0.9, 6.22, -1.95, 0.4, bear, "Fabric")
			r:ball(0.9, 6.18, -1.76, 0.16, Color3.fromRGB(233, 211, 176), "Fabric")
			for _, sx in { -1, 1 } do
				r:ball(0.9 + sx * 0.16, 6.42, -1.98, 0.14, bear, "Fabric")
				r:ball(0.9 + sx * 0.2, 5.75, -1.7, 0.2, bear, "Fabric")
			end
			r:sleep(0, 1.7, 0.1)
			r:sleep(0, 5.4, 0.1)
		end,
	},
	{
		id = "futon",
		name = "Futon",
		cat = "beds",
		style = "modern",
		price = 150,
		place = "floor",
		size = Vector3.new(4.2, 1.8, 7),
		c1 = "C99A62",
		c2 = "D08A6C",
		tags = { "bed" },
		build = function(r: R)
			-- a low wooden platform on a recessed base
			r:bevel(-1.9, 0, -3.25, 1.9, 0.18, 3.25, 0.063, shade(r.c1, 0.6), "Wood", { wear = 1.06 })
			r:bevel(-2.1, 0.18, -3.5, 2.1, 0.45, 3.5, 0.08, r.c1, "Wood", { wear = 1.06 })
			for _, sz in { -1, 1 } do
				r:block(-2.1, 0.45, sz * 3.45 - 0.05, 2.1, 0.52, sz * 3.45 + 0.05, shade(r.c1, 0.86), "Wood")
			end
			-- a thick mattress with rounded sides and tufts
			r:block(-1.62, 0.45, -3.3, 1.62, 1.1, 3.3, r.c2, "Fabric")
			for _, sx in { -1, 1 } do
				r:cyl(sx * 1.62, 0.775, 0, 6.6, 0.65, "z", r.c2, "Fabric")
			end
			for _, z in { -0.6, 0.9, 2.4 } do
				for _, x in { -0.9, 0.9 } do
					r:ball(x, 1.1, z, 0.16, shade(r.c2, 0.72), "Fabric")
				end
			end
			-- a folded quilt at the foot and a pillow at the head
			r:bevel(-1.85, 1.1, 1.75, 1.85, 1.42, 3.0, 0.1, C.Cream, "Fabric", { round = true })
			r:cyl(0, 1.26, 1.75, 3.7, 0.32, "x", C.Cream, "Fabric")
			r:block(-1.88, 1.1, 2.3, 1.88, 1.45, 2.45, shade(C.Cream, 0.85), "Fabric")
			r:piece(function(q: R)
				for _, sx in { -1, 1 } do
					local xa, xb = sx * 2.1, sx * 2.13
					for k = 0, 8 do
						local z = -3.1 + k * 0.775
						q:block(
							math.min(xa, xb),
							0.24,
							z - 0.16,
							math.max(xa, xb),
							0.39,
							z + 0.16,
							shade(r.c1, 0.86),
							"Wood"
						)
					end
				end
			end)
			local patches = { C.Pink, Color3.fromRGB(143, 179, 154), C.Yellow, Color3.fromRGB(110, 140, 168) }
			for i, col in patches do
				local x = -1.35 + (i - 1) * 0.9
				r:block(x - 0.32, 1.42, 1.95, x + 0.32, 1.45, 2.25, col, "Fabric")
				r:block(x - 0.32, 1.42, 2.5, x + 0.32, 1.45, 2.85, patches[(i % 4) + 1], "Fabric")
			end
			pillow(r, 0, 1.1, -2.6, 2.2)
			r:sleep(0, 1.2, 0)
		end,
	},
	{
		id = "bed_canopy",
		name = "Canopy bed",
		cat = "beds",
		style = "fancy",
		price = 600,
		place = "floor",
		size = Vector3.new(6.2, 9, 7.8),
		c1 = "F7F3EA",
		c2 = "D99AA4",
		tags = { "bed" },
		build = function(r: R)
			local cloth = Colors.mix(r.c2, C.White, 0.45)
			local dk = shade(r.c1, 0.88)
			-- four turned posts with finials, and a drape tied back at each corner
			for _, sx in { -1, 1 } do
				for _, sz in { -1, 1 } do
					local x, z = sx * 2.9, sz * 3.7
					r:box(x, 0.75, z, 0.46, 1.5, 0.46, r.c1, "Wood")
					r:cyl(x, 1.55, z, 0.16, 0.54, "y", dk, "Wood")
					r:cyl(x, 5.0, z, 6.8, 0.3, "y", r.c1, "Wood")
					r:ball(x, 8.75, z, 0.5, r.c1, "Wood")
					local x1, x2 = sx * 2.72, sx * 2.86
					local zp = sz * 3.48
					r:block(x1, 4.0, zp, x2, 8.2, zp - sz * 1.1, r.c2, "Fabric")
					r:block(x1, 1.4, zp, x2, 3.7, zp - sz * 0.6, r.c2, "Fabric")
					r:block(sx * 2.68, 3.65, zp + sz * 0.03, sx * 2.9, 4.05, zp - sz * 0.48, C.Gold, "Fabric")
				end
			end
			-- the top frame and a valance round it
			for _, sz in { -1, 1 } do
				r:block(-2.9, 8.2, sz * 3.7 - 0.15, 2.9, 8.55, sz * 3.7 + 0.15, r.c1, "Wood")
				r:block(-2.7, 7.4, sz * 3.6 - 0.06, 2.7, 8.2, sz * 3.6 + 0.06, r.c2, "Fabric")
				r:block(-2.7, 7.32, sz * 3.6 - 0.09, 2.7, 7.42, sz * 3.6 + 0.09, C.Gold, "Fabric")
			end
			for _, sx in { -1, 1 } do
				r:block(sx * 2.9 - 0.15, 8.2, -3.7, sx * 2.9 + 0.15, 8.55, 3.7, r.c1, "Wood")
				r:block(sx * 2.8 - 0.06, 7.4, -3.5, sx * 2.8 + 0.06, 8.2, 3.5, r.c2, "Fabric")
				r:block(sx * 2.79 - 0.1, 7.32, -3.45, sx * 2.79 + 0.1, 7.42, 3.45, C.Gold, "Fabric")
			end
			r:bevel(-2.75, 8.45, -3.55, 2.75, 8.55, 3.55, 0.045, cloth, "Fabric", { round = true })
			-- the bed itself
			r:block(-2.7, 0.5, -3.5, 2.7, 1.25, 3.5, r.c1, "Wood")
			r:block(-2.74, 0.47, 3.44, 2.74, 0.62, 3.56, dk, "Wood")
			mattress(r, -2.6, 2.6, -3.45, 3.4, 1.25, 1.98, -0.9, cloth)
			pillow(r, -1.3, 1.98, -2.8, 2.2)
			pillow(r, 1.3, 1.98, -2.8, 2.2)
			cushion(r, 0, 2.05, -2.3, 1.0, 0, r.c2)
			-- an arched headboard and a low footboard
			r:block(-2.68, 1.25, -3.72, 2.68, 4.2, -3.52, r.c1, "Wood")
			r:block(-1.8, 4.2, -3.7, 1.8, 4.7, -3.54, r.c1, "Wood")
			r:cyl(0, 4.7, -3.62, 0.16, 1.6, "z", r.c1, "Wood")
			r:block(-2.2, 2.2, -3.52, 2.2, 3.9, -3.48, shade(r.c1, 0.94), "Wood")
			r:block(-2.68, 1.25, 3.52, 2.68, 2.3, 3.72, r.c1, "Wood")
			r:sleep(-1.3, 2.05, 0.1)
			r:sleep(1.3, 2.05, 0.1)
		end,
	},
	{
		id = "bed_kids",
		name = "Kids' house bed",
		cat = "beds",
		style = "playful",
		price = 240,
		place = "floor",
		size = Vector3.new(3.8, 6.4, 6.8),
		c1 = "F7F3EA",
		c2 = "7FB8D9",
		tags = { "bed" },
		build = function(r: R)
			r:bevel(-1.7, 0.2, -3.2, 1.7, 0.7, 3.2, 0.08, r.c1, "Wood", { wear = 1.06 })
			r:bevel(-1.6, 0, -3.1, 1.6, 0.2, 3.1, 0.07, shade(r.c1, 0.8), "Wood", { wear = 1.06 })
			mattress(r, -1.55, 1.55, -3.1, 3.1, 0.7, 1.3, -0.7, r.c2)
			-- stars on the blanket
			for _, p in { { -0.7, 0.4 }, { 0.5, 1.3 }, { -0.2, 2.3 }, { 0.8, -0.1 } } do
				r:boxAt(CFrame.new(p[1], 1.44, p[2]) * CFrame.Angles(0, 0.6, 0), 0.3, 0.03, 0.3, C.Yellow, "Fabric")
			end
			pillow(r, 0, 1.3, -2.5, 2.0)
			-- a frame shaped like a little house
			for _, sz in { -1, 1 } do
				local z = sz * 3.25
				for _, sx in { -1, 1 } do
					r:box(sx * 1.75, 2.1, z, 0.3, 4.2, 0.3, r.c1, "Wood")
					r:beam(Vector3.new(sx * 1.85, 4.1, z), Vector3.new(0, 6.15, z), 0.3, 0.3, r.c1, "Wood")
				end
				-- a low fence at the head and foot
				r:block(-1.6, 0.7, z - 0.08, 1.6, 2.0, z + 0.08, r.c1, "Wood")
			end
			for _, sx in { -1, 1 } do
				r:block(sx * 1.75 - 0.15, 3.95, -3.25, sx * 1.75 + 0.15, 4.25, 3.25, r.c1, "Wood")
			end
			r:block(-0.15, 6.0, -3.4, 0.15, 6.3, 3.4, r.c1, "Wood")
			-- a string of little flags along one side
			local flags = { C.Pink, C.Yellow, r.c2, Color3.fromRGB(143, 200, 120), C.Pink }
			for i, col in flags do
				local z = -2.5 + (i - 1) * 1.25
				r:boxAt(CFrame.new(1.75, 3.78, z) * CFrame.Angles(math.pi / 4, 0, 0), 0.05, 0.38, 0.38, col, "Fabric")
			end
			r:sleep(0, 1.4, 0.2)
		end,
	},
}

return items
