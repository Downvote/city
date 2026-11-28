--!nocheck
-- The client's sound end to end under Lune: the real Controllers/Audio on fake Roblox instances
-- (tests/sim/client.luau), with a SoundService to make its sounds in. The user: "Like tomodachi
-- life, can you make it such that villagers have voices ... also, add sounds where necessary,
-- along with a calm cozy music track in the background." Nothing plays before it starts; then
-- presses, menus and notices make their sounds in the Effects group, the groups follow the
-- Settings, a line typing out in UI/Dialogue babbles in the speaker's voice (and not with Voices
-- off), a speech card over a near head babbles and a far one doesn't, the rain comes and goes with
-- the weather, a door near the camera knocks, and the music starts.
--   lune run tests/sim/audio.luau          (from the repository root)

local process = require("@lune/process")
local roblox = require("@lune/roblox")
local Sim = require("./client")

local Color3, Vector3 = roblox.Color3, roblox.Vector3

local Harness, Fake = Sim.Harness, Sim.Fake
local frames, check, run, advance = Sim.frames, Sim.check, Sim.run, Sim.advance
local State, Kit = Sim.State, Sim.Kit

local Sounds = Harness.require("ReplicatedStorage.Shared.Data.Sounds")
local Babble = Harness.require("ReplicatedStorage.Shared.Sim.Babble")
local Audio = Harness.require(Sim.CLIENT .. "Controllers.Audio")
local Graphics = Harness.require(Sim.CLIENT .. "World.Graphics")
local Dialogue = Harness.require(Sim.CLIENT .. "UI.Dialogue")

-- what is under the SoundService, by the id it plays
local service = Fake.new("Folder")
service.Name = "SoundService"
local function soundsOf(id, group)
	local out = {}
	for _, d in service:GetDescendants() do
		if
			d:IsA("Sound")
			and d.SoundId == Sounds.asset(id)
			and (not group or (d.SoundGroup and d.SoundGroup.Name == group))
		then
			table.insert(out, d)
		end
	end
	return out
end

