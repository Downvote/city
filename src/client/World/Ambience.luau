-- Life around town that nobody builds: cars and a bus on the street (they stop at the
-- crossings for anyone walking over), clouds drifting overhead with their shadows sliding
-- across town, birds circling the square, trees swaying, flags waving, the fountain spraying
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

-- clouds and birds ------------------------------------------------------------------------------------

type Cloud = { m: Mover, x: number, y: number, z: number, speed: number }
local clouds: { Cloud } = {}

local function stepClouds(dt: number)
	for _, c in clouds do
		c.x += c.speed * dt
		if c.x > L + 260 then
			c.x = -L - 260
		end
		place(c.m, CFrame.new(c.x, c.y, c.z))
	end
end

local function tintClouds()
	local w = workspace:GetAttribute("Weather")
	local grey = w == "rain" or w == "storm" or w == "cloudy"
	local color = if w == "storm"
		then Color3.fromRGB(150, 150, 165)
		elseif grey then Color3.fromRGB(205, 208, 218)
		else Color3.fromRGB(255, 255, 255)
	for _, c in clouds do
		for _, p in c.m.parts do
			p.Color = color
		end
	end
end

type Bird = { m: Mover, center: Vector3, radius: number, angle: number, speed: number, height: number, phase: number }
local birds: { Bird } = {}

local function stepBirds(dt: number)
	for _, b in birds do
		b.angle += b.speed * dt
		local x = b.center.X + math.cos(b.angle) * b.radius
		local z = b.center.Z + math.sin(b.angle) * b.radius
		local y = b.height + math.sin(clock * 0.8 + b.phase) * 2
		-- facing along the circle
		local ahead = Vector3.new(-math.sin(b.angle), 0, math.cos(b.angle)) * math.sign(b.speed)
		local pos = Vector3.new(x, y, z)
		local cf = CFrame.lookAt(pos, pos + ahead)
			* CFrame.Angles(0, math.pi, 0)
			* CFrame.Angles(0, 0, 0.25 * math.sign(b.speed))
		place(b.m, cf, nil, math.sin(clock * 14 + b.phase) * 0.6)
	end
end

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

	for _ = 1, 12 do
		local c = {
			m = mover("cloud", nil, nil, true),
			x = rng:float(-L - 260, L + 260),
			y = rng:float(150, 200),
			z = rng:float(-320, 320),
			speed = rng:float(2.5, 5),
		}
		local scale = rng:float(0.9, 1.6)
		for i, l in c.m.locals do
			c.m.locals[i] = CFrame.new(l.Position * scale) * l.Rotation
			local p = c.m.parts[i]
			p.Size *= scale
		end
		table.insert(clouds, c)
	end
	tintClouds()
	workspace:GetAttributeChangedSignal("Weather"):Connect(tintClouds)

	local birdColors = {
		{ Color3.fromRGB(90, 150, 230), Color3.fromRGB(60, 110, 190) },
		{ Color3.fromRGB(240, 120, 90), Color3.fromRGB(200, 80, 60) },
		{ Color3.fromRGB(250, 250, 250), Color3.fromRGB(200, 205, 215) },
	}
	for flock = 1, 2 do
		local center = if flock == 1 then Town.SquareCenter + Vector3.new(0, 0, 10) else Town.MarketCenter
		for i = 1, 5 do
			local col = birdColors[(i + flock) % #birdColors + 1]
			table.insert(birds, {
				m = mover("bird", col[1], col[2], false),
				center = center + Vector3.new(rng:float(-6, 6), 0, rng:float(-6, 6)),
				radius = rng:float(34, 58),
				angle = rng:float(0, math.pi * 2),
				speed = (if flock == 1 then 1 else -1) * rng:float(0.35, 0.5),
				height = rng:float(38, 52),
				phase = rng:float(0, 10),
			})
		end
	end

	-- the town's trees, flags and fountain arrive from the server: gather them once it's here
	task.spawn(function()
		local town = workspace:WaitForChild("Town", 30)
		if not town then
			return
		end
		task.wait(3)
		collectTown()
		addEffects()
	end)

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
		stepClouds(dt)
		stepBirds(dt)
		stepSway(dt)
		stepSpinners()
		flush()
	end)
end

return Ambience
