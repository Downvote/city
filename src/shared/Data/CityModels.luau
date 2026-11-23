--!strict
-- The town's other buildings and landmarks, the ones nobody builds: downtown's towers and shops,
-- the civic quarter's school, clinic, library, museum and fire station, the farm and the lookout
-- in the hills, the fairground pier, the lighthouse and the beach huts. Each is a recipe drawn
-- round its own footprint's middle, front facing local -Z (the placement turns it to its street).
-- Most are made from a few kinds (towers, shop rows, houses) with their own colours and sizes.
--
-- Spinning parts: a model's "Hub" part gives the axle (its X axis); parts named "Spin" turn with
-- it and parts named "Cabin" go round with it but stay upright (World/Ambience moves them).

local Recipe = require(script.Parent.Parent.Build.Recipe)

type R = Recipe.Recipe

local CityModels = {}
CityModels.Models = {} :: { [string]: (R) -> () }
local M = CityModels.Models

local function rgb(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end

local WHITE = rgb(250, 250, 248)
local GLASS = rgb(150, 206, 240)
local DOOR = rgb(70, 86, 110)
local WOOD = rgb(196, 146, 96)
local WOOD_DARK = rgb(150, 104, 66)
local STONE = rgb(214, 214, 220)
local ROCK = rgb(150, 152, 160)
local LEAF = rgb(78, 160, 70)
local LEAF_DARK = rgb(52, 128, 66)
local BARK = rgb(140, 98, 62)
local METAL = rgb(186, 192, 202)
local DARK = rgb(64, 70, 86)
local WATER = rgb(84, 168, 236)

local function shade(c: Color3, k: number): Color3
	return Color3.new(math.min(1, c.R * k), math.min(1, c.G * k), math.min(1, c.B * k))
end

-- A window that's lit after dark: glass by day, warm lamplight at night (the World service swaps
-- its colour and material when the lamps come on).
local LAMPLIGHT = rgb(255, 224, 156)
local function lit(r: R, pane: Recipe.Prim): Recipe.Prim
	r:glow(pane, 0)
	pane.attrs = { NightColor = LAMPLIGHT }
	return pane
end
CityModels.lit = lit

-- Kinds of building ---------------------------------------------------------------------------------

export type TowerSpec = {
	w: number,
	d: number,
	floors: number,
	wall: Color3,
	glass: Color3?,
	base: Color3?,
	trim: Color3?,
	top: string?, -- "ac" | "helipad" | "spire" | "garden" | "sign"
	sign: Color3?,
	balconies: boolean?, -- flats: a balcony on every floor of the front
}

-- A tower: a ground floor of shopfront glass under a canopy, then floors with a band of windows
-- right round each, a crown and something on the roof.
function CityModels.tower(spec: TowerSpec): (R) -> ()
	return function(r: R)
		local w, d = spec.w, spec.d
		local fh = 4.2
		local g = fh * 1.3
		local h = g + spec.floors * fh
		local glass = spec.glass or GLASS
		local trim = spec.trim or WHITE
		local base = spec.base or shade(spec.wall, 0.9)
		r:block(-w / 2, 0, -d / 2, w / 2, g, d / 2, base, "Plaster")
		r:block(-w / 2 - 0.3, 0, -d / 2 - 0.3, w / 2 + 0.3, 0.9, d / 2 + 0.3, shade(base, 0.8), "Concrete")
		r:block(-w / 2 + 1.6, 0.9, -d / 2 - 0.15, w / 2 - 1.6, g - 0.9, -d / 2, glass, "Glass")
		-- the way in: a canopy on two columns, double doors, and a sign band over the ground floor
		r:block(-5, g - 0.9, -d / 2 - 4, 5, g - 0.4, -d / 2, trim, "SmoothPlastic")
		for _, cx in { -4.4, 4.4 } do
			r:cyl(cx, (g - 0.9) / 2, -d / 2 - 3.4, g - 0.9, 0.6, "y", trim, "SmoothPlastic")
		end
		r:block(-2.4, 0.2, -d / 2 - 0.3, 2.4, g - 1.6, -d / 2 - 0.1, DOOR, "SmoothPlastic")
		r:block(-0.1, 0.2, -d / 2 - 0.34, 0.1, g - 1.6, -d / 2 - 0.3, trim, "SmoothPlastic")
		r:block(
			-w / 2 - 0.2,
			g - 0.4,
			-d / 2 - 0.4,
			w / 2 + 0.2,
			g + 0.5,
			d / 2 + 0.4,
			spec.sign or trim,
			"SmoothPlastic"
		)
		r:block(-w / 2, g, -d / 2, w / 2, h, d / 2, spec.wall, "Plaster")
		-- pilasters up the corners and between the windows
		for _, cx in { -w / 2, w / 2 } do
			for _, cz in { -d / 2, d / 2 } do
				r:block(cx - 0.7, g, cz - 0.7, cx + 0.7, h, cz + 0.7, trim, "SmoothPlastic")
			end
		end
		local bays = math.max(2, math.floor(w / 9))
		for k = 1, bays - 1 do
			local x = -w / 2 + k * w / bays
			r:block(x - 0.35, g + 0.5, -d / 2 - 0.25, x + 0.35, h, -d / 2, spec.wall, "Plaster")
			r:block(x - 0.35, g + 0.5, d / 2, x + 0.35, h, d / 2 + 0.25, spec.wall, "Plaster")
		end
		if spec.balconies then
			for k = 0, spec.floors - 1 do
				local y = g + k * fh + 0.9
				for _, sx in { -1, 1 } do
					local x = sx * w / 4
					r:block(x - 3.4, y, -d / 2 - 2.2, x + 3.4, y + 0.3, -d / 2, trim, "SmoothPlastic")
					r:block(
						x - 3.4,
						y + 0.3,
						-d / 2 - 2.2,
						x + 3.4,
						y + 1.5,
						-d / 2 - 2,
						shade(spec.wall, 0.86),
						"SmoothPlastic"
					)
				end
			end
		end
		for k = 0, spec.floors - 1 do
			local y1, y2 = g + k * fh + 1.1, g + (k + 1) * fh - 0.7
			local bands = {
				r:block(-w / 2 + 1, y1, -d / 2 - 0.12, w / 2 - 1, y2, -d / 2, glass, "Glass"),
				r:block(-w / 2 + 1, y1, d / 2, w / 2 - 1, y2, d / 2 + 0.12, glass, "Glass"),
				r:block(-w / 2 - 0.12, y1, -d / 2 + 1, -w / 2, y2, d / 2 - 1, glass, "Glass"),
				r:block(w / 2, y1, -d / 2 + 1, w / 2 + 0.12, y2, d / 2 - 1, glass, "Glass"),
			}
			-- somebody is always working late: about a third of the floors stay lit after dark
			for side, band in bands do
				if (k * 5 + side * 3 + spec.floors) % 3 == 0 then
					lit(r, band)
				end
			end
		end
		r:block(-w / 2 - 0.4, h, -d / 2 - 0.4, w / 2 + 0.4, h + 1, d / 2 + 0.4, trim, "SmoothPlastic")
		-- a parapet round the roof, a stair hut and a water tank on legs
		r:block(-w / 2 - 0.4, h + 1, -d / 2 - 0.4, w / 2 + 0.4, h + 2.2, -d / 2 + 0.4, trim, "SmoothPlastic")
		r:block(-w / 2 - 0.4, h + 1, d / 2 - 0.4, w / 2 + 0.4, h + 2.2, d / 2 + 0.4, trim, "SmoothPlastic")
		r:block(-w / 2 - 0.4, h + 1, -d / 2 + 0.4, -w / 2 + 0.4, h + 2.2, d / 2 - 0.4, trim, "SmoothPlastic")
		r:block(w / 2 - 0.4, h + 1, -d / 2 + 0.4, w / 2 + 0.4, h + 2.2, d / 2 - 0.4, trim, "SmoothPlastic")
		r:block(w / 2 - 9, h + 1, d / 2 - 8, w / 2 - 3, h + 4.4, d / 2 - 3, shade(spec.wall, 0.9), "Plaster")
		r:cyl(-w / 2 + 6, h + 4.6, d / 2 - 6, 3.6, 4.4, "y", rgb(196, 150, 110), "WoodPlanks")
		for _, o in { { -1.4, -1.4 }, { 1.4, 1.4 }, { -1.4, 1.4 }, { 1.4, -1.4 } } do
			local lx, lz = -w / 2 + 6 + o[1], d / 2 - 6 + o[2]
			r:block(lx - 0.2, h + 1, lz - 0.2, lx + 0.2, h + 2.8, lz + 0.2, DARK, "Metal")
		end
		local top = spec.top or "ac"
		if top == "ac" then
			r:block(-w / 4, h + 1, -d / 6, -w / 4 + 5, h + 3, -d / 6 + 4, METAL, "Metal")
			r:block(w / 6, h + 1, d / 8, w / 6 + 4, h + 2.6, d / 8 + 5, METAL, "Metal")
		elseif top == "helipad" then
			r:cyl(0, h + 1.3, 0, 0.6, math.min(w, d) - 4, "y", DARK, "SmoothPlastic")
			r:block(-1.6, h + 1.6, -4, 1.6, h + 1.7, 4, WHITE, "SmoothPlastic")
		elseif top == "spire" then
			r:block(-w / 3, h + 1, -d / 3, w / 3, h + 5, d / 3, spec.wall, "SmoothPlastic")
			r:cyl(0, h + 15, 0, 20, 0.8, "y", METAL, "Metal")
			r:glow(r:ball(0, h + 25.5, 0, 1.4, rgb(255, 90, 80), "Neon"), 0)
		elseif top == "garden" then
			r:block(-w / 2 + 1.5, h + 1, -d / 2 + 1.5, w / 2 - 1.5, h + 1.6, d / 2 - 1.5, LEAF, "SmoothPlastic")
			r:ball(-w / 5, h + 3.2, 0, 4, LEAF_DARK, "SmoothPlastic")
			r:ball(w / 5, h + 3, d / 6, 3.4, LEAF_DARK, "SmoothPlastic")
		elseif top == "sign" then
			local sign = spec.sign or rgb(255, 120, 100)
			r:block(-w / 3, h + 1, -1, w / 3, h + 6, 0, sign, "SmoothPlastic")
			r:block(-w / 3 - 0.5, h + 1, -0.5, -w / 3, h + 6, 0.5, METAL, "Metal")
		end
	end
