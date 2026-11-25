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
local Voice = require(script.Parent.Voice)

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
		"{player}, {player}, the ferry's got a new bell, so let's go hear it!",
		"Ehehe, {player}, perfect timing, I've got news!",
		"Hi, {player}, a gull just stole a whole pie!",
	},
	gentle = {
		"Oh, {player}, I made too much stew, so take some home with you.",
		"Oh my, {player}, you look tired, so sit with me, okay?",
		"{player}, there you are, have you eaten? I saved you some beans.",
	},
	bold = {
		"{player}, you're free, right? The harbour needs a hand.",
		"Hah, {player}, walk with me to the sea wall.",
		"Hey, {player}, have you seen how high the tide is today?",
	},
	dreamy = {
		"{player}, the boat bells were ringing this morning, did you hear them?",
		"Oh, {player}, I was counting boats and lost count.",
		"{player}... oh, hello, sorry, where was I?",
	},
	easygoing = {
		"*yawn* Oh, hey, {player}, is it lunch already?",
		"Hey, {player}, bring me an apple from the market sometime, no rush.",
		"Mm, hi, {player}, I've been resting since breakfast.",
	},
	proud = {
		"{player}, I beat everyone at chess today, naturally.",
		"Ah, {player}, have you noticed my new window boxes? Everyone else has.",
		"Hmph, {player}, come and see my best painting yet.",
	},
	shy = {
		"Um, hi, {player}, I didn't think you'd stop.",
		"{player}, um, s-sorry, I didn't mean to stare.",
		"{player}, um, I brought you a cookie (you don't have to take it).",
	},
	cheeky = {
		"{player}, don't drink from the fountain today, hehe, no reason.",
		"{player}, if anyone asks, I was with you all morning, okay?",
		"{player}, quick, watch the baker open her flour bag :P",
	},
	cool = {
		"{player}, hey.",
		"{player}, your place looks good from the road.",
		"Hm, {player}, the pier's third step is loose, so I roped it off.",
	},
	prickly = {
		"{player}, your path's full of weeds, and hi.",
		"{player}, I brought your trash can in, since I was passing anyway.",
		"Ugh, {player}, your shoelace is undone, and no, I'm not tying it.",
	},
	dramatic = {
		"{player}, thank goodness, you're the only one who understands me!",
		"*gasp* {player}, something HUGE has happened!",
		"{player}, the bakery's out of buns, and it's the WORST day ever.",
	},
	bookish = {
		"Oh, {player}, did you know a group of crows is called a murder?",
		"{player}, good, I've saved up a fact for you.",
		"{player}, I've worked out exactly how old the lighthouse is (114 years, I think).",
	},
	gloomy = {
		"Oh, {player}, my umbrella broke again, as usual.",
		"Heh... {player}, you look cheerful, so I'll try not to spoil it.",
		"{player}, hi, did you want something, or are you just being nice?",
	},
	polite = {
		"Good day, {player}, I hope I am not keeping you.",
		"Hello, {player}, how lovely to see you today.",
		"{player}, what a nice surprise, please sit with me.",
	},
	foodie = {
		"{player}, have you eaten? I've already had two snacks.",
		"Mmm, {player}, the café has cheese buns now!",
		"Yum, {player}, the fish stall's frying today, come on!",
	},
	nervous = {
		"Oh, {player}, phew, I thought you were the big dog from the hill.",
		"{player}, h-hi, is everything okay with you?",
		"{player}, sorry, hi, did you hear a bang earlier, or was it just me?",
	},
}