run("nothing plays before it starts", function()
	Audio.play("click")
	Kit.sound("open")
	check(#service:GetDescendants() == 0, "no sounds made")
	local t = Audio.talker(Babble.Middle, "Hello there.")
	t.to(5)
	check(#service:GetDescendants() == 0, "and no voice")
end)

-- the services the game has and the simulation doesn't
Harness.addService("SoundService", service)
local tagged, tagAdded = {}, Fake.signal()
Harness.addService("CollectionService", {
	GetTagged = function(_, tag)
		return tagged[tag] or {}
	end,
	GetInstanceAddedSignal = function()
		return tagAdded
	end,
})
Harness.addService("ContentProvider", { PreloadAsync = function() end })

Audio.start()
frames(2)
advance(0.5)

run("it makes the three groups, as loud as the settings say", function()
	local groups = {}
	for _, c in service:GetChildren() do
		if c:IsA("SoundGroup") then
			groups[c.Name] = c
		end
	end
	check(groups.Music and groups.Effects and groups.Voices, "Music, Effects and Voices")
	local K = Harness.require("ReplicatedStorage.Shared.Config.Tuning").Audio
	local s = Graphics.settings()
	check(math.abs(groups.Effects.Volume - s.sfx * K.Effects) < 1e-6, "the effects at the Effects setting")
	check(math.abs(groups.Music.Volume - s.music * K.Music) < 1e-6, "the music at the Music setting, by day")
	Graphics.set("sfx", 0)
	frames(2)
	check(groups.Effects.Volume == 0 and groups.Voices.Volume == 0, "Effects at nothing quiets them and the voices")
	Graphics.set("sfx", 0.8)
	Graphics.set("voices", false)
	frames(2)
	check(groups.Voices.Volume == 0 and groups.Effects.Volume > 0, "Voices off quiets only the voices")
	Graphics.set("voices", true)
	frames(2)
	check(groups.Voices.Volume > 0, "and on again")
end)

run("a press, a menu and a notice make their sounds, a burst of presses once", function()
	local click = Sounds.Effects.click.id
	local before = #soundsOf(click)
	Kit.sound("click")
	Kit.sound("click")
	frames(1)
	local made = soundsOf(click, "Effects")
	check(#made == before + 1, "one played beside the one kept to clone: " .. #made)
	advance(0.2)
	local panel = Kit.panel("Test", Kit.MenuSize, function() end, "gear")
	frames(2)
	check(#soundsOf(Sounds.Effects.open.id, "Effects") >= 2, "a menu opening")
	Kit.closePanel(panel)
	frames(2)
	check(#soundsOf(Sounds.Effects.close.id, "Effects") >= 2, "and closing")
	local Toasts = Harness.require(Sim.CLIENT .. "UI.Toasts")
	Toasts.show("Saved.", "good")
	frames(1)
	check(#soundsOf(Sounds.Effects.good.id) >= 1, "a notice")
	-- the clones go once they've played
	advance(5)
	check(#soundsOf(click) == 1, "the played ones are gone, the kept one stays")
end)

local function voiceSlots()
	local out = {}
	for _, d in service:GetDescendants() do
		if d:IsA("Sound") and d.SoundGroup and d.SoundGroup.Name == "Voices" then
			table.insert(out, d)
		end
	end
	return out
end

local function heard(name)
	local id = Sounds.Voices[name].id
	local speeds = {}
	for _, s in voiceSlots() do
		if s.SoundId == Sounds.asset(id) and s.PlaybackSpeed ~= (Sounds.Voices[name].rate or 1) then
			table.insert(speeds, s.PlaybackSpeed)
		end
	end
	return speeds
end

run("a line typing out in the scene babbles in the speaker's voice", function()
	local voice = Babble.clean({ pitch = 0.9, speed = 0.8, tone = 0.1, lilt = 0.3 })
	local name = Babble.sound(voice)
	check(name == Sounds.VoiceOrder[1], "a soft voice uses the softest sound")
	local s = Dialogue.open({ Name = "AudioScene", OnClick = function() end })
	s.join({ key = "a", name = "Ada", color = Color3.new(1, 0.5, 0.5), voice = voice })
	s.speak("a")
	s.type("Hi! It's nice to see you. How was the market today?")
	frames(3)
	advance(2)
	local speeds = heard(name)
	check(#speeds > 0, "syllables played")
	local plan = Babble.plan(voice, "Hi! It's nice to see you. How was the market today?")
	local rates = {}
	for _, b in plan do
		rates[string.format("%.4f", b.rate)] = true
	end
	for _, sp in speeds do
		check(rates[string.format("%.4f", sp)] == true, "at the plan's pitch: " .. sp)
	end
	s.close(true)
end)

run("nobody talking, or Voices off: the line is quiet", function()
	-- (the slots keep their last speed: mark them, then see nothing changed)
	for _, slot in voiceSlots() do
		slot.PlaybackSpeed = 0.125
	end
	local s = Dialogue.open({ Name = "Quiet", OnClick = function() end })
	s.join({ key = "a", name = "Ada", color = Color3.new(1, 0.5, 0.5), voice = Babble.Middle })
	s.speak(nil)
	s.type("The rain came down all night.")
	advance(1.5)
	local changed = 0
	for _, slot in voiceSlots() do
		if slot.PlaybackSpeed ~= 0.125 then
			changed += 1
		end
	end
	check(changed == 0, "a line nobody says has no voice")
	Graphics.set("voices", false)
	s.speak("a")
	s.type("Shh, it's late.")
	advance(1.5)
	for _, slot in voiceSlots() do
		if slot.PlaybackSpeed ~= 0.125 then
			changed += 1
		end
	end
	check(changed == 0, "Voices off: nothing")
	Graphics.set("voices", true)
	s.close(true)
end)

run("a speech card over a near head babbles, a far one doesn't", function()
	local function villager(at, voice)
		local m = Fake.new("Model", Sim.ws)
		local head = Fake.new("Part", m)
		head.Name = "Head"
		head.Position = at
		m:SetAttribute("Voice", Babble.encode(voice))
		return m
	end
	local cam = Sim.cam.CFrame.Position
	for _, slot in voiceSlots() do
		slot.PlaybackSpeed = 0.125
	end
	local far = villager(cam + Vector3.new(0, 0, 400), Babble.ByPers.bold)
	Audio.overHead(far, "Morning! Lovely day for it.")
	advance(1)
	local moved = 0
	for _, slot in voiceSlots() do
		if slot.PlaybackSpeed ~= 0.125 then
			moved += 1
		end
	end
	check(moved == 0, "too far off to hear")
	local near = villager(cam + Vector3.new(0, 0, 10), Babble.ByPers.bold)
	Audio.overHead(near, "Morning! Lovely day for it.")
	advance(2)
	check(#heard(Babble.sound(Babble.ByPers.bold)) > 0, "near enough: their voice")
end)

run("the rain comes with the weather and goes with it", function()
	local rain = Sounds.Loops.rain.id
	Sim.ws:SetAttribute("Weather", "rain")
	advance(4)
	local loops = soundsOf(rain, "Effects")
	check(#loops == 1 and loops[1].Looped and loops[1].Volume > 0, "a rain loop, playing")
	Audio.setSheltered(true)
	local outside = loops[1].Volume
	advance(4)
	check(loops[1].Volume < outside, "softer under a roof")
	Audio.setSheltered(false)
	Sim.ws:SetAttribute("Weather", "clear")
	advance(12)
	check(#soundsOf(rain) == 0, "gone when it clears")
	Audio.thunder()
	advance(3)
	check(#soundsOf(Sounds.Effects.thunder.id) >= 1, "thunder after lightning")
end)

run("a door near the camera knocks as it swings", function()
	local leaf = Fake.new("Part", Sim.ws)
	leaf.Position = Sim.cam.CFrame.Position + Vector3.new(4, 0, 0)
	local prompt = Fake.new("ProximityPrompt", leaf)
	prompt.Name = "DoorPrompt"
	prompt.ActionText = "Open"
	tagAdded:Fire(leaf)
	local before = #soundsOf(Sounds.Effects.door.id)
	advance(0.2)
	prompt.ActionText = "Close"
	frames(1)
	check(#soundsOf(Sounds.Effects.door.id) > before, "it opened")
end)

run("the music starts a little after joining, in the Music group", function()
	advance(8)
	local found = false
	for key, t in Sounds.Music do
		if #soundsOf(t.id, "Music") > 0 then
			found = true
			check(not t.night, "a day track by day: " .. key)
		end
	end
	check(found, "a track")
end)

run("no warnings from any of it", function()
	check(#Sim.errors == 0, "warnings: " .. table.concat(Sim.errors, " | "))
end)

local failures = Sim.failures()
print(if failures == 0 then "\naudio sim: all passed" else "\naudio sim: " .. failures .. " failed")
if failures > 0 then
	process.exit(1)
end
