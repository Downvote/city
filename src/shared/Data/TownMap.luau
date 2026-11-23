--!strict
-- The town's island as parts: a sunny island in a turquoise sea with a sandy beach, the street
-- with its lane lines and crosswalks, white curbs and paving, palms in planters, the square's
-- lawns, hedges and brick promenade, and the street furniture (lamps, benches, bins, hydrants,
-- a bus stop). Out at sea, little islets with palms sit on the horizon.
-- Shared and free of services, so the World service builds it and the preview tool can draw it.

local Recipe = require(script.Parent.Parent.Build.Recipe)
local Geometry = require(script.Parent.Parent.Build.Geometry)
local Town = require(script.Parent.Town)
local TownModels = require(script.Parent.TownModels)
local Rng = require(script.Parent.Parent.Util.Rng)

type R = Recipe.Recipe
type Prim = Geometry.Prim
local C = Recipe.Colors

local TownMap = {}

local L = Town.HalfLength
local HW = Town.StreetHalfWidth
local SW = Town.SidewalkWidth

local GRASS = Color3.fromRGB(122, 210, 86)
local ROAD = Color3.fromRGB(104, 110, 128)
local ROAD_EDGE = Color3.fromRGB(92, 98, 116)
local LINE_WHITE = Color3.fromRGB(250, 250, 246)
local LINE_YELLOW = Color3.fromRGB(255, 210, 70)
local CURB = Color3.fromRGB(246, 246, 242)
local WALK = Color3.fromRGB(240, 240, 236)
local JOINT = Color3.fromRGB(218, 220, 216)
local PAVING = Color3.fromRGB(248, 246, 240)
local PAVING_DARK = Color3.fromRGB(198, 214, 228)
local PROMENADE = Color3.fromRGB(232, 128, 84) -- warm brick walks
local HEDGE = Color3.fromRGB(84, 184, 70)
local SOIL = Color3.fromRGB(122, 90, 62)
local SAND = Color3.fromRGB(252, 234, 190)
local SEABED = Color3.fromRGB(236, 226, 186)
local DEEP = Color3.fromRGB(24, 118, 164)
local WATER = Color3.fromRGB(62, 200, 220)
local BARK = Color3.fromRGB(176, 126, 82)
local BARK_DARK = Color3.fromRGB(150, 104, 66)
local LEAF = Color3.fromRGB(84, 192, 70)
local LEAF_LIGHT = Color3.fromRGB(132, 218, 92)

-- The island: grass out to here, then the beach, then the shallows, then the deep sea.
TownMap.IslandX = L + 120
TownMap.IslandZ = 262
TownMap.Beach = 34
TownMap.Shallows = 90
TownMap.WaterY = -1.2

-- A region the preview crops to: { x1, z1, x2, z2 }. Nil builds the whole town.
export type Region = { number }

-- A round piece from p1 to p2 (a beam turned so its length runs along X, made a cylinder).
local function cylBetween(r: R, p1: Vector3, p2: Vector3, d: number, color: Color3, mat: string?)
	local prim = r:beam(p1, p2, d, d, color, mat)
	if prim then
		prim.cf = prim.cf * CFrame.Angles(0, math.pi / 2, 0)
		prim.size = Vector3.new(prim.size.Z, d, d)
		prim.shape = "Cylinder"
	end
end

-- A palm: a curved ringed trunk leaning toward `yaw` (degrees), drooping fronds and coconuts.
-- `spread` scales how far the fronds reach.
local function palm(r: R, ox: number, oy: number, oz: number, h: number, lean: number, yaw: number, spread: number?)
	local dir = Vector3.new(math.cos(math.rad(yaw)), 0, math.sin(math.rad(yaw)))
	local segs = 7
	local prev = Vector3.new(ox, oy, oz)
	local top = prev
	for i = 1, segs do
		local t = i / segs
		local pos = Vector3.new(ox, oy + h * t, oz) + dir * (lean * t * t)
		cylBetween(r, prev, pos, 1.5 - 0.55 * t, if i % 2 == 0 then BARK_DARK else BARK, "Wood")
		prev = pos
		top = pos
	end
	r:ball(top.X, top.Y + 0.3, top.Z, 1.6, LEAF, "SmoothPlastic")
	for k = 0, 2 do
		local a = math.rad(yaw + 60 + k * 120)
		r:ball(top.X + math.cos(a) * 0.7, top.Y - 0.5, top.Z + math.sin(a) * 0.7, 0.85, BARK_DARK, "SmoothPlastic")
	end
	local fronds = 8
	for f = 0, fronds - 1 do
		local a = math.rad(yaw + f * 360 / fronds + (f % 2) * 12)
		local out = Vector3.new(math.cos(a), 0, math.sin(a))
		local color = if f % 2 == 0 then LEAF else LEAF_LIGHT
		local reach = (if f % 2 == 0 then 2.3 else 1.9) * (spread or 1)
		local p0 = top + Vector3.new(0, 0.4, 0)
		for k = 1, 4 do
			local p1 = top + out * (k * reach) + Vector3.new(0, 0.9 * k - 0.42 * k * k + 0.4, 0)
			r:beam(p0, p1, 2.4 - k * 0.42, 0.26, color, "SmoothPlastic")
			p0 = p1
		end
	end
end

-- Street furniture that only the map uses ----------------------------------------------------------

TownMap.Models = {} :: { [string]: (R) -> () }

TownMap.Models.palm = function(r: R)
	palm(r, 0, 0, 0, 15, 2.4, 20)
end

TownMap.Models.palmTall = function(r: R)
	palm(r, 0, 0, 0, 19, 3.4, 200)
