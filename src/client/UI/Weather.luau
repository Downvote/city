-- Rain, snow, blossom and falling leaves around the camera, following the town's weather.

local RunService = game:GetService("RunService")

local Weather = {}

local holder: Part? = nil
local emitter: ParticleEmitter? = nil

local LOOKS = {
	rain = { color = Color3.fromRGB(170, 200, 230), rate = 400, speed = 70, size = 0.12, life = 1.2, stretch = true },
	storm = { color = Color3.fromRGB(150, 175, 210), rate = 700, speed = 90, size = 0.14, life = 1, stretch = true },
	snow = { color = Color3.fromRGB(255, 255, 255), rate = 160, speed = 6, size = 0.35, life = 9 },
	blossom = { color = Color3.fromRGB(255, 190, 210), rate = 40, speed = 4, size = 0.4, life = 10 },
	leaves = { color = Color3.fromRGB(230, 140, 60), rate = 30, speed = 5, size = 0.45, life = 10 },
}

local function apply()
	local kind = workspace:GetAttribute("Weather")
	local look = type(kind) == "string" and LOOKS[kind]
	local e = emitter :: ParticleEmitter
	if not look then
		e.Enabled = false
		return
	end
	e.Enabled = true
	e.Color = ColorSequence.new(look.color)
	e.Rate = look.rate
	e.Speed = NumberRange.new(look.speed * 0.8, look.speed * 1.2)
	e.Lifetime = NumberRange.new(look.life * 0.8, look.life)
	e.Size = NumberSequence.new(look.size)
	e.Transparency = NumberSequence.new(0.2)
	e.SpreadAngle = Vector2.new(if look.stretch then 5 else 40, if look.stretch then 5 else 40)
	e.Rotation = NumberRange.new(0, 360)
	e.RotSpeed = NumberRange.new(if look.stretch then 0 else -60, if look.stretch then 0 else 60)
	e.Orientation = if look.stretch
		then Enum.ParticleOrientation.VelocityParallel
		else Enum.ParticleOrientation.FacingCamera
	e.Squash = if look.stretch then NumberSequence.new(4) else NumberSequence.new(0)
end

function Weather.start()
	local p = Instance.new("Part")
	p.Name = "WeatherCloud"
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Transparency = 1
	p.Size = Vector3.new(120, 1, 120)
	p.Parent = workspace
	holder = p
	local e = Instance.new("ParticleEmitter")
	e.EmissionDirection = Enum.NormalId.Bottom
	e.LightInfluence = 0.6
	e.Enabled = false
	e.Parent = p
	emitter = e
	apply()
	workspace:GetAttributeChangedSignal("Weather"):Connect(apply)
	RunService.RenderStepped:Connect(function()
		local cam = workspace.CurrentCamera
		if cam and holder then
			holder.CFrame = CFrame.new(cam.CFrame.Position + Vector3.new(0, 40, 0))
		end
	end)
end

return Weather
