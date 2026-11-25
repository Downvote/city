--!nonstrict
-- Villager to villager talk, made from parts so two neighbours rarely say the same thing twice:
-- an opener that suits the hour and the weather, a greeting back that depends on how well they
-- get on, a topic (one says what they think, the other agrees or doesn't, in their own way, and
-- the first answers that), a reaction, and a goodbye. Chatter.chat writes it onto an event
-- scene (Data/Events/Kit); Chatter.small gives the few lines of a passing word in the street.
-- The banks (topics, dreams, silly debates, things to fall out over) are here too, for the
-- longer conversations in Data/Events/Talks.
--
-- They talk the way friends text each other (the user pointed at a messaging app's chats: its
-- feel, none of its lines): short bursts, two quick lines where one long one would do, each in
-- their own voice, and the player by name ({player}) now and then.

local K = require(script.Parent.Kit)

local Chatter = {}

-- What they talk about. `about` finishes "They talked about ..." in the town log (no {words} in
-- it: the log fills it in once). `open` is what the first says, `yes` and `no` the second's
-- answer, `more` and `back` the first's reply to each. Lines may call the player {player}.
Chatter.Topics = {
	{
		about = "whether soup is a drink",
		open = {
			"Okay. Soup is a drink. I've decided.",
			"I had my soup out of a mug today. So. Drink?",
		},
		yes = { "Mug means drink. Simple.", "Yep. I drink mine. Always have." },
		no = { "It has carrots in it. That's dinner.", "You can't drink a dumpling. I tried." },
		more = { "I'm asking for it in a mug at the café. Watch me.", "Soup. Drink. Done." },
		back = { "Then what's gravy? Go on. I'll wait.", "Hm. Carrots in a drink. Bold of me." },
	},
	{
		about = "the gulls on the pier",
		open = {
			"I think the gulls have a leader. Big one. Bent beak.",
			"A gull stared at me today. Properly stared. I'm still thinking about it.",
		},
		yes = {
			"Bent Beak. Yes. He's on the pier every day at noon.",
			"They all go quiet when he lands. I've seen it.",
		},
		no = { "They're birds. Hungry birds. That's it.", "Gulls don't have leaders. They have appetites." },
		more = { "I've started saving him my crusts. Just in case.", "If he asks, I was always on his side." },
		back = { "That's what he wants you to think.", "Hm. You've never looked him in the eye, then." },
	},
	{
		about = "how many stairs are too many",
		open = {
			"Twelve stairs. After twelve I need a sit down.",
			"Why do the stairs at the hall keep going? Who needs that many?",
		},
		yes = { "Twelve, a landing, a biscuit. That's the rule.", "I lose count around nine. Then I just sit." },
		no = { "I could do a hundred. Slowly. With breaks.", "Stairs are free exercise. I like them, honestly." },
		more = { "Every house needs a bench halfway up. I'm telling {player}." },
		back = { "Good for you. I'm taking the ramp." },
	},
	{
		about = "socks with sandals",
		open = { "Socks with sandals today. Honestly? Great.", "Don't look at my feet. Okay, look. Socks and sandals." },
		yes = { "Warm toes, fresh air. Can't argue.", "Nobody looks at feet. Wear what you like." },
		no = { "Pick one. Your feet need to know what they are.", "I saw. I've been thinking about it all day." },
		more = { "Stripy ones tomorrow. Maybe." },
		back = { "My feet are very happy, thank you.", "My toes disagree with you." },
	},
	{
		about = "whether it'll rain tomorrow",
		open = { "My knee says rain tomorrow.", "Smell that? Rain. Tomorrow, I reckon." },
		yes = { "My hair's gone frizzy. So yes.", "Gulls are flying low. Rain for sure." },
		no = { "Not a chance. Not a cloud for days.", "My knee says sun, and my knee's never wrong." },
		more = { "Brolly's coming with me anyway." },
		back = { "We'll see whose knee is right.", "Mm. Tomorrow. We'll see." },
	},
	{
		about = "the best kind of bread",
		open = { "Crusty bread is the only bread. I'll argue about this.", "Okay, important. Crusty or soft?" },
		yes = { "Crunchier the better.", "The crust's the best bit. Everyone knows." },
		no = { "Soft rolls. Every time.", "I like bread that doesn't fight back." },
		more = { "Let's ask the baker for the end bits." },
		back = { "You've just got lazy teeth.", "Soft. Hm. Okay. I'll allow it." },
	},
	{
		about = "the moon following people home",
		open = { "Have you noticed the moon follows you home?", "The moon followed me home again. All the way." },
		yes = { "It follows me too. Very nosy.", "I've noticed. I walk faster now." },
		no = { "It follows everyone. You're not special.", "That's just how the moon works." },
		more = { "I wave at it now. To be polite." },
		back = { "Still feels personal." },
	},
	{
		about = "the perfect length for a nap",
		open = { "Twenty minutes. That's the perfect nap.", "I've worked it out. Perfect nap. Twenty minutes." },
		yes = { "Any longer and you wake up in a different week.", "Twenty, then a biscuit." },
		no = { "Two hours or don't bother.", "Twenty? That's a blink." },
		more = { "I'm having one right after this." },
		back = { "Two hours? You'd miss lunch." },
	},
	{
		about = "whoever keeps putting buttons in the fountain",
		open = {
			"Someone's been throwing buttons in the fountain. Buttons. Not coins.",
			"There are buttons in the fountain. Loads of them.",
		},
		yes = { "I saw. A whole cardigan's worth.", "Shiny ones too. Somebody's coat won't do up." },
		no = { "Buttons are cheaper. Makes sense to me.", "Maybe the fountain likes buttons." },
		more = { "I'm finding out who. I'll be checking coats." },
		back = { "You can't wish on a button. Everyone knows that." },
	},
	{
		about = "whether fish sleep",
		open = {
			"Do fish sleep? With their eyes open? Bit creepy...",
			"Fish sleep with their eyes open. I looked it up. I wish I hadn't.",
		},
		yes = { "Really creepy. I'm not walking past the pond tonight.", "They're watching. Even asleep." },
		no = { "They sleep fine. You would too, if you were a fish.", "I bet they have little fish dreams." },
		more = { "Tiptoeing past the pond from now on." },
		back = { "What would a fish dream about? Puddles?" },
	},
	{
		about = "which season is best",
		open = { "Autumn's the best season. Leaves. Soup every day.", "Best season. Go. Mine's autumn." },
		yes = { "Big jumpers too. Autumn wins.", "The crunchy leaves. Yes." },
		no = {
			"Summer. You can't swim in autumn. Well. Once.",
			"Spring. Everything waking up. Like me, slowly.",
		},
		more = { "I've already picked my leaf piles." },
		back = { "You'll come round. Everyone comes round to soup." },
	},
	{
		about = "what the market should sell next",
		open = { "The market needs a stall that only sells spoons.", "Hear me out. A spoon stall." },
		yes = { "Big ones, little ones, the lot.", "I'd buy a spoon. I'd buy five." },
		no = { "Who needs that many spoons?", "It needs a nap stall. Hear me out." },
		more = { "I'll run it. Spoon Corner." },
		back = { "Everyone. Everyone needs that many spoons." },
	},
	{
		about = "whether ghosts get cold",
		open = { "Do ghosts get cold? They never wear coats." },
		yes = { "That's why they moan. Cold ears.", "Someone should knit them something." },
		no = {
			"The wind goes right through them. They don't notice.",
			"Ghosts are made of cold. They're used to it.",
		},
		more = { "I'm leaving a scarf on the gate tonight. Just in case." },
		back = { "Then why do they always hang about by the fire?" },
	},
	{
		about = "whose handwriting is worse",
		open = {
			"My handwriting's so bad I can't read my own shopping list.",
			"My list says eggs. Or legs. I can't tell.",
		},
		yes = { "Mine said eggs and I came home with a hat.", "Same. I draw pictures now." },
		no = { "Mine's lovely. Well. I think it's lovely.", "Write slower. That's all it is." },
		more = { "Let's swap lists and see what we come home with." },
		back = { "I wrote it on the bus. The bus was bumpy." },
	},
	{
		about = "cheese with apple pie",
		open = { "Cheese with apple pie. Have you tried it?", "Don't make a face. Cheese. With apple pie." },
		yes = { "Every Sunday. A slice of each.", "My gran did that. It's good." },
		no = { "Cheese should stay away from pudding.", "That sounds like a dare." },
		more = { "I'll bring some round. You'll see." },
		back = { "Don't knock it till you've tried it." },
	},
	{
		about = "what pet they'd be",
		open = { "If I was a pet I'd be a cat. Window. Sun. All day." },
		yes = { "You'd be a good cat. You already sit in the sun all day.", "You'd sit on everyone's newspaper." },
		no = { "You'd be a dog. You get excited about the post.", "Goldfish. A happy one." },
		more = { "A sunny windowsill. That's all I'd want." },
		back = { "I do not get excited about the post. Much." },
	},
	{
		about = "what's on the little islet out at sea",
		open = { "I bet there's treasure on that little islet.", "What's on the little islet, do you think?" },
		yes = { "Or a crab the size of a dog.", "I've always wanted to row out and look." },
		no = { "Rocks. And one bird. I've been.", "It's a big rock. Sorry." },
		more = { "We should go one day. Bring sandwiches." },
		back = { "Did you dig, though? Did you?" },
	},
	{
		about = "a cloud shaped like a teapot",
		open = { "There was a cloud shaped like a teapot this morning. Did you see?" },
		yes = { "I saw. The spout fell off at lunch.", "And a biscuit one next to it." },
		no = { "That was a duck. Clearly a duck.", "Every cloud looks like a teapot to you." },
		more = { "I took it as a sign. I had two cups." },
		back = { "A duck doesn't have a lid." },
	},
	{
		about = "singing in the bath",
		open = { "I sing in the bath. Loudly. The neighbours have opinions." },
		yes = { "Best echo in the house.", "Me too. I do all the high notes." },
		no = { "I heard you. Through two walls.", "The bath is for thinking. Quietly." },
		more = { "Learning a new one. It has a key change." },
		back = { "Thinking is overrated. I'm singing." },
	},
	{
		about = "borrowed umbrellas",
		open = {
			"Every umbrella I own was borrowed from somebody.",
			"How many umbrellas have I bought? None. How many have I got? Four.",
		},
		yes = { "Umbrellas belong to the town. Like the weather.", "They go round and round. It's fair." },
		no = { "You're meant to give them back, you know.", "One of those is mine, actually." },
		more = { "I'll give one back one day. When it's sunny." },
		back = { "The spotty one? That's mine now." },
	},
	{
		about = "whether toast is just warm bread",
		open = { "Toast is just bread that's been through something." },
		yes = { "It's had a hard day, that's all.", "I mean... yeah." },
		no = { "Toast is toast. It's got a crunch.", "No. Toast earned its name." },
		more = { "I'll never look at toast the same way." },
		back = { "Bread doesn't crunch. That's my whole point." },
	},
	{
		about = "getting up for the sunrise",
		open = { "I got up at six for the sunrise. Never again.", "Six in the morning. Sunrise. Why did I do that." },
		yes = { "There's one every day. It can wait.", "Sunsets. Same thing, but later." },
		no = { "Best bit of the day. Before anyone talks.", "Six is late. I'm up at five." },
		more = { "It was pink, though. Nearly worth it." },
		back = { "Five? On purpose? Are you okay?" },
	},
	{
		about = "the smell of the bakery",
		open = {
			"The bakery smells so good in the morning I walk past twice.",
			"Did you smell the bakery this morning? I walked past three times.",
		},
		yes = { "Three times for me. I pretend I'm lost.", "I stand downwind. On purpose." },
		no = { "I can't walk past at all. I just go in.", "Twice? I basically live in there." },
		more = { "Tomorrow I'm going in. No more walking past." },
		back = { "That's why you're always covered in flour." },
	},
	{
		about = "a secret talent",
		open = { "I can touch my nose with my tongue. Nobody believes me." },
		yes = { "I believe you. Please don't show me.", "I can wiggle my ears. We're both gifted." },
		no = { "Prove it. No. Wait. Don't.", "Nobody can do that." },
		more = { "It's no use to anyone. I'm still proud." },
		back = { "One day. When you least expect it." },
	},
	{
		about = "the clock by the town hall",
		open = { "The clock by the hall is two minutes fast. I like it. I feel ahead." },
		yes = { "I set my watch by it. Always a bit early.", "Two free minutes a day. Lovely." },
		no = { "It's slow, actually. I've been late all week.", "Somebody should fix it. Not me." },
		more = { "Don't tell anyone. I like it like that." },
		back = { "So we've both been wrong all week. Great." },
	},
	{
		about = "their one tomato",
		open = { "My tomato plant has one tomato. One. I'm very proud of it." },
		yes = { "One good tomato beats ten bad ones.", "Has it got a name yet?" },
		no = { "That's a lot of watering for one.", "Mine has nine. Not that I'm counting." },
		more = { "I'm eating it in a sandwich. Slowly." },
		back = { "It's a very good tomato." },
	},
	{
		about = "learning to whistle",
		open = { "I've been learning to whistle for a week. Listen. Fffff." },
		yes = { "That was nearly a note.", "Keep going. The birds look worried, though." },
		no = { "That's just breathing loudly.", "Lips rounder. Like a fish." },
		more = { "By winter I'll be doing tunes." },
		back = { "Like a fish. Fine. Fffff. Fwee." },
	},
	{
		about = "the comfy bench by the fountain",
		open = { "The bench by the fountain is the comfiest in town.", "Fountain bench. Comfiest seat in town. Agree?" },
		yes = { "There's a dip right where you sit.", "I've fallen asleep on it twice." },
		no = { "The one by the gate. More shade.", "Benches aren't comfy. They're benches." },
		more = { "I might move my whole day there." },
		back = { "You've never sat on it properly, then." },
	},
	{
		about = "counting stars",
		open = { "I counted the stars last night. Got to forty. Then I fell asleep." },
		yes = { "I get to thirty. Then I start again.", "Forty's good. Forty's a lot." },
		no = { "There's millions. You were never going to win.", "Why count them? Just look." },
		more = { "Tonight I'm starting from the other side." },
		back = { "Somebody has to keep track." },
	},
	{
		about = "a quiet but impressive hobby",
		open = { "I want a hobby that's quiet but impressive." },
		yes = { "Knitting very small hats.", "Card towers. Hold your breath and build." },
		no = { "Quiet and impressive don't go together. Try drums.", "Be impressive at napping." },
		more = { "Small hats. For mice. I'm doing it." },
		back = { "Drums? My neighbours would leave town." },
	},
	{
		about = "the right way to make tea",
		open = { "Milk first, then tea. That's the rule.", "Quick question. Milk first or tea first? Careful." },
		yes = { "Good. Someone sensible.", "My gran did it that way, so that's that." },
		no = { "Tea first. Always. I'll argue about this all day.", "Milk first? No. Never." },
		more = { "Let's have one now. The proper way." },
		back = { "Well. I'm never making you a cup, then." },
	},
	{
		about = "a strange noise at night",
		open = { "There's a noise at night. Like a tiny trumpet.", "Did you hear it last night? Toot. Toot." },
		yes = { "I've heard it. Toot. Toot.", "I heard it. I think it's the pipes." },
		no = { "That's your snoring.", "That's the wind in the gutter. It does a tune." },
		more = { "I'm staying up tonight to catch it." },
		back = { "I don't snore. I hum. In my sleep." },
	},
	{
		about = "what's at the end of a rainbow",
		open = { "End of a rainbow. What do you hope is there?" },
		yes = { "Cake. Lots of cake.", "A bench and a view. That's all." },
		no = { "A puddle. It's always a puddle.", "More rainbow, probably." },
		more = { "I'd share the cake. Some of it." },
		back = { "Where's your sense of wonder?" },
	},
	{
		about = "the town's name",
		open = { "Who called it Catalog Town? Did they open a catalog and point?" },
		yes = { "Page one, I bet. A picture of a town and a price.", "A furniture catalog. Explains the benches." },
		no = { "It's a good name. Don't you start.", "We all dress out of one. Look at us." },
		more = { "I'm asking {player}. They'd know." },
		back = { "Okay, but which catalog?" },
	},
	{
		about = "ice cream in winter",
		open = { "Ice cream's better in winter. It doesn't melt." },
		yes = { "No drips. It just makes sense.", "And no queue." },
		no = { "Cold food in cold weather? No thanks.", "Winter is for soup. I've said it before." },
		more = { "I'm having one in the snow this year." },
		back = { "Hot soup, cold ice cream. Live a little." },
	},
	{
		about = "tidying up",
		open = { "I tidied my whole room and now I can't find anything." },
		yes = { "Same. I tidied once and lost my keys for a week.", "I keep my mess where I can see it." },
		no = { "Put things back where you got them. Easy.", "Labels. Everything needs a label." },
		more = { "I found a sock from last spring, though." },
		back = { "I'd need a label for the labels." },
	},
	{
		about = "getting a fringe",
		open = { "I'm thinking of getting a fringe.", "Fringe. Yes or no. Quick." },
		yes = { "Do it. Go on.", "A fringe would really suit you." },
		no = { "Remember last time?", "Think about it for a week first." },
		more = { "Tomorrow. Before I chicken out." },
		back = { "Last time was the scissors' fault." },
	},
	{
		about = "reading the last page first",
		open = { "I read the last page of a book first. To be safe." },
		yes = { "Then you know if it's worth it.", "I do it with films. I ask how they end." },
		no = { "That's against the rules. Book rules.", "Why read it at all, then?" },
		more = { "I like knowing everyone's all right." },
		back = { "For the middle bit. The middle bit's good." },
	},
	{
		about = "getting someone's name wrong",
		open = { "I called someone the wrong name for a week and they never said." },
		yes = { "Now you have to keep going. Forever.", "Happened to me. I answered to Gary for a month." },
		no = { "You have to tell them. Today.", "They probably called you the wrong name back." },
		more = { "I'm in too deep now." },
		back = { "Too late. They sign their letters that way now." },
	},
	{
		about = "the best spot on the beach",
		open = { "Best spot on the beach? By the big rock. Easy." },
		yes = { "Shade in the morning, sun after lunch.", "And the crabs leave you alone." },
		no = { "Down by the pier. You can watch the boats.", "Anywhere without sand. Which is nowhere." },
		more = { "I'm putting my towel there first thing." },
		back = { "The boats are fine. The rock is better." },
	},
	{
		about = "the bus being early",
		open = { "The bus came early today. Early. I don't trust it." },
		yes = { "Something's going on. Keep an eye on it.", "Me neither. It's never early." },
		no = { "Maybe the driver had a good morning.", "Be grateful. Get on the bus." },
		more = { "I'm watching the stop tomorrow." },
		back = { "Nobody has that good a morning." },
	},
	{
		about = "jam on scones",
		open = { "Jam first, then cream. Anything else is chaos." },
		yes = { "Chaos. You said it.", "That's how it's done round here." },
		no = { "Cream first. The jam sits on top like a hat.", "I just eat the jam with a spoon." },
		more = { "Let's settle it at the café. With scones." },
		back = { "A jam hat. That's ridiculous. I love it." },
	},
	{
		about = "a song neither of them can remember",
		open = { "Song stuck in my head. I know one line. Dum dum, da da dum." },
		yes = { "Oh, I know that one. No I don't. Dum dum.", "Now it's in my head. Thanks." },
		no = { "That's the bin lorry reversing.", "I don't think that's a song." },
		more = { "We'll be humming it all day now." },
		back = { "It goes somewhere. I just don't know where." },
	},
	{
		about = "talking to plants",
		open = { "I talk to my plants. They never interrupt." },
		yes = { "Mine grew a leaf after I told it a joke.", "Me too. I tell my fern everything." },
		no = { "Plants want water, not chat.", "My cactus doesn't like my stories." },
		more = { "Told my fern about my week today. It listened." },
		back = { "Your cactus needs better stories." },
	},
	{
		about = "whether hats count as furniture for your head",
		open = { "A hat is a little roof for your head." },
		yes = { "With a porch, if it's got a brim.", "That's why I feel safe in a hat." },
		no = { "A roof doesn't blow off in the wind. Usually.", "It's a hat. Don't make it weird." },
		more = { "I want one with a chimney. {player} could build me one." },
		back = { "Mine stays on. Chin strap." },
	},
	-- (newer ones)
	{
		about = "what the town builds next",
		open = {
			"I think {player}'s building a pond next. I saw the measuring.",
			"{player} was out with the hammer again this morning. Something's coming.",
		},
		yes = { "A pond. With ducks, I hope.", "I saw the measuring too. Very serious face." },
		no = { "They measure everything. It's a habit.", "It's a shed. It's always a shed." },
		more = { "I'm keeping a spot free for my chair by it." },
		back = { "Sheds don't need that much measuring." },
	},
	{
		about = "a glove on the fence",
		open = {
			"Someone put a lost glove on the fence post. It's been waving at me all week.",
			"There's a glove on the fence by the gate. Just the one.",
		},
		yes = { "It waves at me too. I wave back.", "I've started saying good morning to it." },
		no = { "It's the wind. Gloves don't wave.", "Somebody's very cold on one side." },
		more = { "If nobody claims it by Friday, it's town property." },
		back = { "The wind doesn't wave. The glove does." },
	},
	{
		about = "getting post",
		open = { "I got a letter today. A real one. With a stamp.", "Nobody writes letters any more. I miss post." },
		yes = { "A real stamp? Keep the envelope.", "Post is the best. Even the boring kind." },
		no = { "It's always a bill. Every time.", "I'd rather someone just knocked." },
		more = { "I'm writing back tonight. Long one. Very long." },
		back = { "A bill is still post. Technically." },
	},
	{
		about = "jumping in puddles",
		open = { "Is there an age where you stop jumping in puddles? Asking for me." },
		yes = { "No. Never. Wellies on.", "The day you stop is a sad day." },
		no = { "Your socks would say yes.", "I stopped. I miss it. Don't stop." },
		more = { "There's a big one by the gate. I'm going in." },
		back = { "My socks have accepted it." },
	},
	{
		about = "the cat that visits everyone",
		open = {
			"There's a cat that comes into my kitchen every morning. It isn't mine.",
			"The ginger cat had breakfast at mine today. Again.",
		},
		yes = { "It comes to mine at lunch. It's doing rounds.", "Same cat. It has a whole timetable." },
		no = { "That cat has a home. It's playing you.", "Stop leaving milk out and it'll stop coming." },
		more = { "I've named it Biscuit. Don't tell its real owner." },
		back = { "We have an understanding, the cat and me." },
	},
	{
		about = "the lighthouse",
		open = {
			"Does anyone actually live in the lighthouse?",
			"The lighthouse came on early tonight. Who does that?",
		},
		yes = { "Someone does. I've seen washing on the line.", "Someone with very strong legs. All those stairs." },
		no = { "It runs itself. It's a lighthouse.", "Nobody. Just the light and some gulls." },
		more = { "I'm taking a cake up there one day to find out." },
		back = { "Then who's hanging out the washing?" },
	},
	{
		about = "going to bed early",
		open = { "I went to bed at eight last night. Best thing I've done all year." },
		yes = { "Eight is the dream. Nobody bothers you at eight.", "I did nine. Felt like a holiday." },
		no = { "Eight? The evening's barely started.", "I'd just lie there thinking about soup." },
		more = { "Seven tonight. I'm pushing it." },
		back = { "Soup thoughts are good thoughts. Still went to bed." },
	},
	{
		about = "getting lost in town",
		open = { "I got lost on the way home. In my own town. Again." },
		yes = { "The streets move. I'm sure of it.", "All the corners look the same at night." },
		no = { "Follow the smell of the bakery. Works every time.", "There's one main road. How?" },
		more = { "I'm tying a ribbon on my gate." },
		back = { "I'll ask {player} to put up more signs." },
	},
	{
		about = "favourite words",
		open = { "My favourite word is crumpet. Say it. Crumpet." },
		yes = { "Crumpet. Okay, that's a good one.", "Mine's puddle. Same feel." },
		no = { "That's a food, not a word.", "Mine's nap. Short. Useful." },
		more = { "I'm going to say it more. Crumpet." },
		back = { "Food words count. Crumpet especially." },
	},
	{
		about = "sea glass",
		open = { "I found a bit of green sea glass on the beach. Smooth as soap." },
		yes = { "Green's lovely. Blue's rarer, though.", "Keep it in a jar on the windowsill." },
		no = { "It's a broken bottle that went for a swim.", "I've got a whole bucket. You can have some." },
		more = { "I'm going back at low tide for more." },
		back = { "A very well travelled bottle, then." },
	},
	{
		about = "the creaky weather vane",
		open = { "The weather vane on the hall creaks every time the wind turns. I hear it from bed." },
		yes = { "Creak. Creak. I hear it too.", "Someone should oil it. Not me." },
		no = { "I like it. Tells me the wind's changed.", "I sleep right through it." },
		more = { "I'm leaving an oil can by the hall door. Quietly." },
		back = { "You sleep through everything." },
	},
}