-- After a talk that answered their wish for one.
local THANKS = {
	_ = "Thanks for stopping, {player}, that really helped.",
	sunny = "{player}, thank you, thank you, I feel so much better!",
	gentle = "Thank you, {player}, I feel much better, so go and rest too, okay?",
	bold = "...Thanks, {player}, I needed that more than I said.",
	dreamy = "Hmm, the grey feeling's gone now, thank you, {player}.",
	easygoing = "Haha, thanks, {player}, that was as good as a nap.",
	proud = "Th-that wasn't me being sad, but thank you, {player}.",
	shy = "Um, thank you, {player}, I feel a lot better.",
	cheeky = "ok, real thanks, {player}, no joke.",
	cool = "{player}, that helped, thanks.",
	prickly = "Don't read into it, {player}, but thanks.",
	dramatic = "{player}, you've saved my whole LIFE, thank you!",
	bookish = "Thank you, {player}, that helped more than a good book.",
	gloomy = "Huh, I actually feel better, thanks, {player}.",
	polite = "Thank you kindly, {player}, I feel much more myself now.",
	foodie = "Thanks, {player}, that cheered me up more than a cake would.",
	nervous = "Oh, I can breathe again, thank you, {player}.",
}

-- No bed yet.
local NOBED = {
	_ = "I still don't have a bed, you know.",
	sunny = "{player}, I've got no bed, so I'm sleeping on coats!",
	gentle = "Sorry to fuss, {player}, but without a bed I can't sleep well.",
	bold = "I'm still on the floor, so get me a bed, right?",
	dreamy = "A bed would be nice, I keep sleeping in odd places...",
	easygoing = "Eh, the floor's comfy, but a bed would be comfier.",
	proud = "Hmph, someone like me shouldn't be sleeping on a rug.",
	shy = "Um, I don't have a bed yet, but the rug's okay.",
	cheeky = "{player}, I'm sleeping in the bath, so a bed, please?",
	cool = "Still no bed, and the floor's cold.",
	prickly = "Ugh, I don't care about a bed, but my back does.",
	dramatic = "*sob* {player}, how many more nights on this cruel FLOOR?",
	bookish = "Actually, I still haven't got a bed, and I've read that floors are bad for your back.",
	gloomy = "Still no bed, as usual, so the floor and I are close now.",
	polite = "Forgive me, {player}, but I still do not have a bed.",
	foodie = "No bed yet, so I sleep next to the bread box.",
	nervous = "{player}, um, I still don't have a bed, is that okay?",
}

-- A quarrel that hasn't blown over.
local QUARREL = {
	_ = "{y} and I aren't talking at the moment.",
	sunny = "{y} and I had a fight, and I hate it!",
	gentle = "{y} and I had an argument, and I want to make it right.",
	bold = "Don't bring up {y}, we're not talking.",
	dreamy = "{y} and I aren't speaking, and I can't remember why...",
	easygoing = "Eh, me and {y} aren't talking, but give it a day.",
	proud = "I'm not speaking to {y} until they apologise.",
	shy = "Um, {y} and I argued, and I don't know what to say...",
	cheeky = "{y} and I are fighting, and I think I'm winning.",
	cool = "{y} and I aren't talking, and that's all.",
	prickly = "Don't say {y}'s name, ugh, fine, I miss them.",
	dramatic = "{y} and I are ENEMIES now, at least until Friday!",
	bookish = "Actually, {y} and I disagree about the tide tables, and we're both stubborn.",
	gloomy = "{y} isn't talking to me, and I knew that would happen.",
	polite = "{y} and I disagreed, and I would like to say sorry.",
	foodie = "{y} and I fell out over the last dumpling.",
	nervous = "{y} is mad at me, and what if it's forever?",
}

-- Their best friend, the one at the top.
local FRIEND = {
	_ = "{y} always makes me laugh.",
	sunny = "{y} and I sat on the pier until it got dark, ehehe!",
	gentle = "{y} walked me home in the rain under their umbrella.",
	bold = "{y}'s solid, and they've always got my back.",
	dreamy = "{y} watched the clouds with me for an hour.",
	easygoing = "Me and {y} did nothing all afternoon, and it was great.",
	proud = "{y} came to watch me win and clapped the loudest.",
	shy = "{y} talks to me a lot, and I like that.",
	cheeky = "{y} helped me hide the baker's rolling pin, hehe.",
	cool = "{y}'s good company, and they don't talk much.",
	prickly = "{y}'s annoying, but I'd carry their boxes up the hill.",
	dramatic = "{y} is my dearest friend in the whole world!",
	bookish = "{y} brought back all four books I lent them, on time.",
	gloomy = "{y} never minds when I'm gloomy, and they bring cookies.",
	polite = "I've kept the card {y} sent when I was ill.",
	foodie = "{y} shares their chips without me even asking.",
	nervous = "{y} walks me past the big dog every morning.",
}

