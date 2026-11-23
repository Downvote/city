-- Build mode on the client: the tools (walls, rooms, floors, roofs, furniture, paint, select,
-- delete), snapping to the grid, see-through ghosts of what you are about to place, picking
-- things under the pointer, and sending the change to the server. BuildUI draws the buttons.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Tuning = require(Shared.Config.Tuning)
local Plan = require(Shared.Build.Plan)
local Shapes = require(Shared.Build.Shapes)
local Builder = require(Shared.Build.Builder)
local Catalog = require(Shared.Build.Catalog)
local Geometry = require(Shared.Build.Geometry)
local Palette = require(Shared.Data.Palette)
local Town = require(Shared.Data.Town)
local Presets = require(Shared.Data.Presets)
local Remotes = require(Shared.Net.Remotes)
local Text = require(Shared.Util.Text)

local State = require(script.Parent.Parent.Controllers.State)
local Toasts = require(script.Parent.Parent.UI.Toasts)
local Kit = require(script.Parent.Parent.UI.Kit)
local BuildCamera = require(script.Parent.BuildCamera)

local BuildMode = {}

local player = Players.LocalPlayer
local P = Tuning.Plot

local changedEvent = Instance.new("BindableEvent")
BuildMode.Changed = changedEvent.Event

-- state -------------------------------------------------------------------------------------------

local s = {
	active = false,
	tool = "select",
	level = 0,
	wallStyle = "wall",
	wallMode = "line", -- "line" or "room"
	wallPaint = {
		a = { c = Palette.Defaults.WallOut.c, m = Palette.Defaults.WallOut.m },
		b = { c = Palette.Defaults.WallIn.c, m = Palette.Defaults.WallIn.m },
	},
	floorPaint = { c = Palette.Defaults.Floor.c, m = Palette.Defaults.Floor.m },
	roof = {
		style = "gable",
		rise = 6,
		over = 1,
		dir = 0,
		c = Palette.Defaults.Roof.c,
		m = Palette.Defaults.Roof.m,
		c2 = Palette.Defaults.RoofGable.c,
		m2 = Palette.Defaults.RoofGable.m,
	},
	paint = { c = "F2E8D5", m = "SmoothPlastic", slot = "main", pick = false },
	placing = nil :: any, -- { id, r, c1, c2, moveKey }
	selected = nil :: any, -- { kind, key }
	snap = true,
	roofsHidden = true,
	seeThrough = false,
	hint = "",
}
BuildMode.state = s

local plotIndex: number? = nil
local plotFrame = CFrame.identity
local buildFolder: Instance? = nil
local ghostFolder: Folder? = nil
local gridFolder: Folder? = nil
-- the cursor label and the selection highlight live in their own folder: the grid and the
-- ghost folders are cleared all the time, and clearing them used to destroy these with them
local markerFolder: Folder? = nil
local marker: Part? = nil
local label: BillboardGui? = nil
local highlight: Highlight? = nil
local connections: { RBXScriptConnection } = {}
local hidden: { [BasePart]: boolean } = {}
local rectStart: Vector3? = nil
local wallStart: Vector3? = nil
local pressPoint: Vector3? = nil
local lastGhostKey = ""
local pointer: Vector2? = nil
local pointerIsScreen = false
local pending = false
local candidate: any = nil -- what a click would do right now: { requests, valid, reason }
local pressedInWorld = false

local function changed(what: string?)
	changedEvent:Fire(what or "state")
end

-- helpers -----------------------------------------------------------------------------------------

local function snapAxis(v: number, lo: number, hi: number): number
	local g = P.WallSnap
	return math.clamp(math.floor(v / g + 0.5) * g, lo, hi)
end

-- Snaps to the wall grid, kept inside the land the player owns.
local function snapX(v: number): number
	local x1, _, x2 = Plan.bounds(State.plan)
	return snapAxis(v, x1, x2)
end

local function snapZ(v: number): number
	local _, z1, _, z2 = Plan.bounds(State.plan)
	return snapAxis(v, z1, z2)
end

local function snapItem(v: number): number
	local g = if s.snap then P.ItemSnap else 0.25
	return math.floor(v / g + 0.5) * g
end

local function isTouch(): boolean
	return UserInputService.TouchEnabled and not UserInputService.MouseEnabled
end

local function currentRay(): Ray?
	local cam = workspace.CurrentCamera
	if not cam then
		return nil
	end
	local pos = pointer
	if not pos then
		if isTouch() then
			return nil
		end
		pos = UserInputService:GetMouseLocation()
		return cam:ViewportPointToRay(pos.X, pos.Y)
	end
	if pointerIsScreen then
		return cam:ScreenPointToRay(pos.X, pos.Y)
	end
	return cam:ViewportPointToRay(pos.X, pos.Y)
end

-- Where the pointer meets the floor plane of the current level, in plot space.
local function planePoint(height: number?): Vector3?
	local ray = currentRay()
	if not ray then
		return nil
	end
	local h = height or Plan.levelBase(s.level)
	local origin = plotFrame:PointToObjectSpace(ray.Origin)
	local dir = plotFrame:VectorToObjectSpace(ray.Direction)
	if math.abs(dir.Y) < 1e-4 then
		return nil
	end
	local t = (h - origin.Y) / dir.Y
	if t < 0 then
		return nil
	end
	return origin + dir * t
end

local function raycast(): RaycastResult?
	local ray = currentRay()
	if not ray then
		return nil
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local ignore = {}
	if player.Character then
		table.insert(ignore, player.Character)
	end
	if ghostFolder then
		table.insert(ignore, ghostFolder)
	end
	if gridFolder then
		table.insert(ignore, gridFolder)
	end
	if markerFolder then
		table.insert(ignore, markerFolder)
	end
	params.FilterDescendantsInstances = ignore
	return workspace:Raycast(ray.Origin, ray.Direction * 600, params)
end

-- The plan object a part belongs to.
local function objectOf(inst: Instance?): (string?, string?, Model?)
	local folder = buildFolder
	while inst and folder and inst.Parent ~= folder do
		inst = inst.Parent
	end
	if inst and inst:IsA("Model") then
		local kind = inst:GetAttribute("BuildKind")
		local key = inst:GetAttribute("BuildKey")
		if type(kind) == "string" and type(key) == "string" then
			return kind, key, inst
		end
	end
	return nil, nil, nil
