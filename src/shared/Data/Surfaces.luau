--!strict
-- What the town's buildings and things are made of, so none of it is left in flat plastic (the
-- user: "for all buildings and decor, make it such that textures are used, never make them
-- untextured"). The models name a material where they know it: a bench is Wood, a lamp post
-- Metal, an awning Fabric:Canvas. Whatever is still SmoothPlastic or Plastic when a model is
-- handed out (TownMap.prims, TownMap.ground) is given one here by what it looks like: leaves are
-- grass, brown is timber, the rest painted metal or painted render. Every one of those has a
-- picture of its own (Data/TextureIds), soft enough to take any paint.
--
-- Left alone: what glows (Neon, and a lamp that lights up after dark), Glass, ForceField, what is
-- see-through or hidden (water, the walls round the shallows) and a part too small for a texture
-- to show (under Tuning.Unstick.Tiny).
--
-- A piece (Geometry.piece) is one material: all its shapes take the one picked for the biggest
-- of them, and its key is written again with it.

local Geometry = require(script.Parent.Parent.Build.Geometry)
local Tuning = require(script.Parent.Parent.Config.Tuning)

type Prim = Geometry.Prim

local Surfaces = {}

-- The materials that are no texture at all.
Surfaces.Plain = { SmoothPlastic = true, Plastic = true }

-- What keeps its own look: light, glass and the force field.
Surfaces.Keeps = { Neon = true, Glass = true, ForceField = true }

-- The textures things are given by look (Data/TextureIds has a picture for each).
Surfaces.Leaves = "Grass" -- a clump of leaves, a hedge: the grass picture, tinted by its paint
Surfaces.Plants = "LeafyGrass" -- leaves and stems drawn as boxes
Surfaces.Timber = "Wood" -- painted or stained timber
Surfaces.Painted = "Metal" -- painted metal: the plainest picture, for small things in any colour
Surfaces.Render = "Concrete:Stucco" -- smooth painted render, for what is pale

local function base(mat: string): string
	local colon = string.find(mat, ":", 1, true)
	return if colon then string.sub(mat, 1, colon - 1) else mat
end

-- Whether a material is flat plastic ("SmoothPlastic", or a look on it like "SmoothPlastic:X").
function Surfaces.plain(mat: string?): boolean
	return mat == nil or Surfaces.Plain[base(mat)] == true
end

-- Whether a shape takes a texture at all: not light, glass or see-through.
function Surfaces.wears(p: Prim): boolean
	return (p.transp or 0) <= 0 and p.role ~= "glow" and not Surfaces.Keeps[base(p.mat)]
end

-- Whether a shape must wear a texture: one that takes it and is big enough for it to show. (The
-- little ones are dressed all the same, so two shapes in one paint never differ in material.)
function Surfaces.shows(p: Prim): boolean
	if not Surfaces.wears(p) then
		return false
	end
	if p.shape == "Piece" then
		return true
	end
	return math.max(p.size.X, p.size.Y, p.size.Z) >= Tuning.Unstick.Tiny
end

-- A face this big (square studs) is a wall or a slab, painted render rather than painted metal.
Surfaces.Wall = 24

-- The texture for a plain shape of this colour, shape and size: leaves and plants in green,
-- timber in brown, pale paint and anything as big as a wall as render, the rest painted metal.
function Surfaces.pick(color: Color3, shape: string?, size: Vector3?): string
	local h, s, v = color:ToHSV()
	local hue = h * 360
	if hue >= 70 and hue <= 140 and s >= 0.25 and v >= 0.2 then
		return if shape == "Ball" or shape == "Cone" then Surfaces.Leaves else Surfaces.Plants
	end
	if hue >= 12 and hue <= 45 and s >= 0.28 and s <= 0.8 and v >= 0.25 and v <= 0.8 then
		return Surfaces.Timber
	end
	if v >= 0.8 and s <= 0.18 then
		return Surfaces.Render
	end
	if size then
		local a, b, c = size.X, size.Y, size.Z
		if math.max(a * b, b * c, a * c) >= Surfaces.Wall then
			return Surfaces.Render
		end
	end
	return Surfaces.Painted
end

local function area(p: Prim): number
	local s = p.size
	return s.X * s.Y + s.Y * s.Z + s.X * s.Z
end

-- The one material for a piece whose shapes are plain: `default`, or picked by its biggest shape.
local function pieceMaterial(p: Prim, default: string?): string
	if default then
		return default
	end
	local best, most = p, -1
	for _, q in p.parts or {} do
		local a = area(q)
		if a > most then
			best, most = q, a
		end
	end
	return Surfaces.pick(best.color, best.shape, best.size)
end

-- Gives one shape a texture if it is plain and shows: `default` when given, else by its look.
-- Returns the shape.
function Surfaces.dressOne(p: Prim, default: string?): Prim
	if not Surfaces.plain(p.mat) or not Surfaces.wears(p) then
		return p
	end
	if p.shape == "Piece" then
		local to = pieceMaterial(p, default)
		local from = p.mat
		p.mat = to
		if p.key and string.sub(p.key, 1, #from) == from then
			p.key = to .. string.sub(p.key, #from + 1)
		end
		-- (a stamp's shapes are shared by every copy of it: they change once, the same way)
		for _, q in p.parts or {} do
			if Surfaces.plain(q.mat) then
				q.mat = to
			end
		end
		return p
	end
	p.mat = default or Surfaces.pick(p.color, p.shape)
	return p
end

-- Gives every plain shape in the list a texture (in place). Returns the list. A colour that is
-- wall sized anywhere in the list is render everywhere in it, so two shapes in one paint that
-- touch never differ in material.
function Surfaces.dress(prims: { Prim }, default: string?): { Prim }
	if default then
		for _, p in prims do
			Surfaces.dressOne(p, default)
		end
		return prims
	end
	local big: { [string]: boolean } = {}
	for _, p in prims do
		if p.shape ~= "Piece" and Surfaces.plain(p.mat) and Surfaces.wears(p) then
			if Surfaces.pick(p.color, p.shape, p.size) == Surfaces.Render then
				big[p.color:ToHex()] = true
			end
		end
	end
	for _, p in prims do
		if p.shape ~= "Piece" and Surfaces.plain(p.mat) and Surfaces.wears(p) and big[p.color:ToHex()] then
			local picked = Surfaces.pick(p.color, p.shape)
			p.mat = if picked == Surfaces.Painted then Surfaces.Render else picked
		else
			Surfaces.dressOne(p)
		end
	end
	return prims
end

-- The shapes in a list that are still flat plastic where they show (the Textures spec wants none
-- in the town). Pieces are opened.
function Surfaces.untextured(prims: { Prim }): { Prim }
	local out = {}
	for _, p in Geometry.flatten(prims) do
		if Surfaces.plain(p.mat) and Surfaces.shows(p) then
			table.insert(out, p)
		end
	end
	return out
end

return Surfaces
