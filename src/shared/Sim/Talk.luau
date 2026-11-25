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
-- their feel only): a villager who stops to talk opens with your name and then a small thing from
-- their day, the point coming late, in a message or two of about six words. Your name ({player},
-- filled in as the line leaves) turns up about one line in seven, mostly first.

-- Walking up to them: their own hello (Personalities' `hello`, which they also say to each other)
-- or one of these, which are for you and use your name.
local GREET = {
	sunny = {
		"{player}! {player}! You'll never guess. The ferry's got a new bell!",
		"{player}! Perfect timing. I've got news. Small news. Okay, medium.",
		"{player}, hi! I just saw a gull steal a whole pie. A whole pie!",
	},
	gentle = {
		"Hello, {player}. Have you had a proper meal today?",
		"Oh, {player}. Come and sit. You've been on your feet all day, haven't you?",
		"{player}, there you are. I picked the first beans this morning. I saved you some.",
	},
	bold = {
		"{player}. You're free, right? Good. I need a hand at the harbour.",
		"{player}! There you are. Walk with me, I'm checking the sea wall.",
		"Hey, {player}. Somebody left the square gate open again. I'm on it.",
	},
	dreamy = {
		"{player}. There's a rainbow in the fountain spray. A tiny one.",
		"{player}... hi. The light's gone gold over the hill.",
		"Oh. {player}. I was counting boats. I lost count. That's fine.",
	},
	easygoing = {
		"*yawn* Oh, {player}. Hey. Is it lunch already?",
		"Hey, {player}. You walking past the market? Bring me an apple. Any apple.",
		"Mm. {player}. I've been resting since breakfast. Research, really.",
	},
	proud = {
		"{player}. You'll want to hear this. I won again.",
		"Ah, {player}. Good. I've got something to show you. It's excellent.",
		"{player}, you've come at the right time. I just finished something brilliant.",
	},
	shy = {
		"Um, {player}. Hi... I didn't think you'd stop.",
		"{player}... um. Hello. I'm not busy. If you wanted to talk. You don't have to.",
		"Oh. {player}. Um... the cat by the library let me stroke it.",
	},
	cheeky = {
		"Psst. {player}. Over here. Act normal.",
		"{player}! Don't look at the fountain. ...Okay, look now.",
		"Oh, {player}. Perfect. I need a lookout. Just stand there.",
	},
	cool = { "{player}. Hey.", "{player}. Ran past your house. Nice roof.", "Oh. {player}. Tide's out. Good walking." },
	prickly = {
		"{player}. There's a weed on your path. Two weeds. Hi.",
		"Oh. {player}. What do you want? ...Fine. Hi.",
		"{player}. You again. Sit, then. Not there. There.",
	},
	dramatic = {
		"{player}! At LAST. I've been waiting all day.",
		"Ah, {player}. You're just in time. Something tremendous has happened.",
		"{player}! {player}. Stop. Listen. I have news of great importance.",
	},
	bookish = {
		"Hello, {player}. Did you know honey never goes off? They've found jars older than the harbour.",
		"Oh, {player}. Sorry, I was halfway through a chapter. Hello.",
		"{player}, hello. I worked out how old the lighthouse is. Do you have a minute? It's a good story.",
	},
	gloomy = {
		"Oh. {player}. Hi. My umbrella broke. Inside out, then off.",
		"{player}. You came. Huh. That's nice.",
		"{player}... hi. I was just thinking nobody would stop today.",
	},
	polite = {
		"Good morning, {player}. I hope I'm not keeping you.",
		"Hello, {player}. How lovely. I was just admiring the harbour.",
		"Good afternoon, {player}. I trust you're keeping well? Do mind the sun today.",
	},
	foodie = {
		"{player}! Had lunch? I've had two.",
		"Hi, {player}. Smell that? The bakery's doing cinnamon today.",
		"{player}! The fish stall has a special. Fried, with lemon. Come on.",
	},
	nervous = {
		"Oh! {player}. Sorry, you made me jump. Hi.",
		"{player}, h-hi. Is everything okay? It's okay? Good.",
		"{player}! Sorry. Hi. I locked my door three times this morning. It's locked.",
	},
}

-- After a talk that answered their wish for one.
local THANKS = {
	_ = "Thanks for stopping, {player}. That helped.",
	sunny = "{player}, thank you! I feel loads better. Let's do this again tomorrow!",
	gentle = "Thank you for sitting with me, {player}. I'll pay you back in soup.",
	bold = "...Thanks, {player}. Needed that. Anyway. Lunch is on me.",
	dreamy = "The fog's gone. It went that way. Thank you, {player}.",
	easygoing = "Heh. Thanks, {player}. That was as good as a nap.",
	proud = "Th-that wasn't me being sad. It was thinking. Anyway! Thank you, {player}.",
	shy = "...Thank you, {player}. Um. I feel a lot better. That's all.",
	cheeky = "Okay. Real thanks, {player}. No joke. ...Right, that's enough of that.",
	cool = "{player}. That helped. ...Thanks.",
	prickly = "Hmph. That helped. Don't make it a thing. ...Thanks, {player}.",
	dramatic = "{player}! I was lost and now I'm found! Well. I'm on this bench. Thank you.",
	bookish = "Thank you, {player}. Twelve minutes, and it helped more than a whole chapter.",
	gloomy = "Huh. I feel better. That never happens. Thanks, {player}.",
	polite = "Thank you ever so much, {player}. I'll write you a note about it. A proper one.",
	foodie = "Thanks, {player}. That was better than soup. Don't tell the soup.",
	nervous = "Oh. Okay. I can breathe again. Thank you, {player}. Sorry. Thank you.",
}

-- No bed yet.
local NOBED = {
	_ = "No bed yet. Just so you know.",
	sunny = "{player}! Still no bed! I've been sleeping on a pile of coats. Nice coats, but still.",
	gentle = "I don't like to make a fuss, {player}... but I haven't a bed yet.",
	bold = "No bed yet. Three nights on the floor. Sort it, okay?",
	dreamy = "I've been sleeping wherever I end up... a bed would stop that.",
	easygoing = "Floor's comfy enough. A bed'd be comfier. If you're asking.",
	proud = "Someone of my standing, sleeping on a rug. A bed, please. Soon.",
	shy = "Um... I don't have a bed yet. Sorry. It's okay. The rug's okay.",
	cheeky = "No bed yet, {player}. I'm sleeping in the bath. It's fine. It's not fine.",
	cool = "Still no bed. Floor's cold.",
	prickly = "Still no bed. I don't care. My back cares. Ugh.",
	dramatic = "Another night on the cold, cruel floor! How long must I suffer, {player}?",
	bookish = "I still haven't got a bed. I've read that sleep matters rather a lot.",
	gloomy = "No bed. Of course. The floor and I are close now.",
	polite = "Forgive me for raising it, {player}, but I don't have a bed yet.",
	foodie = "No bed yet. I've been dozing by the bread bin. It smells nice, at least.",
	nervous = "{player}, um... I still don't have a bed. Is that okay? Is it on the list? Sorry.",
}

-- A quarrel that hasn't blown over.
local QUARREL = {
	_ = "{y} and I aren't talking at the moment.",
	sunny = "{y} and I had a fight and I hate it! Can it just be over?",
	gentle = "{y} and I had words. I keep thinking I should knock on their door.",
	bold = "Don't bring up {y}. We had it out. We're not talking.",
	dreamy = "{y} and I aren't speaking. I forget why. It's still true, though.",
	easygoing = "Me and {y} aren't talking. Eh. Give it a day.",
	proud = "I'm not speaking to {y} until they apologise. They know what for.",
	shy = "{y} and I had a falling out... I feel awful. I don't know what to say to them.",
	cheeky = "{y} and I are in a fight. I'm winning. I think. Am I?",
	cool = "{y} and me. Not talking.",
	prickly = "Don't say {y}'s name. Ugh. ...Fine. I miss them a bit. Whatever.",
	dramatic = "{y} and I are enemies now! Sworn enemies! Until about Friday.",
	bookish = "{y} and I disagreed about the tide tables. Neither of us will back down.",
	gloomy = "{y} isn't talking to me. It was bound to happen.",
	polite = "{y} and I had a disagreement. I do hope we can put it right soon.",
	foodie = "{y} and I fell out over the last dumpling. It was a really good dumpling.",
	nervous = "{y} is cross with me. What if it's forever? Is it forever?",
}

-- Their best friend, the one at the top.
local FRIEND = {
	_ = "{y} always makes me laugh.",
	sunny = "{y} and I sat on the pier till the lamps came on. We talked about everything!",
	gentle = "{y} walked me home in the rain last week. Held the umbrella over me the whole way.",
	bold = "{y}'s solid. If they need a hand, they've got mine.",
	dreamy = "{y} watched the clouds with me for an hour. Didn't say a word. Perfect.",
	easygoing = "Me and {y} did nothing all afternoon. Best afternoon.",
	proud = "{y} came to watch me win. They clapped the loudest. Good taste.",
	shy = "{y} talks to me a lot. I like that. I don't have to think of things to say.",
	cheeky = "{y} helped me hide the baker's rolling pin. True friend.",
	cool = "{y}'s good company. Doesn't talk much.",
	prickly = "{y}'s annoying. I'd still carry their boxes up the hill. Don't tell them.",
	dramatic = "{y}! My dearest friend! We'd swim the harbour for each other. In summer.",
	bookish = "{y} borrowed four of my books and returned all four. On time. A rare person.",
	gloomy = "{y} doesn't mind when I'm gloomy. They just bring biscuits.",
	polite = "{y} sent me a card when I was ill. I've kept it on the mantel.",
	foodie = "{y} shares their chips without me even asking. That's real friendship.",
	nervous = "{y} walks me past the big dog every morning. Every single morning.",
}

-- Small talk anybody might make on an ordinary day.
local SMALL = {
	"{player}, what's going up next? I saw you with a hammer.",
	"Quiet day. The square's half empty.",
	"The harbour smelled like rain this morning. It never rained.",
	"Somebody waved at me from a boat. No idea who. I waved back.",
	"The bakery queue went right round the corner today.",
	"Someone keeps leaving flowers on the bench by the pier.",
	"I sat on the hill and watched the ferry come in.",
	"The fountain's been extra splashy since the wind changed.",
	"I tidied one drawer today. One. It's a start.",
	"The new bench by the hall is comfier than it looks.",
}

-- Small talk of their own, by personality.
local OWN = {
	sunny = {
		"I counted the boats in the harbour. Fourteen! Then one left. Thirteen.",
		"Someone planted flowers round the fountain. I need to know who!",
		"We should have lunch on the square. All of us. The whole town. Can we?",
		"{player}, I learned the baker's middle name. I'm not allowed to tell you.",
		"The harbour dog let me throw its stick. Eleven times!",
	},
	gentle = {
		"There's a button loose on your coat. Leave it with me later.",
		"The baker's been coughing. I'm taking her honey after this.",
		"{player}, you've worked every day this week. Take tomorrow slow, won't you?",
		"I planted mint by my door. Help yourself whenever you like.",
		"The little sparrow by my window came back. With a friend.",
	},
	bold = {
		"Moved the fallen branch off the hill path. Nobody else was going to.",
		"Anything heavy need lifting today? Point at it.",
		"{player}. The sea wall's cracked by the steps. We're fixing it Saturday. You're free, right?",
		"Someone keeps leaving rubbish by the pier. I'm keeping watch tonight.",
		"Raced the ferry along the shore. Nearly won!",
	},
	dreamy = {
		"Does the lighthouse get lonely in the day, with nobody looking at it?",
		"I followed a cat round the square. It knew where it was going. I didn't.",
		"If you put your ear on the bench, you can hear the sea. Or the bench.",
		"{player}, the moon was out at lunch. Just sitting there. Did you see?",
		"I found a feather on my step. Grey, with a white tip. I think it's a letter.",
	},
	easygoing = {
		"Spent the morning watching the tide come in. Busy morning.",
		"Not much to report. Just how I like it.",
		"Mm. I was going to do something today. It'll keep...",
		"{player}, try lying in the grass on the hill sometime. Ten out of ten. Research says so.",
		"The baker asked if I'd swept the step. I said the wind did it.",
	},
	proud = {
		"The baker asked for my advice today. I gave it. Generously.",
		"I repainted my door. Three coats. You can see your face in it.",
		"{player}, your roof's coming along. Not as straight as mine, but coming along.",
		"Someone asked if my garden was done by a professional. I said yes. Me.",
		"My bread came out perfect today. I checked every slice.",
	},
	shy = {
		"There's a quiet step behind the library. I read there sometimes.",
		"Um... your boots are nice. Sorry. That's all.",
		"I waved at someone new today. They waved back. I had to sit down.",
		"{player}, um... would you look at my drawing sometime? Only if you want.",
		"I wrote a thank you note for the postie. It's been in my pocket for a week.",
	},
	cheeky = {
		"Somebody put a hat on the gull statue. No idea who. Nice hat, though.",
		"I told the fisher there's a whale in the harbour. He's still looking. hahaha",
		"The baker's looking for her rolling pin. Don't look at me. Okay, look at me.",
		"{player}, check your mailbox later. Don't worry. Mostly don't worry.",
		"Race you to the fountain. Loser buys buns. Go! I already went.",
	},
	cool = {
		"Boats were back early. Calm sea.",
		"Pier's empty. Good for thinking.",
		"Found a path round the cliff. Short.",
		"{player}. Saw your new roof. Good.",
		"Ran the shore. Saw a heron. That's it.",
	},
	prickly = {
		"Someone left a cart in the middle of the path. I moved it. Honestly.",
		"The gulls took my sandwich. I hate gulls. ...I gave the small one my crust.",
		"{player}, your mailbox is crooked. I'm bringing a hammer over. I was going that way.",
		"I don't need help. ...Hold this. Don't let go.",
		"Everyone's so loud today. You're fine. Don't let it go to your head.",
	},
	dramatic = {
		"I sang to the sea this morning. The sea did not sing back. Rude.",
		"Last night's sunset was so beautiful I had to lie down on the pier.",
		"{player}, when they write the story of this island, you'll be in chapter two. I'm chapter one.",
		"My kettle whistled at me this morning. I took it personally.",
		"I've written a speech for the next festival. It's only nine pages!",
	},
	bookish = {
		"The lighthouse lamp turns once every ten seconds. I timed it for an hour.",
		"I've been reading about tides. The moon pulls the whole sea. Twice a day.",
		"A rainbow is really a full circle. We only see half because the ground's in the way.",
		"{player}, I counted the steps up the hill. There are 212. Or 213, depending where you start.",
		"Snails can sleep for days at a time. I've been checking on the one by my door.",
	},
	gloomy = {
		"I hung my washing out. The sun went in. It always knows.",
		"A gull took my bun. At least someone had a good day.",
		"My plant has one leaf. Just one. I talk to it.",
		"{player}, you look tired. Sit down. The world can end without you for a minute.",
		"The pier bench wobbles. I sit on it anyway. We understand each other.",
	},
	polite = {
		"I took the new neighbours a cake this morning. They seem very pleasant.",
		"If I may, {player}, the flower beds by the hall are a credit to the town.",
		"I've started saying good morning to the gulls. They don't answer, but it seems right.",
		"The market opens at eight. I find quarter to is best, before the crowds.",
		"I've pressed my good hat for the festival. One does like to be ready.",
	},
	foodie = {
		"Pie for breakfast. A small pie. Then a second small pie.",
		"The baker's trying a new rye. Too sour. I had three slices to be sure.",
		"{player}, sweet or salty? I'm working out what to bring you.",
		"Two coins for a roll now. Two! I'm still buying them, but I'm cross.",
		"I tried baking with seaweed. It was... a learning bake.",
	},
	nervous = {
		"I packed an umbrella, a coat and a spare coat. It's sunny. Just in case.",
		"I crossed the little bridge today. Didn't look down. Okay, I looked once.",
		"{player}, sorry, quick question. Is the harbour wall meant to make that noise?",
		"I practised ordering at the bakery in the mirror. Then she knew my order. Phew!",
		"Something tapped my window all night. It was a branch. I checked. Four times.",
	},
}

local JOKES = {
	"Why don't gulls fly over the bay? They'd be bagels. Sorry.",
	"I tried to catch the fog this morning. I mist.",
	"The baker stopped making doughnuts. She got tired of the hole thing.",
	"Why was the broom late? It overswept.",
	"Why did the biscuit go to the doctor? It was feeling crummy.",
	"What do clouds wear under their coats? Thunderwear.",
	"Where do fish keep their money? In the river bank.",
	"Why are fish so clever? They live in schools.",
	"I told the lighthouse a secret. Now everyone's seen it.",
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
			"If {y} needed a hand moving house, I'd be there before they asked.",
			"{y} saved me a seat by the fountain again. They always do.",
			"{y} knows how I take my tea. Nobody else bothers.",
		},
	},
	{
		min = 30,
		lines = {
			"{y} fixed my gate without being asked. Good sort.",
			"I had tea at {y}'s yesterday. They've got a lovely view.",
		},
	},
	{
		min = 10,
		lines = {
			"{y} and I said good morning at the bakery. It's a start.",
			"I've only chatted to {y} twice. Both times were nice.",
		},
	},
	{
		min = -10,
		lines = {
			"{y}? We've never really talked. Should we?",
			"I keep meaning to say hello to {y}. Keep meaning to.",
		},
	},
	{
		min = -40,
		lines = {
			"{y} and I rub each other the wrong way. It happens.",
			"{y} took the last bun right in front of me. I'm not over it.",
		},
	},
	{
		min = -101,
		lines = {
			"Can we not talk about {y}? Thanks.",
			"{y} and I are best kept at opposite ends of the square.",
		},
	},
}

