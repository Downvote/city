--!nocheck
-- Writes Tuning.Look (the game's light and colour grade) as JSON for the preview tools:
--   lune run tools/preview/look.luau <out.json>
-- tools/preview/look.py runs it, so a render shows the light and the grade the game puts on.

local fs = require("@lune/fs")
local process = require("@lune/process")
local serde = require("@lune/serde")
local Tuning = require("../../src/shared/Config/Tuning")

fs.writeFile(process.args[1] or "out/look.json", serde.encode("json", Tuning.Look))
