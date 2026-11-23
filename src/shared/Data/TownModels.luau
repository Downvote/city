--!strict
-- The town's own small things, drawn with the same Recipe API as the furniture: the news board and
-- the welcome sign in the middle of town, and the sign in front of every plot. (The rest of the
-- town is the user's city pack: Data/CityMap.) Each model is built at the origin facing +Z,
-- standing on y = 0; the World service places them. A part named "SignBoard" gets text.

local Recipe = require(script.Parent.Parent.Build.Recipe)
local Geometry = require(script.Parent.Parent.Build.Geometry)
local Colors = require(script.Parent.Parent.Util.Colors)

type R = Recipe.Recipe
local C = Recipe.Colors

local TownModels = {}

local DARK_STONE = Color3.fromRGB(196, 204, 214)
local WOOD = Color3.fromRGB(156, 106, 64)
local DARK_WOOD = Color3.fromRGB(102, 68, 42)

local function shade(c: Color3, k: number): Color3
	return Colors.shade(c, k)
end

TownModels.Models = {}

TownModels.Models.board = function(r: R)
	local cork = Color3.fromRGB(196, 150, 100)
	local roof = Color3.fromRGB(246, 104, 92)
	-- two posts with caps, holding a framed cork board under a little gabled roof
	for _, x in { -4.45, 4.45 } do
		r:box(x, 4.05, 0, 0.6, 8.1, 0.6, DARK_WOOD, "Wood")
		r:block(x - 0.4, 0, -0.4, x + 0.4, 0.3, 0.4, DARK_STONE, "Concrete")
	end
	r:block(-4.3, 2.3, -0.2, 4.3, 7.2, 0.15, cork, "WoodPlanks")
	r:block(-4.15, 7.2, -0.3, 4.15, 7.45, 0.3, WOOD, "Wood")
	r:block(-4.15, 2.05, -0.3, 4.15, 2.3, 0.3, WOOD, "Wood")
	r:block(-4.15, 2.05, 0.3, 4.15, 2.15, 0.7, WOOD, "Wood")
	r:quad(
		Vector3.new(-4.8, 8.1, 1.05),
		Vector3.new(4.8, 8.1, 1.05),
		Vector3.new(4.8, 8.95, 0),
		Vector3.new(-4.8, 8.95, 0),
		0.18,
		roof,
		"Slate"
	)
	r:quad(
		Vector3.new(-4.8, 8.1, -1.05),
		Vector3.new(4.8, 8.1, -1.05),
		Vector3.new(4.8, 8.95, 0),
		Vector3.new(-4.8, 8.95, 0),
		0.18,
		roof,
		"Slate"
	)
	r:block(-4.85, 8.85, -0.15, 4.85, 9.1, 0.15, shade(roof, 0.8), "Slate")
	r:block(-4.75, 7.45, -0.35, 4.75, 8.15, 0.35, WOOD, "WoodPlanks")
	-- notes pinned on it, and a poster with a little map
	local notes: { { x: number, y: number, w: number, h: number, c: Color3 } } = {
		{ x = -3.1, y = 5.7, w = 1.4, h = 1.6, c = C.Paper },
		{ x = -1.3, y = 6.1, w = 1.2, h = 1.2, c = C.Yellow },
		{ x = 2.9, y = 5.9, w = 1.3, h = 1.5, c = C.Pink },
		{ x = -2.5, y = 3.6, w = 1.5, h = 1.3, c = Color3.fromRGB(190, 222, 240) },
		{ x = -0.6, y = 3.9, w = 1.2, h = 1.5, c = C.Paper },
		{ x = 2.5, y = 3.6, w = 1.6, h = 1.2, c = C.Paper },
	}
	for i, n in notes do
		r:boxAt(
			CFrame.new(n.x, n.y, 0.18) * CFrame.Angles(0, 0, (i % 3 - 1) * 0.06),
			n.w,
			n.h,
			0.04,
			n.c,
			"SmoothPlastic"
		)
		r:ball(n.x, n.y + n.h / 2 - 0.15, 0.24, 0.16, if i % 2 == 0 then C.Red else C.Blue, "SmoothPlastic")
	end
	r:block(0.15, 4.6, 0.15, 1.75, 6.6, 0.2, C.Paper, "SmoothPlastic")
	r:block(0.3, 4.8, 0.2, 1.6, 6.0, 0.22, Color3.fromRGB(150, 196, 120), "SmoothPlastic")
	r:block(0.3, 5.3, 0.22, 1.6, 5.4, 0.23, Color3.fromRGB(90, 150, 210), "SmoothPlastic")
	r:block(0.3, 6.15, 0.2, 1.6, 6.45, 0.22, C.Red, "SmoothPlastic")
end

TownModels.Models.sign = function(r: R)
	-- two capped posts, a framed board under a little roof, and a flower box at the foot
	for _, x in { -4.0, 4.0 } do
		r:box(x, 3.6, 0, 0.6, 7.2, 0.6, DARK_WOOD, "Wood")
		r:block(x - 0.4, 0, -0.4, x + 0.4, 0.3, 0.4, DARK_STONE, "Concrete")
	end
	local board = r:block(-3.6, 3.4, -0.25, 3.6, 6, 0.25, WOOD, "WoodPlanks")
	board.name = "SignBoard"
	r:block(-3.75, 6.0, -0.32, 3.75, 6.25, 0.32, DARK_WOOD, "Wood")
	r:block(-3.75, 3.15, -0.32, 3.75, 3.4, 0.32, DARK_WOOD, "Wood")
	for _, sx in { -1, 1 } do
		r:block(
			math.min(sx * 3.6, sx * 3.75),
			3.15,
			-0.32,
			math.max(sx * 3.6, sx * 3.75),
			6.25,
			0.32,
			DARK_WOOD,
			"Wood"
		)
	end
	local roof = Color3.fromRGB(156, 42, 46)
	for _, sz in { -1, 1 } do
		r:quad(
			Vector3.new(-4.7, 7.0, sz * 0.9),
			Vector3.new(4.7, 7.0, sz * 0.9),
			Vector3.new(4.7, 7.7, 0),
			Vector3.new(-4.7, 7.7, 0),
			0.16,
			roof,
			"Slate"
		)
	end
	r:block(-4.75, 7.6, -0.14, 4.75, 7.85, 0.14, shade(roof, 0.8), "Slate")
	r:block(-3.7, 6.25, -0.3, 3.7, 7.05, 0.3, WOOD, "WoodPlanks")
	r:block(-3.4, 0, -0.55, 3.4, 0.9, 0.55, WOOD, "WoodPlanks")
	r:block(-3.3, 0.9, -0.45, 3.3, 0.94, 0.45, C.Soil, "Sand")
	for i, col in { C.Pink, C.Yellow, C.White, C.Red, C.Pink, C.Yellow } do
		local x = -2.7 + (i - 1) * 1.08
		r:ball(x, 1.15, 0, 0.6, if i % 2 == 0 then C.Leaf else C.DarkLeaf, "Grass")
		r:ball(x + 0.15, 1.5, (i % 2 - 0.5) * 0.3, 0.3, col, "SmoothPlastic")
	end
end

TownModels.Models.plotSign = function(r: R)
	for _, x in { -2.85, 2.85 } do
		r:block(x - 0.2, 0, -0.2, x + 0.2, 5.3, 0.2, DARK_WOOD, "Wood")
		r:block(x - 0.26, 5.3, -0.26, x + 0.26, 5.45, 0.26, WOOD, "Wood")
	end
	local board = r:block(-2.6, 3, -0.2, 2.6, 5, 0.2, C.Cream, "Wood")
	board.name = "SignBoard"
	r:block(-2.7, 5.0, -0.26, 2.7, 5.15, 0.26, WOOD, "Wood")
	r:block(-2.7, 2.85, -0.26, 2.7, 3.0, 0.26, WOOD, "Wood")
	r:block(-2.65, 1.2, -0.08, 2.65, 1.4, 0.08, DARK_WOOD, "Wood")
end

function TownModels.prims(name: string): { Geometry.Prim }
	local build = TownModels.Models[name]
	assert(build, "no town model " .. name)
	local r = Recipe.new(C.White, C.White)
	build(r)
	return r.prims
end

-- Every model side by side, for the preview tool.
function TownModels.preview(): { Geometry.Prim }
	local out = {}
	local x = 0
	for _, name in
		{
			"board",
			"sign",
			"plotSign",
		}
	do
		local prims = TownModels.prims(name)
		local lo, hi = Geometry.bounds(prims)
		x -= lo.X
		for _, p in prims do
			p.cf = CFrame.new(x, 0, 0) * p.cf
			table.insert(out, p)
		end
		x += hi.X + 4
	end
	return out
end

return TownModels
