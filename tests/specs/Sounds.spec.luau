--!nocheck
-- The game's sounds (Data/Sounds, Sim/Sound) and the Settings that set them. The user: "add sounds
-- where necessary, along with a calm cozy music track in the background. use roblox library for
-- these, dont make your own." Every sound is a library id with its maker (python3
-- scripts/library_sounds.py check asks Roblox that each still plays), every effect the client asks
-- for is there, the volumes stay soft, the Music, Effects and Voices settings are saved and
-- checked like the others, and the music is softer at night and while somebody is talking.

local Shared = "ReplicatedStorage.Shared."
local Tuning = require(Shared .. "Config.Tuning")
local Sounds = require(Shared .. "Data.Sounds")
local Sound = require(Shared .. "Sim.Sound")
local Graphics = require(Shared .. "Sim.Graphics")
local Schema = require(Shared .. "Sim.Schema")

-- the client files that ask for effects by name (Kit.sound, Audio.play, Audio.at)
local CALLERS = {
	"src/client/UI/Kit.luau",
	"src/client/UI/Toasts.luau",
	"src/client/UI/Hud.luau",
	"src/client/UI/GiftPicker.luau",
	"src/client/UI/Weather.luau",
	"src/client/Build/BuildMode.luau",
	"src/client/World/BuildFx.luau",
	"src/client/World/Earnings.luau",
	"src/client/World/Gather.luau",
	"src/client/Controllers/Audio.luau",
}

