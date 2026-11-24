--!nonstrict
-- Villager to villager talk, made from parts so two neighbours rarely say the same thing twice:
-- an opener that suits the hour and the weather, a greeting back that depends on how well they
-- get on, a topic (one says what they think, the other agrees or doesn't, in their own way, and
-- the first answers that), a reaction, and a goodbye. Chatter.chat writes it onto an event
-- scene (Data/Events/Kit); Chatter.small gives the few lines of a passing word in the street.
-- The banks (topics, dreams, silly debates, things to fall out over) are here too, for the
-- longer conversations in Data/Events/Talks.

local K = require(script.Parent.Kit)

local Chatter = {}

-- What they talk about. `about` finishes "They talked about ..." in the town log. `open` is
-- what the first says, `yes` and `no` the second's answer, `more` and `back` the first's reply
-- to each.
Chatter.Topics = {
	{
		about = "whether soup is a drink",
		open = { "Soup is a drink. I've decided.", "I had my soup from a mug today. So it's a drink now." },
		yes = { "Obviously. Bread is the straw.", "If it fits in a mug, it's a drink." },
		no = { "If it has carrots in it, it's dinner.", "You can't drink a dumpling. I've tried." },
		more = { "We should tell the café. They'll want to know." },
		back = { "Then what's gravy? Answer me that." },
	},
	{
		about = "the gulls on the pier",
		open = { "I think the gulls have a leader. A big one with a bent beak.", "A gull looked me in the eye today. It knew things." },
		yes = { "Bent Beak. He runs this town, really.", "They meet on the pier at noon. I've seen it." },
		no = { "They're just birds. Hungry birds.", "Gulls don't have leaders. They have appetites." },
		more = { "I'm going to start bringing him crusts. For safety." },
		back = { "That's exactly what Bent Beak wants you to think." },
	},
	{
		about = "how many stairs are too many",
		open = { "Any more than twelve stairs and I need a sit down." },
		yes = { "Twelve, then a landing, then a snack.", "I count them. I always lose count on nine." },
		no = { "I could do a hundred. Slowly. With breaks.", "Stairs are free exercise. I love them." },
		more = { "Every house should have a bench halfway up." },
		back = { "Show off. I'm taking the ramp." },
	},
	{
		about = "socks with sandals",
		open = { "I wore socks with sandals today and I felt free." },
		yes = { "Warm toes, fresh air. Best of both.", "Nobody looks at feet. Do what you like." },
		no = { "Pick one. Feet need to know what they are.", "I saw. I've been thinking about it all day." },
		more = { "I might do stripy ones tomorrow." },
		back = { "My feet are very sure of themselves, thank you." },
	},
	{
		about = "whether it'll rain tomorrow",
		open = { "My knee says rain tomorrow.", "Smell that? Rain's coming. Tomorrow, I reckon." },
		yes = { "My hair agrees with your knee.", "The gulls are flying low. Rain for sure." },
		no = { "My knee says sunshine. Knee fight.", "Not a cloud for days. You'll see." },
		more = { "I'll bring a brolly and look very smug." },
		back = { "We'll see whose knee is right." },
	},
	{
		about = "the best kind of bread",
		open = { "Crusty bread is the only bread. Fight me." },
		yes = { "The crunchier the better.", "A good crust is half the meal." },
		no = { "Soft rolls. Every time. I'm not a crocodile.", "I like bread that doesn't hurt." },
		more = { "Let's ask the baker for extra crust." },
		back = { "Your teeth are lazy. I said it." },
	},
	{
		about = "the moon following people home",
		open = { "Have you noticed the moon follows me home?" },
		yes = { "It follows me too. It's very nosy.", "I've noticed. I walk faster now." },
		no = { "It follows everyone. You're not special.", "That's just how the moon works." },
		more = { "I wave at it now. To be polite." },
		back = { "It waved back once. I'm sure it did." },
	},
	{
		about = "the perfect length for a nap",
		open = { "Twenty minutes. That's the perfect nap.", "I've worked it out. The perfect nap is twenty minutes." },
		yes = { "Any longer and you wake up in a different year.", "Twenty, and a biscuit after." },
		no = { "Two hours or don't bother.", "Twenty minutes is a blink. Go big." },
		more = { "I'm going to have one right after this." },
		back = { "Two hours? You'd miss lunch." },
	},
	{
		about = "whoever keeps putting buttons in the fountain",
		open = { "Someone's been throwing buttons in the fountain instead of coins." },
		yes = { "I saw. A whole cardigan's worth.", "Shiny ones too. Somebody's coat is very draughty." },
		no = { "Buttons are cheaper. That's just good sense.", "Maybe the fountain likes buttons." },
		more = { "I'm going to find out who. I'll check everyone's coats." },
		back = { "Wishes don't come true on buttons. Everyone knows." },
	},
	{
		about = "whether fish sleep",
		open = { "Do fish sleep? With their eyes open? That's spooky." },
		yes = { "So spooky. I'm not going near the pond tonight.", "They're watching. Even asleep." },
		no = { "They sleep fine. You'd sleep fine too if you were a fish.", "They have little fish dreams. It's sweet." },
		more = { "I'll knock before I walk past the pond." },
		back = { "What would a fish even dream about? Puddles?" },
	},
	{
		about = "which season is best",
		open = { "Autumn is the best season. Crunchy leaves. Soup." },
		yes = { "Crunchy everything. Yes.", "And big jumpers. Autumn wins." },
		no = { "Summer. You can't swim in autumn. Well, you can. Once.", "Spring. Everything's waking up. Like me, slowly." },
		more = { "I'm already planning which leaves to jump in." },
		back = { "You'll come round. Everyone loves soup." },
	},
	{
		about = "what the market should sell next",
		open = { "The market needs a stall that only sells spoons." },
		yes = { "Big spoons, little spoons, a spoon for every mood.", "I'd buy a spoon. I'd buy five." },
		no = { "Who needs that many spoons?", "It needs a stall for naps. Hear me out." },
		more = { "I'll run it. Spoon Corner." },
		back = { "Everyone. Everyone needs that many spoons." },
	},
	{
		about = "whether ghosts get cold",
		open = { "Do ghosts get cold? They don't wear coats." },
		yes = { "That's why they moan. Cold ears.", "Somebody should knit them something." },
		no = { "They're see-through. The wind goes right through them.", "Ghosts are made of cold. They're used to it." },
		more = { "I'm leaving a scarf on the gate tonight. Just in case." },
		back = { "Then why do they always hang about by the fire?" },
	},
	{
		about = "whose handwriting is worse",
		open = { "My handwriting's so bad I can't read my own shopping list." },
		yes = { "Mine said eggs and I came home with a hat.", "Same. I've started drawing pictures." },
		no = { "Mine's lovely. Everyone says so. Well, I say so.", "Write slower. That's all it is." },
		more = { "Let's swap lists and see who comes home with what." },
		back = { "I wrote that list in a hurry. On a bus. In a storm." },
	},
	{
		about = "cheese with apple pie",
		open = { "Cheese with apple pie. Have you tried it?" },
		yes = { "It's the best secret in the world.", "A slice of each. I do it every Sunday." },
		no = { "Cheese should stay away from pudding.", "That sounds like a dare, not a dessert." },
		more = { "I'll bring some round. You'll see." },
		back = { "Don't knock it till you've tried it." },
	},
	{
		about = "what pet they'd be",
		open = { "If I were a pet I'd be a cat. Napping, judging people." },
		yes = { "You'd be a great cat. You already judge people.", "You'd sit on everyone's newspaper." },
		no = { "You'd be a dog. You get excited about the post.", "You'd be a goldfish. A happy one." },
		more = { "I'd want a sunny windowsill. That's all." },
		back = { "I do not get excited about the post. Much." },
	},
	{
		about = "what's on the little islet out at sea",
		open = { "I bet there's treasure on that little islet out there." },
		yes = { "Or a very lonely crab king.", "I've always wanted to row out and look." },
		no = { "There's rocks. And one bird. I've been.", "It's just a big rock with ideas." },
		more = { "We should go. Bring sandwiches." },
		back = { "You didn't dig, though. Did you?" },
	},
	{
		about = "a cloud shaped like a teapot",
		open = { "There was a cloud shaped like a teapot this morning." },
		yes = { "I saw it. The spout fell off at lunch.", "And one like a biscuit next to it. Lovely." },
		no = { "That was a duck. Clearly a duck.", "Every cloud looks like a teapot to you." },
		more = { "I took it as a sign. I had two cups." },
		back = { "A duck doesn't have a lid." },
	},
	{
		about = "singing in the bath",
		open = { "I sing in the bath. Loudly. The neighbours have opinions." },
		yes = { "The bath has the best echo in the house.", "Me too. I do all the high notes." },
		no = { "I heard you. Through two walls.", "The bath is for thinking. Quietly." },
		more = { "I'm learning a new one. With a key change." },
		back = { "Thinking is overrated. Singing is free." },
	},
	{
		about = "borrowed umbrellas",
		open = { "Every umbrella I own was borrowed from somebody." },
		yes = { "Umbrellas belong to the town. Like the weather.", "They go round and round. It's fair." },
		no = { "That's how you lose friends. And umbrellas.", "One of those might be mine, actually." },
		more = { "I'll give one back. One day. When it's sunny." },
		back = { "Which one? The spotty one? That's mine now." },
	},
	{
		about = "whether toast is just warm bread",
		open = { "Toast is just bread that's been through something." },
		yes = { "It's had an adventure. You can tell.", "Bread with a story." },
		no = { "Toast is its own thing. It has a crunch.", "Toast is a meal. Bread is a start." },
		more = { "I'm going to look at toast differently now." },
		back = { "Bread doesn't crunch. That's my point." },
	},
	{
		about = "getting up for the sunrise",
		open = { "I got up at six to watch the sunrise. Never again." },
		yes = { "Sunrises happen every day. They can wait.", "The sunset's the same, but later. Much better." },
		no = { "It's the best bit of the day. Before anyone talks.", "Six is late. I'm up at five." },
		more = { "I saw it, though. It was pink. Worth it, nearly." },
		back = { "Five? On purpose? Are you all right?" },
	},
	{
		about = "the smell of the bakery",
		open = { "The bakery smells so good in the morning I walk past it twice." },
		yes = { "Three times. I pretend I'm lost.", "I stand downwind on purpose." },
		no = { "I can't walk past at all. I just go in.", "Twice? I live in there, basically." },
		more = { "Tomorrow I'm going in. No more walking past." },
		back = { "That's why you're always covered in flour." },
	},
	{
		about = "a secret talent",
		open = { "I can touch my nose with my tongue. Nobody believes me." },
		yes = { "I believe you. Please don't show me.", "I can wiggle my ears. We're both gifted." },
		no = { "Prove it. No. Wait. Don't.", "Nobody can do that." },
		more = { "It's not useful. But it's mine." },
		back = { "One day I'll show you. When you least expect it." },
	},
	{
		about = "the clock by the town hall",
		open = { "The clock by the hall is two minutes fast. It makes me feel ahead of things." },
		yes = { "I set my watch by it. I'm always a bit early.", "Two minutes of free time a day. Lovely." },
		no = { "It's slow, actually. I've been late all week.", "Somebody should fix it. Not me." },
		more = { "Don't tell anyone. I like it." },
		back = { "Then we've both been wrong. Very on time of us." },
	},
	{
		about = "their one tomato",
		open = { "My tomato plant has one tomato. I'm very proud of it." },
		yes = { "One good tomato beats ten bad ones.", "Has it got a name yet?" },
		no = { "One? That's a lot of watering for one.", "My plant has nine. Not that I'm counting." },
		more = { "I'm going to eat it in a sandwich. Slowly." },
		back = { "Quality, not quantity." },
	},
	{
		about = "learning to whistle",
		open = { "I've been learning to whistle for a week. Listen. Fffff." },
		yes = { "That was nearly a note.", "Keep going. The birds are worried, though." },
		no = { "That's just breathing loudly.", "Purse your lips more. Like a sad fish." },
		more = { "By winter I'll be whistling tunes." },
		back = { "Sad fish. Fine. Fffff. Fwee!" },
	},
	{
		about = "the comfy bench by the fountain",
		open = { "The bench by the fountain is the comfiest in town." },
		yes = { "It's got a dip right where you sit.", "I've fallen asleep on it twice." },
		no = { "The one by the gate is better. More shade.", "Benches aren't comfy. They're benches." },
		more = { "I might move my whole day there." },
		back = { "You've never sat on it properly, then." },
	},
	{
		about = "counting stars",
		open = { "I counted the stars last night. Got to forty and fell asleep." },
		yes = { "I get to about thirty. Then I start again.", "Forty's good. Forty's a lot." },
		no = { "There's millions. You were never going to win.", "Why count them? Just look at them." },
		more = { "Tonight I'm starting from the other side." },
		back = { "Somebody has to keep track." },
	},
	{
		about = "a quiet but impressive hobby",
		open = { "I want a hobby that's quiet but impressive." },
		yes = { "Knitting very small hats.", "Card towers. Hold your breath and build." },
		no = { "Quiet and impressive don't go together. Try drums.", "Just be impressive at napping." },
		more = { "Small hats. For mice. I'm doing it." },
		back = { "Drums? My neighbours would move out." },
	},
	{
		about = "the right way to make tea",
		open = { "Milk first, then tea. That's the rule." },
		yes = { "Good. Someone sensible.", "My gran did it that way. So it's the law." },
		no = { "Tea first. Always. I'll argue about this all day.", "Milk first is how you upset a teapot." },
		more = { "Let's have one now. The proper way." },
		back = { "We can never live together. That's fine." },
	},
	{
		about = "a strange noise at night",
		open = { "There's a noise at night. Like a tiny trumpet." },
		yes = { "I've heard it too. Toot. Toot.", "It's the pipes. Or a very small band." },
		no = { "That's your snoring.", "That's the wind in the gutter. It does a tune." },
		more = { "I'm going to stay up and catch it." },
		back = { "I do not snore. I hum. In my sleep." },
	},
	{
		about = "what's at the end of a rainbow",
		open = { "If you got to the end of a rainbow, what would you hope was there?" },
		yes = { "Cake. Lots of cake.", "A bench and a view. That's all I need." },
		no = { "A puddle. It's always a puddle.", "More rainbow, probably." },
		more = { "I'd share the cake. Probably. Some of it." },
		back = { "Where's your sense of wonder?" },
	},
	{
		about = "the town's name",
		open = { "Maplewick is a funny name. Where's the maple? Where's the wick?" },
		yes = { "I've looked everywhere. No wick.", "There's one maple. By the hall. Maybe." },
		no = { "It's a lovely name. Don't you start.", "The wick's the little bit you don't see." },
		more = { "I'm going to plant a maple. Just to be sure." },
		back = { "Okay, but where IS it?" },
	},
	{
		about = "ice cream in winter",
		open = { "Ice cream tastes better in winter. It doesn't melt." },
		yes = { "No drips. Perfect science.", "And you don't have to queue." },
		no = { "Cold food in cold weather? No thanks.", "Winter is for soup. I've said it before." },
		more = { "I'm having one in the snow this year." },
		back = { "Soup and ice cream. Hot and cold. Live a little." },
	},
	{
		about = "tidying up",
		open = { "I tidied my whole room and now I can't find anything." },
		yes = { "A tidy room is a mystery room.", "I keep my mess where I can see it." },
		no = { "Put things back where you got them. Easy.", "Labels. Everything needs a label." },
		more = { "I found a sock from last spring, though." },
		back = { "I'd need a label for the labels." },
	},
	{
		about = "getting a fringe",
		open = { "I'm thinking of getting a fringe." },
		yes = { "Do it. Be brave.", "A fringe would suit you. Probably." },
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
		open = { "I called someone the wrong name for a whole week and they never said." },
		yes = { "Now you have to keep going. Forever.", "That's happened to me. I answered to Gary." },
		no = { "You have to tell them. Today.", "They probably called you the wrong name back." },
		more = { "I'm in too deep now." },
		back = { "Too late. They've started signing their letters that way." },
	},
	{
		about = "the best spot on the beach",
		open = { "The best spot on the beach is right by the big rock." },
		yes = { "Shade in the morning, sun after lunch.", "And the crabs leave you alone there." },
		no = { "Down by the pier. You can watch the boats.", "Anywhere without sand. Which is nowhere." },
		more = { "I'm putting my towel there first thing tomorrow." },
		back = { "The boats are fine. The rock is better." },
	},
	{
		about = "the bus being early",
		open = { "The bus came early today. Early. I don't trust it." },
		yes = { "Something's going on. Keep an eye on it.", "An early bus is a bus with a plan." },
		no = { "Maybe the driver just had a good morning.", "Be grateful. Get on the bus." },
		more = { "I'm going to wait at the stop tomorrow and watch." },
		back = { "Nobody has that good a morning." },
	},
	{
		about = "jam on scones",
		open = { "Jam first, then cream. Anything else is chaos." },
		yes = { "Chaos. You said it.", "That's how it's done round here." },
		no = { "Cream first. The jam sits on top like a hat.", "I just eat the jam with a spoon." },
		more = { "Let's settle it at the café. With scones." },
		back = { "A hat? A jam hat? That's ridiculous. I love it." },
	},
	{
		about = "a song neither of them can remember",
		open = { "There's a song stuck in my head and I only know one line. Dum dum, da da dum." },
		yes = { "Oh, I know it. No I don't. Dum dum.", "Now it's in my head too. Thanks." },
		no = { "That's the bin lorry's reversing beep.", "That's not a song. That's a sneeze." },
		more = { "We'll be humming it all day now." },
		back = { "It is a song. It goes somewhere. I just don't know where." },
	},
	{
		about = "talking to plants",
		open = { "I talk to my plants. They're better listeners than most people." },
		yes = { "Mine grew a whole leaf after I told it a joke.", "They never interrupt. Very polite." },
		no = { "Plants want water, not chat.", "My cactus doesn't like my stories." },
		more = { "Today I told the fern about my week." },
		back = { "Your cactus just needs better stories." },
	},
	{
		about = "whether hats count as furniture for your head",
		open = { "A hat is just a little roof for your head." },
		yes = { "With a porch, if it's got a brim.", "That's why I feel safe in a hat." },
		no = { "A roof doesn't blow off in the wind. Usually.", "A hat is a hat. Don't make it weird." },
		more = { "I'm going to get one with a chimney." },
		back = { "Mine stays on. I've got a chin strap." },
	},
}

