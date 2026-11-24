--!nonstrict
-- A villager asks you something, and the answer matters a little: which outfit, whether to tell
-- a friend the truth, what to give somebody, a motto, a hobby, what to cook, who to ask to the
-- dance, whether to say sorry first. What you pick can make a friend, a sulk, a new saying.

local K = require(script.Parent.Kit)
local Sayings = require(script.Parent.Parent.Sayings)
local Foods = require(script.Parent.Parent.Foods)

local W = K.W

local list = {}
local function event(def)
	def.actors = def.actors or 1
	table.insert(list, def)
end

event({
	id = "outfit",
	when = "day",
	weight = W({ base = 0.18 }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "Which one")
		s:say("a", "Quick, before I go out. The yellow hat or the stripy scarf?", "question")
		s:by("a", {
			proud = "Both look perfect on me, obviously. But which is MORE perfect?",
			shy = "I don't want anyone to look at me. But I want them to look a bit.",
			easygoing = "I'd just wear both, but apparently that's too much.",
			sunny = "I've changed four times already, I can't decide, you pick.",
			_ = "I've been standing here for twenty minutes.",
		}, "sweat")
		s:choice("The yellow hat", function(c)
			c:by("a", {
				shy = "The hat? Okay. Okay. I'll be brave.",
				proud = "The hat. Yes. People will talk, and they should.",
				easygoing = "Hat. Cool. Done.",
				_ = "The hat it is. Right, I'm off.",
			}, "sparkle", "cheer")
			c:mood("a", 4)
		end)
		s:choice("The stripy scarf", function(c)
			c:by("a", {
				bold = "Scarf. Done. Let's go.",
				dreamy = "The scarf. It's like wearing a hug.",
				_ = "The scarf. Good call, it's cold out.",
			}, "heart")
			c:mood("a", 4)
		end)
		s:choice("Something new altogether", function(c)
			c:say("a", "Ooh. A whole new look? Help me pick.", "sparkle", "cheer")
			c:fx({ t = "creator", who = "a" })
			c:mood("a", 3)
		end)
		s:log("{a} asked which outfit to wear.")
		return s:done()
	end,
})

event({
	id = "truth",
	actors = 2,
	when = "day",
	weight = W({ base = 0.15, rel = 15 }),
	scene = function(ctx, a, b)
		local s = K.scene(ctx, "Honestly")
		s:n("{a} has pulled you aside, out of {b}'s earshot.")
		s:say("a", "{b} keeps cooking for me, and it's... it's really bad. Should I say?", "sweat")
		s:choice("Tell them, kindly", function(c)
			c:say("a", "{b}, I love that you cook for me. But maybe less salt? Much less?", "sweat")
			if K.isPers(ctx, b, "proud", "bold") then
				c:by("b", {
					proud = "Less salt? My cooking is FLAWLESS. ...How much less?",
					_ = "WHAT. ...Fine. I'll taste it first next time.",
				}, "anger")
				c:rel(2)
			else
				c:by("b", {
					shy = "Oh no. I've been doing it all wrong. Thank you for telling me.",
					cheeky = "I knew. I wanted to see how long you'd last.",
					_ = "Honestly? Thank you. Help me next time?",
				}, "heart")
				c:rel(8)
			end
		end)
		s:choice("Keep eating it", function(c)
			c:say("a", "Fine. I'll eat it. I'll have a big glass of water ready.", "sad")
			c:mood("a", -3)
			c:rel(2)
		end)
		s:log("{a} wondered whether to tell {b} the truth about their cooking.")
		return s:done()
	end,
})

-- what a personality likes to be given
local LIKES = {
	sunny = "balloons",
	gentle = "flowers",
	bold = "dumbbells",
	dreamy = "a book of poems",
	easygoing = "a hammock",
	proud = "a mirror",
	shy = "a little plant",
	cheeky = "a joke shop kit",
}
local GIFTS = {
	"flowers",
	"a book of poems",
	"a hammock",
	"a mirror",
	"a little plant",
	"a joke shop kit",
	"balloons",
	"dumbbells",
}

