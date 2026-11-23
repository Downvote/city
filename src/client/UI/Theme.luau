-- The look the player picked for the interface: dark (what the game opens in) or light. The
-- user: "along with the option to change to light mode". The choice is kept with their settings
-- (the `theme` key, sent with SettingSet) and put back on when they next join.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Remotes = require(Shared.Net.Remotes)

local Kit = require(script.Parent.Kit)
local State = require(script.Parent.Parent.Controllers.State)

local Theme = {}

function Theme.name(): string
	return Kit.ThemeName
end

-- The icon for the button that switches: what you would get.
function Theme.icon(): string
	return if Kit.ThemeName == "dark" then "sun" else "moon"
end

-- Puts a look on. `save` false leaves the saved choice alone (putting the saved one on).
function Theme.set(name: string, save: boolean?)
	if name == Kit.ThemeName or not Kit.setTheme(name) then
		return
	end
	local settings = State.data.settings
	if type(settings) == "table" then
		settings.theme = name
	end
	if save ~= false then
		task.spawn(function()
			pcall(function()
				Remotes.fn("SettingSet"):InvokeServer("theme", name)
			end)
		end)
	end
end

function Theme.toggle()
	Theme.set(if Kit.ThemeName == "dark" then "light" else "dark")
end

-- Puts the saved look on once the player's settings arrive.
function Theme.start()
	State.on("settings", function(settings: any)
		local saved = type(settings) == "table" and settings.theme
		if saved == "light" or saved == "dark" then
			Theme.set(saved, false)
		end
	end)
end

return Theme
