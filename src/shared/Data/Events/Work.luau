--!nonstrict
-- At work: a big order, the builder's tower of bricks, letters to the wrong houses, a grumpy
-- customer, a new flavour, an art show, a concert, a lesson, a check up, latte art, a book back
-- ten years late, the lunch rush, a regular, a new trick, the wrong order, a slow day. Each needs
-- a villager with a job (Data/Jobs), and what it pays comes from the job's own income, so it
-- stays in step with wages. The villagers text the way a friend does: one natural sentence a
-- message, two or three messages at a time, each personality with its own habits, and now and
-- then your name ({player}). Where they work ({place}) is the place as people say it ("bakery",
-- "workshop": K.workplace), so a line says "at the {place}" or "by the {place}".

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
	sunny = "It worked, it really worked!|Ehehe, I'm telling everyone at lunch.",
	proud = "Hmph, naturally it worked.|Go on, you can say it was impressive.",
	bold = "Hah, I told you I could do it.|That's how it's done, right?",
	shy = "...!|Um, it worked, and you were here to see it.",
	cheeky = "ok that was actually amazing|tell me i'm amazing, go on",
	cool = "That came out exactly the way I wanted.",
	prickly = "Ugh, don't make a fuss about it.|...It was good, though, wasn't it?",
	dramatic = "*gasp* It WORKED!|I'd like this moment painted, please.",
	bookish = "It went exactly the way I planned it on paper.|I'm writing down what I did before I forget.",
	gloomy = "Huh, it actually worked.|That doesn't happen to me very often.",
	gentle = "Oh, my, it worked.|I'm so glad you were here to see it.",
	dreamy = "Hmm... it worked, and I wasn't even sure what I was doing.|It's like my hands knew before I did.",
	easygoing = "Mm, not bad for someone who's barely awake.|I'll take that.",
	polite = "Oh, how wonderful.|I am so glad it came out well.",
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
	return if w then K.workplace(ctx, vid) else "workplace"
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
			dramatic = "This is the biggest order in the HISTORY of this island!|I may need to lie down first.",
			bookish = "If I manage forty an hour, it'll take me most of the night.|Actually, make that two nights.",
			gloomy = "Something's going to go wrong with this, it always does.|Heh... I'll start anyway.",
			polite = "How very kind of them to think of us.|I will do my very best with it.",
			foodie = "I'm going to need a proper lunch before I start this.|You can't do a job this size on an empty stomach.",
			nervous = "Oh no, oh no, what if I miss one?|What if I miss ten and they never order again?",
			gentle = "Oh, my, that's a lot.|We'll manage it if we take it one bit at a time.",
			dreamy = "Hmm... that's more than I can picture all at once.|I'll do the first one and see how it goes.",
			cheeky = "guess who just got the biggest order ever|and yes, i'm going to brag about it all week",
			_ = "{player}, that's the biggest order we've ever had.|I'd better get started.",
		}, "sweat")
		s:choice("Stay late and get it done.", function(c)
			c:n("{a} worked until the stars came out, and the order went out on time.")
			burst(c, "a", {
				sunny = "That was a long one, but we did it!|I'm going straight to bed, ehehe.",
				gentle = "Oh, my, I'm tired.|Make sure you get some rest too, okay?",
				bold = "Done, and on time.|Hah, I said I could do it.",
				dreamy = "Hmm... the stars came out before I noticed...|Is it done? It's done.",
				easygoing = "*yawn* That was more work than I've done all year.|I'm sleeping in tomorrow.",
				proud = "Every single one done, and done perfectly.|Naturally, I'm exhausted.",
				shy = "We got it done...|I'm so tired, but I'm glad.",
				cheeky = "done, every last one|someone carry me home",
				cool = "It's done.|I'm going to sleep for a long time.",
				prickly = "Done, and never again.|...Okay, maybe again, but not this week.",
				dramatic = "It is FINISHED!|I may never lift my arms again.",
				bookish = "Actually, that took longer than I worked out.|I'll check my numbers again tomorrow, after a sleep.",
				gloomy = "Nothing went wrong, somehow.|I'm too tired to be suspicious about it.",
				polite = "It is all done, and on time.|Thank you for believing in me.",
				foodie = "It's done, and I'm starving.|Is anything still open?",
				nervous = "D-did I get them all?|I got them all, I counted three times.",
				_ = "It's done, and on time.|I'm going straight to bed.",
			}, "zzz")
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
			dramatic = "Look, {player}, my tower is taller than the whole YARD!",
			bookish = "As long as the middle stays over the base, it can't fall.|It's getting quite close to the edge, though.",
			gloomy = "It's going to fall, I just know it.|Heh... it's still standing for now.",
			nervous = "Please don't breathe on it, {player}.|I-I mean it, it's wobbling already.",
			sunny = "{player}, look, look, it's taller than the door!|Let's see how high it goes!",
			gentle = "Oh my, it's getting very tall.|Stand back a little, okay?",
			dreamy = "Hmm... from down here it almost touches the clouds.|Well, not really, but almost.",
			easygoing = "I started stacking them on my break, and I just didn't stop.|It's very relaxing.",
			shy = "Um... it got a bit tall.|Please don't tell anyone.",
			polite = "I hope you do not mind, {player}.|I have been stacking them during my breaks.",
			foodie = "It's like a cake with too many layers.|One more, and it's perfect.",
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
				sunny = "Okay, okay, let's stop!|It's the tallest one ever, ehehe!",
				gentle = "Yes, that's a good idea.|Better safe, okay?",
				dreamy = "Hmm... yes, it looks nice like that.",
				easygoing = "Sure, stopping is my favourite thing.",
				shy = "Okay... yes, let's stop.",
				cheeky = "boring, but fine|i'll add one when you're not looking",
				cool = "Agreed. It stays like that.",
				prickly = "Fine.|I was going to stop anyway.",
				dramatic = "It will stand FOREVER, like a statue!",
				bookish = "Good call, it was leaning about two centimetres too far.",
				gloomy = "Yeah, it was going to fall.|Good call.",
				polite = "Yes, I think that is wise.",
				foodie = "Good, I'm hungry anyway.",
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
			shy = "I'm so sorry about that.|I'll go around again and fix every single one.",
			easygoing = "Mm, just swap with your neighbours and it'll all even out.|I'll do the round again after lunch.",
			cool = "I'll do the whole round again this afternoon.|Leave the wrong ones outside your door.",
			prickly = "Ugh, don't say it, I already know.|I'm fixing it right now.",
			dramatic = "Every MAILBOX in town, and it was me!|Everyone's going to remember this forever.",
			gloomy = "Every single one, as usual.|Heh... at least I'm consistent.",
			polite = "I am very sorry about that.|I will come to every house myself and swap them back.",
			nervous = "Every house, even the one with the big dog?|Oh no, oh no.",
			sunny = "Oops, oops, sorry, everyone!|I'll fix it all by lunch, I promise!",
			gentle = "Oh my, I'm so sorry, everyone.|I'll put it right this afternoon, okay?",
			bold = "Yeah, that was me.|I'll fix it today, no problem.",
			dreamy = "Hmm... I was thinking about something else this morning.|Sorry, everyone.",
			cheeky = "ok, so everyone got a surprise letter today|you're welcome, jk, i'm fixing it",
			bookish = "Actually, it was only two bags, but that's every letter in town.|I'll sort them again by street.",
			foodie = "I hadn't had breakfast yet, that's my excuse.|I'll fix it after a sandwich.",
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
			nervous = "S-sorry, but I don't think this is right.|Could someone have a look?",
			shy = "Um... sorry, but this isn't quite right.",
			gentle = "I'm sorry, dear, but this isn't what I asked for.",
			polite = "Excuse me, I am afraid this is not quite what I ordered.",
			sunny = "Hey, this isn't what I asked for!|Can you fix it, please?",
			cool = "This isn't right.|I'd like it fixed.",
			dreamy = "Hmm... I don't think this is what I asked for.",
			easygoing = "Eh, this isn't really what I wanted.|Could you try again?",
			bookish = "Actually, this isn't what I asked for.|I wrote it down, look.",
			_ = "This is all wrong.|I'd like to talk to whoever's in charge, please.",
		}, "anger", "point")
		burst(s, "a", {
			gentle = "Oh, my, I'm sorry you've had a bad day.|Let me fix it for you, okay?",
			bold = "That's me, I'm in charge.|So what's the problem?",
			proud = "Hmph, there's nothing wrong with it except your mood.",
			shy = "Um... I'm sorry.|What would you like me to change?",
			cheeky = "have you tried smiling? it's free|everything else here costs money, though",
			cool = "Tell me exactly what's wrong with it, and I'll fix it.",
			polite = "I do apologise.|Please tell me how I can put it right.",
			nervous = "Oh no, what did I do?|I'll fix it, I promise, just tell me what's wrong.",
			sunny = "Oh no, I'm sorry!|Let's fix it right now, together!",
			dreamy = "Hmm... oh, I see, I'm sorry.|What did you want it to be?",
			easygoing = "Eh, no problem, let me fix it, no rush.",
			prickly = "Tsk, fine, what's wrong with it?|...I'll fix it.",
			dramatic = "A DISASTER!|I'll fix it at once.",
			bookish = "Actually, let me check the order.|Oh, you're right, I'll fix it.",
			gloomy = "Yeah, I figured something would go wrong today.|Let me fix it.",
			foodie = "Sorry about that, I'll fix it.|Here, have a cookie while you wait.",
			_ = "Okay, let's take a deep breath.|What can I do to help?",
		}, "sweat")
		if K.isPers(ctx, a, "gentle", "sunny", "shy", "polite") or ctx.rng:chance(0.4) then
			burst(s, "b", "...Sorry, I've had a rough day.|Thank you for being patient with me.", "sad")
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
			bold = "{player}, I made something new at the {place}.|It's {thing}, and you're trying it first, right?",
			dreamy = "Hmm... {player}, I had an idea at the {place} last night.|It's {thing}, do you want to try it?",
			easygoing = "{player}, I made {thing} at the {place}.|Try it whenever, no rush.",
			prickly = "{player}, I made {thing}.|Try it, and be honest, but not too honest.",
			gloomy = "{player}, I made {thing}.|It's probably awful, but would you try it?",
			polite = "{player}, if it is no trouble, would you try something new?|It is {thing}.",
			_ = "{player}, there's something new at the {place} today.|It's {thing}, and I'd like to know what you think.",
		}, "idea", "point")
		s:choice("I'd love to try it.", function(c)
			if ctx.rng:chance(0.6) then
				c:n("It was really good, much better than it sounded.")
				burst(c, "a", BRAG, "sparkle", "cheer")
				c:coins(share(ctx, a, 0.6))
				c:xp("a", 15)
				c:mood("a", 5)
			else
				c:n("You took a slow mouthful, and {a} watched your face the whole time.")
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
			gentle = "I painted all of these this season.|Take your time, okay?",
			bold = "{player}, look at these.|Pretty good, right?",
			easygoing = "Have a look around, no rush.|I painted most of them lying down.",
			cheeky = "pick a favourite|wrong answers get painted into the next one",
			polite = "Thank you for coming, {player}.|Please, take your time.",
			foodie = "This one's a bowl of plums.|I ate them after, so it's the only one there is.",
			_ = "Which one's your favourite, {player}?|You can lie if you have to.",
		}, "sparkle")
		s:choice("I like the portrait best.", function(c)
			burst(c, "a", {
				shy = "That one?|...!|You can have it, if you'd like.",
				proud = "Good eye, that's my best one, so it's yours.",
				prickly = "...That's my favourite too.|Take it before I change my mind.",
				sunny = "That one? Yay!|It's yours, let's hang it in your house!",
				gentle = "Oh, that one's special to me.|I'd like you to have it.",
				bold = "Good choice.|It's yours, no arguing.",
				dreamy = "Oh... that one?|You can have it, I painted it on a rainy day.",
				easygoing = "That one? Take it, it's yours.",
				cheeky = "that one, really|ok, it's yours, but i nearly threw it out",
				cool = "That one. It's yours.",
				dramatic = "That one? My PRIDE and joy!|Take it, it's yours.",
				bookish = "That one took me eleven days, actually.|You should have it.",
				gloomy = "That one?|Heh... nobody's ever picked that one, so take it.",
				polite = "Thank you, {player}.|Please, take it as a gift.",
				foodie = "That one? It's yours, and here's a cookie to go with it.",
				nervous = "R-really, that one?|Do you want it? You can have it.",
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
				sunny = "All of them? Ehehe, thank you!|I'll paint even more next season!",
				gentle = "Oh my, that's very kind of you.|Thank you, {player}.",
				bold = "Hah, good answer.|...Thanks. Anyway.",
				dreamy = "All of them...|Hmm, that's a nice thing to hear.",
				easygoing = "Aw, thanks, that's nice to hear.",
				cheeky = "all of them? that's cheating|but thanks, hehe",
				prickly = "You can't like all of them.|...Okay, thanks.",
				dramatic = "ALL of them? *sob*|Thank you, {player}.",
				bookish = "All forty two? Thank you, really.",
				polite = "Thank you very much, {player}, that is kind of you.",
				foodie = "Thanks, that's better than a slice of cake.",
				nervous = "Really? Even the crooked one?|Oh, thank you.",
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
			gentle = "This next one's about a gull who wanted to be a swan.|Sing softly with me, if you know it.",
			bold = "This one's about a gull, and you're all singing along, right?",
			dreamy = "La la ♪... this one's about a gull who dreamed of being a swan.",
			easygoing = "This next one's a slow one, about a gull.|Feel free to sit down.",
			cheeky = "this one's about a gull who wanted to be a swan|he never made it, spoilers",
			prickly = "This one's about a gull.|Don't laugh, it's a sad one.",
			bookish = "This song is about a gull who wanted to be a swan.|I wrote it in nine minutes, actually.",
			gloomy = "This one's about a gull who wanted to be a swan.|It doesn't end well, as usual.",
			polite = "Thank you all for coming.|This next song is about a gull who wished to be a swan.",
			foodie = "This next one's about a gull who wanted to be a swan.|Then we break for snacks.",
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

-- what's taught, and how the teacher starts
local LESSONS = {
	{ "the names of the different clouds", "Right, look up, and repeat after me." },
	{ "how to tie six different knots", "Right, watch my hands, and then you try." },
	{ "the history of the town's fountain", "Right, it all started with a very thirsty mayor." },
	{ "how to say hello in four languages", "Right, repeat after me." },
}

event({
	id = "lesson",
	actors = 2,
	when = "day",
	weight = W({ base = 0.3, job = "teacher" }),
	scene = function(ctx, a, b)
		local lesson = ctx.rng:pick(LESSONS)
		local s = K.scene(ctx, "A lesson"):with({ topic = lesson[1] })
		s:n("{a} is teaching {b} {topic}.")
		s:say("a", lesson[2], "point")
		burst(s, "b", {
			dreamy = "Sorry, I was watching a bird on the windowsill.|Could you start again?",
			proud = "I knew most of this already, but go on.",
			cheeky = "is there a test at the end|asking for a friend",
			cool = "Go on, I'm listening.",
			prickly = "Fine, but I'm not writing anything down.",
			bookish = "Can I take notes?|I brought three pens, just in case.",
			gloomy = "I'll have forgotten all of it by tomorrow.|Heh... go on, though.",
			polite = "Thank you for teaching me.|I will do my very best.",
			nervous = "There isn't a test at the end, is there?|Please say there isn't a test.",
			sunny = "Okay, okay, I'm ready!|Let's do this!",
			gentle = "Thank you for teaching me.|I'll listen carefully, okay?",
			bold = "Right, go on, I'm ready.",
			easygoing = "Sure, but can I lean on the wall while you talk?",
			shy = "Um... okay.|I'll try my best.",
			dramatic = "Teach me, I'm READY!",
			foodie = "Okay, but is there a snack break?",
			_ = "Okay, I'm ready.|Go ahead whenever you like.",
		}, "question")
		s:n("By the end of the hour, {b} had the hang of all of it.")
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
			gentle = "Lovely, you're as healthy as anything.|Do eat a vegetable this week, though, okay?",
			bold = "You're fit as anything, right?|Twenty push ups a day and you'll stay that way.",
			proud = "Perfect health, thanks to my excellent care, naturally.",
			cool = "Everything looks fine, but drink more water.",
			prickly = "You're fine, so stop worrying.|...And drink more water, honestly.",
			bookish = "Everything's normal, actually better than normal.|Keep walking every day and it'll stay that way.",
			gloomy = "You're healthy, which honestly surprised me.|Heh... don't take that the wrong way.",
			polite = "Thank you for coming in.|Everything looks very good.",
			foodie = "All good, but eat more greens and more soup.|Soup counts if there are greens in it.",
			nervous = "I-I think everything's fine.|Let me check once more... yes, all fine.",
			sunny = "All done, and you're perfectly healthy!|Let's keep it that way with a walk!",
			dreamy = "Hmm... everything sounds just right.|Your heart has a nice beat, like a little drum.",
			easygoing = "You're fine, so go and have a nice nap.|Doctor's orders.",
			shy = "Um... everything looks fine.|S-sorry, my hands are cold.",
			cheeky = "you're fine|but i'm writing 'eats too much cake' anyway",
			dramatic = "Perfect HEALTH!|I've never seen anything like it.",
			_ = "All good, but try for more sleep and fewer buns.",
		}, "sparkle")
		burst(s, "b", {
			sunny = "Thanks, I feel better already!",
			gentle = "Thank you, that's a weight off my mind.",
			bold = "Good, I knew I was fine.",
			dreamy = "Oh, good... I'll try to remember all that.",
			easygoing = "Great, so I can go back to my nap?",
			proud = "Naturally, but thank you for checking.",
			shy = "Oh... thank you.",
			cheeky = "so i'm healthy|great, i'm having cake to celebrate",
			cool = "Thanks. Good to know.",
			prickly = "Told you I was fine.|...Thanks, though.",
			dramatic = "I'll LIVE!|Thank you, thank you!",
			bookish = "Thank you, I'll make a note of it.",
			gloomy = "Huh, I'm fine.|I was sure you'd find something.",
			polite = "Thank you kindly for seeing me.",
			foodie = "Great, so does that mean I can have a bun?",
			nervous = "Really? Nothing at all?|Oh, thank goodness, thank you!",
			_ = "Thanks, that's good to hear.",
		}, "heart")
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
				gentle = "Oh my, that's not quite a heart.|I'll try again, okay?",
				bold = "Hah, it's a potato, and I'm proud of it.",
				dreamy = "Hmm... it's a little cloud.|I like it.",
				easygoing = "Eh, it tastes the same, so it's fine.",
				shy = "Oh... um, it was meant to be a heart.|S-sorry.",
				bookish = "Actually, the milk was two degrees too hot.|That's why.",
				polite = "I do apologise, it was meant to be a heart.",
				foodie = "It looks like a potato, and now I want potatoes.",
				nervous = "Oh no, it's a potato.|Can I do it again? Please?",
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
			gentle = "Ten years, oh my.|I'm just glad it came home.",
			shy = "Ten years...|I don't even know what the fine would be for that.",
			cool = "Ten years late.|That's a new record for us.",
			bookish = "It's ten years overdue, ten years and four days, actually.|I looked it up.",
			dramatic = "A whole DECADE, {player}!|This book has been missing for ten entire years.",
			sunny = "Ten years, ten whole years!|Let's find out who had it!",
			bold = "Ten years late, huh?|Whoever it is owes me a story.",
			dreamy = "Hmm... ten years.|I wonder where it's been all this time.",
			easygoing = "Ten years, huh.|Well, it got here in the end, no rush.",
			proud = "Ten years late, and still in perfect shape.|That's because I chose it for the library.",
			cheeky = "ten years late, that's my kind of reader",
			prickly = "Ten years.|Ugh, people.",
			gloomy = "Ten years late.|Heh... at least it came back, most don't.",
			polite = "Ten years late, goodness.|Well, thank you for returning it, whoever you are.",
			foodie = "Ten years, and there's still a crumb in it.",
			nervous = "Ten years? What if it's missing pages?|Oh, it's all there, okay.",
			_ = "Ten whole years late!|The fine on this would buy a small boat.",
		}, "anger")
		burst(s, "a", {
			gentle = "There's a note tucked inside.|It says sorry, and that they loved every page.",
			proud = "I'm going to frame the date stamp and hang it behind the desk.",
			gloomy = "They looked after it, at least.|That's more than most people do.",
			sunny = "Look, look, there's a note!|It says they loved every page!",
			bold = "There's a note.|They say sorry, and they liked it, so fine.",
			dreamy = "There's a pressed flower inside.|Hmm... it's been here ten years too.",
			easygoing = "It's in good shape.|Eh, I'll put it back on the shelf.",
			shy = "Um... there's a little note inside.|It just says sorry.",
			cheeky = "there's a note that says sorry|and a candy wrapper, gross",
			cool = "It's in good shape. They took care of it.",
			prickly = "It's not even damaged.|...Fine, I forgive them.",
			dramatic = "There's a NOTE, {player}!|It says sorry, and that they loved every page.",
			bookish = "It's one of the old copies, actually, from before I worked here.",
			polite = "It is in very good shape.|I will put it back where it belongs.",
			foodie = "There's a recipe card tucked in the back.|Mmm, plum cake.",
			nervous = "Is it damaged? It's not damaged.|Oh, thank goodness.",
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
			gentle = "I've put roses all around the edge, {player}, so it smells lovely.",
			dreamy = "Hmm... I put one in that only opens at night.|It'll be a little surprise for them.",
			cool = "It's bigger than I am.|I'll need help carrying it.",
			dramatic = "It's taller than me, {player}, it's practically a tower of flowers!",
			nervous = "Will it fit through the door?|Oh no, I never measured the door.",
			sunny = "{player}, look, it's bigger than I am!|Will you help me carry it later?",
			bold = "Biggest bouquet ever, right?|And I'm not done yet.",
			easygoing = "It's huge, and I've been at it since breakfast.|Time for a little sit.",
			proud = "Naturally, it's the most beautiful bouquet on the island.|Look at the colours.",
			shy = "Um... it's very big.|I hope they like it.",
			cheeky = "i used every flower in the shop|and a few from the park, don't tell anyone",
			prickly = "Ugh, it's enormous.|...It's pretty good, though, isn't it?",
			bookish = "There are three hundred flowers in it, actually.|I counted as I went.",
			gloomy = "It'll probably fall apart on the way.|...It does look nice, though.",
			polite = "I do hope they like it.|I put in every colour we have.",
			foodie = "It smells so sweet I keep wanting to eat it.|I won't, though.",
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
		local flavours = { "toast and jam", "seaweed and lemon", "birthday cake", "cucumber and mint" }
		local s = K.scene(ctx, "A new flavour"):with({ flavour = ctx.rng:pick(flavours) })
		burst(s, "a", {
			sunny = "{player}, {player}, I made a new flavour!|It's {flavour}, and the first scoop is free!",
			proud = "I've invented a new flavour, {player}.|It's {flavour}, and you may have the first scoop.",
			cheeky = "new flavour today, it's {flavour}|first scoop's free, if you're brave enough",
			nervous = "I-I made a new flavour, it's {flavour}.|Would you try a scoop and tell me if it's awful?",
			gentle = "{player}, I made a new flavour, {flavour}.|Would you like a little taste?",
			bold = "{player}, new flavour, {flavour}.|You're trying it, right?",
			dreamy = "Hmm... {player}, I had a dream about {flavour}.|So I made it.",
			easygoing = "{player}, I made {flavour} today.|Have a scoop whenever you like.",
			shy = "Um, {player}... I made a new flavour.|It's {flavour}, if you want to try it.",
			cool = "New flavour today, {flavour}.|Try it.",
			prickly = "{player}, try this, it's {flavour}.|Don't make a face before you've tasted it.",
			dramatic = "{player}, the WORLD isn't ready for {flavour}!|But you are.",
			bookish = "{player}, it's {flavour}, and it took me eight tries to get right.|Would you like a scoop?",
			gloomy = "{player}, I made {flavour}.|Nobody's tried it yet, so it's probably bad.",
			polite = "{player}, would you like to try our new flavour?|It is {flavour}.",
			foodie = "Mmm, {player}, you have to try {flavour}.|I've had four scoops already.",
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
				sunny = "Vanilla, okay!|Next time you try the new one, promise?",
				gentle = "Of course, vanilla it is.|Enjoy it, okay?",
				bold = "Vanilla, huh?|Fine, next time you're trying it.",
				dreamy = "Hmm... vanilla's like a little white cloud.|That's nice too.",
				easygoing = "Vanilla, sure, can't go wrong.",
				cool = "Vanilla. Here you go.",
				dramatic = "VANILLA? After all my work?|...Fine, here you go.",
				bookish = "Vanilla is the most popular flavour in the world, actually.|Here you go.",
				gloomy = "Yeah, I figured.|Here's your vanilla.",
				polite = "Of course, one vanilla, coming right up.",
				nervous = "Oh, okay, vanilla.|Was the new one too scary?",
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
			gentle = "Oh my, what a long day at the {pa}.|How was yours?",
			bold = "Long day at the {pa}, but I got through it.|How about yours?",
			dreamy = "Hmm... the day at the {pa} went on forever.|How was yours?",
			proud = "I got everything done at the {pa}, naturally.|How was yours?",
			shy = "Um, it was a long day at the {pa}.|How was yours?",
			cheeky = "survived another day at the {pa}|barely, how about you",
			prickly = "Ugh, the {pa} was a nightmare today.|How was yours?",
			dramatic = "The {pa} nearly DESTROYED me today.|How was yours?",
			bookish = "I counted ninety customers at the {pa} today.|How was yours?",
			gloomy = "Another long day at the {pa}, as usual.|How was yours?",
			polite = "Good evening, it was a long day at the {pa}.|How was yours?",
			foodie = "I didn't even get lunch at the {pa} today.|How was yours?",
			nervous = "I think I did okay at the {pa} today.|How was yours?",
			_ = "That was a long day at the {pa}.|How about you?",
		}, "sweat")
		burst(s, "b", {
			gloomy = "Busy, as usual.|Nobody ever stops needing things at the {pb}.",
			sunny = "Busy, busy, busy at the {pb}!|But it was fun.",
			gentle = "Oh, it was busy at the {pb}.|I'm ready for a quiet evening.",
			bold = "It was chaos at the {pb}, but I handled it.",
			dreamy = "Hmm... the {pb} was busy, I think.|It's all a bit blurry now.",
			easygoing = "It was busy at the {pb}, so I'm going to nap for a week.",
			proud = "The {pb} would have fallen apart without me today.",
			shy = "Um... it was busy at the {pb}.|I didn't sit down once.",
			cheeky = "the {pb} was chaos|i only hid in the back twice",
			cool = "Busy at the {pb}. I'm fine.",
			prickly = "Don't ask about the {pb}.|Ugh, everyone wanted something.",
			dramatic = "CHAOS at the {pb}, from morning to night!",
			bookish = "The {pb} had its busiest day this month, actually.",
			polite = "It was very busy at the {pb}, thank you for asking.",
			foodie = "The {pb} was so busy, I only had one lunch.",
			nervous = "The {pb} was so busy, I'm sure I got something wrong.|Oh no, I probably did.",
			_ = "Don't ask, it was chaos at the {pb} all afternoon.|I didn't sit down once.",
		}, "sweat")
		burst(s, "a", {
			sunny = "Ehehe, that sounds exhausting!|At least it's over now!",
			gentle = "Oh, you poor thing.|Put your feet up tonight, okay?",
			bold = "Hah, sounds like you earned your dinner.",
			dreamy = "Hmm... chaos sounds tiring...|At least it's quiet now.",
			easygoing = "Eh, you need a nap, and so do I.",
			proud = "Well, mine was busier, naturally.",
			shy = "Oh no...|I hope tomorrow's quieter for you.",
			cheeky = "mine was worse, probably|let's just say mine was worse",
			cool = "Sounds rough.|Get some sleep.",
			prickly = "Ugh, same here.|...You did all right, though.",
			dramatic = "We are survivors, you and I!",
			bookish = "Actually, I read that the middle of the week is always the busiest.",
			gloomy = "Heh... sounds like my day.",
			polite = "Oh dear, I am sorry to hear that.|Do rest this evening.",
			foodie = "That calls for a really big dinner.",
			nervous = "Oh no, that sounds awful.|Are you okay?",
			_ = "Sounds like you need a rest.",
		}, "laugh")
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
			gloomy = "Well, there goes the rest of my day, as usual.",
			polite = "I am so sorry, everyone.|Please watch your step while I tidy up.",
			nervous = "Did anything break?|Is anyone hurt? Oh no, oh no.",
			sunny = "Oops, oops!|Ehehe, will you help me pick it all up?",
			gentle = "Oh my, what a mess.|It's all right, I'll tidy it up, okay?",
			bold = "Hah, that went everywhere.|Right, I'll pick it all up.",
			dreamy = "Oh... it's all over the floor.|It looks kind of pretty like that.",
			bookish = "That's about two hundred things on the floor, actually.|I'll start counting them back.",
			foodie = "Oh no, was any of it food?|Okay, good, I'll pick it up.",
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
			polite = "Thank you, everyone.|I am very grateful, truly.",
			nervous = "Are they sure it's me?|It's not a mistake? Oh, wow.",
			foodie = "Do you think it comes with a cake?|It really should come with a cake.",
			gentle = "Oh my, that's so kind of everyone.|I'll keep doing my best.",
			bold = "Hah, worker of the month, right?|I'll make it every month.",
			dreamy = "Hmm... my name looks nice up there.|I'll keep looking at it.",
			cheeky = "worker of the month|i'm framing it, and you have to look at it every day",
			bookish = "Worker of the month, that's twelve chances a year, actually.|I'm happy it's this one.",
			_ = "My name's on the board, {player}.|I'm going to walk past it a few more times.",
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
		s:n("It's lunchtime, and it seems the whole town has turned up at the {place} at once.")
		burst(s, "a", {
			sunny = "Hi, hi, one moment, I'll be right with you!",
			gentle = "One at a time, please, there's plenty for everyone.",
			bold = "Next, please, and keep the line moving!",
			dreamy = "So many faces...|Sorry, who was first again?",
			easygoing = "Okay, breathe, everyone gets served eventually.",
			proud = "Hmph, they all know where the best place in town is.",
			shy = "Um... who's next?|Sorry, I didn't see who was next.",
			cheeky = "make a line, or a circle, i'm not picky",
			cool = "Next, please, and have your coins ready.",
			prickly = "Line up properly or nobody gets anything.",
			dramatic = "The HUNGRY crowds are here, {player}!",
			bookish = "That's forty two people in ten minutes.|I think that's a record, actually.",
			gloomy = "Here they come, all of them at once.|Heh... of course.",
			polite = "Thank you so much for waiting.|I will be with you in just a moment.",
			foodie = "Everyone's hungry at the same time, and I understand completely.|I'm starving too.",
			nervous = "So many people, please don't let me drop anything.|Please, please don't drop anything.",
			_ = "Okay, one at a time, please.",
		}, "sweat")
		s:n("An hour later it was quiet again, and the {place} had taken {coins} coins.")
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
		s:n("{b} has come to the {place} at the same time every day this week, and here they are again.")
		burst(s, "a", {
			sunny = "Hi, hi, is it the usual?|I've already started it!",
			gentle = "Hello again, {b}.|Your usual's ready for you.",
			cool = "The usual?",
			prickly = "Same time, every single day.|...It's ready, obviously.",
			dramatic = "My most loyal customer returns, right on time!",
			bookish = "Right on time again, you could set a clock by you.|Actually, I have.",
			polite = "How nice to see you again, {b}.|The same as yesterday?",
			cheeky = "right on time again|you're so predictable, i love it",
			bold = "{b}, right on time.|The usual, right?",
			dreamy = "Oh... hello again, {b}.|I had a feeling you'd come.",
			easygoing = "Hey, {b}, the usual?|I started it when I saw you coming.",
			proud = "Hello, {b}.|Of course you're back, nobody does it better.",
			shy = "Um, hi, {b}.|Is it... the usual?",
			gloomy = "Hi, {b}.|The usual, I guess.",
			foodie = "Hi, {b}, the usual?|I added a little extra today.",
			nervous = "H-hi, {b}, the usual?|I got it right this time, I hope.",
			_ = "Hi, {b}, is it the usual?",
		}, "wave")
		burst(s, "b", {
			shy = "Oh... you remembered.|Yes, please.",
			easygoing = "Mm, you know me too well.",
			proud = "Of course, why would I change something that's perfect?",
			foodie = "The usual, and maybe one extra as a treat.",
			nervous = "Yes, please, is it weird that I come every day?|It's a bit weird, isn't it?",
			gloomy = "Yeah, it's the one thing I can count on.",
			sunny = "Yes, yes, the usual!|You're the best!",
			gentle = "Oh, thank you, you remembered.|Yes, please.",
			bold = "You know it.|The usual.",
			dreamy = "Hmm... yes, the usual.|It's become a nice little habit.",
			cheeky = "the usual, and don't forget the extra|there's always extra",
			cool = "The usual. Thanks.",
			prickly = "Obviously the usual.|...Thanks for remembering.",
			dramatic = "The usual, my friend, ALWAYS the usual!",
			bookish = "The usual.|That's seven days in a row, actually.",
			polite = "Yes, please, the usual, thank you.",
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
	baker = "braiding a loaf into six strands",
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
			sunny = "Oh, um, this isn't mine!|But it looks nice, ehehe.",
			gentle = "Oh, I'm sorry, but I don't think this is what I asked for.",
			bold = "Hey, that's not what I ordered, right?",
			dreamy = "Hmm... this isn't what I asked for.|Or is it? No, it isn't.",
			easygoing = "Huh, this isn't what I asked for.|Eh, it's probably fine.",
			shy = "Um... sorry, I think this is someone else's.",
			cheeky = "this isn't mine|but i'm not complaining yet",
			dramatic = "*gasp* This is NOT what I asked for!",
			bookish = "Actually, I asked for something else.|I can show you, I wrote it down.",
			gloomy = "This isn't what I asked for.|Heh... of course it isn't.",
			foodie = "Wait, this isn't what I ordered.|It does smell good, though.",
			_ = "Um, this isn't what I asked for.",
		}, "question")
		burst(s, "a", {
			shy = "Oh no, I'm so sorry...|I'll swap it right away.",
			proud = "Hmph, think of it as an upgrade.|You're welcome.",
			cheeky = "surprise!|...no? ok, fair",
			gloomy = "Of course I got it wrong.|Sorry, it's that kind of day.",
			dramatic = "A TERRIBLE mistake, and I'm so sorry!",
			sunny = "Oops, sorry, sorry!|I'll make the right one now!",
			gentle = "Oh my, I'm so sorry.|Let me fix that, okay?",
			bold = "My mistake.|I'll fix it right now.",
			dreamy = "Oh... I was thinking about something else.|Sorry.",
			easygoing = "Huh, oops, my bad.|I'll swap it, no rush.",
			cool = "My mistake. I'll fix it.",
			prickly = "Tsk, fine, my mistake.|Give it here.",
			bookish = "Actually, you're right, I mixed up the orders.|Sorry.",
			polite = "I am so sorry, that is my mistake.",
			foodie = "Oh, sorry, I must be hungry.|I'll make the right one.",
			nervous = "Oh no, oh no, I'm so sorry.|Is that okay? I'll fix it.",
			_ = "Oh, sorry, that's my mistake.",
		}, "sweat")
		s:choice("Could you make it again?", function(c)
			c:n("{a} got it right this time and added a little extra.")
			burst(c, "b", {
				prickly = "...Fine, that's better, thanks.",
				polite = "Thank you so much, that is very kind.",
				sunny = "Yay, thank you!|That's the one!",
				gentle = "Oh, thank you, that's lovely.",
				bold = "That's the one, thanks.",
				dreamy = "Oh... that's the one.|Thank you.",
				easygoing = "Perfect, thanks, no harm done.",
				proud = "Much better.|That's how it should be.",
				shy = "Oh... thank you.|That's the one.",
				cheeky = "that's the one, and you added extra, nice",
				cool = "That's the one. Thanks.",
				dramatic = "PERFECT, thank you!",
				bookish = "That's exactly right, thank you.",
				gloomy = "Huh, that's right.|Thanks.",
				foodie = "Mmm, that's the one, and there's extra too.",
				nervous = "Oh, thank you, I'm sorry for the trouble.",
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
					sunny = "Ooh, this is really good!|I'm getting this next time too!",
					gentle = "Oh, this is nice.|I'll keep it, thank you.",
					bold = "Hah, this is better than mine.",
					dreamy = "Hmm... I think I like this one.|It's a nice surprise.",
					easygoing = "Eh, this is fine, really good, even.",
					proud = "Well, I have good taste, so naturally I like it.",
					shy = "Oh... this is nice.|I'll keep it.",
					cheeky = "ok, this is better|don't tell anyone i said that",
					prickly = "...Fine, it's good.|Don't get used to it.",
					dramatic = "A HAPPY accident!",
					bookish = "Interesting, I'd never have picked this, actually.",
					gloomy = "Huh, I like it.|That's strange.",
					polite = "Oh, this is lovely, thank you.",
					nervous = "Is it okay if I keep it?|I think I like it.",
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
		s:n("Nobody has come by the {place} for hours, and {a} has tidied everything twice.")
		burst(s, "a", {
			sunny = "{player}, a person, finally!|Hi, come in, come in!",
			easygoing = "Honestly, I don't mind at all.|I've had a nice long rest.",
			proud = "I've sorted everything by colour, and then by size.|Then I put it all back the way it was.",
			cool = "It's been quiet for hours, {player}.|I don't mind it.",
			prickly = "Don't come in out of pity, {player}.|...You can come in, though.",
			dramatic = "Alone, {player}, utterly ALONE!",
			bookish = "I've read every label in here.|Some of them are actually very interesting.",
			gloomy = "This is how it'll be forever now.|Heh... I suppose it's the weather.",
			foodie = "I've eaten my lunch, and my snack, and then my second lunch.",
			nervous = "Is everything okay?|Is it something I did?",
			gentle = "Oh, hello, {player}.|It's been quiet, so I made tea, would you like some?",
			bold = "{player}, finally, someone.|Come in, I'll give you the good stuff.",
			dreamy = "Hmm... it's so quiet I could hear the rain on the window.|La la ♪",
			shy = "Oh... hi, {player}.|It's been quiet today.",
			cheeky = "{player}, you're my first customer today|you win a prize, and the prize is me talking to you",
			polite = "Good afternoon, {player}.|It has been very quiet today, so it is nice to see you.",
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
			sunny = "Ooh, someone left {thing}!|Let's find who it belongs to!",
			dreamy = "Hmm... someone left {thing}.|I hope they come back for it.",
			easygoing = "Someone left {thing}.|Eh, they'll come back for it.",
			proud = "Someone left {thing}.|Luckily, I notice everything.",
			shy = "Um... someone left {thing}.|What should I do?",
			cheeky = "finders keepers|jk, whose is this",
			dramatic = "Someone ABANDONED {thing}!|We have to find who it belongs to.",
			gloomy = "Someone left {thing}.|They'll never come back for it.",
			polite = "Oh dear, someone has left {thing}.|I do hope they come back for it.",
			foodie = "Someone left {thing}.|Not a snack, sadly.",
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
				sunny = "In it goes!|They'll come back for it, I just know it!",
				gentle = "There, it'll be safe in there.|I hope they come back soon.",
				bold = "In the box.|They'll come back, right?",
				dreamy = "Hmm... it can keep the other lost things company.",
				easygoing = "There, done, they'll find it eventually.",
				proud = "My lost box is the tidiest box in town.",
				shy = "Okay... in it goes.|I hope they find it.",
				cheeky = "forty one lost things now|it's basically a shop",
				cool = "Done. They'll be back.",
				prickly = "In the box.|And they'd better come back for it.",
				dramatic = "Into the box of LOST things it goes!",
				bookish = "That's forty one things in the lost box, actually.|I keep a list.",
				polite = "It will be safe there until they come back.",
				foodie = "In the box it goes.|At least it's not food, or I'd worry.",
				nervous = "What if they don't know to look in there?|I'll put up a sign.",
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
		s:n("{b} has been hanging around the {place} all morning, watching {a} work.")
		burst(s, "b", {
			shy = "Um... could I help?|I could just hold things for you.",
			bold = "Give me something to do, anything at all.",
			sunny = "Can I help, please?|I'll be really, really good!",
			cool = "Need a hand?|I've got the afternoon free.",
			prickly = "Ugh, I'm bored, so give me a job.|Don't make a big deal of it.",
			polite = "May I help, if it is no trouble?",
			nervous = "Could I help, if that's okay?|I-I might drop things, though.",
			gentle = "Could I help you today?|I'd like to be useful, if that's okay.",
			dreamy = "Hmm... it looks fun, what you're doing.|Could I help?",
			easygoing = "Need help?|I'm free all day, and I'm in no hurry.",
			proud = "I could help, you know.|I'm very good at most things.",
			cheeky = "let me help|i promise to only break one thing",
			dramatic = "Let me HELP, please!",
			bookish = "Could I help?|I've been watching, and I think I know how it works now.",
			gloomy = "Could I help?|You probably don't need me, but I'm here.",
			foodie = "Can I help?|I'll work for snacks.",
			_ = "Can I help?|I'm not doing anything else today.",
		}, "question")
		s:choice("Let {b} help out today.", function(c)
			c:n("{b} stayed until closing and only broke one thing, which was already cracked.")
			burst(c, "a", {
				proud = "Not bad at all.|You might have a gift for this.",
				gentle = "Thank you, {b}, that was a big help.",
				cool = "Good work today.",
				prickly = "You were fine.|Come back tomorrow if you want, whatever.",
				sunny = "Thank you, {b}, that was so fun!|Come back tomorrow!",
				bold = "Good job, {b}.|You're hired, if you want it.",
				dreamy = "Thank you, {b}.|It was nice having someone to hum with.",
				easygoing = "Thanks, {b}, I got to sit down twice today.",
				shy = "Um, thank you, {b}.|That really helped.",
				cheeky = "you only broke one thing, i'm impressed",
				dramatic = "{b}, you were AMAZING!",
				bookish = "Thank you, {b}, we finished forty minutes early, actually.",
				gloomy = "Thanks, {b}.|That went better than I thought.",
				polite = "Thank you very much, {b}, you were a great help.",
				foodie = "Thanks, {b}, here, take a snack for the walk home.",
				nervous = "Thank you, {b}.|Was it okay? I hope it wasn't too hard.",
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
			proud = "This is the best part of the day.|It's a shame the town sleeps through me being brilliant.",
			shy = "Oh... good morning.|You're the first one up.",
			cheeky = "don't tell anyone, but the first batch is always the best one",
			cool = "Morning, want a roll while they're hot?",
			prickly = "Don't talk to me until the third tray.|...Here, have a roll.",
			dramatic = "While the whole town sleeps, the baker WORKS away in the dark!",
			bookish = "Dough rises faster when it's warm, actually.|That's why I start so early.",
			gloomy = "Four o'clock every day, as usual.|It's fine, I like the quiet.",
			polite = "Good morning, {player}.|Please have one, my treat.",
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
		local s = K.scene(ctx, "Mail for you")
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
			dreamy = "Hmm... {player}, this one smells like the sea.|It's for you.",
			easygoing = "Oh, {player}, there's one for you.|Saves me a walk.",
			bookish = "{player}, this one's for you.|It came from two islands over, actually.",
			gloomy = "{player}, there's one for you.|It's probably not bad news.",
			polite = "Good morning, {player}.|There is a letter for you.",
			foodie = "{player}, there's one for you.|It's got a jam stain on it, sorry.",
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
			cheeky = "spelled it right this time, i think|hehe, probably",
			cool = "I made you one.|Your name's on top.",
			prickly = "It's just a coffee, so don't make a face.",
			dramatic = "Your name, {player}, written in MILK!",
			nervous = "Is it spelled right?|Please tell me it's spelled right.",
			easygoing = "Here, {player}, your name in the foam.|Drink it slowly, no rush.",
			bookish = "Here, {player}, your name in the foam.|It took eleven tries to get the letters right, actually.",
			gloomy = "Here, {player}.|The letters will melt in a minute, so look fast.",
			polite = "Here you are, {player}.|I hope I spelled your name correctly.",
			foodie = "Here, {player}, it's your name in the foam.|I put a little cinnamon on it, too.",
			_ = "This one's for you, {player}.",
		}, "heart")
		s:choice("*sip*", function(c)
			burst(c, "a", {
				shy = "Oh... you've got a foam moustache now.|Here, have a napkin.",
				cheeky = "foam moustache, nice|i'm not telling you where",
				proud = "Hmph, there goes my lettering.|...You've got a foam moustache, by the way.",
				polite = "Oh, you have a little foam on your lip, {player}.",
				sunny = "Ehehe, foam moustache!|It suits you!",
				gentle = "Oh my, you've got a little foam on your lip.|Here, a napkin.",
				bold = "Hah, foam moustache.|Looks good on you.",
				dreamy = "Hmm... you've got a little cloud on your lip.",
				easygoing = "Heh, foam moustache, I'll leave it there.",
				cool = "Foam. On your lip.",
				prickly = "Ugh, you've got foam everywhere.|Here, a napkin.",
				dramatic = "A MOUSTACHE! *gasp*|It's wonderful.",
				bookish = "Actually, that's the best way to drink it, from the top.|You've got a foam moustache, though.",
				gloomy = "There goes your name.|Heh... and now you've got a foam moustache.",
				foodie = "Good, right?|And you've got a foam moustache, by the way.",
				nervous = "Is it okay? Is it too hot?|Oh, you've got a little foam on your lip.",
				_ = "Ha, now you've got a foam moustache.",
			}, "laugh")
			c:hearts("a", 1)
			c:xp("a", 5)
		end)
		s:choice("Wait, let me look first.", function(c)
			burst(c, "a", {
				proud = "Take your time, it's a work of art.",
				shy = "Oh... you like it?|Okay, good.",
				sunny = "Look as long as you like!|I'll make you another one tomorrow!",
				gentle = "Of course, take your time.|Just don't let it go cold, okay?",
				bold = "Go on, look.|It's good, right?",
				dreamy = "Hmm... it's nice to look at things slowly.",
				easygoing = "Sure, no rush, take your time.",
				cheeky = "take a picture, it'll last longer",
				cool = "Take your time. Drink it warm.",
				prickly = "Don't stare at it.|...Okay, you can stare a little.",
				dramatic = "Yes, LOOK at it, take it all in!",
				bookish = "Take your time, the foam holds for about three minutes, actually.",
				gloomy = "Look fast, it'll be gone in a minute.",
				polite = "Please, take your time.",
				foodie = "Look all you like, but it tastes better warm.",
				nervous = "Is it okay?|You can tell me if it's wobbly.",
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
			gentle = "Oh my, it's melting so fast.|Here, have one before it's gone.",
			dreamy = "Hmm... it's turning into little rivers.|They're pretty, though.",
			easygoing = "Eh, it's melting, and honestly, so am I.",
			proud = "My ice cream is too good to waste.|Somebody eat it, quickly.",
			shy = "Um... it's melting.|I don't know what to do.",
			cheeky = "it's soup now|ice cream soup, very fancy",
			bookish = "It melts twice as fast in direct sun, actually.|I should have brought the umbrella.",
			polite = "Oh dear, it is all melting.|Would you like one, quickly?",
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
		s:n(
			"{a} has started a painting of the harbour on the side of the bakery, with all the boats in and one corner still empty."
		)
		burst(s, "a", {
			sunny = "{player}, what should go in the corner?|Pick something, anything!",
			proud = "When it's finished, people will come from other islands to see it.|You may suggest something for the corner, if you like.",
			shy = "I left a gap in the corner...|I couldn't decide what to put there.",
			cool = "There's a gap left in the corner.|Any ideas?",
			prickly = "Don't say 'a gull'.|...Okay, fine, you can say 'a gull'.",
			dramatic = "This wall is becoming a window onto the sea, {player}!|Only the corner is left, so what goes there?",
			bookish = "Outdoor paint takes two days to dry, three if it rains.|I've left the corner until last, so any ideas?",
			gloomy = "It'll fade in the sun eventually, heh.|Before it does, what should go in the corner?",
			foodie = "There's going to be a big bun in it somewhere.|What else should go in the corner, though?",
			nervous = "Is it okay that it's on the bakery? They said yes, I think.|And what should go in the corner?",
			gentle = "There's just the corner left, {player}.|What do you think would look nice there?",
			bold = "One corner left, {player}.|Tell me what goes there, and I'll paint it.",
			dreamy = "Hmm... the corner's still empty.|Something small should go there, I think.",
			easygoing = "I've got one corner left, and I'm out of ideas.|What do you think?",
			cheeky = "one corner left|if you say a gull, i'm painting you instead",
			polite = "Thank you for stopping, {player}.|What would you put in the corner?",
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
				sunny = "Ehehe, a tiny me!|Look, I'm waving!",
				gentle = "Oh, that's sweet.|A tiny me, waving at everyone.",
				bold = "Hah, there I am.|Everyone will know who painted it.",
				dreamy = "Hmm... a little me, looking at the sea.|I like that.",
				easygoing = "A tiny me, having a rest in the corner.|Perfect.",
				cheeky = "tiny me, waving|now i'm famous",
				cool = "That works. Small, though.",
				prickly = "Fine, but it's very small.|Don't point it out to people.",
				dramatic = "Now I'm part of the harbour FOREVER!",
				bookish = "Lots of painters put themselves in a corner, actually.|It's an old trick.",
				gloomy = "A tiny me.|Heh... it'll be the first bit to fade.",
				polite = "Oh, I hope that is not too much.",
				foodie = "A tiny me, holding a tiny bun.",
				nervous = "Is that too much?|Can people tell it's me? Oh no.",
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
			gentle = "Oh my, it's getting dark.|Could you help me finish before it rains?",
			dreamy = "Hmm... the clouds are coming in fast.|I think I'd better hurry.",
			easygoing = "Eh, I can probably finish before it rains.|Probably.",
			proud = "I'll have this done before the first drop, naturally.|...Could you pass me bricks, though?",
			shy = "Um, {player}?|Could you help me finish before it rains?",
			cheeky = "race you to the end of the wall|me with bricks, you with the bucket",
			bookish = "The rain will be here in about fifteen minutes.|I need eighteen, actually.",
			polite = "Excuse me, {player}, could you help me, please?|The rain is coming.",
			foodie = "If I finish before it rains, I'm having a big lunch.|Will you help me?",
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
			bookish = "This is the oldest copy we have, actually.|The words are a little different from the new one.",
			gloomy = "This part is sad, so be ready.",
			polite = "Thank you all for coming.|Is everyone ready to begin?",
			nervous = "Can everyone hear me?|Should I be louder? Okay, chapter four.",
			dreamy = "Hmm... where did we stop last time?|Oh, the lighthouse, that's right.",
			bold = "Chapter four, and it's a good one.|Everyone sit down, right?",
			easygoing = "Chapter four, everyone.|Lie down if you want, I won't mind.",
			proud = "I read this chapter better than anyone, so listen closely.",
			shy = "Um... chapter four.|I'll try to read loud enough.",
			cheeky = "chapter four, and i'm doing all the voices|even the pigeons",
			foodie = "Chapter four, and there's a feast in this one.|Try not to get hungry.",
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
			dreamy = "Hmm... you look like a plant that needs watering.|Doctor's orders, go and have a glass.",
			easygoing = "That long? Go and have a glass.|No rush, but soon.",
			shy = "Um... you should have some water.|S-sorry, it's my job to say.",
			cheeky = "you look like a raisin|drink some water, raisin",
			_ = "Go and have a glass, doctor's orders.",
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
				sunny = "Okay, but I'm checking later!|Promise, promise?",
				gentle = "All right, but don't forget, okay?",
				bold = "Fine, but I'll be checking.",
				dreamy = "Hmm... okay.|I'll remind you when the sun goes down.",
				easygoing = "Sure, later's fine, I like later.",
				proud = "Fine, but my advice is always right.",
				shy = "Okay... please don't forget.",
				cheeky = "sure you will|i'm watching you",
				cool = "Later, then. Don't forget.",
				dramatic = "I'll be COUNTING the minutes!",
				bookish = "Later is fine, but within the hour, actually.",
				gloomy = "That's what everyone says.|Heh... okay.",
				polite = "Very well, but please do not forget.",
				foodie = "Later, with a snack, okay, that's fair.",
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
	teacher = "an old school desk with forty years of names scratched into the lid",
	doctor = "a jar of candy labelled 'for brave patients only', still full",
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
			easygoing = "So I was putting off the sweeping, like always.|And then I found something at the {place}.",
			proud = "{player}, I've made a discovery at the {place}.|Naturally, I was the one who found it.",
			shy = "Um, {player}?|I found something at the {place}, and I didn't know who else to tell.",
			cheeky = "{player}, guess what i found at the {place}|wrong, come and see",
			cool = "{player}, I found something at the {place}.|You should see it.",
			prickly = "Don't make a big fuss.|But you should come and see what I found at the {place}.",
			dramatic = "{player}, the {place} was hiding a secret all this time!|And I'm the one who found it.",
			bookish = "{player}, I think I've found something old at the {place}.|Actually, quite old.",
			gloomy = "I found something at the {place}.|It's probably nothing... heh, actually, it isn't nothing.",
			polite = "Excuse me, {player}.|I have found something at the {place} that you may like to see.",
			foodie = "I found something at the {place}.|Sadly it's not food, but it's still good.",
			nervous = "I found something at the {place}.|Is it okay that I found it?|Should I give it back, and if so, to who?",
			_ = "{player}, I found something at the {place}.",
		}, "idea", "point")
		s:n("It's {found}.")
		s:choice("Who left it there?", function(c)
			burst(c, "a", {
				bookish = "I don't know yet, but I'll ask at the library.|I love a mystery like this.",
				dreamy = "Hmm... someone who wanted it found one day.",
				cool = "I don't know.|I'll keep it safe until someone asks.",
				sunny = "I don't know, but let's find out together!",
				gentle = "I don't know, but I'll keep it safe for them, okay?",
				bold = "No idea, but I'm going to find out.",
				easygoing = "No idea, it's been there forever, I think.",
				proud = "I'll find out, naturally, I always do.",
				shy = "Um... I don't know.|Maybe someone from a long time ago.",
				cheeky = "a ghost, obviously|jk, i have no idea",
				prickly = "How should I know?|...I'll ask around, though.",
				dramatic = "A MYSTERY, {player}!|And I'm going to solve it.",
				gloomy = "Someone who forgot about it, probably.|Heh... everyone forgets things.",
				polite = "I do not know, but I will ask around.",
				foodie = "No idea, but I'll ask around at lunch.",
				nervous = "I don't know!|What if they want it back? Should I ask around?",
				_ = "I don't know.|I'll keep it safe until somebody asks about it.",
			}, "question")
			c:mood("a", 4)
			c:memo("a", "Nobody's come for the thing I found at work yet, but I check every day.")
		end)
		s:choice("Can I see it up close?", function(c)
			c:n("You turned it over in your hands while {a} watched as if it might break.")
			burst(c, "a", {
				prickly = "Careful with it.|...Okay, you can hold it a bit longer.",
				shy = "...!|You like it? I'm glad I told you.",
				sunny = "Isn't it great?|Let's show everyone!",
				gentle = "Careful, it's very old.|Isn't it lovely?",
				bold = "Good, right?|I knew you'd like it.",
				dreamy = "Hmm... it feels like it's been waiting for someone.",
				easygoing = "Take your time with it, no rush.",
				proud = "Isn't it wonderful?|And I found it, don't forget.",
				cheeky = "careful, it's probably cursed|jk",
				cool = "Careful with it. It's old.",
				dramatic = "Hold it GENTLY, {player}!",
				bookish = "It's at least fifty years old, actually.|Look at the edges.",
				gloomy = "It's nice, isn't it?|I keep thinking I'll break it.",
				polite = "Please, take your time with it.",
				foodie = "Careful, I've just had lunch, so it might be a bit sticky.",
				nervous = "C-careful, please.|Okay, it's fine, you're doing fine.",
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
			gentle = "{player}, there's smoke at the {place}.|Could you come quickly, please?",
			dreamy = "{player}... is that smoke at the {place}?|Or fog? I think it's smoke.",
			easygoing = "{player}, there's smoke at the {place}.|Not great, can you bring a bucket?",
			proud = "{player}, there's smoke at the {place}.|I'm handling it, but bring a bucket.",
			cheeky = "{player}, the {place} is smoking|not in a cool way, bring a bucket",
			prickly = "{player}, there's smoke at the {place}.|Don't just stand there, get a bucket.",
			bookish = "{player}, there's smoke coming out of the {place}.|It's white, so it might be steam, but bring a bucket.",
			polite = "Excuse me, {player}, there is smoke at the {place}.|Could you help, please?",
			foodie = "{player}, there's smoke at the {place}!|Did somebody leave the toast on?",
			_ = "{player}, there's smoke coming out of the {place}.",
		}, "sweat")
		s:n("You ran over with a bucket, but it was only steam from a kettle someone had left boiling nearby.")
		burst(s, "a", {
			nervous = "It was only steam.|I'm going to sit down for a very long time.",
			sunny = "It was steam, ehehe!|That was a lot of running for some steam!",
			gloomy = "Huh, it was just steam.|Things don't usually turn out fine for me.",
			dramatic = "It was steam.|We will speak of this to NO ONE.",
			cool = "...It was steam.|Sorry for the run.",
			bold = "Hah, just steam.|Good practice, though, right?",
			prickly = "It was the kettle.|Ugh, don't say it, I know.",
			gentle = "Oh my, it was only the kettle.|Thank you for coming so fast.",
			dreamy = "Oh... it was steam.|It looked so much like smoke.",
			easygoing = "Heh, just the kettle.|I'm going to sit down now.",
			proud = "Steam, of course.|I knew that, I was testing your speed.",
			shy = "Oh... it was steam.|S-sorry for the fuss.",
			cheeky = "it was the kettle|i'm never telling anyone about this",
			bookish = "It was steam, actually.|Steam is white and smoke is grey, I should have known.",
			polite = "It was only the kettle.|I am so sorry for the trouble.",
			foodie = "Only the kettle.|Well, since it's boiling, let's have tea.",
			_ = "It was only the kettle.|I really thought the whole place was going up.",
		}, "sweat", "laugh")
		s:choice("Better safe than sorry.", function(c)
			burst(c, "a", {
				nervous = "Yes, exactly.|Thank you for not laughing at me.",
				prickly = "Exactly.|...Thanks for coming.",
				sunny = "Yes, yes!|Thanks for running over, {player}!",
				gentle = "Thank you for coming, {player}.|You're very kind.",
				bold = "Exactly.|Thanks for coming fast.",
				dreamy = "Hmm... yes.|Thank you for running.",
				easygoing = "Yeah, thanks for coming, I'll put the kettle away.",
				proud = "Naturally.|...Thank you for coming, though.",
				shy = "Um... thank you for coming.|Really.",
				cheeky = "thanks for coming|you ran funny, but thanks",
				cool = "Right. Thanks for coming.",
				dramatic = "My HERO, with a bucket!",
				bookish = "Exactly, and you got here in under a minute, actually.",
				gloomy = "Yeah.|Thanks for coming, {player}.",
				polite = "Thank you so much for coming, {player}.",
				foodie = "Thanks, {player}.|Stay for tea, the water's hot.",
				_ = "Yeah, thanks for coming so fast, {player}.",
			}, "heart")
			c:hearts("a", 1)
			c:mood("a", 3)
		end)
		s:choice("Should I keep the bucket handy?", function(c)
			burst(c, "a", {
				cheeky = "yes, just in case|that kettle looks guilty",
				gloomy = "Heh... yes, actually.",
				sunny = "Yes, by the door!|Ehehe, just in case!",
				gentle = "That's a good idea.|By the door, okay?",
				bold = "Yeah, by the door.|Just in case, right?",
				dreamy = "Hmm... by the door.|It can hold flowers until we need it.",
				easygoing = "Sure, leave it there, I'll move it later.",
				proud = "I always have a bucket ready.|...From now on.",
				shy = "Um... yes, please.|By the door.",
				cool = "By the door. Good idea.",
				prickly = "Fine, put it by the door.|Not for the kettle, just in general.",
				dramatic = "Keep it CLOSE, {player}!",
				bookish = "By the door, half full, is best, actually.",
				polite = "Yes, please, by the door would be best.",
				foodie = "By the door, next to the snacks.",
				nervous = "Yes, please, and maybe a second one.",
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
			gentle = "{player}, I'm on my own at the {place} tomorrow.|I'm a little nervous, but I'll be okay.",
			bold = "{player}, I'm running the {place} on my own tomorrow.|I'll be fine, right?",
			dreamy = "Hmm... {player}, I'm on my own at the {place} tomorrow.|It feels strange to think about.",
			easygoing = "{player}, they're leaving me on my own at the {place} tomorrow.|Eh, it'll be fine, I think.",
			cheeky = "{player}, i'm in charge of the {place} tomorrow|i'm making new rules",
			dramatic = "{player}, tomorrow I face the {place} ALONE!",
			bookish = "{player}, I'm on my own at the {place} tomorrow.|I've read the notes four times, actually.",
			polite = "Good evening, {player}.|I will be on my own at the {place} tomorrow, and I am a little nervous.",
			foodie = "{player}, I'm on my own at the {place} tomorrow.|I'm packing a very big lunch.",
			_ = "{player}, I'm on my own at the {place} tomorrow.|What if it goes wrong?",
		}, "sweat")
		s:choice("You'll be fine.", function(c)
			burst(c, "a", {
				nervous = "Okay, okay.|I'll check everything twice.",
				gloomy = "You think so?|...Okay, maybe you're right.",
				prickly = "I know.|...Thanks, though.",
				sunny = "You think so? Yay!|I'll do my best!",
				gentle = "Thank you, {player}.|That helps a lot.",
				bold = "Yeah, I will, right?|Thanks.",
				dreamy = "Hmm... okay.|I'll try to remember you said that.",
				easygoing = "Yeah, probably.|Thanks, {player}.",
				proud = "Of course I will.|...Thank you, though.",
				shy = "Okay...|Thank you, {player}.",
				cheeky = "obviously|but thanks",
				cool = "Okay. Thanks.",
				dramatic = "Your faith gives me STRENGTH!",
				bookish = "You're right, I've prepared for it.|Thank you.",
				polite = "Thank you, {player}, that is kind of you.",
				foodie = "Thanks.|I'll feel better after dinner.",
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
				gentle = "Oh, would you?|Thank you, {player}, that means a lot.",
				bold = "You'd do that?|...Thanks. Anyway, come early.",
				dreamy = "Oh... that's nice.|I'll save you the first one.",
				easygoing = "That'd be great, but no rush, come whenever.",
				proud = "I don't need it, but I'd like that.",
				cheeky = "first customer gets a prize|the prize is me being nervous at you",
				prickly = "You don't have to.|...But okay, come early.",
				dramatic = "My FIRST customer!|I'll never forget it.",
				bookish = "Thank you, we open at eight, actually.",
				gloomy = "You'd do that?|Heh... thanks, {player}.",
				polite = "Thank you very much, {player}, I would like that.",
				foodie = "Then I'll have something warm ready for you.",
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