-- Small talk anybody might make on an ordinary day.
local SMALL = {
	"{player}, what are you building next? I keep hearing your hammer.",
	"It's a quiet day, and the square's half empty.",
	"The harbour smelled like rain, but it never came.",
	"Somebody on a boat waved, so I waved back.",
	"The bakery line went around the corner today.",
	"Someone keeps leaving flowers on the pier bench.",
	"I watched the ferry come in from the hill.",
	"The fountain's been extra splashy since the wind changed.",
	"I tidied one drawer today, which is a start.",
	"The new bench by the hall is really comfy.",
}

-- Small talk of their own, by personality.
local OWN = {
	sunny = {
		"I counted fourteen boats in the harbour today!",
		"Somebody planted flowers around the fountain, and I need to know who!",
		"Let's get the whole street to have lunch in the square together!",
		"{player}, I know the baker's middle name now, ehehe.",
		"I threw the harbour dog's stick eleven times!",
	},
	gentle = {
		"Your coat's lost a button, so leave it with me and I'll sew it on.",
		"The baker's been coughing, so I'm taking her honey.",
		"{player}, you've worked all week, so rest tomorrow, okay?",
		"I planted mint by my door, so help yourself.",
		"The sparrow at my window brought a friend.",
	},
	bold = {
		"I cleared the fallen branch off the hill path.",
		"Anything heavy need lifting? Just point at it.",
		"{player}, you're helping with the sea wall on Saturday, right?",
		"Tonight I'm catching whoever drops trash on the pier.",
		"I carried the baker's new oven up her steps by myself!",
	},
	dreamy = {
		"I followed a cat around the square all morning...",
		"You can feel the waves through the pier if you lie on it.",
		"{player}, did you see the moon out at lunchtime?",
		"I found a grey feather with a white tip.",
		"I meant to tell you something, but it's gone.",
	},
	easygoing = {
		"I had a busy morning, and by busy I mean I watched the tide come in.",
		"Not much to report, which is how I like it.",
		"Mm, I had plans today, but eh, they can wait.",
		"{player}, you should try lying in the long grass on the hill sometime.",
		"The baker asked me to sweep her porch, and I said the wind does it for free.",
	},
	proud = {
		"I've started a list of everything I'm best at, and it's on its second page.",
		"Hmph, someone copied my garden, badly.",
		"{player}, your roof's nearly as straight as mine.",
		"They've asked me to judge the flower show, and of course I said yes.",
		"The hall wants to borrow my good chairs for the festival, naturally.",
	},
	shy = {
		"I tried the new tea at the café, and I think I'll go back.",
		"Um, your boots are nice, sorry, that's all.",
		"I waved at someone new, and they waved back.",
		"{player}, um, would you look at my drawing sometime?",
		"I went to the story reading at the library and sat at the back.",
	},
	cheeky = {
		"Somebody's put a bow tie on the harbour dog, hehe.",
		"guess who tied a bell to the baker's door? not saying.",
		"The baker's lost her rolling pin, hehe.",
		"{player}, race you to the fountain, go!",
		"ok, it was me who hid the bakery's spoons.",
	},
	cool = {
		"Boats came in early, so keep a coat handy.",
		"The bakery's out of rye by nine, so go early.",
		"Someone left a rowing boat untied at the pier, so I tied it.",
		"{player}, if you need a hand building, just ask.",
		"I saw a heron on my run.",
	},
	prickly = {
		"Tsk, someone left a cart right in the path.",
		"I gave a gull my crust, so don't tell anyone.",
		"{player}, your mailbox is crooked, so I'll fix it.",
		"I don't need help, but hold this.",
		"Everyone's so loud today, except you, I suppose.",
	},
	dramatic = {
		"The baker spelled my name wrong on my cake, and I may never recover.",
		"The fountain splashed me on PURPOSE, and I'm hurt.",
		"{player}, you're in chapter two of my life story.",
		"My festival speech is only nine pages so far!",
		"*gasp* Someone moved my favourite bench three inches!",
	},
	bookish = {
		"The lighthouse lamp turns once every ten seconds, I timed it.",
		"Did you know the tide comes in twice a day because of the moon?",
		"Actually, a rainbow's a full circle, and the ground hides half.",
		"{player}, I read that snails can sleep for days at a time.",
		"Did you know gulls can drink sea water?",
	},
	gloomy = {
		"My plant only has one leaf left.",
		"The pier bench wobbles, but we understand each other.",
		"{player}, you look tired, so sit with me.",
		"I found a coin, so something bad's coming.",
		"Nobody bothered me at the harbour all afternoon.",
	},
	polite = {
		"I have started saying good morning to the gulls.",
		"If I may say so, {player}, your garden looks very nice.",
		"The market opens at eight, but I like to be there at a quarter to eight.",
		"I am writing letters again, and I had forgotten how much I like it.",
		"I told the harbour master about the loose step on the pier, very politely.",
	},
	foodie = {
		"I had two small pies for breakfast.",
		"I tried three slices of the new rye to be sure, and it's too sour.",
		"{player}, sweet or salty? I'm bringing you something.",
		"I baked with seaweed, and I learned a lot.",
		"Have you eaten? There's a pie cart down by the harbour today.",
	},
	nervous = {
		"I always carry a spare coat, just in case the weather turns.",
		"I crossed the bridge and only looked down once.",
		"{player}, s-sorry, should the harbour wall creak like that?",
		"I practised my order all the way to the bakery, and she already knew it.",
		"I've checked my stove five times this morning, and it's still off.",
	},
}

