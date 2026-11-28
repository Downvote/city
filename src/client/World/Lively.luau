-- Placed pieces that move and give off effects, on this player's screen only. The user: "make
-- animated decor, workplaces with special effects, particle makers, and more enticing types of
-- things". A piece's drawing names what moves and what it gives off (Build/Lively has the names
-- and the attributes); this finds those parts in every plot's placed pieces and plays them:
--   * moving groups turn, swing or bob round their pivots, clock hands keep the town's time,
--     a ride's cabins go round upright: all of it in one batch a frame (BulkMoveTo), thirty
--     times a second, for the pieces near the camera only
--   * lights named Twinkle glimmer (and run through soft colours with `Hue`), ten times a second
--   * effect spots get their emitters (Data/Effects) the first time the camera comes near, and
--     are switched off far away; a workplace's only while its model is marked `Working` (the
--     server marks it while a villager or a player is at work there: Services/Work), and one
--     that follows its piece's switch only while the model isn't marked `LightsOff`
--     (Services/Lights: a fog machine)
--   * running water (parts named Flow) gets its moving pictures (Data/Effects' Flows) the first
--     time the camera comes near, and they run while it is near
-- Everything that touches an effect or a light is in a pcall: a feature missing here (the
-- simulation, an older engine) leaves the piece still, never broken. Nothing goes to the server.

local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Catalog = require(Shared.Build.Catalog)
local Rules = require(Shared.Build.Lively)
local Effects = require(Shared.Data.Effects)
local Tuning = require(Shared.Config.Tuning)

local Lively = {}

local K = Tuning.Lively
Lively.MoveRange = K.MoveRange -- studs from the camera that a piece moves within
Lively.FxRange = K.FxRange -- and gives off its effects within
Lively.RateScale = 1 -- times every effect's rate (the player's detail level: World/Graphics)
local STEP = 1 / K.MoveRate -- seconds between two moves
local GLINT_STEP = 1 / K.GlintRate -- between two glimmers
local LOOK = K.Look -- between two looks at what is near, at work, or due a burst
local SETTLE = K.Settle -- seconds after a piece arrives before it is looked inside (BuildFx springs it up)

type Group = {
	pivot: CFrame,
	motion: string,
	speed: number,
	amount: number,
	axis: string,
	phase: number,
	clock: boolean, -- a clock's hand: no stagger, it tells the time
	parts: { BasePart },
	locals: { CFrame },
	cabins: { BasePart },
	cabinAt: { Vector3 }, -- where each hangs from, in the pivot's space
	cabinHang: { number },
	cabinRot: { CFrame },
}

type Glint = { part: BasePart, base: number, color: Color3, hue: boolean, phase: number }

type Flow = {
	part: BasePart,
	look: Effects.Flow,
	faces: { Enum.NormalId },
	speed: number,
	drift: number,
	made: { Texture }?,
}

type Fx = {
	part: BasePart,
	kind: string,
	preset: Effects.Preset,
	work: boolean,
	switch: boolean,
	color: Color3,
	made: { Instance }?,
	on: boolean,
	due: number,
}

type Entry = {
	model: Model,
	at: Vector3,
	seed: number,
	groups: { Group },
	glints: { Glint },
	fx: { Fx },
	flows: { Flow },
	near: boolean,
	fxNear: boolean,
}

local entries: { [Instance]: Entry } = {}
local list: { Entry } = {}
local clock = 0

local moveParts: { BasePart } = {}
local moveFrames: { CFrame } = {}

-- Reading a piece ------------------------------------------------------------------------------------

local function num(part: Instance, name: string, default: number): number
	local v = part:GetAttribute(name)
	return if type(v) == "number" and v == v then v else default
end

-- Is this a placed piece worth looking inside: one that moves or gives off something, or a
-- workplace (its effect is on while somebody works there)?
function Lively.wants(model: Instance): boolean
	if not model:IsA("Model") or model:GetAttribute("BuildKind") ~= "items" then
		return false
	end
	local id = model:GetAttribute("ItemId")
	local def = if type(id) == "string" then Catalog.get(id) else nil
	return def ~= nil and (def.lively == true or def.job ~= nil)
