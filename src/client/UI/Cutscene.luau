-- A cutscene: a watched event's big moment played on a set of its own (Data/Stages) behind the
-- dialogue's textbox (UI/Dialogue builds this in place of the busts when it is opened with a
-- Stage). The user: "add cutscenes and scenes like tomodachi life as well", then "could you not
-- move the camera around in events with special cutscenes? also, make them much more detailed,
-- without fake lighting."
--
-- So the set is built in the world on this player's own screen (a folder in Workspace, far out
-- over the sea and high up: Stages.Origin), turned so the real sun or moon stands where the set
-- wants it, and lit by the game's own light at the set's hour: Lighting's clock, ambients, haze
-- and grade are held at that hour while the scene is up (the server keeps setting the town's
-- clock, so this sets them again every frame) and the set's lamps really light it. The camera is
-- the player's own, set Scriptable on each shot: it holds still and cuts to the next shot, never
-- drifting or gliding. Black bars slide in over the top and the bottom like a film. When it ends
-- the screen dips to black, and the camera, the light, the weather and the town come back as they
-- were.
--
-- The villagers in it are copies of their real models standing on the set's marks. On each line
-- (Data/Cutscenes works out the beat) the camera cuts to the next shot (a wide shot, the two of
-- them, a close one on whoever talks, a tighter one on the line that matters), everyone turns to
-- whoever is talking, and they act: the villagers' own gestures (a wave, a cheer, a laugh, a
-- dance, by Roblox's animations) and the moves of Data/Moves, keyed poses played here on their
-- joints (running, lying on the grass, pointing at the sky, a play fight, push ups...). Props on
-- the set move (a cat's tail, a seesaw, a robot's head) and come and go between lines, and a few
-- effects go off (shooting stars, a cloud in somebody's shape, glowing hands, confetti, dust,
-- the lights going out). Nothing is timed here but the moves within a line: the server says
-- when each line comes.

local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Stages = require(Shared.Data.Stages)
local Cutscenes = require(Shared.Data.Cutscenes)
local Moves = require(Shared.Data.Moves)
local Builder = require(Shared.Build.Builder)
local Tuning = require(Shared.Config.Tuning)

local Kit = require(script.Parent.Kit)
local State = require(script.Parent.Parent.Controllers.State)

local Cutscene = {}

local T = Kit.Theme

Cutscene.Bars = 0.11 -- the letterbox, a share of the screen's height top and bottom
Cutscene.Walk = 7 -- studs a second a villager walks between marks
Cutscene.Run = 12 -- and from this pace on they run
Cutscene.Ink = Color3.fromRGB(24, 22, 34) -- the outline round each of them, as in town (World/Outlines)
Cutscene.Shadows = 4 -- how many of a set's lamps cast shadows (the nearest to the middle)

-- Roblox's own animations, as the villagers play them in town (server/Npc), for a villager whose
-- model carries none of its own.
local ANIMS = {
	idle = "rbxassetid://507766388",
	walk = "rbxassetid://507777826",
	wave = "rbxassetid://507770239",
	point = "rbxassetid://507770453",
	dance = "rbxassetid://507771019",
	dance2 = "rbxassetid://507776043",
	laugh = "rbxassetid://507770818",
	cheer = "rbxassetid://507770677",
}
local LOOPED = { idle = true, walk = true, dance = true, dance2 = true }

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

local function rgb(c: { number }): Color3
	return Color3.fromRGB(c[1], c[2], c[3])
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
			d.CanQuery = false
			d.CanTouch = false
			d.CastShadow = d ~= root
		end
	end
	root.Anchored = true
	local humanoid = copy:FindFirstChildOfClass("Humanoid")
	if humanoid then
		pcall(function()
			humanoid.PlatformStand = false
			humanoid.Sit = false
			humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
			humanoid.EvaluateStateMachine = false
		end)
	end
	local hips = if humanoid then humanoid.HipHeight else Moves.Hips
	local lift = root.Size.Y / 2 + hips
	return {
		model = copy,
		root = root,
		humanoid = humanoid,
		ids = ids,
		joints = joints,
		lift = lift,
		scale = math.max(0.3, hips / Moves.Hips),
		tracks = {},
	}
end

-- The game's own light for an hour (as Services/World grades the town), with a set's own haze
-- and grade over it: what Lighting is held at while the scene is up.
local function lightFor(s: Stages.Stage, hour: number): { [string]: any }
	local look = Tuning.Look
	local g = look.Grade.Night
	for _, entry in look.Grade.Hours do
		if hour >= entry.From and hour <= entry.To then
			g = entry
			break
		end
	end
	local night = g == look.Grade.Night
	local shade = if night then look.Light.Night else look.Light
	local air = look.Air.Colors[g.Air] or look.Air.Colors.day
	local own = s.light.air or {}
	local grade = s.light.grade or {}
	return {
		hour = hour,
		ambient = rgb(shade.Ambient),
		outdoor = rgb(shade.OutdoorAmbient),
		airColor = own.color or rgb(air.Color),
		airDecay = own.decay or rgb(air.Decay),
		density = own.density or look.Air.Clear.Density,
		haze = own.haze or look.Air.Clear.Haze,
		tint = grade.tint or rgb(g.Tint),
		saturation = grade.saturation or g.Saturation,
		contrast = grade.contrast or g.Contrast,
	}
