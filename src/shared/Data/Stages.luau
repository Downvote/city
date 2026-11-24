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
Stages.Close = { dist = 6.6, side = 52, fov = 30, lift = 0.3 } -- a close shot: how far, how far round, the lens
Stages.Push = { dist = 4.8, fov = 26 } -- where a push in ends

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
-- the same ones the town has. (The list a model comes in may be shared: each prim is copied.)
local function town(r: R, name: string, cf: CFrame)
	local TownMap = require(script.Parent.TownMap) :: any
	for _, p in TownMap.prims(name) do
		if (p.transp or 0) < 0.99 then
			local q = table.clone(p)
			q.cf = cf * p.cf
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
		r:block(x1, top - 0.16, a, x2, top, a + step - gap, if i % 2 == 0 then color else shade(color, 0.93), "WoodPlanks")
	end
	local b = bearer or shade(color, 0.6)
	for _, x in { x1 + 0.8, (x1 + x2) / 2, x2 - 0.8 } do
		r:block(x - 0.25, top - 0.46, z1 + 0.1, x + 0.25, top - 0.16, z2 - 0.1, b, "Wood")
	end
end

-- A rope or a wire from a to b that sags by `sag` in the middle, in `n` straight runs.
local function sagging(r: R, a: Vector3, b: Vector3, sag: number, n: number, thick: number, color: Color3, mat: string?): { Vector3 }
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
		r:tri(p - flat * half, p + flat * half, p - Vector3.new(0, 0.95, 0), 0.04, colors[(i - 1) % #colors + 1], "Fabric")
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
			r:ball(x + math.cos(a) * 0.5 * s, y + 1.95 * s, z + math.sin(a) * 0.5 * s, 0.32 * s, flower, "SmoothPlastic")
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
local function farBlock(r: R, x: number, z: number, w: number, d: number, base: number, top: number, color: Color3, lit: Color3?, seed: number, roof: string?)
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
		{ at = v3(-1.9, 0.3, -9.6), yaw = 72 },
		{ at = v3(1.9, 0.3, -9.6), yaw = -72 },
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
			r:beam(v3(tx + sx * 1.8, 0.6, tz - 1.8), v3(tx + sx * 1.8, 5.2, tz + 1.8), 0.16, 0.2, rgb(110, 80, 60), "Wood")
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
	local made = built[id]
	if not made then
		local s = byId[id]
		assert(s, "no stage " .. tostring(id))
		local r = Recipe.new(C.White, C.White)
		s.build(r)
		made = {}
		for _, p in r.prims do
			if (p.transp or 0) < 0.99 then
				table.insert(made, p)
			end
		end
		built[id] = made
	end
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

-- The close shot on mark i: in front of their face and round toward the set's front, so whoever
-- they face isn't in the way.
function Stages.close(s: Stage, i: number): Shot
	local m = s.marks[i]
	if m.close then
		return m.close
	end
	local head = Stages.head(s, i)
	local f = Stages.facing(m.yaw)
	local k = Stages.Close
	local best: Vector3 = f
	for _, side in { -1, 1 } do
		local d = (CFrame.Angles(0, math.rad(side * k.side), 0) :: CFrame):VectorToWorldSpace(f)
		if d.Z > best.Z or best == f then
			best = d
		end
	end
	return {
		eye = head + best * k.dist + Vector3.new(0, k.lift, 0),
		look = head - Vector3.new(0, 0.15, 0),
		fov = k.fov,
	}
end

-- The push in on mark i: where a slow push toward their face ends.
function Stages.push(s: Stage, i: number): Shot
	local c = Stages.close(s, i)
	local look = c.look
	local dir = (c.eye - look).Unit
	return { eye = look + dir * Stages.Push.dist, look = look, fov = Stages.Push.fov }
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
