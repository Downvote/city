--!strict
-- The sets the big moments of villagers' lives are staged on (UI/Cutscene plays them, Data/Cutscenes
-- says which event plays on which). The user: "add cutscenes and scenes like tomodachi life as
-- well". Taken from that kind of game: a big moment plays as a little scene on a set of its own,
-- with the camera cutting between shots and the light set for the mood. Everything here is our
-- own: the sets, the shots and the light.
--
-- A set is built from primitives like any model in town, in its own space: the origin is the
-- middle of where the villagers stand, at the height of what they stand on, +Y up, and the camera
-- usually looks toward -Z (the back of the set) from the +Z side. It is shown in a ViewportFrame,
-- so it has its own light (ambient, a sun and the way it shines, as the frame takes them) and a
-- painted sky behind it (top, a middle band, the horizon and below it, with a sun or a moon and
-- stars where the hour has them). A viewport has no shadows, no fog and no lamps that light
-- things, so a lit window or a lantern is simply drawn bright (Neon) and the far town is
-- painted in the haze's colours.
--
-- Each set has:
--   marks   where up to three villagers stand: `at` (their feet), `yaw` (which way they face:
--           0 is +Z, toward the camera's side, 90 is +X), `sit` (sitting with `at` on the seat)
--   shots   camera positions by name: `eye`, `look`, `fov` (degrees, top to bottom). A shot with
--           `to` moves from its own eye and look to those over the line (a pan). Every set has a
--           `wide`, a `two` (the first two marks) and a `pan`. A close shot on each mark and a
--           push in on it are worked out from the mark (Stages.close, Stages.push) unless the
--           mark gives its own `close`.
--   bounds  the box the camera keeps inside
--   light   ambient, colour, dir (the way the light travels, as ViewportFrame.LightDirection)
--   sky     top, mid, horizon, low, sun / moon (dir toward it, size in pixels on a 720 high
--           screen, colour, glow, phase: how much of a moon is cut away), stars (how many)
-- The Cutscenes spec holds every shot inside the bounds, clear of the set, looking at something,
-- and every move between two shots clear of the set too.

local Recipe = require(script.Parent.Parent.Build.Recipe)
local Geometry = require(script.Parent.Parent.Build.Geometry)

type R = Recipe.Recipe
type Prim = Geometry.Prim

export type Shot = { eye: Vector3, look: Vector3, fov: number, to: Shot?, sky: boolean? }
export type Mark = { at: Vector3, yaw: number, sit: boolean?, close: Shot? }
export type Light = { ambient: Color3, color: Color3, dir: Vector3 }
export type Disc = { dir: Vector3, size: number, color: Color3, glow: Color3?, phase: number? }
export type Sky = {
	top: Color3,
	mid: Color3?,
	horizon: Color3,
	low: Color3,
	sun: Disc?,
	moon: Disc?,
	stars: number?,
}
export type Stage = {
	id: string,
	name: string,
	marks: { Mark },
	shots: { [string]: Shot },
	bounds: { lo: Vector3, hi: Vector3 },
	light: Light,
	sky: Sky,
	build: (R) -> (),
}

local Stages = {}

Stages.Head = 4.6 -- a standing villager's eyes over their feet
Stages.SitHead = 2.9 -- and a sitting one's over the seat
-- A close shot: how far, how far round, the lens, how far over their eyes it stands, and how far
-- under them it looks (the textbox covers the bottom of the screen, so the face sits high).
Stages.Close = { dist = 6.6, side = 52, fov = 30, lift = 0.3, drop = 0.55 }
Stages.Push = { dist = 5.4, fov = 26, drop = 0.45 } -- where a push in ends

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
-- the same ones the town has. On a set they are only scenery: no seats, lamps that light things
-- or smoke, and with `lit` what lights up at night is drawn lit. (The list a model comes in may
-- be shared: each prim is copied.)
local function town(r: R, name: string, cf: CFrame, lit: boolean?)
	local TownMap = require(script.Parent.TownMap) :: any
	for _, p in TownMap.prims(name) do
		if (p.transp or 0) < 0.99 then
			local q = table.clone(p)
			q.cf = cf * p.cf
			if lit and q.role == "glow" then
				q.mat = "Neon"
			end
			q.role, q.light, q.effect = nil, nil, nil
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
		r:ball(p.X, p.Y - 0.36, p.Z, 0.34, colors[(i - 1) % #colors + 1], "Neon")
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

-- The sets -----------------------------------------------------------------------------------------

local list: { Stage } = {}

local function stage(def: Stage)
	table.insert(list, def)
end

-- A rooftop at sunset over the town. A roof five storeys up: its parapet and a railing along
-- the back, a timber deck where the two of them stand, the stair's hood with its door and lamp,
-- a water tank on its legs, a chimney stack, the washing on a line and pots of flowers. Lights
-- strung over the deck are just coming on. Beyond the parapet the town goes on in the haze, its
-- windows lit, and the sun goes down behind it.
stage({
	id = "rooftop",
	name = "Rooftop at sunset",
	marks = {
		{ at = v3(-1.9, 0.3, -9.9), yaw = 72 },
		{ at = v3(1.9, 0.3, -9.9), yaw = -72 },
		{ at = v3(-6.4, 0.3, -5.6), yaw = 128 },
	},
	shots = {
		wide = { eye = v3(4, 6.4, 9), look = v3(-1, 3.6, -10), fov = 46 },
		two = { eye = v3(0.6, 5.2, -1.2), look = v3(0, 4.3, -9.8), fov = 36 },
		low = { eye = v3(-7.5, 1.6, 2), look = v3(-1, 5.8, -10), fov = 40 },
		sunset = { eye = v3(-2, 5.6, -1.8), look = v3(-14, 9, -60), fov = 44 },
		pan = {
			eye = v3(-11, 7.2, 6),
			look = v3(-12, 4, -14),
			fov = 44,
			to = { eye = v3(6, 6.8, 4), look = v3(0, 4.2, -12), fov = 40 },
		},
	},
	bounds = { lo = v3(-16.5, 0.8, -15), hi = v3(16.5, 16, 12.5) },
	light = { ambient = rgb(150, 122, 152), color = rgb(255, 178, 122), dir = v3(0.78, -0.34, 0.52) },
	sky = {
		top = rgb(84, 82, 156),
		mid = rgb(206, 120, 150),
		horizon = rgb(255, 170, 104),
		low = rgb(160, 104, 120),
		sun = { dir = v3(-0.3, 0.13, -1), size = 92, color = rgb(255, 214, 140), glow = rgb(255, 150, 96) },
	},
	build = function(r: R)
		local FELT = rgb(150, 140, 146)
		local BRICK = rgb(176, 108, 92)
		local CAP = rgb(206, 196, 184)
		local WOOD = rgb(178, 132, 92)
		local IRON = rgb(58, 56, 66)
		local PLASTER = rgb(226, 206, 184)
		-- the roof itself, and the timber deck on it
		r:block(-18, -1.2, -16, 18, 0, 14, FELT, "Slate")
		for i = 0, 5 do
			-- the felt's seams, laid side by side across the roof
			local z = -15 + i * 5
			r:block(-17.6, 0, z - 0.06, 17.6, 0.04, z + 0.06, shade(FELT, 0.86), "Slate")
		end
		boards(r, -9, -13.4, 5, -1, 0.3, WOOD)
		-- the parapet: brick along the back and both sides, a coping on it, a railing over the back
		r:block(-18.8, 0, -16.8, 18.8, 1.8, -16, BRICK, "Brick")
		r:block(-18.8, 0, -16, -18, 1.8, 14, BRICK, "Brick")
		r:block(18, 0, -16, 18.8, 1.8, 14, BRICK, "Brick")
		r:block(-19, 1.8, -16, -17.8, 2.05, 14, CAP, "Concrete")
		r:block(17.8, 1.8, -16, 19, 2.05, 14, CAP, "Concrete")
		r:block(-19, 1.8, -17, 19, 2.05, -16, CAP, "Concrete")
		for x = -18, 18, 3 do
			r:box(x, 3.15, -16.4, 0.14, 2.2, 0.14, IRON, "Metal")
		end
		r:block(-18.2, 4.12, -16.5, 18.2, 4.26, -16.3, IRON, "Metal")
		r:block(-18.2, 3.12, -16.46, 18.2, 3.2, -16.34, IRON, "Metal")
		-- the stair's hood: plaster walls, a flat roof with an overhang, a door with its frame and a
		-- lamp over it, a little window on the side, a vent on top
		r:block(9.5, 0, -12.5, 15.5, 7.4, -7.6, PLASTER, "Plaster")
		r:block(9.2, 7.4, -12.8, 15.8, 7.8, -7.1, CAP, "Concrete")
		r:block(11.25, 0.04, -7.6, 13.75, 5.7, -7.45, rgb(96, 128, 140), "Wood")
		r:block(11, 0, -7.55, 11.25, 5.95, -7.35, shade(PLASTER, 0.86), "Wood")
		r:block(13.75, 0, -7.55, 14, 5.95, -7.35, shade(PLASTER, 0.86), "Wood")
		r:block(11, 5.7, -7.55, 14, 5.95, -7.35, shade(PLASTER, 0.86), "Wood")
		r:box(13.3, 2.9, -7.36, 0.2, 0.2, 0.18, C.Gold, "Metal")
		r:block(12.3, 6.25, -7.6, 12.7, 6.4, -7.0, IRON, "Metal")
		r:block(12.22, 6.4, -7.2, 12.78, 7.05, -6.68, rgb(255, 214, 150), "Neon")
		r:block(12.15, 7.05, -7.25, 12.85, 7.15, -6.62, IRON, "Metal")
		r:block(9.35, 3.6, -11.2, 9.5, 5.2, -9.2, rgb(70, 74, 96), "Glass")
		r:block(9.3, 3.45, -11.35, 9.5, 3.6, -9.05, CAP, "Concrete")
		r:cyl(14.4, 8.6, -11.6, 1.6, 0.6, "y", IRON, "Metal")
		r:cyl(14.4, 9.5, -11.6, 0.2, 1.0, "y", IRON, "Metal")
		-- a box for the air that hums by the hood, its fan on top and its pipe into the wall
		r:block(4.2, 0, -14.8, 7.0, 2.0, -12.6, rgb(206, 208, 212), "Metal")
		r:cyl(5.6, 2.05, -13.7, 0.1, 1.8, "y", rgb(84, 86, 96), "Metal")
		r:block(4.9, 2.1, -13.76, 6.3, 2.14, -13.64, rgb(140, 142, 150), "Metal")
		r:block(5.54, 2.1, -14.4, 5.66, 2.14, -13.0, rgb(140, 142, 150), "Metal")
		r:beam(v3(7.0, 1.0, -13.7), v3(9.5, 1.0, -11.8), 0.25, 0.25, rgb(140, 142, 150), "Metal")
		-- the water tank on four legs, braced, with its bands, a pointed lid and a ladder
		local tx, tz = -13, -11.4
		for _, sx in { -1, 1 } do
			for _, sz in { -1, 1 } do
				r:box(tx + sx * 1.8, 3, tz + sz * 1.8, 0.36, 6, 0.36, rgb(96, 70, 54), "Wood")
			end
			r:beam(
				v3(tx + sx * 1.8, 0.6, tz - 1.8),
				v3(tx + sx * 1.8, 5.2, tz + 1.8),
				0.16,
				0.2,
				rgb(110, 80, 60),
				"Wood"
			)
		end
		r:block(tx - 2.3, 6, tz - 2.3, tx + 2.3, 6.3, tz + 2.3, rgb(110, 80, 60), "WoodPlanks")
		r:cyl(tx, 8.55, tz, 4.5, 4, "y", rgb(150, 110, 80), "WoodPlanks")
		for _, y in { 7.0, 8.55, 10.1 } do
			r:cyl(tx, y, tz, 0.18, 4.14, "y", IRON, "Metal")
		end
		r:cone(tx, 11.6, tz, 1.6, 4.4, rgb(112, 86, 70), "Wood")
		for _, sx in { -0.35, 0.35 } do
			r:box(tx + 1.8 + sx, 3.15, tz + 2.05, 0.1, 6.3, 0.1, IRON, "Metal")
		end
		for y = 0.6, 5.8, 0.65 do
			r:box(tx + 1.8, y, tz + 2.05, 0.7, 0.08, 0.08, IRON, "Metal")
		end
		-- a chimney stack of brick with its pots
		r:block(-5.2, 0, -15.95, -2.6, 4.2, -14.4, BRICK, "Brick")
		r:block(-5.35, 4.2, -16.1, -2.45, 4.45, -14.25, CAP, "Concrete")
		for _, x in { -4.4, -3.4 } do
			r:cyl(x, 4.95, -15.2, 1.0, 0.56, "y", rgb(190, 112, 86), "Slate")
			r:cyl(x, 5.5, -15.2, 0.12, 0.66, "y", rgb(170, 98, 76), "Slate")
		end
		-- the washing line on two posts, with a shirt, a towel, socks and a sheet pegged to it
		for _, x in { -16, -9 } do
			r:box(x, 2.6, 7, 0.24, 5.2, 0.24, rgb(200, 196, 186), "Metal")
			r:box(x, 5.1, 7, 0.16, 0.16, 1.6, rgb(200, 196, 186), "Metal")
		end
		local line = sagging(r, v3(-16, 5.05, 7.5), v3(-9, 5.05, 7.5), 0.35, 6, 0.05, rgb(240, 236, 226))
		local function hang(t: number, w: number, h: number, color: Color3)
			local i = math.clamp(math.floor(t * 6) + 1, 1, 6)
			local p = line[i]:Lerp(line[i + 1], t * 6 - (i - 1))
			r:box(p.X, p.Y - 0.1 - h / 2, p.Z, w, h, 0.06, color, "Fabric")
			r:box(p.X - w * 0.3, p.Y - 0.02, p.Z, 0.08, 0.22, 0.12, rgb(222, 120, 96), "Plastic")
			r:box(p.X + w * 0.3, p.Y - 0.02, p.Z, 0.08, 0.22, 0.12, rgb(222, 120, 96), "Plastic")
		end
		hang(0.14, 1.3, 1.5, rgb(236, 232, 220))
		hang(0.36, 1.1, 1.8, rgb(126, 176, 196))
		hang(0.55, 0.36, 0.7, rgb(232, 196, 112))
		hang(0.62, 0.36, 0.7, rgb(232, 196, 112))
		hang(0.82, 1.5, 2.0, rgb(240, 210, 214))
		-- pots of flowers along the left wall, and a bench of the town's
		pot(r, -16.6, 0, -6, 1.1, rgb(196, 110, 84), rgb(244, 150, 170))
		pot(r, -16.6, 0, -2.6, 0.9, rgb(206, 186, 160), rgb(250, 220, 120))
		pot(r, -16.6, 0, 1, 1.2, rgb(150, 156, 170), nil)
		pot(r, 6.6, 0, -9.6, 0.9, rgb(196, 110, 84), rgb(250, 200, 120))
		town(r, "bench", CFrame.new(-12.4, 0, -4.6) * yaw(90))
		-- a pole at the deck's corner, and lights strung from it to the hood and the tank
		r:cyl(-9.4, 4.1, -0.6, 8.2, 0.3, "y", IRON, "Metal")
		r:cyl(-9.4, 0.12, -0.6, 0.24, 1.0, "y", IRON, "Metal")
		r:box(-9.4, 8.0, -0.6, 0.12, 0.12, 0.9, IRON, "Metal")
		local warm = { rgb(255, 222, 150), rgb(255, 200, 130), rgb(255, 236, 190) }
		stringLights(r, v3(-9.4, 8.0, -0.6), v3(9.4, 7.3, -7.6), 0.5, 14, warm)
		-- the town beyond, in the haze: roofs and towers with their windows lit, nearest first
		local lit = rgb(255, 206, 140)
		local next = rand(7)
		local x = -150
		local k = 0
		while x < 150 do
			k += 1
			local w = 10 + next() * 14
			local z = -72 - next() * 30
			local h = -12 + next() * 16
			local roof = ({ "", "gable", "", "tank", "", "gable" })[k % 6 + 1]
			farBlock(r, x + w / 2, z, w, 10, -40, h, rgb(124, 96, 136), lit, k * 13, roof)
			x += w + 1 + next() * 4
		end
		x = -170
		while x < 170 do
			k += 1
			local w = 14 + next() * 18
			local z = -140 - next() * 34
			local h = -4 + next() * 24
			local roof = if k % 9 == 0 then "spire" else ""
			farBlock(r, x + w / 2, z, w, 12, -40, h, rgb(150, 106, 140), lit, k * 7, roof)
			x += w + 2 + next() * 6
		end
	end,
})

-- The pier at night. Boards out over the water on their piles, a rope along each side, lanterns
-- on posts, and a wider end with a bench, crates, a coil of rope and a life ring. A rowboat is
-- tied up alongside. Out on the water the lighthouse is lit, the shore's windows glow far off
-- and the moon lays a path of light on the sea.
stage({
	id = "pier",
	name = "The pier at night",
	marks = {
		{ at = v3(-1.8, 0, -30.5), yaw = 70 },
		{ at = v3(1.8, 0, -30.5), yaw = -70 },
		{ at = v3(5.6, 0, -27.4), yaw = -125 },
	},
	shots = {
		wide = { eye = v3(5.4, 6.2, -11), look = v3(-0.5, 2.8, -31), fov = 46 },
		two = { eye = v3(0.3, 4.8, -22.5), look = v3(0, 4.3, -30.5), fov = 34 },
		low = { eye = v3(-3.2, 1.5, -20), look = v3(0, 5.2, -31), fov = 42 },
		moon = { eye = v3(2, 4.6, -23), look = v3(-20, 21, -63), fov = 46, sky = true },
		high = { eye = v3(0, 12, -14), look = v3(0, 1, -31), fov = 44 },
		pan = {
			eye = v3(-6.4, 7, 6),
			look = v3(-2, 2, -20),
			fov = 46,
			to = { eye = v3(6, 6, -12), look = v3(0, 3, -32), fov = 42 },
		},
	},
	bounds = { lo = v3(-8.5, 1, -36), hi = v3(8.5, 14, 12) },
	light = { ambient = rgb(84, 94, 142), color = rgb(176, 196, 255), dir = v3(0.86, -0.42, 0.3) },
	sky = {
		top = rgb(14, 18, 48),
		mid = rgb(30, 38, 86),
		horizon = rgb(66, 74, 128),
		low = rgb(18, 24, 58),
		moon = {
			dir = v3(-0.5, 0.42, -1),
			size = 74,
			color = rgb(236, 230, 184),
			glow = rgb(96, 116, 184),
			phase = 0.32,
		},
		stars = 70,
	},
	build = function(r: R)
		local WOOD = rgb(132, 104, 84)
		local PILE = rgb(92, 74, 62)
		local ROPE = rgb(206, 186, 146)
		local IRON = rgb(46, 46, 56)
		local LAMP = rgb(255, 210, 140)
		local SEA = rgb(30, 52, 96)
		-- the sea, and the moon's path on it (strips lying on the water toward the moon)
		r:block(-320, -4.4, -420, 320, -3.2, 160, SEA, "SmoothPlastic")
		local next = rand(3)
		for i = 0, 26 do
			local z = -44 - i * 9 - next() * 4
			local x = z * 0.5 + (next() - 0.5) * 6
			local w = 1.4 + next() * (2 + i * 0.25)
			r:block(x - w / 2, -3.2, z - 0.3, x + w / 2, -3.16, z + 0.3, rgb(150, 170, 222), "SmoothPlastic")
		end
		-- the boards, out to the wider end
		boards(r, -4, -27, 4, 18, 0, WOOD, PILE)
		boards(r, -9, -38, 9, -27, 0, WOOD, PILE)
		-- piles down into the water, standing a little over the boards along the edges, with a rope
		-- strung between them; beams across under the boards
		local posts: { Vector3 } = {}
		for z = 16, -24, -5 do
			for _, x in { -4.35, 4.35 } do
				r:cyl(x, -2.0, z, 7.2, 0.7, "y", PILE, "Wood")
				r:cyl(x, 1.62, z, 0.06, 0.5, "y", shade(PILE, 0.8), "Wood")
				table.insert(posts, v3(x, 1.3, z))
			end
			r:block(-4.7, -0.86, z - 0.3, 4.7, -0.46, z + 0.3, PILE, "Wood")
		end
		for z = -27.4, -38, -3.5 do
			for _, x in { -9.35, 9.35 } do
				r:cyl(x, -2.0, z, 7.2, 0.7, "y", PILE, "Wood")
				r:cyl(x, 1.62, z, 0.06, 0.5, "y", shade(PILE, 0.8), "Wood")
			end
		end
		for x = -6.5, 6.5, 3.25 do
			r:cyl(x, -2.0, -38.35, 7.2, 0.7, "y", PILE, "Wood")
			r:cyl(x, 1.62, -38.35, 0.06, 0.5, "y", shade(PILE, 0.8), "Wood")
		end
		for _, x in { -4.35, 4.35 } do
			for z = 16, -19, -5 do
				sagging(r, v3(x, 1.3, z), v3(x, 1.3, z - 5), 0.22, 3, 0.1, ROPE)
			end
			sagging(r, v3(x, 1.3, -24), v3(x * 2.15, 1.3, -27.4), 0.2, 3, 0.1, ROPE)
		end
		for _, x in { -9.35, 9.35 } do
			for z = -27.4, -34.4, -3.5 do
				sagging(r, v3(x, 1.3, z), v3(x, 1.3, z - 3.5), 0.18, 3, 0.1, ROPE)
			end
			sagging(r, v3(x, 1.3, -34.4), v3(x * 0.695, 1.3, -38.35), 0.18, 3, 0.1, ROPE)
		end
		for x = -6.5, 3.25, 3.25 do
			sagging(r, v3(x, 1.3, -38.35), v3(x + 3.25, 1.3, -38.35), 0.18, 3, 0.1, ROPE)
		end
		-- lanterns on posts: a square post, an arm and a lantern hanging from it, lit
		local function lantern(x: number, z: number, side: number)
			r:box(x, 3.7, z, 0.4, 7.4, 0.4, IRON, "Metal")
			r:box(x, 0.2, z, 0.8, 0.4, 0.8, IRON, "Metal")
			r:block(x, 7.0, z - 0.08, x + side * 1.5, 7.16, z + 0.08, IRON, "Metal")
			local hx = x + side * 1.3
			r:box(hx, 6.7, z, 0.08, 0.6, 0.08, IRON, "Metal")
			r:box(hx, 6.35, z, 0.9, 0.12, 0.9, IRON, "Metal")
			r:box(hx, 5.7, z, 0.6, 1.1, 0.6, LAMP, "Neon")
			for _, sx in { -1, 1 } do
				for _, sz in { -1, 1 } do
					r:box(hx + sx * 0.36, 5.7, z + sz * 0.36, 0.08, 1.1, 0.08, IRON, "Metal")
				end
			end
			r:box(hx, 5.1, z, 0.84, 0.1, 0.84, IRON, "Metal")
		end
		lantern(-4.9, 6, 1)
		lantern(4.9, -6, -1)
		lantern(-4.9, -18, 1)
		lantern(-9.9, -28, 1)
		lantern(9.9, -28, -1)
		lantern(-9.9, -37.6, 1)
		lantern(9.9, -37.6, -1)
		-- at the end: the town's bench, a stack of crates, a coil of rope, a cleat, a life ring on the
		-- rope and a bucket with a fishing rod leaning on the rail
		town(r, "bench", CFrame.new(0, 0, -36.4))
		crate(r, CFrame.new(-7.2, 0, -34.6) * yaw(8), 2, 1.6, 1.6, rgb(176, 136, 92))
		crate(r, CFrame.new(-7.0, 1.6, -34.4) * yaw(-10), 1.6, 1.3, 1.4, rgb(186, 146, 100))
		crate(r, CFrame.new(-5.2, 0, -35.6) * yaw(20), 1.6, 1.3, 1.4, rgb(166, 128, 86))
		r:cyl(6.6, 0.12, -35.4, 0.24, 2.2, "y", ROPE, "Fabric")
		r:cyl(6.6, 0.34, -35.4, 0.2, 1.7, "y", shade(ROPE, 0.9), "Fabric")
		r:cyl(6.6, 0.52, -35.4, 0.16, 1.1, "y", ROPE, "Fabric")
		r:block(-8.2, 0, -28.2, -7.6, 0.5, -27.6, IRON, "Metal")
		r:block(-8.5, 0.5, -28.06, -7.3, 0.7, -27.74, IRON, "Metal")
		-- (a white ring, with a red band round every other piece of it)
		for k = 0, 7 do
			local a = k * math.pi / 4
			local cf = CFrame.new(9.92, 1.5 + math.cos(a) * 0.95, -31 + math.sin(a) * 0.95) * CFrame.Angles(a, 0, 0)
			r:boxAt(cf, 0.34, 0.32, 0.84, rgb(246, 240, 230), "Plastic")
			if k % 2 == 0 then
				r:boxAt(cf, 0.4, 0.38, 0.5, rgb(232, 86, 76), "Plastic")
			end
		end
		r:cyl(-6.6, 0.55, -30.6, 1.1, 1.0, "y", rgb(106, 140, 170), "Metal")
		r:cyl(-6.6, 1.12, -30.6, 0.06, 1.06, "y", IRON, "Metal")
		r:beam(v3(-6.3, 0.9, -30.4), v3(-8.9, 4.6, -29.6), 0.08, 0.08, rgb(90, 70, 56), "Wood")
		-- the rowboat tied up alongside, low in the water, its rope to a pile
		town(r, "rowboat", CFrame.new(-7.2, -3.5, -13) * yaw(6))
		r:beam(v3(-6.4, -2.4, -9), v3(-4.35, 0.9, -9), 0.08, 0.08, ROPE, "Fabric")
		-- the lighthouse out on the water, lit, and the far shore with its windows
		town(r, "lighthouse", CFrame.new(76, -3.2, -190) * yaw(-30), true)
		for i = 0, 6 do
			r:lump(
				CFrame.new(60 + i * 34, -6, -250 - (i % 3) * 18),
				60,
				26 + (i % 2) * 10,
				40,
				rgb(26, 34, 66),
				"SmoothPlastic"
			)
		end
		for i = 0, 9 do
			local x = 80 + i * 22 + next() * 8
			farBlock(
				r,
				x,
				-222 - next() * 10,
				7 + next() * 6,
				6,
				-6,
				4 + next() * 9,
				rgb(36, 44, 80),
				rgb(255, 204, 132),
				40 + i,
				if i % 3 == 0 then "gable" else ""
			)
		end
	end,
})

-- The bandstand dressed for a concert: the town's own bandstand with a microphone, speakers, a
-- drum kit and a keyboard on it, a frame of lights over the front throwing coloured beams down
-- onto the boards, bunting from the roof, benches on the paving for the crowd, lamps and the
-- park's trees behind. Early evening.
stage({
	id = "bandstand",
	name = "The bandstand, lit for a concert",
	marks = {
		-- (the close shots look in through the opening at the front, between the pillars)
		{
			at = v3(-2.4, 1.7, 1.6),
			yaw = 14,
			close = { eye = v3(-1.1, 6.4, 7.6), look = v3(-2.4, 5.75, 1.6), fov = 30 },
		},
		{ at = v3(2.4, 1.7, 1.6), yaw = -14, close = { eye = v3(1.1, 6.4, 7.6), look = v3(2.4, 5.75, 1.6), fov = 30 } },
		{ at = v3(0, 1.7, -1.6), yaw = 0, close = { eye = v3(0, 6.6, 7.4), look = v3(0, 5.75, -1.6), fov = 30 } },
	},
	shots = {
		wide = { eye = v3(0, 6.8, 23), look = v3(0, 5, 0), fov = 42 },
		two = { eye = v3(0, 5.6, 12), look = v3(0, 5.6, 1.6), fov = 34 },
		crowd = { eye = v3(-6, 2.4, 16), look = v3(0, 6.4, 0), fov = 42 },
		high = { eye = v3(8, 13, 19), look = v3(0, 3.6, 0), fov = 42 },
		pan = {
			eye = v3(-10, 6.5, 22),
			look = v3(-3, 4.6, 0),
			fov = 42,
			to = { eye = v3(10, 6.5, 22), look = v3(3, 4.6, 0), fov = 42 },
		},
	},
	bounds = { lo = v3(-16, 1, -6), hi = v3(16, 16, 30) },
	light = { ambient = rgb(132, 112, 162), color = rgb(255, 196, 176), dir = v3(-0.62, -0.5, -0.6) },
	sky = {
		top = rgb(38, 42, 108),
		mid = rgb(116, 78, 148),
		horizon = rgb(240, 138, 136),
		low = rgb(60, 50, 92),
		stars = 24,
	},
	build = function(r: R)
		local GRASS = rgb(108, 150, 96)
		local PAVING = rgb(206, 196, 180)
		local IRON = rgb(44, 44, 54)
		local BLACK = rgb(40, 38, 46)
		r:block(-60, -1, -50, 60, 0, 60, GRASS, "Grass")
		r:block(-15, 0, 8.6, 15, 0.1, 32, PAVING, "Pavement")
		for z = 11, 31, 4 do
			r:block(-15, 0.1, z - 0.06, 15, 0.14, z + 0.06, shade(PAVING, 0.85), "Pavement")
		end
		town(r, "bandstand", CFrame.identity)
		local F = 1.7 -- the bandstand's floor
		-- a microphone on its stand at the front, to one side
		local mx, mz = -3.6, 4.4
		r:cyl(mx, F + 0.05, mz, 0.1, 1.0, "y", IRON, "Metal")
		r:cyl(mx, F + 2.0, mz, 3.9, 0.12, "y", IRON, "Metal")
		r:beam(v3(mx, F + 3.9, mz), v3(mx + 0.3, F + 4.4, mz - 0.4), 0.08, 0.08, IRON, "Metal")
		r:ball(mx + 0.36, F + 4.5, mz - 0.5, 0.34, rgb(80, 80, 92), "Metal")
		-- a speaker each side: a cabinet with two cones
		for _, sx in { -1, 1 } do
			local x = sx * 5.2
			r:block(x - 0.8, F, 1.4, x + 0.8, F + 2.8, 2.8, BLACK, "Plastic")
			for _, y in { F + 0.8, F + 2.0 } do
				r:cyl(x, y, 2.84, 0.08, if y < F + 1 then 1.1 else 0.7, "z", rgb(80, 80, 94), "Metal")
				r:cyl(x, y, 2.9, 0.06, 0.3, "z", rgb(130, 130, 140), "Metal")
			end
		end
		-- the drum kit: a bass drum on its side, a snare and a tom, a cymbal and a stool
		local dx, dz = -3.4, -3.6
		r:cyl(dx, F + 0.95, dz, 1.2, 1.9, "z", rgb(214, 90, 80), "Plastic")
		r:cyl(dx, F + 0.95, dz + 0.62, 0.06, 1.7, "z", rgb(240, 236, 226), "Plastic")
		r:cyl(dx + 1.4, F + 1.9, dz + 0.6, 0.5, 1.0, "y", rgb(214, 90, 80), "Plastic")
		r:cyl(dx + 1.4, F + 2.17, dz + 0.6, 0.04, 1.0, "y", rgb(240, 236, 226), "Plastic")
		r:cyl(dx + 1.4, F + 0.82, dz + 0.6, 1.66, 0.1, "y", IRON, "Metal")
		r:cyl(dx - 0.2, F + 2.35, dz + 0.1, 0.5, 0.8, "y", rgb(214, 90, 80), "Plastic")
		r:cyl(dx - 1.5, F + 1.8, dz + 0.8, 3.6, 0.08, "y", IRON, "Metal")
		r:cyl(dx - 1.5, F + 3.62, dz + 0.8, 0.04, 1.5, "y", C.Gold, "Metal")
		r:cyl(dx + 0.6, F + 0.75, dz - 1.4, 1.5, 0.1, "y", IRON, "Metal")
		r:cyl(dx + 0.6, F + 1.55, dz - 1.4, 0.2, 0.9, "y", BLACK, "Fabric")
		-- a keyboard on a crossed stand
		local kx, kz = 3.4, -3.4
		for _, sx in { -1, 1 } do
			r:beam(v3(kx + sx * 1.2, F, kz - 0.5), v3(kx - sx * 1.2, F + 2.5, kz - 0.1), 0.12, 0.12, IRON, "Metal")
		end
		r:block(kx - 1.9, F + 2.5, kz - 0.7, kx + 1.9, F + 2.8, kz + 0.5, BLACK, "Plastic")
		r:block(kx - 1.75, F + 2.8, kz - 0.1, kx + 1.75, F + 2.88, kz + 0.42, rgb(240, 238, 230), "Plastic")
		for i = 0, 9 do
			if i % 7 ~= 2 and i % 7 ~= 6 then
				local x = kx - 1.55 + i * 0.34
				r:block(x - 0.06, F + 2.88, kz - 0.1, x + 0.06, F + 2.96, kz + 0.16, BLACK, "Plastic")
			end
		end
		-- the frame of lights: two towers and a beam across, coloured lamps hanging from it, and
		-- the beams they throw (see-through)
		for _, sx in { -1, 1 } do
			local x = sx * 11.5
			for _, ox in { -0.5, 0.5 } do
				for _, oz in { -0.5, 0.5 } do
					r:box(x + ox, 5.6, 7 + oz, 0.14, 11.2, 0.14, rgb(190, 192, 200), "Metal")
				end
			end
			for y = 1, 11, 2 do
				r:box(x, y, 6.5, 1.0, 0.1, 0.1, rgb(190, 192, 200), "Metal")
				r:box(x, y, 7.5, 1.0, 0.1, 0.1, rgb(190, 192, 200), "Metal")
			end
			r:block(x - 0.9, 0, 6.1, x + 0.9, 0.3, 7.9, IRON, "Metal")
		end
		for _, dy in { 11.2, 10.4 } do
			for _, oz in { -0.5, 0.5 } do
				r:box(0, dy, 7 + oz, 23, 0.14, 0.14, rgb(190, 192, 200), "Metal")
			end
		end
		for x = -10, 10, 2 do
			r:beam(v3(x, 10.4, 6.5), v3(x + 1, 11.2, 7.5), 0.08, 0.08, rgb(190, 192, 200), "Metal")
		end
		local beams = { rgb(255, 120, 170), rgb(255, 210, 110), rgb(120, 200, 255), rgb(150, 240, 200) }
		for i, x in { -6, -2, 2, 6 } do
			local col = beams[i]
			r:box(x, 10.1, 7, 0.1, 0.5, 0.1, IRON, "Metal")
			local aim = v3(x * 0.3, F, 1)
			local from = v3(x, 9.6, 7)
			local dir = (aim - from).Unit
			r:beam(from - dir * 0.4, from + dir * 0.5, 0.9, 0.9, BLACK, "Metal")
			r:beam(from + dir * 0.5, from + dir * 0.56, 0.7, 0.7, col, "Neon")
			-- the beam: a long see-through cone from the lamp to the boards
			local len = (aim - from).Magnitude
			local mid = from + dir * (len / 2 + 0.56)
			local up = -dir
			local right = up:Cross(Vector3.new(0, 0, 1)).Unit
			local back = right:Cross(up)
			local p = r:add({
				shape = "Cone",
				cf = CFrame.fromMatrix(mid, right, up, back),
				size = v3(3.6, len - 1.1, 3.6),
				color = col,
				mat = "Neon",
			})
			p.transp = 0.9
			p.collide = false
		end
		-- bunting hung round the front of the roof, pillar to pillar either side of the way in
		local flags =
			{ rgb(236, 110, 104), rgb(250, 206, 96), rgb(110, 178, 220), rgb(150, 206, 130), rgb(240, 150, 190) }
		bunting(r, v3(2.95, 9.25, 7.0), v3(7.0, 9.25, 2.9), 0.4, 6, flags)
		bunting(r, v3(-2.95, 9.25, 7.0), v3(-7.0, 9.25, 2.9), 0.4, 6, flags)
		-- benches for the crowd, lamps, beds of flowers and the park's trees behind
		for _, x in { -8, -2.8, 2.8, 8 } do
			town(r, "bench", CFrame.new(x, 0.1, 21) * yaw(180))
		end
		for _, x in { -5.4, 5.4 } do
			town(r, "bench", CFrame.new(x, 0.1, 26.5) * yaw(180))
		end
		for _, at in { v3(-13.6, 0.1, 10), v3(13.6, 0.1, 10), v3(-15.4, 0.1, 25), v3(15.4, 0.1, 25) } do
			town(r, "lamp", CFrame.new(at), true)
		end
		town(r, "flowerBed", CFrame.new(-11, 0, -2) * yaw(90))
		town(r, "flowerBed", CFrame.new(11, 0, -2) * yaw(90))
		town(r, "lowTreeBig", CFrame.new(-17, 0, -12) * yaw(30))
		town(r, "lowTree", CFrame.new(16, 0, -15) * yaw(110))
		town(r, "lowTreeBig", CFrame.new(3, 0, -22) * yaw(200))
		town(r, "hedgeRow", CFrame.new(-10, 0, -13))
		town(r, "hedgeRow", CFrame.new(8, 0, -14) * yaw(-8))
	end,
})

-- A dream: no ground, only a soft cloud to stand on in a pink and lilac sky, with shapes floating
-- all round it. Little clouds, stars, rings, turning cubes, a stair that goes up to nothing, a
-- door standing open on its own cloud with light coming through it, and a teapot as big as a
-- house.
stage({
	id = "dream",
	name = "A dream",
	marks = {
		{ at = v3(0, 0, 0.6), yaw = 0 },
		{ at = v3(-3.4, 0, -1.2), yaw = 38 },
		{ at = v3(3.4, 0, -1.2), yaw = -38 },
	},
	shots = {
		wide = { eye = v3(0, 5.4, 17), look = v3(0, 3.4, -2), fov = 44 },
		two = { eye = v3(-0.6, 4.9, 8.6), look = v3(-1.7, 4.4, -0.3), fov = 34 },
		float = { eye = v3(7, 12.5, 10), look = v3(0, 2, -1), fov = 44 },
		low = { eye = v3(-3, -1.2, 10), look = v3(0, 5.4, -2), fov = 42 },
		door = { eye = v3(4, 6.4, 7), look = v3(11, 6.5, -12), fov = 40 },
		pan = {
			eye = v3(-12.5, 6, 9),
			look = v3(-3, 4, -4),
			fov = 44,
			to = { eye = v3(12.5, 6, 9), look = v3(3, 4, -4), fov = 44 },
		},
	},
	bounds = { lo = v3(-15, -3, -6), hi = v3(15, 16, 20) },
	light = { ambient = rgb(198, 178, 212), color = rgb(255, 240, 236), dir = v3(0.25, -1, -0.45) },
	sky = {
		top = rgb(140, 128, 214),
		mid = rgb(226, 160, 206),
		horizon = rgb(255, 196, 176),
		low = rgb(178, 150, 222),
		moon = {
			dir = v3(0.55, 0.42, -1),
			size = 132,
			color = rgb(250, 230, 180),
			glow = rgb(250, 176, 200),
			phase = 0.36,
		},
		stars = 34,
	},
	build = function(r: R)
		local CLOUD = rgb(250, 240, 248)
		local SHADE = rgb(222, 206, 236)
		-- the cloud they stand on: flattened lumps with their tops level, softer lumps under them
		for _, c in
			{
				{ 0, 0, 9, 2.4, 7 },
				{ -4, -1, 7, 2.2, 6 },
				{ 4.2, -0.6, 7.4, 2.2, 6 },
				{ -1, -3.4, 8, 2.0, 5 },
				{ 1.6, 2.6, 6, 2.0, 4.6 },
			}
		do
			r:lump(CFrame.new(c[1], -c[4] / 2, c[2]), c[3], c[4], c[5], CLOUD, "SmoothPlastic")
		end
		for _, c in
			{
				{ -2.6, -2.2, 0.6, 6 },
				{ 2.8, -2.4, -1.4, 6.4 },
				{ 0, -3, 1.6, 5 },
				{ -5.6, -2, -2, 4 },
				{ 6, -2, 1, 4 },
			}
		do
			r:lump(CFrame.new(c[1], c[2], c[3]), c[4], 3, c[4] * 0.8, SHADE, "SmoothPlastic")
		end
		-- little clouds drifting at every height
		local function puff(x: number, y: number, z: number, s: number)
			r:lump(CFrame.new(x, y, z), 3 * s, 1.4 * s, 2.2 * s, CLOUD, "SmoothPlastic")
			r:lump(CFrame.new(x - 1.2 * s, y - 0.2 * s, z + 0.3 * s), 2 * s, 1.1 * s, 1.6 * s, CLOUD, "SmoothPlastic")
			r:lump(CFrame.new(x + 1.1 * s, y - 0.3 * s, z), 1.8 * s, 1 * s, 1.5 * s, SHADE, "SmoothPlastic")
		end
		puff(-13, 9, -10, 1.6)
		puff(15, 3, -14, 2)
		puff(-18, -4, -6, 1.8)
		puff(-6, 13, -18, 1.4)
		puff(19, 12, -20, 1.6)
		puff(-22, 4, -24, 2.4)
		puff(8, -7, -9, 1.6)
		-- stars: five points, flat and thick, turned every way
		local function star(cf: CFrame, s: number, color: Color3)
			local pts = {}
			for k = 0, 9 do
				local a = k * math.pi / 5
				local rad = if k % 2 == 0 then s else s * 0.45
				table.insert(pts, (cf * CFrame.new(math.sin(a) * rad, math.cos(a) * rad, 0)).Position)
			end
			local mid = cf.Position
			for k = 1, 10 do
				r:tri(mid, pts[k], pts[k % 10 + 1], 0.5 * s, color, "SmoothPlastic")
			end
		end
		star(CFrame.new(-9, 8, -6) * CFrame.Angles(0.2, 0.5, 0.3), 1.4, rgb(255, 226, 140))
		star(CFrame.new(10.5, 10, -7) * CFrame.Angles(-0.1, -0.6, -0.2), 1.1, rgb(255, 196, 150))
		star(CFrame.new(-4, 12.5, -12) * CFrame.Angles(0.3, 0.2, 0.6), 1.0, rgb(255, 236, 170))
		star(CFrame.new(16, 1, -6) * CFrame.Angles(0, -0.8, 0.4), 1.3, rgb(255, 226, 140))
		-- rings: eight short pieces round a circle
		local function ring(cf: CFrame, rad: number, color: Color3)
			for k = 0, 7 do
				local a = k * math.pi / 4
				r:boxAt(
					cf * CFrame.Angles(0, 0, a) * CFrame.new(0, rad, 0),
					rad * 0.86,
					0.5,
					0.5,
					color,
					"SmoothPlastic"
				)
			end
		end
		ring(CFrame.new(-12, 4, -9) * CFrame.Angles(0.4, 0.9, 0), 1.6, rgb(150, 214, 206))
		ring(CFrame.new(8, 13, -13) * CFrame.Angles(1.1, 0.2, 0.3), 1.3, rgb(246, 160, 190))
		-- cubes and balls in soft colours, turned every way
		for _, c in
			{
				{ at = v3(-7, 2.5, -7), s = 1.4, color = rgb(176, 160, 236) },
				{ at = v3(9, 6, -4), s = 1.1, color = rgb(255, 190, 160) },
				{ at = v3(-15, 12, -14), s = 1.8, color = rgb(160, 216, 236) },
				{ at = v3(4, 15, -16), s = 1.2, color = rgb(246, 170, 200) },
			}
		do
			r:boxAt(CFrame.new(c.at) * CFrame.Angles(0.6, 0.8, 0.3), c.s, c.s, c.s, c.color, "SmoothPlastic")
		end
		for _, c in
			{
				{ at = v3(12.5, 7.5, -9), s = 1.2, color = rgb(160, 216, 236) },
				{ at = v3(-10.5, -2, -5), s = 1.0, color = rgb(246, 170, 200) },
				{ at = v3(-2, 16, -14), s = 0.9, color = rgb(255, 226, 150) },
			}
		do
			r:ball(c.at.X, c.at.Y, c.at.Z, c.s * 2, c.color, "SmoothPlastic")
		end
		-- a stair of floating steps going up to nothing at the left
		for k = 0, 7 do
			local a = k * 0.34
			local x, z = -6.5 - math.cos(a) * 3, -6 - math.sin(a) * 3
			local cf = CFrame.new(x, 0.9 + k * 1.1, z) * yaw(-math.deg(a))
			r:boxAt(cf, 2.6, 0.32, 1.2, rgb(252, 248, 244), "SmoothPlastic")
			r:boxAt(cf * CFrame.new(0, -0.3, 0), 2.5, 0.28, 1.1, rgb(214, 196, 236), "SmoothPlastic")
		end
		-- a door standing open on a cloud of its own, light through it
		local dcf = CFrame.new(11, 3.4, -11) * yaw(-20)
		r:lump(dcf * CFrame.new(0, -1.1, 0), 6, 2.2, 4.4, CLOUD, "SmoothPlastic")
		r:boxAt(dcf * CFrame.new(0, 2.85, 0), 3.4, 5.7, 0.2, rgb(255, 236, 196), "Neon")
		for _, sx in { -1, 1 } do
			r:boxAt(dcf * CFrame.new(sx * 1.9, 3.0, 0), 0.4, 6, 0.5, rgb(250, 250, 255), "Wood")
		end
		r:boxAt(dcf * CFrame.new(0, 6.2, 0), 4.2, 0.4, 0.5, rgb(250, 250, 255), "Wood")
		r:boxAt(dcf * CFrame.new(-1.7, 2.85, 1.55) * yaw(-80), 3.2, 5.6, 0.22, rgb(130, 170, 226), "Wood")
		r:boxAt(dcf * CFrame.new(-1.7, 2.85, 2.9), 0.2, 0.2, 0.2, C.Gold, "Metal")
		-- a teapot as big as a house, far behind, tipped as if pouring
		local tcf = CFrame.new(-2, 6, -26) * CFrame.Angles(0, 0.4, -0.25)
		local MINT = rgb(176, 226, 206)
		local function ballAt(cf: CFrame, d: number, color: Color3)
			r:ball(cf.X, cf.Y, cf.Z, d, color, "SmoothPlastic")
		end
		r:lump(tcf, 9, 7.6, 9, MINT, "SmoothPlastic")
		r:lump(tcf * CFrame.new(0, 3.9, 0), 4.6, 1.4, 4.6, shade(MINT, 0.92), "SmoothPlastic")
		ballAt(tcf * CFrame.new(0, 4.8, 0), 1, rgb(255, 196, 160))
		r:beam(
			(tcf * CFrame.new(4, -0.6, 0)).Position,
			(tcf * CFrame.new(7.4, 2.6, 0)).Position,
			1.3,
			1.3,
			MINT,
			"SmoothPlastic"
		)
		for k = 0, 5 do
			local a = -math.pi / 2 + k * math.pi / 5
			r:boxAt(
				tcf * CFrame.new(-4.6 - math.cos(a) * 2.2, math.sin(a) * 2.2, 0) * CFrame.Angles(0, 0, a),
				0.7,
				1.6,
				0.7,
				shade(MINT, 0.9),
				"SmoothPlastic"
			)
		end
		for k = 0, 4 do
			local a = k * 2 * math.pi / 5
			ballAt(tcf * CFrame.new(math.cos(a) * 3.2, 0.6, math.sin(a) * 3.2 + 1.4), 1.1, rgb(246, 170, 200))
		end
	end,
})

-- A wedding arch in a garden: a white arch of slats with lattice sides and flowers all over it,
-- a runner up the middle with petals on it, rows of white chairs either side with bows on the
-- aisle seats, lanterns on hooks, urns of flowers where the aisle starts, and hedges and trees
-- behind. A warm afternoon.
stage({
	id = "wedding",
	name = "A wedding arch in a garden",
	marks = {
		{ at = v3(-1.5, 0.1, -4.4), yaw = 76 },
		{ at = v3(1.5, 0.1, -4.4), yaw = -76 },
		-- (whoever marries them stands behind the arch: seen between the two of them)
		{ at = v3(0, 0.1, -7.8), yaw = 0, close = { eye = v3(0, 5.1, -1.6), look = v3(0, 4.15, -7.8), fov = 30 } },
	},
	shots = {
		wide = { eye = v3(0, 6.6, 16), look = v3(0, 3.8, -5), fov = 44 },
		two = { eye = v3(0.3, 4.9, 3.6), look = v3(0, 4.5, -4.6), fov = 36 },
		low = { eye = v3(0, 2.6, 0.8), look = v3(0, 5.8, -5.4), fov = 42 },
		aisle = { eye = v3(0, 4.9, 12.5), look = v3(0, 4.5, -5), fov = 30 },
		pan = {
			eye = v3(-10.5, 6, 10.5),
			look = v3(-2, 4, -5),
			fov = 44,
			to = { eye = v3(10.5, 6, 10.5), look = v3(2, 4, -5), fov = 44 },
		},
	},
	bounds = { lo = v3(-12, 1, -3.6), hi = v3(12, 14, 18) },
	light = { ambient = rgb(170, 160, 168), color = rgb(255, 234, 202), dir = v3(-0.62, -0.56, 0.4) },
	sky = {
		top = rgb(108, 160, 222),
		mid = rgb(156, 192, 230),
		horizon = rgb(250, 214, 180),
		low = rgb(150, 176, 140),
		sun = { dir = v3(0.8, 0.42, -0.62), size = 72, color = rgb(255, 238, 186), glow = rgb(255, 210, 160) },
	},
	build = function(r: R)
		local GRASS = rgb(118, 168, 98)
		local WHITE = rgb(246, 244, 238)
		local RUNNER = rgb(240, 226, 214)
		local LEAF = rgb(96, 150, 92)
		local PINKS = { rgb(246, 170, 190), rgb(252, 236, 236), rgb(255, 204, 170), rgb(236, 140, 170) }
		r:block(-60, -1, -60, 60, 0, 40, GRASS, "Grass")
		r:block(-1.7, 0, -9, 1.7, 0.1, 16, RUNNER, "Fabric")
		r:block(-1.75, 0, -9, -1.55, 0.14, 16, shade(RUNNER, 0.88), "Fabric")
		r:block(1.55, 0, -9, 1.75, 0.14, 16, shade(RUNNER, 0.88), "Fabric")
		local next = rand(21)
		for i = 1, 34 do
			-- (on a loose grid, so no two lie over each other)
			local x = -1.2 + (i * 3 % 5) * 0.6 + (next() - 0.5) * 0.16
			local z = -2 + i * 0.5 + (next() - 0.5) * 0.12
			r:boxAt(
				CFrame.new(x, 0.12, z) * yaw(next() * 180),
				0.3,
				0.04,
				0.22,
				PINKS[math.floor(next() * 4) + 1],
				"Fabric"
			)
		end
		-- the arch: two pairs of posts with lattice between them, an arc over the top front and
		-- back, slats across it, and flowers climbing it
		for _, sx in { -1, 1 } do
			local x = sx * 3.2
			for _, z in { -6.7, -5.3 } do
				r:box(x, 3.6, z, 0.5, 7.2, 0.5, WHITE, "Wood")
				r:box(x, 0.15, z, 0.8, 0.3, 0.8, shade(WHITE, 0.9), "Wood")
			end
			for k = 0, 4 do
				local y = 0.8 + k * 1.3
				r:beam(v3(x, y, -6.45), v3(x, y + 1.3, -5.55), 0.12, 0.12, WHITE, "Wood")
				r:beam(v3(x - sx * 0.05, y + 1.3, -6.45), v3(x - sx * 0.05, y, -5.55), 0.12, 0.12, WHITE, "Wood")
			end
		end
		local arc: { Vector3 } = {}
		for k = 0, 8 do
			local a = k * math.pi / 8
			table.insert(arc, v3(-math.cos(a) * 3.2, 7.2 + math.sin(a) * 2.4, 0))
		end
		for k = 1, 8 do
			for _, z in { -6.7, -5.3 } do
				r:beam(arc[k] + v3(0, 0, z), arc[k + 1] + v3(0, 0, z), 0.4, 0.5, WHITE, "Wood")
			end
			local m = (arc[k] + arc[k + 1]) / 2
			r:box(m.X, m.Y + 0.05, -6, 0.22, 0.22, 2.0, WHITE, "Wood")
		end
		local function bloom(p: Vector3, s: number)
			r:lump(CFrame.new(p), 1.3 * s, 0.9 * s, 1.0 * s, LEAF, "Grass")
			for k = 0, 2 do
				local a = k * 2.1 + p.X
				r:ball(
					p.X + math.cos(a) * 0.45 * s,
					p.Y + 0.25 * s,
					p.Z + math.sin(a) * 0.4 * s,
					0.55 * s,
					PINKS[k + 1 + (math.floor(p.Y) % 2)],
					"SmoothPlastic"
				)
			end
		end
		for k = 2, 7 do
			bloom(arc[k] + v3(0, 0.4, -5.2 + (k % 2) * 0.1), 1)
		end
		bloom(arc[5] + v3(0, 0.6, -6.1), 1.3)
		for _, sx in { -1, 1 } do
			for _, y in { 0.8, 2.6, 4.6, 6.4 } do
				bloom(v3(sx * 3.6, y, -4.92), 0.9)
			end
		end
		-- a sheer drape hanging at each side of the arch
		for _, sx in { -1, 1 } do
			local d = r:block(sx * 2.4 - 0.5, 1.2, -5.05, sx * 2.4 + 0.5, 8.4, -4.98, rgb(255, 250, 246), "Fabric")
			d.transp = 0.45
		end
		-- the chairs: white folding chairs facing the arch, a bow on each aisle seat
		local function chair(x: number, z: number, bow: boolean)
			local cf = CFrame.new(x, 0, z)
			for _, sx in { -0.7, 0.7 } do
				for _, sz in { -0.7, 0.7 } do
					r:boxAt(cf * CFrame.new(sx, 0.95, sz), 0.16, 1.9, 0.16, WHITE, "Wood")
				end
				r:boxAt(cf * CFrame.new(sx, 2.9, 0.76), 0.16, 2.0, 0.16, WHITE, "Wood")
			end
			r:boxAt(cf * CFrame.new(0, 1.98, 0), 1.7, 0.16, 1.7, WHITE, "Wood")
			for _, y in { 2.6, 3.2, 3.75 } do
				r:boxAt(cf * CFrame.new(0, y, 0.78), 1.4, 0.3, 0.1, WHITE, "Wood")
			end
			if bow then
				local s = if x < 0 then 1 else -1
				r:boxAt(
					cf * CFrame.new(s * 0.79, 3.4, 0.76) * CFrame.Angles(0, 0, 0.5),
					0.1,
					0.5,
					0.3,
					PINKS[1],
					"Fabric"
				)
				r:boxAt(
					cf * CFrame.new(s * 0.79, 3.4, 0.76) * CFrame.Angles(0, 0, -0.5),
					0.1,
					0.5,
					0.3,
					PINKS[1],
					"Fabric"
				)
				r:boxAt(
					cf * CFrame.new(s * 0.79, 2.9, 0.82) * CFrame.Angles(0, 0, 0.15),
					0.08,
					0.9,
					0.16,
					PINKS[1],
					"Fabric"
				)
			end
		end
		for _, z in { 1.6, 5.2, 8.8 } do
			for _, sx in { -1, 1 } do
				chair(sx * 3.4, z, true)
				chair(sx * 5.6, z, false)
			end
		end
		-- lanterns on shepherd's hooks at the ends of the rows, and urns of flowers where the aisle starts
		for _, z in { 2.6, 6.2, 9.8 } do
			for _, sx in { -1, 1 } do
				local x = sx * 7.2
				r:box(x, 2.0, z, 0.1, 4.0, 0.1, rgb(70, 72, 80), "Metal")
				r:beam(v3(x, 4.0, z), v3(x - sx * 0.6, 4.3, z), 0.08, 0.08, rgb(70, 72, 80), "Metal")
				r:box(x - sx * 0.6, 3.95, z, 0.05, 0.6, 0.05, rgb(70, 72, 80), "Metal")
				r:box(x - sx * 0.6, 3.35, z, 0.5, 0.6, 0.5, rgb(255, 236, 200), "Glass")
				r:box(x - sx * 0.6, 3.7, z, 0.6, 0.1, 0.6, rgb(70, 72, 80), "Metal")
			end
		end
		for _, sx in { -1, 1 } do
			local x = sx * 2.6
			r:cyl(x, 1.3, 13, 2.6, 0.8, "y", shade(WHITE, 0.94), "Marble")
			r:cyl(x, 0.15, 13, 0.3, 1.2, "y", shade(WHITE, 0.9), "Marble")
			r:cyl(x, 3.0, 13, 0.8, 1.3, "y", shade(WHITE, 0.94), "Marble")
			bloom(v3(x, 3.8, 13), 1.4)
		end
		-- hedges, rose bushes and trees behind
		town(r, "hedgeRow", CFrame.new(-8.6, 0, -11.5))
		town(r, "hedgeRow", CFrame.new(8.6, 0, -11.5))
		town(r, "hedge", CFrame.new(0, 0, -12.6))
		town(r, "flowerPatch", CFrame.new(-8, 0, -7.5))
		town(r, "flowerPatch", CFrame.new(8.4, 0, -7.2) * yaw(90))
		town(r, "lowTreeBig", CFrame.new(-14, 0, -17) * yaw(40))
		town(r, "lowTreeBig", CFrame.new(14, 0, -16) * yaw(160))
		town(r, "lowTree", CFrame.new(1, 0, -21) * yaw(250))
		bunting(
			r,
			v3(-11.6, 8.8, -13),
			v3(11.4, 8.8, -12.6),
			1.6,
			18,
			{ PINKS[1], WHITE, PINKS[3], rgb(176, 210, 190) }
		)
	end,
})

-- A room got ready for a birthday party: a table under a cloth with a two layer cake and its
-- candles, plates, cups and party hats, presents stacked round it, balloons up by the ceiling,
-- streamers and a string of flags, a sideboard with pictures over it, a rug, and the night
-- outside the window.
stage({
	id = "birthday",
	name = "A birthday party",
	marks = {
		{ at = v3(0, 0, -7.8), yaw = 0 },
		{ at = v3(-5.4, 0, -2.2), yaw = 112 },
		{ at = v3(5.4, 0, -2.2), yaw = -112 },
	},
	shots = {
		wide = { eye = v3(0, 6.4, 9.6), look = v3(0, 3.6, -6), fov = 48 },
		two = { eye = v3(2.8, 5.4, 3.4), look = v3(-2.6, 4.2, -5), fov = 40 },
		cake = { eye = v3(1.6, 5.6, 1.0), look = v3(0, 3.8, -5.6), fov = 30 },
		high = { eye = v3(6, 9.4, 7), look = v3(0, 3, -6), fov = 44 },
		pan = {
			eye = v3(-10, 6, 7),
			look = v3(-6, 4, -8),
			fov = 46,
			to = { eye = v3(10, 6, 7), look = v3(4, 4, -8), fov = 46 },
		},
	},
	bounds = { lo = v3(-13, 1, -9), hi = v3(13, 10, 10) },
	light = { ambient = rgb(190, 160, 150), color = rgb(255, 228, 192), dir = v3(0.36, -0.84, -0.4) },
	sky = { top = rgb(40, 46, 96), mid = rgb(70, 66, 124), horizon = rgb(124, 92, 140), low = rgb(40, 40, 70) },
	build = function(r: R)
		local WOOD = rgb(186, 140, 100)
		local WALL = rgb(244, 214, 186)
		local PANEL = rgb(150, 186, 176)
		local TRIM = rgb(250, 244, 232)
		local CLOTH = rgb(250, 246, 240)
		local PARTY =
			{ rgb(240, 120, 140), rgb(250, 206, 96), rgb(110, 176, 226), rgb(150, 210, 140), rgb(196, 150, 232) }
		-- the floor, the walls (panelled below a rail, striped paper above) and the ceiling
		boards(r, -15, -11, 15, 12, 0, WOOD)
		r:block(-15.6, -0.6, -11.6, 15.6, 11, -11, WALL, "Plaster")
		r:block(-15.6, -0.6, -11, -15, 11, 12, WALL, "Plaster")
		r:block(15, -0.6, -11, 15.6, 11, 12, WALL, "Plaster")
		r:block(-15.6, 11, -11.6, 15.6, 11.6, 12, TRIM, "Plaster")
		r:block(-15, 0, -11, 15, 3.4, -10.9, PANEL, "Wood")
		r:block(-15, 0, -10.9, -14.9, 3.4, 12, PANEL, "Wood")
		r:block(14.9, 0, -10.9, 15, 3.4, 12, PANEL, "Wood")
		r:block(-15, 3.4, -11, 15, 3.6, -10.82, TRIM, "Wood")
		r:block(-15, 3.4, -10.82, -14.82, 3.6, 12, TRIM, "Wood")
		r:block(14.82, 3.4, -10.82, 15, 3.6, 12, TRIM, "Wood")
		r:block(-15, 0, -10.9, 15, 0.5, -10.78, TRIM, "Wood")
		for x = -14, 14, 1.6 do
			r:block(x - 0.25, 3.6, -11, x + 0.25, 11, -10.96, rgb(250, 228, 204), "Plaster")
		end
		r:block(-15, 10.6, -11, 15, 11, -10.8, TRIM, "Wood")
		-- the window: the night outside, a moon, a frame with its bars, a sill and curtains
		local wx = 8.4
		r:block(wx - 2.4, 4.6, -10.96, wx + 2.4, 8.6, -10.92, rgb(36, 44, 92), "Glass")
		r:block(wx + 1.0, 7.4, -10.92, wx + 1.5, 7.9, -10.88, rgb(240, 236, 200), "Neon")
		for _, s in { { -1.5, 5.6 }, { 0.6, 6.8 }, { -0.4, 8.0 }, { 1.9, 5.3 } } do
			r:block(
				wx + s[1] - 0.05,
				s[2] - 0.05,
				-10.92,
				wx + s[1] + 0.05,
				s[2] + 0.05,
				-10.88,
				rgb(250, 246, 220),
				"Neon"
			)
		end
		r:block(wx - 2.6, 4.4, -11, wx + 2.6, 4.6, -10.6, TRIM, "Wood")
		r:block(wx - 2.6, 8.6, -11, wx + 2.6, 8.8, -10.8, TRIM, "Wood")
		r:block(wx - 2.6, 4.6, -11, wx - 2.4, 8.6, -10.8, TRIM, "Wood")
		r:block(wx + 2.4, 4.6, -11, wx + 2.6, 8.6, -10.8, TRIM, "Wood")
		r:block(wx - 0.08, 4.6, -10.92, wx + 0.08, 8.6, -10.84, TRIM, "Wood")
		r:block(wx - 2.4, 6.52, -10.92, wx + 2.4, 6.68, -10.84, TRIM, "Wood")
		for _, sx in { -1, 1 } do
			for k = 0, 2 do
				local x = wx + sx * (2.9 + k * 0.32)
				r:block(
					x - 0.18,
					3.9,
					-10.78 + (k % 2) * 0.1,
					x + 0.18,
					9.2,
					-10.62 + (k % 2) * 0.1,
					rgb(232, 130, 128),
					"Fabric"
				)
			end
		end
		r:block(wx - 3.8, 9.2, -10.8, wx + 3.8, 9.36, -10.5, rgb(120, 96, 80), "Wood")
		-- a door in the right wall
		r:block(14.84, 0.5, -3.2, 14.9, 7.2, 0.2, rgb(150, 112, 86), "Wood")
		r:block(14.7, 0.5, -3.5, 14.9, 7.5, -3.2, TRIM, "Wood")
		r:block(14.7, 0.5, 0.2, 14.9, 7.5, 0.5, TRIM, "Wood")
		r:block(14.7, 7.2, -3.2, 14.9, 7.5, 0.2, TRIM, "Wood")
		r:box(14.78, 3.6, -0.3, 0.12, 0.2, 0.2, C.Gold, "Metal")
		-- the table under its cloth, with the cake, plates, cups and hats
		local T = 2.5 -- the table's top
		for _, sx in { -1, 1 } do
			for _, sz in { -1, 1 } do
				r:box(sx * 3.2, 0.8, -5 + sz * 1.4, 0.3, 1.6, 0.3, shade(WOOD, 0.8), "Wood")
			end
		end
		r:block(-3.6, 1.6, -6.8, 3.6, T, -3.2, CLOTH, "Fabric")
		r:block(-3.66, 1.56, -6.86, 3.66, 1.86, -3.14, rgb(240, 150, 170), "Fabric")
		r:cyl(0, T + 0.04, -5, 0.08, 2.2, "y", rgb(240, 240, 236), "Marble")
		r:cyl(0, T + 0.43, -5, 0.7, 1.7, "y", rgb(250, 232, 226), "SmoothPlastic")
		r:cyl(0, T + 1.06, -5, 0.56, 1.1, "y", rgb(246, 186, 200), "SmoothPlastic")
		r:cyl(0, T + 0.81, -5, 0.06, 1.78, "y", rgb(255, 255, 250), "SmoothPlastic")
		for k = 0, 7 do
			local a = k * math.pi / 4 + math.pi / 8
			r:boxAt(
				CFrame.new(math.cos(a) * 0.86, T + 0.62, -5 + math.sin(a) * 0.86) * CFrame.Angles(0, -a, 0),
				0.08,
				0.34,
				0.2,
				rgb(255, 255, 250),
				"SmoothPlastic"
			)
		end
		for k = 0, 4 do
			local a = k * 2 * math.pi / 5
			local x, z = math.cos(a) * 0.32, -5 + math.sin(a) * 0.32
			r:cyl(x, T + 1.56, z, 0.44, 0.1, "y", PARTY[k + 1], "SmoothPlastic")
			r:ball(x, T + 1.86, z, 0.16, rgb(255, 210, 120), "Neon")
			r:ball(
				math.cos(a + 0.6) * 0.46,
				T + 1.4,
				-5 + math.sin(a + 0.6) * 0.46,
				0.18,
				rgb(214, 60, 80),
				"SmoothPlastic"
			)
		end
		for _, at in { v3(-2.4, T, -4.2), v3(2.4, T, -4.2), v3(-2.6, T, -6.0), v3(2.6, T, -6.0) } do
			r:cyl(at.X, at.Y + 0.04, at.Z, 0.08, 1.0, "y", rgb(240, 240, 236), "Marble")
		end
		for i, at in { v3(-1.6, T, -3.7), v3(1.6, T, -3.7), v3(-3.0, T, -5.0) } do
			r:cyl(at.X, at.Y + 0.25, at.Z, 0.5, 0.4, "y", PARTY[i + 1], "SmoothPlastic")
		end
		for i, at in { v3(-1.4, T, -6.2), v3(1.5, T, -6.3), v3(3.0, T, -4.7) } do
			r:cone(at.X, at.Y + 0.45, at.Z, 0.9, 0.6, PARTY[i], "SmoothPlastic")
			r:ball(at.X, at.Y + 0.96, at.Z, 0.24, PARTY[i + 2], "SmoothPlastic")
		end
		-- presents: boxes with a ribbon round them and a bow
		local function present(
			x: number,
			y: number,
			z: number,
			w: number,
			h: number,
			d: number,
			turn: number,
			color: Color3,
			ribbon: Color3
		)
			local cf = CFrame.new(x, y, z) * yaw(turn)
			r:boxAt(cf * CFrame.new(0, h / 2, 0), w, h, d, color, "SmoothPlastic")
			r:boxAt(cf * CFrame.new(0, h / 2 + 0.02, 0), 0.3, h + 0.04, d + 0.06, ribbon, "Fabric")
			r:boxAt(cf * CFrame.new(0, h / 2 + 0.02, 0), w + 0.06, h + 0.04, 0.3, ribbon, "Fabric")
			r:boxAt(cf * CFrame.new(-0.22, h + 0.18, 0) * CFrame.Angles(0, 0, 0.6), 0.5, 0.12, 0.3, ribbon, "Fabric")
			r:boxAt(cf * CFrame.new(0.22, h + 0.18, 0) * CFrame.Angles(0, 0, -0.6), 0.5, 0.12, 0.3, ribbon, "Fabric")
		end
		present(-5.0, 0, -7.6, 1.8, 1.4, 1.6, 20, PARTY[3], PARTY[2])
		present(-4.9, 1.4, -7.6, 1.0, 0.9, 1.0, 35, PARTY[1], rgb(255, 255, 250))
		present(-6.8, 0, -6.4, 1.3, 1.0, 1.2, -15, PARTY[4], PARTY[1])
		present(5.2, 0, -7.8, 1.6, 1.2, 1.4, -25, PARTY[5], PARTY[2])
		present(6.6, 0, -6.6, 1.1, 1.6, 1.1, 10, PARTY[2], PARTY[3])
		-- the sideboard with pictures over it, and a lamp
		r:block(-13.2, 0, -10.9, -7.2, 3.0, -8.8, rgb(170, 124, 90), "Wood")
		r:block(-13.4, 3.0, -10.9, -7.0, 3.2, -8.6, rgb(150, 108, 78), "Wood")
		for _, x in { -11.7, -8.7 } do
			r:block(x - 1.3, 0.4, -8.8, x + 1.3, 2.6, -8.74, rgb(186, 140, 104), "Wood")
			r:box(x, 1.5, -8.7, 0.5, 0.12, 0.08, C.Gold, "Metal")
		end
		for _, f in
			{
				{ x = -12, y = 6.2, w = 1.6, h = 2.0, color = rgb(140, 190, 220) },
				{ x = -9.2, y = 6.6, w = 2.2, h = 1.6, color = rgb(240, 190, 150) },
			}
		do
			local x1, y1, x2, y2 = f.x - f.w / 2, f.y - f.h / 2, f.x + f.w / 2, f.y + f.h / 2
			r:block(x1, y1, -10.96, x2, y2, -10.8, rgb(120, 90, 70), "Wood")
			r:block(x1 + 0.2, y1 + 0.2, -10.8, x2 - 0.2, y2 - 0.2, -10.76, f.color, "SmoothPlastic")
		end
		r:cyl(-7.9, 3.4, -9.8, 0.4, 0.8, "y", rgb(200, 190, 176), "Marble")
		r:cyl(-7.9, 4.2, -9.8, 1.2, 0.14, "y", rgb(200, 190, 176), "Marble")
		r:cone(-7.9, 5.3, -9.8, 1.2, 1.4, rgb(250, 236, 210), "Fabric")
		-- the rug
		r:block(-7, 0, -9.4, 7, 0.1, 2.4, rgb(196, 110, 100), "Fabric")
		r:block(-6.4, 0.1, -8.8, 6.4, 0.14, 1.8, rgb(232, 196, 150), "Fabric")
		-- balloons up by the ceiling, their strings hanging down
		for i, b in
			{
				{ -12.6, 9.0, -9.2 },
				{ -11.4, 9.6, -9.8 },
				{ -13.4, 8.2, -7.8 },
				{ 12.4, 9.2, -9.4 },
				{ 11.2, 8.6, -9.8 },
				{ 13.2, 9.6, -7.6 },
				{ 0.8, 9.4, -9.6 },
			}
		do
			r:lump(CFrame.new(b[1], b[2], b[3]), 1.3, 1.6, 1.3, PARTY[(i - 1) % 5 + 1], "SmoothPlastic")
			r:box(b[1], b[2] - 0.85, b[3], 0.18, 0.14, 0.18, PARTY[(i - 1) % 5 + 1], "SmoothPlastic")
			r:beam(
				v3(b[1], b[2] - 0.9, b[3]),
				v3(b[1] * 0.92, 3.4, b[3] + 0.4),
				0.04,
				0.04,
				rgb(240, 240, 240),
				"Plastic"
			)
		end
		-- streamers twisting from the middle of the ceiling to its corners, and flags on the wall
		local hub = v3(0, 10.95, -4)
		for i, corner in { v3(-14.8, 10.7, -10.8), v3(14.8, 10.7, -10.8), v3(-14.8, 10.7, 4), v3(14.8, 10.7, 4) } do
			local n = 9
			for k = 0, n - 1 do
				local a = hub:Lerp(corner, k / n) - v3(0, 0.9 * math.sin(math.pi * k / n), 0)
				local b = hub:Lerp(corner, (k + 1) / n) - v3(0, 0.9 * math.sin(math.pi * (k + 1) / n), 0)
				r:beam(a, b, 0.32, 0.05, PARTY[(i + k) % 5 + 1], "Fabric")
			end
		end
		r:cyl(0, 10.6, -4, 0.6, 1.2, "y", TRIM, "Plaster")
		r:ball(0, 10.0, -4, 0.9, rgb(255, 236, 196), "Neon")
		bunting(r, v3(-12, 10.2, -10.6), v3(5.2, 10.2, -10.6), 0.9, 11, PARTY)
		-- two chairs at the ends of the table
		for _, sx in { -1, 1 } do
			local cf = CFrame.new(sx * 4.6, 0, -5) * yaw(sx * 90)
			for _, ox in { -0.65, 0.65 } do
				for _, oz in { -0.65, 0.65 } do
					r:boxAt(cf * CFrame.new(ox, 0.9, oz), 0.2, 1.8, 0.2, shade(WOOD, 0.85), "Wood")
				end
				r:boxAt(cf * CFrame.new(ox, 2.9, 0.65), 0.2, 2.2, 0.2, shade(WOOD, 0.85), "Wood")
			end
			r:boxAt(cf * CFrame.new(0, 1.9, 0), 1.6, 0.2, 1.6, WOOD, "Wood")
			r:boxAt(cf * CFrame.new(0, 3.5, 0.65), 1.3, 0.8, 0.14, WOOD, "Wood")
		end
	end,
})

-- The beach at dawn: the sand going down into the sea, a line of foam where the water comes in,
-- the sun coming up over the water with its path of light, palms, driftwood, a sandcastle, a
-- towel left out, a rowboat pulled up, shells and footprints, and the headland with its
-- lighthouse far off.
stage({
	id = "beach",
	name = "The beach at dawn",
	marks = {
		{ at = v3(-1.7, 0, -2), yaw = 72 },
		{ at = v3(1.7, 0, -2), yaw = -72 },
		{ at = v3(-4.8, 0, 1.6), yaw = 124 },
	},
	shots = {
		wide = { eye = v3(3.2, 5.2, 13), look = v3(0, 3.2, -6), fov = 46 },
		two = { eye = v3(0, 4.7, 6.4), look = v3(0, 4.2, -2), fov = 34 },
		sunrise = { eye = v3(-1, 4.8, 4.4), look = v3(17, 8.4, -56), fov = 44, sky = true },
		low = { eye = v3(2.6, 1.4, 5.4), look = v3(0, 5.2, -3), fov = 42 },
		pan = {
			eye = v3(-11, 5, 8),
			look = v3(-4, 3, -6),
			fov = 46,
			to = { eye = v3(11, 5, 8), look = v3(4, 3, -6), fov = 46 },
		},
	},
	bounds = { lo = v3(-13, 1, -7), hi = v3(13, 14, 16) },
	light = { ambient = rgb(170, 150, 170), color = rgb(255, 204, 156), dir = v3(-0.62, -0.26, 0.74) },
	sky = {
		top = rgb(104, 126, 200),
		mid = rgb(232, 164, 184),
		horizon = rgb(255, 196, 140),
		low = rgb(90, 120, 170),
		sun = { dir = v3(0.3, 0.07, -1), size = 108, color = rgb(255, 226, 160), glow = rgb(255, 170, 120) },
	},
	build = function(r: R)
		local SAND = rgb(236, 214, 172)
		local WET = rgb(196, 170, 136)
		local SEA = rgb(84, 126, 176)
		r:block(-90, -1, -10, 90, 0, 40, SAND, "Sand")
		r:block(-90, -2.6, -18, 90, -1.6, -10, WET, "Sand")
		r:ramp(-90, -1.6, -18, 90, 0, -10, true, WET, "Sand")
		r:block(-90, -1.0, -10, 90, 0, -9.0, SAND, "Sand")
		r:block(-420, -3, -700, 420, -0.9, -14.4, SEA, "SmoothPlastic")
		-- foam where the water comes up the sand, in short runs
		local next = rand(5)
		for x = -60, 60, 6 do
			local z = -14.3 + next() * 0.5
			r:block(x, -0.9, z - 0.25, x + 4 + next() * 2, -0.86, z + 0.25, rgb(246, 244, 236), "SmoothPlastic")
		end
		-- the sun's path on the water
		for i = 0, 22 do
			local z = -22 - i * 9 - next() * 3
			local x = -z * 0.3 + (next() - 0.5) * 4
			local w = 3 + next() * (3 + i * 0.5)
			r:block(x - w / 2, -0.9, z - 0.8, x + w / 2, -0.86, z + 0.8, rgb(176, 160, 176), "SmoothPlastic")
		end
		-- palms, driftwood, a sandcastle, a towel, a rowboat pulled up, rocks
		town(r, "palm", CFrame.new(-17.5, 0, -3.5) * yaw(-10))
		town(r, "palmTall", CFrame.new(19, 0, -1) * yaw(200))
		town(r, "driftwood", CFrame.new(-7, 0, -6.4) * yaw(30))
		town(r, "sandcastle", CFrame.new(9.5, 0, -6.6) * yaw(-20))
		town(r, "towel", CFrame.new(9.5, 0, 5) * yaw(30))
		town(r, "rowboat", CFrame.new(-16, 0, -6) * yaw(60))
		town(r, "rock", CFrame.new(13, 0, -8.5))
		town(r, "boulder", CFrame.new(-26, 0, -9) * yaw(40))
		-- shells, and footprints coming down the beach to where they stand
		for i = 1, 12 do
			local x, z = (next() - 0.5) * 22, -8 + next() * 16
			if math.abs(x) > 3 then
				r:lump(
					CFrame.new(x, 0.02, z) * yaw(next() * 180),
					0.5,
					0.22,
					0.4,
					({ rgb(250, 214, 214), rgb(255, 240, 226), rgb(236, 196, 170) })[i % 3 + 1],
					"SmoothPlastic"
				)
			end
		end
		for k = 0, 9 do
			local z = 14 - k * 1.5
			local x = -1 + math.sin(k * 0.5) * 0.6
			for _, s in { -1, 1 } do
				local fx = x + s * 0.35 + (if k % 2 == 0 then 0 else 0.1 * s)
				r:boxAt(
					CFrame.new(fx, 0.02, z + (if s > 0 then 0.7 else 0)) * yaw(8),
					0.36,
					0.04,
					0.62,
					shade(SAND, 0.86),
					"Sand"
				)
			end
		end
		-- the headland far off, its lighthouse, and a sailboat out on the water
		for i = 0, 5 do
			r:lump(
				CFrame.new(-140 - i * 30, -10, -244 - (i % 2) * 20),
				70,
				30 + (i % 3) * 8,
				50,
				rgb(124, 108, 150),
				"SmoothPlastic"
			)
		end
		town(r, "lighthouse", CFrame.new(-150, 2, -236) * yaw(40))
		town(r, "sailboat", CFrame.new(46, -1.2, -140) * yaw(80))
	end,
})

-- A quiet bench under a tree in the park: the town's bench under a big tree, a lamp and a bin
-- beside it, a gravel path curving past, beds of flowers, a hedge behind, a little pond with
-- lily pads and reeds, and leaves fallen on the grass. A soft afternoon.
stage({
	id = "park",
	name = "A bench under a tree",
	marks = {
		{ at = v3(-1.2, 1.92, -1.6), yaw = 14, sit = true },
		{ at = v3(1.2, 1.92, -1.6), yaw = -14, sit = true },
		{ at = v3(4.6, 0, -3.6), yaw = -62 },
	},
	shots = {
		wide = { eye = v3(0, 6, 15), look = v3(0, 3, -3), fov = 44 },
		two = { eye = v3(0, 4.2, 5.8), look = v3(0, 3.8, -1.6), fov = 34 },
		low = { eye = v3(-3, 1.3, 5), look = v3(0, 6, -4), fov = 42 },
		tree = { eye = v3(6, 2.6, 6), look = v3(1, 9, -6), fov = 50 },
		pan = {
			eye = v3(-12, 5, 10),
			look = v3(-2, 3, -2),
			fov = 44,
			to = { eye = v3(12, 5, 10), look = v3(2, 3, -2), fov = 44 },
		},
	},
	bounds = { lo = v3(-13, 1, -0.4), hi = v3(13, 14, 18) },
	light = { ambient = rgb(160, 160, 170), color = rgb(255, 236, 202), dir = v3(-0.5, -0.7, -0.5) },
	sky = {
		top = rgb(110, 160, 220),
		mid = rgb(150, 192, 228),
		horizon = rgb(232, 222, 182),
		low = rgb(140, 176, 132),
	},
	build = function(r: R)
		local GRASS = rgb(126, 176, 104)
		local GRAVEL = rgb(222, 206, 178)
		r:block(-70, -1, -60, 70, 0, 40, GRASS, "Grass")
		-- the path: short runs of gravel turning along a curve past the bench
		local pts: { Vector3 } = {}
		for k = 0, 12 do
			local x = -36 + k * 6
			table.insert(pts, v3(x, 0, 4.2 - 0.0035 * x * x))
		end
		for k = 1, 12 do
			local a, b = pts[k], pts[k + 1]
			local mid = (a + b) / 2
			local d = b - a
			r:boxAt(
				CFrame.new(mid.X, 0.05, mid.Z) * yaw(math.deg(math.atan2(-d.Z, d.X))),
				d.Magnitude + 0.6,
				0.1,
				4,
				GRAVEL,
				"Pebble"
			)
		end
		town(r, "bench", CFrame.new(0, 0, -1.6))
		town(r, "lowTreeBig", CFrame.new(2.6, 0, -7) * yaw(20))
		town(r, "lamp", CFrame.new(-5.6, 0, -2.8))
		town(r, "bin", CFrame.new(5.6, 0, 0.4))
		town(r, "flowerBed", CFrame.new(-9.6, 0, -4.4) * yaw(15))
		town(r, "flowerBed", CFrame.new(10.4, 0, -5.4) * yaw(-20))
		town(r, "hedgeRow", CFrame.new(-12, 0, -13))
		town(r, "hedgeRow", CFrame.new(5, 0, -14) * yaw(-4))
		town(r, "hedgeRow", CFrame.new(21, 0, -13) * yaw(6))
		town(r, "mushrooms", CFrame.new(5.6, 0, -8.6))
		town(r, "lowTree", CFrame.new(-18, 0, -18) * yaw(70))
		town(r, "lowTreeBig", CFrame.new(20, 0, -22) * yaw(200))
		-- the pond: stones round the water, lily pads with a flower, reeds
		local px, pz = -17, 11
		r:cyl(px, 0.04, pz, 0.08, 8, "y", rgb(96, 150, 176), "SmoothPlastic")
		for k = 0, 7 do
			local a = k * math.pi / 4
			r:boxAt(
				CFrame.new(px + math.cos(a) * 4.3, 0.25, pz + math.sin(a) * 4.3) * yaw(-math.deg(a)),
				1.1,
				0.5,
				3.6,
				rgb(170, 166, 160),
				"Slate"
			)
		end
		for _, l in { { -1.2, 0.8 }, { 1.4, -0.6 }, { 0.2, 1.9 } } do
			r:cyl(px + l[1], 0.1, pz + l[2], 0.04, 1.1, "y", rgb(90, 150, 80), "Grass")
		end
		r:ball(px + 1.4, 0.24, pz - 0.6, 0.34, rgb(250, 190, 210), "SmoothPlastic")
		for k = 0, 5 do
			r:box(
				px - 2.6 + k * 0.25,
				1.0,
				pz - 2.2 + (k % 2) * 0.3,
				0.1,
				2.0 - (k % 3) * 0.3,
				0.1,
				rgb(120, 150, 80),
				"Grass"
			)
		end
		-- leaves fallen on the grass and the path
		local next = rand(9)
		local LEAVES = { rgb(232, 160, 80), rgb(220, 120, 70), rgb(240, 200, 100) }
		for i = 1, 26 do
			local x, z = (next() - 0.5) * 18, -6 + next() * 14
			local onPath = math.abs(z - (4.2 - 0.0035 * x * x)) < 2.1
			r:boxAt(
				CFrame.new(x, if onPath then 0.12 else 0.02, z) * yaw(next() * 180),
				0.5,
				0.04,
				0.34,
				LEAVES[i % 3 + 1],
				"Grass"
			)
		end
	end,
})

-- The town gate, where newcomers come in: the road running in from the hills between fields and
-- fences, two stone pillars with lanterns on them, a little roofed beam across with a board
-- hanging from it, a stone wall going off each way, barrels of flowers, a signpost, a mailbox
-- and a bench. A suitcase stands on the road. Morning.
stage({
	id = "gate",
	name = "The town gate",
	marks = {
		-- (every shot keeps near the road's middle, so a move through the gate goes between the
		-- pillars: the close shots on the two by the gate look back in from just outside it)
		{
			at = v3(-2.2, 0.1, 2.4),
			yaw = 160,
			close = { eye = v3(-0.5, 5.0, -3.6), look = v3(-2.2, 4.15, 2.4), fov = 30 },
		},
		{
			at = v3(2.2, 0.1, 2.4),
			yaw = -160,
			close = { eye = v3(0.5, 5.0, -3.6), look = v3(2.2, 4.15, 2.4), fov = 30 },
		},
		{
			at = v3(1.2, 0.1, -9.6),
			yaw = -12,
			close = { eye = v3(-0.2, 5.0, -3.4), look = v3(1.2, 4.15, -9.6), fov = 30 },
		},
	},
	shots = {
		wide = { eye = v3(0, 6.2, 14), look = v3(0, 3.6, -8), fov = 46 },
		two = { eye = v3(-0.8, 4.8, -5.4), look = v3(0, 4.4, 2.2), fov = 36 },
		road = { eye = v3(0, 6.0, 12), look = v3(0, 3.4, -40), fov = 40 },
		out = { eye = v3(0, 4.6, -14.5), look = v3(0, 4.6, 1.5), fov = 42 },
		pan = {
			eye = v3(-6.5, 5.6, -16),
			look = v3(-2, 4.4, 0),
			fov = 46,
			to = { eye = v3(6.5, 5.6, -16), look = v3(2, 4.4, 0), fov = 46 },
		},
	},
	bounds = { lo = v3(-13, 1, -17), hi = v3(13, 14, 16) },
	light = { ambient = rgb(164, 164, 176), color = rgb(255, 240, 214), dir = v3(-0.55, -0.62, -0.56) },
	sky = {
		top = rgb(104, 164, 228),
		mid = rgb(150, 196, 236),
		horizon = rgb(226, 224, 180),
		low = rgb(150, 182, 130),
		sun = { dir = v3(0.62, 0.5, 0.6), size = 70, color = rgb(255, 236, 170), glow = rgb(255, 220, 170) },
	},
	build = function(r: R)
		local GRASS = rgb(124, 174, 100)
		local ROAD = rgb(196, 170, 132)
		local STONE = rgb(186, 180, 170)
		local STONE_DARK = rgb(150, 144, 136)
		local WOOD = rgb(150, 110, 80)
		r:block(-120, -1, -260, 120, 0, 40, GRASS, "Grass")
		r:block(-3.6, 0, -260, 3.6, 0.1, 40, ROAD, "Ground")
		for _, x in { -1.6, 1.6 } do
			r:block(x - 0.35, 0.1, -260, x + 0.35, 0.14, 40, shade(ROAD, 0.88), "Ground")
		end
		-- the fields either side: rows of crops on the left, a hay bale or two on the right
		for k = 0, 9 do
			local x = -10 - k * 2.2
			r:block(
				x - 0.7,
				0,
				-150,
				x + 0.7,
				0.4,
				-12,
				if k % 2 == 0 then rgb(150, 190, 96) else rgb(176, 200, 110),
				"Grass"
			)
		end
		town(r, "hayBale", CFrame.new(16, 0, -26) * yaw(30))
		town(r, "hayBale", CFrame.new(21, 0, -32) * yaw(-20))
		-- fences along the road out of town: posts and two rails
		for z = -8, -112, -8 do
			for _, x in { -5.4, 5.4 } do
				r:box(x, 0.95, z, 0.3, 1.9, 0.3, WOOD, "Wood")
				if z > -112 then
					r:box(x, 0.8, z - 4, 0.14, 0.2, 8, shade(WOOD, 1.08), "Wood")
					r:box(x, 1.55, z - 4, 0.14, 0.2, 8, shade(WOOD, 1.08), "Wood")
				end
			end
		end
		-- the pillars, with a lantern on each, a stone wall either side with its coping
		local H = 10 -- the pillars' height
		local IRON = rgb(60, 60, 70)
		for _, sx in { -1, 1 } do
			local x = sx * 5.2
			r:block(x - 1, 0, -1, x + 1, H, 1, STONE, "Cobblestone")
			r:block(x - 1.2, 0, -1.2, x + 1.2, 0.6, 1.2, STONE_DARK, "Cobblestone")
			r:block(x - 1.25, H, -1.25, x + 1.25, H + 0.4, 1.25, STONE_DARK, "Slate")
			r:block(x - 0.5, H + 0.4, -0.5, x + 0.5, H + 0.6, 0.5, IRON, "Metal")
			r:block(x - 0.36, H + 0.6, -0.36, x + 0.36, H + 1.6, 0.36, rgb(255, 228, 176), "Glass")
			for _, ox in { -0.4, 0.4 } do
				for _, oz in { -0.4, 0.4 } do
					r:box(x + ox, H + 1.1, oz, 0.1, 1.0, 0.1, IRON, "Metal")
				end
			end
			r:block(x - 0.56, H + 1.6, -0.56, x + 0.56, H + 1.76, 0.56, IRON, "Metal")
			r:cone(x, H + 2.1, 0, 0.7, 0.9, IRON, "Metal")
			local x1, x2 = if sx < 0 then -34 else 6.2, if sx < 0 then -6.2 else 34
			r:block(x1, 0, -0.6, x2, 2.4, 0.6, STONE, "Cobblestone")
			r:block(x1, 2.4, -0.75, x2, 2.7, 0.75, STONE_DARK, "Slate")
			-- barrels of flowers inside the pillars
			local bx = sx * 3.9
			r:cyl(bx, 0.7, 2.6, 1.4, 1.8, "y", rgb(150, 104, 70), "WoodPlanks")
			for _, y in { 0.3, 1.1 } do
				r:cyl(bx, y, 2.6, 0.12, 1.86, "y", rgb(80, 80, 88), "Metal")
			end
			r:cyl(bx, 1.45, 2.6, 0.1, 1.6, "y", C.Soil, "Ground")
			r:lump(CFrame.new(bx, 1.9, 2.6), 1.8, 1.0, 1.8, C.Leaf, "Grass")
			for k = 0, 3 do
				local a = k * 1.6 + sx
				local col = if k % 2 == 0 then rgb(246, 150, 170) else rgb(250, 216, 110)
				r:ball(bx + math.cos(a) * 0.6, 2.3, 2.6 + math.sin(a) * 0.6, 0.4, col, "SmoothPlastic")
			end
		end
		-- the beam between the pillars' tops with its little roof, and the board hanging from it
		local B = H - 1.2 -- the beam's underside
		r:block(-6.4, B, -0.4, 6.4, B + 0.7, 0.4, WOOD, "Wood")
		r:wedge(CFrame.new(0, B + 1.2, -0.55) * yaw(180), 13.6, 1.0, 1.1, rgb(150, 92, 76), "Slate")
		r:wedge(CFrame.new(0, B + 1.2, 0.55), 13.6, 1.0, 1.1, rgb(150, 92, 76), "Slate")
		r:block(-6.9, B + 1.68, -0.12, 6.9, B + 1.84, 0.12, rgb(120, 76, 64), "Slate")
		local G = B - 2.6 -- the board's foot
		for _, x in { -1.9, 1.9 } do
			r:box(x, G + 1.95, 0, 0.08, 1.3, 0.08, IRON, "Metal")
		end
		r:block(-2.6, G + 0.1, -0.12, 2.6, G + 1.3, 0.12, rgb(246, 236, 214), "Wood")
		r:block(-2.7, G, -0.16, 2.7, G + 0.1, 0.16, WOOD, "Wood")
		r:block(-2.7, G + 1.3, -0.16, 2.7, G + 1.4, 0.16, WOOD, "Wood")
		-- the board's picture: two little houses with their roofs and a tree, on both faces
		for _, side in { -1, 1 } do
			local z = side * 0.14
			local function mark(x1: number, y1: number, x2: number, y2: number, color: Color3)
				r:block(x1, G + y1, z - 0.02, x2, G + y2, z + 0.02, color, "SmoothPlastic")
			end
			mark(-1.9, 0.3, -1.0, 0.8, rgb(90, 150, 150))
			mark(-0.7, 0.3, 0.3, 0.9, rgb(220, 120, 100))
			mark(1.0, 0.3, 1.2, 0.7, rgb(120, 90, 70))
			r:ball(1.1, G + 0.9, z, 0.6, rgb(110, 170, 100), "SmoothPlastic")
			for _, roof in { { -1.9, -1.0, 0.8 }, { -0.7, 0.3, 0.9 } } do
				local w = (roof[2] - roof[1]) / 2
				r:wedge(
					CFrame.new(roof[1] + w / 2, G + roof[3] + 0.15, z) * yaw(90),
					0.04,
					0.3,
					w,
					rgb(150, 92, 76),
					"SmoothPlastic"
				)
				r:wedge(
					CFrame.new(roof[2] - w / 2, G + roof[3] + 0.15, z) * yaw(-90),
					0.04,
					0.3,
					w,
					rgb(150, 92, 76),
					"SmoothPlastic"
				)
			end
		end
		-- a signpost, a mailbox, a bench, and the suitcase on the road
		town(r, "signpost", CFrame.new(7.8, 0, -4.2) * yaw(-20))
		town(r, "mailbox", CFrame.new(-7.6, 0, 3.4) * yaw(20))
		town(r, "bench", CFrame.new(-10.5, 0, 6.5) * yaw(90))
		local sc = CFrame.new(0.4, 0.1, -7.4) * yaw(14)
		r:boxAt(sc * CFrame.new(0, 0.7, 0), 1.9, 1.4, 0.7, rgb(170, 100, 76), "Leather")
		for _, sx in { -0.5, 0.5 } do
			r:boxAt(sc * CFrame.new(sx, 0.7, 0), 0.16, 1.48, 0.78, rgb(120, 70, 52), "Leather")
		end
		r:boxAt(sc * CFrame.new(0, 1.5, 0), 0.7, 0.12, 0.14, rgb(80, 60, 50), "Leather")
		for _, sx in { -0.35, 0.35 } do
			r:boxAt(sc * CFrame.new(sx, 1.46, 0), 0.1, 0.12, 0.14, rgb(80, 60, 50), "Leather")
		end
		r:boxAt(sc * CFrame.new(0.7, 1.0, 0.38), 0.3, 0.4, 0.04, rgb(250, 240, 210), "Fabric")
		-- trees in the fields, a windmill and the hills far off
		town(r, "lowTree", CFrame.new(-22, 0, -34) * yaw(30))
		town(r, "lowTreeBig", CFrame.new(26, 0, -56) * yaw(120))
		town(r, "lowTree", CFrame.new(-34, 0, -88) * yaw(210))
		town(r, "windmill", CFrame.new(-56, 0, -150) * yaw(30))
		for i = 0, 6 do
			r:lump(
				CFrame.new(-150 + i * 50, -14, -240 - (i % 2) * 14),
				90,
				46 + (i % 3) * 10,
				50,
				rgb(140, 176, 150),
				"Grass"
			)
		end
	end,
})

-- A kitchen at night: a run of cupboards along the back with the hob, a pot and a kettle, the sink
-- under the window (dark outside, the moon over the roofs), shelves of jars and plates, pans on a
-- rail, a fridge with things stuck to it, a table with a pie on it and a lamp hanging low over it.
stage({
	id = "kitchen",
	name = "A kitchen at night",
	marks = {
		{ at = v3(-3.2, 0, -1.6), yaw = 78 },
		{ at = v3(3.2, 0, -1.6), yaw = -78 },
		{ at = v3(5.4, 0, -6.4), yaw = -50 },
	},
	shots = {
		wide = { eye = v3(0, 6, 9.4), look = v3(0, 3.6, -4), fov = 48 },
		two = { eye = v3(0, 5.0, 4.6), look = v3(0, 4.3, -1.6), fov = 38 },
		pie = { eye = v3(0.6, 4.8, 2.4), look = v3(0, 3.1, -1.6), fov = 30 },
		high = { eye = v3(-6, 8.4, 6.4), look = v3(0, 2.6, -3), fov = 44 },
		pan = {
			eye = v3(-9.4, 5.4, 6.4),
			look = v3(-6, 3.5, -7),
			fov = 46,
			to = { eye = v3(9.4, 5.4, 6.4), look = v3(6, 3.5, -7), fov = 46 },
		},
	},
	bounds = { lo = v3(-11, 1, -5), hi = v3(11, 9, 10) },
	light = { ambient = rgb(126, 100, 98), color = rgb(255, 208, 156), dir = v3(0.3, -0.88, -0.36) },
	sky = { top = rgb(18, 22, 52), mid = rgb(30, 36, 78), horizon = rgb(54, 60, 110), low = rgb(20, 22, 44) },
	build = function(r: R)
		local WALL = rgb(236, 220, 186)
		local TILE = rgb(176, 210, 206)
		local CUP = rgb(126, 160, 150)
		local TOP = rgb(214, 196, 170)
		local WOOD = rgb(176, 130, 92)
		local IRON = rgb(60, 60, 70)
		-- the floor in big checked tiles, the walls, the ceiling and the beams under it
		r:block(-14, -1, -10, 14, 0, 11, rgb(226, 214, 196), "CeramicTiles")
		for i = 0, 8 do
			for j = 0, 6 do
				if (i + j) % 2 == 0 then
					local x, z = -13.5 + i * 3, -9.5 + j * 3
					r:block(x, 0, z, x + 3, 0.04, z + 3, rgb(150, 120, 106), "CeramicTiles")
				end
			end
		end
		r:block(-14.6, -1, -10.6, 14.6, 10, -10, WALL, "Plaster")
		r:block(-14.6, -1, -10, -14, 10, 11, WALL, "Plaster")
		r:block(14, -1, -10, 14.6, 10, 11, WALL, "Plaster")
		r:block(-14.6, 10, -10.6, 14.6, 10.6, 11, rgb(244, 236, 222), "Plaster")
		for x = -10, 10, 5 do
			r:block(x - 0.4, 9.4, -10, x + 0.4, 10, 11, rgb(150, 110, 80), "Wood")
		end
		-- the run of cupboards: doors and handles, the worktop, the tiles behind it
		r:block(-13.4, 0, -10, 5, 3.1, -7.6, CUP, "Wood")
		r:block(-13.4, 0, -7.6, 5, 0.4, -7.5, shade(CUP, 0.7), "Wood")
		for x = -12.5, 4, 2.3 do
			r:block(x, 0.6, -7.6, x + 2.0, 2.9, -7.54, shade(CUP, 1.08), "Wood")
			r:box(x + 1.7, 2.4, -7.5, 0.12, 0.5, 0.08, C.Gold, "Metal")
		end
		r:block(-13.6, 3.1, -10, 5.2, 3.4, -7.4, TOP, "Marble")
		r:block(-13.4, 3.4, -10, 5, 6.2, -9.96, TILE, "CeramicTiles")
		for y = 4.0, 6.0, 0.7 do
			r:block(-13.4, y, -9.96, 5, y + 0.06, -9.92, shade(TILE, 0.85), "CeramicTiles")
		end
		-- the hob with two pans and a kettle on it, the hood over it
		local hx = -9.4
		r:block(hx - 1.6, 3.4, -9.6, hx + 1.6, 3.5, -7.6, rgb(50, 50, 60), "Metal")
		for _, b in { { -0.8, -9.0 }, { 0.8, -9.0 }, { -0.8, -8.1 }, { 0.8, -8.1 } } do
			r:cyl(hx + b[1], 3.53, b[2], 0.06, 0.7, "y", rgb(90, 90, 100), "Metal")
		end
		r:cyl(hx - 0.8, 4.06, -9.0, 1.0, 1.3, "y", rgb(206, 90, 70), "Metal")
		r:cyl(hx - 0.8, 4.6, -9.0, 0.08, 1.36, "y", rgb(180, 76, 60), "Metal")
		r:ball(hx - 0.8, 4.72, -9.0, 0.24, IRON, "Metal")
		r:box(hx - 1.6, 4.3, -9.0, 0.5, 0.16, 0.2, IRON, "Metal")
		r:box(hx, 4.3, -9.0, 0.5, 0.16, 0.2, IRON, "Metal")
		r:cyl(hx + 0.8, 3.98, -8.1, 0.9, 1.0, "y", rgb(232, 230, 222), "Metal")
		r:cone(hx + 0.8, 4.6, -8.1, 0.4, 0.9, rgb(232, 230, 222), "Metal")
		r:beam(v3(hx + 1.2, 3.9, -8.1), v3(hx + 1.7, 4.4, -8.1), 0.2, 0.2, rgb(232, 230, 222), "Metal")
		r:beam(v3(hx + 0.45, 4.6, -8.1), v3(hx + 1.15, 4.6, -8.1), 0.12, 0.12, IRON, "Metal")
		r:block(hx - 1.8, 7.2, -10, hx + 1.8, 7.8, -8.0, rgb(200, 202, 208), "Metal")
		r:block(hx - 0.7, 7.8, -10, hx + 0.7, 10, -9.0, rgb(200, 202, 208), "Metal")
		r:block(hx - 1.6, 0.8, -7.6, hx + 1.6, 2.7, -7.5, rgb(60, 60, 70), "Metal")
		r:block(hx - 1.2, 1.2, -7.5, hx + 1.2, 2.3, -7.46, rgb(40, 40, 52), "Glass")
		r:box(hx, 2.55, -7.4, 2.2, 0.1, 0.1, rgb(200, 202, 208), "Metal")
		-- the sink under the window, its tap, a plant on the sill
		local sx0 = -1.8
		r:block(sx0 - 1.6, 3.4, -9.6, sx0 + 1.6, 3.44, -7.8, rgb(190, 194, 200), "Metal")
		r:block(sx0 - 1.3, 3.44, -9.3, sx0 + 1.3, 3.48, -8.1, rgb(120, 124, 134), "Metal")
		r:cyl(sx0, 3.9, -9.7, 0.9, 0.2, "y", rgb(200, 202, 208), "Metal")
		r:beam(v3(sx0, 4.3, -9.7), v3(sx0, 4.3, -9.0), 0.16, 0.16, rgb(200, 202, 208), "Metal")
		r:block(sx0 - 2.2, 6.4, -10, sx0 + 2.2, 9.0, -9.96, rgb(30, 38, 84), "Glass")
		r:block(sx0 + 0.6, 7.9, -9.96, sx0 + 1.1, 8.4, -9.92, rgb(236, 232, 196), "Neon")
		for _, roof in { { -2.2, -0.6, 7.0 }, { -0.4, 1.2, 6.8 }, { 1.0, 2.2, 7.2 } } do
			r:block(sx0 + roof[1], 6.4, -9.96, sx0 + roof[2], roof[3], -9.92, rgb(20, 24, 52), "SmoothPlastic")
		end
		r:block(sx0 + 0.2, 6.4, -9.96, sx0 + 0.4, 6.6, -9.88, rgb(255, 214, 140), "Neon")
		r:block(sx0 - 2.4, 6.2, -10, sx0 + 2.4, 6.4, -9.6, rgb(250, 244, 232), "Wood")
		r:block(sx0 - 2.4, 9.0, -10, sx0 + 2.4, 9.2, -9.8, rgb(250, 244, 232), "Wood")
		r:block(sx0 - 2.4, 6.4, -10, sx0 - 2.2, 9.0, -9.8, rgb(250, 244, 232), "Wood")
		r:block(sx0 + 2.2, 6.4, -10, sx0 + 2.4, 9.0, -9.8, rgb(250, 244, 232), "Wood")
		r:block(sx0 - 0.08, 6.4, -9.96, sx0 + 0.08, 9.0, -9.88, rgb(250, 244, 232), "Wood")
		pot(r, sx0 + 1.5, 6.4, -9.85, 0.4, rgb(196, 110, 84), rgb(250, 200, 120))
		for _, side in { -1, 1 } do
			r:block(sx0 + side * 2.4 - 0.5, 6.0, -9.78, sx0 + side * 2.4 + 0.5, 9.4, -9.5, rgb(240, 200, 120), "Fabric")
		end
		-- shelves of jars and plates, and pans hanging from a rail
		for _, y in { 6.6, 8.0 } do
			r:block(1.6, y, -10, 5.0, y + 0.16, -9.0, WOOD, "Wood")
			for _, x in { 1.9, 4.7 } do
				r:block(x - 0.08, y - 0.5, -10, x + 0.08, y, -9.2, shade(WOOD, 0.8), "Wood")
			end
		end
		for i, x in { 2.1, 2.8, 3.5, 4.2 } do
			r:cyl(x, 7.06, -9.5, 0.8, 0.5, "y", rgb(220, 226, 230), "Glass")
			r:cyl(
				x,
				6.96,
				-9.5,
				0.56,
				0.42,
				"y",
				({ rgb(230, 130, 90), rgb(240, 200, 90), rgb(170, 110, 160), rgb(130, 180, 100) })[i],
				"SmoothPlastic"
			)
			r:cyl(x, 7.5, -9.5, 0.1, 0.56, "y", rgb(196, 160, 110), "Wood")
		end
		for i, x in { 2.3, 3.0, 3.7, 4.4 } do
			-- (each a little in front of the last, so none share a face)
			r:cyl(
				x,
				8.66,
				-9.74 + i * 0.1,
				0.08,
				1.0,
				"z",
				({ rgb(250, 248, 240), rgb(150, 190, 210) })[i % 2 + 1],
				"Marble"
			)
		end
		r:cyl(-5.2, 8.2, -9.6, 4.6, 0.1, "x", rgb(200, 202, 208), "Metal")
		for i, x in { -6.8, -5.2, -3.6 } do
			r:box(x, 7.85, -9.6, 0.06, 0.7, 0.06, IRON, "Metal")
			local d = 1.2 - i * 0.1
			r:cyl(x, 7.0 - d / 2, -9.5, 0.12, d, "z", rgb(70, 70, 80), "Metal")
			r:box(x, 7.4, -9.5, 0.12, 0.5, 0.1, rgb(70, 70, 80), "Metal")
		end
		-- the fridge, a little rounded at the top, with handles and what is stuck to it
		local fx = 9.6
		r:block(fx - 1.7, 0, -10, fx + 1.7, 7.4, -7.4, rgb(196, 226, 214), "SmoothPlastic")
		r:block(fx - 1.7, 5.2, -7.4, fx + 1.7, 5.3, -7.36, shade(rgb(196, 226, 214), 0.8), "SmoothPlastic")
		r:box(fx - 1.3, 3.4, -7.3, 0.16, 2.0, 0.16, rgb(200, 202, 208), "Metal")
		r:box(fx - 1.3, 6.1, -7.3, 0.16, 1.0, 0.16, rgb(200, 202, 208), "Metal")
		r:block(fx - 0.4, 3.0, -7.4, fx + 0.9, 4.4, -7.36, rgb(250, 248, 236), "SmoothPlastic")
		r:block(fx - 0.2, 3.4, -7.36, fx + 0.3, 3.9, -7.33, rgb(240, 140, 120), "SmoothPlastic")
		for i, m in { { 0.9, 6.2 }, { 1.2, 4.9 }, { 0.2, 5.8 } } do
			r:cyl(
				fx + m[1],
				m[2],
				-7.34,
				0.1,
				0.3,
				"z",
				({ rgb(240, 120, 110), rgb(110, 170, 230), rgb(250, 210, 90) })[i],
				"Plastic"
			)
		end
		-- the table, a cloth down the middle, the pie, a bowl of fruit and two mugs
		local TX, TZ = 0, -1.6
		for _, ox in { -1.4, 1.4 } do
			for _, oz in { -2.6, 2.6 } do
				r:box(TX + ox, 1.35, TZ + oz, 0.3, 2.7, 0.3, shade(WOOD, 0.85), "Wood")
			end
		end
		r:block(TX - 1.75, 2.7, TZ - 3.0, TX + 1.75, 3.0, TZ + 3.0, WOOD, "Wood")
		r:block(TX - 0.9, 3.0, TZ - 3.04, TX + 0.9, 3.04, TZ + 3.04, rgb(214, 96, 90), "Fabric")
		r:cyl(TX, 3.08, TZ, 0.08, 1.9, "y", rgb(246, 244, 236), "Marble")
		r:cyl(TX, 3.3, TZ, 0.36, 1.5, "y", rgb(226, 170, 100), "SmoothPlastic")
		for k = -2, 2 do
			r:box(TX + k * 0.28, 3.5, TZ, 0.12, 0.04, 1.3 - math.abs(k) * 0.18, rgb(240, 196, 130), "SmoothPlastic")
			r:box(TX, 3.54, TZ + k * 0.28, 1.3 - math.abs(k) * 0.18, 0.04, 0.12, rgb(240, 196, 130), "SmoothPlastic")
		end
		r:cyl(TX, 3.3, TZ - 2.0, 0.5, 1.2, "y", rgb(110, 150, 190), "Marble")
		for k = 0, 3 do
			local a = k * 1.6
			r:ball(
				TX + math.cos(a) * 0.3,
				3.7,
				TZ - 2.0 + math.sin(a) * 0.3,
				0.5,
				({ rgb(220, 70, 70), rgb(250, 190, 70), rgb(150, 200, 80), rgb(220, 70, 70) })[k + 1],
				"SmoothPlastic"
			)
		end
		for _, m in
			{ { x = -1.1, z = 1.0, color = rgb(250, 248, 240) }, { x = 1.1, z = 0.4, color = rgb(240, 196, 120) } }
		do
			r:cyl(TX + m.x, 3.34, TZ + m.z, 0.6, 0.5, "y", m.color, "Marble")
			r:box(TX + m.x + 0.33, 3.34, TZ + m.z, 0.16, 0.36, 0.1, m.color, "Marble")
		end
		-- a chair at the far end, a stool by the cupboards and the rug under the table
		local cf = CFrame.new(TX, 0, TZ - 4.0) * yaw(180)
		for _, ox in { -0.65, 0.65 } do
			for _, oz in { -0.65, 0.65 } do
				r:boxAt(cf * CFrame.new(ox, 0.9, oz), 0.2, 1.8, 0.2, shade(WOOD, 0.85), "Wood")
			end
			r:boxAt(cf * CFrame.new(ox, 2.9, 0.65), 0.2, 2.2, 0.2, shade(WOOD, 0.85), "Wood")
		end
		r:boxAt(cf * CFrame.new(0, 1.9, 0), 1.6, 0.2, 1.6, WOOD, "Wood")
		r:boxAt(cf * CFrame.new(0, 3.5, 0.65), 1.3, 0.8, 0.14, WOOD, "Wood")
		r:cyl(-5.4, 1.2, -6.4, 2.4, 0.2, "y", IRON, "Metal")
		r:cyl(-5.4, 2.5, -6.4, 0.2, 1.3, "y", rgb(214, 96, 90), "Fabric")
		r:cyl(-5.4, 0.05, -6.4, 0.1, 1.2, "y", IRON, "Metal")
		r:block(-3.6, 0.04, -6.2, 3.6, 0.12, 3.0, rgb(170, 130, 110), "Fabric")
		r:block(-3.1, 0.12, -5.7, 3.1, 0.16, 2.5, rgb(230, 204, 160), "Fabric")
		-- the lamp hanging low over the table, lit
		r:box(TX, 8.5, TZ, 0.06, 3.0, 0.06, IRON, "Metal")
		r:cone(TX, 6.6, TZ, 0.8, 2.2, rgb(240, 150, 100), "Metal")
		r:ball(TX, 6.15, TZ, 0.6, rgb(255, 222, 168), "Neon")
		-- a clock on the left wall, a calendar beside it
		r:cyl(-13.95, 7.0, 2, 0.1, 1.6, "x", rgb(250, 246, 236), "Marble")
		r:cyl(-14.0, 7.0, 2, 0.06, 1.8, "x", rgb(150, 110, 80), "Wood")
		r:box(-13.88, 7.25, 2, 0.04, 0.5, 0.08, IRON, "Metal")
		r:box(-13.88, 7.0, 2.15, 0.04, 0.08, 0.4, IRON, "Metal")
		r:block(-13.96, 4.6, -1.4, -13.92, 6.4, 0.0, rgb(250, 246, 236), "SmoothPlastic")
		r:block(-13.92, 5.8, -1.3, -13.9, 6.3, -0.1, rgb(214, 96, 90), "SmoothPlastic")
	end,
})

-- A market stall on a busy morning: a counter of boards with boxes of fruit and vegetables on
-- it, scales and a cash tin, a striped awning on four posts with a scalloped edge, bunting, a
-- shelf of jars and baskets at the back, crates and sacks round it, a board out front, and the
-- green with its trees behind.
stage({
	id = "stall",
	name = "A busy market stall",
	marks = {
		-- (seen over the fruit on the counter)
		{ at = v3(0, 0, -2.8), yaw = 0, close = { eye = v3(-0.8, 5.6, 2.8), look = v3(0, 4.3, -2.8), fov = 30 } },
		{ at = v3(-3.0, 0, 1.8), yaw = 150 },
		{ at = v3(3.4, 0, 2.6), yaw = -142 },
	},
	shots = {
		wide = { eye = v3(5, 5.6, 14), look = v3(0, 3.6, -1.5), fov = 44 },
		two = { eye = v3(1.5, 5.2, 6.5), look = v3(-1.4, 4.4, -0.6), fov = 38 },
		counter = { eye = v3(-1.4, 5.4, 2.6), look = v3(0.4, 3.4, -1.0), fov = 36 },
		queue = { eye = v3(8.4, 4.4, 2.4), look = v3(0, 4, 0.6), fov = 40 },
		pan = {
			eye = v3(-10, 5, 9),
			look = v3(-3, 3.5, -2),
			fov = 44,
			to = { eye = v3(10, 5, 9), look = v3(3, 3.5, -2), fov = 44 },
		},
	},
	bounds = { lo = v3(-12, 1, -0.4), hi = v3(12, 12, 16) },
	light = { ambient = rgb(166, 164, 172), color = rgb(255, 244, 224), dir = v3(-0.42, -0.8, -0.44) },
	sky = {
		top = rgb(96, 158, 228),
		mid = rgb(146, 192, 234),
		horizon = rgb(212, 226, 184),
		low = rgb(150, 182, 130),
	},
	build = function(r: R)
		local PAVE = rgb(214, 204, 188)
		local WOOD = rgb(170, 124, 84)
		local CORAL = rgb(234, 120, 104)
		local CREAM = rgb(250, 240, 220)
		r:block(-60, -1, -50, 60, 0, 40, rgb(124, 172, 100), "Grass")
		r:block(-16, 0, -8, 16, 0.1, 22, PAVE, "Pavement")
		for x = -14, 14, 4 do
			r:block(x - 0.06, 0.1, -8, x + 0.06, 0.14, 22, shade(PAVE, 0.86), "Pavement")
		end
		-- the counter: boards on a frame, with crates of produce on it
		r:block(-3.6, 0, -1.6, 3.6, 3.0, -0.4, WOOD, "WoodPlanks")
		for y = 0.4, 2.6, 0.55 do
			r:block(-3.6, y, -0.4, 3.6, y + 0.4, -0.34, shade(WOOD, 1.1), "WoodPlanks")
		end
		r:block(-3.8, 3.0, -1.8, 3.8, 3.2, -0.2, shade(WOOD, 0.85), "Wood")
		local fruit = {
			{ x = -2.6, color = rgb(214, 64, 64) },
			{ x = -1.0, color = rgb(250, 160, 60) },
			{ x = 0.6, color = rgb(130, 190, 80) },
			{ x = 2.2, color = rgb(240, 210, 80) },
		}
		for i, f in fruit do
			crate(r, CFrame.new(f.x, 3.2, -1.0) * yaw((i % 2) * 6 - 3), 1.4, 0.7, 1.1, rgb(196, 160, 110))
			for k = 0, 5 do
				r:ball(
					f.x - 0.4 + (k % 3) * 0.4,
					3.95 + (k // 3) * 0.12,
					-1.25 + (k // 3) * 0.5,
					0.46,
					f.color,
					"SmoothPlastic"
				)
			end
		end
		-- scales and a cash tin at the end of the counter
		r:block(3.0, 3.2, -1.4, 3.7, 3.5, -0.6, rgb(200, 60, 60), "Metal")
		r:cyl(3.35, 3.56, -1.0, 0.1, 0.9, "y", rgb(200, 202, 208), "Metal")
		r:block(-3.7, 3.2, -0.9, -3.0, 3.6, -0.3, rgb(80, 120, 150), "Metal")
		-- four posts and the striped awning, its edge scalloped, bunting under it
		for _, sx in { -1, 1 } do
			for _, z in { -0.2, -4.2 } do
				r:box(sx * 3.9, 3.7, z, 0.3, 7.4, 0.3, WOOD, "Wood")
			end
		end
		local strips = 9
		for k = 0, strips - 1 do
			local x1 = -4.4 + k * 8.8 / strips
			local x2 = x1 + 8.8 / strips
			r:quad(
				v3(x1, 8.2, -4.8),
				v3(x2, 8.2, -4.8),
				v3(x2, 7.3, 0.6),
				v3(x1, 7.3, 0.6),
				0.12,
				if k % 2 == 0 then CORAL else CREAM,
				"Fabric"
			)
			r:wedge(
				CFrame.new((x1 + x2) / 2, 6.95, 0.62) * yaw(180) * CFrame.Angles(0, 0, math.pi),
				x2 - x1 - 0.04,
				0.6,
				0.06,
				if k % 2 == 0 then CORAL else CREAM,
				"Fabric"
			)
		end
		bunting(
			r,
			v3(-3.75, 6.8, -0.2),
			v3(3.75, 6.8, -0.2),
			0.5,
			9,
			{ rgb(110, 178, 220), rgb(250, 206, 96), rgb(150, 206, 130) }
		)
		-- the shelf at the back with jars and baskets
		r:block(-3.6, 0, -4.6, 3.6, 0.2, -3.6, shade(WOOD, 0.8), "Wood")
		for _, y in { 2.2, 4.0 } do
			r:block(-3.4, y, -4.6, 3.4, y + 0.16, -3.6, WOOD, "Wood")
		end
		for _, x in { -3.5, 3.5 } do
			r:block(x - 0.1, 0.2, -4.64, x + 0.1, 4.3, -3.56, shade(WOOD, 0.8), "Wood")
		end
		for i, x in { -2.6, -1.4, -0.2, 1.0, 2.2 } do
			r:cyl(x, 2.76, -4.1, 0.8, 0.5, "y", rgb(220, 226, 230), "Glass")
			r:cyl(
				x,
				2.7,
				-4.1,
				0.6,
				0.42,
				"y",
				({ rgb(230, 130, 90), rgb(240, 200, 90), rgb(170, 110, 160), rgb(130, 180, 100), rgb(220, 80, 80) })[i],
				"SmoothPlastic"
			)
			r:cyl(x, 3.2, -4.1, 0.1, 0.56, "y", CREAM, "Fabric")
		end
		for _, x in { -2.2, 0, 2.2 } do
			r:cyl(x, 4.5, -4.1, 0.6, 1.4, "y", rgb(200, 160, 100), "Fabric")
			r:lump(CFrame.new(x, 4.9, -4.1), 1.2, 0.5, 1.2, rgb(150, 190, 90), "Grass")
		end
		-- crates and sacks round it, a board out front
		town(r, "crateStack", CFrame.new(-6.2, 0.1, -1.6) * yaw(10))
		for i, s in { { 5.4, -0.6 }, { 6.2, -1.6 }, { 5.0, -2.4 } } do
			r:lump(CFrame.new(s[1], 0.9, s[2]) * yaw(i * 40), 1.2, 1.7, 1.1, rgb(214, 190, 150), "Fabric")
			r:cyl(s[1], 1.8, s[2], 0.2, 0.5, "y", rgb(160, 120, 80), "Fabric")
		end
		local ab = CFrame.new(-3.8, 0.1, 3.4) * yaw(30)
		r:boxAt(ab * CFrame.new(0, 1.6, -0.35) * CFrame.Angles(-0.2, 0, 0), 1.6, 3.2, 0.12, rgb(120, 90, 66), "Wood")
		r:boxAt(ab * CFrame.new(0, 1.6, 0.35) * CFrame.Angles(0.2, 0, 0), 1.6, 3.2, 0.12, rgb(120, 90, 66), "Wood")
		r:boxAt(ab * CFrame.new(0, 1.8, 0.66) * CFrame.Angles(0.2, 0, 0), 1.3, 2.2, 0.04, rgb(50, 60, 60), "Slate")
		for k = 0, 2 do
			r:boxAt(
				ab * CFrame.new(0, 2.4 - k * 0.5, 0.72) * CFrame.Angles(0.2, 0, 0),
				0.9 - k * 0.2,
				0.08,
				0.04,
				rgb(240, 236, 220),
				"Slate"
			)
		end
		-- the green behind: trees and hedges, a lamp, a planter, the next stall along
		town(r, "lamp", CFrame.new(-11.5, 0.1, 3))
		town(r, "planterBox", CFrame.new(11.4, 0.1, 6) * yaw(90))
		town(r, "marketStall", CFrame.new(-13.6, 0, -4) * yaw(10))
		town(r, "lowTree", CFrame.new(-6, 0, -16) * yaw(40))
		town(r, "lowTreeBig", CFrame.new(9, 0, -19) * yaw(160))
		town(r, "hedgeRow", CFrame.new(0, 0, -11))
		town(r, "hedgeRow", CFrame.new(16, 0, -10.6) * yaw(4))
	end,
})

-- The lookup ---------------------------------------------------------------------------------------

Stages.list = list

local byId: { [string]: Stage } = {}
for _, s in list do
	byId[s.id] = s
end

function Stages.get(id: string): Stage?
	return byId[id]
end

local built: { [string]: { Prim } } = {}

-- The set's primitives (what can be seen of it), built once. Don't change what comes back.
function Stages.prims(id: string): { Prim }
	local known = built[id]
	if known then
		return known
	end
	local s = byId[id]
	assert(s, "no stage " .. tostring(id))
	local r = Recipe.new(C.White, C.White)
	s.build(r)
	local made: { Prim } = {}
	for _, p in r.prims do
		if (p.transp or 0) < 0.99 then
			table.insert(made, p)
		end
	end
	built[id] = made
	return made
end

-- Which way a villager facing `deg` looks (0 is +Z, 90 is +X).
function Stages.facing(deg: number): Vector3
	local a = math.rad(deg)
	return Vector3.new(math.sin(a), 0, math.cos(a))
end

-- Where the eyes of whoever stands on mark i are.
function Stages.head(s: Stage, i: number): Vector3
	local m = s.marks[i]
	return m.at + Vector3.new(0, if m.sit then Stages.SitHead else Stages.Head, 0)
end

-- What the camera must keep clear of: every solid shape of the set (a see-through one, a beam of
-- light or a sheer drape, it may pass through) as its box, with the box round that in the set's
-- own axes to rule most of them out quickly. Round shapes count as their boxes, which is safe.
type Solid = { cf: CFrame, half: Vector3, lo: Vector3, hi: Vector3 }
local solidsOf: { [string]: { Solid } } = {}

local function solids(s: Stage): { Solid }
	local known = solidsOf[s.id]
	if known then
		return known
	end
	local made: { Solid } = {}
	for _, p in Geometry.flatten(Stages.prims(s.id)) do
		if (p.transp or 0) < 0.3 then
			local half = p.size / 2
			local lo = Vector3.new(math.huge, math.huge, math.huge)
			local hi = -lo
			for _, c in Geometry.corners(p) do
				lo, hi = lo:Min(c), hi:Max(c)
			end
			table.insert(made, { cf = p.cf, half = half, lo = lo, hi = hi })
		end
	end
	solidsOf[s.id] = made
	return made
end

-- Is the point within `margin` of anything solid on the set?
function Stages.inside(s: Stage, p: Vector3, margin: number): boolean
	for _, b in solids(s) do
		if
			p.X > b.lo.X - margin
			and p.X < b.hi.X + margin
			and p.Y > b.lo.Y - margin
			and p.Y < b.hi.Y + margin
			and p.Z > b.lo.Z - margin
			and p.Z < b.hi.Z + margin
		then
			local q = b.cf:PointToObjectSpace(p)
			if
				math.abs(q.X) < b.half.X + margin
				and math.abs(q.Y) < b.half.Y + margin
				and math.abs(q.Z) < b.half.Z + margin
			then
				return true
			end
		end
	end
	return false
end

-- Does the line from a to b come within `margin` of anything solid (tested every quarter stud)?
function Stages.blocked(s: Stage, a: Vector3, b: Vector3, margin: number): boolean
	local n = math.max(1, math.ceil((b - a).Magnitude / 0.25))
	for k = 0, n do
		if Stages.inside(s, a:Lerp(b, k / n), margin) then
			return true
		end
	end
	return false
end

-- Does the line from a to b come within `margin` of anybody standing on a mark other than `skip`
-- (each taken as a post from their feet to over their head)?
function Stages.crowded(s: Stage, a: Vector3, b: Vector3, margin: number, skip: number?): boolean
	local n = math.max(1, math.ceil((b - a).Magnitude / 0.25))
	for j, m in s.marks do
		if j ~= skip then
			local foot = m.at + Vector3.new(0, 0.3, 0)
			local top = Stages.head(s, j) + Vector3.new(0, 0.9, 0)
			for k = 0, n do
				local p = a:Lerp(b, k / n)
				local y = math.clamp(p.Y, foot.Y, top.Y)
				if (Vector3.new(p.X - foot.X, p.Y - y, p.Z - foot.Z)).Magnitude < margin then
					return true
				end
			end
		end
	end
	return false
end

Stages.Sides = { 52, 38, 66, 24, 80, 10 } -- how far round from where they face a close shot may go, best first
Stages.Room = 0.45 -- how near the camera may come to the set
Stages.Body = 1.3 -- and the line it looks along to anybody else on the set

local closeOf: { [string]: Shot } = {}

-- The close shot on mark i: in front of their face and round toward the set's front, at the first
-- angle (Stages.Sides) where nothing on the set and nobody else stands between the camera and
-- their face. Worked out once per mark.
function Stages.close(s: Stage, i: number): Shot
	local m = s.marks[i]
	if m.close then
		return m.close
	end
	local key = s.id .. ":" .. i
	local known = closeOf[key]
	if known then
		return known
	end
	local head = Stages.head(s, i)
	local look = head - Vector3.new(0, Stages.Close.drop, 0)
	local f = Stages.facing(m.yaw)
	local k = Stages.Close
	local first: Shot? = nil
	local found: Shot? = nil
	for _, angle in Stages.Sides do
		local tries = {}
		for _, side in { -1, 1 } do
			local d = (CFrame.Angles(0, math.rad(side * angle), 0) :: CFrame):VectorToWorldSpace(f)
			table.insert(tries, d)
		end
		-- the side nearer the set's front first
		table.sort(tries, function(a: Vector3, b: Vector3): boolean
			return a.Z > b.Z
		end)
		for _, d in tries do
			local eye = head + d * k.dist + Vector3.new(0, k.lift, 0)
			local shot = { eye = eye, look = look, fov = k.fov }
			first = first or shot
			local lo, hi = s.bounds.lo, s.bounds.hi
			local within = eye.X >= lo.X
				and eye.X <= hi.X
				and eye.Y >= lo.Y
				and eye.Y <= hi.Y
				and eye.Z >= lo.Z
				and eye.Z <= hi.Z
			-- (the last stud before their face is theirs: a hat brim or a lifted hand). The push
			-- in comes along the same line to Stages.Push.dist, so the camera needs room that far.
			local away = (eye - look).Unit
			local near = look + away * 1.0
			local push = look + away * Stages.Push.dist
			local pushIn = push.X >= lo.X
				and push.X <= hi.X
				and push.Y >= lo.Y
				and push.Y <= hi.Y
				and push.Z >= lo.Z
				and push.Z <= hi.Z
			if
				within
				and pushIn
				and not Stages.blocked(s, eye, push, Stages.Room)
				and not Stages.blocked(s, push, near, 0.2)
				and not Stages.crowded(s, eye, near, Stages.Body, i)
			then
				found = shot
				break
			end
		end
		if found then
			break
		end
	end
	local shot = found or first :: Shot
	closeOf[key] = shot
	return shot
end

-- The push in on mark i: where a slow push toward their face ends.
function Stages.push(s: Stage, i: number): Shot
	local c = Stages.close(s, i)
	local look = c.look + Vector3.new(0, Stages.Close.drop - Stages.Push.drop, 0)
	local dir = (c.eye - c.look).Unit
	return { eye = c.look + dir * Stages.Push.dist, look = look, fov = Stages.Push.fov }
end

-- Every place the camera can be: the named shots (a pan's start and end apart), and the close
-- shot and the push on each mark. { name, shot } in a steady order.
function Stages.allShots(s: Stage): { { name: string, shot: Shot } }
	local out = {}
	local names = {}
	for name in s.shots do
		table.insert(names, name)
	end
	table.sort(names)
	for _, name in names do
		local shot = s.shots[name]
		table.insert(out, { name = name, shot = { eye = shot.eye, look = shot.look, fov = shot.fov, sky = shot.sky } })
		if shot.to then
			table.insert(out, { name = name .. ":to", shot = shot.to })
		end
	end
	for i in s.marks do
		table.insert(out, { name = "close" .. i, shot = Stages.close(s, i) })
		table.insert(out, { name = "push" .. i, shot = Stages.push(s, i) })
	end
	return out
end

return Stages