-- What a neighbour is like, by their personality.
local LIKE = {
	sunny = "{y} said hello to me four times today. I counted. I liked it.",
	gentle = "{y} left a cake on my step. No note. I know it was them.",
	bold = "{y} carried my shopping up the hill without asking. Then ran back down.",
	dreamy = "{y} asked me if fish get bored. I've been thinking about it all day.",
	easygoing = "{y} was asleep on the pier when I went past. And when I came back.",
	proud = "{y} told me their bread was the best on the island. Then gave me some. It was good.",
	shy = "{y} waved at me from across the square. Then hid behind a stall.",
	cheeky = "{y} swapped my hat for a flowerpot. I didn't notice till lunch.",
	cool = "{y} nodded at me this morning. From them, that's a long chat.",
	prickly = "{y} said my porch was a mess. Then swept it. Grumbling the whole time.",
	dramatic = "{y} announced lunch like it was the end of a play. It was soup.",
	bookish = "{y} told me why the sea is salty. It took twenty minutes. I learned a lot.",
	gloomy = "{y} told me the bridge creaks. Now I hear it every time.",
	polite = "{y} wrote me a thank you note. For saying good morning.",
	foodie = "{y} can tell what every stall is cooking just by sniffing the air.",
	nervous = "{y} asked me if the pier was safe. Then walked on it very slowly.",
}

