--!strict
-- The little drawing API every catalog item's `build` function uses.
--
-- Space: studs, item-local. The origin is the centre of the item's footprint at floor level,
-- +Y is up and +Z is the item's front (the side a person faces it from). An item of size
-- (W, H, D) should stay inside x in [-W/2, W/2], y in [0, H], z in [-D/2, D/2].
-- Wall items: the origin is on the wall's surface, +Z points out into the room, y = 0 is the
-- item's bottom edge. Openings (doors, windows): the origin is the bottom centre of the hole in
-- the wall's middle plane, x runs along the wall; keep the frame within z in [-0.5, 0.5].
-- Ceiling items: the origin is on the ceiling and the item hangs down (negative y).
--
-- r.c1 and r.c2 are the item's two paintable colours. Use them for the main surfaces so the
-- paint tool means something; fixed colours are fine for details (metal, glass, leaves).

local Geometry = require(script.Parent.Geometry)

export type Prim = Geometry.Prim

local Recipe = {}
Recipe.__index = Recipe

export type Recipe = typeof(setmetatable(
	{} :: {
		c1: Color3,
		c2: Color3,
		prims: { Prim },
	},
	Recipe
))

-- Handy fixed colours
Recipe.Colors = {
	White = Color3.fromRGB(245, 243, 238),
	Cream = Color3.fromRGB(242, 232, 213),
	Black = Color3.fromRGB(43, 40, 46),
	Metal = Color3.fromRGB(165, 168, 176),
	DarkMetal = Color3.fromRGB(88, 90, 98),
	Gold = Color3.fromRGB(222, 178, 82),
	Glass = Color3.fromRGB(196, 230, 242),
	Leaf = Color3.fromRGB(86, 160, 72),
	DarkLeaf = Color3.fromRGB(52, 115, 58),
	Bark = Color3.fromRGB(110, 76, 48),
	Soil = Color3.fromRGB(92, 66, 46),
	Stone = Color3.fromRGB(160, 160, 166),
	Water = Color3.fromRGB(90, 170, 220),
	Warm = Color3.fromRGB(255, 214, 150), -- lamp light
	Pink = Color3.fromRGB(245, 158, 181),
	Red = Color3.fromRGB(199, 56, 63),
	Yellow = Color3.fromRGB(255, 212, 92),
	Blue = Color3.fromRGB(79, 169, 217),
	Paper = Color3.fromRGB(250, 246, 235),
}

function Recipe.new(c1: Color3, c2: Color3): Recipe
	return setmetatable({ c1 = c1, c2 = c2, prims = {} }, Recipe)
end

function Recipe.add(self: Recipe, prim: Prim): Prim
	table.insert(self.prims, prim)
	return prim
end

-- An axis aligned box by its centre and size.
function Recipe.box(
	self: Recipe,
	cx: number,
	cy: number,
	cz: number,
	sx: number,
	sy: number,
	sz: number,
	color: Color3,
	mat: string?
): Prim
	return self:add(Geometry.box(CFrame.new(cx, cy, cz), Vector3.new(sx, sy, sz), color, mat))
end

-- An axis aligned box between two corners.
function Recipe.block(
	self: Recipe,
	x1: number,
	y1: number,
	z1: number,
	x2: number,
	y2: number,
	z2: number,
	color: Color3,
	mat: string?
): Prim
	return self:add(Geometry.span(Vector3.new(x1, y1, z1), Vector3.new(x2, y2, z2), color, mat))
end

-- A box at any frame.
function Recipe.boxAt(self: Recipe, cf: CFrame, sx: number, sy: number, sz: number, color: Color3, mat: string?): Prim
	return self:add(Geometry.box(cf, Vector3.new(sx, sy, sz), color, mat))
end

-- A WedgePart at a frame. Roblox's wedge is full height at its back (+Z) and slopes down to its
-- bottom front edge (-Z). `ramp` below is easier when you only want a slope over a box.
function Recipe.wedge(self: Recipe, cf: CFrame, sx: number, sy: number, sz: number, color: Color3, mat: string?): Prim
	return self:add({
		shape = "Wedge",
		cf = cf,
		size = Vector3.new(sx, sy, sz),
		color = color,
		mat = mat or "SmoothPlastic",
	})
end

-- A ramp over the box (x1..x2, y1..y2, z1..z2) that is low at z = lowZ (one of z1 or z2) and
-- high at the other end. Built from a real triangle so the slope is right either way.
function Recipe.ramp(
	self: Recipe,
	x1: number,
	y1: number,
	z1: number,
	x2: number,
	y2: number,
	z2: number,
	lowAtZ1: boolean,
	color: Color3,
	mat: string?
): { Prim }
	local zl = if lowAtZ1 then z1 else z2
	local zh = if lowAtZ1 then z2 else z1
	local xm = (x1 + x2) / 2
	local width = math.abs(x2 - x1)
	local out =
		Geometry.triangle(Vector3.new(xm, y1, zl), Vector3.new(xm, y1, zh), Vector3.new(xm, y2, zh), width, color, mat)
	for _, p in out do
		self:add(p)
	end
	return out
