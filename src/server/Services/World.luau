-- The town itself: ground, street, plaza buildings and plot bases; the clock and calendar;
-- lights that come on at night; doors that players open and close and villagers open on their
-- way; the weather.

local Lighting = game:GetService("Lighting")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Tuning = require(Shared.Config.Tuning)
local Town = require(Shared.Data.Town)
local TownModels = require(Shared.Data.TownModels)
local TownMap = require(Shared.Data.TownMap)
local Builder = require(Shared.Build.Builder)
local Textures = require(Shared.Data.Textures)
local Rng = require(Shared.Util.Rng)
local Schema = require(Shared.Sim.Schema)

local World = {}

local SIZE = Tuning.Plot.Size

local mapFolder: Folder
local plotsFolder: Folder
local plotSigns: { [number]: BasePart } = {}

World.ClockChanged = Instance.new("BindableEvent") -- (hour, dayIndex)
World.NewDay = Instance.new("BindableEvent") -- (calendar)

local function part(props: { [string]: any }): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in props do
		(p :: any)[k] = v
	end
	p.Color = Textures.tint(p.Material.Name, p.Color)
	return p
end

-- A prompt that opens a panel on the client (the client reads the Opens attribute).
local function prompt(at: BasePart, action: string, opens: string, distance: number?)
	local pp = Instance.new("ProximityPrompt")
	pp.ActionText = action
	pp.ObjectText = ""
	pp.HoldDuration = 0
	pp.MaxActivationDistance = distance or 12
	pp.RequiresLineOfSight = false
	pp:SetAttribute("Opens", opens)
	pp.Parent = at
	return pp
end

local function anchorPart(model: Model): BasePart
	local best: BasePart? = nil
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") and d.Transparency < 0.9 then
			if not best or d.Size.Magnitude > best.Size.Magnitude then
				best = d
			end
		end
	end
	return best :: BasePart
end

local function signText(board: BasePart, text: string, face: Enum.NormalId?)
	local gui = Instance.new("SurfaceGui")
	gui.Face = face or Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	gui.Parent = board
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextScaled = true
	label.Font = Enum.Font.FredokaOne
	label.TextColor3 = Color3.fromRGB(70, 48, 30)
	label.Name = "Text"
	label.Parent = gui
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0.06, 0)
	pad.PaddingRight = UDim.new(0.06, 0)
	pad.PaddingTop = UDim.new(0.1, 0)
	pad.PaddingBottom = UDim.new(0.1, 0)
	pad.Parent = label
	return label
end

local function buildMap()
	mapFolder = Instance.new("Folder")
	mapFolder.Name = "Town"
	mapFolder.Parent = workspace

	-- streets, sidewalks, the square and the market (Data/TownMap lays them out)
	local ground = Instance.new("Model")
	ground.Name = "Streets"
	Builder.instantiate(TownMap.ground(), ground, CFrame.identity)
	ground.Parent = mapFolder

	for _, p in TownMap.placements() do
		local m = Instance.new("Model")
		m.Name = p.name
		Builder.instantiate(TownMap.prims(p.name), m, p.cf)
		m.Parent = mapFolder
		if p.action and p.opens then
			prompt(anchorPart(m), p.action, p.opens)
		end
		if p.tag == "welcome" then
			local board = m:FindFirstChild("SignBoard", true)
			if board and board:IsA("BasePart") then
				signText(board, "Welcome to " .. Tuning.Game.Name, Enum.NormalId.Back)
			end
		end
	end

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "Spawn"
	spawn.Anchored = true
	spawn.Size = Vector3.new(8, 0.4, 8)
	spawn.CFrame = CFrame.new(Town.Spots.Spawn + Vector3.new(0, 0.1, 0))
	spawn.Transparency = 1
	spawn.CanCollide = false
	spawn.Duration = 0
	spawn.Parent = mapFolder
end

