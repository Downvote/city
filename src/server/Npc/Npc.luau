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
		still: number, -- counts the times they slowed to nothing, so a pause between two legs isn't taken for a stop
		busy: boolean,
		seat: Seat?,
		sleeping: boolean,
		bubble: BillboardGui?,
		bubbleToken: number,
		vid: string,
		prompt: ProximityPrompt?, -- "Talk": hold E on them
		talkable: boolean, -- false while something else has them (an event's scene, an outing)
		atWork: boolean, -- at their workplace, working (Services/Villagers' routine keeps it)
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
	-- the swing of a held tool, which the Animate script keeps under this name: a hammer blow
	-- at the builder's bench (Sim/Routine)
	toolslash = "rbxassetid://522635514",
}

local LOOPED = { idle = true, walk = true, run = true, sit = true, dance = true, dance2 = true }

-- Roblox plays the tool swing over whatever else the body is doing, by giving it this priority
-- itself each time. So do we, or the idle animation would hide it.
local PRIORITY: { [string]: Enum.AnimationPriority } = { toolslash = Enum.AnimationPriority.Action }

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
		animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoid),
		tracks = {},
		moving = 0,
		still = 0,
		busy = false,
		seat = nil,
		sleeping = false,
		bubble = nil,
		bubbleToken = 0,
		vid = vid,
		prompt = nil,
		talkable = true,
		atWork = false,
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
		self.still += 1
		if speed > 0.5 then
			self:play("walk")
			self:stop("idle")
		else
			-- a walk can pass through a still moment (a corner, a doorstep): only go back to
			-- standing when they have really stopped, or the walk stutters
			local mine = self.still
			task.delay(Npc.StillAfter, function()
				if self.still == mine and not self.sleeping and not self.seat then
					self:stop("walk")
					self:play("idle")
				end
			end)
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
	if PRIORITY[action] then
		track.Priority = PRIORITY[action]
	end
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
-- How villagers path: a little narrower than a door, allowed to hop small steps, and happy to
-- walk through door leaves (they swing open as you come up to them).
local AGENT = {
	AgentRadius = 1.3,
	AgentHeight = 5,
	AgentCanJump = true,
	AgentCanClimb = false,
	WaypointSpacing = 3,
	Costs = { Water = 20, Door = 1 },
}

-- Is the straight line from the villager to a point free of walls and furniture?
function Npc.clearLine(self: Npc, target: Vector3): boolean
	local from = self.root.Position
	local to = Vector3.new(target.X, from.Y, target.Z)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { self.model }
	params.RespectCanCollide = true
	local hit = workspace:Raycast(from, to - from, params)
	if not hit then
		return true
	end
	-- other people don't count as walls
	local model = hit.Instance:FindFirstAncestorOfClass("Model")
	return model ~= nil and model:FindFirstChildOfClass("Humanoid") ~= nil
end

local function computePath(self: Npc, target: Vector3): { PathWaypoint }?
	local path = PathfindingService:CreatePath(AGENT)
	local ok = pcall(function()
		path:ComputeAsync(self.root.Position, target)
	end)
	if ok and path.Status == Enum.PathStatus.Success then
		return path:GetWaypoints()
	end
	return nil
end

-- The user: "the characters seem to walk stop walk stop instead of one continuous walk". A path
-- is a string of waypoints a few studs apart, and each used to be a walk of its own: they
-- walked onto a waypoint, stopped, and only set off for the next when somebody looked. Now a
-- path is one walk: the next leg starts while they are still moving, a little before the
-- waypoint (Reach), and if they do arrive on one the next leg starts in that same moment.
Npc.Reach = 1.2 -- how near a waypoint (flat, in studs) they get before heading for the next
Npc.Arrived = 2.6 -- how near counts as there when the humanoid says a move is over
Npc.StillAfter = 0.25 -- seconds of standing before the walk animation gives way to the idle one

