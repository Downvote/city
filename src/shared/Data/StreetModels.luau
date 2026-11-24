--!strict
-- The street scene: the things that make the town's streets read as a city. Drinks machines,
-- utility poles and the wires between them, air conditioners on the walls, tanks and aerials on
-- the roofs, billboards, poster hoardings and the odds and ends people leave on a pavement. The
-- user asked for a dense modern city, the kind an anime draws. These are our own designs.
--
-- Each is a recipe drawn round its own middle, front facing local -Z, a handful of parts each so
-- there can be a lot of them. The user later asked for detail "similar to the default house
-- everywhere", so each is made of the parts the real thing has: a drinks machine has its
-- buttons, coin slot and hatch, a pole its insulators and transformer, a bin its lid. What is put
-- down by the dozen keeps that detail in one piece (Recipe.piece: shapes made into one mesh,
-- once), the same piece whatever colour the model is painted; what is rare is plain parts.
--
-- Three part names mean something to other code:
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

local WHITE = rgb(250, 246, 236)
local CREAM = rgb(240, 232, 214)
local CONCRETE = rgb(184, 186, 192)
local METAL = rgb(186, 192, 202)
local SILVER = rgb(150, 156, 168)
local DARK = rgb(64, 70, 86)
local BLACK = rgb(40, 42, 50)
local WIRE = rgb(46, 50, 62)
local WOOD = rgb(196, 154, 108)
local WOOD_DARK = rgb(154, 107, 72)
local RED = rgb(214, 108, 98)
local BLUE = rgb(96, 140, 190)
local YELLOW = rgb(236, 198, 110)
local TEAL = rgb(88, 164, 156)
local ORANGE = rgb(228, 150, 100)
local GREEN = rgb(104, 170, 124)
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

-- Draws with `draw` round the origin and adds it to `r` stood at `cf`, so a piece drawn inside
-- stays the same mesh however it is turned.
local function group(r: R, cf: CFrame, draw: (R) -> ())
	local q = Recipe.new(r.c1, r.c2)
	draw(q)
	for _, p in q.prims do
		p.cf = cf * p.cf
		r:add(p)
	end
end

-- Drinks machines -------------------------------------------------------------------------------------

-- A tall drinks machine: a cabinet on a plinth under a cap, a big lit window in a frame, the
-- button column with its buttons, coin slot and change cup, the hatch the can drops into with its
-- flap, and vents down the side. The window glows after dark; the Signs service fills it with
-- cans and gives it the lamp that lights the pavement, so it has none of its own here. The
-- cabinet and the band take the machine's colours; the rest is one piece, the same on all three.
local function vending(r: R, body: Color3, band: Color3)
	r:block(-1.7, 0.3, -1.2, 1.7, 6.12, 1.2, body, "SmoothPlastic")
	local window = r:block(-1.45, 2.9, -1.3, 0.8, 5.9, -1.2, SCREEN, "SmoothPlastic")
	window.name = "Vend"
	r:glow(window, 0)
	window.attrs = { NightColor = SCREEN_NIGHT, SignFace = "Front" }
	r:block(-1.7, 2.2, -1.25, 1.7, 2.6, -1.2, band, "SmoothPlastic")
	r:piece(function(p: R)
		p:block(-1.6, 0, -1.05, 1.6, 0.3, 1.15, DARK, "SmoothPlastic")
		p:block(-1.73, 6.12, -1.23, 1.73, 6.3, 1.23, DARK, "SmoothPlastic")
		p:block(-1.55, 2.8, -1.26, 0.9, 6.0, -1.2, SILVER, "SmoothPlastic")
		p:block(1.0, 2.9, -1.27, 1.45, 5.3, -1.2, SILVER, "SmoothPlastic")
		for k = 0, 3 do
			local y = 4.95 - k * 0.36
			p:block(1.09, y - 0.09, -1.31, 1.36, y + 0.09, -1.27, WHITE, "SmoothPlastic")
		end
		p:block(1.12, 3.42, -1.31, 1.33, 3.6, -1.27, BLACK, "SmoothPlastic")
		p:block(1.06, 3.0, -1.31, 1.39, 3.22, -1.27, BLACK, "SmoothPlastic")
		p:block(-1.2, 0.8, -1.26, 0.9, 1.8, -1.2, BLACK, "SmoothPlastic")
		p:block(-1.1, 1.36, -1.31, 0.8, 1.7, -1.26, SILVER, "SmoothPlastic")
		p:block(1.7, 1.1, -0.6, 1.74, 1.2, 0.6, BLACK, "SmoothPlastic")
	end)
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