event({
	id = "giftadvice",
	actors = 2,
	when = "day",
	weight = W({ base = 0.18, rel = 10 }),
	scene = function(ctx, a, b)
		local want = LIKES[K.pers(ctx, b)] or "flowers"
		local options = { want }
		for _, g in ctx.rng:shuffle(GIFTS) do
			if #options >= 3 then
				break
			end
			if not table.find(options, g) then
				table.insert(options, g)
			end
		end
		options = ctx.rng:shuffle(options)
		local s = K.scene(ctx, "A present for {b}")
		s:say("a", "I want to get {b} something nice. What do you think they'd like?", "question")
		for _, g in options do
			s:choice(g:sub(1, 1):upper() .. g:sub(2), function(c)
				c:with({ gift = g })
				c:n("{a} gave {b} {gift}.")
				if g == want then
					c:voice("b", "excited", "heart", "cheer")
					c:rel(14)
					c:mood("b", 8)
				else
					c:by("b", {
						proud = "Oh. You got me {gift}. How... thoughtful.",
						bold = "You got me {gift}? Huh. Okay. Thanks.",
						shy = "Oh. You got me {gift}. Thank you. Really.",
						cheeky = "You got me {gift}. Is this a prank? It feels like a prank.",
						_ = "Oh. You got me {gift}. That's... thank you.",
					}, "sweat")
					c:rel(3)
				end
			end)
		end
		s:log("{a} asked what to give {b}.")
		return s:done()
	end,
})

event({
	id = "motto",
	when = "any",
	weight = W({ base = 0.12 }),
	scene = function(ctx, a)
		local v = ctx.v(a)
		local options = {}
		for _, say in ctx.rng:shuffle(Sayings.list) do
			if say.id ~= v.saying and #options < 3 then
				table.insert(options, say)
			end
		end
		local s = K.scene(ctx, "A motto")
		s:say("a", "I need a thing I say. Everyone has a thing they say. Pick one for me.", "question")
		for _, say in options do
			s:choice(say.text, function(c)
				c:with({ motto = say.text })
				c:by("a", {
					proud = "'{motto}' Yes. It suits me. Most things do.",
					shy = "'{motto}' Um. I'll try saying it. Quietly at first.",
					easygoing = "'{motto}' Yeah. I can say that.",
					_ = "'{motto}' ...Yes. That's me. That's so me.",
				}, "sparkle", "cheer")
				c:saying("a", say.id)
				c:mood("a", 3)
			end)
		end
		s:log("{a} picked a new saying.")
		return s:done()
	end,
})

event({
	id = "pickhobby",
	when = "day",
	weight = W({ base = 0.1, traits = { focus = -0.2 } }),
	scene = function(ctx, a)
		local v = ctx.v(a)
		local options = {}
		for _, h in ctx.rng:shuffle(Sayings.hobbies) do
			if h.id ~= v.hobby and #options < 3 then
				table.insert(options, h)
			end
		end
		local s = K.scene(ctx, "Something to do")
		s:say("a", "I'm bored of being bored. Give me a hobby. Any hobby.", "question")
		for _, h in options do
			s:choice(h.name:sub(1, 1):upper() .. h.name:sub(2), function(c)
				c:with({ hobby = h.name, Hobby = h.name:sub(1, 1):upper() .. h.name:sub(2) })
				c:by("a", {
					bold = "{Hobby}. Right. I'll be the best at it by Friday.",
					easygoing = "{Hobby}? Sure. Why not.",
					_ = "{Hobby}? Okay. Okay. I'm in.",
				}, "idea", "cheer")
				c:hobby("a", h.id)
				c:mood("a", 4)
				c:memo("a", "You got me into {hobby}. I'm not very good yet.")
			end)
		end
		s:log("{a} asked you to pick them a hobby.")
		return s:done()
	end,
})

event({
	id = "dayplan",
	when = "day",
	weight = W({
		base = 0.15,
		cond = function(ctx)
			return ctx.hour < 13
		end,
	}),
	scene = function(ctx, a)
		local s = K.scene(ctx, "Plans for today")
		s:say("a", "Day off. Beach or library? I can't decide.", "question")
		s:choice("The beach", function(c)
			c:say("a", "The beach it is. I'll take a towel and see how long I last.", "sparkle", "cheer")
			c:mood("a", 5)
			c:memo("a", "I went to the beach because you said so. Good call.")
		end)
		s:choice("The library", function(c)
			c:say("a", "Library, then. There's a big chair by the window I like.", "heart")
			c:mood("a", 4)
			c:memo("a", "I read a whole book at the library yesterday. You were right.")
		end)
		s:log("{a} asked how to spend the day.")
		return s:done()
	end,
})

