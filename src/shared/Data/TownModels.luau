--!strict
-- The plaza's own buildings, drawn with the same Recipe API as the furniture.
-- Each model is built at the origin facing +Z (the street and customer side), standing on y = 0;
-- the World service places them. A part named "SignBoard" gets text on its +Z face.
-- The World service hangs a building's prompt on its biggest part, so the shops keep their
-- floor slab the biggest part (the prompt then sits in the middle of the shop floor).

local Recipe = require(script.Parent.Parent.Build.Recipe)
local Geometry = require(script.Parent.Parent.Build.Geometry)
local Colors = require(script.Parent.Parent.Util.Colors)

type R = Recipe.Recipe
local C = Recipe.Colors

local TownModels = {}

local STONE = Color3.fromRGB(236, 234, 228)
local DARK_STONE = Color3.fromRGB(196, 204, 214)
local WOOD = Color3.fromRGB(154, 110, 76)
local DARK_WOOD = Color3.fromRGB(102, 68, 42)
local IRON = Color3.fromRGB(46, 52, 50)
local CREAM = Color3.fromRGB(250, 246, 236)
local SKIN = Color3.fromRGB(240, 222, 204)

local function shade(c: Color3, k: number): Color3
	return Colors.shade(c, k)
end

-- A round rod from a to b (a cylinder laid along the line).
local function rod(r: R, a: Vector3, b: Vector3, d: number, color: Color3, mat: string?): Geometry.Prim?
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

-- See-through water you can walk into.
local function water(p: Geometry.Prim?, transp: number?)
	if p then
		p.transp = transp or 0.25
		p.collide = false
	end
end

-- A ring of straight pieces round (cx, cz), stretched a little so the outer corners close up.
local function ring(
	r: R,
	cx: number,
	cy: number,
	cz: number,
	radius: number,
	thick: number,
	height: number,
	color: Color3,
	mat: string,
	n: number?
)
	local count = n or 16
	local ext = thick * math.tan(math.pi / count) / 2 + 0.02
	for i = 0, count - 1 do
		local a1 = i / count * math.pi * 2
		local a2 = (i + 1) / count * math.pi * 2
		local p1 = Vector3.new(cx + math.cos(a1) * radius, cy, cz + math.sin(a1) * radius)
		local p2 = Vector3.new(cx + math.cos(a2) * radius, cy, cz + math.sin(a2) * radius)
		local d = (p2 - p1).Unit * ext
		r:beam(p1 - d, p2 + d, thick, height, color, mat)
	end
end

-- A four sided pyramid roof from a square base (half width `half`, at height y0) up to y1.
local function pyramid(r: R, cx: number, cz: number, y0: number, y1: number, half: number, color: Color3)
	local corners = {
		Vector3.new(cx - half, y0, cz - half),
		Vector3.new(cx + half, y0, cz - half),
		Vector3.new(cx + half, y0, cz + half),
		Vector3.new(cx - half, y0, cz + half),
	}
	local apex = Vector3.new(cx, y1, cz)
	for k = 1, 4 do
		r:tri(corners[k], corners[k % 4 + 1], apex, 0.2, if k % 2 == 0 then color else shade(color, 0.88), "Slate")
	end
end

-- A striped canvas awning along a front wall at z = zw, from x1 to x2. It leaves the wall at
-- height y, slopes out `depth` and down `drop`, and has a scalloped flap along its front,
-- closed side cheeks and iron arms underneath.
local function awning(
	r: R,
	x1: number,
	x2: number,
	zw: number,
	y: number,
	depth: number,
	drop: number,
	c1: Color3,
	c2: Color3
)
	local n = math.max(2, math.floor((x2 - x1) / 1.6 + 0.5))
	local sw = (x2 - x1) / n
	local yf, zf = y - drop, zw + depth
	for i = 0, n - 1 do
		local xm = x1 + (i + 0.5) * sw
		local col = if i % 2 == 0 then c1 else c2
		r:beam(Vector3.new(xm, y, zw), Vector3.new(xm, yf, zf), sw, 0.1, col, "Fabric")
		r:block(xm - sw / 2, yf - 0.55, zf - 0.04, xm + sw / 2, yf, zf + 0.04, col, "Fabric")
		r:cyl(xm, yf - 0.55, zf, 0.08, sw, "z", col, "Fabric")
	end
	for _, x in { x1, x2 } do
		r:tri(Vector3.new(x, y, zw), Vector3.new(x, yf, zf), Vector3.new(x, yf - 0.55, zw + 0.3), 0.06, c1, "Fabric")
	end
	r:cyl((x1 + x2) / 2, yf, zf - 0.1, x2 - x1, 0.1, "x", IRON, "Metal")
	for _, x in { x1 + 0.6, (x1 + x2) / 2, x2 - 0.6 } do
		rod(r, Vector3.new(x, y - 1.7, zw), Vector3.new(x, yf - 0.05, zf - 0.1), 0.08, IRON, "Metal")
	end
end

-- A pendant lamp hanging from a ceiling at height `ceil`.
local function pendant(r: R, x: number, z: number, ceil: number, color: Color3, lit: boolean)
	r:cyl(x, ceil - 0.06, z, 0.12, 0.45, "y", IRON, "Metal")
	r:cyl(x, ceil - 0.85, z, 1.5, 0.05, "y", IRON, "SmoothPlastic")
	r:cyl(x, ceil - 1.72, z, 0.28, 0.5, "y", color, "Metal")
	r:cyl(x, ceil - 1.98, z, 0.3, 1.2, "y", color, "Metal")
	local bulb = r:ball(x, ceil - 2.12, z, 0.42, C.Warm, "SmoothPlastic")
	if lit then
		r:glow(bulb, 20, 1.2)
	else
		r:glow(bulb, 0)
	end
end

-- A potted shrub clipped into a ball, standing at (x, z) on the ground.
local function topiary(r: R, x: number, y: number, z: number, pot: Color3)
	r:cyl(x, y + 0.5, z, 1.0, 1.1, "y", pot, "SmoothPlastic")
	r:cyl(x, y + 1.02, z, 0.1, 1.2, "y", shade(pot, 1.1), "SmoothPlastic")
	r:cyl(x, y + 1.5, z, 0.9, 0.14, "y", C.Bark, "Wood")
	r:ball(x, y + 2.3, z, 1.3, C.DarkLeaf, "Grass")
end

-- The shell of a little shop, 20 wide and 13 deep with its door in the middle of the front:
-- a floor, walls up to a parapet, a shopfront with two big windows and an open double door,
-- a fascia with a sign board, a cornice, a flat roof, a striped awning and lights inside.
type Shop = {
	wall: Color3,
	wallMat: string,
	inner: Color3,
	trim: Color3,
	base: Color3,
	floor: Color3,
	floorMat: string,
	stripe1: Color3,
	stripe2: Color3,
	board: Color3,
}

local HX, HZ, T = 10, 6.5, 0.6 -- half width, half depth, wall thickness
local TOP = 12.8 -- top of the walls (the roof deck sits lower, inside the parapet)
local CEIL = 11.4 -- the ceiling inside

