--!strict
-- Every sound this player hears, on their own screen only (the user: "Like tomodachi life, can you
-- make it such that villagers have voices ... also, add sounds where necessary, along with a calm
-- cozy music track in the background. use roblox library for these, dont make your own"). The
-- sounds are Data/Sounds' (all from the Roblox library), made here under SoundService in three
-- groups, Music, Effects and Voices, whose volumes follow the player's Settings (Sim/Sound). Nobody
-- else hears any of it: nothing here is made on the server.
--
--   Audio.play(key)          an effect: a press, a menu opening, a notice, coins, a piece put down
--   Audio.at(key, where)     an effect from a place in the town (a door), heard near the camera
--   Audio.talker(voice, t)   a line typing out in a voice (UI/Dialogue): to(shown) as letters show
--   Audio.babble(voice, t)   a whole line in a voice at once (a speech card over a head, Test)
--   the music               a calm track at a time from Data/Sounds' Playlist, with quiet between
--   the weather             the rain and the wind's loops for the weather now (UI/Weather says
--                           when the camera is under a roof, and when lightning strikes)
--   doors                   a door opening or shutting near the camera (the server swings them)
--
-- Until Audio.start runs (the game's client does; the previews and the simulations don't) every
-- call is silent, and everything that touches the engine is in a pcall, so a sound that won't load
-- never stops anything else.

local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Tuning = require(Shared.Config.Tuning)
local Sounds = require(Shared.Data.Sounds)
local Babble = require(Shared.Sim.Babble)
local Rules = require(Shared.Sim.Sound)
local Builder = require(Shared.Build.Builder)

local State = require(script.Parent.State)
local Graphics = require(script.Parent.Parent.World.Graphics)
local Kit = require(script.Parent.Parent.UI.Kit)

local Audio = {}

local K = Tuning.Audio
local V = Tuning.Voices
local rng: Random = nil :: any -- (made in Audio.start)

local started = false
local service: Instance? = nil
local groups: { [string]: SoundGroup } = {}
local templates: { [string]: Sound } = {} -- one made Sound per effect, cloned to play
local lastPlayed: { [string]: number } = {}
type Slot = { s: Sound, eq: EqualizerSoundEffect?, token: number }
local pools: { [string]: { Slot } } = {}
local poolNext: { [string]: number } = {}
local loops: { [string]: Sound } = {}
local loopLevel: { [string]: number } = {}
local sheltered = false
local overHead = 0 -- lines over heads babbling now

local function make(entry: Sounds.Entry, group: string, parent: Instance?): Sound?
	local ok, made = pcall(function()
		local s = Instance.new("Sound")
		s.SoundId = Sounds.asset(entry.id)
		s.Volume = entry.volume
		if entry.rate then
			s.PlaybackSpeed = entry.rate
		end
		local g = groups[group]
		if g then
			s.SoundGroup = g
		end
		s.Parent = parent or service
		return s
	end)
	return if ok then made else nil
end

-- What the settings, the hour and a conversation make each group's volume now.
local function levels(): Rules.Levels
	local talking = State.data.talking == true
	return Rules.levels(Graphics.settings(), Lighting.ClockTime, talking)
end

local function applyLevels(ease: boolean)
	local l = levels()
	local want: { [string]: number } = { Music = l.music, Effects = l.effects, Voices = l.voices }
	for name, value in want do
		local g = groups[name]
		if g then
			if ease then
				TweenService:Create(g, TweenInfo.new(1.2, Enum.EasingStyle.Quad), { Volume = value }):Play()
			else
				g.Volume = value
			end
		end
	end
end

-- Plays effect `key` (Data/Sounds.Effects) once. opts: Volume (times its own), Rate (times its own).
-- The same effect asked for twice within Tuning.Audio.Gap plays once.
function Audio.play(key: string, opts: { Volume: number?, Rate: number? }?)
	if not started then
		return
	end
	local entry = Sounds.Effects[key]
	if not entry then
		return
	end
	local now = os.clock()
	if now - (lastPlayed[key] or -1) < K.Gap then
		return
	end
	lastPlayed[key] = now
	pcall(function()
		local t = templates[key]
		if not t then
			local made = make(entry, "Effects")
			if not made then
				return
			end
			templates[key] = made
			t = made
		end
		local s = t:Clone()
		s.Volume = entry.volume * ((opts and opts.Volume) or 1)
		s.PlaybackSpeed = (entry.rate or 1) * ((opts and opts.Rate) or 1)
		if entry.from then
			s.TimePosition = entry.from
		end
		s.Parent = service
		s:Play()
		local life = (entry.len or 3) / math.max(0.1, s.PlaybackSpeed) + 0.2
		task.delay(life, function()
			s:Destroy()
		end)
	end)
