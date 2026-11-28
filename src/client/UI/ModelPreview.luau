-- Little 3D pictures in the interface: a ViewportFrame showing primitives or a model, framed to fit.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Builder = require(Shared.Build.Builder)
local Geometry = require(Shared.Build.Geometry)

local ModelPreview = {}

local function frameCamera(vp: ViewportFrame, lo: Vector3, hi: Vector3, yawDeg: number?, pitchDeg: number?)
	local cam = Instance.new("Camera")
	cam.FieldOfView = 30
	local center = (lo + hi) / 2
	local radius = math.max((hi - lo).Magnitude / 2, 0.5)
	local dist = radius / math.tan(math.rad(cam.FieldOfView / 2)) * 1.05
	local yaw = math.rad(yawDeg or 35)
	-- (Pitch: how far it looks down; something flat, a mark on the floor, is seen from high up)
	local pitch = math.rad(pitchDeg or 24)
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
		frameCamera(vp, lo, hi, p.Yaw, p.Pitch)
	end
	if p.Parent then
		vp.Parent = p.Parent
	end
	return vp
end

-- The idle animation the model's own Animate script holds (the default R15 one otherwise).
local function idleOf(model: Model): string
	local animate = model:FindFirstChild("Animate")
	local folder = animate and animate:FindFirstChild("idle")
	if folder then
		for _, a in folder:GetChildren() do
			if a:IsA("Animation") and a.AnimationId ~= "" then
				return a.AnimationId
			end
		end
	end
	return "rbxassetid://507766388"
end

-- A copy is taken as the villager is right then: lying on their back in bed, or mid step. The
-- user: "the character sometimes rotates 90 degrees, can this be fixed?". So the copy is stood
-- up straight at the middle of its own little world, facing -Z, with every joint at rest.
local function standUp(copy: Model)
	local root = copy:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return
	end
	for _, d in copy:GetDescendants() do
		if d:IsA("Motor6D") then
			d.Transform = CFrame.identity
		end
	end
	-- moved whole, part by part, so it holds even where the joints aren't being solved
	copy:PivotTo(root.CFrame:Inverse() * copy:GetPivot())
	root.Anchored = true
	local humanoid = copy:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.PlatformStand = false
		humanoid.Sit = false
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	end
end

-- Plays `id` on the copy for as long as it is shown (the user: "make the character animated as
-- well"). Nothing happens where the animation can't load.
local function playOn(copy: Model, id: string)
	local humanoid = copy:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	pcall(function()
		local animator = humanoid:FindFirstChildOfClass("Animator")
		if not animator then
			animator = Instance.new("Animator")
			animator.Parent = humanoid
		end
		local anim = Instance.new("Animation")
		anim.AnimationId = id
		local track = (animator :: Animator):LoadAnimation(anim)
		track.Looped = true
		track.Priority = Enum.AnimationPriority.Idle
		track:Play(0)
	end)
end

-- Where a standing copy's feet and the top of its head are (the box round the whole model would
-- count wings, tails and whatever they carry).
local function heights(copy: Model, cf: CFrame, size: Vector3): (number, number)
	local lo, hi = cf.Position.Y - size.Y / 2, cf.Position.Y + size.Y / 2
	local root = copy:FindFirstChild("HumanoidRootPart")
	local head = copy:FindFirstChild("Head")
	local humanoid = copy:FindFirstChildOfClass("Humanoid")
	if root and root:IsA("BasePart") and head and head:IsA("BasePart") and humanoid then
		local feet = root.Position.Y - root.Size.Y / 2 - humanoid.HipHeight
		if humanoid.RigType == Enum.HumanoidRigType.R6 then
			feet -= 2 -- an R6 body's legs hang below its hip height
		end
		local crown = head.Position.Y + head.Size.Y / 2
		if crown - feet > 2 then
			-- room for hair and a hat, as far as the model really goes
			return math.max(lo, feet - 0.2), math.min(hi, crown + 1.3)
		end
	end
	return lo, hi
end

