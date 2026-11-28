--!strict
-- The time of day Build mode shows the town at, on this player's screen only. The user: "in
-- build mode, allow the player to toggle what time they see their city in". Morning, noon,
-- evening or night, or "Now", the town's own time. The server sets the Lighting's clock (and the
-- grade, the ambient light and the air that go with the hour) twice a second and that reaches
-- every player, so while a time is picked it is held here every frame: the clock, and the look of
-- that hour from Tuning.Look, the same rules Services/World follows. The town's own lamps, lit
-- windows and signs (NightLight) are switched for the picked hour too, and put back as they were.
-- Leaving Build mode goes back to the town's own time (BuildUI).

local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Tuning = require(Shared.Config.Tuning)
local Builder = require(Shared.Build.Builder)

local ViewTime = {}

export type Option = { id: string, name: string, icon: string, hour: number? }

local V = Tuning.ViewTime
ViewTime.Options = {
	{ id = "now", name = "Now", icon = "clock" },
	{ id = "morning", name = "Morning", icon = "sun", hour = V.Morning },
	{ id = "noon", name = "Noon", icon = "sun", hour = V.Noon },
	{ id = "evening", name = "Evening", icon = "sun", hour = V.Evening },
	{ id = "night", name = "Night", icon = "moon", hour = V.Night },
} :: { Option }

local picked = 1
local conn: RBXScriptConnection? = nil

-- The town's own hour, worked out as the server does (Services/World.hour).
function ViewTime.townHour(): number
	local t = (os.time() % Tuning.Day.Length) / Tuning.Day.Length
	return (Tuning.Day.StartClock + t * 24) % 24
end

local function isNight(h: number): boolean
	return h >= Tuning.Day.NightStart or h < Tuning.Day.NightEnd
end

local function rgb(t: { number }): Color3
	return Color3.fromRGB(t[1], t[2], t[3])
end

-- The look of an hour: the grade and the air's colours from Tuning.Look.Grade, the ambient light
-- from Tuning.Look.Light (lifted after dark), as Services/World eases toward them.
export type Look = {
	tint: Color3,
	saturation: number,
	contrast: number,
	ambient: Color3,
	outdoor: Color3,
	air: Color3,
	decay: Color3,
}
function ViewTime.lookAt(h: number): Look
	local grade = Tuning.Look.Grade
	local look: any = grade.Night
	for _, g in grade.Hours do
		if h >= g.From and h <= g.To then
			look = g
			break
		end
	end
	local light: any = Tuning.Look.Light
	local shade = if look == grade.Night then light.Night else light
	local colors: any = Tuning.Look.Air.Colors
	local air = colors[look.Air] or colors.day
	return {
		tint = rgb(look.Tint),
		saturation = look.Saturation,
		contrast = look.Contrast,
		ambient = rgb(shade.Ambient),
		outdoor = rgb(shade.OutdoorAmbient),
		air = rgb(air.Color),
		decay = rgb(air.Decay),
	}
end

local function applyLook(h: number)
	local look = ViewTime.lookAt(h)
	Lighting.ClockTime = h
	Lighting.Ambient = look.ambient
	Lighting.OutdoorAmbient = look.outdoor
	local cc = Lighting:FindFirstChild("Grading")
	if cc and cc:IsA("ColorCorrectionEffect") then
		cc.TintColor = look.tint
		cc.Saturation = look.saturation
		cc.Contrast = look.contrast
	end
	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
	if atmosphere then
		atmosphere.Color = look.air
		atmosphere.Decay = look.decay
	end
end

-- The town's lamps, lit windows and signs, as the server left them, kept while they are switched
-- for the picked hour.
type Saved = { material: Enum.Material, color: Color3, lights: { [Light]: boolean } }
local saved: { [BasePart]: Saved } = {}
local savedNight: boolean? = nil -- whether the town's own hour was night when they were kept

local function tagged(): { Instance }
	local ok, list = pcall(function()
		return game:GetService("CollectionService"):GetTagged(Builder.Tags.NightLight)
	end)
	return if ok and type(list) == "table" then list else {}
end

-- Lights a lamp up or puts it out on this screen, as Services/World's setLight does.
local function setLamp(p: BasePart, on: boolean)
	if not saved[p] then
		local lights: { [Light]: boolean } = {}
		for _, l in p:GetChildren() do
			if l:IsA("Light") then
				lights[l] = l.Enabled
			end
		end
		saved[p] = { material = p.Material, color = p.Color, lights = lights }
	end
	local was = saved[p]
	for l in was.lights do
		l.Enabled = on
	end
	if on then
		p.Material = Enum.Material.Neon
		local nightColor = p:GetAttribute("NightColor")
		if typeof(nightColor) == "Color3" then
			p.Color = nightColor
		end
	else
		local day = p:GetAttribute("DayMaterial")
		local mat = if type(day) == "string" then (Enum.Material :: any)[day] else nil
		p.Material = if was.material ~= Enum.Material.Neon then was.material else (mat or Enum.Material.SmoothPlastic)
		local dayColor = p:GetAttribute("DayColor")
		p.Color = if typeof(dayColor) == "Color3" then dayColor else was.color
	end
end

local function switchLamps(h: number)
	if savedNight == nil then
		savedNight = isNight(ViewTime.townHour())
	end
	local on = isNight(h)
	for _, p in tagged() do
		if p:IsA("BasePart") then
			setLamp(p, on)
		end
	end
end

-- Puts the lamps back as the town has them. If the town's own hour crossed dusk or dawn while
-- they were switched here, the server's switch already reached them, and they are left be.
local function restoreLamps()
	if savedNight ~= nil and savedNight == isNight(ViewTime.townHour()) then
		for p, was in saved do
			if p.Parent then
				p.Material = was.material
				p.Color = was.color
				for l, enabled in was.lights do
					l.Enabled = enabled
				end
			end
		end
	end
	saved = {}
	savedNight = nil
end

-- The option picked (1 is "Now").
function ViewTime.index(): number
	return picked
end

function ViewTime.current(): Option
	return ViewTime.Options[picked]
end

-- The hour held on the screen, or nil at the town's own time.
function ViewTime.hour(): number?
	return ViewTime.Options[picked].hour
end

-- Picks an option: holds its hour on the screen every frame, or lets the town's own time back.
function ViewTime.set(i: number)
	local n = #ViewTime.Options
	i = math.clamp(math.floor(i), 1, n)
	picked = i
	local h = ViewTime.Options[i].hour
	if not h then
		if conn then
			conn:Disconnect()
			conn = nil
		end
		restoreLamps()
		-- the town's own hour and its look at once (the server's next tick keeps them there)
		applyLook(ViewTime.townHour())
		return
	end
	switchLamps(h)
	applyLook(h)
	if not conn then
		conn = RunService.RenderStepped:Connect(function()
			local held = ViewTime.hour()
			if held then
				applyLook(held)
			end
		end)
	end
end

-- The next option on (1) or back (-1), round from Night to Now.
function ViewTime.step(dir: number)
	local n = #ViewTime.Options
	ViewTime.set((picked - 1 + (if dir < 0 then -1 else 1)) % n + 1)
end

return ViewTime
