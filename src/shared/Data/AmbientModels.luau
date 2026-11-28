--!strict
-- The things that move around town but aren't anyone's to build: cars, the bus and the ducks.
-- Drawn with the Recipe API like everything else, each facing +Z at the origin. The client's
-- Ambience moves them; the parts named Wheel turn as they go.
--
-- The user asked for detail "similar to the default house everywhere", then "make cars and
-- vechicles more detailed": the cars and the bus are drawn with Data/VehicleKit, the kit the
-- vehicles players buy are drawn with (round wheels with spokes, rounded bodies, curved arches,
-- framed windows, lamps, grilles, bumpers with blank plates, mirrors). They are plain parts, not
-- pieces: the client moves every part of a car each frame and makes a piece's shapes as parts
-- anyway. The car park in Data/DetailModels parks the lighter `parked` car, as the town's budget
-- counts it.

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

local Kit = require(script.Parent.VehicleKit)

local function darker(c: Color3, k: number): Color3
	return Color3.new(c.R * k, c.G * k, c.B * k)
end

-- The town's cars are drawn with the kit the bought ones are (Data/VehicleKit: the user, "make cars
-- and vechicles more detailed"), front toward -Z in its own space; here they are turned to face +Z
-- with their wheels on the ground at y 0.
local function onGround(r: R, wheel: number, draw: (R) -> ())
	Kit.at(r, CFrame.new(0, wheel, 0) * CFrame.Angles(0, math.pi, 0), draw)
end

-- A small town car in c1: a rounded body with a sloping bonnet, a boot, two doors a side, its glass
-- framed by pillars with a seal along its foot, round lamps, a grille, bumpers with blank plates,
-- mirrors, and wheels with spokes under curved arches. The traffic's (`seats`) has seats and a
-- steering wheel inside and its wheels named Wheel, so Ambience turns them; a parked one keeps to
-- fewer parts, since the town's budget counts it.
local function townCar(r: R, traffic: boolean)
	onGround(r, 0.8, function(q: R)
		local front = { Vector3.new(-0.95, 0.5, -0.4), Vector3.new(0.95, 0.5, -0.4) }
		Kit.car(q, {
			len = 9.2,
			wid = 4.5,
			R = 0.8,
			tw = 0.7,
			fa = -2.9,
			ra = 2.9,
			sill = -0.25,
			belt = 1.3,
			hood = if traffic then 0.95 else nil,
			roof = 3.15,
			lite = true,
			ws = { -1.7, -0.65 },
			bw = { 1.9, 2.9 },
			rad = 0.35,
			doors = { { -1.5, 0.35 }, { 0.5, 2.35 } },
			posts = { 0.42 },
			roofPaint = darker(q.c1, 0.96),
			spokes = if traffic then 3 else 2,
			arches = if traffic then 6 else 4,
			seats = if traffic then front else nil,
			inside = if traffic then "simple" else nil,
			wheelName = if traffic then "Wheel" else nil,
		})
	end)
end

local function car(r: R)
	townCar(r, true)
end

local function parked(r: R)
	townCar(r, false)
end

-- The town bus: long and two-tone, a row of windows with pillars between them, folding doors in
-- the middle of the kerb side (local -X), a lit sign over the windscreen, mirrors on long arms,
-- vents on the roof, bumpers, lights and wheels under arches.
local function bus(r: R)
	local body = Color3.fromRGB(232, 192, 104)
	local band = Color3.fromRGB(88, 134, 184)
	local q0 = Recipe.new(body, band)
	onGround(q0, 1.0, function(q: R)
		local m = Kit.car(q, {
			len = 18,
			wid = 5.6,
			R = 1.0,
			tw = 0.8,
			fa = -6.2,
			ra = 6.0,
			sill = -0.2,
			belt = 2.2,
			roof = 5.4,
			ws = { -8.75, -8.45 },
			bw = { 8.85, 8.95 },
			inset = 0.18,
			rad = 0.45,
			posts = { -5.6, -2.6, 3.4, 6.2 },
			roofPaint = Color3.fromRGB(246, 242, 232),
			bumper = Kit.TRIM,
			lamps = "wide",
			spokes = 0,
			wheelName = "Wheel",
		})
		-- a blue band along its foot, the folding doors on the kerb side between the axles
		for _, sx in { -1, 1 } do
			q:block(
				sx * m.hw - sx * 0.02,
				0.0,
				m.nose + 0.5,
				sx * m.hw + sx * 0.035,
				0.7,
				m.tail - 0.5,
				band,
				Kit.Paint
			)
		end
		q:block(m.hw - 0.02, 0.0, -1.5, m.hw + 0.1, 4.9, 1.5, Kit.TRIM, "Rubber")
		for _, z in { -0.72, 0.72 } do
			q:block(m.hw + 0.1, 0.2, z - 0.62, m.hw + 0.14, 4.7, z + 0.62, Kit.GLASS, "Glass").transp = 0.3
		end
		-- the sign over the windscreen, the mirrors on their arms, vents on the roof
		q:block(-1.7, 4.45, m.nose + 0.25, 1.7, 5.05, m.nose + 0.42, Kit.TRIM, "Rubber")
		q:block(-1.55, 4.52, m.nose + 0.2, 1.55, 4.98, m.nose + 0.26, Recipe.Colors.Warm, "Neon")
		for _, sx in { -1, 1 } do
			q:beam(
				Vector3.new(sx * (m.hw - 0.1), 5.0, m.nose + 0.4),
				Vector3.new(sx * (m.hw + 0.45), 4.8, m.nose - 0.15),
				0.1,
				0.1,
				Kit.TRIM,
				"Rubber"
			)
			Kit.roundBox(
				q,
				sx * (m.hw + 0.45) - 0.18,
				3.9,
				m.nose - 0.35,
				sx * (m.hw + 0.45) + 0.18,
				4.8,
				m.nose + 0.02,
				0.08,
				body
			)
		end
		for _, z in { -3.5, 4 } do
			Kit.roundBox(q, -0.9, 5.35, z - 0.9, 0.9, 5.65, z + 0.9, 0.12, Color3.fromRGB(210, 206, 196))
		end
	end)
	for _, p in q0.prims do
		r:add(p)
	end
end

-- Small creatures (the user: "small creatures", and later "remove the butterflies and bunnies":
-- the ducks are what is left). Each faces +Z at the origin, feet on y = 0.

-- A duck that sits on the water: a body with its wings folded along it, a tail turned up, a head
-- with a white ring at the neck, two eyes and an orange beak.
local function duck(r: R)
	r:lump(CFrame.new(0, 0.4, 0), 1.2, 0.9, 1.7, r.c1)
	for _, sx in { -1, 1 } do
		r:lump(
			CFrame.new(sx * 0.47, 0.56, -0.15) * CFrame.Angles(0.15, sx * 0.12, 0),
			0.34,
			0.5,
			1.2,
			darker(r.c1, 0.82)
		)
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
	parked = parked,
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