end

-- A beach parasol in stripes, a towel and a lounger.
TownMap.Models.parasol = function(r: R)
	local stripes = { Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 120, 110) }
	r:cyl(0, 3.4, 0, 6.8, 0.3, "y", Color3.fromRGB(240, 240, 236), "SmoothPlastic")
	local tip = Vector3.new(0, 7.4, 0)
	local n = 8
	for i = 0, n - 1 do
		local a1, a2 = i / n * math.pi * 2, (i + 1) / n * math.pi * 2
		local p1 = Vector3.new(math.cos(a1) * 5, 6, math.sin(a1) * 5)
		local p2 = Vector3.new(math.cos(a2) * 5, 6, math.sin(a2) * 5)
		r:tri(tip, p1, p2, 0.15, stripes[i % 2 + 1], "SmoothPlastic")
	end
	r:block(-1.6, 0, 1.2, 1.6, 0.06, 6.2, Color3.fromRGB(90, 190, 230), "Fabric")
	r:block(-1.6, 0.06, 1.2, 1.6, 0.08, 1.8, Color3.fromRGB(255, 255, 255), "Fabric")
	-- the lounger
	r:block(2.6, 0.9, -2.5, 4.6, 1.2, 2.5, Color3.fromRGB(255, 255, 255), "SmoothPlastic")
	r:beam(
		Vector3.new(3.6, 1.2, -2.4),
		Vector3.new(3.6, 3.0, -3.6),
		2,
		0.3,
		Color3.fromRGB(255, 255, 255),
		"SmoothPlastic"
	)
	for _, x in { 2.8, 4.4 } do
		for _, z in { -2.2, 2.2 } do
			r:block(x - 0.15, 0, z - 0.15, x + 0.15, 0.9, z + 0.15, Color3.fromRGB(220, 222, 224), "Metal")
		end
	end
end

-- A little island out at sea: sand rising out of the deep, a grassy top and a few palms.
TownMap.Models.islet = function(r: R)
	r:cyl(0, -7, 0, 18, 64, "y", SAND, "Sand")
	r:cyl(0, 2.1, 0, 0.4, 44, "y", GRASS, "Grass")
	palm(r, -6, 2.3, 4, 16, 3, 140)
	palm(r, 7, 2.3, -3, 13, 2.6, 330)
	palm(r, 2, 2.3, 9, 18, 3.6, 70)
end

TownMap.Models.hydrant = function(r: R)
	local red = Color3.fromRGB(206, 52, 48)
	r:cyl(0, 0.1, 0, 0.2, 1.3, "y", C.DarkMetal, "Metal")
	r:cyl(0, 1.1, 0, 1.9, 0.9, "y", red, "Metal")
	r:cyl(0, 2.1, 0, 0.2, 1.1, "y", red, "Metal")
	r:ball(0, 2.25, 0, 0.9, red, "Metal")
	r:cyl(0, 2.75, 0, 0.3, 0.3, "y", C.Gold, "Metal")
	for _, x in { -0.55, 0.55 } do
		r:cyl(x, 1.4, 0, 0.35, 0.42, "x", C.Gold, "Metal")
	end
	r:cyl(0, 1.25, 0.5, 0.3, 0.5, "z", C.Gold, "Metal")
end

TownMap.Models.bin = function(r: R)
	local green = Color3.fromRGB(52, 110, 74)
	r:cyl(0, 1.5, 0, 3, 1.8, "y", green, "Metal")
	r:cyl(0, 3.05, 0, 0.12, 2, "y", Color3.fromRGB(40, 86, 58), "Metal")
	r:cyl(0, 3.12, 0, 0.06, 1.4, "y", C.Black, "Metal")
	for _, a in { 0, 90 } do
		local cf = CFrame.Angles(0, math.rad(a), 0)
		r:boxAt(cf * CFrame.new(0, 1.6, 0), 1.86, 0.18, 0.2, Color3.fromRGB(40, 86, 58), "Metal")
	end
end

TownMap.Models.bollard = function(r: R)
	r:cyl(0, 1.2, 0, 2.4, 0.6, "y", C.DarkMetal, "Metal")
	r:cyl(0, 2.1, 0, 0.25, 0.66, "y", C.Yellow, "SmoothPlastic")
	r:ball(0, 2.4, 0, 0.6, C.DarkMetal, "Metal")
end

TownMap.Models.streetTree = function(r: R)
	-- a square planter with a white kerb, soil, and a palm
	r:block(-1.8, 0, -1.8, 1.8, 0.45, -1.4, CURB, "Concrete")
	r:block(-1.8, 0, 1.4, 1.8, 0.45, 1.8, CURB, "Concrete")
	r:block(-1.8, 0, -1.4, -1.4, 0.45, 1.4, CURB, "Concrete")
	r:block(1.4, 0, -1.4, 1.8, 0.45, 1.4, CURB, "Concrete")
	r:block(-1.4, 0, -1.4, 1.4, 0.3, 1.4, SOIL, "Ground")
	-- leaning out over the street (local -Z), with a smaller crown that stays off the plots
	palm(r, 0, 0.3, 0, 14, 1.8, 270, 0.68)
end

