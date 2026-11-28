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
-- take how people text, none of the lines). A message is one natural sentence, two only when they
-- belong together, never a string of clipped bits, and each says something a neighbour would
-- really say, in their own voice. A line written "First.|Second." is a burst: Chatter.say sends
-- each part as its own message, and Chatter.small runs them together into one bubble, so a burst
-- has to read well both ways.

local K = require(script.Parent.Kit)
local PlotHas = require(script.Parent.Parent.Parent.Sim.PlotHas)

local Chatter = {}

-- Bursts ---------------------------------------------------------------------------------------------

-- Says `text` as a burst, one message for each part (Kit's s:burst). The gesture goes with the first.
function Chatter.say(s: any, who: string, text: string, icon: string?, gesture: string?): any
	return s:burst(who, text, icon, gesture)
end

-- One of several, as a burst.
function Chatter.pick(s: any, who: string, list: { string }, icon: string?, gesture: string?): any
	return s:burst(who, s.ctx.rng:pick(list), icon, gesture)
end

-- In their own way, as a burst: `map` is keyed by personality, "_" for anyone else (K.byPers).
function Chatter.burst(s: any, who: string, map: { [string]: any }, icon: string?, gesture: string?): any
	return s:burst(who, map, icon, gesture)
end

-- A burst as one bubble (the street has room for one card a head).
Chatter.flat = K.flat

-- Topics ---------------------------------------------------------------------------------------------

-- What they talk about. `about` finishes "They talked about ..." in the town log (no {words} in
-- it: the log fills it in once). `open` is what the first says, `yes` and `no` the second's
-- answer, `more` and `back` the first's reply to each. Any `yes` has to follow any `open`, and
-- `more` any `yes` (the same for `no` and `back`), since each is picked on its own. Two
-- neighbours say these to each other, so nobody here calls the player by name.
Chatter.Topics = {
	{
		about = "whether soup counts as a drink",
		open = {
			"I've decided that soup counts as a drink.",
			"I had my soup out of a mug at lunch, so I think that makes it a drink.",
		},
		yes = {
			"If it comes in a mug, it's a drink, so I agree.",
			"I've been drinking mine straight from the bowl for years.",
		},
		no = {
			"It has carrots in it, so it can't be a drink.",
			"You can't drink a dumpling, and believe me, I've tried.",
		},
		more = { "I'm going to ask for it in a cup at the café and see what they say." },
		back = { "Then what's gravy, if soup isn't a drink?" },
	},
	{
		about = "the gulls on the pier",
		open = {
			"I'm sure the gulls on the pier have a boss, the big one with the bent beak.",
			"A gull with a bent beak stared at me for ages on the pier this morning.",
		},
		yes = {
			"That's Bent Beak, and he lands at noon every single day.",
			"The others all go quiet when he turns up, have you noticed?",
		},
		no = { "They're just gulls, and all they want is your chips.", "Gulls don't have bosses, only appetites." },
		more = { "I've started saving him my crusts, just in case." },
		back = { "You've never looked him in the eye, then." },
	},
	{
		about = "how many stairs are too many",
		open = {
			"After twelve stairs I need to sit down.",
			"Whoever built the town hall steps didn't know when to stop.",
		},
		yes = {
			"My rule is twelve stairs, then a landing, then a cookie.",
			"I lose count at nine and just sit down where I am.",
		},
		no = { "I like stairs, because they're free exercise.", "I could do a hundred, as long as nobody rushes me." },
		more = { "Every house should have a bench halfway up the stairs." },
		back = { "Enjoy them, then, and I'll take the ramp." },
	},
	{
		about = "socks with sandals",
		open = {
			"I'm wearing socks with sandals today, so please don't look down.",
			"Have a look at my feet and tell me what you think of socks with sandals.",
		},
		yes = { "Warm toes and fresh air sounds smart to me.", "Nobody looks at feet anyway, so wear what you like." },
		no = {
			"You need to pick one, because your feet look confused.",
			"I noticed this morning, and I've been thinking about it all day.",
		},
		more = { "I'm wearing the stripy ones tomorrow." },
		back = { "Well, my toes are very happy, thank you." },
	},
	{
		about = "whether it'll rain tomorrow",
		open = { "My knee says it's going to rain tomorrow.", "Can you smell that? I think it'll rain tomorrow." },
		yes = {
			"My hair's gone frizzy, so I think you're right.",
			"The gulls are flying low, and that always means rain.",
		},
		no = { "There hasn't been a cloud in days.", "My knee says sun, and my knee is never wrong." },
		more = { "I'm taking my umbrella out either way." },
		back = { "We'll see who's right in the morning, then." },
	},
	{
		about = "crusty bread against soft bread",
		open = {
			"Crusty bread is the only bread worth eating.",
			"I need your honest answer, because I think crusty bread beats soft.",
		},
		yes = { "The crunchier the better, as far as I'm concerned.", "The crust's the best bit, everyone knows that." },
		no = { "I'll take a soft roll every time.", "I like bread that doesn't fight back." },
		more = { "Let's ask the baker if we can have the end bits." },
		back = { "Soft, then. Fine, I'll allow it." },
	},
	{
		about = "the moon following people home",
		open = {
			"Does the moon follow you home at night as well?",
			"The moon followed me all the way home again last night.",
		},
		yes = { "Every night, and it's very nosy about it.", "I've started walking faster, but it keeps up." },
		no = { "It follows everyone, so you're not special.", "That's just how the moon looks when you're walking." },
		more = { "I wave at it now, since that seems only polite." },
		back = { "It still feels personal to me." },
	},
	{
		about = "the right length for a nap",
		open = {
			"I've worked out that the perfect nap is twenty minutes.",
			"Twenty minutes is the perfect length for a nap, I'm sure of it.",
		},
		yes = {
			"Any longer and you wake up not knowing what day it is.",
			"Twenty minutes and then a cookie is how I do it.",
		},
		no = { "It's two hours or don't bother.", "Twenty minutes is barely a blink." },
		more = { "I'm having one right after this, actually." },
		back = { "Any longer and I'd sleep right through lunch." },
	},
	{
		about = "the buttons in the fountain",
		open = {
			"Someone keeps throwing buttons into the fountain instead of coins.",
			"There are dozens of buttons at the bottom of the fountain, have you seen?",
		},
		yes = {
			"I saw, and it's about a whole cardigan's worth.",
			"There are shiny ones too, so somebody's coat won't do up.",
		},
		no = {
			"Buttons are cheaper than coins, so it makes sense.",
			"Maybe whoever does it has more buttons than coins.",
		},
		more = { "I'm going to find out who, so I'll be checking everyone's coats." },
		back = { "You can't make a wish on a button, though." },
	},
	{
		about = "whether fish sleep",
		open = {
			"Did you know fish sleep with their eyes open?",
			"I read that fish sleep with their eyes open, and now I wish I hadn't.",
		},
		yes = {
			"That's creepy, and now I don't want to walk past the pond tonight.",
			"So they're watching us even when they're asleep.",
		},
		no = { "They sleep fine, and you would too if you were a fish.", "I bet they have little fish dreams, though." },
		more = { "I'm going to tiptoe past the pond from now on." },
		back = { "What would a fish even dream about, puddles?" },
	},
	{
		about = "the best season",
		open = {
			"Autumn's the best season, mostly for the soup.",
			"I've always thought autumn was the best season of the year.",
		},
		yes = {
			"Big sweaters and crunchy leaves, so autumn wins for me too.",
			"I love kicking through the leaves on the hill path.",
		},
		no = {
			"It's summer, because you can't swim in autumn.",
			"I like spring, when everything wakes up slowly like I do.",
		},
		more = { "I've already picked out which leaf piles I'm jumping in." },
		back = { "You'll come round to autumn once the soup starts, everyone does." },
	},
	{
		about = "what the market should sell next",
		open = {
			"The market needs a stall that only sells spoons.",
			"Hear me out, because I think the market needs a spoon stall.",
		},
		yes = { "Big ones and little ones, and I'd buy five.", "I'd buy a few, honestly." },
		no = { "Who needs that many spoons?", "Spoons? I'd rather have a stall that sells socks." },
		more = { "I'd run it myself and call it Spoon Corner." },
		back = { "Everyone needs more spoons than they think." },
	},
	{
		about = "whether ghosts get cold",
		open = { "Do you think ghosts get cold? They never seem to wear coats." },
		yes = { "That would explain all the moaning.", "Someone should knit them something warm." },
		no = { "The wind goes straight through them, so they wouldn't feel it.", "I think they're used to it by now." },
		more = { "I'm leaving an old scarf on the gate tonight, just in case." },
		back = { "Then why are they always by the fireplace in stories?" },
	},
	{
		about = "bad handwriting",
		open = { "My shopping list says either eggs or legs, and I can't read my own writing." },
		yes = { "Mine said eggs once and I came home with a hat.", "Same here, so I draw little pictures now." },
		no = { "If you write a bit slower, it's fine.", "Mine's lovely, I think." },
		more = { "Let's swap lists and see what we each come home with." },
		back = { "I wrote it on the bus, and the bus was bumpy." },
	},
	{
		about = "cheese with apple pie",
		open = { "I have cheese with my apple pie, so please don't make that face." },
		yes = { "My grandma always did that, and it's good.", "I have a slice of each on Sundays." },
		no = {
			"Cheese should stay away from dessert.",
			"That sounds like something you'd only do if someone dared you.",
		},
		more = { "I'll bring some round and you'll see." },
		back = { "Try it before you make up your mind." },
	},
	{
		about = "what pet they'd be",
		open = { "If I were a pet, I'd be a cat that sits in a sunny window all day." },
		yes = { "You'd make a great cat, since you already sit in the sun.", "You'd sit on everyone's newspaper, too." },
		no = {
			"You'd be a dog, because you get so excited when the mail comes.",
			"You'd be a dog, because you can't sit still for five minutes.",
		},
		more = { "A warm windowsill is all I'd ever want." },
		back = { "A dog? I'm a bit offended, but I see why." },
	},
	{
		about = "what's on the little islet out at sea",
		open = {
			"I bet there's treasure buried on that little islet.",
			"I've always wondered if there's anything out on the little islet.",
		},
		yes = { "Maybe treasure, or a crab the size of a dog.", "I've always wanted to row out there and look." },
		no = {
			"It's just rocks and one bird, because I've been.",
			"I rowed out once, and I'm sorry to say it's only a rock.",
		},
		more = { "We should go one day and bring sandwiches." },
		back = { "But did you actually dig?" },
	},
	{
		about = "a cloud shaped like a teapot",
		open = { "There was a cloud shaped just like a teapot this morning, did you see it?" },
		yes = {
			"I saw it, and the spout broke off around lunch.",
			"I did, and there was a little round one next to it like a cookie.",
		},
		no = { "I think that was a duck.", "Every cloud looks like a teapot to you." },
		more = { "I took it as a sign and had two cups." },
		back = { "It had a spout and a lid, so it was a teapot." },
	},
	{
		about = "singing in the bath",
		open = { "I sing in the bath, quite loudly, and the neighbours have opinions about it." },
		yes = { "The bathroom has the best echo in the house.", "Me too, and I always go for the high notes." },
		no = { "I know, because I heard you through two walls.", "The bath's for thinking, quietly." },
		more = { "I'm learning a new song, and it has a key change in it." },
		back = { "Well, I'm not stopping, so you'll have to get used to it." },
	},
	{
		about = "borrowed umbrellas",
		open = { "I've never bought an umbrella in my life, but somehow I own four." },
		yes = {
			"Umbrellas belong to the whole town, like the weather.",
			"They go round and round, so it all evens out.",
		},
		no = { "You're meant to give them back, you know.", "One of those is mine, I'm sure of it." },
		more = { "I'll give one back next time it's sunny." },
		back = { "If it's the spotty one, it's mine now." },
	},
	{
		about = "whether toast is just warm bread",
		open = { "Toast is just bread that's had a rough day." },
		yes = { "Ha, that's exactly what it is.", "I mean... yes, I suppose it is." },
		no = { "Toast has earned its own name.", "Toast crunches and bread doesn't, so they're different." },
		more = { "I'll never look at toast the same way again." },
		back = { "That's my point, because the rough day is what makes it crunch." },
	},
	{
		about = "getting up for the sunrise",
		open = { "I got up at six to watch the sunrise, and I'm never doing it again." },
		yes = { "There's one every day, so it can wait.", "I watch the sunset instead, which is the same but later." },
		no = {
			"It's the best part of the day, before anyone starts talking.",
			"Six is late, I'm up at five every day.",
		},
		more = { "It was pink, though, so it was nearly worth it." },
		back = { "I'll stick to my bed, thanks." },
	},
	{
		about = "the smell of the bakery",
		open = { "The bakery smelled so good this morning that I walked past it three times." },
		yes = { "I do that too, and I pretend I'm lost.", "I stand where the wind blows the smell my way." },
		no = { "I can never walk past, I just go straight in.", "Walk past it? I basically live in there." },
		more = { "Tomorrow I'm going in." },
		back = { "That's why you always have flour on your sleeve." },
	},
	{
		about = "a secret talent",
		open = { "I can touch my nose with my tongue, but nobody believes me." },
		yes = { "I believe you, but please don't show me.", "I can wiggle my ears, so we're both gifted." },
		no = { "Go on, prove it, or actually, please don't.", "Nobody can do that." },
		more = { "It's no use to anyone, but I'm still proud of it." },
		back = { "I'll show you one day when you least expect it." },
	},
	{
		about = "the clock on the town hall",
		open = { "The town hall clock is two minutes fast, and I quite like it." },
		yes = { "I set my watch by it, so I'm always early.", "It's like getting two free minutes a day." },
		no = { "I think it's slow, because I've been late all week.", "Somebody should fix it, but not me." },
		more = { "Don't tell anyone, because I like it the way it is." },
		back = { "Leave it alone, two minutes early never hurt anyone." },
	},
	{
		about = "their one tomato",
		open = { "My tomato plant has grown exactly one tomato, and I'm very proud of it." },
		yes = { "One good tomato beats ten bad ones.", "That's one more tomato than I've got." },
		no = { "That's a lot of watering for one tomato.", "Mine has nine, not that I'm counting." },
		more = { "I'm going to put it in a sandwich and eat it very slowly." },
		back = { "It's a very good tomato, though." },
	},
	{
		about = "learning to whistle",
		open = { "I've been learning to whistle, so listen to this... fffff." },
		yes = { "That was nearly a note.", "Keep going, the birds look interested." },
		no = { "That's just breathing loudly.", "Make your lips rounder, like a fish." },
		more = { "By winter I'll be whistling whole tunes." },
		back = { "Fine, I'll keep practising until I get a real note out." },
	},
	{
		about = "the comfy bench by the fountain",
		open = { "I think the bench by the fountain is the comfiest seat in town." },
		yes = { "There's a dip right where you sit, and it's perfect.", "I've fallen asleep on it twice." },
		no = { "The one by the gate is better, because it gets more shade.", "Benches aren't comfy, they're benches." },
		more = { "I might move my whole day over there." },
		back = { "You've never sat on it properly, then." },
	},
	{
		about = "counting stars",
		open = { "I tried to count the stars last night, got to forty and fell asleep." },
		yes = { "I get to about thirty and lose my place.", "Forty's a lot, honestly." },
		no = { "There are millions, so you were never going to win.", "Why count them when you can just look?" },
		more = { "Tonight I'm starting from the other side of the sky." },
		back = { "Somebody has to keep track." },
	},
	{
		about = "a quiet hobby that still impresses people",
		open = { "I want a hobby that's quiet but still impresses people." },
		yes = { "You could knit very small hats.", "You could build card towers, as long as you hold your breath." },
		no = {
			"Quiet and impressive don't really go together, so try the drums.",
			"You could be impressive at napping.",
		},
		more = { "Ooh, I'll start tonight and see who notices." },
		back = { "That isn't what I had in mind at all." },
	},
	{
		about = "the right way to make tea",
		open = {
			"The milk goes in first, then the tea, and that's the rule.",
			"I'll always put the milk in before the tea, whatever anyone says.",
		},
		yes = { "Good, finally someone sensible.", "My grandma did it that way, so that settles it." },
		no = { "Tea first, and I'll argue about this all day.", "Milk first? Never in my life." },
		more = { "Let's have a cup now, made the proper way." },
		back = { "Then I'm never making you a cup." },
	},
	{
		about = "a strange noise at night",
		open = {
			"There's a noise at night like a tiny trumpet, have you heard it?",
			"Did you hear that tooting noise last night?",
		},
		yes = { "I've heard it, it goes toot, toot.", "I've heard it, and I think it's the pipes." },
		no = { "I think that's your snoring.", "It's the wind in the gutter playing a little tune." },
		more = { "I'm staying up tonight to catch whatever it is." },
		back = { "No, it's something outside, and I'm going to find out what." },
	},
	{
		about = "what's at the end of a rainbow",
		open = { "I hope there's cake at the end of a rainbow." },
		yes = { "Lots of it, I hope.", "Cake and a bench to eat it on." },
		no = { "You'd only find a puddle, every time.", "I think it just goes on forever." },
		more = { "I'd share the cake with you, some of it." },
		back = { "Where's your sense of wonder?" },
	},
	{
		about = "the town's name",
		open = { "Do you think whoever named Catalog Town just opened a catalog and pointed?" },
		yes = {
			"I bet it was a furniture catalog, which explains all the benches.",
			"Page one, I bet, with a picture of a town on it.",
		},
		no = { "It's a good name, so don't start.", "We all get our clothes out of one, so it fits." },
		more = { "I'm going to look it up at the library." },
		back = { "Fine, but which catalog?" },
	},
	{
		about = "ice cream in winter",
		open = { "Ice cream is better in winter, because it doesn't melt." },
		yes = { "No drips, so it just makes sense.", "And there's never a line." },
		no = { "Cold food in cold weather? No thanks.", "Winter is for soup." },
		more = { "I'm having one in the snow this year." },
		back = { "You can have hot soup and then cold ice cream, you know." },
	},
	{
		about = "tidying up",
		open = { "I tidied my whole room, and now I can't find anything." },
		yes = { "Same, I lost my keys for a week once.", "I keep my mess where I can see it for that reason." },
		no = { "If you put things back where you got them, it's easy.", "You need labels on everything." },
		more = { "I did find a sock from last spring, though." },
		back = { "I'd need a list just to remember where everything goes." },
	},
	{
		about = "getting a short haircut",
		open = { "I'm thinking of cutting my hair really short.", "Should I get my hair cut really short? Be honest." },
		yes = { "Do it, go on.", "Short hair would really suit you." },
		no = { "Remember what happened last time?", "Give it a week before you decide." },
		more = { "Tomorrow, then, before I change my mind." },
		back = { "If I wait, I'll only talk myself out of it." },
	},
	{
		about = "reading the last page first",
		open = { "I always read the last page of a book first, just to be safe." },
		yes = { "That way you know if it's worth it.", "I ask how films end before I watch them, too." },
		no = { "That's against the rules of books.", "Then why read it at all?" },
		more = { "I like knowing everyone turns out all right." },
		back = { "I still read the middle, and the middle's the good bit." },
	},
	{
		about = "getting someone's name wrong",
		open = { "I called someone by the wrong name for a whole week, and they never said a thing." },
		yes = {
			"Now you have to keep going forever.",
			"Someone called me Gary for a month once, and I answered to it.",
		},
		no = { "You need to tell them today.", "You have to tell them, it's only fair." },
		more = { "It's gone on too long to fix it now." },
		back = { "It's too late, it's been a whole week." },
	},
	{
		about = "the best spot on the beach",
		open = { "The best spot on the beach is by the big rock, easily." },
		yes = { "You get shade in the morning and sun after lunch.", "The crabs leave you alone there, too." },
		no = { "I like it down by the pier, where you can watch the boats.", "Anywhere without sand, so nowhere." },
		more = { "My towel's going down there first thing tomorrow." },
		back = { "You'll change your mind once you try it." },
	},
	{
		about = "the bus being early",
		open = { "The bus came early today, and I don't trust it." },
		yes = { "Something's going on, so keep an eye on it.", "Me neither, it's never early." },
		no = { "Maybe the driver had a nice morning.", "Just be grateful and get on the bus." },
		more = { "I'm watching the stop tomorrow to see if it does it again." },
		back = { "I'll be grateful once I know why it was early." },
	},
	{
		about = "jam and cream on scones",
		open = { "It's jam first and then cream on a scone, and anything else is chaos." },
		yes = { "That's how it's always been done round here.", "Chaos is the right word for it." },
		no = { "Cream first, so the jam sits on top like a hat.", "I just eat the jam with a spoon." },
		more = { "Let's settle it at the café over some scones." },
		back = { "Then I'm afraid you're doing scones wrong." },
	},
	{
		about = "a song neither of them can remember",
		open = { "I've got a song stuck in my head, but all I know is the bit that goes dum dum, da da dum." },
		yes = { "Oh, I know that one... no, I don't, but now it's stuck in mine.", "Now it's in my head too, thanks." },
		no = { "That's the garbage truck backing up.", "I don't think that's a real song." },
		more = { "We'll both be humming it all day now." },
		back = { "It goes somewhere after that, I just don't know where." },
	},
	{
		about = "talking to plants",
		open = { "I talk to my plants, and they never interrupt." },
		yes = { "Mine grew a new leaf after I told it a joke.", "I tell my fern everything." },
		no = { "Plants want water, not a chat.", "My cactus doesn't seem to like my stories." },
		more = { "I told my fern all about my week, and it listened." },
		back = { "Mine seem happier for it, so I'm carrying on." },
	},
	{
		about = "hats as little roofs",
		open = { "A hat is really just a little roof for your head." },
		yes = { "And the brim is the porch.", "That's why I always feel safe in a hat." },
		no = { "A roof doesn't blow off in the wind.", "It's a hat, so don't make it weird." },
		more = { "I want one with a little chimney on top." },
		back = { "Mine has a chin strap, so it's a better roof than most." },
	},
	{
		about = "what the town builds next",
		open = {
			"Someone was out with a tape measure on the empty plot this morning.",
			"There's string tied to little sticks all over the empty plot, so something's being built.",
		},
		yes = { "I hope it's a pond with ducks.", "I saw the string too, and there was loads of it." },
		no = { "People measure things all the time, so it doesn't mean much.", "It'll be a shed, it's always a shed." },
		more = { "I'm keeping a spot free for my chair next to it." },
		back = { "Nobody ties up that much string for nothing." },
	},
	{
		about = "a glove on the fence",
		open = { "Someone hung a lost glove on the fence post, and it's been waving at me all week." },
		yes = { "It waves at me too, so I wave back.", "I say good morning to it now." },
		no = { "That's just the wind.", "Somebody's walking round with one cold hand." },
		more = { "If nobody claims it by Friday, it belongs to the town." },
		back = { "Well, I'm still going to wave back at it." },
	},
	{
		about = "getting mail",
		open = {
			"I got a real letter today, with a stamp and everything.",
			"Nobody writes letters any more, and I miss getting mail.",
		},
		yes = { "Keep the envelope if it's got a nice stamp.", "Even boring mail is good mail." },
		no = { "It's always a bill, though.", "I'd rather someone just knocked on the door." },
		more = { "I'm going to write to my cousin tonight and hope they write back." },
		back = { "I still love hearing the mail come through the door." },
	},
	{
		about = "jumping in puddles",
		open = { "I don't think anyone is ever too old to jump in puddles." },
		yes = { "Never, so keep your rain boots on.", "The day you stop is a sad day." },
		no = { "Your socks would disagree.", "I stopped years ago, and I don't miss it." },
		more = { "There's a big one by the gate, and I'm going in." },
		back = { "Wet socks are half the fun, honestly." },
	},
	{
		about = "the cat that visits everyone",
		open = {
			"A ginger cat comes into my kitchen every morning, and it isn't mine.",
			"The ginger cat had breakfast at my house again this morning.",
		},
		yes = { "It comes to mine at lunch, so it must do rounds.", "Same cat, and I think it has a schedule." },
		no = { "That cat has a home, it's just playing you.", "You need to stop leaving milk out." },
		more = { "I've named it Cookie, so don't tell its real owner." },
		back = { "The cat and I have an understanding." },
	},
	{
		about = "the lighthouse",
		open = {
			"Does anyone actually live in the lighthouse?",
			"The lighthouse came on early last night, so someone must be up there.",
		},
		yes = {
			"Someone does, because there's washing on a line up there.",
			"They must have strong legs with all those stairs.",
		},
		no = { "I think it runs by itself.", "There's nobody up there but the light and some gulls." },
		more = { "One day I'll take a cake up there and find out." },
		back = { "Then who keeps the windows so clean?" },
	},
	{
		about = "going to bed early",
		open = { "I went to bed at eight last night, and it's the best thing I've done all year." },
		yes = {
			"Eight is the dream, because nobody bothers you after eight.",
			"I went at nine and it felt like a day off.",
		},
		no = { "The evening's barely started at eight.", "I'd just lie there thinking about soup." },
		more = { "I'm going for seven tonight." },
		back = { "You'd change your mind if you tried it." },
	},
	{
		about = "getting lost in town",
		open = { "I got lost on the way home again, in my own town." },
		yes = { "All the corners look the same after dark.", "I swear the streets move around at night." },
		no = { "Just follow the smell of the bakery.", "There's one main road, so how?" },
		more = { "I'm tying a ribbon on my gate so I can spot it." },
		back = { "We need more signs, and I'm going to ask for some." },
	},
	{
		about = "favourite words",
		open = { "My favourite word is noodle, so go on and say it out loud." },
		yes = { "Noodle, okay, that's a good one.", "Mine's puddle, and it has the same feel." },
		no = { "That's a food, though.", "Mine's nap, short and useful." },
		more = { "I'm going to start saying it more often." },
		back = { "Noodle's still the best, and I'm not changing my mind." },
	},
	{
		about = "sea glass",
		open = { "I found a piece of green sea glass on the beach, as smooth as soap." },
		yes = { "Green's lovely, but blue's rarer.", "Keep it in a jar on the windowsill." },
		no = { "It's only an old bottle that went for a swim.", "I've got a whole bucket of it, so have some of mine." },
		more = { "I'm going back at low tide to look for more." },
		back = { "Mine's special, though, because I found it myself." },
	},
	{
		about = "the creaky weather vane",
		open = { "The weather vane on the hall creaks every time the wind turns, and I can hear it from bed." },
		yes = { "I hear it too, all night.", "Someone should oil it, but not me." },
		no = { "I like it, because it tells me the wind's changed.", "I sleep right through it." },
		more = { "I'm leaving an oil can by the hall door, quietly." },
		back = { "It's easy to like it when it isn't outside your window." },
	},
	{
		about = "the right way to eat a bun",
		open = { "I eat a sugar bun from the bottom up, so the sugary bit comes last." },
		yes = { "Sugar last, obviously.", "Same, the top is the prize." },
		no = { "Top first, because life's short.", "You're overthinking a bun." },
		more = { "There's a right way to do everything." },
		back = { "Nobody overthinks a bun enough." },
	},
	{
		about = "the boats coming in",
		open = { "I counted eleven boats coming in this morning, and one had a dog on it." },
		yes = { "The brown dog? I think he steers.", "He's always on the blue boat." },
		no = { "Dogs don't go out on boats, do they?", "I think that was a big cat." },
		more = { "I'm going to wave at him tomorrow." },
		back = { "This one had a little hat on, so it was definitely a dog." },
	},
	{
		about = "the last warm day of the year",
		open = { "I think today is the last warm day of the year, I can feel it." },
		yes = { "Then I'm sitting outside until dark.", "Same, so I'm not wasting it." },
		no = { "You said that last week.", "There's always one more." },
		more = { "Let's get ice cream right now while we can." },
		back = { "This time I mean it." },
	},
	{
		about = "the seagull who stole a sandwich",
		open = { "A gull took my sandwich right out of my hand while I was in the middle of a bite." },
		yes = { "They have no shame at all.", "It was the same gull that got me, I know it." },
		no = { "You have to eat faster round here.", "You were waving it about, though." },
		more = { "I'm eating indoors from now on." },
		back = { "I'll hold on with both hands next time, then." },
	},
	-- and some only where there's something to talk about (`need`: a kind of piece in town,
	-- Sim/PlotHas.Kinds; the user, "conversations and chats that only happen when certain work
	-- places are present ... things like mailboxes, fridges, etc. can also be present")
	{
		about = "the new ice cream flavour",
		need = "icecream",
		open = {
			"The ice cream cart has a honey flavour now, and I've had it twice today.",
			"Have you tried the new flavour at the ice cream cart?",
		},
		yes = { "The honey one? I had it for lunch.", "I went back for a second scoop, it's that good." },
		no = { "I always get strawberry, I can't help it.", "Honey in ice cream sounds wrong to me." },
		more = { "Let's go before it sells out." },
		back = { "One spoonful, that's all I ask." },
	},
	{
		about = "who keeps eating things from the fridge",
		need = "fridge",
		open = {
			"Somebody ate the last of the cheese in my fridge, and it wasn't me.",
			"I put a note on my pudding in the fridge, and it still went.",
		},
		yes = { "It's always the cheese, isn't it?", "I've started hiding mine behind the jam." },
		no = { "Are you sure you didn't eat it yourself at midnight?", "Maybe you just forgot you ate it." },
		more = { "I'm buying a lock for the fridge." },
		back = { "I'd remember eating a whole cheese." },
	},
	{
		about = "the swing",
		need = "swing",
		open = {
			"I went so high on the swing this morning that I could see over the roofs.",
			"I still think the swing is the best thing in town, and I'm a grown up.",
		},
		yes = { "Me too, I go on it when nobody's looking.", "It's the best seat in town, honestly." },
		no = { "The swing makes me dizzy.", "I'm too old for swings, sadly." },
		more = { "Race you to it later." },
		back = { "One go, and you'll change your mind." },
	},
	{
		about = "the post being late",
		need = "mailbox",
		open = {
			"The post came at two today, and I'd been checking since nine.",
			"I've been waiting for a parcel all week, and the mailbox is still empty.",
		},
		yes = { "Mine came late too, it must be the hill.", "I check the mailbox about ten times a day." },
		no = { "Mine came on time this morning.", "The post always comes, you just have to stop looking." },
		more = { "I'm going to sit by the mailbox and wait." },
		back = { "Easy to say when yours has come." },
	},
	{
		about = "the stars through the telescope",
		need = "telescope",
		open = {
			"I looked at the moon through the telescope last night, and you can see the craters.",
			"Somebody left the telescope pointing at the lighthouse, and I watched a gull land on it.",
		},
		yes = { "I saw a planet through it once, a bright one.", "It's even better on a really clear night." },
		no = { "I looked once and only saw my own eyelashes.", "I can never find anything through it." },
		more = { "Come and look with me tonight." },
		back = { "You've got to keep the other eye shut." },
	},
	{
		about = "the BBQ",
		need = "bbq",
		open = {
			"We should light the BBQ while the weather's nice.",
			"I can still smell last night's BBQ on my jumper.",
		},
		yes = {
			"I'll bring the sausages if you bring the buns.",
			"I've been waiting all week for someone to say that.",
		},
		no = { "Last time it rained the second we lit it.", "The smoke always follows me round the garden." },
		more = { "Saturday, then, and nobody burns anything." },
		back = { "Stand on the other side, then." },
	},
}

-- Dreams they tell each other. Each finishes "I dreamed ..." (no {words}: it is filled in once).
Chatter.Dreams = {
	"I was a pancake and everyone in town wanted a turn flipping me",
	"a goose chased me round the square and said sorry the whole way",
	"I lived in a teapot and the walls were always warm",
	"I raced the wind along the beach and won by a nose",
	"every door in town was round and nobody could find their own house",
	"a cloud came down and asked if it could be a sheep",
	"the fountain was full of soup and nobody minded",
	"I could talk to crabs and they were all very rude",
	"my teeth had turned into jelly beans",
	"I was mayor of a town full of ducks",
	"it snowed sugar and I ate half the garden",
	"my bed floated out to sea and a whale waved at me",
	"I had an exam on spoons and hadn't studied",
	"the moon came down for tea and ate all the cookies",
	"I was tiny and a snail gave me a ride home",
	"everyone talked in songs and I only knew one",
	"my shoes went for a walk without me",
	"the bakery was a castle and the baker was a friendly dragon",
	"there was a door at the back of my wardrobe that opened onto the beach",
	"I could fly, but only about a foot off the ground",
	"the sea was tea and the boats were cookies",
	"there were stairs in my garden that went down to the stars",
	"the hall clock ran off and I had to chase it home",
	"every house in town grew legs and went for a walk",
	"I was the lighthouse and everyone kept asking me the time",
	"the gulls held a meeting and voted me out of town",
}

-- Little things worth disagreeing about, loudly, for a minute. The first says `q` and `yes`,
-- the second `no`.
Chatter.Debates = {
	{
		q = "Is a cloud wet?",
		yes = "Of course it's wet, it's rain waiting to happen.",
		no = "I've walked through fog and come out bone dry.",
	},
	{
		q = "Do fish ever get thirsty?",
		yes = "Everything gets thirsty sometimes.",
		no = "They live in a drink, so they're fine.",
	},
	{
		q = "Is a muffin just a cake with no confidence?",
		yes = "Yes, it's a shy little cake.",
		no = "A muffin is for breakfast and a cake is for parties.",
	},
	{
		q = "Is cereal a kind of soup?",
		yes = "It's bits in a bowl of liquid, so it's soup.",
		no = "Soup is hot and cereal is breakfast, so no.",
	},
	{
		q = "Which came first, the egg or the omelette?",
		yes = "The egg, because you need one to make the other.",
		no = "The omelette, because nobody wants an egg on its own.",
	},
	{
		q = "Is a beanbag a chair?",
		yes = "You sit on it, so it's a chair.",
		no = "It's a bag of beans, it says so in the name.",
	},
	{
		q = "Do crabs walk sideways, or forwards with their faces on wrong?",
		yes = "Sideways, just look at them.",
		no = "Forwards, their faces are just on the wrong way round.",
	},
	{
		q = "Is it rude to wave at a boat when you don't know who's on it?",
		yes = "You don't know them, so yes, it's rude.",
		no = "Waving at boats is the law of the sea.",
	},
	{
		q = "Can you really be friends with a pigeon?",
		yes = "Of course you can, I've got three.",
		no = "A pigeon's only your friend while you've got bread.",
	},
	{
		q = "Is a baked potato a dinner or a side?",
		yes = "With beans and cheese, it's a whole dinner.",
		no = "It's a side, because a potato can't carry a meal on its own.",
	},
	{
		q = "Should socks always match?",
		yes = "Matching socks mean tidy feet and a tidy mind.",
		no = "Odd socks are more fun.",
	},
	{
		q = "Is the sea just a very big puddle?",
		yes = "It's the same thing, only bigger and saltier.",
		no = "Puddles don't have whales in them.",
	},
	{ q = "Is a hammock a bed?", yes = "You sleep in it, so it's a bed.", no = "It's a net with big ideas." },
	{
		q = "Is it still breakfast if you eat it at noon?",
		yes = "Breakfast is whenever you wake up.",
		no = "At noon it's lunch, I'm sorry.",
	},
	{
		q = "Do ducks have favourite people?",
		yes = "The big one walks me home, so I think we're close.",
		no = "They have favourite bread, which isn't the same thing.",
	},
	{
		q = "Is a hot dog a sandwich?",
		yes = "It's bread, a filling and more bread, so it's a sandwich.",
		no = "It's one piece of bread folded over, so it's closer to a taco.",
	},
	{
		q = "Is a lighthouse a house?",
		yes = "It's got house right there in the name.",
		no = "You couldn't get a sofa up those stairs.",
	},
}

-- Small things two friends can fall out over and forget by teatime. Each is something one of them
-- did ("It was you"), so it finishes "arguing about ...".
Chatter.Spats = {
	"who ate the last cookie",
	"who forgot to water the plants",
	"who left the back door open all night",
	"who chewed the end of the borrowed pen",
	"who started humming that song",
	"who knocked over the stack of chairs",
	"who let the cat in",
	"who heard the owl first",
	"who left the gate open",
	"who forgot to bring the cookies",
	"who took the comfy chair",
	"who finished the milk",
	"who lost the good umbrella",
	"who tracked mud through the hall",
}

-- Openers ---------------------------------------------------------------------------------------------

-- How each personality starts a conversation, whatever the hour.
local OPEN_BY = {
	sunny = { "{b}! There you are, I've been looking for you.", "{b}, wait, wait, have you got a second?" },
	gentle = { "Oh, {b}, did you sleep all right?", "{b}, have you had anything to eat today?" },
	bold = { "{b}, you've got a minute, right? Sit down.", "There you are, {b}. You're free, right?" },
	dreamy = { "Oh, {b}... I didn't see you come round the corner.", "{b}... I was just watching the boats." },
	easygoing = { "*yawn*|Oh, hey, {b}.", "Hey, {b}, it's a nice day for sitting down, isn't it?" },
	proud = { "Ah, {b}, good timing, because I have news.", "{b}, you're just the person I wanted to see." },
	shy = { "Um... {b}?|Hi.", "Oh, {b}... h-hi." },
	cheeky = { "psst, {b}, come here a sec", "hey {b}, don't turn round... ok, you can turn round" },
	cool = { "{b}.", "Hey, {b}." },
	prickly = { "Oh, it's you.|...Hi, {b}.", "{b}, you're in my spot. Ugh, fine, sit down." },
	dramatic = { "{b}! At last, the very person I needed.", "{b}, you won't BELIEVE the morning I've had." },
	bookish = {
		"Oh, {b}, good, I read something odd this morning.",
		"Hello, {b}, can I tell you about something I read?",
	},
	gloomy = { "Hey, {b}, you're still standing, then.", "{b}... it's nice to see someone, heh." },
	polite = { "Excuse me, {b}, do you have a moment?", "Hello, {b}, I hope I am not keeping you from anything." },
	foodie = { "{b}, have you eaten? You look like you haven't.", "{b}, you smell of cinnamon, where have you been?" },
	nervous = { "Oh, {b}! Sorry, you made me jump.", "{b}? I-is this a good time, or should I come back?" },
}

-- The quick second message some of them send straight after the first, before the other answers.
local FOLLOW_BY = {
	sunny = { "Okay, so, listen to this.", "Sorry, I've got loads to tell you." },
	gentle = { "Can I tell you something, if you've got a minute?", "I've been meaning to tell you something." },
	bold = "This'll be quick, I promise.",
	dreamy = { "Hmm... I had something to tell you.", "Wait, I just had a thought, and now it's gone." },
	easygoing = "No rush, I've got all day.",
	proud = "You'll want to hear this, trust me.",
	shy = "If you're not busy, I mean...",
	cheeky = { "hehe", "don't look at me like that" },
	cool = "It's a quick one.",
	prickly = "I'll be quick, I've got things to do.",
	dramatic = "You might want to sit down for this.",
	bookish = "I've been wanting to ask you something all morning.",
	gloomy = "It's nothing much, as usual.",
	polite = "I wanted to tell you something, if it's no trouble.",
	foodie = { "Can you smell toast, or is it just me?", "Is that a bun in your pocket? Never mind." },
	nervous = { "Sorry, is this a bad time?", "I-I'll be quick, I promise." },
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
		table.insert(list, "Oh, hi, {b}, have you got a minute?")
	else
		table.insert(list, "Evening, {b}.")
		table.insert(list, "You're out late, {b}.")
	end
	local w = ctx.weather
	if w == "rain" then
		table.insert(list, "{b}, it's a day for ducks out here.")
	elseif w == "snow" then
		table.insert(list, "{b}, there's so much snow out here.")
	elseif w == "storm" then
		table.insert(list, "That thunder nearly made me drop my bag, {b}.")
	elseif w == "blossom" then
		table.insert(list, "{b}, you've got petals in your hair.")
	elseif w == "leaves" then
		table.insert(list, "Mind the leaves, {b}, they're slippery.")
	end
	table.insert(list, "Hey, {b}, how's your day going?")
	local own = OPEN_BY[K.pers(ctx, a)]
	if own then
		for _ = 1, 2 do
			table.insert(list, if type(own) == "table" then ctx.rng:pick(own) else own)
		end
	end
	return ctx.rng:pick(list)
end

-- Hello back from somebody they get on with well enough.
local GREET = {
	sunny = "Oh, hi, hi, what's up?",
	gentle = "Oh, hello, how are you doing?",
	bold = "Hey, what's up?",
	dreamy = "Oh... hello there.",
	easygoing = "Mm, hey.",
	proud = "Ah, hello, good of you to come over.",
	shy = "Oh, um, hi.",
	cheeky = "oh, hey you",
	cool = "Hey.",
	prickly = "Ugh, what is it?",
	dramatic = "Oh, hello, hello!",
	bookish = "Oh, hello, what is it?",
	gloomy = "Hey... what's up with you?",
	polite = "Hello, how are you today?",
	foodie = "Oh, hi, I was just thinking about lunch.",
	nervous = "Oh! H-hi, you made me jump.",
	_ = "Oh, hi.",
}

-- What the second says once the first has had the last word: when they agreed, and when they
-- didn't. These follow any topic, so they say nothing about the topic itself.
local AGREED = {
	sunny = "Ehehe, that's so you.",
	gentle = "Oh, that does sound like you.",
	bold = "Hah, of course you would.",
	dreamy = "Hmm... I like that.",
	easygoing = "Heh, fair enough.",
	proud = "Hmph, not a bad idea.",
	shy = "Hehe... that does sound like you.",
	cheeky = "hehe, of course you would",
	cool = "Hm, fair.",
	prickly = "Ugh, of course you would.",
	dramatic = "That is SO you.",
	bookish = "Ha, I'd expect nothing less.",
	gloomy = "Heh... that's very you.",
	polite = "How very like you.",
	foodie = "Ha, I like the way you think.",
	nervous = "Ha, that's so you.",
	_ = "Ha, that's so you.",
}
local DISAGREED = {
	sunny = "Ehehe, okay, we'll agree to disagree.",
	gentle = "Well, we can't agree on everything, can we?",
	bold = "Hah, you're still wrong.",
	dreamy = "Hmm... maybe we're both a bit right.",
	easygoing = "Eh, I'm not going to argue about it.",
	proud = "Hmph, I know I'm right, though.",
	shy = "Um... maybe you're right.",
	cheeky = "nope, still wrong, hehe",
	cool = "Agree to disagree, then.",
	prickly = "Whatever, I'm still right.",
	dramatic = "We'll NEVER agree on this, will we?",
	bookish = "Actually, I think we need more facts before we decide.",
	gloomy = "Heh... we'll never settle that one.",
	polite = "Well, I respect your view, even if I do not share it.",
	foodie = "Let's argue about it over lunch.",
	nervous = "O-okay, maybe you've got a point.",
	_ = "Ha, we'll have to agree to disagree.",
}

-- A goodbye between neighbours, after any topic (the talk card's own goodbyes in Data/Personalities
-- are said to the player and can mention things this chat never touched).
local BYE = {
	sunny = { "Okay, I'm off, see you later!", "Bye, bye, wave if you see me!" },
	gentle = { "Take care of yourself, all right?", "Goodbye for now, and wrap up warm." },
	bold = { "Right, I'm off, so stay out of trouble.", "Later, and shout if you need a hand." },
	dreamy = { "Bye for now... I'll be on the pier.", "See you, I'm going to sit on the hill for a bit." },
	easygoing = { "Okay, I'm off for a nap.", "See you, there's no rush on anything." },
	proud = { "Right, I have important things to do.", "Goodbye, and do tell people you saw me." },
	shy = { "Um, bye, thanks for talking to me.", "Okay, um, see you tomorrow." },
	cheeky = { "ok, bye, i'll come and bother you tomorrow", "see you, and remember you never saw me" },
	cool = { "Later.", "See you, and get home safe." },
	prickly = { "Right, I've wasted enough time, see you.", "Bye, and don't do anything silly while I'm gone." },
	dramatic = { "Goodbye, until we meet AGAIN!", "I must go, my fans are waiting." },
	bookish = { "I must get back to my book, but this was lovely.", "I'll let you go, sorry for talking so long." },
	gloomy = { "Bye, that was nice, which is unusual.", "See you, and be careful on the way home, heh." },
	polite = { "It was a pleasure, as always.", "Goodbye for now, and have a lovely day." },
	foodie = { "Bye, I'm off to get a snack!", "It's nearly dinner, so I'd better go." },
	nervous = { "Okay, bye, sorry for keeping you.", "Bye, and get home safe, okay?" },
	_ = "Right, I'd better go, see you later.",
}

-- How they say hello back, by how well they get on, in their own way.
local function greet(ctx: any, s: any, score: number)
	if score <= -10 then
		Chatter.burst(s, "b", {
			sunny = "Oh, um, hi.",
			gentle = "Hello, {a}.",
			bold = "What do you want now?",
			dreamy = "Oh... it's you.",
			easygoing = "Mm, hey.",
			proud = "Hmph, it's you.",
			shy = "Oh... hi.",
			cheeky = "well, well, look who it is",
			cool = "Hm, hi.",
			prickly = "Ugh, what do you want?",
			dramatic = "You, of all people.",
			bookish = "Hello, I suppose.",
			gloomy = "Oh, great, hi.",
			polite = "Good day, {a}.",
			foodie = "I was in the middle of eating, but hi.",
			nervous = "Oh, um... is this about before?",
			_ = "Mm, hello.",
		}, "anger")
	elseif score >= 40 then
		Chatter.burst(s, "b", {
			sunny = { "Oh good, it's you!", "Oh, hi, hi! I was hoping I'd see you." },
			gentle = "{a}, I was hoping I'd see you today.",
			bold = "Hah, good, I was getting bored.",
			dreamy = "Oh, {a}... I was just thinking about you.",
			easygoing = "Oh, hey, good, come and sit down.",
			proud = "Ah, my second favourite person, after me.",
			shy = "Oh, {a}... I'm glad it's you.",
			cheeky = "oh no, it's you... kidding, hi",
			cool = "Hey, good timing.",
			prickly = "Oh, it's you.|...Good, actually. Sit down.",
			dramatic = "{a}! My favourite person in this whole town.",
			bookish = "{a}, good, I've got so much to tell you.",
			gloomy = "Oh, it's you. Good, that's... good.",
			polite = "{a}, what a nice surprise, please sit down.",
			foodie = "{a}, perfect timing, because I've got two buns and only one of me.",
			nervous = "Oh, it's you, phew.",
			_ = "Oh good, it's you.",
		}, "heart")
	else
		Chatter.burst(s, "b", GREET)
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

-- The topics two villagers can talk about here: every topic with no `need`, and those whose
-- piece is in town (ctx.has; the street's chats hand theirs in too).
function Chatter.topics(ctx: any): { any }
	local out = {}
	for _, t in Chatter.Topics do
		if t.need == nil or (ctx.has ~= nil and ctx.has(PlotHas.Kinds[t.need])) then
			table.insert(out, t)
		end
	end
	return out
end

-- A whole chat onto scene `s` between stars a and b. Returns the topic, whether they agreed,
-- and how much it did for their friendship. `goesOn` leaves off the goodbye, for a chat that
-- carries on to another topic (Data/Events/Talks' long chat).
function Chatter.chat(ctx: any, s: any, a: string, b: string, topic: any?, goesOn: boolean?): (any, boolean, number)
	local t = topic or ctx.rng:pick(Chatter.topics(ctx))
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
			Chatter.burst(s, "b", AGREED, "music", "laugh")
		end
	else
		Chatter.pick(s, "b", t.no, "question")
		Chatter.pick(s, "a", t.back, if score <= -10 then "anger" else "sweat")
		if ctx.rng:chance(0.5) then
			Chatter.burst(s, "b", DISAGREED, "question")
		end
	end
	if not goesOn and ctx.rng:chance(0.7) then
		Chatter.burst(s, ctx.rng:pick({ "a", "b" }), BYE, nil, "wave")
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
	local t = ctx.rng:pick(Chatter.topics(ctx))
	local yes = Chatter.agrees(ctx, a, b)
	local out = {
		{ who = "a", text = ctx.f(Chatter.flat(ctx.rng:pick(t.open))) },
		{ who = "b", text = ctx.f(Chatter.flat(ctx.rng:pick(if yes then t.yes else t.no))) },
	}
	if ctx.rng:chance(0.6) then
		table.insert(out, { who = "a", text = ctx.f(Chatter.flat(ctx.rng:pick(if yes then t.more else t.back))) })
		table.insert(
			out,
			{ who = "b", text = ctx.f(Chatter.flat(K.byPers(ctx, b, if yes then AGREED else DISAGREED))) }
		)
	end
	return out
end

return Chatter
