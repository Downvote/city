--!strict
-- A plot's name (the user: "allow naming of plots, and the name should appear in place of the big
-- "Level x" at the top left above the level bar"). The profile keeps it as `plotName`, "" until
-- the player names their plot, and the main screen shows it over the level bar (UI/Hud).
-- `clean` is what a saved or sent name is cut down to. A name a player types must also go through
-- the text filter on the server before anyone else sees it.

local Tuning = require(script.Parent.Parent.Config.Tuning)

local PlotName = {}

PlotName.MaxLength = Tuning.PlotName.MaxLength

-- A name as it may be kept: a string of at most MaxLength characters, no control characters, no
-- runs of spaces and none at either end. Anything else comes back "".
function PlotName.clean(raw: any): string
	if type(raw) ~= "string" or utf8.len(raw) == nil then
		return ""
	end
	local s = raw:gsub("%c", " "):gsub("%s+", " "):gsub("^ ", ""):gsub(" $", "")
	local n = utf8.len(s) or 0
	if n > PlotName.MaxLength then
		local cut = utf8.offset(s, PlotName.MaxLength + 1)
		if cut then
			s = s:sub(1, cut - 1):gsub(" $", "")
		end
	end
	return s
end

-- What the main screen says over the level bar: the plot's name, or with none yet its owner's
-- town ("Juniper's town"), or "Your town" with no owner's name either.
function PlotName.title(name: any, owner: any): string
	local named = PlotName.clean(name)
	if named ~= "" then
		return named
	end
	local who = PlotName.clean(owner)
	if who ~= "" then
		return who .. "'s town"
	end
	return "Your town"
end

return PlotName