TownMap.Models.busStop = function(r: R)
	local frame = Color3.fromRGB(46, 78, 120)
	for _, x in { -5, 5 } do
		for _, z in { -1.6, 1.4 } do
			r:block(x - 0.2, 0, z - 0.2, x + 0.2, 8, z + 0.2, frame, "Metal")
		end
	end
	r:block(-5.6, 8, -2.2, 5.6, 8.5, 2.2, frame, "Metal")
	r:block(-5.4, 8.5, -2, 5.4, 8.7, 2, Color3.fromRGB(196, 230, 242), "Glass").transp = 0.4
	local back = r:glass(-4.8, 0.6, -1.65, 4.8, 7.8, -1.55)
	back.transp = 0.55
	for _, x in { -5, 5 } do
		local side = r:glass(x - 0.05, 2, -1.4, x + 0.05, 7.8, 0.6)
		side.transp = 0.55
	end
	-- an advert on the back wall
	r:block(1.4, 2, -1.5, 4.4, 6.6, -1.42, Color3.fromRGB(250, 214, 120), "SmoothPlastic")
	r:block(1.7, 4.6, -1.42, 4.1, 6.2, -1.38, Color3.fromRGB(242, 95, 92), "SmoothPlastic")
	-- the bench
	r:block(-4.2, 1.7, -1.4, 0.8, 2, -0.2, Color3.fromRGB(150, 100, 60), "WoodPlanks")
	for _, x in { -3.8, 0.4 } do
		r:block(x - 0.15, 0, -1.2, x + 0.15, 1.7, -0.4, C.DarkMetal, "Metal")
	end
	r:seat(-2.6, 2, -0.8, 0)
	r:seat(-0.6, 2, -0.8, 0)
	-- the stop sign on a pole beside it
	r:cyl(6.6, 4.5, 1.2, 9, 0.3, "y", C.Metal, "Metal")
	r:cyl(6.6, 9.2, 1.2, 0.3, 2, "z", Color3.fromRGB(59, 130, 246), "SmoothPlastic")
	r:cyl(6.6, 9.2, 1.36, 0.06, 1.4, "z", C.White, "SmoothPlastic")
end

-- A low hedge along X, length w.
TownMap.Models.hedge = function(r: R)
	r:block(-4, 0, -0.9, 4, 2.6, 0.9, HEDGE, "Grass")
	r:block(-3.8, 2.6, -0.7, 3.8, 2.9, 0.7, Color3.fromRGB(76, 146, 70), "Grass")
end

