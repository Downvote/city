--!nonstrict
-- Conversations you can watch, longer than a passing word: a long chat over two topics, gossip
-- about a third villager (who may be listening), dreams compared, a squabble that grows and then
-- fizzles out, a silly debate you settle, catching up on the day, moaning about the weather,
-- making plans, a story made up a line each, and the small talk of a town: who waves at you more,
-- a hedgehog on the way home, a tip passed on, sugar borrowed, a sunset, a bad day at work, the
-- wrong coat, a porch in the rain, compliments swapped badly; and the newer ones, a plan made in
-- three voices at once and a note passed on the wrong way round. Built from Data/Events/Chatter's
-- parts, so they come out different each time, and said the way friends text: a burst of short
-- messages, each in their own voice, and you by your name ({player}) when they turn to you.

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
			sunny = "Oh. Oh. That reminds me.",
			dreamy = "Hm.|That makes me think of something.",
			bookish = "Actually, that reminds me of something.",
			dramatic = "Speaking of which.|Prepare yourself.",
			nervous = "Can I say something random?|Sorry.",
			cheeky = "ok unrelated",
			easygoing = "Oh. Also.|Heh. I forgot what. No, got it.",
			_ = "Oh. Also.",
		}, "idea")
		Chatter.pick(s, "b", t2.open, "idea", "point")
		if Chatter.agrees(ctx, b, a) then
			Chatter.pick(s, "a", t2.yes, "music")
			Chatter.pick(s, "b", t2.more, "sparkle")
		else
			Chatter.pick(s, "a", t2.no, "question")
			Chatter.pick(s, "b", t2.back, "sweat")
		end
		s:n("An hour went by. Neither of them noticed.")
		s:rel(d1 + 4)
		s:with({ one = t1.about, two = t2.about })
		s:log("{a} and {b} talked for an hour about {one}, and then {two}.")
		return s:done()
	end,
})

-- What there is to say about somebody, from what they're like and what they've been up to.
local DOWN = "{c} seems a bit down lately.|Have you noticed?"

