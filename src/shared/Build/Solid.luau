--!strict
-- What of a placed piece people bump into. The user: "villagers and the player can sometimes get
-- stuck in objects". Every part of a piece used to be solid, down to the cup on a table, a
-- picture's frame and a plant's leaves, so a body caught on the little things, climbed onto them
-- or wedged between them. Now only a piece's body is solid: the sofa's seat, back and arms, a
-- table's top and legs, a bookcase's sides, a tree's trunk. The rest is walked through:
--   * a piece that hangs on a wall or from a ceiling, a small thing that stands on a surface,
--     a mark, and a rug or mat lying flat (no taller than Tuning.Unstick.Flat): all of it
--   * a part whose longest side is under Tuning.Unstick.Tiny (a knob, a cup, a book, a twig)
--   * what stands on the piece's own top (the kettle drawn on a counter, the hutch on a desk)
--   * leaves and flowers (foliage: Grass and LeafyGrass, or a part named Leaf)
-- The basic shapes, stairs and paths keep every part: they are for building with and walking on.
-- A piece drawn as pieces (Recipe.piece: details for show, never solid) used to be walked
-- through whole when its body was one of them (a stall, an arch's columns, a deck's boards): on
-- a floor or the ground its pieces are opened into their shapes and those go by the same rules,
-- so its body is solid like any other. (What players build is drawn from plain parts anyway, so
-- it looks the same.) Pieces stay as drawn where the drawing already says what is solid: a
-- door's or a window's (clear of the doorway), a workplace's (its loop of spots round it,
-- Sim/Routine, was laid out to them), the shapes', stairs' and paths' (stairs are walked up a
-- hidden ramp, and their treads must not catch a foot) and any piece with a hidden solid box.
-- A part that isn't solid can still be clicked (CanQuery stays on), so Build mode picks it as
-- before. Plain data, so the specs can hold the catalog to it; Build/Builder applies it to every
-- piece it draws on a plot.

local Catalog = require(script.Parent.Catalog)
local Geometry = require(script.Parent.Geometry)
local Tuning = require(script.Parent.Parent.Config.Tuning)

local Solid = {}

local K = Tuning.Unstick

-- pieces nothing of which is solid, by where they go (Catalog.Places)
Solid.Never = { wall = true, ceiling = true, surface = true, mark = true }

-- the materials of leaves, flowers and grass
Solid.Foliage = { Grass = true, LeafyGrass = true }

local function baseMaterial(mat: string): string
	local colon = string.find(mat, ":", 1, true)
	return if colon then string.sub(mat, 1, colon - 1) else mat
end

-- Are all of the piece's parts solid, whatever their size? (building blocks, stairs, paths)
function Solid.whole(def: Catalog.Def): boolean
	return def.stack == true or def.place == "stairs" or Catalog.isPath(def)
end

-- Is nothing of the piece solid?
function Solid.none(def: Catalog.Def): boolean
	if Solid.Never[def.place] then
		return true
	end
	if Catalog.hasTag(def, "rug") then
		return true
	end
	return def.place == "floor" and def.size.Y <= K.Flat and not Solid.whole(def)
end

-- Are the piece's own pieces opened into their shapes (see above)? `prims` as Catalog.prims drew them.
function Solid.opens(def: Catalog.Def, prims: { Geometry.Prim }): boolean
	if def.job or Solid.none(def) or Solid.whole(def) then
		return false
	end
	if def.place ~= "floor" and def.place ~= "ground" then
		return false
	end
	for _, p in prims do
		if (p.transp or 0) >= 0.99 and p.collide ~= false and not p.role then
			return false -- solid where its drawing says, by a hidden box
		end
	end
	return true
end

-- Does this part of the piece stay solid? `prim` is in the piece's own space (y = 0 its floor).
function Solid.keeps(def: Catalog.Def, prim: Geometry.Prim): boolean
	if prim.collide == false then
		return false
	end
	if Solid.none(def) then
		return false
	end
	if Solid.whole(def) then
		return true
	end
	if Solid.Foliage[baseMaterial(prim.mat)] or prim.name == "Leaf" then
		return false
	end
	if math.max(prim.size.X, prim.size.Y, prim.size.Z) < K.Tiny then
		return false
	end
	local top = def.surface
	if top then
		local lo = Geometry.bounds({ prim })
		if lo.Y >= top - K.OnTop then
			return false
		end
	end
	return true
end

-- The piece's prims with what isn't solid marked (collide = false) and, on a floor or the
-- ground, its pieces opened into their shapes. Call it on the prims Catalog.prims drew, before
-- they are moved into the plot, and use the list it returns.
function Solid.apply(def: Catalog.Def, prims: { Geometry.Prim }): { Geometry.Prim }
	local out = prims
	local all = Solid.opens(def, prims)
	-- (a piece drawn solid, `collide`, is opened wherever the rules apply at all: that only
	-- ever takes its little parts out of it)
	local solidOnes = not Solid.none(def) and not Solid.whole(def)
	if all or solidOnes then
		out = table.create(#prims)
		for _, p in prims do
			if p.shape == "Piece" and p.parts and (all or p.collide == true) then
				for _, q in p.parts do
					local c = table.clone(q)
					c.cf = p.cf * q.cf
					c.name = p.name -- (a named piece's name goes on every part it is made as)
					c.collide = nil
					table.insert(out, c)
				end
			else
				table.insert(out, p)
			end
		end
	end
	for _, p in out do
		if not Solid.keeps(def, p) then
			p.collide = false
		end
	end
	return out
end

return Solid
