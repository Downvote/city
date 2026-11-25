-- Rain, snow, blossom and falling leaves around the camera, following the town's weather.
-- The user: "it seems like weather particles arent showing, such as rain". They were started from
-- the end of the HUD's start (anything failing before it stopped them), rain was specks a tenth of
-- a stud across (too small to see past a few studs) and asked for a stretch Roblox doesn't allow
-- (more than 3). Now it starts on its own, each drop is a long streak big enough to see, every
-- setting is put on by itself (one Roblox refuses doesn't stop the rest), and the drops give off a
-- little light of their own so rain still shows at night.

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Weather = {}

local holder: Part? = nil
local emitter: ParticleEmitter? = nil
local falling = false -- the weather has something to drop
local sheltered = false -- there's a roof over the camera
local SPARK = "rbxasset://textures/particles/sparkles_main.dds"

type Look = {
	color: Color3,
	rate: number,
	speed: number,
	size: number,
	life: number,
	stretch: boolean?,
	glow: number,
	see: number,
}

local LOOKS: { [string]: Look } = {
	rain = {
		color = Color3.fromRGB(196, 214, 236),
		rate = 900,
		speed = 75,
		size = 0.3,
		life = 1.3,
		stretch = true,
		glow = 0.25,
		see = 0.35,
	},
	storm = {
		color = Color3.fromRGB(180, 198, 226),
		rate = 1500,
		speed = 95,
		size = 0.34,
		life = 1.1,
		stretch = true,
		glow = 0.2,
		see = 0.3,
	},
	snow = { color = Color3.fromRGB(255, 255, 255), rate = 260, speed = 7, size = 0.5, life = 9, glow = 0.3, see = 0.1 },
	blossom = {
		color = Color3.fromRGB(255, 190, 210),
		rate = 60,
		speed = 4,
		size = 0.55,
		life = 10,
		glow = 0.1,
		see = 0.05,
	},
	leaves = { color = Color3.fromRGB(230, 140, 60), rate = 45, speed = 5, size = 0.6, life = 10, glow = 0, see = 0.05 },
}

local function set(e: ParticleEmitter, key: string, value: any)
	local ok, why = pcall(function()
		(e :: any)[key] = value
	end)
	if not ok then
		warn("[Weather] couldn't set " .. key .. ": " .. tostring(why))
	end
end

local function apply()
	local e = emitter
	if not e then
		return
	end
	local kind = workspace:GetAttribute("Weather")
	local look = if type(kind) == "string" then LOOKS[kind] else nil
	if not look then
		falling = false
		e.Enabled = false
		return
	end
	local streak = look.stretch == true
	set(e, "Texture", SPARK)
	set(e, "Color", ColorSequence.new(look.color))
	set(e, "Rate", look.rate)
	set(e, "Speed", NumberRange.new(look.speed * 0.85, look.speed * 1.15))
	set(e, "Lifetime", NumberRange.new(look.life * 0.8, look.life))
	set(e, "Size", NumberSequence.new(look.size))
	set(
		e,
		"Transparency",
		NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.08, look.see),
			NumberSequenceKeypoint.new(0.9, look.see),
			NumberSequenceKeypoint.new(1, 1),
		})
	)
	set(e, "SpreadAngle", if streak then Vector2.new(4, 4) else Vector2.new(40, 40))
	set(e, "Rotation", NumberRange.new(0, 360))
	set(e, "RotSpeed", if streak then NumberRange.new(0, 0) else NumberRange.new(-60, 60))
	set(
		e,
		"Orientation",
		if streak then Enum.ParticleOrientation.VelocityParallel else Enum.ParticleOrientation.FacingCamera
	)
	-- a drop is drawn long along its fall (3 is as far as Roblox stretches one)
	set(e, "Squash", NumberSequence.new(if streak then 3 else 0))
	set(e, "LightEmission", look.glow)
	set(e, "LightInfluence", 0.5)
	set(e, "Drag", if streak then 0 else 0.4)
	set(e, "Acceleration", if streak then Vector3.new(2, 0, 1) else Vector3.new(1.5, -0.5, 0.8))
	falling = true
	e.Enabled = not sheltered
end

-- Whether there's a roof (or anything solid) over the camera: no rain falls indoors.
local function underRoof(at: Vector3): boolean
	local skip: { Instance } = {}
	if holder then
		table.insert(skip, holder)
	end
	local char = Players.LocalPlayer and Players.LocalPlayer.Character
	if char then
		table.insert(skip, char)
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = skip
	local hit = workspace:Raycast(at, Vector3.new(0, 60, 0), params)
	return hit ~= nil and hit.Instance.Transparency < 0.9
end

function Weather.start()
	if holder then
		return
	end
	local p = Instance.new("Part")
	p.Name = "WeatherCloud"
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Transparency = 1
	-- (a close square: the drops are thickest round the camera, where they're seen)
	p.Size = Vector3.new(90, 1, 90)
	p.Parent = workspace
	holder = p
	local e = Instance.new("ParticleEmitter")
	e.Name = "Weather"
	e.EmissionDirection = Enum.NormalId.Bottom
	e.Enabled = false
	e.Parent = p
	emitter = e
	local ok, why = pcall(apply)
	if not ok then
		warn("[Weather] " .. tostring(why))
	end
	workspace:GetAttributeChangedSignal("Weather"):Connect(function()
		local fine, err = pcall(apply)
		if not fine then
			warn("[Weather] " .. tostring(err))
		end
	end)
	local roofClock = 0
	RunService.RenderStepped:Connect(function(dt)
		local cam = workspace.CurrentCamera
		if cam and holder then
			holder.CFrame = CFrame.new(cam.CFrame.Position + Vector3.new(0, 32, 0))
			roofClock += dt
			if roofClock > 0.3 then
				roofClock = 0
				local covered = underRoof(cam.CFrame.Position)
				if covered ~= sheltered then
					sheltered = covered
					if emitter then
						emitter.Enabled = falling and not sheltered
					end
				end
			end
		end
	end)
end

return Weather
