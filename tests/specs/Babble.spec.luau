--!nocheck
-- Villagers' voices (Sim/Babble). The user: "Like tomodachi life, can you make it such that
-- villagers have voices, talking like in tomodachi life sounds? players can configure them just
-- like in tomodachi life." A voice is four sliders saved with the villager; as a line types out, a
-- syllable plays every few letters, its pitch, pace and sound from the voice. These hold the
-- sliders, the defaults by personality, the letters to beeps and the pitch from the sliders.

local Shared = "ReplicatedStorage.Shared."
local Tuning = require(Shared .. "Config.Tuning")
local Babble = require(Shared .. "Sim.Babble")
local Sounds = require(Shared .. "Data.Sounds")
local Schema = require(Shared .. "Sim.Schema")
local Personalities = require(Shared .. "Data.Personalities")

local K = Tuning.Voices

local function onStep(x)
	local n = x / K.Step
	return math.abs(n - math.floor(n + 0.5)) < 1e-6 and x >= 0 and x <= 1
end

local function isVoice(v)
	for _, k in Babble.Keys do
		if type(v[k]) ~= "number" or not onStep(v[k]) then
			return false
		end
	end
	return true
end

local function letters(text)
	local out = {}
	for _, c in utf8.codes(text) do
		table.insert(out, c)
	end
	return out
end

