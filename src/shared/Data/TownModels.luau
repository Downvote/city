--!strict
-- The plaza's own buildings, drawn with the same Recipe API as the furniture.
-- Each model is built at the origin facing +Z; the World service places them.

local Recipe = require(script.Parent.Parent.Build.Recipe)
local Geometry = require(script.Parent.Parent.Build.Geometry)

type R = Recipe.Recipe
local C = Recipe.Colors

local TownModels = {}

local STONE = Color3.fromRGB(196, 190, 178)
local DARK_STONE = Color3.fromRGB(150, 145, 136)
local WOOD = Color3.fromRGB(150, 100, 60)
local DARK_WOOD = Color3.fromRGB(105, 70, 42)

local function ring(
	r: R,
	cx: number,
	cy: number,
	cz: number,
	radius: number,
	thick: number,
	height: number,
	color: Color3,
	mat: string,
	n: number?
)
	local count = n or 16
	for i = 0, count - 1 do
		local a1 = i / count * math.pi * 2
		local a2 = (i + 1) / count * math.pi * 2
		r:beam(
			Vector3.new(cx + math.cos(a1) * radius, cy, cz + math.sin(a1) * radius),
			Vector3.new(cx + math.cos(a2) * radius, cy, cz + math.sin(a2) * radius),
			thick,
			height,
			color,
			mat
		)
	end
end

local function awning(r: R, w: number, d: number, y: number, c1: Color3, c2: Color3)
	local stripes = math.max(2, math.floor(w / 1.5))
	for i = 0, stripes - 1 do
		local x1 = -w / 2 + i * w / stripes
		local x2 = x1 + w / stripes
		local col = if i % 2 == 0 then c1 else c2
		r:tri(
			Vector3.new((x1 + x2) / 2, y, -d / 2),
			Vector3.new((x1 + x2) / 2, y, d / 2),
			Vector3.new((x1 + x2) / 2, y + 1.6, -d / 2),
			x2 - x1,
			col,
			"Fabric"
		)
		-- scalloped front edge
		r:block(x1, y - 0.6, d / 2 - 0.1, x2, y, d / 2 + 0.05, col, "Fabric")
	end
end

TownModels.Models = {}

TownModels.Models.fountain = function(r: R)
	-- basin
	ring(r, 0, 1, 0, 8, 1.2, 2, STONE, "Cobblestone", 24)
	r:cyl(0, 0.2, 0, 0.4, 16.5, "y", DARK_STONE, "Cobblestone")
	local water = r:cyl(0, 1.2, 0, 0.3, 15.2, "y", C.Water, "Glass")
	water.transp = 0.25
	water.collide = false
	-- middle column and two bowls
	r:cyl(0, 3, 0, 6, 1.6, "y", STONE, "Marble")
	r:cyl(0, 4.2, 0, 0.6, 7, "y", STONE, "Marble")
	local w2 = r:cyl(0, 4.55, 0, 0.2, 6.2, "y", C.Water, "Glass")
	w2.transp = 0.25
	r:cyl(0, 7, 0, 3, 1.1, "y", STONE, "Marble")
	r:cyl(0, 8.4, 0, 0.5, 3.6, "y", STONE, "Marble")
	local top = r:ball(0, 9.2, 0, 1.4, C.Water, "Glass")
	top.transp = 0.2
	top.effect = "sparkles"
	-- spouts of water falling into the basin
	for i = 0, 5 do
		local a = i / 6 * math.pi * 2
		local p = r:beam(
			Vector3.new(math.cos(a) * 3.2, 4.4, math.sin(a) * 3.2),
			Vector3.new(math.cos(a) * 4.4, 1.3, math.sin(a) * 4.4),
			0.35,
			0.35,
			C.Water,
			"Glass"
		)
		if p then
			p.transp = 0.35
			p.collide = false
		end
	end
end

