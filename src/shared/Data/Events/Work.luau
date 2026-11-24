--!nonstrict
-- At work: a big order, the builder's tower of bricks, letters to the wrong houses, a grumpy
-- customer, a new flavour, an art show, a concert, a lesson, a check up, latte art, a book back
-- ten years late. Each needs a villager with that job (Data/Jobs), and what it pays comes from
-- the job's own income, so it stays in step with wages.

local K = require(script.Parent.Kit)
local Tuning = require(script.Parent.Parent.Parent.Config.Tuning)

local W = K.W

local list = {}
local function event(def)
	def.actors = def.actors or 1
	table.insert(list, def)
end

-- a share of a day's takings at their job
local function share(ctx, vid, k: number): number
	local w = ctx.job(vid)
	if not w then
		return 0
	end
	return math.max(5, math.floor(w.job.income * Tuning.Jobs.BusyDayShare * k / 5) * 5)
end

local function place(ctx, vid): string
	local w = ctx.job(vid)
	return if w then w.def.name:lower() else "workplace"
end

-- what a big order looks like, by job
local ORDER = {
	baker = { "bakes", "two hundred bread rolls for the fair on the next island" },
	barista = { "bakes", "sixty coffees for the ferry crew, all different" },
	icecream = { "bakes", "ice cream for a whole school trip" },
	shopkeeper = { "parcels", "a cart full of apples for a cider maker" },
	florist = { "bouquet", "flowers for every table at a big party" },
	postie = { "parcels", "a mountain of parcels before the holidays" },
	builder = { "bricks", "a new garden wall for the hall" },
}

event({
	id = "bigorder",
	cutscene = "stall",
	when = "day",
	weight = W({ base = 0.3, job = { "baker", "barista", "icecream", "shopkeeper", "florist", "postie", "builder" } }),
	scene = function(ctx, a)
		local w = ctx.job(a)
		local o = ORDER[w.job.id] or ORDER.shopkeeper
		local coins = share(ctx, a, 1.2)
		local s = K.scene(ctx, "A big order"):with({ order = o[2], place = place(ctx, a), coins = coins })
		s:prop(o[1], "a")
		s:n("A big order came in at the {place}: {order}.")
		s:by("a", {
			bold = "Easy. Done by lunch.",
			easygoing = "That's... a lot. Can I panic slowly?",
			proud = "They came to the best. Naturally.",
			shy = "That's so many. What if I get it wrong?",
			_ = "That's the biggest order we've ever had.",
		}, "sweat")
		s:choice("Work late and get it done", function(c)
			c:n("{a} worked till the stars came out. The order went out on time.")
			c:voice("a", "tired", "zzz")
			c:coins(coins)
			c:xp("a", 25)
			c:mood("a", -2)
			c:memo("a", "We did the big order. I can still smell it on my hands.")
		end)
		s:choice("Take on what you can", function(c)
			c:n("{a} took half. The customer was happy enough.")
			c:coins(math.floor(coins / 2))
			c:xp("a", 10)
			c:mood("a", 2)
		end)
		s:log("{a} got a big order at the {place}.")
		return s:done()
	end,
})

event({
	id = "bricktower",
	when = "day",
	weight = W({ base = 0.4, job = "builder" }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "The tower of bricks")
		s:prop("bricks", "a")
		s:n("{a} has been stacking spare bricks in the yard. The tower is taller than a door now. It leans.")
		s:by("a", {
			bold = "One more. Just one more.",
			proud = "Engineering. Pure engineering.",
			cheeky = "If it falls, I was never here.",
			_ = "It's practice. For what, I don't know yet.",
		}, "sparkle", "point")
		s:choice("Add one more", function(c)
			if ctx.rng:chance(0.5) then
				c:n("It held. It wobbled, and it held.")
				c:voice("a", "brag", "sparkle", "cheer")
				c:xp("a", 15)
				c:mood("a", 5)
				c:leave("bricks", 8, "a")
			else
				c:n("It did not hold. Bricks everywhere. A gull flew off in disgust.")
				c:say("a", "...Right. Lunch, then tidy up.", "sweat")
				c:mood("a", -2)
			end
		end)
		s:choice("Quit while it's standing", function(c)
			c:by("a", {
				proud = "Fine. It's perfect as it is anyway.",
				bold = "Fine. I could've done one more, though.",
				_ = "Good call. I'll leave it up for people to see.",
			}, "heart")
			c:leave("bricks", 8, "a")
			c:xp("a", 8)
			c:mood("a", 3)
		end)
		s:log("{a} built a tower of bricks at work.")
		return s:done()
	end,
})

