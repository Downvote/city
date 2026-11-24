--!nocheck
-- Prints the names of the icons the older shape lists also draw (the foods among them), for
-- review sheets: lune run tools/preview/art_names.luau
local Harness = require("../../tests/harness").init(".")
local Icons = Harness.require("StarterPlayer.StarterPlayerScripts.Client.UI.Icons")
print(table.concat(Icons.names(), " "))