local function shopShell(r: R, s: Shop)
	local zf = HZ - T -- the inside face of the front wall
	-- the floor, a step at the door and a plinth round the foot of the walls
	r:block(-HX - 0.2, 0, -HZ - 0.2, HX + 0.2, 0.4, HZ + 0.2, s.floor, s.floorMat)
	r:block(-3.4, 0, HZ + 0.2, 3.4, 0.2, HZ + 1.2, DARK_STONE, "Concrete")
	r:block(-HX - 0.06, 0.4, -HZ - 0.06, HX + 0.06, 1.0, -HZ + 0.1, s.base, "Concrete")
	for _, sx in { -1, 1 } do
		r:block(
			math.min(sx * HX, sx * (HX + 0.06)),
			0.4,
			-HZ - 0.06,
			math.max(sx * HX, sx * (HX + 0.06)),
			1.0,
			HZ,
			s.base,
			"Concrete"
		)
	end
	-- back and side walls, painted inside with a skirting board
	r:block(-HX, 0.4, -HZ, HX, TOP, -HZ + T, s.wall, s.wallMat)
	for _, sx in { -1, 1 } do
		r:block(
			math.min(sx * HX, sx * (HX - T)),
			0.4,
			-HZ + T,
			math.max(sx * HX, sx * (HX - T)),
			TOP,
			HZ,
			s.wall,
			s.wallMat
		)
		r:block(
			math.min(sx * (HX - T), sx * (HX - T - 0.05)),
			0.4,
			-HZ + T,
			math.max(sx * (HX - T), sx * (HX - T - 0.05)),
			CEIL,
			zf,
			s.inner,
			"SmoothPlastic"
		)
		r:block(
			math.min(sx * (HX - T), sx * (HX - T - 0.12)),
			0.4,
			-HZ + T,
			math.max(sx * (HX - T), sx * (HX - T - 0.12)),
			0.9,
			zf,
			s.trim,
			"Wood"
		)
	end
	r:block(-HX + T, 0.4, -HZ + T, HX - T, CEIL, -HZ + T + 0.05, s.inner, "SmoothPlastic")
	r:block(-HX + T, 0.4, -HZ + T, HX - T, 0.9, -HZ + T + 0.12, s.trim, "Wood")
	-- the shopfront: bulkheads under two big windows, framed and split by a mullion and transom
	for _, sx in { -1, 1 } do
		local xo, xi = sx * (HX - T), sx * 3.6
		local x1, x2 = math.min(xo, xi), math.max(xo, xi)
		r:block(x1, 0.4, zf, x2, 2.2, HZ + 0.05, s.base, "Wood")
		r:block(x1 + 0.3, 0.75, HZ + 0.05, x2 - 0.3, 1.85, HZ + 0.09, shade(s.base, 1.15), "Wood")
		r:block(x1 - 0.1, 2.2, zf - 0.1, x2 + 0.1, 2.45, HZ + 0.3, s.trim, "Wood")
		r:glass(x1 + 0.3, 2.45, HZ - 0.35, x2 - 0.3, 8.8, HZ - 0.25)
		r:block(x1, 2.45, zf, x1 + 0.3, 8.8, HZ, s.trim, "Wood")
		r:block(x2 - 0.3, 2.45, zf, x2, 8.8, HZ, s.trim, "Wood")
		local xm = (x1 + x2) / 2
		r:block(xm - 0.08, 2.45, HZ - 0.4, xm + 0.08, 8.8, HZ - 0.12, s.trim, "Wood")
		r:block(x1 + 0.3, 7.25, HZ - 0.4, x2 - 0.3, 7.4, HZ - 0.12, s.trim, "Wood")
		-- the jamb between the window and the door, then the door frame
		r:block(math.min(sx * 3.0, sx * 3.6), 0.4, zf, math.max(sx * 3.0, sx * 3.6), 8.8, HZ + 0.05, s.trim, "Wood")
		r:block(
			math.min(sx * 2.7, sx * 3.0),
			0.4,
			zf - 0.1,
			math.max(sx * 2.7, sx * 3.0),
			8.8,
			HZ + 0.12,
			shade(s.trim, 0.9),
			"Wood"
		)
	end
	r:block(-HX + T, 8.8, zf, HX - T, 9.3, HZ + 0.08, s.trim, "Wood")
	-- the two door leaves, propped open against the inside of the front wall
	for _, sx in { -1, 1 } do
		local x = sx * 2.62
		local za, zb = zf - 2.6, zf - 0.05
		r:block(x - 0.07, 0.4, za, x + 0.07, 8.5, za + 0.2, s.base, "Wood")
		r:block(x - 0.07, 0.4, zb - 0.2, x + 0.07, 8.5, zb, s.base, "Wood")
		r:block(x - 0.07, 0.4, za + 0.2, x + 0.07, 1.4, zb - 0.2, s.base, "Wood")
		r:block(x - 0.07, 8.2, za + 0.2, x + 0.07, 8.5, zb - 0.2, s.base, "Wood")
		r:glass(x - 0.03, 1.4, za + 0.2, x + 0.03, 8.2, zb - 0.2)
		r:block(x + sx * 0.07, 4.2, za + 0.35, x + sx * 0.15, 5.4, za + 0.45, C.Gold, "Metal")
	end
	-- the fascia above, a framed sign board, a cornice and a parapet with a raised middle
	r:block(-HX, 9.3, zf, HX, TOP, HZ, s.wall, s.wallMat)
	r:block(-6.2, 9.55, HZ, 6.2, 11.45, HZ + 0.16, s.board, "Wood")
	for _, y in { 9.45, 11.45 } do
		r:block(-6.3, y, HZ, 6.3, y + 0.12, HZ + 0.24, s.trim, "Wood")
	end
	r:block(-HX - 0.3, 11.75, HZ, HX + 0.3, 12.2, HZ + 0.45, s.trim, "Wood")
	for _, sx in { -1, 1 } do
		r:block(
			math.min(sx * HX, sx * (HX + 0.3)),
			11.75,
			-HZ,
			math.max(sx * HX, sx * (HX + 0.3)),
			12.2,
			HZ + 0.45,
			s.trim,
			"Wood"
		)
	end
	r:block(-4.2, TOP, zf, 4.2, 14.0, HZ, s.wall, s.wallMat)
	r:block(-4.4, 14.0, zf - 0.1, 4.4, 14.25, HZ + 0.1, s.trim, "Wood")
	r:block(-HX - 0.1, TOP, zf - 0.1, -4.2, TOP + 0.2, HZ + 0.1, s.trim, "Wood")
	r:block(4.2, TOP, zf - 0.1, HX + 0.1, TOP + 0.2, HZ + 0.1, s.trim, "Wood")
	r:block(-HX - 0.1, TOP, -HZ - 0.1, HX + 0.1, TOP + 0.2, -HZ + T + 0.1, s.trim, "Wood")
	for _, sx in { -1, 1 } do
		r:block(
			math.min(sx * (HX + 0.1), sx * (HX - T - 0.1)),
			TOP,
			-HZ + T + 0.1,
			math.max(sx * (HX + 0.1), sx * (HX - T - 0.1)),
			TOP + 0.2,
			zf - 0.1,
			s.trim,
			"Wood"
		)
	end
	r:block(-HX + T, CEIL, -HZ + T, HX - T, CEIL + 0.4, zf, Color3.fromRGB(120, 116, 112), "Concrete")
	r:block(-HX + T, CEIL - 0.04, -HZ + T, HX - T, CEIL, zf, CREAM, "SmoothPlastic")
	-- the back and sides: windows, a staff door under a little canopy, a bin and a down pipe
	local pane = Color3.fromRGB(120, 150, 172)
	for _, x in { -6.2, -2.2 } do
		r:block(x - 1.0, 3.2, -HZ - 0.05, x + 1.0, 7.8, -HZ, pane, "Glass")
		r:block(x - 1.2, 2.95, -HZ - 0.35, x + 1.2, 3.2, -HZ, s.trim, "Wood")
		r:block(x - 1.15, 7.8, -HZ - 0.2, x + 1.15, 8.1, -HZ, s.trim, "Wood")
		for _, dx in { -1.07, 1.07 } do
			r:block(x + dx - 0.08, 3.2, -HZ - 0.12, x + dx + 0.08, 7.8, -HZ, s.trim, "Wood")
		end
		r:block(x - 0.05, 3.2, -HZ - 0.1, x + 0.05, 7.8, -HZ, s.trim, "Wood")
		r:block(x - 1.0, 5.45, -HZ - 0.1, x + 1.0, 5.55, -HZ, s.trim, "Wood")
	end
	for _, sx in { -1, 1 } do
		local xa, xb = sx * HX, sx * (HX + 0.05)
		r:block(math.min(xa, xb), 3.2, -0.7, math.max(xa, xb), 7.8, 1.7, pane, "Glass")
		local xs = sx * (HX + 0.3)
		r:block(math.min(xa, xs), 2.95, -0.9, math.max(xa, xs), 3.2, 1.9, s.trim, "Wood")
		r:block(math.min(xa, sx * (HX + 0.2)), 7.8, -0.85, math.max(xa, sx * (HX + 0.2)), 8.1, 1.85, s.trim, "Wood")
		r:block(math.min(xa, sx * (HX + 0.1)), 3.2, 0.45, math.max(xa, sx * (HX + 0.1)), 7.8, 0.55, s.trim, "Wood")
	end
	r:block(3.9, 0.4, -HZ - 0.12, 6.1, 8.0, -HZ, s.trim, "Wood")
	r:block(4.15, 0.4, -HZ - 0.2, 5.85, 7.75, -HZ - 0.12, s.base, "Wood")
	r:block(4.4, 4.4, -HZ - 0.23, 5.6, 7.3, -HZ - 0.2, shade(s.base, 1.15), "Wood")
	r:ball(4.4, 3.9, -HZ - 0.28, 0.16, C.Gold, "Metal")
	r:block(3.6, 8.3, -HZ - 1.3, 6.4, 8.5, -HZ, s.trim, "Wood")
	for _, x in { 3.8, 6.2 } do
		r:beam(Vector3.new(x, 7.1, -HZ), Vector3.new(x, 8.3, -HZ - 1.1), 0.12, 0.12, s.trim, "Wood")
	end
	r:block(3.8, 0, -HZ - 1.0, 6.2, 0.3, -HZ - 0.2, DARK_STONE, "Concrete")
	r:cyl(7.6, 0.85, -HZ - 0.8, 1.7, 1.1, "y", Color3.fromRGB(52, 98, 72), "Metal")
	r:cyl(7.6, 1.75, -HZ - 0.8, 0.1, 1.2, "y", shade(Color3.fromRGB(52, 98, 72), 0.8), "Metal")
	r:cyl(-HX + 0.35, 6.6, -HZ - 0.15, 12.4, 0.22, "y", s.trim, "Metal")
	r:block(-HX + 0.1, 12.4, -HZ - 0.4, -HX + 0.6, 12.8, -HZ, s.trim, "Metal")
	-- an air unit, a vent pipe and a hatch on the roof
	r:block(3.0, CEIL + 0.4, -4.4, 6.0, CEIL + 1.9, -2.4, Color3.fromRGB(200, 202, 206), "Metal")
	r:cyl(4.5, CEIL + 1.92, -3.4, 0.06, 1.6, "y", Color3.fromRGB(90, 92, 98), "Metal")
	r:cyl(-5.5, CEIL + 1.1, -3.5, 1.4, 0.5, "y", Color3.fromRGB(150, 152, 156), "Metal")
	r:cyl(-5.5, CEIL + 1.85, -3.5, 0.1, 0.7, "y", Color3.fromRGB(150, 152, 156), "Metal")
	r:block(-2.0, CEIL + 0.4, 1.0, 0.0, CEIL + 0.65, 3.0, Color3.fromRGB(140, 136, 130), "Metal")
	awning(r, -HX + 0.4, HX - 0.4, HZ, 9.25, 3.0, 1.4, s.stripe1, s.stripe2)
	-- lights inside
	pendant(r, -4.5, 0, CEIL, s.board, true)
	pendant(r, 4.5, 0, CEIL, s.board, true)
	pendant(r, 0, -3, CEIL, s.board, false)
	-- a projecting sign on a bracket at the corner
	rod(r, Vector3.new(HX - 1.1, 10.9, HZ), Vector3.new(HX - 1.1, 10.9, HZ + 2.1), 0.1, IRON, "Metal")
	r:block(HX - 1.16, 9.5, HZ + 0.4, HX - 1.04, 10.75, HZ + 1.9, s.board, "Wood")
	for _, z in { HZ + 0.6, HZ + 1.7 } do
		r:block(HX - 1.12, 10.75, z - 0.02, HX - 1.08, 10.9, z + 0.02, IRON, "Metal")
	end