event({
	id = "wrongletters",
	actors = 2,
	when = "day",
	weight = W({ base = 0.4, job = "postie" }),
	scene = function(ctx, a, b)
		local s = K.scene(ctx, "The wrong letters")
		s:prop("parcels", "a")
		s:n("{a} mixed up two bags this morning. Every letter in town went to the wrong house.")
		s:say("b", "I got a birthday card for somebody called Edna. We don't have an Edna.", "question")
		s:by("a", {
			proud = "That was a test of everyone's honesty. Well done, you passed.",
			shy = "I'm so sorry. I'll fix it. I'll fix all of it.",
			easygoing = "Just swap with your neighbours. It'll even out.",
			_ = "Ah. I'll do the round again. Backwards.",
		}, "sweat")
		s:xp("a", 10)
		s:rel(3)
		s:log("{a} put every letter through the wrong door.")
		return s:done()
	end,
})

event({
	id = "grumpycustomer",
	actors = 2,
	when = "day",
	weight = W({ base = 0.25, job = "any", btraits = { temper = 0.6 } }),
	scene = function(ctx, a, b)
		local s = K.scene(ctx, "A grumpy customer"):with({ place = place(ctx, a) })
		s:n("{b} came into the {place} in a very bad mood.")
		s:by("b", {
			proud = "This is not what I asked for. Who's in charge here?",
			bold = "This is all wrong. Who's in charge?",
			cheeky = "Is this meant to be like this? Seriously?",
			_ = "This is all wrong. I want to speak to whoever's in charge.",
		}, "anger", "point")
		s:by("a", {
			gentle = "I'm sorry it's been a bad day. Let me make it right.",
			bold = "That's me. I'm in charge. What's the problem?",
			proud = "Nothing here is wrong. Except your mood.",
			shy = "I'm s-sorry. What would you like?",
			cheeky = "Have you tried smiling? It's free. Everything else costs.",
			_ = "Okay. Deep breath. What can I do?",
		}, "sweat")
		if K.isPers(ctx, a, "gentle", "sunny", "shy") or ctx.rng:chance(0.4) then
			s:say("b", "...Sorry. Rough morning. Thank you.", "sad")
			s:rel(5)
			s:xp("a", 10)
		else
			s:say("b", "Hmph.", "anger")
			s:rel(-4)
		end
		s:log("{b} was a grumpy customer at {a}'s {place}.")
		return s:done()
	end,
})

local NEWTHINGS = {
	baker = "a loaf shaped like a cat",
	barista = "coffee with a spoon of honey and a pinch of salt",
	icecream = "pickle and honey ice cream",
	shopkeeper = "socks that come in threes, in case you lose one",
}

event({
	id = "newproduct",
	cutscene = "stall",
	when = "day",
	weight = W({ base = 0.25, job = { "baker", "barista", "icecream", "shopkeeper" } }),
	scene = function(ctx, a)
		local w = ctx.job(a)
		local s = K.scene(ctx, "Something new")
			:with({ thing = NEWTHINGS[w.job.id] or "something new", place = place(ctx, a) })
		s:say("a", "New at the {place} today: {thing}. Try it. Be honest.", "idea", "point")
		s:choice("Try it", function(c)
			if ctx.rng:chance(0.6) then
				c:n("It's good. It's actually good.")
				c:voice("a", "excited", "sparkle", "cheer")
				c:coins(share(ctx, a, 0.6))
				c:xp("a", 15)
				c:mood("a", 5)
			else
				c:n("You chewed. You kept chewing. {a} watched you chew.")
				c:say("a", "I'll take it off the board.", "sweat")
				c:xp("a", 5)
			end
		end)
		s:choice("Maybe tomorrow", function(c)
			c:say("a", "Tomorrow, then. There's plenty left.", "sad")
		end)
		s:log("{a} tried out {thing} at the {place}.")
		return s:done()
	end,
})

event({
	id = "artshow",
	when = "day",
	weight = W({ base = 0.3, job = "artist" }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "An art show")
		s:prop("easel", "a")
		s:prop("mural", "a")
		s:n("{a} has hung everything they painted this season along the street for an art show.")
		s:by("a", {
			proud = "Each one is a masterpiece. Some more than others.",
			shy = "Please say something. Anything. Even 'hm'.",
			dreamy = "This one's called 'Wednesday'. You can tell.",
			_ = "Which one's your favourite? Lie if you have to.",
		}, "sparkle")
		s:choice("The portrait", function(c)
			c:by("a", {
				shy = "That one? You can have it. If you want.",
				proud = "Good eye. It's yours.",
				_ = "That one? It's yours. No arguing.",
			}, "heart", "cheer")
			c:keep("keep_portrait", "a")
			c:xp("a", 10)
			c:hearts("a", 1)
		end)
		s:choice("All of them", function(c)
			c:by("a", {
				shy = "Really? All of them? ...Thank you.",
				proud = "Of course. They're all good.",
				_ = "You're only saying that. Say it again.",
			}, "heart")
			c:xp("a", 15)
			c:mood("a", 6)
			c:all(2)
		end)
		s:log("{a} put on an art show.")
		return s:done()
	end,
})

