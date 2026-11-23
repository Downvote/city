-- Life around town that nobody builds: cars and a bus on the street (they stop at the
-- crossings for anyone walking over), leaves and grass leaning with the wind, flags waving,
-- fountains spraying, traffic lights changing, boats bobbing, butterflies, rabbits and ducks,
-- and fireflies over the lawns at night. All of it is local to each player's screen: nothing
-- here is sent to the server or seen by anyone else.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Builder = require(Shared.Build.Builder)
local Town = require(Shared.Data.Town)
local TownMap = require(Shared.Data.TownMap)
local AmbientModels = require(Shared.Data.AmbientModels)
local Rng = require(Shared.Util.Rng)

local Ambience = {}

local L = Town.HalfLength
local LANE = 6.5
local CROSSINGS = { -274, 0, 274 }
local BUS_STOP_X = 96

local folder: Folder
local rng = Rng.new(31)
local clock = 0

-- One moving thing: its parts and where each sits relative to the model's origin.
type Mover = {
	parts: { BasePart },
	locals: { CFrame },
	wheels: { [number]: boolean }, -- indexes into parts
	wings: { [number]: Vector3 }, -- wing parts and the point they hinge on
}

local function mover(name: string, c1: Color3?, c2: Color3?, shadow: boolean): Mover
	local model = Instance.new("Model")
	model.Name = name
	local parts = Builder.instantiate(AmbientModels.prims(name, c1, c2), model, CFrame.identity)
	local m: Mover = { parts = {}, locals = {}, wheels = {}, wings = {} }
	for i, p in parts do
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = shadow
		m.parts[i] = p
		m.locals[i] = p.CFrame
		if p.Name == "Wheel" then
			m.wheels[i] = true
		elseif p.Name == "WingL" then
			m.wings[i] = Vector3.new(-0.3, 0, 0)
		elseif p.Name == "WingR" then
			m.wings[i] = Vector3.new(0.3, 0, 0)
		end
	end
	model.Parent = folder
	return m
end

local moveParts: { BasePart } = {}
local moveFrames: { CFrame } = {}

-- Queues a mover's parts at frame `cf`; wheels turn by `spin`, wings flap by `flap` radians.
local function place(m: Mover, cf: CFrame, spin: number?, flap: number?)
	for i, p in m.parts do
		local l = m.locals[i]
		if spin and m.wheels[i] then
			l = l * CFrame.Angles(spin, 0, 0)
		elseif flap and m.wings[i] then
			local hinge = m.wings[i]
			local a = if hinge.X < 0 then flap else -flap
			l = CFrame.new(hinge) * CFrame.Angles(0, 0, a) * CFrame.new(-hinge) * l
		end
		table.insert(moveParts, p)
		table.insert(moveFrames, cf * l)
	end
end

local function flush()
	if #moveParts > 0 then
		workspace:BulkMoveTo(moveParts, moveFrames, Enum.BulkMoveMode.FireCFrameChanged)
		table.clear(moveParts)
		table.clear(moveFrames)
	end
end

-- traffic -----------------------------------------------------------------------------------------

type Car = { m: Mover, x: number, dir: number, cruise: number, speed: number, spin: number, wait: number, bus: boolean }
local cars: { Car } = {}

local function addCar(x: number, dir: number, bus: boolean, color: Color3?)
	local m = mover(if bus then "bus" else "car", color, nil, true)
	table.insert(cars, {
		m = m,
		x = x,
		dir = dir,
		cruise = if bus then 14 else rng:float(18, 26),
		speed = 0,
		spin = 0,
		wait = 0,
		bus = bus,
	})
end

-- Crossings with someone on them right now (updated a few times a second).
local busy: { [number]: boolean } = {}

local function walkers(): { Vector3 }
	local out = {}
	for _, plr in Players:GetPlayers() do
		local root = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") then
			table.insert(out, root.Position)
		end
	end
	local plots = workspace:FindFirstChild("Plots")
	if plots then
		for _, plot in plots:GetChildren() do
			local villagers = plot:FindFirstChild("Villagers")
			if villagers then
				for _, npc in villagers:GetChildren() do
					local root = npc:FindFirstChild("HumanoidRootPart")
					if root and root:IsA("BasePart") then
						table.insert(out, root.Position)
					end
				end
			end
		end
	end
	return out
end

local function refreshCrossings()
	local people = walkers()
	for i, cx in CROSSINGS do
		busy[i] = false
		for _, p in people do
			if math.abs(p.X - cx) < 8 and math.abs(p.Z) < Town.StreetHalfWidth + 1 then
				busy[i] = true
			end
		end
	end
