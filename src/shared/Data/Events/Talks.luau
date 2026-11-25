--!nonstrict
-- Conversations you can watch, longer than a passing word: a long chat over two topics, gossip
-- about a third villager (who may be listening), dreams compared, a squabble that grows and then
-- fizzles out, a silly debate you settle, catching up on the day, moaning about the weather,
-- making plans, a story made up a line each, and the small talk of a town: who waves at you more,
-- a hedgehog on the way home, a tip passed on, sugar borrowed, a sunset, a bad day at work, the
-- wrong coat, a porch in the rain, compliments swapped badly; and the newer ones, a plan made in
-- three voices at once and a message passed on wrong. Built from Data/Events/Chatter's parts, so
-- they come out different each time, and said the way friends text: one natural sentence a
-- message, each in their own voice, and you by your name ({player}) when they turn to you.

local K = require(script.Parent.Kit)
local Chatter = require(script.Parent.Chatter)
local Sayings = require(script.Parent.Parent.Sayings)

local W = K.W
local burst = Chatter.burst
local say = Chatter.say

local list = {}
local function event(def)
	def.actors = def.actors or 2
	table.insert(list, def)
end

-- where each job is done, for "at the café" and the like (Data/Jobs)
local WORKPLACE = {
	shopkeeper = "the market stall",
	barista = "the café",
	baker = "the bakery",
	florist = "the flower cart",
	artist = "the easel",
	doctor = "the clinic",
	teacher = "the school",
	musician = "the stage",
	builder = "the workbench",
	postie = "the post office",
	icecream = "the ice cream cart",
	librarian = "the library",
}

-- a long chat: one topic, then another
event({
	id = "longchat",
	when = "any",
	weight = W({ base = 0.25, rel = 20, traits = { social = 0.4 } }),
	scene = function(ctx, a, b)
		local s = K.scene(ctx, "A long chat")
		local t1, _, d1 = Chatter.chat(ctx, s, a, b)
		local t2 = t1
		while t2 == t1 do
			t2 = ctx.rng:pick(Chatter.Topics)
		end
		s:n("Then they got onto something else.")
		burst(s, "b", {
			sunny = "Wait, wait, that reminds me of something.",
			dreamy = "Hmm... that makes me think of something.",
			bookish = "Actually, that reminds me of something I read.",
			dramatic = "Speaking of which, prepare yourself for this.",
			nervous = "C-can I say something random? Sorry.",
			cheeky = "ok, totally unrelated, but",
			easygoing = "Oh, and also... wait, I forgot what I was going to say, but now I've got it.",
			_ = "Oh, that reminds me.",
		}, "idea")
		Chatter.pick(s, "b", t2.open, "idea", "point")
		if Chatter.agrees(ctx, b, a) then
			Chatter.pick(s, "a", t2.yes, "music")
			Chatter.pick(s, "b", t2.more, "sparkle")
		else
			Chatter.pick(s, "a", t2.no, "question")
			Chatter.pick(s, "b", t2.back, "sweat")
		end
		s:n("An hour went by, and neither of them noticed.")
		s:rel(d1 + 4)
		s:with({ one = t1.about, two = t2.about })
		s:log("{a} and {b} talked for an hour about {one}, and then {two}.")
		return s:done()
	end,
})

-- What there is to say about somebody, from what they're like and what they've been up to.
local DOWN = "{c} has seemed a bit down lately, and I'm a little worried."

local function gossipAbout(ctx, c): { string }
	local v = ctx.v(c)
	local out = {}
	local byPers = {
		sunny = "{c} stopped to chat at every single stall in the market, and it took all morning.",
		gentle = "{c} knitted the bakery cat a little hat, and the cat actually wears it.",
		bold = "{c} raced a gull down the whole length of the pier, and the gull won.",
		dreamy = "{c} sat by the fountain for two hours yesterday, just watching the water.",
		easygoing = "{c} fell asleep at the bus stop, standing up.",
		proud = "{c} has started carrying a little mirror in their top pocket.",
		shy = "{c} waved at me yesterday and then hid behind a bin.",
		cheeky = "{c} swapped all the house numbers on our street, so now I live at number four.",
		cool = "{c} fixed the broken bench by the gate and didn't tell anyone.",
		prickly = "{c} told the gulls off this morning, and the gulls actually listened.",
		dramatic = "{c} stood on a chair at the café just to announce it was lunchtime.",
		bookish = "{c} has read every book in the library, and some of them twice.",
		gloomy = "{c} took an umbrella out on a sunny day, and then it rained on everyone but them.",
		polite = "{c} walked into a lamppost and then said sorry to it.",
		foodie = "{c} has been giving every bun at the bakery a score out of ten in a little notebook.",
		nervous = "{c} checked their door was locked four times this morning, and I counted.",
	}
	table.insert(out, byPers[v.pers] or "{c} has been up to all sorts lately.")
	local hobby = Sayings.hobby(v.hobby)
	if hobby then
		table.insert(out, "{c} has really got into " .. hobby.name .. " lately, and does it every evening.")
	end
	local job = ctx.job(c)
	if job then
		local name = job.job.name:lower()
		local an = if name:match("^[aeiou]") then "an " else "a "
		table.insert(out, "{c} keeps telling everyone that being " .. an .. name .. " is the best job in town.")
	end
	if (v.mood or 50) < 35 then
		table.insert(out, DOWN)
	end
	for _, other in ctx.present do
		if other ~= c and ctx.rel(c, other) >= K.BestFriends then
			table.insert(out, "{c} has a best friend now, and they've even got matching scarves.")
			break
		end
	end
	return out
end