local function gossipAbout(ctx, c): { string }
	local v = ctx.v(c)
	local out = {}
	local byPers = {
		sunny = "{c} stopped to chat with every stall at the market.|Every one.|Took all morning.",
		gentle = "{c} knitted the bakery cat a hat.|And the cat wears it.",
		bold = "{c} raced a gull down the pier.|The gull won.",
		dreamy = "{c} sat by the fountain for two hours yesterday.|Just watching the water.",
		easygoing = "{c} fell asleep at the bus stop.|Standing up.",
		proud = "{c} carries a little mirror now.|Top pocket.",
		shy = "{c} waved at me.|Then hid behind a bin.",
		cheeky = "{c} swapped all the house numbers on our street.|I live at 4 now.",
		cool = "{c} fixed the bench by the gate.|Told nobody.",
		prickly = "{c} told the gulls off this morning.|The gulls listened.",
		dramatic = "{c} stood on a chair at the café.|To announce lunch.",
		bookish = "{c} has read every book in the library.|Some twice.",
		gloomy = "{c} took an umbrella out on a sunny day.|Then it rained. Only on them.",
		polite = "{c} walked into a lamppost.|Then said sorry to it.",
		foodie = "{c} has been scoring every bun at the bakery.|Out of ten. In a notebook.",
		nervous = "{c} checked their door was locked four times this morning.|I counted.",
	}
	table.insert(out, byPers[v.pers] or "{c} has been very {c} lately.")
	local hobby = Sayings.hobby(v.hobby)
	if hobby then
		table.insert(out, "{c} is really into " .. hobby.name .. " at the moment.|Every evening.")
	end
	local job = ctx.job(c)
	if job then
		table.insert(out, "{c} says the " .. job.def.name:lower() .. " is the best job in town.|Every day.")
	end
	if (v.mood or 50) < 35 then
		table.insert(out, DOWN)
	end
	for _, other in ctx.present do
		if other ~= c and ctx.rel(c, other) >= K.BestFriends then
			table.insert(out, "{c} has a best friend now.|Matching scarves and everything.")
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
			sunny = "{b}. {b}.|Have you seen {c} lately?",
			gentle = "{b}, have you noticed anything about {c}?",
			bold = "{b}. You seen what {c}'s been up to?",
			shy = "Um. {b}?|Have you noticed {c} lately?",
			proud = "{b}. A word. About {c}.",
			cheeky = "psst {b}|it's about {c}|hehe",
			cool = "{b}. About {c}.",
			prickly = "I don't gossip.|But {c}.",
			dramatic = "{b}. Sit down.|This is about {c}.",
			bookish = "{b}, I've noticed something about {c}.|Just an observation.",
			gloomy = "{b}. Seen {c} lately?",
			polite = "{b}, may I ask you about {c}?|Nothing unkind.",
			foodie = "{b}. Over here. Bring the crisps.|It's about {c}.",
			nervous = "{b}, can I tell you something?|About {c}?|You won't say I said?",
			_ = "{b}, have you noticed {c} lately?",
		}, "question")
		say(s, "a", said, "idea", "point")
		if kind then
			burst(s, "b", {
				sunny = "Oh no. Really?|I'll find them later.",
				gentle = "Oh, dear.|I'll take them some soup tonight.",
				bold = "Who upset them?|Tell me who.",
				cool = "I'll check on them.",
				prickly = "Hm.|I'll go round later. Don't read into it.",
				polite = "Oh no. We should see if they need anything.",
				foodie = "I'll bake something.|Nobody stays sad near a warm bun.",
				nervous = "Is it something I did?|What if it's something I did?",
				_ = "Now you mention it, yes.|We should check on them.",
			}, "sad")
		elseif ctx.rel(b, c) >= 30 then
			burst(s, "b", {
				sunny = "That's so {c}.|I love that.",
				gentle = "Oh, be nice. {c}'s lovely.",
				bold = "Good for {c}.",
				dreamy = "I think I'd like to do that too.",
				easygoing = "Heh. Fair enough.",
				proud = "I'd never.|But it's very {c}.",
				shy = "Oh.|I think that's nice, actually.",
				cheeky = "hahaha|that's very {c}",
				cool = "Sounds like {c}.",
				dramatic = "That is the most {c} thing I've ever heard.",
				bookish = "That fits. {c} does things properly.",
				gloomy = "Huh. Good for them.|Someone's having fun.",
				polite = "How lovely. Good for {c}.",
				_ = "That's {c} being {c}.|I like that about them.",
			}, "heart")
		else
			burst(s, "b", {
				bold = "So?",
				dreamy = "Hm.|I wonder why.",
				easygoing = "Huh. Okay.",
				proud = "I've always said {c} was odd.",
				shy = "Oh. Um.|Okay.",
				cheeky = "more|tell me everything",
				cool = "Okay.",
				prickly = "Not my business.|...What else?",
				dramatic = "No. Really?|Go on.",
				gloomy = "Figures.",
				_ = "Really? Huh.",
			}, "question")
		end
		if ctx.rng:chance(0.35) then
			s:n("Then {c} came round the corner.")
			burst(s, "c", {
				bold = "Talking about me?|Say it to my face.",
				proud = "Talking about me? Naturally.",
				shy = "Um.|Were you talking about me?",
				cool = "Hm?",
				prickly = "I can hear you, you know.",
				dramatic = "My ears are burning.|Who's talking about me?",
				nervous = "Wait. Was that about me?|Was it bad?",
				cheeky = "talking about me?|good",
				_ = "Talking about me?",
			}, "question")
			if kind then
				say(s, "a", "We were worried about you.|That's all.", "heart")
				s:voice("c", "thanks", "heart")
				s:relx("a", "c", 6)
				s:relx("b", "c", 4)
			else
				burst(s, "a", {
					cheeky = "lampposts|we were talking about lampposts|fascinating things",
					proud = "We were, yes.|Mostly nice things.",
					shy = "N-no. Nothing.|Sorry.",
					polite = "We were, and I apologise.|It was nothing unkind.",
					cool = "Yes.",
					_ = "No.|We were talking about... lampposts.",
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
			dreamy = "I had a dream.|I dreamed {one}.|It's still a bit here.",
			nervous = "I had the worst dream.|Well, the oddest.|I dreamed {one}.",
			cheeky = "ok so last night|I dreamed {one}",
			_ = "Strangest dream last night.|I dreamed {one}.",
		}, "zzz")
		burst(s, "b", {
			proud = "Mine was better.|I dreamed {two}.",
			shy = "Um. I dreamed {two}.|Is that weird?",
			dreamy = "I've been there.|Last week I dreamed {two}.",
			sunny = "Mine was weirder.|I dreamed {two}.",
			easygoing = "Heh. I dreamed {two}.|Then I slept in.",
			cool = "I dreamed {two}.|Woke up hungry.",
			dramatic = "Mine was a whole saga.|I dreamed {two}.",
			gloomy = "I dreamed {two}.|Then my alarm went.",
			bookish = "I dreamed {two}.|I wrote it down. Here.",
			foodie = "I dreamed {two}.|There was gravy. Everywhere.",
			nervous = "I dreamed {two}.|Woke up and checked the door.",
			_ = "That's nothing.|I dreamed {two}.",
		}, "zzz")
		burst(s, "a", {
			dreamy = "Our dreams know each other.",
			bold = "Okay. Yours wins.|This time.",
			cheeky = "what did you eat before bed|I want some",
			bookish = "Dreams are your brain tidying up.|Yours needs a big tidy.",
			gloomy = "Mine never mean anything.|Yours might.",
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
	"A duck walked between them. They both watched it go.",
	"A gull landed on the bench and took half of {a}'s sandwich.",
	"The bell on the hall rang and they both lost their place.",
	"Someone went past carrying a very large cake.",
}

event({
	id = "spat",
	when = "day",
	weight = W({ base = 0.2, quarrel = "any", traits = { temper = 0.6 } }),
	scene = function(ctx, a, b)
		local s = K.scene(ctx, "A squabble"):with({ thing = ctx.rng:pick(Chatter.Spats) })
		s:n("{a} and {b} started arguing about {thing}.")
		burst(s, "a", {
			dramatic = "It was you.|The whole town knows it was you.",
			prickly = "It was you. Obviously.",
			nervous = "It was you.|Wasn't it?|It wasn't me. I checked.",
			cheeky = "it was you|everyone saw",
			_ = "It was you.|Everyone knows.",
		}, "anger", "point")
		burst(s, "b", {
			cool = "No.",
			gloomy = "Course it's my fault.|Everything is.",
			bookish = "If you go through it in order, it was you.",
			proud = "Me? Never.",
			_ = "Me?|It was obviously you.",
		}, "anger")
		s:voice("a", "angry", "anger")
		s:voice("b", "angry", "anger")
		if K.isPers(ctx, a, "proud", "bold", "prickly") or K.isPers(ctx, b, "proud", "bold", "prickly") then
			s:say("a", "I'm not saying another word.", "anger")
			s:say("b", "Good.", "anger")
			s:say("a", "...It was you, though.", "anger")
		end
		s:n(ctx.rng:pick(FIZZLE))
		s:say("b", "...What were we arguing about?", "question")
		burst(s, "a", {
			foodie = "No idea.|Want half my bun?",
			prickly = "Doesn't matter.|Biscuit?",
			cool = "Forgot.|Tea?",
			_ = "No idea.|Biscuit?",
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
			sunny = "{player}.|Help. You decide.",
			dramatic = "{player}.|Only you can end this.",
			polite = "{player}, I'm sorry to drag you in.|What do you think?",
			nervous = "Um, {player}?|Could you say who's right? Gently?",
			cheeky = "{player}|tell them they're wrong",
			cool = "{player}. Settle it.",
			_ = "{player}. You decide.",
		}, "question")
		s:choice("{a}'s right.", function(c)
			c:voice("a", "brag", "sparkle", "cheer")
			c:voice("b", "no", "anger")
			c:mood("a", 3)
			c:mood("b", -2)
		end)
		s:choice("{b}'s right.", function(c)
			c:voice("b", "brag", "sparkle", "cheer")
			c:voice("a", "no", "anger")
			c:mood("b", 3)
			c:mood("a", -2)
		end)
		s:choice("You're both wrong.", function(c)
			c:n("{a} and {b} looked at each other, then at you.")
			say(c, "b", "Well.|Now we agree on something.|You're wrong, {player}.", "laugh", "laugh")
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
	weight = W({
		base = 0.3,
		rel = 10,
		cond = function(ctx, a, b)
			local va, vb = ctx.v(a), ctx.v(b)
			return (va.memo ~= nil) or (vb.memo ~= nil)
		end,
	}),
	scene = function(ctx, a, b)
		local s = K.scene(ctx, "Catching up")
		local va, vb = ctx.v(a), ctx.v(b)
		burst(s, "a", {
			sunny = "So? What's new?|Tell me everything.",
			cool = "What's new?",
			bookish = "So what have you been up to?|From the beginning.",
			foodie = "What's new with you?|Besides lunch.",
			gentle = "How've you been?|Really, I mean.",
			cheeky = "ok spill",
			_ = "So what's new with you?",
		}, "question")
		if vb.memo then
			s:say("b", vb.memo.text, "music")
		else
			s:voice("b", "hmm", "question")
			s:say("b", "Not much. You?", "question")
		end
		if va.memo then
			s:say("a", va.memo.text, "music")
		end
		s:voice("b", ctx.rng:pick({ "laugh", "wow", "yes" }), "music", "laugh")
		s:rel(5)
		s:log("{a} and {b} caught up on their news.")
		return s:done()
	end,
})

local MOANS = {
	rain = { "Rain again.|My socks have given up.", "It's rained so long my umbrella's gone floppy." },
	storm = { "That thunder's been going since breakfast.", "My hat blew off.|It's in the sea now." },
	snow = { "I can't feel my nose.|Is it still there?", "My door froze shut.|I came out the window." },
	clear = { "Too hot.|I'm melting.", "Not a cloud.|Not one." },
	cloudy = { "This weather can't make up its mind.", "Grey again.|Third day." },
	blossom = { "Petals everywhere.|There's one in my tea.", "I've sneezed nine times today.|Nine." },
	leaves = { "Swept my step.|It's covered again already.", "A leaf hit me in the face.|Right in the face." },
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
			sunny = "It's not that bad.|Okay. It's a bit bad.",
			proud = "Weather doesn't bother me.|Never has.",
			easygoing = "I just stay in.|Solved.",
			gentle = "Come in and have something warm.",
			cheeky = "i like it|everyone's grumpy except me",
			bold = "It's weather. You'll live.",
			shy = "Um. Yes.|It's a lot.",
			dreamy = "I like it.|Everything looks different.",
			cool = "Could be worse.",
			prickly = "Moaning won't fix it.|...It is awful, though.",
			dramatic = "The sky has it in for us!|Personally.",
			bookish = "Wettest week since spring, actually.|I keep a chart.",
			gloomy = "It'll be worse tomorrow.",
			polite = "It is trying, isn't it?|Would you like to share my umbrella?",
			foodie = "This is what soup is for.",
			nervous = "Will it get worse?|Should I bring my washing in?",
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
			sunny = "We should do {plan}.|This week.|For real.",
			bold = "{plan}. This week. You and me.",
			shy = "Um. Would you want to do {plan}?|This week? If you're free.",
			_ = "We should have {plan}.|This week.",
		}, "idea", "point")
		burst(s, "b", {
			easygoing = "Sure.|Not too early, though.",
			proud = "I'll plan it.|My plans don't go wrong.",
			bold = "This week? Why not today?",
			cool = "Sure.",
			nervous = "This week? Which day?|I need to write it down.",
			dramatic = "Yes.|The event of the season.",
			foodie = "I'll do the food.|Obviously I'll do the food.",
			gloomy = "It'll rain.|But okay.",
			_ = "Yes. Let's actually do it this time.",
		}, "music")
		s:say("a", "We always say that.", "sweat")
		s:say("b", "This time we mean it.", "heart")
		s:rel(5)
		s:memo("a", "{b} and I are planning {plan}. Actually doing it this time.")
		s:log("{a} and {b} planned {plan}.")
		return s:done()
	end,
})