end

-- How far a car can go before it must stop (a busy crossing ahead, a car in front, its stop).
local function room(car: Car): number
	local best = math.huge
	for i, cx in CROSSINGS do
		if busy[i] then
			local stopLine = cx - car.dir * 10
			local d = (stopLine - car.x) * car.dir
			if d > -1 and d < best then
				best = d
			end
		end
	end
	for _, other in cars do
		if other ~= car and other.dir == car.dir then
			local gap = (other.x - car.x) * car.dir
			local length = if other.bus or car.bus then 16 else 11
			if gap > 0 and gap - length < best then
				best = gap - length
			end
		end
	end
	return best
end

local function stepCars(dt: number)
	for _, car in cars do
		if car.wait > 0 then
			car.wait -= dt
			car.speed = 0
		else
			local free = room(car)
			local target = if free < 3 then 0 elseif free < 18 then car.cruise * (free - 3) / 15 else car.cruise
			-- the bus pulls in at its stop on the south side every time round
			if car.bus and car.dir < 0 then
				local d = (BUS_STOP_X - car.x) * car.dir
				if d > 0 and d < 20 then
					target = math.min(target, car.cruise * d / 20 + 0.5)
				end
				if math.abs(car.x - BUS_STOP_X) < 0.6 then
					car.wait = 4
					car.x = BUS_STOP_X + car.dir * 0.7
				end
			end
			car.speed += (target - car.speed) * math.min(1, dt * 2.5)
			car.x += car.dir * car.speed * dt
		end
		if car.dir > 0 and car.x > L + 30 then
			car.x = -L - 30
		elseif car.dir < 0 and car.x < -L - 30 then
			car.x = L + 30
		end
		car.spin -= car.speed * dt / 0.8
		local z = car.dir * LANE
		local cf = CFrame.new(car.x, 0.05, z) * CFrame.Angles(0, if car.dir > 0 then math.pi / 2 else -math.pi / 2, 0)
		place(car.m, cf, car.spin)
	end
end