event({
	id = "gossip",
	actors = 3,
	when = "any",
	weight = W({ base = 0.25, count = 3, traits = { social = 0.3, mischief = 0.3 } }),
	scene = function(ctx, a, b, c)
		local s = K.scene(ctx, "Did you hear")
		local said = ctx.rng:pick(gossipAbout(ctx, c))
		local kind = said == DOWN
		burst(s, "a", {
			sunny = "{b}, wait, wait, have you seen {c} lately?",
			gentle = "{b}, have you noticed anything about {c} lately?",
			bold = "{b}, you've seen what {c}'s been up to, right?",
			shy = "Um, {b}?|Have you noticed anything about {c}?",
			proud = "{b}, I need a quick word with you about {c}.",
			cheeky = "psst, {b}, it's about {c}, hehe",
			cool = "{b}. It's about {c}.",
			prickly = "I don't usually gossip, but you have to hear this about {c}.",
			dramatic = "{b}, sit down, because this is about {c}.",
			bookish = "{b}, I've noticed something about {c}, and it's only an observation.",
			gloomy = "{b}, have you seen much of {c} lately?",
			polite = "{b}, may I ask you about {c}? It's nothing unkind.",
			foodie = "{b}, come over here and bring the crisps, because it's about {c}.",
			nervous = "{b}, can I tell you something about {c}?|You won't say I told you, will you?",
			_ = "{b}, have you noticed anything about {c} lately?",
		}, "question")
		say(s, "a", said, "idea", "point")
		if kind then
			burst(s, "b", {
				sunny = "Oh no, really? I'll go and find them later.",
				gentle = "Oh, my. I'll take them some soup tonight.",
				bold = "Has someone upset them? Tell me who.",
				cool = "I'll check on them.",
				prickly = "Hm. I'll go round later, but don't read into it.",
				polite = "Oh dear, we should see if they need anything.",
				foodie = "I'll bake them something, because nobody stays sad near a warm bun.",
				nervous = "Oh no, what if it's something I did?",
				_ = "Now you mention it, yes, we should check on them.",
			}, "sad")
		elseif ctx.rel(b, c) >= 30 then
			burst(s, "b", {
				sunny = "Ehehe, that's so {c}, I love it.",
				gentle = "Oh, that sounds just like {c}, bless them.",
				bold = "Good for {c}, honestly.",
				dreamy = "Hmm... I think I'd like to try that too.",
				easygoing = "Heh, fair enough.",
				proud = "I'd never do that myself, but it's very {c}.",
				shy = "Oh... I think that's nice, actually.",
				cheeky = "hahaha, that is so {c}",
				cool = "Sounds like {c}.",
				dramatic = "That is the most {c} thing I've EVER heard.",
				bookish = "That fits, because {c} always throws themselves into things.",
				gloomy = "Huh, good for them, someone's having fun.",
				polite = "How lovely, good for {c}.",
				_ = "That's just {c} being {c}, and I like that about them.",
			}, "heart")
		else
			burst(s, "b", {
				bold = "So what?",
				dreamy = "Hmm... I wonder why.",
				easygoing = "Huh, okay.",
				proud = "I've always said {c} was a bit odd.",
				shy = "Oh, um, okay.",
				cheeky = "tell me more, tell me everything",
				cool = "Okay.",
				prickly = "That's none of my business, but what else?",
				dramatic = "No, really? Go on.",
				gloomy = "Figures.",
				_ = "Really? I didn't know that.",
			}, "question")
		end
		if ctx.rng:chance(0.35) then
			s:n("Then {c} came round the corner.")
			burst(s, "c", {
				bold = "Are you two talking about me? Say it to my face.",
				proud = "Talking about me, are you? Naturally.",
				shy = "Um... were you talking about me?",
				cool = "Hm? What about me?",
				prickly = "I can hear you, you know.",
				dramatic = "My ears are burning, so who's talking about me?",
				nervous = "Wait, was that about me? Was it bad?",
				cheeky = "talking about me? good",
				_ = "Were you talking about me?",
			}, "question")
			if kind then
				say(s, "a", "We were only worried about you, that's all.", "heart")
				s:voice("c", "thanks", "heart")
				s:relx("a", "c", 6)
				s:relx("b", "c", 4)
			else
				burst(s, "a", {
					cheeky = "lampposts, we were talking about lampposts",
					proud = "We were, and it was mostly nice things.",
					shy = "N-no, it was nothing, sorry.",
					polite = "We were, and I apologise, but it was nothing unkind.",
					cool = "Yes.",
					_ = "No, we were talking about... lampposts.",
				}, "sweat")
				s:voice("c", "angry", "anger")
				s:relx("a", "c", -5)
				s:relx("b", "c", -2)
			end
		else
			s:relx("a", "b", 4)
		end
		s:log("{a} and {b} talked about {c}.")
		return s:done()
	end,
})

event({
	id = "dreamtalk",
	cutscene = "dream",
	when = "day",
	weight = W({ base = 0.18, traits = { focus = -0.3 } }),
	scene = function(ctx, a, b)
		local d1 = ctx.rng:pick(Chatter.Dreams)
		local d2 = d1
		while d2 == d1 do
			d2 = ctx.rng:pick(Chatter.Dreams)
		end
		local s = K.scene(ctx, "Last night's dreams"):with({ one = d1, two = d2 })
		burst(s, "a", {
			dreamy = "Hmm... I had the strangest dream.|I dreamed {one}, and part of me is still there.",
			nervous = "I had the oddest dream last night.|I dreamed {one}, and I woke up so confused.",
			cheeky = "ok so last night I dreamed {one}",
			_ = "I had such a strange dream last night.|I dreamed {one}.",
		}, "zzz")
		burst(s, "b", {
			proud = "Mine was better, I dreamed {two}.",
			shy = "Um, I dreamed {two}.|Is that weird?",
			dreamy = "Hmm... last week I dreamed {two}.",
			sunny = "Mine was even weirder, I dreamed {two}!",
			easygoing = "Heh, I dreamed {two}, and then I slept in.",
			cool = "I dreamed {two}. Then I woke up hungry.",
			dramatic = "Mine was a whole saga, I dreamed {two}.",
			gloomy = "I dreamed {two}, and then my alarm went off.",
			bookish = "I dreamed {two}, and I wrote it all down the moment I woke up.",
			foodie = "I dreamed {two}, and there was gravy on everything.",
			nervous = "I dreamed {two}, and when I woke up I checked the door was locked.",
			_ = "That's nothing, I dreamed {two}.",
		}, "zzz")
		burst(s, "a", {
			dreamy = "Maybe our dreams know each other.",
			bold = "Okay, yours wins, but only this time.",
			cheeky = "what did you eat before bed, because i want some",
			bookish = "Dreams are your brain tidying up, and yours needed a big tidy.",
			gloomy = "Mine never mean anything, but yours might.",
			_ = "What do you think it means?",
		}, "question")
		s:voice("b", ctx.rng:pick({ "hmm", "laugh" }), "question")
		s:rel(6)
		s:log("{a} and {b} compared their dreams.")
		return s:done()
	end,
})

