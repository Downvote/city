--!strict
-- The town's island as parts: a sunny island in a turquoise sea with a sandy beach, the street
-- with its lane lines and crosswalks, white curbs and paving, palms in planters, the square's
-- lawns, hedges and brick promenade, and the street furniture (lamps, benches, bins, hydrants,
-- a bus stop). Out at sea, little islets with palms sit on the horizon.
-- Shared and free of services, so the World service builds it and the preview tool can draw it.

local Recipe = require(script.Parent.Parent.Build.Recipe)
local Geometry = require(script.Parent.Parent.Build.Geometry)
local Tuning = require(script.Parent.Parent.Config.Tuning)
local Town = require(script.Parent.Town)
local TownModels = require(script.Parent.TownModels)
local Rng = require(script.Parent.Parent.Util.Rng)
local Hills = require(script.Parent.Hills)
local DetailModels = require(script.Parent.DetailModels)
local CityModels = require(script.Parent.CityModels)
local StreetModels = require(script.Parent.StreetModels)
local Facades = require(script.Parent.Facades)
local Landmarks = require(script.Parent.Landmarks)
local StreetPaint = require(script.Parent.StreetPaint)

type R = Recipe.Recipe
type Prim = Geometry.Prim
local C = Recipe.Colors

local TownMap = {}

local L = Town.HalfLength
local HW = Town.StreetHalfWidth
local SW = Town.SidewalkWidth

local GRASS = Color3.fromRGB(112, 188, 84)
local ROAD = Color3.fromRGB(92, 96, 108)
local LINE_WHITE = Color3.fromRGB(250, 250, 246)
local LINE_YELLOW = Color3.fromRGB(255, 210, 70)
local MANHOLE = Color3.fromRGB(70, 74, 86)
local LANE = Color3.fromRGB(226, 200, 176) -- the cobbled lanes through downtown's blocks
local GRAVEL = Color3.fromRGB(236, 226, 204)
local CURB = Color3.fromRGB(246, 246, 242)
local WALK = Color3.fromRGB(240, 240, 236)
local PAVING = Color3.fromRGB(236, 238, 240)
local PAVING_DARK = Color3.fromRGB(214, 220, 228)
local PROMENADE = Color3.fromRGB(232, 128, 84) -- warm brick walks
local HEDGE = Color3.fromRGB(84, 184, 70)
local SOIL = Color3.fromRGB(122, 90, 62)
local SAND = Color3.fromRGB(252, 234, 190)
local SEABED = Color3.fromRGB(150, 214, 230)
local DEEP = Color3.fromRGB(36, 104, 190)
local WATER = Color3.fromRGB(70, 156, 232)
local BARK = Color3.fromRGB(176, 126, 82)
local BARK_DARK = Color3.fromRGB(150, 104, 66)
local LEAF = Color3.fromRGB(84, 192, 70)
local LEAF_LIGHT = Color3.fromRGB(132, 218, 92)

-- The island: grass out to here, then the beach, then the shallows, then the deep sea.
TownMap.IslandX = 1100 -- grass from -IslandX to IslandX
TownMap.IslandN = 940 -- and from -IslandS to IslandN (the hills run up to the north shore)
TownMap.IslandS = 292
TownMap.Beach = 38
TownMap.Shallows = 92
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
local function palm(
	r: R,
	ox: number,
	oy: number,
	oz: number,
	h: number,
	lean: number,
	yaw: number,
	spread: number?,
	far: boolean?
)
	local dir = Vector3.new(math.cos(math.rad(yaw)), 0, math.sin(math.rad(yaw)))
	-- (`far` palms, out on the islets, are drawn with fewer pieces)
	local segs = if far then 3 else 5
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
	if not far then
		for k = 0, 1 do
			local a = math.rad(yaw + 60 + k * 180)
			r:ball(top.X + math.cos(a) * 0.7, top.Y - 0.5, top.Z + math.sin(a) * 0.7, 0.85, BARK_DARK, "SmoothPlastic")
		end
	end
	local fronds = if far then 5 else 7
	for f = 0, fronds - 1 do
		local a = math.rad(yaw + f * 360 / fronds + (f % 2) * 12)
		local out = Vector3.new(math.cos(a), 0, math.sin(a))
		local color = if f % 2 == 0 then LEAF else LEAF_LIGHT
		local reach = (if f % 2 == 0 then 2.3 else 1.9) * (spread or 1)
		local p0 = top + Vector3.new(0, 0.4, 0)
		-- two pieces a frond: up and out, then drooping
		for _, k in { 1.4, 3 } do
			local p1 = top + out * (k * reach * 1.3) + Vector3.new(0, 1.1 * k - 0.62 * k * k + 0.4, 0)
			r:beam(p0, p1, 2.6 - k * 0.55, 0.26, color, "SmoothPlastic")
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

-- A little boat: a white hull with a coloured stripe and a pointed bow, a small cabin. Every
-- piece is named `name`, so the client bobs the boat as one.
local function boat(r: R, x: number, z: number, yaw: number, stripe: Color3, name: string)
	local frame = CFrame.new(x, TownMap.WaterY, z) * CFrame.Angles(0, math.rad(yaw), 0)
	local white = Color3.fromRGB(250, 250, 250)
	local parts = {
		r:boxAt(frame * CFrame.new(0, 0.3, 0), 3.4, 1.4, 7, white, "SmoothPlastic"),
		r:boxAt(frame * CFrame.new(0, 0.55, 0), 3.5, 0.3, 7.05, stripe, "SmoothPlastic"),
		r:wedge(frame * CFrame.new(0, 0.3, -4.75), 3.4, 1.4, 2.5, white, "SmoothPlastic"),
		r:boxAt(frame * CFrame.new(0, 1.5, 0.8), 2.4, 1.2, 2.8, white, "SmoothPlastic"),
		r:boxAt(frame * CFrame.new(0, 1.6, -0.62), 2.2, 0.7, 0.06, Color3.fromRGB(120, 190, 240), "Glass"),
		r:boxAt(frame * CFrame.new(0, 2.15, 0.8), 2.6, 0.12, 3, stripe, "SmoothPlastic"),
	}
	for _, prim in parts do
		prim.name = name
		prim.collide = false
	end
end