-- a story made up a line each
local STORY = {
	start = {
		"Once there was a goose who wanted to run the town.",
		"Once, a very small boat set off to find the edge of the sea.",
		"Long ago, the bakery's oven started talking.",
		"There was a lighthouse that was scared of the dark.",
	},
	middle = {
		"On the way it met a crab who owed it money.",
		"Then it rained for a hundred years. Mostly on Tuesdays.",
		"Everyone in town turned into spoons. Except Gerald.",
		"So it hid in a teapot and waited for spring.",
		"Then a whale came along and asked for directions.",
	},
	finish = {
		"And they all had cake. The end.",
		"And that's why the gulls are so rude. The end.",
		"And it's still out there, if you look. The end.",
		"Then they woke up. It was all a dream. Or was it. The end.",
	},
}

event({
	id = "storycircle",
	actors = 3,
	when = "any",
	weight = W({ base = 0.12, count = 3, traits = { focus = -0.2 } }),
	scene = function(ctx, a, b, c)
		local s = K.scene(ctx, "A story, a line each")
		say(s, "a", "Let's make up a story.|A line each.|I'll start.", "idea")
		s:pick("a", STORY.start, "music")
		s:pick("b", STORY.middle, "music")
		s:pick("c", STORY.middle, "music")
		s:pick("a", STORY.finish, "sparkle")
		burst(s, "b", {
			proud = "That was mostly my line, really.",
			dreamy = "I want to live in that story.",
			bookish = "We should write it down.|I'll fix the middle.",
			dramatic = "A masterpiece.|I'm moved.",
			cheeky = "that made no sense|again",
			_ = "That made no sense.|Again.",
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
		s:say("a", "What would you do?", "question")
		burst(s, "b", {
			sunny = "Don't think so hard.|Walk with me. You'll forget all about it.",
			gentle = "Kettle on first.|Then tell me all of it.",
			bold = "Stop worrying and do it.|That's what I do.",
			dreamy = "I'd go and look at the sea for a while.|Things look smaller after.",
			easygoing = "Have a nap.|If it's still there after, then worry.",
			proud = "Do what I'd do.|It usually works out for me.",
			shy = "I'd hide.|But you're braver than me. You'll be okay.",
			cheeky = "put a whoopee cushion on it|problems hate that",
			cool = "Sleep on it.|Then decide.",
			prickly = "You're overthinking it.|Ask me again tomorrow if it's still bad.",
			dramatic = "Face it head on.|Like a ship in a storm.",
			bookish = "Write it all down.|Things look smaller on paper. I read that and it works.",
			gloomy = "It might go wrong. It might not.|Either way I'll be there.",
			polite = "If I may, I'd ask someone you trust.|Which I hope is me.",
			foodie = "Eat something first.|Nobody decides well hungry.",
			nervous = "I'd worry too.|Let's worry together. Then make a list.",
		}, "idea")
		s:choice("That's good advice.", function(c)
			c:voice("a", "thanks", "heart")
			c:rel(7)
			c:mood("a", 4)
		end)
		s:choice("Ask someone else too.", function(c)
			burst(c, "b", {
				proud = "Someone else?|Who else is there?",
				shy = "Oh. Yes.|That's better.",
				gentle = "That's sensible.|Ask as many people as you like.",
				prickly = "Fine.|They'll say the same.",
				polite = "Of course. That's very wise.",
				cheeky = "rude|fair, but rude",
				_ = "Rude.|Fair, but rude.",
			}, "sweat")
			c:say("a", "Thanks anyway. Really.", "heart")
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
			bold = "Up. Come on.|You're the toughest person I know. After me.",
			sunny = "Hey. Budge up.|Whatever it is, you've got me.",
			gentle = "Come here.|It'll look smaller tomorrow. It always does.",
			cheeky = "want me to cheer you up|or prank whoever did this|both?",
			shy = "Um. I brought you a biscuit.|No need to talk.",
			proud = "Chin up. People can see you.|Well. I can see you.",
			dreamy = "Want to watch the clouds?|They don't ask questions.",
			easygoing = "Hey. Sit.|We don't have to do anything.",
			cool = "Move over.",
			prickly = "Budge up.|I'm not leaving till you're okay, so.",
			dramatic = "No sad faces on my watch.|Tell me who I'm cross with.",
			bookish = "Can I sit?|I won't say anything clever. Promise.",
			gloomy = "Bad day? Same.|Let's be bad together.",
			polite = "May I sit with you a while?|Only if you'd like.",
			foodie = "I've got two pastries.|You look like you need one.",
			nervous = "Are you okay?|You're not okay. Tell me how to help.",
			_ = "Want to go for a walk?|It might help.",
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
			sunny = "{player}! Quick.|Settle something.",
			proud = "{player}. A small matter.|Settle it.",
			shy = "Um, {player}?|Could you settle something?",
			cheeky = "{player}|settle this",
			cool = "{player}. Settle something.",
			polite = "{player}, sorry.|Could you settle something for us?",
			_ = "{player}.|Settle something for us?",
		}, "question", "wave")
		s:say("a", "We've been counting. Who waves at you more?", "question")
		burst(s, "b", {
			bold = "It's me.|Say it's me.",
			dramatic = "Think carefully.|This matters more than you know.",
			gloomy = "It's {a}.|It's always {a}. Go on.",
			nervous = "You don't have to answer.|Unless you want to.",
			foodie = "Loser buys the buns.|Just so you know.",
			_ = "Be honest. We can take it.",
		}, "sweat")
		local SULK = {
			gloomy = "Knew it.",
			prickly = "Whatever.|My waves are better quality.",
			polite = "Fair enough. Well done.",
			foodie = "Fine. I'll buy the buns.",
			cheeky = "rigged!",
			_ = "Hmph.|I'm waving twice tomorrow.",
		}
		s:choice("{a} does.", function(c)
			c:voice("a", "brag", "sparkle", "cheer")
			burst(c, "b", SULK, "sweat")
			c:mood("a", 3)
			c:mood("b", -1)
		end)
		s:choice("{b} does.", function(c)
			c:voice("b", "brag", "sparkle", "cheer")
			burst(c, "a", SULK, "sweat")
			c:mood("b", 3)
			c:mood("a", -1)
		end)
		s:choice("I wave back at you both.", function(c)
			c:n("{a} and {b} looked at each other.")
			c:say("a", "That's such a {player} answer.", "laugh", "laugh")
			c:say("b", "Annoyingly fair.", "heart")
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
			nervous = "Did you hear that?|Tell me you heard that.",
			shy = "Um...|Something's in the hedge.",
			dramatic = "Something stirs.|In the hedge.",
			gloomy = "Something's in the hedge.|This is how it ends.",
			bold = "Hedge. Moving.|Stay behind me.",
			_ = "Shh.|Something's in the hedge.",
		}, "sweat")
		s:n("The hedge rustled. Out came a hedgehog, very slowly.")
		burst(s, "a", {
			cool = "It's a hedgehog.",
			bookish = "Hedgehogs come out at night.|Perfectly normal.",
			sunny = "Aww. Hello, little one.|You gave us a fright.",
			cheeky = "hehe|your face, {b}",
			prickly = "It's a hedgehog. Calm down.|...It is quite sweet.",
			foodie = "Is it after the crumbs in my pocket?|It can have them.",
			_ = "Oh.|Hello, you.",
		}, "heart")
		s:voice("b", "laugh", "music", "laugh")
		s:rel(6)
		s:memo("b", "A hedgehog lives in the park hedge. It gave me such a fright. It's sweet, really.")
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
		local s = K.scene(ctx, "You have to try it"):with({ rec = rec, Rec = rec:sub(1, 1):upper() .. rec:sub(2) })
		burst(s, "a", {
			foodie = "{b}. {Rec}.|You have to. Today.|I'll come with you.",
			bookish = "Have you tried {rec}?|I've got a list of reasons you should.",
			cool = "{Rec}. Try it.",
			sunny = "You have to try {rec}.|Promise me.",
			dramatic = "{b}. {Rec}.|It'll change your life.",
			_ = "You have to try {rec}.|Trust me.",
		}, "idea", "point")
		burst(s, "b", {
			prickly = "Fine.|If it's bad I'm telling you.",
			nervous = "What if I don't like it?|Then what?",
			easygoing = "Sure. Sometime.",
			polite = "I'd be glad to.|Thank you for thinking of me.",
			gloomy = "It'll be closed.|It's always closed when I go.",
			_ = "Okay. I'll try it.",
		}, "question")
		s:n("The next day, {b} went and tried it.")
		burst(s, "b", {
			prickly = "...It was good.|Don't look at me like that.",
			gloomy = "It was open. And good.|Strange day.",
			dramatic = "Life changing!|I'm a new person.",
			cool = "Good call.",
			_ = "You were right.|Annoyingly right.",
		}, "heart")
		s:rel(6)
		s:memo("b", "{a} told me to try {rec}. They were right. Don't tell them I said.")
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
			polite = "Sorry to bother you.|Might I borrow a cup of sugar? I'll bring it back.",
			foodie = "Sugar.|Emergency.|I'm halfway through a cake.",
			shy = "Um. Sorry.|Do you have any sugar?",
			cool = "Sugar?",
			nervous = "Hi. Sorry.|I'm out of sugar. I checked twice.",
			_ = "Hi.|Sugar? I'm out.",
		}, "question")
		burst(s, "a", {
			gentle = "Come in, come in.|Sit down while I find it.",
			sunny = "Sugar? Sure. Come in.|Have you heard about the gulls?",
			prickly = "Fine. Come in.|Don't touch anything.",
			gloomy = "Come in. Mind the mess.|There's always a mess.",
			_ = "Come in.|It's in here somewhere.",
		}, "heart")
		s:n("An hour later {b} left with the sugar, a slice of pie and all the news.")
		burst(s, "b", {
			foodie = "The cake.|My cake. It's still in the bowl.",
			nervous = "Oh no.|Did I turn my oven off?",
			_ = "Oh no.|The cake. I forgot the cake.",
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
			cool = "Nice.",
			dreamy = "The sea's gone gold.|Like somebody spilled tea.",
			gloomy = "It'll be dark soon.|...It's nice, though.",
			dramatic = "Look at that.|The whole sky. Just for us.",
			bookish = "The light comes a longer way at sunset. That's the red.|Sorry. It's lovely, I mean.",
			foodie = "It looks like the top of a peach tart.",
			_ = "Look at that.",
		}, "heart")
		s:voice("b", "happy", "heart")
		s:n("Neither of them said much after that. A boat went by.")
		burst(s, "a", {
			prickly = "Same time tomorrow.|Don't be late.",
			nervous = "Same time tomorrow?|If that's okay?",
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
		local s = K.scene(ctx, "A long day"):with({ job = if w then w.def.name:lower() else "work" })
		burst(s, "a", {
			gloomy = "Worst day at the {job}.|Then it got worse.",
			dramatic = "Today at the {job} was a disaster.|I'll start from the beginning.",
			nervous = "I think I got something wrong at the {job}.|I keep going over it.",
			proud = "The {job} was not my best day.|Tell no one.",
			prickly = "Don't ask about the {job}.",
			sunny = "Today was rubbish.|The {job} was rubbish.",
			_ = "Long day at the {job}.",
		}, "sad")
		burst(s, "b", {
			gentle = "Come here.|Tell me all of it.",
			foodie = "Sit. Eat this.|Then tell me.",
			cool = "Talk, or quiet?",
			bookish = "Did it go wrong, or does it feel like it did?|They're different.",
			polite = "I'm so sorry.|What can I do?",
			cheeky = "want me to go pull a face at the {job}",
			_ = "Want to talk about it?",
		}, "heart")
		s:n("{a} talked. {b} listened, and nodded in the right places.")
		burst(s, "a", {
			prickly = "...Fine. Thanks.|That helped.",
			cool = "Thanks.",
			_ = "Thanks.|That helps, actually.",
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
		s:say("a", "Why does my coat smell of peppermints?", "question")
		s:say("b", "Why are there seven pencils in my pocket?", "question")
		burst(s, "a", {
			bookish = "I like a spare pencil.|Or six.",
			cheeky = "those are emergency pencils",
			nervous = "What if I need to write something down?|Seven times?",
			_ = "Those are my pencils.|Give them back.",
		}, "sweat")
		burst(s, "b", {
			foodie = "And those peppermints are mine.|I'll be needing those.",
			_ = "Swap back?|Same café, same time tomorrow?",
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
		s:say("a", "We could run for it.", "idea")
		burst(s, "b", {
			gloomy = "We'd be soaked in two steps.|I've done the maths.",
			bold = "Let's run.|On three.",
			easygoing = "Or we stay here.|It's nice here.",
			nervous = "What if it gets worse halfway?",
			dreamy = "Listen to it on the roof.|Like little feet.",
			bookish = "Running only gets you a bit less wet.|I read a whole thing about it.",
			_ = "Or we wait.|It can't rain forever.",
		}, "question")
		s:n("They waited. It rained for another hour. They talked about nothing much.")
		s:voice("a", "laugh", "music", "laugh")
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
			sunny = "Okay I have to say it.|Your hat today. Perfect.",
			shy = "Um. I like your scarf.|That's all.|Bye. No, wait.",
			cool = "Good jacket.",
			prickly = "Your hair looks fine today.|Don't make it weird.",
			polite = "If I may, you look very smart today.",
			dramatic = "That colour. On you!|I had to stop walking.",
			_ = "I like your jumper.|Just saying.",
		}, "heart")
		burst(s, "b", {
			proud = "I know.|But thank you.",
			shy = "Oh. Oh no.|Thank you.|Where do I put my hands.",
			gloomy = "Really? Huh.|Nobody says that.",
			bookish = "Thank you.|I've had it six years, actually.",
			nervous = "Really?|You're not just saying it?",
			_ = "Oh. Thanks.",
		}, "sparkle")
		burst(s, "b", {
			cheeky = "and your shoes are|shoes|lovely shoes",
			cool = "Your shoes are fine too.",
			_ = "And your, um.|Your shoes are nice.",
		}, "sweat")
		s:voice("a", "laugh", "music", "laugh")
		s:rel(5)
		s:log("{a} and {b} swapped compliments, badly.")
		return s:done()
	end,
})

-- three of them make a plan for tomorrow, all talking at once
local OUTINGS = {
	{ what = "a swim at the cove", bring = "towels" },
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
			sunny = "Okay okay okay.|Tomorrow. {what}.|All of us.",
			bold = "Tomorrow. {what}.|Nine sharp. Everyone's coming.",
			dramatic = "Tomorrow we do {what}.|It's been decided!",
			shy = "Um. I was thinking.|Tomorrow? {what}?|Only if you want.",
			_ = "Tomorrow.|Fancy {what}?",
		}, "idea", "point")
		burst(s, "b", {
			easygoing = "How early is early?|Asking for me.",
			nervous = "What time?|What if it rains?|I'll bring a coat. Two coats.",
			foodie = "I'll do snacks.|Don't anyone else do snacks.",
			cool = "In.",
			prickly = "Fine.|I'm not carrying anything.",
			_ = "I'm in.",
		}, "music")
		burst(s, "c", {
			bookish = "Someone has to bring {bring}.|I'll make a list.",
			gloomy = "It'll rain.|I'll still come.",
			proud = "I'll lead the way.|I know the best route.",
			cheeky = "i'm coming|i'm bringing nothing",
			_ = "Who's bringing {bring}?",
		}, "question")
		s:n("They agreed on everything except the time, then agreed on that too.")
		say(s, "a", "Nine.|Ish.", "heart")
		s:relx("a", "b", 4)
		s:relx("a", "c", 4)
		s:relx("b", "c", 3)
		s:memo("a", "Tomorrow it's {what} with {b} and {c}. Nine. Ish.")
		s:log("{a}, {b} and {c} planned {what}.")
		return s:done()
	end,
})