-- a squabble that grows, then fizzles out
local FIZZLE = {
	"A duck walked right between them, and they both stopped to watch it go.",
	"A gull landed on the bench and took half of {a}'s sandwich.",
	"The town hall bell rang, and they both lost their place.",
	"Someone walked past carrying a very large cake.",
}

event({
	id = "spat",
	when = "day",
	weight = W({ base = 0.2, quarrel = "any", traits = { temper = 0.6 } }),
	scene = function(ctx, a, b)
		local s = K.scene(ctx, "A squabble"):with({ thing = ctx.rng:pick(Chatter.Spats) })
		s:n("{a} and {b} started arguing about {thing}.")
		burst(s, "a", {
			dramatic = "It was you, and the whole town knows it was you.",
			prickly = "Ugh, it was obviously you.",
			nervous = "It was you, wasn't it?|I-I checked, and it wasn't me.",
			cheeky = "it was you, everyone saw",
			_ = "It was you, and everyone knows it.",
		}, "anger", "point")
		burst(s, "b", {
			cool = "No, it wasn't.",
			gloomy = "Of course it's my fault, everything is.",
			bookish = "Actually, if you go through it in order, it was you.",
			proud = "Me? Never.",
			_ = "Me? It was obviously you.",
		}, "anger")
		s:voice("a", "angry", "anger")
		s:voice("b", "angry", "anger")
		if K.isPers(ctx, a, "proud", "bold", "prickly") or K.isPers(ctx, b, "proud", "bold", "prickly") then
			s:say("a", "I'm not saying another word.", "anger")
			s:say("b", "Good.", "anger")
			s:say("a", "...It was you, though.", "anger")
		end
		s:n(ctx.rng:pick(FIZZLE))
		s:say("b", "...What were we even arguing about?", "question")
		burst(s, "a", {
			foodie = "No idea, but do you want half my bun?",
			prickly = "It doesn't matter. Do you want a biscuit?",
			cool = "I forgot. Do you want some tea?",
			_ = "No idea. Do you want a biscuit?",
		}, "heart")
		s:rel(2)
		s:log("{a} and {b} argued about {thing}, then forgot why.")
		return s:done()
	end,
})

event({
	id = "debate",
	when = "any",
	weight = W({ base = 0.2, traits = { social = 0.2 } }),
	scene = function(ctx, a, b)
		local d = ctx.rng:pick(Chatter.Debates)
		local s = K.scene(ctx, "A big question"):with({ q = d.q })
		s:say("a", "{q}", "question", "point")
		s:say("a", d.yes, "idea")
		s:say("b", d.no, "anger")
		burst(s, "a", {
			sunny = "{player}, help, you decide!",
			dramatic = "{player}, only you can end this.",
			polite = "{player}, I'm sorry to drag you into this, but what do you think?",
			nervous = "Um, {player}?|C-could you say which of us is right? Gently?",
			cheeky = "{player}, tell them they're wrong",
			cool = "{player}. Settle it, please.",
			_ = "{player}, you decide.",
		}, "question")
		s:choice("I think {a}'s right.", function(c)
			c:voice("a", "brag", "sparkle", "cheer")
			c:voice("b", "no", "anger")
			c:mood("a", 3)
			c:mood("b", -2)
		end)
		s:choice("I'm with {b} on this one.", function(c)
			c:voice("b", "brag", "sparkle", "cheer")
			c:voice("a", "no", "anger")
			c:mood("b", 3)
			c:mood("a", -2)
		end)
		s:choice("You're both wrong, sorry.", function(c)
			c:n("{a} and {b} looked at each other, then at you.")
			say(c, "b", "Well, now we agree on something.|You're the one who's wrong, {player}.", "laugh", "laugh")
			c:rel(8)
		end)
		s:log("{a} and {b} argued about a big question: {q}")
		return s:done()
	end,
})

-- catching up: what they've each been up to (the last event they were in, if it's fresh)
event({
	id = "catchup",
	when = "any",
	weight = W({ base = 0.3, rel = 10 }),
	scene = function(ctx, a, b)
		local s = K.scene(ctx, "Catching up")
		local va, vb = ctx.v(a), ctx.v(b)
		-- What each of them has to tell: the last thing that happened to them (their memo) when it
		-- isn't said to the player, or else a piece of news of their own.
		local you = ctx.f("{player}")
		local function news(v): string?
			local m = v.memo and v.memo.text
			if m and not string.find(m, you, 1, true) and not string.find(" " .. string.lower(m), "%Wyou") then
				return m
			end
			local lines = K.sceneLines(v.pers, "happy")
			return if #lines > 0 then ctx.f(ctx.rng:pick(lines)) else nil
		end
		local saysB, saysA = news(vb), news(va)
		burst(s, "a", {
			sunny = "So what's new? Tell me everything!",
			cool = "What's new with you?",
			bookish = "So what have you been up to? Start from the beginning.",
			foodie = "What's new with you, apart from lunch?",
			gentle = "How have you been? Really, I mean.",
			cheeky = "ok, spill",
			_ = "So what's new with you?",
		}, "question")
		if saysB then
			s:say("b", saysB, "music")
		else
			s:say("b", "Not much, really. What about you?", "question")
		end
		if saysA then
			s:say("a", saysA, "music")
		end
		s:voice("b", "laugh", "music", "laugh")
		s:rel(5)
		s:log("{a} and {b} caught up on their news.")
		return s:done()
	end,
})