-- A marina on the beach: a boardwalk out over the water on posts, finger piers between the
-- berths, and moored boats.
TownMap.Models.marina = function(r: R)
	local deck = Color3.fromRGB(214, 170, 120)
	local post = Color3.fromRGB(160, 120, 84)
	local y = 0.3
	-- the main walk, from the sand out over the water (local -Z is out to sea)
	r:block(-3, y - 0.4, -70, 3, y, 4, deck, "WoodPlanks")
	for z = -68, 2, 10 do
		for _, x in { -2.6, 2.6 } do
			r:cyl(x, -2.2, z, 5, 0.8, "y", post, "Wood")
		end
	end
	-- the head of the pier, across the end
	r:block(-26, y - 0.4, -76, 26, y, -70, deck, "WoodPlanks")
	-- finger piers off both sides, with a boat in most berths
	local stripes = {
		Color3.fromRGB(64, 150, 232),
		Color3.fromRGB(255, 108, 98),
		Color3.fromRGB(86, 198, 74),
		Color3.fromRGB(255, 190, 50),
	}
	local n = 0
	for _, side in { -1, 1 } do
		for k, z in { -18, -36, -54 } do
			local x1, x2 = if side < 0 then -20 else 3, if side < 0 then -3 else 20
			r:block(x1, y - 0.4, z - 1.2, x2, y, z + 1.2, deck, "WoodPlanks")
			r:cyl((x1 + x2) / 2 + side * 7, -2.2, z, 5, 0.7, "y", post, "Wood")
			if (k + (if side > 0 then 1 else 0)) % 3 ~= 0 then
				n += 1
				boat(r, side * 11.5, z - 8.2, 0, stripes[(n - 1) % #stripes + 1], "Boat" .. n)
			end
		end
	end
	-- a couple of benches and a lamp at the head
	for _, x in { -18, 18 } do
		r:block(x - 2, y, -74.6, x + 2, y + 1, -73.4, Color3.fromRGB(190, 140, 96), "Wood")
	end
end

-- A little island out at sea: sand rising out of the deep, a grassy top and a few palms.
TownMap.Models.islet = function(r: R)
	r:cyl(0, -7, 0, 18, 64, "y", SAND, "Sand")
	r:cyl(0, 2.1, 0, 0.4, 44, "y", GRASS, "Grass")
	palm(r, -6, 2.3, 4, 16, 3, 140, nil, true)
	palm(r, 7, 2.3, -3, 13, 2.6, 330, nil, true)
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

TownMap.Models.streetTreeLow = function(r: R)
	-- a square planter with a white kerb and a round low poly tree
	r:block(-1.8, 0, -1.8, 1.8, 0.45, -1.4, CURB, "Concrete")
	r:block(-1.8, 0, 1.4, 1.8, 0.45, 1.8, CURB, "Concrete")
	r:block(-1.8, 0, -1.4, -1.4, 0.45, 1.4, CURB, "Concrete")
	r:block(1.4, 0, -1.4, 1.8, 0.45, 1.4, CURB, "Concrete")
	r:block(-1.4, 0, -1.4, 1.4, 0.3, 1.4, SOIL, "Ground")
	CityModels.lowTree(r, 0, 0.3, 0, 1)
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
		-- the newer kits first: street buildings from the facade kit, then the set pieces
		local made = Facades.prims(name) or Landmarks.prims(name)
		if made then
			return made
		end
		-- (the street scene first: its billboard takes the place of the older one)
		local street = StreetModels.prims(name)
		if street then
			return street
		end
		local city = CityModels.prims(name)
		if city then
			return city
		end
		local detail = DetailModels.prims(name)
		if detail then
			return detail
		end
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

-- Which roads cross a road, and where: for a road along x, the x of every road along z whose run
-- covers its z (and the other way round), as { at, half width, sidewalk, neg = the other road goes
-- on to the negative side, pos = to the positive side }.
local function crossings(road: any): { any }
	local out: { any } = {}
	local horizontal = road[2] == road[4]
	for _, o in Town.Roads do
		if o ~= road then
			local oh = o[2] == o[4]
			if oh ~= horizontal then
				if horizontal then
					local x, z = o[1], road[2]
					if
						x >= math.min(road[1], road[3]) - 1
						and x <= math.max(road[1], road[3]) + 1
						and z >= math.min(o[2], o[4]) - 1
						and z <= math.max(o[2], o[4]) + 1
					then
						local lo, hi = math.min(o[2], o[4]), math.max(o[2], o[4])
						table.insert(out, { x, o[5], o[6], neg = lo < z - 1, pos = hi > z + 1 })
					end
				else
					local z, x = o[2], road[1]
					if
						z >= math.min(road[2], road[4]) - 1
						and z <= math.max(road[2], road[4]) + 1
						and x >= math.min(o[1], o[3]) - 1
						and x <= math.max(o[1], o[3]) + 1
					then
						local lo, hi = math.min(o[1], o[3]), math.max(o[1], o[3])
						table.insert(out, { z, o[5], o[6], neg = lo < x - 1, pos = hi > x + 1 })
					end
				end
			end
		end
	end
	table.sort(out, function(a, b)
		return a[1] < b[1]
	end)
	return out
end
TownMap.crossings = crossings

-- The whole island as one list of flat parts: the sea, the beach and the grass; every road with
-- its sidewalks, lane lines and crossings; the square and the market; the boardwalk; downtown's
-- paved blocks; the path up the hills; and the hills themselves.
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
			r:block(a, y1, b, c, y2, d, color, if mat == "" then "SmoothPlastic" else mat)
		end
	end

	-- the island: grass, a sandy beach round it, sand under the shallows, the deep sea floor, and
	-- the water over all of it (see through, so the shallows show light and the deep sea dark)
	local IX, IN, IS, B, SH = TownMap.IslandX, TownMap.IslandN, TownMap.IslandS, TownMap.Beach, TownMap.Shallows
	local WY = TownMap.WaterY
	slab(-IX, -IS, IX, IN, -2.1, -0.1, GRASS, "Grass")
	slab(-IX - B, -IS - B, IX + B, IN + B, -2.6, -0.35, SAND, "Sand")
	slab(-IX - B - SH, -IS - B - SH, IX + B + SH, IN + B + SH, -4, -2.5, SEABED, "Sand")
	local FAR = 3000
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
	-- a softer coastline: round capes of sand out into the shallows, and grassy headlands over the
	-- sand on the east, west and north shores (the south has the boardwalk)
	do
		local coast = Rng.new(73)
		local function disc(x: number, z: number, radius: number, top: number, color: Color3, mat: string)
			if
				region
				and (
					x < region[1] - radius
					or x > region[3] + radius
					or z < region[2] - radius
					or z > region[4] + radius
				)
			then
				return
			end
			r:cyl(x, top - 1.1, z, 2.2, radius * 2, "y", color, mat)
		end
		local x = -IX
		while x < IX do
			disc(x, IN + B, coast:float(26, 56), -0.36, SAND, "Sand")
			disc(x + coast:float(-20, 20), -IS - B, coast:float(22, 44), -0.36, SAND, "Sand")
			disc(x + coast:float(-20, 20), IN, coast:float(18, 40), -0.11, GRASS, "Grass")
			x += coast:float(70, 120)
		end
		local z = -IS
		while z < IN do
			for _, sx in { 1, -1 } do
				disc(sx * (IX + B), z + coast:float(-20, 20), coast:float(26, 52), -0.36, SAND, "Sand")
				if z > -200 then
					disc(sx * IX, z + coast:float(-20, 20), coast:float(16, 34), -0.11, GRASS, "Grass")
				end
			end
			z += coast:float(70, 120)
		end
	end
	-- walls nobody sees at the edge of the shallows, so nobody wanders off into the deep
	local EX, EN, ES = IX + B + SH, IN + B + SH, IS + B + SH
	for _, w in
		{
			{ -EX - 2, -ES - 2, EX + 2, -ES },
			{ -EX - 2, EN, EX + 2, EN + 2 },
			{ -EX - 2, -ES, -EX, EN },
			{ EX, -ES, EX + 2, EN },
		}
	do
		local a, b, c, d = clip(region, w[1], w[2], w[3], w[4])
		if a then
			local wall = r:block(a, -4, b, c, 60, d, WATER, "SmoothPlastic")
			wall.transp = 1
			wall.name = "SeaWall"
		end
	end

	-- the roads: tarmac, a dashed middle line (yellow on the main street), sidewalks with a curb,
	-- cut where another road crosses, corner squares at every junction, zebra crossings by them
	for _, road in Town.Roads do
		local hw, sw = road[5], road[6]
		local horizontal = road[2] == road[4]
		local main = road.name == "Main Street"
		local a1, a2 = math.min(road[1], road[3]), math.max(road[1], road[3])
		if not horizontal then
			a1, a2 = math.min(road[2], road[4]), math.max(road[2], road[4])
		end
		local at = if horizontal then road[2] else road[1]
		-- (x along, z across) to world for this road
		local function rect(
			u1: number,
			v1: number,
			u2: number,
			v2: number,
			y1: number,
			y2: number,
			col: Color3,
			mat: string?
		)
			if horizontal then
				slab(u1, at + v1, u2, at + v2, y1, y2, col, mat or "")
			else
				slab(at + v1, u1, at + v2, u2, y1, y2, col, mat or "")
			end
		end
		local cross = crossings(road)
		local function nearCross(u: number, extra: number): boolean
			for _, c in cross do
				if math.abs(u - c[1]) < c[2] + c[3] + extra then
					return true
				end
			end
			return false
		end
		rect(a1, -hw, a2, hw, -0.15, 0.05, ROAD, "Asphalt")
		-- dashes down the middle
		local step = if main then 14 else 20
		local u = a1 + 6
		while u < a2 - 10 do
			if not nearCross(u + 3.5, 6) and not (main and (math.abs(u) < 14 or math.abs(math.abs(u) - 274) < 14)) then
				rect(u, -0.3, u + 7, 0.3, 0.05, 0.08, if main then LINE_YELLOW else LINE_WHITE)
			end
			u += step
		end
		-- a manhole cover in one lane and a drain at the kerb, every so often
		local m, turn = a1 + 46, 0
		while m < a2 - 40 do
			if not nearCross(m, 12) and not nearCross(m + 30, 12) then
				local v = if turn % 2 == 0 then hw * 0.45 else -hw * 0.45
				rect(m - 1.5, v - 1.5, m + 1.5, v + 1.5, 0.05, 0.085, MANHOLE, "Metal")
				rect(m + 28.4, hw - 1.2, m + 31.6, hw - 0.2, 0.05, 0.085, MANHOLE, "Metal")
			end
			m += 118
			turn += 1
		end
		-- sidewalks, cut at junctions on the side the other road goes on to
		for _, side in { 1, -1 } do
			local stops = { a1 }
			for _, c in cross do
				if (side > 0 and c.pos) or (side < 0 and c.neg) then
					table.insert(stops, c[1] - c[2] - c[3])
					table.insert(stops, c[1] + c[2] + c[3])
				end
			end
			table.insert(stops, a2)
			for k = 1, #stops - 1, 2 do
				local s1, s2 = math.max(stops[k], a1), math.min(stops[k + 1], a2)
				if s2 > s1 then
					local v1, v2 = side * hw, side * (hw + sw)
					rect(s1, math.min(v1, v2), s2, math.max(v1, v2), -0.15, 0.3, WALK, "Pavement")
					local c1, c2 = side * hw, side * (hw + 0.6)
					rect(s1, math.min(c1, c2), s2, math.max(c1, c2), 0.3, 0.42, CURB, "Concrete")
				end
			end
		end
		-- zebra crossings just outside each junction, and corner squares (drawn once, by roads along x)
		for _, c in cross do
			for _, dir in { -1, 1 } do
				local u0 = c[1] + dir * (c[2] + c[3] + 4)
				if u0 > a1 + 4 and u0 < a2 - 4 then
					local v = -hw + 1.6
					while v < hw - 2.6 do
						if horizontal then
							slab(u0 - 3, at + v, u0 + 3, at + v + 1.6, 0.05, 0.08, LINE_WHITE, "")
						else
							slab(at + v, u0 - 3, at + v + 1.6, u0 + 3, 0.05, 0.08, LINE_WHITE, "")
						end
						v += 2.8
					end
				end
			end
			if horizontal then
				for _, dx in { -1, 1 } do
					for _, dz in { -1, 1 } do
						if (dz > 0 and not c.pos) or (dz < 0 and not c.neg) then
							continue
						end
						local x1 = c[1] + dx * c[2]
						local x2 = c[1] + dx * (c[2] + c[3])
						local z1 = at + dz * hw
						local z2 = at + dz * (hw + sw)
						if c[1] + dx * c[2] > a1 - 1 and c[1] + dx * c[2] < a2 + 1 then
							slab(
								math.min(x1, x2),
								math.min(z1, z2),
								math.max(x1, x2),
								math.max(z1, z2),
								-0.15,
								0.3,
								WALK,
								"Pavement"
							)
						end
					end
				end
			end
		end
		-- the main street's own crossings in front of the square, the market and between the plots
		if main then
			for _, cx in { 0, -274, 274 } do
				local v = -hw + 2.2
				while v < hw - 2.6 do
					slab(cx - 6, v, cx + 6, v + 1.6, 0.05, 0.08, LINE_WHITE, "")
					v += 2.8
				end
			end
		end
	end

	-- the square (north) and the market (south): paving with a border and a grid of joints
	for _, center in { Town.SquareCenter, Town.MarketCenter } do
		local x1, x2 = center.X - 50, center.X + 50
		local z1 = if center.Z > 0 then HW + SW else center.Z - 60
		local z2 = if center.Z > 0 then center.Z + 60 else -(HW + SW)
		slab(x1, z1, x2, z2, -0.15, 0.25, PAVING_DARK, "Pavement")
		slab(x1 + 1.2, z1 + 1.2, x2 - 1.2, z2 - 1.2, -0.15, 0.27, PAVING, "Pavement")
		local jz1 = if center.Z > 0 then HW + SW + 1.2 else center.Z - 58.8
		local jz2 = if center.Z > 0 then center.Z + 58.8 else -(HW + SW + 1.2)
		for gx = center.X - 48, center.X + 48, 12 do
			slab(gx - 0.12, jz1, gx + 0.12, jz2, 0.27, 0.28, PAVING_DARK, "Pavement")
		end
		for _, sx in { -1, 1 } do
			local x = center.X + sx * 45
			slab(x - 3, jz1, x + 3, jz2, 0.27, 0.285, PROMENADE, "Brick")
		end
	end
	-- brick walks from the crossing to the fountain and to the hall, and on to the ring roads
	slab(-5, HW + SW, 5, Town.Spots.Fountain.Z - 16, 0.27, 0.29, PROMENADE, "Brick")
	slab(-5, Town.Spots.Hall.Z + 14, 5, -(HW + SW), 0.27, 0.29, PROMENADE, "Brick")
	local RZ = Town.RingZ
	slab(-6, Town.SquareCenter.Z + 60, 6, RZ - 17, -0.15, 0.27, PAVING, "Pavement")
	slab(-6, -(RZ - 17), 6, Town.MarketCenter.Z - 60, -0.15, 0.27, PAVING, "Pavement")
	slab(-3, Town.SquareCenter.Z + 60, 3, RZ - 17, 0.27, 0.29, PROMENADE, "Brick")
	slab(-3, -(RZ - 17), 3, Town.MarketCenter.Z - 60, 0.27, 0.29, PROMENADE, "Brick")
	-- a round of lighter paving and a ring of dark stone around the fountain
	if not region or (region[1] < 20 and region[3] > -20 and region[2] < 100 and region[4] > 60) then
		local f = Town.Spots.Fountain
		r:cyl(f.X, 0.28, f.Z, 0.04, 36, "y", PAVING_DARK, "Pavement")
		r:cyl(f.X, 0.29, f.Z, 0.04, 34, "y", Color3.fromRGB(234, 222, 200), "Pavement")
	end
	-- lawns in the square's corners
	for _, l in TownMap.lawns() do
		local cx, cz, hx, hz = l[1], l[2], l[3], l[4]
		slab(cx - hx, cz - hz, cx + hx, cz + hz, -0.15, 0.32, GRASS, "Grass")
		slab(cx - hx - 0.5, cz - hz - 0.5, cx + hx + 0.5, cz - hz, -0.15, 0.6, CURB, "Concrete")
		slab(cx - hx - 0.5, cz + hz, cx + hx + 0.5, cz + hz + 0.5, -0.15, 0.6, CURB, "Concrete")
		slab(cx - hx - 0.5, cz - hz, cx - hx, cz + hz, -0.15, 0.6, CURB, "Concrete")
		slab(cx + hx, cz - hz, cx + hx + 0.5, cz + hz, -0.15, 0.6, CURB, "Concrete")
	end

	-- downtown's blocks are paved right up to the sidewalks
	-- with a cobbled lane through the middle of each and a darker band round its edge
	for _, b in TownMap.blocks("east") do
		slab(b[1], b[2], b[3], b[4], -0.15, 0.22, PAVING, "Pavement")
		local mid = (b[2] + b[4]) / 2
		slab(b[1] + 8, mid - 5, b[3] - 8, mid + 5, 0.22, 0.25, LANE, "Cobblestone")
		slab(b[1] + 3, b[2] + 3, b[3] - 3, b[2] + 5.4, 0.22, 0.25, PAVING_DARK, "Pavement")
		slab(b[1] + 3, b[4] - 5.4, b[3] - 3, b[4] - 3, 0.22, 0.25, PAVING_DARK, "Pavement")
		slab(b[1] + 3, b[2] + 5.4, b[1] + 5.4, b[4] - 5.4, 0.22, 0.25, PAVING_DARK, "Pavement")
		slab(b[3] - 5.4, b[2] + 5.4, b[3] - 3, b[4] - 5.4, 0.22, 0.25, PAVING_DARK, "Pavement")
	end
	-- the civic quarter's lawns have gravel paths: one along each block and two across
	for _, b in TownMap.blocks("west") do
		local mid = (b[2] + b[4]) / 2
		slab(b[1], mid - 2.5, b[3], mid + 2.5, 0, 0.07, GRAVEL, "Pavement")
		for _, t in { 0.3, 0.7 } do
			local x = b[1] + (b[3] - b[1]) * t
			slab(x - 2, b[2], x + 2, b[4], 0, 0.07, GRAVEL, "Pavement")
		end
	end

	-- the boardwalk along the south shore, with a rail on the sea side
	local bz1, bz2 = -IS, -(RZ + 11 + 6)
	slab(-IX + 30, bz1, IX - 30, bz2, -0.15, 0.32, Color3.fromRGB(214, 172, 124), "WoodPlanks")
	slab(-IX + 30, bz1, IX - 30, bz1 + 0.5, 0.32, 2.6, Color3.fromRGB(250, 250, 246), "SmoothPlastic")

	-- a path of flat stones up the hills from Hill Road to the lookout, winding a little
	do
		local z = RZ + 18
		local top = Hills.Plateaus[1]
		while z < top.z - top.r do
			local t = (z - RZ) / (top.z - RZ)
			local x = math.sin(t * math.pi * 2.2) * 40 * (1 - t)
			if not region or (x >= region[1] and x <= region[3] and z >= region[2] and z <= region[4]) then
				local y = math.max(Hills.at(x, z), 0) + 0.05
				r:cyl(x, y, z, 0.3, 4.2, "y", Color3.fromRGB(226, 216, 196), "SmoothPlastic")
			end
			z += 7
		end
	end

	-- and the hills themselves
	for _, p in Hills.prims(region) do
		r:add(p)
	end
	-- what is laid flat on top: paving patterns, markings, covers
	for _, p in StreetPaint.ground(region) do
		r:add(p)
	end
	return r.prims
end

-- The city blocks between the roads east (downtown) or west (the civic quarter) of the old town:
-- { x1, z1, x2, z2 } inside the sidewalks.
function TownMap.blocks(side: string): { { number } }
	local sx = if side == "east" then 1 else -1
	local xs = { { 559, 813 }, { 847, 1053 } }
	local zs = { { 148, 245 }, { 22, 114 }, { -114, -22 }, { -245, -148 } }
	local out = {}
	for _, x in xs do
		for _, z in zs do
			local x1, x2 = sx * x[1], sx * x[2]
			table.insert(out, { math.min(x1, x2), z[1], math.max(x1, x2), z[2] })
		end
	end
	return out
end

-- What stands on the ground ---------------------------------------------------------------------------

export type Placement = { name: string, cf: CFrame, action: string?, opens: string?, tag: string? }

-- The street scene ------------------------------------------------------------------------------------
--
-- The user asked for the town to read as a dense modern city: drinks machines, utility poles and
-- their wires, air conditioners on the walls, tanks and aerials on the roofs, billboards, posters
-- and the clutter of a pavement (Data/StreetModels). All of it goes on last, so nothing that stood
-- before has moved, and a thing only goes where its parts are clear of every part already there.
-- It is seeded, so it is the same town every time.

type Box = { number } -- x1, y1, z1, x2, y2, z2
type Shape = { all: Box, foot: Box?, boxes: { Box }, prims: { Prim } }
type Wall = { x: number, z: number, dx: number, dz: number, nx: number, nz: number, len: number, top: number }
type Shell = { walls: { Wall }, x1: number, x2: number, front: number, body: Box?, roof: Box? }

-- What a model takes up, worked out once: a box round all of it, one round what stands on the
-- ground (anything overhead left out), and one for every part.
local shapes: { [string]: Shape } = {}
local function shapeOf(name: string): Shape
	local s = shapes[name]
	if not s then
		local prims = TownMap.prims(name)
		local lo, hi = Geometry.bounds(prims)
		local boxes = table.create(#prims)
		local foot: Box? = nil
		for i, p in prims do
			local a, b = Geometry.bounds({ p })
			boxes[i] = { a.X, a.Y, a.Z, b.X, b.Y, b.Z }
			if a.Y < 6 then
				if foot then
					foot[1], foot[3] = math.min(foot[1], a.X), math.min(foot[3], a.Z)
					foot[4], foot[6] = math.max(foot[4], b.X), math.max(foot[6], b.Z)
					foot[5] = math.max(foot[5], b.Y)
				else
					foot = { a.X, a.Y, a.Z, b.X, b.Y, b.Z }
				end
			end
		end
		s = { all = { lo.X, lo.Y, lo.Z, hi.X, hi.Y, hi.Z }, foot = foot, boxes = boxes, prims = prims }
		shapes[name] = s
	end
	return s
end

-- A model space box moved by a placement's frame (placements only ever turn about Y).
local function moved(cf: CFrame, b: Box): Box
	local px, py, pz, r00, _, r02, _, _, _, r20, _, r22 = cf:GetComponents()
	local ax, bx, cx, dx = r00 * b[1], r00 * b[4], r02 * b[3], r02 * b[6]
	local az, bz, cz, dz = r20 * b[1], r20 * b[4], r22 * b[3], r22 * b[6]
	return {
		px + math.min(ax, bx) + math.min(cx, dx),
		py + b[2],
		pz + math.min(az, bz) + math.min(cz, dz),
		px + math.max(ax, bx) + math.max(cx, dx),
		py + b[5],
		pz + math.max(az, bz) + math.max(cz, dz),
	}
end

-- The yaw that turns a model's front (local -Z) to look along (nx, nz).
local function facing(nx: number, nz: number): number
	return math.deg(math.atan2(-nx, -nz))
end

-- A building's shell, read from its parts: the outside walls of its ground floor (upright slabs
-- at least 10 long and 6 high, standing on the ground at the edge of the footprint), where its
-- front is, the block of storeys over the ground floor, and its flat roof if it has one.
-- Everything hung on a wall or stood on a roof is placed from this, so it is only ever put where
-- a wall or a roof really is.
local shells: { [string]: Shell } = {}
local function shellOf(name: string): Shell
	local found = shells[name]
	if found then
		return found
	end
	local s = shapeOf(name)
	local slabs: { Box } = {}
	local x1, z1, x2, z2 = math.huge, math.huge, -math.huge, -math.huge
	for i, p in s.prims do
		local b = s.boxes[i]
		local sx, sy, sz = b[4] - b[1], b[5] - b[2], b[6] - b[3]
		local solid = p.shape == "Block" and (p.transp or 0) < 0.2 and p.mat ~= "Glass"
		-- (square to the model: its own box is the box round it)
		local square = math.abs(sx * sy * sz - p.size.X * p.size.Y * p.size.Z) < 0.01 * sx * sy * sz
		if solid and square and b[2] <= 1 and sy >= 6 and math.min(sx, sz) <= 1.2 and math.max(sx, sz) >= 10 then
			table.insert(slabs, b)
			x1, z1, x2, z2 = math.min(x1, b[1]), math.min(z1, b[3]), math.max(x2, b[4]), math.max(z2, b[6])
		end
	end
	local walls: { Wall } = {}
	for _, b in slabs do
		local along = b[4] - b[1] > b[6] - b[3]
		if along and math.abs(b[6] - z2) < 0.05 then
			table.insert(walls, { x = b[1], z = b[6], dx = 1, dz = 0, nx = 0, nz = 1, len = b[4] - b[1], top = b[5] })
		elseif not along and math.abs(b[4] - x2) < 0.05 then
			table.insert(walls, { x = b[4], z = b[3], dx = 0, dz = 1, nx = 1, nz = 0, len = b[6] - b[3], top = b[5] })
		elseif not along and math.abs(b[1] - x1) < 0.05 then
			table.insert(walls, { x = b[1], z = b[3], dx = 0, dz = 1, nx = -1, nz = 0, len = b[6] - b[3], top = b[5] })
		end
	end
	-- the roof: the highest slab as wide as the building, or a deck laid over most of that slab
	-- (a roof garden's lawn)
	local roof: Box? = nil
	local w, d = s.all[4] - s.all[1], s.all[6] - s.all[3]
	local least = 0
	for pass = 1, 2 do
		for i, p in s.prims do
			local b = s.boxes[i]
			local sx, sz = b[4] - b[1], b[6] - b[3]
			if p.shape == "Block" and (p.transp or 0) < 0.2 and b[5] >= 8 then
				local wide = if pass == 1 then sx >= 0.8 * w and sz >= 0.8 * d else sx * sz >= least
				if wide and (roof == nil or b[5] > roof[5]) then
					roof = b
				end
			end
		end
		if not roof then
			break
		end
		least = 0.7 * (roof[4] - roof[1]) * (roof[6] - roof[3])
	end
	-- the storeys over the ground floor: the biggest block that starts above head height
	local body: Box? = nil
	local most = 0
	for i, p in s.prims do
		local b = s.boxes[i]
		local sx, sy, sz = b[4] - b[1], b[5] - b[2], b[6] - b[3]
		local solid = p.shape == "Block" and (p.transp or 0) < 0.2
		if solid and b[2] >= 6 and sx >= 10 and sz >= 10 and sy >= 4 and sx * sy * sz > most then
			body = b
			most = sx * sy * sz
		end
	end
	local shell: Shell = { walls = walls, x1 = x1, x2 = x2, front = z1, body = body, roof = roof }
	shells[name] = shell
	return shell
end

local sceneCache: { Placement }? = nil

local function streetScene(standing: { Placement }): { Placement }
	local added: { Placement } = {}

	-- Everything standing in town, sorted into a grid of cells: each with a box round all of it
	-- and, worked out when something comes near, a box for every part.
	type Solid = { name: string, cf: CFrame, box: Box, parts: { Box }? }
	local CELL = 48
	local cells: { [number]: { Solid } } = {}
	local function stand(name: string, cf: CFrame)
		local solid: Solid = { name = name, cf = cf, box = moved(cf, shapeOf(name).all) }
		local b = solid.box
		for cx = math.floor(b[1] / CELL), math.floor(b[4] / CELL) do
			for cz = math.floor(b[3] / CELL), math.floor(b[6] / CELL) do
				local key = (cx + 512) * 1024 + cz + 512
				local cell = cells[key]
				if not cell then
					cell = {}
					cells[key] = cell
				end
				table.insert(cell, solid)
			end
		end
	end
	for _, p in standing do
		local z = p.cf.Position.Z
		if p.tag ~= "backdrop" and z > -310 and z < 290 then
			stand(p.name, p.cf)
		end
	end
	local function partsOf(solid: Solid): { Box }
		local parts = solid.parts
		if parts then
			return parts
		end
		local made: { Box } = {}
		for i, b in shapeOf(solid.name).boxes do
			made[i] = moved(solid.cf, b)
		end
		solid.parts = made
		return made
	end
	-- Calls `visit` with every part whose box overlaps (x1, z1)-(x2, z2) on the ground; stops when it
	-- returns true.
	local NONE: { Solid } = {}
	local function over(x1: number, z1: number, x2: number, z2: number, visit: (Box) -> boolean): boolean
		for cx = math.floor(x1 / CELL), math.floor(x2 / CELL) do
			for cz = math.floor(z1 / CELL), math.floor(z2 / CELL) do
				local cell: { Solid } = cells[(cx + 512) * 1024 + cz + 512] or NONE
				for _, solid in cell do
					local sb = solid.box
					if sb[1] < x2 and sb[4] > x1 and sb[3] < z2 and sb[6] > z1 then
						for _, q in partsOf(solid) do
							if q[1] < x2 and q[4] > x1 and q[3] < z2 and q[6] > z1 and visit(q) then
								return true
							end
						end
					end
				end
			end
		end
		return false
	end
	-- Does anything reach into this box? Flat things underfoot (paving, a lawn) don't count:
	-- `floor` is the ground the box stands on.
	local function hits(b: Box, floor: number): boolean
		return over(b[1], b[3], b[4], b[6], function(q)
			return q[2] < b[5] and q[5] > b[2] and q[5] > floor + 0.35
		end)
	end

	-- Ground nothing may stand on: the roads, the players' plots, the spawn and the festival spot.
	local half = Tuning.Plot.Size / 2
	local function offLimits(b: Box): boolean
		for _, road in Town.Roads do
			local hw = road[5] + 0.3
			if
				b[4] > math.min(road[1], road[3]) - hw
				and b[1] < math.max(road[1], road[3]) + hw
				and b[6] > math.min(road[2], road[4]) - hw
				and b[3] < math.max(road[2], road[4]) + hw
			then
				return true
			end
		end
		for i = 1, Tuning.Plot.Count do
			local c = Town.plotCenter(i)
			local reach = half - 0.4
			if b[4] > c.X - reach and b[1] < c.X + reach and b[6] > c.Z - reach and b[3] < c.Z + reach then
				return true
			end
		end
		for _, spot in { Town.Spots.Spawn, Town.Spots.Festival } do
			if b[4] > spot.X - 6 and b[1] < spot.X + 6 and b[6] > spot.Z - 6 and b[3] < spot.Z + 6 then
				return true
			end
		end
		return false
	end

	-- The whole scene keeps to a budget of parts, whatever the buildings turn out to have room
	-- for: once it is spent, nothing more goes down.
	local BUDGET = 1940
	local spent = 0
	local function add(name: string, cf: CFrame): boolean
		local cost = #shapeOf(name).boxes
		if spent + cost > BUDGET then
			return false
		end
		spent += cost
		table.insert(added, { name = name, cf = cf })
		stand(name, cf)
		return true
	end
	-- Puts a model down if its parts are clear of everything. `room` asks for that many studs of
	-- empty pavement in front of it too (a drinks machine nobody can reach is no use).
	local function put(name: string, x: number, y: number, z: number, yaw: number, room: number?): boolean
		local cf = CFrame.new(x, y, z) * CFrame.Angles(0, math.rad(yaw), 0)
		local s = shapeOf(name)
		if spent + #s.boxes > BUDGET or (s.foot and offLimits(moved(cf, s.foot))) then
			return false
		end
		for _, lb in s.boxes do
			-- (drawn in a hair, so a thing may touch what it leans on or stands on)
			local b = moved(cf, lb)
			for axis = 1, 3 do
				local inset = math.min(0.05, (b[axis + 3] - b[axis]) / 2)
				b[axis], b[axis + 3] = b[axis] + inset, b[axis + 3] - inset
			end
			if hits(b, y) then
				return false
			end
		end
		if room then
			local a = s.all
			if hits(moved(cf, { a[1] + 0.1, 0.6, a[3] - room, a[4] - 0.1, 5, a[3] }), y) then
				return false
			end
		end
		return add(name, cf)
	end

	local SIDEWALK = 0.3
	local DOWNTOWN = 0.22
	local GRASS = -0.1

	-- Is `u` along a road where people step off the kerb to cross it? The zebra crossings just
	-- outside each junction, and the main street's own three.
	local function atCrossing(road: any, u: number): boolean
		for _, c in crossings(road) do
			for _, dir in { -1, 1 } do
				if math.abs(u - (c[1] + dir * (c[2] + c[3] + 4))) < 5 then
					return true
				end
			end
		end
		if road == Town.Roads[1] then
			for _, x in { 0, -274, 274 } do
				if math.abs(u - x) < 8 then
					return true
				end
			end
		end
		return false
	end

	-- Utility poles along a street's kerb at a regular spacing, the wires strung between them.
	-- `side` is which side of the road (1: north or east), `first` where the first pole goes.
	-- (The wires go up once every pole is standing, so one street's wires may cross another's.)
	local poles = Rng.new(52)
	local strung: { Placement } = {}
	local function poleLine(road: any, side: number, first: number, last: number, step: number)
		local horizontal = road[2] == road[4]
		local v = (if horizontal then road[2] else road[1]) + side * (road[5] + 1.5)
		local yaw = if horizontal then (if side > 0 then 0 else 180) else (if side > 0 then 90 else -90)
		local stood: { number } = {}
		for u = first, last, step do
			for _, nudge in { 0, 4, -4, 8, -8 } do
				local w = u + nudge
				local x, z = if horizontal then w else v, if horizontal then v else w
				if not atCrossing(road, w) and put("utilityPole", x, SIDEWALK, z, yaw) then
					table.insert(stood, w)
					-- now and then, the morning's rubbish at its foot
					if poles:chance(0.22) then
						local o = if poles:chance(0.5) then 2 else -2
						local back = v + side * 1.2
						put(
							"binBags",
							if horizontal then w + o else back,
							SIDEWALK,
							if horizontal then back else w + o,
							yaw + 180
						)
					end
					break
				end
			end
		end
		for i = 1, #stood - 1 do
			local a, b = stood[i], stood[i + 1]
			local len = b - a
			-- the wires hang from the pole whose own +X looks at the next one
			local from = if (horizontal and side > 0) or (not horizontal and side < 0) then a else b
			local cf = CFrame.new(if horizontal then from else v, SIDEWALK, if horizontal then v else from)
				* CFrame.Angles(0, math.rad(yaw), 0)
			if len <= 120 and not hits(moved(cf, { 1.5, 14, -2.2, len - 1.5, 19.4, 2.2 }), 0) then
				table.insert(strung, { name = string.format("wireSpan:%d", len), cf = cf })
			end
		end
	end
	local function roadAt(x1: number, z1: number, x2: number, z2: number): any
		for _, road in Town.Roads do
			if road[1] == x1 and road[2] == z1 and road[3] == x2 and road[4] == z2 then
				return road
			end
		end
		error("no such road")
	end
	local main = Town.Roads[1]
	local RZ, CZ = Town.RingZ, Town.CrossZ
	local AX = Town.AvenueX
	local hill, harbour = roadAt(-AX[3], RZ, AX[3], RZ), roadAt(-AX[3], -RZ, AX[3], -RZ)
	local firstAvenue, midAvenue = roadAt(AX[1], -RZ, AX[1], RZ), roadAt(AX[2], -RZ, AX[2], RZ)
	local crossNorth, crossSouth = roadAt(AX[1], CZ, AX[3], CZ), roadAt(AX[1], -CZ, AX[3], -CZ)
	-- (how far a side road's sidewalk reaches from its middle)
	local reach = hill[5] + hill[6]
	-- The whole length of the main street, and downtown's streets: its two avenues and its two
	-- cross streets. A pole every 68 studs, as the main street's lamps are, and half way between
	-- them.
	poleLine(main, 1, -986, 986, 68)
	poleLine(midAvenue, 1, -238, 238, 68)
	poleLine(firstAvenue, 1, -238, 238, 68)
	poleLine(crossNorth, 1, 578, 986, 68)
	poleLine(crossSouth, -1, 578, 986, 68)
	for _, span in strung do
		add(span.name, span.cf)
	end

	-- What the ground is at a spot: downtown's paving, a sidewalk, the boardwalk or grass.
	local function groundAt(x: number, z: number): number
		for _, b in TownMap.blocks("east") do
			if x >= b[1] and x <= b[3] and z >= b[2] and z <= b[4] then
				return DOWNTOWN
			end
		end
		for _, road in Town.Roads do
			local reach = road[5] + road[6]
			if
				x > math.min(road[1], road[3]) - reach
				and x < math.max(road[1], road[3]) + reach
				and z > math.min(road[2], road[4]) - reach
				and z < math.max(road[2], road[4]) + reach
			then
				return SIDEWALK
			end
		end
		if z < -(RZ + reach) and z > -TownMap.IslandS then
			return 0.32 -- the boardwalk
		end
		return GRASS
	end
	local function set(name: string, x: number, z: number, yaw: number, room: number?): boolean
		return put(name, x, groundAt(x, z), z, yaw, room)
	end
	local MACHINES = { "vendingMachine", "vendingMachine2", "vendingMachine3" }
	-- A row of drinks machines side by side from (x, z), the row running along local +X, and
	-- sometimes the bin for empties at the end of it.
	local function machines(x: number, z: number, yaw: number, count: number, first: number, bin: boolean)
		local along = CFrame.Angles(0, math.rad(yaw), 0) * Vector3.new(1, 0, 0)
		for k = 0, count - 1 do
			set(MACHINES[(first + k) % #MACHINES + 1], x + along.X * k * 3.6, z + along.Z * k * 3.6, yaw, 3)
		end
		if bin then
			set("canBin", x + along.X * (count * 3.6 - 0.7), z + along.Z * (count * 3.6 - 0.7), yaw)
		end
	end

	-- Big boards on a post: at the corners where the main street meets the first avenue, at two
	-- of downtown's junctions (side on to the street, so both ways read them), and on the seafront
	-- at the ends of the avenues.
	local edge = Town.StreetHalfWidth + Town.SidewalkWidth
	set("billboardTall", AX[1] - 28, edge + 12, 90)
	set("billboardTall", -(AX[1] - 28), -(edge + 12), 90)
	set("billboardTall", AX[2] + 24, -(edge + 9), 90)
	set("billboardTall", AX[2] + 25, CZ + 27, 90)
	for _, x in { AX[1] - 2, AX[2] - 6, -(AX[1] - 2) } do
		set("billboardTall", x, -(RZ + reach + 5), 0)
	end

	-- Hoardings of posters. Downtown, one beside the mouth of each lane, with a drinks machine
	-- beside some of them.
	local posters = Rng.new(58)
	local hoardings = 0
	for _, b in TownMap.blocks("east") do
		local mid = (b[2] + b[4]) / 2
		for _, e in { { b[1] + 2.2, 90, 1 }, { b[3] - 2.2, -90, -1 } } do
			-- (not the last avenue, out by the shore)
			if math.abs(e[1]) < AX[3] - 40 then
				hoardings += 1
				local name = if hoardings % 2 == 0 then "posterWall2" else "posterWall"
				local side = if hoardings % 3 == 0 then -1 else 1
				local ok = set(name, e[1], mid + side * 12.5, e[2])
				if not ok then
					side = -side
					ok = set(name, e[1], mid + side * 12.5, e[2])
				end
				if ok and posters:chance(0.35) then
					machines(e[1] - e[3] * 0.9, mid + side * 21.6, e[2], 1, hoardings, posters:chance(0.5))
				end
			end
		end
	end
	-- Round the old town, on the verge between the ring road's sidewalk and the hedges, and in the
	-- gaps between the plots on the main street.
	local verge = RZ - reach - 0.8
	for i, x in { -390, -130, 130, 390 } do
		set(if i % 2 == 0 then "posterWall2" else "posterWall", x, verge, 180)
		machines(x - 9.5, verge - 0.5, 180, 1, i, i % 2 == 0)
	end
	for i, x in { -260, 260 } do
		set(if i % 2 == 0 then "posterWall2" else "posterWall", x, -verge, 0)
		machines(x + 9.5, -verge + 0.5, 0, 1, i + 1, true)
	end
	set("posterWall", AX[1] - reach - 0.8, 120, -90)
	set("posterWall2", -(AX[1] - reach - 0.8), -120, 90)
	set("posterWall", 274, -(edge + 0.5), 180)
	set("posterWall", -274, edge + 0.5, 0)

	-- Drinks machines at the back of the main street's sidewalk: by the crossings between the
	-- plots, at the corners of the square and the market, and at either end of the old town.
	local back = edge - 1.3
	machines(270.2, back, 0, 2, 0, true)
	machines(-270.2, -back, 180, 2, 1, true)
	machines(56, back, 0, 1, 2, true)
	machines(-56, -back, 180, 1, 0, false)
	machines(496, -back, 180, 2, 1, false)
	machines(-496, back, 0, 2, 2, true)

	-- Telephone boxes: by the square, at a crossing, on a downtown corner and on the seafront.
	set("phoneBooth", -59, edge - 1.9, 0)
	set("phoneBooth", 287, -(edge - 1.9), 180)
	set("phoneBooth", AX[2] + 22, edge + 3, 0)
	set("phoneBooth", 334, -(RZ + reach + 9.3), 180)
	set("phoneBooth", -250, -(RZ + reach + 9.3), 180)

	-- Where an avenue crosses the main street, a street sign on the two corners that have no
	-- traffic light.
	for _, x in { AX[1], -AX[1], AX[2], -AX[2] } do
		local dx, dz = hill[5] + 1.6, Town.StreetHalfWidth + 1.6
		set("streetSignPost", x + dx, dz, 0)
		set("streetSignPost", x - dx, -dz, 180)
	end

	-- Buildings: what leans on their walls, hangs from them and stands on their roofs --------------
	type Face = { at: Vector3, dir: Vector3, n: Vector3, len: number, y1: number, y2: number }
	local HALLS = {
		cinema = true,
		station = true,
		library = true,
		museum = true,
		clinic = true,
		school = true,
		fireStation = true,
	}
	local function kindOf(name: string): string?
		if name == "shop" then
			return nil -- the old town's own shop, on the market
		elseif name:sub(1, 4) == "shop" or name == "deptStore" or name == "postOffice" then
			return "shop"
		elseif name:sub(1, 9) == "apartment" then
			return "flats"
		elseif name:sub(1, 6) == "office" or name == "hotel" or name == "skyTower" then
			return "tower"
		elseif HALLS[name] then
			return "hall"
		end
		return nil
	end
	-- Stands a model with its back to a wall, `s` along it from the wall's near end and `gap` out.
	local function lean(name: string, f: Face, s: number, gap: number?, room: number?): boolean
		local a = shapeOf(name).all
		local pos = f.at + f.dir * (s + (a[4] - a[1]) / 2) + f.n * (a[6] + (gap or 0.06))
		return put(name, pos.X, f.y1, pos.Z, facing(f.n.X, f.n.Z), room)
	end
	-- The free heights between y1 and y2 over a patch of ground: the gaps no part reaches into.
	local function gaps(x1: number, z1: number, x2: number, z2: number, y1: number, y2: number): { { number } }
		local taken: { { number } } = {}
		over(x1, z1, x2, z2, function(q)
			if q[5] > y1 and q[2] < y2 then
				table.insert(taken, { q[2], q[5] })
			end
			return false
		end)
		table.sort(taken, function(a, b)
			return a[1] < b[1]
		end)
		local free: { { number } } = {}
		local y = y1
		for _, t in taken do
			if t[1] > y then
				table.insert(free, { y, t[1] })
			end
			y = math.max(y, t[2])
		end
		if y2 > y then
			table.insert(free, { y, y2 })
		end
		return free
	end
	-- Hangs air conditioners on a wall `s` along it, one in each free height from y1 up (so on a
	-- tower they sit under the windows, floor after floor), `most` at the most.
	local AC = shapeOf("acUnit").all
	local function airCon(f: Face, s: number, y1: number, y2: number, most: number): number
		local c = f.at + f.dir * s
		local p1 = c - f.dir * ((AC[4] - AC[1]) / 2 + 0.3) + f.n * 0.07
		local p2 = c + f.dir * ((AC[4] - AC[1]) / 2 + 0.3) + f.n * (AC[6] - AC[3] + 0.2)
		local tall = AC[5] - AC[2]
		local hung = 0
		for _, g in gaps(math.min(p1.X, p2.X), math.min(p1.Z, p2.Z), math.max(p1.X, p2.X), math.max(p1.Z, p2.Z), y1, y2) do
			if hung < most and g[2] - g[1] >= tall + 0.08 then
				-- snug between two rows of windows, or low on a blank wall
				local y = if g[2] - g[1] < 3 then (g[1] + g[2] - tall) / 2 else g[1] + 0.6
				local at = c + f.n * 0.03
				local cf = CFrame.new(at.X, y, at.Z) * CFrame.Angles(0, math.rad(facing(f.n.X, f.n.Z)), 0)
				if add("acUnit", cf) then
					hung += 1
				end
			end
		end
		return hung
	end
	local LEFT_OUT = { "crateStack", "binBags", "drinksCrates", "crateStack" }
	local dress = Rng.new(64)
	for _, p in standing do
		local kind = kindOf(p.name)
		if kind then
			local shell = shellOf(p.name)
			local east = p.cf.Position.X > 0
			-- (the civic quarter is quieter than downtown, and its buildings stand on lawns)
			local busy = if east then 1 else 0.5
			local ground = p.cf.Y + (if east then 0 else 0.1)
			local function face(x: number, z: number, dx: number, dz: number, nx: number, nz: number): Face
				return {
					at = p.cf * Vector3.new(x, 0, z),
					dir = p.cf:VectorToWorldSpace(Vector3.new(dx, 0, dz)),
					n = p.cf:VectorToWorldSpace(Vector3.new(nx, 0, nz)),
					len = 0,
					y1 = ground,
					y2 = ground,
				}
			end
			local sides: { Face } = {}
			local backs: { Face } = {}
			for _, w in shell.walls do
				local f = face(w.x, w.z, w.dx, w.dz, w.nx, w.nz)
				f.len, f.y2 = w.len, p.cf.Y + w.top
				table.insert(if w.nz > 0 then backs else sides, f)
			end

			-- a drinks machine or two round the corner from the door, at the first clear stretch
			-- of a side wall (a poster may have the corner)
			if kind ~= "hall" and #sides > 0 and dress:chance(0.45 * busy) then
				local f = sides[dress:int(1, #sides)]
				local first = dress:int(1, #MACHINES)
				local s = 1.6
				while s < f.len - 5 and not lean(MACHINES[first], f, s, nil, 3) do
					s += 1.4
				end
				if s < f.len - 5 then
					s += 3.6
					if dress:chance(0.3) and lean(MACHINES[first % #MACHINES + 1], f, s, nil, 3) then
						s += 3.6
					end
					if dress:chance(0.35) then
						lean("canBin", f, s + 0.2)
					end
				end
			end
			-- behind: the air conditioning's big box, and crates or rubbish by the back door
			for _, f in backs do
				if dress:chance(0.55 * busy) then
					lean("condenser", f, dress:float(2, math.max(2, f.len - 6)))
				end
				if kind == "shop" and dress:chance(0.6 * busy) then
					lean(dress:pick(LEFT_OUT), f, dress:float(2, math.max(2, f.len - 5)))
				end
			end
			for _, f in sides do
				if dress:chance(0.3 * busy) then
					lean(dress:pick(LEFT_OUT), f, dress:float(10, math.max(10, f.len - 5)))
				end
			end
			-- out the front of a shop: a sandwich board on the pavement, crates under the window
			if kind == "shop" and east then
				local front = face(shell.x1, shell.front, 1, 0, 0, -1)
				local width = shell.x2 - shell.x1
				if dress:chance(0.6) then
					lean("aBoard", front, width / 2 + (if dress:chance(0.5) then 3.4 else -5.4), 2)
				end
				if dress:chance(0.4) then
					lean("drinksCrates", front, if dress:chance(0.5) then 1.4 else width - 5, 0.3)
				end
			end

			-- air conditioners: one low on a back or side wall, then up the storeys above
			local limit = if kind == "flats" then 5 elseif kind == "tower" then 3 elseif kind == "shop" then 2 else 1
			if not east then
				limit = math.ceil(limit / 2)
			end
			local hung = 0
			local low: { Face } = {}
			for _, f in backs do
				table.insert(low, f)
			end
			for _, f in sides do
				table.insert(low, f)
			end
			if #low > 0 and dress:chance(0.8) then
				local f = low[dress:int(1, #low)]
				if f.len > 7 then
					hung += airCon(f, dress:float(3, f.len - 3), ground + 6.1, f.y2 - 0.2, 1)
				end
			end
			local body = shell.body
			if body then
				local upper = {
					face(body[1], body[6], 1, 0, 0, 1),
					face(body[1], body[3], 0, 1, -1, 0),
					face(body[4], body[3], 0, 1, 1, 0),
				}
				upper[1].len, upper[2].len, upper[3].len = body[4] - body[1], body[6] - body[3], body[6] - body[3]
				local y1, y2 = p.cf.Y + body[2] + 0.2, p.cf.Y + body[5] - 0.6
				for _ = 1, 5 do
					if hung < limit then
						local f = upper[dress:int(1, 3)]
						local from = y1 + dress:float(0, 0.6) * (y2 - y1)
						local most = math.min(limit - hung, if kind == "shop" then 1 else 3)
						hung += airCon(f, dress:float(3, f.len - 3), from, y2, most)
					end
				end
			end

			-- the roof: a water tank and an aerial on a shop, aerials and dishes on flats, a mast
			-- with a red lamp on an office
			local roof = shell.roof
			if roof then
				local top = p.cf.Y + roof[5]
				local look = p.cf.LookVector
				local yaw = facing(look.X, look.Z)
				local function onRoof(name: string, chance: number)
					if not dress:chance(chance * busy) then
						return
					end
					local a = shapeOf(name).all
					local rx = (roof[4] - roof[1]) / 2 - 1.8 - (a[4] - a[1]) / 2
					local rz = (roof[6] - roof[3]) / 2 - 1.8 - (a[6] - a[3]) / 2
					if rx < 0 or rz < 0 then
						return
					end
					for _ = 1, 10 do
						local at = p.cf
							* Vector3.new(
								(roof[1] + roof[4]) / 2 + dress:float(-rx, rx),
								0,
								(roof[3] + roof[6]) / 2 + dress:float(-rz, rz)
							)
						if put(name, at.X, top, at.Z, yaw + dress:int(0, 3) * 90) then
							return
						end
					end
				end
				if kind == "shop" then
					onRoof("rooftopTank", 0.5)
					onRoof("antenna", 0.3)
					onRoof("satDish", 0.35)
				elseif kind == "flats" then
					onRoof("antenna", 0.4)
					onRoof("satDish", 0.6)
					onRoof("satDish", 0.3)
				elseif kind == "tower" then
					if p.name ~= "skyTower" then
						onRoof("antennaMast", 0.9)
					end
					onRoof("satDish", 0.4)
				else
					onRoof("satDish", 0.4)
				end
			end
		end
	end

	-- Kerbside clutter, scattered along the streets: cones, rails, newspaper boxes, scooters. Not
	-- at a crossing, by a bus stop or where a player arrives on their plot.
	local KERB = {
		"trafficCone",
		"newsBox",
		"guardRail",
		"scooter",
		"trafficCone",
		"bollardRow",
		"newsBox2",
		"coneBar",
		"scooter2",
		"trafficCone",
		"binBags",
	}
	local quiet: { Vector3 } = {}
	for _, p in standing do
		if p.name == "busStop" then
			table.insert(quiet, p.cf.Position)
		end
	end
	for i = 1, Tuning.Plot.Count do
		table.insert(quiet, Town.plotArrival(i).Position)
	end
	local clutter = Rng.new(57)
	local function kerb(road: any, side: number, from: number, to: number, least: number, most: number)
		local horizontal = road[2] == road[4]
		local at = if horizontal then road[2] else road[1]
		local street = if horizontal then (if side > 0 then 0 else 180) else (if side > 0 then 90 else -90)
		local u = from + clutter:float(0, most - least)
		while u < to do
			local name = clutter:pick(KERB)
			local off, yaw = 1.6, street
			if name == "guardRail" or name == "bollardRow" then
				off = 1
			elseif name:sub(1, 7) == "scooter" then
				-- parked along the kerb
				off, yaw = 1.5, street + (if clutter:chance(0.5) then 90 else -90)
			elseif name:sub(1, 7) == "newsBox" then
				-- its window to the people walking by
				off, yaw = 1.4, street + 180
			elseif name == "binBags" then
				off = 2.4
			end
			local w = math.floor(u)
			local v = at + side * (road[5] + off)
			local x, z = if horizontal then w else v, if horizontal then v else w
			local calm = atCrossing(road, w)
			for _, q in quiet do
				if (q.X - x) ^ 2 + (q.Z - z) ^ 2 < 14 ^ 2 then
					calm = true
				end
			end
			if not calm then
				put(name, x, SIDEWALK, z, yaw)
			end
			u += clutter:float(least, most)
		end
	end
	-- (thickest in the old town, thinner downtown, thin on the ring road and out west)
	for _, side in { 1, -1 } do
		kerb(main, side, -1040, -560, 110, 190)
		kerb(main, side, -520, 520, 50, 90)
		kerb(main, side, 560, 1040, 70, 120)
		kerb(midAvenue, side, -240, 240, 70, 130)
		kerb(firstAvenue, side, -240, 240, 90, 150)
		kerb(crossNorth, side, 570, 1040, 80, 140)
		kerb(crossSouth, side, 570, 1040, 80, 140)
	end
	kerb(hill, -1, -520, 1040, 110, 200)
	kerb(harbour, 1, -520, 1040, 110, 200)
	kerb(roadAt(-AX[1], -RZ, -AX[1], RZ), 1, -240, 240, 110, 200)

	-- (the boxes were only needed to lay the scene out)
	table.clear(shapes)
	table.clear(shells)
	return added
end

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
	-- is x, z inside a road or its junction (other than `skip`)? Things standing by a road keep out.
	local function nearRoad(x: number, z: number, skip: any?): boolean
		for _, road in Town.Roads do
			if road ~= skip then
				local hw = road[5] + 2
				local x1, x2 = math.min(road[1], road[3]) - hw, math.max(road[1], road[3]) + hw
				local z1, z2 = math.min(road[2], road[4]) - hw, math.max(road[2], road[4]) + hw
				if x > x1 and x < x2 and z > z1 and z < z2 then
					return true
				end
			end
		end
		return false
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
		for z = mk.Z - 30, mk.Z + 30, 30 do
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

	-- along the main street: lamps, then troughs of flowers, benches, potted shrubs, bike racks and
	-- post boxes near the kerb. No trees: the user asked for none near the roads.
	local walkZ = HW + 3 -- near the curb, leaving room to walk behind
	for x = -L + 40, L - 40, 68 do
		if not nearRoad(x, HW + 1.6) then
			for _, side in { 1, -1 } do
				put("lamp", x, side * (HW + 1.6), if side > 0 then 0 else 180)
			end
		end
	end
	local KERB =
		{ "planterBox", "benchLite", "planterBox2", "shrubPot", "planterBox", "bikeRack", "planterBox2", "mailbox" }
	local kerbN = 0
	for x = -L + 20, L - 20, 34 do
		local onPlaza = math.abs(x) < 54
		local nearCross = math.abs(x - 274) < 14 or math.abs(x + 274) < 14
		if not onPlaza and not nearCross and not nearRoad(x, walkZ) then
			kerbN += 1
			for _, side in { 1, -1 } do
				put(
					KERB[(kerbN + (if side > 0 then 0 else 3)) % #KERB + 1],
					x,
					side * walkZ,
					if side > 0 then 0 else 180
				)
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

	-- lamps and street furniture along the other roads (no trees here either)
	local SIDE = { "planterBox", "benchLite", "shrubPot", "bin", "planterBox2", "mailbox", "shrubPot", "hydrant" }
	local sideN = 0
	for k, road in Town.Roads do
		if k > 1 then
			local horizontal = road[2] == road[4]
			local hw = road[5]
			local a1 = if horizontal then math.min(road[1], road[3]) else math.min(road[2], road[4])
			local a2 = if horizontal then math.max(road[1], road[3]) else math.max(road[2], road[4])
			local at = if horizontal then road[2] else road[1]
			local u = a1 + 30
			local n = 0
			while u < a2 - 30 do
				n += 1
				local side = if n % 2 == 0 then 1 else -1
				local v = side * (hw + 1.8)
				local x, z = if horizontal then u else at + v, if horizontal then at + v else u
				if not nearRoad(x, z, road) then
					local yaw = if horizontal then (if side > 0 then 0 else 180) else (if side > 0 then -90 else 90)
					if n % 3 == 0 then
						put("streetLamp", x, z, yaw)
					else
						sideN += 1
						put(SIDE[sideN % #SIDE + 1], x, z, yaw)
					end
					local last = out[#out]
					last.cf = last.cf + Vector3.new(0, 0.3, 0)
				end
				u += 46
			end
		end
	end
	-- traffic lights at every junction: one over each road, on opposite corners
	for _, road in Town.Roads do
		if road[2] == road[4] then
			for _, o in Town.Roads do
				if o[1] == o[3] then
					local x, z = o[1], road[2]
					local onRoad = x >= math.min(road[1], road[3]) - 1 and x <= math.max(road[1], road[3]) + 1
					local onOther = z >= math.min(o[2], o[4]) - 1 and z <= math.max(o[2], o[4]) + 1
					if onRoad and onOther then
						local dx, dz = o[5] + 1.6, road[5] + 1.6
						put("trafficLight", x - dx, z + dz, 0)
						put("trafficLight", x + dx, z - dz, 90)
						for i = 0, 1 do
							local light = out[#out - i]
							light.cf = light.cf + Vector3.new(0, 0.3, 0)
						end
					end
				end
			end
		end
	end
	-- more bus stops: on Hill Road, by the boardwalk, and one in each quarter
	for _, p in { { -300, Town.RingZ }, { 380, -Town.RingZ }, { 700, Town.CrossZ }, { -700, Town.CrossZ } } do
		put("busStop", p[1], p[2] - 14.8, 0)
		put("bin", p[1] - 8, p[2] - 13, 0)
	end
	put("busStop", 930, -Town.CrossZ - 14.8, 0)
	put("busStop", -930, -Town.CrossZ - 14.8, 0)

	-- bushes along the old town's ring and the promenades up to the hills and down to the sea
	for _, sx in { -1, 1 } do
		for z = 30, 136, 13 do
			put("bush", sx * 58, z, z * 7)
			put("bush", sx * 58, -z, z * 11)
		end
		for i, z in { 160, 179, 198, 217, 236 } do
			local name = if i % 2 == 1 then "planterBox" else "shrubPot"
			put(name, sx * 14, z, 90)
			put(if i % 2 == 1 then "planterBox2" else "shrubPot", sx * 14, -z, 90)
		end
	end
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

	-- downtown, east of the old town
	local function on(name: string, x: number, z: number, yaw: number, y: number?, extra: { [string]: any }?)
		put(name, x, z, yaw, extra)
		if y and y ~= 0 then
			local last = out[#out]
			last.cf = last.cf + Vector3.new(0, y, 0)
		end
	end
	-- a building with its lot: landscaping sized to the building's own footprint
	local NO_LOT = { carPark = true, cityPark = true, pondPark = true, playground = true, sportsField = true }
	NO_LOT.basketCourt = true
	NO_LOT.station = true
	local plain = on
	local lotKind = "plaza"
	on = function(name: string, x: number, z: number, yaw: number, y: number?, extra: { [string]: any }?)
		plain(name, x, z, yaw, y, extra)
		if NO_LOT[name] or name:sub(1, 3) == "low" or name == "benchLite" or name == "streetLamp" then
			return
		end
		local lo, hi = Geometry.bounds(TownMap.prims(name))
		local margin = 5
		local w = math.ceil(hi.X - lo.X) + margin * 2
		local d = math.ceil(hi.Z - lo.Z) + margin * 2
		local cf = out[#out].cf * CFrame.new((lo.X + hi.X) / 2, 0, (lo.Z + hi.Z) / 2)
		table.insert(out, { name = string.format("lot:%dx%d:%s:%d", w, d, lotKind, margin), cf = cf })
	end
	local DT = 0.22 -- downtown's paving
	on("hotel", 650, 169, 0, DT)
	on("shopCoral", 735, 165, 0, DT)
	on("shopYellow", 775, 165, 0, DT)
	on("carPark", 700, 214, 0, DT)
	on("officeBlue", 890, 169, 0, DT)
	on("officeTeal", 1000, 169, 0, DT)
	on("deptStore", 630, 48, 0, DT)
	on("shopBlue", 725, 39, 0, DT)
	on("shopMint", 772, 39, 0, DT)
	on("cinema", 920, 48, 0, DT)
	on("apartmentLilac", 1010, 41, 0, DT)
	on("cityPark", 686, -68, 0, DT)
	on("apartmentPeach", 890, -41, 180, DT)
	on("apartmentMint", 995, -41, 180, DT)
	on("station", 686, -165, 180, DT)
	on("skyTower", 950, -173, 180, DT)
	-- and along the back of each block, facing the street behind
	on("apartmentPeach", 880, 226, 180, DT)
	on("shopBlue", 955, 228, 180, DT)
	on("shopMint", 1012, 228, 180, DT)
	on("shopOrange", 615, 97, 180, DT)
	on("shopLilac", 660, 97, 180, DT)
	on("officeBlue", 745, 93, 180, DT)
	on("officeTeal", 895, 93, 180, DT)
	on("shopPink", 990, 97, 180, DT)
	on("officeBlue", 880, -93, 0, DT)
	on("shopOrange", 960, -97, 0, DT)
	on("apartmentLilac", 1020, -95, 0, DT)
	on("shopPink", 890, -228, 0, DT)
	on("shopMint", 1012, -228, 0, DT)

	-- the civic quarter, west of the old town: every building in its own hedged garden
	lotKind = "garden"
	on("school", -686, 166, 0)
	on("playground", -686, 214, 0)
	on("sportsField", -950, 190, 0)
	on("library", -640, 42, 0)
	on("museum", -760, 52, 0)
	on("clinic", -960, 42, 0)
	on("basketCourt", -960, 92, 0)
	on("pondPark", -686, -68, 0)
	on("fireStation", -960, -60, 180)
	on("postOffice", -640, -166, 180)
	on("shopCoral", -700, -165, 180)
	on("shopLilac", -760, -165, 180)
	on("apartmentMint", -990, -167, 180)
	on("apartmentLilac", -900, -167, 180)
	on("houseRow", -888, -45, 180)
	on("houseRow", -950, -228, 0)
	on("houseRow", -1010, 60, -90)
	on("houseRow", -686, -222, 0)
	for _, p in { { -700, 50, 90 }, { -716, 50, -90 }, { -900, 70, 0 } } do
		on("benchLite", p[1], p[2], p[3])
	end

	on = plain
	-- Pockets: every gap between the buildings gets a little place of its own (a cafe terrace, a
	-- fountain, food trucks, a small car park downtown; gardens, ponds, picnic lawns, allotments
	-- and playgrounds in the civic quarter). Each goes where a 30 stud square is free, clear of
	-- every building and its lot, and faces the nearest street.
	local boundsOf: { [string]: { Vector3 } } = {}
	local function footprint(p: Placement): (number, number, number, number)
		local b = boundsOf[p.name]
		if not b then
			local lo, hi = Geometry.bounds(TownMap.prims(p.name))
			b = { lo, hi }
			boundsOf[p.name] = b
		end
		local x1, z1, x2, z2 = math.huge, math.huge, -math.huge, -math.huge
		for _, cx in { b[1].X, b[2].X } do
			for _, cz in { b[1].Z, b[2].Z } do
				local w = p.cf * Vector3.new(cx, 0, cz)
				x1, z1, x2, z2 = math.min(x1, w.X), math.min(z1, w.Z), math.max(x2, w.X), math.max(z2, w.Z)
			end
		end
		return x1, z1, x2, z2
	end
	local INSET = 7
	local pocketRng = Rng.new(88)
	-- (`HALF` is half the square each one needs, `GAP` the room left round it)
	local function pockets(block: { number }, kinds: { string }, y: number, most: number, HALF: number, GAP: number)
		local taken: { { number } } = {}
		for _, p in out do
			local pos = p.cf.Position
			if pos.X > block[1] - 70 and pos.X < block[3] + 70 and pos.Z > block[2] - 70 and pos.Z < block[4] + 70 then
				table.insert(taken, { footprint(p) })
			end
		end
		local function free(x: number, z: number): boolean
			for _, t in taken do
				if
					x - HALF - GAP < t[3]
					and x + HALF + GAP > t[1]
					and z - HALF - GAP < t[4]
					and z + HALF + GAP > t[2]
				then
					return false
				end
			end
			return true
		end
		local spots: { { number } } = {}
		for x = block[1] + INSET + HALF, block[3] - INSET - HALF, 5 do
			for z = block[2] + INSET + HALF, block[4] - INSET - HALF, 5 do
				if free(x, z) then
					table.insert(spots, { x, z })
				end
			end
		end
		local placed = 0
		local turn = pocketRng:int(1, #kinds)
		while placed < most and #spots > 0 do
			local i = pocketRng:int(1, #spots)
			local x, z = spots[i][1], spots[i][2]
			table.remove(spots, i)
			if free(x, z) then
				local north, south, east, west = block[4] - z, z - block[2], block[3] - x, x - block[1]
				local nearest = math.min(north, south, east, west)
				local yaw = if nearest == south
					then 0
					elseif nearest == north then 180
					elseif nearest == west then 90
					else -90
				turn += 1
				put(kinds[turn % #kinds + 1], x, z, yaw)
				local last = out[#out]
				last.cf = last.cf + Vector3.new(0, y, 0)
				table.insert(taken, { x - HALF, z - HALF, x + HALF, z + HALF })
				placed += 1
			end
		end
	end
	local PLAZAS = { "pocketCafe", "pocketFountain", "pocketTrucks", "pocketStatue", "pocketParking", "pocketGarden" }
	local GARDENS = {
		"pocketGarden",
		"pocketPond",
		"pocketPicnic",
		"pocketAllotment",
		"pocketPlay",
		"pocketFountain",
		"pocketStatue",
	}
	-- then single things in the smaller gaps that are left
	local SMALL = {
		"kiosk",
		"shrubPot",
		"benchLite",
		"planterBox",
		"cafeLite",
		"statue",
		"bikeRack",
		"planterBox2",
		"cafeLite2",
		"fountainSmall",
		"billboard",
	}
	local GREEN =
		{ "shrubPot", "flowerStrip", "benchLite", "wildflowers", "picnicTable", "hedgeRow", "boulder", "planterBox2" }
	for _, block in TownMap.blocks("east") do
		pockets(block, PLAZAS, DT, 5, 15, 6)
		pockets(block, SMALL, DT, 7, 8, 7)
	end
	for _, block in TownMap.blocks("west") do
		pockets(block, GARDENS, 0, 6, 15, 6)
		pockets(block, GREEN, 0, 6, 8, 8)
	end
	-- cars parked at the kerb along the side streets (never on the main street, where cars drive)
	local parking = Rng.new(41)
	for k, road in Town.Roads do
		if k > 1 then
			local horizontal = road[2] == road[4]
			local hw = road[5]
			local a1 = if horizontal then math.min(road[1], road[3]) else math.min(road[2], road[4])
			local a2 = if horizontal then math.max(road[1], road[3]) else math.max(road[2], road[4])
			local at = if horizontal then road[2] else road[1]
			local u = a1 + 40 + parking:float(0, 30)
			while u < a2 - 40 do
				local side = if parking:chance(0.5) then 1 else -1
				local v = side * (hw - 2.8)
				local x, z = if horizontal then u else at + v, if horizontal then at + v else u
				-- keep clear of junctions (measured along the road, from every road that crosses)
				local clear = true
				for _, c in crossings(road) do
					if math.abs(u - c[1]) < c[2] + c[3] + 14 then
						clear = false
					end
				end
				if clear then
					put("parkedCar" .. parking:int(1, 6), x, z, if horizontal then 90 else 0, { tag = "parked" })
					local last = out[#out]
					last.cf = last.cf + Vector3.new(0, 0.05, 0)
				end
				u += 70 + parking:float(0, 50)
			end
		end
	end
	-- between the old town's plots and the ring roads: clipped hedges with flowers, strips of
	-- flower bed and a bench now and then (no trees: they'd stand right by the road)
	local edge = 0
	for _, sz in { 1, -1 } do
		local x = -508.0
		while x < 510 do
			if math.abs(x) > 24 then
				edge += 1
				local name = if edge % 7 == 0 then "benchLite" elseif edge % 3 == 0 then "flowerStrip" else "hedgeRow"
				put(name, x, sz * 235, if sz > 0 then 180 else 0)
			end
			x += 24
		end
	end
	for _, sx in { 1, -1 } do
		for z = -228, 228, 24 do
			if math.abs(z) > 34 then
				edge += 1
				local name = if edge % 7 == 0 then "benchLite" elseif edge % 3 == 0 then "flowerStrip" else "hedgeRow"
				put(name, sx * 504, z, if sx > 0 then 90 else -90)
			end
		end
	end

	-- the hills: the farm, the lookout, the observatory, the radio mast and the camp
	local function hill(name: string, x: number, z: number, yaw: number, extra: { [string]: any }?)
		on(name, x, z, yaw, Hills.at(x, z) - 0.1, extra)
	end
	hill("farmyard", -720, 490, 0)
	hill("barn", -610, 445, 200)
	hill("windmill", -640, 548, 0)
	hill("lookout", 0, 640, 0)
	hill("observatory", -380, 760, 0)
	hill("radioMast", 380, 760, 0)
	hill("camp", 650, 520, 0)
	for _, p in { { -630, 520 }, { -770, 430 }, { -800, 540 } } do
		hill("lowTree", p[1], p[2], 0)
	end
	-- a mountain lake on the east peak and a ring of standing stones on the west one
	hill("tarn", 860, 720, 200)
	hill("stoneCircle", -860, 720, 0)
	-- hay bales round the farm, a rail along the lookout's edge, picnic tables and signposts
	for _, p in { { -670, 452 }, { -676, 459 }, { -663, 460 }, { -766, 452 }, { -598, 502 }, { -605, 508 } } do
		hill("hayBale", p[1], p[2], p[1] * 7)
	end
	for a = 200, 340, 20 do
		local rad = math.rad(a)
		local yaw = math.deg(math.atan2(-math.cos(rad), -math.sin(rad)))
		hill("fenceRun", 43 * math.cos(rad), 640 + 43 * math.sin(rad), yaw)
	end
	for _, p in { { 24, 652, 20 }, { 676, 548, -30 }, { 690, 500, 60 }, { -350, 742, 10 }, { 836, 676, 0 } } do
		hill("picnicTable", p[1], p[2], p[3])
	end
	for _, p in
		{ { 24, 300, 0 }, { 30, 596, 40 }, { -556, 420, 90 }, { 592, 470, -60 }, { -344, 716, 0 }, { 800, 640, 30 } }
	do
		hill("signpost", p[1], p[2], p[3])
	end
	hill("signpost", -806, 664, -30)
	-- trees over the slopes, clear of the flat tops and the path, thicker in the north east
	local woods = Rng.new(23)
	for _ = 1, 240 do
		local x = woods:float(Hills.X1 + 60, Hills.X2 - 60)
		local z = woods:float(Hills.Z1 + 50, Hills.Z2 - 60)
		local clear = true
		for _, pl in Hills.Plateaus do
			if math.sqrt((x - pl.x) ^ 2 + (z - pl.z) ^ 2) < pl.r + 14 then
				clear = false
			end
		end
		if math.abs(x) < 60 and z < 600 then
			clear = false -- the path up to the lookout
		end
		if x > -620 and x < -100 and z < 400 then
			clear = false -- the creator's meadow
		end
		if clear and Hills.slope(x, z) < 0.8 then
			local pine = x > 300 or woods:chance(0.35)
			local name = if pine
				then (if woods:chance(0.4) then "lowPineBig" else "lowPine")
				else (if woods:chance(0.3) then "lowTreeBig" else "lowTree")
			hill(name, x, z, woods:float(0, 360))
		end
	end
	for _ = 1, 16 do
		local x = woods:float(Hills.X1 + 80, Hills.X2 - 80)
		local z = woods:float(Hills.Z1 + 30, Hills.Z2 - 80)
		if Hills.slope(x, z) < 0.5 then
			hill(if woods:chance(0.8) then "wildflowers" else "rock", x, z, woods:float(0, 360))
		end
	end
	-- boulders, fallen logs, wild flowers and mushrooms over the slopes
	local wild = Rng.new(77)
	local function scatter(name: string, count: number, steepest: number)
		for _ = 1, count do
			local x = wild:float(Hills.X1 + 60, Hills.X2 - 60)
			local z = wild:float(Hills.Z1 + 44, Hills.Z2 - 60)
			local clear = not (x > -620 and x < -100 and z < 400) and not (math.abs(x) < 16 and z < 600)
			for _, pl in Hills.Plateaus do
				if math.sqrt((x - pl.x) ^ 2 + (z - pl.z) ^ 2) < pl.r + 10 then
					clear = false
				end
			end
			if clear and Hills.slope(x, z) < steepest then
				hill(name, x, z, wild:float(0, 360))
			end
		end
	end
	scatter("boulder", 30, 0.9)
	scatter("boulderBig", 9, 0.7)
	scatter("log", 14, 0.5)
	scatter("wildflowers", 46, 0.6)
	scatter("mushrooms", 18, 0.6)

	-- the waterfront: lamps and benches on the boardwalk, palms and parasols on the sand, the
	-- marina, the fairground pier, the beach huts, the lifeguard and the lighthouse
	local IX, IN, IS, B = TownMap.IslandX, TownMap.IslandN, TownMap.IslandS, TownMap.Beach
	local bwz = -(Town.RingZ + 11 + 6) - 6.5
	for x = -IX + 60, IX - 60, 80 do
		on("streetLamp", x, bwz + 5, 180, 0.32)
		if math.abs(x + 320) > 30 and math.abs(x - 300) > 30 then
			on("benchLite", x + 40, bwz - 3.5, 180, 0.32)
		end
	end
	local function clearOfPiers(x: number): boolean
		return math.abs(x - 300) > 34 and math.abs(x + 320) > 64 and math.abs(x - 640) > 40 and math.abs(x - 1000) > 30
	end
	on("marina", 300, -(IS + 2), 0)
	on("fairPier", -320, -IS, 0)
	on("ferrisWheel", -300, -IS - 92, 0, 0.4)
	on("carousel", -352, -IS - 62, 0, 0.4)
	on("stall", -368, -IS - 108, 30, 0.4)
	on("stall", -278, -IS - 55, -20, 0.4)
	on("stall", -272, -IS - 112, -60, 0.4)
	on("beachHuts", 640, -IS - 14, 0, -0.35)
	on("lifeguard", 0, -IS - 20, 0, -0.35)
	on("lighthouse", 1000, -IS - 80, 180)
	local beach = Rng.new(31)
	for x = -IX + 30, IX - 30, 58 do
		local px = x + beach:float(-10, 10)
		if clearOfPiers(px) and math.abs(px) > 12 then
			on(if beach:chance(0.5) then "palm" else "palmTall", px, -IS - B * 0.45 + beach:float(-5, 5), 270, -0.6)
		end
	end
	for x = -IX + 80, IX - 80, 110 do
		local px = x + beach:float(-12, 12)
		if clearOfPiers(px) and math.abs(px) > 20 then
			on("parasol", px, -IS - B * 0.7, beach:float(-20, 20), -0.7)
		end
	end
	-- palms along the east and west shores, and a quiet cove on the north shore
	for _, side in { 1, -1 } do
		for z = -IS + 30, IN - 30, 120 do
			local pz = z + beach:float(-10, 10)
			-- (not at the ends of the main street: no trees by a road)
			if math.abs(pz) > 46 then
				on("palm", side * (IX + B * 0.45), pz, if side > 0 then 0 else 180, -0.6)
			end
		end
	end
	for _, x in { 160, 200, 250 } do
		on("parasol", x, IN + B * 0.55, beach:float(0, 360), -0.7)
	end
	for _, x in { 120, 300, -200, -500, 520, 800 } do
		on("palm", x, IN + B * 0.4, 90, -0.6)
	end
	-- things left on the sand: towels, sandcastles, beach balls and driftwood; surfboards, a
	-- volleyball net and rowing boats pulled up at the water's edge
	local sand = Rng.new(47)
	local function onSand(name: string, count: number)
		for _ = 1, count do
			local x = sand:float(-IX + 40, IX - 40)
			if clearOfPiers(x) and math.abs(x) > 16 and math.abs(x - 130) > 26 and math.abs(x + 520) > 26 then
				on(name, x, -IS - sand:float(8, B - 9), sand:float(0, 360), -0.35)
			end
		end
	end
	onSand("towel", 14)
	onSand("towel2", 12)
	onSand("sandcastle", 9)
	onSand("beachBall", 9)
	onSand("driftwood", 8)
	on("volleyNet", 130, -IS - 19, 90, -0.35)
	on("volleyNet", -520, -IS - 19, 90, -0.35)
	for _, x in { 70, -150, 470, 830 } do
		on("surfRack", x, -IS - 5, 0, -0.35)
	end
	for _, x in { -570, -90, 430, 900 } do
		on("rowboat", x, -IS - B + 3, 80 + x % 30, -0.5)
	end
	for _, p in { { 160, 14 }, { 236, 22 }, { 190, 8 } } do
		on(if p[2] > 20 then "driftwood" else "towel", p[1], IN + p[2], p[1], -0.35)
	end
	on("rowboat", 280, IN + B - 3, 250, -0.5)

	-- out at sea: little islets on the horizon
	local sea = Rng.new(19)
	for x = -IX - 100, IX + 100, 520 do
		put("islet", x + sea:float(-60, 60), -IS - sea:float(330, 420), sea:float(0, 360), { tag = "backdrop" })
		put("islet", x + sea:float(-60, 60), IN + sea:float(330, 420), sea:float(0, 360), { tag = "backdrop" })
	end
	for _, side in { 1, -1 } do
		put("islet", side * (IX + 380), sea:float(0, 600), sea:float(0, 360), { tag = "backdrop" })
	end
	-- nearer in: sailing boats at anchor, buoys marking the way into the marina and round the
	-- pier, and rocks breaking the surface
	local function afloat(name: string, x: number, z: number, yaw: number, sink: number)
		put(name, x, z, yaw, { tag = "backdrop" })
		local last = out[#out]
		last.cf = last.cf + Vector3.new(0, -sink, 0)
	end
	for i, p in { { -120, -IS - 160, 70 }, { 130, -IS - 210, 200 }, { 540, -IS - 180, 120 }, { -660, -IS - 200, 300 } } do
		afloat(if i % 2 == 0 then "sailboat2" else "sailboat", p[1], p[2], p[3], 1.2)
	end
	afloat("sailboat2", 300, IN + 150, 30, 1.2)
	afloat("sailboat", -1100 - 170, 300, 160, 1.2)
	for _, p in { { 270, -IS - 120 }, { 330, -IS - 120 }, { 270, -IS - 170 }, { 330, -IS - 170 }, { -410, -IS - 150 } } do
		afloat("buoy", p[1], p[2], 0, 1)
	end
	afloat("buoy", -230, -IS - 150, 0, 1)
	afloat("buoy", 200, IN + 110, 0, 1)
	for _, p in { { 1050, -IS - 120 }, { 950, -IS - 130 }, { -900, -IS - 150 }, { 700, IN + 120 }, { -320, IN + 140 } } do
		afloat("seaRocks", p[1], p[2], p[1], 1)
	end
	afloat("seaRocks", 1100 + 130, 520, 40, 1)

	-- the set pieces (Data/Landmarks)
	for _, p in Landmarks.placements() do
		table.insert(out, p)
	end

	-- the street scene goes on last, round everything that is already standing
	local scene: { Placement } = sceneCache or streetScene(out)
	sceneCache = scene
	for _, p in scene do
		table.insert(out, { name = p.name, cf = p.cf })
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