-- (Clouds drifted overhead and birds circled the square until the user asked: "remove clouds
-- and birds from the sky".)

-- swaying trees and waving flags ------------------------------------------------------------------------

type Sway = { parts: { BasePart }, locals: { CFrame }, base: CFrame, phase: number, amount: number, axis: string }
local sways: { Sway } = {}

-- spinning rides and the windmill: parts named "Spin" turn round the model's "Hub" (its X axis);
-- parts named "Cabin" go round with it but stay upright
type Spinner = {
	hub: CFrame,
	spin: { BasePart },
	spinLocal: { CFrame },
	cabins: { BasePart },
	cabinLocal: { Vector3 },
	cabinRot: { CFrame },
	speed: number,
}
local spinners: { Spinner } = {}
local SPEEDS = { ferrisWheel = 0.12, carousel = 0.5, windmill = 0.7 }

local function collectSpinner(model: Model)
	local hub = model:FindFirstChild("Hub", true)
	if not (hub and hub:IsA("BasePart")) then
		return
	end
	local s: Spinner = {
		hub = hub.CFrame,
		spin = {},
		spinLocal = {},
		cabins = {},
		cabinLocal = {},
		cabinRot = {},
		speed = SPEEDS[model.Name] or 0.3,
	}
	for _, p in model:GetDescendants() do
		if p:IsA("BasePart") then
			if p.Name == "Spin" then
				table.insert(s.spin, p)
				table.insert(s.spinLocal, hub.CFrame:ToObjectSpace(p.CFrame))
			elseif p.Name == "Cabin" then
				table.insert(s.cabins, p)
				table.insert(s.cabinLocal, hub.CFrame:PointToObjectSpace(p.Position))
				table.insert(s.cabinRot, p.CFrame - p.Position)
			end
		end
	end
	table.insert(spinners, s)
end

local function stepSpinners()
	local cam = workspace.CurrentCamera
	local eye = if cam then cam.CFrame.Position else Vector3.zero
	for _, s in spinners do
		if (s.hub.Position - eye).Magnitude < 400 then
			local turned = s.hub * CFrame.Angles(clock * s.speed, 0, 0)
			for i, p in s.spin do
				table.insert(moveParts, p)
				table.insert(moveFrames, turned * s.spinLocal[i])
			end
			for i, p in s.cabins do
				table.insert(moveParts, p)
				table.insert(moveFrames, CFrame.new(turned:PointToWorldSpace(s.cabinLocal[i])) * s.cabinRot[i])
			end
		end
	end
end

local function collectTown()
	table.clear(sways)
	table.clear(spinners)
	local town = workspace:FindFirstChild("Town")
	if not town then
		return
	end
	for _, model in town:GetChildren() do
		if model:IsA("Model") then
			local name = model.Name
			if SPEEDS[name] then
				collectSpinner(model)
			end
			if name == "tree" or name == "pine" or name == "streetTree" or name == "palm" or name == "palmTall" then
				local pivot = model:GetPivot()
				local base = CFrame.new(pivot.Position)
				local parts, locals = {}, {}
				for _, p in model:GetDescendants() do
					-- leaves sway; the trunk stays put
					if p:IsA("BasePart") and p.Position.Y > pivot.Position.Y + 4.5 then
						table.insert(parts, p)
						table.insert(locals, base:ToObjectSpace(p.CFrame))
					end
				end
				if #parts > 0 then
					table.insert(sways, {
						parts = parts,
						locals = locals,
						base = base,
						phase = rng:float(0, math.pi * 2),
						amount = if name == "pine" then 0.018 else 0.03,
						axis = "tree",
					})
				end
			elseif name == "marina" then
				-- each moored boat bobs on its own
				local groups: { [string]: { BasePart } } = {}
				for _, p in model:GetDescendants() do
					if p:IsA("BasePart") and p.Name:match("^Boat%d+$") then
						groups[p.Name] = groups[p.Name] or {}
						table.insert(groups[p.Name], p)
					end
				end
				for _, parts in groups do
					local centre = Vector3.zero
					for _, p in parts do
						centre += p.Position
					end
					local base = CFrame.new(centre / #parts)
					local locals = {}
					for _, p in parts do
						table.insert(locals, base:ToObjectSpace(p.CFrame))
					end
					table.insert(sways, {
						parts = parts,
						locals = locals,
						base = base,
						phase = rng:float(0, math.pi * 2),
						amount = 0.035,
						axis = "bob",
					})
				end
			elseif name == "flagpole" then
				local pivot = model:GetPivot()
				local parts, locals = {}, {}
				for _, p in model:GetDescendants() do
					if p:IsA("BasePart") and p.Name == "Flag" then
						table.insert(parts, p)
						table.insert(locals, pivot:ToObjectSpace(p.CFrame))
					end
				end
				if #parts > 0 then
					table.insert(sways, {
						parts = parts,
						locals = locals,
						base = pivot,
						phase = rng:float(0, math.pi * 2),
						amount = 0.25,
						axis = "flag",
					})
				end
			end
		end
	end
end

local swayClock = 0
local function stepSway(dt: number)
	swayClock += dt
	if swayClock < 1 / 15 then
		return
	end
	swayClock = 0
	local cam = workspace.CurrentCamera
	local eye = if cam then cam.CFrame.Position else Vector3.zero
	local breeze = if workspace:GetAttribute("Weather") == "storm" then 2.5 else 1
	for _, s in sways do
		if (s.base.Position - eye).Magnitude < 260 then
			local a = math.sin(clock * 1.4 + s.phase) * s.amount * breeze
			local rot
			if s.axis == "flag" then
				rot = CFrame.Angles(0, a + math.sin(clock * 3.1 + s.phase) * 0.08, 0)
			elseif s.axis == "bob" then
				-- up and down on the swell, rolling a little
				rot = CFrame.new(0, math.sin(clock * 1.1 + s.phase) * 0.18, 0)
					* CFrame.Angles(a * 0.4, 0, math.sin(clock * 0.9 + s.phase * 2) * 0.05)
			else
				rot = CFrame.Angles(a, 0, a * 0.6)
			end
			for i, p in s.parts do
				table.insert(moveParts, p)
				table.insert(moveFrames, s.base * rot * s.locals[i])
			end
		end
	end
end

-- the fountain and the fireflies ----------------------------------------------------------------------

local fireflies: { ParticleEmitter } = {}

local function addEffects()
	local town = workspace:FindFirstChild("Town")
	local fountain = town and town:FindFirstChild("fountain")
	local spout = fountain and fountain:FindFirstChild("Spout", true)
	if spout and spout:IsA("BasePart") then
		local spray = Instance.new("ParticleEmitter")
		spray.Name = "Spray"
		spray.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		spray.Color = ColorSequence.new(Color3.fromRGB(200, 235, 255), Color3.fromRGB(150, 210, 250))
		spray.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.5),
			NumberSequenceKeypoint.new(1, 0.15),
		})
		spray.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.2),
			NumberSequenceKeypoint.new(1, 1),
		})
		spray.Lifetime = NumberRange.new(0.9, 1.3)
		spray.Rate = 70
		spray.Speed = NumberRange.new(9, 13)
		spray.SpreadAngle = Vector2.new(14, 14)
		spray.Acceleration = Vector3.new(0, -26, 0)
		spray.EmissionDirection = Enum.NormalId.Top
		spray.LightEmission = 0.4
		spray.Parent = spout
	end
	for _, l in TownMap.lawns() do
		local p = Instance.new("Part")
		p.Name = "Fireflies"
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.Transparency = 1
		p.Size = Vector3.new(l[3] * 2, 3, l[4] * 2)
		p.CFrame = CFrame.new(l[1], 2.5, l[2])
		p.Parent = folder
		local e = Instance.new("ParticleEmitter")
		e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		e.Color = ColorSequence.new(Color3.fromRGB(255, 240, 140), Color3.fromRGB(200, 255, 120))
		e.LightEmission = 1
		e.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(0.3, 0.35),
			NumberSequenceKeypoint.new(1, 0),
		})
		e.Lifetime = NumberRange.new(2.5, 4)
		e.Rate = 6
		e.Speed = NumberRange.new(0.3, 1)
		e.SpreadAngle = Vector2.new(180, 180)
		e.Enabled = false
		e.Parent = p
		table.insert(fireflies, e)
	end