-- Dreams they tell each other. Each finishes "I dreamed ..." (no {words}: it is filled in once).
Chatter.Dreams = {
	"I was a pancake and everyone wanted to flip me",
	"a polite goose chased me all round town, saying sorry the whole time",
	"I lived inside a teapot and the walls were warm",
	"I raced the wind and won by a nose",
	"all the doors in town were round and nobody could find their house",
	"a cloud asked me if it could be a sheep",
	"the fountain was full of soup and nobody minded",
	"I could talk to crabs and they were very rude",
	"my teeth were made of jelly beans",
	"I was in charge of a town of ducks",
	"it snowed sugar and I ate the garden",
	"my bed floated out to sea and I waved at a whale",
	"I had to sit an exam on spoons",
	"the moon came down for tea and ate all the biscuits",
	"I was tiny and a snail gave me a lift",
	"everyone spoke in songs and I only knew one",
	"my shoes walked off without me",
	"the bakery was a castle and the baker was a dragon, a nice one",
	"I found a door in my wardrobe that went to the beach",
	"I could fly, but only about a foot off the ground",
	"the sea was tea and the boats were biscuits",
	"there were stairs in my garden that went down to the stars",
	"the clock on the hall ran off and I had to chase it home",
	"every house in town had legs and they went for a walk",
}

