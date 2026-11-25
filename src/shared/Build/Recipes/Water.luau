--!strict
-- Things that go in the water: on a pool or a pond the player has dug in Build mode (Build/Water).
-- The user: "also, add ability to add water, along with things that can go in the water".
--
-- Every piece here has place = "water" (Plan only lets it go where Build/Water says) and says how
-- it sits with `water`:
--   "float"   on the surface: boats, floats, lily pads, and a shoal swimming under it
--   "bottom"  on the floor of shallow water: reeds, stepping stones
--   "edge"    on the side, reaching out over the water: a jetty, a ladder, a diving board, a slide
-- and `draft`, how far under the surface (or, at the edge, under the ground) its own floor is. So
-- in a piece's own frame the waterline is at y = draft for a float, the ground at y = draft for an
-- edge piece, and for a piece on the bottom the surface is 2 up (shallow water is 2 deep).
-- The lifebuoy stand goes on dry ground beside the water, as anything else in the garden does.

local Recipe = require(script.Parent.Parent.Recipe)
local Lively = require(script.Parent.Parent.Lively)
local Colors = require(script.Parent.Parent.Parent.Util.Colors)

local C = Recipe.Colors

type R = Recipe.Recipe

local function shade(c: Color3, k: number): Color3
	return Colors.shade(c, k)
end

local function rgb(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end

local ROPE = rgb(200, 180, 138)
local SPRAY = rgb(214, 240, 246)
local MUD = rgb(96, 80, 60)

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
		mat = mat or "SmoothPlastic",
	})
end