TownMap.Models.flowerBed = function(r: R)
	r:block(-4, 0, -2, 4, 0.5, 2, Color3.fromRGB(170, 120, 82), "Wood")
	r:block(-3.7, 0.5, -1.7, 3.7, 0.7, 1.7, SOIL, "Ground")
	local colours = { C.Pink, C.Yellow, Color3.fromRGB(240, 240, 250), Color3.fromRGB(196, 120, 220), C.Red }
	local i = 0
	for x = -3, 3, 1.5 do
		for z = -1, 1, 1 do
			i += 1
			r:cyl(x, 0.95, z, 0.5, 0.12, "y", C.DarkLeaf, "Grass")
			r:ball(x, 1.35, z, 0.75, colours[i % #colours + 1], "SmoothPlastic")
		end
	end
end

TownMap.Models.streetSign = function(r: R)
	r:cyl(0, 4.5, 0, 9, 0.3, "y", C.Metal, "Metal")
	r:block(-2.4, 8.2, -0.08, 2.4, 9.2, 0.08, Color3.fromRGB(46, 120, 74), "SmoothPlastic")
	r:block(-2.2, 8.4, 0.08, 2.2, 9, 0.12, C.White, "SmoothPlastic")
end

-- A market stall facing +Z: a counter with produce crates, four posts and a striped awning.
TownMap.Models.marketStall = function(r: R)
	local wood = Color3.fromRGB(160, 110, 66)
	local dark = Color3.fromRGB(110, 74, 44)
	r:block(-4, 0, -1.6, 4, 3, 1.4, wood, "WoodPlanks")
	r:block(-4.2, 3, -1.8, 4.2, 3.3, 1.7, dark, "Wood")
	-- crates of fruit and veg on the counter
	local produce = { C.Red, Color3.fromRGB(245, 160, 50), C.Leaf, C.Yellow }
	for i = 0, 3 do
		local x = -3 + i * 2
		r:block(x - 0.8, 3.3, -0.6, x + 0.8, 3.9, 1.2, Color3.fromRGB(196, 150, 96), "Wood")
		for j = 0, 2 do
			r:ball(x - 0.4 + (j % 2) * 0.8, 4.1, -0.2 + j * 0.5, 0.6, produce[i + 1], "SmoothPlastic")
		end
	end
	for _, x in { -3.9, 3.9 } do
		for _, z in { -1.5, 1.5 } do
			r:block(x - 0.18, 0, z - 0.18, x + 0.18, if z < 0 then 8.4 else 7.2, z + 0.18, dark, "Wood")
		end
	end
	-- the awning slopes down to the front, in stripes
	local stripes = 6
	for i = 0, stripes - 1 do
		local x1 = -4.6 + i * 9.2 / stripes
		local cf = CFrame.new(x1 + 9.2 / stripes / 2, 7.9, 0) * CFrame.Angles(math.rad(-22), 0, 0)
		r:boxAt(cf, 9.2 / stripes, 0.2, 4.4, if i % 2 == 0 then C.White else Color3.fromRGB(46, 150, 90), "Fabric")
	end
	for i = 0, stripes - 1 do
		local x = -4.6 + (i + 0.5) * 9.2 / stripes
		r:block(
			x - 0.75,
			6.4,
			2.02,
			x + 0.75,
			7.1,
			2.12,
			if i % 2 == 0 then C.White else Color3.fromRGB(46, 150, 90),
			"Fabric"
		)
	end
end

-- A café table with two chairs under a parasol.
TownMap.Models.cafeTable = function(r: R)
	local metal = Color3.fromRGB(60, 64, 72)
	r:cyl(0, 0.05, 0, 0.1, 1.4, "y", metal, "Metal")
	r:cyl(0, 1.3, 0, 2.5, 0.2, "y", metal, "Metal")
	r:cyl(0, 2.6, 0, 0.12, 2.8, "y", C.White, "SmoothPlastic")
	for _, side in { -1, 1 } do
		local z = side * 2
		r:block(-0.7, 1.4, z - 0.7, 0.7, 1.6, z + 0.7, Color3.fromRGB(150, 100, 60), "WoodPlanks")
		for _, dx in { -0.55, 0.55 } do
			for _, dz in { -0.55, 0.55 } do
				r:block(dx - 0.08, 0, z + dz - 0.08, dx + 0.08, 1.4, z + dz + 0.08, metal, "Metal")
			end
		end
		r:block(-0.7, 1.6, z + side * 0.6, 0.7, 3.1, z + side * 0.72, Color3.fromRGB(150, 100, 60), "WoodPlanks")
		r:seat(0, 1.6, z, if side > 0 then 180 else 0)
	end
	r:cyl(0, 4.2, 0, 5.6, 0.16, "y", C.White, "Metal")
	-- the parasol: eight panels round a peak
	local colours = { Color3.fromRGB(242, 95, 92), C.White }
	for i = 0, 7 do
		local a1, a2 = i / 8 * math.pi * 2, (i + 1) / 8 * math.pi * 2
		r:tri(
			Vector3.new(math.cos(a1) * 3.4, 6.2, math.sin(a1) * 3.4),
			Vector3.new(math.cos(a2) * 3.4, 6.2, math.sin(a2) * 3.4),
			Vector3.new(0, 7.4, 0),
			0.12,
			colours[i % 2 + 1],
			"Fabric"
		)
	end
	r:ball(0, 7.45, 0, 0.35, C.White, "SmoothPlastic")
end

-- A round bandstand for the square's festivals: a raised floor, eight posts and a peaked roof.
TownMap.Models.bandstand = function(r: R)
	local white = Color3.fromRGB(244, 240, 232)
	local roof = Color3.fromRGB(255, 120, 104)
	r:cyl(0, 0.75, 0, 1.5, 17, "y", Color3.fromRGB(196, 190, 178), "Cobblestone")
	r:cyl(0, 1.6, 0, 0.2, 16, "y", Color3.fromRGB(176, 128, 82), "WoodPlanks")
	-- steps up on the front
	r:block(-2.4, 0, 8.2, 2.4, 0.5, 9.6, Color3.fromRGB(196, 190, 178), "Cobblestone")
	r:block(-2.4, 0.5, 8.2, 2.4, 1, 8.9, Color3.fromRGB(196, 190, 178), "Cobblestone")
	for i = 0, 7 do
		local a = (i + 0.5) / 8 * math.pi * 2
		local x, z = math.cos(a) * 7.2, math.sin(a) * 7.2
		r:cyl(x, 5.6, z, 8, 0.6, "y", white, "Wood")
		-- a low rail between posts, except at the front where the steps come up
		local a2 = (i + 1.5) / 8 * math.pi * 2
		local x2, z2 = math.cos(a2) * 7.2, math.sin(a2) * 7.2
		if not (z > 5 and z2 > 5) then
			r:beam(Vector3.new(x, 3.4, z), Vector3.new(x2, 3.4, z2), 0.25, 0.3, white, "Wood")
		end
	end
	r:cyl(0, 9.75, 0, 0.5, 16.4, "y", white, "Wood")
	for i = 0, 7 do
		local a1, a2 = i / 8 * math.pi * 2, (i + 1) / 8 * math.pi * 2
		r:tri(
			Vector3.new(math.cos(a1) * 8.6, 10, math.sin(a1) * 8.6),
			Vector3.new(math.cos(a2) * 8.6, 10, math.sin(a2) * 8.6),
			Vector3.new(0, 14, 0),
			0.3,
			roof,
			"RoofShingles"
		)
	end
	r:cyl(0, 14.6, 0, 1.4, 0.2, "y", C.Gold, "Metal")
	r:ball(0, 15.4, 0, 0.6, C.Gold, "Metal")
end

TownMap.Models.flagpole = function(r: R)
	r:cyl(0, 0.3, 0, 0.6, 1.6, "y", Color3.fromRGB(196, 190, 178), "Concrete")
	r:cyl(0, 8, 0, 15, 0.3, "y", C.Metal, "Metal")
	r:ball(0, 15.6, 0, 0.5, C.Gold, "Metal")
	-- the flag's parts are named so the client can wave them
	r:block(0.15, 12.2, -0.05, 4.6, 15, 0.05, Color3.fromRGB(59, 130, 246), "Fabric").name = "Flag"
	r:block(0.15, 13.2, -0.06, 4.6, 14, 0.06, C.White, "Fabric").name = "Flag"
end

-- decoration ----------------------------------------------------------------------------------------

-- A round bush of a few leafy balls.
TownMap.Models.bush = function(r: R)
	r:ball(0, 1.6, 0, 3.4, Color3.fromRGB(78, 160, 74), "Grass")
	r:ball(-1.3, 1.2, 0.6, 2.4, Color3.fromRGB(96, 182, 84), "Grass")
	r:ball(1.2, 1.3, -0.4, 2.6, Color3.fromRGB(64, 140, 66), "Grass")
	r:ball(0.3, 2.6, 0.2, 2, Color3.fromRGB(110, 196, 92), "Grass")
end

-- A patch of flowers in the grass: a low green tuft dotted with blooms.
TownMap.Models.flowerPatch = function(r: R)
	r:cyl(0, 0.15, 0, 0.3, 7, "y", Color3.fromRGB(96, 176, 80), "Grass")
	local colours = {
		C.Pink,
		C.Yellow,
		Color3.fromRGB(250, 250, 255),
		Color3.fromRGB(190, 120, 240),
		C.Red,
		Color3.fromRGB(255, 160, 80),
	}
	local rng = Rng.new(5)
	for i = 1, 14 do
		local a = rng:float(0, math.pi * 2)
		local d = rng:float(0.4, 3)
		local x, z = math.cos(a) * d, math.sin(a) * d
		local h = rng:float(0.5, 1.1)
		r:cyl(x, h / 2, z, h, 0.1, "y", C.DarkLeaf, "Grass")
		r:ball(x, h + 0.15, z, rng:float(0.45, 0.65), colours[i % #colours + 1], "SmoothPlastic")
	end
end

TownMap.Models.rock = function(r: R)
	r:ball(0, 0.6, 0, 2.6, Color3.fromRGB(170, 172, 182), "Slate")
	r:ball(1.3, 0.4, 0.6, 1.6, Color3.fromRGB(150, 152, 162), "Slate")
	r:ball(-1, 0.3, -0.7, 1.2, Color3.fromRGB(186, 188, 196), "Slate")
end

-- Rolling hills round the edge of the world: the top of a big buried ball.
local function hill(radius: number, height: number) -- (no longer placed; kept for the preview scenes)
	return function(r: R)
		r:ball(0, height - radius, 0, radius * 2, Color3.fromRGB(110, 186, 86), "Grass")
	end
end
TownMap.Models.hillS = hill(55, 14)
TownMap.Models.hillM = hill(80, 22)
TownMap.Models.hillL = hill(110, 30)

function TownMap.prims(name: string): { Prim }
	local build = TownMap.Models[name]
	if not build then
		return TownModels.prims(name)
	end
	local r = Recipe.new(C.White, C.White)
	build(r)
	return r.prims
end

-- The ground ---------------------------------------------------------------------------------------

local function clip(region: Region?, x1: number, z1: number, x2: number, z2: number): (number?, number, number, number)
	if not region then
		return x1, z1, x2, z2
	end
	local a, b, c, d =
		math.max(x1, region[1]), math.max(z1, region[2]), math.min(x2, region[3]), math.min(z2, region[4])
	if a >= c or b >= d then
		return nil, 0, 0, 0
	end
	return a, b, c, d
end

-- The square's lawns: { centre x, centre z, half width, half depth }. Only the north corners;
-- the notice board and the tailor stand in the south ones.
function TownMap.lawns(): { { number } }
	local sq = Town.SquareCenter
	return { { sq.X - 30, sq.Z + 30, 12, 15 }, { sq.X + 30, sq.Z + 30, 12, 15 } }
end

-- The street, curbs, sidewalks, the square and the market, as one list of flat parts.
function TownMap.ground(region: Region?): { Prim }
	local r = Recipe.new(C.White, C.White)
	local function slab(
		x1: number,
		z1: number,
		x2: number,
		z2: number,
		y1: number,
		y2: number,
		color: Color3,
		mat: string
	)
		local a, b, c, d = clip(region, x1, z1, x2, z2)
		if a then
			r:block(a, y1, b, c, y2, d, color, mat)
		end
	end

	-- the island: grass, a sandy beach round it, sand under the shallows, the deep sea floor, and
	-- the water over all of it (see through, so the shallows show light and the deep sea dark)
	local IX, IZ, B, SH = TownMap.IslandX, TownMap.IslandZ, TownMap.Beach, TownMap.Shallows
	local WY = TownMap.WaterY
	slab(-IX, -IZ, IX, IZ, -2.1, -0.1, GRASS, "Grass")
	slab(-IX - B, -IZ - B, IX + B, IZ + B, -2.6, -0.35, SAND, "Sand")
	slab(-IX - B - SH, -IZ - B - SH, IX + B + SH, IZ + B + SH, -4, -2.5, SEABED, "Sand")
	local FAR = 2400
	slab(-FAR, -FAR, FAR, FAR, -18, -16, DEEP, "SmoothPlastic")
	do
		local a, b, c, d = clip(region, -FAR, -FAR, FAR, FAR)
		if a then
			local water = r:block(a, WY - 0.2, b, c, WY, d, WATER, "SmoothPlastic")
			water.transp = 0.3
			water.collide = false
			water.name = "Water"
		end
	end
	-- walls nobody sees at the edge of the shallows, so nobody wanders off into the deep
	local EX, EZ = IX + B + SH, IZ + B + SH
	for _, w in
		{
			{ -EX - 2, -EZ - 2, EX + 2, -EZ },
			{ -EX - 2, EZ, EX + 2, EZ + 2 },
			{ -EX - 2, -EZ, -EX, EZ },
			{ EX, -EZ, EX + 2, EZ },
		}
	do
		local a, b, c, d = clip(region, w[1], w[2], w[3], w[4])
		if a then
			local wall = r:block(a, -4, b, c, 30, d, WATER, "SmoothPlastic")
			wall.transp = 1
			wall.name = "SeaWall"
		end
	end
	-- the road, with a darker gutter strip along each edge
	slab(-L, -HW + 1, L, HW - 1, -0.15, 0.05, ROAD, "Asphalt")
	for _, side in { 1, -1 } do
		local z1, z2 = side * (HW - 1), side * HW
		slab(-L, math.min(z1, z2), L, math.max(z1, z2), -0.15, 0.05, ROAD_EDGE, "Asphalt")
	end

	-- crosswalk places: in front of the square and the market, and between the plot pairs
	local crossings = { 0, -274, 274 }
	local ordered = table.clone(crossings)
	table.sort(ordered)
	local function nearCrossing(x: number, gap: number): boolean
		for _, cx in crossings do
			if math.abs(x - cx) < gap then
				return true
			end
		end
		return false
	end

	-- solid edge lines and the dashed middle line
	for _, side in { 1, -1 } do
		local z = side * (HW - 1.8)
		local x = -L + 4
		while x < L - 4 do
			local x2 = math.min(L - 4, x + 40)
			if not nearCrossing((x + x2) / 2, 30) then
				slab(x, z - 0.2, x2, z + 0.2, 0.05, 0.08, LINE_WHITE, "SmoothPlastic")
			end
			x = x2
		end
	end
	for x = -L + 6, L - 14, 14 do
		if not nearCrossing(x + 3.5, 14) then
			slab(x, -0.3, x + 7, 0.3, 0.05, 0.08, LINE_YELLOW, "SmoothPlastic")
		end
	end
	-- zebra crossings with stop lines
	for _, cx in crossings do
		for z = -HW + 2.2, HW - 2.6, 2.8 do
			slab(cx - 6, z, cx + 6, z + 1.6, 0.05, 0.08, LINE_WHITE, "SmoothPlastic")
		end
		for _, side in { 1, -1 } do
			local sx = cx + side * 8.5
			slab(
				sx - 0.4,
				if side > 0 then -HW + 1.5 else 0.6,
				sx + 0.4,
				if side > 0 then -0.6 else HW - 1.5,
				0.05,
				0.08,
				LINE_WHITE,
				"SmoothPlastic"
			)
		end
	end

	-- curbs and sidewalks
	for _, side in { 1, -1 } do
		local inner = side * HW
		local curbOuter = side * (HW + 0.8)
		local outer = side * (HW + SW)
		local function zs(a: number, b: number): (number, number)
			return math.min(a, b), math.max(a, b)
		end
		local cz1, cz2 = zs(inner, curbOuter)
		local wz1, wz2 = zs(curbOuter, outer)
		-- curbs drop to the road at the crossings so prams and villagers roll straight across
		local x = -L
		for _, cx in ordered do
			slab(x, cz1, cx - 6, cz2, -0.15, 0.4, CURB, "Concrete")
			slab(cx - 6, cz1, cx + 6, cz2, -0.15, 0.12, CURB, "Concrete")
			x = cx + 6
		end
		slab(x, cz1, L, cz2, -0.15, 0.4, CURB, "Concrete")
		slab(-L, wz1, L, wz2, -0.15, 0.3, WALK, "Pavement")
		-- joints across the sidewalk every 8 studs
		for jx = -L + 8, L - 8, 8 do
			slab(jx - 0.1, wz1, jx + 0.1, wz2, 0.3, 0.32, JOINT, "Concrete")
		end
	end

	-- the square (north) and the market (south): paving with a darker border
	for _, center in { Town.SquareCenter, Town.MarketCenter } do
		local x1, x2 = center.X - 50, center.X + 50
		-- the paving runs right up to the sidewalk
		local z1 = if center.Z > 0 then HW + SW else center.Z - 60
		local z2 = if center.Z > 0 then center.Z + 60 else -(HW + SW)
		slab(x1, z1, x2, z2, -0.15, 0.25, PAVING_DARK, "Pavement")
		slab(x1 + 1.2, z1 + 1.2, x2 - 1.2, z2 - 1.2, -0.15, 0.27, PAVING, "Pavement")
	end
	-- a grid of joints in the paving, and lighter walkways from the crossing to the fountain
	-- and to the hall
	local LIGHT = Color3.fromRGB(236, 224, 202)
	for _, center in { Town.SquareCenter, Town.MarketCenter } do
		local z1 = if center.Z > 0 then HW + SW + 1.2 else center.Z - 58.8
		local z2 = if center.Z > 0 then center.Z + 58.8 else -(HW + SW + 1.2)
		for gx = center.X - 48, center.X + 48, 12 do
			slab(gx - 0.12, z1, gx + 0.12, z2, 0.27, 0.28, PAVING_DARK, "Pavement")
		end
		for gz = center.Z - 60 + 12, center.Z + 60 - 12, 12 do
			if gz > z1 and gz < z2 then
				slab(center.X - 48.8, gz - 0.12, center.X + 48.8, gz + 0.12, 0.27, 0.28, PAVING_DARK, "Pavement")
			end
		end
	end
	local _ = LIGHT
	slab(-5, HW + SW, 5, Town.Spots.Fountain.Z - 16, 0.27, 0.29, PROMENADE, "Brick")
	slab(-5, Town.Spots.Hall.Z + 14, 5, -(HW + SW), 0.27, 0.29, PROMENADE, "Brick")
	-- and a brick walk round the square's edge
	for _, center in { Town.SquareCenter, Town.MarketCenter } do
		local z1 = if center.Z > 0 then HW + SW + 1.2 else center.Z - 58.8
		local z2 = if center.Z > 0 then center.Z + 58.8 else -(HW + SW + 1.2)
		for _, sx in { -1, 1 } do
			local x = center.X + sx * 45
			slab(x - 3, z1, x + 3, z2, 0.27, 0.285, PROMENADE, "Brick")
		end
	end
	-- a round of lighter paving and a ring of dark stone around the fountain
	if not region or (region[1] < 20 and region[3] > -20 and region[2] < 100 and region[4] > 60) then
		local f = Town.Spots.Fountain
		r:cyl(f.X, 0.28, f.Z, 0.04, 36, "y", PAVING_DARK, "Pavement")
		r:cyl(f.X, 0.29, f.Z, 0.04, 34, "y", Color3.fromRGB(234, 222, 200), "Pavement")
	end
	-- lawns in the square's four corners
	for _, l in TownMap.lawns() do
		local cx, cz, hx, hz = l[1], l[2], l[3], l[4]
		slab(cx - hx, cz - hz, cx + hx, cz + hz, -0.15, 0.32, GRASS, "Grass")
		-- a kerb round the lawn
		slab(cx - hx - 0.5, cz - hz - 0.5, cx + hx + 0.5, cz - hz, -0.15, 0.6, CURB, "Concrete")
		slab(cx - hx - 0.5, cz + hz, cx + hx + 0.5, cz + hz + 0.5, -0.15, 0.6, CURB, "Concrete")
		slab(cx - hx - 0.5, cz - hz, cx - hx, cz + hz, -0.15, 0.6, CURB, "Concrete")
		slab(cx + hx, cz - hz, cx + hx + 0.5, cz + hz, -0.15, 0.6, CURB, "Concrete")
	end
	return r.prims
end

-- What stands on the ground ---------------------------------------------------------------------------

export type Placement = { name: string, cf: CFrame, action: string?, opens: string?, tag: string? }

function TownMap.placements(): { Placement }
	local out: { Placement } = {}
	local function put(name: string, x: number, z: number, yaw: number, extra: { [string]: any }?)
		local p: Placement = { name = name, cf = CFrame.new(x, 0, z) * CFrame.Angles(0, math.rad(yaw), 0) }
		if extra then
			p.action = extra.action
			p.opens = extra.opens
			p.tag = extra.tag
		end
		table.insert(out, p)
	end
	local S = Town.Spots
	local PAVE_Y = 0.27
	local function onPaving(name: string, x: number, z: number, yaw: number, extra: { [string]: any }?)
		put(name, x, z, yaw, extra)
		local last = out[#out]
		last.cf = last.cf + Vector3.new(0, PAVE_Y, 0)
	end

	-- the plaza's buildings
	onPaving("fountain", S.Fountain.X, S.Fountain.Z, 0)
	onPaving("board", S.Board.X, S.Board.Z, 180, { action = "Town news", opens = "news" })
	onPaving("tailor", S.Tailor.X, S.Tailor.Z, 180, { action = "Make a villager", opens = "creator" })
	onPaving("shop", S.Shop.X, S.Shop.Z, 0, { action = "Shop", opens = "shop" })
	onPaving("hall", S.Hall.X, S.Hall.Z, 0, { action = "City hall", opens = "city" })
	onPaving("sign", 14, 30, 180, { tag = "welcome" })

	-- benches round the fountain, facing it
	for i = 0, 5 do
		-- none on the walkway's end or the festival spot in front of the bandstand
		local a = i / 6 * math.pi * 2
		local x, z = S.Fountain.X + math.cos(a) * 16, S.Fountain.Z + math.sin(a) * 16
		local yaw = math.deg(math.atan2(S.Fountain.X - x, S.Fountain.Z - z))
		onPaving("bench", x, z, yaw)
	end
	-- the square: lawns get a tree and flowers each, hedges line the far side
	local sq = Town.SquareCenter
	for i, l in TownMap.lawns() do
		local cx, cz = l[1], l[2]
		local sx = if cx < 0 then -1 else 1
		put("palm", cx + sx * 4, cz + 5, i * 70)
		local bed = out[#out]
		bed.cf = bed.cf + Vector3.new(0, 0.32, 0)
		put("flowerBed", cx - sx * 3, cz - 8, 0)
		bed = out[#out]
		bed.cf = bed.cf + Vector3.new(0, 0.32, 0)
	end
	for x = -44, 44, 8 do
		if math.abs(x) > 8 then
			onPaving("hedge", x, sq.Z + 57, 0)
		end
	end
	onPaving("bin", -9, 60, 0)
	onPaving("bin", 9, 102, 0)
	-- the bandstand at the top of the square, where festivals gather
	onPaving("bandstand", 0, sq.Z + 44, 180)
	-- café tables outside the shop
	for _, p in { { -10, -36 }, { -10, -46 }, { -10, -56 } } do
		onPaving("cafeTable", p[1], p[2], 90)
	end
	-- the market: stalls of planters and benches along its sides
	local mk = Town.MarketCenter
	for _, sx in { -1, 1 } do
		for z = mk.Z - 20, mk.Z + 40, 30 do
			onPaving("streetTree", mk.X + sx * 44, z, 0)
		end
		onPaving("bench", mk.X + sx * 40, mk.Z + 5, sx * -90)
	end
	onPaving("bin", 12, -40, 0)
	-- market stalls down the east side
	for i, z in { -40, -58, -76 } do
		onPaving("marketStall", 26, z, -90)
		local _ = i
	end
	-- flags in front of the hall
	for _, x in { -12, 12 } do
		onPaving("flagpole", x, Town.Spots.Hall.Z + 22, 0)
	end

	-- lamps at the plaza corners
	for _, p in
		{ { -40, 30 }, { 40, 30 }, { -40, 130 }, { 40, 130 }, { -40, -30 }, { 40, -30 }, { -40, -130 }, { 40, -130 } }
	do
		onPaving("lamp", p[1], p[2], 0)
	end

	-- along the street: lamps, street trees, hydrants and signs on both sidewalks
	local walkZ = HW + 3 -- tree pits near the curb leave room to walk behind them
	for x = -L + 40, L - 40, 68 do
		for _, side in { 1, -1 } do
			put("lamp", x, side * (HW + 1.6), if side > 0 then 0 else 180)
		end
	end
	for x = -L + 20, L - 20, 34 do
		local onPlaza = math.abs(x) < 54
		local nearCross = math.abs(x - 274) < 14 or math.abs(x + 274) < 14
		if not onPlaza and not nearCross then
			for _, side in { 1, -1 } do
				put("streetTree", x, side * walkZ, if side > 0 then 0 else 180)
				local last = out[#out]
				last.cf = last.cf + Vector3.new(0, 0.3, 0)
			end
		end
	end
	for _, x in { -320, -120, 120, 320 } do
		put("hydrant", x, HW + 1.5, 0)
		put("hydrant", -x, -(HW + 1.5), 180)
	end
	for _, cx in { -274, 274 } do
		for _, side in { 1, -1 } do
			put("streetSign", cx + 9, side * (HW + 1.4), if side > 0 then 0 else 180)
			for _, bx in { -5, 5 } do
				put("bollard", cx + bx, side * (HW + 1.2), 0)
			end
		end
	end
	-- the bus stop on the south side, facing the street
	put("busStop", 96, -(HW + SW - 2.2), 0)
	put("bin", 88, -(HW + 2), 0)

	-- bushes along the plaza's sides, on the grass between it and the plots
	for _, sx in { -1, 1 } do
		for z = 30, 136, 13 do
			put("bush", sx * 58, z, z * 7)
		end
		for z = -136, -30, 13 do
			put("bush", sx * 58, z, z * 11)
		end
	end
	-- flowers in the square's lawns
	for _, l in TownMap.lawns() do
		local cx, cz = l[1], l[2]
		for _, d in { { -6, 6 }, { 6, -4 } } do
			put("flowerPatch", cx + d[1], cz + d[2], 0)
			local last = out[#out]
			last.cf = last.cf + Vector3.new(0, 0.32, 0)
		end
		for _, d in { { -10, -12 }, { 10, 12 } } do
			put("bush", cx + d[1], cz + d[2], 0)
			local last = out[#out]
			last.cf = last.cf + Vector3.new(0, 0.32, 0)
		end
	end
	-- out at sea: little islets on the horizon
	local sea = Rng.new(19)
	local IX, IZ, B = TownMap.IslandX, TownMap.IslandZ, TownMap.Beach
	for x = -L - 200, L + 200, 210 do
		for _, side in { 1, -1 } do
			put("islet", x + sea:float(-60, 60), side * sea:float(470, 560), sea:float(0, 360), { tag = "backdrop" })
		end
	end
	for _, side in { 1, -1 } do
		put("islet", side * (IX + 260), sea:float(-120, 120), sea:float(0, 360), { tag = "backdrop" })
	end
	-- flowers and a few rocks in the grass round the edge of town
	for _ = 1, 70 do
		local x = sea:float(-IX + 10, IX - 10)
		local z = sea:float(-IZ + 6, IZ - 6)
		local inTown = math.abs(z) < 238 and math.abs(x) < L + 14
		local onSquare = math.abs(x) < 70 and math.abs(z) < 150
		if not inTown and not onSquare then
			put(if sea:chance(0.75) then "flowerPatch" else "rock", x, z, sea:float(0, 360))
		end
	end

	-- palms and round trees round the edge of town, clear of the street, the square and every plot
	local trees = Rng.new(7)
	for _ = 1, 120 do
		local x = trees:float(-IX + 8, IX - 8)
		local z = trees:float(-IZ + 4, IZ - 4)
		local inTown = math.abs(z) < 236 and math.abs(x) < L + 12
		local onSquare = math.abs(x) < 54 and math.abs(z) < 150
		if not inTown and not onSquare then
			local kind = if trees:chance(0.6) then (if trees:chance(0.5) then "palm" else "palmTall") else "tree"
			put(kind, x, z, trees:float(0, 360))
		end
	end
	-- the beach: palms leaning out to sea, and parasols on the sand
	local beach = Rng.new(31)
	for _, side in { 1, -1 } do
		local z0 = side * (IZ + B * 0.45)
		for x = -IX + 20, IX - 20, 26 do
			local px, pz = x + beach:float(-8, 8), z0 + beach:float(-6, 6)
			put(if beach:chance(0.5) then "palm" else "palmTall", px, pz, if side > 0 then 90 else 270)
			local last = out[#out]
			last.cf = last.cf + Vector3.new(0, -0.25, 0)
		end
		for x = -IX + 60, IX - 60, 70 do
			put("parasol", x + beach:float(-10, 10), side * (IZ + B * 0.7), beach:float(-20, 20))
			local last = out[#out]
			last.cf = last.cf + Vector3.new(0, -0.35, 0)
		end
	end
	for _, side in { 1, -1 } do
		for z = -IZ + 20, IZ - 20, 30 do
			put("palm", side * (IX + B * 0.45), z + beach:float(-8, 8), if side > 0 then 0 else 180)
			local last = out[#out]
			last.cf = last.cf + Vector3.new(0, -0.25, 0)
		end
	end
	return out
end

-- The middle of town as one list, for the preview tool.
function TownMap.preview(region: Region?): { Prim }
	local reg = region or { -110, -150, 110, 150 }
	local out = TownMap.ground(reg)
	for _, p in TownMap.placements() do
		local pos = p.cf.Position
		if pos.X >= reg[1] and pos.X <= reg[3] and pos.Z >= reg[2] and pos.Z <= reg[4] then
			for _, prim in TownMap.prims(p.name) do
				prim.cf = p.cf * prim.cf
				table.insert(out, prim)
			end
		end
	end
	return out
end

return TownMap
