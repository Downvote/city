--!nonstrict
-- Villager to villager talk, made from parts so two neighbours rarely say the same thing twice:
-- an opener that suits the hour and the weather, a greeting back that depends on how well they
-- get on, a topic (one says what they think, the other agrees or doesn't, in their own way, and
-- the first answers that), a reaction, and a goodbye. Chatter.chat writes it onto an event
-- scene (Data/Events/Kit); Chatter.small gives the few lines of a passing word in the street.
-- The banks (topics, dreams, silly debates, things to fall out over) are here too, for the
-- longer conversations in Data/Events/Talks.
--
-- They talk the way friends text each other (the user handed over a messaging app's chats: we
-- take how people text, none of the lines): a burst of two or three short messages where one long
-- one would do, the point in the second or third, each in their own voice, and the player by name
-- ({player}) now and then. A line written "First.|Second." is a burst: Chatter.say sends each
-- part as its own message, and Chatter.small runs them together into one bubble.

local K = require(script.Parent.Kit)

local Chatter = {}

-- Bursts ---------------------------------------------------------------------------------------------

local function parts(text: string): { string }
	local out = {}
	for part in string.gmatch(text, "[^|]+") do
		local trimmed = part:match("^%s*(.-)%s*$")
		if trimmed and #trimmed > 0 then
			table.insert(out, trimmed)
		end
	end
	if #out == 0 then
		table.insert(out, text)
	end
	return out
end

-- Says `text` as a burst, one message for each part. The gesture goes with the first.
function Chatter.say(s: any, who: string, text: string, icon: string?, gesture: string?): any
	for i, part in parts(text) do
		s:say(who, part, icon, if i == 1 then gesture else nil)
	end
	return s
end

-- One of several, as a burst.
function Chatter.pick(s: any, who: string, list: { string }, icon: string?, gesture: string?): any
	return Chatter.say(s, who, s.ctx.rng:pick(list), icon, gesture)
end

-- In their own way, as a burst: `map` is keyed by personality, "_" for anyone else (K.byPers).
function Chatter.burst(s: any, who: string, map: { [string]: any }, icon: string?, gesture: string?): any
	return Chatter.say(s, who, K.byPers(s.ctx, s:vid(who), map), icon, gesture)
end

-- A burst as one bubble (the street has room for one card a head).
function Chatter.flat(text: string): string
	return table.concat(parts(text), " ")
end

-- Topics ---------------------------------------------------------------------------------------------

