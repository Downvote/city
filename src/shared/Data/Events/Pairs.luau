--!nonstrict
-- Two or three villagers together: games and rivalries, duets, secret handshakes, picnics,
-- misunderstandings and promises, friendships starting and falling apart, making up, and best
-- friends; and the smaller things of a week: a jigsaw with a piece gone, cuttings over a fence, a
-- fence in two colours, three teas, two night owls at the fountain, rock paper scissors for the
-- comfy chair, a walk home after work, a present they made you, stones skipped, birds counted.
-- How it goes depends on who they are and how well they get on, and they say it in short bursts,
-- each in their own voice (Data/Personalities). There is no romance (the user: "remove any
-- romance, just best friends is the highest").

local K = require(script.Parent.Kit)
local Chatter = require(script.Parent.Chatter)
local Sayings = require(script.Parent.Parent.Sayings)

local W = K.W

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
	s:by(who, {
		proud = { "That didn't count. I wasn't ready.", "Best of three. Best of five." },
		bold = { "Rematch. Now.", "I was going easy on you." },
		easygoing = "Eh. You win. Snacks?",
		gentle = "Well played. Really.",
		shy = "You're good at this...",
		cheeky = "I let you win. Remember that.",
		cool = "Hm. Next time.",
		prickly = { "Whatever. I wasn't trying.", "Fine. You win. Don't gloat." },
		dramatic = "Defeated. In front of everyone. I'll never recover.",
		bookish = "Interesting. I'll need to study your technique.",
		gloomy = "Knew I'd lose. I always lose.",
		polite = "Well done. That was very well played.",
		foodie = "Fine. Loser buys the buns. I'll buy the buns.",
		nervous = "Did I do it wrong? I think I did it wrong.",
		_ = "Next time. Next time for sure.",
	}, if K.isPers(ctx, vid, "proud", "bold", "prickly", "dramatic") then "anger" else "sweat")
end

-- the one whose cake lost the bake off
local SULK = {
	proud = "Hmph. I'm eating mine on my own, then.",
	gentle = "Oh, well done. It was fun to make anyway.",
	shy = "Oh. That's okay. Yours did look nicer.",
	bold = "Rematch. Next week. Bigger cakes.",
	easygoing = "Eh. More for me.",
	cheeky = "Fine. I'm hiding yours.",
	cool = "Fair.",
	prickly = "Whatever. Mine tastes better and you know it.",
	dramatic = "My cake. Rejected. I need to lie down.",
	gloomy = "Knew it.",
	polite = "Congratulations. It really was lovely.",
	foodie = "Fine. But I'm having a slice of both. For research.",
	nervous = "Was mine bad? Was it the icing? It was the icing.",
	_ = "Fine. Fine. More for me.",
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
		s:by("a", {
			nervous = "Your move. No rush. Okay, a bit of rush.",
			cool = "Your move.",
			dramatic = "Your move. Choose wisely. Everything depends on it.",
			_ = "Your move. Take your time. Not that much time.",
		}, "question")
		local w, l = winner(ctx, a, b)
		s:n("Then, one move, and it was over.")
		s:voice(w, "brag", "sparkle", "cheer")
		loses(s, ctx, l, ctx.stars[l])
		s:choice("Rematch", function(c)
			c:n("They played again. And again. Nobody's sure who won in the end.")
			c:rel(6)
			c:mood("a", 2)
			c:mood("b", 2)
		end)
		s:choice("Call it a draw", function(c)
			c:by(w, {
				proud = "A draw. Fine. We both know I won.",
				gentle = "A draw. That seems fair.",
				cheeky = "A draw. I'm still telling everyone I won.",
				polite = "A draw. Thank you, {player}. Very diplomatic.",
				_ = "A draw. Fine. I won, though.",
			}, "sweat")
			c:say(l, "Draw.", "anger")
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
		s:say("a", "One two three four, I declare a thumb war.", "idea", "point")
		s:by("b", {
			cool = "Fine.",
			nervous = "Wait, wait. What are the rules? Okay. Go.",
			dramatic = "You'll regret this.",
			_ = "You're on.",
		}, "sparkle")
		s:n("It was very serious. There were rules nobody had heard of before.")
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
		s:say("a", "Staring contest. First to blink buys the buns.", "idea")
		s:n("They stared. A gull landed between them. They kept staring.")
		if ctx.rng:chance(0.5) then
			s:n("Then {b} sneezed.")
			s:say("b", "That's not blinking. Sneezing isn't blinking.", "sweat")
			s:say("a", "Your eyes shut. Buns, please.", "sparkle")
		else
			s:n("Then the gull pecked {a}'s shoe.")
			s:say("a", "Ow. I blinked. The gull cheated.", "anger")
			s:say("b", "The gull's on my side. Buns, please.", "sparkle")
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
	{ "What runs but never walks?", "A river. The sea just sits there." },
}

event({
	id = "riddles",
	when = "any",
	weight = W({ base = 0.12, traits = { focus = 0.2 } }),
	scene = function(ctx, a, b)
		local r = ctx.rng:pick(RIDDLES)
		local s = K.scene(ctx, "Riddle me this"):with({ q = r[1], ans = r[2] })
		s:say("a", "Riddle. {q}", "question", "point")
		if ctx.rng:chance(0.5) then
			s:say("b", "{ans}", "idea")
			s:by("a", {
				prickly = "Who told you? Someone told you.",
				dramatic = "How? How did you know?",
				_ = "How did you know that?",
			}, "anger")
			s:voice("b", "brag", "sparkle")
		else
			s:voice("b", "hmm", "question")
			s:say("a", "{ans}", "sparkle", "cheer")
			s:by("b", {
				bookish = "Oh, come on. That's barely a riddle. ...I didn't get it, though.",
				gloomy = "I'd never have got that.",
				_ = "Oh, come on.",
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
		s:n("{a} and {b} have each made a cake. They want you to say whose is better.")
		s:by("a", {
			proud = "Mine has three layers. Count them.",
			cheeky = "Mine has a surprise in the middle. A good one. Hehe.",
			foodie = "Mine's brown butter and pear. I've been working on it for a month.",
			nervous = "Mine's lemon. I hope it's lemon enough. Is it lemon enough?",
			_ = "Mine's lemon. Real lemons.",
		}, "sparkle", "point")
		s:by("b", {
			proud = "Mine's flawless. Look at the icing.",
			shy = "Mine's... a bit flat. But it tastes nice. I think.",
			gloomy = "Mine sank in the middle. It still counts.",
			dramatic = "Mine is chocolate. Dark. Mysterious. Like me.",
			_ = "Mine's chocolate. You can't beat chocolate.",
		}, "sparkle")
		s:say("a", "{player}. Be fair. Pick one.", "question")
		s:choice("{a}'s", function(c)
			c:voice("a", "excited", "sparkle", "cheer")
			c:by("b", SULK, "sweat")
			c:mood("a", 6)
			c:mood("b", -4)
			c:rel(-2)
		end)
		s:choice("{b}'s", function(c)
			c:voice("b", "excited", "sparkle", "cheer")
			c:by("a", SULK, "sweat")
			c:mood("b", 6)
			c:mood("a", -4)
			c:rel(-2)
		end)
		s:choice("They're both lovely", function(c)
			c:say("a", "That's what people say when they can't choose, {player}.", "sweat")
			c:say("b", "Let's just eat them both.", "heart")
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
		s:by("b", {
			nervous = "La la... sorry. Can we start again? What key is this?",
			dramatic = "Laaa. Laaaaa. Right. I'm ready. The world is ready.",
			_ = "La la laaa. Hang on. What key is this in?",
		}, "music")
		if ctx.rng:chance(0.55) then
			s:n("Then it came together. {b} sang, {a} played, and people stopped to listen.")
			s:voice("a", "excited", "music", "cheer")
			s:rel(8)
			s:all(2)
		else
			s:n("{a} played one song and {b} sang a different one. Loudly. Both at once.")
			s:voice("b", "laugh", "music", "laugh")
			s:say("a", "We'll practise. A lot.", "sweat")
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
		s:say("a", "We need a secret handshake. Every best friend has one.", "idea", "point")
		s:say("b", "Shake, shake, elbow, spin...", "music")
		s:say("a", "...clap, thumbs, wiggle, other elbow, bow.", "music")
		s:n("It now takes a full minute to say hello.")
		s:by("b", {
			proud = "Nobody else will ever know it. It's ours.",
			easygoing = "I'll remember half of it. That's enough.",
			cool = "Good. Again.",
			nervous = "Was it elbow then spin, or spin then elbow? Again. Slower.",
			bookish = "I'm writing it down. In code.",
			_ = "Again. From the top.",
		}, "heart", "cheer")
		s:rel(9)
		s:memo("a", "{b} and I have a secret handshake now. No, I can't show you, {player}.")
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
		s:say("a", "I'll teach you mine if you teach me yours.", "music")
		s:n("{a}'s dance was mostly arms. {b}'s was mostly feet. They put them together.")
		s:by("b", {
			bold = "We look amazing. Don't tell me if we don't.",
			shy = "I keep stepping on you. Sorry. Sorry.",
			dreamy = "We look like two leaves in the wind...",
			prickly = "This is silly. ...Again. From the arms bit.",
			gloomy = "We look ridiculous. I'm having fun, though. Weird.",
			dramatic = "Look at us. The whole town will want lessons.",
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
	{ "I said I'd bring the pie.", "I've borrowed a pig for the afternoon." },
	{ "I said meet me by the fountain.", "I've been waiting by the mountain all morning." },
	{ "I said I'd lend you my coat.", "I've told everyone you're giving me a goat." },
	{ "I said the party's at six.", "I brought six cakes. Is that wrong?" },
}

event({
	id = "misheard",
	when = "day",
	weight = W({ base = 0.15 }),
	scene = function(ctx, a, b)
		local m = ctx.rng:pick(MISHEARD)
		local s = K.scene(ctx, "A mix up"):with({ said = m[1], heard = m[2] })
		s:say("b", "{heard}", "sparkle")
		s:say("a", "...{said}", "sweat")
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
		s:say("a", "Promise me something.", "heart")
		s:say("a", "One day we'll get up early and watch the sun come up from the hill.", "heart")
		s:by("b", {
			easygoing = "Early early? ...Okay. For you. Once.",
			proud = "I promise. And I always keep my promises.",
			shy = "I promise. I'll bring a blanket.",
			cool = "Deal.",
			prickly = "Fine. Promise. You'd better bring snacks.",
			gloomy = "It'll be cloudy. But I promise.",
			nervous = "I promise. You'll have to knock very loudly.",
			_ = "Promise. Pinky promise.",
		}, "heart")
		s:rel(8)
		s:memo("a", "{b} and I are going to watch the sunrise one day. We promised.")
		s:memo("b", "I promised {a} we'd watch the sunrise. I'm going to need an alarm.")
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
		s:by("a", {
			foodie = "Egg, cheese, cucumber, and one I'm calling the mystery. Try the mystery.",
			_ = "There's one in here I don't remember making. Want to find out what it is?",
		}, "music")
		if ctx.rng:chance(0.4) then
			s:n("Then the ants found them. All of them.")
			s:by("b", {
				bold = "Back. These are our sandwiches.",
				gentle = "Oh, let them have a crumb or two.",
				shy = "There's one on my sandwich. It's looking at me.",
				gloomy = "Course. Ants. Always ants.",
				nervous = "Are they on me? Are they on me? Check my back.",
				_ = "Move the rug. Quick. Quick.",
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
		s:n("{a} threw a snowball at {b}. It was a very good throw.")
		s:by("b", {
			bold = "Oh, it's on!",
			shy = "Eep. Cold. Cold. Down my collar.",
			proud = "You'll regret that. Instantly.",
			gentle = "Oh. You little... right.",
			cool = "...Okay.",
			prickly = "Really? Really. Fine.",
			dramatic = "You've started something you can't finish.",
			_ = "That's it. Snow war.",
		}, "anger")
		s:n("Ten minutes later both of them were white from head to toe and laughing too hard to throw.")
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
		s:n("{a} and {b} spent the whole afternoon on a sandcastle. Four towers and a moat.")
		s:by("a", {
			proud = "The finest castle on this beach. On any beach.",
			dreamy = "A crab lives in the left tower now. He's the king.",
			bookish = "The moat's at the right depth. I measured with a spoon.",
			_ = "Don't step on it. Nobody step on it.",
		}, "sparkle", "point")
		s:say("b", "I did the flag. The flag's the important bit.", "music")
		s:choice("Leave it for the tide", function(c)
			c:by("a", {
				dreamy = "The sea can have it. It'll make something else out of the sand.",
				proud = "The tide won't knock down anything better all year.",
				gloomy = "The tide'll take it. Things go. It was good while it lasted.",
				_ = "Leave it. The sea can have it tonight.",
			}, "heart")
			c:leave("sandcastle", 12, "a")
			c:rel(8)
			c:memo("b", "Our sandcastle might still be there. Go and look, {player}.")
		end)
		s:choice("Take a picture first", function(c)
			c:say("b", "Smile, castle.", "sparkle", "cheer")
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
		s:n("{a} borrowed {b}'s favourite mug and dropped it. It's in three pieces.")
		s:by("a", {
			nervous = "{player}. {player}. What do I do? {b} loves that mug.",
			gloomy = "I broke {b}'s mug. Course I did. What now, {player}?",
			dramatic = "{player}. I've done a terrible thing. The mug.",
			_ = "What do I do, {player}? {b} loves that mug.",
		}, "sweat")
		s:choice("Tell {b} now", function(c)
			c:say("a", "{b}... I broke your mug. I'm really sorry.", "sad")
			c:by("b", {
				gentle = "Oh. It's only a mug. Thank you for telling me.",
				proud = "That mug can't be replaced. ...But thank you for being honest.",
				easygoing = "Eh. I've got loads. Don't worry about it.",
				bold = "You what? ...Fine. You owe me a mug.",
				cool = "Okay. Thanks for telling me.",
				prickly = "Great. ...It's fine. It was a bit chipped anyway.",
				dramatic = "My mug. We had years together. ...I forgive you.",
				polite = "Oh, please don't worry. Thank you for telling me.",
				_ = "Oh. Well. Thanks for telling me.",
			}, "question")
			c:rel(3)
			c:mood("a", 3)
		end)
		s:choice("Glue it back together", function(c)
			c:n("{a} glued it. It looks nearly the same, if you squint, from far away.")
			if ctx.rng:chance(0.5) then
				c:say("b", "Has my mug always had a crack down it?", "question")
				c:say("a", "...Yes?", "sweat")
				c:rel(-4)
			else
				c:say("b", "My mug. Thanks for bringing it back.", "heart")
				c:say("a", "Mm. Don't put anything hot in it.", "sweat")
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
		s:by("a", {
			proud = "I wore it first. Everyone knows I wore it first.",
			cheeky = "Twins. We're twins now. Hold my hand.",
			shy = "Oh no. I'll go and change.",
			cool = "Huh.",
			dramatic = "This square isn't big enough for two of this jumper.",
			_ = "Well. One of us has good taste.",
		}, "sweat")
		s:by("b", {
			proud = "Mine fits better.",
			easygoing = "Saves people telling us apart. Wait.",
			prickly = "Change. Now. ...Fine, I'll change.",
			gloomy = "Of course. The one day I dress up.",
			_ = "Great minds.",
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
		s:by("b", {
			bookish = "That one's a bear. The three in a row are its belt, I read.",
			_ = "That one's a bear. Those three are its belt.",
		}, "point")
		s:say("a", "Bears don't wear belts.", "question")
		s:say("b", "This one does. He's a smart bear.", "sparkle")
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
		s:n("{a} and {b} sat on the pier with one rod between them for three hours.")
		s:by("a", {
			dramatic = "Something's biting. Something huge. Stand back.",
			nervous = "Something's biting. What do I do? What do I do?",
			_ = "Something's biting. Something big.",
		}, "idea")
		local catch =
			ctx.rng:pick({ "an old boot", "a very small fish", "a crab, holding on out of spite", "somebody's hat" })
		s:with({ catch = catch })
		s:n("It was {catch}.")
		s:by("b", {
			cheeky = "Dinner. Tonight we feast.",
			easygoing = "Still counts. Back in it goes.",
			gloomy = "Course it is.",
			foodie = "Not dinner. Not dinner at all.",
			_ = "Well. We caught something.",
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
		s:say("a", "Guess who I am. 'Oh, hello, is it lunch yet? I simply must have a bun.'", "music", "point")
		s:say("b", "Is that meant to be me?", "question")
		local good = K.isPers(ctx, b, "cheeky", "sunny", "easygoing") or ctx.rng:chance(0.3)
		if good then
			s:say("b", "...It's quite good, actually. Do another one.", "laugh", "laugh")
			s:rel(6)
		else
			s:by("b", {
				prickly = "I do not sound like that. Stop it.",
				dramatic = "I sound nothing like that. My voice is far lower.",
				_ = "I do not sound like that.",
			}, "anger")
			s:say("a", "You sort of do.", "sweat")
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
		s:say("a", "Hold still. I've seen this done loads of times.", "idea")
		s:n("{a} gave {b} a haircut with the kitchen scissors.")
		if ctx.rng:chance(0.5) then
			s:voice("b", "wow", "sparkle")
			s:by("a", {
				proud = "I'm a natural. Clearly.",
				cheeky = "I'm a natural. Who's next? Nobody? Okay.",
				_ = "I'm a natural. Who's next?",
			}, "sparkle", "cheer")
			s:rel(6)
		else
			s:say("b", "Why is it shorter on one side?", "question")
			s:say("a", "That's the style. It's called... the Lopsided.", "sweat")
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
		s:say("a", "Bet you can't go a whole day without a snack.", "idea", "point")
		s:by("b", {
			foodie = "A whole day? ...Fine. Easy. I've got snacks hidden.",
			cool = "Easy.",
			_ = "Easy. Watch me.",
		}, "sparkle")
		s:n("By eleven, {b} was standing very close to the bakery window.")
		if ctx.rng:chance(0.5) then
			s:say("b", "I'm only looking. Looking is allowed.", "sweat")
			s:n("{b} made it to dinner. Just.")
			s:voice("b", "brag", "sparkle", "cheer")
		else
			s:say("b", "One bun. One bun doesn't count.", "sweat")
			s:say("a", "It counts. Pay up.", "sparkle")
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
		s:say("a", "Help me get this wardrobe up the stairs?", "question")
		s:say("b", "Sure. Lift on three. One, two...", "point")
		s:n("It took an hour, two scraped knuckles and a lot of 'left, no, your left'.")
		s:by("b", {
			bold = "Done. I could do another. I won't, but I could.",
			easygoing = "I need a lie down. On the wardrobe, ideally.",
			gloomy = "My back's gone. It's fine. It was going anyway.",
			dramatic = "My arms. I'll never lift anything again.",
			_ = "Never moving house. Never. Promise me.",
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
		s:say("a", "Do you remember the day we met?", "heart")
		s:by("b", {
			cheeky = "You had your jumper on inside out. I'll never forget it.",
			shy = "I was too nervous to say hello. You said it first.",
			proud = "You were very impressed by me. I remember that clearly.",
			cool = "You asked to borrow a pen. Never gave it back.",
			prickly = "You trod on my foot. Then said sorry six times.",
			bookish = "Tuesday. Raining. You were reading over my shoulder.",
			nervous = "You said hi and I said thanks. I still think about that.",
			_ = "You asked me where the bakery was. We were standing in front of it.",
		}, "music")
		s:say("a", "Feels like ages ago. It wasn't, really, was it?", "heart")
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
		s:say("a", "Everyone squeeze in. {b}, you're blinking. Again. Okay. Cheese.", "sparkle", "point")
		s:n("Click. It came out lovely. Even the gull in the corner.")
		s:choice("Could I have a copy?", function(c)
			c:say("a", "Course, {player}. You're in it. That's your elbow.", "heart", "cheer")
			c:keep("keep_photo", "a")
			c:rel(5)
			c:all(2)
		end)
		s:choice("Pin it up in town", function(c)
			c:say("a", "Good idea. Everyone can see it.", "heart")
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
		s:n("Neither of them moves. The biscuit waits.")
		s:choice("Give it to {a}", function(c)
			c:voice("a", "thanks", "heart")
			c:by("b", {
				proud = "I didn't want it anyway.",
				shy = "That's okay. Really. It's fine.",
				bold = "Fine. Next one's mine.",
				foodie = "I'll remember this, {player}.",
				_ = "I didn't want it anyway. I wanted it a bit.",
			}, "sad")
			c:mood("a", 2)
		end)
		s:choice("Split it", function(c)
			c:n("It broke into one big half and one small half. They both looked at the big half.")
			c:say("a", "...Have the big one.", "heart")
			c:rel(5)
		end)
		s:choice("Eat it yourself", function(c)
			c:n("You ate the biscuit. Both of them watched you do it.")
			c:say("a", "Bold, {player}.", "anger")
			c:say("b", "We'll remember this.", "anger")
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
		s:say("a", "{b}, can I borrow some coins till payday? I'll pay you back. With a bun.", "sweat")
		if K.trait(ctx, b, "kind") >= 0.5 then
			s:by("b", {
				gentle = "Of course. Don't worry about the bun. Well. Maybe the bun.",
				sunny = "Course. Here. Forget the bun.",
				bold = "Here. Pay me back whenever.",
				shy = "Um. Here. There's no rush.",
				easygoing = "Sure. Whenever's fine.",
				polite = "Of course. Please, take your time.",
				foodie = "Here. But I'm holding you to the bun.",
				_ = "Sure. Bun first, though.",
			}, "heart")
			s:rel(6)
		else
			s:by("b", {
				proud = "I'll need that in writing.",
				cheeky = "Depends. How big a bun?",
				prickly = "How many? ...Fine. Here. Don't tell anyone I'm soft.",
				gloomy = "I never get these back. Here.",
				_ = "How many coins are we talking?",
			}, "question")
			s:rel(1)
		end
		s:log("{a} borrowed some coins from {b}.")
		return s:done()
	end,
})

local EXCUSES = {
	sunny = "I stopped to say hello to everyone. Everyone. It took a while.",
	gentle = "A bird had a bad wing, so I sat with it till it flew. Sorry.",
	bold = "I took a shortcut. Over a fence. Then another fence.",
	dreamy = "I was early, I think... to a different day.",
	easygoing = "I set off on time. I walked very slowly.",
	proud = "I'm not late. Everyone else is early.",
	shy = "I was outside for ten minutes. I didn't want to knock.",
	cheeky = "I was hiding behind you the whole time. Kidding. I slept in.",
	cool = "Overslept.",
	prickly = "Don't. I know. The bus.",
	dramatic = "You won't believe the morning I've had. A goose. A puddle. Don't ask.",
	bookish = "I started a chapter on the step. Then the next one.",
	gloomy = "Lost a shoe. Found it. Lost the other one.",
	polite = "I'm so sorry. I've no excuse. Let me buy you a tea.",
	foodie = "The bakery had a queue. I couldn't just walk past a queue.",
	nervous = "I went back to check the door. Three times. Sorry. Sorry.",
}

event({
	id = "late",
	when = "day",
	weight = W({ base = 0.15, traits = { focus = -0.3 } }),
	scene = function(ctx, a, b)
		local s = K.scene(ctx, "Running late")
		s:n("{b} waited by the fountain for half an hour before {a} turned up.")
		s:by("b", {
			cool = "...",
			prickly = "Half an hour. Half.",
			nervous = "You're here. I thought something happened. Where were you?",
			_ = "Where were you?",
		}, "anger")
		s:say("a", EXCUSES[K.pers(ctx, a)] or "Sorry. Long story.", "sweat")
		s:by("b", {
			gentle = "Well, you're here now.",
			proud = "Unacceptable. Buy me a bun.",
			easygoing = "Eh. I sat down. It was nice.",
			gloomy = "It's fine. I'm used to waiting.",
			_ = "Fine. You're buying.",
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
		s:say("b", "Password?", "question")
		s:by("a", {
			cheeky = "Open up or I'm taking a cushion.",
			dreamy = "Moonbeam pudding.",
			proud = "I don't need a password. I built the west wall.",
			foodie = "Crumpets.",
			cool = "Let me in.",
			_ = "Biscuits.",
		}, "sparkle")
		s:say("b", "Correct. Come in. Mind the lamp.", "heart")
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
	"footsteps on the pier at midnight, with nobody there",
}

event({
	id = "ghoststory",
	when = "night",
	weight = W({ base = 0.18, traits = { mischief = 0.3 } }),
	scene = function(ctx, a, b)
		local s = K.scene(ctx, "A ghost story"):with({ story = ctx.rng:pick(GHOSTS) })
		s:say("a", "Want to hear a scary one? It's about {story}.", "idea")
		s:n("{a} told it slowly, in a low voice, holding a lantern under their chin.")
		s:say("a", "...and the last thing anyone heard was... boo.", "anger", "point")
		s:voice("b", "scared", "sweat")
		s:by("a", {
			gentle = "Oh, sorry. It's only a story. Here. Hold my hand.",
			cheeky = "Hehehe. Got you.",
			dramatic = "And that's a true story. Mostly.",
			_ = "Too scary? Want another?",
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
		s:n("A crack of thunder. {a} jumped a foot in the air.")
		s:voice("a", "scared", "sweat")
		s:by("b", {
			bold = "It's just noise. Stand by me. I'll shout back at it.",
			gentle = "Come here. We'll count between the flashes together.",
			cheeky = "It's the sky moving furniture. That's all.",
			shy = "I'm scared too. Can we be scared together?",
			sunny = "It's okay. I've got you. It's only noise. It can't get in.",
			dreamy = "Count with me. One... two... three. See? It's moving away.",
			proud = "Thunder doesn't bother me. Stand next to me if you like.",
			easygoing = "Eh. It's just loud. Sit with me.",
			cool = "It's far off. You're fine.",
			prickly = "It's thunder. It can't hurt you. ...Sit here, then.",
			dramatic = "The sky's having a tantrum. Let it. We'll stay in.",
			bookish = "Count after the flash. Every three seconds is about a kilometre. It's miles away.",
			gloomy = "Yeah. I hate it too. Sit with me.",
			polite = "Would you like to stay here till it passes? Please do.",
			foodie = "Thunder means hot chocolate. House rule.",
			nervous = "I know. I know. Me too. Let's go inside. Now. Please.",
			_ = "It's all right. It'll pass. They always do.",
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
		s:n("It's pouring, and {b} forgot an umbrella. {a} holds theirs out.")
		s:by("a", {
			cool = "Get under.",
			prickly = "Get under. You'll catch cold and I'll have to hear about it.",
			_ = "There's room for two. Just about.",
		}, "heart")
		s:by("b", {
			shy = "Oh. Th-thank you. I'll stand very small.",
			proud = "I was enjoying the rain. But fine.",
			polite = "That's very kind. Thank you.",
			gloomy = "I always forget it. Thanks.",
			_ = "You're a lifesaver.",
		}, "heart")
		s:n("They walked home slowly and both got one wet shoulder.")
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
		s:n("{a} and {b} have never really talked before. Then they found out they share {thing}.")
		s:by("a", {
			sunny = "No way! You too? You tooo?",
			cool = "Huh. Same.",
			nervous = "Wait. Really? You're not just saying it?",
			_ = "No way. You too?",
		}, "sparkle")
		s:voice("b", "excited", "sparkle", "cheer")
		s:rel(14)
		s:memo("a", "{b} and I have {thing}. Who knew?")
		s:log("{a} and {b} found out they have {thing}.")
		return s:done()
	end,
})

event({
	id = "sorrycard",
	when = "any",
	weight = W({ base = 0.6, quarrel = true, traits = { kind = 0.8 } }),
	scene = function(ctx, a, b)
		local s = K.scene(ctx, "A sorry card")
		s:n("{a} has made a card for {b}. It has a drawing of a sad cat on the front.")
		s:by("a", {
			shy = "{player}... could you give this to {b}? I can't. I'll go all red.",
			proud = "Give this to {b}, would you, {player}? I'm busy. Very busy.",
			bold = "Give this to {b}? I'd do it, but I'd say it wrong.",
			prickly = "Take this to {b}. Don't read it. ...You can read it.",
			nervous = "{player}, could you give this to {b}? What if they rip it up?",
			_ = "{player}, could you give this to {b}? I don't think I can do it myself.",
		}, "sweat")
		s:choice("Take it to {b}", function(c)
			c:n("{b} opened it. Inside it said: 'I was silly. I miss you. Here is a cat.'")
			c:by("b", {
				proud = "...Hmph. It's a very good cat.",
				shy = "Oh. Oh, that's... tell them yes. Tell them I miss them too.",
				bold = "Tell them to come here and say it. ...Tell them it's okay.",
				cool = "...Tell them it's fine.",
				gloomy = "They drew a cat. For me. ...Tell them I'm sorry too.",
				_ = "Tell them I'm sorry too.",
			}, "heart")
			c:fx({ t = "makeup", a = "a", b = "b" })
			c:rel(10)
			c:mood("a", 5)
		end)
		s:choice("Say it in person", function(c)
			c:by("a", {
				shy = "You're right. I'll go. I'll go red, but I'll go.",
				proud = "Fine. In person. I'll be very dignified about it.",
				nervous = "In person? Okay. Okay. Walk me to the door?",
				_ = "You're right. I'll go and say it.",
			}, "sweat")
			if ctx.rng:chance(0.6) then
				c:say("b", "...Okay. I'm sorry too.", "heart")
				c:fx({ t = "makeup", a = "a", b = "b" })
				c:rel(8)
			else
				c:say("b", "Not yet. Give me a day.", "anger")
				c:mood("a", -3)
			end
		end)
		s:log("{a} made {b} a sorry card.")
		return s:done()
	end,
})

local SECRETS = {
	"a secret",
	"a surprise for someone",
	"who ate the last of the jam",
	"what they got everyone for their birthdays",
}

event({
	id = "fallout",
	when = "day",
	weight = W({ base = 0.08, rel = 30, traits = { temper = 0.3 } }),
	scene = function(ctx, a, b)
		local s = K.scene(ctx, "Falling out"):with({ secret = ctx.rng:pick(SECRETS) })
		s:n("{b} told {a} {secret}. Then {a} told half the town.")
		s:by("b", {
			cool = "That was a secret.",
			dramatic = "That was a secret. A sacred one.",
			_ = "That was a secret.",
		}, "anger", "point")
		s:by("a", {
			cheeky = "It slipped out. Repeatedly.",
			sunny = "I got excited. I'm so sorry.",
			nervous = "I didn't mean to. It just came out. Then it kept coming out.",
			_ = "I didn't think it was that big a deal.",
		}, "sweat")
		s:choice("Tell {a} to say sorry", function(c)
			c:voice("a", "sorry", "sad")
			c:say("b", "Fine. But I'm not telling you anything else for a week.", "anger")
			c:rel(-4)
		end)
		s:choice("Let them cool off", function(c)
			c:say("b", "I need some time.", "anger")
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
			s:by("b", {
				prickly = "You're lucky I put up with you.",
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
	"I'll have the big one. The big one. With a hat.",
	"Gerald, you can't take the bus. You're a snowman.",
	"Five more minutes, Captain.",
}

event({
	id = "sleeptalk",
	when = "night",
	weight = W({ base = 0.12 }),
	scene = function(ctx, a, b)
		local s = K.scene(ctx, "Talking in their sleep")
		s:n("{b} walked past {a}'s window late at night and heard them talking.")
		s:say("a", ctx.rng:pick(SLEEPTALK), "zzz")
		s:by("b", {
			cheeky = "I'm writing this down. All of it.",
			gentle = "Sweet dreams, whatever they are.",
			bookish = "Fascinating. I'm noting the time.",
			_ = "I'm asking about this tomorrow.",
		}, "laugh")
		s:memo("b", "{a} talks in their sleep. I'm not saying what about.")
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
		s:say("a", "I had the oddest dream. I dreamed {dream}.", "zzz")
		s:say("b", "...So did I.", "question")
		s:n("They looked at each other for a long moment.")
		s:by("b", {
			dreamy = "We're connected. It's obvious.",
			bold = "Okay, that's weird. I'm not scared. It's weird.",
			bookish = "There must be a reason. We both had cheese, didn't we?",
			gloomy = "That's not a good sign. Is it?",
			dramatic = "Fate. That's what this is.",
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
		s:n("{a} and {b} on one end of the rope, {c} on the other.")
		s:by("c", {
			bold = "Two against one? Bring it.",
			shy = "Two against one? Um. Okay.",
			proud = "Two against one? That seems fair. For you.",
			cool = "Fine.",
			gloomy = "Two against one. Course.",
			dramatic = "Two against one. They'll sing songs about this.",
			_ = "Two against one? Fine. I've been eating my greens.",
		}, "sparkle")
		if K.trait(ctx, c, "brave") > 0.65 then
			s:n("{c} dug in their heels and pulled them both over the line.")
			s:voice("c", "brag", "sparkle", "cheer")
		else
			s:n("{c} lasted four seconds and then went face first into the grass.")
			s:by("c", {
				proud = "I let you win. That was kindness.",
				shy = "Ow. Okay. You win.",
				prickly = "Don't. Say. Anything.",
				_ = "I'm in the grass. You win.",
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
		s:n("{a} on guitar, {b} singing, {c} banging two pans together. It's a band.")
		s:say("b", "We need a name. A good one.", "question")
		s:say("b", "{player}, you pick.", "question")
		for i = 1, 3 do
			local name = names[i]
			s:choice(name, function(ch)
				ch:with({ band = name })
				ch:say("a", "{band}. That's us. That's who we are now.", "music", "cheer")
				ch:say("c", "First gig's tonight. In my kitchen.", "sparkle")
				ch:relx("a", "b", 5)
				ch:relx("a", "c", 5)
				ch:relx("b", "c", 5)
				ch:memo("c", "I'm in a band called {band}. I play the pans.")
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
		s:n("{a} and {b} are whispering behind the hedge. They're planning something for {c}.")
		s:say("a", "Balloons, cake, everyone hides, then boo. I mean, surprise.", "idea")
		s:say("c", "What are you two doing back there?", "question")
		s:say("b", "Nothing. Looking at the hedge. Nice hedge.", "sweat")
		s:choice("Help them hide it", function(ch)
			ch:n("You walked {c} the long way round. When they got back, the street was full of balloons.")
			ch:prop("balloons", "a")
			ch:voice("c", "excited", "heart", "cheer")
			ch:relx("a", "c", 8)
			ch:relx("b", "c", 8)
			ch:mood("c", 8)
		end)
		s:choice("Let {c} find out", function(ch)
			ch:say("c", "Is that a cake? Behind the hedge? For me?", "sparkle")
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
		s:say("a", "{c}, you decide. {q}", "question", "point")
		s:say("a", d.yes, "anger")
		s:say("b", d.no, "anger")
		s:by("c", {
			gentle = "You're both a little bit right. Now hug.",
			proud = "You're both wrong. I'm right. Next question.",
			easygoing = "Does it matter? Let's get lunch.",
			cheeky = "I'm not saying until someone buys me a bun.",
			cool = "{b}.",
			prickly = "Why am I always the one? ...{a}. Fine. {a}.",
			dramatic = "I've heard both sides. I need a day to think.",
			bookish = "Actually, it depends what you mean by it. Let's define our terms.",
			gloomy = "Neither of you. Nobody's ever right.",
			polite = "I really couldn't say. You both make good points.",
			foodie = "Can we talk about this over lunch?",
			nervous = "Don't make me pick. Please don't make me pick.",
			_ = "I'm not getting involved. ...I'm getting involved. It's {b}.",
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
-- script: two lines, then after the answer a heart line, a line, and the narrator).
event({
	id = "thanks",
	when = "day",
	weight = W({ base = 0.3, rel = 55 }),
	scene = function(ctx, a, b)
		local s = K.scene(ctx, "Saying thank you")
		s:n("{a} has been pacing up and down the roof for an hour.")
		s:by("a", {
			nervous = "{player}... {b} looked after me all week when I was ill. I never said thank you. Should I? Now?",
			prickly = "{player}. {b} looked after me all week when I was ill. I never said thanks. Should I? Don't answer that.",
			_ = "{player}. {b} looked after me all week when I was ill. I never said thank you properly. Should I?",
		}, "sweat")
		s:choice("Go and say it", function(ch)
			ch:by("a", {
				proud = "{b}. About last week. The soup, sitting up with me. Thank you. There. I said it.",
				shy = "{b}? Um. Thank you. For the soup. And for staying. I should have said.",
				bold = "{b}. Thanks. For the soup and that. I mean it.",
				prickly = "{b}. The soup. The sitting up. ...Thanks. Don't make it a thing.",
				dramatic = "{b}. Last week, you saved me. With soup. I'll never forget it.",
				gloomy = "{b}. You didn't have to look after me. Nobody does. Thanks.",
				polite = "{b}, thank you so much for looking after me last week. It meant a great deal.",
				nervous = "{b}? Thank you. For the soup. And staying. Sorry it took so long to say.",
				_ = "{b}, I never said thank you. For the soup, and sitting with me. It meant a lot.",
			}, "heart")
			ch:by("b", {
				shy = "Oh. You didn't have to say anything. I'm glad you did.",
				proud = "It was very good soup. But thank you. Really.",
				cheeky = "I know. I've been waiting weeks for this. Come here.",
				cool = "Anytime.",
				prickly = "...Took you long enough. Come here.",
				foodie = "It was my best soup. You deserved it. Thank you for saying.",
				_ = "Oh. You didn't have to. I'm glad you did, though.",
			}, "heart", "cheer")
			ch:n("They stayed up there until the sun went down.")
			ch:rel(8)
			ch:mood("a", 10)
			ch:mood("b", 10)
			ch:hearts("a", 2)
		end)
		s:choice("Wait for a better moment", function(ch)
			ch:by("a", {
				shy = "Tomorrow. I'll do it tomorrow. I think.",
				proud = "Tomorrow. When the moment's right. I'll know.",
				nervous = "Tomorrow. Yes. That gives me time to practise.",
				_ = "You're right. Tomorrow, then.",
			}, "sweat")
			ch:mood("a", -2)
		end)
		s:default(2)
		s:log("{a} thanked {b} properly at last.")
		return s:done()
	end,
})

-- Best friends keep a day for each other now and then. The cutscene goes where the plan in the
-- first line says (Data/Cutscenes: three lines).
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
			nervous = "Same time next month? You'll remember? I'll remind you.",
			dramatic = "Same time next month. It's tradition now.",
			_ = "Same time next month?",
		}, "heart")
		s:by("a", {
			proud = "It's already in my diary. In pen.",
			cheeky = "Same time tomorrow, more like.",
			shy = "I'd like that a lot.",
			cool = "Obviously.",
			prickly = "Obviously. Don't be late.",
			foodie = "Only if we get the ice cream again.",
			_ = "Obviously.",
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
		s:say("a", "Wait. You're into {hobby} too?", "question", "point")
		s:by("b", {
			proud = "I'm quite good, actually. You can watch.",
			shy = "I didn't think anyone else was. I never said.",
			bold = "Every evening. Want to see who's better?",
			cool = "Yeah. For years.",
			bookish = "For years. I've got notes. Want to see my notes?",
			nervous = "I am. Is that okay? I'm not very good.",
			_ = "Since I was little. Why didn't you say?",
		}, "sparkle")
		s:n("They spent the rest of the afternoon at it, comparing notes and getting in each other's way.")
		s:rel(10)
		s:mood("a", 4)
		s:mood("b", 4)
		s:memo("a", "Turns out {b} is into {hobby} too. We do it together on Thursdays now.")
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
		s:by("a", {
			cheeky = "You always want the toasted one. You're very easy to read.",
			gentle = "You had that look. The toasted one look.",
			proud = "I notice things. It's a gift.",
			cool = "You always do.",
			bookish = "Thirty one visits. Thirty one toasted ones. I keep track.",
			foodie = "It's the best thing on the menu. You have taste.",
			_ = "You've had it every time for a year.",
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
		s:say("a", "One each. Now it's official.", "heart")
		s:by("b", {
			proud = "I'll wear it every day. On the good wrist.",
			shy = "I've never had one before.",
			bold = "Best friends. For life. No take backs!",
			cool = "...Thanks. I'm keeping it on.",
			prickly = "It's a bit itchy. I'm never taking it off.",
			dramatic = "I'll wear it until the string gives out. Then I'll keep the string.",
			gloomy = "Nobody's ever made me one. ...I like it.",
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
		s:by("a", {
			nervous = "One piece is missing. One. I've checked the box four times.",
			gloomy = "One piece missing. Of course. Right in the middle.",
			dramatic = "A piece is missing. The very last one. I can't bear it.",
			bookish = "Nine hundred and ninety nine. I counted twice. One's missing.",
			_ = "One piece is missing. The last one.",
		}, "sweat")
		s:by("b", {
			cool = "Check your sleeve.",
			cheeky = "Hehe. Wasn't me.",
			_ = "It has to be somewhere.",
		}, "question")
		s:n("It was in {b}'s sock.")
		s:by("b", {
			proud = "I was keeping it safe.",
			prickly = "Don't look at me like that. Socks are pockets for feet.",
			nervous = "How? How did it get there? Is my other sock okay?",
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
		s:by("a", {
			bookish = "Geranium. Keep it warm. I've written it on the pot.",
			nervous = "It's a geranium. Don't let it get cold. Or too hot. Or wet. Or dry.",
			cool = "Geranium. Keep it warm.",
			_ = "Geranium. Don't let it get cold.",
		}, "idea")
		s:by("b", {
			cheeky = "Mint. It'll take over your whole garden. Hehe. Good luck.",
			gloomy = "Mint. It'll take over. Everything does.",
			foodie = "Mint. For tea, for peas, for everything.",
			polite = "And this is mint, with my thanks. It does spread, I'm afraid.",
			_ = "Mint. It spreads. You've been warned.",
		}, "music")
		s:rel(6)
		s:memo("b", "{a} gave me a geranium. I've named it. I'm not telling you the name, {player}.")
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
		s:n("{a} and {b} are painting the fence between their gardens. One side each.")
		s:say("a", "Mine's white. Like a fence should be.", "point")
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
		s:by("b", {
			dramatic = "Mine's lilac. It's a statement.",
			cheeky = "Mine's spots. Hehe.",
			gloomy = "Mine's grey. It goes with the sky.",
			_ = "Mine's {colour}. It's nicer.",
		}, "sparkle")
		s:by("a", {
			prickly = "It's a fence. It doesn't need a personality.",
			nervous = "It doesn't match. Does it have to match? I think it has to match.",
			_ = "It doesn't match. It has to match.",
		}, "anger")
		s:say("b", "{player}. You choose. The whole fence goes one colour.", "question")
		s:choice("Paint it all white", function(c)
			c:by("a", {
				proud = "White. Correct. I'll get the big brush.",
				bookish = "White. It reflects the most light, you know. Practical.",
				prickly = "Good. Sensible. ...Thanks, {player}.",
				nervous = "White? Really? Okay. Phew. White.",
				_ = "White. Thank you, {player}.",
			}, "sparkle", "cheer")
			c:by("b", {
				gloomy = "White. Fine. Plain. Like everything.",
				dramatic = "White. The colour of giving up. Fine.",
				_ = "White. Fine. Boring, but fine.",
			}, "sweat")
			c:rel(2)
			c:mood("a", 3)
			c:mood("b", -1)
		end)
		s:choice("Paint it all {colour}", function(c)
			c:by("b", {
				dramatic = "The whole fence in {colour}. People will come from miles.",
				cheeky = "Spots everywhere. Hehe. Best fence in town.",
				sunny = "Yes! The whole thing. I'll get more paint.",
				_ = "The whole fence in {colour}. Oh, it'll look lovely.",
			}, "sparkle", "cheer")
			c:by("a", {
				gloomy = "Fine. A party fence. Great.",
				_ = "Fine. Loud fence. Everybody look.",
			}, "sweat")
			c:rel(2)
			c:mood("b", 3)
			c:mood("a", -1)
		end)
		s:choice("Leave it half and half", function(c)
			c:n("The fence stayed half and half. People stop to look at it.")
			c:say("a", "It's growing on me.", "heart")
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
		s:n("{a} has lined up three cups of tea and won't let {b} leave till they've tried them all.")
		s:by("a", {
			foodie = "Sip. Swirl. Think. Then tell me.",
			bookish = "These are from three different hills. You can taste the difference. Supposedly.",
			proud = "I blended one of these myself. Guess which. It's the best one.",
			_ = "Which one's best? Be honest.",
		}, "question")
		s:by("b", {
			cool = "They all taste like tea.",
			gloomy = "They all taste like tea. Sorry.",
			polite = "They're all lovely. Thank you for going to the trouble.",
			dramatic = "The second. It tastes like a rainy afternoon in a good book.",
			foodie = "Second one. Smoky. A bit of honey at the end. Am I right?",
			_ = "The middle one? It's the middle one.",
		}, "sparkle")
		s:by("a", {
			foodie = "Yes. Yes. Finally someone gets it.",
			proud = "Correct. That's mine. You've got taste.",
			_ = "The middle one. Good. I'll make that one again.",
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
		s:n("{a} couldn't sleep, so they went for a walk. {b} was already sitting on the fountain wall.")
		s:say("a", "You too?", "question")
		s:by("b", {
			gloomy = "Every night. It's fine. The fountain's good company.",
			dreamy = "The moon kept knocking on my window.",
			nervous = "I kept thinking I'd left the gate open. I checked. Twice. It was shut.",
			foodie = "I got up for toast. Then I just... kept going.",
			easygoing = "I fell asleep at six. Now I'm awake. Fair trade, really.",
			cool = "Yeah.",
			_ = "Yeah. Couldn't settle.",
		}, "zzz")
		s:n("They sat and listened to the water until the sky went light.")
		s:by("a", {
			prickly = "Same time tomorrow? I hope not. ...Maybe.",
			_ = "Same time tomorrow? I hope not.",
		}, "laugh", "laugh")
		s:rel(7)
		s:log("{a} and {b} met at the fountain in the middle of the night.")
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
		s:say("a", "Rock, paper, scissors. Best of one.", "idea", "point")
		s:by("b", {
			proud = "Best of three. I always win best of three.",
			nervous = "Okay. Wait. What beats what again?",
			cool = "Go.",
			_ = "Fine. On three.",
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
		local w = ctx.job(a)
		local s = K.scene(ctx, "The walk home"):with({ job = if w then w.def.name:lower() else "work" })
		s:n("{a} finished at the {job} and found {b} waiting at the end of the road.")
		s:by("a", {
			sunny = "You waited! Aww.",
			prickly = "You didn't have to wait. ...Thanks for waiting.",
			gloomy = "You waited? For me? Huh.",
			cool = "Hey. Walk?",
			nervous = "You waited? How long? Sorry. Thank you. Sorry.",
			_ = "Oh. You waited.",
		}, "heart")
		s:by("b", {
			foodie = "The bakery's on the way. But also you.",
			bookish = "I was reading. I lost track. Then you came out.",
			cheeky = "I was just standing here. Total coincidence.",
			_ = "Thought we could walk back together.",
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
		s:by("a", {
			sunny = "{player}! Close your eyes. Okay. Open them ^^",
			shy = "Um. {player}. We made you something. You don't have to like it.",
			proud = "{player}. We made you something. It's very good.",
			cheeky = "{player}. Guess what's behind my back. Wrong. Guess again.",
			gloomy = "We made you something. It's probably not your thing.",
			dramatic = "{player}. A gift. From both of us. With feeling.",
			polite = "{player}, we'd like you to have this. It's from both of us.",
			_ = "{player}. We made you something.",
		}, "sparkle")
		s:by("b", {
			foodie = "A cushion. I wanted to stitch a cake on it. I was outvoted.",
			nervous = "It's a cushion. Is it okay? The stitching's a bit wonky on one side.",
			bookish = "A cushion. Forty rows of stitches. I counted.",
			_ = "A cushion. For your house. {a} did the stitching.",
		}, "heart")
		s:choice("I love it", function(c)
			c:voice("a", "excited", "sparkle", "cheer")
			c:voice("b", "happy", "heart")
			c:keep("keep_cushion", "a")
			c:rel(6)
			c:mood("a", 4)
			c:mood("b", 4)
		end)
		s:choice("Where's the wonky bit?", function(c)
			c:say("b", "Here. And here. Don't look too close.", "sweat")
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
		s:say("a", "Four. Did you see that? Four skips.", "sparkle", "point")
		s:by("b", {
			bold = "Watch this. Seven.",
			nervous = "Mine sank. Straight down. Is that allowed?",
			bookish = "It's all in the wrist. And the angle. About twenty degrees.",
			dreamy = "Mine went plop... I liked the plop.",
			_ = "Watch. ...Two. It counts.",
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
		s:say("a", "Eleven gulls, three sparrows and... what's that one?", "question", "point")
		s:by("b", {
			bookish = "A wagtail. See how it bobs? Wagtail.",
			gloomy = "A gull. It's always a gull.",
			dramatic = "That's the rarest bird I've ever seen. Write it down. In capitals.",
			cool = "Pigeon.",
			cheeky = "That's {player} in a hat. Hehe.",
			_ = "No idea. Write 'small brown one'.",
		}, "idea")
		s:by("a", {
			bookish = "I'll draw it. We'll look it up later.",
			_ = "I'm putting a question mark.",
		}, "sweat")
		s:rel(5)
		s:memo("a", "We counted forty birds on the hill. One was a mystery.")
		s:log("{a} and {b} counted birds on the hill.")
		return s:done()
	end,
})

return list
