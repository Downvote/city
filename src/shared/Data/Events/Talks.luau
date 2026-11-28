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

-- a long chat: one topic, then another
event({
	id = "longchat",
	when = "any",
	weight = W({ base = 0.25, rel = 20, traits = { social = 0.4 } }),
	scene = function(ctx, a, b)
		local s = K.scene(ctx, "A long chat")
		local t1, _, d1 = Chatter.chat(ctx, s, a, b, nil, true)
		local t2 = t1
		while t2 == t1 do
			t2 = ctx.rng:pick(Chatter.topics(ctx))
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
			gentle = "Oh, and that reminds me of something else, if you've got a minute.",
			bold = "Right, next thing, I've been meaning to tell you this.",
			proud = "Speaking of which, I had an excellent thought yesterday.",
			shy = "Um, can I say something else? It's a bit random.",
			cool = "Hm, that reminds me of something.",
			prickly = "Ugh, that reminds me, I wanted to complain about something.",
			gloomy = "Heh... that reminds me of something else that went wrong.",
			polite = "If you do not mind, that reminds me of something.",
			foodie = "Oh, that reminds me, and it's about food, sort of.",
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
		shy = "{c} waved at me yesterday and then hid behind a tree.",
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
			cool = "{b}, it's about {c}.",
			prickly = "I don't usually gossip, but you have to hear this about {c}.",
			dramatic = "{b}, sit down, because this is about {c}.",
			bookish = "{b}, I've noticed something about {c}, and it's only an observation.",
			gloomy = "{b}, have you seen much of {c} lately?",
			polite = "{b}, may I ask you about {c}? It's nothing unkind.",
			foodie = "{b}, come over here and bring the snacks, because it's about {c}.",
			nervous = "{b}, can I tell you something about {c}?|You won't say I told you, will you?",
			dreamy = "{b}... have you noticed something different about {c}?",
			easygoing = "{b}, no big deal, but have you heard about {c}?",
			_ = "{b}, have you noticed anything about {c} lately?",
		}, "question")
		say(s, "a", said, "idea", "point")
		if kind then
			burst(s, "b", {
				sunny = "Oh no, really? I'll go and find them later.",
				gentle = "Oh, my. I'll take them some soup tonight.",
				bold = "Has someone upset them? Tell me who.",
				cool = "I'll check on them.",
				prickly = "Ugh, I'll go round later, but don't read into it.",
				polite = "Oh dear, we should see if they need anything.",
				foodie = "I'll bake them something, because nobody stays sad near a warm bun.",
				nervous = "Oh no, what if it's something I did?",
				dreamy = "Oh... I did see them looking at the sea for a long time.|Maybe they need a friend.",
				easygoing = "Huh, really?|Let's go and sit with them later, no fuss.",
				proud = "Down? That won't do.|I'll go and cheer them up, I'm very good at it.",
				shy = "Oh... I didn't notice.|Maybe I could leave them a note?",
				cheeky = "oh no, really?|i'll go and make them laugh, i've got a new joke",
				dramatic = "{c} is feeling DOWN? That's terrible!|We have to do something.",
				bookish = "Actually, I noticed they haven't been to the library in a week.|We should check on them.",
				gloomy = "Heh... I know how that feels.|We should check on them.",
				_ = "Now you mention it, yes, we should check on them.",
			}, "sad")
		elseif ctx.rel(b, c) >= 30 then
			burst(s, "b", {
				sunny = "Ehehe, that's so {c}, I love it.",
				gentle = "Oh, that sounds just like {c}, how sweet of them.",
				bold = "Hah, that's {c} all over.",
				dreamy = "Hmm... that sounds just like them.",
				easygoing = "Heh, fair enough.",
				proud = "I'd never do that myself, but it's very {c}.",
				shy = "Oh... that does sound like {c}.",
				cheeky = "hahaha, that is so {c}",
				cool = "Sounds like {c}.",
				dramatic = "That is the most {c} thing I've EVER heard.",
				bookish = "That fits, because {c} always throws themselves into things.",
				gloomy = "Huh, good for them, someone's having fun.",
				polite = "Oh, that's very like {c}, isn't it?",
				prickly = "Ugh, of course they did.|...It's a bit funny, I'll give them that.",
				foodie = "Ha, that's so {c}.|I'll tell them I heard, over lunch.",
				nervous = "Oh, that's so {c}!|Wait, are we allowed to talk about this?",
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
				sunny = "Really? Ooh, tell me more!",
				gentle = "Oh, I didn't know that.|Good for them, I suppose.",
				bookish = "Interesting.|Actually, that explains a few things.",
				polite = "Oh, I see.|I did not know that.",
				foodie = "Huh, really?|I'll ask them about it over lunch.",
				nervous = "R-really? I had no idea.|Should we be talking about this?",
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
				dramatic = "Somebody's talking about me, I can FEEL it.",
				nervous = "Wait, was that about me? Was it bad?",
				cheeky = "talking about me? good",
				sunny = "Hi, hi! Were you two talking about me?",
				gentle = "Oh, hello, you two.|Were you talking about me?",
				dreamy = "Hmm... did someone say my name?",
				easygoing = "Hey, you two.|Was that my name I heard?",
				bookish = "I heard my name twice, so I'm guessing you were talking about me.",
				gloomy = "Talking about me?|Heh... I can guess what you were saying.",
				polite = "Good afternoon, both of you.|Were you talking about me, by any chance?",
				foodie = "Were you two talking about me?|Is it about the buns I took?",
				_ = "Were you talking about me?",
			}, "question")
			if kind then
				say(s, "a", "We were only worried about you, that's all.", "heart")
				burst(s, "c", {
					sunny = "Aww, you two!|I'm okay, really, but thank you.",
					gentle = "Oh, that's kind of you both.|I'm all right, I promise.",
					bold = "...Thanks. I'm fine, though.",
					dreamy = "Oh... that's nice of you.|I've just been a bit quiet, that's all.",
					easygoing = "Heh, thanks.|I'm all right, just tired.",
					proud = "Worried? About me?|...Well, that's very kind.",
					shy = "Oh... thank you.|I didn't think anyone noticed.",
					cheeky = "aww, you do care|i'm ok, really",
					cool = "...Thanks, I'm all right.",
					prickly = "Ugh, I'm fine.|...But thanks.",
					dramatic = "You were WORRIED about me?|I'm so touched I could cry.",
					bookish = "That's very kind of you.|I've had a lot on my mind, that's all.",
					gloomy = "Heh... nobody's worried about me in ages.|Thanks.",
					polite = "That's very kind of you both.|I'm quite all right, thank you.",
					foodie = "Thanks, you two.|A bun would help, if anyone's offering.",
					nervous = "Y-you were worried? I'm okay, I promise.|...Thank you, though.",
					_ = "Oh, that's kind of you.|I'm all right, really.",
				}, "heart")
				s:relx("a", "c", 6)
				s:relx("b", "c", 4)
			else
				burst(s, "a", {
					cheeky = "lampposts, we were talking about lampposts",
					proud = "We were, and it was mostly nice things.",
					shy = "N-no, it was nothing, sorry.",
					polite = "We were, and I apologise, but it was nothing unkind.",
					cool = "Yes.",
					sunny = "We were! But only nice things, I promise!",
					gentle = "Oh, we were, I'm sorry.|It was nothing bad, I promise.",
					bold = "Yeah, we were.|Nothing bad, though, right?",
					dreamy = "Were we...? Hmm, maybe a little.",
					easygoing = "Eh, maybe a bit.|Nothing bad, though.",
					prickly = "So what if we were?|...Sorry, it was nothing mean.",
					dramatic = "Talking about YOU? We'd never do that!|...Well, maybe a little.",
					bookish = "Technically, yes.|But it was mostly nice things, actually.",
					gloomy = "Yeah, we were.|Heh... sorry about that.",
					foodie = "We were talking about lunch, mostly.|And you, a little.",
					nervous = "N-no! Well, yes, sorry, sorry!",
					_ = "No, we were talking about... lampposts.",
				}, "sweat")
				burst(s, "c", {
					sunny = "Next time, just ask me, okay?|It's not nice being talked about.",
					gentle = "I'd rather you talked to me than about me, all right?",
					bold = "If you've got something to say, say it to me.",
					dreamy = "Hmm... I don't like being talked about.|I'm going for a walk.",
					easygoing = "Eh, talk about me all you like, just not where I can hear it.",
					proud = "Hmph, I'm sure it was fascinating.|I'll leave you to it.",
					shy = "Oh... okay, I'll go, then.",
					cheeky = "rude|i'm telling everyone you two gossip",
					cool = "Hm. Ask me next time.",
					prickly = "Ugh, I heard all of it, you know.",
					dramatic = "Talked about behind my back, in my OWN town!",
					bookish = "For the record, I'd have told you myself if you'd asked.",
					gloomy = "Heh... of course you were.|Carry on, then.",
					polite = "I would prefer you asked me directly, thank you.",
					foodie = "Fine, but I'm not sharing my buns with either of you today.",
					nervous = "Was it bad? It was bad, wasn't it?|...I'm going home.",
					_ = "You could just ask me, you know.",
				}, "anger")
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
			cheeky = "ok so last night i dreamed {one}",
			sunny = "I had the funniest dream last night!|I dreamed {one}!",
			gentle = "I had such a sweet dream last night.|I dreamed {one}.",
			bold = "Listen to this, I dreamed {one} last night.",
			easygoing = "*yawn* I had a weird one last night.|I dreamed {one}.",
			proud = "I had a wonderful dream last night.|I dreamed {one}, and I was brilliant in it.",
			shy = "Um, can I tell you my dream?|I dreamed {one}.",
			cool = "I had a strange dream last night.|I dreamed {one}.",
			prickly = "Don't laugh, but I dreamed {one} last night.",
			dramatic = "I had the most INCREDIBLE dream.|I dreamed {one}!",
			bookish = "I had a very strange dream last night.|I dreamed {one}, which is interesting, actually.",
			gloomy = "I had a weird dream last night.|Heh... I dreamed {one}, of all things.",
			polite = "I had a very strange dream last night.|I dreamed {one}.",
			foodie = "I had a dream last night, and there wasn't even any food in it.|I dreamed {one}.",
			_ = "I had such a strange dream last night.|I dreamed {one}.",
		}, "zzz")
		burst(s, "b", {
			proud = "Mine was better, I dreamed {two}.",
			shy = "Um, I dreamed {two}.|Is that weird?",
			dreamy = "Hmm... last week I dreamed {two}.",
			sunny = "Mine was even weirder, I dreamed {two}!",
			easygoing = "Heh, I dreamed {two}, and then I slept in.",
			cool = "I dreamed {two}. Then I woke up hungry.",
			dramatic = "Mine was like a whole film, I dreamed {two}.",
			gloomy = "I dreamed {two}, and then my alarm went off.",
			bookish = "I dreamed {two}, and I wrote it all down the moment I woke up.",
			foodie = "I dreamed {two}, and there was gravy on everything.",
			nervous = "I dreamed {two}, and when I woke up I checked the door was locked.",
			gentle = "Oh, my, I dreamed {two}.",
			polite = "How funny, I dreamed {two}.",
			prickly = "Ugh, I dreamed {two}, so yours isn't that strange.",
			bold = "Hah, I dreamed {two}.",
			cheeky = "hehe, i dreamed {two}",
			_ = "That's nothing, I dreamed {two}.",
		}, "zzz")
		burst(s, "a", {
			dreamy = "Maybe our dreams know each other.",
			bold = "Okay, yours wins, but only this time.",
			cheeky = "what did you eat before bed, because i want some",
			bookish = "Dreams are your brain tidying up, and yours needed a big tidy.",
			gloomy = "Mine never mean anything, but yours might.",
			sunny = "Ehehe, that's so funny!",
			gentle = "Oh my, that sounds like quite a night.",
			easygoing = "Heh, that's a good one.|I want that dream next time I nap.",
			proud = "Hmph, not bad, but mine was more interesting.",
			shy = "Oh... that's a nice one.",
			cool = "Hm, that's odd.",
			prickly = "Ugh, fine, yours is stranger.",
			dramatic = "That's even BETTER than mine!",
			polite = "How very interesting.",
			foodie = "Did you eat cheese before bed? That always does it.",
			nervous = "Oh no, does that mean something? Does it mean something bad?",
			_ = "What do you think it means?",
		}, "question")
		burst(s, "b", {
			sunny = "Ehehe, let's both dream something normal tonight.",
			gentle = "Let's both have a quiet night tonight, all right?",
			bold = "Hah, I'm having that dream again tonight if I can.",
			dreamy = "Hmm... I hope I dream it again tonight.",
			easygoing = "Either way, I'm having a nap to find out.",
			proud = "Mine was better, and we both know it.",
			shy = "Um, I liked hearing about yours.",
			cheeky = "i'm telling everyone about yours, hehe",
			cool = "Dreams are like that.",
			prickly = "Either way, no more cheese before bed for you.",
			dramatic = "We should write these down and turn them into a PLAY.",
			bookish = "I'm writing both of these down, for science.",
			gloomy = "Heh... mine will be a boring one tonight, as usual.",
			polite = "What a funny pair of dreams.",
			foodie = "Next time I'm dreaming about cake, on purpose.",
			nervous = "I-I hope tonight's dream is a calm one.",
			_ = "Either way, I hope I get that one again.",
		}, "question")
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
			gentle = "I think it was you, and I'm a little upset about it.",
			shy = "Um... I think it was you.",
			polite = "I'm fairly sure it was you, if I'm honest.",
			sunny = "It was you, I saw you!",
			dreamy = "It was you, wasn't it? I'm sure it was.",
			bold = "It was you, and you know it.",
			easygoing = "Eh, I'm pretty sure it was you.",
			proud = "It was you, obviously, since it certainly wasn't me.",
			cool = "It was you.",
			bookish = "Actually, I worked it out, and it was you.",
			gloomy = "It was you... heh, though I'll get the blame, as usual.",
			foodie = "It was you, I'd bet my lunch on it.",
			_ = "It was you, and everyone knows it.",
		}, "anger", "point")
		burst(s, "b", {
			cool = "No, it wasn't.",
			gloomy = "Of course it's my fault, everything is.",
			bookish = "Actually, if you go through it in order, it was you.",
			proud = "Me? Never.",
			sunny = "Me? No way, it wasn't me!",
			gentle = "Me? Oh, I don't think so.",
			bold = "Me? Hah, no, it was you.",
			dreamy = "Me...? I don't think it was me.",
			easygoing = "Me? Nah, that sounds like way too much effort.",
			shy = "M-me? I don't think so...",
			cheeky = "me? no way, i was at home all day",
			prickly = "Me? Ugh, don't be ridiculous.",
			dramatic = "ME? How could you even SAY that?",
			polite = "Me? I am afraid you are mistaken.",
			foodie = "Me? No, I've been at the bakery all morning.",
			nervous = "M-me? No, I don't think it was me... was it?",
			_ = "Me? It was obviously you.",
		}, "anger")
		burst(s, "a", {
			sunny = "Just say it was you, and we can stop!",
			gentle = "Please just admit it, it's all right.",
			bold = "Admit it, and we can stop.",
			dreamy = "Hmm, I'm almost sure it was you.",
			easygoing = "Come on, it was totally you.",
			proud = "I'm never wrong about these things.",
			shy = "I-I think I saw you, though.",
			cheeky = "you're doing your guilty face",
			cool = "It was you, so just say it.",
			prickly = "Don't even start, I know it was you.",
			dramatic = "I saw it with my OWN eyes!",
			bookish = "I remember the exact time, so it was definitely you.",
			gloomy = "It's always me who gets the blame, so this time it's you.",
			polite = "I'm afraid I'm quite sure it was you.",
			foodie = "It was you, and you had crumbs on your chin at the time.",
			nervous = "I-I'm almost sure it was you, sorry.",
			_ = "It was definitely you.",
		}, "anger")
		burst(s, "b", {
			sunny = "It wasn't me, I promise!",
			gentle = "It really wasn't me, all right?",
			bold = "It wasn't me, and that's that.",
			dreamy = "Hmm... I don't remember doing it.",
			easygoing = "Eh, it wasn't me, I was napping.",
			proud = "I would never do something so careless.",
			shy = "It... it wasn't me.",
			cheeky = "prove it",
			cool = "It wasn't me.",
			prickly = "Ugh, it wasn't me, so drop it.",
			dramatic = "How DARE you, it wasn't me!",
			bookish = "Actually, I was somewhere else entirely at the time.",
			gloomy = "Fine, blame me, everyone does.",
			polite = "I'm sorry, but it really wasn't me.",
			foodie = "I was eating at the time, so it can't have been me.",
			nervous = "I-it wasn't me, I don't think.",
			_ = "It wasn't me!",
		}, "anger")
		if K.isPers(ctx, a, "proud", "bold", "prickly") or K.isPers(ctx, b, "proud", "bold", "prickly") then
			s:say("a", "I'm not saying another word.", "anger")
			s:say("b", "Good.", "anger")
			s:say("a", "...It was you, though.", "anger")
		end
		s:n(ctx.rng:pick(FIZZLE))
		s:say("b", "...What were we even arguing about?", "question")
		burst(s, "a", {
			foodie = "No idea, but do you want half my bun?",
			prickly = "It doesn't matter.|Do you want a cookie?",
			cool = "I forgot. Do you want some tea?",
			sunny = "No idea, ehehe!|Let's get ice cream.",
			gentle = "I don't remember.|Come and have some tea with me, okay?",
			bold = "No idea.|Lunch, then?",
			dreamy = "Hmm... I've forgotten already.|Look, that cloud looks like a boot.",
			easygoing = "No idea.|Want to sit down? I want to sit down.",
			proud = "I don't remember.|But I was right, whatever it was.",
			shy = "Um... I forgot too, sorry.",
			cheeky = "no clue|truce? i've got some sweets in my pocket",
			dramatic = "I have NO idea.|Let's never speak of it again.",
			bookish = "I honestly can't remember.|That's quite funny, actually.",
			gloomy = "No idea.|Heh... want to just go home?",
			polite = "I am afraid I do not remember.|Would you like a cup of tea?",
			nervous = "I-I don't remember either.|Are we still friends?",
			_ = "No idea.|Do you want a cookie?",
		}, "heart")
		s:rel(2)
		s:log("{a} and {b} argued about {thing}, then forgot why.")
		return s:done()
	end,
})