-- The bin for empties that stands beside a machine: a foot, the bin, a band with a label, the
-- lid and the two round holes the cans go through.
M.canBin = function(r: R)
	r:piece(function(p: R)
		p:block(-0.85, 0, -0.75, 0.85, 0.12, 0.75, DARK, "Metal")
		p:block(-0.8, 0.12, -0.7, 0.8, 3.2, 0.7, METAL, "Metal")
		p:block(-0.84, 2.0, -0.74, 0.84, 2.4, 0.74, TEAL, "Metal")
		for _, x in { -0.4, 0.4 } do
			p:cyl(x, 3.52, 0, 0.04, 0.44, "y", BLACK, "Metal")
		end
	end, true)
	r:block(-0.86, 3.2, -0.76, 0.86, 3.5, 0.76, TEAL, "Metal")
end

-- Poles and wires ------------------------------------------------------------------------------------

-- Where the wires leave a pole: { height, how far across }. The spans hang from the same points.
local WIRES = { { 19.05, -1.9 }, { 19.05, 1.9 }, { 16.9, -1.25 } }

-- A utility pole: a concrete post narrowing towards the top with a striped band low down and
-- a step bolt, two crossarms with white insulators where the wires are tied, and a transformer drum
-- on a bracket on the side away from the street. The wires run along local X.
M.utilityPole = function(r: R)
	r:piece(function(p: R)
		p:cyl(0, 0.2, 0, 0.4, 1.2, "y", shade(CONCRETE, 0.9), "Concrete")
		p:cyl(0, 6, 0, 12, 0.9, "y", CONCRETE, "Concrete")
		p:cyl(0, 16, 0, 8, 0.76, "y", CONCRETE, "Concrete")
		p:cyl(0, 2.8, 0, 1.6, 1.0, "y", YELLOW, "Concrete")
		p:cyl(0, 2.8, 0, 0.3, 1.08, "y", BLACK, "Concrete")
		p:block(0.42, 9, -0.06, 0.78, 9.12, 0.06, DARK, "Concrete")
	end, true)
	r:piece(function(p: R)
		p:block(-0.16, 18.6, -2.3, 0.16, 18.95, 2.3, DARK, "Metal")
		p:block(-0.16, 16.5, -1.6, 0.16, 16.8, 1.6, DARK, "Metal")
		for _, w in WIRES do
			p:cyl(0, w[1], w[2], 0.3, 0.26, "y", WHITE, "Metal")
		end
	end)
	r:piece(function(p: R)
		p:block(-0.2, 13.3, 0.35, 0.2, 13.6, 0.75, DARK, "Metal")
		p:cyl(0, 14.2, 1.2, 2.4, 1.5, "y", METAL, "Metal")
		p:cyl(0, 15.48, 1.2, 0.16, 1.62, "y", DARK, "Metal")
	end)
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

-- The front of an outdoor fan unit, round the origin facing local -Z: the fan's dark round, two
-- bars of its guard and the hub, and a service panel with louvres beside it.
local function fanFront(p: R, fx: number, fy: number, front: number, d: number)
	p:cyl(fx, fy, front, 0.06, d, "z", BLACK, "SmoothPlastic")
	for _, dy in { -0.18, 0.18 } do
		p:block(fx - d / 2 + 0.06, fy + dy - 0.03, front - 0.06, fx + d / 2 - 0.06, fy + dy + 0.03, front - 0.03, SILVER, "SmoothPlastic")
	end
	p:cyl(fx, fy, front - 0.045, 0.03, d * 0.24, "z", SILVER, "SmoothPlastic")
