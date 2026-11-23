--!nocheck
-- Lists the icons with no vector art yet: lune run tools/preview/art_missing.luau
local Harness = require("../../tests/harness").init(".")
local Icons = Harness.require("StarterPlayer.StarterPlayerScripts.Client.UI.Icons")
local missing = {}
for _, name in Icons.names() do
	if not Icons.hasArt(name) then
		table.insert(missing, name)
	end
end
print(#missing .. " without art: " .. table.concat(missing, " "))
