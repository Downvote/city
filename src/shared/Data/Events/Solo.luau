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
local Memory = require(script.Parent.Parent.Parent.Sim.Memory)

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
	sunny = "Wait, wait, did you see that?|It actually worked, ehehe.",
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
	dreamy = "Hmm... it worked.|La la ♪, I think it just wanted to work today.",
	easygoing = "Mm, that went well, and I barely even tried.",
	polite = "Oh, how wonderful.|Thank you kindly for watching.",
	foodie = "That calls for a bun to celebrate.|Maybe two, if the bakery's still open.",
	nervous = "I-it worked?|Oh, thank goodness, I was so sure it wouldn't.",
	_ = "It actually worked.|I wasn't sure it would.",
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
					sunny = "You really want it?|Here, here, take it, and put it somewhere I can see it when I come over.",
					cool = "Sure, it's yours.|...I'm glad you like it.",
					prickly = "Ugh, fine, take it before I change my mind.|And don't let it get dusty, okay?",
					dramatic = "Then it is DECIDED, it goes home with the {player}!|Treat it like the treasure it is.",
					bookish = "Of course you can.|Actually, if you keep it out of the sun, it should last for years.",
					gloomy = "You actually want it?|Heh... okay, that's really nice of you.",
					polite = "I would be honoured, {player}.|Thank you kindly for asking.",
					foodie = "Sure, it's yours.|Bring me a cookie sometime and we'll call it even.",
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
					dramatic = "Then it STAYS with its maker, as it should!",
					gloomy = "Okay, somebody should keep it.|It might as well be me.",
					polite = "Thank you, I will take very good care of it.",
					nervous = "Oh, phew.|I'd have worried about it the whole time it was away.",
					sunny = "Okay, then it's going right on my windowsill.|Come and visit it whenever you like.",
					gentle = "All right, I'll keep it safe.|You can come and see it any time, okay?",
					bold = "Fine, it stays here.|You can come and look at it, right?",
					easygoing = "Sure, it can sit on my shelf and take it easy.",
					bookish = "All right, I'll keep it.|I'll put a little label on it with today's date.",
					foodie = "Okay, it can go on the kitchen shelf, next to the cookie jar.",
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
			polite = "Hello, {player}, and please excuse me.|I have had the hiccups since breakfast.",
			foodie = "I ate my breakfast far too fast this morning.|It was worth it, though, because it had honey in it.",
			nervous = "W-what if these hiccups never stop?|Is that something that can actually happen to people?",
			gentle = "Oh my, I've had the hiccups since breakfast.|Don't worry about me, okay? Hic.",
			easygoing = "I've had the hiccups since breakfast.|Eh, I'm just going to wait them out, hic.",
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
				dramatic = "My HEART.|...Wait, my hiccups are gone.",
				nervous = "Aah, my heart's racing!|...Wait, are they gone?",
				cheeky = "aah, rude|...oh, they've stopped, hehe",
				sunny = "Waah.|...Oh, they're gone, ehehe, thank you.",
				gentle = "Oh my!|...Oh, they've stopped, thank you.",
				dreamy = "Oh... you scared me.|And the hiccups floated away.",
				proud = "Th-that didn't scare me at all.|...But they're gone, so thank you.",
				bookish = "Aah!|...Oh, it actually worked, and I read that it doesn't.",
				gloomy = "Heh... you got me.|And they're gone, which never happens.",
				polite = "Oh my goodness!|...Oh, they have stopped, thank you.",
				foodie = "Aah, I nearly dropped my snack!|...Oh, they've stopped.",
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
			sunny = "{player}, {player}, guess what.|I've decided to take up {hobby}.",
			bold = "{player}, I've made up my mind.|I'm taking up {hobby}, starting today.",
			shy = "Um, {player}...|I've been thinking that maybe I'd like to try {hobby}.",
			cheeky = "guess what|actually don't guess, i'm taking up {hobby}",
			cool = "{player}.|I'm going to take up {hobby}.",
			dramatic = "{player}, today a new chapter of my life begins.|It's the chapter of {hobby}.",
			polite = "Excuse me, {player}, if you have a moment.|I have decided to take up {hobby}.",
			gentle = "{player}, I've decided to try something new.|I'm going to take up {hobby}.",
			dreamy = "Hmm... {player}, I think I'd like to try {hobby}.",
			easygoing = "{player}, I'm going to take up {hobby}, I think.",
			proud = "{player}, I've chosen a new hobby.|It's {hobby}, and it's lucky to have me.",
			prickly = "{player}, I'm taking up {hobby}, starting today.",
			bookish = "{player}, I've made a decision.|I'm going to take up {hobby}.",
			gloomy = "{player}, I've decided to try {hobby}.",
			foodie = "{player}, after lunch today, I'm taking up {hobby}.",
			nervous = "{player}, I've decided to try {hobby}.|I'm a little scared, but I've decided.",
			_ = "{player}, I've decided something.|I'm going to take up {hobby}.",
		}, "idea", "point")
		burst(s, "a", {
			bold = "There's no point waiting around.|You're coming to watch me try, right?",
			shy = "Is that a silly idea?|You don't have to answer that.",
			cheeky = "don't laugh|i can tell you're about to laugh",
			sunny = "I already told everyone at the market, so now I have to do it.",
			easygoing = "It seems relaxing, and I'm hoping it's mostly sitting down.",
			dreamy = "The idea came to me in a dream...|Well, during a nap, but I think that counts.",
			proud = "Naturally, I expect I'll be good at it.|Most things come easily to me, after all.",
			cool = "It seemed worth a try.",
			prickly = "Don't make a big thing out of it, okay?",
			dramatic = "I've already bought a special hat for it.",
			bookish = "I've read two books about it already.|Now I just have to actually do it.",
			gloomy = "I'll probably be terrible at it.|I want to try anyway, though.",
			polite = "If you have any tips, I would be very grateful to hear them.",
			foodie = "Is there a snack that goes with it?|There really should be one.",
			nervous = "W-what if I turn out to be terrible at it?|Please tell me if I am, but gently.",
			gentle = "I'd love for you to come and watch me sometime, if you're free.",
			_ = "I've already bought everything I need for it.|Please don't tell me it's silly.",
		}, "sparkle")
		s:choice("Go for it.", function(c)
			burst(c, "a", {
				easygoing = "Right, I'll start after a little nap.",
				shy = "...!|Okay, I'll give it a try.",
				proud = "I intend to.|Watch me be good at it right from the start.",
				prickly = "I was going to anyway.|...But thanks.",
				nervous = "O-okay, I'm really going for it.|Wish me luck!",
				gloomy = "Okay... if you think so, {player}, I'll give it a go.",
				sunny = "Ehehe, I knew you'd say that.|I'm starting right now.",
				gentle = "Thank you, {player}.|I'll take it slowly, okay?",
				bold = "Hah, I knew you'd say that.|Watch me.",
				dreamy = "Okay... I'll start when the light is nice.",
				cheeky = "ok, but if i'm bad at it, it's your fault",
				cool = "Okay, starting today.",
				dramatic = "Then my new LIFE begins today!",
				bookish = "Thank you, I'll start with the basics, chapter one.",
				polite = "Thank you, {player}, I will do my best.",
				foodie = "Okay, right after lunch, then.",
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
				sunny = "Aw, but this one's different.|...Okay, maybe it isn't.",
				gentle = "Oh, you're right.|But I really think I'll stick with this one, okay?",
				dreamy = "Hmm... was it?|I forget the others.",
				easygoing = "Eh, fair, but this one has more sitting down.",
				prickly = "Ugh, you counted?|...Fine, it is.",
				bookish = "Actually, it's my fourth, I keep a list.|But point taken.",
				polite = "I suppose that is true.|Perhaps I will think it over.",
				foodie = "Okay, but the others didn't have snacks.|This one might.",
				nervous = "Oh no, is it? Is that bad?|Maybe I'll stick with this one, then.",
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
		s:n("{a} is wearing one blue sock and one striped one.")
		burst(s, "a", "My other blue sock has gone missing.|I've looked everywhere, even in the fridge.", "question")
		burst(s, "a", {
			proud = "So I've decided odd socks are the new fashion.|You saw it here first.",
			dreamy = "Maybe it went off on a little trip...|I hope it's having a nice time.",
			cheeky = "someone in this town is stealing socks|and i'm going to find out who",
			gentle = "Oh well, this stripy one keeps my foot just as warm.",
			sunny = "Have you seen it anywhere, {player}?|It's blue and a bit sad looking.",
			cool = "It'll turn up eventually.",
			prickly = "Whatever, nobody looks at socks anyway.",
			dramatic = "It left without a single word.|After all the miles we walked together.",
			bookish = "Did you know people lose about one sock a month?|I looked it up after I lost the third one.",
			gloomy = "Things always go missing, that's just what they do.|Especially my things.",
			foodie = "I don't know why I checked the fridge.|I did have a snack while I was in there, though.",
			nervous = "What if it ended up in someone else's laundry?|That would be so awkward to ask about.",
			bold = "I'm wearing odd socks today, and I'm fine with it, right?",
			easygoing = "Eh, odd socks are fine, nobody's checking.",
			shy = "Um... please don't look at my feet.|I lost the other one.",
			polite = "I do apologise for the odd socks.|The other one has gone missing.",
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
			dramatic = "This tune HAUNTS me, {player}, day and night.",
			easygoing = "It's been going around in my head since breakfast.|I've given up fighting it, honestly.",
			sunny = "{player}, I've been humming this all day!|Hum it with me, hum it.",
			gentle = "Oh my, I can't stop humming it.|I hope it's not bothering you.",
			bold = "This tune won't leave my head.|I'm going to hum it until it gives up.",
			dreamy = "La la ♪... I've had this tune since I woke up.|It's a nice one, though.",
			proud = "I've been humming this all day.|It's catchy because I hum it so well.",
			shy = "Um... sorry, I keep humming.|I can't help it.",
			cheeky = "dum da dum dum|you're going to have it stuck too now, hehe",
			bookish = "Did you know a song gets stuck when you only remember part of it?|I only know these four notes.",
			gloomy = "This tune has been stuck in my head all day.|It'll probably be there forever.",
			polite = "Please excuse my humming, {player}.|I cannot seem to stop.",
			foodie = "I've been humming it since breakfast.|It's the song from the bakery radio.",
			_ = "{player}, I can't get this tune out of my head.|Please make it stop.",
		}, "sweat")
		s:choice("Dum da dum DUM.", function(c)
			burst(c, "a", {
				cheeky = "oh, harmonies now?|hehe, we're a band",
				sunny = "Ehehe, now we've both got it.",
				cool = "Hm.|That wasn't bad, actually.",
				prickly = "Great, now it's stuck in both our heads.|Thanks a lot.",
				polite = "Oh dear, now you have caught it too.|I am so sorry, {player}.",
				gentle = "Oh, you know it too.|That's sweet.",
				bold = "Hah, now you've got it too, right?",
				dreamy = "La la ♪... we sound nice together.",
				easygoing = "Heh, now it's stuck in two heads, that's fair.",
				proud = "Not bad, but I hum it better.",
				shy = "Oh... you hummed it too.|Hee.",
				dramatic = "A DUET!",
				bookish = "You got the last note a little flat, actually.|But that was fun.",
				gloomy = "Great, now you're stuck with it too.|Heh... sorry.",
				foodie = "Now we need a snack to get it out of our heads.",
				nervous = "Oh no, now you've got it too.|I'm so sorry.",
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
		local s = K.scene(ctx, "The big pumpkin")
		s:prop("marrow", "a")
		s:n("{a} has been growing a pumpkin behind the house, and it's about the size of a wheelbarrow now.")
		burst(s, "a", {
			proud = "{player}, have you seen my pumpkin yet?|I measured it, and it's the biggest in town by far.|Go on, try and find a bigger one.",
			gentle = "I've been singing to it every morning.|I think it might actually be helping, don't you?",
			bold = "I tried to lift it this morning and couldn't.|You'll help me get it off the ground on Friday, right?",
			shy = "Um...|I didn't mean for it to get this big, honestly.",
			easygoing = "I just kept watering it, and it kept growing, heh.|At this point I'm too scared to stop.",
			sunny = "Look, look, {player}!|It's so big I can't get my arms around it now.",
			cool = "Hm, it's gotten very big.|I'm still deciding what to do with it.",
			prickly = "Don't touch it.|...Fine, you can pat it once.",
			dramatic = "Look at it, the PRIDE of the whole island!",
			bookish = "Did you know a pumpkin is a fruit?|This is a very, very large fruit.",
			gloomy = "Something's going to eat it before I can pick it, you watch.|Heh... things like that always happen to me.",
			foodie = "I'm torn between making soup and stuffing it.|Maybe I'll do both, there's enough of it.",
			nervous = "W-what if it never stops growing?|Where would I even put it?",
			dreamy = "Hmm... it got bigger overnight again.|I think it likes the moonlight.",
			cheeky = "it's bigger than me now|i'm going to give it a name",
			polite = "Good morning, {player}.|I am afraid my pumpkin has got rather large.",
			_ = "I don't know what to do with it, {player}.|I only wanted to see how big it would get.",
		}, "sparkle", "point")
		s:choice("Keep watering it.", function(c)
			burst(c, "a", {
				proud = "Exactly.|It can get even bigger, I know it can.",
				dreamy = "Hmm... grow, little pumpkin, grow.",
				sunny = "Yes, yes, let's make it the biggest ever.",
				gentle = "All right, I'll keep looking after it.|Grow nice and slowly, okay?",
				bold = "Right, more water.|Let's see how big it gets, right?",
				easygoing = "Sure, watering is easy, I can do that lying down.",
				shy = "Okay... I'll keep watering it.",
				cheeky = "more water|we're making a monster, hehe",
				cool = "More water, then.",
				prickly = "Fine, but if it takes over the garden, that's your fault.",
				dramatic = "It will be the BIGGEST pumpkin the world has ever seen.",
				bookish = "It grows about two centimetres a day, actually.|I've been measuring.",
				gloomy = "Okay.|Something will probably eat it, though.",
				polite = "Very well, I will keep watering it.",
				foodie = "Okay, the bigger it gets, the more pie we'll have.",
				nervous = "What if it gets too big?|Okay, okay, a little more water.",
				_ = "More water it is, then.|Let's see how far it goes.",
			}, "sparkle", "cheer")
			c:leave("marrow", 18, "a")
			c:mood("a", 5)
			c:memo("a", "The pumpkin's still growing, and I've had to move the fence for it.")
		end)
		s:choice("Soup for the whole street?", function(c)
			burst(c, "a", {
				foodie = "Yes, yes, I'll get the big pot out!|And bread, we'll need lots of bread.",
				gloomy = "Soup, okay.|At least nothing can eat it before I do now.",
				sunny = "Soup, soup, soup for everyone.|Let's get the big pot.",
				gentle = "Oh, what a nice idea.|Everyone can have a warm bowl, okay?",
				bold = "Soup for the whole street, I like it.|Big pot, right now.",
				dreamy = "Hmm... pumpkin soup on a cold evening.|That sounds nice.",
				easygoing = "Soup's easy, and everybody's happy, sure.",
				proud = "My pumpkin soup will be the best soup on the street, naturally.",
				shy = "Um... okay.|I hope everyone likes it.",
				cheeky = "soup for everyone|you're doing the chopping, though",
				cool = "Soup it is. I'll get a pot.",
				prickly = "Fine, soup.|But I'm keeping one slice for myself.",
				dramatic = "A FEAST for the whole street!",
				bookish = "One pumpkin like this makes about forty bowls, actually.",
				polite = "What a kind idea.|I will invite everyone on the street.",
				nervous = "Soup for everyone?|What if it's not enough? Okay, I'll make two pots.",
				_ = "Soup for everyone, then.|I'll need to borrow the big pot.",
			}, "heart")
			c:all(3)
			c:mood("a", 3)
			c:memo("a", "Everybody had pumpkin soup, and there's still half a pumpkin left.")
		end)
		s:log("{a} grew an enormous pumpkin.")
		return s:done()
	end,
})

makes({
	id = "marrowshow",
	title = "The pumpkin show",
	item = "keep_trophy",
	w = { base = 0.08, season = { 2, 3 } },
	lines = {
		{ "n", "{a} took a pumpkin to the show on the next island and came back with a little silver cup." },
		{ "a", "{player}, I came second at the pumpkin show.", "sparkle" },
		{ "a", "The winner's pumpkin was wearing a tiny hat.|I'm pretty sure that's why it won.", "sweat" },
	},
	react = {
		proud = "Hmph, second is just the first of the losers.|I'll be back next year to win it properly.",
		easygoing = "Second's great, honestly.|There's a lot less pressure than first.",
		shy = "I nearly didn't go at all...|I'm really glad I did, though.",
		bold = "Next year I'm winning it, hat or no hat.",
		cool = "Second's fine by me.",
		prickly = "Whatever, I'll take second.|I'm not bitter, so stop looking at me like that.",
		dramatic = "I was ROBBED, {player}, robbed by a hat.",
		gloomy = "I was expecting last place.|So this feels like a lot, honestly.",
		polite = "The judges were very kind.|I have already sent them a thank you note.",
		nervous = "My hands were shaking the whole time.|But I still came second!",
		sunny = "Second, second, I came second.|Next year let's go together.",
		gentle = "I'm so happy with second.|Everyone there was so kind.",
		dreamy = "Hmm... a little silver cup.|It catches the light so nicely.",
		cheeky = "second place|first place had a hat, so it doesn't count",
		bookish = "There were fourteen pumpkins, and I came second.|That's very good, actually.",
		foodie = "Second place, and I got to try every pie at the show.",
		_ = "I'll happily take second.",
	},
	ask = "Can it go on my shelf?",
	keep = "You earned it, so keep it.",
	memo = "I came second at the pumpkin show, so next year I'm bringing a hat.",
	log = "{a} came second at the pumpkin show.",
})

-- a bad haircut --------------------------------------------------------------------------------------

event({
	id = "haircut",
	when = "day",
	weight = W({ base = 0.2, traits = { focus = -0.2 } }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "New bangs")
		s:n("{a} cut their own bangs this morning, and they came out a bit crooked.")
		burst(s, "a", {
			shy = "Um, please don't look at me...|I tried to cut my own bangs.",
			proud = "Hmph, it's meant to look like this.|It's a style, you can look it up.",
			cheeky = "i meant to do that|the left side, anyway",
			easygoing = "Eh, it'll grow back.|Everything does, eventually.",
			bold = "Hah, I cut it myself this morning and went a bit too far.",
			dreamy = "I was thinking about clouds while I cut it...|Maybe that was the problem.",
			sunny = "{player}, be honest with me.|Wait, no, be nice instead.",
			cool = "Hm, I cut it myself.|It didn't go to plan, as you can see.",
			prickly = "Go on, say something about it.|...Actually, don't.",
			dramatic = "It's a DISASTER.|I can never show my face in the square again.",
			bookish = "Hair grows about a centimetre a month.|So this will take roughly four months to fix.",
			gloomy = "Heh... it was always going to end up like this.",
			polite = "I am so sorry you have to look at this, {player}.",
			nervous = "Is it bad?|Oh no, it's bad, isn't it? How bad is it?",
			gentle = "Oh my, I cut my own bangs this morning.|It's not too bad, is it?",
			foodie = "I cut them while I was waiting for my toast.|The toast came out better.",
			_ = "Is it really bad? You can be honest.|Actually, no, please don't be honest.",
		}, "sweat")
		s:choice("It suits you.", function(c)
			burst(c, "a", {
				proud = "I know.|Say it again, a bit louder this time.",
				shy = "...!|Really? You're not just saying that?",
				prickly = "You're just saying that.|...Thanks, though.",
				gloomy = "Huh, okay.|Maybe it's not the worst thing that's happened this week.",
				nervous = "Oh, thank goodness.|I was so sure everyone would stare.",
				sunny = "Really, really?|Ehehe, I'm keeping it, then.",
				gentle = "Oh, that's kind of you, {player}.|Thank you.",
				bold = "Hah, I knew it.|Thanks.",
				dreamy = "Hmm... really?|Then maybe it's meant to be like this.",
				easygoing = "Cool, then I don't have to fix it.",
				cheeky = "i know, i'm a genius with scissors|jk, thank you",
				cool = "Okay, thanks.",
				dramatic = "You've SAVED my whole week.",
				bookish = "Really? Thank you.|That makes the next four months a lot easier.",
				polite = "Thank you, {player}, that is very kind of you.",
				foodie = "Thanks, that's sweeter than honey.",
				_ = "Really, {player}?|Okay, then I'm keeping it.",
			}, "heart")
			c:mood("a", 5)
			c:hearts("a", 1)
			c:remember("a", "haircut")
		end)
		s:choice("Maybe wear a hat for a week.", function(c)
			burst(c, "a", {
				proud = "Th-the bangs aren't that bad.|...Fine, where did I put my hat?",
				easygoing = "Fair enough, I've got a hat around here somewhere.",
				dramatic = "A HAT?|...Yes, all right, a hat.",
				cheeky = "rude|accurate, but rude",
				sunny = "A hat, okay!|I'll find the brightest one I've got.",
				gentle = "Oh, that's a good idea.|I have a nice warm one.",
				bold = "A hat, fine.|A big one, right?",
				dreamy = "Hmm... a hat with a flower on it, maybe.",
				shy = "Oh... okay.|I'll find a hat.",
				cool = "Fair, hat it is.",
				prickly = "Ugh, fine.|But only for a week.",
				bookish = "Good idea, a hat for four months, then.",
				gloomy = "Yeah, I figured.|Heh... hat it is.",
				polite = "Yes, I think that would be best.",
				foodie = "Fine, a hat, and a muffin to cheer me up.",
				nervous = "Is it that bad?|Okay, okay, where's my hat?",
				_ = "Is it really that bad?|Right, I'll go and find a hat.",
			}, "sad")
			c:mood("a", -3)
			c:memo("a", "I'm wearing a hat until my bangs grow out, so please don't ask.")
			-- and they do (Sim/Memory), until they ask whether it can come off
			c:wear("a", "beanie")
			c:follow("hatoff", { hours = 36 })
		end)
		s:log("{a} cut their own bangs.")
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
		s:n("The cat jumped a foot in the air, then gave {a} a long look.")
		burst(s, "a", {
			shy = "Sorry, sorry, cat...|I didn't mean to.",
			bold = "Hah, you jumped higher than I've ever seen a cat jump.",
			cheeky = "ten out of ten jump, honestly|sorry cat, hehe",
			gentle = "Oh, my, you poor thing.|I didn't mean to scare you.",
			dreamy = "Hmm... I think it thinks I'm a thundercloud now.",
			cool = "Hm, it'll get over it.",
			prickly = "Don't look at me like that.|You were the one sleeping on my wall.",
			dramatic = "It will NEVER forgive me.",
			polite = "I do apologise.|That was very rude of me.",
			nervous = "Is it okay? Is it hurt?|...Oh, good, it's only glaring at me.",
			sunny = "Oops, sorry, kitty!|That was a really high jump, though.",
			easygoing = "Heh, sorry, cat.|Go back to sleep, it's fine.",
			proud = "It was a very nice sneeze, just so you know.",
			bookish = "A sneeze can go about a hundred and sixty kilometres an hour, actually.|No wonder it jumped.",
			gloomy = "Even the cats don't like me now.|Heh... as usual.",
			foodie = "Sorry, cat.|I'll bring you a bit of fish later.",
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
			proud = "Hmph, this is the story of my life.|It'll be worth a fortune one day, you'll see.",
			cheeky = "half of it is made up|apparently yesterday i won a boat race",
			cool = "It's my diary.|It's private.",
			prickly = "What? People write things down all the time.|It's completely normal.",
			dramatic = "Every word in here is true, and every tear too.",
			bookish = "I've kept a diary since I was eight.|This is notebook number forty one.",
			gloomy = "Today it rained, and tomorrow it'll probably rain again.|That's most of what's in here.",
			polite = "Good evening, {player}.|I always end the day by writing a little, I hope you do not mind.",
			sunny = "{player}, hi, hi.|I'm writing about today, and you're in it.",
			gentle = "Oh, {player}, I'm just writing about my day.|I always do it before bed.",
			bold = "It's my diary.|Yes, I keep one, and no, you can't read it.",
			dreamy = "Hmm... I write down my dreams so I don't forget them.|Last night's was about fish.",
			easygoing = "I write a little every night.|Usually just 'had a nap'.",
			foodie = "I write down everything I ate today.|It's a very long diary.",
			nervous = "Oh, {player}!|Did you see what I wrote? Please say you didn't.",
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
					dramatic = "How DARE you.|...Heh, nice try, though.",
					sunny = "Ehehe, no way.|It's a secret.",
					dreamy = "Hmm... not today.|Maybe one day.",
					easygoing = "Heh, nope, nice try, though.",
					proud = "Certainly not.|You'll have to wait for the book.",
					cheeky = "nope|it's top secret, you're not allowed",
					bookish = "No, but I'll lend you any other book I own.",
					gloomy = "No.|It's boring anyway, trust me.",
					polite = "I am sorry, but it is private.",
					foodie = "Nope, but you can read my shopping list.",
					nervous = "N-no, please, it's private!",
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
			sunny = "Look, look, that one's {one}.|And that one's {two}.",
			gentle = "Oh, look, that one looks like {one}.|And the little one is {two}.",
			bold = "That one's {one}, easy.|And that's {two}, right?",
			dreamy = "Hmm... that one's {one}.|And over there... {two}, I think.",
			easygoing = "That one's {one}.|And that one... eh, {two}, sure.",
			proud = "That one is clearly {one}.|And that one is {two}, I'm always right about these.",
			shy = "Um... that one looks like {one}.|And maybe that one's {two}?",
			cool = "That one's {one}, that one's {two}.",
			prickly = "That one's {one}, obviously.|And that's {two}, don't argue.",
			dramatic = "That one is {one}.|And THAT one is {two}!",
			bookish = "That one looks like {one}.|And the one beside it looks like {two}, actually.",
			gloomy = "That one looks like {one}.|And that one's {two}, I guess, before it falls apart.",
			polite = "That one looks very much like {one}.|And the one next to it is {two}, I believe.",
			foodie = "That one looks like {one}.|And that one's {two}, but I wish it was a pie.",
			nervous = "That one looks like {one}, right?|And that's {two}? Is that right?",
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
			sunny = "Come on, lie down with me.|Let's find a cloud that looks like you.",
			gentle = "Come and lie down for a bit, {player}.|You work so hard.",
			proud = "I'm very good at this, you know.|I see shapes nobody else can.",
			dramatic = "The SKY is putting on a show just for me.",
			polite = "Would you like to join me, {player}?|There is plenty of room.",
			nervous = "Is it okay to just lie here?|Nobody's going to think it's weird?",
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
		s:n("{a} has left their umbrella on the path and is jumping in every puddle.")
		burst(s, "a", {
			proud = "Hmph, this is for my health, you know.|Splashing is very good for the legs.",
			shy = "Hehe, nobody's looking...|Oh, um, except you.",
			gentle = "Oh, my, I haven't done this since I was small.",
			cool = "You didn't see this.",
			prickly = "What? It's raining, so this is what puddles are for.",
			dramatic = "That was the biggest splash this street has ever SEEN.",
			gloomy = "My boots leak anyway.|I might as well get some use out of them.",
			nervous = "This is allowed, right?|Nobody's going to get mad at me?",
			sunny = "{player}, watch this one.|Ehehe, that was the biggest yet.",
			bold = "Hah, biggest splash on the street.|Your turn, right?",
			dreamy = "Hmm... every puddle has a little sky in it.|La la ♪",
			easygoing = "I'm already wet, so I might as well keep going.",
			cheeky = "splash attack|you're next, {player}, hehe",
			bookish = "This one's about ten centimetres deep, actually.|Watch.",
			polite = "Please excuse me, {player}.|I could not resist.",
			foodie = "This is more fun than lunch.|Almost.",
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
			sunny = "{player}, come and meet my new friend.|Let's build him a little brother together.",
			cool = "I built a snowman.|He came out well.",
			prickly = "He's lopsided, I know.|Don't say it.",
			dramatic = "Look at him standing tall against the winter.|This is my finest work.",
			gloomy = "He'll have melted by Thursday.|Still, look at him while he's here.",
			foodie = "I gave him cookies for buttons and then ate one.|So now he only has two buttons.",
			gentle = "Isn't he sweet?|I gave him my old scarf so he won't get cold.",
			easygoing = "He took all morning, but I took a lot of breaks.",
			proud = "The finest snowman on the island, naturally.|Look how straight he stands.",
			shy = "Um, I made a snowman.|He's a bit lopsided.",
			bookish = "Three balls, each one a bit smaller, like a proper snowman.|I measured them, actually.",
			polite = "Good afternoon, {player}.|May I introduce my snowman?",
			nervous = "Is he leaning?|He's leaning, isn't he? Oh no.",
			_ = "Doesn't he look smart, {player}?|I lent him my scarf.",
		}, "sparkle", "point")
		s:choice("He needs a carrot nose.", function(c)
			burst(c, "a", {
				cheeky = "ooh, perfect|now he can smell the bakery like the rest of us",
				sunny = "Yes, yes, a carrot.|Let's go and get one together.",
				gentle = "Oh, that's perfect.|I have one in the kitchen, I'll get it.",
				bold = "Good idea, carrot nose, right now.",
				dreamy = "Hmm... a carrot nose.|He'll look so happy.",
				easygoing = "Good idea, I'll go and get one... in a minute.",
				proud = "I was about to say that.|A carrot, naturally.",
				shy = "Oh... yes, a carrot.|That's a nice idea.",
				cool = "Good call, a carrot.",
				prickly = "Fine, a carrot.|But a straight one, not a bent one.",
				dramatic = "A NOSE! He needs a nose.",
				bookish = "A carrot is the usual nose, actually.",
				gloomy = "A carrot, okay.|Something will eat it, but okay.",
				polite = "What a good idea, thank you.",
				foodie = "I'd better not eat this one, then.",
				nervous = "A carrot? Will it fall off?|Okay, I'll push it in really well.",
				_ = "Oh, that's perfect.|Now he can smell the bakery like the rest of us.",
			}, "heart", "cheer")
			c:leave("snowman", 24, "a")
			c:mood("a", 6)
			c:memo("a", "Have you said hello to my snowman yet? He's very polite.")
		end)
		s:choice("It's too cold for me.", function(c)
			burst(c, "a", {
				cheeky = "fair, i can't feel my fingers anymore anyway",
				sunny = "Aw, okay.|Then let's get hot chocolate together.",
				gentle = "Oh, you're right, it's freezing.|Go and warm up, okay?",
				bold = "Hah, too cold?|Fine, I'll finish him myself.",
				dreamy = "Hmm... my nose is cold too.|I'll stay a little longer, though.",
				easygoing = "Fair, I'm going inside too, he's done enough.",
				proud = "Hmph, the cold doesn't bother me.|...Okay, it does a bit.",
				shy = "Oh... okay.|My fingers are cold too.",
				cool = "Fair, go warm up.",
				prickly = "Fine, go inside.|...I'm coming too, it's freezing.",
				dramatic = "My fingers have turned to ICE!",
				bookish = "It's minus three, actually.|Inside sounds good.",
				gloomy = "Yeah, it's freezing.|I'll probably catch a cold.",
				polite = "Of course, please go and get warm.",
				foodie = "Then let's go and get soup.|Hot soup, right now.",
				nervous = "Is it too cold?|You're right, let's go inside.",
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
			sunny = "Jump in with me, {player}.|Let's go together on three, ready?",
			cool = "I'm allowing myself one jump.",
			prickly = "I raked every one of those myself.|So I'm jumping in it, and don't argue.",
			dramatic = "This one is for AUTUMN.",
			nervous = "W-what if there's a hedgehog in there?|...No, I checked twice, it's fine.",
			gentle = "Oh, it's such a nice big pile.|Just one little jump, okay?",
			dreamy = "Hmm... it smells like autumn.|I'm going to lie in it and listen.",
			shy = "Um... is it okay if I jump in?|Just once.",
			bookish = "There must be two thousand leaves in there, actually.|I'm jumping in anyway.",
			gloomy = "I'll probably land on a stick.|...Here goes.",
			polite = "Please excuse me, {player}.|I would like to jump in, just once.",
			foodie = "It looks like a giant pile of cornflakes.|I'm jumping in.",
			_ = "Just one jump, I promise.|Then I'll rake it all up again.",
		}, "sparkle", "cheer")
		s:n("Now the leaves are everywhere again, and {a} is lying in the middle.")
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
			dramatic = "I'm cooked, {player}, like a sausage on a grill.",
			bookish = "I knew all about sunscreen.|I'd read about it, I just didn't wear any.",
			gloomy = "Of course it was only one side, heh.",
			foodie = "I look like a radish.|A nice fresh one, at least.",
			sunny = "{player}, look, I'm half pink.|Ehehe, it really stings, though.",
			gentle = "Oh my, I fell asleep in the sun.|It's a little sore, that's all.",
			bold = "Hah, I fell asleep on the beach.|It stings, but I'm fine, right?",
			dreamy = "Hmm... I was dreaming about the sea.|I didn't notice the sun at all.",
			cheeky = "i'm two colours now|it's a new look",
			polite = "Please do not look, {player}.|I fell asleep in the sun.",
			nervous = "Oh no, is it bad?|It's bad, isn't it? It really stings.",
			_ = "It's only on one side, so I look like a radish.",
		}, "sweat")
		s:choice("I'll get you some aloe.", function(c)
			burst(c, "a", {
				polite = "Oh, that is very kind of you.|Thank you kindly.",
				prickly = "...That actually helps.|Fine, thanks.",
				shy = "...!|Thank you.",
				cool = "Hm, that's cold.|Thanks, {player}.",
				sunny = "Ooh, that's cold.|Thank you, thank you.",
				gentle = "Oh, that's so much better.|Thank you, {player}.",
				bold = "Hah, cold.|Thanks.",
				dreamy = "Mm... that's cool, like rain.|Thank you.",
				easygoing = "Ahh, that's nice.|I could fall asleep again.",
				proud = "Hmph, I didn't need it.|...It does help, though.",
				cheeky = "cold, cold, cold|ok, thanks",
				dramatic = "Oh, the RELIEF!|Thank you, {player}.",
				bookish = "Aloe really does help, actually.|Thank you.",
				gloomy = "Thanks.|That's actually nice.",
				foodie = "Ooh, cold, like ice cream.|Thanks, {player}.",
				nervous = "Will it work?|Oh, it's working, thank you.",
				_ = "Ooh, that's cold.|Thank you, {player}.",
			}, "heart")
			c:mood("a", 3)
			c:hearts("a", 1)
		end)
		s:choice("Sunscreen next time?", function(c)
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
			sunny = "{player}, look how high it is.|It's pulling so hard.",
			cool = "{player}, look.|It's really pulling today.",
			gentle = "Look, {player}, it's flying so nicely.|Isn't it pretty?",
			bold = "Look at it go, {player}.|Highest kite on the hill, right?",
			dreamy = "La la ♪... it's dancing with the wind.",
			easygoing = "It's doing all the work, I'm just holding on.",
			proud = "Look at that, {player}.|I'm very good at kites.",
			shy = "Um, {player}, look...|It's really high.",
			cheeky = "look how high it is|higher than your kite, if you had one",
			prickly = "Don't distract me, it's pulling.|...Okay, look, it's really high.",
			dramatic = "It's touching the SKY, {player}!",
			bookish = "That's about forty metres of string out, actually.",
			gloomy = "It's actually staying up.|For now.",
			polite = "Look, {player}, the wind is very good today.",
			foodie = "It's flying so well.|I'll celebrate with a snack after.",
			nervous = "It's pulling so hard!|What if the string snaps?",
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
				sunny = "Oh no, my kite!|Let's get it down together.",
				gentle = "Oh dear, it's stuck up there.|I hope it isn't torn.",
				dreamy = "Oh... it wanted to sit in the tree for a while.",
				easygoing = "Eh, it'll come down when it's ready.",
				proud = "Th-that was on purpose.|I was testing the tree.",
				bookish = "The wind dropped by half, actually.|That's why.",
				polite = "Oh dear, it seems to be stuck.",
				foodie = "Oh no, the kite.|Well, I was getting hungry anyway.",
				_ = "Well... at least it's still up high.",
			}, "sweat")
			s:choice("Let's get it down.", function(c)
				c:n("A long stick got it down, with only one small hole.")
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
				sunny = "Higher, higher.|Look at it go.",
				cool = "It's good wind for it today.",
				gloomy = "It's actually staying up, huh.",
				dramatic = "It FLIES.",
				shy = "...!|It's so high up.",
				gentle = "Oh, look how high it is.|It's lovely up there.",
				bold = "Hah, look at it go.|Nothing can stop it today.",
				dreamy = "La la ♪... it's almost touching the clouds.",
				easygoing = "Nice, it's flying itself, I'm just here.",
				proud = "Perfect flying, naturally.",
				cheeky = "it's so high|i'm basically a pilot now",
				prickly = "Okay, it's flying.|Don't say anything, you'll ruin it.",
				bookish = "That's nearly all fifty metres of string, actually.",
				polite = "Oh, how lovely, it is flying beautifully.",
				foodie = "It's so high.|I'm going to fly it all afternoon and then eat.",
				nervous = "It's so high!|Is that too high? Okay, it's fine.",
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
			dramatic = "A new star, born tonight.|...With little lights on its wings.",
			gloomy = "It's a plane.|Things usually turn out to be planes.",
			sunny = "I'm going to name it after you, {player}!|Wait, it's a plane, isn't it?",
			gentle = "Oh, it's a plane.|It's still pretty, though.",
			bold = "That's a plane, right?|Yeah, it's a plane.",
			easygoing = "Eh, it's a plane, but I'm calling it a star anyway.",
			shy = "Um... it's a plane, isn't it?|S-sorry.",
			prickly = "Ugh, it's a plane.|Don't say anything.",
			polite = "Oh, I believe it may be a plane.",
			foodie = "It's a plane.|I bet they're serving snacks up there.",
			nervous = "Wait, is it a plane?|Oh no, I already told my neighbour.",
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
			sunny = "{player}, are you up too?|Ehehe, good, talk to me for a bit.",
			cool = "I can't sleep.|You're up too, I see.",
			prickly = "Don't ask why, I just can't sleep, okay?",
			dramatic = "The night is so very LONG, {player}.",
			bookish = "I read that counting backwards helps you fall asleep.|I've reached minus forty.",
			gloomy = "It's two in the morning, and I'm awake as usual...|I'll be useless tomorrow.",
			foodie = "I can't stop thinking about toast.|Is it too late to make some?",
			nervous = "D-did I lock the front door?|I'm sure I did, but I'm going to check again.",
			gentle = "Oh, {player}, you're up late too.|I can't seem to settle tonight.",
			easygoing = "*yawn*|I napped all afternoon, and now I can't sleep, funny that.",
			polite = "Good evening, {player}, and sorry it is so late.|I cannot seem to get to sleep.",
			_ = {
				"I've counted four hundred sheep so far.|Even they're getting bored.",
				"Every time I close my eyes, I remember something I forgot to do.",
			},
		}, "zzz")
		s:choice("Warm milk?", function(c)
			burst(c, "a", {
				cheeky = "warm milk, ok, grandma|...it's actually working, night",
				sunny = "Ooh, warm milk.|...I'm getting sleepy already, night night.",
				gentle = "Oh, that sounds lovely.|Good night, {player}, sleep well, okay?",
				bold = "Warm milk, okay.|...Huh, it's working, good night.",
				dreamy = "Mm... warm milk.|I can feel the dreams coming already.",
				easygoing = "*yawn* That did it.|Night, {player}.",
				proud = "I suppose warm milk could work.|...It's working, good night.",
				shy = "Um... okay.|Thank you, good night.",
				cool = "Warm milk, okay.|Night.",
				prickly = "Fine, I'll try it.|...Okay, it's working, good night.",
				dramatic = "The milk of SLEEP.|Good night, {player}.",
				bookish = "Warm milk really does help you sleep, actually.|Good night.",
				gloomy = "It won't work.|...Oh, it's working, good night.",
				polite = "Thank you, {player}, that is very kind.|Good night.",
				foodie = "Warm milk, and maybe a cookie?|...Good night, {player}.",
				nervous = "Warm milk, okay.|What if it doesn't work? Oh, it's working, good night.",
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
				sunny = "Tomorrow, ehehe, it's going to be such a good day.|Okay, I'll try to sleep now, good night.",
				gentle = "Oh, I was just worrying about a friend.|Talking helps, thank you, good night.",
				bold = "Work stuff, but I've decided what to do.|Good night, {player}.",
				dreamy = "Hmm... I was wondering where the moon goes in the day.|I'll dream about it, good night.",
				easygoing = "Nothing, really, I just napped too long.|I'll try again now, good night.",
				proud = "Nothing I can't handle.|...But thank you for asking, good night.",
				dramatic = "Oh, a thousand THINGS, {player}.|But I feel better now, good night.",
				polite = "Only a small worry, and it feels smaller now.|Thank you, and good night.",
				foodie = "Breakfast, mostly.|I'm making pancakes, so I need to sleep, good night.",
				_ = "Only the things I forgot to do today.|Saying them out loud helped, good night, {player}.",
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
	when = "night",
	weight = W({ base = 0.2, traits = { lazy = 0.4 } }),
	scene = function(ctx, a)
		local food = ctx.rng:pick(Foods.list)
		local s = K.scene(ctx, "A midnight snack"):with({ food = food.name:lower() })
		s:n("A light is on in {a}'s kitchen at two in the morning.")
		burst(s, "a", {
			cheeky = "oh, hi|i'm not eating, i'm guarding the {food}",
			cool = "{player}.|I'm not eating, I'm only checking on the {food}.",
			sunny = "Oh, hi, {player}.|I'm just checking on the {food}, ehehe.",
			gentle = "Oh, {player}, you're up too?|I was just checking on the {food}.",
			bold = "Oh, hey.|Yes, I'm eating the {food}, and I'm not sorry.",
			dreamy = "Oh... {player}.|The {food} looked so nice in the moonlight.",
			easygoing = "Oh, hey, {player}.|Just me and the {food}, having a quiet night.",
			proud = "{player}.|I'm testing the {food}, to make sure it's good.",
			shy = "Oh... {player}.|I was only, um, looking at the {food}.",
			prickly = "What are you doing up?|I'm not eating the {food}, so don't ask.",
			dramatic = "{player}! You've caught me with the {food}.",
			bookish = "Oh, {player}.|I'm only checking the {food} is still fresh, actually.",
			gloomy = "Oh, it's you.|Yes, it's the {food}, I couldn't sleep.",
			polite = "Oh, good evening, {player}.|I was only checking on the {food}.",
			foodie = "Mmm, {player}, you have to try this {food}.|It's even better cold.",
			nervous = "Oh no, {player}!|I-I'm not eating the {food}, I promise.",
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
			polite = "Would you like some?|I would feel rude eating alone.",
			foodie = "Mmm, everything tastes better at night, have you noticed?",
			nervous = "Is it too late to be eating?|Oh no, it is, isn't it?",
			sunny = "Want some?|Let's share it, ehehe.",
			gentle = "Do you want some?|You should eat something too, okay?",
			dreamy = "Hmm... food tastes different at night.|Like it's a secret.",
			_ = "I was only going to have one bite, and now look.",
		}, "heart")
		s:mood("a", 3)
		s:log("{a} had a midnight snack.")
		return s:done()
	end,
})

event({
	id = "nightmare",
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
			dramatic = "{player}, I dreamed the sea came up the street and took my HOUSE.",
			bookish = "I dreamed the library had no books left.|There were just rows and rows of empty shelves.",
			gloomy = "I dreamed it was sunny and everyone was happy.|Then I woke up, heh.",
			polite = "Forgive me for bothering you so late.|I dreamed I would forgotten to thank someone, and it was awful.",
			foodie = "I dreamed every pie in town was empty.|There was just crust, everywhere.",
			nervous = "I dreamed I left the oven on.|I don't even use my oven, but I've checked it twice now.",
			gentle = "I'm sorry, {player}, I know it's late.|I dreamed everyone in town had moved away.",
			sunny = "{player}, are you awake?|I dreamed nobody would play with me, it was awful.",
			easygoing = "*yawn* {player}, I had a weird one.|I dreamed I had to run everywhere.",
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
				sunny = "Yeah, you're right!|Stay and talk for a bit, though, please.",
				gentle = "You're right.|Thank you for staying with me, {player}.",
				dreamy = "Hmm... yes, only a dream.|The clouds are still there, look.",
				easygoing = "Yeah, I know.|I'll just go back to sleep, I'm good at that.",
				cheeky = "obviously|you can stay though, if you want",
				dramatic = "Only a dream, but SUCH a dream!|Stay with me a moment.",
				bookish = "I know, dreams are just the brain sorting things, actually.|Still, could you stay a minute?",
				polite = "Yes, of course.|Thank you for staying with me.",
				foodie = "I know.|Want some warm milk with me?",
				nervous = "Y-you're right.|Can you stay just a minute, though?",
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
			dramatic = "Rise, little fern, and reach for the SUN.",
			bookish = "Actually, plants like the air we breathe out.|So I talk to them as much as I can.",
			gloomy = "Please don't die like the last one.|I've got a good feeling about you, though.",
			polite = "Hello there, and thank you for growing so nicely.",
			foodie = "When you're a big tomato, you'll be the best tomato in town.",
			nervous = "Is it too much water, or not enough?|I wish you could tell me.",
			sunny = "Good morning, good morning, little plant.|Let's both grow big today.",
			bold = "Grow, plant.|You can do it, right?",
			easygoing = "Take your time, little plant.|No rush at all.",
			shy = "Um... hi, plant.|You're doing really well.",
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
			sunny = "Thank you all so much for being here.|I'd like to thank my mom, the baker, and the man with the dog.",
			dramatic = "Friends, neighbours, and gulls of the harbour, I stand before you HUMBLED.",
			bookish = "Thank you, I promise I'll be brief.|There are only nine short sections.",
			polite = "Thank you, every one of you.|And thank you too, mirror.",
			gentle = "Thank you all for coming.|I'd like to thank everyone who was kind to me.",
			bold = "Thanks, everyone.|I'm going to keep this short, right?",
			dreamy = "Hmm... thank you all.|I'd like to thank the sea, and the clouds, and...",
			easygoing = "Thanks, everyone.|That's it, that's the speech.",
			cheeky = "thank you, thank you|no autographs, please",
			cool = "Thank you, that's all.",
			prickly = "Thanks for coming.|Now go home.",
			gloomy = "Thank you all for coming.|I didn't think anyone would.",
			foodie = "Thank you all for coming.|There's cake after, so I'll be quick.",
			nervous = "Th-thank you all for coming.|I, um, I forgot the rest.",
			_ = "Thank you, thank you.|I'd like to thank... um, everybody, I suppose.",
		}, "sparkle", "point")
		burst(s, "a", {
			shy = "...!|You heard all of that, didn't you?|I'm going to go and hide now.",
			proud = "Go on, you can say it was good.|I'll take questions now, if you have any.",
			cool = "How long have you been standing there?",
			prickly = "You didn't see any of that, got it, {player}?",
			nervous = "H-how long have you been standing there?|Was it bad? Please say it wasn't bad.",
			cheeky = "oh, hi|that speech was for the gulls, they asked for one",
			sunny = "Oh, {player}, you heard.|Was it good? Was it good?",
			gentle = "Oh my, {player}, you heard that.|It's only practice, okay?",
			bold = "Oh, {player}.|Good, you can tell me how it was.",
			dreamy = "Oh... {player}.|I was practising for a dream I had.",
			easygoing = "Oh, hey, {player}.|Just practising, in case anyone ever asks me to talk.",
			dramatic = "{player}! You heard my SPEECH?",
			bookish = "Oh, {player}, I'm practising for the town meeting.|It's four minutes long, actually.",
			gloomy = "Oh, you heard that.|Heh... nobody's going to ask me to give a speech anyway.",
			polite = "Oh, good afternoon, {player}.|I do apologise, I was only practising.",
			foodie = "Oh, {player}, hi.|It's for the bake sale, if they ever give me a prize.",
			_ = "Oh, {player}, hi.|It isn't for anything, I just like to be ready.",
		}, "sweat")
		s:choice("*clap clap*", function(c)
			burst(c, "a", {
				shy = "Oh...|Um, thank you.",
				proud = "Thank you, yes.|Please, keep clapping.",
				cheeky = "louder|i can't hear you, hehe",
				dramatic = "Thank you, you're too kind.|I could do an encore, if you insist.",
				sunny = "Ehehe, thank you, thank you.|I'll do it again tomorrow.",
				gentle = "Oh, that's so kind of you.|Thank you, {player}.",
				bold = "Hah, thanks.|That was a good one, right?",
				dreamy = "Oh... clapping.|That's a nice sound.",
				easygoing = "Heh, thanks, one person clapping is plenty.",
				cool = "Thanks, that helps.",
				prickly = "Stop it.|...Okay, one more clap.",
				bookish = "Thank you, I'll cut it down to three minutes, though.",
				gloomy = "You're clapping?|Heh... that's nice.",
				polite = "Thank you very much, {player}.",
				foodie = "Thank you, that deserves a snack.",
				nervous = "Really? Was it okay?|Thank you, thank you.",
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
			sunny = "{player}, I've decided to become a new me.|I'm doing fifty push ups every morning, starting today.",
			cool = "{player}.|I'm doing fifty push ups a day from now on.",
			gentle = "{player}, I've decided to look after myself more.|Fifty push ups every morning, starting today.",
			bold = "{player}, fifty push ups every morning, starting now.|You're joining me, right?",
			dreamy = "Hmm... {player}, I dreamed I was really strong.|So I'm doing fifty push ups a day now.",
			easygoing = "{player}, I'm starting a new routine.|Fifty push ups a day, after my nap.",
			proud = "{player}, from today I'm doing fifty push ups every morning.|I'll be the fittest person in town.",
			shy = "Um, {player}... I'm going to try fifty push ups a day.|Please don't watch.",
			cheeky = "{player}, meet the new me|fifty push ups a day, starting now, probably",
			prickly = "{player}, I'm doing fifty push ups a day from now on.|Don't look so surprised.",
			dramatic = "{player}, today I become a NEW person!|Fifty push ups, every single morning.",
			bookish = "{player}, I read that fifty push ups a day is a good start.|So I'm starting today.",
			gloomy = "{player}, I'm going to do fifty push ups a day.|We'll see how long that lasts.",
			polite = "Good morning, {player}.|I have decided to do fifty push ups every morning.",
			foodie = "{player}, I'm doing fifty push ups a day now.|So I can eat more pie.",
			nervous = "{player}, I'm going to try fifty push ups a day.|What if I can't even do one?",
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
				dramatic = "I gave it everything I had, all four of them.",
				gloomy = "Four, heh.|I knew it would be something like that.",
				foodie = "I think four push ups has earned me a bun.",
				prickly = "Not a word.|Four is a start.",
				sunny = "Four, ehehe!|That's four more than yesterday.",
				gentle = "Four is a good start.|I'll go easy on myself, okay?",
				bold = "Four.|Tomorrow it's five, and then fifty, right?",
				dreamy = "Hmm... the grass is so soft.|I'll just stay here for a while.",
				shy = "Um... only four.|Please don't tell anyone.",
				cheeky = "four push ups|that's like fifty in cat years",
				bookish = "Four push ups is eight percent of fifty, actually.|It's a start.",
				polite = "Four will have to do for today, I think.",
				nervous = "Only four?|Is that bad? It's bad, isn't it?",
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
		s:n("The mail brought a letter for {a}, in handwriting they knew at once.")
		burst(s, "a", {
			shy = "{player}...|It's from my best friend back home, and she still remembers me.",
			proud = "Someone from my old town wrote to say they miss me.|Well, of course they do.",
			dreamy = "It smells like the town I grew up in...|Like salt and toast.",
			cool = "Hm, it's from an old friend.|They're doing well.",
			prickly = "They actually wrote to me.|...Took them long enough.",
			dramatic = "Eight whole pages, {player}.|From the BEST friend I've ever had.",
			gloomy = "I thought they'd forgotten all about me.|They hadn't, and I don't get many letters, so that was nice.",
			polite = "How very thoughtful of them.|I must write a proper reply this evening.",
			nervous = "I was scared it would be bad news.|It's only news from home, phew.",
			sunny = "{player}, look, look, a letter from home!|They want to come and visit.",
			gentle = "Oh, it's from an old friend, {player}.|They wanted to know if I'm eating well.",
			bold = "It's from my old neighbour.|They still owe me a game of cards.",
			easygoing = "It's from an old friend.|Nothing much happens there either, which is nice.",
			cheeky = "a letter from an old friend|they still think i'm the nice one, hehe",
			bookish = "It's from my old teacher.|She still writes in green ink, after twelve years.",
			foodie = "It's from my aunt.|There's a recipe for plum cake in it, too.",
			_ = "It's from an old friend, {player}.|They're doing well, and they want to hear all about this place.",
		}, "heart")
		s:choice("Write back today.", function(c)
			burst(c, "a", "I will, as soon as I get home.|I'll tell them about you, too.", "heart", "cheer")
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
	{ "a sweater their grandma had knitted, with a reindeer on the front.", 4 },
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
		s:n("A parcel turned up outside {a}'s door with no return address.")
		burst(s, "a", {
			cheeky = "{player}, someone sent me a box|if it's a prank, i'll be impressed",
			shy = "Um, {player}?|There's a box outside my door, but what if it's meant for someone else?",
			bold = "There's a box outside my door with no name on it.|Only one way to find out what's inside.",
			cool = "{player}.|Someone left a box outside my door with no name on it.",
			prickly = "I didn't order this.|Who sends people things without asking?",
			dramatic = "A mystery, {player}, outside my very own DOOR!",
			bookish = "It hasn't got a local stamp.|So it must have come over on the ferry.",
			gloomy = "It's probably a bill.|In a box, for some reason.",
			foodie = "If I shake it, does it sound like cookies?|Mmm, I think it sounds like cookies.",
			nervous = "Should I open it? What if it ticks?|...Okay, it doesn't tick.",
			sunny = "{player}, {player}, a box came for me.|Let's open it together.",
			gentle = "Oh, {player}, someone left me a box.|Isn't that kind of them?",
			dreamy = "Hmm... a box, with no name.|It's like it fell out of a dream.",
			easygoing = "Someone left a box outside my door.|I'll open it after a little sit.",
			proud = "Someone sent me a gift, naturally.|People like me, you know.",
			polite = "Good morning, {player}.|A parcel has come for me, but I did not order anything.",
			_ = "{player}, a parcel came for me.|I didn't order anything, did I?",
		}, "question")
		s:choice("Open it now.", function(c)
			local p = ctx.rng:pick(PARCEL)
			c:with({ inside = p[1] })
			c:n("Inside was {inside}")
			if p[2] > 0 then
				burst(c, "a", {
					sunny = "Oh, I love it, I really love it.",
					cool = "Huh, that's actually nice.",
					prickly = "Hm.|...I'm keeping it.",
					shy = "...!|Is this really for me?",
					gloomy = "Something nice, for me, huh.",
					cheeky = "ok this is better than a prank",
					gentle = "Oh my, how lovely.|Someone was thinking of me.",
					bold = "Hah, nice.|I'll take it.",
					dreamy = "Oh... how nice.|I wonder who sent it.",
					easygoing = "Huh, that's nice, and I didn't even have to go anywhere.",
					proud = "Of course it's something nice.|Someone has good taste.",
					dramatic = "It's PERFECT!",
					bookish = "Oh, that's lovely.|I'll work out who sent it, I always do.",
					polite = "Oh, how very kind.|I must find out who sent it and thank them.",
					foodie = "Oh, that's lovely.|Though I was hoping for cookies.",
					nervous = "Is it really for me?|Oh, it's lovely, thank you, whoever you are.",
					_ = "Oh, that's really nice.",
				}, "sparkle")
			else
				burst(c, "a", {
					prickly = "A single button, seriously?",
					dramatic = "A BUTTON?|All of that for one button?",
					cheeky = "a button|respect, honestly",
					sunny = "A button.|Ehehe, okay, it's a nice button.",
					gentle = "A button.|Well, it's a pretty button.",
					bold = "A button?|Hah, okay, sure.",
					dreamy = "Hmm... a button.|Maybe it's from someone's favourite coat.",
					easygoing = "A button, huh.|Eh, I'll find a use for it.",
					proud = "A single button.|Well, it's a very nice button.",
					shy = "Oh... a button.|That's okay.",
					cool = "A button, okay.",
					bookish = "A button.|Actually, it's quite an old one.",
					gloomy = "A button.|Heh... sounds about right.",
					polite = "Oh, a button.|How unusual.",
					foodie = "A button.|I was hoping it was chocolate.",
					nervous = "A button?|Is it a message? What does it mean?",
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
			dramatic = "My good shirt, {player}, my GOOD shirt.",
			gloomy = "Yep, that's how the day's going, then.",
			polite = "Oh, dear.|Did any of it get on you? I am so sorry.",
			foodie = "What a waste of good tea.|It had honey in it and everything.",
			nervous = "Is it hot? No, it's not hot.|Okay, I'm fine, I'm fine.",
			sunny = "Oops, oops.|Ehehe, at least it wasn't hot.",
			gentle = "Oh my, all down my front.|It's all right, I'll go and change.",
			bold = "Hah, that's one way to wear tea.|I'll go and change.",
			dreamy = "Oh... the tea went for a walk.|Down my shirt.",
			bookish = "Tea stains come out with cold water, actually.|I'll go and soak it.",
			_ = "Great, just great.",
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
			foodie = "{player}, nobody's ever put these two together, which is crazy.|Look at them, they belong in the same bowl!",
			bookish = "Someone tried this in a very old cookbook.|The whole entry just says 'no', so let's see if they were right.",
			nervous = "Nobody's ever put these two together.|Is there a reason? There's a reason, isn't there?",
			cool = "I'm trying a new dish.|We'll see how it goes.",
			sunny = "{player}, I'm making a dish nobody's ever tried!|Let's find out why, ehehe.",
			gentle = "{player}, I'm trying something new.|It might be strange, but let's see, okay?",
			bold = "Nobody's ever put these two together.|I'm doing it anyway.",
			dreamy = "Hmm... I dreamed about these two together.|So I'm trying it.",
			easygoing = "I had these two in the cupboard, so I'm putting them together.|It's the easy way.",
			proud = "Nobody's ever put these two together.|Clearly nobody was as clever as me.",
			shy = "Um, {player}... I'm trying a new dish.|It might be strange.",
			cheeky = "new dish|it's either amazing or a crime",
			prickly = "Don't make that face.|It's going to work.",
			dramatic = "{player}, I am inventing a NEW dish.|History is being made.",
			gloomy = "Nobody's ever put these two together.|There's probably a good reason.",
			polite = "Good afternoon, {player}.|I am trying a new recipe, if you would like to watch.",
			_ = "Nobody's ever put these two together.|Let's find out why.",
		}, "idea")
		s:choice("Let me taste it.", function(c)
			if ctx.rng:chance(0.5) then
				c:n("It was good, oddly good.")
				burst(c, "a", BRAG, "sparkle", "cheer")
				c:mood("a", 5)
				c:memo("a", "My {one} and {two} dish actually worked, so I'm making it again on Sunday.")
				c:remember("a", "dish", { what = "{one} and {two} dish" })
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
			dramatic = "Stand back, {player}, art is happening.",
			bookish = "I'm trying the old way of doing it.|Did you know you're meant to leave a whole day between the layers?",
			gloomy = "It's the harbour on a grey day.|So, most days.",
			foodie = "It's a bowl of fruit.|I've eaten two of the models, so I'm working from memory.",
			nervous = "Don't look yet!|Okay, you can look now... no, wait, okay, look.",
			cheeky = "hold still, {player}|i might put you in it",
			sunny = "{player}, look, look.|It's nearly done, isn't it pretty?",
			gentle = "I'm painting the street in the afternoon light.|It's so peaceful.",
			bold = "Nearly done, and it's good, right?",
			easygoing = "I've been painting all afternoon.|Well, painting and sitting.",
			polite = "Good afternoon, {player}.|I hope you do not mind me painting here.",
			_ = "Hold still, {player}.|I might put you in it.",
		}, "sparkle")
		s:choice("Could you paint me?", function(c)
			c:n("{a} had you sit on a crate for an hour, then turned the canvas around.")
			burst(c, "a", {
				shy = "It's you...|Well, it's meant to be, and you can keep it.",
				proud = "There, you've never looked better.|You can keep it, of course.",
				cheeky = "i gave you a slightly bigger nose|artist's choice, you can keep it",
				prickly = "It's you.|Take it before I change my mind.",
				dramatic = "Look, {player}, this is how the WORLD will remember you.",
				polite = "Thank you for sitting so still.|Please, it is yours to keep.",
				sunny = "Ta-da, it's you.|Let's hang it up right now.",
				gentle = "There you are, {player}.|I hope you like it.",
				bold = "There, that's you.|Pretty good, right?",
				dreamy = "Hmm... it's you, but a little dreamier.|You can keep it.",
				easygoing = "There you go, that's you.|It took me ages, but it was worth it.",
				cool = "Done, it's yours.",
				bookish = "It took exactly an hour, actually.|You can keep it.",
				gloomy = "It's not great.|...But it is you, and you can have it.",
				foodie = "There, it's you.|I almost painted you holding a pie.",
				nervous = "Is it okay? Does it look like you?|You can keep it, if you want.",
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
				sunny = "Okay, okay.|I'll show you first when it's done.",
				gentle = "Thank you, {player}.|Come back later and see it, okay?",
				bold = "Good, I'll show you when it's done.",
				dreamy = "Mm... okay.|It's nearly there, I think.",
				easygoing = "Sure, I'll be here all afternoon anyway.",
				proud = "Come back when it's finished.|You won't believe it.",
				shy = "Okay...|Thank you.",
				cool = "Okay, later.",
				prickly = "Good.|...Come back later, though.",
				dramatic = "Go, and come back when the MASTERPIECE is done.",
				bookish = "Thanks, I need about two more hours, actually.",
				gloomy = "Okay.|It'll probably look worse when it's done, heh.",
				polite = "Thank you, {player}.|I will show you when it is finished.",
				foodie = "Thanks, I'll finish after a snack.",
				nervous = "Okay, thanks.|I'll show you, if it turns out okay.",
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
		{ "n", "{a} has clay up to the elbows and a pot drying by the door." },
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
		prickly = "It's crooked on purpose, obviously.",
		bookish = "People have made pots this way for thousands of years.|Now I'm one of them.",
		foodie = "It's going to be my soup pot.|I'm making soup in it tonight.",
		sunny = "It's my very first pot.|I'm going to make a hundred more.",
		gentle = "It's a little crooked, but I made it with care.",
		bold = "It's a good pot, right?|I'm keeping it on the table.",
		dreamy = "Hmm... it looks like it's leaning over to listen to something.",
		easygoing = "It took all day, with breaks.|Mostly breaks.",
		cheeky = "it's a pot|it's also a hat, if you want",
		dramatic = "My first POT!|Look at it, {player}.",
		gloomy = "It leans a bit.|Most things I make do.",
		polite = "I hope it is all right.|It is my very first one.",
		nervous = "Does it look okay?|It's leaning, isn't it? Oh no.",
		_ = "I put some lavender in it to hide the crooked bit.",
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
		{ "n", "{a} has been sitting outside their door with a knife and a bit of wood since lunch." },
		{ "a", "It's meant to be a bird.|You can tell it's a bird, right?", "question" },
	},
	react = {
		cheeky = "i was going for a duck, but it had other ideas",
		bold = "It took me three bits of wood.|I snapped the first two in half.",
		cool = "It's a robin, if you were wondering.",
		gloomy = "It looks a bit sad, like me.|I like it, though.",
		nervous = "I only cut myself twice.|That's good for a first try, right?",
		dramatic = "It sings, {player}, in its own wooden way.",
		sunny = "It's a bird, a little bird.|I'm going to make a whole family of them.",
		gentle = "It's a little bird.|I hope it looks happy.",
		dreamy = "Hmm... I think it's about to fly away.|It just doesn't know it yet.",
		easygoing = "It took all afternoon, but I wasn't in a hurry.",
		proud = "Look at those wings.|Nobody else in town could carve those.",
		shy = "Um... it's a bit rough.|I'm still learning.",
		prickly = "It's a bird.|Don't say it looks like a potato.",
		bookish = "It's a robin, actually.|You can tell by the round chest.",
		polite = "I hope you like it.|It is my first one.",
		foodie = "It's a bird.|I nearly carved a sandwich instead.",
		_ = "I think it's the nicest thing I've ever made.",
	},
	memo = "I carved a little bird, and now my thumb has a bandage on it.",
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
		sunny = "It's so warm.|Let's have a picnic on it.",
		bold = "It's big enough for two, and it's warm, right?",
		dreamy = "Hmm... every patch is a little memory.",
		easygoing = "It's perfect for naps.|I've already tested it twice.",
		shy = "Um... it's a bit uneven.|But I like it.",
		cheeky = "one patch is from my neighbour's curtain|don't tell them",
		cool = "It's warm, that's what counts.",
		dramatic = "Every patch holds a STORY!",
		bookish = "There are forty eight patches, actually.|Six rows of eight.",
		gloomy = "It's a bit lumpy.|It's warm, though.",
		foodie = "It's the perfect size for a picnic blanket.",
		nervous = "Is it okay?|Some of the stitches came out crooked.",
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
				sunny = "Look, look, a ship in a bottle!|Guess how I got it in there.",
				gentle = "Isn't it sweet?|It took me most of the week.",
				bold = "A ship in a bottle, built by me.|Pretty good, right?",
				dreamy = "Hmm... it looks like it's sailing on glass.",
				easygoing = "It took most of the week.|Slowly, the way I like it.",
				shy = "Um... I made a ship.|It's in a bottle.",
				cheeky = "guess how it got in there|wrong, it was magic",
				cool = "It's a ship in a bottle. It took a week.",
				prickly = "Don't ask how I got it in there.|It's a secret.",
				dramatic = "A whole SHIP, {player}, in a bottle!",
				bookish = "It's a model of a real ship, actually.|It took me most of the week.",
				gloomy = "It took me all week.|I'll probably drop it.",
				polite = "May I show you something, {player}?|It took me most of the week.",
				foodie = "I used a jam jar first.|This bottle works much better.",
				nervous = "Careful, it breaks easily.|It took me all week.",
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
		sunny = "Next I'm making a whole fleet.",
		gentle = "I'd like to give it a little name, I think.",
		bold = "Next time I'm doing a bigger ship.",
		easygoing = "I did a bit each evening, no rush.",
		shy = "My hands were shaking the whole time...|But it worked.",
		cheeky = "i dropped the first one in the sink|this is ship number two",
		prickly = "Don't touch the glass.|...Okay, you can touch it a little.",
		dramatic = "It sails FOREVER in its tiny sea!",
		gloomy = "I'll probably knock it off the shelf someday.|Heh... until then, it's nice.",
		polite = "I hope it looks all right to you.",
		foodie = "I worked on it every evening after dinner.",
		nervous = "What if it falls apart inside?|It won't, I hope.",
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
				sunny = "One shell for every nice day!|Look, the jar's full.",
				gentle = "I keep one shell for each nice day.|The jar's full now, isn't that lovely?",
				bold = "One shell for every good day.|The jar's full, so it's been a good year.",
				dreamy = "Hmm... one shell for every nice day.|The jar's full of them now.",
				easygoing = "One shell for each nice day.|I'm going to need a bigger jar.",
				proud = "One shell for every good day.|Naturally, I need a bigger jar.",
				shy = "Um... I keep a shell for each nice day.|The jar's full now.",
				cool = "One shell for each good day. The jar's full.",
				prickly = "It's one shell for every nice day.|Don't make it a thing.",
				dramatic = "One shell for every HAPPY day.|And look, it's overflowing.",
				bookish = "One shell for each nice day, and there are a hundred and twelve, actually.",
				gloomy = "One shell for every nice day.|I thought it would be emptier.",
				polite = "I keep one shell for every pleasant day.|I am happy to say the jar is full.",
				foodie = "One shell for every nice day.|It used to be a cookie jar.",
				nervous = "I keep one shell for every nice day.|Is that silly? The jar's full.",
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
		sunny = "Look, look, {player}, this one's pink inside.",
		gentle = "This little one's from a quiet morning I liked very much.",
		bold = "This big one's my favourite.|I found it on a really windy day.",
		easygoing = "I picked them up on my walks.|Slow walks.",
		proud = "I only keep the best ones.|I'm very picky.",
		shy = "Um... this one's my favourite.|It's from a really nice day.",
		cool = "This one's from the day of the big storm.",
		prickly = "Don't shake it.|...Okay, one shake.",
		dramatic = "Every shell is a MEMORY, {player}!",
		bookish = "This spiral one's a whelk, actually.|They're my favourite.",
		polite = "This one is from a very nice afternoon, I remember it well.",
		foodie = "This one's from the day I had the best fish sandwich ever.",
		nervous = "Careful, some of them are sharp.|Sorry.",
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
		polite = "I left a little dish of seeds by the door.|It seemed like the right thing to do.",
		nervous = "D-do you think the bird likes it?|It hasn't said, but it's a bird.",
		sunny = "A bird moved in already.|Let's give it a name.",
		dreamy = "Hmm... I hope it has nice dreams in there.",
		easygoing = "The bird moved in fast.|It must like the quiet, like me.",
		proud = "Only the best house for the birds of this town.",
		shy = "Um... I hope the bird is happy there.",
		cheeky = "the bird pays no rent|i'm working on it",
		cool = "It's a good house. The bird agrees.",
		prickly = "The bird didn't even say thanks.|...It's fine, I like it anyway.",
		dramatic = "A HOME, for a tiny bird.",
		bookish = "The door is three centimetres wide, actually.|That keeps the big birds out.",
		gloomy = "Something will knock it down, probably.|Until then, the bird likes it.",
		foodie = "I left a bit of bread on the roof.|It's a welcome present.",
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
		sunny = "Listen, listen.|Isn't it pretty?",
		gentle = "It's such a soft sound.|I hope it helps you sleep.",
		bold = "It's loud when the wind picks up.|I like it loud.",
		proud = "Every note is just right.|I tuned them myself.",
		shy = "Um... is it too loud?|I like it, though.",
		cheeky = "it's loudest at night|sorry, neighbours",
		prickly = "Don't say it's too loud.|It's just right.",
		dramatic = "The wind SINGS for us.",
		gloomy = "It's a bit sad sounding.|I like that, though.",
		polite = "I hope it is not too loud for the neighbours.",
		foodie = "It sounds like the bell at the bakery.|Now I'm hungry.",
		nervous = "Is it annoying?|Tell me if it's annoying.",
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
		shy = "The heart's a bit crooked...|Is that all right?",
		cheeky = "there's a secret message on the bottom|don't look yet",
		foodie = "It's exactly the right size for soup.|I tested it already.",
		prickly = "The dots were an accident.|Now they're on purpose.",
		sunny = "It's for you, well, maybe.|Let's have tea in it together.",
		gentle = "I hope it makes your mornings a little nicer.",
		bold = "Best mug I've made.|Tea tastes better in it, right?",
		dreamy = "Hmm... the dots look like little stars.",
		easygoing = "It's a good mug.|Perfect for slow mornings.",
		proud = "Look at that heart.|Nobody paints hearts like I do.",
		cool = "It came out well. Have it.",
		dramatic = "A mug made with my whole HEART!",
		bookish = "It took three coats of paint, actually.|And a whole night to dry.",
		gloomy = "The paint's a bit smudged.|It still holds tea, though.",
		polite = "I hope you like it.|I painted it very carefully.",
		nervous = "Is the paint okay?|I hope it doesn't come off in the wash.",
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
		sunny = "Look, look, they're so pretty.|Let's go and pick more together.",
		bold = "They came out great, right?|I'm doing more next week.",
		easygoing = "I just left them in a book and forgot about them.|Best way to do it.",
		proud = "Look how perfectly flat they are.|It's all in the timing.",
		shy = "Um... they're a bit small.|But I like them.",
		cheeky = "i used the heaviest book i have|which i have never read, hehe",
		cool = "They came out well.",
		prickly = "Don't touch them, they're easy to break.|...Okay, gently.",
		dramatic = "Their beauty is SAVED forever!",
		polite = "I hope you like them.|They are from the hill.",
		foodie = "I was going to put mint in too, but I ate it.",
		nervous = "Are they okay?|They're not too squashed?",
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
		sunny = "Look, it glows!|Let's make a whole row of them.",
		gentle = "It makes the room feel warm, doesn't it?",
		dreamy = "Hmm... it glows like the moon.",
		easygoing = "It's nice to sit next to.|I've been doing that all evening.",
		proud = "Nobody folds paper like I do.",
		cheeky = "the first one turned into a hat|this one's a lantern, i promise",
		prickly = "Don't touch it.|...You can look, though.",
		dramatic = "A tiny MOON in my window!",
		bookish = "It's folded from one sheet, actually.|No glue at all.",
		gloomy = "It's a soft light.|Good for quiet nights.",
		polite = "I hope you like it.|It took the whole evening.",
		foodie = "It's the colour of honey.|Now I want toast with honey.",
		_ = "I painted little petals all the way around it.",
	},
	memo = "I made a paper lantern, and it makes my room feel so warm.",
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
		proud = "It has three twisty patterns in it.|Do you know how hard those are to knit?",
		dramatic = "It began life as a scarf.|It became something far greater.",
		sunny = "It's a cushion now, ehehe.|Let's put it on the bench outside.",
		gentle = "It's a little lumpy, but it's soft.|It's yours if you'd like it.",
		bold = "A scarf, a cushion, whatever.|It's comfy, right?",
		dreamy = "Hmm... it decided to be a cushion.|I just went along with it.",
		shy = "Um... it was meant to be a scarf.|Sorry.",
		cheeky = "it's a scarf for a very wide neck|jk, it's a cushion",
		cool = "It's a cushion now. That's fine.",
		prickly = "Don't laugh.|It's a very good cushion.",
		bookish = "I lost count of the rows, actually.|That's how it got so wide.",
		gloomy = "It's not what I planned.|Things rarely are, heh.",
		polite = "I hope it is comfortable.|It was meant to be a scarf.",
		foodie = "It's perfect for sitting on at picnics.",
		nervous = "Is it okay that it's a cushion?|I didn't mean it to be.",
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
		sunny = "Look, look, a gull!|It's even got a beak.",
		gentle = "Isn't it sweet?|It's made from bits the sea left behind.",
		bold = "It's tougher than a real gull.|And quieter, right?",
		easygoing = "I just picked up wood on my walk, and it turned into a gull.",
		proud = "A work of art, from bits of wood.|That's real skill.",
		shy = "Um... it's a gull.|I hope it looks like one.",
		cool = "It's a gull, it's good.",
		prickly = "It's a gull.|Don't say it looks like a duck.",
		dramatic = "From the SEA, a gull is born!",
		bookish = "This bit of wood came all the way across the sea, actually.|You can tell by the salt.",
		gloomy = "It looks a bit lonely.|Like a real gull, I suppose.",
		polite = "I hope you like it.|It is made from driftwood.",
		nervous = "Is it okay?|Its head keeps falling off.",
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
		sunny = "Shake it, {player}, go on.",
		bold = "Give it a good shake.|Better than real snow, right?",
		dreamy = "Hmm... it's like a little world that's always calm.",
		easygoing = "Shake it and watch.|It's very relaxing.",
		proud = "Every tiny window is painted by hand, naturally.",
		shy = "Um... do you like it?|The tree's a bit crooked.",
		cool = "Shake it, watch the snow.",
		prickly = "Don't shake it too hard.|...Okay, a little harder.",
		dramatic = "A whole WINTER in my hands.",
		bookish = "The snow is tiny bits of white glitter, actually.|It falls slowly in the water.",
		polite = "Please, give it a gentle shake.",
		foodie = "The house in it looks like a gingerbread house.|I want one.",
		nervous = "Careful, it's glass!|Okay, now shake it gently.",
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
			dramatic = "I have fallen in front of the WHOLE town.",
			gloomy = "Hello again, floor.|We meet so often, heh.",
			polite = "Oh, excuse me.|Sorry, everyone, do carry on.",
			nervous = "D-did anyone see that?|Did you see that? Oh no, oh no.",
			sunny = "Ehehe, oops.|I'm okay, I'm okay.",
			gentle = "Oh my, I'm all right.|Nobody worry, okay?",
			dreamy = "Oh... the ground came up to say hello.",
			easygoing = "Eh, I was going to sit down anyway.",
			bookish = "There's a stone sticking up two centimetres, actually.|That's what got me.",
			foodie = "I'm fine, but I nearly dropped my bun.",
			_ = "I'm fine, I'm fine.|Keep walking, there's nothing to see.",
		}, "sweat", "laugh")
		s:mood("a", -1)
		s:log("{a} tripped over nothing.")
		return s:done()
	end,
})

local PIGEON = { "Captain", "Nugget", "Sir Flaps", "Doris", "Pudding", "Gary" }

event({
	id = "pigeon",
	when = "day",
	weight = W({ base = 0.15 }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "A follower")
		s:n("A pigeon has been following {a} around town all morning.")
		burst(s, "a", {
			shy = "Um, {player}...|It won't stop looking at me, but I think it's sweet.",
			bold = "I've got a sidekick now.|It keeps up, too.",
			cheeky = "i gave it one crumb, just one|now it thinks it lives with me",
			cool = "{player}.|There's a pigeon following me, and I've decided it can stay.",
			prickly = "Shoo.|...Fine, don't shoo, you can stay.",
			dramatic = "A loyal companion, {player}, and it chose ME.",
			gloomy = "It's the first friend I've made all week...|And it's a pigeon, heh.",
			foodie = "It likes the same bakery as me, so I respect it.",
			nervous = "Does it want something?|What does it want from me?",
			sunny = "{player}, {player}, I have a pigeon now!",
			gentle = "{player}, this pigeon has been following me all morning.|I think it's lonely, poor thing.",
			dreamy = "Hmm... a pigeon keeps following me.|Maybe we were friends in a dream.",
			easygoing = "This pigeon's been with me all morning.|It walks as slowly as I do.",
			proud = "Even the pigeons can see I'm someone worth following.",
			bookish = "Pigeons can remember faces for years, actually.|So I suppose we're friends now.",
			polite = "Good morning, {player}.|This pigeon seems to have chosen me.",
			_ = "I think it's decided we're friends now.",
		}, "question")
		burst(s, "a", "It needs a name, though.|What should I call it?", "idea")
		s:askName({
			var = "pet",
			suggest = PIGEON,
			ask = "What should the pigeon be called?",
			build = function(c)
				burst(c, "a", {
					prickly = "{pet}.|...Fine, it suits the little pest.",
					cheeky = "{pet}, hehe|hello, {pet}",
					sunny = "{pet}! Hi, hi, {pet}!",
					gentle = "{pet}, what a sweet name.|Hello, {pet}.",
					bold = "{pet}, good name.|Come on, {pet}.",
					dreamy = "{pet}... hmm, yes, that feels right.",
					easygoing = "{pet}, sure, that works.",
					proud = "{pet}, a fine name for a fine pigeon.",
					shy = "{pet}...|Hello, {pet}.",
					cool = "{pet}, good.",
					dramatic = "{pet}, the BRAVEST pigeon in town.",
					bookish = "{pet}, good, I'll write it down.",
					gloomy = "{pet}.|Heh... it suits it.",
					polite = "{pet}, how lovely.|Thank you, {player}.",
					foodie = "{pet}, and I'll share my crumbs with you.",
					nervous = "{pet}? Is that okay with it?|It looks okay with it.",
					_ = "{pet} is perfect.|Hello, {pet}.",
				}, "heart", "cheer")
				c:mood("a", 3)
				c:memo("a", "{pet} the pigeon still follows me everywhere.")
				c:follow("pigeonback", { chance = 0.5, hours = 8, words = { pet = "{pet}" } })
			end,
		})
		s:log("A pigeon adopted {a}.")
		return s:done()
	end,
})

local CATS = { "Turnip", "Duchess", "Pebble", "Mr Socks", "Waffle", "Pickle" }

event({
	id = "stray",
	when = "day",
	weight = W({
		base = 0.12,
		traits = { kind = 0.3 },
		cond = function(ctx, a)
			return ctx.memory(a, "pet") == nil
		end,
	}),
	scene = function(ctx, a)
		local s = K.scene(ctx, "A cat moves in")
		s:prop("cat", "a")
		s:n("A ginger cat has been sitting outside {a}'s door for three days.")
		burst(s, "a", {
			gentle = "{player}, I think it's decided it lives here now.|Who am I to argue with a cat?",
			proud = "Hmph, even cats know quality when they see it.|It picked my door out of the whole street.",
			easygoing = "It naps even more than I do, and I respect that.",
			cool = "It's staying, as far as I'm concerned.",
			prickly = "I didn't invite it.|...I did buy it a bowl, but don't read into it.",
			bookish = "Did you know cats pick their people?|It's never the other way around.",
			gloomy = "It'll leave, they always do...|Oh, it's still here, heh.",
			polite = "Hello, {player}.|A cat has chosen my door, out of every door in town.",
			sunny = "{player}, I think I have a cat now!|It hasn't said so, but it hasn't left either.",
			shy = "Um...|I think I might have a cat now.",
			bold = "There's a cat outside my door, and it's not leaving.|Fine by me.",
			dreamy = "Hmm... a cat has been sitting outside my door.|I think it walked out of a dream.",
			cheeky = "i have a cat now|well, the cat has me",
			dramatic = "{player}, a cat has CHOSEN me!",
			foodie = "A cat has been sitting outside my door for three days.|I may have given it some fish.",
			nervous = "There's a cat outside my door, {player}.|What if it belongs to someone?",
			_ = "I think I have a cat now, {player}.",
		}, "heart")
		burst(s, "a", "It'll need a name, though.|What do you think suits it?", "question")
		s:askName({
			var = "pet",
			suggest = CATS,
			ask = "What should the cat be called?",
			build = function(c)
				burst(c, "a", {
					cool = "{pet}.|...Yes, that's right.",
					shy = "{pet}...|...!|Hello, {pet}.",
					sunny = "{pet}, yes, yes.|Hi, {pet}.",
					gentle = "{pet}, that's lovely.|Welcome home, {pet}.",
					bold = "{pet}, good, that's settled.",
					dreamy = "{pet}... it blinked at me, so it likes it.",
					easygoing = "{pet}, nice, it's already asleep.",
					proud = "{pet}, an excellent name, naturally.",
					cheeky = "{pet}, hehe|it's ignoring me already, perfect",
					prickly = "{pet}.|...Fine, it suits it.",
					dramatic = "{pet}, the new BOSS of my house.",
					bookish = "{pet}, good.|Cats like names with two sounds, actually.",
					gloomy = "{pet}.|Heh... it looked at me, so it must be okay.",
					polite = "{pet}, how lovely.|Thank you, {player}.",
					foodie = "{pet}, and I'm buying {pet} the good fish.",
					nervous = "{pet}?|Do you like it? It purred, so yes.",
					_ = "{pet}, yes, you look exactly like a {pet}.",
				}, "heart", "cheer")
				c:mood("a", 6)
				c:hearts("a", 1)
				c:memo("a", "{pet} slept on my face last night, and I didn't have the heart to move.")
				-- and the cat is theirs for a while (Sim/Memory)
				c:remember("a", "pet", { what = "cat", name = "{pet}" })
				c:follow("petnews", { chance = 0.5, hours = 10 })
			end,
		})
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
			sunny = "{player}, {player}, come here quickly.|Bring a cup with you.",
			cool = "There's a big spider in the bath.|I'll need a cup.",
			prickly = "It can't stay.|...Fine, it can stay until I find a cup.",
			dramatic = "{player}, there's a BEAST in my bath!",
			bookish = "Actually, that's a house spider, and they eat flies.|I still don't want it in my bath, though.",
			gloomy = "Of course it's in the bath.|Where else would it be?",
			polite = "Excuse me, would you please move?|I would like to have a bath.",
			foodie = "It's bigger than a meatball.|Why did I just think of a meatball?",
			nervous = "Don't move, is it moving?|Oh no, oh no, it's moving.",
			easygoing = "There's a spider in my bath.|Eh, it can have it, I'll wash later.",
			_ = "Can someone else deal with this?|I'm not going in there, {player}.",
		}, "sweat")
		s:choice("I'll take it outside.", function(c)
			c:n("You carried it out in a cup and let it go by the hedge.")
			c:voice("a", "thanks", "heart")
			c:hearts("a", 1)
			c:mood("a", 2)
			-- it may find its way back (Sim/FollowUps)
			c:follow("spiderback", { chance = 0.35, hours = 6 })
		end)
		s:choice("It was here first.", function(c)
			burst(c, "a", {
				gentle = "Then it can stay.|I'll wash at the beach for now.",
				proud = "Fine, it's my guest.|I'll wash in the sea like a hero.",
				nervous = "O-okay, okay.|I'll just never go in there again.",
				cheeky = "wow, ok|the spider gets the bath and i get the sea",
				sunny = "Okay, it can stay.|I'll go and swim in the sea instead.",
				bold = "Fine, it wins this one.|I'll wash at the beach.",
				dreamy = "Hmm... then it's the spider's bath now.",
				easygoing = "Fair, I'll skip the bath today.",
				shy = "Oh... okay.|It was here first.",
				cool = "Fair, it stays.",
				prickly = "Ugh, fine.|It's paying rent, though.",
				dramatic = "Then I give up my BATH to a spider.",
				bookish = "That's fair, it was probably there for weeks, actually.",
				gloomy = "Of course it gets the bath.|I'll wash at the beach.",
				polite = "Very well, it may stay.|I will wash at the beach.",
				foodie = "Fine, it can stay.|I'll go and get a snack instead.",
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
			sunny = "{player}, I found a coin on my way out!|And then I found ANOTHER one by the fountain.",
			cool = "{player}.|I found a coin outside my door and another by the fountain.",
			gentle = "{player}, I found a coin outside my door.|And then another by the fountain, isn't that sweet?",
			bold = "Two coins before breakfast, {player}.|Today's my day, right?",
			dreamy = "Hmm... a coin was shining on the path.|Then another one by the fountain.",
			easygoing = "I found a coin on my way out.|Then another, and I didn't even look for them.",
			proud = "{player}, I found two coins this morning.|Luck follows talent, you know.",
			shy = "Um, {player}... I found a coin.|And then another one.",
			cheeky = "found a coin|found another coin|i'm rich now, basically",
			prickly = "I found two coins this morning.|Don't get excited, it's only two.",
			dramatic = "{player}, COINS, everywhere I walk.",
			bookish = "{player}, I found two coins this morning.|The odds of that are about one in fifty, actually.",
			gloomy = "I found a coin this morning.|Then another, which is strange for me.",
			polite = "Good morning, {player}.|I found a coin on my way out, and another by the fountain.",
			foodie = "{player}, I found two coins this morning.|That's a free bun, at least.",
			nervous = "{player}, I found a coin, and then another one.|Is that okay? Should I tell someone?",
			_ = "I found a coin on my way out this morning.|Then I found another one by the fountain.",
		}, "sparkle", "cheer")
		burst(s, "a", {
			proud = "Naturally, the world has finally caught up with me.",
			dreamy = "I think the sky likes me today...",
			cool = "It's not a bad start to the day.",
			gloomy = "Something bad's bound to happen to make up for it.|Nothing yet, though.",
			dramatic = "Luck is SMILING at me.|For today, at least.",
			nervous = "Should I hand them in?|Who would I even give them to?",
			sunny = "Today's the best day ever.|Let's see what else I find.",
			gentle = "Isn't that a nice surprise?|I'll share them with someone who needs them.",
			bold = "Hah, lucky me.|Let's see what else today brings.",
			easygoing = "Eh, I'll take it.|Good things happen when you're not rushing.",
			shy = "Um... it's nice, isn't it?|I don't usually find things.",
			cheeky = "i'm going to walk around all day looking at the ground",
			prickly = "Don't jinx it.|...But it's nice.",
			bookish = "I'm writing it down, actually.|I want to see if it happens again.",
			polite = "It is a very pleasant start to the day.",
			foodie = "I'm spending them on a bun, obviously.",
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
			dramatic = "The WHOLE world has turned against me!",
			gloomy = "This is just a normal morning for me, as usual...",
			foodie = "My toast, my poor toast.|It had jam on it and everything.",
			nervous = "What's going to go wrong next?|No, don't answer that.",
			shy = "Um, {player}...|It's been one of those mornings.",
			gentle = "Oh my, it's been one of those mornings.|I'll make a nice cup of tea and start again.",
			bold = "Toe, toast, and it's not even nine.|I'm not letting it win, right?",
			dreamy = "Hmm... the morning got out of bed on the wrong side.|Not me, the morning.",
			cheeky = "my toe hates me|my toast hates me|great start",
			bookish = "Toast lands butter side down about half the time, actually.|Today was that half.",
			polite = "I am having a rather bad morning, I am afraid.",
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
			sunny = "{player}, guess what.|I'm collecting {things} now, and I've got eleven already.",
			cheeky = "guess what i collect now|wrong, it's {things}, and i've got eleven",
			cool = "{player}.|I've started collecting {things}, and I'm at eleven so far.",
			gentle = "{player}, I've started collecting {things}.|I've got eleven already, isn't that nice?",
			bold = "{player}, I'm collecting {things} now.|Eleven already, and I'm going for a hundred.",
			dreamy = "Hmm... {player}, I've started keeping {things}.|There are eleven now.",
			easygoing = "I've started collecting {things}.|They keep turning up, so why not?",
			proud = "{player}, I'm collecting {things}.|I already have eleven, and only the best ones.",
			shy = "Um, {player}... I've been collecting {things}.|I have eleven.",
			prickly = "I collect {things} now.|Eleven so far, and don't laugh.",
			dramatic = "{player}, I've started a COLLECTION!|Eleven {things}, and counting.",
			bookish = "{player}, I've started a collection of {things}.|Eleven so far, all with labels, actually.",
			gloomy = "I've started collecting {things}.|Eleven so far, though nobody's asked to see them.",
			polite = "Good afternoon, {player}.|I have started collecting {things}, and I have eleven so far.",
			foodie = "{player}, I'm collecting {things} now.|Eleven, and I keep them in an old cookie tin.",
			nervous = "{player}, I've been collecting {things}.|Eleven so far, is that weird?",
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
			sunny = "I'm going to get a hundred.|You can help me find them.",
			gentle = "I keep them on the windowsill where the sun hits them.",
			bold = "I'm going to have the biggest collection in town, right?",
			easygoing = "I'm not looking for them, they just turn up.",
			shy = "I keep them in a little box...|I can show you, if you want.",
			dramatic = "Each one is PRECIOUS to me!",
			polite = "I hope it is not too strange a hobby.",
			foodie = "I keep them in a cookie tin.|The cookies are long gone.",
			nervous = "Is it a strange thing to collect?|Please say it isn't.",
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
			cheeky = "look at me, i'm very fancy|hehe",
			proud = "Frankly, I think it suits me.",
			shy = "I've scrubbed it four times...|It's still there.",
			cool = "It's staying, apparently.",
			dramatic = "I am a new person now, {player}.|A person with a moustache.",
			nervous = "W-what if it never comes off?|What if this is just my face now?",
			sunny = "Look, look, I have a moustache.|Ehehe, it won't come off.",
			gentle = "Oh my, it won't come off.|Does it look all right?",
			bold = "It won't wash off, so I'm keeping it.|It's a good look, right?",
			dreamy = "Hmm... I've got a curly moustache now.|I wonder if it'll fade by tomorrow.",
			easygoing = "It won't come off.|Eh, I'll just wear it.",
			prickly = "Don't laugh.|I used the wrong pen, okay?",
			bookish = "It's the kind of ink that won't wash off, actually.|I should have read the pen.",
			gloomy = "Of course it was the pen that won't wash off.|Heh... of course.",
			polite = "Please excuse my face, {player}.|It will not wash off.",
			foodie = "It's in the way when I eat.|That's the real problem.",
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
		s:n("{a} sat outside their door with a guitar and wrote a song about the town.")
		burst(s, "a", "Oh Catalog Town, your gulls are loud,|your bread is warm, and I'm so proud.", "music")
		burst(s, "a", {
			proud = "That's going to be a hit, just you wait.",
			shy = "That's all I've got so far...|Was it all right?",
			cool = "It's only a rough draft.",
			dramatic = "There are eleven verses, {player}, and you've only heard one.",
			foodie = "The line about the bread is my favourite, obviously.",
			sunny = "That's only the first verse.|Let's sing it together.",
			gentle = "I wrote it for everyone here.|I hope they like it.",
			bold = "That's the chorus.|Catchy, right?",
			dreamy = "La la ♪... the rest is still floating around in my head.",
			easygoing = "That's as far as I got before my nap.",
			cheeky = "verse two is about you|you'll have to wait",
			prickly = "Don't say it's cheesy.|...It's a little cheesy.",
			bookish = "It has four lines a verse, and every second line rhymes, actually.",
			gloomy = "It's not very good yet.|Heh... it might never be.",
			polite = "I hope you did not mind listening.",
			nervous = "Was it okay?|I've never played it for anyone.",
			_ = "The second verse is about the bus.|It still needs some work.",
		}, "sparkle")
		s:choice("Again, from the top.", function(c)
			burst(c, "a", {
				shy = "You want to hear it again?|Okay... um, from the top.",
				bold = "From the top, and louder this time!",
				sunny = "Yay, from the top!|Sing with me.",
				gentle = "Of course, from the top.|Sing along if you like.",
				dreamy = "La la ♪... from the top, then.",
				easygoing = "Sure, from the top, nice and slow.",
				proud = "Of course you want to hear it again.",
				cheeky = "from the top, and you have to do the gull noises",
				cool = "From the top.",
				prickly = "Fine, from the top.|Don't laugh at the second line.",
				dramatic = "Once more, with FEELING!",
				bookish = "From the top, and I've fixed the second line, actually.",
				gloomy = "You want to hear it again?|Heh... okay.",
				polite = "Of course, from the beginning.",
				foodie = "From the top, and the bread line is louder this time.",
				nervous = "Again? Okay, um, from the top.",
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
		s:n("{a} is blowing bubbles outside their door, and some of them are very big.")
		burst(s, "a", {
			dreamy = "Each one's a tiny world...|And then it pops.",
			bold = "That's the biggest one yet.|It swallowed a whole leaf.",
			proud = "There's a technique to it.|I'm not going to share it, though.",
			cool = "That one went right over the roof.",
			gloomy = "They never last long.|They're nice while they do, though.",
			sunny = "Catch one, {player}.|Ooh, nearly.",
			gentle = "Look at them float.|Aren't they pretty?",
			easygoing = "Bubbles are the laziest fun.|You just blow and watch.",
			shy = "Um... do you want to try?|You can blow the next one.",
			cheeky = "i aimed that one at the cat|it worked, hehe",
			prickly = "Don't pop them.|...Okay, you can pop one.",
			dramatic = "LOOK at the size of that one!",
			bookish = "The colours come from light bending in the soap, actually.",
			polite = "Would you like a turn, {player}?",
			foodie = "I made the mix with dish soap.|It smells like lemon.",
			nervous = "Is it okay to blow bubbles out here?|Nobody minds, right?",
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
	"in a beach chair at noon",
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
			sunny = "Huh? I'm awake, I'm awake!|Ehehe, was I snoring?",
			gentle = "Oh my, did I fall asleep?|I must have been more tired than I thought.",
			bold = "I wasn't asleep.|I was thinking, right?",
			dreamy = "Mm... I was dreaming about the sea.|Where was I?",
			shy = "Oh... was I asleep?|S-sorry.",
			cheeky = "i was awake the whole time|i heard everything, hehe",
			dramatic = "I was in the deepest SLEEP of my life.",
			bookish = "I was asleep for about twenty minutes, actually.|That's the perfect nap length.",
			gloomy = "I fell asleep.|Heh... as usual.",
			polite = "Oh, please excuse me.|I must have fallen asleep.",
			foodie = "Mm... is it lunchtime?|I dreamed it was lunchtime.",
			nervous = "Was I asleep? For how long?|Did anyone see?",
			_ = "Was I asleep?|No, I definitely wasn't asleep.",
		}, "zzz")
		s:mood("a", 3)
		s:log("{a} fell asleep {spot}.")
		return s:done()
	end,
})

event({
	id = "homesick",
	when = "any",
	weight = W({ base = 0.12 }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "Homesick")
		s:n("{a} is sitting on the wall by the sea, looking out.")
		burst(s, "a", {
			bold = "I miss my old street sometimes.|Don't tell anyone I said that.",
			shy = "My old house had a blue door...|I think about it sometimes.",
			proud = "Where I grew up, there's a statue of my grandma.|It's a small one, but still.",
			cool = "I was just thinking about home.",
			prickly = "I'm fine.|...I miss home a bit, that's all.",
			dramatic = "Across that sea, {player}, is everything I left behind.",
			gloomy = "Nobody back home writes much anymore...",
			foodie = "My dad made a stew every Sunday.|I've tried, but I can never get it right.",
			gentle = "Oh, hello, {player}.|I was just thinking about home.",
			sunny = "I miss home a little today.|But I'm happy here too, really.",
			dreamy = "Hmm... somewhere over there is my old house.|I can almost see it.",
			easygoing = "I was just thinking about home.|We had a really good hammock.",
			cheeky = "i miss home a tiny bit|don't tell anyone, i have a reputation",
			bookish = "My old town is about forty kilometres that way, actually.",
			polite = "Good evening, {player}.|I was only thinking about home.",
			nervous = "I miss home a little.|Is that okay? It's okay to miss it, right?",
			_ = "I miss the place I grew up.|Even the smell of it.",
		}, "sad")
		s:choice("Tell me about it?", function(c)
			c:n("{a} talked about home for a long time, and you heard all about a dog called Bean.")
			burst(c, "a", {
				bold = "...Thanks.|Anyway, don't tell anyone I got all mushy, okay?",
				shy = "Thanks for listening.|I don't usually talk about it...",
				proud = "Well, that was more than I meant to say.",
				prickly = "...Thanks.|Don't make it weird.",
				polite = "Thank you for listening, {player}.|I truly appreciate it.",
				cool = "...Thanks.",
				sunny = "Thanks for listening, {player}!|Let's go and get buns, I feel better.",
				gentle = "Thank you for listening, {player}.|That was kind of you.",
				dreamy = "Thank you... it feels closer now.",
				easygoing = "Thanks, that was nice.|I feel lighter.",
				cheeky = "ok, that was a lot of feelings|thanks for listening, i guess",
				dramatic = "You've healed my HEART, {player}.",
				bookish = "Thank you, I talked for forty minutes, actually.|Sorry, I was rambling.",
				gloomy = "Thanks.|That was nice of you, really.",
				foodie = "Thanks, {player}.|I'll make you my dad's stew someday.",
				nervous = "Thank you, {player}.|Was that too much? Sorry.",
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
			proud = "My alarms are clearly broken.|I'll be buying better ones.",
			cool = "Tomorrow, then.",
			gloomy = "Heh... I knew that would happen.",
			nervous = "Did I miss anything?|Please tell me I didn't miss anything important.",
			sunny = "Oops, I slept in.|Tomorrow, for sure, I'll get up early.",
			gentle = "Oh my, I must have needed the sleep.|That's all right, isn't it?",
			bold = "I'll get up tomorrow.|Three alarms wasn't enough, so four, right?",
			dreamy = "Hmm... I was having such a nice dream.|The alarms didn't stand a chance.",
			shy = "Um... I slept through all of them.|Please don't tell anyone.",
			cheeky = "i turned them all off in my sleep|i'm a genius even when asleep",
			prickly = "Don't say anything.|The alarms were too quiet.",
			dramatic = "BETRAYED by my own alarms.",
			bookish = "I slept for eleven hours, actually.|My body clearly had other plans.",
			polite = "I am afraid I slept through all three alarms.",
			foodie = "I missed breakfast, so it's an early lunch, then.",
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
			dramatic = "A gift, hidden from me all these years.",
			sunny = "Look, look, they wiggle.|I'm going to show everyone.",
			gentle = "Isn't it funny?|I never knew I could do it.",
			bold = "Watch, both at once.|Bet you can't do that, right?",
			dreamy = "Hmm... I wonder what else my ears can do.",
			easygoing = "It's the least tiring talent ever.|Perfect for me.",
			prickly = "Don't tell anyone.|...Okay, watch again.",
			bookish = "Most people can't do it, actually.|It's a tiny muscle most people never use.",
			gloomy = "It's not a useful talent.|But it's mine, heh.",
			polite = "I hope that was not too strange to watch.",
			foodie = "I wonder if I can do it while eating.|Let me get a snack and test it.",
			nervous = "Is it weird?|It's a little weird, isn't it?",
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
			nervous = "There's someone up there.|{player}, there's really someone up there!",
			sunny = "Hello, hello, who's up there?|Come down and say hi.",
			gentle = "Oh my, I'm so sorry.|I didn't know anyone was up there.",
			easygoing = "Heh, fair enough, I'll be quiet now.",
			proud = "Keep it down? I have a lovely voice.",
			cheeky = "keep it down yourself|...sorry, i couldn't help it",
			dramatic = "The hill SPEAKS, {player}.",
			bookish = "Echoes come back faster when the cliff is closer, actually.|That voice was much closer.",
			polite = "I am so sorry, I did not mean to bother you.",
			foodie = "Sorry, sorry.|I'll go and eat my lunch quietly.",
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
			sunny = "{player}, quick, look!|Let's watch it together before it goes.",
			gentle = "Oh, look, a rainbow.|Isn't it lovely, {player}?",
			bold = "Look at that rainbow.|Best one this year, right?",
			easygoing = "Huh, a rainbow.|Worth stopping for, I think.",
			shy = "Oh... a rainbow.|Can you see it, {player}?",
			prickly = "Okay, it's pretty.|Don't make me say it twice.",
			dramatic = "A RAINBOW, {player}.|The sky is painting just for us.",
			polite = "Oh, how lovely.|Do look, {player}.",
			foodie = "It's the colours of a fruit salad.|Now I want a fruit salad.",
			nervous = "Quick, look before it goes!|Oh no, is it going?",
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
			sunny = "{player}, can I tell you something?|It's small, but it's bugging me.",
			gentle = "{player}, could I tell you something?|It's only a little worry.",
			bold = "{player}, I need to say something.|It's silly, but it's bugging me.",
			dreamy = "Hmm... {player}, can I tell you something?|It keeps floating around in my head.",
			easygoing = "{player}, can I tell you something?|It's small, but it won't let me nap.",
			proud = "{player}, I'm not worried.|But there's something I'd like to mention.",
			cheeky = "{player}, don't laugh|ok, you can laugh a little",
			dramatic = "{player}, I have a TERRIBLE worry.",
			bookish = "{player}, can I tell you something?|It's a small thing, but I've thought about it nine times today.",
			gloomy = "{player}, can I tell you something?|It's probably nothing, but things never are.",
			polite = "Excuse me, {player}.|May I tell you something small?",
			foodie = "{player}, can I tell you something?|It's putting me off my lunch.",
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
			dramatic = "It's ALL I can think about, {player}.",
			bookish = "Statistically it's fine, but my brain won't listen.",
			gentle = "I'm sure it's fine, but it's been nagging at me.",
			sunny = "I'm sure it's fine.|...Mostly sure.",
			easygoing = "It's probably fine, but it's stopping me from napping.",
			foodie = "I can't even enjoy my snack until I know.",
			polite = "I am sorry to trouble you with something so small.",
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
				sunny = "You're right.|Okay, I'm going to stop worrying right now.",
				gentle = "You're right, {player}.|Thank you for listening.",
				bold = "Yeah, you're right.|I'm done worrying about it.",
				dreamy = "Hmm... maybe.|It feels smaller now.",
				shy = "Okay...|Thank you, {player}.",
				cheeky = "ok, you win|i'm still checking later though",
				cool = "You're right, thanks.",
				prickly = "Fine, you're right.|...Thanks.",
				dramatic = "You've SAVED me from my own head!",
				bookish = "You're right, it's very unlikely, actually.|Thank you.",
				polite = "Thank you, {player}, that helps very much.",
				foodie = "You're right.|I can finish my snack now.",
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
				sunny = "It was fine, ehehe.|Thanks for coming with me.",
				gentle = "Thank you for coming with me.|I feel so much better.",
				dreamy = "Oh... it was fine.|It's always fine, isn't it?",
				easygoing = "It was fine, so now I can nap.",
				cheeky = "it was fine|obviously, i knew that",
				cool = "It was fine, thanks.",
				prickly = "It was fine.|...Thanks for coming, though.",
				dramatic = "It was FINE! Oh, the relief!",
				bookish = "It was fine, just like the numbers said, actually.|Thank you anyway.",
				gloomy = "It was fine.|Heh... that's a nice change.",
				foodie = "It was fine.|Let's get a snack to celebrate.",
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
	"Today is a good day to eat a second cookie.",
	"Somebody is thinking about you. It's the baker, and you owe them money.",
	"The answer is yes, if the question is soup.",
}

event({
	id = "fortune",
	when = "any",
	weight = W({ base = 0.12 }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "A fortune"):with({ fortune = ctx.rng:pick(FORTUNES) })
		s:n("{a} cracked open a fortune cookie and read the slip inside.")
		s:n("'{fortune}'")
		burst(s, "a", {
			dreamy = "This is going to come true...|I can feel it.",
			proud = "I make my own fortune, thank you very much.",
			cheeky = "keeping this, it's going on the fridge",
			cool = "Hm.|I'll keep an eye out.",
			gloomy = "That's better than I expected, honestly.",
			foodie = "The cookie was good, and that's fortune enough for me.",
			nervous = "What does it mean?|Does it mean something bad?",
			sunny = "Ooh, I love it.|I'm keeping it forever.",
			gentle = "What a sweet little fortune.|I'll keep it in my purse.",
			bold = "Hah, I'll take it.|It's going on my wall.",
			easygoing = "Sounds good to me.|No effort needed.",
			shy = "Um... I hope it comes true.|Is that silly?",
			prickly = "Fortunes are silly.|...I'm keeping it anyway.",
			dramatic = "It's DESTINY, {player}!",
			bookish = "These are all written in one factory, actually.|I'm still keeping it.",
			polite = "How very interesting.|I will keep it, I think.",
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
			sunny = "{player}, {player}, come here.|I've invented {gadget}, watch.",
			dramatic = "{player}, the moment has come.|I give you {gadget}.",
			cool = "{player}.|I made {gadget}, so watch this.",
			gentle = "{player}, come and see.|I've made {gadget}, I hope it works.",
			bold = "{player}, watch this.|I made {gadget}, and it's going to work, right?",
			dreamy = "Hmm... {player}, I dreamed up {gadget}.|Now I've built it.",
			easygoing = "{player}, I made {gadget}.|It took a while, but here it is.",
			proud = "{player}, I've invented {gadget}.|Naturally, it's a work of genius.",
			shy = "Um, {player}...|I made {gadget}, if you want to see.",
			cheeky = "{player}, i made {gadget}|stand back, just in case",
			prickly = "{player}, I made {gadget}.|Don't laugh until you've seen it.",
			bookish = "{player}, I've built {gadget}.|I drew the plans first, all six pages, actually.",
			gloomy = "{player}, I made {gadget}.|It probably won't work, but watch.",
			polite = "Good afternoon, {player}.|May I show you {gadget}?",
			foodie = "{player}, I made {gadget}.|If it works, I'm celebrating with cake.",
			nervous = "{player}, I made {gadget}.|What if it blows up? It won't, I think.",
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
				easygoing = "Eh, want to get lunch anyway?",
				cool = "Hm, noted.|I'll have another go tomorrow.",
				dramatic = "It lived so BRIEFLY.",
				gloomy = "Yeah, that's about right.",
				sunny = "Oops, ehehe.|Version two will be even better.",
				gentle = "Oh my, that didn't go to plan.|Is everyone all right?",
				bold = "Hah, okay, that didn't work.|I'll fix it tomorrow, right?",
				dreamy = "Hmm... it had other ideas.|I'll think about it in the bath.",
				shy = "Oh no...|S-sorry, everyone.",
				cheeky = "that was a test|it passed the test of being bad",
				prickly = "Don't say anything.|It nearly worked.",
				bookish = "Actually, I think the spring was too tight.|I'll redo my drawings.",
				polite = "Oh dear, I do apologise for the mess.",
				foodie = "Well, that's made me hungry.|Lunch first, then I'll fix it.",
				nervous = "Oh no, oh no, is anything broken?|Is anyone hurt?",
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
			dramatic = "They got on a BOAT, {player}, after everything.",
			sunny = "I finished it, I finished it.|Let's talk about the ending, please.",
			gentle = "Oh, that ending.|I need a cup of tea and a quiet minute.",
			easygoing = "That took me all summer.|Worth every lazy afternoon.",
			cheeky = "i read the last page first|still cried, hehe",
			prickly = "That ending was terrible.|...I'm going to read it again.",
			polite = "What a wonderful book.|I will be thinking about it for days.",
			foodie = "The ending had a big feast in it.|Now I'm starving.",
			nervous = "It's over?|What do I read now? I need a new one.",
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
	when = "day",
	weight = W({ base = 0.18, traits = { focus = -0.5 } }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "Miles away"):with({ dream = ctx.rng:pick(DAYDREAMS) })
		s:n("{a} has been staring at the same spot for ten minutes, smiling.")
		burst(s, "a", "Oh, sorry, {player}, I was miles away.|I was imagining {dream}.", "zzz")
		burst(s, "a", {
			dreamy = "It was going so well...|Can I go back to it?",
			proud = "It'll happen one day, just you wait.",
			cool = "Anyway, where were we?",
			gloomy = "Back to real life, as usual.",
			cheeky = "you were in it too|you were very rude, hehe",
			sunny = "It was so much fun.|Let's make it happen for real.",
			gentle = "It was such a nice daydream.|Sorry, did you need me?",
			bold = "I'm going to do it one day.|Watch me.",
			easygoing = "Daydreams are the best kind of nap.|No bed needed.",
			shy = "Um... sorry, I drift off sometimes.|Please don't tell anyone.",
			prickly = "Don't look at me like that.|Everyone daydreams.",
			dramatic = "Why did you wake me from such a BEAUTIFUL dream?",
			bookish = "I was gone about ten minutes, actually.|Sorry.",
			polite = "I do apologise, {player}.|I was far away for a moment.",
			foodie = "There was food in it too.|There's always food in mine.",
			nervous = "Was I gone long?|Did I miss something?",
			_ = "Was I gone long?|I was, wasn't I?",
		}, "sparkle")
		s:mood("a", 3)
		s:log("{a} was lost in a daydream.")
		return s:done()
	end,
})

event({
	id = "dreamfood",
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
			sunny = "It was the best house ever.|I want to dream it again tonight.",
			gentle = "It was such a sweet dream.|I woke up smiling.",
			bold = "Best dream ever, right?|I'm going to have it again tonight.",
			dreamy = "Hmm... the windows were made of sugar.|I can still taste them.",
			shy = "Um... is that a strange dream?|I liked it, though.",
			cheeky = "i ate the whole house|no regrets",
			cool = "It was a good dream.",
			prickly = "Don't laugh.|It was a very good dream.",
			dramatic = "It was the most DELICIOUS dream of my life.",
			bookish = "Dreams about food usually mean you went to bed hungry, actually.",
			gloomy = "Then I woke up, and there was no {food}.|As usual.",
			polite = "It was a very pleasant dream, I must say.",
			nervous = "Is it weird to dream about eating a house?|It felt very real.",
			_ = "I woke up so hungry.",
		}, "heart")
		s:mood("a", 2)
		s:log("{a} dreamed about {food}.")
		return s:done()
	end,
})

event({
	id = "dreamsong",
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
		s:n("It sounded a lot like the garbage truck backing up.")
		burst(s, "a", {
			proud = "That song is going to be famous one day.",
			shy = "It sounded much better in the dream...",
			cool = "And now it's gone, oh well.",
			sunny = "Wasn't it pretty?|Let's make up the rest together.",
			gentle = "Oh, it's gone.|It was such a lovely tune.",
			bold = "That was it, right?|I'll remember the rest later.",
			dreamy = "La la ♪... no, that's not it either.|It floated away.",
			easygoing = "Eh, it'll come back to me tonight, maybe.",
			cheeky = "that was a hit|you just don't know it yet",
			prickly = "Don't say it sounded like anything.|It was beautiful.",
			dramatic = "Lost FOREVER.|The greatest song never sung.",
			bookish = "Dreams fade within ten minutes of waking, actually.|That's why it's gone.",
			gloomy = "It's gone already.|Heh... of course it is.",
			polite = "I do apologise, it was much better in my dream.",
			foodie = "It's gone.|I think it was about pancakes.",
			nervous = "Was it bad?|It sounded bad, didn't it?",
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
				sunny = "Imagine this place in ten years' time!|A fair every week, and a giant slide.",
				gentle = "Imagine this place in ten years' time.|More gardens, and everyone still happy.",
				bold = "Imagine this place in ten years' time.|Bigger, louder, and with a proper harbour wall.",
				dreamy = "Hmm... imagine this place in ten years.|Maybe a tower you can see the stars from.",
				easygoing = "Imagine this place in ten years.|More benches, I hope.",
				cheeky = "imagine this place in ten years|a statue of me, obviously",
				cool = "Imagine this place in ten years. Bigger, I think.",
				prickly = "In ten years it'll be twice as big.|And twice as noisy, probably.",
				dramatic = "In ten years, this town will be LEGENDARY!",
				bookish = "In ten years, at this rate, we'll have twice as many houses, actually.",
				gloomy = "In ten years it'll all be different.|Things always change, heh.",
				polite = "Imagine this place in ten years' time.|I would like a little theatre, if I may.",
				nervous = "Imagine this place in ten years.|What if it gets too big? Then again, it would be nice.",
				_ = "Imagine this place in ten years' time.|More houses, and a bigger bakery.",
			}, "idea", "point")
		end
		burst(s, "a", {
			gentle = "I hope we're all still here to see it.",
			cheeky = "i want my name on something|a bench, at least",
			proud = "I'd like a say in where things go, though.",
			shy = "I hope there's still room in it for me.",
			gloomy = "I hope I'm still around for it...|I'd like that, heh.",
			prickly = "Just don't wreck it, {player}, that's all I'm saying.",
			polite = "Thank you for building it, {player}.|I do mean that.",
			cool = "It'll be good.",
			sunny = "And we'll all still be here together.",
			bold = "And I'll help you build it, right?",
			dreamy = "Hmm... I'll still be here, watching the clouds.",
			easygoing = "As long as there's still a quiet spot for naps.",
			dramatic = "And you, {player}, will be its HERO.",
			bookish = "I'll keep notes on every new building, actually.",
			foodie = "As long as there's a bakery on every street.",
			nervous = "As long as it doesn't change too fast.|Is that silly?",
			_ = "You'll be the one building it, won't you, {player}?",
		}, "heart")
		s:hearts("a", 1)
		s:log("{a} wondered what the town will be like in ten years.")
		return s:done()
	end,
})

event({
	id = "lemonade",
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
			polite = "Hello there.|Would you like a glass of lemonade?",
			foodie = "I put mint in it, and a little ginger.|Try it, go on!",
			nervous = "Is it too sour?|Please tell me if it's too sour.",
			sunny = "Lemonade, lemonade, ice cold.|Get some, {player}.",
			gentle = "Would you like some lemonade?|It's a hot day, so drink up, okay?",
			dreamy = "Hmm... the ice cubes look like little stars.|Want a glass?",
			bookish = "One lemon makes about two glasses, actually.|So I squeezed forty.",
			gloomy = "Nobody's bought any yet.|Do you want some?",
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
	jogging = "{a} has started running around the island before breakfast.",
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
			sunny = "{player}, guess what, I've taken up {hobby}.|Sorry, I keep telling everyone.",
			gentle = "I've started {hobby}.|It's nice to have something quiet for the evenings.",
			bold = "I took up {hobby} this week.|I'll be good at it by the end of the month, you'll see.",
			dreamy = "I've been doing {hobby}...|The time sort of disappears when I do it.",
			easygoing = "I took up {hobby}, nothing serious.|It's something to do between naps.",
			proud = "I've taken up {hobby}.|I'm told I have a natural gift for it.",
			shy = "Um, I've started {hobby}...|I'm not very good yet, so please don't watch.",
			cheeky = "i've got a new hobby, it's {hobby}|don't laugh, ok you can laugh a bit",
			cool = "I've taken up {hobby}, and it's better than I expected.",
			prickly = "Yes, I've started {hobby}, so don't make a fuss.",
			dramatic = "{player}, I've found my true calling.|It's {hobby}.",
			bookish = "I've taken up {hobby}.|I read three books on it first, of course.",
			gloomy = "I started {hobby} thinking I'd hate it.|I don't, heh.",
			polite = "Hello, {player}.|I have taken up {hobby}, if I may mention it.",
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
		s:n("{a} ran for the bus, and the doors shut right in front of them.")
		burst(s, "a", {
			bold = "Hey!|...It saw me, I know it definitely saw me.",
			proud = "Th-that's fine, I was going to walk anyway.|It's good for my health.",
			shy = "Oh...|Okay, that's fine, it's fine.",
			cheeky = "rude|i'm writing a letter to the bus",
			easygoing = "Eh, there's a bench, so I'll just wait.",
			dreamy = "Bye, bus...|Have a nice trip.",
			sunny = "{player}, did you see that?|I was so, so close, ehehe.",
			cool = "I'll get the next one, then.",
			prickly = "Great, wonderful.|No, I'm not upset, why would I be?",
			dramatic = "It left without me, {player}.|It's GONE.",
			gloomy = "It always leaves just as I get there, as usual.",
			polite = "Oh, dear.|I hope the driver has a nice day anyway.",
			foodie = "I was going to the market for cheese.|The cheese will have to wait, I suppose.",
			nervous = "Was that the last one?|Oh no, it wasn't the last one, was it?",
			gentle = "Oh well, I'll wait for the next one.|It's a nice day to sit.",
			bookish = "The next one's in twelve minutes, actually.|I checked the timetable.",
			_ = "I missed it by one step.|One single step.",
		}, "sweat")
		s:choice("Walk with me?", function(c)
			c:n("You walked down to the harbour together, and the bus was still sitting at the stop.")
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
				sunny = "Okay, I'll wait.|I'll count the cars while I do.",
				gentle = "That's all right, I'll wait.|Thank you, {player}.",
				bold = "Fine, I'll wait.|It'd better come soon, though.",
				dreamy = "Hmm... I'll wait and watch the clouds.",
				proud = "I was going to wait anyway.",
				shy = "Okay... I'll wait here.",
				cheeky = "ok, but if it's late, i'm writing another letter",
				cool = "Okay, I'll wait.",
				dramatic = "I will wait, FOREVER if I must!",
				bookish = "Twelve minutes, I can read a chapter.",
				gloomy = "It'll be late.|They always are.",
				polite = "Thank you, I will wait for the next one.",
				foodie = "Then I've got time for a snack.",
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
		s:n("The bakery isn't open yet, and {a} is standing outside, breathing in the smell.")
		burst(s, "a", {
			foodie = "Mmm, rye, and something with cinnamon.|And yes, there are definitely buns.",
			dreamy = "If I stand here long enough, I think I'll turn into toast...",
			easygoing = "It's the best smell in town.|I come and stand here every morning.",
			bold = "I'm first in line.|I'm always first, you know.",
			shy = "Oh, {player}...|I wasn't just standing here sniffing, honestly.",
			cool = "It isn't open yet, but it's worth the wait.",
			prickly = "What?|It's free, they can't charge for a smell.",
			dramatic = "This, {player}, is why I get up in the morning.",
			bookish = "Actually, that smell is mostly the crust browning.|There's a proper word for it, but I've forgotten it.",
			gloomy = "It always smells better than it tastes...|Well, almost always.",
			polite = "Good morning, {player}.|The smell is lovely, is not it?",
			sunny = "Smell it, {player}, smell it.|Let's be first in line together.",
			gentle = "Oh, I love this smell.|It's like a warm blanket.",
			proud = "I can tell what's baking just by the smell.|Not everyone can do that.",
			cheeky = "i'm not waiting, i'm smelling|totally different",
			nervous = "Is it okay to stand here?|I'm not in the way, am I?",
			_ = "Smell that, just smell it.",
		}, "heart")
		s:n("Then the baker came out and gave {a} the first roll of the day.")
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
				dramatic = "A monster of the deep.|...A very small one, so back you go.",
				foodie = "That's about half a sandwich.|Maybe a third, so back you go.",
				sunny = "I caught one, I caught one.|Okay, back you go, little guy.",
				dreamy = "Hmm... it's so shiny.|Back you go, little one.",
				easygoing = "Huh, a fish.|Back you go, no hard feelings.",
				shy = "Oh... it's so small.|Sorry, back you go.",
				cheeky = "a whale|ok, a tiny whale|back you go",
				prickly = "That's it?|...Fine, back you go.",
				bookish = "That's a young mackerel, actually.|It needs to grow, so back it goes.",
				gloomy = "Of course it's tiny.|Back you go.",
				polite = "Oh, how small you are.|Please, go back home.",
				nervous = "Is it okay? Did I hurt it?|Quick, back you go.",
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
				sunny = "A boot, ehehe!|And a crab.",
				gentle = "Oh, a little crab.|Let's put you back gently.",
				bold = "A boot?|Hah, next time it's a real fish.",
				dreamy = "Hmm... the crab was living in it.|I've taken its house.",
				easygoing = "A boot.|Eh, still counts as a catch.",
				proud = "A boot.|I meant to clean up the harbour.",
				shy = "Oh... a boot.|Sorry, crab.",
				cool = "A boot, and a crab.",
				dramatic = "A BOOT! From the deep.",
				polite = "Oh, a boot.|I am so sorry, crab.",
				foodie = "A boot.|Not quite what I wanted for dinner.",
				_ = "A boot with a crab in it.|Hello, crab.",
			}, "sweat")
			s:mood("a", 1)
		else
			s:n("It was only seaweed again.")
			burst(s, "a", {
				easygoing = "Eh, it's about the sitting, really.",
				dreamy = "Hmm, the sea's keeping its fish today.|Fair enough.",
				sunny = "Nothing yet.|Next time, for sure.",
				gentle = "Nothing today.|That's all right, it's peaceful here.",
				bold = "Nothing yet, but I'm not giving up.",
				proud = "The fish are scared of me, clearly.",
				shy = "Um... nothing again.|That's okay.",
				cheeky = "the fish are on strike|i respect it",
				cool = "Nothing. I'll stay a bit.",
				prickly = "Seaweed again.|Ugh, fine, one more try.",
				dramatic = "The sea is LAUGHING at me.",
				bookish = "Fish bite more at dawn, actually.|I'll come back early.",
				gloomy = "Nothing again, as usual.",
				polite = "Only seaweed, I am afraid.|I will try a little longer.",
				foodie = "No fish.|I'll just get fish and chips later.",
				nervous = "Am I doing it wrong?|Maybe I'm doing it wrong.",
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
			polite = "I must apologise to the librarian in person.|Perhaps I will bring a cake.",
			nervous = "What's the fine?|What if there's a list, and I'm on it?",
			sunny = "{player}, look what I found!|Three weeks late, oops, ehehe.",
			gentle = "Oh my, it's three weeks late.|I'll take it back today and say sorry.",
			bold = "Three weeks late.|I'll take it back and face it, right?",
			dreamy = "Hmm... it was hiding under the sofa.|I forgot all about it.",
			easygoing = "Three weeks late, huh.|Eh, it'll keep another day.",
			cheeky = "three weeks late|i'm basically a pirate now",
			foodie = "There's a crumb in it.|And a bigger crumb.",
			_ = "{player}...|I'd forgotten I even had it.",
		}, "sweat")
		s:choice("I'll come with you.", function(c)
			c:n("You took it back together.")
			c:n("The librarian gave {a} a long look but no fine.")
			burst(c, "a", "That look was worse than a fine.|...Thanks for coming with me, {player}.", "heart")
			c:mood("a", 4)
			c:hearts("a", 1)
		end)
		s:choice("Read it first, then?", function(c)
			burst(c, "a", {
				bookish = "...You're right, I never finished it.|One more night won't hurt.",
				nervous = "Keep it another day? Wouldn't that be worse?|...Okay, fine, one more day.",
				cheeky = "a partner in crime|i like it, hehe",
				sunny = "Yes, let's read it together.|Then we'll take it back.",
				gentle = "Oh, that's a nice idea.|I'll read a little tonight.",
				bold = "Hah, good idea.|One more night, right?",
				dreamy = "Hmm... I'd like to know how it ends.",
				easygoing = "One more night won't hurt.|I'll read it in bed.",
				proud = "I'll finish it tonight.|I read very quickly.",
				shy = "Um... okay.|Just one more night.",
				cool = "Fair, one more night.",
				prickly = "Fine.|But if there's a fine, it's your fault.",
				dramatic = "Another night of SECRET reading.",
				gloomy = "Sure.|The fine can't get much worse.",
				polite = "Perhaps just one more night, then.",
				foodie = "One more night, with a cup of cocoa.",
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
			shy = "Everyone turns around when I walk past...",
			bold = "I'll walk them in.|Ten laps of the square should do it.",
			easygoing = "Eh, at least nobody can lose me now.",
			cool = "They'll stop eventually.",
			prickly = "Don't, I know.|I can hear them too.",
			dramatic = "I am announced wherever I go.",
			bookish = "Actually, it's the new soles.|They usually wear in after about a week.",
			gloomy = "And I paid good money for these.",
			foodie = "They sound like a rubber duck.|Now I want a bath, and a bun.",
			nervous = "Is it loud? It's loud, isn't it?|Can everyone hear it?",
			polite = "I do apologise for the noise, everyone.",
			sunny = "Squeak, squeak.|Ehehe, they're like little songs.",
			gentle = "Oh dear, they're a little noisy.|I'm sure they'll settle down.",
			dreamy = "Hmm... they sound like little birds.|I don't mind.",
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
			sunny = "Somebody's out there, {player}!|We have to write back.",
			dreamy = "It floated all this way just to say hello...",
			cool = "Huh, so there's someone out there.",
			prickly = "It's probably a joke.|...I'm keeping it, though.",
			dramatic = "A VOICE from across the sea.",
			bookish = "Actually, the current runs east at this time of year.|So it must have come from that way.",
			gloomy = "I hope someone wrote back to them.|Somebody should.",
			nervous = "Do we answer it?|What would we even say?",
			gentle = "Someone sent this all the way across the sea.|Isn't that sweet?",
			bold = "Someone's out there, {player}.|We're writing back, right?",
			easygoing = "It drifted all this way.|Eh, no rush, we can write back tomorrow.",
			proud = "Of course it washed up near me.|Good things always find me.",
			shy = "Um, {player}... someone wrote this.|Should we write back?",
			cheeky = "hello from the red lighthouse|ok, we're pen pals now",
			polite = "How lovely, someone has written to us.|We must write back.",
			foodie = "It came all this way.|We should send them a recipe back.",
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
			sunny = "{player}, you came!|Look, look, it's coming up.",
			cool = "Hm, it's a good one today.",
			prickly = "It's cold and early.|...Worth it, though, but don't tell anyone I said that.",
			dramatic = "A new day is BORN.",
			bookish = "Actually, that light left the sun about eight minutes ago.|So we're always seeing it a little late.",
			gloomy = "Huh, it's pretty.|I didn't expect that.",
			polite = "Thank you for coming up with me.|It is lovely, is not it?",
			foodie = "It looks just like an egg yolk.|Now I want breakfast.",
			nervous = "We didn't miss it, did we?|Oh, phew, there it is.",
			proud = "I chose the best spot on the hill, naturally.",
			shy = "Oh... you came.|It's so pretty, isn't it?",
			cheeky = "i got up before the sun|who's the early bird now",
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
			cheeky = "i locked myself out|the key's on the table, i can see it from here",
			proud = "Th-the door locked itself.|I had nothing to do with it.",
			shy = "I locked myself out...|Again.",
			cool = "The key's inside, and I'm out here.",
			prickly = "Go on, laugh about it.|Get it over with.",
			dramatic = "Shut out of my very own home.",
			gloomy = "Locked out, as usual, heh.",
			nervous = "I checked I had it.|I checked twice, so how did this happen?",
			sunny = "I locked myself out, ehehe.|The key's right there on the table.",
			gentle = "Oh my, I've locked myself out.|The key's on the kitchen table.",
			bold = "Locked out.|I'll find a way in, right?",
			dreamy = "Hmm... I was thinking about something else when I shut the door.",
			easygoing = "I locked myself out.|Eh, I'll sit here for a bit.",
			bookish = "I locked myself out.|That's the third time this year, actually.",
			polite = "I am afraid I have locked myself out.",
			foodie = "I locked myself out.|And my lunch is in there.",
			_ = "I've locked myself out.|The key's sitting on the kitchen table.",
		}, "sweat")
		s:choice("Try the back window?", function(c)
			if ctx.rng:chance(0.6) then
				c:n("The back window was open a crack, so {a} climbed in head first and landed in the laundry basket.")
				burst(c, "a", "I'm in!|Well, I'm in the laundry, but I'm in.", "sparkle", "cheer")
				c:mood("a", 4)
			else
				c:n("The back window was shut tight. {a} got halfway up the drainpipe and changed their mind.")
				burst(c, "a", "Nope, not doing that.|The neighbour has a spare, so I'll go and ask.", "sweat")
				c:mood("a", -1)
			end
		end)
		s:choice("I'll wait with you.", function(c)
			c:n("The spare key was in a teapot at the neighbour's, so you both stayed for tea.")
			burst(c, "a", {
				polite = "Thank you for waiting with me.|That was very kind of you.",
				prickly = "...Thanks for waiting.|You didn't have to.",
				sunny = "Thank you, {player}!|Next time I'm putting a key in a teapot too.",
				gentle = "Thank you for waiting with me.|That was a nice cup of tea, wasn't it?",
				bold = "Thanks for sticking around.|I owe you one.",
				dreamy = "Hmm... a key in a teapot.|Thank you, {player}.",
				easygoing = "Thanks, {player}.|That was the nicest way to be locked out.",
				proud = "Thank you.|I knew the spare was there, of course.",
				shy = "Um... thank you for waiting.|You didn't have to.",
				cheeky = "thanks, {player}|i'm locking myself out more often now",
				cool = "Thanks for waiting.",
				dramatic = "My HERO, {player}.",
				bookish = "Thank you, {player}.|I'm writing 'check for key' on my door, actually.",
				gloomy = "Thanks.|That was nicer than I deserved.",
				foodie = "Thanks, {player}.|And now I can have my lunch.",
				nervous = "Thank you, {player}.|I'm going to check for my key every morning now.",
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
			sunny = "{player}, good night.|Let's do something fun tomorrow, okay?",
			gentle = "Good night, {player}.|Don't stay up too late, okay?",
			bold = "Hey, {player}.|It's late, so get to bed.",
			dreamy = "Good night...|Did you see the moon's out?",
			easygoing = "Night, I'm already half asleep.",
			proud = "Good night, {player}.|I saw you working hard today.",
			shy = "Um...|Good night, {player}.",
			cheeky = "psst, {player}|night, hehe",
			cool = "Night.",
			prickly = "You're up late.|...Good night, then.",
			dramatic = "Good NIGHT, {player}, see you in the morning.",
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
				sunny = "Yep, but I'm going now.|Night night.",
				gentle = "I was just about to go to bed.|Good night, {player}, sleep well.",
				bold = "Yeah, but I'm going now.|Night.",
				dreamy = "I was looking at the moon...|Night, {player}.",
				easygoing = "Barely.|Night, {player}.",
				proud = "I don't need much sleep.|...Good night, though.",
				shy = "Um... yes.|Good night.",
				cheeky = "nope, i'm sleepwalking|night",
				dramatic = "The night is young.|...No, it isn't, good night.",
				bookish = "One more chapter.|Okay, two, good night.",
				gloomy = "Couldn't sleep, as usual.|Night.",
				polite = "Only a little longer.|Good night, {player}.",
				foodie = "I was having a snack.|Night, {player}.",
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
			sunny = "{player}, come and hide here with me!|There's room.",
			gentle = "It'll pass soon, it always does.",
			bold = "I'm making a run for it.|Any second now.",
			dreamy = "I like the sound it makes on the awning...",
			easygoing = "I'll wait it out.|I'm very good at waiting.",
			proud = "I left my umbrella at home on purpose.|I'm testing how waterproof my coat is.",
			shy = "I didn't bring an umbrella...",
			cheeky = "been here an hour|the baker keeps giving me looks",
			cool = "I forgot my umbrella.",
			prickly = "The forecast said sun.|The forecast lied.",
			dramatic = "Trapped by the storm, {player}.",
			bookish = "Rain this heavy usually stops within half an hour.",
			gloomy = "Of course it's raining.|I only just washed my hair.",
			polite = "I do hope the baker does not mind me standing here.",
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
				sunny = "Thank you, thank you!|Let's share an umbrella every time it rains.",
				gentle = "Thank you, {player}.|Come in for something warm, okay?",
				bold = "Thanks.|Your shoulder's soaked, though, sorry.",
				dreamy = "Hmm... the rain sounds different under an umbrella.|Thank you.",
				easygoing = "Thanks, {player}.|That was easier than running.",
				proud = "Thank you.|I'd have been fine, but thank you.",
				shy = "Um... thank you.|Your side got all wet.",
				cheeky = "thanks, {player}|you're wetter than me, though, hehe",
				cool = "Thanks, your shoulder's soaked.",
				dramatic = "You SAVED me from the storm.",
				bookish = "Thank you.|An umbrella only covers about half of two people, actually.",
				gloomy = "Thanks.|That was nice of you.",
				foodie = "Thanks, {player}.|Come in and have a bun to dry off.",
				nervous = "Thank you so much.|You're all wet, I'm so sorry.",
				_ = "Thanks, {player}.|Your side's all wet, look.",
			}, "heart")
			c:mood("a", 4)
			c:hearts("a", 1)
		end)
		s:choice("Run for it together?", function(c)
			c:n("You both ran, and you were both soaked by the end of the street.")
			burst(c, "a", {
				sunny = "Ehehe, we're so, so wet.|That was fun, though.",
				gentle = "Oh, my, look at us.|Come in and dry off before you catch a cold, okay?",
				bold = "Hah, that was a proper sprint.",
				dreamy = "Hmm... I quite like being this wet, actually.",
				easygoing = "Well, I can't get any wetter now, heh.",
				proud = "I won, obviously.|...Don't look at my hair.",
				shy = "I'm soaked...|That was kind of fun, though.",
				cheeky = "you're wetter than me, so i win",
				cool = "Well, we're soaked.|It was worth it.",
				prickly = "I'm soaked through.|...Fine, that was fun.",
				dramatic = "We ran through the STORM together.",
				bookish = "Actually, running gets you about as wet as walking.|I'd like to test that again some time.",
				gloomy = "Soaked, as usual.|That was fun, though, heh.",
				polite = "Oh, dear, we are drenched.|Do come in and dry off.",
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
			sunny = "I'm making snow angels.|Let's make a whole row of them together, {player}.",
			dreamy = "If I lie here long enough, I wonder if it'll snow on me...",
			bold = "That's six so far.|I'm doing the whole field.",
			easygoing = "I'm not getting up.|I live here now.",
			cool = "It's cold, but it's good.",
			prickly = "What?|It's snow, this is what you're supposed to do.",
			dramatic = "I am ONE with the winter!",
			gloomy = "I'll be cold for hours.|It's worth it, though.",
			nervous = "Is the snow deep enough for this?|I think I hit the ground a bit.",
			gentle = "Come and make one with me.|It's soft, I promise.",
			proud = "Look how neat my wings are.|It's harder than it looks.",
			shy = "Um... I'm making snow angels.|Do you want to make one too?",
			cheeky = "snow angel|or snow monster, if you squint",
			bookish = "The snow's about twenty centimetres deep, actually.|Perfect for this.",
			polite = "Please, join me, {player}.|There is plenty of snow.",
			foodie = "It's like lying in a giant bowl of sugar.",
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
				dramatic = "I've been wearing spring all day.",
				nervous = "Have they been there all morning?|But I talked to the baker like this!",
				sunny = "Petals? Ehehe, I'm a flower.|Let's go and get more.",
				gentle = "Oh my, have I?|Thank you for telling me, {player}.",
				bold = "Huh, petals.|I'm keeping them in.",
				dreamy = "Hmm... the tree must have liked me.",
				easygoing = "Eh, they can stay.|They're not hurting anyone.",
				bookish = "They fall about this time every year, actually.|I should have checked.",
				gloomy = "And nobody said anything?|Heh... figures.",
				polite = "Oh, thank you for telling me, {player}.",
				foodie = "Petals?|Are they the kind you can eat?",
				_ = "Oh, ha, how long have they been there?|Thanks, {player}.",
			}, "sweat")
			c:mood("a", 2)
		end)
		s:choice("(Say nothing, they suit them.)", function(c)
			c:n("{a} kept the petals in all day, and three people said they looked nice.")
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
		sunny = "You can see your roof in it, {player}!|Look, right there.",
		cool = "It came out well.",
		bookish = "I'll write the date on the back.|It'll be history one day.",
		gloomy = "It looks nicer than I thought it would.|The town, I mean.",
		dramatic = "Our whole town, in one frame.",
		polite = "I had two copies made.|I hoped you might like one.",
		gentle = "It's our whole town in one picture.|I'd like you to have one.",
		bold = "One photo, one try.|Came out great, right?",
		dreamy = "Hmm... the light was soft and gold.|It feels like a dream.",
		easygoing = "One photo, and an hour of sitting.|My kind of afternoon.",
		proud = "The finest photo of this town ever taken, naturally.",
		shy = "Um... it came out okay.|I hope you like it.",
		cheeky = "you can see your roof|and the hole in it, hehe",
		prickly = "It's just a photo.|...It's a really good photo.",
		foodie = "You can even see the bakery's chimney.|Smoke and everything.",
		nervous = "Is it blurry?|It's not blurry, is it?",
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
			dramatic = "The SKY is furious tonight.",
			gloomy = "The roof's going to leak.|I just know it will.",
			nervous = "W-was that close? It sounded really close.|Oh no, oh no, it was close.",
			bold = "I'm only under here because it's warm.|...That one was loud, though.",
			proud = "This blanket is for warmth, not for hiding.",
			easygoing = "Mm, I'm staying under here until it's over.",
			sunny = "{player}, it's so loud.|Come and sit under the blanket with me.",
			cheeky = "i'm not hiding|this is a blanket fort, very different",
			bookish = "Thunder is just air heating up very fast, actually.|...It's still loud, though.",
			polite = "Please excuse the blanket, {player}.|The storm is very loud tonight.",
			foodie = "I brought snacks under here.|It's a storm picnic.",
			_ = "Is it going to get louder?|It's going to get louder, isn't it?",
		}, "sweat")
		s:choice("I'll sit with you.", function(c)
			c:n("You sat with {a} until the storm passed, and they fell asleep sitting up.")
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
			proud = "That's a dense loaf.|It's how they do it in other countries, you know.",
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
			sunny = "My first loaf.|Ehehe, it's a bit heavy, but it's mine.",
			gentle = "Oh dear, it's a little heavy.|I'll try again, okay?",
			dreamy = "Hmm... it's like a stone from the beach.|A bread stone.",
			easygoing = "It's heavy, but it's bread.|I'll take it.",
			polite = "I am afraid it did not rise very much.",
			_ = "It's supposed to sound hollow.|It does not sound hollow.",
		}, "sweat")
		s:choice("Butter, lots of butter.", function(c)
			c:n("You both had a slice with a lot of butter, and it took a while.")
			burst(c, "a", {
				cheeky = "not bad, just chewy|good exercise for the jaw, hehe",
				sunny = "Not bad, not bad.|Butter fixes everything.",
				gentle = "It's not too bad with butter.|Thank you for eating it with me.",
				bold = "Chewy, but good.|Next one's going to be perfect.",
				dreamy = "Hmm... it's chewy.|Like eating a cloud made of rope.",
				easygoing = "Chewy, but there's butter, so fine.",
				proud = "With butter, it's practically perfect.",
				shy = "Um... is it okay?|Thank you for eating it.",
				cool = "Chewy, but okay.",
				prickly = "It's chewy.|Don't say it.",
				dramatic = "My jaw is TIRED, but my heart is full!",
				bookish = "The butter really helps, actually.|It softens the crust.",
				gloomy = "It's chewy.|But it's better than I thought.",
				polite = "Thank you for trying it.|It is better with butter.",
				foodie = "Mmm, with butter it's not bad.|With jam, it might be good.",
				nervous = "Is it okay?|You don't have to finish it.",
				_ = "Not bad, just chewy.|It's good exercise for the jaw.",
			}, "heart")
			c:mood("a", 4)
			c:hearts("a", 1)
		end)
		s:choice("It'd make a good doorstop.", function(c)
			burst(c, "a", {
				cheeky = "rude|...but yes, it would",
				sunny = "Ehehe, a doorstop.|I'll use it today.",
				gentle = "Oh dear, you're right.|I'll make it a doorstop, then.",
				bold = "Hah, fair.|It's going by the back door.",
				dreamy = "Hmm... a bread doorstop.|That's kind of nice.",
				easygoing = "Fair, it's not going anywhere.",
				proud = "It would be the finest doorstop in town.",
				shy = "Oh... okay.|It is very heavy.",
				cool = "Fair.",
				prickly = "Rude.|...You're right, though.",
				dramatic = "My bread, a DOORSTOP?|...Fine, it's perfect for that.",
				bookish = "It weighs about two kilograms, actually.|It would work.",
				gloomy = "Yeah.|That's all it's good for, heh.",
				polite = "That is fair, I suppose.",
				foodie = "A doorstop, and a snack in an emergency.",
				nervous = "Is it that bad?|...Okay, doorstop.",
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
			sunny = "{player}, quick question.|What colour should my door be? I can't choose.",
			cool = "{player}.|You pick a colour for my door.",
			prickly = "I need a colour for my door.|Don't overthink it, just say one.",
			dramatic = "A door says who you are, {player}.|What should mine say?",
			bookish = "I've narrowed it down to two colours.|I can't get any further, so you choose.",
			nervous = "What colour should I paint it?|What if I pick wrong and I'm stuck with it for years?",
			polite = "Hello, {player}.|May I ask your opinion on my door?",
			shy = "Um, {player}?|Which colour should I use for the door?",
			gentle = "{player}, could you help me choose?|What colour should my door be?",
			bold = "{player}, pick a colour for my door.|I'll paint it right now.",
			dreamy = "Hmm... {player}, what colour should my door be?|I keep changing my mind.",
			easygoing = "{player}, pick a colour for my door.|Any one, I'm not picky.",
			proud = "{player}, my door needs a new colour.|Choose well, it's an important door.",
			cheeky = "{player}, pick a colour|if i hate it, i'm blaming you",
			gloomy = "{player}, what colour should my door be?|Whatever I pick will probably look wrong.",
			foodie = "{player}, what colour for my door?|I was thinking the colour of butter.",
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
					sunny = "{Colour}, yes, yes!|Let's paint it together.",
					gentle = "{Colour}, oh, that's lovely.|Thank you, {player}.",
					bold = "{Colour}, done.|I'm starting now.",
					dreamy = "{Colour}... hmm, yes, I can see it.",
					easygoing = "{Colour}, sure, easy.|I'll start after a sit.",
					shy = "{Colour}...|Okay, I like it.",
					cheeky = "{colour}, ok, good choice|i was going to pick that anyway",
					dramatic = "{Colour}! The PERFECT colour.",
					bookish = "{Colour}, good, that's two coats, about an hour, actually.",
					polite = "{Colour}, thank you very much, {player}.",
					foodie = "{Colour}, like candy.|I like it.",
					nervous = "{Colour}?|Okay, if you're sure, {colour} it is.",
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
			sunny = "'{player}, thank you for everything! Come over for tea soon, and don't bring anything.'",
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
			foodie = "'Thank you for everything. I left a cookie under this note for you.'",
			nervous = "'Thank you for everything, if that's okay to say.'",
			_ = "'Thank you for the town, {player}.'",
		}, "heart")
		s:choice("Pin it up by the door.", function(c)
			c:n("You pinned it up by the door, and {a} went pink when they saw it there later.")
			c:hearts("a", 1)
			c:mood("a", 4)
		end)
		s:choice("Write one back.", function(c)
			c:n("You wrote one back, and {a} read it twice by the front door.")
			burst(c, "a", {
				prickly = "...You wrote back, okay.|I'm keeping it, obviously.",
				cool = "I got your note.|...Thanks.",
				shy = "...!|I got your note, and it's on my fridge now.",
				sunny = "You wrote back, you wrote back.|It's on my fridge now.",
				gentle = "Thank you for your note, {player}.|I'll keep it forever.",
				bold = "Got your note.|It's going on my wall, right next to the door.",
				dreamy = "Hmm... I read your note three times.|It's on my fridge now.",
				easygoing = "Got your note.|It's on the fridge, where all the good stuff goes.",
				proud = "Your note was very well written.|Almost as good as mine.",
				cheeky = "got your note|it's on my fridge, next to my best drawing",
				dramatic = "Your note is my TREASURE now.",
				bookish = "I got your note.|I filed it with my letters, under T for thank you.",
				gloomy = "I got your note.|Heh... nobody's ever written back before.",
				polite = "Thank you for your kind note, {player}.|I have put it on my fridge.",
				foodie = "Got your note.|It's on the fridge, next to the snacks.",
				nervous = "You wrote back?|Oh, thank you, I read it five times.",
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
			sunny = "The boats come in at five!|Let's go and watch them together.",
			gentle = "The boats are coming in soon.|Would you walk down to the harbour with me?",
			bold = "The boats come in at five.|You're walking down with me, right?",
			dreamy = "The boats come in at five...|I like watching them find their way into the harbour.",
			cool = "The boats come in soon.|Do you want to watch?",
			prickly = "I'm going to watch the boats come in.|You can come if you want, whatever.",
			dramatic = "The fleet returns at five.|We simply must be there.",
			gloomy = "The boats are coming in soon.|It's the best bit of my day, so will you come?",
			foodie = "The fresh fish comes off the boats at five.|We could watch, and then eat.",
			nervous = "W-would you come and watch the boats with me?|You don't have to, only if you want.",
			easygoing = "The boats come in at five.|Want to sit on the wall and watch? No rush.",
			proud = "The boats come in at five.|I know the best spot to watch from, naturally.",
			shy = "Um, the boats come in at five...|Would you like to watch with me?",
			cheeky = "boats at five|i bet you a bun the red one's first",
			bookish = "The boats come in at five, actually, give or take ten minutes.|Want to watch?",
			polite = "The boats will be coming in at five.|Would you like to watch them with me?",
			_ = "The boats come in soon, so will you come and watch?",
		}, "idea")
		s:choice("Let's go.", function(c)
			c:n("You sat on the harbour wall with {a} and watched the boats come in.")
			burst(c, "a", {
				cool = "It's good, right?",
				prickly = "See, it was worth it.|...Thanks for coming.",
				gloomy = "That was nice.|I mean it.",
				sunny = "Wasn't that great?|Let's come back tomorrow.",
				gentle = "That was so nice, {player}.|Thank you for coming with me.",
				bold = "Good, right?|Same time next week.",
				dreamy = "Hmm... the red sail is my favourite.|It looks like a little flame.",
				easygoing = "That was the best way to spend an evening.|Thanks, {player}.",
				proud = "I told you it was the best spot.|Thanks for coming.",
				shy = "Um... thank you for coming.|I liked that.",
				cheeky = "the red one was first|you owe me a bun",
				dramatic = "Every boat came HOME!|Thank you for coming, {player}.",
				bookish = "That was eleven boats, actually.|Thanks for coming.",
				polite = "Thank you for coming, {player}.|That was lovely.",
				foodie = "Now the fish is in.|Dinner's on me, {player}.",
				nervous = "They all made it back.|Oh, good, thanks for coming.",
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
				sunny = "Aw, okay.|Next time, then.",
				bold = "Fine, then I'll bring the boats to you.|...That was a joke.",
				gentle = "That's all right, {player}.|Another day, okay?",
				dreamy = "Oh... okay.|The boats will come again tomorrow.",
				easygoing = "No problem.|The boats come every day.",
				proud = "Your loss.|It's the best view in town.",
				cheeky = "boo|ok, another day",
				cool = "Okay, another time.",
				dramatic = "Then I'll watch ALONE.|...See you tomorrow.",
				bookish = "That's fine, they come in every day at five, actually.",
				gloomy = "Yeah, I figured.|Another time.",
				polite = "Of course, perhaps another time.",
				foodie = "Okay, I'll save you some fish.",
				nervous = "Oh, okay, sorry.|Was it a bad time to ask?",
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
			sunny = "I had something to tell you, and now it's gone.|It was good news, too.",
			dreamy = "I ran so fast the thought fell out of my head...",
			cheeky = "i forgot, hehe|hi, though",
			cool = "I forgot what it was.|Hi anyway.",
			prickly = "Don't look at me like that.|It'll come back to me.",
			dramatic = "It was important, {player}, and now it's lost FOREVER.",
			bookish = "Did you know walking through a doorway makes you forget things?|There's a study on it, and there was a door.",
			gloomy = "I've forgotten what it was, as usual.",
			nervous = "Was it something bad?|I hope it wasn't something bad.",
			gentle = "Oh my, I had something to tell you.|It's gone now, I'm sorry.",
			bold = "I had something important.|Give me a second, it'll come back.",
			easygoing = "I ran all this way and forgot.|Eh, it'll come back.",
			proud = "I had something very important to say.|It'll come back, my memory is excellent.",
			shy = "Um... I forgot.|S-sorry.",
			polite = "I do apologise, {player}.|I have forgotten what I wanted to say.",
			foodie = "It was about food, I know that much.|It's always about food.",
			_ = "I've forgotten what I was going to say.",
		}, "sweat")
		s:n("They walked off, and ten steps later they turned around.")
		s:say("a", "The bakery has cheese buns today, that was it!", "idea", "point")
		s:mood("a", 3)
		s:log("{a} ran over to tell you about the cheese buns.")
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
			cheeky = "eggs and green paint|and do not forget the ladder this time",
			sunny = "Eggs, flour, and green paint for the shed.|Oh, and ask about the ladder.",
			gentle = "Eggs, flour, and green paint for the shed.|And ask nicely about the ladder.",
			bold = "Eggs, flour, green paint.|And get that ladder.",
			dreamy = "Eggs... flour... green paint for the shed.|And something about a ladder.",
			easygoing = "Eggs, flour, and green paint, no rush.|And ask about a ladder sometime.",
			proud = "Eggs, flour, and the best green paint they have.|And a ladder.",
			shy = "Um... eggs, flour, green paint.|And ask about the ladder.",
			prickly = "Eggs, flour, green paint.|And don't forget the ladder again.",
			dramatic = "Eggs, flour, and GREEN paint for the shed!|And the ladder, never forget the ladder.",
			bookish = "Twelve eggs, two bags of flour, and green paint for the shed.|And ask about the ladder.",
			gloomy = "Eggs, flour, and green paint.|And a ladder, if anyone will lend me one.",
			foodie = "Eggs, flour, butter, more butter.|Oh, and green paint and a ladder.",
			nervous = "Eggs, flour, green paint, ladder.|Did I forget anything? I always forget something.",
			_ = "Eggs, flour, and green paint for the shed.|Oh, and ask about the ladder.",
		}, "question")
		s:choice("Huh?", function(c)
			burst(c, "a", {
				cool = "Oh, that was meant for me.|...Can I borrow your ladder on Saturday?",
				gentle = "Oh, my, I was reading aloud again, sorry, {player}.|Since you're here, could I borrow your ladder?",
				easygoing = "Oh, ha, I was talking to myself again.|...You don't have a ladder, do you?",
				polite = "Oh, I do apologise, that was my shopping list.|While I am here, may I borrow a ladder on Saturday?",
				prickly = "That wasn't for you.|...Okay, the last bit was, so can I borrow your ladder on Saturday?",
				sunny = "Oops, that was my list, ehehe.|Can I borrow your ladder on Saturday?",
				bold = "That was my list.|So, can I borrow your ladder on Saturday?",
				dreamy = "Oh... was I reading out loud?|Can I borrow your ladder, by the way?",
				proud = "That was my list, nothing to worry about.|Though I could use your ladder on Saturday.",
				shy = "Oh... sorry, that was my list.|Um, could I borrow your ladder?",
				cheeky = "that was my list|but since you asked, ladder, saturday, please",
				dramatic = "My list! You heard my SECRET list!|...Can I borrow your ladder?",
				bookish = "Sorry, that was my shopping list.|Could I borrow your ladder on Saturday, from nine to twelve?",
				gloomy = "That was my list.|You probably don't have a ladder, do you?",
				foodie = "That was my list.|Can I borrow a ladder, and maybe an egg?",
				nervous = "Oh no, was I reading out loud?|Sorry, can I borrow your ladder?",
				_ = "Oh, that was my list.|...Since you're here, can I borrow your ladder?",
			}, "sweat")
			c:n("On Saturday the shed went green, and so did one of {a}'s elbows.")
		end)
		s:choice("Ask who about the ladder?", function(c)
			burst(c, "a", {
				shy = "Um...|You, actually, if that's okay.",
				cheeky = "you, obviously|i was going to ask nicely, i promise",
				dramatic = "You, {player}, it was always you.|The shed awaits us on Saturday.",
				sunny = "You, of course.|Saturday, please, please.",
				gentle = "You, actually, if you don't mind.|Saturday, if that's all right.",
				bold = "You.|Saturday, okay?",
				dreamy = "Oh... you, I think.|Saturday?",
				easygoing = "You, actually.|Saturday, no rush.",
				proud = "You, naturally.|Who else has a good ladder?",
				cool = "You, on Saturday.",
				prickly = "You, obviously.|Don't make me ask twice.",
				bookish = "You, actually.|You're the only one on my list with a ladder.",
				gloomy = "You.|If that's okay, which it probably isn't.",
				polite = "You, if you would be so kind.|On Saturday, please.",
				foodie = "You.|I'll pay you in muffins.",
				nervous = "Y-you, if that's okay?|Only on Saturday.",
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
			sunny = "Oh, um, it's nothing.|Never mind, ehehe.",
			gentle = "Oh, never mind, it's nothing.|Sorry to bother you.",
			bold = "Never mind.|It's not important.",
			dreamy = "Hmm... never mind.",
			easygoing = "Eh, never mind.",
			proud = "It's nothing.|Forget I said anything.",
			cheeky = "nothing|forget it",
			dramatic = "No, NO, it's nothing!",
			bookish = "Actually, never mind.|It's not important.",
			polite = "I am sorry, it is nothing.",
			foodie = "Never mind.|It's not about food, so it can wait.",
			_ = "Never mind.",
		}, "sweat")
		s:n("You ask what it is.")
		burst(s, "a", {
			shy = "I sat on the bench you put by the pond this morning.|...It's a good bench, that's all.",
			cool = "The lamp by my door works again, since you fixed it.|...Thanks.",
			prickly = "It's nothing.|...Your garden looks nice, but don't let it go to your head.",
			gloomy = "I had a good day, and I wanted to tell someone.|You were the someone, heh.",
			nervous = "I wanted to say thank you for the house.|Sorry, that's all, sorry.",
			sunny = "Nothing, I just wanted to say hi.|Hi, ehehe.",
			dreamy = "The light on the water just now went all gold...|You missed it.",
			gentle = "I just wanted to say the town feels like home now.|Thank you for that.",
			bold = "Your fence looks good, that's all.|Nice work.",
			easygoing = "I had a really good nap in the park.|I wanted to tell someone.",
			proud = "I noticed you planted flowers by the square.|Good choice, very good choice.",
			cheeky = "i saw you trip on the path earlier|i'm not telling anyone, hehe",
			dramatic = "The sunset tonight was the most BEAUTIFUL thing!|I had to tell someone.",
			bookish = "I counted the houses in town this morning.|There are more than last month, actually.",
			polite = "I only wanted to say thank you for the new bench.|It is very comfortable.",
			foodie = "The bakery's new bread is amazing.|I needed someone to know.",
			_ = "Nothing much, but the town looks nice today.|I wanted to say it to someone.",
		}, "heart")
		s:choice("Thanks for telling me.", function(c)
			burst(c, "a", {
				cool = "Okay.|Later.",
				prickly = "Yeah, well, bye.",
				polite = "Thank you for listening.|Have a lovely day, {player}.",
				proud = "Hmph, well, now you know.",
				sunny = "Okay, bye bye!|See you tomorrow.",
				gentle = "You're welcome.|Take care, okay?",
				bold = "Yeah, see you.",
				dreamy = "Mm... okay.|Bye, {player}.",
				easygoing = "Sure, bye, {player}.",
				shy = "Oh... okay.|Bye.",
				cheeky = "ok, bye|don't miss me too much",
				dramatic = "Goodbye, {player}, until next TIME.",
				bookish = "Okay, bye.|I'll tell you if anything else happens, actually.",
				gloomy = "Okay.|Bye, {player}.",
				foodie = "Okay, bye.|I'm off for a snack.",
				nervous = "Okay, sorry for bothering you.|Bye.",
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
				polite = "Oh, I would rather not, but thank you for asking.",
				sunny = "No way, once is enough, ehehe.",
				gentle = "Oh, I'll say it again some other time.",
				bold = "No.|Once is plenty.",
				dreamy = "Hmm... it's gone now.|Words do that.",
				easygoing = "Nah, once is enough for me.",
				cheeky = "nope|you'll have to wait for the next one",
				dramatic = "Never AGAIN.|...Okay, maybe once more, someday.",
				bookish = "I'd rather not, actually.|Once is enough.",
				gloomy = "No.|Heh... once was hard enough.",
				foodie = "No, but I'll say it over lunch sometime.",
				nervous = "A-again? No, no, once was enough.",
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
			sunny = "{player}.|{player}, where are you? Hello?",
			shy = "{player}?|Sorry, it's nothing...",
			prickly = "{player}, hello?|Fine, ignore me, then.",
			bold = "{player}, where are you?|I'm coming to look for you.",
			gentle = "{player}?|Are you all right? I was getting worried.",
			dreamy = "{player}...?|Hmm, maybe you're out looking at clouds.",
			easygoing = "{player}?|Eh, they'll turn up.",
			proud = "{player}, I'm looking for you.|It's not like you to ignore me.",
			cheeky = "{player}|{player}|ok i'll keep shouting",
			cool = "{player}, where are you?",
			dramatic = "{player}, where ARE you?|Have you vanished?",
			bookish = "{player}?|I've checked four streets already, actually.",
			polite = "Excuse me, {player}?|Are you nearby?",
			foodie = "{player}?|I brought snacks, so come out.",
			_ = "{player}?|...Are you around?",
		}, "question")
		s:n("You were up on a roof fixing something, and you call down.")
		burst(s, "a", {
			gloomy = "Oh, right, a roof.|That makes sense, I thought you'd had enough of me.",
			nervous = "Oh, you're on a roof, okay, good.|Please be careful up there, sorry.",
			sunny = "You're on the roof, can I come up?|...I'll take that as a no, so maybe later.",
			shy = "Oh...|Sorry, I'll wait down here.",
			prickly = "A roof, of course.|...Come down for lunch, I made too much.",
			bold = "Hah, there you are.|I'll hold the ladder steady for you.",
			gentle = "Oh, there you are.|Please be careful up there, okay?",
			dreamy = "Oh... you're on the roof.|You're closer to the clouds up there.",
			easygoing = "Oh, a roof.|Cool, I'll wait down here.",
			proud = "A roof, of course.|I would have looked there next.",
			cheeky = "you're on a roof|don't fall, i'm not catching you",
			cool = "A roof, okay, be careful.",
			dramatic = "You're on the ROOF? Come down before I faint.",
			bookish = "On a roof, of course.|I should have checked the roofs, actually.",
			polite = "Oh, there you are.|Please do be careful up there.",
			foodie = "Oh, you're on a roof.|Come down when you're hungry.",
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
			prickly = "{player}, about that photo.|Throw it out, now.",
			cool = "You've got a photo of mine.|Throw it out, please.",
			shy = "Um, {player}...|I think one of my photos went to you by mistake, so please don't look at it.",
			proud = "I hear a photo of me is going around.|It is not my best angle, so return it at once.",
			cheeky = "that photo of me|it's art, but also give it back",
			dramatic = "There is a photograph of me ASLEEP, {player}!|Destroy it, I beg you.",
			sunny = "{player}, that photo of me, ehehe.|Please give it back.",
			gentle = "Oh, {player}, I think you've got a photo of mine.|Could you give it back, please?",
			bold = "You've got a photo of me.|Hand it over, right?",
			dreamy = "Hmm... a photo of me went to your house.|Was I dreaming in it?",
			easygoing = "I hear you've got a photo of me sleeping.|Eh, at least I look comfy.",
			bookish = "{player}, one of my photos went to your house.|It was number twelve on the roll, actually.",
			gloomy = "There's a photo of me at your place.|It's probably awful.",
			polite = "Excuse me, {player}.|I believe one of my photos went to you by mistake.",
			foodie = "{player}, there's a photo of me at yours.|Was I holding a sandwich in it?",
			nervous = "{player}, there's a photo of me at yours!|Did you look? Please say you didn't look.",
			_ = "{player}, there's a photo of me at yours.|Please don't look at it.",
		}, "sweat")
		s:choice("Already threw it out.", function(c)
			burst(c, "a", {
				prickly = "Good.|...You looked, didn't you?",
				shy = "Oh, thank goodness.|Thank you.",
				proud = "Good, then we'll say no more about it.",
				sunny = "Thank you, thank you!|You're the best.",
				gentle = "Oh, thank you, {player}.",
				bold = "Good.|...You looked, right?",
				dreamy = "Oh... good.|Did I look peaceful, at least?",
				easygoing = "Thanks.|It was probably a nice nap, though.",
				cheeky = "good|...you looked, didn't you, hehe",
				cool = "Good, thanks.",
				dramatic = "My DIGNITY is saved.",
				bookish = "Thank you.|I'll check the next roll more carefully, actually.",
				gloomy = "Good.|You looked, though, didn't you?",
				polite = "Thank you very much, {player}.",
				foodie = "Thanks.|I'll buy you a bun for that.",
				nervous = "Oh, thank goodness.|You didn't look, right?",
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
				cheeky = "i know|frame it",
				sunny = "It is? Ehehe, okay.|You can keep it, then.",
				gentle = "Oh, you're sweet.|All right, you can keep it.",
				bold = "Hah, fine.|Keep it, but don't show anyone.",
				dreamy = "Hmm... I do look peaceful.|Keep it, then.",
				easygoing = "Eh, I do look comfy.|Keep it.",
				dramatic = "It's a MASTERPIECE?|...Fine, keep it, but show nobody.",
				bookish = "It is quite a good photo, actually.|Keep it, but don't show anyone.",
				gloomy = "It's not.|...Fine, keep it.",
				polite = "That is kind of you to say.|You may keep it, but please show nobody.",
				foodie = "Is there drool?|...Keep it, but nobody sees it.",
				nervous = "R-really?|Okay, keep it, but please, please don't show anyone.",
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
		s:n("{a} slipped by the fountain and sat right down in the water, and only you saw.")
		burst(s, "a", {
			shy = "...|Please don't tell anyone, please.",
			proud = "That didn't happen, do you understand?|It did not happen.",
			easygoing = "Well, I needed a bath anyway.|...Don't tell anyone, though.",
			prickly = "Not one word.|Not a single word, got it?",
			cool = "You saw nothing.",
			dramatic = "My dignity, {player}, gone down the drain with the wishing coins.|Tell no one.",
			nervous = "Did anyone else see? Only you?|Okay, please don't tell anyone.",
			polite = "Oh, dear.|I would be grateful if we kept that between us.",
			gloomy = "Of course I fell in.|You didn't see that, okay?",
			sunny = "Ehehe, oops.|Please don't tell anyone, okay?",
			gentle = "Oh my, I'm all wet.|Let's keep this between us, okay?",
			bold = "Right, that didn't happen.|Got it?",
			dreamy = "Hmm... the water's quite nice.|Don't tell anyone, though.",
			cheeky = "i meant to do that|...please don't tell anyone",
			bookish = "The fountain's only about forty centimetres deep, actually.|Please don't tell anyone.",
			foodie = "My sandwich is wet now.|Don't tell anyone, please.",
			_ = "You didn't see that, okay?",
		}, "sweat")
		s:choice("Your secret's safe.", function(c)
			burst(c, "a", {
				shy = "Thank you...|I'm going home to change.",
				proud = "Good.|You've earned a little of my trust.",
				prickly = "Good.|...Thanks.",
				sunny = "Thank you, thank you!|I'm going home to dry off.",
				gentle = "Thank you, {player}.|I'll go and change now.",
				bold = "Good.|I'm going home to dry off.",
				dreamy = "Thank you...|I'll go and dry off in the sun.",
				easygoing = "Thanks.|I'm going home for a warm nap.",
				cheeky = "thanks|you're a good friend, for once",
				cool = "Thanks, going home.",
				dramatic = "You are a TRUE friend.",
				bookish = "Thank you.|I'll walk home the back way, actually.",
				gloomy = "Thanks.|That's nice of you.",
				polite = "Thank you very much, {player}.",
				foodie = "Thanks.|I'm going home for a hot drink.",
				nervous = "Thank you, thank you.|Nobody else saw, right?",
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
				sunny = "Two coins, ehehe.|So it wasn't all bad.",
				gentle = "Oh, you.|Two, actually, and don't tell anyone.",
				bold = "Two.|Don't tell anyone, right?",
				dreamy = "Hmm... two coins and a leaf.|Don't tell anyone.",
				easygoing = "Two, actually, so I came out ahead.",
				cool = "Two, don't tell anyone.",
				dramatic = "TWO coins.|...Please tell no one.",
				bookish = "Two, both from last year, actually.|Don't tell anyone.",
				gloomy = "Two.|At least something good came of it.",
				polite = "Two, I am afraid.|Please do not tell anyone.",
				foodie = "Two, enough for a bun.|Don't tell anyone.",
				nervous = "Two, but should I put them back?|Please don't tell anyone.",
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
			sunny = "{player}, I'm home.|There was a dog in a hat on the last ferry.|Good night.",
			gentle = "I'm home, {player}.|The path by the harbour was slippery, so be careful there tomorrow, okay?|Sleep well.",
			bold = "I'm home, and I walked the cliff path in the dark.|Night.",
			dreamy = "I'm home...|The moon followed me the whole way.",
			easygoing = "I'm home, I took the long way on purpose.|Night.",
			proud = "Home safe, {player}.|Three people said they liked my hat today, good night.",
			shy = "I'm home.|The square was loud today, but it was okay.",
			cheeky = "home|i took a lemon off the tree by the market, don't tell|night",
			cool = "I'm home.|Night.",
			prickly = "I'm home, in case you were wondering.|...Not that you were, but good night.",
			dramatic = "I have returned, and the harbour lights were magnificent tonight.|See you in the morning.",
			bookish = "I'm home, and I saw a grey heron on the way.|Good night, {player}.",
			gloomy = "I'm home, and nothing went wrong today.|That's weird, heh.",
			polite = "Good night, {player}, I am home safe.|Thank you for today.",
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
			sunny = "...That's all, good night!",
			gentle = "...That's all, sleep well, okay?",
			bold = "...That's all. Night.",
			easygoing = "...That's it, night.",
			proud = "...That's all, I just wanted you to know I'm home.",
			cool = "...Night.",
			prickly = "...That's all, don't make it weird.",
			dramatic = "...That's ALL, good night.",
			bookish = "...That's all, I just wanted to say good night twice.",
			polite = "...That is all, good night, {player}.",
			foodie = "...That's all, night, I'm off to make toast.",
			nervous = "...That's all, sorry, good night.",
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
			gentle = "Oh, {player}, there you are.|{what} {todo}|Take care of yourself, okay?",
			bold = "{player}, listen.|{what} {todo}",
			polite = "Excuse me, {player}, and sorry to stop you.|{what} {todo}|Do take care today.",
			nervous = "S-sorry, {player}, it's just a quick thing.|{what} {todo}|That's all, sorry.",
			prickly = "{player}.|{what} {todo}|Don't make me say it twice.",
			sunny = "{player}, quick!|{what} {todo}",
			dreamy = "Hmm... {player}.|{what} {todo}",
			easygoing = "Hey, {player}.|{what} {todo}",
			proud = "{player}, some advice.|{what} {todo}",
			shy = "Um, {player}...|{what} {todo}",
			cheeky = "psst, {player}|{what} {todo}",
			dramatic = "{player}, a WARNING.|{what} {todo}",
			bookish = "{player}, a quick note.|{what} {todo}",
			gloomy = "{player}.|{what} {todo}|Just so you know.",
			foodie = "{player}, before you go.|{what} {todo}",
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
		s:n("It's late, and {a} is sitting outside their door, looking up.")
		burst(s, "a", {
			dreamy = "Do you think the bakery oven gets lonely at night?|It stays warm for hours after everyone goes home...|Maybe that's why the bread is so good.",
			gloomy = "Do you ever think about how far away the stars are?|They're not thinking about us at all, heh.|...Sorry, it's a night thought.",
			easygoing = "The sea's louder at night, have you noticed?|Or maybe everything else is just quieter, and either way it's nice.",
			bookish = "Did you know some of those stars might not be there anymore?|Their light has been travelling for ages, and I find that oddly calming.",
			shy = "{player}, sorry, are you awake?|The square looks nice with nobody in it.",
			cool = "{player}.|It's quiet tonight, and that's good.",
			sunny = "{player}, you're up too.|Look how many stars there are, I've counted thirty already.",
			proud = "I've decided which star is mine, that bright one there.|You can have the one next to it.",
			prickly = "I can't sleep, so don't ask why.|...The sky's nice, though.",
			nervous = "Do you think all the boats are in?|I counted them, and I think they're all in, okay.",
			polite = "Good evening, {player}, I hope I am not keeping you.|It is such a clear night.",
			foodie = "If the moon were a cheese, what cheese would it be?|I've been thinking about it for an hour.",
			dramatic = "Look at the night, {player}.|The whole sky is SHOWING off.",
			gentle = "Oh, {player}, are you still up?|The air's so soft tonight.",
			cheeky = "look at the moon|it looks like it's judging the gulls",
			bold = "I can't sleep, so I've walked the whole harbour twice.|You're up too, right? Come for a walk.",
			_ = "It's funny how quiet it gets at night.|You can hear the boats knocking together.",
		}, "zzz")
		s:choice("Go to bed, you.", function(c)
			burst(c, "a", {
				prickly = "You first.|...Fine, night.",
				cool = "Okay.|You too.",
				sunny = "Okay, okay.|Night night, {player}.",
				gentle = "All right, I'll go in.|You get some sleep too, okay?",
				bold = "Fine, I'm going.|You too, right now.",
				dreamy = "Mm... five more stars, then bed.",
				easygoing = "Yeah, bed sounds good.|Night.",
				proud = "I was about to, naturally.|Good night.",
				shy = "Oh... okay.|Good night.",
				cheeky = "you first|...ok fine, night",
				dramatic = "To BED, then.|Good night, {player}.",
				bookish = "You're right, it's nearly one o'clock, actually.|Night.",
				gloomy = "Yeah, okay.|Night, {player}.",
				polite = "You are right.|Good night, {player}.",
				foodie = "After one more snack.|Night, {player}.",
				nervous = "Okay, I'll check the door first.|Good night.",
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
				sunny = "That tomorrow's going to be a good day.|I can tell, good night.",
				gentle = "That I'm glad we're all here together.|Good night, {player}.",
				bold = "That this town's the best one around.|Night.",
				easygoing = "That tomorrow can be slow too.|Night, {player}.",
				proud = "That I chose the right town, naturally.|Good night.",
				cheeky = "that i should prank the baker tomorrow|night, hehe",
				cool = "That this is a good place. Night.",
				dramatic = "That I'll NEVER leave this town.|Good night.",
				bookish = "That I've lived here two hundred days now, actually.|Good night.",
				polite = "That I am very happy here.|Good night, {player}.",
				foodie = "That breakfast is in seven hours.|Good night.",
				nervous = "That I hope tomorrow goes okay.|It will, right? Good night.",
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
			dramatic = "{player}, look at the biggest carrot this island has ever grown.|...It's about the size of my thumb.|But it's a very GOOD thumb.",
			sunny = "{player}, look at my carrot, it's this big.|...Okay, it's small, but it's mine.",
			nervous = "I grew a carrot, but it's tiny.|Is it meant to be this tiny?",
			foodie = "This is the first carrot from my patch, and it's small.|Small ones are sweeter, everyone knows that.",
			proud = "My first carrot, perfectly formed.|Small, but perfect.",
			cheeky = "close your eyes|ok, open them|it's a carrot, a baby one",
			gentle = "{player}, look what I grew.|It's small, but I'm proud of it.",
			bold = "{player}, my first carrot.|Small, but tough, right?",
			dreamy = "Hmm... I grew a carrot.|It's a very small one.",
			easygoing = "My first carrot.|It took its time, like me.",
			shy = "Um, {player}... I grew a carrot.|It's a bit small.",
			cool = "My first carrot, it's small.",
			prickly = "Don't laugh.|It's my first carrot.",
			bookish = "My first carrot, about four centimetres, actually.|Not bad for clay soil.",
			gloomy = "I grew a carrot.|It's tiny, as expected.",
			polite = "Good afternoon, {player}.|May I show you my very first carrot?",
			_ = "My first carrot is small.|It's still a carrot, though.",
		}, "sparkle", "point")
		s:choice("Best carrot I've seen.", function(c)
			burst(c, "a", {
				dramatic = "Thank you, finally someone with eyes.",
				sunny = "I know, I know!|I'm going to grow a hundred more.",
				nervous = "Really? Oh, okay, thank you.|Maybe I'll grow a bigger one next time.",
				proud = "I know.|Say it again, a little louder.",
				gentle = "Oh, thank you, {player}.|That's very sweet.",
				bold = "Hah, right?|Next year they'll be huge.",
				dreamy = "Oh... thank you.|I'll grow another one for you.",
				easygoing = "Thanks, it didn't even need much work.",
				shy = "Really?|Thank you, {player}.",
				cheeky = "you're just saying that|but i'll take it",
				cool = "Thanks.",
				prickly = "Obviously.|...Thanks.",
				bookish = "Thank you, I'll write it in my garden notes.",
				gloomy = "Really?|Heh... that's nice to hear.",
				polite = "Thank you very much, {player}.",
				foodie = "Thanks, I'm going to eat it with a little butter.",
				_ = "Right? I'm going to frame it.|Then I'm going to eat it.",
			}, "heart", "cheer")
			c:mood("a", 5)
			c:hearts("a", 1)
		end)
		s:choice("Is it finished growing?", function(c)
			burst(c, "a", {
				dramatic = "It is FINISHED!|It simply chose to stay humble.",
				foodie = "It's finished, it's a snack carrot.|That's a real thing, I promise.",
				proud = "Th-that's the size they come!|Anyway, next year I'm growing a pumpkin.",
				sunny = "Yep, that's it.|Small and happy.",
				gentle = "I think so.|It did its best.",
				bold = "It's done.|Next one will be bigger.",
				dreamy = "Hmm... maybe it just likes being small.",
				easygoing = "It's done.|It knew when to stop.",
				shy = "Um... I think so.|Is that bad?",
				cheeky = "it's done|it's a baby carrot, and it's proud",
				cool = "It's done, it's small.",
				prickly = "Yes, it's finished.|Don't say anything.",
				bookish = "It's done, the leaves turned yellow, actually.|It's just small.",
				gloomy = "It's done.|This is as good as it gets, heh.",
				polite = "I believe it has finished growing, yes.",
				nervous = "Is it finished? I think so?|Oh no, should I have waited?",
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
			sunny = "{player}, {player}, watch this!|I learned it this morning.",
			proud = "{player}, watch closely.|You'll want to remember this.",
			bold = "Watch this cartwheel, {player}.|You're watching, right?",
			shy = "Um, {player}?|Could you watch me, just once? Don't laugh...",
			dramatic = "Ladies, gentlemen and gulls, I give you THE CARTWHEEL!",
			cheeky = "watch this|no, really, watch",
			cool = "{player}.|Watch this.",
			nervous = "O-okay, I'm going to try a cartwheel.|Stand back, further than that.",
			gentle = "{player}, would you watch me for a moment?|I learned a cartwheel.",
			dreamy = "Hmm... {player}, watch this.|I think I can do a cartwheel.",
			easygoing = "{player}, watch this.|Just one, I'm saving my energy.",
			prickly = "Watch this, {player}.|And don't laugh if it goes wrong.",
			bookish = "{player}, watch this.|I read that it's all about the hands, actually.",
			gloomy = "{player}, watch this.|It'll probably go wrong.",
			polite = "{player}, if you have a moment, please watch this.",
			foodie = "{player}, watch this.|I haven't eaten yet, so I'm light.",
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
				sunny = "Ehehe, half a cartwheel!|Next time, a whole one.",
				gentle = "Oh my, I fell.|I'm all right, though.",
				bold = "That was half.|I'll get the other half tomorrow.",
				dreamy = "Hmm... the grass is soft, at least.",
				easygoing = "Half is enough for today.",
				shy = "Oh no...|Please don't tell anyone.",
				cheeky = "that was a new move|it's called the sit down",
				dramatic = "I have FALLEN!|...But I'll get up again.",
				bookish = "I didn't push hard enough with my left hand, actually.",
				polite = "I am afraid that did not go well.",
				foodie = "I think I need a snack first.",
				nervous = "Did anyone else see?|Oh no, oh no.",
				_ = "That was half of one, and halves count.",
			}, "sweat")
		end
		s:choice("Do it again.", function(c)
			burst(c, "a", {
				proud = "Naturally.|Count them this time.",
				shy = "...!|Okay, once more.",
				sunny = "Okay, one more time.",
				gentle = "All right, one more.|Watch carefully.",
				bold = "Again? Sure, watch this.",
				dreamy = "Mm... one more, then.",
				easygoing = "One more, then I'm lying down.",
				cheeky = "again? ok, but this one costs a bun",
				cool = "One more.",
				prickly = "Fine, one more.|Don't blink.",
				dramatic = "An ENCORE.",
				bookish = "One more, and I'll count the seconds, actually.",
				gloomy = "One more.|Don't expect too much.",
				polite = "Of course, one more.",
				foodie = "One more, then lunch.",
				nervous = "A-again? Okay, okay, one more.",
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
		s:n("{a} is sitting by a little fire on the beach with a bag of marshmallows.")
		burst(s, "a", {
			bold = "{player}, over here.|The fire's going, so sit down.",
			gentle = "Come and get warm, {player}.|There's room on the log.",
			sunny = "{player}, come sit by the fire.|I've got marshmallows.",
			dreamy = "The sparks go up like they're joining the stars...|Will you sit?",
			easygoing = "Pull up a log.|I've been here two hours, and it's great.",
			proud = "I built this fire myself, with the very first match.|Sit down and admire it.",
			shy = "Oh, {player}...|Um, do you want to sit? You don't have to.",
			cheeky = "marshmallow?|i've only burned six",
			cool = "There's a fire.|Sit down if you want.",
			prickly = "You're letting the cold in, standing there.|Just sit down.",
			dramatic = "The fire calls to us, {player}.|Sit, and listen to it crackle.",
			bookish = "Driftwood sometimes burns blue.|It's the salt, so sit and watch for it.",
			gloomy = "It'll go out eventually.|Will you sit with me until it does?",
			polite = "Good evening, {player}.|Would you like to join me by the fire?",
			foodie = "I've got bread on a stick.|Well, it's toast on a stick now, do you want one?",
			nervous = "Is it too big?|No, it's not too big, I checked, so sit if you want.",
			_ = "Sit for a bit, {player}, it's warm.",
		}, "heart", "wave")
		s:choice("Move over.", function(c)
			c:n("You sat by the fire with {a} until it burned down.")
			burst(c, "a", {
				cool = "It was a good night for it.",
				prickly = "That was all right.|...Same time next week.",
				sunny = "That was so nice.|Let's do it again next week.",
				gentle = "That was lovely, {player}.|Let's do it again, okay?",
				bold = "Good fire, right?|Next week, same spot.",
				dreamy = "Hmm... the stars were nice tonight.",
				easygoing = "That was perfect.|I nearly fell asleep.",
				proud = "Best fire on the beach, naturally.",
				shy = "That was nice...|Thank you for staying.",
				cheeky = "i only burned seven marshmallows|that's a record",
				dramatic = "What a MAGICAL night.",
				bookish = "That was about three hours, actually.|It didn't feel like it.",
				gloomy = "That was nice.|I mean it.",
				polite = "Thank you for keeping me company, {player}.",
				foodie = "That was the best toast I've ever had.",
				nervous = "Is the fire really out?|Okay, it's out, that was nice.",
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
			polite = "Excuse me, {player}, I am sorry to bother you.|Did I leave a little green notebook here?",
			nervous = "S-sorry, {player}, did I leave my notebook here?|It's small and green and full of lists, sorry.",
			bookish = "{player}, have you seen my notebook?|Every bird I've seen this year is in it, all two hundred and six.",
			dramatic = "{player}, my whole life is in that notebook.|Have you seen it?",
			sunny = "{player}, have you seen my notebook?|It's green, and it's got stickers on it.",
			gentle = "{player}, sorry to bother you.|Have you seen my little green notebook?",
			bold = "{player}, did I leave my notebook here?|It's green, I need it.",
			dreamy = "Hmm... {player}, have you seen my notebook?|I wrote a dream in it this morning.",
			easygoing = "{player}, did I leave my notebook here?|No rush, I just need it eventually.",
			proud = "{player}, I seem to have lost my notebook.|It's very important, naturally.",
			shy = "Um, {player}... did I leave my notebook here?|It's small and green.",
			cheeky = "{player}, did you steal my notebook|jk, but have you seen it",
			cool = "{player}. Have you seen a green notebook?",
			prickly = "{player}, have you seen my notebook?|Don't say I'm always losing things.",
			gloomy = "{player}, I lost my notebook.|It's probably gone forever.",
			foodie = "{player}, have you seen my notebook?|All my recipes are in it.",
			_ = "{player}, did I leave my notebook here?|It's green, about this big.",
		}, "question")
		s:choice("Let's look around.", function(c)
			c:n("You both looked under every cushion. Then {a} sat down, and something crackled.")
			burst(c, "a", "Oh, it was in my back pocket.|It was there the whole time.", "sweat")
			c:mood("a", 2)
			c:hearts("a", 1)
		end)
		s:choice("Is that it, under your arm?", function(c)
			burst(c, "a", {
				polite = "...|So it is, I do apologise, I will go home now.",
				dramatic = "...|We will never speak of this.",
				sunny = "...|Ehehe, oops, so it is.",
				gentle = "...|Oh my, so it is, I'm sorry.",
				bold = "...|Yeah, okay, it is.",
				dreamy = "...|Oh... it was here all along.",
				easygoing = "...|Huh, so it is, that's easy, then.",
				proud = "...|I was testing you, naturally.",
				shy = "...|Oh no, so it is, sorry.",
				cheeky = "...|i was checking if you'd notice",
				cool = "...|So it is.",
				prickly = "...|Don't say anything.",
				bookish = "...|So it is, I was holding it the whole time, actually.",
				gloomy = "...|Of course it was, heh.",
				foodie = "...|So it is, and there's a crumb on the cover.",
				nervous = "...|Oh no, it was, I'm so sorry.",
				_ = "...|Yes, it is, and I'm going home now.",
			}, "sweat", "laugh")
			c:mood("a", 1)
		end)
		s:log("{a} lost a notebook that wasn't lost.")
		return s:done()
	end,
})

-- lately: things that stay with them for a few days ---------------------------------------------------
--
-- The user: "along with their conversations and events having more impact, such as remembering if
-- they joined a band, started wearing a new accessory (temporarily), etc." The first few here start
-- something that lasts a few days (Sim/Memory: a pet, a garden, a pen pal, training for the race,
-- something new to wear); the rest come back to it while it lasts (Kit's W{ memory = ... }), as
-- the band's own show does for a villager in a band.

local PET_NAMES = { "Biscuit", "Pebble", "Noodle", "Muffin", "Socks", "Waffle", "Button", "Pickle" }

-- (a cat that moves in has an event of its own, "stray")
local STRAYS = {
	{ kind = "puppy", prop = "dog", how = "A muddy puppy with no collar followed {a} home from the harbour." },
	{ kind = "rabbit", how = "A rabbit has been living under {a}'s porch, and today it hopped inside." },
}

event({
	id = "foundpet",
	when = "day",
	weight = W({
		base = 0.12,
		traits = { kind = 0.25 },
		cond = function(ctx, a)
			return ctx.memory(a, "pet") == nil
		end,
	}),
	scene = function(ctx, a)
		local stray = ctx.rng:pick(STRAYS)
		local s = K.scene(ctx, "A new friend"):with({ pet = stray.kind })
		if stray.prop then
			s:prop(stray.prop, "a")
		end
		s:n(stray.how)
		burst(s, "a", {
			sunny = "{player}, look who came to stay!|I'm keeping this {pet}, and it needs a name, quick!",
			gentle = "Oh, {player}, the poor little thing was so hungry.|I'd like to keep this {pet}, but it needs a name first.",
			bold = "This {pet} picked me, so it's staying.|{player}, you're naming it.",
			dreamy = "Hmm... this {pet} looked at me like it knew me already.|It should have a name, {player}.",
			easygoing = "This {pet} moved in and I didn't say no, so I guess it lives here now.|You pick a name, {player}.",
			proud = "This {pet} has excellent taste, since it chose me.|{player}, help me choose a name worthy of it.",
			shy = "Um, {player}... this {pet} won't leave, and I don't want it to.|Could you help me name it?",
			cheeky = "{player} i have a {pet} now|nobody asked me, and nobody asked the {pet} either|name it?",
			cool = "{player}, this {pet} has no home, so it's staying with me.|It needs a name.",
			prickly = "Ugh, this {pet} keeps following me around.|...Fine, it can stay, but it needs a name.",
			dramatic = "{player}, fate has sent me a {pet}!|It deserves a GRAND name.",
			bookish = "{player}, I checked the notice board, and nobody's missing a {pet}.|So I'm keeping it, and it needs a name.",
			gloomy = "This {pet} actually likes me, heh.|I suppose it needs a name, {player}.",
			polite = "{player}, this {pet} seems to have no home, so I have offered it mine.|Would you kindly help me name it?",
			foodie = "This {pet} and I shared my lunch, so we're family now.|{player}, what should I call it?",
			nervous = "{player}, I have a {pet} now, I think?|What if I'm bad at it, and what do I even call it?",
			_ = "{player}, this {pet} needs a home, so I'm keeping it.|Will you help me name it?",
		}, "heart", "wave")
		s:askName({
			var = "name",
			suggest = PET_NAMES,
			ask = "What should the {pet} be called?",
			build = function(c)
				burst(c, "a", {
					sunny = "{name}! Ehehe, that's the one.",
					gentle = "{name}, what a lovely name.|Come on, {name}, let's get you something warm to eat.",
					bold = "{name} it is, and it already answers to it.",
					dreamy = "{name}... yes, it looked up when you said it.",
					easygoing = "{name}, sure, it's easy to shout across the garden.",
					proud = "{name}, a fine name, nearly as good as one I'd have chosen.",
					shy = "{name}... I like it.|Thank you, {player}.",
					cheeky = "{name}, ok, that's a good one|it sneezed, so i think that means yes",
					cool = "{name}, good.|Thanks, {player}.",
					prickly = "{name}, fine, it's a good name.|Don't tell anyone I'm happy about this.",
					dramatic = "{name}, a name for the ages!",
					bookish = "{name}, good, it's short enough to call from the far end of the garden.",
					gloomy = "{name}, huh, it's a nice name.|I'll try not to let it down.",
					polite = "{name} it is, thank you kindly, {player}.",
					foodie = "{name}, that sounds like something tasty, so it's perfect.",
					nervous = "{name}, okay, {name}.|I'll take really good care of it, I promise.",
					_ = "{name}, that's perfect.|Thanks, {player}.",
				}, "heart", "cheer")
				c:mood("a", 6)
				c:remember("a", "pet", { what = stray.kind, name = "{name}" })
				c:follow("petnews", { chance = 0.5, hours = 10 })
				c:memo("a", "I took in a {pet} and called it {name}, so come and say hello.")
			end,
		})
		s:log("{a} took in a {pet}.")
		return s:done()
	end,
})

local CROPS = { "tomatoes", "beans", "strawberries", "carrots", "pumpkins", "peas" }

event({
	id = "newgarden",
	when = "day",
	weight = W({
		base = 0.12,
		season = { 1, 2, 3 },
		traits = { focus = 0.2 },
		cond = function(ctx, a)
			return ctx.memory(a, "garden") == nil
		end,
	}),
	scene = function(ctx, a)
		local pair = ctx.rng:shuffle(CROPS)
		local s = K.scene(ctx, "A new garden")
		s:n("{a} has dug up a patch of ground behind their house and is holding two packets of seeds.")
		burst(s, "a", {
			sunny = "{player}, I'm starting a garden!|I've got two packets of seeds, so help me pick one!",
			gentle = "{player}, I'm starting a little garden behind the house.|Which seeds should I plant first, do you think?",
			bold = "I dug the whole patch myself, so now it's time to plant.|{player}, pick the seeds.",
			dreamy = "Hmm... I want a garden I can sit in and watch things grow.|Which seeds, {player}?",
			easygoing = "I'm starting a garden, a small one, because big ones are a lot of work.|Pick the seeds for me, {player}?",
			proud = "This will be the finest garden on the island, naturally.|{player}, you may choose what goes in first.",
			shy = "Um, {player}, I've started a garden...|Could you help me choose the seeds?",
			cheeky = "{player} i dug a hole and now it's a garden|pick a packet, any packet",
			cool = "{player}, I'm starting a garden.|Which seeds would you plant?",
			prickly = "Don't laugh, I'm starting a garden.|Just pick the seeds, {player}.",
			dramatic = "{player}, today I become a GARDENER.|Choose the seeds of my future!",
			bookish = "I've read up on soil and sunlight, so I'm ready to start a garden.|{player}, which of these should go in first?",
			gloomy = "I'm starting a garden, and the gulls will probably eat it.|Which seeds, {player}?",
			polite = "Good morning, {player}, I am starting a small garden.|Would you kindly choose the first seeds?",
			foodie = "I'm growing my own food, {player}, starting today.|Which of these would taste best?",
			nervous = "I'm starting a garden, but what if nothing grows?|{player}, which seeds should I try?",
			_ = "I'm starting a garden.|Which seeds should go in first, {player}?",
		}, "idea", "point")
		for i = 1, 2 do
			local crop = pair[i]
			s:choice("Plant the " .. crop .. ".", function(c)
				c:with({ crop = crop, Crop = crop:sub(1, 1):upper() .. crop:sub(2) })
				burst(c, "a", {
					sunny = "{Crop}, yes!|I'm planting them right now, ehehe.",
					gentle = "{Crop}, good choice.|I'll water them every morning, okay?",
					bold = "{Crop} it is, and they'll be the biggest on the island.",
					dreamy = "{Crop}... I can almost see them already.",
					easygoing = "{Crop}, sure, they sound easy enough.",
					proud = "{Crop}, an excellent choice, nearly as good as mine would have been.",
					shy = "{Crop}... okay, I'll do my best with them.",
					cheeky = "{crop} it is, and if they don't grow i'm blaming you",
					cool = "{Crop}, good.|I'll get them in today.",
					prickly = "{Crop}, fine.|...They'd better grow.",
					dramatic = "{Crop}, the finest crop of the season starts TODAY.",
					bookish = "{Crop}, good, they like this much sun, actually.",
					gloomy = "{Crop}... let's hope the slugs don't find them.",
					polite = "{Crop} it is, thank you kindly, {player}.",
					foodie = "{Crop}, mmm, I'm already planning what to cook with them.",
					nervous = "{Crop}, okay.|What if I plant them upside down? Is that even possible?",
					_ = "{Crop}, good choice.|I'll plant them now.",
				}, "sparkle", "cheer")
				c:mood("a", 5)
				c:remember("a", "garden", { what = crop })
				c:memo("a", "I started a garden, and the {crop} went in first.")
			end)
		end
		s:log("{a} started a garden.")
		return s:done()
	end,
})

event({
	id = "penpal",
	when = "day",
	weight = W({
		base = 0.1,
		traits = { social = 0.15 },
		cond = function(ctx, a)
			return ctx.memory(a, "penpal") == nil
		end,
	}),
	scene = function(ctx, a)
		local s = K.scene(ctx, "A letter in a bottle")
		s:n("{a} found a bottle on the beach with a letter inside and an address on the back.")
		burst(s, "a", {
			sunny = "{player}, {player}, I found a message in a bottle!|Someone over the sea wants a pen pal!",
			gentle = "{player}, look, someone far away put a letter in a bottle.|They sound a little lonely, don't they?",
			bold = "Found a letter in a bottle on the beach.|There's an address, so I'm writing back, right?",
			dreamy = "A bottle came in with the tide, {player}...|Somebody over the sea wrote a letter and let it go.",
			easygoing = "I was lying on the beach, and a bottle washed up right next to me.|There's a letter in it.",
			proud = "Naturally, the bottle washed up by me.|Someone over the sea is asking for a pen pal.",
			shy = "Um, {player}, I found a letter in a bottle...|They want someone to write back.",
			cheeky = "{player} i found a message in a bottle|it's not treasure, but it's close",
			cool = "{player}, a bottle washed up with a letter in it.|There's an address on the back.",
			prickly = "Someone threw a bottle in the sea, and it hit my foot.|...There's a letter in it, though.",
			dramatic = "{player}, a message in a BOTTLE!|Someone across the sea is reaching out to me!",
			bookish = "Actually, bottles can float for months, so this letter might be quite old.|There's an address, {player}.",
			gloomy = "A bottle washed up with a letter in it.|It was probably meant for somebody else, heh...",
			polite = "Good afternoon, {player}, I found a letter in a bottle on the beach.|The writer asks for a pen pal.",
			foodie = "I hoped the bottle had juice in it, but it's a letter.|Someone wants a pen pal, {player}.",
			nervous = "{player}, I found a letter in a bottle!|What if it's important?",
			_ = "{player}, I found a letter in a bottle on the beach.|Someone over the sea wants a pen pal.",
		}, "sparkle", "wave")
		s:choice("Write back to them.", function(c)
			burst(c, "a", {
				sunny = "Yes, yes, I'm writing back tonight!|I'll tell them all about the town.",
				gentle = "I'll write back tonight and tell them they're not alone.",
				bold = "Hah, I've already got the paper out.",
				dreamy = "I'll write back... and send it in the same bottle.",
				easygoing = "Sure, I'll write back, after a snack.",
				proud = "My letters are very good, so they're lucky.",
				shy = "Okay... writing is easier than talking, anyway.",
				cheeky = "writing back now, and i'm telling them i live in a castle",
				cool = "Okay, I'll write back tonight.",
				prickly = "Fine, I'll write back, but only one page.",
				dramatic = "A pen pal across the sea, it's like something out of a story!",
				bookish = "I'll write back, and I'll ask what books they have over there.",
				gloomy = "Okay, I'll write back, but they probably won't answer.",
				polite = "I shall write back this evening, thank you, {player}.",
				foodie = "I'll write back and ask what they eat over there.",
				nervous = "Okay, I'll write back, but what do I even say first?",
				_ = "I'll write back tonight.",
			}, "heart", "cheer")
			c:mood("a", 5)
			c:remember("a", "penpal")
			c:memo("a", "I've got a pen pal over the sea now, and I'm waiting for their next letter.")
		end)
		s:choice("It could be a prank.", function(c)
			burst(c, "a", {
				sunny = "Aw, you think so?|...I'm keeping the bottle anyway.",
				bold = "Hah, maybe, but I'm not scared of a prank.",
				dreamy = "Hmm... maybe, but it's a very nice bottle.",
				gloomy = "Yeah, that sounds about right.",
				cheeky = "a prank? that's my job",
				prickly = "Ugh, you're probably right.",
				polite = "Perhaps you are right, so I will keep it on my shelf.",
				nervous = "A prank? Oh no, I nearly wrote back.",
				_ = "Maybe you're right, but I'm keeping the bottle.",
			}, "sweat")
			c:mood("a", -1)
		end)
		s:log("{a} found a letter in a bottle.")
		return s:done()
	end,
})

event({
	id = "training",
	when = "day",
	weight = W({
		base = 0.12,
		traits = { brave = 0.2, lazy = -0.2 },
		cond = function(ctx, a)
			return ctx.memory(a, "training") == nil
		end,
	}),
	scene = function(ctx, a)
		local s = K.scene(ctx, "The harbour race")
		s:n("{a} has signed up for the harbour race and is stretching by the fountain.")
		burst(s, "a", {
			sunny = "{player}, I'm running in the harbour race!|I've never run a race before, ehehe.",
			gentle = "{player}, I signed up for the harbour race.|I'm not fast, but I'd like to finish.",
			bold = "I'm in the harbour race, {player}.|I'm going to win it.",
			dreamy = "I signed up for the harbour race...|I'm not sure why, but the sea looked so nice that morning.",
			easygoing = "I signed up for the harbour race, which was not my best idea.|There's still time to train, though.",
			proud = "I've entered the harbour race, naturally.|Somebody has to show everyone how it's done.",
			shy = "Um, {player}, I signed up for the harbour race...|Please don't tell anyone yet.",
			cheeky = "guess who's in the harbour race|me, and i've never run further than the bakery",
			cool = "{player}, I'm running the harbour race.|I start training today.",
			prickly = "Yes, I signed up for the race.|No, I don't want to hear about it.",
			dramatic = "{player}, I am running the harbour RACE.|The whole town will see me cross that line.",
			bookish = "I've signed up for the harbour race.|Actually, I've already drawn up a training plan.",
			gloomy = "I signed up for the harbour race, and I don't know why.|I'll probably come last.",
			polite = "Good morning, {player}, I have entered the harbour race.|I would like to train properly.",
			foodie = "I signed up for the harbour race because there's a pie stall at the finish.|Now I have to actually train.",
			nervous = "{player}, I signed up for the harbour race!|What if I trip in front of everyone?",
			_ = "I signed up for the harbour race.|Now I have to train for it.",
		}, "idea", "cheer")
		s:choice("I'll time you every morning.", function(c)
			burst(c, "a", {
				sunny = "Really? Then I'll run extra fast every morning!",
				gentle = "Thank you, {player}, that means a lot.",
				bold = "Hah, good, and don't go easy on me.",
				dreamy = "Every morning... okay, I'll look for you by the fountain.",
				easygoing = "Every morning? Okay, but not too early.",
				proud = "Good, you'll get to watch me improve.",
				shy = "You'd do that? Um... thank you.",
				cheeky = "ok but no laughing when i stop for a snack",
				cool = "Good, six sharp at the fountain.",
				prickly = "Fine, but bring a watch that works.",
				dramatic = "My own COACH, this changes everything!",
				bookish = "Good, I'll write your times next to mine.",
				gloomy = "Really? Okay, I'll try not to waste your time.",
				polite = "That is very kind of you, thank you.",
				foodie = "Great, and the bakery opens right after, so that works.",
				nervous = "Oh, okay, I'll feel better if you're there.",
				_ = "Thanks, {player}, that really helps.",
			}, "heart", "cheer")
			c:mood("a", 5)
			c:hearts("a", 1)
			c:remember("a", "training")
		end)
		s:choice("Start slow, then.", function(c)
			burst(c, "a", {
				easygoing = "Slow is my favourite speed, so that works.",
				bookish = "Yes, week one is mostly walking, actually.",
				proud = "Hmph, I don't need to start slow, but fine.",
				foodie = "Slow, with snack breaks, got it.",
				dreamy = "Slow... like the tide coming in.",
				sunny = "Okay, slow, but I'll speed up soon!",
				_ = "Okay, I'll start slow and build up.",
			}, "sparkle")
			c:mood("a", 3)
			c:remember("a", "training")
		end)
		s:log("{a} signed up for the harbour race.")
		return s:done()
	end,
})

-- something new to wear for a few days, from the market (Sim/Memory's accessories)
local FINDS = { "strawhat", "flowers", "backpack", "bowtie", "sunhat" }

-- what they might find at the market that they aren't wearing already
local function findsFor(ctx, a)
	local out = {}
	local v = ctx.v(a)
	local worn = {}
	for _, m in Memory.all(v, "accessory", ctx.now) do
		worn[m.what] = true
	end
	for _, f in FINDS do
		if not worn[f] then
			table.insert(out, f)
		end
	end
	return out
end

event({
	id = "newthing",
	when = "day",
	weight = W({
		base = 0.12,
		cond = function(ctx, a)
			return #Memory.all(ctx.v(a), "accessory", ctx.now) < 2 and #findsFor(ctx, a) > 0
		end,
	}),
	scene = function(ctx, a)
		local find = ctx.rng:pick(findsFor(ctx, a))
		local s = K.scene(ctx, "From the market"):with({ thing = Memory.Accessories[find].words })
		s:n("{a} bought a {thing} at the market and keeps taking it off and putting it back on.")
		burst(s, "a", {
			sunny = "{player}, I bought a {thing} at the market!|Does it look good? Be honest, but say yes.",
			gentle = "{player}, I bought a {thing}, but I'm not sure it's really me.|What do you think?",
			bold = "Got a {thing} at the market.|It looks good, right?",
			dreamy = "I saw this {thing} at the market, and it felt like mine...|Does it suit me, {player}?",
			easygoing = "I picked up a {thing} at the market, and now I can't decide if I'll wear it.",
			proud = "I've found the perfect {thing}, naturally.|You may tell me how good it looks, {player}.",
			shy = "Um, {player}, I bought a {thing}...|Is it too much for me?",
			cheeky = "new {thing}|rate it out of ten, and it had better be a ten",
			cool = "{player}, I bought a {thing}.|What do you think?",
			prickly = "I bought a {thing}, and I don't want any jokes about it.|...Does it look okay?",
			dramatic = "{player}, I found a {thing} that was MADE for me.|Or was it? Tell me the truth.",
			bookish = "I bought a {thing} at the market.|Actually, the stall had a whole row of them, so they must be popular.",
			gloomy = "I bought a {thing}, and now I think it looks silly on me.|Does it, {player}?",
			polite = "Good afternoon, {player}, I have bought a {thing}.|May I ask your honest opinion?",
			foodie = "I went to the market for buns and came back with a {thing}.|Does it look good, at least?",
			nervous = "{player}, I bought a {thing}, but what if people laugh?|Should I wear it?",
			_ = "I bought a {thing} at the market.|Does it look good on me?",
		}, "question", "wave")
		s:choice("Wear it, it suits you.", function(c)
			burst(c, "a", {
				sunny = "Ehehe, then I'm wearing it everywhere!",
				gentle = "Oh, thank you, I'll wear it, then.",
				bold = "Hah, knew it, it's staying on.",
				dreamy = "Then I'll wear it until it feels like mine...",
				easygoing = "Cool, that saves me deciding.",
				proud = "Of course it does, but it's nice to hear.",
				shy = "R-really? Okay, I'll be brave and wear it.",
				cheeky = "a ten, i knew it",
				cool = "Okay, it stays on.",
				prickly = "Fine, it stays on, but I was going to wear it anyway.",
				dramatic = "Then the {thing} and I shall never be APART.",
				bookish = "Good, I'd already worked out it goes with four of my outfits.",
				gloomy = "Okay, I'll wear it, at least until the wind takes it.",
				polite = "Thank you kindly, I will wear it with pride.",
				foodie = "Great, now I'm going back for those buns.",
				nervous = "Okay, okay, I'm wearing it.|Tell me if anyone laughs.",
				_ = "Then I'm wearing it, thanks, {player}.",
			}, "sparkle", "cheer")
			c:mood("a", 5)
			c:wear("a", find)
			c:follow("suitme", { chance = 0.5, hours = 8, words = { worn = find } })
		end)
		s:choice("Save it for a special day.", function(c)
			burst(c, "a", {
				proud = "Hmph, every day is special when I'm in it, but fine.",
				easygoing = "Good idea, that's less effort today anyway.",
				foodie = "A special day, like a big lunch, got it.",
				sunny = "Okay, I'll save it for the next festival!",
				gloomy = "Yeah, I'll save it, then I'll forget I have it.",
				_ = "Good idea, I'll keep it for something special.",
			}, "heart")
			c:mood("a", 1)
		end)
		s:log("{a} bought a {thing} at the market.")
		return s:done()
	end,
})

-- the band plays (a villager in a band: the "band" event, Pairs)
event({
	id = "gig",
	when = "any",
	weight = W({ base = 0.35, memory = "band" }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "A show in the square"):with({ band = ctx.memoryWords(a, "band").name })
		s:prop("guitar", "a")
		s:n("{a}'s band, {band}, is setting up to play a few songs in the square.")
		burst(s, "a", {
			sunny = "{player}, {band} is playing in the square, and you have to come!|We learned a new song just for today.",
			gentle = "{player}, our band is playing a few songs in the square.|Would you come and listen, if you're free?",
			bold = "{band} is on in ten minutes, {player}.|Front row, right?",
			dreamy = "We're playing in the square soon...|I hope the gulls sing along.",
			easygoing = "We're playing a few songs in the square, nothing big.|Come if you feel like it.",
			proud = "{band} is playing in the square, and I'm the star, naturally.|You'll want to see this, {player}.",
			shy = "Um, {player}, we're playing in the square soon...|Could you stand where I can see you?",
			cheeky = "{band} is playing in the square|we only know three songs, so we play them twice",
			cool = "{player}, we're playing in the square soon.|Come if you can.",
			prickly = "We're playing in the square, and I didn't want to, but here we are.|...You're coming, aren't you?",
			dramatic = "{player}, {band} is about to play its first real SHOW!|I might faint.",
			bookish = "We're playing in the square, and I've written the songs down in order.|Actually, I've numbered them too.",
			gloomy = "We're playing in the square, so it'll probably rain.|Come anyway, {player}?",
			polite = "{player}, our band will be playing a few songs in the square.|We would be honoured if you came.",
			foodie = "We're playing in the square, and there's a bun stall right next to it.|Come for the music and stay for the buns.",
			nervous = "{player}, we're playing in the square, and what if I forget the words?",
			_ = "{player}, our band is playing in the square soon.|Will you come and listen?",
		}, "music", "wave")
		s:choice("I'll be right at the front.", function(c)
			burst(c, "a", {
				sunny = "Ehehe, then I'll wave at you between songs!",
				gentle = "Thank you, {player}, I'll play better knowing you're there.",
				bold = "Hah, good, cheer the loudest.",
				dreamy = "Then I'll play the slow one for you...",
				easygoing = "Nice, bring a blanket, the ground's hard.",
				proud = "Good, the front is the best place to see me.",
				shy = "Okay... I'll look at you if I get nervous.",
				cheeky = "front row means you have to dance, those are the rules",
				cool = "Good, see you there.",
				prickly = "Fine, but no singing along, you're off key.",
				dramatic = "Then this will be the greatest SHOW this town has seen!",
				bookish = "Good, the sound is best about three steps back from the front, actually.",
				gloomy = "Okay, at least one person will clap, heh.",
				polite = "Thank you kindly, it means a great deal.",
				foodie = "Great, bring me a bun for after.",
				nervous = "Oh, okay, phew, I can do this.",
				_ = "Great, look for me on the left.",
			}, "heart", "cheer")
			c:mood("a", 6)
			c:hearts("a", 1)
			c:memo("a", "{band} played in the square, and the {player} was right at the front.")
		end)
		s:choice("Play the one about the gulls.", function(c)
			burst(c, "a", {
				sunny = "The gull song? Yes, that's the best one!",
				dramatic = "The gull SONG, of course, the crowd loves it.",
				bookish = "Actually, it's called Hold On to Your Bun, but yes.",
				cheeky = "the gull song, we'll play it twice",
				gloomy = "The gull song, okay, it's the only one we know all the way through.",
				_ = "The gull song, good choice, we'll start with that one.",
			}, "music")
			c:mood("a", 4)
		end)
		s:log("{a}'s band, {band}, played in the square.")
		return s:done()
	end,
})

-- how a pet has been getting on (a villager who took one in: "stray", "foundpet")
local PET_NEWS = {
	"{name}, {a}'s {pet}, has started following {a} to work every morning.",
	"{a}'s {pet}, {name}, got into the flour and left white footprints all over the kitchen.",
	"{name} the {pet} fell asleep in {a}'s shoe, and nobody has the heart to move them.",
}

event({
	id = "petnews",
	when = "day",
	weight = W({ base = 0.35, memory = "pet" }),
	scene = function(ctx, a)
		local w = ctx.memoryWords(a, "pet")
		local s = K.scene(ctx, "How the pet is doing"):with({ name = w.name, pet = w.what })
		if w.what == "cat" or w.what == "kitten" then
			s:prop("cat", "a")
		elseif w.what == "puppy" then
			s:prop("dog", "a")
		end
		s:n(ctx.rng:pick(PET_NEWS))
		burst(s, "a", {
			sunny = "{player}, {name} did the funniest thing today!|I laughed so hard I had to sit down.",
			gentle = "{player}, {name} is settling in so well.|Would you like to come and say hello?",
			bold = "{name}'s got more nerve than half this town, {player}.|I'm proud of them.",
			dreamy = "{name} sat in the window all afternoon...|I think we were both watching the same cloud.",
			easygoing = "{name} has the right idea about naps, {player}.|We're basically the same.",
			proud = "{name} is clearly the cleverest pet on the island, {player}.|I've trained them well, naturally.",
			shy = "Um, {player}... I think {name} likes you.|They look at the door whenever you go past.",
			cheeky = "{name} stole my sock this morning|honestly, i respect it",
			cool = "{player}, {name}'s doing well.|They've got the run of the house now.",
			prickly = "{name} chewed my good slippers.|...I can't stay mad at them, and it's annoying.",
			dramatic = "{player}, {name} has stolen my HEART.|And my lunch, but mostly my heart.",
			bookish = "{name} has worked out where the treats are kept, {player}.|Actually, that's quite clever.",
			gloomy = "{name} still likes me, {player}, after a whole week.|That's a record.",
			polite = "Good day, {player}, {name} sends their regards.|Well, they would if they could.",
			foodie = "{name} and I had breakfast together again, {player}.|They're a very fussy eater, just like me.",
			nervous = "{player}, is it normal for {name} to sleep this much?|I keep checking they're still breathing.",
			_ = "{player}, {name} has really settled in.|You should come and say hello.",
		}, "heart", "wave")
		s:choice("Bring {name} round sometime.", function(c)
			burst(c, "a", {
				sunny = "Yes, yes, we'll come round tomorrow!",
				gentle = "We'd love that, and I'll bring some treats.",
				shy = "Okay... {name} would like that.",
				cheeky = "{name} says hide your socks",
				prickly = "Fine, but if they chew your rug, that's on you.",
				dramatic = "A VISIT, {name} will be thrilled!",
				polite = "We would be delighted, thank you.",
				nervous = "Okay, I'll make sure they're on their best behaviour.",
				_ = "We'd like that, see you soon.",
			}, "heart", "cheer")
			c:mood("a", 4)
			c:hearts("a", 1)
		end)
		s:choice("Give {name} a pat from me.", function(c)
			burst(c, "a", {
				cool = "I'll pass it on.",
				foodie = "I'll give them a treat from you too.",
				gloomy = "I'll tell them someone else likes them, heh.",
				bookish = "I will, and I'll note that you asked after them.",
				_ = "I will, they'll like that.",
			}, "heart")
			c:mood("a", 3)
		end)
		s:log("{a} told you how {name} the {pet} is doing.")
		return s:done()
	end,
})

-- the first of the crop (a villager who started a garden: "newgarden")
event({
	id = "firstcrop",
	when = "day",
	weight = W({ base = 0.35, memory = "garden" }),
	scene = function(ctx, a)
		local crop = ctx.memoryWords(a, "garden").what
		local s = K.scene(ctx, "The first crop"):with({ crop = crop })
		s:n("{a} has picked the first of their {crop} and is showing everyone.")
		burst(s, "a", {
			sunny = "{player}, look, my first {crop}!|I grew these myself, ehehe.",
			gentle = "{player}, the first {crop} were ready this morning.|I saved the best ones for you.",
			bold = "First {crop} of the season, {player}.|Grown by me.",
			dreamy = "I picked my first {crop} this morning...|They were still wet with dew.",
			easygoing = "My {crop} grew without much help from me.|Want some, {player}?",
			proud = "Look at my first {crop}, {player}.|They're finer than anything at the market, naturally.",
			shy = "Um, {player}... my {crop} grew.|Would you like some?",
			cheeky = "{player} my {crop} grew|i only lost a few to the gulls",
			cool = "{player}, the {crop} are ready.|Take some.",
			prickly = "Here, take some {crop}.|I grew too many, so it's not a big deal.",
			dramatic = "{player}, my first {crop}!|I've never been so PROUD.",
			bookish = "My first {crop}, {player}.|Actually, they were ready three days early.",
			gloomy = "My {crop} actually grew, {player}.|I don't know what to do with good news.",
			polite = "Good morning, {player}, my first {crop} are ready.|Would you kindly accept some?",
			foodie = "My first {crop}, {player}, and I already know what I'm cooking.|You're invited.",
			nervous = "{player}, my {crop} grew!|Are they meant to look like this?",
			_ = "{player}, my first {crop} are ready.|Would you like some?",
		}, "sparkle", "cheer")
		s:choice("I'd love some.", function(c)
			burst(c, "a", {
				sunny = "Here, take the big ones!",
				gentle = "Here you go, and wash them first, okay?",
				bold = "Hah, take two, I've got plenty.",
				shy = "Here... I picked the nicest ones.",
				cheeky = "here, but you owe me a pie now",
				prickly = "Take them before I change my mind.",
				dramatic = "Take them, and remember this DAY.",
				gloomy = "Here, they're the first good thing I've grown, heh.",
				polite = "Please, take as many as you would like.",
				foodie = "Take some, but save room for what I'm cooking later.",
				_ = "Here you go, enjoy them.",
			}, "heart")
			c:mood("a", 5)
			c:hearts("a", 1)
			c:memo("a", "I gave the {player} the first of my {crop}, and there are plenty more coming.")
		end)
		s:choice("Cook something with them.", function(c)
			burst(c, "a", {
				foodie = "Oh, I've got so many ideas already!",
				bookish = "I've got a cookbook with a whole chapter on {crop}.",
				easygoing = "Something easy, then, like eating them as they are.",
				_ = "Good idea, I'll make something for everyone.",
			}, "idea")
			c:mood("a", 4)
		end)
		s:log("{a} picked their first {crop}.")
		return s:done()
	end,
})

-- the dish again (a villager who learned one: "recipe", the cook in "cook")
event({
	id = "dishagain",
	when = "day",
	weight = W({ base = 0.3, memory = "dish" }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "The same dish again"):with({ dish = ctx.memoryWords(a, "dish").what })
		s:prop("bakes", "a")
		s:n("{a} made their {dish} again and brought some round, still warm.")
		burst(s, "a", {
			sunny = "{player}, I made my {dish} again, and it's my best yet!|Try some, try some!",
			gentle = "{player}, I made too much of my {dish}, so I brought you some.|Eat it while it's warm, okay?",
			bold = "I made my {dish} again.|Eat up, {player}.",
			dreamy = "I made my {dish} again, and the kitchen smelled lovely...|I thought of you, {player}.",
			easygoing = "I made my {dish} again, because it's easy.|Want some, {player}?",
			proud = "My {dish}, {player}, made just right this time.|You're very lucky to get some.",
			shy = "Um, {player}, I made my {dish} again...|You don't have to try it.",
			cheeky = "{player} i made my {dish} again|this time i only burned the pan",
			cool = "{player}, I made my {dish} again.|There's some for you.",
			prickly = "I made my {dish} again, and there's too much.|Take some, I'm not throwing it out.",
			dramatic = "{player}, I've finally got my {dish} PERFECT.|Taste it.",
			bookish = "I made my {dish} again with a few changes, {player}.|I wrote every one of them down.",
			gloomy = "I made my {dish} again, and nothing went wrong, {player}.|I'm a bit worried.",
			polite = "Good evening, {player}, I have made my {dish} again.|Would you care to try some?",
			foodie = "{player}, my {dish} is ready, and it's my best yet.|Mmm, grab a spoon.",
			nervous = "{player}, I made my {dish} again, but what if it's worse than last time?|Could you try it?",
			_ = "{player}, I made my {dish} again.|Would you like some?",
		}, "heart", "wave")
		s:choice("Mmm, it's really good.", function(c)
			burst(c, "a", {
				sunny = "Really? Ehehe, I'll make it every week, then!",
				gentle = "Oh, I'm so glad, and I'll make you more soon.",
				proud = "Of course it is, I've been practising.",
				shy = "Really? Um... thank you.",
				cheeky = "i know, i'm basically a chef now",
				cool = "Good, I changed one thing.",
				prickly = "Obviously.|...Thanks, though.",
				dramatic = "You LIKE it? I need to sit down.",
				gloomy = "Really? Huh, okay.|That's nice to hear.",
				polite = "Thank you kindly, that is lovely to hear.",
				foodie = "Right? Mmm, I'm having a second helping.",
				nervous = "Oh, phew, I was so worried.",
				_ = "Really? Thanks, {player}.",
			}, "heart", "cheer")
			c:mood("a", 5)
			c:hearts("a", 1)
		end)
		s:choice("Can I have the recipe?", function(c)
			burst(c, "a", {
				bookish = "Of course, I'll copy it out neatly for you.",
				cheeky = "nope, family secret hehe|ok fine, i'll write it down",
				proud = "Hmph, I suppose I can share it with you.",
				polite = "I would be honoured, so I will write it out this evening.",
				_ = "Sure, I'll write it down for you.",
			}, "idea")
			c:mood("a", 3)
			c:memo("a", "{player} asked for the recipe for my {dish}, so I'm writing it out.")
		end)
		s:log("{a} brought you some of their {dish}.")
		return s:done()
	end,
})

-- a letter back (a villager with a pen pal: "penpal")
event({
	id = "penletter",
	when = "day",
	weight = W({ base = 0.3, memory = "penpal" }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "A letter back")
		s:prop("parcels", "a")
		s:n("{a} is reading a letter on the bench outside the post office and smiling at it.")
		burst(s, "a", {
			sunny = "{player}, my pen pal wrote back!|Their dog rides in their bike basket, how cute is that?",
			gentle = "{player}, my pen pal wrote back.|They said my letter cheered them up.",
			bold = "My pen pal wrote back, {player}.|They say their harbour is bigger, so I'm writing back to argue.",
			dreamy = "My pen pal can see whales from their window...|I've never seen one.",
			easygoing = "My pen pal wrote back, four whole pages.|I'll answer it after a nap.",
			proud = "My pen pal says my letter was the best they've ever had, {player}.|Naturally.",
			shy = "Um, {player}, my pen pal wrote back...|They wanted to know about my friends, so I wrote about you.",
			cheeky = "my pen pal wrote back|they believe the castle thing, so it's working",
			cool = "{player}, my pen pal wrote back.|They sent a picture of their harbour.",
			prickly = "My pen pal wrote back, and they spelled my name wrong.|...It's still a nice letter.",
			dramatic = "{player}, a LETTER from across the sea!|They sent a pressed flower too.",
			bookish = "My pen pal wrote back, {player}.|Actually, they're reading the same book I am right now.",
			gloomy = "My pen pal actually wrote back, {player}.|I didn't think they would.",
			polite = "Good afternoon, {player}, my pen pal has written back.|They send their kind regards to the whole town.",
			foodie = "My pen pal sent me a recipe for fish pie, {player}.|We're having it tonight.",
			nervous = "{player}, my pen pal wrote back!|What if I answer too fast and seem strange?",
			_ = "{player}, my pen pal wrote back.|They want to hear all about the town.",
		}, "sparkle", "wave")
		s:choice("Tell them I said hello.", function(c)
			burst(c, "a", {
				sunny = "I will, and I'll draw you in the corner of the page!",
				shy = "Okay... I already did, actually.",
				cheeky = "telling them you're my royal guard hehe",
				prickly = "Fine, one line about you, that's all.",
				polite = "I shall, in my very next letter.",
				_ = "I will, and I'll tell them all about you.",
			}, "heart", "cheer")
			c:mood("a", 4)
			c:hearts("a", 1)
		end)
		s:choice("What else did they say?", function(c)
			burst(c, "a", {
				bookish = "They wrote about the tides, and they sent a list of books.|I've already started the first one.",
				dreamy = "They wrote about the boats and the birds...|It sounds a lot like here.",
				dramatic = "EVERYTHING, they told me everything.",
				gloomy = "They asked if it rains here as much as it does there.|It does, heh.",
				_ = "Mostly the weather over there, and the boats.|It sounds like a nice place.",
			}, "sparkle")
			c:mood("a", 3)
		end)
		s:log("{a}'s pen pal wrote back.")
		return s:done()
	end,
})

-- race day (a villager in training: "training"), and then the training is over
local RACE_MIDDLE = {
	sunny = "I finished, I actually finished, ehehe!",
	proud = "Middle of the pack, but only because I started slowly on purpose.",
	cheeky = "middle of the pack, just like i planned",
	dramatic = "I SURVIVED, and that's what matters.",
	gloomy = "I finished in the middle, which is better than I thought.",
	nervous = "I finished, and I didn't fall over once!",
	_ = "I finished, and I didn't stop once.",
}
local RACE_LAST = {
	sunny = "Last, but that was so much fun!",
	proud = "Hmph, somebody has to make the others look good.",
	cheeky = "last, but i was first to the pie stall",
	gloomy = "Last, like I said, but people clapped, so that's nice.",
	nervous = "Last, but I didn't fall over, so I'm happy.",
	_ = "Last, but I finished, and that counts.",
}

event({
	id = "raceday",
	when = "day",
	weight = W({ base = 0.35, memory = "training" }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "Race day")
		s:n("It's the day of the harbour race, and {a} is at the start line, bouncing on their toes.")
		burst(s, "a", {
			sunny = "{player}, it's today, it's today!|Cheer for me, okay?",
			gentle = "{player}, you came.|I'll do my best, and I'll look for you at the finish.",
			bold = "{player}, watch me win this.|It won't take long.",
			dreamy = "The sea's so calm today...|I hope my legs remember what to do.",
			easygoing = "It's race day, {player}.|I trained, mostly.",
			proud = "Today everyone sees what I can do, {player}.|Naturally, I'll win.",
			shy = "Um, {player}... everyone's looking at us.|Stay near the finish, okay?",
			cheeky = "race day|if i lose, it's because i let them win",
			cool = "{player}, it's race day.|I'm ready.",
			prickly = "Don't wave at me, I need to focus.|...Okay, one wave.",
			dramatic = "{player}, my moment has COME.|Remember me if I collapse.",
			bookish = "I've run the course twice this week, {player}.|My times are good.",
			gloomy = "It's race day, {player}.|I'll probably come last, but I'm here.",
			polite = "Good morning, {player}, thank you for coming to watch.|I shall do my very best.",
			foodie = "{player}, the pie stall's at the finish line.|That's all I need to know.",
			nervous = "{player}, what if I fall at the start?|What if I go the wrong way?",
			_ = "{player}, it's race day.|Cheer for me, okay?",
		}, "sparkle", "wave")
		local roll = ctx.rng:float(0, 1)
		local placed = if roll < 0.3 then "first" elseif roll < 0.75 then "middle" else "last"
		local function run(c)
			if placed == "first" then
				c:n("{a} crossed the line first, and the whole harbour cheered.")
				c:prop("trophy", "a")
				burst(c, "a", BRAG, "sparkle", "cheer")
				c:mood("a", 8)
				c:memo("a", "I won the harbour race, and I'm still wearing the medal.")
			elseif placed == "middle" then
				c:n("{a} finished in the middle of the pack, red in the face and grinning.")
				burst(c, "a", RACE_MIDDLE, "sparkle", "cheer")
				c:mood("a", 5)
				c:memo("a", "I ran the whole harbour race without stopping.")
			else
				c:n("{a} came in last, and the crowd clapped loudest of all for them.")
				burst(c, "a", RACE_LAST, "heart")
				c:mood("a", 3)
				c:memo("a", "I came last in the harbour race, but everyone clapped.")
			end
			-- the training is over, and so is that memory
			c:forget("a", "training")
		end
		s:choice("Go on, you've got this.", function(c)
			run(c)
			c:hearts("a", 1)
		end)
		s:choice("Just have fun out there.", function(c)
			run(c)
			c:mood("a", 2)
		end)
		s:log("{a} ran the harbour race.")
		return s:done()
	end,
})

return list
