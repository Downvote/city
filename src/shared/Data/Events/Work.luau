--!nonstrict
-- At work: a big order, the builder's tower of bricks, letters to the wrong houses, a grumpy
-- customer, a new flavour, an art show, a concert, a lesson, a check up, latte art, a book back
-- ten years late, the lunch rush, a regular, a new trick, the wrong order, a slow day. Each needs
-- a villager with a job (Data/Jobs), and what it pays comes from the job's own income, so it
-- stays in step with wages. The villagers talk the way a friend texts you, and call you by name
-- ({player}).

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
			shy = "That's so many... what if I get it wrong?",
			sunny = "{player}! Did you hear? Our biggest one ever!",
			cool = "Okay. Let's go.",
			prickly = "Who orders that much? ...Fine. Fine. I'll do it.",
			dramatic = "The biggest order this island has ever seen!",
			bookish = "If I do forty an hour, that's... a late night. Actually, two.",
			gloomy = "Something will go wrong. Something always does. Starting now.",
			polite = "How kind of them to think of us. I'll do my very best.",
			foodie = "I'll need a snack first. A big one. For energy.",
			nervous = "So many. What if I miss one? What if I miss ten?",
			_ = "{player}, that's the biggest order we've ever had.",
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
			cool = "Holding. For now.",
			prickly = "It's practice. Stop looking at it like that.",
			dramatic = "My tower rises, {player}!",
			bookish = "As long as the middle stays over the base, it can't fall. Actually, it's quite close.",
			gloomy = "It's going to fall. Look at it, {player}. Still standing, though.",
			nervous = "Don't breathe on it, {player}. Please don't breathe on it.",
			_ = "It's practice, {player}. For what, I don't know yet.",
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
				c:say("a", "...Right.", "sweat")
				c:say("a", "Lunch. Then tidy up.", "sweat")
				c:mood("a", -2)
			end
		end)
		s:choice("Quit while it's standing", function(c)
			c:by("a", {
				proud = "Fine. It's perfect as it is anyway.",
				bold = "Fine. I could've done one more, though.",
				nervous = "Oh thank goodness. Yes. Stopping.",
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
		s:say("b", "I got a birthday card for somebody called Edna.", "question")
		s:say("b", "We don't have an Edna.", "question")
		s:by("a", {
			proud = "That was a test of everyone's honesty. Well done, you passed.",
			shy = "I'm so sorry. I'll fix it. I'll fix all of it...",
			easygoing = "Just swap with your neighbours. It'll even out.",
			cool = "...I'll do the round again.",
			prickly = "Don't. I know. I'm fixing it.",
			dramatic = "Chaos! In every letterbox! And it was me!",
			gloomy = "Every one. Of course it was every one.",
			polite = "I'm terribly sorry. I'll come round to each house myself.",
			nervous = "Every house? Even the one with the dog? Oh no.",
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
			prickly = "This is wrong. Fix it. Now, please.",
			dramatic = "I have never been so let down in all my life!",
			gloomy = "Wrong. Of course it's wrong.",
			foodie = "This isn't what I ordered. I ordered the one with the crust.",
			_ = "This is all wrong. I want to speak to whoever's in charge.",
		}, "anger", "point")
		s:by("a", {
			gentle = "I'm sorry it's been a bad day. Let me make it right.",
			bold = "That's me. I'm in charge. What's the problem?",
			proud = "Nothing here is wrong. Except your mood.",
			shy = "I'm s-sorry. What would you like?",
			cheeky = "Have you tried smiling? It's free. Everything else costs.",
			cool = "Okay. What's wrong with it?",
			polite = "I do apologise. Please, tell me how I can help.",
			nervous = "Oh no. Oh no. What did I do? I'll fix it.",
			_ = "Okay. Deep breath. What can I do?",
		}, "sweat")
		if K.isPers(ctx, a, "gentle", "sunny", "shy", "polite") or ctx.rng:chance(0.4) then
			s:say("b", "...Sorry.", "sad")
			s:say("b", "Rough morning. Thank you.", "sad")
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
		s:say("a", "{player}! New at the {place} today.", "idea", "point")
		s:say("a", "It's {thing}. Try it. Be honest.", "idea")
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
			cool = "Have a look.",
			prickly = "Don't tell me which ones you don't like, {player}. Just the good ones.",
			dramatic = "A season of my soul, {player}, on one street!",
			gloomy = "Nobody's stopped yet. You're the first.",
			nervous = "Is it too many? Should I take some down?",
			_ = "Which one's your favourite, {player}? Lie if you have to.",
		}, "sparkle")
		s:choice("The portrait", function(c)
			c:by("a", {
				shy = "That one? You can have it, {player}. If you want.",
				proud = "Good eye. It's yours.",
				prickly = "...That's my favourite too. Take it. Before I change my mind.",
				_ = "That one? It's yours, {player}. No arguing.",
			}, "heart", "cheer")
			c:keep("keep_portrait", "a")
			c:xp("a", 10)
			c:hearts("a", 1)
		end)
		s:choice("All of them", function(c)
			c:by("a", {
				shy = "Really? All of them? ...Thank you.",
				proud = "Of course. They're all good.",
				cool = "...Thanks.",
				gloomy = "You mean that, {player}? Huh. Okay. Thanks.",
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
			cool = "This one's about a gull.",
			dramatic = "This next song... is about a gull. Who dreamed of being a swan!",
			sunny = "Hi everyone! Hi {player}! This one's about a gull!",
			nervous = "Is this on? It's on. Okay. This one's about a gull.",
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
			cool = "Go on.",
			prickly = "Fine. But I'm not writing anything down.",
			bookish = "Can I take notes? I brought three pens.",
			gloomy = "I'll forget it all by tomorrow. Go on, though.",
			polite = "Thank you for teaching me. I'll do my best.",
			nervous = "Is there a test? Please say there's no test.",
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
			cool = "You're fine.",
			prickly = "You're fine. Stop worrying. ...Drink more water.",
			bookish = "All normal. Actually, better than normal. Keep walking every day.",
			gloomy = "You're healthy. Which surprised me, honestly.",
			polite = "Thank you for coming in. Everything looks well.",
			foodie = "All good. Eat more greens. And soup. Soup counts.",
			nervous = "All fine, I think. Let me check again. Yes. Fine.",
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
				cool = "...Abstract.",
				prickly = "Don't. It tastes the same.",
				dramatic = "My heart, {player}! It became a potato!",
				gloomy = "That's about how my week's going.",
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
			shy = "Ten years... I don't even know what the fine is for that.",
			cool = "Ten years. Huh.",
			bookish = "Ten years. Actually, ten years and four days.",
			dramatic = "A DECADE, {player}! It's been gone a decade!",
			_ = "Ten years. TEN. The fine on this would buy a boat.",
		}, "anger")
		s:by("a", {
			gentle = "There's a note inside. It says sorry, and that they loved it.",
			proud = "I'll be framing the date stamp.",
			gloomy = "They looked after it, at least. More than most.",
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
			cool = "It's big.",
			dramatic = "It's taller than me, {player}!",
			nervous = "Will it fit through the door? I didn't measure the door.",
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
		s:say("a", "New flavour. {flavour}.", "idea", "point")
		s:say("a", "First scoop's free, {player}.", "idea")
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
				prickly = "Vanilla. Wow. Fine.",
				foodie = "Vanilla's a classic, {player}. But you're missing out. A lot.",
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
		s:say("b", "Don't ask.", "sweat")
		s:say("b", "Something exploded at the {pb}. Only a little.", "sweat")
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
			shy = "Oh no oh no oh no...",
			cool = "...Well.",
			prickly = "Don't help. I've got it. ...Okay, help.",
			dramatic = "Ruin! Everywhere!",
			gloomy = "There goes the morning.",
			polite = "I'm so sorry, everyone. Please mind your feet.",
			nervous = "Did anything break? Is anyone hurt? Is it just me?",
			_ = "Well, {player}. Now it's a floor display.",
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
		s:n("The customers at the {place} put {a}'s name on a little board. Worker of the month.")
		s:by("a", {
			proud = "Only of the month?",
			shy = "Me? Really? I'm going to cry a bit...",
			easygoing = "Huh. I'll take it. Can I have the afternoon off?",
			sunny = "{player}! Look! My name! On a board!",
			cool = "Nice.",
			prickly = "It's just a board. ...I'm taking a picture of it.",
			dramatic = "Recognised at last!",
			gloomy = "Me? Huh. That's... actually nice.",
			polite = "Thank you, everyone. I'm very grateful.",
			nervous = "Are they sure? It's not a mistake? Okay. Wow.",
			_ = "I'm putting this on my fridge, {player}.",
		}, "sparkle", "cheer")
		s:xp("a", 20)
		s:mood("a", 6)
		s:log("{a} was worker of the month at the {place}.")
		return s:done()
	end,
})

-- more working days -----------------------------------------------------------------------------

event({
	id = "lunchrush",
	cutscene = "stall",
	when = "day",
	weight = W({
		base = 0.2,
		job = "any",
		cond = function(ctx)
			return ctx.hour >= 11 and ctx.hour < 15
		end,
	}),
	scene = function(ctx, a)
		local coins = share(ctx, a, 0.7)
		local s = K.scene(ctx, "The lunch rush"):with({ place = place(ctx, a), coins = coins })
		s:n("Twelve o'clock, and the whole town turned up at the {place} at once.")
		s:by("a", {
			sunny = "Hi! Hi! Yes! One moment! Hi!",
			gentle = "One at a time, there's plenty for everyone.",
			bold = "Next. Next. NEXT.",
			dreamy = "So many faces... who was first again?",
			easygoing = "Okay. Breathe. Everyone gets served eventually.",
			proud = "They know where the good stuff is.",
			shy = "Um. Who's next? Sorry. Who's next?",
			cheeky = "Form a queue! Or a circle. I'm not fussy.",
			cool = "Next.",
			prickly = "Line up properly or nobody gets anything.",
			dramatic = "The hordes descend, {player}!",
			bookish = "Forty two people in ten minutes. That's a record. Actually, I'm counting.",
			gloomy = "Here they come. All of them.",
			polite = "Thank you for waiting. Thank you. Thank you so much.",
			foodie = "Everyone's hungry at once. I get it. I really get it.",
			nervous = "So many. Don't drop anything. Don't drop anything.",
			_ = "Okay. One at a time. One at a time.",
		}, "sweat")
		s:n("By one o'clock it was quiet again. The till had {coins} more coins in it.")
		s:coins(coins)
		s:xp("a", 12)
		s:mood("a", 2)
		s:log("{a} got through the lunch rush at the {place}.")
		return s:done()
	end,
})

event({
	id = "regular",
	actors = 2,
	when = "day",
	weight = W({ base = 0.18, job = "any" }),
	scene = function(ctx, a, b)
		local s = K.scene(ctx, "The usual"):with({ place = place(ctx, a) })
		s:n("{b} has come into the {place} every day this week at exactly ten past ten.")
		s:by("a", {
			sunny = "Morning! The usual? I've already started it.",
			gentle = "Good morning, {b}. Your usual's ready.",
			cool = "Usual?",
			prickly = "Ten past ten. Every day. ...It's ready. Obviously.",
			dramatic = "My most loyal customer returns!",
			bookish = "Ten past ten. You could set a clock by you. Actually, I have.",
			polite = "Good morning. The same as yesterday?",
			_ = "Morning. The usual?",
		}, "wave")
		s:by("b", {
			shy = "Oh. You remembered... yes, please.",
			easygoing = "You know me too well.",
			proud = "Of course. Why change perfection?",
			foodie = "The usual. And maybe one extra. As a treat. For me.",
			nervous = "Yes. Is that weird? Coming every day? Is it weird?",
			gloomy = "Yeah. It's the only thing I'm sure of.",
			_ = "The usual. Thanks.",
		}, "heart")
		s:rel(5)
		s:xp("a", 6)
		s:memo("b", "{a} has my usual ready before I get there now.")
		s:log("{b} is a regular at {a}'s {place}.")
		return s:done()
	end,
})

local TRICKS = {
	baker = "plaiting a loaf into six strands",
	barista = "pouring a little leaf into the foam",
	icecream = "scooping a ball so round it rolls",
	shopkeeper = "stacking apples into a pyramid that doesn't fall",
	florist = "tying a bow with one hand",
	postie = "sorting a whole bag without looking at the street names",
	builder = "laying a brick with one tap of the trowel",
	artist = "mixing the exact grey of the harbour on a cloudy day",
	musician = "playing a song backwards, by ear",
	teacher = "remembering everyone's name after hearing it once",
	doctor = "taking a pulse without looking at the clock",
	librarian = "finding any book on the shelves in under a minute",
}

event({
	id = "newtrick",
	when = "day",
	weight = W({ base = 0.18, job = "any", traits = { focus = 0.3 } }),
	scene = function(ctx, a)
		local w = ctx.job(a)
		local s = K.scene(ctx, "A new trick")
			:with({ trick = TRICKS[w.job.id] or "doing the job a little faster", place = place(ctx, a) })
		s:n("{a} has been practising {trick} at the {place} all week. Today it finally worked.")
		s:say("a", "{player}. Watch this.", "idea", "point")
		s:by("a", {
			sunny = "Did you see, {player}? Did you see it? Again, again!",
			gentle = "There. It took me a while, but there.",
			bold = "Got it. Took a week. Got it.",
			dreamy = "My hands knew before I did.",
			easygoing = "Huh. That was easier than I thought.",
			proud = "And that's how a professional does it.",
			shy = "I did it... I actually did it.",
			cheeky = "Now I'm going to show off to every single customer.",
			cool = "Yeah. Got it.",
			prickly = "Don't clap, {player}. ...Okay, a little clap.",
			dramatic = "Mastery! At last!",
			bookish = "The trick was in the wrist. Actually, it's always in the wrist.",
			gloomy = "I'll probably forget how by tomorrow. But today, I've got it.",
			polite = "Thank you for watching, {player}. It means a lot.",
			foodie = "I'm celebrating with a bun. Two buns.",
			nervous = "Was it right? It looked right. Did it look right?",
			_ = "I've been trying that all week.",
		}, "sparkle", "cheer")
		s:xp("a", 20)
		s:mood("a", 4)
		s:memo("a", "I learned a new trick at work. Want to see it again?")
		s:log("{a} learned a new trick at the {place}.")
		return s:done()
	end,
})

event({
	id = "wrongorder",
	actors = 2,
	when = "day",
	weight = W({ base = 0.18, job = "any", traits = { focus = -0.3 } }),
	scene = function(ctx, a, b)
		local s = K.scene(ctx, "The wrong order"):with({ place = place(ctx, a) })
		s:n("{b} asked for one thing at the {place}. {a} handed over something else entirely.")
		s:by("b", {
			cool = "This isn't mine.",
			prickly = "That's not what I said. At all.",
			polite = "Sorry to bother you, but I think this might be someone else's?",
			nervous = "Um. Is this... did I say it wrong? I might have said it wrong.",
			_ = "Um. This isn't what I asked for.",
		}, "question")
		s:by("a", {
			shy = "Oh no. Sorry. Sorry...",
			proud = "That's an upgrade. You're welcome.",
			cheeky = "Surprise! ...No? Okay.",
			gloomy = "Of course. Sorry.",
			dramatic = "A terrible mistake!",
			_ = "Oh. Oh, sorry.",
		}, "sweat")
		s:choice("Make it again", function(c)
			c:n("{a} made it again, properly this time, and threw in a little extra.")
			c:by("b", {
				prickly = "...Fine. That's better. Thanks.",
				polite = "Thank you so much. That's very kind.",
				_ = "Thanks. That's the one.",
			}, "heart")
			c:xp("a", 6)
			c:rel(4)
		end)
		s:choice("They might like it", function(c)
			if ctx.rng:chance(0.5) then
				c:n("{b} tried it. Then tried it again.")
				c:by("b", {
					foodie = "Oh. Oh, this is better than what I wanted.",
					cool = "...This is good, actually.",
					_ = "Huh. I like this more.",
				}, "sparkle")
				c:rel(6)
				c:mood("b", 3)
			else
				c:n("{b} tried it, swallowed hard and said nothing at all.")
				c:rel(-2)
			end
		end)
		s:log("{a} gave {b} the wrong order at the {place}.")
		return s:done()
	end,
})

event({
	id = "slowday",
	when = "day",
	weight = W({ base = 0.16, job = "any", weather = { "rain", "storm", "cloudy", "snow" } }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "A slow day"):with({ place = place(ctx, a) })
		s:n("Not one customer at the {place} all morning. {a} has tidied everything twice.")
		s:by("a", {
			sunny = "{player}! A person! Hi! Come in, come in!",
			easygoing = "Honestly? I don't mind. I've had a lovely sit.",
			proud = "I've rearranged it by colour. Then by size. Then back.",
			cool = "Quiet one.",
			prickly = "Don't come in out of pity, {player}. ...Come in, though.",
			dramatic = "Alone, {player}. Utterly alone.",
			bookish = "I've been reading the labels. All of them. Some are very interesting.",
			gloomy = "This is how it'll be now. Forever.",
			foodie = "I've eaten my lunch. And my snack. And my second lunch.",
			nervous = "Is everything okay? Is it me? Is it something I did?",
			_ = "It's the weather. Nobody wants to come out.",
		}, "zzz")
		s:xp("a", 5)
		s:mood("a", -1)
		s:log("{a} had a slow day at the {place}.")
		return s:done()
	end,
})

local LEFT = { "a straw hat", "a striped scarf", "a red umbrella", "a library book", "one glove" }

event({
	id = "leftbehind",
	when = "day",
	weight = W({ base = 0.15, job = "any" }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "Left behind"):with({ thing = ctx.rng:pick(LEFT), place = place(ctx, a) })
		s:n("Someone left {thing} on the counter at the {place}.")
		s:by("a", {
			gentle = "Oh, someone will miss that.",
			bold = "They can't have gone far.",
			cool = "Someone's coming back for that.",
			prickly = "People. Always leaving things. Every single day.",
			bookish = "I've seen that on someone. Tall, blue coat. Went towards the harbour.",
			nervous = "What if they need it? What if it's their only one?",
			_ = "Whose is this? {player}, did you see who left it?",
		}, "question")
		s:choice("Run after them", function(c)
			c:n("{a} caught them at the end of the street, out of breath.")
			c:say("a", "Got them. They were so pleased.", "heart", "cheer")
			c:mood("a", 4)
			c:all(1)
		end)
		s:choice("Put it in the lost box", function(c)
			c:n("It went in the box under the counter, with the other forty things.")
			c:by("a", {
				gloomy = "Nobody ever comes back for anything in here.",
				_ = "They'll be back. People always come back.",
			}, "zzz")
			c:xp("a", 3)
		end)
		s:log("Someone left {thing} at {a}'s {place}.")
		return s:done()
	end,
})

event({
	id = "helper",
	actors = 2,
	when = "day",
	weight = W({
		base = 0.2,
		job = "any",
		cond = function(ctx, a, b)
			return b ~= nil and ctx.job(b) == nil
		end,
	}),
	scene = function(ctx, a, b)
		local s = K.scene(ctx, "A spare pair of hands"):with({ place = place(ctx, a) })
		s:n("{b} has been hanging round the {place} all morning, watching {a} work.")
		s:by("b", {
			shy = "Um. Could I help? I'll just hold things.",
			bold = "Give me something to do. Anything.",
			sunny = "Can I help? Please? I'll be really good!",
			cool = "Need a hand?",
			prickly = "I'm bored. Give me a job. Don't make a big deal of it.",
			polite = "Might I help, if it's no trouble?",
			nervous = "I could help? If that's okay? I might drop things.",
			_ = "Can I help? I've got nothing on.",
		}, "question")
		s:choice("Let them help for the day", function(c)
			c:n("{b} stayed till closing. They only broke one thing, and it was already cracked.")
			c:by("a", {
				proud = "Not bad. You might have a gift for this.",
				gentle = "Thank you, {b}. That was a big help.",
				cool = "Good work.",
				prickly = "You were fine. Come back tomorrow if you want. Whatever.",
				_ = "Thanks. Come back any time.",
			}, "heart")
			c:xp("b", 20)
			c:xp("a", 5)
			c:rel(6)
			c:mood("b", 5)
		end)
		s:choice("Maybe another day", function(c)
			c:say("b", "Okay. Another day.", "sad")
			c:mood("b", -2)
		end)
		s:log("{b} helped {a} at the {place}.")
		return s:done()
	end,
})

event({
	id = "earlyoven",
	when = "day",
	weight = W({
		base = 0.35,
		job = "baker",
		cond = function(ctx)
			return ctx.hour < 11
		end,
	}),
	scene = function(ctx, a)
		local s = K.scene(ctx, "Four in the morning")
		s:prop("bakes", "a")
		s:n("{a} has been up since four. The first trays are out and the street is starting to smell of it.")
		s:by("a", {
			sunny = "{player}! You're up early too! Here, first roll's yours!",
			gentle = "Morning. Here, take one while they're warm.",
			bold = "Six trays done. Four to go.",
			dreamy = "The town's still asleep. Just me and the oven.",
			easygoing = "I sleep in the afternoons. It works out.",
			proud = "Best part of the day. Nobody to see me be brilliant.",
			shy = "Oh. Morning... you're the first one up.",
			cheeky = "Don't tell anyone, but the first batch is always the best.",
			cool = "Morning. Roll?",
			prickly = "Don't talk to me till the third tray. ...Here. Roll.",
			dramatic = "While the town sleeps, the baker toils!",
			bookish = "The dough rises faster when it's warm. Actually, that's why I start so early.",
			gloomy = "Four o'clock. Every day. It's fine. I like the quiet.",
			polite = "Good morning. Please, have one. On the house.",
			foodie = "I've already eaten two. Quality control.",
			nervous = "Is that one burnt? It's not burnt. Is it?",
			_ = "Morning. Take one while they're hot.",
		}, "heart")
		s:xp("a", 10)
		s:mood("a", 2)
		s:log("{a} was up at four baking.")
		return s:done()
	end,
})

event({
	id = "postforyou",
	when = "day",
	weight = W({ base = 0.3, job = "postie" }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "Post for you")
		s:prop("parcels", "a")
		s:n("{a} stops you halfway down the street, digging in the bag.")
		s:by("a", {
			sunny = "{player}! Wait! There's one for you!",
			gentle = "{player}, there's a card for you. Here.",
			bold = "One for you. Here.",
			proud = "Delivered to your hand. Not even your door.",
			shy = "Um. {player}? This is yours.",
			cheeky = "I didn't read it. I read it a little.",
			cool = "Yours.",
			prickly = "Here. Yours. Don't make me walk to your door.",
			dramatic = "A letter, {player}! From afar!",
			nervous = "This is yours. I checked. Twice. It's yours.",
			_ = "{player}, one for you.",
		}, "wave")
		s:n("It's a postcard from a tourist who came through last month. There are coins taped to the back.")
		s:n("'Lovely town. Buy the baker something from me.'")
		s:coins(30)
		s:xp("a", 5)
		s:log("A tourist sent a postcard and some coins for the town.")
		return s:done()
	end,
})

event({
	id = "foamname",
	when = "day",
	weight = W({ base = 0.3, job = "barista" }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "Your name in the foam")
		s:n("{a} slides a cup across the counter. Your name is written on top in foam.")
		s:by("a", {
			sunny = "Ta da! {player}! I practised all morning!",
			gentle = "I hope you like it, {player}.",
			bold = "Your name. In foam. Drink it.",
			dreamy = "The letters will float away if you wait.",
			proud = "Perfect lettering. You're welcome.",
			shy = "It's a bit wobbly... sorry.",
			cheeky = "I spelled it right this time. I think. Look.",
			cool = "Made you one.",
			prickly = "It's just a coffee. Don't make a face.",
			dramatic = "Your name, {player}! Written in milk!",
			nervous = "Is it spelled right? Please say it's spelled right.",
			_ = "One for you, {player}.",
		}, "heart")
		s:choice("Drink it", function(c)
			c:say("a", "Ha. Now you've got a moustache.", "laugh")
			c:hearts("a", 1)
			c:xp("a", 5)
		end)
		s:choice("Wait, let me look at it first", function(c)
			c:by("a", {
				proud = "Take your time. It's a work of art.",
				shy = "Oh... you like it? Okay. Good.",
				_ = "Hehe. Go on. Before it melts.",
			}, "sparkle")
			c:hearts("a", 1)
			c:mood("a", 3)
		end)
		s:log("{a} wrote your name in the foam.")
		return s:done()
	end,
})

event({
	id = "melting",
	when = "day",
	weight = W({ base = 0.35, job = "icecream", season = 2, weather = "clear" }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "Melting")
		s:n("It's so hot that the ice cream at {a}'s cart is melting faster than it can be sold.")
		s:by("a", {
			sunny = "{player}! Help! It's all going runny!",
			bold = "Right. Everyone gets one. Now.",
			cool = "It's going.",
			prickly = "Don't stand there. Eat something. Help me out.",
			dramatic = "It melts before my eyes!",
			gloomy = "It's all going. Like everything.",
			foodie = "I can't let it go to waste. I'll eat it. I'll eat all of it.",
			nervous = "What do I do? Do I sell it cheap? Do I give it away?",
			_ = "It's melting faster than I can scoop, {player}.",
		}, "sweat")
		s:choice("Hand out free cones", function(c)
			c:n("{a} gave a cone to everyone in the square before it could melt. Some people had three.")
			c:all(3)
			c:mood("a", 4)
			c:xp("a", 5)
		end)
		s:choice("Close early and save what's left", function(c)
			c:n("{a} put the lid down and pushed the cart into the shade.")
			c:say("a", "Back tonight. When it's cool.", "zzz")
			c:coins(share(ctx, a, 0.3))
		end)
		s:log("Ice cream melted at {a}'s cart on a hot day.")
		return s:done()
	end,
})

event({
	id = "muralwall",
	when = "day",
	weight = W({ base = 0.3, job = "artist" }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "A wall to paint")
		s:prop("mural", "a")
		s:n("{a} has started a painting on the side of the bakery. It's the harbour, with all the boats in.")
		s:by("a", {
			sunny = "{player}! What should go in the corner? Pick something!",
			proud = "When it's done people will come from other islands.",
			shy = "I left a gap... I didn't know what to put there.",
			cool = "There's a gap. Ideas?",
			prickly = "Don't say 'a gull'. ...Okay, you can say 'a gull'.",
			dramatic = "A wall becomes a window, {player}!",
			bookish = "Outdoor paint takes two days to cure. Actually, three if it rains.",
			gloomy = "It'll fade in the sun. Give it ten years. Still.",
			foodie = "It's going to have a bun in it somewhere. A big bun.",
			nervous = "Is it okay that it's on the bakery? I asked. They said yes. I think.",
			_ = "There's a corner left, {player}. What goes there?",
		}, "question")
		s:choice("A gull", function(c)
			c:n("{a} painted a gull in the corner, holding a chip.")
			c:say("a", "Perfect. It's very us.", "sparkle", "cheer")
			c:xp("a", 15)
			c:all(2)
		end)
		s:choice("You", function(c)
			c:n("{a} painted themselves in the corner, very small, waving.")
			c:by("a", {
				shy = "Is that too much? It's tiny. It's fine.",
				proud = "Every great painting has the artist in it somewhere.",
				_ = "Ha. Okay. A tiny me.",
			}, "sweat")
			c:xp("a", 15)
			c:mood("a", 5)
		end)
		s:log("{a} painted a picture of the harbour on the bakery wall.")
		return s:done()
	end,
})

event({
	id = "beforerain",
	when = "day",
	weight = W({ base = 0.4, job = "builder", weather = { "cloudy", "rain" } }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "Before the rain")
		s:prop("bricks", "a")
		s:n("The sky's going dark and {a} has half a wall still to finish.")
		s:by("a", {
			bold = "Twenty minutes. I can do it in twenty minutes.",
			sunny = "{player}! Grab a bucket? Pretty please?",
			cool = "Gonna be close.",
			prickly = "Don't just stand there. Pass me that.",
			dramatic = "A race against the sky!",
			gloomy = "It's going to rain right on the wet mortar. I know it.",
			nervous = "Is that thunder? Was that thunder? Hurry, hurry.",
			_ = "If it rains on this before it sets, I'm starting again.",
		}, "sweat")
		s:choice("Pass them bricks", function(c)
			c:n("You passed bricks. {a} laid them. The last one went in as the first drop fell.")
			c:say("a", "Done. Just.", "sparkle", "cheer")
			c:say("a", "Thanks, {player}. Tea's on me.", "heart")
			c:xp("a", 15)
			c:hearts("a", 1)
		end)
		s:choice("Throw a sheet over it", function(c)
			c:n("A big sheet and four bricks on the corners. It'll keep till morning.")
			c:say("a", "Good idea. I'll finish it tomorrow.", "idea")
			c:xp("a", 5)
			c:mood("a", 2)
		end)
		s:log("{a} raced the rain to finish a wall.")
		return s:done()
	end,
})

event({
	id = "readinghour",
	when = "day",
	weight = W({ base = 0.3, job = "librarian", count = 2 }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "Reading hour")
		s:n("It's reading hour at the library. {a} reads a story out loud to whoever turns up.")
		local who = nil
		for _, vid in ctx.present do
			if vid ~= a then
				who = vid
				break
			end
		end
		if who then
			s:with({ x = ctx.v(who).name })
			s:n("Today it's {x}, two pigeons on the windowsill, and you.")
		end
		s:by("a", {
			sunny = "Okay! Chapter four! The best one!",
			gentle = "Get comfy. This one's a nice one.",
			cool = "Chapter four.",
			prickly = "No talking. ...Unless it's a good question.",
			dramatic = "And now. The storm. The ship. The lighthouse.",
			bookish = "This is the first edition. Actually, the words are a bit different from the new one.",
			gloomy = "It's sad, this bit. Fair warning.",
			polite = "Thank you all for coming. Let's begin.",
			nervous = "Can everyone hear? Should I be louder? Okay. Chapter four.",
			_ = "Chapter four. Where were we.",
		}, "music")
		s:xp("a", 12)
		s:all(2)
		s:log("{a} held reading hour at the library.")
		return s:done()
	end,
})

event({
	id = "drinkwater",
	when = "day",
	weight = W({ base = 0.3, job = "doctor" }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "Doctor's orders")
		s:n("{a} stops you in the street and looks at you closely.")
		s:say("a", "{player}. When did you last drink some water?", "question", "point")
		s:by("a", {
			sunny = "You've been building all day! I saw you! Water, now!",
			gentle = "You look a bit tired. Look after yourself, won't you?",
			bold = "That long? Drink. Now.",
			proud = "Doctor's orders. And I'm a very good doctor.",
			cool = "Drink something.",
			prickly = "I'm not fussing. I'm just saying. Drink something. Today.",
			dramatic = "You're wilting, {player}! Like a flower!",
			bookish = "Most people need about two litres. Actually, more when it's warm.",
			gloomy = "You'll get a headache. People always do.",
			polite = "Forgive me for asking. Please do drink something soon.",
			foodie = "And eat something too. Something with soup in it.",
			nervous = "You're okay, right? You look okay. Just checking.",
			_ = "Drink some water. Doctor's orders.",
		}, "sweat")
		s:choice("Drink some water", function(c)
			c:n("{a} watched you drink a whole glass.")
			c:say("a", "Good. Same time tomorrow.", "heart")
			c:hearts("a", 1)
			c:xp("a", 5)
		end)
		s:choice("Later, promise", function(c)
			c:by("a", {
				prickly = "'Later.' Right. I'll be checking.",
				nervous = "You promise? Okay. I'll ask again later. Just in case.",
				_ = "I'll hold you to that.",
			}, "question")
			c:xp("a", 3)
		end)
		s:log("{a} told you to drink some water.")
		return s:done()
	end,
})

return list
