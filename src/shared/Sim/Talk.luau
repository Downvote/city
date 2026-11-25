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
		"{player}, perfect timing, I've got news!",
		"Hi, {player}, a gull just stole a whole pie!",
	},
	gentle = {
		"Hello, {player}, have you had a proper meal today?",
		"Oh, {player}, come and sit for a bit.",
		"{player}, there you are, I saved you some beans.",
	},
	bold = {
		"{player}, you're free, right? The harbour needs a hand.",
		"{player}, walk with me to the sea wall.",
		"Hey, {player}, somebody left the square gate open again.",
	},
	dreamy = {
		"{player}, there's a tiny rainbow in the fountain.",
		"Oh, {player}, I was counting boats and lost count.",
		"{player}... oh, hello, I was miles away.",
	},
	easygoing = {
		"*yawn* Oh, hey, {player}, is it lunch already?",
		"Hey, {player}, bring me an apple from the market?",
		"Mm, hi, {player}, I've been resting since breakfast.",
	},
	proud = {
		"{player}, you'll want to hear this, I won again.",
		"Ah, {player}, I've got something excellent to show you.",
		"{player}, you've come just as I finished something brilliant.",
	},
	shy = {
		"Um, hi, {player}, I didn't think you'd stop.",
		"{player}, um, I'm not busy, if you want to talk.",
		"Oh, {player}, um, the library cat let me stroke it.",
	},
	cheeky = {
		"Psst, {player}, over here, and act normal.",
		"{player}, don't look at the fountain yet, okay, now look.",
		"Oh, {player}, perfect, I need a lookout.",
	},
	cool = {
		"{player}, hey.",
		"{player}, your new roof looks good from the road.",
		"Oh, {player}, the tide's out, so it's good walking.",
	},
	prickly = {
		"{player}, your path's full of weeds, and hi.",
		"Oh, it's you, {player}, what do you want? Fine, hello.",
		"{player}, you again, so sit down, but not there.",
	},
	dramatic = {
		"{player}, at LAST, I've been waiting all day!",
		"Ah, {player}, something tremendous has happened!",
		"{player}, stop and listen, I have news of great importance!",
	},
	bookish = {
		"Hello, {player}, did you know honey never goes off?",
		"Oh, {player}, sorry, I was halfway through a chapter.",
		"{player}, I've worked out exactly how old the lighthouse is.",
	},
	gloomy = {
		"Oh, {player}, my umbrella broke again, as usual.",
		"{player}, you came over, huh, that's nice.",
		"{player}, hi, I thought nobody would stop today.",
	},
	polite = {
		"Good day, {player}, I hope I'm not keeping you.",
		"Hello, {player}, how lovely, I was admiring the harbour.",
		"{player}, how are you keeping? Well, I hope.",
	},
	foodie = {
		"{player}, have you eaten? I've already had two snacks.",
		"Hi, {player}, can you smell that? The bakery's doing cinnamon.",
		"{player}, the fish stall's frying today, so come on!",
	},
	nervous = {
		"Oh, {player}, sorry, you made me jump, hi.",
		"{player}, h-hi, is everything okay with you?",
		"{player}, sorry, hi, I locked my door three times today.",
	},
}

-- After a talk that answered their wish for one.
local THANKS = {
	_ = "Thanks for stopping, {player}, that really helped.",
	sunny = "{player}, thank you, I feel so much better!",
	gentle = "Thank you, {player}, I'll pay you back in soup.",
	bold = "...Thanks, {player}, lunch is on me.",
	dreamy = "Hmm, the grey feeling's gone now, thank you, {player}.",
	easygoing = "Heh, thanks, {player}, that was as good as a nap.",
	proud = "Th-that wasn't me being sad, but thank you, {player}.",
	shy = "Um, thank you, {player}, I feel a lot better.",
	cheeky = "ok, real thanks, {player}, no joke.",
	cool = "{player}, that helped, thanks.",
	prickly = "Don't make it a thing, {player}, but thanks.",
	dramatic = "{player}, you've rescued me from DESPAIR, thank you!",
	bookish = "Thank you, {player}, that helped more than a good book.",
	gloomy = "Huh, I actually feel better, thanks, {player}.",
	polite = "Thank you kindly, {player}, I'll write you a proper note.",
	foodie = "Thanks, {player}, that was better than soup.",
	nervous = "Oh, I can breathe again, thank you, {player}.",
}

