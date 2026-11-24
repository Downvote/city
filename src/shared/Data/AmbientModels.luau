--!strict
-- The things that move around town but aren't anyone's to build: cars, the bus and the ducks.
-- Drawn with the Recipe API like everything else, each facing +Z at the origin. The client's
-- Ambience moves them; the parts named Wheel turn as they go.
--
-- The user asked for detail "similar to the default house everywhere", so a car has its cabin
-- with windows split by pillars, wheel arches, bumpers with number plates, a grille, lights and
-- mirrors; the bus its windows, doors, sign and mirrors. They are plain parts, not pieces: the
-- client moves every part of a car each frame and makes a piece's shapes as parts anyway. The
-- car park in Data/DetailModels parks these same cars.

local Recipe = require(script.Parent.Parent.Build.Recipe)
local Geometry = require(script.Parent.Parent.Build.Geometry)

type R = Recipe.Recipe
local C = Recipe.Colors

local AmbientModels = {}

AmbientModels.CarColors = {
	Color3.fromRGB(210, 104, 96),
	Color3.fromRGB(96, 140, 192),
	Color3.fromRGB(232, 196, 110),
	Color3.fromRGB(120, 184, 160),
	Color3.fromRGB(246, 242, 232),
	Color3.fromRGB(226, 146, 96),
	Color3.fromRGB(160, 136, 200),
}

local GLASS = Color3.fromRGB(70, 110, 150)
local TYRE = Color3.fromRGB(40, 38, 46)
local HUB = Color3.fromRGB(200, 204, 214)
local PLATE = Color3.fromRGB(246, 242, 226)

local function darker(c: Color3, k: number): Color3
	return Color3.new(c.R * k, c.G * k, c.B * k)
end

-- A wheel: the tyre and the hub in it, both named Wheel so they turn. A dark round on the body
-- behind it makes the arch.
local function wheel(r: R, x: number, z: number, d: number)
	local side = if x > 0 then 1 else -1
	local t = r:cyl(x, d / 2, z, 0.7, d, "x", TYRE, "SmoothPlastic")
	t.name = "Wheel"
	local h = r:cyl(x + side * 0.3, d / 2, z, 0.2, d * 0.5, "x", HUB, "Metal")
	h.name = "Wheel"
end

local function arch(r: R, x: number, z: number, d: number, face: number)
	local side = if x > 0 then 1 else -1
	r:cyl(side * (face + 0.07), d / 2, z, 0.06, d * 1.25, "x", Color3.fromRGB(52, 50, 58), "SmoothPlastic")
end

-- A small rounded city car: the body in c1 with a cabin on it, its windows split by pillars, a
-- windscreen and a rear window, bumpers with plates, a grille, headlights that light at night,
-- tail lights, mirrors, and wheels under arches.
local function car(r: R)
	local body = r.c1
	local trim = darker(body, 0.75)
	r:block(-2.3, 0.75, -4.5, 2.3, 2.2, 4.5, body, "SmoothPlastic")
	r:block(-2.36, 0.65, -4.6, 2.36, 1.05, 4.6, trim, "SmoothPlastic")
	r:block(-2.0, 2.2, -2.6, 2.0, 3.8, 1.6, body, "SmoothPlastic")
	-- the windows: two each side either side of the middle pillar, front and back
	for _, sx in { -1, 1 } do
		r:block(sx * 2.0, 2.45, -0.4, sx * 2.04, 3.55, 1.35, GLASS, "Glass")
		r:block(sx * 2.0, 2.45, -2.35, sx * 2.04, 3.55, -0.6, GLASS, "Glass")
	end
	r:block(-1.75, 2.4, 1.6, 1.75, 3.55, 1.64, GLASS, "Glass")
	r:block(-1.75, 2.5, -2.64, 1.75, 3.5, -2.6, GLASS, "Glass")
	-- bumpers with their plates, the grille, the lights
	r:block(-2.4, 0.7, 4.6, 2.4, 1.25, 4.9, C.DarkMetal, "Metal")
	r:block(-2.4, 0.7, -4.9, 2.4, 1.25, -4.6, C.DarkMetal, "Metal")
	r:block(-0.55, 0.78, 4.9, 0.55, 1.15, 4.94, PLATE, "SmoothPlastic")
	r:block(-0.55, 0.78, -4.94, 0.55, 1.15, -4.9, PLATE, "SmoothPlastic")
	r:block(-0.95, 1.4, 4.5, 0.95, 1.95, 4.56, darker(body, 0.55), "SmoothPlastic")
	for _, x in { -1.6, 1.6 } do
		r:glow(r:block(x - 0.45, 1.6, 4.5, x + 0.45, 2.05, 4.62, C.Warm, "Neon"), 0)
		r:block(x - 0.45, 1.6, -4.62, x + 0.45, 2.05, -4.5, C.Red, "Neon")
	end
	-- mirrors on the doors by the windscreen
	for _, sx in { -1, 1 } do
		r:block(sx * 2.0, 2.3, 1.05, sx * 2.38, 2.6, 1.3, trim, "SmoothPlastic")
	end
	for _, x in { -2.2, 2.2 } do
		for _, z in { -3, 3 } do
			arch(r, x, z, 1.6, 2.3)
			wheel(r, x, z, 1.6)
		end
	end