end

-- An air conditioner's outdoor box on a wall: the origin is on the wall at the box's bottom edge
-- and the box hangs out from it on two brackets. It is overhead,
-- so nobody bumps into it.
M.acUnit = function(r: R)
	r:noCollide(r:block(-1.4, 0.18, -1.1, 1.4, 1.6, 0, CREAM, "SmoothPlastic"))
	r:piece(function(p: R)
		fanFront(p, -0.4, 0.89, -1.1, 1.2)
		p:block(0.55, 0.33, -1.14, 1.25, 1.45, -1.1, shade(CREAM, 0.92), "SmoothPlastic")
		for _, sx in { -1, 1 } do
			p:block(sx * 1.05 - 0.07, 0, -1.0, sx * 1.05 + 0.07, 0.18, 0, DARK, "SmoothPlastic")
		end
	end)
end

-- The bigger kind that stands on the ground behind a shop, on a concrete pad, with a grille on
-- top and its pipes running down the side.
M.condenser = function(r: R)
	r:block(-1.9, 0, -1, 1.9, 0.25, 1, CONCRETE, "Concrete")
	r:piece(function(p: R)
		p:block(-1.7, 0.25, -0.8, 1.7, 3.1, 0.8, CREAM, "SmoothPlastic")
		fanFront(p, -0.5, 1.7, -0.8, 2)
		p:block(0.75, 0.5, -0.84, 1.5, 2.9, -0.8, shade(CREAM, 0.92), "SmoothPlastic")
		for _, z in { -0.4, 0, 0.4 } do
			p:block(-1.5, 3.1, z - 0.1, 1.5, 3.14, z + 0.1, shade(CREAM, 0.8), "SmoothPlastic")
		end
		for _, y in { 0.7, 1.0 } do
			p:block(1.7, y - 0.06, 0.1, 1.84, y + 0.06, 0.24, WHITE, "SmoothPlastic")
		end
	end, true)
end

-- A water tank on legs for a flat roof: the tank with two hoops round it and a pointed lid.
M.rooftopTank = function(r: R)
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			r:block(sx * 1.3 - 0.15, 0, sz * 1.3 - 0.15, sx * 1.3 + 0.15, 2, sz * 1.3 + 0.15, DARK, "Metal")
		end
	end
	r:cyl(0, 4, 0, 4, 4, "y", CREAM, "SmoothPlastic")
	r:cone(0, 6.45, 0, 0.9, 4.2, TEAL, "SmoothPlastic")
	r:cyl(0, 3, 0, 0.2, 4.08, "y", shade(CREAM, 0.82), "SmoothPlastic")
	r:cyl(0, 5, 0, 0.2, 4.08, "y", shade(CREAM, 0.82), "SmoothPlastic")
end

-- A television aerial: a mast on a foot, a boom and four bars across it.
M.antenna = function(r: R)
	r:block(-0.3, 0, -0.3, 0.3, 0.2, 0.3, DARK, "Metal")
	r:cyl(0, 3.6, 0, 7.2, 0.26, "y", METAL, "Metal")
	r:block(-0.08, 6.5, -2, 0.08, 6.66, 1.2, METAL, "Metal")
	for k, z in { -1.6, -0.8, 0, 0.8 } do
		local half = 1.7 - k * 0.25
		r:block(-half, 6.66, z - 0.07, half, 6.74, z + 0.07, METAL, "Metal")
	end
end

-- A taller mast for a tower's roof, with a red lamp on top.
M.antennaMast = function(r: R)
	r:block(-0.7, 0, -0.7, 0.7, 0.8, 0.7, CONCRETE, "Concrete")
	r:cyl(0, 6.8, 0, 12, 0.4, "y", METAL, "Metal")
	r:block(-1.6, 9.2, -0.08, 1.6, 9.36, 0.08, METAL, "Metal")
	r:block(-1, 11, -0.08, 1, 11.16, 0.08, METAL, "Metal")
	r:block(-1.3, 7.4, -0.08, 1.3, 7.56, 0.08, METAL, "Metal")
	r:cyl(0, 12.75, 0, 0.1, 0.7, "y", DARK, "Metal")
	r:glow(r:ball(0, 13.1, 0, 0.8, rgb(255, 96, 86), "SmoothPlastic"), 0)
