--!strict
-- The small things that make the island look lived in: street furniture for the sidewalks,
-- pocket plazas and gardens for the gaps between buildings, and props for the hills, the beach
-- and the sea. The user: "detail the entire map more". None of them is a tree: trees keep to the
-- parks, the hills and the beach (the user: "remove the trees near the road").
--
-- Each is a recipe drawn round its own middle, front facing local -Z, a handful of parts each so
-- there can be a lot of them.

local Recipe = require(script.Parent.Parent.Build.Recipe)

type R = Recipe.Recipe

local DetailModels = {}
DetailModels.Models = {} :: { [string]: (R) -> () }
local M = DetailModels.Models

local function rgb(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end

local function shade(c: Color3, k: number): Color3
	return Color3.new(math.min(1, c.R * k), math.min(1, c.G * k), math.min(1, c.B * k))
end

local WHITE = rgb(250, 246, 236)
local STONE = rgb(226, 222, 214)
local ROCK = rgb(150, 152, 160)
local SOIL = rgb(118, 88, 64)
local LEAF = rgb(84, 176, 74)
local HEDGE = rgb(72, 138, 78)
local WOOD = rgb(196, 154, 108)
local WOOD_DARK = rgb(154, 107, 72)
local METAL = rgb(186, 192, 202)
local DARK = rgb(64, 70, 86)
local GLASS = rgb(150, 206, 240)
local WATER = rgb(84, 168, 236)
local LAWN = rgb(132, 190, 106)
local ASPHALT = rgb(104, 108, 120)
local RED = rgb(214, 108, 98)
local BLUE = rgb(96, 140, 190)
local YELLOW = rgb(236, 198, 110)
local TEAL = rgb(88, 164, 156)
local PINK = rgb(240, 158, 176)
local BLOOMS = { rgb(240, 148, 164), rgb(240, 206, 118), rgb(250, 246, 236), rgb(184, 160, 222), rgb(236, 156, 110) }

-- Small pieces drawn at an offset, so the pockets below can share them -------------------------------

local function bench(r: R, x: number, z: number, yaw: number)
	local f = CFrame.new(x, 0, z) * CFrame.Angles(0, math.rad(yaw), 0)
	r:boxAt(f * CFrame.new(0, 1.2, 0), 4, 0.3, 1.4, WOOD, "Wood")
	r:boxAt(f * CFrame.new(0, 2, 0.6), 4, 1.2, 0.25, WOOD, "Wood")
	for _, sx in { -1.6, 1.6 } do
		r:boxAt(f * CFrame.new(sx, 0.55, 0), 0.3, 1.1, 1.2, DARK, "Metal")
	end
end

-- A stone trough of flowers, `along` "x" or "z".
local function planter(r: R, x: number, y: number, z: number, along: string, first: number)
	local hx, hz = if along == "x" then 3 else 0.9, if along == "x" then 0.9 else 3
	r:block(x - hx, y, z - hz, x + hx, y + 1.3, z + hz, STONE, "Concrete")
	r:block(x - hx + 0.3, y + 1.3, z - hz + 0.3, x + hx - 0.3, y + 1.45, z + hz - 0.3, SOIL, "Ground")
	for k = 0, 3 do
		local o = -2.1 + k * 1.4
		local px, pz = if along == "x" then x + o else x, if along == "x" then z else z + o
		r:ball(px, y + 1.9, pz, 1.3, BLOOMS[(first + k) % #BLOOMS + 1], "SmoothPlastic")
	end
end

-- A clipped shrub in a clay pot.
local function shrub(r: R, x: number, y: number, z: number)
	r:cyl(x, y + 0.8, z, 1.6, 2.2, "y", rgb(190, 130, 104), "SmoothPlastic")
	r:ball(x, y + 2.6, z, 3, LEAF, "SmoothPlastic").name = "Leaf"
	r:ball(x + 0.7, y + 3.4, z - 0.4, 1.8, shade(LEAF, 1.15), "SmoothPlastic").name = "Leaf"
end

-- A round table under a parasol, with two stools.
local function cafe(r: R, x: number, y: number, z: number, top: Color3)
	r:cyl(x, y + 1.3, z, 2.6, 0.3, "y", DARK, "Metal")
	r:cyl(x, y + 2.7, z, 0.25, 3.4, "y", WHITE, "SmoothPlastic")
	r:cyl(x, y + 5.2, z, 4.8, 0.2, "y", WOOD_DARK, "Wood")
	r:cyl(x, y + 7.5, z, 0.5, 7.4, "y", top, "Fabric")
	r:cyl(x, y + 8, z, 0.5, 4, "y", shade(top, 1.12), "Fabric")
	for _, sx in { -1, 1 } do
		r:cyl(x + sx * 2.7, y + 0.9, z, 1.8, 1.2, "y", WOOD, "Wood")
	end
end

-- A lamp on a short post, lit at night.
local function lamp(r: R, x: number, y: number, z: number)
	r:cyl(x, y + 2.6, z, 5.2, 0.4, "y", DARK, "Metal")
	r:glow(r:ball(x, y + 5.6, z, 1.3, rgb(255, 236, 190), "SmoothPlastic"), 14, 1)
end

-- A low hedge between two points on the same line.
local function hedge(r: R, x1: number, z1: number, x2: number, z2: number, y: number?)
	local base = y or 0
	r:block(
		math.min(x1, x2),
		base,
		math.min(z1, z2),
		math.max(x1, x2),
		base + 2,
		math.max(z1, z2),
		HEDGE,
		"SmoothPlastic"
	)
end

local function flowers(r: R, x: number, y: number, z: number, n: number, first: number)
	for k = 0, n - 1 do
		local a = k * 2.4
		r:ball(
			x + math.cos(a) * (0.8 + k * 0.35),
			y + 0.45,
			z + math.sin(a) * (0.8 + k * 0.35),
			1,
			BLOOMS[(first + k) % #BLOOMS + 1],
			"SmoothPlastic"
		)
	end
end

local function car(r: R, x: number, y: number, z: number, yaw: number, col: Color3)
	local f = CFrame.new(x, y, z) * CFrame.Angles(0, math.rad(yaw), 0)
	r:boxAt(f * CFrame.new(0, 1.5, 0), 4.2, 1.5, 9, col, "SmoothPlastic")
	r:boxAt(f * CFrame.new(0, 2.9, 0.4), 3.8, 1.4, 4.8, shade(col, 1.08), "SmoothPlastic")
	r:boxAt(f * CFrame.new(0, 2.95, 0.4), 3.86, 1, 4.2, GLASS, "Glass")
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			r:boxAt(f * CFrame.new(sx * 2, 0.8, sz * 2.8), 0.5, 1.6, 1.6, DARK, "SmoothPlastic")
		end
	end
end

-- Street furniture ----------------------------------------------------------------------------------

M.planterBox = function(r: R)
	planter(r, 0, 0, 0, "x", 0)
end

M.planterBox2 = function(r: R)
	planter(r, 0, 0, 0, "x", 2)
end

M.shrubPot = function(r: R)
	shrub(r, 0, 0, 0)
end

-- A rack with two bikes leaning in it.
M.bikeRack = function(r: R)
	for _, x in { -2.2, 0, 2.2 } do
		r:block(x - 0.08, 0, -0.9, x + 0.08, 1.7, 0.9, METAL, "Metal")
	end
	for i, x in { -1.1, 1.1 } do
		local col = if i == 1 then RED else BLUE
		r:cyl(x, 1.1, -1.5, 0.16, 2.2, "x", DARK, "SmoothPlastic")
		r:cyl(x, 1.1, 1.3, 0.16, 2.2, "x", DARK, "SmoothPlastic")
		r:block(x - 0.1, 1.7, -1.5, x + 0.1, 2, 1.3, col, "Metal")
		r:block(x - 0.25, 2.3, 0.4, x + 0.25, 2.5, 1.2, DARK, "SmoothPlastic")
	end
end

M.mailbox = function(r: R)
	r:block(-0.25, 0, -0.25, 0.25, 2.4, 0.25, DARK, "Metal")
	r:block(-0.9, 2.4, -0.7, 0.9, 3.9, 0.7, BLUE, "Metal")
	r:cyl(0, 3.9, 0, 1.8, 1.4, "x", BLUE, "Metal")
	r:block(-0.6, 3.3, -0.76, 0.6, 3.5, -0.7, DARK, "SmoothPlastic")
end

-- Traffic lights: a pole on the corner with an arm out over the road (local -Z).
M.trafficLight = function(r: R)
	r:cyl(0, 5.6, 0, 11.2, 0.5, "y", DARK, "Metal")
	r:block(-0.2, 10.5, -7, 0.2, 10.9, 0, DARK, "Metal")
	r:block(-0.7, 8.3, -7.6, 0.7, 11.3, -6.6, rgb(50, 54, 66), "Metal")
	-- (the client changes the lights: red, green, amber, turn about with the other road's)
	r:ball(0, 10.6, -7.66, 0.7, rgb(240, 80, 70), "SmoothPlastic").name = "Red"
	r:ball(0, 9.8, -7.66, 0.7, rgb(250, 200, 80), "SmoothPlastic").name = "Amber"
	r:ball(0, 9, -7.66, 0.7, rgb(90, 220, 120), "SmoothPlastic").name = "Green"
end

-- A kiosk selling papers and snacks under a striped awning.
M.kiosk = function(r: R)
	r:block(-4, 0, -3, 4, 0.3, 3, STONE, "Concrete")
	r:block(-3.6, 0.3, -1.6, 3.6, 7, 2.6, rgb(240, 220, 170), "Plaster")
	r:glow(r:block(-3, 3, -1.75, 3, 5.6, -1.6, rgb(120, 90, 70), "SmoothPlastic"), 0).attrs =
		{ NightColor = rgb(255, 224, 156) }
	r:block(-3.3, 2.6, -2.6, 3.3, 3, -1.6, WOOD, "Wood")
	for k = 0, 3 do
		local x = -2.85 + k * 1.9
		r:boxAt(
			CFrame.new(x, 6.3, -2.9) * CFrame.Angles(math.rad(20), 0, 0),
			1.9,
			0.2,
			2.9,
			if k % 2 == 0 then RED else WHITE,
			"Fabric"
		)
	end
	r:block(-3.8, 7, -1.8, 3.8, 7.5, 2.8, RED, "SmoothPlastic")
	r:block(-2.4, 7.5, -1.7, 2.4, 8.9, -1.4, WHITE, "SmoothPlastic")
	r:block(-2.6, 3, -2.4, -1.4, 3.5, -1.8, WHITE, "SmoothPlastic")
	r:ball(1.8, 3.4, -2.1, 0.8, rgb(255, 150, 60), "SmoothPlastic")
end

M.cafeLite = function(r: R)
	cafe(r, 0, 0, 0, RED)
end

M.cafeLite2 = function(r: R)
	cafe(r, 0, 0, 0, TEAL)
end

-- A food truck with its hatch open (the hatch faces local -Z).
local function truck(r: R, x: number, z: number, body: Color3)
	r:block(x - 6, 1.2, z - 3, x + 4, 8, z + 3, body, "SmoothPlastic")
	r:block(x + 4, 1.2, z - 2.8, x + 7.6, 5.4, z + 2.8, WHITE, "SmoothPlastic")
	r:block(x + 5.4, 3.4, z - 2.86, x + 7.66, 5.2, z + 2.86, GLASS, "Glass")
	r:block(x - 4.6, 4, z - 3.1, x + 2.4, 6.6, z - 3, rgb(84, 66, 62), "SmoothPlastic")
	r:boxAt(CFrame.new(x - 1.1, 7.3, z - 4.3) * CFrame.Angles(math.rad(-14), 0, 0), 7.4, 0.2, 2.8, WHITE, "Fabric")
	r:block(x - 4.8, 3.6, z - 3.9, x + 2.6, 4, z - 3, WOOD, "Wood")
	for _, wx in { -3.6, 5 } do
		r:cyl(x + wx, 1.1, z, 6.4, 2.2, "z", DARK, "SmoothPlastic")
	end
	r:block(x - 6.04, 2.6, z - 3.04, x + 4.04, 3.2, z + 3.04, WHITE, "SmoothPlastic")
	r:cyl(x - 2, 8.5, z, 1, 1.4, "y", METAL, "Metal")
end

M.foodTruck = function(r: R)
	truck(r, 0, 0, PINK)
end

M.foodTruck2 = function(r: R)
	truck(r, 0, 0, TEAL)
end

-- A statue on a stepped plinth.
local function statue(r: R, x: number, y: number, z: number)
	local bronze = rgb(110, 164, 144)
	r:block(x - 3, y, z - 3, x + 3, y + 0.6, z + 3, STONE, "Concrete")
	r:block(x - 2, y + 0.6, z - 2, x + 2, y + 3.4, z + 2, shade(STONE, 0.94), "Concrete")
	r:cyl(x, y + 5.6, z, 4.4, 1.8, "y", bronze, "Metal")
	r:ball(x, y + 8.5, z, 1.8, bronze, "Metal")
	r:boxAt(CFrame.new(x + 1.3, y + 7, z) * CFrame.Angles(0, 0, math.rad(-50)), 0.6, 2.8, 0.6, bronze, "Metal")
	r:block(x - 1.2, y + 1.6, z - 2.06, x + 1.2, y + 2.4, z - 2, rgb(214, 180, 90), "Metal")
end

M.statue = function(r: R)
	statue(r, 0, 0, 0)
end

-- A small round fountain.
local function fountain(r: R, x: number, y: number, z: number)
	r:cyl(x, y + 0.6, z, 1.2, 12, "y", STONE, "Concrete")
	r:cyl(x, y + 1.05, z, 0.4, 10.4, "y", WATER, "SmoothPlastic")
	r:cyl(x, y + 2, z, 2.8, 1.4, "y", STONE, "Concrete")
	r:cyl(x, y + 3.5, z, 0.5, 4.4, "y", STONE, "Concrete")
	r:cyl(x, y + 3.85, z, 0.3, 3.6, "y", WATER, "SmoothPlastic")
	local jet = r:cyl(x, y + 5, z, 2, 0.5, "y", rgb(214, 240, 255), "Glass")
	jet.transp = 0.35
	jet.collide = false
	jet.name = "Jet" -- the client sprays water from it
end

M.fountainSmall = function(r: R)
	fountain(r, 0, 0, 0)
end

-- A billboard on two legs: a sunny picture and two lines of writing.
M.billboard = function(r: R)
	for _, x in { -5, 5 } do
		r:block(x - 0.3, 0, -0.3, x + 0.3, 9, 0.3, DARK, "Metal")
	end
	r:block(-8, 9, -0.4, 8, 17, 0.4, WHITE, "SmoothPlastic")
	r:block(-7.4, 9.6, -0.5, 7.4, 16.4, -0.4, rgb(140, 206, 250), "SmoothPlastic")
	r:cyl(-3.6, 13, -0.52, 0.1, 4.4, "z", YELLOW, "SmoothPlastic")
	r:block(0.4, 13.4, -0.56, 6.4, 14.4, -0.5, WHITE, "SmoothPlastic")
	r:block(0.4, 11.4, -0.56, 4.6, 12.4, -0.5, WHITE, "SmoothPlastic")
end

-- A clipped hedge 16 long with flowers along the top.
M.hedgeRow = function(r: R)
	r:block(-8, 0, -0.9, 8, 2.2, 0.9, HEDGE, "SmoothPlastic")
	for k = 0, 2 do
		r:ball(-5 + k * 5, 2.3, 0, 1.1, BLOOMS[k + 1], "SmoothPlastic")
	end
end

-- A strip of flower bed 12 long.
M.flowerStrip = function(r: R)
	r:block(-6, 0, -1.1, 6, 0.3, 1.1, SOIL, "Ground")
	for k = 0, 6 do
		r:ball(-5 + k * 1.66, 0.7, (k % 2 - 0.5) * 0.7, 1.1, BLOOMS[k % #BLOOMS + 1], "SmoothPlastic")
	end
end

-- A manhole cover, flat on the road.
M.manhole = function(r: R)
	r:cyl(0, 0.03, 0, 0.06, 3, "y", rgb(84, 88, 100), "Metal")
	r:cyl(0, 0.05, 0, 0.06, 2.2, "y", rgb(104, 108, 120), "Metal")
end

-- Pockets: little places for the gaps between buildings, each inside a 32 by 32 square -----------------

-- A terrace: a kiosk, three tables under parasols and troughs of flowers.
M.pocketCafe = function(r: R)
	r:block(-15, 0, -15, 15, 0.12, 15, rgb(236, 214, 190), "Pavement")
	local k = Recipe.new(WHITE, WHITE)
	M.kiosk(k)
	for _, p in k.prims do
		p.cf = CFrame.new(0, 0.12, 9) * p.cf
		r:add(p)
	end
	cafe(r, -8, 0.12, -4, RED)
	cafe(r, 8, 0.12, -4, TEAL)
	cafe(r, 0, 0.12, -10, YELLOW)
	planter(r, -13, 0.12, 6, "z", 0)
	planter(r, 13, 0.12, 6, "z", 2)
	lamp(r, -13, 0.12, -13)
	lamp(r, 13, 0.12, -13)
end

-- A pocket garden: a lawn in a low hedge, flower beds, a path through and two benches.
M.pocketGarden = function(r: R)
	r:block(-15, 0, -15, 15, 0.2, 15, LAWN, "Grass")
	r:block(-2, 0.2, -15, 2, 0.26, 15, rgb(232, 226, 214), "Pavement")
	for _, sx in { -1, 1 } do
		hedge(r, sx * 15, -15, sx * 13.6, 15, 0.2)
		hedge(r, sx * 3.4, 13.6, sx * 13.6, 15, 0.2)
		hedge(r, sx * 3.4, -15, sx * 13.6, -13.6, 0.2)
		r:block(sx * 5, 0.2, -4, sx * 11, 0.45, 4, SOIL, "Ground")
		flowers(r, sx * 8, 0.4, -1.6, 5, if sx > 0 then 0 else 2)
		flowers(r, sx * 8, 0.4, 2, 4, if sx > 0 then 3 else 1)
		bench(r, sx * 3.6, sx * 9, sx * -90)
		r:ball(sx * 10.5, 1.9, -10, 4, LEAF, "SmoothPlastic")
		r:ball(sx * 10.5, 1.6, 10, 3.4, shade(LEAF, 1.12), "SmoothPlastic")
	end
	lamp(r, 3.2, 0.2, 0)
end

-- A round fountain with benches and potted shrubs round it.
M.pocketFountain = function(r: R)
	r:cyl(0, 0.06, 0, 0.12, 30, "y", rgb(232, 226, 214), "Pavement")
	fountain(r, 0, 0.12, 0)
	for k = 0, 3 do
		local a = math.rad(45 + k * 90)
		local x, z = math.cos(a) * 11.5, math.sin(a) * 11.5
		shrub(r, x, 0.12, z)
	end
	bench(r, 0, -10.5, 180)
	bench(r, 0, 10.5, 0)
	bench(r, -10.5, 0, 90)
	bench(r, 10.5, 0, -90)
	lamp(r, -13, 0.12, 0.1)
	lamp(r, 13, 0.12, 0.1)
end

-- A statue in a ring of flowers.
M.pocketStatue = function(r: R)
	r:cyl(0, 0.06, 0, 0.12, 28, "y", rgb(232, 226, 214), "Pavement")
	r:cyl(0, 0.2, 0, 0.3, 14, "y", SOIL, "Ground")
	statue(r, 0, 0.3, 0)
	for k = 0, 9 do
		local a = math.rad(k * 36)
		r:ball(math.cos(a) * 5.4, 0.8, math.sin(a) * 5.4, 1.3, BLOOMS[k % #BLOOMS + 1], "SmoothPlastic")
	end
	bench(r, -10, -8, 135)
	bench(r, 10, -8, -135)
	lamp(r, -11, 0.12, 8)
	lamp(r, 11, 0.12, 8)
end

-- Two food trucks, tables, a bin and bunting between two posts.
M.pocketTrucks = function(r: R)
	r:block(-15, 0, -15, 15, 0.1, 15, ASPHALT, "Asphalt")
	truck(r, -6.5, 10, PINK)
	truck(r, 7, 3, TEAL)
	cafe(r, -9, 0.1, -3, YELLOW)
	cafe(r, 1, 0.1, -9, RED)
	cafe(r, 10, 0.1, -9, TEAL)
	for _, x in { -14, 14 } do
		r:block(x - 0.2, 0, -14.2, x + 0.2, 7, -13.8, DARK, "Metal")
	end
	r:block(-14, 6.6, -14.05, 14, 6.7, -13.95, DARK, "SmoothPlastic")
	for k = 0, 8 do
		local col = ({ RED, YELLOW, BLUE })[k % 3 + 1]
		r:block(-12.6 + k * 3.1, 5.7, -14.08, -11.4 + k * 3.1, 6.6, -13.92, col, "Fabric")
	end
end

-- A small car park: eight bays and three cars.
M.pocketParking = function(r: R)
	r:block(-15, 0, -15, 15, 0.1, 15, ASPHALT, "Asphalt")
	for k = 0, 4 do
		local x = -12 + k * 6
		r:block(x - 0.12, 0.1, -14, x + 0.12, 0.14, -5, WHITE, "SmoothPlastic")
		r:block(x - 0.12, 0.1, 5, x + 0.12, 0.14, 14, WHITE, "SmoothPlastic")
	end
	car(r, -9, 0.1, -9.5, 0, RED)
	car(r, 3, 0.1, -9.5, 0, rgb(246, 242, 232))
	car(r, -3, 0.1, 9.5, 180, BLUE)
	car(r, 9, 0.1, 9.5, 180, YELLOW)
	lamp(r, -14, 0.1, 0)
	lamp(r, 14, 0.1, 0)
end

-- Picnic tables on a lawn, with a barbecue.
local function picnic(r: R, x: number, y: number, z: number, yaw: number)
	local f = CFrame.new(x, y, z) * CFrame.Angles(0, math.rad(yaw), 0)
	r:boxAt(f * CFrame.new(0, 2.4, 0), 6, 0.3, 2.6, WOOD, "Wood")
	for _, sz in { -1, 1 } do
		r:boxAt(f * CFrame.new(0, 1.3, sz * 2.3), 6, 0.25, 1.1, WOOD, "Wood")
	end
	for _, sx in { -1, 1 } do
		r:boxAt(f * CFrame.new(sx * 2.4, 1.2, 0), 0.3, 2.4, 5.4, WOOD_DARK, "Wood")
	end
end

M.picnicTable = function(r: R)
	picnic(r, 0, 0, 0, 0)
end

M.pocketPicnic = function(r: R)
	r:block(-15, 0, -15, 15, 0.2, 15, LAWN, "Grass")
	picnic(r, -7, 0.2, -6, 20)
	picnic(r, 7, 0.2, 5, -15)
	-- the barbecue, and a blanket with a basket
	r:block(-9.6, 0.2, 7.4, -7.4, 2.2, 9, DARK, "Metal")
	r:block(-9.8, 2.2, 7.2, -7.2, 2.5, 9.2, rgb(90, 94, 106), "Metal")
	r:block(4, 0.2, -12, 11, 0.3, -7, RED, "Fabric")
	r:block(5, 0.3, -11, 6.6, 1.3, -9.6, WOOD_DARK, "Wood")
	flowers(r, -11, 0.2, -11, 5, 0)
	flowers(r, 11, 0.2, 11, 5, 2)
	r:ball(12, 1.8, -12, 3.6, LEAF, "SmoothPlastic")
	r:ball(-12, 1.6, 12, 3.2, shade(LEAF, 1.12), "SmoothPlastic")
end

-- An allotment: four vegetable beds, a shed and a water butt.
M.pocketAllotment = function(r: R)
	r:block(-15, 0, -15, 15, 0.2, 15, LAWN, "Grass")
	local crops = { rgb(120, 176, 96), rgb(226, 156, 104), rgb(206, 104, 98), rgb(164, 196, 110) }
	for i, p in { { -8, -7 }, { 2, -7 }, { -8, 3 }, { 2, 3 } } do
		r:block(p[1] - 4, 0.2, p[2] - 3, p[1] + 4, 0.7, p[2] + 3, WOOD_DARK, "Wood")
		r:block(p[1] - 3.6, 0.7, p[2] - 2.6, p[1] + 3.6, 0.8, p[2] + 2.6, SOIL, "Ground")
		for k = 0, 2 do
			r:ball(p[1] - 2.4 + k * 2.4, 1.2, p[2], 1.4, crops[i], "SmoothPlastic")
		end
	end
	-- the shed
	r:block(8, 0.2, 6, 14, 6, 13, rgb(176, 124, 104), "WoodPlanks")
	r:block(7.6, 6, 5.6, 14.4, 6.6, 13.4, rgb(110, 84, 62), "SmoothPlastic")
	r:block(10, 0.2, 5.9, 12, 4.4, 6, rgb(110, 84, 62), "SmoothPlastic")
	r:cyl(11, 1.7, -10, 3, 2.6, "y", rgb(90, 128, 170), "SmoothPlastic")
	for _, sx in { -1, 1 } do
		hedge(r, sx * 15, -15, sx * 13.8, 15, 0.2)
	end
end

-- A little duck pond with reeds, stepping stones and a bench.
M.pocketPond = function(r: R)
	r:block(-15, 0, -15, 15, 0.2, 15, LAWN, "Grass")
	r:cyl(0, 0.24, 0, 0.1, 20, "y", STONE, "Concrete")
	r:cyl(0, 0.3, 0, 0.1, 17.6, "y", WATER, "SmoothPlastic")
	for k = 0, 4 do
		local a = math.rad(200 + k * 14)
		r:cyl(math.cos(a) * 8.2, 1.6, math.sin(a) * 8.2, 2.8, 0.3, "y", rgb(96, 150, 70), "SmoothPlastic")
	end
	r:ball(-2, 0.8, 1, 1.1, WHITE, "SmoothPlastic")
	r:ball(-2.6, 1.3, 1, 0.6, WHITE, "SmoothPlastic")
	r:ball(3, 0.8, -3, 1.1, YELLOW, "SmoothPlastic")
	for k = 0, 2 do
		r:cyl(4.5 + k * 2.6, 0.36, 4.5 + k * 2.2, 0.16, 2, "y", ROCK, "Slate")
	end
	bench(r, -11, -11, 135)
	bench(r, 11, -11, -135)
	flowers(r, 11.5, 0.2, 11.5, 5, 1)
	flowers(r, -11.5, 0.2, 11.5, 5, 3)
end

-- A small playground: swings, a slide and a sandpit.
M.pocketPlay = function(r: R)
	r:block(-15, 0, -15, 15, 0.2, 15, rgb(240, 220, 176), "Sand")
	-- swings
	for _, x in { -12, -4 } do
		r:block(x - 0.25, 0.2, -9.25, x + 0.25, 7, -8.75, RED, "Metal")
	end
	r:block(-12.2, 6.8, -9.2, -3.8, 7.2, -8.8, RED, "Metal")
	for _, x in { -10, -6 } do
		r:block(x - 0.8, 1.6, -9.4, x + 0.8, 1.8, -8.6, DARK, "SmoothPlastic")
		r:block(x - 0.06, 1.8, -9.05, x + 0.06, 6.8, -8.95, METAL, "Metal")
	end
	-- the slide
	r:block(4, 0.2, -10, 8, 5, -6, BLUE, "SmoothPlastic")
	r:ramp(4.6, 0.2, -6, 7.4, 5, 3, false, YELLOW, "SmoothPlastic")
	-- the sandpit and a roundabout
	r:block(-12, 0.2, 2, -3, 0.8, 11, WOOD, "Wood")
	r:block(-11.4, 0.8, 2.6, -3.6, 0.9, 10.4, rgb(255, 236, 190), "Sand")
	r:ball(-8, 1.3, 6, 1.4, RED, "SmoothPlastic")
	r:cyl(8, 0.7, 9, 0.5, 7, "y", TEAL, "SmoothPlastic")
	r:cyl(8, 1.6, 9, 2, 0.5, "y", DARK, "Metal")
	bench(r, 0, 13, 0)
end

-- The hills -------------------------------------------------------------------------------------------

M.boulder = function(r: R)
	r:lump(CFrame.new(0, 1.5, 0) * CFrame.Angles(0.2, 0.5, 0.15), 5.4, 3.8, 4.6, ROCK, "Slate")
	r:lump(CFrame.new(2.6, 0.9, 1.7) * CFrame.Angles(-0.2, 1.1, 0.3), 3, 2.2, 2.6, shade(ROCK, 1.1), "Slate")
	r:lump(CFrame.new(-2.3, 0.7, -1.5) * CFrame.Angles(0.3, 0.2, -0.2), 2.4, 1.7, 2.2, shade(ROCK, 0.9), "Slate")
end

M.boulderBig = function(r: R)
	r:lump(CFrame.new(0, 3, 0) * CFrame.Angles(0.15, 0.7, 0.1), 10, 7.4, 8.6, ROCK, "Slate")
	r:lump(CFrame.new(4.8, 1.6, 2.8) * CFrame.Angles(-0.2, 0.3, 0.3), 5.4, 3.8, 4.8, shade(ROCK, 1.1), "Slate")
	r:lump(CFrame.new(-4.2, 1.2, -3.2) * CFrame.Angles(0.25, 1.2, -0.15), 4.4, 3, 4, shade(ROCK, 0.9), "Slate")
	r:lump(CFrame.new(1, 6.2, -1) * CFrame.Angles(0.1, 0.4, 0), 3.4, 1.4, 3, rgb(120, 180, 90))
end

M.log = function(r: R)
	r:cyl(0, 0.9, 0, 8, 1.8, "x", WOOD_DARK, "Wood")
	r:cyl(4.02, 0.9, 0, 0.1, 1.5, "x", rgb(226, 190, 140), "Wood")
	r:cyl(-5.4, 0.7, 2, 1.4, 2, "y", WOOD_DARK, "Wood")
end

-- A signpost with two fingers.
M.signpost = function(r: R)
	r:cyl(0, 3.2, 0, 6.4, 0.5, "y", WOOD_DARK, "Wood")
	r:block(0, 5, -0.15, 4, 6, 0.15, WOOD, "Wood")
	r:block(-3.6, 3.7, -0.15, 0, 4.6, 0.15, WOOD, "Wood")
end

M.hayBale = function(r: R)
	r:cyl(0, 1.8, 0, 3.4, 3.6, "x", rgb(230, 206, 138), "SmoothPlastic")
	r:cyl(1.72, 1.8, 0, 0.06, 2.6, "x", rgb(210, 184, 120), "SmoothPlastic")
end

-- A length of post and rail fence, 14 long.
M.fenceRun = function(r: R)
	for _, x in { -7, 0, 7 } do
		r:block(x - 0.3, 0, -0.3, x + 0.3, 3.2, 0.3, WOOD_DARK, "Wood")
	end
	r:block(-7, 2.3, -0.12, 7, 2.8, 0.12, WOOD, "Wood")
	r:block(-7, 1.1, -0.12, 7, 1.6, 0.12, WOOD, "Wood")
end

M.wildflowers = function(r: R)
	for k = 0, 6 do
		local a = k * 2.4
		local d = 0.8 + k * 0.55
		r:ball(math.cos(a) * d, 0.5, math.sin(a) * d, 1, BLOOMS[k % #BLOOMS + 1], "SmoothPlastic")
	end
end

M.mushrooms = function(r: R)
	for i, p in { { 0, 0, 1 }, { 1.4, 0.8, 0.7 }, { -1, 1.2, 0.6 } } do
		local s = p[3]
		r:cyl(p[1], 0.6 * s, p[2], 1.2 * s, 0.5 * s, "y", WHITE, "SmoothPlastic")
		r:ball(p[1], 1.3 * s, p[2], 1.6 * s, if i == 2 then rgb(236, 160, 110) else RED, "SmoothPlastic")
	end
end

-- A mountain lake: water in a stony rim, a jetty with a rowing boat, reeds and a bench.
M.tarn = function(r: R)
	r:cyl(0, 0.1, 0, 0.3, 62, "y", rgb(196, 190, 176), "Slate")
	r:cyl(0, 0.2, 0, 0.3, 56, "y", WATER, "SmoothPlastic")
	r:cyl(6, 0.32, -4, 0.1, 30, "y", shade(WATER, 1.12), "SmoothPlastic")
	-- the jetty
	r:block(-2, 0.4, -40, 2, 1, -14, WOOD, "WoodPlanks")
	for _, z in { -36, -26, -16 } do
		for _, x in { -1.8, 1.8 } do
			r:cyl(x, 0.6, z, 2, 0.5, "y", WOOD_DARK, "Wood")
		end
	end
	-- the boat
	r:block(3, 0.5, -24, 7, 1.5, -15, rgb(214, 116, 98), "SmoothPlastic")
	r:block(3.4, 1.1, -23.6, 6.6, 1.5, -15.4, WOOD, "Wood")
	r:block(3, 1.2, -20, 7, 1.5, -19, WOOD_DARK, "Wood")
	-- reeds, lily pads and rocks on the shore
	for k = 0, 7 do
		local a = math.rad(40 + k * 12)
		r:cyl(math.cos(a) * 26, 1.8, math.sin(a) * 26, 3.4, 0.35, "y", rgb(96, 150, 70), "SmoothPlastic")
	end
	for _, p in { { -10, 8 }, { -14, 2 }, { 12, 14 }, { 16, -8 } } do
		r:cyl(p[1], 0.38, p[2], 0.08, 3, "y", rgb(96, 180, 90), "SmoothPlastic")
	end
	r:ball(-13.4, 0.7, 2.4, 0.9, PINK, "SmoothPlastic")
	r:lump(CFrame.new(-28, 1.2, -14) * CFrame.Angles(0.2, 0.4, 0.1), 5.6, 3.4, 4.4, ROCK, "Slate")
	r:lump(CFrame.new(26, 1, -18) * CFrame.Angles(-0.1, 1, 0.2), 4.4, 2.8, 3.8, shade(ROCK, 1.1), "Slate")
	bench(r, -8, -34, 180)
end

-- A ring of old standing stones on a hilltop meadow, with a flat one in the middle.
M.stoneCircle = function(r: R)
	for k = 0, 8 do
		local a = math.rad(k * 40)
		local x, z = math.cos(a) * 20, math.sin(a) * 20
		local h = 7 + (k * 7) % 4
		r:boxAt(
			CFrame.new(x, h / 2 - 0.3, z) * CFrame.Angles(0, -a, 0) * CFrame.Angles(0.06, 0, ((k % 3) - 1) * 0.08),
			2.2,
			h,
			3.4,
			shade(ROCK, 0.9 + (k % 3) * 0.08),
			"Slate"
		)
	end
	-- two with a stone laid across
	r:boxAt(
		CFrame.new(20 * math.cos(math.rad(20)), 9.6, 20 * math.sin(math.rad(20))) * CFrame.Angles(0, math.rad(-110), 0),
		16,
		1.6,
		3,
		ROCK,
		"Slate"
	)
	r:boxAt(CFrame.new(0, 0.6, 0) * CFrame.Angles(0, 0.4, 0), 7, 1.2, 4.6, shade(ROCK, 1.1), "Slate")
	for k = 0, 5 do
		local a = math.rad(30 + k * 60)
		r:ball(math.cos(a) * 9, 0.5, math.sin(a) * 9, 1.1, BLOOMS[k % #BLOOMS + 1], "SmoothPlastic")
	end
end

-- The beach and the sea ------------------------------------------------------------------------------

local function towel(r: R, col: Color3, stripe: Color3)
	r:block(-1.8, 0, -3.4, 1.8, 0.12, 3.4, col, "Fabric")
	r:block(-1.8, 0.12, -0.6, 1.8, 0.16, 0.6, stripe, "Fabric")
	r:ball(2.6, 0.7, -2.4, 1.4, stripe, "SmoothPlastic")
end

M.towel = function(r: R)
	towel(r, RED, WHITE)
end

M.towel2 = function(r: R)
	towel(r, TEAL, YELLOW)
end

M.sandcastle = function(r: R)
	local sand = rgb(238, 206, 150)
	r:block(-2, 0, -2, 2, 1.2, 2, sand, "Sand")
	for _, p in { { -1.6, -1.6 }, { 1.6, -1.6 }, { -1.6, 1.6 }, { 1.6, 1.6 } } do
		r:cyl(p[1], 1.1, p[2], 2.2, 1.4, "y", sand, "Sand")
	end
	r:cyl(0, 2, 0, 1.6, 1.8, "y", sand, "Sand")
	r:block(-0.06, 2.8, -0.06, 0.06, 4.4, 0.06, DARK, "Metal")
	r:block(0.06, 3.7, -0.04, 1.2, 4.4, 0.04, RED, "Fabric")
end

M.beachBall = function(r: R)
	r:ball(0, 1.1, 0, 2.2, WHITE, "SmoothPlastic")
	r:cyl(0, 1.1, 0, 0.5, 2.24, "y", RED, "SmoothPlastic")
end

-- Surfboards leaning on a rail.
M.surfRack = function(r: R)
	for _, x in { -3, 3 } do
		r:block(x - 0.2, 0, -0.2, x + 0.2, 3.6, 0.2, WOOD_DARK, "Wood")
	end
	r:block(-3, 3.2, -0.15, 3, 3.5, 0.15, WOOD, "Wood")
	for i, x in { -1.8, 0, 1.8 } do
		local col = ({ YELLOW, TEAL, PINK })[i]
		r:boxAt(CFrame.new(x, 3.4, -0.9) * CFrame.Angles(math.rad(-14), 0, 0), 1.5, 7, 0.3, col, "SmoothPlastic")
	end
end

M.rowboat = function(r: R)
	r:block(-2, 0, -4.6, 2, 1.2, 4.6, BLUE, "SmoothPlastic")
	r:block(-1.6, 0.6, -4.2, 1.6, 1.2, 4.2, WOOD, "Wood")
	r:block(-2, 0.9, -0.6, 2, 1.2, 0.6, WOOD_DARK, "Wood")
	r:boxAt(CFrame.new(2.6, 0.9, 1) * CFrame.Angles(0, 0.3, 0.2), 0.3, 0.3, 7, WOOD_DARK, "Wood")
end

-- A volleyball net on the sand, with the court marked out.
M.volleyNet = function(r: R)
	for _, x in { -9, 9 } do
		r:cyl(x, 3.6, 0, 7.2, 0.5, "y", WHITE, "Metal")
	end
	local net = r:block(-9, 3.6, -0.06, 9, 7, 0.06, WHITE, "Fabric")
	net.transp = 0.45
	r:block(-9, 6.9, -0.1, 9, 7.1, 0.1, RED, "Fabric")
	for _, z in { -14, 14 } do
		r:block(-9, 0, z - 0.15, 9, 0.06, z + 0.15, BLUE, "Fabric")
	end
	for _, x in { -9, 9 } do
		r:block(x - 0.15, 0, -14, x + 0.15, 0.06, 14, BLUE, "Fabric")
	end
	r:ball(4, 1, 6, 2, YELLOW, "SmoothPlastic")
end

M.driftwood = function(r: R)
	r:boxAt(CFrame.new(0, 0.5, 0) * CFrame.Angles(0, 0.5, 0.05), 7, 0.9, 1, rgb(196, 176, 150), "Wood")
	r:boxAt(CFrame.new(1.6, 0.9, 1.2) * CFrame.Angles(0.2, -0.7, 0.4), 3, 0.5, 0.5, rgb(180, 160, 136), "Wood")
	r:ball(-3, 0.3, -1.6, 0.9, PINK, "SmoothPlastic")
end

-- A buoy bobbing out in the bay, with a light on top.
M.buoy = function(r: R)
	r:cyl(0, 0.4, 0, 2.4, 3.6, "y", RED, "SmoothPlastic")
	r:cyl(0, 1.8, 0, 0.5, 3.6, "y", WHITE, "SmoothPlastic")
	r:cyl(0, 3.6, 0, 3.4, 0.4, "y", DARK, "Metal")
	r:glow(r:ball(0, 5.6, 0, 1, rgb(255, 120, 100), "SmoothPlastic"), 12, 1, rgb(255, 120, 100))
end

-- A sailing boat at anchor.
local function sailboat(r: R, hull: Color3, sail: Color3)
	r:block(-3, -0.6, -8, 3, 2, 8, hull, "SmoothPlastic")
	r:block(-2.4, 2, -7.4, 2.4, 2.3, 7.4, WOOD, "WoodPlanks")
	r:wedge(CFrame.new(0, 0.7, -10.5), 6, 2.6, 5, hull, "SmoothPlastic")
	r:block(-1.6, 2.3, 1, 1.6, 4.2, 5.4, WHITE, "SmoothPlastic")
	r:cyl(0, 12, -1, 20, 0.5, "y", WOOD_DARK, "Wood")
	r:wedge(CFrame.new(0, 12.5, 3.6) * CFrame.Angles(0, 0, 0), 0.2, 17, 8.4, sail, "Fabric")
	r:wedge(CFrame.new(0, 10, -4.4) * CFrame.Angles(0, math.pi, 0), 0.2, 12, 6, shade(sail, 0.94), "Fabric")
	r:block(-0.05, 21.4, -1, 0.05, 22.6, 1, RED, "Fabric")
end

M.sailboat = function(r: R)
	sailboat(r, WHITE, WHITE)
end

M.sailboat2 = function(r: R)
	sailboat(r, rgb(84, 116, 170), rgb(255, 236, 200))
end

-- Rocks breaking the surface, with a gull on the tallest.
M.seaRocks = function(r: R)
	r:lump(CFrame.new(0, 0.6, 0) * CFrame.Angles(0.15, 0.6, 0.1), 10, 6.6, 8.6, ROCK, "Slate")
	r:lump(CFrame.new(6, -0.4, 3) * CFrame.Angles(-0.2, 0.2, 0.3), 6.6, 4.4, 5.4, shade(ROCK, 0.9), "Slate")
	r:lump(CFrame.new(-5, -0.6, -4) * CFrame.Angles(0.2, 1.2, -0.2), 5.4, 4, 4.8, shade(ROCK, 1.1), "Slate")
	r:ball(0.4, 4.2, 0.2, 1.1, WHITE, "SmoothPlastic")
	r:ball(0.9, 4.7, 0.2, 0.6, WHITE, "SmoothPlastic")
end

function DetailModels.prims(name: string): { any }?
	local build = M[name]
	if not build then
		return nil
	end
	local r = Recipe.new(WHITE, WHITE)
	build(r)
	return r.prims
end

return DetailModels
