--!nonstrict
-- Things one villager goes through: small odd days, hobbies, the weather, dreams and daydreams,
-- and the things they make (some of which they'll give you, as keepsakes). How they take it is
-- their own: Kit's s:by picks the line by their personality. They talk the way a friend texts
-- you (the user's reference was a messaging app's chats): the villager speaks first, in bursts
-- of two or three messages, your answer is one of two short replies, and they take it in
-- another little burst. Each message is one whole sentence a person would really send (the
-- user: "avoid having strings of short sentences"), and each personality has its habits (a
-- laugh, a stammer, a sign off) used now and then, never on every line. Now and then they use
-- your name ({player}), most often first.

local K = require(script.Parent.Kit)
local Sayings = require(script.Parent.Parent.Sayings)
local Foods = require(script.Parent.Parent.Foods)

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

-- How they take it when the thing they tried comes off.
local BRAG = {
	sunny = "Wait, wait, did you see that?|It actually worked, ehehe!",
	proud = "Hmph, naturally it worked.|Go on, you can say it was impressive.",
	bold = "Hah, told you I could do it.",
	shy = "...!|Um, I think it actually worked.",
	cheeky = "ok did you see that|first try, well, third, but who's counting",
	cool = "Hm, that came out clean.",
	prickly = "Ugh, don't make a fuss about it.|...It was pretty good, though, wasn't it?",
	dramatic = "Did everyone SEE that?|That was the finest moment of my whole life.",
	bookish = "It went exactly the way I planned it on paper.|I'm writing down every step before I forget.",
	gloomy = "Heh... it actually worked for once.|I keep waiting for the catch.",
	gentle = "Oh, my, it worked.|I'm so glad you were here to see it.",
	dreamy = "Hmm, it worked.|I think it just wanted to work today.",
	easygoing = "Mm, that went well, and I barely even tried.",
	polite = "Oh, how pleasing.|Thank you kindly for watching.",
	foodie = "That calls for a bun to celebrate.|Maybe two, if the bakery's still open.",
	nervous = "I-it worked?|Oh, thank goodness, I was so sure it wouldn't.",
	_ = "It actually worked.|Did you see it?",
}

-- Something they made, which they may let you keep: shown while the scene plays, given as a
-- keepsake (Build/Recipes/Keepsakes) if you ask for it, kept if you tell them to.
local function makes(o: { [string]: any })
	event({
		id = o.id,
		when = o.when or "day",
		weight = W(o.w),
		scene = function(ctx, a)
			local s = K.scene(ctx, o.title)
			s:prop("item:" .. o.item, "a")
			for _, l in o.lines do
				if l[1] == "n" then
					s:n(l[2])
				else
					burst(s, l[1], l[2], l[3], l[4])
				end
			end
			burst(s, "a", o.react, "sparkle")
			s:choice(o.ask or "Can I have it?", function(c)
				burst(c, "a", {
					shy = "...!|Um, you really want it?|Okay, here, but please be gentle with it.",
					proud = "Hmph, of course you want it.|Look after it, {player}, because there isn't another one like it.",
					cheeky = "hmm ok, you can have it|but i get to visit it whenever i want, hehe",
					dreamy = "Hmm... I think it wanted to go with you anyway.|It'll be happier at your place, I can tell.",
					bold = "Hah, take it, it's yours.|No giving it back, got it?",
					easygoing = "Sure, go ahead.|It saves me finding a shelf for it, heh.",
					gentle = "Of course you can, {player}.|I'd really like you to have it.",
					sunny = "You really want it?|Here, here, take it, and put it somewhere I can see it when I come over!",
					cool = "Sure, it's yours.|...I'm glad you like it.",
					prickly = "Ugh, fine, take it before I change my mind.|And don't let it get dusty, okay?",
					dramatic = "Then it is DECIDED, it goes home with {player}!|Treat it like the treasure it is.",
					bookish = "Of course you can.|Actually, if you keep it out of the sun, it should last for years.",
					gloomy = "You actually want it?|Heh... okay, that's really nice of you.",
					polite = "I'd be honoured, {player}.|Thank you kindly for asking.",
					foodie = "Sure, it's yours.|Bring me a biscuit sometime and we'll call it even.",
					nervous = "Y-you're sure you want it?|Okay, here, I know you'll be careful with it.",
					_ = { "Of course you can, here you go.", "You want it? Here you go, {player}." },
				}, "heart", "cheer")
				c:keep(o.item, "a")
				c:mood("a", 4)
				c:hearts("a", 1)
				c:memo("a", o.memo)
			end)
			s:choice(o.keep or "Keep it, it's yours.", function(c)
				burst(c, "a", {
					proud = "Good, then it's going in my front window.|Everyone who walks past will see it.",
					shy = "Okay...|I'll keep it somewhere safe.",
					cheeky = "good, because i wasn't really going to give it away|hehe",
					dreamy = "Then it stays here with me...|I'll put it where I can see it every morning.",
					cool = "Okay, it stays with me.",
					prickly = "Good.|...I like it more than I let on, so don't read into it.",
					dramatic = "Then it shall stay with its maker, as it should!",
					gloomy = "Okay, somebody should keep it.|It might as well be me.",
					polite = "Thank you, I'll take very good care of it.",
					nervous = "Oh, phew.|I'd have worried about it the whole time it was away.",
					_ = "Okay, I'll find it a good spot at home, {player}.",
				}, "heart")
				c:mood("a", 6)
				c:memo("a", o.memo)
			end)
			s:log(o.log)
			return s:done()
		end,
	})
end

-- hiccups --------------------------------------------------------------------------------------------

event({
	id = "hiccups",
	when = "day",
	weight = W({ base = 0.3 }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "Hiccups")
		s:n("{a} has had the hiccups since breakfast.")
		burst(s, "a", {
			proud = "Hmph, these hiccups have lasted since breakfast.|I've tried everything, and I do mean everything.",
			shy = "Um, {player}...|I've had the hiccups all morning, so please don't laugh if I, um... hic.",
			bold = "I've had these hiccups for three hours, {player}.|I'm going to beat them if it takes all day.",
			dreamy = "Every hiccup feels like a little bubble popping...|There goes another one.",
			cheeky = "ok so i've had the hiccups since breakfast|hic|i'm pretending i'm doing it on purpose",
			sunny = "{player}, I've had the hiccups since breakfast!|I can't even say hello properly, ehehe.",
			cool = "Hic.|...Ignore that, I've had them all morning.",
			prickly = "Ugh, I've had the hiccups since breakfast.|Don't say a single word about it.",
			dramatic = "{player}, I have suffered three HOURS of hiccups.|My dignity is gone.",
			bookish = "Actually, a hiccup is just your diaphragm twitching.|Knowing that hasn't helped me at all, sadly.",
			gloomy = "Heh... I've had the hiccups since breakfast.|They'll probably last until bedtime.",
			polite = "Hello, {player}, and I do beg your pardon.|I've had the hiccups since breakfast.",
			foodie = "I ate my porridge far too fast this morning.|It was worth it, though, because it had honey in it.",
			nervous = "W-what if these hiccups never stop?|Is that something that can actually happen to people?",
			_ = {
				"I'm totally fine, hic, completely fine.",
				"I've had the hiccups for three hours now.|Three whole hours.",
			},
		}, "sweat")
		s:choice("Want me to scare them out?", function(c)
			c:n("You crept up behind {a} and shouted boo.")
			burst(c, "a", {
				shy = "Eep!|...Oh, they're gone.",
				bold = "Hah, you actually got me.|...And they're gone, nice work.",
				easygoing = "Whoa, don't do that to me.|...Oh, they stopped, heh, thanks.",
				cool = "That was unnecessary.|It worked, though.",
				prickly = "Seriously?|...Oh, they actually stopped, so I guess thanks.",
				dramatic = "My HEART!|...Wait, my hiccups are gone.",
				nervous = "Aah, my heart's racing!|...Wait, are they gone?",
				cheeky = "aah, rude|...oh, they've stopped, hehe",
				_ = "Aah!|...Wait, they've stopped.",
			}, "sparkle")
			c:mood("a", 4)
			c:memo("a", "{player} scared my hiccups away, which was rude, but it worked.")
		end)
		s:choice("Try drinking water upside down.", function(c)
			c:n("{a} bent over and tried to drink from the far side of the glass.")
			burst(c, "a", "Now I've got water all down my front.|And I've still got the hiccups.", "sweat")
			c:mood("a", -1)
			c:memo("a", "Never try drinking water upside down, trust me on this one.")
		end)
		s:log("{a} had the hiccups all morning.")
		return s:done()
	end,
})

-- a new hobby ------------------------------------------------------------------------------------------

event({
	id = "newhobby",
	when = "day",
	weight = W({ base = 0.25, traits = { focus = -0.3 } }),
	scene = function(ctx, a)
		local v = ctx.v(a)
		local options = {}
		for _, h in Sayings.hobbies do
			if h.id ~= v.hobby then
				table.insert(options, h)
			end
		end
		local h = ctx.rng:pick(options)
		local s = K.scene(ctx, "A new hobby"):with({ hobby = h.name })
		burst(s, "a", {
			sunny = "{player}, {player}, guess what!|I've decided to take up {hobby}!",
			bold = "{player}, I've made up my mind.|I'm taking up {hobby}, starting today.",
			shy = "Um, {player}...|I've been thinking that maybe I'd like to try {hobby}.",
			cheeky = "guess what|actually don't guess, i'm taking up {hobby}",
			cool = "{player}.|I'm going to take up {hobby}.",
			dramatic = "{player}, today a new chapter of my life begins.|It's the chapter of {hobby}!",
			polite = "Excuse me, {player}, if you have a moment.|I've decided to take up {hobby}.",
			_ = "{player}, I've decided something.|I'm going to take up {hobby}.",
		}, "idea", "point")
		burst(s, "a", {
			bold = "There's no point waiting around.|You're coming to watch me try, right?",
			shy = "Is that a silly idea?|You don't have to answer that.",
			cheeky = "don't laugh|i can tell you're about to laugh",
			sunny = "I already told everyone at the market, so now I have to do it!",
			easygoing = "It seems relaxing, and I'm hoping it's mostly sitting down.",
			dreamy = "The idea came to me in a dream...|Well, during a nap, but I think that counts.",
			proud = "Naturally, I expect I'll be good at it.|Most things come easily to me, after all.",
			cool = "It seemed worth a try.",
			prickly = "Don't make a big thing out of it, okay?",
			dramatic = "I've already bought a special hat for it!",
			bookish = "I've read two books about it already.|Now I just have to actually do it.",
			gloomy = "I'll probably be terrible at it.|I want to try anyway, though.",
			polite = "If you have any tips, I'd be very grateful to hear them.",
			foodie = "Is there a snack that goes with it?|There really should be one.",
			nervous = "W-what if I turn out to be terrible at it?|Please tell me if I am, but gently.",
			_ = "I've already bought everything I need for it.|Please don't tell me it's silly.",
		}, "sparkle")
		s:choice("Go for it.", function(c)
			burst(c, "a", {
				easygoing = "Right, I'll start straight after a snack.",
				shy = "...!|Okay, I'll give it a try.",
				proud = "I intend to.|Watch me be good at it right from the start.",
				prickly = "I was going to anyway.|...But thanks.",
				nervous = "O-okay, I'm really going for it.|Wish me luck!",
				gloomy = "Okay... if you think so, {player}, I'll give it a go.",
				sunny = "Ehehe, I knew you'd say that!|I'm starting right now!",
				_ = "Right, I'm starting now.",
			}, "music", "cheer")
			c:hobby("a", h.id)
			c:mood("a", 6)
			c:memo("a", "I've taken up {hobby}, so please ask me about it sometime.")
		end)
		s:choice("Isn't that your fifth hobby?", function(c)
			burst(c, "a", {
				proud = "Th-that would only be my fourth!|And I would have been very good at this one.",
				bold = "Hah, fine, forget I said anything.",
				shy = "Oh...|Yeah, it was a silly idea, sorry.",
				dramatic = "And so another dream is folded up and put away.|Fine, I see how it is.",
				cool = "Hm, that's fair.",
				cheeky = "wow, traitor|it's my sixth, actually, hehe",
				gloomy = "Heh... yeah, and I gave up on the other four too.",
				sunny = "Aw, but this one's different!|...Okay, maybe it isn't.",
				_ = "Okay, maybe you're right.",
			}, "sad")
			c:mood("a", -2)
		end)
		s:log("{a} wanted to take up {hobby}.")
		return s:done()
	end,
})

-- odd socks ----------------------------------------------------------------------------------------------

event({
	id = "sock",
	when = "any",
	weight = W({ base = 0.25, traits = { focus = -0.3 } }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "The missing sock")
		s:n("{a} is wearing one blue sock and one stripy one.")
		burst(s, "a", "My other blue sock has gone missing.|I've looked everywhere, even in the fridge.", "question")
		burst(s, "a", {
			proud = "So I've decided odd socks are the new fashion.|You saw it here first.",
			dreamy = "Maybe it went off on a little trip...|I hope it's having a nice time.",
			cheeky = "someone in this town is stealing socks|and i'm going to find out who",
			gentle = "Oh well, this stripy one keeps my foot just as warm.",
			sunny = "Have you seen it anywhere, {player}?|It's blue and a bit sad looking.",
			cool = "It'll turn up eventually.",
			prickly = "Whatever, nobody looks at socks anyway.",
			dramatic = "It left without a single word!|After all the miles we walked together.",
			bookish = "Did you know people lose about one sock a month?|I looked it up after I lost the third one.",
			gloomy = "Things always go missing, that's just what they do.|Especially my things.",
			foodie = "I don't know why I checked the fridge.|I did have a snack while I was in there, though.",
			nervous = "What if it ended up in someone else's washing?|That would be so awkward to ask about.",
			_ = "Does anyone even look at socks?|Actually, don't answer that.",
		}, "sweat")
		s:mood("a", 1)
		s:memo("a", "I'm still one sock short, in case you were wondering.")
		s:log("{a} lost a sock.")
		return s:done()
	end,
})

-- a song stuck in their head -------------------------------------------------------------------------

event({
	id = "earworm",
	when = "day",
	weight = W({ base = 0.25 }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "Stuck in my head")
		s:n("{a} has been humming the same four notes all day.")
		s:say("a", "Dum da dum DUM.", "music")
		burst(s, "a", {
			cool = "I've had that tune in my head since breakfast.|Make it stop.",
			prickly = "Ugh, if you start humming it too, I'm leaving.",
			nervous = "I-is the humming annoying you?|Sorry, I can't seem to stop.",
			dramatic = "This tune HAUNTS me, {player}, day and night!",
			easygoing = "It's been going round my head since breakfast.|I've given up fighting it, honestly.",
			_ = "{player}, I can't get this tune out of my head.|Please make it stop.",
		}, "sweat")
		s:choice("Dum da dum DUM.", function(c)
			burst(c, "a", {
				cheeky = "oh, harmonies now?|hehe, we're a band",
				sunny = "Ehehe, now we've both got it!",
				cool = "Hm.|That wasn't bad, actually.",
				prickly = "Great, now it's stuck in both our heads.|Thanks a lot.",
				polite = "Oh dear, now you've caught it too.|I'm so sorry, {player}.",
				_ = "Now we've both got it stuck.|Thanks a lot, heh.",
			}, "music", "laugh")
			c:mood("a", 3)
		end)
		s:choice("Here, hum this instead.", function(c)
			c:n("You hummed a different tune, and {a} listened with their eyes shut.")
			burst(
				c,
				"a",
				"Oh no, now I've got yours stuck instead.|...It's a better one, though, so thanks, {player}.",
				"music"
			)
			c:mood("a", 2)
			c:memo("a", "You put a song in my head, and it's still there.")
		end)
		s:log("{a} had a song stuck in their head.")
		return s:done()
	end,
})

-- the giant marrow ---------------------------------------------------------------------------------------

event({
	id = "marrow",
	when = "day",
	weight = W({
		base = 0.12,
		season = { 2, 3 },
		cond = function(ctx, a)
			return ctx.v(a).hobby == "gardening" or ctx.rng:chance(0.5)
		end,
	}),
	scene = function(ctx, a)
		local s = K.scene(ctx, "The big marrow")
		s:prop("marrow", "a")
		s:n("{a} has been growing a marrow behind the house, and it's about the size of a wheelbarrow now.")
		burst(s, "a", {
			proud = "{player}, have you seen my marrow yet?|I measured it, and it's the biggest in town by far.|Go on, try and find a bigger one.",
			gentle = "I've been singing to it every morning.|I think it might actually be helping, don't you?",
			bold = "I tried to lift it this morning and couldn't.|You'll help me get it off the ground on Friday, right?",
			shy = "Um...|I didn't mean for it to get this big, honestly.",
			easygoing = "I just kept watering it, and it kept growing, heh.|At this point I'm too scared to stop.",
			sunny = "Look, look, {player}!|It's so big I can't get my arms round it now!",
			cool = "Hm, it's gotten very big.|I'm still deciding what to do with it.",
			prickly = "Don't touch it.|...Fine, you can pat it once.",
			dramatic = "Behold the pride of the whole island!",
			bookish = "Did you know a marrow is technically a fruit?|This is a very, very large fruit.",
			gloomy = "Something's going to eat it before I can pick it, you watch.|Heh... things like that always happen to me.",
			foodie = "I'm torn between making soup and stuffing it.|Maybe I'll do both, there's enough of it.",
			nervous = "W-what if it never stops growing?|Where would I even put it?",
			_ = "I don't know what to do with it, {player}.|I only wanted to see how big it would get.",
		}, "sparkle", "point")
		s:choice("Keep watering it.", function(c)
			burst(c, "a", {
				proud = "Exactly.|It can get even bigger, I know it can.",
				dreamy = "Hmm... grow, little marrow, grow.",
				_ = "More water it is, then.|Let's see how far it goes.",
			}, "sparkle", "cheer")
			c:leave("marrow", 18, "a")
			c:mood("a", 5)
			c:memo("a", "The marrow's still growing, and I've had to move the fence for it.")
		end)
		s:choice("Soup for the whole street?", function(c)
			burst(c, "a", {
				foodie = "Yes, yes, I'll get the big pot out!|And bread, we'll need lots of bread.",
				gloomy = "Soup, okay.|At least nothing can eat it before I do now.",
				_ = "Soup for everyone, then.|I'll need to borrow the big pot.",
			}, "heart")
			c:all(3)
			c:mood("a", 3)
			c:memo("a", "Everybody had marrow soup, and there's still half a marrow left.")
		end)
		s:log("{a} grew an enormous marrow.")
		return s:done()
	end,
})

makes({
	id = "marrowshow",
	title = "The marrow show",
	item = "keep_trophy",
	w = { base = 0.08, season = { 2, 3 } },
	lines = {
		{ "n", "{a} took a marrow to the show on the next island and came back with a little silver cup." },
		{ "a", "{player}, I came second at the marrow show.", "sparkle" },
		{ "a", "The winner's marrow was wearing a tiny hat.|I'm fairly sure that's what swung it.", "sweat" },
	},
	react = {
		proud = "Hmph, second is just the first of the losers.|I'll be back next year to win it properly.",
		easygoing = "Second's great, honestly.|There's a lot less pressure than first.",
		shy = "I nearly didn't go at all...|I'm really glad I did, though.",
		bold = "Next year I'm winning it, hat or no hat.",
		cool = "Second's fine by me.",
		prickly = "Whatever, I'll take second.|I'm not bitter, so stop looking at me like that.",
		dramatic = "I was ROBBED, {player}, robbed by a hat!",
		gloomy = "I was expecting last place.|So this feels like a lot, honestly.",
		polite = "The judges were very kind.|I've already sent them a thank you note.",
		nervous = "My hands were shaking the whole time.|But I still came second!",
		_ = "I'll happily take second.",
	},
	ask = "Can it go on my shelf?",
	keep = "You earned it, so keep it.",
	memo = "I came second at the marrow show, so next year I'm bringing a hat.",
	log = "{a} came second at the marrow show.",
})

-- a bad haircut --------------------------------------------------------------------------------------

event({
	id = "haircut",
	when = "day",
	weight = W({ base = 0.2, traits = { focus = -0.2 } }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "A new fringe")
		s:n("{a} cut their own fringe this morning, and it came out a bit wonky.")
		burst(s, "a", {
			shy = "Um, please don't look at me...|I tried to cut my own fringe.",
			proud = "Hmph, it's meant to look like this.|It's a style, you can look it up.",
			cheeky = "i meant to do that|the left side, anyway",
			easygoing = "Eh, it'll grow back.|Everything does, eventually.",
			bold = "Hah, I cut it myself this morning and went a bit too far.",
			dreamy = "I was thinking about clouds while I cut it...|Maybe that was the problem.",
			sunny = "{player}, be honest with me!|Wait, no, be nice instead!",
			cool = "Hm, I cut it myself.|It didn't go to plan, as you can see.",
			prickly = "Go on, say something about it.|...Actually, don't.",
			dramatic = "It's a DISASTER.|I can never show my face in the square again.",
			bookish = "Hair grows about a centimetre a month.|So this will take roughly four months to fix.",
			gloomy = "Heh... it was always going to end up like this.",
			polite = "I'm so sorry you have to look at this, {player}.",
			nervous = "Is it bad?|Oh no, it's bad, isn't it? How bad is it?",
			_ = "Is it really bad? You can be honest.|Actually, no, please don't be honest.",
		}, "sweat")
		s:choice("It suits you.", function(c)
			burst(c, "a", {
				proud = "I know.|Say it again, a bit louder this time.",
				shy = "...!|Really? You're not just saying that?",
				prickly = "You're just saying that.|...Thanks, though.",
				gloomy = "Huh, okay.|Maybe it's not the worst thing that's happened this week.",
				nervous = "Oh, thank goodness.|I was so sure everyone would stare.",
				_ = "Really, {player}?|Okay, then I'm keeping it.",
			}, "heart")
			c:mood("a", 5)
			c:hearts("a", 1)
		end)
		s:choice("Maybe wear a hat for a week.", function(c)
			burst(c, "a", {
				proud = "Th-the fringe isn't that bad.|...Fine, where did I put my hat?",
				easygoing = "Fair enough, I've got a hat around here somewhere.",
				dramatic = "A HAT?|...Yes, all right, a hat.",
				cheeky = "rude|accurate, but rude",
				_ = "Is it really that bad?|Right, I'll go and find a hat.",
			}, "sad")
			c:mood("a", -3)
			c:memo("a", "I'm wearing a hat until my fringe grows out, so please don't ask.")
		end)
		s:log("{a} cut their own fringe.")
		return s:done()
	end,
})

-- the sneeze and the cat -----------------------------------------------------------------------------

event({
	id = "sneeze",
	when = "day",
	weight = W({ base = 0.22 }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "A big sneeze")
		s:prop("cat", "a")
		s:n("A cat was asleep on the wall when {a} sneezed right next to it.")
		s:say("a", "Aaaaachoo!", "sweat")
		s:n("The cat shot up into the air, landed on its feet and gave {a} a long look.")
		burst(s, "a", {
			shy = "Sorry, sorry, cat...|I didn't mean to.",
			bold = "Hah, you jumped higher than I've ever seen a cat jump.",
			cheeky = "ten out of ten jump, honestly|sorry cat, hehe",
			gentle = "Oh, my, you poor thing.|I didn't mean to scare you.",
			dreamy = "Hmm... I think it thinks I'm a thundercloud now.",
			cool = "Hm, it'll get over it.",
			prickly = "Don't look at me like that.|You were the one sleeping on my wall.",
			dramatic = "It will NEVER forgive me!",
			polite = "I do apologise.|That was very rude of me.",
			nervous = "Is it okay? Is it hurt?|...Oh, good, it's only glaring at me.",
			_ = "That cat is never going to forgive me.",
		}, "question")
		s:mood("a", 2)
		s:memo("a", "There's a cat that glares at me now, all because I sneezed near it once.")
		s:log("{a} sneezed and scared a cat.")
		return s:done()
	end,
})

-- a diary ---------------------------------------------------------------------------------------------

event({
	id = "diary",
	when = "night",
	weight = W({ base = 0.25, traits = { social = -0.4 } }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "Dear diary")
		s:n("{a} is writing in a little book with a lock on it.")
		burst(s, "a", {
			shy = "Oh, {player}...|Please don't read it, it's mostly about the weather.",
			proud = "Hmph, these are my memoirs.|They'll be worth a fortune one day, you'll see.",
			cheeky = "half of it is made up|apparently yesterday i won a boat race",
			cool = "It's my diary.|It's private.",
			prickly = "What? People write things down all the time.|It's completely normal.",
			dramatic = "Every word in here is true, and every tear too!",
			bookish = "I've kept a diary since I was eight.|This is notebook number forty one.",
			gloomy = "Today it rained, and tomorrow it'll probably rain again.|That's most of what's in here.",
			polite = "Good evening, {player}.|I always end the day by writing a little, I hope you don't mind.",
			_ = "It's my diary.|I've written in it every day since I moved here.",
		}, "sweat")
		s:choice("Can I have a look?", function(c)
			if ctx.rng:chance(0.5) then
				c:n("You leaned over and read 'Today was nice, I saw the sea and had a bun.'")
				burst(
					c,
					"a",
					"Hey, that's private!|...Well, that's all it says, and it really was a good bun.",
					"sweat"
				)
				c:mood("a", -1)
			else
				c:n("{a} snapped the book shut before you got close.")
				burst(c, "a", {
					bold = "Hah, nice try.",
					shy = "Th-that's private...",
					gentle = "Not that one, {player}, please.",
					cool = "No.",
					prickly = "Absolutely not, go away.|...Good night.",
					dramatic = "How DARE you!|...Heh, nice try, though.",
					_ = "Nice try, but no.",
				}, "anger")
				c:mood("a", -5)
			end
		end)
		s:choice("I'll leave you to it.", function(c)
			burst(c, "a", "Thanks, {player}.|I'll write that you were nice about it.", "heart")
			c:hearts("a", 1)
			c:mood("a", 2)
		end)
		s:log("{a} wrote in their diary.")
		return s:done()
	end,
})

-- cloud spotting -------------------------------------------------------------------------------------

local CLOUDS = { "a teapot", "a sleeping dog", "a bun", "a whale with a hat on", "the town hall", "a sock" }

event({
	id = "clouds",
	when = "day",
	weight = W({ base = 0.2, weather = { "clear", "cloudy" }, traits = { focus = -0.4 } }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "Cloud spotting"):with({ one = ctx.rng:pick(CLOUDS), two = ctx.rng:pick(CLOUDS) })
		s:n("{a} is lying on their back on the grass, pointing at the sky.")
		burst(s, "a", {
			cheeky = "that one looks like {one}|and the one next to it is {two}, obviously",
			_ = "That one looks like {one}.|And the one next to it is... {two}, I think.",
		}, "idea", "point")
		burst(s, "a", {
			dreamy = "I'm going to stay here until they've all turned into something.",
			easygoing = "This is the best way to spend an afternoon.|Don't tell anyone how long I've been lying here.",
			bold = "I've been lying here for an hour.|Is that allowed? I'm doing it anyway.",
			cheeky = "and the grumpy one on the left looks like you, {player}",
			shy = "I don't usually do this where people can see me...",
			cool = "It's a good sky for it today.",
			prickly = "Don't just stand there.|Either lie down or move, you're blocking the view.",
			bookish = "Actually, those puffy ones are cumulus.|The flat one behind them is stratus.",
			gloomy = "That one looks like rain.|They all do after a while.",
			foodie = "That one's a bun, and that one's also a bun.|I think I might be hungry.",
			_ = "Come and lie down, {player}, there's room.",
		}, "music")
		s:mood("a", 4)
		s:log("{a} spent the afternoon looking at clouds.")
		return s:done()
	end,
})

-- the weather ---------------------------------------------------------------------------------------

event({
	id = "puddles",
	when = "day",
	weight = W({ base = 0.35, weather = "rain", traits = { mischief = 0.4 } }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "Puddles")
		s:prop("umbrella", "a")
		s:n("{a} left their umbrella open on the path and is jumping in every puddle on the street.")
		burst(s, "a", {
			proud = "Hmph, this is for my health, I'll have you know.|Splashing is very good for the legs.",
			shy = "Hehe, nobody's looking...|Oh, um, except you.",
			gentle = "Oh, my, I haven't done this since I was small.",
			cool = "You didn't see this.",
			prickly = "What? It's raining, so this is what puddles are for.",
			dramatic = "That was the biggest splash this street has ever SEEN!",
			gloomy = "My boots leak anyway.|I might as well get some use out of them.",
			nervous = "This is allowed, right?|Nobody's going to tell me off?",
			sunny = "{player}, watch this one!|Ehehe, that was the biggest yet!",
			_ = { "Did you see that splash, {player}?", "That's the biggest puddle on the street, so watch this." },
		}, "music", "cheer")
		s:mood("a", 5)
		s:memo("a", "My boots are still wet from all the puddles.")
		s:log("{a} jumped in puddles in the rain.")
		return s:done()
	end,
})

event({
	id = "snowman",
	when = "day",
	weight = W({ base = 0.5, weather = "snow" }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "A snowman")
		s:prop("snowman", "a")
		s:n("{a} has rolled three big snowballs and stacked them up.")
		burst(s, "a", {
			bold = "That's the tallest snowman in town.|He's even taller than me, look.",
			dreamy = "I've decided his name is Gerald.|He looks like a Gerald, doesn't he?",
			cheeky = "i gave him my neighbour's hat|don't tell them",
			sunny = "{player}, come and meet my new friend!|Let's build him a little brother together!",
			cool = "I built a snowman.|He came out well.",
			prickly = "He's lopsided, I know.|Don't say it.",
			dramatic = "Look at him standing tall against the winter!|This is my finest work.",
			gloomy = "He'll have melted by Thursday.|Still, look at him while he's here.",
			foodie = "I gave him biscuits for buttons and then ate one.|So now he only has two buttons.",
			_ = "Doesn't he look smart, {player}?|I lent him my scarf.",
		}, "sparkle", "point")
		s:choice("He needs a carrot nose.", function(c)
			burst(c, "a", {
				cheeky = "ooh, perfect|now he can smell the bakery like the rest of us",
				_ = "Oh, that's perfect.|Now he can smell the bakery like the rest of us.",
			}, "heart", "cheer")
			c:leave("snowman", 24, "a")
			c:mood("a", 6)
			c:memo("a", "Have you said hello to my snowman yet? He's very polite.")
		end)
		s:choice("It's too cold for me.", function(c)
			burst(c, "a", {
				cheeky = "fair, i can't feel my fingers anymore anyway",
				_ = "That's fair, I can't feel my fingers anymore anyway.",
			}, "sweat")
			c:leave("snowman", 12, "a")
			c:mood("a", 3)
		end)
		s:log("{a} built a snowman.")
		return s:done()
	end,
})
event({
	id = "leafpile",
	when = "day",
	weight = W({
		base = 0.3,
		cond = function(ctx)
			return ctx.weather == "leaves" or (ctx.season == 3 and ctx.weather ~= "rain")
		end,
	}),
	scene = function(ctx, a)
		local s = K.scene(ctx, "A pile of leaves")
		s:prop("leaves", "a")
		s:n("{a} raked every leaf on the street into one big pile.")
		burst(s, "a", {
			easygoing = "That took me ages to rake.|So now I'm going to lie in it for a while.",
			bold = "I'm taking a run up, so stand back.|You're jumping in after me, right?",
			proud = "Look how neat that pile is.|Nobody touch it until I've jumped in first.",
			cheeky = "three|two|one|ok i'm jumping",
			sunny = "Jump in with me, {player}!|Let's go together on three, ready?",
			cool = "I'm allowing myself one jump.",
			prickly = "I raked every one of those myself.|So I'm jumping in it, and don't argue.",
			dramatic = "This one is for autumn!",
			nervous = "W-what if there's a hedgehog in there?|...No, I checked twice, it's fine.",
			_ = "Just one jump, I promise.|Then I'll rake it all up again.",
		}, "sparkle", "cheer")
		s:n("Now there are leaves everywhere, and {a} is lying in what's left of the pile.")
		s:leave("leaves", 10, "a")
		s:mood("a", 5)
		s:log("{a} jumped in a pile of leaves.")
		return s:done()
	end,
})

event({
	id = "sunburn",
	when = "day",
	weight = W({ base = 0.25, season = 2, weather = "clear" }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "Too much sun")
		s:n("{a} fell asleep on the beach, and one side of their face is bright pink.")
		burst(s, "a", {
			proud = "Hmph, it's a tan.|A very bright tan, but a tan.",
			easygoing = "It was worth it, though.|That was the best nap I've had all year.",
			shy = "Everyone's going to see it...|Um, could I borrow a hat?",
			cool = "I've got half a tan now.|It'll even out.",
			prickly = "Don't laugh, it really stings.",
			dramatic = "I'm cooked, {player}, like a sausage on a grill!",
			bookish = "I knew all about sun cream.|I'd read about it, I just didn't wear any.",
			gloomy = "Of course it was only one side, heh.",
			foodie = "I look like a radish.|A nice fresh one, at least.",
			_ = "It's only on one side, so I look like a radish.",
		}, "sweat")
		s:choice("I'll get you some aloe.", function(c)
			burst(c, "a", {
				polite = "Oh, that's very kind of you.|Thank you kindly.",
				prickly = "...That actually helps.|Fine, thanks.",
				shy = "...!|Thank you.",
				cool = "Hm, that's cold.|Thanks, {player}.",
				_ = "Ooh, that's cold.|Thank you, {player}.",
			}, "heart")
			c:mood("a", 3)
			c:hearts("a", 1)
		end)
		s:choice("Sun cream next time?", function(c)
			burst(c, "a", "Yes, next time, I promise.|I'll set an alarm too, so I don't fall asleep.", "sweat")
			c:mood("a", -1)
		end)
		s:log("{a} got sunburnt on the beach.")
		return s:done()
	end,
})

event({
	id = "kite",
	when = "day",
	weight = W({ base = 0.25, weather = { "clear", "cloudy", "blossom", "leaves" } }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "Flying a kite")
		s:prop("kite", "a")
		s:n("{a} has got a kite right up into the wind.")
		burst(s, "a", {
			sunny = "{player}, look how high it is!|It's pulling so hard!",
			cool = "{player}, look.|It's really pulling today.",
			_ = "Look how high it's gone.|I can feel it pulling on the string.",
		}, "sparkle", "point")
		if ctx.rng:chance(0.4) then
			s:n("Then the wind dropped, and the kite went nose first into the top of a tree.")
			burst(s, "a", {
				bold = "I'm climbing up after it.|Hold my shoes, would you?",
				shy = "Oh no...|Oh no, no, no.",
				cheeky = "well|the tree seems to be having a nice time",
				cool = "Great.",
				prickly = "Of course.|Of course that happened.",
				dramatic = "It's been stolen from me by a TREE!",
				gloomy = "I knew that was going to happen.",
				nervous = "Can we get it down?|It's not broken, is it?",
				_ = "Well... at least it's still up high.",
			}, "sweat")
			s:choice("Let's get it down.", function(c)
				c:n("With a long stick and a lot of jumping, the kite came down with only one small hole.")
				burst(c, "a", "Got it back, and it'll still fly with that little hole.|Thanks, {player}.", "heart")
				c:mood("a", 4)
				c:hearts("a", 1)
			end)
			s:choice("The birds can fly it now.", function(c)
				burst(c, "a", "Maybe a bird will have a go.|That'd be nice, I suppose...", "sad")
				c:mood("a", -3)
			end)
		else
			burst(s, "a", {
				sunny = "Higher, higher!|Look at it go!",
				cool = "It's good wind for it today.",
				gloomy = "It's actually staying up, huh.",
				dramatic = "It FLIES!",
				shy = "...!|It's so high up.",
				_ = "I've let out nearly all the string.|It's almost up at the clouds.",
			}, "music", "cheer")
			s:mood("a", 5)
		end
		s:log("{a} flew a kite.")
		return s:done()
	end,
})

event({
	id = "stargaze",
	when = "night",
	weight = W({
		base = 0.25,
		weather = "clear",
		cond = function(ctx, a)
			return ctx.v(a).hobby == "stargazing" or ctx.rng:chance(0.6)
		end,
	}),
	scene = function(ctx, a)
		local s = K.scene(ctx, "Through the telescope")
		s:prop("telescope", "a")
		s:n("{a} has set up a telescope in the garden.")
		burst(
			s,
			"a",
			"{player}, I think I've found a new star.|It's moving, though, and it keeps blinking.",
			"idea",
			"point"
		)
		burst(s, "a", {
			proud = "I'm naming it after myself, obviously.",
			dreamy = "Maybe it's a star that wants to be somewhere else...",
			cheeky = "ok it's a plane, i know it's a plane|let me have this",
			cool = "Hm, it's a plane.",
			bookish = "Actually, stars don't move about like that.|So I'm afraid it's a plane.",
			dramatic = "A new star, born tonight!|...With little lights on its wings.",
			gloomy = "It's a plane.|Things usually turn out to be planes.",
			_ = "...It might be a plane, actually.",
		}, "question")
		s:mood("a", 4)
		s:memo("a", "I found a new star last night, and then it turned out to be a plane.")
		s:log("{a} went stargazing.")
		return s:done()
	end,
})

-- the night --------------------------------------------------------------------------------------------

event({
	id = "insomnia",
	cutscene = "kitchen",
	when = "night",
	weight = W({ base = 0.3, traits = { lazy = -0.3 } }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "Can't sleep")
		s:n("It's late, and {a} is still wide awake.")
		burst(s, "a", {
			dreamy = "{player}, are you awake?|My head won't stop wandering about tonight.",
			proud = "I'm not tired, sleep is for other people.|...It's two in the morning, isn't it?",
			bold = "I can't sleep.|I've been staring at the ceiling for an hour, and it's winning.",
			cheeky = "u up?|i'm not sleeping, i'm planning things, hehe",
			shy = "Um, {player}? Sorry, I know it's late...|I keep thinking about something I said today.",
			sunny = "{player}, are you up too?|Ehehe, good, talk to me for a bit!",
			cool = "I can't sleep.|You're up too, I see.",
			prickly = "Don't ask why, I just can't sleep, okay?",
			dramatic = "The night is so very LONG, {player}.",
			bookish = "I read that counting backwards helps you fall asleep.|I've reached minus forty.",
			gloomy = "It's two in the morning, and I'm awake as usual...|I'll be useless tomorrow.",
			foodie = "I can't stop thinking about toast.|Is it too late to make some?",
			nervous = "D-did I lock the front door?|I'm sure I did, but I'm going to check again.",
			gentle = "Oh, {player}, you're up late too.|I can't seem to settle tonight.",
			easygoing = "*yawn*|I napped all afternoon, and now I can't sleep, funny that.",
			polite = "Good evening, {player}, and forgive the hour.|I can't seem to get to sleep.",
			_ = {
				"I've counted four hundred sheep so far.|Even they're getting bored.",
				"Every time I close my eyes, I remember something I forgot to do.",
			},
		}, "zzz")
		s:choice("Warm milk?", function(c)
			burst(c, "a", {
				cheeky = "warm milk, ok, grandma|...it's actually working, night",
				_ = "Mm, warm milk sounds nice.|...I'm getting sleepy already, good night, {player}.",
			}, "zzz")
			c:mood("a", 4)
		end)
		s:choice("What's on your mind?", function(c)
			burst(c, "a", {
				shy = "It's silly, but I waved at someone today and they didn't see.|...Saying it out loud helped, good night.",
				gloomy = "A bit of everything, really.|...Sorry, forget I said that, good night.",
				nervous = "Tomorrow, mostly, all of it at once.|...Actually, it sounds fine when I say it out loud, good night.",
				prickly = "Nothing.|...Okay, it's work, but forget it, good night.",
				bookish = "I was wondering whether the tide turns at the same time on every island.|I'll look it up tomorrow, good night.",
				cool = "Nothing much.|...Thanks for asking.",
				cheeky = "a prank, a really good one|you'll find out tomorrow, night",
				sunny = "Tomorrow, ehehe, it's going to be such a good day!|Okay, I'll try to sleep now, good night!",
				_ = "Nothing really, but thanks for asking.|Good night, {player}.",
			}, "zzz")
			c:n("{a} was asleep a few minutes later.")
			c:mood("a", 5)
			c:hearts("a", 1)
			c:memo("a", "Did I say anything odd the other night? Just forget it if I did.")
		end)
		s:log("{a} couldn't sleep.")
		return s:done()
	end,
})

event({
	id = "midnightsnack",
	cutscene = "kitchen",
	when = "night",
	weight = W({ base = 0.2, traits = { lazy = 0.4 } }),
	scene = function(ctx, a)
		local food = ctx.rng:pick(Foods.list)
		local s = K.scene(ctx, "A midnight snack"):with({ food = food.name:lower() })
		s:n("A light is on in {a}'s kitchen at two in the morning.")
		burst(s, "a", {
			cheeky = "oh, hi|i'm not eating, i'm guarding the {food}",
			cool = "{player}.|I'm not eating, I'm only checking on the {food}.",
			_ = "Oh, {player}, hi.|I'm not eating anything, I'm only checking on the {food}.",
		}, "sweat")
		burst(s, "a", {
			proud = "A real chef tests recipes at all hours, you know.",
			easygoing = "Honestly, this is the best meal of the day, heh.",
			shy = "Please don't tell anyone about this...",
			cheeky = "you didn't see anything|hehe",
			bold = "I was hungry, so what?",
			cool = "Hm, want some?",
			prickly = "Don't look at me like that.|Everyone does this.",
			dramatic = "It CALLED to me, {player}, what could I do?",
			bookish = "Actually, a small snack can help you sleep.|There's research on it, I promise.",
			gloomy = "I'll regret this in the morning, as usual.|Not yet, though.",
			polite = "Would you care for some?|I'd feel rude eating alone.",
			foodie = "Mmm, everything tastes better at night, have you noticed?",
			nervous = "Is it too late to be eating?|Oh no, it is, isn't it?",
			_ = "I was only going to have one bite, and now look.",
		}, "heart")
		s:mood("a", 3)
		s:log("{a} had a midnight snack.")
		return s:done()
	end,
})

event({
	id = "nightmare",
	cutscene = "dream",
	when = "night",
	weight = W({ base = 0.18 }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "A bad dream")
		s:n("{a} woke up with a jump.")
		burst(s, "a", {
			bold = "{player}, you up?|I had a dream where I lost every single race.",
			proud = "{player}, I had an awful dream.|Nobody in town knew who I was, not a single person.",
			shy = "Um, {player}...|I dreamed I had to give a speech in the square in my pyjamas.",
			dreamy = "Hmm... I dreamed all the clouds had gone away.|The sky was just empty.",
			cheeky = "had a dream i was the one getting pranked|horrible, zero stars",
			cool = "I had a bad dream.|I'm fine now.",
			prickly = "I dreamed the bakery shut for good.|Don't laugh, it was horrible.",
			dramatic = "{player}, I dreamed the sea came up the street and took my HOUSE!",
			bookish = "I dreamed the library had no books left.|There were just rows and rows of empty shelves.",
			gloomy = "I dreamed it was sunny and everyone was happy.|Then I woke up, heh.",
			polite = "Forgive me for bothering you so late.|I dreamed I'd forgotten to thank someone, and it was awful.",
			foodie = "I dreamed every pie in town was empty.|There was just crust, everywhere.",
			nervous = "I dreamed I left the oven on.|I don't even use my oven, but I've checked it twice now.",
			gentle = "I'm sorry, {player}, I know it's late.|I dreamed everyone in town had moved away.",
			_ = "{player}...|I dreamed my house floated away and I couldn't catch it.",
		}, "sad")
		s:choice("It was only a dream.", function(c)
			burst(c, "a", {
				bold = "Yeah, I know.|...Stay and talk for a bit, though?",
				proud = "Obviously, I wasn't scared.|...You can stay for a minute, though.",
				shy = "Okay...|Could you stay until I'm sleepy again?",
				prickly = "I know that.|...You can stay a minute, if you want.",
				gloomy = "Yeah...|Thanks for staying up with me, {player}.",
				cool = "Yeah.|...Thanks.",
				_ = "I know.|Can you stay until I'm sleepy again?",
			}, "heart")
			c:mood("a", 4)
			c:hearts("a", 1)
		end)
		s:choice("Leave a light on.", function(c)
			burst(c, "a", "Okay, I'll leave the lamp on.|...That's much better.", "zzz")
			c:mood("a", 2)
		end)
		s:log("{a} had a bad dream.")
		return s:done()
	end,
})

-- small odd things ----------------------------------------------------------------------------------

event({
	id = "plants",
	when = "day",
	weight = W({
		base = 0.15,
		traits = { kind = 0.2 },
		cond = function(ctx, a)
			return ctx.v(a).hobby == "gardening" or ctx.rng:chance(0.5)
		end,
	}),
	scene = function(ctx, a)
		local s = K.scene(ctx, "Talking to plants")
		s:n("{a} is crouched by a flowerpot, talking to it quietly.")
		burst(s, "a", {
			gentle = "You're doing so well, look at that new leaf.|I'm very proud of you.",
			proud = "You'll be the finest fern in town.|Now stand up straight.",
			cheeky = "grow, or i tell the other plants your secrets",
			dreamy = "Hmm... I think it likes the rain more than it likes me.",
			cool = "You're doing fine.|Keep going.",
			prickly = "Grow, I'm not asking twice.|...Please.",
			dramatic = "Rise, little fern, and reach for the sun!",
			bookish = "Actually, plants like the air we breathe out.|So I talk to them as much as I can.",
			gloomy = "Please don't die like the last one.|I've got a good feeling about you, though.",
			polite = "Hello there, and thank you for growing so nicely.",
			foodie = "When you're a big tomato, you'll be the best tomato in town.",
			nervous = "Is it too much water, or not enough?|I wish you could tell me.",
			_ = "Plants grow better if you chat to them.|Everyone knows that.",
		}, "heart")
		s:mood("a", 3)
		s:log("{a} talked to their plants.")
		return s:done()
	end,
})
event({
	id = "speech",
	when = "day",
	weight = W({ base = 0.12, traits = { brave = 0.3, social = 0.2 } }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "Practising a speech")
		s:n("{a} is practising a speech in front of the mirror.")
		burst(s, "a", {
			proud = "Thank you, thank you, I'm honoured.|I really couldn't have done it without... well, myself.",
			shy = "Um, thank you all for coming...|I, um, really appreciate it.",
			sunny = "Thank you all so much for being here!|I'd like to thank my mum, the baker, and the man with the dog.",
			dramatic = "Friends, neighbours, and gulls of the harbour, I stand before you humbled!",
			bookish = "Thank you, I promise I'll be brief.|There are only nine short sections.",
			polite = "Thank you, every one of you.|And thank you too, mirror.",
			_ = "Thank you, thank you.|I'd like to thank... um, everybody, I suppose.",
		}, "sparkle", "point")
		burst(s, "a", {
			shy = "...!|You heard all of that, didn't you?|I'm going to go and hide now.",
			proud = "Go on, you can say it was good.|I'll take questions now, if you have any.",
			cool = "How long have you been standing there?",
			prickly = "You didn't see any of that, got it, {player}?",
			nervous = "H-how long have you been standing there?|Was it bad? Please say it wasn't bad.",
			cheeky = "oh, hi|that speech was for the gulls, they asked for one",
			_ = "Oh, {player}, hi.|It isn't for anything, I just like to be ready.",
		}, "sweat")
		s:choice("*clap clap*", function(c)
			burst(c, "a", {
				shy = "Oh...|Um, thank you.",
				proud = "Thank you, yes.|Please, keep clapping.",
				cheeky = "louder|i can't hear you, hehe",
				dramatic = "Thank you, you're too kind!|I could do an encore, if you insist.",
				_ = "Ha, thank you.|I'll save you a seat for the real thing.",
			}, "sparkle", "cheer")
			c:mood("a", 5)
		end)
		s:choice("I didn't hear a thing.", function(c)
			burst(c, "a", "Good, neither did I.", "sweat")
			c:mood("a", 1)
		end)
		s:log("{a} practised a speech in the mirror.")
		return s:done()
	end,
})

event({
	id = "workout",
	when = "day",
	weight = W({ base = 0.2 }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "A new routine")
		burst(s, "a", {
			sunny = "{player}, I've decided to become a new me!|I'm doing fifty push ups every morning, starting today!",
			cool = "{player}.|I'm doing fifty push ups a day from now on.",
			_ = "{player}, this is the new me.|I'm doing fifty push ups every morning, starting today.",
		}, "idea", "point")
		if K.isPers(ctx, a, "bold") then
			s:n("{a} did fifty push ups, then fifty more, then went for a run.")
			burst(s, "a", "That was just the warm up.|You're coming with me tomorrow, right?", "sparkle", "cheer")
			s:mood("a", 5)
		else
			s:n("{a} managed four push ups, then lay down on the grass.")
			burst(s, "a", {
				easygoing = "Four is a lot of push ups, for me anyway.|I'll do five tomorrow, maybe.",
				proud = "Hmph, those were four perfect push ups.|It's about quality, not how many you do.",
				cool = "Four is good enough for a first day.",
				dramatic = "I gave it everything I had, all four of them!",
				gloomy = "Four, heh.|I knew it would be something like that.",
				foodie = "I think four push ups has earned me a bun.",
				prickly = "Not a word.|Four is a start.",
				_ = "I'll do fifty tomorrow, definitely.",
			}, "zzz")
			s:mood("a", 1)
		end
		s:log("{a} started a new exercise routine.")
		return s:done()
	end,
})

event({
	id = "letter",
	when = "day",
	weight = W({ base = 0.2 }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "A letter")
		s:n("The post brought a letter for {a}, in handwriting they knew at once.")
		burst(s, "a", {
			shy = "{player}...|It's from my best friend back home, and she still remembers me.",
			proud = "Someone from my old town wrote to say they miss me.|Well, of course they do.",
			dreamy = "It smells like the town I grew up in...|Like salt and toast.",
			cool = "Hm, it's from an old friend.|They're doing well.",
			prickly = "They actually wrote to me.|...Took them long enough.",
			dramatic = "Eight whole pages, {player}!|From the dearest friend I've ever had!",
			gloomy = "I thought they'd forgotten all about me.|They hadn't, and I don't get many letters, so that was nice.",
			polite = "How very thoughtful of them.|I must write a proper reply this evening.",
			nervous = "I was scared it would be bad news.|It's only news from home, phew.",
			_ = "It's from an old friend, {player}.|They're doing well, and they want to hear all about this place.",
		}, "heart")
		s:choice("Write back today.", function(c)
			burst(c, "a", "I will, and I'll tell them all about this place.|And about you, too.", "heart", "cheer")
			c:mood("a", 6)
			c:memo("a", "I wrote back to my old friend and told them all about you, {player}.")
		end)
		s:choice("What does it say?", function(c)
			burst(
				c,
				"a",
				"It's mostly news from home.|At the end there's a drawing of a cat called Plum, and that's the best part.",
				"heart"
			)
			c:mood("a", 4)
		end)
		s:log("{a} got a letter from an old friend.")
		return s:done()
	end,
})

local PARCEL = {
	{ "a jumper their gran had knitted, with a reindeer on the front.", 4 },
	{ "a rubber duck, with no note at all.", 2 },
	{ "a book they had lent somebody three years ago.", 3 },
	{ "a box of fudge, signed 'You know who'.", 5 },
	{ "another, smaller box, and inside that, a single button.", -1 },
}

event({
	id = "parcel",
	when = "day",
	weight = W({ base = 0.2 }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "A parcel")
		s:prop("box", "a")
		s:n("A parcel turned up on {a}'s step with no return address.")
		burst(s, "a", {
			cheeky = "{player}, someone sent me a box|if it's a prank, i'll be impressed",
			shy = "Um, {player}?|There's a box on my step, but what if it's meant for someone else?",
			bold = "There's a box on my step with no name on it.|Only one way to find out what's inside.",
			cool = "{player}.|Someone left a box on my step with no name on it.",
			prickly = "I didn't order this.|Who sends people things without asking?",
			dramatic = "A mystery, {player}, on my very own doorstep!",
			bookish = "It hasn't got a local stamp.|So it must have come over on the ferry.",
			gloomy = "It's probably a bill.|In a box, for some reason.",
			foodie = "If I shake it, does it sound like biscuits?|Mmm, I think it sounds like biscuits.",
			nervous = "Should I open it? What if it ticks?|...Okay, it doesn't tick.",
			_ = "{player}, a parcel came for me.|I didn't order anything, did I?",
		}, "question")
		s:choice("Open it now.", function(c)
			local p = ctx.rng:pick(PARCEL)
			c:with({ inside = p[1] })
			c:n("Inside was {inside}")
			if p[2] > 0 then
				burst(c, "a", {
					sunny = "Oh, I love it, I really love it!",
					cool = "Huh, that's actually nice.",
					prickly = "Hm.|...I'm keeping it.",
					shy = "...!|Is this really for me?",
					gloomy = "Something nice, for me, huh.",
					cheeky = "ok this is better than a prank",
					_ = "Oh, that's really nice.",
				}, "sparkle")
			else
				burst(c, "a", {
					prickly = "A single button, seriously?",
					dramatic = "A BUTTON?|All of that for one button?",
					cheeky = "a button|respect, honestly",
					_ = "...It's a button.|Okay, then.",
				}, "question")
			end
			c:mood("a", p[2])
			c:memo("a", "Someone sent me a parcel, and I still don't know who it was.")
		end)
		s:choice("Tea first?", function(c)
			burst(c, "a", "Good idea, tea first and then the box.", "music")
			c:mood("a", 2)
		end)
		s:log("{a} got a mystery parcel.")
		return s:done()
	end,
})

event({
	id = "spill",
	when = "day",
	weight = W({ base = 0.2, traits = { focus = -0.3 } }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "Oops")
		s:n("{a} tipped a whole cup of tea down their front.")
		burst(s, "a", {
			proud = "I meant to do that.|I'm trying out brown this season.",
			shy = "Oh no...|Please tell me nobody else saw that.",
			easygoing = "Eh, it was getting cold anyway.",
			cheeky = "it's a tea shirt now, get it?|ok i'll stop",
			cool = "Hm.|I'll go and change.",
			prickly = "Don't say anything.|Not one word.",
			dramatic = "My good shirt, {player}, my GOOD shirt!",
			gloomy = "Yep, that's how the day's going, then.",
			polite = "Oh, dear.|Did any of it get on you? I'm so sorry.",
			foodie = "What a waste of good tea.|It had honey in it and everything.",
			nervous = "Is it hot? No, it's not hot.|Okay, I'm fine, I'm fine.",
			_ = "Brilliant, just brilliant.",
		}, "sweat")
		s:mood("a", -1)
		s:log("{a} spilled tea down their front.")
		return s:done()
	end,
})

-- what goes into a new dish ("a dish with {one} and {two}", "my {one} and {two} dish")
local INGREDIENTS = {
	"pickles",
	"chocolate",
	"cheese",
	"carrots",
	"honey",
	"broccoli",
	"star fruit",
	"sardines",
	"pumpkin",
	"chili",
	"mint",
	"peanut butter",
}

event({
	id = "recipe",
	when = "day",
	weight = W({ base = 0.18 }),
	scene = function(ctx, a)
		local pair = ctx.rng:shuffle(INGREDIENTS)
		local s = K.scene(ctx, "A new recipe"):with({ one = pair[1], two = pair[2] })
		s:n("{a} is inventing a dish with {one} and {two}.")
		burst(s, "a", {
			foodie = "{player}, nobody's ever put these two together, which is mad.|Look at them, they belong in the same bowl!",
			bookish = "Someone tried this in a very old cookbook.|The whole entry just says 'no', so let's see if they were right.",
			nervous = "Nobody's ever put these two together.|Is there a reason? There's a reason, isn't there?",
			cool = "I'm trying a new dish.|We'll see how it goes.",
			sunny = "{player}, I'm making a dish nobody's ever tried!|Let's find out why, ehehe.",
			_ = "Nobody's ever put these two together.|Let's find out why.",
		}, "idea")
		s:choice("Let me taste it.", function(c)
			if ctx.rng:chance(0.5) then
				c:n("It was good, oddly good.")
				burst(c, "a", BRAG, "sparkle", "cheer")
				c:mood("a", 5)
				c:memo("a", "My {one} and {two} dish actually worked, so I'm making it again on Sunday.")
			else
				c:n("You chewed slowly while {a} watched your face.")
				burst(c, "a", "Is it that bad?|...It's that bad, I'll write 'no' next to it.", "sweat")
				c:mood("a", -1)
			end
		end)
		s:choice("You first.", function(c)
			c:n("{a} took a big bite, stopped, and quietly put the spoon down.")
			burst(c, "a", "We're never going to speak of this, {player}.", "sweat")
		end)
		s:log("{a} invented a recipe.")
		return s:done()
	end,
})

-- things they make, and might give you ---------------------------------------------------------------

event({
	id = "painting",
	when = "day",
	weight = W({
		base = 0.12,
		cond = function(ctx, a)
			return ctx.v(a).hobby == "painting" or ctx.rng:chance(0.4)
		end,
	}),
	scene = function(ctx, a)
		local s = K.scene(ctx, "At the easel")
		s:prop("easel", "a")
		s:n("{a} set up an easel in the street and has been painting all afternoon.")
		burst(s, "a", {
			proud = "This is a masterpiece in the making.|Please don't stand in my light.",
			shy = "It's not finished...|Well, it might be, I can't really tell.",
			dreamy = "I'm painting the sea...|The way it looks when it's in a good mood.",
			cool = "It's almost done.",
			prickly = "Don't hover.|...Okay, you can look, but quickly.",
			dramatic = "Stand back, {player}, art is happening!",
			bookish = "I'm trying the old way of doing it.|Did you know you're meant to leave a whole day between the layers?",
			gloomy = "It's the harbour on a grey day.|So, most days.",
			foodie = "It's a bowl of fruit.|I've eaten two of the models, so I'm working from memory.",
			nervous = "Don't look yet!|Okay, you can look now... no, wait, okay, look.",
			cheeky = "hold still, {player}|i might put you in it",
			_ = "Hold still, {player}.|I might put you in it.",
		}, "sparkle")
		s:choice("Could you paint me?", function(c)
			c:n("{a} had you sit on a crate for an hour, then turned the canvas round.")
			burst(c, "a", {
				shy = "It's you...|Well, it's meant to be, and you can keep it.",
				proud = "There, you've never looked better.|You can keep it, of course.",
				cheeky = "i gave you a slightly bigger nose|artist's choice, you can keep it",
				prickly = "It's you.|Take it before I change my mind.",
				dramatic = "Behold, {player}, as the ages shall remember you!",
				polite = "Thank you for sitting so still.|Please, it's yours to keep.",
				_ = "There, it's you, {player}.|You can keep it.",
			}, "heart", "cheer")
			c:keep("keep_portrait", "a")
			c:hearts("a", 1)
			c:mood("a", 5)
			c:memo("a", "I painted your portrait, so I hope you've hung it somewhere nice.")
		end)
		s:choice("I'll leave you to it.", function(c)
			burst(c, "a", {
				cheeky = "ok, but no peeking until it's done",
				_ = "Thanks, I'll show you when it's finished.",
			}, "music")
			c:mood("a", 3)
		end)
		s:log("{a} spent the afternoon painting.")
		return s:done()
	end,
})

makes({
	id = "pottery",
	title = "A pot",
	item = "keep_pot",
	w = { base = 0.1 },
	lines = {
		{ "n", "{a} has clay up to the elbows and a pot drying on the step." },
		{
			"a",
			"{player}, come and look at my pot.|It's a bit lopsided, but that's the handmade look.",
			"sparkle",
			"point",
		},
	},
	react = {
		proud = "It's the best pot on the island.|I've seen the others, so I'd know.",
		shy = "It's my first one...|Is it all right?",
		cool = "It holds water, mostly.",
		prickly = "It's wonky on purpose, obviously.",
		bookish = "People have made pots this way for thousands of years.|Now I'm one of them.",
		foodie = "It's going to be my soup pot.|I'm making soup in it tonight.",
		sunny = "It's my very first pot!|I'm going to make a hundred more!",
		_ = "I put some lavender in it to hide the wonky bit.",
	},
	memo = "I made a pot, but it leaks a little at the bottom.",
	log = "{a} made a clay pot.",
})
makes({
	id = "whittling",
	title = "Whittling",
	item = "keep_bird",
	w = { base = 0.1, traits = { focus = 0.2 } },
	lines = {
		{ "n", "{a} has been sitting on the step with a knife and a bit of wood since lunch." },
		{ "a", "It's meant to be a bird.|You can tell it's a bird, right?", "question" },
	},
	react = {
		cheeky = "i was going for a duck, but it had other ideas",
		bold = "It took me three bits of wood.|I snapped the first two in half.",
		cool = "It's a robin, if you were wondering.",
		gloomy = "It looks a bit sad, like me.|I like it, though.",
		nervous = "I only cut myself twice.|That's good for a first try, right?",
		dramatic = "It sings, {player}, in its own wooden way!",
		_ = "I think it's the nicest thing I've ever made.",
	},
	memo = "I carved a little bird, and now my thumb has a plaster on it.",
	log = "{a} carved a wooden bird.",
})

makes({
	id = "quilting",
	title = "A patchwork quilt",
	item = "keep_quilt",
	w = { base = 0.08, season = { 3, 4 }, traits = { kind = 0.2 } },
	lines = {
		{ "n", "{a} finished a quilt today, made from old shirts and a curtain." },
		{ "a", "Every patch on it came from something.|That one's from my favourite shirt.", "heart", "point" },
	},
	react = {
		gentle = "I sewed a little heart in the middle for whoever sleeps under it.",
		proud = "There are two hundred stitches in it, and I counted every one.",
		polite = "I do hope it keeps someone warm this winter.",
		prickly = "It took forever, so don't tell me it's nice.|...It is nice, though, right?",
		_ = "It took me weeks, and I kept pricking my fingers.",
	},
	memo = "That quilt took me weeks to finish. Are you warm enough at night, {player}?",
	log = "{a} finished a patchwork quilt.",
})

makes({
	id = "bottleship",
	title = "A ship in a bottle",
	item = "keep_boat",
	w = { base = 0.06, traits = { focus = 0.4 } },
	lines = {
		{ "n", "{a} is holding a bottle up to the light, and there's a little ship inside." },
		{
			"a",
			{
				proud = "Go on, guess how I got it in there.",
				_ = "Don't ask me how I got it in there.|It took me most of the week.",
			},
			"sweat",
		},
	},
	react = {
		dreamy = "I like to think it's sailing somewhere very small...",
		proud = "It takes patience and steady hands.|Luckily, I have both.",
		bookish = "Actually, the mast folds down, and you pull it up with a thread.|It's quite clever.",
		cool = "The tiny flag was the hardest part.",
		_ = "I needed tweezers and a lot of deep breaths.",
	},
	memo = "I put a ship in a bottle, and I've already started on a second one.",
	log = "{a} put a ship in a bottle.",
})

makes({
	id = "shells",
	title = "A jar of shells",
	item = "keep_shells",
	w = { base = 0.1, season = { 2, 3 } },
	lines = {
		{ "n", "{a} came back from the beach with full pockets and a jar." },
		{
			"a",
			{
				cheeky = "i keep one shell for every nice day i have|the jar's full now",
				_ = "I keep one shell for every nice day I have.|The jar's run out of room.",
			},
			"music",
			"point",
		},
	},
	react = {
		dreamy = "If you hold one to your ear, you can hear the beach from that day...",
		cheeky = "one of them was actually a crab, but i put him back",
		gloomy = "I counted them all.|There were more nice days than I thought, heh.",
		sunny = "Look, look, {player}, this one's pink inside!",
		_ = "Some of them have the date written inside in pencil.",
	},
	memo = "I filled a whole jar with shells, but the beach has a few left.",
	log = "{a} filled a jar with shells.",
})

makes({
	id = "birdhouse",
	title = "A birdhouse",
	item = "keep_birdhouse",
	w = { base = 0.08, season = { 1, 2 }, traits = { kind = 0.2 } },
	lines = {
		{ "n", "{a} has built a little house on a post, with a round door and flowers painted on." },
		{ "a", "A bird moved in before the paint was even dry.", "sparkle" },
	},
	react = {
		gentle = "I gave it a perch so they can sit and look out.",
		bold = "It's the best house on the street.|Don't tell the builders I said that.",
		polite = "I left a little dish of seeds by the door.|It seemed only proper.",
		nervous = "D-do you think the bird likes it?|It hasn't said, but it's a bird.",
		_ = "The roof comes off, so you can clean it out.",
	},
	memo = "I built a birdhouse, and there's a robin living in it now.",
	log = "{a} built a birdhouse.",
})

makes({
	id = "chime",
	title = "A wind chime",
	item = "keep_chime",
	w = { base = 0.07, weather = { "clear", "cloudy", "leaves" } },
	lines = {
		{ "n", "Something on {a}'s porch tinkles every time the wind blows." },
		{ "a", "I made a wind chime out of old pipes.|Listen to it.", "music" },
	},
	react = {
		dreamy = "The wind plays it better than I ever could.",
		easygoing = "It's music I don't even have to play, perfect.",
		cool = "It makes a nice sound.",
		bookish = "Each length of pipe gives a different note.|I worked them all out on paper first.",
		_ = "Each pipe makes a different note.|One of them's a bit flat, but I like it.",
	},
	memo = "Every time it's windy, I think of the chime I made.",
	log = "{a} made a wind chime.",
})

makes({
	id = "mug",
	title = "A painted mug",
	item = "keep_mug",
	w = { base = 0.1 },
	lines = {
		{ "n", "{a} has been painting mugs at the kitchen table, and there's paint on the cat." },
		{ "a", "This one came out the best.|It has a heart on it, and some dots.", "heart", "point" },
	},
	react = {
		shy = "The heart's a bit wonky...|Is that all right?",
		cheeky = "there's a secret message on the bottom|don't look yet",
		foodie = "It's exactly the right size for soup.|I tested it already.",
		prickly = "The dots were an accident.|Now they're on purpose.",
		_ = "Tea tastes better out of a mug someone made for you.",
	},
	memo = "Are you drinking out of the mug I painted, {player}? Please say yes.",
	log = "{a} painted a mug.",
})

makes({
	id = "pressing",
	title = "Pressed flowers",
	item = "keep_flowers",
	w = { base = 0.08, season = { 1, 2 }, traits = { kind = 0.2 } },
	lines = {
		{ "n", "{a} has a heavy book on the table with flowers sticking out of it." },
		{
			"a",
			"I've been pressing flowers from the hill.|These ones are ready, so I've put them in a frame.",
			"sparkle",
		},
	},
	react = {
		gentle = "They'll keep their colour for years like this.",
		dreamy = "They look like they're asleep, all flat and quiet.",
		bookish = "I used my dictionary to press them.|It's the heaviest book I own.",
		gloomy = "They'll last longer like this.|Longer than most things do.",
		_ = "There's a daisy, two poppies and some lavender.|I wrote their names on a little label.",
	},
	memo = "I pressed some flowers in a big book, and now the book smells lovely.",
	log = "{a} pressed some flowers.",
})

makes({
	id = "lanternmaking",
	when = "night",
	title = "A paper lantern",
	item = "keep_lantern",
	w = { base = 0.06 },
	lines = {
		{ "n", "There's a warm glow in {a}'s window, where they've been folding paper all evening." },
		{ "a", "It's a paper lantern.|It folds flat, and then it opens out like this.", "sparkle" },
	},
	react = {
		shy = "I like the light it makes...|It's so soft.",
		bold = "I set fire to the first one.|This one's fine, though.",
		nervous = "The candle inside is a tiny one.|I checked it's safe, twice.",
		cool = "It gives a good light.",
		_ = "I painted little petals all the way round it.",
	},
	memo = "I made a paper lantern, and it's the cosiest thing I own.",
	log = "{a} made a paper lantern.",
})

makes({
	id = "knitting",
	title = "Knitting",
	item = "keep_cushion",
	w = {
		base = 0.07,
		season = { 3, 4 },
		cond = function(ctx, a)
			return ctx.v(a).hobby == "knitting" or ctx.rng:chance(0.5)
		end,
	},
	lines = {
		{ "n", "{a} is surrounded by wool, and in the middle of it all is a cushion." },
		{ "a", "I was knitting a scarf.|Somewhere along the way, it turned into a cushion.", "sweat" },
	},
	react = {
		easygoing = "It's good for naps.|I've checked several times.",
		proud = "It has three cables in it.|Do you know how hard cables are to knit?",
		dramatic = "It began life as a scarf!|It became something far greater.",
		_ = "It has a button on it.|The button doesn't do anything.",
	},
	memo = "I knitted a cushion, so somebody please come and sit on it.",
	log = "{a} knitted a cushion.",
})

makes({
	id = "driftwood",
	title = "Driftwood",
	item = "keep_gull",
	w = { base = 0.05, traits = { focus = -0.2 } },
	lines = {
		{ "n", "{a} spent the morning dragging bits of wood up from the beach." },
		{ "a", "It's a gull made out of driftwood.|Its head is an old fishing float.", "sparkle", "point" },
	},
	react = {
		cheeky = "it's even got the gull look|the 'give me your chips' look",
		dreamy = "The sea made the wood...|I only put the pieces together.",
		foodie = "It's guarding my lunch.|It's better at it than I am.",
		_ = "The real gulls keep staring at it.|I think they're jealous.",
	},
	memo = "My driftwood gull scared off a real one this morning.",
	log = "{a} made a gull out of driftwood.",
})

makes({
	id = "snowglobe",
	title = "A snow globe",
	item = "keep_globe",
	w = { base = 0.07, season = 4 },
	lines = {
		{ "n", "{a} is shaking a little glass ball and watching the snow fall inside it." },
		{ "a", "There's a tiny house in it with a tiny tree.|I made all of it myself.", "sparkle" },
	},
	react = {
		gentle = "It's for cold evenings.|You give it a shake and watch it by the fire.",
		cheeky = "i nearly glued my finger in there",
		gloomy = "It's always winter in there.|I find that calming, heh.",
		sunny = "Shake it, {player}, go on!",
		_ = "Go on, give it a shake.|See how the snow swirls?",
	},
	memo = "I keep shaking the snow globe I made, and I can't stop.",
	log = "{a} made a snow globe.",
})

-- little moments ----------------------------------------------------------------------------------

event({
	id = "trip",
	when = "day",
	weight = W({ base = 0.22, traits = { focus = -0.3 } }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "Smooth")
		s:n("{a} tripped over absolutely nothing in the middle of the square.")
		burst(s, "a", {
			proud = "Th-that was a dance move.|It's very new and very difficult.",
			cheeky = "ta da|i'll be here all week",
			shy = "Nobody saw that...|Please tell me nobody saw that.",
			bold = "The ground started it.",
			cool = "Hm, I meant to do that.",
			prickly = "What are you looking at?|Keep walking, {player}.",
			dramatic = "I have fallen in front of the WHOLE town!",
			gloomy = "Hello again, floor.|We meet so often, heh.",
			polite = "Oh, excuse me.|Sorry, everyone, do carry on.",
			nervous = "D-did anyone see that?|Did you see that? Oh no, oh no.",
			_ = "I'm fine, I'm fine.|Keep walking, there's nothing to see.",
		}, "sweat", "laugh")
		s:mood("a", -1)
		s:log("{a} tripped over nothing.")
		return s:done()
	end,
})

local PIGEON = { "Captain", "Biscuit", "Sir Flaps", "Doris", "Pudding", "Gary" }

event({
	id = "pigeon",
	when = "day",
	weight = W({ base = 0.15 }),
	scene = function(ctx, a)
		local names = ctx.rng:shuffle(PIGEON)
		local s = K.scene(ctx, "A follower")
		s:n("A pigeon has been following {a} round town all morning.")
		burst(s, "a", {
			shy = "Um, {player}...|It won't stop looking at me, but I think it's sweet.",
			bold = "I've got a sidekick now.|It keeps up, too.",
			cheeky = "i gave it one crumb, just one|now it thinks it lives with me",
			cool = "{player}.|There's a pigeon following me, and I've decided it can stay.",
			prickly = "Shoo.|...Fine, don't shoo, you can stay.",
			dramatic = "A loyal companion, {player}, and it chose ME!",
			gloomy = "It's the first friend I've made all week...|And it's a pigeon, heh.",
			foodie = "It likes the same bakery as me, so I respect it.",
			nervous = "Does it want something?|What does it want from me?",
			sunny = "{player}, {player}, I have a pigeon now!",
			_ = "I think it's decided we're friends now.",
		}, "question")
		burst(s, "a", "It needs a name, though.|What should I call it?", "idea")
		for i = 1, 2 do
			local name = names[i]
			s:choice(name .. "?", function(c)
				c:with({ pet = name })
				burst(c, "a", {
					prickly = "{pet}.|...Fine, it suits the little pest.",
					cheeky = "{pet}, hehe|hello, {pet}",
					_ = "{pet} is perfect.|Hello, {pet}.",
				}, "heart", "cheer")
				c:mood("a", 3)
				c:memo("a", "{pet} the pigeon still follows me everywhere.")
			end)
		end
		s:log("A pigeon adopted {a}.")
		return s:done()
	end,
})

local CATS = { "Turnip", "Duchess", "Pebble", "Mr Socks", "Waffle", "Pickle" }

event({
	id = "stray",
	when = "day",
	weight = W({ base = 0.12, traits = { kind = 0.3 } }),
	scene = function(ctx, a)
		local names = ctx.rng:shuffle(CATS)
		local s = K.scene(ctx, "A cat moves in")
		s:prop("cat", "a")
		s:n("A ginger cat has been sitting on {a}'s doorstep for three days.")
		burst(s, "a", {
			gentle = "{player}, I think it's decided it lives here now.|Who am I to argue with a cat?",
			proud = "Hmph, even cats know quality when they see it.|It picked my step out of the whole street.",
			easygoing = "It naps even more than I do, and I respect that.",
			cool = "It's staying, as far as I'm concerned.",
			prickly = "I didn't invite it.|...I did buy it a bowl, but don't read into it.",
			bookish = "Did you know cats pick their people?|It's never the other way round.",
			gloomy = "It'll leave, they always do...|Oh, it's still here, heh.",
			polite = "Hello, {player}.|A cat has chosen my doorstep, of all the doorsteps in town.",
			sunny = "{player}, I think I have a cat now!|It hasn't said so, but it hasn't left either!",
			shy = "Um...|I think I might have a cat now.",
			_ = "I think I have a cat now, {player}.",
		}, "heart")
		burst(s, "a", "It'll need a name, though.|What do you think suits it?", "question")
		for i = 1, 2 do
			local name = names[i]
			s:choice(name .. "?", function(c)
				c:with({ pet = name })
				burst(c, "a", {
					cool = "{pet}.|...Yes, that's right.",
					shy = "{pet}...|...!|Hello, {pet}.",
					_ = "{pet}, yes, you look exactly like a {pet}.",
				}, "heart", "cheer")
				c:mood("a", 6)
				c:hearts("a", 1)
				c:memo("a", "{pet} slept on my face last night, and I didn't have the heart to move.")
			end)
		end
		s:log("A stray cat moved in with {a}.")
		return s:done()
	end,
})

event({
	id = "spider",
	when = "any",
	weight = W({ base = 0.18 }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "A spider")
		s:n("There's a spider in {a}'s bath, and it's a big one.")
		burst(s, "a", {
			bold = "I'll put it outside, gently.|Come here, little guy.",
			gentle = "Oh, my, the poor thing.|It's only looking for somewhere warm, isn't it?",
			shy = "{player}...|There's a spider in my bath, so it can have the house now.",
			proud = "I'm not scared, I'm letting it have the bath.|As a guest.",
			cheeky = "gonna put it in someone's shoe|...kidding, kidding",
			dreamy = "Do you think it has a name?|It looks like a Clive to me.",
			sunny = "{player}, {player}, come here quickly!|Bring a cup with you!",
			cool = "There's a big spider in the bath.|I'll need a cup.",
			prickly = "It can't stay.|...Fine, it can stay until I find a cup.",
			dramatic = "{player}, there's a BEAST in my bath!",
			bookish = "Actually, that's a house spider, and they eat flies.|I still don't want it in my bath, though.",
			gloomy = "Of course it's in the bath.|Where else would it be?",
			polite = "Excuse me, would you mind terribly moving?|I'd like to have a bath.",
			foodie = "It's bigger than a meatball.|Why did I just think of a meatball?",
			nervous = "Don't move, is it moving?|Oh no, oh no, it's moving.",
			_ = "Can someone else deal with this?|I'm not going in there, {player}.",
		}, "sweat")
		s:choice("I'll take it outside.", function(c)
			c:n("You carried it out in a cup and let it go by the hedge.")
			c:voice("a", "thanks", "heart")
			c:hearts("a", 1)
			c:mood("a", 2)
		end)
		s:choice("It was here first.", function(c)
			burst(c, "a", {
				gentle = "Then it can stay.|I'll wash at the beach for now.",
				proud = "Fine, it's my guest.|I'll bathe in the sea like a hero.",
				nervous = "O-okay, okay.|I'll just never go in there again.",
				cheeky = "wow, ok|the spider gets the bath and i get the sea",
				_ = "Fine, it can stay.|I'll wash at the beach.",
			}, "sweat")
			c:mood("a", -2)
		end)
		s:log("{a} found a spider in the bath.")
		return s:done()
	end,
})

event({
	id = "luckyday",
	when = "day",
	weight = W({ base = 0.15 }),
	scene = function(ctx, a)
		local coins = ctx.rng:int(2, 6) * 5
		local s = K.scene(ctx, "A lucky day"):with({ coins = coins })
		s:n("Everything is going right for {a} today.")
		burst(s, "a", {
			sunny = "{player}, I found a coin on my way out!|And then I found ANOTHER one by the fountain!",
			cool = "{player}.|I found a coin on my step and another by the fountain.",
			_ = "I found a coin on my way out this morning.|Then I found another one by the fountain.",
		}, "sparkle", "cheer")
		burst(s, "a", {
			proud = "Naturally, the world has finally caught up with me.",
			dreamy = "I think the sky likes me today...",
			cool = "It's not a bad start to the day.",
			gloomy = "Something bad's bound to happen to make up for it.|Nothing yet, though.",
			dramatic = "Fortune smiles upon me!|For today, at least.",
			nervous = "Should I hand them in?|Who would I even give them to?",
			_ = "I'm not going to ask why, I'll just enjoy it.",
		}, "music")
		s:coins(coins)
		s:mood("a", 5)
		s:memo("a", "I had the luckiest day yesterday, but it's back to normal now.")
		s:log("{a} had a lucky day and found {coins} coins.")
		return s:done()
	end,
})

event({
	id = "unlucky",
	when = "day",
	weight = W({ base = 0.2 }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "One of those days")
		s:n("{a} stubbed their toe on the way out, then dropped their toast butter side down.")
		burst(s, "a", {
			sunny = "Okay, okay, I'm still smiling.|Look, I'm smiling, ehehe.",
			proud = "This is a test, and I'm passing it.",
			easygoing = "I'm going back to bed.|I'll try again tomorrow.",
			cool = "Hm, today's cancelled, then.",
			prickly = "Don't, just don't, {player}.",
			dramatic = "The whole universe has turned against me!",
			gloomy = "This is just a normal morning for me, as usual...",
			foodie = "My toast, my poor toast.|It had jam on it and everything.",
			nervous = "What's going to go wrong next?|No, don't answer that.",
			shy = "Um, {player}...|It's been one of those mornings.",
			_ = "What's going to go wrong next?|Actually, don't answer that.",
		}, "sad")
		s:choice("Want to see my seagull impression?", function(c)
			c:n("You did your best seagull. It wasn't very good, but {a} laughed.")
			c:voice("a", "laugh", "music", "laugh")
			c:mood("a", 6)
			c:hearts("a", 1)
		end)
		s:choice("Tomorrow's another day.", function(c)
			burst(c, "a", "It had better be.", "sad")
			c:mood("a", -2)
		end)
		s:log("{a} had an unlucky day.")
		return s:done()
	end,
})

local COLLECT = { "spoons", "buttons", "stamps", "bottle tops", "interesting pebbles", "old keys" }

event({
	id = "collection",
	when = "day",
	weight = W({ base = 0.15, traits = { focus = 0.2 } }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "A collection"):with({ things = ctx.rng:pick(COLLECT) })
		burst(s, "a", {
			sunny = "{player}, guess what!|I'm collecting {things} now, and I've got eleven already!",
			cheeky = "guess what i collect now|wrong, it's {things}, and i've got eleven",
			cool = "{player}.|I've started collecting {things}, and I'm at eleven so far.",
			_ = "{player}, I've started collecting {things}.|I've got eleven already.",
		}, "sparkle", "point")
		burst(s, "a", {
			proud = "It's going to be the finest collection on the island.",
			dreamy = "Each one has its own story...|Well, I make them up, but still.",
			cheeky = "some of them were in other people's drawers|i'll give those back, i promise",
			cool = "Eleven's a good start.",
			prickly = "It's a perfectly normal hobby.|Stop smiling like that.",
			bookish = "Each one is labelled with the date, the place, and its condition.",
			gloomy = "Nobody else wanted them, so I took them in.",
			_ = "I don't really know why.|They're just nice to have.",
		}, "music")
		s:mood("a", 3)
		s:memo("a", "I'm up to twenty {things} now, if you want to see them.")
		s:log("{a} started collecting {things}.")
		return s:done()
	end,
})

event({
	id = "moustache",
	when = "day",
	weight = W({ base = 0.1, traits = { mischief = 0.5 } }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "It won't wash off")
		s:n("{a} drew a curly moustache on their face for a laugh, with the wrong pen.")
		burst(s, "a", {
			cheeky = "look at me, i'm distinguished|hehe",
			proud = "Frankly, I think it suits me.",
			shy = "I've scrubbed it four times...|It's still there.",
			cool = "It's staying, apparently.",
			dramatic = "I am a new person now, {player}!|A person with a moustache.",
			nervous = "W-what if it never comes off?|What if this is just my face now?",
			_ = "I'll have to wear it to work.|Tell me it suits me, {player}.",
		}, "sweat", "laugh")
		s:mood("a", 1)
		s:memo("a", "The moustache is nearly gone, but you can still see the curly bit.")
		s:log("{a} drew on a moustache that won't come off.")
		return s:done()
	end,
})

event({
	id = "songwriting",
	when = "day",
	weight = W({
		base = 0.1,
		cond = function(ctx, a)
			return ctx.v(a).hobby == "guitar" or ctx.rng:chance(0.4)
		end,
	}),
	scene = function(ctx, a)
		local s = K.scene(ctx, "A song about town")
		s:prop("guitar", "a")
		s:n("{a} sat on the step with a guitar and wrote a song about the town.")
		burst(s, "a", "Oh Catalog Town, your gulls are loud,|your bread is warm, and I'm so proud.", "music")
		burst(s, "a", {
			proud = "That's going to be a hit, mark my words.",
			shy = "That's all I've got so far...|Was it all right?",
			cool = "It's only a rough draft.",
			dramatic = "There are eleven verses, {player}, and you've only heard one!",
			foodie = "The line about the bread is my favourite, obviously.",
			_ = "The second verse is about the bus.|It still needs some work.",
		}, "sparkle")
		s:choice("Again, from the top.", function(c)
			burst(c, "a", {
				shy = "You want to hear it again?|Okay... um, from the top.",
				bold = "From the top, and louder this time!",
				_ = "From the top, then, and you can sing along this time.",
			}, "music", "cheer")
			c:all(2)
		end)
		s:choice("It needs a key change.", function(c)
			burst(c, "a", "You're right, it needs a key change.|And maybe fewer gulls.", "idea")
			c:mood("a", 3)
		end)
		s:log("{a} wrote a song about the town.")
		return s:done()
	end,
})

event({
	id = "bubbles",
	when = "day",
	weight = W({ base = 0.18, weather = { "clear", "blossom" } }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "Bubbles")
		s:n("{a} is blowing bubbles off the step, and some of them are very big.")
		burst(s, "a", {
			dreamy = "Each one's a tiny world...|And then it pops.",
			bold = "That's the biggest one yet.|It swallowed a whole leaf.",
			proud = "There's a technique to it.|I'm not going to share it, though.",
			cool = "That one went right over the roof.",
			gloomy = "They never last long.|They're nice while they do, though.",
			sunny = "Catch one, {player}!|Ooh, nearly!",
			_ = "One landed on a dog.|It looked so surprised.",
		}, "sparkle")
		s:mood("a", 3)
		s:log("{a} blew bubbles.")
		return s:done()
	end,
})

local NAPSPOTS = {
	"on a bench",
	"standing up at the bus stop",
	"in a deckchair at noon",
	"in a hammock with their shoes on",
	"under the big tree in the middle of a sentence",
}

event({
	id = "napspot",
	when = "day",
	weight = W({ base = 0.12, traits = { lazy = 0.6 } }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "Asleep"):with({ spot = ctx.rng:pick(NAPSPOTS) })
		s:n("{a} has fallen asleep {spot}.")
		s:say("a", "Zzz...", "zzz")
		burst(s, "a", {
			easygoing = "Mm, I was only resting my eyes.|*yawn* Five more minutes, okay?",
			proud = "I was resting my eyes on purpose.|There's a difference.",
			cool = "I'm up.|I was only resting.",
			prickly = "I wasn't asleep, so stop smiling, {player}.",
			_ = "Was I asleep?|No, I definitely wasn't asleep.",
		}, "zzz")
		s:mood("a", 3)
		s:log("{a} fell asleep {spot}.")
		return s:done()
	end,
})

event({
	id = "homesick",
	cutscene = "pier",
	when = "any",
	weight = W({ base = 0.12 }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "Homesick")
		s:n("{a} is sitting on the wall by the sea, looking out.")
		burst(s, "a", {
			bold = "I miss my old street sometimes.|Don't tell anyone I said that.",
			shy = "My old house had a blue door...|I think about it sometimes.",
			proud = "Where I grew up, there's a statue of my gran.|It's a small one, but still.",
			cool = "I was just thinking about home.",
			prickly = "I'm fine.|...I miss home a bit, that's all.",
			dramatic = "Across that sea, {player}, is everything I left behind.",
			gloomy = "Nobody back home writes much anymore...",
			foodie = "My dad made a stew every Sunday.|I've tried, but I can never get it right.",
			gentle = "Oh, hello, {player}.|I was just thinking about home.",
			_ = "I miss the place I grew up.|Even the smell of it.",
		}, "sad")
		s:choice("Tell me about it?", function(c)
			c:n("{a} talked about home for a long time, and you heard all about a dog called Bean.")
			burst(c, "a", {
				bold = "...Thanks.|Anyway, don't tell anyone I got soppy, all right?",
				shy = "Thanks for listening.|I don't usually talk about it...",
				proud = "Well, that was more than I meant to say.",
				prickly = "...Thanks.|Don't make it weird.",
				polite = "Thank you for listening, {player}.|I truly appreciate it.",
				cool = "...Thanks.",
				_ = "Thanks, I haven't talked about it in ages.",
			}, "heart")
			c:mood("a", 5)
			c:hearts("a", 1)
			c:memo("a", "I told you about Bean, didn't I? He was our dog back home, and a very good dog.")
		end)
		s:choice("This is home now too.", function(c)
			burst(c, "a", "...Yeah.|Yeah, it is, thanks, {player}.", "heart")
			c:mood("a", 3)
		end)
		s:log("{a} felt a bit homesick.")
		return s:done()
	end,
})

event({
	id = "earlybird",
	when = "day",
	weight = W({ base = 0.15, traits = { lazy = 0.3 } }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "The early start")
		burst(s, "a", "I've set three alarms for tomorrow.|I'm getting up at five and going for a run.", "sweat")
		s:n("{a} switched off all three alarms without waking up, and now it's nearly lunchtime.")
		burst(s, "a", {
			easygoing = "I think my body made the right call, honestly.",
			proud = "My alarms are clearly faulty.|I'll be having words with them.",
			cool = "Tomorrow, then.",
			gloomy = "Heh... I knew that would happen.",
			nervous = "Did I miss anything?|Please tell me I didn't miss anything important.",
			_ = "I'll set four alarms tomorrow.",
		}, "zzz")
		s:mood("a", 1)
		s:log("{a} slept through three alarms.")
		return s:done()
	end,
})

event({
	id = "ears",
	when = "day",
	weight = W({ base = 0.1 }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "A hidden talent")
		burst(s, "a", "{player}, look at this.|I just found out I can wiggle my ears.", "sparkle", "point")
		s:n("They can, just about.")
		burst(s, "a", {
			proud = "I've always been gifted, and now there's proof.",
			cheeky = "i'm going to do it at the worst possible moments",
			shy = "I've never been good at something this quickly before...",
			cool = "Hm. It's not useful, but I'm keeping it.",
			dramatic = "A gift, hidden from me all these years!",
			_ = "What else can I do that I don't know about yet?",
		}, "music")
		s:mood("a", 4)
		s:memo("a", "Do you want to see me wiggle my ears? I've been practising.")
		s:log("{a} found out they can wiggle their ears.")
		return s:done()
	end,
})

event({
	id = "echo",
	when = "day",
	weight = W({ base = 0.1, traits = { social = 0.2 } }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "The echo")
		s:n("{a} climbed the hill and shouted hello at the cliffs.")
		s:n("The cliffs shouted hello back, and then a different voice said 'keep it down'.")
		burst(s, "a", {
			bold = "Who said that?|Come out where I can see you.",
			shy = "Sorry, sorry...|I didn't know anyone was up there.",
			dreamy = "Hmm... the hill has opinions.|I like that in a hill.",
			cool = "Huh.|Someone's up there.",
			prickly = "You keep it down!|...Sorry, that was rude of me.",
			gloomy = "Even the hill wants me to be quiet, heh.",
			nervous = "There's someone up there.|{player}, there's someone UP there!",
			_ = "I think somebody lives up there.",
		}, "question")
		s:mood("a", 2)
		s:log("{a} shouted at the cliffs to hear the echo.")
		return s:done()
	end,
})

event({
	id = "rainbow",
	when = "day",
	weight = W({ base = 0.3, weather = "rain", traits = { focus = -0.2 } }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "A rainbow")
		s:n("The rain stopped for a minute, and a rainbow came out over the harbour.")
		burst(s, "a", {
			dreamy = "I'm going to find where it ends...|I'll be back by dinner.",
			proud = "It came out for me, obviously.|Look, it's pointing right at my house.",
			cheeky = "race you to the end of it, go",
			cool = "{player}, look up over the harbour.",
			gloomy = "Huh, that's actually nice.",
			bookish = "It's only sunlight bending through raindrops.|Still, look at it.",
			sunny = "{player}, quick, look!|Let's watch it together before it goes!",
			_ = "Quick, look, before it goes.",
		}, "sparkle", "point")
		s:mood("a", 4)
		s:log("{a} saw a rainbow.")
		return s:done()
	end,
})

-- small worries you can settle by going to look ("Let's go and check.")
local WORRIES = {
	"I can't remember if I locked the door, and I've already gone back twice.",
	"I think I left the kettle on when I came out.",
	"I'm not sure I shut the gate, and the neighbour's dog always gets in.",
	"I think I left my window wide open, and the gulls get in.",
	"I might have left the oven on, and now I can't stop picturing it.",
}

event({
	id = "worry",
	when = "any",
	weight = W({ base = 0.2, traits = { brave = -0.3 } }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "A worry")
		burst(s, "a", {
			shy = "Um, {player}...|Can I tell you something? It's only small.",
			nervous = "S-sorry, can I ask you something?|Sorry, I know you're busy.",
			cool = "{player}.|It's a small thing, but it's bothering me.",
			prickly = "Don't laugh, okay?",
			_ = "{player}...|Can I tell you something?",
		}, "sweat")
		s:say("a", ctx.rng:pick(WORRIES), "sweat")
		-- how it sits with them (one worry: a second one from their own lines would pile on)
		burst(s, "a", {
			shy = "It's probably nothing...|But I can't stop thinking about it.",
			nervous = "What if it's really bad?|Oh no, oh no.",
			gloomy = "It'll be the one day it actually matters, as usual.",
			proud = "Not that I'm worried, of course.",
			bold = "It's bugging me, and I hate that.",
			cool = "I know it's probably fine.",
			prickly = "I know it's silly, so don't say it.",
			dramatic = "It's ALL I can think about, {player}!",
			bookish = "Statistically it's fine, but my brain won't listen.",
			gentle = "I'm sure it's fine, but it's been nagging at me.",
			sunny = "I'm sure it's fine!|...Mostly sure.",
			easygoing = "It's probably fine, but it's stopping me from napping.",
			foodie = "I can't even enjoy my snack until I know.",
			polite = "I'm sorry to trouble you with something so small.",
			dreamy = "Hmm... it keeps floating back into my head.",
			cheeky = "and before you laugh, yes, i know",
			_ = "It's probably fine, but it keeps bugging me.",
		}, "question")
		s:choice("It's not as bad as you think.", function(c)
			burst(c, "a", {
				proud = "I wasn't worried.|...Okay, maybe a little.",
				easygoing = "Yeah, you're right.|Worrying is too much effort anyway.",
				gloomy = "Maybe...|Thanks for saying so, though.",
				nervous = "You really think so?|Okay, okay, I'm breathing.",
				_ = "You think so, {player}?|Okay, I'll try to stop thinking about it.",
			}, "heart")
			c:mood("a", 4)
			c:hearts("a", 1)
		end)
		s:choice("Let's go and check.", function(c)
			c:n("You went to check together, and it was fine. It's always fine.")
			burst(c, "a", {
				shy = "Thanks, and sorry...|I feel a bit silly now.",
				proud = "I knew it was fine.|I was just checking that you knew.",
				bold = "Right, good, that's settled.",
				polite = "Thank you so much for coming with me, {player}.",
				nervous = "Oh, thank goodness, thank you.|I'd have checked six more times on my own.",
				_ = "Thanks, I feel a bit silly now.",
			}, "heart")
			c:mood("a", 5)
		end)
		s:log("{a} was worried about something small.")
		return s:done()
	end,
})

local FORTUNES = {
	"You will meet a tall stranger. It will be a lamppost.",
	"Good things come to those who nap.",
	"Today is a good day to eat a second biscuit.",
	"Somebody is thinking about you. It's the baker, and you owe them money.",
	"The answer is yes, if the question is soup.",
}

event({
	id = "fortune",
	when = "any",
	weight = W({ base = 0.12 }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "A fortune"):with({ fortune = ctx.rng:pick(FORTUNES) })
		s:n("{a} cracked open a fortune biscuit and read the slip inside.")
		s:n("'{fortune}'")
		burst(s, "a", {
			dreamy = "This is going to come true...|I can feel it.",
			proud = "I make my own fortune, thank you very much.",
			cheeky = "keeping this, it's going on the fridge",
			cool = "Hm.|I'll keep an eye out.",
			gloomy = "That's better than I expected, honestly.",
			foodie = "The biscuit was good, and that's fortune enough for me.",
			nervous = "What does it mean?|Does it mean something bad?",
			_ = "That's oddly specific.",
		}, "question")
		s:mood("a", 2)
		s:log("{a} got a strange fortune.")
		return s:done()
	end,
})

-- an invention, and what happened when it didn't work
local GADGETS = {
	{ "a toaster that butters too", "There was a bang, and a smell like burnt toast." },
	{ "a hat with an umbrella on it", "The umbrella opened, and the wind took the hat over the hedge." },
	{ "a self stirring spoon", "The spoon spun so fast it flicked soup all up the wall." },
	{ "shoes with little bells in", "The bells jammed after two steps, and now the shoes just squeak." },
}

event({
	id = "invention",
	when = "day",
	weight = W({ base = 0.1, traits = { focus = -0.2, mischief = 0.2 } }),
	scene = function(ctx, a)
		local gadget = ctx.rng:pick(GADGETS)
		local s = K.scene(ctx, "An invention"):with({ gadget = gadget[1] })
		burst(s, "a", {
			sunny = "{player}, {player}, come here!|I've invented {gadget}, watch!",
			dramatic = "{player}, the moment has come.|Behold, {gadget}!",
			cool = "{player}.|I made {gadget}, so watch this.",
			_ = "{player}, come here a minute.|I've invented {gadget}, so watch.",
		}, "idea", "point")
		if ctx.rng:chance(0.35) then
			s:n("It worked, and everyone was as surprised as {a} was.")
			burst(s, "a", BRAG, "sparkle", "cheer")
			s:mood("a", 6)
		else
			s:n(gadget[2])
			burst(s, "a", {
				proud = "Hmph, version two will be perfect.",
				easygoing = "Eh, shall we get lunch anyway?",
				cool = "Hm, noted.|I'll have another go tomorrow.",
				dramatic = "It lived so BRIEFLY!",
				gloomy = "Yeah, that's about right.",
				_ = "Back to the drawing board, then.",
			}, "sweat")
			s:mood("a", -1)
		end
		s:log("{a} invented {gadget}.")
		return s:done()
	end,
})

event({
	id = "finishbook",
	when = "any",
	weight = W({
		base = 0.12,
		cond = function(ctx, a)
			return ctx.v(a).hobby == "reading" or ctx.rng:chance(0.5)
		end,
	}),
	scene = function(ctx, a)
		local s = K.scene(ctx, "The last page")
		s:n("{a} closed a very thick book and stared at the wall for a while.")
		burst(s, "a", {
			bold = "The dog lived at the end.|I had to sit down for that.",
			shy = "It's over...|What do I do with my evenings now?",
			proud = "I saw that ending coming two hundred pages ago.",
			dreamy = "I want to live inside that book...|Do you think I could?",
			cool = "It was a good book.",
			bookish = "That was nine hundred pages.|I'm starting it again tomorrow.",
			gloomy = "Everyone left at the end, the way they always do.",
			dramatic = "They got on a BOAT, {player}, after everything!",
			_ = "Six hundred pages, and at the end they just got on a boat.",
		}, "sad")
		s:mood("a", 2)
		s:memo("a", "I finished that big book, and I'm still thinking about the ending.")
		s:log("{a} finished a long book.")
		return s:done()
	end,
})

-- dreams and daydreams ------------------------------------------------------------------------------

local DAYDREAMS = {
	"sailing a boat to the little islet and finding a castle on it",
	"opening a café that only sells pudding",
	"riding a gull across the harbour",
	"winning a medal for the best nap",
	"the whole town throwing me a parade for no reason",
	"living in a lighthouse with a cat and a lot of books",
}

event({
	id = "daydream",
	cutscene = "dream",
	when = "day",
	weight = W({ base = 0.18, traits = { focus = -0.5 } }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "Miles away"):with({ dream = ctx.rng:pick(DAYDREAMS) })
		s:n("{a} has been staring at the same spot for ten minutes, smiling.")
		burst(s, "a", "Oh, sorry, {player}, I was miles away.|I was imagining {dream}.", "zzz")
		burst(s, "a", {
			dreamy = "It was going so well...|Can I go back to it?",
			proud = "It'll happen one day, mark my words.",
			cool = "Anyway, where were we?",
			gloomy = "Back to real life, as usual.",
			cheeky = "you were in it too|you were very rude, hehe",
			_ = "Was I gone long?|I was, wasn't I?",
		}, "sparkle")
		s:mood("a", 3)
		s:log("{a} was lost in a daydream.")
		return s:done()
	end,
})

event({
	id = "dreamfood",
	cutscene = "dream",
	when = "day",
	weight = W({ base = 0.12 }),
	scene = function(ctx, a)
		-- a house can be made of cheese or pie, not soup
		local solid = {}
		for _, f in Foods.list do
			if f.id ~= "soup" and f.id ~= "curry" and f.id ~= "stew" then
				table.insert(solid, f)
			end
		end
		local fav = Foods.get(ctx.v(a).fav)
		if not fav or not table.find(solid, fav) then
			fav = ctx.rng:pick(solid)
		end
		local s = K.scene(ctx, "A dream about food"):with({ food = fav.name:lower() })
		burst(
			s,
			"a",
			"{player}, I had the best dream last night.|I lived in a house made of {food}, and I ate the front door.",
			"zzz"
		)
		burst(s, "a", {
			easygoing = "That's the best dream I've had all year.",
			proud = "Even in my dreams, I have excellent taste.",
			foodie = "Then I ate the stairs and the roof, mmm.|Best night of my life.",
			_ = "I woke up so hungry.",
		}, "heart")
		s:mood("a", 2)
		s:log("{a} dreamed about {food}.")
		return s:done()
	end,
})

event({
	id = "dreamsong",
	cutscene = "dream",
	when = "day",
	weight = W({ base = 0.1, traits = { focus = -0.3 } }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "A song from a dream")
		burst(
			s,
			"a",
			"I heard the most beautiful song in my dream last night.|Quick, let me sing it before I forget... la la LAA la.",
			"music"
		)
		s:n("It sounded a lot like the bin lorry reversing.")
		burst(s, "a", {
			proud = "That song is going to be famous one day.",
			shy = "It sounded much better in the dream...",
			cool = "And now it's gone, oh well.",
			_ = "Hmm, it's gone already.|Did you catch any of it, {player}?",
		}, "question")
		s:mood("a", 2)
		s:log("{a} sang a song from a dream.")
		return s:done()
	end,
})

event({
	id = "futuretown",
	when = "day",
	weight = W({ base = 0.08 }),
	scene = function(ctx, a)
		local city = ctx.city()
		local s = K.scene(ctx, "Ten years from now")
		s:n("{a} was looking out over the rooftops.")
		if city.value > 20000 then
			burst(
				s,
				"a",
				"Imagine this place in ten years' time.|It's already big, so I want a tram next.",
				"idea",
				"point"
			)
		else
			burst(s, "a", {
				proud = "Imagine this place in ten years' time.|More houses, and a statue of me in the square.",
				shy = "Imagine this place in ten years...|There'd be more houses, and more people, I suppose.",
				foodie = "Imagine this place in ten years' time.|I'm hoping for three bakeries, maybe four.",
				_ = "Imagine this place in ten years' time.|More houses, and a bigger bakery.",
			}, "idea", "point")
		end
		burst(s, "a", {
			gentle = "I hope we're all still here to see it.",
			cheeky = "i want my name on something|a bench, at least",
			proud = "I'd like a say in where things go, mind you.",
			shy = "I hope there's still room in it for me.",
			gloomy = "I hope I'm still around for it...|I'd like that, heh.",
			prickly = "Just don't wreck it, {player}, that's all I'm saying.",
			polite = "Thank you for building it, {player}.|I do mean that.",
			cool = "It'll be good.",
			_ = "You'll be the one building it, won't you, {player}?",
		}, "heart")
		s:hearts("a", 1)
		s:log("{a} wondered what the town will be like in ten years.")
		return s:done()
	end,
})

event({
	id = "lemonade",
	cutscene = "stall",
	when = "day",
	weight = W({ base = 0.18, season = 2, weather = { "clear", "cloudy" } }),
	scene = function(ctx, a)
		local coins = ctx.rng:int(3, 8) * 5
		local s = K.scene(ctx, "Lemonade"):with({ coins = coins })
		s:prop("stall", "a")
		s:n("{a} has set up a lemonade stand on the corner.")
		burst(s, "a", {
			proud = "This is the finest lemonade on the island.|I squeezed every lemon myself.",
			shy = "Um, would you like some lemonade?|Only if you want some, no pressure...",
			cheeky = "half price if you can guess what's in it|nobody can",
			bold = "Cold lemonade, get it here!|You'll have a glass, right?",
			easygoing = "There's lemonade, and you can leave the coins in the tin.|I'm going to sit down for a bit.",
			cool = "There's cold lemonade, if you want some.",
			prickly = "Buy some or move along.|...Do you want a free one, {player}?",
			dramatic = "Lemonade, the only cure for a day this HOT!",
			polite = "Hello there.|Would you care for a glass of lemonade?",
			foodie = "I put mint in it, and a little ginger.|Try it, go on!",
			nervous = "Is it too sour?|Please tell me if it's too sour.",
			_ = "Cold lemonade here, come and get some.",
		}, "music", "wave")
		s:n("By the afternoon the jug was empty and the tin was full.")
		s:coins(coins)
		s:mood("a", 4)
		s:log("{a} sold lemonade and made {coins} coins for the town.")
		return s:done()
	end,
})

-- A villager takes up a hobby on their own, and the town hears about it (the user: "make random
-- events where villagers pick up hobbies instead": a hobby was one of the thank yous you picked
-- at a new heart level). One a villager has already isn't picked again.
local TAKEN_UP = {
	gardening = "{a} has dug a patch behind the house and planted rows of something.",
	painting = "{a} bought a box of paints and has been down by the harbour with an easel.",
	guitar = "{a} found an old guitar at the market, and you can hear it from the street.",
	fishing = "{a} borrowed a rod and has been on the pier since early this morning.",
	baking = "{a} has been baking every evening this week, and the whole street smells of it.",
	stargazing = "{a} has been up on the hill after dark with a borrowed telescope.",
	jogging = "{a} has started running round the island before breakfast.",
	reading = "{a} came back from the library with an armful of books.",
	knitting = "{a} has been knitting on the bench by the square most afternoons.",
	birds = "{a} has started carrying a notebook and stopping to look at gulls.",
}

event({
	id = "takeuphobby",
	when = "day",
	weight = W({
		base = 0.16,
		cond = function(ctx, a)
			local v = ctx.v(a)
			for _, h in Sayings.hobbies do
				if h.id ~= v.hobby then
					return true
				end
			end
			return false
		end,
	}),
	scene = function(ctx, a)
		local v = ctx.v(a)
		local pool = {}
		for _, h in Sayings.hobbies do
			if h.id ~= v.hobby then
				table.insert(pool, h)
			end
		end
		local h = ctx.rng:pick(pool)
		local s = K.scene(ctx, "Something new")
		s:with({ hobby = h.name, Hobby = h.name:sub(1, 1):upper() .. h.name:sub(2) })
		s:n(TAKEN_UP[h.id] or "{a} has taken up {hobby}.")
		burst(s, "a", {
			sunny = "{player}, guess what, I've taken up {hobby}!|Sorry, I keep telling everyone.",
			gentle = "I've started {hobby}.|It's nice to have something quiet for the evenings.",
			bold = "I took up {hobby} this week.|I'll be good at it by the end of the month, you'll see.",
			dreamy = "I've been doing {hobby}...|The time sort of disappears when I do it.",
			easygoing = "I took up {hobby}, nothing serious.|It's something to do between naps.",
			proud = "I've taken up {hobby}.|I'm told I have a natural gift for it.",
			shy = "Um, I've started {hobby}...|I'm not very good yet, so please don't watch.",
			cheeky = "i've got a new hobby, it's {hobby}|don't laugh, ok you can laugh a bit",
			cool = "I've taken up {hobby}, and it's better than I expected.",
			prickly = "Yes, I've started {hobby}, so don't make a fuss.",
			dramatic = "{player}, I've found my true calling.|It's {hobby}!",
			bookish = "I've taken up {hobby}.|I read three books on it first, of course.",
			gloomy = "I started {hobby} thinking I'd hate it.|I don't, heh.",
			polite = "Hello, {player}.|I've taken up {hobby}, if I may mention it.",
			foodie = "{Hobby} makes me so hungry.|I think that's a good sign.",
			nervous = "I s-started {hobby} this week.|Is it okay if I'm bad at it for a while?",
			_ = "I've started {hobby}, and I'm still working it out.",
		}, "idea", "cheer")
		s:hobby("a", h.id)
		s:mood("a", 4)
		s:memo("a", "I took up {hobby} this week, so ask me how it's going.")
		s:log("{a} took up {hobby}.")
		return s:done()
	end,
})

-- more of one villager's days ---------------------------------------------------------------------

event({
	id = "missedbus",
	when = "day",
	weight = W({ base = 0.15 }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "Missed it")
		s:n("{a} ran for the bus and missed it by one step, and the doors shut right in front of them.")
		burst(s, "a", {
			bold = "Hey!|...It saw me, I know it definitely saw me.",
			proud = "Th-that's fine, I was going to walk anyway.|It's good for my health.",
			shy = "Oh...|Okay, that's fine, it's fine.",
			cheeky = "rude|i'm writing a letter to the bus",
			easygoing = "Eh, there's a bench, so I'll just wait.",
			dreamy = "Bye, bus...|Have a nice trip.",
			sunny = "{player}, did you see that?|I was SO close, ehehe.",
			cool = "I'll get the next one, then.",
			prickly = "Great, wonderful.|No, I'm not upset, why would I be?",
			dramatic = "It left without me, {player}!|It's GONE!",
			gloomy = "It always leaves just as I get there, as usual.",
			polite = "Oh, dear.|I hope the driver has a nice day anyway.",
			foodie = "I was going to the market for cheese.|The cheese will have to wait, I suppose.",
			nervous = "Was that the last one?|Oh no, it wasn't the last one, was it?",
			_ = "I missed it by one step.|One single step.",
		}, "sweat")
		s:choice("Walk with me?", function(c)
			c:n("You walked down to the harbour together, and the bus was still at the stop when you got there.")
			burst(c, "a", "Of course it was.|...It was a nice walk, though, so thanks, {player}.", "heart")
			c:mood("a", 4)
			c:hearts("a", 1)
			c:memo("a", "Remember when we walked to the harbour and nearly beat the bus?")
		end)
		s:choice("Another one's due soon.", function(c)
			burst(c, "a", {
				easygoing = "See, I told you.|It's bench time.",
				nervous = "How soon is soon?|Okay, I'll wait right here.",
				prickly = "Fine, I'm sitting down.|Don't talk to me until it comes.",
				_ = "Yeah, okay, I'll wait for it.",
			}, "zzz")
			c:mood("a", -1)
		end)
		s:log("{a} missed the bus by one step.")
		return s:done()
	end,
})

event({
	id = "bakerysmell",
	when = "day",
	weight = W({
		base = 0.14,
		cond = function(ctx)
			return ctx.hour < 11
		end,
	}),
	scene = function(ctx, a)
		local s = K.scene(ctx, "Warm bread")
		s:n("The bakery isn't open yet, and {a} is standing outside it with their eyes shut, breathing in.")
		burst(s, "a", {
			foodie = "Mmm, rye, and something with cinnamon.|And yes, there are definitely buns.",
			dreamy = "If I stand here long enough, I think I'll turn into toast...",
			easygoing = "It's the best smell in town.|I come and stand here every morning.",
			bold = "I'm first in the queue.|I'm always first, you know.",
			shy = "Oh, {player}...|I wasn't just standing here sniffing, honestly.",
			cool = "It isn't open yet, but it's worth the wait.",
			prickly = "What?|It's free, they can't charge for a smell.",
			dramatic = "This, {player}, is why I get up in the morning!",
			bookish = "Actually, that smell is mostly the crust browning.|There's a proper word for it, but I've forgotten it.",
			gloomy = "It always smells better than it tastes...|Well, almost always.",
			polite = "Good morning, {player}.|The smell is lovely, isn't it?",
			_ = "Smell that, just smell it.",
		}, "heart")
		s:n("The door opened, and the baker handed {a} the first roll of the day, still too hot to hold.")
		burst(s, "a", "Hot, hot, hot!|It's worth it, though.", "sparkle", "cheer")
		s:mood("a", 4)
		s:log("{a} waited outside the bakery for the first roll.")
		return s:done()
	end,
})

event({
	id = "pierfish",
	when = "day",
	weight = W({ base = 0.15, weather = { "clear", "cloudy", "leaves", "blossom" } }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "On the pier")
		s:prop("fishing", "a")
		s:n("{a} has been sitting at the end of the pier with a rod since breakfast.")
		burst(s, "a", "Shh, {player}, keep quiet.|I think something's biting.", "question")
		local roll = ctx.rng:float(0, 1)
		if roll < 0.35 then
			s:n("Up came a fish, silver and flapping, about the size of a spoon.")
			burst(s, "a", {
				proud = "A fine catch, look at it.",
				bold = "Hah, got you!|...Okay, back you go, tiny.",
				gentle = "Oh, my, you're only little.|Back you go.",
				cool = "It's small.|It still counts.",
				dramatic = "A monster of the deep!|...A very small one, so back you go.",
				foodie = "That's about half a sandwich.|Maybe a third, so back you go.",
				_ = "It's a fish, but a small one.|Back you go.",
			}, "sparkle", "cheer")
			s:mood("a", 5)
			s:memo("a", "I caught a fish off the pier, but it was so small that I put it back.")
		elseif roll < 0.7 then
			s:n("Up came an old boot, full of water and one surprised crab.")
			burst(s, "a", {
				cheeky = "new shoe|just the one, though",
				prickly = "Every time, every single time.",
				gloomy = "Of course it's a boot.",
				nervous = "D-does someone want that back?",
				bookish = "That boot's been down there for years.|Look at all the barnacles on it.",
				_ = "A boot with a crab in it.|Hello, crab.",
			}, "sweat")
			s:mood("a", 1)
		else
			s:n("It was only seaweed again.")
			burst(s, "a", {
				easygoing = "Eh, it's about the sitting, really.",
				dreamy = "Hmm, the sea's keeping its fish today.|Fair enough.",
				_ = "Nothing again.|I'm staying another hour anyway.",
			}, "zzz")
			s:mood("a", 2)
		end
		s:log("{a} went fishing off the pier.")
		return s:done()
	end,
})

event({
	id = "latebook",
	when = "any",
	weight = W({ base = 0.08, traits = { focus = -0.2 } }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "Three weeks late")
		s:n("{a} found a library book under the sofa, and it was due back three weeks ago.")
		burst(s, "a", {
			shy = "Oh no...|The librarian's going to look at me.",
			proud = "Three weeks is nothing.|I was studying it.",
			cool = "Oops.",
			prickly = "Who put that there?|...I did, didn't I?",
			dramatic = "I'm a criminal, {player}, a LIBRARY criminal!",
			bookish = "No, no, no.|I've never had a late book in my life.",
			gloomy = "The fine's going to be huge.|I just know it.",
			polite = "I must apologise to the librarian in person.|Perhaps I'll bring a cake.",
			nervous = "What's the fine?|What if there's a list, and I'm on it?",
			_ = "{player}...|I'd forgotten I even had it.",
		}, "sweat")
		s:choice("I'll come with you.", function(c)
			c:n("You went together. The librarian looked at the date, then at {a}, and stamped it.")
			c:n("There was no fine, only a very long look.")
			burst(c, "a", "That look was worse than a fine.|...Thanks for coming with me, {player}.", "heart")
			c:mood("a", 4)
			c:hearts("a", 1)
		end)
		s:choice("Read it first, then?", function(c)
			burst(c, "a", {
				bookish = "...You're right, I never finished it.|One more night won't hurt.",
				nervous = "Keep it another day? Wouldn't that be worse?|...Okay, fine, one more day.",
				cheeky = "a partner in crime|i like it, hehe",
				_ = "Ha, fair enough.|I never got past chapter two.",
			}, "zzz")
			c:mood("a", 2)
			c:memo("a", "I'm still reading that late library book, so don't tell anyone.")
		end)
		s:log("{a} found a library book three weeks late.")
		return s:done()
	end,
})

event({
	id = "squeakyshoes",
	when = "day",
	weight = W({ base = 0.13 }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "New shoes")
		s:n("{a} has new shoes, and they squeak on every single step.")
		s:say("a", "Squeak, squeak, squeak.", "sweat")
		burst(s, "a", {
			cheeky = "i can't sneak up on anyone now|my whole career, ruined",
			proud = "They're very good shoes.|They just want everyone to know it.",
			shy = "Everyone turns round when I walk past...",
			bold = "I'll walk them in.|Ten laps of the square should do it.",
			easygoing = "Eh, at least nobody can lose me now.",
			cool = "They'll stop eventually.",
			prickly = "Don't, I know.|I can hear them too.",
			dramatic = "I am announced wherever I go!",
			bookish = "Actually, it's the new soles.|They usually wear in after about a week.",
			gloomy = "And I paid good money for these.",
			foodie = "They sound like a rubber duck.|Now I want a bath, and a bun.",
			nervous = "Is it loud? It's loud, isn't it?|Can everyone hear it?",
			polite = "I do apologise for the noise, everyone.",
			_ = "I'm told they stop once they're worn in.|I hope that's soon.",
		}, "sweat", "laugh")
		s:mood("a", 1)
		s:memo("a", "My shoes have mostly stopped squeaking, but the left one still does.")
		s:log("{a}'s new shoes squeak.")
		return s:done()
	end,
})

event({
	id = "bottlenote",
	when = "day",
	weight = W({ base = 0.1, weather = { "clear", "cloudy", "leaves" } }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "A note in a bottle")
		s:n("{a} found a bottle on the beach with a rolled up note inside.")
		s:n("It said 'Hello from the island with the red lighthouse. Is anyone there?'")
		burst(s, "a", {
			sunny = "Somebody's out there, {player}!|We have to write back!",
			dreamy = "It floated all this way just to say hello...",
			cool = "Huh, so there's someone out there.",
			prickly = "It's probably a joke.|...I'm keeping it, though.",
			dramatic = "A voice from across the sea!",
			bookish = "Actually, the current runs east at this time of year.|So it must have come from that way.",
			gloomy = "I hope someone wrote back to them.|Somebody should.",
			nervous = "Do we answer it?|What would we even say?",
			_ = "It's come all the way from another island, {player}.",
		}, "sparkle")
		s:choice("Write back.", function(c)
			c:n(
				"{a} wrote 'Yes, this is Catalog Town, and we have a good bakery' and threw the bottle as far as they could."
			)
			burst(c, "a", "It went about four metres.|...It'll get there eventually.", "heart")
			c:mood("a", 5)
			c:memo("a", "I sent a note back in that bottle, and I check the beach every morning now.")
		end)
		s:choice("Keep the note.", function(c)
			burst(c, "a", "Yeah, I'll pin it up by the door.", "heart")
			c:mood("a", 3)
		end)
		s:log("{a} found a message in a bottle.")
		return s:done()
	end,
})

event({
	id = "sunrise",
	when = "day",
	weight = W({
		base = 0.12,
		weather = { "clear", "cloudy", "blossom" },
		cond = function(ctx)
			return ctx.hour < 10
		end,
	}),
	scene = function(ctx, a)
		local s = K.scene(ctx, "Sunrise")
		s:n("{a} climbed the hill in the dark to watch the sun come up over the sea.")
		burst(s, "a", {
			gentle = "There it is.|Good morning, everyone.",
			dreamy = "It's like the sea is waking up too...",
			bold = "Hah, made it, I beat the sun up here.",
			easygoing = "Okay, that was worth getting up for, just this once.",
			sunny = "{player}, you came!|Look, look, it's coming up!",
			cool = "Hm, it's a good one today.",
			prickly = "It's cold and early.|...Worth it, though, but don't tell anyone I said that.",
			dramatic = "A new day is born!",
			bookish = "Actually, that light left the sun about eight minutes ago.|So we're always seeing it a little late.",
			gloomy = "Huh, it's pretty.|I didn't expect that.",
			polite = "Thank you for coming up with me.|It's lovely, isn't it?",
			foodie = "It looks just like an egg yolk.|Now I want breakfast.",
			nervous = "We didn't miss it, did we?|Oh, phew, there it is.",
			_ = "There it is.",
		}, "sparkle")
		s:mood("a", 5)
		s:memo("a", "I watched the sun come up from the hill, and I'm doing it again on Sunday.")
		s:log("{a} watched the sunrise from the hill.")
		return s:done()
	end,
})

event({
	id = "lockedout",
	when = "day",
	weight = W({ base = 0.12, traits = { focus = -0.4 } }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "Locked out")
		s:n("{a} is standing outside their own front door, patting every pocket.")
		s:say("a", "{player}, hi, please don't laugh.", "sweat")
		burst(s, "a", {
			cheeky = "i locked myself out|the key's on the table, i can SEE it",
			proud = "Th-the door locked itself.|I had nothing to do with it.",
			shy = "I locked myself out...|Again.",
			cool = "The key's inside, and I'm out here.",
			prickly = "Go on, laugh about it.|Get it over with.",
			dramatic = "Shut out of my very own home!",
			gloomy = "Locked out, as usual, heh.",
			nervous = "I checked I had it.|I checked twice, so how did this happen?",
			_ = "I've locked myself out.|The key's sitting on the kitchen table.",
		}, "sweat")
		s:choice("Try the back window?", function(c)
			if ctx.rng:chance(0.6) then
				c:n("The back window was open a crack, so {a} climbed in head first and landed in the washing basket.")
				burst(c, "a", "I'm in!|Well, I'm in the washing, but I'm in.", "sparkle", "cheer")
				c:mood("a", 4)
			else
				c:n("The back window was shut tight. {a} got halfway up the drainpipe and thought better of it.")
				burst(c, "a", "Nope, not doing that.|The neighbour has a spare, so I'll go and ask.", "sweat")
				c:mood("a", -1)
			end
		end)
		s:choice("I'll wait with you.", function(c)
			c:n("The spare key was at the neighbour's, in a teapot, and you had a cup of tea while you were there.")
			burst(c, "a", {
				polite = "Thank you for waiting with me.|That was very kind of you.",
				prickly = "...Thanks for waiting.|You didn't have to.",
				_ = "Thanks, {player}.|That was nicer than being locked out has any right to be.",
			}, "heart")
			c:mood("a", 4)
			c:hearts("a", 1)
		end)
		s:log("{a} locked themselves out.")
		return s:done()
	end,
})

event({
	id = "goodnight",
	when = "night",
	weight = W({ base = 0.12, traits = { social = 0.3 } }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "Night")
		s:n("A window opens as you pass, and {a} leans out in their pyjamas.")
		burst(s, "a", {
			sunny = "{player}, good night!|Let's do something fun tomorrow, okay?",
			gentle = "Good night, {player}.|Don't stay up too late, all right?",
			bold = "Hey, {player}.|It's late, so get to bed.",
			dreamy = "Good night...|Did you see the moon's out?",
			easygoing = "Night, I'm already half asleep.",
			proud = "Good night, {player}.|I saw you working hard today.",
			shy = "Um...|Good night, {player}.",
			cheeky = "psst, {player}|night, hehe",
			cool = "Night.",
			prickly = "You're up late.|...Good night, then.",
			dramatic = "Farewell until morning, {player}!",
			bookish = "Good night, I'm reading one more chapter.|Two at most.",
			gloomy = "Good night.|Tomorrow might even be all right, heh.",
			polite = "Good night, {player}.|Thank you for today.",
			foodie = "Night, I'm going to dream about pancakes on purpose.",
			nervous = "Good night!|You locked your door, right?",
			_ = "Good night, {player}.",
		}, "zzz", "wave")
		s:choice("Night.", function(c)
			burst(c, "a", "Sleep well.", "heart")
			c:hearts("a", 1)
			c:mood("a", 2)
		end)
		s:choice("Still up?", function(c)
			burst(c, "a", {
				cool = "I couldn't sleep, but I think I can now.|Night.",
				prickly = "Clearly.|...I'm going to bed now, night.",
				nervous = "I was checking the windows.|They're all shut, so it's bed now.",
				_ = "I'm just going.|Night, {player}.",
			}, "zzz")
			c:mood("a", 3)
		end)
		s:log("{a} said goodnight from the window.")
		return s:done()
	end,
})

event({
	id = "noumbrella",
	when = "day",
	weight = W({ base = 0.18, weather = { "rain", "storm" } }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "Caught in the rain")
		s:n("{a} is sheltering under the bakery's awning, and the rain's coming down hard.")
		burst(s, "a", {
			sunny = "{player}, come and hide here with me!|There's room!",
			gentle = "It'll pass soon, it always does.",
			bold = "I'm making a run for it.|Any second now.",
			dreamy = "I like the sound it makes on the awning...",
			easygoing = "I'll wait it out.|I'm very good at waiting.",
			proud = "I left my umbrella at home on purpose.|I'm testing how waterproof my coat is.",
			shy = "I didn't bring an umbrella...",
			cheeky = "been here an hour|the baker keeps giving me looks",
			cool = "I forgot my umbrella.",
			prickly = "The forecast said sun.|The forecast lied.",
			dramatic = "Trapped by the storm, {player}!",
			bookish = "Rain this heavy usually stops within half an hour.",
			gloomy = "Of course it's raining.|I only just washed my hair.",
			polite = "I do hope the baker doesn't mind me standing here.",
			foodie = "Since I'm here, I might as well get a bun.|It'd be rude not to.",
			nervous = "It'll stop, won't it?|When will it stop?",
			_ = "I forgot my umbrella again.",
		}, "sweat")
		s:choice("Share my umbrella?", function(c)
			c:prop("umbrella", "a")
			c:n("You walked {a} home under one umbrella, and you both got one wet shoulder each.")
			burst(c, "a", {
				polite = "Thank you so much.|Please, come in and dry off.",
				prickly = "...Thanks.|Your shoulder's soaked, honestly, so thanks.",
				_ = "Thanks, {player}.|Your side's all wet, look.",
			}, "heart")
			c:mood("a", 4)
			c:hearts("a", 1)
		end)
		s:choice("Run for it together?", function(c)
			c:n("You both ran, and you were both soaked by the end of the street.")
			burst(c, "a", {
				sunny = "Ehehe, we're SO wet!|That was fun, though!",
				gentle = "Oh, my, look at us.|Come in and dry off before you catch a cold, all right?",
				bold = "Hah, that was a proper sprint.",
				dreamy = "Hmm... I quite like being this wet, actually.",
				easygoing = "Well, I can't get any wetter now, heh.",
				proud = "I won, obviously.|...Don't look at my hair.",
				shy = "I'm soaked...|That was kind of fun, though.",
				cheeky = "you're wetter than me, so i win",
				cool = "Well, we're soaked.|It was worth it.",
				prickly = "I'm soaked through.|...Fine, that was fun.",
				dramatic = "We ran through the STORM together!",
				bookish = "Actually, running gets you about as wet as walking.|I'd like to test that again some time.",
				gloomy = "Soaked, as usual.|That was fun, though, heh.",
				polite = "Oh, dear, we're drenched.|Do come in and dry off.",
				foodie = "I need a hot drink and a bun right now.",
				nervous = "I nearly slipped twice!|...But we made it, we actually made it.",
				_ = "We're soaked!|That was fun, though.",
			}, "laugh", "laugh")
			c:mood("a", 3)
			c:memo("a", "Remember when we ran home in the rain? My boots still squelch.")
		end)
		s:log("{a} got caught in the rain.")
		return s:done()
	end,
})

event({
	id = "snowangel",
	when = "day",
	weight = W({ base = 0.2, weather = "snow" }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "In the snow")
		s:n("{a} is lying on their back in the snow, flapping their arms and legs.")
		burst(s, "a", {
			sunny = "I'm making snow angels!|Let's make a whole row of them together, {player}!",
			dreamy = "If I lie here long enough, I wonder if it'll snow on me...",
			bold = "That's six so far.|I'm doing the whole field.",
			easygoing = "I'm not getting up.|I live here now.",
			cool = "It's cold, but it's good.",
			prickly = "What?|It's snow, this is what you're supposed to do.",
			dramatic = "I am one with the winter!",
			gloomy = "I'll be cold for hours.|It's worth it, though.",
			nervous = "Is the snow deep enough for this?|I think I hit the ground a bit.",
			_ = "Come on, {player}, there's room for two.",
		}, "sparkle")
		s:mood("a", 4)
		s:log("{a} made snow angels.")
		return s:done()
	end,
})

event({
	id = "petals",
	when = "day",
	weight = W({ base = 0.18, weather = "blossom" }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "Petals")
		s:n("{a} has had pink petals stuck in their hair all morning, and nobody's said anything.")
		s:choice("You've got petals in your hair.", function(c)
			burst(c, "a", {
				shy = "Have they been there all morning?|Oh no, did everyone see?",
				proud = "I know.|I left them in, it's a look.",
				cheeky = "i know|i'm a tree now",
				cool = "Huh.|I'll leave them in.",
				prickly = "And nobody else said anything?|Thanks, {player}, and thanks a lot, everyone else.",
				dramatic = "I've been wearing spring all day!",
				nervous = "Have they been there all morning?|But I talked to the baker like this!",
				_ = "Oh, ha, how long have they been there?|Thanks, {player}.",
			}, "sweat")
			c:mood("a", 2)
		end)
		s:choice("(Say nothing, they suit them.)", function(c)
			c:n("{a} walked round all day with petals in their hair and was told three times that they looked nice.")
			c:mood("a", 5)
			c:memo("a", "Three people told me I looked nice yesterday, and I still don't know why.")
		end)
		s:log("{a} had petals in their hair all day.")
		return s:done()
	end,
})

makes({
	id = "townphoto",
	title = "A photo of town",
	item = "keep_photo",
	w = { base = 0.07, weather = { "clear", "cloudy", "blossom", "leaves" } },
	lines = {
		{ "n", "{a} went up the hill with a camera and took one photo of the whole town." },
		{ "a", "I only took the one.|I waited an hour for the light to be right.", "sparkle", "point" },
	},
	react = {
		sunny = "You can see your roof in it, {player}!|Look, right there!",
		cool = "It came out well.",
		bookish = "I'll write the date on the back.|It'll be history one day.",
		gloomy = "It looks nicer than I thought it would.|The town, I mean.",
		dramatic = "Our whole town, in one frame!",
		polite = "I had two copies made.|I hoped you might like one.",
		_ = "You can see the bakery and the gulls.|And there's your house, look.",
	},
	ask = "Can I have a copy?",
	memo = "That photo from the hill came out well. Did you put yours up?",
	log = "{a} took a photo of the whole town.",
})
event({
	id = "thunder",
	when = "night",
	weight = W({ base = 0.3, weather = "storm", traits = { brave = -0.4 } }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "Under the blanket")
		s:n("There's a storm overhead, and {a} is under a blanket with only their eyes showing.")
		burst(s, "a", {
			shy = "{player}...|It's very loud tonight, isn't it?",
			gentle = "I'm fine, really.|Is everyone else all right?",
			dreamy = "It sounds like someone's moving furniture up there...",
			cool = "Hm, that was a loud one.",
			prickly = "I'm not scared.|I'm cold, that's why the blanket.",
			dramatic = "The heavens are FURIOUS tonight!",
			gloomy = "The roof's going to leak.|I just know it will.",
			nervous = "W-was that close? It sounded really close.|Oh no, oh no, it was close.",
			bold = "I'm only under here because it's warm.|...That one was loud, though.",
			proud = "This blanket is for warmth, not for hiding.",
			easygoing = "Mm, I'm staying under here until it's over.",
			_ = "Is it going to get louder?|It's going to get louder, isn't it?",
		}, "sweat")
		s:choice("I'll sit with you.", function(c)
			c:n("You sat with {a} until the rain went soft, and they fell asleep sitting up.")
			c:mood("a", 5)
			c:hearts("a", 1)
			c:memo("a", "Thanks for sitting with me in the storm, {player}. I slept fine after that.")
		end)
		s:choice("Count the seconds with me.", function(c)
			c:n("There was a flash, then one, two, three, four, five, six, and a boom.")
			burst(c, "a", "Six seconds means it's further away, right?|Okay, it's moving off.", "heart")
			c:mood("a", 3)
		end)
		s:log("{a} sat out the storm under a blanket.")
		return s:done()
	end,
})

event({
	id = "firstloaf",
	when = "day",
	weight = W({ base = 0.12 }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "The first loaf")
		s:prop("bakes", "a")
		s:n("{a} baked bread for the first time, and it came out very heavy.")
		s:say("a", "{player}, knock on it for me.", "question")
		s:n("It went clonk.")
		burst(s, "a", {
			proud = "That's a dense loaf.|It's how they do it abroad, you know.",
			foodie = "It's a bit tough, but the flavour's there.|I'm sure the flavour's in there somewhere.",
			bold = "The next one will be perfect.|This one's a doorstop.",
			shy = "I followed the recipe, mostly...",
			cool = "It's a brick.",
			prickly = "It's bread, and it's perfectly fine, okay?",
			dramatic = "Six hours of my life, {player}, SIX!",
			bookish = "I think the yeast was old.|Or I was impatient, or both, actually.",
			gloomy = "I knew it would come out like this.",
			nervous = "Is it safe to eat?|It's safe, isn't it?",
			cheeky = "it's supposed to sound hollow|it does not sound hollow",
			_ = "It's supposed to sound hollow.|It does not sound hollow.",
		}, "sweat")
		s:choice("Butter, lots of butter.", function(c)
			c:n("You both had a slice with a lot of butter, and it took a while.")
			burst(c, "a", {
				cheeky = "not bad, just chewy|good exercise for the jaw, hehe",
				_ = "Not bad, just chewy.|It's good exercise for the jaw.",
			}, "heart")
			c:mood("a", 4)
			c:hearts("a", 1)
		end)
		s:choice("It'd make a good doorstop.", function(c)
			burst(c, "a", {
				cheeky = "rude|...but yes, it would",
				_ = "Ha, it'd be perfect for that, actually.",
			}, "laugh")
			c:mood("a", 1)
			c:memo("a", "My first loaf is holding my back door open, and it's doing a very good job.")
		end)
		s:log("{a} baked their first loaf.")
		return s:done()
	end,
})

local DOORS = { { "Yellow", "yellow" }, { "Green", "green" }, { "Sky blue", "sky blue" } }

event({
	id = "doorcolour",
	when = "day",
	weight = W({ base = 0.13 }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "Which colour")
		s:n("{a} is standing in front of their house with some pots of paint and a brush.")
		burst(s, "a", {
			sunny = "{player}, quick question!|What colour should my door be? I can't choose!",
			cool = "{player}.|You pick a colour for my door.",
			prickly = "I need a colour for my door.|Don't overthink it, just say one.",
			dramatic = "A door says who you are, {player}!|What should mine say?",
			bookish = "I've narrowed it down to two colours.|I can't get any further, so you choose.",
			nervous = "What colour should I paint it?|What if I pick wrong and I'm stuck with it for years?",
			polite = "Hello, {player}.|Might I ask your opinion on my door?",
			shy = "Um, {player}?|Which colour should I use for the door?",
			_ = "{player}, quick question.|What colour should my door be?",
		}, "question", "point")
		local pick = ctx.rng:shuffle(DOORS)
		for i = 1, 2 do
			local d = pick[i]
			s:choice(d[1] .. ".", function(c)
				c:with({ colour = d[2], Colour = d[1] })
				burst(c, "a", {
					proud = "Naturally, {colour} is the right choice.|I was about to say the same thing.",
					prickly = "{Colour}.|...Fine, yes, that's good.",
					gloomy = "{Colour}...|Okay, that might actually look nice.",
					cool = "{Colour} it is.",
					_ = "{Colour}, yes.|I'm starting now.",
				}, "sparkle", "cheer")
				c:mood("a", 4)
				c:memo("a", "My door's {colour} now, and you picked it, {player}. Come and look.")
			end)
		end
		s:log("{a} asked what colour to paint their door.")
		return s:done()
	end,
})

event({
	id = "thanknote",
	when = "day",
	weight = W({ base = 0.1, traits = { kind = 0.3 } }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "A note")
		s:n("There was a note under your door this morning, in {a}'s handwriting.")
		burst(s, "a", {
			sunny = "'{player}, thank you for everything! Come round for tea soon, and don't bring anything.'",
			gentle = "'Dear {player}, thank you for looking after us all. Come by whenever you can.'",
			bold = "'Thanks for the town. That's it, that's the note.'",
			dreamy = "'I saw a heron today and thought of you. Thank you for the town.'",
			easygoing = "'Thanks, {player}, I just wanted to say it.'",
			proud = "'You've done well with this place, {player}, and I've noticed.'",
			shy = "'Um, thank you for the house, and for everything. Sorry this is so short.'",
			cheeky = "'thanks for the town, this note will self destruct'|'it won't, but thanks anyway'",
			cool = "'Thanks. It's a good town.'",
			prickly = "'Thank you, and don't make it weird when you see me.'",
			dramatic = "'{player}, this town is a GIFT, and I had to write it down!'",
			bookish = "'I've been keeping a list of things I like about this town. You're on it, so thank you.'",
			gloomy = "'I didn't think I'd like it here, but I do. Thanks.'",
			polite = "'Dear {player}, thank you for all your hard work. With warm regards.'",
			foodie = "'Thank you for everything. I left a biscuit under this note for you.'",
			nervous = "'Thank you for everything, if that's okay to say.'",
			_ = "'Thank you for the town, {player}.'",
		}, "heart")
		s:choice("Pin it up by the door.", function(c)
			c:n("You pinned it up by the door, and {a} went pink when they saw it there later.")
			c:hearts("a", 1)
			c:mood("a", 4)
		end)
		s:choice("Write one back.", function(c)
			c:n("You wrote one back, and {a} read it twice on the doorstep.")
			burst(c, "a", {
				prickly = "...You wrote back, okay.|I'm keeping it, obviously.",
				cool = "I got your note.|...Thanks.",
				shy = "...!|I got your note, and it's on my fridge now.",
				_ = "I got your note, {player}.|It's on my fridge.",
			}, "heart")
			c:hearts("a", 1)
			c:mood("a", 6)
			c:memo("a", "I've still got your note, {player}, and it's on the fridge.")
		end)
		s:log("{a} left you a thank you note.")
		return s:done()
	end,
})

event({
	id = "boatsin",
	cutscene = "pier",
	when = "day",
	weight = W({
		base = 0.12,
		traits = { social = 0.2 },
		cond = function(ctx)
			return ctx.hour >= 15
		end,
	}),
	scene = function(ctx, a)
		local s = K.scene(ctx, "Boats coming in")
		s:n("{a} catches up with you on the street.")
		s:say("a", "{player}, are you busy?", "question", "wave")
		burst(s, "a", {
			sunny = "The boats come in at five!|Let's go and watch them together!",
			gentle = "The boats are coming in soon.|Would you walk down to the harbour with me?",
			bold = "The boats come in at five.|You're walking down with me, right?",
			dreamy = "The boats come in at five...|I like watching them find their way into the harbour.",
			cool = "The boats come in soon.|Do you want to watch?",
			prickly = "I'm going to watch the boats come in.|You can come if you want, whatever.",
			dramatic = "The fleet returns at five!|We simply must be there.",
			gloomy = "The boats are coming in soon.|It's the best bit of my day, so will you come?",
			foodie = "The fresh fish comes off the boats at five.|We could watch, and then eat.",
			nervous = "W-would you come and watch the boats with me?|You don't have to, only if you want.",
			_ = "The boats come in soon, so will you come and watch?",
		}, "idea")
		s:choice("Let's go.", function(c)
			c:n("You sat on the harbour wall with {a} while the boats came in one by one, each with gulls following.")
			burst(c, "a", {
				cool = "It's good, right?",
				prickly = "See, it was worth it.|...Thanks for coming.",
				gloomy = "That was nice.|I mean it.",
				_ = "My favourite one's the boat with the red sail.|Thanks for coming, {player}.",
			}, "heart")
			c:mood("a", 5)
			c:hearts("a", 1)
			c:memo("a", "Do you want to watch the boats again sometime? The red one's my favourite.")
		end)
		s:choice("Not today, sorry.", function(c)
			burst(c, "a", {
				shy = "Oh...|Of course, sorry for asking.",
				prickly = "Fine.|...Another time, then.",
				sunny = "Aw, okay!|Next time, then!",
				bold = "Fine, then I'll bring the boats to you.|...That was a joke.",
				_ = "Okay, another day, then.",
			}, "sad")
			c:mood("a", -2)
		end)
		s:default(2)
		s:log("{a} asked you to watch the boats come in.")
		return s:done()
	end,
})

event({
	id = "forgot",
	when = "day",
	weight = W({ base = 0.14, traits = { social = 0.3, focus = -0.2 } }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "Wait, what was it")
		s:n("{a} spotted you from across the square and ran all the way over.")
		s:say("a", "{player}, hi!", "wave")
		s:say("a", "...", "question")
		burst(s, "a", {
			sunny = "I had something to tell you, and now it's gone!|It was good news, too.",
			dreamy = "I ran so fast the thought fell out of my head...",
			cheeky = "i forgot, hehe|hi, though",
			cool = "I forgot what it was.|Hi anyway.",
			prickly = "Don't look at me like that.|It'll come back to me.",
			dramatic = "It was important, {player}, and now it's lost FOREVER!",
			bookish = "Did you know walking through a doorway makes you forget things?|There's a study on it, and there was a door.",
			gloomy = "I've forgotten what it was, as usual.",
			nervous = "Was it something bad?|I hope it wasn't something bad.",
			_ = "I've forgotten what I was going to say.",
		}, "sweat")
		s:n("They walked off, and ten steps later they turned round.")
		s:say("a", "The bakery has cheese scones today, that was it!", "idea", "point")
		s:mood("a", 3)
		s:log("{a} ran over to tell you about the scones.")
		return s:done()
	end,
})

-- the way a friend texts: a note meant for themselves, the ping and the wait, no reply, a picture
-- to delete, a secret to keep, home safe, a warning, a night thought (the user's reference chats)

event({
	id = "wrongtext",
	when = "day",
	weight = W({ base = 0.12, traits = { focus = -0.2 } }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "A list")
		s:n("{a} stops at your gate, reading out loud from a scrap of paper.")
		burst(s, "a", {
			cool = "Two boxes of nails, and green paint for the shed.|Remember to check the ladder.",
			polite = "Flour, eggs, and green paint for the shed.|And I must ask about borrowing a ladder.",
			cheeky = "eggs and green paint|and do NOT forget the ladder this time",
			_ = "Eggs, flour, and green paint for the shed.|Oh, and ask about the ladder.",
		}, "question")
		s:choice("Huh?", function(c)
			burst(c, "a", {
				cool = "Oh, that was meant for me.|...Can I borrow your ladder on Saturday?",
				gentle = "Oh, my, I was reading aloud again, sorry, {player}.|Since you're here, could I borrow your ladder?",
				easygoing = "Oh, ha, I was talking to myself again.|...You don't have a ladder, do you?",
				polite = "Oh, I do apologise, that was my shopping list.|While I'm here, might I borrow a ladder on Saturday?",
				prickly = "That wasn't for you.|...Okay, the last bit was, so can I borrow your ladder on Saturday?",
				_ = "Oh, that was my list.|...Since you're here, can I borrow your ladder?",
			}, "sweat")
			c:n("On Saturday the shed went green, and so did one of {a}'s elbows.")
		end)
		s:choice("Ask who about the ladder?", function(c)
			burst(c, "a", {
				shy = "Um...|You, actually, if that's okay.",
				cheeky = "you, obviously|i was going to ask nicely, i promise",
				dramatic = "You, {player}, it was always you!|The shed awaits us on Saturday.",
				_ = "Oh, you, actually.|Saturday, if you can spare it.",
			}, "sweat")
			c:n("On Saturday the shed went green, and so did one of {a}'s elbows.")
		end)
		s:mood("a", 4)
		s:hearts("a", 1)
		s:memo("a", "The shed's green now, so thanks for the ladder.")
		s:log("{a} asked to borrow your ladder.")
		return s:done()
	end,
})

event({
	id = "pingwait",
	when = "any",
	weight = W({ base = 0.1, traits = { social = -0.3 } }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "Nothing")
		s:say("a", "{player}.", "question")
		s:say("a", "{player}?", "question")
		burst(s, "a", {
			shy = "Um...|Never mind, it's nothing.",
			cool = "...",
			prickly = "Forget it.",
			nervous = "Sorry, it's not important, really.",
			gloomy = "...Never mind.",
			_ = "Never mind.",
		}, "sweat")
		s:n("You ask what it is.")
		burst(s, "a", {
			shy = "I sat on the bench you put by the pond this morning.|...It's a good bench, that's all.",
			cool = "The lamp by my door works again, since you fixed it.|...Thanks.",
			prickly = "It's nothing.|...Your garden looks nice, but don't let it go to your head.",
			gloomy = "I had a good day, and I wanted to tell someone.|You were the someone, heh.",
			nervous = "I wanted to say thank you for the house.|Sorry, that's all, sorry.",
			sunny = "Nothing, I just wanted to say hi!|Hi, ehehe!",
			dreamy = "The light on the water just now went all gold...|You missed it.",
			_ = "Nothing much, but the town looks nice today.|I wanted to say it to someone.",
		}, "heart")
		s:choice("Thanks for telling me.", function(c)
			burst(c, "a", {
				cool = "Okay.|Later.",
				prickly = "Yeah, well, bye.",
				polite = "Thank you for listening.|Have a lovely day, {player}.",
				proud = "Hmph, well, now you know.",
				_ = "Okay, bye, {player}.",
			}, "heart")
			c:hearts("a", 1)
		end)
		s:choice("Say that again?", function(c)
			burst(c, "a", {
				prickly = "No.|...Fine, it's nice, happy now?",
				shy = "...!|N-no, once was a lot.",
				cool = "No, once is enough.",
				proud = "Once is plenty, and you heard me the first time.",
				polite = "Oh, I'd rather not, but thank you for asking.",
				_ = "Once is enough, heh.",
			}, "sweat")
			c:mood("a", 3)
		end)
		s:log("{a} wanted to tell you something small.")
		return s:done()
	end,
})

event({
	id = "noreply",
	when = "day",
	weight = W({ base = 0.1, traits = { brave = -0.2 } }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "Hello?")
		s:n("{a} is calling up and down the street.")
		burst(s, "a", {
			gloomy = "{player}?|...|It's fine, everyone gets tired of me sooner or later.",
			nervous = "{player}, are you okay?|Did something happen? Should I go and get someone?",
			sunny = "{player}!|{player}, where are you? Hello?",
			shy = "{player}?|Sorry, it's nothing...",
			prickly = "{player}, hello?|Fine, ignore me, then.",
			bold = "{player}, where are you?|I'm coming to look for you.",
			_ = "{player}?|...Are you around?",
		}, "question")
		s:n("You were up on a roof the whole time, and you call down.")
		burst(s, "a", {
			gloomy = "Oh, right, a roof.|That makes sense, I thought you'd had enough of me.",
			nervous = "Oh, you're on a roof, okay, good.|Please be careful up there, sorry.",
			sunny = "You're on the ROOF, can I come up?|...I'll take that as a no, so maybe later!",
			shy = "Oh...|Sorry, I'll wait down here.",
			prickly = "A roof, of course.|...Come down for lunch, I made too much.",
			bold = "Hah, there you are.|I'll hold the ladder steady for you.",
			_ = "Oh, you're up there.|Okay, hi.",
		}, "sweat")
		s:mood("a", 2)
		s:log("{a} couldn't find you. You were on a roof.")
		return s:done()
	end,
})

event({
	id = "deletepic",
	when = "day",
	weight = W({ base = 0.1 }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "The photo")
		s:prop("camera", "a")
		s:n("{a} had a roll of photos printed, and one of them came through your door by mistake.")
		s:n("It shows {a} asleep on a bench with their mouth open.")
		burst(s, "a", {
			prickly = "{player}, about that photo.|Put it in the bin, now.",
			cool = "You've got a photo of mine.|Bin it, please.",
			shy = "Um, {player}...|I think one of my photos went to you by mistake, so please don't look at it.",
			proud = "I hear a photo of me is going round.|It is not my best angle, so return it at once.",
			cheeky = "that photo of me|it's art, but also give it back",
			dramatic = "There is a photograph of me ASLEEP, {player}!|Destroy it, I beg you.",
			_ = "{player}, there's a photo of me at yours.|Please don't look at it.",
		}, "sweat")
		s:choice("Already binned it.", function(c)
			burst(c, "a", {
				prickly = "Good.|...You looked, didn't you?",
				shy = "Oh, thank goodness.|Thank you.",
				proud = "Good, then we'll say no more about it.",
				_ = "Thank you.|...You looked, didn't you?",
			}, "heart")
			c:mood("a", 2)
		end)
		s:choice("It's a good one, though.", function(c)
			burst(c, "a", {
				prickly = "...|Fine, keep it, but show nobody.",
				shy = "...!|You really think so?|Okay, you can keep it, but only you.",
				proud = "Of course it's good, everything I do is good.|...Show nobody, though.",
				cool = "Keep it, then.|Show nobody.",
				cheeky = "i KNOW|frame it",
				_ = "It is not.|...Fine, keep it, but show nobody.",
			}, "sweat")
			c:mood("a", 3)
			c:hearts("a", 1)
			c:memo("a", "You still have that photo, don't you? Show nobody.")
		end)
		s:log("A photo of {a} asleep came to you by mistake.")
		return s:done()
	end,
})

event({
	id = "secretsafe",
	when = "day",
	weight = W({ base = 0.1, traits = { focus = -0.2 } }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "Splash")
		s:n("{a} slipped on the wet step by the fountain and sat right down in it, and you were the only one who saw.")
		burst(s, "a", {
			shy = "...|Please don't tell anyone, please.",
			proud = "That didn't happen, do you understand?|It did not happen.",
			easygoing = "Well, I needed a bath anyway.|...Don't tell anyone, though.",
			prickly = "Not one word.|Not a single word, got it?",
			cool = "You saw nothing.",
			dramatic = "My dignity, {player}, gone down the drain with the wishing coins!|Tell no one.",
			nervous = "Did anyone else see? Only you?|Okay, please don't tell anyone.",
			polite = "Oh, dear.|I'd be grateful if we kept that between us.",
			gloomy = "Of course I fell in.|You didn't see that, okay?",
			_ = "You didn't see that, okay?",
		}, "sweat")
		s:choice("Your secret's safe.", function(c)
			burst(c, "a", {
				shy = "Thank you...|I'm going home to change.",
				proud = "Good.|You've earned a little of my trust.",
				prickly = "Good.|...Thanks.",
				_ = "Thanks, I'm going home to dry off.",
			}, "heart")
			c:hearts("a", 1)
		end)
		s:choice("Find any coins in there?", function(c)
			burst(c, "a", {
				shy = "...!|Please don't tell anyone, please.",
				proud = "Th-that's not funny.|Anyway, I'm going home, so forget this.",
				prickly = "Seriously?|...Two, I found two, and don't tell anyone.",
				cheeky = "three, actually, and a button|don't tell anyone",
				_ = "...Two, actually.|Don't tell anyone.",
			}, "sweat")
			c:mood("a", 1)
			c:memo("a", "You never told anyone about the fountain, right? Right?")
		end)
		s:log("{a} sat down in the fountain by accident.")
		return s:done()
	end,
})

event({
	id = "homesafe",
	when = "night",
	weight = W({ base = 0.1, traits = { social = 0.2 } }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "Home")
		s:n("{a} gets back late and calls across the street before going in.")
		burst(s, "a", {
			sunny = "{player}, I'm home!|There was a dog in a hat on the last ferry!|Good night!",
			gentle = "I'm home, {player}.|The path by the harbour was slippery, so mind it tomorrow, okay?|Sleep well.",
			bold = "I'm home, and I walked the cliff path in the dark.|Night.",
			dreamy = "I'm home...|The moon followed me the whole way.",
			easygoing = "I'm home, I took the long way on purpose.|Night.",
			proud = "Home safe, {player}.|Three people said they liked my hat today, good night.",
			shy = "I'm home.|The square was loud today, but it was okay.",
			cheeky = "home|i took a lemon off the tree by the market, don't tell|night",
			cool = "I'm home.|Night.",
			prickly = "I'm home, in case you were wondering.|...Not that you were, but good night.",
			dramatic = "I have returned, and the harbour lights were magnificent tonight!|Farewell until morning.",
			bookish = "I'm home, and I saw a grey heron on the way.|Good night, {player}.",
			gloomy = "I'm home, and nothing went wrong today.|That's weird, heh.",
			polite = "Good night, {player}, I'm home safe.|Thank you for today.",
			foodie = "I'm home, and I had two pies at the harbour.|They were worth it, night.",
			nervous = "I'm home, and I checked the door twice.|Good night, sorry, good night.",
			_ = "I'm home, {player}.|Night.",
		}, "zzz", "wave")
		s:say("a", "{player}.", "heart")
		-- (most of them said good night already)
		s:by("a", {
			dreamy = "...That's all, good night.",
			shy = "...That's all, good night.",
			gloomy = "...That's all, good night.",
			cheeky = "...that's all, night again",
			_ = "...That's all, I just wanted to say good night again.",
		}, "heart")
		s:mood("a", 2)
		s:hearts("a", 1)
		s:log("{a} called goodnight on the way in.")
		return s:done()
	end,
})

-- (none of them names a time, since the day could be anywhere from breakfast to dusk)
local WARNINGS = {
	wet = {
		{ "The rain's going to get heavier.", "Take the long coat." },
		{ "The harbour steps flood at high tide.", "Use the top path." },
	},
	snow = { { "It's icy outside the bakery.", "Walk on the grass side." } },
	hot = { { "The sun's really strong today.", "Wear a hat." } },
	any = {
		{ "The bakery's shutting early today.", "Get your bread while you can." },
		{ "The gulls are bold today.", "Keep your snacks out of sight." },
	},
}

event({
	id = "warning",
	when = "day",
	weight = W({ base = 0.12, pers = { "cool", "gentle", "bold", "polite", "nervous", "prickly" } }),
	scene = function(ctx, a)
		local kind = if ctx.weather == "rain" or ctx.weather == "storm"
			then "wet"
			elseif ctx.weather == "snow" then "snow"
			elseif ctx.season == 2 and ctx.weather == "clear" then "hot"
			else "any"
		local w = ctx.rng:pick(WARNINGS[kind])
		local s = K.scene(ctx, "Heads up"):with({ what = w[1], todo = w[2] })
		burst(s, "a", {
			cool = "{player}.|{what}|{todo}|Later.",
			gentle = "Oh, {player}, there you are.|{what} {todo}|Take care of yourself, all right?",
			bold = "{player}, listen.|{what} {todo}",
			polite = "Excuse me, {player}, and forgive the interruption.|{what} {todo}|Do take care today.",
			nervous = "S-sorry, {player}, it's just a quick thing.|{what} {todo}|That's all, sorry.",
			prickly = "{player}.|{what} {todo}|Don't make me say it twice.",
			_ = "{player}.|{what} {todo}",
		}, "idea")
		s:hearts("a", 1)
		s:log("{a} gave you a heads up about the day.")
		return s:done()
	end,
})

event({
	id = "nightthought",
	when = "night",
	weight = W({ base = 0.1, traits = { focus = -0.2 } }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "Late")
		s:n("It's late, and {a} is sitting on their step, looking up.")
		burst(s, "a", {
			dreamy = "Do you think the bakery oven gets lonely at night?|It stays warm for hours after everyone goes home...|Maybe that's why the bread is so good.",
			gloomy = "Do you ever think about how far away the stars are?|They're not thinking about us at all, heh.|...Sorry, it's a night thought.",
			easygoing = "The sea's louder at night, have you noticed?|Or maybe everything else is just quieter, and either way it's nice.",
			bookish = "Did you know some of those stars might not be there anymore?|Their light has been travelling for ages, and I find that oddly calming.",
			shy = "{player}, sorry, are you awake?|The square looks nice with nobody in it.",
			cool = "{player}.|It's quiet tonight, and that's good.",
			sunny = "{player}, you're up too!|Look how many stars there are, I've counted thirty already!",
			proud = "I've decided which star is mine, that bright one there.|You can have the one next to it.",
			prickly = "I can't sleep, so don't ask why.|...The sky's nice, though.",
			nervous = "Do you think all the boats are in?|I counted them, and I think they're all in, okay.",
			polite = "Good evening, {player}, I hope I'm not keeping you.|It's such a clear night.",
			foodie = "If the moon were a cheese, what cheese would it be?|I've been thinking about it for an hour.",
			dramatic = "Look at the night, {player}!|It's really showing off.",
			gentle = "Oh, {player}, are you still up?|The air's so soft tonight.",
			cheeky = "look at the moon|it looks like it's judging the gulls",
			bold = "I can't sleep, so I've walked the whole harbour twice.|You're up too, right? Come for a walk.",
			_ = "It's funny how quiet it gets at night.|You can hear the boats knocking together.",
		}, "zzz")
		s:choice("Go to bed, you.", function(c)
			burst(c, "a", {
				prickly = "You first.|...Fine, night.",
				cool = "Okay.|You too.",
				_ = "Okay, you too.|Night, {player}.",
			}, "zzz")
			c:mood("a", 2)
		end)
		s:choice("What else are you thinking?", function(c)
			burst(c, "a", {
				gloomy = "That I'd miss this place if I ever had to leave.|...Forget I said that, good night.",
				shy = "That I like it here...|That's all, forget I said it, good night.",
				prickly = "Nothing.|...That this town's all right, but don't repeat that.",
				dreamy = "Whether the fish are asleep...|They'd have to be, wouldn't they? Night.",
				sunny = "That tomorrow's going to be a good day!|I can tell, good night!",
				_ = "That I like it here.|...Forget I said that, good night.",
			}, "heart")
			c:hearts("a", 1)
			c:memo("a", "Did I say anything odd the other night? Don't answer that.")
		end)
		s:log("{a} sat up late looking at the sky.")
		return s:done()
	end,
})

event({
	id = "bighaul",
	when = "day",
	weight = W({ base = 0.1, season = { 2, 3 } }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "A carrot")
		s:n("{a} comes up the street holding something behind their back.")
		burst(s, "a", {
			dramatic = "{player}, behold the biggest carrot this island has ever grown!|...It's about the size of my thumb.|But it's a very GOOD thumb.",
			sunny = "{player}, look at my carrot, it's THIS big!|...Okay, it's small, but it's mine!",
			nervous = "I grew a carrot, but it's tiny.|Is it meant to be this tiny?",
			foodie = "This is the first carrot from my patch, and it's small.|Small ones are sweeter, everyone knows that.",
			proud = "My first carrot, perfectly formed.|Small, but perfect.",
			cheeky = "close your eyes|ok, open them|it's a carrot, a baby one",
			_ = "My first carrot is small.|It's still a carrot, though.",
		}, "sparkle", "point")
		s:choice("Best carrot I've seen.", function(c)
			burst(c, "a", {
				dramatic = "Thank you, finally someone with eyes!",
				sunny = "I KNOW!|I'm going to grow a hundred more!",
				nervous = "Really? Oh, okay, thank you.|Maybe I'll grow a bigger one next time.",
				proud = "I know.|Say it again, a little louder.",
				_ = "Right? I'm going to frame it.|Then I'm going to eat it.",
			}, "heart", "cheer")
			c:mood("a", 5)
			c:hearts("a", 1)
		end)
		s:choice("Is it finished growing?", function(c)
			burst(c, "a", {
				dramatic = "It is FINISHED!|It simply chose to stay humble.",
				foodie = "It's finished, it's a snack carrot.|That's a real thing, I promise.",
				proud = "Th-that's the size they come!|Anyway, next year I'm growing a marrow.",
				_ = "It's finished, it just didn't try very hard.|It's like me on a Monday.",
			}, "sweat")
			c:mood("a", 1)
		end)
		s:log("{a} grew a very small carrot.")
		return s:done()
	end,
})

event({
	id = "cartwheel",
	when = "day",
	weight = W({ base = 0.1, traits = { brave = 0.2 }, weather = { "clear", "cloudy", "blossom", "leaves" } }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "Watch this")
		s:n("{a} waves you over to the grass by the square.")
		burst(s, "a", {
			sunny = "{player}, {player}, watch this!|I learned it this morning!",
			proud = "{player}, watch closely.|You'll want to remember this.",
			bold = "Watch this cartwheel, {player}.|You're watching, right?",
			shy = "Um, {player}?|Could you watch me, just once? Don't laugh...",
			dramatic = "Ladies, gentlemen and gulls, I give you THE CARTWHEEL!",
			cheeky = "watch this|no, really, watch",
			cool = "{player}.|Watch this.",
			nervous = "O-okay, I'm going to try a cartwheel.|Stand back, further than that.",
			_ = "{player}, watch this.|I've learned how to do a cartwheel.",
		}, "idea", "point")
		if ctx.rng:chance(0.55) then
			s:n("It was a perfect cartwheel, and then another one for luck.")
			burst(s, "a", BRAG, "sparkle", "cheer")
		else
			s:n("It was half a cartwheel, and then a sit down on the grass.")
			burst(s, "a", {
				proud = "Th-that was only the warm up.",
				prickly = "That didn't count.|The grass moved.",
				gloomy = "Yeah, that's about as far as I got this morning too.",
				cool = "That was halfway.",
				_ = "That was half of one, and halves count.",
			}, "sweat")
		end
		s:choice("Do it again.", function(c)
			burst(c, "a", {
				proud = "Naturally.|Count them this time.",
				shy = "...!|Okay, once more.",
				sunny = "Okay, one more time!",
				_ = "Okay, one more.",
			}, "sparkle", "cheer")
			c:mood("a", 4)
		end)
		s:choice("Teach me?", function(c)
			c:n("Ten minutes later you were both lying on the grass, out of breath and laughing.")
			c:mood("a", 5)
			c:hearts("a", 1)
			c:memo("a", "You're getting better at cartwheels, {player}, a bit.")
		end)
		s:log("{a} showed you a cartwheel.")
		return s:done()
	end,
})

event({
	id = "campfire",
	when = "night",
	weight = W({ base = 0.1, weather = { "clear", "cloudy", "leaves" } }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "A fire on the beach")
		s:prop("campfire", "a")
		s:n("There's a little fire going on the beach, and {a} is sitting by it with a stick and a paper bag.")
		burst(s, "a", {
			bold = "{player}, over here.|The fire's going, so sit down.",
			gentle = "Come and get warm, {player}.|There's room on the log.",
			sunny = "{player}, come sit by the fire!|I've got marshmallows!",
			dreamy = "The sparks go up like they're joining the stars...|Will you sit?",
			easygoing = "Pull up a log.|I've been here two hours, and it's great.",
			proud = "I built this fire myself, with the very first match.|Sit down and admire it.",
			shy = "Oh, {player}...|Um, do you want to sit? You don't have to.",
			cheeky = "marshmallow?|i've only burned six",
			cool = "There's a fire.|Sit down if you want.",
			prickly = "You're letting the cold in, standing there.|Just sit down.",
			dramatic = "The fire calls to us, {player}!|Sit, and listen to it crackle.",
			bookish = "Driftwood sometimes burns blue.|It's the salt, so sit and watch for it.",
			gloomy = "It'll go out eventually.|Will you sit with me until it does?",
			polite = "Good evening, {player}.|Would you care to join me by the fire?",
			foodie = "I've got bread on a stick.|Well, it's toast on a stick now, do you want one?",
			nervous = "Is it too big?|No, it's not too big, I checked, so sit if you want.",
			_ = "Sit for a bit, {player}, it's warm.",
		}, "heart", "wave")
		s:choice("Budge up.", function(c)
			c:n("You sat by the fire with {a} until it was only embers, and neither of you said much.")
			burst(c, "a", {
				cool = "It was a good night for it.",
				prickly = "That was all right.|...Same time next week.",
				_ = "We should do that again.",
			}, "heart")
			c:mood("a", 5)
			c:hearts("a", 1)
			c:memo("a", "We should do the fire on the beach again, {player}.")
		end)
		s:choice("Just for a minute.", function(c)
			burst(c, "a", "A minute's fine.|...That was a lot more than a minute, heh.", "music")
			c:mood("a", 3)
		end)
		s:log("{a} sat by a fire on the beach.")
		return s:done()
	end,
})

event({
	id = "lostnotebook",
	when = "day",
	weight = W({ base = 0.1, traits = { focus = -0.3 } }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "The notebook")
		s:n("{a} comes to your door, patting their pockets.")
		burst(s, "a", {
			polite = "Excuse me, {player}, I'm sorry to bother you.|Did I leave a little green notebook here?",
			nervous = "S-sorry, {player}, did I leave my notebook here?|It's small and green and full of lists, sorry.",
			bookish = "{player}, have you seen my notebook?|Every bird I've seen this year is in it, all two hundred and six.",
			dramatic = "{player}, my whole life is in that notebook!|Have you seen it?",
			_ = "{player}, did I leave my notebook here?|It's green, about this big.",
		}, "question")
		s:choice("Let's look round.", function(c)
			c:n("You both looked under every cushion. Then {a} sat down, and something crackled.")
			burst(c, "a", "Oh, it was in my back pocket.|It was there the whole time.", "sweat")
			c:mood("a", 2)
			c:hearts("a", 1)
		end)
		s:choice("Is that it, under your arm?", function(c)
			burst(c, "a", {
				polite = "...|So it is, I do apologise, I'll see myself out.",
				dramatic = "...|We will never speak of this.",
				_ = "...|Yes, it is, and I'm going home now.",
			}, "sweat", "laugh")
			c:mood("a", 1)
		end)
		s:log("{a} lost a notebook that wasn't lost.")
		return s:done()
	end,
})

return list
