local roblox = require("@lune/roblox")
local Sim = require("../../tests/sim/client")
local Enum = roblox.Enum
Sim.BuildMode.enter()
Sim.frames(3)
Sim.press("Select")
local SelectTool = Sim.Harness.require(Sim.CLIENT .. "Build.SelectTool")
local Town = Sim.Harness.require("ReplicatedStorage.Shared.Data.Town")
local requests = {}
local spots = { { 262, 176 }, { 266, 176 }, { 270, 176 } }
for _, at in spots do
	table.insert(requests, { type = "add", kind = "items", obj = { id = "chair_wood", x = at[1], y = 0, z = at[2], r = 0, lv = 0 } })
end
Sim.advance(0.2)
print("placed", Sim.remoteFn("BuildApply").OnServerInvoke(Sim.player, requests))
Sim.frames(3)
local frame = Town.plotFrame(1)
local lo, hi = roblox.Vector2.new(math.huge, math.huge), roblox.Vector2.new(-math.huge, -math.huge)
for _, at in spots do
	local v, on = Sim.cam:WorldToViewportPoint(frame * roblox.Vector3.new(at[1], 1, at[2]))
	print("proj", v, on)
	lo = roblox.Vector2.new(math.min(lo.X, v.X), math.min(lo.Y, v.Y))
	hi = roblox.Vector2.new(math.max(hi.X, v.X), math.max(hi.Y, v.Y))
end
Sim.setMouse(lo - roblox.Vector2.new(40, 40))
Sim.input(Enum.UserInputType.MouseButton1, true)
Sim.setMouse(hi + roblox.Vector2.new(40, 40))
Sim.input(Enum.UserInputType.MouseButton1, false)
print("count", SelectTool.count())
Sim.press("GroupMove")
print("holding", SelectTool.holding())
Sim.mouseAtPlot(266, 166)
Sim.frames(3)
local m = Sim.ws:FindFirstChild("BuildMarkers")
local t = m and m:FindFirstChild("Text", true)
print("label", t and t.Text, t and t.Parent and t.Parent.Enabled)
