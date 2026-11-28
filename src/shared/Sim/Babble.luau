--!strict
-- How a villager sounds when they talk. The user: "Like tomodachi life, can you make it such that
-- villagers have voices, talking like in tomodachi life sounds? players can configure them just
-- like in tomodachi life." Not words: a babble of short sounds from the Roblox library
-- (Data/Sounds' Voices), one every few letters as their words type out, each pitched and timed by
-- the villager's own voice, so every villager sounds like themselves. The idea is taken, never the
-- sounds: ours are library sounds put together our own way.
--
-- A voice is four sliders, each 0 to 1 (Tuning.Voices.Step apart), saved with the villager
-- (`voice`) and set in the creator:
--   pitch  low to high (Tuning.Voices.Pitch: semitones off the sound's own pitch)
--   speed  how quickly the syllables come and how short each is
--   tone   soft to bright: which of the syllable sounds, and its treble
--   lilt   flat to sing song: how far the pitch moves along a line
-- A villager with no voice saved (an old save) has their personality's (ByPers), moved a little by
-- their id so two of the same personality don't sound alike. Free of services: the spec runs it.
--
-- Babble.plan(voice, text) is the babble for a line: a beep at a letter (by its place among the
-- line's letters, as UI/Dialogue counts them while it types) with its sound, its speed (pitch) and
-- loudness. The same words always babble the same way (choices come from the letters, never at
-- random). Spaces, digits' neighbours and marks never get a beep; a question rises at its end, a
-- sentence that ends in a full stop falls a little, and "!" is a touch louder.

local Tuning = require(script.Parent.Parent.Config.Tuning)
local Sounds = require(script.Parent.Parent.Data.Sounds)

local Babble = {}

local K = Tuning.Voices

export type Voice = { pitch: number, speed: number, tone: number, lilt: number }
export type Beep = { at: number, sound: string, rate: number, volume: number, length: number }

Babble.Keys = { "pitch", "speed", "tone", "lilt" }

-- the sliders' names in the creator
Babble.Sliders = {
	{ key = "pitch", name = "Pitch" },
	{ key = "speed", name = "Speed" },
	{ key = "tone", name = "Tone" },
	{ key = "lilt", name = "Melody" },
}

-- Each personality's voice, as they'd sound before anyone changes it.
-- stylua: ignore
Babble.ByPers = {
	sunny = { pitch = 0.65, speed = 0.65, tone = 0.6, lilt = 0.7 },
	gentle = { pitch = 0.55, speed = 0.35, tone = 0.2, lilt = 0.5 },
	bold = { pitch = 0.3, speed = 0.6, tone = 0.7, lilt = 0.4 },
	dreamy = { pitch = 0.6, speed = 0.25, tone = 0.15, lilt = 0.8 },
	easygoing = { pitch = 0.4, speed = 0.3, tone = 0.35, lilt = 0.5 },
	proud = { pitch = 0.4, speed = 0.45, tone = 0.65, lilt = 0.3 },
	shy = { pitch = 0.7, speed = 0.4, tone = 0.2, lilt = 0.35 },
	cheeky = { pitch = 0.75, speed = 0.8, tone = 0.8, lilt = 0.8 },
	cool = { pitch = 0.3, speed = 0.45, tone = 0.5, lilt = 0.15 },
	prickly = { pitch = 0.45, speed = 0.7, tone = 0.85, lilt = 0.3 },
	dramatic = { pitch = 0.55, speed = 0.55, tone = 0.65, lilt = 0.95 },
	bookish = { pitch = 0.5, speed = 0.55, tone = 0.45, lilt = 0.3 },
	gloomy = { pitch = 0.2, speed = 0.2, tone = 0.25, lilt = 0.1 },
	polite = { pitch = 0.55, speed = 0.45, tone = 0.4, lilt = 0.4 },
	foodie = { pitch = 0.45, speed = 0.5, tone = 0.3, lilt = 0.6 },
	nervous = { pitch = 0.7, speed = 0.9, tone = 0.5, lilt = 0.6 },
} :: { [string]: Voice }

Babble.Middle = { pitch = 0.5, speed = 0.5, tone = 0.5, lilt = 0.5 } :: Voice

local function snap(x: number): number
	local s = K.Step
	return math.clamp(math.floor(x / s + 0.5) * s, 0, 1)
end

-- A number from a string, the same every time.
local function hash(s: string): number
	local h = 5381
	for i = 1, #s do
		h = (h * 33 + string.byte(s, i)) % 2147483647
	end
	return h
end

-- A voice from anything: each slider a number, clamped to 0..1 and snapped to its step, a missing
-- or broken one from `fallback` (the middle of every slider without one). Nil when `raw` isn't a
-- table at all.
function Babble.clean(raw: any, fallback: Voice?): Voice?
	if type(raw) ~= "table" then
		return nil
	end
	local base = fallback or Babble.Middle
	local out: any = {}
	for _, k in Babble.Keys do
		local v = raw[k]
		if type(v) ~= "number" or v ~= v or v == math.huge or v == -math.huge then
			v = (base :: any)[k]
		end
		out[k] = snap(v)
	end
	return out :: Voice
end

-- A personality's voice, moved a little by `seed` (a villager's id) when one is given.
function Babble.default(pers: string?, seed: string?): Voice
	local base = (pers and Babble.ByPers[pers]) or Babble.Middle
	local out: any = table.clone(base)
	if seed and seed ~= "" then
		for i, k in Babble.Keys do
			-- (pitch and speed move the most: the tone and the melody say who they are)
			local share = if i <= 2 then 1 else 0.5
			local wob = (hash(seed .. "|" .. k) % 1000) / 999 * 2 - 1
			out[k] = out[k] + wob * K.Nudge * share
		end
	end
	return Babble.clean(out) :: Voice
end

-- The voice a villager talks in: their own, or their personality's.
function Babble.of(v: any): Voice
	if type(v) ~= "table" then
		return Babble.Middle
	end
	local pers = if type(v.pers) == "string" then v.pers else nil
	local id = if type(v.id) == "string" then v.id else nil
	local fallback = Babble.default(pers, id)
	return Babble.clean(v.voice, fallback) or fallback
end

-- A voice from a number or a string (a player in the tutorial: their user id), the same every time.
function Babble.forSeed(seed: any): Voice
	local s = tostring(seed)
	local out: any = {}
	for _, k in Babble.Keys do
		out[k] = 0.2 + (hash(s .. "|" .. k) % 1000) / 999 * 0.6
	end
	return Babble.clean(out) :: Voice
end

-- On a villager's model (an attribute, so every screen hears them): "0.50,0.40,0.70,0.30".
function Babble.encode(voice: Voice): string
	return string.format("%.2f,%.2f,%.2f,%.2f", voice.pitch, voice.speed, voice.tone, voice.lilt)
end

function Babble.decode(s: any): Voice?
	if type(s) ~= "string" then
		return nil
	end
	local p, sp, t, l = s:match("^([%d%.]+),([%d%.]+),([%d%.]+),([%d%.]+)$")
	if not p then
		return nil
	end
	return Babble.clean({ pitch = tonumber(p), speed = tonumber(sp), tone = tonumber(t), lilt = tonumber(l) })
end

local function lerp(a: number, b: number, t: number): number
	return a + (b - a) * t
end

-- Seconds between two syllables, and how long each lasts at most.
function Babble.gap(voice: Voice): number
	return lerp(K.Gap[1], K.Gap[2], voice.speed)
end

function Babble.length(voice: Voice): number
	return lerp(K.Length[1], K.Length[2], voice.speed)
end

-- The syllable sound for a voice's tone (Data/Sounds' Voices, softest first), and the treble to
-- give it (dB, for an equalizer's high band): each sound covers a stretch of the slider and is made
-- a little duller or brighter along it.
function Babble.sound(voice: Voice): (string, number)
	local list = Sounds.VoiceOrder
	local n = #list
	local i = math.clamp(math.floor(voice.tone * n) + 1, 1, n)
	local within = voice.tone * n - (i - 1) -- 0..1 along its stretch
	return list[i], lerp(-6, 3, math.clamp(within, 0, 1))
end

-- The speed to play a syllable at for `semitones` off the voice's own pitch.
function Babble.rate(voice: Voice, semitones: number?): number
	local name = Babble.sound(voice)
	local own = Sounds.Voices[name]
	local base = if own and own.rate then own.rate else 1
	local st = lerp(K.Pitch[1], K.Pitch[2], voice.pitch) + (semitones or 0)
	return base * 2 ^ (st / 12)
end

-- Is this character one a beep may land on: a letter or a digit, in any script.
local function speakable(c: number): boolean
	if c < 128 then
		local ch = string.char(c)
		return ch:match("[%w]") ~= nil
	end
	-- outside plain text: letters of other scripts count, but not the marks and faces we write
	-- (♪, ~, …, the quotes and dashes)
	return not (c == 0x266A or c == 0x2026 or (c >= 0x2010 and c <= 0x201F) or c == 0x00B7)
end

-- How a letter moves the pitch, -1 to 1, the same every time: the vowels sit up, the rest about.
local VOWEL = { a = 0.6, e = 0.9, i = 1, o = 0.2, u = 0.4, y = 0.7 }
local function lean(c: number): number
	if c < 128 then
		local ch = string.char(c):lower()
		local v = VOWEL[ch]
		if v then
			return v
		end
		return ((c * 37) % 17) / 8 - 1
	end
	return ((c * 37) % 17) / 8 - 1
end

-- The babble for a line of plain words (no rich text tags). `lps`: letters a second as the words
-- show (Tuning.Voices.Typing by default).
function Babble.plan(voice: Voice, text: string, lps: number?): { Beep }
	local perSecond = lps or K.Typing
	local codes: { number } = {}
	local ok = pcall(function()
		for _, c in utf8.codes(text) do
			table.insert(codes, c)
		end
	end)
	if not ok then
		codes = {}
		for i = 1, #text do
			table.insert(codes, string.byte(text, i))
		end
	end
	local n = #codes
	local beeps: { Beep } = {}
	if n == 0 then
		return beeps
	end
	local every = math.max(1, math.floor(Babble.gap(voice) * perSecond + 0.5))
	local sound, _ = Babble.sound(voice)
	local length = Babble.length(voice)
	-- Each letter's sentence: how it ends ("?" if a question mark is in its closing marks, else "!"
	-- if there is one, else "."; "" for none) and where its last letter is. A sentence runs to a run of marks
	-- (". ", "?!", "...", "…") or to the end of the line.
	local sentenceEnd: { [number]: number } = {}
	local endHow: { [number]: string } = {}
	local function isMark(c: number?): boolean
		return c == 63 or c == 33 or c == 46 or c == 0x2026 -- ? ! . …
	end
	local start = 1
	local k = 1
	while k <= n do
		if isMark(codes[k]) or k == n then
			local stop = k
			-- (a line that stops without a mark ends as it goes: no rise, no fall)
			local how = if isMark(codes[k]) then "." else ""
			while stop <= n and isMark(codes[stop]) do
				if codes[stop] == 63 then
					how = "?"
				elseif codes[stop] == 33 and how ~= "?" then
					how = "!"
				end
				stop += 1
			end
			stop = math.min(stop - 1, n)
			if stop < k then
				stop = k
			end
			local lastLetter = start
			for j = start, stop do
				if speakable(codes[j]) then
					lastLetter = j
				end
			end
			for j = start, stop do
				sentenceEnd[j] = lastLetter
				endHow[j] = how
			end
			start = stop + 1
			k = stop + 1
		else
			k += 1
		end
	end
	local since = math.huge
	local lilt = voice.lilt * K.Lilt
	for i = 1, n do
		since += 1
		local c = codes[i]
		if speakable(c) and since >= every then
			since = 0
			local t = (i - 1) / math.max(1, n - 1)
			-- the line's arc: up a little in the first part, gently down to the end
			local arc = math.sin(t * math.pi) * 0.5 - t * 0.3
			local st = lilt * (arc + lean(c) * 0.6)
			local close = sentenceEnd[i] - i -- letters to the end of this sentence
			local volume = 1
			if close < every * 2 then
				local k = 1 - close / (every * 2)
				if endHow[i] == "?" then
					st += K.Rise * k
				elseif endHow[i] == "!" then
					volume = 1.15
				elseif endHow[i] == "." then
					st -= K.Fall * k
				end
			end
			table.insert(beeps, {
				at = i,
				sound = sound,
				rate = Babble.rate(voice, st),
				volume = volume,
				length = length,
			})
		end
	end
	return beeps
end

return Babble