-- Dreams they tell each other. Each finishes "I dreamed ..."
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
	"I was the mayor of a town of ducks",
	"it snowed sugar and I ate the garden",
	"my bed floated out to sea and I waved at a whale",
	"I had to sit an exam on spoons",
	"the moon came down for tea and ate all the biscuits",
	"I was tiny and a snail gave me a lift",
	"everyone spoke in songs and I only knew one",
	"my shoes walked off without me",
	"the bakery was a castle and the baker was a dragon, a nice one",
	"I found a door in my wardrobe that led to the beach",
	"I could fly, but only about a foot off the ground",
}

-- Little things worth disagreeing about, loudly, for a minute.
Chatter.Debates = {
	{ q = "Is a cloud wet?", yes = "Of course it's wet. It's made of rain.", no = "You can't get wet from a cloud. I've walked through fog." },
	{ q = "Do fish get thirsty?", yes = "Everything gets thirsty. Even fish.", no = "They live in a drink. They're fine." },
	{ q = "Is a muffin just a cake with no confidence?", yes = "Exactly. A shy little cake.", no = "A muffin is breakfast. A cake is a party." },
	{ q = "Is cereal soup?", yes = "Bits in a bowl of liquid. Soup.", no = "Soup is hot. Cereal is breakfast. Done." },
	{ q = "Which came first, the egg or the omelette?", yes = "The egg. You need an egg to make an omelette.", no = "The omelette. Nobody wants an egg on its own." },
	{ q = "Is a beanbag a chair?", yes = "You sit on it. Chair.", no = "It's a bag. Of beans. That's in the name." },
	{ q = "Are crabs walking sideways or forwards to the side?", yes = "Sideways. Look at them.", no = "Forwards. They just face the wrong way." },
	{ q = "Is it rude to wave at a boat?", yes = "You don't know them. Rude.", no = "Waving at boats is the law of the sea." },
	{ q = "Can you be friends with a pigeon?", yes = "Course you can. I've got three.", no = "A pigeon is only your friend while you've got bread." },
	{ q = "Is a jacket potato a dinner or a side?", yes = "Big enough to be dinner. With beans, it's a feast.", no = "It's a side. A potato can't carry a whole meal." },
	{ q = "Should socks match?", yes = "Matching socks are a sign of a tidy mind.", no = "Odd socks are more fun. And easier." },
	{ q = "Is the sea just a very big puddle?", yes = "Same thing. Just bigger and saltier.", no = "Puddles don't have whales in them." },
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
}