end

-- A dress form: a stand, a flared skirt, a bodice and a head.
local function mannequin(r: R, x: number, y: number, z: number, dress: Color3)
	r:cyl(x, y + 0.06, z, 0.12, 1.2, "y", IRON, "Metal")
	r:cyl(x, y + 1.25, z, 2.3, 0.12, "y", IRON, "Metal")
	r:cyl(x, y + 2.7, z, 0.7, 1.7, "y", dress, "Fabric")
	r:cyl(x, y + 3.35, z, 0.65, 1.25, "y", dress, "Fabric")
	r:cyl(x, y + 3.9, z, 0.45, 0.85, "y", shade(dress, 0.85), "Fabric")
	r:cyl(x, y + 4.5, z, 0.75, 1.1, "y", dress, "Fabric")
	r:cyl(x, y + 5.05, z, 0.35, 0.26, "y", SKIN, "SmoothPlastic")
	r:ball(x, y + 5.5, z, 0.7, SKIN, "SmoothPlastic")
end

-- A clothes rail running along z at x, from z1 to z2, with garments hung side on.
local function clothesRail(r: R, x: number, y: number, z1: number, z2: number, colors: { Color3 })
	for _, z in { z1, z2 } do
		rod(r, Vector3.new(x, y, z), Vector3.new(x, y + 5.5, z), 0.12, IRON, "Metal")
		r:block(x - 0.6, y, z - 0.06, x + 0.6, y + 0.08, z + 0.06, IRON, "Metal")
	end
	rod(r, Vector3.new(x, y + 5.35, z1), Vector3.new(x, y + 5.35, z2), 0.1, C.Metal, "Metal")
	local step = (z2 - z1) / #colors
	for i, col in colors do
		local z = z1 + (i - 0.5) * step
		r:block(x - 0.55, y + 5.05, z - 0.03, x + 0.55, y + 5.13, z + 0.03, DARK_WOOD, "Wood")
		local long = i % 3 == 0
		r:block(x - 0.6, y + (if long then 2.2 else 3.1), z - 0.13, x + 0.6, y + 5.05, z + 0.13, col, "Fabric")
	end
end

TownModels.Models = {}

TownModels.Models.fountain = function(r: R)
	local light = Color3.fromRGB(222, 216, 204)
	-- a wide step, then a basin wall with a coping round it
	r:cyl(0, 0.15, 0, 0.3, 18.2, "y", DARK_STONE, "Cobblestone")
	ring(r, 0, 1.1, 0, 7.9, 0.9, 1.6, STONE, "Cobblestone", 16)
	ring(r, 0, 2.0, 0, 7.9, 1.25, 0.25, light, "Marble", 16)
	r:cyl(0, 0.4, 0, 0.2, 15.2, "y", Color3.fromRGB(70, 104, 112), "Slate")
	water(r:cyl(0, 1.55, 0, 0.12, 15.0, "y", C.Water, "Glass"))
	-- a carved column holding a wide bowl, then a slimmer column and a small bowl
	r:cyl(0, 0.95, 0, 1.3, 3.0, "y", STONE, "Marble")
	r:cyl(0, 1.75, 0, 0.3, 2.2, "y", light, "Marble")
	r:cyl(0, 3.0, 0, 2.2, 1.3, "y", STONE, "Marble")
	r:cyl(0, 4.15, 0, 0.3, 1.8, "y", light, "Marble")
	r:cyl(0, 4.45, 0, 0.3, 2.6, "y", STONE, "Marble")
	r:cyl(0, 4.75, 0, 0.3, 5.0, "y", STONE, "Marble")
	r:cyl(0, 5.1, 0, 0.4, 7.0, "y", light, "Marble")
	water(r:cyl(0, 5.31, 0, 0.1, 6.6, "y", C.Water, "Glass"))
	r:cyl(0, 6.3, 0, 2.0, 0.9, "y", STONE, "Marble")
	r:cyl(0, 6.6, 0, 0.25, 1.3, "y", light, "Marble")
	r:cyl(0, 7.4, 0, 0.2, 1.6, "y", STONE, "Marble")
	r:cyl(0, 7.65, 0, 0.3, 2.8, "y", STONE, "Marble")
	r:cyl(0, 7.95, 0, 0.3, 3.6, "y", light, "Marble")
	water(r:cyl(0, 8.14, 0, 0.1, 3.2, "y", C.Water, "Glass"))
	r:cyl(0, 8.5, 0, 0.8, 0.55, "y", STONE, "Marble")
	r:cyl(0, 8.95, 0, 0.15, 0.85, "y", light, "Marble")
	local top = r:ball(0, 9.4, 0, 0.9, C.Water, "Glass")
	top.name = "Spout" -- the client sprays water from here
	top.transp = 0.2
	top.effect = "sparkles"
	-- water falling from each bowl into the one below
	for i = 0, 5 do
		local a = i / 6 * math.pi * 2 + math.pi / 6
		water(r:cyl(math.cos(a) * 1.72, 6.65, math.sin(a) * 1.72, 2.8, 0.16, "y", C.Water, "Glass"), 0.4)
	end
	for i = 0, 7 do
		local a = i / 8 * math.pi * 2
		water(r:cyl(math.cos(a) * 3.45, 3.3, math.sin(a) * 3.45, 3.6, 0.2, "y", C.Water, "Glass"), 0.4)
	end
end

