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
		-- what a shape drawn here without a material of its own is made of (a piece's material:
		-- Recipe.piece); nil for Geometry.Default
		mat: string?,
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
	Gold = Color3.fromRGB(214, 176, 96),
	Glass = Color3.fromRGB(196, 230, 242),
	Leaf = Color3.fromRGB(110, 166, 96), -- greens lean yellow and never go neon
	DarkLeaf = Color3.fromRGB(74, 128, 86),
	Bark = Color3.fromRGB(112, 84, 60),
	Soil = Color3.fromRGB(92, 66, 46),
	Stone = Color3.fromRGB(160, 160, 166),
	Water = Color3.fromRGB(104, 172, 208),
	Warm = Color3.fromRGB(255, 214, 150), -- lamp light
	Pink = Color3.fromRGB(245, 158, 181),
	Red = Color3.fromRGB(184, 80, 90),
	Yellow = Color3.fromRGB(240, 204, 110),
	Blue = Color3.fromRGB(92, 150, 196),
	Paper = Color3.fromRGB(250, 246, 235),
}

function Recipe.new(c1: Color3, c2: Color3): Recipe
	return setmetatable({ c1 = c1, c2 = c2, prims = {} }, Recipe)
end

-- What a painted piece's slots are painted in: the paint tool's material goes on with its colour
-- (the user: "some objects, when painted, seem to keep their texture, such as grass"), so every
-- part in a slot's colour takes it. Light and glass keep their own.
local KEEPS = { Neon = true, Glass = true, ForceField = true }
-- the untextured materials a piece's own material takes the place of
local PLAIN = { SmoothPlastic = true, Plastic = true }

function Recipe.add(self: Recipe, prim: Prim): Prim
	-- (a shape that names no material is made of this recipe's own, or the kit's default)
	if prim.mat == nil then
		prim.mat = self.mat or Geometry.Default
	end
	local m1, m2 = (self :: any).m1, (self :: any).m2
	if (m1 or m2) and not KEEPS[prim.mat] and not (prim.transp and prim.transp > 0) then
		if m1 and prim.color == self.c1 then
			prim.mat = m1
		elseif m2 and prim.color == self.c2 then
			prim.mat = m2
		end
	end
	table.insert(self.prims, prim)
	return prim
end