end

-- Plays effect `key` from a place in the town, heard only near the camera (it fades with distance).
function Audio.at(key: string, where: Vector3, opts: { Volume: number?, Rate: number? }?)
	if not started then
		return
	end
	local cam = workspace.CurrentCamera
	if not cam then
		return
	end
	local d = (cam.CFrame.Position - where).Magnitude
	if d > K.Heard then
		return
	end
	local fall = math.clamp(1 - d / K.Heard, 0, 1)
	Audio.play(key, {
		Volume = ((opts and opts.Volume) or 1) * (0.25 + 0.75 * fall * fall),
		Rate = opts and opts.Rate,
	})
end

-- The voices: a few Sounds for each syllable sound, played in turn, each with its own equalizer
-- for the tone's treble.
local function voiceSound(name: string): Slot?
	local entry = Sounds.Voices[name]
	if not entry then
		return nil
	end
	local pool = pools[name]
	if not pool then
		local fresh: { Slot } = {}
		pool = fresh
		for _ = 1, 4 do
			local s = make(entry, "Voices")
			if s then
				local eq: EqualizerSoundEffect? = nil
				pcall(function()
					local e = Instance.new("EqualizerSoundEffect")
					e.LowGain = 0
					e.MidGain = 0
					e.HighGain = 0
					e.Parent = s
					eq = e
				end)
				table.insert(fresh, { s = s, eq = eq, token = 0 })
			end
		end
		pools[name] = fresh
	end
	if #pool == 0 then
		return nil
	end
	local i = (poolNext[name] or 0) % #pool + 1
	poolNext[name] = i
	return pool[i]
end

local function voicesOn(): boolean
	return started and Graphics.settings().voices ~= false
end