-- A rod bent through the points, its joints closed up.
local function bent(r: R, pts: { Vector3 }, d: number, color: Color3, mat: string?)
	for i = 1, #pts - 1 do
		local a, b = pts[i], pts[i + 1]
		local step = (b - a).Unit * (d * 0.3)
		rod(r, if i > 1 then a - step else a, if i < #pts - 1 then b + step else b, d, color, mat)
	end
end

-- A ring of `n` short rods round the frame's Y axis (a swim ring, a lifebuoy): radius `rad` to
-- the middle of the tube, the tube `tube` thick, each piece coloured by `colorAt`.
local function torus(
	r: R,
	frame: CFrame,
	rad: number,
	tube: number,
	n: number,
	colorAt: (number) -> Color3,
	mat: string?,
	tubeAt: ((number) -> number)?
)
	for k = 0, n - 1 do
		local a0, a1 = k / n * math.pi * 2, (k + 1) / n * math.pi * 2
		local p0 = frame * Vector3.new(math.cos(a0) * rad, 0, math.sin(a0) * rad)
		local p1 = frame * Vector3.new(math.cos(a1) * rad, 0, math.sin(a1) * rad)
		local d = if tubeAt then tubeAt(k) else tube
		local ext = (p1 - p0).Unit * (d * 0.3)
		rod(r, p0 - ext, p1 + ext, d, colorAt(k), mat)
	end
end

-- A blade of a water plant from its foot, leaning out along the angle `a`: wide below, narrow
-- above, the top half in the lighter colour.
local function blade(
	r: R,
	x: number,
	y: number,
	z: number,
	h: number,
	a: number,
	lean: number,
	low: Color3,
	high: Color3
)
	local out = Vector3.new(math.cos(a), 0, math.sin(a))
	local foot = Vector3.new(x, y, z)
	local mid = foot + out * (lean * h * 0.4) + Vector3.new(0, h * 0.55, 0)
	local top = foot + out * (lean * h) + Vector3.new(0, h, 0)
	local b1 = r:beam(foot, mid, 0.16, 0.05, low, "Grass")
	local b2 = r:beam(mid - (mid - foot).Unit * 0.05, top, 0.1, 0.04, high, "Grass")
	if b1 then
		b1.collide = false
	end
	if b2 then
		b2.collide = false
	end
end

-- A water lily's flower on a pad at (x, z), the pad's top at y.
local function lily(r: R, x: number, y: number, z: number, petal: Color3, turn: number)
	local light = Colors.mix(petal, C.White, 0.4)
	for k = 0, 5 do
		local a = turn + k * math.pi / 3
		r:lump(
			CFrame.new(x + math.cos(a) * 0.22, y + 0.07, z + math.sin(a) * 0.22) * CFrame.Angles(0, -a, 0.45),
			0.42,
			0.1,
			0.2,
			petal,
			"SmoothPlastic"
		)
	end
	for k = 0, 4 do
		local a = turn + 0.5 + k * math.pi * 2 / 5
		r:lump(
			CFrame.new(x + math.cos(a) * 0.12, y + 0.16, z + math.sin(a) * 0.12) * CFrame.Angles(0, -a, 0.9),
			0.3,
			0.09,
			0.15,
			light,
			"SmoothPlastic"
		)
	end
	r:ball(x, y + 0.24, z, 0.14, C.Yellow, "SmoothPlastic")
end

-- One fish of a shoal: (x, y, z) its middle, s its length, turned to face along yaw.
local function fish(r: R, x: number, y: number, z: number, s: number, yaw: number, body: Color3, patch: Color3)
	local f = CFrame.new(x, y, z) * CFrame.Angles(0, yaw, 0)
	r:noCollide(r:lump(f, 0.34 * s, 0.36 * s, s, body, "SmoothPlastic"))
	r:noCollide(
		r:lump(
			f * CFrame.new(0, 0, -0.58 * s) * CFrame.Angles(0.3, 0, 0),
			0.05 * s,
			0.4 * s,
			0.32 * s,
			shade(body, 0.85),
			"SmoothPlastic"
		)
	)
	r:noCollide(
		r:lump(f * CFrame.new(0, 0.17 * s, -0.05 * s), 0.05 * s, 0.16 * s, 0.32 * s, shade(body, 0.85), "SmoothPlastic")
	)
	r:noCollide(r:lump(f * CFrame.new(0, 0.1 * s, 0.12 * s), 0.26 * s, 0.14 * s, 0.34 * s, patch, "SmoothPlastic"))
	for _, sx in { -1, 1 } do
		r:noCollide(r:ball(0, 0, 0, 0.06 * s, C.Black, "SmoothPlastic")).cf = f
			* CFrame.new(sx * 0.14 * s, 0.05 * s, 0.34 * s)
	end
end

local list: { any } = {
	-- plants -------------------------------------------------------------------------------------------
	{
		id = "water_lilies",
		name = "Lily pads",
		cat = "water",
		style = "garden",
		price = 60,
		place = "water",
		water = "float",
		draft = 0.04,
		size = Vector3.new(4, 0.8, 4),
		c1 = "6E9C5A",
		c2 = "F0A8BC",
		tags = { "plant" },
		build = function(r: R)
			local pads = {
				{ -0.95, 0.7, 1.5, 0.3 },
				{ 0.9, -0.75, 1.35, 2.1 },
				{ 0.75, 1.05, 0.95, 4.0 },
				{ -0.95, -1.05, 1.05, 1.2 },
				{ 1.4, 0.2, 0.7, 5.3 },
				{ -0.05, 0.05, 0.6, 3.1 },
			}
			for i, p in pads do
				local x, z, d, turn = p[1], p[2], p[3], p[4]
				local tone = if i % 2 == 0 then shade(r.c1, 0.9) else r.c1
				r:noCollide(r:cyl(x, 0.06, z, 0.06, d, "y", tone, "SmoothPlastic"))
				-- the vein from the middle to the notch, a hair above the pad
				r:noCollide(
					r:boxAt(
						CFrame.new(x, 0.105, z) * CFrame.Angles(0, turn, 0) * CFrame.new(0, 0, d * 0.22),
						0.05,
						0.03,
						d * 0.42,
						shade(r.c1, 0.72),
						"SmoothPlastic"
					)
				)
			end
			lily(r, -0.95, 0.09, 0.7, r.c2, 0.2)
			lily(r, 0.9, 0.09, -0.75, r.c2, 1.1)
			-- a bud still closed, on its stem
			r:noCollide(r:cyl(0.75, 0.25, 1.05, 0.32, 0.07, "y", C.DarkLeaf, "SmoothPlastic"))
			r:noCollide(r:cone(0.75, 0.55, 1.05, 0.4, 0.24, r.c2, "SmoothPlastic"))
		end,
	},
	{
		id = "water_reeds",
		name = "Reeds",
		cat = "water",
		style = "garden",
		price = 50,
		place = "water",
		water = "bottom",
		size = Vector3.new(2.6, 6, 2.6),
		c1 = "6E9450",
		c2 = "A8B46A",
		tags = { "plant" },
		build = function(r: R)
			-- a mound of mud on the floor, the blades out of it and up through the surface (2 up)
			r:lump(CFrame.new(0, 0.12, 0) * CFrame.Angles(0, 0.4, 0), 1.7, 0.4, 1.4, MUD, "Mud")
			r:lump(CFrame.new(0.4, 0.1, -0.3) * CFrame.Angles(0, 1.3, 0), 1.0, 0.3, 0.9, shade(MUD, 0.9), "Mud")
			for k = 0, 10 do
				local a = k * 2.39
				local rr = 0.15 + (k % 4) * 0.14
				local h = 4.0 + ((k * 37) % 10) / 10 * 1.8
				local lean = 0.07 + (k % 3) * 0.05
				blade(r, math.cos(a) * rr, 0.15, math.sin(a) * rr, h, a, lean, r.c1, r.c2)
			end
			-- seed heads on the three tallest
			for _, k in { 2, 5, 8 } do
				local a = k * 2.39
				local rr = 0.15 + (k % 4) * 0.14
				local h = 4.0 + ((k * 37) % 10) / 10 * 1.8
				local lean = 0.07 + (k % 3) * 0.05
				local tip = Vector3.new(math.cos(a) * (rr + lean * h), 0.15 + h, math.sin(a) * (rr + lean * h))
				r:noCollide(
					r:lump(
						CFrame.new(tip - Vector3.new(0, 0.3, 0)) * CFrame.Angles(0, a, 0),
						0.16,
						0.45,
						0.16,
						rgb(184, 156, 104),
						"Fabric"
					)
				)
			end
		end,
	},
	{
		id = "water_bulrush",
		name = "Bulrushes",
		cat = "water",
		style = "garden",
		price = 60,
		place = "water",
		water = "bottom",
		size = Vector3.new(2.4, 6.4, 2.4),
		c1 = "6A8E4E",
		c2 = "7A5238",
		tags = { "plant" },
		build = function(r: R)
			r:lump(CFrame.new(0, 0.12, 0) * CFrame.Angles(0, 1.1, 0), 1.6, 0.4, 1.5, MUD, "Mud")
			-- stems with their brown heads and a thin spike on top
			for k = 0, 5 do
				local a = k * 1.05 + 0.3
				local rr = 0.3 + (k % 2) * 0.2
				local x, z = math.cos(a) * rr, math.sin(a) * rr
				local h = 4.6 + ((k * 53) % 10) / 10 * 1.4
				r:noCollide(r:cyl(x, 0.15 + h / 2, z, h, 0.08, "y", r.c1, "Grass"))
				r:noCollide(r:cyl(x, 0.15 + h - 0.9, z, 0.9, 0.26, "y", r.c2, "Fabric"))
				r:noCollide(r:cyl(x, 0.15 + h + 0.15, z, 0.3, 0.04, "y", shade(r.c1, 0.8), "Grass"))
			end
			-- long leaves leaning out
			for k = 0, 6 do
				local a = k * 0.9 + 0.6
				blade(
					r,
					math.cos(a) * 0.2,
					0.15,
					math.sin(a) * 0.2,
					3.6 + (k % 3) * 0.5,
					a,
					0.16,
					r.c1,
					shade(r.c1, 1.15)
				)
			end
		end,
	},
	{
		id = "water_fish",
		name = "Fish shoal",
		cat = "water",
		style = "garden",
		price = 200,
		place = "water",
		water = "float",
		draft = 1.4,
		size = Vector3.new(3.6, 1.4, 3.6),
		c1 = "E9894A",
		c2 = "F2EEE6",
		build = function(r: R)
			-- under the surface (1.4 up), all heading roughly the same way
			local school = {
				{ 0, 0.7, 0.9, 0.9, 0.1 },
				{ -0.9, 0.5, 0.2, 0.75, 0.25 },
				{ 0.85, 0.85, 0.1, 0.8, -0.15 },
				{ -0.3, 0.35, -0.8, 0.95, 0.05 },
				{ 0.6, 0.45, -1.1, 0.7, 0.3 },
				{ -1.2, 0.8, -0.9, 0.6, -0.2 },
				{ 1.25, 0.3, 1.1, 0.65, 0.4 },
			}
			for i, f in school do
				local body = if i % 3 == 0 then r.c2 else r.c1
				local patch = if i % 3 == 0 then r.c1 else r.c2
				fish(r, f[1], f[2], f[3], f[4], f[5], body, patch)
			end
		end,
	},
	-- boats ---------------------------------------------------------------------------------------------
	{
		id = "water_boat",
		name = "Rowing boat",
		cat = "water",
		style = "seaside",
		price = 700,
		place = "water",
		water = "float",
		draft = 0.5,
		size = Vector3.new(3.8, 2, 9),
		c1 = "4A7896",
		c2 = "A87A52",
		tags = { "seat" },
		build = function(r: R)
			local cream = rgb(236, 230, 216)
			-- the hull's outline, stern to bow, at the gunwale and along the bottom (one side)
			local top = {
				Vector3.new(1.45, 1.55, -4.2),
				Vector3.new(1.8, 1.55, -0.8),
				Vector3.new(1.3, 1.55, 2.6),
				Vector3.new(0, 1.55, 4.45),
			}
			local bottom = {
				Vector3.new(0.95, 0.15, -4.0),
				Vector3.new(1.15, 0.15, -0.8),
				Vector3.new(0.7, 0.15, 2.4),
				Vector3.new(0, 0.15, 3.9),
			}
			local function flip(v: Vector3): Vector3
				return Vector3.new(-v.X, v.Y, v.Z)
			end
			-- both sides, a cream strake under the waterline and the paint over it
			local t = (0.75 - 0.15) / (1.55 - 0.15)
			for _, sx in { 1, -1 } do
				for i = 1, 3 do
					local a1, a2 = top[i], top[i + 1]
					local b1, b2 = bottom[i], bottom[i + 1]
					if sx < 0 then
						a1, a2, b1, b2 = flip(a1), flip(a2), flip(b1), flip(b2)
					end
					local m1, m2 = b1:Lerp(a1, t), b2:Lerp(a2, t)
					r:quad(m1, m2, b2, b1, 0.12, cream, "Wood")
					r:quad(a1, a2, m2, m1, 0.12, r.c1, "Wood")
				end
			end
			-- the bottom, the transom across the stern and the stem up the bow
			r:quad(bottom[1], bottom[2], flip(bottom[2]), flip(bottom[1]), 0.12, cream, "Wood")
			r:quad(bottom[2], bottom[3], flip(bottom[3]), flip(bottom[2]), 0.12, cream, "Wood")
			r:tri(bottom[3], bottom[4], flip(bottom[3]), 0.12, cream, "Wood")
			r:quad(top[1], flip(top[1]), flip(bottom[1]), bottom[1], 0.15, r.c1, "Wood")
			r:beam(
				bottom[4] + Vector3.new(0, -0.05, -0.05),
				top[4] + Vector3.new(0, 0.05, 0.02),
				0.18,
				0.18,
				r.c2,
				"Wood"
			)
			-- a rubbing strake along the gunwale on each side
			for _, sx in { 1, -1 } do
				local pts = {}
				for _, v in top do
					table.insert(pts, Vector3.new(v.X * sx, 1.62, v.Z))
				end
				for i = 1, #pts - 1 do
					local a, b = pts[i], pts[i + 1]
					local step = (b - a).Unit * 0.06
					r:beam(
						if i > 1 then a - step else a,
						if i < #pts - 1 then b + step else b,
						0.16,
						0.14,
						r.c2,
						"Wood"
					)
				end
			end
			-- floorboards, three thwarts to sit on, and the rowlocks
			for _, x in { -0.55, 0, 0.55 } do
				r:block(x - 0.2, 0.3, -3.5, x + 0.2, 0.36, 2.6, shade(r.c2, 1.1), "WoodPlanks")
			end
			local function halfWidth(z: number): number
				for i = 1, 3 do
					local a, b = top[i], top[i + 1]
					if z >= a.Z and z <= b.Z then
						return a.X + (b.X - a.X) * (z - a.Z) / (b.Z - a.Z)
					end
				end
				return 1
			end
			for _, z in { -3.0, -0.6, 1.9 } do
				local hw = halfWidth(z) - 0.22
				r:block(-hw, 0.95, z - 0.32, hw, 1.08, z + 0.32, r.c2, "Wood")
			end
			r:seat(0, 1.08, -0.6, 180)
			r:seat(0, 1.08, -3.0, 0)
			for _, sx in { 1, -1 } do
				local x = sx * (halfWidth(-0.6) - 0.05)
				r:cyl(x, 1.75, -0.6, 0.22, 0.08, "y", C.DarkMetal, "Metal")
			end
			-- the oars, shipped along the boat with their blades forward
			for _, sx in { 1, -1 } do
				local a = Vector3.new(sx * 0.55, 1.13, -3.4)
				local b = Vector3.new(sx * 0.85, 1.2, 2.2)
				r:beam(a, b, 0.11, 0.11, rgb(198, 168, 120), "Wood")
				local dir = (b - a).Unit
				local blade = b + dir * 0.55
				r:boxAt(CFrame.lookAt(blade, blade + dir), 0.34, 0.05, 1.1, rgb(198, 168, 120), "Wood")
			end
		end,
	},
	{
		id = "water_kayak",
		name = "Kayak",
		cat = "water",
		style = "seaside",
		price = 420,
		place = "water",
		water = "float",
		draft = 0.35,
		size = Vector3.new(1.6, 1.3, 7.6),
		c1 = "D8664C",
		c2 = "3A3A40",
		tags = { "seat" },
		build = function(r: R)
			r:lump(CFrame.new(0, 0.45, 0), 1.3, 0.9, 7.4, r.c1, "SmoothPlastic")
			-- the cockpit's rim with the seat down in it, and two hatches
			r:lump(CFrame.new(0, 0.9, -0.4), 0.95, 0.16, 1.5, r.c2, "Plastic")
			r:lump(CFrame.new(0, 1.0, -0.4), 0.7, 0.06, 1.2, shade(r.c2, 0.7), "Plastic")
			r:seat(0, 0.8, -0.4, 0)
			for _, z in { 2.2, -2.3 } do
				local y = 0.45 + 0.45 * math.sqrt(1 - (z / 3.7) ^ 2)
				r:cyl(0, y + 0.02, z, 0.08, 0.55, "y", r.c2, "Plastic")
			end
			-- a stripe along each side
			for _, sx in { 1, -1 } do
				r:beam(
					Vector3.new(sx * 0.665, 0.55, -2.4),
					Vector3.new(sx * 0.665, 0.55, 2.4),
					0.05,
					0.1,
					C.White,
					"Plastic"
				)
			end
			-- the paddle, laid across the cockpit
			local a, b = Vector3.new(0.4, 1.05, -1.9), Vector3.new(-0.3, 1.05, 1.3)
			r:beam(a, b, 0.09, 0.09, C.DarkMetal, "Metal")
			local dir = (b - a).Unit
			for _, e in { { a, -dir }, { b, dir } } do
				local mid = e[1] + e[2] * 0.4
				r:boxAt(CFrame.lookAt(mid, mid + e[2]), 0.3, 0.04, 0.75, rgb(240, 196, 92), "Plastic")
			end
		end,
	},
	{
		id = "water_pedalo",
		name = "Pedalo",
		cat = "water",
		style = "playful",
		price = 900,
		place = "water",
		water = "float",
		draft = 0.45,
		size = Vector3.new(4.4, 4, 6.4),
		c1 = "F2EEE6",
		c2 = "4FA0B8",
		tags = { "seat" },
		build = function(r: R)
			-- two floats, the deck across them, the bow faired off
			for _, sx in { -1, 1 } do
				r:lump(CFrame.new(sx * 1.5, 0.5, 0), 1.2, 1.0, 6.2, r.c2, "Plastic")
			end
			r:block(-1.9, 0.95, -2.6, 1.9, 1.15, 2.6, r.c1, "Plastic")
			r:ramp(-1.6, 1.15, 1.6, 1.6, 1.6, 2.5, false, r.c1, "Plastic")
			-- the seat for two, with its cushions and a rolled top to the back
			r:block(-1.3, 1.15, -1.6, 1.3, 1.65, -0.4, r.c1, "Plastic")
			for _, sx in { -1, 1 } do
				r:block(sx * 0.1, 1.65, -1.55, sx * 1.2, 1.8, -0.45, r.c2, "Fabric")
				r:seat(sx * 0.65, 1.8, -1.0, 0)
			end
			r:block(-1.3, 1.65, -1.78, 1.3, 2.85, -1.55, r.c1, "Plastic")
			r:cyl(0, 2.88, -1.66, 2.6, 0.24, "x", r.c1, "Plastic")
			-- the pedals in front of it, and a little tiller between the two
			r:block(-1.3, 1.15, 0.6, 1.3, 1.5, 1.45, shade(r.c1, 0.92), "Plastic")
			for _, sx in { -1, 1 } do
				r:cyl(sx * 0.5, 1.6, 0.55, 0.12, 0.5, "x", C.DarkMetal, "Metal")
				r:block(sx * 0.5 - 0.16, 1.48, 0.25, sx * 0.5 + 0.16, 1.56, 0.5, C.Black, "Plastic")
			end
			r:cyl(0, 2.0, -0.6, 0.7, 0.08, "y", C.DarkMetal, "Metal")
			r:ball(0, 2.38, -0.6, 0.18, C.Black, "Plastic")
			-- a striped sun roof on four poles
			for _, sx in { -1, 1 } do
				for _, z in { -1.9, 1.5 } do
					r:cyl(sx * 1.65, 2.475, z, 2.65, 0.1, "y", C.Metal, "Metal")
				end
			end
			for k = 0, 4 do
				local x1 = -1.9 + k * 0.76
				r:block(x1, 3.8, -2.2, x1 + 0.76, 3.95, 1.8, if k % 2 == 0 then r.c2 else r.c1, "Fabric")
			end
			-- the paddle wheel at the stern, under its hood
			r:cyl(0, 0.62, -2.9, 1.6, 0.12, "x", C.DarkMetal, "Metal")
			for k = 0, 5 do
				local a = k * math.pi / 3
				r:boxAt(
					CFrame.new(0, 0.62, -2.9) * CFrame.Angles(a, 0, 0) * CFrame.new(0, 0, 0.28),
					1.2,
					0.07,
					0.46,
					r.c2,
					"Plastic"
				)
			end
			r:block(-0.9, 1.0, -3.2, 0.9, 1.25, -2.62, r.c1, "Plastic")
		end,
	},
	-- floats and toys ------------------------------------------------------------------------------------
	{
		id = "water_ring",
		name = "Swim ring",
		cat = "water",
		style = "playful",
		price = 80,
		place = "water",
		water = "float",
		draft = 0.2,
		size = Vector3.new(2.8, 0.6, 2.8),
		c1 = "E86A5C",
		c2 = "F4F0E6",
		tags = { "toy" },
		build = function(r: R)
			-- (the white stripes a touch fatter, so where two colours meet their faces never share
			-- a plane)
			torus(
				r,
				CFrame.new(0, 0.28, 0),
				1.1,
				0.56,
				12,
				function(k)
					return if (k // 3) % 2 == 0 then r.c1 else r.c2
				end,
				"Plastic",
				function(k)
					return if (k // 3) % 2 == 0 then 0.56 else 0.62
				end
			)
			-- the valve
			r:cyl(math.cos(0.3) * 1.1, 0.6, math.sin(0.3) * 1.1, 0.1, 0.12, "y", shade(r.c2, 0.85), "Plastic")
		end,
	},
	{
		id = "water_lilo",
		name = "Lilo",
		cat = "water",
		style = "seaside",
		price = 90,
		place = "water",
		water = "float",
		draft = 0.12,
		size = Vector3.new(2.8, 0.6, 6.6),
		c1 = "4F9CC6",
		c2 = "F2D06A",
		tags = { "toy" },
		build = function(r: R)
			-- five tubes side by side, rounded at the ends, and a pillow across the head
			for k = 0, 4 do
				local x = -1.0 + k * 0.5
				local col = if k % 2 == 0 then r.c1 else r.c2
				r:cyl(x, 0.24, -0.3, 5.0, 0.44, "z", col, "Plastic")
				r:ball(x, 0.24, -2.8, 0.44, col, "Plastic")
				r:ball(x, 0.24, 2.2, 0.44, col, "Plastic")
			end
			r:cyl(0, 0.3, 2.75, 2.4, 0.58, "x", r.c1, "Plastic")
			for _, sx in { -1, 1 } do
				r:ball(sx * 1.2, 0.3, 2.75, 0.58, r.c1, "Plastic")
			end
			r:cyl(1.0, 0.5, -2.6, 0.1, 0.1, "y", C.White, "Plastic")
		end,
	},
	{
		id = "water_duck",
		name = "Duck float",
		cat = "water",
		style = "playful",
		price = 260,
		place = "water",
		water = "float",
		draft = 0.35,
		size = Vector3.new(2.8, 3.2, 3.6),
		c1 = "F2CC5C",
		c2 = "E8894A",
		tags = { "toy" },
		build = function(r: R)
			r:lump(CFrame.new(0, 0.75, -0.2), 2.6, 1.5, 3.0, r.c1, "Plastic")
			r:lump(CFrame.new(0, 1.1, 0.8), 2.0, 1.4, 1.4, r.c1, "Plastic")
			r:lump(CFrame.new(0, 1.45, -1.45) * CFrame.Angles(-0.6, 0, 0), 1.0, 1.0, 0.8, r.c1, "Plastic")
			for _, sx in { -1, 1 } do
				r:lump(
					CFrame.new(sx * 1.2, 1.0, -0.3) * CFrame.Angles(0, 0, sx * 0.2),
					0.4,
					0.9,
					1.7,
					shade(r.c1, 0.9),
					"Plastic"
				)
			end
			-- the head, its beak and its eyes, and a tuft on top
			r:ball(0, 2.35, 0.9, 1.4, r.c1, "Plastic")
			r:lump(CFrame.new(0, 2.2, 1.65), 0.75, 0.28, 0.75, r.c2, "Plastic")
			r:lump(CFrame.new(0, 2.05, 1.55), 0.6, 0.18, 0.5, shade(r.c2, 0.85), "Plastic")
			for _, sx in { -1, 1 } do
				r:ball(sx * 0.38, 2.55, 1.48, 0.18, C.Black, "Plastic")
				r:ball(sx * 0.4, 2.6, 1.56, 0.06, C.White, "Plastic")
			end
			r:lump(CFrame.new(0, 3.1, 0.85) * CFrame.Angles(-0.3, 0, 0), 0.3, 0.4, 0.3, r.c1, "Plastic")
		end,
	},
	{
		id = "water_ball",
		name = "Beach ball",
		cat = "water",
		style = "playful",
		price = 40,
		place = "water",
		water = "float",
		draft = 0.12,
		size = Vector3.new(1.4, 1.4, 1.4),
		c1 = "F2EEE6",
		c2 = "E8655A",
		tags = { "toy" },
		build = function(r: R)
			-- made of six slices round its axis, white between the coloured ones, so it shows its
			-- stripes from every side
			local stripes = { r.c2, rgb(240, 196, 92), rgb(79, 156, 198) }
			for k = 0, 5 do
				local col = if k % 2 == 0 then r.c1 else stripes[(k - 1) // 2 + 1]
				r:lump(CFrame.new(0, 0.65, 0) * CFrame.Angles(0, k * math.pi / 6, 0), 1.3, 1.3, 0.62, col, "Plastic")
			end
			-- a white cap over each end, where the slices meet
			for _, y in { -0.02, 1.32 } do
				r:cyl(0, y, 0, 0.18, 0.46, "y", r.c1, "Plastic")
			end
		end,
	},
	{
		id = "water_lantern",
		name = "Floating lantern",
		cat = "water",
		style = "fancy",
		price = 120,
		place = "water",
		water = "float",
		draft = 0.08,
		size = Vector3.new(1.3, 1.7, 1.3),
		c1 = "F4E6C8",
		c2 = "8E6440",
		tags = { "light" },
		build = function(r: R)
			-- a wooden float, a frame of four posts with paper between, and a little roof
			r:cyl(0, 0.1, 0, 0.2, 1.2, "y", r.c2, "Wood")
			r:block(-0.42, 0.2, -0.42, 0.42, 0.26, 0.42, shade(r.c2, 0.85), "Wood")
			local paper = r:block(-0.34, 0.3, -0.34, 0.34, 1.22, 0.34, r.c1, "Fabric")
			paper.transp = 0.1
			r:glow(paper, 8, 0.8)
			for _, sx in { -1, 1 } do
				for _, sz in { -1, 1 } do
					r:block(
						sx * 0.36 - 0.03,
						0.26,
						sz * 0.36 - 0.03,
						sx * 0.36 + 0.03,
						1.26,
						sz * 0.36 + 0.03,
						r.c2,
						"Wood"
					)
				end
			end
			for _, y in { 0.3, 1.2 } do
				r:block(-0.39, y - 0.04, -0.39, 0.39, y + 0.04, -0.33, r.c2, "Wood")
				r:block(-0.39, y - 0.04, 0.33, 0.39, y + 0.04, 0.39, r.c2, "Wood")
			end
			r:cone(0, 1.42, 0, 0.32, 0.95, r.c2, "Wood")
			r:ball(0, 1.62, 0, 0.1, C.Gold, "Metal")
		end,
	},
	{
		id = "water_jet",
		name = "Fountain jet",
		cat = "water",
		style = "fancy",
		price = 400,
		place = "water",
		water = "float",
		draft = 0.35,
		size = Vector3.new(2.6, 5.4, 2.6),
		c1 = "CDEEF5",
		c2 = "6E7480",
		lively = true, -- (it sprays: World/Lively)
		build = function(r: R)
			-- the nozzle just under the surface (0.35 up), and the foam round it
			r:cyl(0, 0.2, 0, 0.25, 0.7, "y", r.c2, "Metal")
			r:cyl(0, 0.38, 0, 0.15, 0.25, "y", shade(r.c2, 0.8), "Metal")
			local foam = r:cyl(0, 0.38, 0, 0.06, 1.6, "y", r.c1, "Glass")
			foam.transp = 0.45
			foam.collide = false
			for k = 0, 7 do
				local a = k * math.pi / 4
				local p = r:lump(
					CFrame.new(math.cos(a) * 0.55, 0.47, math.sin(a) * 0.55) * CFrame.Angles(0, -a, 0),
					0.4,
					0.32,
					0.3,
					SPRAY,
					"Glass"
				)
				p.transp = 0.35
				p.collide = false
			end
			-- the column of water, and its crown falling back all round
			local jet = r:cyl(0, 2.375, 0, 3.85, 0.28, "y", r.c1, "Glass")
			jet.transp = 0.35
			jet.collide = false
			jet.name = "Jet"
			local core = r:cyl(0, 2.375, 0, 3.75, 0.14, "y", C.White, "Glass")
			core.transp = 0.2
			core.collide = false
			local crown = r:lump(CFrame.new(0, 4.4, 0), 0.6, 0.5, 0.6, SPRAY, "Glass")
			crown.transp = 0.3
			crown.collide = false
			for k = 0, 5 do
				local a = k * math.pi / 3 + 0.2
				local out = Vector3.new(math.cos(a), 0, math.sin(a))
				local p1 = Vector3.new(0, 4.35, 0)
				local p2 = out * 0.95 + Vector3.new(0, 3.4, 0)
				local p3 = out * 1.15 + Vector3.new(0, 1.8, 0)
				for i, seg in { { a = p1, b = p2, see = 0.3 }, { a = p2, b = p3, see = 0.5 } } do
					local b = r:beam(seg.a, seg.b, 0.12 - i * 0.02, 0.06, SPRAY, "Glass")
					if b then
						b.transp = seg.see
						b.collide = false
					end
				end
				local drop = r:ball(p3.X, 1.7, p3.Z, 0.12, SPRAY, "Glass")
				drop.transp = 0.4
				drop.collide = false
			end
			-- and real spray off the top, on each player's screen
			Lively.fx(r, "splash", 0, 4.6, 0, { w = 0.2, d = 0.2 })
		end,
	},
	-- on the bottom and at the edge -----------------------------------------------------------------------
	{
		id = "water_stones",
		name = "Stepping stones",
		cat = "water",
		style = "garden",
		price = 150,
		place = "water",
		water = "bottom",
		size = Vector3.new(2.6, 2.5, 7.4),
		c1 = "A6A29A",
		c2 = "8E8A82",
		build = function(r: R)
			-- three stones up from the floor, their flat tops a little over the surface (2 up)
			for k, s in { { -0.3, -2.5 }, { 0.35, 0 }, { -0.2, 2.5 } } do
				r:lump(CFrame.new(s[1], 0.9, s[2]) * CFrame.Angles(0, k * 0.9, 0), 1.7, 1.9, 1.6, r.c2, "Rock")
				r:lump(CFrame.new(s[1], 2.12, s[2]) * CFrame.Angles(0, k * 1.7, 0), 2.0, 0.55, 1.8, r.c1, "Slate")
			end
			-- a bit of weed at the waterline of the middle one
			r:noCollide(
				r:lump(CFrame.new(0.95, 1.95, 0.3) * CFrame.Angles(0, 0.5, 0), 0.5, 0.2, 0.7, C.DarkLeaf, "Grass")
			)
		end,
	},
	{
		id = "water_jetty",
		name = "Jetty",
		cat = "water",
		style = "rustic",
		price = 600,
		place = "water",
		water = "edge",
		draft = 1.4,
		size = Vector3.new(4, 2.6, 10),
		c1 = "9C7A58",
		c2 = "6E5644",
		surface = 1.95,
		build = function(r: R)
			-- the ground is 1.4 up: its back end rests on the side, the rest runs out over the water
			for _, sx in { -1, 1 } do
				r:block(sx * 1.5 - 0.15, 1.45, -5, sx * 1.5 + 0.15, 1.75, 5, r.c2, "Wood")
			end
			for _, z in { -4.5, -1.5, 1.5, 4.5 } do
				r:block(-1.35, 1.55, z - 0.15, 1.35, 1.75, z + 0.15, r.c2, "Wood")
			end
			-- the planks, a little apart
			local k = 0
			for z = -5, 4.5, 0.5 do
				r:block(
					-2,
					1.75,
					z + 0.03,
					2,
					1.95,
					z + 0.47,
					if k % 2 == 0 then r.c1 else shade(r.c1, 0.93),
					"WoodPlanks"
				)
				k += 1
			end
			-- posts down into the water, braced, and the last two standing up as bollards
			for _, sx in { -1, 1 } do
				for _, z in { -4.4, -0.8, 2.6 } do
					r:cyl(sx * 1.75, 0.875, z, 1.75, 0.36, "y", r.c2, "Wood")
				end
				r:cyl(sx * 1.75, 1.3, 4.6, 2.6, 0.4, "y", r.c2, "Wood")
				r:cyl(sx * 1.75, 2.62, 4.6, 0.06, 0.46, "y", shade(r.c2, 0.8), "Wood")
				r:beam(
					Vector3.new(sx * 1.75, 0.3, -0.8),
					Vector3.new(sx * 1.75, 1.4, 2.6),
					0.12,
					0.12,
					shade(r.c2, 0.9),
					"Wood"
				)
				r:beam(
					Vector3.new(sx * 1.75, 0.3, 2.6),
					Vector3.new(sx * 1.75, 1.4, -0.8),
					0.12,
					0.12,
					shade(r.c2, 0.9),
					"Wood"
				)
			end
			-- a rope slung between the bollards
			bent(
				r,
				{ Vector3.new(-1.75, 2.35, 4.6), Vector3.new(0, 2.15, 4.6), Vector3.new(1.75, 2.35, 4.6) },
				0.08,
				ROPE,
				"Fabric"
			)
		end,
	},
	{
		id = "water_ladder",
		name = "Pool ladder",
		cat = "water",
		style = "modern",
		price = 220,
		place = "water",
		water = "edge",
		draft = 2.4,
		size = Vector3.new(2.4, 5.6, 2.8),
		c1 = "C9CED6",
		c2 = "8A9098",
		build = function(r: R)
			-- the ground is 2.4 up: the rails come up out of the water at the front, over the side
			-- and down onto it at the back
			for _, sx in { -1, 1 } do
				local x = sx * 0.85
				bent(r, {
					Vector3.new(x, 0.3, 0.9),
					Vector3.new(x, 3.3, 0.9),
					Vector3.new(x, 4.15, 0.75),
					Vector3.new(x, 4.55, 0.3),
					Vector3.new(x, 4.4, -0.25),
					Vector3.new(x, 3.9, -0.6),
					Vector3.new(x, 2.78, -0.75),
				}, 0.16, r.c1, "Metal")
				r:cyl(x, 2.78, -0.75, 0.06, 0.32, "y", r.c1, "Metal")
			end
			-- three treads, each with a grip along it
			for _, y in { 0.6, 1.3, 2.0 } do
				r:block(-0.78, y - 0.06, 0.6, 0.78, y + 0.06, 1.0, r.c2, "Metal")
				r:block(-0.7, y + 0.06, 0.66, 0.7, y + 0.1, 0.94, shade(r.c2, 0.7), "Rubber")
			end
		end,
	},
	{
		id = "water_board",
		name = "Diving board",
		cat = "water",
		style = "modern",
		price = 480,
		place = "water",
		water = "edge",
		draft = 0,
		size = Vector3.new(2.4, 2.4, 9.6),
		c1 = "F2F0EA",
		c2 = "4A86B4",
		build = function(r: R)
			local grey = rgb(200, 196, 188)
			-- a plinth on the side with a step up, two brackets holding the board's end and a
			-- roller under it further out
			r:block(-1.1, 0, -4.8, 1.1, 0.3, -2.4, grey, "Concrete")
			r:block(-0.6, 0.3, -4.78, 0.6, 0.85, -4.45, grey, "Concrete")
			for _, sx in { -1, 1 } do
				r:block(sx * 0.75 - 0.08, 0.3, -4.4, sx * 0.75 + 0.08, 1.45, -3.6, r.c2, "Metal")
				r:block(sx * 0.75 - 0.07, 0.3, -1.45, sx * 0.75 + 0.07, 1.22, -1.05, r.c2, "Metal")
			end
			r:block(-0.6, 1.3, -4.4, 0.6, 1.45, -3.8, shade(r.c2, 0.8), "Metal")
			r:cyl(0, 1.34, -1.25, 1.7, 0.22, "x", shade(r.c2, 0.8), "Metal")
			-- the board and the grip along its top
			r:block(-0.7, 1.45, -4.5, 0.7, 1.65, 4.6, r.c1, "Plastic")
			r:block(-0.6, 1.65, -2.0, 0.6, 1.69, 4.45, r.c2, "Fabric")
			-- hand rails up from the plinth
			for _, sx in { -1, 1 } do
				local x = sx * 0.88
				bent(r, {
					Vector3.new(x, 0.3, -4.6),
					Vector3.new(x, 2.25, -4.3),
					Vector3.new(x, 2.25, -2.9),
					Vector3.new(x, 1.75, -2.4),
				}, 0.12, C.Metal, "Metal")
			end
		end,
	},
	{
		id = "water_slide",
		name = "Water slide",
		cat = "water",
		style = "playful",
		price = 1100,
		place = "water",
		water = "edge",
		draft = 0.4,
		size = Vector3.new(4, 7.4, 11),
		c1 = "F2C14E",
		c2 = "4F9CC6",
		build = function(r: R)
			local g = 0.4 -- the ground
			-- a ladder up the back to a railed platform on four legs
			for _, sx in { -1, 1 } do
				rod(r, Vector3.new(sx * 0.7, g, -5.3), Vector3.new(sx * 0.7, 7.0, -4.65), 0.14, r.c2, "Metal")
			end
			for y = 1.0, 5.8, 0.6 do
				local z = -5.3 + (y - g) / (7.0 - g) * 0.65
				r:cyl(0, y, z, 1.3, 0.1, "x", C.Metal, "Metal")
			end
			r:block(-1.0, 6.0, -4.8, 1.0, 6.2, -3.4, r.c2, "Metal")
			for _, sx in { -1, 1 } do
				for _, z in { -4.65, -3.55 } do
					r:cyl(sx * 0.9, (g + 6.0) / 2, z, 6.0 - g, 0.16, "y", r.c2, "Metal")
				end
				r:cyl(sx * 1.0, 6.7, -4.1, 1.0, 0.1, "y", C.Metal, "Metal")
				rod(r, Vector3.new(sx * 1.0, 7.2, -4.7), Vector3.new(sx * 1.0, 7.2, -3.45), 0.1, C.Metal, "Metal")
			end
			-- the chute, steep at first and running out flat over the water
			local pts = {}
			local n = 9
			for i = 0, n do
				local t = i / n
				table.insert(pts, Vector3.new(0, 0.3 + 5.8 * (1 - t) ^ 1.8, -3.4 + 8.6 * t))
			end
			local running = rgb(200, 232, 242)
			for i = 1, n do
				local a, b = pts[i], pts[i + 1]
				local step = (b - a).Unit * 0.04
				local a2, b2 = if i > 1 then a - step else a, if i < n then b + step else b
				r:beam(a2, b2, 1.4, 0.14, r.c1, "Plastic")
				-- (offsets square to the chute, which tilts)
				local along = (b2 - a2).Unit
				local up = along:Cross(Vector3.yAxis).Unit:Cross(along).Unit
				for _, sx in { -1, 1 } do
					local side = Vector3.new(sx * 0.75, 0, 0) + up * 0.22
					r:beam(a2 + side, b2 + side, 0.1, 0.5, shade(r.c1, 0.92), "Plastic")
				end
				-- water running down it
				local wet = r:beam(a2 + up * 0.115, b2 + up * 0.115, 1.0, 0.03, running, "Glass")
				if wet then
					wet.transp = 0.45
					wet.collide = false
				end
			end
			-- legs under the chute
			for _, i in { 4, 6 } do
				local p = pts[i]
				for _, sx in { -1, 1 } do
					r:cyl(sx * 0.6, (g + p.Y - 0.08) / 2, p.Z, p.Y - 0.08 - g, 0.16, "y", r.c2, "Metal")
				end
			end
		end,
	},
	{
		id = "water_raft",
		name = "Floating platform",
		cat = "water",
		style = "rustic",
		price = 500,
		place = "water",
		water = "float",
		draft = 0.7,
		size = Vector3.new(6, 1.6, 6),
		c1 = "B08A62",
		c2 = "4F86A8",
		surface = 1.5,
		build = function(r: R)
			-- four drums half under the water (0.7 up), each with two hoops
			for _, sx in { -1, 1 } do
				for _, sz in { -1, 1 } do
					r:cyl(sx * 1.6, 0.62, sz * 1.4, 2.4, 1.2, "z", r.c2, "Metal")
					for _, e in { -0.85, 0.85 } do
						r:cyl(sx * 1.6, 0.62, sz * 1.4 + e, 0.1, 1.26, "z", shade(r.c2, 0.75), "Metal")
					end
				end
			end
			-- the frame, then the deck of planks
			local frame = shade(r.c1, 0.75)
			r:block(-2.95, 1.12, -2.95, 2.95, 1.32, -2.65, frame, "Wood")
			r:block(-2.95, 1.12, 2.65, 2.95, 1.32, 2.95, frame, "Wood")
			r:block(-2.95, 1.12, -2.65, -2.65, 1.32, 2.65, frame, "Wood")
			r:block(2.65, 1.12, -2.65, 2.95, 1.32, 2.65, frame, "Wood")
			r:block(-0.15, 1.12, -2.65, 0.15, 1.32, 2.65, frame, "Wood")
			for k = 0, 10 do
				local z = -3 + k * 0.545
				r:block(
					-3,
					1.32,
					z + 0.03,
					3,
					1.5,
					z + 0.515,
					if k % 2 == 0 then r.c1 else shade(r.c1, 0.93),
					"WoodPlanks"
				)
			end
			-- cleats at the corners and a short ladder down one side
			for _, sx in { -1, 1 } do
				for _, sz in { -1, 1 } do
					r:block(
						sx * 2.5 - 0.25,
						1.5,
						sz * 2.6 - 0.07,
						sx * 2.5 + 0.25,
						1.62,
						sz * 2.6 + 0.07,
						C.DarkMetal,
						"Metal"
					)
				end
				rod(r, Vector3.new(sx * 0.45, 1.5, 2.95), Vector3.new(sx * 0.45, 0.1, 2.95), 0.1, C.Metal, "Metal")
			end
			for _, y in { 0.4, 0.95 } do
				r:cyl(0, y, 2.95, 0.9, 0.08, "x", C.Metal, "Metal")
			end
		end,
	},
	-- on the side --------------------------------------------------------------------------------------------
	{
		id = "water_buoy",
		name = "Lifebuoy stand",
		cat = "water",
		style = "seaside",
		price = 160,
		place = "ground",
		size = Vector3.new(1.8, 5.8, 1.2),
		c1 = "D85A4C",
		c2 = "F2EEE6",
		build = function(r: R)
			-- a post on a concrete foot, a board on its front, the ring on a hook
			r:block(-0.45, 0, -0.45, 0.45, 0.25, 0.45, rgb(196, 192, 184), "Concrete")
			r:block(-0.14, 0.25, -0.14, 0.14, 5.4, 0.14, r.c2, "Wood")
			r:block(-0.2, 5.4, -0.2, 0.2, 5.6, 0.2, r.c1, "Wood")
			r:block(-0.8, 2.3, 0.14, 0.8, 4.6, 0.22, r.c2, "Wood")
			r:block(-0.06, 4.05, 0.22, 0.06, 4.15, 0.46, C.DarkMetal, "Metal")
			torus(r, CFrame.new(0, 3.35, 0.42) * CFrame.Angles(math.pi / 2, 0, 0), 0.62, 0.22, 8, function(k)
				return if (k // 2) % 2 == 0 then r.c1 else r.c2
			end, "Plastic")
			-- the grab line looped round it
			for k = 0, 3 do
				local a = k * math.pi / 2 + math.pi / 4
				local p = Vector3.new(math.cos(a) * 0.62, 3.35 + math.sin(a) * 0.62, 0.42)
				r:boxAt(CFrame.new(p) * CFrame.Angles(0, 0, a), 0.12, 0.26, 0.26, ROPE, "Fabric")
			end
			-- a plate on the post with a cross on it
			r:block(-0.35, 4.75, 0.14, 0.35, 5.15, 0.2, r.c1, "Plastic")
			r:block(-0.05, 4.82, 0.2, 0.05, 5.08, 0.24, C.White, "Plastic")
			r:block(-0.15, 4.9, 0.2, -0.05, 5.0, 0.24, C.White, "Plastic")
			r:block(0.05, 4.9, 0.2, 0.15, 5.0, 0.24, C.White, "Plastic")
		end,
	},
}

return list