end

export type ShopSpec = {
	w: number,
	d: number,
	floors: number,
	wall: Color3,
	awning: Color3?,
	trim: Color3?,
	cols: number?,
	sign: Color3?,
}

-- A shop row building: a shopfront and striped awning at the bottom, rows of windows above, a
-- cornice and a sign board.
function CityModels.shop(spec: ShopSpec): (R) -> ()
	return function(r: R)
		local w, d = spec.w, spec.d
		local fh = 4.4
		local h = spec.floors * fh + 0.6
		local trim = spec.trim or WHITE
		r:block(-w / 2, 0, -d / 2, w / 2, h, d / 2, spec.wall, "Brick")
		r:block(-w / 2 - 0.2, 0, -d / 2 - 0.2, w / 2 + 0.2, 0.8, d / 2 + 0.2, shade(spec.wall, 0.78), "Concrete")
		lit(r, r:block(-w / 2 + 1.2, 0.8, -d / 2 - 0.15, w / 2 - 1.2, fh - 0.8, -d / 2, GLASS, "Glass"))
		-- the shopfront's frame, and the door with its own frame and a step
		r:block(-w / 2 + 0.9, 0.8, -d / 2 - 0.22, -w / 2 + 1.3, fh - 0.6, -d / 2, trim, "SmoothPlastic")
		r:block(w / 2 - 1.3, 0.8, -d / 2 - 0.22, w / 2 - 0.9, fh - 0.6, -d / 2, trim, "SmoothPlastic")
		r:block(-1.8, 0.2, -d / 2 - 0.26, 1.8, 4, -d / 2 - 0.1, trim, "SmoothPlastic")
		r:block(-1.4, 0.2, -d / 2 - 0.32, 1.4, 3.6, -d / 2 - 0.2, DOOR, "SmoothPlastic")
		r:block(-2.2, 0, -d / 2 - 1.4, 2.2, 0.2, -d / 2, STONE, "Concrete")
		-- the striped awning, sloping out
		local stripes = 6
		local awning = spec.awning or rgb(255, 110, 100)
		for k = 0, stripes - 1 do
			local x1 = -w / 2 + 1 + k * (w - 2) / stripes
			local x2 = x1 + (w - 2) / stripes
			local col = if k % 2 == 0 then awning else WHITE
			r:boxAt(
				CFrame.new((x1 + x2) / 2, fh - 0.3, -d / 2 - 1.6) * CFrame.Angles(math.rad(22), 0, 0),
				x2 - x1,
				0.2,
				3.4,
				col,
				"Fabric"
			)
		end
		local cols = spec.cols or math.max(2, math.floor(w / 6))
		for f = 1, spec.floors - 1 do
			local y1 = f * fh + 1
			for c = 0, cols - 1 do
				local x = -w / 2 + (c + 0.5) * w / cols
				local pane = r:block(x - 1.2, y1, -d / 2 - 0.12, x + 1.2, y1 + 2.4, -d / 2, GLASS, "Glass")
				if (c + f) % 2 == 0 then
					lit(r, pane)
				end
				-- a sill with a flower box under each window
				r:block(x - 1.5, y1 - 0.5, -d / 2 - 0.7, x + 1.5, y1, -d / 2, trim, "SmoothPlastic")
				local flowers = if c % 2 == 0 then rgb(250, 130, 150) else rgb(255, 210, 90)
				r:block(x - 1.3, y1, -d / 2 - 0.6, x + 1.3, y1 + 0.5, -d / 2 - 0.15, flowers, "SmoothPlastic")
			end
			r:block(-w / 2 - 0.1, y1, -d / 2 + 1, -w / 2, y1 + 2.4, d / 2 - 1, GLASS, "Glass")
			r:block(w / 2, y1, -d / 2 + 1, w / 2 + 0.1, y1 + 2.4, d / 2 - 1, GLASS, "Glass")
		end
		r:block(-w / 2 - 0.4, h - 0.6, -d / 2 - 0.4, w / 2 + 0.4, h + 0.3, d / 2 + 0.4, trim, "SmoothPlastic")
		if spec.sign then
			r:block(-w / 4, h + 0.3, -d / 2 + 0.2, w / 4, h + 2.6, -d / 2 + 0.8, spec.sign, "SmoothPlastic")
		end
		-- on the roof: an air unit and a vent
		r:block(w / 2 - 7, h + 0.3, d / 2 - 6, w / 2 - 3, h + 1.9, d / 2 - 2.5, METAL, "Metal")
		r:cyl(-w / 2 + 4, h + 1.1, d / 2 - 4, 1.6, 1.2, "y", METAL, "Metal")
	end
end

-- A small house with a gable roof, a door and two windows.
local function house(r: R, x: number, z: number, w: number, d: number, wall: Color3, roof: Color3, yaw: number?)
	local f = CFrame.new(x, 0, z) * CFrame.Angles(0, math.rad(yaw or 0), 0)
	local h = 5.4
	r:boxAt(f * CFrame.new(0, h / 2, 0), w, h, d, wall, "Plaster")
	r:boxAt(f * CFrame.new(0, 0.3, 0), w + 0.3, 0.6, d + 0.3, shade(wall, 0.8), "Concrete")
	local rh = 3.4
	r:wedge(f * CFrame.new(0, h + rh / 2, -d / 4 - 0.25), w + 1, rh, d / 2 + 0.5, roof, "RoofShingles")
	r:wedge(
		f * CFrame.new(0, h + rh / 2, d / 4 + 0.25) * CFrame.Angles(0, math.pi, 0),
		w + 1,
		rh,
		d / 2 + 0.5,
		roof,
		"RoofShingles"
	)
	-- a chimney, a framed door on a step, and a sill under each window
	r:boxAt(f * CFrame.new(w / 4, h + rh * 0.8, d / 5), 1.4, 3, 1.4, rgb(196, 120, 100), "Brick")
	r:boxAt(f * CFrame.new(0, 1.9, -d / 2 - 0.08), 2.2, 3.8, 0.16, WHITE, "SmoothPlastic")
	r:boxAt(f * CFrame.new(0, 1.7, -d / 2 - 0.14), 1.8, 3.4, 0.16, DOOR, "SmoothPlastic")
	r:boxAt(f * CFrame.new(0, 0.15, -d / 2 - 0.9), 2.6, 0.3, 1.6, STONE, "Concrete")
	for _, sx in { -1, 1 } do
		lit(r, r:boxAt(f * CFrame.new(sx * w / 4 + sx * 0.6, 3, -d / 2 - 0.08), 1.6, 1.6, 0.16, GLASS, "Glass"))
		r:boxAt(f * CFrame.new(sx * w / 4 + sx * 0.6, 2.05, -d / 2 - 0.2), 2, 0.25, 0.4, WHITE, "SmoothPlastic")
	end