end

local function readGroup(pivot: BasePart, members: { BasePart }, cabins: { BasePart }?): Group
	local motion = pivot:GetAttribute("Motion")
	local axis = pivot:GetAttribute("Axis")
	local m: string = if type(motion) == "string" and Rules.Motions[motion] then motion else "spin"
	local g: Group = {
		pivot = pivot.CFrame,
		motion = m,
		speed = num(pivot, "Speed", 1),
		amount = num(pivot, "Amount", 0),
		axis = if type(axis) == "string" and Rules.Axes[axis] then axis else "Y",
		phase = num(pivot, "Phase", 0),
		clock = m == "minute" or m == "hour",
		parts = {},
		locals = {},
		cabins = {},
		cabinAt = {},
		cabinHang = {},
		cabinRot = {},
	}
	-- a pivot you can see goes round with its group (an axle, a hub); a hidden one stays
	if pivot.Transparency < 0.99 then
		table.insert(members, pivot)
	end
	for _, p in members do
		table.insert(g.parts, p)
		table.insert(g.locals, g.pivot:ToObjectSpace(p.CFrame))
	end
	local riders: { BasePart } = cabins or {}
	for _, p in riders do
		local hang = num(p, "Hang", 0)
		local at = p.CFrame.Position
		table.insert(g.cabins, p)
		table.insert(g.cabinAt, g.pivot:PointToObjectSpace(at + Vector3.new(0, hang, 0)))
		table.insert(g.cabinHang, hang)
		table.insert(g.cabinRot, p.CFrame - at)
	end
	return g
end

