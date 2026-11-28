--!nonstrict
-- A villager comes to you with something small, and the answer matters a little: which outfit,
-- whether to tell a friend the truth, what to give somebody, a motto, a hobby, what to cook, who
-- to take to the dance, whether to say sorry first; too much bread, a shell off the beach, a
-- colour for the front door, company on the pier at night, a stool they made, a neighbour's late
-- music, lights on the islet, nerves before a big day, a soup to taste, a letter to their grandma, a
-- drooping plant, a rainy day, a night they can't sleep, a name they've forgotten, a secret spot,
-- a silly hat, a question they want to practise, a bet on the weather, a knock at six, a wave you
-- missed, the room you built them. What you pick can make a friend, a sulk, a new saying.
--
-- And the chats that are only a chat: a message meant for somebody else, the worry the morning
-- after a late chat that they said something odd, a picture they want you to see, an invite for
-- tomorrow, sorry for yesterday, guess what's in my pocket, a long day let out and taken back, a
-- part in their story, a favour, a small win, a question about you, a nag about your sleep, this
-- or that, a roll from the bakery, a walk home in the dark, something left outside your door. (One
-- villager's own phone moments, a list sent to the wrong person, a name with no reply, home safe,
-- are in Data/Events/Solo.)
--
-- They come to you the way a friend texts (the user handed over a messaging app's chats; we take
-- how people text, never the lines): they open with your name, explain in one to three messages
-- and ask; you get two short answers, often the same move said two ways or one plain and one a
-- joke; they take it in another burst and end on the plan or a thanks. A message is one whole,
-- natural sentence, two only when they belong together (the user: "Try to avoid having strings of
-- short sentences, and redo the contents of sentences, some of them are too unnatural for people
-- to say or dont make sense"), and each personality's habits show now and then: Sunny's "Ehehe",
-- Bold's "right?", Cheeky's lower case, Polite's "if it's no trouble", Nervous's stammer. Your
-- name is {player}.

local K = require(script.Parent.Kit)
local Chatter = require(script.Parent.Chatter)
local Sayings = require(script.Parent.Parent.Sayings)
local Foods = require(script.Parent.Parent.Foods)

local W = K.W
local burst = Chatter.burst
local say = Chatter.say

local list = {}
local function event(def)
	def.actors = def.actors or 1
	table.insert(list, def)
end

local function upper(s: string): string
	return s:sub(1, 1):upper() .. s:sub(2)
end

event({
	id = "outfit",
	when = "day",
	weight = W({ base = 0.18 }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "Hat or scarf")
		burst(s, "a", {
			sunny = "{player}, I need a second opinion, quick!|Should I wear the yellow hat or the stripy scarf?|I've changed four times already, so you get to pick.",
			gentle = "{player}, sorry to bother you with something silly.|Would the yellow hat or the stripy scarf look nicer today?|Take your time, okay?",
			bold = "{player}, I'm out the door in five minutes.|It's the yellow hat or the stripy scarf, and you're deciding.|You've got an opinion on hats, right?",
			dreamy = "{player}, I've been standing at the mirror for a while now.|The yellow hat is like a little sun, and the scarf is like a blanket...|Which one should I wear?",
			easygoing = "Quick question, no rush.|Yellow hat or stripy scarf?|I was going to wear both, but apparently that's too much.",
			proud = "{player}, I have an important question for you.|The yellow hat and the stripy scarf both suit me, naturally.|I just need to know which one suits me more.",
			shy = "Um, {player}, do you have a second?|I can't choose between the yellow hat and the stripy scarf.|Sorry, it's a silly thing to ask you.",
			cheeky = "ok {player}, you're voting on something|yellow hat or stripy scarf?|whichever one loses goes on the scarecrow in my garden hehe",
			cool = "{player}.|Yellow hat or stripy scarf, which one?|I'm going out in ten minutes.",
			prickly = "{player}, don't laugh at this.|Does the yellow hat or the stripy scarf look better on me?|Just pick one, I'm already late.",
			dramatic = "{player}, my whole afternoon depends on your answer.|The yellow hat, or the stripy scarf?|Choose wisely, because the entire square is going to SEE it.",
			bookish = "{player}, I made a list of points for the yellow hat and the stripy scarf.|Actually, it came out exactly even, which I didn't expect.|Could you break the tie for me?",
			gloomy = "Which looks less bad on me, the yellow hat or the stripy scarf?|Heh... I've tried them both so many times that I can't tell any more.",
			polite = "Hello, {player}, and forgive me for the silly question.|Would you choose the yellow hat or the stripy scarf for a walk into town?",
			foodie = "I'm meeting a friend for lunch and I can't decide what to wear.|Yellow hat or stripy scarf?|Whichever one hides crumbs better, really.",
			nervous = "{player}, s-sorry, can I ask you something quickly?|Should I wear the yellow hat or the stripy scarf?|What if I pick the wrong one and the whole square stares at me?",
			_ = "Can you help me before I head out?|Should I wear the yellow hat or the stripy scarf?",
		}, "question", "wave")
		s:choice("Go with the yellow hat.", function(c)
			burst(c, "a", {
				shy = "Okay, I'll wear the hat...|It feels a bit brave for me, but I'll try.|Thank you for choosing.",
				proud = "Hmph, I was leaning towards the hat anyway.|Everyone in the square is going to stop and look, you'll see.",
				easygoing = "Mm, the hat it is.|Now I can go back to my nap, no rush.",
				cool = "The hat, then.|Thanks for the help.",
				nervous = "Are you sure about the hat?|Okay, okay, I'll wear the hat.|Thank you, I feel much better now.",
				dramatic = "The hat is a bold choice, and the right one!|I'm going to make an entrance the square won't forget.",
				cheeky = "hat it is|sorry scarf, it's scarecrow time for you",
				gloomy = "The hat... it'll blow off in the wind, as usual.|...Fine, I'll wear it anyway.",
				sunny = "The hat! Ehehe, I knew you'd pick that one.|Okay, I'm off, see you later.",
				gentle = "The hat, then, it does look cheerful.|Thank you, and take care of yourself today.",
				bold = "Hah, the hat, good call.|You're walking me to the square in it, then, right?",
				dreamy = "Hmm, the hat...|It's the same yellow as my butter dish, I only just noticed.",
				prickly = "Ugh, the hat, fine.|I was leaning that way anyway, so don't read into it.",
				bookish = "The hat, then.|Actually, yellow is the easiest colour to spot from far away, so it's practical too.",
				polite = "The yellow hat it is, thank you kindly.|Have a lovely day, {player}.",
				foodie = "The hat, then, yellow like a lemon tart.|Mmm, now I want a lemon tart, so I'm off to lunch.",
				_ = "The hat it is, then.|Thanks, you've saved me ten more minutes at the mirror.",
			}, "sparkle", "cheer")
			c:mood("a", 4)
			-- and they put it on, for real, and keep it on (Sim/Memory); later they may ask whether
			-- it really suits them
			c:wear("a", "yellowhat")
			c:follow("suitme", { chance = 0.5, hours = 8, words = { worn = "yellowhat" } })
		end)
		s:choice("The stripy scarf, definitely.", function(c)
			burst(c, "a", {
				bold = "Scarf it is, and I'm out the door.|...Thanks. Anyway, see you later.",
				dreamy = "Hmm... the scarf, then.|Wearing it feels like being wrapped up in a blanket.",
				gloomy = "Good, the scarf.|It'll turn cold later anyway, it always does.",
				foodie = "The scarf, then.|It's got folds, and folds are perfect for hiding a cookie or two.",
				prickly = "Fine, the scarf.|Don't read into the fact that I asked you, okay?|...But thanks.",
				cheeky = "scarf it is|guess the hat's going on the scarecrow then hehe",
				polite = "The scarf it is, and thank you kindly, {player}.|Have a lovely day.",
				shy = "The scarf, okay...|Thank you, I feel less nervous about going out now.",
				nervous = "The scarf, okay, the scarf.|It can't blow away like a hat could, so that's good.",
				dramatic = "The scarf, of course, it's so much more mysterious.|Everyone in the square will wonder where I'm off to.",
				sunny = "The scarf! Ehehe, the stripes are my favourite part.|Let's walk to the square together and show it off.",
				gentle = "The scarf, then, it's nice and warm.|Thank you, and wrap up warm yourself, okay?",
				easygoing = "*yawn* The scarf, sure.|It's soft enough to nap in later, so that's a win.",
				proud = "Hmph, the scarf, naturally.|It does suit me rather well, doesn't it?",
				cool = "The scarf, then.|Take your coat too, it's getting cold.",
				bookish = "The scarf, good.|Did you know it has four colours in the stripes? I counted them this morning.",
				_ = "The scarf, good call.|It's colder out than it looks today.",
			}, "heart")
			c:mood("a", 4)
			c:wear("a", "scarf")
			c:follow("suitme", { chance = 0.5, hours = 8, words = { worn = "scarf" } })
		end)
		s:choice("Why not try a whole new look?", function(c)
			burst(c, "a", {
				nervous = "A whole new look, right now?|O-okay, but will you stay while I choose?|Is that okay?",
				prickly = "Ugh, fine, something new.|You're helping me pick, though, since it was your idea.",
				sunny = "A whole new look? Yes, yes, let's do it!|Come on, you have to help me pick everything.",
				cool = "Hm.|Okay, let's see what else I've got.",
				gloomy = "A whole new look... it'll still be me underneath, heh.|Come and help me try things on, anyway.",
				shy = "A whole new look? Um, okay...|Could you come and help me choose? I'd feel braver.",
				bold = "Hah, a whole new look, why not?|Come round, and we'll sort it out right now.",
				cheeky = "new look? ok, but you're picking|and no laughing at the first one",
				gentle = "Oh my, a whole new look?|Come and help me, okay? I'll make us some tea first.",
				dreamy = "A new look... hmm, like starting a new page.|La la ♪, come and help me find something that sparkles.",
				easygoing = "A whole new look? That sounds like a lot of work...|Eh, it's fine, come over and we'll take it slow.",
				proud = "A new look? Hmph, even I can get better, I suppose.|Come and watch, you'll want to see this.",
				dramatic = "A whole NEW me?|*gasp* Yes, come over right now, this is a big day.",
				bookish = "A new look, hmm.|Actually, I have three outfits I've never worn, so let's start there.",
				polite = "A new look? What a lovely idea.|Would you come and help me choose, if it's no trouble?",
				foodie = "A new look? Ooh, okay.|Come over and help, and I'll make us sandwiches while we pick.",
				_ = "Ooh, a whole new look?|Come over and help me pick, then.",
			}, "sparkle", "cheer")
			c:fx({ t = "creator", who = "a" })
			c:mood("a", 3)
		end)
		s:log("{a} asked which outfit to wear.")
		return s:done()
	end,
})

event({
	id = "truth",
	actors = 2,
	when = "day",
	weight = W({ base = 0.15, rel = 15 }),
	scene = function(ctx, a, b)
		local s = K.scene(ctx, "An honest answer")
		burst(s, "a", {
			polite = "{player}, may I ask your advice on something a little awkward?|{b} has been bringing me dinner every evening, which is very kind of them.|The trouble is that it's always far too salty, and I don't know whether to say so.",
			prickly = "{player}, I've got an awkward question, and I don't want a lecture.|{b} keeps cooking for me, and it's so salty I can barely swallow it.|I've eaten every bite so far, so should I say something?",
			nervous = "{player}, s-sorry, can I ask you something awkward?|{b} keeps cooking for me, and it's always really, really salty.|What if they ask me straight out whether I liked it?",
			foodie = "I need to ask you as someone who takes food seriously.|{b} keeps cooking dinner for me, and the soup tastes like seawater.|Do I tell them, or do I keep smiling?",
			gentle = "{player}, could I ask for some advice?|{b} keeps bringing me dinner, which is so sweet of them.|Oh, my, it's just very, very salty, and I don't know whether to tell them.",
			shy = "Um, {player}, can I ask you something?|{b} keeps bringing me dinner, and it's... very salty.|I don't want to hurt their feelings, so I haven't said anything.",
			cheeky = "{player} i need advice and you're not allowed to laugh|{b} keeps cooking me dinner and it tastes like they cooked it in the sea|do i tell them or keep feeding it to the gulls",
			cool = "{player}.|{b} keeps cooking for me, and it's far too salty.|Should I tell them?",
			bold = "I'll be straight with you.|{b}'s cooking is so salty I need a jug of water with it, and they keep making more.|I should tell them, right?",
			dreamy = "{player}, can I ask you something?|{b} keeps bringing me dinner, and it all tastes a bit like the sea...|I think they use far too much salt, but I don't know how to say so.",
			sunny = "I need your advice about something.|{b} keeps cooking for me, which is so nice of them, but the food is really salty.|Should I say something?",
			easygoing = "{player}, got a minute? No rush.|{b}'s been bringing me dinner every night, which is great, except it's always far too salty.|Should I say something, or just keep eating it?",
			proud = "{player}, I need a word about something delicate.|{b} keeps cooking dinner for me, and it's far too salty, which I'd never do myself.|Should I tell them, or is that too much?",
			dramatic = "{player}, I have a TERRIBLE problem.|{b} keeps cooking for me, and every dinner tastes like the whole sea.|Do I tell them and break their heart?",
			bookish = "{player}, can I ask your advice?|{b} keeps bringing me dinner, and I think they use about four times the salt a recipe needs.|Should I tell them, or would that be rude?",
			gloomy = "{player}, I've got a problem, as usual.|{b} keeps cooking for me, and it's always far too salty.|Heh... if I tell them, they'll probably never cook for me again.",
			_ = "I've got an awkward question for you.|{b} keeps cooking dinner for me, and it's always far too salty.|Should I tell them the truth?",
		}, "sweat")
		s:choice("Tell them, but kindly.", function(c)
			burst(c, "a", {
				prickly = "{b}, thanks for all the dinners, I mean it.|But please use less salt next time.|...A lot less.",
				cool = "{b}, thanks for cooking for me.|It's too salty, though, so try half as much next time.",
				shy = "Um, {b}, I really love that you cook for me...|Could you maybe use a little less salt next time?",
				nervous = "{b}, I-I really love that you cook for me.|Could you maybe go easier on the salt next time? Is that okay?",
				sunny = "{b}, I love that you cook for me, I really do!|Could you use a little less salt next time? Let's cook it together!",
				gentle = "{b}, thank you for all those dinners, they mean a lot.|Could you use a little less salt next time, okay?",
				bold = "{b}, your dinners are great, but there's too much salt in them.|Half as much next time, right?",
				dreamy = "{b}, your dinners are so kind of you...|They just taste a little like the sea, so maybe less salt?",
				easygoing = "Hey, {b}, thanks for all the dinners.|No rush, but maybe go a bit easier on the salt next time?",
				proud = "{b}, your cooking is very nearly perfect.|With a little less salt, it would be as good as mine.",
				cheeky = "{b} i love your dinners|but i think the whole salt jar fell in again :P",
				dramatic = "{b}, your dinners are a GIFT, truly.|But the salt, {b}, the salt is too much.",
				bookish = "{b}, thank you for cooking for me.|Actually, most recipes only need a pinch of salt, so maybe try half as much?",
				gloomy = "{b}, thanks for the dinners, really.|They're a bit salty, though... sorry, I'm bad at saying this.",
				polite = "{b}, thank you kindly for all the dinners.|If it's no trouble, could you use a little less salt next time?",
				foodie = "{b}, your dinners smell amazing.|Mmm, go easy on the salt and they'll taste as good as they smell.",
				_ = "{b}, I really love that you cook for me.|Could you maybe go easier on the salt next time?|...A lot easier, actually.",
			}, "sweat")
			if K.isPers(ctx, b, "proud", "bold", "prickly", "dramatic") then
				burst(c, "b", {
					proud = "Less salt? My cooking is perfectly fine.|...How much less are we talking about?",
					prickly = "Ugh, fine, less salt.|Don't read anything into me listening to you.",
					dramatic = "*gasp* You're insulting my cooking to my FACE?|...Fine, show me how much salt you'd use.",
					bold = "Too salty? Hah, fine, you're right.|I'll taste it first next time, deal?",
					_ = "What, seriously?|...Fine, I'll taste it before I bring it round next time.",
				}, "anger")
				c:rel(2)
			else
				burst(c, "b", {
					shy = "Oh no, I've been doing it wrong this whole time...|Thank you for telling me, really.",
					cheeky = "ok i knew it was bad|i was waiting to see how long you'd keep eating it hehe",
					gloomy = "Heh... I knew it was bad, as usual.|Thanks for eating it all anyway.",
					polite = "Thank you for being honest with me.|Would you show me how you'd make it, if it's no trouble?",
					nervous = "Was it all bad, every single night?|Oh no, oh no, will you cook with me next time so I get it right?",
					sunny = "Too salty? Oh no, ehehe, sorry!|Let's cook together next time, then.",
					gentle = "Oh my, I'm so sorry, I had no idea.|Thank you for telling me so kindly.",
					dreamy = "Oh... I did wonder why everyone drank so much water.|Thank you for telling me.",
					easygoing = "Ah, too much salt, huh.|Eh, it's fine, I'll just use less, thanks for saying.",
					cool = "Too salty, noted.|I'll use half as much next time.",
					bookish = "Oh, I measured it by eye instead of with a spoon.|Thank you, I'll follow the recipe properly next time.",
					foodie = "Too salty? Oh no, that's every cook's worst fear.|Thank you for telling me, really, so come and taste the next pot.",
					_ = "Thank you for being honest with me.|Will you come and cook with me next time?",
				}, "heart")
				c:rel(8)
			end
		end)
		s:choice("Just keep eating it.", function(c)
			burst(c, "a", {
				gloomy = "Fine, I'll keep eating it.|Heh... I suppose that's what I get for having friends who cook.",
				cheeky = "fine, i'll keep eating it|the gulls are getting a very salty dinner tonight though",
				bold = "Fine, I'll eat it.|I ate worse than that on a fishing boat once.",
				gentle = "All right, I'll keep eating it.|They're trying so hard, and I don't have the heart to say anything.",
				nervous = "O-okay, I'll keep eating it.|What if they ask me to finish the whole pot, though?",
				shy = "Okay, I'll keep eating it...|I'll just drink a lot of water afterwards.",
				sunny = "Okay, I'll keep eating it!|Ehehe, I'll keep a big jug of water by my plate.",
				dreamy = "Okay, I'll keep eating it...|Hmm, the sea is salty and people love the sea, so maybe it's fine.",
				easygoing = "Sure, I'll keep eating it.|Eh, it's fine, a bit of extra salt never hurt anyone.",
				proud = "Very well, I'll eat it with a smile.|Nobody can say I'm not a good friend.",
				cool = "Fine, I'll keep eating it.|I'll bring a big glass of water.",
				prickly = "Ugh, fine, I'll keep eating it.|But I'm not finishing the soup, so don't ask.",
				dramatic = "Then I will suffer in silence, plate after plate.|Nobody will ever know how BRAVE I was.",
				bookish = "All right, I'll keep eating it.|I'll drink two glasses of water with each meal, just to be safe.",
				polite = "Very well, I will keep eating it.|It would be rude to refuse, after all their kindness.",
				foodie = "Fine, I'll keep eating it.|I'll bring some plain bread to soak up the salt.",
				_ = "Fine, I'll keep eating it.|I'll just have a very big glass of water ready.",
			}, "sad")
			c:mood("a", -3)
			c:rel(2)
		end)
		s:log("{a} wondered whether to tell {b} the truth about their cooking.")
		return s:done()
	end,
})

-- what a personality likes to be given
local LIKES = {
	sunny = "balloons",
	gentle = "flowers",
	bold = "dumbbells",
	dreamy = "a book of poems",
	easygoing = "a hammock",
	proud = "a mirror",
	shy = "a little plant",
	cheeky = "a joke shop kit",
	cool = "a pair of sunglasses",
	prickly = "a cactus",
	dramatic = "a velvet cushion",
	bookish = "a new notebook",
	gloomy = "a black umbrella",
	polite = "a box of writing paper",
	foodie = "a cookbook",
	nervous = "a lucky charm",
}
-- the presents you'd say "them" about, not "it"
local PLURAL = { ["flowers"] = true, ["balloons"] = true, ["dumbbells"] = true, ["a pair of sunglasses"] = true }
local GIFTS = {
	"flowers",
	"a book of poems",
	"a hammock",
	"a mirror",
	"a little plant",
	"a joke shop kit",
	"balloons",
	"dumbbells",
	"a pair of sunglasses",
	"a cactus",
	"a velvet cushion",
	"a new notebook",
	"a black umbrella",
	"a box of writing paper",
	"a cookbook",
	"a lucky charm",
}

event({
	id = "giftadvice",
	actors = 2,
	when = "day",
	weight = W({ base = 0.18, rel = 10 }),
	scene = function(ctx, a, b)
		local want = LIKES[K.pers(ctx, b)] or "flowers"
		local options = { want }
		for _, g in ctx.rng:shuffle(GIFTS) do
			if #options >= 3 then
				break
			end
			if not table.find(options, g) then
				table.insert(options, g)
			end
		end
		options = ctx.rng:shuffle(options)
		local s = K.scene(ctx, "A present for {b}")
		burst(s, "a", {
			nervous = "{player}, I want to get {b} a present, but I'm scared I'll get it wrong.|What if they open it and have to pretend to like it?|What do you think they'd want?",
			bookish = "I'm choosing a present for {b}.|I've narrowed it down to three, after reading a whole chapter on what people like to be given.|Which one do you think they'd like best?",
			sunny = "{player}, help me, help me!|I want to get {b} a present, and I've got no idea what they like.|You know them, so you choose.",
			shy = "Um, {player}, I'd like to give {b} something.|I don't know them that well yet, though.|What do you think they'd like?",
			cool = "{player}.|I'm getting {b} a present.|Any idea what they'd like?",
			foodie = "I want to get {b} a present, and I can't give everyone cake.|Well, I could, but I want this one to be special.|What would they like?",
			gentle = "I'd like to give {b} a little something.|They've seemed tired lately, and I want to cheer them up.|What do you think they'd like?",
			dreamy = "{player}, I want to give {b} something...|I keep picturing them opening it, but I can't picture what's inside.|What would they like?",
			bold = "{player}, I'm getting {b} a present today.|You know them better than I do, right?|So tell me what they'd like.",
			easygoing = "{player}, I want to get {b} a present, but thinking about it is making me sleepy.|What do you think they'd like?",
			proud = "{player}, I'm getting {b} a present, and it has to be perfect, as my presents always are.|What would they like?",
			cheeky = "{player} i'm getting {b} a present|help me pick, and if they hate it, i'm saying it was your idea hehe",
			prickly = "I'm getting {b} a present, don't ask why.|What would they like, since you know them?",
			dramatic = "{player}, I must find {b} the PERFECT present.|What would they like?",
			gloomy = "I want to get {b} a present, but I'm bad at presents.|Heh... what would they like?",
			polite = "Good afternoon, {player}, I would like to buy {b} a present.|What do you think they would like?",
			_ = "{player}, I want to get {b} something nice.|What do you think they'd like?",
		}, "question")
		for _, g in options do
			s:choice("Get them " .. g .. ".", function(c)
				c:with({ gift = g, Gift = upper(g), it = if PLURAL[g] then "them" else "it" })
				c:n("{a} gave {b} {gift}.")
				if g == want then
					burst(c, "b", {
						sunny = "{Gift}! Ehehe, how did you know?|I love {it}, I really do!",
						gentle = "Oh, my, {gift}.|That's exactly what I would have picked for myself.",
						bold = "Hah! {Gift}, now that's a present.|...Thanks. I mean it.",
						dreamy = "Hmm... {gift}.|It's like you read my mind.",
						easygoing = "Oh, {gift}, nice.|That's exactly my kind of thing, thanks.",
						proud = "{Gift}? Hmph, you have excellent taste.|Almost as good as mine.",
						shy = "{Gift}...!|Um, thank you, I really love {it}.",
						cheeky = "wait, {gift}? that's perfect|who told you, hehe",
						cool = "{Gift}.|That's exactly what I wanted, thanks.",
						prickly = "{Gift}? Ugh, how did you know?|...It's perfect. Don't tell anyone I said that.",
						dramatic = "*gasp* {Gift}!|This is the BEST present anyone has ever given me.",
						bookish = "{Gift}, how did you know?|I've been meaning to get myself one for ages.",
						gloomy = "{Gift}? For me?|Heh... that's actually perfect. I don't get many of those.",
						polite = "{Gift}, how thoughtful of you.|It's just what I wanted, thank you kindly.",
						foodie = "{Gift}! I'm cooking you dinner to say thanks for this.",
						nervous = "{Gift}, for me? R-really?|I love {it}, thank you so much!",
						_ = "{Gift}! That's exactly what I wanted.|Thank you!",
					}, "heart", "cheer")
					c:rel(14)
					c:mood("b", 8)
				else
					burst(c, "b", {
						proud = "{Gift}? How very... thoughtful of you.",
						bold = "{Gift}? Huh, I wouldn't have guessed that.|...Thanks. Anyway.",
						shy = "Oh, you got me {gift}...|Thank you, really, I'll find a good place for {it}.",
						cheeky = "{gift}? is this a prank|it feels like a prank, but thanks",
						cool = "{Gift}.|Thanks, that's kind of you.",
						prickly = "{Gift}? Hm, I'll find a use for {it} somewhere.|Don't ask me later whether I did.",
						gloomy = "{Gift}... okay, thanks.|Nobody ever knows what to get me, so don't feel bad.",
						polite = "{Gift}, how very kind of you.|Thank you kindly.",
						foodie = "{Gift}? Can I eat any of it?|No? Well, thank you anyway.",
						nervous = "Is this really for me?|I'll look after {it} very carefully, I promise.",
						gentle = "Oh, my, {gift}.|Thank you, that's very thoughtful of you.",
						sunny = "Ooh, {gift}, thank you!|I'll find somewhere good for {it}.",
						dreamy = "{Gift}...|I'll put {it} by the window, where I'll see {it} every morning.",
						easygoing = "{Gift}? Huh, okay.|Thanks, I'll find a spot for {it}.",
						dramatic = "{Gift}... how... SURPRISING.|Thank you, truly, I think.",
						bookish = "{Gift}, interesting.|I'll read up on what to do with {it}, thank you.",
						_ = "Oh, you got me {gift}.|That's... really kind, thank you.",
					}, "sweat")
					c:rel(3)
				end
			end)
		end
		s:log("{a} asked what to give {b}.")
		return s:done()
	end,
})

event({
	id = "motto",
	when = "any",
	weight = W({ base = 0.12 }),
	scene = function(ctx, a)
		local v = ctx.v(a)
		local options = {}
		for _, sy in ctx.rng:shuffle(Sayings.list) do
			if sy.id ~= v.saying and #options < 2 then
				table.insert(options, sy)
			end
		end
		local s = K.scene(ctx, "A thing to say")
		burst(s, "a", {
			dramatic = "{player}, every great person has a line they're known for.|I've just realised I don't have one, and it's a TRAGEDY.|Will you choose mine?",
			cool = "{player}.|Everyone round here has a thing they always say.|I don't, so pick one for me.",
			nervous = "{player}, I just noticed that everyone has a thing they always say.|I-I don't have one, and what if people have noticed?|Could you pick one for me?",
			sunny = "I want a catchphrase like everyone else has.|Help me pick one, and I'll start saying it today.",
			gloomy = "{player}, everyone has a thing they say, except me.|Heh... mine's just a long sigh.|Could you pick me something better?",
			proud = "Someone like me deserves a proper saying.|Choose me something worthy, and I'll make it famous.",
			bookish = "Did you know most people repeat the same few phrases every day?|I've been listening, and I realised I don't have one of my own.|Would you choose one for me?",
			cheeky = "{player} i need a catchphrase|everyone's got one and mine can't just be hehe|pick something good",
			gentle = "{player}, could you help me with something small?|Everyone has a little saying they use, and I'd like one too.",
			dreamy = "{player}...|I noticed that everyone has a thing they always say.|I don't think I have one, so could you pick mine?",
			bold = "{player}, everyone round here has a saying, and I need one.|Pick a good one, right?",
			easygoing = "Everyone's got a thing they always say, and mine is just 'mm'.|Could you pick me something better?",
			shy = "Um, {player}, everyone has a little saying, except me.|Could you pick one for me? Only if you want to.",
			prickly = "Everyone in town has a saying, and it's annoying.|Fine, pick one for me too.",
			polite = "Good morning, {player}, I have noticed that everyone has a saying.|Would you be kind enough to choose one for me?",
			foodie = "{player}, everyone has a saying, and mine is just 'what's for lunch?'|Pick me a better one.",
			_ = "{player}, can you help me pick a catchphrase?|Everyone in town seems to have one except me.",
		}, "question")
		for _, sy in options do
			s:choice(sy.text, function(c)
				c:with({ motto = sy.text })
				burst(c, "a", {
					proud = "'{motto}' Hmph, yes, that suits me.|Most things do, naturally.",
					shy = "'{motto}' Um, I'll try it.|Quietly at first, if that's okay.",
					easygoing = "'{motto}' Mm, I can say that without much effort.|That's the kind of saying I like.",
					cool = "'{motto}' Fine, that one's mine now.",
					dramatic = "'{motto}' That's me, that's EXACTLY me!|The whole square will be hearing it by tonight.",
					gloomy = "'{motto}' Heh... I'll give it a week.|Nobody will notice anyway.",
					cheeky = "'{motto}' ok that's good|i'm saying it to everyone until they beg me to stop",
					gentle = "'{motto}' Oh, I like that one.|I'll try it out on the neighbours tomorrow.",
					sunny = "'{motto}' Yes, yes, that's the one!|I'm saying it to everyone I see today.",
					bold = "'{motto}' Hah, I like it.|I'm saying it all day, right?",
					dreamy = "'{motto}' Hmm... it sounds like a song.|La la ♪, I'll hum it all day.",
					prickly = "'{motto}' Fine, it's not bad.|Don't tell anyone you picked it.",
					bookish = "'{motto}' Good, it's short and easy to remember.|Did you know most sayings are under six words?",
					polite = "'{motto}' What a lovely choice, thank you kindly.|I will use it often.",
					foodie = "'{motto}' Mmm, I like it.|I'll say it every time I sit down to eat.",
					nervous = "'{motto}' Okay, okay, I can say that.|What if I say it at the wrong time, though?",
					_ = "'{motto}' ...Yes, that sounds like me.|Thanks for picking it.",
				}, "sparkle", "cheer")
				c:saying("a", sy.id)
				c:mood("a", 3)
			end)
		end
		s:log("{a} picked a new saying.")
		return s:done()
	end,
})

event({
	id = "pickhobby",
	when = "day",
	weight = W({ base = 0.1, traits = { focus = -0.2 } }),
	scene = function(ctx, a)
		local v = ctx.v(a)
		local options = {}
		for _, h in ctx.rng:shuffle(Sayings.hobbies) do
			if h.id ~= v.hobby and #options < 2 then
				table.insert(options, h)
			end
		end
		local s = K.scene(ctx, "Something to do")
		burst(s, "a", {
			gloomy = "{player}, I'm bored, and it's the heavy kind of bored.|Heh... I've been staring at the ceiling since lunch.",
			dramatic = "{player}, I'm so bored I could lie down in the middle of the square.|Nothing in my life has ever been this DULL.",
			easygoing = "I've run out of things to do.|I napped, then I had a snack, then I napped again, and the day still isn't over.",
			sunny = "{player}, {player}, I'm so bored!|I've already tidied my whole house twice today.",
			cheeky = "{player} i'm bored|like, really bored, i've counted my socks twice",
			bookish = "I've finished every book I borrowed this week.|Actually, I think I need something to do that isn't reading.",
			nervous = "{player}, I've got nothing to do today, and it's making me jittery.|What if I just sit here fidgeting all afternoon?",
			gentle = "Have you got a minute?|I've had a very quiet week, and I think I'd like a hobby.",
			dreamy = "{player}...|I've been sitting by the window all morning, watching the gulls.|I think I need something to do.",
			bold = "{player}, I'm bored, and I hate being bored.|I need something to do, right now.",
			proud = "{player}, someone as talented as me shouldn't be this bored.|I need a new hobby.",
			shy = "Um, {player}, I've been a bit bored lately.|Sorry, that's a silly thing to say.",
			cool = "{player}.|I'm bored.",
			prickly = "I'm bored, and don't tell me to read a book.|I need something else.",
			polite = "Good afternoon, {player}, I have a lot of free time this week.|I would like to find something new to do.",
			foodie = "{player}, I'm so bored that I've eaten three lunches.|I need something else to do.",
			_ = "I'm so bored that I've started counting the tiles on my floor.",
		}, "sad")
		burst(s, "a", {
			cheeky = "pick me a new hobby, go on",
			sunny = "Pick a hobby for me, please, please!",
			gentle = "Would you pick a hobby for me, if you have a minute?",
			bold = "Pick me a hobby, and I'll start today.",
			dreamy = "Could you pick something for me...? I can't choose.",
			easygoing = "Pick me a hobby, something I can do sitting down.",
			proud = "Choose me a hobby worthy of my talents.",
			shy = "Could you pick a hobby for me? (Only if you want to.)",
			cool = "Pick a hobby for me.",
			prickly = "Just pick something for me, and make it good.",
			dramatic = "Choose my new PASSION, {player}!",
			bookish = "Could you pick a hobby for me? I've narrowed it down to about forty.",
			gloomy = "Could you pick something for me?|Heh... I'll probably give up, but still.",
			polite = "Would you please pick a new hobby for me to try?",
			foodie = "Pick me a hobby, and if it involves snacks, even better.",
			nervous = "Could you pick a hobby for me? Something safe, please.",
			_ = "Could you pick a new hobby for me to try?",
		}, "question")
		for _, h in options do
			s:choice("Why not try " .. h.name .. "?", function(c)
				c:with({ hobby = h.name, Hobby = upper(h.name) })
				burst(c, "a", {
					bold = "Okay, {hobby} it is.|I'll be the best in town at it by Friday, you'll see.",
					easygoing = "{Hobby}? Sure, why not.|As long as I can take breaks, I'm in.",
					proud = "{Hobby}, very well.|I'll be excellent at it, naturally.",
					shy = "Um, {hobby}? Okay, I'll try...|Please don't watch me the first few times, though.",
					bookish = "{Hobby}, how interesting.|I'll borrow a book on it from the library first, of course.",
					nervous = "{Hobby}? What if I'm terrible at it?|...O-okay, I'll give it a try anyway.",
					sunny = "{Hobby}? Yes, yes, I'm starting this afternoon!",
					gentle = "{Hobby}, that sounds lovely.|I'll start gently and see how I get on.",
					dreamy = "{Hobby}...|I can already picture myself doing it down on the pier.",
					cheeky = "{hobby}? ok, fine, i'll try it|if i'm bad at it, that's on you hehe",
					cool = "{Hobby}, okay.|I'll try it this week.",
					prickly = "{Hobby}? Ugh, fine.|If I like it, I'm not thanking you.",
					dramatic = "{Hobby}! My new PASSION!|I'll be famous for it by the weekend.",
					gloomy = "{Hobby}... okay.|Heh... I'll give it a week.",
					polite = "{Hobby}, what a lovely idea, thank you.|I will start this afternoon.",
					foodie = "{Hobby}? Ooh, okay.|I'll start after lunch.",
					_ = "{Hobby}? Okay, I'm in.|I'll make a start this afternoon.",
				}, "idea", "cheer")
				c:hobby("a", h.id)
				c:mood("a", 4)
				c:memo("a", "You got me into {hobby}, {player}, though I'm not very good yet.")
			end)
		end
		s:log("{a} asked you to pick them a hobby.")
		return s:done()
	end,
})

event({
	id = "dayplan",
	when = "day",
	weight = W({
		base = 0.15,
		cond = function(ctx)
			return ctx.hour < 13
		end,
	}),
	scene = function(ctx, a)
		local s = K.scene(ctx, "Plans for today")
		burst(s, "a", {
			easygoing = "*yawn* I've got the whole day off today.|I can't decide between the beach and the library, and bed is looking good too.",
			bookish = "I've got a day off, and the library is the obvious choice.|Actually, the beach would be nice as well, if it weren't for all the sand.",
			nervous = "I've got the day off today, and I can't decide what to do.|If I pick the beach, what if it rains the moment I get there?",
			sunny = "I've finally got a day off!|I want to go to the beach, but the library just got new books in.",
			cool = "I've got the day off.|It's the beach or the library, and I can't decide.",
			gloomy = "I've got a day off, and I'll waste it, as usual.|It's the beach or the library, I think.",
			foodie = "I've got the day off, so I'm planning it around lunch.|The beach has the fish stall, but the library is right next to the bakery.",
			gentle = "I've got a day off today, which hardly ever happens.|I'd like to go to the beach or the library, but I can't choose.",
			dreamy = "I've got the whole day off...|The beach would be nice, and so would the library, and now I've been standing in my doorway for ages.",
			shy = "Um, I've got a day off today.|I can't decide between the beach and the library.",
			bold = "{player}, I've got a whole day off, and I'm not wasting it.|It's the beach or the library, and I can't make up my mind.",
			proud = "I've earned a day off, naturally.|It's the beach or the library, and I want the one that deserves me.",
			cheeky = "guess what, day off|beach or library? you pick, since you've got nothing better to do hehe",
			prickly = "Ugh, I've got a day off and no idea what to do with it.|The beach or the library, I suppose, not that I care much.",
			dramatic = "A whole DAY off, {player}!|The beach or the library, and my entire day depends on it.",
			polite = "Good morning, {player}, I have the day off today.|I cannot decide between the beach and the library.",
			_ = "I've got the day off today.|I can't decide between the beach and the library.",
		}, "question")
		s:say("a", "Will you pick for me, {player}?", "question")
		s:choice("Go to the beach.", function(c)
			burst(c, "a", {
				foodie = "The beach it is, then.|I'm getting a fish sandwich from the stall on the way.",
				sunny = "The beach, yes, yes!|I'm going to build the biggest sandcastle on it.",
				dramatic = "The beach! Sun, waves and sand in absolutely everything.|I'm going right now.",
				bold = "Beach it is, and I'm swimming out to the buoy and back.",
				easygoing = "Mm, the beach, then.|I'll find a quiet spot and nap in the sun.",
				bookish = "The beach, then, sand and all.|I'll take a book, of course.",
				gentle = "The beach, then, it's lovely this time of year.|I'll pack a little lunch, and don't forget your sun hat, okay?",
				dreamy = "The beach... I'll listen to the waves until I forget the time.|La la ♪",
				proud = "The beach, naturally, it's where I look my best.|I'll take the good towel.",
				shy = "The beach, okay...|I'll find a quiet corner where nobody will look at me.",
				cheeky = "beach it is|i'm burying someone's sandals in the sand, jk... maybe",
				cool = "The beach, then.|I'll go early, before it gets busy.",
				prickly = "Fine, the beach.|Sand gets everywhere, but it's not like I had a better idea.",
				gloomy = "The beach, then.|Heh... it'll cloud over the second I lay out my towel, as usual.",
				polite = "The beach it is, thank you for choosing.|Have a lovely day, {player}.",
				nervous = "The beach, okay.|What if I get sunburned? ...I'll take a big hat, so it's fine.",
				_ = "The beach it is, then.|I'll take a towel and see how long I can sit still.",
			}, "sparkle", "cheer")
			c:mood("a", 5)
			c:memo("a", "I went to the beach because you told me to, {player}, and it was a good call.")
		end)
		s:choice("Go to the library.", function(c)
			burst(c, "a", {
				foodie = "The library, then, and the bakery's right next door.|I'll get a bun on the way out.",
				sunny = "The library! I'm getting the new books before anyone else does.",
				gloomy = "The library, then.|Someone will be in my chair, as usual, but I'll go.",
				gentle = "The library, how lovely.|I'll bring you back a book you might like, okay?",
				bold = "Library it is.|I'm reading the whole sea monster series in one go, watch me.",
				dreamy = "The library... I love how quiet it is in there.|The dust in the sunlight looks like tiny stars.",
				easygoing = "The library, nice.|There's a big soft chair in there that's perfect for a nap, no rush.",
				proud = "The library, a fine choice for a fine mind.|Mine, naturally.",
				shy = "The library, okay.|It's quiet there, so that suits me.",
				cheeky = "library it is|i'm hiding bookmarks in all the wrong pages hehe, jk",
				cool = "The library, then.|I'll be back before dark.",
				prickly = "The library, fine.|It's the only quiet place in town, not that I care.",
				dramatic = "The library! A thousand STORIES waiting for me.|I may never come out.",
				bookish = "The library, of course.|They got twelve new books in on Tuesday, and I've only read two of them.",
				polite = "The library, thank you, that is a lovely idea.|I will return my books while I am there.",
				nervous = "The library, good, it's quiet and safe.|Unless my books are overdue... oh no, I'd better check.",
				_ = "The library, then.|There's a big chair by the window that I always try to get.",
			}, "heart")
			c:mood("a", 4)
			c:memo("a", "I read a whole book at the library yesterday, so you were right.")
		end)
		s:log("{a} asked how to spend the day.")
		return s:done()
	end,
})

-- asked to the dance: yes from a friend, a polite no from anyone else
local DANCE_YES = {
	sunny = "Yes, yes, I'll bring my dancing shoes!",
	gentle = "Of course I'll come, that sounds lovely.",
	bold = "Hah, sure, and I'm dancing whether you do or not.",
	dreamy = "Hmm... yes, I'd like that.|They hang lanterns all over the hall, you know.",
	easygoing = "Sure, as long as I can sit down between songs.",
	proud = "Naturally, I accept.|I'll wear my best shoes, so try to keep up.",
	shy = "Um, yes... I'd like that.",
	cheeky = "only if we hit the snack table first|deal?",
	cool = "Sure, I'll come.",
	prickly = "Ugh, fine, I'll come.|I'm not dancing, though.",
	dramatic = "Yes! I've been waiting all YEAR for someone to ask me.",
	bookish = "Yes, I'd like that.|Actually, I'll read up on a few steps beforehand.",
	gloomy = "Me? Heh... okay, I'll come.",
	polite = "I would be happy to, thank you kindly for asking.",
	foodie = "Yes, as long as we stand right next to the cake.",
	nervous = "O-okay, yes, as long as nobody makes me dance.",
	_ = "Sure, I'd like that.",
}
local DANCE_NO = {
	sunny = "Aww, I'm already going with someone else, sorry!",
	gentle = "Oh, I'm sorry, I don't think I'll go this time.|Have fun for me, okay?",
	bold = "No, ask someone else.",
	dreamy = "Hmm... I don't think so, sorry.",
	easygoing = "Eh, I'll pass, dances aren't really my thing.",
	proud = "Hmph, I already have plans on Friday.",
	shy = "Um... sorry, I can't.",
	cheeky = "nah, i'm busy that night hehe",
	cool = "No, sorry.",
	prickly = "Ugh, no... ask me next time, or whatever.",
	dramatic = "*sob* My Friday is already taken, I'm SO sorry.",
	bookish = "Sorry, I'm working at the library on Friday, from six until nine.",
	gloomy = "Heh... no, I'd only spoil it for you.",
	polite = "That is very kind of you to ask, but I must say no, I am sorry.",
	foodie = "Sorry, I'm cooking for my cousin on Friday.",
	nervous = "S-sorry, I can't, I'm really sorry.",
	_ = "Sorry, I'm busy on Friday.",
}

event({
	id = "dancepartner",
	actors = 3,
	when = "any",
	weight = W({ base = 0.12, count = 3 }),
	scene = function(ctx, a, b, c)
		local s = K.scene(ctx, "The dance")
		burst(s, "a", {
			shy = "Um, {player}, there's a dance at the hall on Friday.|I'd like to go, but not on my own.",
			bold = "There's a dance at the hall on Friday, and I'm going.|I'm just not turning up on my own.",
			dramatic = "{player}, the hall dance is on Friday.|I need someone beside me when I walk in, purely for the effect.",
			nervous = "The hall's having a dance on Friday.|What if I go alone and end up standing by the wall all night?",
			sunny = "There's a dance at the hall on Friday, and I really want to go.|It'll be so much more fun if I bring a friend.",
			gentle = "There's a dance at the hall on Friday.|I'd love to go, but I'd feel better with a friend beside me.",
			dreamy = "{player}, they're hanging lanterns in the hall for Friday's dance...|I want to go, but not on my own.",
			polite = "{player}, there's to be a dance at the hall on Friday.|I'd rather not go alone, if I can help it.",
			easygoing = "There's a dance at the hall on Friday.|I'd go, but standing around alone sounds like a lot of work.",
			proud = "There's a dance at the hall on Friday, and I'll be the best dancer there, naturally.|I just need someone to arrive with.",
			cheeky = "dance at the hall on friday|i'm going, but i need someone to blame when i trip",
			cool = "There's a dance at the hall on Friday.|I'm not going alone.",
			prickly = "Ugh, there's a dance at the hall on Friday.|I'm not going on my own, so don't laugh.",
			bookish = "There's a dance at the hall on Friday, the first one in eight months.|I'd rather not go on my own.",
			gloomy = "There's a dance at the hall on Friday.|Heh... I'll end up standing by the wall, unless I bring someone.",
			foodie = "There's a dance at the hall on Friday, and they always put out a big snack table.|I'd rather not eat my way through it alone, though.",
			_ = "There's a dance at the hall on Friday.|I'd rather not go on my own.",
		}, "sweat")
		s:say("a", "Should I ask {b} or {c} to come with me?", "question")
		s:choice("Ask {b}, I think.", function(ch)
			say(
				ch,
				"a",
				"{b}, would you come to the dance with me on Friday?|I need someone to stand by the snack table with.",
				"sweat"
			)
			burst(ch, "b", if ctx.rel(a, b) >= 0 then DANCE_YES else DANCE_NO, "heart")
			ch:relx("a", "b", if ctx.rel(a, b) >= 0 then 10 else -2)
		end)
		s:choice("Ask {c}, I think.", function(ch)
			say(
				ch,
				"a",
				"{c}, would you come to the dance with me on Friday?|I need someone to stand by the snack table with.",
				"sweat"
			)
			burst(ch, "c", if ctx.rel(a, c) >= 0 then DANCE_YES else DANCE_NO, "heart")
			ch:relx("a", "c", if ctx.rel(a, c) >= 0 then 10 else -2)
		end)
		s:choice("Why not all go together?", function(ch)
			say(ch, "a", "Why choose, when we can all go together?|We can take over the snack table.", "music")
			ch:relx("a", "b", 3)
			ch:relx("a", "c", 3)
		end)
		s:log("{a} asked who to take to the dance.")
		return s:done()
	end,
})

local PLANTNAMES = { "Fernando", "Leafy", "Little Steve", "Sprout", "Margaret", "Gus" }

event({
	id = "nameplant",
	when = "day",
	weight = W({ base = 0.1 }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "A plant with no name")
		burst(s, "a", {
			dramatic = "I've brought home a new fern.|It's a very serious fern, so it needs a name with some weight to it.",
			gloomy = "I got a fern from the market.|It droops a bit and looks worried all the time, like me.|It needs a name.",
			sunny = "I got a fern from the market today.|It needs a name, and I want you to choose it.",
			bookish = "{player}, I've got a new fern, and it needs a name.|Did you know ferns are older than trees?|It deserves a good one.",
			shy = "Um, {player}, I got a little fern.|It doesn't have a name yet, and I thought you might pick one.",
			cheeky = "{player} i got a fern|it needs a name and you're picking, no take backs",
			gentle = "I've brought home a little fern.|It needs a name, and I'd like you to choose it.",
			dreamy = "{player}, my new fern keeps leaning towards the window...|I think it's waiting for a name.",
			bold = "{player}, I bought a fern, and it needs a name.|Something strong, right? Pick one.",
			easygoing = "I got a fern from the market, and it's very relaxed, like me.|It needs a name, no rush.",
			proud = "I've bought the finest fern at the market, naturally.|It needs a name to match.",
			cool = "{player}, I got a fern.|It needs a name, so pick one.",
			prickly = "I got a fern, don't ask why.|It needs a name, and I'm bad at names, so you pick.",
			polite = "Good afternoon, {player}, I have bought a fern for my windowsill.|Would you be so kind as to choose a name for it?",
			foodie = "I got a fern from the market, right next to the herb stall.|It looks a bit like parsley, but it needs a proper name.",
			nervous = "{player}, I got a fern, and I've already moved it three times.|What if it doesn't like my house?|Could you pick a name for it?",
			_ = "{player}, I've got a new fern for my windowsill.|It needs a name, and I can't think of a good one.",
		}, "question")
		s:askName({
			var = "plant",
			suggest = PLANTNAMES,
			ask = "What should the fern be called?",
			build = function(c)
				burst(c, "a", {
					dramatic = "{plant}, a name to be remembered!|Hello, {plant}, welcome to your new home.",
					cheeky = "{plant} hehe|ok fine, it actually suits it",
					gloomy = "{plant}... heh, it does look like a {plant}.|Welcome home, {plant}.",
					sunny = "{plant}! Ehehe, it's perfect, perfect!|Hello, {plant}, let's be best friends.",
					gentle = "{plant}, oh, that's sweet.|I'll water you every morning, okay, {plant}?",
					bold = "{plant}, good, strong name.|You're going to grow big, {plant}, right?",
					dreamy = "{plant}... hmm, it waved a leaf when you said that.|Hello, {plant}.",
					easygoing = "{plant}, nice, that's easy to say.|We're going to get along, {plant}.",
					proud = "{plant}, hmph, a fine name.|For a fine fern, which I picked out myself, naturally.",
					shy = "{plant}... I like it.|H-hello, {plant}.",
					cool = "{plant}, good name.|Welcome home, {plant}.",
					prickly = "{plant}? Fine, it suits it.|Don't tell anyone I talk to it.",
					bookish = "{plant}, good.|I'll write it on a little card in the pot, with today's date.",
					polite = "{plant}, what a lovely name, thank you kindly.|Welcome to your new home, {plant}.",
					foodie = "{plant}, yum, that sounds like a dessert.|Welcome home, {plant}, I'll put you by the herbs.",
					nervous = "{plant}, okay, that's a good name.|Please grow, {plant}, I'll try really hard to remember to water you.",
					_ = "{plant}, I like that.|Hello, {plant}, welcome to your new windowsill.",
				}, "heart", "cheer")
				c:mood("a", 3)
				c:memo("a", "I named my fern {plant}, and I say good morning to it every day.")
				-- and it grows (Sim/FollowUps)
				c:follow("ferngrows", { chance = 0.7, hours = 12, words = { plant = "{plant}" } })
			end,
		})
		s:log("{a} asked you to name their plant.")
		return s:done()
	end,
})

event({
	id = "dyehair",
	when = "day",
	weight = W({ base = 0.1, traits = { brave = 0.3 } }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "A bold idea")
		burst(s, "a", {
			nervous = "{player}, I'm thinking of dyeing my hair blue.|What if it comes out green and stays that way for months?|Should I do it?",
			dramatic = "{player}, I've decided it's time for a whole new me.|A BLUE me.|Should I do it?",
			shy = "Um, {player}, I've been thinking about dyeing my hair blue.|Is that a silly idea?|You don't have to answer if it is.",
			cheeky = "{player} i'm dyeing my hair blue|well, i'm thinking about it|you're saying yes, right",
			proud = "I'm considering bright blue hair.|It would suit me, naturally, but I'd like a second opinion.",
			gloomy = "I keep thinking about dyeing my hair blue.|It'll look awful, I expect, but I can't stop thinking about it.",
			gentle = "{player}, can I ask what you think?|I've been wondering about dyeing my hair blue, just a soft blue.",
			dreamy = "I saw a blue fishing boat this morning...|Now I can't stop thinking about having hair that colour.",
			sunny = "{player}, I've had a fun idea!|I want to dye my hair bright blue, so should I?",
			bold = "{player}, I'm dyeing my hair bright blue.|It'll look great, right?",
			easygoing = "I've been thinking about dyeing my hair blue, no rush on it.|It'd mean sitting still for an hour, which I'm good at.",
			cool = "I'm thinking of blue hair.|Yes or no?",
			prickly = "Don't laugh, but I'm thinking of dyeing my hair blue.|Just tell me if it's a bad idea, or whatever.",
			bookish = "I've been reading about hair dye, {player}.|Actually, the blue kind lasts about six weeks, so should I try it?",
			polite = "{player}, may I ask your opinion?|I am thinking of dyeing my hair blue, and I would like to know if you think it would suit me.",
			foodie = "I'm thinking of dyeing my hair blue, like a blueberry.|Should I do it?",
			_ = "I'm thinking of dyeing my hair bright blue.|Should I go for it?",
		}, "idea")
		s:choice("Go for it.", function(c)
			burst(c, "a", {
				shy = "Okay, okay, I'll do it.|Right now, before I lose my nerve.",
				bold = "Hah! That's what I wanted to hear.|I'm getting the dye right now.",
				prickly = "Fine, I'll do it.|If it looks awful, I'm blaming you, though.",
				cheeky = "knew you'd say that hehe|blue me incoming",
				nervous = "R-really? Okay, I'm doing it.|If it turns green, you're hiding in my house with me.",
				dreamy = "Blue, then...|I'll look like the sea at noon.",
				sunny = "Yes, yes, I'm doing it right now!",
				gentle = "All right, I'll do it.|Come and see it after, okay? I'll make tea.",
				easygoing = "Okay, blue it is.|I'll do it after my nap, no rush.",
				proud = "Naturally, I knew you'd agree.|I'll look wonderful, as usual.",
				cool = "Okay, I'm doing it.|I'll show you tomorrow.",
				dramatic = "Then the NEW me begins today!|Goodbye, old hair, I'll never forget you.",
				bookish = "Right, I'm doing it.|I've read the instructions twice, so it should be fine.",
				gloomy = "Okay, I'll do it.|Heh... if it goes wrong, at least I'll have something new to sulk about.",
				polite = "Then I will do it, thank you kindly for the push.|I will show you how it looks tomorrow.",
				foodie = "Okay, I'm doing it!|Blueberry hair, here I come.",
				_ = "Okay, I'm doing it.|Right now, before I change my mind.",
			}, "sparkle", "cheer")
			c:fx({ t = "creator", who = "a" })
			c:mood("a", 4)
		end)
		s:choice("Sleep on it first.", function(c)
			burst(c, "a", {
				dreamy = "Hmm... I'll sleep on it.|Maybe I'll dream about it, and the dream will be blue.",
				easygoing = "Sleep on it, mm, my favourite kind of advice.|I'm very good at the sleeping part.",
				dramatic = "Sleep on it? But I'm READY now.|...Fine, one night, and then I'm doing it.",
				bold = "Hah, fine, one night.|If I still want it in the morning, I'm doing it.",
				sunny = "Okay, I'll wait until tomorrow!|It's going to be so hard to get to sleep, though.",
				nervous = "Yes, sleeping on it is safe.|I'll decide in the morning, if I sleep at all.",
				shy = "Okay... I'll think about it tonight.|Thank you for not laughing.",
				cheeky = "boo, fine|i'll sleep on it, but i'm dreaming in blue",
				gloomy = "Heh... I'll probably talk myself out of it by morning.",
				proud = "Hmph, very well.|I'll look wonderful in the morning, blue or not.",
				gentle = "That's sensible, I'll sleep on it.|You get a good night's sleep too, okay?",
				cool = "Good idea.|I'll decide in the morning.",
				prickly = "Ugh, fine, I'll sleep on it.|Not because you said so, I was going to anyway.",
				bookish = "Sleeping on it is wise.|Actually, people make better choices after a good night's sleep, or so I've read.",
				polite = "That is very sensible advice, thank you.|I will decide in the morning.",
				foodie = "Okay, I'll sleep on it.|I'll decide over breakfast, I always think better with toast.",
				_ = "That's sensible, I suppose.|I'll see if I still want it in the morning.",
			}, "zzz")
			c:mood("a", 1)
		end)
		s:log("{a} thought about dyeing their hair blue.")
		return s:done()
	end,
})

-- a dinner made around each food (a carrot on its own isn't a dinner)
local DINNER = {
	apple = "apple crumble",
	bread = "soup with fresh bread rolls",
	carrot = "carrot soup",
	cheese = "cheese on toast",
	soup = "mushroom soup",
	skewer = "fish skewers",
	tart = "a berry tart",
	honeycake = "honey cake",
	riceball = "rice balls",
	pancakes = "pancakes",
	curry = "spicy curry",
	pie = "pumpkin pie",
	icecream = "ice cream for dessert",
	salad = "a big garden salad",
	chocolate = "chocolate cake",
	pudding = "a steamed pudding",
	broccoli = "broccoli and cheese bake",
	pickles = "cheese and pickle sandwiches",
	stew = "hearty stew",
	starfruit = "star fruit salad",
	dragonchili = "a pot of fire chili",
	goldapple = "golden apple pie",
}

event({
	id = "cookfor",
	cutscene = "kitchen",
	actors = 2,
	when = "day",
	weight = W({ base = 0.12, rel = 20 }),
	scene = function(ctx, a, b)
		local fav = Foods.get(ctx.v(b).fav)
		local options = {}
		if fav then
			table.insert(options, fav)
		end
		for _, f in ctx.rng:shuffle(Foods.list) do
			if #options >= 3 then
				break
			end
			if not table.find(options, f) then
				table.insert(options, f)
			end
		end
		options = ctx.rng:shuffle(options)
		local s = K.scene(ctx, "Dinner for {b}")
		burst(s, "a", {
			foodie = "{player}, I'm cooking dinner for {b} tonight.|This is my moment, and I want it to be perfect.",
			nervous = "{player}, I'm cooking dinner for {b} tonight.|I've never cooked for anyone before, and what if it's awful?",
			gloomy = "I'm cooking for {b} tonight.|Something will burn, because something always burns.",
			proud = "{player}, I'm cooking dinner for {b} tonight.|It'll be excellent, naturally, but I still need to choose a dish.",
			shy = "Um, {player}, I offered to cook dinner for {b} tonight.|I don't really know what they like, though.",
			bold = "{b}'s coming round for dinner tonight, and I'm cooking.|You know what they like, right?",
			gentle = "I've invited {b} round for dinner tonight.|They've had a long week, so I want to make something they love.|Have you eaten, by the way? There'll be plenty left over.",
			dreamy = "{player}, I'm cooking for {b} tonight...|I've been staring into my cupboard for ten minutes.",
			sunny = "{b}'s coming to dinner tonight, and I'm cooking.|I want it to be the best meal they've had all week.",
			easygoing = "I said I'd cook dinner for {b} tonight, which seemed easy at the time.|Now I actually have to pick something, so help me out.",
			cheeky = "{player} i'm cooking for {b} tonight|i'm not telling them what's in it until they've eaten it hehe",
			cool = "I'm cooking for {b} tonight.|I need a dish.",
			prickly = "I'm cooking dinner for {b} tonight, don't make a thing of it.|I just want it to be good, that's all.",
			dramatic = "{player}, tonight I cook for {b}, and it will be a night to REMEMBER.|If I can choose a dish, that is.",
			bookish = "I'm cooking dinner for {b} tonight.|I've got four cookbooks open on the table, and that's actually making it harder.",
			polite = "Good afternoon, {player}, I have invited {b} for dinner this evening.|I would like to make something they will truly enjoy.",
			_ = "{player}, I'm cooking dinner for {b} tonight.|I want to make something they'll really enjoy.",
		}, "question")
		s:say("a", "What do you think I should make?", "question")
		for _, f in options do
			local dish = DINNER[f.id] or Foods.phrase(f)
			s:choice("What about " .. dish .. "?", function(c)
				c:with({ food = dish })
				c:n("{a} cooked dinner for {b} that evening, with {food} on the menu.")
				if fav and f.id == fav.id then
					say(c, "b", "You made my favourite!|How did you know?", "heart", "cheer")
					c:rel(12)
					c:mood("b", 6)
				else
					burst(c, "b", {
						sunny = "That was so good, thank you!|Same time next week?",
						gentle = "Oh, that was lovely, thank you.|You've made my whole week better.",
						bold = "Hah, that hit the spot.|...Thanks. Next one's on me.",
						dreamy = "Hmm... that was nice.|Thank you for cooking for me.",
						easygoing = "Mm, that was good, thanks.|I might need a nap now.",
						proud = "Hmph, not bad at all.|You may cook for me again.",
						shy = "Um, thank you, that was really nice.",
						cheeky = "ok that was good|i'm coming round every night now hehe",
						cool = "That was good, thanks.|I'll do the dishes.",
						prickly = "Fine, that was nice.|...Thanks for cooking.",
						dramatic = "That was a FEAST.|Thank you, truly.",
						bookish = "That was lovely, thank you.|Actually, could I have the recipe?",
						gloomy = "That was really nice, heh.|Thanks for having me.",
						polite = "Thank you kindly for dinner.|It was delicious.",
						foodie = "Mmm, that was good!|Who taught you to cook like that?",
						nervous = "That was so nice, th-thank you.|You didn't have to go to all that trouble.",
						_ = "Thanks for dinner, that was really nice.",
					}, "heart")
					c:rel(5)
				end
			end)
		end
		s:log("{a} cooked dinner for {b}.")
		return s:done()
	end,
})

event({
	id = "sayfirst",
	actors = 2,
	when = "any",
	weight = W({ base = 0.5, quarrel = true }),
	scene = function(ctx, a, b)
		local s = K.scene(ctx, "Who says sorry")
		burst(s, "a", {
			prickly = "{player}, {b} and I still aren't speaking.|I don't care, but it's getting annoying.",
			gloomy = "{b} and I still aren't talking.|It's only been a few days, but it feels like ages.",
			nervous = "{player}, {b} and I still aren't talking.|It's been two whole days, and I've been counting the hours.",
			proud = "{player}, {b} and I are not speaking at the moment.|I'm perfectly fine about it, of course.",
			sunny = "{player}, {b} and I still aren't talking.|I hate it so much, it's making my whole day grey.",
			shy = "Um, {player}, {b} and I still haven't made up.|I keep seeing them in the square and looking away.",
			bold = "{b} and I still aren't talking, and I'm sick of it.",
			gentle = "{player}, {b} and I still haven't made up.|Oh, my, I keep thinking about how upset they looked.",
			dreamy = "I walked past {b}'s house today...|We still aren't talking, and it feels strange not to wave.",
			easygoing = "{b} and I still aren't talking, and it's been days.|I'm usually good at letting things go, but this one's stuck.",
			cheeky = "{player} {b} and i still aren't talking|i hid their shoes, but they started it, so",
			cool = "{b} and I aren't talking.|It's been three days.",
			dramatic = "{player}, {b} and I are no longer SPEAKING.|It's been three days, and every one felt like a year.",
			bookish = "{b} and I haven't spoken for four days now.|Actually, it's four days and six hours, I've been counting.",
			polite = "{player}, {b} and I have not spoken since our argument.|It has been several days, and I find it very sad.",
			foodie = "{b} and I still aren't talking, and we always have lunch together on Fridays.|I ate alone today, and nothing tasted right.",
			_ = "{player}, {b} and I still aren't talking.|It's been days now, and I hate it.",
		}, "sad")
		s:say("a", "Should I say sorry first, even though it was half their fault?", "sad")
		s:choice("Say sorry first.", function(c)
			burst(c, "a", {
				proud = "{b}, I may have been partly wrong.|Can we stop this now?",
				shy = "{b}, um, I'm sorry about the other day.|I really don't like not talking to you.",
				bold = "{b}, I'm sorry, all right?|Can we stop this now?",
				prickly = "{b}, I'm sorry.|...I mean it, so don't make me say it twice.",
				dramatic = "{b}, I've been a complete fool.|Let's put an end to this terrible silence.",
				polite = "{b}, I'm sorry for my part in it.|I'd very much like us to be friends again.",
				nervous = "{b}, I-I'm really sorry about the other day.|Can we please stop fighting?",
				gentle = "{b}, I'm sorry about the other day.|I've missed talking to you.",
				sunny = "{b}, I'm really sorry!|Can we please be friends again?",
				dreamy = "{b}, I've been thinking about you all week...|I'm sorry, can we be friends again?",
				easygoing = "Hey, {b}, I'm sorry about the other day.|Life's too short for this, so can we let it go?",
				cheeky = "{b} sorry about the other day|truce? i'll even give your shoes back",
				cool = "{b}, I'm sorry.|Let's drop it.",
				bookish = "{b}, I've thought it over, and I was partly wrong.|I'm sorry, and I'd like to be friends again.",
				gloomy = "{b}, I'm sorry about the other day.|Heh... I'm not good at this, but I mean it.",
				foodie = "{b}, I'm sorry about the other day.|Can we have lunch on Friday like we used to?",
				_ = "{b}, I'm sorry about the other day.|Can we stop this now?",
			}, "sad")
			if ctx.rng:chance(0.5 + K.trait(ctx, b, "kind") * 0.4) then
				burst(c, "b", {
					proud = "...Fine, I accept.|I'm sorry too, a little.",
					bold = "Yeah, I'm sorry too.|We're done fighting, so come here.",
					shy = "Oh, I'm sorry too.|I didn't like it either.",
					cool = "Yeah, I'm sorry too.",
					gloomy = "I thought you'd never speak to me again.|...I'm sorry too.",
					gentle = "Oh, I'm sorry too.|Let's not do that again, all right?",
					sunny = "I'm sorry too, really.|I missed you so much, it was awful.",
					dreamy = "Oh... I was hoping you'd say that.|I'm sorry too, so let's go and look at the sea.",
					easygoing = "Eh, it's fine, I'm sorry too.|Let's forget it and get a snack.",
					cheeky = "ok fine, sorry too|but you're buying the ice cream hehe",
					prickly = "Ugh, fine, I'm sorry too.|...I missed you, a bit, so don't read into it.",
					dramatic = "*sob* I'm sorry TOO!|Let's never fight again, ever.",
					bookish = "I'm sorry too.|Actually, I think we were both a little bit wrong.",
					polite = "Thank you, and I am sorry too.|I would very much like to put it behind us.",
					foodie = "I'm sorry too.|Let's get lunch and talk it all out, my treat.",
					nervous = "Oh, thank goodness, I'm sorry too.|I was so scared you'd never talk to me again.",
					_ = "...Yes, I'm sorry too.|I really missed you.",
				}, "heart")
				c:fx({ t = "makeup", a = "a", b = "b" })
				c:rel(10)
				c:mood("a", 5)
			else
				burst(c, "b", {
					sunny = "I'm still a bit hurt, honestly.|Can we talk tomorrow instead?",
					gentle = "Thank you for saying it.|I just need a little more time, all right?",
					bold = "Not yet.|I'm still mad, so give me a day.",
					dreamy = "Hmm... I'm not ready yet.|Ask me again tomorrow.",
					easygoing = "Eh, I'm still a bit annoyed, honestly.|Give me a day or so.",
					proud = "Hmph, an apology like that?|I'll think about accepting it.",
					shy = "Um... I'm not ready yet.|Sorry.",
					cheeky = "nope, not yet|try again tomorrow",
					cool = "Not yet, give me a day.",
					dramatic = "You think one sorry fixes EVERYTHING?|I need time to recover.",
					bookish = "I appreciate it, but I'm still thinking it all over.|Can we talk later this week?",
					gloomy = "Heh... I'm still too fed up to talk.|Maybe tomorrow.",
					polite = "Thank you, but I'm not quite ready yet.|Perhaps tomorrow.",
					foodie = "I'm still upset, and I haven't even had lunch.|Ask me later.",
					nervous = "I-I'm not ready yet, sorry.|Can we talk tomorrow?",
					prickly = "Ugh, not yet.|...Give me a day, then I'll come round.",
					_ = "That's it? You haven't even said what you're sorry for.|I'm not ready to talk yet.",
				}, "anger")
				c:rel(-3)
			end
		end)
		s:choice("Give it another day.", function(c)
			burst(c, "a", {
				proud = "One more day, then.|They might come to me first, which would be better.",
				shy = "One more day, then.|I need to work out what I'm going to say.",
				nervous = "Okay, one more day.|But if it gets to three days, I'm going round there.",
				sunny = "Okay, one more day!|Tomorrow I'll go round with cake, and we'll fix it.",
				gentle = "One more day, then.|It'll give us both time to calm down, okay?",
				bold = "Fine, one more day.|Then I'm knocking on their door, and that's that.",
				dreamy = "One more day...|Maybe I'll see them by the fountain, and it'll all just be fine.",
				easygoing = "One more day, sure.|No rush, these things usually sort themselves out.",
				cheeky = "one more day|they'll say sorry first, bet you",
				cool = "One more day.|Then I'll talk to them.",
				prickly = "Fine, one more day.|Not that I'm waiting for them, or whatever.",
				dramatic = "One more DAY of this silence?|...Fine, I'll be brave.",
				bookish = "One more day, then.|I'll write down what I want to say, so I get it right.",
				gloomy = "One more day.|Heh... it'll probably feel like a week.",
				polite = "One more day, then, thank you.|I will speak to them tomorrow.",
				foodie = "One more day, then.|Tomorrow I'll bring them a pie, since nobody stays angry in front of a pie.",
				_ = "One more day, then.|After that, I'll go and talk to them.",
			}, "sad")
			c:mood("a", -2)
		end)
		s:log("{a} wondered whether to say sorry to {b}.")
		return s:done()
	end,
})

local SKILLS =
	{ "juggling", "whistling with two fingers", "skipping stones", "doing a handstand", "folding paper cranes" }

event({
	id = "learnskill",
	when = "day",
	weight = W({ base = 0.1 }),
	scene = function(ctx, a)
		local opts = ctx.rng:shuffle(SKILLS)
		local s = K.scene(ctx, "Something to learn")
		burst(s, "a", {
			bold = "{player}, I want to learn a new skill this week.|Pick one, and I'll have it down by Sunday.",
			bookish = "I'd like to learn something new this week.|Something practical, ideally, rather than something I can read about.",
			easygoing = "I'm thinking of learning something new.|Nothing too tiring, mind you, since I have naps to fit in.",
			nervous = "{player}, I want to learn something new, but I don't know what.|What if I pick something and I'm hopeless at it?",
			sunny = "I want to learn something new this week!|You choose, and I'll practise every single day.",
			gentle = "I'd like to learn something new this week.|Nothing difficult, just something to do in the evenings.",
			dreamy = "I watched someone on the beach yesterday who could do something amazing...|It made me want to learn a new skill.",
			cheeky = "{player} i'm learning a new trick this week|pick one and i'll show off with it at the market",
			proud = "{player}, I've decided to learn a new skill this week.|I'm already good at most things, naturally, so choose well.",
			shy = "Um, {player}, I want to learn something new.|Could you pick something for me? Only if you want to.",
			cool = "I want to learn something new.|Pick one.",
			prickly = "I'm bored of doing the same things every day.|Pick something for me to learn, and don't make it silly.",
			dramatic = "{player}, I need a new TALENT.|Something that makes the whole square stop and stare.",
			gloomy = "I want to learn something new, though I'll probably be bad at it.|Heh... pick something anyway.",
			polite = "Good morning, {player}, I would like to learn a new skill this week.|Would you be kind enough to suggest one?",
			foodie = "I want to learn something new this week, and not just another recipe.|Well, maybe another recipe after this.",
			_ = "I want to learn something new this week.|Can you pick something for me to try?",
		}, "question")
		for i = 1, 2 do
			local skill = opts[i]
			s:choice("Try " .. skill .. ".", function(c)
				c:with({ skill = skill, Skill = upper(skill) })
				burst(c, "a", {
					proud = "{Skill}? Very well.|I'll be better at it than anyone in town by Sunday.",
					easygoing = "{Skill}? Sure, that sounds easy enough.|I'll start practising at some point.",
					bookish = "{Skill}? Excellent choice.|I'll read up on how it works tonight.",
					bold = "{Skill}? Hah, done.|I'll have it down by Sunday, you'll see.",
					sunny = "{Skill}! Yes, yes, I'm starting right now!",
					cheeky = "ok, {skill} it is|i'll be showing off at the market by friday",
					gloomy = "{Skill}... I'll be bad at it, as usual.|But okay, I'll try.",
					nervous = "{Skill}? Okay, I'll try it.|If it goes badly, please don't watch.",
					gentle = "{Skill}, that sounds nice.|I'll practise a little every evening.",
					dreamy = "{Skill}...|I'll practise on the beach where nobody can see.",
					shy = "{Skill}? Um, okay...|I'll practise when nobody's around.",
					cool = "{Skill}, fine.|I'll practise every evening.",
					prickly = "{Skill}? Ugh, fine.|Don't expect me to show you until I'm good at it.",
					dramatic = "{Skill}! My new TALENT.|The whole town will be talking about it by Sunday.",
					polite = "{Skill}, what a good idea, thank you.|I will practise every evening this week.",
					foodie = "{Skill}? Okay, I'm in.|I'll practise after dinner, every night.",
					_ = "{Skill}? Okay, I'll give it a go.|I'll practise every day this week.",
				}, "idea", "cheer")
				c:xp("a", 10)
				c:mood("a", 3)
				c:memo("a", "I've been practising {skill} every day, but don't ask me to show you yet.")
			end)
		end
		s:log("{a} wanted to learn something new.")
		return s:done()
	end,
})

event({
	id = "surpriseparty",
	actors = 2,
	when = "any",
	weight = W({ base = 0.1, rel = 20, traits = { mischief = 0.2 } }),
	scene = function(ctx, a, b)
		local s = K.scene(ctx, "Keep a secret?")
		burst(s, "a", {
			nervous = "I'm planning a surprise party for {b} on Friday.|You won't tell them, will you?|Please promise me you won't.",
			cheeky = "{player} guess what|i'm throwing {b} a surprise party on friday|you didn't hear it from me and you won't tell, right",
			sunny = "{player}, I'm planning a surprise party for {b} on Friday!|Don't tell them, don't tell them, okay?",
			polite = "{player}, I'm arranging a small surprise party for {b} on Friday.|I'd be very grateful if you kept it to yourself.",
			gentle = "I'm planning a little surprise party for {b} on Friday.|They've been working so hard lately.|You'll keep it quiet, won't you?",
			dreamy = "{player}, I'm planning a surprise party for {b} on Friday...|I keep picturing lanterns all round the room.|You won't tell them, will you?",
			bold = "{player}, I'm throwing {b} a surprise party on Friday.|You can keep a secret, right?",
			easygoing = "{player}, I'm throwing a surprise party for {b} on Friday.|Nothing fancy, just snacks and people, so don't tell them.",
			proud = "{player}, I'm planning a surprise party for {b} on Friday, and it'll be the best this town has seen.|Naturally, it's a secret.",
			shy = "Um, {player}, I'm planning a surprise party for {b} on Friday.|Could you not tell them? (Sorry, I know you wouldn't.)",
			cool = "I'm throwing {b} a surprise party on Friday.|Don't tell them.",
			prickly = "I'm throwing {b} a surprise party on Friday, don't make a big deal of it.|And don't tell them, obviously.",
			dramatic = "{player}, I'm planning the surprise party of the CENTURY for {b}.|It's on Friday, and you must keep this secret forever.",
			bookish = "{player}, I'm planning a surprise party for {b} on Friday.|I've made a list of twenty-two guests, and you're on it, so please don't tell.",
			gloomy = "I'm planning a surprise party for {b} on Friday.|Heh... someone will spoil it, they always do, but please don't let it be you.",
			foodie = "{player}, I'm planning a surprise party for {b} on Friday.|I've already planned the cake, three layers, and you can't tell them.",
			_ = "{player}, I'm planning a surprise party for {b} on Friday.|You won't tell them, will you?",
		}, "idea")
		s:choice("My lips are sealed.", function(c)
			say(c, "a", "Good, now act normal around them.|Very, very normal.", "sparkle")
			c:n("At the party, {b} was so surprised that they dropped a whole cake.")
			c:prop("balloons", "a")
			c:rel(10)
			c:mood("b", 8)
		end)
		s:choice("Drop them a hint.", function(c)
			c:n("You told {b} to wear something nice on Friday, for no reason at all.")
			say(c, "b", "Wait, why would I need to dress up on Friday?|...Is there a surprise party?", "sparkle")
			say(c, "a", "Who told them?|{player}, was it you?", "anger")
			c:rel(4)
			c:mood("b", 4)
		end)
		s:log("{a} planned a surprise party for {b}.")
		return s:done()
	end,
})

-- newer ones -----------------------------------------------------------------------------------------

event({
	id = "toomuchbread",
	when = "day",
	weight = W({ base = 0.11, traits = { kind = 0.1 } }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "Too much bread")
		burst(s, "a", {
			foodie = "{player}, this is a bread emergency!|I got carried away at the oven and made far too much.",
			sunny = "{player}, okay, so, I made some bread.|I made so much bread that you wouldn't believe it.",
			gentle = "I'm sorry to bother you, but have you eaten yet?|I've baked far too much bread this morning.",
			dramatic = "{player}, there has been a bread SITUATION in my kitchen.",
			nervous = "I think I made too much bread.|Is eleven loaves too many for one person?",
			gloomy = "I made too much bread.|Heh... of course I did.",
			cool = "{player}.|I made too much bread.",
			dreamy = "I was daydreaming at the oven and kept putting more loaves in...|Now there's bread everywhere.",
			bold = "{player}, I made too much bread, and I mean way too much.",
			easygoing = "So, I made bread this morning, and I sort of didn't stop.",
			proud = "{player}, I baked bread this morning, and it came out perfectly, naturally.|There's just rather a lot of it.",
			shy = "Um, {player}... I think I made too much bread.",
			cheeky = "{player} guess what|i made bread, like, way too much bread",
			prickly = "Ugh, don't say anything, but I made too much bread.",
			bookish = "{player}, I've had a small accident with a recipe.",
			polite = "Good morning, {player}, I am afraid I have baked far too much bread.",
			_ = "{player}, I made way too much bread.",
		}, "sweat")
		burst(s, "a", {
			foodie = "There are eleven loaves on the table right now.|I can't eat them all, and believe me, I've thought about it.",
			bookish = "I doubled the recipe, then doubled it again by mistake.|That's four times the bread, and I've counted every loaf.|Sorry, I'm rambling again, but what do I do with it all?",
			nervous = "There are eleven of them, and they're everywhere.|The kitchen's so full I can't even reach the sink.",
			easygoing = "I think it's eleven loaves, but I stopped counting.|They're all over the kitchen, and one of them is on my chair.",
			sunny = "There are eleven loaves, eleven!|Help me think of what to do with them all.",
			gentle = "There are eleven loaves on the table, oh my.|I can't eat them all, and I hate to waste good bread.",
			bold = "Eleven loaves, and I'm not throwing any of it out.|So what do I do with them?",
			dreamy = "There's bread on the table, on the chairs, on the windowsill...|Eleven loaves, I think, and they all smell lovely.",
			proud = "Eleven perfect loaves, if I do say so myself.|But even I can't eat that many, so what do I do?",
			shy = "There are eleven loaves, and I don't know anyone well enough to give them to.|What should I do?",
			cheeky = "eleven loaves, {player}|i could build a bread fort, but i want a better idea",
			cool = "There are eleven loaves.|What do I do with them?",
			prickly = "There are eleven loaves on my table, and I'm not eating bread for a month.|So, any ideas?",
			dramatic = "ELEVEN loaves, {player}, in one small kitchen!|I can barely get to my own sink.",
			gloomy = "There are eleven loaves, and they'll go stale before I eat even two.|Heh... what do I do with them?",
			polite = "There are eleven loaves in my kitchen, which is far too many for one person.|What would you suggest?",
			_ = "There are eleven loaves, and the kitchen's full.|What do I do with them all?",
		}, "question")
		s:choice("Share it round the street.", function(c)
			burst(c, "a", {
				sunny = "Yes, I'll knock on every door!|Everyone's getting a loaf, whether they want one or not.",
				shy = "Um, I could leave them outside people's doors.|That way I won't have to talk to anyone.",
				polite = "What a kind idea.|I'll take one to every house on the street.",
				prickly = "Fine, I'll hand them out.|If anyone asks, it was a mistake and not a present.",
				gentle = "That's a lovely idea.|I'll wrap them up and take them round this afternoon.",
				bold = "Good plan, I'm doing the whole street.|Nobody says no to free bread, right?",
				dreamy = "Share it round... yes, like the gulls share chips.|I'll leave one by every door.",
				easygoing = "Sure, I'll take them round.|One loaf at a time, with a little sit down in between.",
				proud = "A loaf for every house, from the best baker on the street.|They'll talk about it for weeks, naturally.",
				cheeky = "ok, bread delivery time|i'm ringing every doorbell and running away hehe",
				cool = "Good idea.|I'll do it now.",
				dramatic = "A gift of bread for EVERY house!|They'll remember this day.",
				bookish = "There are eleven houses on my street, actually.|Eleven loaves, eleven houses, it's perfect.",
				gloomy = "Okay, I'll hand them out.|Heh... someone will say they're not hungry, as usual.",
				foodie = "Yes, share it round!|I'll put a little pot of jam with each one.",
				nervous = "Share it round? What if people don't want it?|...No, everyone likes bread, it's fine, I'll do it.",
				_ = "That's a good idea.|I'll do the rounds this afternoon.",
			}, "sparkle", "cheer")
			c:n("By dinner time there was a loaf outside every door in the street.")
			c:all(2)
			c:mood("a", 4)
			c:memo("a", "I gave bread to the whole street, and now people keep waving at me.")
		end)
		s:choice("Have a toast morning tomorrow.", function(c)
			burst(c, "a", {
				foodie = "A toast morning, oh, you're good.|I'll bring the jam, and you bring the butter.",
				easygoing = "Toast tomorrow means less work today.|I like the way you think.",
				sunny = "A toast morning, yes, yes!|Come over at eight, and we'll eat until we can't.",
				gentle = "A toast morning, how lovely.|Come over early, okay? I'll have the butter ready.",
				bold = "Toast morning, done.|You're coming at eight, and you're bringing butter.",
				dreamy = "A toast morning... that sounds like a song.|La la ♪, toast and jam.",
				proud = "A toast morning, what a fine idea.|My toast is famous, naturally, so get ready.",
				shy = "A toast morning? Um, would you come?|(It's okay if you're busy.)",
				cheeky = "toast morning|i'm putting jam on everything, even you, jk",
				cool = "Toast tomorrow, then.|Come at eight.",
				prickly = "Toast morning, fine.|You can come if you want, or whatever.",
				dramatic = "A TOAST morning!|This is the best idea anyone has ever had.",
				bookish = "A toast morning, good.|Actually, eleven loaves make about a hundred and fifty slices, so bring friends.",
				gloomy = "A toast morning.|Heh... I'll burn the first batch, as usual, but come anyway.",
				polite = "A toast morning, what a lovely idea.|Please do come, if it is no trouble.",
				nervous = "A toast morning, okay.|What if I burn it all? ...I'll stand by the toaster, it'll be fine.",
				_ = "A toast morning, yes.|Bring butter, and lots of it.",
			}, "heart")
			c:mood("a", 3)
			c:memo("a", "Tomorrow is toast morning at mine, and you're invited, {player}.")
		end)
		s:log("{a} made too much bread.")
		return s:done()
	end,
})

event({
	id = "shellfind",
	when = "day",
	weight = W({ base = 0.11, weather = { "clear", "cloudy", "blossom", "leaves" } }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "A shell from the beach")
		s:prop("box", "a")
		burst(s, "a", {
			sunny = "{player}, look, look!|I found the most perfect shell on the beach.",
			dreamy = "I found a shell this morning.|When I hold it to my ear it sounds like the sea, which makes sense, I suppose.",
			bookish = "Look at this spiral shell I found.|Actually, it turns to the right, which is what most of them do.",
			cool = "{player}.|I found a shell on the beach this morning.",
			shy = "Um, {player}?|I found this on the beach, and I wanted to show someone.",
			dramatic = "{player}, the sea has given me a GIFT.",
			gentle = "{player}, I found such a pretty shell on the beach this morning.|I carried it home in both hands so it wouldn't break.",
			easygoing = "I was lying on the beach doing nothing, and a shell rolled right up to my hand.|It's a really nice one.",
			bold = "{player}, check this out, I found the best shell on the whole beach.",
			proud = "{player}, I found the finest shell on the beach this morning.|Naturally, I knew it was special the second I saw it.",
			cheeky = "{player} guess what i found on the beach|a shell, and no, there's no crab in it, i checked",
			prickly = "I found a shell on the beach, don't laugh.|It's actually really nice.",
			gloomy = "I found a shell on the beach, and it's not even broken.|Heh... that never happens to me.",
			polite = "Good morning, {player}, may I show you something?|I found this shell on the beach this morning.",
			foodie = "{player}, look what I found on the beach, it's the colour of a peach.|Mmm, now I want a peach.",
			nervous = "{player}, I found a shell on the beach.|I've been carrying it so carefully all morning in case I dropped it.",
			_ = "{player}, look at this shell I found on the beach.",
		}, "sparkle")
		s:say("a", "There isn't a single chip on it, so what should I do with it?", "question")
		s:choice("Put it on your windowsill.", function(c)
			burst(c, "a", {
				dreamy = "On the windowsill, yes.|That way it can still see the sea.",
				foodie = "On the windowsill, next to my jam jars.|They'll look nice together.",
				gentle = "The windowsill, yes.|I'll see it every morning when I open the curtains.",
				sunny = "The windowsill, yes!|I'll say good morning to it every day.",
				bold = "Windowsill, done.|It's going right in the middle, where everyone can see it.",
				easygoing = "The windowsill, sure.|It can sit there and do nothing all day, like me.",
				proud = "The windowsill, naturally.|Every fine house needs something fine in the window.",
				shy = "The windowsill... okay.|It'll be my little secret, by the curtain.",
				cheeky = "windowsill it is|everyone walking past can be jealous of it hehe",
				cool = "The windowsill.|Good spot.",
				prickly = "Fine, the windowsill.|Not that anyone will notice it.",
				dramatic = "The windowsill, where the whole STREET can see it!|It's like a little museum.",
				bookish = "The windowsill, good.|Actually, the sun will keep it dry there, which is best for shells.",
				gloomy = "The windowsill.|Heh... I'll knock it off by accident, as usual, but okay.",
				polite = "The windowsill, what a lovely idea.|Thank you kindly, {player}.",
				nervous = "The windowsill, okay.|What if it falls? ...I'll put a cloth under it, then it's fine.",
				_ = "The windowsill, yes.|I'll put it where the light hits it.",
			}, "heart")
			c:mood("a", 4)
			c:memo("a", "My shell is on the windowsill now, so come and see it, {player}.")
		end)
		s:choice("Give it to a friend.", function(c)
			burst(c, "a", {
				shy = "Give it to a friend? Um, I'll try.|Maybe tomorrow, when I'm feeling brave.",
				sunny = "Ooh, I know exactly who to give it to!",
				prickly = "Fine, somebody's getting a shell.|They'd better like it.",
				gentle = "Give it to a friend, oh, that's sweet.|I know just the person, and I'll wrap it in a little cloth.",
				bold = "Give it away? Hah, sure.|I know exactly who's getting it.",
				dreamy = "Give it to a friend...|Hmm, a shell is like a little piece of the sea to give someone.",
				easygoing = "Sure, I'll give it away.|I'll find someone on the way home, no rush.",
				proud = "A gift from me? They'll be thrilled, naturally.",
				cheeky = "give it away? ok|i'm putting it in someone's shoe hehe",
				cool = "Okay.|I know who'll like it.",
				dramatic = "A GIFT from the sea, passed on to a friend!|I'll tell them the whole story.",
				bookish = "Give it to a friend, good idea.|I'll write a little note saying where I found it.",
				gloomy = "Give it away? Heh... okay.|They'll probably lose it, but okay.",
				polite = "What a kind idea.|I will give it to a friend this afternoon.",
				foodie = "Give it away? Okay.|I'll put it in a box with some cookies, so it's a proper present.",
				nervous = "Give it to a friend? What if they don't like it?|...No, they'll like it, I'll do it.",
				_ = "I know someone who'd really like it.",
			}, "heart")
			c:all(1)
			c:mood("a", 2)
		end)
		s:log("{a} found a perfect shell.")
		return s:done()
	end,
})

-- front door colours, two of them offered each time
local DOORS = {
	{
		name = "sage green",
		said = {
			gentle = "Sage, yes, it's soft and calm.|It'll look lovely with the garden.",
			cool = "Green works for me.",
			dreamy = "Sage green...|Like the moss on the harbour wall.",
			sunny = "Sage green! Ehehe, it's like a leaf!|Come and help me paint it this weekend.",
			bold = "Sage green, good choice.|I'm painting it tomorrow, and you're holding the ladder, right?",
			easygoing = "Sage green, nice and calm.|I'll start painting after lunch, or after a nap.",
			proud = "Sage green, very elegant.|The whole street will copy me, naturally.",
			shy = "Sage green... I like that.|It's quiet, like me.",
			cheeky = "sage green? ok, fine, you win|my door's going to look like a big piece of lettuce hehe",
			prickly = "Sage green, fine.|It's not bad, I'll give you that.",
			dramatic = "Sage green, the colour of a QUIET forest!|My door will be a work of art.",
			bookish = "Sage green, good.|Actually, the paint shop calls it Meadow Number Four, which I like.",
			gloomy = "Sage green... that's nice, actually.|Heh... it won't show the dirt, either.",
			polite = "Sage green, what a tasteful choice.|Thank you kindly for helping me.",
			foodie = "Sage green, like the herb.|Mmm, now I want pasta with sage and butter.",
			nervous = "Sage green, okay, that's calm.|Calm is good, nothing can go wrong with calm.",
			_ = "Sage green, oh, that's nice.|It'll go with the hedge.",
		},
		memo = "My door's sage green now, and it looks like a very smart leaf.",
	},
	{
		name = "butter yellow",
		said = {
			sunny = "Yellow! Why didn't I think of that?",
			gloomy = "Yellow is very bright...|I'll get used to it, I think.",
			foodie = "Butter yellow, mmm.|I'll be hungry every time I come home.",
			gentle = "Butter yellow, oh, how cheerful.|It'll be like coming home to sunshine.",
			bold = "Butter yellow, bright and loud, I like it.|Nobody's going to miss my house now, right?",
			dreamy = "Butter yellow...|Like the light just before the sun goes down.",
			easygoing = "Butter yellow, sure.|It'll make me smile on the way back from a nap.",
			proud = "Butter yellow, a confident colour.|For a confident person, naturally.",
			shy = "Butter yellow? It's very bright...|Um, okay, I'll be brave.",
			cheeky = "butter yellow lol|people are going to try to spread my door on toast",
			cool = "Yellow, then.|I'll paint it on Saturday.",
			prickly = "Yellow? Ugh, it's so bright.|...Fine, it's actually nice.",
			dramatic = "Butter YELLOW!|My door will shine like the sun itself.",
			bookish = "Butter yellow, good choice.|Did you know yellow doors are meant to bring good luck? (I read that somewhere.)",
			polite = "Butter yellow, how very cheerful.|Thank you for your help, {player}.",
			nervous = "Yellow? What if it's too bright?|...No, it's nice, it's really nice, okay.",
			_ = "Butter yellow, that's so cheerful.|It'll brighten up the whole street.",
		},
		memo = "My door's butter yellow now, and people smile when they walk past.",
	},
	{
		name = "sky blue",
		said = {
			dreamy = "Sky blue...|It'll be like having a little bit of sky at home.",
			proud = "Sky blue, a classic choice.|It suits the house, and it suits me.",
			nervous = "Blue? Okay, blue is safe.|Blue is good, I think.",
			sunny = "Sky blue, yes, yes!|It'll look like a summer day every day.",
			gentle = "Sky blue, that's lovely.|It'll be such a calm thing to come home to.",
			bold = "Sky blue, good, done.|I'm painting it tonight.",
			easygoing = "Sky blue, easy on the eyes.|I like it, no more thinking needed.",
			shy = "Sky blue... that's nice.|Thank you for helping me choose.",
			cheeky = "sky blue|i'm painting a cloud on it too, jk",
			cool = "Sky blue, good.|I'll start tomorrow.",
			prickly = "Sky blue, hmph, fine.|It's better than what I had, anyway.",
			dramatic = "Sky blue, as BIG as the sky itself!|My door will be the talk of the street.",
			bookish = "Sky blue, nice.|It's the most common door colour in town, actually, I've counted nine.",
			gloomy = "Sky blue.|Heh... at least it's one bit of sky that won't rain on me.",
			polite = "Sky blue, a lovely choice.|Thank you kindly for helping me.",
			foodie = "Sky blue, like a blueberry milkshake.|Mmm, I'm painting it after a snack.",
			_ = "Sky blue it is, then.|Thanks for helping me choose.",
		},
		memo = "My door's sky blue now, so you can't miss my house.",
	},
}

event({
	id = "doorpaint",
	when = "day",
	weight = W({ base = 0.11 }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "A new colour")
		burst(s, "a", {
			sunny = "{player}, can you help me with something?|I'm painting my front door, and I can't decide on a colour.",
			proud = "{player}, I'm repainting my front door.|It needs a colour that says something about me.",
			nervous = "{player}, I'm painting my front door this weekend.|What if I pick a bad colour and have to look at it every day?",
			bookish = "{player}, I've got my door colours down to two.|It took me a whole week of staring at paint cards.",
			gloomy = "{player}, I'm painting my door, though it'll only peel again.|Which colour should I use, anyway?",
			dramatic = "{player}, my front door is ready for a whole new era.|All it needs is the right colour.",
			cool = "{player}.|I'm painting my door.|Pick a colour.",
			gentle = "{player}, I'm painting my front door this week.|Could you help me choose the colour?",
			dreamy = "{player}, I'm painting my front door...|I keep picturing it in different colours, and they're all nice.",
			easygoing = "{player}, I'm finally painting my front door.|I've been meaning to for about a year, no rush.|Which colour do you think?",
			bold = "{player}, I'm painting my front door this weekend.|You've got a good eye, right? Pick the colour.",
			shy = "Um, {player}, I'm painting my front door.|Could you help me pick a colour? Only if you have time.",
			cheeky = "{player} i'm painting my door|you pick the colour, and if it's ugly, everyone will know it was you hehe",
			prickly = "I'm painting my front door, don't ask why.|Just tell me which colour, I don't want to think about it.",
			polite = "Good afternoon, {player}, I am painting my front door.|Would you help me choose a colour, if it is no trouble?",
			foodie = "{player}, I'm painting my front door, and every colour on the card is named after a food.|Which one should I pick?",
			_ = "{player}, I'm painting my front door.|Which colour do you think?",
		}, "question")
		local doors = ctx.rng:shuffle(DOORS)
		for i = 1, 2 do
			local d = doors[i]
			s:choice("Go with " .. d.name .. ".", function(c)
				burst(c, "a", d.said, "heart")
				c:mood("a", 4)
				c:memo("a", d.memo)
			end)
		end
		s:log("{a} asked what colour to paint their door.")
		return s:done()
	end,
})

event({
	id = "pierwalk",
	cutscene = "pier",
	when = "night",
	weight = W({ base = 0.12, weather = { "clear", "cloudy", "snow", "blossom", "leaves" } }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "The pier")
		burst(s, "a", {
			shy = "Um, {player}?|Would you walk to the pier with me?|I don't like going out there on my own in the dark.",
			sunny = "{player}, do you want to walk down to the pier?|The stars are out, and it's so clear tonight.",
			gloomy = "I'm going down to the pier, though it'll be cold.|You could come, if you want.",
			dreamy = "{player}, the water at the pier goes silver at night.|Have you ever seen it?|Come with me...",
			nervous = "Would you come to the pier with me?|The boards creak a lot, and I keep thinking one of them will snap.",
			cool = "{player}.|I'm walking down to the pier.|Want to come?",
			prickly = "{player}, I'm going to the pier.|You can come if you want, or not, whatever.",
			polite = "Good evening, {player}.|Would you care to walk to the pier with me, if you have the time?",
			cheeky = "{player} walk to the pier with me|last one to the end buys the cocoa hehe",
			gentle = "{player}, it's such a calm night.|Would you walk down to the pier with me for a bit?",
			easygoing = "{player}, I'm wandering down to the pier.|No plan, just looking at the water, if you want to come.",
			bold = "{player}, I'm walking to the pier.|You're coming, right?",
			proud = "{player}, I'm taking an evening walk to the pier.|You may join me, if you like.",
			dramatic = "{player}, the moon is out over the pier, and it's BEAUTIFUL.|Come with me, quick, before it goes.",
			bookish = "{player}, the tide's at its highest at nine tonight.|Would you walk to the pier with me and see it?",
			foodie = "{player}, I'm walking to the pier with a bag of warm chips.|There's enough for two, if you'd like to come.",
			_ = "{player}, will you walk down to the pier with me?|It's a lovely night for it.",
		}, "question")
		s:choice("Sure, let's go.", function(c)
			c:n("You walked to the end of the pier together and listened to the water.")
			burst(c, "a", {
				shy = "Thank you for coming.|It's much nicer with two.",
				prickly = "...This was nice.|Don't tell anyone I said that.",
				gloomy = "That was actually good.|Heh... I don't get many nights like that.",
				dramatic = "I'll remember this night for the rest of the week!",
				cool = "That was a good walk.|Thanks for coming.",
				polite = "Thank you kindly, {player}.|Sleep well.",
				sunny = "That was the best walk ever!|Let's do it again next week.",
				gentle = "Thank you for coming with me.|Get home safe, okay?",
				dreamy = "The water really was silver...|Thank you for seeing it with me.",
				bold = "Good walk.|...Thanks. Anyway, same time next week, right?",
				easygoing = "That was nice and slow, just how I like it.|I could've fallen asleep out there.",
				proud = "A fine evening, and fine company.|Mostly mine, naturally, but yours too.",
				cheeky = "that was nice|you owe me cocoa though, i won hehe",
				bookish = "Thank you for coming.|Actually, I counted the boards on the way back, and there are a hundred and twelve.",
				foodie = "That was lovely, and the chips were perfect.|Let's do this again next week, and bring more chips.",
				nervous = "That was nice, and nothing snapped.|Thank you for coming, I wasn't scared at all with you there.",
				_ = "Thanks for coming.|Same time next week?",
			}, "heart")
			c:hearts("a", 1)
			c:mood("a", 5)
			c:memo("a", "{player} walked to the pier with me, and the water was all silver.")
		end)
		s:choice("Not tonight, sorry.", function(c)
			burst(c, "a", {
				shy = "Oh, okay.|That's all right, really.",
				prickly = "Fine.|I didn't want company anyway.",
				nervous = "That's fine, totally fine.|I'll just walk very fast.",
				sunny = "Aw, okay.|Next time, then, promise?",
				polite = "Of course, another time.|I'm sorry for asking so late.",
				gentle = "Oh, that's all right.|Get some rest, okay?",
				bold = "Your loss, then.|Next time, though, right?",
				dreamy = "Oh... okay.|I'll tell you what colour the water was.",
				easygoing = "Eh, it's fine.|The pier's not going anywhere.",
				proud = "Hmph, very well.|You'll miss a lovely evening, but that's your choice.",
				cheeky = "boo|fine, i'll race the gulls instead",
				cool = "Okay.|Another time.",
				dramatic = "*sob* Alone, on the pier, in the dark?|...Fine, but I'll be very brave about it.",
				bookish = "That's all right.|I'll take a book and read under the lamp at the end.",
				gloomy = "Heh... I thought so.|It's fine, I'm used to walking alone.",
				foodie = "That's okay.|More chips for me, I suppose.",
				_ = "Okay, next time, then.",
			}, "sad")
			c:mood("a", -1)
		end)
		s:default(2)
		s:log("{a} asked you to walk to the pier with them.")
		return s:done()
	end,
})

event({
	id = "showoff",
	when = "day",
	weight = W({ base = 0.1, traits = { focus = 0.2 } }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "Look what I made")
		burst(s, "a", {
			proud = "Come and look at this.|I made a stool with three legs, and it's perfectly level.",
			sunny = "{player}, I finished it!|It's my very first stool, and it actually stands up.",
			shy = "Um, {player}?|I made a stool, and I wanted to show you.|You can tell me if it's bad.",
			dramatic = "{player}, I present to you my greatest work.|It's a stool, and it's MAGNIFICENT.",
			nervous = "{player}, could you look at something for me?|I made a stool, and I need you to be honest.|...But not too honest, okay?",
			bookish = "I built a stool from a proper plan.|I followed every single step in order.",
			cool = "{player}.|I made a stool.|Take a look.",
			cheeky = "{player} i made a stool|sit on it, it's fine, i promise|...mostly fine",
			gentle = "{player}, I finished the stool I was making.|Would you come and look at it?",
			dreamy = "I made a stool...|I sanded it until it felt like a pebble.",
			bold = "{player}, come and look, I built a stool.|It's solid, right? Sit on it.",
			easygoing = "I made a stool, which took me about three weeks, with naps.|Want to see it?",
			prickly = "I made a stool, don't make a big deal of it.|Just tell me what you think.",
			gloomy = "I made a stool, and for once I actually finished something.|Here it is.",
			polite = "Good afternoon, {player}, I have made a stool.|Would you be kind enough to look at it?",
			foodie = "{player}, I made a stool, and it's almost as good as my cakes.",
			_ = "{player}, look, I made a stool.",
		}, "sparkle")
		burst(s, "a", {
			bookish = "It's perfectly level, too.|I checked it by rolling a marble across the top.",
			nervous = "It wobbles a little bit.|Is that bad? It's bad, isn't it?",
			foodie = "It's for the kitchen, so I can sit down while things bake.",
			proud = "Go on, tell me it's the finest stool you've ever seen.",
			cheeky = "so, what do you think",
			sunny = "I painted the seat yellow, too!",
			gentle = "It's for my reading corner, by the fire.",
			bold = "It held me standing up, so it's strong, right?",
			dreamy = "There's a knot in the wood that looks like a little moon...",
			easygoing = "It's mostly for putting my feet up on.",
			shy = "It's a bit small... sorry.",
			cool = "It's sturdy, I tested it.",
			prickly = "And don't say it's wonky, because it isn't.",
			dramatic = "I've given every leg a NAME.",
			gloomy = "Heh... it'll probably break the first time someone sits on it.",
			polite = "I hope it is not too rough, I sanded it as well as I could.",
			_ = "It only wobbles a tiny bit.",
		}, "question")
		s:choice("It looks really good.", function(c)
			burst(c, "a", {
				gloomy = "Really?|Heh... okay, I'll keep it, then.",
				prickly = "I know it is.|...Thanks, though.",
				shy = "...!|Thank you, really.",
				proud = "Naturally.|Go on, say it again, but louder.",
				sunny = "Really? Ehehe, I'm so happy!",
				gentle = "Oh, thank you.|I'll put it by the fire.",
				cheeky = "see, told you it was fine|it's going by my window",
				nervous = "Really? Oh, thank goodness.|I'm putting it by the window.",
				bold = "Hah, I knew it.|...Thanks. Anyway, it's going by the door.",
				dreamy = "Really...?|I'll put it by the window, where the light can sit on it too.",
				easygoing = "Thanks, I'm pretty happy with it.|Time for a sit down on it, I think.",
				cool = "Thanks.|It's going by the door.",
				dramatic = "Really? REALLY?|*gasp* I'm going to make a whole set!",
				bookish = "Thank you.|I'm already planning the next one, with four legs this time.",
				polite = "Thank you kindly, {player}.|I am really very pleased with it.",
				foodie = "Really? Yay!|I'm putting it right by the oven.",
				_ = "Really? I'm putting it by the window.",
			}, "heart")
			c:hearts("a", 1)
			c:mood("a", 5)
		end)
		s:choice("It wobbles a bit, though.", function(c)
			burst(c, "a", {
				proud = "It does not wobble.|...Th-the floor is uneven, that's all.",
				nervous = "I knew it, I knew it.|I'll fix it tonight, I promise.",
				cool = "Hm, I'll fix it tonight.",
				cheeky = "that's a feature|it rocks you gently while you sit hehe",
				gloomy = "Of course it does, as usual.",
				bookish = "But the marble didn't roll off...|Actually, I think it's my table that isn't level, so I'll check again.",
				dramatic = "WOBBLES? ...Oh. It does, doesn't it.|I'll fix it before anyone else sees.",
				sunny = "It wobbles? Ehehe, oops!|I'll fix it this afternoon, and then it'll be perfect.",
				gentle = "Oh, it does, doesn't it.|Thank you for being honest with me.",
				bold = "It wobbles? Hah, not for long.|I'm fixing it right now.",
				dreamy = "Hmm... it does rock a little, like a boat.|I sort of like it, but I'll fix it.",
				easygoing = "Eh, it's fine, it's a rocking stool now.|I'll fix it at some point.",
				shy = "Oh... sorry.|I'll fix it, I promise.",
				prickly = "Ugh, I know it wobbles.|You didn't have to say it... but thanks, I'll fix it.",
				polite = "Oh dear, you are quite right.|Thank you for telling me, I will fix it.",
				foodie = "It wobbles like a jelly, doesn't it?|I'll fix it before I put a cake on it.",
				_ = "Oh, yes, it does.|I'll put a bit of card under that leg.",
			}, "sweat")
			c:xp("a", 8)
			c:memo("a", "My stool doesn't wobble any more, because the {player} spotted it.")
		end)
		s:log("{a} showed you a stool they made.")
		return s:done()
	end,
})

event({
	id = "noisyneighbour",
	actors = 2,
	when = "any",
	weight = W({ base = 0.1, rel = -40, relMax = 40 }),
	scene = function(ctx, a, b)
		local s = K.scene(ctx, "Next door")
		burst(s, "a", {
			nervous = "{player}, could I ask you about something?|It's about {b}, and it's not a big thing, more of a medium thing.",
			polite = "{player}, I'm sorry to bring this to you.|It's about {b}'s music, which goes on rather late at night.",
			prickly = "{player}, it's {b} again.|Their music was going until midnight, and I've had enough.",
			gloomy = "{b}'s music goes on all night, every night.|I haven't slept properly in days, as usual.",
			easygoing = "Hey, {player}.|{b}'s been playing music really late.|I don't mind much, but even I can't nap through it.",
			bold = "{b} plays music until midnight every night.|I'm about to go round there.",
			shy = "Um, {player}, {b}'s music keeps me awake.|I don't know how to tell them.",
			gentle = "{player}, I don't like to complain.|{b}'s music goes on very late, and I'm so tired.",
			dreamy = "{b}'s music drifts over the fence every night...|It's nice music, but it goes on until midnight.",
			sunny = "I love music, I really do.|But {b} plays it until midnight, and I'm so tired.",
			proud = "{player}, I have a complaint, and I don't make complaints lightly.|{b}'s music goes on far too late.",
			cheeky = "{player} {b}'s music goes until midnight|i've been singing along through the wall to annoy them, but it's not working",
			cool = "{b} plays music until midnight.|I can't sleep.",
			dramatic = "{player}, I haven't SLEPT in days.|{b}'s music goes on until midnight, every single night.",
			bookish = "{b}'s music goes on until twelve every night.|I've been keeping a note, and it's eleven nights in a row.",
			foodie = "{b}'s music goes on so late that I can't sleep.|I've started having midnight snacks to pass the time, and that can't go on.",
			_ = "{b} plays music really late every night.|I haven't had a proper night's sleep all week.",
		}, "sweat")
		s:say("a", "What should I do about it?", "question")
		s:choice("Knock and ask nicely.", function(c)
			burst(c, "a", {
				shy = "You want me to knock on their door?|...Okay, I'll knock very quietly.",
				bold = "Fine, I'll be nice about it.|I'm going over now.",
				prickly = "Ugh, fine, I'll be nice about it.",
				gentle = "You're right, I'll just ask them gently.",
				sunny = "Okay, I'll knock and ask nicely!|Maybe I'll take them a cookie too.",
				dreamy = "Ask nicely... okay.|Maybe they don't know how far music carries at night.",
				easygoing = "Sure, I'll go and ask nicely.|No need to make a big thing of it.",
				proud = "Very well, I'll be gracious about it.|I'm very good at being gracious.",
				cheeky = "ok, nicely|i'll only knock once, which is very nice for me",
				cool = "Okay.|I'll go now.",
				dramatic = "Very well, I'll be CALM about it.|Watch me be calm.",
				bookish = "Asking nicely works most of the time, I've read.|I'll go over now.",
				gloomy = "Okay, I'll ask.|Heh... they'll probably turn it up.",
				polite = "Yes, that is the proper thing to do.|I will go over now.",
				foodie = "Okay, I'll ask nicely.|I'll take them some cookies, since nobody says no to someone with cookies.",
				nervous = "Knock on their door? Oh no, oh no.|...Okay, I'll do it, quickly, before I get scared.",
				_ = "Okay, I'll go and ask nicely.",
			}, "sweat")
			burst(c, "b", {
				cheeky = "was it too loud? hehe sorry|i'll put the quiet records on",
				proud = "Too loud? But it's good music.|...Fine, I'll turn it down.",
				gloomy = "Sorry, I didn't think anyone could hear it.",
				polite = "Oh, I'm so sorry about that.|I'll keep it down, and thank you for telling me.",
				dramatic = "My music kept you AWAKE?|I'm so embarrassed, and it stops at nine from now on.",
				nervous = "Oh no, was it really that loud?|Has it been every night? I'm so sorry.",
				gentle = "Oh, my, I'm so sorry.|I'll keep it down from now on.",
				sunny = "Oh no, was it too loud? Sorry, sorry!|I'll turn it down, and let's listen together some time.",
				bold = "Too loud? Fair enough.|I'll turn it off at ten, deal?",
				dreamy = "Oh... I didn't think it went that far.|I'll play it softly, like a lullaby.",
				easygoing = "Oh, was it loud? Sorry.|I'll turn it down, no problem.",
				shy = "Oh no, I'm so sorry...|I'll keep it really quiet from now on.",
				cool = "Sorry.|I'll stop at ten.",
				prickly = "Ugh, fine, I'll turn it down.|...Sorry, I didn't know you could hear it.",
				bookish = "Oh, I'm sorry.|Actually, sound carries further at night, I should have thought of that.",
				foodie = "Oh no, sorry!|Here, take some cake, and I'll keep it down from now on.",
				_ = "Oh, sorry about that.|I'll turn it down.",
			}, "heart")
			c:rel(6)
			c:mood("a", 4)
		end)
		s:choice("Ask {b} for a song you like.", function(c)
			say(c, "a", "Ask them to play something I like, you mean?|Huh, I hadn't thought of that.", "idea")
			c:n("That night {a} knocked on {b}'s door with a song request.")
			burst(c, "b", {
				sunny = "You like my music? Ehehe, that's the best!|I'll play your song tomorrow, nice and early.",
				gentle = "Oh, my, a request!|I'll play it tomorrow evening, and not so late this time.",
				bold = "Hah, a request? Now we're talking.|I'll play it at a sensible hour, too.",
				dreamy = "You've been listening to my music...?|I'll play your song at sunset, then, and stop before it gets late.",
				easygoing = "Oh, nice, a request.|I'll play it early, before my nap.",
				proud = "Hmph, so you've been enjoying my music.|I'll play it tomorrow, and earlier, since you asked so nicely.",
				shy = "Oh... you've been listening?|Um, I'll play it tomorrow, and I'll stop earlier.",
				cheeky = "a request? ok, i'm flattered|i'll play it tomorrow, before bedtime, promise",
				cool = "Good choice.|I'll play it tomorrow, and I'll stop at nine.",
				prickly = "Ugh, fine, I'll play your song.|...And I'll stop earlier, since the walls are so thin.",
				dramatic = "A REQUEST? I have fans?|I'll play it tomorrow, and I'll finish by nine, I promise.",
				bookish = "Oh, that's a good one, actually.|I'll play it tomorrow, and I'll keep an eye on the time.",
				gloomy = "Someone actually likes my music? Heh...|I'll play it tomorrow, and not so late.",
				polite = "What a lovely request.|I'll play it tomorrow evening, at a more sensible hour.",
				foodie = "Ooh, that's my favourite song to cook to!|I'll play it at dinner time tomorrow instead of midnight.",
				nervous = "Y-you've been hearing it every night? Oh no.|I'll play your song tomorrow, and I'll stop much earlier.",
				_ = "A request? Sure, I'll play it tomorrow.|And I'll stop a bit earlier, too.",
			}, "music", "cheer")
			c:rel(4)
			c:mood("a", 2)
			c:mood("b", 3)
		end)
		s:log("{a} asked what to do about {b}'s late music.")
		return s:done()
	end,
})

event({
	id = "islelights",
	when = "day",
	weight = W({ base = 0.1, traits = { focus = -0.1 } }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "Lights on the islet")
		burst(s, "a", {
			nervous = "I saw something strange last night.|There were three lights moving around on the islet.",
			dramatic = "{player}, last night I saw something I cannot EXPLAIN.|There were lights on the islet, and they were moving!",
			bookish = "I saw lights on the islet last night.|I wrote down the times they appeared, if you'd like to see.",
			gloomy = "I saw lights on the islet last night.|It's nothing, I'm sure, it's always nothing.",
			dreamy = "{player}, there were little lights on the islet last night.|They looked like they were dancing...",
			cool = "{player}.|I saw lights on the islet last night.|That's odd, isn't it?",
			cheeky = "{player} guess what|i saw lights on the islet last night|spooky hehe",
			gentle = "{player}, did you see the lights on the islet last night?|I was worried someone was stuck out there.",
			sunny = "{player}, guess what I saw last night!|There were lights on the islet, and they were moving.",
			bold = "{player}, I saw lights on the islet last night.|Somebody's out there, right? I want to know who.",
			easygoing = "I was sitting outside half asleep last night, and I saw lights on the islet.|I figured I was dreaming, but they kept moving.",
			proud = "{player}, I saw lights on the islet last night, and I'm never wrong about these things.|They were moving.",
			shy = "Um, {player}, I saw lights on the islet last night.|I didn't tell anyone, in case they laughed.",
			prickly = "Don't laugh, but I saw lights on the islet last night.|They were moving, and I wasn't imagining it.",
			polite = "Good morning, {player}, I saw something rather strange last night.|There were lights moving about on the islet.",
			foodie = "I was up late for a midnight snack, and I saw lights on the islet.|They were moving around, like someone carrying lanterns.",
			_ = "{player}, I saw lights out on the islet last night.|They were moving around, as if someone was walking with lanterns.",
		}, "question")
		s:say("a", "There's nobody living out there, is there?", "question")
		s:choice("Fishing boats, I bet.", function(c)
			burst(c, "a", {
				nervous = "Boats, yes, boats are normal.|Phew, okay.",
				dramatic = "Boats, of course.|How dull, and what a relief.",
				bookish = "Boats would explain why they were moving.|Good thinking.",
				gloomy = "Boats, that's the boring answer.|You're right, though.",
				gentle = "Oh, boats, of course.|I'm glad nobody's stuck out there.",
				sunny = "Boats! Of course, of course.|Ehehe, I got all worked up over nothing.",
				bold = "Boats, right.|I was hoping for something more exciting, though.",
				dreamy = "Boats... hmm, little boats with little lanterns.|That's nice too.",
				easygoing = "Boats, sure, that makes sense.|Good, now I can stop thinking about it.",
				proud = "Boats, of course.|I'd have worked that out myself, naturally.",
				shy = "Oh... boats.|Sorry, I feel a bit silly now.",
				cheeky = "boats? boring|i was hoping for ghosts hehe",
				cool = "Boats.|That makes sense.",
				prickly = "Boats, obviously.|I knew that, I was just checking.",
				polite = "Fishing boats, of course.|Thank you, that is a relief.",
				foodie = "Fishing boats, out at night...|Mmm, so there'll be fresh fish at the market tomorrow.",
				_ = "Oh, boats, that makes sense.",
			}, "sweat")
			c:mood("a", 2)
		end)
		s:choice("Let's watch for them tonight.", function(c)
			burst(c, "a", {
				bold = "Yes! I'll bring a flashlight.",
				nervous = "Tonight, together?|Okay, as long as we're together.",
				cheeky = "a stakeout|i'll bring the snacks",
				sunny = "Yes, yes, a night watch!|Let's bring blankets and cocoa.",
				gentle = "Tonight, then.|Wear something warm, okay? It gets cold by the water.",
				dreamy = "Tonight... yes.|Maybe they'll dance again.",
				easygoing = "Sure, tonight.|I'll bring a blanket, in case I fall asleep.",
				proud = "Very well, I'll keep watch.|I have excellent eyes, naturally.",
				shy = "Tonight? Um, okay...|I'll stand next to you, if that's all right.",
				cool = "Tonight, then.|Bring a coat.",
				prickly = "Fine, tonight.|It's not like I was going to sleep anyway.",
				dramatic = "A secret night WATCH!|This is the most exciting thing that's ever happened to me.",
				bookish = "Tonight, good.|I'll bring my notebook and write down every time we see them.",
				gloomy = "Tonight, okay.|Heh... they won't show up now that we're looking, as usual.",
				polite = "Tonight, then, thank you.|I will meet you by the harbour after dinner.",
				foodie = "Tonight! I'll bring snacks.|You can't watch for lights on an empty stomach.",
				_ = "Tonight, then.|Meet me by the harbour.",
			}, "sparkle")
			c:n(
				"That night you watched from the harbour wall. Three small lights moved slowly across the islet, then went out."
			)
			burst(c, "a", {
				gloomy = "See, I told you.|Nobody ever believes me.",
				dramatic = "We're official witnesses now, {player}.",
				gentle = "So there really was someone out there.|I hope they got home safe.",
				nervous = "See? I wasn't imagining it.|...Now I'm going to lie awake wondering.",
				sunny = "We saw them, we saw them!|Let's come back tomorrow night too.",
				bold = "There, I knew it.|We're finding out who it was, right?",
				dreamy = "They really were dancing...|Hmm, maybe some things don't need explaining.",
				easygoing = "Huh, so it was real.|Well, I'm going to bed now, that was a lot.",
				proud = "I told you, didn't I?|I'm never wrong about these things.",
				shy = "You saw them too...|I'm glad I'm not the only one.",
				cheeky = "ok that was actually spooky|not funny spooky, real spooky",
				cool = "So it's real.|We'll watch again tomorrow.",
				prickly = "See? I wasn't making it up.|...Thanks for staying with me.",
				bookish = "Three lights, gone at ten past eleven.|I'm writing all of this down.",
				polite = "How very strange.|Thank you for keeping me company tonight.",
				foodie = "We saw them!|I need a hot drink after that, and maybe a pie.",
				_ = "...See?|I told you there was something.",
			}, "sparkle")
			c:hearts("a", 1)
			c:mood("a", 4)
			c:memo("a", "{player} saw the islet lights too, so now we're both keeping watch.")
		end)
		s:log("{a} saw lights on the islet.")
		return s:done()
	end,
})

event({
	id = "marketnerves",
	when = "any",
	weight = W({ base = 0.12, job = "any" }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "Tomorrow"):with({ job = K.workplace(ctx, a) })
		burst(s, "a", {
			nervous = "{player}, it's a big day at the {job} tomorrow.|What if nobody comes?|What if everybody comes at once?",
			gloomy = "Tomorrow's a big day at the {job}.|It'll go wrong, because things usually do.",
			proud = "{player}, I'm running the {job} on my own tomorrow.|I'm not nervous.|...Well, maybe a little.",
			sunny = "Tomorrow's a big day at the {job}!|I'm excited, but I also feel a bit sick.",
			polite = "{player}, may I ask your advice?|Tomorrow is a very big day at the {job}.",
			shy = "Um, {player}, it's a big day at the {job} tomorrow.|There are going to be so many people.",
			bold = "It's a big day at the {job} tomorrow.|I'm ready for it, mostly.",
			gentle = "{player}, tomorrow's a big day at the {job}.|I want everyone to have a nice time, and I'm a little nervous.",
			dreamy = "Tomorrow's a big day at the {job}...|I dreamed I forgot to open the door.",
			easygoing = "{player}, tomorrow's a busy one at the {job}.|I'll have to be awake the whole day, which is a lot.",
			cheeky = "{player} big day at the {job} tomorrow|i'm totally fine, i'm only shaking a little bit hehe",
			cool = "It's a big day at the {job} tomorrow.|I'd like it to go well.",
			prickly = "It's a big day at the {job} tomorrow, and I'm not nervous.|Stop looking at me like that.",
			dramatic = "{player}, tomorrow is the BIGGEST day of my life at the {job}.|Possibly of anyone's life.",
			bookish = "Tomorrow's a big day at the {job}.|I've made a plan for every hour, and I've checked it three times.",
			foodie = "Tomorrow's a big day at the {job}.|I'm so nervous I've only eaten two lunches today.",
			_ = "Tomorrow's a big day at the {job}.|I keep going over everything in my head.",
		}, "sweat")
		s:choice("You'll be great.", function(c)
			burst(c, "a", {
				gloomy = "You think so?|...Okay, I'll try thinking so too.",
				nervous = "Oh, okay.|Thank you, I needed to hear that.",
				prickly = "Obviously.|...Thanks, though.",
				shy = "...!|Thank you.",
				gentle = "Thank you, that's kind of you.|I'll get a good night's sleep and do my best.",
				sunny = "You think so? Ehehe, okay!|I'll do my best, my very best.",
				bold = "Hah, I know.|...Thanks. Anyway, I'd better get some sleep.",
				dreamy = "Hmm... you think so?|I'll hold on to that tomorrow.",
				easygoing = "Thanks, that helps.|I'll have an early night, and it'll be fine.",
				proud = "Naturally, I'll be great.|...But thank you for saying it.",
				cheeky = "obviously|but thanks, you're not so bad yourself",
				cool = "Thanks.|I'll be ready.",
				dramatic = "You believe in me?|*sob* That's all I needed!",
				bookish = "Thank you.|Actually, I've got a plan for every hour, so I feel better now.",
				polite = "Thank you kindly, that is very kind of you to say.|I will do my very best.",
				foodie = "Thanks, {player}.|I'll eat a big breakfast and give it everything.",
				_ = "Thanks, I really needed to hear that.",
			}, "heart")
			c:mood("a", 6)
		end)
		s:choice("Practise on me now.", function(c)
			c:n("{a} ran through the whole day out loud while you played everyone who might turn up.")
			burst(c, "a", {
				cheeky = "you were a terrible customer|perfect practice, honestly",
				bookish = "That really helped.|I found two things I need to fix.",
				nervous = "Okay, okay.|I didn't drop anything, so that's a start.",
				sunny = "That was so fun!|Let's do it again before I go to bed.",
				gentle = "Thank you for helping me, that was sweet of you.|I feel much calmer now.",
				bold = "Good practice.|Tomorrow's going to be easy, right?",
				dreamy = "Hmm... I think I remember everything now.|Thank you for being all those people.",
				easygoing = "Okay, that helped.|Now I can relax for the rest of the evening.",
				proud = "Hmph, I was excellent, as expected.|You were a fine customer too.",
				shy = "Thank you...|I feel a little braver now.",
				cool = "That helped.|I'm ready.",
				prickly = "That helped, a bit.|Don't tell anyone how good you were at playing a grumpy customer.",
				dramatic = "A practice run, and a SUCCESS!|Tomorrow will be the real show.",
				gloomy = "Okay, that went better than I thought.|Heh... maybe tomorrow will too.",
				polite = "Thank you kindly for your time.|I feel much better prepared now.",
				foodie = "That helped, thanks.|Let's get a snack, I've earned one.",
				_ = "Okay, I think I've got it now.",
			}, "sparkle")
			c:xp("a", 10)
			c:mood("a", 4)
		end)
		s:log("{a} was nervous about a big day at work.")
		return s:done()
	end,
})

event({
	id = "soupsalt",
	cutscene = "kitchen",
	when = "day",
	weight = W({ base = 0.1 }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "Taste this")
		burst(s, "a", {
			foodie = "Come and taste this!|Quickly, before it goes cold.",
			sunny = "{player}, will you try my soup?|Tell me the truth, but the nice version.",
			nervous = "{player}, could you taste this for me?|I've tasted it forty times, and I can't tell any more.",
			proud = "Try my soup.|You'll be the second person to call it perfect, after me.",
			bookish = "I made soup, and I followed the recipe exactly.|Something's still missing, though, so could you try it?",
			gloomy = "{player}, I made soup.|It needs something, like everything I make.",
			cool = "{player}.|I made soup, so will you taste it?",
			gentle = "{player}, have you eaten yet?|I made soup, and I'd love you to try it.",
			dreamy = "{player}, I made soup...|It tastes like something's missing, but I can't tell what.",
			easygoing = "I made soup, and I've tasted it so many times that I can't tell any more.|Can you try it?",
			bold = "{player}, taste this soup.|Be honest, right? I can take it.",
			shy = "Um, {player}, I made soup.|Would you taste it? (It's okay if not.)",
			cheeky = "{player} taste my soup|i only put one weird thing in it, jk, it's normal",
			prickly = "I made soup, and I need someone to taste it.|You're here, so you'll do.",
			dramatic = "{player}, I've made a soup, and it might be my MASTERPIECE.|Or it might be a disaster, so taste it, quick.",
			polite = "Good afternoon, {player}, I have made soup.|Would you taste it for me, please?",
			_ = "{player}, will you taste my soup?|I can't tell if it needs salt.",
		}, "question")
		s:choice("Add a pinch of salt.", function(c)
			burst(c, "a", {
				foodie = "Mmm, just a pinch, yes!|You've got the tongue for this.",
				gloomy = "Salt, yeah.|...That's better, annoyingly.",
				gentle = "A pinch of salt, yes.|Oh, that's much better, thank you.",
				sunny = "A pinch of salt, yes!|Ehehe, now it's perfect, perfect!",
				bold = "Salt, right, I knew it.|Now it's good.",
				dreamy = "A pinch of salt...|Oh, now it tastes like it's supposed to.",
				easygoing = "Salt, sure.|Mm, that fixed it, easy.",
				proud = "A pinch of salt, naturally.|I was about to add it myself.",
				shy = "Salt... oh, that's much better.|Thank you.",
				cheeky = "salt? ok|oh, ok, you were right, but don't get a big head",
				cool = "Salt, then.|Better, thanks.",
				prickly = "Ugh, salt, of course.|...Fine, it's better, thanks.",
				dramatic = "SALT! Of course!|You've saved my soup.",
				bookish = "A pinch of salt, good.|Actually, salt brings out the other flavours, which is why it works.",
				polite = "A pinch of salt, thank you.|That is very much better.",
				nervous = "Just a pinch? Okay, a tiny pinch.|...Oh, that's better, phew.",
				_ = "Just a pinch of salt...|Oh, that's it, that's exactly it.",
			}, "sparkle")
			c:mood("a", 4)
			c:xp("a", 5)
		end)
		s:choice("It's perfect as it is.", function(c)
			burst(c, "a", {
				proud = "I know it is.|I just wanted to hear someone say it.",
				nervous = "Really? You'd tell me if it wasn't?|Okay, okay, I believe you.",
				gloomy = "Perfect? Heh... that's a first.|I'll leave it alone, then.",
				cool = "Hm, good.|I'll leave it, then.",
				sunny = "Perfect? Yay, ehehe!|Stay for a bowl, there's loads.",
				gentle = "Oh, I'm so glad.|Stay and have a bowl, okay? You look hungry.",
				bold = "Perfect, right?|I knew it was.",
				dreamy = "Perfect...|I'll stop stirring, then, and just watch it.",
				easygoing = "Great, then I'm done.|Less work for me.",
				shy = "Really?|Thank you... that makes me happy.",
				cheeky = "perfect? you're just being nice|ok, i'll take it",
				prickly = "Obviously it is.|...Thanks.",
				dramatic = "PERFECT?|I may cry into the soup.",
				bookish = "Perfect, good.|I'll write down exactly what I did, then.",
				polite = "Thank you kindly, I am so glad you like it.|Would you stay for a bowl?",
				foodie = "Yes, yum!|Now grab a spoon, it's best while it's hot.",
				_ = "Really? Oh, good, I'm glad.|I'll stop fiddling with it, then.",
			}, "heart")
			c:mood("a", 5)
		end)
		s:log("{a} asked you to taste their soup.")
		return s:done()
	end,
})

event({
	id = "lettergran",
	when = "any",
	weight = W({ base = 0.1 }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "A letter to Grandma")
		s:prop("parcels", "a")
		burst(s, "a", {
			bookish = "I'm writing a letter to my grandma.|I'm already on page four, so is that too long?",
			gloomy = "I'm writing to my grandma.|Nothing happens here that's worth putting in a letter, though.",
			dramatic = "{player}, I'm writing my grandma a letter she'll keep FOREVER.|...I've been stuck on the second line for an hour.",
			cool = "{player}.|I'm writing to my grandma, and I'm stuck.",
			shy = "Um, {player}, I'm writing to my grandma.|What do people usually put in letters?",
			polite = "{player}, I am writing to my grandmother this afternoon.|Would you help me decide what to say?",
			sunny = "I'm writing a letter to my grandma.|I want to tell her everything, but I don't know where to start.",
			gentle = "I'm writing to my grandma.|I want her to know I'm happy here and eating properly, but I don't know what to say.",
			dreamy = "I've been writing to my grandma...|So far it just says 'Dear Grandma'.",
			easygoing = "I'm writing to my grandma, and I've done the 'Dear Grandma' part.|That took me all morning, so what comes next?",
			proud = "I'm writing to my grandma, and she does love hearing how well I'm doing.|Naturally, there's a lot to tell, so where do I start?",
			cheeky = "{player} i'm writing to my grandma|i want to put something in that makes her laugh",
			prickly = "I'm writing to my grandma, and don't make that face.|I just don't know what to put.",
			foodie = "I'm writing to my grandma, who taught me to make pancakes.|I want to tell her everything, but I don't know where to start.",
			nervous = "I'm writing to my grandma, and she hasn't heard from me in weeks.|What if she thinks I forgot her? What do I even say?",
			bold = "{player}, I'm writing to my grandma, and I'm stuck after one line.|You're good with words, right? Help me out.",
			_ = "I'm writing to my grandma, and I don't know what to put.|She always wants to hear everything.",
		}, "question")
		s:choice("Tell her about the town.", function(c)
			burst(c, "a", {
				gloomy = "The town, okay...|Actually, I could tell her about the gulls on the pier, and about you.",
				sunny = "The town, yes!|I'll start with the bakery, because she loves bread more than anyone.",
				gentle = "The town, yes.|She'll love hearing about the gardens.",
				dreamy = "The town...|I'll tell her how the harbour looks in the evening.",
				bold = "The town, right.|I'll tell her about the harbour, and that I'm doing great.",
				easygoing = "The town, sure.|I'll tell her it's quiet and I nap a lot, she'll like that.",
				proud = "The town, naturally, and my part in it.|She'll be so proud of me.",
				shy = "The town... okay.|I'll tell her about the people who are nice to me.",
				cheeky = "the town, ok|i'm telling her about the gull that stole my sandwich hehe",
				cool = "The town.|Good idea.",
				prickly = "The town, fine.|I'll leave out the noisy neighbours, or whatever.",
				dramatic = "The TOWN, yes!|I'll write about every single person, and she'll be reading for a week.",
				bookish = "The town, good.|I'll tell her about the library, it has four thousand books, actually.",
				polite = "The town, what a good idea.|She will be pleased to hear how kind everyone is.",
				foodie = "The town, yes!|I'll start with the bakery, and the fish stall, and the cake shop...",
				nervous = "The town, okay, that's safe.|I'll tell her I'm happy, so she won't worry.",
				_ = "The town, yes.|She'd really like that.",
			}, "idea")
			c:mood("a", 4)
			c:memo("a", "I told my grandma all about the town, and now she wants to know who the {player} is.")
		end)
		s:choice("Keep it short and sweet.", function(c)
			burst(c, "a", {
				bookish = "Four pages down to one, then...|That hurts, but you're right.",
				sunny = "Short and sweet, okay!|'Dear Grandma, I'm happy, come and visit!'",
				gentle = "Short and sweet, yes.|She'll just be happy to hear from me.",
				bold = "Short, good.|Three lines and done, right?",
				dreamy = "Short and sweet...|Like a little poem, maybe.",
				easygoing = "Short, great, less writing.|I'll be done before lunch.",
				proud = "Short and sweet, like me.|Well, sweet, anyway.",
				shy = "Short is good.|I'm not very good at writing long letters anyway.",
				cheeky = "short? ok|'dear grandma, still alive, love you, bye' hehe",
				cool = "Short, then.|I'll finish it now.",
				prickly = "Short, fine.|She knows I'm not one for long letters anyway.",
				dramatic = "Short?|...Fine, short, but every word will be BEAUTIFUL.",
				gloomy = "Short, then.|Heh... I didn't have much to say anyway.",
				polite = "Short and sweet, then, thank you.|She will be happy to hear from me.",
				foodie = "Short and sweet, like a cookie.|I'll put a recipe in at the end.",
				nervous = "Short? What if she thinks I don't care?|...No, short is fine, she'll be happy, okay.",
				_ = "Short, then.|'Dear Grandma, all is well here, lots of love,' and that's it.",
			}, "sweat")
			c:mood("a", 2)
		end)
		s:log("{a} wrote a letter to their grandma.")
		return s:done()
	end,
})

event({
	id = "droopyplant",
	when = "day",
	weight = W({ base = 0.1 }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "A sad plant")
		burst(s, "a", {
			gentle = "{player}, my plant's drooping.|I've been looking after it, but I don't know what it needs.",
			nervous = "{player}, my plant's drooping.|Is it dying? Is it my fault?",
			gloomy = "My plant's drooping.|Heh... everything I look after does, sooner or later.",
			dramatic = "{player}, my fern is WILTING.|I can't bear to look at it.",
			bookish = "My plant's drooping.|I've ruled out three causes, and there are seven left on my list.",
			dreamy = "{player}, my plant's leaning over like it's tired...|I think it's sad about something.",
			sunny = "My plant's gone all droopy, and I don't know why.|Can you help me work out what it needs?",
			bold = "{player}, my plant's drooping, and I want it fixed today.|You know plants, right?",
			easygoing = "My plant's gone all floppy, and I think it's tired.|I know the feeling, but I'd like it to cheer up.",
			proud = "My plant is drooping, which is very strange, since I look after it perfectly.|What could it possibly need?",
			shy = "Um, {player}, my plant's drooping...|I'm sorry, I didn't know who else to ask.",
			cheeky = "{player} my plant's being dramatic|it's all floppy and sad and i didn't even do anything this time",
			cool = "My plant's drooping.|What does it need?",
			prickly = "My plant's drooping, and I've done everything right.|Ugh, just tell me what's wrong with it.",
			polite = "Good morning, {player}, I am a little worried about my plant.|It has started to droop, and I do not know why.",
			foodie = "My plant's drooping, and it's my basil, so this is serious.|What do I do?",
			_ = "My plant's gone all droopy.|I don't know what's wrong with it.",
		}, "sad")
		-- one of the two fixes works, this time
		local works = ctx.rng:pick({ 1, 2 })
		local function after(c, ok)
			if ok then
				c:n("By the next morning it was standing up straight again.")
				burst(c, "a", {
					gloomy = "It's alive...|Huh, something actually went right.",
					dramatic = "It LIVES!|You saved it, {player}.",
					gentle = "Oh, my, it's standing up straight again.|Thank you, I was so worried about it.",
					sunny = "It's better, it's better!|Ehehe, thank you, let's celebrate with lemonade.",
					bold = "Hah, look at it now.|Good call, {player}, right on the first try.",
					dreamy = "It's standing tall again...|I think it's happy, it's leaning towards me.",
					easygoing = "Oh, nice, it's awake again.|That was easy, thanks.",
					proud = "It's doing wonderfully, naturally.|With a little help from you, I'll admit.",
					shy = "It's better...!|Thank you so much, {player}.",
					cheeky = "it lives hehe|ok, you're officially the plant doctor now",
					cool = "It's better.|Thanks.",
					prickly = "Huh, it's fine now.|...Thanks, I guess, but don't let it go to your head.",
					bookish = "It's better, and that's one cause ticked off my list.|Thank you, I'll write down what worked.",
					polite = "It looks so much better, thank you kindly.|I am very grateful.",
					foodie = "It's better! My basil is saved.|Come round for pasta when it's grown, okay?",
					nervous = "It's better? It's really better?|Oh, thank goodness, I was so scared.",
					_ = "Look, it's perked right up.|Thank you, I was really worried about it.",
				}, "sparkle", "cheer")
				c:mood("a", 5)
				c:memo("a", "My plant's doing really well now, because the {player} knew what it needed.")
			else
				c:n("By the next morning it was drooping a little more.")
				burst(c, "a", {
					nervous = "It's worse, it's definitely worse.|Okay, should we try the other thing?",
					sunny = "Oh no, it's droopier!|Okay, okay, we'll try the other thing tomorrow.",
					gentle = "Oh my, it's worse, poor thing.|I'll try something else, and keep a close eye on it.",
					bold = "Worse? Right, that wasn't it.|We'll try the other thing, then.",
					dreamy = "It's drooping more...|Hmm, maybe it wanted something else.",
					easygoing = "Huh, it's worse.|Eh, plants are tricky, I'll try something else.",
					proud = "Worse? That can't be right.|Th-the plant is just being difficult.",
					shy = "It's worse... sorry, I must have done it wrong.",
					cheeky = "ok it's worse|that one's on you, plant doctor",
					cool = "It's worse.|Wrong guess, then.",
					prickly = "Ugh, it's worse.|Not your fault, I suppose, or whatever.",
					dramatic = "It's WORSE! *sob*|Hold on, little plant, we're not giving up.",
					bookish = "It's worse, so that's one cause ruled out.|Six left on my list.",
					gloomy = "Worse, as usual.|Heh... I knew it.",
					polite = "Oh dear, it has drooped a little more.|Thank you for trying, all the same.",
					foodie = "It's worse, my poor basil.|I'll try something else before it's too late for pasta.",
					_ = "Oh, it wasn't that, then.|I'll try something else tomorrow.",
				}, "sweat")
				c:mood("a", -1)
			end
		end
		s:choice("Give it more water.", function(c)
			burst(c, "a", {
				nervous = "Not too much, though, right?|How much is too much? Okay, one cup.",
				sunny = "Water, yes! Drink up, little plant!",
				gentle = "A drink, of course.|There you go, little one.",
				bold = "Water, right.|I'm giving it a big drink right now.",
				dreamy = "A drink...|La la ♪, here's some water for you.",
				easygoing = "Water, easy enough.|I'll give it a drink and then have one myself.",
				proud = "Water, naturally, I was about to do that.",
				shy = "Water... okay.|I hope that's what it wanted.",
				cheeky = "water? ok, here you go, plant|don't say i never do anything for you",
				cool = "Water, then.|Done.",
				prickly = "Water, fine.|You'd better cheer up, plant.",
				dramatic = "Water! The gift of LIFE!|Drink, little plant, drink.",
				bookish = "More water, good.|I'll give it exactly one cup and check it in the morning.",
				gloomy = "Water, then.|Heh... it'll probably drown now.",
				polite = "More water, of course.|Thank you for the advice.",
				foodie = "Water, okay.|Like soup, but for plants.",
				_ = "Water, okay.|A big drink for you, then.",
			}, "idea")
			after(c, works == 1)
		end)
		s:choice("Move it into the sun.", function(c)
			burst(c, "a", {
				dreamy = "The sun, yes...|It's been stuck in the corner, poor thing.",
				sunny = "The sun, yes! Plants love the sun as much as I do.",
				gentle = "Into the sun, yes.|A little warmth will do it good.",
				bold = "Sun, right.|It's going on the windowsill right now.",
				easygoing = "The sun, sure.|It can have my sunny spot, and I'll nap somewhere else.",
				proud = "The sun, naturally.|The best spot in the house, for the best plant.",
				shy = "The sun... okay.|I'll put it by the window.",
				cheeky = "sun it is|go get a tan, plant",
				cool = "The sun.|I'll move it.",
				prickly = "Fine, the sun.|It had better be grateful.",
				dramatic = "Into the LIGHT!|Go, little plant, go and be free.",
				bookish = "Sunlight, good.|Plants need about six hours a day, so the windowsill it is.",
				gloomy = "The sun, okay.|Heh... it'll get too much now, as usual.",
				polite = "Into the sun, of course.|Thank you for the suggestion.",
				foodie = "The sun, yes.|Basil loves the sun, just like tomatoes do.",
				nervous = "The sun? What if it burns?|...Okay, just the morning sun, then.",
				_ = "Into the sun, then.|The windowsill it is.",
			}, "idea")
			after(c, works == 2)
		end)
		s:log("{a}'s plant was drooping.")
		return s:done()
	end,
})

event({
	id = "rainyday",
	when = "day",
	weight = W({ base = 0.3, weather = { "rain", "storm" } }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "A rainy day")
		burst(s, "a", {
			sunny = "{player}, it's raining so hard!|I've been pacing round my room all morning, so what do I do?",
			easygoing = "It's raining, which is a great excuse to do nothing.|Or something, I suppose, if you've got ideas.",
			bold = "It's raining too hard to go anywhere.|I've been stuck inside all morning, and I can't sit still any longer.",
			dreamy = "It's raining...|I could do anything today, and that's the trouble.",
			gloomy = "It's raining, of course.|What does anyone even do on a day like this?",
			nervous = "It's raining, and it doesn't look like it'll stop.|What if it rains all day and I just sit here?",
			gentle = "It's pouring out there, so stay dry, okay?|I'm stuck inside and can't think what to do.",
			cheeky = "{player} it's raining|i'm bored already and it's only been an hour|give me something to do",
			proud = "{player}, the rain has ruined my plans for the day.|What would you do?",
			foodie = "{player}, it's raining, and I've already eaten all my snacks.|What do I do now?",
			shy = "Um, {player}, it's raining a lot.|What do you do on days like this?",
			cool = "It's raining.|I'm stuck inside, so what should I do?",
			prickly = "Ugh, rain.|I'm stuck inside and bored, so don't just stand there, give me an idea.",
			dramatic = "{player}, it's RAINING, and my whole day is ruined.|What do I do now?",
			bookish = "It's been raining for six hours straight.|I've already read two books, so I need something else to do.",
			polite = "Good morning, {player}, what a wet day it is.|What would you suggest I do?",
			_ = "{player}, it's raining.|What should I do all day?",
		}, "question")
		s:choice("Bake something.", function(c)
			burst(c, "a", {
				foodie = "Yes, yes, the big cake!|I've been waiting for a reason to make it.",
				bold = "Baking sounds good.|I'm going to make the biggest cake you've ever seen.",
				gentle = "Baking sounds lovely.|I'll save you a slice, if you come round.",
				cheeky = "ok, baking|if the smoke alarm goes off, that's on you",
				sunny = "Baking, yes, yes!|Come over later and help me eat it.",
				dreamy = "Baking...|The house will smell like cinnamon, and the windows will steam up.",
				easygoing = "Baking, sure.|Mostly the waiting part, which I'm great at.",
				proud = "Baking, naturally.|My cakes are the best in town, so this is easy.",
				shy = "Baking, okay.|I'll make a small one, and maybe give you a piece.",
				cool = "Baking.|Good idea.",
				prickly = "Baking, fine.|Don't expect a slice unless you come round.",
				dramatic = "A rainy day BAKE!|I'll make a cake as tall as the clock tower.",
				bookish = "Baking, good.|I've got a recipe I've been meaning to try, and it needs exactly four eggs.",
				gloomy = "Baking, okay.|Heh... it'll sink in the middle, as usual.",
				polite = "Baking, what a lovely idea.|I will save a slice for you, if you would like one.",
				nervous = "Baking? What if I burn it?|...I'll set a timer, two timers, it'll be fine.",
				_ = "Baking, good idea.|The whole house will smell lovely.",
			}, "heart")
			c:mood("a", 4)
		end)
		s:choice("Go and jump in puddles.", function(c)
			burst(c, "a", {
				sunny = "Rain boots on, let's go!",
				shy = "Puddles, like a little kid?|...Okay, maybe just a small one.",
				gloomy = "I'll get soaked.|...Okay, fine, let's.",
				prickly = "That's ridiculous.|...Where did I put my rain boots?",
				cheeky = "puddles, yes|race you to the big one by the gate",
				gentle = "Puddles? Oh, why not.|Put your rain boots on too, okay? I don't want you catching a cold.",
				bold = "Puddles, hah, yes.|I'm going for the biggest one first.",
				dreamy = "Puddles... they look like little mirrors with the sky in them.|Let's go.",
				easygoing = "Puddles, sure, why not.|I'll jump in one, then sit under a tree.",
				proud = "Puddle jumping? Hmph, very well.|I'll make the biggest splash, naturally.",
				cool = "Puddles.|Okay, I'll get my coat.",
				dramatic = "PUDDLES! Yes!|Let the rain do its worst.",
				bookish = "Puddles? Actually, I haven't done that in years.|Let me find my rain boots.",
				polite = "Jumping in puddles? Oh, how fun.|I will get my rain boots, then.",
				foodie = "Puddles, then cocoa after.|That's the best kind of rainy day.",
				nervous = "Puddles? What if I slip?|...Okay, I'll hold on to you, then.",
				_ = "Puddles, yes.|I'm getting my rain boots on.",
			}, "sparkle", "cheer")
			c:mood("a", 6)
		end)
		s:log("{a} asked what to do on a rainy day.")
		return s:done()
	end,
})

event({
	id = "cantsleep",
	when = "night",
	weight = W({ base = 0.12 }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "Still awake")
		burst(s, "a", {
			nervous = "{player}?|Sorry, are you awake?|I can't sleep.",
			dreamy = "{player}, are you up?|The moon's so bright tonight that I can't close my eyes.",
			gloomy = "{player}, I can't sleep again, as usual.|Heh... I've been staring at the ceiling for an hour.",
			cool = "{player}.|Are you still up?",
			sunny = "{player}, you're up too?|I can't sleep, my brain just won't stop!",
			easygoing = "{player}...|It's two in the morning, and I'm wide awake, which isn't like me at all.",
			gentle = "{player}, sorry if I woke you.|I can't sleep, and I didn't want to be the only one awake.",
			shy = "Um, {player}?|Are you awake? Sorry, you don't have to answer.",
			bold = "{player}, you're still up, right?|I can't sleep at all.",
			proud = "{player}, are you awake?|I'm not having trouble sleeping, I'm just choosing not to.",
			cheeky = "{player} you up?|guess who can't sleep",
			prickly = "{player}, are you up?|I can't sleep, and I'm not happy about it.",
			dramatic = "{player}, are you awake?|I can't SLEEP, and the night is so long.",
			bookish = "{player}, are you awake?|It's ten past two, and I've been lying here since eleven.",
			polite = "Good evening, {player}, I am sorry to bother you so late.|Are you awake?",
			foodie = "{player}, are you awake?|I can't sleep, and I've already had a midnight snack.",
			_ = "{player}, are you still awake?",
		}, "zzz")
		burst(s, "a", {
			nervous = "I keep thinking about tomorrow, and then the day after that.",
			foodie = "I think it's the cheese I had after dinner.|It was a lot of cheese.",
			dramatic = "My thoughts won't be quiet.|It's like they're throwing a party in my head.",
			bookish = "I tried counting sheep.|Then I started wondering how many sheep there are on the whole island.|Did you know nobody has ever actually counted them?",
			gloomy = "I've been lying here listing everything that could go wrong.|It's a long list.",
			shy = "I keep thinking about something silly I said today.",
			gentle = "I keep worrying about everyone, and then I can't stop.",
			sunny = "I keep planning tomorrow, and it's going to be such a good day.",
			dreamy = "I keep wondering where the gulls sleep at night.",
			bold = "I keep thinking about work, and I can't switch my head off.",
			easygoing = "I had a nap at six, then another at eight, and now I'm wide awake.",
			proud = "I keep thinking about how well I did today.|There's a lot to think about.",
			cheeky = "i had three cups of tea after dinner|that was a mistake hehe",
			cool = "My head won't stop.",
			prickly = "Someone's dog has been barking for an hour, ugh.",
			polite = "I keep going over a conversation I had today, and wondering if I was rude.",
			_ = "I keep going over today in my head.",
		}, "question")
		s:choice("Try to get some sleep.", function(c)
			burst(c, "a", {
				prickly = "Fine.|You go to sleep too, seriously.",
				cool = "Okay, good night.",
				gloomy = "Okay...|Night, {player}.",
				nervous = "Okay, sorry for keeping you up.|Good night.",
				gentle = "You're right.|Sleep well, {player}, and take care of yourself.",
				cheeky = "ok, ok, going|night {player}",
				sunny = "Okay, I'll try!|Good night, {player}, see you in the morning.",
				bold = "Fine, I'll try.|Night, {player}.",
				dreamy = "Okay...|I'll count the stars until I fall asleep.",
				easygoing = "Yeah, okay.|Sleep is my favourite thing, so I should be good at it.",
				proud = "Very well, I'll sleep.|I'm very good at sleeping, naturally.",
				shy = "Okay... sorry for bothering you.|Good night.",
				dramatic = "Very well, I'll try.|Good night, {player}, until morning!",
				bookish = "You're right.|I'll read one chapter and then turn the light off, I promise.",
				polite = "Yes, you are quite right.|Good night, {player}, and thank you.",
				foodie = "Okay, I'll try.|I'll have a warm milk first, that always helps.",
				_ = "Okay, you too.|Good night, {player}.",
			}, "zzz")
			c:n("{a} was asleep before ten minutes were up.")
			c:mood("a", 3)
		end)
		s:choice("What's on your mind?", function(c)
			burst(c, "a", {
				nervous = "Okay, so, the first thing is...",
				gloomy = "You don't really want to hear it.|...Okay, well.",
				prickly = "Nothing.|...Fine, everything.",
				cheeky = "ok, you asked for this",
				cool = "...Okay, if you're sure.",
				sunny = "Ooh, okay, so, first thing tomorrow...",
				gentle = "Oh, you're sweet to ask.|Well, it's a few things...",
				bold = "Okay, I'll tell you straight.|It's about work.",
				dreamy = "Hmm... it's hard to say...|It's like a cloud that keeps changing shape.",
				easygoing = "Eh, nothing much, really.|...Well, maybe one thing.",
				proud = "Nothing that I can't handle, naturally.|...But since you asked.",
				shy = "Um... are you sure?|It's a bit silly.",
				dramatic = "Oh, {player}, where do I even BEGIN?",
				bookish = "Well, there are three things, actually.|I'll start with the first.",
				polite = "That is very kind of you to ask.|If you are sure you do not mind...",
				foodie = "Okay, but first, do you want a snack?|I think better with a snack.",
				_ = "You really want to know?|Okay, so...",
			}, "heart")
			c:n("You talked until the sky started to go grey.")
			burst(c, "a", {
				sunny = "Ehehe, sorry, I talked so much!|Thanks for staying up with me!",
				dreamy = "The gulls slept on the roof the whole time, did you notice?|Thank you for staying up with me...",
				foodie = "All that talking has made me hungry again.|Thanks for staying up with me, though.",
				gentle = "I'm sorry I kept you up so late.|Thank you for listening, and get some sleep, okay?",
				cheeky = "ok, forget everything i said|...thanks for listening, though",
				cool = "Thanks for listening.|Get some sleep.",
				bold = "...Thanks, I needed that.|Now go to bed, it's nearly morning.",
				polite = "Thank you kindly for listening.|I'm sorry for keeping you up so late.",
				easygoing = "Huh, it's nearly morning.|Thanks for staying up, I think I can sleep now.",
				nervous = "I-I'm sorry, I talked all night.|Thank you for listening, really.",
				proud = "Hmph, I'm not usually the one who needs to talk.|...But thank you for listening.",
				shy = "Sorry for talking so much...|Thank you for listening to me.",
				prickly = "Don't tell anyone I talked that much.|...Thanks, though.",
				dramatic = "You've SAVED me, {player}.|I'll sleep like a baby now.",
				bookish = "We talked for three hours and twelve minutes.|Sorry, I'm rambling again, but thank you for listening.",
				gloomy = "That was nice, actually.|Heh... strange, I feel better.",
				_ = "Forget I said all that, okay?|...Thanks for listening, though.",
			}, "zzz")
			c:hearts("a", 1)
			c:mood("a", 5)
		end)
		s:log("{a} couldn't sleep.")
		return s:done()
	end,
})

event({
	id = "forgotname",
	actors = 2,
	when = "day",
	weight = W({ base = 0.1, rel = -20, relMax = 20 }),
	scene = function(ctx, a, b)
		local s = K.scene(ctx, "What's their name")
		s:n("{b} is walking over to say hello.")
		burst(s, "a", {
			nervous = "{player}, help me, quickly.|I've forgotten the name of the person coming over, and I've known them for weeks.",
			shy = "Um, {player}, what's the name of the one coming over?|Please don't look at them while you tell me.",
			proud = "{player}, quickly, the one coming over.|I know their name, naturally, but I need you to say it first.",
			gloomy = "I've forgotten their name again.|And now they're coming over, as usual.",
			cool = "{player}.|Quick, what's their name?",
			gentle = "{player}, oh, my, the person coming over...|I've forgotten their name, and they're always so kind to me.",
			dreamy = "Someone's waving at me...|I know their face, but the name's gone right out of my head.",
			sunny = "{player}, quick, quick!|What's the name of the person coming over?",
			bold = "{player}, quick, the one coming over.|What's their name? Tell me, fast.",
			easygoing = "Uh, {player}, someone's coming over, and their name has gone right out of my head.|Help me out?",
			cheeky = "{player} help|what's their name, i've been calling them 'hey you' for weeks",
			prickly = "{player}, don't laugh.|What's the name of the one coming over?",
			dramatic = "{player}, it's a DISASTER.|I've forgotten the name of the person coming over.",
			bookish = "{player}, I can remember a hundred book titles, but not the name of the person coming over.|What is it?",
			polite = "{player}, I am so embarrassed, but I have forgotten the name of the person coming over.|Could you tell me, please?",
			foodie = "{player}, the person coming over always buys the plum buns.|I know that, but I can't remember their name.",
			_ = "Who's that coming over?|I've completely forgotten their name.",
		}, "sweat")
		s:choice("Whisper the name to {a}.", function(c)
			c:n("You whispered the name just in time.")
			say(c, "a", "Hi, {b}!|How are you, {b}? It's so good to see you, {b}.", "sparkle")
			burst(c, "b", {
				cheeky = "why do you keep saying my name",
				cool = "...Hi.",
				sunny = "Hi, hi!|Ehehe, you said my name three times.",
				gentle = "Hello, dear.|You seem very cheerful today.",
				bold = "Hah, hi.|Why do you keep saying my name?",
				dreamy = "Hello...|My name sounds funny when you say it that many times.",
				easygoing = "Hey.|That's a lot of my name for one hello.",
				proud = "Hello.|It is a good name, I'll admit.",
				shy = "Oh... hi.|Um, yes, that's me.",
				prickly = "Yes, that's my name.|You don't have to wear it out.",
				dramatic = "My NAME, three times!|I feel so special.",
				bookish = "Hello.|You said my name three times, which is two more than usual.",
				gloomy = "Hi...|Heh... nobody's ever that happy to see me.",
				polite = "Good afternoon to you too.|You are very cheerful today.",
				foodie = "Hi!|You sound like someone who's just had a good lunch.",
				nervous = "H-hi, yes, that's me.|Is something wrong? Why do you keep saying it?",
				_ = "Hi.|You're really happy to see me today, huh?",
			}, "question")
			c:rel(3)
		end)
		s:choice("Just ask them.", function(c)
			burst(c, "a", {
				cool = "Sorry, I've forgotten your name.|What is it again?",
				proud = "I knew it a minute ago, honestly.|What's your name again?",
				cheeky = "ok this is awkward|what's your name again",
				sunny = "Sorry, sorry, my head's empty today!|What's your name again?",
				gentle = "Oh my, I'm so sorry.|Would you tell me your name again?",
				bold = "I'll be honest, I've forgotten your name.|What is it?",
				dreamy = "I'm sorry... your name floated away.|What is it again?",
				easygoing = "Sorry, my brain's still napping.|What's your name again?",
				shy = "Um... I'm really sorry...|What's your name again?",
				prickly = "Ugh, don't be offended.|What's your name again?",
				dramatic = "I've done something TERRIBLE.|I've forgotten your name, please forgive me.",
				bookish = "I'm sorry, I'm good with books and bad with names.|What's yours again?",
				gloomy = "Sorry, I forgot your name, as usual.|What is it?",
				polite = "I do apologise, but I have forgotten your name.|Would you remind me, please?",
				foodie = "I remember you love plum buns, but I've forgotten your name.|What is it again?",
				nervous = "I'm so sorry, I've forgotten your name.|Oh no, is that rude? It's rude, isn't it?",
				_ = "I'm so sorry, this is awful.|What's your name again?",
			}, "sweat")
			burst(c, "b", {
				gentle = "It's {b}, and don't worry, all right?|I forget names all the time.",
				proud = "It's {b}.|I'll try not to be hurt.",
				prickly = "It's {b}.|Write it down this time.",
				gloomy = "It's {b}.|Heh... nobody remembers, so it's fine.",
				sunny = "It's {b}!|What was yours again? Ehehe, I'm kidding.",
				dreamy = "It's {b}.|Names are slippery, I forget them too.",
				bold = "It's {b}.|Don't forget it again, right?",
				easygoing = "It's {b}, no big deal.|I forget my own name before breakfast.",
				shy = "Oh... it's {b}.|It's okay, really.",
				cheeky = "it's {b}|i'm telling everyone you forgot hehe, jk",
				cool = "It's {b}.|It's fine.",
				dramatic = "You FORGOT? *gasp*|It's {b}, and I'll never forget this.",
				bookish = "It's {b}.|People forget names all the time, actually, it's very common.",
				polite = "It is {b}, and please do not worry.|It happens to everyone.",
				foodie = "It's {b}, the plum bun one.|Don't worry, I remember people by their favourite food too.",
				nervous = "It's {b}... is that okay? I mean, of course it is.|Please don't feel bad!",
				_ = "It's {b}, but don't worry about it.",
			}, "heart")
			c:rel(6)
		end)
		s:log("{a} forgot {b}'s name.")
		return s:done()
	end,
})

event({
	id = "secretspot",
	when = "day",
	weight = W({ base = 0.1, weather = { "clear", "cloudy", "blossom", "leaves", "snow" } }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "A secret spot")
		burst(s, "a", {
			dreamy = "{player}...|Can I show you a place?|Nobody else knows about it.",
			cheeky = "{player} want to see my secret spot|you have to pinky promise not to tell",
			shy = "Um, {player}?|There's a place I go to on my own.|I could show you, if you'd like.",
			cool = "{player}.|There's a spot I like up on the hill.|Want to see it?",
			bookish = "There's a flat rock up behind the hill.|You can see the whole bay from it, and hardly anyone knows it's there.|Would you like to see?",
			gentle = "{player}, would you like to see a place I go when I need some quiet?|I'd like to show you.",
			sunny = "I want to show you my secret spot!|Come on, it's not far.",
			bold = "{player}, I'm showing you my secret spot.|Come on, and keep up.",
			easygoing = "There's a spot on the hill that's perfect for naps.|Want to see it? No rush.",
			proud = "{player}, I've found the best view in town, naturally.|I'll show you, if you promise not to tell.",
			prickly = "There's a place I go, and don't tell anyone about it.|...Do you want to see it, or not?",
			dramatic = "{player}, I have a SECRET place.|Only the people I trust most may see it.",
			gloomy = "There's a place I go when everything's too much.|Heh... you can see it, if you want.",
			polite = "{player}, there is a quiet place I like to visit.|Would you like to see it?",
			foodie = "I've got a secret picnic spot up on the hill.|I'll show you, and I'll bring sandwiches.",
			nervous = "{player}, can I show you a place I go?|You won't tell anyone, will you? What if it gets busy?",
			_ = "Do you want to see my secret spot?|It's not far, and nobody else goes there.",
		}, "idea")
		s:choice("I'd love to see it.", function(c)
			c:n("{a} led you up a path behind the hill to a flat rock that looks out over the whole town.")
			burst(c, "a", {
				dreamy = "This is where I come to think.|Or to not think, sometimes.",
				cheeky = "tell no one|not even the gulls",
				shy = "I've never shown anyone before.|You're the first.",
				gloomy = "It's the one place where nothing ever goes wrong.",
				gentle = "I come here when I've had a long day.|You're welcome here any time, all right?",
				sunny = "Isn't it amazing? Ehehe!|Let's come here together all the time.",
				bold = "Best view in town, right?|Now it's yours too.",
				easygoing = "This is where I nap on sunny days.|You can nap here too, there's room.",
				proud = "Wonderful, isn't it?|I found it myself, naturally.",
				cool = "This is it.|You can come here too.",
				prickly = "Don't tell anyone, okay?|...You can come here, I suppose.",
				dramatic = "Look at it, my SECRET kingdom!|Now it's ours.",
				bookish = "You can see all forty-two roofs in town from here.|I counted them, sorry, I'm rambling.",
				polite = "This is my favourite place.|You are welcome to come here any time.",
				foodie = "This is my picnic spot.|Here, have a sandwich, it tastes better with a view.",
				nervous = "So, um, this is it.|Is it okay? Do you like it?",
				_ = "You can come up here too, whenever you like.|It's our spot now.",
			}, "heart")
			c:hearts("a", 1)
			c:mood("a", 5)
			c:memo("a", "I showed the {player} my secret spot, so now it's our spot.")
		end)
		s:choice("Maybe another day.", function(c)
			burst(c, "a", {
				shy = "Okay.|It'll still be there another day.",
				cheeky = "your loss|it's very secret",
				sunny = "Okay, another day!|Ehehe, I won't forget.",
				gentle = "Of course, another day.|Take care, okay?",
				bold = "Fine, another day.|But you're coming, right?",
				dreamy = "Another day...|It'll still be there, waiting.",
				easygoing = "Sure, no rush.|It's not going anywhere.",
				proud = "Hmph, very well.|It's an honour you'll have to wait for.",
				cool = "Okay.|Another day.",
				prickly = "Fine, whatever.|...The offer's still there.",
				dramatic = "Another DAY?|...Fine, the secret will wait.",
				bookish = "Another day, then.|It's best at about five, when the sun is low.",
				gloomy = "Heh... okay.|I didn't think you'd want to.",
				polite = "Of course, another day.|Thank you all the same.",
				foodie = "Another day, then.|I'll pack a bigger picnic next time.",
				nervous = "Oh, okay, that's fine.|Was it weird that I asked? Sorry.",
				_ = "Another day, then.|Don't forget, okay?",
			}, "sad")
			c:mood("a", -1)
		end)
		s:default(2)
		s:log("{a} wanted to show you their secret spot.")
		return s:done()
	end,
})

event({
	id = "sillyhat",
	actors = 2,
	when = "day",
	weight = W({ base = 0.1, rel = 0, btraits = { mischief = 0.2 } }),
	scene = function(ctx, a, b)
		local s = K.scene(ctx, "A silly hat")
		s:n("{a} lost a bet to {b} and has to wear a very silly hat all day.")
		burst(s, "a", {
			proud = "{player}, don't look at me.|...Do I look ridiculous? Be honest, and be quick.",
			gloomy = "Go on, {player}, laugh.|Everyone else already has.",
			dramatic = "{player}, don't look, this is my SHAME.",
			prickly = "Not a word, {player}.|...Okay, one word.|How bad is it?",
			nervous = "{player}, is it bad? It's bad, isn't it?|Is everyone looking at me?",
			sunny = "Look at my hat!|It has a feather and a little bell on it.",
			cool = "{player}.|I lost a bet, so don't ask about the hat.",
			gentle = "{player}, I lost a bet, so I'm stuck with this hat.|Please be kind about it, okay?",
			dreamy = "There's a bell on my hat...|It jingles every time I nod, so I'm trying not to nod.",
			bold = "{player}, I lost a bet, and I'm wearing it proudly.|It looks great, right?",
			easygoing = "I lost a bet, so now I've got this hat.|Eh, it's fine, it keeps the sun off.",
			shy = "Um, {player}, please don't look...|I lost a bet.",
			cheeky = "{player} don't laugh|ok you can laugh a little",
			bookish = "{player}, I lost a bet about how many steps go up to the clock tower.|Now I have to wear this hat.",
			polite = "Good afternoon, {player}, please excuse my hat.|I lost a bet, and I always keep my word.",
			foodie = "{player}, I lost a bet, and now I have to wear this hat all day.|It looks like a cake, so at least there's that.",
			_ = "{player}, be honest with me.|How silly does this hat look?",
		}, "sweat")
		s:choice("It suits you, honestly.", function(c)
			burst(c, "a", {
				proud = "It does, doesn't it?|I might even keep it.",
				gloomy = "You're just saying that.|...Should I keep it?",
				sunny = "Really? Ehehe, then I'm keeping it!",
				gentle = "Oh, you're sweet.|Maybe it's not so bad after all.",
				bold = "Hah, right?|I'm wearing it all week now.",
				dreamy = "Really...?|The bell does sound nice.",
				easygoing = "Huh, really?|Then I'll stop worrying about it.",
				shy = "R-really?|Um... thank you.",
				cheeky = "it does, doesn't it|i'm starting a trend",
				cool = "Thanks.|I'll keep it on, then.",
				prickly = "You're just being nice.|...But thanks.",
				dramatic = "It SUITS me?|Then I'll wear it with pride!",
				bookish = "Really?|Actually, the feather is from a real gull, which is interesting.",
				polite = "That is very kind of you to say.|Thank you, {player}.",
				foodie = "Really?|Then I'm wearing it to dinner too.",
				nervous = "Really? You're not just saying that?|Oh, thank goodness.",
				_ = "Really?|Huh, maybe it's not so bad after all.",
			}, "sparkle")
			-- so they put it on for good (Sim/Memory), and may ask about it again later
			c:wear("a", "sillyhat")
			c:say("b", "That was meant to be a punishment, you know.", "sweat")
			c:follow("suitme", { chance = 0.6, hours = 6, words = { worn = "sillyhat" } })
			c:mood("a", 5)
		end)
		s:choice("It's very silly.", function(c)
			burst(c, "a", {
				prickly = "I know, I know.",
				dramatic = "I KNOW.|And I've got six more hours of this.",
				sunny = "I know, ehehe!|At least it makes people smile.",
				gentle = "Oh, I know.|It's only for today, at least.",
				bold = "Yeah, it is.|I'm still winning the next bet, though.",
				dreamy = "Hmm... it is.|The bell keeps ringing in my ears.",
				easygoing = "Yeah, I know.|Eh, it's only for a day.",
				proud = "Silly? Th-this is fashion, actually.",
				shy = "I know...|Please stop looking.",
				cheeky = "yeah it is|i'm getting them back next time",
				cool = "I know.|Six more hours.",
				bookish = "I know.|Six hours and twelve minutes to go.",
				gloomy = "I know.|Heh... this is how everyone will remember me.",
				polite = "Yes, it is rather silly.|I will wear it all day anyway, as I promised.",
				foodie = "I know.|I'm going to get a big lunch to make up for it.",
				nervous = "I know, I know.|What if it never comes off?",
				_ = "I know, I know it is.",
			}, "sad")
			burst(c, "b", {
				sunny = "Ehehe, a bet's a bet!",
				gentle = "It's a little bit silly, but you're being a good sport about it.",
				bold = "Hah! A bet's a bet, and you lost.",
				dreamy = "Hmm... it suits the day, somehow.",
				easygoing = "Heh, only six more hours to go.",
				proud = "Hmph, that's what happens when you bet against me.",
				shy = "Um, sorry, I'm trying not to laugh.",
				cheeky = "hehe, best bet i ever won",
				cool = "Hm. A bet's a bet.",
				prickly = "You knew the deal when you made the bet.",
				dramatic = "It's a MASTERPIECE of silliness.",
				bookish = "Actually, I designed it myself, so I'm quite proud of it.",
				gloomy = "Heh... I'd have lost too, if I were you.",
				polite = "Oh, goodness, I'm sorry, I can't help laughing.",
				foodie = "You can take it off at dinner time, I promise.",
				nervous = "I-I'm sorry, is it too much? I didn't think it would be this silly.",
				_ = "Ha, a bet's a bet.",
			}, "music", "laugh")
			c:rel(2)
			c:mood("a", -1)
			c:mood("b", 3)
		end)
		s:log("{a} wore a silly hat after losing a bet to {b}.")
		return s:done()
	end,
})

-- yes to the quiz team
local QUIZ_YES = {
	cool = "Sure, when is it?",
	bookish = "Yes, I'd love to.|Actually, I know nearly all the capitals.",
	foodie = "Is there food at the quiz?|Then yes.",
	dramatic = "I thought you'd never ask!|Yes, a thousand times.",
	gloomy = "You want me on the team?|I'll get every question wrong, but okay.",
	bold = "Hah, obviously!|We're going to win, too.",
	proud = "Naturally, and you've chosen well.",
	cheeky = "yes, but i'm picking the team name",
	shy = "Um, yes... if you really want me.",
	nervous = "M-me? Okay, yes, I'll try my best.",
	polite = "Of course, I'd be glad to.",
	sunny = "Yes, yes, I'd love to!|Let's win the whole thing.",
	gentle = "Oh, I'd love to.|I'll bring snacks for the team, okay?",
	dreamy = "A quiz...? Hmm, yes.|I know a lot about clouds, if that helps.",
	easygoing = "Sure, sounds fun.|As long as I don't have to answer the hard ones.",
	prickly = "Ugh, fine, I'll join.|Only because you'll lose without me.",
	_ = "Yes, of course I will.",
}

event({
	id = "practiseask",
	actors = 2,
	when = "day",
	weight = W({ base = 0.1, rel = -10, traits = { brave = -0.2 } }),
	scene = function(ctx, a, b)
		local s = K.scene(ctx, "Practising")
		burst(s, "a", {
			nervous = "{player}, can I practise on you?|I want to ask {b} to join my quiz team, and I keep messing it up in my head.",
			shy = "Um, {player}, can I practise on you?|I want to ask {b} to join my quiz team.|It's nothing big, really.",
			proud = "I'm asking {b} to join my quiz team.|I've prepared a short speech, naturally.",
			bookish = "I'm asking {b} to join our quiz team.|I've written out three different ways to ask.",
			gentle = "{player}, I'd like to ask {b} to join our quiz team.|Could I practise on you first?",
			sunny = "I really want {b} on my quiz team.|Can I practise asking you first?",
			dreamy = "{player}, I want to ask {b} to join my quiz team...|But every time I try, I forget what I was going to say.",
			easygoing = "{player}, can I practise asking {b} to join my quiz team?|I'd just ask, but I always mumble when it matters.",
			bold = "I'm asking {b} to join my quiz team.|I'll practise on you once, then I'm going, right?",
			cheeky = "{player} i'm asking {b} to join my quiz team|pretend to be {b} for a minute, and make it hard",
			cool = "I'm asking {b} to join my quiz team.|Let me try it on you.",
			prickly = "I need to ask {b} to join my quiz team.|Don't laugh, but can I practise on you?",
			dramatic = "{player}, I must ask {b} to join my quiz team.|It's the biggest question I've ever asked.",
			gloomy = "I want to ask {b} to join my quiz team.|Heh... they'll say no, but can I practise anyway?",
			polite = "{player}, I would like to ask {b} to join our quiz team.|May I practise on you first?",
			foodie = "I want {b} on my quiz team, and I'm bribing them with pie.|Can I practise asking you first?",
			_ = "{player}, can I practise asking {b} to join my quiz team?|I always go quiet when I try to ask people things.",
		}, "sweat")
		local keen = ctx.rel(a, b) >= 0
		s:choice("Just go and ask them.", function(c)
			burst(c, "a", {
				nervous = "Go right now?|Okay, okay, I'm going.",
				shy = "Now?|...Okay, before I get scared.",
				sunny = "Okay, okay, I'm going!|Wish me luck!",
				gentle = "You're right.|I'll go and ask them now.",
				bold = "Right, I'm going now.|No more waiting.",
				dreamy = "Now...? Okay.|I'll go before I forget again.",
				easygoing = "Sure, why not.|Practising sounds like more work anyway.",
				proud = "Very well.|I didn't need the practice anyway.",
				cheeky = "ok, going|if they say no, i'm blaming you",
				cool = "Okay.|I'm going.",
				prickly = "Fine.|I'm going, don't watch.",
				dramatic = "Now? Into the UNKNOWN?|...Fine, I'm going.",
				bookish = "Just ask?|Actually, that's what all three of my notes say anyway.",
				gloomy = "Okay, I'll go.|Heh... wish me luck, I'll need it.",
				polite = "Very well, I will go and ask them now.|Thank you, {player}.",
				foodie = "Okay, I'm going.|I'll take the pie, just in case.",
				_ = "Right, I'm going now.",
			}, "sweat")
			if keen then
				burst(c, "b", QUIZ_YES, "heart")
				c:rel(8)
			else
				burst(c, "b", {
					prickly = "You want me on a quiz team?|...Fine, but only for one night.",
					sunny = "A quiz? Ooh, maybe!|Let me think about it, okay?",
					gentle = "Oh, that's kind of you.|Let me think about it for a day or two.",
					bold = "A quiz team? Hah, maybe.|Ask me again when you've got a better team name.",
					dreamy = "Hmm... a quiz...|I'll think about it, if I remember.",
					easygoing = "Eh, maybe.|Quizzes sound like a lot of thinking.",
					proud = "Me, on your team?|I'll think about it, but no promises.",
					shy = "Um... I'm not sure...|Can I think about it?",
					cheeky = "a quiz team? maybe|what's in it for me hehe",
					cool = "Maybe.|I'll let you know.",
					dramatic = "A quiz? Such a big decision!|I'll need time to think.",
					bookish = "A quiz? I'd have to check my calendar.|I'll let you know by Thursday.",
					gloomy = "Me? Heh... I'd only slow you down.|I'll think about it.",
					polite = "Thank you for asking.|May I think about it and give you an answer tomorrow?",
					foodie = "A quiz? Is there food?|...I'll think about it.",
					nervous = "A quiz? With people watching?|I-I'll think about it, okay?",
					_ = "Oh, a quiz team?|I'll think about it.",
				}, "question")
				c:rel(2)
			end
		end)
		s:choice("Practise on me first.", function(c)
			c:n("{a} asked you four times, and the fourth time was very good.")
			burst(c, "a", {
				dramatic = "I've never been more ready for anything in my life!",
				sunny = "Okay, I'm ready, ready!|Here I go!",
				gentle = "Thank you for being so patient.|I think I can do it now.",
				bold = "Got it.|I'm going right now.",
				dreamy = "Okay... I think the words are staying in my head now.",
				easygoing = "Okay, I think I've got it.|That was more practice than I usually do for anything.",
				proud = "Hmph, I was perfect the third time too.|But fine, I'm ready.",
				shy = "Okay...|I think I can do it now.",
				cheeky = "ok, the fourth time was the best one|going now",
				cool = "Okay.|Ready.",
				prickly = "Fine, I'm ready.|Don't tell anyone I needed four goes.",
				bookish = "Four tries, and the fourth was the best.|That's about right, actually.",
				gloomy = "Okay, I'm as ready as I'll ever be.|Heh...",
				polite = "Thank you kindly for your help.|I believe I am ready now.",
				foodie = "Okay, I'm ready.|And I've still got the pie, just in case.",
				nervous = "Okay, okay, I think I can do this.|...Is my hair okay?",
				_ = "Okay, I think I'm ready now.",
			}, "sparkle")
			burst(c, "b", QUIZ_YES, "heart")
			c:rel(8)
			c:mood("a", 3)
			c:memo("a", "{b} joined our quiz team, and I practised on the {player} first.")
		end)
		s:log("{a} wanted to ask {b} to join their quiz team.")
		return s:done()
	end,
})

event({
	id = "weatherbet",
	when = "day",
	weight = W({ base = 0.09, traits = { mischief = 0.2 } }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "A bet on the weather")
		burst(s, "a", {
			cheeky = "{player} bet you it's sunny tomorrow|go on, take the bet",
			bold = "Let's bet on tomorrow's weather.|Sun or rain, you choose, and I'll take the other one.",
			bookish = "Did you know you can tell tomorrow's weather from today's clouds?|I've been reading them all afternoon, so would you like to bet on it?",
			gloomy = "Want to bet on tomorrow's weather?|I'll lose, as usual, so you might as well pick first.",
			sunny = "Let's make a bet!|Sun or rain tomorrow, you pick.",
			dreamy = "The clouds look heavy this afternoon...|Do you think it'll rain tomorrow, or not?",
			gentle = "{player}, let's make a little bet, just for fun.|Do you think it'll be sunny or rainy tomorrow?",
			easygoing = "I've got a lazy little bet for you.|Sun or rain tomorrow, you pick, and I'll take whatever's left.",
			proud = "{player}, I'm excellent at guessing the weather.|Pick sun or rain for tomorrow, and I'll prove it.",
			shy = "Um, {player}, do you want to make a bet?|Sun or rain tomorrow... only if you want to.",
			cool = "Sun or rain tomorrow.|Pick one.",
			prickly = "Bet you can't guess tomorrow's weather.|Sun or rain, go on, pick.",
			dramatic = "{player}, I challenge you to a BET.|Sun or rain tomorrow, choose!",
			polite = "{player}, would you like a friendly bet?|Will it be sunny or rainy tomorrow?",
			foodie = "{player}, let's bet on tomorrow's weather.|If it's sunny, I'm having a picnic, and if it rains, soup.",
			nervous = "{player}, want to bet on the weather? Just a small bet.|Sun or rain tomorrow?",
			_ = "{player}, sun or rain tomorrow?|Pick one, and we'll see who's right.",
		}, "idea")
		burst(s, "a", {
			cheeky = "loser sings a song by the fountain, deal?",
			sunny = "Loser sings a song by the fountain, ehehe!",
			gentle = "Whoever loses sings a little song by the fountain, okay?",
			bold = "Loser sings by the fountain, loud, deal?",
			dreamy = "Whoever loses sings by the fountain...|I already know which song I'd sing.",
			easygoing = "Loser sings by the fountain, nothing too hard.",
			proud = "The loser sings by the fountain, and it won't be me.",
			shy = "Whoever loses sings by the fountain... um, quietly is okay.",
			cool = "Loser sings by the fountain.",
			prickly = "Loser sings by the fountain, and no backing out.",
			dramatic = "The loser SINGS by the fountain, for the whole square to hear!",
			bookish = "Whoever loses sings one song by the fountain, at least two verses.",
			gloomy = "Loser sings by the fountain.|Heh... I'd better start practising.",
			polite = "Whoever loses will sing a song by the fountain, if that is all right with you.",
			foodie = "Whoever loses buys the other one a pie, and sings by the fountain.",
			nervous = "Whoever loses sings by the fountain... oh no, what if it's me?",
			_ = "Whoever loses has to sing a song by the fountain.",
		}, "music")
		s:choice("I say sun.", function(c)
			burst(c, "a", {
				gloomy = "Sun is a brave guess.|We'll see.",
				cheeky = "wait, sun was my pick|so we're on the same side, who sings then",
				sunny = "Sun? Then I'm saying rain!|Ehehe, this is going to be fun.",
				gentle = "Sun, how hopeful.|Then I'll say rain, and we'll see.",
				bold = "Sun? Then I'm taking rain.|Start warming up your voice, right?",
				dreamy = "Sun...|Then I'll be rain, like the clouds told me.",
				easygoing = "Sun, okay.|Rain for me, then, I'm not fussy.",
				proud = "Sun? Hmph, a brave guess.|I'm saying rain, and I'm never wrong.",
				shy = "Sun? Okay...|Then I'll say rain, I suppose.",
				cool = "Sun.|Then I say rain.",
				prickly = "Sun? Fine, I'll take rain.|You're going to lose, by the way.",
				dramatic = "SUN? Then I choose RAIN!|Let the sky decide.",
				bookish = "Sun, then.|The clouds say rain, actually, so I like my chances.",
				polite = "Sun it is, then.|I will take rain, and may the best guess win.",
				foodie = "Sun? Then I'm saying rain.|I'll get soup ready, just in case I win.",
				nervous = "Sun? Okay, then I'm rain.|Oh no, what if I have to sing?",
				_ = "You think it'll be sunny?|You'd better warm up your voice, then.",
			}, "sparkle")
			c:mood("a", 2)
			c:memo("a", "{player} bet me it'd be sunny, so somebody's singing at the fountain.")
		end)
		s:choice("I say rain.", function(c)
			burst(c, "a", {
				cheeky = "rain? bold choice|i hope you've got a song ready, hehe",
				sunny = "Rain? Then I'm saying sun!|It's going to be sunny, I can feel it.",
				gentle = "Rain? Oh, I hope not.|I'll say sun, then.",
				bold = "Rain? Hah, I'm taking sun.|Get your singing voice ready.",
				dreamy = "Rain...|Then I'll say sun, so one of us will be happy.",
				easygoing = "Rain, sure.|Sun for me, then, I'll be napping in it.",
				proud = "Rain? Then I choose sun, the obvious winner.",
				shy = "Rain? Um, then I'll say sun.|I hope you don't mind singing...",
				cool = "Rain.|Then I say sun.",
				prickly = "Rain? Ugh, you're probably right.|I'm saying sun anyway.",
				dramatic = "RAIN? Then I stand with the SUN!",
				bookish = "Rain, then.|I'll take sun, though the clouds are against me, actually.",
				gloomy = "Rain... you're probably right.|I'll say sun, and lose, as usual.",
				polite = "Rain, then.|I will take sun, and may the best guess win.",
				foodie = "Rain? Then I'm saying sun.|Picnic tomorrow, you'll see.",
				nervous = "Rain? Then I'll say sun, I suppose.|What if it's cloudy and nobody wins?",
				_ = "You think it'll rain?|You'd better warm up your voice, then.",
			}, "sparkle")
			c:mood("a", 2)
			c:memo("a", "{player} bet me it'd rain, so somebody's singing at the fountain.")
		end)
		s:log("{a} made a bet with you about the weather.")
		return s:done()
	end,
})

event({
	id = "earlyknock",
	when = "day",
	weight = W({
		base = 0.1,
		cond = function(ctx)
			return ctx.hour >= 15
		end,
	}),
	scene = function(ctx, a)
		local s = K.scene(ctx, "Wake me up")
		burst(s, "a", {
			easygoing = "{player}, can I ask a big favour?|Would you knock on my door at six tomorrow?|I want to see the sunrise just once in my life.",
			dreamy = "I want to see the sunrise from the hill tomorrow...|But I always sleep right through it.",
			nervous = "{player}, could you knock on my door at six tomorrow?|I've set three alarms, but what if they all fail?",
			bold = "{player}, knock on my door at six tomorrow, and knock loud.|I want to see the sunrise.",
			gloomy = "I want to see the sunrise tomorrow.|I'll sleep through it, as usual.",
			gentle = "{player}, I've always wanted to watch the sunrise from the hill.|Would you knock on my door at six tomorrow, if it's not too early for you?",
			sunny = "I want to see the sunrise tomorrow, just once.|Can you knock on my door at six?",
			proud = "{player}, I'd like to see the sunrise tomorrow.|Naturally, I could wake myself, but would you knock at six, just in case?",
			shy = "Um, {player}, could you knock on my door at six tomorrow?|I want to see the sunrise... only if it's not too much trouble.",
			cheeky = "{player} knock on my door at six tomorrow|if i don't answer, knock louder, i sleep like a rock hehe",
			cool = "{player}, knock on my door at six tomorrow.|I want to see the sunrise.",
			prickly = "I want to see the sunrise, don't ask why.|Knock on my door at six, would you?",
			dramatic = "{player}, I MUST see the sunrise tomorrow.|Knock at six, and don't let me sleep through it.",
			bookish = "The sun comes up at fourteen minutes past six tomorrow.|Would you knock on my door at six, so I'm up in time?",
			polite = "{player}, may I ask a favour?|Would you knock on my door at six tomorrow morning, so I can see the sunrise?",
			foodie = "I want to have breakfast on the hill and watch the sunrise.|Can you knock on my door at six? I'll pack you a roll.",
			_ = "{player}, could you knock on my door at six tomorrow?|I want to see the sunrise.",
		}, "question")
		s:choice("I'll knock, don't worry.", function(c)
			burst(c, "a", {
				easygoing = "You're a hero, a very early hero.|I'll owe you a nap.",
				nervous = "Thank you so much.|Knock twice, or maybe three times, just in case.",
				prickly = "Fine, good.|...Thanks.",
				bold = "Hah, good.|If I don't answer, keep knocking.",
				sunny = "Yay, thank you!|We can watch it together, if you want.",
				gentle = "Thank you, that's so kind.|Get some sleep yourself, okay?",
				dreamy = "Thank you...|I'll dream about the sun coming up, so I'm ready.",
				proud = "Very good.|I'll be ready, naturally.",
				shy = "Thank you... really.|Sorry it's so early.",
				cheeky = "thanks|knock like you mean it",
				cool = "Thanks.|Six, then.",
				dramatic = "My HERO!|I'll owe you forever.",
				bookish = "Thank you.|Six exactly, if you can, because the sunrise won't wait.",
				gloomy = "Thanks.|Heh... if I don't wake up, just leave me.",
				polite = "Thank you very much, {player}.|I am very grateful.",
				foodie = "Thank you!|I'll have the rolls ready when you knock.",
				_ = "Thanks, that's a big help.|Knock loudly, okay?",
			}, "heart")
			c:hearts("a", 1)
			c:mood("a", 4)
			c:memo("a", "{player} knocked at six, and I saw the sunrise. It was all pink.")
		end)
		s:choice("Leave your curtains open.", function(c)
			burst(c, "a", {
				bookish = "Actually, using the sun as an alarm is a very old idea.|It's a good one, though.",
				sunny = "The curtains! Ehehe, that's so clever!",
				gentle = "Oh, what a lovely idea.|The sun can wake me up gently.",
				bold = "The curtains, right.|Simple, and it'll work.",
				dreamy = "The sun as an alarm...|That sounds like something from a dream.",
				easygoing = "Leave the curtains open?|Then I don't have to set an alarm, perfect.",
				proud = "The curtains, of course.|I was just about to think of that.",
				shy = "The curtains... okay.|I'll try that, thank you.",
				cheeky = "curtains open? ok|if i sleep through it, that's on you",
				cool = "Curtains open.|Good idea.",
				prickly = "The curtains, fine.|...That's actually smart.",
				dramatic = "Let the SUN itself wake me!|That's beautiful.",
				gloomy = "Curtains open, okay.|Heh... it'll be cloudy, as usual.",
				polite = "What a clever idea.|Thank you, I will leave them open tonight.",
				foodie = "Curtains open, good.|I'll leave a cookie by the bed for when I wake up.",
				nervous = "Curtains open? What if the sun doesn't come out?|...I'll set an alarm too, just in case.",
				_ = "Leave the curtains open, so the sun wakes me up by itself.|That's clever.",
			}, "idea")
			c:mood("a", 2)
			c:memo("a", "I left my curtains open and the sun woke me up, more or less.")
		end)
		s:log("{a} asked you to wake them for the sunrise.")
		return s:done()
	end,
})

event({
	id = "walkedpast",
	when = "day",
	weight = W({ base = 0.11, traits = { social = 0.15 } }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "You walked right past")
		burst(s, "a", {
			sunny = "{player}, you walked right past me earlier!|I waved and everything.",
			cheeky = "{player} i waved at you this morning|you walked straight past me, i'm hurt",
			shy = "Um, {player}?|I waved at you earlier, but you didn't see.|That's okay, though.",
			prickly = "{player}, I waved at you earlier.|You walked right past me, but whatever.",
			dramatic = "{player}, I waved at you this morning, and you walked RIGHT past.|I've never felt so invisible.",
			gloomy = "{player}, I waved at you earlier.|You didn't see me, but nobody does, so it's fine.",
			polite = "Good afternoon, {player}.|I believe I waved at you earlier, but please do not worry about it.",
			gentle = "{player}, I waved at you this morning.|You looked busy, so I hope everything's all right.",
			dreamy = "{player}, I waved at you this morning...|You were looking at the sea, so I don't think you saw.",
			bold = "{player}, I waved at you this morning, and you walked right past.|You owe me a wave, right?",
			easygoing = "I waved at you this morning, but you walked right past.|No big deal, I was half asleep anyway.",
			proud = "{player}, I waved at you this morning, and you didn't wave back.|I'm not upset, I'm just surprised.",
			cool = "{player}.|I waved this morning, and you didn't see.",
			bookish = "{player}, I waved at you at ten past nine this morning.|You walked right past, actually.",
			foodie = "{player}, I waved at you from the bakery this morning.|You walked right past, and I had a bun for you.",
			nervous = "{player}, I waved at you this morning, and you didn't wave back.|Are you upset with me? Did I do something?",
			_ = "{player}, I waved at you this morning.|You walked right past me.",
		}, "sad", "wave")
		s:choice("Sorry, I didn't see you.", function(c)
			burst(c, "a", {
				prickly = "Ugh, fine.|Wave twice next time to make up for it.",
				gloomy = "...It's okay.|Thanks for saying sorry.",
				cheeky = "apology accepted|wave twice next time though",
				gentle = "Oh, don't worry about it.|I just wanted to make sure you were all right.",
				shy = "Oh, no, it's fine, really.|I'll wave bigger next time.",
				bold = "Hah, fine.|Wave back next time, or I'll shout.",
				polite = "Not at all, it happens to everyone.|Have a lovely day.",
				dreamy = "Hmm... the sea does that to people.|Wave back next time, okay?",
				sunny = "That's okay!|Next time I'll wave with both arms.",
				easygoing = "Eh, it's fine.|I'm not always awake either.",
				proud = "Hmph, very well.|I'm hard to miss, though.",
				cool = "It's fine.|Look up next time.",
				dramatic = "You're FORGIVEN!|...This time.",
				bookish = "That's okay.|People miss about half the waves they get, actually, I read that somewhere.",
				foodie = "That's okay.|The bun's still here, if you want it.",
				nervous = "Oh, phew, so you're not upset with me?|That's a relief.",
				_ = "Ha, that's okay.|Wave back next time, though.",
			}, "heart")
			c:mood("a", 3)
		end)
		s:choice("I waved back, you missed it.", function(c)
			burst(c, "a", {
				cheeky = "you did not|...wait, did you?",
				nervous = "You did? Oh no, and I didn't wave back?|Now I feel terrible.",
				proud = "Nobody waves at me without me noticing, {player}.",
				sunny = "You did? Ehehe, then we're even!",
				gentle = "Oh, you did?|Then I'm the one who should say sorry.",
				bold = "You did? Hah, I missed it.|Fine, we're even.",
				dreamy = "Did you...?|Hmm, maybe I was looking at a cloud.",
				easygoing = "Did you? Huh.|Then we're both a bit sleepy today.",
				shy = "Oh... you did?|Sorry, I didn't see.",
				cool = "You did?|Then we're even.",
				prickly = "You did not.|...Fine, maybe you did.",
				dramatic = "You waved BACK?|And I MISSED it? How sad.",
				bookish = "You did?|Then it was bad timing, actually.",
				gloomy = "Oh... I missed it, as usual.",
				polite = "Oh, did you?|I do apologise, I must have missed it.",
				foodie = "You did? I was probably looking at the buns.|Sorry!",
				_ = "Did you?|Then we both missed it.",
			}, "laugh", "laugh")
			c:mood("a", 2)
		end)
		s:log("{a} waved at you and you walked right past.")
		return s:done()
	end,
})

event({
	id = "thanksroom",
	when = "any",
	weight = W({ base = 0.12, bed = true }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "My room")
		burst(s, "a", {
			sunny = "{player}, I just wanted to say something!|My room is so nice, and I love the window.",
			shy = "Um, {player}, it's about my room.|It's really nice, and thank you.|That's all I wanted to say.",
			cool = "{player}.|My room's good, so thanks.",
			prickly = "My room's fine, {player}.|...Better than fine, actually.|Don't let it go to your head.",
			polite = "{player}, I would like to thank you properly for my room.|It is very comfortable, and I sleep so well in it.",
			gloomy = "My room's nice, weirdly.|I keep waiting for something to go wrong with it.",
			dramatic = "{player}, my room is PERFECT.|I cried a little when I first saw it.",
			foodie = "My room is lovely.|It's close to the kitchen, and that's all I ever ask.",
			gentle = "{player}, I wanted to thank you for my room.|I sleep so well in it.",
			dreamy = "The light comes through my window in stripes in the morning...|I love my room, thank you.",
			easygoing = "{player}, my bed is the comfiest bed I've ever napped in.|Thanks for the room.",
			bold = "{player}, my room's great.|You did a good job, right? ...Thanks. Anyway.",
			proud = "{player}, my room is very fine, as I deserve.|Thank you for that.",
			cheeky = "{player} my room's actually really nice|don't tell anyone i said that hehe",
			bookish = "{player}, my room gets sun for six hours a day.|It's perfect for reading, thank you.",
			nervous = "{player}, I just wanted to say thank you for my room.|Is it okay that I like it so much?",
			_ = "{player}, my room's really nice.|Thank you.",
		}, "heart")
		s:choice("I'm glad you like it.", function(c)
			burst(c, "a", {
				sunny = "I really, really do!|Thank you for building it, {player}.",
				gentle = "Thank you, that means a lot.|Take care of yourself, too.",
				bold = "Hah, I do.|...Thanks, I owe you one.",
				dreamy = "I do...|Thank you, I'll remember this.",
				easygoing = "Mm, a lot.|I'm going back for a nap in it right now.",
				proud = "It suits me perfectly, naturally.|Thank you for that.",
				shy = "...!|Thank you, really.",
				cheeky = "i do|don't let it go to your head, though hehe",
				cool = "I do, thanks.",
				prickly = "Yeah, well.|...Thanks.",
				dramatic = "Like it? I ADORE it.|Thank you a thousand times.",
				bookish = "I do, very much.|I've already worked out where every book goes.",
				gloomy = "I do, heh.|Nothing's gone wrong with it yet, which is a first.",
				polite = "Very much so.|Thank you kindly, {player}.",
				foodie = "I really do.|Come round for dinner sometime, and I'll cook to say thanks.",
				nervous = "I-I really do.|Thank you so much, {player}.",
				_ = "I really do.|Thank you, {player}.",
			}, "heart")
			c:mood("a", 4)
		end)
		s:choice("Anything you'd change?", function(c)
			burst(c, "a", {
				bookish = "A shelf, a tall one, for my books.|Actually, maybe two shelves.",
				foodie = "A little table by the bed for snacks.",
				dreamy = "A window that looks out at the sea...|If that's possible.",
				proud = "A mirror, a big one.",
				cool = "A lamp, maybe.",
				nervous = "Nothing, it's perfect!|Well... maybe a nightlight, just in case.",
				gentle = "Maybe some curtains with flowers on.|Only if you have time, of course.",
				sunny = "A big yellow rug!|Ehehe, it would make every morning sunny.",
				bold = "A bigger bed.|I stretch out a lot.",
				easygoing = "A hammock, maybe.|For naps between naps.",
				shy = "Um... maybe a little plant?|Only if it's no trouble.",
				cheeky = "a slide from my bed to the kitchen|jk, maybe a rug",
				prickly = "Nothing.|...Okay, a lock for the window, it rattles.",
				dramatic = "A CHANDELIER.|...Or a lamp, a lamp is fine.",
				gloomy = "A thicker blanket, maybe.|Heh... I'm always cold.",
				polite = "Perhaps a small writing desk, if it is no trouble.",
				_ = "Maybe a rug.|My feet get cold in the mornings.",
			}, "idea")
			c:mood("a", 2)
			c:memo("a", "I told the {player} what I'd like for my room, but there's no rush.")
		end)
		s:log("{a} thanked you for their room.")
		return s:done()
	end,
})

-- chats --------------------------------------------------------------------------------------------
-- Only a chat: what they send you on an ordinary day, in the shapes a phone chat takes, each in
-- their own voice.

-- a message meant for somebody else
event({
	id = "wrongperson",
	actors = 2,
	when = "day",
	weight = W({ base = 0.1, rel = -20 }),
	scene = function(ctx, a, b)
		local s = K.scene(ctx, "Wrong chat")
		burst(s, "a", {
			bold = "{b}, you've still got my ladder.|I need it back by six.",
			prickly = "{b}, you've had my ladder for a whole week now.|Seriously, I need it back.",
			polite = "{b}, I hope you do not mind my asking.|Could I please have my ladder back today?",
			cheeky = "{b} where's my ladder|i know it was you",
			nervous = "{b}, sorry, did you borrow my ladder?|I'm not upset, I just really need it today.",
			gentle = "{b}, sorry to ask, but do you still have my ladder?|I need it for the gutter today.",
			sunny = "{b}, do you still have my ladder?|I need it back today, thank you, thank you!",
			dreamy = "{b}, I think you still have my ladder...|I need it for the apple tree today.",
			easygoing = "Hey, {b}, no rush, but do you still have my ladder?|Well, a bit of a rush, I need it today.",
			proud = "{b}, I'd like my ladder back, please.|It's a very good ladder, as you know.",
			shy = "Um, {b}, sorry... do you still have my ladder?|I need it today, if that's okay.",
			cool = "{b}, I need my ladder back today.",
			dramatic = "{b}, where is my LADDER?|I can't reach anything without it.",
			bookish = "{b}, you borrowed my ladder eight days ago.|I need it back today, if you've finished with it.",
			gloomy = "{b}, do you still have my ladder?|Heh... I suppose you forgot, as usual.",
			foodie = "{b}, I need my ladder back to pick plums today.|I'll save you some for the trouble.",
			_ = "{b}, have you still got my ladder?|I need it back today.",
		})
		s:n("The message came to you instead.")
		burst(s, "a", {
			bold = "Wait, that went to the wrong person.|Hi, {player}.",
			prickly = "...|That wasn't meant for you.|Ugh.",
			polite = "Oh dear, that was meant for {b}.|I'm sorry, {player}.",
			cheeky = "oops|hi {player}, you didn't see that",
			nervous = "Oh no, sorry, {player}!|That was meant for {b}.",
			cool = "Hm, that was meant for {b}.|Sorry, {player}.",
			gentle = "Oh, my, that was meant for {b}.|Sorry, {player}.",
			sunny = "Oops, that was for {b}!|Ehehe, hi, {player}!",
			dreamy = "Oh... that was meant for {b}.|Hello, {player}, anyway.",
			easygoing = "Oops, wrong person.|Hey, {player}, while you're here.",
			proud = "That message was for {b}, obviously.|I don't make mistakes like that often.",
			shy = "Oh no... that was for {b}.|S-sorry, {player}.",
			dramatic = "WRONG person!|{player}, I'm so embarrassed.",
			bookish = "Oh, that was for {b}.|Sorry, {player}, your names are next to each other in my address book.",
			gloomy = "That was meant for {b}.|Heh... of course I sent it to the wrong person.",
			foodie = "Oops, that was for {b}.|Sorry, {player}, I was thinking about lunch.",
			_ = "Oh, that was meant for {b}.|Sorry, {player}.",
		}, "sweat")
		s:choice("I'll ask {b} for you.", function(c)
			say(c, "a", "Would you?|Thanks, that would really help.", "heart")
			burst(c, "b", {
				gentle = "Oh, the ladder, I'm so sorry.|I'll bring it over right now.",
				easygoing = "The ladder, right.|I'm sitting on it, well, near it.",
				dreamy = "There was a ladder?|Oh, that ladder, it's leaning against my tree.",
				proud = "I was improving it, actually.|It'll come back better than before.",
				sunny = "The ladder! I'm so sorry, I forgot all about it.|I'll bring it back right now.",
				bold = "Your ladder, right, my fault.|I'm bringing it back right now.",
				shy = "Oh no, the ladder... I'm so sorry.|I'll bring it back right away.",
				cheeky = "the ladder? oh, that ladder|ok fine, it's behind my shed, i'll bring it",
				cool = "The ladder.|I'll bring it now.",
				prickly = "Ugh, the ladder, I know.|I was going to bring it back today anyway.",
				dramatic = "THE LADDER! I'm a terrible person!|I'll bring it back this very minute.",
				bookish = "Oh, the ladder.|I've had it for eight days, haven't I? Sorry, I'll bring it now.",
				gloomy = "The ladder... yeah, I forgot, as usual.|Sorry, I'll bring it back.",
				polite = "Oh, the ladder, I do apologise.|I will return it this afternoon.",
				foodie = "The ladder! I've been using it to reach the top shelf in my kitchen.|Sorry, I'll bring it back with some buns.",
				nervous = "Oh no, the ladder, I'm so sorry!|I-I'll bring it back right now, is that okay?",
				_ = "The ladder? I forgot I had it.|Sorry about that.",
			}, "sweat")
			c:rel(4)
			c:mood("a", 2)
		end)
		s:choice("Is it the one by {b}'s door?", function(c)
			burst(c, "a", {
				bold = "I knew it, so I'm going over now.",
				prickly = "By their door, of course it is.|...Thanks.",
				polite = "That would be the one.|Thank you, {player}, that's very helpful.",
				cheeky = "detective {player} strikes again|thanks",
				sunny = "Yes, that's it!|Thank you, thank you, I'll go and get it now.",
				gentle = "Oh, that's the one.|Thank you, that's very kind of you.",
				dreamy = "By their door...?|Oh, I must have walked right past it.",
				easygoing = "That's the one.|That saves me a walk, thanks.",
				proud = "That's my ladder, yes.|Well spotted, almost as good as me.",
				shy = "Oh... that's it.|Thank you so much.",
				cool = "That's the one.|Thanks.",
				dramatic = "My LADDER! You found it!|You're a hero.",
				bookish = "That's it, it has my name on the third step.|Thank you.",
				gloomy = "That's it.|Heh... it's been there all week, hasn't it?",
				foodie = "That's it!|I'll get it on my way to the bakery, thanks.",
				nervous = "That's it? Oh, phew.|Thank you, I thought it was gone forever.",
				_ = "That's the one, thanks.",
			}, "idea")
			c:mood("a", 2)
		end)
		s:log("{a} sent you a message meant for {b}.")
		return s:done()
	end,
})

-- the morning after a late chat
event({
	id = "saidodd",
	when = "day",
	weight = W({
		base = 0.1,
		cond = function(ctx)
			return ctx.hour < 14
		end,
	}),
	scene = function(ctx, a)
		local s = K.scene(ctx, "The morning after")
		burst(s, "a", {
			shy = "Um, {player}, about last night.|Did I say anything odd?",
			prickly = "Forget everything I said last night, all right?|I was half asleep.",
			proud = "{player}, about last night.|I didn't say anything embarrassing, correct?",
			dramatic = "{player}, what did I say to you last night?|I fear the WORST.",
			gloomy = "I sent you a lot of messages last night.|Sorry about that, did I say anything odd?",
			nervous = "{player}, s-sorry about last night.|Did I say anything strange? I can't remember half of it.",
			easygoing = "I woke up and found twelve messages to you on my phone, all sent at three in the morning.|Was any of it weird?",
			gentle = "{player}, I hope I didn't keep you up last night.|Did I say anything odd? I was half asleep.",
			dreamy = "I think I sent you something about the moon last night...|Did it make any sense?",
			sunny = "{player}, I just read what I sent you last night!|Did I really say all that?",
			bold = "{player}, about my messages last night.|I said some weird stuff, right? Just tell me.",
			cheeky = "{player} ignore everything i sent last night|actually, what did i send",
			cool = "{player}.|About last night's messages, was any of it odd?",
			bookish = "{player}, I sent you nineteen messages last night.|Sorry, I was rambling, but did any of it make sense?",
			polite = "Good morning, {player}, I must apologise for my messages last night.|I hope I did not say anything strange.",
			foodie = "{player}, I think I texted you about cheese at midnight.|Was it as weird as I think?",
			_ = "{player}, did I say anything odd last night?|I was so tired that I can't remember.",
		}, "sweat")
		s:choice("Nothing you need to worry about.", function(c)
			burst(c, "a", {
				shy = "Oh, good.|Thank you.",
				prickly = "Good.|...You're lying, but thanks.",
				proud = "Just as I thought.",
				dramatic = "Phew, my reputation survives!",
				nervous = "Oh, okay.|Thank you, I was so worried.",
				dreamy = "Oh, good...|I thought I might have sent you a poem.",
				sunny = "Phew, ehehe!|Then let's pretend it never happened.",
				gentle = "Oh, thank goodness.|You're very kind, you know.",
				bold = "Good.|Let's never talk about it again, right?",
				easygoing = "Great, then I'll stop thinking about it.|Back to normal.",
				cheeky = "good|you didn't screenshot anything, right",
				cool = "Good.|Thanks.",
				bookish = "Good.|I'll put my phone in another room after ten, from now on.",
				gloomy = "Really?|Heh... that's a first.",
				polite = "That is a relief, thank you.|You are very kind.",
				foodie = "Phew.|I'll blame the late snack anyway.",
				_ = "Oh, good, thanks.",
			}, "heart")
			c:mood("a", 3)
		end)
		s:choice("Maybe you dreamed it.", function(c)
			burst(c, "a", {
				shy = "...So I did say something.|Okay, never mind, please don't tell me.",
				prickly = "That means yes.|Ugh.",
				dreamy = "Maybe I did...|It was a nice dream, then.",
				cheeky = "hahaha|ok what did i say",
				sunny = "Ehehe, so I did say something!|Okay, I'll just pretend I dreamed it too.",
				gentle = "Oh my, that means I did.|Well, let's leave it in the dream, okay?",
				bold = "That means I said something.|Fine, forget it, and we're good, right?",
				easygoing = "Eh, dreams are fine.|I'll go with that.",
				proud = "A dream, yes, naturally.|I'd never say anything silly while awake.",
				cool = "Hm.|I'll take that.",
				dramatic = "A DREAM? So it was that bad?|I'll never send a message after ten again.",
				bookish = "A dream, then.|Actually, lots of people send messages half asleep, I've read.",
				gloomy = "So I did say something.|Heh... as usual.",
				polite = "That is very kind of you to say so.|Let us leave it at that.",
				foodie = "A dream... was it about cheese?|It was about cheese, wasn't it?",
				nervous = "Oh no, so I did say something?|...Okay, okay, I'll just believe it was a dream.",
				_ = "Maybe I did.|Let's say I did.",
			}, "laugh", "laugh")
			c:mood("a", 2)
			c:hearts("a", 1)
		end)
		s:log("{a} asked if they'd said anything odd last night.")
		return s:done()
	end,
})

-- a picture they want you to see
local PICTURES = {
	"a cloud shaped exactly like a sheep",
	"the bakery cat asleep in the bread basket",
	"the harbour at sunrise, all pink",
	"a duck sitting in a puddle in the square",
	"their first ever tomato",
}

event({
	id = "lookphoto",
	when = "day",
	weight = W({ base = 0.1, traits = { social = 0.15 } }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "A picture"):with({ pic = ctx.rng:pick(PICTURES) })
		s:prop("camera", "a")
		burst(s, "a", {
			sunny = "{player}, {player}, look at this!",
			proud = "I took a picture.|You'll want to see it, everyone does.",
			shy = "Um, {player}, I took a picture.|You don't have to look if you're busy.",
			dramatic = "{player}, I took the most AMAZING picture.",
			cool = "{player}.|Look at this.",
			foodie = "Look what I saw on my way to lunch.",
			gentle = "{player}, I took a picture this morning, and it made me smile.|I wanted to show you.",
			dreamy = "I took a picture this morning...|It's my favourite one so far.",
			cheeky = "{player} look at this picture i took|best one i've ever taken, easily",
			easygoing = "{player}, I took a picture without even getting up.|Want to see?",
			prickly = "I took a picture, and it's actually good.|Look at it, and don't make a fuss.",
			bookish = "{player}, I've been practising with my camera.|This is picture number forty-one.",
			gloomy = "I took a picture, and it didn't come out blurry.|Heh... look.",
			polite = "Good morning, {player}, may I show you a picture I took?",
			nervous = "{player}, I took a picture, and I've never shown anyone one before.|Can you look?",
			bold = "{player}, come here and look at this picture I took.",
			_ = "{player}, look at the picture I took this morning.",
		}, "sparkle")
		s:n("It was {pic}.")
		burst(s, "a", {
			proud = "It's good, isn't it?|Go on, say it.",
			shy = "Is it okay?",
			gloomy = "It actually came out, which is a first.",
			bookish = "Actually, I waited twenty minutes for the light to be right.",
			nervous = "Is it good? Be honest, but not too honest.",
			cheeky = "go on, tell me it's good",
			sunny = "Isn't it great, great?",
			gentle = "It made me smile, and I hope it does the same for you.",
			bold = "Great shot, right?",
			dreamy = "Look at the little shadow in the corner...",
			easygoing = "Not bad for a lazy shot, right?",
			cool = "I like it.",
			prickly = "It's good, right? ...Say it is.",
			dramatic = "It's the picture of the YEAR.",
			polite = "I hope you like it.",
			foodie = "It's almost as nice as the lunch I had after.",
			_ = "It's good, right?",
		}, "question")
		s:choice("That's a great picture.", function(c)
			burst(c, "a", {
				proud = "Naturally.|Say it again, but louder.",
				shy = "...!|Thank you.",
				sunny = "Right? I'm going to take loads more!",
				gloomy = "Really?|Heh... okay, I'll keep it.",
				cool = "...Thanks.",
				gentle = "Thank you, I'm glad it made you smile too.",
				dreamy = "I'll keep it in my notebook...|Thank you for looking.",
				cheeky = "obviously, i'm very talented",
				nervous = "Really? Oh, phew.|I nearly didn't show anyone.",
				bold = "Hah, I know.|I'm taking a better one tomorrow.",
				easygoing = "Thanks.|I'll take more when I feel like it.",
				prickly = "Obviously.|...But thanks for looking.",
				dramatic = "You LOVE it!|I'm putting it in a frame right now.",
				bookish = "Thank you.|It took eleven tries, actually.",
				polite = "Thank you kindly.|I am very pleased you like it.",
				foodie = "Thanks!|I'll take one of my lunch tomorrow, it's even better.",
				_ = "I knew you'd like it.",
			}, "heart")
			c:mood("a", 4)
			c:hearts("a", 1)
		end)
		s:choice("Is that your thumb in the corner?", function(c)
			burst(c, "a", {
				proud = "Th-that's part of it.|It shows how big everything is.|Anyway!",
				prickly = "It's a frame.|Ugh, fine, it's my thumb.",
				cheeky = "my thumb wanted to be in it too",
				shy = "Oh no, it is...",
				dramatic = "That thumb is ART.",
				sunny = "My thumb? Oh no, ehehe!|I'll take another one, without the thumb.",
				gentle = "Oh my, it is.|Well, it's a friendly thumb.",
				bold = "So what? It's a good thumb, right?",
				dreamy = "My thumb...?|Oh, it looks like a little hill.",
				easygoing = "Yeah, I didn't move it.|Eh, it's fine, it's part of the picture now.",
				cool = "It is.|I'll cut it out.",
				bookish = "It is my thumb, actually.|That's the third time this week.",
				gloomy = "Of course it is.|Heh... every picture I take has a thumb in it.",
				polite = "Oh dear, so it is.|Please forgive my thumb.",
				foodie = "My thumb? Oh, and it's a bit sticky from the jam bun, too.",
				nervous = "My thumb? Oh no, it's ruined, isn't it?|I'll take another one.",
				_ = "...It is.|Just ignore the thumb.",
			}, "sweat")
			c:mood("a", 1)
		end)
		s:log("{a} showed you a picture of {pic}.")
		return s:done()
	end,
})

-- an invite for tomorrow
local TOMORROWS = {
	{ what = "a morning's fishing", place = "the end of the pier", time = "seven" },
	{ what = "breakfast", place = "the café", time = "nine" },
	{ what = "a walk up the hill", place = "the fountain", time = "ten" },
	{ what = "a look round the market", place = "the market gate", time = "eleven" },
}

event({
	id = "invite",
	when = "day",
	weight = W({ base = 0.11, traits = { social = 0.2 } }),
	scene = function(ctx, a)
		local t = ctx.rng:pick(TOMORROWS)
		local s = K.scene(ctx, "Tomorrow?"):with({
			what = t.what,
			place = t.place,
			time = t.time,
			What = upper(t.what),
			Place = upper(t.place),
		})
		burst(s, "a", {
			sunny = "{player}, are you free tomorrow?|Say yes, say yes!",
			bold = "{player}, you're free tomorrow morning, right?",
			shy = "Um, {player}, are you busy tomorrow?|You can say if you are.",
			polite = "Hello, {player}.|Are you free tomorrow morning, by any chance?",
			cool = "{player}.|Are you free tomorrow?",
			cheeky = "{player} you're free tomorrow|i checked",
			easygoing = "{player}, have you got anything on tomorrow?|My whole day's empty, which I planned very carefully.",
			gentle = "{player}, are you free tomorrow morning?|I'd love some company, if you're not too busy.",
			dreamy = "{player}, are you doing anything tomorrow?|I've had a nice idea, I think.",
			proud = "{player}, I have a free day tomorrow, and I've decided to spend some of it with you.|Are you free?",
			prickly = "{player}, are you busy tomorrow?|Not that I'm asking for any reason.",
			dramatic = "{player}, tomorrow could be the BEST day ever.|Are you free?",
			bookish = "{player}, are you free tomorrow?|I've got a plan, and it's very well organised.",
			gloomy = "Are you free tomorrow?|Heh... you're probably busy.",
			foodie = "{player}, are you free tomorrow?|I've got a plan, and there's food at the end of it.",
			nervous = "{player}, are you free tomorrow? Sorry, is that a weird question?|I've got an idea, if you want.",
			_ = "{player}, are you free tomorrow?",
		}, "question")
		s:choice("Yes, I'm free.", function(c)
			burst(c, "a", {
				sunny = "I knew it!|Come for {what} with me, and we'll meet at {place} at {time}.",
				bold = "Good, then we're going for {what}.|Meet me at {place} at {time}, and don't be late.",
				shy = "Oh, good...|Would you come for {what} with me?|We could meet at {place} at {time}, if that's okay.",
				polite = "Wonderful.|Would {what} suit you? We could meet at {place} at {time}.",
				cool = "Good.|Meet me at {place} at {time} for {what}.",
				gentle = "Oh, lovely.|Would you come for {what} with me? We could meet at {place} at {time}.",
				dreamy = "Good...|Let's go for {what}, and meet at {place} at {time}.",
				cheeky = "knew it|{place} at {time}, we're doing {what}",
				easygoing = "Nice, then let's do {what}.|Meet me at {place} at {time}, if I'm awake.",
				proud = "Excellent.|We're going for {what}, and you'll meet me at {place} at {time}.",
				prickly = "Fine, good, then it's {what}.|Meet me at {place} at {time}, and don't be late.",
				dramatic = "YES!|We're going for {what}, so meet me at {place} at {time}!",
				bookish = "Good.|I'm thinking {what}, meeting at {place} at {time}, and I've checked the weather.",
				gloomy = "Oh... good.|We could go for {what}, at {place}, at {time}, if you want.",
				foodie = "Yay!|Let's go for {what}, then lunch after, and meet at {place} at {time}.",
				nervous = "Oh, good!|Would {what} be okay? We could meet at {place} at {time}, if that's okay.",
				_ = "Good.|How about {what}?|We could meet at {place} at {time}.",
			}, "heart")
			c:mood("a", 4)
			c:memo("a", "Tomorrow it's {what} with the {player}, and we're meeting at {place} at {time}.")
		end)
		s:choice("Depends what for.", function(c)
			burst(c, "a", {
				sunny = "It's {what}, so now you're free, right?",
				bold = "It's {what}, so you're free.",
				cheeky = "you'll find out|{place} at {time}, be there",
				shy = "Oh, um, I was thinking of {what}...|Only if you'd like to.",
				gentle = "Oh, I was thinking of {what}.|Could we meet at {place} at {time}, okay?",
				dreamy = "Hmm... {what}, I think.|At {place}, at {time}.",
				easygoing = "Just {what}, nothing big.|We could meet at {place} at {time}, if you're up.",
				proud = "It's {what}, and it'll be wonderful.|Meet me at {place} at {time}.",
				cool = "It's {what}.|Meet me at {place} at {time}.",
				prickly = "Ugh, it's {what}, okay?|Meet me at {place} at {time}, if you want.",
				dramatic = "It's {what}, and it'll be MAGICAL.|Meet me at {place} at {time}.",
				bookish = "I was thinking {what}.|I've planned it to the minute, so meet me at {place} at {time}.",
				gloomy = "Just {what}.|Heh... at {place} at {time}, if you still want to.",
				polite = "I was thinking of {what}.|Would {place} at {time} suit you?",
				foodie = "It's {what}, and I'm bringing snacks.|Meet me at {place} at {time}.",
				nervous = "I-it's {what}, is that okay?|We could meet at {place} at {time}.",
				_ = "I was thinking {what}.|Could we meet at {place} at {time}?",
			}, "idea")
			c:mood("a", 3)
			c:memo("a", "Tomorrow it's {what} with the {player}, and we're meeting at {place} at {time}.")
		end)
		s:log("{a} asked you along for {what} tomorrow.")
		return s:done()
	end,
})

-- sorry for yesterday
event({
	id = "sorryday",
	when = "any",
	weight = W({ base = 0.08, traits = { temper = 0.2 } }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "About yesterday")
		burst(s, "a", {
			polite = "Hello, {player}.|About yesterday, I was rude to you, and I apologise.",
			prickly = "{player}, about yesterday.|I was rude to you.|...Sorry.",
			bold = "{player}, about yesterday.|I snapped at you, and that wasn't fair.",
			gloomy = "{player}, yesterday was a bad day.|I took it out on you, and I'm sorry.",
			proud = "{player}, about yesterday.|I was not at my best, and that's all I'll say.",
			nervous = "{player}, I'm so sorry about yesterday.|I was horrible to you, and I've been thinking about it all night.",
			cool = "{player}, about yesterday.|I'm sorry.",
			gentle = "{player}, about yesterday.|I was grumpy with you, and I'm sorry, I didn't mean it.",
			dreamy = "{player}, I was in a strange mood yesterday...|I think I snapped at you, and I'm sorry.",
			sunny = "{player}, I'm really sorry about yesterday.|I was grumpy, and it wasn't fair on you.",
			easygoing = "{player}, about yesterday.|I was grumpy, which isn't like me, and I'm sorry.",
			shy = "Um, {player}... about yesterday.|I'm sorry I was rude, I didn't mean it.",
			cheeky = "{player} about yesterday|i was being a pain, sorry, for real this time",
			dramatic = "{player}, I was a MONSTER yesterday.|Can you ever forgive me?",
			bookish = "{player}, about yesterday.|I was rude to you, and I've thought about it a lot since.",
			foodie = "{player}, about yesterday, I hadn't eaten all day and I was awful to you.|I'm sorry.",
			_ = "{player}, about yesterday.|I was in a bad mood, and I'm sorry.",
		}, "sad")
		s:choice("It's already forgotten.", function(c)
			burst(c, "a", {
				prickly = "...Good.|Thanks.",
				polite = "Thank you, that is very kind of you.|I will bring you some tea later, if you would like.",
				nervous = "Really? Oh, thank you so much.",
				gloomy = "Okay...|Thanks, {player}.",
				sunny = "Really? Ehehe, thank you!|Let's get ice cream later, my treat.",
				gentle = "Oh, thank you, that means so much.|Take care of yourself today, okay?",
				bold = "Good.|...Thanks. Anyway, lunch is on me.",
				dreamy = "Oh... thank you.|It feels like the sun came out.",
				easygoing = "Thanks, that's a relief.|Let's just have a nice day, then.",
				proud = "Good.|I knew you'd be gracious about it, like me.",
				shy = "Really?|Thank you... I was so worried.",
				cheeky = "phew|you're the best, don't tell anyone i said that",
				cool = "Thanks.|I'll make it up to you.",
				dramatic = "FORGOTTEN? You're too kind!|I don't deserve you.",
				bookish = "Thank you.|I wrote down three ways to say sorry, and I only needed one.",
				foodie = "Thank you!|I'm bringing you a pie later, no arguments.",
				_ = "Thank you, that means a lot.",
			}, "heart")
			c:mood("a", 4)
		end)
		s:choice("Are you okay now?", function(c)
			burst(c, "a", {
				prickly = "I'm fine.|...Better, actually, thanks for asking.",
				bold = "Yeah, I'm fine.|Thanks, and lunch is on me.",
				gloomy = "Oh...|Yeah, a bit better.",
				cool = "...Yeah, I'm okay now. Thanks.",
				proud = "Naturally, I'm fine now.|...Thank you for asking.",
				sunny = "I'm much better now!|Thanks for asking, really.",
				gentle = "I'm better now, thank you.|And you? Have you been sleeping okay?",
				dreamy = "Hmm... yes, I think so.|The clouds have moved on.",
				easygoing = "Yeah, I'm good now.|I had a long nap, and that fixed most of it.",
				shy = "I'm okay now...|Thank you for asking.",
				cheeky = "yeah, i'm good|thanks for asking, that's sweet",
				dramatic = "I'm myself AGAIN!|Thank you for asking.",
				bookish = "I'm better, thank you.|I slept nine hours, which helped a lot.",
				polite = "I am much better now, thank you for asking.|Have a lovely day.",
				foodie = "I'm better now.|I had a proper breakfast, which helped.",
				nervous = "I-I'm okay now, I think.|Thank you for asking, really.",
				_ = "Yeah, I'm better now.|Thanks for asking.",
			}, "heart")
			c:hearts("a", 1)
			c:mood("a", 5)
		end)
		s:log("{a} said sorry for yesterday.")
		return s:done()
	end,
})

-- guess what's in my pocket
event({
	id = "guessquiz",
	when = "day",
	weight = W({ base = 0.1, traits = { mischief = 0.2 } }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "Guess")
		burst(s, "a", {
			cheeky = "{player} guess what's in my pocket|you'll never get it",
			sunny = "{player}, guess what's in my pocket!|Guess, guess!",
			bookish = "Here's a small test for you.|What do you think is in my pocket?",
			foodie = "Guess what's in my pocket.|Here's a hint, it's still warm.",
			dramatic = "There is a MYSTERY in my pocket.|Can you guess what it is?",
			gentle = "{player}, I've got a little something in my pocket.|Can you guess what it is?",
			dreamy = "There's something in my pocket that I found this morning...|Can you guess what it is?",
			bold = "{player}, guess what's in my pocket.|One try, and make it good.",
			easygoing = "Guess what's in my pocket.|No rush, take your time.",
			proud = "{player}, I have something rather special in my pocket.|I doubt you can guess what.",
			shy = "Um, {player}, can you guess what's in my pocket?|It's nothing big.",
			cool = "Guess what's in my pocket.",
			prickly = "Guess what's in my pocket.|And no silly guesses.",
			gloomy = "Guess what's in my pocket.|Heh... it's nothing exciting.",
			polite = "{player}, would you like to guess what is in my pocket?",
			nervous = "{player}, guess what's in my pocket?|It's not a bug, don't worry.",
			_ = "{player}, guess what's in my pocket.|I'll give you two tries.",
		}, "idea")
		-- either way, the answer
		local reveal = K.byPers(ctx, ctx.stars and ctx.stars.a, {
			cheeky = "nothing hehe|made you guess, though",
			foodie = "It's a bun, and it's still warm.|Do you want half?",
			bookish = "It's an empty snail shell.|I checked that it was empty, don't worry.",
			sunny = "It's a marble!|It's the shiniest one in town.",
			dramatic = "A single button...|From a coat I have never seen.",
			gloomy = "It's a bit of string.|Heh... that's all I ever have.",
			dreamy = "It's a feather from a gull.|I've been carrying it around all day.",
			gentle = "It's a toffee I saved for you.|Here, take it.",
			bold = "It's a whistle, and it's really loud.|Want to hear?",
			easygoing = "It's a candy wrapper.|I didn't feel like walking to the trash can.",
			proud = "It's a medal from the fishing contest.|First place, naturally.",
			shy = "It's a little drawing I did...|Of the harbour, and it's not very good.",
			cool = "It's a key.|I don't know what it opens.",
			prickly = "It's a lucky coin.|Don't laugh, it works.",
			polite = "It is a clean handkerchief.|A person should always carry one.",
			nervous = "It's a bandage.|I always carry one, just in case something happens.",
			_ = "It's a pebble from the beach.|It's a really good one.",
		})
		s:choice("Is it a cookie?", function(c)
			burst(c, "a", {
				polite = "No, I am afraid it is not a cookie.",
				cool = "No.",
				cheeky = "nope",
				sunny = "Nope! Ehehe, good guess, though.",
				gentle = "Oh, not a cookie, no.|Are you hungry, dear?",
				bold = "No, wrong.|Try again.",
				dreamy = "A cookie...? No.|But now I want one.",
				easygoing = "Nah, I'd have eaten it by now.",
				proud = "A cookie? Hmph, it's far more interesting than that.",
				shy = "Um, no... sorry.",
				prickly = "No, obviously not a cookie.",
				dramatic = "A COOKIE? You think so little of my pocket?",
				bookish = "No, though cookies are the most common thing to find in a pocket, actually.",
				gloomy = "No.|Heh... I wish it was.",
				foodie = "Close, it's something to eat, but no.",
				nervous = "N-no, not a cookie, sorry!",
				_ = "Nope, not a cookie.",
			}, "laugh")
			say(c, "a", reveal, "sparkle")
			c:mood("a", 2)
		end)
		s:choice("Is it a frog?", function(c)
			burst(c, "a", {
				polite = "A frog? Goodness, no.",
				cheeky = "why would i have a frog in my pocket|...don't answer that",
				sunny = "A frog? Ehehe, no, no!",
				gentle = "A frog? Oh my, no.|The poor thing would be squashed.",
				bold = "A frog? Hah, no way.",
				dreamy = "A frog... that would be nice, actually.|But no.",
				easygoing = "A frog? Too much work to carry around.",
				proud = "A frog? Certainly not.",
				shy = "A frog? N-no...",
				cool = "No frogs.",
				prickly = "A frog? Ugh, no.",
				dramatic = "A FROG? In MY pocket? Never!",
				bookish = "No, though there are four kinds of frog in the pond by the hill, actually.",
				gloomy = "No.|Heh... the frogs don't like me either.",
				foodie = "A frog? No, and I don't want to think about that near my lunch.",
				nervous = "A frog? No, no, I'd scream.",
				_ = "Why would it be a frog?|No, it's not a frog.",
			}, "laugh", "laugh")
			say(c, "a", reveal, "sparkle")
			c:mood("a", 2)
		end)
		s:log("{a} made you guess what was in their pocket.")
		return s:done()
	end,
})

-- a long day let out, then taken back
event({
	id = "vent",
	when = "any",
	weight = W({ base = 0.1, job = "any", traits = { temper = 0.2 } }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "A long one"):with({ job = K.workplace(ctx, a) })
		burst(s, "a", {
			prickly = "{player}, today at the {job} was a mess from start to finish.|Then the coffee machine broke, and someone asked if I was tired.|Of course I'm tired!",
			polite = "Forgive me, {player}, I just need to say this to someone.|The {job} was very hard today, and everything went wrong at once.",
			gloomy = "Everything went wrong at the {job} today.|Even the things that never go wrong went wrong, as usual.",
			bold = "Two people were off today, so I ran the {job} on my own.|I did all of it, and now I'm done.",
			nervous = "I got so many things mixed up at the {job} today.|Nobody got angry with me, but I was angry with myself.",
			gentle = "I'm sorry, I need to tell someone about my day.|Everything at the {job} took twice as long as it should have.",
			dreamy = "Today at the {job} went wrong from the very start...|I feel like I've been underwater all day.",
			sunny = "Today at the {job} was the worst!|Everything that could go wrong did.",
			easygoing = "Today at the {job} was so busy that I didn't sit down once.|Not even once, and you know me.",
			proud = "{player}, today at the {job} was a disaster, and none of it was my fault.|Well, almost none of it.",
			shy = "Um, {player}, today at the {job} was really hard.|Sorry, I just needed to tell someone.",
			cheeky = "{player} today at the {job} was the worst|i dropped a whole box, then tripped over it, then dropped it again",
			cool = "It was a long day at the {job}.|Everything went wrong.",
			dramatic = "{player}, today at the {job} was a DISASTER from start to finish.|I barely made it out alive.",
			bookish = "Today at the {job}, eleven things went wrong.|I counted them, which probably didn't help.",
			foodie = "Today at the {job} was so busy that I missed lunch.|I missed lunch, {player}, and nobody even noticed.",
			_ = "{player}, it was such a long day at the {job}.|Everything piled up at once.",
		}, "sad")
		s:say("a", "...Sorry, that was a lot to say all at once.", "sweat")
		s:choice("You do so much.", function(c)
			burst(c, "a", {
				prickly = "Ugh, don't say that.|...Thanks.",
				polite = "That is kind of you to say.|Please forget how much I complained.",
				gloomy = "...|Thanks, and forget I said all that, okay?",
				bold = "Hah! Somebody has to.|...Thanks, though.",
				gentle = "That's kind of you.|I'm sorry for going on and on.",
				sunny = "You think so? Ehehe, thanks!|I feel better already.",
				dreamy = "Hmm... thank you.|It feels lighter, now that I've said it.",
				easygoing = "Thanks.|I think I've earned a long nap now.",
				proud = "I do, don't I?|Thank you for noticing.",
				shy = "Oh...|Thank you, really.",
				cheeky = "i do, don't i|you can tell everyone that hehe",
				cool = "Thanks.|That helps.",
				dramatic = "Someone NOTICED!|Thank you, {player}.",
				bookish = "Thank you.|Sorry, I was rambling again.",
				foodie = "Thanks.|I'm going to make a big dinner and forget all about it.",
				nervous = "Really? You don't think I messed up?|Thank you, that helps.",
				_ = "Oh... thanks.|Forget I said all that, okay?",
			}, "heart")
			c:mood("a", 5)
		end)
		s:choice("Let me help tomorrow.", function(c)
			burst(c, "a", {
				prickly = "You'd only get in the way.|...Come at nine.",
				polite = "You would do that?|Then thank you, and nine o'clock, if that is all right.",
				bold = "Yeah? Good, nine o'clock.|I always pay back a favour.",
				nervous = "Really? Oh, thank you so much.",
				sunny = "Really? Yay!|Come at nine, and we'll do it together.",
				gentle = "Oh, you're so kind.|Come at nine, and have breakfast first, okay?",
				dreamy = "You'd do that...?|Then tomorrow won't feel so heavy.",
				easygoing = "Really? That'd be great.|Come at nine, or ten, whenever.",
				proud = "Very well, I'll allow it.|Nine o'clock, and don't be late.",
				shy = "Really?|Um... thank you, is nine o'clock okay?",
				cheeky = "yes please|i'm giving you all the boring jobs hehe",
				cool = "Okay.|Come at nine.",
				dramatic = "You'd DO that for me?|Nine o'clock, my hero.",
				bookish = "Thank you.|I'll make you a list of jobs, with times.",
				gloomy = "You'd do that?|Heh... okay, thanks.",
				foodie = "Really? I'll make you lunch.|Come at nine.",
				_ = "You would?|Thank you, that would really help.",
			}, "heart")
			c:hearts("a", 1)
			c:mood("a", 5)
			c:xp("a", 4)
		end)
		s:log("{a} told you about a bad day at work.")
		return s:done()
	end,
})

-- a part in their story
local ROLES = {
	{
		role = "a sidekick",
		mine = "my sidekick",
		theirs = "their sidekick",
		today = "We're going to find out who keeps ringing the hall bell at midnight.",
		memo = "{player} was my sidekick today, and we nearly caught whoever rings the hall bell.",
	},
	{
		role = "a witness",
		mine = "my witness",
		theirs = "their witness",
		today = "I'm going to skip a stone ten times, and I need someone to see it.",
		memo = "{player} saw me skip a stone ten times, so it officially happened.",
	},
	{
		role = "an apprentice",
		mine = "my apprentice",
		theirs = "their apprentice",
		today = "I'm going to teach you how to build the perfect sandcastle.",
		memo = "{player} is my sandcastle apprentice now, and they're learning fast.",
	},
	{
		role = "a judge",
		mine = "my judge",
		theirs = "their judge",
		today = "You're going to judge the paper boat race at the harbour this afternoon.",
		memo = "{player} judged the paper boat race, and everyone agreed it was fair.",
	},
}

event({
	id = "sidekick",
	when = "day",
	weight = W({ base = 0.1, traits = { social = 0.2, mischief = 0.2 } }),
	scene = function(ctx, a)
		local r = ctx.rng:pick(ROLES)
		local s = K.scene(ctx, "A part for you"):with({ role = r.role, mine = r.mine, theirs = r.theirs })
		burst(s, "a", {
			dramatic = "{player}, the moment has finally come.|From today, you will be {mine}.",
			cheeky = "{player} congratulations|you're {mine} now, no take backs",
			sunny = "{player}, I've got big news!|I've picked you to be {mine}.",
			dreamy = "{player}...|I need {role}, and I decided it's you.",
			bold = "{player}, I need {role}, and you're it.|You're free today, right?",
			gentle = "{player}, I need {role} today.|Would you mind? It'd mean a lot.",
			shy = "Um, {player}, I need {role} today.|Would you do it? You don't have to.",
			polite = "{player}, may I ask you to be {mine} today?|I would be very grateful.",
			proud = "{player}, I've chosen you to be {mine} today.|It's quite an honour, naturally.",
			nervous = "{player}, c-could you be {mine} today?|I can't think of anyone else I'd ask.",
			easygoing = "{player}, I need {role} today.|It's an easy job, I promise, I picked it myself.",
			cool = "{player}, I need {role} today.|You're it.",
			prickly = "{player}, I need {role} today.|Don't make a big deal of it, just say yes.",
			bookish = "{player}, I need {role} today.|I've thought about it, and you're the best choice, actually.",
			gloomy = "{player}, I need {role} today.|Heh... you'll probably say no, but I'm asking.",
			foodie = "{player}, I need {role} today.|I'll pay you in sandwiches.",
			_ = "{player}, I need {role} today, and I thought of you.",
		}, "sparkle", "point")
		burst(s, "a", { cheeky = r.today:lower(), _ = r.today }, "idea")
		s:choice("I'm in.", function(c)
			burst(c, "a", {
				dramatic = "*trumpet noise*|...That was me, in case you were wondering.",
				cheeky = "excellent hehe|i knew you'd say yes",
				sunny = "Yes! Meet me at the fountain, let's go!",
				dreamy = "Good...|I'll be waiting by the water.",
				bold = "Hah! Good.|Meet me at the fountain in ten minutes, and don't be late.",
				nervous = "Th-thank you!|Meet me at the fountain in ten minutes, okay?",
				gentle = "Oh, thank you.|Meet me at the fountain in ten minutes, okay?",
				easygoing = "Nice.|Meet me at the fountain in ten minutes, or fifteen.",
				proud = "Naturally.|Meet me at the fountain in ten minutes.",
				shy = "Really?|Thank you... could we meet at the fountain in ten minutes?",
				cool = "Good.|Meet me at the fountain in ten minutes.",
				prickly = "Good, meet me at the fountain in ten minutes.|Don't be late.",
				bookish = "Excellent.|Meet me at the fountain in ten minutes, I've planned everything.",
				gloomy = "Oh... you said yes.|Meet me at the fountain in ten minutes, then.",
				polite = "Thank you kindly.|Could we meet at the fountain in ten minutes?",
				foodie = "Yay!|Meet me at the fountain in ten minutes, and I'll bring snacks.",
				_ = "Good.|Meet me at the fountain in ten minutes.",
			}, "sparkle", "cheer")
			c:hearts("a", 1)
			c:mood("a", 5)
			c:memo("a", r.memo)
		end)
		s:choice("Why me?", function(c)
			burst(c, "a", {
				dramatic = "Why you? WHY YOU?|...Because everyone else said no.",
				cheeky = "you were the nearest, that's why",
				sunny = "Because you're the best, obviously.|Meet me at the fountain in ten minutes.",
				dreamy = "Yours was the first name I thought of.",
				gentle = "Because you're the kindest person I know.|Meet me at the fountain in ten minutes, all right?",
				shy = "Um, because I trust you...|Could you meet me at the fountain in ten minutes?",
				polite = "Because I could not think of anyone better.|Could we meet at the fountain in ten minutes?",
				bold = "Because you're good at it, right?|Meet me at the fountain in ten minutes.",
				easygoing = "You were the first person I thought of, and I didn't want to think any more.|Meet me at the fountain in ten minutes.",
				proud = "Because I only choose the best, naturally.|Meet me at the fountain in ten minutes.",
				cool = "You're good at this.|Meet me at the fountain in ten minutes.",
				prickly = "Don't read into it, you're just good at this.|Meet me at the fountain in ten minutes.",
				bookish = "I made a list, and you came out on top.|Meet me at the fountain in ten minutes.",
				gloomy = "Because you're the only one who listens.|Heh... meet me at the fountain in ten minutes.",
				foodie = "Because you always share your snacks.|Meet me at the fountain in ten minutes.",
				nervous = "B-because I trust you, is that okay?|Could you meet me at the fountain in ten minutes?",
				_ = "Because you're good at this sort of thing.|Meet me at the fountain in ten minutes.",
			}, "question")
			c:mood("a", 3)
		end)
		s:log("{a} made you {theirs}.")
		return s:done()
	end,
})

-- a favour, and what came of it
local FAVOURS = {
	{
		ask = "hold the ladder while I fix my gutter",
		after = "The gutter's fixed, so the next storm can do its worst.",
	},
	{ ask = "help me carry a sofa up the hill", after = "The sofa's finally in, but I can't feel my arms." },
	{
		ask = "stand at the stall while I get more bread",
		after = "We sold out, and you sold more than half of it.",
	},
	{ ask = "help me find my cat", after = "She was on the roof the whole time, just watching us look." },
}

event({
	id = "favour",
	when = "day",
	weight = W({ base = 0.12, traits = { social = 0.1 } }),
	scene = function(ctx, a)
		local f = ctx.rng:pick(FAVOURS)
		local s = K.scene(ctx, "A favour"):with({ ask = f.ask, after = f.after })
		burst(s, "a", {
			sunny = "{player}, are you free right now?|Could you {ask}?|You only need to be there, I promise.",
			shy = "Um, {player}, if you're not busy...|Could you {ask}?|You wouldn't have to do much.",
			bold = "{player}, you're free, right?|I need you to {ask}.|It won't take long.",
			polite = "Hello, {player}, I am sorry to interrupt.|Could you possibly {ask}, if it is no trouble?",
			cool = "{player}.|Can you {ask}?",
			easygoing = "{player}, could you {ask}?|No rush, but I'll pay you in cookies.",
			nervous = "{player}, s-sorry to ask.|Could you {ask}?|You can say no, I won't mind.",
			gentle = "{player}, I'm sorry to ask, but could you {ask}?|It would help me so much.",
			dreamy = "{player}, could you {ask}?|You were the first person I thought of.",
			prickly = "{player}, I need you to {ask}.|Don't make a big thing of it.",
			proud = "{player}, I've decided you're the right person for a small job.|Could you {ask}?",
			cheeky = "{player} you're not doing anything, right|good, then you can {ask} hehe",
			dramatic = "{player}, I need your help, and it's URGENT.|Could you {ask}?",
			bookish = "{player}, it's a job for two people, I've checked.|Could you {ask}? It should take about an hour.",
			gloomy = "{player}, could you {ask}?|Heh... I'd do it myself, but it would go wrong.",
			foodie = "{player}, could you {ask}?|There's cake in it for you.",
			_ = "{player}, are you free?|Could you {ask}?",
		}, "question")
		s:choice("On my way.", function(c)
			c:n("You went round to help, and it took about an hour.")
			say(c, "a", "{after}", "heart")
			burst(c, "a", {
				sunny = "Thank you!|Next time, I'm helping you.",
				bold = "...Thanks, I owe you one.|I always pay back.",
				polite = "Thank you, {player}.|I'll return the favour properly.",
				cool = "...Thanks.",
				gloomy = "That actually went well.|Heh... thanks.",
				proud = "...You were a great help, I'll admit.|I'll return the favour, naturally.",
				gentle = "Thank you so much.|Come round for tea soon, all right?",
				dreamy = "Thank you...|It felt easy with two.",
				easygoing = "Thanks, that was a lot less work with you.|I owe you a nap... I mean, a favour.",
				shy = "Thank you so much...|I couldn't have done it alone.",
				cheeky = "thanks|you're actually useful, who knew hehe",
				prickly = "Thanks.|...I mean it, so don't make a thing of it.",
				dramatic = "You SAVED me, {player}!|I'll never forget this.",
				bookish = "Thank you.|It took fifty-eight minutes, which is faster than I planned.",
				foodie = "Thank you!|Come round tonight, I'm making you dinner.",
				nervous = "Thank you so much, really.|Nothing went wrong, and that's because of you.",
				_ = "Thanks so much.|I owe you one.",
			}, "heart")
			c:hearts("a", 1)
			c:mood("a", 5)
		end)
		s:choice("Only if there's tea.", function(c)
			burst(c, "a", {
				easygoing = "Mm, there's always tea.",
				bold = "Hah! Fine, there'll be tea.",
				cheeky = "tea and a cookie, final offer",
				sunny = "There's tea, and cake too, ehehe!",
				gentle = "Of course there's tea.|I'll put the pot on now.",
				dreamy = "Tea, yes...|I've got the one that smells like flowers.",
				proud = "There's tea, and it's the best tea in town, naturally.",
				shy = "Um, yes, there's tea...|I hope you like it.",
				cool = "There's tea.|Come round.",
				prickly = "Fine, there's tea.|Don't get used to it.",
				dramatic = "TEA? There will be a whole POT!",
				bookish = "There's tea, three kinds actually.|You can pick.",
				gloomy = "There's tea.|Heh... it's the cheap kind, sorry.",
				polite = "Of course there is tea.|Please come round.",
				foodie = "Tea, and buns, and jam, and maybe soup.|Come round.",
				nervous = "There's tea, I think... yes, there's tea.|Come round.",
				_ = "There's tea, I promise.|Come round.",
			}, "laugh", "laugh")
			c:n("You went round to help. There was tea, and it took about an hour.")
			say(c, "a", "{after}", "heart")
			c:mood("a", 4)
		end)
		s:log("{a} asked you for a favour.")
		return s:done()
	end,
})

-- a small win
local WINS = {
	"I didn't drop a single thing at work today.",
	"I said hello to someone first.",
	"I got up the first time my alarm went off.",
	"My bread rose properly for once.",
}

event({
	id = "smallwin",
	when = "day",
	weight = W({ base = 0.1, traits = { brave = -0.25 } }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "A good day"):with({ win = ctx.rng:pick(WINS) })
		burst(s, "a", {
			nervous = "{player}, guess what?|{win}|I-I know it's a small thing, but it felt big.",
			shy = "Um, {player}?|{win}|That's all, I just wanted to tell someone.",
			gloomy = "Something went right for once.|{win}|Now I'm waiting for the catch.",
			sunny = "{player}, guess what!|{win}",
			proud = "{player}, I have news.|{win}|Go on, you can say you're impressed.",
			gentle = "{player}, something nice happened today.|{win}",
			dreamy = "{player}, guess what...|{win}|I'm still a bit surprised.",
			bold = "{player}, listen to this.|{win}|Not bad, right?",
			dramatic = "{player}, something INCREDIBLE happened today.|{win}",
			easygoing = "{player}, guess what...|{win}|And I didn't even try that hard.",
			cheeky = "{player} guess what|{win}|you can clap now",
			cool = "{player}.|{win}",
			prickly = "Don't make a big deal of it, but listen.|{win}",
			bookish = "{player}, I have a small update.|{win}|That's the first time this month, actually.",
			polite = "Good afternoon, {player}, may I share some good news?|{win}",
			foodie = "{player}, guess what!|{win}|I'm having a cake to celebrate.",
			_ = "{player}, guess what?|{win}",
		}, "sparkle")
		s:choice("That's a big deal.", function(c)
			burst(c, "a", {
				nervous = "Is it? Oh, thank you.",
				shy = "...!|Thank you.",
				gloomy = "Heh...|Okay, I'll let it be a big deal.",
				proud = "It is, isn't it?",
				gentle = "Thank you, it does feel nice.",
				dramatic = "It IS a big deal, thank you!|I'm telling everyone.",
				sunny = "It is, it is!|Ehehe, let's celebrate.",
				bold = "Right? I knew you'd get it.",
				dreamy = "Hmm... it does feel big, doesn't it?",
				easygoing = "Yeah, I'm pretty happy about it.|I might reward myself with a nap.",
				cheeky = "it really is|i'm putting it on a poster hehe",
				cool = "It is.|Thanks.",
				prickly = "It's not that big.|...Okay, it's a bit big.",
				bookish = "It is, actually.|Small changes add up, I read that somewhere.",
				polite = "Thank you kindly, I think so too.",
				foodie = "It is!|I'm celebrating with pie.",
				_ = "I know, right?",
			}, "heart")
			c:mood("a", 5)
		end)
		s:choice("Told you you'd manage.", function(c)
			burst(c, "a", {
				nervous = "You did say that, didn't you?",
				gloomy = "You did.|...Don't get used to it.",
				prickly = "Don't be smug about it.|...Thanks.",
				sunny = "You did! Ehehe, you were right!",
				gentle = "You did say that.|Thank you for believing in me.",
				bold = "Yeah, yeah, you did.|...Thanks. Anyway.",
				dreamy = "You did...|I remember now.",
				easygoing = "You did, and I didn't even have to try that hard.",
				proud = "I'd have managed without you saying it, naturally.|...But thanks.",
				shy = "You did...|Thank you for saying it.",
				cheeky = "ok, ok, you were right|don't let it go to your head",
				cool = "You did.|Thanks.",
				dramatic = "You SAID so, and you were RIGHT!",
				bookish = "You did, on Tuesday, actually.|You were right.",
				polite = "You did, and you were right.|Thank you.",
				foodie = "You did!|Have a cookie, you've earned it.",
				_ = "You did, and thanks.",
			}, "heart")
			c:mood("a", 4)
			c:hearts("a", 1)
		end)
		s:log("{a} told you about a small win.")
		return s:done()
	end,
})

-- a question about you, then their own answer
local QUESTIONS = {
	{
		q = "What's your perfect day off?",
		one = "Sleeping in, definitely.",
		oneBack = "Sleeping in is a very good choice.",
		two = "Building something.",
		twoBack = "Of course you'd say that, {player}.",
		own = {
			easygoing = "Mine? I nap, and then I rest after the nap.",
			bookish = "I read in the bath until the water goes cold.",
			bold = "I swim out to the buoy and back, twice.",
			dreamy = "I sit on the pier and count the boats...|I never get to the end.",
			foodie = "I eat my way round the market, very slowly.",
			sunny = "Mine? A picnic with everyone I know, all day long!",
			gentle = "I'd bake something and have friends round for tea.",
			proud = "I'd spend it being admired, naturally.|At the market, in my best coat.",
			shy = "I'd stay in with a blanket and a good book, where nobody needs me.",
			cheeky = "mine's playing tricks on everyone at the market and then hiding",
			cool = "A long walk, on my own.",
			prickly = "Nobody knocking on my door, and that's it.",
			dramatic = "A whole day at the theatre, every show, twice!",
			gloomy = "Staying in bed while it rains.|Heh... that's my favourite.",
			polite = "A quiet walk by the sea, then tea with a good friend.",
			nervous = "A day where nothing happens at all, so nothing can go wrong.",
			_ = "I walk the beach from one end to the other.",
		},
	},
	{
		q = "What are you scared of?",
		one = "Geese, honestly.",
		oneBack = "Geese? That's fair, they're mean.",
		two = "Running out of nails.",
		twoBack = "Ha, that's a builder's answer.",
		own = {
			nervous = "Me? Lots of things, but mostly the dark.|And geese, now that you mention it.",
			bold = "Me? Nothing.|...Deep water, but don't tell anyone.",
			gloomy = "I'm scared of being forgotten.|Heh... sorry, that was a bit much.",
			proud = "Nothing at all, naturally.|...Spiders, a little.",
			sunny = "Me? The dark, a bit, but I sleep with a little lamp on, so it's fine!",
			gentle = "I'm scared of the people I love getting hurt.|Silly, isn't it?",
			dreamy = "I'm scared of forgetting my dreams before I wake up...",
			easygoing = "Me? Alarm clocks, honestly.",
			shy = "Um... talking in front of lots of people.",
			cheeky = "nothing|ok, maybe crabs, they're sneaky",
			cool = "Heights.|I don't talk about it.",
			prickly = "I'm not scared of anything.|...Fine, moths, they fly at your face.",
			dramatic = "EVERYTHING, {player}.|But mostly storms.",
			bookish = "Losing my place in a book, actually.|I use three bookmarks now.",
			polite = "I am a little scared of thunderstorms, if I am honest.",
			foodie = "An empty fridge.|That's real fear.",
			_ = "I'm scared of thunder.|I hide under the table when it starts.",
		},
	},
	{
		q = "Sweet breakfast or savoury?",
		one = "Sweet, every time.",
		oneBack = "Sweet, so it's jam on everything, then.",
		two = "Savoury, please.",
		twoBack = "Savoury, so you're an eggs on toast person.",
		own = {
			foodie = "Mmm, both!|Sweet, then savoury, then sweet again.",
			easygoing = "Whatever's nearest the bed, honestly.",
			sunny = "Sweet! Pancakes with lots of syrup!",
			gentle = "I like porridge with a little honey.|It's warm, and it keeps you going until lunch.",
			bold = "Savoury, eggs and toast.|A real breakfast.",
			dreamy = "Something sweet... toast with honey, eaten by the window.",
			proud = "A proper breakfast, naturally, with eggs done exactly right.",
			shy = "Um... just toast, usually.",
			cheeky = "cake for breakfast, and nobody can stop me",
			cool = "Savoury, usually eggs.",
			prickly = "Savoury, obviously.|Sweet things in the morning make me feel sick.",
			dramatic = "Sweet, the SWEETEST!|Pancakes stacked up to the ceiling.",
			bookish = "Savoury, and actually, eggs keep you full for longer, I read that.",
			gloomy = "Whatever's left in the cupboard.|Heh... usually dry bread.",
			polite = "I prefer a savoury breakfast, thank you, with a cup of tea.",
			nervous = "Savoury, I think? Is that the wrong answer?",
			_ = "I'm a toast person myself.|Jam on one slice and cheese on the other.",
		},
	},
	{
		q = "What did you want to be when you were small?",
		one = "A builder.",
		oneBack = "And now you are one, that's nice.",
		two = "A pirate.",
		twoBack = "Ha, you'd make a good pirate.",
		own = {
			dramatic = "I wanted to be a famous actor.|I'm still deciding when that happens.",
			proud = "I wanted to be the best at something, anything at all.|And I got there, naturally.",
			dreamy = "I wanted to be a cloud...|I still think about it sometimes.",
			bookish = "I wanted to be a lighthouse keeper, for all the reading time.",
			sunny = "I wanted to be a balloon seller!|Everyone's happy when they see balloons.",
			gentle = "I wanted to be a nurse.|I still like looking after people.",
			bold = "A firefighter.|I still could be, right?",
			easygoing = "A cat, honestly.|They nap all day.",
			shy = "Um... a librarian, so I could be quiet all day.",
			cheeky = "a pirate, obviously|i still have the hat",
			cool = "A sailor.|I still like boats.",
			prickly = "I wanted to be the boss of everyone.|Don't laugh.",
			gloomy = "I don't know, I never really had a plan.|Heh...",
			polite = "I wanted to be a teacher, I think.|I still enjoy helping people learn.",
			foodie = "A chef, of course!|Or a taste tester, that's a real job.",
			nervous = "An astronaut, until I found out about the rocket part.",
			_ = "I wanted to be a baker, and I still might be one day.",
		},
	},
}

event({
	id = "askabout",
	when = "any",
	weight = W({ base = 0.1, traits = { social = 0.1 } }),
	scene = function(ctx, a)
		local item = ctx.rng:pick(QUESTIONS)
		local s = K.scene(ctx, "A question"):with({ q = item.q })
		burst(s, "a", {
			sunny = "{player}, I've got a question for you.|{q}",
			shy = "Um, {player}, could I ask you something?|{q}",
			bookish = "{player}, I've been asking everyone this for a little study.|{q}",
			cheeky = "{player} question time|{q}|answer honestly, i'll know if you don't",
			cool = "{player}.|{q}",
			polite = "Hello, {player}. May I ask you something?|{q}",
			gentle = "{player}, can I ask you something about yourself?|{q}",
			dreamy = "{player}, I was just wondering...|{q}",
			foodie = "{player}, I'm on my lunch break, and I've got a question.|{q}",
			bold = "{player}, quick question, and answer straight.|{q}",
			easygoing = "{player}, I was lying in the grass and wondering something.|{q}",
			proud = "{player}, I'd like to know something about you.|{q}",
			prickly = "I'm only asking because I'm curious, okay?|{q}",
			dramatic = "{player}, I have an IMPORTANT question.|{q}",
			gloomy = "{player}, can I ask you something?|Heh... you don't have to answer.|{q}",
			nervous = "{player}, can I ask you something? It's not weird, I promise.|{q}",
			_ = "{player}, can I ask you something?|{q}",
		}, "question")
		for _, pair in { { item.one, item.oneBack }, { item.two, item.twoBack } } do
			s:choice(pair[1], function(c)
				c:say("a", pair[2], "music")
				burst(c, "a", item.own, "heart")
				c:mood("a", 3)
			end)
		end
		s:log("{a} asked you something about yourself.")
		return s:done()
	end,
})

-- worried about you
event({
	id = "worryyou",
	when = "any",
	weight = W({ base = 0.08, traits = { kind = 0.2 } }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "Look after yourself")
		burst(s, "a", {
			gentle = "{player}, you were still hammering at nine last night.|I could hear it all the way from my garden.|Please eat something warm today, okay?",
			prickly = "{player}, you've eaten today, right?|...Right?",
			bold = "You look worn out.|You're stopping for lunch today, and that's not a question.",
			polite = "Hello, {player}, and forgive me for saying so.|You looked very tired yesterday, so are you resting enough?",
			nervous = "Are you okay?|You looked so tired yesterday, so are you sleeping and eating properly?",
			easygoing = "You were up late again, weren't you?|I saw your lamp on.|Even builders need a nap now and then.",
			foodie = "When did you last eat?|A cookie doesn't count, by the way.",
			cool = "{player}.|Your lamp was on at two in the morning.|Get some sleep.",
			dreamy = "Your lamp was still on when I looked out last night...|Are you sleeping all right?",
			sunny = "You've been working so hard lately!|Are you remembering to rest?",
			shy = "Um, {player}, you looked really tired today.|Sorry, it's not my business, but are you okay?",
			proud = "{player}, you've been working too hard.|I'd know, I'm an expert at working hard.",
			cheeky = "{player} your lamp was on at two in the morning|i know because mine was too hehe",
			dramatic = "{player}, you look EXHAUSTED.|When did you last sleep a whole night?",
			bookish = "{player}, people need about eight hours of sleep, actually.|Your lamp was on past two, so I don't think you're getting it.",
			gloomy = "You look tired, {player}.|Heh... trust me, I know the look.",
			_ = "{player}, you've been working late every night.|Are you looking after yourself?",
		}, "sweat")
		s:choice("I'm fine, really.", function(c)
			burst(c, "a", {
				gentle = "Mm, you said that last week, too.|I'm bringing you soup.|You can say no, but I'm still bringing it.",
				prickly = "Sure you are.|There's a pie outside your door, since I was passing anyway.",
				bold = "Sure you are.|I'm coming to get you at one o'clock.",
				polite = "Good, I'm glad to hear it.|Do drink some water, at least.",
				nervous = "Okay, okay.|But if you're not fine, you'll tell me, won't you?",
				easygoing = "Heh, sure.|Have a nap anyway, for me.",
				foodie = "Fine people eat lunch.|I'll bring some round.",
				cool = "Hm.|Sleep anyway.",
				dreamy = "Hmm... if you say so.|Promise me you'll rest a little anyway.",
				sunny = "Okay, but I'm bringing you lunch anyway!",
				proud = "Hmph, if you say so.|I'm bringing you dinner anyway, I insist.",
				shy = "Okay... sorry for worrying.|(Please rest, though.)",
				cheeky = "sure you are|i'm hiding your hammer until tomorrow, jk... maybe",
				dramatic = "FINE? You call that fine?|I'm bringing you soup, and that's final.",
				bookish = "If you say so.|But I'm leaving a book about sleep outside your door.",
				gloomy = "Heh... that's what I always say.|Rest anyway, okay?",
				_ = "Okay, but look after yourself anyway.",
			}, "heart")
			c:mood("a", 2)
		end)
		s:choice("You're right, I'll rest.", function(c)
			burst(c, "a", {
				gentle = "Good, and eat something warm before bed.|Take care of yourself.",
				prickly = "Good.|...Took you long enough.",
				bold = "Good, I knew you'd listen.",
				polite = "I'm very glad, and thank you for listening.",
				nervous = "Oh, good, okay, good.",
				easygoing = "Look at you, resting like a natural.",
				foodie = "Good, and start with soup.",
				cool = "Good.",
				dreamy = "Good...|Sleep well tonight.",
				sunny = "Yay, good!|Sleep well, and see you tomorrow!",
				proud = "Good, you listened to me.|Wise choice.",
				shy = "Good...|I'm glad.",
				cheeky = "good|i'll be checking your lamp tonight hehe",
				dramatic = "Thank GOODNESS!|Now I can sleep too.",
				bookish = "Good.|Eight hours, remember.",
				gloomy = "Good.|Heh... at least one of us will sleep.",
				_ = "Good, and thanks for listening.",
			}, "heart")
			c:hearts("a", 1)
			c:mood("a", 3)
		end)
		s:log("{a} worried you weren't looking after yourself.")
		return s:done()
	end,
})

-- this or that
local EITHERS = {
	{
		q = "Do you like the crust or the middle of the loaf?",
		one = "The crust.",
		two = "The middle.",
		oneBack = "A crust person, I knew it.",
		twoBack = "The soft middle, noted.|I'll save you the centre slice next time.",
		mine = "I start at the edge and work my way round.|It makes it last longer.",
	},
	{
		q = "Sunrise or sunset?",
		one = "Sunrise.",
		two = "Sunset.",
		oneBack = "You're an early riser, then.|I'll wave at you from bed.",
		twoBack = "Sunset, good choice.|Nobody has to get up early for it.",
		mine = "I like the bit just after sunset, when the sea goes purple.",
	},
	{
		q = "Rain on the roof or waves on the beach?",
		one = "Rain on the roof.",
		two = "Waves on the beach.",
		oneBack = "Rain on the roof is best with a blanket.",
		twoBack = "Waves, yes, I fall asleep to those.",
		mine = "I like the rain first, and then the waves after it stops.",
	},
	{
		q = "Tea or cocoa?",
		one = "Tea, please.",
		two = "Cocoa, please.",
		oneBack = "Tea, very sensible.",
		twoBack = "Cocoa, with the skin on top?",
		mine = "Me, I have cocoa in winter and tea the rest of the year.",
	},
}

event({
	id = "thisorthat",
	when = "any",
	weight = W({ base = 0.11 }),
	scene = function(ctx, a)
		local item = ctx.rng:pick(EITHERS)
		local s = K.scene(ctx, "This or that"):with({ q = item.q })
		burst(s, "a", {
			foodie = "{player}, this is important.|{q}",
			sunny = "{player}, quick question!|{q}",
			bookish = "I'm doing a small survey.|{q}",
			cheeky = "{player}|{q}|real answers only",
			nervous = "Can I ask you something silly?|{q}",
			gentle = "{player}, I've got a silly question for you.|{q}",
			dreamy = "I was just thinking about something...|{q}",
			bold = "{player}, one question, and answer fast.|{q}",
			easygoing = "{player}, here's an easy one, no rush.|{q}",
			proud = "{player}, I already know my answer, naturally.|{q}",
			shy = "Um, {player}, can I ask you a silly question?|{q}",
			cool = "{player}, a question for you.|{q}",
			prickly = "Answer this, and don't overthink it.|{q}",
			dramatic = "{player}, I need to know RIGHT now.|{q}",
			gloomy = "{player}, can I ask you something?|Heh... it's not important.|{q}",
			polite = "{player}, may I ask you a small question?|{q}",
			_ = "{player}, settle something for me.|{q}",
		}, "question")
		for _, pair in { { item.one, item.oneBack }, { item.two, item.twoBack } } do
			s:choice(pair[1], function(c)
				say(c, "a", pair[2], "music")
				say(c, "a", item.mine, "heart")
				c:mood("a", 2)
			end)
		end
		s:log("{a} asked you this or that.")
		return s:done()
	end,
})

-- a roll from the bakery
event({
	id = "errand",
	when = "day",
	weight = W({
		base = 0.1,
		cond = function(ctx)
			return ctx.hour < 14
		end,
	}),
	scene = function(ctx, a)
		local s = K.scene(ctx, "On your way past")
		burst(s, "a", {
			easygoing = "*yawn* Who decided the bakery should open at six?|Could you grab me a roll on your way past? The plain kind.",
			prickly = "The line at the bakery goes out the door.|I'm not standing in that, so are you going past?",
			gloomy = "I woke up late and missed the good bread, as usual.|Are you anywhere near the bakery?",
			foodie = "Are you near the bakery?|They've got seed rolls today, and I'm stuck at home waiting for a delivery.",
			sunny = "{player}, are you going past the bakery?|Could you get me a bun? I'll pay you back.",
			shy = "Um, {player}, if you're going past the bakery...|Could you get me a roll? Only if it's no trouble.",
			gentle = "{player}, are you going past the bakery this morning?|Could you pick me up a roll? I'll pay you back, of course.",
			dreamy = "I can smell the bakery from here...|Could you bring me a roll if you go past?",
			cheeky = "{player} you're going past the bakery, right|get me a roll, i'll owe you",
			bold = "{player}, you're going past the bakery, right?|Get me a roll, the big kind, and I'll pay you back.",
			proud = "You may get me a roll from the bakery, if you're going past.|I'll pay, naturally.",
			cool = "Are you going past the bakery?|Get me a roll, if you are.",
			dramatic = "{player}, I'm WEAK with hunger.|Could you bring me a roll from the bakery?",
			bookish = "{player}, the bakery sells out of rolls by half past nine.|Could you get me one on your way past?",
			polite = "Good morning, {player}, if you happen to pass the bakery...|Could you please get me a roll? I will pay you back, of course.",
			nervous = "{player}, are you going past the bakery?|Could you get me a roll? Sorry, is that too much to ask?",
			_ = "{player}, are you going past the bakery?|Could you grab me a roll?",
		}, "question")
		s:choice("I'll bring you one.", function(c)
			burst(c, "a", {
				easygoing = "You're the best.|I'll pay you back, eventually.",
				prickly = "...Thanks.|The plain one, please.",
				gloomy = "You would?|Heh... okay, thanks.",
				foodie = "A seed roll, please!|Get two if they're still warm.",
				sunny = "The one with sugar on top, please!|Thank you, thank you.",
				shy = "...!|Thank you.",
				gentle = "Thank you, that's so kind.|Have you eaten yet? Get one for yourself too.",
				cheeky = "best neighbour ever|the one with sugar on, please",
				dramatic = "You're a HERO, and I won't forget this.",
				bold = "Good.|...Thanks. Anyway, the big one, please.",
				dreamy = "Thank you...|The one with the little seeds on, if they have it.",
				proud = "Excellent.|I knew I could count on you.",
				cool = "Thanks.|I'll pay you when you get here.",
				bookish = "Thank you.|The rye one, please, it's the best one they make, actually.",
				polite = "Thank you kindly.|The plain one would be lovely, if they have it.",
				nervous = "Really? Oh, thank you.|Any roll is fine, really, I don't mind which.",
				_ = "Thanks, you're a lifesaver.",
			}, "heart")
			c:hearts("a", 1)
			c:mood("a", 4)
		end)
		s:choice("Early bird gets the bun.", function(c)
			burst(c, "a", {
				easygoing = "Heh, the bun can wait for me.|I'm going back to sleep.",
				prickly = "Ugh.|Fine, I'll go myself.",
				gloomy = "The early bird is everyone but me, as usual.",
				foodie = "Then I'm the late bird, and I'm starving.",
				sunny = "Ehehe, okay, okay!|I'm going now.",
				shy = "Oh... okay.|I'll go myself, then.",
				cheeky = "rude|fine, i'm going",
				dramatic = "You'd leave me to STARVE?|...Fine, I'll go myself.",
				gentle = "Ha, you're right.|I'll go myself, then, and get you one too.",
				bold = "Hah, fair.|I'm going now, and I'm getting the last one.",
				dreamy = "The early bird...|Hmm, I'll go and be a late bird, then.",
				proud = "Hmph, I'll go myself.|I'm a very good early bird, actually.",
				cool = "Okay.|I'll go myself.",
				bookish = "Actually, birds that get up early really do get more food.|I'll go myself.",
				polite = "Quite right.|I will go myself, then.",
				nervous = "Oh no, what if they've sold out?|I'll go right now, quickly.",
				_ = "Hah, fine.|I'll go myself.",
			}, "laugh", "laugh")
			c:mood("a", 1)
		end)
		s:log("{a} asked you to bring them a roll from the bakery.")
		return s:done()
	end,
})

-- a walk home in the dark
event({
	id = "walkyouhome",
	when = "night",
	weight = W({ base = 0.08, traits = { brave = 0.1, kind = 0.1 } }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "The way back")
		burst(s, "a", {
			bold = "{player}, the cliff path's all mud tonight.|I'm walking you home, and no arguing.",
			gentle = "{player}, it's very dark on the harbour path tonight.|Could I walk back with you? I'd feel better.",
			prickly = "{player}, it's pitch black out there.|I'm going your way anyway, so wait for me.",
			polite = "Good evening, {player}.|The lamps on the hill road are out, so may I walk you home?",
			nervous = "{player}, it's so dark tonight.|Could we walk back together? It's for you, and a bit for me.",
			cool = "{player}.|The lamps are out, so I'll walk you back.",
			dreamy = "{player}, the lamps have gone out on the hill road...|Can we walk back together? I don't mind the dark with company.",
			sunny = "{player}, it's so dark out tonight.|Let's walk back together, it's more fun anyway.",
			shy = "Um, {player}, it's really dark out.|Could I walk back with you? Only if you don't mind.",
			easygoing = "{player}, it's dark out, and I'm going your way anyway.|Let's walk slowly, no rush.",
			proud = "{player}, it's very dark out.|I'll walk you home, I know every step of the path.",
			cheeky = "{player} it's dark|i'm walking you home, in case a gull gets you hehe",
			dramatic = "{player}, the night is DARK and full of puddles.|I'll walk you home, of course.",
			bookish = "{player}, three of the lamps on the hill road are out.|I'll walk you home, if that's all right.",
			gloomy = "It's really dark out.|Heh... I'll walk you home, if you don't mind me.",
			foodie = "{player}, it's dark out, and I'm going past your house to get a late snack.|Let's walk together.",
			_ = "{player}, it's really dark out.|I'll walk you home.",
		}, "question")
		s:choice("I can manage.", function(c)
			burst(c, "a", {
				bold = "Sure you can.|I'm still coming.",
				prickly = "I know you can.|I'm still coming, since I'm going that way.",
				gentle = "I know you can.|Let me come anyway, okay?",
				polite = "Of course.|I'll walk a little way behind, then.",
				nervous = "Okay...|Can I come anyway?",
				cool = "...I'm still coming.",
				sunny = "I know! But walking together is more fun.|Come on!",
				dreamy = "I know...|But I'd like the company.",
				easygoing = "Sure you can.|I'm walking that way anyway, no big deal.",
				proud = "Of course you can.|But I'm coming anyway, naturally.",
				shy = "Oh... okay.|Um, could I come anyway?",
				cheeky = "sure you can|i'm coming anyway, try and stop me",
				dramatic = "You can manage? In THIS dark?|...I'm coming anyway.",
				bookish = "I'm sure you can.|But two people are safer than one, actually.",
				gloomy = "Okay...|Heh... I'll come anyway, if that's all right.",
				foodie = "I know, but I've got a bag of warm chips.|Walk with me and share them.",
				_ = "Sure.|I'll come anyway.",
			}, "sweat")
			c:n("You walked home together, and the lamps came back on halfway.")
		end)
		s:choice("Thanks, I'd like that.", function(c)
			burst(c, "a", {
				bold = "Good.|Mind the puddle by the gate.",
				prickly = "Good.|Keep up.",
				gentle = "Good.|Hold my arm on the steps.",
				polite = "It's my pleasure.",
				nervous = "Oh, good.|Okay, let's go.",
				cool = "Okay.",
				sunny = "Yay, come on, it's this way!",
				dreamy = "Good...|Look, you can see every star tonight.",
				easygoing = "Cool, let's go.|Nice and slow.",
				proud = "Very good.|Follow me, I know the way.",
				shy = "Okay...|I'm glad.",
				cheeky = "ok, let's go|last one to the gate is a rotten egg",
				dramatic = "Then we go TOGETHER into the night!",
				bookish = "Good.|It's six hundred steps to your door, I counted once.",
				gloomy = "Okay.|Heh... it's nice, not walking alone.",
				foodie = "Good.|Here, have a chip on the way.",
				_ = "Good.|It's this way.",
			}, "heart")
			c:n("You walked home together, and the lamps came back on halfway.")
		end)
		s:hearts("a", 1)
		s:mood("a", 3)
		s:log("{a} walked you home in the dark.")
		return s:done()
	end,
})

-- something left outside your door
local STEPS = {
	{ thing = "a jar of plum jam", edible = true },
	{ thing = "a bag of rolls, still warm", edible = true },
	{ thing = "a pot of mint", edible = false },
	{ thing = "a pair of knitted mittens", edible = false },
	{ thing = "a smooth stone with a face painted on it", edible = false },
}

event({
	id = "onyourstep",
	when = "day",
	weight = W({ base = 0.07, traits = { kind = 0.2 } }),
	scene = function(ctx, a)
		local st = ctx.rng:pick(STEPS)
		local s = K.scene(ctx, "Outside your door"):with({ thing = st.thing })
		burst(s, "a", {
			prickly = "{player}, there's something outside your door.|Don't make a fuss about it.",
			cheeky = "{player} go and look outside your door|no, it's not a frog this time",
			shy = "Um, {player}, there's something outside your door.|It's from me, but you don't have to like it.",
			foodie = "Go and look outside your door.|I hope you like it as much as I liked getting it ready.",
			gentle = "{player}, I left you a little something outside your door.|It's only small, so don't make a fuss, okay?",
			proud = "There's a gift outside your front door.|It's from me, and you're welcome.",
			polite = "Good afternoon, {player}.|I have left a small something outside your door.|Please do not feel you have to return it.",
			dreamy = "I left something outside your door...|I saw it at the market and thought of you.",
			sunny = "{player}, go and look outside your door!|I left you a surprise.",
			easygoing = "{player}, I left something outside your door.|It's nothing big, I was walking past anyway.",
			bold = "{player}, check outside your door.|I left you something, and you're keeping it.",
			cool = "{player}.|I left something outside your door.",
			bookish = "{player}, I left something outside your door at ten past eight.|I hope it's still there.",
			gloomy = "I left something outside your door.|Heh... it's probably not much, but it's from me.",
			nervous = "{player}, I left something outside your door.|Is that okay? I didn't knock, in case you were busy.",
			dramatic = "{player}, there's a SURPRISE outside your door!|Go and look, quickly.",
			_ = "{player}, I left something outside your door.|I hope you like it.",
		}, "heart")
		s:n("It was {thing}.")
		s:choice("You didn't have to.", function(c)
			burst(c, "a", {
				prickly = "I know.|I had spare, that's all.",
				shy = "I wanted to.|...That's all.",
				proud = "I know, I'm very generous.",
				gentle = "I wanted to.|You do so much round here, so take care of yourself, all right?",
				cheeky = "i know|i'm amazing",
				sunny = "But I wanted to, ehehe!",
				bold = "I know.|Just say thanks, right?",
				dreamy = "I know...|It just felt like yours.",
				easygoing = "Eh, it was no trouble.|I was going that way anyway.",
				cool = "I know.|I wanted to.",
				dramatic = "Of COURSE I had to!|You deserve the world.",
				bookish = "I know.|Actually, small presents make people happier than big ones, I read that.",
				gloomy = "I know.|Heh... I wanted someone to have it.",
				polite = "It was my pleasure, truly.",
				foodie = "I know, but I wanted to, and I had spare.",
				nervous = "I know, I just... is it okay? Do you like it?",
				_ = "I know, but I wanted to.",
			}, "heart")
			c:hearts("a", 1)
			c:mood("a", 3)
		end)
		s:choice("Can I eat it?", function(c)
			if st.edible then
				burst(c, "a", {
					foodie = "Yes, that's the whole point!",
					cheeky = "yes, why else would i leave food outside your door",
					sunny = "Yes, yes, eat it!",
					gentle = "Of course, it's for eating.|Have it with something warm, okay?",
					bold = "Yes, obviously.|Eat it while it's good.",
					dreamy = "Yes...|It's best eaten by a window.",
					easygoing = "Sure, go ahead.|No rush, it'll keep.",
					proud = "Of course, and it's delicious, naturally.",
					shy = "Um, yes... I hope you like it.",
					cool = "Yes.|Eat it soon.",
					prickly = "Yes, obviously.|What else would you do with it?",
					dramatic = "EAT it? You must!",
					bookish = "Yes, it'll keep for about three days, actually.",
					gloomy = "Yes.|Heh... I hope it's still good.",
					polite = "Yes, please do enjoy it.",
					nervous = "Yes! Unless it's gone bad... no, it's fine, it's fresh.",
					_ = "Yes, please eat it.",
				}, "laugh", "laugh")
			else
				burst(c, "a", {
					foodie = "No, and I'm as surprised as you are.",
					cheeky = "please don't",
					gloomy = "No.|Heh... of course you'd ask that.",
					sunny = "No, no! Ehehe, it's not food!",
					gentle = "Oh my, no.|It's for looking at, not eating.",
					bold = "No.|Seriously, don't.",
					dreamy = "No...|It's for keeping.",
					easygoing = "Nah, it's not food.|Nice try, though.",
					proud = "Certainly not.|It's far too fine to eat.",
					shy = "Um, no...|Sorry, it's not food.",
					cool = "No.",
					prickly = "No, are you serious?|Ugh.",
					dramatic = "NO! Don't you dare!",
					bookish = "No, it's not something you can eat, actually.|Please don't try.",
					polite = "No, I am afraid it is not for eating.",
					nervous = "No! Oh no, don't, please!",
					_ = "No!|Please don't eat it.",
				}, "laugh", "laugh")
			end
			c:mood("a", 2)
		end)
		s:log("{a} left {thing} outside your door.")
		return s:done()
	end,
})

return list
