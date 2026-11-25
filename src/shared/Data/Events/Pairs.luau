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
		sunny = "Aww, you win this time!|Rematch tomorrow?",
		dreamy = "Oh... I lost? I was watching the clouds.",
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

-- the winner's line, after any game or contest
local WINS = {
	sunny = "I won? Ehehe, I won!",
	gentle = "Oh, my, I think I won.",
	bold = "Hah! Told you I'd win.",
	dreamy = "Oh... did I win? I wasn't really keeping track.",
	easygoing = "Huh, I won, and I wasn't even trying.",
	proud = "Naturally, I win again.",
	shy = "Um... I think I won?",
	cheeky = "hehe, i win, pay up",
	cool = "Easy.",
	prickly = "Obviously. Was there ever any doubt?",
	dramatic = "VICTORY! Everyone remember this day!",
	bookish = "Exactly as I planned it.",
	gloomy = "I won? Heh, that never happens.",
	polite = "Oh, I won? Thank you, that was fun.",
	foodie = "I win, so the loser buys the buns.",
	nervous = "I-I won? I actually won!",
	_ = "Ha, I win!",
}

-- the one whose cake lost the bake off
local SULK = {
	proud = "Hmph. I'll eat mine on my own, then.",
	gentle = "Oh, well done, it was fun to make mine anyway.",
	shy = "Oh, that's okay.|Yours did look nicer than mine.",
	bold = "Fine, but I want a rematch next week with bigger cakes.",
	easygoing = "Eh, that just means more cake for me.",
	cheeky = "fine, but i'm hiding the winning one|hehe",
	cool = "Hm, that's fair.",
	prickly = "Whatever, mine tastes better and you know it.",
	dramatic = "My cake has been REJECTED.|I need to go and lie down.",
	gloomy = "Heh... I knew mine wouldn't win.",
	polite = "Congratulations, it really was a lovely cake.",
	foodie = "Fine, but I'm having a slice of both, for research.",
	nervous = "W-was mine bad?|It was the icing, wasn't it?",
	sunny = "Aww, okay!|Yours was really good, and I'll try harder next time.",
	dreamy = "Oh... that's okay.|Mine was a bit lopsided anyway.",
	bookish = "Fair enough.|I'll find out what I did wrong, it was probably the oven.",
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
			sunny = "Your move, your move!|Ehehe, I can't wait to see what you do.",
			gentle = "It's your move, take your time, okay?",
			bold = "Your move, and make it a good one.",
			dreamy = "Hmm... is it your move? I lost track.",
			easygoing = "Your move, no rush, I'm comfy.",
			proud = "Your move, though I've already won, naturally.",
			shy = "Um... it's your move.",
			prickly = "It's your move, and you're taking forever.",
			bookish = "Your move, and I've already worked out your next three.",
			gloomy = "It's your move.|Heh... I've lost already, haven't I?",
			polite = "It is your move, whenever you are ready.",
			foodie = "Your move, and hurry, I'm getting hungry.",
			_ = "It's your move.|Take your time, just not all of it.",
		}, "question")
		local w, l = winner(ctx, a, b)
		s:n("One move later, the game was over.")
		burst(s, w, WINS, "sparkle", "cheer")
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
				cool = "Hm, a draw's fine.",
				sunny = "A draw, so we both win!",
				bold = "A draw? Fine, but next time I'm winning.",
				dreamy = "A draw... that's nice, nobody's sad.",
				easygoing = "A draw works for me, less effort.",
				prickly = "Ugh, fine, a draw.|I was winning, though.",
				dramatic = "A DRAW? After all that?|...Fine, I accept.",
				bookish = "A draw is the fairest result, actually.",
				foodie = "A draw, so we both buy the buns.",
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
			sunny = "Ooh, yes, I love thumb wars!",
			gentle = "All right, but gently, okay?",
			bold = "Hah, you're on, and I don't lose.",
			dreamy = "A thumb war...? Okay.",
			easygoing = "Sure, as long as I can stay sitting down.",
			proud = "Very well, get ready to lose.",
			shy = "Um... okay, I'll try.",
			prickly = "Fine, but no cheating.",
			bookish = "I've read about this, actually, it's all in the wrist.",
			gloomy = "Okay.|Heh... I'll lose.",
			polite = "Very well, may the best thumb win.",
			foodie = "Okay, and the winner gets the last bun.",
			_ = "You're on.",
		}, "sparkle")
		s:n("It got very serious, and {a} kept making up new rules halfway through.")
		local w, l = winner(ctx, a, b)
		burst(s, w, WINS, "sparkle", "cheer")
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
				sunny = "Wait, you knew it? Ehehe, how?",
				gentle = "Oh my, you got it so fast.",
				bold = "Hah, you got it, how?",
				dreamy = "Oh... you knew it already?",
				easygoing = "Huh, you got it, nice.",
				proud = "You got it? Well, it was an easy one.",
				shy = "Oh... you knew it.",
				cool = "You got it.|How?",
				bookish = "You got it, so where did you hear it?",
				gloomy = "You knew it.|Heh... of course you did.",
				polite = "Well done, how did you know?",
				foodie = "You got it! Who told you, the baker?",
				nervous = "Y-you knew it? Did I say it wrong?",
				_ = "How did you know that one?",
			}, "anger")
			burst(s, "b", {
				sunny = "Ehehe, I heard it at the bakery last week!",
				gentle = "My grandma used to tell me that one.",
				bold = "Hah, easy.",
				dreamy = "Hmm... it just came to me.",
				easygoing = "Lucky guess, honestly.",
				proud = "I know all the riddles, naturally.",
				shy = "Um, I think I heard it somewhere...",
				cheeky = "i'll never tell, hehe",
				cool = "Everyone knows that one.",
				prickly = "Because it's an old one, obviously.",
				dramatic = "I am simply a GENIUS.",
				bookish = "It's in a riddle book at the library, actually.",
				gloomy = "It's the only one I know, heh.",
				polite = "I'm afraid I've heard it before.",
				foodie = "My brain works better after lunch.",
				nervous = "I-I just guessed, honestly!",
				_ = "Lucky guess.",
			}, "sparkle")
		else
			burst(s, "b", {
				sunny = "Wait, wait, I know this one...|No, I don't, it's gone.",
				bookish = "Give me a moment, I've definitely read this one somewhere.",
				proud = "It's on the tip of my tongue, so don't you dare tell me.",
				nervous = "Oh no, I-I'm really bad at riddles.",
				gloomy = "Heh... I never get these.",
				cheeky = "is it a trick question?",
				cool = "Hm, no idea.",
				dreamy = "Hmm... a shark with very good manners?",
				gentle = "Oh, let me think... no, I don't know.",
				bold = "Give me a second, I'll get it.|...No, I won't, tell me.",
				easygoing = "Eh, I give up, too much thinking.",
				shy = "Um... I don't know, sorry.",
				prickly = "Ugh, I hate riddles.|Just tell me.",
				dramatic = "This riddle is TORTURE.|Tell me before I faint.",
				polite = "I am afraid I do not know.|What is it?",
				foodie = "Is it something you can eat?|No? Then I give up.",
				_ = "Hmm, I give up, so what is it?",
			}, "question")
			s:say("a", "{ans}", "sparkle", "cheer")
			burst(s, "b", {
				bookish = "Actually, that's barely a riddle.|...I didn't get it, though.",
				gloomy = "Heh... I'd never have got that.",
				proud = "I knew that, I was just letting you have it.",
				sunny = "Oh! Ehehe, of course it is!",
				gentle = "Oh, that's a clever one.",
				bold = "Hah, that's a good one, I'll admit it.",
				dreamy = "Oh... that's a nice answer.",
				easygoing = "Huh, okay, that's fair.",
				shy = "Oh... I should have got that.",
				cheeky = "ok that's good, i'm stealing it",
				cool = "Hm, good one.",
				prickly = "Ugh, that's so obvious now.",
				dramatic = "Of COURSE! How did I miss it?",
				polite = "Oh, how clever, well done.",
				foodie = "Oh, of course, I think better after lunch.",
				nervous = "Oh no, that was easy, wasn't it? Sorry.",
				_ = "Oh, come on, that's not fair.",
			}, "sweat")
		end
		s:rel(4)
		s:log("{a} asked {b} a riddle.")
		return s:done()
	end,
})