TownModels.Models.board = function(r: R)
	local cork = Color3.fromRGB(196, 150, 100)
	local roof = Color3.fromRGB(194, 126, 99)
	-- two posts with caps, holding a framed cork board under a little gabled roof
	for _, x in { -4.45, 4.45 } do
		r:box(x, 4.05, 0, 0.6, 8.1, 0.6, DARK_WOOD, "Wood")
		r:block(x - 0.4, 0, -0.4, x + 0.4, 0.3, 0.4, DARK_STONE, "Concrete")
	end
	r:block(-4.3, 2.3, -0.2, 4.3, 7.2, 0.15, cork, "WoodPlanks")
	r:block(-4.15, 7.2, -0.3, 4.15, 7.45, 0.3, WOOD, "Wood")
	r:block(-4.15, 2.05, -0.3, 4.15, 2.3, 0.3, WOOD, "Wood")
	r:block(-4.15, 2.05, 0.3, 4.15, 2.15, 0.7, WOOD, "Wood")
	r:quad(
		Vector3.new(-4.8, 8.1, 1.05),
		Vector3.new(4.8, 8.1, 1.05),
		Vector3.new(4.8, 8.95, 0),
		Vector3.new(-4.8, 8.95, 0),
		0.18,
		roof,
		"Slate"
	)
	r:quad(
		Vector3.new(-4.8, 8.1, -1.05),
		Vector3.new(4.8, 8.1, -1.05),
		Vector3.new(4.8, 8.95, 0),
		Vector3.new(-4.8, 8.95, 0),
		0.18,
		roof,
		"Slate"
	)
	r:block(-4.85, 8.85, -0.15, 4.85, 9.1, 0.15, shade(roof, 0.8), "Slate")
	r:block(-4.7, 7.45, -0.35, 4.7, 8.15, 0.35, WOOD, "WoodPlanks")
	-- notes pinned on it, and a poster with a little map
	local notes: { { x: number, y: number, w: number, h: number, c: Color3 } } = {
		{ x = -3.1, y = 5.7, w = 1.4, h = 1.6, c = C.Paper },
		{ x = -1.3, y = 6.1, w = 1.2, h = 1.2, c = C.Yellow },
		{ x = 2.9, y = 5.9, w = 1.3, h = 1.5, c = C.Pink },
		{ x = -2.5, y = 3.6, w = 1.5, h = 1.3, c = Color3.fromRGB(190, 222, 240) },
		{ x = -0.6, y = 3.9, w = 1.2, h = 1.5, c = C.Paper },
		{ x = 2.5, y = 3.6, w = 1.6, h = 1.2, c = C.Paper },
	}
	for i, n in notes do
		r:boxAt(
			CFrame.new(n.x, n.y, 0.18) * CFrame.Angles(0, 0, (i % 3 - 1) * 0.06),
			n.w,
			n.h,
			0.04,
			n.c,
			"SmoothPlastic"
		)
		r:ball(n.x, n.y + n.h / 2 - 0.15, 0.24, 0.16, if i % 2 == 0 then C.Red else C.Blue, "SmoothPlastic")
	end
	r:block(0.15, 4.6, 0.15, 1.75, 6.6, 0.2, C.Paper, "SmoothPlastic")
	r:block(0.3, 4.8, 0.2, 1.6, 6.0, 0.24, Color3.fromRGB(150, 196, 120), "SmoothPlastic")
	r:block(0.3, 5.3, 0.24, 1.6, 5.4, 0.28, Color3.fromRGB(90, 150, 210), "SmoothPlastic")
	r:block(0.3, 6.15, 0.2, 1.6, 6.45, 0.24, C.Red, "SmoothPlastic")
end

TownModels.Models.tailor = function(r: R)
	local plum = Color3.fromRGB(196, 100, 140)
	shopShell(r, {
		wall = Color3.fromRGB(242, 192, 204),
		wallMat = "Plaster",
		inner = Color3.fromRGB(250, 238, 232),
		trim = CREAM,
		base = plum,
		floor = Color3.fromRGB(214, 180, 140),
		floorMat = "WoodPlanks",
		stripe1 = Color3.fromRGB(232, 140, 160),
		stripe2 = CREAM,
		board = plum,
	})
	local F = 0.4 -- the floor inside
	-- a coat hanger picked out on the sign board, with a dot either side
	local hz = HZ + 0.2
	r:cyl(0, 11.0, hz, 0.06, 0.32, "z", CREAM, "SmoothPlastic")
	r:cyl(0, 11.0, hz + 0.04, 0.07, 0.16, "z", plum, "SmoothPlastic")
	rod(r, Vector3.new(0, 10.85, hz), Vector3.new(-1.3, 10.05, hz), 0.12, CREAM, "SmoothPlastic")
	rod(r, Vector3.new(0, 10.85, hz), Vector3.new(1.3, 10.05, hz), 0.12, CREAM, "SmoothPlastic")
	rod(r, Vector3.new(-1.35, 10.0, hz), Vector3.new(1.35, 10.0, hz), 0.12, CREAM, "SmoothPlastic")
	for _, x in { -3.2, 3.2 } do
		r:cyl(x, 10.5, hz, 0.06, 0.5, "z", Color3.fromRGB(232, 140, 160), "SmoothPlastic")
	end
	-- dress forms in both windows, and potted shrubs by the door
	mannequin(r, -6.5, F, 4.3, Color3.fromRGB(232, 140, 160))
	mannequin(r, 6.5, F, 4.3, Color3.fromRGB(110, 160, 200))
	topiary(r, -4.3, 0, HZ + 0.9, plum)
	topiary(r, 4.3, 0, HZ + 0.9, plum)
	-- a chalk board out front
	for _, s in { -1, 1 } do
		r:boxAt(
			CFrame.new(-7.0, 1.55, HZ + 2.0 + s * 0.35) * CFrame.Angles(-s * 0.22, 0, 0),
			1.5,
			3.1,
			0.12,
			DARK_WOOD,
			"Wood"
		)
		r:boxAt(
			CFrame.new(-7.0, 1.7, HZ + 2.0 + s * 0.42) * CFrame.Angles(-s * 0.22, 0, 0),
			1.2,
			2.3,
			0.04,
			Color3.fromRGB(46, 60, 54),
			"SmoothPlastic"
		)
	end
	for i, w in { 0.9, 0.6, 0.75 } do
		local y = 2.4 - i * 0.4
		local cf = CFrame.new(-7.0, 1.7, HZ + 2.49) * CFrame.Angles(-0.22, 0, 0) * CFrame.new(-0.45 + w / 2, y - 1.7, 0)
		r:boxAt(cf, w, 0.08, 0.02, CREAM, "SmoothPlastic")
	end
	-- a long rail of clothes down the left wall
	clothesRail(r, -8.5, F, -2.4, 3.4, {
		Color3.fromRGB(232, 140, 160),
		C.Cream,
		Color3.fromRGB(110, 160, 200),
		Color3.fromRGB(143, 179, 154),
		Color3.fromRGB(240, 200, 110),
		Color3.fromRGB(196, 160, 230),
		C.White,
		Color3.fromRGB(200, 90, 90),
	})
	-- a fitting room in the back left corner: a partition and a curtain on a rail
	r:block(-6.5, F, -HZ + T, -6.3, 8.0, -3.0, CREAM, "Wood")
	r:cyl(-7.9, 8.0, -3.0, 2.8, 0.1, "x", C.Gold, "Metal")
	for i = 0, 3 do
		local x1 = -9.3 + i * 0.7
		r:block(
			x1,
			F + 0.3,
			if i % 2 == 0 then -3.1 else -2.95,
			x1 + 0.7,
			7.9,
			if i % 2 == 0 then -2.95 else -2.8,
			if i % 2 == 0 then plum else shade(plum, 1.15),
			"Fabric"
		)
	end
	-- a long mirror on the back wall and a padded pouf to sit on
	r:block(-5.4, 1.1, -HZ + T + 0.05, -2.8, 8.2, -HZ + T + 0.25, C.Gold, "Metal")
	r:block(-5.2, 1.3, -HZ + T + 0.25, -3.0, 8.0, -HZ + T + 0.3, Color3.fromRGB(205, 225, 234), "Glass")
	r:cyl(-2.0, F + 0.7, 1.0, 1.4, 1.6, "y", Color3.fromRGB(232, 140, 160), "Fabric")
	r:cyl(-2.0, F + 1.42, 1.0, 0.04, 1.3, "y", shade(Color3.fromRGB(232, 140, 160), 0.8), "Fabric")
	r:seat(-2.0, F + 1.44, 1.0, 90)
	r:noCollide(r:block(-3.2, F, -1.5, 3.2, F + 0.04, 3.0, Color3.fromRGB(236, 210, 200), "Carpet"))
	-- a round table of folded clothes and a hat
	r:cyl(-4.6, F + 0.05, -0.6, 0.1, 1.2, "y", CREAM, "Wood")
	r:cyl(-4.6, F + 1.4, -0.6, 2.7, 0.3, "y", CREAM, "Wood")
	r:cyl(-4.6, F + 2.8, -0.6, 0.15, 2.4, "y", CREAM, "Wood")
	for i, col in { Color3.fromRGB(110, 160, 200), C.Cream, Color3.fromRGB(232, 140, 160) } do
		local a = i * math.pi * 2 / 3
		r:block(
			-4.6 + math.cos(a) * 0.6 - 0.35,
			F + 2.88,
			-0.6 + math.sin(a) * 0.6 - 0.3,
			-4.6 + math.cos(a) * 0.6 + 0.35,
			F + 3.1 + (i % 2) * 0.12,
			-0.6 + math.sin(a) * 0.6 + 0.3,
			col,
			"Fabric"
		)
	end
	r:cyl(-4.6, F + 2.92, -0.6, 0.06, 0.9, "y", Color3.fromRGB(214, 190, 140), "Fabric")
	r:cyl(-4.6, F + 3.1, -0.6, 0.3, 0.5, "y", Color3.fromRGB(214, 190, 140), "Fabric")
	-- the counter at the back, with a sewing machine and a till on it
	local top = F + 3.2
	r:block(2.6, F, -3.6, 8.6, top - 0.2, -2.2, plum, "Wood")
	for i = 0, 2 do
		local x = 3.0 + i * 1.9
		r:block(x, F + 0.4, -2.2, x + 1.6, top - 0.6, -2.14, shade(plum, 1.18), "Wood")
	end
	r:block(2.4, top - 0.2, -3.8, 8.8, top, -2.0, CREAM, "Marble")
	r:block(3.4, top, -3.3, 5.4, top + 0.25, -2.5, C.White, "Metal")
	r:block(3.6, top + 0.25, -3.1, 3.95, top + 1.4, -2.7, C.White, "Metal")
	r:block(3.6, top + 1.15, -3.1, 5.2, top + 1.5, -2.7, C.White, "Metal")
	r:block(4.95, top + 0.6, -3.05, 5.15, top + 1.15, -2.75, C.White, "Metal")
	r:cyl(3.5, top + 1.2, -2.9, 0.15, 0.7, "x", C.DarkMetal, "Metal")
	r:cyl(4.4, top + 1.6, -2.9, 0.3, 0.3, "y", Color3.fromRGB(232, 140, 160), "Fabric")
	r:block(6.6, top, -3.4, 7.8, top + 0.6, -2.5, C.DarkMetal, "Metal")
	r:boxAt(CFrame.new(7.2, top + 0.9, -3.15) * CFrame.Angles(-0.3, 0, 0), 1.0, 0.6, 0.08, C.Black, "SmoothPlastic")
	-- shelves of fabric rolls behind the counter
	for _, y in { 2.6, 4.4, 6.2 } do
		r:block(2.6, y, -HZ + T, HX - T, y + 0.15, -HZ + T + 1.0, CREAM, "Wood")
		for i, col in
			{
				Color3.fromRGB(200, 90, 90),
				Color3.fromRGB(110, 160, 200),
				Color3.fromRGB(240, 200, 110),
				Color3.fromRGB(143, 179, 154),
			}
		do
			r:cyl(
				3.2 + (i - 1) * 1.55,
				y + 0.43,
				-HZ + T + 0.5,
				0.56,
				0.56,
				"y",
				if y > 4 then shade(col, 1.1) else col,
				"Fabric"
			)
		end
	end
