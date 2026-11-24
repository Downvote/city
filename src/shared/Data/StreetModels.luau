--!strict
-- The street scene: the things that make the town's streets read as a city. Drinks machines,
-- utility poles and the wires between them, air conditioners on the walls, tanks and aerials on
-- the roofs, billboards, poster hoardings and the odds and ends people leave on a pavement. The
-- user asked for a dense modern city, the kind an anime draws. These are our own designs.
--
-- Each is a recipe drawn round its own middle, front facing local -Z, a handful of parts each so
-- there can be a lot of them. Three part names mean something to other code:
--   Vend   a drinks machine's lit window
--   Ad     a face an advert goes on
--   Plate  a street sign's name plate
-- Each is a thin block that says which of its sides shows with a SignFace attribute, the way
-- Data/CityModels marks its boards: "Front" (the part's own -Z, which is the model's front
-- here), or nothing at all when both big sides show.

local Recipe = require(script.Parent.Parent.Build.Recipe)

type R = Recipe.Recipe

local StreetModels = {}
StreetModels.Models = {} :: { [string]: (R) -> () }
local M = StreetModels.Models

local function rgb(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end

local function shade(c: Color3, k: number): Color3
	return Color3.new(math.min(1, c.R * k), math.min(1, c.G * k), math.min(1, c.B * k))
end

local WHITE = rgb(250, 250, 248)
local CREAM = rgb(240, 232, 214)
local CONCRETE = rgb(184, 186, 192)
local METAL = rgb(186, 192, 202)
local DARK = rgb(64, 70, 86)
local WIRE = rgb(46, 50, 62)
local WOOD = rgb(196, 146, 96)
local WOOD_DARK = rgb(150, 104, 66)
local RED = rgb(240, 96, 90)
local BLUE = rgb(80, 150, 230)
local YELLOW = rgb(255, 208, 90)
local TEAL = rgb(70, 190, 180)
local ORANGE = rgb(255, 146, 66)
local GREEN = rgb(96, 190, 120)
local PAPER = rgb(236, 228, 208) -- a bare advert face, before anything is pasted on it
local SCREEN = rgb(222, 238, 246) -- a lit window by day
local SCREEN_NIGHT = rgb(206, 244, 255) -- and after dark

-- Marks a face an advert goes on: its front, or both big sides of a board that stands free.
local function advert(prim: Recipe.Prim, bothSides: boolean?): Recipe.Prim
	prim.name = "Ad"
	if not bothSides then
		prim.attrs = { SignFace = "Front" }
	end
	return prim
end

-- Drinks machines -------------------------------------------------------------------------------------

-- A tall drinks machine: a cabinet on a plinth, a big lit window, the coin column beside it and
-- the hatch the can drops into. The window glows after dark; the Signs service fills it with
-- cans and gives it the lamp that lights the pavement, so it has none of its own here.
local function vending(r: R, body: Color3, band: Color3)
	r:block(-1.6, 0, -1.05, 1.6, 0.3, 1.15, DARK, "Metal")
	r:block(-1.7, 0.3, -1.2, 1.7, 6.3, 1.2, body, "SmoothPlastic")
	local window = r:block(-1.45, 2.9, -1.3, 0.8, 5.9, -1.2, SCREEN, "SmoothPlastic")
	window.name = "Vend"
	r:glow(window, 0)
	window.attrs = { NightColor = SCREEN_NIGHT, SignFace = "Front" }
	r:block(1, 2.9, -1.27, 1.45, 5.3, -1.2, shade(body, 0.72), "SmoothPlastic")
	r:block(-1.7, 2.2, -1.25, 1.7, 2.6, -1.2, band, "SmoothPlastic")
	r:block(-1.2, 0.8, -1.26, 0.9, 1.8, -1.2, DARK, "SmoothPlastic")
end

M.vendingMachine = function(r: R)
	vending(r, RED, WHITE)
end

M.vendingMachine2 = function(r: R)
	vending(r, BLUE, YELLOW)
end

M.vendingMachine3 = function(r: R)
	vending(r, WHITE, TEAL)
end

-- The bin for empties that stands beside a machine.
M.canBin = function(r: R)
	r:block(-0.8, 0, -0.7, 0.8, 3.2, 0.7, METAL, "Metal")
	r:block(-0.85, 3.2, -0.75, 0.85, 3.5, 0.75, TEAL, "SmoothPlastic")
end

-- Poles and wires ------------------------------------------------------------------------------------

-- Where the wires leave a pole: { height, how far across }. The spans hang from the same points.
local WIRES = { { 19.05, -1.9 }, { 19.05, 1.9 }, { 16.9, -1.25 } }

-- A utility pole: a concrete post with a hazard band, two crossarms and a transformer drum on the
-- side away from the street. The wires run along local X.
M.utilityPole = function(r: R)
	r:cyl(0, 10, 0, 20, 0.9, "y", CONCRETE, "Concrete")
	r:cyl(0, 2.6, 0, 1.6, 1, "y", YELLOW, "SmoothPlastic")
	r:block(-0.16, 18.6, -2.3, 0.16, 18.95, 2.3, DARK, "Metal")
	r:block(-0.16, 16.5, -1.6, 0.16, 16.8, 1.6, DARK, "Metal")
	r:cyl(0, 14.2, 1.2, 2.4, 1.5, "y", METAL, "Metal")
end

-- The wires from the pole this is placed on to the next one, `len` studs away along local +X.
-- They sag a little in the middle and nobody can bump into them.
function StreetModels.wires(len: number): (R) -> ()
	return function(r: R)
		local sag = math.clamp(len * 0.03, 0.6, 2.2)
		for _, w in WIRES do
			local a = Vector3.new(0, w[1], w[2])
			local mid = Vector3.new(len / 2, w[1] - sag, w[2])
			local b = Vector3.new(len, w[1], w[2])
			for _, seg in { { a, mid }, { mid, b } } do
				local wire = r:beam(seg[1], seg[2], 0.16, 0.16, WIRE, "SmoothPlastic")
				if wire then
					r:noCollide(wire)
				end
			end
		end
	end
end

-- Walls and roofs ------------------------------------------------------------------------------------

-- An air conditioner's outdoor box on a wall: the origin is on the wall at the box's bottom edge
-- and the box hangs out from it. It is overhead, so nobody bumps into it.
M.acUnit = function(r: R)
	r:noCollide(r:block(-1.4, 0, -1.1, 1.4, 1.6, 0, CREAM, "SmoothPlastic"))
	r:noCollide(r:cyl(-0.4, 0.8, -1.12, 0.08, 1.25, "z", DARK, "SmoothPlastic"))
end

-- The bigger kind that stands on the ground behind a shop.
M.condenser = function(r: R)
	r:block(-1.9, 0, -1, 1.9, 0.25, 1, CONCRETE, "Concrete")
	r:block(-1.7, 0.25, -0.8, 1.7, 3.1, 0.8, CREAM, "SmoothPlastic")
	r:cyl(-0.5, 1.7, -0.82, 0.08, 2, "z", DARK, "SmoothPlastic")
end

-- A water tank on legs for a flat roof.
M.rooftopTank = function(r: R)
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			r:block(sx * 1.3 - 0.15, 0, sz * 1.3 - 0.15, sx * 1.3 + 0.15, 2, sz * 1.3 + 0.15, DARK, "Metal")
		end
	end
	r:cyl(0, 4, 0, 4, 4, "y", CREAM, "SmoothPlastic")
	r:cone(0, 6.45, 0, 0.9, 4.2, TEAL, "SmoothPlastic")
end

-- A television aerial: a mast, a boom and two bars across it.
M.antenna = function(r: R)
	r:cyl(0, 3.6, 0, 7.2, 0.26, "y", METAL, "Metal")
	r:block(-0.08, 6.5, -2, 0.08, 6.66, 1.2, METAL, "Metal")
	r:block(-1.6, 6.5, -1.67, 1.6, 6.66, -1.53, METAL, "Metal")
	r:block(-1.1, 6.5, 0.33, 1.1, 6.66, 0.47, METAL, "Metal")
end

-- A taller mast for a tower's roof, with a red lamp on top.
M.antennaMast = function(r: R)
	r:block(-0.7, 0, -0.7, 0.7, 0.8, 0.7, CONCRETE, "Concrete")
	r:cyl(0, 6.8, 0, 12, 0.4, "y", METAL, "Metal")
	r:block(-1.6, 9.2, -0.08, 1.6, 9.36, 0.08, METAL, "Metal")
	r:block(-1, 11, -0.08, 1, 11.16, 0.08, METAL, "Metal")
	r:glow(r:ball(0, 13.1, 0, 0.8, rgb(255, 96, 86), "SmoothPlastic"), 0)
end

-- A satellite dish on a short stand, looking up at the sky.
M.satDish = function(r: R)
	r:cyl(0, 0.9, 0, 1.8, 0.4, "y", DARK, "Metal")
	local tilt = CFrame.new(0, 2.5, -0.3) * CFrame.Angles(math.rad(-50), 0, 0)
	r:boxAt(tilt * CFrame.Angles(0, 0, math.pi / 2), 0.3, 3, 3, WHITE, "SmoothPlastic").shape = "Cylinder"
	r:boxAt(tilt * CFrame.new(0, 0.9, 0), 0.14, 1.5, 0.14, DARK, "Metal")
end

-- Adverts ---------------------------------------------------------------------------------------------

-- A billboard on two legs: a board with an advert on both sides and a lamp bar along the top.
-- (It takes the place of the older one in Data/DetailModels and stands in exactly its footprint.
-- The bar only glows: the Signs service lights a big advert itself.)
M.billboard = function(r: R)
	for _, x in { -5, 5 } do
		r:block(x - 0.3, 0, -0.3, x + 0.3, 9, 0.3, DARK, "Metal")
	end
	r:block(-8, 9, -0.4, 8, 17, 0.23, WHITE, "SmoothPlastic")
	advert(r:block(-7.5, 9.5, -0.57, 7.5, 16.5, 0.4, PAPER, "SmoothPlastic"), true)
	r:glow(r:block(-7, 17, -0.57, 7, 17.3, -0.2, rgb(255, 244, 214), "SmoothPlastic"), 0)
end

-- A big board high on one steel post, for a junction or the seafront. Adverts on both sides.
M.billboardTall = function(r: R)
	r:cyl(0, 7.2, 0, 14.4, 1.2, "y", DARK, "Metal")
	r:block(-7.4, 14.4, -0.4, 7.4, 22.4, 0.4, shade(DARK, 1.25), "Metal")
	advert(r:block(-7, 14.8, -0.56, 7, 22, 0.56, PAPER, "SmoothPlastic"), true)
	r:block(-7.4, 14, -1.5, 7.4, 14.3, 0.4, DARK, "Metal")
	r:glow(r:block(-6.4, 14.3, -1.5, 6.4, 14.6, -1.2, rgb(255, 244, 214), "SmoothPlastic"), 0)
end

-- A hoarding of pasted posters: a fence panel between two posts with a face for each poster.
local function hoarding(r: R, faces: number, panel: Color3)
	local half = faces * 2
	r:block(-half, 0.5, -0.12, half, 5.6, 0.12, panel, "WoodPlanks")
	for _, sx in { -1, 1 } do
		r:block(sx * half - 0.25, 0, -0.25, sx * half + 0.25, 5.9, 0.25, shade(panel, 0.72), "Wood")
	end
	for k = 0, faces - 1 do
		local x = -half + 2 + k * 4
		advert(r:block(x - 1.6, 1.2, -0.2, x + 1.6, 5.1, -0.12, PAPER, "SmoothPlastic"))
	end
end

M.posterWall = function(r: R)
	hoarding(r, 3, rgb(120, 170, 150))
end

M.posterWall2 = function(r: R)
	hoarding(r, 2, rgb(236, 200, 120))
end

-- A sandwich board outside a shop: two boards leaning together at the top, the advert on the
-- front one.
M.aBoard = function(r: R)
	local lean = CFrame.new(0, 1.55, -0.35) * CFrame.Angles(math.rad(13), 0, 0)
	r:boxAt(lean, 2, 3.2, 0.14, DARK, "Wood")
	advert(r:boxAt(lean * CFrame.new(0, 0.1, -0.1), 1.7, 2.6, 0.06, PAPER, "SmoothPlastic"))
	r:boxAt(CFrame.new(0, 1.55, 0.35) * CFrame.Angles(math.rad(-13), 0, 0), 2, 3.2, 0.14, DARK, "Wood")
end

-- Street clutter --------------------------------------------------------------------------------------

local function cone(r: R, x: number, z: number, band: boolean)
	r:block(x - 0.7, 0, z - 0.7, x + 0.7, 0.16, z + 0.7, shade(ORANGE, 0.82), "SmoothPlastic")
	r:cone(x, 1.26, z, 2.2, 1.1, ORANGE, "SmoothPlastic")
	if band then
		r:cyl(x, 1.25, z, 0.4, 0.62, "y", WHITE, "SmoothPlastic")
	end
end

M.trafficCone = function(r: R)
	cone(r, 0, 0, true)
end

-- Two cones with a striped bar between them, round a hole in the pavement.
M.coneBar = function(r: R)
	cone(r, -2.4, 0, false)
	cone(r, 2.4, 0, false)
	r:block(-2.4, 1.5, -0.1, 2.4, 1.8, 0.1, YELLOW, "SmoothPlastic")
	r:block(-0.8, 1.5, -0.12, 0.8, 1.8, 0.12, DARK, "SmoothPlastic")
end

-- Wooden crates left by a back door.
M.crateStack = function(r: R)
	r:block(-1.7, 0, -1.1, 0.5, 2.2, 1.1, WOOD, "WoodPlanks")
	r:boxAt(CFrame.new(-0.5, 3.1, 0) * CFrame.Angles(0, math.rad(14), 0), 1.9, 1.8, 1.9, WOOD_DARK, "WoodPlanks")
	r:boxAt(
		CFrame.new(1.5, 0.8, 0.3) * CFrame.Angles(0, math.rad(-20), 0),
		1.6,
		1.6,
		1.6,
		shade(WOOD, 1.1),
		"WoodPlanks"
	)
end

-- Bottle crates outside a shop: two stacks in bright plastic.
M.drinksCrates = function(r: R)
	for i, col in { YELLOW, RED, BLUE } do
		local y = (i - 1) * 1.05
		r:boxAt(
			CFrame.new(-0.9, y + 0.5, 0) * CFrame.Angles(0, math.rad((i - 2) * 7), 0),
			1.6,
			1,
			1.2,
			col,
			"SmoothPlastic"
		)
	end
	r:block(0.1, 0, -0.6, 1.7, 1, 0.6, GREEN, "SmoothPlastic")
	r:block(0.25, 1, -0.45, 1.55, 1.3, 0.45, DARK, "SmoothPlastic")
end

-- A box that sells newspapers.
local function newsBox(r: R, col: Color3)
	r:block(-0.3, 0, -0.3, 0.3, 1.3, 0.3, DARK, "Metal")
	r:block(-0.9, 1.3, -0.7, 0.9, 3.7, 0.7, col, "Metal")
	r:block(-0.65, 2.3, -0.76, 0.65, 3.4, -0.7, rgb(150, 206, 240), "Glass")
end

M.newsBox = function(r: R)
	newsBox(r, YELLOW)
end

M.newsBox2 = function(r: R)
	newsBox(r, RED)
end

-- A telephone box: a solid back with the telephone on it, glass sides, a roof with a lit band.
M.phoneBooth = function(r: R)
	r:block(-1.7, 0, -1.7, 1.7, 0.25, 1.7, DARK, "Metal")
	r:block(-1.7, 0.25, 1.45, 1.7, 7.3, 1.7, TEAL, "Metal")
	for _, sx in { -1, 1 } do
		local side = r:glass(sx * 1.7, 0.25, -1.6, sx * 1.58, 7.3, 1.45)
		side.transp = 0.5
	end
	r:block(-1.85, 7.3, -1.85, 1.85, 8, 1.85, TEAL, "Metal")
	local band = r:block(-1.5, 7.4, -1.92, 1.5, 7.9, -1.85, SCREEN, "SmoothPlastic")
	r:glow(band, 8, 0.6, SCREEN_NIGHT)
	band.attrs = { NightColor = SCREEN_NIGHT }
	r:block(-0.7, 3, 1, 0.7, 5, 1.45, DARK, "SmoothPlastic")
end

-- A parked scooter, its nose toward local -Z.
local function scooter(r: R, col: Color3)
	for _, z in { -1.9, 1.7 } do
		r:cyl(0, 0.65, z, 0.4, 1.3, "x", DARK, "SmoothPlastic")
	end
	r:block(-0.45, 0.7, -1.6, 0.45, 0.95, 0.5, DARK, "SmoothPlastic")
	r:block(-0.55, 0.9, 0.3, 0.55, 2.1, 2.3, col, "SmoothPlastic")
	r:block(-0.45, 2.1, 0.4, 0.45, 2.4, 2.1, rgb(50, 52, 62), "SmoothPlastic")
	r:boxAt(CFrame.new(0, 2.1, -1.55) * CFrame.Angles(math.rad(14), 0, 0), 1.1, 2.7, 0.3, col, "SmoothPlastic")
	r:block(-1, 3.4, -1.3, 1, 3.6, -1.1, DARK, "Metal")
end

M.scooter = function(r: R)
	scooter(r, TEAL)
end

M.scooter2 = function(r: R)
	scooter(r, rgb(255, 170, 190))
end

-- Four short posts in a row, to keep cars off the pavement.
M.bollardRow = function(r: R)
	for k = 0, 3 do
		r:cyl(-3.6 + k * 2.4, 1.2, 0, 2.4, 0.56, "y", if k % 2 == 0 then YELLOW else DARK, "Metal")
	end
end

-- A length of pedestrian rail along a kerb.
M.guardRail = function(r: R)
	for _, x in { -4.2, 0, 4.2 } do
		r:cyl(x, 1.4, 0, 2.8, 0.36, "y", WHITE, "Metal")
	end
	r:block(-4.2, 2.3, -0.1, 4.2, 2.56, 0.1, GREEN, "Metal")
	r:block(-4.2, 1.1, -0.1, 4.2, 1.36, 0.1, GREEN, "Metal")
end

-- A street sign: a post with the street's name on a plate and a round sign under it.
M.streetSignPost = function(r: R)
	r:cyl(0, 4.4, 0, 8.8, 0.3, "y", METAL, "Metal")
	local plate = r:block(-1.9, 7.6, -0.26, 1.9, 8.6, -0.16, BLUE, "SmoothPlastic")
	plate.name = "Plate"
	plate.attrs = { SignFace = "Front" }
	r:cyl(0, 6, -0.2, 0.1, 1.9, "z", RED, "SmoothPlastic")
	r:cyl(0, 6, -0.26, 0.06, 1.3, "z", WHITE, "SmoothPlastic")
end

-- Rubbish bags put out for the morning.
M.binBags = function(r: R)
	r:lump(CFrame.new(0, 0.8, 0) * CFrame.Angles(0.2, 0.4, 0.1), 2, 1.7, 1.8, rgb(84, 92, 112), "SmoothPlastic")
	r:lump(CFrame.new(1.4, 0.65, 0.4) * CFrame.Angles(-0.2, 1, 0.2), 1.6, 1.3, 1.5, rgb(104, 112, 132), "SmoothPlastic")
	r:lump(CFrame.new(0.5, 0.6, -1.1) * CFrame.Angles(0.1, 0.2, -0.2), 1.5, 1.2, 1.4, WHITE, "SmoothPlastic")
end

function StreetModels.prims(name: string): { any }?
	local build = M[name]
	if not build then
		-- "wireSpan:<length>"
		local len = name:match("^wireSpan:(%d+)$")
		if len then
			build = StreetModels.wires(tonumber(len) :: number)
		end
	end
	if not build then
		return nil
	end
	local r = Recipe.new(WHITE, WHITE)
	build(r)
	return r.prims
end

return StreetModels
