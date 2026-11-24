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

-- They talk to you the way a friend texts (the user pointed at a messaging app's chats: the feel
-- only): short bursts, a small thing from their day or a favour to ask, and now and then your name
-- ({player}, filled in as the line leaves) to get your attention, to thank you or to tease you.

-- Walking up to them: their own hello (Personalities' `hello`, which they also say to each other)
-- or one of these, which are for you and use your name.
local GREET = {
	sunny = {
		"{player}! Hiii! I was hoping you'd come by.",
		"Oh, {player}! Perfect timing. I've got news. Small news.",
	},
	gentle = { "Hello, {player}. Have you eaten today?", "Oh, {player}. Come and sit a minute." },
	bold = { "{player}! There you are. Walk with me.", "Oi, {player}. Took your time." },
	dreamy = {
		"Oh... {player}. I was just thinking about you. Or a cloud. One of those.",
		"{player}... hi. The light's all gold today.",
	},
	easygoing = { "Mm. Hey, {player}.", "Oh hey, {player}. Snack time yet?" },
	proud = { "Ah, {player}. You've come to the right person.", "{player}. Good. I've got something to show you." },
	shy = { "Oh. Um. Hi, {player}.", "{player}... hi. I didn't think you'd stop." },
	cheeky = { "Psst. {player}. Over here. Act normal.", "Oh, {player}. Perfect. I need a lookout." },
	cool = { "{player}. Hey.", "Oh. {player}. Hi." },
	prickly = { "Oh. {player}. What do you want? Fine. Hi.", "{player}. You again. Sit, then." },
	dramatic = { "{player}! At last! I've been waiting all day.", "Ah, {player}. You're just in time for my news." },
	bookish = {
		"Hello, {player}. I've got a fact for you, if you've a moment.",
		"Oh, {player}. Sorry, I was halfway through a chapter. Hello.",
	},
	gloomy = { "Oh. Hi, {player}. It'll rain later.", "{player}. You came. Huh. Nice." },
	polite = { "Hello, {player}. How lovely to see you.", "Good day, {player}. I hope you're keeping well." },
	foodie = { "{player}! Have you eaten? I have. Twice.", "Hi, {player}. Can you smell the bakery? Mmm." },
	nervous = { "Oh! {player}. Sorry, you made me jump. Hi.", "{player}, hi. Is everything okay? It's okay? Good." },
}

-- After a talk that answered their wish for one.
local THANKS = {
	_ = "Thanks, {player}. I feel better already.",
	sunny = "Oh, thank you, {player}! I really needed that. I feel loads better.",
	gentle = "Thank you for stopping, {player}. I feel much better now.",
	bold = "Yeah. Okay. That helped. Thanks, {player}.",
	dreamy = "Oh... the fog's lifted a bit. Thank you, {player}.",
	easygoing = "Thanks, {player}. Needed that.",
	proud = "I was perfectly fine. But... thank you, {player}.",
	shy = "Thanks for talking to me, {player}. Um. I feel a lot better.",
	cheeky = "Right, I'm cheered up. Don't tell anyone it was you, {player}.",
	cool = "Better now. Thanks, {player}.",
	prickly = "Hmph. That helped. Don't read into it. Thanks, {player}.",
	dramatic = "{player}, you've saved me. I feel alive again!",
	bookish = "Thank you, {player}. I read that talking helps, and it turns out it does.",
	gloomy = "That helped. Weird. Thanks, {player}.",
	polite = "Thank you very much, {player}. I feel ever so much better.",
	foodie = "Thanks, {player}. That was as good as soup. Nearly.",
	nervous = "Phew. Thank you, {player}. I can breathe again.",
}

-- No bed yet.
local NOBED = {
	_ = "I still don't have a bed, you know.",
	sunny = "Still no bed! I've been sleeping on a pile of coats. Could you sort one out, {player}?",
	gentle = "I don't like to be a bother, but I still haven't got a bed.",
	bold = "Still no bed. I'm sleeping on the floor. Sort it out.",
	dreamy = "I still don't have a bed... I just sleep wherever I end up.",
	easygoing = "No bed yet. Floor's fine. A bed'd be better.",
	proud = "I'm still without a bed. I don't complain, but honestly.",
	shy = "Um. I don't have a bed yet. It's okay. The floor's okay.",
	cheeky = "Still no bed, {player}. I might just move into yours.",
	cool = "No bed yet. Noticed?",
	prickly = "Still no bed. I don't care. My back cares.",
	dramatic = "Another night on the cold, hard floor. When will it end, {player}?",
	bookish = "I still haven't got a bed. Actually, I've read that sleep matters quite a lot.",
	gloomy = "No bed. Figures. The floor and I are friends now.",
	polite = "I'm sorry to mention it, {player}, but I don't have a bed yet.",
	foodie = "Still no bed. I've been sleeping by the bread bin. It smells nice, at least.",
	nervous = "{player}, um, I still don't have a bed. Is that okay? Is it on the list?",
}

-- A quarrel that hasn't blown over.
local QUARREL = {
	_ = "{y} and I aren't speaking right now.",
	sunny = "{y} and I had a fight and I hate it. Can things just go back to normal?",
	gentle = "{y} and I have had words. I hope it blows over soon.",
	bold = "Don't talk to me about {y}. We're not speaking.",
	dreamy = "{y} and I aren't speaking. I can't remember why. We just aren't.",
	easygoing = "Me and {y} aren't talking. It'll blow over.",
	proud = "I'm not speaking to {y}. They know what they did.",
	shy = "{y} and I had a falling out. I feel awful about it.",
	cheeky = "{y} and I are having a fight. I'm winning.",
	cool = "{y} and me? Not talking.",
	prickly = "Don't say {y}'s name. Ugh. Fine. I miss them a bit. Whatever.",
	dramatic = "{y} has betrayed me! We are enemies now. For a day or two.",
	bookish = "{y} and I disagreed about something, and neither of us will back down.",
	gloomy = "{y} isn't talking to me. Figures.",
	polite = "{y} and I had a disagreement. I do hope we can patch it up.",
	foodie = "{y} and I fell out over the last dumpling. It was a really good dumpling.",
	nervous = "{y} is cross with me. What if they're cross forever? Are they?",
}

-- Their best friend, the one at the top.
local FRIEND = {
	_ = "{y} always makes me laugh.",
	sunny = "{y} always makes me laugh. We sat on the pier talking for hours yesterday!",
	gentle = "{y} came round with soup when I had a cold. They're good like that.",
	bold = "{y}'s all right. Better than all right.",
	dreamy = "{y} gets my thoughts. Even the odd ones.",
	easygoing = "Me and {y} sat on the pier all afternoon. Good times.",
	proud = "{y} is nearly as good company as me.",
	shy = "{y} talks to me a lot. I like that.",
	cheeky = "{y} laughs at all my jokes. Even the bad ones.",
	cool = "{y}'s solid.",
	prickly = "{y}'s annoying. I'd help them move house, though. Don't tell them.",
	dramatic = "{y}, my dearest companion! We'd cross the sea for each other. In a boat.",
	bookish = "{y} lets me tell them facts for hours. They even ask questions.",
	gloomy = "{y} sits with me when it rains. That's a lot of sitting.",
	polite = "{y} has been a wonderful friend to me. I'm very lucky.",
	foodie = "{y} always saves me the crust. That's real friendship.",
	nervous = "{y} always checks I'm okay. I check they're okay. It works.",
}

-- Small talk anybody might make on an ordinary day.
local SMALL = {
	"What are you building next, {player}?",
	"Quiet day today. I like it like that.",
	"I went for a walk round town earlier. The harbour smelled like rain.",
	"Have you tried the bench by the fountain? It's comfier than it looks.",
	"Somebody on a boat waved at me this morning. No idea who. I waved back anyway.",
	"I keep meaning to tidy my room. Keep meaning to.",
	"The bakery queue was out the door this morning. Did you see?",
	"Someone's been leaving flowers on the bench by the pier. Every day.",
	"I stood on the hill and looked at the sea for ages today.",
}

-- Small talk of their own, by personality.
local OWN = {
	sunny = {
		"I've said hi to about twenty people today and it's not even lunch!",
		"Did you see the new flowers by the fountain? Someone's been busy and I need to know who.",
		"We should all have lunch on the square one day. The whole town. Can we? Please?",
		"{player}, I learned the fisher's name today. And his dog's. And his dog's favourite stick.",
		"Guess what. No, guess. Okay, I'll tell you. The bakery's doing a new bun.",
	},
	gentle = {
		"Your collar's turned up at the back. There. That's better.",
		"I left some bread out for the ducks. Don't tell anyone, they'll say I spoil them.",
		"Are you sleeping all right, {player}? You can tell me.",
		"I planted some herbs by my door. Come and pick some whenever you like.",
		"The bench by the pier gets so cold. I've been knitting it a cushion.",
	},
	bold = {
		"Race you to the pier. No? Fine.",
		"I fixed the gate by the square. Kicked it. Works now.",
		"Need anything carried? I'm bored.",
		"{player}. Hill. Top. You and me. Tomorrow. Be there.",
		"Somebody left a crate on the path. I moved it. With one hand.",
	},
	dreamy = {
		"The water in the fountain goes round and round... I wonder if it gets dizzy.",
		"I followed a cat round the square this morning. It seemed to know where it was going.",
		"Have you noticed the town sounds different after it rains?",
		"{player}... if you could be a cloud, which one? I'd be that one. The wispy one.",
		"I found a shell that sounds like the sea. They all do. This one sounds like a different sea.",
	},
	easygoing = {
		"Found a good nap spot. Not telling you where.",
		"Not much to report. Which is how I like it.",
		"Eh. Same as yesterday. Good, though.",
		"{player}, there's a hammock by the beach nobody uses. Except me now.",
		"Mm. I was going to do something today. Can't remember what. Oh well.",
	},
	proud = {
		"My window boxes are the best on the street. Ask anyone.",
		"I've been told I have very good posture. Twice this week.",
		"I could run this town, you know. Not that you're doing badly, {player}.",
		"I swept the whole square before breakfast. You're welcome, everyone.",
		"My bread came out perfect today. Perfect. I checked.",
	},
	shy = {
		"I found a quiet spot by the water. Nobody goes there.",
		"Um. I like your hat.",
		"I tried to say hello to someone new today. I waved. From quite far away.",
		"{player}... um, can I show you something later? Only if you have time.",
		"I wrote the baker a thank you note. I haven't given it to her yet.",
	},
	cheeky = {
		"Have you noticed the fountain's a bit... fizzier today? No reason.",
		"Somebody turned all the benches round to face the wall. No idea who. Hehe.",
		"I know who keeps putting buttons in the fountain. My lips are sealed. For now.",
		"{player}, if a duck follows you round all day, that wasn't me. Okay, it was me.",
		"Dare you to ring the harbour bell and run. I'll time you :)",
	},
	cool = {
		"Watched the boats come in. Good morning.",
		"Pier's quiet today. I like it.",
		"Got a new spot on the hill. Good view.",
		"{player}. Nice work on the town.",
		"Tea. Bench. Sea. Sorted.",
	},
	prickly = {
		"Someone left the gate open again. I shut it. Again. You're welcome.",
		"The gulls stole my sandwich. I hate them. I saved one some crust anyway.",
		"Your path's wonky, {player}. Ugh. Fine. I'll fix it.",
		"I don't need help. Hand me that, though.",
		"Everyone's too loud today. Except you. You're fine.",
	},
	dramatic = {
		"I tripped on the square today. In front of everyone. So I bowed. They clapped.",
		"Did you see the sunset last night? I wept. A little.",
		"{player}, one day there'll be a statue of me on the square. Facing the sea.",
		"I've written a play about the harbour. It's three hours long. There's a storm in act two.",
		"I lost a sock today. A tragedy in one act.",
	},
	bookish = {
		"Actually, octopuses have three hearts. I've been thinking about that all morning.",
		"Did you know the word muscle comes from the Latin for little mouse? Because of how it moves.",
		"I've been reading about lighthouses. The old keepers had to wind the lamp by hand all night.",
		"{player}, the library has an old map of this coast now. You should come and see it.",
		"A cloud can weigh as much as a hundred elephants and still float. I find that comforting.",
	},
	gloomy = {
		"It'll rain this afternoon. I brought my washing in. Twice.",
		"Saw a gull steal a whole fish today. At least someone's winning.",
		"My tomatoes didn't grow. Typical. One did. It's small. I like it.",
		"{player}, you work too much. Sit. The sea will still be there.",
		"The bench by the pier has a wobbly leg. Like me. Heh.",
	},
	polite = {
		"I've been helping at the library. The books are in such lovely order now.",
		"May I say, {player}, the town looks wonderful this season.",
		"I wrote thank you notes to everyone on my street. It took all afternoon.",
		"I do enjoy the market on a quiet morning. Everyone says good morning.",
		"Thank you for the paths, {player}. My shoes have never been cleaner.",
	},
	foodie = {
		"I had soup for breakfast. Don't judge. It was good soup.",
		"The bakery's cinnamon smell reaches my window. I wake up hungry every day.",
		"{player}, what's your favourite snack? Mine changes every hour.",
		"I went fishing all morning. Mostly I was thinking about fish pie.",
		"The market had strawberries today. Sooo sweet. I had to sit down.",
	},
	nervous = {
		"I checked the weather three times this morning. It said sunny. I brought an umbrella anyway.",
		"Do you think the pier's safe? I walked on it. It was fine. I'm still thinking about it.",
		"{player}, is my door shut? You can see it from here. Is it? Okay. Thank you.",
		"I practised saying hello to the baker four times. Then she said hello first. Phew.",
		"There was a noise in my roof last night. It was a bird. I checked. With a broom.",
	},
}

local JOKES = {
	"Why did the gull sit on the bun? To keep it warm. Then it ate it.",
	"I told the fountain a joke. It didn't laugh. It gave me a wet look.",
	"What do you call a sleepy crab? A crab nap. Hehe.",
	"Why don't crabs share? They're shellfish.",
	"I bought a book about boats. Can't put it down. It's very heavy.",
	"What's a pancake's favourite day? Flip day.",
	"What do you call a fish with no eyes? A fsh. Sorry.",
	"What did the sea say to the beach? Nothing. It just waved.",
	"I'd tell you a bread joke, but it needs time to rise.",
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
			"{y} is my favourite person. Don't tell the others.",
			"If {y} asked me to carry a piano, I'd ask where to.",
			"{y} saved me a seat by the fountain again.",
		},
	},
	{
		min = 30,
		lines = { "{y} lent me a ladder last week. Good sort.", "I had tea round at {y}'s yesterday. Lovely place." },
	},
	{
		min = 10,
		lines = { "I don't know {y} that well yet. They wave a lot.", "{y} seems nice. We should talk more." },
	},
	{ min = -10, lines = { "Who's {y} again? Oh, the one with the hat.", "I haven't really met {y}. Should I?" } },
	{
		min = -40,
		lines = { "{y} and I don't really get on.", "{y} borrowed my rake and gave it back muddy. Just saying." },
	},
	{ min = -101, lines = { "Don't mention {y}. Please.", "I'd rather not talk about {y}, if that's all right." } },
}