-- A viewport showing a copy of a model (villagers): Face (a close-up of the head), Stand (the
-- whole of them upright), Bust (the same, for a frame cut off at the hips), or the model whole
-- from a little to the side. With Stand and Shadow the second thing
-- returned is their shadow on whatever is behind them (the user: "there should also be a shadow
-- cast on the background in the character customization and character select screen"): the same
-- copy again, drawn all in black and see-through, a little bigger and off to one side.
function ModelPreview.fromModel(source: Model, props: { [string]: any }?): (ViewportFrame?, ViewportFrame?)
	local p = props or {}
	local ok, copy = pcall(function()
		source.Archivable = true
		return source:Clone()
	end)
	if not ok or not copy then
		return nil, nil
	end
	local shade: ViewportFrame? = nil
	local twin: Model? = nil
	local vp = Instance.new("ViewportFrame")
	vp.BackgroundTransparency = 1
	vp.Size = p.Size or UDim2.fromScale(1, 1)
	-- shade enough that a pale outfit keeps its folds: with the old bright ambient a white
	-- dress came out flat and washed out
	vp.Ambient = Color3.fromRGB(138, 134, 150)
	vp.LightColor = Color3.fromRGB(214, 208, 198)
	vp.LightDirection = Vector3.new(-0.5, -1, -0.6)
	local world = Instance.new("WorldModel")
	world.Parent = vp
	local idle = idleOf(copy)
	-- (Without: what an event puts on them later in a conversation stays off until then, UI/Dialogue)
	local without: { [string]: boolean } = if type(p.Without) == "table" then p.Without else {}
	for _, d in copy:GetDescendants() do
		-- nothing that runs, floats over their head or asks to be pressed comes along
		if
			d:IsA("Script")
			or d:IsA("LocalScript")
			or d:IsA("BillboardGui")
			or d:IsA("ProximityPrompt")
			or d:IsA("Highlight")
			or (d:IsA("Accessory") and without[tostring(d:GetAttribute("Lately"))])
		then
			d:Destroy()
		end
	end
	copy.Parent = world
	standUp(copy)
	local cf, size = copy:GetBoundingBox()
	local head = copy:FindFirstChild("Head")
	if p.Face and head and head:IsA("BasePart") then
		local cam = Instance.new("Camera")
		cam.FieldOfView = 30
		local look = head.CFrame
		cam.CFrame = CFrame.lookAt(look.Position + look.LookVector * 5 + Vector3.new(0, 0.3, 0), look.Position)
		cam.Parent = vp
		vp.CurrentCamera = cam
	elseif p.Stand or p.Bust then
		-- the whole of them standing, fitted to the frame's height (a tall frame): seen from the
		-- front and a touch to one side, from about chest height. A bust (UI/Dialogue) is framed
		-- the same way in a frame its holder cuts off at the hips, turned by Yaw toward the middle
		-- of the screen (a negative Yaw faces them to the right)
		local root = copy:FindFirstChild("HumanoidRootPart")
		local front = if root and root:IsA("BasePart") then root.CFrame.LookVector else Vector3.new(0, 0, -1)
		local dir = CFrame.fromAxisAngle(Vector3.yAxis, math.rad(p.Yaw or 14)):VectorToWorldSpace(front)
		local cam = Instance.new("Camera")
		cam.FieldOfView = 24
		local lo, hi = heights(copy, cf, size)
		local middle = Vector3.new(cf.Position.X, (lo + hi) / 2, cf.Position.Z)
		if root and root:IsA("BasePart") then
			middle = Vector3.new(root.Position.X, (lo + hi) / 2, root.Position.Z)
		end
		local half = (hi - lo) / 2 + 0.25
		local dist = half / math.tan(math.rad(12))
		cam.CFrame = CFrame.lookAt(middle + dir * dist + Vector3.new(0, 0.4, 0), middle)
		cam.Parent = vp
		vp.CurrentCamera = cam
		vp.Name = "Avatar"
		if p.Shadow then
			local s = Instance.new("ViewportFrame")
			s.Name = "AvatarShadow"
			s.BackgroundTransparency = 1
			s.Size = vp.Size
			s.Position = UDim2.new(0.11, 0, 0.02, 0)
			s.ImageColor3 = Color3.new(0, 0, 0)
			s.ImageTransparency = if type(p.Shadow) == "number" then p.Shadow else 0.66
			local world2 = Instance.new("WorldModel")
			world2.Parent = s
			local second = copy:Clone()
			second.Parent = world2
			local cam2 = Instance.new("Camera")
			cam2.FieldOfView = 24
			-- a little nearer, so the shadow is a little bigger than they are
			cam2.CFrame = CFrame.lookAt(middle + dir * dist * 0.93 + Vector3.new(0, 0.4, 0), middle)
			cam2.Parent = s
			s.CurrentCamera = cam2
			shade, twin = s, second
		end
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
		if shade then
			shade.Parent = p.Parent
		end
		vp.Parent = p.Parent
	end
	if (p.Stand or p.Bust) and p.Still ~= true then
		-- an animation only loads once the copy is somewhere in the game; the shadow's copy
		-- starts in the same breath, so the two keep step
		local function play(model: Model, id: string)
			playOn(model, id)
			if model == copy and twin then
				playOn(twin, id)
			end
		end
		if vp:IsDescendantOf(game) then
			play(copy, idle)
		else
			local wait: RBXScriptConnection? = nil
			wait = vp.AncestryChanged:Connect(function()
				if vp:IsDescendantOf(game) then
					if wait then
						wait:Disconnect()
					end
					play(copy, idle)
				end
			end)
		end
	end
	return vp, shade
end

return ModelPreview
