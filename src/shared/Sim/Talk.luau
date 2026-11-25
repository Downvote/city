--!strict
-- Talking to a villager. The user: "allow the option to interact/chat with villagers by holding
-- e on them". Pure data in and out so the specs can run it; Services/Villagers puts the prompt on
-- every villager and answers it, UI/TalkCard is the card the owner sees.
--   lines   what they say back: a greeting in their own voice when you walk up (or what they
--           are wishing for, if anything), then small talk about how they feel, their work,
--           their hobby and the people they live with. Since the user asked for "much much more
--           random events ... conversations": what they got up to in their last event (its memo,
--           while it's fresh), what they think of a neighbour (by how they get on, and what that
--           neighbour is like), a worry, a joke, the season and the weather.
--   chats   the little good a chat does. In your own town the first few chats a day with a
--           villager lift their mood a touch and fill their hearts by a point (Sim/Life); after
--           that they still answer and nothing is gained. A chat is also the answer to a wish
--           for one. Somebody visiting gets the line and nothing else.

local Tuning = require(script.Parent.Parent.Config.Tuning)
local Personalities = require(script.Parent.Parent.Data.Personalities)
local Sayings = require(script.Parent.Parent.Data.Sayings)
local Foods = require(script.Parent.Parent.Data.Foods)
local Text = require(script.Parent.Parent.Util.Text)
local City = require(script.Parent.City)
local Life = require(script.Parent.Life)
local Relationships = require(script.Parent.Relationships)

local K = Tuning.Talk

local Talk = {}

export type Chat = {
	counted: boolean, -- one of the day's few that count
	hearts: number, -- heart points it gave
	mood: number, -- mood it gave
	left: number, -- how many more will count today
	wish: boolean, -- it answered their wish for a talk
	coins: number, -- what they gave you for that
}

-- What to say back -----------------------------------------------------------------------------------

-- Can a villager be stopped for a talk? `mode` is what Services/Villagers has them doing: nil
-- is their own day, "chat" a word with a neighbour and "talk" a talk already going on. An
-- event's scene ("event") and an outing ("away") are not interrupted.
function Talk.free(mode: string?): boolean
	return mode == nil or mode == "chat" or mode == "talk"
end

-- What the lines below are keyed by: a villager's personality (Data/Personalities), with "_" for
-- anybody else. The user: "for the humanization, make sure to take note of the personalities of the
-- villagers as well", so a shy villager and a loud one don't say the same thing the same way.
local function own(map: { [string]: string }, pers: string?): string
	return (pers and map[pers]) or map._
end

-- They talk to you the way a friend texts (the user gave us a messaging app's chats to learn from:
-- their feel only), and then: "Try to avoid having strings of short sentences, and redo the
-- contents of sentences". So each line here is one talk card message: one complete sentence, or
-- two that flow together, never three and never a run of clipped bits, the way a friend starts a
-- chat when you stop by. Your name ({player}, filled in as the line leaves) turns up about one line
-- in seven, mostly first, and each personality's speech habits (Data/Personalities) show now and
-- then on top of an ordinary sentence.