-- Jokes that land without explaining: a question, then the answer.
local JOKES = {
	"Why did the baker stop making doughnuts? She got tired of the hole thing.",
	"Why was the broom late? It overswept.",
	"Why did the cookie go to the doctor? It was feeling crummy.",
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
			"If {y} needed help, I'd be there before they asked.",
			"{y} saved me a seat by the fountain again.",
			"{y} knows how I take my tea.",
		},
	},
	{
		min = 30,
		lines = {
			"{y} fixed my gate without being asked.",
			"I had tea at {y}'s, and what a view.",
		},
	},
	{
		min = 10,
		lines = {
			"{y} and I said good morning at the bakery.",
			"I've only chatted with {y} twice, but it was nice.",
		},
	},
	{
		min = -10,
		lines = {
			"I've never really talked to {y}, should I?",
			"I keep meaning to say hello to {y}.",
		},
	},
	{
		min = -40,
		lines = {
			"{y} and I just don't get along.",
			"{y} took the last bun right in front of me.",
		},
	},
	{
		min = -101,
		lines = {
			"Can we not talk about {y}, please?",
			"{y} and I should stay at opposite ends of the square.",
		},
	},
}

-- What a neighbour is like, by their personality.
local LIKE = {
	sunny = "{y} said hello to me four times today!",
	gentle = "{y} left a cake outside my door without a note.",
	bold = "{y} carried my shopping up the hill without asking.",
	dreamy = "{y} asked if fish get bored, and now I wonder too.",
	easygoing = "{y} slept on the pier all afternoon.",
	proud = "{y} says their bread's the island's best, and it is.",
	shy = "{y} waved at me and then hid behind a stall.",
	cheeky = "{y} swapped my hat for a flowerpot!",
	cool = "{y} nodded at me today, which from them is a long chat.",
	prickly = "{y} called my porch a mess, then swept it, grumbling.",
	dramatic = "{y} told me lunch was ready like it was the last scene of a play.",
	bookish = "{y} spent twenty minutes telling me why the sea is salty.",
	gloomy = "{y} said the bridge creaks, and now I always hear it.",
	polite = "{y} wrote me a thank you note for saying good morning.",
	foodie = "{y} can tell what every stall's cooking by the smell.",
	nervous = "{y} asked if the pier was safe, then tiptoed across.",
}