event({
	id = "concert",
	cutscene = { stage = "bandstand", extras = 3, open = "wide", ending = { shot = "wide", act = { all = "dance" } } },
	when = "any",
	weight = W({
		base = 0.3,
		job = "musician",
		count = 2,
		cond = function(ctx)
			return ctx.hour >= 17 or ctx.hour < 1
		end,
	}),
	scene = function(ctx, a)
		local s = K.scene(ctx, "A concert")
		s:prop("microphone", "a")
		s:prop("guitar", "a")
		s:n("{a} is playing a concert at the bandstand. The whole town is there.")
		s:by("a", {
			shy = "Um. This one's about a gull who wanted to be a swan.",
			proud = "This next one's my best. You'll want to remember it.",
			_ = "This next one's about a gull who wanted to be a swan. Clap if you know it.",
		}, "music")
		s:n("Nobody knows it. Everybody claps.")
		s:fx({ t = "festival" })
		s:xp("a", 20)
		s:coins(share(ctx, a, 0.8))
		s:all(3)
		s:log("{a} played a concert at the bandstand.")
		return s:done()
	end,
})

local LESSONS = {
	"the names of all the clouds",
	"how to tie six different knots",
	"the history of the town's fountain",
	"how to say hello in four languages",
}

event({
	id = "lesson",
	actors = 2,
	when = "day",
	weight = W({ base = 0.3, job = "teacher" }),
	scene = function(ctx, a, b)
		local s = K.scene(ctx, "A lesson"):with({ topic = ctx.rng:pick(LESSONS) })
		s:n("{a} is teaching {b} {topic}.")
		s:say("a", "Right. Repeat after me.", "point")
		s:by("b", {
			dreamy = "Sorry, I was watching a bird. Can you start again?",
			proud = "I knew most of this already.",
			cheeky = "Is there a test? Can I copy off you?",
			_ = "Okay. I'm ready. I'm ready now. Go.",
		}, "question")
		s:n("By the end, {b} could do it without looking.")
		s:xp("a", 15)
		s:xp("b", 20)
		s:rel(5)
		s:log("{a} taught {b} {topic}.")
		return s:done()
	end,
})

event({
	id = "checkup",
	actors = 2,
	when = "day",
	weight = W({ base = 0.25, job = "doctor" }),
	scene = function(ctx, a, b)
		local s = K.scene(ctx, "A check up")
		s:say("a", "Say ahh.", "point")
		s:say("b", "Ahhhhh.", "sweat")
		s:by("a", {
			gentle = "Lovely. Healthy as a horse. Eat a vegetable this week, though.",
			bold = "You're fine. Do twenty push ups. You're still fine.",
			proud = "Perfect health. Thanks to me, naturally.",
			_ = "All good. More sleep, fewer buns.",
		}, "sparkle")
		s:voice("b", "thanks", "heart")
		s:xp("a", 15)
		s:mood("b", 4)
		s:rel(4)
		s:log("{a} gave {b} a check up.")
		return s:done()
	end,
})

event({
	id = "latteart",
	when = "day",
	weight = W({ base = 0.3, job = "barista" }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "Latte art")
		s:n("{a} is trying to pour a heart into the foam.")
		if ctx.rng:chance(0.5) then
			s:n("It came out a perfect heart. {a} held it up for everyone to see.")
			s:voice("a", "brag", "sparkle", "cheer")
			s:xp("a", 10)
			s:mood("a", 4)
		else
			s:n("It came out looking like a potato with legs.")
			s:by("a", {
				proud = "It's a swan. Clearly a swan.",
				cheeky = "It's a potato. I meant to. It's a special potato.",
				_ = "...It's abstract.",
			}, "sweat")
			s:xp("a", 5)
		end
		s:log("{a} tried some latte art.")
		return s:done()
	end,
})