end

-- A cylinder along an axis ("x", "y" or "z").
function Recipe.cyl(
	self: Recipe,
	cx: number,
	cy: number,
	cz: number,
	length: number,
	diameter: number,
	axis: string,
	color: Color3,
	mat: string?
): Prim
	-- Roblox cylinders run along their own X axis
	local rot = CFrame.identity
	if axis == "y" then
		rot = CFrame.Angles(0, 0, math.pi / 2)
	elseif axis == "z" then
		rot = CFrame.Angles(0, math.pi / 2, 0)
	end
	return self:add({
		shape = "Cylinder",
		cf = CFrame.new(cx, cy, cz) * rot,
		size = Vector3.new(length, diameter, diameter),
		color = color,
		mat = mat or "SmoothPlastic",
	})
end

function Recipe.ball(
	self: Recipe,
	cx: number,
	cy: number,
	cz: number,
	diameter: number,
	color: Color3,
	mat: string?
): Prim
	return self:add({
		shape = "Ball",
		cf = CFrame.new(cx, cy, cz),
		size = Vector3.new(diameter, diameter, diameter),
		color = color,
		mat = mat or "SmoothPlastic",
	})
end

-- A beam (box) from one point to another.
function Recipe.beam(
	self: Recipe,
	p1: Vector3,
	p2: Vector3,
	width: number,
	height: number,
	color: Color3,
	mat: string?
): Prim?
	local prim = Geometry.beam(p1, p2, width, height, color, mat)
	if prim then
		self:add(prim)
	end
	return prim
end

-- A flat triangle with thickness.
function Recipe.tri(
	self: Recipe,
	a: Vector3,
	b: Vector3,
	c: Vector3,
	thickness: number,
	color: Color3,
	mat: string?
): { Prim }
	local out = Geometry.triangle(a, b, c, thickness, color, mat)
	for _, p in out do
		self:add(p)
	end
	return out
end

-- See-through glass between two corners.
function Recipe.glass(self: Recipe, x1: number, y1: number, z1: number, x2: number, y2: number, z2: number): Prim
	local p = self:block(x1, y1, z1, x2, y2, z2, Recipe.Colors.Glass, "Glass")
	p.transp = 0.55
	return p
end

-- Marks a prim as lit at night (it glows and its light switches on). A range of 0 makes it glow
-- with no light of its own, for the extra bulbs of something that already has one.
function Recipe.glow(self: Recipe, prim: Prim, range: number?, brightness: number?, color: Color3?): Prim
	prim.role = "glow"
	if range == 0 then
		return prim
	end
	prim.light = {
		range = range or 14,
		brightness = brightness or 1.2,
		color = color or Recipe.Colors.Warm,
	}
	return prim
end

function Recipe.smoke(self: Recipe, prim: Prim): Prim
	prim.effect = "smoke"
	return prim
end

function Recipe.fire(self: Recipe, prim: Prim): Prim
	prim.effect = "fire"
	return prim
end

function Recipe.noCollide(self: Recipe, prim: Prim): Prim
	prim.collide = false
	return prim
end

-- A place to sit: (x, y, z) is the seat surface, yaw turns the sitter (0 faces +Z, the front).
function Recipe.seat(self: Recipe, x: number, y: number, z: number, yaw: number?): Prim
	return self:add({
		shape = "Block",
		cf = CFrame.new(x, y + 0.1, z) * CFrame.Angles(0, math.rad(yaw or 0), 0),
		size = Vector3.new(1.6, 0.2, 1.6),
		color = Recipe.Colors.White,
		mat = "SmoothPlastic",
		transp = 1,
		collide = false,
		role = "seat",
	})
end

-- A place to sleep: (x, y, z) is the mattress top under the sleeper's middle; yaw points the head
-- (0 = head toward -Z, the back of the bed).
function Recipe.sleep(self: Recipe, x: number, y: number, z: number, yaw: number?): Prim
	return self:add({
		shape = "Block",
		cf = CFrame.new(x, y + 0.1, z) * CFrame.Angles(0, math.rad(yaw or 0), 0),
		size = Vector3.new(2, 0.2, 5),
		color = Recipe.Colors.White,
		mat = "SmoothPlastic",
		transp = 1,
		collide = false,
		role = "bed",
	})
end

-- Marks a prim as a door leaf that swings round a hinge at local x = hingeX (in the door's frame).
function Recipe.door(self: Recipe, prim: Prim, hingeX: number): Prim
	prim.role = "door"
	prim.collide = false
	prim.attrs = prim.attrs or {};
	(prim.attrs :: any).HingeX = hingeX
	return prim
end

-- Shorthand: a table top with four legs, used by many tables and desks.
function Recipe.legs(
	self: Recipe,
	w: number,
	d: number,
	h: number,
	leg: number,
	inset: number,
	color: Color3,
	mat: string?
)
	local hx = w / 2 - inset - leg / 2
	local hz = d / 2 - inset - leg / 2
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			self:box(sx * hx, h / 2, sz * hz, leg, h, leg, color, mat)
		end
	end
end

return Recipe