end

local function nightEffects()
	local h = Lighting.ClockTime
	local night = h < 5.5 or h > 19.5
	for _, e in fireflies do
		e.Enabled = night
	end
end

-- life: leaves, grass, creatures and moving details -----------------------------------------------------
--
-- The user: "Make the world alot more lively, such as animated blades of grass, animated details,
-- small creatures, trees with leaves that sway with the wind, etc." All of it is drawn on this
-- player's screen only, near where they are, and moved in the one batch the cars use.

-- where the player is (their character, or the camera when there is none yet)
local function here(): Vector3
	local char = Players.LocalPlayer and Players.LocalPlayer.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		return root.Position
	end
	local cam = workspace.CurrentCamera
	return if cam then cam.CFrame.Position else Vector3.zero
end

-- The wind: a slow wave that crosses the island, so things lean one after another, not all at
-- once, with a quicker flutter on top. Stronger in a storm.
local function wind(at: Vector3, phase: number): number
	local gust = if workspace:GetAttribute("Weather") == "storm" then 2.4 else 1
	local wave = math.sin(clock * 0.9 + at.X * 0.035 + at.Z * 0.021)
	return (wave * 0.7 + math.sin(clock * 2.3 + phase) * 0.3) * gust
end

-- Leaves: every clump of leaves in town (parts named Leaf: tree crowns, pine tiers, shrubs) leans
-- with the wind round a point under it. Signs that hang (SwingSign) swing from their top edge.
type Leaf = { part: BasePart, rest: CFrame, pivot: Vector3, phase: number, amount: number }
local leaves: { Leaf } = {}

local function collectLeaves(town: Instance)
	table.clear(leaves)
	for _, p in town:GetDescendants() do
		if p:IsA("BasePart") then
			if p.Name == "Leaf" then
				table.insert(leaves, {
					part = p,
					rest = p.CFrame,
					pivot = p.CFrame.Position - Vector3.new(0, p.Size.Y * 0.8, 0),
					phase = rng:float(0, math.pi * 2),
					amount = 0.05,
				})
			elseif p.Name == "SwingSign" then
				table.insert(leaves, {
					part = p,
					rest = p.CFrame,
					pivot = p.CFrame.Position + Vector3.new(0, p.Size.Y / 2, 0),
					phase = rng:float(0, math.pi * 2),
					amount = 0.12,
				})
			end
		end
	end
end

local leafClock = 0
local function stepLeaves(dt: number)
	leafClock += dt
	if leafClock < 1 / 15 then
		return
	end
	leafClock = 0
	local eye = here()
	for _, l in leaves do
		local d = l.pivot - eye
		if d.X * d.X + d.Z * d.Z < 190 * 190 then
			local a = wind(l.pivot, l.phase) * l.amount
			local turn = CFrame.new(l.pivot) * CFrame.Angles(a, 0, a * 0.7) * CFrame.new(-l.pivot)
			table.insert(moveParts, l.part)
			table.insert(moveFrames, turn * l.rest)
		end
	end
end