end
CityModels.house = house

-- A low poly tree: an eight sided trunk under a crown of faceted lumps, each a different green and
-- turned its own way (Build/LowPoly cuts the shapes).
local function lowTree(r: R, x: number, y: number, z: number, s: number)
	r:cyl(x, y + 2 * s, z, 4 * s, 1.1 * s, "y", BARK, "Wood")
	r:lump(CFrame.new(x, y + 5.2 * s, z) * CFrame.Angles(0.2, 0.6, 0.1), 6.4 * s, 5 * s, 6 * s, LEAF)
	r:lump(
		CFrame.new(x + 1.9 * s, y + 6.4 * s, z - 0.9 * s) * CFrame.Angles(0.5, 1.3, 0.3),
		4.6 * s,
		3.8 * s,
		4.4 * s,
		shade(LEAF, 1.1)
	)
	r:lump(
		CFrame.new(x - 1.8 * s, y + 6 * s, z + 1.1 * s) * CFrame.Angles(-0.3, 2.2, 0.4),
		4.8 * s,
		4 * s,
		4.6 * s,
		shade(LEAF, 0.88)
	)
	r:lump(
		CFrame.new(x + 0.2 * s, y + 7.9 * s, z + 0.5 * s) * CFrame.Angles(0.4, 0.2, -0.5),
		3.8 * s,
		3 * s,
		3.6 * s,
		shade(LEAF, 1.2)
	)
end
CityModels.lowTree = lowTree

-- A low poly pine: a trunk under three stacked cones, each a little smaller and turned a little.
local function lowPine(r: R, x: number, y: number, z: number, s: number)
	r:cyl(x, y + 1.3 * s, z, 2.6 * s, 0.9 * s, "y", BARK, "Wood")
	local tiers = { { 4.3, 4.6, 6.4, 1 }, { 6.5, 4, 5, 1.08 }, { 8.7, 3.6, 3.4, 1.16 } }
	for i, t in tiers do
		local cone = r:cone(x, y + t[1] * s, z, t[2] * s, t[3] * s, shade(LEAF_DARK, t[4]))
		cone.cf = cone.cf * CFrame.Angles(0, math.rad(i * 22.5), 0)
	end
end
CityModels.lowPine = lowPine

M.lowTree = function(r: R)
	lowTree(r, 0, 0, 0, 1)
end
M.lowTreeBig = function(r: R)
	lowTree(r, 0, 0, 0, 1.4)
end
M.lowPine = function(r: R)
	lowPine(r, 0, 0, 0, 1)
end
M.lowPineBig = function(r: R)
	lowPine(r, 0, 0, 0, 1.5)
end

local function bench(r: R, x: number, z: number, yaw: number)
	local f = CFrame.new(x, 0, z) * CFrame.Angles(0, math.rad(yaw), 0)
	r:boxAt(f * CFrame.new(0, 1.2, 0), 4, 0.3, 1.4, WOOD, "Wood")
	r:boxAt(f * CFrame.new(0, 2, 0.6), 4, 1.2, 0.25, WOOD, "Wood")
	for _, sx in { -1.6, 1.6 } do
		r:boxAt(f * CFrame.new(sx, 0.55, 0), 0.3, 1.1, 1.2, DARK, "Metal")
	end
end

-- A parked car: a body, a cabin with windows, wheels and lights.
local function car(r: R, x: number, y: number, z: number, yaw: number, col: Color3)
	local f = CFrame.new(x, y, z) * CFrame.Angles(0, math.rad(yaw), 0)
	r:boxAt(f * CFrame.new(0, 1.5, 0), 4.2, 1.5, 9, col, "SmoothPlastic")
	r:boxAt(f * CFrame.new(0, 2.85, 0.5), 3.8, 1.3, 4.6, shade(col, 0.94), "SmoothPlastic")
	r:boxAt(f * CFrame.new(0, 2.85, 0.5), 3.86, 0.9, 4, rgb(120, 170, 210), "Glass")
	r:boxAt(f * CFrame.new(0, 2.85, 0.5), 3.4, 0.9, 4.66, rgb(120, 170, 210), "Glass")
	for _, wx in { -1.9, 1.9 } do
		for _, wz in { -2.8, 2.8 } do
			r:boxAt(f * CFrame.new(wx, 0.75, wz), 0.7, 1.5, 1.5, rgb(50, 50, 58), "SmoothPlastic")
		end
	end
	r:boxAt(f * CFrame.new(0, 1.7, -4.52), 3.6, 0.4, 0.1, rgb(255, 244, 200), "SmoothPlastic")
	r:boxAt(f * CFrame.new(0, 1.7, 4.52), 3.6, 0.4, 0.1, rgb(230, 70, 70), "SmoothPlastic")
end
CityModels.car = car

local CAR_COLORS = {
	rgb(236, 110, 100),
	rgb(110, 170, 236),
	rgb(250, 210, 110),
	rgb(250, 250, 248),
	rgb(120, 204, 160),
	rgb(110, 110, 130),
}
for k, col in CAR_COLORS do
	M["parkedCar" .. k] = function(r: R)
		car(r, 0, 0, 0, 0, col)
	end
end

