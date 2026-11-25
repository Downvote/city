--!nocheck
local Harness = require("../../tests/harness")
Harness.init(".")
local Z = Harness.loadFile("tools/preview/zfight_lib.luau")()
local Plan = Harness.require("ReplicatedStorage.Shared.Build.Plan")
local Shapes = Harness.require("ReplicatedStorage.Shared.Build.Shapes")
local Tuning = Harness.require("ReplicatedStorage.Shared.Config.Tuning")
local total = 0
for _, style in Plan.WallStyleOrder do
	for _, len in { 2, 6, 12, 26 } do
		local def = Plan.WallStyles[style]
		local p = def.paint or { c = "B4B4B8", m = "Cobblestone" }
		local w = { x1 = 100, z1 = 10, x2 = 100 + len, z2 = 10, lv = 0, style = style, a = p, b = p }
		local plan = Plan.new()
		plan.walls["1"] = w
		local r1, r2 = Shapes.wallReach(plan, "1")
		local prims = Z.open(Shapes.wall(w, {}, r1, r2))
		local group = {}
		for i = 1, #prims do group[i] = 1 end
		local found = Z.scan(prims, { supports = { { 0, 1, 0, 0 } }, group = group })
		local near = 0
		for _, f in found do if f.cls == "near" then near += 1; print(style, len, Z.describe(prims[f.a]), Z.describe(prims[f.b]), f.area, f.gap) end end
		total += near
		if len == 12 then print(style, #prims, "parts", near, "near") end
	end
end
print("total", total)