end

-- A satellite dish on a short stand, looking up at the sky: the dish and its rim, the arm that
-- holds the receiver out in front of it, and the mount.
M.satDish = function(r: R)
	r:cyl(0, 0.9, 0, 1.8, 0.4, "y", DARK, "Metal")
	r:block(-0.3, 1.7, -0.5, 0.3, 2.0, 0.1, DARK, "Metal")
	local tilt = CFrame.new(0, 2.5, -0.3) * CFrame.Angles(math.rad(-50), 0, 0)
	r:cone(0, 0, 0, 0.4, 2.6, shade(WHITE, 0.9), "SmoothPlastic").cf = tilt
		* CFrame.new(0, -0.1, 0)
		* CFrame.Angles(math.pi, 0, 0)
	r:boxAt(tilt * CFrame.new(0, 0.1, 0) * CFrame.Angles(0, 0, math.pi / 2), 0.08, 3, 3, WHITE, "SmoothPlastic").shape =
		"Cylinder"
	r:beam((tilt * CFrame.new(0, 0.14, 1.2)).Position, (tilt * CFrame.new(0, 1.2, 0)).Position, 0.1, 0.1, DARK, "Metal")
	r:boxAt(tilt * CFrame.new(0, 1.25, 0), 0.26, 0.36, 0.26, DARK, "Metal")
end

-- Adverts ---------------------------------------------------------------------------------------------

-- A billboard on two braced legs: a board with an advert on both sides, a walkway under the
-- front and a lamp bar along the top. (It takes the place of the older one in Data/DetailModels
-- and stands in exactly its footprint. The bar only glows: the Signs service lights a big advert
-- itself.)
M.billboard = function(r: R)
	for _, x in { -5, 5 } do
		r:block(x - 0.3, 0, -0.3, x + 0.3, 9, 0.3, DARK, "Metal")
	end
	r:beam(Vector3.new(-4.7, 1, 0), Vector3.new(4.7, 8.2, 0), 0.24, 0.2, DARK, "Metal")
	r:beam(Vector3.new(4.7, 1, 0), Vector3.new(-4.7, 8.2, 0), 0.18, 0.2, DARK, "Metal")
	r:block(-8, 9, -0.4, 8, 17, 0.23, WHITE, "SmoothPlastic")
	advert(r:block(-7.5, 9.5, -0.57, 7.5, 16.5, 0.4, PAPER, "SmoothPlastic"), true)
	r:block(-7.5, 8.6, -1.4, 7.5, 8.75, -0.4, SILVER, "Metal")
	r:glow(r:block(-7, 17, -0.57, 7, 17.3, -0.2, rgb(255, 244, 214), "SmoothPlastic"), 0)
end

-- A big board high on one steel post, for a junction or the seafront: a foot, a bracket under the
-- frame, a walkway with a rail along it, adverts on both sides.
M.billboardTall = function(r: R)
	r:block(-1.2, 0, -1.2, 1.2, 0.3, 1.2, DARK, "Metal")
	r:cyl(0, 7.2, 0, 14.4, 1.2, "y", DARK, "Metal")
	r:block(-1.2, 13.6, -0.7, 1.2, 14.0, 0.7, shade(DARK, 0.85), "Metal")
	r:block(-7.4, 14.4, -0.4, 7.4, 22.4, 0.4, shade(DARK, 1.25), "Metal")
	advert(r:block(-7, 14.8, -0.56, 7, 22, 0.56, PAPER, "SmoothPlastic"), true)
	r:block(-7.4, 14, -1.5, 7.4, 14.3, 0.4, DARK, "Metal")
	r:block(-7.4, 15.1, -1.55, 7.4, 15.2, -1.45, SILVER, "Metal")
	r:glow(r:block(-6.4, 14.3, -1.5, 6.4, 14.6, -1.2, rgb(255, 244, 214), "SmoothPlastic"), 0)
