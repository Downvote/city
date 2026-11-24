-- A cutscene: a watched event's big moment played on a set of its own (Data/Stages) behind the
-- dialogue's textbox (UI/Dialogue builds this in place of the busts when it is opened with a
-- Stage). The user: "add cutscenes and scenes like tomodachi life as well". The set stands in a
-- ViewportFrame that fills the screen, with its own camera and light and a sky painted behind it
-- in bands (its sun or moon and its stars go where the camera says they are), and black bars
-- slide in over the top and the bottom of the screen like a film. The player's own camera is
-- never touched ("no need for the camera to jump after clicking on watch").
--
-- The villagers in it are copies of their real models (as UI/ModelPreview makes them) standing on
-- the set's marks, playing their idle. Others from town fill the free marks when the script asks
-- for guests. On each line (Data/Cutscenes works out the beat) the camera eases to the next shot
-- (a wide shot, the two of them, a close one on whoever talks, a slow push in on the line that
-- matters, a pan across the set), everyone turns toward whoever is talking, and they act: the
-- villagers' own gestures (a wave, a cheer, a laugh, a dance) and what is done here with their
-- joints and where they stand (hanging their head, a nod, a hop, going down on one knee, a bow,
-- walking to another mark and sitting down). Nothing is timed here but the moves within a line:
-- the server says when each line comes.
--
-- A move that would take the camera through the set is made as a quick dip to black instead, so
-- the camera never passes through a wall (the Cutscenes spec keeps every move between two shots
-- clear, so this is only for a shot left half way).

local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Stages = require(Shared.Data.Stages)
local Cutscenes = require(Shared.Data.Cutscenes)
local Builder = require(Shared.Build.Builder)

local Kit = require(script.Parent.Kit)
local State = require(script.Parent.Parent.Controllers.State)

local Cutscene = {}

local T = Kit.Theme

Cutscene.Bars = 0.11 -- the letterbox, a share of the screen's height top and bottom
Cutscene.Ease = 0.9 -- seconds the camera takes from one shot to the next
Cutscene.Pan = 4.0 -- and to glide along a pan
Cutscene.Push = 4.4 -- and to push in on a face
Cutscene.Drift = 0.12 -- studs the camera breathes, so a held shot isn't dead still
Cutscene.Walk = 7 -- studs a second a villager walks between marks
Cutscene.SkySpan = 34 -- degrees over the horizon where the sky's top colour starts (tools/preview/stage.py)
Cutscene.SkyMid = 0.6 -- where its middle colour sits between the top and the horizon
Cutscene.SitLift = 1.25 -- a sitting villager's middle over the seat

-- Roblox's own animations, as the villagers play them in town (server/Npc), for a villager whose
-- model carries none of its own.
local ANIMS = {
	idle = "rbxassetid://507766388",
	walk = "rbxassetid://507777826",
	sit = "rbxassetid://2506281703",
	wave = "rbxassetid://507770239",
	point = "rbxassetid://507770453",
	dance = "rbxassetid://507771019",
	dance2 = "rbxassetid://507776043",
	laugh = "rbxassetid://507770818",
	cheer = "rbxassetid://507770677",
}
local LOOPED = { idle = true, walk = true, sit = true, dance = true, dance2 = true }
-- acts that play out and end on their own, and how long they take (the rest last until
-- something else replaces them)
local ONCE =
	{ nod = 1.4, shake = 1.4, hop = 1.35, jump = 1.5, fidget = 2.6, stomp = 1.0, bow = 1.8, spin = 1.2, hug = 2.4 }

local function animId(model: Model, action: string): string?
	local animate = model:FindFirstChild("Animate")
	local folder = animate and animate:FindFirstChild(action)
	if folder then
		for _, a in folder:GetChildren() do
			if a:IsA("Animation") and a.AnimationId ~= "" then
				return a.AnimationId
			end
		end
	end
	return nil
end

local function ease(t: number, style: string): number
	t = math.clamp(t, 0, 1)
	if style == "inout" then
		return 0.5 - math.cos(math.pi * t) / 2
	end
	return 1 - (1 - t) * (1 - t) * (1 - t)
end

local function rand(seed: number): () -> number
	local s = seed % 2147483646 + 1
	return function(): number
		s = (s * 48271) % 2147483647
		return s / 2147483647
	end
end