end

-- The town bus: long and two-tone, a row of windows with pillars between them, folding doors
-- in the middle of the kerb side (local -X), a lit sign over the windscreen, wipers, mirrors on arms, vents on
-- the roof, bumpers, lights and wheels under arches.
local function bus(r: R)
	local body = Color3.fromRGB(232, 192, 104)
	local band = Color3.fromRGB(88, 134, 184)
	r:block(-2.8, 0.8, -9, 2.8, 6.2, 9, body, "SmoothPlastic")
	r:block(-2.85, 0.7, -9.1, 2.85, 1.5, 9.1, band, "SmoothPlastic")
	r:block(-2.9, 3.2, -8.6, 2.9, 5.2, 8.2, GLASS, "Glass")
	for z = -7, 7, 3.5 do
		r:block(-2.95, 3.2, z - 0.15, 2.95, 5.2, z + 0.15, body, "SmoothPlastic")
	end
	r:block(-2.6, 2, 9, 2.6, 5.4, 9.15, GLASS, "Glass")
	r:block(-2.6, 2.4, -9.15, 2.6, 5.2, -9, GLASS, "Glass")
	r:block(-1.6, 5.5, 9.05, 1.6, 6.1, 9.2, Color3.fromRGB(40, 40, 50), "SmoothPlastic")
	r:block(-1.4, 5.6, 9.2, 1.4, 6, 9.25, C.Warm, "Neon")
	r:block(-2.9, 6.2, -9.1, 2.9, 6.5, 9.1, band, "SmoothPlastic")
	-- the doors: two glass leaves in a dark frame, between the wheels
	r:block(-2.98, 1.5, 1.0, -2.92, 5.6, 4.0, Color3.fromRGB(60, 64, 76), "SmoothPlastic")
	r:block(-3.02, 1.7, 1.15, -2.98, 5.4, 2.45, GLASS, "Glass")
	r:block(-3.02, 1.7, 2.55, -2.98, 5.4, 3.85, GLASS, "Glass")
	-- wipers, mirrors on their arms, vents on the roof
	for _, x in { -1.2, 1.0 } do
		r:boxAt(CFrame.new(x, 2.4, 9.18) * CFrame.Angles(0, 0, 0.5), 1.5, 0.08, 0.05, C.Black, "SmoothPlastic")
	end
	for _, sx in { -1, 1 } do
		r:block(sx * 2.8, 5.1, 8.7, sx * 3.4, 5.2, 8.8, C.DarkMetal, "Metal")
		r:block(sx * 3.3, 4.3, 8.65, sx * 3.5, 5.15, 8.85, C.Black, "SmoothPlastic")
	end
	for _, z in { -4, 3 } do
		r:block(-1, 6.5, z - 1, 1, 6.8, z + 1, Color3.fromRGB(210, 206, 196), "SmoothPlastic")
	end
	-- bumpers, lights, wheels
	r:block(-2.9, 0.6, 9.1, 2.9, 1.2, 9.4, C.DarkMetal, "Metal")
	r:block(-2.9, 0.6, -9.4, 2.9, 1.2, -9.1, C.DarkMetal, "Metal")
	for _, x in { -1.9, 1.9 } do
		r:glow(r:block(x - 0.5, 1.6, 9.1, x + 0.5, 2.2, 9.25, C.Warm, "Neon"), 0)
		r:block(x - 0.5, 1.6, -9.25, x + 0.5, 2.2, -9.1, C.Red, "Neon")
	end
	for _, x in { -2.7, 2.7 } do
		for _, z in { -6, 6 } do
			arch(r, x, z, 2, 2.85)
			wheel(r, x, z, 2)
		end
	end