local MOANS = {
	rain = {
		"It's rained for so long that my socks have given up.",
		"It's rained so much that my umbrella's gone floppy.",
	},
	storm = {
		"That thunder's been going since breakfast.",
		"The wind took my hat this morning, and now it's in the sea.",
	},
	snow = { "It's so cold I can't feel my nose.", "My front door froze shut, so I had to climb out the window." },
	clear = {
		"The sun's been in my eyes everywhere I go today.",
		"There hasn't been a single cloud all day, and I've burnt my nose.",
	},
	cloudy = { "This weather can't make up its mind.", "It's been grey for three days in a row now." },
	blossom = {
		"There are petals everywhere, and one landed in my tea.",
		"I've sneezed nine times today because of all the blossom.",
	},
	leaves = {
		"I swept my step, and it's already covered in leaves again.",
		"A leaf blew straight into my face on the way here.",
	},
}

event({
	id = "moan",
	when = "any",
	weight = W({ base = 0.2 }),
	scene = function(ctx, a, b)
		local lines = MOANS[ctx.weather] or MOANS.cloudy
		local s = K.scene(ctx, "This weather")
		Chatter.pick(s, "a", lines, "sweat")
		burst(s, "b", {
			sunny = "Ehehe, it's not that bad... okay, it's a bit bad.",
			proud = "Hmph, weather has never bothered me.",
			easygoing = "I just stay in when it's like this, problem solved.",
			gentle = "Come in and have something warm, okay?",
			cheeky = "i like it, everyone's grumpy except me",
			bold = "It's only weather, you'll live.",
			shy = "Um... yes, it's a lot.",
			dreamy = "Hmm... I like it, everything looks a bit different.",
			cool = "It could be worse.",
			prickly = "Moaning won't fix it. ...It is awful, though.",
			dramatic = "The sky has it in for us, personally.",
			bookish = "Actually, I keep a weather chart, and this is the worst week since spring.",
			gloomy = "It'll be worse tomorrow, as usual.",
			polite = "It is trying, isn't it? Would you like to share my umbrella?",
			foodie = "This is exactly what soup is for.",
			nervous = "Do you think it'll get worse? Should I bring my washing in?",
			_ = "Don't get me started.",
		}, "question")
		s:voice("a", "laugh", "music")
		s:rel(4)
		s:log("{a} and {b} moaned about the weather.")
		return s:done()
	end,
})

local PLANS = {
	"a trip to the little islet",
	"a picnic on the hill",
	"a night of board games",
	"a walk along the whole beach",
	"a baking day",
}

event({
	id = "plans",
	when = "day",
	weight = W({ base = 0.18, rel = 25 }),
	scene = function(ctx, a, b)
		local s = K.scene(ctx, "Making plans"):with({ plan = ctx.rng:pick(PLANS) })
		burst(s, "a", {
			sunny = "We should do {plan} this week, for real this time!",
			bold = "You and me are doing {plan} this week, right?",
			shy = "Um, would you want to do {plan} this week?|Only if you're free.",
			_ = "We should do {plan} this week.",
		}, "idea", "point")
		burst(s, "b", {
			easygoing = "Sure, as long as it's not too early.",
			proud = "I'll plan it, and my plans never go wrong.",
			bold = "Why wait for this week? Let's do it today.",
			cool = "Sure.",
			nervous = "Which day this week? I need to write it down.",
			dramatic = "Yes, and it'll be the event of the season.",
			foodie = "I'll do the food, obviously.",
			gloomy = "It'll rain, but okay.",
			_ = "Yes, let's actually do it this time.",
		}, "music")
		s:say("a", "We always say that, though.", "sweat")
		s:say("b", "This time we mean it.", "heart")
		s:rel(5)
		s:memo("a", "{b} and I are planning {plan}, and this time we're actually doing it.")
		s:log("{a} and {b} planned {plan}.")
		return s:done()
	end,
})

-- a story made up a line each
local STORY = {
	start = {
		"Once there was a goose who wanted to run the town.",
		"Once, a very small boat set off to find the edge of the sea.",
		"Long ago, the oven at the bakery started talking.",
		"There was once a lighthouse that was scared of the dark.",
	},
	middle = {
		"On the way, it met a crab who owed it money.",
		"Then it rained for a hundred years, mostly on Tuesdays.",
		"Then everyone in town turned into spoons, except Gerald.",
		"So it hid in a teapot and waited for spring.",
		"Then a whale came along and asked for directions.",
	},
	finish = {
		"And they all had cake, the end.",
		"And that's why the gulls are so rude, the end.",
		"And it's still out there if you look, the end.",
		"Then they woke up, and it had all been a dream, the end.",
	},
}

event({
	id = "storycircle",
	actors = 3,
	when = "any",
	weight = W({ base = 0.12, count = 3, traits = { focus = -0.2 } }),
	scene = function(ctx, a, b, c)
		local s = K.scene(ctx, "A story, a line each")
		say(s, "a", "Let's make up a story, a line each, and I'll start.", "idea")
		s:pick("a", STORY.start, "music")
		s:pick("b", STORY.middle, "music")
		s:pick("c", STORY.middle, "music")
		s:pick("a", STORY.finish, "sparkle")
		burst(s, "b", {
			proud = "That was mostly my line, really.",
			dreamy = "Hmm... I'd like to live in that story.",
			bookish = "We should write it down, and I'll tidy up the middle.",
			dramatic = "That was a masterpiece, and I'm actually moved.",
			cheeky = "that made no sense at all, again",
			_ = "That made no sense at all, again.",
		}, "laugh", "laugh")
		s:relx("a", "b", 4)
		s:relx("a", "c", 4)
		s:relx("b", "c", 4)
		s:log("{a}, {b} and {c} made up a story together.")
		return s:done()
	end,
})