-- Which waypoint of `list` to head for from `position`: the one at `index`, or a later one when
-- they are already as good as on it. Never past the last (that one they walk right onto).
function Npc.nextLeg(list: { any }, index: number, position: Vector3, reach: number): number
	while index < #list do
		local at = list[index].Position
		local dx, dz = at.X - position.X, at.Z - position.Z
		if dx * dx + dz * dz > reach * reach then
			break
		end
		index += 1
	end
	return index
end

-- How far a path runs over the ground, waypoint to waypoint.
function Npc.pathLength(list: { any }): number
	local total = 0
	for i = 2, #list do
		local a, b = list[i - 1].Position, list[i].Position
		total += Vector3.new(b.X - a.X, 0, b.Z - a.Z).Magnitude
	end
	return total
end

-- How far the walk to a point would be (without taking it), or nil when there is no way there.
function Npc.routeLength(self: Npc, target: Vector3): number?
	local list = computePath(self, target)
	return if list then Npc.pathLength(list) else nil
end

-- Walks to a world point along a real path round walls and furniture. Returns true if it got
-- there, or false and why not: "noroute" (a point nothing can reach is refused: no walking into
-- walls), "far" (the way there is longer than `maxPath` studs: for a spot that should be a few
-- steps off, a long way means it lies behind a wall), "cancelled" (a newer walk, a halt, the
-- body gone) or "stuck".
function Npc.walkTo(self: Npc, target: Vector3, timeout: number?, maxPath: number?): (boolean, string?)
	self:standUp()
	self.moving += 1
	local token = self.moving
	local deadline = os.clock() + (timeout or 25)
	local tries = 0
	while tries < 3 do
		tries += 1
		if self.moving ~= token or not self.model.Parent then
			return false, "cancelled"
		end
		local waypoints = computePath(self, target)
		if not waypoints then
			-- no route; only step there if it's right in front of them with nothing in the way
			if (target - self.root.Position).Magnitude < 6 and self:clearLine(target) then
				waypoints = {
					{ Position = self.root.Position, Action = Enum.PathWaypointAction.Walk },
					{ Position = target, Action = Enum.PathWaypointAction.Walk },
				} :: any
			else
				return false, "noroute"
			end
		end
		local list = waypoints :: any
		if maxPath and Npc.pathLength(list) > maxPath then
			return false, "far"
		end
		local index = 1 -- the waypoint they are heading for (the first is where they stand)
		local arrived = #list < 2
		local stuck = false
		local again = false -- the engine gave a move up: set off for the same waypoint once more
		-- sets off for waypoint `to`, hopping wherever a waypoint passed on the way asks for it
		local function head(to: number)
			for i = index + 1, to do
				if list[i].Action == Enum.PathWaypointAction.Jump then
					self.humanoid.Jump = true
				end
			end
			index = to
			self.humanoid:MoveTo(list[index].Position)
		end
		-- a leg that ends starts the next in the same moment, so they never stand between two
		local conn = self.humanoid.MoveToFinished:Connect(function()
			if self.moving ~= token or arrived or stuck then
				return
			end
			local pos = self.root.Position
			local at = list[index].Position
			if Vector3.new(at.X - pos.X, 0, at.Z - pos.Z).Magnitude > Npc.Arrived then
				-- the engine gives a move up after eight seconds. The watch below sets off for
				-- the same waypoint again (not from in here: a move must never restart itself
				-- from its own ending), and says when they are really stuck
				again = true
			elseif index < #list then
				head(index + 1)
			else
				arrived = true
			end
		end)
		if not arrived then
			head(Npc.nextLeg(list, 2, self.root.Position, Npc.Reach))
		end
		-- watch for being stuck on a corner: no progress for a while means replan
		local lastPos = self.root.Position
		local lastMove = os.clock()
		while not arrived and self.moving == token and os.clock() < deadline do
			task.wait(0.1)
			if arrived or self.moving ~= token then
				break
			end
			local pos = self.root.Position
			-- nearly on this waypoint: head for the next while they are still moving
			local to = Npc.nextLeg(list, index, pos, Npc.Reach)
			if to ~= index then
				again = false
				head(to)
			elseif again then
				again = false
				self.humanoid:MoveTo(list[index].Position)
			end
			if (pos - lastPos).Magnitude > 0.4 then
				lastPos = pos
				lastMove = os.clock()
			elseif os.clock() - lastMove > 1.2 then
				self.humanoid.Jump = true
				if os.clock() - lastMove > 2.4 then
					stuck = true
					break
				end
			end
		end
		conn:Disconnect()
		if self.moving ~= token then
			return false, "cancelled"
		end
		if (self.root.Position - target).Magnitude < 3.5 then
			return true
		end
		if os.clock() >= deadline then
			break
		end
	end
	self:halt()
	if (self.root.Position - target).Magnitude < 3.5 then
		return true
	end
	return false, "stuck"
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

