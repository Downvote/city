--!strict
-- The game's one low poly style. The user: "currently, the models are simply shapes put together
-- to form objects, like the trees. could you reference low poly models online and replicate them
-- in a distinct shared style across all objects, or use the roblox library to replace models?"
--
-- Low poly packs share a look: flat shaded facets, chunky polygonal forms and no smooth curves.
-- Trunks and poles are prisms, crowns and rocks are faceted lumps, pines are stacked cones. This
-- module makes that kit of shapes with Roblox's own solid modelling when the server starts, once
-- each, and the Builder then uses a copy wherever a model asks for a ball, a cylinder or a cone.
-- So every model in the game, the map's and the catalog's alike, is drawn in the same facets
-- without anyone redrawing them, and a model costs no more parts than before.
--
--   Gem    a ball: a cube with every edge cut at 45 degrees, eighteen faces
--   Prism  a cylinder: eight sides, along its X axis as Roblox's cylinders are
--   Disc   a wide cylinder (a pond, a plaza): sixteen sides, so it still reads as round
--   Cone   eight sides, point up (+Y)
--
-- Every shape fills the unit box round its own middle, so setting a copy's Size stretches it to
-- whatever the model asked for. If solid modelling isn't allowed or fails, there is no kit and
-- the Builder falls back to Roblox's smooth ball and cylinder.

local LowPoly = {}

LowPoly.FolderName = "LowPolyKit"
LowPoly.Shapes = { "Gem", "Prism", "Disc", "Cone" }

-- A cylinder at least this wide is drawn as a Disc.
LowPoly.DiscFrom = 9

local function block(cf: CFrame, size: Vector3): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.Size = size
	p.CFrame = cf
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = Enum.Material.SmoothPlastic
	p.Color = Color3.new(1, 1, 1)
	return p
end

local function wedge(cf: CFrame, size: Vector3): WedgePart
	local p = Instance.new("WedgePart")
	p.Anchored = true
	p.Size = size
	p.CFrame = cf
	p.Material = Enum.Material.SmoothPlastic
	p.Color = Color3.new(1, 1, 1)
	return p
end

-- What each shape is cut from: the unit cube, and the pieces it is intersected with.
local function pieces(name: string): { BasePart }
	local out: { BasePart } = {}
	local unit = Vector3.new(1, 1, 1)
	if name == "Gem" then
		local q = math.rad(45)
		table.insert(out, block(CFrame.Angles(q, 0, 0), unit))
		table.insert(out, block(CFrame.Angles(0, q, 0), unit))
		table.insert(out, block(CFrame.Angles(0, 0, q), unit))
	elseif name == "Prism" then
		table.insert(out, block(CFrame.Angles(math.rad(45), 0, 0), unit))
	elseif name == "Disc" then
		for k = 1, 3 do
			table.insert(out, block(CFrame.Angles(math.rad(k * 22.5), 0, 0), unit))
		end
	elseif name == "Cone" then
		-- eight wedges round the middle, each one's slope running from the base's edge to the tip
		for k = 0, 7 do
			table.insert(
				out,
				wedge(CFrame.Angles(0, math.rad(k * 45), 0) * CFrame.new(0, 0.5, 0), Vector3.new(4, 2, 1))
			)
		end
	end
	return out
end

-- Cuts one shape. Returns it, or nil and why not.
local function cut(name: string): (BasePart?, string?)
	local main = block(CFrame.identity, Vector3.new(1, 1, 1))
	local others = pieces(name)
	local ok, result = pcall(function()
		local geometry = game:GetService("GeometryService") :: any
		-- (every shape's hull, which is the shape itself: they are all convex. A gem's used to be
		-- its box, and a gem is turned a different way at every spot (LowPoly.turn), so a solid
		-- ball or rock had corners nobody could see sticking out of it, the user: "collission
		-- boxes that arent part of the mesh but are invisible")
		return geometry:IntersectAsync(main, others, {
			CollisionFidelity = Enum.CollisionFidelity.Hull,
			RenderFidelity = Enum.RenderFidelity.Precise,
			SplitApart = false,
		})
	end)
	main:Destroy()
	for _, o in others do
		o:Destroy()
	end
	if not ok then
		return nil, tostring(result)
	end
	local shape = if type(result) == "table" then result[1] else result
	if typeof(shape) ~= "Instance" or not shape:IsA("BasePart") then
		return nil, "nothing came back"
	end
	-- every shape should fill the unit box; anything else would stretch wrongly
	local size = shape.Size
	if math.abs(size.X - 1) > 0.05 or math.abs(size.Y - 1) > 0.05 or math.abs(size.Z - 1) > 0.05 then
		shape:Destroy()
		return nil, "came out the wrong size: " .. tostring(size)
	end
	shape.Name = name
	shape.Anchored = true
	shape.CFrame = CFrame.identity
	shape.Material = Enum.Material.SmoothPlastic
	pcall(function()
		local op = shape :: any
		op.UsePartColor = true -- so each copy takes its own colour
		op.SmoothingAngle = 0 -- flat facets
	end)
	return shape, nil
end

-- Makes the kit (server). Returns a folder holding the shapes that worked, and what went wrong
-- with the rest. An empty folder means no kit: the Builder then keeps Roblox's own shapes.
function LowPoly.make(): (Folder, { string })
	local folder = Instance.new("Folder")
	folder.Name = LowPoly.FolderName
	local problems = {}
	for _, name in LowPoly.Shapes do
		local shape, why = cut(name)
		if shape then
			shape.Parent = folder
		else
			table.insert(problems, name .. ": " .. tostring(why))
		end
	end
	return folder, problems
end

-- The kit shape a primitive is drawn with, by its shape and size (nil for boxes and wedges).
function LowPoly.shapeFor(shape: string, size: Vector3): string?
	if shape == "Ball" then
		return "Gem"
	elseif shape == "Cylinder" then
		return if math.max(size.Y, size.Z) >= LowPoly.DiscFrom then "Disc" else "Prism"
	elseif shape == "Cone" then
		return "Cone"
	end
	return nil
end

-- A turn for a gem, different for every spot, so a clump of them (a tree's crown, a bush, a
-- cloud) doesn't sit in rows. A ball looks the same from every side, so any turn is right.
function LowPoly.turn(at: Vector3): CFrame
	local h = math.abs(at.X * 12.9898 + at.Y * 78.233 + at.Z * 37.719)
	local a = (h % 1) * math.pi * 2
	local b = ((h * 1.618) % 1) * math.pi * 2
	local c = ((h * 2.414) % 1) * math.pi * 2
	return CFrame.Angles(a, b, c)
end

return LowPoly