TownModels.Models.board = function(r: R)
	for _, x in { -4, 4 } do
		r:block(x - 0.35, 0, -0.35, x + 0.35, 8, 0.35, DARK_WOOD, "Wood")
	end
	r:block(-4.4, 2.5, -0.25, 4.4, 7.2, 0.25, WOOD, "WoodPlanks")
	r:block(-4.8, 7.2, -0.6, 4.8, 7.6, 0.6, DARK_WOOD, "Wood")
	r:tri(Vector3.new(0, 7.6, -1.2), Vector3.new(0, 7.6, 1.2), Vector3.new(0, 9, 0), 10, C.Red, "Slate")
	-- notes pinned on it
	local notes: { { x: number, y: number, c: Color3 } } = {
		{ x = -3.2, y = 5.6, c = C.Paper },
		{ x = -1.4, y = 6.1, c = C.Yellow },
		{ x = 0.6, y = 5.4, c = C.Paper },
		{ x = 2.6, y = 6, c = C.Pink },
		{ x = -2.4, y = 3.6, c = C.Blue },
		{ x = 0, y = 3.4, c = C.Paper },
		{ x = 2.4, y = 3.8, c = C.Paper },
	}
	for _, n in notes do
		r:box(n.x, n.y, 0.3, 1.4, 1.6, 0.06, n.c, "SmoothPlastic")
		r:ball(n.x, n.y + 0.65, 0.36, 0.2, C.Red, "SmoothPlastic")
	end
end

local function stall(r: R, c1: Color3, c2: Color3)
	-- counter
	r:block(-5, 0, 1, 5, 3.4, 3, WOOD, "WoodPlanks")
	r:block(-5.3, 3.4, 0.8, 5.3, 3.7, 3.3, DARK_WOOD, "Wood")
	-- posts
	for _, x in { -5, 5 } do
		for _, z in { -3, 3 } do
			r:block(x - 0.3, 0, z - 0.3, x + 0.3, 8, z + 0.3, DARK_WOOD, "Wood")
		end
	end
	-- back wall
	r:block(-5, 0, -3.2, 5, 8, -2.8, WOOD, "WoodPlanks")
	awning(r, 11, 7.6, 8, c1, c2)
end

TownModels.Models.tailor = function(r: R)
	stall(r, C.Pink, C.White)
	-- a dress form on the counter
	r:cyl(2.5, 4.1, 2, 0.8, 0.3, "y", C.DarkMetal, "Metal")
	r:cyl(2.5, 5.3, 2, 1.6, 0.15, "y", C.DarkMetal, "Metal")
	r:ball(2.5, 6.5, 2, 1.6, Color3.fromRGB(240, 200, 170), "Fabric")
	r:block(1.8, 5.8, 1.6, 3.2, 6.9, 2.4, C.Pink, "Fabric")
	-- spools of thread
	for i, col in { C.Red, C.Blue, C.Yellow } do
		r:cyl(-3.5 + i * 0.9, 4.1, 2.2, 0.8, 0.6, "y", col, "Fabric")
	end
	-- hanging clothes on the back wall
	for i, col in { C.Blue, C.Yellow, C.Red, Color3.fromRGB(120, 191, 94) } do
		local x = -4 + i * 1.6
		r:block(x - 0.6, 4, -2.7, x + 0.6, 6.4, -2.5, col, "Fabric")
	end
	r:block(-4.5, 6.6, -2.6, 4.5, 6.8, -2.4, C.Metal, "Metal")
end

