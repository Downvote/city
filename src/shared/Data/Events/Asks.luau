--!nonstrict
-- A villager comes to you with something small, and the answer matters a little: which outfit,
-- whether to tell a friend the truth, what to give somebody, a motto, a hobby, what to cook, who
-- to take to the dance, whether to say sorry first; too much bread, a shell off the beach, a
-- colour for the front door, company on the pier at night, a stool they made, a neighbour's late
-- music, lights on the islet, nerves before a big day, a soup to taste, a letter to their gran, a
-- drooping plant, a rainy day, a night they can't sleep, a name they've forgotten, a secret spot,
-- a silly hat, a question they want to practise, a bet on the weather, a knock at six, a wave you
-- missed, the room you built them. What you pick can make a friend, a sulk, a new saying.
--
-- They come to you the way a friend texts: short bursts, two or three quick lines, their own
-- voice, and your name ({player}, the player's own name) when they want your attention.

local K = require(script.Parent.Kit)
local Sayings = require(script.Parent.Parent.Sayings)
local Foods = require(script.Parent.Parent.Foods)

local W = K.W

local list = {}
local function event(def)
	def.actors = def.actors or 1
	table.insert(list, def)
end

local function upper(s: string): string
	return s:sub(1, 1):upper() .. s:sub(2)
end

event({
	id = "outfit",
	when = "day",
	weight = W({ base = 0.18 }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "Which one")
		s:say("a", "{player}, quick. Before I go out.", "question", "wave")
		s:say("a", "Yellow hat or stripy scarf?", "question")
		s:by("a", {
			proud = "Both look perfect on me. Obviously. But which is more perfect?",
			shy = "I don't want people to look at me. But I want them to look a bit.",
			easygoing = "I'd wear both, but apparently that's too much.",
			sunny = "I've changed four times. I can't decide. You pick. Please.",
			cool = "Pick one.",
			prickly = "Don't laugh. Just pick.",
			dramatic = "This decides my whole afternoon. No pressure.",
			bookish = "I made a list of pros and cons. It's a tie.",
			gloomy = "Both look bad. Pick the less bad one.",
			polite = "Sorry to ask. I'd really value your opinion.",
			foodie = "Whichever hides crumbs better.",
			nervous = "What if I pick wrong and everyone sees? Help.",
			_ = "I've been standing here twenty minutes.",
		}, "sweat")
		s:choice("The yellow hat", function(c)
			c:by("a", {
				shy = "The hat? Okay. Okay. I'll be brave.",
				proud = "The hat. People will talk, and they should.",
				easygoing = "Hat. Cool. Done.",
				cool = "Hat. Okay.",
				nervous = "The hat. You're sure? Okay. The hat.",
				dramatic = "The hat. Bold. I like it. I like you.",
				_ = "The hat it is. Thanks, {player}.",
			}, "sparkle", "cheer")
			c:mood("a", 4)
		end)
		s:choice("The stripy scarf", function(c)
			c:by("a", {
				bold = "Scarf. Done. Let's go.",
				dreamy = "The scarf. It's like wearing a hug...",
				gloomy = "Scarf. Good. It'll be cold anyway.",
				foodie = "Scarf. It has folds. Folds hold snacks.",
				_ = "The scarf. Good call. It's cold out.",
			}, "heart")
			c:mood("a", 4)
		end)
		s:choice("Something new altogether", function(c)
			c:by("a", {
				nervous = "A whole new look? Now? Okay. Stay with me while I pick.",
				prickly = "New. Fine. You're helping, though.",
				_ = "Ooh. A whole new look? Help me pick, {player}.",
			}, "sparkle", "cheer")
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
		s:say("a", "{player}. Can I ask you something awkward?", "sweat")
		s:by("a", {
			polite = "{b} keeps cooking for me, which is very kind. But it's... not good. Should I say?",
			prickly = "{b} keeps cooking for me. It's awful. I've eaten all of it. Should I say?",
			nervous = "{b} keeps cooking for me and it's really bad. What if they ask if I liked it? Should I say?",
			foodie = "{b} keeps cooking for me. As someone who knows food. It's bad. Should I say?",
			_ = "{b} keeps cooking for me. And it's... it's really bad. Should I say?",
		}, "sweat")
		s:choice("Tell them, kindly", function(c)
			c:say("a", "{b}, I love that you cook for me. But maybe less salt? Much less?", "sweat")
			if K.isPers(ctx, b, "proud", "bold", "prickly", "dramatic") then
				c:by("b", {
					proud = "Less salt? My cooking is flawless. ...How much less?",
					prickly = "Fine. Less salt. Don't read into it.",
					dramatic = "My cooking. Insulted. ...Show me how much.",
					_ = "What. ...Fine. I'll taste it first next time.",
				}, "anger")
				c:rel(2)
			else
				c:by("b", {
					shy = "Oh no. I've been doing it all wrong. Thank you for telling me.",
					cheeky = "I knew. I wanted to see how long you'd last.",
					gloomy = "I knew it was bad. Thanks for eating it anyway.",
					polite = "Thank you for being so honest. Would you show me how you'd do it?",
					nervous = "It was bad? All of it? Oh no. Help me next time?",
					_ = "Honestly? Thank you. Help me next time?",
				}, "heart")
				c:rel(8)
			end
		end)
		s:choice("Keep eating it", function(c)
			c:say("a", "Fine. I'll eat it. With a big glass of water.", "sad")
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
	cool = "a pair of sunglasses",
	prickly = "a cactus",
	dramatic = "a velvet cushion",
	bookish = "a new notebook",
	gloomy = "a black umbrella",
	polite = "a box of writing paper",
	foodie = "a cookbook",
	nervous = "a lucky charm",
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
	"a pair of sunglasses",
	"a cactus",
	"a velvet cushion",
	"a new notebook",
	"a black umbrella",
	"a box of writing paper",
	"a cookbook",
	"a lucky charm",
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
		s:by("a", {
			nervous = "{player}, I want to get {b} something. What if I get it wrong?",
			bookish = "{player}, I'm getting {b} a present. I've narrowed it to three.",
			_ = "{player}. I want to get {b} something nice.",
		}, "question")
		s:say("a", "What would they like?", "question")
		for _, g in options do
			s:choice(upper(g), function(c)
				c:with({ gift = g })
				c:n("{a} gave {b} {gift}.")
				if g == want then
					c:voice("b", "excited", "heart", "cheer")
					c:rel(14)
					c:mood("b", 8)
				else
					c:by("b", {
						proud = "Oh. {gift}. How... thoughtful.",
						bold = "You got me {gift}? Huh. Okay. Thanks.",
						shy = "Oh. You got me {gift}. Thank you. Really.",
						cheeky = "{gift}. Is this a prank? It feels like a prank.",
						cool = "{gift}. Thanks.",
						prickly = "{gift}? Hm. I'll find a use for it. Probably.",
						gloomy = "{gift}. Okay. Nobody ever knows what to get me.",
						polite = "{gift}. How kind of you. Thank you.",
						foodie = "{gift}. Can you eat it? No? Okay. Thanks.",
						nervous = "{gift}? For me? Oh. Thank you. I'll look after it.",
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
		s:say("a", "{player}. I need a thing I say.", "question")
		s:by("a", {
			dramatic = "Everyone has a line. A signature. I need mine.",
			cool = "Everyone's got one. Pick mine.",
			nervous = "Everyone has one and I don't and people have noticed. Probably. Pick one?",
			_ = "Everyone's got a thing they say. Pick one for me?",
		}, "question")
		for _, say in options do
			s:choice(say.text, function(c)
				c:with({ motto = say.text })
				c:by("a", {
					proud = "'{motto}' Yes. It suits me. Most things do.",
					shy = "'{motto}' Um. I'll try saying it. Quietly at first.",
					easygoing = "'{motto}' Yeah. I can say that.",
					cool = "'{motto}' Fine. That's mine now.",
					dramatic = "'{motto}' Oh, that's me. That's exactly me.",
					gloomy = "'{motto}' Hm. I'll give it a week.",
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
		s:by("a", {
			gloomy = "{player}. I'm bored. Very bored. Bored all the way down.",
			dramatic = "{player}. I'm so bored I could lie down in the road.",
			easygoing = "{player}. I'm bored. Not a lot. Just enough.",
			_ = "{player}. I'm bored of being bored.",
		}, "sad")
		s:say("a", "Give me a hobby. Any hobby.", "question")
		for _, h in options do
			s:choice(upper(h.name), function(c)
				c:with({ hobby = h.name, Hobby = upper(h.name) })
				c:by("a", {
					bold = "{Hobby}. Right. I'll be the best at it by Friday.",
					easygoing = "{Hobby}? Sure. Why not.",
					proud = "{Hobby}. Very well. I'll be good at it, naturally.",
					shy = "{Hobby}? Um. Okay. I'll try.",
					bookish = "{Hobby}. I'll get a book on it first.",
					nervous = "{Hobby}? What if I'm bad at it? ...Okay. I'll try.",
					_ = "{Hobby}? Okay. Okay. I'm in.",
				}, "idea", "cheer")
				c:hobby("a", h.id)
				c:mood("a", 4)
				c:memo("a", "You got me into {hobby}, {player}. I'm not very good yet.")
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
		s:by("a", {
			easygoing = "Day off. Beach or library? Or bed. Bed's an option.",
			bookish = "Day off. Library, obviously. But the beach has... sand. Help?",
			nervous = "Day off. What if I pick the beach and it rains?",
			_ = "Day off today. Beach or library? I can't decide.",
		}, "question")
		s:say("a", "You pick, {player}.", "question")
		s:choice("The beach", function(c)
			c:say("a", "Beach it is. I'll take a towel and see how long I last.", "sparkle", "cheer")
			c:mood("a", 5)
			c:memo("a", "I went to the beach because you said so, {player}. Good call.")
		end)
		s:choice("The library", function(c)
			c:say("a", "Library, then. There's a big chair by the window I like.", "heart")
			c:mood("a", 4)
			c:memo("a", "I read a whole book at the library. You were right.")
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
		s:say("a", "There's a dance at the hall on Friday. I don't want to go on my own.", "sweat")
		s:say("a", "{player}. {b} or {c}? Who do I ask?", "question")
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
		s:choice("Go as a group", function(ch)
			ch:say("a", "All of us. Course. Why choose?", "music")
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
		s:say("a", "{player}. My new plant needs a name.", "question")
		s:by("a", {
			dramatic = "It's a fern. A very serious fern. It needs a name with weight.",
			gloomy = "It's a fern. It looks worried. Like me.",
			_ = "It's a fern. Very serious fern.",
		}, "question")
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
		s:say("a", "I'm thinking of dyeing my hair blue. Bright blue.", "idea")
		s:by("a", {
			nervous = "Should I? What if it goes green? Should I?",
			dramatic = "A new me. A blue me. Should I, {player}?",
			_ = "Should I, {player}?",
		}, "question")
		s:choice("Do it", function(c)
			c:by("a", {
				shy = "Okay. Okay. Before I lose my nerve.",
				bold = "Yes. Now. Get the dye.",
				prickly = "Fine. If it's awful I'm blaming you.",
				_ = "Yes. Now, before I change my mind.",
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
		s:by("a", {
			foodie = "{player}. I'm cooking for {b} tonight. This is my moment.",
			nervous = "{player}, I'm cooking for {b} tonight and I've never cooked for anyone.",
			_ = "{player}, I'm cooking dinner for {b} tonight.",
		}, "question")
		s:say("a", "What should I make?", "question")
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
		s:by("a", {
			prickly = "{player}. {b} and I still aren't talking. Whatever.",
			gloomy = "{b} and I still aren't talking. It's been ages.",
			nervous = "{player}... {b} and I still aren't talking. It's been two days. I've counted.",
			_ = "{player}. {b} and I still aren't talking.",
		}, "sad")
		s:say("a", "Should I say sorry first? It was half their fault.", "sad")
		s:choice("Say it first", function(c)
			c:by("a", {
				proud = "{b}. I may have been... partly wrong. Can we stop this now?",
				shy = "{b}? I'm sorry. I don't like this. Can we stop?",
				bold = "{b}. I'm sorry. There. Can we stop this now?",
				prickly = "{b}. Sorry. ...I mean it. Don't make me say it twice.",
				dramatic = "{b}. I've been a fool. I'm sorry. Let's end this.",
				polite = "{b}, I'm sorry. I'd very much like us to be friends again.",
				_ = "{b}. I'm sorry. Can we stop this now?",
			}, "sad")
			if ctx.rng:chance(0.5 + K.trait(ctx, b, "kind") * 0.4) then
				c:by("b", {
					proud = "...Fine. I'm sorry too. A bit.",
					bold = "Yeah. Me too. Done. Come here.",
					shy = "Oh. Me too. I'm sorry too.",
					cool = "Yeah. Me too.",
					gloomy = "I thought you'd never talk to me again. ...Sorry too.",
					_ = "...Yes. I'm sorry too. I missed you.",
				}, "heart")
				c:fx({ t = "makeup", a = "a", b = "b" })
				c:rel(10)
				c:mood("a", 5)
			else
				c:say("b", "Half? Half?", "anger")
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
		s:say("a", "{player}. I want to learn something this week.", "question")
		s:say("a", "Which one?", "question")
		for i = 1, 2 do
			local skill = opts[i]
			s:choice(upper(skill), function(c)
				c:with({ skill = skill, Skill = upper(skill) })
				c:by("a", {
					proud = "{Skill}. I'll be better at it than anyone in town by Sunday.",
					easygoing = "{Skill}. Cool. I'll practise. At some point.",
					bookish = "{Skill}. I'll read up on it tonight.",
					gloomy = "{Skill}. I'll be bad at it. But okay.",
					_ = "{Skill}. Right. Every day this week.",
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
		s:say("a", "{player}. I'm planning a surprise party for {b}.", "idea")
		s:by("a", {
			nervous = "You won't tell them, will you? Promise? Promise promise?",
			cheeky = "You won't tell. Hehe. Will you?",
			_ = "You won't tell them, will you?",
		}, "question")
		s:choice("My lips are sealed", function(c)
			c:say("a", "Good. Act normal. Very normal.", "sparkle")
			c:n("At the party, {b} was so surprised they dropped a whole cake. Worth it.")
			c:prop("balloons", "a")
			c:rel(10)
			c:mood("b", 8)
		end)
		s:choice("Drop a hint", function(c)
			c:n("You told {b} to wear something nice on Friday. No reason.")
			c:say("b", "Is there a surprise party? There's a surprise party.", "sparkle")
			c:say("a", "Who told? Who told, {player}?", "anger")
			c:rel(4)
			c:mood("b", 4)
		end)
		s:log("{a} planned a surprise party for {b}.")
		return s:done()
	end,
})

-- newer ones -----------------------------------------------------------------------------------------

event({
	id = "toomuchbread",
	when = "day",
	weight = W({ base = 0.11, traits = { kind = 0.1 } }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "Too much bread")
		s:by("a", {
			foodie = "{player}. Emergency. I made too much bread.",
			sunny = "{player}. Okay so. I made bread. A lot of bread.",
			gentle = "{player}, sorry to bother you. I've baked far too much bread.",
			dramatic = "{player}. There has been a bread situation.",
			nervous = "{player}? I think I made too much bread. Is eleven loaves too many?",
			gloomy = "I made too much bread. Of course I did.",
			cool = "Made too much bread.",
			_ = "{player}. I made too much bread.",
		}, "sweat")
		s:by("a", {
			foodie = "Eleven loaves. The dough kept rising and so did my hopes.",
			bookish = "I doubled the recipe. Then I doubled it again by mistake. That's four times. I checked.",
			_ = "Eleven loaves. The kitchen's full. What do I do?",
		}, "question")
		s:choice("Share it round the street", function(c)
			c:by("a", {
				sunny = "Yes. I'll knock on every door.",
				shy = "Every door? Um. Okay. I'll leave them on the steps.",
				polite = "What a kind idea. One for every house.",
				prickly = "Fine. If anyone asks, it was a mistake.",
				_ = "Good idea. I'll do the rounds.",
			}, "sparkle", "cheer")
			c:n("By teatime there was a loaf on every doorstep in the street.")
			c:all(2)
			c:mood("a", 4)
			c:memo("a", "I gave bread to the whole street. People keep waving at me now.")
		end)
		s:choice("Toast for everyone tomorrow", function(c)
			c:by("a", {
				foodie = "A toast morning. Oh, you're good, {player}.",
				easygoing = "Toast tomorrow. Less work today. I like it.",
				_ = "A toast morning. Yes. Bring butter.",
			}, "heart")
			c:mood("a", 3)
			c:memo("a", "Tomorrow is toast morning. You're invited, {player}.")
		end)
		s:choice("Freeze the rest", function(c)
			c:by("a", {
				nervous = "Will it be okay frozen? It'll be okay. Okay.",
				gloomy = "Freezer. It'll get forgotten. But okay.",
				_ = "Freezer. Sensible. Boring, but sensible.",
			}, "sweat")
			c:mood("a", 1)
		end)
		s:log("{a} made too much bread.")
		return s:done()
	end,
})

event({
	id = "shellfind",
	when = "day",
	weight = W({ base = 0.11, weather = { "clear", "cloudy", "blossom", "leaves" } }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "A shell")
		s:prop("box", "a")
		s:by("a", {
			sunny = "{player}. Look. Look what I found.",
			dreamy = "{player}... I found a shell. It sounds like the sea. Well. It is from the sea.",
			bookish = "{player}, look. A spiral shell. It turns to the right. Most do, actually.",
			cool = "Found a shell.",
			shy = "Um, {player}? I found this. On the beach.",
			dramatic = "{player}. Look. The sea has given me a gift.",
			_ = "{player}, look. Found it on the beach.",
		}, "sparkle")
		s:say("a", "Not a chip on it. What do I do with it?", "question")
		s:choice("Keep it on your windowsill", function(c)
			c:by("a", {
				dreamy = "On the windowsill. Then it can still see the sea.",
				foodie = "Windowsill. Next to my jam jar. They'll be friends.",
				_ = "Windowsill. Yes. Where the light hits it.",
			}, "heart")
			c:mood("a", 4)
			c:memo("a", "My shell is on the windowsill. Come and look at it, {player}.")
		end)
		s:choice("Give it to a friend", function(c)
			c:by("a", {
				shy = "A friend? Um. I'll give it to someone. Tomorrow. Maybe.",
				sunny = "Ooh. I know exactly who.",
				prickly = "Fine. Somebody gets a shell. They'd better like it.",
				_ = "I know who'd like it.",
			}, "heart")
			c:all(1)
			c:mood("a", 2)
		end)
		s:choice("Put it back on the beach", function(c)
			c:by("a", {
				gloomy = "Back it goes. Nothing good stays. ...That's fine.",
				bookish = "Good thinking. Something might live in it next.",
				easygoing = "Back it goes. It was happy there.",
				_ = "Back it goes. Someone else can find it.",
			}, "sweat")
			c:mood("a", 1)
		end)
		s:log("{a} found a perfect shell.")
		return s:done()
	end,
})

event({
	id = "doorpaint",
	when = "day",
	weight = W({ base = 0.11 }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "A new colour")
		s:by("a", {
			sunny = "{player}. Help. I'm painting my front door and I can't pick.",
			proud = "{player}. I'm painting my door. It needs to say me.",
			nervous = "{player}, I'm painting my door. What if I pick a bad colour and have to look at it every day?",
			bookish = "{player}, I've got the door colours down to three. Took me a week.",
			gloomy = "Painting my door. It'll peel. Still. Which colour?",
			dramatic = "{player}. My door needs a new look. A whole new era.",
			_ = "{player}, I'm painting my front door. Which colour?",
		}, "question")
		s:choice("Sage green", function(c)
			c:by("a", {
				gentle = "Sage. Soft. Calm. Yes.",
				cool = "Green. Fine.",
				_ = "Sage green. Oh, that's nice.",
			}, "heart")
			c:mood("a", 4)
			c:memo("a", "My door's sage green now. It looks like a leaf. A smart leaf.")
		end)
		s:choice("Butter yellow", function(c)
			c:by("a", {
				sunny = "Yellow. Of course. Why didn't I think of that?",
				gloomy = "Yellow. Bright. Hm. ...I'll get used to it.",
				foodie = "Butter yellow. I'll be hungry every time I come home.",
				_ = "Butter yellow. Cheerful. I like it.",
			}, "sparkle", "cheer")
			c:mood("a", 4)
			c:memo("a", "My door's butter yellow now. People smile at it.")
		end)
		s:choice("Sky blue", function(c)
			c:by("a", {
				dreamy = "Sky blue. A bit of sky at home...",
				proud = "Sky blue. Classic. Like me.",
				nervous = "Blue. Okay. Blue's safe. Blue's good.",
				_ = "Sky blue. Done. Thanks, {player}.",
			}, "heart")
			c:mood("a", 4)
			c:memo("a", "My door's sky blue now. You can't miss it.")
		end)
		s:log("{a} asked what colour to paint their door.")
		return s:done()
	end,
})

event({
	id = "pierwalk",
	cutscene = "pier",
	when = "night",
	weight = W({ base = 0.12, weather = { "clear", "cloudy", "snow", "blossom", "leaves" } }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "The pier")
		s:by("a", {
			shy = "Um. {player}? Would you walk to the pier with me? I don't like it on my own in the dark.",
			sunny = "{player}. Pier walk? The stars are out. Come on.",
			gloomy = "Going to the pier. It's cold. You could come. If you want.",
			dreamy = "The pier's lovely at night... the water goes all silver. Come?",
			nervous = "Would you come to the pier with me? It creaks. A lot.",
			cool = "Pier. Want to come?",
			prickly = "I'm going to the pier. You can come. Or not. Whatever.",
			polite = "Would you care to walk to the pier with me, {player}? Only if you've time.",
			_ = "{player}, walk to the pier with me?",
		}, "question")
		s:choice("Sure, let's go", function(c)
			c:n("You walked to the end of the pier together and listened to the water.")
			c:by("a", {
				shy = "Thanks for coming. It's nicer with two.",
				prickly = "...This was nice. Don't tell anyone I said that.",
				gloomy = "That was... actually good. Huh.",
				dramatic = "I'll remember this night all week.",
				cool = "Good walk.",
				_ = "Thanks, {player}. Same time next week?",
			}, "heart")
			c:hearts("a", 1)
			c:mood("a", 5)
			c:memo("a", "{player} walked to the pier with me. The water was all silver.")
		end)
		s:choice("Not tonight", function(c)
			c:by("a", {
				shy = "Oh. Okay. That's okay.",
				prickly = "Fine. Didn't want company anyway.",
				nervous = "That's fine. Totally fine. I'll go fast.",
				sunny = "Aw. Next time, then. Promise?",
				_ = "Okay. Next time.",
			}, "sad")
			c:mood("a", -1)
		end)
		s:default(2)
		s:log("{a} asked you to walk to the pier with them.")
		return s:done()
	end,
})

event({
	id = "showoff",
	when = "day",
	weight = W({ base = 0.1, traits = { focus = 0.2 } }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "Look what I made")
		s:by("a", {
			proud = "{player}. Come here. You need to see this.",
			sunny = "{player}. I finished it. Come and see. Come on.",
			shy = "Um, {player}? I made something. You can say if it's bad.",
			dramatic = "{player}. Behold. My finest work.",
			nervous = "{player}, can you look at something? Be honest. Not too honest.",
			bookish = "{player}, I built a stool. From a proper plan. Every step.",
			cool = "Made a thing. Look.",
			_ = "{player}, look. I made a stool.",
		}, "sparkle")
		s:by("a", {
			proud = "Three legs. Perfectly level. Sit on it. Go on.",
			bookish = "It's level. I checked with a marble.",
			nervous = "It wobbles a bit. Is that bad? It's a bit bad.",
			foodie = "It's for the kitchen. For sitting while things bake.",
			_ = "It only wobbles a bit.",
		}, "question")
		s:choice("It's lovely", function(c)
			c:by("a", {
				gloomy = "Really? Huh. Okay. I'll keep it.",
				prickly = "I know. ...Thanks.",
				shy = "Really? Oh. I'm going to go red now.",
				_ = "Really? I'm putting it by the window.",
			}, "heart")
			c:hearts("a", 1)
			c:mood("a", 5)
		end)
		s:choice("It wobbles a bit", function(c)
			c:by("a", {
				proud = "It does not. ...Where?",
				nervous = "I knew it. I knew it. I'll fix it tonight.",
				cool = "Hm. I'll fix it.",
				cheeky = "That's a feature. It rocks you to sleep.",
				gloomy = "Course it does.",
				_ = "Oh. Yes. A bit of card under that leg.",
			}, "sweat")
			c:xp("a", 8)
			c:memo("a", "My stool doesn't wobble any more. {player} spotted it.")
		end)
		s:log("{a} showed you a stool they made.")
		return s:done()
	end,
})

event({
	id = "noisyneighbour",
	actors = 2,
	when = "any",
	weight = W({ base = 0.1, rel = -40, relMax = 40 }),
	scene = function(ctx, a, b)
		local s = K.scene(ctx, "Next door")
		s:by("a", {
			nervous = "{player}, can I ask you something? It's about {b}. Not a big thing. A medium thing.",
			polite = "{player}, I'm sorry to bring this to you. It's about {b}.",
			prickly = "{player}. It's {b}. Again.",
			gloomy = "{player}. {b}'s music. All night. Every night.",
			easygoing = "Hey {player}. {b}'s been playing music late. I don't mind. Mostly.",
			_ = "{player}. {b} plays music really late. I can't sleep.",
		}, "sweat")
		s:say("a", "What do I do?", "question")
		s:choice("Knock and ask nicely", function(c)
			c:by("a", {
				shy = "Knock? Me? Okay. I'll knock very quietly.",
				bold = "Right. Knocking now.",
				prickly = "Fine. Nicely. I'll try.",
				_ = "Okay. I'll ask nicely.",
			}, "sweat")
			c:by("b", {
				cheeky = "Too loud? Hehe. Sorry. I'll put the quiet one on.",
				proud = "Loud? It's good music. ...But fine. Quieter.",
				gloomy = "Sorry. I didn't think anyone could hear. Nobody ever says.",
				polite = "Oh, I'm so sorry. I'll keep it down. Thank you for telling me.",
				dramatic = "My music kept you up? I'm mortified. It stops at nine from now on.",
				nervous = "Oh no. Was it loud? Every night? I'm so sorry.",
				_ = "Oh. Sorry. I'll turn it down.",
			}, "heart")
			c:rel(6)
			c:mood("a", 4)
		end)
		s:choice("Pillow over your head", function(c)
			c:by("a", {
				gloomy = "Pillow over the head. Story of my life.",
				easygoing = "Pillow. Easy. Done.",
				_ = "A pillow. Fine. I'll try it.",
			}, "sad")
			c:mood("a", -1)
		end)
		s:choice("Ask {b} for a song you like", function(c)
			c:say("a", "Join in, you mean? Huh. Okay.", "idea")
			c:n("That night {a} knocked on {b}'s door with a request.")
			c:voice("b", "excited", "music", "cheer")
			c:rel(4)
			c:mood("a", 2)
			c:mood("b", 3)
		end)
		s:log("{a} asked what to do about {b}'s late music.")
		return s:done()
	end,
})

event({
	id = "islelights",
	when = "day",
	weight = W({ base = 0.1, traits = { focus = -0.1 } }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "Something odd")
		s:by("a", {
			nervous = "{player}. Last night. Lights on the islet. Three of them. Moving.",
			dramatic = "{player}. I saw something last night I cannot explain.",
			bookish = "{player}, I saw lights on the islet last night. I wrote down the times. Look.",
			gloomy = "Saw lights on the islet last night. Probably nothing. Probably.",
			dreamy = "{player}... there were little lights on the islet last night. Dancing, sort of.",
			cool = "Lights on the islet last night. Odd.",
			cheeky = "{player}. Lights. On the islet. Last night. Spooky.",
			_ = "{player}, I saw lights on the islet last night.",
		}, "question")
		s:say("a", "There's nobody out there. Is there?", "question")
		s:choice("Probably fishing boats", function(c)
			c:by("a", {
				nervous = "Boats. Yes. Boats are normal. Phew.",
				dramatic = "Boats. Of course. How dull. What a relief.",
				bookish = "Boats would explain the moving. Good thinking.",
				gloomy = "Boats. Boring answer. Probably right.",
				_ = "Boats. Oh. That makes sense.",
			}, "sweat")
			c:mood("a", 2)
		end)
		s:choice("Let's watch for them tonight", function(c)
			c:by("a", {
				bold = "Yes. I'll bring a torch.",
				nervous = "Tonight? Together? Okay. If it's together.",
				cheeky = "A stakeout. I'll bring snacks.",
				_ = "Tonight, then. Meet me by the harbour.",
			}, "sparkle")
			c:n("That night you watched from the harbour wall. Three small lights bobbed across the islet, then went out.")
			c:by("a", {
				gloomy = "Told you. Nobody ever believes me.",
				dramatic = "We're witnesses now, {player}.",
				_ = "...See? I told you.",
			}, "sparkle")
			c:hearts("a", 1)
			c:mood("a", 4)
			c:memo("a", "{player} saw the islet lights too. We're keeping watch.")
		end)
		s:choice("Write it down", function(c)
			c:by("a", {
				bookish = "Already have. Page four.",
				_ = "Good idea. I'll keep a notebook.",
			}, "idea")
			c:mood("a", 1)
			c:memo("a", "I'm keeping a notebook about the islet lights. Three sightings so far.")
		end)
		s:log("{a} saw lights on the islet.")
		return s:done()
	end,
})

event({
	id = "marketnerves",
	when = "any",
	weight = W({ base = 0.12, job = "any" }),
	scene = function(ctx, a)
		local w = ctx.job(a)
		local s = K.scene(ctx, "Tomorrow"):with({ job = if w then w.def.name:lower() else "work" })
		s:by("a", {
			nervous = "{player}... big day at the {job} tomorrow. What if nobody comes? What if everybody comes?",
			gloomy = "Big day at the {job} tomorrow. It'll go wrong. Things do.",
			proud = "I'm running the {job} on my own tomorrow. Not nervous. Well. A bit.",
			sunny = "{player}. Big day at the {job} tomorrow. I'm excited. And a bit sick.",
			polite = "{player}, may I ask your advice? It's a big day at the {job} tomorrow.",
			shy = "Um. Tomorrow at the {job}... there'll be so many people.",
			_ = "Big day at the {job} tomorrow. I'm nervous.",
		}, "sweat")
		s:choice("You'll be great", function(c)
			c:by("a", {
				gloomy = "You think so? ...Okay. I'll try thinking so too.",
				nervous = "Really? You mean it? Okay. I'll be great.",
				prickly = "Obviously. ...Thanks, though.",
				_ = "Thanks, {player}. I needed that.",
			}, "heart")
			c:mood("a", 6)
		end)
		s:choice("Get an early night", function(c)
			c:by("a", {
				easygoing = "An early night. My favourite kind of advice.",
				nervous = "Early night. Yes. And two alarms.",
				_ = "Early night. Good plan.",
			}, "zzz")
			c:mood("a", 3)
			c:xp("a", 6)
		end)
		s:choice("Practise on me now", function(c)
			c:n("{a} ran through the whole day out loud. You played the customers.")
			c:by("a", {
				cheeky = "You were a terrible customer. Perfect practice.",
				bookish = "That helped. I found two things to fix.",
				_ = "Okay. I think I've got it.",
			}, "sparkle")
			c:xp("a", 10)
			c:mood("a", 4)
		end)
		s:log("{a} was nervous about a big day at work.")
		return s:done()
	end,
})

event({
	id = "soupsalt",
	cutscene = "kitchen",
	when = "day",
	weight = W({ base = 0.1 }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "Taste this")
		s:by("a", {
			foodie = "{player}. Taste. Now. Before it goes cold.",
			sunny = "{player}. Try my soup? Tell me the truth. The nice truth.",
			nervous = "Could you taste this? I can't tell any more. I've tasted it forty times.",
			proud = "Try my soup. You'll be the second person to call it perfect. I was the first.",
			bookish = "I followed the recipe exactly. But something's missing. Could you try?",
			gloomy = "Made soup. Probably needs something. Everything does.",
			_ = "{player}, taste my soup? Does it need salt?",
		}, "question")
		s:choice("A pinch of salt", function(c)
			c:by("a", {
				foodie = "A pinch. You've got the tongue for this, {player}.",
				gloomy = "Salt. Yeah. ...That's better. Annoyingly.",
				_ = "Salt. Just a pinch. ...Oh. Oh, that's it.",
			}, "sparkle")
			c:mood("a", 4)
			c:xp("a", 5)
		end)
		s:choice("It's perfect as it is", function(c)
			c:by("a", {
				proud = "I know. I just wanted to hear it.",
				nervous = "Really? You'd say if it wasn't? Okay. Okay.",
				_ = "Really? Oh good. I'll stop fiddling.",
			}, "heart")
			c:mood("a", 5)
		end)
		s:choice("More pepper", function(c)
			c:by("a", {
				foodie = "Pepper. Bold call. ...I respect it.",
				_ = "Pepper. Okay. Oh. That's got a kick.",
			}, "sweat")
			c:mood("a", 2)
		end)
		s:log("{a} asked you to taste their soup.")
		return s:done()
	end,
})

event({
	id = "lettergran",
	when = "any",
	weight = W({ base = 0.1 }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "A letter to Gran")
		s:prop("parcels", "a")
		s:by("a", {
			bookish = "I'm writing to my gran. Four pages so far. Is that too long?",
			gloomy = "Writing to my gran. Nothing ever happens here worth writing.",
			dramatic = "I'm writing to my gran. It's going to be a letter for the ages.",
			cool = "Writing to my gran. Stuck.",
			shy = "Um... I'm writing to my gran. What do people write?",
			polite = "I'm writing to my gran, {player}. Would you help me with what to say?",
			_ = "{player}, I'm writing to my gran. I don't know what to put.",
		}, "question")
		s:choice("Tell her about the town", function(c)
			c:by("a", {
				gloomy = "The town. Okay. ...There is a lot, actually. The gulls. The fountain. You.",
				sunny = "The town. Okay. Where do I even start. The bakery.",
				_ = "The town. Yes. She'd like that.",
			}, "idea")
			c:mood("a", 4)
			c:memo("a", "I told my gran all about the town. She wants to know who {player} is.")
		end)
		s:choice("Keep it short and sweet", function(c)
			c:by("a", {
				bookish = "Short. Four pages down to one. That hurts.",
				_ = "Short. 'Dear Gran, all well, lots of love.' Done.",
			}, "sweat")
			c:mood("a", 2)
		end)
		s:log("{a} wrote a letter to their gran.")
		return s:done()
	end,
})

event({
	id = "droopyplant",
	when = "day",
	weight = W({ base = 0.1 }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "A sad plant")
		s:by("a", {
			gentle = "{player}... my plant's drooping. I don't know what it needs.",
			nervous = "{player}, my plant's drooping. Is it dying? Is it my fault?",
			gloomy = "My plant's drooping. Everything I touch.",
			dramatic = "{player}. My fern. It's wilting. I can't watch.",
			bookish = "My plant's drooping. I've ruled out three things. There are seven left.",
			_ = "{player}, my plant's gone all droopy.",
		}, "sad")
		-- one of the two fixes works, this time
		local works = ctx.rng:pick({ 1, 2 })
		local function after(c, ok)
			if ok then
				c:n("By the next morning it was standing up straight again.")
				c:by("a", {
					gloomy = "It's alive. Huh. Something went right.",
					dramatic = "It lives. You saved it, {player}.",
					_ = "Look. It's perked right up. Thanks, {player}.",
				}, "sparkle", "cheer")
				c:mood("a", 5)
				c:memo("a", "My plant's doing really well now. {player} knew what it needed.")
			else
				c:n("By the next morning it was drooping a little more.")
				c:by("a", {
					nervous = "Worse. It's worse. Okay. Try the other thing?",
					_ = "Hm. Not that, then.",
				}, "sweat")
				c:mood("a", -1)
			end
		end
		s:choice("More water", function(c)
			c:by("a", {
				nervous = "Not too much? How much is too much? Okay. A cup.",
				_ = "Water. Okay. Big drink for you.",
			}, "idea")
			after(c, works == 1)
		end)
		s:choice("Move it into the sun", function(c)
			c:by("a", {
				dreamy = "The sun. Yes... it's been in the corner, poor thing.",
				_ = "Into the sun. Windowsill it is.",
			}, "idea")
			after(c, works == 2)
		end)
		s:choice("Talk to it", function(c)
			c:by("a", {
				dreamy = "I'll tell it about my day... it'll like that.",
				cool = "Talk to it. Fine.",
				prickly = "I'm not talking to a plant. ...What do I say?",
				_ = "Talk to it? Okay. Hello, plant.",
			}, "heart")
			c:mood("a", 3)
		end)
		s:log("{a}'s plant was drooping.")
		return s:done()
	end,
})

event({
	id = "rainyday",
	when = "day",
	weight = W({ base = 0.3, weather = { "rain", "storm" } }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "A rainy day")
		s:by("a", {
			sunny = "{player}. It's raining. I'm going spare. What do I do?",
			easygoing = "Rain. Great excuse to do nothing. Or something. You pick.",
			bold = "Rain. Can't go out. I'm climbing the walls.",
			dreamy = "It's raining... I could do anything. That's the trouble.",
			gloomy = "Rain. Course it is. What do people do on days like this?",
			nervous = "It's raining. What if it doesn't stop? What do I do all day?",
			_ = "{player}, it's raining. What do I do all day?",
		}, "question")
		s:choice("Bake something", function(c)
			c:by("a", {
				foodie = "Yes. Yes. The big cake.",
				_ = "Bake. Oh, the house will smell lovely.",
			}, "heart")
			c:mood("a", 4)
		end)
		s:choice("Read by the window", function(c)
			c:by("a", {
				bookish = "I've got three on the go. I'll finish one. Maybe two.",
				bold = "Read? Sit still? ...Okay. One chapter.",
				_ = "By the window. With a blanket. Yes.",
			}, "heart")
			c:mood("a", 4)
		end)
		s:choice("Jump in puddles", function(c)
			c:by("a", {
				sunny = "Wellies on.",
				shy = "Puddles? Like a kid? ...Okay. Just a small one.",
				gloomy = "I'll get soaked. ...Okay. Yes. Let's.",
				prickly = "That's ridiculous. Where are my wellies.",
				_ = "Puddles. Yes. Wellies on.",
			}, "sparkle", "cheer")
			c:mood("a", 6)
		end)
		s:log("{a} asked what to do on a rainy day.")
		return s:done()
	end,
})

event({
	id = "cantsleep",
	when = "night",
	weight = W({ base = 0.12 }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "Still awake")
		s:by("a", {
			nervous = "{player}? Sorry. Are you awake? I can't sleep.",
			dreamy = "{player}... are you up? The moon's too bright.",
			gloomy = "Can't sleep. Again.",
			cool = "You up?",
			sunny = "{player}. You're up too? I can't sleep. My brain won't stop.",
			_ = "{player}? You awake?",
		}, "zzz")
		s:by("a", {
			nervous = "I keep thinking about tomorrow. And the day after.",
			foodie = "I think it's the cheese I had. It was a lot of cheese.",
			dramatic = "My thoughts won't be quiet. They're having a party.",
			bookish = "I started counting sheep. Then I wondered how many sheep there are. In the world.",
			_ = "My head won't switch off.",
		}, "question")
		s:choice("Count the boats in the harbour", function(c)
			c:say("a", "One... two... three... the little red one... four...", "zzz")
			c:n("{a} was asleep before ten.")
			c:mood("a", 4)
		end)
		s:choice("Warm milk", function(c)
			c:by("a", {
				foodie = "Warm milk. With honey. Now we're talking.",
				_ = "Warm milk. Okay. Like when I was little.",
			}, "heart")
			c:mood("a", 3)
		end)
		s:choice("Tell me what's on your mind", function(c)
			c:by("a", {
				nervous = "Okay. So. First thing...",
				gloomy = "You don't want to hear it. ...Okay. Well.",
				prickly = "Nothing. ...Fine. Everything.",
				_ = "Okay. Thanks, {player}.",
			}, "heart")
			c:n("They talked until the sky went grey. {a} slept until noon.")
			c:hearts("a", 1)
			c:mood("a", 5)
		end)
		s:log("{a} couldn't sleep.")
		return s:done()
	end,
})

event({
	id = "forgotname",
	actors = 2,
	when = "day",
	weight = W({ base = 0.1, rel = -20, relMax = 20 }),
	scene = function(ctx, a, b)
		local s = K.scene(ctx, "What's their name")
		s:n("{b} is walking over to say hello.")
		s:by("a", {
			nervous = "{player}. Help. That one coming over. I've forgotten their name. I've known them weeks.",
			shy = "Um. {player}. The one coming over... what's their name? Don't look.",
			proud = "{player}. Quickly. That one. Their name. I know it. I just need you to say it.",
			gloomy = "I've forgotten their name. Again. And they're coming over.",
			cool = "{player}. Name. Quick.",
			_ = "{player}. Who's that coming over? I've forgotten their name.",
		}, "sweat")
		s:choice("Whisper it to them", function(c)
			c:n("You whispered it.")
			c:say("a", "{b}. Hi. Hello, {b}. How are you, {b}?", "sparkle")
			c:by("b", {
				cheeky = "Why do you keep saying my name?",
				cool = "...Hi.",
				_ = "Hi. You're very... keen today.",
			}, "question")
			c:rel(3)
		end)
		s:choice("Just ask them", function(c)
			c:say("a", "Sorry. This is awful. What's your name again?", "sweat")
			c:by("b", {
				gentle = "It's {b}. Don't worry. I forget mine sometimes.",
				proud = "It's {b}. I'll try not to be hurt.",
				prickly = "It's {b}. Write it down this time.",
				gloomy = "{b}. Nobody remembers. It's fine.",
				sunny = "{b}. Ha. That's okay. What's yours again? Kidding.",
				_ = "It's {b}. Don't worry about it.",
			}, "heart")
			c:rel(6)
		end)
		s:log("{a} forgot {b}'s name.")
		return s:done()
	end,
})

event({
	id = "secretspot",
	when = "day",
	weight = W({ base = 0.1, weather = { "clear", "cloudy", "blossom", "leaves", "snow" } }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "A secret spot")
		s:by("a", {
			dreamy = "{player}... can I show you something? A place. Nobody else knows.",
			cheeky = "{player}. Want to see my secret spot? Pinky promise you won't tell.",
			shy = "Um, {player}? There's a place I go. I could show you. If you want.",
			cool = "Got a spot I like. Want to see?",
			bookish = "I found a hollow up on the hill. You can see the whole bay from it. Want to see?",
			_ = "{player}, want to see my secret spot?",
		}, "idea")
		s:choice("Show me", function(c)
			c:n("{a} led you up a path behind the hill to a flat rock looking out over the whole town.")
			c:by("a", {
				dreamy = "This is where I come to think. Or not think.",
				cheeky = "Tell no one. Not even the gulls.",
				shy = "I've never shown anyone. You're the first.",
				gloomy = "It's the one place nothing goes wrong.",
				_ = "You can come here too. It's ours now.",
			}, "heart")
			c:hearts("a", 1)
			c:mood("a", 5)
			c:memo("a", "I showed {player} my secret spot. It's our spot now.")
		end)
		s:choice("Another day", function(c)
			c:by("a", {
				shy = "Okay. It'll still be there.",
				cheeky = "Your loss. It's very secret.",
				_ = "Another day. Don't forget.",
			}, "sad")
			c:mood("a", -1)
		end)
		s:default(2)
		s:log("{a} wanted to show you their secret spot.")
		return s:done()
	end,
})

event({
	id = "sillyhat",
	actors = 2,
	when = "day",
	weight = W({ base = 0.1, rel = 0, btraits = { mischief = 0.2 } }),
	scene = function(ctx, a, b)
		local s = K.scene(ctx, "A silly hat")
		s:n("{a} lost a bet to {b} and has to wear a very silly hat all day.")
		s:by("a", {
			proud = "{player}. Don't look at me. ...Do I look ridiculous? Be quick.",
			gloomy = "Go on. Laugh. Everyone else has.",
			dramatic = "{player}. Witness my shame.",
			prickly = "Not a word. ...Okay. One word. How bad?",
			nervous = "Is it bad? It's bad. Is everyone looking?",
			sunny = "{player}. Look at my hat. It has a feather. And a bell.",
			cool = "Hat. Bet. Don't ask.",
			_ = "{player}. Be honest. How silly is this hat?",
		}, "sweat")
		s:choice("It suits you", function(c)
			c:by("a", {
				proud = "It does, doesn't it? I might keep it.",
				gloomy = "You're just saying that. ...Am I keeping it?",
				_ = "Really? Huh. Maybe it's not so bad.",
			}, "sparkle")
			c:say("b", "That was meant to be a punishment.", "sweat")
			c:mood("a", 5)
		end)
		s:choice("It's very silly", function(c)
			c:by("a", {
				prickly = "I know. I know.",
				_ = "I know. I know it is.",
			}, "sad")
			c:voice("b", "laugh", "music", "laugh")
			c:rel(2)
			c:mood("a", -1)
			c:mood("b", 3)
		end)
		s:log("{a} wore a silly hat after losing a bet to {b}.")
		return s:done()
	end,
})

event({
	id = "practiseask",
	actors = 2,
	when = "day",
	weight = W({ base = 0.1, rel = -10, traits = { brave = -0.2 } }),
	scene = function(ctx, a, b)
		local s = K.scene(ctx, "Practising")
		s:by("a", {
			nervous = "{player}, can I practise on you? I want to ask {b} to join my quiz team and I keep getting it wrong.",
			shy = "Um, {player}... can I practise on you? I want to ask {b} something. Quiz team. It's nothing.",
			proud = "{player}. I'm asking {b} to join my quiz team. I've prepared a speech.",
			bookish = "{player}, I'm asking {b} to join our quiz team. I've written out three ways to ask.",
			_ = "{player}, can I practise asking {b} to join my quiz team?",
		}, "sweat")
		local keen = ctx.rel(a, b) >= 0
		s:choice("Just go and ask", function(c)
			c:by("a", {
				nervous = "Just go? Now? Okay. Okay okay okay.",
				shy = "Now? ...Okay. Before I lose my nerve.",
				_ = "Right. Going now.",
			}, "sweat")
			if keen then
				c:by("b", {
					cool = "Sure. When?",
					bookish = "Yes. I know all the capitals. Most of them.",
					foodie = "Is there food at the quiz? Then yes.",
					dramatic = "I thought you'd never ask. Yes.",
					gloomy = "Me? Okay. I'll get them all wrong. But okay.",
					_ = "Yes. Course I will.",
				}, "heart")
				c:rel(8)
			else
				c:by("b", {
					prickly = "Quiz? Me? ...Fine. One night.",
					_ = "Hm. I'll think about it.",
				}, "question")
				c:rel(2)
			end
		end)
		s:choice("Practise on me first", function(c)
			c:n("{a} asked you four times. The fourth time was very good.")
			c:by("a", {
				dramatic = "I've never been more ready for anything.",
				_ = "Okay. I'm ready now. I think.",
			}, "sparkle")
			c:voice("b", "yes", "heart")
			c:rel(8)
			c:mood("a", 3)
			c:memo("a", "{b} joined our quiz team. I practised on {player} first.")
		end)
		s:log("{a} wanted to ask {b} to join their quiz team.")
		return s:done()
	end,
})

event({
	id = "weatherbet",
	when = "day",
	weight = W({ base = 0.09, traits = { mischief = 0.2 } }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "A bet on the weather")
		s:by("a", {
			cheeky = "{player}. Bet you it rains tomorrow.",
			bold = "Bet you it's sunny tomorrow. Go on. Bet.",
			bookish = "I've been reading the clouds. Want to bet on tomorrow's weather?",
			gloomy = "It'll rain tomorrow. Bet you it does.",
			_ = "{player}, sun or rain tomorrow? Pick one.",
		}, "idea")
		s:say("a", "Loser sings a song at the fountain.", "music")
		s:choice("Sun", function(c)
			c:by("a", {
				gloomy = "Sun. Brave. We'll see.",
				_ = "Sun? Okay. Warm up your voice.",
			}, "sparkle")
			c:mood("a", 2)
			c:memo("a", "{player} bet me it'd be sunny. Somebody's singing at the fountain.")
		end)
		s:choice("Rain", function(c)
			c:by("a", {
				cheeky = "Rain? That's my pick. ...Fine. We're on the same side. Who sings?",
				_ = "Rain? Okay. Warm up your voice.",
			}, "sparkle")
			c:mood("a", 2)
			c:memo("a", "{player} bet me it'd rain. Somebody's singing at the fountain.")
		end)
		s:log("{a} made a bet with you about the weather.")
		return s:done()
	end,
})

event({
	id = "earlyknock",
	when = "day",
	weight = W({
		base = 0.1,
		cond = function(ctx)
			return ctx.hour >= 15
		end,
	}),
	scene = function(ctx, a)
		local s = K.scene(ctx, "Wake me up")
		s:by("a", {
			easygoing = "{player}. Big favour. Knock on my door at six tomorrow? I want to see the sunrise. Once.",
			dreamy = "I want to see the sunrise from the hill tomorrow... but I'll sleep through it.",
			nervous = "Could you knock on my door at six? I've set three alarms. What if they all fail?",
			bold = "Knock at six. Loud. I want to see the sunrise.",
			gloomy = "I want to see the sunrise. I'll sleep through it. I always do.",
			_ = "{player}, could you knock on my door at six tomorrow? I want to see the sunrise.",
		}, "question")
		s:choice("I'll knock", function(c)
			c:by("a", {
				easygoing = "You're a hero. A very early hero.",
				nervous = "Thank you. Knock twice. No, three times.",
				prickly = "Fine. Good. Thanks.",
				_ = "Thanks, {player}. Knock loud.",
			}, "heart")
			c:hearts("a", 1)
			c:mood("a", 4)
			c:memo("a", "{player} knocked at six and I saw the sunrise. It was pink. Worth it.")
		end)
		s:choice("Leave your curtains open", function(c)
			c:by("a", {
				bookish = "The sun as an alarm. Very old idea. Very good one.",
				_ = "Curtains open. The sun can wake me itself. Clever.",
			}, "idea")
			c:mood("a", 2)
			c:memo("a", "I left my curtains open and the sun woke me up. Mostly.")
		end)
		s:log("{a} asked you to wake them for the sunrise.")
		return s:done()
	end,
})

event({
	id = "walkedpast",
	when = "day",
	weight = W({ base = 0.11, traits = { social = 0.15 } }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "You walked right past")
		s:by("a", {
			sunny = "{player}. You walked right past me. I waved and everything.",
			cheeky = "{player}. I waved at you. You walked straight past. Hehe. I'm hurt.",
			shy = "Um. {player}? I waved earlier. You didn't see. That's okay.",
			prickly = "I waved at you earlier. You walked right past. Whatever.",
			dramatic = "{player}. This morning. I waved. You walked on. I've never felt so small.",
			gloomy = "I waved at you earlier. You didn't see. Nobody sees me.",
			polite = "Good afternoon, {player}. I believe I waved at you earlier. No matter.",
			_ = "{player}, I waved at you this morning. You walked right past.",
		}, "sad", "wave")
		s:choice("Sorry, I was miles away", function(c)
			c:by("a", {
				prickly = "Hmph. Fine. Wave twice next time.",
				gloomy = "...It's okay. Thanks for saying.",
				cheeky = "Sorry accepted. Wave twice next time.",
				_ = "Ha. That's okay. Wave next time.",
			}, "heart")
			c:mood("a", 3)
		end)
		s:choice("I waved back. You missed it", function(c)
			c:by("a", {
				cheeky = "You did not. ...Did you?",
				nervous = "You did? Oh no. Did I not wave back? Now I feel bad.",
				proud = "Nobody waves back without me seeing.",
				_ = "Did you? Then we both missed it.",
			}, "laugh", "laugh")
			c:mood("a", 2)
		end)
		s:log("{a} waved at you and you walked right past.")
		return s:done()
	end,
})

event({
	id = "thanksroom",
	when = "any",
	weight = W({ base = 0.12, bed = true }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "My room")
		s:by("a", {
			sunny = "{player}. Just wanted to say. My room's really nice. I love the window.",
			shy = "Um. {player}. My room. It's nice. Thank you. That's all.",
			cool = "Room's good. Thanks.",
			prickly = "Room's fine. Better than fine. Don't let it go to your head.",
			polite = "{player}, I wanted to thank you properly for my room. It's very comfortable.",
			gloomy = "My room's nice. Weirdly. I keep waiting for something to go wrong.",
			dramatic = "{player}. My room. It's perfect. I cried. A little.",
			foodie = "My room is lovely. Close to the kitchen. That's all I ask.",
			_ = "{player}, my room's really nice. Thanks.",
		}, "heart")
		s:choice("Glad you like it", function(c)
			c:voice("a", "thanks", "heart")
			c:mood("a", 4)
		end)
		s:choice("Anything you'd change?", function(c)
			c:by("a", {
				bookish = "A shelf. A tall one. For books. Many books.",
				foodie = "A little table for snacks. By the bed.",
				dreamy = "A window that looks at the sea. If that's possible.",
				proud = "A mirror. A big one.",
				cool = "A lamp. Maybe.",
				nervous = "Nothing. It's perfect. Well. A nightlight. Just in case.",
				_ = "Maybe a rug. My feet get cold.",
			}, "idea")
			c:mood("a", 2)
			c:memo("a", "I told {player} what I'd like for my room. No rush.")
		end)
		s:log("{a} thanked you for their room.")
		return s:done()
	end,
})

return list