end

-- A post of a hoarding with its cap and a foot, round the origin.
local function hoardingPost(r: R, x: number)
	group(r, CFrame.new(x, 0, 0), function(q: R)
		q:piece(function(p: R)
			p:block(-0.25, 0, -0.25, 0.25, 5.9, 0.25, WOOD_DARK, "Wood")
			p:block(-0.32, 5.9, -0.32, 0.32, 6.05, 0.32, shade(WOOD_DARK, 0.85), "Wood")
			p:block(-0.34, 0, -0.34, 0.34, 0.3, 0.34, shade(WOOD_DARK, 0.85), "Wood")
		end, true)
	end)
end

-- A hoarding of pasted posters: a fence panel between two posts, a rail along its top and a
-- board along its foot, with a face for each poster.
local function hoarding(r: R, faces: number, panel: Color3)
	local half = faces * 2
	r:block(-half, 0.5, -0.12, half, 5.6, 0.12, panel, "WoodPlanks")
	r:block(-half, 5.6, -0.16, half, 5.85, 0.16, shade(panel, 0.8), "Wood")
	r:block(-half, 0.1, -0.1, half, 0.5, 0.1, shade(panel, 0.8), "Wood")
	for _, sx in { -1, 1 } do
		hoardingPost(r, sx * half)
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

-- A sandwich board outside a shop: two boards leaning together on a hinge at the top, held by a
-- bar each side, the advert on the front one over a ledge for the chalk.
M.aBoard = function(r: R)
	local lean = CFrame.new(0, 1.55, -0.35) * CFrame.Angles(math.rad(13), 0, 0)
	r:piece(function(p: R)
		p:block(-0.98, 2.98, -0.08, 0.98, 3.1, 0.08, BLACK, "Wood")
		p:boxAt(lean, 2, 3.2, 0.14, DARK, "Wood")
		p:boxAt(CFrame.new(0, 1.55, 0.35) * CFrame.Angles(math.rad(-13), 0, 0), 2, 3.2, 0.14, DARK, "Wood")
		p:boxAt(lean * CFrame.new(0, -1.3, -0.1), 1.9, 0.16, 0.06, WOOD, "Wood")
		for _, sx in { -1, 1 } do
			p:block(sx * 0.95 - 0.03, 0.87, -0.5, sx * 0.95 + 0.03, 0.93, 0.5, BLACK, "Wood")
		end
	end, true)
	advert(r:boxAt(lean * CFrame.new(0, 0.1, -0.1), 1.7, 2.6, 0.06, PAPER, "SmoothPlastic"))
end

-- Street clutter --------------------------------------------------------------------------------------

-- A traffic cone on its square foot with two white bands, round the origin.
local function cone(r: R, x: number, z: number)
	group(r, CFrame.new(x, 0, z), function(q: R)
		q:block(-0.7, 0, -0.7, 0.7, 0.16, 0.7, shade(ORANGE, 0.82), "SmoothPlastic")
		q:piece(function(p: R)
			p:block(-0.12, 2.3, -0.12, 0.12, 2.36, 0.12, ORANGE, "SmoothPlastic")
			p:cone(0, 1.26, 0, 2.2, 1.1, ORANGE, "SmoothPlastic")
			p:cyl(0, 1.0, 0, 0.26, 0.74, "y", WHITE, "SmoothPlastic")
			p:cyl(0, 1.6, 0, 0.2, 0.48, "y", WHITE, "SmoothPlastic")
		end, true)
	end)
end

M.trafficCone = function(r: R)
	cone(r, 0, 0)
end

-- Two cones with a striped bar between them, round a hole in the pavement.
M.coneBar = function(r: R)
	cone(r, -2.4, 0)
	cone(r, 2.4, 0)
	for k = 0, 2 do
		local x = -2.4 + k * 1.6
		r:block(x, 1.5, -0.1, x + 1.6, 1.8, 0.1, if k % 2 == 0 then YELLOW else BLACK, "SmoothPlastic")
	end
end

