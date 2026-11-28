--!nocheck
-- What is still flat plastic where it shows (Data/Surfaces: "for all buildings and decor, make it
-- such that textures are used, never make them untextured"), by the line that drew it.
--   lune run tools/preview/untextured.luau [town|starter|presets] [lines to list] [colors]
-- `town` is every model as the map hands it out, so it should find none; the starter house and
-- the ready-made buildings are Build mode's pieces and finishes. With `colors` it counts by colour
-- and shape instead of by line. The first line counts every shape in it by material.
local process = require("@lune/process")
local Harness = require("../../tests/harness")
Harness.init(".")
local Z = Harness.loadFile("tools/preview/zfight_lib.luau")()
local Shared = "ReplicatedStorage.Shared."
local require = Harness.require
local Geometry = require(Shared .. "Build.Geometry")
local TownMap = require(Shared .. "Data.TownMap")
local Surfaces = require(Shared .. "Data.Surfaces")
local Tuning = require(Shared .. "Config.Tuning")
Z.tag()
local scope = process.args[1] or "town"
COLORS = process.args[3] == "colors"
local bySrc, total, plastic, byMat = {}, 0, 0, {}
local function visit(prims, weight, model)
	for _, p in Geometry.flatten(prims) do
		total += weight
		local base = string.match(p.mat, "^[^:]+")
		byMat[p.mat] = (byMat[p.mat] or 0) + weight
		if Surfaces.plain(p.mat) and Surfaces.shows(p) then
			plastic += weight
			local k = if COLORS then (p.color:ToHex() .. " " .. p.shape) else (p.src or "?") .. " [" .. p.shape .. "]"
			local e = bySrc[k]
			if not e then
				e = { n = 0, models = {} }
				bySrc[k] = e
			end
			e.n += weight
			e.models[model] = true
		end
	end
end
if scope == "town" then
	visit(TownMap.ground(), 1, "ground")
	local seen = {}
	local count = {}
	for _, p in TownMap.placements() do
		count[p.name] = (count[p.name] or 0) + 1
	end
	for name, n in count do
		visit(TownMap.prims(name), n, name)
	end
elseif scope == "starter" or scope == "presets" then
	local Builder = require(Shared .. "Build.Builder")
	local Plan = require(Shared .. "Build.Plan")
	local function planVisit(plan, made, name)
		if made then
			for _, m in made do
				visit(Builder.primsFor(plan, m.kind, m.key) or {}, 1, name)
			end
		else
			for _, kind in Plan.Kinds do
				for key in plan[kind] do
					visit(Builder.primsFor(plan, kind, key) or {}, 1, name)
				end
			end
		end
	end
	if scope == "starter" then
		planVisit(require(Shared .. "Data.StarterHouse").plan(), nil, "starter")
	else
		local Presets = require(Shared .. "Data.Presets")
		for _, p in Presets.list do
			local full = Tuning.Plot.Size
			local plan = Plan.new(full)
			plan.size = full
			local _, why, _, trial, made = Presets.check(plan, Presets.requests(p.id, 0, 0, 0))
			planVisit(trial, made, p.id)
		end
	end
end
local keys = {}
for k in bySrc do
	table.insert(keys, k)
end
table.sort(keys, function(a, b)
	return bySrc[a].n > bySrc[b].n
end)
print(string.format("%s: %d prims, %d visible plastic", scope, total, plastic))
local mats = {}
for m in byMat do
	table.insert(mats, m)
end
table.sort(mats, function(a, b)
	return byMat[a] > byMat[b]
end)
local line = {}
for _, m in mats do
	table.insert(line, m .. "=" .. byMat[m])
end
print(table.concat(line, "  "))
local limit = tonumber(process.args[2]) or 60
for i, k in keys do
	if i > limit then
		break
	end
	local ms = {}
	for m in bySrc[k].models do
		table.insert(ms, m)
	end
	table.sort(ms)
	local s = table.concat(ms, ",")
	if #s > 70 then
		s = s:sub(1, 70) .. "..."
	end
	print(string.format("%6d %s  {%s}", bySrc[k].n, k, s))
end
