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
-- And the chats that are only a chat: a message meant for somebody else, the worry the morning
-- after a late chat that they said something odd, a picture they want you to see, an invite for
-- tomorrow, sorry for yesterday, guess what's in my pocket, a long day let out and taken back, a
-- part in their story, a favour, a small win, a question about you, a nag about your sleep, this
-- or that, a roll from the bakery, a walk home in the dark, something left on your step. (One
-- villager's own phone moments, a list sent to the wrong person, a name with no reply, home safe,
-- are in Data/Events/Solo.)
--
-- They come to you the way a friend texts (the user handed over a messaging app's chats; we take
-- how people text, never the lines): they open, in a burst of two to four short messages, the
-- point in the second or third; you get two short answers, often the same move said two ways or
-- one plain and one a joke; they take it in another burst and sign off. Your name is {player}.

local K = require(script.Parent.Kit)
local Chatter = require(script.Parent.Chatter)
local Sayings = require(script.Parent.Parent.Sayings)
local Foods = require(script.Parent.Parent.Foods)

local W = K.W
local burst = Chatter.burst
local say = Chatter.say

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
		burst(s, "a", {
			sunny = "{player}! Emergency.|Yellow hat or stripy scarf?|I've changed four times. You pick.",
			gentle = "{player}, sorry, a quick one.|The yellow hat or the stripy scarf?|I won't keep you.",
			bold = "{player}. Settle this fast.|Yellow hat or stripy scarf.|I'm out the door in five.",
			dreamy = "{player}.|The yellow hat looks like the sun.|The scarf looks like a road. Which?",
			easygoing = "{player}...|yellow hat or stripy scarf?|I'd wear both but apparently that's a lot.",
			proud = "{player}. A small question, but an important one.|The yellow hat or the stripy scarf?|Both suit me. I need the better one.",
			shy = "Um, {player}.|If you've got a second...|The yellow hat, or the stripy scarf?",
			cheeky = "{player}|vote. hat or scarf|the one you don't pick goes on the goat",
			cool = "{player}.|Hat or scarf.",
			prickly = "{player}. Don't laugh.|Yellow hat or stripy scarf.|Pick. Quickly.",
			dramatic = "{player}. My whole afternoon hangs on this.|The yellow hat. Or the stripy scarf.",
			bookish = "{player}, I listed what's good about the hat and the scarf.|It's a tie. Could you break it?",
			gloomy = "{player}.|Yellow hat or stripy scarf.|They both look bad. Pick the less bad one.",
			polite = "Hello, {player}. Forgive the silly question.|Would you choose the yellow hat or the stripy scarf?",
			foodie = "{player}. Yellow hat or stripy scarf?|Whichever hides crumbs better.",
			nervous = "{player}, s-sorry, quick question.|Yellow hat or stripy scarf?|What if I pick wrong and the whole square sees?",
			_ = "{player}, quick. Before I go out.|Yellow hat or stripy scarf?",
		}, "question", "wave")
		s:choice("The yellow hat.", function(c)
			burst(c, "a", {
				shy = "The hat?|Okay.|I'll be brave.",
				proud = "The hat. People will talk.|They should.",
				easygoing = "Hat. Done.|Back to sitting.",
				cool = "Hat. Okay.",
				nervous = "The hat. You're sure?|Okay. The hat.|Thank you.",
				dramatic = "The hat. Bold.|I'll make an entrance.",
				cheeky = "hat it is|sorry, scarf. goat time",
				gloomy = "The hat. It'll blow off.|...Fine. The hat.",
				_ = "The hat it is.|Thanks, {player}.",
			}, "sparkle", "cheer")
			c:mood("a", 4)
		end)
		s:choice("The stripy scarf.", function(c)
			burst(c, "a", {
				bold = "Scarf. Done. Going.",
				dreamy = "The scarf.|Like wearing a hug.",
				gloomy = "Scarf. Good.|It'll be cold anyway.",
				foodie = "Scarf.|It has folds. Folds hold snacks.",
				prickly = "Scarf. Fine.|...Thanks.",
				cheeky = "scarf|the hat goes on the goat then",
				polite = "The scarf. Thank you, {player}.|Have a pleasant day.",
				_ = "The scarf. Good call.|It's cold out.",
			}, "heart")
			c:mood("a", 4)
		end)
		s:choice("Try a whole new look.", function(c)
			burst(c, "a", {
				nervous = "A whole new look?|Now?|Okay. Stay while I pick.",
				prickly = "New. Fine.|You're helping, though.",
				sunny = "A whole new look.|Yes. Help me pick.",
				cool = "Hm. Okay.",
				_ = "Ooh. A whole new look?|Help me pick, {player}.",
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
		burst(s, "a", {
			polite = "{player}, may I ask you something a bit awkward?|{b} keeps cooking for me. It's very kind.|But it isn't good. Should I say?",
			prickly = "{player}. Awkward question.|{b} keeps cooking for me.|It's awful. I've eaten all of it. Should I say?",
			nervous = "{player}, s-sorry, quick question.|{b} keeps cooking for me and it's really bad.|What if they ask if I liked it?",
			foodie = "{player}. Speaking as someone who knows food.|{b} keeps cooking for me.|It's bad. Do I say?",
			gentle = "{player}, I need your advice.|{b} keeps bringing me dinner, which is so kind.|But it's very, very salty. Do I tell them?",
			shy = "Um, {player}.|{b} keeps bringing me dinner.|It's... um. Not good. Should I say something?",
			cheeky = "{player}|{b} keeps cooking for me|it's a crime|do i tell them",
			cool = "{player}.|{b}'s cooking.|Bad. Do I say?",
			_ = "{player}. Awkward question.|{b} keeps cooking for me.|It's really bad. Should I say?",
		}, "sweat")
		s:choice("Tell them, kindly.", function(c)
			say(c, "a", "{b}, I love that you cook for me.|Maybe less salt?|Much less?", "sweat")
			if K.isPers(ctx, b, "proud", "bold", "prickly", "dramatic") then
				burst(c, "b", {
					proud = "Less salt? My cooking is fine.|...How much less?",
					prickly = "Fine. Less salt.|Don't read into it.",
					dramatic = "My cooking. Insulted.|...Show me how much.",
					_ = "What.|...Fine. I'll taste it first next time.",
				}, "anger")
				c:rel(2)
			else
				burst(c, "b", {
					shy = "Oh no.|I've been doing it all wrong.|Thank you for telling me.",
					cheeky = "i knew|i wanted to see how long you'd last",
					gloomy = "I knew it was bad.|Thanks for eating it anyway.",
					polite = "Thank you for being honest.|Would you show me how you'd do it?",
					nervous = "It was bad? All of it?|Oh no.|Help me next time?",
					_ = "Honestly? Thank you.|Help me next time?",
				}, "heart")
				c:rel(8)
			end
		end)
		s:choice("Keep eating it.", function(c)
			burst(c, "a", {
				gloomy = "Fine. I'll eat it.|Heh... it's what I deserve.",
				cheeky = "fine|the gulls are getting fed tonight|kidding. mostly",
				bold = "Fine.|I've eaten worse. Once.",
				_ = "Fine. I'll eat it.|With a big glass of water.",
			}, "sad")
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
		burst(s, "a", {
			nervous = "{player}, I want to get {b} something.|What if I get it wrong?|What would they like?",
			bookish = "{player}, I'm getting {b} a present.|I've got it down to three.|Which one?",
			sunny = "{player}! Help.|Present for {b}. What do they like?",
			shy = "Um, {player}...|I want to give {b} something.|What would they like?",
			cool = "{player}.|Present for {b}. Ideas?",
			_ = "{player}. I want to get {b} something nice.|What would they like?",
		}, "question")
		for _, g in options do
			s:choice(upper(g) .. ".", function(c)
				c:with({ gift = g, Gift = upper(g) })
				c:n("{a} gave {b} {gift}.")
				if g == want then
					c:voice("b", "excited", "heart", "cheer")
					c:rel(14)
					c:mood("b", 8)
				else
					burst(c, "b", {
						proud = "Oh. {Gift}.|How... thoughtful.",
						bold = "{Gift}? Huh.|Okay. Thanks.",
						shy = "Oh. {Gift}.|Thank you. Really.",
						cheeky = "{gift}|is this a prank|it feels like a prank",
						cool = "{Gift}. Thanks.",
						prickly = "{Gift}? Hm.|I'll find a use for it. Don't check.",
						gloomy = "{Gift}. Okay.|Nobody ever knows what to get me.",
						polite = "{Gift}. How kind of you.|Thank you.",
						foodie = "{Gift}. Can you eat it?|No? Okay. Thanks.",
						nervous = "{Gift}? For me?|Oh. I'll look after it.",
						_ = "Oh. {Gift}.|That's... thank you.",
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
		for _, sy in ctx.rng:shuffle(Sayings.list) do
			if sy.id ~= v.saying and #options < 2 then
				table.insert(options, sy)
			end
		end
		local s = K.scene(ctx, "A motto")
		burst(s, "a", {
			dramatic = "{player}.|Everyone has a line. A signature.|I need mine.",
			cool = "{player}.|Everyone's got a thing they say.|Pick mine.",
			nervous = "{player}, everyone has a thing they say.|I don't. What if people noticed?|Pick one for me?",
			sunny = "{player}! I need a catchphrase.|Like everyone else has.|Pick one?",
			gloomy = "{player}.|Everyone has a thing they say.|Mine's just sighing. Pick me a better one.",
			_ = "{player}. I need a thing I say.|Everyone's got one.|Pick mine?",
		}, "question")
		for _, sy in options do
			s:choice(sy.text, function(c)
				c:with({ motto = sy.text })
				burst(c, "a", {
					proud = "'{motto}'|Yes. It suits me. Most things do.",
					shy = "'{motto}'|Um. I'll try it.|Quietly at first.",
					easygoing = "'{motto}'|Yeah. I can say that.",
					cool = "'{motto}'|Fine. Mine now.",
					dramatic = "'{motto}'|That's me. That's exactly me.",
					gloomy = "'{motto}'|Hm. I'll give it a week.",
					_ = "'{motto}'|...Yes. That's so me.",
				}, "sparkle", "cheer")
				c:saying("a", sy.id)
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
			if h.id ~= v.hobby and #options < 2 then
				table.insert(options, h)
			end
		end
		local s = K.scene(ctx, "Something to do")
		burst(s, "a", {
			gloomy = "{player}.|I'm bored.|Bored all the way down.",
			dramatic = "{player}.|I'm so bored I could lie down in the road.",
			easygoing = "{player}.|I'm bored. Not a lot. Just enough.",
			sunny = "{player} {player}.|I'm bored. So bored.",
			cheeky = "{player}|i'm bored|entertain me. or give me a hobby",
			_ = "{player}.|I'm bored of being bored.",
		}, "sad")
		s:say("a", "Give me a hobby. Any hobby.", "question")
		for _, h in options do
			s:choice(upper(h.name) .. ".", function(c)
				c:with({ hobby = h.name, Hobby = upper(h.name) })
				burst(c, "a", {
					bold = "{Hobby}. Right.|Best in town by Friday.",
					easygoing = "{Hobby}?|Sure. Why not.",
					proud = "{Hobby}. Very well.|I'll be good at it, naturally.",
					shy = "{Hobby}?|Um. Okay. I'll try.",
					bookish = "{Hobby}.|I'll get a book on it first.",
					nervous = "{Hobby}? What if I'm bad at it?|...Okay. I'll try.",
					_ = "{Hobby}?|Okay. I'm in.",
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
		burst(s, "a", {
			easygoing = "*yawn*|Day off.|Beach or library? Or bed. Bed's an option.",
			bookish = "Day off.|Library, obviously. But the beach has... sand.|Help?",
			nervous = "Day off today.|What if I pick the beach and it rains?",
			sunny = "Day off! Finally.|Beach or library?",
			cool = "Day off.|Beach or library.",
			_ = "Day off today.|Beach or library? I can't decide.",
		}, "question")
		s:say("a", "You pick, {player}.", "question")
		s:choice("The beach.", function(c)
			say(c, "a", "Beach it is.|I'll take a towel and see how long I last.", "sparkle", "cheer")
			c:mood("a", 5)
			c:memo("a", "I went to the beach because you said so, {player}. Good call.")
		end)
		s:choice("The library.", function(c)
			say(c, "a", "Library, then.|There's a big chair by the window I like.", "heart")
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
		burst(s, "a", {
			shy = "Um, {player}.|There's a dance at the hall on Friday.|I don't want to go on my own...",
			bold = "{player}. Dance at the hall, Friday.|I'm going. I'm not going alone.",
			dramatic = "{player}. The hall dance is Friday.|I need someone to arrive with. For effect.",
			_ = "There's a dance at the hall on Friday.|I don't want to go on my own.",
		}, "sweat")
		s:say("a", "{player}. {b} or {c}? Who do I ask?", "question")
		s:choice("Ask {b}.", function(ch)
			say(ch, "a", "{b}. Come to the dance with me?|I need someone to stand by the snacks with.", "sweat")
			ch:voice("b", if ctx.rel(a, b) >= 0 then "yes" else "no", "heart")
			ch:relx("a", "b", if ctx.rel(a, b) >= 0 then 10 else -2)
		end)
		s:choice("Ask {c}.", function(ch)
			say(ch, "a", "{c}. Come to the dance with me?|I need someone to stand by the snacks with.", "sweat")
			ch:voice("c", if ctx.rel(a, c) >= 0 then "yes" else "no", "heart")
			ch:relx("a", "c", if ctx.rel(a, c) >= 0 then 10 else -2)
		end)
		s:choice("Go as a group.", function(ch)
			say(ch, "a", "All of us.|Why choose?|The snack table won't know what hit it.", "music")
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
		burst(s, "a", {
			dramatic = "{player}. My new fern needs a name.|A serious fern. It needs a name with weight.",
			gloomy = "{player}.|Got a fern. It looks worried.|Like me. It needs a name.",
			sunny = "{player}! I got a fern!|It needs a name.",
			bookish = "{player}, my fern needs a name.|Ferns are older than trees, you know. It deserves a good one.",
			_ = "{player}. My new plant needs a name.|It's a fern.|Very serious fern.",
		}, "question")
		for i = 1, 2 do
			local name = names[i]
			s:choice(name .. ".", function(c)
				c:with({ plant = name })
				say(c, "a", "{plant}.|Hello, {plant}. Welcome home.", "heart", "cheer")
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
		burst(s, "a", {
			nervous = "I'm thinking of dyeing my hair blue.|What if it goes green?|Should I, {player}?",
			dramatic = "{player}. A new me!|A BLUE me.|Should I?",
			shy = "Um, {player}.|I've been thinking about blue hair.|Is that silly?",
			cheeky = "{player}|blue hair. yes or yes",
			_ = "I'm thinking of dyeing my hair blue.|Bright blue.|Should I, {player}?",
		}, "idea")
		s:choice("Do it.", function(c)
			burst(c, "a", {
				shy = "Okay.|Okay.|Before I lose my nerve.",
				bold = "Yes. Get the dye.",
				prickly = "Fine.|If it's awful I'm blaming you.",
				cheeky = "knew you'd say that",
				_ = "Yes.|Now, before I change my mind.",
			}, "sparkle", "cheer")
			c:fx({ t = "creator", who = "a" })
			c:mood("a", 4)
		end)
		s:choice("Sleep on it.", function(c)
			burst(c, "a", {
				dreamy = "I'll dream about it.|In blue.",
				easygoing = "Sleep on it.|My favourite kind of advice.",
				_ = "Sensible.|I'll dream about being blue.",
			}, "zzz")
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
		burst(s, "a", {
			foodie = "{player}.|I'm cooking for {b} tonight.|This is my moment.",
			nervous = "{player}, I'm cooking for {b} tonight.|I've never cooked for anyone.|What if it's bad?",
			gloomy = "{player}.|Cooking for {b} tonight.|Something will burn. Something always burns.",
			proud = "{player}. I'm cooking for {b} tonight.|It'll be excellent. I just need a dish.",
			_ = "{player}, I'm cooking dinner for {b} tonight.",
		}, "question")
		s:say("a", "What should I make?", "question")
		for _, f in options do
			s:choice(f.name .. ".", function(c)
				c:with({ food = f.name:lower() })
				c:n("{a} made {food}.")
				if fav and f.id == fav.id then
					say(c, "b", "My favourite.|How did you know?", "heart", "cheer")
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
		burst(s, "a", {
			prickly = "{player}.|{b} and I still aren't talking.|Whatever.",
			gloomy = "{player}.|{b} and I still aren't talking.|It's been ages. Feels like ages.",
			nervous = "{player}...|{b} and I still aren't talking.|It's been two days. I've counted.",
			proud = "{player}. {b} and I aren't speaking.|I'm fine about it. Completely fine.",
			sunny = "{player}.|{b} and I aren't talking.|I hate it.",
			_ = "{player}.|{b} and I still aren't talking.",
		}, "sad")
		s:say("a", "Should I say sorry first? It was half their fault.", "sad")
		s:choice("Say it first.", function(c)
			burst(c, "a", {
				proud = "{b}.|I may have been partly wrong.|Can we stop this now?",
				shy = "{b}?|I'm sorry.|I don't like this. Can we stop?",
				bold = "{b}. I'm sorry.|There. Can we stop now?",
				prickly = "{b}. Sorry.|...I mean it. Don't make me say it twice.",
				dramatic = "{b}.|I've been a fool.|Let's end this.",
				polite = "{b}, I'm sorry.|I'd very much like us to be friends again.",
				_ = "{b}. I'm sorry.|Can we stop this now?",
			}, "sad")
			if ctx.rng:chance(0.5 + K.trait(ctx, b, "kind") * 0.4) then
				burst(c, "b", {
					proud = "...Fine.|I'm sorry too. A bit.",
					bold = "Yeah. Me too.|Done. Come here.",
					shy = "Oh.|Me too. I'm sorry too.",
					cool = "Yeah. Me too.",
					gloomy = "I thought you'd never talk to me again.|...Sorry too.",
					_ = "...Yes.|I'm sorry too. I missed you.",
				}, "heart")
				c:fx({ t = "makeup", a = "a", b = "b" })
				c:rel(10)
				c:mood("a", 5)
			else
				say(c, "b", "Half?|Half?", "anger")
				c:rel(-3)
			end
		end)
		s:choice("Give it a day.", function(c)
			burst(c, "a", {
				proud = "One more day.|They might come to me first.",
				shy = "One more day.|I need to work out what to say.",
				_ = "One more day.|Then I'll go.",
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
		burst(s, "a", {
			bold = "{player}. New skill this week.|Pick one. I'll beat it.",
			bookish = "{player}, I want to learn something new this week.|Practical, ideally. Which?",
			easygoing = "{player}.|Thinking of learning something.|Nothing too tiring.",
			_ = "{player}. I want to learn something this week.|Which one?",
		}, "question")
		for i = 1, 2 do
			local skill = opts[i]
			s:choice(upper(skill) .. ".", function(c)
				c:with({ skill = skill, Skill = upper(skill) })
				burst(c, "a", {
					proud = "{Skill}.|Better than anyone in town by Sunday.",
					easygoing = "{Skill}. Cool.|I'll practise. At some point.",
					bookish = "{Skill}.|I'll read up on it tonight.",
					gloomy = "{Skill}. I'll be bad at it.|But okay.",
					_ = "{Skill}. Right.|Every day this week.",
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
		burst(s, "a", {
			nervous = "{player}. I'm planning a surprise party for {b}.|You won't tell them, will you?|Promise?",
			cheeky = "{player}|surprise party for {b}|you didn't hear it from me. you won't tell. right",
			sunny = "{player}! Surprise party for {b}.|Don't tell. Don't tell.",
			_ = "{player}. I'm planning a surprise party for {b}.|You won't tell them, will you?",
		}, "idea")
		s:choice("My lips are sealed.", function(c)
			say(c, "a", "Good.|Act normal.|Very normal.", "sparkle")
			c:n("At the party, {b} was so surprised they dropped a whole cake. Worth it.")
			c:prop("balloons", "a")
			c:rel(10)
			c:mood("b", 8)
		end)
		s:choice("Drop a hint.", function(c)
			c:n("You told {b} to wear something nice on Friday. No reason.")
			say(c, "b", "Is there a surprise party?|There's a surprise party.", "sparkle")
			say(c, "a", "Who told?|Who told, {player}?", "anger")
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
		burst(s, "a", {
			foodie = "{player}.|Emergency!|I made too much bread.",
			sunny = "{player}! Okay so.|I made bread. A lot of bread.",
			gentle = "{player}, sorry to bother you.|I've baked far too much bread.",
			dramatic = "{player}.|There has been a bread situation.",
			nervous = "{player}?|I think I made too much bread.|Is eleven loaves too many?",
			gloomy = "{player}.|I made too much bread.|Of course I did.",
			cool = "{player}.|Made too much bread.",
			_ = "{player}.|I made too much bread.",
		}, "sweat")
		burst(s, "a", {
			foodie = "Eleven loaves.|The dough kept rising and so did my hopes.",
			bookish = "I doubled the recipe, then doubled it again by mistake.|That's four times. I checked.",
			nervous = "Eleven.|The kitchen's full. I can't get to the kettle.",
			_ = "Eleven loaves.|The kitchen's full. What do I do?",
		}, "question")
		s:choice("Share it round the street.", function(c)
			burst(c, "a", {
				sunny = "Yes!|I'll knock on every door.",
				shy = "Every door?|Um. Okay.|I'll leave them on the steps.",
				polite = "What a kind idea.|One for every house.",
				prickly = "Fine.|If anyone asks, it was a mistake.",
				_ = "Good idea.|I'll do the rounds.",
			}, "sparkle", "cheer")
			c:n("By teatime there was a loaf on every doorstep in the street.")
			c:all(2)
			c:mood("a", 4)
			c:memo("a", "I gave bread to the whole street. People keep waving at me now.")
		end)
		s:choice("Toast morning tomorrow.", function(c)
			burst(c, "a", {
				foodie = "A toast morning.|Oh, you're good, {player}.",
				easygoing = "Toast tomorrow.|Less work today. I like it.",
				_ = "A toast morning.|Yes. Bring butter.",
			}, "heart")
			c:mood("a", 3)
			c:memo("a", "Tomorrow is toast morning. You're invited, {player}.")
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
		burst(s, "a", {
			sunny = "{player}. Look.|Look what I found.",
			dreamy = "{player}.|I found a shell.|It sounds like the sea. Well. It is from the sea.",
			bookish = "{player}, look. A spiral shell.|It turns to the right. Most do, actually.",
			cool = "Found a shell.",
			shy = "Um, {player}?|I found this.|On the beach.",
			dramatic = "{player}.|The sea has given me a gift.",
			_ = "{player}, look.|Found it on the beach.",
		}, "sparkle")
		s:say("a", "Not a chip on it. What do I do with it?", "question")
		s:choice("Put it on your windowsill.", function(c)
			burst(c, "a", {
				dreamy = "On the windowsill.|Then it can still see the sea.",
				foodie = "Windowsill. Next to the jam jar.|They'll be friends.",
				_ = "Windowsill. Yes.|Where the light hits it.",
			}, "heart")
			c:mood("a", 4)
			c:memo("a", "My shell is on the windowsill. Come and look at it, {player}.")
		end)
		s:choice("Give it to a friend.", function(c)
			burst(c, "a", {
				shy = "A friend?|Um. I'll give it to someone.|Tomorrow.",
				sunny = "Ooh.|I know exactly who.",
				prickly = "Fine. Somebody gets a shell.|They'd better like it.",
				_ = "I know who'd like it.",
			}, "heart")
			c:all(1)
			c:mood("a", 2)
		end)
		s:log("{a} found a perfect shell.")
		return s:done()
	end,
})

-- front door colours, two of them offered each time
local DOORS = {
	{
		name = "Sage green",
		said = {
			gentle = "Sage.|Soft and calm. Yes.",
			cool = "Green. Fine.",
			_ = "Sage green.|Oh, that's nice.",
		},
		memo = "My door's sage green now. It looks like a leaf. A smart leaf.",
	},
	{
		name = "Butter yellow",
		said = {
			sunny = "Yellow!|Why didn't I think of that?",
			gloomy = "Yellow. Bright.|...I'll get used to it.",
			foodie = "Butter yellow.|I'll be hungry every time I come home.",
			_ = "Butter yellow.|Cheerful. I like it.",
		},
		memo = "My door's butter yellow now. People smile at it.",
	},
	{
		name = "Sky blue",
		said = {
			dreamy = "Sky blue.|A bit of sky at home.",
			proud = "Sky blue. Classic.|Like me.",
			nervous = "Blue. Okay.|Blue's safe. Blue's good.",
			_ = "Sky blue. Done.|Thanks, {player}.",
		},
		memo = "My door's sky blue now. You can't miss it.",
	},
}

event({
	id = "doorpaint",
	when = "day",
	weight = W({ base = 0.11 }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "A new colour")
		burst(s, "a", {
			sunny = "{player}. Help.|I'm painting my front door and I can't pick.",
			proud = "{player}. I'm painting my door.|It needs to say me.",
			nervous = "{player}, I'm painting my door.|What if I pick a bad colour?|I'd have to look at it every day.",
			bookish = "{player}, I've got my door colours down to two.|It took me a week.",
			gloomy = "{player}.|Painting my door. It'll peel.|Still. Which colour?",
			dramatic = "{player}.|My door needs a new look.|A whole new era.",
			cool = "{player}.|Door paint. Pick one.",
			_ = "{player}, I'm painting my front door.|Which colour?",
		}, "question")
		local doors = ctx.rng:shuffle(DOORS)
		for i = 1, 2 do
			local d = doors[i]
			s:choice(d.name .. ".", function(c)
				burst(c, "a", d.said, "heart")
				c:mood("a", 4)
				c:memo("a", d.memo)
			end)
		end
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
		burst(s, "a", {
			shy = "Um. {player}?|Would you walk to the pier with me?|I don't like it on my own in the dark.",
			sunny = "{player}! Pier walk?|The stars are out.",
			gloomy = "{player}.|Going to the pier. It's cold.|You could come. If you want.",
			dreamy = "{player}.|The water at the pier goes silver at night.|Come?",
			nervous = "{player}, would you come to the pier with me?|It creaks. A lot.",
			cool = "{player}.|Pier. Want to come?",
			prickly = "{player}. I'm going to the pier.|You can come. Or not.",
			polite = "Good evening, {player}.|Would you care to walk to the pier with me? Only if you've time.",
			cheeky = "{player}|pier. now. i'll race you",
			_ = "{player}.|Walk to the pier with me?",
		}, "question")
		s:choice("Sure, let's go.", function(c)
			c:n("You walked to the end of the pier together and listened to the water.")
			burst(c, "a", {
				shy = "Thanks for coming.|It's nicer with two.",
				prickly = "...This was nice.|You didn't hear that from me.",
				gloomy = "That was...|actually good.|Huh.",
				dramatic = "I'll remember this night all week.",
				cool = "Good walk.",
				polite = "Thank you, {player}.|Sleep well.",
				_ = "Thanks, {player}.|Same time next week?",
			}, "heart")
			c:hearts("a", 1)
			c:mood("a", 5)
			c:memo("a", "{player} walked to the pier with me. The water was all silver.")
		end)
		s:choice("Not tonight.", function(c)
			burst(c, "a", {
				shy = "Oh. Okay.|That's okay.",
				prickly = "Fine.|Didn't want company anyway.",
				nervous = "That's fine. Totally fine.|I'll walk fast.",
				sunny = "Aw.|Next time, then. Promise?",
				polite = "Of course. Another time.|Sorry to have asked so late.",
				_ = "Okay.|Next time.",
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
		burst(s, "a", {
			proud = "{player}. Come here.|I made a stool.|Three legs. Perfectly level.",
			sunny = "{player}! I finished it.|A stool! My first ever.",
			shy = "Um, {player}?|I made something.|It's a stool. You can say if it's bad.",
			dramatic = "{player}.|Behold!|A stool.",
			nervous = "{player}, can you look at something?|I made a stool.|Be honest. Not too honest.",
			bookish = "{player}, I built a stool.|From a proper plan. Every step.",
			cool = "Made a stool.|Look.",
			cheeky = "{player}|made a stool|sit on it. it's fine. probably",
			_ = "{player}, look.|I made a stool.",
		}, "sparkle")
		burst(s, "a", {
			bookish = "It's level.|I checked with a marble.",
			nervous = "It wobbles a bit.|Is that bad? It's a bit bad.",
			foodie = "It's for the kitchen.|For sitting while things bake.",
			_ = "It only wobbles a bit.",
		}, "question")
		s:choice("It's lovely.", function(c)
			burst(c, "a", {
				gloomy = "Really?|Huh. Okay. I'll keep it.",
				prickly = "I know.|...Thanks.",
				shy = "...!|Really?|Thank you.",
				proud = "Say it again.|Louder.",
				_ = "Really?|It's going by the window.",
			}, "heart")
			c:hearts("a", 1)
			c:mood("a", 5)
		end)
		s:choice("It wobbles a bit.", function(c)
			burst(c, "a", {
				proud = "It does not.|...Where?",
				nervous = "I knew it.|I knew it.|I'll fix it tonight.",
				cool = "Hm. I'll fix it.",
				cheeky = "that's a feature|it rocks you to sleep",
				gloomy = "Course it does.",
				_ = "Oh. Yes.|A bit of card under that leg.",
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
		burst(s, "a", {
			nervous = "{player}, could I ask a thing?|It's about {b}.|Not a big thing. A medium thing.",
			polite = "{player}, I'm sorry to bring this to you.|It's about {b}'s music. It goes on rather late.",
			prickly = "{player}.|It's {b}.|Again.",
			gloomy = "{player}.|{b}'s music.|All night. Every night.",
			easygoing = "Hey {player}.|{b}'s been playing music late.|I don't mind. Mostly.",
			bold = "{player}. {b} plays music till midnight.|I'm going round there.",
			_ = "{player}.|{b} plays music really late.|I can't sleep.",
		}, "sweat")
		s:say("a", "What do I do?", "question")
		s:choice("Knock and ask nicely.", function(c)
			burst(c, "a", {
				shy = "Knock? Me?|Okay.|I'll knock very quietly.",
				bold = "Nicely. Right.|Knocking now.",
				prickly = "Fine. Nicely.|I'll try.",
				_ = "Okay.|I'll ask nicely.",
			}, "sweat")
			burst(c, "b", {
				cheeky = "too loud? hehe|sorry. i'll put the quiet one on",
				proud = "Loud? It's good music.|...Fine. Quieter.",
				gloomy = "Sorry.|I didn't think anyone could hear.",
				polite = "Oh, I'm so sorry.|I'll keep it down. Thank you for telling me.",
				dramatic = "My music kept you up?|I'm mortified. It stops at nine from now on.",
				nervous = "Oh no. Was it loud?|Every night?|I'm so sorry.",
				_ = "Oh. Sorry.|I'll turn it down.",
			}, "heart")
			c:rel(6)
			c:mood("a", 4)
		end)
		s:choice("Ask {b} for a song you like.", function(c)
			say(c, "a", "Join in, you mean?|Huh.|Okay.", "idea")
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
		burst(s, "a", {
			nervous = "{player}.|Last night.|Lights on the islet. Three of them. Moving.",
			dramatic = "{player}.|I saw something last night I cannot explain.|Lights. On the islet.",
			bookish = "{player}, I saw lights on the islet last night.|I wrote down the times. Here.",
			gloomy = "Saw lights on the islet last night.|It's nothing. It's always nothing.",
			dreamy = "{player}.|There were little lights on the islet last night.|Dancing.",
			cool = "Lights on the islet last night.|Odd.",
			cheeky = "{player}|lights. on the islet. last night|spooky",
			_ = "{player}.|I saw lights on the islet last night.",
		}, "question")
		s:say("a", "There's nobody out there. Is there?", "question")
		s:choice("Fishing boats, I bet.", function(c)
			burst(c, "a", {
				nervous = "Boats.|Yes. Boats are normal.|Phew.",
				dramatic = "Boats. Of course.|How dull. What a relief.",
				bookish = "Boats would explain the moving.|Good thinking.",
				gloomy = "Boats.|Boring answer. You're right, though.",
				_ = "Boats. Oh.|That makes sense.",
			}, "sweat")
			c:mood("a", 2)
		end)
		s:choice("Let's watch for them tonight.", function(c)
			burst(c, "a", {
				bold = "Yes!|I'll bring a torch.",
				nervous = "Tonight? Together?|Okay. If it's together.",
				cheeky = "a stakeout|i'll bring snacks",
				_ = "Tonight, then.|Meet me by the harbour.",
			}, "sparkle")
			c:n(
				"That night you watched from the harbour wall. Three small lights bobbed across the islet, then went out."
			)
			burst(c, "a", {
				gloomy = "Told you.|Nobody ever believes me.",
				dramatic = "We're witnesses now, {player}.",
				_ = "...See?|I told you.",
			}, "sparkle")
			c:hearts("a", 1)
			c:mood("a", 4)
			c:memo("a", "{player} saw the islet lights too. We're keeping watch.")
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
		burst(s, "a", {
			nervous = "{player}...|Big day at the {job} tomorrow.|What if nobody comes? What if everybody comes?",
			gloomy = "Big day at the {job} tomorrow.|It'll go wrong.|Things do.",
			proud = "{player}. I'm running the {job} on my own tomorrow.|Not nervous.|Well. A bit.",
			sunny = "{player}. Big day at the {job} tomorrow.|I'm excited. And a bit sick.",
			polite = "{player}, may I ask your advice?|It's a big day at the {job} tomorrow.",
			shy = "Um.|Tomorrow at the {job}...|there'll be so many people.",
			bold = "Big day at the {job} tomorrow.|I'm ready.|Mostly.",
			_ = "Big day at the {job} tomorrow.|I'm nervous.",
		}, "sweat")
		s:choice("You'll be great.", function(c)
			burst(c, "a", {
				gloomy = "You think so?|...Okay. I'll try thinking so too.",
				nervous = "Oh.|Okay.|Thank you.",
				prickly = "Obviously.|...Thanks, though.",
				shy = "...!|Thank you.",
				_ = "Thanks, {player}.|I needed that.",
			}, "heart")
			c:mood("a", 6)
		end)
		s:choice("Practise on me now.", function(c)
			c:n("{a} ran through the whole day out loud. You played the customers.")
			burst(c, "a", {
				cheeky = "you were a terrible customer|perfect practice",
				bookish = "That helped.|I found two things to fix.",
				nervous = "Okay. Okay.|I didn't drop anything. That's a start.",
				_ = "Okay.|I think I've got it.",
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
		burst(s, "a", {
			foodie = "{player}.|Taste!|Now, before it goes cold.",
			sunny = "{player}. Try my soup?|Tell me the truth. The nice truth.",
			nervous = "Could you taste this?|I can't tell any more.|I've tasted it forty times.",
			proud = "Try my soup.|You'll be the second to call it perfect. I was the first.",
			bookish = "I followed the recipe exactly.|But something's missing. Could you try?",
			gloomy = "Made soup.|It needs something. Everything does.",
			cool = "Soup. Taste it.",
			_ = "{player}, taste my soup?|Does it need salt?",
		}, "question")
		s:choice("A pinch of salt.", function(c)
			burst(c, "a", {
				foodie = "A pinch.|You've got the tongue for this, {player}.",
				gloomy = "Salt. Yeah.|...That's better. Annoyingly.",
				_ = "Salt. Just a pinch.|...Oh.|Oh, that's it.",
			}, "sparkle")
			c:mood("a", 4)
			c:xp("a", 5)
		end)
		s:choice("It's perfect as it is.", function(c)
			burst(c, "a", {
				proud = "I know.|I just wanted to hear it.",
				nervous = "Really?|You'd say if it wasn't?|Okay. Okay.",
				_ = "Really? Oh good.|I'll stop fiddling.",
			}, "heart")
			c:mood("a", 5)
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
		burst(s, "a", {
			bookish = "I'm writing to my gran.|Four pages so far.|Is that too long?",
			gloomy = "Writing to my gran.|Nothing happens here worth writing.",
			dramatic = "I'm writing to my gran.|A letter for the ages.|I've stalled on line two.",
			cool = "Writing to my gran.|Stuck.",
			shy = "Um...|I'm writing to my gran.|What do people write?",
			polite = "I'm writing to my gran, {player}.|Would you help me with what to say?",
			_ = "{player}, I'm writing to my gran.|I don't know what to put.",
		}, "question")
		s:choice("Tell her about the town.", function(c)
			burst(c, "a", {
				gloomy = "The town. Okay.|...There is a lot, actually.|The gulls. The fountain. You.",
				sunny = "The town. Okay.|Where do I even start.|The bakery.",
				_ = "The town. Yes.|She'd like that.",
			}, "idea")
			c:mood("a", 4)
			c:memo("a", "I told my gran all about the town. She wants to know who {player} is.")
		end)
		s:choice("Keep it short and sweet.", function(c)
			burst(c, "a", {
				bookish = "Short.|Four pages down to one.|That hurts.",
				_ = "Short.|'Dear Gran, all well, lots of love.'|Done.",
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
		burst(s, "a", {
			gentle = "{player}...|My plant's drooping.|I don't know what it needs.",
			nervous = "{player}, my plant's drooping.|Is it dying?|Is it my fault?",
			gloomy = "My plant's drooping.|Everything I touch.",
			dramatic = "{player}.|My fern. It's wilting.|I can't watch.",
			bookish = "My plant's drooping.|I've ruled out three causes. Seven left.",
			_ = "{player}.|My plant's gone all droopy.",
		}, "sad")
		-- one of the two fixes works, this time
		local works = ctx.rng:pick({ 1, 2 })
		local function after(c, ok)
			if ok then
				c:n("By the next morning it was standing up straight again.")
				burst(c, "a", {
					gloomy = "It's alive.|Huh.|Something went right.",
					dramatic = "It lives.|You saved it, {player}.",
					_ = "Look. It's perked right up.|Thanks, {player}.",
				}, "sparkle", "cheer")
				c:mood("a", 5)
				c:memo("a", "My plant's doing really well now. {player} knew what it needed.")
			else
				c:n("By the next morning it was drooping a little more.")
				burst(c, "a", {
					nervous = "Worse.|It's worse.|Okay. Try the other thing?",
					_ = "Hm.|Not that, then.",
				}, "sweat")
				c:mood("a", -1)
			end
		end
		s:choice("More water.", function(c)
			burst(c, "a", {
				nervous = "Not too much?|How much is too much?|Okay. A cup.",
				_ = "Water. Okay.|Big drink for you.",
			}, "idea")
			after(c, works == 1)
		end)
		s:choice("Move it into the sun.", function(c)
			burst(c, "a", {
				dreamy = "The sun. Yes.|It's been in the corner, poor thing.",
				_ = "Into the sun.|Windowsill it is.",
			}, "idea")
			after(c, works == 2)
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
		burst(s, "a", {
			sunny = "{player}.|It's raining.|I'm going spare. What do I do?",
			easygoing = "Rain.|Great excuse to do nothing.|Or something. You pick.",
			bold = "Rain. Can't go out.|I'm climbing the walls.",
			dreamy = "It's raining.|I could do anything.|That's the trouble.",
			gloomy = "Rain.|Course it is.|What does anyone do on a day like this?",
			nervous = "It's raining.|What if it doesn't stop?|What do I do all day?",
			_ = "{player}, it's raining.|What do I do all day?",
		}, "question")
		s:choice("Bake something.", function(c)
			burst(c, "a", {
				foodie = "Yes.|Yes.|The big cake.",
				bold = "Bake. Okay.|Something huge.",
				_ = "Bake.|Oh, the house will smell lovely.",
			}, "heart")
			c:mood("a", 4)
		end)
		s:choice("Jump in puddles.", function(c)
			burst(c, "a", {
				sunny = "Wellies on!",
				shy = "Puddles? Like a kid?|...Okay. Just a small one.",
				gloomy = "I'll get soaked.|...Okay. Yes. Let's.",
				prickly = "That's ridiculous.|Where are my wellies.",
				_ = "Puddles. Yes.|Wellies on.",
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
		burst(s, "a", {
			nervous = "{player}?|Sorry. Are you awake?|I can't sleep.",
			dreamy = "{player}.|Are you up?|The moon's too bright.",
			gloomy = "{player}.|Can't sleep.|Again.",
			cool = "{player}.|You up?",
			sunny = "{player}. You're up too?|I can't sleep.|My brain won't stop.",
			easygoing = "{player}...|it's two in the morning|and I'm awake. That's not like me.",
			_ = "{player}?|You awake?",
		}, "zzz")
		burst(s, "a", {
			nervous = "I keep thinking about tomorrow.|And the day after.",
			foodie = "It's the cheese I had.|So much cheese.",
			dramatic = "My thoughts won't be quiet.|They're having a party.",
			bookish = "I started counting sheep.|Then I wondered how many sheep there are. In total.",
			gloomy = "Lying here listing everything that could go wrong.|It's a long list.",
			_ = "My head won't switch off.",
		}, "question")
		s:choice("Go to sleep.", function(c)
			burst(c, "a", {
				prickly = "Fine.|You too. Seriously.",
				cool = "Okay.|Night.",
				gloomy = "Okay.|...Night, {player}.",
				nervous = "Okay.|Sorry for waking you.|Good night.",
				_ = "Okay.|You too.|Good night, {player}.",
			}, "zzz")
			c:n("{a} was asleep before ten minutes were up.")
			c:mood("a", 3)
		end)
		s:choice("What's on your mind?", function(c)
			burst(c, "a", {
				nervous = "Okay.|So.|First thing...",
				gloomy = "You don't want to hear it.|...Okay. Well.",
				prickly = "Nothing.|...Fine. Everything.",
				_ = "Okay.|Thanks, {player}.",
			}, "heart")
			c:n("They talked until the sky went grey.")
			say(c, "a", "Forget I said all that.|...Thanks for listening, though.", "zzz")
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
		burst(s, "a", {
			nervous = "{player}. Help.|That one coming over.|I've forgotten their name. I've known them weeks.",
			shy = "Um. {player}.|The one coming over.|What's their name? Don't look.",
			proud = "{player}. Quickly. That one.|I know their name. I need you to say it first.",
			gloomy = "I've forgotten their name.|Again.|And they're coming over.",
			cool = "{player}.|Name.|Quick.",
			_ = "{player}.|Who's that coming over?|I've forgotten their name.",
		}, "sweat")
		s:choice("Whisper it to them.", function(c)
			c:n("You whispered it.")
			say(c, "a", "{b}. Hi.|Hello, {b}.|How are you, {b}?", "sparkle")
			burst(c, "b", {
				cheeky = "why do you keep saying my name",
				cool = "...Hi.",
				_ = "Hi.|You're very keen today.",
			}, "question")
			c:rel(3)
		end)
		s:choice("Just ask them.", function(c)
			say(c, "a", "Sorry.|This is awful.|What's your name again?", "sweat")
			burst(c, "b", {
				gentle = "It's {b}.|Don't worry. I forget mine sometimes.",
				proud = "It's {b}.|I'll try not to be hurt.",
				prickly = "It's {b}.|Write it down this time.",
				gloomy = "{b}.|Nobody remembers. It's fine.",
				sunny = "{b}!|What's yours again? Kidding.",
				_ = "It's {b}.|Don't worry about it.",
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
		burst(s, "a", {
			dreamy = "{player}.|Can I show you a place?|Nobody else knows it.",
			cheeky = "{player}|want to see my secret spot|pinky promise you won't tell",
			shy = "Um, {player}?|There's a place I go.|I could show you. If you want.",
			cool = "Got a spot I like.|Want to see?",
			bookish = "I found a hollow up on the hill.|You can see the whole bay from it.|Want to see?",
			_ = "{player}.|Want to see my secret spot?",
		}, "idea")
		s:choice("Show me.", function(c)
			c:n("{a} led you up a path behind the hill to a flat rock looking out over the whole town.")
			burst(c, "a", {
				dreamy = "This is where I come to think.|Or not think.",
				cheeky = "tell no one|not even the gulls",
				shy = "I've never shown anyone.|You're the first.",
				gloomy = "It's the one place nothing goes wrong.",
				_ = "You can come here too.|It's ours now.",
			}, "heart")
			c:hearts("a", 1)
			c:mood("a", 5)
			c:memo("a", "I showed {player} my secret spot. It's our spot now.")
		end)
		s:choice("Another day.", function(c)
			burst(c, "a", {
				shy = "Okay.|It'll still be there.",
				cheeky = "your loss|it's very secret",
				_ = "Another day.|Don't forget.",
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
		burst(s, "a", {
			proud = "{player}. Don't look at me.|...Do I look ridiculous?|Be quick.",
			gloomy = "Go on.|Laugh.|Everyone else has.",
			dramatic = "{player}.|Witness my shame.",
			prickly = "Not a word.|...Okay. One word.|How bad?",
			nervous = "Is it bad?|It's bad.|Is everyone looking?",
			sunny = "{player}! Look at my hat.|It has a feather. And a bell.",
			cool = "Hat. Bet.|Don't ask.",
			_ = "{player}. Be honest.|How silly is this hat?",
		}, "sweat")
		s:choice("It suits you.", function(c)
			burst(c, "a", {
				proud = "It does, doesn't it?|I might keep it.",
				gloomy = "You're just saying that.|...Am I keeping it?",
				_ = "Really?|Huh. Maybe it's not so bad.",
			}, "sparkle")
			c:say("b", "That was meant to be a punishment.", "sweat")
			c:mood("a", 5)
		end)
		s:choice("It's very silly.", function(c)
			burst(c, "a", {
				prickly = "I know.|I know.",
				dramatic = "I KNOW.|I've got six more hours of this.",
				_ = "I know.|I know it is.",
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
		burst(s, "a", {
			nervous = "{player}, can I practise on you?|I want to ask {b} to join my quiz team.|I keep getting it wrong in my head.",
			shy = "Um, {player}...|Can I practise on you?|I want to ask {b} something. Quiz team. It's nothing.",
			proud = "{player}. I'm asking {b} to join my quiz team.|I've prepared a speech.",
			bookish = "{player}, I'm asking {b} to join our quiz team.|I've written out three ways to ask.",
			_ = "{player}.|Can I practise asking {b} to join my quiz team?",
		}, "sweat")
		local keen = ctx.rel(a, b) >= 0
		s:choice("Just go and ask.", function(c)
			burst(c, "a", {
				nervous = "Just go? Now?|Okay.|Okay okay okay.",
				shy = "Now?|...Okay. Before I lose my nerve.",
				_ = "Right.|Going now.",
			}, "sweat")
			if keen then
				burst(c, "b", {
					cool = "Sure. When?",
					bookish = "Yes.|I know all the capitals. Most of them.",
					foodie = "Is there food at the quiz?|Then yes.",
					dramatic = "I thought you'd never ask.|Yes.",
					gloomy = "Me? Okay.|I'll get them all wrong. But okay.",
					_ = "Yes.|Course I will.",
				}, "heart")
				c:rel(8)
			else
				burst(c, "b", {
					prickly = "Quiz? Me?|...Fine. One night.",
					_ = "Hm.|I'll think about it.",
				}, "question")
				c:rel(2)
			end
		end)
		s:choice("Practise on me first.", function(c)
			c:n("{a} asked you four times. The fourth time was very good.")
			burst(c, "a", {
				dramatic = "I've never been more ready for anything.",
				_ = "Okay.|I'm ready now. I think.",
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
		burst(s, "a", {
			cheeky = "{player}|bet you it rains tomorrow|go on",
			bold = "{player}.|Bet you it's sunny tomorrow.|Go on. Bet.",
			bookish = "I've been reading the clouds.|Want to bet on tomorrow's weather?",
			gloomy = "It'll rain tomorrow.|Bet you it does.",
			_ = "{player}.|Sun or rain tomorrow?|Pick one.",
		}, "idea")
		s:say("a", "Loser sings a song at the fountain.", "music")
		s:choice("Sun.", function(c)
			burst(c, "a", {
				gloomy = "Sun. Brave.|We'll see.",
				_ = "Sun? Okay.|Warm up your voice.",
			}, "sparkle")
			c:mood("a", 2)
			c:memo("a", "{player} bet me it'd be sunny. Somebody's singing at the fountain.")
		end)
		s:choice("Rain.", function(c)
			burst(c, "a", {
				cheeky = "rain? that's my pick|fine. we're on the same side|who sings then",
				_ = "Rain? Okay.|Warm up your voice.",
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
		burst(s, "a", {
			easygoing = "{player}. Big favour.|Knock on my door at six tomorrow?|I want to see the sunrise. Once.",
			dreamy = "I want to see the sunrise from the hill tomorrow.|But I'll sleep through it.",
			nervous = "Could you knock on my door at six?|I've set three alarms.|What if they all fail?",
			bold = "Knock at six. Loud.|I want to see the sunrise.",
			gloomy = "I want to see the sunrise.|I'll sleep through it.|I always do.",
			_ = "{player}.|Could you knock on my door at six tomorrow?|I want to see the sunrise.",
		}, "question")
		s:choice("I'll knock.", function(c)
			burst(c, "a", {
				easygoing = "You're a hero.|A very early hero.",
				nervous = "Thank you.|Knock twice. No, three times.",
				prickly = "Fine. Good.|Thanks.",
				_ = "Thanks, {player}.|Knock loud.",
			}, "heart")
			c:hearts("a", 1)
			c:mood("a", 4)
			c:memo("a", "{player} knocked at six and I saw the sunrise. It was pink. Worth it.")
		end)
		s:choice("Leave your curtains open.", function(c)
			burst(c, "a", {
				bookish = "The sun as an alarm.|Very old idea. Very good one.",
				_ = "Curtains open.|The sun can wake me itself. Clever.",
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
		burst(s, "a", {
			sunny = "{player}.|You walked right past me.|I waved and everything.",
			cheeky = "{player}|i waved at you|you walked straight past. i'm hurt :P",
			shy = "Um. {player}?|I waved earlier.|You didn't see. That's okay.",
			prickly = "{player}.|I waved at you earlier.|You walked right past. Whatever.",
			dramatic = "{player}.|This morning. I waved.|You walked on. I've never felt so small.",
			gloomy = "{player}.|I waved at you earlier.|You didn't see. Nobody sees me.",
			polite = "Good afternoon, {player}.|I believe I waved at you earlier. No matter.",
			_ = "{player}.|I waved at you this morning.|You walked right past.",
		}, "sad", "wave")
		s:choice("Sorry, I was miles away.", function(c)
			burst(c, "a", {
				prickly = "Hmph.|Fine. Wave twice next time.",
				gloomy = "...It's okay.|Thanks for saying.",
				cheeky = "sorry accepted|wave twice next time",
				_ = "Ha. That's okay.|Wave next time.",
			}, "heart")
			c:mood("a", 3)
		end)
		s:choice("I waved back. You missed it.", function(c)
			burst(c, "a", {
				cheeky = "you did not|...did you?",
				nervous = "You did?|Oh no. Did I not wave back?|Now I feel bad.",
				proud = "Nobody waves back without me seeing.",
				_ = "Did you?|Then we both missed it.",
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
		burst(s, "a", {
			sunny = "{player}.|Just wanted to say.|My room's really nice. I love the window.",
			shy = "Um. {player}.|My room.|It's nice. Thank you. That's all.",
			cool = "Room's good.|Thanks.",
			prickly = "Room's fine.|Better than fine.|Don't let it go to your head.",
			polite = "{player}, a proper thank you for my room.|It's very comfortable.",
			gloomy = "My room's nice.|Weirdly.|I keep waiting for something to go wrong.",
			dramatic = "{player}.|My room. It's perfect.|I cried. A little.",
			foodie = "My room is lovely.|Close to the kitchen. That's all I ask.",
			_ = "{player}, my room's really nice.|Thanks.",
		}, "heart")
		s:choice("Glad you like it.", function(c)
			c:voice("a", "thanks", "heart")
			c:mood("a", 4)
		end)
		s:choice("Anything you'd change?", function(c)
			burst(c, "a", {
				bookish = "A shelf.|A tall one. For books.|Many books.",
				foodie = "A little table by the bed.|For snacks.",
				dreamy = "A window that looks at the sea.|If that's possible.",
				proud = "A mirror.|A big one.",
				cool = "A lamp. Maybe.",
				nervous = "Nothing. It's perfect.|Well.|A nightlight. Just in case.",
				_ = "Maybe a rug.|My feet get cold.",
			}, "idea")
			c:mood("a", 2)
			c:memo("a", "I told {player} what I'd like for my room. No rush.")
		end)
		s:log("{a} thanked you for their room.")
		return s:done()
	end,
})

-- chats --------------------------------------------------------------------------------------------
-- Only a chat: what they send you on an ordinary day, in the shapes a phone chat takes, each in
-- their own voice.

-- a message meant for somebody else
event({
	id = "wrongperson",
	actors = 2,
	when = "day",
	weight = W({ base = 0.1, rel = -20 }),
	scene = function(ctx, a, b)
		local s = K.scene(ctx, "Wrong chat")
		burst(s, "a", {
			bold = "{b}. You've got my ladder.|I need it back by six.",
			prickly = "{b}. My ladder.|You've had it a week.|Seriously.",
			polite = "{b}, I hope you don't mind my asking.|Might I have my ladder back today?",
			cheeky = "{b} where's my ladder|i know it's you",
			nervous = "{b}, sorry, did you borrow my ladder?|I'm not cross. I just need it.",
			_ = "{b}, have you still got my ladder?|I need it today.",
		})
		s:n("It went to you instead.")
		burst(s, "a", {
			bold = "Wait.|Wrong person.|Hi, {player}.",
			prickly = "...|That wasn't for you.|Ugh.",
			polite = "Oh dear.|That was meant for {b}. I'm sorry, {player}.",
			cheeky = "oops|hi {player}|you didn't see that",
			nervous = "Oh no.|Sorry, {player}.|That was for {b}.",
			_ = "Oh.|That was meant for {b}.|Sorry, {player}.",
		}, "sweat")
		s:choice("I'll ask {b} for you.", function(c)
			say(c, "a", "Would you?|Thanks.", "heart")
			burst(c, "b", {
				gentle = "Oh, the ladder. I'm so sorry.|I'll bring it over now.",
				easygoing = "The ladder. Right.|I'm sitting on it. Well. Near it.",
				dreamy = "There was a ladder?|Oh. The ladder. It's by the tree.",
				proud = "I was improving it.|It'll come back better.",
				_ = "The ladder.|I forgot I had it. Sorry.",
			}, "sweat")
			c:rel(4)
			c:mood("a", 2)
		end)
		s:choice("Is it the ladder by {b}'s door?", function(c)
			burst(c, "a", {
				bold = "Knew it.|Going now.",
				prickly = "By the door. Of course.|Thanks, {player}.",
				polite = "That would be it.|Thank you, {player}. That's very helpful.",
				cheeky = "detective {player}|thanks",
				_ = "That's the one.|Thanks, {player}.",
			}, "idea")
			c:mood("a", 2)
		end)
		s:log("{a} sent you a message meant for {b}.")
		return s:done()
	end,
})

-- the morning after a late chat
event({
	id = "saidodd",
	when = "day",
	weight = W({
		base = 0.1,
		cond = function(ctx)
			return ctx.hour < 14
		end,
	}),
	scene = function(ctx, a)
		local s = K.scene(ctx, "The morning after")
		burst(s, "a", {
			shy = "Um, {player}.|About last night.|Did I say anything odd?",
			prickly = "{player}.|Last night.|Forget everything I said.",
			proud = "{player}. About last night.|I said nothing embarrassing. Correct?",
			dramatic = "{player}.|What did I say last night?|I fear the worst.",
			gloomy = "{player}.|I sent you a lot last night.|Sorry. Did I say anything odd?",
			nervous = "{player}, s-sorry about last night.|Did I say anything strange?|I can't remember half of it.",
			easygoing = "{player}.|I wake up and there are twelve messages to you.|From me. At three.",
			_ = "{player}.|Did I say anything odd last night?",
		}, "sweat")
		s:choice("Not a thing.", function(c)
			burst(c, "a", {
				shy = "Oh.|Good.|Thank you.",
				prickly = "Good.|...You're lying. Thanks.",
				proud = "As I thought.",
				dramatic = "Phew.|My reputation survives.",
				nervous = "Oh.|Okay.|Thank you.",
				_ = "Oh good.|Thanks.",
			}, "heart")
			c:mood("a", 3)
		end)
		s:choice("Maybe you dreamed it.", function(c)
			burst(c, "a", {
				shy = "...So I did say something.|Okay. Never mind. Don't tell me.",
				prickly = "That's a yes.|Ugh.",
				dreamy = "Maybe I did.|It was a nice dream, then.",
				cheeky = "hahaha|ok what did i say",
				_ = "Maybe I did.|Let's say I did.",
			}, "laugh", "laugh")
			c:mood("a", 2)
			c:hearts("a", 1)
		end)
		s:log("{a} asked if they'd said anything odd last night.")
		return s:done()
	end,
})

-- a picture they want you to see
local PICTURES = {
	"a cloud shaped exactly like a sheep",
	"the bakery cat asleep in the bread basket",
	"the harbour at sunrise, all pink",
	"a duck sitting in a puddle in the square",
	"their first ever tomato",
}

event({
	id = "lookphoto",
	when = "day",
	weight = W({ base = 0.1, traits = { social = 0.15 } }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "A picture"):with({ pic = ctx.rng:pick(PICTURES) })
		s:prop("camera", "a")
		burst(s, "a", {
			sunny = "{player}! {player}!|Look at this.",
			proud = "{player}. I took a picture.|You'll want to see it. Everyone does.",
			shy = "Um, {player}.|I took a picture.|You don't have to look.",
			dramatic = "{player}.|I have captured something.|Behold!",
			cool = "{player}.|Look.",
			foodie = "{player}. Look what I saw on the way to lunch.",
			_ = "{player}.|Look what I took this morning.",
		}, "sparkle")
		s:n("It was {pic}.")
		burst(s, "a", {
			proud = "Good, isn't it?|Say it.",
			shy = "Is it okay?",
			gloomy = "It came out. That's a first.",
			bookish = "I waited twenty minutes for the light.",
			_ = "Good, right?",
		}, "question")
		s:choice("That's a great picture.", function(c)
			burst(c, "a", {
				proud = "Say it again.|Louder.",
				shy = "...!|Thank you.",
				sunny = "Right? RIGHT?|I'm taking more.",
				gloomy = "Really?|Heh... okay. I'll keep it.",
				cool = "...Thanks.",
				_ = "I knew you'd like it.",
			}, "heart")
			c:mood("a", 4)
			c:hearts("a", 1)
		end)
		s:choice("Is that your thumb in the corner?", function(c)
			burst(c, "a", {
				proud = "Th-that's part of it.|It shows scale.|Anyway!",
				prickly = "It's a frame.|Ugh. Fine. It's my thumb.",
				cheeky = "it's a cameo",
				shy = "Oh no.|It is.",
				dramatic = "That thumb is ART.",
				_ = "...It is.|Ignore the thumb.",
			}, "sweat")
			c:mood("a", 1)
		end)
		s:log("{a} showed you a picture of {pic}.")
		return s:done()
	end,
})

-- an invite for tomorrow
local TOMORROWS = {
	{ what = "a morning's fishing off the pier", place = "the end of the pier", time = "seven" },
	{ what = "breakfast at the café", place = "the café", time = "nine" },
	{ what = "a walk up the hill", place = "the fountain", time = "ten" },
	{ what = "a look round the market", place = "the market", time = "eleven" },
}

event({
	id = "invite",
	when = "day",
	weight = W({ base = 0.11, traits = { social = 0.2 } }),
	scene = function(ctx, a)
		local t = ctx.rng:pick(TOMORROWS)
		local s = K.scene(ctx, "Tomorrow?"):with({
			what = t.what,
			place = t.place,
			time = t.time,
			What = upper(t.what),
			Place = upper(t.place),
		})
		burst(s, "a", {
			sunny = "{player}.|Are you free tomorrow?|Say yes.",
			bold = "{player}. Tomorrow morning.|You're free, right?",
			shy = "Um, {player}.|Are you busy tomorrow?|You can say yes.",
			polite = "Hello, {player}. Are you free tomorrow morning, by any chance?",
			cool = "{player}. Tomorrow. Free?",
			cheeky = "{player}|you're free tomorrow|i checked",
			easygoing = "{player}.|Got anything on tomorrow?|I've got nothing on. On purpose.",
			_ = "{player}.|Are you free tomorrow?",
		}, "question")
		s:choice("I'm free.", function(c)
			burst(c, "a", {
				sunny = "Knew it!|{What}. {Place} at {time}.",
				bold = "Good.|{What}. {Place}, {time}. Don't be late.",
				shy = "Oh.|Then would you come for {what}?|{Place}, at {time}...",
				polite = "Wonderful.|Would {what} suit you? {Place} at {time}.",
				cool = "Good.|{What}. {Place}, {time}.",
				_ = "Good.|{What}?|{Place}, {time}.",
			}, "heart")
			c:mood("a", 4)
			c:memo("a", "Tomorrow it's {what} with {player}. {Place} at {time}.")
		end)
		s:choice("Depends what for.", function(c)
			burst(c, "a", {
				sunny = "{What}.|Now you're free.",
				bold = "{What}.|So you're free.",
				cheeky = "you'll find out|{place} at {time}. come",
				shy = "Oh. Um.|{What}. If you'd like.",
				_ = "{What}.|{Place} at {time}?",
			}, "idea")
			c:mood("a", 3)
			c:memo("a", "Tomorrow it's {what} with {player}. {Place} at {time}.")
		end)
		s:log("{a} asked you along for {what} tomorrow.")
		return s:done()
	end,
})

-- sorry for yesterday
event({
	id = "sorryday",
	when = "any",
	weight = W({ base = 0.08, traits = { temper = 0.2 } }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "About yesterday")
		burst(s, "a", {
			polite = "Good morning, {player}.|About yesterday. I was short with you, and I apologise.",
			prickly = "{player}.|About yesterday.|I was rude. ...Sorry.",
			bold = "{player}. Yesterday.|I snapped. That wasn't fair.",
			gloomy = "{player}.|Yesterday was a bad day.|I took it out on you. Sorry.",
			proud = "{player}. About yesterday.|I was not at my best.|That's all.",
			nervous = "{player}, I'm sorry about yesterday.|I was horrible.|I've been thinking about it all night.",
			cool = "{player}.|Yesterday.|Sorry.",
			_ = "{player}.|About yesterday.|I was in a mood. I'm sorry.",
		}, "sad")
		s:choice("Already forgotten.", function(c)
			burst(c, "a", {
				prickly = "...Good.|Thanks.",
				polite = "Thank you.|You're very kind.|I'll bring you tea at four, if that suits.",
				nervous = "Really?|Oh.|Thank you.",
				gloomy = "Okay.|...Thanks.",
				_ = "Thanks, {player}.",
			}, "heart")
			c:mood("a", 4)
		end)
		s:choice("Are you okay now?", function(c)
			burst(c, "a", {
				prickly = "I'm fine.|...Better. Thanks for asking.",
				bold = "Yeah.|Thanks. Lunch is on me.",
				gloomy = "Oh.|...Yeah. A bit.",
				cool = "...Yeah.",
				proud = "I am now.|Thank you.",
				_ = "Oh.|Yeah. Better now. Thanks.",
			}, "heart")
			c:hearts("a", 1)
			c:mood("a", 5)
		end)
		s:log("{a} said sorry for yesterday.")
		return s:done()
	end,
})

-- guess what's in my pocket
event({
	id = "guessquiz",
	when = "day",
	weight = W({ base = 0.1, traits = { mischief = 0.2 } }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "Guess")
		burst(s, "a", {
			cheeky = "{player}|guess what's in my pocket|you'll never",
			sunny = "{player}. Guess what's in my pocket.|Guess. Guess.",
			bookish = "{player}, a small test.|What do you think is in my pocket?",
			foodie = "{player}. Guess what's in my pocket.|Hint: it's warm.",
			dramatic = "{player}.|In my pocket is a mystery.|Guess.",
			_ = "{player}.|Guess what's in my pocket.",
		}, "idea")
		-- either way, the answer
		local reveal = K.byPers(ctx, ctx.stars and ctx.stars.a, {
			cheeky = "nothing|made you guess though",
			foodie = "A bun.|Still warm. Half each?",
			bookish = "A snail shell.|Empty. I checked.",
			sunny = "A conker.|The shiniest one in town.",
			dramatic = "A single button.|From a coat I've never seen.",
			gloomy = "A bit of string.|That's all I ever have.",
			_ = "A pebble from the beach.|It's a good one.",
		})
		s:choice("A biscuit?", function(c)
			c:say("a", "No.", "laugh")
			say(c, "a", reveal, "sparkle")
			c:mood("a", 2)
		end)
		s:choice("A frog?", function(c)
			say(c, "a", "A frog?|No.|Why would it be a frog.", "laugh", "laugh")
			say(c, "a", reveal, "sparkle")
			c:mood("a", 2)
		end)
		s:log("{a} made you guess what was in their pocket.")
		return s:done()
	end,
})

-- a long day let out, then taken back
event({
	id = "vent",
	when = "any",
	weight = W({ base = 0.1, job = "any", traits = { temper = 0.2 } }),
	scene = function(ctx, a)
		local w = ctx.job(a)
		local s = K.scene(ctx, "A long one"):with({ job = if w then w.def.name:lower() else "work" })
		burst(s, "a", {
			prickly = "Three orders at the {job} came in wrong.|Then the kettle broke.|Then someone asked if I was tired.|Of course I'm tired.",
			polite = "Forgive me, {player}, I need to say this somewhere.|The {job} was very trying today.|Everything went wrong at once.",
			gloomy = "Everything at the {job} went wrong today.|Everything.|Even the bits that can't.",
			bold = "{player}. The {job} today.|Two people off, one of me.|I did it all. I'm done.",
			nervous = "{player}, the {job} today...|I mixed up two orders and then a third one.|Nobody was cross but I was.",
			_ = "{player}.|Long day at the {job}.|Everything piled up at once.",
		}, "sad")
		s:say("a", "...Sorry. That was a lot.", "sweat")
		s:choice("You do so much.", function(c)
			burst(c, "a", {
				prickly = "Ugh. Don't say that.|...Thanks.",
				polite = "That's kind of you to say.|Forget I went on.",
				gloomy = "...|Thanks. Forget I said all that.",
				bold = "Hah.|Somebody has to.|Thanks, though.",
				_ = "Oh.|Thanks.|Forget I said all that.",
			}, "heart")
			c:mood("a", 5)
		end)
		s:choice("Let me help tomorrow.", function(c)
			burst(c, "a", {
				prickly = "You'd get in the way.|...Come at nine.",
				polite = "You'd do that?|Then thank you. Nine, if that suits.",
				bold = "Yeah?|Good. Nine. I always pay back.",
				nervous = "Really?|Oh.|Thank you.",
				_ = "You would?|Thanks, {player}.",
			}, "heart")
			c:hearts("a", 1)
			c:mood("a", 5)
			c:xp("a", 4)
		end)
		s:log("{a} let off steam about work.")
		return s:done()
	end,
})

-- a part in their story
local ROLES = {
	{
		role = "a sidekick",
		mine = "my sidekick",
		theirs = "their sidekick",
		quest = "find out who keeps ringing the hall bell at midnight",
	},
	{ role = "a witness", mine = "my witness", theirs = "their witness", quest = "watch me skip a stone ten times" },
	{
		role = "an apprentice",
		mine = "my apprentice",
		theirs = "their apprentice",
		quest = "learn the secret of the perfect sandcastle",
	},
	{ role = "a judge", mine = "my judge", theirs = "their judge", quest = "decide whose snowman is better" },
}

event({
	id = "sidekick",
	when = "day",
	weight = W({ base = 0.1, traits = { social = 0.2, mischief = 0.2 } }),
	scene = function(ctx, a)
		local r = ctx.rng:pick(ROLES)
		local s = K.scene(ctx, "A part for you")
			:with({ role = r.role, mine = r.mine, theirs = r.theirs, quest = r.quest })
		burst(s, "a", {
			dramatic = "{player}.|The moment has come.|You will be {mine}.",
			cheeky = "{player}|congratulations|you're {mine} now",
			sunny = "{player}! Big news.|You're {mine}.",
			dreamy = "{player}.|I need {role}.|It's you. I decided.",
			_ = "{player}.|I need {role}.|You'll do.",
		}, "sparkle", "point")
		s:say("a", "Today we {quest}.", "idea")
		s:choice("I'm in.", function(c)
			burst(c, "a", {
				dramatic = "Yes.|*trumpet noise*|That's me, by the way.",
				cheeky = "excellent|i knew you'd crack",
				sunny = "Yes!|Meet me at the fountain.",
				dreamy = "Good.|I'll be by the water.",
				_ = "Good.|Fountain. Ten minutes.",
			}, "sparkle", "cheer")
			c:hearts("a", 1)
			c:mood("a", 5)
			c:memo("a", "{player} is {mine} now. Today we had to {quest}.")
		end)
		s:choice("Why me?", function(c)
			burst(c, "a", {
				dramatic = "Why you?|WHY YOU?|...Everyone else said no!",
				cheeky = "you were nearest",
				sunny = "Because you're the best.|Fountain. Ten minutes.",
				dreamy = "You were the first name I thought of.",
				_ = "Because.|Fountain. Ten minutes.",
			}, "question")
			c:mood("a", 3)
		end)
		s:log("{a} made you {theirs}.")
		return s:done()
	end,
})

-- a favour, and what came of it
local FAVOURS = {
	{ ask = "hold the ladder while I fix my gutter", after = "The gutter's fixed. Not a drop all night." },
	{ ask = "help me carry a sofa up the hill", after = "The sofa's in. My arms are not." },
	{ ask = "stand at the stall while I fetch more bread", after = "We sold out. You sold half of it." },
	{ ask = "help me find my cat", after = "She was on the roof the whole time. Watching us." },
}

event({
	id = "favour",
	when = "day",
	weight = W({ base = 0.12, traits = { social = 0.1 } }),
	scene = function(ctx, a)
		local f = ctx.rng:pick(FAVOURS)
		local s = K.scene(ctx, "A favour"):with({ ask = f.ask, after = f.after })
		burst(s, "a", {
			sunny = "{player}! Are you free?|Could you {ask}?|You only have to be there.",
			shy = "Um, {player}.|If you're free...|could you {ask}?|You wouldn't have to do much.",
			bold = "{player}. You're free, right?|I need you to {ask}.|Ten minutes.",
			polite = "Hello, {player}. Sorry to butt in.|Might you {ask}? I'd be very grateful.",
			cool = "{player}.|Can you {ask}?",
			easygoing = "{player}...|could you {ask}?|I'll pay you in biscuits.",
			nervous = "{player}, s-sorry to ask.|Could you {ask}?|You can say no.",
			_ = "{player}.|Are you free?|Could you {ask}?",
		}, "question")
		s:choice("On my way.", function(c)
			c:n("You went round. It took an hour.")
			say(c, "a", "{after}", "heart")
			burst(c, "a", {
				sunny = "Thanks!|Next time I'm helping you.",
				bold = "I owe you one.|I always pay back.",
				polite = "Thank you, {player}.|I'll return the favour properly.",
				cool = "...Thanks.",
				gloomy = "That went well.|Weird. Thanks.",
				_ = "Thanks, {player}.|Next time it's on me.",
			}, "heart")
			c:hearts("a", 1)
			c:mood("a", 5)
		end)
		s:choice("Only if there's tea.", function(c)
			burst(c, "a", {
				easygoing = "There's always tea.",
				bold = "Hah. Fine. Tea.",
				cheeky = "tea and a biscuit. final offer",
				_ = "There's tea.|Come round.",
			}, "laugh", "laugh")
			c:n("You went round. There was tea. It took an hour.")
			say(c, "a", "{after}", "heart")
			c:mood("a", 4)
		end)
		s:log("{a} asked you for a favour.")
		return s:done()
	end,
})

-- a small win
local WINS = {
	"I didn't drop a single thing at work today.",
	"I said hello to someone first.",
	"I got up when my alarm went. The first time.",
	"My bread rose. Properly.",
}

event({
	id = "smallwin",
	when = "day",
	weight = W({ base = 0.1, traits = { brave = -0.25 } }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "A good day"):with({ win = ctx.rng:pick(WINS) })
		burst(s, "a", {
			nervous = "{player}!|{win}|I-I know it's small. It felt big.",
			shy = "Um, {player}.|{win}|That's all. I wanted to tell someone.",
			gloomy = "{player}.|{win}|Waiting for the catch.",
			sunny = "{player}! Guess what.|{win}",
			_ = "{player}.|{win}",
		}, "sparkle")
		s:choice("That's a big deal.", function(c)
			burst(c, "a", {
				nervous = "It is?|Oh.|Thank you.",
				shy = "...!|Thank you.",
				gloomy = "Heh...|Okay. I'll let it be big.",
				_ = "I know, right?",
			}, "heart")
			c:mood("a", 5)
		end)
		s:choice("Told you you'd manage.", function(c)
			burst(c, "a", {
				nervous = "You did.|You did say that.",
				gloomy = "You did.|...Don't get used to it.",
				prickly = "Don't be smug.|...Thanks.",
				_ = "You did.|Thanks.",
			}, "heart")
			c:mood("a", 4)
			c:hearts("a", 1)
		end)
		s:log("{a} told you about a small win.")
		return s:done()
	end,
})

-- a question about you, then their own answer
local QUESTIONS = {
	{
		q = "What's your perfect day off?",
		one = "Sleep in.",
		oneBack = "Sleeping in. Good choice.",
		two = "Build something.",
		twoBack = "Of course you do.",
		own = {
			easygoing = "Me? I nap.|Then I rest from the nap.",
			bookish = "I read in the bath till it goes cold.",
			bold = "I swim out to the buoy and back.",
			dreamy = "I sit on the pier and count boats.|I never get to the end.",
			foodie = "I eat my way round the market.|Slowly.",
			_ = "I walk the beach end to end.|Slowly.",
		},
	},
	{
		q = "What are you scared of?",
		one = "Geese.",
		oneBack = "Geese. Fair.",
		two = "Running out of nails.",
		twoBack = "Ha. That's a builder's answer.",
		own = {
			nervous = "Me? Lots.|Mostly the dark.|And geese.",
			bold = "Nothing.|...Deep water. Don't tell anyone.",
			gloomy = "Being forgotten.|Heh. Sorry. Too much.",
			proud = "Nothing at all.|Spiders, a bit.",
			_ = "Thunder.|I hide under the table.",
		},
	},
	{
		q = "Sweet breakfast or savoury?",
		one = "Sweet.",
		oneBack = "Sweet. Jam on everything, then.",
		two = "Savoury.",
		twoBack = "Savoury. Eggs on toast person.",
		own = {
			foodie = "Both.|Sweet, then savoury, then sweet.",
			easygoing = "Whatever's nearest the bed.",
			_ = "Toast.|Toast is both if you're brave.",
		},
	},
	{
		q = "When you were small, what did you want to be?",
		one = "A builder.",
		oneBack = "And now you are. That's nice.",
		two = "A pirate.",
		twoBack = "Ha. You'd make a good one.",
		own = {
			dramatic = "A famous actor.|I'm still deciding when.",
			proud = "The best at something.|Anything. I got there.",
			dreamy = "A cloud.",
			bookish = "A lighthouse keeper.|All that reading time.",
			_ = "A baker.|I still might.",
		},
	},
}

event({
	id = "askabout",
	when = "any",
	weight = W({ base = 0.1, traits = { social = 0.1 } }),
	scene = function(ctx, a)
		local item = ctx.rng:pick(QUESTIONS)
		local s = K.scene(ctx, "A question"):with({ q = item.q })
		burst(s, "a", {
			sunny = "{player}! Question.|{q}",
			shy = "Um, {player}.|Could I ask a question?|{q}",
			bookish = "{player}, I've been asking everyone this.|{q}|It's for a study. A small one.",
			cheeky = "{player}|{q}|answer honestly. i'll know",
			cool = "{player}.|{q}",
			polite = "Hello, {player}. May I ask you something?|{q}",
			_ = "{player}.|{q}",
		}, "question")
		for _, pair in { { item.one, item.oneBack }, { item.two, item.twoBack } } do
			s:choice(pair[1], function(c)
				c:say("a", pair[2], "music")
				burst(c, "a", item.own, "heart")
				c:mood("a", 3)
			end)
		end
		s:log("{a} asked you something about yourself.")
		return s:done()
	end,
})

-- worried about you
event({
	id = "worryyou",
	when = "any",
	weight = W({ base = 0.08, traits = { kind = 0.2 } }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "Look after yourself")
		burst(s, "a", {
			gentle = "{player}, you were still hammering at nine last night.|I could hear it from the garden.|Please eat something warm today, okay?",
			prickly = "{player}.|You ate today, right?|Right?!",
			bold = "{player}. You look done in.|You're stopping for lunch.|That's not a question.",
			polite = "Good morning, {player}. Forgive me for saying so.|You looked very tired yesterday. Are you resting?",
			nervous = "{player}, are you okay?|You looked tired yesterday.|Are you sleeping? Eating?",
			easygoing = "You were up late again, weren't you.|I saw your lamp on.|Even builders need naps.",
			foodie = "{player}. When did you last eat?|A biscuit doesn't count.",
			cool = "{player}.|Your lamp was on at two.|Sleep.",
			_ = "{player}.|You've been working late every night.|Are you looking after yourself?",
		}, "sweat")
		s:choice("I'm fine, really.", function(c)
			burst(c, "a", {
				gentle = "Mm. You said that last week too.|I'm bringing soup.|You can say no. I'm still bringing it.",
				prickly = "Sure you are.|There's a pie on your step.|I had spare.",
				bold = "Sure you are.|One o'clock. I'm coming to get you.",
				polite = "Good. I'm glad.|Do drink some water, at least.",
				nervous = "Okay.|Okay. But if you're not, you'll say?",
				easygoing = "Heh. Sure.|Nap anyway. For me.",
				foodie = "Fine people eat lunch.|I'll bring some round.",
				cool = "Hm.|Sleep anyway.",
				_ = "Hm.|Look after yourself anyway.",
			}, "heart")
			c:mood("a", 2)
		end)
		s:choice("You're right. I'll rest.", function(c)
			burst(c, "a", {
				gentle = "Good.|Get the barley loaf. It keeps you going.",
				prickly = "Good.|...Took you long enough.",
				bold = "Good.|Knew you'd see sense.",
				polite = "I'm very glad.|Thank you for listening.",
				nervous = "Oh.|Good.|Okay. Good.",
				easygoing = "Look at you.|A natural.",
				foodie = "Good.|Start with soup.",
				cool = "Good.",
				_ = "Good.|Thanks for listening.",
			}, "heart")
			c:hearts("a", 1)
			c:mood("a", 3)
		end)
		s:log("{a} worried you weren't looking after yourself.")
		return s:done()
	end,
})

-- this or that
local EITHERS = {
	{
		q = "Crust or middle?",
		one = "Crust.",
		two = "Middle.",
		oneBack = "A crust person.|I knew it.",
		twoBack = "Soft middle. Noted.|I'm saving you the centre slice.",
		mine = "I start at the edge and go round.|It makes it last.",
	},
	{
		q = "Sunrise or sunset?",
		one = "Sunrise.",
		two = "Sunset.",
		oneBack = "Up early, then.|I'll wave.",
		twoBack = "Sunset.|Nobody has to get up for it.",
		mine = "I like the bit after sunset.|When the sea goes purple.",
	},
	{
		q = "Rain on the roof or waves on the beach?",
		one = "Rain on the roof.",
		two = "Waves on the beach.",
		oneBack = "Rain.|Best with a blanket.",
		twoBack = "Waves.|I fall asleep to those.",
		mine = "Rain, then waves after.|Both.",
	},
	{
		q = "Tea or cocoa?",
		one = "Tea.",
		two = "Cocoa.",
		oneBack = "Tea. Sensible.",
		twoBack = "Cocoa.|With the skin on top?",
		mine = "Cocoa in winter, tea the rest.|I'm not fussy.|I'm a bit fussy.",
	},
}

event({
	id = "thisorthat",
	when = "any",
	weight = W({ base = 0.11 }),
	scene = function(ctx, a)
		local item = ctx.rng:pick(EITHERS)
		local s = K.scene(ctx, "This or that"):with({ q = item.q })
		burst(s, "a", {
			foodie = "{player}!|Important.|{q}",
			sunny = "{player}! Quick.|{q}",
			bookish = "{player}, small survey.|{q}",
			cheeky = "{player}|{q}|wrong answers only. no, real answers",
			nervous = "{player}, can I ask something silly?|{q}",
			_ = "{player}.|{q}",
		}, "question")
		for _, pair in { { item.one, item.oneBack }, { item.two, item.twoBack } } do
			s:choice(pair[1], function(c)
				say(c, "a", pair[2], "music")
				say(c, "a", item.mine, "heart")
				c:mood("a", 2)
			end)
		end
		s:log("{a} asked you this or that.")
		return s:done()
	end,
})

-- a roll from the bakery
event({
	id = "errand",
	when = "day",
	weight = W({
		base = 0.1,
		cond = function(ctx)
			return ctx.hour < 14
		end,
	}),
	scene = function(ctx, a)
		local s = K.scene(ctx, "On your way past")
		burst(s, "a", {
			easygoing = "*yawn*|Who decided the bakery opens at six.|Grab me a roll on your way past? The plain kind.",
			prickly = "{player}.|The bakery queue is out the door.|I'm not standing in that. Are you going past?",
			gloomy = "{player}.|Woke up late. Missed the good bread.|As usual. Are you near the bakery?",
			foodie = "{player}. Are you near the bakery?|Seed rolls today.|I'm stuck in waiting for a parcel.",
			sunny = "{player}! Are you going past the bakery?|Get me a bun? I'll pay you back.",
			shy = "Um, {player}.|If you're going past the bakery...|could you get me a roll? Only if it's no trouble.",
			_ = "{player}.|Are you going past the bakery?|Could you grab me a roll?",
		}, "question")
		s:choice("I'll bring you one.", function(c)
			burst(c, "a", {
				easygoing = "You're the best.|I'll pay you back. Eventually.",
				prickly = "...Thanks.|Plain one.",
				gloomy = "You would?|Heh... okay. Thanks.",
				foodie = "Seed roll.|Two if they're warm.",
				sunny = "The one with sugar on.|Thank you.",
				shy = "...!|Thank you.",
				_ = "Thanks, {player}.",
			}, "heart")
			c:hearts("a", 1)
			c:mood("a", 4)
		end)
		s:choice("Early bird gets the bun.", function(c)
			burst(c, "a", {
				easygoing = "Heh.|The bun can wait for me.|Back to sleep.",
				prickly = "Ugh.|Fine. I'll go myself.",
				gloomy = "The early bird was everyone but me.",
				foodie = "Then I'm the late bird.|And I'm starving.",
				sunny = "Hahaha.|Okay, okay. I'm going.",
				_ = "Hah.|Fine. I'll go.",
			}, "laugh", "laugh")
			c:mood("a", 1)
		end)
		s:log("{a} asked you to bring them a roll from the bakery.")
		return s:done()
	end,
})

-- a walk home in the dark
event({
	id = "walkyouhome",
	when = "night",
	weight = W({ base = 0.08, traits = { brave = 0.1, kind = 0.1 } }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "The way back")
		burst(s, "a", {
			bold = "{player}. The cliff path's all mud.|I'm walking you home.|No arguing.",
			gentle = "{player}, it's very dark on the harbour path tonight.|Could I walk back with you? I'd feel better.",
			prickly = "{player}. It's pitch black out.|I'm going your way anyway.|Wait for me.",
			polite = "Good evening, {player}. The lamps on the hill road are out.|May I walk you home?",
			nervous = "{player}? It's very dark tonight.|Could we walk back together?|For you. And a bit for me.",
			cool = "{player}.|Lamps are out.|I'll walk you.",
			_ = "{player}.|It's dark out.|I'll walk you home.",
		}, "question")
		s:choice("I can manage.", function(c)
			burst(c, "a", {
				bold = "Sure you can.|I'm still coming.",
				prickly = "I know.|I'm still coming. I said I was going that way.",
				gentle = "I know you can.|Humour me.",
				polite = "Of course.|I'll walk a little way behind, then.",
				nervous = "Okay.|Can I come anyway?",
				cool = "...Still coming.",
				_ = "Sure.|I'll come anyway.",
			}, "sweat")
			c:n("You walked home together. The lamps came back on halfway.")
		end)
		s:choice("Thanks. I'd like that.", function(c)
			burst(c, "a", {
				bold = "Good.|Mind the puddle by the gate.",
				prickly = "Good.|Keep up.",
				gentle = "Good.|Hold my arm on the steps.",
				polite = "It's my pleasure.",
				nervous = "Oh good.|Okay. Let's go.",
				cool = "Okay.",
				_ = "Good.|This way.",
			}, "heart")
			c:n("You walked home together. The lamps came back on halfway.")
		end)
		s:hearts("a", 1)
		s:mood("a", 3)
		s:log("{a} walked you home in the dark.")
		return s:done()
	end,
})

-- something left on your step
local STEPS = {
	{ thing = "a jar of plum jam", edible = true },
	{ thing = "a bag of rolls, still warm", edible = true },
	{ thing = "a pot of mint", edible = false },
	{ thing = "a pair of knitted mittens", edible = false },
	{ thing = "a smooth stone with a face painted on it", edible = false },
}

event({
	id = "onyourstep",
	when = "day",
	weight = W({ base = 0.07, traits = { kind = 0.2 } }),
	scene = function(ctx, a)
		local st = ctx.rng:pick(STEPS)
		local s = K.scene(ctx, "On your step"):with({ thing = st.thing })
		burst(s, "a", {
			prickly = "{player}.|There's something on your step.|Don't make a fuss.",
			cheeky = "{player}|go check your step|no it's not a frog",
			shy = "Um, {player}.|There's something on your step.|It's from me. You don't have to like it.",
			foodie = "{player}. Your step.|Now. Before it goes cold.",
			gentle = "{player}, I left you a little something on your step.|It's only small.",
			proud = "{player}. On your doorstep is a gift.|From me. You're welcome.",
			polite = "Good afternoon, {player}.|I've left a small something on your step.|Please don't feel you must return it.",
			_ = "{player}.|I left something on your step.",
		}, "heart")
		s:n("It was {thing}.")
		s:choice("You didn't have to.", function(c)
			burst(c, "a", {
				prickly = "I know.|I had spare. That's all.",
				shy = "I wanted to.|...That's all.",
				proud = "I know. I'm generous.",
				gentle = "I wanted to.|You do so much round here.",
				cheeky = "i know|i'm amazing",
				_ = "I wanted to.",
			}, "heart")
			c:hearts("a", 1)
			c:mood("a", 3)
		end)
		s:choice("Can I eat it?", function(c)
			if st.edible then
				burst(c, "a", {
					foodie = "Yes.|That's the whole point.",
					cheeky = "yes|that's why it's sticky",
					_ = "Yes.|Eat it.",
				}, "laugh", "laugh")
			else
				burst(c, "a", {
					foodie = "No.|I'm surprised too.",
					cheeky = "please don't",
					gloomy = "No.|Of course you'd ask that.",
					_ = "No.|Please don't eat it.",
				}, "laugh", "laugh")
			end
			c:mood("a", 2)
		end)
		s:log("{a} left {thing} on your step.")
		return s:done()
	end,
})

return list