-- A copy of a villager's model to stand on the set: stood up straight, every joint at rest,
-- nothing in it that runs or floats over their head, and the animations it would play.
local function copyOf(source: Model): any?
	local ok, copy = pcall(function()
		source.Archivable = true
		return source:Clone()
	end)
	if not ok or not copy then
		return nil
	end
	local ids = {}
	for action, default in ANIMS do
		ids[action] = animId(copy, action) or default
	end
	for _, d in copy:GetDescendants() do
		if
			d:IsA("Script")
			or d:IsA("LocalScript")
			or d:IsA("BillboardGui")
			or d:IsA("ProximityPrompt")
			or d:IsA("Highlight")
		then
			d:Destroy()
		end
	end
	local root = copy:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		copy:Destroy()
		return nil
	end
	local joints = {}
	for _, d in copy:GetDescendants() do
		if d:IsA("Motor6D") then
			d.Transform = CFrame.identity
			joints[d.Name] = { motor = d, c0 = d.C0 }
		elseif d:IsA("BasePart") then
			d.CanCollide = false
			d.CastShadow = false
		end
	end
	root.Anchored = true
	local humanoid = copy:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.PlatformStand = false
		humanoid.Sit = false
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	end
	local lift = root.Size.Y / 2 + (if humanoid then humanoid.HipHeight else 2)
	return { model = copy, root = root, humanoid = humanoid, ids = ids, joints = joints, lift = lift, tracks = {} }
end