-- A wooden crate: the box with its four corner posts standing proud. One piece, round its
-- bottom middle.
local function crate(r: R, cf: CFrame)
	group(r, cf, function(q: R)
		q:piece(function(p: R)
			p:block(-0.85, 0, -0.85, 0.85, 1.7, 0.85, WOOD, "WoodPlanks")
			for _, c in { { -1, -1 }, { 1, -1 }, { -1, 1 }, { 1, 1 } } do
				p:block(c[1] * 0.85 - 0.12, 0, c[2] * 0.85 - 0.12, c[1] * 0.85 + 0.12, 1.66, c[2] * 0.85 + 0.12, WOOD_DARK, "WoodPlanks")
			end
		end, true)
	end)
end

-- Wooden crates left by a back door, two side by side and one on top.
M.crateStack = function(r: R)
	crate(r, CFrame.new(-0.7, 0, 0))
	crate(r, CFrame.new(-0.55, 1.7, 0) * CFrame.Angles(0, math.rad(10), 0))
	crate(r, CFrame.new(1.4, 0, 0.22) * CFrame.Angles(0, math.rad(-12), 0))
end

-- Bottle crates outside a shop: a stack of three in bright plastic and one beside it, the
-- tops of the bottles showing in the ones on top.
M.drinksCrates = function(r: R)
	r:piece(function(p: R)
		for i, col in { YELLOW, RED, BLUE } do
			local y = (i - 1) * 1.05
			p:boxAt(CFrame.new(-0.9, y + 0.5, 0) * CFrame.Angles(0, math.rad((i - 2) * 7), 0), 1.6, 1, 1.2, col, "SmoothPlastic")
		end
		p:block(0.3, 0.55, -0.64, 1.5, 0.75, -0.6, shade(GREEN, 0.7), "SmoothPlastic")
		local top = CFrame.new(-0.9, 2.6, 0) * CFrame.Angles(0, math.rad(7), 0)
		for i = 0, 2 do
			for j = 0, 1 do
				p:boxAt(top * CFrame.new(-0.5 + i * 0.5, 0.49, -0.25 + j * 0.5), 0.26, 0.1, 0.26, rgb(80, 120, 90), "SmoothPlastic")
				p:cyl(0.4 + i * 0.5, 1.06, -0.25 + j * 0.5, 0.12, 0.24, "y", rgb(120, 86, 60), "SmoothPlastic")
			end
		end
	end, true)
	r:block(0.1, 0, -0.6, 1.7, 1, 0.6, GREEN, "SmoothPlastic")
end

-- A box that sells newspapers: a post on a foot, the box in its colour, and in front a window
-- framing today's front page, a handle, a coin slot and the lid's hinge.
local function newsBox(r: R, col: Color3)
	r:block(-0.9, 1.3, -0.7, 0.9, 3.7, 0.7, col, "Metal")
	r:piece(function(p: R)
		p:block(-0.45, 0, -0.45, 0.45, 0.08, 0.45, DARK, "Metal")
		p:block(-0.3, 0.08, -0.3, 0.3, 1.3, 0.3, DARK, "Metal")
		p:block(-0.7, 2.25, -0.74, 0.7, 3.45, -0.7, DARK, "Metal")
		p:block(-0.6, 2.35, -0.78, 0.6, 3.35, -0.74, PAPER, "Metal")
		p:block(-0.5, 3.08, -0.81, 0.5, 3.24, -0.78, BLACK, "Metal")
		for _, y in { 2.8, 2.58 } do
			p:block(-0.5, y, -0.8, 0.3, y + 0.08, -0.78, SILVER, "Metal")
		end
		p:block(0.5, 3.5, -0.75, 0.75, 3.6, -0.7, BLACK, "Metal")
		p:block(-0.4, 2.02, -0.82, 0.4, 2.12, -0.7, BLACK, "Metal")
		p:cyl(0, 3.7, 0.7, 1.7, 0.14, "x", DARK, "Metal")
	end)
end

M.newsBox = function(r: R)
	newsBox(r, YELLOW)
end

M.newsBox2 = function(r: R)
	newsBox(r, RED)
end

