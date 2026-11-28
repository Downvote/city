--!strict
-- What a player's sound settings mean on their own screen (the user: "add sounds where necessary,
-- along with a calm cozy music track in the background. use roblox library for these, dont make
-- your own"). Settings' Music and Effects (0 to 1) and Voices (on or off) are saved with the
-- profile like the graphics choices (Schema.Settings, `SettingSet` checks each on the server); the
-- client's Controllers/Audio plays Data/Sounds with them. This is the rule behind it, free of
-- services so the Settings spec can hold it: how loud each group is, when the music is softer,
-- and which track comes next.

local Tuning = require(script.Parent.Parent.Config.Tuning)
local Sounds = require(script.Parent.Parent.Data.Sounds)
local Graphics = require(script.Parent.Graphics)

local Sound = {}

local K = Tuning.Audio

-- the settings the Settings menu's Sound rows show
Sound.Keys = { "music", "sfx", "voices" }

export type Levels = { music: number, effects: number, voices: number }

-- Is the town's hour `hour` (0 to 24) in the night, when the music is softer?
function Sound.night(hour: number?): boolean
	if type(hour) ~= "number" or hour ~= hour then
		return false
	end
	local h = hour % 24
	if K.NightFrom > K.NightTo then
		return h >= K.NightFrom or h < K.NightTo
	end
	return h >= K.NightFrom and h < K.NightTo
end

-- How loud each group plays (a SoundGroup's Volume): the settings times Tuning.Audio, the music
-- softer at night and while a conversation is up, the voices silent with Voices off (and never
-- louder than the effects they sit under).
function Sound.levels(settings: any, hour: number?, talking: boolean?): Levels
	local s = Graphics.clean(settings)
	local music = s.music * K.Music
	if Sound.night(hour) then
		music *= K.Night
	end
	if talking then
		music *= K.Talking
	end
	local effects = s.sfx * K.Effects
	return {
		music = music,
		effects = effects,
		voices = if s.voices then s.sfx * K.Voices else 0,
	}
end

-- The track to play after `last`: one of the playlist's that suits the hour (Data/Sounds'
-- Playlist: a track marked `night` only plays at night, one marked `day` only by day), never the
-- one just played while there is another, picked by `roll` (0 to 1).
function Sound.nextTrack(last: string?, night: boolean, roll: number): string
	local fits: { string } = {}
	for _, key in Sounds.Playlist do
		local t = Sounds.Music[key]
		if t and not (t.night and not night) and not (t.day and night) and key ~= last then
			table.insert(fits, key)
		end
	end
	if #fits == 0 then
		for _, key in Sounds.Playlist do
			if key ~= last then
				table.insert(fits, key)
			end
		end
	end
	if #fits == 0 then
		return Sounds.Playlist[1]
	end
	local i = math.clamp(math.floor(math.clamp(roll, 0, 0.999999) * #fits) + 1, 1, #fits)
	return fits[i]
end

-- Seconds of quiet between two tracks, for `roll` (0 to 1).
function Sound.rest(roll: number): number
	return K.Rest[1] + (K.Rest[2] - K.Rest[1]) * math.clamp(roll, 0, 1)
end

-- How much of the rain and the wind is heard in weather `kind` (Data/Sounds' Weather), all of it
-- softer under a roof.
function Sound.weather(kind: string?, sheltered: boolean?): { [string]: number }
	local out: { [string]: number } = {}
	for loop in Sounds.Loops do
		out[loop] = 0
	end
	local mix = kind and Sounds.Weather[kind]
	if mix then
		for loop, share in mix do
			out[loop] = if sheltered then share * K.UnderRoof else share
		end
	end
	return out
end

return Sound
