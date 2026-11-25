--!nocheck
-- Every personality writes its own way (the user: "just like the blue archive momotalks, make
-- every single personality have a unique and distinct speech pattern, like using ~ at the end of
-- sentances, ... and other details"). Sim/Voice puts each one's marks on every line they say.

local Shared = "ReplicatedStorage.Shared."
local Voice = require(Shared .. "Sim.Voice")
local Personalities = require(Shared .. "Data.Personalities")

-- lines anybody might be handed (an event's default, a job line), to see each hand on them
local SHARED = {
	"Thanks, that really helps.",
	"I'm going to the market later.",
	"Did you see the boats come in?",
	"That was a lovely day out.",
	"Sorry, I didn't mean to.",
	"It's raining again.",
	"We should do this more often!",
	"I don't know what to say.",
	"Okay, I'll meet you at the fountain.",
	"The bakery has fresh bread today.",
	"Can you help me carry this?",
	"That's the best news all week!",
	"Hi, it's good to see you.",
	"I can't find my keys anywhere.",
	"So, what do you want to do?",
	"Yeah, that sounds fine to me.",
	"Hey, wait for me.",
	"No, I'd rather stay in.",
	"It's a nice evening for a walk.",
	"That's not how I remember it.",
	"Oh, I nearly forgot to tell you.",
	"I made too much soup again.",
	"Wait, is that a seal?",
	"This is so much fun!",
}

local function all(pers)
	local out = {}
	for _, t in SHARED do
		table.insert(out, Voice.speak(pers, t))
	end
	return out
end

local function share(list, test)
	local n = 0
	for _, t in list do
		if test(t) then
			n += 1
		end
	end
	return n / #list
end

describe("Voice", function()
	it("has a hand for every personality but a few who speak with words alone", function()
		for _, p in Personalities.list do
			local wordsOnly = p.id == "proud" or p.id == "bookish" or p.id == "foodie"
			expect(Voice.Rules[p.id] ~= nil or wordsOnly).toBeTruthy()
		end
	end)

	it("says a line the same way every time, and saying it twice changes nothing", function()
		for _, p in Personalities.list do
			for _, t in SHARED do
				local once = Voice.speak(p.id, t)
				expect(Voice.speak(p.id, t)).toBe(once)
				expect(Voice.speak(p.id, once)).toBe(once)
			end
		end
	end)

	it("leaves the words alone", function()
		-- only the marks, a drawl, a stammer, case or a contraction change: never what is said
		local function squeeze(s)
			local out, n = s:gsub("(%a)%1", "%1")
			while n > 0 do
				out, n = out:gsub("(%a)%1", "%1")
			end
			return out
		end
		local function words(t)
			local w = t:lower():gsub("cannot", "can not"):gsub("let us", "let's"):gsub("(%a)%-(%a)", "%2")
			return squeeze((w:gsub("[^%a]", "")))
		end
		local OPEN = {
			["i'm"] = "i am",
			["it's"] = "it is",
			["that's"] = "that is",
			["don't"] = "do not",
			["didn't"] = "did not",
			["can't"] = "can not",
			["i'll"] = "i will",
			["i'd"] = "i would",
		}
		for _, p in Personalities.list do
			for _, t in SHARED do
				local plain = t:lower()
				if p.id == "polite" then
					for from, to in OPEN do
						plain = plain:gsub("%f[%a]" .. from .. "%f[%A]", to)
					end
				end
				expect(words(Voice.speak(p.id, t))).toBe(words(plain))
			end
		end
	end)

	it("gives each hand its marks", function()
		local gentle = all("gentle")
		expect(share(gentle, function(t)
			return t:sub(-1) == "~"
		end) >= 0.25).toBeTruthy()

		local cheeky = all("cheeky")
		for _, t in cheeky do
			expect(t:lower()).toBe(t)
			expect(t:sub(-1) ~= ".").toBeTruthy()
		end

		for _, t in all("cool") do
			expect(t:find("!", 1, true)).toBe(nil)
			expect(t:find("~", 1, true)).toBe(nil)
			expect(t:sub(-3) ~= "...").toBeTruthy()
		end

		local gloomy = all("gloomy")
		for _, t in gloomy do
			expect(t:find("!", 1, true)).toBe(nil)
		end
		expect(share(gloomy, function(t)
			return t:sub(-3) == "..."
		end) >= 0.4).toBeTruthy()

		for _, t in all("polite") do
			expect(t:find("'m", 1, true) or t:find("n't", 1, true) or t:find("'ll", 1, true) or t:find("'s ", 1, true)).toBe(
				nil
			)
		end

		expect(share(all("nervous"), function(t)
			return t:match("^%a%-%a") ~= nil
		end) >= 0.2).toBeTruthy()

		expect(share(all("dramatic"), function(t)
			return t:find("!!", 1, true) ~= nil
		end) >= 0.1).toBeTruthy()

		expect(share(all("easygoing"), function(t)
			return t:match("^%a*(%a)%1%1") ~= nil
		end) >= 0.1).toBeTruthy()

		expect(share(all("shy"), function(t)
			return t:find("...", 1, true) ~= nil
		end) >= 0.25).toBeTruthy()

		expect(share(all("dreamy"), function(t)
			return t:sub(-3) == "..."
		end) >= 0.2).toBeTruthy()

		expect(share(all("sunny"), function(t)
			return t:sub(-1) == "!"
		end) >= 0.3).toBeTruthy()

		for _, t in all("bold") do
			expect(t:sub(-3) ~= "...").toBeTruthy()
			expect(t:find("~", 1, true)).toBe(nil)
		end
	end)

	it("keeps the soft ~ for the gentle ones alone", function()
		for _, p in Personalities.list do
			if p.id ~= "gentle" then
				for _, t in SHARED do
					expect(Voice.speak(p.id, t .. "~"):sub(-1) ~= "~").toBeTruthy()
				end
			end
		end
	end)

	it("never stammers on a name, and leaves narration and silence alone", function()
		for _ = 1, 3 do
			expect(Voice.speak("nervous", "Robin, are you free?")).toBe("Robin, are you free?")
		end
		expect(Voice.speak("cheeky", "...")).toBe("...")
		expect(Voice.speak("gentle", "")).toBe("")
		expect(Voice.speak(nil, "Hello.")).toBe("Hello.")
	end)
end)