-- What they talk about. `about` finishes "They talked about ..." in the town log (no {words} in
-- it: the log fills it in once). `open` is what the first says, `yes` and `no` the second's
-- answer, `more` and `back` the first's reply to each. Lines may call the player {player}.
Chatter.Topics = {
	{
		about = "whether soup counts as a drink",
		open = { "Soup is a drink.|I've decided.", "Had my soup out of a mug today.|So. Drink?" },
		yes = { "Mug means drink. Done.", "I've been drinking mine for years." },
		no = { "It has carrots in it.", "You can't sip a dumpling. I've tried." },
		more = { "I'm asking for it in a cup at the café.|Watch me." },
		back = { "Then what's gravy?|Go on. I'll wait." },
	},
	{
		about = "the gulls on the pier",
		open = { "The gulls have a boss.|Big one. Bent beak.", "A gull stared at me this morning.|For ages." },
		yes = { "Bent Beak. He lands at noon. Every day.", "They all go quiet when he turns up." },
		no = { "They're gulls. They want chips.", "Gulls don't have bosses. Just appetites." },
		more = { "I've started saving him my crusts.|In case." },
		back = { "You've never looked him in the eye, then." },
	},
	{
		about = "how many stairs are too many",
		open = { "Twelve stairs.|After twelve I need a sit down.", "Who built the hall steps?|They don't stop." },
		yes = { "Twelve, a landing, a biscuit. That's the rule.", "I lose count at nine and just sit." },
		no = { "I like stairs. Free exercise.", "I could do a hundred. Slowly." },
		more = { "Every house needs a bench halfway up.|I'm telling {player}." },
		back = { "Enjoy them. I'm taking the ramp." },
	},
	{
		about = "socks with sandals",
		open = { "Socks with sandals today.|Don't look.", "Okay, look at my feet.|Socks. Sandals. Thoughts?" },
		yes = { "Warm toes and fresh air. Smart.", "Nobody looks at feet. Wear what you like." },
		no = { "Pick one. Your feet are confused.", "I saw. It's been on my mind all day." },
		more = { "Stripy ones tomorrow." },
		back = { "My toes are very happy, thanks." },
	},
	{
		about = "whether it'll rain tomorrow",
		open = { "My knee says rain tomorrow.", "Smell that?|Rain. Tomorrow, I reckon." },
		yes = { "My hair's gone frizzy. So yes.", "The gulls are flying low. Rain." },
		no = { "Not a cloud for days.", "My knee says sun. My knee's never wrong." },
		more = { "Umbrella's coming with me anyway." },
		back = { "We'll see whose knee wins." },
	},
	{
		about = "crusty bread against soft bread",
		open = { "Crusty bread.|The only bread.", "Important question.|Crusty or soft?" },
		yes = { "The crunchier the better.", "The crust's the best bit. Everyone knows." },
		no = { "Soft rolls. Every time.", "I like bread that doesn't fight back." },
		more = { "Let's ask the baker for the end bits." },
		back = { "Soft. Hm.|Fine. I'll allow it." },
	},
	{
		about = "the moon following people home",
		open = { "The moon followed me home again.", "Does the moon follow you home too?|All the way?" },
		yes = { "Every night. Very nosy.", "I walk faster now. It keeps up." },
		no = { "It follows everyone. You're not special.", "That's just how the moon works." },
		more = { "I wave at it now.|Seems polite." },
		back = { "Still feels personal." },
	},
	{
		about = "the right length for a nap",
		open = { "Twenty minutes.|That's the perfect nap.", "I've worked it out.|Perfect nap. Twenty minutes." },
		yes = { "Any longer and you wake up next week.", "Twenty, then a biscuit." },
		no = { "Two hours or don't bother.", "Twenty? That's a blink." },
		more = { "Having one right after this." },
		back = { "Two hours? You'd miss lunch." },
	},
	{
		about = "the buttons in the fountain",
		open = {
			"Someone keeps throwing buttons in the fountain.|Buttons.",
			"There are buttons in the fountain.|Dozens.",
		},
		yes = { "I saw. A whole cardigan's worth.", "Shiny ones too. Somebody's coat won't do up." },
		no = { "Buttons are cheaper than coins. Makes sense.", "Maybe the fountain likes buttons." },
		more = { "I'm finding out who.|I'll be checking coats." },
		back = { "You can't wish on a button." },
	},
	{
		about = "whether fish sleep",
		open = {
			"Do fish sleep?|With their eyes open?",
			"Fish sleep with their eyes open.|I looked it up. I wish I hadn't.",
		},
		yes = { "Creepy. I'm not walking past the pond tonight.", "They're watching. Even asleep." },
		no = { "They sleep fine. You would too, as a fish.", "I bet they have little fish dreams." },
		more = { "Tiptoeing past the pond from now on." },
		back = { "What does a fish dream about. Puddles?" },
	},
	{
		about = "the best season",
		open = { "Autumn's the best season.|Leaves. Soup.", "Best season. Go.|Mine's autumn." },
		yes = { "Big jumpers. Autumn wins.", "The crunchy leaves. Yes." },
		no = { "Summer. You can't swim in autumn.", "Spring. Everything waking up slowly. Like me." },
		more = { "I've already picked out my leaf piles." },
		back = { "You'll come round. Everyone comes round to soup." },
	},
	{
		about = "what the market should sell next",
		open = { "The market needs a stall that only sells spoons.", "Hear me out.|A spoon stall." },
		yes = { "Big ones, little ones, the lot.", "I'd buy five." },
		no = { "Who needs that many spoons?", "It needs a nap stall. Hear me out." },
		more = { "I'll run it.|Spoon Corner." },
		back = { "Everyone. Everyone needs that many spoons." },
	},
	{
		about = "whether ghosts get cold",
		open = { "Do ghosts get cold?|They never wear coats." },
		yes = { "That's why they moan. Cold ears.", "Someone should knit them something." },
		no = { "The wind goes straight through them.", "They're made of cold. They're used to it." },
		more = { "I'm leaving a scarf on the gate tonight." },
		back = { "Then why do they hang round fireplaces?" },
	},
	{
		about = "bad handwriting",
		open = { "My list says eggs.|Or legs.|I can't read my own writing." },
		yes = { "Mine said eggs and I came home with a hat.", "Same. I draw pictures now." },
		no = { "Write slower. That's all it is.", "Mine's lovely. I think." },
		more = { "Let's swap lists and see what we come home with." },
		back = { "I wrote it on the bus. The bus was bumpy." },
	},
	{
		about = "cheese with apple pie",
		open = { "Cheese with apple pie.|Don't make that face." },
		yes = { "Every Sunday. A slice of each.", "My gran did that. It's good." },
		no = { "Cheese should stay away from pudding.", "That sounds like a dare." },
		more = { "I'll bring some round. You'll see." },
		back = { "Try it before you judge it." },
	},
	{
		about = "what pet they'd be",
		open = { "If I was a pet I'd be a cat.|Window. Sun. All day." },
		yes = { "You'd be a great cat. You already sit in the sun.", "You'd sit on everyone's paper." },
		no = { "You'd be a dog. You get excited about the post.", "Goldfish. A happy one." },
		more = { "A warm windowsill. That's all I'd want." },
		back = { "I don't get excited about the post.|Much." },
	},
	{
		about = "what's on the little islet out at sea",
		open = { "I bet there's treasure on that little islet.", "What's out on the islet, do you reckon?" },
		yes = { "Or a crab the size of a dog.", "I've always wanted to row out and look." },
		no = { "Rocks. And one bird. I've been.", "It's a rock. Sorry." },
		more = { "We should go. Bring sandwiches." },
		back = { "Did you dig, though?|Did you?" },
	},
	{
		about = "a cloud shaped like a teapot",
		open = { "There was a cloud like a teapot this morning.|Did you see?" },
		yes = { "I saw. The spout fell off at lunch.", "With a biscuit cloud next to it." },
		no = { "That was a duck.", "Every cloud's a teapot to you." },
		more = { "I took it as a sign.|Had two cups." },
		back = { "Ducks don't have lids." },
	},
	{
		about = "singing in the bath",
		open = { "I sing in the bath.|Loudly.|The neighbours have opinions." },
		yes = { "Best echo in the house.", "Me too. I do all the high notes." },
		no = { "I heard you. Through two walls.", "The bath's for thinking. Quietly." },
		more = { "Learning a new one. It has a key change." },
		back = { "Thinking's overrated. I'm singing." },
	},
	{
		about = "borrowed umbrellas",
		open = { "How many umbrellas have I bought?|None.|How many have I got? Four." },
		yes = { "Umbrellas belong to the town. Like the weather.", "They go round and round. It's fair." },
		no = { "You're meant to give them back.", "One of those is mine." },
		more = { "I'll give one back.|When it's sunny." },
		back = { "The spotty one? Mine now." },
	},
	{
		about = "whether toast is just warm bread",
		open = { "Toast is just bread that's had a rough day." },
		yes = { "A hard day. That's all it is.", "I mean... yeah." },
		no = { "Toast earned its name.", "Toast crunches. Bread doesn't." },
		more = { "I'll never look at toast the same way." },
		back = { "That's my whole point. The rough day did it." },
	},
	{
		about = "getting up for the sunrise",
		open = { "Got up at six for the sunrise.|Never again." },
		yes = { "There's one every day. It can wait.", "Sunsets. Same thing, but later." },
		no = { "Best bit of the day. Before anyone talks.", "Six is late. I'm up at five." },
		more = { "It was pink, though.|Nearly worth it." },
		back = { "Five? On purpose?" },
	},
	{
		about = "the smell of the bakery",
		open = { "The bakery smelled so good this morning.|I walked past three times." },
		yes = { "Three for me. I pretend I'm lost.", "I stand downwind. On purpose." },
		no = { "I can't walk past. I just go in.", "Walk past? I basically live in there." },
		more = { "Tomorrow I'm going in." },
		back = { "That's why you're always floury." },
	},
	{
		about = "a secret talent",
		open = { "I can touch my nose with my tongue.|Nobody believes me." },
		yes = { "I believe you. Please don't show me.", "I can wiggle my ears. We're both gifted." },
		no = { "Prove it.|No. Wait. Don't.", "Nobody can do that." },
		more = { "It's no use to anyone. I'm still proud." },
		back = { "One day. When you least expect it." },
	},
	{
		about = "the clock on the town hall",
		open = { "The hall clock is two minutes fast.|I like it. I feel ahead." },
		yes = { "I set my watch by it. Always early.", "Two free minutes a day." },
		no = { "It's slow. I've been late all week.", "Somebody should fix it. Not me." },
		more = { "Don't tell anyone. I like it like that." },
		back = { "So we've both been wrong all week." },
	},
	{
		about = "their one tomato",
		open = { "My tomato plant has one tomato.|One.|I'm very proud of it." },
		yes = { "One good tomato beats ten bad ones.", "Has it got a name yet?" },
		no = { "That's a lot of watering for one.", "Mine has nine. Not that I count." },
		more = { "It's going in a sandwich. Slowly." },
		back = { "It's a very good tomato." },
	},
	{
		about = "learning to whistle",
		open = { "I've been learning to whistle.|Listen.|Fffff." },
		yes = { "That was nearly a note.", "Keep going. The birds look worried." },
		no = { "That's just breathing loudly.", "Rounder lips. Like a fish." },
		more = { "By winter I'll be doing tunes." },
		back = { "Like a fish. Fine.|Fffff. Fwee." },
	},
	{
		about = "the comfy bench by the fountain",
		open = { "The fountain bench is the comfiest seat in town.|Agree?" },
		yes = { "There's a dip right where you sit.", "I've fallen asleep on it twice." },
		no = { "The one by the gate. More shade.", "Benches aren't comfy. They're benches." },
		more = { "I might move my whole day there." },
		back = { "You've never sat on it properly." },
	},
	{
		about = "counting stars",
		open = { "Counted the stars last night.|Got to forty.|Then I fell asleep." },
		yes = { "I get to thirty and start again.", "Forty's a lot." },
		no = { "There's millions. You were never going to win.", "Why count them? Just look." },
		more = { "Tonight I'm starting from the other side." },
		back = { "Somebody has to keep track." },
	},
	{
		about = "a quiet hobby that still impresses people",
		open = { "I want a hobby that's quiet.|But impressive." },
		yes = { "Knitting very small hats.", "Card towers. Hold your breath and build." },
		no = { "Quiet and impressive don't go together. Try drums.", "Be impressive at napping." },
		more = { "Small hats. For mice.|I'm doing it." },
		back = { "Drums? My neighbours would leave town." },
	},
	{
		about = "the right way to make tea",
		open = { "Milk first, then tea.|That's the rule.", "Careful with this one.|Milk first, or tea first?" },
		yes = { "Good. Someone sensible.", "My gran did it that way, so that's that." },
		no = { "Tea first. I'll argue about this all day.", "Milk first? Never." },
		more = { "Let's have one now. The proper way." },
		back = { "I'm never making you a cup, then." },
	},
	{
		about = "a strange noise at night",
		open = { "There's a noise at night.|Like a tiny trumpet.", "Did you hear it last night?|Toot. Toot." },
		yes = { "I've heard it. Toot. Toot.", "I think it's the pipes." },
		no = { "That's your snoring.", "It's the wind in the gutter. It plays a tune." },
		more = { "I'm staying up tonight to catch it." },
		back = { "I don't snore.|I hum. In my sleep." },
	},
	{
		about = "what's at the end of a rainbow",
		open = { "End of a rainbow.|What do you hope is there?" },
		yes = { "Cake. Lots of it.", "A bench and a view." },
		no = { "A puddle. It's always a puddle.", "More rainbow." },
		more = { "I'd share the cake.|Some of it." },
		back = { "Where's your sense of wonder?" },
	},
	{
		about = "the town's name",
		open = { "Who named this place Catalog Town?|Did they open a catalog and point?" },
		yes = { "Page one, I bet. A town and a price.", "A furniture catalog. Explains the benches." },
		no = { "It's a good name. Don't start.", "We all dress out of one. Look at us." },
		more = { "I'm asking {player}. They'd know." },
		back = { "Okay, but which catalog?" },
	},
	{
		about = "ice cream in winter",
		open = { "Ice cream's better in winter.|It doesn't melt." },
		yes = { "No drips. It just makes sense.", "And no queue." },
		no = { "Cold food in cold weather? No thanks.", "Winter is for soup." },
		more = { "I'm having one in the snow this year." },
		back = { "Hot soup, cold ice cream. Live a little." },
	},
	{
		about = "tidying up",
		open = { "I tidied my whole room.|Now I can't find anything." },
		yes = { "Same. Lost my keys for a week once.", "I keep my mess where I can see it." },
		no = { "Put things back where you got them.", "Labels. Everything needs a label." },
		more = { "Found a sock from last spring, though." },
		back = { "I'd need a label for the labels." },
	},
	{
		about = "getting a fringe",
		open = { "Thinking of getting a fringe.", "Fringe.|Yes or no. Quick." },
		yes = { "Do it. Go on.", "A fringe would really suit you." },
		no = { "Remember last time?", "Give it a week first." },
		more = { "Tomorrow. Before I lose my nerve." },
		back = { "Last time was the scissors' fault." },
	},
	{
		about = "reading the last page first",
		open = { "I read the last page of a book first.|To be safe." },
		yes = { "Then you know if it's worth it.", "I ask how films end before I watch." },
		no = { "That's against book rules.", "Why read it at all, then?" },
		more = { "I like knowing everyone's all right." },
		back = { "For the middle. The middle's good." },
	},
	{
		about = "getting someone's name wrong",
		open = { "I called someone the wrong name for a week.|They never said." },
		yes = { "Now you have to keep going. Forever.", "Somebody called me Gary for a month. I answered." },
		no = { "Tell them. Today.", "They've been calling you the wrong one back." },
		more = { "I'm in too deep now." },
		back = { "Too late. They sign their notes that way now." },
	},
	{
		about = "the best spot on the beach",
		open = { "Best spot on the beach?|By the big rock. Easy." },
		yes = { "Shade in the morning, sun after lunch.", "And the crabs leave you alone." },
		no = { "Down by the pier. You can watch the boats.", "Anywhere without sand. So nowhere." },
		more = { "My towel's going there first thing." },
		back = { "The boats are fine. The rock's better." },
	},
	{
		about = "the bus being early",
		open = { "The bus came early today.|Early.|I don't trust it." },
		yes = { "Something's going on. Watch it.", "Me neither. It's never early." },
		no = { "Maybe the driver had a nice morning.", "Be grateful. Get on the bus." },
		more = { "I'm watching the stop tomorrow." },
		back = { "Nobody has that nice a morning." },
	},
	{
		about = "jam and cream on scones",
		open = { "Jam first, then cream.|Anything else is chaos." },
		yes = { "Chaos. You said it.", "That's how it's done round here." },
		no = { "Cream first. The jam sits on top like a hat.", "I eat the jam with a spoon." },
		more = { "Let's settle it at the café. With scones." },
		back = { "A jam hat. That's ridiculous.|I love it." },
	},
	{
		about = "a song neither of them can remember",
		open = { "Song stuck in my head.|I know one line.|Dum dum, da da dum." },
		yes = { "I know that one. No, I don't. Dum dum.", "Now it's in my head. Thanks." },
		no = { "That's the bin lorry reversing.", "I don't think that's a song." },
		more = { "We'll be humming it all day." },
		back = { "It goes somewhere. I don't know where." },
	},
	{
		about = "talking to plants",
		open = { "I talk to my plants.|They never interrupt." },
		yes = { "Mine grew a leaf after I told it a joke.", "I tell my fern everything." },
		no = { "Plants want water, not chat.", "My cactus doesn't like my stories." },
		more = { "Told my fern about my week. It listened." },
		back = { "Your cactus needs better stories." },
	},
	{
		about = "hats as little roofs",
		open = { "A hat is a little roof for your head." },
		yes = { "With a porch, if it's got a brim.", "That's why I feel safe in a hat." },
		no = { "A roof doesn't blow off. Usually.", "It's a hat. Don't make it weird." },
		more = { "I want one with a chimney.|{player} could build me one." },
		back = { "Mine stays on. Chin strap." },
	},
	{
		about = "what the town builds next",
		open = {
			"{player} was out measuring again.|Something's coming.",
			"Saw {player} with the hammer this morning.|Very serious face.",
		},
		yes = { "A pond. With ducks, I hope.", "I saw the measuring too. Lots of string." },
		no = { "They measure everything. It's a habit.", "It's a shed. It's always a shed." },
		more = { "I'm keeping a spot free for my chair by it." },
		back = { "Sheds don't need that much string." },
	},
	{
		about = "a glove on the fence",
		open = { "Someone hung a lost glove on the fence post.|It's been waving at me all week." },
		yes = { "It waves at me too. I wave back.", "I say good morning to it now." },
		no = { "That's the wind.", "Somebody's very cold on one side." },
		more = { "Nobody claims it by Friday, it's town property." },
		back = { "The wind doesn't wave. The glove does." },
	},
	{
		about = "getting post",
		open = { "Got a letter today.|A real one. With a stamp.", "Nobody writes letters any more.|I miss post." },
		yes = { "A real stamp? Keep the envelope.", "Even boring post is good post." },
		no = { "It's always a bill.", "I'd rather someone knocked." },
		more = { "Writing back tonight.|Long one." },
		back = { "A bill is still post.|Technically." },
	},
	{
		about = "jumping in puddles",
		open = { "Is there an age where you stop jumping in puddles?|Asking for me." },
		yes = { "No. Never. Wellies on.", "The day you stop is a sad day." },
		no = { "Your socks would say yes.", "I stopped. I miss it. Don't stop." },
		more = { "There's a big one by the gate.|I'm going in." },
		back = { "My socks have made their peace with it." },
	},
	{
		about = "the cat that visits everyone",
		open = {
			"A cat comes into my kitchen every morning.|It isn't mine.",
			"The ginger cat had breakfast at mine.|Again.",
		},
		yes = { "It comes to mine at lunch. It does rounds.", "Same cat. It has a timetable." },
		no = { "That cat has a home. It's playing you.", "Stop leaving milk out." },
		more = { "I've named it Biscuit.|Don't tell its real owner." },
		back = { "We have an understanding, the cat and me." },
	},
	{
		about = "the lighthouse",
		open = { "Does anyone live in the lighthouse?", "The lighthouse came on early tonight.|Who does that?" },
		yes = { "Someone does. There's washing on a line.", "Someone with strong legs. All those stairs." },
		no = { "It runs itself.", "Nobody. Just the light and some gulls." },
		more = { "I'm taking a cake up there one day to find out." },
		back = { "Then whose washing is that?" },
	},
	{
		about = "going to bed early",
		open = { "Went to bed at eight last night.|Best thing I've done all year." },
		yes = { "Eight is the dream. Nobody bothers you at eight.", "I did nine. Felt like a holiday." },
		no = { "Eight? The evening's barely started.", "I'd lie there thinking about soup." },
		more = { "Seven tonight. I'm pushing it." },
		back = { "Soup thoughts are good thoughts." },
	},
	{
		about = "getting lost in town",
		open = { "I got lost on the way home.|In my own town.|Again." },
		yes = { "The streets move. I'm sure of it.", "All the corners look the same at night." },
		no = { "Follow the smell of the bakery.", "There's one main road. How?" },
		more = { "I'm tying a ribbon on my gate." },
		back = { "I'll ask {player} for more signs." },
	},
	{
		about = "favourite words",
		open = { "My favourite word is crumpet.|Say it.|Crumpet." },
		yes = { "Crumpet. Okay, that's a good one.", "Mine's puddle. Same feel." },
		no = { "That's a food.", "Mine's nap. Short. Useful." },
		more = { "I'm going to say it more." },
		back = { "Food words count. Crumpet most of all." },
	},
	{
		about = "sea glass",
		open = { "Found green sea glass on the beach.|Smooth as soap." },
		yes = { "Green's lovely. Blue's rarer.", "Keep it in a jar on the sill." },
		no = { "It's a bottle that went for a swim.", "I've got a whole bucket. Have some." },
		more = { "Going back at low tide for more." },
		back = { "A well travelled bottle, then." },
	},
	{
		about = "the creaky weather vane",
		open = { "The weather vane on the hall creaks.|Every time the wind turns.|I hear it from bed." },
		yes = { "Creak. Creak. I hear it too.", "Someone should oil it. Not me." },
		no = { "I like it. Tells me the wind's changed.", "I sleep through it." },
		more = { "I'm leaving an oil can by the hall door. Quietly." },
		back = { "You sleep through everything." },
	},
	{
		about = "the right way to eat a bun",
		open = { "I eat a bun from the bottom up.|Saves the sugar for last." },
		yes = { "Sugar last. Obviously.", "Same. The top's the prize." },
		no = { "Top first. Life's short.", "You're overthinking a bun." },
		more = { "There's a right way to do everything." },
		back = { "Nobody overthinks a bun enough." },
	},
	{
		about = "the boats coming in",
		open = { "Counted the boats coming in this morning.|Eleven.|One had a dog on it." },
		yes = { "The brown dog? He steers, I think.", "He's always on the blue one." },
		no = { "Dogs don't go on boats.", "That was a big cat." },
		more = { "I'm going to wave at him tomorrow." },
		back = { "This one had a little hat on." },
	},
	{
		about = "the last warm day of the year",
		open = { "I think today's the last warm day.|I can feel it." },
		yes = { "Then I'm sitting outside till dark.", "Same. I'm not wasting it." },
		no = { "You said that last week.", "There's always one more." },
		more = { "Ice cream. Now. While we can." },
		back = { "This time I mean it." },
	},
	{
		about = "the seagull who stole a sandwich",
		open = { "A gull took my sandwich.|Out of my hand.|I was mid bite." },
		yes = { "They have no shame.", "Same gull. I know it was." },
		no = { "Eat faster.", "You were waving it about." },
		more = { "I'm eating indoors from now on." },
		back = { "I wasn't waving.|I was pointing at the view." },
	},
}

