--!strict
-- Customers and company. The user: "while villagers are working or you are working, villagers
-- might come up to interact and do chats based on the work that is being done, like villagers
-- buying ice cream. do this as well with things like the swing, where villagers might sit with each
-- other or with you."
--   a call   on a break or pottering about (Routine's "visit"), a villager walks up to a workplace
--            where somebody is at work, a villager or the player, and is served there: they ask for
--            what that job is for (a cone at the ice cream cart, a book at the library, a look at a
--            sore knee at the clinic) in their own words, the worker answers, they thank them.
--   company  sitting down near somebody already sat on a bench, a swing or a seat for two
--            (Routine's "sit"), they may take the free seat beside them and chat: with another
--            villager, or with the player.
-- Every line here leaves through Sim/Voice on its way out (Npc.say), so the marks are theirs; each
-- personality's own words are written into its lines (the sunny "Ehehe", the shy "Um" and an aside
-- in brackets, the bookish "Actually,"). The player is "{player}", filled in by Npc.say. No
-- services: Services/Villagers acts it out, tests/specs/Visits.spec.luau holds the lines.

local Text = require(script.Parent.Parent.Util.Text)
local Rng = require(script.Parent.Parent.Util.Rng)

local Visits = {}

-- What a customer asks for, by job and by the customer's personality. `_` are a few anybody says.
local ASKS: { [string]: { [string]: string | { string } } } = {
	shopkeeper = {
		_ = { "Two apples and a pear, please.", "What came in fresh today?", "A bag of oranges, please." },
		sunny = "Hi, hi, can I get a bag of the red apples, please!",
		gentle = "Oh my, these pears look lovely, so could I have four for a crumble?",
		bold = "You've still got the big oranges, right? I'll take six.",
		dreamy = "Hmm... I came for something, and now I only want that one green apple.",
		easygoing = "No rush, but could I grab a few of whatever's ripe today?",
		proud = "Hmph, only the best apples for me, so I'll pick them myself.",
		shy = "Um, could I have two apples, please? (the small ones are fine)",
		cheeky = "If I buy one pear, do I get the wonky one for free? Hehe.",
		cool = "Hm. Six apples and a bag, please.",
		prickly = "Tsk, I only came for lemons, so don't try to sell me anything else.",
		dramatic = "*gasp* The yellow plums are back, and I'll take ALL of them.",
		bookish = "Actually, I need exactly seven apples for the recipe, if you have them.",
		gloomy = "Heh... the peaches always bruise on the walk home, but I'll take three.",
		polite = "Hello, may I please have a bag of pears, if it is no trouble?",
		foodie = "Mmm, those plums smell ready, so give me a bag for after lunch.",
		nervous = "Oh no, I forgot my list, so maybe just some apples? Is that okay?",
	},
	barista = {
		_ = { "One coffee, please.", "A tea with milk, please.", "What's good today?" },
		sunny = "One hot chocolate with extra cream, please, it's a cream kind of day!",
		gentle = "A warm milky tea for me, please, and take your time, okay?",
		bold = "Strong coffee, black, and make it a big one.",
		dreamy = "Could I have something that tastes like a rainy afternoon? Oh, a latte is fine.",
		easygoing = "*yawn* Coffee, please, the biggest one you've got, no rush.",
		proud = "My usual, the one I told everyone about, and make it look nice.",
		shy = "Um, a small tea, please (if the machine isn't busy).",
		cheeky = "Surprise me, but if it's decaf I'm telling everyone :P",
		cool = "Iced coffee. No sugar, thanks.",
		prickly = "Just a coffee, and don't draw anything in the foam.",
		dramatic = "I need a coffee right NOW or I will simply fall over.",
		bookish = "A flat white, please, which is actually less milk than a latte.",
		gloomy = "A black coffee... it'll go cold before I finish it, as usual.",
		polite = "May I please have a cup of tea with a little milk? Thank you kindly.",
		foodie = "A mocha and a slice of that lemon cake to go with it, mmm.",
		nervous = "C-could I get a latte? Oh, or iced, unless hot is easier?",
	},
	baker = {
		_ = { "A loaf of bread, please.", "Two rolls, please.", "What just came out of the oven?" },
		sunny = "Something smells amazing, so one of whatever just came out, please!",
		gentle = "A loaf of the soft white bread, please, for my neighbour's soup.",
		bold = "Two sourdough loaves, and I'll carry them myself.",
		dreamy = "The rolls look like little clouds today... could I have three?",
		easygoing = "Eh, I'll take whatever's still warm, I'm not fussy.",
		proud = "Hmph, I only buy the best bread in town, so here I am.",
		shy = "Um, one cinnamon bun, please, if there are any left.",
		cheeky = "If I buy a bun, can I have the burnt ones nobody wants? Hehe.",
		cool = "One rye loaf. Sliced, please.",
		prickly = "A baguette, and not the squashed one at the end.",
		dramatic = "Tell me you saved me a croissant, I've thought about it ALL morning.",
		bookish = "Did you know bread rises faster when it's warm? Anyway, one brown loaf, please.",
		gloomy = "Heh... one roll, before they're all gone like last time.",
		polite = "May I please have six bread rolls, if it is no trouble?",
		foodie = "Mmm, I'll take the seeded loaf and two jam tarts for after lunch.",
		nervous = "Oh no, am I too late for the morning bread? Just a roll, then, is that okay?",
	},
	florist = {
		_ = { "A bunch of tulips, please.", "Something nice for a table, please.", "Which ones last longest?" },
		sunny = "Can I get the brightest flowers you've got? They're a surprise for a friend!",
		gentle = "A small bunch of daisies, please, for someone who's feeling poorly.",
		bold = "I'll take the big sunflowers, right? They'll suit my kitchen.",
		dreamy = "La la ♪ which of these smells most like spring?",
		easygoing = "Just a few tulips, whatever colour, no rush.",
		proud = "I want roses for my table, the finest ones, naturally.",
		shy = "Um, could I have just one flower? (it's for my windowsill)",
		cheeky = "Which flowers say sorry for eating your last cookie? Asking for me.",
		cool = "Something yellow. Wrapped, please.",
		prickly = "Tsk, my plants died again, so I'm buying cut ones.",
		dramatic = "These lilies are SO beautiful that I might cry, so I'll take them.",
		bookish = "Actually, tulips keep growing in the vase, did you know? I'll take five.",
		gloomy = "Flowers for my windowsill... they'll wilt, but they're nice while they last.",
		polite = "May I please have a bunch of the pink carnations? Thank you kindly.",
		foodie = "Do you have any flowers you can eat? Mmm, I'm making a salad.",
		nervous = "What if they don't like roses? Maybe the mixed bunch, is that okay?",
	},
	artist = {
		_ = { "Is that one for sale?", "Could you paint my house one day?", "Can I see what you're working on?" },
		sunny = "Could you paint me with my kite? I'll hold really still, I promise!",
		gentle = "Is that one of the harbour for sale? It would be lovely by my window.",
		bold = "Paint me standing up with my arms crossed, looking brave.",
		dreamy = "Could you paint the sky the way it was yesterday, all pink at the edges?",
		easygoing = "I'd love a little painting of my cat, no rush at all.",
		proud = "I'd like my portrait done from my good side, which is both sides.",
		shy = "Um, could I just watch you paint for a bit? (I won't talk)",
		cheeky = "Paint me with a crown on, and don't tell anyone I asked.",
		cool = "That little sea one. How much?",
		prickly = "Ugh, fine, my mum wants a portrait of me, so let's get it over with.",
		dramatic = "Paint me as a HERO, in the rain, looking into the distance.",
		bookish = "Is that oil or acrylic? Actually, I'd like one either way.",
		gloomy = "Could you paint me? It'll look nothing like me, but I'd still like one.",
		polite = "Would you be so kind as to paint a small picture of my garden?",
		foodie = "Could you paint a bowl of peaches? Mmm, I'd hang it in my kitchen.",
		nervous = "If I sit for a portrait, what if I blink? Is that okay?",
	},
	doctor = {
		_ = { "I've had a headache since yesterday.", "Could you look at my arm?", "I think I've caught a cold." },
		sunny = "Hi, my knee's been funny since I ran down the hill, so can you look?",
		gentle = "I've had a little cough, so I thought I'd better get it checked, okay?",
		bold = "I'm fine, really, but my friend made me come in about this scratch.",
		dreamy = "My head feels a bit floaty today... is that normal?",
		easygoing = "*yawn* I keep falling asleep, though that might just be me.",
		proud = "I'm in perfect health, naturally, and I'm only here for a check.",
		shy = "Um, sorry, my throat's a bit sore (it's probably nothing).",
		cheeky = "I ate six ice creams yesterday, so my tummy has a complaint for you.",
		cool = "Sprained my wrist. It's not bad.",
		prickly = "Tsk, I only came in because everyone kept telling me to.",
		dramatic = "I stubbed my toe, and I think this is the END for me.",
		bookish = "I read about my symptoms, and actually, I'd like a second opinion.",
		gloomy = "Heh... I've got a cold, as usual, right before the weekend.",
		polite = "Good day, may I please see the doctor about my sore back?",
		foodie = "I think I ate too much at lunch, mmm, but it was so good.",
		nervous = "What if this rash is something bad? Oh no, can you look?",
	},
	teacher = {
		_ = {
			"Could you help me with my spelling?",
			"Can I sit in on today's lesson?",
			"I've got a question about maps.",
		},
		sunny = "Can I sit in on the lesson today? I love a good lesson!",
		gentle = "Could you help me with my letters, okay? My spelling's gone rusty.",
		bold = "Teach me the times tables again, because I'm going to win the quiz.",
		dreamy = "Is it true the moon pulls the sea? I was wondering about it all morning...",
		easygoing = "Mind if I sit at the back and listen? I'll try not to nod off.",
		proud = "Hmph, I already know most of it, but I'd like to check my answers.",
		shy = "Um, could you explain fractions to me? (just once more)",
		cheeky = "Is there homework today? Say no, say no.",
		cool = "I've got a question about the old maps. Got a minute?",
		prickly = "I don't need help, I just want to know how long division works.",
		dramatic = "Teach me poetry, because I have so many FEELINGS to put somewhere.",
		bookish = "Actually, I found a mistake in the history book, so can I show you?",
		gloomy = "I never understood maths... could you try anyway?",
		polite = "Excuse me, would you mind explaining the lesson once more, please?",
		foodie = "Is the cooking class today? Mmm, I hope we're making pancakes.",
		nervous = "I-I missed the last lesson, is that okay? What did I miss?",
	},
	musician = {
		_ = { "Could you play one more?", "Here's a coin for you.", "Do you take requests?" },
		sunny = "Play something we can dance to, please, I've got my dancing shoes on!",
		gentle = "Could you play something slow and soft? It's been a long day, okay?",
		bold = "Play the loud one, the one everyone shouts along to.",
		dreamy = "Do you know a song about the sea? La la ♪ yes, that one.",
		easygoing = "Something easy to listen to, no rush, I'll be on the grass.",
		proud = "Play my favourite, and you know which one, everyone does.",
		shy = "Um, here's a coin for you (that song was really nice).",
		cheeky = "I'll give you a coin if you play it twice as fast, hehe.",
		cool = "That was good. Play another.",
		prickly = "Tsk, play something that isn't about love, please.",
		dramatic = "Play the saddest song you know, because I want to FEEL something.",
		bookish = "Do you know any old folk songs? Actually, that one has eleven verses.",
		gloomy = "Play something slow... the sad ones are the best ones.",
		polite = "May I request a song, please? Something cheerful, if it is no trouble.",
		foodie = "Play something for lunch, mmm, a picnic sort of song.",
		nervous = "C-could you play my song? It's okay if you don't know it.",
	},
	builder = {
		_ = { "Could you fix my chair?", "My door won't shut properly.", "Can you make me a shelf?" },
		sunny = "My chair wobbles every time I laugh, so can you fix it?",
		gentle = "Could you mend this little stool, okay? It was my grandmother's.",
		bold = "I need a new shelf, a strong one, for my weights.",
		dreamy = "My window won't open, and I like to hear the rain... can you help?",
		easygoing = "My fence fell over a while back, no rush, it's been fine like that.",
		proud = "Build me a bench, a really fine one that people will notice.",
		shy = "Um, sorry, my door squeaks (only a little).",
		cheeky = "I broke my bed jumping on it, don't ask how, hehe.",
		cool = "Got a hinge for a cupboard door? Mine snapped.",
		prickly = "Ugh, my table leg came off, so fix it and don't laugh.",
		dramatic = "My bookshelf COLLAPSED in the night, and it was terrible.",
		bookish = "Could you build me a shelf exactly forty inches wide? I measured twice.",
		gloomy = "My roof leaks again... could you take a look?",
		polite = "Would you please have a look at my drawer? It will not close.",
		foodie = "Can you make me a bigger kitchen table? Mmm, more room for dinner.",
		nervous = "My step creaks, so what if it breaks? Could you check it?",
	},
	postie = {
		_ = { "One stamp, please.", "Is there any mail for me?", "I'd like to send this parcel." },
		sunny = "One stamp, please, I'm writing to everyone I know!",
		gentle = "Could you post this card for me, okay? It's my aunt's birthday.",
		bold = "This parcel's heavy, and I carried it all the way here, so send it fast.",
		dreamy = "I wrote a letter to the sea... oh, no, to my cousin by the sea.",
		easygoing = "Is there any mail for me? No rush, I'll wait.",
		proud = "Send this first class, naturally, because it's very important.",
		shy = "Um, I'd like to send this letter (it's nothing important).",
		cheeky = "Can you post this to my friend without my name on it? Hehe, it's a prank.",
		cool = "Two stamps. Thanks.",
		prickly = "Tsk, my parcel's late again, so where is it?",
		dramatic = "This letter MUST get there tomorrow, or everything is ruined.",
		bookish = "Actually, how many days does a parcel take to reach the next island?",
		gloomy = "Any mail for me? Heh... no, I didn't think so.",
		polite = "May I please send this parcel? Thank you kindly for your help.",
		foodie = "I'm sending my aunt a jar of jam, mmm, so could you wrap it well?",
		nervous = "What if my letter gets lost? Oh no, can I get a receipt?",
	},
	icecream = {
		_ = { "A vanilla cone, please.", "Two scoops of chocolate, please.", "What flavours have you got today?" },
		sunny = "A strawberry cone, please, with sprinkles on top!",
		gentle = "One small vanilla, please, and one for my little neighbour.",
		bold = "Three scoops of chocolate, and don't skimp.",
		dreamy = "Mint, I think... it tastes like the sea breeze.",
		easygoing = "Whatever flavour's melting the fastest, and I'll help with it.",
		proud = "Two scoops of your finest in a cone, naturally.",
		shy = "Um, one scoop of vanilla, please (a small one).",
		cheeky = "Can I try every flavour first, all of them? Hehe.",
		cool = "Lemon sorbet. A cup, thanks.",
		prickly = "Tsk, it's too hot today, so just give me the biggest one.",
		dramatic = "I NEED ice cream, because this is an emergency.",
		bookish = "Did you know vanilla comes from an orchid? One scoop of it, please.",
		gloomy = "Chocolate, please... it'll melt before I get home.",
		polite = "May I please have a scoop of strawberry in a cup?",
		foodie = "Mmm, a waffle cone with two scoops and the caramel sauce.",
		nervous = "What if I drop it? Maybe a cup, is that okay?",
	},
	librarian = {
		_ = { "I'd like to borrow this one, please.", "I'm returning these.", "Do you have anything about boats?" },
		sunny = "I finished the whole book in one night, so can I have the next one?",
		gentle = "Could you find me something to read by the fire, okay? It's going to rain.",
		bold = "Give me the biggest adventure book you've got.",
		dreamy = "Do you have a book about clouds? Or one about the stars?",
		easygoing = "I'm returning this, and it's only a little late, haha.",
		proud = "I'll take the hardest book on the shelf, naturally.",
		shy = "Um, I'd like to borrow this (if nobody else wants it).",
		cheeky = "I want the scary book, the one that kept everyone up, hehe.",
		cool = "Returning this. It was good.",
		prickly = "Tsk, someone folded the pages in this, and it wasn't me.",
		dramatic = "This book's ending BROKE my heart, so I need another one by her.",
		bookish = "Actually, I'd like all three of these, and I'll have them back by Friday.",
		gloomy = "Heh... the book I wanted is out again, as usual.",
		polite = "May I please borrow this one? I will take good care of it.",
		foodie = "Do you have any cookbooks? Mmm, I'm after a good pie.",
		nervous = "This is late, is that okay? Oh no, is there a fine?",
	},
}

-- What the worker says back, by job: anybody at it, a villager or the player. {name} is the
-- customer.
local SERVES: { [string]: { string } } = {
	shopkeeper = {
		"Here you go, I picked out the best ones.",
		"Fresh this morning, so enjoy them.",
		"There you are, {name}, and come back soon.",
		"I put an extra one in the bag for you.",
	},
	barista = {
		"Here's your cup, and careful, it's hot.",
		"One coffee, made just how you like it.",
		"There you go, {name}, enjoy it.",
		"I drew a little leaf on top for you.",
	},
	baker = {
		"Still warm, so eat one on the way home.",
		"Here you go, and mind the crumbs.",
		"That's the last one, {name}, so you're in luck.",
		"Fresh out of the oven, so enjoy it.",
	},
	florist = {
		"Here, I put in a sprig of green as well.",
		"Keep them out of the sun and they'll last.",
		"There you go, {name}, they suit you.",
		"I wrapped them in the nice paper for you.",
	},
	artist = {
		"Hold that pose, and I'll start with your nose.",
		"It'll be dry by tomorrow, {name}.",
		"Here, have a look at it so far.",
		"Thanks, I'll keep it by the window for you.",
	},
	doctor = {
		"Nothing serious, so rest and drink plenty of water.",
		"Take these, and come back if it gets worse.",
		"You'll be fine, {name}, I promise.",
		"Sit down there and let me have a look.",
	},
	teacher = {
		"Good question, so let me show you on the board.",
		"Sit anywhere you like, {name}.",
		"Here, start with this page.",
		"Try it once more and you'll have it.",
	},
	musician = {
		"This next one's for you, {name}.",
		"Thanks, I'll play it next.",
		"Coming right up, so clap along if you know it.",
		"Thanks, that's my lunch sorted.",
	},
	builder = {
		"Leave it with me, and it'll be ready tomorrow.",
		"That's an easy fix, so give me five minutes.",
		"There, good as new, {name}.",
		"I'll come round and look at it after work.",
	},
	postie = {
		"That'll be there by tomorrow.",
		"Here's your stamp, {name}.",
		"I'll put it on the first boat out.",
		"It'll go out with the afternoon post.",
	},
	icecream = {
		"Here you go, and eat it before it drips.",
		"One cone, coming right up.",
		"Extra sprinkles, just for you, {name}.",
		"Careful, it's melting already.",
	},
	librarian = {
		"Here you go, and have it back in two weeks.",
		"Good choice, {name}, I loved that one.",
		"Let me stamp it for you.",
		"Try this one too, I think you'll like it.",
	},
}

-- The customer's thanks once served, by personality.
local THANKS: { [string]: { string } } = {
	sunny = { "Thanks so much, this is perfect!", "Ehehe, thank you, see you tomorrow!" },
	gentle = { "Thank you, dear, and take care of yourself, okay?", "Oh my, that's lovely, thank you." },
	bold = { "Thanks, I'll be back tomorrow.", "Good, that's just what I wanted." },
	dreamy = { "Oh... thank you, it's just right.", "Thanks, I'll think about this all afternoon." },
	easygoing = { "Thanks, that's great, haha.", "Nice, thanks, see you around." },
	proud = { "Hmph, good, just as I'd hoped.", "Naturally, it's perfect, so thank you." },
	shy = { "Th-thank you (really).", "Um, thanks, and sorry for the bother." },
	cheeky = { "Thanks, you're the best, hehe.", "Yes, thanks, see you later :P" },
	cool = { "Thanks.", "Good. Later." },
	prickly = { "Fine, thanks, I suppose.", "Hm, it'll do, so thanks." },
	dramatic = { "THANK you, you've saved my whole day!", "*gasp* It's perfect, thank you!" },
	bookish = { "Thank you, that's exactly what I needed.", "Thanks, and sorry, I was rambling again." },
	gloomy = { "Thanks... that was nice, which is strange.", "Heh, thanks." },
	polite = { "Thank you kindly, and have a lovely day.", "Thank you very much, that is wonderful." },
	foodie = { "Mmm, thank you, this is going to be good.", "Thanks, I'll have it with lunch." },
	nervous = { "Th-thanks, oh, phew, that went fine.", "Thank you, and sorry if I took too long." },
}

-- What a customer says first when it's the player behind the counter, by personality.
local GREET: { [string]: string } = {
	sunny = "{player}, you're working here today? That's so fun!",
	gentle = "Oh my, {player}, you're serving today? Don't tire yourself out, okay?",
	bold = "Hah, {player} behind the counter, I had to see this.",
	dreamy = "Oh, {player}... I didn't know you worked here.",
	easygoing = "Hey, {player}, look at you, all busy.",
	proud = "{player}, serving me yourself? Naturally.",
	shy = "Um, {player}? I didn't know it'd be you.",
	cheeky = "{player}, you look funny back there, hehe.",
	cool = "Hm. {player}. Didn't expect you here.",
	prickly = "{player}? Tsk, don't mess up my order.",
	dramatic = "{player} is SERVING today? This is huge.",
	bookish = "Oh, {player}, I read that the best towns are run by people who work in them.",
	gloomy = "Heh... {player}, they've got you working too?",
	polite = "Good day, {player}, how kind of you to serve us.",
	foodie = "{player}, are you on shift? Mmm, then you'll know what's good.",
	nervous = "Oh, {player}, I-I didn't know you'd be here, is that okay?",
}

-- Sitting down beside another villager, by the personality of whoever sits down.
local SIT: { [string]: { string } } = {
	sunny = { "Mind if I sit here? I've been on my feet all day!", "Scoot over, I want to tell you about my morning!" },
	gentle = { "Can I sit with you a while? You look like you need a rest, okay?", "Oh my, it's nice here, isn't it?" },
	bold = { "Move over, this seat's got the better view.", "Room for one more, right?" },
	dreamy = { "The clouds look nice from here... can I sit?", "Oh, I think this seat was waiting for me." },
	easygoing = { "Mind if I flop down here? No rush to talk.", "*yawn* Good spot, I might stay a while." },
	proud = {
		"I'll sit here, since it's the best seat, naturally.",
		"Hmph, you picked a good spot, I'll give you that.",
	},
	shy = { "Um, can I sit here? (I won't talk much)", "Is this seat free? Sorry." },
	cheeky = { "Budge up, it's my turn, hehe.", "Guess who's sitting next to you now :P" },
	cool = { "Mind if I sit? I'll be quiet.", "Good spot. I'll join you." },
	prickly = { "Ugh, every other seat's taken, so I'm sitting here.", "Don't read into it, I just wanted to sit." },
	dramatic = { "My legs are SO tired that I need this seat.", "*gasp* Finally, someone to sit with!" },
	bookish = {
		"Actually, this is the sunniest seat in town, I checked.",
		"Mind if I sit? I'll only read a page or two.",
	},
	gloomy = { "Heh... mind if I sit? It'll rain soon anyway.", "This seat's free, which makes a change." },
	polite = { "Excuse me, may I sit beside you, if it is no trouble?", "Thank you for the room, it is a lovely day." },
	foodie = { "Can I sit? I brought snacks, mmm.", "I'll sit here and finish my sandwich, if that's okay." },
	nervous = { "C-can I sit here? Is that okay?", "Oh, sorry, is this seat taken? Phew, okay." },
}

-- And beside the player.
local SIT_PLAYER: { [string]: { string } } = {
	sunny = { "{player}, can I sit with you? Let's watch everyone go by!", "Ehehe, {player}, I saw you sitting here!" },
	gentle = {
		"Oh, {player}, you look tired, so let's sit a while, okay?",
		"{player}, have you eaten? I'll sit with you.",
	},
	bold = { "{player}, scoot over, I'm joining you.", "Hah, {player}, you found the best seat." },
	dreamy = { "{player}... the sky's nice from here, isn't it?", "Oh, {player}, I was just thinking about you." },
	easygoing = { "Hey, {player}, nice spot, so mind if I nap here?", "*yawn* {player}, wake me if anything happens." },
	proud = {
		"{player}, I'll let you sit next to me. Hmph, I mean the other way round.",
		"{player}, I've got a seat with you, naturally.",
	},
	shy = { "Um, {player}, can I sit here? (only if it's okay)", "{player}... um, hi." },
	cheeky = { "{player}, bet you didn't see me coming, hehe.", "{player}, I'm stealing half your seat :P" },
	cool = { "{player}. Nice day for it.", "Hm. Mind if I sit, {player}?" },
	prickly = { "{player}, I wanted this seat first, but fine, I'll share.", "Tsk, {player}, move your elbow over." },
	dramatic = {
		"{player}, sitting with you is the BEST part of my day!",
		"*gasp* {player}, a free seat right next to you!",
	},
	bookish = {
		"{player}, did you know this seat gets sun for six hours a day?",
		"Mind if I read here, {player}? I'll be quiet.",
	},
	gloomy = {
		"{player}... mind if I sit? You look like you could use company too.",
		"Heh, {player}, nobody ever sits with me.",
	},
	polite = { "Good day, {player}, may I sit beside you?", "{player}, thank you for the room, if it is no trouble." },
	foodie = {
		"{player}, want half my sandwich? Mmm, I'll sit here.",
		"{player}, have you had lunch? I'm sitting with you.",
	},
	nervous = { "{player}, c-can I sit with you? Is that okay?", "Oh, {player}, sorry, is this seat free?" },
}

local function pickOf(rng: Rng.Rng?, list: { string }): string
	if #list == 0 then
		return "..."
	end
	return if rng then rng:pick(list) else list[1]
end

-- What a customer of this personality asks for at a workplace of this job: their own line now and
-- then, else one anybody says.
function Visits.ask(job: string, pers: string?, rng: Rng.Rng?): string
	local map = ASKS[job]
	if not map then
		return "One of those, please."
	end
	local own = pers and map[pers]
	if type(own) == "string" and (not rng or rng:chance(0.6)) then
		return own
	end
	return pickOf(rng, map._ :: { string })
end

-- What the worker says back. {name} is the customer's name.
function Visits.serve(job: string, name: string?, rng: Rng.Rng?): string
	local list = SERVES[job] or { "Here you go, and come again." }
	return Text.fill(pickOf(rng, list), { name = name or "" })
end

-- The customer's thanks.
function Visits.thanks(pers: string?, rng: Rng.Rng?): string
	return pickOf(rng, (pers and THANKS[pers]) or { "Thanks." })
end

-- What a customer says first to the player behind the counter.
function Visits.greet(pers: string?): string
	return (pers and GREET[pers]) or "Oh, hi, {player}."
end

-- What somebody says sitting down beside another villager, or beside the player.
function Visits.sit(pers: string?, rng: Rng.Rng?, toPlayer: boolean?): string
	local map = if toPlayer then SIT_PLAYER else SIT
	return pickOf(rng, (pers and map[pers]) or { "Mind if I sit here?" })
end

-- Does this job have customers' lines of its own?
function Visits.has(job: string): boolean
	return ASKS[job] ~= nil and SERVES[job] ~= nil
end

-- Every line, with who says it, for the spec: { text, pers?, kind, job? }.
function Visits.all(): { any }
	local out: { any } = {}
	for job, map in ASKS do
		for pers, v in map do
			if type(v) == "string" then
				table.insert(out, { text = v, pers = pers, kind = "ask", job = job })
			else
				for _, t in v do
					table.insert(out, { text = t, kind = "ask", job = job })
				end
			end
		end
	end
	for job, list in SERVES do
		for _, t in list do
			table.insert(out, { text = t, kind = "serve", job = job })
		end
	end
	local byPers: { [string]: { [string]: { string } } } = { thanks = THANKS, sit = SIT, sitPlayer = SIT_PLAYER }
	for kind, map in byPers do
		for pers, list in map do
			for _, t in list do
				table.insert(out, { text = t, pers = pers, kind = kind })
			end
		end
	end
	for pers, t in GREET do
		table.insert(out, { text = t, pers = pers, kind = "greet" })
	end
	return out
end

-- Seats side by side. `free` are seats nobody is on, `taken` the ones somebody sits on (each with
-- its position); a free seat within `reach` studs of a taken one is a seat beside that somebody.
-- Returns { free index, taken index } pairs, nearest first.
function Visits.beside(free: { Vector3 }, taken: { Vector3 }, reach: number): { { number } }
	local out = {}
	for i, f in free do
		local best, bestD = nil, math.huge
		for j, t in taken do
			local d = (f - t).Magnitude
			if d <= reach and d < bestD and d > 0.5 then
				best, bestD = j, d
			end
		end
		if best then
			table.insert(out, { i, best, bestD })
		end
	end
	table.sort(out, function(a, b)
		return a[3] < b[3]
	end)
	for _, pair in out do
		pair[3] = nil
	end
	return out
end

return Visits