-- told they were right, and told they weren't
local RIGHT = {
	sunny = "Ehehe, I knew it!",
	gentle = "Oh, thank you, I did think so.",
	bold = "Hah, told you.",
	dreamy = "Hmm... I had a feeling.",
	easygoing = "Yeah, I'll take that.",
	proud = "Naturally, I'm always right.",
	shy = "Oh... really? Thank you.",
	cheeky = "hehe, told you so",
	cool = "Hm, I thought so.",
	prickly = "Obviously. Was there ever any doubt?",
	dramatic = "VICTORY!",
	bookish = "Exactly, the reasoning was sound.",
	gloomy = "I was right? Heh, that's new.",
	polite = "Thank you, that's kind of you to say.",
	foodie = "Ha, I win, and winners get a snack.",
	nervous = "R-really? I was right?",
	_ = "Ha, I knew it.",
}
local WRONG = {
	sunny = "Aww, okay, okay, you win this one.",
	gentle = "Oh, well, I still think I'm a little bit right.",
	bold = "Not a chance, but fine.",
	dreamy = "Hmm... I'm still not sure.",
	easygoing = "Eh, I'm too comfy to argue.",
	proud = "Hmph, you're both mistaken.",
	shy = "Oh... okay.",
	cheeky = "rigged",
	cool = "Hm, we'll see.",
	prickly = "Whatever, I know I'm right.",
	dramatic = "I've been BETRAYED.",
	bookish = "I'd like to see the evidence, actually.",
	gloomy = "Heh... I'm always on the wrong side.",
	polite = "Well, I suppose I'll have to accept that.",
	foodie = "Fine, but I'm still right, and I'm getting a cookie.",
	nervous = "Oh, okay, sorry, I was wrong.",
	_ = "Fine, but I still think I'm right.",
}

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
			cool = "{player}, settle it, please.",
			gentle = "{player}, would you help us decide?|We'll both listen, okay?",
			bold = "{player}, you settle it, right now.",
			dreamy = "{player}... what do you think?",
			easygoing = "{player}, you pick, and then we can all sit down.",
			proud = "{player}, tell them I'm right, so we can move on.",
			shy = "Um, {player}... what do you think?",
			prickly = "{player}, just tell them they're wrong.",
			bookish = "{player}, we need a third opinion, and you're it.",
			gloomy = "{player}, you decide.|Heh... it'll be against me, as usual.",
			foodie = "{player}, settle this, and then we can all go to lunch.",
			_ = "{player}, you decide.",
		}, "question")
		s:choice("I think {a}'s right.", function(c)
			burst(c, "a", RIGHT, "sparkle", "cheer")
			burst(c, "b", WRONG, "anger")
			c:mood("a", 3)
			c:mood("b", -2)
		end)
		s:choice("I'm with {b} on this one.", function(c)
			burst(c, "b", RIGHT, "sparkle", "cheer")
			burst(c, "a", WRONG, "anger")
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
		if saysA and saysA == saysB then
			-- two villagers with the same news: the second tells something else
			local lines = K.sceneLines(va.pers, "happy")
			saysA = if #lines > 0 then ctx.f(ctx.rng:pick(lines)) else nil
		end
		burst(s, "a", {
			sunny = "So what's new? Tell me everything!",
			cool = "What's new with you?",
			bookish = "So what have you been up to? Start from the beginning.",
			foodie = "What's new with you, apart from lunch?",
			gentle = "How have you been? Really, I mean.",
			cheeky = "ok, tell me everything",
			bold = "Right, what's new with you?",
			dreamy = "Hmm... what have you been up to?",
			easygoing = "So, anything new, or just the usual?",
			proud = "Tell me your news, and then I'll tell you mine, which is better.",
			shy = "Um... what's new with you?",
			prickly = "So, what's new? Not that I was wondering.",
			dramatic = "Tell me EVERYTHING that's happened since I last saw you.",
			gloomy = "So... is there anything new with you?",
			polite = "How have you been? Please do tell me your news.",
			nervous = "So, um, what's new? Is everything okay?",
			_ = "So what's new with you?",
		}, "question")
		if saysB then
			s:say("b", saysB, "music")
		else
			s:say("b", "Not much, really, so what about you?", "question")
		end
		if saysA then
			s:say("a", saysA, "music")
			burst(s, "b", {
				sunny = "Ooh, and then what happened?",
				gentle = "Oh, my, tell me more over tea.",
				bold = "Hah, I'd have liked to see that.",
				dreamy = "Hmm... that sounds like quite a week.",
				easygoing = "Huh, sounds like a busy week.",
				proud = "Interesting, almost as interesting as my week.",
				shy = "Oh... that's nice, really.",
				cheeky = "ooh, tell me more",
				cool = "Huh, good for you.",
				prickly = "Huh, not bad.",
				dramatic = "And you're only telling me NOW?",
				bookish = "Oh, I'd love to hear the whole story.",
				gloomy = "Heh, more happens to you than to me.",
				polite = "How interesting, do tell me more.",
				foodie = "Tell me more over lunch, I'm starving.",
				nervous = "Oh, wow, really?",
				_ = "Huh, tell me more.",
			}, "music", "laugh")
		end
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
		"I swept outside my door, and it's already covered in leaves again.",
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
			prickly = "Complaining won't fix it.|...It is awful, though.",
			dramatic = "The sky is out to get us, personally.",
			bookish = "Actually, I keep a weather chart, and this is the worst week since spring.",
			gloomy = "It'll be worse tomorrow, as usual.",
			polite = "What awful weather.|Would you like to share my umbrella?",
			foodie = "This is exactly what soup is for.",
			nervous = "Do you think it'll get worse? Should I bring my washing in?",
			_ = "Don't get me started.",
		}, "question")
		burst(s, "a", {
			sunny = "Ehehe, okay, you've cheered me up a bit.",
			gentle = "You're right, I'll stop fussing.",
			bold = "Hah, fine, I'll stop complaining.",
			dreamy = "Hmm... maybe it's not so bad.",
			easygoing = "Eh, fair enough, I'll go and sit inside.",
			proud = "Hmph, I was only mentioning it.",
			shy = "Um, yes, you're right.",
			cheeky = "ok fine, complaining over",
			cool = "Hm, fair enough.",
			prickly = "Ugh, fine, I'll stop.",
			dramatic = "Then I will SUFFER in silence.",
			bookish = "You're right, it can't last much longer.",
			gloomy = "Heh... we'll see.",
			polite = "Quite right, I will stop complaining.",
			foodie = "Okay, but I'm still getting soup.",
			nervous = "O-okay, I'll try not to worry about it.",
			_ = "Ha, okay, I feel a bit better now.",
		}, "music")
		s:rel(4)
		s:log("{a} and {b} moaned about the weather.")
		return s:done()
	end,
})