end

-- Small creatures (the user: "small creatures", and later "remove the butterflies and bunnies":
-- the ducks are what is left). Each faces +Z at the origin, feet on y = 0.

-- A duck that sits on the water: a body with its wings folded along it, a tail turned up, a head
-- with a white ring at the neck, two eyes and an orange beak.
local function duck(r: R)
	r:lump(CFrame.new(0, 0.4, 0), 1.2, 0.9, 1.7, r.c1)
	for _, sx in { -1, 1 } do
		r:lump(CFrame.new(sx * 0.47, 0.56, -0.15) * CFrame.Angles(0.15, sx * 0.12, 0), 0.34, 0.5, 1.2, darker(r.c1, 0.82))
	end
	r:boxAt(CFrame.new(0, 0.72, -0.9) * CFrame.Angles(-0.5, 0, 0), 0.5, 0.18, 0.45, darker(r.c1, 0.9), "SmoothPlastic")
	r:cyl(0, 0.82, 0.62, 0.12, 0.5, "y", Color3.fromRGB(250, 250, 246), "SmoothPlastic")
	r:ball(0, 1.08, 0.7, 0.8, r.c2, "SmoothPlastic")
	r:block(-0.15, 0.95, 1.05, 0.15, 1.1, 1.4, Color3.fromRGB(250, 160, 60), "SmoothPlastic")
	for _, sx in { -1, 1 } do
		r:ball(sx * 0.3, 1.2, 0.9, 0.12, C.Black, "SmoothPlastic")
	end
end

AmbientModels.Models = {
	duck = duck,
	car = car,
	bus = bus,
} :: { [string]: (R) -> () }

function AmbientModels.prims(name: string, c1: Color3?, c2: Color3?): { Geometry.Prim }
	local build = AmbientModels.Models[name]
	assert(build, "no ambient model " .. name)
	local r = Recipe.new(c1 or AmbientModels.CarColors[1], c2 or C.White)
	build(r)
	return r.prims
end

-- Every model side by side, for the preview tool.
function AmbientModels.preview(): { Geometry.Prim }
	local out = {}
	local x = 0
	type Entry = { name: string, c1: Color3?, c2: Color3? }
	local list: { Entry } = {
		{ name = "car", c1 = AmbientModels.CarColors[1] },
		{ name = "car", c1 = AmbientModels.CarColors[2] },
		{ name = "car", c1 = AmbientModels.CarColors[3] },
		{ name = "bus" },
		{ name = "duck", c1 = Color3.fromRGB(150, 116, 84), c2 = Color3.fromRGB(56, 130, 96) },
	}
	for _, e in list do
		for _, p in AmbientModels.prims(e.name, e.c1, e.c2) do
			p.cf = CFrame.new(x, 0, 0) * p.cf
			table.insert(out, p)
		end
		x += if e.name == "bus" then 16 elseif e.name == "duck" then 5 else 9
	end
	return out
end

return AmbientModels