-- The landscaping round a building `w` by `d` (the building's footprint plus `margin` each side),
-- front to local -Z. "garden": a lawn pad, a clipped hedge round the edge with a gap for the path,
-- gate posts with lamps, a paved path to the door, shrubs in the back corners and flower beds by
-- the path. "plaza": stone tubs of flowers at the corners, and benches by the door. No trees: the
-- user asked for none near the roads, and every lot fronts one.
function CityModels.lot(w: number, d: number, kind: string, margin: number): (R) -> ()
	return function(r: R)
		local hw, hd = w / 2, d / 2
		local hedge = rgb(60, 136, 66)
		local blooms = { rgb(255, 140, 160), rgb(255, 214, 100), rgb(250, 250, 250), rgb(190, 150, 240) }
		if kind == "garden" then
			r:block(-hw, 0, -hd, hw, 0.16, hd, rgb(122, 196, 88), "Grass")
			r:block(-hw, 0, hd - 1.5, hw, 2.2, hd, hedge, "SmoothPlastic")
			r:block(-hw, 0, -hd, -hw + 1.5, 2.2, hd - 1.5, hedge, "SmoothPlastic")
			r:block(hw - 1.5, 0, -hd, hw, 2.2, hd - 1.5, hedge, "SmoothPlastic")
			r:block(-hw + 1.5, 0, -hd, -4, 2.2, -hd + 1.5, hedge, "SmoothPlastic")
			r:block(4, 0, -hd, hw - 1.5, 2.2, -hd + 1.5, hedge, "SmoothPlastic")
			r:block(-2.6, 0.16, -hd, 2.6, 0.22, -hd + margin, rgb(232, 226, 214), "Pavement")
			-- gate posts either side of the path, with a lamp on each
			for _, sx in { -1, 1 } do
				r:block(sx * 3.3 - 0.5, 0, -hd - 0.1, sx * 3.3 + 0.5, 3, -hd + 0.9, rgb(226, 222, 214), "Concrete")
				r:glow(r:ball(sx * 3.3, 3.5, -hd + 0.4, 1, rgb(255, 236, 190), "SmoothPlastic"), 10, 0.8)
				-- round shrubs in the back corners (no trees this close to a road)
				r:ball(sx * (hw - 4), 1.6, hd - 4, 4, LEAF, "SmoothPlastic")
				r:ball(sx * (hw - 6.4), 1.1, hd - 3.4, 2.6, shade(LEAF, 1.14), "SmoothPlastic")
				-- a flower bed either side of the path
				r:block(sx * 3.4, 0.16, -hd + 2, sx * 8.6, 0.4, -hd + 4, rgb(124, 92, 66), "Ground")
				for k = 0, 2 do
					r:ball(
						sx * (4.2 + k * 1.7),
						0.7,
						-hd + 3,
						1.1,
						blooms[(k + (if sx > 0 then 1 else 0)) % #blooms + 1]
					)
				end
			end
		else
			-- a paved forecourt: flower tubs at the corners, benches by the door, a bike rack
			for _, sx in { -1, 1 } do
				for _, sz in { -1, 1 } do
					local x, z = sx * (hw - 3), sz * (hd - 3)
					r:block(x - 2.2, 0, z - 2.2, x + 2.2, 1.1, z + 2.2, rgb(226, 222, 214), "Concrete")
					r:block(x - 1.8, 1.1, z - 1.8, x + 1.8, 1.3, z + 1.8, rgb(110, 84, 62), "Ground")
					r:ball(x, 1.9, z, 2.8, LEAF, "SmoothPlastic")
					local col = blooms[(if sx > 0 then 1 else 0) * 2 + (if sz > 0 then 1 else 0) + 1]
					r:ball(x + 0.9, 2.5, z - 0.8, 1.1, col, "SmoothPlastic")
					r:ball(x - 0.8, 2.6, z + 0.7, 1, col, "SmoothPlastic")
				end
				bench(r, sx * 8, -hd + 2, 180)
			end
		end
	end
end

-- A light street lamp: a pole, an arm and a lit head.
M.streetLamp = function(r: R)
	r:cyl(0, 4.5, 0, 9, 0.5, "y", DARK, "Metal")
	r:block(-0.25, 8.6, -2.4, 0.25, 9, 0.2, DARK, "Metal")
	local head = r:block(-0.7, 8.2, -3, 0.7, 8.7, -1.6, rgb(255, 236, 190), "SmoothPlastic")
	r:glow(head, 16, 1)
end

M.benchLite = function(r: R)
	bench(r, 0, 0, 0)
end

-- Downtown ------------------------------------------------------------------------------------------

M.hotel = CityModels.tower({
	w = 44,
	d = 30,
	floors = 14,
	wall = rgb(250, 236, 214),
	glass = rgb(120, 190, 236),
	trim = rgb(255, 196, 100),
	top = "sign",
	sign = rgb(255, 130, 90),
})
M.officeBlue =
	CityModels.tower({ w = 34, d = 30, floors = 11, wall = rgb(104, 160, 224), glass = rgb(176, 222, 250), top = "ac" })
M.officeTeal = CityModels.tower({
	w = 30,
	d = 30,
	floors = 16,
	wall = rgb(70, 190, 186),
	glass = rgb(190, 240, 236),
	top = "helipad",
})
M.skyTower = CityModels.tower({
	w = 38,
	d = 38,
	floors = 26,
	wall = rgb(140, 190, 240),
	glass = rgb(206, 236, 255),
	trim = WHITE,
	top = "spire",
})
M.apartmentPeach = CityModels.tower({
	balconies = true,
	w = 32,
	d = 26,
	floors = 9,
	wall = rgb(255, 196, 166),
	glass = GLASS,
	trim = WHITE,
	top = "garden",
})
M.apartmentMint = CityModels.tower({
	w = 32,
	d = 26,
	floors = 8,
	wall = rgb(176, 232, 206),
	glass = GLASS,
	trim = WHITE,
	top = "ac",
	balconies = true,
})
M.apartmentLilac = CityModels.tower({
	balconies = true,
	w = 28,
	d = 26,
	floors = 10,
	wall = rgb(206, 190, 246),
	glass = GLASS,
	trim = WHITE,
	top = "garden",
})
M.shopCoral = CityModels.shop({
	w = 30,
	d = 22,
	floors = 3,
	wall = rgb(255, 160, 140),
	awning = rgb(255, 255, 255),
	sign = rgb(60, 170, 240),
})
M.shopYellow = CityModels.shop({
	w = 26,
	d = 22,
	floors = 2,
	wall = rgb(255, 214, 110),
	awning = rgb(64, 186, 104),
	sign = rgb(255, 110, 100),
})
M.shopBlue =
	CityModels.shop({ w = 28, d = 22, floors = 3, wall = rgb(130, 196, 250), awning = rgb(255, 196, 70), sign = WHITE })
M.shopMint = CityModels.shop({
	w = 24,
	d = 22,
	floors = 2,
	wall = rgb(160, 228, 196),
	awning = rgb(255, 120, 160),
	sign = rgb(255, 196, 70),
})
M.deptStore = CityModels.shop({
	w = 70,
	d = 40,
	floors = 3,
	wall = rgb(255, 250, 240),
	awning = rgb(255, 110, 100),
	cols = 10,
	sign = rgb(255, 110, 100),
})

M.cinema = function(r: R)
	local w, d, h = 56, 40, 14
	local wall = rgb(120, 92, 200)
	r:block(-w / 2, 0, -d / 2, w / 2, h, d / 2, wall, "SmoothPlastic")
	r:block(-w / 2 + 2, 0.3, -d / 2 - 0.15, w / 2 - 2, 5, -d / 2, GLASS, "Glass")
	-- the marquee over the doors, lit
	r:glow(r:block(-18, 5.4, -d / 2 - 4, 18, 8.6, -d / 2, rgb(255, 214, 90), "Neon"), 18, 1.2)
	r:block(-17, 5.8, -d / 2 - 4.15, 17, 8.2, -d / 2 - 4, WHITE, "SmoothPlastic")
	-- the tall sign blade on the corner
	r:glow(r:block(w / 2 - 3, 7, -d / 2 - 2.5, w / 2 - 1.8, h + 8, -d / 2 + 0.5, rgb(255, 110, 120), "Neon"), 0)
	-- poster frames
	for _, x in { -w / 2 + 4, w / 2 - 8 } do
		r:block(x, 9.5, -d / 2 - 0.2, x + 4, 13, -d / 2, rgb(255, 196, 70), "SmoothPlastic")
	end
	r:block(-w / 2 - 0.4, h, -d / 2 - 0.4, w / 2 + 0.4, h + 1, d / 2 + 0.4, rgb(255, 214, 90), "SmoothPlastic")
end

M.station = function(r: R)
	local w, d, h = 80, 22, 8
	local wall = rgb(250, 240, 222)
	r:block(-w / 2, 0, -d / 2, w / 2, h, d / 2, wall, "SmoothPlastic")
	-- the long arched roof
	r:cyl(0, h, 0, w + 4, d + 4, "x", rgb(255, 128, 100), "SmoothPlastic")
	r:block(-w / 2 + 2, 0.3, -d / 2 - 0.15, w / 2 - 2, 5.5, -d / 2, GLASS, "Glass")
	-- the clock over the doors
	r:cyl(0, h + 7, -d / 2 - 1.8, 0.6, 6, "z", WHITE, "SmoothPlastic")
	r:cyl(0, h + 7, -d / 2 - 2.15, 0.2, 4.6, "z", DARK, "SmoothPlastic")
	-- the platform and the line behind, with a train waiting
	r:block(-w / 2 - 10, 0, d / 2, w / 2 + 10, 1.2, d / 2 + 12, STONE, "SmoothPlastic")
	r:block(-w / 2 - 10, 1.2, d / 2 + 11, w / 2 + 10, 1.3, d / 2 + 12, rgb(255, 214, 90), "SmoothPlastic")
	for _, z in { d / 2 + 15.5, d / 2 + 20.5 } do
		r:block(-w / 2 - 30, 0.1, z - 0.3, w / 2 + 30, 0.6, z + 0.3, METAL, "Metal")
	end
	local carriage = rgb(64, 160, 236)
	for k = 0, 2 do
		local x = -40 + k * 30
		r:block(x - 13, 1, d / 2 + 13.5, x + 13, 8, d / 2 + 22.5, carriage, "SmoothPlastic")
		r:block(x - 12, 4.4, d / 2 + 13.38, x + 12, 6.6, d / 2 + 13.5, GLASS, "Glass")
		r:block(x - 13.1, 7.6, d / 2 + 13.4, x + 13.1, 8.4, d / 2 + 22.6, WHITE, "SmoothPlastic")
	end
	r:wedge(CFrame.new(51.5, 4.5, d / 2 + 18) * CFrame.Angles(0, math.rad(-90), 0), 9, 7, 5, carriage, "SmoothPlastic")
	-- benches on the platform
	for _, x in { -20, 0, 20 } do
		bench(r, x, d / 2 + 5, 180)
	end
end

-- A small paved park with trees, a fountain and benches (a downtown block).
M.cityPark = function(r: R)
	r:block(-110, 0, -40, 110, 0.3, 40, rgb(140, 210, 96), "SmoothPlastic")
	r:block(-110, 0.3, -4, 110, 0.34, 4, rgb(236, 236, 232), "SmoothPlastic")
	r:block(-4, 0.3, -40, 4, 0.34, 40, rgb(236, 236, 232), "SmoothPlastic")
	r:cyl(0, 0.9, 0, 1.2, 18, "y", STONE, "SmoothPlastic")
	r:cyl(0, 1.2, 0, 0.4, 15, "y", WATER, "SmoothPlastic")
	r:cyl(0, 2.6, 0, 3, 2.4, "y", STONE, "SmoothPlastic")
	for _, p in
		{ { -60, -20 }, { -80, 18 }, { -30, 20 }, { 40, -20 }, { 70, 18 }, { 86, -16 }, { -88, -20 }, { 25, 20 } }
	do
		lowTree(r, p[1], 0.3, p[2], 1.2)
	end
	for _, p in { { -14, -8, 0 }, { 14, 8, 180 }, { -40, 8, 180 }, { 40, -8, 0 } } do
		bench(r, p[1], p[2], p[3])
	end
end

-- A car park: grey tarmac and white bay lines.
M.carPark = function(r: R)
	r:block(-50, 0, -30, 50, 0.22, 30, rgb(140, 146, 158), "SmoothPlastic")
	for x = -45, 45, 10 do
		for _, z in { -28, 10 } do
			r:block(x - 0.2, 0.22, z, x + 0.2, 0.25, z + 18, WHITE, "SmoothPlastic")
		end
	end
end

-- The civic quarter -------------------------------------------------------------------------------

M.school = function(r: R)
	local wall = rgb(255, 214, 150)
	CityModels.shop({
		w = 70,
		d = 24,
		floors = 2,
		wall = wall,
		awning = rgb(64, 160, 236),
		cols = 10,
		sign = rgb(64, 160, 236),
	})(r)
	-- a clock tower over the middle
	r:block(-6, 9, -10, 6, 20, 2, wall, "SmoothPlastic")
	r:wedge(CFrame.new(0, 22, -7), 13, 4, 6, rgb(255, 110, 100), "SmoothPlastic")
	r:wedge(CFrame.new(0, 22, -1) * CFrame.Angles(0, math.pi, 0), 13, 4, 6, rgb(255, 110, 100), "SmoothPlastic")
	r:cyl(0, 16, -10.2, 0.4, 6, "z", WHITE, "SmoothPlastic")
	r:cyl(0, 16, -10.45, 0.2, 4.4, "z", DARK, "SmoothPlastic")
end

-- A sports field: a pitch with lines and goals, a running track round it and seats along a side.
M.sportsField = function(r: R)
	r:block(-60, 0, -36, 60, 0.25, 36, rgb(232, 112, 92), "SmoothPlastic")
	r:block(-50, 0.25, -28, 50, 0.3, 28, rgb(110, 200, 90), "SmoothPlastic")
	for _, line in
		{
			{ -48, -26.4, 48, -26 },
			{ -48, 26, 48, 26.4 },
			{ -48.4, -26, -48, 26 },
			{ 48, -26, 48.4, 26 },
			{ -0.2, -26, 0.2, 26 },
		}
	do
		r:block(line[1], 0.3, line[2], line[3], 0.34, line[4], WHITE, "SmoothPlastic")
	end
	for _, sx in { -1, 1 } do
		local x = sx * 47
		r:block(x - 0.3, 0.3, -5, x + 0.3, 4.5, -4.4, WHITE, "SmoothPlastic")
		r:block(x - 0.3, 0.3, 4.4, x + 0.3, 4.5, 5, WHITE, "SmoothPlastic")
		r:block(x - 0.3, 4.5, -5, x + 0.3, 5.1, 5, WHITE, "SmoothPlastic")
	end
	for k = 0, 2 do
		r:block(
			-36,
			0,
			38 + k * 2,
			36,
			1 + k * 1.2,
			40 + k * 2,
			if k % 2 == 0 then rgb(64, 160, 236) else WHITE,
			"SmoothPlastic"
		)
	end
end

M.clinic = function(r: R)
	CityModels.shop({ w = 46, d = 28, floors = 3, wall = WHITE, awning = rgb(70, 196, 170), cols = 7 })(r)
	-- the cross on the front
	r:block(-1.6, 9, -14.6, 1.6, 15, -14.2, rgb(255, 96, 96), "SmoothPlastic")
	r:block(-4.6, 10.4, -14.6, 4.6, 13.6, -14.2, rgb(255, 96, 96), "SmoothPlastic")
	-- a canopy over the ambulance bay on the side
	r:block(23, 4.4, -12, 33, 5, 4, rgb(70, 196, 170), "SmoothPlastic")
	for _, z in { -11, 3 } do
		r:block(32.4, 0, z - 0.3, 33, 4.4, z + 0.3, WHITE, "SmoothPlastic")
	end
end

M.library = function(r: R)
	local wall = rgb(214, 128, 100)
	r:block(-28, 0, -14, 28, 12, 14, wall, "Brick")
	for x = -22, 22, 8.8 do
		r:block(x - 1.6, 2, -14.15, x + 1.6, 10, -14, GLASS, "Glass")
	end
	r:block(-29, 12, -15, 29, 13.2, 15, WHITE, "SmoothPlastic")
	for k = 0, 2 do
		r:block(-8 - k, 0, -15 - k * 1.4, 8 + k, 0.6 * (3 - k), -14 - k * 1.4, STONE, "SmoothPlastic")
	end
	r:block(-2, 0.2, -14.3, 2, 5, -14.1, DOOR, "SmoothPlastic")
end

M.museum = function(r: R)
	local stone = rgb(244, 240, 230)
	r:block(-30, 0, -14, 30, 13, 16, stone, "Marble")
	-- steps, columns and a pediment over them
	for k = 0, 2 do
		r:block(-24, k * 0.7, -24 + k * 1.6, 24, (k + 1) * 0.7, -14, shade(stone, 0.95), "SmoothPlastic")
	end
	for x = -20, 20, 8 do
		r:cyl(x, 8, -20, 11.8, 2.2, "y", WHITE, "SmoothPlastic")
	end
	r:block(-24, 13.9, -22, 24, 15, -14, stone, "SmoothPlastic")
	r:wedge(CFrame.new(-12, 17.5, -18) * CFrame.Angles(0, math.rad(90), 0), 8, 5, 24, stone, "SmoothPlastic")
	r:wedge(CFrame.new(12, 17.5, -18) * CFrame.Angles(0, math.rad(-90), 0), 8, 5, 24, stone, "SmoothPlastic")
	r:block(-3, 2, -14.2, 3, 9, -14, DOOR, "SmoothPlastic")
	-- banners
	for _, x in { -25, 25 } do
		r:block(x - 1.4, 4, -14.3, x + 1.4, 11, -14.1, rgb(255, 110, 100), "Fabric")
	end
end

M.fireStation = function(r: R)
	local red = rgb(236, 82, 72)
	r:block(-26, 0, -14, 26, 11, 14, red, "Brick")
	for k = -1, 1 do
		local x = k * 15
		r:block(x - 5.5, 0.2, -14.2, x + 5.5, 8, -14, rgb(236, 236, 240), "SmoothPlastic")
		for y = 2, 7, 1.6 do
			r:block(x - 5.5, y, -14.3, x + 5.5, y + 0.15, -14.2, rgb(196, 200, 210), "SmoothPlastic")
		end
	end
	r:block(-27, 11, -15, 27, 12, 15, WHITE, "SmoothPlastic")
	-- the hose tower
	r:block(20, 11, 4, 28, 26, 12, red, "SmoothPlastic")
	r:block(19.5, 26, 3.5, 28.5, 27, 12.5, WHITE, "SmoothPlastic")
	-- a fire engine out front
	local fx, fz = -15, -22
	r:block(fx - 4, 1.2, fz - 7, fx + 4, 5.4, fz + 5, red, "SmoothPlastic")
	r:block(fx - 4, 1.2, fz - 10, fx + 4, 6, fz - 7, red, "SmoothPlastic")
	r:block(fx - 3.6, 3.6, fz - 10.1, fx + 3.6, 5.4, fz - 10, GLASS, "Glass")
	r:block(fx - 3, 5.4, fz - 5, fx + 3, 5.9, fz + 4, METAL, "Metal")
	for _, wx in { -4.2, 4.2 } do
		for _, wz in { -8, 3 } do
			r:cyl(fx + wx, 1.2, fz + wz, 0.8, 2.4, "x", DARK, "SmoothPlastic")
		end
	end
end

-- A row of four little houses, each with a garden hedge and a shrub.
M.houseRow = function(r: R)
	local walls = { rgb(255, 214, 186), rgb(186, 226, 250), rgb(255, 236, 170), rgb(206, 238, 196) }
	local roofs = { rgb(236, 110, 90), rgb(86, 150, 220), rgb(236, 150, 70), rgb(100, 180, 120) }
	for k = 0, 3 do
		local x = -27 + k * 18
		house(r, x, 0, 11, 9, walls[k + 1], roofs[k + 1], 0)
		r:block(x - 8, 0, -9, x + 8, 1.2, -8.2, LEAF_DARK, "SmoothPlastic")
		-- a shrub in each back garden (no trees this close to the road)
		r:ball(x + 6, 1.3, 6, 3, LEAF, "SmoothPlastic")
		r:ball(x + 4.4, 0.9, 6.6, 2, shade(LEAF, 1.15), "SmoothPlastic")
	end
end

M.postOffice = CityModels.shop({
	w = 34,
	d = 24,
	floors = 2,
	wall = rgb(120, 180, 250),
	awning = rgb(255, 214, 90),
	sign = rgb(255, 214, 90),
})

-- A park with a pond, a little bridge, trees and benches.
M.pondPark = function(r: R)
	r:block(-110, 0, -42, 110, 0.3, 42, rgb(132, 206, 90), "SmoothPlastic")
	r:cyl(-10, 0.32, 0, 0.1, 64, "y", rgb(214, 210, 196), "SmoothPlastic")
	r:cyl(-10, 0.36, 0, 0.12, 58, "y", WATER, "SmoothPlastic")
	-- the bridge across
	r:block(-14, 0.4, -32, -6, 1.6, 32, WOOD, "WoodPlanks")
	for _, x in { -14, -6 } do
		r:block(x - 0.3, 1.6, -30, x + 0.3, 3, 30, WOOD_DARK, "Wood")
	end
	-- ducks
	for _, p in { { -30, -8 }, { -26, -12 }, { 10, 10 } } do
		r:ball(p[1], 0.9, p[2], 1.2, WHITE, "SmoothPlastic")
		r:ball(p[1] - 0.7, 1.5, p[2], 0.7, WHITE, "SmoothPlastic")
	end
	for _, p in
		{ { 50, -20 }, { 70, 18 }, { 86, -10 }, { -70, 20 }, { -86, -18 }, { 40, 20 }, { -60, -20 }, { 88, 20 } }
	do
		lowTree(r, p[1], 0.3, p[2], 1.3)
	end
	for _, p in { { 30, -6, 90 }, { 30, 6, 90 }, { -60, 0, -90 } } do
		bench(r, p[1], p[2], p[3])
	end
end

-- A playground: a slide, swings, a roundabout and a sandpit.
M.playground = function(r: R)
	r:block(-40, 0, -30, 40, 0.25, 30, rgb(255, 214, 160), "SmoothPlastic")
	-- the slide: a ladder tower and a chute down
	r:block(-24, 0, -6, -18, 6, 0, rgb(64, 160, 236), "SmoothPlastic")
	r:ramp(-24, 0.25, 0, -18, 6, 14, false, rgb(255, 196, 60), "SmoothPlastic")
	-- swings
	for _, x in { 4, 16 } do
		r:beam(Vector3.new(x - 6, 0, -14), Vector3.new(x - 6, 8, -10), 0.5, 0.5, rgb(255, 110, 100), "SmoothPlastic")
		r:beam(Vector3.new(x + 6, 0, -14), Vector3.new(x + 6, 8, -10), 0.5, 0.5, rgb(255, 110, 100), "SmoothPlastic")
	end
	r:block(-2, 7.8, -10.3, 22, 8.4, -9.7, rgb(255, 110, 100), "SmoothPlastic")
	for _, x in { 1, 7, 13, 19 } do
		r:block(x - 0.9, 2, -10.6, x + 0.9, 2.3, -9.4, DARK, "SmoothPlastic")
	end
	-- the roundabout
	r:cyl(18, 0.7, 14, 0.8, 9, "y", rgb(110, 200, 90), "SmoothPlastic")
	r:cyl(18, 1.9, 14, 2, 1, "y", METAL, "Metal")
	-- a sandpit
	r:block(-32, 0.25, 12, -16, 0.5, 26, rgb(255, 232, 170), "Sand")
end

M.basketCourt = function(r: R)
	r:block(-30, 0, -18, 30, 0.25, 18, rgb(255, 150, 90), "SmoothPlastic")
	r:block(-28, 0.25, -16, 28, 0.28, -15.6, WHITE, "SmoothPlastic")
	r:block(-28, 0.25, 15.6, 28, 0.28, 16, WHITE, "SmoothPlastic")
	r:block(-0.2, 0.25, -16, 0.2, 0.28, 16, WHITE, "SmoothPlastic")
	for _, sx in { -1, 1 } do
		local x = sx * 27
		r:cyl(x + sx * 1.5, 4.5, 0, 9, 0.6, "y", DARK, "Metal")
		r:block(x - 0.2, 8, -3, x + 0.2, 11, 3, WHITE, "SmoothPlastic")
		r:cyl(x - sx * 1.4, 8.6, 0, 0.2, 2.2, "y", rgb(255, 110, 70), "Metal")
	end
end

-- The hills ---------------------------------------------------------------------------------------

M.barn = function(r: R)
	local red = rgb(222, 76, 66)
	r:block(-14, 0, -10, 14, 10, 10, red, "SmoothPlastic")
	r:wedge(CFrame.new(0, 13, -5.25), 30, 6, 10.5, WHITE, "SmoothPlastic")
	r:wedge(CFrame.new(0, 13, 5.25) * CFrame.Angles(0, math.pi, 0), 30, 6, 10.5, WHITE, "SmoothPlastic")
	r:block(-5, 0.2, -10.2, 5, 8, -10, rgb(250, 246, 236), "SmoothPlastic")
	r:beam(Vector3.new(-4.6, 0.6, -10.3), Vector3.new(4.6, 7.6, -10.3), 0.6, 0.15, red, "SmoothPlastic")
	r:beam(Vector3.new(4.6, 0.6, -10.3), Vector3.new(-4.6, 7.6, -10.3), 0.6, 0.15, red, "SmoothPlastic")
	-- the silo beside it
	r:cyl(20, 9, 0, 18, 9, "y", rgb(214, 220, 228), "SmoothPlastic")
	r:ball(20, 18, 0, 9, rgb(120, 170, 230), "SmoothPlastic")
end

-- A windmill: a white tower, a cap and four sails that turn.
M.windmill = function(r: R)
	r:cyl(0, 5, 0, 10, 9, "y", WHITE, "SmoothPlastic")
	r:cyl(0, 12.5, 0, 5, 7, "y", WHITE, "SmoothPlastic")
	r:block(-3.4, 15, -3.4, 3.4, 18, 3.4, rgb(222, 76, 66), "SmoothPlastic")
	r:block(-1.2, 0.2, -4.6, 1.2, 3.6, -4.3, DOOR, "SmoothPlastic")
	local hub = r:cyl(0, 16.5, -4.6, 1.6, 2, "z", WOOD_DARK, "Wood")
	hub.name = "Hub"
	for k = 0, 3 do
		local a = k * math.pi / 2 + math.pi / 4
		local tip = Vector3.new(math.cos(a) * 11, 16.5 + math.sin(a) * 11, -5.2)
		local arm = r:beam(Vector3.new(0, 16.5, -5.2), tip, 0.5, 0.5, WOOD_DARK, "Wood")
		if arm then
			arm.name = "Spin"
		end
		local mid = Vector3.new(math.cos(a) * 6.5, 16.5 + math.sin(a) * 6.5, -5.4)
		local sail = r:boxAt(CFrame.new(mid) * CFrame.Angles(0, 0, a), 8, 2.6, 0.2, rgb(255, 250, 240), "Fabric")
		sail.name = "Spin"
	end
end

-- A field of crop rows inside a low fence.
local function field(r: R, x: number, z: number, w: number, d: number, crop: Color3)
	r:block(x - w / 2, 0, z - d / 2, x + w / 2, 0.3, z + d / 2, rgb(170, 120, 80), "SmoothPlastic")
	local rows = math.floor(d / 5)
	for k = 0, rows - 1 do
		local rz = z - d / 2 + (k + 0.5) * d / rows
		r:block(x - w / 2 + 1, 0.3, rz - 1, x + w / 2 - 1, 1.2, rz + 1, crop, "SmoothPlastic")
	end
	for _, side in { { -1, 0 }, { 1, 0 }, { 0, -1 }, { 0, 1 } } do
		local horizontal = side[2] ~= 0
		local fx, fz = x + side[1] * (w / 2 + 1), z + side[2] * (d / 2 + 1)
		local len = if horizontal then w + 2 else d + 2
		r:box(fx, 1.6, fz, if horizontal then len else 0.3, 0.3, if horizontal then 0.3 else len, WOOD, "Wood")
	end
end

local function cow(r: R, x: number, z: number, yaw: number)
	local f = CFrame.new(x, 0, z) * CFrame.Angles(0, math.rad(yaw), 0)
	r:boxAt(f * CFrame.new(0, 2.4, 0), 2.2, 2, 4, WHITE, "SmoothPlastic")
	r:boxAt(f * CFrame.new(0.6, 2.9, 0.6), 1.2, 1, 1.6, DARK, "SmoothPlastic")
	r:boxAt(f * CFrame.new(0, 3.1, -2.6), 1.6, 1.6, 1.6, WHITE, "SmoothPlastic")
	r:boxAt(f * CFrame.new(0, 2.6, -3.5), 1.2, 0.8, 0.4, rgb(255, 180, 180), "SmoothPlastic")
	for _, lx in { -0.7, 0.7 } do
		for _, lz in { -1.4, 1.4 } do
			r:boxAt(f * CFrame.new(lx, 0.7, lz), 0.5, 1.4, 0.5, DARK, "SmoothPlastic")
		end
	end
end

-- The farm on its plateau (the barn and windmill are their own pieces): fields, hay and cows.
M.farmyard = function(r: R)
	field(r, -60, -40, 46, 34, rgb(255, 214, 80))
	field(r, -60, 10, 46, 34, rgb(110, 200, 90))
	field(r, 0, 50, 46, 30, rgb(255, 150, 70))
	for _, p in { { 30, -20 }, { 36, -14 }, { 26, -12 } } do
		r:cyl(p[1], 1.4, p[2], 3, 2.8, "x", rgb(240, 206, 110), "SmoothPlastic")
	end
	for _, p in { { 50, 20, 30 }, { 60, 30, 200 }, { 44, 36, 120 } } do
		cow(r, p[1], p[2], p[3])
	end
	-- a path of flat stones across the yard
	for k = 0, 8 do
		r:cyl(-20 + k * 7, 0.1, -60 + k * 6, 0.25, 3.4, "y", rgb(222, 214, 196), "SmoothPlastic")
	end
end

-- The lookout: a wooden platform up on posts, with two ramps up to it, a telescope and benches.
M.lookout = function(r: R)
	local deckY = 12
	r:block(-7, deckY - 0.6, -13, 7, deckY, 7, WOOD, "WoodPlanks")
	for _, p in { { -6.5, -12.5 }, { 6.5, -12.5 }, { -6.5, 6.5 }, { 6.5, 6.5 } } do
		r:block(p[1] - 0.6, 0, p[2] - 0.6, p[1] + 0.6, deckY, p[2] + 0.6, WOOD_DARK, "Wood")
	end
	-- railings round the deck (open where the top ramp lands)
	r:block(-7, deckY, 6.6, 7, deckY + 2.6, 7, WOOD_DARK, "Wood")
	r:block(-7, deckY, -13, -6.6, deckY + 2.6, 7, WOOD_DARK, "Wood")
	r:block(-7, deckY, -13, 7, deckY + 2.6, -12.6, WOOD_DARK, "Wood")
	r:block(6.6, deckY, -9, 7, deckY + 2.6, 7, WOOD_DARK, "Wood")
	-- up from the ground on the east side, a landing, and back up to the deck
	r:ramp(7, 0, -9, 11, deckY / 2, 9, true, WOOD, "WoodPlanks")
	r:block(7, deckY / 2 - 0.6, 9, 15, deckY / 2, 13, WOOD, "WoodPlanks")
	r:ramp(11, deckY / 2, -9, 15, deckY, 9, false, WOOD, "WoodPlanks")
	r:block(7, deckY - 0.6, -13, 15, deckY, -9, WOOD, "WoodPlanks")
	r:block(7, deckY / 2, 12.6, 15, deckY / 2 + 2.4, 13, WOOD_DARK, "Wood")
	-- a roof over half the deck
	r:wedge(CFrame.new(0, deckY + 7, -0.5), 16, 3, 7, rgb(222, 76, 66), "SmoothPlastic")
	r:wedge(CFrame.new(0, deckY + 7, 6.5) * CFrame.Angles(0, math.pi, 0), 16, 3, 7, rgb(222, 76, 66), "SmoothPlastic")
	for _, x in { -6.5, 6.5 } do
		r:block(x - 0.3, deckY, 6, x + 0.3, deckY + 5.5, 6.6, WOOD_DARK, "Wood")
	end
	-- the telescope, looking out over the town
	r:cyl(-3, deckY + 1.6, -10, 3.2, 0.4, "y", DARK, "Metal")
	r:boxAt(CFrame.new(-3, deckY + 3.4, -10.6) * CFrame.Angles(math.rad(-18), 0, 0), 0.9, 0.9, 3, METAL, "Metal")
	bench(r, 3, -4, 180)
end

M.observatory = function(r: R)
	r:cyl(0, 4, 0, 8, 18, "y", WHITE, "SmoothPlastic")
	r:ball(0, 8, 0, 17.4, rgb(236, 240, 246), "SmoothPlastic")
	r:boxAt(CFrame.new(0, 12, -6) * CFrame.Angles(math.rad(-38), 0, 0), 3, 9, 1, DARK, "SmoothPlastic")
	r:block(-1.6, 0.2, -9.1, 1.6, 4.6, -8.9, DOOR, "SmoothPlastic")
	for k = 0, 1 do
		r:block(-3 - k, 0, -10.4 - k * 1.2, 3 + k, 0.5 * (2 - k), -9 - k * 1.2, STONE, "SmoothPlastic")
	end
end

M.radioMast = function(r: R)
	r:block(-3, 0, -3, 3, 1, 3, STONE, "SmoothPlastic")
	r:cyl(0, 19, 0, 36, 1, "y", rgb(255, 110, 100), "Metal")
	r:cyl(0, 13, 0, 1, 3, "y", WHITE, "Metal")
	r:cyl(0, 25, 0, 1, 2.4, "y", WHITE, "Metal")
	r:glow(r:ball(0, 37.5, 0, 1.4, rgb(255, 80, 70), "Neon"), 0)
end

local function tent(r: R, x: number, z: number, yaw: number, col: Color3)
	local f = CFrame.new(x, 0, z) * CFrame.Angles(0, math.rad(yaw), 0)
	r:wedge(f * CFrame.new(0, 2, -1.75), 5, 4, 3.5, col, "Fabric")
	r:wedge(f * CFrame.new(0, 2, 1.75) * CFrame.Angles(0, math.pi, 0), 5, 4, 3.5, shade(col, 0.88), "Fabric")
end

-- The campsite in the pines: tents round a fire, a log cabin and a picnic table.
M.camp = function(r: R)
	tent(r, -12, -6, 20, rgb(255, 150, 70))
	tent(r, 6, -14, -30, rgb(64, 160, 236))
	tent(r, 14, 4, 80, rgb(110, 200, 90))
	-- the campfire
	for k = 0, 3 do
		local a = k * math.pi / 2 + 0.4
		r:boxAt(CFrame.new(0, 0.5, 0) * CFrame.Angles(0, a, math.rad(15)), 3, 0.6, 0.6, WOOD_DARK, "Wood")
	end
	r:fire(r:glow(r:ball(0, 1, 0, 1.2, rgb(255, 150, 60), "Neon"), 14, 1.4, rgb(255, 170, 90)))
	for k = 0, 4 do
		local a = k / 5 * math.pi * 2
		r:cyl(math.cos(a) * 6, 0.6, math.sin(a) * 6, 1.2, 1.4, "y", ROCK, "SmoothPlastic")
	end
	house(r, -22, 20, 14, 10, rgb(170, 116, 74), rgb(110, 76, 52), 160)
	-- a picnic table
	r:block(16, 2.4, 18, 22, 2.8, 22, WOOD, "Wood")
	for _, z in { 17, 23 } do
		r:block(16, 1.4, z - 0.5, 22, 1.7, z + 0.5, WOOD, "Wood")
	end
end

-- The waterfront ----------------------------------------------------------------------------------

-- A ferris wheel: two legs either side of the hub, a rim of beams, spokes and cabins.
M.ferrisWheel = function(r: R)
	local R0 = 16
	local hy = R0 + 4
	local col = rgb(255, 110, 100)
	for _, sz in { -2.2, 2.2 } do
		r:beam(Vector3.new(-9, 0, sz), Vector3.new(0, hy, sz), 1, 1, WHITE, "Metal")
		r:beam(Vector3.new(9, 0, sz), Vector3.new(0, hy, sz), 1, 1, WHITE, "Metal")
	end
	local hub = r:cyl(0, hy, 0, 5.4, 2.4, "z", METAL, "Metal")
	hub.name = "Hub"
	local n = 16
	for k = 0, n - 1 do
		local a1, a2 = k / n * math.pi * 2, (k + 1) / n * math.pi * 2
		local p1 = Vector3.new(math.cos(a1) * R0, hy + math.sin(a1) * R0, 0)
		local p2 = Vector3.new(math.cos(a2) * R0, hy + math.sin(a2) * R0, 0)
		local rim = r:beam(p1, p2, 0.8, 1.2, if k % 2 == 0 then col else rgb(255, 214, 90), "SmoothPlastic")
		if rim then
			rim.name = "Spin"
		end
		if k % 2 == 0 then
			local spoke = r:beam(Vector3.new(0, hy, 0), p1, 0.4, 0.4, WHITE, "Metal")
			if spoke then
				spoke.name = "Spin"
			end
			local cabinCol = ({ rgb(64, 160, 236), rgb(110, 200, 90), rgb(255, 196, 60), rgb(200, 130, 240) })[(k / 2) % 4 + 1]
			local c = r:box(p1.X, p1.Y - 2.2, 0, 3, 2.6, 2.6, cabinCol, "SmoothPlastic")
			c.name = "Cabin"
			local roof = r:box(p1.X, p1.Y - 0.7, 0, 3.4, 0.5, 3, WHITE, "SmoothPlastic")
			roof.name = "Cabin"
		end
	end
	r:block(-11, 0, -4, 11, 0.6, 4, STONE, "SmoothPlastic")
end

-- A carousel: a round deck, a striped canopy and horses on poles that go round.
M.carousel = function(r: R)
	r:cyl(0, 0.5, 0, 1, 20, "y", rgb(255, 214, 90), "SmoothPlastic")
	local hub = r:cyl(0, 4, 0, 8, 1.6, "y", rgb(255, 110, 100), "Metal")
	hub.name = "Hub"
	r:cyl(0, 8.4, 0, 0.8, 22, "y", rgb(255, 110, 100), "SmoothPlastic")
	r:cyl(0, 9.2, 0, 0.8, 14, "y", WHITE, "SmoothPlastic")
	r:cyl(0, 10, 0, 0.8, 7, "y", rgb(255, 110, 100), "SmoothPlastic")
	local horses = { WHITE, rgb(255, 196, 220), rgb(200, 230, 255), rgb(255, 236, 170), rgb(220, 250, 220), WHITE }
	for k = 0, 5 do
		local a = k / 6 * math.pi * 2
		local x, z = math.cos(a) * 7, math.sin(a) * 7
		local pole = r:cyl(x, 4.6, z, 7.6, 0.3, "y", rgb(255, 214, 90), "Metal")
		pole.name = "Spin"
		local body = r:boxAt(CFrame.new(x, 3, z) * CFrame.Angles(0, -a, 0), 1, 1.4, 3, horses[k + 1], "SmoothPlastic")
		body.name = "Spin"
		local head = r:boxAt(
			CFrame.new(x, 4, z) * CFrame.Angles(0, -a, 0) * CFrame.new(0, 0, -1.6),
			0.9,
			1.4,
			1,
			horses[k + 1],
			"SmoothPlastic"
		)
		head.name = "Spin"
	end
end

-- A food stall with a striped awning.
M.stall = function(r: R)
	r:block(-4, 0, -2.5, 4, 3, 2.5, WHITE, "SmoothPlastic")
	r:block(-4.2, 3, -2.7, 4.2, 3.2, 2.7, rgb(255, 196, 90), "SmoothPlastic")
	for k = 0, 3 do
		local x = -4 + k * 2
		r:boxAt(
			CFrame.new(x + 1, 5, -3.3) * CFrame.Angles(math.rad(25), 0, 0),
			2,
			0.2,
			3,
			if k % 2 == 0 then rgb(255, 110, 100) else WHITE,
			"Fabric"
		)
	end
	for _, x in { -3.8, 3.8 } do
		r:block(x - 0.2, 3.2, -2.6, x + 0.2, 6, -2.2, WHITE, "SmoothPlastic")
	end
end

-- The fairground pier: a wide deck out over the water on posts, with railings.
M.fairPier = function(r: R)
	r:block(-8, -0.1, -40, 8, 0.4, 2, WOOD, "WoodPlanks")
	r:block(-60, -0.1, -130, 60, 0.4, -40, WOOD, "WoodPlanks")
	for _, x in { -60, 60 } do
		r:block(x - 0.3, 0.4, -130, x + 0.3, 3, -40, WHITE, "SmoothPlastic")
	end
	r:block(-60, 0.4, -130.3, 60, 3, -129.7, WHITE, "SmoothPlastic")
	for x = -50, 50, 25 do
		for _, z in { -50, -90, -125 } do
			r:cyl(x, -3, z, 6, 1.2, "y", WOOD_DARK, "Wood")
		end
	end
	for _, z in { -10, -30 } do
		r:cyl(-6, -3, z, 6, 1, "y", WOOD_DARK, "Wood")
		r:cyl(6, -3, z, 6, 1, "y", WOOD_DARK, "Wood")
	end
end

M.lighthouse = function(r: R)
	-- rocks round the foot
	for _, p in { { -8, -4, 9 }, { 6, -7, 8 }, { 8, 6, 10 }, { -6, 8, 8 }, { 0, 0, 13 } } do
		r:ball(p[1], -1, p[2], p[3], ROCK, "SmoothPlastic")
	end
	local y = 4
	local diam = 11
	for k = 0, 5 do
		local col = if k % 2 == 0 then WHITE else rgb(236, 82, 72)
		r:cyl(0, y + 2.5, 0, 5, diam, "y", col, "SmoothPlastic")
		y += 5
		diam -= 0.7
	end
	r:cyl(0, y + 0.3, 0, 0.6, diam + 4, "y", DARK, "SmoothPlastic")
	r:cyl(0, y + 1.8, 0, 2.4, diam + 3.6, "y", WHITE, "SmoothPlastic")
	r:cyl(0, y + 4, 0, 4.4, diam - 1.6, "y", GLASS, "Glass")
	r:glow(r:ball(0, y + 4, 0, 3, rgb(255, 240, 180), "Neon"), 40, 2, rgb(255, 236, 190))
	r:ball(0, y + 7, 0, diam - 1, rgb(236, 82, 72), "SmoothPlastic")
	r:block(-1.4, 4, -5.6, 1.4, 8, -5.3, DOOR, "SmoothPlastic")
	-- a little jetty to the beach
	r:block(-2, 0.1, -60, 2, 0.6, -6, WOOD, "WoodPlanks")
end

M.beachHuts = function(r: R)
	local cols = { rgb(255, 120, 120), rgb(110, 196, 250), rgb(255, 214, 90), rgb(130, 220, 170), rgb(206, 170, 250) }
	for k = 0, 4 do
		house(r, -24 + k * 12, 0, 8, 7, cols[k + 1], WHITE, 0)
	end
end

M.lifeguard = function(r: R)
	for _, p in { { -2, -2 }, { 2, -2 }, { -2, 2 }, { 2, 2 } } do
		r:block(p[1] - 0.3, 0, p[2] - 0.3, p[1] + 0.3, 7, p[2] + 0.3, WHITE, "SmoothPlastic")
	end
	r:block(-2.6, 7, -2.6, 2.6, 11, 2.6, rgb(255, 110, 100), "SmoothPlastic")
	r:block(-2.2, 8.8, -2.65, 2.2, 10.4, -2.6, GLASS, "Glass")
	r:block(-3, 11, -3, 3, 11.6, 3, WHITE, "SmoothPlastic")
	r:ramp(-1.2, 0, 3, 1.2, 7, 12, false, WOOD, "WoodPlanks")
end

function CityModels.prims(name: string): { any }?
	local build = M[name]
	if not build then
		-- "lot:<w>x<d>:<kind>:<margin>"
		local w, d, kind, margin = name:match("^lot:(%d+)x(%d+):(%a+):(%d+)$")
		if w then
			build =
				CityModels.lot(tonumber(w) :: number, tonumber(d) :: number, kind :: string, tonumber(margin) :: number)
		end
	end
	if not build then
		return nil
	end
	local r = Recipe.new(WHITE, WHITE)
	build(r)
	return r.prims
end

return CityModels
