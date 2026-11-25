--!nonstrict
-- Two or three villagers together: games and rivalries, duets, secret handshakes, picnics,
-- misunderstandings and promises, friendships starting and falling apart, making up, and best
-- friends; and the smaller things of a week: a jigsaw with a piece gone, cuttings over a fence, a
-- fence in two colours, three teas, two night owls at the fountain, rock paper scissors for the
-- comfy chair, a walk home after work, a present they made you, stones skipped, birds counted;
-- and the newer ones, a friend who was ill and the soup that followed, and a lost bet paid in
-- public. How it goes depends on who they are and how well they get on. They talk the way friends
-- text, each message one whole sentence in their own voice with their own habits (Data/Personalities,
-- docs/GAME_DESIGN.md). There is no romance (the user: "remove any romance, just best friends is
-- the highest").

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

-- who wins a contest: the bolder one a little more often
local function winner(ctx, a, b): (string, string)
	local pa = 0.5 + (K.trait(ctx, a, "brave") - K.trait(ctx, b, "brave")) * 0.3
	if ctx.rng:chance(pa) then
		return "a", "b"
	end
	return "b", "a"
end

-- the loser's line: proud and bold ones take it badly, gentle and easygoing ones don't mind
local function loses(s, ctx, who, vid)
	burst(s, who, {
		proud = { "That one didn't count, because I wasn't ready.", "Hmph. We're doing best of three, then." },
		bold = { "I want a rematch, right now.", "I was going easy on you, you know that, right?" },
		easygoing = "Eh, you win, so I'll go and get us some snacks.",
		gentle = "Oh, my, you played that really well.",
		shy = "Um... you're really good at this.",
		cheeky = "ok fine, you win this one|i'm still telling everyone i let you win",
		cool = "Hm. I'll get you next time.",
		prickly = { "Whatever, I wasn't even trying.", "Fine, you win, but don't gloat about it." },
		dramatic = "Defeated, in front of EVERYONE.|I don't think I'll ever get over this.",
		bookish = "Interesting, I'll have to work out how you did that.",
		gloomy = "Heh... I knew I'd lose, as usual.",
		polite = "Well done, that was very nicely played.",
		foodie = "Fine, the loser buys the buns, so I'm off to the bakery.",
		nervous = "D-did I do it wrong?|I think I did something wrong at the start.",
		_ = "I'll get you next time, I promise.",
	}, if K.isPers(ctx, vid, "proud", "bold", "prickly", "dramatic") then "anger" else "sweat")
end

-- the one whose cake lost the bake off
local SULK = {
	proud = "Hmph. I'll eat mine on my own, then.",
	gentle = "Oh, well done, it was fun to make mine anyway.",
	shy = "Oh, that's okay.|Yours did look nicer than mine.",
	bold = "Fine, but I want a rematch next week with bigger cakes.",
	easygoing = "Eh, that just means more cake for me.",
	cheeky = "fine, but i'm hiding the winning one|hehe",
	cool = "Hm. That's fair.",
	prickly = "Whatever, mine tastes better and you know it.",
	dramatic = "My cake has been REJECTED.|I need to go and lie down.",
	gloomy = "Heh... I knew mine wouldn't win.",
	polite = "Congratulations, it really was a lovely cake.",
	foodie = "Fine, but I'm having a slice of both, for research.",
	nervous = "W-was mine bad?|It was the icing, wasn't it?",
	_ = "Fine, that just means more cake for me.",
}

-- games and rivalries -------------------------------------------------------------------------------

event({
	id = "boardgame",
	when = "any",
	weight = W({ base = 0.25, traits = { focus = 0.2 } }),
	scene = function(ctx, a, b)
		local s = K.scene(ctx, "Game night")
		s:prop("boardgame", "a")
		s:n("{a} and {b} have been bent over a board game for an hour.")
		burst(s, "a", {
			nervous = "It's your move.|N-no rush, but could you go soon?",
			cool = "It's your move.",
			dramatic = "It's your move, and EVERYTHING depends on it.",
			cheeky = "your move|no pressure, but i'm winning",
			_ = "It's your move.|Take your time, just not all of it.",
		}, "question")
		local w, l = winner(ctx, a, b)
		s:n("One move later, the game was over.")
		s:voice(w, "brag", "sparkle", "cheer")
		loses(s, ctx, l, ctx.stars[l])
		s:choice("Play another one.", function(c)
			c:n("They played four more games, and by the end nobody could remember the score.")
			c:rel(6)
			c:mood("a", 2)
			c:mood("b", 2)
		end)
		s:choice("Call it a draw.", function(c)
			burst(c, w, {
				proud = "A draw, fine, but we both know I won.",
				gentle = "A draw seems fair to me.",
				cheeky = "a draw|i'm still telling everyone i won",
				polite = "A draw it is.|Thank you, {player}, that's very fair.",
				shy = "Um... a draw is nice, I think.",
				nervous = "A draw? Oh, good, nobody has to lose.",
				gloomy = "A draw is the best I was ever going to get.",
				cool = "Hm. A draw's fine.",
				sunny = "A draw, so we both win!",
				_ = "Fine, a draw, but I was winning.",
			}, "sweat")
			c:say(l, "It's a draw, and that's that.", "anger")
			c:rel(3)
		end)
		s:log("{a} and {b} played a board game.")
		return s:done()
	end,
})

event({
	id = "thumbwar",
	when = "any",
	weight = W({ base = 0.15, traits = { mischief = 0.3 } }),
	scene = function(ctx, a, b)
		local s = K.scene(ctx, "Thumb war")
		say(s, "a", "One, two, three, four, I declare a thumb war.", "idea", "point")
		burst(s, "b", {
			cool = "Fine, let's go.",
			nervous = "W-wait, what are the rules again?",
			dramatic = "You'll regret challenging me.",
			cheeky = "oh, you're done for",
			_ = "You're on.",
		}, "sparkle")
		s:n("It got very serious, and {a} kept making up new rules halfway through.")
		local w, l = winner(ctx, a, b)
		s:voice(w, "brag", "sparkle", "cheer")
		loses(s, ctx, l, ctx.stars[l])
		s:rel(3)
		s:log("{a} and {b} had a thumb war.")
		return s:done()
	end,
})

event({
	id = "staring",
	when = "any",
	weight = W({ base = 0.12 }),
	scene = function(ctx, a, b)
		local s = K.scene(ctx, "Staring contest")
		say(s, "a", "Let's have a staring contest.|Whoever blinks first buys the buns.", "idea")
		s:n("They stared at each other while a gull landed between them and walked off again.")
		if ctx.rng:chance(0.5) then
			s:n("Then {b} sneezed.")
			say(s, "b", "That doesn't count, because sneezing isn't blinking.", "sweat")
			say(s, "a", "Your eyes were shut, so you're buying the buns.", "sparkle")
		else
			s:n("Then the gull came back and pecked {a}'s shoe.")
			say(s, "a", "Ow, that gull made me blink, so it doesn't count.", "anger")
			say(s, "b", "The gull's on my side, so you owe me buns.", "sparkle")
		end
		s:rel(4)
		s:log("{a} and {b} had a staring contest.")
		return s:done()
	end,
})

local RIDDLES = {
	{ "What has hands but can't clap?", "A clock." },
	{ "What gets wetter the more it dries?", "A towel." },
	{ "What can you catch but not throw?", "A cold." },
	{ "What has a neck but no head?", "A bottle." },
	{ "What runs but never walks?", "A river." },
	{ "What has teeth but never bites?", "A comb." },
}

event({
	id = "riddles",
	when = "any",
	weight = W({ base = 0.12, traits = { focus = 0.2 } }),
	scene = function(ctx, a, b)
		local r = ctx.rng:pick(RIDDLES)
		local s = K.scene(ctx, "Riddle me this"):with({ q = r[1], ans = r[2] })
		say(s, "a", "I've got a riddle for you.|{q}", "question", "point")
		if ctx.rng:chance(0.5) then
			s:say("b", "{ans}", "idea")
			burst(s, "a", {
				prickly = "Who told you the answer?",
				dramatic = "*gasp* How did you know that?",
				cheeky = "you cheated, you definitely cheated",
				_ = "How did you know that one?",
			}, "anger")
			s:voice("b", "brag", "sparkle")
		else
			burst(s, "b", {
				sunny = "Wait, wait, I know this one...|No, I don't, it's gone.",
				bookish = "Hmm, give me a moment, I've definitely read this one somewhere.",
				proud = "It's on the tip of my tongue, so don't you dare tell me.",
				nervous = "Oh no, I-I'm really bad at riddles.",
				gloomy = "Heh... I never get these.",
				cheeky = "is it a trick question?",
				cool = "Hm. No idea.",
				dreamy = "Hmm... a shark with very good manners?",
				_ = "Hmm, I give up, so what is it?",
			}, "question")
			s:say("a", "{ans}", "sparkle", "cheer")
			burst(s, "b", {
				bookish = "Actually, that's barely a riddle.|...I didn't get it, though.",
				gloomy = "Heh... I'd never have got that.",
				proud = "I knew that, I was just letting you have it.",
				_ = "Oh, come on, that's not fair.",
			}, "sweat")
		end
		s:rel(4)
		s:log("{a} asked {b} a riddle.")
		return s:done()
	end,
})

event({
	id = "bakeoff",
	cutscene = "kitchen",
	when = "day",
	weight = W({ base = 0.12 }),
	scene = function(ctx, a, b)
		local s = K.scene(ctx, "The bake off")
		s:prop("cake", "a")
		s:n("{a} and {b} have each made a cake, and they want you to say whose is better.")
		burst(s, "a", {
			proud = "Mine has three layers.|Go on, count them.",
			cheeky = "mine has a surprise in the middle|a good one, hehe",
			foodie = "Mine's brown butter and pear.|I've been working on it for a month.",
			nervous = "Mine's lemon.|I-is it lemony enough, do you think?",
			_ = "Mine's lemon, made with real lemons.",
		}, "sparkle", "point")
		burst(s, "b", {
			proud = "Mine's flawless, just look at the icing.",
			shy = "Mine came out a bit flat...|It tastes nice, though, I think.",
			gloomy = "Mine sank in the middle, as usual.|It still counts, though.",
			dramatic = "Mine is dark chocolate, as dark and mysterious as me.",
			_ = "Mine's chocolate, and you can't beat chocolate.",
		}, "sparkle")
		say(s, "a", "{player}, you have to be fair about this.|Which one's better?", "question")
		s:choice("{a}'s cake.", function(c)
			c:voice("a", "excited", "sparkle", "cheer")
			burst(c, "b", SULK, "sweat")
			c:mood("a", 6)
			c:mood("b", -4)
			c:rel(-2)
		end)
		s:choice("{b}'s cake.", function(c)
			c:voice("b", "excited", "sparkle", "cheer")
			burst(c, "a", SULK, "sweat")
			c:mood("b", 6)
			c:mood("a", -4)
			c:rel(-2)
		end)
		s:choice("They're both lovely.", function(c)
			burst(c, "a", {
				shy = "Um... that's what people say when they can't choose.",
				proud = "Hmph, that's what people say when they can't choose, {player}.",
				cheeky = "that's what people say when they can't choose, {player}",
				gentle = "Oh, that's kind of you, {player}.",
				_ = "That's what people say when they can't choose, {player}.",
			}, "sweat")
			say(c, "b", "Let's just eat them both, then.", "heart")
			c:rel(5)
			c:mood("a", 2)
			c:mood("b", 2)
		end)
		s:log("{a} and {b} had a bake off.")
		return s:done()
	end,
})

-- doing things together ------------------------------------------------------------------------------

event({
	id = "duet",
	cutscene = "bandstand",
	when = "any",
	weight = W({ base = 0.15, traits = { social = 0.2 } }),
	scene = function(ctx, a, b)
		local s = K.scene(ctx, "A duet")
		s:prop("guitar", "a")
		s:prop("microphone", "b")
		s:n("{a} picked up a guitar and {b} took the microphone.")
		burst(s, "b", {
			nervous = "La la... sorry, can we start again?|What key is this in?",
			dramatic = "Laaa, laaaaa.|Right, my voice is warmed up now.",
			shy = "La... um, is this thing on?",
			_ = "La la laaa.|Hang on, what key is this in?",
		}, "music")
		if ctx.rng:chance(0.55) then
			s:n("On the second try it came together, and people stopped in the street to listen.")
			s:voice("a", "excited", "music", "cheer")
			s:rel(8)
			s:all(2)
		else
			s:n("{a} played one song while {b} sang a completely different one, very loudly.")
			s:voice("b", "laugh", "music", "laugh")
			say(s, "a", "We're going to need a lot more practice.", "sweat")
			s:rel(4)
		end
		s:log("{a} and {b} sang a duet.")
		return s:done()
	end,
})

event({
	id = "handshake",
	when = "day",
	weight = W({ base = 0.18, rel = 20, traits = { mischief = 0.2 } }),
	scene = function(ctx, a, b)
		local s = K.scene(ctx, "A secret handshake")
		say(s, "a", "We need a secret handshake, like proper friends have.", "idea", "point")
		s:say("b", "Shake, shake, elbow, spin...", "music")
		s:say("a", "...clap, thumbs, wiggle, other elbow, bow.", "music")
		s:n("Now it takes them a full minute to say hello.")
		burst(s, "b", {
			proud = "Nobody else will ever know it, because it's ours.",
			easygoing = "I'll remember about half of it, and that's probably enough.",
			cool = "Hm. Let's do it again.",
			nervous = "W-was it elbow then spin, or spin then elbow?|Can we go again, slower?",
			bookish = "I'm writing it down in code so nobody can copy it.",
			_ = "Again, from the top!",
		}, "heart", "cheer")
		s:rel(9)
		s:memo("a", "{b} and I have a secret handshake now. And no, I can't show you, {player}.")
		s:log("{a} and {b} made up a secret handshake.")
		return s:done()
	end,
})

event({
	id = "dancelesson",
	when = "day",
	weight = W({ base = 0.15, traits = { social = 0.3 } }),
	scene = function(ctx, a, b)
		local s = K.scene(ctx, "Dance lessons")
		say(s, "a", "I'll teach you my dance if you teach me yours.", "music")
		s:n("{a}'s dance was mostly arms and {b}'s was mostly feet, so they put the two together.")
		burst(s, "b", {
			bold = "We look amazing, right?",
			shy = "Um... sorry, I keep stepping on your feet.",
			dreamy = "Hmm... we look like two leaves blowing about.",
			prickly = "This is silly.|...Again, from the arm bit.",
			gloomy = "We look ridiculous, but I'm having fun, which is new.",
			dramatic = "Look at us!|The whole town will be begging for lessons.",
			_ = "We should do this at the next party.",
		}, "music", "dance")
		s:rel(7)
		s:mood("a", 3)
		s:mood("b", 3)
		s:log("{a} and {b} taught each other a dance.")
		return s:done()
	end,
})

local MISHEARD = {
	{ "I asked you to bring a pie.", "I've borrowed a pig for the afternoon, like you asked." },
	{ "I said I'd meet you by the pear tree.", "I've been waiting on the pier for an hour." },
	{ "I said I'd lend you my coat.", "I've told everyone you're giving me a goat." },
	{ "I said the party starts at six.", "I've brought six cakes for the party, like you said." },
}

event({
	id = "misheard",
	when = "day",
	weight = W({ base = 0.15 }),
	scene = function(ctx, a, b)
		local m = ctx.rng:pick(MISHEARD)
		local s = K.scene(ctx, "A mix up"):with({ said = m[1], heard = m[2] })
		s:say("b", "{heard}", "sparkle")
		s:say("a", "...", "sweat")
		s:say("a", "{said}", "sweat")
		s:n("There was a long pause.")
		s:voice("b", "laugh", "music", "laugh")
		s:voice("a", "laugh", "music", "laugh")
		s:rel(5)
		s:log("{a} and {b} got their wires crossed.")
		return s:done()
	end,
})

event({
	id = "promise",
	cutscene = "rooftop",
	when = "any",
	weight = W({ base = 0.12, rel = 30 }),
	scene = function(ctx, a, b)
		local s = K.scene(ctx, "A promise")
		burst(s, "a", {
			shy = "Um... can you promise me something?|One day, let's get up early and watch the sun come up from the hill.",
			bold = "Promise me one thing.|One day we're watching the sunrise from the hill, and no excuses.",
			dreamy = "Will you promise me something?|One morning we'll sit on the hill and watch the sun come up, with only the gulls around...",
			_ = "Will you promise me something?|One day we'll get up early and watch the sunrise from the hill.",
		}, "heart")
		burst(s, "b", {
			easygoing = "*yawn* That early?|...Okay, for you, I'll do it once.",
			proud = "I promise, and I always keep my promises.",
			shy = "I promise.|I'll bring a blanket for us.",
			cool = "Deal. I'll be there.",
			prickly = "Fine, I promise, but you'd better bring snacks.",
			gloomy = "It'll probably be cloudy, but I promise.",
			nervous = "I promise, but you'll have to knock really loudly.",
			_ = "I promise, pinky promise.",
		}, "heart")
		s:rel(8)
		s:memo("a", "{b} and I are going to watch the sunrise from the hill one day. We promised.")
		s:memo("b", "I promised {a} we'd watch the sunrise together, so I'm going to need an alarm.")
		s:log("{a} and {b} made a promise.")
		return s:done()
	end,
})

event({
	id = "picnic",
	cutscene = "park",
	when = "day",
	weight = W({ base = 0.25, rel = 10, weather = { "clear", "blossom", "cloudy" } }),
	scene = function(ctx, a, b)
		local s = K.scene(ctx, "A picnic")
		s:prop("picnic", "a")
		s:n("{a} and {b} spread a rug on the grass and unpacked far too many sandwiches.")
		burst(s, "a", {
			foodie = "I made egg, cheese and cucumber.|There's also one I'm calling the mystery, so try that first.",
			_ = "There's one in here I don't remember making.|Do you want to find out what's in it?",
		}, "music")
		if ctx.rng:chance(0.4) then
			s:n("Then the ants found the sandwiches, every last one.")
			burst(s, "b", {
				bold = "Hey, back off, these are our sandwiches!",
				gentle = "Oh, my, let them have a crumb or two.",
				shy = "Um... there's one on my sandwich, and it's looking at me.",
				gloomy = "Heh... ants, as usual.",
				nervous = "A-are they on me?|Can you check my back, please?",
				_ = "Quick, move the rug before they get the rest!",
			}, "sweat")
			s:rel(5)
		else
			s:voice("b", "happy", "heart")
			s:rel(9)
			s:mood("a", 4)
			s:mood("b", 4)
		end
		s:log("{a} and {b} had a picnic.")
		return s:done()
	end,
})

event({
	id = "snowballs",
	when = "day",
	weight = W({ base = 0.45, weather = "snow" }),
	scene = function(ctx, a, b)
		local s = K.scene(ctx, "Snowball fight")
		s:n("{a} threw a snowball at {b}, and it was a very good throw.")
		burst(s, "b", {
			bold = "Hah, it's on now!",
			shy = "Eep! It went down my collar...",
			proud = "You're going to regret that.",
			gentle = "Oh, you little... right, that's it.",
			cool = "...Okay. You asked for this.",
			prickly = "Really?|Fine, you asked for it.",
			dramatic = "You've started something you can't finish!",
			cheeky = "oh, you're getting it now",
			_ = "That's it, this means war.",
		}, "anger")
		s:n("Ten minutes later they were both white from head to toe and laughing too hard to throw.")
		s:rel(7)
		s:mood("a", 4)
		s:mood("b", 4)
		s:log("{a} and {b} had a snowball fight.")
		return s:done()
	end,
})

event({
	id = "sandcastle",
	cutscene = "beach",
	when = "day",
	weight = W({ base = 0.25, season = 2, weather = { "clear", "cloudy" } }),
	scene = function(ctx, a, b)
		local s = K.scene(ctx, "A sandcastle")
		s:prop("sandcastle", "a")
		s:n("{a} and {b} spent the whole afternoon building a sandcastle with four towers and a moat.")
		burst(s, "a", {
			proud = "It's the finest castle on this beach.|On any beach, really.",
			dreamy = "A crab's moved into the left tower...|I think he's the king now.",
			bookish = "The moat's exactly the right depth, because I measured it with a spoon.",
			_ = "Nobody step on it, please.",
		}, "sparkle", "point")
		say(s, "b", "I did the flag, and the flag's the most important bit.", "music")
		s:choice("Leave it for the tide.", function(c)
			burst(c, "a", {
				dreamy = "Hmm... the sea can have it, and maybe it'll make something new out of the sand.",
				proud = "The tide won't knock down anything better all year.",
				gloomy = "The tide will take it, but it was good while it lasted.",
				_ = "Let's leave it, and the sea can have it tonight.",
			}, "heart")
			c:leave("sandcastle", 12, "a")
			c:rel(8)
			c:memo("b", "Our sandcastle might still be on the beach, so go and look, {player}.")
		end)
		s:choice("Take a picture first.", function(c)
			say(c, "b", "Everyone smile, including the castle.", "sparkle", "cheer")
			c:leave("sandcastle", 12, "a")
			c:rel(8)
			c:mood("a", 2)
		end)
		s:log("{a} and {b} built a sandcastle.")
		return s:done()
	end,
})

event({
	id = "brokeit",
	when = "day",
	weight = W({ base = 0.12, traits = { focus = -0.3 } }),
	scene = function(ctx, a, b)
		local s = K.scene(ctx, "Something broke")
		s:n("{a} borrowed {b}'s favourite mug and dropped it, and now it's in three pieces.")
		burst(s, "a", {
			nervous = "{player}, {player}!|I-I broke {b}'s favourite mug, and they love that mug.|What do I do?",
			gloomy = "I broke {b}'s mug.|Heh... what do I do now, {player}?",
			dramatic = "{player}, I've done something TERRIBLE.|I broke {b}'s favourite mug.",
			cheeky = "{player}, small problem|{b}'s mug is now three mugs",
			_ = "{player}, I broke {b}'s favourite mug.|What do I do?",
		}, "sweat")
		s:choice("Tell {b} now.", function(c)
			say(c, "a", "{b}...|I broke your mug, and I'm really sorry.", "sad")
			burst(c, "b", {
				gentle = "Oh, it's only a mug.|Thank you for telling me.",
				proud = "That mug can't be replaced.|...But thank you for being honest.",
				easygoing = "Eh, I've got loads of mugs, so don't worry about it.",
				bold = "You what?|...Fine, but you owe me a mug.",
				cool = "Hm. Thanks for telling me.",
				prickly = "Great.|...It's fine, it was chipped anyway.",
				dramatic = "We had YEARS together, that mug and me.|...I forgive you, though.",
				polite = "Oh, please don't worry.|Thank you for telling me.",
				_ = "Oh, well, thanks for telling me.",
			}, "question")
			c:rel(3)
			c:mood("a", 3)
		end)
		s:choice("Glue it back together.", function(c)
			c:n("{a} glued it back together. From far away, it looks nearly the same.")
			if ctx.rng:chance(0.5) then
				say(c, "b", "Has my mug always had a crack down the side?", "question")
				c:say("a", "...Yes?", "sweat")
				c:rel(-4)
			else
				say(c, "b", "Oh, you brought my mug back, thanks.", "heart")
				say(c, "a", "Mm... maybe don't put anything hot in it.", "sweat")
				c:mood("a", -2)
			end
		end)
		s:log("{a} broke {b}'s mug.")
		return s:done()
	end,
})

event({
	id = "twins",
	when = "day",
	weight = W({ base = 0.1 }),
	scene = function(ctx, a, b)
		local s = K.scene(ctx, "Same outfit")
		s:n("{a} and {b} turned up to the square wearing exactly the same thing.")
		burst(s, "a", {
			proud = "I wore it first, and everyone knows I wore it first.",
			cheeky = "we're twins now|hold my hand, twin",
			shy = "Oh no...|I'll go home and change.",
			cool = "Hm. Same jumper.",
			dramatic = "This square isn't big enough for two of this jumper.",
			_ = "Well, one of us has good taste.",
		}, "sweat")
		burst(s, "b", {
			proud = "Hmph. Mine fits better.",
			easygoing = "Eh, it'll save people telling us apart.|...Wait, no, it won't.",
			prickly = "Go and change, right now.|...Fine, I'll change.",
			gloomy = "Heh... the one day I dress up, and this happens.",
			_ = "Great minds think alike.",
		}, "laugh", "laugh")
		s:rel(4)
		s:log("{a} and {b} wore the same outfit.")
		return s:done()
	end,
})

event({
	id = "stargazepair",
	cutscene = "rooftop",
	when = "night",
	weight = W({ base = 0.18, rel = 15, weather = "clear" }),
	scene = function(ctx, a, b)
		local s = K.scene(ctx, "Under the stars")
		s:prop("telescope", "a")
		s:n("{a} and {b} are lying on the grass, passing a telescope back and forth.")
		burst(s, "b", {
			bookish = "That one's the bear.|Actually, the three stars in a row are meant to be its belt.",
			dreamy = "That one's a bear...|He's wearing a belt.",
			_ = "That one's a bear, and those three stars are its belt.",
		}, "point")
		s:say("a", "Bears don't wear belts.", "question")
		say(s, "b", "This one does, because he's a very smart bear.", "sparkle")
		s:rel(8)
		s:log("{a} and {b} looked at the stars.")
		return s:done()
	end,
})

event({
	id = "fishingtrip",
	cutscene = "pier",
	when = "day",
	weight = W({
		base = 0.15,
		cond = function(ctx, a)
			return ctx.v(a).hobby == "fishing" or ctx.rng:chance(0.5)
		end,
	}),
	scene = function(ctx, a, b)
		local s = K.scene(ctx, "Gone fishing")
		s:prop("fishing", "a")
		s:n("{a} and {b} sat on the pier for three hours with one rod between them.")
		burst(s, "a", {
			dramatic = "Something's biting, something HUGE!|Everybody stand back!",
			nervous = "Something's biting!|W-what do I do?",
			cool = "Hm. Something's biting.",
			_ = "Something's biting, and it feels big.",
		}, "idea")
		local catch =
			ctx.rng:pick({ "an old boot", "a very small fish", "a crab that wouldn't let go", "somebody's hat" })
		s:with({ catch = catch })
		s:n("It was {catch}.")
		burst(s, "b", {
			cheeky = "dinner is served|hehe",
			easygoing = "Eh, it still counts.|Let's throw it back in.",
			gloomy = "Heh... of course it is.",
			foodie = "That's not dinner, not even close.",
			_ = "Well, at least we caught something.",
		}, "sweat", "laugh")
		s:rel(6)
		s:log("{a} and {b} went fishing and caught {catch}.")
		return s:done()
	end,
})

event({
	id = "impression",
	when = "day",
	weight = W({ base = 0.12, traits = { mischief = 0.5 } }),
	scene = function(ctx, a, b)
		local s = K.scene(ctx, "An impression")
		say(s, "a", "Guess who this is.|'Is it lunch yet? I simply must have a bun.'", "music", "point")
		s:say("b", "Is that meant to be me?", "question")
		local good = K.isPers(ctx, b, "cheeky", "sunny", "easygoing") or ctx.rng:chance(0.3)
		if good then
			say(s, "b", "...It's quite good, actually.|Do another one!", "laugh", "laugh")
			s:rel(6)
		else
			burst(s, "b", {
				prickly = "I do not sound like that, so stop it.",
				dramatic = "I sound NOTHING like that.|My voice is much lower.",
				_ = "I do not sound like that.",
			}, "anger")
			s:say("a", "You do, a bit.", "sweat")
			s:rel(-3)
		end
		s:log("{a} did an impression of {b}.")
		return s:done()
	end,
})

event({
	id = "haircut2",
	when = "day",
	weight = W({ base = 0.08, rel = 20 }),
	scene = function(ctx, a, b)
		local s = K.scene(ctx, "A trim")
		say(s, "a", "Hold still, I've watched the barber do this loads of times.", "idea")
		s:n("{a} gave {b} a haircut with the kitchen scissors.")
		if ctx.rng:chance(0.5) then
			s:voice("b", "wow", "sparkle")
			burst(s, "a", {
				proud = "Hmph, I'm clearly a natural.",
				cheeky = "i'm a natural|so who's next?",
				shy = "Um... it actually came out nice, didn't it?",
				nervous = "It worked?|Oh, thank goodness, I was so scared I'd cut an ear.",
				prickly = "See, I told you I could do it.",
				gloomy = "Huh, it went right for once.",
				_ = "I'm a natural.|Who's next?",
			}, "sparkle", "cheer")
			s:rel(6)
		else
			s:say("b", "Why is it shorter on one side?", "question")
			say(s, "a", "That's the style, it's called the Lopsided.", "sweat")
			s:mood("b", -3)
			s:rel(2)
		end
		s:log("{a} cut {b}'s hair.")
		return s:done()
	end,
})

event({
	id = "bet",
	when = "day",
	weight = W({ base = 0.12, traits = { mischief = 0.2, brave = 0.2 } }),
	scene = function(ctx, a, b)
		local s = K.scene(ctx, "A bet")
		say(s, "a", "I bet you can't go a whole day without a snack.", "idea", "point")
		burst(s, "b", {
			foodie = "A whole day?|...Fine, easy, I've got snacks hidden for afterwards anyway.",
			cool = "Easy, you're on.",
			nervous = "A whole day? What if I faint?|...Okay, I'll try.",
			_ = "That's easy, just watch me.",
		}, "sparkle")
		s:n("By eleven, {b} was standing very close to the bakery window.")
		if ctx.rng:chance(0.5) then
			say(s, "b", "I'm only looking, and looking is allowed.", "sweat")
			s:n("{b} made it to dinner, but only just.")
			s:voice("b", "brag", "sparkle", "cheer")
		else
			say(s, "b", "One bun doesn't count, does it?", "sweat")
			say(s, "a", "It counts, so pay up.", "sparkle")
		end
		s:rel(4)
		s:log("{a} and {b} had a bet.")
		return s:done()
	end,
})

event({
	id = "heavylift",
	when = "day",
	weight = W({ base = 0.12 }),
	scene = function(ctx, a, b)
		local s = K.scene(ctx, "A heavy wardrobe")
		burst(s, "a", {
			bold = "You and me are getting this wardrobe up the stairs, right now.",
			polite = "Would you help me carry the wardrobe upstairs, if it's no trouble?",
			_ = "Can you help me get this wardrobe up the stairs?",
		}, "question")
		say(s, "b", "Sure, we'll lift on three.|One, two...", "point")
		s:n("It took an hour, two scraped knuckles and a lot of 'left, no, your other left'.")
		burst(s, "b", {
			bold = "Done.|I could carry another one, I just won't.",
			easygoing = "I need a lie down, ideally on the wardrobe.",
			gloomy = "My back's gone, but it was on its way out anyway.",
			dramatic = "My ARMS.|I'm never lifting anything again.",
			_ = "Promise me you'll never move house.",
		}, "sweat")
		s:rel(7)
		s:mood("a", 3)
		s:log("{a} and {b} carried a wardrobe up the stairs.")
		return s:done()
	end,
})

event({
	id = "howwemet",
	cutscene = "park",
	when = "any",
	weight = W({ base = 0.15, rel = 40 }),
	scene = function(ctx, a, b)
		local s = K.scene(ctx, "Remember when")
		say(s, "a", "Do you remember the day we met?", "heart")
		burst(s, "b", {
			cheeky = "you had your jumper on inside out|i'll never forget it, hehe",
			shy = "Um... I was too nervous to say hello, so you said it first.",
			proud = "You were very impressed by me, I remember that clearly.",
			cool = "You borrowed a pen and never gave it back.",
			prickly = "You trod on my foot and then said sorry six times.",
			bookish = "It was a rainy Tuesday, and you read my whole letter over my shoulder.",
			nervous = "You said hi and I said thanks.|I-I still think about that.",
			_ = "You asked me where the bakery was while we were standing right in front of it.",
		}, "music")
		say(s, "a", "It feels like ages ago, but it wasn't really, was it?", "heart")
		s:rel(8)
		s:log("{a} and {b} talked about the day they met.")
		return s:done()
	end,
})

event({
	id = "photo",
	when = "day",
	weight = W({ base = 0.08, rel = 20, count = 3 }),
	scene = function(ctx, a, b)
		local s = K.scene(ctx, "Say cheese")
		s:prop("camera", "a")
		s:n("{a} set up a camera on a tripod by the fountain and waved everyone over.")
		say(
			s,
			"a",
			"Everyone squeeze in a bit closer.|{b}, you blinked, so we're doing it again.|Okay, say cheese!",
			"sparkle",
			"point"
		)
		s:n("It came out lovely, even the gull in the corner.")
		s:choice("Could I have a copy?", function(c)
			say(
				c,
				"a",
				"Of course, {player}, you're in it.|That's your elbow, right there on the edge.",
				"heart",
				"cheer"
			)
			c:keep("keep_photo", "a")
			c:rel(5)
			c:all(2)
		end)
		s:choice("Pin it up in the square.", function(c)
			say(c, "a", "Good idea, then everyone can see it.", "heart")
			c:rel(5)
			c:all(3)
		end)
		s:log("{a} took a photo of everyone.")
		return s:done()
	end,
})

event({
	id = "lastbiscuit",
	when = "any",
	weight = W({ base = 0.15 }),
	scene = function(ctx, a, b)
		local s = K.scene(ctx, "The last biscuit")
		s:n("There's one biscuit left on the plate between {a} and {b}.")
		s:say("a", "You have it.", "question")
		s:say("b", "No, you have it.", "question")
		s:n("Neither of them moves, and the biscuit just sits there.")
		s:choice("Split it.", function(c)
			c:n("It broke into one big half and one small half, and they both looked at the big half.")
			say(c, "a", "...You have the big half.", "heart")
			c:rel(5)
		end)
		s:choice("Eat it yourself.", function(c)
			c:n("You ate the biscuit while both of them watched you do it.")
			burst(c, "a", {
				cheeky = "wow, {player}|you actually ate it",
				polite = "Well, that's one way to settle it.",
				_ = "That was a bold move, {player}.",
			}, "anger")
			say(c, "b", "We're going to remember this, you know.", "anger")
			c:rel(4)
		end)
		s:log("{a} and {b} argued politely over the last biscuit.")
		return s:done()
	end,
})

event({
	id = "lend",
	when = "day",
	weight = W({ base = 0.1, btraits = { kind = 0.3 } }),
	scene = function(ctx, a, b)
		local s = K.scene(ctx, "A loan")
		burst(s, "a", {
			polite = "{b}, I'm sorry to ask, but could I borrow a few coins until payday?|I'll pay you back with a bun on top.",
			cheeky = "{b}, can i borrow some coins till payday?|i'll throw in a bun",
			nervous = "{b}, s-sorry to ask, but could I borrow some coins until payday?|I'll pay you back with a bun, or two buns.",
			_ = "{b}, can I borrow some coins until payday?|I'll pay you back with a bun on top.",
		}, "sweat")
		if K.trait(ctx, b, "kind") >= 0.5 then
			burst(s, "b", {
				gentle = "Of course, and don't worry about the bun.|...Well, maybe the bun.",
				sunny = "Of course, here you go!|Forget about the bun.",
				bold = "Here, pay me back whenever.",
				shy = "Um... here, there's no rush.",
				easygoing = "Sure, whenever's fine, there's no rush.",
				polite = "Of course, please take your time.",
				foodie = "Here, but I'm holding you to that bun.",
				_ = "Sure, but the bun comes first.",
			}, "heart")
			s:rel(6)
		else
			burst(s, "b", {
				proud = "I'll need that in writing.",
				cheeky = "depends how big the bun is",
				prickly = "How many?|...Fine, here, and don't tell anyone I'm soft.",
				gloomy = "I never get these back.|...Here.",
				_ = "How many coins are we talking about?",
			}, "question")
			s:rel(1)
		end
		s:log("{a} borrowed some coins from {b}.")
		return s:done()
	end,
})

local EXCUSES = {
	sunny = "I stopped to say hello to everyone on the way, and I mean everyone!",
	gentle = "A bird had a hurt wing, so I sat with it until it flew off.|I'm sorry.",
	bold = "I took a shortcut over a fence, and then another fence.",
	dreamy = "Hmm... I think I was early, just for a different day.",
	easygoing = "I set off on time, I just walked really slowly.",
	proud = "I'm not late, everyone else is early.",
	shy = "Um... I was outside for ten minutes, but I didn't want to knock.",
	cheeky = "i was hiding behind you the whole time|ok, i slept in",
	cool = "I overslept. Sorry.",
	prickly = "I know, so don't say it.|The bus was late.",
	dramatic = "You won't BELIEVE my morning.|There was a goose and a puddle, and I'd rather not talk about it.",
	bookish = "I sat on my step to finish a chapter, and then I started the next one.",
	gloomy = "I lost a shoe, found it, and then lost the other one.",
	polite = "I'm so sorry, I have no excuse.|Please, let me buy you a tea.",
	foodie = "There was a queue at the bakery, and I can't just walk past a queue.",
	nervous = "I-I went back to check I'd locked the door, three times.|I'm really sorry.",
}

event({
	id = "late",
	when = "day",
	weight = W({ base = 0.15, traits = { focus = -0.3 } }),
	scene = function(ctx, a, b)
		local s = K.scene(ctx, "Running late")
		s:n("{b} waited by the fountain for half an hour before {a} turned up.")
		burst(s, "b", {
			cool = "...",
			prickly = "Ugh, I've been standing here for half an hour.",
			nervous = "Y-you're here!|I thought something had happened to you.",
			gentle = "There you are, I was starting to worry.",
			_ = "Where have you been?",
		}, "anger")
		say(s, "a", EXCUSES[K.pers(ctx, a)] or "Sorry, it's a long story.", "sweat")
		burst(s, "b", {
			gentle = "Well, you're here now.",
			proud = "Hmph, that's unacceptable, so you're buying me a bun.",
			easygoing = "Eh, I sat down and had a nice rest, so it's fine.",
			gloomy = "It's fine, I'm used to waiting.",
			_ = "Fine, but you're buying.",
		}, "question")
		s:rel(2)
		s:log("{a} was late to meet {b}.")
		return s:done()
	end,
})

event({
	id = "pillowfort",
	when = "any",
	weight = W({
		base = 0.12,
		rel = 20,
		cond = function(ctx)
			return ctx.weather == "rain" or ctx.weather == "storm" or (ctx.hour >= 19 or ctx.hour < 6)
		end,
	}),
	scene = function(ctx, a, b)
		local s = K.scene(ctx, "A pillow fort")
		s:prop("pillowfort", "a")
		s:n("{a} and {b} took every cushion in the house and built a fort.")
		s:say("b", "What's the password?", "question")
		burst(s, "a", {
			cheeky = "open up or i'm taking a cushion",
			dreamy = "Hmm... moonbeam pudding?",
			proud = "I don't need a password, I built the west wall.",
			foodie = "Is it crumpets?",
			cool = "Just let me in.",
			_ = "Is it biscuits?",
		}, "sparkle")
		say(s, "b", "Fine, come in, and mind the lamp on your way.", "heart")
		s:rel(8)
		s:mood("a", 4)
		s:mood("b", 4)
		s:log("{a} and {b} built a pillow fort.")
		return s:done()
	end,
})

local GHOSTS = {
	"a ghost who haunts the bakery and only eats the crusts",
	"a lighthouse that turns its light on by itself",
	"a gull that knows your name",
	"footsteps on the pier at midnight with nobody there",
}

event({
	id = "ghoststory",
	when = "night",
	weight = W({ base = 0.18, traits = { mischief = 0.3 } }),
	scene = function(ctx, a, b)
		local s = K.scene(ctx, "A ghost story"):with({ story = ctx.rng:pick(GHOSTS) })
		say(s, "a", "Do you want to hear a scary one?|It's about {story}.", "idea")
		s:n("{a} told it slowly, in a low voice, holding a lantern under their chin.")
		say(s, "a", "...and the last thing anyone heard was a voice right behind them saying BOO.", "anger", "point")
		s:voice("b", "scared", "sweat")
		burst(s, "a", {
			gentle = "Oh, I'm sorry, it's only a story.|Here, you can hold my hand.",
			cheeky = "hehehe, got you",
			dramatic = "And that story is completely true.|Well, mostly.",
			_ = "Was that too scary?|Do you want to hear another one?",
		}, "laugh", "laugh")
		s:rel(5)
		s:log("{a} told {b} a ghost story.")
		return s:done()
	end,
})

event({
	id = "thunderhug",
	when = "any",
	weight = W({ base = 0.6, weather = "storm", rel = 0 }),
	scene = function(ctx, a, b)
		local s = K.scene(ctx, "Thunder")
		s:n("There was a crack of thunder, and {a} jumped a foot in the air.")
		s:voice("a", "scared", "sweat")
		burst(s, "b", {
			bold = "Hah, it's just noise.|Stand next to me and I'll shout back at it.",
			gentle = "Come here, all right?|We'll count between the flashes together.",
			cheeky = "it's just the sky moving its furniture around",
			shy = "Um... I'm scared of it too.|Can we be scared together?",
			sunny = "It's okay, I've got you!|It's only noise, and it can't get in.",
			dreamy = "Count with me...|One, two, three... see, it's moving away.",
			proud = "Thunder doesn't bother me.|You can stand next to me if you like.",
			easygoing = "Eh, it's just loud.|Come and sit with me till it's done.",
			cool = "It's far off. You're fine.",
			prickly = "It's thunder, it can't hurt you.|...Sit here, then.",
			dramatic = "The sky is having a TANTRUM.|Let it, and we'll stay inside.",
			bookish = "Count after the flash.|Every three seconds is about a kilometre, so it's miles away.",
			gloomy = "Yeah, I hate it too.|Come and sit with me.",
			polite = "Would you like to stay here until it passes?|Please do.",
			foodie = "Thunder means hot chocolate, that's a house rule.",
			nervous = "I know, I know, me too.|C-can we go inside, please?",
			_ = "It's all right, it'll pass soon.",
		}, "heart")
		s:rel(9)
		s:mood("a", 2)
		s:log("{b} kept {a} company through the thunder.")
		return s:done()
	end,
})

event({
	id = "umbrellashare",
	when = "day",
	weight = W({ base = 0.25, weather = "rain", rel = 5 }),
	scene = function(ctx, a, b)
		local s = K.scene(ctx, "One umbrella")
		s:prop("umbrella", "a")
		s:n("It's pouring, and {b} forgot an umbrella, so {a} holds theirs out.")
		burst(s, "a", {
			cool = "Get under, you'll get soaked.",
			prickly = "Get under.|You'll catch a cold and I'll have to hear about it.",
			bold = "Get under here, right now.",
			_ = "There's room for two under here, just about.",
		}, "heart")
		burst(s, "b", {
			shy = "Oh... th-thank you.|I'll try to stand very small.",
			proud = "I was enjoying the rain, but fine.",
			polite = "That's very kind of you, thank you.",
			gloomy = "I always forget mine.|Thanks.",
			_ = "You're a lifesaver, thank you.",
		}, "heart")
		s:n("They walked home slowly, and both of them got one wet shoulder.")
		s:rel(8)
		s:log("{a} shared an umbrella with {b}.")
		return s:done()
	end,
})

event({
	id = "newfriends",
	when = "day",
	weight = W({ base = 0.3, relMax = 25, rel = -5 }),
	scene = function(ctx, a, b)
		local s = K.scene(ctx, "Something in common")
		local thing = ctx.rng:pick({
			"the same favourite song",
			"a fear of geese",
			"the same birthday month",
			"a soft spot for rainy days",
			"a secret love of pickles",
		})
		s:with({ thing = thing })
		s:n("{a} and {b} have never really talked before, and then they found out they share {thing}.")
		burst(s, "a", {
			sunny = "No way, you too?|Wait, wait, really?",
			cool = "Huh. Same here.",
			nervous = "W-wait, really?|You're not just saying that?",
			cheeky = "no way|we're basically twins now",
			_ = "No way, you too?",
		}, "sparkle")
		s:voice("b", "excited", "sparkle", "cheer")
		s:rel(14)
		s:memo("a", "It turns out {b} and I share {thing}. Who knew?")
		s:log("{a} and {b} found out they share {thing}.")
		return s:done()
	end,
})

event({
	id = "sorrycard",
	when = "any",
	weight = W({ base = 0.6, quarrel = true, traits = { kind = 0.8 } }),
	scene = function(ctx, a, b)
		local s = K.scene(ctx, "A sorry card")
		s:n("{a} has made a card for {b} with a drawing of a sad cat on the front.")
		burst(s, "a", {
			shy = "Um, {player}, could you give this to {b}?|I can't do it myself, I'll go all red.",
			proud = "{player}, give this to {b}, would you?|I'm very busy at the moment.",
			bold = "{player}, can you give this to {b}?|I'd do it myself, but I'd say it all wrong.",
			prickly = "{player}, take this to {b}, and don't read it.|...Fine, you can read it.",
			nervous = "{player}, c-could you give this to {b}?|What if they rip it up?",
			_ = "{player}, could you give this to {b}?|I can't bring myself to do it.",
		}, "sweat")
		s:choice("Take it to {b}.", function(c)
			c:n("{b} opened it, and inside it said 'I was silly and I miss you, so here is a cat.'")
			burst(c, "b", {
				proud = "...Hmph.|It's a very good cat.",
				shy = "Oh, that's...|Tell them I miss them too.",
				bold = "Tell them to come and say it themselves.|...And tell them it's okay.",
				cool = "...Tell them it's fine.",
				gloomy = "They drew a cat, for me?|...Tell them I'm sorry too.",
				_ = "Tell them I'm sorry too.",
			}, "heart")
			c:fx({ t = "makeup", a = "a", b = "b" })
			c:rel(10)
			c:mood("a", 5)
		end)
		s:choice("Say it in person.", function(c)
			burst(c, "a", {
				shy = "You're right, I'll go.|I'll go red, but I'll go.",
				proud = "Fine, in person, and I'll be very dignified about it.",
				nervous = "I-in person?|Okay, okay, but will you walk me to the door?",
				_ = "You're right, I'll go and say it.",
			}, "sweat")
			if ctx.rng:chance(0.6) then
				say(c, "b", "...Okay.|I'm sorry too.", "heart")
				c:fx({ t = "makeup", a = "a", b = "b" })
				c:rel(8)
			else
				say(c, "b", "Not yet, give me a day.", "anger")
				c:mood("a", -3)
			end
		end)
		s:log("{a} made {b} a sorry card.")
		return s:done()
	end,
})

local SECRETS = {
	"a secret",
	"about a surprise for someone",
	"who ate the last of the jam",
	"what they got everyone for their birthdays",
}

event({
	id = "fallout",
	when = "day",
	weight = W({ base = 0.08, rel = 30, traits = { temper = 0.3 } }),
	scene = function(ctx, a, b)
		local s = K.scene(ctx, "Falling out"):with({ secret = ctx.rng:pick(SECRETS) })
		s:n("{b} told {a} {secret}, and then {a} told half the town.")
		burst(s, "b", {
			cool = "That was a secret.",
			dramatic = "That was a secret, a SACRED one.",
			prickly = "That was a secret, seriously.",
			_ = "That was supposed to be a secret.",
		}, "anger", "point")
		burst(s, "a", {
			cheeky = "it slipped out|a few times",
			sunny = "I got excited, and I'm so sorry!",
			nervous = "I-I didn't mean to, it just came out.|And then it kept coming out.",
			_ = "I didn't think it was that big a deal.",
		}, "sweat")
		s:choice("Tell {a} to say sorry.", function(c)
			c:voice("a", "sorry", "sad")
			say(c, "b", "Fine, but I'm not telling you anything for a week.", "anger")
			c:rel(-4)
		end)
		s:choice("Let them cool off.", function(c)
			say(c, "b", "I need some time on my own.", "anger")
			c:fx({ t = "quarrel", a = "a", b = "b" })
			c:rel(-10)
		end)
		s:log("{a} told everyone {b}'s secret.")
		return s:done()
	end,
})

event({
	id = "tease",
	when = "day",
	weight = W({ base = 0.15, traits = { mischief = 0.4 } }),
	scene = function(ctx, a, b)
		local s = K.scene(ctx, "A bit of teasing")
		s:voice("a", "tease", "sparkle", "point")
		local score = ctx.rel(a, b)
		if score >= 30 then
			s:voice("b", "laugh", "music", "laugh")
			burst(s, "b", {
				prickly = "You're lucky I put up with you.",
				cool = "Hm. Lucky for you I like you.",
				_ = "You're lucky I like you.",
			}, "heart")
			s:rel(4)
		else
			s:voice("b", "angry", "anger")
			s:rel(-3)
		end
		s:log("{a} teased {b}.")
		return s:done()
	end,
})

local SLEEPTALK = {
	"No... not the pudding... the pudding's innocent...",
	"I'll have the big one, please, the one with the hat.",
	"Gerald, you can't take the bus, you're a snowman.",
	"Five more minutes, Captain.",
}

event({
	id = "sleeptalk",
	when = "night",
	weight = W({ base = 0.12 }),
	scene = function(ctx, a, b)
		local s = K.scene(ctx, "Talking in their sleep")
		s:n("{b} walked past {a}'s window late at night and heard them talking in their sleep.")
		s:say("a", ctx.rng:pick(SLEEPTALK), "zzz")
		burst(s, "b", {
			cheeky = "i'm writing all of this down",
			gentle = "Sweet dreams, whatever they are.",
			bookish = "Fascinating, I'm making a note of the time.",
			_ = "I'm asking about this tomorrow.",
		}, "laugh")
		s:memo("b", "{a} talks in their sleep, but I'm not saying what about.")
		s:rel(2)
		s:log("{b} heard {a} talking in their sleep.")
		return s:done()
	end,
})

event({
	id = "dreamsame",
	cutscene = "dream",
	when = "day",
	weight = W({ base = 0.06, rel = 20 }),
	scene = function(ctx, a, b)
		local s = K.scene(ctx, "The same dream"):with({ dream = ctx.rng:pick(Chatter.Dreams) })
		say(s, "a", "I had the oddest dream last night.|I dreamed {dream}.", "zzz")
		s:say("b", "...So did I.", "question")
		s:n("They looked at each other for a long moment.")
		burst(s, "b", {
			dreamy = "Hmm... we must be connected somehow.",
			bold = "Okay, that's weird, and I'm not scared, it's just weird.",
			bookish = "There must be a reason.|We both had cheese before bed, didn't we?",
			gloomy = "Heh... that can't be a good sign, can it?",
			dramatic = "This is FATE, that's what this is.",
			_ = "We should stop eating cheese before bed.",
		}, "sparkle")
		s:rel(10)
		s:log("{a} and {b} had the same dream.")
		return s:done()
	end,
})

-- three of them --------------------------------------------------------------------------------------

event({
	id = "tugofwar",
	actors = 3,
	when = "day",
	weight = W({ base = 0.12, count = 3 }),
	scene = function(ctx, a, b, c)
		local s = K.scene(ctx, "Tug of war")
		s:prop("rope", "a")
		s:n("{a} and {b} took one end of the rope, and {c} took the other.")
		burst(s, "c", {
			bold = "Two against one?|Hah, bring it!",
			shy = "Two against one?|Um... okay.",
			proud = "Two against one seems fair, for you.",
			cool = "Fine, let's go.",
			gloomy = "Two against one, as usual.",
			dramatic = "Two against one, and they'll sing songs about this.",
			_ = "Two against one?|Fine, I've been eating my greens.",
		}, "sparkle")
		if K.trait(ctx, c, "brave") > 0.65 then
			s:n("{c} dug in their heels and pulled them both over the line.")
			s:voice("c", "brag", "sparkle", "cheer")
		else
			s:n("{c} lasted four seconds and then went face first into the grass.")
			burst(s, "c", {
				proud = "I let you win, and that was very kind of me.",
				shy = "Ow...|Okay, you win.",
				prickly = "Don't say a single word.",
				_ = "I'm face down in the grass, so I suppose you win.",
			}, "sweat")
		end
		s:relx("a", "b", 4)
		s:relx("a", "c", 3)
		s:relx("b", "c", 3)
		s:log("{a}, {b} and {c} had a tug of war.")
		return s:done()
	end,
})

local BANDS =
	{ "The Soggy Biscuits", "Gull Patrol", "Three Spoons", "The Night Buses", "Marrowfat", "Thursday Pudding" }

event({
	id = "band",
	cutscene = { stage = "bandstand", open = "wide", ending = { shot = "wide", act = { all = "dance" } } },
	actors = 3,
	when = "any",
	weight = W({ base = 0.1, count = 3, traits = { social = 0.2 } }),
	scene = function(ctx, a, b, c)
		local names = ctx.rng:shuffle(BANDS)
		local s = K.scene(ctx, "A band")
		s:prop("guitar", "a")
		s:prop("microphone", "b")
		s:n("{a} is on guitar, {b} is singing, and {c} is banging two pans together, so it's a band.")
		burst(s, "b", {
			dramatic = "We need a name, something people will chant.|{player}, you choose!",
			shy = "We need a name...|{player}? Could you pick one?",
			_ = "We need a good name.|{player}, will you pick one?",
		}, "question")
		for i = 1, 2 do
			local name = names[i]
			s:choice(name .. ".", function(ch)
				ch:with({ band = name })
				say(ch, "a", "{band}, that's who we are now.", "music", "cheer")
				say(ch, "c", "Our first gig is tonight, in my kitchen.", "sparkle")
				ch:relx("a", "b", 5)
				ch:relx("a", "c", 5)
				ch:relx("b", "c", 5)
				ch:memo("c", "I'm in a band called {band}, and I play the pans.")
			end)
		end
		s:log("{a}, {b} and {c} started a band.")
		return s:done()
	end,
})

event({
	id = "surpriseplan",
	actors = 3,
	when = "day",
	weight = W({
		base = 0.1,
		count = 3,
		cond = function(ctx, a, b, c)
			return ctx.rel(a, c) >= 20 and ctx.rel(b, c) >= 20
		end,
	}),
	scene = function(ctx, a, b, c)
		local s = K.scene(ctx, "A surprise")
		s:n("{a} and {b} are whispering behind the hedge, planning something for {c}.")
		say(
			s,
			"a",
			"We get balloons and cake, everyone hides, and then we jump out and shout boo.|I mean surprise, we shout surprise.",
			"idea"
		)
		s:say("c", "What are you two doing back there?", "question")
		say(s, "b", "Nothing, we're just looking at the hedge.|It's a really nice hedge.", "sweat")
		s:choice("Help them hide it.", function(ch)
			ch:n("You walked {c} the long way round, and when they got back the street was full of balloons.")
			ch:prop("balloons", "a")
			ch:voice("c", "excited", "heart", "cheer")
			ch:relx("a", "c", 8)
			ch:relx("b", "c", 8)
			ch:mood("c", 8)
		end)
		s:choice("Let {c} find out.", function(ch)
			say(ch, "c", "Is that a cake behind the hedge?|Is it for me?", "sparkle")
			ch:say("a", "...Surprise.", "sweat")
			ch:relx("a", "c", 4)
			ch:mood("c", 4)
		end)
		s:log("{a} and {b} planned a surprise for {c}.")
		return s:done()
	end,
})

event({
	id = "referee",
	actors = 3,
	when = "day",
	weight = W({ base = 0.12, count = 3 }),
	scene = function(ctx, a, b, c)
		local d = ctx.rng:pick(Chatter.Debates)
		local s = K.scene(ctx, "Settle it"):with({ q = d.q })
		say(s, "a", "{c}, you can decide this one.|{q}", "question", "point")
		s:say("a", d.yes, "anger")
		s:say("b", d.no, "anger")
		burst(s, "c", {
			gentle = "You're both a little bit right, so now you have to hug.",
			proud = "You're both wrong, and I'm right.|Next question.",
			easygoing = "Does it really matter?|Let's just get lunch.",
			cheeky = "not saying until someone buys me a bun",
			cool = "Hm. {b} is right.",
			prickly = "Why am I always the one?|...Fine, it's {a}.",
			dramatic = "I've heard both sides, and I need a whole day to think.",
			bookish = "Actually, it depends what you mean by it, so let's define our terms first.",
			gloomy = "Neither of you, because nobody's ever right.",
			polite = "I really couldn't say, you both make good points.",
			foodie = "Can we talk about this over lunch?",
			nervous = "P-please don't make me pick.",
			_ = "I'm not getting involved.|...Okay, I'm getting involved, and it's {b}.",
		}, "question")
		s:relx("a", "b", 2)
		s:relx("a", "c", 2)
		s:relx("b", "c", 2)
		s:log("{c} settled an argument between {a} and {b}.")
		return s:done()
	end,
})

-- best friends -----------------------------------------------------------------------------------
-- As close as two villagers get: there is no romance (the user: "remove any romance, just best
-- friends is the highest"). K.BestFriends is the score for it.

-- A thank you that has waited too long, said up on the roof at sunset (Data/Cutscenes has its
-- script: two lines, then after the answer a heart line, a line, and the narrator; so each is
-- one message here, never a burst).
event({
	id = "thanks",
	when = "day",
	weight = W({ base = 0.3, rel = 55 }),
	scene = function(ctx, a, b)
		local s = K.scene(ctx, "Saying thank you")
		s:n("{a} has been pacing up and down the roof for an hour.")
		s:by("a", {
			nervous = "{player}, {b} looked after me all week when I was ill, and I never said thank you. Sh-should I go and say it now?",
			prickly = "{player}, {b} looked after me when I was ill and I never thanked them. Don't look at me like that.",
			shy = "Um, {player}, {b} sat with me all week when I was ill, and I never thanked them. Do you think I should?",
			proud = "{player}, {b} looked after me when I was ill, and I ought to thank them properly. I should, shouldn't I?",
			_ = "{player}, {b} looked after me all week when I was ill, and I never said thank you. Should I?",
		}, "sweat")
		s:choice("Go and say it.", function(ch)
			ch:by("a", {
				proud = "{b}, thank you for the soup and for sitting up with me last week. There, I said it.",
				shy = "{b}, um, thank you for the soup and for staying with me. I should have said it sooner.",
				bold = "{b}, thanks for the soup and for everything last week. I mean it.",
				prickly = "{b}, thanks for the soup and for sitting up with me. Don't make it a whole thing.",
				dramatic = "{b}, you SAVED me last week with that soup. I'll never forget it.",
				gloomy = "{b}, you didn't have to look after me, but you did. Thanks.",
				polite = "{b}, thank you for looking after me last week. It meant a great deal to me.",
				nervous = "{b}, th-thank you for the soup and for staying. Sorry it took me so long to say it.",
				cheeky = "{b}, ok, i'm being serious for one second. thank you for the soup.",
				_ = "{b}, I never thanked you for the soup and for sitting with me. It meant a lot.",
			}, "heart")
			ch:by("b", {
				shy = "Oh, you didn't have to say anything, but I'm really glad you did.",
				proud = "It was very good soup, naturally. But thank you, really.",
				cheeky = "i know, i've been waiting weeks for this. come here.",
				cool = "Anytime. I mean that.",
				prickly = "...Took you long enough. Come here.",
				foodie = "It was my best soup, and you deserved it. Thank you for saying so.",
				gentle = "Oh, you, of course I did. You'd have done the same for me.",
				_ = "Oh, you didn't have to, but I'm glad you did.",
			}, "heart", "cheer")
			ch:n("They stayed up there until the sun went down.")
			ch:rel(8)
			ch:mood("a", 10)
			ch:mood("b", 10)
			ch:hearts("a", 2)
		end)
		s:choice("Wait for a better moment.", function(ch)
			ch:by("a", {
				shy = "Um, I'll do it tomorrow, I think.",
				proud = "Tomorrow, then, when the moment's right.",
				nervous = "T-tomorrow, yes, that gives me time to practise.",
				_ = "You're right, I'll do it tomorrow.",
			}, "sweat")
			ch:mood("a", -2)
		end)
		s:default(2)
		s:log("{a} thanked {b} properly at last.")
		return s:done()
	end,
})

-- Best friends keep a day for each other now and then. The cutscene goes where the plan in the
-- first line says (Data/Cutscenes: three lines, one message each).
local DAYS = {
	"a picnic on the beach",
	"a walk along the sand at sunset",
	"ice cream by the fountain",
	"an afternoon counting boats from the pier",
	"a concert at the bandstand",
}

event({
	id = "dayout",
	when = "day",
	weight = W({ base = 0.5, rel = K.BestFriends }),
	scene = function(ctx, a, b)
		local s = K.scene(ctx, "A day out"):with({ plan = ctx.rng:pick(DAYS) })
		s:n("{a} and {b} went out for {plan}, the way they do every few weeks.")
		s:by("b", {
			nervous = "Same time next month? I'll remind you, in case you forget.",
			dramatic = "Same time next month, because it's a TRADITION now.",
			sunny = "Let's do this again next month, okay? Say yes!",
			cheeky = "same time next month, you're coming, i already checked",
			_ = "Same time next month?",
		}, "heart")
		s:by("a", {
			proud = "It's already in my diary, in pen.",
			cheeky = "same time tomorrow, more like",
			shy = "I'd like that a lot.",
			cool = "Obviously. I'll be there.",
			prickly = "Obviously, and don't be late.",
			foodie = "Yes, and next time I'm bringing twice as many snacks.",
			gloomy = "If it doesn't rain... yes.",
			_ = "Of course I'll come.",
		}, "heart")
		s:rel(6)
		s:mood("a", 6)
		s:mood("b", 6)
		s:log("{a} and {b} went out for {plan}.")
		return s:done()
	end,
})

-- Two who turn out to have the same hobby.
event({
	id = "samehobby",
	when = "day",
	weight = W({
		base = 0.3,
		rel = 10,
		cond = function(ctx, a, b)
			local x, y = ctx.v(a), ctx.v(b)
			return x.hobby ~= nil and x.hobby == y.hobby and Sayings.hobby(x.hobby) ~= nil
		end,
	}),
	scene = function(ctx, a, b)
		local hobby = Sayings.hobby(ctx.v(a).hobby) or Sayings.hobbies[1]
		local s = K.scene(ctx, "Same here"):with({ hobby = hobby.name })
		say(s, "a", "Wait, you're into {hobby} too?", "question", "point")
		burst(s, "b", {
			proud = "I'm quite good at it, actually, so you can watch me.",
			shy = "I didn't think anyone else was, so I never said.",
			bold = "Every evening.|Want to see who's better, then?",
			cool = "Yeah, for years.",
			bookish = "For years, actually.|Do you want to see my notes?",
			nervous = "I-I am, is that okay?|I'm not very good at it yet.",
			_ = "Since I was little.|Why didn't you ever say?",
		}, "sparkle")
		s:n("They spent the rest of the afternoon at it, comparing notes and getting in each other's way.")
		s:rel(10)
		s:mood("a", 4)
		s:mood("b", 4)
		s:memo("a", "It turns out {b} is into {hobby} too, so we do it together on Thursdays now.")
		s:log("{a} and {b} found out they're both into {hobby}.")
		return s:done()
	end,
})

-- Best friends know each other's order.
event({
	id = "usual",
	when = "day",
	weight = W({ base = 0.3, rel = K.BestFriends }),
	scene = function(ctx, a, b)
		local s = K.scene(ctx, "The usual")
		s:n("{a} got to the café first and ordered for {b} without asking.")
		s:say("b", "How did you know I wanted the toasted one?", "question")
		burst(s, "a", {
			cheeky = "you always want the toasted one|you're very easy to read, hehe",
			gentle = "You had that look on your face, the toasted one look.",
			proud = "I notice things, it's a gift.",
			cool = "You always get it.",
			bookish = "You've been here thirty one times and had the toasted one every time.|I keep track.",
			foodie = "It's the best thing on the menu, and you have good taste.",
			_ = "You've had it every single time for a year.",
		}, "heart")
		s:rel(5)
		s:mood("b", 4)
		s:log("{a} ordered for {b} and got it right.")
		return s:done()
	end,
})

-- best friends make it official
event({
	id = "bracelets",
	when = "day",
	weight = W({ base = 0.1, rel = 60 }),
	scene = function(ctx, a, b)
		local s = K.scene(ctx, "Best friends")
		s:n("{a} made two friendship bracelets out of string and gave one to {b}.")
		say(s, "a", "There's one for each of us, so now it's official.", "heart")
		burst(s, "b", {
			proud = "I'll wear it every day, on my good wrist.",
			shy = "...!|I've never had one before.",
			bold = "Best friends, and no take backs!",
			cool = "...Thanks. I'm keeping it on.",
			prickly = "It's a bit itchy.|...I'm never taking it off.",
			dramatic = "I'll wear it until the string falls apart, and then I'll keep the string.",
			gloomy = "Nobody's ever made me one before.|...I like it.",
			_ = "I'm never taking it off.",
		}, "heart", "cheer")
		s:rel(10)
		s:log("{a} and {b} swapped friendship bracelets.")
		return s:done()
	end,
})

-- newer ones -----------------------------------------------------------------------------------------

-- a jigsaw with its last piece gone
event({
	id = "jigsaw",
	when = "any",
	weight = W({ base = 0.12, rel = 0, traits = { focus = 0.2 } }),
	scene = function(ctx, a, b)
		local s = K.scene(ctx, "The last piece")
		s:prop("boardgame", "a")
		s:n("{a} and {b} have spent three evenings on a thousand piece jigsaw of the harbour.")
		burst(s, "a", {
			nervous = "Oh no, oh no, one piece is missing.|I've checked the box four times.",
			gloomy = "One piece is missing, right in the middle, as usual.",
			dramatic = "A piece is MISSING, the very last one.|I can't bear it.",
			bookish = "There are nine hundred and ninety nine pieces here.|I counted twice, so one's definitely missing.",
			_ = "One piece is missing, and it's the last one.",
		}, "sweat")
		burst(s, "b", {
			cool = "Check your sleeve.",
			cheeky = "hehe, it wasn't me",
			_ = "It has to be around here somewhere.",
		}, "question")
		s:n("It was in {b}'s sock.")
		burst(s, "b", {
			proud = "I was keeping it safe.",
			prickly = "Don't look at me like that.|Socks are basically pockets for feet.",
			nervous = "H-how did it get there?|Is my other sock okay?",
			_ = "How did it get in my sock?",
		}, "sweat")
		s:voice("a", "laugh", "music", "laugh")
		s:rel(7)
		s:log("{a} and {b} finished a jigsaw. The last piece was in {b}'s sock.")
		return s:done()
	end,
})

-- cuttings over the garden fence
event({
	id = "cuttings",
	when = "day",
	weight = W({ base = 0.11, rel = 5, traits = { kind = 0.2 }, season = { 1, 2, 3 } }),
	scene = function(ctx, a, b)
		local s = K.scene(ctx, "Over the fence")
		s:n("{a} and {b} are swapping cuttings over the garden fence.")
		burst(s, "a", {
			bookish = "This is a geranium.|Keep it somewhere warm, I've written it on the pot.",
			nervous = "It's a geranium, so don't let it get cold.|Or too hot, or too wet, or too dry.",
			cool = "It's a geranium. Keep it warm.",
			_ = "Here's a geranium, just don't let it get cold.",
		}, "idea")
		burst(s, "b", {
			cheeky = "here's some mint|it'll take over your whole garden, good luck",
			gloomy = "This is mint.|It'll take over everything, as usual.",
			foodie = "Mmm, this is mint, and it's lovely in tea and on peas.",
			polite = "And this is mint, with my thanks.|I'm afraid it does spread.",
			_ = "Here's some mint, but it spreads, so you've been warned.",
		}, "music")
		s:rel(6)
		s:memo("b", "{a} gave me a geranium and I've named it, but I'm not telling you the name, {player}.")
		s:log("{a} and {b} swapped cuttings over the fence.")
		return s:done()
	end,
})

-- one fence, two colours, and you settle it
event({
	id = "fencepaint",
	when = "day",
	weight = W({ base = 0.1, rel = -10, weather = { "clear", "cloudy", "blossom", "leaves" } }),
	scene = function(ctx, a, b)
		local s = K.scene(ctx, "One fence")
		s:n("{a} and {b} are painting the fence between their gardens, one side each.")
		say(s, "a", "I'm painting mine white, like a fence should be.", "point")
		local own = K.byPers(ctx, ctx.stars.b, {
			dramatic = "lilac",
			cheeky = "spotty",
			bold = "bright red",
			dreamy = "sea green",
			sunny = "sunflower yellow",
			gloomy = "dark grey",
			_ = "pale blue",
		})
		s:with({ colour = own })
		burst(s, "b", {
			dramatic = "Mine's lilac, because it makes a statement.",
			cheeky = "mine's got spots|hehe",
			gloomy = "Mine's grey, so it matches the sky.",
			_ = "Mine's {colour}, and it looks nicer.",
		}, "sparkle")
		burst(s, "a", {
			prickly = "It's a fence, it doesn't need a personality.",
			nervous = "B-but it doesn't match.|Doesn't a fence have to match?",
			_ = "It doesn't match, and a fence has to match.",
		}, "anger")
		say(s, "b", "{player}, you choose.|Whatever you say, the whole fence goes that colour.", "question")
		s:choice("Paint it all white.", function(c)
			burst(c, "a", {
				proud = "White, naturally.|I'll go and get the big brush.",
				bookish = "Actually, white reflects the most light, so it's the practical choice.",
				prickly = "Good, that's sensible.|...Thanks, {player}.",
				nervous = "You picked white?|Oh, phew, thank you.",
				_ = "White it is.|Thank you, {player}.",
			}, "sparkle", "cheer")
			burst(c, "b", {
				gloomy = "White, fine, plain like everything else.",
				dramatic = "White, the colour of giving up.|Fine.",
				_ = "Fine, white, it's boring but fine.",
			}, "sweat")
			c:rel(2)
			c:mood("a", 3)
			c:mood("b", -1)
		end)
		s:choice("Paint it all {colour}.", function(c)
			burst(c, "b", {
				dramatic = "The whole fence in {colour}?|People will come from miles away to see it.",
				cheeky = "spots everywhere|best fence in town, hehe",
				sunny = "Yes, yes!|I'll go and get more paint!",
				_ = "The whole fence in {colour}, and it's going to look great.",
			}, "sparkle", "cheer")
			burst(c, "a", {
				gloomy = "Fine, a party fence, great.",
				_ = "Fine, but everyone's going to stare at it.",
			}, "sweat")
			c:rel(2)
			c:mood("b", 3)
			c:mood("a", -1)
		end)
		s:choice("Leave it half and half.", function(c)
			c:n("The fence stayed half and half, and people stop to look at it.")
			c:say("a", "It's growing on me, actually.", "heart")
			c:say("b", "It's the only fence like it in town.", "heart")
			c:rel(6)
		end)
		s:log("{a} and {b} painted a fence.")
		return s:done()
	end,
})

-- three teas
event({
	id = "teatasting",
	when = "any",
	weight = W({ base = 0.11, rel = 0 }),
	scene = function(ctx, a, b)
		local s = K.scene(ctx, "Three teas")
		s:n("{a} has lined up three cups of tea and won't let {b} leave until they've tried them all.")
		burst(s, "a", {
			foodie = "Take a sip and really think about it before you tell me.",
			bookish = "These come from three different hills.|You're meant to be able to taste the difference.",
			proud = "I blended one of these myself.|Guess which, and here's a hint, it's the best one.",
			_ = "Which one's best?|Be honest with me.",
		}, "question")
		burst(s, "b", {
			cool = "Hm. The middle one.",
			gloomy = "They all taste like tea to me... maybe the middle one?",
			polite = "They're all lovely, but if I had to choose, the middle one.",
			dramatic = "The middle one tastes like a rainy afternoon with a good book.",
			foodie = "Mmm, the middle one is smoky with a bit of honey at the end.|Am I right?",
			_ = "The middle one, I think.",
		}, "sparkle")
		burst(s, "a", {
			foodie = "Yes, yes!|Finally, someone who gets it.",
			proud = "Correct, that's the one I blended.|You've got good taste.",
			_ = "The middle one, good, I'll make that one again.",
		}, "heart")
		s:rel(5)
		s:log("{a} made {b} taste three teas.")
		return s:done()
	end,
})

-- two who can't sleep, at the fountain
event({
	id = "nightowls",
	when = "night",
	weight = W({ base = 0.12, rel = -10 }),
	scene = function(ctx, a, b)
		local s = K.scene(ctx, "Night owls")
		s:n("{a} couldn't sleep, so they went for a walk and found {b} already sitting on the fountain wall.")
		s:say("a", "You can't sleep either?", "question")
		burst(s, "b", {
			gloomy = "I never can, as usual.|The fountain's good company, though.",
			dreamy = "Hmm... the moon was so bright it kept me awake.",
			nervous = "I kept thinking I'd left the gate open.|I checked twice, and it was shut.",
			foodie = "I got up for toast, and then I just kept walking.",
			easygoing = "*yawn* I fell asleep at six in the evening, so now I'm wide awake.",
			cool = "Hm. I couldn't settle.",
			_ = "No, I couldn't settle.",
		}, "zzz")
		s:n("They sat and listened to the water until the sky went light.")
		burst(s, "a", {
			prickly = "Same time tomorrow?|...I hope not, but maybe.",
			_ = "Same time tomorrow?|Hopefully not.",
		}, "laugh", "laugh")
		s:rel(7)
		s:log("{a} and {b} met at the fountain at two in the morning.")
		return s:done()
	end,
})

-- rock, paper, scissors for the comfy chair
event({
	id = "rps",
	when = "day",
	weight = W({ base = 0.11 }),
	scene = function(ctx, a, b)
		local s = K.scene(ctx, "The comfy chair")
		s:n("There's one comfy chair in the café, and {a} and {b} got there at the same time.")
		say(s, "a", "Rock, paper, scissors for it, best of one.", "idea", "point")
		burst(s, "b", {
			proud = "Best of three, because I always win best of three.",
			nervous = "O-okay, wait, what beats what again?",
			cool = "Fine, go.",
			_ = "Fine, on three.",
		}, "question")
		local w, l = winner(ctx, a, b)
		s:n("It went to best of five in the end.")
		s:voice(w, "brag", "sparkle", "cheer")
		loses(s, ctx, l, ctx.stars[l])
		s:rel(3)
		s:log("{a} and {b} played rock, paper, scissors for the comfy chair.")
		return s:done()
	end,
})

-- a walk home after work
event({
	id = "walkhome",
	when = "day",
	weight = W({
		base = 0.12,
		job = "any",
		rel = 10,
		cond = function(ctx)
			return ctx.hour >= 15
		end,
	}),
	scene = function(ctx, a, b)
		local s = K.scene(ctx, "The walk home"):with({ job = K.workplace(ctx, a) })
		s:n("{a} finished at the {job} and found {b} waiting where the road bends.")
		burst(s, "a", {
			sunny = "You waited for me!|That's so nice, thank you!",
			prickly = "You didn't have to wait.|...But thanks for waiting.",
			gloomy = "You waited for me?|Heh... that's nice.",
			cool = "Hey. Want to walk home together?",
			nervous = "Y-you waited? How long were you here?|Sorry, and thank you.",
			_ = "Oh, you waited for me.",
		}, "heart")
		burst(s, "b", {
			foodie = "The bakery's on the way, and I wanted someone to share the buns with.",
			bookish = "I was reading and lost track of time, and then you came out.",
			cheeky = "i was just standing here|total coincidence, hehe",
			_ = "I thought we could walk back together.",
		}, "music")
		s:n("They walked home the long way, past the harbour.")
		s:rel(6)
		s:mood("a", 3)
		s:log("{b} met {a} after work and they walked home together.")
		return s:done()
	end,
})

-- the two of them made you something
event({
	id = "foryou",
	when = "day",
	weight = W({
		base = 0.07,
		rel = 30,
		cond = function(ctx, a, b)
			return (ctx.v(a).mood or 50) >= 40 and (ctx.v(b).mood or 50) >= 40
		end,
	}),
	scene = function(ctx, a, b)
		local s = K.scene(ctx, "For you")
		s:n("{a} and {b} have been hiding something behind their backs all afternoon.")
		burst(s, "a", {
			sunny = "{player}, close your eyes, okay?|...Okay, now open them!",
			shy = "Um, {player}, we made you something.|You don't have to like it, though.",
			proud = "{player}, we made you something, and it's very good.",
			cheeky = "{player}, guess what's behind my back|wrong, guess again",
			gloomy = "{player}, we made you something.|It's probably not your sort of thing.",
			dramatic = "{player}, we have a GIFT for you, from both of us.",
			polite = "{player}, we'd like you to have this.|It's from both of us.",
			_ = "{player}, we made you something.",
		}, "sparkle")
		burst(s, "b", {
			foodie = "It's a cushion.|I wanted to stitch a cake on it, but I was outvoted.",
			nervous = "It's a cushion, is that okay?|The stitching's a bit wonky on one side.",
			bookish = "It's a cushion with forty rows of stitches.|I counted them.",
			_ = "It's a cushion for your house, and {a} did the stitching.",
		}, "heart")
		s:choice("I love it.", function(c)
			c:voice("a", "excited", "sparkle", "cheer")
			c:voice("b", "happy", "heart")
			c:keep("keep_cushion", "a")
			c:rel(6)
			c:mood("a", 4)
			c:mood("b", 4)
		end)
		s:choice("Did you stitch it yourselves?", function(c)
			say(c, "b", "We did, and that corner's a bit wonky, so don't look too closely.", "sweat")
			c:voice("a", "laugh", "music", "laugh")
			c:keep("keep_cushion", "a")
			c:rel(6)
			c:mood("b", 2)
		end)
		s:log("{a} and {b} made you a cushion.")
		return s:done()
	end,
})

-- skipping stones
event({
	id = "skipstones",
	when = "day",
	weight = W({ base = 0.11, weather = { "clear", "cloudy", "blossom" } }),
	scene = function(ctx, a, b)
		local s = K.scene(ctx, "Skipping stones")
		s:n("{a} and {b} are skipping stones off the beach.")
		say(s, "a", "Did you see that?|That one skipped four times.", "sparkle", "point")
		burst(s, "b", {
			bold = "Hah, watch this one.|Seven!",
			nervous = "Mine sank straight down.|I-is that allowed?",
			bookish = "Actually, it's all in the wrist and the angle, about twenty degrees.",
			dreamy = "Mine went plop...|I liked the plop.",
			_ = "Watch this one.|...Two, but it still counts.",
		}, "question")
		local w, l = winner(ctx, a, b)
		s:n("{" .. w .. "} got eight skips on the last throw.")
		s:voice(w, "brag", "sparkle", "cheer")
		loses(s, ctx, l, ctx.stars[l])
		s:rel(4)
		s:log("{a} and {b} skipped stones on the beach.")
		return s:done()
	end,
})

-- counting birds on the hill
event({
	id = "birdcount",
	when = "day",
	weight = W({ base = 0.1, weather = { "clear", "cloudy", "blossom", "leaves" } }),
	scene = function(ctx, a, b)
		local s = K.scene(ctx, "Counting birds")
		s:n("{a} and {b} are sitting on the hill with a notebook, counting birds for the town's list.")
		say(s, "a", "That's eleven gulls and three sparrows so far.|What's that one?", "question", "point")
		burst(s, "b", {
			bookish = "That's a wagtail.|See how its tail bobs up and down?",
			gloomy = "Heh... it's a gull, it's always a gull.",
			dramatic = "That's the rarest bird I've ever seen!|Write it down in capitals.",
			cool = "It's a pigeon.",
			cheeky = "that's a pigeon in a little hat|hehe",
			_ = "No idea, just write 'small brown one'.",
		}, "idea")
		burst(s, "a", {
			bookish = "I'll draw it, and we can look it up later.",
			_ = "I'm putting a question mark next to it.",
		}, "sweat")
		s:rel(5)
		s:memo("a", "We counted forty birds on the hill, and one of them is still a mystery.")
		s:log("{a} and {b} counted birds on the hill.")
		return s:done()
	end,
})

-- one was ill, and the other turned up with soup without being asked
event({
	id = "soupvisit",
	when = "day",
	weight = W({ base = 0.1, rel = 10, btraits = { kind = 0.3 } }),
	scene = function(ctx, a, b)
		local s = K.scene(ctx, "Soup at the door")
		s:n("{a} has had a cold all week, and this morning {b} knocked with a pot of soup.")
		burst(s, "b", {
			gentle = "I heard you were poorly, so I made soup.|You can say no, but I'm leaving it anyway.",
			bold = "You're ill, so I brought soup.|You're eating it, and that's not up for debate.",
			prickly = "I made too much soup, and that's the only reason I'm here.|...How's the cough?",
			foodie = "It's chicken and barley, and it's been on the stove for two days.|Eat it while it's hot.",
			nervous = "H-hi, sorry, I made soup.|I didn't know what else to do, is that okay?",
			cheeky = "soup delivery|tips welcome, hehe",
			_ = "I heard you were ill, so I made you some soup.",
		}, "heart")
		burst(s, "a", {
			gloomy = "For me?|Heh... thanks.",
			proud = "I was managing perfectly well.|...It does smell very good.",
			shy = "Oh... thank you.|You didn't have to do that.",
			cool = "...Thanks. I mean it.",
			dramatic = "You've SAVED me.|Come in, just don't get too close.",
			_ = "Oh, you didn't have to do that.|Thank you.",
		}, "heart")
		s:n("{b} stayed to make sure the whole bowl got finished.")
		s:rel(9)
		s:mood("a", 6)
		s:memo("a", "{b} brought me soup when I was ill, and I'm going to pay that back.")
		s:log("{b} brought {a} soup when they were ill.")
		return s:done()
	end,
})

-- a lost bet, paid in the square
local FORFEITS = {
	"sing a song on the fountain steps",
	"wear their jumper backwards all day",
	"say good morning to every gull on the pier",
	"carry the other one's shopping for a week",
}

event({
	id = "forfeit",
	when = "day",
	weight = W({ base = 0.09, rel = 0, traits = { mischief = 0.2 } }),
	scene = function(ctx, a, b)
		local s = K.scene(ctx, "A bet's a bet"):with({ forfeit = ctx.rng:pick(FORFEITS) })
		s:n("{a} lost a bet to {b}, and now has to {forfeit}.")
		burst(s, "a", {
			proud = "I'm doing this with dignity, so don't look.",
			shy = "Do I really have to?|...I have to, don't I?",
			dramatic = "If this is the end of me, let it be remembered.",
			cheeky = "you'll pay for this|in buns",
			gloomy = "Of course I lost, as usual.",
			_ = "Fine, a bet's a bet.",
		}, "sweat")
		burst(s, "b", {
			cheeky = "go on then, we're all waiting",
			gentle = "You can skip it if it's too much.|...You're doing it anyway, aren't you?",
			proud = "Rules are rules.",
			bold = "Go on, and do all of it.",
			_ = "Go on, then.",
		}, "laugh", "laugh")
		s:n("{a} did all of it, and a few people clapped.")
		burst(s, "a", {
			proud = "Flawless, naturally.|The next bet's mine.",
			shy = "That was awful...|...but it was a bit fun, too.",
			_ = "Done.|Rematch next week?",
		}, "sparkle")
		s:rel(4)
		s:mood("b", 3)
		s:log("{a} paid off a lost bet to {b}.")
		return s:done()
	end,
})

return list