-- Plays one syllable of a voice now (`loud`: times its loudness, for a voice far off).
local function beep(voice: Babble.Voice, b: Babble.Beep, loud: number?)
	local entry = Sounds.Voices[b.sound]
	local slot = voiceSound(b.sound)
	if not entry or not slot then
		return
	end
	local _, treble = Babble.sound(voice)
	pcall(function()
		local s: Sound = slot.s
		slot.token += 1
		local mine = slot.token
		-- a syllable from a recording of many: which one, by the letter it falls on
		local from, len = entry.from or 0, entry.len or b.length
		local grains = entry.grains
		local rate = b.rate
		if grains and #grains > 0 then
			local g = grains[(b.at % #grains) + 1]
			from, len = g[1], g[2]
			-- (each syllable to the voice's pitch, whatever its own was)
			if g[3] and entry.hz then
				rate *= entry.hz / g[3]
			end
		end
		s:Stop()
		s.PlaybackSpeed = rate
		s.Volume = entry.volume * b.volume * (loud or 1)
		if slot.eq then
			(slot.eq :: EqualizerSoundEffect).HighGain = treble
		end
		s.TimePosition = from
		s:Play()
		-- cut short at the syllable's length, faded over the last few hundredths so it doesn't click
		local lasts = math.min(b.length, len / math.max(0.1, rate))
		local fade = math.min(0.03, lasts / 3)
		task.delay(lasts - fade, function()
			if slot.token == mine then
				TweenService:Create(s, TweenInfo.new(fade), { Volume = 0 }):Play()
				task.delay(fade, function()
					if slot.token == mine then
						s:Stop()
					end
				end)
			end
		end)
	end)
end

export type Talker = { to: (shown: number) -> (), stop: () -> () }

local SILENT: Talker = {
	to = function(_: number) end,
	stop = function() end,
}

-- A line typing out in `voice`: call to(n) with how many letters show; each syllable plays as
-- its letter comes (one a call at the most), and stop() ends it when the rest shows at once.
function Audio.talker(voice: Babble.Voice?, text: string): Talker
	if not voice or not voicesOn() or text == "" then
		return SILENT
	end
	local plan = Babble.plan(voice, text)
	local i = 1
	local done = false
	return {
		to = function(shown: number)
			if done then
				return
			end
			local due: Babble.Beep? = nil
			while i <= #plan and plan[i].at <= shown do
				due = plan[i]
				i += 1
			end
			if due then
				beep(voice, due)
			end
		end,
		stop = function()
			done = true
		end,
	}
end

-- A whole line babbled at the pace the scene types (Tuning.Voices.Typing), at most
-- Tuning.Voices.Card seconds of it; `loud` times its loudness. Returns a function that stops it.
function Audio.babble(voice: Babble.Voice?, text: string, loud: number?): () -> ()
	if not voice or not voicesOn() or text == "" then
		return function() end
	end
	local plan = Babble.plan(voice, text)
	local stopped = false
	task.spawn(function()
		local t0 = os.clock()
		for _, b in plan do
			local at = (b.at - 1) / V.Typing
			if at > V.Card then
				break
			end
			local wait = at - (os.clock() - t0)
			if wait > 0 then
				task.wait(wait)
			end
			if stopped then
				return
			end
			beep(voice, b, loud)
		end
	end)
	return function()
		stopped = true
	end
end

-- A villager's line over their head (World/Bubbles: a speech card got new words): babbled in their
-- voice when they are near the camera, quieter further off, never while a conversation is up, and
-- only a couple at once.
function Audio.overHead(model: Model, text: string)
	if not voicesOn() or State.data.talking == true or overHead >= V.Together then
		return
	end
	local head = model:FindFirstChild("Head") or model.PrimaryPart
	local cam = workspace.CurrentCamera
	if not head or not head:IsA("BasePart") or not cam then
		return
	end
	local d = (cam.CFrame.Position - head.Position).Magnitude
	if d > V.Hear then
		return
	end
	local voice = Babble.decode(model:GetAttribute("Voice"))
	if not voice then
		local vid = model:GetAttribute("Vid")
		voice = Babble.default(nil, if type(vid) == "string" then vid else nil)
	end
	overHead += 1
	local fall = 1 - d / V.Hear
	Audio.babble(voice, text, 0.35 + 0.65 * fall)
	task.delay(V.Card + 0.2, function()
		overHead -= 1
	end)
end

-- The weather's loops: each eased toward what the weather and the roof over the camera ask for.
local function weatherNow(): string
	local w = workspace:GetAttribute("Weather")
	return if type(w) == "string" then w else "clear"
end

local function stepLoops(dt: number)
	local want = Rules.weather(weatherNow(), sheltered)
	for key, entry in Sounds.Loops do
		local target = (want[key] or 0) * entry.volume
		local now = loopLevel[key] or 0
		-- (about two seconds to come or go all the way)
		local most = entry.volume / 2 * dt
		now += math.clamp(target - now, -most, most)
		loopLevel[key] = now
		local s = loops[key]
		if now > 0.001 and not s then
			local made = make(entry, "Effects")
			if made then
				made.Looped = true
				made.Volume = 0
				pcall(function()
					made:Play()
				end)
				loops[key] = made
				s = made
			end
		end
		if s then
			s.Volume = now
			if now <= 0.001 then
				pcall(function()
					s:Destroy()
				end)
				loops[key] = nil
			end
		end
	end
end

-- UI/Weather: the camera went under a roof or out from under one.
function Audio.setSheltered(on: boolean)
	sheltered = on
end

-- UI/Weather: lightning far off; its rumble comes a moment later.
function Audio.thunder()
	if not started then
		return
	end
	task.delay(rng:NextNumber(K.Thunder[1], K.Thunder[2]), function()
		Audio.play("thunder", { Volume = if sheltered then K.UnderRoof else 1, Rate = rng:NextNumber(0.85, 1.05) })
	end)
end

-- A sound's number (or 1 for a true flag), 0 where it can't be read.
local function read(s: Sound, key: string): number
	local ok, v = pcall(function()
		return (s :: any)[key]
	end)
	if not ok then
		return 0
	end
	if type(v) == "boolean" then
		return if v then 1 else 0
	end
	return if type(v) == "number" then v else 0
end

-- The music: a track, faded in and out, then a rest, then another (never the same twice running).
local function musicLoop()
	task.wait(K.FirstAfter)
	local last: string? = nil
	local made: { [string]: Sound } = {}
	while true do
		local key = Rules.nextTrack(last, Rules.night(Lighting.ClockTime), rng:NextNumber())
		last = key
		local entry = Sounds.Music[key]
		local s = made[key]
		if entry and not s then
			local track = make(entry, "Music")
			if track then
				made[key] = track
				s = track
			end
		end
		if entry and s then
			local track: Sound = s
			pcall(function()
				track.Volume = 0
				track.TimePosition = 0
				track:Play()
				TweenService:Create(track, TweenInfo.new(K.Fade, Enum.EasingStyle.Sine), { Volume = entry.volume })
					:Play()
			end)
			-- wait for its length to be known, then until it nears its end
			local waited = 0
			while read(track, "TimeLength") <= 0 and waited < 10 do
				task.wait(0.5)
				waited += 0.5
			end
			local length = read(track, "TimeLength")
			if length <= 0 then
				length = 120
			end
			while read(track, "IsPlaying") == 1 and read(track, "TimePosition") < length - K.Fade do
				task.wait(1)
			end
			pcall(function()
				TweenService:Create(track, TweenInfo.new(K.Fade, Enum.EasingStyle.Sine), { Volume = 0 }):Play()
			end)
			task.wait(K.Fade)
			pcall(function()
				track:Stop()
			end)
		else
			task.wait(5)
		end
		task.wait(Rules.rest(rng:NextNumber()))
	end
end

-- Doors: the server swings them and words their prompt "Close" when one is open; a change near the
-- camera plays a door opening or shutting where it is.
local hookedDoors: { [Instance]: boolean } = {}
local function hookDoor(leaf: Instance)
	if hookedDoors[leaf] or not leaf:IsA("BasePart") then
		return
	end
	local function watch(prompt: Instance)
		if not prompt:IsA("ProximityPrompt") or prompt.Name ~= "DoorPrompt" or hookedDoors[leaf] then
			return
		end
		hookedDoors[leaf] = true
		prompt:GetPropertyChangedSignal("ActionText"):Connect(function()
			-- (shutting, a touch lower)
			local opened = prompt.ActionText == "Close"
			Audio.at("door", leaf.Position, { Rate = if opened then 1 else 0.88 })
		end)
		leaf.Destroying:Connect(function()
			hookedDoors[leaf] = nil
		end)
	end
	local prompt = leaf:FindFirstChild("DoorPrompt")
	if prompt then
		watch(prompt)
	else
		local conn: RBXScriptConnection? = nil
		conn = leaf.ChildAdded:Connect(function(c)
			watch(c)
			if hookedDoors[leaf] and conn then
				conn:Disconnect()
			end
		end)
	end
end

function Audio.start()
	if started then
		return
	end
	local CollectionService: CollectionService
	local ok = pcall(function()
		CollectionService = game:GetService("CollectionService")
		rng = Random.new()
		service = game:GetService("SoundService")
		for _, name in { "Music", "Effects", "Voices" } do
			local g = Instance.new("SoundGroup")
			g.Name = name
			g.Volume = 0
			g.Parent = service
			groups[name] = g
		end
	end)
	if not ok or not service then
		return
	end
	started = true
	applyLevels(false)
	Graphics.Changed.Event:Connect(function()
		applyLevels(true)
	end)
	State.on("talking", function()
		applyLevels(true)
	end)
	-- the hour moves the music's level: looked at now and then
	task.spawn(function()
		while true do
			task.wait(5)
			applyLevels(true)
		end
	end)
	-- the interface's sounds (Kit.press, Kit.panel, Kit.closePanel, UI/Toasts)
	Kit.sound = function(kind: string)
		Audio.play(kind)
	end
	task.spawn(musicLoop)
	-- the weather's loops, a few times a second
	task.spawn(function()
		local last = os.clock()
		while true do
			task.wait(0.25)
			local now = os.clock()
			pcall(stepLoops, now - last)
			last = now
		end
	end)
	-- doors
	for _, leaf in CollectionService:GetTagged(Builder.Tags.DoorLeaf) do
		hookDoor(leaf)
	end
	CollectionService:GetInstanceAddedSignal(Builder.Tags.DoorLeaf):Connect(hookDoor)
	-- the sounds loaded early, so the first press doesn't wait for one
	task.spawn(function()
		local list = {}
		for key, entry in Sounds.Effects do
			local s = templates[key] or make(entry, "Effects")
			if s then
				templates[key] = s
				table.insert(list, s)
			end
		end
		for name in Sounds.Voices do
			local slot = voiceSound(name)
			if slot then
				table.insert(list, slot.s)
			end
		end
		pcall(function()
			game:GetService("ContentProvider"):PreloadAsync(list)
		end)
	end)
end

return Audio