-- Traffic lights: the two at a junction take turns (one hangs over each road). Green, a moment
-- of amber, then red while the other road goes.
type Signal = { red: BasePart, amber: BasePart, green: BasePart, across: boolean }
local signals: { Signal } = {}
local RED, AMBER, GREEN = Color3.fromRGB(240, 80, 70), Color3.fromRGB(250, 200, 80), Color3.fromRGB(90, 220, 120)
local DIM = 0.28

local function collectSignals(town: Instance)
	table.clear(signals)
	for _, model in town:GetChildren() do
		if model.Name == "trafficLight" then
			local red, amber, green =
				model:FindFirstChild("Red"), model:FindFirstChild("Amber"), model:FindFirstChild("Green")
			if red and amber and green and red:IsA("BasePart") and amber:IsA("BasePart") and green:IsA("BasePart") then
				-- which road it hangs over: its arm reaches from the pole toward the lamps
				local arm = red.CFrame.Position - (model :: Model):GetPivot().Position
				table.insert(
					signals,
					{ red = red, amber = amber, green = green, across = math.abs(arm.X) > math.abs(arm.Z) }
				)
			end
		end
	end
end

local function lamp(p: BasePart, color: Color3, on: boolean)
	p.Material = if on then Enum.Material.Neon else Enum.Material.SmoothPlastic
	p.Color = if on then color else Color3.new(color.R * DIM, color.G * DIM, color.B * DIM)
end

local signalStep = -1
local function stepSignals()
	local CYCLE = 24
	local t = clock % CYCLE
	-- 0..10 one road green, 10..12 amber, 12..22 the other green, 22..24 amber
	local step = if t < 10 then 0 elseif t < 12 then 1 elseif t < 22 then 2 else 3
	if step == signalStep then
		return
	end
	signalStep = step
	for _, s in signals do
		local mine = if s.across then step else (step + 2) % 4
		lamp(s.green, GREEN, mine == 0)
		lamp(s.amber, AMBER, mine == 1)
		lamp(s.red, RED, mine >= 2)
	end
end

-- Things on the water bob: buoys, boats at anchor, rowing boats pulled half up the sand.
local FLOATS = { buoy = 0.3, sailboat = 0.22, sailboat2 = 0.22, rowboat = 0.08 }

local function collectFloats(town: Instance)
	for _, model in town:GetChildren() do
		local rise = FLOATS[model.Name]
		if rise and model:IsA("Model") then
			local base = CFrame.new(model:GetPivot().Position)
			local parts, locals = {}, {}
			for _, p in model:GetDescendants() do
				if p:IsA("BasePart") then
					table.insert(parts, p)
					table.insert(locals, base:ToObjectSpace(p.CFrame))
				end
			end
			table.insert(sways, {
				parts = parts,
				locals = locals,
				base = base,
				phase = rng:float(0, math.pi * 2),
				amount = rise * 0.16,
				axis = "bob",
			})
		end
	end
end

-- Water spraying from every small fountain's jet.
local function collectJets(town: Instance)
	local made = 0
	for _, p in town:GetDescendants() do
		if p:IsA("BasePart") and p.Name == "Jet" and made < 40 then
			made += 1
			local spray = Instance.new("ParticleEmitter")
			spray.Name = "Spray"
			spray.Texture = "rbxasset://textures/particles/sparkles_main.dds"
			spray.Color = ColorSequence.new(Color3.fromRGB(210, 238, 255))
			spray.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 0.1) })
			spray.Transparency =
				NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1) })
			spray.Lifetime = NumberRange.new(0.6, 0.9)
			spray.Rate = 26
			spray.Speed = NumberRange.new(5, 7)
			spray.SpreadAngle = Vector2.new(22, 22)
			spray.Acceleration = Vector3.new(0, -22, 0)
			-- the jet is a cylinder stood on end: its own +X points up
			spray.EmissionDirection = Enum.NormalId.Right
			spray.LightEmission = 0.3
			spray.Parent = p
		end
	end
end

-- Grass: tufts of blades on the lawns round the player, each leaning with the wind. There is a
-- fixed number of them; a tuft the player has walked away from is moved to fresh grass ahead.
type Tuft = { blades: { BasePart }, at: Vector3, yaw: number, phase: number, tall: number, live: boolean }
local tufts: { Tuft } = {}
local TUFTS = 150
local GRASS_REACH = 85
local GREENS = { Color3.fromRGB(104, 160, 66), Color3.fromRGB(126, 182, 78), Color3.fromRGB(88, 142, 60) }
local PETALS = { Color3.fromRGB(255, 236, 130), Color3.fromRGB(255, 170, 190), Color3.fromRGB(250, 250, 250) }

