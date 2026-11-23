--!strict
-- The things that move around town but aren't anyone's to build: cars and the bus. Drawn with the Recipe API like everything else, each facing +Z at the origin. The
-- client's Ambience moves them; the parts named here (wheels, wings) are the ones it animates.

local Recipe = require(script.Parent.Parent.Build.Recipe)
local Geometry = require(script.Parent.Parent.Build.Geometry)

type R = Recipe.Recipe
local C = Recipe.Colors

local AmbientModels = {}

AmbientModels.CarColors = {
	Color3.fromRGB(232, 72, 72),
	Color3.fromRGB(64, 150, 240),
	Color3.fromRGB(255, 200, 60),
	Color3.fromRGB(110, 210, 170),
	Color3.fromRGB(245, 245, 240),
	Color3.fromRGB(255, 140, 60),
	Color3.fromRGB(170, 120, 230),
}

local GLASS = Color3.fromRGB(70, 110, 150)
local TYRE = Color3.fromRGB(40, 38, 46)
local HUB = Color3.fromRGB(200, 204, 214)

local function wheel(r: R, x: number, z: number, d: number)
	local t = r:cyl(x, d / 2, z, 0.7, d, "x", TYRE, "SmoothPlastic")
	t.name = "Wheel"
	local h = r:cyl(x + (if x > 0 then 0.3 else -0.3), d / 2, z, 0.2, d * 0.5, "x", HUB, "Metal")
	h.name = "Wheel"
end

-- A small rounded city car: body in c1, a cabin with windows, wheels, lights.
local function car(r: R)
	local body = r.c1
	local trim = Color3.new(body.R * 0.75, body.G * 0.75, body.B * 0.75)
	r:block(-2.3, 0.7, -4.6, 2.3, 2.3, 4.6, body, "SmoothPlastic")
	r:block(-2.35, 0.6, -4.7, 2.35, 1.05, 4.7, trim, "SmoothPlastic")
	-- the cabin, set back, with glass all round
	r:block(-2, 2.3, -2.6, 2, 3.9, 1.6, body, "SmoothPlastic")
	r:block(-2.05, 2.5, -2.4, 2.05, 3.7, 1.4, GLASS, "Glass")
	r:block(-1.8, 2.45, 1.4, 1.8, 3.6, 1.75, GLASS, "Glass")
	r:block(-1.8, 2.45, -2.75, 1.8, 3.6, -2.4, GLASS, "Glass")
	r:block(-2.1, 3.9, -2.7, 2.1, 4.1, 1.7, trim, "SmoothPlastic")
	-- bumpers and lights
	r:block(-2.4, 0.7, 4.6, 2.4, 1.3, 4.9, C.DarkMetal, "Metal")
	r:block(-2.4, 0.7, -4.9, 2.4, 1.3, -4.6, C.DarkMetal, "Metal")
	for _, x in { -1.6, 1.6 } do
		r:glow(r:block(x - 0.45, 1.6, 4.6, x + 0.45, 2.1, 4.75, C.Warm, "Neon"), 0)
		r:block(x - 0.45, 1.6, -4.75, x + 0.45, 2.1, -4.6, C.Red, "Neon")
	end
	for _, x in { -2.2, 2.2 } do
		for _, z in { -3, 3 } do
			wheel(r, x, z, 1.6)
		end
	end
end

-- The town bus: long, two-tone, with a row of windows and a sign on the front.
local function bus(r: R)
	local body = Color3.fromRGB(255, 196, 60)
	local band = Color3.fromRGB(64, 150, 240)
	r:block(-2.8, 0.8, -9, 2.8, 6.2, 9, body, "SmoothPlastic")
	r:block(-2.85, 0.7, -9.1, 2.85, 1.5, 9.1, band, "SmoothPlastic")
	r:block(-2.9, 3.2, -8.6, 2.9, 5.2, 8.2, GLASS, "Glass")
	for z = -7, 7, 3.5 do
		r:block(-2.95, 3.2, z - 0.15, 2.95, 5.2, z + 0.15, body, "SmoothPlastic")
	end
	r:block(-2.6, 2, 9, 2.6, 5.4, 9.15, GLASS, "Glass")
	r:block(-1.6, 5.5, 9.05, 1.6, 6.1, 9.2, Color3.fromRGB(40, 40, 50), "SmoothPlastic")
	r:block(-1.4, 5.6, 9.2, 1.4, 6, 9.25, C.Warm, "Neon")
	r:block(-2.9, 6.2, -9.1, 2.9, 6.5, 9.1, band, "SmoothPlastic")
	for _, x in { -1.9, 1.9 } do
		r:glow(r:block(x - 0.5, 1.6, 9.1, x + 0.5, 2.2, 9.25, C.Warm, "Neon"), 0)
		r:block(x - 0.5, 1.6, -9.25, x + 0.5, 2.2, -9.1, C.Red, "Neon")
	end
	for _, x in { -2.7, 2.7 } do
		for _, z in { -6, 6 } do
			wheel(r, x, z, 2)
		end
	end
end

-- Small creatures (the user: "small creatures", and later "remove the butterflies and bunnies":
-- the ducks are what is left). Each faces +Z at the origin, feet on y = 0.

-- A duck that sits on the water: a body, a head, an orange beak and a little tail.
local function duck(r: R)
	r:lump(CFrame.new(0, 0.4, 0), 1.2, 0.9, 1.7, r.c1)
	r:ball(0, 1.05, 0.7, 0.8, r.c2, "SmoothPlastic")
	r:block(-0.15, 0.95, 1.05, 0.15, 1.1, 1.4, Color3.fromRGB(250, 160, 60), "SmoothPlastic")
	r:block(-0.2, 0.5, -1.1, 0.2, 0.9, -0.75, r.c1, "SmoothPlastic")
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
	}
	for _, e in list do
		for _, p in AmbientModels.prims(e.name, e.c1, e.c2) do
			p.cf = CFrame.new(x, 0, 0) * p.cf
			table.insert(out, p)
		end
		x += if e.name == "bus" then 16 else 9
	end
	return out
end

return AmbientModels