-- No bed yet.
local NOBED = {
	_ = "I still don't have a bed, just so you know.",
	sunny = "{player}, I've got no bed, so I'm sleeping on coats!",
	gentle = "Sorry to fuss, {player}, but I've no bed yet.",
	bold = "I'm still on the floor, so sort me out a bed, okay?",
	dreamy = "A bed would be nice, I keep sleeping in odd places...",
	easygoing = "Eh, the floor's comfy, but a bed would be comfier.",
	proud = "I shouldn't be sleeping on a rug, so a bed, please.",
	shy = "Um, I don't have a bed yet, but the rug's okay.",
	cheeky = "{player}, I'm sleeping in the bath, so a bed, please?",
	cool = "Still no bed, and the floor's cold.",
	prickly = "I don't care about a bed, but my back does.",
	dramatic = "{player}, how many more nights on this cruel floor?",
	bookish = "I still haven't got a bed, and sleep matters.",
	gloomy = "Still no bed, so the floor and I are close now.",
	polite = "Forgive me, {player}, but I don't have a bed yet.",
	foodie = "No bed yet, so I doze by the bread bin.",
	nervous = "{player}, um, I still don't have a bed, is that okay?",
}

-- A quarrel that hasn't blown over.
local QUARREL = {
	_ = "{y} and I aren't talking at the moment.",
	sunny = "{y} and I had a fight, and I hate it!",
	gentle = "{y} and I had words, and I want to make it right.",
	bold = "Don't bring up {y}, we're not talking.",
	dreamy = "{y} and I aren't speaking, and I can't remember why...",
	easygoing = "Me and {y} aren't talking, but give it a day.",
	proud = "I'm not speaking to {y} until they apologise.",
	shy = "{y} and I fell out, and I don't know what to say...",
	cheeky = "{y} and I are fighting, and I think I'm winning.",
	cool = "{y} and I aren't talking, and that's all.",
	prickly = "Don't say {y}'s name, ugh, fine, I miss them.",
	dramatic = "{y} and I are sworn enemies, at least until Friday!",
	bookish = "{y} and I disagree about the tide tables, and neither will budge.",
	gloomy = "{y} isn't talking to me, which was bound to happen.",
	polite = "{y} and I disagreed, and I'd like to mend it.",
	foodie = "{y} and I fell out over the last dumpling.",
	nervous = "{y} is cross with me, and what if it's forever?",
}

-- Their best friend, the one at the top.
local FRIEND = {
	_ = "{y} always makes me laugh.",
	sunny = "{y} and I sat on the pier till the lamps came on!",
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
	gloomy = "{y} never minds when I'm gloomy, and they bring biscuits.",
	polite = "I've kept the card {y} sent when I was ill.",
	foodie = "{y} shares their chips without me even asking.",
	nervous = "{y} walks me past the big dog every morning.",
}