-- Opens a cutscene inside `parent` (the dialogue scene's root), behind whatever else is in it.
-- opts: script and stage (from Cutscenes.forEvent), event (as EventShow sent it), modelOf (a
-- villager's model in town by their id), and Extras (models of guests, else found in town).
-- Returns { root, join(actor), found(key, model), shows(key), beat(line), close(now) }.
function Cutscene.new(parent: GuiObject, opts: { [string]: any }): any
	local story: Cutscenes.Script = opts.script
	local stage = assert(Stages.get(opts.stage), "no stage " .. tostring(opts.stage))
	local gui = Kit.root()
	local scaleObj = gui:FindFirstChild("Scale")
	local function scale(): number
		return if scaleObj and scaleObj:IsA("UIScale") then scaleObj.Scale else 1
	end
	local inset = Kit.topInset() / scale()

	local root = Kit.new("Frame", {
		Name = "Cutscene",
		BackgroundColor3 = stage.sky.top,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 1, inset),
		Position = UDim2.fromOffset(0, -inset),
		ClipsDescendants = true,
		ZIndex = 0,
		Parent = parent,
	})
	root:SetAttribute("KeepColors", true)
	root:SetAttribute("Stage", stage.id)

	-- the sky: the top colour behind everything, then a band from the top to the horizon, one
	-- from the horizon to the low colour, and the low colour under that
	local sky = Kit.new("Frame", {
		Name = "Sky",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 0,
		Parent = root,
	})
	local function band(name: string, a: Color3, b: Color3, mid: Color3?): Frame
		local f = Kit.new("Frame", {
			Name = name,
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderSizePixel = 0,
			Size = UDim2.fromScale(1, 0.5),
			ZIndex = 0,
			Parent = sky,
		})
		local keys = { ColorSequenceKeypoint.new(0, a) }
		if mid then
			table.insert(keys, ColorSequenceKeypoint.new(Cutscene.SkyMid, mid))
		end
		table.insert(keys, ColorSequenceKeypoint.new(1, b))
		Kit.new("UIGradient", { Name = "Bands", Rotation = 90, Color = ColorSequence.new(keys), Parent = f })
		return f
	end
	local skyUp = band("Upper", stage.sky.top, stage.sky.horizon, stage.sky.mid)
	local skyDown = band("Lower", stage.sky.horizon, stage.sky.low)
	local skyLow = Kit.new("Frame", {
		Name = "Low",
		BackgroundColor3 = stage.sky.low,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 0,
		Parent = sky,
	})
	local discs: { any } = {}
	local function disc(name: string, d: Stages.Disc?)
		if not d then
			return
		end
		local holder = Kit.new("Frame", {
			Name = name,
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromOffset(0, 0),
			ZIndex = 1,
			Parent = sky,
		})
		local rings = {}
		if d.glow then
			for i, k in { 2.6, 1.8, 1.3 } do
				local g = Kit.new("Frame", {
					Name = "Glow" .. i,
					BackgroundColor3 = d.glow,
					BackgroundTransparency = ({ 0.84, 0.72, 0.56 })[i],
					BorderSizePixel = 0,
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(0.5, 0.5),
					ZIndex = 1,
					Parent = holder,
				})
				Kit.corner(g, "round")
				table.insert(rings, { frame = g, k = k })
			end
		end
		local face = Kit.new("Frame", {
			Name = "Face",
			BackgroundColor3 = d.color,
			BorderSizePixel = 0,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			ZIndex = 1,
			Parent = holder,
		})
		Kit.corner(face, "round")
		table.insert(rings, { frame = face, k = 1 })
		local bite: Frame? = nil
		if d.phase and d.phase > 0 then
			bite = Kit.new("Frame", {
				Name = "Shade",
				BackgroundColor3 = stage.sky.horizon,
				BorderSizePixel = 0,
				AnchorPoint = Vector2.new(0.5, 0.5),
				ZIndex = 1,
				Parent = holder,
			})
			Kit.corner(bite :: Frame, "round")
		end
		table.insert(discs, { holder = holder, d = d, rings = rings, bite = bite })
	end
	disc("Sun", stage.sky.sun)
	disc("Moon", stage.sky.moon)
	local stars: { any } = {}
	do
		local next = rand(11)
		for i = 1, stage.sky.stars or 0 do
			local az = next() * 2 * math.pi
			local el = math.rad(10 + next() * 70)
			local size = 1.5 + next() * 2
			local alpha = 0.45 + 0.55 * next()
			local f = Kit.new("Frame", {
				Name = "Star",
				BackgroundColor3 = Color3.fromRGB(255, 250, 236),
				BackgroundTransparency = 1 - alpha,
				BorderSizePixel = 0,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Size = UDim2.fromOffset(size, size),
				ZIndex = 1,
				Parent = sky,
			})
			Kit.corner(f, "round")
			local dir = Vector3.new(math.sin(az) * math.cos(el), math.sin(el), -math.cos(az) * math.cos(el))
			table.insert(stars, { frame = f, dir = dir, i = i })
		end
	end

	-- the set, in its own little world, with its own camera and light
	local view = Kit.new("ViewportFrame", {
		Name = "StageView",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Ambient = stage.light.ambient,
		LightColor = stage.light.color,
		LightDirection = stage.light.dir.Unit,
		ZIndex = 2,
		Parent = root,
	})
	view:SetAttribute("Stage", stage.id)
	local world = Instance.new("WorldModel")
	world.Name = "World"
	world.Parent = view
	local set = Instance.new("Model")
	set.Name = "Set"
	set.Parent = world
	local cam = Instance.new("Camera")
	cam.Name = "StageCamera"
	cam.Parent = view
	view.CurrentCamera = cam

	-- the letterbox, and a curtain of black that lifts as it opens
	local bars = {}
	for i, side in { "Top", "Bottom" } do
		local bar = Kit.new("Frame", {
			Name = "Bar" .. side,
			BackgroundColor3 = T.Shadow,
			BorderSizePixel = 0,
			Size = UDim2.fromScale(1, Cutscene.Bars),
			AnchorPoint = Vector2.new(0, if i == 1 then 0 else 1),
			Position = UDim2.fromScale(0, if i == 1 then -Cutscene.Bars else 1 + Cutscene.Bars),
			ZIndex = 4,
			Parent = root,
		})
		bars[i] = bar
		TweenService:Create(bar, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
			Position = UDim2.fromScale(0, if i == 1 then 0 else 1),
		}):Play()
	end
	local curtain = Kit.new("Frame", {
		Name = "Curtain",
		BackgroundColor3 = T.Shadow,
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 5,
		Parent = root,
	})
	local function lift(seconds: number)
		TweenService:Create(curtain, TweenInfo.new(seconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundTransparency = 1,
		}):Play()
	end

	-- the actors -------------------------------------------------------------------------------------

	local people: { [string]: any } = {} -- by key: a letter, or x1, x2... for a guest
	local order: { string } = {}
	local taken: { [number]: string } = {} -- mark -> who stands on it
	local speaker: string? = nil
	local lastSpeaker: string? = nil
	local stageNow = stage

	local function play(p: any, action: string, fade: number?)
		if not p.humanoid then
			return
		end
		local track = p.tracks[action]
		if not track then
			pcall(function()
				local animator = p.humanoid:FindFirstChildOfClass("Animator")
				if not animator then
					animator = Instance.new("Animator")
					animator.Parent = p.humanoid
				end
				local anim = Instance.new("Animation")
				anim.AnimationId = p.ids[action]
				track = animator:LoadAnimation(anim)
				track.Looped = LOOPED[action] == true
				if not LOOPED[action] then
					track.Priority = Enum.AnimationPriority.Action
				end
			end)
			p.tracks[action] = track
		end
		if track and not track.IsPlaying then
			track:Play(fade or 0.2)
		end
	end

	local function stop(p: any, action: string)
		local track = p.tracks[action]
		if track and track.IsPlaying then
			track:Stop(0.25)
		end
	end

	-- Stands someone on a mark of the set that is up now.
	local function stand(p: any, i: number)
		local m = stageNow.marks[i]
		if p.mark and taken[p.mark] == p.key then
			taken[p.mark] = nil
		end
		p.mark = i
		taken[i] = p.key
		p.feet = m.at
		p.base = m.yaw
		p.yaw = m.yaw
		p.sitting = m.sit == true
		p.walk = nil
		if p.sitting then
			stop(p, "idle")
			play(p, "sit", 0)
		else
			stop(p, "sit")
			play(p, "idle", 0)
		end
	end

	local function freeMark(): number?
		for i in stageNow.marks do
			if not taken[i] then
				return i
			end
		end
		return nil
	end

	local function add(key: string, model: Model, mark: number?): any?
		if people[key] or not root.Parent then
			return people[key]
		end
		local i = mark or freeMark()
		if not i or not stageNow.marks[i] or taken[i] then
			i = freeMark()
		end
		if not i then
			return nil
		end
		local p = copyOf(model)
		if not p then
			return nil
		end
		p.key = key
		p.act = nil
		p.actAt = 0
		p.model.Name = "Actor_" .. key
		p.model.Parent = world
		people[key] = p
		table.insert(order, key)
		stand(p, i)
		return p
	end

	-- the guests a script asks for: other villagers from town, on the free marks
	local function guests()
		local want = story.extras or 0
		if want <= 0 then
			return
		end
		local inEvent: { [string]: boolean } = {}
		local actors = opts.event and opts.event.actors
		if type(actors) == "table" then
			for _, vid in actors do
				inEvent[vid] = true
			end
		end
		local models: { Model } = opts.Extras or {}
		if #models == 0 and opts.modelOf then
			for _, vid in State.data.order or {} do
				if not inEvent[vid] then
					local m = opts.modelOf(vid)
					if m then
						table.insert(models, m)
					end
				end
			end
		end
		local n = 0
		for _, m in models do
			if n >= want or not freeMark() then
				break
			end
			-- a guest leaves the marks the stars are given free
			local i: number? = nil
			for k in stageNow.marks do
				local forStar = false
				for letter in (opts.event and opts.event.names) or {} do
					if Cutscenes.markOf(story, letter) == k then
						forStar = true
					end
				end
				if not taken[k] and not forStar then
					i = k
					break
				end
			end
			if not i then
				break
			end
			n += 1
			add("x" .. n, m, i)
		end
	end

	-- joints and where they stand, for an act at `t` seconds in
	local function pose(p: any, now: number): (CFrame, { [string]: CFrame })
		local t = now - p.actAt
		local act = p.act
		local lift, side, turn, roll = 0, 0, 0, 0
		local j: { [string]: CFrame } = {}
		local function head(pitch: number, yaw: number?, r: number?)
			j.Neck = CFrame.Angles(pitch, yaw or 0, r or 0)
		end
		if act == "sad" then
			head(-0.42 * ease(t / 0.5, "out"))
			j.Waist = CFrame.Angles(-0.12 * ease(t / 0.5, "out"), 0, 0)
		elseif act == "nod" then
			head(-0.32 * math.abs(math.sin(t * 6.5)))
		elseif act == "shake" then
			head(-0.05, 0.42 * math.sin(t * 9) * (1 - t / 1.4))
		elseif act == "tilt" then
			head(0.05, 0.1, 0.3 * ease(t / 0.4, "out"))
		elseif act == "shy" then
			head(-0.3 * ease(t / 0.5, "out"), 0.35 * ease(t / 0.5, "out"))
		elseif act == "doze" then
			head(-0.25 - 0.25 * math.sin(t * 1.6))
		elseif act == "gaze" then
			head(0.5 * ease(t / 0.7, "out"))
		elseif act == "bow" then
			j.Waist = CFrame.Angles(-0.65 * math.sin(math.pi * math.clamp(t / 1.8, 0, 1)), 0, 0)
		elseif act == "hop" then
			lift = 0.55 * math.abs(math.sin(t * 7))
		elseif act == "jump" then
			lift = 1.5 * math.abs(math.sin(t * math.pi / 0.75))
		elseif act == "fidget" then
			side = 0.16 * math.sin(t * 4.2)
			turn = 7 * math.sin(t * 2.1)
		elseif act == "stomp" then
			lift = -0.22 * math.abs(math.sin(t * 9))
			j.Waist = CFrame.Angles(-0.1, 0, 0)
		elseif act == "sway" then
			roll = 0.07 * math.sin(t * 2.2)
		elseif act == "spin" then
			turn = 360 * ease(t / 1.2, "inout")
		elseif act == "kneel" and not p.sitting then
			local k = ease(t / 0.5, "out")
			lift = -0.5 * (p.lift - p.root.Size.Y / 2) * k
			j.RightHip = CFrame.Angles(1.5 * k, 0, 0)
			j.RightKnee = CFrame.Angles(-1.5 * k, 0, 0)
			j.LeftHip = CFrame.Angles(-0.15 * k, 0, 0)
			j.LeftKnee = CFrame.Angles(-1.45 * k, 0, 0)
		elseif act == "hug" then
			local k = math.sin(math.pi * math.clamp(t / 2.4, 0, 1))
			j.Waist = CFrame.Angles(-0.2 * k, 0, 0)
			j.LeftShoulder = CFrame.Angles(1.2 * k, 0, 0)
			j.RightShoulder = CFrame.Angles(1.2 * k, 0, 0)
			p.lean = 0.9 * k
		end
		local yawNow = math.rad(p.yaw + turn)
		local fwd = Vector3.new(math.sin(yawNow), 0, math.cos(yawNow))
		local right = Vector3.new(fwd.Z, 0, -fwd.X)
		local feet = p.feet + right * side + fwd * (if act == "hug" then (p.lean or 0) else 0)
		local up = if p.sitting then Cutscene.SitLift + (p.root.Size.Y / 2 - 1) else p.lift
		local at = CFrame.new(feet + Vector3.new(0, up + lift, 0)) * CFrame.Angles(0, yawNow + math.pi, 0)
		if roll ~= 0 then
			-- a sway turns them about their feet
			at = CFrame.new(feet) * CFrame.Angles(0, 0, roll) * CFrame.new(-feet) * at
		end
		return at, j
	end

	-- the camera ------------------------------------------------------------------------------------

	local now = os.clock
	local camNow = { eye = Vector3.zero, look = -Vector3.zAxis, fov = 40 }
	local legs: { any } = {}
	local legAt = 0

	local function setCam(shot: Stages.Shot)
		camNow = { eye = shot.eye, look = shot.look, fov = shot.fov }
		legs = {}
	end

	local function shotNamed(name: string?, on: string?): (Stages.Shot?, string)
		if (name == "close" or name == "push") and on then
			local p = people[on]
			local i = p and (p.goal or p.mark)
			if i then
				return if name == "close" then Stages.close(stageNow, i) else Stages.push(stageNow, i), name
			end
			return nil, "wide"
		end
		local shot = name and stageNow.shots[name]
		if shot then
			return shot, name :: string
		end
		return stageNow.shots.wide, "wide"
	end

	-- Moves the camera to a shot: eased, along a pan, or a slow push.
	local function goTo(name: string?, on: string?)
		local shot, kind = shotNamed(name, on)
		if not shot then
			shot = stageNow.shots.wide
			kind = "wide"
		end
		local s = shot :: Stages.Shot
		local list = {}
		if kind == "push" then
			table.insert(list, { to = s, dur = Cutscene.Push, style = "inout" })
		else
			table.insert(list, { to = { eye = s.eye, look = s.look, fov = s.fov }, dur = Cutscene.Ease, style = "out" })
			if s.to then
				table.insert(list, { to = s.to, dur = Cutscene.Pan, style = "inout" })
			end
		end
		-- a straight move through the set is made as a dip to black instead
		if Stages.blocked(stageNow, camNow.eye, list[1].to.eye, 0.25) then
			curtain.BackgroundTransparency = 0.05
			TweenService:Create(curtain, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				BackgroundTransparency = 1,
			}):Play()
			setCam(list[1].to)
			table.remove(list, 1)
		end
		legs = list
		legAt = now()
	end

	-- the beats ---------------------------------------------------------------------------------------

	local lastBeat: Cutscenes.Beat? = nil
	local fx: { any } = {}

	local function meteors()
		local W = root.AbsoluteSize.X
		for k = 0, 3 do
			local f = Kit.new("Frame", {
				Name = "Meteor",
				BackgroundColor3 = Color3.fromRGB(255, 246, 220),
				BorderSizePixel = 0,
				AnchorPoint = Vector2.new(1, 0.5),
				Size = UDim2.fromOffset(130, 2),
				Rotation = -24,
				BackgroundTransparency = 1,
				ZIndex = 1,
				Parent = sky,
			})
			Kit.new("UIGradient", {
				Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 1),
					NumberSequenceKeypoint.new(1, 0),
				}),
				Parent = f,
			})
			local x0 = 0.15 + ((k * 0.37) % 0.7)
			table.insert(fx, { frame = f, start = now() + k * 0.85, x = x0, y = 0.12 + (k % 2) * 0.1, w = W })
		end
	end

	local function setAct(p: any, act: string?)
		if p.act == "dance" or p.act == "dance2" then
			stop(p, p.act)
		end
		p.act = act
		p.actAt = now()
		p.lean = 0
		if act and Cutscenes.Acts[act] and ANIMS[act] then
			play(p, act, 0.15)
		end
	end

	local function walkTo(p: any, i: number)
		local m = stageNow.marks[i]
		if not m or (taken[i] and taken[i] ~= p.key) then
			return
		end
		if p.mark and taken[p.mark] == p.key then
			taken[p.mark] = nil
		end
		taken[i] = p.key
		p.goal = i
		-- (whoever gets up off a seat walks on the ground under it)
		local floor = if p.sitting then 0 else p.feet.Y
		local target = Vector3.new(m.at.X, floor, m.at.Z)
		if m.sit then
			-- to the front of the seat, then down onto it
			local f = Stages.facing(m.yaw)
			target = Vector3.new(m.at.X + f.X * 1.3, floor, m.at.Z + f.Z * 1.3)
		end
		if p.sitting then
			p.sitting = false
			stop(p, "sit")
		end
		local dist = (Vector3.new(target.X, 0, target.Z) - Vector3.new(p.feet.X, 0, p.feet.Z)).Magnitude
		p.walk = { from = p.feet, to = target, start = now(), dur = math.max(0.6, dist / Cutscene.Walk), mark = i }
		if p.act == "kneel" then
			setAct(p, nil)
		end
		stop(p, "idle")
		play(p, "walk", 0.15)
	end

	-- Moves the scene to another set: a fade to black, the new set, everyone on their marks.
	local function changeSet(id: string)
		local nextStage = Stages.get(id)
		if not nextStage or nextStage == stageNow then
			return
		end
		curtain.BackgroundTransparency = 0
		stageNow = nextStage
		set:ClearAllChildren()
		pcall(function()
			Builder.instantiate(Stages.prims(id), set, CFrame.identity, { plain = true })
		end)
		view.Ambient = nextStage.light.ambient
		view.LightColor = nextStage.light.color
		view.LightDirection = nextStage.light.dir.Unit
		root.BackgroundColor3 = nextStage.sky.top
		root:SetAttribute("Stage", id)
		view:SetAttribute("Stage", id)
		taken = {}
		for _, key in order do
			people[key].mark = nil
		end
		for _, key in order do
			local p = people[key]
			local want = if #key == 1 then Cutscenes.markOf(story, key) else nil
			local i = if want and nextStage.marks[want] and not taken[want] then want else freeMark()
			if i then
				stand(p, i)
				setAct(p, nil)
				p.goal = nil
			else
				p.model.Parent = nil
			end
		end
		-- the sky's colours
		local up = skyUp:FindFirstChild("Bands")
		if up and up:IsA("UIGradient") then
			local keys = { ColorSequenceKeypoint.new(0, nextStage.sky.top) }
			if nextStage.sky.mid then
				table.insert(keys, ColorSequenceKeypoint.new(Cutscene.SkyMid, nextStage.sky.mid))
			end
			table.insert(keys, ColorSequenceKeypoint.new(1, nextStage.sky.horizon))
			up.Color = ColorSequence.new(keys)
		end
		local down = skyDown:FindFirstChild("Bands")
		if down and down:IsA("UIGradient") then
			down.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, nextStage.sky.horizon),
				ColorSequenceKeypoint.new(1, nextStage.sky.low),
			})
		end
		skyLow.BackgroundColor3 = nextStage.sky.low
		for _, d in discs do
			d.holder.Visible = false
		end
		for _, s in stars do
			s.frame.Visible = false
		end
		lift(0.6)
	end

	local function apply(b: Cutscenes.Beat, line: any)
		if b.set then
			changeSet(b.set)
			setCam(shotNamed(b.shot, b.on) or stageNow.shots.wide)
		end
		-- who is talking, and who everyone turns to
		local who = if type(line.who) == "string" and people[line.who] then line.who else nil
		if who then
			if who ~= speaker then
				lastSpeaker = speaker
			end
			speaker = who
		elseif not line.ask then
			speaker = nil
		end
		for key, p in people do
			p.lookAt = nil
			if speaker and key ~= speaker then
				p.lookAt = speaker
			elseif speaker and key == speaker then
				p.lookAt = if lastSpeaker and people[lastSpeaker] then lastSpeaker else nil
			end
		end
		local looks: { [string]: string } = b.look or {}
		for key, target in looks do
			local p = people[key]
			if p then
				p.lookAt = target
			end
		end
		-- moves
		local moves: { [string]: number } = b.move or {}
		for key, i in moves do
			local p = people[key]
			if p and stageNow.marks[i] then
				walkTo(p, i)
			end
		end
		-- acts: a held one goes when they next talk with nothing to do
		if who and people[who] and not (b.act and b.act[who]) then
			local p = people[who]
			if p.act and p.act ~= "kneel" and not ONCE[p.act] then
				setAct(p, nil)
			end
		end
		local acts: { [string]: string } = b.act or {}
		for key, act in acts do
			local targets = {}
			if key == "all" then
				targets = table.clone(order)
			elseif key == "others" then
				for _, k in order do
					if k ~= speaker then
						table.insert(targets, k)
					end
				end
			else
				targets = { key }
			end
			for _, k in targets do
				local p = people[k]
				if p and Cutscenes.Acts[act] then
					setAct(p, act)
				end
			end
		end
		if b.fx == "stars" and (stageNow.sky.stars or 0) > 0 then
			meteors()
		end
		goTo(b.shot, b.on)
	end

	-- every frame: the camera, the sky, and everyone on the set --------------------------------------------

	local function cameraNow(): (Vector3, Vector3, number)
		local t = now()
		while #legs > 0 do
			local leg = legs[1]
			if not leg.from then
				leg.from = { eye = camNow.eye, look = camNow.look, fov = camNow.fov }
				leg.start = math.max(t, legAt)
			end
			local k = (t - leg.start) / leg.dur
			local e = ease(k, leg.style)
			camNow = {
				eye = leg.from.eye:Lerp(leg.to.eye, e),
				look = leg.from.look:Lerp(leg.to.look, e),
				fov = leg.from.fov + (leg.to.fov - leg.from.fov) * e,
			}
			if k < 1 then
				break
			end
			table.remove(legs, 1)
			legAt = t
		end
		local fwd = (camNow.look - camNow.eye).Unit
		local right = fwd:Cross(Vector3.yAxis)
		right = if right.Magnitude > 1e-3 then right.Unit else Vector3.xAxis
		local drift = right * math.sin(t * 0.37) * Cutscene.Drift
			+ Vector3.yAxis * math.sin(t * 0.53) * Cutscene.Drift * 0.5
		return camNow.eye + drift, camNow.look + drift * 0.5, camNow.fov
	end

	local function skyNow(eye: Vector3, look: Vector3, fov: number)
		local screen = if workspace.CurrentCamera then workspace.CurrentCamera.ViewportSize else Vector2.new(1280, 720)
		local W, H = math.max(1, screen.X), math.max(1, screen.Y)
		local focal = (H / 2) / math.tan(math.rad(fov) / 2)
		local fwd = (look - eye).Unit
		local right = fwd:Cross(Vector3.yAxis)
		right = if right.Magnitude > 1e-3 then right.Unit else Vector3.xAxis
		local up = right:Cross(fwd)
		local pitch = math.asin(math.clamp(fwd.Y, -1, 1))
		local function rowOf(deg: number): number
			local d = math.clamp(math.rad(deg) - pitch, -1.45, 1.45)
			return (H / 2 - focal * math.tan(d)) / H
		end
		local top, hor, low = rowOf(Cutscene.SkySpan), rowOf(0), rowOf(-Cutscene.SkySpan)
		skyUp.Position = UDim2.fromScale(0, top)
		skyUp.Size = UDim2.fromScale(1, math.max(0, hor - top))
		skyDown.Position = UDim2.fromScale(0, hor)
		skyDown.Size = UDim2.fromScale(1, math.max(0, low - hor))
		skyLow.Position = UDim2.fromScale(0, low)
		skyLow.Size = UDim2.fromScale(1, math.max(0, 1 - low))
		local k = scale()
		local function project(dir: Vector3): (number?, number?)
			local d = dir.Unit
			local z = d:Dot(fwd)
			if z <= 0.05 then
				return nil, nil
			end
			return 0.5 + focal * d:Dot(right) / z / W, 0.5 - focal * d:Dot(up) / z / H
		end
		for _, d in discs do
			local x, y = project(d.d.dir)
			d.holder.Visible = x ~= nil and stageNow == stage
			if x and y then
				d.holder.Position = UDim2.fromScale(x, y)
				local size = d.d.size * H / 720 / k
				for _, ring in d.rings do
					ring.frame.Size = UDim2.fromOffset(size * ring.k, size * ring.k)
				end
				if d.bite then
					d.bite.Size = UDim2.fromOffset(size, size)
					d.bite.Position = UDim2.new(0.5, size * (d.d.phase or 0), 0.5, -size * 0.05)
					-- the sky's own colour where the moon is, so the bite matches it
					local c = stage.sky.horizon
					if y < hor then
						local t = math.clamp((y - top) / math.max(1e-6, hor - top), 0, 1)
						local mid = stage.sky.mid
						if mid then
							c = if t < Cutscene.SkyMid
								then stage.sky.top:Lerp(mid, t / Cutscene.SkyMid)
								else mid:Lerp(stage.sky.horizon, (t - Cutscene.SkyMid) / (1 - Cutscene.SkyMid))
						else
							c = stage.sky.top:Lerp(stage.sky.horizon, t)
						end
					end
					d.bite.BackgroundColor3 = c
				end
			end
		end
		for _, s in stars do
			local x, y = project(s.dir)
			s.frame.Visible = x ~= nil and stageNow == stage
			if x and y then
				s.frame.Position = UDim2.fromScale(x, y)
			end
		end
	end

	local function step()
		if not root.Parent then
			return
		end
		local eye, look, fov = cameraNow()
		cam.CFrame = CFrame.lookAt(eye, look)
		cam.FieldOfView = fov
		skyNow(eye, look, fov)
		local t = now()
		for _, p in people do
			if p.model.Parent then
				-- walking to another mark, then turning to face the way it faces
				if p.walk then
					local w = p.walk
					local k = math.clamp((t - w.start) / w.dur, 0, 1)
					p.feet = w.from:Lerp(w.to, k)
					local d = w.to - w.from
					if d.Magnitude > 0.1 then
						p.base = math.deg(math.atan2(d.X, d.Z))
					end
					if k >= 1 then
						local m = stageNow.marks[w.mark]
						p.walk = nil
						p.mark = w.mark
						p.goal = nil
						p.base = m.yaw
						stop(p, "walk")
						if m.sit then
							p.feet = m.at
							p.sitting = true
							play(p, "sit", 0.2)
						else
							p.feet = m.at
							play(p, "idle", 0.2)
						end
					end
				end
				-- turning toward whoever they look at, not too far from the way their mark faces
				local want = p.base
				local target = p.lookAt
				local at: Vector3? = nil
				if target == "camera" then
					at = eye
				elseif target and people[target] then
					at = people[target].feet
				end
				if at and not p.walk then
					local d = at - p.feet
					if Vector3.new(d.X, 0, d.Z).Magnitude > 0.3 then
						local face = math.deg(math.atan2(d.X, d.Z))
						local off = (face - p.base + 540) % 360 - 180
						want = p.base + math.clamp(off, if p.sitting then -25 else -55, if p.sitting then 25 else 55)
					end
				end
				local diff = (want - p.yaw + 540) % 360 - 180
				p.yaw += diff * math.min(1, 0.12)
				if p.act and ONCE[p.act] and t - p.actAt > ONCE[p.act] then
					p.act = nil
				end
				local cf, joints = pose(p, t)
				pcall(function()
					p.model:PivotTo(cf * (p.root.CFrame:Inverse() * p.model:GetPivot()))
				end)
				for name, j in p.joints do
					local extra = joints[name]
					j.motor.C0 = if extra then j.c0 * extra else j.c0
				end
			end
		end
		-- shooting stars across the sky
		for i = #fx, 1, -1 do
			local m = fx[i]
			local k = (t - m.start) / 0.9
			if k >= 1 then
				m.frame:Destroy()
				table.remove(fx, i)
			elseif k >= 0 then
				m.frame.Position = UDim2.fromScale(m.x + 0.22 * k, m.y + 0.1 * k)
				m.frame.BackgroundTransparency = 0.1 + 0.9 * k
			end
		end
	end

	-- the set itself, and the camera on its first shot
	pcall(function()
		Builder.instantiate(Stages.prims(stage.id), set, CFrame.identity, { plain = true })
	end)
	setCam(stage.shots[story.open or "wide"] or stage.shots.wide)
	lift(0.6)
	local conn = RunService.RenderStepped:Connect(step)

	local self: any = { root = root, view = view, camera = cam }

	-- Somebody in the event steps onto their mark (a model that can't be found leaves it empty).
	function self.join(actor: any)
		if type(actor) ~= "table" or people[actor.key] then
			return
		end
		if actor.model then
			add(actor.key, actor.model, Cutscenes.markOf(story, actor.key))
		end
	end

	-- A model found late.
	function self.found(key: string, model: Model)
		if not people[key] then
			add(key, model, Cutscenes.markOf(story, key))
		end
	end

	-- Is this one standing on the set?
	function self.shows(key: string): boolean
		return people[key] ~= nil
	end

	-- What the villagers are saying now (or { ask = true }, { ending = true }).
	function self.beat(line: any)
		if type(line) ~= "table" or not root.Parent then
			return
		end
		local b = Cutscenes.beat(story, line, lastBeat)
		lastBeat = b
		apply(b, line)
	end

	-- Where the camera is now (for the previews and the simulation).
	function self.shot(): (Vector3, Vector3, number)
		return cameraNow()
	end

	function self.close(nowNow: boolean?)
		if conn then
			conn:Disconnect()
		end
		if not root.Parent then
			return
		end
		if nowNow then
			root:Destroy()
			return
		end
		local info = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		TweenService:Create(curtain, info, { BackgroundTransparency = 0 }):Play()
		for i, bar in bars do
			TweenService:Create(bar, info, {
				Position = UDim2.fromScale(0, if i == 1 then -Cutscene.Bars else 1 + Cutscene.Bars),
			}):Play()
		end
	end

	guests()
	step()
	return self
end

return Cutscene