-- advice about a worry, in the friend's own way
event({
	id = "advice",
	when = "any",
	weight = W({ base = 0.18, rel = 15, traits = { brave = -0.3 } }),
	scene = function(ctx, a, b)
		local s = K.scene(ctx, "Some advice")
		s:voice("a", "worry", "sweat")
		s:say("a", "What would you do if you were me?", "question")
		burst(s, "b", {
			sunny = "Don't think about it so hard, and come for a walk with me instead!",
			gentle = "Let me put the kettle on first, and then tell me all of it, okay?",
			bold = "Stop worrying and just do it, that's what I do.",
			dreamy = "I'd go and look at the sea for a while... things seem smaller after that.",
			easygoing = "Have a nap, and if it's still there when you wake up, then worry.",
			proud = "Do what I'd do, because it usually works out for me.",
			shy = "Um, I'd probably hide...|But you're braver than me, so you'll be okay.",
			cheeky = "put a whoopee cushion on it, problems hate that",
			cool = "Sleep on it, then decide in the morning.",
			prickly = "You're overthinking it, so ask me again tomorrow if it still feels bad.",
			dramatic = "Face it head on, like a ship in a STORM.",
			bookish = "Actually, writing it all down helps, because things look smaller on paper.",
			gloomy = "It might go wrong or it might not, but either way I'll be there.",
			polite = "If I may, I'd ask someone you trust, and I hope that's me.",
			foodie = "Eat something first, because nobody makes good decisions hungry.",
			nervous = "I'd worry too, so let's worry together and then make a list.",
		}, "idea")
		s:choice("That's good advice.", function(c)
			c:voice("a", "thanks", "heart")
			c:rel(7)
			c:mood("a", 4)
		end)
		s:choice("Maybe ask someone else too.", function(c)
			burst(c, "b", {
				proud = "Someone else? Who else is there?",
				shy = "Oh... yes, that's a better idea.",
				gentle = "That's sensible, so ask as many people as you like.",
				prickly = "Fine, but they'll say the same thing.",
				polite = "Of course, that's very wise.",
				cheeky = "rude, but fair",
				_ = "That's a bit rude, but fair.",
			}, "sweat")
			c:say("a", "Thanks anyway, I mean it.", "heart")
			c:rel(3)
			c:mood("a", 2)
		end)
		s:log("{a} asked {b} for advice.")
		return s:done()
	end,
})

-- a pep talk for somebody who's down
event({
	id = "peptalk",
	when = "day",
	weight = W({
		base = 0.15,
		rel = 10,
		cond = function(ctx, a)
			return (ctx.v(a).mood or 50) < 55
		end,
	}),
	scene = function(ctx, a, b)
		local s = K.scene(ctx, "A pep talk")
		s:n("{a} has been sitting on the steps with their head in their hands.")
		s:voice("a", "sad", "sad")
		burst(s, "b", {
			bold = "Come on, up you get, because you're the toughest person I know after me.",
			sunny = "Hey, budge up, because whatever it is, you've got me.",
			gentle = "Come here... it'll look smaller tomorrow, it always does.",
			cheeky = "do you want me to cheer you up, or prank whoever did this?",
			shy = "Um, I brought you a biscuit.|We don't have to talk.",
			proud = "Chin up, people can see you. Well, I can see you.",
			dreamy = "Do you want to watch the clouds with me? They don't ask questions.",
			easygoing = "Hey, I'll sit with you, and we don't have to do anything.",
			cool = "Move over. I'll sit with you.",
			prickly = "Budge up, because I'm not leaving until you're okay.",
			dramatic = "No sad faces on my watch, so tell me who I'm cross with.",
			bookish = "Can I sit with you? I promise I won't say anything clever.",
			gloomy = "Bad day? Me too, so let's be gloomy together.",
			polite = "May I sit with you a while? Only if you'd like.",
			foodie = "I've got two pastries, and you look like you need one.",
			nervous = "Are you okay?|Tell me how I can help, please.",
			_ = "Do you want to go for a walk? It might help.",
		}, "heart")
		s:voice("a", "thanks", "heart")
		s:rel(8)
		s:mood("a", 8)
		s:log("{b} cheered {a} up.")
		return s:done()
	end,
})

-- newer ones -----------------------------------------------------------------------------------------

-- who waves at you more: they've been counting, and want your say
event({
	id = "whowaves",
	when = "day",
	weight = W({ base = 0.12, rel = 0, traits = { social = 0.2 } }),
	scene = function(ctx, a, b)
		local s = K.scene(ctx, "Who waves more")
		burst(s, "a", {
			sunny = "{player}! Quick, we need you to settle something.",
			proud = "{player}, there's a small matter we need you to settle.",
			shy = "Um, {player}?|Could you settle something for us?",
			cheeky = "{player}, you have to settle this",
			cool = "{player}. We need you to settle something.",
			polite = "Sorry to bother you, {player}, but could you settle something for us?",
			_ = "{player}, can you settle something for us?",
		}, "question", "wave")
		s:say("a", "We've been keeping count, and we want to know which of us waves at you more.", "question")
		burst(s, "b", {
			bold = "It's me, right? Say it's me.",
			dramatic = "Think carefully, because this matters more than you know.",
			gloomy = "It's {a}, isn't it? It's always {a}.",
			nervous = "Y-you don't have to answer, unless you want to.",
			foodie = "Whoever loses is buying the buns, just so you know.",
			_ = "Be honest, we can take it.",
		}, "sweat")
		local SULK = {
			sunny = "Aww, I'll just have to wave harder tomorrow.",
			gentle = "Oh well, well done, I mean that.",
			shy = "Oh... that's okay.",
			gloomy = "I knew it.",
			prickly = "Whatever, my waves are better quality.",
			polite = "Fair enough, well done.",
			foodie = "Fine, I'll buy the buns.",
			cheeky = "rigged!",
			_ = "Hmph, I'm waving twice tomorrow.",
		}
		s:choice("{a} waves more.", function(c)
			c:voice("a", "brag", "sparkle", "cheer")
			burst(c, "b", SULK, "sweat")
			c:mood("a", 3)
			c:mood("b", -1)
		end)
		s:choice("{b} waves more.", function(c)
			c:voice("b", "brag", "sparkle", "cheer")
			burst(c, "a", SULK, "sweat")
			c:mood("b", 3)
			c:mood("a", -1)
		end)
		s:choice("I wave back at both of you.", function(c)
			c:n("{a} and {b} looked at each other.")
			c:say("a", "That's such a {player} answer.", "laugh", "laugh")
			c:say("b", "It's annoyingly fair, though.", "heart")
			c:rel(5)
			c:mood("a", 2)
			c:mood("b", 2)
		end)
		s:log("{a} and {b} asked who waves at you more.")
		return s:done()
	end,
})

