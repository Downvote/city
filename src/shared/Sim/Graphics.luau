--!strict
-- What a player's Settings mean for their own screen (the user: "add settings for graphic
-- quality, background blur, bloom, etc."). The choices are saved with the profile (Schema.Settings,
-- `SettingSet` checks each on the server) and put on by client World/Graphics; this is the rule
-- behind them, free of services so the Settings spec can hold it.

local Tuning = require(script.Parent.Parent.Config.Tuning)
local Schema = require(script.Parent.Schema)

local Graphics = {}

Graphics.Keys = { "detail", "blur", "blurStrength", "bloom", "sunRays", "haze" }
Graphics.Detail = { "low", "medium", "high" }

export type Level = {
	Shadows: boolean,
	Reach: number,
	Particles: number,
	Outlines: number,
	Layers: number,
}

-- The settings with every key there, each of the default's type and a known choice (what came from
-- an old save, or a broken one, falls back to the default).
function Graphics.clean(settings: any): { [string]: any }
	local out: { [string]: any } = {}
	local given = if type(settings) == "table" then settings else {}
	local defaults: { [string]: any } = Schema.Settings :: any
	for k, default in defaults do
		local v = given[k]
		if typeof(v) ~= typeof(default) or (type(v) == "number" and v ~= v) then
			v = default
		elseif type(v) == "number" then
			v = math.clamp(v, 0, 1)
		elseif type(v) == "string" then
			local choices: { [string]: boolean }? = (Schema.SettingChoices :: any)[k]
			if choices and not choices[v :: string] then
				v = default
			end
		end
		out[k] = v
	end
	return out
end

-- What the detail level keeps (Tuning.Graphics.Levels).
function Graphics.level(settings: any): Level
	local s = Graphics.clean(settings)
	return Tuning.Graphics.Levels[s.detail] or Tuning.Graphics.Levels.high
end

-- How strong the background blur is (the lens's FarIntensity), 0 with it off.
function Graphics.blur(settings: any): number
	local s = Graphics.clean(settings)
	if not s.blur then
		return 0
	end
	return Tuning.Look.Lens.FarIntensity * 2 * s.blurStrength
end

-- Which of Tuning.Graphics.BlurSteps the strength is nearest (1 soft, 2 medium, 3 strong).
function Graphics.blurStep(settings: any): number
	local s = Graphics.clean(settings)
	local best, gap = 1, math.huge
	for i, v in Tuning.Graphics.BlurSteps do
		if math.abs(v - s.blurStrength) < gap then
			best, gap = i, math.abs(v - s.blurStrength)
		end
	end
	return best
end

-- The air on this screen in weather `kind`: the weather's own (Tuning.Weather.Looks), or nearly
-- clear with the haze off. Returns the Atmosphere's Density and Haze.
function Graphics.air(settings: any, kind: string?): (number, number)
	local s = Graphics.clean(settings)
	if not s.haze then
		return Tuning.Weather.NoHaze.Density, Tuning.Weather.NoHaze.Haze
	end
	local look = Tuning.Weather.Looks[kind or "clear"] or Tuning.Weather.Looks.clear
	return look.Density, look.Haze
end

return Graphics