TownModels.Models.shop = function(r: R)
	stall(r, Color3.fromRGB(120, 191, 94), C.White)
	-- crates of food on the counter and in front
	local fruit = { C.Red, C.Yellow, Color3.fromRGB(240, 138, 46), Color3.fromRGB(120, 191, 94) }
	for i = 0, 3 do
		local x = -3.6 + i * 2.4
		r:block(x - 1, 3.7, 1.2, x + 1, 4.5, 2.8, DARK_WOOD, "WoodPlanks")
		for j = 0, 2 do
			r:ball(x - 0.55 + j * 0.55, 4.7, 2, 0.6, fruit[i + 1], "SmoothPlastic")
		end
	end
	for i = 0, 1 do
		local x = -2 + i * 4
		r:block(x - 1.2, 0, 3.5, x + 1.2, 1.6, 5.3, DARK_WOOD, "WoodPlanks")
		for j = 0, 2 do
			r:ball(x - 0.6 + j * 0.6, 1.8, 4.4, 0.7, fruit[(i + j) % 4 + 1], "SmoothPlastic")
		end
	end
end

TownModels.Models.hall = function(r: R)
	-- the town hall: steps, a row of columns, a pediment with a clock, and a flag
	local wall = Color3.fromRGB(242, 232, 213)
	local trim = Color3.fromRGB(196, 190, 178)
	r:block(-9, 0, -7, 9, 1, 6, trim, "Concrete")
	r:block(-8, 1, -6, 8, 1.6, 6.5, trim, "Concrete")
	r:block(-7, 1.6, -6, 7, 11, 1, wall, "Plaster")
	-- door and windows on the front
	r:block(-1.5, 1.6, 0.95, 1.5, 6.6, 1.1, Color3.fromRGB(110, 70, 40), "Wood")
	r:ball(1, 4, 1.15, 0.3, C.Gold, "Metal")
	for _, x in { -4.6, 4.6 } do
		r:glass(x - 1.2, 4, 0.95, x + 1.2, 8, 1.05)
		r:block(x - 1.4, 3.8, 0.95, x + 1.4, 4, 1.3, trim, "Concrete")
	end
	-- porch columns
	for i = 0, 4 do
		local x = -6 + i * 3
		r:cyl(x, 6.3, 4.6, 9.4, 1.1, "y", C.White, "Marble")
	end
	r:block(-7.6, 11, -6.4, 7.6, 12, 5.4, trim, "Concrete")
	-- pediment
	r:tri(Vector3.new(-7.6, 12, 5.2), Vector3.new(7.6, 12, 5.2), Vector3.new(0, 15.5, 5.2), 0.6, wall, "Plaster")
	r:quad(
		Vector3.new(-8, 12, 5.6),
		Vector3.new(0, 15.8, 5.6),
		Vector3.new(0, 15.8, -6.6),
		Vector3.new(-8, 12, -6.6),
		0.5,
		Color3.fromRGB(156, 42, 46),
		"Slate"
	)
	r:quad(
		Vector3.new(8, 12, 5.6),
		Vector3.new(0, 15.8, 5.6),
		Vector3.new(0, 15.8, -6.6),
		Vector3.new(8, 12, -6.6),
		0.5,
		Color3.fromRGB(156, 42, 46),
		"Slate"
	)
	r:tri(Vector3.new(-7.6, 12, -6.2), Vector3.new(7.6, 12, -6.2), Vector3.new(0, 15.5, -6.2), 0.6, wall, "Plaster")
	-- clock
	r:cyl(0, 13.3, 5.5, 0.2, 2.2, "z", C.White, "SmoothPlastic")
	r:block(-0.06, 13.3, 5.62, 0.06, 14.1, 5.66, C.Black, "SmoothPlastic")
	r:block(-0.06, 13.24, 5.62, 0.6, 13.36, 5.66, C.Black, "SmoothPlastic")
	-- flag
	r:block(-0.1, 15.5, -0.5, 0.1, 21, -0.3, C.DarkMetal, "Metal")
	r:block(0.1, 19.4, -0.45, 2.8, 20.9, -0.35, C.Blue, "Fabric")
end