end

local function modelOf(kind: string, key: string): Model?
	if not buildFolder then
		return nil
	end
	return buildFolder:FindFirstChild(Builder.modelName(kind, key)) :: Model?
end

local function clearGhost()
	if ghostFolder then
		ghostFolder:ClearAllChildren()
	end
	lastGhostKey = ""
end

local function showGhost(key: string, prims: { Geometry.Prim }, valid: boolean)
	if not ghostFolder then
		return
	end
	if key == lastGhostKey then
		return
	end
	lastGhostKey = key
	ghostFolder:ClearAllChildren()
	Builder.instantiate(prims, ghostFolder, plotFrame, {
		ghost = true,
		tint = if valid then nil else Color3.fromRGB(235, 80, 80),
	})
end

local function setLabel(text: string?, at: Vector3?)
	if not label or not marker then
		return
	end
	if text and at then
		marker.CFrame = plotFrame * CFrame.new(at)
		label.Enabled = true
		local t = label:FindFirstChild("Text")
		if t and t:IsA("TextLabel") then
			t.Text = text
		end
	else
		label.Enabled = false
	end
end

local function setHighlight(model: Instance?, color: Color3?)
	if not highlight then
		return
	end
	highlight.Adornee = model
	highlight.Enabled = model ~= nil
	if color then
		highlight.OutlineColor = color
		highlight.FillColor = color
	end
end

local function coins(): number
	return State.data.coins or 0
end

local function costText(cost: number): string
	if cost < 0 then
		return "+" .. Text.commas(-cost)
	end
	return Text.commas(cost)
end

-- what a click does --------------------------------------------------------------------------------

local function newWall(a: Vector3, b: Vector3): any
	local style = s.wallStyle
	local paintA = s.wallPaint.a
	local paintB = s.wallPaint.b
	if style == "hedge" then
		paintA = { c = Palette.Defaults.Hedge.c, m = Palette.Defaults.Hedge.m }
		paintB = paintA
	elseif style == "stone" then
		paintA = { c = Palette.Defaults.Stone.c, m = Palette.Defaults.Stone.m }
		paintB = paintA
	elseif style == "fence" or style == "railing" then
		paintA = { c = Palette.Defaults.Fence.c, m = Palette.Defaults.Fence.m }
		paintB = paintA
	elseif style == "glass" then
		paintA = { c = "45454A", m = "Metal" }
		paintB = paintA
	end
	return {
		x1 = a.X,
		z1 = a.Z,
		x2 = b.X,
		z2 = b.Z,
		lv = s.level,
		style = style,
		a = table.clone(paintA),
		b = table.clone(paintB),
	}
end

local function rectOf(a: Vector3, b: Vector3): (number, number, number, number)
	return math.min(a.X, b.X), math.min(a.Z, b.Z), math.max(a.X, b.X), math.max(a.Z, b.Z)
end

local function hasWall(w: any): boolean
	for _, o in State.plan.walls do
		if o.lv == w.lv then
			if
				(o.x1 == w.x1 and o.z1 == w.z1 and o.x2 == w.x2 and o.z2 == w.z2)
				or (o.x1 == w.x2 and o.z1 == w.z2 and o.x2 == w.x1 and o.z2 == w.z1)
			then
				return true
			end
		end
	end
	return false
end

