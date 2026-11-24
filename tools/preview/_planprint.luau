--!nocheck
local process = require("@lune/process")
local Harness = require("../../tests/harness")
Harness.init(".")
local R = Harness.require
local Presets = R("ReplicatedStorage.Shared.Data.Presets")
local Plan = R("ReplicatedStorage.Shared.Build.Plan")
local id = process.args[1]
local plan = Plan.new(200)
plan.size = 200
local _, why, _, trial, made = Presets.check(plan, Presets.requests(id, 0, 0, 0))
print(why)
for _, m in made do
	local o = trial[m.kind][m.key]
	if m.kind == "walls" then
		print(m.key, "wall", o.x1, o.z1, o.x2, o.z2, "lv", o.lv, o.style, o.a.c, o.b.c)
	elseif m.kind == "floors" then
		print(m.key, "floor", o.x1, o.z1, o.x2, o.z2, "lv", o.lv)
	elseif m.kind == "roofs" then
		print(m.key, "roof", o.x1, o.z1, o.x2, o.z2, "lv", o.lv, o.style)
	end
end