-- a rustle in the hedge on the way home
event({
	id = "nightwalk",
	when = "night",
	weight = W({ base = 0.15, rel = 0 }),
	scene = function(ctx, a, b)
		local s = K.scene(ctx, "On the way home")
		s:n("{a} and {b} are walking home late, past the dark end of the park.")
		burst(s, "b", {
			nervous = "D-did you hear that? Tell me you heard that.",
			shy = "Um... there's something in the hedge.",
			dramatic = "*gasp* Something is moving in that hedge.",
			gloomy = "There's something in the hedge, so this is how it ends.",
			bold = "Something's moving in the hedge, so stay behind me.",
			_ = "Shh, there's something in the hedge.",
		}, "sweat")
		s:n("The hedge rustled, and out came a hedgehog, very slowly.")
		burst(s, "a", {
			cool = "It's a hedgehog.",
			bookish = "Hedgehogs come out at night, so that's perfectly normal.",
			sunny = "Aww, hello, little one, you gave us such a fright!",
			cheeky = "hehe, you should've seen your face, {b}",
			prickly = "It's a hedgehog, calm down. ...It is quite sweet, though.",
			foodie = "Do you think it's after the crumbs in my pocket? It can have them.",
			_ = "Oh, hello, you.",
		}, "heart")
		s:voice("b", "laugh", "music", "laugh")
		s:rel(6)
		s:memo("b", "A hedgehog lives in the park hedge, and it gave me such a fright. It's sweet, really.")
		s:log("{a} and {b} met a hedgehog on the way home.")
		return s:done()
	end,
})

-- a tip passed on, and tried
local RECS = {
	"the soup at the café",
	"the bench by the harbour at sunset",
	"the path along the cliffs",
	"the big window seat in the library",
	"the cinnamon buns on a Tuesday",
}

event({
	id = "recommend",
	when = "day",
	weight = W({ base = 0.14, rel = 5 }),
	scene = function(ctx, a, b)
		local rec = ctx.rng:pick(RECS)
		local s = K.scene(ctx, "You have to try it"):with({ rec = rec })
		burst(s, "a", {
			foodie = "{b}, you have to try {rec}, and I'll come with you.",
			bookish = "Have you tried {rec}? I've got a whole list of reasons you should.",
			cool = "Try {rec}. It's good.",
			sunny = "You have to try {rec}, promise me!",
			dramatic = "{b}, {rec} will change your LIFE.",
			_ = "You have to try {rec}, trust me.",
		}, "idea", "point")
		burst(s, "b", {
			prickly = "Fine, but if it's bad, I'm telling you.",
			nervous = "What if I don't like it, though?",
			easygoing = "Sure, I'll get round to it sometime.",
			polite = "I'd be glad to, thank you for thinking of me.",
			gloomy = "It'll be closed, it always is when I go.",
			_ = "Okay, I'll give it a try.",
		}, "question")
		s:n("The next day, {b} went and tried it.")
		burst(s, "b", {
			prickly = "...It was good, so don't look at me like that.",
			gloomy = "It was open, and it was good, which never happens to me.",
			dramatic = "It changed my life, and I'm a new person!",
			cool = "Good call.",
			_ = "You were right, annoyingly.",
		}, "heart")
		s:rel(6)
		s:memo("b", "{a} told me to try {rec}, and they were right, but don't tell them I said so.")
		s:log("{a} told {b} to try {rec}.")
		return s:done()
	end,
})

-- a cup of sugar, and an hour of news
event({
	id = "borrowsugar",
	when = "day",
	weight = W({ base = 0.14, rel = -10, traits = { social = 0.2 } }),
	scene = function(ctx, a, b)
		local s = K.scene(ctx, "A cup of sugar")
		s:n("{b} knocked on {a}'s door to borrow a cup of sugar.")
		burst(s, "b", {
			polite = "Sorry to bother you, but might I borrow a cup of sugar? I'll bring it back.",
			foodie = "It's a sugar emergency, and I'm halfway through a cake.",
			shy = "Um, sorry... do you have any sugar I could borrow?",
			cool = "Have you got any sugar? I've run out.",
			nervous = "Hi, sorry, I'm out of sugar, and I checked twice.",
			_ = "Hi, I've run out of sugar, have you got any?",
		}, "question")
		burst(s, "a", {
			gentle = "Come in, come in, and sit down while I find it.",
			sunny = "Sugar? Sure, come in, and have you heard about the gulls?",
			prickly = "Fine, come in, but don't touch anything.",
			gloomy = "Come in, and mind the mess, there's always a mess.",
			_ = "Come in, it's in here somewhere.",
		}, "heart")
		s:n("An hour later, {b} left with the sugar, a slice of pie and all the news.")
		burst(s, "b", {
			foodie = "My cake... it's still sitting in the bowl at home.",
			nervous = "Oh no, oh no, did I leave my oven on?",
			_ = "Oh no, I completely forgot about the cake.",
		}, "sweat")
		s:rel(7)
		s:log("{b} borrowed sugar from {a} and stayed an hour.")
		return s:done()
	end,
})