local function wallTool()
	local p = planePoint()
	if not p then
		clearGhost()
		setLabel(nil)
		candidate = nil
		return
	end
	local g = Vector3.new(snapX(p.X), Plan.levelBase(s.level), snapZ(p.Z))
	if s.wallMode == "room" then
		if not rectStart then
			showGhost("dot" .. tostring(g), {
				Geometry.box(
					CFrame.new(g + Vector3.new(0, 0.5, 0)),
					Vector3.new(0.8, 1, 0.8),
					Color3.fromRGB(255, 212, 92)
				),
			}, true)
			setLabel("Click a corner", g + Vector3.new(0, 3, 0))
			candidate = nil
			return
		end
		local x1, z1, x2, z2 = rectOf(rectStart, g)
		if x2 - x1 < P.WallSnap or z2 - z1 < P.WallSnap then
			clearGhost()
			setLabel("Make it bigger", g + Vector3.new(0, 3, 0))
			candidate = nil
			return
		end
		local walls = {
			newWall(Vector3.new(x1, 0, z1), Vector3.new(x2, 0, z1)),
			newWall(Vector3.new(x2, 0, z1), Vector3.new(x2, 0, z2)),
			newWall(Vector3.new(x2, 0, z2), Vector3.new(x1, 0, z2)),
			newWall(Vector3.new(x1, 0, z2), Vector3.new(x1, 0, z1)),
		}
		local requests = {}
		local prims = {}
		local cost = 0
		local valid, reason = true, nil
		for _, w in walls do
			local ok, err = Plan.validate(State.plan, "walls", w)
			if not ok then
				valid, reason = false, err
			end
			if not hasWall(w) then
				table.insert(requests, { type = "add", kind = "walls", obj = w })
				cost += Plan.cost("walls", w)
				Geometry.append(prims, Shapes.wall(w, {}, P.WallThickness / 2, P.WallThickness / 2))
			end
		end
		if s.wallStyle == "wall" then
			local f = { x1 = x1, z1 = z1, x2 = x2, z2 = z2, lv = s.level, c = s.floorPaint.c, m = s.floorPaint.m }
			if Plan.validate(State.plan, "floors", f) then
				table.insert(requests, { type = "add", kind = "floors", obj = f })
				cost += Plan.cost("floors", f)
				Geometry.append(prims, Shapes.floor(f, Plan.holes(State.plan, s.level)))
			end
		end
		if cost > coins() then
			valid, reason = false, "not enough coins"
		end
		showGhost(string.format("room%d,%d,%d,%d,%s", x1, z1, x2, z2, tostring(valid)), prims, valid)
		setLabel(
			string.format("%d x %d   %s", x2 - x1, z2 - z1, if valid then costText(cost) else reason),
			g + Vector3.new(0, 4, 0)
		)
		candidate = { requests = requests, valid = valid and #requests > 0, reason = reason }
		return
	end
	if not wallStart then
		showGhost("dot" .. tostring(g), {
			Geometry.box(
				CFrame.new(g + Vector3.new(0, 0.5, 0)),
				Vector3.new(0.8, 1, 0.8),
				Color3.fromRGB(255, 212, 92)
			),
		}, true)
		setLabel(nil)
		candidate = nil
		return
	end
	local w = newWall(wallStart, g)
	local len = Plan.wallLength(w)
	if len < 0.01 then
		clearGhost()
		setLabel(nil)
		candidate = nil
		return
	end
	local valid, reason = Plan.validate(State.plan, "walls", w)
	if valid and hasWall(w) then
		valid, reason = false, "there's already a wall there"
	end
	local cost = Plan.cost("walls", w)
	if valid and cost > coins() then
		valid, reason = false, "not enough coins"
	end
	showGhost(string.format("w%s|%s|%s", tostring(wallStart), tostring(g), tostring(valid)), Shapes.wall(w, {}), valid)
	local mid = (wallStart + g) / 2 + Vector3.new(0, 4, 0)
	setLabel(string.format("%.0f studs   %s", len, if valid then costText(cost) else reason or ""), mid)
	candidate = { requests = { { type = "add", kind = "walls", obj = w } }, valid = valid, reason = reason, chain = g }
end

local function rectTool(kind: string)
	local p = planePoint()
	if not p then
		clearGhost()
		setLabel(nil)
		candidate = nil
		return
	end
	local g = Vector3.new(snapX(p.X), Plan.levelBase(s.level), snapZ(p.Z))
	if not rectStart then
		showGhost("dot" .. tostring(g), {
			Geometry.box(
				CFrame.new(g + Vector3.new(0, 0.3, 0)),
				Vector3.new(P.WallSnap, 0.4, P.WallSnap),
				Color3.fromRGB(255, 212, 92)
			),
		}, true)
		setLabel(if kind == "floors" then "Click a corner" else "Click a corner of the house", g + Vector3.new(0, 3, 0))
		candidate = nil
		return
	end
	local x1, z1, x2, z2 = rectOf(rectStart, g)
	if x2 - x1 < P.WallSnap then
		x2 = x1 + P.WallSnap
	end
	if z2 - z1 < P.WallSnap then
		z2 = z1 + P.WallSnap
	end
	local obj, prims
	if kind == "floors" then
		obj = { x1 = x1, z1 = z1, x2 = x2, z2 = z2, lv = s.level, c = s.floorPaint.c, m = s.floorPaint.m }
		prims = Shapes.floor(obj, Plan.holes(State.plan, s.level))
	else
		local r = s.roof
		obj = {
			x1 = x1,
			z1 = z1,
			x2 = x2,
			z2 = z2,
			lv = s.level,
			style = r.style,
			rise = r.rise,
			dir = r.dir,
			over = r.over,
			c = r.c,
			m = r.m,
			c2 = r.c2,
			m2 = r.m2,
		}
		prims = Shapes.roof(obj)
	end
	local valid, reason = Plan.validate(State.plan, kind, obj)
	local cost = Plan.cost(kind, obj)
	if valid and cost > coins() then
		valid, reason = false, "not enough coins"
	end
	showGhost(
		string.format(
			"%s%d,%d,%d,%d,%s,%s",
			kind,
			x1,
			z1,
			x2,
			z2,
			tostring(valid),
			game:GetService("HttpService"):JSONEncode(s.roof)
		),
		prims,
		valid
	)
	setLabel(
		string.format("%d x %d   %s", x2 - x1, z2 - z1, if valid then costText(cost) else reason or ""),
		g + Vector3.new(0, 4, 0)
	)
	candidate = { requests = { { type = "add", kind = kind, obj = obj } }, valid = valid, reason = reason }
end

-- Works out where the item being placed would go.
local function placeCandidate(): (any?, string?)
	local pl = s.placing
	if not pl then
		return nil, nil
	end
	local def = Catalog.get(pl.id)
	if not def then
		return nil, nil
	end
	local hit = raycast()
	if def.place == "opening" or def.place == "wall" then
		if not hit then
			return nil, "point at a wall"
		end
		local kind, key = objectOf(hit.Instance)
		if kind ~= "walls" or not key then
			return nil, "point at a wall"
		end
		local w = State.plan.walls[key]
		if not w then
			return nil, nil
		end
		if w.style ~= "wall" then
			return nil, "only plain walls take this"
		end
		local local3 = plotFrame:PointToObjectSpace(hit.Position)
		local d = Plan.wallDir(w)
		local n = Plan.wallNormal(w)
		local t = (local3 - Vector3.new(w.x1, local3.Y, w.z1)):Dot(d)
		t = math.floor(t * 2 + 0.5) / 2
		local normal = plotFrame:VectorToObjectSpace(hit.Normal)
		local side = if normal:Dot(n) >= 0 then "a" else "b"
		local bottom = Plan.wallSpan(w.style, w.lv)
		local y
		if def.place == "opening" then
			y = Plan.openingY(w, (def.opening :: any).sill)
		else
			y = math.floor((local3.Y - bottom - def.size.Y / 2) * 2 + 0.5) / 2
			y = math.max(0, y)
		end
		return {
			id = pl.id,
			x = 0,
			y = y,
			z = 0,
			r = 0,
			lv = w.lv,
			wall = key,
			t = t,
			side = side,
			c1 = pl.c1,
			c2 = pl.c2,
		},
			nil
	end
	-- free standing: stand on whatever is under the pointer, or on the floor plane
	local base = if s.level == 0 then 0 else Plan.levelBase(s.level)
	local top = Plan.levelTop(s.level)
	local pos: Vector3?
	if hit then
		local l = plotFrame:PointToObjectSpace(hit.Position)
		local onLevel = l.Y >= base - 0.6 and l.Y <= top - 0.5
		local hitKind, _, hitModel = objectOf(hit.Instance)
		if hitKind == "items" and hitModel and def.place ~= "surface" then
			onLevel = false -- only small things stack on furniture
		end
		if hitKind == "walls" or hitKind == "roofs" then
			onLevel = false
		end
		if onLevel and hit.Normal.Y > 0.7 then
			pos = l
		end
	end
	if not pos then
		pos = planePoint(if s.level == 0 then 0 else base)
	end
	if not pos then
		return nil, nil
	end
	local x, z = snapItem(pos.X), snapItem(pos.Z)
	local y = math.floor(pos.Y * 100 + 0.5) / 100
	if def.place == "stairs" then
		y = if s.level == 0 then P.Foundation else Plan.levelBase(s.level)
	elseif def.place == "ceiling" then
		y = Plan.levelTop(s.level) - (if s.level < P.Levels - 1 then 1 else 0)
	elseif s.level > 0 then
		y = math.max(y, base)
	end
	return { id = pl.id, x = x, y = y, z = z, r = pl.r % 360, lv = s.level, c1 = pl.c1, c2 = pl.c2 }, nil
end

-- Placing a ready-made building: its ghost is built once per building and turn (in a model of
-- its own) and slid about as the mouse moves; whether it fits is checked on a copy of the plan.
local presetGhost: Model? = nil
local presetGhostKey = ""
local presetCheckKey = ""
local presetCheck: any = nil

local function presetGhostModel(id: string, rot: number, valid: boolean): Model?
	local key = string.format("%s|%d|%s", id, rot, tostring(valid))
	if presetGhost and presetGhost.Parent and key == presetGhostKey then
		return presetGhost
	end
	if not ghostFolder then
		return nil
	end
	ghostFolder:ClearAllChildren()
	lastGhostKey = ""
	local empty = Plan.new(P.Size)
	empty.size = P.Size
	local _, _, _, trial, made = Presets.check(empty, Presets.requests(id, 0, 0, rot))
	local prims = {}
	for _, m in made do
		local obj = (trial :: any)[m.kind][m.key]
		local def = m.kind == "items" and Catalog.get(obj.id)
		if not (def and def.place == "ceiling") then
			Geometry.append(prims, Builder.primsFor(trial, m.kind, m.key) or {})
		end
	end
	local model = Instance.new("Model")
	model.Name = "PresetGhost"
	Builder.instantiate(prims, model, CFrame.identity, {
		ghost = true,
		tint = if valid then nil else Color3.fromRGB(235, 80, 80),
	})
	model.WorldPivot = CFrame.identity
	model.Parent = ghostFolder
	presetGhost = model
	presetGhostKey = key
	return model
end

local function presetTool()
	local pl = s.placing
	local preset = pl and Presets.get(pl.preset)
	local p = planePoint(0)
	if not preset or not p then
		clearGhost()
		presetGhost = nil
		setLabel(nil)
		candidate = nil
		return
	end
	local fw, fd = Presets.footprint(preset, pl.r)
	local x1, z1, x2, z2 = Plan.bounds(State.plan)
	local ox = math.clamp(math.floor((p.X - fw / 2) / P.WallSnap + 0.5) * P.WallSnap, x1, math.max(x1, x2 - fw))
	local oz = math.clamp(math.floor((p.Z - fd / 2) / P.WallSnap + 0.5) * P.WallSnap, z1, math.max(z1, z2 - fd))
	local key = string.format("%s|%d|%d|%d", preset.id, ox, oz, pl.r)
	if key ~= presetCheckKey then
		presetCheckKey = key
		local requests = Presets.requests(preset.id, ox, oz, pl.r)
		local ok, why, cost = Presets.check(State.plan, requests)
		if ok and cost > coins() then
			ok, why = false, "not enough coins"
		end
		presetCheck = { requests = requests, valid = ok, reason = why, cost = cost }
	end
	local c = presetCheck
	local model = presetGhostModel(preset.id, pl.r, c.valid)
	if model then
		model:PivotTo(plotFrame * CFrame.new(ox, 0, oz))
	end
	setLabel(
		if c.valid then string.format("%s   %s", preset.name, costText(c.cost)) else c.reason or "",
		Vector3.new(ox + fw / 2, 16, oz + fd / 2)
	)
	candidate = { requests = c.requests, valid = c.valid, reason = c.reason }
end

local function placeTool()
	local item, reason = placeCandidate()
	if not item then
		clearGhost()
		setLabel(reason, if reason then planePoint() else nil)
		candidate = nil
		return
	end
	local def = Catalog.get(item.id) :: any
	local moveKey = s.placing.moveKey
	local valid, why = Plan.validItem(State.plan, item, moveKey)
	local cost = if moveKey then 0 else def.price
	if valid and cost > coins() then
		valid, why = false, "not enough coins"
	end
	local frame = Plan.itemFrame(State.plan, item)
	if not frame then
		clearGhost()
		candidate = nil
		return
	end
	local prims = Geometry.transform(Catalog.prims(def, item.c1, item.c2), frame)
	local key = string.format(
		"i%s|%.2f|%.2f|%.2f|%d|%s|%s|%s|%s",
		item.id,
		item.x,
		item.y,
		item.z,
		item.r,
		tostring(item.wall),
		tostring(item.t),
		tostring(item.side),
		tostring(valid)
	)
	showGhost(key, prims, valid)
	local at = frame.Position + Vector3.new(0, def.size.Y + 1.5, 0)
	setLabel(if valid then (if moveKey then "Move here" else costText(cost)) else why, at)
	if moveKey then
		local before = State.plan.items[moveKey]
		item.c1 = before and before.c1
		item.c2 = before and before.c2
		candidate =
			{ requests = { { type = "set", kind = "items", key = moveKey, obj = item } }, valid = valid, reason = why }
	else
		candidate = { requests = { { type = "add", kind = "items", obj = item } }, valid = valid, reason = why }
	end
end

-- The side of a wall a hit landed on.
local function sideOf(hit: RaycastResult, w: any): string
	local normal = plotFrame:VectorToObjectSpace(hit.Normal)
	return if normal:Dot(Plan.wallNormal(w)) >= 0 then "a" else "b"
end

local function paintRequest(hit: RaycastResult): any?
	local kind, key = objectOf(hit.Instance)
	if not kind or not key then
		return nil
	end
	local obj = Plan.copy((State.plan :: any)[kind][key])
	if not obj then
		return nil
	end
	local c, m = s.paint.c, s.paint.m
	if kind == "walls" then
		local def = Plan.WallStyles[obj.style]
		if def and def.fence or obj.style == "glass" then
			obj.a = { c = c, m = m }
			obj.b = { c = c, m = m }
		else
			obj[sideOf(hit, obj)] = { c = c, m = m }
		end
	elseif kind == "floors" then
		obj.c, obj.m = c, m
	elseif kind == "roofs" then
		if s.paint.slot == "trim" then
			obj.c2, obj.m2 = c, m
		else
			obj.c, obj.m = c, m
		end
	elseif kind == "items" then
		if s.paint.slot == "trim" then
			obj.c2 = c
		else
			obj.c1 = c
		end
	end
	return { type = "set", kind = kind, key = key, obj = obj }
end

-- Reads the colour under the pointer into the paint brush.
local function pickColor(hit: RaycastResult)
	local kind, key = objectOf(hit.Instance)
	if not kind or not key then
		return
	end
	local obj = (State.plan :: any)[kind][key]
	if kind == "walls" then
		local side = obj[sideOf(hit, obj)]
		s.paint.c, s.paint.m = side.c, side.m
	elseif kind == "floors" then
		s.paint.c, s.paint.m = obj.c, obj.m
	elseif kind == "roofs" then
		if s.paint.slot == "trim" then
			s.paint.c, s.paint.m = obj.c2, obj.m2
		else
			s.paint.c, s.paint.m = obj.c, obj.m
		end
	elseif kind == "items" then
		local def = Catalog.get(obj.id)
		if def then
			s.paint.c = if s.paint.slot == "trim" then (obj.c2 or def.c2 or def.c1) else (obj.c1 or def.c1)
		end
	end
	s.paint.pick = false
	changed("paint")
end

local function pickTool(color: Color3)
	local hit = raycast()
	clearGhost()
	setLabel(nil)
	if not hit then
		setHighlight(nil)
		candidate = nil
		return nil
	end
	local kind, key, model = objectOf(hit.Instance)
	if not kind then
		setHighlight(nil)
		candidate = nil
		return nil
	end
	setHighlight(model, color)
	return hit, kind, key
end

local pulseClock = 0
local function update()
	if not s.active or pending then
		return
	end
	-- whatever is under the pointer or picked breathes gently
	pulseClock += 1 / 60
	if highlight then
		highlight.FillTransparency = 0.68 + math.sin(pulseClock * 5) * 0.12
	end
	local tool = s.tool
	if tool == "wall" then
		setHighlight(nil)
		wallTool()
	elseif tool == "floor" then
		setHighlight(nil)
		rectTool("floors")
	elseif tool == "roof" then
		setHighlight(nil)
		rectTool("roofs")
	elseif tool == "place" then
		setHighlight(nil)
		placeTool()
	elseif tool == "preset" then
		setHighlight(nil)
		presetTool()
	elseif tool == "paint" then
		local hit = pickTool(Color3.fromRGB(255, 212, 92))
		candidate = if hit and not s.paint.pick
			then { requests = { paintRequest(hit) }, valid = true, paint = hit }
			else { pick = hit }
	elseif tool == "delete" then
		local hit, kind, key = pickTool(Color3.fromRGB(235, 80, 80))
		if hit and kind and key then
			local ops = Plan.removeOps(State.plan, kind, key)
			local refund = -Plan.changeCost(ops)
			setLabel(
				"Sell for " .. Text.commas(refund),
				plotFrame:PointToObjectSpace(hit.Position + Vector3.new(0, 3, 0))
			)
			candidate = { requests = { { type = "remove", kind = kind, key = key } }, valid = true }
		end
	elseif tool == "select" then
		local _, kind, key = pickTool(Color3.fromRGB(79, 169, 217))
		candidate = { select = if kind then { kind = kind, key = key } else false }
		if s.selected and not kind then
			setHighlight(modelOf(s.selected.kind, s.selected.key), Color3.fromRGB(79, 169, 217))
		end
	end
end

-- A failing frame shouldn't silently kill the tools: report the error once and carry on.
local lastError: string? = nil
local function safeUpdate()
	local ok, err = pcall(update)
	if not ok then
		local msg = tostring(err)
		if msg ~= lastError then
			lastError = msg
			warn("[BuildMode] " .. msg)
			Toasts.show("Build mode hit a snag: " .. msg:sub(1, 100), "warn")
		end
	end
end

-- sending -----------------------------------------------------------------------------------------

local sendToken = 0
local placedEvent = Instance.new("BindableEvent")
BuildMode.Placed = placedEvent.Event -- (ok) after the server answers

function BuildMode.send(requests: { any }, onDone: ((boolean) -> ())?)
	if pending or #requests == 0 then
		return
	end
	pending = true
	sendToken += 1
	local token = sendToken
	-- never let one lost answer freeze the tools
	task.delay(8, function()
		if pending and sendToken == token then
			pending = false
		end
	end)
	task.spawn(function()
		local called, ok, err = pcall(function()
			return Remotes.fn("BuildApply"):InvokeServer(requests)
		end)
		if sendToken == token then
			pending = false
		end
		lastGhostKey = ""
		if not called then
			warn("[BuildMode] BuildApply failed:", ok)
			Toasts.show("Couldn't reach the server. Try again.", "warn")
			ok = false
		elseif not ok then
			Toasts.show(Text.fill("Can't do that: {why}", { why = err or "something went wrong" }), "warn")
		end
		placedEvent:Fire(ok == true)
		if onDone then
			onDone(ok == true)
		end
	end)
end

local function primary(released: boolean?)
	if not s.active then
		return
	end
	local tool = s.tool
	if tool == "wall" and s.wallMode == "line" then
		-- drag from one point to another for a single wall, or click, click, click for a chain
		local p = planePoint()
		if not p then
			return
		end
		local g = Vector3.new(snapX(p.X), Plan.levelBase(s.level), snapZ(p.Z))
		if released then
			if wallStart and pressPoint and (g - pressPoint).Magnitude > 0.1 then
				if candidate and candidate.valid then
					BuildMode.send(candidate.requests)
				elseif candidate and candidate.reason then
					Toasts.show(candidate.reason, "warn")
				end
				wallStart = nil
			end
			pressPoint = nil
			return
		end
		if not wallStart then
			wallStart = g
			pressPoint = g
			return
		end
		pressPoint = nil
		if candidate and candidate.valid then
			BuildMode.send(candidate.requests)
			wallStart = candidate.chain
		elseif candidate and candidate.reason then
			Toasts.show(candidate.reason, "warn")
		end
		return
	end
	if (tool == "wall" and s.wallMode == "room") or tool == "floor" or tool == "roof" then
		local p = planePoint()
		if not p then
			return
		end
		local g = Vector3.new(snapX(p.X), Plan.levelBase(s.level), snapZ(p.Z))
		if not rectStart then
			if not released then
				rectStart = g
				pressPoint = g
			end
			return
		end
		if released and pressPoint and (g - pressPoint).Magnitude < 0.1 then
			return -- a plain click: wait for the second corner
		end
		if released and not pressPoint then
			return
		end
		if candidate and candidate.valid then
			BuildMode.send(candidate.requests)
		elseif candidate and candidate.reason then
			Toasts.show(candidate.reason, "warn")
		end
		rectStart = nil
		pressPoint = nil
		return
	end
	if released then
		return
	end
	if tool == "preset" then
		if candidate and candidate.valid then
			presetCheckKey = ""
			-- a whole building is a big step: once it's down, go back to picking
			BuildMode.send(candidate.requests, function(ok)
				if ok and s.tool == "preset" then
					BuildMode.setTool("select")
				end
			end)
		elseif candidate and candidate.reason then
			Toasts.show(candidate.reason, "warn")
		end
		return
	end
	if tool == "place" then
		if candidate and candidate.valid then
			local moving = s.placing and s.placing.moveKey
			BuildMode.send(candidate.requests)
			if moving then
				s.placing = nil
				s.tool = "select"
				changed("tool")
			end
		elseif candidate and candidate.reason then
			Toasts.show(candidate.reason, "warn")
		end
	elseif tool == "paint" then
		if s.paint.pick and candidate and candidate.pick then
			pickColor(candidate.pick)
		elseif candidate and candidate.valid and candidate.requests[1] then
			BuildMode.send(candidate.requests)
		end
	elseif tool == "delete" then
		if candidate and candidate.valid then
			BuildMode.send(candidate.requests)
		end
	elseif tool == "select" then
		if candidate and candidate.select then
			s.selected = candidate.select
		else
			s.selected = nil
		end
		changed("selected")
	end
end

local function cancel()
	if wallStart or rectStart then
		wallStart = nil
		rectStart = nil
		pressPoint = nil
		lastGhostKey = ""
		return
	end
	if s.tool == "place" or s.tool == "preset" then
		s.placing = nil
		s.tool = "select"
		clearGhost()
		changed("tool")
	elseif s.selected then
		s.selected = nil
		changed("selected")
	end
end

-- levels, roofs and see-through walls ----------------------------------------------------------------

local function applyVisibility(model: Instance)
	local kind = model:GetAttribute("BuildKind")
	local lv = model:GetAttribute("Level")
	if type(lv) ~= "number" then
		return
	end
	local hide = false
	local ghosty = false
	if s.active then
		if kind == "roofs" then
			hide = s.roofsHidden and lv >= s.level
		elseif lv > s.level then
			hide = true
		elseif kind == "walls" and lv == s.level and s.seeThrough then
			ghosty = true
		end
	end
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			if hide then
				d.LocalTransparencyModifier = 0.94
				if hidden[d] == nil then
					hidden[d] = d.CanQuery
				end
				d.CanQuery = false
			elseif ghosty then
				d.LocalTransparencyModifier = 0.6
				if hidden[d] ~= nil then
					d.CanQuery = hidden[d]
					hidden[d] = nil
				end
			else
				d.LocalTransparencyModifier = 0
				if hidden[d] ~= nil then
					d.CanQuery = hidden[d]
					hidden[d] = nil
				end
			end
		end
	end
end

local function applyAllVisibility()
	if not buildFolder then
		return
	end
	for _, m in buildFolder:GetChildren() do
		applyVisibility(m)
	end
end

local function drawGrid()
	if not gridFolder then
		return
	end
	gridFolder:ClearAllChildren()
	local h = Plan.levelBase(s.level) + 0.06
	if s.level == 0 then
		h = 0.08
	end
	local step = 4
	local color = Color3.fromRGB(255, 255, 255)
	local x1, z1, x2, z2 = Plan.bounds(State.plan)
	local function line(cf: CFrame, size: Vector3, strong: boolean)
		local part = Instance.new("Part")
		part.Anchored = true
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.CastShadow = false
		part.Material = Enum.Material.SmoothPlastic
		part.Color = color
		part.Transparency = if strong then 0.45 else 0.75
		part.Size = size
		part.CFrame = cf
		part.Parent = gridFolder
	end
	for z = z1, z2, step do
		line(plotFrame * CFrame.new((x1 + x2) / 2, h, z), Vector3.new(x2 - x1, 0.04, 0.12), (z - z1) % 12 == 0)
	end
	for x = x1, x2, step do
		line(plotFrame * CFrame.new(x, h, (z1 + z2) / 2), Vector3.new(0.12, 0.04, z2 - z1), (x - x1) % 12 == 0)
	end
end

function BuildMode.setLevel(n: number)
	s.level = math.clamp(n, 0, P.Levels - 1)
	wallStart, rectStart = nil, nil
	lastGhostKey = ""
	BuildCamera.setHeight(Plan.levelBase(s.level))
	drawGrid()
	applyAllVisibility()
	changed("level")
end

function BuildMode.setRoofsHidden(v: boolean)
	s.roofsHidden = v
	applyAllVisibility()
	changed("view")
end

function BuildMode.setSeeThrough(v: boolean)
	s.seeThrough = v
	applyAllVisibility()
	changed("view")
end

-- tools and settings ---------------------------------------------------------------------------------

function BuildMode.setTool(tool: string)
	s.tool = tool
	wallStart, rectStart, pressPoint = nil, nil, nil
	if tool ~= "place" and tool ~= "preset" then
		s.placing = nil
	end
	presetGhost = nil
	presetCheckKey = ""
	if tool ~= "select" then
		s.selected = nil
	end
	lastGhostKey = ""
	clearGhost()
	setLabel(nil)
	setHighlight(nil)
	local hints = {
		select = "Click something to pick it.",
		wall = if s.wallMode == "room"
			then "Click two corners to make a room."
			else "Click to start a wall, click again to end it. Right click stops.",
		floor = "Click two corners to lay a floor.",
		roof = "Click two corners over the walls.",
		place = "Click to place. R turns it.",
		preset = "Click to put the building down. R turns it.",
		paint = "Click a wall side, floor, roof or item to paint it.",
		delete = "Click something to sell it back.",
	}
	s.hint = hints[tool] or ""
	changed("tool")
end

function BuildMode.startPlacing(id: string, c1: string?, c2: string?)
	local def = Catalog.get(id)
	if not def then
		return
	end
	s.placing = { id = id, r = 0, c1 = c1, c2 = c2 }
	BuildMode.setTool("place")
	s.placing = { id = id, r = 0, c1 = c1, c2 = c2 }
	changed("tool")
end

-- Picks up a ready-made building to place.
function BuildMode.startPreset(id: string)
	if not Presets.get(id) then
		return
	end
	BuildMode.setTool("preset")
	s.placing = { preset = id, r = 0 }
	changed("tool")
end

function BuildMode.rotate(step: number?)
	local pl = s.placing
	if pl and pl.preset then
		pl.r = (pl.r + 90) % 360
		presetCheckKey = ""
		return
	end
	if pl then
		local def = Catalog.get(pl.id)
		local d = step or 45
		if def and def.place == "stairs" then
			d = 90
		end
		pl.r = (pl.r + d) % 360
		lastGhostKey = ""
		return
	end
	local sel = s.selected
	if sel and sel.kind == "items" then
		local obj = Plan.copy(State.plan.items[sel.key])
		local def = obj and Catalog.get(obj.id)
		if obj and def and def.place ~= "opening" and def.place ~= "wall" then
			obj.r = (obj.r + (if def.place == "stairs" then 90 else (step or 45))) % 360
			BuildMode.send({ { type = "set", kind = "items", key = sel.key, obj = obj } })
		elseif obj and def then
			obj.side = if obj.side == "a" then "b" else "a"
			BuildMode.send({ { type = "set", kind = "items", key = sel.key, obj = obj } })
		end
	elseif sel and sel.kind == "roofs" then
		local obj = Plan.copy(State.plan.roofs[sel.key])
		obj.dir = (obj.dir + 1) % 4
		BuildMode.send({ { type = "set", kind = "roofs", key = sel.key, obj = obj } })
	end
end

function BuildMode.moveSelected()
	local sel = s.selected
	if not sel or sel.kind ~= "items" then
		return
	end
	local obj = State.plan.items[sel.key]
	if not obj then
		return
	end
	BuildMode.setTool("place")
	s.placing = { id = obj.id, r = obj.r, c1 = obj.c1, c2 = obj.c2, moveKey = sel.key }
	changed("tool")
end

function BuildMode.copySelected()
	local sel = s.selected
	if not sel or sel.kind ~= "items" then
		return
	end
	local obj = State.plan.items[sel.key]
	if obj then
		BuildMode.startPlacing(obj.id, obj.c1, obj.c2)
		s.placing.r = obj.r
	end
end

function BuildMode.deleteSelected()
	local sel = s.selected
	if not sel then
		return
	end
	BuildMode.send({ { type = "remove", kind = sel.kind, key = sel.key } })
	s.selected = nil
	changed("selected")
end

-- Changes fields of the selected object (roof shape, wall style, item colours).
function BuildMode.editSelected(fields: { [string]: any })
	local sel = s.selected
	if not sel then
		return
	end
	local obj = Plan.copy((State.plan :: any)[sel.kind][sel.key])
	if not obj then
		return
	end
	for k, v in fields do
		obj[k] = v
	end
	BuildMode.send({ { type = "set", kind = sel.kind, key = sel.key, obj = obj } })
end

-- The Model of the picked object, if it's still built.
function BuildMode.selectedModel(): Model?
	local sel = s.selected
	if not sel then
		return nil
	end
	return modelOf(sel.kind, sel.key)
end

function BuildMode.selectedObject(): (string?, string?, any)
	local sel = s.selected
	if not sel then
		return nil, nil, nil
	end
	return sel.kind, sel.key, (State.plan :: any)[sel.kind][sel.key]
end

function BuildMode.undo()
	task.spawn(function()
		local ok, err = Remotes.fn("BuildUndo"):InvokeServer()
		if not ok and err then
			Toasts.show(err, "info")
		end
	end)
end

function BuildMode.redo()
	task.spawn(function()
		local ok, err = Remotes.fn("BuildRedo"):InvokeServer()
		if not ok and err then
			Toasts.show(err, "info")
		end
	end)
end

function BuildMode.notify()
	changed("state")
end

-- entering and leaving -------------------------------------------------------------------------------

local function bindKeys()
	table.insert(
		connections,
		UserInputService.InputBegan:Connect(function(input, processed)
			if not s.active then
				return
			end
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				-- our own check: Roblox's processed flag isn't reliable for telling interface clicks
				-- from clicks on the world
				if Kit.overUI() then
					return
				end
				pointer = nil
				pointerIsScreen = false
				pressedInWorld = true
				primary(false)
			elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
				cancel()
			elseif input.UserInputType == Enum.UserInputType.Keyboard and not processed then
				local ctrl = UserInputService:IsKeyDown(Enum.KeyCode.LeftControl)
					or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)
				local shift = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
				if input.KeyCode == Enum.KeyCode.R then
					BuildMode.rotate(if shift then 15 else 45)
				elseif
					input.KeyCode == Enum.KeyCode.Escape
					or input.KeyCode == Enum.KeyCode.Backspace and s.tool ~= "select"
				then
					cancel()
				elseif input.KeyCode == Enum.KeyCode.Delete or input.KeyCode == Enum.KeyCode.X and not ctrl then
					BuildMode.deleteSelected()
				elseif input.KeyCode == Enum.KeyCode.Z and ctrl then
					if shift then
						BuildMode.redo()
					else
						BuildMode.undo()
					end
				elseif input.KeyCode == Enum.KeyCode.Y and ctrl then
					BuildMode.redo()
				elseif input.KeyCode == Enum.KeyCode.G then
					s.snap = not s.snap
					changed("view")
				elseif input.KeyCode == Enum.KeyCode.PageUp or input.KeyCode == Enum.KeyCode.Period then
					BuildMode.setLevel(s.level + 1)
				elseif input.KeyCode == Enum.KeyCode.PageDown or input.KeyCode == Enum.KeyCode.Comma then
					BuildMode.setLevel(s.level - 1)
				elseif input.KeyCode == Enum.KeyCode.M and s.selected then
					BuildMode.moveSelected()
				elseif input.KeyCode == Enum.KeyCode.C and s.selected and not ctrl then
					BuildMode.copySelected()
				end
			end
		end)
	)
	table.insert(
		connections,
		UserInputService.InputEnded:Connect(function(input, processed)
			-- a release over the panels (a swatch, a tab) must not finish a half drawn rectangle
			if s.active and input.UserInputType == Enum.UserInputType.MouseButton1 and pressedInWorld then
				pressedInWorld = false
				if not Kit.overUI() then
					primary(true)
				end
			end
			local _ = processed
		end)
	)
	table.insert(
		connections,
		UserInputService.TouchTapInWorld:Connect(function(pos, processed)
			if not s.active or processed or BuildCamera.dragged then
				return
			end
			pointer = pos
			pointerIsScreen = true
			lastGhostKey = ""
			update()
			primary(false)
		end)
	)
	table.insert(
		connections,
		UserInputService.InputChanged:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseMovement then
				pointer = nil
				pointerIsScreen = false
			end
		end)
	)
	table.insert(connections, RunService.RenderStepped:Connect(safeUpdate))