-- Little things worth disagreeing about, loudly, for a minute.
Chatter.Debates = {
	{
		q = "Is a cloud wet?",
		yes = "Course it's wet. It's made of rain.",
		no = "You can't get wet from a cloud. I've walked through fog.",
	},
	{
		q = "Do fish get thirsty?",
		yes = "Everything gets thirsty. Even fish.",
		no = "They live in a drink. They're fine.",
	},
	{
		q = "Is a muffin just a cake with no confidence?",
		yes = "Yes. A shy little cake.",
		no = "A muffin is breakfast. A cake is a party.",
	},
	{ q = "Is cereal soup?", yes = "Bits in a bowl of liquid. Soup.", no = "Soup is hot. Cereal is breakfast. Done." },
	{
		q = "Which came first, the egg or the omelette?",
		yes = "The egg. You need an egg to make an omelette.",
		no = "The omelette. Nobody wants an egg on its own.",
	},
	{ q = "Is a beanbag a chair?", yes = "You sit on it. Chair.", no = "It's a bag. Of beans. It's in the name." },
	{
		q = "Do crabs walk sideways, or forwards with their faces turned?",
		yes = "Sideways. Look at them.",
		no = "Forwards. They just face the wrong way.",
	},
	{
		q = "Is it rude to wave at a boat?",
		yes = "You don't know them. Rude.",
		no = "Waving at boats is the law of the sea.",
	},
	{
		q = "Can you be friends with a pigeon?",
		yes = "Course you can. I've got three.",
		no = "A pigeon is only your friend while you've got bread.",
	},
	{
		q = "Is a jacket potato a dinner or a side?",
		yes = "Big enough to be dinner. With beans, it's a feast.",
		no = "It's a side. A potato can't carry a whole meal.",
	},
	{
		q = "Should socks match?",
		yes = "Matching socks. Tidy feet, tidy mind.",
		no = "Odd socks are more fun. And easier.",
	},
	{
		q = "Is the sea just a very big puddle?",
		yes = "Same thing. Bigger. Saltier.",
		no = "Puddles don't have whales in them.",
	},
	{
		q = "Is a hammock a bed?",
		yes = "You sleep in it. Bed.",
		no = "It's a net with big ideas.",
	},
	{
		q = "Is it still breakfast if you have it at noon?",
		yes = "Breakfast is whenever you wake up.",
		no = "At noon it's lunch. Sorry.",
	},
	{
		q = "Do ducks have favourite people?",
		yes = "The big one follows me home. We're close.",
		no = "They have favourite bread. That's different.",
	},
}

