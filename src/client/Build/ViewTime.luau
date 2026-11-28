--!strict
-- The time of day the town is shown at, on this player's screen only. The user: "in build mode,
-- allow the player to toggle what time they see their city in". Morning, noon, evening or night,
-- or "Now", the town's own time; Build mode opens at noon (the user: "can you make the default for
-- build mode day time?", Tuning.ViewTime.Default) and leaving it goes back to the town's own time
-- (BuildUI). The server sets the Lighting's clock (and the grade, the ambient light and the air
-- that go with the hour) twice a second and that reaches every player, so while an hour is shown
-- it is held here every frame: the clock, and the look of that hour from Tuning.Look, the same
-- rules Services/World follows. The town's own lamps, lit windows and signs (NightLight) are
-- switched for that hour too, and put back as they were.
--
-- Something else may hold an hour for a while, over Build mode's pick: the creator (the user:
-- "weather effects and time seems to affect the avatar creator") holds a clear noon, and asks for
-- clear weather too (`ViewTime.clear()`: UI/Weather stops what falls and clears the air,
-- Controllers/Audio quiets the rain). A cutscene owns the light while it plays (the camera's
-- `Cutscene` attribute), so nothing is held here then.

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

-- Holds from elsewhere, by who asked (the last one asked wins): an hour, and whether the weather
-- should stand down while it lasts.
type Hold = { who: string, hour: number, clear: boolean }
local holds: { Hold } = {}

-- The option Build mode opens at (Tuning.ViewTime.Default; 1 is "Now").
function ViewTime.defaultIndex(): number
	for i, o in ViewTime.Options do
		if o.id == V.Default then
			return i
		end
	end
	return 1
end

-- The town's own hour, worked out as the server does (Services/World.hour).
function ViewTime.townHour(): number
	local t = (os.time() % Tuning.Day.Length) / Tuning.Day.Length
	return (Tuning.Day.StartClock + t * 24) % 24
end

-- The town's own weather now (Services/World writes it on workspace).
function ViewTime.townWeather(): string
	local w = workspace:GetAttribute("Weather")
	return if type(w) == "string" and Tuning.Weather.Looks[w] then w else "clear"
end

local function isNight(h: number): boolean
	return h >= Tuning.Day.NightStart or h < Tuning.Day.NightEnd
end

local function rgb(t: { number }): Color3
	return Color3.fromRGB(t[1], t[2], t[3])
end

-- The look of an hour in a weather: the grade and the air's colours from Tuning.Look.Grade, the
-- ambient light from Tuning.Look.Light (lifted after dark), and the weather's sun, shadows and grey
-- (Tuning.Weather.Looks), as Services/World eases toward them.
export type Look = {
	tint: Color3,
	saturation: number,
	contrast: number,
	ambient: Color3,
	outdoor: Color3,
	air: Color3,
	decay: Color3,
	brightness: number,
	softness: number,
}
function ViewTime.lookAt(h: number, weather: string?): Look
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
	local sky: any = Tuning.Weather.Looks[weather or "clear"] or Tuning.Weather.Looks.clear
	return {
		tint = rgb(look.Tint),
		saturation = look.Saturation + sky.Grey,
		contrast = look.Contrast,
		ambient = rgb(shade.Ambient),
		outdoor = rgb(shade.OutdoorAmbient),
		air = rgb(air.Color),
		decay = rgb(air.Decay),
		brightness = light.Brightness * sky.Sun,
		softness = sky.Soft,
	}
end

local function applyLook(h: number, weather: string)
	local look = ViewTime.lookAt(h, weather)
	Lighting.ClockTime = h
	Lighting.Ambient = look.ambient
	Lighting.OutdoorAmbient = look.outdoor
	Lighting.Brightness = look.brightness
	Lighting.ShadowSoftness = look.softness
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
-- for the hour shown.
type Saved = { material: Enum.Material, color: Color3, lights: { [Light]: boolean } }
local saved: { [BasePart]: Saved } = {}
local savedNight: boolean? = nil -- whether the town's own hour was night when they were kept
local lampsOn: boolean? = nil -- what they are switched to now

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
		p.Material = if was.material ~= Enum.Material.Neon then was.material else (mat or Enum.Material.Plaster)
		local dayColor = p:GetAttribute("DayColor")
		p.Color = if typeof(dayColor) == "Color3" then dayColor else was.color
	end
end

local function switchLamps(h: number)
	if savedNight == nil then
		savedNight = isNight(ViewTime.townHour())
	end
	local on = isNight(h)
	if on == lampsOn then
		return
	end
	lampsOn = on
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
	lampsOn = nil
end

local function topHold(): Hold?
	return holds[#holds]
end

-- The option picked in Build mode (1 is "Now").
function ViewTime.index(): number
	return picked
end

function ViewTime.current(): Option
	return ViewTime.Options[picked]
end

-- The hour held on the screen (a hold's, else Build mode's pick), or nil at the town's own time.
function ViewTime.hour(): number?
	local hold = topHold()
	if hold then
		return hold.hour
	end
	return ViewTime.Options[picked].hour
end

-- Whether something on this screen wants clear weather now (the creator).
function ViewTime.clear(): boolean
	for _, hold in holds do
		if hold.clear then
			return true
		end
	end
	return false
end

-- The weather the held look is drawn in: clear while a hold asks for it, else the town's.
local function weatherShown(): string
	return if ViewTime.clear() then "clear" else ViewTime.townWeather()
end

local function cutscene(): boolean
	local cam = workspace.CurrentCamera
	return cam ~= nil and cam:GetAttribute("Cutscene") == true
end

-- Holds whatever is to be held now, or lets the town's own time back.
local function refresh()
	local h = ViewTime.hour()
	if not h then
		if conn then
			conn:Disconnect()
			conn = nil
		end
		restoreLamps()
		-- the town's own hour and its look at once (the server's next tick keeps them there)
		applyLook(ViewTime.townHour(), ViewTime.townWeather())
		return
	end
	switchLamps(h)
	applyLook(h, weatherShown())
	if not conn then
		conn = RunService.RenderStepped:Connect(function()
			local held = ViewTime.hour()
			if held and not cutscene() then
				switchLamps(held)
				applyLook(held, weatherShown())
			end
		end)
	end
end

-- Picks an option in Build mode: holds its hour on the screen every frame, or lets the town's own
-- time back (unless something else holds one).
function ViewTime.set(i: number)
	local n = #ViewTime.Options
	picked = math.clamp(math.floor(i), 1, n)
	refresh()
end

-- The next option on (1) or back (-1), round from Night to Now.
function ViewTime.step(dir: number)
	local n = #ViewTime.Options
	ViewTime.set((picked - 1 + (if dir < 0 then -1 else 1)) % n + 1)
end

-- Holds `hour` on this screen for `who` until it lets go (`clear`: and clear weather), over Build
-- mode's pick. Asking again moves it to the top.
function ViewTime.hold(who: string, hour: number, clear: boolean?)
	for i = #holds, 1, -1 do
		if holds[i].who == who then
			table.remove(holds, i)
		end
	end
	table.insert(holds, { who = who, hour = hour, clear = clear == true })
	refresh()
end

-- Lets go of `who`'s hold: back to the next hold, Build mode's pick or the town's own time.
function ViewTime.release(who: string)
	local had = false
	for i = #holds, 1, -1 do
		if holds[i].who == who then
			table.remove(holds, i)
			had = true
		end
	end
	if had then
		refresh()
	end
end

return ViewTime