end

function BuildMode.enter(): boolean
	if s.active then
		return true
	end
	local index = player:GetAttribute("Plot")
	if type(index) ~= "number" then
		Toasts.show("Your plot isn't ready yet.", "warn")
		return false
	end
	plotIndex = index
	plotFrame = Town.plotFrame(index)
	local plots = workspace:FindFirstChild("Plots")
	local plotModel = plots and plots:FindFirstChild("Plot" .. index)
	buildFolder = plotModel and plotModel:FindFirstChild("Build")
	if not buildFolder then
		return false
	end
	s.active = true
	local gf = Instance.new("Folder")
	gf.Name = "BuildGhost"
	gf.Parent = workspace
	ghostFolder = gf
	local grid = Instance.new("Folder")
	grid.Name = "BuildGrid"
	grid.Parent = workspace
	gridFolder = grid
	local marks = Instance.new("Folder")
	marks.Name = "BuildMarkers"
	marks.Parent = workspace
	markerFolder = marks
	local m = Instance.new("Part")
	m.Anchored = true
	m.CanCollide = false
	m.CanQuery = false
	m.CanTouch = false
	m.Transparency = 1
	m.Size = Vector3.new(0.2, 0.2, 0.2)
	m.Parent = marks
	marker = m
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(240, 34)
	bb.AlwaysOnTop = true
	bb.Enabled = false
	bb.Adornee = m
	bb.Parent = m
	local t = Instance.new("TextLabel")
	t.Name = "Text"
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundColor3 = Color3.fromRGB(255, 249, 238)
	t.BackgroundTransparency = 0.1
	t.TextColor3 = Color3.fromRGB(74, 52, 38)
	t.Font = Enum.Font.FredokaOne
	t.TextSize = 18
	t.Parent = bb
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = t
	label = bb
	local h = Instance.new("Highlight")
	h.FillTransparency = 0.75
	h.OutlineTransparency = 0
	h.DepthMode = Enum.HighlightDepthMode.Occluded
	h.Enabled = false
	h.Parent = marks
	highlight = h

	BuildCamera.enable(plotFrame)
	BuildCamera.setHeight(Plan.levelBase(s.level))
	-- stop the character walking off while WASD moves the camera
	ContextActionService:BindActionAtPriority(
		"BuildFreeze",
		function()
			return Enum.ContextActionResult.Sink
		end,
		false,
		Enum.ContextActionPriority.High.Value,
		Enum.PlayerActions.CharacterForward,
		Enum.PlayerActions.CharacterBackward,
		Enum.PlayerActions.CharacterLeft,
		Enum.PlayerActions.CharacterRight,
		Enum.PlayerActions.CharacterJump
	)
	drawGrid()
	applyAllVisibility()
	table.insert(
		connections,
		buildFolder.ChildAdded:Connect(function(child)
			task.defer(applyVisibility, child)
			if s.selected and child.Name == Builder.modelName(s.selected.kind, s.selected.key) then
				changed("selected")
			end
		end)
	)
	bindKeys()
	BuildMode.setTool("select")
	changed("active")
	return true
end

function BuildMode.exit()
	if not s.active then
		return
	end
	s.active = false
	for _, c in connections do
		c:Disconnect()
	end
	connections = {}
	ContextActionService:UnbindAction("BuildFreeze")
	BuildCamera.disable()
	applyAllVisibility()
	for part, canQuery in hidden do
		if part.Parent then
			part.CanQuery = canQuery
			part.LocalTransparencyModifier = 0
		end
	end
	hidden = {}
	if ghostFolder then
		ghostFolder:Destroy()
	end
	if gridFolder then
		gridFolder:Destroy()
	end
	if markerFolder then
		markerFolder:Destroy()
	end
	ghostFolder, gridFolder, markerFolder, marker, label, highlight = nil, nil, nil, nil, nil, nil
	wallStart, rectStart, candidate = nil, nil, nil
	s.selected = nil
	s.placing = nil
	changed("active")
end

function BuildMode.isActive(): boolean
	return s.active
end

function BuildMode.plotIndex(): number?
	return plotIndex
end

State.onPlan(function(ops)
	if s.active then
		lastGhostKey = ""
		if ops == nil then
			drawGrid() -- a full plan: maybe more land
		end
		changed("plan")
	end
end)

return BuildMode