local function buildPlots()
	plotsFolder = Instance.new("Folder")
	plotsFolder.Name = "Plots"
	plotsFolder.Parent = workspace
	for i = 1, Tuning.Plot.Count do
		local frame = Town.plotFrame(i)
		local model = Instance.new("Model")
		model.Name = "Plot" .. i
		model:SetAttribute("Index", i)
		local base = part({
			Name = "Base",
			Size = Vector3.new(SIZE, 1, SIZE),
			CFrame = frame * CFrame.new(SIZE / 2, -0.5, SIZE / 2),
			Color = Color3.fromRGB(112, 188, 84),
			Material = Enum.Material.Grass,
		})
		base.Parent = model
		base.Color = Textures.tint("Grass", Color3.fromRGB(112, 188, 84))
		local build = Instance.new("Folder")
		build.Name = "Build"
		build.Parent = model
		local npcs = Instance.new("Folder")
		npcs.Name = "Villagers"
		npcs.Parent = model
		local sign = Instance.new("Model")
		sign.Name = "Sign"
		Builder.instantiate(
			TownModels.prims("plotSign"),
			sign,
			frame * CFrame.new(SIZE / 2, 0, -1.6) * CFrame.Angles(0, math.pi, 0)
		)
		sign.Parent = model
		local board = sign:FindFirstChild("SignBoard", true) :: BasePart
		signText(board, "Plot " .. i .. "\nfor sale", Enum.NormalId.Back)
		plotSigns[i] = board
		model.Parent = plotsFolder
	end
end

function World.plotModel(i: number): Model
	return plotsFolder:FindFirstChild("Plot" .. i) :: Model
end

function World.setPlotSign(i: number, text: string)
	local board = plotSigns[i]
	if board then
		local label = board:FindFirstChild("Text", true)
		if label and label:IsA("TextLabel") then
			label.Text = text
		end
	end
end

-- Clock and calendar ------------------------------------------------------------------------------

-- The calendar is the same in every server: it follows real time.
function World.dayIndex(): number
	return math.floor(os.time() / Tuning.Day.Length)
end

function World.hour(): number
	local t = (os.time() % Tuning.Day.Length) / Tuning.Day.Length
	return (Tuning.Day.StartClock + t * 24) % 24
end

function World.calendar(): { s: number, d: number, y: number }
	local day = World.dayIndex()
	local perYear = Schema.DaysPerSeason * #Schema.Seasons
	local inYear = day % perYear
	return {
		s = math.floor(inYear / Schema.DaysPerSeason) + 1,
		d = inYear % Schema.DaysPerSeason + 1,
		y = math.floor(day / perYear) % 1000 + 1,
	}
end

function World.isNight(h: number?): boolean
	local hour = h or World.hour()
	return hour >= Tuning.Day.NightStart or hour < Tuning.Day.NightEnd
end

local lightsOn = false

local function setLight(p: Instance, on: boolean)
	if not p:IsA("BasePart") then
		return
	end
	for _, l in p:GetChildren() do
		if l:IsA("Light") then
			l.Enabled = on
		end
	end
	if on then
		p.Material = Enum.Material.Neon
	else
		local day = p:GetAttribute("DayMaterial")
		local mat = type(day) == "string" and (Enum.Material :: any)[day]
		p.Material = mat or Enum.Material.SmoothPlastic
	end
end

local function setAllLights(on: boolean)
	lightsOn = on
	for _, p in CollectionService:GetTagged(Builder.Tags.NightLight) do
		setLight(p, on)
	end
end

-- The look of the world: bright and a little toy-like, the way city builders are. Soft shadows,
-- richer colours, a touch of bloom on lamps and windows, light haze for depth. The colour
-- grading follows the time of day (see `grade`).
local grading: ColorCorrectionEffect? = nil

local function stylize()
	-- cozy and soft: warm sunlight, gentle shadows, a little glow
	Lighting.Brightness = 2.6
	Lighting.Ambient = Color3.fromRGB(150, 140, 132)
	Lighting.OutdoorAmbient = Color3.fromRGB(176, 168, 158)
	Lighting.ColorShift_Top = Color3.fromRGB(255, 232, 196)
	Lighting.EnvironmentDiffuseScale = 0.75
	Lighting.EnvironmentSpecularScale = 0.2
	Lighting.ShadowSoftness = 0.7
	Lighting.GlobalShadows = true
	Lighting.ExposureCompensation = 0.05
	local cc = Instance.new("ColorCorrectionEffect")
	cc.Name = "Grading"
	cc.Saturation = 0.16
	cc.Contrast = 0.02
	cc.Brightness = 0.03
	cc.Parent = Lighting
	grading = cc
	local bloom = Instance.new("BloomEffect")
	bloom.Intensity = 0.35
	bloom.Size = 24
	bloom.Threshold = 1.5
	bloom.Parent = Lighting
	local rays = Instance.new("SunRaysEffect")
	rays.Intensity = 0.05
	rays.Spread = 0.55
	rays.Parent = Lighting