-- Dreams they tell each other. Each finishes "I dreamed ..." (no {words}: it is filled in once).
Chatter.Dreams = {
	"I was a pancake and everyone wanted a turn flipping me",
	"a goose chased me round the square, saying sorry the whole way",
	"I lived in a teapot and the walls were warm",
	"I raced the wind along the beach and won by a nose",
	"every door in town was round and nobody could find their house",
	"a cloud asked if it could be a sheep",
	"the fountain was full of soup and nobody minded",
	"I could talk to crabs and they were very rude",
	"my teeth were jelly beans",
	"I was mayor of a town of ducks",
	"it snowed sugar and I ate half the garden",
	"my bed floated out to sea and a whale waved",
	"I had an exam on spoons and hadn't revised",
	"the moon came down for tea and ate all the biscuits",
	"I was tiny and a snail gave me a lift home",
	"everyone talked in songs and I only knew one",
	"my shoes went for a walk without me",
	"the bakery was a castle and the baker was a nice dragon",
	"there was a door at the back of my wardrobe that opened onto the beach",
	"I could fly, but only about a foot off the ground",
	"the sea was tea and the boats were biscuits",
	"there were stairs in my garden going down to the stars",
	"the hall clock ran off and I had to chase it home",
	"every house in town grew legs and went for a stroll",
	"I was the lighthouse and everyone kept asking me the time",
	"the gulls held a meeting and voted me out",
}