-- Small talk anybody might make on an ordinary day.
local SMALL = {
	"{player}, what are you building next? I saw your hammer.",
	"It's a quiet day, and the square's half empty.",
	"The harbour smelled like rain, but it never came.",
	"Somebody on a boat waved, so I waved back.",
	"The bakery queue went round the corner today.",
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
		"I need to know who planted the fountain flowers!",
		"Can we all have lunch on the square?",
		"{player}, I know the baker's middle name now, ehehe.",
		"I threw the harbour dog's stick eleven times!",
	},
	gentle = {
		"Leave your coat with me, it's lost a button.",
		"The baker's been coughing, so I'm taking her honey.",
		"{player}, you've worked all week, so rest tomorrow, okay?",
		"I planted mint by my door, so help yourself.",
		"The sparrow at my window brought a friend.",
	},
	bold = {
		"I cleared the fallen branch off the hill path.",
		"Anything heavy need lifting? Just point at it.",
		"{player}, we're fixing the sea wall Saturday, right?",
		"I'm watching the pier tonight to catch the litterbug.",
		"I raced the ferry along the shore today!",
	},
	dreamy = {
		"I followed a cat round the square all morning...",
		"You can feel the waves through the pier if you lie on it.",
		"{player}, did you see the moon out at lunchtime?",
		"I found a grey feather with a white tip.",
		"I meant to tell you something, but it's gone.",
	},
	easygoing = {
		"Busy morning, I watched the whole tide come in.",
		"Not much to report, which is how I like it.",
		"Mm, I had plans today, but they'll keep.",
		"{player}, try lying in the hill grass sometime.",
		"I told the baker the wind would sweep her step.",
	},
	proud = {
		"The baker asked for my advice today, naturally.",
		"Hmph, someone copied my garden, badly.",
		"{player}, your roof's nearly as straight as mine.",
		"They want me to judge the flower show, naturally.",
		"My door's the shiniest on the whole street.",
	},
	shy = {
		"I read on a quiet step behind the library.",
		"Um, your boots are nice, sorry, that's all.",
		"I waved at someone new, and they waved back.",
		"{player}, um, would you look at my drawing sometime?",
		"I went to the library reading and sat at the back.",
	},
	cheeky = {
		"Somebody put a hat on the gull statue, hehe.",
		"guess what, the harbour dog steals hats now.",
		"The baker's lost her rolling pin, hehe.",
		"{player}, race you to the fountain, go!",
		"ok, it was me who hid the bakery's spoons.",
	},
	cool = {
		"The boats came back early, so the sea's calm.",
		"The pier's empty today, which is good for thinking.",
		"I found a shorter path round the cliff.",
		"{player}, I saw your new roof, and it's good.",
		"I saw a heron on my run.",
	},
	prickly = {
		"Someone left a cart right in the path, honestly.",
		"I gave a gull my crust, so don't tell anyone.",
		"{player}, your mailbox is crooked, so I'll fix it.",
		"I don't need help, but hold this.",
		"Everyone's so loud today, except you, I suppose.",
	},
	dramatic = {
		"The sea ignored my song, how RUDE.",
		"My kettle whistled at me, and I took offence.",
		"{player}, you're in chapter two of my memoirs.",
		"My festival speech is only nine pages so far!",
		"*gasp* Someone moved my favourite bench three inches!",
	},
	bookish = {
		"The lighthouse lamp turns once every ten seconds, I timed it.",
		"Did you know the moon pulls the whole sea twice a day?",
		"Actually, a rainbow's a full circle, and the ground hides half.",
		"{player}, did you know snails can sleep for days?",
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
		"I've started saying good morning to the gulls.",
		"If I may, {player}, the hall's flowers look splendid.",
		"The market opens at eight, but quarter to is best.",
		"My good hat is pressed for the festival.",
		"I've reported the loose step on the pier, politely.",
	},
	foodie = {
		"I had two small pies for breakfast.",
		"The new rye's too sour, I checked three slices.",
		"{player}, sweet or salty? I'm bringing you something.",
		"I baked with seaweed, and I learned a lot.",
		"Have you eaten? The fish stall's got chips today.",
	},
	nervous = {
		"I brought a spare coat, and it's sunny.",
		"I crossed the bridge and only looked down once.",
		"{player}, s-sorry, should the harbour wall creak like that?",
		"I practised my bakery order, and she already knew it.",
		"I've checked my stove all morning, and it's off.",
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
			"{y} and I rub each other up the wrong way.",
			"{y} took the last bun right in front of me.",
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
	sunny = "{y} said hello to me four times today!",
	gentle = "{y} left a cake on my step without a note.",
	bold = "{y} carried my shopping up the hill without asking.",
	dreamy = "{y} asked if fish get bored, and now I wonder too.",
	easygoing = "{y} slept on the pier all afternoon.",
	proud = "{y} says their bread's the island's best, and it is.",
	shy = "{y} waved at me and then hid behind a stall.",
	cheeky = "{y} swapped my hat for a flowerpot!",
	cool = "{y} nodded at me today, which from them is a long chat.",
	prickly = "{y} called my porch a mess, then swept it, grumbling.",
	dramatic = "{y} announced soup like it was the end of a play.",
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
	shy = "{y}'s my best friend, um, I've never said that aloud.",
	cheeky = "{y}'s my best friend, and we've got a secret knock.",
	cool = "{y}'s my best friend, that's all.",
	prickly = "{y}'s my best friend, ugh, don't tell them.",
	dramatic = "{y}'s my best friend, so I'm writing them a song!",
	bookish = "{y} is my best friend, and we argue about every book.",
	gloomy = "{y}'s my best friend, and it rains less when they're around.",
	polite = "{y} is a very dear friend, and I count myself lucky.",
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
		"It's too hot for shoes today.",
		"The beach is packed right to the water.",
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
		"My winter plan is a blanket, some tea and a window.",
	},
}