-- Small things two friends can fall out over and forget by teatime.
Chatter.Spats = {
	"who ate the last biscuit",
	"whose turn it was to water the plants",
	"which way the toilet roll goes",
	"whether the door was left open on purpose",
	"a borrowed pen that came back chewed",
	"who was humming first",
	"the right way to stack chairs",
	"whose shadow is longer",
	"whether a wave counts as a hello",
	"who heard the owl first",
	"who left the gate open",
	"whose turn it was to bring biscuits",
	"who sat in whose chair",
}

-- How each personality starts a conversation, whatever the hour.
local OPEN_BY = {
	sunny = "Oh, {b}! Hi hi. I was hoping I'd run into you.",
	gentle = "Ah, {b}. How are you keeping?",
	bold = "{b}. Got a minute? Good.",
	dreamy = "Oh... {b}. I was just thinking about you. Or about clouds. You were in it.",
	easygoing = "Hey, {b}. Mm. Nice day for sitting.",
	proud = "Ah, {b}. Just the person.",
	shy = "Um... hi, {b}.",
	cheeky = "Psst. {b}. C'mere a sec.",
	cool = "{b}. Hey.",
	prickly = "Oh. It's you, {b}. Fine. Hi.",
	dramatic = "{b}. At last. I have news.",
	bookish = "Oh, {b}, good. I read something odd today. Hello, first.",
	gloomy = "Hey, {b}. Still here, then.",
	polite = "Good day, {b}. Do you have a moment?",
	foodie = "{b}. Have you eaten? Sit down.",
	nervous = "Oh. {b}. Sorry, you made me jump. Hi.",
}