-- the one whose cake won
local BAKE_WON = {
	sunny = "Mine won? Ehehe, I'm so happy!",
	gentle = "Oh, my, thank you, I'm so pleased.",
	bold = "Hah! I knew it all along.",
	dreamy = "Hmm... really? Mine?",
	easygoing = "Oh, nice, and I didn't even follow the recipe.",
	proud = "Naturally, it was never in doubt.",
	shy = "Mine? Oh... thank you.",
	cheeky = "hehe, told you mine was better",
	cool = "Hm, good.",
	prickly = "Obviously. Did you even taste the other one?",
	dramatic = "My cake is VICTORIOUS!",
	bookish = "I did follow the recipe exactly, actually.",
	gloomy = "Mine won? Heh, that's a first.",
	polite = "Oh, thank you, that's very kind.",
	foodie = "Yes! All that practice paid off.",
	nervous = "R-really? Mine? Oh, phew.",
	_ = "Ha, mine won!",
}

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
			sunny = "Mine's strawberry, with little hearts on top!",
			gentle = "Mine's a simple sponge with jam.|I made it with lots of care, okay?",
			bold = "Mine's the biggest, so it wins, right?",
			dreamy = "Mine's lavender... it smells like a summer evening.",
			easygoing = "Mine's a banana cake, it's the easiest one I know.",
			shy = "Um... mine's vanilla.|It's nothing special.",
			cool = "Mine's coffee and walnut.",
			prickly = "Mine's ginger, and don't say it's too spicy.",
			dramatic = "Mine is a towering STRAWBERRY dream.",
			bookish = "Mine's from a recipe book that's a hundred years old, and I followed it exactly.",
			gloomy = "Mine's carrot cake.|Heh... it looks a bit sad.",
			polite = "Mine is a lemon sponge, and I do hope you like it.",
			_ = "Mine's lemon, made with real lemons.",
		}, "sparkle", "point")
		burst(s, "b", {
			proud = "Mine's flawless, just look at the icing.",
			shy = "Mine came out a bit flat...|It tastes nice, though, I think.",
			gloomy = "Mine sank in the middle, as usual.|It still counts, though.",
			dramatic = "Mine is dark chocolate, as dark and mysterious as me.",
			sunny = "Mine's got sprinkles, all the colours!",
			gentle = "Mine's a little honey cake, nice and soft.",
			bold = "Mine's chocolate, and it's going to win.",
			dreamy = "Mine has little sugar stars on it...",
			easygoing = "Mine's a sponge, I made it this morning between naps.",
			cheeky = "mine's chocolate, and i licked the spoon, so it's lucky",
			cool = "Mine's chocolate.|It's good.",
			prickly = "Mine's chocolate, obviously, and it's better.",
			bookish = "Mine's chocolate, and I measured everything twice.",
			polite = "Mine is chocolate, and I hope you like it.",
			foodie = "Mine's chocolate with a salted caramel middle, mmm.",
			nervous = "Mine's chocolate... I-I hope it's not too dry.",
			_ = "Mine's chocolate, and you can't beat chocolate.",
		}, "sparkle")
		burst(s, "a", {
			cheeky = "{player}, be fair about this|which one's better",
			sunny = "{player}, you choose, and be honest!",
			gentle = "{player}, which one do you like better? Be honest, okay?",
			bold = "{player}, pick one, and pick mine.",
			dreamy = "{player}... which one do you like?",
			easygoing = "{player}, you decide, no pressure.",
			proud = "{player}, tell us which is better, though I think we know.",
			shy = "Um, {player}... which one is better?",
			cool = "{player}, which one?",
			prickly = "{player}, be fair, and don't just say both.",
			dramatic = "{player}, the moment of TRUTH has come.",
			bookish = "{player}, judge them on taste, looks and how soft they are, please.",
			gloomy = "{player}, which one's better?|Heh... I can guess.",
			polite = "{player}, would you please tell us which one you prefer?",
			foodie = "{player}, taste both, slowly, and then tell us.",
			nervous = "{player}, which one is better? Please be gentle.",
			_ = "{player}, you have to be fair about this.|Which one's better?",
		}, "question")
		s:choice("{a}'s cake.", function(c)
			burst(c, "a", BAKE_WON, "sparkle", "cheer")
			burst(c, "b", SULK, "sweat")
			c:mood("a", 6)
			c:mood("b", -4)
			c:rel(-2)
		end)
		s:choice("{b}'s cake.", function(c)
			burst(c, "b", BAKE_WON, "sparkle", "cheer")
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
				sunny = "Aww, {player}, that's so nice!|But you have to pick one!",
				bold = "Both? Come on, {player}, pick one.",
				dreamy = "Both...? Hmm, that's nice, I suppose.",
				easygoing = "Eh, both works for me.",
				cool = "That's not an answer, {player}.",
				prickly = "Ugh, that's not an answer, {player}.",
				dramatic = "BOTH? {player}, you can't do this to us!",
				bookish = "That's not really an answer, {player}, actually.",
				gloomy = "Heh... that means you don't like either.",
				polite = "How very fair of you, {player}.",
				foodie = "Both? Fine, then we eat both.",
				nervous = "Both? Oh, phew, nobody loses.",
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
			sunny = "La la la!|Ehehe, okay, I'm ready!",
			gentle = "La la... is this okay? Let's go slowly.",
			bold = "Okay, let's go, loud and clear.",
			dreamy = "La la ♪... hmm, which song were we doing?",
			easygoing = "La la... okay, I'm warmed up enough.",
			proud = "Listen closely, this is how it's done.",
			cheeky = "la la la, ok i'm ready, are you",
			cool = "Ready.|Let's go.",
			prickly = "Ugh, fine, let's just start.",
			bookish = "Before we start, it's in G, I checked.",
			gloomy = "La la...|Heh... this'll go wrong.",
			polite = "Are you ready?|Then let us begin.",
			foodie = "La la... hang on, I need some water first.",
			_ = "La la laaa.|Hang on, what key is this in?",
		}, "music")
		if ctx.rng:chance(0.55) then
			s:n("On the second try it came together, and people stopped in the street to listen.")
			burst(s, "a", {
				sunny = "Ehehe, people were clapping!",
				gentle = "Oh, my, that was lovely, wasn't it?",
				bold = "Hah! We should do that every week.",
				dreamy = "Hmm... it sounded like the sea for a moment.",
				easygoing = "Huh, that went well, nice.",
				proud = "Naturally, with me on guitar.",
				shy = "Um... people were listening to us.",
				cheeky = "we should start charging",
				cool = "That was good.",
				prickly = "Fine, that was actually good.",
				dramatic = "We were MAGNIFICENT.",
				bookish = "That was much better than the first try.",
				gloomy = "Huh, nobody threw anything.",
				polite = "What a lovely crowd, thank you all.",
				foodie = "That's better than warm bread!",
				nervous = "Th-they liked it? They actually liked it!",
				_ = "That was great, let's do it again.",
			}, "music", "cheer")
			s:rel(8)
			s:all(2)
		else
			s:n("{a} played one song while {b} sang a completely different one, very loudly.")
			burst(s, "b", {
				sunny = "Ehehe, okay, that was a mess!",
				gentle = "Oh my, we weren't even singing the same song.",
				bold = "Hah, I was louder, so I win.",
				dreamy = "Hmm... I liked my song better.",
				easygoing = "Heh, both songs were good, just not together.",
				proud = "My song was the right one, for the record.",
				shy = "Hehe, okay, that was silly.",
				cheeky = "hehe, mine was better",
				cool = "Hm, that didn't work.",
				prickly = "Ugh, you were playing the wrong song.",
				dramatic = "That was a DISASTER, and I loved it.",
				bookish = "Actually, we were in two different keys as well.",
				gloomy = "Heh... that went about as well as I expected.",
				polite = "Oh, goodness, I'm so sorry about that.",
				foodie = "I think I need a snack after that.",
				nervous = "S-sorry, was I singing the wrong one?",
				_ = "Ha, okay, that was a mess.",
			}, "music", "laugh")
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
			cool = "Hm, let's do it again.",
			nervous = "W-was it elbow then spin, or spin then elbow?|Can we go again, slower?",
			bookish = "I'm writing it down in code so nobody can copy it.",
			sunny = "Ehehe, it's perfect!|Let's do it every single time we meet.",
			gentle = "Oh, I love it.|Let's do it slowly the first few times, okay?",
			bold = "Best handshake in town, right?",
			dreamy = "Hmm... it's like a little dance.",
			shy = "Um... I like having a secret with you.",
			cheeky = "nobody else can learn it, ever, hehe",
			prickly = "This is silly.|...Do it again, I wasn't ready.",
			dramatic = "This handshake will be FAMOUS.",
			gloomy = "Heh... I'll forget it by tomorrow, but okay.",
			polite = "What a lovely idea, thank you.",
			foodie = "Let's add a bit where we share a cookie.",
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
			sunny = "Ehehe, we're so good at this!",
			gentle = "Oh, this is fun, careful with your feet, okay?",
			easygoing = "This is nice, but can we do the slow bit again?",
			proud = "I'm a natural, as you can see.",
			cheeky = "we look silly and i love it",
			cool = "Not bad.|Again.",
			bookish = "There are twelve steps, and I've got nine of them.",
			polite = "Thank you, this is very good fun.",
			foodie = "This is hungry work, so snack break?",
			nervous = "Am I doing it right? Is that okay?",
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
		burst(s, "b", {
			sunny = "Ehehe, oops!",
			gentle = "Oh, my, I'm so sorry.",
			bold = "Hah, well, mine sounded better.",
			dreamy = "Hmm... I did wonder about that.",
			easygoing = "Heh, that would explain a lot.",
			proud = "Well, you should speak more clearly.",
			shy = "Oh no... sorry.",
			cheeky = "honestly, my version was better",
			cool = "...Ah.",
			prickly = "Ugh, why didn't you say it properly?",
			dramatic = "So all of THAT was for nothing?",
			bookish = "Actually, that does make more sense.",
			gloomy = "Heh... of course I got it wrong.",
			polite = "Oh dear, I do apologise.",
			foodie = "Oh, I think I need a snack after that.",
			nervous = "Oh no, oh no, I got it all wrong.",
			_ = "Oh. That makes more sense.",
		}, "music", "laugh")
		burst(s, "a", {
			sunny = "Ehehe, it's fine, it's funnier this way!",
			gentle = "It's all right, I'm laughing too.",
			bold = "Hah, never mind, it's a good story now.",
			dreamy = "Hmm... I like your version better.",
			easygoing = "Eh, let's just go with it.",
			proud = "I'll forgive you, this once.",
			shy = "Hehe... it's okay.",
			cheeky = "i'm telling everyone about this",
			cool = "It's fine, and it's funny, actually.",
			prickly = "Ugh.|...Okay, it's a bit funny.",
			dramatic = "This will be told for GENERATIONS.",
			bookish = "I'm writing this one down.",
			gloomy = "Heh, at least it's funny.",
			polite = "Please don't worry, it's quite funny really.",
			foodie = "Let's laugh about it over lunch.",
			nervous = "It's okay, it's okay, it's funny really.",
			_ = "Ha, never mind, it's funny now.",
		}, "music", "laugh")
		s:rel(5)
		s:log("{a} and {b} mixed up a message.")
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
			sunny = "Promise me something, okay?|One day, let's watch the sunrise from the hill together!",
			gentle = "Will you promise me something, dear?|One day, let's watch the sun come up from the hill.",
			easygoing = "Promise me something, even though it means getting up early.|One day, we'll watch the sunrise from the hill.",
			proud = "I'd like a promise from you.|One day, we'll watch the sunrise from the hill, and it'll be perfect.",
			cheeky = "promise me something|one day we're watching the sunrise from the hill, even if i have to drag you",
			cool = "Promise me something.|One day, we'll watch the sunrise from the hill.",
			prickly = "Promise me something, and don't laugh.|One day, we're watching the sunrise from the hill.",
			dramatic = "Make me a PROMISE.|One day, we'll watch the sun rise over the hill together.",
			bookish = "Will you promise me something?|One day, let's watch the sunrise from the hill, it's at about six in summer.",
			gloomy = "Can you promise me something?|Heh... one day, let's watch the sunrise from the hill.",
			polite = "May I ask you for a promise?|One day, I would like us to watch the sunrise from the hill.",
			foodie = "Promise me something?|One day we'll watch the sunrise from the hill, with breakfast.",
			nervous = "Can you promise me something? It's not a big thing.|One day, let's watch the sunrise from the hill.",
			_ = "Will you promise me something?|One day we'll get up early and watch the sunrise from the hill.",
		}, "heart")
		burst(s, "b", {
			easygoing = "*yawn* That early?|...Okay, for you, I'll do it once.",
			proud = "I promise, and I always keep my promises.",
			shy = "I promise.|I'll bring a blanket for us.",
			cool = "Deal, I'll be there.",
			prickly = "Fine, I promise, but you'd better bring snacks.",
			gloomy = "It'll probably be cloudy, but I promise.",
			nervous = "I promise, but you'll have to knock really loudly.",
			sunny = "I promise, I promise!|Ehehe, I'm so excited already.",
			gentle = "I promise.|I'll bring something warm to drink.",
			bold = "Promise, and I'll be there first.",
			dreamy = "I promise...|I'll dream about it until then.",
			cheeky = "promise|but if you're late, i'm eating your breakfast",
			dramatic = "I PROMISE, with all my heart!",
			bookish = "I promise, and I'll look up the best day for it.",
			polite = "I promise, and I would be delighted.",
			foodie = "I promise, and I'll bring breakfast.",
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
			sunny = "I made so many sandwiches, ehehe!|One of them is a surprise, want to try it?",
			gentle = "I made all your favourites, I think.|There's one I'm not sure about, though, if you're brave.",
			bold = "I made a stack, so eat up.|There's one mystery one, and you're trying it.",
			dreamy = "There's one in here... I don't remember what I put in it.|Do you want to find out?",
			easygoing = "I made a few, then got bored and put everything in the last one.|Want to try it?",
			proud = "I made all of these myself, naturally.|There's one special one, and you're lucky enough to try it.",
			shy = "Um, I made sandwiches...|There's one I'm not sure about, would you try it?",
			cheeky = "i made one with a surprise in it|go on, try it hehe",
			cool = "There's one mystery sandwich.|Try it.",
			prickly = "I made too many, don't say anything.|There's one I don't remember making, so try it.",
			dramatic = "I made a FEAST.|And one sandwich is a total mystery.",
			bookish = "I made twelve sandwiches, four kinds, actually.|One of them has no label, so want to try it?",
			gloomy = "I made sandwiches.|Heh... one of them looks strange, want to try it?",
			polite = "I have made sandwiches for us both.|There is one I am not sure about, would you like to try it?",
			nervous = "I made sandwiches, but I don't know what's in one of them.|Is that okay? Do you want to try it?",
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
				sunny = "Ants! Ehehe, they're having a picnic too!",
				dreamy = "Oh... look, they're carrying the crumbs home in a little line.",
				easygoing = "Eh, let them have it, I'm full anyway.",
				proud = "Excuse me, ants, this picnic is mine.",
				cheeky = "the ants have taken the mystery one, good luck to them",
				cool = "Ants.|Move the basket.",
				prickly = "Ugh, ants, of course.|Shoo, all of you.",
				dramatic = "ANTS! Run, save the sandwiches!",
				bookish = "Actually, ants can carry fifty times their own weight, so they'll take the lot.",
				polite = "Oh dear, we seem to have guests.",
				foodie = "No, no, not the sandwiches!|Take the crusts, take anything else.",
				_ = "Quick, move the rug before they get the rest!",
			}, "sweat")
			s:rel(5)
		else
			burst(s, "b", {
				sunny = "Yes, yes, give me the mystery one!",
				gentle = "Oh, go on, then, I'll try it.",
				bold = "Hah, hand it over.",
				dreamy = "Hmm... all right, I'll be brave.",
				easygoing = "Sure, I'll eat anything right now.",
				proud = "I'll try it, but I expect great things.",
				shy = "Um, okay... I'll try a little bit.",
				cheeky = "if it's pickle and jam again, i'm leaving",
				cool = "Sure, pass it here.",
				prickly = "Fine, but if it's fish and jam, I'm going home.",
				dramatic = "Hand it over, I'm BRAVE.",
				bookish = "I'll try it, for science.",
				gloomy = "Heh... it'll be something awful, but go on.",
				polite = "I'd be glad to, thank you.",
				foodie = "Mystery sandwiches are the best kind, so hand it over.",
				nervous = "W-what's in it? ...Okay, I'll try it.",
				_ = "Go on, then, hand it over.",
			}, "heart")
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
			cool = "...Okay, you asked for this.",
			prickly = "Really?|Fine, you asked for it.",
			dramatic = "You've started something you can't finish!",
			cheeky = "oh, you're getting it now",
			sunny = "Hey! Ehehe, okay, now it's war!",
			dreamy = "Oh... snow down my neck.|Okay, my turn.",
			easygoing = "Eh, I'll get you back... after I lie down in the snow for a bit.",
			bookish = "Right, I've worked out the best angle, so watch out.",
			gloomy = "Heh... of course it hit me.|Okay, you asked for it.",
			polite = "Oh! Well, I am afraid I must throw one back.",
			foodie = "Hey, I was eating a muffin!|Now you're getting it.",
			nervous = "Ah! C-cold, cold!|Okay, okay, I'm throwing one back.",
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
			sunny = "Look at it, look at it!|It's the best castle ever!",
			gentle = "Oh, it's lovely.|Careful, nobody step on the moat, okay?",
			bold = "Best castle on the beach, right?",
			easygoing = "That's a lot of work for one afternoon.|Worth it, though.",
			shy = "Um... it came out really nice.",
			cheeky = "nobody touch it, except me, hehe",
			cool = "Good castle.",
			prickly = "Nobody touch it.|I mean it.",
			dramatic = "Look at it, a CASTLE fit for a king!",
			gloomy = "It's actually good.|Heh... the tide will get it, though.",
			polite = "It came out rather well, I think.",
			foodie = "It looks like a giant sand cake.",
			nervous = "It's so nice... what if a dog runs over it?",
			_ = "Nobody step on it, please.",
		}, "sparkle", "point")
		say(s, "b", "I did the flag, and the flag's the most important bit.", "music")
		s:choice("Leave it for the tide.", function(c)
			burst(c, "a", {
				dreamy = "Hmm... the sea can have it, and maybe it'll make something new out of the sand.",
				proud = "The tide won't knock down anything better all year.",
				gloomy = "The tide will take it, but it was good while it lasted.",
				sunny = "Bye, castle! Ehehe, we'll build a bigger one tomorrow.",
				gentle = "Let's leave it, the sea can enjoy it too.",
				bold = "Leave it, we'll build a better one next time.",
				easygoing = "Sure, less carrying for us.",
				shy = "Okay... bye, little castle.",
				cheeky = "bye castle, the crab can keep it",
				cool = "Leave it.|We'll build another.",
				prickly = "Fine, the sea can have it.|...It was good, though.",
				dramatic = "Goodbye, castle! I'll never forget you!",
				bookish = "High tide is at nine, so it has about four hours left.",
				polite = "Let us leave it for the sea, then.",
				foodie = "Let's leave it and go and get chips.",
				nervous = "Just leave it? Oh, okay... I'll miss it.",
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
			sunny = "{player}, I did something bad.|I broke {b}'s favourite mug, and I feel awful!",
			gentle = "{player}, oh my, I've broken {b}'s favourite mug.|What should I do?",
			bold = "{player}, I broke {b}'s favourite mug.|I should just tell them, right?",
			dreamy = "{player}... I broke {b}'s mug.|It slipped right out of my hands while I was looking at the sky.",
			easygoing = "{player}, so, uh, I broke {b}'s favourite mug.|What do I do?",
			proud = "{player}, there's been a small accident with {b}'s mug.|It wasn't my fault, mostly.",
			shy = "Um, {player}... I broke {b}'s mug.|I don't know what to do.",
			cool = "{player}, I broke {b}'s mug.|What should I do?",
			prickly = "{player}, don't say anything, but I broke {b}'s mug.|What do I do?",
			bookish = "{player}, I broke {b}'s favourite mug, into exactly three pieces.|What should I do?",
			polite = "{player}, I am afraid I have broken {b}'s favourite mug.|What should I do?",
			foodie = "{player}, I broke {b}'s favourite mug, the one with the cupcake on it.|What do I do?",
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
				sunny = "Oh no, my mug!|...It's okay, really, we can paint a new one together!",
				dreamy = "Oh... my mug.|It had a little moon on it.",
				shy = "Oh... it's okay.|Thank you for telling me.",
				cheeky = "my mug? noooo|ok fine, you're buying me a new one, a bigger one",
				bookish = "Oh, my mug.|Actually, it was eleven years old, so it had a good life.",
				gloomy = "My mug... heh, of course.|It's fine, thanks for telling me.",
				foodie = "My cocoa mug? Oh no.|Well, you're buying the cocoa next time.",
				nervous = "M-my mug? Oh no, are you okay? Did you cut yourself?",
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
			cool = "Hm, same sweater.",
			dramatic = "This square isn't big enough for two of this sweater.",
			gentle = "Oh, my, we match!",
			sunny = "We match, we match!",
			polite = "Oh dear, how embarrassing.",
			bold = "Hah, nice sweater.|Mine's better, though, right?",
			dreamy = "Oh... we're wearing the same thing.|Like two clouds.",
			easygoing = "Heh, look at that.|Saves me deciding what to wear tomorrow.",
			prickly = "Ugh, you're wearing my sweater.",
			bookish = "What are the chances? Actually, it's the only sweater the shop sells.",
			gloomy = "Heh... of course this happens to me.",
			foodie = "We match!|Let's get matching ice creams too.",
			nervous = "Oh no, we match.|Is everyone looking? They're looking.",
			_ = "Well, one of us has good taste.",
		}, "sweat")
		burst(s, "b", {
			proud = "Hmph, mine fits better.",
			easygoing = "Eh, it'll save people telling us apart.|...Wait, no, it won't.",
			prickly = "Go and change, right now.|...Fine, I'll change.",
			gloomy = "Heh... the one day I dress up, and this happens.",
			sunny = "We're twins! Ehehe, let's walk around together.",
			gentle = "Oh, it looks lovely on you too.",
			bold = "Ha, we look great, so who cares.",
			dreamy = "Hmm... maybe we're the same person.",
			shy = "Um... I don't mind matching.",
			cheeky = "matching sweaters, best friends, i'm keeping this",
			cool = "It's fine.|Yours suits you.",
			dramatic = "The TOWN will talk!",
			bookish = "We should make a note of who wore it first, for the record.",
			polite = "Oh, it suits you very well.",
			foodie = "Well, now we have to go for lunch together.",
			nervous = "Should one of us go and change? Should it be me?",
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
		s:n("{a} and {b} are lying on a blanket, passing a telescope back and forth.")
		burst(s, "b", {
			bookish = "That one's the bear.|Actually, the three stars in a row are meant to be its belt.",
			dreamy = "That one's a bear...|He's wearing a belt.",
			sunny = "Look, look, that one's a bear!|And those three stars are its belt!",
			gentle = "Oh, look, that one's a bear.|Those three little stars are its belt.",
			bold = "That one's a bear, and those three are its belt, right?",
			easygoing = "That one's a bear, I think.|With a belt, those three stars there.",
			proud = "That one's the bear, naturally, and those three stars are its belt.",
			shy = "Um... I think that one's a bear.|Those three are its belt.",
			cheeky = "that one's a bear, and those three are its belt|don't argue",
			cool = "That's the bear.|Those three stars are its belt.",
			prickly = "That one's a bear, obviously.|Those three are its belt.",
			dramatic = "Look, the great BEAR!|And there, his belt of three stars.",
			gloomy = "That one's a bear.|Heh... and those three stars are his belt.",
			polite = "That one is a bear, I believe, and those three stars are its belt.",
			foodie = "That one's a bear, and those three are its belt.|He's probably hungry.",
			nervous = "That one's a bear, I think? And those three stars are its belt.",
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
			cool = "Hm, something's biting.",
			sunny = "Something's biting, something's biting!",
			gentle = "Oh my, something's biting!|Careful now.",
			bold = "Something's biting, and I'm pulling it in.",
			dreamy = "Oh... the line's moving.|Something's down there.",
			easygoing = "Hey, something's biting.|Wake up, we've got one.",
			proud = "Something's biting, naturally, I chose the spot.",
			shy = "Um... I think something's biting?",
			cheeky = "something's biting, and it's mine",
			prickly = "Finally, something's biting.",
			bookish = "Something's biting, and the line's pulling to the left, so it's a big one.",
			gloomy = "Something's biting.|Heh... it'll get away.",
			polite = "Oh, I believe something is biting.",
			foodie = "Something's biting!|Dinner, here we come.",
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
			sunny = "Ehehe, we caught something!|That counts, right?",
			gentle = "Oh, well, it's something.|Let's put it back gently.",
			bold = "Hah, that's not what I was hoping for.",
			dreamy = "Oh... the sea gave us a present.",
			proud = "A fine catch, all things considered.",
			shy = "Um... that's not a fish, is it?",
			cool = "Hm, not what I expected.",
			prickly = "Three hours for that?|Ugh.",
			dramatic = "Three hours, for THIS?",
			bookish = "Well, that's interesting, actually.|I'll write it down anyway.",
			polite = "Well, it is better than nothing, I suppose.",
			nervous = "Is it going to bite?|...Oh, okay, it's fine.",
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
		burst(s, "b", {
			cheeky = "wait, is that meant to be me",
			sunny = "Wait, is that me? Ehehe, is it?",
			gentle = "Oh my, is that meant to be me?",
			bold = "Is that meant to be me? Hah.",
			dreamy = "Hmm... is that me?",
			easygoing = "Is that meant to be me? Heh.",
			proud = "Is that supposed to be me? I hope not.",
			shy = "Um... is that me?",
			cool = "Is that me?",
			prickly = "Ugh, is that supposed to be me?",
			dramatic = "Is that meant to be ME?",
			bookish = "Is that meant to be me? I don't say 'simply'.",
			gloomy = "Is that me?|Heh... probably.",
			polite = "Excuse me, is that meant to be me?",
			foodie = "Is that meant to be me?|...That's fair, I am always asking about lunch.",
			nervous = "I-is that meant to be me? Do I really sound like that?",
			_ = "Is that meant to be me?",
		}, "question")
		local good = K.isPers(ctx, b, "cheeky", "sunny", "easygoing") or ctx.rng:chance(0.3)
		if good then
			burst(s, "b", {
				cheeky = "...ok, that's actually quite good|do another one",
				sunny = "Ehehe, that's so good!|Do another one!",
				gentle = "Oh my, that's very good.|Do another one?",
				bold = "Hah, that's perfect!|Do another.",
				dreamy = "Hmm... that's very close.|Do another one.",
				easygoing = "Heh, that's pretty good.|Do another one.",
				proud = "Not bad, though I'd have done it better.",
				shy = "Hehe... that's really good.",
				cool = "That's good.|Do another.",
				prickly = "Ugh, that's actually good.|Don't tell anyone I said so.",
				dramatic = "BRAVO!|Do another, do another!",
				bookish = "That's very accurate, actually.|Do another one.",
				gloomy = "Heh... that's really good, actually.",
				polite = "Oh, that is very good.|Could you do another?",
				foodie = "Ha, that's good!|Do one of the baker next.",
				nervous = "Is that really how I sound?|It's good, though!",
				_ = "...It's quite good, actually.|Do another one!",
			}, "laugh", "laugh")
			s:rel(6)
		else
			burst(s, "b", {
				prickly = "I do not sound like that, so stop it.",
				dramatic = "I sound NOTHING like that.|My voice is much lower.",
				sunny = "I don't sound like that!|...Do I? Ehehe.",
				gentle = "Oh, I don't sound like that, do I?",
				bold = "I don't sound like that, right?",
				dreamy = "Hmm... I don't think I sound like that.",
				easygoing = "Eh, I don't sound like that.|Do I?",
				proud = "I sound far more elegant than that.",
				shy = "Um... I don't sound like that... do I?",
				cheeky = "i do not sound like that, hehe",
				cool = "I don't sound like that.",
				bookish = "I don't say 'simply', for the record.",
				gloomy = "Heh... I suppose I do sound like that.",
				polite = "I am quite sure I do not sound like that.",
				foodie = "I don't sound like that!|...I do ask about lunch a lot, though.",
				nervous = "I don't sound like that, do I? Oh no, do I?",
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
			burst(s, "b", {
				sunny = "Ooh, I love it!",
				gentle = "Oh, my, it looks lovely.",
				bold = "Hah, not bad at all.",
				dreamy = "Hmm... I feel lighter.",
				easygoing = "Huh, nice, and I didn't even have to get up.",
				proud = "Hmph, I look even better than before.",
				shy = "Oh... it looks nice.",
				cheeky = "ok, i look great",
				cool = "Hm, good cut.",
				prickly = "Fine, it's good.|Don't let it go to your head.",
				dramatic = "I look like a STAR.",
				bookish = "It's very even, actually.",
				gloomy = "Huh, it's actually good.",
				polite = "How lovely, thank you.",
				foodie = "It's good, and I didn't even have to pay.",
				nervous = "I-it's good? Oh, it's really good!",
				_ = "Oh, that actually looks good.",
			}, "sparkle")
			burst(s, "a", {
				proud = "Hmph, I'm clearly a natural.",
				cheeky = "i'm a natural|so who's next?",
				shy = "Um... it actually came out nice, didn't it?",
				nervous = "It worked?|Oh, thank goodness, I was so scared I'd cut an ear.",
				prickly = "See, I told you I could do it.",
				gloomy = "Huh, it went right for once.",
				sunny = "Ehehe, I did it!|Who's next, who's next?",
				gentle = "Oh, I'm so glad you like it.",
				bold = "Hah, I told you I could do it.",
				dreamy = "Hmm... I just followed the shape of your head.",
				easygoing = "Huh, that went better than I thought.|I'll take a nap to celebrate.",
				cool = "Good.|Who's next?",
				dramatic = "I'm an ARTIST!",
				bookish = "I read a whole book on it, actually, so I'm glad it worked.",
				polite = "I am so pleased you like it.",
				foodie = "Great, now you owe me a bun.",
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
			sunny = "A whole day? Ehehe, easy!",
			gentle = "Oh, all right, I'll try my best.",
			bold = "Hah, easy, you're on.",
			dreamy = "A whole day... hmm, okay.",
			easygoing = "Eh, I'll just sleep through lunch.",
			proud = "A whole day? Naturally, I'll win.",
			shy = "Um... okay, I'll try.",
			cheeky = "easy, and you're buying me a cake after",
			prickly = "Fine, and you'll owe me.",
			dramatic = "A whole DAY? ...Fine, I accept your challenge!",
			bookish = "A whole day? People can easily go much longer, actually.",
			gloomy = "A whole day.|Heh... I'll lose.",
			polite = "Very well, I accept.",
			_ = "That's easy, just watch me.",
		}, "sparkle")
		s:n("By eleven, {b} was standing very close to the bakery window.")
		if ctx.rng:chance(0.5) then
			say(s, "b", "I'm only looking, and looking is allowed.", "sweat")
			s:n("{b} made it to dinner, but only just.")
			burst(s, "b", {
				sunny = "I did it! Ehehe, pay up!",
				gentle = "Oh, my, I actually did it.",
				bold = "Hah, told you, so pay up.",
				dreamy = "Hmm... I forgot I was even hungry.",
				easygoing = "Eh, I napped through most of it.",
				proud = "Naturally, I have excellent willpower.",
				shy = "Um... I did it, I think.",
				cheeky = "pay up, hehe",
				cool = "Told you, so pay up.",
				prickly = "Obviously, so now pay up.",
				dramatic = "I have SURVIVED the longest day of my life.",
				bookish = "I kept busy reading, and it worked.",
				gloomy = "I did it, and now I'm starving, heh.",
				polite = "I managed it, and I'll take my winnings politely.",
				foodie = "I did it, and now I'm eating everything.",
				nervous = "I-I did it! Can I eat now?",
				_ = "I did it, so pay up.",
			}, "sparkle", "cheer")
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
			sunny = "Can you help me carry my wardrobe upstairs? Please, please?",
			gentle = "Could you help me with the wardrobe? We'll go slowly, okay?",
			dreamy = "My wardrobe needs to go upstairs... could you help?",
			easygoing = "Can you help me move the wardrobe upstairs?|We'll take lots of breaks.",
			proud = "I need someone strong to help with my wardrobe.|You'll do.",
			shy = "Um, could you help me carry my wardrobe up the stairs?",
			cheeky = "help me get this wardrobe upstairs, you're the bottom end, hehe",
			cool = "Help me get this wardrobe upstairs.",
			prickly = "Help me with this wardrobe, and don't complain.",
			dramatic = "This wardrobe has BEATEN me.|Help me get it upstairs.",
			bookish = "The wardrobe's two metres tall, and the stairs are narrow.|Can you help?",
			gloomy = "Can you help me get the wardrobe upstairs?|Heh... it'll probably get stuck.",
			foodie = "Help me get the wardrobe upstairs, and I'll make lunch after.",
			nervous = "Could you help with the wardrobe? What if it falls on us?",
			_ = "Can you help me get this wardrobe up the stairs?",
		}, "question")
		say(s, "b", "Sure, we'll lift on three.|One, two...", "point")
		s:n("It took an hour, two scraped knuckles and a lot of 'left, no, your other left'.")
		burst(s, "b", {
			bold = "Done.|I could carry another one, I just won't.",
			easygoing = "I need a lie down, ideally on the wardrobe.",
			gloomy = "My back's gone, but it was on its way out anyway.",
			dramatic = "My ARMS.|I'm never lifting anything again.",
			sunny = "We did it! Ehehe, high five!",
			gentle = "Oh, thank you, let me get you some tea.",
			dreamy = "Hmm... my arms feel like jelly.",
			proud = "Done, and it was mostly me.",
			shy = "Thank you so much... sorry it was so heavy.",
			cheeky = "done|you lifted, i supervised, hehe",
			cool = "Done.|Thanks.",
			prickly = "Ugh, done.|...Thanks for helping.",
			bookish = "Done, and only one scratch on the wall.",
			polite = "Thank you kindly, I could not have done it alone.",
			foodie = "Done!|Lunch is on me, I promised.",
			nervous = "We did it, and nobody got squashed!",
			_ = "Promise me you'll never buy another wardrobe.",
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
			cheeky = "you had your sweater on inside out|i'll never forget it, hehe",
			shy = "Um... I was too nervous to say hello, so you said it first.",
			proud = "You were very impressed by me, I remember that clearly.",
			cool = "You borrowed a pen and never gave it back.",
			prickly = "You stepped on my foot and then said sorry six times.",
			bookish = "It was a rainy Tuesday, and you read my whole letter over my shoulder.",
			nervous = "You said hi and I said thanks.|I-I still think about that.",
			sunny = "You were carrying a huge balloon, and it hit me on the head!",
			gentle = "You looked so lost, so I made you a cup of tea.",
			bold = "You tried to race me to the end of the pier, and you lost.",
			dreamy = "It was raining... and you shared your umbrella.",
			easygoing = "We both fell asleep on the same bench.",
			dramatic = "It was like a scene from a FILM, and you dropped your hat.",
			gloomy = "I tripped over your bag.|Heh... it was a great start.",
			polite = "You held the door for me at the bakery.",
			foodie = "We both reached for the last cinnamon bun.",
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
		local s = K.scene(ctx, "The last cookie")
		s:n("There's one cookie left on the plate between {a} and {b}.")
		burst(s, "a", {
			cheeky = "you have it",
			sunny = "You have it, go on!",
			gentle = "You have it, dear.",
			bold = "Take it, it's yours.",
			dreamy = "You have it...",
			easygoing = "Eh, you have it.",
			proud = "You may have it.",
			shy = "Um... you have it.",
			cool = "Take it.",
			prickly = "Just take it.",
			dramatic = "I insist, it's YOURS!",
			bookish = "You have it, you've only had two.",
			gloomy = "You have it.|Heh... I don't deserve it.",
			polite = "Please, you have it.",
			foodie = "You have it... I mean it... mostly.",
			nervous = "Y-you have it, really.",
			_ = "You have it.",
		}, "question")
		burst(s, "b", {
			cheeky = "no, you have it",
			sunny = "No, no, you have it!",
			gentle = "No, dear, you have it.",
			bold = "No, you have it.",
			dreamy = "No... you have it.",
			easygoing = "Nah, you have it.",
			proud = "No, I couldn't possibly, you have it.",
			shy = "N-no, you have it.",
			cool = "No, you.",
			prickly = "No, you take it.",
			dramatic = "NO, you have it!",
			bookish = "No, you've only had one, actually, so you have it.",
			gloomy = "No, you have it.",
			polite = "No, please, I insist you have it.",
			foodie = "No, you have it... are you sure, though?",
			nervous = "No, you have it, please, really.",
			_ = "No, you have it.",
		}, "question")
		s:n("Neither of them moves, and the cookie just sits there.")
		s:choice("Split it.", function(c)
			c:n("It broke into one big half and one small half, and they both looked at the big half.")
			burst(c, "a", {
				cheeky = "...you have the big half",
				sunny = "...You have the big half!",
				gentle = "...You have the big half, dear.",
				bold = "...You have the big half.",
				dreamy = "...You have the big half...",
				easygoing = "...You have the big half, I'm not that hungry.",
				proud = "...You may have the big half.",
				shy = "...You have the big half, um.",
				cool = "...The big half's yours.",
				prickly = "...Just take the big half.",
				dramatic = "...The BIG half is yours.",
				bookish = "...You have the big half, it's about sixty percent.",
				gloomy = "...You have the big half.",
				polite = "...Please take the big half.",
				foodie = "...You have the big half, probably.",
				nervous = "...You have the big half, is that okay?",
				_ = "...You have the big half.",
			}, "heart")
			c:rel(5)
		end)
		s:choice("Eat it yourself.", function(c)
			c:n("You ate the cookie while both of them watched you do it.")
			burst(c, "a", {
				cheeky = "wow, {player}|you actually ate it",
				polite = "Well, that's one way to settle it.",
				sunny = "{player}! Ehehe, you ate it!",
				gentle = "Oh my, {player}, I hope it was nice.",
				bold = "Hah, {player}, that took guts.",
				dreamy = "Oh... it's gone.|Was it good, {player}?",
				easygoing = "Heh, that solves that, {player}.",
				proud = "Well, {player}, I was about to offer it to you anyway.",
				shy = "Oh... um, okay.",
				cool = "Fair enough, {player}.",
				prickly = "Ugh, {player}, really?",
				dramatic = "{player}, you MONSTER.",
				bookish = "That's one way to settle it, {player}, actually.",
				gloomy = "Heh... of course, {player}.",
				foodie = "{player}, how could you?|...Was it good?",
				nervous = "Oh! Oh, okay, that's fine, {player}.",
				_ = "That was a bold move, {player}.",
			}, "anger")
			say(c, "b", "We're going to remember this, you know.", "anger")
			c:rel(4)
		end)
		s:log("{a} and {b} argued politely over the last cookie.")
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
			cheeky = "{b}, can i borrow some coins until payday?|i'll throw in a bun",
			nervous = "{b}, s-sorry to ask, but could I borrow some coins until payday?|I'll pay you back with a bun, or two buns.",
			sunny = "{b}, could I borrow a few coins until payday?|I'll pay you back with a bun, promise!",
			gentle = "{b}, I'm sorry to ask, but could I borrow a few coins?|I'll pay you back on payday, with a bun.",
			bold = "{b}, lend me a few coins until payday, right?|You'll get a bun on top.",
			dreamy = "{b}... could I borrow a few coins?|I'll pay you back, with a bun, I think.",
			easygoing = "{b}, could you lend me a few coins until payday?|I'll throw in a bun, eventually.",
			proud = "{b}, I've run a little low on coins until payday.|I'll pay you back with a bun, naturally.",
			shy = "Um, {b}... could I borrow a few coins? Only until payday.|I'll bring you a bun too.",
			cool = "{b}, can I borrow a few coins until payday?|I'll pay you back.",
			prickly = "Don't make a thing of it, but can I borrow some coins until payday?|You'll get a bun.",
			dramatic = "{b}, I'm completely BROKE until payday.|Could you lend me a few coins? There'll be a bun in it.",
			bookish = "{b}, could I borrow twelve coins until payday?|I'll pay you back on Friday, with a bun.",
			gloomy = "{b}, could I borrow a few coins until payday?|Heh... I'll pay you back, I promise.",
			foodie = "{b}, can I borrow some coins until payday?|I'll pay you back with the best bun at the bakery.",
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
				dreamy = "Of course... here.",
				proud = "Here, and you may pay me back whenever you like.",
				cheeky = "here, but the bun better be a big one",
				cool = "Here.|No rush.",
				prickly = "Fine, here.|Don't make it a habit.",
				dramatic = "Take it, take it ALL!|...Well, just these few.",
				bookish = "Here you go, and I'll make a note of it so neither of us forgets.",
				gloomy = "Here.|Heh... I know how it feels.",
				nervous = "O-of course, here, take as many as you need.",
				_ = "Sure, but the bun comes first.",
			}, "heart")
			s:rel(6)
		else
			burst(s, "b", {
				proud = "I'll need that in writing.",
				cheeky = "depends how big the bun is",
				prickly = "How many?|...Fine, here, and don't tell anyone I'm soft.",
				gloomy = "I never get these back.|...Here.",
				sunny = "How many? Ehehe, okay, as long as I get my bun.",
				gentle = "Oh... how many do you need, dear?",
				bold = "How many, and when do I get them back?",
				dreamy = "Hmm... how many?",
				easygoing = "Eh, how many? I don't have a lot.",
				shy = "Um... how many do you need?",
				cool = "How many?",
				dramatic = "Coins? From ME? How many?",
				bookish = "How many exactly, and when will you pay me back?",
				polite = "How many would you need?",
				foodie = "Depends, which bun?",
				nervous = "H-how many? I don't have many, sorry.",
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
	cool = "I overslept, sorry.",
	prickly = "I know, so don't say it.|The bus was late.",
	dramatic = "You won't BELIEVE my morning.|There was a goose and a puddle, and I'd rather not talk about it.",
	bookish = "I sat outside my door to finish a chapter, and then I started the next one.",
	gloomy = "I lost a shoe, found it, and then lost the other one.",
	polite = "I'm so sorry, I have no excuse.|Please, let me buy you a tea.",
	foodie = "There was a line at the bakery, and I can't just walk past a line.",
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
			sunny = "There you are!|I was about to send out a search party, ehehe.",
			bold = "Finally.|Half an hour, you know.",
			dreamy = "Oh... there you are.|I was watching the fountain, so I didn't mind.",
			easygoing = "Hey, there you are.|I nearly fell asleep.",
			proud = "You're late, and I don't wait for just anyone.",
			shy = "Oh... you're here.|I was starting to think I had the wrong day.",
			cheeky = "you're late|i've been counting the pigeons, there are nine",
			dramatic = "You're ALIVE!|I was about to tell the whole town.",
			bookish = "You're thirty-two minutes late, actually.",
			gloomy = "Oh, you came.|Heh... I thought you'd forgotten.",
			polite = "Ah, there you are.|I was beginning to worry.",
			foodie = "Finally, I'm starving.|Where have you been?",
			_ = "Where have you been?",
		}, "anger")
		say(s, "a", EXCUSES[K.pers(ctx, a)] or "Sorry, it's a long story.", "sweat")
		burst(s, "b", {
			gentle = "Well, you're here now.",
			proud = "Hmph, that's unacceptable, so you're buying me a bun.",
			easygoing = "Eh, I sat down and had a nice rest, so it's fine.",
			gloomy = "It's fine, I'm used to waiting.",
			sunny = "You're here now, so it's fine!|You're buying, though.",
			dramatic = "Half an HOUR!|...Fine, you're forgiven, but you're buying.",
			bold = "Fine, but next time I'm leaving after ten minutes.",
			dreamy = "Hmm... that's a good story, actually.",
			shy = "Oh... that's okay, really.",
			cheeky = "that's the worst excuse ever|you're buying",
			cool = "Okay.|Let's go.",
			prickly = "Ugh, fine.|You're buying, and that's final.",
			bookish = "That's the third time this month, but fine.",
			polite = "Please do not worry, you are here now.",
			foodie = "Fine, but you're buying lunch, a big one.",
			nervous = "That's okay! I was just worried something happened.",
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
			foodie = "Is it pancakes?",
			cool = "Just let me in.",
			sunny = "Is it 'sunshine'? Is it 'sunshine'?",
			gentle = "Is it 'please'?",
			bold = "I'm coming in, password or not.",
			easygoing = "Is it 'nap time'? Please say it's 'nap time'.",
			shy = "Um... is it 'hello'?",
			prickly = "Ugh, I don't know, 'cushion'?",
			dramatic = "Is it 'open SESAME'?",
			bookish = "It's 'cushion', because you always pick the thing in front of you.",
			gloomy = "I'll never guess it.|Heh... is it 'no'?",
			polite = "May I come in, please?",
			nervous = "I-I don't know it! Is there a hint?",
			_ = "Is it cookies?",
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
		burst(s, "b", {
			sunny = "Eek! Okay, okay, I jumped!",
			gentle = "Oh, my, my heart's racing.",
			bold = "Hah, I didn't jump.|...Okay, I jumped a bit.",
			dreamy = "Hmm... I'm sleeping with the light on tonight.",
			easygoing = "Nope, I'm not walking home on my own after that.",
			proud = "I wasn't scared, I was just surprised.",
			shy = "Eep...!|Can I sit closer to you?",
			cheeky = "ok, that got me, i'll admit it",
			cool = "...That was a good one.",
			prickly = "I'm not scared.|...Stay close, but not that close.",
			dramatic = "*gasp* I nearly fainted!",
			bookish = "I know it's made up, but I'm still checking under my bed tonight.",
			gloomy = "Heh... that sounds like my luck.",
			polite = "Oh, goodness, that gave me quite a fright.",
			foodie = "I'm so scared I need a cookie.",
			nervous = "Oh no, oh no, I'm never going out at night again.",
			_ = "Eek, that was too scary!",
		}, "sweat")
		burst(s, "a", {
			gentle = "Oh, I'm sorry, it's only a story.|Here, you can hold my hand.",
			cheeky = "hehehe, got you",
			dramatic = "And that story is completely true.|Well, mostly.",
			sunny = "Ehehe, got you!|Want to hear another one?",
			bold = "Hah, got you good.",
			dreamy = "Hmm... I think it might be true, actually.",
			easygoing = "Heh, that one always works.",
			proud = "I'm very good at telling those, aren't I?",
			shy = "Um... sorry, was that too scary?",
			cool = "Good one, right?",
			prickly = "It's just a story.|...Mostly.",
			bookish = "It's based on an old story, actually, from about a hundred years ago.",
			gloomy = "Heh... I've got scarier ones.",
			polite = "I do apologise, I hope that was not too frightening.",
			foodie = "That calls for hot chocolate, I think.",
			nervous = "Sorry, was that too much? I scared myself a bit.",
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
		burst(s, "a", {
			sunny = "Eek! That was so loud!",
			gentle = "Oh, my, that made me jump.",
			bold = "Hah, that was close.|...I didn't jump, for the record.",
			dreamy = "Hmm... that one shook the windows.",
			easygoing = "Whoa, that woke me right up.",
			proud = "I wasn't startled, I was just stretching.",
			shy = "Eep...!",
			cheeky = "ok, that was loud, not gonna lie",
			cool = "...That was close.",
			prickly = "Ugh, I hate thunder.",
			dramatic = "*gasp* Did you hear that?",
			bookish = "That was close, barely a second after the flash.",
			gloomy = "Of course there's a storm, heh.",
			polite = "Oh, goodness, pardon me.",
			foodie = "That made me drop my cookie.",
			nervous = "Oh no, oh no, that was so loud.",
			_ = "Whoa, that was loud!",
		}, "sweat")
		burst(s, "b", {
			bold = "Hah, it's just noise.|Stand next to me and I'll shout back at it.",
			gentle = "Come here, all right?|We'll count between the flashes together.",
			cheeky = "it's just the sky moving its furniture around",
			shy = "Um... I'm scared of it too.|Can we be scared together?",
			sunny = "It's okay, I've got you!|It's only noise, and it can't get in.",
			dreamy = "Count with me...|One, two, three... see, it's moving away.",
			proud = "Thunder doesn't bother me.|You can stand next to me if you like.",
			easygoing = "Eh, it's just loud.|Come and sit with me until it's done.",
			cool = "It's far off, so you're fine.",
			prickly = "It's thunder, it can't hurt you.|...Sit here, then.",
			dramatic = "The sky is having a TANTRUM.|Let it, and we'll stay inside.",
			bookish = "Count after the flash.|Every three seconds is about a kilometre, so it's far away.",
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
			sunny = "Here, get under!|Ehehe, there's room for two.",
			gentle = "Come here, dear, you'll catch a cold.",
			dreamy = "Here... there's room under here for two.",
			easygoing = "Here, hop under, no rush.",
			proud = "You may share my umbrella, it's a very good one.",
			shy = "Um... would you like to share?",
			cheeky = "get under, but you're holding it",
			dramatic = "Quick, under here before you WASH away!",
			bookish = "Get under, it's big enough for two, I measured.",
			gloomy = "Here, get under.|Heh... I know what it's like to forget.",
			polite = "Please, do share my umbrella.",
			foodie = "Get under, and mind my shopping.",
			nervous = "Here, quick, get under! Is there enough room?",
			_ = "There's room for two under here, just about.",
		}, "heart")
		burst(s, "b", {
			shy = "Oh... th-thank you.|I'll try to stand very small.",
			proud = "I was enjoying the rain, but fine.",
			polite = "That's very kind of you, thank you.",
			gloomy = "I always forget mine.|Thanks.",
			cheeky = "you're a lifesaver, thanks",
			sunny = "Thank you, thank you, I'm already soaked!",
			gentle = "Oh, thank you, that's so kind.",
			bold = "Thanks, I owe you one.",
			dreamy = "Oh... thank you.|The rain sounds nice on top.",
			easygoing = "Thanks, I was going to just get wet.",
			cool = "Thanks.",
			prickly = "Fine.|...Thanks.",
			dramatic = "You've SAVED me from the storm!",
			bookish = "Thank you, I left mine at the library, actually.",
			foodie = "Thanks, my bread was getting soggy.",
			nervous = "Th-thank you! Am I too close? Sorry.",
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
			cool = "Huh, same here.",
			nervous = "W-wait, really?|You're not just saying that?",
			cheeky = "no way|we're basically twins now",
			gentle = "Oh my, you too?|That's lovely.",
			bold = "Wait, you too? Hah!",
			dreamy = "Oh... you too?",
			easygoing = "Huh, you too? Nice.",
			proud = "You too? You have excellent taste, then.",
			shy = "Um... you too?",
			prickly = "Wait, you too?|Huh.",
			dramatic = "You TOO? No way!",
			bookish = "You too? That's quite rare, actually.",
			gloomy = "You too?|Heh... I thought it was only me.",
			polite = "You as well? How wonderful.",
			foodie = "No way, you too?|We need to get lunch and talk about this.",
			_ = "No way, you too?",
		}, "sparkle")
		burst(s, "b", {
			sunny = "Yes, me too! I thought I was the only one!",
			gentle = "Oh, my, me too, isn't that lovely?",
			bold = "Hah, me too, so we're friends now.",
			dreamy = "Hmm... I always thought I was the only one.",
			easygoing = "Huh, me too, nice.",
			proud = "Naturally, it shows you have good taste.",
			shy = "Um... yes, me too.",
			cheeky = "no way, me too, hehe",
			cool = "Same, huh.",
			prickly = "Fine, me too, so don't make it weird.",
			dramatic = "Me TOO! This changes everything.",
			bookish = "Me too, and I've never met anyone else who does.",
			gloomy = "Me too, heh... nobody ever gets it.",
			polite = "Me too, how lovely to find out.",
			foodie = "Me too, so this calls for a snack.",
			nervous = "R-really? Me too!",
			_ = "Me too, I thought I was the only one!",
		}, "sparkle", "cheer")
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
			sunny = "{player}, could you give this to {b}?|I made it really colourful so it'd cheer them up!",
			gentle = "{player}, would you give this to {b} for me?|I want them to know I'm sorry.",
			dreamy = "{player}... could you give this to {b}?|I drew a cat, and I hope it says enough.",
			easygoing = "{player}, can you give this to {b}?|I'd go myself, but I'd just mumble.",
			cheeky = "{player} give this to {b}|and don't laugh at my drawing",
			cool = "{player}, give this to {b}.|Please.",
			dramatic = "{player}, take this to {b}.|It holds my whole HEART.",
			bookish = "{player}, could you give this card to {b}?|I wrote three drafts, so it's the best I can do.",
			gloomy = "{player}, could you give this to {b}?|Heh... they'll probably throw it away.",
			polite = "{player}, would you please give this card to {b}?|I would be very grateful.",
			foodie = "{player}, could you give this to {b}?|I put a cookie in the envelope too.",
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
				sunny = "A cat! Ehehe, that's so sweet!|Tell them I miss them too.",
				gentle = "Oh, that's so sweet.|Tell them I'm not upset any more, okay?",
				dreamy = "Oh... it's a nice cat.|Tell them I miss them too.",
				easygoing = "Heh, a cat.|Tell them it's all fine.",
				cheeky = "a cat? ok, that's cute|tell them they're forgiven, but barely",
				prickly = "Ugh, a cat.|...Tell them it's fine, okay?",
				dramatic = "A CAT! *sob*|Tell them all is forgiven.",
				bookish = "The cat has five whiskers on one side and four on the other.|...Tell them I'm sorry too.",
				polite = "How very thoughtful.|Please tell them I accept, and that I am sorry too.",
				foodie = "A cat!|Tell them we're fine, and to come to lunch.",
				nervous = "They're not angry any more? Oh, phew.|Tell them I'm sorry too.",
				_ = "Tell them I'm sorry too.",
			}, "heart")
			c:fx({ t = "makeup", a = "a", b = "b" })
			c:rel(10)
			c:mood("a", 5)
		end)
		s:choice("Say it in person.", function(c)
			burst(c, "a", {
				shy = "You're right, I'll go.|I'll go red, but I'll go.",
				proud = "Fine, in person, and I'll be very calm about it.",
				nervous = "I-in person?|Okay, okay, but will you walk me to the door?",
				sunny = "In person? Okay, okay, I'll go now!",
				gentle = "You're right, it's better in person.",
				bold = "Fine, I'll say it to their face.",
				dreamy = "In person... okay, I'll try.",
				easygoing = "Yeah, okay, I'll walk over.",
				cheeky = "in person? ugh, fine",
				cool = "Okay.|I'll go.",
				prickly = "Ugh, fine, I'll go myself.",
				dramatic = "In PERSON? ...You're right, I'll be brave.",
				bookish = "You're right, it means more in person, actually.",
				gloomy = "In person... okay.|Heh... wish me luck.",
				polite = "You are quite right.|I will go and apologise properly.",
				foodie = "Okay, I'll go, and I'll take them a bun.",
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
			dramatic = "That was a secret, a SPECIAL one.",
			prickly = "That was a secret, seriously.",
			sunny = "That was a secret!|Why did you tell everyone?",
			gentle = "That was a secret, and I trusted you.",
			bold = "That was a secret, and you know it.",
			dreamy = "That was a secret... I only told you.",
			easygoing = "Hey, that was a secret, you know.",
			proud = "That was private, and you know it.",
			shy = "That was... a secret.",
			cheeky = "that was a secret, not cool",
			bookish = "I told you that as a secret, actually.",
			gloomy = "That was a secret.|Heh... I should've known.",
			polite = "That was meant to stay between us.",
			foodie = "That was a secret, and I told you over cake.",
			nervous = "That was a secret! Oh no, who else knows?",
			_ = "That was supposed to be a secret.",
		}, "anger", "point")
		burst(s, "a", {
			cheeky = "it slipped out|a few times",
			sunny = "I got excited, and I'm so sorry!",
			nervous = "I-I didn't mean to, it just came out.|And then it kept coming out.",
			gentle = "Oh no, I didn't think, I'm so sorry.",
			bold = "I didn't think it mattered that much.",
			dreamy = "Oh... it just floated out.",
			easygoing = "Eh, I didn't think it was a big deal.",
			proud = "It was going to come out anyway.",
			shy = "I-I'm sorry... I only told one person, and then...",
			cool = "I didn't think.",
			prickly = "Ugh, it's not that big a deal.",
			dramatic = "I couldn't HOLD it in!",
			bookish = "I only told four people, actually.|...Then they told more.",
			gloomy = "Heh... I ruin everything.",
			polite = "I am so sorry, I did not realise it was a secret.",
			foodie = "It slipped out over lunch, sorry.",
			_ = "I didn't think it was that big a deal.",
		}, "sweat")
		s:choice("Tell {a} to say sorry.", function(c)
			burst(c, "a", {
				sunny = "I'm so sorry, I got excited and it just came out!",
				gentle = "I'm sorry, I should never have told anyone.",
				bold = "Sorry. I messed up, and I know it.",
				dreamy = "I'm sorry... I didn't think before I said it.",
				easygoing = "Sorry, I didn't think it was a big thing, but it was.",
				proud = "I may have been... careless.|I apologise.",
				shy = "I'm really sorry... I won't do it again.",
				cheeky = "ok, i'm sorry, really|my mouth runs faster than my brain",
				cool = "Sorry. I shouldn't have said anything.",
				prickly = "Fine, I'm sorry.|...I mean it.",
				dramatic = "I've betrayed your trust, and I'm SO sorry.",
				bookish = "You're right, I'm sorry, I should have kept it to myself.",
				gloomy = "Sorry, that was my fault, as usual.",
				polite = "I am so sorry, that was wrong of me.",
				foodie = "I'm sorry, I'll make it up to you with cake.",
				nervous = "Oh no, I'm sorry, I'm really sorry.",
				_ = "I'm sorry, I shouldn't have told anyone.",
			}, "sad")
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
			burst(s, "b", {
				sunny = "Ehehe, hey!",
				gentle = "Oh, you.",
				bold = "Hah, watch it.",
				dreamy = "Hmm... maybe you're right.",
				easygoing = "Heh, fair.",
				proud = "Hmph, I'll let that one go.",
				shy = "Oh... hehe.",
				cheeky = "hey, that's my job",
				cool = "Hm, very funny.",
				prickly = "Ugh, you're one to talk.",
				dramatic = "How DARE you.|...Okay, that was a bit funny.",
				bookish = "That's a fair point, actually.",
				gloomy = "Heh... yeah, that's me.",
				polite = "Oh, you are cheeky.",
				foodie = "Ha, I'll get you back later.",
				nervous = "W-wait, really? Is it that bad?",
				_ = "Ha, hey!",
			}, "music", "laugh")
			burst(s, "b", {
				prickly = "You're lucky I put up with you.",
				cool = "Hm. Lucky for you I like you.",
				sunny = "Ehehe, you know I'm only joking!",
				gentle = "Oh, I'm only teasing, you know that.",
				bold = "Hah, you know I mean it nicely.",
				dreamy = "Hmm... I only tease the people I like.",
				easygoing = "Heh, I'm just messing with you.",
				proud = "You should be honoured I tease you at all.",
				shy = "Um... I was only joking.",
				cheeky = "you love it, admit it",
				dramatic = "I only tease my FAVOURITE people.",
				bookish = "Actually, people only tease the friends they're close to.",
				gloomy = "Heh... somebody has to keep you from getting a big head.",
				polite = "I hope you know I am only joking.",
				foodie = "Don't worry, I'll buy you a bun to say sorry.",
				nervous = "I-I was only joking! You know that, right?",
				_ = "You're lucky I like you.",
			}, "heart")
			s:rel(4)
		else
			burst(s, "b", {
				sunny = "Hey, that wasn't very nice.",
				gentle = "That wasn't kind, and I think you know it.",
				bold = "You think that's funny? It isn't.",
				dreamy = "Hmm... that wasn't very nice.",
				easygoing = "Eh, not cool.",
				proud = "Hmph, how rude.",
				shy = "Oh... okay.",
				cheeky = "wow, rude",
				cool = "Not funny.",
				prickly = "Ugh, mind your own business.",
				dramatic = "I have NEVER been so insulted.",
				bookish = "That's a bit unkind, actually.",
				gloomy = "Heh... thanks for pointing it out.",
				polite = "I'd rather you didn't say things like that.",
				foodie = "Rude, and I haven't even had lunch.",
				nervous = "Oh no, is it really that bad?",
				_ = "Hey, that's not very nice.",
			}, "anger")
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
			sunny = "Ehehe, they're so funny when they're asleep!",
			bold = "Hah, I'm teasing them about this tomorrow.",
			dreamy = "Hmm... I wonder where they are in their dream.",
			easygoing = "Heh, even their sleep is busier than mine.",
			proud = "I never talk in my sleep, naturally.",
			shy = "Oh... I shouldn't be listening.",
			cool = "Hm.|Interesting.",
			prickly = "Ugh, I didn't need to hear that.",
			dramatic = "What a STORY, even asleep!",
			gloomy = "Heh... their dreams sound better than mine.",
			polite = "I really should not be listening.",
			foodie = "Did they say pudding? Now I want pudding.",
			nervous = "Should I wake them? No, no, I'll leave them.",
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
			sunny = "We had the same dream? Ehehe, that's amazing!",
			gentle = "Oh my, the same dream?|How strange, and how lovely.",
			easygoing = "Huh, same dream.|Maybe we're just that close.",
			proud = "Clearly my dream was so good you had to share it.",
			shy = "Um... that's a bit strange, isn't it?",
			cheeky = "ok, that's spooky, i'm getting goosebumps",
			cool = "Hm.|That's strange.",
			prickly = "That's weird.|Stop being in my dreams.",
			polite = "How very strange, I have never heard of such a thing.",
			foodie = "Was there cheese involved? There's always cheese involved.",
			nervous = "Oh no, what does it mean? Is it a sign?",
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
			sunny = "Two against one? Ehehe, okay, let's go!",
			gentle = "Two against one? Oh, be gentle with me.",
			dreamy = "Two against one... hmm, okay.",
			easygoing = "Two against one? Eh, sure, why not.",
			cheeky = "two against one? you're going down",
			prickly = "Two against one? Ugh, fine.",
			bookish = "Two against one is about twice the pull, actually.|...I'll try anyway.",
			polite = "Two against one? Very well, I accept.",
			foodie = "Two against one? Good thing I had a big lunch.",
			nervous = "T-two against one? Oh no.",
			_ = "Two against one?|Fine, I've been eating my greens.",
		}, "sparkle")
		if K.trait(ctx, c, "brave") > 0.65 then
			s:n("{c} dug in their heels and pulled them both over the line.")
			burst(s, "c", WINS, "sparkle", "cheer")
		else
			s:n("{c} lasted four seconds and then went face first into the grass.")
			burst(s, "c", {
				proud = "I let you win, and that was very kind of me.",
				shy = "Ow...|Okay, you win.",
				prickly = "Don't say a single word.",
				sunny = "Ow, ehehe!|Okay, you win, rematch!",
				gentle = "Oh my, I'm all grassy.|Well done, you two.",
				bold = "Two against one doesn't count.|Rematch, one on one.",
				dreamy = "The grass smells nice down here...|You win.",
				easygoing = "I'm comfy down here, actually.|You win.",
				cheeky = "i meant to do that|you win, i guess",
				cool = "Hm, fair enough.|You win.",
				dramatic = "DEFEATED! In the grass!|Remember me kindly.",
				bookish = "Two against one, so that was always going to happen, actually.",
				gloomy = "Face first, as usual.|Heh...",
				polite = "Well played, both of you.",
				foodie = "I've got grass in my mouth, and it's not a good salad.",
				nervous = "Ow... I'm okay, I'm okay!",
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
	{ "The Soggy Cookies", "Gull Patrol", "Three Spoons", "The Night Buses", "Pickle Jar", "Thursday Pudding" }

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
			cheeky = "we need a name|{player}, you pick",
			sunny = "We need a name, a really fun one!|{player}, pick one, please!",
			gentle = "We need a name for our little band.|{player}, would you choose one?",
			bold = "We need a name, and it has to be loud.|{player}, pick one.",
			dreamy = "We need a name... something that sounds like music.|{player}, could you pick?",
			easygoing = "We need a name, but thinking of one sounds hard.|{player}, you pick.",
			proud = "Every great band needs a great name.|{player}, choose one worthy of us.",
			cool = "We need a name.|{player}, pick one.",
			prickly = "We need a name, and no silly ones.|{player}, pick.",
			bookish = "We need a name, and I've got a list of forty.|{player}, could you just pick one?",
			gloomy = "We need a name.|Heh... {player}, you pick, I'll only ruin it.",
			polite = "We are in need of a name.|{player}, would you kindly choose one?",
			foodie = "We need a name, something about food if we can.|{player}, you choose!",
			nervous = "We need a name, and what if it's a bad one?|{player}, could you pick?",
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
			burst(ch, "c", {
				sunny = "All this is for me? Ehehe, I love it!",
				gentle = "Oh, my, all of this for me?",
				bold = "Hah! You got me, you really got me.",
				dreamy = "Hmm... is all this for me?",
				easygoing = "Whoa, for me? Nice.",
				proud = "For me? Well, naturally, but thank you.",
				shy = "Is this... for me? Oh...",
				cheeky = "wait, this is for me? ok, you got me",
				cool = "...You got me, thanks.",
				prickly = "Ugh, you lot.|...Thank you.",
				dramatic = "*gasp* For ME? I could cry!",
				bookish = "I had no idea, actually, and I usually have an idea.",
				gloomy = "For me? Heh... nobody's ever done this before.",
				polite = "How wonderful, thank you all so much.",
				foodie = "Is that cake? For me? You're the best!",
				nervous = "F-for me? Oh, wow, thank you!",
				_ = "All this is for me? Thank you!",
			}, "heart", "cheer")
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
			cool = "Hm, {b} is right.",
			prickly = "Why am I always the one?|...Fine, it's {a}.",
			dramatic = "I've heard both sides, and I need a whole day to think.",
			bookish = "Actually, it depends what you both mean by it, so let's start there.",
			gloomy = "Neither of you, because nobody's ever right.",
			polite = "I really couldn't say, you both make good points.",
			foodie = "Can we talk about this over lunch?",
			nervous = "P-please don't make me pick.",
			sunny = "Ehehe, you're both right, so let's get ice cream!",
			bold = "It's {a}, and that's final.",
			dreamy = "Hmm... I think it's {b}, but I'm not sure why.",
			shy = "Um... do I have to?|...It's {a}, I think.",
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
		s:n("{a} has been pacing up and down the roof terrace for an hour.")
		s:by("a", {
			nervous = "{player}, {b} looked after me all week when I was ill, and I never said thank you. Sh-should I go and say it now?",
			prickly = "{player}, {b} looked after me when I was ill and I never thanked them. Don't look at me like that.",
			shy = "Um, {player}, {b} sat with me all week when I was ill, and I never thanked them. Do you think I should?",
			proud = "{player}, {b} looked after me when I was ill, and I ought to thank them properly. I should, shouldn't I?",
			sunny = "{player}, {b} looked after me all week when I was ill, and I never said thank you! I should go right now, shouldn't I?",
			gentle = "{player}, {b} took such good care of me when I was ill. I never thanked them properly, and I'd like to.",
			bold = "{player}, {b} looked after me all week when I was ill, and I never thanked them. I'm going to, right?",
			dreamy = "{player}, {b} sat with me every day when I was ill... and I never said thank you. Should I?",
			easygoing = "{player}, {b} looked after me all week when I was ill, and I never got round to saying thanks. I should, huh?",
			cheeky = "{player}, {b} looked after me when i was ill and i never said thanks. should i? don't laugh",
			cool = "{player}, {b} looked after me when I was ill. I never thanked them.",
			dramatic = "{player}, {b} NURSED me back to health last week, and I never thanked them. What kind of friend am I?",
			bookish = "{player}, {b} brought me soup six days in a row when I was ill. I never thanked them, actually, so should I?",
			gloomy = "{player}, {b} looked after me when I was ill, and I never said thanks. Heh... it's probably too late now.",
			polite = "{player}, {b} looked after me so kindly when I was unwell, and I have not thanked them. Should I do so now?",
			foodie = "{player}, {b} made me soup every day when I was ill, really good soup. I never thanked them, so should I?",
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
				sunny = "{b}, thank you so much for the soup and for staying with me! You're the best.",
				gentle = "{b}, thank you for looking after me last week. It meant so much, really.",
				dreamy = "{b}, thank you for the soup... and for sitting with me while I slept.",
				easygoing = "{b}, thanks for the soup and for everything last week. I should've said it sooner.",
				cool = "{b}, thanks for last week. The soup helped.",
				bookish = "{b}, thank you for the soup, all six bowls of it. I should have said it days ago.",
				foodie = "{b}, thank you for the soup. It was the best soup I've ever had, and I'm not just saying that.",
				_ = "{b}, I never thanked you for the soup and for sitting with me. It meant a lot.",
			}, "heart")
			ch:by("b", {
				shy = "Oh, you didn't have to say anything, but I'm really glad you did.",
				proud = "It was very good soup, naturally. But thank you, really.",
				cheeky = "i know, i've been waiting weeks for this. come here.",
				cool = "Anytime, I mean that.",
				prickly = "...Took you long enough. Come here.",
				foodie = "It was my best soup, and you deserved it. Thank you for saying so.",
				gentle = "Oh, you, of course I did. You'd have done the same for me.",
				sunny = "Aww, of course! That's what friends are for, ehehe.",
				bold = "Hah, of course. You'd do the same for me, right?",
				dreamy = "Oh... you're welcome. I liked sitting with you.",
				easygoing = "Eh, it was nothing, I just brought soup and napped in your chair.",
				dramatic = "Oh, stop, you'll make me CRY. You're welcome.",
				bookish = "You're welcome. Actually, it was seven bowls, but who's counting?",
				gloomy = "Heh... you're welcome. It was nice to be useful.",
				polite = "You are very welcome. I was glad to help.",
				nervous = "Oh, you're welcome! Are you feeling better now? Really better?",
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
				sunny = "Okay, tomorrow, then! I'll bring them flowers.",
				gentle = "You're right, I'll find a quiet moment tomorrow.",
				bold = "Fine, tomorrow, first thing.",
				dreamy = "Tomorrow... when the light's nicer.",
				easygoing = "Yeah, tomorrow's good, no rush.",
				cheeky = "tomorrow, then, and i'll bring a cake so it's less awkward",
				cool = "Tomorrow, then.",
				prickly = "Fine, tomorrow, and don't remind me.",
				dramatic = "Tomorrow, at the PERFECT moment.",
				bookish = "Tomorrow, then, after I've worked out what to say.",
				gloomy = "Tomorrow, then. Heh... if I'm still brave enough.",
				polite = "Tomorrow, then, when the time is right.",
				foodie = "Tomorrow, and I'll bring some of my own soup back for them.",
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
			gentle = "Same time next month? I'd love that.",
			bold = "Same time next month, right? No excuses.",
			dreamy = "Can we do this again next month...?",
			easygoing = "Same time next month? Nice and easy.",
			proud = "We'll do this again next month, I insist.",
			shy = "Um... could we do this again next month?",
			cool = "Same time next month.",
			prickly = "Same time next month, and you'd better come.",
			bookish = "Same time next month? I'll mark it on my calendar.",
			gloomy = "Same time next month? Heh... if you want to.",
			polite = "Would you like to do this again next month?",
			foodie = "Same time next month? I'll plan the snacks.",
			_ = "Same time next month?",
		}, "heart")
		s:by("a", {
			proud = "It's already on my calendar, in pen.",
			cheeky = "same time tomorrow, more like",
			shy = "I'd like that a lot.",
			cool = "I'll be there.",
			prickly = "Obviously, and don't be late.",
			foodie = "Yes, and next time I'm bringing twice as many snacks.",
			gloomy = "If it doesn't rain... yes.",
			sunny = "Yes, yes, of course!",
			gentle = "Of course, I'd love to.",
			bold = "Hah, try and stop me.",
			dreamy = "Yes... I'd like that.",
			easygoing = "Sure, sounds good to me.",
			dramatic = "It's the BEST day of every month.",
			bookish = "Yes, and I'll look up the weather beforehand.",
			polite = "I would like that very much.",
			nervous = "Yes! I-I mean, yes, I'd love to.",
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
			sunny = "Yes, yes, I love it!|We should do it together!",
			gentle = "Oh, I am, it's how I relax in the evenings.",
			dreamy = "Hmm... yes, it's the thing that makes the evenings feel soft.",
			easygoing = "Yeah, I do it when I'm not napping, so, sometimes.",
			cheeky = "obviously, and i'm better at it than you, hehe",
			prickly = "Yes, and don't tell anyone.",
			dramatic = "It's my PASSION!",
			gloomy = "Yeah.|Heh... I'm not very good, though.",
			polite = "I am, yes, for a few years now.",
			foodie = "I am, and I always do it with a snack.",
			_ = "Since I was little.|Why didn't you ever say?",
		}, "sparkle")
		s:n("They spent the rest of the afternoon comparing notes, and they made plans to do it together.")
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
			sunny = "Ehehe, I just knew!",
			bold = "You always get it, right?",
			dreamy = "Hmm... it just felt like a toasted one day.",
			easygoing = "Lucky guess, and it saved us both standing in line.",
			shy = "Um... I remembered from last time.",
			prickly = "Because you always get it, obviously.",
			dramatic = "I KNOW you, that's how.",
			gloomy = "You always get it.|Heh... I notice things.",
			polite = "I hope you do not mind that I ordered for you.",
			nervous = "I-I hope that's okay, I just guessed.",
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
			sunny = "Ehehe, it's so pretty!|I'm never taking it off.",
			gentle = "Oh, it's lovely.|I'll wear it every day, okay?",
			dreamy = "Oh... it's the colours of the sunset.",
			easygoing = "Nice, it's comfy too.",
			cheeky = "matching ones, hehe, everyone's going to be jealous",
			bookish = "Thank you, and it's a very neat knot, actually.",
			polite = "Thank you so much, I will treasure it.",
			foodie = "I love it, and it's the colour of strawberry jam.",
			nervous = "For me? Oh, I-I love it!",
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
			sunny = "Oh no, one piece is missing!|Help me look, help me look!",
			gentle = "Oh dear, there's one piece missing.|Let's look for it together, okay?",
			bold = "One piece is missing, and we're finding it.",
			dreamy = "Hmm... there's a little hole in the harbour.",
			easygoing = "Huh, one piece is missing.|Eh, we can still see what it is.",
			proud = "One piece is missing, and it's certainly not my fault.",
			shy = "Um... I think there's a piece missing.",
			cheeky = "one piece is missing|and it's not in my pocket, i checked, hehe",
			cool = "One piece is missing.",
			prickly = "Ugh, one piece is missing.",
			polite = "Oh dear, I believe one piece is missing.",
			foodie = "One piece is missing, and if it's under the cake plate, I'm sorry.",
			_ = "One piece is missing, and it's the last one.",
		}, "sweat")
		burst(s, "b", {
			cool = "Check your sleeve.",
			cheeky = "hehe, it wasn't me",
			sunny = "It's here somewhere, I know it!",
			gentle = "Don't worry, we'll find it.",
			bold = "Check under the table.",
			dreamy = "Maybe it went for a little walk...",
			easygoing = "Eh, it'll turn up.",
			proud = "I certainly didn't lose it.",
			shy = "Um... I'll look under the chair.",
			prickly = "Don't look at me.",
			dramatic = "It's GONE! Forever!",
			bookish = "It must be somewhere near the table, actually.",
			gloomy = "It's gone.|Heh... these things always go.",
			polite = "I am sure it is here somewhere.",
			foodie = "Did it fall in the snack bowl?",
			nervous = "Oh no, did I lose it? I'm so sorry!",
			_ = "It has to be around here somewhere.",
		}, "question")
		s:n("It was in {b}'s sock.")
		burst(s, "b", {
			proud = "I was keeping it safe.",
			prickly = "Don't look at me like that.|Socks are basically pockets for feet.",
			nervous = "H-how did it get there?|Is my other sock okay?",
			sunny = "In my sock? Ehehe, how?",
			gentle = "Oh my, it was in my sock.",
			bold = "Hah, in my sock, of all places.",
			dreamy = "Hmm... my sock wanted to keep it.",
			easygoing = "Huh, that's been there all evening, then.",
			shy = "Oh no... it was in my sock, sorry.",
			cheeky = "ok, it was in my sock, but i didn't put it there, probably",
			cool = "It was in my sock.|Huh.",
			dramatic = "My SOCK? How dare it!",
			bookish = "In my sock, which explains why my foot felt funny.",
			gloomy = "My sock... heh, of course.",
			polite = "I am so sorry, it was in my sock.",
			foodie = "In my sock? Well, at least it wasn't in the soup.",
			_ = "How did it get in my sock?",
		}, "sweat")
		burst(s, "a", {
			sunny = "Ehehe, of all the places!",
			gentle = "Oh, my, of all the places.",
			bold = "Hah! Three evenings, and it was in your sock.",
			dreamy = "Hmm... socks are where things go to hide.",
			easygoing = "Heh, well, it's done now.",
			proud = "I'd never have lost a piece in my sock.",
			shy = "Hehe... at least we found it.",
			cheeky = "i'm telling everyone about the sock",
			cool = "Hm. Put it in, then.",
			prickly = "Unbelievable.|...Put it in, then.",
			dramatic = "THREE evenings, and it was in your SOCK!",
			bookish = "I'm adding 'check socks' to my jigsaw rules.",
			gloomy = "Heh... of course it was.",
			polite = "Well, all's well that ends well.",
			foodie = "Finished, so that's earned us a cookie.",
			nervous = "Oh, phew, we found it!",
			_ = "Ha, of all the places!",
		}, "music", "laugh")
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
			cool = "It's a geranium, so keep it warm.",
			sunny = "Here's a geranium, it's so pretty!|Keep it warm, okay?",
			gentle = "Here's a geranium, dear.|Keep it somewhere warm, okay?",
			bold = "Geranium for you.|Don't let it get cold, right?",
			dreamy = "This is a geranium...|It likes the sun, like a cat.",
			easygoing = "Here, a geranium.|It's easy, just keep it warm.",
			proud = "A geranium from my garden, the finest on the street.",
			shy = "Um, this is a geranium for you...|It doesn't like the cold.",
			cheeky = "here's a geranium|don't kill it, hehe",
			prickly = "It's a geranium.|Don't let it die, or I'll know.",
			dramatic = "A GERANIUM for you!|Keep it safe from the cold.",
			gloomy = "Here's a geranium.|Heh... mine always die, but yours might not.",
			polite = "Here is a geranium for you.|Please keep it somewhere warm.",
			foodie = "Here's a geranium.|Sadly you can't eat it.",
			_ = "Here's a geranium, just don't let it get cold.",
		}, "idea")
		burst(s, "b", {
			cheeky = "here's some mint|it'll take over your whole garden, good luck",
			gloomy = "This is mint.|It'll take over everything, as usual.",
			foodie = "Mmm, this is mint, and it's lovely in tea and on peas.",
			polite = "And this is mint, with my thanks.|I'm afraid it does spread.",
			sunny = "And here's some mint!|It smells so nice!",
			gentle = "And here's some mint for you.|It does spread, so keep it in a pot, okay?",
			bold = "Here's mint, and it spreads like crazy.",
			dreamy = "Mint... it smells like a cold morning.",
			easygoing = "Here's some mint, and it grows by itself, which is my kind of plant.",
			proud = "Mint from my garden, the best you'll find.",
			shy = "Um... here's some mint.|It spreads a bit, sorry.",
			cool = "Mint.|It spreads.",
			prickly = "Here's mint, and don't blame me when it's everywhere.",
			dramatic = "MINT! It will take over your whole garden!",
			bookish = "This is mint, and it spreads under the soil, actually, so keep it in a pot.",
			nervous = "Here's some mint, b-but it spreads, so watch it.",
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
			gentle = "soft pink",
			easygoing = "pale green",
			proud = "gold",
			shy = "pale yellow",
			cool = "navy blue",
			prickly = "dark green",
			bookish = "olive green",
			polite = "cream",
			foodie = "peach",
			nervous = "sky blue",
			_ = "pale blue",
		})
		s:with({ colour = own })
		burst(s, "b", {
			dramatic = "Mine's lilac, because it makes a statement.",
			cheeky = "mine's got spots|hehe",
			gloomy = "Mine's grey, so it matches the sky.",
			sunny = "Mine's sunflower yellow, and it's so cheerful!",
			gentle = "Mine's a soft pink, it's nice and calm.",
			bold = "Mine's bright red, and you can see it from the harbour.",
			dreamy = "Mine's sea green... like the water in the morning.",
			easygoing = "Mine's pale green, it looks restful.",
			proud = "Mine's gold, naturally, the best colour there is.",
			shy = "Um... mine's pale yellow.|Is that okay?",
			cool = "Mine's navy blue.",
			prickly = "Mine's dark green, and I like it, so there.",
			bookish = "Mine's olive green, it's a very old colour for fences, actually.",
			polite = "Mine is cream, which I think is rather nice.",
			foodie = "Mine's peach, like a peach tart.",
			nervous = "Mine's sky blue... is that bad?",
			_ = "Mine's {colour}, and it looks nicer.",
		}, "sparkle")
		burst(s, "a", {
			prickly = "It's a fence, it doesn't need a personality.",
			nervous = "B-but it doesn't match.|Doesn't a fence have to match?",
			sunny = "But it doesn't match!|A fence should match, shouldn't it?",
			gentle = "Oh dear, it doesn't match at all.",
			bold = "It doesn't match, and that's not right.",
			dreamy = "Hmm... it looks like two different fences.",
			easygoing = "Eh, it doesn't match... does it matter? It kind of matters.",
			proud = "It doesn't match, and mine is clearly the correct side.",
			shy = "Um... they don't match...",
			cheeky = "it doesn't match, and yours is louder",
			cool = "It doesn't match.",
			dramatic = "It doesn't MATCH! The whole street will see!",
			bookish = "A fence should match on both sides, actually, it's an old rule.",
			gloomy = "It doesn't match.|Heh... of course.",
			polite = "I am afraid it does not quite match.",
			foodie = "It doesn't match, it's like jam on one side and butter on the other.",
			_ = "It doesn't match, and a fence has to match.",
		}, "anger")
		say(s, "b", "{player}, you choose.|Whatever you say, the whole fence goes that colour.", "question")
		s:choice("Paint it all white.", function(c)
			burst(c, "a", {
				proud = "White, naturally.|I'll go and get the big brush.",
				bookish = "Actually, white reflects the most light, so it's the practical choice.",
				prickly = "Good, that's sensible.|...Thanks, {player}.",
				nervous = "You picked white?|Oh, phew, thank you.",
				sunny = "White! Yay, thank you, {player}!",
				gentle = "White, thank you, {player}, that's very fair.",
				bold = "White, good call, {player}.",
				dreamy = "White... like a cloud, thank you.",
				easygoing = "White, great, and it's less work too.",
				shy = "White... thank you, {player}.",
				cheeky = "white wins, hehe, sorry not sorry",
				cool = "White.|Thanks.",
				dramatic = "WHITE! Thank you, {player}!",
				gloomy = "White, huh.|Heh... I actually won something.",
				polite = "White, thank you kindly, {player}.",
				foodie = "White, like icing, thank you!",
				_ = "White it is.|Thank you, {player}.",
			}, "sparkle", "cheer")
			burst(c, "b", {
				gloomy = "White, fine, plain like everything else.",
				dramatic = "White, the colour of giving up.|Fine.",
				sunny = "Aww, white?|Okay, okay, I'll paint it white.",
				gentle = "White, then.|It's fine, it's only a fence.",
				bold = "White? Fine, but I'm painting my door red.",
				dreamy = "White... okay.|I'll paint little flowers on my side, very small.",
				easygoing = "White, fine, less thinking.",
				proud = "White? Hmph, very well, but it won't look as good.",
				shy = "Oh... okay, white.",
				cheeky = "white? boring|i'm adding one spot when nobody's looking",
				cool = "Fine.|White.",
				prickly = "Ugh, fine, white.",
				bookish = "White, fine, it's the practical choice.",
				polite = "White it is, then.",
				foodie = "White, fine, like plain toast.",
				nervous = "White? Okay, that's fine, really.",
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
				gentle = "Oh, really, {colour}?|Thank you, {player}.",
				bold = "Hah, {colour} it is!|Best fence on the street, right?",
				dreamy = "All {colour}... it'll be like living in a painting.",
				easygoing = "Nice, {colour}, and I've already done half.",
				proud = "Naturally, {colour}.|You have excellent taste, {player}.",
				shy = "Really? All {colour}?|Thank you...",
				cool = "Good, it's all {colour}, then.",
				prickly = "Hmph, good choice.|...Thanks.",
				bookish = "All {colour}, then.|I'll need four more tins, actually.",
				gloomy = "Really? Mine?|Heh... that never happens.",
				polite = "Thank you, {player}, how very kind.",
				foodie = "Yes!|I'm celebrating with a snack.",
				nervous = "Really? All of it? Oh, wow, thank you!",
				_ = "The whole fence in {colour}, and it's going to look great.",
			}, "sparkle", "cheer")
			burst(c, "a", {
				gloomy = "Fine, a party fence, great.",
				sunny = "Okay, okay, it's colourful at least!",
				gentle = "Oh, all right, it is quite pretty.",
				bold = "Fine, but I'm not painting it.",
				dreamy = "Hmm... maybe I'll get used to it.",
				easygoing = "Eh, fine, as long as I don't have to paint it.",
				proud = "Very well, but I still prefer white.",
				shy = "Oh... okay, that's fine.",
				cheeky = "fine, but i'm calling it your fence now",
				cool = "Fine.",
				prickly = "Ugh, fine, whatever.",
				dramatic = "My white DREAMS, gone!",
				bookish = "Fine, but white would have lasted longer, actually.",
				polite = "Very well, if that is what you think.",
				foodie = "Fine, it does look a bit like a cake.",
				nervous = "O-okay, as long as the neighbours don't mind.",
				_ = "Fine, but everyone's going to stare at it.",
			}, "sweat")
			c:rel(2)
			c:mood("b", 3)
			c:mood("a", -1)
		end)
		s:choice("Leave it half and half.", function(c)
			c:n("The fence stayed half and half, and people still stop to look at it.")
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
			sunny = "Try them all, all three!|Which one's your favourite?",
			gentle = "Take your time with each one, okay?|Tell me which you like best.",
			bold = "Three teas, one winner.|Pick the best.",
			dreamy = "Each one tastes like a different time of day...|Which one do you like?",
			easygoing = "No rush, just sip them and tell me which is best.",
			shy = "Um... could you try these and tell me which is best?",
			cheeky = "one of these is salty, jk|which one's best",
			cool = "Try all three.|Which is best?",
			prickly = "Try them, and be honest, don't just pick the middle one.",
			dramatic = "Three teas, three STORIES.|Which one is your favourite?",
			gloomy = "I made three teas.|Heh... they probably all taste the same.",
			polite = "Would you be kind enough to try all three and tell me which you prefer?",
			nervous = "Can you try these? Be honest, but not too honest.",
			_ = "Which one's best?|Be honest with me.",
		}, "question")
		burst(s, "b", {
			cool = "Hm, the middle one.",
			gloomy = "They all taste like tea to me... maybe the middle one?",
			polite = "They're all lovely, but if I had to choose, the middle one.",
			dramatic = "The middle one tastes like a rainy afternoon with a good book.",
			foodie = "Mmm, the middle one is smoky with a bit of honey at the end.|Am I right?",
			sunny = "The middle one, the middle one!",
			gentle = "Oh, the middle one, it's so soft.",
			bold = "The middle one, easy.",
			dreamy = "The middle one... it tastes like the evening.",
			easygoing = "The middle one, I think, it's the comfiest.",
			proud = "The middle one, obviously, I have very good taste.",
			shy = "Um... the middle one?",
			cheeky = "the middle one, final answer",
			prickly = "The middle one, and don't make me do this again.",
			bookish = "The middle one, it's less bitter, actually.",
			nervous = "The middle one? Is that wrong?",
			_ = "The middle one, I think.",
		}, "sparkle")
		burst(s, "a", {
			foodie = "Yes, yes!|Finally, someone who gets it.",
			proud = "Correct, that's the one I blended.|You've got good taste.",
			sunny = "Yes! Ehehe, that's my favourite too!",
			gentle = "Oh, that's my favourite too.",
			bold = "Hah, right answer.",
			dreamy = "The middle one... I knew you'd like it.",
			easygoing = "Nice, that one's the easiest to make, too.",
			shy = "Oh... that's the one I like too.",
			cheeky = "correct, you win a cup of tea, hehe",
			cool = "Good.|That's the one.",
			prickly = "Fine, that's the right answer.|...Thanks.",
			dramatic = "The middle one! You have a GIFT.",
			bookish = "The middle one, good, that matches my notes.",
			gloomy = "The middle one.|Heh... I got one right.",
			polite = "The middle one, how lovely, I agree.",
			nervous = "The middle one? Oh, phew, that's the one I hoped.",
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
			cool = "Hm, I couldn't settle.",
			sunny = "Nope! My head's too full of tomorrow, ehehe.",
			gentle = "No, I've been worrying about a friend.|It's nice to see you, though.",
			bold = "No, so I came out here instead of lying there.",
			proud = "I don't need much sleep, naturally.",
			shy = "Um... no, I couldn't.",
			cheeky = "nope, i had three cups of tea, my own fault",
			prickly = "No, my neighbour snores through the wall.",
			dramatic = "Sleep has LEFT me.",
			bookish = "No, I read until one, and then I was wide awake.",
			polite = "I am afraid not, no.",
			_ = "No, I couldn't settle.",
		}, "zzz")
		s:n("They sat and listened to the water until the sky went light.")
		burst(s, "a", {
			prickly = "Same time tomorrow?|...I hope not, but maybe.",
			sunny = "Same time tomorrow?|Ehehe, I hope we both sleep, though.",
			gentle = "Let's both try to sleep tomorrow, okay?",
			bold = "Same time tomorrow?|No, we're both sleeping tomorrow, right?",
			dreamy = "Same time tomorrow...?|Maybe the moon will be out again.",
			easygoing = "Same time tomorrow?|Nah, I'm sleeping through tomorrow.",
			proud = "Same time tomorrow? I'll allow it.",
			shy = "Um... same time tomorrow?|Only if we can't sleep.",
			cheeky = "same time tomorrow?|bring snacks this time",
			cool = "Same time tomorrow?|Maybe.",
			dramatic = "Same time TOMORROW?|...I hope not, honestly.",
			bookish = "Same time tomorrow?|Actually, I'd rather sleep.",
			gloomy = "Same time tomorrow?|Heh... probably.",
			polite = "Same time tomorrow?|Though I do hope we both sleep.",
			foodie = "Same time tomorrow?|I'll bring toast.",
			nervous = "Same time tomorrow? I-I hope not, I need sleep.",
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
			sunny = "Okay, okay, ready!",
			gentle = "All right, and no hard feelings, okay?",
			bold = "Hah, you're on.",
			dreamy = "Hmm... I'll pick whatever feels right.",
			easygoing = "Sure, but if I lose, I'm sitting on the floor next to it.",
			shy = "Um... okay.",
			cheeky = "ok, and i always pick rock, jk",
			prickly = "Fine, but no cheating.",
			dramatic = "This chair will be MINE!",
			bookish = "Actually, most people pick rock first, so I'm ready.",
			gloomy = "Fine.|Heh... I'll lose.",
			polite = "Very well, the best of luck to you.",
			foodie = "Fine, and the loser gets the snacks.",
			_ = "Fine, on three.",
		}, "question")
		local w, l = winner(ctx, a, b)
		s:n("It went to best of five in the end.")
		burst(s, w, WINS, "sparkle", "cheer")
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
		s:n("{a} finished at the {job} and found {b} waiting at the corner.")
		burst(s, "a", {
			sunny = "You waited for me!|That's so nice, thank you!",
			prickly = "You didn't have to wait.|...But thanks for waiting.",
			gloomy = "You waited for me?|Heh... that's nice.",
			cool = "Hey. Want to walk home together?",
			nervous = "Y-you waited? How long were you here?|Sorry, and thank you.",
			gentle = "Oh, you waited for me?|That's so sweet.",
			bold = "Hah, you waited? Good, let's go.",
			dreamy = "Oh... you're here.|That's nice.",
			easygoing = "Hey, you waited.|Nice, I didn't want to walk alone.",
			proud = "Waiting for me? Naturally.",
			shy = "Oh... you waited for me?",
			cheeky = "you waited for me? aww|you must really like me, hehe",
			dramatic = "You WAITED for me?|What a friend!",
			bookish = "You waited? I'm twenty minutes late, actually, sorry.",
			polite = "How kind of you to wait for me.",
			foodie = "You waited!|Are you hungry? I'm starving.",
			_ = "Oh, you waited for me.",
		}, "heart")
		burst(s, "b", {
			foodie = "The bakery's on the way, and I wanted someone to share the buns with.",
			bookish = "I was reading and lost track of time, and then you came out.",
			cheeky = "i was just standing here|total coincidence, hehe",
			sunny = "I wanted to walk with you, so I waited!",
			gentle = "I thought you might want some company after a long day.",
			bold = "I was passing, so I waited, and now we're walking.",
			dreamy = "I was watching the clouds, and then you came out.",
			easygoing = "I sat down for a minute, and it turned into twenty.",
			proud = "I simply thought you'd want my company.",
			shy = "Um... I just thought we could walk together.",
			cool = "I was nearby.|Let's go.",
			prickly = "I wasn't waiting, I was just standing here.",
			dramatic = "I couldn't let you walk home ALONE!",
			gloomy = "I had nothing else to do.|Heh... and I wanted to.",
			polite = "I hope you do not mind, I thought we might walk together.",
			nervous = "I-I hope it's okay that I waited?",
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
			gentle = "{player}, we made you a little something.|We hope you like it, okay?",
			bold = "{player}, we made you something, and you're going to love it.",
			dreamy = "{player}... we made you something.|It took us all afternoon.",
			easygoing = "{player}, we made you something.|It took ages, but in a nice way.",
			cool = "{player}, this is for you.",
			prickly = "{player}, we made you something, so don't make a fuss.",
			bookish = "{player}, we made you something, and it took four evenings, actually.",
			foodie = "{player}, we made you something, and no, you can't eat it.",
			nervous = "{player}, we made you something.|I hope you like it, is that okay?",
			_ = "{player}, we made you something.",
		}, "sparkle")
		burst(s, "b", {
			foodie = "It's a cushion.|I wanted to stitch a cake on it, but I was outvoted.",
			nervous = "It's a cushion, is that okay?|The stitching's a bit wonky on one side.",
			bookish = "It's a cushion with forty rows of stitches.|I counted them.",
			sunny = "It's a cushion, with a sun on it!",
			gentle = "It's a cushion, for your favourite chair.",
			bold = "It's a cushion, and it's built to last.",
			dreamy = "It's a cushion... soft like a cloud.",
			easygoing = "It's a cushion, perfect for naps.",
			proud = "It's a cushion, and the stitching is excellent, if I say so myself.",
			shy = "Um... it's a cushion.",
			cheeky = "it's a cushion|there's a whoopee cushion inside, jk",
			cool = "It's a cushion.",
			prickly = "It's a cushion, obviously.",
			dramatic = "It's a CUSHION, made with our own hands!",
			gloomy = "It's a cushion.|Heh... it's a bit lumpy.",
			polite = "It is a cushion, for your home.",
			_ = "It's a cushion for your house, and {a} did the stitching.",
		}, "heart")
		s:choice("I love it.", function(c)
			burst(c, "a", {
				sunny = "Ehehe, you love it? I'm so happy!",
				gentle = "Oh, I'm so glad, we hoped you would.",
				bold = "Hah! Told you they'd love it.",
				dreamy = "Hmm... I'm so glad.",
				easygoing = "Nice, all that sitting still was worth it.",
				proud = "Naturally, we made it very well.",
				shy = "Oh... really? I'm so glad.",
				cheeky = "hehe, knew you would",
				cool = "Good, we hoped so.",
				prickly = "Good, because it took ages.",
				dramatic = "They LOVE it! Did you hear that?",
				bookish = "I'm so pleased, it took us four evenings.",
				gloomy = "You do? Heh... that's a relief.",
				polite = "We're very glad, thank you.",
				foodie = "Brilliant, that calls for cake.",
				nervous = "R-really? Oh, phew!",
				_ = "You do? Oh, good!",
			}, "sparkle", "cheer")
			burst(c, "b", {
				sunny = "Put it somewhere everyone can see it!",
				gentle = "It'll look lovely on your chair.",
				bold = "Put it somewhere good, all right?",
				dreamy = "It'll be nice for your naps...",
				easygoing = "It's perfect for naps, trust me.",
				proud = "Make sure you keep it somewhere it can be admired.",
				shy = "Um... I'm really glad.",
				cheeky = "you're welcome, hehe",
				cool = "Glad you like it.",
				prickly = "Don't spill anything on it.",
				dramatic = "Cherish it FOREVER.",
				bookish = "It's good for reading, too, I tested it.",
				gloomy = "It'll get squashed, but that's what cushions are for, heh.",
				polite = "We hope it brings you comfort.",
				foodie = "Don't eat cookies on it, I learned that the hard way.",
				nervous = "Th-the wonky side goes at the back, okay?",
				_ = "We're really glad you like it.",
			}, "heart")
			c:keep("keep_cushion", "a")
			c:rel(6)
			c:mood("a", 4)
			c:mood("b", 4)
		end)
		s:choice("Did you stitch it yourselves?", function(c)
			burst(c, "b", {
				cheeky = "we did|that corner's a bit wonky, so don't look too closely",
				sunny = "We did, all by ourselves!|Ehehe, one corner's a bit wonky.",
				gentle = "We did, and one corner's a bit wonky, so be kind to it.",
				bold = "We did, and don't look at the wonky corner.",
				dreamy = "We did... one corner went its own way.",
				easygoing = "Yeah, we did, slowly.|One corner's a bit wonky.",
				proud = "Of course, and most of it is perfect.",
				shy = "Um, yes... one corner's a bit wonky, sorry.",
				cool = "We did.|One corner's wonky.",
				prickly = "Yes, and don't look at the corner.",
				dramatic = "Every STITCH, by hand!|...Except the wonky corner.",
				bookish = "We did, forty rows, and one corner went a bit wrong.",
				gloomy = "We did.|Heh... one corner's a mess.",
				polite = "We did, though one corner is a little uneven.",
				foodie = "We did, between snacks, so one corner's a bit wonky.",
				nervous = "We did! The corner's a bit wonky, is that okay?",
				_ = "We did, and that corner's a bit wonky, so don't look too closely.",
			}, "sweat")
			burst(c, "a", {
				sunny = "Ehehe, the wonky corner was mine.",
				gentle = "We did our best, and we had fun doing it.",
				bold = "Hah, I did the straight bits.",
				dreamy = "Hmm... the wonky bit is my favourite.",
				easygoing = "Heh, the wonky bit is my work.",
				proud = "The good stitches are mine, for the record.",
				shy = "Hehe... the wonky corner was me.",
				cheeky = "the wonky bit is art",
				cool = "The wonky bit was me.",
				prickly = "It's not that wonky.|...Okay, it's a bit wonky.",
				dramatic = "Every stitch was made with LOVE.",
				bookish = "Forty rows by hand, and only one went wrong.",
				gloomy = "Heh, the wonky corner was me, as usual.",
				polite = "We did, and we hope you'll forgive the corner.",
				foodie = "We did, between snacks.",
				nervous = "I-it was my first time sewing, sorry!",
				_ = "Ha, we did our best.",
			}, "music", "laugh")
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
			sunny = "Ooh, watch mine!|...Three! Ehehe!",
			gentle = "Oh, that was a good one.|Let me try.",
			easygoing = "Nice.|Mine did two and then gave up, like me.",
			proud = "Four? Watch me do six, naturally.",
			shy = "Um... mine did one.|Is that okay?",
			cheeky = "watch this|...ok that one doesn't count",
			cool = "Watch.|...Five.",
			prickly = "Ugh, mine keep sinking.",
			dramatic = "Watch my stone FLY!|...It sank.",
			gloomy = "Mine sank, as usual.",
			polite = "How lovely, may I try?",
			foodie = "Nice!|This flat one looks like a cookie.",
			_ = "Watch this one.|...Two, but it still counts.",
		}, "question")
		local w, l = winner(ctx, a, b)
		s:n("{" .. w .. "} got eight skips on the last throw.")
		burst(s, w, WINS, "sparkle", "cheer")
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
			sunny = "Ooh, it's a little robin!",
			gentle = "Oh, I think that's a robin, the little thing.",
			bold = "That's a crow, easy.",
			dreamy = "Hmm... it's a bird that looks like it's thinking.",
			easygoing = "No idea, but it looks comfy.",
			proud = "That's a thrush, obviously.",
			shy = "Um... a sparrow, maybe?",
			prickly = "It's a starling, and it's loud.",
			polite = "I believe that is a blackbird.",
			foodie = "It's the one that always steals my crumbs.",
			nervous = "Is it a hawk? Should we move?",
			_ = "No idea, just write 'small brown one'.",
		}, "idea")
		burst(s, "a", {
			bookish = "I'll draw it, and we can look it up later.",
			sunny = "Ehehe, I'll write it down with a smiley face!",
			gentle = "I'll write it down, and we can ask someone later.",
			bold = "I'm writing it down, done.",
			dreamy = "I'll draw it in the corner of the page...",
			easygoing = "I'll just write 'bird'.",
			proud = "I'll write it down properly, naturally.",
			shy = "Um... I'll write it with a question mark.",
			cheeky = "i'm writing 'mystery bird', hehe",
			cool = "Question mark, then.",
			prickly = "Fine, a question mark, but I'm not happy about it.",
			dramatic = "A MYSTERY bird! I'll write it in big letters.",
			gloomy = "Question mark.|Heh... like everything else.",
			polite = "I will mark it as unknown, then.",
			foodie = "I'll write 'crumb thief'.",
			nervous = "What if we write it down wrong? I'll put a question mark.",
			_ = "I'm putting a question mark next to it anyway.",
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
			gentle = "I heard you were ill, so I made soup.|You can say no, but I'm leaving it anyway.",
			bold = "You're ill, so I brought soup.|You're eating it, and that's that.",
			prickly = "I made too much soup, and that's the only reason I'm here.|...How's the cough?",
			foodie = "It's chicken and barley, and it's been on the stove for two days.|Eat it while it's hot.",
			nervous = "H-hi, sorry, I made soup.|I didn't know what else to do, is that okay?",
			cheeky = "soup delivery|tips welcome, hehe",
			sunny = "Soup delivery! I made it with extra carrots!",
			dreamy = "I made you soup...|It's been bubbling all morning.",
			easygoing = "I made soup, and I made a lot, so eat up.",
			proud = "I've made you my famous soup.|You'll feel better in no time, naturally.",
			shy = "Um... I made you some soup.|I hope that's okay.",
			cool = "Soup.|Eat it while it's hot.",
			dramatic = "I've brought SOUP!|Eat it, and get well.",
			bookish = "I made you soup, it's got ginger in it, actually, which helps with colds.",
			gloomy = "I made you soup.|Heh... it's probably not very good.",
			polite = "I made you some soup, and I hope you feel better soon.",
			_ = "I heard you were ill, so I made you some soup.",
		}, "heart")
		burst(s, "a", {
			gloomy = "For me?|Heh... thanks.",
			proud = "I was managing perfectly well.|...It does smell very good.",
			shy = "Oh... thank you.|You didn't have to do that.",
			cool = "...Thanks, I mean it.",
			dramatic = "You've SAVED me.|Come in, just don't get too close.",
			sunny = "Soup! Ehehe, thank you, thank you!",
			gentle = "Oh, thank you, that's so kind.",
			bold = "Thanks, I needed that.",
			dreamy = "Oh... it smells like a warm blanket.",
			easygoing = "Oh, nice, now I don't have to cook.",
			cheeky = "soup? you're the best|*cough*",
			prickly = "I'm fine, I don't need... okay, thanks.",
			bookish = "Thank you, that's exactly what I needed, actually.",
			polite = "Thank you so much, that is very kind of you.",
			foodie = "Mmm, that smells amazing.|Thank you.",
			nervous = "Oh, thank you! Don't come too close, I don't want you to catch it.",
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
	{ what = "sing a song on the fountain steps", done = "{a} sang the whole song, and a few people clapped." },
	{
		what = "wear their sweater backwards all day",
		done = "{a} wore it backwards all day, and three people asked if it was a new style.",
	},
	{
		what = "say good morning to every gull on the pier",
		done = "{a} said good morning to every gull on the pier, and a few people clapped.",
	},
	{
		what = "carry the other one's shopping for a week",
		done = "{a} carried the shopping all week and only grumbled twice.",
	},
}

event({
	id = "forfeit",
	when = "day",
	weight = W({ base = 0.09, rel = 0, traits = { mischief = 0.2 } }),
	scene = function(ctx, a, b)
		local f = ctx.rng:pick(FORFEITS)
		local s = K.scene(ctx, "A bet's a bet"):with({ forfeit = f.what })
		s:n("{a} lost a bet to {b}, and now has to {forfeit}.")
		burst(s, "a", {
			proud = "I'm doing this with dignity, so don't look.",
			shy = "Do I really have to?|...I have to, don't I?",
			dramatic = "If this is the end of me, let it be remembered.",
			cheeky = "you'll pay for this|in buns",
			gloomy = "Of course I lost, as usual.",
			sunny = "Okay, okay, I'll do it!|Ehehe, it'll be fun, I think.",
			gentle = "Oh, all right, a promise is a promise.",
			bold = "Fine, I'll do it, and I'll do it properly.",
			dreamy = "Hmm... okay.|I'll pretend it's a dream.",
			easygoing = "Eh, it's fine, let's get it over with.",
			cool = "Fine.|Let's go.",
			prickly = "Ugh, fine.|Don't watch.",
			bookish = "A bet's a bet, I suppose, and I did agree to it.",
			polite = "Very well, I always keep my word.",
			foodie = "Fine, but I'm having a snack first.",
			nervous = "Oh no, oh no, okay, I'll do it.",
			_ = "Fine, a bet's a bet.",
		}, "sweat")
		burst(s, "b", {
			cheeky = "go on then, we're all waiting",
			gentle = "You can skip it if it's too much.|...You're doing it anyway, aren't you?",
			proud = "Rules are rules.",
			bold = "Go on, and do all of it.",
			sunny = "Go on, go on!",
			dreamy = "Go on... I'll watch.",
			easygoing = "Take your time, but go on.",
			shy = "Um... you can do it.",
			cool = "Go on.",
			prickly = "Go on, I've been waiting all week for this.",
			dramatic = "The moment has COME!",
			bookish = "Go on, I'm timing you, actually.",
			gloomy = "Go on.|Heh... I'd hate to be you.",
			polite = "Whenever you are ready.",
			foodie = "Go on, and then we'll get lunch.",
			nervous = "G-go on, but only if you're okay.",
			_ = "Go on, then.",
		}, "laugh", "laugh")
		s:n(f.done)
		burst(s, "a", {
			proud = "Flawless, naturally.|The next bet's mine.",
			shy = "That was awful...|...but it was a bit fun, too.",
			cheeky = "done|rematch next week, and you're going down",
			sunny = "Done! Ehehe, that was actually fun!",
			gentle = "There, all done.|That wasn't so bad.",
			bold = "Done, and I did all of it.|Rematch next week.",
			dreamy = "It's done... it felt like a dream.",
			easygoing = "Done.|Now I need a nap.",
			cool = "Done.|Next time it's you.",
			prickly = "Done, and nobody talk about it.",
			dramatic = "It is DONE!|I've never been so brave.",
			bookish = "Done, and it took less time than I thought, actually.",
			gloomy = "Done.|Heh... at least it's over.",
			polite = "There, I have kept my word.",
			foodie = "Done, and now I'm starving.",
			nervous = "I did it! Oh, phew, phew.",
			_ = "Done.|Rematch next week?",
		}, "sparkle")
		s:rel(4)
		s:mood("b", 3)
		s:log("{a} paid off a lost bet to {b}.")
		return s:done()
	end,
})

return list