-- A best friend, as close as two villagers get (there is no romance: the user, "remove any
-- romance, just best friends is the highest"). In the speaker's own way.
local BEST = {
	_ = "{y} is my best friend. Has been for ages.",
	sunny = "{y}'s my best friend! We've got matching scarves. I knitted them. Badly!",
	gentle = "{y} is my best friend. They know when I need tea before I do.",
	bold = "{y}'s my best friend. If they need me, I'm already on my way.",
	dreamy = "{y} is my best friend. We finish each other's... um. They'd know.",
	easygoing = "{y}'s my best friend. We nap on the same bench. Different ends.",
	proud = "{y} is my best friend. I chose well. I always do.",
	shy = "{y} is my best friend. I've never said that out loud before.",
	cheeky = "{y}'s my best friend. We've got a secret knock. It goes on for ages.",
	cool = "{y}'s my best friend. That's all.",
	prickly = "{y}'s my best friend. Ugh. Don't tell them I said it.",
	dramatic = "{y} is my best friend in all the world! I'm writing them an opera.",
	bookish = "{y} is my best friend. We've read the same forty books and disagree about all of them.",
	gloomy = "{y} is my best friend. When they're around, it rains less. Feels like it, anyway.",
	polite = "{y} is my very dear friend. I count myself fortunate.",
	foodie = "{y}'s my best friend. I give them the last dumpling. That's how you know.",
	nervous = "{y} is my best friend. I checked. They said yes straight away.",
}
local LEVELS = Tuning.Relationships.Levels
local BEST_FRIENDS = LEVELS[#LEVELS].Min

-- By season (1 spring, 2 summer, 3 autumn, 4 winter).
local SEASON = {
	{
		"The daffodils by the hall are out. All at once, like they planned it.",
		"Spring cleaning. Found a glove I lost in winter. Just the one.",
		"Everything smells green today.",
	},
	{
		"Too hot for shoes. I'm being careful where I step.",
		"The beach is packed. I found a spot the size of a towel.",
		"I've got a sunburnt nose. Only the tip.",
	},
	{
		"Everything crunches underfoot. I love it.",
		"The trees on the hill went orange overnight. Go and look.",
		"It's dark by dinner now. Soup weather.",
	},
	{
		"My fingers have been cold since Monday.",
		"Frost on every roof this morning. The whole town looked sugared.",
		"Winter plan. Blanket. Tea. Window. Repeat.",
	},
}

local WEATHER = {
	rain = {
		"Rain on the roof all night. Best sleep I've had.",
		"My boots are still wet from yesterday. And now today.",
		"Good day for a book and a window.",
	},
	storm = {
		"That thunder rattled my cups. All of them.",
		"Every boat's tied up. Even the gulls are hiding.",
		"{player}, stay in tonight. That wind means it.",
	},
	snow = {
		"Go and stand in the snow for a bit. It's quieter than you'd think.",
		"Snow on every roof. The whole town looks iced.",
		"I made a snowman. He's leaning. Like me after lunch.",
	},
	blossom = {
		"Petals in my hair. I'm keeping them there.",
		"Stand under the trees by the square. It's like pink snow.",
		"I swept up the petals. They came straight back. Fair enough.",
	},
	leaves = {
		"Swept my step. The leaves came back. Swept it again. They won.",
		"I've been stepping on all the crunchy ones. Every single one.",
		"A leaf landed on my head and stayed there all morning.",
	},
	clear = {
		"Not a cloud anywhere. I'm not wasting it.",
		"You can see every island from the hill today.",
		"Sun's out and so is everyone. The square's full.",
	},
	cloudy = {
		"Grey sky. Good for walking. Not too bright.",
		"The clouds are sitting right on the hill today.",
		"Cloudy. The sea's gone the colour of a spoon.",
	},
}

-- A craving, in their own words ({food} is the food's name, so it starts a sentence).
local CRAVE = {
	_ = "{food}. I keep thinking about it. Is that odd?",
	sunny = "{player}! {player}! You know what I want? {food}! Can we? Please?",
	gentle = "{player}, I've been good all week. {food} would be such a treat. Only if it's no bother.",
	bold = "{food}. That's what I need. Today, if you can.",
	dreamy = "There's a smell on the wind. {food}, I think. I want to follow it.",
	easygoing = "Mm... {food}. That'd hit the spot. No rush. Bit of a rush.",
	proud = "I deserve a treat, frankly. {food}. The good kind, please.",
	shy = "Um, {player}... sorry. {food}. I keep thinking about it. You don't have to.",
	cheeky = "{player}, deal for you. {food}, and I stop pranking you. For a day.",
	cool = "{player}. {food}. If you're passing.",
	prickly = "Ugh. Don't look at me like that. {food}. I want some. Fine. Said it.",
	dramatic = "{player}, I'll perish without it! {food}! Bring it and I'll live again!",
	bookish = "I read an old cookbook last night. Chapter six. {food}. I've thought of nothing else.",
	gloomy = "{food}... I'd like some. It'll be sold out. It always is.",
	polite = "Forgive me for asking, {player}. {food}. I would be ever so grateful.",
	foodie = "{player}! {food}! I've been dreaming about it since breakfast. Please?",
	nervous = "{player}, sorry. {food}. Is it greedy to want some? I really want some.",
}

-- Someone they'd like to meet.
local MEET = {
	_ = "I'd like to meet {y} properly. Could you help?",
	sunny = "{player}! I want to be friends with {y}! Can you introduce us? Today?",
	gentle = "{y} always looks a little lonely. Would you introduce us, {player}?",
	bold = "{player}. Introduce me to {y}. I tried. They ran. Not my fault.",
	dreamy = "{y} looks at the sea the way I do. Could you introduce us?",
	easygoing = "{y} seems all right. Introduce us sometime? No rush.",
	proud = "{y} should meet me. It would do them good. Arrange it, {player}?",
	shy = "Um, {player}... I'd like to talk to {y}. Could you stand with me? I won't know what to say.",
	cheeky = "{y} looks like they'd be fun to prank. I mean, to know. Introduce us?",
	cool = "{player}. {y}. Introduce us sometime.",
	prickly = "That {y}. Introduce us. Don't make it weird. I'm only curious.",
	dramatic = "{player}! Fate says I must meet {y}! Make it happen!",
	bookish = "I've noticed {y} reads on the pier. I'd love to ask what. Would you introduce us?",
	gloomy = "{y} won't like me. Nobody does at first. Introduce us anyway?",
	polite = "{player}, would you be so kind as to introduce me to {y}? I'd be most grateful.",
	foodie = "{y} always has the best snacks. I need to know them. Introduce us?",
	nervous = "{player}, could you introduce me to {y}? And stay? What if I say something odd?",
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
		return "I keep thinking about something to eat."
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
		add("That helped, {player}. Thank you.")
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
				add("Slept like a log last night. A happy log.")
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