-- A best friend, as close as two villagers get (there is no romance: the user, "remove any
-- romance, just best friends is the highest"). In the speaker's own way.
local BEST = {
	_ = "{y}'s been my best friend for ages.",
	sunny = "{y}'s my best friend, so I knitted us scarves!",
	gentle = "My best friend {y} always knows when I need tea.",
	bold = "{y}'s my best friend, so I've got their back.",
	dreamy = "{y}'s my best friend, and we don't need words.",
	easygoing = "{y}'s my best friend, and the best nap company.",
	proud = "{y}'s my best friend, and I chose well.",
	shy = "{y}'s my best friend, um, I've never said that out loud.",
	cheeky = "{y}'s my best friend, and we've got a secret knock.",
	cool = "{y}'s my best friend, that's all.",
	prickly = "{y}'s my best friend, ugh, don't tell them.",
	dramatic = "{y}'s my best friend, so I'm writing them a song!",
	bookish = "{y} is my best friend, and we argue about every book.",
	gloomy = "{y}'s my best friend, and they're the only one who laughs at my jokes.",
	polite = "{y} is a very good friend, and I feel lucky every day.",
	foodie = "{y}'s my best friend, so they get my last dumpling.",
	nervous = "{y} is my best friend, I checked, and they said yes.",
}
local LEVELS = Tuning.Relationships.Levels
local BEST_FRIENDS = LEVELS[#LEVELS].Min

-- By season (1 spring, 2 summer, 3 autumn, 4 winter).
local SEASON = {
	{
		"The daffodils by the hall all came out at once.",
		"Spring cleaning turned up my lost winter glove.",
		"Everything smells green and fresh today.",
	},
	{
		"It stays light so late now that I keep forgetting dinner.",
		"The beach has been packed every afternoon this week.",
		"I've got a sunburnt nose, just the tip.",
	},
	{
		"Everything crunches underfoot now, and I love it.",
		"The trees on the hill went orange overnight.",
		"It's dark by dinner now, which means soup.",
	},
	{
		"My fingers have been cold since Monday.",
		"There was frost on every roof this morning, like sugar.",
		"My winter plan is a blanket and a cup of tea by the window.",
	},
}

local WEATHER = {
	rain = {
		"Rain on the roof always helps me sleep.",
		"My boots haven't dried since yesterday.",
		"It's a good day to read by the window.",
	},
	storm = {
		"That thunder rattled every cup in my cupboard.",
		"Every boat's tied up, and even the gulls are hiding.",
		"{player}, stay in tonight, because that wind means it.",
	},
	snow = {
		"Go and stand in the snow, it's quieter than you'd think.",
		"The snow on the roofs looks like icing.",
		"My snowman's leaning like me after a big lunch.",
	},
	blossom = {
		"I've got petals in my hair, and I'm keeping them.",
		"The trees by the square are dropping petals like pink snow.",
		"I swept up the petals, and they blew straight back.",
	},
	leaves = {
		"I swept outside my door twice, and the leaves won.",
		"I've stepped on every crunchy leaf I could find.",
		"I had a leaf stuck in my hair all morning, and nobody told me.",
	},
	clear = {
		"There's not a cloud anywhere today.",
		"You can see every island from the hill today.",
		"Clear skies all day, so my laundry's finally dry.",
	},
	cloudy = {
		"It's grey out, but that's good for walking.",
		"The clouds are sitting right on the hill.",
		"It's so grey that I nearly brought an umbrella, just in case.",
	},
}

-- A craving, in their own words ({food} as it reads inside a sentence: "a rice ball", "ice cream").
local CRAVE = {
	_ = "I could really go for {food} right now.",
	sunny = "{player}, {player}, let's go get {food} together today!",
	gentle = "I've been good all week, {player}, so {food} would be such a treat.",
	bold = "Hah, {player}, I need {food} today, so you'll get me some, right?",
	dreamy = "Hmm... I keep thinking about {food}, I can almost smell it.",
	easygoing = "Mm, {player}, {food} would be nice, no rush.",
	proud = "I think I've earned {food}, and only the good kind, please.",
	shy = "Um, sorry, {player}... {food} would be nice, but you don't have to.",
	cheeky = "{player}, deal? get me {food} and i won't prank you for a whole day",
	cool = "{player}. If you're passing the market, I'd like {food}.",
	prickly = "Ugh, don't stare, I just want {food}.",
	dramatic = "{player}, I'll simply DIE if I don't have {food} today!",
	bookish = "I've been reading an old cookbook, and now I can't stop thinking about {food}.",
	gloomy = "I'd like {food}, but they'll have sold out, as usual.",
	polite = "{player}, if it is no trouble, {food} would be very welcome.",
	foodie = "{player}, I've been dreaming about {food} since breakfast.",
	nervous = "S-sorry, {player}, is it greedy if I ask for {food}?",
}

-- Someone they'd like to meet.
local MEET = {
	_ = "I'd like to meet {y} properly, could you help?",
	sunny = "{player}, introduce me to {y}, I want us to be friends!",
	gentle = "{y} looks lonely, so would you introduce us?",
	bold = "{player}, introduce me to {y}, I tried and they ran off.",
	dreamy = "{y} looks at the sea like I do, so could you introduce us?",
	easygoing = "{y} seems nice, so introduce us, no rush.",
	proud = "Naturally, {y} should meet me, so arrange it, {player}.",
	shy = "Um, {player}, would you stand with me while I meet {y}?",
	cheeky = "{y} looks fun to prank, I mean, to know, so introduce us?",
	cool = "{player}, introduce me to {y} sometime.",
	prickly = "Introduce me to {y}, and don't make it weird.",
	dramatic = "{player}, fate says I must meet {y}, so make it happen!",
	bookish = "I've seen {y} reading on the pier, so would you introduce us?",
	gloomy = "{y} won't like me, but introduce us anyway?",
	polite = "{player}, would you please introduce me to {y}, if it is no trouble?",
	foodie = "{y} always has the best snacks, so introduce us?",
	nervous = "{player}, could you introduce me to {y}? What if I say something odd?",
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
			return Text.fill(own(CRAVE, v.pers), { food = Foods.phrase(food) })
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

-- {player} in a line is the player's name (the user: "the player is to be referred to as their
-- player name"): filled in here, as the line leaves. `name` is whoever is talking to them when
-- that isn't the town's owner (a visitor); otherwise it is the owner's own name.
local function named(profile: any, text: string, name: any): string
	local who = if type(name) == "string" and name ~= "" then name else Text.playerName(profile)
	-- a line that opens with the name starts with a capital, even when the name is "friend"
	if text:sub(1, 8) == "{player}" then
		who = who:sub(1, 1):upper() .. who:sub(2)
	end
	return (Text.fill(text, { player = who }))
end

-- The line for what they're wishing for, or nil.
function Talk.wishLine(profile: any, vid: string): string?
	local line = wishFor(profile, vid)
	local v = profile.villagers[vid]
	return if line then Voice.speak(v and v.pers, named(profile, line, nil)) else nil
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
				add("I slept really well last night, which was lovely.")
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
	-- said, with the name in and in their own hand: Sim/Voice)
	if o.last then
		local fresh = {}
		for _, text in pool do
			local said = named(profile, text, o.name)
			if text ~= o.last and said ~= o.last and Voice.speak(v.pers, said) ~= o.last then
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
	local v = profile.villagers[vid]
	-- in their own hand (Sim/Voice)
	return Voice.speak(v and v.pers, named(profile, lineFor(profile, vid, rng, opts), opts and opts.name))
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