-- Little things worth disagreeing about, loudly, for a minute.
Chatter.Debates = {
	{ q = "Is a cloud wet?", yes = "Course it's wet. It's rain waiting.", no = "I've walked through fog. Bone dry." },
	{ q = "Do fish get thirsty?", yes = "Everything gets thirsty.", no = "They live in a drink. They're fine." },
	{
		q = "Is a muffin a cake with no confidence?",
		yes = "Yes. A shy little cake.",
		no = "A muffin is breakfast. A cake is a party.",
	},
	{ q = "Is cereal soup?", yes = "Bits in a bowl of liquid. Soup.", no = "Soup is hot. Cereal is breakfast. Done." },
	{
		q = "Which came first, the egg or the omelette?",
		yes = "The egg. You need one to make the other.",
		no = "The omelette. Nobody wants an egg on its own.",
	},
	{ q = "Is a beanbag a chair?", yes = "You sit on it. Chair.", no = "It's a bag of beans. It says so." },
	{
		q = "Do crabs walk sideways, or forwards facing the wrong way?",
		yes = "Sideways. Look at them.",
		no = "Forwards. Their faces are just on wrong.",
	},
	{
		q = "Is it rude to wave at a boat?",
		yes = "You don't know them. Rude.",
		no = "Waving at boats is the law of the sea.",
	},
	{
		q = "Can you be friends with a pigeon?",
		yes = "Course. I've got three.",
		no = "A pigeon's your friend while you've got bread.",
	},
	{
		q = "Is a jacket potato a dinner or a side?",
		yes = "With beans it's a feast.",
		no = "It's a side. A potato can't carry a meal.",
	},
	{ q = "Should socks match?", yes = "Matching socks. Tidy feet, tidy mind.", no = "Odd socks are more fun." },
	{
		q = "Is the sea just a very big puddle?",
		yes = "Same thing. Bigger. Saltier.",
		no = "Puddles don't have whales.",
	},
	{ q = "Is a hammock a bed?", yes = "You sleep in it. Bed.", no = "It's a net with big ideas." },
	{
		q = "Is it still breakfast at noon?",
		yes = "Breakfast is whenever you wake up.",
		no = "At noon it's lunch. Sorry.",
	},
	{
		q = "Do ducks have favourite people?",
		yes = "The big one walks me home. We're close.",
		no = "They have favourite bread. Different thing.",
	},
	{
		q = "Is a hot dog a sandwich?",
		yes = "Bread, filling, bread. Sandwich.",
		no = "It's one bit of bread. Folded. That's a taco.",
	},
	{
		q = "Is a lighthouse a house?",
		yes = "It's got house in the name.",
		no = "You can't fit a sofa up those stairs.",
	},
}