-- What a neighbour is like, by their personality.
local LIKE = {
	sunny = "{y} is always so cheerful. How do they do it?",
	gentle = "{y} dropped a cake round last week. No reason, just because.",
	bold = "{y} challenged me to a race. I said no. They raced anyway.",
	dreamy = "{y} told me the moon is a big pebble. I've been thinking about it all day.",
	easygoing = "I've never seen {y} hurry. Not once.",
	proud = "{y} checks their hair in every window they walk past.",
	shy = "{y} said hello to me today. All on their own.",
	cheeky = "{y} put a frog in my bucket. I think it was a present.",
	cool = "{y} said four words to me today. I think that's a lot for them.",
	prickly = "{y} told me my fence was crooked, then fixed it before I could argue.",
	dramatic = "{y} fell over on the square and called it a performance. People clapped.",
	bookish = "{y} told me a fact about eels. I can't stop thinking about it.",
	gloomy = "{y} said it would rain. It did. They looked almost pleased.",
	polite = "{y} thanked me for holding a door. Then thanked me for the thanks.",
	foodie = "{y} smells like fresh bread every time I see them. Every time.",
	nervous = "{y} asked me three times if they'd locked their door. They had.",
}

-- A best friend, as close as two villagers get (there is no romance: the user, "remove any
-- romance, just best friends is the highest"). In the speaker's own way.
local BEST = {
	_ = "{y} and I are best friends. We've got a handshake and everything.",
	sunny = "{y} is my best friend, did I tell you? We do everything together!",
	gentle = "{y} is my best friend. I don't know what I'd do without them.",
	bold = "{y}'s my best friend. Anyone got a problem with that, they come to me.",
	dreamy = "{y} is my best friend. I think we knew each other before, somehow.",
	easygoing = "Me and {y}? Best friends. Easy.",
	proud = "{y} is my best friend. They're very lucky.",
	shy = "{y} is my best friend. I've never had one before.",
	cheeky = "{y} is my best friend. We've got a secret handshake. It takes four minutes.",
	cool = "{y}. Best friend. Yeah.",
	prickly = "{y}'s my best friend. Don't make it a whole thing.",
	dramatic = "{y} is my best friend in the whole world. I wrote them a song. Nine verses.",
	bookish = "{y} is my best friend. We swap books every week and leave notes in the margins.",
	gloomy = "{y} is my best friend. Things are less bad with them around.",
	polite = "{y} is my dearest friend. I'm very grateful for them.",
	foodie = "{y} is my best friend. We share snacks. Even the good ones.",
	nervous = "{y} is my best friend. I asked them to make sure. They said yes. Twice.",
}
local LEVELS = Tuning.Relationships.Levels
local BEST_FRIENDS = LEVELS[#LEVELS].Min

-- By season (1 spring, 2 summer, 3 autumn, 4 winter).
local SEASON = {
	{
		"Have you seen the daffodils by the hall? They're out already.",
		"Spring cleaning today. Found a sock I lost in winter.",
		"Everything smells green. I love it.",
	},
	{
		"Too hot for socks today.",
		"The beach is packed. I found a spot. A small spot.",
		"I got sunburnt on one ear. Just the one.",
	},
	{
		"I love this time of year. Everything's crunchy.",
		"The trees on the hill have gone all orange. Go and look.",
		"It's getting dark so early. Soup weather.",
	},
	{
		"My nose has been cold since Tuesday.",
		"There was ice on the harbour this morning. Thin ice. I didn't test it.",
		"Winter. Blankets. Tea. That's my plan.",
	},
}

local WEATHER = {
	rain = {
		"Good day for staying in with a book.",
		"Rain again. My boots are still wet from yesterday.",
		"I like the sound of rain on the roof. Not on my head, though.",
	},
	storm = {
		"Did you hear that thunder? I hid under the table.",
		"The boats are all tied up. Even the gulls are hiding.",
		"Stay in tonight, {player}. That wind means it.",
	},
	snow = {
		"Have you been out in the snow yet? Go on.",
		"Snow on all the roofs. The whole town looks like a cake.",
		"I made a snowman. He's a bit lopsided. Like his maker.",
	},
	blossom = {
		"There are petals in my hair. Leave them.",
		"The trees by the square are all pink. Go and stand under them.",
		"Petals everywhere. Sweeping is pointless. I don't mind.",
	},
	leaves = {
		"I've swept my step three times today.",
		"The leaves are so crunchy. I've been stepping on all the crunchy ones.",
		"A leaf landed on my head and stayed there for ages.",
	},
	clear = {
		"Not a cloud. I'm making the most of it.",
		"You can see the far islands today. All of them.",
		"Sun's out. Everyone's out. Lovely.",
	},
	cloudy = {
		"Grey again. I don't mind grey.",
		"Cloudy. Good walking weather. Not too hot.",
		"The clouds are so low today the hill's lost its top.",
	},
}

-- A craving, in their own words ({food} is the food's name, so it starts a sentence).
local CRAVE = {
	_ = "I keep thinking about food. {food}, to be exact.",
	sunny = "{player}, don't laugh, but all I can think about today is food. {food}, mostly.",
	gentle = "I don't like to ask, {player}. {food} would be lovely, though.",
	bold = "{food}. I want some. Now, ideally.",
	dreamy = "I dreamed about food last night... {food}, I think. I can still smell it.",
	easygoing = "{food}. Man. Could really go for that.",
	proud = "I have a craving, if you must know. {food}. A good one.",
	shy = "Um. {food}... I've been wanting some. If it's no trouble.",
	cheeky = "I'll stop bothering you if you do one thing for me, {player}. {food}. Deal?",
	cool = "{food}. Want some. That's all.",
	prickly = "Don't make a thing of it. {food}. I want some. Whatever.",
	dramatic = "I yearn, {player}. I yearn for one thing. {food}.",
	bookish = "I've been reading old recipes all week. {food} keeps coming up. I'd quite like some.",
	gloomy = "{food}. I want some. I won't get any. But I want some.",
	polite = "If it isn't too much trouble, {player}. {food} would be very welcome.",
	foodie = "{player}! {food}! I can taste it already. Mmm. Please?",
	nervous = "Um, {player}? {food}. Is that a silly thing to want? I really want it.",
}

-- Someone they'd like to meet.
local MEET = {
	_ = "I'd like to get to know {y}. Could you introduce us?",
	sunny = "{player}, I really want to be friends with {y}. Could you introduce us? Please?",
	gentle = "I'd like to get to know {y} better. Would you introduce us?",
	bold = "Introduce me to {y}. I'd do it myself, but they keep walking off.",
	dreamy = "I keep seeing {y} around... I think we'd get on. Could you introduce us?",
	easygoing = "{y} seems cool. Introduce us sometime?",
	proud = "{y} seems worth knowing. You could introduce us.",
	shy = "I'd like to talk to {y}. I don't know how to start. Could you help, {player}?",
	cheeky = "Who's {y}? They look fun. Introduce me?",
	cool = "{y} seems all right. Introduce us?",
	prickly = "That {y}. Introduce us. I'm curious, that's all.",
	dramatic = "{player}, I must meet {y}. Our paths have to cross. Arrange it!",
	bookish = "I keep seeing {y} reading by the harbour. Would you introduce us?",
	gloomy = "{y} probably won't like me. Introduce us anyway?",
	polite = "Might you introduce me to {y}, {player}? I'd be very grateful.",
	foodie = "{y} always smells like baking. I need to know them. Introduce us?",
	nervous = "Could you introduce me to {y}? What if I say something weird? Stay close, okay?",
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
		return "I keep thinking about food."
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
		add("I needed that. Thanks, {player}.")
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
				add("I slept well last night.")
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
