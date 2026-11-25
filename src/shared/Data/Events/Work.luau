--!nonstrict
-- At work: a big order, the builder's tower of bricks, letters to the wrong houses, a grumpy
-- customer, a new flavour, an art show, a concert, a lesson, a check up, latte art, a book back
-- ten years late, the lunch rush, a regular, a new trick, the wrong order, a slow day. Each needs
-- a villager with a job (Data/Jobs), and what it pays comes from the job's own income, so it
-- stays in step with wages. The villagers text the way a friend does: one natural sentence a
-- message, two or three messages at a time, each personality with its own habits, and now and
-- then your name ({player}). A workplace's name ({place}) is a thing such as "bread oven" or
-- "chalkboard", so a line says "at the {place}" or "by the {place}", never "into" it.

local K = require(script.Parent.Kit)
local Tuning = require(script.Parent.Parent.Parent.Config.Tuning)

local W = K.W

local list = {}
local function event(def)
	def.actors = def.actors or 1
	table.insert(list, def)
end

-- A burst: what they'd send as two or three quick messages (Kit's s:burst: a line or a map
-- keyed by personality, "|" between the messages).
local function burst(s, who: string, map: any, icon: string?, gesture: string?)
	return s:burst(who, map, icon, gesture)
end

-- How they take it when the thing they tried comes off (a brick tower that holds, a new thing
-- that tastes good, a heart in the foam).
local BRAG = {
	sunny = "Did you see that, did you see it?|Ehehe! I'm telling everyone at lunch.",
	proud = "Hmph, naturally it worked.|Go on, you can say it was impressive.",
	bold = "Hah, I told you I could do it.|That's how it's done, right?",
	shy = "...!|Um, it worked, and you were here to see it.",
	cheeky = "ok that was actually amazing|tell me i'm amazing, go on",
	cool = "That came out exactly the way I wanted.",
	prickly = "Ugh, don't make a fuss about it.|...It was good, though, wasn't it?",
	dramatic = "*gasp* Did everyone SEE that?|I'd like this moment painted, please.",
	bookish = "It went exactly the way I planned it on paper.|I'm writing down what I did before I forget.",
	gloomy = "Huh, it actually worked.|That doesn't happen to me very often.",
	gentle = "Oh, my, it worked.|I'm so glad you were here to see it.",
	dreamy = "Hmm... it worked, and I wasn't even sure what I was doing.|It's like my hands knew before I did.",
	easygoing = "Mm, not bad for someone who's barely awake.|I'll take that.",
	polite = "Oh, how pleasing.|Thank you kindly for watching.",
	foodie = "Mmm, that calls for a treat.|I'm having a bun at lunch to celebrate.",
	nervous = "I-it worked?|It worked, and nothing went wrong at all!",
	_ = "It worked, did you see?|I'm really pleased with that.",
}

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
	barista = { "bakes", "sixty coffees for the ferry crew, all made differently" },
	icecream = { "bakes", "ice cream for a whole school trip" },
	shopkeeper = { "parcels", "a whole cart of apples for the cider maker" },
	florist = { "bouquet", "flowers for every table at the harvest supper" },
	postie = { "parcels", "a mountain of parcels to send before the holidays" },
	builder = { "bricks", "a new garden wall for the town hall" },
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
		s:n("A huge order came in at the {place}, {order}.")
		burst(s, "a", {
			bold = "Hah, I'll have that done by lunch, easily.",
			easygoing = "Mm, that's more than I usually do in a week.|I'll panic about it slowly, if that's all right.",
			proud = "Hmph, of course they came to us, we're the best on the island.|I'll make sure every single one is perfect.",
			shy = "Um... that's so many.|What if I get some of them wrong?",
			sunny = "{player}, did you hear, did you hear?|It's the biggest order we've ever had!",
			cool = "That's a big one, {player}, but it's doable if I start now.",
			prickly = "Ugh, who even orders that much at once?|Fine, I'll do it, but I'm not smiling about it.",
			dramatic = "This is the biggest order in the history of this island!|I may need to lie down first.",
			bookish = "If I manage forty an hour, it'll take me most of the night.|Actually, make that two nights.",
			gloomy = "Something's going to go wrong with this, it always does.|Heh... I'll start anyway.",
			polite = "How very kind of them to think of us.|I'll do my very best with it.",
			foodie = "I'm going to need a proper lunch before I start this.|You can't do a job this size on an empty stomach.",
			nervous = "Oh no, oh no, what if I miss one?|What if I miss ten and they never order again?",
			gentle = "Oh, my, that's a lot.|We'll manage it if we take it one bit at a time.",
			dreamy = "Hmm... that's more than I can picture all at once.|I'll do the first one and see how it goes.",
			cheeky = "guess who just got the biggest order ever|and yes, i'm going to brag about it all week",
			_ = "{player}, that's the biggest order we've ever had.|I'd better get started.",
		}, "sweat")
		s:choice("Stay late and get it done.", function(c)
			c:n("{a} worked until the stars came out, and the order went out on time.")
			c:voice("a", "tired", "zzz")
			c:coins(coins)
			c:xp("a", 25)
			c:mood("a", -2)
			c:memo("a", "We finished that big order in the end, and my arms still ache from it.")
		end)
		s:choice("Only take what you can manage.", function(c)
			c:n("{a} took on half of it, and the customer was happy enough with that.")
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
		s:n("{a} has been stacking spare bricks in the yard all week, and the tower is taller than a door now.")
		burst(s, "a", {
			bold = "One more brick and it'll be taller than me, right?",
			proud = "It's all down to careful engineering, you know.|Go on, you can say it's impressive.",
			cheeky = "if it falls over, i was never here|you didn't see anything",
			cool = "Hm, it's holding for now.|I wouldn't stand too close, though.",
			prickly = "It's practice, so stop looking at it like that.|...Fine, it's also a bit fun.",
			dramatic = "Behold, {player}, my tower rises over the yard!",
			bookish = "As long as the middle stays over the base, it can't fall.|It's getting quite close to the edge, though.",
			gloomy = "It's going to fall, I just know it.|Heh... it's still standing for now.",
			nervous = "Please don't breathe on it, {player}.|I-I mean it, it's wobbling already.",
			sunny = "{player}, look, look, it's taller than the door!|Let's see how high it goes!",
			_ = "I've been calling it practice, {player}.|I'm not sure what it's practice for, though.",
		}, "sparkle", "point")
		s:choice("Add one more brick.", function(c)
			if ctx.rng:chance(0.5) then
				c:n("It wobbled for a second, and then it held.")
				burst(c, "a", BRAG, "sparkle", "cheer")
				c:xp("a", 15)
				c:mood("a", 5)
				c:leave("bricks", 8, "a")
			else
				c:n("The tower came down, and bricks went all over the yard.")
				burst(c, "a", "Right... I think I'll have lunch first.|Then I'll tidy all this up.", "sweat")
				c:mood("a", -2)
			end
		end)
		s:choice("Stop while it's standing.", function(c)
			burst(c, "a", {
				proud = "Fine, it's perfect as it is anyway.",
				bold = "Fine, but I could've done one more, you know.",
				nervous = "Oh, thank goodness.|Yes, let's stop while it's still up.",
				_ = "Good idea, let's stop there.|I'll leave it up so people can see it.",
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
		s:n("{a} mixed up two bags this morning, and every letter in town went to the wrong house.")
		burst(
			s,
			"b",
			"I got a birthday card for somebody called Edna this morning.|Nobody called Edna lives in this town.",
			"question"
		)
		burst(s, "a", {
			proud = "Th-that was a test of everyone's honesty.|And you passed, so well done.",
			shy = "I'm so sorry about that.|I'll go round again and fix every single one.",
			easygoing = "Mm, just swap with your neighbours and it'll all even out.|I'll do the round again after lunch.",
			cool = "I'll do the whole round again this afternoon.|Leave the wrong ones on your step.",
			prickly = "Ugh, don't say it, I already know.|I'm fixing it right now.",
			dramatic = "Every letterbox in town, and it was me!|I'll never live this down.",
			gloomy = "Every single one, as usual.|Heh... at least I'm consistent.",
			polite = "I'm terribly sorry about that.|I'll come round to every house myself and swap them back.",
			nervous = "Every house, even the one with the big dog?|Oh no, oh no.",
			_ = "I'll do the round again this afternoon.|Sorry about Edna's card.",
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
		s:n("{b} came up to {a} at the {place} in a very bad mood.")
		burst(s, "b", {
			proud = "This is not what I asked for at all.|I'd like to speak to whoever's in charge.",
			bold = "This is all wrong, so who's in charge here?",
			cheeky = "is it meant to be like this|because it really isn't great",
			prickly = "Ugh, this is wrong.|Fix it, please, and quickly.",
			dramatic = "I have never been so let down in all my LIFE!",
			gloomy = "It's wrong, as usual.|I don't know why I expected anything else.",
			foodie = "I came all this way before lunch, and it's still not right.",
			_ = "This is all wrong.|I'd like to talk to whoever's in charge, please.",
		}, "anger", "point")
		burst(s, "a", {
			gentle = "Oh, my, I'm sorry you've had a bad day.|Let me put it right for you, all right?",
			bold = "That's me, I'm in charge.|So what's the problem?",
			proud = "Hmph, there's nothing wrong with it except your mood.",
			shy = "Um... I'm sorry.|What would you like me to change?",
			cheeky = "have you tried smiling? it's free|everything else here costs money, though",
			cool = "Tell me exactly what's wrong with it, and I'll fix it.",
			polite = "I do apologise.|Please tell me how I can put it right.",
			nervous = "Oh no, what did I do?|I'll fix it, I promise, just tell me what's wrong.",
			_ = "Okay, let's take a deep breath.|What can I do to help?",
		}, "sweat")
		if K.isPers(ctx, a, "gentle", "sunny", "shy", "polite") or ctx.rng:chance(0.4) then
			burst(s, "b", "...Sorry, I've had a rough morning.|Thank you for being patient with me.", "sad")
			s:rel(5)
			s:xp("a", 10)
		else
			s:say("b", "Fine, I'll go somewhere else next time.", "anger")
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
	shopkeeper = "jam made from the plums on the hill",
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
		burst(s, "a", {
			sunny = "{player}, {player}, there's something new at the {place} today!|It's {thing}, and you have to try it!",
			proud = "{player}, I've made something new at the {place}.|It's {thing}, and you may have the first taste.",
			shy = "Um, {player}... I made something new.|It's {thing}, but you don't have to try it if you don't want to.",
			cool = "{player}, there's something new at the {place}.|It's {thing}, so tell me what you think.",
			cheeky = "new thing at the {place} today|it's {thing}, and you're my taste tester, sorry",
			gentle = "I've been working on something new, {player}.|It's {thing}, would you like the first taste?",
			foodie = "Mmm, {player}, you have to try this.|It's {thing}, and I've already had three.",
			nervous = "{player}, c-could you try something for me?|It's {thing}, and I can't tell if it's good or terrible.",
			dramatic = "*gasp* {player}, you're just in time for my newest creation!|It's {thing}, and it might change your life.",
			bookish = "{player}, I've been testing a new recipe at the {place}.|It's {thing}, and I'd like an honest opinion.",
			_ = "{player}, there's something new at the {place} today.|It's {thing}, so be honest with me.",
		}, "idea", "point")
		s:choice("I'd love to try it.", function(c)
			if ctx.rng:chance(0.6) then
				c:n("It tastes really good.")
				burst(c, "a", BRAG, "sparkle", "cheer")
				c:coins(share(ctx, a, 0.6))
				c:xp("a", 15)
				c:mood("a", 5)
			else
				c:n("You took a slow mouthful, and {a} watched your face the whole while.")
				burst(c, "a", "...Okay, I can see it on your face.|I'll take it off the board for now.", "sweat")
				c:xp("a", 5)
			end
		end)
		s:choice("Maybe tomorrow?", function(c)
			burst(c, "a", "All right, tomorrow, then.|There's plenty left, so I'll save you some.", "sad")
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
		burst(s, "a", {
			proud = "Every one of these is a masterpiece.|Well, some of them more than others.",
			shy = "Um... please say something about them.|Even just 'hm' is fine.",
			dreamy = "This one's the harbour on a foggy morning.|I sat on the wall for hours to paint it.",
			cool = "Have a look around.|Tell me if one stands out.",
			prickly = "Don't tell me which ones you don't like.|Only tell me the good ones, okay?",
			dramatic = "A whole season of my SOUL, {player}, hung on one street!",
			gloomy = "Nobody's stopped to look yet, so you're the first.|Heh... thanks for that.",
			nervous = "Are there too many?|Should I take some of them down?",
			sunny = "{player}, come and look, I hung them all up myself!|Which one do you like best?",
			bookish = "I've hung them in the order I painted them, actually.|You can see the season change as you walk along.",
			_ = "Which one's your favourite, {player}?|You can lie if you have to.",
		}, "sparkle")
		s:choice("I like the portrait best.", function(c)
			burst(c, "a", {
				shy = "That one?|...!|You can have it, if you'd like.",
				proud = "Good eye, that's my best one, so it's yours.",
				prickly = "...That's my favourite too.|Take it before I change my mind.",
				_ = "That one?|Then it's yours, {player}, and no arguing.",
			}, "heart", "cheer")
			c:keep("keep_portrait", "a")
			c:xp("a", 10)
			c:hearts("a", 1)
		end)
		s:choice("I like all of them.", function(c)
			burst(c, "a", {
				shy = "Really, all of them?|...Thank you, that means a lot.",
				proud = "Of course you do, they're all good.",
				cool = "...Thanks, that's good to hear.",
				gloomy = "You really mean that?|Heh... okay, thanks, {player}.",
				_ = "You're only saying that to be nice.|...Say it again, though.",
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
		s:n("{a} is playing a concert at the bandstand, and the whole town has come.")
		burst(s, "a", {
			shy = "Um... this one's about a gull who wanted to be a swan.",
			proud = "This next one's my best, so you'll want to remember it.",
			cool = "This next one's about a gull, and it's a short one.",
			dramatic = "This next song is about a gull who dreamed of being a swan, and it breaks my heart every time.",
			sunny = "Hi, everyone, and hi, {player}!|This one's about a gull, so sing along if you know it!",
			nervous = "Is this thing on?|Oh, it's on, okay, this one's about a gull.",
			_ = "This next one's about a gull who wanted to be a swan.|Clap along if you know it.",
		}, "music")
		s:n("Nobody knows it, but everybody claps.")
		s:fx({ t = "festival" })
		s:xp("a", 20)
		s:coins(share(ctx, a, 0.8))
		s:all(3)
		s:log("{a} played a concert at the bandstand.")
		return s:done()
	end,
})

local LESSONS = {
	"the names of the different clouds",
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
		s:say("a", "Right, repeat after me.", "point")
		burst(s, "b", {
			dreamy = "Sorry, I was watching a bird on the windowsill.|Could you start again?",
			proud = "I knew most of this already, but go on.",
			cheeky = "is there a test at the end|asking for a friend",
			cool = "Go on, I'm listening.",
			prickly = "Fine, but I'm not writing anything down.",
			bookish = "Can I take notes?|I brought three pens, just in case.",
			gloomy = "I'll have forgotten all of it by tomorrow.|Heh... go on, though.",
			polite = "Thank you for teaching me.|I'll do my very best.",
			nervous = "There isn't a test at the end, is there?|Please say there isn't a test.",
			_ = "Okay, I'm ready.|Go ahead whenever you like.",
		}, "question")
		s:n("By the end of the hour, {b} had it all memorised.")
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
		s:say("a", "Open wide and say ahh for me.", "point")
		s:say("b", "Ahhhh.", "sweat")
		burst(s, "a", {
			gentle = "Lovely, you're as healthy as anything.|Do eat a vegetable this week, though, all right?",
			bold = "You're fit as anything, right?|Twenty push ups a day and you'll stay that way.",
			proud = "Perfect health, thanks to my excellent care, naturally.",
			cool = "Everything looks fine, but drink more water.",
			prickly = "You're fine, so stop worrying.|...And drink more water, honestly.",
			bookish = "Everything's normal, actually better than normal.|Keep walking every day and it'll stay that way.",
			gloomy = "You're healthy, which honestly surprised me.|Heh... don't take that the wrong way.",
			polite = "Thank you for coming in.|Everything looks very well indeed.",
			foodie = "All good, but eat more greens and more soup.|Soup counts if there are greens in it.",
			nervous = "I-I think everything's fine.|Let me check once more... yes, all fine.",
			_ = "All good, but try for more sleep and fewer buns.",
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
			s:n("It came out a perfect heart, and {a} held it up for everyone to see.")
			burst(s, "a", BRAG, "sparkle", "cheer")
			s:xp("a", 10)
			s:mood("a", 4)
		else
			s:n("It came out looking more like a potato with legs.")
			burst(s, "a", {
				proud = "Th-that's a swan, it's clearly a swan.",
				cheeky = "it's a potato and i meant to do that|it's a very special potato",
				cool = "Hm, I'm calling that abstract.",
				prickly = "Ugh, don't say anything.|It tastes exactly the same.",
				dramatic = "My beautiful heart, {player}, it became a POTATO!",
				gloomy = "That's about how my whole week's been going.",
				sunny = "Ehehe, it's a potato!|I'll do you a proper one next time!",
				_ = "...Let's just call it abstract.",
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
		s:n("Someone pushed a book back through the library door this morning, ten years after it was due.")
		burst(s, "a", {
			gentle = "Ten years, well, I never.|I'm just glad it came home.",
			shy = "Ten years...|I don't even know what the fine would be for that.",
			cool = "Ten years late.|That's a new record for us.",
			bookish = "It's ten years overdue, ten years and four days, actually.|I looked it up.",
			dramatic = "A whole decade, {player}!|This book has been missing for ten entire years.",
			_ = "Ten whole years late!|The fine on this would buy a small boat.",
		}, "anger")
		burst(s, "a", {
			gentle = "There's a note tucked inside.|It says sorry, and that they loved every page.",
			proud = "I'm going to frame the date stamp and hang it behind the desk.",
			gloomy = "They looked after it, at least.|That's more than most people do.",
			_ = "It's in better shape than I'd have guessed.|Whoever had it looked after it.",
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
		s:n("{a} has been asked to make the biggest bouquet the town has ever seen.")
		burst(s, "a", {
			gentle = "I've put sweet peas all round the edge, {player}, so it smells lovely.",
			dreamy = "Hmm... I put one in that only opens at night.|It'll be a little surprise for them.",
			cool = "It's bigger than I am.|I'll need help carrying it.",
			dramatic = "It's taller than me, {player}, it's practically a tower of flowers!",
			nervous = "Will it fit through the door?|Oh no, I never measured the door.",
			sunny = "{player}, look, it's bigger than I am!|Will you help me carry it later?",
			_ = "It's so big I've had to use two buckets.|Now I've run out of buckets.",
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
		burst(s, "a", {
			sunny = "{player}, {player}, I made a new flavour!|It's {flavour}, and the first scoop is free!",
			proud = "I've invented a new flavour, {player}.|It's {flavour}, and you may have the first scoop.",
			cheeky = "new flavour today, it's {flavour}|first scoop's free, if you're brave enough",
			nervous = "I-I made a new flavour, it's {flavour}.|Would you try a scoop and tell me if it's awful?",
			_ = "There's a new flavour today, {player}.|It's {flavour}, and the first scoop's free.",
		}, "idea", "point")
		s:choice("One scoop, please.", function(c)
			c:n("It tasted odd at first, then lovely, then odd again.")
			burst(c, "a", "Was that a good face?|I honestly can't tell from here.", "question")
			c:xp("a", 10)
			c:mood("a", 3)
		end)
		s:choice("Just vanilla, please.", function(c)
			burst(c, "a", {
				cheeky = "coward|...i mean, a very sensible choice",
				shy = "Oh, that's okay.|Vanilla's nice too.",
				proud = "Vanilla, of course.|Well, it's your loss.",
				prickly = "Vanilla, really?|Fine, here you go.",
				foodie = "Vanilla's a classic, so I can't argue.|You're missing out on something good, though.",
				_ = "That's fair, vanilla it is.",
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
		burst(s, "a", {
			cool = "It was a long day at the {pa}.|How was yours?",
			sunny = "That was such a long day at the {pa}!|How was yours?",
			easygoing = "*yawn* That was a long day at the {pa}.|How was yours?",
			_ = "That was a long day at the {pa}.|How about you?",
		}, "sweat")
		burst(s, "b", {
			gloomy = "Busy, as usual.|Nobody ever stops needing things at the {pb}.",
			_ = "Don't ask, it was chaos at the {pb} all afternoon.|I didn't sit down once.",
		}, "sweat")
		s:voice("a", "laugh", "laugh")
		s:say("b", "Same time tomorrow, then?", "heart")
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
		s:n("{a} knocked over a whole stack of things at the {place}, and they went everywhere.")
		burst(s, "a", {
			cheeky = "well, that's one way to get everyone's attention",
			proud = "Nobody saw that, right?|Good, then it didn't happen.",
			easygoing = "Eh, I'll pick it all up in a minute.|It's not going anywhere.",
			shy = "Oh no...|I'm so sorry, I'll clean it up right away.",
			cool = "Hm, that's going to take a while to pick up.",
			prickly = "Don't help, I've got it.|...Okay, fine, you can help.",
			dramatic = "This is a DISASTER, {player}, there's mess everywhere I look.",
			gloomy = "Well, there goes my whole morning, as usual.",
			polite = "I'm so sorry, everyone.|Please mind your feet while I tidy up.",
			nervous = "Did anything break?|Is anyone hurt? Oh no, oh no.",
			sunny = "Oops, oops!|Ehehe, will you help me pick it all up?",
			_ = "Well, {player}, I suppose I'm tidying the floor today.",
		}, "sweat")
		s:mood("a", -2)
		s:xp("a", 5)
		s:log("{a} knocked over a stack of things at the {place}.")
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
		s:n("People who come to the {place} have put {a}'s name up on a little board as worker of the month.")
		burst(s, "a", {
			proud = "Only of the month?|I'd have thought of the year, at least.",
			shy = "Me? Are they sure?|...!",
			easygoing = "Huh, I'll take it.|Do I get the afternoon off for it?",
			sunny = "{player}, look, look, my name's on a board!|Let's celebrate after work!",
			cool = "Hm, that's nice of them.|I'll keep it up.",
			prickly = "Ugh, it's just a board.|...I'm taking a picture of it, though.",
			dramatic = "Recognised at last, after all this time!|I'd like to thank everyone who believed in me.",
			gloomy = "Me? Huh.|That's really nice, I don't get many of those.",
			polite = "Thank you, everyone.|I'm very grateful, truly.",
			nervous = "Are they sure it's me?|It's not a mistake? Oh, wow.",
			foodie = "Do you think it comes with a cake?|It really should come with a cake.",
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
		s:n("It's twelve o'clock, and it seems the whole town has turned up at the {place} at once.")
		burst(s, "a", {
			sunny = "Hi, hi, one moment, I'll be right with you!",
			gentle = "One at a time, please, there's plenty for everyone.",
			bold = "Next, please, and keep the line moving!",
			dreamy = "So many faces...|Sorry, who was first again?",
			easygoing = "Okay, breathe, everyone gets served eventually.",
			proud = "Hmph, they all know where the best place in town is.",
			shy = "Um... who's next?|Sorry, I didn't see who was next.",
			cheeky = "form a queue, or a circle, i'm not fussy",
			cool = "Next, please, and have your coins ready.",
			prickly = "Line up properly or nobody gets anything.",
			dramatic = "The hungry hordes descend upon us, {player}!",
			bookish = "That's forty two people in ten minutes.|I think that's a record, actually.",
			gloomy = "Here they come, all of them at once.|Heh... of course.",
			polite = "Thank you so much for waiting.|I'll be with you in just a moment.",
			foodie = "Everyone's hungry at the same time, and I understand completely.|I'm starving too.",
			nervous = "So many people, please don't let me drop anything.|Please, please don't drop anything.",
			_ = "Okay, one at a time, please.",
		}, "sweat")
		s:n("By one o'clock it was quiet again, and the till had {coins} more coins in it.")
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
		s:n("{b} has come to the {place} every day this week at exactly ten past ten.")
		burst(s, "a", {
			sunny = "Morning, is it the usual?|I've already started it!",
			gentle = "Good morning, {b}.|Your usual's ready for you.",
			cool = "The usual?",
			prickly = "Ten past ten, every single day.|...It's ready, obviously.",
			dramatic = "My most loyal customer returns, right on time!",
			bookish = "Ten past ten again, you could set a clock by you.|Actually, I have.",
			polite = "Good morning, {b}.|The same as yesterday?",
			cheeky = "ten past ten on the dot|you're so predictable, i love it",
			_ = "Morning, {b}, is it the usual?",
		}, "wave")
		burst(s, "b", {
			shy = "Oh... you remembered.|Yes, please.",
			easygoing = "Mm, you know me too well.",
			proud = "Of course, why would I change something that's perfect?",
			foodie = "The usual, and maybe one extra as a treat.",
			nervous = "Yes, please, is it weird that I come every day?|It's a bit weird, isn't it?",
			gloomy = "Yeah, it's the one thing I can count on.",
			_ = "The usual, thanks.",
		}, "heart")
		s:rel(5)
		s:xp("a", 6)
		s:memo("b", "{a} has my usual ready before I even get there now.")
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
		s:n("{a} has been practising {trick} at the {place} all week, and today it finally worked.")
		s:say("a", "{player}, watch this for a second.", "idea", "point")
		burst(s, "a", {
			sunny = "Did you see, did you see?|Ehehe, I'll do it again!",
			gentle = "There, {player}, it took me all week, but there it is.",
			bold = "Hah, it took a whole week, but I got it.",
			dreamy = "Hmm... my hands knew how before I did.",
			easygoing = "Huh, that was easier than I thought it'd be.",
			proud = "And that's how a professional does it.|You can clap if you like.",
			shy = "I did it...|I actually did it in front of someone.",
			cheeky = "now i'm going to show off to every single customer",
			cool = "That took a week, but I've got it now.",
			prickly = "Don't clap, {player}.|...Okay, maybe a little clap.",
			dramatic = "Mastery, at long last!|I feel like I've climbed a mountain.",
			bookish = "The trick was all in the wrist.|It's nearly always in the wrist, actually.",
			gloomy = "I'll forget how by tomorrow.|But today I can do it, so that's something.",
			polite = "Thank you for watching.|It means a lot to me.",
			foodie = "I'm celebrating with a bun.|Maybe two buns, actually.",
			nervous = "Was that right?|I-it looked right, didn't it?",
			_ = "I've been trying to do that all week.",
		}, "sparkle", "cheer")
		s:xp("a", 20)
		s:mood("a", 4)
		s:memo("a", "Do you want to see the new trick I learned at work?")
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
		s:n("{b} asked for one thing at the {place}, and {a} handed over something else entirely.")
		burst(s, "b", {
			cool = "This isn't what I asked for.",
			proud = "Hmph, this isn't what I asked for at all.",
			prickly = "That's not what I said at all.",
			polite = "Sorry to bother you, but I think this might be someone else's?",
			nervous = "Um, is this... did I say it wrong?|I might have said it wrong.",
			_ = "Um, this isn't what I asked for.",
		}, "question")
		burst(s, "a", {
			shy = "Oh no, I'm so sorry...|I'll swap it right away.",
			proud = "Hmph, think of it as an upgrade.|You're welcome.",
			cheeky = "surprise!|...no? ok, fair",
			gloomy = "Of course I got it wrong.|Sorry, it's that kind of day.",
			dramatic = "A terrible mistake, and I'm so sorry!",
			_ = "Oh, sorry, that's my mistake.",
		}, "sweat")
		s:choice("Could you make it again?", function(c)
			c:n("{a} sorted it out properly this time and threw in a little extra.")
			burst(c, "b", {
				prickly = "...Fine, that's better, thanks.",
				polite = "Thank you so much, that's very kind.",
				_ = "Thanks, that's the one.",
			}, "heart")
			c:xp("a", 6)
			c:rel(4)
		end)
		s:choice("Maybe give it a chance?", function(c)
			if ctx.rng:chance(0.5) then
				c:n("{b} looked it over for a while and decided to keep it.")
				burst(c, "b", {
					foodie = "Oh, this is better than what I wanted.",
					cool = "...This is good, actually.",
					_ = "Huh, I think I like this more.",
				}, "sparkle")
				c:rel(6)
				c:mood("b", 3)
			else
				c:n("{b} looked it over, frowned and didn't say a word.")
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
		s:n("Nobody has come by the {place} all morning, and {a} has tidied everything twice.")
		burst(s, "a", {
			sunny = "{player}, a person, finally!|Hi, come in, come in!",
			easygoing = "Honestly, I don't mind at all.|I've had a lovely long sit.",
			proud = "I've sorted everything by colour, and then by size.|Then I put it all back the way it was.",
			cool = "It's been quiet all morning, {player}.|I don't mind it.",
			prickly = "Don't come in out of pity, {player}.|...You can come in, though.",
			dramatic = "Alone, {player}, utterly ALONE!",
			bookish = "I've read every label in here.|Some of them are actually very interesting.",
			gloomy = "This is how it'll be forever now.|Heh... I suppose it's the weather.",
			foodie = "I've eaten my lunch, and my snack, and then my second lunch.",
			nervous = "Is everything okay?|Is it something I did?",
			_ = "It's the weather, nobody wants to come out in it.",
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
		s:n("Someone left {thing} behind at the {place}.")
		burst(s, "a", {
			gentle = "Oh, my, someone's going to miss that.",
			bold = "They can't have gone far, right?",
			cool = "Hm, someone will be back for that.",
			prickly = "Ugh, people are always leaving things.|Every single day, honestly.",
			bookish = "Actually, I saw who it belongs to.|It was someone in a blue coat, heading towards the harbour.",
			nervous = "What if they need it?|What if it's the only one they have?",
			_ = "Whose is this?|{player}, did you see who left it?",
		}, "question")
		s:choice("Run after them!", function(c)
			c:n("{a} caught up with them at the end of the street, out of breath.")
			burst(c, "a", "I got them, and they were so pleased.", "heart", "cheer")
			c:mood("a", 4)
			c:all(1)
		end)
		s:choice("Put it in the lost box?", function(c)
			c:n("It went in the box under the counter with forty other lost things.")
			burst(c, "a", {
				gloomy = "Nobody ever comes back for anything in there.",
				_ = "They'll be back for it, people always come back.",
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
		burst(s, "b", {
			shy = "Um... could I help?|I could just hold things for you.",
			bold = "Give me something to do, anything at all.",
			sunny = "Can I help, please?|I'll be really, really good!",
			cool = "Need a hand?|I've got the afternoon free.",
			prickly = "Ugh, I'm bored, so give me a job.|Don't make a big deal of it.",
			polite = "Might I help, if it's no trouble?",
			nervous = "Could I help, if that's okay?|I-I might drop things, though.",
			_ = "Can I help?|I've got nothing else on today.",
		}, "question")
		s:choice("Let {b} help out today.", function(c)
			c:n("{b} stayed until closing and only broke one thing, which was already cracked.")
			burst(c, "a", {
				proud = "Not bad at all.|You might have a gift for this.",
				gentle = "Thank you, {b}, that was a big help.",
				cool = "Good work today.",
				prickly = "You were fine.|Come back tomorrow if you want, whatever.",
				_ = "Thanks, come back any time.",
			}, "heart")
			c:xp("b", 20)
			c:xp("a", 5)
			c:rel(6)
			c:mood("b", 5)
		end)
		s:choice("Maybe another day, {b}.", function(c)
			burst(c, "b", "Okay, another day, then.", "sad")
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
		s:n("{a} has been up since four, and the whole street smells of fresh bread.")
		burst(s, "a", {
			sunny = "{player}, you're up early too!|Here, the first roll's yours!",
			gentle = "Good morning, {player}, did you sleep all right?|Here, take one while they're warm.",
			bold = "Six trays done and four to go.|Grab one on your way past, right?",
			dreamy = "Hmm... the town's still asleep.|It's just me and the oven at this hour.",
			easygoing = "*yawn* I nap in the afternoons, so it works out fine.",
			proud = "This is the best part of the day.|It's a shame nobody's around to see me be brilliant.",
			shy = "Oh... good morning.|You're the first one up.",
			cheeky = "don't tell anyone, but the first batch is always the best one",
			cool = "Morning, want a roll while they're hot?",
			prickly = "Don't talk to me until the third tray.|...Here, have a roll.",
			dramatic = "While the whole town sleeps, the baker toils away in the dark!",
			bookish = "Dough rises faster when it's warm, actually.|That's why I start so early.",
			gloomy = "Four o'clock every day, as usual.|It's fine, I like the quiet.",
			polite = "Good morning, {player}.|Please have one, on the house.",
			foodie = "Mmm, I've already eaten two.|That's quality control.",
			nervous = "Is that one burnt?|I-it's not burnt, is it?",
			_ = "Morning, take one while they're hot.",
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
		s:n("{a} stops you halfway down the street, digging through the bag.")
		burst(s, "a", {
			sunny = "{player}, wait, wait, there's one for you!",
			gentle = "{player}, there's a card for you.|Here you go.",
			bold = "There's one for you, {player}.|Saves me a walk, right?",
			proud = "Delivered straight into your hand, not even to your door.",
			shy = "Um, {player}?|This one's yours.",
			cheeky = "i didn't read it|ok i read it a little",
			cool = "This one's yours.|Later.",
			prickly = "Here, it's yours.|Don't make me walk all the way to your door.",
			dramatic = "A letter for you, {player}, all the way from another island!",
			nervous = "This one's yours, I checked twice.|It's definitely yours.",
			_ = "{player}, there's one for you.",
		}, "wave")
		s:n("It's a postcard from a tourist who came through last month, with coins taped to the back.")
		s:n("It says, 'Lovely town. Please buy the baker something from me.'")
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
		s:n("{a} slides a cup across the counter with your name written in the foam.")
		burst(s, "a", {
			sunny = "Look, look, it's your name!|I practised all morning for this!",
			gentle = "I hope you like it, {player}.|I took my time over the letters.",
			bold = "That's your name, in foam.|Drink it while it's hot.",
			dreamy = "Hmm... the letters drift apart if you wait long enough.",
			proud = "Perfect lettering, if I say so myself.|You're welcome.",
			shy = "It's a bit wobbly...|Sorry, I'll do better next time.",
			cheeky = "spelled it right this time, i think|look, look",
			cool = "I made you one.|Your name's on top.",
			prickly = "It's just a coffee, so don't make a face.",
			dramatic = "Your name, {player}, written in MILK!",
			nervous = "Is it spelled right?|Please tell me it's spelled right.",
			_ = "This one's for you, {player}.",
		}, "heart")
		s:choice("*sip*", function(c)
			burst(c, "a", "Ha, now you've got a foam moustache.", "laugh")
			c:hearts("a", 1)
			c:xp("a", 5)
		end)
		s:choice("Wait, let me look first.", function(c)
			burst(c, "a", {
				proud = "Take your time, it's a work of art.",
				shy = "Oh... you like it?|Okay, good.",
				_ = "Heh, go on, but drink it before it goes cold.",
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
		burst(s, "a", {
			sunny = "{player}, help, it's all going runny!",
			bold = "Right, everyone gets one, right now.",
			cool = "It's all melting, {player}.|I can't scoop fast enough.",
			prickly = "Don't just stand there, eat something.|Help me out here.",
			dramatic = "It's melting before my very eyes, and there's nothing I can do!",
			gloomy = "It's all going, like everything does.|Heh... sorry, it's the heat.",
			foodie = "I can't let it go to waste.|I'll eat it myself if I have to, all of it.",
			nervous = "What do I do, sell it cheap?|Or do I give it all away?",
			_ = "It's melting faster than I can scoop, {player}.",
		}, "sweat")
		s:choice("Free cones for everyone?", function(c)
			c:n("{a} handed a cone to everyone in the square before it could melt, and some people had three.")
			c:all(3)
			c:mood("a", 4)
			c:xp("a", 5)
		end)
		s:choice("Close early and save the rest.", function(c)
			c:n("{a} put the lid down and pushed the cart into the shade.")
			burst(c, "a", "I'll come back out tonight when it's cooler.", "zzz")
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
		s:n("{a} has started a painting of the harbour on the side of the bakery, with all the boats in.")
		burst(s, "a", {
			sunny = "{player}, what should go in the corner?|Pick something, anything!",
			proud = "When this is finished, people will come from other islands to see it.",
			shy = "I left a gap in the corner...|I couldn't decide what to put there.",
			cool = "There's a gap left in the corner.|Any ideas?",
			prickly = "Don't say 'a gull'.|...Okay, fine, you can say 'a gull'.",
			dramatic = "This wall is becoming a window, {player}, a window onto the sea!",
			bookish = "Outdoor paint takes two days to dry properly.|Three if it rains, actually.",
			gloomy = "It'll fade in the sun eventually.|Heh... it should last a few years first, though.",
			foodie = "There's going to be a bun in it somewhere.|A big one, on the bakery's windowsill.",
			nervous = "Is it okay that it's on the bakery?|I asked, and they said yes, I think.",
			_ = "There's a corner left, {player}.|What should go there?",
		}, "question")
		s:choice("A gull, obviously.", function(c)
			c:n("{a} painted a gull in the corner, holding a chip.")
			burst(c, "a", "Perfect, there's always a gull on the harbour wall.", "sparkle", "cheer")
			c:xp("a", 15)
			c:all(2)
		end)
		s:choice("Paint yourself in it.", function(c)
			c:n("{a} painted themselves in the corner, very small, waving.")
			burst(c, "a", {
				shy = "Is that too much?|It's only tiny, so it's fine, right?",
				proud = "Every great painting has the artist in it somewhere.",
				_ = "Ha, okay, a tiny me it is.",
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
		s:n("The sky's going dark, and {a} still has half a wall to finish.")
		burst(s, "a", {
			bold = "Twenty minutes, I can do it in twenty minutes, right?",
			sunny = "{player}, will you grab a bucket and help?|Let's beat the rain together!",
			cool = "It's going to be close.|Can you pass me bricks?",
			prickly = "Don't just stand there, pass me that.",
			dramatic = "It's a race against the sky itself!",
			gloomy = "It's going to rain right on the wet mortar, I know it.",
			nervous = "Was that thunder?|Hurry, hurry, I think that was thunder.",
			_ = "If it rains on this before it sets, I'll have to start again.",
		}, "sweat")
		s:choice("I'll pass you bricks.", function(c)
			c:n("You passed bricks and {a} laid them, and the last one went in as the first drop fell.")
			burst(c, "a", "Done, just in time.|Thanks, {player}, the tea's on me.", "heart", "cheer")
			c:xp("a", 15)
			c:hearts("a", 1)
		end)
		s:choice("Throw a sheet over it.", function(c)
			c:n("A big sheet with a brick on each corner should keep it dry until morning.")
			burst(c, "a", "Good idea, I'll finish it tomorrow.", "idea")
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
		s:n("It's reading hour at the library, and {a} is reading a story out loud to whoever turns up.")
		local who = nil
		for _, vid in ctx.present do
			if vid ~= a then
				who = vid
				break
			end
		end
		if who then
			s:with({ x = ctx.v(who).name })
			s:n("Today it's {x}, two pigeons on the windowsill and you.")
		end
		burst(s, "a", {
			sunny = "Okay, it's chapter four!|It's the best one, I promise!",
			gentle = "Get comfy, everyone.|This one's a nice one.",
			cool = "We're on chapter four, so settle in.",
			prickly = "No talking, please.|...Unless it's a good question.",
			dramatic = "And now, the storm, the ship, the LIGHTHOUSE!",
			bookish = "This is the first edition, actually.|The words are a little different from the new one.",
			gloomy = "This bit's sad, so fair warning.",
			polite = "Thank you all for coming.|Shall we begin?",
			nervous = "Can everyone hear me?|Should I be louder? Okay, chapter four.",
			dreamy = "Hmm... where did we stop last time?|Oh, the lighthouse, that's right.",
			_ = "Chapter four, where were we?",
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
		s:say("a", "{player}, when did you last drink some water?", "question", "point")
		burst(s, "a", {
			sunny = "You've been building all day, I saw you!|Water, right now!",
			gentle = "You look a little tired.|Look after yourself, won't you?",
			bold = "That long, really?|Go and drink a glass right now.",
			proud = "Doctor's orders, and I happen to be a very good doctor.",
			cool = "Drink something before you go back to work.|Later.",
			prickly = "I'm not fussing, I'm just saying.|Drink something today, okay?",
			dramatic = "You're wilting, like a flower in the sun!",
			bookish = "Most people need about two litres a day.|More when it's warm, actually.",
			gloomy = "You'll get a headache, people always do.|Heh... then you'll come and see me.",
			polite = "Forgive me for asking.|Please do drink something soon.",
			foodie = "Eat something too, while you're at it.|Something with soup in it would be best.",
			nervous = "You're okay, though, right?|You look okay, I'm just checking.",
			_ = "Drink some water, doctor's orders.",
		}, "sweat")
		s:choice("*drinks a whole glass*", function(c)
			c:n("{a} watched you drink every last drop.")
			burst(c, "a", "Good, same time tomorrow.", "heart")
			c:hearts("a", 1)
			c:xp("a", 5)
		end)
		s:choice("Later, I promise.", function(c)
			burst(c, "a", {
				prickly = "'Later,' right.|I'll be checking.",
				nervous = "You promise?|I'll ask again later, just in case.",
				_ = "I'll hold you to that.",
			}, "question")
			c:xp("a", 3)
		end)
		s:log("{a} told you to drink some water.")
		return s:done()
	end,
})

-- texts from work: something found, a small disaster and the relief after, a first shift -----------

local FOUNDS = {
	baker = "a ring of old keys, baked into the back of the oven wall",
	barista = "a coin from the year the café opened, stuck under the grinder",
	icecream = "a tiny wooden spoon with someone's initials carved on it",
	shopkeeper = "a price list from fifty years ago, when bread cost a penny",
	florist = "a seed packet with no name, only a drawing of a blue flower",
	postie = "a letter at the bottom of the bag, addressed to the town itself",
	builder = "a note in a bottle inside the old wall, left by whoever built it",
	artist = "an old canvas with a sketch of the harbour from before any houses were built",
	musician = "a page of music tucked inside the bandstand piano",
	teacher = "an old school slate with forty years of names scratched into the frame",
	doctor = "a jar of sweets labelled 'for brave patients only', still full",
	librarian = "a pressed flower in a book nobody has borrowed in thirty years",
}

event({
	id = "foundatwork",
	when = "day",
	weight = W({ base = 0.12, job = "any" }),
	scene = function(ctx, a)
		local w = ctx.job(a)
		local s = K.scene(ctx, "Look what I found")
			:with({ found = FOUNDS[w.job.id] or "a key nobody can find a lock for", place = place(ctx, a) })
		burst(s, "a", {
			sunny = "{player}, {player}!|You won't believe what I found at the {place}!",
			gentle = "{player}, are you busy?|I found something lovely at the {place}.",
			bold = "{player}, come down to the {place}, right now.|I found something you need to see.",
			dreamy = "{player}...|The {place} had a little secret hidden in it.",
			easygoing = "So I was putting off the sweeping, as you do.|And then I found something at the {place}.",
			proud = "{player}, I've made a discovery at the {place}.|Naturally, I was the one who found it.",
			shy = "Um, {player}?|I found something at the {place}, and I didn't know who else to tell.",
			cheeky = "{player}, guess what's in my pocket|wrong, come and see",
			cool = "{player}, I found something at the {place}.|You should see it.",
			prickly = "Don't make a big fuss.|But you should come and see what I found at the {place}.",
			dramatic = "{player}, the {place} was hiding a secret all this time!|And I'm the one who found it.",
			bookish = "{player}, I think I've found something old at the {place}.|Actually, quite old.",
			gloomy = "I found something at the {place}.|It's probably nothing... heh, actually, it isn't nothing.",
			polite = "Good afternoon, {player}.|I've found something at the {place} that you may like to see.",
			foodie = "I found something at the {place}.|Sadly it's not food, but it's still good.",
			nervous = "I found something at the {place}.|Is it okay that I found it?|Should I give it back, and if so, to who?",
			_ = "{player}, I found something at the {place}.",
		}, "idea", "point")
		s:n("It's {found}.")
		s:choice("Who left it there?", function(c)
			burst(c, "a", {
				bookish = "I've no idea yet, but I'll ask at the library.|I love a mystery like this.",
				dreamy = "Hmm... someone who wanted it found one day.",
				cool = "I don't know.|I'll keep it safe until someone asks.",
				_ = "I've no idea.|I'll keep it safe until somebody asks about it.",
			}, "question")
			c:mood("a", 4)
			c:memo("a", "Nobody's come for the thing I found at work yet, but I check every day.")
		end)
		s:choice("Can I see it up close?", function(c)
			c:n("You turned it over in your hands while {a} watched as if it might break.")
			burst(c, "a", {
				prickly = "Careful with it.|...Okay, you can hold it a bit longer.",
				shy = "...!|You like it? I'm glad I told you.",
				_ = "It's good, right?|I'm glad I told you first.",
			}, "heart")
			c:hearts("a", 1)
			c:mood("a", 3)
		end)
		s:log("{a} found {found} at the {place}.")
		return s:done()
	end,
})

event({
	id = "workscare",
	when = "day",
	weight = W({ base = 0.12, job = "any", traits = { brave = -0.2 } }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "A scare at work"):with({ place = place(ctx, a) })
		burst(s, "a", {
			nervous = "{player}, the {place} is full of smoke!|What do I do, what do I do?",
			sunny = "{player}, emergency, there's smoke at the {place}!",
			gloomy = "{player}, there's smoke at the {place}.|So this is how it ends, then.",
			dramatic = "{player}, there's smoke at the {place}!|This is the worst day of my whole life!",
			cool = "{player}, there's smoke at the {place}.|Bring a bucket.",
			bold = "{player}, there's smoke at the {place}.|Grab a bucket and get over here, quick.",
			shy = "Um, {player}...|There's smoke coming from the {place}.",
			_ = "{player}, there's smoke coming out of the {place}.",
		}, "sweat")
		s:n("You ran over with a bucket, but it was only steam from a kettle someone had left boiling nearby.")
		burst(s, "a", {
			nervous = "It was only steam.|I'm going to sit down for a very long time.",
			sunny = "It was steam, ehehe!|That was a lot of running for some steam!",
			gloomy = "Huh, it was just steam.|Things don't usually turn out fine for me.",
			dramatic = "It was steam.|We shall speak of this to NO ONE.",
			cool = "...It was steam.|Sorry for the run.",
			bold = "Hah, just steam.|Good practice, though, right?",
			prickly = "It was the kettle.|Ugh, don't say it, I know.",
			_ = "It was only the kettle.|Thanks for running over.",
		}, "sweat", "laugh")
		s:choice("Better safe than sorry.", function(c)
			burst(c, "a", {
				nervous = "Yes, exactly.|Thank you for not laughing at me.",
				prickly = "Exactly.|...Thanks for coming.",
				_ = "Yeah, thanks for coming so fast, {player}.",
			}, "heart")
			c:hearts("a", 1)
			c:mood("a", 3)
		end)
		s:choice("Should I keep the bucket handy?", function(c)
			burst(c, "a", {
				cheeky = "yes, just in case|that kettle looks guilty",
				gloomy = "Heh... yes, actually.",
				_ = "Ha, put it by the door.|Just in case.",
			}, "laugh")
			c:mood("a", 4)
		end)
		s:log("Steam from a kettle gave {a} a scare at the {place}.")
		return s:done()
	end,
})

event({
	id = "firstshift",
	when = "any",
	weight = W({
		base = 0.12,
		job = "any",
		traits = { brave = -0.3 },
		cond = function(ctx, a)
			return (ctx.v(a).lv or 1) <= 3
		end,
	}),
	scene = function(ctx, a)
		local s = K.scene(ctx, "Tomorrow"):with({ place = place(ctx, a) })
		burst(s, "a", {
			nervous = "H-hello, {player}, it's me, from the {place}.|They want me working on my own tomorrow.|What if someone asks me something and I don't know the answer?",
			shy = "Um, {player}... I'm on my own at the {place} tomorrow.|What if someone asks me something I don't know?",
			gloomy = "I'm on my own at the {place} tomorrow.|It'll go wrong, as usual.",
			proud = "I'm running the {place} on my own tomorrow, and I'm not nervous at all.|...Th-that's not true, I'm a bit nervous.",
			sunny = "{player}, I'm on my own at the {place} tomorrow!|It's exciting and scary at the same time!",
			prickly = "I'm on my own at the {place} tomorrow.|I'm fine, so don't ask if I'm fine.",
			cool = "I'm doing my first shift alone at the {place} tomorrow.|I thought you'd want to know.",
			_ = "{player}, I'm on my own at the {place} tomorrow.|What if it goes wrong?",
		}, "sweat")
		s:choice("You'll be fine.", function(c)
			burst(c, "a", {
				nervous = "Okay, okay.|I'll check everything twice.",
				gloomy = "You think so?|...Okay, maybe you're right.",
				prickly = "I know.|...Thanks, though.",
				_ = "Okay, thanks, {player}.",
			}, "heart")
			c:mood("a", 3)
			c:memo("a", "My first shift on my own went fine, and I didn't drop a single thing.")
		end)
		s:choice("I'll come by first thing.", function(c)
			burst(c, "a", {
				nervous = "Oh... thank you.|Please come early, just in case.",
				shy = "...!|You'd really do that? Thank you.",
				sunny = "Yes, you'll be my first customer!|Let's have breakfast after!",
				cool = "...Okay, thanks.",
				_ = "You would? Thanks, that really helps.",
			}, "heart")
			c:hearts("a", 1)
			c:xp("a", 5)
			c:memo("a", "You were my first customer when I worked on my own, and I still remember that.")
		end)
		s:log("{a} was worried about their first shift alone.")
		return s:done()
	end,
})

return list