-- What of a piece moves, glimmers and gives off effects, as it stands now (its pose as drawn).
function Lively.read(model: Model): Entry?
	local pivots: { [number]: BasePart } = {}
	local members: { [number]: { BasePart } } = {}
	local cabins: { BasePart } = {}
	local glints: { Glint } = {}
	local fx: { Fx } = {}
	local flows: { Flow } = {}
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			-- a moving part that glimmers as it goes (a firefly: Build/Lively.blink)
			if d:GetAttribute("Blink") == true then
				table.insert(glints, {
					part = d,
					base = d.Transparency,
					color = d.Color,
					hue = false,
					phase = (#glints * 2.39) % (math.pi * 2),
				})
			end
			local role, g = Rules.roleOf(d.Name)
			if role == "pivot" and g then
				pivots[g] = d
			elseif role == "move" and g then
				members[g] = members[g] or {}
				table.insert(members[g], d)
			elseif d.Name == Rules.Cabin then
				table.insert(cabins, d)
			elseif d.Name == Rules.Twinkle then
				table.insert(glints, {
					part = d,
					base = d.Transparency,
					color = d.Color,
					hue = d:GetAttribute("Hue") == true,
					phase = (#glints * 2.39) % (math.pi * 2),
				})
			elseif d.Name == Rules.Fx then
				local kind = d:GetAttribute("Fx")
				local preset = if type(kind) == "string" then Effects.get(kind) else nil
				if preset and type(kind) == "string" then
					local c = d:GetAttribute("FxColor")
					table.insert(fx, {
						part = d,
						kind = kind,
						preset = preset,
						work = d:GetAttribute("FxWork") == true,
						switch = d:GetAttribute("FxSwitch") == true,
						color = if typeof(c) == "Color3" then c else Color3.new(1, 1, 1),
						made = nil,
						on = false,
						due = 0,
					})
				end
			elseif d.Name == Rules.Flow then
				local kind = d:GetAttribute("Flow")
				local look = if type(kind) == "string" then Effects.Flows[kind] else nil
				if look then
					local faces: { Enum.NormalId } = {}
					local named = d:GetAttribute("FlowFaces")
					for name in string.gmatch(if type(named) == "string" then named else "Front,Back", "%a+") do
						local face = (Enum.NormalId :: any)[name]
						if face then
							table.insert(faces, face)
						end
					end
					table.insert(flows, {
						part = d,
						look = look,
						faces = faces,
						speed = num(d, "FlowSpeed", 0),
						drift = num(d, "FlowDrift", 0),
						made = nil,
					})
				end
			end
		end
	end
	local groups: { Group } = {}
	for g = 1, Rules.Groups do
		local pivot = pivots[g]
		if pivot then
			table.insert(groups, readGroup(pivot, members[g] or {}, if g == 1 then cabins else nil))
		end
	end
	if #groups == 0 and #glints == 0 and #fx == 0 and #flows == 0 then
		return nil
	end
	local at = model:GetPivot().Position
	return {
		model = model,
		at = at,
		-- two of the same piece side by side don't move in step
		seed = (at.X * 0.37 + at.Z * 0.61) % (math.pi * 2),
		groups = groups,
		glints = glints,
		fx = fx,
		flows = flows,
		near = false,
		fxNear = false,
	}
end

-- Effects ---------------------------------------------------------------------------------------------

local function sequence(values: { number }): NumberSequence
	if #values == 1 then
		return NumberSequence.new(values[1])
	end
	local keys = {}
	for i, v in values do
		table.insert(keys, NumberSequenceKeypoint.new((i - 1) / (#values - 1), v))
	end
	return NumberSequence.new(keys)
end

local function range(values: { number }?, default: number): NumberRange
	if not values then
		return NumberRange.new(default)
	end
	return NumberRange.new(values[1], values[2] or values[1])
end

-- The colours one effect gives off: its fixed ones, or the piece's paint first when tinted.
local function colorsOf(f: Fx): { Color3 }
	local p = f.preset
	local out: { Color3 } = {}
	if p.tint then
		table.insert(out, f.color)
	end
	for _, c in p.colors or {} do
		table.insert(out, c)
	end
	if #out == 0 then
		table.insert(out, Color3.new(1, 1, 1))
	end
	return out
end

local function emitter(f: Fx, color: Color3, share: number): ParticleEmitter?
	local p = f.preset
	local ok, e = pcall(function()
		local e = Instance.new("ParticleEmitter")
		e.Name = "Lively"
		e.Texture = Effects.Textures[p.texture] or Effects.Textures.sparkle
		e.Color = if p.fade then ColorSequence.new(color, p.fade) else ColorSequence.new(color)
		e.Size = sequence(p.size)
		e.Transparency = sequence(p.transp)
		e.Lifetime = range(p.life, 1)
		e.Rate = p.rate * share * Lively.RateScale
		e.Speed = range(p.speed, 1)
		e.SpreadAngle = Vector2.new(p.spread[1], p.spread[2] or p.spread[1])
		e.Acceleration = p.accel or Vector3.zero
		e.Drag = p.drag or 0
		e.Rotation = range(p.rot, 0)
		e.RotSpeed = range(p.spin, 0)
		e.LightEmission = p.light or 0
		e.EmissionDirection = (Enum.NormalId :: any)[p.dir or "Top"] or Enum.NormalId.Top
		e.LockedToPart = p.locked == true
		if p.orient then
			e.Orientation = (Enum.ParticleOrientation :: any)[p.orient] or Enum.ParticleOrientation.FacingCamera
		end
		e.Enabled = false
		return e
	end)
	if not ok or not e then
		return nil
	end
	if p.squash then
		pcall(function()
			(e :: any).Squash = sequence(p.squash :: { number })
		end)
	end
	e.Parent = f.part
	return e
end

local function make(f: Fx): { Instance }
	local made: { Instance } = {}
	local colors = colorsOf(f)
	for _, c in colors do
		local e = emitter(f, c, 1 / #colors)
		if e then
			table.insert(made, e)
		end
	end
	local fire = f.preset.fire
	if fire then
		pcall(function()
			local fl = Instance.new("Fire")
			fl.Name = "Lively"
			fl.Size = fire.size
			fl.Heat = fire.heat
			fl.Color = colors[1]
			fl.SecondaryColor = f.preset.fade or colors[1]
			fl.Enabled = false
			fl.Parent = f.part
			table.insert(made, fl)
		end)
	end
	return made
end

-- Running water's moving pictures: on each face, the flow's picture, and each further layer
-- bigger, fainter and slower (Data/Effects' Flows).
local function makeFlow(w: Flow): { Texture }
	local made: { Texture } = {}
	local look = w.look
	for _, face in w.faces do
		for layer = 1, math.max(1, look.layers) do
			pcall(function()
				local t = Instance.new("Texture")
				t.Name = "Lively"
				t.Texture = Effects.Textures[look.texture] or ""
				t.Face = face
				local grow = 1 + (layer - 1) * 0.6
				t.StudsPerTileU = look.studsU * grow
				t.StudsPerTileV = look.studsV * grow
				t.Transparency = math.min(0.95, look.transp + (layer - 1) * 0.25)
				t.Color3 = Color3.new(1, 1, 1)
				t:SetAttribute("Pace", 1 / grow)
				t:SetAttribute("Start", (layer - 1) * 1.37)
				t.Parent = w.part
				table.insert(made, t)
			end)
		end
	end
	return made
end

local function switch(f: Fx, on: boolean)
	f.on = on
	local made: { Instance } = f.made or {}
	for _, inst in made do
		pcall(function()
			(inst :: any).Enabled = on
		end)
	end
end

-- Taking pieces in and out ---------------------------------------------------------------------------

local function forget(model: Instance)
	local e = entries[model]
	if not e then
		return
	end
	entries[model] = nil
	local i = table.find(list, e)
	if i then
		table.remove(list, i)
	end
end

local function take(model: Model)
	if entries[model] or model.Parent == nil then
		return
	end
	local e = Lively.read(model)
	if e then
		entries[model] = e
		table.insert(list, e)
	end
end

-- Takes a piece in once it has settled: the spring BuildFx plays on a new piece scales it, and
-- what moves is measured from the pose it ends in.
local function arrive(model: Instance, tries: number?)
	if not Lively.wants(model) then
		return
	end
	task.delay(SETTLE, function()
		if model.Parent == nil or not model:IsA("Model") then
			return
		end
		local ok, scale = pcall(function()
			return (model :: Model):GetScale()
		end)
		if ok and type(scale) == "number" and math.abs(scale - 1) > 1e-3 and (tries or 0) < 6 then
			arrive(model, (tries or 0) + 1)
			return
		end
		take(model :: Model)
	end)
end

-- Watches one folder of placed pieces (a plot's Build folder).
function Lively.watch(folder: Instance)
	folder.ChildAdded:Connect(function(model)
		arrive(model)
	end)
	folder.ChildRemoved:Connect(forget)
	for _, model in folder:GetChildren() do
		arrive(model)
	end
end

-- Takes in a piece at once, without waiting for it to settle (the simulation and previews).
function Lively.add(model: Model): boolean
	if not Lively.wants(model) then
		return false
	end
	take(model)
	return entries[model] ~= nil
end

function Lively.count(): number
	return #list
end

-- Each frame -------------------------------------------------------------------------------------------

local function eye(): Vector3
	local cam = workspace.CurrentCamera
	return if cam then cam.CFrame.Position else Vector3.zero
end

-- What is near, who is at work, and the bursts that are due.
local function look()
	local from = eye()
	local now = clock
	for _, e in list do
		local d = (e.at - from).Magnitude
		e.near = d < Lively.MoveRange
		e.fxNear = d < Lively.FxRange
		if e.near then
			for _, w in e.flows do
				if not w.made then
					w.made = makeFlow(w)
				end
			end
		end
		if #e.fx > 0 then
			local working = e.model:GetAttribute(Rules.Working) == true
			local lit = e.model:GetAttribute(Rules.Off) ~= true
			for _, f in e.fx do
				local want = e.fxNear and (not f.work or working) and (not f.switch or lit)
				if want and not f.made then
					f.made = make(f)
				end
				if f.made and f.on ~= want then
					switch(f, want)
				end
				local burst = f.preset.burst
				if burst and f.on and now >= f.due then
					f.due = now + burst.every
					local made: { Instance } = f.made or {}
					for _, inst in made do
						if inst:IsA("ParticleEmitter") then
							pcall(function()
								(inst :: ParticleEmitter):Emit(math.max(1, math.floor(burst.count / #made)))
							end)
						end
					end
				end
			end
		end
	end
end

local function stepMotion()
	local hour = Lighting.ClockTime
	for _, e in list do
		if e.near then
			for _, g in e.groups do
				local phase = if g.clock then g.phase else g.phase + e.seed
				local turned = g.pivot * Rules.offset(g.motion, g.speed, g.amount, g.axis, phase, clock, hour)
				for i, p in g.parts do
					table.insert(moveParts, p)
					table.insert(moveFrames, turned * g.locals[i])
				end
				for i, p in g.cabins do
					table.insert(moveParts, p)
					local hook = turned:PointToWorldSpace(g.cabinAt[i])
					table.insert(moveFrames, CFrame.new(hook - Vector3.new(0, g.cabinHang[i], 0)) * g.cabinRot[i])
				end
			end
		end
	end
	if #moveParts > 0 then
		local ok, why = pcall(function()
			workspace:BulkMoveTo(moveParts, moveFrames, Enum.BulkMoveMode.FireCFrameChanged)
		end)
		table.clear(moveParts)
		table.clear(moveFrames)
		if not ok then
			warn("[Lively] " .. tostring(why))
		end
	end
end

-- Running water runs: every picture slides down its face (and across, if it drifts), each layer
-- at its own pace.
local function stepFlows()
	for _, e in list do
		if e.near then
			for _, w in e.flows do
				local made = w.made
				if made then
					for _, t in made do
						local pace = (t:GetAttribute("Pace") :: number?) or 1
						local start = (t:GetAttribute("Start") :: number?) or 0
						t.OffsetStudsV = (start + clock * w.speed * pace) % t.StudsPerTileV
						t.OffsetStudsU = (start + clock * w.drift * pace) % t.StudsPerTileU
					end
				end
			end
		end
	end
end

local function stepGlints()
	for _, e in list do
		if e.near then
			for _, g in e.glints do
				local wave = math.max(0, math.sin(clock * 2.1 + g.phase + e.seed))
				local dip = math.max(0, math.sin(clock * 5.3 + g.phase * 1.7))
				g.part.Transparency = math.min(0.9, g.base + 0.5 * wave * wave * dip)
				if g.hue then
					g.part.Color = Color3.fromHSV((clock * 0.07 + g.phase / (math.pi * 2)) % 1, 0.42, 1)
				end
			end
		end
	end
end

-- Moves everything one frame on by `dt` seconds (the game's own heartbeat calls it, and so can
-- the simulation).
local lookClock, moveClock, glintClock = LOOK, STEP, GLINT_STEP
function Lively.step(dt: number)
	clock += dt
	lookClock += dt
	if lookClock >= LOOK then
		lookClock = 0
		look()
	end
	moveClock += dt
	if moveClock >= STEP then
		moveClock = 0
		stepMotion()
		stepFlows()
	end
	glintClock += dt
	if glintClock >= GLINT_STEP then
		glintClock = 0
		stepGlints()
	end
end

-- Starting ------------------------------------------------------------------------------------------------

local function watchPlot(plot: Instance)
	local build = plot:FindFirstChild("Build")
	if build then
		Lively.watch(build)
		return
	end
	local c: RBXScriptConnection? = nil
	c = plot.ChildAdded:Connect(function(child)
		if child.Name == "Build" then
			if c then
				c:Disconnect()
			end
			Lively.watch(child)
		end
	end)
end

function Lively.start()
	task.spawn(function()
		local plots = workspace:FindFirstChild("Plots")
		local waited = 0
		while not plots and waited < 60 do
			task.wait(1)
			waited += 1
			plots = workspace:FindFirstChild("Plots")
		end
		if not plots then
			return
		end
		plots.ChildAdded:Connect(watchPlot)
		for _, plot in plots:GetChildren() do
			watchPlot(plot)
		end
	end)
	RunService.Heartbeat:Connect(Lively.step)
end

return Lively