-- a note for one friend that went through another, and changed on the way
local RELAYS = {
	{ said = "bring the ladder", heard = "bring a lobster" },
	{ said = "meet at the pier at two", heard = "eat a pear at two" },
	{ said = "the cat's on the roof again", heard = "the hat's on the roof again" },
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
		s:n("{a} asked {b} to tell {c} to {said}. {b} was eating at the time.")
		burst(s, "c", {
			cool = "{a}.|{b} says you want me to {heard}.|Why.",
			nervous = "{a}, sorry, quick question.|{b} said to {heard}?|Is that right? I'll do it. I just want to check.",
			sunny = "{a}! I'm on my way.|{b} said to {heard}.|Weird, but okay.",
			polite = "Hello, {a}.|{b} passed on your message. You'd like me to {heard}?",
			_ = "{a}.|{b} says you want me to {heard}?",
		}, "question")
		burst(s, "a", {
			prickly = "No.|I said {said}.|Seriously, {b}.",
			cheeky = "hahaha|no|{said}",
			dramatic = "{heard}?|I said {said}. What have you done, {b}.",
			_ = "...No.|I said {said}.",
		}, "sweat")
		burst(s, "b", {
			foodie = "I had a mouthful of bun.|It's not my fault.",
			gloomy = "Course I got it wrong.",
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