end

TownModels.Models.shop = function(r: R)
	local green = Color3.fromRGB(72, 146, 104)
	shopShell(r, {
		wall = Color3.fromRGB(243, 223, 166),
		wallMat = "Plaster",
		inner = Color3.fromRGB(255, 248, 228),
		trim = CREAM,
		base = green,
		floor = Color3.fromRGB(236, 232, 222),
		floorMat = "Marble",
		stripe1 = Color3.fromRGB(108, 170, 124),
		stripe2 = CREAM,
		board = green,
	})
	local F = 0.4
	local fruit = {
		C.Red,
		Color3.fromRGB(245, 150, 50),
		C.Yellow,
		Color3.fromRGB(130, 190, 80),
		Color3.fromRGB(150, 70, 140),
		Color3.fromRGB(230, 80, 60),
	}
	-- an apple and a pear on the sign board
	local hz = HZ + 0.25
	r:ball(-0.8, 10.45, hz, 1.2, C.Red, "SmoothPlastic")
	r:block(-0.84, 11.0, hz - 0.05, -0.76, 11.4, hz + 0.05, C.Bark, "Wood")
	r:boxAt(CFrame.new(-0.5, 11.25, hz) * CFrame.Angles(0, 0, -0.6), 0.45, 0.2, 0.06, C.Leaf, "SmoothPlastic")
	r:ball(0.8, 10.3, hz, 0.95, Color3.fromRGB(200, 210, 90), "SmoothPlastic")
	r:ball(0.8, 10.85, hz, 0.6, Color3.fromRGB(200, 210, 90), "SmoothPlastic")
	r:block(0.77, 11.1, hz - 0.04, 0.83, 11.35, hz + 0.04, C.Bark, "Wood")
	-- crates of fruit on stands either side of the door, under the awning
	for _, sx in { -1, 1 } do
		local x1, x2 = math.min(sx * 3.9, sx * 9.2), math.max(sx * 3.9, sx * 9.2)
		r:block(x1, 0, HZ + 0.35, x2, 1.0, HZ + 2.4, DARK_WOOD, "WoodPlanks")
		for i = 0, 2 do
			local cx = x1 + 0.9 + i * 1.75
			local front = fruit[(i + (if sx > 0 then 3 else 0)) % #fruit + 1]
			local back = fruit[(i + (if sx > 0 then 1 else 4)) % #fruit + 1]
			r:block(cx - 0.8, 1.0, HZ + 1.35, cx + 0.8, 1.7, HZ + 2.4, WOOD, "WoodPlanks")
			r:block(cx - 0.7, 1.7, HZ + 1.45, cx + 0.7, 1.85, HZ + 2.3, front, "SmoothPlastic")
			r:ball(cx - 0.3, 1.9, HZ + 1.9, 0.5, front, "SmoothPlastic")
			r:ball(cx + 0.3, 1.92, HZ + 1.8, 0.5, shade(front, 1.1), "SmoothPlastic")
			r:block(cx - 0.8, 1.0, HZ + 0.4, cx + 0.8, 2.4, HZ + 1.35, WOOD, "WoodPlanks")
			r:block(cx - 0.7, 2.4, HZ + 0.5, cx + 0.7, 2.55, HZ + 1.25, back, "SmoothPlastic")
			r:ball(cx, 2.62, HZ + 0.88, 0.5, shade(back, 1.1), "SmoothPlastic")
		end
	end
	-- tall shelves of goods down the left wall
	local x1, x2 = -HX + T, -HX + T + 1.4
	for _, z in { -4.6, 3.4 } do
		r:block(x1, F, z, x2, F + 6.0, z + 0.15, CREAM, "Wood")
	end
	r:block(x1, F, -4.45, x2, F + 0.5, 3.4, green, "Wood")
	local goods = {
		Color3.fromRGB(230, 80, 60),
		Color3.fromRGB(245, 200, 80),
		Color3.fromRGB(90, 150, 210),
		Color3.fromRGB(240, 240, 230),
		Color3.fromRGB(130, 190, 80),
		Color3.fromRGB(245, 150, 50),
	}
	for k, y in { F + 0.5, F + 1.9, F + 3.3, F + 4.7 } do
		r:block(x1, y, -4.45, x2, y + 0.12, 3.4, CREAM, "Wood")
		for i = 0, 3 do
			local z = -4.3 + i * 1.95
			r:block(x1 + 0.1, y + 0.12, z, x2 - 0.15, y + 1.1, z + 1.7, goods[(i + k) % #goods + 1], "SmoothPlastic")
		end
	end
	-- a double sided shelf in the middle of the floor
	r:block(-5.8, F, -3.4, -4.2, F + 0.45, 1.8, green, "Wood")
	r:block(-5.05, F + 0.45, -3.4, -4.95, F + 4.2, 1.8, CREAM, "Wood")
	for k, y in { F + 0.45, F + 1.75, F + 3.05 } do
		r:block(-5.8, y, -3.4, -4.2, y + 0.1, 1.8, CREAM, "Wood")
		for i = 0, 2 do
			local z = -3.25 + i * 1.7
			r:block(-5.7, y + 0.1, z, -5.1, y + 0.95, z + 1.5, goods[(i + k + 2) % #goods + 1], "SmoothPlastic")
			r:block(-4.9, y + 0.1, z, -4.3, y + 0.95, z + 1.5, goods[(i + k + 4) % #goods + 1], "SmoothPlastic")
		end
	end
	-- a glass fronted fridge on the back wall, lit inside
	local fz = -HZ + T
	r:block(0.4, F, fz, 8.6, F + 6.2, fz + 1.4, C.White, "Metal")
	r:block(0.4, F, fz + 1.4, 8.6, F + 0.6, fz + 1.45, green, "Metal")
	local inside =
		r:block(0.7, F + 0.7, fz + 0.1, 8.3, F + 5.8, fz + 0.15, Color3.fromRGB(230, 244, 250), "SmoothPlastic")
	r:glow(inside, 0)
	for k, y in { F + 0.8, F + 2.5, F + 4.2 } do
		r:block(0.7, y, fz + 0.15, 8.3, y + 0.08, fz + 1.3, C.Metal, "Metal")
		for i = 0, 5 do
			local x = 1.1 + i * 1.25
			r:block(
				x - 0.4,
				y + 0.08,
				fz + 0.4,
				x + 0.4,
				y + 1.1,
				fz + 1.1,
				goods[(i + k) % #goods + 1],
				"SmoothPlastic"
			)
		end
	end
	r:glass(0.7, F + 0.65, fz + 1.4, 8.3, F + 5.85, fz + 1.46)
	for _, x in { 3.23, 5.77 } do
		r:block(x - 0.06, F + 0.65, fz + 1.4, x + 0.06, F + 5.85, fz + 1.5, C.White, "Metal")
	end
	-- the till counter by the right window, and a stack of baskets by the door
	local top = F + 3.2
	r:block(4.6, F, 1.0, 8.6, top - 0.2, 2.6, green, "Wood")
	r:block(4.4, top - 0.2, 0.8, 8.8, top, 2.8, CREAM, "Marble")
	r:block(5.0, top, 1.3, 6.2, top + 0.5, 2.1, C.DarkMetal, "Metal")
	r:boxAt(CFrame.new(5.6, top + 0.85, 1.55) * CFrame.Angles(0.35, 0, 0), 1.0, 0.6, 0.08, C.Black, "SmoothPlastic")
	r:block(7.0, top, 1.3, 7.9, top + 0.12, 2.1, C.Metal, "Metal")
	r:cyl(7.45, top + 0.35, 1.7, 0.4, 0.6, "y", C.Metal, "Metal")
	for i = 0, 2 do
		r:block(3.5, F + i * 0.5, 3.4, 4.5, F + i * 0.5 + 0.45, 4.3, C.Red, "Plastic")
	end
end

TownModels.Models.hall = function(r: R)
	local wall = Color3.fromRGB(200, 224, 210)
	local trim = Color3.fromRGB(250, 246, 236)
	local roof = Color3.fromRGB(100, 128, 160)
	local door = Color3.fromRGB(96, 58, 36)
	-- a stone podium with steps up to a raised porch
	r:block(-10.5, 0, -7.5, 10.5, 0.6, 6.5, STONE, "Concrete")
	r:block(-9.5, 0.6, -7.0, 9.5, 1.2, 5.6, shade(STONE, 1.04), "Concrete")
	r:block(-5.5, 0, 6.5, 5.5, 0.3, 7.4, STONE, "Concrete")
	r:block(-5.5, 0.6, 5.6, 5.5, 0.9, 6.3, STONE, "Concrete")
	-- the main block: a stone base band, plaster walls, corner pilasters and a cornice
	r:block(-8, 1.2, -6.5, 8, 11.4, 1.5, wall, "Plaster")
	r:block(-8.1, 1.2, -6.6, 8.1, 2.2, 1.58, STONE, "Concrete")
	r:block(-8.2, 10.8, -6.7, 8.2, 11.0, 1.7, trim, "SmoothPlastic")
	r:block(-8.4, 11.2, -6.9, 8.4, 11.7, 1.9, trim, "SmoothPlastic")
	for _, sx in { -1, 1 } do
		r:block(
			math.min(sx * 7.35, sx * 8.08),
			2.2,
			1.4,
			math.max(sx * 7.35, sx * 8.08),
			10.8,
			1.72,
			trim,
			"SmoothPlastic"
		)
	end
	-- tall windows with panes, sills and a little pediment over each
	for _, sx in { -1, 1 } do
		local x = sx * 6.45
		r:glass(x - 0.75, 3.0, 1.45, x + 0.75, 8.2, 1.56)
		r:block(x - 0.95, 2.95, 1.5, x - 0.75, 8.2, 1.7, trim, "SmoothPlastic")
		r:block(x + 0.75, 2.95, 1.5, x + 0.95, 8.2, 1.7, trim, "SmoothPlastic")
		r:block(x - 1.05, 2.75, 1.5, x + 1.05, 2.95, 1.85, trim, "SmoothPlastic")
		r:block(x - 0.95, 8.2, 1.5, x + 0.95, 8.4, 1.75, trim, "SmoothPlastic")
		r:block(x - 0.05, 3.0, 1.55, x + 0.05, 8.2, 1.62, trim, "SmoothPlastic")
		for _, y in { 4.75, 6.5 } do
			r:block(x - 0.75, y - 0.04, 1.55, x + 0.75, y + 0.04, 1.62, trim, "SmoothPlastic")
		end
		r:block(x - 1.1, 8.4, 1.5, x + 1.1, 8.55, 1.85, trim, "SmoothPlastic")
		r:tri(
			Vector3.new(x - 1.1, 8.55, 1.7),
			Vector3.new(x + 1.1, 8.55, 1.7),
			Vector3.new(x, 9.2, 1.7),
			0.2,
			trim,
			"SmoothPlastic"
		)
		-- and one down each side
		local xs = sx * 8.0
		r:glass(math.min(xs, xs + sx * 0.08), 3.0, -3.3, math.max(xs, xs + sx * 0.08), 8.2, -1.7)
		r:block(math.min(xs, xs + sx * 0.3), 2.75, -3.5, math.max(xs, xs + sx * 0.3), 2.95, -1.5, trim, "SmoothPlastic")
		r:block(
			math.min(xs, xs + sx * 0.15),
			8.2,
			-3.45,
			math.max(xs, xs + sx * 0.15),
			8.45,
			-1.55,
			trim,
			"SmoothPlastic"
		)
		r:block(
			math.min(xs, xs + sx * 0.12),
			3.0,
			-2.55,
			math.max(xs, xs + sx * 0.12),
			8.2,
			-2.45,
			trim,
			"SmoothPlastic"
		)
	end
	-- three plainer windows across the back
	for _, x in { -4.5, 0, 4.5 } do
		r:glass(x - 0.7, 3.0, -6.58, x + 0.7, 8.2, -6.5)
		r:block(x - 0.9, 2.75, -6.85, x + 0.9, 2.95, -6.5, trim, "SmoothPlastic")
		r:block(x - 0.85, 8.2, -6.7, x + 0.85, 8.45, -6.5, trim, "SmoothPlastic")
		r:block(x - 0.05, 3.0, -6.62, x + 0.05, 8.2, -6.55, trim, "SmoothPlastic")
	end
	-- a panelled double door under a fanlight, with a lantern either side
	r:block(-2.0, 1.2, 1.5, 2.0, 7.6, 1.62, trim, "SmoothPlastic")
	for _, sx in { -1, 1 } do
		local x1, x2 = math.min(sx * 0.03, sx * 1.45), math.max(sx * 0.03, sx * 1.45)
		r:block(x1, 1.2, 1.62, x2, 6.4, 1.74, door, "Wood")
		r:block(x1 + 0.22, 1.6, 1.74, x2 - 0.22, 3.6, 1.77, shade(door, 1.15), "Wood")
		r:block(x1 + 0.22, 3.9, 1.74, x2 - 0.22, 6.0, 1.77, shade(door, 1.15), "Wood")
		r:ball(sx * 0.25, 3.8, 1.82, 0.16, C.Gold, "Metal")
		r:block(sx * 2.7 - 0.1, 4.6, 1.5, sx * 2.7 + 0.1, 4.8, 1.95, IRON, "Metal")
		r:block(sx * 2.7 - 0.25, 4.8, 1.75, sx * 2.7 + 0.25, 4.9, 2.25, IRON, "Metal")
		local lantern = r:block(sx * 2.7 - 0.2, 4.9, 1.8, sx * 2.7 + 0.2, 5.5, 2.2, C.Warm, "Glass")
		r:glow(lantern, 14, 1)
		r:block(sx * 2.7 - 0.26, 5.5, 1.74, sx * 2.7 + 0.26, 5.62, 2.26, IRON, "Metal")
	end
	r:glass(-1.45, 6.5, 1.6, 1.45, 7.45, 1.68)
	for _, x in { -0.5, 0.5 } do
		r:block(x - 0.04, 6.5, 1.62, x + 0.04, 7.45, 1.72, trim, "SmoothPlastic")
	end
	-- a porch of four columns under a pediment with a round window
	for _, x in { -4.5, -1.5, 1.5, 4.5 } do
		r:block(x - 0.55, 1.2, 4.05, x + 0.55, 1.55, 5.15, STONE, "Concrete")
		r:cyl(x, 5.6, 4.6, 8.1, 0.8, "y", trim, "Marble")
		r:cyl(x, 1.7, 4.6, 0.3, 0.95, "y", trim, "Marble")
		r:block(x - 0.6, 9.65, 4.0, x + 0.6, 10.0, 5.2, trim, "Marble")
	end
	r:block(-5.4, 10.0, 1.5, 5.4, 11.1, 5.4, trim, "SmoothPlastic")
	r:block(-5.4, 10.5, 5.4, 5.4, 10.6, 5.45, shade(trim, 0.85), "SmoothPlastic")
	r:block(-5.7, 11.1, 1.5, 5.7, 11.45, 5.7, trim, "SmoothPlastic")
	r:tri(
		Vector3.new(-5.4, 11.45, 5.45),
		Vector3.new(5.4, 11.45, 5.45),
		Vector3.new(0, 14.2, 5.45),
		0.3,
		wall,
		"Plaster"
	)
	r:beam(Vector3.new(-5.85, 11.35, 5.6), Vector3.new(0.05, 14.5, 5.6), 0.5, 0.35, trim, "SmoothPlastic")
	r:beam(Vector3.new(5.85, 11.35, 5.6), Vector3.new(-0.05, 14.5, 5.6), 0.5, 0.35, trim, "SmoothPlastic")
	for _, sx in { -1, 1 } do
		r:quad(
			Vector3.new(sx * 5.9, 11.55, 5.75),
			Vector3.new(0, 14.62, 5.75),
			Vector3.new(0, 14.62, 1.5),
			Vector3.new(sx * 5.9, 11.55, 1.5),
			0.3,
			roof,
			"Slate"
		)
	end
	r:cyl(0, 12.5, 5.6, 0.12, 1.5, "z", trim, "SmoothPlastic")
	r:cyl(0, 12.5, 5.7, 0.04, 1.1, "z", Color3.fromRGB(150, 180, 200), "Glass")
	-- a slate roof along the main block, with plaster gable ends
	r:quad(
		Vector3.new(-8.5, 11.7, 2.0),
		Vector3.new(8.5, 11.7, 2.0),
		Vector3.new(8.5, 15.2, -2.5),
		Vector3.new(-8.5, 15.2, -2.5),
		0.35,
		roof,
		"Slate"
	)
	r:quad(
		Vector3.new(-8.5, 11.7, -7.0),
		Vector3.new(8.5, 11.7, -7.0),
		Vector3.new(8.5, 15.2, -2.5),
		Vector3.new(-8.5, 15.2, -2.5),
		0.35,
		roof,
		"Slate"
	)
	r:block(-8.6, 15.05, -2.75, 8.6, 15.35, -2.25, shade(roof, 0.8), "Slate")
	for _, sx in { -1, 1 } do
		r:tri(
			Vector3.new(sx * 8.1, 11.7, 1.75),
			Vector3.new(sx * 8.1, 11.7, -6.75),
			Vector3.new(sx * 8.1, 15.0, -2.5),
			0.3,
			wall,
			"Plaster"
		)
	end
	-- a clock tower on the ridge with a bell, a pointed roof and a flag
	local cz = -2.5
	r:block(-1.4, 14.2, cz - 1.4, 1.4, 16.6, cz + 1.4, wall, "Plaster")
	r:block(-1.6, 16.6, cz - 1.6, 1.6, 16.9, cz + 1.6, trim, "SmoothPlastic")
	r:cyl(0, 15.45, cz + 1.42, 0.06, 1.9, "z", trim, "SmoothPlastic")
	r:cyl(0, 15.45, cz + 1.47, 0.04, 1.6, "z", C.Cream, "SmoothPlastic")
	r:block(-0.05, 15.45, cz + 1.49, 0.05, 16.1, cz + 1.52, C.Black, "SmoothPlastic")
	r:block(-0.05, 15.4, cz + 1.49, 0.5, 15.5, cz + 1.52, C.Black, "SmoothPlastic")
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			r:box(sx * 1.25, 17.9, cz + sz * 1.25, 0.3, 2.0, 0.3, trim, "SmoothPlastic")
		end
	end
	r:cyl(0, 18.2, cz, 0.7, 0.8, "y", C.Gold, "Metal")
	r:ball(0, 18.55, cz, 0.6, C.Gold, "Metal")
	r:block(-1.6, 18.9, cz - 1.6, 1.6, 19.2, cz + 1.6, trim, "SmoothPlastic")
	pyramid(r, 0, cz, 19.2, 21.2, 1.6, roof)
	r:ball(0, 21.25, cz, 0.35, C.Gold, "Metal")
	r:cyl(0, 22.9, cz, 3.2, 0.12, "y", C.Metal, "Metal")
	r:block(0.08, 23.3, cz - 0.05, 2.7, 24.4, cz + 0.05, Color3.fromRGB(84, 120, 170), "Fabric")
	r:block(0.08, 23.7, cz - 0.09, 2.66, 24.0, cz + 0.09, C.White, "Fabric")
	-- clipped shrubs at the front corners of the podium
	for _, sx in { -1, 1 } do
		r:block(sx * 9.2 - 0.7, 0.6, 4.0, sx * 9.2 + 0.7, 1.6, 5.8, STONE, "Concrete")
		r:ball(sx * 9.2, 2.2, 4.9, 1.6, C.DarkLeaf, "Grass")
	end
end

TownModels.Models.lamp = function(r: R)
	-- a stepped base, a slim post with collars, a ladder bar and a four sided lantern
	r:block(-0.7, 0, -0.7, 0.7, 0.35, 0.7, IRON, "Metal")
	r:cyl(0, 0.85, 0, 1.0, 1.0, "y", IRON, "Metal")
	r:cyl(0, 1.4, 0, 0.12, 0.8, "y", shade(IRON, 1.4), "Metal")
	r:cyl(0, 4.5, 0, 6.2, 0.42, "y", IRON, "Metal")
	r:cyl(0, 2.2, 0, 0.18, 0.56, "y", shade(IRON, 1.4), "Metal")
	r:cyl(0, 7.0, 0, 0.18, 0.56, "y", shade(IRON, 1.4), "Metal")
	r:block(-0.75, 7.25, -0.05, 0.75, 7.35, 0.05, IRON, "Metal")
	for _, x in { -0.8, 0.8 } do
		r:ball(x, 7.3, 0, 0.18, IRON, "Metal")
	end
	r:cyl(0, 7.7, 0, 0.3, 0.6, "y", IRON, "Metal")
	r:block(-0.7, 7.85, -0.7, 0.7, 8.05, 0.7, IRON, "Metal")
	local glass = r:block(-0.55, 8.05, -0.55, 0.55, 9.35, 0.55, C.Warm, "Glass")
	r:glow(glass, 22, 1.4)
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			r:box(sx * 0.6, 8.7, sz * 0.6, 0.1, 1.3, 0.1, IRON, "Metal")
		end
	end
	r:block(-0.8, 9.35, -0.8, 0.8, 9.5, 0.8, IRON, "Metal")
	pyramid(r, 0, 0, 9.5, 10.2, 0.75, IRON)
	r:ball(0, 10.3, 0, 0.26, IRON, "Metal")
end

TownModels.Models.bench = function(r: R)
	-- cast iron ends with a curled arm, wooden slats for the seat and a sloped back
	for _, sx in { -1, 1 } do
		local x = sx * 2.5
		rod(r, Vector3.new(x, 0, 0.85), Vector3.new(x, 2.65, 0.8), 0.18, IRON, "Metal")
		rod(r, Vector3.new(x, 0, -0.8), Vector3.new(x, 1.85, -0.85), 0.2, IRON, "Metal")
		rod(r, Vector3.new(x, 1.8, -0.85), Vector3.new(x, 3.6, -1.15), 0.2, IRON, "Metal")
		r:block(x - 0.09, 1.65, -0.9, x + 0.09, 1.78, 0.9, IRON, "Metal")
		r:block(x - 0.11, 2.55, -1.0, x + 0.11, 2.68, 0.85, IRON, "Metal")
		r:cyl(x, 2.55, 0.95, 0.24, 0.3, "x", IRON, "Metal")
		r:block(x - 0.07, 0, -0.85, x + 0.07, 0.12, 0.9, IRON, "Metal")
	end
	r:block(-2.4, 0.5, -0.05, 2.4, 0.62, 0.05, IRON, "Metal")
	for i = 0, 4 do
		local z = -0.72 + i * 0.36
		r:block(-2.7, 1.78, z - 0.15, 2.7, 1.92, z + 0.15, WOOD, "WoodPlanks")
	end
	for _, y in { 2.3, 2.75, 3.2 } do
		local z = -0.69 - (y - 1.8) * 0.1667
		r:boxAt(CFrame.new(0, y, z) * CFrame.Angles(-0.16, 0, 0), 5.4, 0.32, 0.12, WOOD, "WoodPlanks")
	end
	r:seat(-1.2, 1.92, 0, 0)
	r:seat(1.2, 1.92, 0, 0)
end

TownModels.Models.tree = function(r: R)
	for i = 0, 4 do
		local a = i / 5 * math.pi * 2 + 0.3
		r:beam(
			Vector3.new(0, 0.9, 0),
			Vector3.new(math.cos(a) * 1.4, 0.05, math.sin(a) * 1.4),
			0.55,
			0.45,
			C.Bark,
			"Wood"
		)
	end
	r:cyl(0, 0.7, 0, 1.4, 1.8, "y", C.Bark, "Wood")
	r:cyl(0, 3.4, 0, 5.4, 1.35, "y", C.Bark, "Wood")
	rod(r, Vector3.new(0, 4.8, 0), Vector3.new(-2.2, 7.4, 0.8), 0.6, C.Bark, "Wood")
	rod(r, Vector3.new(0, 5.2, 0), Vector3.new(2.0, 7.8, -1.0), 0.6, C.Bark, "Wood")
	rod(r, Vector3.new(0, 5.6, 0), Vector3.new(0.4, 8.2, 1.8), 0.5, C.Bark, "Wood")
	local leaf = C.Leaf
	r:ball(0, 8.6, 0, 6.6, leaf, "Grass")
	r:ball(-2.5, 7.4, 1.0, 4.6, shade(leaf, 0.82), "Grass")
	r:ball(2.4, 7.6, -0.8, 4.8, shade(leaf, 0.88), "Grass")
	r:ball(0.6, 7.2, 2.5, 4.4, shade(leaf, 0.94), "Grass")
	r:ball(-0.9, 7.6, -2.5, 4.4, shade(leaf, 0.78), "Grass")
	r:ball(2.0, 9.9, 1.2, 4.0, shade(leaf, 1.06), "Grass")
	r:ball(-1.8, 10.1, -0.6, 4.0, shade(leaf, 1.03), "Grass")
	r:ball(0.3, 11.2, -0.3, 3.6, shade(leaf, 1.12), "Grass")
end

TownModels.Models.pine = function(r: R)
	for i = 0, 2 do
		local a = i / 3 * math.pi * 2 + 0.5
		r:beam(
			Vector3.new(0, 0.6, 0),
			Vector3.new(math.cos(a) * 1.0, 0.05, math.sin(a) * 1.0),
			0.4,
			0.32,
			C.Bark,
			"Wood"
		)
	end
	r:cyl(0, 1.6, 0, 3.2, 1.1, "y", C.Bark, "Wood")
	local tiers = {
		{ 2.4, 7.2, 3.5, 0 },
		{ 4.8, 9.3, 2.9, math.pi / 4 },
		{ 7.0, 11.2, 2.2, 0.2 },
		{ 9.2, 13.2, 1.5, math.pi / 4 + 0.2 },
	}
	for k, t in tiers do
		local y0, y1, half, turn = t[1], t[2], t[3], t[4]
		local col = shade(C.DarkLeaf, 1 + (k - 1) * 0.06)
		local corners = {}
		for i = 0, 3 do
			local a = turn + math.pi / 4 + i * math.pi / 2
			table.insert(corners, Vector3.new(math.cos(a) * half * math.sqrt(2), y0, math.sin(a) * half * math.sqrt(2)))
		end
		local apex = Vector3.new(0, y1, 0)
		for i = 1, 4 do
			r:tri(corners[i], corners[i % 4 + 1], apex, 0.4, if i % 2 == 0 then col else shade(col, 0.88), "Grass")
		end
		if k == 1 then
			r:boxAt(
				CFrame.new(0, y0 + 0.05, 0) * CFrame.Angles(0, -turn, 0),
				half * 2,
				0.1,
				half * 2,
				shade(col, 0.7),
				"Grass"
			)
		end
	end
end

TownModels.Models.sign = function(r: R)
	-- two capped posts, a framed board under a little roof, and a flower box at the foot
	for _, x in { -4.0, 4.0 } do
		r:box(x, 3.6, 0, 0.6, 7.2, 0.6, DARK_WOOD, "Wood")
		r:block(x - 0.4, 0, -0.4, x + 0.4, 0.3, 0.4, DARK_STONE, "Concrete")
	end
	local board = r:block(-3.6, 3.4, -0.25, 3.6, 6, 0.25, WOOD, "WoodPlanks")
	board.name = "SignBoard"
	r:block(-3.75, 6.0, -0.32, 3.75, 6.25, 0.32, DARK_WOOD, "Wood")
	r:block(-3.75, 3.15, -0.32, 3.75, 3.4, 0.32, DARK_WOOD, "Wood")
	for _, sx in { -1, 1 } do
		r:block(
			math.min(sx * 3.6, sx * 3.75),
			3.15,
			-0.32,
			math.max(sx * 3.6, sx * 3.75),
			6.25,
			0.32,
			DARK_WOOD,
			"Wood"
		)
	end
	local roof = Color3.fromRGB(164, 92, 86)
	for _, sz in { -1, 1 } do
		r:quad(
			Vector3.new(-4.7, 7.0, sz * 0.9),
			Vector3.new(4.7, 7.0, sz * 0.9),
			Vector3.new(4.7, 7.7, 0),
			Vector3.new(-4.7, 7.7, 0),
			0.16,
			roof,
			"Slate"
		)
	end
	r:block(-4.75, 7.6, -0.14, 4.75, 7.85, 0.14, shade(roof, 0.8), "Slate")
	r:block(-3.7, 6.25, -0.3, 3.7, 7.05, 0.3, WOOD, "WoodPlanks")
	r:block(-3.4, 0, -0.55, 3.4, 0.9, 0.55, WOOD, "WoodPlanks")
	r:block(-3.3, 0.9, -0.45, 3.3, 0.94, 0.45, C.Soil, "Sand")
	for i, col in { C.Pink, C.Yellow, C.White, C.Red, C.Pink, C.Yellow } do
		local x = -2.7 + (i - 1) * 1.08
		r:ball(x, 1.15, 0, 0.6, if i % 2 == 0 then C.Leaf else C.DarkLeaf, "Grass")
		r:ball(x + 0.15, 1.5, (i % 2 - 0.5) * 0.3, 0.3, col, "SmoothPlastic")
	end
end

TownModels.Models.plotSign = function(r: R)
	for _, x in { -2.85, 2.85 } do
		r:block(x - 0.2, 0, -0.2, x + 0.2, 5.3, 0.2, DARK_WOOD, "Wood")
		r:block(x - 0.26, 5.3, -0.26, x + 0.26, 5.45, 0.26, WOOD, "Wood")
	end
	local board = r:block(-2.6, 3, -0.2, 2.6, 5, 0.2, C.Cream, "Wood")
	board.name = "SignBoard"
	r:block(-2.7, 5.0, -0.26, 2.7, 5.15, 0.26, WOOD, "Wood")
	r:block(-2.7, 2.85, -0.26, 2.7, 3.0, 0.26, WOOD, "Wood")
	r:block(-2.65, 1.2, -0.08, 2.65, 1.4, 0.08, DARK_WOOD, "Wood")
end

TownModels.Models.mailbox = function(r: R)
	local blue = Color3.fromRGB(76, 108, 150)
	r:block(-0.25, 0, -0.25, 0.25, 0.15, 0.25, DARK_STONE, "Concrete")
	r:block(-0.15, 0, -0.15, 0.15, 3, 0.15, DARK_WOOD, "Wood")
	r:block(-0.3, 2.85, -0.6, 0.3, 3.0, 0.6, DARK_WOOD, "Wood")
	r:beam(Vector3.new(0, 2.2, 0.12), Vector3.new(0, 2.85, 0.5), 0.12, 0.12, DARK_WOOD, "Wood")
	r:block(-0.5, 3, -0.8, 0.5, 3.6, 0.8, blue, "Metal")
	r:cyl(0, 3.6, 0, 1.6, 1, "z", blue, "Metal")
	r:block(-0.46, 3.03, 0.8, 0.46, 3.6, 0.84, shade(blue, 0.85), "Metal")
	r:cyl(0, 3.6, 0.82, 0.04, 0.92, "z", shade(blue, 0.85), "Metal")
	r:block(-0.1, 3.7, 0.84, 0.1, 3.78, 0.92, C.Metal, "Metal")
	r:block(0.5, 3.15, -0.3, 0.56, 4.0, -0.22, C.Red, "Metal")
	r:block(0.5, 3.75, -0.22, 0.56, 4.0, 0.15, C.Red, "Metal")
end

function TownModels.prims(name: string): { Geometry.Prim }
	local build = TownModels.Models[name]
	assert(build, "no town model " .. name)
	local r = Recipe.new(C.White, C.White)
	build(r)
	return r.prims
end

-- Every model side by side, for the preview tool.
function TownModels.preview(): { Geometry.Prim }
	local out = {}
	local x = 0
	for _, name in
		{
			"fountain",
			"board",
			"tailor",
			"shop",
			"hall",
			"lamp",
			"bench",
			"tree",
			"pine",
			"sign",
			"plotSign",
			"mailbox",
		}
	do
		local prims = TownModels.prims(name)
		local lo, hi = Geometry.bounds(prims)
		x -= lo.X
		for _, p in prims do
			p.cf = CFrame.new(x, 0, 0) * p.cf
			table.insert(out, p)
		end
		x += hi.X + 4
	end
	return out
end

return TownModels