-- Walking up to them: their own hello (Personalities' `hello`, which they also say to each other)
-- or one of these, which are for you and use your name.
local GREET = {
	sunny = {
		"{player}, guess what, the ferry's got a new bell!",
		"{player}, perfect timing, I've got news for you!",
		"Hi, {player}, I just saw a gull steal a whole pie!",
	},
	gentle = {
		"Hello, {player}, have you had a proper meal today?",
		"Oh, {player}, come and sit, you've been on your feet all day.",
		"{player}, there you are, I saved you some beans from the garden.",
	},
	bold = {
		"{player}, you're free right now, right? I need a hand at the harbour.",
		"There you are, {player}, walk with me while I check the sea wall.",
		"Hey, {player}, somebody left the square gate open again.",
	},
	dreamy = {
		"{player}, there's a tiny rainbow in the fountain, come and see.",
		"Oh, hi, {player}, I was counting boats and lost count.",
		"{player}... hello, the light's gone gold over the hill.",
	},
	easygoing = {
		"*yawn* Oh, hey, {player}, is it lunch already?",
		"Hey, {player}, could you bring me an apple if you're passing the market?",
		"Mm, hi, {player}, I've been resting since breakfast, for research.",
	},
	proud = {
		"{player}, you'll want to hear this, because I won again.",
		"Ah, {player}, good, I've got something excellent to show you.",
		"{player}, you've come just as I finished something brilliant.",
	},
	shy = {
		"Um, hi, {player}, I didn't think you'd stop.",
		"{player}, um, hello, I'm not busy, if you wanted to talk.",
		"Oh, {player}, um, the cat by the library let me stroke it.",
	},
	cheeky = {
		"Psst, {player}, over here, and act normal.",
		"{player}, don't look at the fountain yet, okay, now look.",
		"Oh, {player}, perfect, I need a lookout, so just stand there.",
	},
	cool = {
		"{player}, hey.",
		"{player}, I ran past your house this morning, and the roof looks good.",
		"Oh, {player}, the tide's out, so it's good walking.",
	},
	prickly = {
		"{player}, you've got weeds on your path, and hi, I suppose.",
		"Oh, it's you, {player}, what do you want? Fine, hello.",
		"{player}, you again, so sit down, but not there.",
	},
	dramatic = {
		"{player}, at LAST, I've been waiting all day!",
		"Ah, {player}, you're just in time, something tremendous has happened!",
		"{player}, stop and listen, I have news of great importance!",
	},
	bookish = {
		"Hello, {player}, did you know honey can keep for thousands of years?",
		"Oh, {player}, sorry, I was halfway through a chapter, hello.",
		"{player}, hello, I've worked out how old the lighthouse is, if you have a minute.",
	},
	gloomy = {
		"Oh, hi, {player}, my umbrella broke this morning, as usual.",
		"{player}, you came over, huh, that's nice.",
		"{player}, hi, I was just thinking nobody would stop today.",
	},
	polite = {
		"Good day, {player}, I hope I'm not keeping you from anything.",
		"Hello, {player}, how lovely, I was just admiring the harbour.",
		"{player}, how are you keeping? Do mind the sun today, it's very strong.",
	},
	foodie = {
		"{player}, have you had lunch yet? I've had two.",
		"Hi, {player}, can you smell that? The bakery's doing cinnamon today.",
		"{player}, the fish stall's doing fried fish with lemon, so come on!",
	},
	nervous = {
		"Oh, {player}, sorry, you made me jump, hi.",
		"{player}, h-hi, is everything okay with you?",
		"{player}, sorry, hi, I locked my door three times this morning.",
	},
}

-- After a talk that answered their wish for one.
local THANKS = {
	_ = "Thanks for stopping, {player}, that really helped.",
	sunny = "{player}, thank you, I feel so much better, so let's do this again tomorrow!",
	gentle = "Thank you for sitting with me, {player}, and I'll pay you back in soup.",
	bold = "...Thanks, {player}, I needed that, so lunch is on me.",
	dreamy = "Hmm, the grey feeling's gone now, thank you, {player}.",
	easygoing = "Heh, thanks, {player}, that was as good as a nap.",
	proud = "Th-that wasn't me being sad, I was thinking, but thank you, {player}.",
	shy = "Um, thank you, {player}, I feel a lot better now.",
	cheeky = "ok, real thanks, {player}, no joke this time.",
	cool = "{player}, that helped, thanks.",
	prickly = "Don't make it a thing, {player}, but that helped, so thanks.",
	dramatic = "{player}, you've rescued me from the depths of DESPAIR, thank you!",
	bookish = "Thank you, {player}, that helped more than a whole chapter would have.",
	gloomy = "Huh, I feel better, which never happens, so thanks, {player}.",
	polite = "Thank you kindly, {player}, I'll write you a proper note about it.",
	foodie = "Thanks, {player}, that was better than a bowl of soup, and I love soup.",
	nervous = "Oh, I can breathe again, thank you, {player}, sorry, thank you.",
}

-- No bed yet.
local NOBED = {
	_ = "Just so you know, I still don't have a bed.",
	sunny = "{player}, I still don't have a bed, so I've been sleeping on a pile of coats!",
	gentle = "I don't like to make a fuss, {player}, but I still haven't got a bed.",
	bold = "I've slept on the floor three nights now, so sort me out a bed, okay?",
	dreamy = "I've been sleeping wherever I end up, so a bed would be nice...",
	easygoing = "Eh, the floor's comfy enough, but a bed would be comfier.",
	proud = "Someone like me shouldn't be sleeping on a rug, so a bed, please.",
	shy = "Um, I don't have a bed yet, sorry, but the rug's okay for now.",
	cheeky = "{player}, I've got no bed, so I'm sleeping in the bath, and it's not fine.",
	cool = "Still no bed, and the floor's cold.",
	prickly = "I don't care that I've got no bed, but my back does.",
	dramatic = "Another night on the cold, cruel floor, {player}, how long must I suffer?",
	bookish = "I still haven't got a bed, and I've read that sleep matters rather a lot.",
	gloomy = "No bed yet, as usual, so the floor and I are getting close.",
	polite = "Forgive me for raising it, {player}, but I don't have a bed yet.",
	foodie = "I've got no bed yet, so I've been dozing by the bread bin.",
	nervous = "{player}, um, I still don't have a bed, is that on the list? Sorry.",
}

-- A quarrel that hasn't blown over.
local QUARREL = {
	_ = "{y} and I aren't talking at the moment.",
	sunny = "{y} and I had a fight, and I hate it, so can it just be over?",
	gentle = "{y} and I had words, and I keep thinking I should knock on their door.",
	bold = "Don't bring up {y}, because we had it out and we're not talking.",
	dreamy = "{y} and I aren't speaking, and I can't remember why...",
	easygoing = "Me and {y} aren't talking right now, but give it a day.",
	proud = "I'm not speaking to {y} until they apologise, and they know what for.",
	shy = "{y} and I had a falling out, and I don't know what to say to them...",
	cheeky = "{y} and I are in a fight, and I think I'm winning, am I winning?",
	cool = "{y} and I aren't talking, and that's all I'll say.",
	prickly = "Don't say {y}'s name to me, ugh, fine, I miss them a bit.",
	dramatic = "{y} and I are sworn enemies now, at least until Friday!",
	bookish = "{y} and I disagreed about the tide tables, and neither of us will back down.",
	gloomy = "{y} isn't talking to me, which was bound to happen sooner or later.",
	polite = "{y} and I had a disagreement, and I do hope we can put it right soon.",
	foodie = "{y} and I fell out over the last dumpling, and it was a really good dumpling.",
	nervous = "{y} is cross with me, and what if it's forever? Is it forever?",
}

-- Their best friend, the one at the top.
local FRIEND = {
	_ = "{y} always makes me laugh.",
	sunny = "{y} and I sat on the pier until the lamps came on, talking about everything!",
	gentle = "{y} walked me home in the rain and held the umbrella the whole way.",
	bold = "{y}'s solid, and they've always got my back.",
	dreamy = "{y} watched the clouds with me for an hour, and it was perfect.",
	easygoing = "Me and {y} did nothing all afternoon, and it was great.",
	proud = "{y} came to watch me win and clapped the loudest.",
	shy = "{y} talks to me a lot, and I like that.",
	cheeky = "{y} helped me hide the baker's rolling pin, so that's a true friend.",
	cool = "{y}'s good company, and they don't talk much.",
	prickly = "{y}'s annoying, but I'd still carry their boxes up the hill.",
	dramatic = "{y} is my dearest friend in the whole world!",
	bookish = "{y} brought back all four books I lent them, on time.",
	gloomy = "{y} never minds when I'm gloomy, and they bring biscuits.",
	polite = "{y} sent me a card when I was ill, and I've kept it.",
	foodie = "{y} shares their chips without me even asking.",
	nervous = "{y} walks me past the big dog every morning without fail.",
}

-- Small talk anybody might make on an ordinary day.
local SMALL = {
	"{player}, what are you building next? I saw you with a hammer.",
	"It's a quiet day, and the square's half empty.",
	"The harbour smelled like rain this morning, but it never came.",
	"Somebody on a boat waved at me, so I waved back.",
	"The bakery queue went right round the corner today.",
	"Someone keeps leaving flowers on the bench by the pier.",
	"I sat on the hill and watched the ferry come in.",
	"The fountain's been extra splashy since the wind changed.",
	"I tidied one drawer today, which is a start.",
	"The new bench by the hall is comfier than it looks.",
}

-- Small talk of their own, by personality.
local OWN = {
	sunny = {
		"I counted the boats in the harbour, and there were fourteen!",
		"Someone planted flowers round the fountain, and I need to know who!",
		"Let's have lunch on the square with the whole town, can we?",
		"{player}, I learned the baker's middle name, but I promised not to tell.",
		"The harbour dog let me throw its stick eleven times!",
	},
	gentle = {
		"Oh, my, your coat's lost a button, so leave it with me later.",
		"The baker's been coughing, so I'm taking her some honey.",
		"{player}, you've worked every day this week, so take tomorrow slowly, okay?",
		"I planted mint by my door, so help yourself whenever you like.",
		"The sparrow by my window came back, and it brought a friend.",
	},
	bold = {
		"I moved the fallen branch off the hill path, since nobody else would.",
		"Anything heavy need lifting today? Just point at it.",
		"{player}, the sea wall's cracked, so we're fixing it Saturday, right?",
		"Someone keeps leaving rubbish by the pier, so I'm keeping watch tonight.",
		"I raced the ferry along the shore and nearly won!",
	},
	dreamy = {
		"I followed a cat round the square for an hour...",
		"You can feel the waves through the pier boards if you lie down.",
		"{player}, the moon was out at lunchtime, did you see?",
		"I found a grey feather with a white tip on my step.",
		"Sorry, I was going to tell you something, but it's gone.",
	},
	easygoing = {
		"I spent the morning watching the tide come in, so, busy morning.",
		"Not much to report, which is how I like it.",
		"Mm, I was going to do something today, but it'll keep.",
		"{player}, try lying in the grass on the hill sometime, it's the best.",
		"The baker asked if I'd swept her step, and I said the wind did it.",
	},
	proud = {
		"The baker asked for my advice today, and I gave it, generously.",
		"Hmph, someone tried to copy my garden, but they'll never get it right.",
		"{player}, your roof's coming along, not as straight as mine, but coming along.",
		"I've been asked to judge the flower show, naturally.",
		"My door is the shiniest on the street, and I'd like that noted.",
	},
	shy = {
		"There's a quiet step behind the library where I read sometimes.",
		"Um, your boots are nice, sorry, that's all.",
		"I waved at someone new today, and they waved back.",
		"{player}, um, would you look at my drawing sometime? Only if you want to.",
		"I sat at the back of the library reading, and it was nice.",
	},
	cheeky = {
		"Somebody put a hat on the gull statue, no idea who, hehe.",
		"guess what, I taught the harbour dog to steal hats.",
		"The baker's looking for her rolling pin, so don't look at me.",
		"{player}, race you to the fountain, and loser buys buns, go!",
		"I hid all the bakery's spoons in the flowerpots, ok that was me.",
	},
	cool = {
		"The boats came back early, so the sea's calm.",
		"The pier's empty today, which is good for thinking.",
		"I found a path round the cliff, and it's shorter.",
		"{player}, I saw your new roof, and it's good.",
		"I ran the shore and saw a heron, that's all.",
	},
	prickly = {
		"Someone left a cart in the middle of the path, so I moved it, honestly.",
		"I hate gulls, but I gave the small one my crust anyway.",
		"{player}, your mailbox is crooked, so I'm bringing a hammer, I was passing anyway.",
		"I don't need help, but hold this, and don't let go.",
		"Everyone's so loud today except you, so don't let it go to your head.",
	},
	dramatic = {
		"I sang to the sea this morning, and it didn't sing back, how RUDE.",
		"The kettle whistled at me this morning, and I took it personally.",
		"{player}, when they write the story of this island, you'll be in chapter two.",
		"I've written a speech for the next festival, and it's only nine pages!",
		"*gasp* Someone moved my favourite bench three inches to the left.",
	},
	bookish = {
		"The lighthouse lamp turns once every ten seconds, because I timed it.",
		"I've been reading about tides, and the moon pulls the whole sea twice a day.",
		"Actually, a rainbow is a full circle, but the ground hides the bottom half.",
		"{player}, did you know snails can sleep for days at a time?",
		"Sorry, I'm rambling again, but did you know gulls can drink sea water?",
	},
	gloomy = {
		"My plant has only one leaf, but I talk to it anyway.",
		"The pier bench wobbles, but I sit on it anyway, so we understand each other.",
		"{player}, you look tired, so sit down, the world can manage without you for a minute.",
		"Heh, I found a coin on the path, so something bad's bound to happen now.",
		"I sat by the harbour all afternoon, and nobody bothered me.",
	},
	polite = {
		"I've started saying good morning to the gulls, which seems only right.",
		"If I may, {player}, the flower beds by the hall are a credit to the town.",
		"The market opens at eight, but I find quarter to is best, before the crowds.",
		"I've pressed my good hat for the festival, because one does like to be ready.",
		"I left a note about the loose step on the pier, very politely, of course.",
	},
	foodie = {
		"I had pie for breakfast, a small one, and then a second small one.",
		"The baker's new rye is too sour, and I had three slices to be sure.",
		"{player}, sweet or salty? I'm working out what to bring you.",
		"I tried baking with seaweed, so let's call it a learning experience.",
		"Have you eaten? The fish stall's doing chips with lemon today.",
	},
	nervous = {
		"I packed an umbrella and a spare coat, just in case, and it's sunny.",
		"I crossed the little bridge today and only looked down once.",
		"{player}, sorry, quick question, is the harbour wall meant to make that noise?",
		"I practised ordering at the bakery in the mirror, and then she already knew my order.",
		"S-sorry, I've been checking my stove all morning, but it's off, definitely off.",
	},
}

-- Jokes that land without explaining: a question, then the answer.
local JOKES = {
	"Why did the baker stop making doughnuts? She got tired of the hole thing.",
	"Why was the broom late? It overswept.",
	"Why did the biscuit go to the doctor? It was feeling crummy.",
	"What do clouds wear under their coats? Thunderwear.",
	"Where do fish keep their money? In the river bank.",
	"Why are fish so clever? They live in schools.",
	"What did the sea say to the beach? Nothing, it just waved.",
	"Why did the tomato turn red? It saw the salad dressing.",
	"What's a gull's favourite food? Whatever you're holding.",
}

-- How often they tell one: the cheeky, sunny and dramatic ones love a joke, the shy, prickly
-- and nervous ones keep theirs in.
local JOKY = {
	sunny = 2,
	gentle = 1,
	bold = 1,
	dreamy = 1,
	easygoing = 1,
	proud = 1,
	shy = 0,
	cheeky = 2,
	cool = 1,
	prickly = 0,
	dramatic = 2,
	bookish = 1,
	gloomy = 1,
	polite = 1,
	foodie = 1,
	nervous = 0,
}

-- What they think of a neighbour, by how well they get on.
local OPINION = {
	{
		min = 60,
		lines = {
			"If {y} needed help moving house, I'd be there before they asked.",
			"{y} saved me a seat by the fountain again, like they always do.",
			"{y} knows how I take my tea, and nobody else ever bothers.",
		},
	},
	{
		min = 30,
		lines = {
			"{y} fixed my gate without being asked, which was good of them.",
			"I had tea at {y}'s yesterday, and they've got a lovely view.",
		},
	},
	{
		min = 10,
		lines = {
			"{y} and I said good morning at the bakery, so that's a start.",
			"I've only chatted with {y} twice, but both times were nice.",
		},
	},
	{
		min = -10,
		lines = {
			"I've never really talked to {y}, should I?",
			"I keep meaning to say hello to {y}, and I keep not doing it.",
		},
	},
	{
		min = -40,
		lines = {
			"{y} and I rub each other up the wrong way, but it happens.",
			"{y} took the last bun right in front of me, and I'm not over it.",
		},
	},
	{
		min = -101,
		lines = {
			"Can we not talk about {y}, please?",
			"{y} and I are best kept at opposite ends of the square.",
		},
	},
}

-- What a neighbour is like, by their personality.
local LIKE = {
	sunny = "{y} said hello to me four times today, and I liked it every time.",
	gentle = "{y} left a cake on my step with no note, but I know it was them.",
	bold = "{y} carried my shopping up the hill and then ran back down again.",
	dreamy = "{y} asked me if fish ever get bored, and I've been thinking about it all day.",
	easygoing = "{y} was asleep on the pier when I went past, and still asleep when I came back.",
	proud = "{y} says their bread is the best on the island, and it really is.",
	shy = "{y} waved at me from across the square and then hid behind a stall.",
	cheeky = "{y} swapped my hat for a flowerpot, and I didn't notice till lunch.",
	cool = "{y} nodded at me this morning, which from them is a long chat.",
	prickly = "{y} said my porch was a mess, then swept it, grumbling the whole time.",
	dramatic = "{y} announced lunch like it was the end of a play, and it was soup.",
	bookish = "{y} told me why the sea is salty, and it took twenty minutes.",
	gloomy = "{y} told me the bridge creaks, and now I hear it every time.",
	polite = "{y} wrote me a thank you note for saying good morning.",
	foodie = "{y} can tell what every stall's cooking just by sniffing the air.",
	nervous = "{y} asked me if the pier was safe and then walked on it very slowly.",
}

-- A best friend, as close as two villagers get (there is no romance: the user, "remove any
-- romance, just best friends is the highest"). In the speaker's own way.
local BEST = {
	_ = "{y} is my best friend, and has been for ages.",
	sunny = "{y}'s my best friend, and I knitted us matching scarves, badly!",
	gentle = "{y} is my best friend, and they know when I need tea before I do.",
	bold = "{y}'s my best friend, so if they need me, I'm already on my way.",
	dreamy = "{y} is my best friend, and we can sit for hours without talking.",
	easygoing = "{y}'s my best friend, and we nap on the same bench, at different ends.",
	proud = "{y} is my best friend, and I chose well, as I always do.",
	shy = "{y} is my best friend, and I've never said that out loud before.",
	cheeky = "{y}'s my best friend, and we've got a secret knock that goes on for ages.",
	cool = "{y}'s my best friend, and that's all there is to it.",
	prickly = "{y}'s my best friend, ugh, so don't tell them I said that.",
	dramatic = "{y} is my best friend in all the world, and I'm writing them a song!",
	bookish = "{y} is my best friend, and we've argued about every book we've both read.",
	gloomy = "{y} is my best friend, and it feels like it rains less when they're around.",
	polite = "{y} is a very dear friend, and I count myself lucky.",
	foodie = "{y}'s my best friend, so I give them the last dumpling, which is how you know.",
	nervous = "{y} is my best friend, and I checked, and they said yes straight away.",
}
local LEVELS = Tuning.Relationships.Levels
local BEST_FRIENDS = LEVELS[#LEVELS].Min

-- By season (1 spring, 2 summer, 3 autumn, 4 winter).
local SEASON = {
	{
		"The daffodils by the hall all came out at once, like they'd planned it.",
		"I was spring cleaning and found the glove I lost in winter.",
		"Everything smells green and fresh today.",
	},
	{
		"It's too hot for shoes, so I'm being careful where I step.",
		"The beach is so packed that I could only find room for a towel.",
		"I've got a sunburnt nose, but only on the tip.",
	},
	{
		"Everything crunches underfoot now, and I love it.",
		"The trees on the hill went orange overnight, so go and look.",
		"It's dark by dinner time now, so it's soup weather.",
	},
	{
		"My fingers have been cold since Monday.",
		"There was frost on every roof this morning, and the town looked sugared.",
		"My winter plan is a blanket, a pot of tea and a window seat.",
	},
}

local WEATHER = {
	rain = {
		"The rain on the roof gave me the best sleep I've had in ages.",
		"My boots are still wet from yesterday, and now they're wet again.",
		"It's a good day for a book by the window.",
	},
	storm = {
		"That thunder rattled every cup in my cupboard.",
		"Every boat's tied up, and even the gulls are hiding.",
		"{player}, stay in tonight, because that wind means it.",
	},
	snow = {
		"Go and stand in the snow for a bit, it's quieter than you'd think.",
		"There's snow on every roof, and the whole town looks iced.",
		"I made a snowman, and he's leaning like me after a big lunch.",
	},
	blossom = {
		"I've got petals in my hair, and I'm keeping them there.",
		"Stand under the trees by the square, because it's like pink snow.",
		"I swept up the petals, and they blew straight back, so fair enough.",
	},
	leaves = {
		"I swept my step twice, and the leaves won both times.",
		"I've been stepping on every crunchy leaf I can find.",
		"A leaf landed on my head this morning and stayed there for an hour.",
	},
	clear = {
		"There isn't a cloud anywhere, so I'm not wasting today.",
		"You can see every island from the hill today.",
		"The sun's out and so is everyone, so the square's full.",
	},
	cloudy = {
		"It's grey out, but that's good for walking.",
		"The clouds are sitting right on top of the hill today.",
		"The sea's gone the colour of an old spoon today.",
	},
}

-- A craving, in their own words ({food} is the food's name, capitalised, so it starts a sentence).
local CRAVE = {
	_ = "{food} would really hit the spot right now.",
	sunny = "{player}, guess what I want? {food}, and I want it today!",
	gentle = "I've been good all week, {player}. {food} would be such a treat.",
	bold = "{food}, that's what I need, so today if you can.",
	dreamy = "I keep smelling something on the wind... {food}, I think, and now I want some.",
	easygoing = "Mm, {player}. {food} would hit the spot, but no rush.",
	proud = "I deserve a treat, frankly. {food}, and the good kind, please.",
	shy = "Um, {player}, sorry to ask. {food} would be really nice, but you don't have to.",
	cheeky = "{player}, here's a deal. {food}, and I won't prank you for a whole day.",
	cool = "{player}. {food}, if you're passing the market.",
	prickly = "Don't look at me like that. {food}, I want some, okay?",
	dramatic = "{player}, I shall perish without it! {food}, bring me some and I'll live again!",
	bookish = "I read an old cookbook last night. {food} has been on my mind ever since.",
	gloomy = "{food} would be nice, but it'll be sold out, as usual.",
	polite = "Forgive me for asking, {player}. {food} would be ever so welcome, if it's no trouble.",
	foodie = "{player}, have you eaten? {food} is all I've thought about since breakfast.",
	nervous = "S-sorry, {player}, is it greedy to ask? {food} would be really nice.",
}

-- Someone they'd like to meet.
local MEET = {
	_ = "I'd like to meet {y} properly, could you help?",
	sunny = "{player}, I want to be friends with {y}, so can you introduce us today?",
	gentle = "{y} always looks a little lonely, so would you introduce us, {player}?",
	bold = "{player}, introduce me to {y}, because I tried and they ran off.",
	dreamy = "{y} looks at the sea the same way I do, so could you introduce us?",
	easygoing = "{y} seems all right, so introduce us sometime, no rush.",
	proud = "{y} should meet me, it'd do them good, so could you arrange it, {player}?",
	shy = "Um, {player}, could you stand with me while I talk to {y}? I won't know what to say.",
	cheeky = "{y} looks fun to prank, I mean, fun to know, so introduce us?",
	cool = "{player}, introduce me to {y} sometime.",
	prickly = "Introduce me to that {y}, and don't make it weird, I'm only curious.",
	dramatic = "{player}, fate says I must meet {y}, so make it happen!",
	bookish = "I've seen {y} reading on the pier, and I'd love to ask what, so would you introduce us?",
	gloomy = "{y} won't like me, nobody does at first, but introduce us anyway?",
	polite = "{player}, would you be so kind as to introduce me to {y}?",
	foodie = "{y} always has the best snacks, so I need to know them, introduce us?",
	nervous = "{player}, could you introduce me to {y} and stay with me? What if I say something odd?",
}

-- The maps keyed by personality, for the specs (every personality has a voice in each).
Talk.Voices = {
	GREET = GREET,
	THANKS = THANKS,
	NOBED = NOBED,
	QUARREL = QUARREL,
	FRIEND = FRIEND,
	OWN = OWN,
	JOKY = JOKY,
	LIKE = LIKE,
	BEST = BEST,
	CRAVE = CRAVE,
	MEET = MEET,
}
-- And the lines anybody says, for the same checks.
Talk.Shared = { SMALL = SMALL, JOKES = JOKES, OPINION = OPINION, SEASON = SEASON, WEATHER = WEATHER }

-- Their last event, as they'd tell it, while it's still fresh.
function Talk.memo(v: any, now: number?): string?
	local m = v and v.memo
	if type(m) ~= "table" or type(m.text) ~= "string" or type(m.t) ~= "number" or not now then
		return nil
	end
	local fresh = Tuning.Events.MemoHours * Tuning.Day.Length / 24
	if now - m.t > fresh or now < m.t then
		return nil
	end
	return m.text
end

-- A villager's wish in their own words, or nil when they have none to tell. (A wish for a talk
-- isn't told: the talk answers it.)
local function wishFor(profile: any, vid: string): string?
	local v = profile.villagers[vid]
	local w = v and v.wish
	if not w then
		return nil
	end
	if w.kind == "food" then
		local food = Foods.get(w.arg)
		if food then
			return Text.fill(own(CRAVE, v.pers), { food = food.name })
		end
		return "I keep thinking about something nice to eat."
	elseif w.kind == "friend" then
		local other = profile.villagers[w.arg]
		if other then
			return Text.fill(own(MEET, v.pers), { y = other.name })
		end
	end
	return nil
end

-- The line for what they're wishing for, or nil.
function Talk.wishLine(profile: any, vid: string): string?
	local line = wishFor(profile, vid)
	return if line then (Text.fill(line, { player = Text.playerName(profile) })) else nil
end

-- {player} in a line is the player's name (the user: "the player is to be referred to as their
-- player name"): filled in here, as the line leaves. `name` is whoever is talking to them when
-- that isn't the town's owner (a visitor); otherwise it is the owner's own name.
local function named(profile: any, text: string, name: any): string
	local who = if type(name) == "string" and name ~= "" then name else Text.playerName(profile)
	return (Text.fill(text, { player = who }))
end

-- What a villager says to someone who stops to talk. opts:
--   first    they were just walked up to (a greeting, or their wish); otherwise it is small talk
--   last     what they said last, so they don't say it twice running
--   working  they are at work right now (their job's lines join in)
--   now      os time, for quarrels and how fresh their last event is
--   chat     what Talk.chat made of this talk, when it is the town's owner talking
--   season   1..4, and weather (World's), when known
--   name     what to call the one talking, when it is a visitor and not the town's owner
local function lineFor(profile: any, vid: string, rng: any, opts: { [string]: any }?): string
	local v = profile.villagers[vid]
	if not v then
		return "..."
	end
	local o: { [string]: any } = opts or {}
	local pers = Personalities.get(v.pers)
	local pool: { string } = {}
	local function add(text: string?, weight: number?)
		if text and text ~= "" then
			for _ = 1, weight or 1 do
				table.insert(pool, text)
			end
		end
	end
	local function addLines(kind: string, weight: number?)
		local lines: { string } = if pers then (pers.lines[kind] or {}) else {}
		for _, text in lines do
			add(text, weight)
		end
	end
	local saying = Sayings.get(v.saying)
	local chat: Chat? = o.chat
	if chat and chat.wish then
		add(own(THANKS, v.pers))
		add("That helped a lot, {player}, thank you.")
	elseif o.first then
		local wish = wishFor(profile, vid)
		if wish then
			return wish
		end
		-- their hello (which they say to each other too), or one just for you, with your name
		addLines("hello", 2)
		for _, text in GREET[v.pers] or {} do
			add(text, 2)
		end
		add(saying and saying.text)
	else
		local sad = v.mood < 35
		if sad then
			addLines("sad", 2)
		elseif v.mood >= 65 then
			addLines("happy", 2)
		end
		if not v.bed then
			add(own(NOBED, v.pers), 3)
		end
		for _, other in profile.order do
			local ov = profile.villagers[other]
			if ov and other ~= vid and Relationships.quarreling(profile, vid, other, o.now or 0) then
				add(Text.fill(own(QUARREL, v.pers), { y = ov.name }), 3)
			end
		end
		if not sad then
			for _, text in SMALL do
				add(text)
			end
			for _, text in OWN[v.pers] or {} do
				add(text)
			end
			if v.bed then
				add("I slept like a log last night, which was lovely.")
			end
			add(saying and saying.text)
			local hobby = Sayings.hobby(v.hobby)
			add(hobby and hobby.line, 2)
			local friend = Relationships.bestFriend(profile, vid)
			local fv = friend and profile.villagers[friend]
			if fv and friend and not Relationships.quarreling(profile, vid, friend, o.now or 0) then
				add(Text.fill(own(FRIEND, v.pers), { y = fv.name }), 2)
			end
			local work = o.working and City.jobOf(profile, vid)
			if work then
				for _, text in work.job.lines do
					add(text)
				end
			end
			-- what they got up to lately
			add(Talk.memo(v, o.now), 3)
			-- a neighbour or two: how they get on, what they're like, a best friend
			local others = {}
			for _, other in profile.order do
				if other ~= vid and profile.villagers[other] then
					table.insert(others, other)
				end
			end
			for _ = 1, math.min(2, #others) do
				local other: string = table.remove(others, rng:int(1, #others)) :: string
				local ov = profile.villagers[other]
				local score = Relationships.peek(profile, vid, other)
				for _, band in OPINION do
					if score >= band.min then
						add(Text.fill(rng:pick(band.lines), { y = ov.name }))
						break
					end
				end
				local like = LIKE[ov.pers]
				if like then
					add(Text.fill(like, { y = ov.name }))
				end
				if score >= BEST_FRIENDS then
					add(Text.fill(own(BEST, v.pers), { y = ov.name }), 2)
				end
			end
			-- a worry, a joke (more from the cheeky ones), the season and the weather
			addLines("worry")
			add(rng:pick(JOKES), JOKY[v.pers] or 1)
			if type(o.season) == "number" and SEASON[o.season] then
				add(rng:pick(SEASON[o.season]))
			end
			if type(o.weather) == "string" and WEATHER[o.weather] then
				add(rng:pick(WEATHER[o.weather]))
			end
		end
	end
	-- not the same thing twice running, when there is anything else to say (`last` is what they
	-- said, with the name in)
	if o.last then
		local fresh = {}
		for _, text in pool do
			if text ~= o.last and named(profile, text, o.name) ~= o.last then
				table.insert(fresh, text)
			end
		end
		if #fresh > 0 then
			pool = fresh
		end
	end
	if #pool == 0 then
		return "..."
	end
	return rng:pick(pool)
end

-- What a villager says when you stop to talk: their own words, about how they feel, the town, the
-- people they know, or what they're wishing for. opts.name is what to call a visitor (see above).
function Talk.line(profile: any, vid: string, rng: any, opts: { [string]: any }?): string
	return named(profile, lineFor(profile, vid, rng, opts), opts and opts.name)
end

-- The good a chat does ---------------------------------------------------------------------------------

-- How many more chats with a villager count on in-game day `day`.
function Talk.left(profile: any, vid: string, day: number): number
	local v = profile.villagers[vid]
	if not v then
		return 0
	end
	local had = if v.chatDay == day then (v.chats or 0) else 0
	return math.max(0, K.ChatsPerDay - had)
end

-- The town's owner chats with one of their villagers on in-game day `day`. The first few a day
-- count: a little mood and a heart point each. A villager who wished for a talk has the wish
-- granted, whatever the count. Heart levels and a granted wish add their notices to `notices`.
function Talk.chat(profile: any, vid: string, day: number, rng: any, notices: { string }?): Chat
	local out: Chat = { counted = false, hearts = 0, mood = 0, left = 0, wish = false, coins = 0 }
	local v = profile.villagers[vid]
	if not v then
		return out
	end
	if v.wish and v.wish.kind == "cheer" then
		local granted, coins, said = Life.grantWish(profile, vid, "cheer", nil, rng)
		if granted then
			out.wish = true
			out.coins = coins
			if notices then
				for _, n in said do
					table.insert(notices, n)
				end
			end
		end
	end
	if v.chatDay ~= day then
		v.chatDay = day
		v.chats = 0
	end
	local had: number = v.chats or 0
	if had < K.ChatsPerDay then
		v.chats = had + 1
		local before: number = v.mood
		v.mood = math.clamp(before + K.ChatMood, Tuning.Villagers.MoodMin, Tuning.Villagers.MoodMax)
		out.mood = v.mood - before
		Life.addHearts(profile, vid, K.ChatHearts, rng, notices)
		out.hearts = K.ChatHearts
		out.counted = true
	end
	out.left = math.max(0, K.ChatsPerDay - (v.chats or 0))
	return out
end

-- What the talk card says about a chat, under the villager's words.
function Talk.note(profile: any, vid: string, chat: Chat): string
	local v = profile.villagers[vid]
	local name = if v then v.name else "?"
	if chat.wish then
		return Text.fill("{x} feels better for the talk.", { x = name })
	elseif chat.counted then
		return Text.fill(
			"{x} enjoyed that. Chat {n} of {max} today.",
			{ x = name, n = K.ChatsPerDay - chat.left, max = K.ChatsPerDay }
		)
	end
	return "You two have caught up for today."
end

return Talk