-- Keeps the server simulating the villager (players' clients must not own NPCs).
function Npc.claim(self: Npc)
	if self.root.Anchored or not self.root:IsDescendantOf(workspace) then
		return
	end
	pcall(function()
		self.root:SetNetworkOwner(nil)
	end)
end

-- The prompt players hold E on to talk to a villager (touch and gamepads get their own way to
-- hold it). It sits on the body's root part, so it comes and goes with the body: a new look is
-- a new body, and Services/Villagers puts a new prompt on it. It is off while they sleep and
-- while something else has them (setTalkable).
function Npc.talkPrompt(self: Npc, name: string): ProximityPrompt
	local old = self.prompt
	if old then
		old:Destroy()
	end
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "TalkPrompt"
	prompt.ActionText = "Talk"
	prompt.ObjectText = name
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.HoldDuration = Tuning.Talk.HoldSeconds
	prompt.MaxActivationDistance = Tuning.Talk.Distance
	prompt.RequiresLineOfSight = false
	prompt.Enabled = self.talkable and not self.sleeping
	prompt.Parent = self.root
	self.prompt = prompt
	return prompt
end

function Npc.setTalkable(self: Npc, on: boolean)
	self.talkable = on
	local prompt = self.prompt
	if prompt then
		prompt.Enabled = on and not self.sleeping
	end
end

function Npc.standUp(self: Npc)
	if self.sleeping then
		self.sleeping = false
		self.root.Anchored = false
		self.humanoid.PlatformStand = false
		self.humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
		self:stop("sit")
		self:claim()
		self:setTalkable(self.talkable)
	end
	if self.seat then
		self.humanoid.Sit = false
		self.humanoid.Jump = true
		self.seat = nil
		self:stop("sit")
		task.wait(0.15)
		self:claim()
	end
end

-- Lies down on a bed spot (a part from a bed recipe's r:sleep()).
function Npc.sleep(self: Npc, spot: BasePart)
	self:halt()
	self.sleeping = true
	self:setTalkable(self.talkable) -- nobody is woken for a chat
	self:stop("walk")
	self:play("idle")
	self.humanoid.PlatformStand = true
	self.root.Anchored = true
	-- on their back: head toward the spot's -Z (the bed head), face up
	local lying = spot.CFrame
		* CFrame.fromMatrix(Vector3.new(0, 0.2 + self.root.Size.Z / 2, 0), Vector3.new(-1, 0, 0), Vector3.new(0, 0, -1))
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
	-- dark like the rest of the interface (the client's UI/Kit: Paper, Line and Ink)
	frame.BackgroundColor3 = Color3.fromRGB(37, 40, 54)
	frame.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = frame
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(66, 71, 93)
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
	label.TextColor3 = Color3.fromRGB(236, 238, 246)
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
	label.TextStrokeColor3 = Color3.fromRGB(16, 18, 26)
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