-- Small things two friends can fall out over and forget by teatime.
Chatter.Spats = {
	"who ate the last biscuit",
	"whose turn it was to water the plants",
	"which way the toilet roll goes",
	"whether the door was left open on purpose",
	"a borrowed pen that came back chewed",
	"who started humming first",
	"the right way to stack chairs",
	"whose shadow is longer",
	"whether a nod counts as a hello",
	"who heard the owl first",
	"who left the gate open",
	"whose turn it was to bring biscuits",
	"who sat in whose chair",
	"whether a tomato is a fruit",
}

-- Openers ---------------------------------------------------------------------------------------------

-- How each personality starts a conversation, whatever the hour.
local OPEN_BY = {
	sunny = { "{b}! There you are.", "{b}. {b}. Got a second?" },
	gentle = { "Oh, {b}. Did you sleep all right?", "{b}. Have you eaten today?" },
	bold = { "{b}. You've got a minute. Sit.", "{b}. You're free, right? Good." },
	dreamy = { "{b}.|Your shadow's very long today.", "Oh. {b}.|You came round the corner like a boat." },
	easygoing = { "*yawn*|Oh. Hey, {b}.", "Hey, {b}. Nice day for sitting down." },
	proud = { "{b}. Good timing. I have news.", "Ah, {b}. Just the person." },
	shy = { "Um... {b}?|Hi.", "Oh. {b}. H-hi." },
	cheeky = { "psst. {b}.|c'mere", "{b}. don't turn round.|ok you can turn round" },
	cool = { "{b}.", "Hey. {b}." },
	prickly = { "Oh. It's you.|...Hi, {b}.", "{b}. You're in my spot.|Fine. Sit." },
	dramatic = { "{b}. At last.|The very person I needed.", "{b} {b} {b}.|You won't believe my morning." },
	bookish = { "{b}, good. I read something odd this morning.", "Oh, {b}. Hello. Can I tell you something?" },
	gloomy = { "Hey, {b}. Still standing, then.", "{b}.|Nice to see someone. Heh..." },
	polite = { "Good day, {b}. Have you a moment?", "Hello, {b}. Am I keeping you from something?" },
	foodie = { "{b}. Have you eaten? You look like you haven't.", "{b}. I smell cinnamon on you. Where from?" },
	nervous = { "Oh. {b}. Sorry. You made me jump.", "{b}? Is this a good time? I can come back." },
}

