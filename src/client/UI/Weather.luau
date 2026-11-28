-- The weather on this player's own screen, round the camera (the user: "could you use better
-- weather effects?"). Data/Weather says what falls: rain as streaks in three depths with splashes
-- and rings where it lands and puddles on hard ground open to the sky, softly falling snow, mist
-- drifting low in fog, petals in blossom and leaves turning over as they come down; spring's
-- petals and autumn's leaves drift a little whatever the weather. A storm adds lightning: a flash
-- and a bolt far off. The air (the haze) eases to the weather's here too, so a player who turned
-- the haze off in Settings keeps clear air. How much is drawn follows their detail level
-- (World/Graphics). Nothing here is seen by anyone else.
--
-- (Before: one emitter of specks over a square, every setting put on by itself so one Roblox
-- refused couldn't stop the rest; that care stays: `set` puts each on in a pcall.)

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Tuning = require(Shared.Config.Tuning)
local Data = require(Shared.Data.Weather)
local Seasons = require(Shared.Data.Seasons)
local Rules = require(Shared.Sim.Graphics)

local Graphics = require(script.Parent.Parent.World.Graphics)
local Audio = require(script.Parent.Parent.Controllers.Audio)
local ViewTime = require(script.Parent.Parent.Build.ViewTime) -- (clear weather while the creator is open)

local Weather = {}

local K = Tuning.Weather
local MOST_RATE = 400 -- the most one emitter is given a second (a layer past it is split)

local folder: Folder? = nil
local boxes: { [string]: Part } = {}
local rings: { [string]: { Part } } = {} -- a ring box's four parts (Data/Weather.ringParts)
local cells: { Part } = {}
local emitters: { { e: ParticleEmitter, box: string } } = {}
local sheltered = false
local drawnKey = ""

local function kindNow(): string
	local w = workspace:GetAttribute("Weather")
	return if Data.known(w) then w :: string else "clear"
end

local function seasonNow(): number
	local s = workspace:GetAttribute("Season")
	return if type(s) == "number" then s else 1
end

local function set(e: Instance, key: string, value: any)
	local ok, why = pcall(function()
		(e :: any)[key] = value
	end)
	if not ok then
		warn("[Weather] couldn't set " .. key .. ": " .. tostring(why))
	end
end

local function sequence(values: { number }): NumberSequence
	if #values == 1 then
		return NumberSequence.new(values[1])
	end
	local points = {}
	for i, v in values do
		table.insert(points, NumberSequenceKeypoint.new((i - 1) / (#values - 1), v))
	end
	return NumberSequence.new(points)
end

local function range(r: { number }?, default: number): NumberRange
	if not r then
		return NumberRange.new(default)
	end
	return NumberRange.new(r[1], r[2] or r[1])
end

local function hidden(name: string, size: Vector3): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Transparency = 1
	p.Size = size
	p.Parent = folder
	return p
end

-- One emitter of a layer, on `holder`, with a share of its rate.
local function emitter(layer: Data.Layer, holder: BasePart, color: Color3, rate: number): ParticleEmitter
	local e = Instance.new("ParticleEmitter")
	e.Name = "Weather"
	e.Enabled = false
	set(e, "Texture", Data.Textures[layer.texture] or Data.Textures.dot)
	set(e, "Color", ColorSequence.new(color))
	set(e, "Size", sequence(layer.size))
	set(e, "Transparency", sequence(layer.transp))
	set(e, "Lifetime", range(layer.life, 1))
	set(e, "Rate", rate)
	set(e, "Speed", range(layer.speed, 1))
	set(e, "SpreadAngle", Vector2.new(layer.spread[1], layer.spread[2] or layer.spread[1]))
	set(e, "Acceleration", layer.accel or Vector3.zero)
	set(e, "Drag", layer.drag or 0)
	set(e, "Rotation", range(layer.rot, 0))
	set(e, "RotSpeed", range(layer.spin, 0))
	set(e, "LightEmission", layer.light or 0)
	set(e, "LightInfluence", 0.6)
	local box = Data.Boxes[layer.box]
	set(e, "EmissionDirection", if layer.box == "ground" then Enum.NormalId.Top else Enum.NormalId.Bottom)
	if box and box.volume then
		set(e, "ShapeStyle", Enum.ParticleEmitterShapeStyle.Volume)
	end
	if layer.orient == "streak" then
		-- upright, facing the camera: the streak's picture is a vertical line, and VelocityParallel
		-- would lay its left to right along the fall (the rain fell as sideways dashes)
		set(e, "Orientation", Enum.ParticleOrientation.FacingCameraWorldUp)
	elseif layer.orient == "flat" then
		set(e, "Orientation", Enum.ParticleOrientation.VelocityPerpendicular)
	else
		set(e, "Orientation", Enum.ParticleOrientation.FacingCamera)
	end
	if layer.flip then
		set(
			e,
			"FlipbookLayout",
			if layer.flip == 8 then Enum.ParticleFlipbookLayout.Grid8x8 else Enum.ParticleFlipbookLayout.Grid4x4
		)
		set(e, "FlipbookMode", Enum.ParticleFlipbookMode.Loop)
		set(e, "FlipbookFramerate", range(layer.flipFps, 10))
		set(e, "FlipbookStartRandom", true)
	end
	e.Parent = holder
	return e
end

local function clear()
	for _, x in emitters do
		x.e:Destroy()
	end
	table.clear(emitters)
end

-- What should fall now: the weather's layers at this screen's detail, and the season's drift.
local function layersNow(): { Data.Layer }
	local level = Graphics.level()
	local look = Seasons.at(seasonNow())
	return Data.drawn(kindNow(), level.Layers, level.Particles, look.air, K.SeasonAir)
end

-- Whether the weather stands down on this screen: something wants a clear day (the creator: the
-- user, "weather effects and time seems to affect the avatar creator"; Build/ViewTime.clear).
local function calm(): boolean
	return ViewTime.clear()
end

local function enableAll()
	local still = calm()
	for _, x in emitters do
		x.e.Enabled = not still and (x.box == "ground" or not sheltered)
	end
end

-- Makes the emitters for what falls now (again, when the weather, the season or the detail changes).
local function draw()
	local level = Graphics.level()
	local key = kindNow() .. ":" .. seasonNow() .. ":" .. level.Layers .. ":" .. level.Particles
	if key == drawnKey then
		return
	end
	drawnKey = key
	clear()
	for _, layer in layersNow() do
		local holders: { BasePart } = {}
		-- (a ring's four parts share its rate by their size; a patch of ground gets it all)
		local shares: { number } = {}
		if layer.box == "ground" then
			for _, c in cells do
				table.insert(holders, c)
				table.insert(shares, 1)
			end
		elseif rings[layer.box] then
			local total = 0
			for _, p in rings[layer.box] do
				total += p.Size.X * p.Size.Z
			end
			for _, p in rings[layer.box] do
				table.insert(holders, p)
				table.insert(shares, p.Size.X * p.Size.Z / math.max(total, 1))
			end
		elseif boxes[layer.box] then
			table.insert(holders, boxes[layer.box])
			table.insert(shares, 1)
		end
		local colors = layer.colors
		for h, holder in holders do
			local rate = layer.rate * shares[h] / #colors
			local pieces = math.max(1, math.ceil(rate / MOST_RATE))
			for _, color in colors do
				for _ = 1, pieces do
					table.insert(emitters, { e = emitter(layer, holder, color, rate / pieces), box = layer.box })
				end
			end
		end
	end
	enableAll()
end

-- Is there a roof (or anything solid) over the camera? Nothing falls indoors.
local function underRoof(at: Vector3): boolean
	local skip: { Instance } = {}
	if folder then
		table.insert(skip, folder)
	end
	local char = Players.LocalPlayer and Players.LocalPlayer.Character
	if char then
		table.insert(skip, char)
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = skip
	local hit = workspace:Raycast(at, Vector3.new(0, 60, 0), params)
	return hit ~= nil and (hit.Instance :: BasePart).Transparency < 0.9
end

local groundParams = RaycastParams.new()
groundParams.FilterType = Enum.RaycastFilterType.Exclude
groundParams.IgnoreWater = false

local function skipList(): { Instance }
	local skip: { Instance } = {}
	if folder then
		table.insert(skip, folder)
	end
	for _, p in Players:GetPlayers() do
		if p.Character then
			table.insert(skip, p.Character)
		end
	end
	return skip
end

-- The rain's patches of ground: a square of them round the camera, each set on whatever is under
-- its middle (a road, a roof, a hill, the sea), so the splashes land where the rain does.
local function placeCells(at: Vector3)
	groundParams.FilterDescendantsInstances = skipList()
	local n, size = K.Cells, K.Cell
	local x0 = math.floor(at.X / size) * size - (n - 1) / 2 * size
	local z0 = math.floor(at.Z / size) * size - (n - 1) / 2 * size
	for i, cell in cells do
		local gx, gz = (i - 1) % n, (i - 1) // n
		local x, z = x0 + gx * size, z0 + gz * size
		local hit = workspace:Raycast(Vector3.new(x, at.Y + 80, z), Vector3.new(0, -400, 0), groundParams)
		local y = if hit then hit.Position.Y + 0.15 else at.Y - 6
		cell.CFrame = CFrame.new(x, y, z)
	end
end

-- Puddles: dark glassy pools on hard ground open to the sky, near the camera, while it's wet.
local HARD = {
	Asphalt = true,
	Concrete = true,
	Pavement = true,
	Cobblestone = true,
	Brick = true,
	Slate = true,
	Granite = true,
	Limestone = true,
	Sandstone = true,
}
local puddles: { Part } = {}
local puddleAt: Vector3? = nil
local rng = Random.new()

local function dropPuddles(fade: boolean)
	for _, p in puddles do
		if fade then
			local t = TweenService:Create(p, TweenInfo.new(4), { Transparency = 1 })
			t.Completed:Connect(function()
				p:Destroy()
			end)
			t:Play()
		else
			p:Destroy()
		end
	end
	table.clear(puddles)
	puddleAt = nil
end

local function placePuddles(at: Vector3)
	dropPuddles(false)
	puddleAt = at
	local skip = skipList()
	groundParams.FilterDescendantsInstances = skip
	local up = RaycastParams.new()
	up.FilterType = Enum.RaycastFilterType.Exclude
	up.FilterDescendantsInstances = skip
	local reach = K.PuddleReach
	for _ = 1, K.Puddles * 3 do
		if #puddles >= K.Puddles then
			break
		end
		local a, d = rng:NextNumber(0, math.pi * 2), rng:NextNumber(6, reach)
		local from = Vector3.new(at.X + math.cos(a) * d, at.Y + 60, at.Z + math.sin(a) * d)
		local hit = workspace:Raycast(from, Vector3.new(0, -200, 0), groundParams)
		if hit and hit.Normal.Y > 0.97 and hit.Instance:IsA("BasePart") and HARD[hit.Material.Name] then
			-- open to the sky
			if not workspace:Raycast(hit.Position + Vector3.new(0, 0.3, 0), Vector3.new(0, 200, 0), up) then
				local size = rng:NextNumber(K.PuddleSize[1], K.PuddleSize[2])
				local p = hidden("Puddle", Vector3.new(0.02, size, size))
				p.Shape = Enum.PartType.Cylinder
				p.Material = Enum.Material.Glass
				p.Color = Color3.fromRGB(70, 80, 96)
				p.Reflectance = 0.2
				-- (over the road's paint, which stands 0.11 above it, so no two faces lie together)
				p.CFrame = CFrame.new(hit.Position + Vector3.new(0, 0.13, 0)) * CFrame.Angles(0, 0, math.pi / 2)
				p.Transparency = 1
				TweenService:Create(p, TweenInfo.new(6), { Transparency = 0.45 }):Play()
				table.insert(puddles, p)
			end
		end
	end
end

-- Lightning: a flash over the whole picture and a bolt coming down far off.
local flash: ColorCorrectionEffect? = nil
local function strike(at: Vector3)
	local cc = flash
	if not cc then
		local made = Instance.new("ColorCorrectionEffect")
		made.Name = "Lightning"
		made.Brightness = 0
		made.Parent = Lighting
		flash = made
		cc = made
	end
	local a = rng:NextNumber(0, math.pi * 2)
	local d = rng:NextNumber(K.Lightning.Far[1], K.Lightning.Far[2])
	local x, z = at.X + math.cos(a) * d, at.Z + math.sin(a) * d
	local bolt: { Part } = {}
	local top = Vector3.new(x, 320, z)
	local steps = 10
	for i = 1, steps do
		local y = 320 * (1 - i / steps)
		local nxt = Vector3.new(x + rng:NextNumber(-14, 14), y, z + rng:NextNumber(-14, 14))
		local seg = hidden("Bolt", Vector3.new(0.8, 0.8, (nxt - top).Magnitude))
		seg.Material = Enum.Material.Neon
		seg.Color = Color3.fromRGB(226, 232, 255)
		seg.Transparency = 0
		seg.CFrame = CFrame.lookAt((top + nxt) / 2, nxt)
		table.insert(bolt, seg)
		top = nxt
	end
	if cc then
		local peak = K.Lightning.Flash
		cc.Brightness = peak
		TweenService:Create(cc, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Brightness = 0,
		}):Play()
		task.delay(0.18, function()
			cc.Brightness = peak * 0.6
			TweenService:Create(cc, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Brightness = 0,
			}):Play()
		end)
	end
	task.delay(0.22, function()
		for _, seg in bolt do
			seg:Destroy()
		end
	end)
end

-- The air on this screen, every frame: the weather's, eased (Tuning.Weather.AirRate), clear at once
-- while the weather stands down, thin at once with the haze off (Settings). This screen is the
-- only one that sets it (Services/World leaves it after the start), so it never jumps between two
-- values: it did, the server's every half second over this one's, and the fog flickered.
local airDensity, airHaze = -1, -1
local function stepAir(dt: number)
	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
	if not atmosphere then
		return
	end
	local still = calm()
	local density, haze = Rules.air(Graphics.settings(), if still then "clear" else kindNow())
	if airDensity < 0 then
		airDensity, airHaze = atmosphere.Density, atmosphere.Haze
	end
	local k = if still or not Graphics.settings().haze then 1 else 1 - math.exp(-K.AirRate * dt)
	airDensity += (density - airDensity) * k
	airHaze += (haze - airHaze) * k
	if atmosphere.Density ~= airDensity then
		atmosphere.Density = airDensity
	end
	if atmosphere.Haze ~= airHaze then
		atmosphere.Haze = airHaze
	end
end

-- Where the ground is under what the camera looks at (the rings sit on it), found a few times a
-- second.
local groundY: number? = nil
local function findGround(at: Vector3)
	groundParams.FilterDescendantsInstances = skipList()
	local hit = workspace:Raycast(at + Vector3.new(0, 40, 0), Vector3.new(0, -200, 0), groundParams)
	groundY = if hit then hit.Position.Y else at.Y - 4
end

function Weather.start()
	if folder then
		return
	end
	local f = Instance.new("Folder")
	f.Name = "WeatherFx"
	f.Parent = workspace
	folder = f
	for name, box in Data.Boxes do
		if box.ring then
			local parts = {}
			for i, piece in Data.ringParts(name) do
				table.insert(parts, hidden("Weather" .. name .. i, piece.size))
			end
			rings[name] = parts
		elseif name ~= "ground" then
			boxes[name] = hidden("Weather" .. name, box.size)
		end
	end
	for _ = 1, K.Cells * K.Cells do
		table.insert(cells, hidden("RainCell", Data.Boxes.ground.size))
	end
	local function redraw()
		local ok, why = pcall(draw)
		if not ok then
			warn("[Weather] " .. tostring(why))
		end
	end
	redraw()
	workspace:GetAttributeChangedSignal("Weather"):Connect(redraw)
	workspace:GetAttributeChangedSignal("Season"):Connect(redraw)
	Graphics.Changed.Event:Connect(redraw)

	local roofClock, cellClock = 0, 0
	local cellsAt: Vector3? = nil
	local nextStrike = os.clock() + 8
	local wasCalm = false
	RunService.RenderStepped:Connect(function(dt)
		local cam = workspace.CurrentCamera
		if not cam then
			return
		end
		local eye = cam.CFrame.Position
		for name, part in boxes do
			local box = Data.Boxes[name]
			part.CFrame = CFrame.new(eye + Vector3.new(0, box.up, 0))
		end
		-- the rings round the spot the camera looks at, on the ground under it
		local spot = cam.Focus.Position
		if not groundY then
			findGround(spot)
		end
		for name, parts in rings do
			local box = Data.Boxes[name]
			local middle = Vector3.new(spot.X, (groundY :: number) + box.up, spot.Z)
			for i, piece in Data.ringParts(name) do
				local part = parts[i]
				if part then
					part.CFrame = CFrame.new(middle + piece.at)
				end
			end
		end
		-- the creator wants a clear day: nothing falls, no puddles, no lightning
		local still = calm()
		if still ~= wasCalm then
			wasCalm = still
			enableAll()
			if still then
				dropPuddles(false)
			end
		end
		roofClock += dt
		if roofClock > 0.3 then
			roofClock = 0
			local covered = underRoof(eye)
			if covered ~= sheltered then
				sheltered = covered
				enableAll()
				Audio.setSheltered(covered) -- (the rain and the wind heard softer indoors)
			end
		end
		local kind = kindNow()
		local wet = Data.Wet[kind] == true
		cellClock += dt
		if cellClock > 0.4 then
			cellClock = 0
			findGround(spot)
			if wet and not still and (not cellsAt or (eye - (cellsAt :: Vector3)).Magnitude > K.Cell / 2) then
				cellsAt = eye
				placeCells(eye)
			end
			-- puddles while it rains, where the detail allows; they dry when it stops
			local want = wet and not still and Graphics.level().Puddles
			if want and (not puddleAt or (eye - (puddleAt :: Vector3)).Magnitude > K.PuddleReach * 0.6) then
				placePuddles(eye)
			elseif not want and #puddles > 0 then
				dropPuddles(true)
			end
		end
		stepAir(dt)
		if Data.Lightning[kind] and not still and os.clock() > nextStrike then
			nextStrike = os.clock() + rng:NextNumber(K.Lightning.Every[1], K.Lightning.Every[2])
			strike(eye)
			Audio.thunder()
		end
	end)
end

return Weather