describe("Babble", function()
	it("gives every personality a voice of its own, inside the sliders", function()
		local seen = {}
		for _, p in Personalities.list do
			local v = Babble.ByPers[p.id]
			expect(v ~= nil).toBeTruthy()
			expect(isVoice(Babble.clean(v))).toBe(true)
			local key = Babble.encode(v)
			expect(seen[key] == nil).toBeTruthy()
			seen[key] = true
		end
		expect(#Babble.Sliders).toBe(#Babble.Keys)
	end)

	it("cleans what it is sent: clamped, on its steps, broken ones from the fallback", function()
		expect(Babble.clean(nil)).toBe(nil)
		expect(Babble.clean("loud")).toBe(nil)
		local v = Babble.clean({ pitch = 7, speed = -2, tone = 0 / 0, lilt = 0.333 })
		expect(v.pitch).toBe(1)
		expect(v.speed).toBe(0)
		expect(v.tone).toBe(0.5)
		expect(onStep(v.lilt)).toBe(true)
		expect(v.lilt).toBeNear(0.35, 1e-9)
		local fb = Babble.clean({ pitch = 0.2 }, { pitch = 0, speed = 0.1, tone = 0.9, lilt = 1 })
		expect(fb.pitch).toBeNear(0.2, 1e-9)
		expect(fb.tone).toBeNear(0.9, 1e-9)
		expect(Babble.clean({ pitch = math.huge }).pitch).toBe(0.5)
	end)

	it("lets an old save's villager talk in their personality's voice, a little their own", function()
		local a = Babble.of({ id = "v1", pers = "gloomy" })
		local b = Babble.of({ id = "v2", pers = "gloomy" })
		local base = Babble.ByPers.gloomy
		for _, k in Babble.Keys do
			expect(math.abs(a[k] - base[k]) <= K.Nudge + K.Step / 2 + 1e-9).toBeTruthy()
		end
		expect(Babble.encode(a) ~= Babble.encode(b)).toBeTruthy()
		-- the same villager sounds the same every time
		expect(Babble.encode(Babble.of({ id = "v1", pers = "gloomy" }))).toBe(Babble.encode(a))
		-- a saved voice wins
		local own = { pitch = 0.9, speed = 0.1, tone = 0.2, lilt = 0.4 }
		expect(Babble.encode(Babble.of({ id = "v1", pers = "gloomy", voice = own }))).toBe(Babble.encode(own))
		-- nothing at all: the middle of every slider
		expect(Babble.encode(Babble.of(nil))).toBe(Babble.encode(Babble.Middle))
	end)

	it("writes a voice on a model and reads it back", function()
		local v = Babble.clean({ pitch = 0.25, speed = 0.8, tone = 0.6, lilt = 0.05 })
		local back = Babble.decode(Babble.encode(v))
		for _, k in Babble.Keys do
			expect(back[k]).toBeNear(v[k], 1e-9)
		end
		expect(Babble.decode("nonsense")).toBe(nil)
		expect(Babble.decode(5)).toBe(nil)
		-- a player's (the tutorial's friend) is the same each time and inside the sliders
		expect(Babble.encode(Babble.forSeed(1234))).toBe(Babble.encode(Babble.forSeed(1234)))
		expect(isVoice(Babble.forSeed("someone"))).toBe(true)
	end)

	it("saves the voice the creator sends, and none when it sends none", function()
		local input = Schema.cleanVillagerInput({
			name = "Ada",
			pers = "shy",
			voice = { pitch = 2, speed = 0.4, tone = 0.3, lilt = 0.6 },
		})
		expect(input.voice.pitch).toBe(1)
		local v = Schema.newVillager("v9", input, {
			pick = function(_, list)
				return list[1]
			end,
		})
		expect(v.voice.speed).toBeNear(0.4, 1e-9)
		local plain = Schema.cleanVillagerInput({ name = "Bo", pers = "shy" })
		expect(plain.voice).toBe(nil)
		-- an old save's broken voice is dropped, a good one kept clean
		local p = Schema.migrate({
			villagers = {
				v1 = { name = "A", pers = "sunny", voice = "loud" },
				v2 = { name = "B", pers = "sunny", voice = { pitch = 0.42, speed = 1, tone = 0, lilt = 0.5 } },
			},
		})
		expect(p.villagers.v1.voice).toBe(nil)
		expect(onStep(p.villagers.v2.voice.pitch)).toBe(true)
	end)

	it("turns the pitch slider into speed: higher sliders, higher syllables", function()
		local low = Babble.rate({ pitch = 0, speed = 0.5, tone = 0.5, lilt = 0.5 })
		local mid = Babble.rate({ pitch = 0.5, speed = 0.5, tone = 0.5, lilt = 0.5 })
		local high = Babble.rate({ pitch = 1, speed = 0.5, tone = 0.5, lilt = 0.5 })
		expect(low < mid and mid < high).toBeTruthy()
		-- each end is Tuning.Voices.Pitch semitones off the sound's own pitch
		local name = Babble.sound({ pitch = 0.5, speed = 0.5, tone = 0.5, lilt = 0.5 })
		local own = Sounds.Voices[name].rate or 1
		expect(high / own).toBeNear(2 ^ (K.Pitch[2] / 12), 1e-6)
		expect(low / own).toBeNear(2 ^ (K.Pitch[1] / 12), 1e-6)
		-- a semitone up is the twelfth root of two
		local v = { pitch = 0.5, speed = 0.5, tone = 0.5, lilt = 0.5 }
		expect(Babble.rate(v, 12) / Babble.rate(v)).toBeNear(2, 1e-6)
	end)

	it("picks the syllable sound by tone, softest first, every one in Data/Sounds", function()
		local last = 0
		for i = 0, 20 do
			local name, treble = Babble.sound({ pitch = 0.5, speed = 0.5, tone = i / 20, lilt = 0.5 })
			local at = table.find(Sounds.VoiceOrder, name)
			expect(at ~= nil).toBeTruthy()
			expect(at >= last).toBeTruthy()
			last = at
			expect(treble).toBeBetween(-6, 3)
			expect(Sounds.Voices[name] ~= nil).toBeTruthy()
		end
		expect(Babble.sound({ pitch = 0.5, speed = 0.5, tone = 0, lilt = 0.5 })).toBe(Sounds.VoiceOrder[1])
		expect(Babble.sound({ pitch = 0.5, speed = 0.5, tone = 1, lilt = 0.5 })).toBe(
			Sounds.VoiceOrder[#Sounds.VoiceOrder]
		)
	end)

	it("babbles on letters only, every few letters, faster voices more often", function()
		local text = "Hey, how are you doing? I baked bread today, and it came out well."
		local codes = letters(text)
		local slow = Babble.plan({ pitch = 0.5, speed = 0, tone = 0.5, lilt = 0.5 }, text)
		local fast = Babble.plan({ pitch = 0.5, speed = 1, tone = 0.5, lilt = 0.5 }, text)
		expect(#slow > 0).toBeTruthy()
		expect(#fast > #slow).toBeTruthy()
		for _, plan in { slow, fast } do
			local last = -math.huge
			for _, b in plan do
				local ch = utf8.char(codes[b.at])
				expect(ch:match("%w") ~= nil).toBeTruthy()
				expect(b.at > last).toBeTruthy()
				last = b.at
				expect(b.rate > 0).toBeTruthy()
				expect(b.length > 0).toBeTruthy()
			end
		end
		-- the first letter starts it
		expect(slow[1].at).toBe(1)
		-- gaps follow the speed slider: Tuning.Voices.Gap seconds at the typing pace
		local every = math.floor(K.Gap[1] * K.Typing + 0.5)
		for i = 2, #slow do
			expect(slow[i].at - slow[i - 1].at >= every).toBeTruthy()
		end
		-- about one a gap's worth of letters, never one a letter
		expect(#slow <= math.ceil(#codes / every)).toBeTruthy()
		expect(#fast < #codes / 2).toBeTruthy()
	end)

	it("says nothing for nothing, and copes with any script", function()
		expect(#Babble.plan(Babble.Middle, "")).toBe(0)
		expect(#Babble.plan(Babble.Middle, "... !? ~")).toBe(0)
		local t = Babble.plan(Babble.Middle, "ありがとう、またね")
		expect(#t > 0).toBeTruthy()
		expect(#Babble.plan(Babble.Middle, "♪ ♪ …")).toBe(0)
	end)

	it("babbles the same words the same way every time", function()
		local v = Babble.ByPers.dramatic
		local a = Babble.plan(v, "Oh no, the soup boiled over again!")
		local b = Babble.plan(v, "Oh no, the soup boiled over again!")
		expect(#a).toBe(#b)
		for i in a do
			expect(a[i].at).toBe(b[i].at)
			expect(a[i].rate).toBe(b[i].rate)
		end
	end)

	it("rises at a question's end, falls at a sentence's, and moves more with more melody", function()
		local v = { pitch = 0.5, speed = 0.5, tone = 0.5, lilt = 0 }
		local q = Babble.plan(v, "Do you want some tea")
		local qq = Babble.plan(v, "Do you want some tea?")
		local dot = Babble.plan(v, "Do you want some tea.")
		expect(#q).toBe(#qq)
		expect(qq[#qq].rate > q[#q].rate).toBeTruthy()
		expect(dot[#dot].rate < q[#q].rate).toBeTruthy()
		-- with no melody every syllable but the ends sits on the voice's own pitch
		expect(q[1].rate).toBeNear(Babble.rate(v), 1e-9)
		-- an exclamation is a touch louder at its end
		local bang = Babble.plan(v, "That is so good!")
		expect(bang[#bang].volume > 1).toBeTruthy()
		-- the more melody, the further the pitch moves along a line
		local function spread(plan)
			local lo, hi = math.huge, -math.huge
			for _, b in plan do
				lo, hi = math.min(lo, b.rate), math.max(hi, b.rate)
			end
			return hi / lo
		end
		local line = "I went down to the harbour and the boats were all out at sea"
		local flat = Babble.plan({ pitch = 0.5, speed = 0.8, tone = 0.5, lilt = 0 }, line)
		local lively = Babble.plan({ pitch = 0.5, speed = 0.8, tone = 0.5, lilt = 1 }, line)
		expect(spread(lively) > spread(flat)).toBeTruthy()
		expect(spread(flat)).toBeNear(1, 1e-9)
		-- and never further than the melody and a question's rise allow
		expect(spread(lively) <= 2 ^ ((2 * K.Lilt + K.Rise + K.Fall) / 12) + 1e-6).toBeTruthy()
	end)

	it("babbles a sentence ending in its own way, a question in the middle of a line too", function()
		local v = { pitch = 0.5, speed = 1, tone = 0.5, lilt = 0 }
		local plan = Babble.plan(v, "Are you sure? It looks heavy to me.")
		local base = Babble.rate(v)
		local up, down = false, false
		for _, b in plan do
			up = up or b.rate > base * 1.01
			down = down or b.rate < base * 0.99
		end
		expect(up and down).toBeTruthy()
	end)
end)
