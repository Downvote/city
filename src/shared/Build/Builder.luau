--!strict
-- Turns primitives into Parts, and a plan's objects into Models.
-- Used by the server for the real builds and by the client for see-through placement ghosts.

local Geometry = require(script.Parent.Geometry)
local Plan = require(script.Parent.Plan)
local Shapes = require(script.Parent.Shapes)
local Catalog = require(script.Parent.Catalog)
local Solid = require(script.Parent.Solid) -- (what of a placed piece is solid)
local Water = require(script.Parent.Water) -- (water: pools and ponds)
local Stretch = require(script.Parent.Stretch) -- (a piece made wider, deeper or taller)
local Basement = require(script.Parent.Basement) -- (the basement's lining round its open sides)
local Textures = require(script.Parent.Parent.Data.Textures)
local Palette = require(script.Parent.Parent.Data.Palette)
local LowPoly = require(script.Parent.LowPoly)
local Tuning = require(script.Parent.Parent.Config.Tuning)

type Prim = Geometry.Prim

local Builder = {}

Builder.Tags = {
	NightLight = "NightLight", -- parts that glow and light up after dark
	-- parts that glow on a piece a player placed: on at every hour, switched by its owner and put
	-- out near a sleeping villager (Sim/Lights, Services/Lights); the clock leaves them alone
	PlacedLight = "PlacedLight",
	-- the lamps in the rooms of the town's buildings (Data/Interiors): lit at every hour, as a
	-- shop's are, so a room you walk into is lit by day too; the clock leaves them alone
	RoomLight = "RoomLight",
	DoorLeaf = "DoorLeaf",
	SeatSpot = "SeatSpot",
	BedSpot = "BedSpot",
}

-- The low poly kit (Build/LowPoly): a folder of shapes the server cuts when it starts. With it,
-- balls, cylinders and cones are drawn as faceted copies of its shapes; without it (the specs, or
-- a place where solid modelling failed) they are Roblox's own smooth ones.
local kit: { [string]: BasePart } = {}

function Builder.useKit(folder: Instance?)
	kit = {}
	if folder then
		for _, name in LowPoly.Shapes do
			local shape = folder:FindFirstChild(name)
			if shape and shape:IsA("BasePart") then
				kit[name] = shape
			end
		end
	end
end

function Builder.hasKit(): boolean
	return next(kit) ~= nil
end

-- Pictures from the Roblox library (Plan: Pictures). Roblox's own thumbnail of an asset shows a
-- decal's picture as well as an image's, and only once its moderation has passed it.
function Builder.pictureUri(id: number): string
	return string.format("rbxthumb://type=Asset&id=%d&w=420&h=420", id)
end

-- Shows the picture on one face of a part: a SurfaceGui with the picture filling it.
function Builder.showPicture(part: BasePart, face: string, id: number)
	local normal = (Enum.NormalId :: any)[face]
	if not normal then
		return
	end
	local gui = Instance.new("SurfaceGui")
	gui.Name = "Picture"
	gui.Face = normal
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 60
	gui.LightInfluence = 1
	local image = Instance.new("ImageLabel")
	image.Name = "Image"
	image.BackgroundTransparency = 1
	image.Size = UDim2.fromScale(1, 1)
	image.Image = Builder.pictureUri(id)
	image.ScaleType = Enum.ScaleType.Crop
	image.Parent = gui
	gui.Parent = part
end

export type Options = {
	ghost: boolean?, -- see-through, no collisions, no lights (placement previews)
	plain: boolean?, -- pieces as their shapes, never merged (what players build in Build mode)
	placed: boolean?, -- a piece on a player's plot (Builder.render): what glows is PlacedLight
	tint: Color3?, -- ghost colour override (red when a spot is not allowed)
}

local function makePart(prim: Prim, frame: CFrame, opts: Options?): BasePart
	local part: BasePart
	local ghost = opts and opts.ghost
	if prim.role == "seat" and not ghost then
		local seat = Instance.new("Seat")
		seat.Disabled = true
		part = seat
	elseif prim.shape == "Wedge" then
		part = Instance.new("WedgePart")
	elseif prim.shape == "CornerWedge" then
		part = Instance.new("CornerWedgePart")
	else
		-- round as Roblox draws it, not the low poly kit: a shape marked `smooth` (a wheel, a lamp)
		local name = if prim.smooth then nil else LowPoly.shapeFor(prim.shape, prim.size)
		local shape = name and kit[name]
		if shape then
			part = shape:Clone()
			part.Name = "Part"
			part:SetAttribute("Kit", name)
		else
			local p = Instance.new("Part")
			if prim.shape == "Cylinder" then
				p.Shape = Enum.PartType.Cylinder
			elseif prim.shape == "Ball" then
				p.Shape = Enum.PartType.Ball
			end
			part = p
		end
	end
	local cf = frame * prim.cf
	local round = prim.size.X == prim.size.Y and prim.size.Y == prim.size.Z
	if part:GetAttribute("Kit") == "Gem" and round then
		-- every gem turned its own way, so clumps of them look grown rather than stacked (a lump
		-- stretched and turned on purpose keeps the turn it was given)
		cf = cf * LowPoly.turn(prim.cf.Position)
	elseif prim.shape == "Cone" and part:GetAttribute("Kit") == nil then
		-- no kit: a cone falls back to a cylinder standing on its end
		cf = cf * CFrame.Angles(0, 0, math.pi / 2)
		local p = part :: Part
		p.Shape = Enum.PartType.Cylinder
		prim = table.clone(prim)
		prim.size = Vector3.new(prim.size.Y, prim.size.X, prim.size.Z)
	end
	part.Size = prim.size
	part.CFrame = cf
	part.Anchored = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	-- "Concrete" is Roblox's material; "Concrete:Panel" is that material in one of our own
	-- looks (a MaterialVariant named CatalogTownPanel, Data/Textures). Where the place has no such
	-- variant the part simply shows the plain material.
	local base, look = prim.mat, nil
	local colon = string.find(prim.mat, ":", 1, true)
	if colon then
		base, look = string.sub(prim.mat, 1, colon - 1), string.sub(prim.mat, colon + 1)
	end
	local mat = (Enum.Material :: any)[base]
	part.Material = mat or (Enum.Material :: any)[Geometry.Default]
	if look then
		part.MaterialVariant = "CatalogTown" .. look
	end
	part.Color = Textures.tint(prim.mat, prim.color)
	part.Transparency = prim.transp or 0
	part.CanCollide = prim.collide ~= false
	if prim.name then
		part.Name = prim.name
	end
	-- a picture from the library on the face the piece named (Catalog: `picture`)
	local attrs = prim.attrs
	if attrs and type(attrs.Picture) == "string" and type(attrs.PictureId) == "number" then
		Builder.showPicture(part, attrs.Picture, attrs.PictureId)
	end
	if ghost then
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.CastShadow = false
		if (prim.transp or 0) < 0.99 then
			part.Transparency = math.max(0.45, prim.transp or 0)
		end
		if opts and opts.tint then
			part.Color = opts.tint
		end
		return part
	end
	if (prim.transp or 0) >= 0.99 then
		part.CastShadow = false
		part.CanQuery = prim.collide ~= false
	end
	if prim.role == "seat" then
		part:AddTag(Builder.Tags.SeatSpot)
		part.CanQuery = false
	elseif prim.role == "bed" then
		part:AddTag(Builder.Tags.BedSpot)
		part.CanQuery = false
	elseif prim.role == "door" then
		part:AddTag(Builder.Tags.DoorLeaf)
		part:SetAttribute("Closed", part.CFrame)
		-- the doorway's own frame in the world: the hinge and the slide are measured in it
		part:SetAttribute("Frame", frame * (prim.frame or CFrame.identity))
		-- villagers path straight through doors (they open them on their way: Services/World)
		pcall(function()
			local modifier = Instance.new("PathfindingModifier")
			modifier.Label = "Door"
			modifier.PassThrough = true
			modifier.Parent = part
		end)
	end
	-- a lamp in one of the town's rooms is lit at every hour (Data/Interiors marks it)
	local room = prim.role == "glow"
		and not (opts and opts.placed)
		and prim.attrs ~= nil
		and (prim.attrs :: any).RoomLight == true
	if room then
		part:AddTag(Builder.Tags.RoomLight)
		part.Material = Enum.Material.Neon
	elseif prim.role == "glow" then
		-- the town's own lamps follow the hour (Services/World); a player's lights are theirs
		part:AddTag(if opts and opts.placed then Builder.Tags.PlacedLight else Builder.Tags.NightLight)
		-- (the material it goes back to when it is put out; a look stays on the part as its
		-- MaterialVariant, worn again once the material is back)
		part:SetAttribute("DayMaterial", base)
	end
	if prim.light then
		local l = prim.light
		-- each kind of lamp by its own numbers (Tuning.Lights, Tuning.RoomLights): a light reaches
		-- across the room it is in ("make lights in general stronger, so they fill up the whole
		-- room"), Roblox's lights no further than Tuning.Lights.MaxRange
		local scale = if opts and opts.plain
			then Tuning.Lights.Placed
			elseif room then Tuning.RoomLights
			else Tuning.Lights.Town
		local reach = math.min(l.range * scale.Range, Tuning.Lights.MaxRange)
		if l.kind == "spot" then
			local spot = Instance.new("SpotLight")
			spot.Face = (Enum.NormalId :: any)[l.face or "Bottom"] or Enum.NormalId.Bottom
			spot.Angle = Tuning.Lights.SpotAngle
			spot.Range = reach
			spot.Brightness = l.brightness * scale.Brightness
			spot.Color = l.color
			spot.Shadows = false
			spot.Enabled = room
			spot.Parent = part
		else
			local point = Instance.new("PointLight")
			point.Range = reach
			point.Brightness = l.brightness * scale.Brightness
			point.Color = l.color
			point.Shadows = false
			point.Enabled = room
			point.Parent = part
		end
	end
	if prim.effect == "fire" then
		local f = Instance.new("Fire")
		f.Size = math.max(1, math.min(prim.size.X, prim.size.Z) * 1.5)
		f.Heat = 4
		f.Parent = part
	elseif prim.effect == "smoke" then
		local s = Instance.new("Smoke")
		s.Size = 1.5
		s.RiseVelocity = 3
		s.Opacity = 0.08
		s.Parent = part
	elseif prim.effect == "sparkles" then
		local s = Instance.new("Sparkles")
		s.Parent = part
	end
	if prim.attrs then
		for k, v in prim.attrs do
			part:SetAttribute(k, v)
		end
	end
	return part
end

-- Pieces ------------------------------------------------------------------------------------------
--
-- A "Piece" primitive (Geometry.piece) is a handful of small shapes that make one thing. On a
-- server that has switched it on (Builder.cutPieces, set by Services/World) each different piece
-- is merged into one mesh the first time it is met, by solid modelling, and every use after that
-- is a copy of it. Merging takes a moment each, so pieces don't hold the town up: a piece that
-- isn't ready is queued, and one worker makes and places them behind the rest of the build.
-- Anywhere else (a client, the specs, the previews), and for a piece whose merge failed or came
-- out the wrong size, the shapes are made as ordinary parts. It looks the same either way.

Builder.cutPieces = false
Builder.Pieces = { cut = 0, failed = 0, placed = 0, waiting = 0 }

local pieceKit: { [string]: BasePart | false } = {}
-- where each mesh's own middle sits in its piece's frame (the merge decides; usually the origin)
local pieceAt: { [string]: CFrame } = {}
type Waiting = { prim: Prim, frame: CFrame, parent: Instance }
local pieceQueue: { Waiting } = {}
local pieceWorker = false

local function upright(cf: CFrame): boolean
	local _, _, _, a, _, _, _, e, _, _, _, k = cf:GetComponents()
	return math.abs(a - 1) < 1e-4 and math.abs(e - 1) < 1e-4 and math.abs(k - 1) < 1e-4
end

local function expandPiece(prim: Prim, frame: CFrame, parent: Instance, opts: Options?, out: { BasePart }?)
	local f = frame * prim.cf
	local subs: { Prim } = prim.parts or {}
	for _, sub in subs do
		local part = makePart(sub, f, opts)
		if prim.collide ~= true then
			part.CanCollide = false
		end
		if prim.name then
			part.Name = prim.name -- a named piece's name goes on every part it is made as
		end
		part.Parent = parent
		if out then
			table.insert(out, part)
		end
	end
end

-- Merges a piece's shapes into one mesh. Yields. The shapes are made where they stand in the
-- piece's own frame, so wherever the merge puts the mesh's middle, that frame is what a copy is
-- placed by (pieceAt). Returns nil when it can't be done or the mesh isn't the size of the
-- piece's box, so the caller falls back to plain parts.
local function cutPiece(prim: Prim): BasePart?
	-- only the boxes and wedges are merged (Geometry.merges); round shapes are placed beside it
	local subs: { Prim } = {}
	local all: { Prim } = prim.parts or {}
	for _, sub in all do
		if Geometry.merges(sub) then
			table.insert(subs, sub)
		end
	end
	local main: BasePart? = nil
	local rest: { BasePart } = {}
	for _, sub in subs do
		local part = makePart(sub, CFrame.identity, nil)
		if not main and sub.shape == "Block" and upright(sub.cf) then
			main = part
		else
			table.insert(rest, part)
		end
	end
	local shape: BasePart? = nil
	local material, look = (Enum.Material :: any)[Geometry.Default], ""
	if main then
		material, look = main.Material, main.MaterialVariant
	end
	if main and #rest == 0 then
		shape = main
		main = nil
	elseif main then
		local ok, result = pcall(function()
			local geometry = game:GetService("GeometryService") :: any
			-- Precise: a frame simplified at a distance would close over the pane inside it
			return geometry:UnionAsync(main, rest, {
				CollisionFidelity = Enum.CollisionFidelity.Box,
				RenderFidelity = Enum.RenderFidelity.Precise,
				SplitApart = false,
			})
		end)
		local made = if ok then (if type(result) == "table" then result[1] else result) else nil
		if typeof(made) == "Instance" and made:IsA("BasePart") then
			shape = made
		end
	end
	if main then
		main:Destroy()
	end
	for _, part in rest do
		part:Destroy()
	end
	if not shape then
		return nil
	end
	-- a sanity check on what came back: standing square, it has to be the size of the box round
	-- the shapes that went in
	if upright(shape.CFrame) then
		local lo, hi = Geometry.bounds(subs)
		local d = shape.Size - (hi - lo)
		if
			math.abs(d.X) > 0.1
			or math.abs(d.Y) > 0.1
			or math.abs(d.Z) > 0.1
			or shape.CFrame.Position.Magnitude > math.max(1, prim.size.Magnitude)
		then
			shape:Destroy()
			return nil
		end
	end
	pieceAt[prim.key or ""] = shape.CFrame
	shape.Name = "Piece"
	shape.Anchored = true
	shape.Material = material
	shape.MaterialVariant = look
	shape.CanCollide = prim.collide == true
	shape.CanTouch = false
	pcall(function()
		local op = shape :: any
		op.UsePartColor = false -- each shape keeps the colour it was drawn in
		op.SmoothingAngle = 0 -- flat facets
	end)
	return shape
end

local function placePiece(template: BasePart, prim: Prim, frame: CFrame, parent: Instance, out: { BasePart }?): BasePart
	local part = template:Clone()
	part.CFrame = frame * prim.cf * (pieceAt[prim.key or ""] or CFrame.identity)
	if prim.name then
		part.Name = prim.name -- (a tree's crown is named Leaf, and sways)
	end
	part.Parent = parent
	Builder.Pieces.placed += 1
	-- the round shapes, as parts of their own beside the mesh
	local f = frame * prim.cf
	local all: { Prim } = prim.parts or {}
	for _, sub in all do
		if not Geometry.merges(sub) then
			local round = makePart(sub, f, nil)
			if prim.collide ~= true then
				round.CanCollide = false
			end
			if prim.name then
				round.Name = prim.name
			end
			round.Parent = parent
			if out then
				table.insert(out, round)
			end
		end
	end
	return part
end

local function workPieces()
	if pieceWorker then
		return
	end
	pieceWorker = true
	task.spawn(function()
		local done = 0
		local at = 1
		while at <= #pieceQueue do
			local job = pieceQueue[at]
			at += 1
			Builder.Pieces.waiting = #pieceQueue - at + 1
			local key = job.prim.key or ""
			local known = pieceKit[key]
			local template: BasePart? = if known then known :: BasePart else nil
			if known == nil then
				template = cutPiece(job.prim)
				pieceKit[key] = template or false
				if template then
					Builder.Pieces.cut += 1
				else
					Builder.Pieces.failed += 1
				end
				task.wait() -- solid modelling isn't to be called in a rush
			end
			-- whatever it was for may have been taken down while it waited
			if job.parent.Parent ~= nil then
				if template then
					placePiece(template, job.prim, job.frame, job.parent)
				else
					expandPiece(job.prim, job.frame, job.parent, nil, nil)
				end
			end
			done += 1
			if done % 60 == 0 then
				task.wait()
			end
		end
		table.clear(pieceQueue)
		Builder.Pieces.waiting = 0
		pieceWorker = false
	end)
end

-- Merges, ahead of time, every different piece in these lists of prims (Services/World does it
-- for the whole town before building it, so no building stands without its windows while its
-- pieces are merged one by one). Yields; spaces the merges a frame apart, as solid modelling
-- asks. Stops after `budget` seconds: whatever is left is built from plain parts, so a slow
-- server still opens in time. Returns how many were merged, failed and left.
--
-- `weights[i]` is how many times list i is used (a model placed forty times weighs forty), so the
-- pieces seen most are merged first. What the budget leaves is merged later, one at a time, as
-- the town is built (the queue above): the server opens sooner, and those details arrive a
-- moment after their buildings instead of the whole town waiting for them.
function Builder.preparePieces(lists: { { Prim } }, budget: number?, weights: { number }?): (number, number, number)
	if not Builder.cutPieces then
		return 0, 0, 0
	end
	local todo: { Prim } = {}
	local seen: { [string]: number } = {}
	for i, list in lists do
		local w = if weights then weights[i] or 1 else 1
		for _, prim in list do
			local key = prim.key
			if prim.shape == "Piece" and key and pieceKit[key] == nil then
				if seen[key] == nil then
					seen[key] = 0
					table.insert(todo, prim)
				end
				seen[key] += w
			end
		end
	end
	table.sort(todo, function(a, b)
		return seen[a.key or ""] > seen[b.key or ""]
	end)
	local stop = os.clock() + (budget or 60)
	local cut, failed, left = 0, 0, 0
	for _, prim in todo do
		local key = prim.key or ""
		if os.clock() > stop then
			left += 1 -- still nil: merged later, when something that uses it is built
		else
			local template = cutPiece(prim)
			pieceKit[key] = template or false
			if template then
				cut += 1
			else
				failed += 1
			end
			task.wait()
		end
	end
	Builder.Pieces.cut += cut
	Builder.Pieces.failed += failed
	return cut, failed, left
end

-- Makes parts for prims, placed by `frame`, under `parent`. A piece that is still to be merged
-- (see above) arrives a little later and is not in the list returned.
function Builder.instantiate(prims: { Prim }, parent: Instance, frame: CFrame?, opts: Options?): { BasePart }
	local f = frame or CFrame.identity
	local out = table.create(#prims)
	for _, prim in prims do
		if prim.shape == "Piece" then
			local cutting = Builder.cutPieces and not (opts and (opts.ghost or opts.plain))
			local known = if cutting then pieceKit[prim.key or ""] else false
			if known == nil then
				table.insert(pieceQueue, { prim = prim, frame = f, parent = parent })
				Builder.Pieces.waiting = #pieceQueue
				workPieces()
			elseif known then
				table.insert(out, placePiece(known :: BasePart, prim, f, parent, out))
			else
				expandPiece(prim, f, parent, opts, out)
			end
		else
			local part = makePart(prim, f, opts)
			part.Parent = parent
			table.insert(out, part)
		end
	end
	return out
end

-- What a save painted in a retired finish (flat paint, plastic) is drawn in now: the textured
-- finish that took its place (Palette.drawn), on every shape and on the shapes in a piece.
local function retire(prims: { Prim }): { Prim }
	for _, p in prims do
		local now = Palette.drawn(p.mat)
		if now ~= p.mat then
			if p.key and string.sub(p.key, 1, #p.mat) == p.mat then
				p.key = now .. string.sub(p.key, #p.mat + 1)
			end
			p.mat = now
		end
		if p.parts then
			retire(p.parts)
		end
	end
	return prims
end

local function primsOf(plan: Plan.PlanData, kind: string, key: string): { Prim }?
	if kind == "walls" then
		local w = plan.walls[key]
		if not w then
			return nil
		end
		local r1, r2 = Shapes.wallReach(plan, key)
		return Shapes.wall(w, Plan.openings(plan, key), r1, r2)
	elseif kind == "floors" then
		local f = plan.floors[key]
		if not f then
			return nil
		end
		-- the full height walls of the storey below, where they run under this floor
		local under = {}
		if f.lv > 0 then
			for wallKey, w in plan.walls do
				local style = Plan.WallStyles[w.style]
				if w.lv == f.lv - 1 and style and style.full and (w.x1 == w.x2 or w.z1 == w.z2) then
					local r1, r2 = Shapes.wallReach(plan, wallKey)
					local e1, e2 = math.max(r1[1], r1[2]), math.max(r2[1], r2[2])
					local t = style.thick / 2
					if w.x1 == w.x2 then
						local s = if w.z2 >= w.z1 then 1 else -1
						local za, zb = w.z1 - s * e1, w.z2 + s * e2
						table.insert(under, { w.x1 - t, math.min(za, zb), w.x1 + t, math.max(za, zb) })
					else
						local s = if w.x2 >= w.x1 then 1 else -1
						local xa, xb = w.x1 - s * e1, w.x2 + s * e2
						table.insert(under, { math.min(xa, xb), w.z1 - t, math.max(xa, xb), w.z1 + t })
					end
				end
			end
		end
		-- (a ground floor is drawn with the ground floors it meets: Shapes.groundFloor)
		local prims = if f.lv == 0
			then Shapes.groundFloor(plan, key, Plan.holes(plan, f.lv))
			else Shapes.floor(f, Plan.holes(plan, f.lv), under)
		if f.lv == Basement.Level then
			Geometry.append(prims, Basement.lining(plan, key))
		end
		return prims
	elseif kind == "roofs" then
		-- (fitted to the roofs it meets on its floor: Shapes.roofIn)
		return Shapes.roofIn(plan, key)
	elseif kind == "waters" then
		-- (water: its rim or bank and the basin's lining; the water itself is terrain in the game)
		local w = plan.waters and plan.waters[key]
		if not w then
			return nil
		end
		return Water.prims(w)
	elseif kind == "items" then
		local item = plan.items[key]
		if not item then
			return nil
		end
		local def = Catalog.get(item.id)
		local frame = Plan.itemFrame(plan, item)
		if not def or not frame then
			return nil
		end
		local prims = Catalog.prims(def, item.c1, item.c2, item.img, item.m1, item.m2)
		-- only the piece's body is solid, not its little parts (Build/Solid: "villagers and the
		-- player can sometimes get stuck in objects")
		prims = Solid.apply(def, prims)
		-- stretched with the Stretch pass: every part scaled from the piece's pivot (Build/Stretch)
		prims = Stretch.prims(prims, Stretch.of(item))
		for _, p in prims do
			if p.role == "door" then
				p.frame = frame
			end
		end
		return Geometry.transform(prims, frame)
	end
	return nil
end

-- The primitives for one plan object, in the plot's frame.
function Builder.primsFor(plan: Plan.PlanData, kind: string, key: string): { Prim }?
	local prims = primsOf(plan, kind, key)
	return if prims then retire(prims) else nil
end

-- Where a door leaf stands when it's open: swung round its hinge (HingeX along its doorway),
-- slid along the wall (Slide) or lifted (Lift). The hinge is the doorway's own, wherever the
-- plot and the wall put it.
function Builder.doorOpen(leaf: BasePart): CFrame?
	local closed = leaf:GetAttribute("Closed")
	local frame = leaf:GetAttribute("Frame")
	if typeof(closed) ~= "CFrame" or typeof(frame) ~= "CFrame" then
		return nil
	end
	local slide = leaf:GetAttribute("Slide")
	local lift = leaf:GetAttribute("Lift")
	if type(slide) == "number" then
		return closed + frame.RightVector * slide
	elseif type(lift) == "number" then
		return closed + Vector3.new(0, lift, 0)
	end
	local hx = leaf:GetAttribute("HingeX")
	local hinge: number = if type(hx) == "number" then hx else 0
	local angle = if hinge < 0 then -math.rad(95) else math.rad(95)
	local pivot = frame * CFrame.new(hinge, 0, 0)
	return pivot * CFrame.Angles(0, angle, 0) * pivot:Inverse() * closed
end

function Builder.modelName(kind: string, key: string): string
	return kind .. "_" .. key
end

-- Builds (or rebuilds) one object's Model under `folder`. Returns nil when the object is gone.
function Builder.render(plan: Plan.PlanData, kind: string, key: string, folder: Instance, plotFrame: CFrame): Model?
	local name = Builder.modelName(kind, key)
	local old = folder:FindFirstChild(name)
	if old then
		old:Destroy()
	end
	local prims = Builder.primsFor(plan, kind, key)
	if not prims then
		return nil
	end
	local model = Instance.new("Model")
	model.Name = name
	model:SetAttribute("BuildKind", kind)
	model:SetAttribute("BuildKey", key)
	local obj = (plan :: any)[kind][key]
	if obj and obj.lv ~= nil then
		model:SetAttribute("Level", obj.lv)
	end
	if kind == "items" then
		model:SetAttribute("ItemId", obj.id)
	end
	-- what players build is drawn from plain parts, as the piece looked while they held it (the
	-- user: "alot of the objects seem to have its pieces wrong after putting them down in build
	-- mode"); merging is for the town's own models, which never change. Its lights are the
	-- player's own (Sim/Lights): on at every hour, not switched by the clock.
	Builder.instantiate(prims, model, plotFrame, { plain = true, placed = true })
	model.Parent = folder
	return model
end

-- Renders the whole plan (used when a plot loads).
function Builder.renderAll(plan: Plan.PlanData, folder: Instance, plotFrame: CFrame)
	for _, kind in Plan.Kinds do
		for key in (plan :: any)[kind] or {} do -- (a plan from before there was water has none)
			Builder.render(plan, kind, key, folder, plotFrame)
		end
	end
end

-- Re-renders what a change touched.
function Builder.update(
	plan: Plan.PlanData,
	affected: { [string]: { [string]: boolean } },
	folder: Instance,
	plotFrame: CFrame
)
	for kind, keys in affected do
		for key in keys do
			Builder.render(plan, kind, key, folder, plotFrame)
		end
	end
end

return Builder
