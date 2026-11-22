-- Little 3D pictures in the interface: a ViewportFrame showing primitives or a model, framed to fit.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Builder = require(Shared.Build.Builder)
local Geometry = require(Shared.Build.Geometry)

local ModelPreview = {}

local function frameCamera(vp: ViewportFrame, lo: Vector3, hi: Vector3, yawDeg: number?)
	local cam = Instance.new("Camera")
	cam.FieldOfView = 30
	local center = (lo + hi) / 2
	local radius = math.max((hi - lo).Magnitude / 2, 0.5)
	local dist = radius / math.tan(math.rad(cam.FieldOfView / 2)) * 1.05
	local yaw = math.rad(yawDeg or 35)
	local pitch = math.rad(24)
	local dir = Vector3.new(math.sin(yaw) * math.cos(pitch), math.sin(pitch), math.cos(yaw) * math.cos(pitch))
	cam.CFrame = CFrame.lookAt(center + dir * dist, center)
	cam.Parent = vp
	vp.CurrentCamera = cam
end

-- A viewport showing primitives (catalog items, monsters).
function ModelPreview.fromPrims(prims: { Geometry.Prim }, props: { [string]: any }?): ViewportFrame
	local p = props or {}
	local vp = Instance.new("ViewportFrame")
	vp.BackgroundTransparency = 1
	vp.Size = p.Size or UDim2.fromScale(1, 1)
	vp.Position = p.Position or UDim2.new()
	vp.LightDirection = Vector3.new(-0.6, -1, -0.4)
	vp.Ambient = Color3.fromRGB(190, 180, 170)
	vp.LightColor = Color3.fromRGB(255, 246, 230)
	vp.Name = "Preview"
	local visible = {}
	for _, prim in prims do
		if (prim.transp or 0) < 0.99 then
			table.insert(visible, prim)
		end
	end
	local model = Instance.new("Model")
	Builder.instantiate(visible, model, CFrame.identity)
	model.Parent = vp
	if #visible > 0 then
		local lo, hi = Geometry.bounds(visible)
		frameCamera(vp, lo, hi, p.Yaw)
	end
	if p.Parent then
		vp.Parent = p.Parent
	end
	return vp
end

-- A viewport showing a copy of a model (villagers).
function ModelPreview.fromModel(source: Model, props: { [string]: any }?): ViewportFrame?
	local p = props or {}
	local ok, copy = pcall(function()
		source.Archivable = true
		return source:Clone()
	end)
	if not ok or not copy then
		return nil
	end
	local vp = Instance.new("ViewportFrame")
	vp.BackgroundTransparency = 1
	vp.Size = p.Size or UDim2.fromScale(1, 1)
	vp.Ambient = Color3.fromRGB(200, 190, 180)
	vp.LightDirection = Vector3.new(-0.5, -1, -0.6)
	local world = Instance.new("WorldModel")
	world.Parent = vp
	for _, d in copy:GetDescendants() do
		if d:IsA("Script") or d:IsA("LocalScript") then
			d:Destroy()
		end
	end
	copy.Parent = world
	local cf, size = copy:GetBoundingBox()
	local head = copy:FindFirstChild("Head")
	if p.Face and head and head:IsA("BasePart") then
		local cam = Instance.new("Camera")
		cam.FieldOfView = 30
		local look = head.CFrame
		cam.CFrame = CFrame.lookAt(look.Position + look.LookVector * 5 + Vector3.new(0, 0.3, 0), look.Position)
		cam.Parent = vp
		vp.CurrentCamera = cam
	else
		-- look at the model's front, a little from the side
		local root = copy:FindFirstChild("HumanoidRootPart")
		local front = if root and root:IsA("BasePart") then root.CFrame.LookVector else Vector3.new(0, 0, -1)
		local side = math.rad(p.Yaw or 20)
		local dir = (CFrame.fromAxisAngle(Vector3.yAxis, side):VectorToWorldSpace(front) + Vector3.new(0, 0.25, 0)).Unit
		local cam = Instance.new("Camera")
		cam.FieldOfView = 30
		local radius = math.max(size.Magnitude / 2, 0.5)
		local dist = radius / math.tan(math.rad(15)) * 0.95
		cam.CFrame = CFrame.lookAt(cf.Position + dir * dist, cf.Position)
		cam.Parent = vp
		vp.CurrentCamera = cam
	end
	if p.Parent then
		vp.Parent = p.Parent
	end
	return vp
end

return ModelPreview
