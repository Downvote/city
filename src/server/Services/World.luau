-- The town itself: ground, street, plaza buildings and plot bases; the clock and calendar;
-- lights that come on at night; doors that players open and close and villagers open on their
-- way; the weather.

local Lighting = game:GetService("Lighting")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Tuning = require(Shared.Config.Tuning)
local Town = require(Shared.Data.Town)
local TownModels = require(Shared.Data.TownModels)
local TownMap = require(Shared.Data.TownMap)
local Builder = require(Shared.Build.Builder)
local LowPoly = require(Shared.Build.LowPoly)
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
	-- a window with a NightColor is glass by day and warm lamplight after dark
	local nightColor = p:GetAttribute("NightColor")
	if on then
		p.Material = Enum.Material.Neon
		if typeof(nightColor) == "Color3" then
			if p:GetAttribute("DayColor") == nil then
				p:SetAttribute("DayColor", p.Color)
			end
			p.Color = nightColor
		end
	else
		local day = p:GetAttribute("DayMaterial")
		local mat = type(day) == "string" and (Enum.Material :: any)[day]
		p.Material = mat or Enum.Material.SmoothPlastic
		local dayColor = p:GetAttribute("DayColor")
		if typeof(dayColor) == "Color3" then
			p.Color = dayColor
		end
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

-- How thick the air is: a soft haze on a clear day that fades the far end of the island into the
-- sky, thicker when it's overcast or raining.
local FOG = {
	clear = { density = 0.24, haze = 1 },
	dense = { density = 0.42, haze = 2.4 },
}

-- The drawn look. The user: "stylize everything, including the map, to zenless zone zero style.
-- Make shaders, new models and textures if necessary". Roblox runs no shaders of our own, so the
-- look of a drawn city comes from the light and from the effects laid over the picture:
--   shadows with a hard edge, the way a cel is painted, not a soft blur
--   shade that is a colour (violet) and not grey, under warm sunlight
--   hardly any shine or bounce from the sky, so a wall is one flat colour
--   stronger colours and more contrast over the whole picture
--   a bloom on anything bright, which is what makes the signs glow after dark
-- People get ink outlines on each player's own screen (the client's World/Outlines).
local function stylize()
	Lighting.Brightness = 3.1
	Lighting.Ambient = Color3.fromRGB(126, 118, 158)
	Lighting.OutdoorAmbient = Color3.fromRGB(152, 146, 186)
	Lighting.ColorShift_Top = Color3.fromRGB(255, 236, 200)
	Lighting.EnvironmentDiffuseScale = 0.3
	Lighting.EnvironmentSpecularScale = 0.12
	Lighting.ShadowSoftness = 0.06
	Lighting.GlobalShadows = true
	Lighting.ExposureCompensation = 0.12
	local cc = Instance.new("ColorCorrectionEffect")
	cc.Name = "Grading"
	cc.Saturation = 0.34
	cc.Contrast = 0.17
	cc.Brightness = 0.02
	cc.Parent = Lighting
	grading = cc
	-- bloom you can see: lamps, lit windows and the signs after dark
	local bloom = Instance.new("BloomEffect")
	bloom.Name = "Glow"
	bloom.Intensity = 0.95
	bloom.Size = 28
	bloom.Threshold = 0.92
	bloom.Parent = Lighting
	local rays = Instance.new("SunRaysEffect")
	rays.Name = "Rays"
	rays.Intensity = 0.08
	rays.Spread = 0.72
	rays.Parent = Lighting
	-- a drawing is sharp all the way back: only the far distance softens a touch
	local dof = Instance.new("DepthOfFieldEffect")
	dof.Name = "Lens"
	dof.FocusDistance = 110
	dof.InFocusRadius = 260
	dof.NearIntensity = 0
	dof.FarIntensity = 0.05
	dof.Parent = Lighting
end

-- Fog and a sky, unless the place already has its own.
local function air()
	if not Lighting:FindFirstChildOfClass("Atmosphere") then
		local a = Instance.new("Atmosphere")
		a.Density = FOG.clear.density
		a.Offset = 0.12
		a.Haze = FOG.clear.haze
		a.Glare = 0.3
		a.Color = Color3.fromRGB(226, 230, 246)
		a.Decay = Color3.fromRGB(255, 198, 170)
		a.Parent = Lighting
	end
	if not Lighting:FindFirstChildOfClass("Sky") then
		local sky = Instance.new("Sky")
		sky.SunAngularSize = 14
		sky.MoonAngularSize = 9
		sky.Parent = Lighting
	end
	-- no clouds: the user asked for a clear sky ("remove clouds and birds from the sky"). Take
	-- out any the place came with too.
	local terrain = workspace:FindFirstChildOfClass("Terrain")
	local clouds = terrain and terrain:FindFirstChildOfClass("Clouds")
	if clouds then
		clouds:Destroy()
	end
end

-- Clear light at noon, a deep orange at dawn and dusk, and a blue night in which the colours
-- and the contrast are pushed further, so lit signs and windows stand out of it.
local function grade(h: number)
	local cc = grading
	if not cc then
		return
	end
	local tint, saturation, contrast
	if h >= 7.5 and h <= 16.5 then
		tint, saturation, contrast = Color3.fromRGB(255, 250, 242), 0.34, 0.17
	elseif (h > 16.5 and h < 19.5) or (h > 5 and h < 7.5) then
		tint, saturation, contrast = Color3.fromRGB(255, 212, 184), 0.38, 0.19
	else
		tint, saturation, contrast = Color3.fromRGB(176, 190, 255), 0.44, 0.24
	end
	cc.TintColor = cc.TintColor:Lerp(tint, 0.08)
	cc.Saturation += (saturation - cc.Saturation) * 0.08
	cc.Contrast += (contrast - cc.Contrast) * 0.08
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
		local fog = if kind == "rain" or kind == "storm" or kind == "cloudy" then FOG.dense else FOG.clear
		atmosphere.Density = fog.density
		atmosphere.Haze = fog.haze
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
		local goal = if open then Builder.doorOpen(leaf) else leaf:GetAttribute("Closed")
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
	air()
	-- the low poly kit first, so the map and every house are built in its facets
	local kit, problems = LowPoly.make()
	kit.Parent = ReplicatedStorage
	Builder.useKit(kit)
	for _, why in problems do
		warn("[World] low poly shape not made, keeping Roblox's own: " .. why)
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