-- the harbour bench at sundown
event({
	id = "sunsetbench",
	when = "day",
	weight = W({
		base = 0.15,
		rel = 15,
		weather = { "clear", "cloudy", "blossom", "leaves" },
		cond = function(ctx)
			return ctx.hour >= 16
		end,
	}),
	scene = function(ctx, a, b)
		local s = K.scene(ctx, "Sundown")
		s:n("{a} and {b} are on the bench by the harbour, watching the sun go down.")
		burst(s, "a", {
			cool = "That's nice.",
			dreamy = "Hmm... the sea's gone gold, like someone spilled tea in it.",
			gloomy = "It'll be dark soon... it's nice, though.",
			dramatic = "Look at that, the whole sky, just for us.",
			bookish = "Did you know the light has further to travel at sunset? That's why it goes red.",
			foodie = "It looks like the top of a peach tart.",
			_ = "Look at that sky.",
		}, "heart")
		burst(s, "b", {
			sunny = "It's so pretty, I want to remember it.",
			gentle = "Oh, my, it's lovely, isn't it?",
			bold = "That's not bad at all.",
			dreamy = "Hmm... I could watch this every evening.",
			easygoing = "Mm, this is the best seat in town.",
			proud = "I'd say it's the best sunset all year.",
			shy = "...It's really pretty.",
			cheeky = "ok, that's actually nice",
			cool = "Yeah. It's good.",
			prickly = "Fine, it's nice, so don't make it a thing.",
			dramatic = "I might cry, honestly.",
			bookish = "I'm going to write down all the colours when I get home.",
			gloomy = "It won't last, but it's nice while it does.",
			polite = "It's lovely, thank you for sitting with me.",
			foodie = "It's the exact colour of apricot jam.",
			nervous = "It's so quiet out here... in a good way, I mean.",
			_ = "It's lovely.",
		}, "heart")
		s:n("Neither of them said much after that, and a boat went by.")
		burst(s, "a", {
			prickly = "Same time tomorrow, and don't be late.",
			nervous = "Same time tomorrow? I-if that's okay?",
			_ = "Same time tomorrow?",
		}, "heart")
		s:rel(6)
		s:log("{a} and {b} watched the sun go down from the harbour bench.")
		return s:done()
	end,
})

-- somebody listens after a long day at work
event({
	id = "badshift",
	when = "any",
	weight = W({ base = 0.14, job = "any", rel = 0 }),
	scene = function(ctx, a, b)
		local w = ctx.job(a)
		local place = if w then WORKPLACE[w.job.id] or "work" else "work"
		local s = K.scene(ctx, "A long day"):with({ work = place })
		burst(s, "a", {
			gloomy = "Today at {work} was awful, and then it got worse, as usual.",
			dramatic = "Today at {work} was a DISASTER, so let me start from the beginning.",
			nervous = "I think I got something wrong at {work}, and I keep going over it.",
			proud = "Today at {work} was not my finest, so tell no one.",
			prickly = "Ugh, don't ask me about {work}.",
			sunny = "Today at {work} was rubbish from start to finish.",
			_ = "It was a long day at {work}.",
		}, "sad")
		burst(s, "b", {
			gentle = "Oh, my... come here and tell me all of it.",
			foodie = "Sit down and eat this first, then tell me.",
			cool = "Do you want to talk, or just sit quietly?",
			bookish = "Did it actually go wrong, or does it just feel like it did? Those are different.",
			polite = "I'm so sorry, what can I do?",
			cheeky = "want me to go and pull a face at {work} for you?",
			_ = "Do you want to talk about it?",
		}, "heart")
		s:n("{a} talked, and {b} listened and nodded in the right places.")
		burst(s, "a", {
			prickly = "...Fine, thanks, that helped.",
			cool = "Thanks.",
			_ = "Thanks, that actually helped.",
		}, "heart")
		s:rel(6)
		s:mood("a", 5)
		s:log("{b} listened to {a} after a long day at work.")
		return s:done()
	end,
})

-- the wrong coats
event({
	id = "wrongcoat",
	when = "day",
	weight = W({
		base = 0.1,
		rel = 5,
		cond = function(ctx)
			return ctx.season == 3 or ctx.season == 4 or ctx.weather == "rain"
		end,
	}),
	scene = function(ctx, a, b)
		local s = K.scene(ctx, "The wrong coat")
		s:n("{a} and {b} left the café in a hurry and each went home in the other's coat.")
		s:say("a", "This coat smells of peppermints, and I don't think it's mine.", "question")
		s:say("b", "There are seven pencils in this pocket, so this one must be yours.", "question")
		burst(s, "a", {
			bookish = "I like to carry a spare pencil, or six.",
			cheeky = "those are emergency pencils, ok",
			nervous = "What if I need to write something down in a hurry?",
			_ = "Those are my pencils, so I'll have them back, please.",
		}, "sweat")
		burst(s, "b", {
			foodie = "And those peppermints are mine, so I'll be needing them.",
			_ = "Shall we swap back at the café tomorrow?",
		}, "laugh", "laugh")
		s:rel(4)
		s:log("{a} and {b} went home in each other's coats.")
		return s:done()
	end,
})

-- stuck under a porch
event({
	id = "rainporch",
	when = "any",
	weight = W({ base = 0.3, weather = { "rain", "storm" } }),
	scene = function(ctx, a, b)
		local s = K.scene(ctx, "Under the porch")
		s:n("{a} and {b} are stuck under the same porch, waiting for the rain to stop.")
		s:say("a", "We could just run for it.", "idea")
		burst(s, "b", {
			gloomy = "We'd be soaked in two steps, I've done the maths.",
			bold = "I'd run for it, but it's coming down even harder now.",
			easygoing = "Or we could just stay here, because it's nice under here.",
			nervous = "B-but what if it gets worse halfway?",
			dreamy = "Hmm... listen to it on the roof, like lots of little feet.",
			bookish = "Actually, running only keeps you a little drier, I read a whole article about it.",
			_ = "Or we could wait, because it can't rain forever.",
		}, "question")
		s:n("They waited, and it rained for another hour while they talked about nothing much.")
		burst(s, "a", {
			sunny = "Look, it's stopping, and there's a rainbow over the harbour!",
			bold = "Right, it's easing off, so let's go.",
			dreamy = "Hmm... I'll miss the sound of it on the roof.",
			easygoing = "That was nice, actually, I'd do it again.",
			cool = "It's stopped. Let's go.",
			dramatic = "We SURVIVED.",
			gloomy = "It's stopped... until we're halfway home, I bet.",
			nervous = "I-it's stopped, so let's go before it starts again.",
			_ = "I think it's easing off, so shall we go?",
		}, "music", "laugh")
		s:rel(6)
		s:log("{a} and {b} waited out the rain under a porch.")
		return s:done()
	end,
})