event({
	id = "overdue",
	when = "day",
	weight = W({ base = 0.3, job = "librarian" }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "A very late book")
		s:n("Someone posted a book back through the library door. It's ten years overdue.")
		s:by("a", {
			gentle = "Ten years. Well, I never.",
			shy = "Ten years. I don't even know what the fine is for that.",
			_ = "Ten years. TEN. The fine on this would buy a boat.",
		}, "anger")
		s:by("a", {
			gentle = "There's a note inside. It says sorry, and that they loved it.",
			proud = "I'll be framing the date stamp.",
			_ = "It's in better shape than I'd have guessed. They looked after it.",
		}, "heart")
		s:xp("a", 10)
		s:mood("a", 3)
		s:log("A book came back to {a}'s library ten years late.")
		return s:done()
	end,
})

event({
	id = "bigbouquet",
	when = "day",
	weight = W({ base = 0.3, job = "florist" }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "The biggest bouquet")
		s:prop("bouquet", "a")
		s:n("{a} has been asked for the biggest bouquet the town has ever seen. It needs a bucket.")
		s:by("a", {
			gentle = "I've put sweet peas all round the edge.",
			dreamy = "I put in one that only opens at night. A little secret.",
			_ = "Two buckets, actually. I've run out of buckets.",
		}, "sparkle")
		s:coins(share(ctx, a, 0.8))
		s:xp("a", 15)
		s:mood("a", 4)
		s:log("{a} made an enormous bouquet.")
		return s:done()
	end,
})

event({
	id = "flavour",
	when = "day",
	weight = W({ base = 0.3, job = "icecream" }),
	scene = function(ctx, a)
		local flavours = { "toast and marmalade", "seaweed and lemon", "birthday cake", "cucumber and mint" }
		local s = K.scene(ctx, "A new flavour"):with({ flavour = ctx.rng:pick(flavours) })
		s:say("a", "New flavour. {flavour}. First scoop's free.", "idea", "point")
		s:choice("Have a scoop", function(c)
			c:n("Odd. Then lovely. Then odd again.")
			c:say("a", "That face. Is that a good face?", "question")
			c:xp("a", 10)
			c:mood("a", 3)
		end)
		s:choice("Stick to vanilla", function(c)
			c:by("a", {
				cheeky = "Coward. I mean, sensible.",
				shy = "Oh. That's okay. Vanilla's nice.",
				proud = "Vanilla. Of course. Your loss.",
				_ = "Fair enough. Vanilla it is.",
			}, "sweat")
		end)
		s:log("{a} invented {flavour} ice cream.")
		return s:done()
	end,
})

event({
	id = "coworkers",
	actors = 2,
	when = "any",
	weight = W({
		base = 0.2,
		job = "any",
		cond = function(ctx, a, b)
			return ctx.job(b) ~= nil
		end,
	}),
	scene = function(ctx, a, b)
		local s = K.scene(ctx, "After work"):with({ pa = place(ctx, a), pb = place(ctx, b) })
		s:say("a", "Long day at the {pa}. You?", "sweat")
		s:say("b", "Don't ask. Something exploded at the {pb}. Only a little.", "sweat")
		s:voice("a", "laugh", "laugh")
		s:say("b", "Same time tomorrow?", "heart")
		s:rel(5)
		s:log("{a} and {b} swapped stories about work.")
		return s:done()
	end,
})

event({
	id = "mishap",
	when = "day",
	weight = W({ base = 0.2, job = "any", traits = { focus = -0.4 } }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "Whoops"):with({ place = place(ctx, a) })
		s:n("{a} knocked over the whole front display at the {place}. It went everywhere.")
		s:by("a", {
			cheeky = "That's how you get people's attention.",
			proud = "Nobody saw. Right? Nobody saw.",
			easygoing = "I'll pick it up. In a minute.",
			shy = "Oh no oh no oh no.",
			_ = "Well, now it's a floor display.",
		}, "sweat")
		s:mood("a", -2)
		s:xp("a", 5)
		s:log("{a} knocked over the display at the {place}.")
		return s:done()
	end,
})

event({
	id = "bestworker",
	when = "day",
	weight = W({
		base = 0.15,
		job = "any",
		cond = function(ctx, a)
			return (ctx.v(a).lv or 1) >= 5
		end,
	}),
	scene = function(ctx, a)
		local s = K.scene(ctx, "Worker of the month"):with({ place = place(ctx, a) })
		s:n("The customers at the {place} put {a}'s name on a little board: worker of the month.")
		s:by("a", {
			proud = "Only of the month?",
			shy = "Me? Really? I'm going to cry a bit.",
			easygoing = "Huh. I'll take it. Can I have the afternoon off?",
			_ = "I'm putting this on my fridge.",
		}, "sparkle", "cheer")
		s:xp("a", 20)
		s:mood("a", 6)
		s:log("{a} was worker of the month at the {place}.")
		return s:done()
	end,
})

return list
