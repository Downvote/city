-- The little show when you build: a new piece springs up out of a puff of dust with a few
-- sparkles, and a piece you sell vanishes in a puff. Only on your own screen, only for your
-- own plot (the plan changes come from State).

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Builder = require(Shared.Build.Builder)
local Town = require(Shared.Data.Town)
local Plan = require(Shared.Build.Plan)

local State = require(script.Parent.Parent.Controllers.State)

local BuildFx = {}

local player = Players.LocalPlayer

local function buildFolder(): Instance?
	local index = player:GetAttribute("Plot")
	if type(index) ~= "number" then
		return nil
	end
	local plots = workspace:FindFirstChild("Plots")
	local plot = plots and plots:FindFirstChild("Plot" .. index)
	return plot and plot:FindFirstChild("Build")
end

local function emitter(parent: Instance, texture: string, color: ColorSequence): ParticleEmitter
	local e = Instance.new("ParticleEmitter")
	e.Texture = texture
	e.Color = color
	e.Enabled = false
	e.Parent = parent
	return e
end

-- A puff of dust (and sparkles, for something new) at a point, `size` studs across.
function BuildFx.puff(at: Vector3, size: number, sparkles: boolean)
	local p = Instance.new("Part")
	p.Name = "BuildPuff"
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Transparency = 1
	p.Size = Vector3.new(math.clamp(size, 2, 24), 1, math.clamp(size, 2, 24))
	p.CFrame = CFrame.new(at)
	p.Parent = workspace
	local dust = emitter(
		p,
		"rbxasset://textures/particles/smoke_main.dds",
		ColorSequence.new(Color3.fromRGB(255, 250, 240), Color3.fromRGB(225, 215, 200))
	)
	dust.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1.2),
		NumberSequenceKeypoint.new(1, 4),
	})
	dust.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.25),
		NumberSequenceKeypoint.new(1, 1),
	})
	dust.Lifetime = NumberRange.new(0.5, 0.9)
	dust.Speed = NumberRange.new(6, 11)
	dust.SpreadAngle = Vector2.new(180, 25)
	dust.Drag = 5
	dust.Acceleration = Vector3.new(0, 3, 0)
	dust.RotSpeed = NumberRange.new(-90, 90)
	dust:Emit(math.floor(math.clamp(size * 1.5, 10, 26)))
	if sparkles then
		local stars = emitter(
			p,
			"rbxasset://textures/particles/sparkles_main.dds",
			ColorSequence.new(Color3.fromRGB(255, 230, 120), Color3.fromRGB(255, 255, 255))
		)
		stars.LightEmission = 1
		stars.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.8),
			NumberSequenceKeypoint.new(1, 0),
		})
		stars.Lifetime = NumberRange.new(0.6, 1)
		stars.Speed = NumberRange.new(8, 14)
		stars.SpreadAngle = Vector2.new(60, 60)
		stars.Acceleration = Vector3.new(0, -12, 0)
		stars:Emit(10)
	end
	Debris:AddItem(p, 2)
end

-- Springs a freshly built model up from small, with a little overshoot.
function BuildFx.pop(model: Model)
	local ok = pcall(function()
		model:ScaleTo(0.4)
	end)
	if not ok then
		return
	end
	local v = Instance.new("NumberValue")
	v.Value = 0.4
	v.Changed:Connect(function(s)
		if model.Parent then
			pcall(function()
				model:ScaleTo(math.max(0.05, s))
			end)
		end
	end)
	local tween = TweenService:Create(v, TweenInfo.new(0.42, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Value = 1,
	})
	tween:Play()
	task.delay(0.45, function()
		if model.Parent then
			pcall(function()
				model:ScaleTo(1)
			end)
		end
		v:Destroy()
	end)
end

-- Where a removed object stood, from its saved fields, in world space.
local function whereWas(kind: string, obj: any): Vector3?
	local index = player:GetAttribute("Plot")
	if type(index) ~= "number" or type(obj) ~= "table" then
		return nil
	end
	if obj.wall then
		return nil -- a door or window: it goes with its wall's puff
	end
	local frame = Town.plotFrame(index)
	local lv = Plan.levelBase(obj.lv or 0)
	if kind == "items" and obj.x then
		return frame * Vector3.new(obj.x, (obj.y or 0) + 1.5, obj.z)
	elseif obj.x1 then
		return frame * Vector3.new((obj.x1 + obj.x2) / 2, lv + 2, (obj.z1 + obj.z2) / 2)
	end
	return nil
end

function BuildFx.start()
	State.onPlan(function(ops: any)
		if type(ops) ~= "table" then
			return -- a whole plan (joining, buying land): no show
		end
		for _, op in ops do
			if op.op == "add" and type(op.kind) == "string" and type(op.key) == "string" then
				task.spawn(function()
					local folder = buildFolder()
					local name = Builder.modelName(op.kind, op.key)
					local model = folder and folder:WaitForChild(name, 2)
					if model and model:IsA("Model") then
						local cf, size = model:GetBoundingBox()
						BuildFx.puff(cf.Position - Vector3.new(0, size.Y / 2 - 0.5, 0), math.max(size.X, size.Z), true)
						BuildFx.pop(model)
					end
				end)
			elseif op.op == "remove" and type(op.kind) == "string" then
				local at = whereWas(op.kind, op.obj)
				if at then
					BuildFx.puff(at, 6, false)
				end
			end
		end
	end)
end

return BuildFx