TownModels.Models.lamp = function(r: R)
	r:cyl(0, 0.3, 0, 0.6, 1.4, "y", C.DarkMetal, "Metal")
	r:cyl(0, 4, 0, 7.6, 0.4, "y", C.DarkMetal, "Metal")
	r:block(-0.7, 7.8, -0.7, 0.7, 8.1, 0.7, C.DarkMetal, "Metal")
	local glass = r:block(-0.55, 8.1, -0.55, 0.55, 9.4, 0.55, C.Warm, "Glass")
	r:glow(glass, 22, 1.4)
	r:block(-0.75, 9.4, -0.75, 0.75, 9.7, 0.75, C.DarkMetal, "Metal")
end

TownModels.Models.bench = function(r: R)
	for _, x in { -2.2, 2.2 } do
		r:block(x - 0.25, 0, -0.8, x + 0.25, 1.6, 0.8, C.DarkMetal, "Metal")
	end
	r:block(-2.6, 1.6, -0.9, 2.6, 1.9, 0.9, WOOD, "WoodPlanks")
	r:block(-2.6, 1.9, -0.9, 2.6, 3.4, -0.7, WOOD, "WoodPlanks")
	r:seat(-1.2, 1.9, 0, 0)
	r:seat(1.2, 1.9, 0, 0)
end

TownModels.Models.tree = function(r: R)
	r:cyl(0, 3, 0, 6, 1.4, "y", C.Bark, "Wood")
	r:ball(0, 7.5, 0, 7, C.Leaf, "Grass")
	r:ball(1.8, 6.4, 1, 4.6, C.DarkLeaf, "Grass")
	r:ball(-1.6, 6.8, -1.2, 4.8, C.Leaf, "Grass")
	r:ball(0.4, 9.6, -0.4, 4.4, C.Leaf, "Grass")
end

TownModels.Models.pine = function(r: R)
	r:cyl(0, 1.5, 0, 3, 1.2, "y", C.Bark, "Wood")
	local layers = { { 3, 7, 3.6 }, { 5.4, 5.4, 3.2 }, { 7.6, 3.8, 2.8 } }
	for _, l in layers do
		local y, w, h = l[1], l[2], l[3]
		for i = 0, 3 do
			local a = i * math.pi / 2
			local dx, dz = math.cos(a), math.sin(a)
			r:tri(
				Vector3.new(dx * w / 2, y, dz * w / 2),
				Vector3.new(-dz * w / 2, y, dx * w / 2),
				Vector3.new(0, y + h, 0),
				0.5,
				C.DarkLeaf,
				"Grass"
			)
		end
		r:block(-w / 2.9, y, -w / 2.9, w / 2.9, y + 0.6, w / 2.9, C.DarkLeaf, "Grass")
	end
end

TownModels.Models.sign = function(r: R)
	for _, x in { -3, 3 } do
		r:block(x - 0.3, 0, -0.3, x + 0.3, 6, 0.3, DARK_WOOD, "Wood")
	end
	local board = r:block(-3.6, 3.4, -0.25, 3.6, 6, 0.25, WOOD, "WoodPlanks")
	board.name = "SignBoard"
end

TownModels.Models.plotSign = function(r: R)
	r:block(-0.25, 0, -0.25, 0.25, 4.6, 0.25, DARK_WOOD, "Wood")
	local board = r:block(-2.6, 3, -0.2, 2.6, 5, 0.2, C.Cream, "Wood")
	board.name = "SignBoard"
end

TownModels.Models.mailbox = function(r: R)
	r:block(-0.15, 0, -0.15, 0.15, 3, 0.15, DARK_WOOD, "Wood")
	r:block(-0.5, 3, -0.8, 0.5, 3.8, 0.8, C.Blue, "Metal")
	r:cyl(0, 3.8, 0, 1.6, 1, "z", C.Blue, "Metal")
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
	for _, name in { "fountain", "board", "tailor", "shop", "hall", "lamp", "bench", "tree", "pine", "sign" } do
		for _, p in TownModels.prims(name) do
			p.cf = CFrame.new(x, 0, 0) * p.cf
			table.insert(out, p)
		end
		x += 20
	end
	return out
end

return TownModels