end

-- Warm light in the morning and evening, clear white at noon, cool blue at night.
local function grade(h: number)
	local cc = grading
	if not cc then
		return
	end
	local tint
	if h >= 7.5 and h <= 16.5 then
		tint = Color3.fromRGB(255, 248, 236)
	elseif (h > 16.5 and h < 19.5) or (h > 5 and h < 7.5) then
		tint = Color3.fromRGB(255, 226, 196)
	else
		tint = Color3.fromRGB(196, 210, 255)
	end
	cc.TintColor = cc.TintColor:Lerp(tint, 0.08)
end

local function clockLoop()
	local lastDay = World.dayIndex()
	local lastWhole = -1
	while true do
		local h = World.hour()
		Lighting.ClockTime = h
		grade(h)
		local night = World.isNight(h)
		if night ~= lightsOn then
			setAllLights(night)
		end
		local day = World.dayIndex()
		if day ~= lastDay then
			lastDay = day
			workspace:SetAttribute("Calendar", nil)
			local cal = World.calendar()
			workspace:SetAttribute("Season", cal.s)
			workspace:SetAttribute("Day", cal.d)
			World.NewDay:Fire(cal)
		end
		local whole = math.floor(h)
		if whole ~= lastWhole then
			lastWhole = whole
			World.ClockChanged:Fire(h, day)
		end
		task.wait(0.5)
	end
end

-- Weather -----------------------------------------------------------------------------------------

World.Weathers = { "clear", "cloudy", "rain", "storm", "snow", "blossom", "leaves" }

function World.setWeather(kind: string)
	workspace:SetAttribute("Weather", kind)
	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
	if atmosphere then
		local dense = kind == "rain" or kind == "storm" or kind == "cloudy"
		atmosphere.Density = if dense then 0.4 else 0.24
		atmosphere.Haze = if dense then 2.2 else 0.9
	end
end

function World.weather(): string
	local w = workspace:GetAttribute("Weather")
	return if type(w) == "string" then w else "clear"
end

-- A fresh weather for the season every few in-game hours.
local function weatherLoop()
	local rng = Rng.new()
	while true do
		local cal = World.calendar()
		local options
		if cal.s == 1 then
			options = { "clear", "clear", "blossom", "blossom", "rain", "cloudy" }
		elseif cal.s == 2 then
			options = { "clear", "clear", "clear", "cloudy", "storm", "rain" }
		elseif cal.s == 3 then
			options = { "clear", "leaves", "leaves", "cloudy", "rain" }
		else
			options = { "snow", "snow", "clear", "cloudy" }
		end
		World.setWeather(rng:pick(options))
		task.wait(Tuning.Day.Length / 4)
	end
end

-- Doors -------------------------------------------------------------------------------------------

-- Doors stay shut until someone opens them. A player uses the door's prompt (Open, then Close).
-- A villager opens a door as they come up to it and shuts it behind them a moment after they've
-- gone through; a door a player opened is left the way the player left it.
type Door = { open: boolean, byVillager: boolean, lastNear: number }
local doorState: { [Instance]: Door } = {}
local DOOR_TWEEN = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function openFrame(leaf: BasePart): CFrame
	local closed = leaf:GetAttribute("Closed") :: CFrame
	local frame = leaf:GetAttribute("Frame") :: CFrame
	local slide = leaf:GetAttribute("Slide")
	local lift = leaf:GetAttribute("Lift")
	if type(slide) == "number" then
		return closed + frame.RightVector * slide
	elseif type(lift) == "number" then
		return closed + Vector3.new(0, lift, 0)
	end
	local hx = leaf:GetAttribute("HingeX")
	hx = if type(hx) == "number" then hx else 0
	local angle = if hx < 0 then -math.rad(95) else math.rad(95)
	local pivot = frame * CFrame.new(hx, 0, 0)
	return pivot * CFrame.Angles(0, angle, 0) * pivot:Inverse() * closed
end

local function leavesOf(model: Instance): { BasePart }
	local out = {}
	for _, leaf in model:GetChildren() do
		if leaf:IsA("BasePart") and leaf:HasTag(Builder.Tags.DoorLeaf) then
			table.insert(out, leaf)
		end
	end
	return out
