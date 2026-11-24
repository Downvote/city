-- The town itself: ground, street, plaza buildings and plot bases; the clock and calendar;
-- lights that come on at night; doors that players open and close and villagers open on their
-- way; the weather.

local Lighting = game:GetService("Lighting")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Tuning = require(Shared.Config.Tuning)
local Town = require(Shared.Data.Town)
local TownModels = require(Shared.Data.TownModels)
local TownMap = require(Shared.Data.TownMap)
local Ground = require(Shared.Data.Terrain)
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

-- What the server is doing while it starts, for the loading card (UI/Loading shows it).
local function step(text: string)
	workspace:SetAttribute("Startup", text)
	print("[World] " .. text)
end
World.step = step

-- The island's natural ground as Roblox terrain (Data/Terrain lays it out): the grass with its
-- long blades, the hills, the beach whose edge at the water is a run of curves, and the sea with
-- small waves that run up the sand. Written column by column round the island, in tiles, then
-- the open sea out to the horizon in big blocks. The grass's blades and length are in the place
-- file (default.project.json: Roblox doesn't let scripts set them); the rest is set here.
local function buildTerrain(groundPrims: { any }, placements: { any }, drawn: { [string]: { any } })
	local started = os.clock()
	local terrain = workspace.Terrain
	local water = Ground.Water
	terrain.WaterColor = Color3.fromRGB(water.Color[1], water.Color[2], water.Color[3])
	terrain.WaterTransparency = water.Transparency
	terrain.WaterReflectance = water.Reflectance
	terrain.WaterWaveSize = water.WaveSize
	terrain.WaterWaveSpeed = water.WaveSpeed
	for name, c in Ground.Colors do
		-- (coloured as a part of that material is, so a texture laid over it comes out the same)
		local color = Textures.tint(name, Color3.fromRGB(c[1], c[2], c[3]))
		pcall(function()
			terrain:SetMaterialColor((Enum.Material :: any)[name], color)
		end)
	end
	-- Roblox's own blades stay off: the long grass is SkinnedGrass's (client World/Grass)
	pcall(function()
		(terrain :: any).Decoration = false
	end)
	terrain:Clear()
	local mats: { [string]: any } = {}
	for _, name in Ground.Materials do
		mats[name] = (Enum.Material :: any)[name]
	end
	-- (a breath now and then, so the server isn't stuck in one long step)
	local rest = os.clock()
	local function pause()
		if os.clock() - rest > 0.1 then
			task.wait()
			rest = os.clock()
		end
	end
	local plan = Ground.plan(TownMap.cover(groundPrims, placements, drawn), pause)
	local classic = false
	local tiles = Ground.tiles(plan)
	for n, tile in tiles do
		if n % 8 == 1 then
			step(("Shaping the island (%d of %d)"):format(n, #tiles))
		end
		local lo, hi, channels = Ground.voxels(plan, tile, mats)
		local region = Region3.new(lo, hi)
		if not classic then
			-- sand and sea in one voxel (Roblox's shorelines), so the water's edge lies on the slope
			local ok, why = pcall(function()
				terrain:WriteVoxelChannels(region, Ground.Voxel, channels)
			end)
			if not ok then
				warn("[World] terrain written the older way, one material a voxel: " .. tostring(why))
				classic = true
			end
		end
		if classic then
			local materials, occupancy = Ground.classic(channels, mats)
			terrain:WriteVoxels(region, Ground.Voxel, materials, occupancy)
		end
		pause()
	end
	-- The open sea past the island's shallows is flat parts, not terrain: as terrain it was ten
	-- million voxels of water out to the horizon, slow to write and for every player to load
	-- (the user, stuck on "Writing the island's ground", as this step was called then: "its stuck
	-- here"). A see-through sheet at the sea's level over a dark floor, in pieces of at most 1,000
	-- studs.
	step("Filling in the sea")
	local sea = Instance.new("Folder")
	sea.Name = "OpenSea"
	local deep = Ground.Colors.Slate
	for _, block in Ground.openSea() do
		local p = Instance.new("Part")
		p.Anchored = true
		p.CastShadow = false
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.Material = Enum.Material.SmoothPlastic
		if block.material == "Water" then
			p.Name = "Sea"
			p.Size = Vector3.new(block.size.X, 0.4, block.size.Z)
			p.CFrame = CFrame.new(block.center.X, Ground.WaterY - 0.2, block.center.Z)
			p.Color = Color3.fromRGB(water.Color[1], water.Color[2], water.Color[3])
			p.Transparency = 0.25
			p.Reflectance = 0.05
			p.CanCollide = false
			p.CanQuery = false
		else
			p.Name = "SeaFloor"
			p.Size = Vector3.new(block.size.X, 2, block.size.Z)
			p.CFrame = CFrame.new(block.center.X, Ground.Floor - 1, block.center.Z)
			p.Color = if deep then Color3.fromRGB(deep[1], deep[2], deep[3]) else Color3.fromRGB(60, 90, 120)
		end
		p.Parent = sea
	end
	sea.Parent = workspace
	print(("[World] terrain written in %.1f s"):format(os.clock() - started))
end

local function buildMap()
	mapFolder = Instance.new("Folder")
	mapFolder.Name = "Town"
	mapFolder.Parent = workspace

	-- Everything the town is made of, worked out once (a model used in many places is drawn
	-- once), so its pieces can be merged before anything is built: a building then goes up with
	-- its windows, awnings and railings already on it.
	local groundPrims = TownMap.ground()
	local placements = TownMap.placements()
	local drawn: { [string]: { any } } = {}
	local lists = { groundPrims }
	local weights = { 1 }
	local slot: { [string]: number } = {}
	for _, p in placements do
		if not drawn[p.name] then
			drawn[p.name] = TownMap.prims(p.name)
			table.insert(lists, drawn[p.name])
			table.insert(weights, 0)
			slot[p.name] = #lists
		end
		weights[slot[p.name]] += 1
	end
	-- If the terrain can't be written (an API this server doesn't have, a bad tile), the island
	-- still gets plain grass and sea, and the rest of the town still goes up: a failure here used
	-- to stop the server before the streets, the plots and the spawn were built, and players fell
	-- through an empty world (the user: "it keeps spawning me below the world").
	step("Shaping the island")
	local wrote, why = pcall(buildTerrain, groundPrims, placements, drawn)
	if not wrote then
		warn("[World] the terrain couldn't be written, so the island is plain grass: " .. tostring(why))
		pcall(function()
			local terrain = workspace.Terrain
			terrain:Clear()
			-- (out to the old town's cape on the south)
			local IX, IS, IN = Ground.IslandX, Ground.IslandS + Ground.Cape.out, Ground.IslandN
			local B = Ground.Beach
			terrain:FillBlock(
				CFrame.new(0, Ground.WaterY - 3, (IN - IS) / 2),
				Vector3.new(2 * (IX + B) + 400, 6, IN + IS + 2 * B + 400),
				Enum.Material.Water
			)
			terrain:FillBlock(
				CFrame.new(0, -2.3, (IN - IS) / 2),
				Vector3.new(2 * (IX + B), 4.4, IN + IS + 2 * B),
				Enum.Material.Sand
			)
			terrain:FillBlock(CFrame.new(0, -2.1, (IN - IS) / 2), Vector3.new(2 * IX, 4, IN + IS), Enum.Material.Grass)
		end)
	end
	local started = os.clock()
	-- (a short while only, the most used first: the rest are merged as the town goes up, so the
	-- server doesn't keep players on empty ground for a minute)
	step("Merging the town's details")
	local cut, failed, left = Builder.preparePieces(lists, Tuning.World.MergeBudget, weights)
	if cut + failed + left > 0 then
		print(
			("[World] merged %d kinds of detail piece in %.1f s (%d failed, %d to merge as the town goes up)"):format(
				cut,
				os.clock() - started,
				failed,
				left
			)
		)
	end

	-- streets, sidewalks, the square and the market (Data/TownMap lays them out)
	local building = os.clock()
	step("Putting the town up")
	local ground = Instance.new("Model")
	ground.Name = "Streets"
	Builder.instantiate(groundPrims, ground, CFrame.identity)
	ground.Parent = mapFolder

	for _, p in placements do
		local m = Instance.new("Model")
		m.Name = p.name
		Builder.instantiate(drawn[p.name], m, p.cf)
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
	print(("[World] the town's %d models went up in %.1f s"):format(#placements, os.clock() - building))
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
		base.Color = Textures.tint("Grass", Color3.fromRGB(138, 192, 112))
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
	clear = { density = Tuning.Look.Air.Clear.Density, haze = Tuning.Look.Air.Clear.Haze },
	dense = { density = Tuning.Look.Air.Dense.Density, haze = Tuning.Look.Air.Dense.Haze },
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
local function rgb(c: { number }): Color3
	return Color3.fromRGB(c[1], c[2], c[3])
end

-- The long grass: SkinnedGrass by xander_z22 (the user: "you should use this for grass"), kept in
-- the place file as it came (ServerStorage.Vendor). Its two sample scripts would start a second
-- copy of the grass on every client, so they come out; the module and the meshes go to the
-- clients, which lay the patches (client World/Grass).
function World.shareGrass()
	local vendor = ServerStorage:FindFirstChild("Vendor")
	local pack = vendor and vendor:FindFirstChild("SkinnedGrass")
	if not pack then
		warn("[World] the grass pack is missing from ServerStorage.Vendor")
		return
	end
	local copy = pack:Clone()
	for _, d in copy:GetDescendants() do
		if d:IsA("BaseScript") then
			d:Destroy()
		end
	end
	copy.Parent = ReplicatedStorage
end

local function stylize()
	-- The numbers are in Tuning.Look, where the preview tools read them too.
	local light = Tuning.Look.Light
	Lighting.Brightness = light.Brightness
	Lighting.Ambient = rgb(light.Ambient)
	Lighting.OutdoorAmbient = rgb(light.OutdoorAmbient)
	Lighting.ColorShift_Top = rgb(light.SunTint)
	-- The user then showed that game's streets and asked to "emulate the level of detail of these
	-- shaders": there the sun is low and warm, shadows are long with a slightly soft edge, and the
	-- shade is lifted by light off the sky. So: a sun that rides lower all day (the latitude), a
	-- little softness on the shadow's edge, a little more light from the sky.
	Lighting.GeographicLatitude = light.Latitude
	Lighting.EnvironmentDiffuseScale = light.SkyDiffuse
	Lighting.EnvironmentSpecularScale = light.SkySpecular
	Lighting.ShadowSoftness = light.ShadowSoftness
	Lighting.GlobalShadows = true
	Lighting.ExposureCompensation = light.Exposure
	-- Shadow maps, kept close by when a player's graphics quality drops. Roblox turns shadow map
	-- shadows off below quality level 4 and keeps only its voxel shadows, which are 4 studs
	-- across: too coarse for an eave or a porch roof. Realistic is the style whose shadows have an
	-- edge we can set (ShadowSoftness), and PrioritizeLightingQuality asks Roblox to give up view
	-- distance before shadows. In a pcall: a server that doesn't know them keeps the place's own.
	pcall(function()
		Lighting.LightingStyle = Enum.LightingStyle.Realistic
	end)
	pcall(function()
		Lighting.PrioritizeLightingQuality = true
	end)
	local first = Tuning.Look.Grade.Hours[1]
	local cc = Instance.new("ColorCorrectionEffect")
	cc.Name = "Grading"
	cc.Saturation = first.Saturation
	cc.Contrast = first.Contrast
	cc.Brightness = Tuning.Look.Grade.Brightness
	cc.TintColor = rgb(first.Tint)
	cc.Parent = Lighting
	grading = cc
	-- A glow on what really gives off light: lamps, lit windows and the signs after dark. It
	-- used to start at anything pale (a threshold of 0.92, with nearly full strength and a wide
	-- spread), so a white wall or a lamp at night washed the whole picture out. The user: "the
	-- bloom might be too much". Now only what is brighter than white glows, and gently.
	local bloom = Instance.new("BloomEffect")
	bloom.Name = "Glow"
	bloom.Intensity = Tuning.Look.Bloom.Intensity
	bloom.Size = Tuning.Look.Bloom.Size
	bloom.Threshold = Tuning.Look.Bloom.Threshold
	bloom.Parent = Lighting
	-- rays through the haze, and only the far distance softened
	local rays = Instance.new("SunRaysEffect")
	rays.Name = "Rays"
	rays.Intensity = Tuning.Look.SunRays.Intensity
	rays.Spread = Tuning.Look.SunRays.Spread
	rays.Parent = Lighting
	local lens = Tuning.Look.Lens
	local dof = Instance.new("DepthOfFieldEffect")
	dof.Name = "Lens"
	dof.FocusDistance = lens.FocusDistance
	dof.InFocusRadius = lens.InFocusRadius
	dof.NearIntensity = 0
	dof.FarIntensity = lens.FarIntensity
	dof.Parent = Lighting
end

-- The haze (Tuning.Look.Air), on the place's own Atmosphere if it has one, and a sky.
local function air()
	local a = Lighting:FindFirstChildOfClass("Atmosphere")
	if not a then
		a = Instance.new("Atmosphere")
		a.Parent = Lighting
	end
	local look = Tuning.Look.Air
	local day = look.Colors.day
	a.Density = FOG.clear.density
	a.Offset = look.Offset
	a.Haze = FOG.clear.haze
	a.Glare = look.Glare
	a.Color = rgb(day.Color)
	a.Decay = rgb(day.Decay)
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

-- Clear light round noon, gold through the long morning and afternoon, a deep orange at dawn
-- and dusk, and a blue night in which the colours and the contrast are pushed further, so lit
-- signs and windows stand out of it. The air takes the hour's colour too: a golden haze toward
-- evening, a cool one at night.
local AIR = {
	day = { color = rgb(Tuning.Look.Air.Colors.day.Color), decay = rgb(Tuning.Look.Air.Colors.day.Decay) },
	gold = { color = rgb(Tuning.Look.Air.Colors.gold.Color), decay = rgb(Tuning.Look.Air.Colors.gold.Decay) },
	dusk = { color = rgb(Tuning.Look.Air.Colors.dusk.Color), decay = rgb(Tuning.Look.Air.Colors.dusk.Decay) },
	night = { color = rgb(Tuning.Look.Air.Colors.night.Color), decay = rgb(Tuning.Look.Air.Colors.night.Decay) },
}

local function grade(h: number)
	local cc = grading
	if not cc then
		return
	end
	local look = Tuning.Look.Grade.Night
	for _, g in Tuning.Look.Grade.Hours do
		if h >= g.From and h <= g.To then
			look = g
			break
		end
	end
	local air = AIR[look.Air] or AIR.day
	cc.TintColor = cc.TintColor:Lerp(rgb(look.Tint), 0.08)
	cc.Saturation += (look.Saturation - cc.Saturation) * 0.08
	cc.Contrast += (look.Contrast - cc.Contrast) * 0.08
	-- the shade is darker by day than it used to be, so after dark it is lifted again
	local light = Tuning.Look.Light
	local shade = if look == Tuning.Look.Grade.Night then light.Night else light
	Lighting.OutdoorAmbient = Lighting.OutdoorAmbient:Lerp(rgb(shade.OutdoorAmbient), 0.08)
	Lighting.Ambient = Lighting.Ambient:Lerp(rgb(shade.Ambient), 0.08)
	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
	if atmosphere then
		atmosphere.Color = atmosphere.Color:Lerp(air.color, 0.08)
		atmosphere.Decay = atmosphere.Decay:Lerp(air.decay, 0.08)
	end
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
	-- the wind the grass leans in: a breeze, a gale in a storm
	local wind = if kind == "storm" then Ground.StormWind else Ground.Wind
	workspace.GlobalWind = Vector3.new(wind[1], wind[2], wind[3])
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
	World.shareGrass()
	step("Setting up the lighting")
	Lighting.ClockTime = World.hour()
	stylize()
	air()
	-- the low poly kit first, so the map and every house are built in its facets
	step("Getting the models ready")
	local kit, problems = LowPoly.make()
	kit.Parent = ReplicatedStorage
	Builder.useKit(kit)
	for _, why in problems do
		warn("[World] low poly shape not made, keeping Roblox's own: " .. why)
	end
	-- where solid modelling works, the town's detail pieces (window frames, awnings, shutters)
	-- are merged into one mesh each and copied (buildMap merges the town's before it builds)
	Builder.cutPieces = Builder.hasKit()
	buildMap()
	step("Laying out the plots")
	buildPlots()
	step("Town built")
	task.spawn(function()
		task.wait(2)
		while Builder.Pieces.waiting > 0 do
			task.wait(1)
		end
		local n = Builder.Pieces
		if n.failed > 0 then
			warn(
				("[World] %d kinds of detail piece couldn't be merged and are built from parts (%d merged)"):format(
					n.failed,
					n.cut
				)
			)
		end
	end)
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