event({
	id = "dancepartner",
	actors = 3,
	when = "any",
	weight = W({ base = 0.12, count = 3 }),
	scene = function(ctx, a, b, c)
		local s = K.scene(ctx, "The dance")
		s:say("a", "There's a dance at the hall on Friday. I don't want to go on my own. {b} or {c}?", "sweat")
		s:choice("Ask {b}", function(ch)
			ch:say("a", "{b}, come to the dance with me? I need someone to stand by the snacks with.", "sweat")
			ch:voice("b", if ctx.rel(a, b) >= 0 then "yes" else "no", "heart")
			ch:relx("a", "b", if ctx.rel(a, b) >= 0 then 10 else -2)
		end)
		s:choice("Ask {c}", function(ch)
			ch:say("a", "{c}, come to the dance with me? I need someone to stand by the snacks with.", "sweat")
			ch:voice("c", if ctx.rel(a, c) >= 0 then "yes" else "no", "heart")
			ch:relx("a", "c", if ctx.rel(a, c) >= 0 then 10 else -2)
		end)
		s:choice("Go with everyone", function(ch)
			ch:say("a", "Everyone. Of course. Why choose?", "music")
			ch:relx("a", "b", 3)
			ch:relx("a", "c", 3)
		end)
		s:log("{a} asked who to take to the dance.")
		return s:done()
	end,
})

local PLANTNAMES = { "Fernando", "Leafy", "Little Steve", "Sprout", "Margaret", "Gus" }

event({
	id = "nameplant",
	when = "day",
	weight = W({ base = 0.1 }),
	scene = function(ctx, a)
		local names = ctx.rng:shuffle(PLANTNAMES)
		local s = K.scene(ctx, "A plant with no name")
		s:say("a", "My new plant needs a name. It's a fern. It's very serious.", "question")
		for i = 1, 3 do
			local name = names[i]
			s:choice(name, function(c)
				c:with({ plant = name })
				c:say("a", "{plant}. Hello, {plant}. Welcome home.", "heart", "cheer")
				c:mood("a", 3)
				c:memo("a", "{plant} the fern has a new leaf. I'm very proud.")
			end)
		end
		s:log("{a} asked you to name their plant.")
		return s:done()
	end,
})

event({
	id = "dyehair",
	when = "day",
	weight = W({ base = 0.1, traits = { brave = 0.3 } }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "A bold idea")
		s:say("a", "I'm thinking of dyeing my hair blue. Bright blue. Should I?", "idea")
		s:choice("Do it", function(c)
			c:by("a", {
				shy = "Okay. Okay. Before I lose my nerve.",
				bold = "Yes. Now. Get the dye.",
				_ = "Yes. Let's do it now before I change my mind.",
			}, "sparkle", "cheer")
			c:fx({ t = "creator", who = "a" })
			c:mood("a", 4)
		end)
		s:choice("Sleep on it", function(c)
			c:say("a", "Sensible. I'll dream about being blue.", "zzz")
			c:mood("a", 1)
		end)
		s:log("{a} thought about dyeing their hair blue.")
		return s:done()
	end,
})

event({
	id = "cookfor",
	cutscene = "kitchen",
	actors = 2,
	when = "day",
	weight = W({ base = 0.12, rel = 20 }),
	scene = function(ctx, a, b)
		local fav = Foods.get(ctx.v(b).fav)
		local options = {}
		if fav then
			table.insert(options, fav)
		end
		for _, f in ctx.rng:shuffle(Foods.list) do
			if #options >= 3 then
				break
			end
			if not table.find(options, f) then
				table.insert(options, f)
			end
		end
		options = ctx.rng:shuffle(options)
		local s = K.scene(ctx, "Dinner for {b}")
		s:say("a", "I'm cooking dinner for {b} tonight. What should I make?", "question")
		for _, f in options do
			s:choice(f.name, function(c)
				c:with({ food = f.name:lower() })
				c:n("{a} made {food}.")
				if fav and f.id == fav.id then
					c:say("b", "My favourite. How did you know?", "heart", "cheer")
					c:rel(12)
					c:mood("b", 6)
				else
					c:voice("b", "thanks", "heart")
					c:rel(5)
				end
			end)
		end
		s:log("{a} cooked dinner for {b}.")
		return s:done()
	end,
})