-- Openers by the hour and the weather ({b} is who they're talking to).
local function opener(ctx: any): string
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
		table.insert(list, "Still out and about, {b}?")
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
	return ctx.rng:pick(list)
end

-- How they say hello back, by how well they get on.
local function greet(ctx: any, s: any, score: number)
	if score <= -10 then
		s:pick("b", { "Oh. It's you.", "What now?", "Mm. Hello." }, "anger")
	elseif score >= 40 then
		s:pick("b", { "There you are. I was hoping I'd see you.", "Oh good, it's you.", "My favourite person." }, "heart")
	else
		s:voice("b", "hello")
	end
end

-- Does the second one agree? Kind and shy ones lean yes, proud and bold ones like to argue, and
-- friends agree more than people who don't get on.
function Chatter.agrees(ctx: any, a: string, b: string): boolean
	local score = ctx.rel(a, b)
	local p = 0.6
	if score >= 30 then
		p += 0.15
	elseif score <= -10 then
		p -= 0.25
	end
	local pers = K.pers(ctx, b)
	if pers == "proud" or pers == "bold" then
		p -= 0.15
	elseif pers == "gentle" or pers == "shy" or pers == "sunny" then
		p += 0.1
	end
	return ctx.rng:chance(math.clamp(p, 0.15, 0.9))
end

-- A whole chat onto scene `s` between stars a and b. Returns the topic, whether they agreed,
-- and how much it did for their friendship.
function Chatter.chat(ctx: any, s: any, a: string, b: string, topic: any?): (any, boolean, number)
	local t = topic or ctx.rng:pick(Chatter.Topics)
	local score = ctx.rel(a, b)
	s:say("a", opener(ctx), nil, "wave")
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
		if K.isPers(ctx, b, "cheeky") and score >= 20 then
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

-- A passing word in the street (Services/Villagers' chats between neighbours): two or four
-- lines, who says each ("a" or "b") and what. No scene, no player: just the bubbles.
function Chatter.small(ctx: any, a: string, b: string): { { who: string, text: string } }
	local t = ctx.rng:pick(Chatter.Topics)
	local yes = Chatter.agrees(ctx, a, b)
	local out = {
		{ who = "a", text = ctx.rng:pick(t.open) },
		{ who = "b", text = ctx.rng:pick(if yes then t.yes else t.no) },
	}
	if ctx.rng:chance(0.6) then
		table.insert(out, { who = "a", text = ctx.rng:pick(if yes then t.more else t.back) })
		table.insert(out, { who = "b", text = K.voiceText(ctx, b, if yes then "laugh" else "hmm") })
	end
	return out
end

return Chatter
