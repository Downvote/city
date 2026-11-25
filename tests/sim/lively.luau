--!nocheck
-- Placed pieces that move and give off effects (the user: "make animated decor, workplaces with
-- special effects, particle makers, and more enticing types of things"), on the client: the real
-- World/Lively on fake Roblox instances, the pieces put down through the real server Build
-- service. Sails turn near the camera and stop far from it, a Ferris wheel's cabins go round
-- upright, a clock's hands keep the town's time, lights twinkle, a particle maker's emitter comes
-- on near the camera and goes off away from it, a workplace's only while it is marked Working,
-- and a VIP piece's card offers the pass instead of placing it.
--   lune run tests/sim/lively.luau          (from the repository root)

local process = require("@lune/process")
local roblox = require("@lune/roblox")
local Sim = require("./client")

local Vector3, CFrame = roblox.Vector3, roblox.CFrame
local check, run, frames = Sim.check, Sim.run, Sim.frames
local errors, profile, Fake = Sim.errors, Sim.profile, Sim.Fake

local Harness = Sim.Harness
local Town = Harness.require("ReplicatedStorage.Shared.Data.Town")
local Builder = Harness.require("ReplicatedStorage.Shared.Build.Builder")
local Rules = Harness.require("ReplicatedStorage.Shared.Build.Lively")
local Lively = Harness.require(Sim.CLIENT .. "World.Lively")

local plot = Town.plotFrame(1)
local apply = Sim.remoteFn("BuildApply")

local function place(id, x, z)
	local ok, why =
		apply:InvokeServer({ { type = "add", kind = "items", obj = { id = id, x = x, y = 0, z = z, r = 0, lv = 0 } } })
	return ok, why
end

local function modelOf(id)
	for _, m in Sim.buildFolder:GetChildren() do
		if m:GetAttribute("ItemId") == id then
			return m
		end
	end
	return nil
end

local function named(model, name)
	local out = {}
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") and d.Name == name then
			table.insert(out, d)
		end
	end
	return out
end

local function lookAt(x, z)
	Sim.cam.CFrame = CFrame.new(plot * Vector3.new(x, 30, z + 40))
end

local warned = #errors
frames(3)
Lively.start()
frames(2)

run("putting lively pieces down", function()
	local pieces = {
		{ "move_windmill", 212, 112 },
		{ "move_ferris_wheel", 226, 112 },
		{ "fx_sparkles", 238, 106 },
		{ "work_cafe", 250, 112 },
		{ "glitz_dance_floor", 214, 126 },
		{ "move_lava_lamp", 238, 112 },
	}
	for _, p in pieces do
		local ok, why = place(p[1], p[2], p[3])
		check(ok == true, "the server puts down " .. p[1] .. (if ok then "" else " (" .. tostring(why) .. ")"))
	end
	lookAt(228, 112)
	Sim.advance(2)
	frames(20)
	check(Lively.count() >= 6, "the client has taken them in (" .. Lively.count() .. ")")
end)

run("things move near the camera", function()
	local mill = modelOf("move_windmill")
	local sails = named(mill, "Move")
	check(#sails > 10, "the windmill's sails are named to move (" .. #sails .. ")")
	local was = sails[5].CFrame
	frames(12)
	check(sails[5].CFrame ~= was, "the sails turn")
	check((sails[5].CFrame.Position - was.Position).Magnitude < 6, "round their hub, not off somewhere")
	local pivot = named(mill, "Pivot")[1]
	local pivotWas = pivot.CFrame
	frames(6)
	check(pivot.CFrame == pivotWas, "the hidden pivot stays put")
	local wheel = modelOf("move_ferris_wheel")
	local cabin = named(wheel, "Cabin")[3]
	local cabinWas = cabin.CFrame
	frames(60)
	check(cabin.CFrame.Position ~= cabinWas.Position, "a Ferris wheel's cabins go round")
	check(cabin.CFrame.LookVector:Dot(cabinWas.LookVector) > 0.9999, "and stay upright")
	local lamp = modelOf("move_lava_lamp")
	local blob = named(lamp, "Move2")[1]
	local blobWas = blob.CFrame.Position
	frames(30)
	check(blob.CFrame.Position ~= blobWas, "the lava rises and falls")
	check(math.abs(blob.CFrame.Position.X - blobWas.X) < 1e-3, "straight up and down")
end)

run("lights twinkle and tiles change colour", function()
	local floor = modelOf("glitz_dance_floor")
	local tiles = named(floor, Rules.Twinkle)
	check(#tiles == 16, "the dance floor's sixteen tiles glimmer")
	local before = {}
	for i, t in tiles do
		before[i] = t.Color
	end
	frames(40)
	local changed = 0
	for i, t in tiles do
		if t.Color ~= before[i] then
			changed += 1
		end
	end
	check(changed > 8, "and run through the colours (" .. changed .. " changed)")
end)

run("a particle maker gives off its effect, a workplace only while it is worked at", function()
	local stone = modelOf("fx_sparkles")
	local spot = named(stone, Rules.Fx)[1]
	local emitter = spot and spot:FindFirstChildOfClass("ParticleEmitter")
	check(emitter ~= nil and emitter.Enabled, "the sparkle stone's emitter is on near the camera")
	check(emitter ~= nil and emitter.Color.Keypoints[1].Value == spot:GetAttribute("FxColor"), "in the piece's paint")
	local cafe = modelOf("work_cafe")
	local steam = named(cafe, Rules.Fx)[1]
	check(
		steam ~= nil and steam:GetAttribute("FxWork") == true,
		"the cafe counter has a spot for steam while it is worked at"
	)
	local function steaming()
		local e = steam:FindFirstChildOfClass("ParticleEmitter")
		return e ~= nil and e.Enabled
	end
	check(not steaming(), "nobody at work: no steam")
	cafe:SetAttribute(Rules.Working, true)
	frames(40)
	check(steaming(), "somebody at work: steam over the machine")
	cafe:SetAttribute(Rules.Working, nil)
	frames(40)
	check(not steaming(), "and it stops when they do")
	-- far away, the effects go off and nothing moves
	Sim.cam.CFrame = CFrame.new(plot * Vector3.new(228, 30, 1400))
	frames(40)
	check(not emitter.Enabled, "far from the camera the emitter is off")
	local sail = named(modelOf("move_windmill"), "Move")[5]
	local was = sail.CFrame
	frames(12)
	check(sail.CFrame == was, "and the sails stand still")
	lookAt(228, 112)
	frames(40)
	check(emitter.Enabled, "back near, it comes on again")
end)

run("a piece drawn again is taken in afresh", function()
	local mill = modelOf("move_windmill")
	local key = mill:GetAttribute("BuildKey")
	local item = table.clone(profile.plan.items[key])
	item.c1 = "CCDDEA"
	local ok, why = apply:InvokeServer({ { type = "set", kind = "items", key = key, obj = item } })
	check(ok == true, "repainting the windmill draws it again" .. (if ok then "" else " (" .. tostring(why) .. ")"))
	Sim.advance(2)
	frames(40)
	local fresh = modelOf("move_windmill")
	local sail = named(fresh, "Move")[5]
	local was = sail.CFrame
	frames(12)
	check(fresh ~= mill and sail.CFrame ~= was, "and the new one turns")
end)

run("a VIP piece: offered on its card, refused by the server without the pass", function()
	local ok, why = place("vip_throne", 205, 135)
	check(ok ~= true and type(why) == "string", "the server won't put a VIP piece down without the pass")
	Sim.BuildMode.enter()
	frames(3)
	Sim.press("Outdoor")
	Sim.press("Effects")
	local tray = Sim.gui:FindFirstChild("Tray", true)
	local cards = Fake.find(tray, function(d)
		return d:IsA("TextButton") and Fake.shown(d) and d:GetAttribute("ItemId") ~= nil
	end)
	check(#cards >= 10, "the Effects tab lists the particle makers (" .. #cards .. ")")
	local vip
	for _, c in cards do
		if c:GetAttribute("Vip") then
			vip = c
		end
	end
	check(vip ~= nil and vip:FindFirstChild("Vip", true) ~= nil, "a VIP piece's card wears a VIP tag")
	vip.Activated:Fire()
	frames(2)
	check(Sim.BuildMode.state.placing == nil, "picking it without the pass places nothing")
	profile.passes = { vip = true }
	Sim.remoteEvent("State"):FireClient(Sim.player, { passes = profile.passes })
	frames(2)
	local ok2 = place("vip_firework", 205, 135)
	check(ok2 == true, "with the pass the server puts it down")
	Sim.press("Done")
end)

print(
	string.format(
		"\nlively sim: %s (%d warnings)",
		if Sim.failures() == 0 then "all passed" else Sim.failures() .. " failed",
		#errors - warned
	)
)
for i = warned + 1, #errors do
	print("  warning: " .. errors[i])
end
if Sim.failures() > 0 or #errors > warned then
	process.exit(1)
end
