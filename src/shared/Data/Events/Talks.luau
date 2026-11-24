--!nonstrict
-- Conversations you can watch, longer than a passing word: a long chat over two topics, gossip
-- about a third villager (who may be listening), dreams compared, a squabble that grows and then
-- fizzles out, a silly debate you settle, catching up on the day, moaning about the weather,
-- making plans, a story made up a line each. Built from Data/Events/Chatter's parts, so they
-- come out different each time.

local K = require(script.Parent.Kit)
local Chatter = require(script.Parent.Chatter)
local Sayings = require(script.Parent.Parent.Sayings)

local W = K.W

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
		s:n("Then they got onto something else entirely.")
		s:pick("b", t2.open, "idea", "point")
		if Chatter.agrees(ctx, b, a) then
			s:pick("a", t2.yes, "music")
			s:pick("b", t2.more, "sparkle")
		else
			s:pick("a", t2.no, "question")
			s:pick("b", t2.back, "sweat")
		end
		s:n("An hour went by. Neither of them noticed.")
		s:rel(d1 + 4)
		s:with({ one = t1.about, two = t2.about })
		s:log("{a} and {b} talked for an hour about {one}, and then {two}.")
		return s:done()
	end,
})

-- What there is to say about somebody, from what they're like and what they've been up to.
local function gossipAbout(ctx, c): { string }
	local v = ctx.v(c)
	local out = {}
	local byPers = {
		sunny = "{c} said good morning to a lamppost today. Twice.",
		gentle = "{c} knitted a hat for the bakery's cat. It wears it.",
		bold = "{c} challenged a gull to a race. The gull won.",
		dreamy = "{c} asked me what colour Thursday is. I didn't know.",
		easygoing = "{c} fell asleep standing up at the bus stop.",
		proud = "{c} bought a little mirror to carry around. For emergencies.",
		shy = "{c} waved at me and then hid behind a bin.",
		cheeky = "{c} swapped all the house numbers on our street. I live at 4 now.",
	}
	table.insert(out, byPers[v.pers] or "{c} has been acting very {c} lately.")
	local hobby = Sayings.hobby(v.hobby)
	if hobby then
		table.insert(out, "{c} has been doing " .. hobby.name .. " every single evening. Every one.")
	end
	local job = ctx.job(c)
	if job then
		table.insert(out, "{c} told me the " .. job.def.name:lower() .. " is the best job in town. Three times.")
	end
	if (v.mood or 50) < 35 then
		table.insert(out, "{c} seems a bit down. Have you noticed?")
	end
	for _, other in ctx.present do
		if other ~= c and ctx.bond(c, other) == "crush" then
			table.insert(out, "I think {c} likes someone. They went pink at the market.")
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
		local kind = string.find(said, "down", 1, true) ~= nil
		s:say("a", "Psst. {b}. Have you noticed {c} lately?", "question")
		s:say("a", said, "idea", "point")
		if ctx.rel(b, c) >= 30 then
			s:by("b", {
				gentle = "Oh, be nice. {c}'s lovely.",
				cheeky = "Ha. That's very {c}. I love it.",
				_ = "That's just {c} being {c}. I like that about them.",
			}, "heart")
		else
			s:by("b", {
				proud = "I've always said {c} was odd.",
				cheeky = "Tell me more. Tell me everything.",
				_ = "Really? Huh.",
			}, "question")
		end
		if ctx.rng:chance(0.35) then
			s:n("Then {c} walked round the corner.")
			s:say("c", "Talking about me?", "question")
			if kind then
				s:say("a", "We were worried about you. That's all.", "heart")
				s:voice("c", "thanks", "heart")
				s:relx("a", "c", 6)
				s:relx("b", "c", 4)
			else
				s:say("a", "No. Talking about... lampposts.", "sweat")
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
	when = "day",
	weight = W({ base = 0.18, traits = { focus = -0.3 } }),
	scene = function(ctx, a, b)
		local d1 = ctx.rng:pick(Chatter.Dreams)
		local d2 = d1
		while d2 == d1 do
			d2 = ctx.rng:pick(Chatter.Dreams)
		end
		local s = K.scene(ctx, "Last night's dreams"):with({ one = d1, two = d2 })
		s:say("a", "I had the strangest dream. I dreamed {one}.", "zzz")
		s:by("b", {
			proud = "Mine was better. I dreamed {two}.",
			shy = "Um. I dreamed {two}. Is that weird?",
			dreamy = "Oh, I've been there. Last week I dreamed {two}.",
			_ = "That's nothing. I dreamed {two}.",
		}, "zzz")
		s:by("a", {
			dreamy = "I think our dreams know each other.",
			bold = "Okay, yours wins. This time.",
			cheeky = "What did you eat before bed? I want some.",
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
	"A gull landed on the bench and stole half of {a}'s sandwich.",
	"The church bell rang and they both forgot where they were.",
	"Someone walked past carrying a very large cake.",
}

event({
	id = "spat",
	when = "day",
	weight = W({ base = 0.2, quarrel = "any", traits = { temper = 0.6 } }),
	scene = function(ctx, a, b)
		local s = K.scene(ctx, "A squabble"):with({ thing = ctx.rng:pick(Chatter.Spats) })
		s:n("{a} and {b} started arguing about {thing}.")
		s:say("a", "It was you. Everyone knows it was you.", "anger", "point")
		s:say("b", "Me? It was obviously you.", "anger")
		s:voice("a", "angry", "anger")
		s:voice("b", "angry", "anger")
		if K.isPers(ctx, a, "proud", "bold") or K.isPers(ctx, b, "proud", "bold") then
			s:say("a", "I'm not saying another word about it.", "anger")
			s:say("b", "Good.", "anger")
			s:say("a", "...Except that it was you.", "anger")
		end
		s:n(ctx.rng:pick(FIZZLE))
		s:say("b", "...What were we arguing about?", "question")
		s:say("a", "No idea. Want a biscuit?", "heart")
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
		s:n("They both turn to you.")
		s:choice("{a} is right", function(c)
			c:voice("a", "brag", "sparkle", "cheer")
			c:voice("b", "no", "anger")
			c:mood("a", 3)
			c:mood("b", -2)
		end)
		s:choice("{b} is right", function(c)
			c:voice("b", "brag", "sparkle", "cheer")
			c:voice("a", "no", "anger")
			c:mood("b", 3)
			c:mood("a", -2)
		end)
		s:choice("You're both wrong", function(c)
			c:n("{a} and {b} looked at each other, then at you.")
			c:say("b", "Well, now we agree on something. You're wrong.", "laugh", "laugh")
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
		s:say("a", "So what's new with you?", "question")
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
	rain = { "Rain again. My socks have given up.", "It's not raining, it's the sky doing the washing up." },
	storm = { "That thunder's been going since breakfast.", "My hat blew off. It's in the sea now. Gone." },
	snow = { "I can't feel my nose. Is it still there?", "My door's frozen shut. I came out the window." },
	clear = { "Too hot. I'm melting like an ice lolly.", "Not a cloud. Not one. I'm boiling." },
	cloudy = { "It can't decide what it wants to do, this weather.", "Grey, grey, grey. Like soup that's gone off." },
	blossom = { "Petals everywhere. I keep finding them in my tea.", "I've sneezed nine times today. Nine." },
	leaves = { "I swept my step and it's covered again already.", "A leaf hit me in the face. Right in the face." },
}

event({
	id = "moan",
	when = "any",
	weight = W({ base = 0.2 }),
	scene = function(ctx, a, b)
		local lines = MOANS[ctx.weather] or MOANS.cloudy
		local s = K.scene(ctx, "This weather")
		s:say("a", ctx.rng:pick(lines), "sweat")
		s:by("b", {
			sunny = "Oh, come on, it's not that bad. It's a bit bad.",
			proud = "I don't feel it. I'm above weather.",
			easygoing = "I just stay in. Problem solved.",
			gentle = "Come in and have a cup of something warm.",
			cheeky = "I like it. Means everyone's grumpy and I'm not.",
			_ = "Don't get me started.",
		}, "question")
		s:voice("a", "laugh", "music")
		s:rel(4)
		s:log("{a} and {b} moaned about the weather.")
		return s:done()
	end,
})

local PLANS = { "a trip to the little islet", "a picnic on the hill", "a night of board games", "a walk along the whole beach", "a baking day" }

event({
	id = "plans",
	when = "day",
	weight = W({ base = 0.18, rel = 25 }),
	scene = function(ctx, a, b)
		local s = K.scene(ctx, "Making plans"):with({ plan = ctx.rng:pick(PLANS) })
		s:say("a", "We should do {plan}. This week.", "idea", "point")
		s:by("b", {
			easygoing = "Sure. Not too early, though.",
			proud = "I'll plan it. My plans are flawless.",
			bold = "This week? Why not today?",
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
		"Once there was a goose who wanted to be mayor.",
		"Once, a very small boat set off to find the edge of the sea.",
		"Long ago, the bakery's oven started talking.",
		"There was a lighthouse that was scared of the dark.",
	},
	middle = {
		"But on the way, it met a crab who owed it money.",
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
		s:say("a", "Let's make up a story. A line each. I'll start.", "idea")
		s:pick("a", STORY.start, "music")
		s:pick("b", STORY.middle, "music")
		s:pick("c", STORY.middle, "music")
		s:pick("a", STORY.finish, "sparkle")
		s:by("b", {
			proud = "That was mostly my line, really.",
			dreamy = "I want to live in that story.",
			_ = "That made no sense. Again.",
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
		s:by("b", {
			sunny = "Smile at it. Things get scared when you smile at them.",
			gentle = "Sleep on it, have something warm, and be kind to yourself.",
			bold = "Walk straight at it. Head first. Works every time.",
			dreamy = "Ask the sea. The sea knows things.",
			easygoing = "Have a nap. If it's still there after, then worry.",
			proud = "Do what I would do. Which is be brilliant.",
			shy = "I'd hide. But you're braver than me. You'll be fine.",
			cheeky = "Put a whoopee cushion on it. Problems hate that.",
		}, "idea")
		s:choice("That's good advice", function(c)
			c:voice("a", "thanks", "heart")
			c:rel(7)
			c:mood("a", 4)
		end)
		s:choice("Maybe ask someone else too", function(c)
			c:say("b", "Rude. Fair, but rude.", "sweat")
			c:say("a", "Thanks anyway. Really.", "heart")
			c:rel(3)
			c:mood("a", 2)
		end)
		s:log("{a} asked {b} for advice.")
		return s:done()
	end,
})

-- a pep talk for somebody nervous about something
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
		s:by("b", {
			bold = "Up. Come on. Up. You're the toughest person I know. After me.",
			sunny = "Hey. Hey. You. Yes, you. You're brilliant, and today's not over.",
			gentle = "Come here. Whatever it is, it'll look smaller tomorrow.",
			cheeky = "Want me to cheer you up or prank whoever did this? Both?",
			_ = "Want to go for a walk? Walks fix things.",
		}, "heart")
		s:voice("a", "thanks", "heart")
		s:rel(8)
		s:mood("a", 8)
		s:log("{b} cheered {a} up.")
		return s:done()
	end,
})

return list
