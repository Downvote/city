--!nocheck
-- Where the town's parts go (the Town spec's budgets): loose parts and pieces by the line that
-- drew them, or by model, each counted as often as its model is placed.
--   lune run tools/preview/parts_by_line.luau [lines|models] [how many] [opened]
-- Parts as served (Geometry.served) by default; `opened` counts every shape in a piece.
local process = require("@lune/process")
local Harness = require("../../tests/harness")
Harness.init(".")
local Z = Harness.loadFile("tools/preview/zfight_lib.luau")()
local require = Harness.require
local Shared = "ReplicatedStorage.Shared."
local Geometry = require(Shared .. "Build.Geometry")
local TownMap = require(Shared .. "Data.TownMap")
Z.tag()
local by, models = {}, {}
local opened = (process.args[3] == "opened")
local function note(prims, n, model)
	for _, p in prims do
		local served = if opened then #Geometry.flatten({ p }) else Geometry.served({ p })
		local k = (p.src or "?") .. (if p.shape == "Piece" then " [piece]" else " [" .. p.shape .. "]")
		by[k] = (by[k] or 0) + served * n
		models[model] = (models[model] or 0) + served * n
	end
end
note(TownMap.ground(), 1, "ground")
local count = {}
for _, p in TownMap.placements() do
	count[p.name] = (count[p.name] or 0) + 1
end
for name, n in count do
	note(TownMap.prims(name), n, name)
end
local function top(t, limit)
	local keys = {}
	for k in t do
		table.insert(keys, k)
	end
	table.sort(keys, function(a, b)
		return t[a] > t[b]
	end)
	for i = 1, math.min(limit, #keys) do
		print(string.format("%6d %s", t[keys[i]], keys[i]))
	end
end
local mode = process.args[1] or "lines"
top(if mode == "models" then models else by, tonumber(process.args[2]) or 50)