event({
	id = "sayfirst",
	actors = 2,
	when = "any",
	weight = W({ base = 0.5, quarrel = true }),
	scene = function(ctx, a, b)
		local s = K.scene(ctx, "Who says sorry")
		s:say("a", "{b} and I still aren't talking. Should I say sorry first? It was half their fault.", "sad")
		s:choice("Say it first", function(c)
			c:by("a", {
				proud = "{b}. I may have been... partly wrong. Can we stop this now?",
				shy = "{b}? I'm sorry. I don't like this. Can we stop?",
				bold = "{b}. I'm sorry. There. Can we stop this now?",
				_ = "{b}. I'm sorry. Can we stop this now?",
			}, "sad")
			if ctx.rng:chance(0.5 + K.trait(ctx, b, "kind") * 0.4) then
				c:say("b", "...Yes. I'm sorry too. I missed you.", "heart")
				c:fx({ t = "makeup", a = "a", b = "b" })
				c:rel(10)
				c:mood("a", 5)
			else
				c:say("b", "Half? HALF?", "anger")
				c:rel(-3)
			end
		end)
		s:choice("Give it a day", function(c)
			c:by("a", {
				proud = "One more day. They might come to me first.",
				shy = "One more day. I need to work out what to say.",
				_ = "One more day. Then I'll go.",
			}, "sad")
			c:mood("a", -2)
		end)
		s:log("{a} wondered whether to say sorry to {b}.")
		return s:done()
	end,
})

local SKILLS =
	{ "juggling", "whistling with two fingers", "skipping stones", "doing a handstand", "folding paper cranes" }

event({
	id = "learnskill",
	when = "day",
	weight = W({ base = 0.1 }),
	scene = function(ctx, a)
		local opts = ctx.rng:shuffle(SKILLS)
		local s = K.scene(ctx, "Something to learn")
		s:say("a", "I want to learn something this week. Which one?", "question")
		for i = 1, 2 do
			local skill = opts[i]
			s:choice(skill:sub(1, 1):upper() .. skill:sub(2), function(c)
				c:with({ skill = skill, Skill = skill:sub(1, 1):upper() .. skill:sub(2) })
				c:by("a", {
					proud = "{Skill}. I'll be better at it than anyone in town by Sunday.",
					easygoing = "{Skill}. Cool. I'll practise. At some point.",
					_ = "{Skill}. Right. I'll practise every day this week.",
				}, "idea", "cheer")
				c:xp("a", 10)
				c:mood("a", 3)
				c:memo("a", "I've been practising {skill}. Ask me to show you. Actually, don't, yet.")
			end)
		end
		s:log("{a} wanted to learn something new.")
		return s:done()
	end,
})

event({
	id = "surpriseparty",
	actors = 2,
	when = "any",
	weight = W({ base = 0.1, rel = 20, traits = { mischief = 0.2 } }),
	scene = function(ctx, a, b)
		local s = K.scene(ctx, "Keep a secret?")
		s:say("a", "I'm planning a surprise party for {b}. You won't tell them, will you?", "question")
		s:choice("My lips are sealed", function(c)
			c:say("a", "Good. Act normal. Act very normal.", "sparkle")
			c:n("At the party {b} was so surprised they dropped a whole cake. Worth it.")
			c:prop("balloons", "a")
			c:rel(10)
			c:mood("b", 8)
		end)
		s:choice("Drop a hint", function(c)
			c:n("You told {b} to wear something nice on Friday. No reason.")
			c:say("b", "Is there a surprise party? There's a surprise party.", "sparkle")
			c:say("a", "Who told? WHO TOLD?", "anger")
			c:rel(4)
			c:mood("b", 4)
		end)
		s:log("{a} planned a surprise party for {b}.")
		return s:done()
	end,
})

return list
