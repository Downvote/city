--!strict
-- Every sound the game plays, all from the Roblox library (the user: "use roblox library for these,
-- dont make your own"): Roblox's own uploads and the libraries Roblox licensed for every game, Pro
-- Sound Effects' sounds and APM's music, so any game may play them. Each was found and measured
-- with scripts/library_sounds.py (search, info), and `python3 scripts/library_sounds.py check`
-- confirms every id here is still public and still plays (run it now and then: sounds can be
-- taken down). Played on each player's own screen by client Controllers/Audio; Sim/Sound and
-- Sim/Babble are the rules.
--
-- A line: `id` the audio's asset id, `volume` its Sound.Volume (worked out from how loud it is, so
-- each sits at its own soft level before the player's Settings), `rate` its PlaybackSpeed, `from`
-- and `len` where in it the sound starts and how long it lasts (seconds), `name` and `by` what the
-- Creator Store calls it and who made it (for music, the artist and the library). One sound a
-- line: the check script reads this file line by line.

export type Entry = {
	id: number,
	volume: number,
	name: string,
	by: string,
	rate: number?,
	from: number?,
	len: number?,
	hz: number?, -- (a voice) the pitch it has as recorded
	grains: { { number } }?, -- (a voice) its syllables: { from, len, hz }
	day: boolean?, -- (music) only by day
	night: boolean?, -- (music) only at night
}

local Sounds = {}

-- One-shot effects, by what they're for: a press (click; a tab: tab), a menu opening and closing,
-- a notice (good news: good; a warning: warn), coins earned over a villager (coin) and coins
-- claimed (coins), the town's next level, a gift, something picked up, a piece put down, sold or
-- turned in Build mode, a door, thunder.
-- stylua: ignore
Sounds.Effects = {
	click = { id = 15675059323, volume = 0.126, len = 0.09, name = "Roblox_UI_Bright_Click", by = "Roblox" }, -- loudest -15.0 dB, 0.09 s heard
	tab = { id = 15675032796, volume = 0.617, len = 0.03, name = "Roblox_UI_Small_Click", by = "Roblox" }, -- loudest -30.8 dB, 0.03 s heard
	open = { id = 15675012262, volume = 0.072, len = 0.25, name = "Roblox_UI_Whoosh_04", by = "Roblox" }, -- loudest -14.2 dB, 0.24 s heard
	close = { id = 10128766965, volume = 0.562, len = 0.33, name = "RBLX UI Swipe (SFX)", by = "Roblox" }, -- loudest -33.0 dB, 0.33 s heard
	notice = { id = 15675055424, volume = 0.08, len = 0.75, name = "Roblox_UI_Cute_Pop", by = "Roblox" }, -- loudest -12.1 dB, 0.75 s heard
	good = { id = 15675055424, volume = 0.09, rate = 1.12, len = 0.75, name = "Roblox_UI_Cute_Pop", by = "Roblox" }, -- loudest -12.1 dB, 0.75 s heard
	warn = { id = 15675062723, volume = 0.038, len = 0.21, name = "Roblox_UI_Whistle_Low", by = "Roblox" }, -- loudest -8.5 dB, 0.2 s heard
	coin = { id = 12221990, volume = 0.077, rate = 1.5, len = 0.48, name = "electronicpingshort.wav", by = "Roblox" }, -- loudest -15.7 dB, 0.48 s heard
	coins = { id = 127645268874265, volume = 0.176, len = 0.41, name = "CoinTransfer_01", by = "Roblox" }, -- loudest -17.9 dB, 0.41 s heard
	levelup = { id = 15675043410, volume = 0.104, len = 0.94, name = "Roblox_UI_Tonal_Stinger", by = "Roblox" }, -- loudest -9.3 dB, 0.94 s heard
	gift = { id = 9117042092, volume = 0.21, len = 2.02, name = "Music Box Swan Lake Single Notes 3 (SFX)", by = "ProSoundEffects" }, -- loudest -17.6 dB, 2.02 s heard (the user: "change the gift sound ... to something else from the roblox library"; it was a cluster of magic chimes)
	pickup = { id = 17208204604, volume = 0.191, len = 0.41, name = "Roblox GUI - Bubble", by = "Roblox" }, -- loudest -18.6 dB, 0.41 s heard
	place = { id = 9120898595, volume = 0.359, len = 0.99, name = "Wood Impact 1 (SFX)", by = "ProSoundEffects" }, -- loudest -22.1 dB, 0.99 s heard
	sell = { id = 15675075163, volume = 0.234, len = 0.34, name = "Roblox_UI_Delete", by = "Roblox" }, -- loudest -21.4 dB, 0.34 s heard
	rotate = { id = 16480568432, volume = 0.044, len = 0.46, name = "Audio/Roblox_Pinball_Bumper_Soft_Click_03", by = "Roblox" }, -- loudest -9.9 dB, 0.46 s heard
	door = { id = 9114142431, volume = 2.5, len = 0.59, name = "Door Latch Open And Close 2 (SFX)", by = "ProSoundEffects" }, -- loudest -42.2 dB, 0.59 s heard
	thunder = { id = 9120018050, volume = 0.335, len = 4.04, name = "Thunder Distant Boom Thud Rapid Hits 15 (SFX)", by = "ProSoundEffects" }, -- loudest -21.5 dB, 4.01 s heard
} :: { [string]: Entry }

-- The weather's loops (Weather below says how much of each), played over and over.
-- stylua: ignore
Sounds.Loops = {
	rain = { id = 9112852671, volume = 2.213, len = 36.01, name = "Rain Continuous Drizzle 2 (SFX)", by = "ProSoundEffects" }, -- loudest -41.9 dB, 36.01 s heard
	storm = { id = 9112853287, volume = 1.799, len = 41.01, name = "Rain Heavy 1 (SFX)", by = "ProSoundEffects" }, -- loudest -37.1 dB, 41.01 s heard
	wind = { id = 9114057104, volume = 0.977, len = 37.05, name = "Desert Wind Whistley Light Gusts 1 (SFX)", by = "ProSoundEffects" }, -- loudest -38.8 dB, 37.03 s heard
} :: { [string]: Entry }

-- How much of each loop the weather has (0 to 1); a kind not here is quiet.
Sounds.Weather = {
	rain = { rain = 1 },
	storm = { storm = 1, wind = 0.7 },
	snow = { wind = 0.4 },
	cloudy = { wind = 0.25 },
	leaves = { wind = 0.5 },
	blossom = { wind = 0.25 },
} :: { [string]: { [string]: number } }

-- The villagers' syllables (Sim/Babble), softest first (VoiceOrder): a round mouth pop, a soft
-- wooden knock, a synth voice's syllables, a little beep. `rate` brings each to the same pitch.
-- stylua: ignore
Sounds.Voices = {
	pluck = { id = 9117014841, volume = 0.367, rate = 0.881, from = 0.07, len = 0.1, hz = 681, name = "Mouth Drips Cheek Pluck Water Liquid 19 (SFX)", by = "ProSoundEffects" }, -- loudest -19.3 dB, 0.12 s heard
	block = { id = 9120917813, volume = 0.417, rate = 0.794, from = 0.0, len = 0.08, hz = 756, name = "Wood Impacts Soft Impacts On Temple Blocks 6 (SFX)", by = "ProSoundEffects" }, -- loudest -21.4 dB, 0.09 s heard
	chatter = { id = 9118531345, volume = 0.881, rate = 0.759, hz = 790, grains = { { 0.08, 0.2, 759 }, { 0.509, 0.11, 826 }, { 1.018, 0.09, 781 } }, len = 1.53, name = "Robot Vocals Silly Chatter Synthy Rambling 6 (SFX)", by = "ProSoundEffects" }, -- loudest -26.9 dB, 1.5 s heard
	beep = { id = 9113880475, volume = 0.603, rate = 0.535, from = 0.0, len = 0.12, hz = 1645, name = "Computer Keyboard Beep 3 (SFX)", by = "ProSoundEffects" }, -- loudest -26.6 dB, 0.13 s heard
} :: { [string]: Entry }
Sounds.VoiceOrder = { "pluck", "block", "chatter", "beep" }

-- The music: calm tracks played one at a time with quiet between, picked at random from the
-- Playlist (Sim/Sound.nextTrack), never the same twice running. `day` ones only by day, `night`
-- ones only at night. Each track's volume sets it to the same loudness over the whole song
-- (`python3 scripts/library_sounds.py level <ids>`: weighted as the ear hears, the quiet stretches
-- left out), so no song plays quieter than the rest (the user: "some songs are quieter than
-- others"; they had been set by their loudest moment). A new track takes `Sounds.MusicLevel`.
-- stylua: ignore
Sounds.Music = {
	lakefront = { id = 9038622066, volume = 0.157, day = true, name = "Lakefront Days (Ukulele Underscore Version)", by = "Inside Tracks (APMOfficial)" }, -- whole song -16.5 dB, 135.21 s heard
	ukulele = { id = 1842619720, volume = 0.108, day = true, name = "Ukulele Lullaby", by = "Jacob King (APMOfficial)" }, -- whole song -13.2 dB, 152.59 s heard
	peaceful = { id = 122584281971383, volume = 0.129, name = "Peaceful Days", by = "Franck Sarkissian (APMOfficial)" }, -- whole song -14.7 dB, 94.87 s heard
	cozy = { id = 1847848565, volume = 0.138, name = "Calm And Cozy C", by = "Otto Sieben (APMOfficial)" }, -- whole song -15.4 dB, 105.7 s heard
	musicbox = { id = 9047785119, volume = 0.332, night = true, name = "Music Box Lullaby", by = "Erazoff (APMOfficial)" }, -- whole song -23.0 dB, 136.18 s heard
	evening = { id = 1847848511, volume = 0.091, night = true, name = "Calm And Cozy A", by = "Otto Sieben (APMOfficial)" }, -- whole song -11.7 dB, 119.3 s heard
} :: { [string]: Entry }
-- the loudness every track is set to, in dB over the whole song (library_sounds.py level)
Sounds.MusicLevel = -32.6
Sounds.Playlist = { "lakefront", "ukulele", "peaceful", "cozy", "musicbox", "evening" }

function Sounds.asset(id: number): string
	return "rbxassetid://" .. tostring(id)
end

-- Every sound here, with the table it is in and its key.
function Sounds.all(): { { group: string, key: string, entry: Entry } }
	local out = {}
	for _, pair in
		{
			{ "Effects", Sounds.Effects },
			{ "Loops", Sounds.Loops },
			{ "Voices", Sounds.Voices },
			{ "Music", Sounds.Music },
		} :: { { any } }
	do
		local keys = {}
		for k in pair[2] do
			table.insert(keys, k)
		end
		table.sort(keys)
		for _, k in keys do
			table.insert(out, { group = pair[1], key = k, entry = pair[2][k] })
		end
	end
	return out
end

return Sounds