-- The quick second line some of them send straight after the first, before the other answers.
local FOLLOW_BY = {
	sunny = { "Okaaay so. Listen.", "Hehe. Sorry. I've got loads to say." },
	gentle = { "Only if you've got time.", "No rush at all." },
	bold = "This'll be quick.",
	dreamy = { "Hm... where was I.", "Wait. I had a thought. There it is." },
	easygoing = "No rush.",
	proud = "You'll want to hear this.",
	shy = "Um. If you're not busy...",
	cheeky = { "Hehe. Okay.", "Don't look at me like that." },
	cool = "Quick one.",
	prickly = "Don't make it a whole thing.",
	dramatic = "Brace yourself.",
	bookish = "I've been thinking about this all morning, actually.",
	gloomy = "It's nothing much. As usual.",
	polite = "If it's no trouble.",
	foodie = { "Do you smell toast? No? Okay.", "Is that a bun in your pocket? Never mind." },
	nervous = { "Is now okay? I can come back.", "Sorry. Is this a bad time?" },
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
		table.insert(list, "Oh, hi {b}. Got a minute?")
	else
		table.insert(list, "Evening, {b}.")
		table.insert(list, "Still out, {b}?")
	end
	local w = ctx.weather
	if w == "rain" then
		table.insert(list, "Lovely weather for ducks, eh {b}?")
	elseif w == "snow" then
		table.insert(list, "{b}. Snow. Have you seen?")
	elseif w == "storm" then
		table.insert(list, "Did you hear that thunder, {b}?")
	elseif w == "blossom" then
		table.insert(list, "{b}, you've got petals in your hair.")
	elseif w == "leaves" then
		table.insert(list, "Mind the leaves, {b}. Slippy.")
	end
	table.insert(list, "Hey, {b}. Can I ask you something?")
	local own = OPEN_BY[K.pers(ctx, a)]
	if own then
		table.insert(list, own)
		table.insert(list, own)
	end
	return ctx.rng:pick(list)
end

-- How they say hello back, by how well they get on, in their own way.
local function greet(ctx: any, s: any, score: number)
	if score <= -10 then
		s:by("b", {
			sunny = "Oh. Hi. Um, hi.",
			gentle = "Hello, {a}.",
			bold = "What now?",
			dreamy = "Oh. You.",
			easygoing = "Mm. Hey.",
			proud = "Oh. It's you.",
			shy = "Oh... hi.",
			cheeky = "Well, look who it is.",
			cool = "Mm.",
			prickly = "What do you want.",
			dramatic = "Oh. You. Of all people.",
			bookish = "Hello. I suppose.",
			gloomy = "Great. Hi.",
			polite = "Good afternoon. {a}.",
			foodie = "I was eating. Hi.",
			nervous = "Oh. Um. Is this about before?",
			_ = "Mm. Hello.",
		}, "anger")
	elseif score >= 40 then
		s:by("b", {
			sunny = { "Oh good, it's you. I was hoping it'd be you.", "There you are. I was just looking for you." },
			gentle = "{a}. I was hoping I'd see you today.",
			bold = "There you are. Finally.",
			dreamy = "Oh, {a}. I was just thinking about you.",
			easygoing = "Oh, hey. Good. Sit down.",
			proud = "Ah. My favourite person. After me.",
			shy = "Oh, {a}. Hi. I'm glad it's you.",
			cheeky = "Oh no, it's you. Kidding. Hi.",
			cool = "Hey. Good timing.",
			prickly = "Took you long enough. Sit.",
			dramatic = "{a}. My favourite person in this whole town.",
			bookish = "{a}. I was hoping it'd be you. I've got so much to tell you.",
			gloomy = "Oh. You. Good. That's... good.",
			polite = "{a}. What a nice surprise. Please, sit.",
			foodie = "{a}. Perfect. I've got two buns and only one of me.",
			nervous = "Oh, it's you. Phew. Hi.",
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
	s:say("a", opener(ctx, a), nil, "wave")
	local follow = FOLLOW_BY[K.pers(ctx, a)]
	if follow and ctx.rng:chance(0.35) then
		s:by("a", { _ = follow })
	end
	greet(ctx, s, score)
	s:pick("a", t.open, "idea", "point")
	local yes = Chatter.agrees(ctx, a, b)
	if yes then
		s:pick("b", t.yes, "music")
		s:pick("a", t.more, "sparkle")
		if ctx.rng:chance(0.6) then
			s:voice("b", ctx.rng:pick({ "laugh", "yes", "excited" }), "music", "laugh")
		end
	else
		s:pick("b", t.no, "question")
		s:pick("a", t.back, if score <= -10 then "anger" else "sweat")
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
-- lines, who says each ("a" or "b") and what. No scene, no player: just the bubbles.
function Chatter.small(ctx: any, a: string, b: string): { { who: string, text: string } }
	ctx = plain(ctx)
	local t = ctx.rng:pick(Chatter.Topics)
	local yes = Chatter.agrees(ctx, a, b)
	local out = {
		{ who = "a", text = ctx.f(ctx.rng:pick(t.open)) },
		{ who = "b", text = ctx.f(ctx.rng:pick(if yes then t.yes else t.no)) },
	}
	if ctx.rng:chance(0.6) then
		table.insert(out, { who = "a", text = ctx.f(ctx.rng:pick(if yes then t.more else t.back)) })
		table.insert(out, { who = "b", text = K.voiceText(ctx, b, if yes then "laugh" else "hmm") })
	end
	return out
end

return Chatter