local groundParams: RaycastParams? = nil

-- The ground at x, z if it is grass (and what it is, to stay off the grass of someone's roof).
local function grassAt(x: number, z: number, from: number): Vector3?
	if not groundParams then
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = { folder }
		groundParams = params
	end
	local hit = workspace:Raycast(Vector3.new(x, from + 40, z), Vector3.new(0, -120, 0), groundParams :: RaycastParams)
	if hit and hit.Material == Enum.Material.Grass and hit.Normal.Y > 0.82 then
		return hit.Position
	end
	return nil
end

local function makeTuft(): Tuft
	local blades = {}
	local model = Instance.new("Model")
	model.Name = "grass"
	for i = 1, 3 do
		local b = Instance.new("WedgePart")
		b.Name = "Blade"
		b.Anchored = true
		b.CanCollide = false
		b.CanQuery = false
		b.CanTouch = false
		b.CastShadow = false
		b.Material = Enum.Material.SmoothPlastic
		b.Color = GREENS[(i + #tufts) % #GREENS + 1]
		b.Size = Vector3.new(0.14, 1, 0.42)
		b.Parent = model
		blades[i] = b
	end
	-- one tuft in five has a flower in it
	if #tufts % 5 == 0 then
		local f = Instance.new("Part")
		f.Name = "Blade"
		f.Shape = Enum.PartType.Ball
		f.Anchored = true
		f.CanCollide = false
		f.CanQuery = false
		f.CanTouch = false
		f.CastShadow = false
		f.Material = Enum.Material.SmoothPlastic
		f.Color = PETALS[(#tufts // 5) % #PETALS + 1]
		f.Size = Vector3.new(0.42, 0.42, 0.42)
		f.Parent = model
		blades[4] = f
	end
	model.Parent = folder
	return { blades = blades, at = Vector3.zero, yaw = 0, phase = rng:float(0, 6.28), tall = 1, live = false }
end

-- Moves up to a few tufts that are out of reach onto grass near the player.
local function tendGrass()
	local eye = here()
	local moved = 0
	for _, t in tufts do
		if moved >= 10 then
			break
		end
		local d = t.at - eye
		if not t.live or d.X * d.X + d.Z * d.Z > (GRASS_REACH + 12) ^ 2 then
			moved += 1
			local a, r = rng:float(0, math.pi * 2), math.sqrt(rng:float(0.03, 1)) * GRASS_REACH
			local spot = grassAt(eye.X + math.cos(a) * r, eye.Z + math.sin(a) * r, eye.Y)
			if spot then
				t.at = spot
				t.yaw = rng:float(0, math.pi * 2)
				t.tall = rng:float(0.8, 1.5)
				t.live = true
				for i, b in t.blades do
					if i <= 3 then
						b.Size = Vector3.new(0.14, t.tall * (1.15 - i * 0.12), 0.42)
					end
				end
			elseif t.live then
				-- nowhere to go this time: hide it until there is
				t.live = false
				for _, b in t.blades do
					table.insert(moveParts, b)
					table.insert(moveFrames, CFrame.new(0, -200, 0))
				end
			end
		end
	end
end

local grassClock, tendClock = 0, 0
local function stepGrass(dt: number)
	tendClock += dt
	if tendClock > 0.35 then
		tendClock = 0
		if #tufts < TUFTS then
			for _ = 1, 15 do
				if #tufts < TUFTS then
					table.insert(tufts, makeTuft())
				end
			end
		end
		tendGrass()
	end
	grassClock += dt
	if grassClock < 1 / 20 then
		return
	end
	grassClock = 0
	for _, t in tufts do
		if t.live then
			local lean = wind(t.at, t.phase) * 0.22
			local base = CFrame.new(t.at) * CFrame.Angles(0, t.yaw, 0)
			for i, b in t.blades do
				if i <= 3 then
					-- three blades fanned out, each hinged at the ground
					local fan = CFrame.Angles(0, (i - 2) * 2.1, 0) * CFrame.Angles(0.28 + lean, 0, lean * 0.5)
					table.insert(moveParts, b)
					table.insert(moveFrames, base * fan * CFrame.new(0, b.Size.Y / 2, 0))
				else
					local tip = base * CFrame.Angles(lean, 0, lean * 0.5) * CFrame.new(0, t.tall * 1.1, 0)
					table.insert(moveParts, b)
					table.insert(moveFrames, tip)
				end
			end
		end
	end
end

-- Butterflies: a handful near the player, each wandering round a spot of grass, wings going.
type Butterfly = { m: Mover, home: Vector3, phase: number, speed: number, reach: number }
local butterflies: { Butterfly } = {}
local WINGS = {
	Color3.fromRGB(255, 196, 70),
	Color3.fromRGB(255, 140, 170),
	Color3.fromRGB(130, 190, 255),
	Color3.fromRGB(250, 250, 250),
	Color3.fromRGB(190, 150, 240),
}

local function stepButterflies()
	local eye = here()
	local day = Lighting.ClockTime > 6 and Lighting.ClockTime < 19
	for i, b in butterflies do
		local d = b.home - eye
		if d.X * d.X + d.Z * d.Z > 70 * 70 then
			-- too far behind: find it a new patch of grass near the player
			local a, r = rng:float(0, math.pi * 2), rng:float(10, 45)
			local spot = grassAt(eye.X + math.cos(a) * r, eye.Z + math.sin(a) * r, eye.Y)
			if spot then
				b.home = spot
			end
		end
		local t = clock * b.speed + b.phase
		-- a wandering loop with a bob in it; gone to bed at night
		local pos = b.home
			+ Vector3.new(
				math.sin(t) * b.reach + math.sin(t * 2.7) * 1.2,
				2 + math.sin(t * 3.1) * 0.8 + (if day then 0 else -300),
				math.cos(t * 0.8) * b.reach + math.cos(t * 2.3) * 1.2
			)
		local ahead = Vector3.new(math.cos(t) * b.reach, 0, -math.sin(t * 0.8) * b.reach * 0.8)
		local cf = if ahead.Magnitude > 0.01 then CFrame.lookAt(pos, pos - ahead) else CFrame.new(pos)
		place(b.m, cf, nil, 0.25 + math.abs(math.sin(clock * 16 + i)) * 1.1)
	end
end

-- Rabbits: they sit, look about, then hop a little way across the grass.
type Rabbit = { m: Mover, at: Vector3, from: Vector3, to: Vector3, t: number, wait: number, yaw: number }
local rabbits: { Rabbit } = {}
local FUR = { Color3.fromRGB(214, 190, 160), Color3.fromRGB(240, 236, 228), Color3.fromRGB(150, 130, 116) }

local function stepRabbits(dt: number)
	local eye = here()
	for i, r in rabbits do
		local d = r.at - eye
		local far = d.X * d.X + d.Z * d.Z
		if far > 110 * 110 or r.at.Y < -100 then
			-- left behind: turn up again somewhere on the grass near the player, out of the way
			local a, dist = rng:float(0, math.pi * 2), rng:float(35, 70)
			local spot = grassAt(eye.X + math.cos(a) * dist, eye.Z + math.sin(a) * dist, eye.Y)
			if spot then
				r.at, r.from, r.to, r.t, r.wait = spot, spot, spot, 1, rng:float(0.5, 3)
			end
		elseif r.t >= 1 then
			r.wait -= dt
			if r.wait <= 0 then
				-- away from the player if they are close, anywhere otherwise
				local a = if far < 14 * 14
					then math.atan2(d.Z, d.X) + rng:float(-0.6, 0.6)
					else rng:float(0, math.pi * 2)
				local hop = rng:float(3, 5.5)
				local spot = grassAt(r.at.X + math.cos(a) * hop, r.at.Z + math.sin(a) * hop, r.at.Y)
				if spot and math.abs(spot.Y - r.at.Y) < 2.5 then
					r.from, r.to, r.t = r.at, spot, 0
					r.yaw = math.atan2(spot.X - r.at.X, spot.Z - r.at.Z)
					r.wait = if far < 14 * 14 then 0.05 else rng:float(0.2, 2.6)
				else
					r.wait = 0.4
				end
			end
		else
			r.t = math.min(1, r.t + dt * 3.2)
			r.at = r.from:Lerp(r.to, r.t)
		end
		local up = math.sin(math.clamp(r.t, 0, 1) * math.pi) * 1.1
		-- nose twitching while it sits: a tiny nod
		local nod = if r.t >= 1 then math.sin(clock * 5 + i) * 0.05 else -0.25
		place(r.m, CFrame.new(r.at + Vector3.new(0, up, 0)) * CFrame.Angles(0, r.yaw, 0) * CFrame.Angles(nod, 0, 0))
	end
end

-- Ducks: a few on the pond in the park and the lake in the hills, paddling slow circles.
type Duck = { m: Mover, center: Vector3, radius: number, angle: number, speed: number }
local ducks: { Duck } = {}

local function collectDucks(town: Instance)
	if #ducks > 0 then
		return
	end
	local ponds: { { any } } = {}
	for _, model in town:GetChildren() do
		if model:IsA("Model") then
			local pivot = model:GetPivot()
			if model.Name == "pondPark" then
				table.insert(ponds, { pivot * Vector3.new(-10, 0.5, 0), 24, 4 })
			elseif model.Name == "tarn" then
				table.insert(ponds, { pivot * Vector3.new(0, 0.5, 0), 22, 3 })
			elseif model.Name == "pocketPond" then
				table.insert(ponds, { pivot * Vector3.new(0, 0.42, 0), 6, 1 })
			end
		end
	end
	for _, pond in ponds do
		for k = 1, pond[3] do
			local white = (k + #ducks) % 3 == 0
			table.insert(ducks, {
				m = mover(
					"duck",
					if white then Color3.fromRGB(250, 250, 246) else Color3.fromRGB(150, 116, 84),
					if white then Color3.fromRGB(250, 250, 246) else Color3.fromRGB(56, 130, 96),
					false
				),
				center = pond[1],
				radius = pond[2] * rng:float(0.35, 0.8),
				angle = rng:float(0, math.pi * 2),
				speed = rng:float(0.12, 0.22) * (if k % 2 == 0 then 1 else -1),
			})
		end
	end
end

local function stepDucks(dt: number)
	local eye = here()
	for i, d in ducks do
		if (d.center - eye).Magnitude < 260 then
			d.angle += d.speed * dt
			local pos = d.center
				+ Vector3.new(
					math.cos(d.angle) * d.radius,
					math.sin(clock * 2 + i) * 0.05,
					math.sin(d.angle) * d.radius
				)
			local ahead = Vector3.new(-math.sin(d.angle), 0, math.cos(d.angle)) * math.sign(d.speed)
			place(d.m, CFrame.lookAt(pos, pos - ahead) * CFrame.Angles(0, 0, math.sin(clock * 1.6 + i) * 0.06))
		end
	end
end

local function startCreatures()
	for i = 1, 14 do
		table.insert(butterflies, {
			m = mover("butterfly", WINGS[i % #WINGS + 1], nil, false),
			home = Vector3.new(0, -500, 0),
			phase = rng:float(0, 20),
			speed = rng:float(0.5, 0.9),
			reach = rng:float(3, 7),
		})
	end
	for i = 1, 7 do
		local away = Vector3.new(0, -500, 0)
		table.insert(rabbits, {
			m = mover("rabbit", FUR[i % #FUR + 1], nil, false),
			at = away,
			from = away,
			to = away,
			t = 1,
			wait = 0,
			yaw = 0,
		})
	end
end

local function stepLife(dt: number)
	stepLeaves(dt)
	stepSignals()
	stepGrass(dt)
	stepButterflies()
	stepRabbits(dt)
	stepDucks(dt)
end

-- starting -------------------------------------------------------------------------------------------

function Ambience.start()
	folder = Instance.new("Folder")
	folder.Name = "Ambience"
	folder.Parent = workspace

	-- traffic both ways, and the bus
	local colors = AmbientModels.CarColors
	for i = 1, 4 do
		addCar(-L + i * 240 + rng:float(-40, 40), 1, false, colors[(i - 1) % #colors + 1])
		addCar(L - i * 240 + rng:float(-40, 40), -1, false, colors[(i + 2) % #colors + 1])
	end
	addCar(L - 60, -1, true)

	-- the town's trees, flags and fountain arrive from the server: gather them once it's here
	task.spawn(function()
		local town = workspace:WaitForChild("Town", 30)
		if not town then
			return
		end
		task.wait(3)
		collectTown()
		addEffects()
		collectLeaves(town)
		collectSignals(town)
		collectFloats(town)
		collectJets(town)
		collectDucks(town)
	end)
	startCreatures()

	local crossingClock = 0
	local nightClock = 0
	RunService.Heartbeat:Connect(function(dt)
		clock += dt
		crossingClock += dt
		if crossingClock > 0.3 then
			crossingClock = 0
			refreshCrossings()
		end
		nightClock += dt
		if nightClock > 2 then
			nightClock = 0
			nightEffects()
		end
		stepCars(dt)
		stepSway(dt)
		stepSpinners()
		stepLife(dt)
		flush()
	end)
end

return Ambience
