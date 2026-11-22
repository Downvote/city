-- One villager's body in the world: spawning the character, its animations, walking with
-- pathfinding, sitting, lying in bed, speech bubbles and little emotion icons over its head.

local PathfindingService = game:GetService("PathfindingService")
local TweenService = game:GetService("TweenService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Tuning = require(Shared.Config.Tuning)

local Npc = {}
Npc.__index = Npc

export type Npc = typeof(setmetatable(
	{} :: {
		model: Model,
		humanoid: Humanoid,
		root: BasePart,
		animator: Animator?,
		tracks: { [string]: AnimationTrack },
		moving: number,
		busy: boolean,
		seat: Seat?,
		sleeping: boolean,
		bubble: BillboardGui?,
		bubbleToken: number,
		vid: string,
	},
	Npc
))

-- Roblox's own default animations, used when a villager has no animation pack.
local DEFAULT_ANIMS = {
	idle = "rbxassetid://507766388",
	walk = "rbxassetid://507777826",
	run = "rbxassetid://507767714",
	jump = "rbxassetid://507765000",
	fall = "rbxassetid://507767968",
	sit = "rbxassetid://2506281703",
	wave = "rbxassetid://507770239",
	point = "rbxassetid://507770453",
	dance = "rbxassetid://507771019",
	dance2 = "rbxassetid://507776043",
	laugh = "rbxassetid://507770818",
	cheer = "rbxassetid://507770677",
}

local LOOPED = { idle = true, walk = true, run = true, sit = true, dance = true, dance2 = true }

-- Reads the animation id the character's Animate script would use for an action.
local function animId(model: Model, action: string): string
	local animate = model:FindFirstChild("Animate")
	local folder = animate and animate:FindFirstChild(action)
	if folder then
		for _, a in folder:GetChildren() do
			if a:IsA("Animation") and a.AnimationId ~= "" then
				return a.AnimationId
			end
		end
	end
	return DEFAULT_ANIMS[action]
end

function Npc.new(model: Model, vid: string): Npc
	local humanoid = model:FindFirstChildOfClass("Humanoid") :: Humanoid
	local root = model:FindFirstChild("HumanoidRootPart") :: BasePart
	local self = setmetatable({
		model = model,
		humanoid = humanoid,
		root = root,
		animator = humanoid:FindFirstChildOfClass("Animator"),
		tracks = {},
		moving = 0,
		busy = false,
		seat = nil,
		sleeping = false,
		bubble = nil,
		bubbleToken = 0,
		vid = vid,
	}, Npc)
	humanoid.WalkSpeed = Tuning.Villagers.WalkSpeed
	humanoid.AutoRotate = true
	humanoid.BreakJointsOnDeath = false
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
	model:SetAttribute("Vid", vid)
	-- the LocalScript Animate never runs on a server NPC; the server plays the animations itself
	local animate = model:FindFirstChild("Animate")
	if animate and animate:IsA("LocalScript") then
		animate.Enabled = false
	end
	humanoid.Running:Connect(function(speed)
		if self.sleeping or self.seat then
			return
		end
		if speed > 0.5 then
			self:play("walk")
			self:stop("idle")
		else
			self:stop("walk")
			self:play("idle")
		end
	end)
	return self
end

function Npc.track(self: Npc, action: string): AnimationTrack?
	local existing = self.tracks[action]
	if existing then
		return existing
	end
	if not self.animator then
		return nil
	end
	local id = animId(self.model, action) or DEFAULT_ANIMS[action]
	if not id then
		return nil
	end
	local anim = Instance.new("Animation")
	anim.AnimationId = id
	local ok, track = pcall(function()
		return (self.animator :: Animator):LoadAnimation(anim)
	end)
	if not ok or not track then
		return nil
	end
	track.Looped = LOOPED[action] == true
	self.tracks[action] = track
	return track
end

function Npc.play(self: Npc, action: string, fade: number?)
	local t = self:track(action)
	if t and not t.IsPlaying then
		t:Play(fade or 0.2)
	end
end

function Npc.stop(self: Npc, action: string)
	local t = self.tracks[action]
	if t and t.IsPlaying then
		t:Stop(0.2)
	end
end

-- Plays a one-off gesture (wave, cheer, laugh, point, dance) for a few seconds.
function Npc.gesture(self: Npc, action: string, seconds: number?)
	local t = self:track(action)
	if not t then
		return
	end
	t:Play(0.15)
	if t.Looped then
		task.delay(seconds or 3, function()
			if t.IsPlaying then
				t:Stop(0.3)
			end
		end)
	end
end

function Npc.position(self: Npc): Vector3
	return self.root.Position
end

-- Walking ----------------------------------------------------------------------------------------

-- Walks to a world point. Returns true if it got there. Cancelled by a newer walk or stand().
function Npc.walkTo(self: Npc, target: Vector3, timeout: number?): boolean
	self:standUp()
	self.moving += 1
	local token = self.moving
	local path = PathfindingService:CreatePath({
		AgentRadius = 1.6,
		AgentHeight = 5,
		AgentCanJump = false,
		WaypointSpacing = 4,
		Costs = { Water = 20 },
	})
	local ok = pcall(function()
		path:ComputeAsync(self.root.Position, target)
	end)
	local waypoints
	if ok and path.Status == Enum.PathStatus.Success then
		waypoints = path:GetWaypoints()
	else
		waypoints = { { Position = target } }
	end
	local deadline = os.clock() + (timeout or 25)
	for i, wp in waypoints do
		if self.moving ~= token or not self.model.Parent then
			return false
		end
		if i > 1 or #waypoints == 1 then
			self.humanoid:MoveTo(wp.Position)
			local arrived = false
			local conn
			conn = self.humanoid.MoveToFinished:Connect(function(reached)
				arrived = true
				local _ = reached
				conn:Disconnect()
			end)
			local stepEnd = os.clock() + 6
			while not arrived and os.clock() < stepEnd and os.clock() < deadline and self.moving == token do
				task.wait(0.1)
			end
			if conn.Connected then
				conn:Disconnect()
			end
			if os.clock() >= deadline then
				break
			end
		end
	end
	if self.moving ~= token then
		return false
	end
	return (self.root.Position - target).Magnitude < 4
end

-- Stops walking and turns to face a point.
function Npc.face(self: Npc, point: Vector3)
	self.moving += 1
	self.humanoid:MoveTo(self.root.Position)
	local flat = Vector3.new(point.X, self.root.Position.Y, point.Z)
	if (flat - self.root.Position).Magnitude > 0.1 then
		self.model:PivotTo(CFrame.lookAt(self.root.Position, flat))
	end
end

function Npc.halt(self: Npc)
	self.moving += 1
	self.humanoid:MoveTo(self.root.Position)
end

-- Sitting and sleeping ---------------------------------------------------------------------------

function Npc.sit(self: Npc, seat: Seat): boolean
	if seat.Occupant then
		return false
	end
	self:halt()
	Npc.useSeat(seat, self.humanoid)
	task.wait(0.2)
	if seat.Occupant == self.humanoid then
		self.seat = seat
		self:stop("walk")
		self:stop("idle")
		self:play("sit")
		return true
	end
	return false
end

-- Seats stay disabled so people don't sit by bumping into them; this lets one humanoid sit and
-- disables the seat again once they get up.
function Npc.useSeat(seat: Seat, humanoid: Humanoid)
	seat.Disabled = false
	seat:Sit(humanoid)
	local conn
	conn = seat:GetPropertyChangedSignal("Occupant"):Connect(function()
		if not seat.Occupant then
			seat.Disabled = true
			conn:Disconnect()
		end
	end)
	task.delay(0.5, function()
		if not seat.Occupant then
			seat.Disabled = true
			if conn.Connected then
				conn:Disconnect()
			end
		end
	end)
end

function Npc.standUp(self: Npc)
	if self.sleeping then
		self.sleeping = false
		self.root.Anchored = false
		self.humanoid.PlatformStand = false
		self.humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
		self:stop("sit")
	end
	if self.seat then
		self.humanoid.Sit = false
		self.humanoid.Jump = true
		self.seat = nil
		self:stop("sit")
		task.wait(0.15)
	end
end

-- Lies down on a bed spot (a part from a bed recipe's r:sleep()).
function Npc.sleep(self: Npc, spot: BasePart)
	self:halt()
	self.sleeping = true
	self:stop("walk")
	self:play("idle")
	self.humanoid.PlatformStand = true
	self.root.Anchored = true
	local hip = self.humanoid.HipHeight
	local lying = spot.CFrame * CFrame.new(0, 0.3 + self.root.Size.Z / 2, 0) * CFrame.Angles(math.rad(-90), 0, 0)
	local _ = hip
	self.model:PivotTo(lying)
end

-- Bubbles ----------------------------------------------------------------------------------------

local function makeBubble(self: Npc): BillboardGui
	if self.bubble and self.bubble.Parent then
		return self.bubble
	end
	local head = self.model:FindFirstChild("Head") or self.root
	local gui = Instance.new("BillboardGui")
	gui.Name = "Bubble"
	gui.Size = UDim2.fromOffset(240, 70)
	gui.StudsOffset = Vector3.new(0, 3.4, 0)
	gui.MaxDistance = 90
	gui.AlwaysOnTop = false
	gui.Adornee = head :: BasePart
	gui.Enabled = false
	local frame = Instance.new("Frame")
	frame.Name = "Card"
	frame.AnchorPoint = Vector2.new(0.5, 1)
	frame.Position = UDim2.fromScale(0.5, 1)
	frame.Size = UDim2.fromScale(0, 0)
	frame.AutomaticSize = Enum.AutomaticSize.XY
	frame.BackgroundColor3 = Color3.fromRGB(255, 252, 245)
	frame.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = frame
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(214, 190, 160)
	stroke.Thickness = 2
	stroke.Parent = frame
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 10)
	pad.PaddingRight = UDim.new(0, 10)
	pad.PaddingTop = UDim.new(0, 6)
	pad.PaddingBottom = UDim.new(0, 6)
	pad.Parent = frame
	local label = Instance.new("TextLabel")
	label.Name = "Text"
	label.BackgroundTransparency = 1
	label.AutomaticSize = Enum.AutomaticSize.XY
	label.Size = UDim2.fromOffset(0, 0)
	label.Font = Enum.Font.BuilderSansMedium
	label.TextSize = 18
	label.TextWrapped = true
	label.TextColor3 = Color3.fromRGB(74, 52, 38)
	label.Parent = frame
	local limit = Instance.new("UISizeConstraint")
	limit.MaxSize = Vector2.new(230, 200)
	limit.Parent = label
	gui.Parent = self.model
	self.bubble = gui
	return gui
end

-- Shows a speech bubble for a few seconds.
function Npc.say(self: Npc, text: string, seconds: number?)
	local gui = makeBubble(self)
	self.bubbleToken += 1
	local token = self.bubbleToken
	local label = gui:FindFirstChild("Text", true) :: TextLabel
	label.Text = text
	gui.Enabled = true
	local card = gui:FindFirstChild("Card") :: Frame
	local scale = card:FindFirstChildOfClass("UIScale") or Instance.new("UIScale")
	scale.Parent = card
	scale.Scale = 0.6
	TweenService:Create(scale, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 })
		:Play()
	task.delay(seconds or math.clamp(#text / 14, 2.5, 6), function()
		if self.bubbleToken == token and gui.Parent then
			gui.Enabled = false
		end
	end)
end

-- A small symbol over the head: "heart", "anger", "music", "sweat", "zzz", "idea", "question", "sparkle".
local ICONS = {
	heart = "♥",
	anger = "!!",
	music = "♪",
	sweat = "...",
	zzz = "zzz",
	idea = "!",
	question = "?",
	sparkle = "✦",
	sad = "T_T",
}
local ICON_COLORS = {
	heart = Color3.fromRGB(232, 102, 122),
	anger = Color3.fromRGB(199, 56, 63),
	music = Color3.fromRGB(79, 169, 217),
	sweat = Color3.fromRGB(120, 150, 200),
	zzz = Color3.fromRGB(156, 122, 214),
	idea = Color3.fromRGB(214, 160, 44),
	question = Color3.fromRGB(133, 108, 88),
	sparkle = Color3.fromRGB(255, 190, 60),
	sad = Color3.fromRGB(90, 130, 190),
}

function Npc.icon(self: Npc, kind: string, seconds: number?)
	local head = self.model:FindFirstChild("Head") or self.root
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(60, 40)
	gui.StudsOffset = Vector3.new(1.6, 2.6, 0)
	gui.MaxDistance = 80
	gui.Adornee = head :: BasePart
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.Text = ICONS[kind] or kind
	label.TextColor3 = ICON_COLORS[kind] or Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.4
	label.TextStrokeColor3 = Color3.new(1, 1, 1)
	label.Parent = gui
	gui.Parent = self.model
	TweenService
		:Create(gui, TweenInfo.new(seconds or 2.5, Enum.EasingStyle.Sine), { StudsOffset = Vector3.new(1.6, 4, 0) })
		:Play()
	task.delay(seconds or 2.5, function()
		gui:Destroy()
	end)
end

-- A name tag over the head.
function Npc.setName(self: Npc, name: string, color: Color3?)
	local existing = self.model:FindFirstChild("NameTag")
	if existing then
		existing:Destroy()
	end
	local head = self.model:FindFirstChild("Head") or self.root
	local gui = Instance.new("BillboardGui")
	gui.Name = "NameTag"
	gui.Size = UDim2.fromOffset(160, 26)
	gui.StudsOffset = Vector3.new(0, 2.2, 0)
	gui.MaxDistance = 45
	gui.Adornee = head :: BasePart
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.FredokaOne
	label.TextSize = 18
	label.Text = name
	label.TextColor3 = color or Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.25
	label.TextStrokeColor3 = Color3.fromRGB(60, 40, 30)
	label.Parent = gui
	gui.Parent = self.model
end

function Npc.destroy(self: Npc)
	self.moving += 1
	self.model:Destroy()
end

return Npc