describe("Sounds", function()
	it("lists every sound by its library id, with its name and maker, at a soft volume", function()
		local n = 0
		for _, e in Sounds.all() do
			n += 1
			local s = e.entry
			expect(type(s.id) == "number" and s.id > 0 and s.id == math.floor(s.id)).toBeTruthy()
			expect(type(s.name) == "string" and #s.name > 0).toBeTruthy()
			expect(type(s.by) == "string" and #s.by > 0).toBeTruthy()
			expect(s.volume).toBeBetween(0.01, 2.5)
			if s.rate then
				expect(s.rate).toBeBetween(0.25, 3)
			end
			if s.from then
				expect(s.from >= 0).toBeTruthy()
			end
			expect(Sounds.asset(s.id)).toBe("rbxassetid://" .. s.id)
		end
		expect(n >= 20).toBeTruthy()
	end)

	it("has every effect the client asks for", function()
		local asked = 0
		for _, path in CALLERS do
			local text = readFile(path)
			expect(text ~= nil).toBeTruthy()
			for _, pattern in { 'Kit%.sound%("(%w+)"', 'Audio%.play%("(%w+)"', 'Audio%.at%("(%w+)"' } do
				for key in text:gmatch(pattern) do
					asked += 1
					if not Sounds.Effects[key] then
						error(path .. " asks for a sound there is none of: " .. key)
					end
				end
			end
		end
		expect(asked >= 12).toBeTruthy()
		-- and what Kit.press and the notices play by kind
		for _, key in { "click", "tab", "open", "close", "notice", "good", "warn" } do
			expect(Sounds.Effects[key] ~= nil).toBeTruthy()
		end
	end)

	it("keeps the voices' syllables in order and the playlist whole", function()
		local seen = {}
		for _, name in Sounds.VoiceOrder do
			expect(Sounds.Voices[name] ~= nil).toBeTruthy()
			seen[name] = true
			local v = Sounds.Voices[name]
			-- a syllable is short: one sound, or a recording cut into its syllables
			if v.grains then
				for _, g in v.grains do
					expect(g[2]).toBeBetween(0.03, 0.3)
					expect(g[3] > 0).toBeTruthy()
				end
				expect(v.hz > 0).toBeTruthy()
			else
				expect(v.len).toBeBetween(0.03, 0.3)
			end
		end
		for name in Sounds.Voices do
			expect(seen[name]).toBe(true)
		end
		local listed = {}
		for _, key in Sounds.Playlist do
			expect(Sounds.Music[key] ~= nil).toBeTruthy()
			listed[key] = true
		end
		for key in Sounds.Music do
			expect(listed[key]).toBe(true)
		end
		for kind, mix in Sounds.Weather do
			for loop, share in mix do
				expect(Sounds.Loops[loop] ~= nil).toBeTruthy()
				expect(share).toBeBetween(0, 1)
			end
			local _ = kind
		end
	end)

	it("saves Music, Effects and Voices with every profile, an old one too", function()
		for _, k in Sound.Keys do
			expect(Schema.Settings[k] ~= nil).toBeTruthy()
		end
		expect(Schema.Settings.voices).toBe(true)
		local old = Schema.migrate({ settings = { music = 0.2, sfx = 0.1 } })
		expect(old.settings.music).toBe(0.2)
		expect(old.settings.voices).toBe(true)
		local s = Graphics.clean({ music = 4, sfx = 0 / 0, voices = "yes" })
		expect(s.music).toBe(1)
		expect(s.sfx).toBe(Schema.Settings.sfx)
		expect(s.voices).toBe(true)
	end)

	it("plays each group no louder than Tuning.Audio, the voices off with Voices off", function()
		local K = Tuning.Audio
		local full = Sound.levels({ music = 1, sfx = 1, voices = true }, 12, false)
		expect(full.music).toBeNear(K.Music, 1e-9)
		expect(full.effects).toBeNear(K.Effects, 1e-9)
		expect(full.voices).toBeNear(K.Voices, 1e-9)
		expect(full.voices <= full.effects).toBeTruthy()
		local quiet = Sound.levels({ music = 0, sfx = 0, voices = true }, 12, false)
		expect(quiet.music).toBe(0)
		expect(quiet.effects).toBe(0)
		expect(quiet.voices).toBe(0)
		expect(Sound.levels({ voices = false }, 12, false).voices).toBe(0)
		-- nothing is loud by default
		local default = Sound.levels(nil, 12, false)
		expect(default.music <= 0.5).toBeTruthy()
		expect(default.effects <= 0.8).toBeTruthy()
	end)

	it("plays the music softer at night and under a conversation", function()
		local day = Sound.levels({}, 12, false).music
		expect(Sound.levels({}, 23, false).music < day).toBeTruthy()
		expect(Sound.levels({}, 2, false).music < day).toBeTruthy()
		expect(Sound.levels({}, 8, false).music).toBeNear(day, 1e-9)
		expect(Sound.levels({}, 12, true).music < day).toBeTruthy()
		expect(Sound.night(Tuning.Audio.NightFrom)).toBe(true)
		expect(Sound.night(Tuning.Audio.NightTo)).toBe(false)
		expect(Sound.night(nil)).toBe(false)
	end)

	it("never plays the same track twice running, and keeps night tracks to the night", function()
		for _, night in { false, true } do
			local last = nil
			for i = 0, 40 do
				local key = Sound.nextTrack(last, night, (i * 0.137) % 1)
				local t = Sounds.Music[key]
				expect(t ~= nil).toBeTruthy()
				expect(key ~= last).toBeTruthy()
				if not night then
					expect(t.night ~= true).toBeTruthy()
				else
					expect(t.day ~= true).toBeTruthy()
				end
				last = key
			end
		end
		expect(Sound.rest(0)).toBe(Tuning.Audio.Rest[1])
		expect(Sound.rest(1)).toBe(Tuning.Audio.Rest[2])
	end)

	it("hears rain in the rain, wind in a storm, nothing in clear weather, all softer indoors", function()
		local rain = Sound.weather("rain", false)
		expect(rain.rain > 0).toBeTruthy()
		local storm = Sound.weather("storm", false)
		expect(storm.storm > 0 and storm.wind > 0).toBeTruthy()
		for _, v in Sound.weather("clear", false) do
			expect(v).toBe(0)
		end
		for _, v in Sound.weather(nil, false) do
			expect(v).toBe(0)
		end
		expect(Sound.weather("rain", true).rain < rain.rain).toBeTruthy()
	end)
end)
