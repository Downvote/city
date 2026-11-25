--!strict
-- The basic shapes, to build anything from (the user: "there should also be basic shapes, like
-- cube, cylinder, etc"): cubes, cylinders, balls, wedges, corner wedges, cones, pyramids, half
-- cylinders, arches, rings, tubes, planks, pillars and quarter rounds, each in a few sizes.
-- One colour each (c1), so the paint tool makes them anything, and they stack: they stand on one
-- another and on tables and counters (`stack`), and the ones with a flat top carry things on it
-- (`surface`).
--
-- They keep the town's low poly look (Build/LowPoly): a ball is a gem and a cylinder an eight
-- sided prism, and the rounded shapes drawn here from boxes and wedges (the half cylinder, the
-- arch, the ring, the tube, the quarter round) follow the same eight sides.

local Recipe = require(script.Parent.Parent.Recipe)
local Colors = require(script.Parent.Parent.Parent.Util.Colors)

type R = Recipe.Recipe

-- the corner of an octagon that sits on a circle's flat sides: tan(22.5 degrees)
local OCT = math.tan(math.rad(22.5))

local MAT = "SmoothPlastic"

-- A Roblox wedge part at a frame (full height at its +Z, sloping down to its -Z bottom edge).
local function wedge(r: R, cf: CFrame, sx: number, sy: number, sz: number)
	r:wedge(cf, sx, sy, sz, r.c1, MAT)
end

-- A corner wedge: its point over the (+X, -Z) corner of its box.
local function corner(r: R, cf: CFrame, sx: number, sy: number, sz: number)
	r:add({ shape = "CornerWedge", cf = cf, size = Vector3.new(sx, sy, sz), color = r.c1, mat = MAT })
end

-- Builders, one per kind of shape: each draws the shape `w` wide, `h` tall and `d` deep,
-- standing on y = 0 in the middle of its box.

local function cube(r: R, w: number, h: number, d: number)
	r:box(0, h / 2, 0, w, h, d, r.c1, MAT)
end

local function cylinder(r: R, w: number, h: number, _d: number)
	r:cyl(0, h / 2, 0, h, w, "y", r.c1, MAT)
end

local function sphere(r: R, w: number, _h: number, _d: number)
	r:ball(0, w / 2, 0, w, r.c1, MAT)
end

-- a ramp: low at the front (+Z), up to full height at the back
local function ramp(r: R, w: number, h: number, d: number)
	wedge(r, CFrame.new(0, h / 2, 0) * CFrame.Angles(0, math.pi, 0), w, h, d)
end

local function cornerWedge(r: R, w: number, h: number, d: number)
	corner(r, CFrame.new(0, h / 2, 0), w, h, d)
end

local function cone(r: R, w: number, h: number, _d: number)
	r:cone(0, h / 2, 0, h, w, r.c1, MAT)
end

-- four corner wedges, their points meeting over the middle
local function pyramid(r: R, w: number, h: number, _d: number)
	local a = w / 2
	for k = 0, 3 do
		local turn = CFrame.Angles(0, k * math.pi / 2, 0)
		-- (for the quarter at +x, +z: the box's X runs to -z and its Z to +x, so its point is
		-- at the middle)
		local cf = turn * CFrame.fromMatrix(Vector3.new(a / 2, h / 2, a / 2), -Vector3.zAxis, Vector3.yAxis)
		corner(r, cf, a, h, a)
	end
end

-- half an eight sided prism lying along x, its flat side down: `d` across, `d` / 2 tall
local function halfCylinder(r: R, w: number, _h: number, d: number)
	local R = d / 2
	local low, cut = OCT * R, R - OCT * R
	r:block(-w / 2, 0, -R, w / 2, low, R, r.c1, MAT)
	r:block(-w / 2, low, -low, w / 2, R, low, r.c1, MAT)
	-- the two sloping facets, their square corners against the middle
	local y = (low + R) / 2
	wedge(r, CFrame.new(0, y, -(R + low) / 2), w, cut, cut)
	wedge(r, CFrame.new(0, y, (R + low) / 2) * CFrame.Angles(0, math.pi, 0), w, cut, cut)
end

-- a quarter of an eight sided prism lying along x: square at the back and the bottom, its
-- rounded face to the front and the top
local function quarterRound(r: R, w: number, h: number, d: number)
	local R = math.min(h, d)
	local z0 = -d / 2
	local low, cut = OCT * R, R - OCT * R
	r:block(-w / 2, 0, z0, w / 2, low, z0 + R, r.c1, MAT)
	r:block(-w / 2, low, z0, w / 2, R, z0 + low, r.c1, MAT)
	wedge(r, CFrame.new(0, (low + R) / 2, z0 + (low + R) / 2) * CFrame.Angles(0, math.pi, 0), w, cut, cut)
end

-- An arch: two legs, a lintel, and the eight sided top of its opening, `open` wide; the opening's
-- top is a quarter of the arch's width under its own top.
local function arch(open: number): (R, number, number, number) -> ()
	return function(r: R, w: number, h: number, d: number)
		local a = open / 2
		local top = h - math.max(0.6, (w - open) / 2)
		local cut = a - OCT * a
		r:block(-w / 2, 0, -d / 2, -a, h, d / 2, r.c1, MAT)
		r:block(a, 0, -d / 2, w / 2, h, d / 2, r.c1, MAT)
		r:block(-a, top, -d / 2, a, h, d / 2, r.c1, MAT)
		-- the corners of the opening, square against the lintel and the legs
		local y = top - cut / 2
		local x = (a + OCT * a) / 2
		r:add({
			shape = "Wedge",
			cf = CFrame.fromMatrix(Vector3.new(-x, y, 0), -Vector3.zAxis, -Vector3.yAxis),
			size = Vector3.new(d, cut, cut),
			color = r.c1,
			mat = MAT,
		})
		r:add({
			shape = "Wedge",
			cf = CFrame.fromMatrix(Vector3.new(x, y, 0), Vector3.zAxis, -Vector3.yAxis),
			size = Vector3.new(d, cut, cut),
			color = r.c1,
			mat = MAT,
		})
	end
end

-- An upright hoop of eight sides, `band` thick, facing the front.
local function ring(band: number): (R, number, number, number) -> ()
	return function(r: R, w: number, _h: number, d: number)
		local R = w / 2
		local side = 2 * R * OCT
		for k = 0, 7 do
			local theta = k * math.pi / 4
			local mid = R - band / 2
			local at = Vector3.new(math.cos(theta) * mid, R + math.sin(theta) * mid, 0)
			r:boxAt(CFrame.new(at) * CFrame.Angles(0, 0, theta - math.pi / 2), side, band, d, r.c1, MAT)
		end
	end
end

-- A hollow tube standing up: eight sides, each `wall` thick.
local function tube(wall: number): (R, number, number, number) -> ()
	return function(r: R, w: number, h: number, _d: number)
		local R = w / 2
		local side = 2 * R * OCT
		for k = 0, 7 do
			local cf = CFrame.Angles(0, k * math.pi / 4, 0) * CFrame.new(0, h / 2, R - wall / 2)
			r:boxAt(cf, side, h, wall, r.c1, MAT)
		end
	end
end

local function plank(r: R, w: number, h: number, d: number)
	r:box(0, h / 2, 0, w, h, d, r.c1, "Wood")
	-- the grain: two fine raised lines along the top
	local groove = Colors.shade(r.c1, 0.86)
	for _, z in { -d / 4, d / 4 } do
		r:block(-w / 2 + 0.15, h - 0.01, z - 0.025, w / 2 - 0.15, h + 0.03, z + 0.025, groove, "Wood")
	end
end

-- a square pillar on a plinth, under a capital
local function pillar(r: R, w: number, h: number, _d: number)
	local foot = math.max(0.3, h * 0.06)
	local trim = Colors.shade(r.c1, 0.92)
	r:box(0, foot / 2, 0, w, foot, w, trim, MAT)
	r:box(0, foot + 0.06, 0, w - 0.12, 0.12, w - 0.12, trim, MAT)
	r:box(0, h / 2, 0, w * 0.76, h - foot * 2, w * 0.76, r.c1, MAT)
	r:box(0, h - foot - 0.06, 0, w - 0.12, 0.12, w - 0.12, trim, MAT)
	r:box(0, h - foot / 2, 0, w, foot, w, trim, MAT)
end

-- The shapes: what each is called, its builder, its colour, whether things stand on its top, and
-- its sizes as { size, w, h, d, price, name? } (the name when "<size> <shape>" won't do).
type Size = { string | number }
type Kind = {
	id: string,
	name: string,
	draw: (R, number, number, number) -> (),
	c1: string,
	top: boolean?,
	sizes: { Size },
}

local KINDS: { Kind } = {
	{
		id = "cube",
		name = "cube",
		draw = cube,
		c1 = "EADBC4",
		top = true,
		sizes = {
			{ "Small", 2, 2, 2, 10 },
			{ "Medium", 4, 4, 4, 24 },
			{ "Large", 8, 8, 8, 60 },
			{ "Long", 8, 2, 2, 24, "Long block" },
		},
	},
	{
		id = "cylinder",
		name = "cylinder",
		draw = cylinder,
		c1 = "9CC4D8",
		top = true,
		sizes = {
			{ "Small", 2, 2, 2, 10 },
			{ "Medium", 4, 4, 4, 24 },
			{ "Large", 8, 4, 8, 50 },
			{ "Tall", 2, 8, 2, 24 },
		},
	},
	{
		id = "sphere",
		name = "ball",
		draw = sphere,
		c1 = "E8A8A0",
		sizes = { { "Small", 2, 2, 2, 10 }, { "Medium", 4, 4, 4, 24 }, { "Large", 8, 8, 8, 60 } },
	},
	{
		id = "wedge",
		name = "wedge",
		draw = ramp,
		c1 = "B8D4A0",
		sizes = {
			{ "Small", 2, 2, 2, 10 },
			{ "Medium", 4, 4, 4, 24 },
			{ "Large", 8, 8, 8, 60 },
			{ "Long", 4, 2, 8, 24 },
		},
	},
	{
		id = "corner",
		name = "corner wedge",
		draw = cornerWedge,
		c1 = "D8C890",
		sizes = { { "Small", 2, 2, 2, 10 }, { "Medium", 4, 4, 4, 24 }, { "Large", 8, 8, 8, 60 } },
	},
	{
		id = "cone",
		name = "cone",
		draw = cone,
		c1 = "E0B070",
		sizes = {
			{ "Small", 2, 2, 2, 10 },
			{ "Medium", 4, 4, 4, 24 },
			{ "Large", 8, 8, 8, 60 },
			{ "Tall", 2, 6, 2, 16 },
		},
	},
	{
		id = "pyramid",
		name = "pyramid",
		draw = pyramid,
		c1 = "D9B98C",
		sizes = {
			{ "Small", 2, 2, 2, 10 },
			{ "Medium", 4, 3, 4, 24 },
			{ "Large", 8, 6, 8, 60 },
			{ "Tall", 4, 8, 4, 30 },
		},
	},
	{
		id = "halfcyl",
		name = "half cylinder",
		draw = halfCylinder,
		c1 = "A8B8E0",
		sizes = {
			{ "Small", 2, 1, 2, 10 },
			{ "Medium", 4, 2, 4, 24 },
			{ "Large", 8, 4, 8, 50 },
			{ "Long", 8, 1, 2, 20 },
		},
	},
	{
		id = "arch",
		name = "arch",
		draw = arch(2),
		c1 = "D8D0C4",
		top = true,
		sizes = { { "Small", 4, 4, 1, 16 } },
	},
	{
		id = "arch_m",
		name = "arch",
		draw = arch(4),
		c1 = "D8D0C4",
		top = true,
		sizes = { { "Medium", 6, 7, 1.5, 30 } },
	},
	{
		id = "arch_l",
		name = "arch",
		draw = arch(6),
		c1 = "D8D0C4",
		top = true,
		sizes = { { "Large", 10, 11, 2, 60 } },
	},
	{
		id = "ring",
		name = "ring",
		draw = ring(0.4),
		c1 = "E8B8C8",
		sizes = { { "Small", 2, 2, 0.4, 10 } },
	},
	{
		id = "ring_m",
		name = "ring",
		draw = ring(0.7),
		c1 = "E8B8C8",
		sizes = { { "Medium", 4, 4, 0.7, 20 } },
	},
	{
		id = "ring_l",
		name = "ring",
		draw = ring(1.2),
		c1 = "E8B8C8",
		sizes = { { "Large", 8, 8, 1.2, 40 } },
	},
	{
		id = "tube",
		name = "tube",
		draw = tube(0.3),
		c1 = "A0C8C0",
		sizes = { { "Small", 2, 2, 2, 10 }, { "Tall", 2, 8, 2, 24 } },
	},
	{
		id = "tube_m",
		name = "tube",
		draw = tube(0.45),
		c1 = "A0C8C0",
		sizes = { { "Medium", 4, 4, 4, 24 } },
	},
	{
		id = "tube_l",
		name = "tube",
		draw = tube(0.6),
		c1 = "A0C8C0",
		sizes = { { "Large", 8, 4, 8, 44 } },
	},
	{
		id = "plank",
		name = "plank",
		draw = plank,
		c1 = "B58A5E",
		top = true,
		sizes = {
			{ "Small", 4, 0.25, 1, 6 },
			{ "Medium", 8, 0.25, 1, 10 },
			{ "Large", 12, 0.3, 2, 20 },
		},
	},
	{
		id = "pillar",
		name = "pillar",
		draw = pillar,
		c1 = "EEE8DC",
		top = true,
		sizes = { { "Small", 1.2, 4, 1.2, 14 }, { "Medium", 1.6, 8, 1.6, 30 }, { "Large", 2.4, 12, 2.4, 60 } },
	},
	{
		id = "quarter",
		name = "quarter round",
		draw = quarterRound,
		c1 = "C8B8E0",
		sizes = {
			{ "Small", 2, 1, 1, 8 },
			{ "Medium", 4, 2, 2, 16 },
			{ "Large", 8, 4, 4, 40 },
			{ "Long", 8, 1, 1, 14 },
		},
	},
}

local items = {}
for _, kind in KINDS do
	for _, size in kind.sizes do
		local label = size[1] :: string
		local w, h, d = size[2] :: number, size[3] :: number, size[4] :: number
		local id = "shape_" .. string.gsub(kind.id, "_%a$", "") .. "_" .. string.lower(label)
		local draw = kind.draw
		table.insert(items, {
			id = id,
			name = (size[6] :: any) or (label .. " " .. kind.name),
			cat = "shapes",
			price = size[5] :: number,
			place = "floor",
			size = Vector3.new(w, h, d),
			c1 = kind.c1,
			stack = true,
			surface = if kind.top then h else nil,
			build = function(r: R)
				draw(r, w, h, d)
			end,
		})
	end
end

return items