local WEATHER = {
	rain = {
		"Rain on the roof always helps me sleep.",
		"My boots haven't dried since yesterday.",
		"It's a good day for a book by the window.",
	},
	storm = {
		"That thunder rattled every cup in my cupboard.",
		"Every boat's tied up, and even the gulls are hiding.",
		"{player}, stay in tonight, because that wind means it.",
	},
	snow = {
		"Go and stand in the snow, it's quieter than you'd think.",
		"There's snow on every roof, and the town looks iced.",
		"My snowman's leaning like me after a big lunch.",
	},
	blossom = {
		"I've got petals in my hair, and I'm keeping them.",
		"The trees by the square are dropping petals like pink snow.",
		"I swept up the petals, and they blew straight back.",
	},
	leaves = {
		"I swept my step twice, and the leaves won.",
		"I've stepped on every crunchy leaf I could find.",
		"A leaf sat on my head for an hour.",
	},
	clear = {
		"There's not a cloud anywhere today.",
		"You can see every island from the hill today.",
		"The sun's out, so the whole square's full.",
	},
	cloudy = {
		"It's grey out, but that's good for walking.",
		"The clouds are sitting right on top of the hill.",
		"The sea's gone the colour of an old spoon.",
	},
}

-- A craving, in their own words ({food} as it reads inside a sentence: "a rice ball", "ice cream").
local CRAVE = {
	_ = "I could really go for {food} right now.",
	sunny = "{player}, guess what I'm craving? I'd love {food} today!",
	gentle = "I've been good all week, {player}, so {food} would be such a treat.",
	bold = "I need {food}, {player}, today if you can manage it.",
	dreamy = "Hmm... I keep thinking about {food}, I can almost smell it.",
	easygoing = "Mm, {player}, {food} would really hit the spot, but there's no rush.",
	proud = "I think I've earned {food}, and only the good kind, please.",
	shy = "Um, sorry, {player}... {food} would be nice, but you don't have to.",
	cheeky = "{player}, deal? get me {food} and i won't prank you for a whole day",
	cool = "{player}. If you're passing the market, I'd like {food}.",
	prickly = "Don't look at me like that, I just want {food}, okay?",
	dramatic = "{player}, I'll simply PERISH if I don't have {food} today!",
	bookish = "I've been reading an old cookbook, and now I can't stop thinking about {food}.",
	gloomy = "I'd like {food}, but they'll have sold out, as usual.",
	polite = "Forgive me, {player}, but {food} would be ever so welcome.",
	foodie = "{player}, I've been dreaming about {food} since breakfast.",
	nervous = "S-sorry, {player}, is it greedy if I ask for {food}?",
}

-- Someone they'd like to meet.
local MEET = {
	_ = "I'd like to meet {y} properly, could you help?",
	sunny = "{player}, introduce me to {y}, I want us to be friends!",
	gentle = "{y} looks a little lonely, so would you introduce us?",
	bold = "{player}, introduce me to {y}, I tried and they ran off.",
	dreamy = "{y} looks at the sea like I do, so could you introduce us?",
	easygoing = "{y} seems all right, so introduce us sometime, no rush.",
	proud = "{y} should meet me, so could you arrange it, {player}?",
	shy = "Um, {player}, would you stand with me while I meet {y}?",
	cheeky = "{y} looks fun to prank, I mean, to know, so introduce us?",
	cool = "{player}, introduce me to {y} sometime.",
	prickly = "Introduce me to {y}, and don't make it weird.",
	dramatic = "{player}, fate says I must meet {y}, so make it happen!",
	bookish = "I've seen {y} reading on the pier, so would you introduce us?",
	gloomy = "{y} won't like me, but introduce us anyway?",
	polite = "{player}, would you be so kind as to introduce me to {y}?",
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
	return if line then named(profile, line, nil) else nil
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