-- Draws a handful of small shapes as one piece (Geometry.piece): `draw` gets a recipe of its own
-- to draw them on, in this recipe's space, and they come back as a single primitive that the
-- Builder makes as one mesh. For details used over and over: a window's frame, an awning, a
-- shutter. Keep them plain (one material, no names, lights or see-through) and start with a box
-- that isn't turned. `collide` lets people bump into it (off by default: details are for show).
-- `mat` is what the piece is made of: every shape in it that names no material of its own (or
-- names plain plastic) takes it.
function Recipe.piece(self: Recipe, draw: (Recipe) -> (), collide: boolean?, mat: string?): Prim
	local q = Recipe.new(self.c1, self.c2)
	q.mat = mat
	draw(q)
	if mat then
		for _, p in q.prims do
			if PLAIN[p.mat] then
				p.mat = mat
			end
		end
	end
	-- (a piece is one material: when any of it is in a painted slot's colour, the whole of it
	-- takes that slot's material, before it is merged)
	local sa: any = self
	local m1, m2 = sa.m1, sa.m2
	if (m1 or m2) and #q.prims > 0 and not KEEPS[q.prims[1].mat] then
		local to = nil
		for _, p in q.prims do
			if m1 and p.color == self.c1 then
				to = m1
				break
			elseif m2 and p.color == self.c2 then
				to = to or m2
			end
		end
		if to then
			for _, p in q.prims do
				p.mat = to
			end
		end
	end
	local made = Geometry.piece(q.prims, collide)
	table.insert(self.prims, made) -- (already in its slots' materials)
	return made
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
	return self:add(Geometry.box(CFrame.new(cx, cy, cz), Vector3.new(sx, sy, sz), color, mat or self.mat))
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
	return self:add(Geometry.span(Vector3.new(x1, y1, z1), Vector3.new(x2, y2, z2), color, mat or self.mat))
end

-- A box at any frame.
function Recipe.boxAt(self: Recipe, cf: CFrame, sx: number, sy: number, sz: number, color: Color3, mat: string?): Prim
	return self:add(Geometry.box(cf, Vector3.new(sx, sy, sz), color, mat or self.mat))
end

-- A WedgePart at a frame. Roblox's wedge is full height at its back (+Z) and slopes down to its
-- bottom front edge (-Z). `ramp` below is easier when you only want a slope over a box.
function Recipe.wedge(self: Recipe, cf: CFrame, sx: number, sy: number, sz: number, color: Color3, mat: string?): Prim
	return self:add({
		shape = "Wedge",
		cf = cf,
		size = Vector3.new(sx, sy, sz),
		color = color,
		mat = mat or self.mat or Geometry.Default,
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
	local out = Geometry.triangle(
		Vector3.new(xm, y1, zl),
		Vector3.new(xm, y1, zh),
		Vector3.new(xm, y2, zh),
		width,
		color,
		mat or self.mat
	)
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
		mat = mat or self.mat or Geometry.Default,
	})
end

-- A cone standing on its base, point up: (cx, cy, cz) is its middle.
function Recipe.cone(
	self: Recipe,
	cx: number,
	cy: number,
	cz: number,
	height: number,
	diameter: number,
	color: Color3,
	mat: string?
): Prim
	return self:add({
		shape = "Cone",
		cf = CFrame.new(cx, cy, cz),
		size = Vector3.new(diameter, height, diameter),
		color = color,
		mat = mat or self.mat or Geometry.Default,
	})
end

-- A faceted lump (a rock, a clump of leaves): a ball stretched to any size and turned any way.
function Recipe.lump(self: Recipe, cf: CFrame, sx: number, sy: number, sz: number, color: Color3, mat: string?): Prim
	return self:add({
		shape = "Ball",
		cf = cf,
		size = Vector3.new(sx, sy, sz),
		color = color,
		mat = mat or self.mat or Geometry.Default,
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
		mat = mat or self.mat or Geometry.Default,
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
	local prim = Geometry.beam(p1, p2, width, height, color, mat or self.mat)
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
	local out = Geometry.triangle(a, b, c, thickness, color, mat or self.mat)
	for _, p in out do
		self:add(p)
	end
	return out
end

-- A flat four sided face with thickness (corners in order).
function Recipe.quad(
	self: Recipe,
	p1: Vector3,
	p2: Vector3,
	p3: Vector3,
	p4: Vector3,
	thickness: number,
	color: Color3,
	mat: string?
): { Prim }
	local out = Geometry.quad(p1, p2, p3, p4, thickness, color, mat or self.mat)
	for _, p in out do
		self:add(p)
	end
	return out
end

-- Edges ------------------------------------------------------------------------------------------
--
-- The user: "for edges and corners where faces meet, is it possible to detail and weather them such
-- that edges have weathering detail on their textures or is smoothed?" Roblox shades no edge of its
-- own, so the edge is drawn: a box whose top edges are cut back at 45 degrees (a chamfer, the way a
-- table top, a counter's nosing or a shelf is finished), or rounded over. The cut catches the light
-- differently from the faces either side, so the edge reads, and `wear` paints it a little lighter
-- or darker than the face, where hands and feet rub the paint and the grime collects.

export type BevelOpts = {
	round: boolean?, -- rounded over (truly round rods and balls) rather than cut at 45 degrees
	under: boolean?, -- the bottom edges too (a slab seen from below: a shelf, a floating top)
	wear: number?, -- the edges' paint times this (0.9 a shade darker, 1.08 rubbed lighter)
}

-- What a shape in `color` drawn in `mat` is made of once the paint tool's material is on (the
-- edges of a bevel are a shade off their face's colour, so they ask for it by the face's).
function Recipe.slotMat(self: Recipe, color: Color3, mat: string?): string
	local m = mat or self.mat or Geometry.Default
	local m1, m2 = (self :: any).m1, (self :: any).m2
	if not KEEPS[m] then
		if m1 and color == self.c1 then
			return m1
		elseif m2 and color == self.c2 then
			return m2
		end
	end
	return m
end

local function shaded(c: Color3, k: number?): Color3
	if not k or k == 1 then
		return c
	end
	return Color3.new(math.clamp(c.R * k, 0, 1), math.clamp(c.G * k, 0, 1), math.clamp(c.B * k, 0, 1))
end

-- A box between two corners with its top edges cut back by `b` (or rounded over: opts.round), in
-- one line where a recipe would draw a plain block. The top stays where the block's was, so what
-- stands on it stands as before; only its rim is taken in. Returns the box's body (the part a
-- recipe would mark or name). A bevel too big for the box is made to fit; a tiny one is no bevel.
function Recipe.bevel(
	self: Recipe,
	x1: number,
	y1: number,
	z1: number,
	x2: number,
	y2: number,
	z2: number,
	b: number,
	color: Color3,
	mat: string?,
	opts: BevelOpts?
): Prim
	local o: BevelOpts = opts or {}
	x1, x2 = math.min(x1, x2), math.max(x1, x2)
	y1, y2 = math.min(y1, y2), math.max(y1, y2)
	z1, z2 = math.min(z1, z2), math.max(z1, z2)
	local h = y2 - y1
	b = math.min(b, (x2 - x1) / 2 - 0.02, (z2 - z1) / 2 - 0.02, if o.under then h * 0.45 else h * 0.9)
	if b < 0.02 then
		return self:block(x1, y1, z1, x2, y2, z2, color, mat)
	end
	local edge = shaded(color, o.wear)
	local em = self:slotMat(color, mat)
	local bottom = if o.under then y1 + b else y1
	local body = self:block(x1, bottom, z1, x2, y2 - b, z2, color, mat)
	self:block(x1 + b, y2 - b, z1 + b, x2 - b, y2, z2 - b, color, mat)
	if o.under then
		self:block(x1 + b, y1, z1 + b, x2 - b, y1 + b, z2 - b, color, mat)
	end
	local xm, zm = (x1 + x2) / 2, (z1 + z2) / 2
	local lx, lz = x2 - x1, z2 - z1
	-- the four top edges (and the four bottom ones), each a wedge full height on its inner side:
	-- the front and back run the whole length, the sides between them
	local function edges(y: number, flip: boolean)
		local turn = if flip then CFrame.Angles(0, 0, math.pi) else CFrame.identity
		if o.round then
			-- (a rod along each edge, a ball at each corner, all truly round)
			local c = y
			for _, z in { z1 + b, z2 - b } do
				local rod = self:cyl(xm, c, z, lx - 2 * b, 2 * b, "x", edge, em)
				rod.smooth = true
			end
			for _, x in { x1 + b, x2 - b } do
				local rod = self:cyl(x, c, zm, lz - 2 * b, 2 * b, "z", edge, em)
				rod.smooth = true
				for _, z in { z1 + b, z2 - b } do
					local ball = self:ball(x, c, z, 2 * b, edge, em)
					ball.smooth = true
				end
			end
			return
		end
		local yc = if flip then y + b / 2 else y - b / 2
		self:wedge(CFrame.new(xm, yc, z2 - b / 2) * CFrame.Angles(0, math.pi, 0) * turn, lx, b, b, edge, em)
		self:wedge(CFrame.new(xm, yc, z1 + b / 2) * turn, lx, b, b, edge, em)
		if lz - 2 * b > 0.01 then
			self:wedge(
				CFrame.new(x1 + b / 2, yc, zm) * CFrame.Angles(0, math.pi / 2, 0) * turn,
				lz - 2 * b,
				b,
				b,
				edge,
				em
			)
			self:wedge(
				CFrame.new(x2 - b / 2, yc, zm) * CFrame.Angles(0, -math.pi / 2, 0) * turn,
				lz - 2 * b,
				b,
				b,
				edge,
				em
			)
		end
	end
	if o.round then
		edges(y2 - b, false)
		if o.under then
			edges(y1 + b, true)
		end
	else
		edges(y2, false)
		if o.under then
			edges(y1, true)
		end
	end
	return body
end

-- See-through glass between two corners.
function Recipe.glass(self: Recipe, x1: number, y1: number, z1: number, x2: number, y2: number, z2: number): Prim
	local p = self:block(x1, y1, z1, x2, y2, z2, Recipe.Colors.Glass, "Glass")
	p.transp = 0.55
	return p
end

-- Marks a prim as lit at night (it glows and its light switches on). A range of 0 makes it glow
-- with no light of its own, for the extra bulbs of something that already has one. On a player's
-- plot it is on at every hour instead, until its owner switches it off (Sim/Lights).
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
-- Roblox seats face their sitter along the seat's LookVector (-Z), so the part is turned round.
function Recipe.seat(self: Recipe, x: number, y: number, z: number, yaw: number?): Prim
	return self:add({
		shape = "Block",
		cf = CFrame.new(x, y + 0.1, z) * CFrame.Angles(0, math.rad((yaw or 0) + 180), 0),
		size = Vector3.new(1.6, 0.2, 1.6),
		color = Recipe.Colors.White,
		mat = Geometry.Default,
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
		mat = Geometry.Default,
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
			self:box(sx * hx, h / 2, sz * hz, leg, h, leg, color, mat or self.mat)
		end
	end
end

return Recipe
