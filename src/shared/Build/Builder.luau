--!strict
-- Turns primitives into Parts, and a plan's objects into Models.
-- Used by the server for the real builds and by the client for see-through placement ghosts.

local Geometry = require(script.Parent.Geometry)
local Plan = require(script.Parent.Plan)
local Shapes = require(script.Parent.Shapes)
local Catalog = require(script.Parent.Catalog)
local Textures = require(script.Parent.Parent.Data.Textures)

type Prim = Geometry.Prim

local Builder = {}

Builder.Tags = {
	NightLight = "NightLight", -- parts that glow and light up after dark
	DoorLeaf = "DoorLeaf",
	SeatSpot = "SeatSpot",
	BedSpot = "BedSpot",
}

export type Options = {
	ghost: boolean?, -- see-through, no collisions, no lights (placement previews)
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
		local p = Instance.new("Part")
		if prim.shape == "Cylinder" then
			p.Shape = Enum.PartType.Cylinder
		elseif prim.shape == "Ball" then
			p.Shape = Enum.PartType.Ball
		end
		part = p
	end
	part.Size = prim.size
	part.CFrame = frame * prim.cf
	part.Anchored = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	local mat = (Enum.Material :: any)[prim.mat]
	part.Material = mat or Enum.Material.SmoothPlastic
	part.Color = Textures.tint(prim.mat, prim.color)
	part.Transparency = prim.transp or 0
	part.CanCollide = prim.collide ~= false
	if prim.name then
		part.Name = prim.name
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
		part:SetAttribute("Frame", frame)
		-- villagers path straight through doors (they open them on their way: Services/World)
		pcall(function()
			local modifier = Instance.new("PathfindingModifier")
			modifier.Label = "Door"
			modifier.PassThrough = true
			modifier.Parent = part
		end)
	elseif prim.role == "glow" then
		part:AddTag(Builder.Tags.NightLight)
		part:SetAttribute("DayMaterial", prim.mat)
	end
	if prim.light then
		local l = prim.light
		if l.kind == "spot" then
			local spot = Instance.new("SpotLight")
			spot.Face = (Enum.NormalId :: any)[l.face or "Bottom"] or Enum.NormalId.Bottom
			spot.Angle = 80
			spot.Range = l.range
			spot.Brightness = l.brightness
			spot.Color = l.color
			spot.Shadows = false
			spot.Enabled = false
			spot.Parent = part
		else
			local point = Instance.new("PointLight")
			point.Range = l.range
			point.Brightness = l.brightness
			point.Color = l.color
			point.Shadows = false
			point.Enabled = false
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

-- Makes parts for prims, placed by `frame`, under `parent`.
function Builder.instantiate(prims: { Prim }, parent: Instance, frame: CFrame?, opts: Options?): { BasePart }
	local f = frame or CFrame.identity
	local out = table.create(#prims)
	for _, prim in prims do
		local part = makePart(prim, f, opts)
		part.Parent = parent
		table.insert(out, part)
	end
	return out
end

-- The primitives for one plan object, in the plot's frame.
function Builder.primsFor(plan: Plan.PlanData, kind: string, key: string): { Prim }?
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
		return Shapes.floor(f, Plan.holes(plan, f.lv))
	elseif kind == "roofs" then
		local r = plan.roofs[key]
		if not r then
			return nil
		end
		return Shapes.roof(r)
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
		return Geometry.transform(Catalog.prims(def, item.c1, item.c2), frame)
	end
	return nil
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
	Builder.instantiate(prims, model, plotFrame)
	model.Parent = folder
	return model
end

-- Renders the whole plan (used when a plot loads).
function Builder.renderAll(plan: Plan.PlanData, folder: Instance, plotFrame: CFrame)
	for _, kind in Plan.Kinds do
		for key in (plan :: any)[kind] do
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