local PLANS = {
	"take a boat out to the little islet",
	"have a picnic on the hill",
	"have a board game night",
	"walk the whole length of the beach",
	"have a baking day",
}

event({
	id = "plans",
	when = "day",
	weight = W({ base = 0.18, rel = 25 }),
	scene = function(ctx, a, b)
		local s = K.scene(ctx, "Making plans"):with({ plan = ctx.rng:pick(PLANS) })
		burst(s, "a", {
			sunny = "We should {plan} this week, for real this time!",
			bold = "You and me are going to {plan} this week, right?",
			shy = "Um, would you want to {plan} this week?|Only if you're free.",
			gentle = "We should {plan} this week, if you'd like to.",
			dreamy = "Hmm... wouldn't it be nice to {plan} this week?",
			easygoing = "We should {plan} this week, nice and easy.",
			proud = "I've decided we should {plan} this week.",
			cheeky = "we're going to {plan} this week, no excuses",
			cool = "Let's {plan} this week.",
			prickly = "We keep saying we'll {plan}, so this week we actually are.",
			dramatic = "This week, we {plan}, and it'll be AMAZING.",
			bookish = "I've checked, and Thursday is free, so let's {plan} then.",
			gloomy = "We should {plan} this week.|Heh... if nothing goes wrong.",
			polite = "Would you like to {plan} with me this week?",
			foodie = "Let's {plan} this week, and I'll bring lunch.",
			nervous = "Would you want to {plan} this week? If you're not busy?",
			_ = "We should {plan} this week.",
		}, "idea", "point")
		burst(s, "b", {
			easygoing = "Sure, as long as it's not too early.",
			proud = "I'll plan it, and my plans never go wrong.",
			bold = "Yes, and this week we're actually doing it, right?",
			cool = "Sure.",
			nervous = "Which day this week? I need to write it down.",
			dramatic = "Yes, and it'll be the event of the season.",
			foodie = "I'll do the food, obviously.",
			gloomy = "It'll rain, but okay.",
			sunny = "Yes, yes, let's do it!",
			gentle = "Oh, I'd love that.|I'll bring a blanket.",
			dreamy = "Hmm... yes, that sounds nice.",
			shy = "Um, yes... I'd like that a lot.",
			cheeky = "yes, but i'm in charge of the fun",
			prickly = "Fine, I'm in.|Don't be late.",
			bookish = "Yes, and I'll make a list of what we need.",
			polite = "I would be delighted, thank you.",
			_ = "Yes, I'd love that.",
		}, "music")
		burst(s, "a", {
			sunny = "Yay, I'm writing it on my calendar right now!",
			nervous = "Okay, I'm writing it down so we don't forget.",
			gloomy = "We always say that, though.|Heh... and then it rains.",
			easygoing = "We always say that, and then we take a nap instead.",
			prickly = "Ugh, we always say that, though.",
			dreamy = "We always say that, though... maybe this time.",
			gentle = "Lovely, then it's settled, okay?",
			bold = "Good, it's settled, no backing out.",
			proud = "Excellent, then it's settled, as I planned.",
			shy = "Okay... I'm really glad you said yes.",
			cheeky = "settled, and i'm telling everyone so you can't back out",
			cool = "Good, it's settled.",
			dramatic = "Then it's DECIDED!",
			bookish = "Good, I'm putting it on my calendar.",
			polite = "Wonderful, then it is settled.",
			foodie = "Good, I'll start planning the snacks.",
			_ = "Good, then it's settled.",
		}, "music")
		burst(s, "b", {
			gloomy = "Unless it rains, as usual.",
			cheeky = "pinky promise",
			cool = "We'll do it.",
			sunny = "This time we really are, ehehe!",
			gentle = "This time we really will, I promise.",
			bold = "This time we're doing it, no excuses.",
			dreamy = "This time... yes, I think we will.",
			easygoing = "This time for real, even if I have to get up early.",
			proud = "We'll do it, because I said so.",
			shy = "This time we really will... I hope.",
			prickly = "We're doing it this time, or I'm not talking to you.",
			dramatic = "This time, nothing can STOP us!",
			bookish = "This time, it's written down, so it counts.",
			polite = "This time, I promise we will.",
			foodie = "This time we're doing it, and there'll be snacks.",
			nervous = "This time we will, unless something happens... no, we will.",
			_ = "This time we really mean it.",
		}, "heart")
		s:rel(5)
		s:memo("a", "{b} and I are going to {plan}, and this time we're actually doing it.")
		s:log("{a} and {b} made plans to {plan}.")
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
		"After that, it rained for a hundred years, mostly on Tuesdays.",
		"Meanwhile, everyone in town turned into spoons, except Gerald.",
		"It got scared and hid in a teapot until spring.",
		"Then a whale came along and asked for directions.",
	},
	finish = {
		"And they all had cake, the end.",
		"And that's why the gulls are so rude, the end.",
		"And it's still out there if you look, the end.",
		"And then they woke up, and it had all been a dream, the end.",
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
		local middle = ctx.rng:shuffle(STORY.middle)
		s:say("b", middle[1], "music")
		s:say("c", middle[2], "music")
		s:pick("a", STORY.finish, "sparkle")
		burst(s, "b", {
			proud = "That was mostly my line, really.",
			dreamy = "Hmm... I'd like to live in that story.",
			bookish = "We should write it down, and I'll tidy up the middle.",
			dramatic = "That was a MASTERPIECE, and I might cry.",
			cheeky = "that made no sense at all, again",
			sunny = "Ehehe, let's do another one!",
			gentle = "Oh, that was lovely, let's do another.",
			bold = "Hah, best story yet, right?",
			easygoing = "Heh, that was fun, and I barely had to think.",
			shy = "Um, I liked that one... a lot.",
			cool = "Not bad.",
			prickly = "That was ridiculous.|...Again, though.",
			gloomy = "Heh... that was actually fun.",
			polite = "What a lovely story, thank you both.",
			foodie = "Good story, but it needed more food in it.",
			nervous = "Was my line okay? I panicked a bit.",
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
		burst(s, "a", {
			sunny = {
				"What if I throw a party and only the gulls come?",
				"I said I'd bring a cake to the fair, and I've forgotten which kind.",
			},
			gentle = {
				"My neighbour's been very quiet this week, and I don't know whether to knock.",
				"I said yes to helping three people on Saturday, and I can't be in three places.",
			},
			bold = {
				"I snapped at someone at work today, and I can't stop thinking about it.",
				"I said I'd swim round the islet next week, and I'm not sure I can.",
			},
			dreamy = {
				"I keep losing things, and I don't know where they go.",
				"I said I'd sing at the bandstand, and now I can't remember why.",
			},
			easygoing = {
				"I said I'd fix someone's fence, and I can't remember whose.",
				"I've put my chores off for so long that I don't know where to start.",
			},
			proud = {
				"What if the judges don't like my cake this year?",
				"I told everyone I'd win the race, and now I have to win it.",
			},
			shy = {
				"What if I wave at someone and they don't see me?",
				"I wrote the mail carrier a thank you note, but it's still in my pocket.",
			},
			cheeky = {
				"i think i went too far with the bubbles in the fountain",
				"what if nobody finds my next prank funny",
			},
			cool = {
				"I lent someone my good rope, and I can't remember who.",
				"My roof's going to leak in the next storm, and I can't reach the hole.",
			},
			prickly = {
				"Ugh, I snapped at the baker, and now she won't look at me.",
				"My knee's been clicking all week, and I don't like it.",
			},
			dramatic = {
				"What if I forget my lines at the festival and the whole town laughs?",
				"My voice has gone croaky two days before the concert.",
			},
			bookish = {
				"I've lent out so many books that I've lost track of who has them.",
				"I've been asked to give a talk at the library, and I've never spoken to a crowd.",
			},
			gloomy = {
				"I think I upset someone this week, but I don't know who.",
				"My roof's dripping, and I put a bucket under it and gave up.",
			},
			polite = {
				"I worry that I'm a bother to the neighbours with all my visits.",
				"I hope I didn't offend anyone at the market this morning.",
			},
			foodie = {
				"I put too much pepper in the soup, and I've already given it out.",
				"I promised to bake for the fair, and I've never baked a thing in my life.",
			},
			nervous = {
				"I have to give a speech at the hall tomorrow, and what if my mind goes blank?",
				"What if I say the wrong thing at the party on Friday?",
			},
			_ = "I said I'd help with the fair, and I don't know where to start.",
		}, "sweat")
		s:say("a", "What would you do if you were me?", "question")
		burst(s, "b", {
			sunny = "Don't think about it so hard, and come for a walk with me instead!",
			gentle = "Let me make us some tea first, and then tell me all of it, okay?",
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
			polite = "If I may, I'd take it one step at a time, and you can always come to me.",
			foodie = "Eat something first, because nobody makes good decisions hungry.",
			nervous = "I'd worry too, so let's worry together and then make a list.",
		}, "idea")
		s:choice("That's good advice.", function(c)
			burst(c, "a", {
				sunny = "You're right, thank you!",
				gentle = "Thank you, I feel better already.",
				bold = "...Yeah, you're right, thanks.",
				dreamy = "Hmm... thank you, that helps.",
				easygoing = "Yeah, okay, that helps, thanks.",
				proud = "Hmph, that's actually good advice.|Thank you.",
				shy = "Um, thank you so much, really.",
				cheeky = "ok, that actually helped",
				cool = "Thanks, that helps.",
				prickly = "...Fine, that helps.|Thanks.",
				dramatic = "You've SAVED me, thank you.",
				bookish = "That's sensible, thank you.",
				gloomy = "Heh... thanks, that does help a bit.",
				polite = "Thank you kindly, that's very helpful.",
				foodie = "Thanks, I'll think it over with a snack.",
				nervous = "Thank you, sorry, thank you.",
				_ = "Thanks, that really helps.",
			}, "heart")
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
				sunny = "Ooh, good idea, I'll ask everyone!",
				bold = "Fair enough, I'll ask around.",
				dreamy = "Hmm... maybe someone else will see it differently.",
				easygoing = "Sure, I'll ask a few people, no rush.",
				cool = "Okay, I'll ask around.",
				dramatic = "Ask OTHERS? Am I so much trouble?|...Fine, you're right.",
				bookish = "Good idea, more opinions are always better, actually.",
				gloomy = "Heh... you're tired of me, then.|No, you're right.",
				foodie = "Okay, I'll ask a few people over lunch.",
				nervous = "Oh no, was it too much to ask you?|Okay, I'll ask someone else too.",
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
			sunny = "Hey, I'm sitting with you, because whatever it is, you've got me.",
			gentle = "Come here... it'll look smaller tomorrow, it always does.",
			cheeky = "do you want me to cheer you up, or prank whoever did this?",
			shy = "Um, I brought you a cookie.|We don't have to talk.",
			proud = "Chin up, people can see you. Well, I can see you.",
			dreamy = "Do you want to watch the clouds with me? They don't ask questions.",
			easygoing = "Hey, I'll sit with you, and we don't have to do anything.",
			cool = "Move over. I'll sit with you.",
			prickly = "Make room, because I'm not leaving until you're okay.",
			dramatic = "No sad faces while I'm here, so tell me who I'm ANGRY with.",
			bookish = "Can I sit with you? I promise I won't say anything clever.",
			gloomy = "Bad day? Me too, so let's be gloomy together.",
			polite = "May I sit with you a while? Only if you'd like.",
			foodie = "I've got two pastries, and you look like you need one.",
			nervous = "Are you okay?|Tell me how I can help, please.",
			_ = "Do you want to go for a walk? It might help.",
		}, "heart")
		burst(s, "a", {
			sunny = "Thanks, that really helps, you know.",
			gentle = "Thank you, I feel a little better already.",
			bold = "...Yeah, okay. Thanks for sitting with me.",
			dreamy = "Thank you... I feel lighter already.",
			easygoing = "Thanks, I needed someone to just sit with.",
			proud = "Hmph, I'm fine.|...But thank you for staying.",
			shy = "Um, thank you, really.",
			cheeky = "ok, that helped a bit|thanks",
			cool = "...Thanks, I mean it.",
			prickly = "Ugh, fine, I feel better.|...Thanks.",
			dramatic = "You've saved me from the WORST day, thank you.",
			bookish = "Thank you, I think I just needed company.",
			gloomy = "Thanks, that's the nicest thing all week.",
			polite = "Thank you, that's very kind of you.",
			foodie = "Thanks, I feel better, and a bit hungry, which is a good sign.",
			nervous = "Oh, th-thank you so much!",
			_ = "Thank you, that really helped.",
		}, "heart")
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
			cool = "{player}, we need you to settle something.",
			polite = "Sorry to bother you, {player}, but could you settle something for us?",
			gentle = "{player}, could you help us with a little question?",
			bold = "{player}, come here, you're settling this.",
			dreamy = "{player}... could you settle something for us?",
			easygoing = "{player}, quick one, no rush, but could you settle something for us?",
			prickly = "{player}, settle this, so I can stop arguing with them.",
			dramatic = "{player}, only YOU can settle this.",
			bookish = "{player}, we need an outside opinion, actually.",
			gloomy = "{player}, settle something for us.|Heh... I know how it'll go.",
			foodie = "{player}, settle this, and then we're getting snacks.",
			nervous = "{player}, s-sorry, could you settle something for us?",
			_ = "{player}, can you settle something for us?",
		}, "question", "wave")
		burst(s, "a", {
			cheeky = "we've been counting, and we need to know which of us waves at you more",
			sunny = "We've been counting, and we need to know who waves at you more!",
			gentle = "We've been keeping count, just for fun, of which of us waves at you more.",
			bold = "We need to know which of us waves at you more, so tell us straight.",
			dreamy = "We've been wondering which of us waves at you more...",
			easygoing = "We want to know which of us waves at you more, and we've been counting, sort of.",
			proud = "We'd like to know which of us waves at you more, though I think we know.",
			shy = "Um, we've been wondering which of us waves at you more...",
			cool = "Which of us waves at you more?",
			prickly = "We've been arguing about which of us waves at you more, don't laugh.",
			dramatic = "Which of us waves at you MORE? We must know!",
			bookish = "We've each been counting how often we wave at you, and our numbers don't match.",
			gloomy = "We want to know which of us waves at you more, but you don't have to answer.",
			polite = "We have been wondering which of us waves at you more.",
			foodie = "We've been keeping count of which of us waves at you more, between lunches.",
			nervous = "We've been counting which of us waves at you more... is that weird?",
			_ = "We've been keeping count, and we want to know which of us waves at you more.",
		}, "question")
		burst(s, "b", {
			bold = "It's me, right? Say it's me.",
			dramatic = "Think carefully, because this matters more than you know.",
			gloomy = "It's {a}, isn't it? It's always {a}.",
			nervous = "Y-you don't have to answer, unless you want to.",
			foodie = "Whoever loses is buying the buns, just so you know.",
			sunny = "It's me, isn't it? Ehehe!",
			gentle = "Whatever you say, we won't mind, okay?",
			dreamy = "Hmm... I think it might be me.",
			easygoing = "No pressure, but it's probably me.",
			proud = "It's clearly me, but go ahead and say it.",
			shy = "Um... you don't have to pick me.",
			cheeky = "it's me, and if it's not, it's rigged",
			cool = "Be honest.",
			prickly = "Just say it's me, and we can all go home.",
			bookish = "Before you answer, I've counted eleven waves this week.",
			polite = "Please be honest, we will not mind.",
			_ = "Be honest, we can take it.",
		}, "sweat")
		local SULK = {
			sunny = "Aww, I'll just have to wave harder tomorrow.",
			gentle = "Oh well, well done, I mean that.",
			shy = "Oh... that's okay.",
			gloomy = "Heh... I knew it all along.",
			prickly = "Whatever, my waves are better quality.",
			polite = "Fair enough, well done.",
			foodie = "Fine, I'll buy the buns.",
			cheeky = "rigged!",
			nervous = "Oh, okay... I'll try to wave more.",
			cool = "Fine, I'll wave more.",
			bold = "Fine, I'll wave twice as hard tomorrow.",
			dramatic = "Then I'll wave with BOTH arms tomorrow.",
			bookish = "I'll be keeping a closer count from now on.",
			easygoing = "Eh, waving takes effort, so fair enough.",
			dreamy = "Hmm... I'll wave bigger tomorrow.",
			proud = "Hmph, I'm waving twice tomorrow.",
			_ = "Fine, I'm waving twice tomorrow.",
		}
		local WON = {
			sunny = "Ehehe, I knew it!",
			gentle = "Oh, really? That's sweet of you to notice.",
			bold = "Hah! Told you.",
			dreamy = "Hmm... I do like waving.",
			easygoing = "Heh, and I barely even lift my arm.",
			proud = "Naturally, my waves are hard to miss.",
			shy = "Oh... me? Really?",
			cheeky = "hehe, guess who's the best",
			cool = "Hm, I thought so.",
			prickly = "Obviously. I've been counting too.",
			dramatic = "VICTORY! I knew my waves were the biggest.",
			bookish = "That matches my own count, actually.",
			gloomy = "Me? Heh... that's a first.",
			polite = "Oh, how kind of you to notice.",
			foodie = "Ha, then the buns are on you.",
			nervous = "M-me? Oh, wow.",
			_ = "Ha, I knew it.",
		}
		s:choice("{a} waves more.", function(c)
			burst(c, "a", WON, "sparkle", "cheer")
			burst(c, "b", SULK, "sweat")
			c:mood("a", 3)
			c:mood("b", -1)
		end)
		s:choice("{b} waves more.", function(c)
			burst(c, "b", WON, "sparkle", "cheer")
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
			sunny = "Eek, something's moving in the hedge!",
			gentle = "Oh my, stay close, there's something in the hedge.",
			dreamy = "Hmm... the hedge is moving all by itself...",
			easygoing = "Uh, is that hedge moving, or am I that tired?",
			proud = "Something is in that hedge, and I'm not scared, just so you know.",
			cheeky = "ok what was that, and don't say it was me",
			cool = "Stop, there's something in the hedge.",
			prickly = "Ugh, what's in that hedge?",
			bookish = "Something's in the hedge, and it's about the size of a cat, actually.",
			polite = "Excuse me, but I think something is in the hedge.",
			foodie = "Something's in the hedge, and I've got snacks in my pocket, so it's probably after me.",
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
			gentle = "Oh, it's only a little hedgehog, the sweet thing.",
			bold = "Hah, it's a hedgehog, nothing to worry about.",
			dreamy = "Oh... a hedgehog, out for a night walk.",
			easygoing = "Heh, it's just a hedgehog, taking its time.",
			proud = "A hedgehog, just as I thought all along.",
			shy = "Oh... it's only a little hedgehog.",
			dramatic = "A HEDGEHOG! Oh, my poor heart can't take this.",
			gloomy = "A hedgehog... I was sure it was something worse.",
			polite = "Oh, it is a hedgehog.|Good evening, little one.",
			nervous = "A-a hedgehog? Oh, phew, it's only a hedgehog.",
			_ = "Oh, hello, you.",
		}, "heart")
		burst(s, "b", {
			sunny = "Ehehe, it scared me half to death!",
			gentle = "Oh, my, it's so tiny, look at its little nose.",
			bold = "Hah, I knew it was nothing.",
			dreamy = "Hmm... it's out for a walk too.",
			easygoing = "Heh, it's slower than me, which is saying something.",
			proud = "I wasn't scared, for the record.",
			shy = "Oh... it's so small.",
			cheeky = "ok, it's very cute, i'll allow it",
			cool = "Hm, fine, it's cute.",
			prickly = "Ugh, my heart's still going.|...It is sweet, though.",
			dramatic = "I thought that was the END of me.",
			bookish = "Its nose is twitching, look, it's sniffing for beetles.",
			gloomy = "Heh... for once it wasn't something bad.",
			polite = "Oh, goodness, what a relief.",
			foodie = "Phew, I thought it was a fox after my snacks.",
			nervous = "Oh, thank goodness, it's only a hedgehog.",
			_ = "Ha, it's only a hedgehog.",
		}, "music", "laugh")
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
	"the cinnamon buns at the bakery",
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
			cool = "Try {rec}, it's good.",
			sunny = "You have to try {rec}, promise me!",
			dramatic = "{b}, {rec} will change your LIFE.",
			gentle = "{b}, have you tried {rec}? I think you'd love it.",
			bold = "{b}, you're trying {rec} this week, right? You have to.",
			dreamy = "Have you ever tried {rec}...? It's like a little dream.",
			easygoing = "You should try {rec} sometime, no rush, it's really nice.",
			proud = "{b}, take my advice and try {rec}, I have excellent taste.",
			shy = "Um, {b}, have you tried {rec}? I think you'd like it.",
			cheeky = "{b} you haven't tried {rec}? wow, ok, go now",
			prickly = "Ugh, you still haven't tried {rec}? Go, it's good.",
			gloomy = "You should try {rec}.|Heh... it's the one thing in town I like.",
			polite = "{b}, if I may, you really should try {rec}.",
			nervous = "{b}, have you tried {rec}? I think you'd like it, I hope.",
			_ = "You have to try {rec}, trust me.",
		}, "idea", "point")
		burst(s, "b", {
			prickly = "Fine, but if it's bad, I'm telling you.",
			nervous = "What if I don't like it, though?",
			easygoing = "Sure, I'll get round to it sometime.",
			polite = "I'd be glad to, thank you for thinking of me.",
			gloomy = "It'll be closed, it always is when I go.",
			cheeky = "ok, but if it's bad, you owe me",
			sunny = "Ooh, okay, I'll go tomorrow!",
			gentle = "That sounds lovely, I'll try it this week.",
			bold = "Fine, I'll go tomorrow, and it had better be good.",
			dreamy = "Hmm... okay, I'll go and see.",
			proud = "Very well, I'll judge it for myself.",
			shy = "Okay... I'll try it, thank you.",
			cool = "Okay, I'll try it.",
			dramatic = "Then tomorrow, my LIFE changes!",
			bookish = "Okay, I'll try it and let you know what I think.",
			foodie = "Say no more, I'm going tomorrow.",
			_ = "Okay, I'll give it a try.",
		}, "question")
		s:n("The next day, {b} went and tried {rec} for themselves.")
		burst(s, "b", {
			prickly = "...It was good, so don't look at me like that.",
			gloomy = "It was open, and it was good, which never happens to me.",
			dramatic = "It changed my life, and I'm a new person!",
			cool = "Good call.",
			sunny = "You were so right, I loved it!",
			gentle = "You were right, it was lovely.",
			dreamy = "Hmm... you were right, it was really nice.",
			easygoing = "Yeah, that was good, nice one.",
			proud = "Not bad, I'll admit you were right this once.",
			shy = "Um, you were right, it was really nice.",
			bold = "Hah, you were right, and I'm going back tomorrow.",
			bookish = "You were right, and I've added it to my own list.",
			polite = "You were quite right, thank you for the tip.",
			foodie = "Mmm, you were right, and I'm going back for more.",
			nervous = "You were right, and I didn't hate it at all!",
			cheeky = "ok fine, it was good|don't get a big head about it",
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
		s:n("{b} knocked on {a}'s door to borrow a cup of sugar for a cake.")
		burst(s, "b", {
			polite = "Sorry to bother you, but may I borrow a cup of sugar?|I will bring it back.",
			foodie = "It's a sugar emergency, and I'm halfway through a cake.",
			shy = "Um, sorry... do you have any sugar I could borrow?",
			cool = "Have you got any sugar? I've run out.",
			nervous = "Hi, sorry, I'm out of sugar, and I checked twice.",
			sunny = "Hi, hi!|Do you have any sugar? I'm baking a cake!",
			gentle = "Hello, dear, sorry to bother you.|Could I borrow a little sugar for a cake?",
			bold = "I need a cup of sugar, and you've got some, right?",
			dreamy = "Hello... I ran out of sugar right in the middle of a cake.",
			easygoing = "Hey, sorry, I ran out of sugar halfway through a cake.|Got any?",
			proud = "I'm making my famous cake, and I've run out of sugar.",
			cheeky = "hi, i need sugar, it's for a cake, not a prank, promise",
			prickly = "Don't ask, I ran out of sugar.|Have you got some?",
			dramatic = "Help, I have NO sugar, and the cake is waiting!",
			bookish = "Hello, I need exactly one cup of sugar for a cake.|Do you have any?",
			gloomy = "I ran out of sugar, as usual.|Do you have any?",
			_ = "Hi, I've run out of sugar, have you got any?",
		}, "question")
		burst(s, "a", {
			gentle = "Come in, come in, and sit down while I find it.",
			sunny = "Sugar? Sure, come in, and have you heard about the gulls?",
			prickly = "Fine, come in, but don't touch anything.",
			gloomy = "Come in, and mind the mess, there's always a mess.",
			bold = "Sure, come in, I've got loads.",
			dreamy = "Sugar...? Come in, I'll look for it.",
			easygoing = "Sure, come in, have a seat, no rush.",
			proud = "Of course, my kitchen always has plenty.|Come in.",
			shy = "Oh, um, yes... please come in.",
			cheeky = "sugar? sure, come in, but you have to hear my news first",
			cool = "Sure, come in.",
			dramatic = "Come in, come in, you poor thing!",
			bookish = "Come in, it's on the second shelf, I think.",
			polite = "Of course, please do come in.",
			foodie = "Sugar? Come in, and taste this pie while I find it.",
			nervous = "Oh, sure, come in, sorry about the mess.",
			_ = "Come in, it's in here somewhere.",
		}, "heart")
		s:n("An hour later, {b} went home with the sugar and a slice of pie.")
		burst(s, "b", {
			foodie = "My cake... it's still sitting in the bowl at home.",
			nervous = "Oh no, oh no, did I leave my oven on?",
			sunny = "Oh no, the cake! Ehehe, I forgot all about it!",
			gentle = "Oh my, my poor cake, I forgot all about it.",
			bold = "The cake! I'd better run home right now.",
			dreamy = "Hmm... wasn't I making something?|Oh, the cake.",
			easygoing = "Oh, the cake... eh, it'll keep for a bit.",
			proud = "The cake! Th-that was part of the plan, of course.",
			shy = "Oh no... I forgot the cake.",
			cheeky = "wait, the cake|oops",
			cool = "The cake.|I forgot.",
			prickly = "Ugh, the cake, I forgot all about it.",
			dramatic = "THE CAKE! I completely forgot about it!",
			bookish = "Oh, the cake, and I've been gone fifty-five minutes, actually.",
			gloomy = "The cake... heh, I forgot, as usual.",
			polite = "Oh dear, I have forgotten all about my cake.",
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
			sunny = "Look, look, the sky's going pink!",
			gentle = "Oh, look at the sky, isn't it lovely?",
			bold = "Now that's a sunset.",
			easygoing = "This is my favourite part of the day, no rush at all.",
			proud = "What a sunset, almost as good as the ones I paint.",
			shy = "Um... the sky's really pretty.",
			cheeky = "the sun's going down, quick, wave goodbye",
			prickly = "Fine, the sunset's nice, I'll admit it.",
			polite = "What a beautiful evening.",
			nervous = "The sky's gone all red... is that normal?|It's pretty, I mean.",
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
			cool = "Yeah, it's good.",
			prickly = "Fine, it's nice, so don't make it a thing.",
			dramatic = "I might cry, honestly.",
			bookish = "I'm going to write down all the colours when I get home.",
			gloomy = "It won't last, but it's nice while it does.",
			polite = "It's lovely, thank you for sitting with me.",
			foodie = "It's the exact colour of apricot jam.",
			nervous = "It's so quiet out here... in a good way, I mean.",
			_ = "It's lovely.",
		}, "heart")
		s:n("They sat quietly for a while after that.")
		burst(s, "a", {
			prickly = "Same time tomorrow, and don't be late.",
			nervous = "Same time tomorrow? I-if that's okay?",
			sunny = "Same time tomorrow, okay?",
			gentle = "Same time tomorrow, if you'd like?",
			bold = "Same time tomorrow, right?",
			dreamy = "Same time tomorrow...?",
			easygoing = "Same time tomorrow, and I'll bring a cushion.",
			proud = "Same time tomorrow, I insist.",
			shy = "Um... same time tomorrow?",
			cheeky = "same time tomorrow, and you bring the snacks",
			cool = "Same time tomorrow.",
			dramatic = "Same time TOMORROW, promise me!",
			bookish = "Same time tomorrow, the sun goes down at fourteen minutes past seven.",
			gloomy = "Same time tomorrow?|Heh... if it's not raining.",
			polite = "Would you like to meet here again tomorrow?",
			foodie = "Same time tomorrow, and I'll bring a picnic.",
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
		local place = if w then "the " .. K.workplace(ctx, a) else "work"
		local s = K.scene(ctx, "A long day"):with({ work = place })
		burst(s, "a", {
			gloomy = "Today at {work} was awful, and then it got worse, as usual.",
			dramatic = "Today at {work} was a DISASTER, so let me start from the beginning.",
			nervous = "I think I got something wrong at {work}, and I keep going over it.",
			proud = "Today at {work} was not my best day, so don't tell anyone.",
			prickly = "Ugh, don't ask me about {work}.",
			sunny = "Today at {work} was the worst, and I couldn't even smile about it!",
			gentle = "Oh my, today at {work} was such a long one.",
			bold = "Today at {work} was rough, and I'm still annoyed.",
			dreamy = "Today at {work} went all wrong... I don't even know where to start.",
			easygoing = "Today at {work} was so busy I didn't get a single break.",
			shy = "Um, today at {work} wasn't very good...",
			cheeky = "today at {work} was a mess, and for once it wasn't my fault",
			cool = "It was a bad day at {work}.",
			bookish = "Today at {work}, seven things went wrong before lunch.",
			polite = "I am afraid today at {work} was very difficult.",
			foodie = "Today at {work} was so bad that I didn't even get lunch.",
			_ = "It was a long day at {work}.",
		}, "sad")
		burst(s, "b", {
			gentle = "Oh, my... come here and tell me all of it.",
			foodie = "Sit down and eat this first, then tell me.",
			cool = "Do you want to talk, or just sit quietly?",
			bookish = "Did it actually go wrong, or does it just feel like it did? Those are different.",
			polite = "I'm so sorry, what can I do?",
			cheeky = "want me to go and pull a face at {work} for you?",
			sunny = "Oh no! Come here, let's sit down and you can tell me.",
			bold = "Who made it bad? Tell me everything.",
			dreamy = "Oh... come and sit by the water and tell me about it.",
			easygoing = "Sit down, no rush, and tell me about it.",
			proud = "Tell me what happened, and I'll tell you how I'd fix it.",
			shy = "Oh... do you want to talk about it?",
			prickly = "Ugh, that's awful.|Sit down and tell me who to be angry at.",
			dramatic = "A bad day? Tell me EVERYTHING.",
			gloomy = "Heh... I know those days.|Tell me about it.",
			nervous = "Oh no, are you okay? What happened?",
			_ = "Do you want to talk about it?",
		}, "heart")
		s:n("So {a} told {b} all about it.")
		burst(s, "a", {
			prickly = "...Fine, thanks, that helped.",
			cool = "Thanks.",
			sunny = "Thanks, I feel so much better!",
			gentle = "Thank you for listening, really.",
			bold = "...Thanks. Anyway, tomorrow's a new day.",
			dreamy = "Thank you... it feels lighter now.",
			easygoing = "Thanks, I think I'll go and have a long nap now.",
			proud = "Thank you, that helped, I'll admit.",
			shy = "Thank you... really.",
			cheeky = "ok, i feel better|thanks for listening to all that",
			dramatic = "You've SAVED my evening, thank you.",
			bookish = "Thank you, saying it all out loud helped, actually.",
			gloomy = "Thanks.|Heh... that was nice of you.",
			polite = "Thank you kindly for listening.",
			foodie = "Thanks, I feel better, and now I'm hungry.",
			nervous = "Thank you, I-I feel a lot better now.",
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
			sunny = "Pencils are always handy, ehehe!",
			gentle = "I like to have a pencil for everyone, just in case.",
			bold = "Seven pencils is the right number, trust me.",
			dreamy = "I draw clouds when I'm bored... I need lots of pencils.",
			easygoing = "I keep finding pencils and putting them in there, and I never take them out.",
			proud = "A person should always be ready, and I always am.",
			shy = "Um... they're mine, sorry.",
			cool = "They're mine.|I need them back.",
			prickly = "Yes, they're mine, and don't count them again.",
			dramatic = "Those pencils are PRECIOUS to me!",
			gloomy = "They're mine.|Heh... most of them don't even work.",
			polite = "Those are mine, yes, and I would like them back, please.",
			foodie = "Those are mine, I write recipes down everywhere I go.",
			_ = "Those are my pencils, so I'll have them back, please.",
		}, "sweat")
		burst(s, "b", {
			foodie = "And those peppermints are mine, so I'll be needing them.",
			sunny = "Let's swap back at the café tomorrow, okay?",
			gentle = "Let's swap back at the café tomorrow, all right?",
			bold = "We'll swap back at the café tomorrow, nine o'clock.",
			dreamy = "We could swap back at the café tomorrow...|Your coat is very warm, though.",
			easygoing = "Let's swap back tomorrow, no rush, your coat's comfy.",
			proud = "We'll swap back tomorrow, and please take good care of mine, it's very fine.",
			shy = "Um, could we swap back at the café tomorrow?",
			cheeky = "swap back tomorrow, but i'm keeping one pencil hehe",
			cool = "We'll swap back at the café tomorrow.",
			prickly = "We'll swap back tomorrow, and don't spill anything on mine.",
			dramatic = "Until TOMORROW, then, at the café!",
			bookish = "We'll swap back tomorrow, and I've counted the pencils, so I'll know.",
			gloomy = "We'll swap back tomorrow.|Heh... if I don't lose yours first.",
			polite = "Could we swap back at the café tomorrow, please?",
			nervous = "Can we swap back tomorrow? I-I'll keep yours really safe, I promise.",
			_ = "Let's swap back at the café tomorrow, then.",
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
			gloomy = "We'd be soaked in two steps, I've worked it out.",
			bold = "I'd run for it, but it's coming down even harder now.",
			easygoing = "Or we could just stay here, because it's nice under here.",
			nervous = "B-but what if it gets worse halfway?",
			dreamy = "Hmm... listen to it on the roof, like lots of little feet.",
			bookish = "Actually, running only keeps you a little drier, I read a whole article about it.",
			sunny = "Or we could wait, and maybe there'll be a rainbow!",
			gentle = "Let's wait a little, you'll catch a cold out there.",
			proud = "I don't run in the rain, it looks silly.|We'll wait.",
			shy = "Um... I'd rather wait, if that's okay.",
			cheeky = "you first, and i'll watch",
			cool = "We'll get soaked.|Let's wait.",
			prickly = "Ugh, no, I'm not getting soaked.",
			dramatic = "Out THERE? We'd be washed away!",
			polite = "I would rather we waited, if you do not mind.",
			foodie = "Or we could wait and share this muffin, I've got one in my bag.",
			_ = "Or we could wait, because it can't rain forever.",
		}, "question")
		s:n("It rained for another hour, and they talked the whole time.")
		burst(s, "a", {
			sunny = "Look, it's stopping, and there's a rainbow over the harbour!",
			bold = "Right, it's easing off, so let's go.",
			dreamy = "Hmm... I'll miss the sound of it on the roof.",
			easygoing = "That was nice, actually, I'd do it again.",
			cool = "It's stopped, let's go.",
			dramatic = "We SURVIVED.",
			gloomy = "It's stopped... until we're halfway home, I bet.",
			nervous = "I-it's stopped, so let's go before it starts again.",
			gentle = "Oh, it's stopping, so let's go before it starts again, okay?",
			proud = "There, it's stopping, just as I said it would.",
			shy = "Um... I think it's stopped.",
			cheeky = "it stopped, race you home",
			prickly = "Finally, it's stopped.|...That wasn't so bad.",
			bookish = "It's stopped, and that was exactly sixty-one minutes, actually.",
			polite = "It seems to have stopped, thank you for the company.",
			foodie = "It's stopped, so let's go and get something warm to eat.",
			_ = "I think it's easing off, so let's go.",
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
			gentle = "Oh, that colour really suits you, I wanted to say.",
			bold = "Your coat's great, I'm just saying it.",
			dreamy = "Your scarf is the same blue as the sea this morning...",
			easygoing = "Nice shirt, by the way, it looks comfy.",
			proud = "You look nice today, almost as nice as me.",
			cheeky = "your hair looks good today, no joke",
			bookish = "That colour suits you, actually, it brings out your eyes.",
			gloomy = "You look nice today.|Heh... I don't say that often.",
			foodie = "Your sweater is the colour of a lemon tart, and I mean that in a good way.",
			nervous = "I like your hat, I mean, is that weird to say?",
			_ = "I like your sweater, I just wanted to say.",
		}, "heart")
		burst(s, "b", {
			proud = "I know, but thank you.",
			shy = "Oh... oh no, thank you.|Where do I put my hands?",
			gloomy = "Really? Huh, nobody ever says that.",
			bookish = "Thank you, I've had it six years, actually.",
			nervous = "Really? You're not just saying that?",
			dramatic = "Oh, you're too kind, truly!",
			sunny = "Aww, thank you!",
			gentle = "Oh, my, thank you.",
			bold = "Hah, thanks.",
			dreamy = "Oh... thank you, that's nice to hear.",
			easygoing = "Oh, thanks, I just threw it on.",
			cheeky = "i know, but thanks",
			cool = "Thanks.",
			prickly = "Ugh, stop.|...Thanks.",
			polite = "That is very kind of you, thank you.",
			foodie = "Aw, thanks, it's got no stains on it, for once.",
			_ = "Oh, thanks.",
		}, "sparkle")
		burst(s, "b", {
			cheeky = "and your shoes are... shoes, lovely shoes",
			cool = "Your shoes are fine too.",
			sunny = "And your shoes! They're so, um, nice and shoe-shaped!",
			gentle = "And your shoes are... lovely, yes.",
			bold = "Your shoes are... good, solid shoes.",
			dreamy = "And your shoes... hmm, they're nice shoes.",
			easygoing = "And your shoes are, uh, nice, yeah.",
			proud = "Your shoes are almost as good as mine.",
			shy = "Um... your shoes are nice too...",
			prickly = "Your shoes are fine, okay?",
			dramatic = "And your SHOES! They're... shoes!",
			bookish = "And your shoes are... very well made, actually.",
			gloomy = "Your shoes are nice... heh, I'm bad at this.",
			polite = "And your shoes are very nice, if I may say.",
			foodie = "And your shoes are nice, like... like two nice loaves.",
			nervous = "And your shoes! They're good, I think, sorry.",
			_ = "And your, um... your shoes are nice.",
		}, "sweat")
		burst(s, "a", {
			sunny = "Ehehe, thanks, they're new!",
			gentle = "Oh, thank you, they're my comfy ones.",
			bold = "Hah, they're just shoes, but thanks.",
			dreamy = "Hmm... I'd forgotten which ones I put on.",
			easygoing = "Heh, they're my slippers, actually.",
			proud = "Naturally, I chose them carefully.",
			shy = "Oh... th-thank you.",
			cheeky = "nice save",
			cool = "...Thanks.",
			prickly = "Ugh, nice try.|...Thanks, though.",
			dramatic = "My SHOES? Oh, you noticed!",
			bookish = "Thank you, they've been mended twice, actually.",
			gloomy = "Heh, they've got a hole in them, but thanks.",
			polite = "How kind of you, thank you.",
			foodie = "Thanks, but don't look too closely, there's jam on the left one.",
			nervous = "R-really? I nearly didn't wear them.",
			_ = "Ha, thanks, nice save.",
		}, "music", "laugh")
		s:rel(5)
		s:log("{a} and {b} swapped compliments, badly.")
		return s:done()
	end,
})

-- three of them make a plan for tomorrow, all talking at once
local OUTINGS = {
	{ what = "a swim at the cove", bring = "the towels" },
	{ what = "breakfast on the hill", bring = "the big flask" },
	{ what = "a kite day on the beach", bring = "the string" },
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
			sunny = "Okay, okay, tomorrow we're all going for {what}!",
			bold = "Tomorrow it's {what} at nine sharp, and everyone's coming.",
			dramatic = "Tomorrow it's {what}, and it has been DECIDED.",
			shy = "Um, I was thinking...|Would anyone want to come for {what} tomorrow? Only if you want.",
			gentle = "How about {what} tomorrow, all of us?",
			dreamy = "Hmm... what if we all went for {what} tomorrow?",
			easygoing = "We should go for {what} tomorrow, nothing too early.",
			proud = "I've planned {what} for tomorrow, and you're both invited.",
			cheeky = "tomorrow, {what}, all of us, no excuses",
			cool = "Let's go for {what} tomorrow.|Who's in?",
			prickly = "We're going for {what} tomorrow, and nobody's backing out.",
			bookish = "I've checked the weather, and tomorrow is perfect for {what}.",
			gloomy = "Does anyone want to go for {what} tomorrow?|Heh... probably not.",
			polite = "Would you both like to come for {what} tomorrow?",
			foodie = "Let's go for {what} tomorrow, and I'll pack lunch.",
			nervous = "Would everyone want to go for {what} tomorrow? If that's okay?",
			_ = "Does anyone want to go for {what} tomorrow?",
		}, "idea", "point")
		burst(s, "b", {
			easygoing = "Sure, as long as it's not too early.",
			nervous = "What time? What if it rains?|I'll bring a coat, maybe two.",
			foodie = "I'll do the snacks, so nobody else bring any.",
			cool = "I'm in.",
			prickly = "Fine, but I'm not carrying anything.",
			sunny = "Yes, yes, I'm coming!",
			gentle = "That sounds lovely, I'll be there.",
			bold = "I'm in, and I'll be first there.",
			dreamy = "Hmm... yes, that sounds nice.",
			proud = "I'll come, naturally.",
			shy = "Um, could I come too?",
			cheeky = "i'm in, obviously",
			dramatic = "I wouldn't miss it for the WORLD!",
			bookish = "I'm in, and I'll check the tide times.",
			gloomy = "I'll come.|Heh... if it doesn't rain.",
			polite = "I would love to come, thank you.",
			_ = "I'm in.",
		}, "music")
		burst(s, "c", {
			bookish = "Someone has to bring {bring}, so I'll make a list.",
			gloomy = "It'll rain on us, but I'll still come.",
			proud = "I'll lead the way, since I know the best route.",
			cheeky = "i'm coming, and i'm bringing nothing",
			sunny = "I'll bring {bring}, ehehe, leave it to me!",
			gentle = "I'll bring {bring}, and maybe a blanket too.",
			bold = "I'll bring {bring}, don't worry about it.",
			dreamy = "Hmm... someone should bring {bring}... me, maybe.",
			easygoing = "Someone else can bring {bring}, I'll just bring myself.",
			shy = "Um... I could bring {bring}, if that helps.",
			cool = "I'll bring {bring}.",
			prickly = "Fine, I'll bring {bring}, since nobody else will.",
			dramatic = "I'll bring {bring}, and I'll carry it PROUDLY.",
			polite = "I would be happy to bring {bring}.",
			foodie = "Who's bringing {bring}? Not me, I've got the snacks.",
			nervous = "Who's bringing {bring}? Should I? I'll bring two, just in case.",
			_ = "Who's bringing {bring}?",
		}, "question")
		s:n("They planned the whole thing.")
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
			gentle = "{a}, {b} said you'd like me to {heard}, is that right?",
			bold = "{a}, {b} says you want me to {heard}, so what's going on?",
			dreamy = "{a}... {b} said you wanted me to {heard}? That sounds fun.",
			easygoing = "Hey, {a}, {b} says you want me to {heard}, which sounds like a lot of work.",
			proud = "{a}, {b} tells me you want me to {heard}, which is a very strange thing to ask me.",
			shy = "Um, {a}... {b} said you wanted me to {heard}?",
			cheeky = "{a}, {b} says you want me to {heard}, and honestly, i'm in",
			prickly = "{a}, why does {b} say you want me to {heard}?",
			dramatic = "{a}! {b} says you want me to {heard}? What does it MEAN?",
			bookish = "{a}, {b} says you want me to {heard}, which doesn't sound right, actually.",
			gloomy = "{a}, {b} says you want me to {heard}.|Heh... that sounds about right for my day.",
			foodie = "{a}, {b} says you want me to {heard}, and I'll need a snack first.",
			_ = "{a}, {b} says you want me to {heard}?",
		}, "question")
		burst(s, "a", {
			prickly = "No, I said {said}. Honestly, {b}.",
			cheeky = "hahaha, no, i said {said}",
			dramatic = "I said {said}, {b}! What have you DONE?",
			sunny = "No, no, I said {said}! Ehehe, {b}!",
			gentle = "Oh, no, I said {said}.|{b}, you got it all mixed up.",
			bold = "No, I said {said}, {b}, come on.",
			dreamy = "Hmm... I said {said}, I think.",
			easygoing = "Nah, I said {said}, but that one's funny too.",
			proud = "I said {said}, {b}, quite clearly.",
			shy = "Um, no... I said {said}.",
			cool = "No.|I said {said}.",
			bookish = "No, I said {said}, which is quite a different thing, actually.",
			gloomy = "I said {said}.|Heh... of course it got mixed up.",
			polite = "I am afraid I said {said}, not that.",
			foodie = "I said {said}, {b}, were you eating again?",
			nervous = "N-no, I said {said}! Oh no, did you start already?",
			_ = "...No, I said {said}.",
		}, "sweat")
		burst(s, "b", {
			foodie = "I had a mouthful of bun, so it's not my fault.",
			gloomy = "Of course I got it wrong.",
			proud = "I passed on exactly what I heard.",
			sunny = "Oops, sorry, sorry! Ehehe!",
			gentle = "Oh my, I'm sorry, I must have heard it wrong.",
			bold = "Hey, I said what I heard, okay?",
			dreamy = "Hmm... it sounded right when I said it.",
			easygoing = "Eh, close enough, right?",
			shy = "S-sorry... I had my mouth full.",
			cheeky = "honestly, mine was better",
			cool = "I was eating.|My mistake.",
			prickly = "Ugh, fine, I was eating, okay?",
			dramatic = "It was the BUN's fault, not mine!",
			bookish = "To be fair, they sound quite alike with a mouthful of bun.",
			polite = "I do apologise, I was eating at the time.",
			nervous = "Oh no, I'm so sorry, it's my fault!",
			_ = "In my defence, I was eating.",
		}, "sweat")
		burst(s, "c", {
			sunny = "Ehehe, I was about to go and do it!",
			gentle = "Oh, my, I'm glad I asked first.",
			bold = "Hah, I was halfway out the door.",
			dreamy = "Hmm... I was quite looking forward to it.",
			easygoing = "Heh, good thing I hadn't started yet.",
			proud = "I knew it sounded wrong, naturally.",
			shy = "Oh... okay, I'll do the right one.",
			cheeky = "shame, i liked the first one better",
			cool = "Hm, glad I asked.",
			prickly = "Ugh, next time just tell me yourself.",
			dramatic = "I was READY to do it, too!",
			bookish = "I did think it was an odd request.",
			gloomy = "Heh... I'd have done it, too.",
			polite = "Oh, I'm glad I checked.",
			foodie = "Next time, nobody passes on messages while eating.",
			nervous = "Oh, thank goodness I asked first!",
			_ = "Ha, I'm glad I asked first.",
		}, "music", "laugh")
		s:relx("a", "b", 2)
		s:relx("a", "c", 3)
		s:relx("b", "c", 3)
		s:log("{b} passed on a message from {a} to {c}, wrongly.")
		return s:done()
	end,
})

return list