-- The quick second message some of them send straight after the first, before the other answers.
local FOLLOW_BY = {
	sunny = { "Okay so. Listen.", "Sorry. I've got loads to say." },
	gentle = { "Only if you've got time.", "No rush at all." },
	bold = "This'll be quick.",
	dreamy = { "Hm.|Where was I.", "Wait. I had a thought. There." },
	easygoing = "No rush. Never any rush.",
	proud = "You'll want to hear this.",
	shy = "If you're not busy...",
	cheeky = { "hehe", "don't look at me like that" },
	cool = "Quick one.",
	prickly = "Don't make it a whole thing.",
	dramatic = "Brace yourself.",
	bookish = "I've been thinking about it all morning.",
	gloomy = "It's nothing much. As usual.",
	polite = "If it's no trouble.",
	foodie = { "Do you smell toast? No? Okay.", "Is that a bun in your pocket? Never mind." },
	nervous = { "Sorry. Is this a bad time?", "I-I'll be quick." },
}

-- Openers by the hour, the weather and who is talking ({b} is who they're talking to).
local function opener(ctx: any, a: string): string
	local list = {}
	local h = ctx.hour or 12
	if h < 11 then
		table.insert(list, "Morning, {b}.")
		table.insert(list, "You're up early, {b}.")
	elseif h < 17 then
		table.insert(list, "Afternoon, {b}.")
		table.insert(list, "Oh, hi {b}.|Got a minute?")
	else
		table.insert(list, "Evening, {b}.")
		table.insert(list, "Still out, {b}?")
	end
	local w = ctx.weather
	if w == "rain" then
		table.insert(list, "{b}.|Weather for ducks, eh?")
	elseif w == "snow" then
		table.insert(list, "{b}.|Snow. Have you seen?")
	elseif w == "storm" then
		table.insert(list, "{b}. Did you hear that thunder?")
	elseif w == "blossom" then
		table.insert(list, "{b}, you've got petals in your hair.")
	elseif w == "leaves" then
		table.insert(list, "Mind the leaves, {b}.|Slippy.")
	end
	table.insert(list, "Hey, {b}.|Quick question.")
	local own = OPEN_BY[K.pers(ctx, a)]
	if own then
		for _ = 1, 2 do
			table.insert(list, if type(own) == "table" then ctx.rng:pick(own) else own)
		end
	end
	return ctx.rng:pick(list)
end

-- How they say hello back, by how well they get on, in their own way.
local function greet(ctx: any, s: any, score: number)
	if score <= -10 then
		Chatter.burst(s, "b", {
			sunny = "Oh. Hi.|Um. Hi.",
			gentle = "Hello, {a}.",
			bold = "What now?",
			dreamy = "Oh. You.",
			easygoing = "Mm. Hey.",
			proud = "Oh. It's you.",
			shy = "Oh...|Hi.",
			cheeky = "well well well",
			cool = "Mm.",
			prickly = "What do you want.",
			dramatic = "You. Of all people.",
			bookish = "Hello. I suppose.",
			gloomy = "Great. Hi.",
			polite = "Good afternoon, {a}.",
			foodie = "I was eating. Hi.",
			nervous = "Oh. Um.|Is this about before?",
			_ = "Mm. Hello.",
		}, "anger")
	elseif score >= 40 then
		Chatter.burst(s, "b", {
			sunny = { "Oh good, it's you.", "There you are. I was looking for you." },
			gentle = "{a}. I was hoping I'd see you today.",
			bold = "There you are. Finally.",
			dreamy = "Oh, {a}.|I was just thinking about you.",
			easygoing = "Oh, hey. Good. Sit down.",
			proud = "Ah. My second favourite person. After me.",
			shy = "Oh, {a}.|I'm glad it's you.",
			cheeky = "oh no it's you|kidding. hi",
			cool = "Hey. Good timing.",
			prickly = "Took you long enough. Sit.",
			dramatic = "{a}. My favourite person in this whole town.",
			bookish = "{a}. Good. I've got so much to tell you.",
			gloomy = "Oh. You.|Good. That's... good.",
			polite = "{a}. What a nice surprise. Please, sit.",
			foodie = "{a}. Perfect. I've got two buns and only one of me.",
			nervous = "Oh, it's you.|Phew. Hi.",
			_ = "Oh good, it's you.",
		}, "heart")
	else
		s:voice("b", "hello")
	end
end

-- Does the second one agree? Kind and shy ones lean yes, proud, bold and prickly ones like to
-- argue, and friends agree more than people who don't get on.
function Chatter.agrees(ctx: any, a: string, b: string): boolean
	local score = ctx.rel(a, b)
	local p = 0.6
	if score >= 30 then
		p += 0.15
	elseif score <= -10 then
		p -= 0.25
	end
	local pers = K.pers(ctx, b)
	if pers == "proud" or pers == "bold" or pers == "prickly" then
		p -= 0.15
	elseif pers == "dramatic" or pers == "bookish" then
		p -= 0.05
	elseif pers == "gentle" or pers == "shy" or pers == "sunny" or pers == "polite" or pers == "nervous" then
		p += 0.1
	end
	return ctx.rng:chance(math.clamp(p, 0.15, 0.9))
end

-- A whole chat onto scene `s` between stars a and b. Returns the topic, whether they agreed,
-- and how much it did for their friendship.
function Chatter.chat(ctx: any, s: any, a: string, b: string, topic: any?): (any, boolean, number)
	local t = topic or ctx.rng:pick(Chatter.Topics)
	local score = ctx.rel(a, b)
	Chatter.say(s, "a", opener(ctx, a), nil, "wave")
	local follow = FOLLOW_BY[K.pers(ctx, a)]
	if follow and ctx.rng:chance(0.35) then
		Chatter.burst(s, "a", { _ = follow })
	end
	greet(ctx, s, score)
	Chatter.pick(s, "a", t.open, "idea", "point")
	local yes = Chatter.agrees(ctx, a, b)
	if yes then
		Chatter.pick(s, "b", t.yes, "music")
		Chatter.pick(s, "a", t.more, "sparkle")
		if ctx.rng:chance(0.6) then
			s:voice("b", ctx.rng:pick({ "laugh", "yes", "excited" }), "music", "laugh")
		end
	else
		Chatter.pick(s, "b", t.no, "question")
		Chatter.pick(s, "a", t.back, if score <= -10 then "anger" else "sweat")
		if K.isPers(ctx, b, "cheeky", "prickly") and score >= 20 then
			s:voice("b", "tease", "sparkle", "laugh")
		elseif ctx.rng:chance(0.5) then
			s:voice("b", ctx.rng:pick({ "hmm", "no", "laugh" }), "question")
		end
	end
	if ctx.rng:chance(0.7) then
		s:voice(ctx.rng:pick({ "a", "b" }), "bye", nil, "wave")
	end
	local d = if yes then 6 elseif score <= -10 then -2 else 2
	return t, yes, d
end

-- The street's chats (Services/Villagers) hand in a context with no ctx.f; a personality's line
-- may say {player}, and Npc.say fills that in when the bubble goes up, so it passes as it is.
local function plain(ctx: any): any
	if ctx.f then
		return ctx
	end
	return setmetatable({
		f = function(text: string): string
			return text
		end,
	}, { __index = ctx })
end

-- A passing word in the street (Services/Villagers' chats between neighbours): two or four
-- lines, who says each ("a" or "b") and what. No scene, no player: just the bubbles, a burst
-- run together into one.
function Chatter.small(ctx: any, a: string, b: string): { { who: string, text: string } }
	ctx = plain(ctx)
	local t = ctx.rng:pick(Chatter.Topics)
	local yes = Chatter.agrees(ctx, a, b)
	local out = {
		{ who = "a", text = ctx.f(Chatter.flat(ctx.rng:pick(t.open))) },
		{ who = "b", text = ctx.f(Chatter.flat(ctx.rng:pick(if yes then t.yes else t.no))) },
	}
	if ctx.rng:chance(0.6) then
		table.insert(out, { who = "a", text = ctx.f(Chatter.flat(ctx.rng:pick(if yes then t.more else t.back))) })
		table.insert(out, { who = "b", text = K.voiceText(ctx, b, if yes then "laugh" else "hmm") })
	end
	return out
end

return Chatter
