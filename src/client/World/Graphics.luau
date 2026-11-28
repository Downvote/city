--!strict
-- Puts this player's Settings on their own screen (the user: "add settings for graphic quality,
-- background blur, bloom, etc."): the glow, the sun's rays and the background blur the server put
-- on Lighting switched or eased here, the shadows, and how much of our own costly things is drawn
-- (Tuning.Graphics.Levels: how far pieces move and give off effects, particles, outlines, the
-- weather's layers). Sim/Graphics is the rule; UI/Settings is the menu. Nothing here reaches anyone
-- else's screen. Roblox's own graphics quality is the player's to set in Roblox's menu: a script
-- can't.

local Lighting = game:GetService("Lighting")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Remotes = require(Shared.Net.Remotes)
local Tuning = require(Shared.Config.Tuning)
local Rules = require(Shared.Sim.Graphics)

local State = require(script.Parent.Parent.Controllers.State)

local Graphics = {}

-- fired after a change is put on (UI/Weather, World/Ambience and World/Outlines read the level)
Graphics.Changed = Instance.new("BindableEvent")

local current: { [string]: any } = Rules.clean(nil)

function Graphics.settings(): { [string]: any }
	return current
end

function Graphics.level(): Rules.Level
	return Rules.level(current)
end

-- Puts the settings on: what the server made on Lighting, and the pieces' ranges and rates.
function Graphics.apply()
	local level = Graphics.level()
	pcall(function()
		Lighting.GlobalShadows = level.Shadows
	end)
	local glow = Lighting:FindFirstChild("Glow")
	if glow and glow:IsA("BloomEffect") then
		glow.Enabled = current.bloom
	end
	local rays = Lighting:FindFirstChild("Rays")
	if rays and rays:IsA("SunRaysEffect") then
		rays.Enabled = current.sunRays
	end
	local lens = Lighting:FindFirstChild("Lens")
	if lens and lens:IsA("DepthOfFieldEffect") then
		local strength = Rules.blur(current)
		lens.Enabled = strength > 0
		lens.FarIntensity = strength
	end
	-- the placed pieces' motion and effects (World/Lively reads these)
	local ok, Lively = pcall(require, script.Parent.Lively)
	if ok and type(Lively) == "table" then
		local K = Tuning.Lively
		Lively.MoveRange = K.MoveRange * level.Reach
		Lively.FxRange = K.FxRange * level.Reach
		Lively.RateScale = level.Particles
	end
	Graphics.Changed:Fire()
end

-- Changes one setting on this screen at once and saves it (the server checks it).
function Graphics.set(key: string, value: any)
	if current[key] == value then
		return
	end
	current[key] = value
	current = Rules.clean(current)
	local settings = State.data.settings
	if type(settings) == "table" then
		settings[key] = current[key]
	end
	Graphics.apply()
	task.spawn(function()
		pcall(function()
			Remotes.fn("SettingSet"):InvokeServer(key, current[key])
		end)
	end)
end

function Graphics.start()
	State.on("settings", function(settings: any)
		current = Rules.clean(settings)
		Graphics.apply()
	end)
	-- the glow, the rays and the lens arrive from the server: switch each as it comes
	Lighting.ChildAdded:Connect(function()
		task.defer(Graphics.apply)
	end)
	Graphics.apply()
end

return Graphics
