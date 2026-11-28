--!strict
-- What the sets (Data/Stages) are drawn with: the town's own models, and the little things every
-- set needs again (boards, a rope, string lights, bunting, a pot of flowers, a crate, a far
-- building, a lamp that really lights, a tree, tufts of grass, a puff of cloud). Each draws on a
-- recipe (Build/Recipe) in the set's own space.

local Recipe = require(script.Parent.Parent.Parent.Build.Recipe)

type R = Recipe.Recipe

local K = {}

local C = Recipe.Colors

local function rgb(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end

local function yaw(deg: number): CFrame
	return CFrame.Angles(0, math.rad(deg), 0)
end

local function v3(x: number, y: number, z: number): Vector3
	return Vector3.new(x, y, z)
end

-- A colour a little darker (k < 1) or lighter (k > 1).
local function shade(c: Color3, k: number): Color3
	return Color3.new(math.clamp(c.R * k, 0, 1), math.clamp(c.G * k, 0, 1), math.clamp(c.B * k, 0, 1))
end

-- A model of the town's own (Data/TownMap), set down at `cf`: the bench, the lamp, the trees are
-- the same ones the town has. Its lamps keep their lights (the cutscene puts them on after dark),
-- and with `lit` what lights up is drawn lit whatever the hour. (The list a model comes in may be
-- shared: each prim is copied.)
local function town(r: R, name: string, cf: CFrame, lit: boolean?)
	local TownMap = require(script.Parent.Parent.TownMap) :: any
	for _, p in TownMap.prims(name) do
		if (p.transp or 0) < 0.99 then
			local q = table.clone(p)
			q.cf = cf * p.cf
			if lit and q.role == "glow" then
				q.mat = "Neon"
			end
			q.effect = nil
			r:add(q)
		end
	end
end

-- A deterministic little random, so a set is the same every time it is built.
local function rand(seed: number): () -> number
	local s = seed % 2147483646 + 1
	return function(): number
		s = (s * 48271) % 2147483647
		return s / 2147483647
	end
end

-- Boards laid side by side between x1 and x2 (running along X), z1..z2 across them, their tops
-- at `top`, on two bearers. Every other board a shade darker.
local function boards(r: R, x1: number, z1: number, x2: number, z2: number, top: number, color: Color3, bearer: Color3?)
	local w, gap = 0.82, 0.1
	local n = math.max(1, math.floor((z2 - z1 + gap) / (w + gap)))
	local step = (z2 - z1 + gap) / n
	for i = 0, n - 1 do
		local a = z1 + i * step
		r:block(
			x1,
			top - 0.16,
			a,
			x2,
			top,
			a + step - gap,
			if i % 2 == 0 then color else shade(color, 0.93),
			"WoodPlanks"
		)
	end
	local b = bearer or shade(color, 0.6)
	for _, x in { x1 + 0.8, (x1 + x2) / 2, x2 - 0.8 } do
		r:block(x - 0.25, top - 0.46, z1 + 0.1, x + 0.25, top - 0.16, z2 - 0.1, b, "Wood")
	end
end

-- A rope or a wire from a to b that sags by `sag` in the middle, in `n` straight runs.
local function sagging(
	r: R,
	a: Vector3,
	b: Vector3,
	sag: number,
	n: number,
	thick: number,
	color: Color3,
	mat: string?
): { Vector3 }
	local pts = {}
	for i = 0, n do
		local t = i / n
		table.insert(pts, a:Lerp(b, t) - Vector3.new(0, sag * 4 * t * (1 - t), 0))
	end
	for i = 1, n do
		r:beam(pts[i], pts[i + 1], thick, thick, color, mat or "Fabric")
	end
	return pts
end

-- A string of bulbs on a wire from a to b, lit.
local function stringLights(r: R, a: Vector3, b: Vector3, sag: number, bulbs: number, colors: { Color3 })
	local pts = sagging(r, a, b, sag, 8, 0.06, rgb(60, 56, 64), "Plastic")
	for i = 1, bulbs do
		local t = (i - 0.5) / bulbs
		local p = a:Lerp(b, t) - Vector3.new(0, sag * 4 * t * (1 - t), 0)
		r:box(p.X, p.Y - 0.12, p.Z, 0.12, 0.14, 0.12, rgb(70, 66, 72), "Metal")
		local bulb = r:ball(p.X, p.Y - 0.36, p.Z, 0.34, colors[(i - 1) % #colors + 1], "Neon")
		-- (every fourth bulb lights what is under it; the rest only glow)
		r:glow(bulb, if i % 4 == 2 then 12 else 0, 0.7, colors[(i - 1) % #colors + 1])
	end
	return pts
end

-- Little flags on a cord from a to b.
local function bunting(r: R, a: Vector3, b: Vector3, sag: number, flags: number, colors: { Color3 })
	sagging(r, a, b, sag, 8, 0.05, rgb(236, 230, 214), "Fabric")
	local across = (b - a)
	local flat = Vector3.new(across.X, 0, across.Z).Unit
	for i = 1, flags do
		local t = (i - 0.5) / flags
		local p = a:Lerp(b, t) - Vector3.new(0, sag * 4 * t * (1 - t) + 0.04, 0)
		local half = 0.42
		r:tri(
			p - flat * half,
			p + flat * half,
			p - Vector3.new(0, 0.95, 0),
			0.04,
			colors[(i - 1) % #colors + 1],
			"Fabric"
		)
	end
end

-- A flower pot: the pot, its rim, the soil and a bush of leaves with a few flowers.
local function pot(r: R, x: number, y: number, z: number, size: number, potColor: Color3, flower: Color3?)
	local s = size
	r:cyl(x, y + 0.45 * s, z, 0.9 * s, 1.1 * s, "y", potColor, "Slate")
	r:cyl(x, y + 0.91 * s, z, 0.14 * s, 1.26 * s, "y", shade(potColor, 1.08), "Slate")
	r:cyl(x, y + 0.97 * s, z, 0.1 * s, 1.0 * s, "y", C.Soil, "Ground")
	r:lump(CFrame.new(x, y + 1.45 * s, z), 1.4 * s, 1.1 * s, 1.4 * s, C.Leaf, "Grass")
	r:lump(CFrame.new(x + 0.3 * s, y + 1.85 * s, z - 0.2 * s), 0.9 * s, 0.8 * s, 0.9 * s, C.DarkLeaf, "Grass")
	if flower then
		for i = 0, 2 do
			local a = i * 2.1
			r:ball(
				x + math.cos(a) * 0.5 * s,
				y + 1.95 * s,
				z + math.sin(a) * 0.5 * s,
				0.32 * s,
				flower,
				"SmoothPlastic"
			)
		end
	end
end

-- A wooden crate: its boards and corner posts.
local function crate(r: R, cf: CFrame, w: number, h: number, d: number, color: Color3)
	local dark = shade(color, 0.78)
	r:boxAt(cf * CFrame.new(0, h / 2, 0), w - 0.16, h - 0.16, d - 0.16, dark, "WoodPlanks")
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			r:boxAt(cf * CFrame.new(sx * (w / 2 - 0.1), h / 2, sz * (d / 2 - 0.1)), 0.2, h, 0.2, color, "WoodPlanks")
		end
	end
	for _, y in { 0.18, h - 0.18 } do
		for _, sz in { -1, 1 } do
			r:boxAt(cf * CFrame.new(0, y, sz * (d / 2 - 0.04)), w - 0.4, 0.26, 0.08, color, "WoodPlanks")
		end
		for _, sx in { -1, 1 } do
			r:boxAt(cf * CFrame.new(sx * (w / 2 - 0.04), y, 0), 0.08, 0.26, d - 0.4, color, "WoodPlanks")
		end
	end
end

-- A far building drawn as a shape against the sky, with a few lit windows on the side that
-- faces the set (+Z). Far away, in the haze's colour.
local function farBlock(
	r: R,
	x: number,
	z: number,
	w: number,
	d: number,
	base: number,
	top: number,
	color: Color3,
	lit: Color3?,
	seed: number,
	roof: string?
)
	r:block(x - w / 2, base, z - d / 2, x + w / 2, top, z + d / 2, color, "SmoothPlastic")
	if roof == "gable" then
		local rise = math.min(w, 10) * 0.35
		r:wedge(CFrame.new(x - w / 4, top + rise / 2, z) * yaw(-90), d, rise, w / 2, color, "SmoothPlastic")
		r:wedge(CFrame.new(x + w / 4, top + rise / 2, z) * yaw(90), d, rise, w / 2, color, "SmoothPlastic")
	elseif roof == "spire" then
		r:cone(x, top + 4, z, 8, math.min(w, d) * 0.7, color, "SmoothPlastic")
	elseif roof == "tank" then
		r:cyl(x + w * 0.2, top + 1.4, z, 2.8, 2.4, "y", color, "SmoothPlastic")
	end
	if lit then
		local next = rand(seed)
		local cols = math.max(1, math.floor(w / 3.2))
		local rows = math.max(1, math.floor((top - base) / 4.2))
		for i = 0, cols - 1 do
			for j = 0, rows - 1 do
				if next() < 0.32 then
					local wx = x - w / 2 + (i + 0.5) * w / cols
					local wy = top - 2.4 - j * 4.2
					if wy > base + 1 then
						r:box(wx, wy, z + d / 2 + 0.05, 1.1, 1.5, 0.1, lit, "Neon")
					end
				end
			end
		end
	end
end

-- New for the sets drawn in the world ------------------------------------------------------------------

-- A lamp post that really lights: a foot, a fluted pole, an arm and a lantern of glass round a
-- bulb, with a cap. `h` is how tall; the light is warm unless `color` says.
local function lampPost(r: R, x: number, y: number, z: number, h: number, color: Color3?, range: number?)
	local IRON = rgb(52, 52, 60)
	local warm = color or rgb(255, 214, 150)
	r:cyl(x, y + 0.3, z, 0.6, 0.9, "y", IRON, "Metal")
	r:cyl(x, y + 0.75, z, 0.3, 0.6, "y", IRON, "Metal")
	r:cyl(x, y + h / 2, z, h - 1.2, 0.26, "y", IRON, "Metal")
	r:cyl(x, y + h - 0.7, z, 0.2, 0.5, "y", IRON, "Metal")
	r:box(x, y + h - 0.55, z, 0.9, 0.1, 0.9, IRON, "Metal")
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			r:box(x + sx * 0.4, y + h + 0.05, z + sz * 0.4, 0.08, 1.1, 0.08, IRON, "Metal")
		end
	end
	r:glass(x - 0.38, y + h - 0.5, z - 0.38, x + 0.38, y + h + 0.6, z + 0.38)
	r:glow(r:ball(x, y + h + 0.05, z, 0.5, warm, "Neon"), range or 20, 1.6, warm)
	r:box(x, y + h + 0.66, z, 1.0, 0.12, 1.0, IRON, "Metal")
	r:cone(x, y + h + 0.95, z, 0.5, 0.9, IRON, "Metal")
	r:ball(x, y + h + 1.25, z, 0.18, IRON, "Metal")
end

-- A tree drawn round: a trunk that leans a little as it climbs, roots at its foot, a few
-- branches and a crown of soft balls of leaves in two greens (or the colours given).
local function roundTree(r: R, x: number, y: number, z: number, h: number, seed: number, leaf: Color3?, leaf2: Color3?)
	local next = rand(seed)
	local BARK = rgb(112, 84, 66)
	local a, b = leaf or rgb(96, 150, 84), leaf2 or rgb(72, 124, 70)
	local base = Vector3.new(x, y, z)
	local lean = Vector3.new((next() - 0.5) * 1.2, 0, (next() - 0.5) * 1.2)
	local pts = { base }
	for i = 1, 4 do
		local t = i / 4
		table.insert(pts, base + Vector3.new(0, h * 0.62 * t, 0) + lean * t * t)
	end
	for i = 1, 4 do
		local w = 1.1 - i * 0.16
		r:beam(pts[i], pts[i + 1], w, w, BARK, "Wood")
		r:ball(pts[i + 1].X, pts[i + 1].Y, pts[i + 1].Z, w * 1.02, BARK, "Wood")
	end
	for k = 0, 3 do
		local ang = k * math.pi / 2 + next()
		local tip = base + Vector3.new(math.cos(ang) * 1.3, 0.1, math.sin(ang) * 1.3)
		r:beam(base + Vector3.new(0, 0.5, 0), tip, 0.4, 0.3, BARK, "Wood")
	end
	local top = pts[5]
	for k = 0, 2 do
		local ang = k * 2.1 + next()
		local tip = top + Vector3.new(math.cos(ang) * h * 0.22, h * 0.12, math.sin(ang) * h * 0.22)
		r:beam(pts[4], tip, 0.4, 0.4, BARK, "Wood")
	end
	local crown = h * 0.24
	for k = 1, 9 do
		local ang = next() * math.pi * 2
		local d = next() * crown * 0.9
		local s = crown * (0.75 + next() * 0.5)
		local c = top + Vector3.new(math.cos(ang) * d, crown * 0.35 + (next() - 0.3) * crown * 0.6, math.sin(ang) * d)
		local leafBall = r:ball(c.X, c.Y, c.Z, s, if k % 3 == 0 then b else a, "Grass")
		leafBall.name = "Leaf"
	end
end

-- Tufts of grass: three thin blades each, leaning out, scattered over a patch (x1..x2, z1..z2) at
-- the height of the ground there.
local function tufts(
	r: R,
	x1: number,
	z1: number,
	x2: number,
	z2: number,
	y: number,
	n: number,
	seed: number,
	color: Color3?
)
	local next = rand(seed)
	local g = color or rgb(104, 150, 82)
	for _ = 1, n do
		local x, z = x1 + next() * (x2 - x1), z1 + next() * (z2 - z1)
		local turn = next() * 360
		for k = -2, 2 do
			local h = 0.45 + next() * 0.45
			r:boxAt(
				CFrame.new(x, y - 0.05, z)
					* yaw(turn + k * 40)
					* CFrame.Angles(0, 0, math.rad(k * 14))
					* CFrame.new(0, h / 2, 0),
				0.16,
				h,
				0.06,
				shade(g, 0.92 + next() * 0.22),
				"Grass"
			).collide =
				false
		end
	end
end

-- Little flowers on stems over a patch: a stem, two leaves and a round head.
local function flowers(
	r: R,
	x1: number,
	z1: number,
	x2: number,
	z2: number,
	y: number,
	n: number,
	seed: number,
	colors: { Color3 }
)
	local next = rand(seed)
	for i = 1, n do
		local x, z = x1 + next() * (x2 - x1), z1 + next() * (z2 - z1)
		local h = 0.5 + next() * 0.6
		local made = {
			r:cyl(x, y + h / 2, z, h, 0.06, "y", rgb(84, 132, 70), "Grass"),
			r:boxAt(
				CFrame.new(x + 0.1, y + h * 0.4, z) * CFrame.Angles(0, 0, math.rad(-40)),
				0.24,
				0.05,
				0.12,
				rgb(96, 150, 80),
				"Grass"
			),
			r:ball(x, y + h + 0.08, z, 0.26, colors[(i - 1) % #colors + 1], "SmoothPlastic"),
			r:ball(x, y + h + 0.12, z, 0.1, rgb(250, 220, 120), "SmoothPlastic"),
		}
		-- (feet go through them: the camera's checks and the marks' room leave them out)
		for _, p in made do
			p.collide = false
		end
	end
end

-- A puff of cloud: soft round balls heaped together, flatter underneath.
local function cloud(r: R, cf: CFrame, size: number, seed: number, color: Color3?)
	local next = rand(seed)
	local c = color or rgb(246, 246, 250)
	for k = 1, 7 do
		local x = (next() - 0.5) * size * 1.6
		local yy = next() * size * 0.35
		local zz = (next() - 0.5) * size * 0.5
		local s = size * (0.55 + next() * 0.5) * (1 - math.abs(x) / (size * 1.9))
		r:lump(cf * CFrame.new(x, yy, zz), s * 1.2, s * 0.9, s, c, "SmoothPlastic")
	end
	r:lump(cf * CFrame.new(0, -size * 0.05, 0), size * 2.2, size * 0.45, size * 0.8, shade(c, 0.94), "SmoothPlastic")
end

-- A piece from Build mode's catalog, drawn as players get it (detailed furniture and the rest),
-- set down at `cf` in its own colours (or the two given, as hex).
local function item(r: R, id: string, cf: CFrame, c1: string?, c2: string?)
	local Catalog = require(script.Parent.Parent.Parent.Build.Catalog) :: any
	local def = Catalog.get(id)
	assert(def, "no catalog item " .. id)
	for _, p in Catalog.prims(def, c1, c2) do
		if (p.transp or 0) < 0.99 then
			local q = table.clone(p)
			q.cf = cf * p.cf
			r:add(q)
		end
	end
end

-- A window in a wall that runs along X with its face at z, its sill at y: a frame, glazing
-- bars and the sill, with the night (or the day) behind it as a pane of its own colour.
local function window(
	r: R,
	x: number,
	y: number,
	z: number,
	w: number,
	h: number,
	frame: Color3,
	behind: Color3,
	out: number?
)
	local d = out or 1
	r:block(x - w / 2, y, z - 0.05 * d, x + w / 2, y + h, z - 0.12 * d, behind, "Glass")
	r:block(x - w / 2 - 0.2, y + h, z - 0.1 * d, x + w / 2 + 0.2, y + h + 0.2, z + 0.12 * d, frame, "Wood")
	r:block(x - w / 2 - 0.2, y - 0.2, z - 0.1 * d, x + w / 2 + 0.2, y, z + 0.12 * d, frame, "Wood")
	r:block(x - w / 2 - 0.35, y - 0.32, z - 0.1 * d, x + w / 2 + 0.35, y - 0.2, z + 0.42 * d, frame, "Wood")
	r:block(x - w / 2 - 0.2, y, z - 0.1 * d, x - w / 2, y + h, z + 0.12 * d, frame, "Wood")
	r:block(x + w / 2, y, z - 0.1 * d, x + w / 2 + 0.2, y + h, z + 0.12 * d, frame, "Wood")
	r:block(x - 0.06, y, z - 0.03 * d, x + 0.06, y + h, z + 0.06 * d, frame, "Wood")
	r:block(x - w / 2, y + h / 2 - 0.06, z - 0.03 * d, x + w / 2, y + h / 2 + 0.06, z + 0.06 * d, frame, "Wood")
end

-- A picture in a frame hung on a wall facing +Z at z: the frame and the picture inside it, a few
-- bands of colour for whatever it shows.
local function picture(r: R, x: number, y: number, z: number, w: number, h: number, frame: Color3, colors: { Color3 })
	r:block(x - w / 2, y - h / 2, z, x + w / 2, y + h / 2, z + 0.12, frame, "Wood")
	local n = #colors
	for i, c in colors do
		local y1 = y - h / 2 + 0.15 + (i - 1) * (h - 0.3) / n
		r:block(x - w / 2 + 0.15, y1, z + 0.12, x + w / 2 - 0.15, y1 + (h - 0.3) / n, z + 0.16, c, "SmoothPlastic")
	end
end

-- A row of books on a shelf: thin spines of different heights and colours from x1 to x2, standing
-- on `y`, their backs at z (spines facing +Z).
local function books(r: R, x1: number, x2: number, y: number, z: number, seed: number)
	local next = rand(seed)
	local COLS = {
		rgb(150, 70, 66),
		rgb(70, 96, 140),
		rgb(84, 120, 84),
		rgb(196, 160, 90),
		rgb(120, 84, 120),
		rgb(206, 196, 176),
	}
	local x = x1
	while x < x2 - 0.2 do
		local w = 0.14 + next() * 0.14
		local h = 0.75 + next() * 0.4
		r:block(x, y, z, x + w, y + h, z + 0.7, COLS[math.floor(next() * #COLS) + 1], "Fabric")
		x += w + 0.02
	end
end

-- Where a catalog piece's seat or bed is (its `role`, "seat" or "bed"), in the piece's own space,
-- so a mark can be put on it: its top's middle.
local function spotOf(id: string, role: string): Vector3
	local Catalog = require(script.Parent.Parent.Parent.Build.Catalog) :: any
	for _, p in Catalog.prims(Catalog.get(id)) do
		if p.role == role then
			return p.cf.Position - Vector3.new(0, 0.1, 0)
		end
	end
	error("no " .. role .. " on " .. id)
end

K.spotOf = spotOf
K.rgb = rgb
K.yaw = yaw
K.v3 = v3
K.shade = shade
K.town = town
K.rand = rand
K.boards = boards
K.sagging = sagging
K.stringLights = stringLights
K.bunting = bunting
K.pot = pot
K.crate = crate
K.farBlock = farBlock
K.lampPost = lampPost
K.roundTree = roundTree
K.tufts = tufts
K.flowers = flowers
K.cloud = cloud
K.item = item
K.window = window
K.picture = picture
K.books = books

return K