-- compliments, swapped badly
event({
	id = "compliments",
	when = "day",
	weight = W({ base = 0.12, rel = 10 }),
	scene = function(ctx, a, b)
		local s = K.scene(ctx, "A nice thing to say")
		burst(s, "a", {
			sunny = "Okay, I have to say it, your hat today is perfect.",
			shy = "Um, I like your scarf.|That's all, bye... wait, no, sorry.",
			cool = "That's a good jacket.",
			prickly = "Your hair looks fine today, so don't make it weird.",
			polite = "If I may say so, you look very smart today.",
			dramatic = "That colour on you! I had to stop walking.",
			_ = "I like your jumper, I just wanted to say.",
		}, "heart")
		burst(s, "b", {
			proud = "I know, but thank you.",
			shy = "Oh... oh no, thank you.|Where do I put my hands?",
			gloomy = "Really? Huh, nobody ever says that.",
			bookish = "Thank you, I've had it six years, actually.",
			nervous = "Really? You're not just saying that?",
			_ = "Oh, thanks.",
		}, "sparkle")
		burst(s, "b", {
			cheeky = "and your shoes are... shoes, lovely shoes",
			cool = "Your shoes are fine too.",
			_ = "And your, um... your shoes are nice.",
		}, "sweat")
		s:voice("a", "laugh", "music", "laugh")
		s:rel(5)
		s:log("{a} and {b} swapped compliments, badly.")
		return s:done()
	end,
})

-- three of them make a plan for tomorrow, all talking at once
local OUTINGS = {
	{ what = "a swim at the cove", bring = "the towels" },
	{ what = "breakfast on the hill", bring = "the big flask" },
	{ what = "kites on the beach", bring = "the string" },
	{ what = "a walk to the lighthouse", bring = "proper shoes" },
}

event({
	id = "tomorrowplan",
	actors = 3,
	when = "any",
	weight = W({ base = 0.11, count = 3, traits = { social = 0.2 } }),
	scene = function(ctx, a, b, c)
		local o = ctx.rng:pick(OUTINGS)
		local s = K.scene(ctx, "Tomorrow"):with({ what = o.what, bring = o.bring })
		burst(s, "a", {
			sunny = "Okay, okay, tomorrow we're all doing {what}!",
			bold = "Tomorrow it's {what} at nine sharp, and everyone's coming.",
			dramatic = "Tomorrow we do {what}, and it has been DECIDED.",
			shy = "Um, I was thinking...|Would anyone want to do {what} tomorrow? Only if you want.",
			_ = "Does anyone fancy {what} tomorrow?",
		}, "idea", "point")
		burst(s, "b", {
			easygoing = "How early is early? I'm asking for me.",
			nervous = "What time? What if it rains?|I'll bring a coat, maybe two.",
			foodie = "I'll do the snacks, so nobody else bring any.",
			cool = "I'm in.",
			prickly = "Fine, but I'm not carrying anything.",
			_ = "I'm in.",
		}, "music")
		burst(s, "c", {
			bookish = "Someone has to bring {bring}, so I'll make a list.",
			gloomy = "It'll rain on us, but I'll still come.",
			proud = "I'll lead the way, since I know the best route.",
			cheeky = "i'm coming, and i'm bringing nothing",
			_ = "Who's bringing {bring}?",
		}, "question")
		s:n("They agreed on everything except the time, and then they agreed on that too.")
		say(s, "a", "Nine o'clock, then, more or less.", "heart")
		s:relx("a", "b", 4)
		s:relx("a", "c", 4)
		s:relx("b", "c", 3)
		s:memo("a", "Tomorrow it's {what} with {b} and {c}, at nine or so.")
		s:log("{a}, {b} and {c} planned {what}.")
		return s:done()
	end,
})

-- a message for one friend that went through another, and changed on the way
local RELAYS = {
	{ said = "bring the ladder", heard = "bring a lobster" },
	{ said = "meet at the pier at two", heard = "eat a pear at two" },
	{ said = "get the cat off the roof", heard = "get the hat off the roof" },
	{ said = "pick up some flour", heard = "pick some flowers" },
}

event({
	id = "relay",
	actors = 3,
	when = "day",
	weight = W({ base = 0.1, count = 3 }),
	scene = function(ctx, a, b, c)
		local r = ctx.rng:pick(RELAYS)
		local s = K.scene(ctx, "Pass it on"):with({ said = r.said, heard = r.heard })
		s:n("{a} asked {b} to tell {c} to {said}, but {b} was eating at the time.")
		burst(s, "c", {
			cool = "{a}, {b} says you want me to {heard}. Why?",
			nervous = "{a}, sorry, quick question...|{b} said you want me to {heard}, is that right?",
			sunny = "{a}! I'm on my way, but {b} said to {heard}, which is a bit odd.",
			polite = "Hello, {a}, {b} passed on your message, and you'd like me to {heard}?",
			_ = "{a}, {b} says you want me to {heard}?",
		}, "question")
		burst(s, "a", {
			prickly = "No, I said {said}. Honestly, {b}.",
			cheeky = "hahaha, no, i said {said}",
			dramatic = "I said {said}, {b}! What have you DONE?",
			_ = "...No, I said {said}.",
		}, "sweat")
		burst(s, "b", {
			foodie = "I had a mouthful of bun, so it's not my fault.",
			gloomy = "Of course I got it wrong.",
			proud = "I passed on exactly what I heard.",
			_ = "In my defence, I was eating.",
		}, "sweat")
		s:voice("c", "laugh", "music", "laugh")
		s:relx("a", "b", 2)
		s:relx("a", "c", 3)
		s:relx("b", "c", 3)
		s:log("{b} passed on a message from {a} to {c}, wrongly.")
		return s:done()
	end,
})

return list