-- A telephone box: a solid back, glass sides, a frame of corner posts and a rail over the open
-- front, a roof with a lit band and a crown, and on the back wall the telephone with its
-- handset, cord, keypad and coin slot over a shelf with a directory on it.
M.phoneBooth = function(r: R)
	r:block(-1.7, 0.25, 1.45, 1.7, 7.3, 1.7, TEAL, "Metal")
	for _, sx in { -1, 1 } do
		local side = r:glass(sx * 1.7, 0.25, -1.45, sx * 1.58, 7.3, 1.45)
		side.transp = 0.5
	end
	local band = r:block(-1.5, 7.4, -1.92, 1.5, 7.9, -1.85, SCREEN, "SmoothPlastic")
	r:glow(band, 8, 0.6, SCREEN_NIGHT)
	band.attrs = { NightColor = SCREEN_NIGHT }
	r:piece(function(p: R)
		p:block(-1.7, 0, -1.7, 1.7, 0.25, 1.7, DARK, "Metal")
		for _, sx in { -1, 1 } do
			p:block(sx * 1.6 - 0.12, 0.25, -1.7, sx * 1.6 + 0.12, 7.3, -1.45, TEAL, "Metal")
		end
		p:block(-1.48, 6.9, -1.7, 1.48, 7.3, -1.5, TEAL, "Metal")
		p:block(-1.85, 7.3, -1.85, 1.85, 8, 1.85, TEAL, "Metal")
		p:block(-1.4, 8, -1.4, 1.4, 8.3, 1.4, shade(TEAL, 0.85), "Metal")
		-- the telephone
		p:block(-0.6, 3.4, 1.0, 0.6, 5.0, 1.45, DARK, "Metal")
		p:block(-0.36, 3.7, 0.94, 0.2, 4.5, 1.0, SILVER, "Metal")
		p:block(0.3, 4.6, 0.94, 0.5, 4.7, 1.0, BLACK, "Metal")
		p:block(-0.82, 3.6, 0.8, -0.6, 4.7, 1.1, BLACK, "Metal")
		p:beam(Vector3.new(-0.71, 3.6, 0.95), Vector3.new(-0.3, 3.2, 0.98), 0.06, 0.06, BLACK, "Metal")
		p:block(-0.9, 2.5, 0.8, 0.9, 2.62, 1.45, DARK, "Metal")
		p:block(-0.6, 2.62, 0.9, 0.3, 2.86, 1.35, rgb(214, 186, 90), "Metal")
	end)
end