end

local function setDoor(model: Instance, open: boolean)
	local st = doorState[model]
	if not st or st.open == open then
		return
	end
	st.open = open
	for _, leaf in leavesOf(model) do
		local goal = if open then openFrame(leaf) else leaf:GetAttribute("Closed")
		if typeof(goal) == "CFrame" then
			TweenService:Create(leaf, DOOR_TWEEN, { CFrame = goal }):Play()
		end
		local prompt = leaf:FindFirstChild("DoorPrompt")
		if prompt and prompt:IsA("ProximityPrompt") then
			prompt.ActionText = if open then "Close" else "Open"
		end
	end
end

-- Opens or closes a door for a player or a script. Returns whether it's open now.
function World.toggleDoor(model: Instance): boolean
	local st = doorState[model]
	if not st then
		return false
	end
	st.byVillager = false
	setDoor(model, not st.open)
	return st.open
end

local function doorLoop()
	while true do
		task.wait(0.2)
		-- where the villagers are
		local villagers = {}
		for _, plot in plotsFolder:GetChildren() do
			local npcs = plot:FindFirstChild("Villagers")
			if npcs then
				for _, npc in npcs:GetChildren() do
					local root = npc:FindFirstChild("HumanoidRootPart")
					if root and root:IsA("BasePart") then
						table.insert(villagers, root.Position)
					end
				end
			end
		end
		-- every door, by its model
		local doors: { [Instance]: BasePart } = {}
		for _, leaf in CollectionService:GetTagged(Builder.Tags.DoorLeaf) do
			if leaf:IsA("BasePart") and leaf.Parent and leaf:IsDescendantOf(workspace) and not doors[leaf.Parent] then
				doors[leaf.Parent] = leaf
			end
		end
		local now = os.clock()
		for model, first in doors do
			local st = doorState[model]
			if not st then
				st = { open = false, byVillager = false, lastNear = 0 }
				doorState[model] = st
				local prompt = Instance.new("ProximityPrompt")
				prompt.Name = "DoorPrompt"
				prompt.ActionText = "Open"
				prompt.ObjectText = ""
				prompt.HoldDuration = 0
				prompt.MaxActivationDistance = 9
				prompt.RequiresLineOfSight = false
				prompt.Parent = first
				prompt.Triggered:Connect(function()
					World.toggleDoor(model)
				end)
			end
			local frame = first:GetAttribute("Frame")
			if typeof(frame) == "CFrame" then
				local center = (frame :: CFrame).Position + Vector3.new(0, 3, 0)
				local near = false
				for _, pos in villagers do
					if (pos - center).Magnitude < 6.5 then
						near = true
						break
					end
				end
				if near then
					st.lastNear = now
					if not st.open then
						st.byVillager = true
						setDoor(model, true)
					end
				elseif st.open and st.byVillager and now - st.lastNear > 1.2 then
					st.byVillager = false
					setDoor(model, false)
				end
			end
		end
		for model in doorState do
			if not model.Parent then
				doorState[model] = nil
			end
		end
	end
end

function World.init()
	Lighting.ClockTime = World.hour()
	stylize()
	if not Lighting:FindFirstChildOfClass("Atmosphere") then
		local a = Instance.new("Atmosphere")
		a.Density = 0.24
		a.Offset = 0.2
		a.Haze = 0.9
		a.Glare = 0.2
		a.Color = Color3.fromRGB(236, 228, 214)
		a.Decay = Color3.fromRGB(250, 214, 176)
		a.Parent = Lighting
	end
	if not Lighting:FindFirstChildOfClass("Sky") then
		local sky = Instance.new("Sky")
		sky.SunAngularSize = 14
		sky.MoonAngularSize = 9
		sky.Parent = Lighting
	end
	buildMap()
	buildPlots()
	local cal = World.calendar()
	workspace:SetAttribute("Season", cal.s)
	workspace:SetAttribute("Day", cal.d)
	workspace:SetAttribute("Weather", "clear")
end

function World.start()
	CollectionService:GetInstanceAddedSignal(Builder.Tags.NightLight):Connect(function(p)
		setLight(p, lightsOn)
	end)
	setAllLights(World.isNight())
	task.spawn(clockLoop)
	task.spawn(weatherLoop)
	task.spawn(doorLoop)
end

return World