end

-- Opens a cutscene inside `parent` (the dialogue scene's root), behind whatever else is in it.
-- opts: script and stage (from Cutscenes.forEvent), event (as EventShow sent it), modelOf (a
-- villager's model in town by their id), and Extras (models of guests, else found in town).
-- Returns { root, folder, join(actor), found(key, model), shows(key), beat(line), shot(),
-- figures(), close(now) }.
function Cutscene.new(parent: GuiObject, opts: { [string]: any }): any
	local story: Cutscenes.Script = opts.script
	local stage = assert(Stages.get(opts.stage), "no stage " .. tostring(opts.stage))
	local hour: number = (story :: any).hour or stage.light.hour
	local gui = Kit.root()
	local scaleObj = gui:FindFirstChild("Scale")
	local function scale(): number
		return if scaleObj and scaleObj:IsA("UIScale") then scaleObj.Scale else 1
	end
	local inset = Kit.topInset() / scale()

	-- the screen: see-through over the world, the letterbox and a curtain of black
	local root = Kit.new("Frame", {
		Name = "Cutscene",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 1, inset),
		Position = UDim2.fromOffset(0, -inset),
		ClipsDescendants = true,
		ZIndex = 0,
		Parent = parent,
	})
	root:SetAttribute("KeepColors", true)
	root:SetAttribute("Stage", stage.id)
	root:SetAttribute("Hour", hour)
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

	-- the world: the set, its props and the cast, in a folder of this screen's own
	local folder = Instance.new("Folder")
	folder.Name = "CutsceneSet"
	folder.Parent = workspace
	local setModel = Instance.new("Model")
	setModel.Name = "Set"
	setModel.Parent = folder

	-- the player's camera and the light, kept to be put back
	local cam = workspace.CurrentCamera
	local saved: { [string]: any } = {}
	pcall(function()
		saved.camType = cam.CameraType
		saved.camCF = cam.CFrame
		saved.fov = cam.FieldOfView
		saved.subject = cam.CameraSubject
		saved.focus = cam.Focus
	end)
	cam:SetAttribute("Cutscene", true)
	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
	local grading = Lighting:FindFirstChild("Grading")
	local LIGHT_KEYS = { "ClockTime", "Ambient", "OutdoorAmbient" }
	saved.light = {}
	for _, k in LIGHT_KEYS do
		pcall(function()
			saved.light[k] = (Lighting :: any)[k]
		end)
	end
	if atmosphere then
		saved.air = {
			Color = atmosphere.Color,
			Decay = atmosphere.Decay,
			Density = atmosphere.Density,
			Haze = atmosphere.Haze,
		}
	end
	if grading and grading:IsA("ColorCorrectionEffect") then
		saved.grade = { TintColor = grading.TintColor, Saturation = grading.Saturation, Contrast = grading.Contrast }
	end
	-- the weather round the camera stops while the scene is up (World's rain is the town's)
	local weatherOff: { [Instance]: boolean } = {}
	local function holdWeather()
		-- (UI/Weather keeps its emitters in WeatherFx; WeatherCloud was its old name)
		local cloud = workspace:FindFirstChild("WeatherFx") or workspace:FindFirstChild("WeatherCloud")
		if cloud then
			for _, e in cloud:GetDescendants() do
				if e:IsA("ParticleEmitter") then
					if weatherOff[e] == nil then
						weatherOff[e] = e.Enabled
					end
					e.Enabled = false
				end
			end
		end
	end

	local stageNow = stage
	local lightNow = lightFor(stage, hour)
	local function holdLight()
		pcall(function()
			Lighting.ClockTime = lightNow.hour
		end)
		pcall(function()
			Lighting.Ambient = lightNow.ambient
			Lighting.OutdoorAmbient = lightNow.outdoor
		end)
		if atmosphere then
			pcall(function()
				atmosphere.Color = lightNow.airColor
				atmosphere.Decay = lightNow.airDecay
				atmosphere.Density = lightNow.density
				atmosphere.Haze = lightNow.haze
			end)
		end
		if grading and grading:IsA("ColorCorrectionEffect") then
			grading.TintColor = lightNow.tint
			grading.Saturation = lightNow.saturation
			grading.Contrast = lightNow.contrast
		end
	end

	-- where the set stands in the world: turned so the real sun (or moon) is where it wants it
	local frame = CFrame.new(Stages.Origin)
	local function placeSet(st: Stages.Stage)
		holdLight()
		local real: Vector3? = nil
		pcall(function()
			local sun = Lighting:GetSunDirection()
			real = if sun.Y > -0.05 then sun else Lighting:GetMoonDirection()
		end)
		local dir = real or Stages.lightAt(lightNow.hour)
		frame = CFrame.new(Stages.Origin) * CFrame.Angles(0, Stages.turnFor(st, dir), 0)
	end

	local lampsLit = true
	local lamps: { { part: BasePart, lights: { Light }, day: Enum.Material, prop: boolean?, stays: boolean? } } = {}
	local function setLamps(on: boolean)
		lampsLit = on
		for _, l in lamps do
			if (l.prop or l.stays) and not on then
				-- (what glows on a prop, a robot's eyes, and a lamp marked `Stays` stay lit in the dark)
				continue
			end
			l.part.Material = if on then Enum.Material.Neon else l.day
			for _, light in l.lights do
				light.Enabled = on
			end
		end
	end

	-- Makes the parts of a list of primitives in `holder`, quiet (nothing to bump, click or step
	-- on) and with the town's switching taken off; its lamps go in the set's list.
	local function make(prims: { any }, holder: Instance, at: CFrame, prop: boolean?): { BasePart }
		local made: { BasePart } = {}
		local ok, why = pcall(function()
			made = Builder.instantiate(prims, holder, at, { plain = true, smooth = true })
		end)
		if not ok then
			warn("cutscene set: " .. tostring(why))
		end
		for _, p in made do
			p.CanCollide = false
			p.CanQuery = false
			p.CanTouch = false
			local glows = p:HasTag(Builder.Tags.NightLight) or p:HasTag(Builder.Tags.PlacedLight)
			if glows then
				p:RemoveTag(Builder.Tags.NightLight)
				p:RemoveTag(Builder.Tags.PlacedLight)
				local lights = {}
				for _, l in p:GetChildren() do
					if l:IsA("Light") then
						table.insert(lights, l)
					end
				end
				table.insert(lamps, {
					part = p,
					lights = lights,
					day = p.Material,
					prop = prop,
					stays = p:GetAttribute("Stays") == true,
				})
			end
		end
		return made
	end

	-- the props: what stands still of each and its moving parts, where each one is now
	local props: { [string]: any } = {}
	local function buildProps(st: Stages.Stage)
		for _, pr in props do
			pr.model:Destroy()
		end
		table.clear(props)
		for name, def in (st.props or {}) :: { [string]: Stages.Prop } do
			local made = Stages.propPrims(st.id, name)
			local model = Instance.new("Model")
			model.Name = "Prop_" .. name
			model.Parent = folder
			local still = Instance.new("Model")
			still.Name = "Still"
			still.Parent = model
			make(made.still, still, CFrame.identity, true)
			local parts = {}
			for part, list in made.parts do
				local m = Instance.new("Model")
				m.Name = part
				m.Parent = model
				local ps = make(list, m, CFrame.identity, true)
				local rest = {}
				for _, p in ps do
					rest[p] = p.CFrame
				end
				parts[part] = { model = m, rest = rest }
			end
			props[name] = { def = def, model = model, still = still, parts = parts, spot = def.start }
			local stillRest = {}
			for _, p in still:GetDescendants() do
				if p:IsA("BasePart") then
					stillRest[p] = p.CFrame
				end
			end
			props[name].stillRest = stillRest
			model.Parent = if def.start then folder else nil
		end
	end

	local function buildSet(st: Stages.Stage)
		setModel:ClearAllChildren()
		table.clear(lamps)
		placeSet(st)
		make(Stages.prims(st.id), setModel, frame)
		buildProps(st)
		-- the nearest few lamps cast shadows of their own
		local ranked = {}
		for _, l in lamps do
			if #l.lights > 0 then
				table.insert(ranked, l)
			end
		end
		table.sort(ranked, function(a, b)
			return (a.part.CFrame.Position - frame.Position).Magnitude
				< (b.part.CFrame.Position - frame.Position).Magnitude
		end)
		for i, l in ranked do
			for _, light in l.lights do
				pcall(function()
					(light :: any).Shadows = i <= Cutscene.Shadows
				end)
			end
		end
		setLamps(Stages.lampsOn(st, lightNow.hour))
	end

	-- the actors -------------------------------------------------------------------------------------

	local people: { [string]: any } = {} -- by key: a letter, or x1, x2... for a guest
	local order: { string } = {}
	local taken: { [number]: string } = {} -- mark -> who stands on it
	local speaker: string? = nil
	local lastSpeaker: string? = nil
	local castNow: { [string]: number }? = nil -- the marks the stars stand on, once a scene moves to another set
	local function markOf(letter: string): number?
		if castNow then
			return castNow[letter]
		end
		return Cutscenes.markOf(story, letter)
	end

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
		p.pose = m.pose or (if m.sit then "sit" else nil)
		p.walk = nil
		play(p, "idle", 0)
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
		if mark == 0 then
			-- offstage: they are in the event but not on the set (a cloud in their shape, say)
			return nil
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
		p.source = model
		p.act = nil
		p.actAt = 0
		p.model.Name = "Actor_" .. key
		p.model.Parent = folder
		pcall(function()
			local ink = Instance.new("Highlight")
			ink.Name = "Ink"
			ink.FillTransparency = 1
			ink.OutlineColor = Cutscene.Ink
			ink.OutlineTransparency = 0
			ink.DepthMode = Enum.HighlightDepthMode.Occluded
			ink.Parent = p.model
		end)
		people[key] = p
		table.insert(order, key)
		stand(p, i)
		return p
	end

	-- the guests a script asks for: other villagers from town, on the free marks
	local function guests(count: number?)
		local want = count or story.extras or 0
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
			local here = false
			for _, p in people do
				if p.source == m then
					here = true
				end
			end
			if here then
				continue
			end
			-- a guest leaves the marks the stars are given free
			local i: number? = nil
			for k in stageNow.marks do
				local forStar = false
				for letter in (opts.event and opts.event.names) or {} do
					if markOf(letter) == k then
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
			add("x" .. (#order + 1), m, i)
		end
	end

	-- the camera: one still shot at a time ------------------------------------------------------------

	local now = os.clock
	local camNow: Stages.Shot = Stages.resolve(stage, stage.shots[story.open or "wide"] or stage.shots.wide, hour)

	local function shotNamed(name: string?, on: string?): Stages.Shot
		if (name == "close" or name == "push") and on then
			local p = people[on]
			local i = p and (p.goal or p.mark)
			if i then
				return if name == "close" then Stages.close(stageNow, i) else Stages.push(stageNow, i)
			end
			return stageNow.shots.wide
		end
		local shot = name and stageNow.shots[name]
		return Stages.resolve(stageNow, shot or stageNow.shots.wide, lightNow.hour)
	end

	-- the beats ---------------------------------------------------------------------------------------

	local lastBeat: Cutscenes.Beat? = nil
	local effects: { any } = {} -- what goes off: { kind, start, parts, step }

	local function setAct(p: any, act: string?)
		if p.walk and act then
			-- whoever is walking does it once they get there
			p.pending = act
			return
		end
		if p.act and ANIMS[p.act] then
			stop(p, p.act)
		end
		p.act = act
		p.actAt = now()
		if act and ANIMS[act] then
			play(p, act, 0.15)
		end
	end

	local function walkTo(p: any, i: number, pace: number?)
		local m = stageNow.marks[i]
		if not m or (taken[i] and taken[i] ~= p.key) then
			return
		end
		if p.mark and taken[p.mark] == p.key then
			taken[p.mark] = nil
		end
		taken[i] = p.key
		p.goal = i
		local target = Vector3.new(m.at.X, m.at.Y, m.at.Z)
		if m.sit then
			-- to the front of the seat, then onto it
			local f = Stages.facing(m.yaw)
			target = Vector3.new(m.at.X + f.X * 1.3, p.feet.Y, m.at.Z + f.Z * 1.3)
		end
		local speed = pace or Cutscene.Walk
		local dist = (Vector3.new(target.X, 0, target.Z) - Vector3.new(p.feet.X, 0, p.feet.Z)).Magnitude
		p.pose = nil
		p.walk = {
			from = p.feet,
			to = target,
			start = now(),
			dur = math.max(0.6, dist / speed),
			mark = i,
			run = speed >= Cutscene.Run,
		}
		if p.act and not (p.act == "run") then
			setAct(p, nil)
		end
		if speed >= Cutscene.Run then
			p.act = "run"
			p.actAt = now()
		else
			play(p, "walk", 0.15)
		end
	end

	-- a cloud in somebody's shape, up in the sky among the others
	local function cloudOf(letter: string)
		local source = opts.event and opts.event.actors and opts.event.actors[letter]
		local model = (people[letter] and people[letter].source) or (source and opts.modelOf and opts.modelOf(source))
		local spot = stageNow.spots and stageNow.spots.cloud
		if not model or not spot then
			return
		end
		local p = copyOf(model)
		if not p then
			return
		end
		local white = Color3.fromRGB(246, 248, 252)
		for _, d in p.model:GetDescendants() do
			if
				d:IsA("Decal")
				or d:IsA("Texture")
				or d:IsA("SurfaceAppearance")
				or d:IsA("Shirt")
				or d:IsA("Pants")
				or d:IsA("ShirtGraphic")
			then
				d:Destroy()
			elseif d:IsA("SpecialMesh") then
				d.TextureId = ""
			elseif d:IsA("BasePart") then
				d.Color = white
				d.Material = Enum.Material.SmoothPlastic
				d.CastShadow = false
				pcall(function()
					(d :: any).TextureID = ""
				end)
			end
		end
		p.model.Name = "Cloud_" .. letter
		p.model.Parent = folder
		local size = 16
		pcall(function()
			p.model:ScaleTo(size)
		end)
		local j, r = Moves.sample("float", 0.8)
		local stand = frame * spot
		pcall(function()
			p.model:PivotTo(Moves.place(stand, r, size) * (p.root.CFrame:Inverse() * p.model:GetPivot()))
		end)
		for name, jj in p.joints do
			local a = j[name]
			jj.motor.C0 = if a then jj.c0 * Moves.turn(a) else jj.c0
		end
		-- soft puffs round them so they read as cloud
		local puffs = {}
		for _, d in p.model:GetDescendants() do
			if d:IsA("BasePart") and d ~= p.root and d.Size.Magnitude > 4 then
				local ball = Instance.new("Part")
				ball.Shape = Enum.PartType.Ball
				ball.Anchored = true
				ball.CanCollide, ball.CanQuery, ball.CanTouch, ball.CastShadow = false, false, false, false
				ball.Material = Enum.Material.SmoothPlastic
				ball.Color = white
				ball.Transparency = 0.15
				local s = math.max(d.Size.X, d.Size.Z) * 1.05
				ball.Size = Vector3.new(s, s, s)
				ball.CFrame = d.CFrame
				ball.Parent = p.model
				table.insert(puffs, ball)
			end
		end
		table.insert(effects, { kind = "cloud", start = now(), model = p.model })
	end

	-- hands that glow, and light what is round them
	local function glowOf(letter: string)
		local p = people[letter]
		if not p or p.glow then
			return
		end
		p.glow = {}
		for _, name in { "LeftHand", "RightHand" } do
			local hand = p.model:FindFirstChild(name)
			if hand and hand:IsA("BasePart") then
				local ball = Instance.new("Part")
				ball.Name = "Glow"
				ball.Shape = Enum.PartType.Ball
				ball.Size = Vector3.new(0.9, 0.9, 0.9)
				ball.Material = Enum.Material.Neon
				ball.Color = Color3.fromRGB(150, 220, 255)
				ball.Transparency = 0.15
				ball.CanCollide, ball.CanQuery, ball.CanTouch, ball.CastShadow = false, false, false, false
				ball.Massless = true
				ball.CFrame = hand.CFrame
				local weld = Instance.new("WeldConstraint")
				weld.Part0 = hand
				weld.Part1 = ball
				weld.Parent = ball
				ball.Parent = p.model
				local light = Instance.new("PointLight")
				light.Color = Color3.fromRGB(150, 220, 255)
				light.Range = 9
				light.Brightness = 2.2
				light.Parent = ball
				pcall(function()
					local sparks = Instance.new("ParticleEmitter")
					sparks.Texture = "rbxasset://textures/particles/sparkles_main.dds"
					sparks.Color = ColorSequence.new(Color3.fromRGB(190, 240, 255))
					sparks.LightEmission = 1
					sparks.Size = NumberSequence.new(0.25, 0)
					sparks.Lifetime = NumberRange.new(0.3, 0.6)
					sparks.Rate = 24
					sparks.Speed = NumberRange.new(1, 3)
					sparks.SpreadAngle = Vector2.new(180, 180)
					sparks.Parent = ball
				end)
				table.insert(p.glow, ball)
			end
		end
	end

	-- a little particle effect: dust at someone's feet, or confetti over the set
	local function burst(kind: string, letter: string?)
		local at = frame.Position + Vector3.new(0, 9, 0)
		local p = letter and people[letter]
		if kind == "dust" then
			if not p then
				return
			end
			at = p.root.CFrame.Position - Vector3.new(0, p.lift - 0.3, 0)
		end
		local holder = Instance.new("Part")
		holder.Name = "Fx"
		holder.Anchored = true
		holder.Transparency = 1
		holder.CanCollide, holder.CanQuery, holder.CanTouch, holder.CastShadow = false, false, false, false
		holder.Size = if kind == "confetti" then Vector3.new(14, 1, 10) else Vector3.new(1.5, 0.2, 1.5)
		holder.CFrame = CFrame.new(at)
		holder.Parent = folder
		pcall(function()
			local e = Instance.new("ParticleEmitter")
			if kind == "confetti" then
				e.Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 120, 120)),
					ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 220, 110)),
					ColorSequenceKeypoint.new(1, Color3.fromRGB(120, 190, 255)),
				})
				e.Size = NumberSequence.new(0.25)
				e.Lifetime = NumberRange.new(3, 4)
				e.Speed = NumberRange.new(2, 5)
				e.Acceleration = Vector3.new(0, -6, 0)
				e.Rotation = NumberRange.new(0, 360)
				e.RotSpeed = NumberRange.new(-200, 200)
				e.EmissionDirection = Enum.NormalId.Bottom
			else
				e.Texture = "rbxasset://textures/particles/smoke_main.dds"
				e.Color = ColorSequence.new(Color3.fromRGB(214, 196, 166))
				e.Size = NumberSequence.new(0.6, 1.8)
				e.Transparency = NumberSequence.new(0.5, 1)
				e.Lifetime = NumberRange.new(0.6, 1)
				e.Speed = NumberRange.new(1, 2)
			end
			e.Rate = if kind == "confetti" then 60 else 30
			e.Parent = holder
		end)
		table.insert(
			effects,
			{ kind = kind, start = now(), holder = holder, follow = p, life = if kind == "confetti" then 5 else 3 }
		)
	end

	-- shooting stars across the sky in front of the camera
	local function meteors()
		for k = 0, 3 do
			local streak = Instance.new("Part")
			streak.Name = "Meteor"
			streak.Anchored = true
			streak.Material = Enum.Material.Neon
			streak.Color = Color3.fromRGB(255, 246, 220)
			streak.Size = Vector3.new(0.5, 0.5, 14)
			streak.CanCollide, streak.CanQuery, streak.CanTouch, streak.CastShadow = false, false, false, false
			streak.Transparency = 1
			streak.Parent = folder
			table.insert(effects, { kind = "meteor", start = now() + k * 0.85, part = streak, k = k, life = 0.9 })
		end
	end

	local function setProp(name: string, spot: any)
		local pr = props[name]
		if not pr then
			return
		end
		if spot == false or not pr.def.spots[spot] then
			pr.spot = nil
			pr.model.Parent = nil
		else
			pr.spot = spot
			pr.model.Parent = folder
		end
	end

	-- Moves the scene to another set: a fade to black, the new set, everyone on their marks.
	local function changeSet(id: string, cast: { [string]: number }?)
		local nextStage = Stages.get(id)
		if not nextStage or nextStage == stageNow then
			return
		end
		curtain.BackgroundTransparency = 0
		stageNow = nextStage
		lightNow = lightFor(nextStage, nextStage.light.hour)
		buildSet(nextStage)
		root:SetAttribute("Stage", id)
		root:SetAttribute("Hour", lightNow.hour)
		taken = {}
		castNow = cast
		for _, key in order do
			people[key].mark = nil
		end
		for _, key in order do
			local p = people[key]
			local want = if #key == 1 then markOf(key) else nil
			local i = if want and nextStage.marks[want] and not taken[want] then want else freeMark()
			if want == 0 then
				i = nil
			end
			if i then
				p.model.Parent = folder
				stand(p, i)
				setAct(p, nil)
				p.goal = nil
			else
				p.model.Parent = nil
			end
		end
		-- the town turns up: whoever else is about fills the marks left
		guests(#nextStage.marks)
		lift(0.6)
	end

	local function apply(b: Cutscenes.Beat, line: any)
		if b.set then
			changeSet(b.set, (b :: any).cast)
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
		-- props come, go and move
		for name, spot in (b :: any).prop or {} do
			setProp(name, spot)
		end
		-- moves
		local moves: { [string]: number } = b.move or {}
		local pace: { [string]: number } = (b :: any).pace or {}
		for key, i in moves do
			local p = people[key]
			if p and stageNow.marks[i] then
				walkTo(p, i, pace[key])
			end
		end
		-- acts: a held one goes when they next talk with nothing to do
		if who and people[who] and not (b.act and b.act[who]) then
			local p = people[who]
			local m = p.act and Moves.list[p.act]
			if p.act and p.act ~= "kneel" and not (m and not m.loop and not m.hold) and not p.walk then
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
		-- what goes off
		local fx = b.fx
		local list = if type(fx) == "table" then fx elseif type(fx) == "string" then { fx } else {}
		for _, f in list do
			local kind, letter = string.match(f, "^(%a+):?(%a*)$")
			if kind == "stars" then
				meteors()
			elseif kind == "cloud" and letter ~= "" then
				cloudOf(letter)
			elseif kind == "glow" and letter ~= "" then
				glowOf(letter)
			elseif kind == "dust" and letter ~= "" then
				burst("dust", letter)
			elseif kind == "confetti" then
				burst("confetti")
			elseif kind == "dark" then
				setLamps(false)
			elseif kind == "lit" then
				setLamps(true)
			elseif kind == "flash" then
				curtain.BackgroundColor3 = Color3.new(1, 1, 1)
				curtain.BackgroundTransparency = 0.1
				TweenService:Create(curtain, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					BackgroundTransparency = 1,
				}):Play()
				task.delay(0.55, function()
					curtain.BackgroundColor3 = T.Shadow
				end)
			end
		end
		-- the camera cuts to its shot and holds it
		camNow = shotNamed(b.shot, b.on)
	end

	-- every frame: the light, the camera, the props and everyone on the set ----------------------------------

	local function cameraNow(): (Vector3, Vector3, number)
		return camNow.eye, camNow.look, camNow.fov
	end

	local function poseOf(p: any, t: number): (CFrame, { [string]: { number } })
		local baseJ, baseR = Moves.sample(p.pose, t)
		local joints, rootOff = baseJ, baseR
		if p.act and Moves.list[p.act] then
			local j, r, done = Moves.sample(p.act, t - p.actAt)
			joints, rootOff = Moves.over(baseJ, baseR, j, r)
			if done then
				p.act = nil
			end
		end
		local yawNow = math.rad(p.yaw)
		local stand = CFrame.new(p.feet + Vector3.new(0, p.lift, 0)) * CFrame.Angles(0, yawNow + math.pi, 0)
		local at = Moves.place(stand, rootOff, p.scale)
		-- a mark that rides on a prop moves with it
		local m = p.mark and stageNow.marks[p.mark]
		if m and m.ride and not p.walk then
			local pr = props[m.ride.prop]
			if pr and pr.spot then
				local moved = Stages.partAt(stageNow, m.ride.prop, m.ride.part, pr.spot, t)
				local rest = pr.def.spots[pr.spot]
				at = moved * rest:Inverse() * at
			end
		end
		return at, joints
	end

	local function step()
		if not root.Parent then
			return
		end
		holdLight()
		holdWeather()
		local t = now()
		local eye, look, fov = cameraNow()
		local worldEye = frame:PointToWorldSpace(eye)
		local worldLook = frame:PointToWorldSpace(look)
		pcall(function()
			cam.CameraType = Enum.CameraType.Scriptable
			cam.CFrame = CFrame.lookAt(worldEye, worldLook)
			cam.FieldOfView = fov
			cam.Focus = CFrame.new(worldLook)
		end)
		-- props: each moving part where its motion has it
		local moveParts, moveFrames = {}, {}
		for name, pr in props do
			if pr.spot then
				local spotCF = frame * pr.def.spots[pr.spot]
				for p, rest in pr.stillRest do
					table.insert(moveParts, p)
					table.insert(moveFrames, spotCF * rest)
				end
				for part, rec in pr.parts do
					local at = frame * Stages.partAt(stageNow, name, part, pr.spot, t)
					for p, rest in rec.rest do
						table.insert(moveParts, p)
						table.insert(moveFrames, at * rest)
					end
				end
			end
		end
		if #moveParts > 0 then
			local ok = pcall(function()
				workspace:BulkMoveTo(moveParts, moveFrames, Enum.BulkMoveMode.FireCFrameChanged)
			end)
			if not ok then
				for i, p in moveParts do
					p.CFrame = moveFrames[i]
				end
			end
		end
		for _, p in people do
			if p.model.Parent then
				-- walking (or running) to another mark, then turning to face the way it faces
				if p.walk then
					local w = p.walk
					local k = math.clamp((t - w.start) / w.dur, 0, 1)
					p.feet = w.from:Lerp(w.to, k)
					local d = w.to - w.from
					if Vector3.new(d.X, 0, d.Z).Magnitude > 0.1 then
						p.base = math.deg(math.atan2(d.X, d.Z))
						p.yaw = p.base
					end
					if k >= 1 then
						local m = stageNow.marks[w.mark]
						p.walk = nil
						p.mark = w.mark
						p.goal = nil
						p.base = m.yaw
						p.feet = m.at
						p.pose = m.pose or (if m.sit then "sit" else nil)
						stop(p, "walk")
						if w.run then
							p.act = nil
						end
						if p.pending then
							local act = p.pending
							p.pending = nil
							setAct(p, act)
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
				if at and not p.walk and not p.pose then
					local d = at - p.feet
					if Vector3.new(d.X, 0, d.Z).Magnitude > 0.3 then
						local face = math.deg(math.atan2(d.X, d.Z))
						local off = (face - p.base + 540) % 360 - 180
						want = p.base + math.clamp(off, -55, 55)
					end
				end
				if not p.walk then
					local diff = (want - p.yaw + 540) % 360 - 180
					p.yaw += diff * 0.12
				end
				local cf, joints = poseOf(p, t)
				p.last = { root = cf, joints = joints }
				pcall(function()
					p.model:PivotTo(frame * cf * (p.root.CFrame:Inverse() * p.model:GetPivot()))
				end)
				for name, j in p.joints do
					local a = joints[name]
					j.motor.C0 = if a then j.c0 * Moves.turn(a) else j.c0
				end
			end
		end
		-- what goes off
		for i = #effects, 1, -1 do
			local e = effects[i]
			local k = (t - e.start) / (e.life or 1e9)
			if e.kind == "meteor" then
				if k >= 1 then
					e.part:Destroy()
					table.remove(effects, i)
				elseif k >= 0 then
					local fwd = (worldLook - worldEye).Unit
					local right = fwd:Cross(Vector3.yAxis).Unit
					local from = worldEye + fwd * 260 + right * (-70 + e.k * 35) + Vector3.yAxis * (95 + (e.k % 2) * 25)
					local dir = (right * 0.9 - Vector3.yAxis * 0.42).Unit
					e.part.CFrame = CFrame.lookAt(from + dir * 90 * k, from + dir * (90 * k + 1))
					e.part.Transparency = 0.1 + 0.85 * k
				end
			elseif e.holder then
				if e.follow and e.follow.root then
					e.holder.CFrame = CFrame.new(e.follow.root.CFrame.Position - Vector3.new(0, e.follow.lift - 0.3, 0))
				end
				if k >= 1 then
					e.holder:Destroy()
					table.remove(effects, i)
				elseif k > 0.6 then
					for _, em in e.holder:GetChildren() do
						if em:IsA("ParticleEmitter") then
							em.Enabled = false
						end
					end
				end
			end
		end
	end

	-- the set itself, and the camera on its first shot
	buildSet(stage)
	lift(0.6)
	local conn = RunService.RenderStepped:Connect(step)

	local self: any = { root = root, folder = folder }
	Cutscene.current = self

	-- Somebody in the event steps onto their mark (a model that can't be found leaves it empty).
	function self.join(actor: any)
		if type(actor) ~= "table" or people[actor.key] then
			return
		end
		if actor.model then
			add(actor.key, actor.model, markOf(actor.key))
		end
	end

	-- A model found late.
	function self.found(key: string, model: Model)
		if not people[key] then
			add(key, model, markOf(key))
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

	-- The shot the camera holds now, in the set's own space (for the previews and the simulation).
	function self.shot(): (Vector3, Vector3, number)
		return cameraNow()
	end

	-- Where the set stands in the world, its hour, and how everyone on it stands: { key, root (in
	-- the set's space), joints, model } (for the previews).
	function self.figures(): { any }
		local out = {}
		for _, key in order do
			local p = people[key]
			if p.model.Parent and p.last then
				table.insert(
					out,
					{ key = key, root = p.last.root, joints = p.last.joints, model = p.source, glow = p.glow ~= nil }
				)
			end
		end
		return out
	end
	function self.where(): (CFrame, string, number)
		return frame, stageNow.id, lightNow.hour
	end
	function self.lampsLit(): boolean
		return lampsLit
	end
	function self.propsNow(): { [string]: string }
		local out = {}
		for name, pr in props do
			if pr.spot then
				out[name] = pr.spot
			end
		end
		return out
	end

	-- Puts everything back: the camera where the player had it, the town's light, the weather.
	local restored = false
	local function restore()
		if restored then
			return
		end
		restored = true
		if Cutscene.current == self then
			Cutscene.current = nil
		end
		if conn then
			conn:Disconnect()
		end
		pcall(function()
			cam:SetAttribute("Cutscene", nil)
			cam.CameraType = saved.camType or Enum.CameraType.Custom
			if saved.subject then
				cam.CameraSubject = saved.subject
			end
			if saved.camCF then
				cam.CFrame = saved.camCF
			end
			if saved.fov then
				cam.FieldOfView = saved.fov
			end
			if saved.focus then
				cam.Focus = saved.focus
			end
		end)
		for k, v in saved.light or {} do
			pcall(function()
				(Lighting :: any)[k] = v
			end)
		end
		if atmosphere and saved.air then
			for k, v in saved.air do
				pcall(function()
					(atmosphere :: any)[k] = v
				end)
			end
		end
		if grading and saved.grade then
			for k, v in saved.grade do
				pcall(function()
					(grading :: any)[k] = v
				end)
			end
		end
		for e, was in weatherOff do
			pcall(function()
				e.Enabled = was
			end)
		end
		folder:Destroy()
	end

	function self.close(nowNow: boolean?)
		if restored then
			return
		end
		if nowNow or not root.Parent then
			restore()
			if root.Parent then
				root:Destroy()
			end
			return
		end
		-- a dip to black over the screen, in a layer of its own (the scene's root goes with the
		-- dialogue), the town back behind it, and the black lifting off it
		local player = Players.LocalPlayer
		local layer = Instance.new("ScreenGui")
		layer.Name = "CutsceneFade"
		layer.IgnoreGuiInset = true
		layer.DisplayOrder = 50
		layer.ResetOnSpawn = false
		layer.Parent = player and player:FindFirstChildOfClass("PlayerGui") or gui.Parent
		local black = Kit.new("Frame", {
			Name = "Black",
			BackgroundColor3 = T.Shadow,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Size = UDim2.fromScale(1, 1),
			Parent = layer,
		})
		local info = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		TweenService:Create(black, info, { BackgroundTransparency = 0 }):Play()
		for i, bar in bars do
			TweenService:Create(bar, info, {
				Position = UDim2.fromScale(0, if i == 1 then -Cutscene.Bars else 1 + Cutscene.Bars),
			}):Play()
		end
		task.delay(0.32, function()
			restore()
			TweenService:Create(black, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				BackgroundTransparency = 1,
			}):Play()
			task.delay(0.5, function()
				layer:Destroy()
			end)
		end)
	end

	guests()
	step()
	return self
end

return Cutscene