-- A parked scooter, its nose toward local -Z: tyres and hubs, a fork, the footboard, the body
-- and the leg shield in its colour, a seat, handlebars with mirrors at their ends, a headlight, a tail light
-- over the number plate, and its stand. The colour is two parts; the rest is one piece.
local function scooter(r: R, col: Color3)
	local lean = CFrame.new(0, 2.1, -1.55) * CFrame.Angles(math.rad(14), 0, 0)
	r:block(-0.55, 0.9, 0.3, 0.55, 2.1, 2.3, col, "SmoothPlastic")
	r:boxAt(lean, 1.1, 2.7, 0.3, col, "SmoothPlastic")
	-- (the bars and mirrors are parts of their own, so the piece's box stays as narrow as the body)
	r:block(-1, 3.4, -1.3, 1, 3.6, -1.1, DARK, "Metal")
	for _, sx in { -1, 1 } do
		r:block(sx * 0.86 - 0.12, 3.18, -1.36, sx * 0.86 + 0.12, 3.4, -1.3, SILVER, "Metal")
	end
	r:piece(function(p: R)
		for _, z in { -1.9, 1.7 } do
			p:cyl(0, 0.65, z, 0.36, 1.3, "x", BLACK, "Metal")
			p:cyl(0, 0.65, z, 0.44, 0.6, "x", SILVER, "Metal")
		end
		p:beam(Vector3.new(0, 1.0, -1.7), Vector3.new(0, 0.65, -1.9), 0.14, 0.14, DARK, "Metal")
		p:block(-0.45, 0.7, -1.6, 0.45, 0.95, 0.5, DARK, "Metal")
		p:block(-0.45, 2.1, 0.4, 0.45, 2.4, 2.1, rgb(50, 52, 62), "Metal")
		p:boxAt(lean * CFrame.new(0, 0.9, -0.2), 0.5, 0.35, 0.1, rgb(255, 240, 200), "Metal")
		p:block(-0.25, 1.6, 2.3, 0.25, 1.85, 2.36, rgb(220, 80, 76), "Metal")
		p:block(-0.3, 1.1, 2.3, 0.3, 1.45, 2.34, WHITE, "Metal")
		p:beam(Vector3.new(0.3, 0.8, 0.2), Vector3.new(0.6, 0, 0.4), 0.08, 0.08, DARK, "Metal")
	end)
end

M.scooter = function(r: R)
	scooter(r, TEAL)
end

M.scooter2 = function(r: R)
	scooter(r, rgb(255, 170, 190))
end

-- Four short posts in a row, to keep cars off the pavement: each a dark post with a yellow band
-- and a rounded cap.
M.bollardRow = function(r: R)
	for k = 0, 3 do
		local x = -3.6 + k * 2.4
		r:cyl(x, 1.1, 0, 2.2, 0.56, "y", DARK, "Metal")
		r:cyl(x, 1.7, 0, 0.3, 0.62, "y", YELLOW, "Metal")
	end
end

-- A length of pedestrian rail along a kerb: three posts, a top rail and a lower one, and bars
-- between them.
M.guardRail = function(r: R)
	r:piece(function(p: R)
		for _, x in { -4.2, 0, 4.2 } do
			p:cyl(x, 1.4, 0, 2.8, 0.36, "y", WHITE, "Metal")
		end
		p:block(-4.2, 1.1, -0.1, 4.2, 1.36, 0.1, GREEN, "Metal")
		for k = 0, 7 do
			if k ~= 4 then
				local x = -3.6 + k * 1.05
				p:block(x - 0.04, 1.36, -0.04, x + 0.04, 2.3, 0.04, GREEN, "Metal")
			end
		end
	end, true)
	r:block(-4.2, 2.3, -0.1, 4.2, 2.56, 0.1, GREEN, "Metal")
end

-- A street sign: a post on a collar with a cap, the street's name on a plate at the top and a
-- no entry sign under it.
M.streetSignPost = function(r: R)
	r:cyl(0, 0.2, 0, 0.4, 0.5, "y", DARK, "Metal")
	r:cyl(0, 4.4, 0, 8.8, 0.3, "y", METAL, "Metal")
	r:cyl(0, 8.85, 0, 0.1, 0.38, "y", DARK, "Metal")
	local plate = r:block(-1.9, 7.6, -0.26, 1.9, 8.6, -0.16, BLUE, "SmoothPlastic")
	plate.name = "Plate"
	plate.attrs = { SignFace = "Front" }
	r:cyl(0, 6, -0.2, 0.1, 1.9, "z", RED, "SmoothPlastic")
	r:block(-0.6, 5.85, -0.3, 0.6, 6.15, -0.25, WHITE, "SmoothPlastic")
end

-- Rubbish bags put out for the morning, the black ones tied at the neck.
M.binBags = function(r: R)
	r:piece(function(p: R)
		local bags = {
			{ CFrame.new(0, 0.8, 0) * CFrame.Angles(0.2, 0.4, 0.1), 2, 1.7, 1.8, rgb(84, 92, 112) },
			{ CFrame.new(1.4, 0.65, 0.4) * CFrame.Angles(-0.2, 1, 0.2), 1.6, 1.3, 1.5, rgb(104, 112, 132) },
		}
		for _, b in bags do
			p:lump(b[1], b[2], b[3], b[4], b[5], "SmoothPlastic")
			local top = (b[1] * CFrame.new(0, b[3] / 2, 0)).Position
			p:block(top.X - 0.13, top.Y - 0.12, top.Z - 0.13, top.X + 0.13, top.Y + 0.2, top.Z + 0.13, shade(b[5], 0.85), "SmoothPlastic")
		end
	end, true)
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
