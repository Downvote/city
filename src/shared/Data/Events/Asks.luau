--!nonstrict
-- A villager comes to you with something small, and the answer matters a little: which outfit,
-- whether to tell a friend the truth, what to give somebody, a motto, a hobby, what to cook, who
-- to take to the dance, whether to say sorry first; too much bread, a shell off the beach, a
-- colour for the front door, company on the pier at night, a stool they made, a neighbour's late
-- music, lights on the islet, nerves before a big day, a soup to taste, a letter to their gran, a
-- drooping plant, a rainy day, a night they can't sleep, a name they've forgotten, a secret spot,
-- a silly hat, a question they want to practise, a bet on the weather, a knock at six, a wave you
-- missed, the room you built them. What you pick can make a friend, a sulk, a new saying.
--
-- And the chats that are only a chat: a message meant for somebody else, the worry the morning
-- after a late chat that they said something odd, a picture they want you to see, an invite for
-- tomorrow, sorry for yesterday, guess what's in my pocket, a long day let out and taken back, a
-- part in their story, a favour, a small win, a question about you, a nag about your sleep, this
-- or that, a roll from the bakery, a walk home in the dark, something left on your step. (One
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
				easygoing = "Mm, the hat it is.|Now I can go back to sitting on my step.",
				cool = "The hat, then.|Thanks for the help.",
				nervous = "Are you sure about the hat?|Okay, okay, I'll wear the hat.|Thank you, I feel much better now.",
				dramatic = "The hat is a bold choice, and the right one!|I'm going to make an entrance the square won't forget.",
				cheeky = "hat it is|sorry scarf, it's scarecrow time for you",
				gloomy = "The hat... it'll blow off in the wind, as usual.|...Fine, I'll wear it anyway.",
				sunny = "The hat! Ehehe, I knew you'd pick that one.|Okay, I'm off, see you later.",
				gentle = "The hat, then, it does look cheerful.|Thank you, and take care of yourself today.",
				_ = "The hat it is, then.|Thanks, you've saved me ten more minutes at the mirror.",
			}, "sparkle", "cheer")
			c:mood("a", 4)
		end)
		s:choice("The stripy scarf, definitely.", function(c)
			burst(c, "a", {
				bold = "Scarf it is, and I'm out the door.|...Thanks. Anyway, see you later.",
				dreamy = "Hmm... the scarf, then.|Wearing it feels like being wrapped up in a blanket.",
				gloomy = "Good, the scarf.|It'll turn cold later anyway, it always does.",
				foodie = "The scarf, then.|It's got folds, and folds are perfect for hiding a biscuit or two.",
				prickly = "Fine, the scarf.|Don't read into the fact that I asked you, okay?|...But thanks.",
				cheeky = "scarf it is|guess the hat's going on the scarecrow then hehe",
				polite = "The scarf it is, and thank you kindly, {player}.|Have a lovely day.",
				shy = "The scarf, okay...|Thank you, I feel less nervous about going out now.",
				nervous = "The scarf, okay, the scarf.|It can't blow away like a hat could, so that's good.",
				dramatic = "The scarf, of course, it's so much more mysterious.|Everyone in the square will wonder where I'm off to.",
				_ = "The scarf, good call.|It's colder out than it looks today.",
			}, "heart")
			c:mood("a", 4)
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
			_ = "I've got an awkward question for you.|{b} keeps cooking dinner for me, and it's always far too salty.|Should I tell them the truth?",
		}, "sweat")
		s:choice("Tell them, but kindly.", function(c)
			burst(c, "a", {
				prickly = "{b}, thanks for all the dinners, I mean it.|But please use less salt next time.|...A lot less.",
				cool = "{b}, thanks for cooking for me.|It's too salty, though, so try half as much next time.",
				shy = "Um, {b}, I really love that you cook for me...|Could you maybe use a little less salt next time?",
				nervous = "{b}, I-I really love that you cook for me.|Could you maybe go easier on the salt next time? Is that okay?",
				_ = "{b}, I really love that you cook for me.|Could you maybe go easier on the salt next time?|...A lot easier, actually.",
			}, "sweat")
			if K.isPers(ctx, b, "proud", "bold", "prickly", "dramatic") then
				burst(c, "b", {
					proud = "Less salt? My cooking is perfectly fine.|...How much less are we talking about?",
					prickly = "Ugh, fine, less salt.|Don't read anything into me listening to you.",
					dramatic = "*gasp* You're insulting my cooking to my FACE?|...Fine, show me how much salt you'd use.",
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
			_ = "I'm so bored that I've started counting the tiles on my floor.",
		}, "sad")
		burst(s, "a", {
			cheeky = "pick me a new hobby, go on",
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
	proud = "Very well, I accept.|I'll wear my best shoes.",
	shy = "Um, yes... I'd like that.",
	cheeky = "only if we hit the snack table first|deal?",
	cool = "Sure, I'll come.",
	prickly = "Ugh, fine, I'll come.|I'm not dancing, though.",
	dramatic = "Yes! I've been waiting all YEAR for someone to ask me.",
	bookish = "Yes, I'd like that.|I'll look up a few steps beforehand.",
	gloomy = "Me? Heh... okay, I'll come.",
	polite = "I'd be happy to, thank you for asking.",
	foodie = "Yes, as long as we stand right next to the cake.",
	nervous = "O-okay, yes, as long as nobody makes me dance.",
	_ = "Sure, I'd like that.",
}
local DANCE_NO = {
	sunny = "Aww, I'm already going with someone else, sorry!",
	gentle = "I'm sorry, I don't think I'll go this time.",
	bold = "No, ask someone else.",
	dreamy = "Hmm... I don't think so, sorry.",
	easygoing = "Eh, I'll pass, dances aren't really my thing.",
	proud = "Hmph, I already have plans on Friday.",
	shy = "Um... sorry, I can't.",
	cheeky = "nah, i'm busy that night hehe",
	cool = "No, sorry.",
	prickly = "Ugh, no.",
	dramatic = "Alas, my Friday is already spoken for.",
	bookish = "Sorry, I've already got plans on Friday.",
	gloomy = "No, I'd only spoil it for you.",
	polite = "That's kind of you to ask, but I'll have to say no.",
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
			say(ch, "a", "Why choose, when we can all go together?|The snack table won't know what hit it.", "music")
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
		local names = ctx.rng:shuffle(PLANTNAMES)
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
			_ = "{player}, I've got a new fern for my windowsill.|It needs a name, and I can't think of a good one.",
		}, "question")
		for i = 1, 2 do
			local name = names[i]
			s:choice("How about " .. name .. "?", function(c)
				c:with({ plant = name })
				burst(c, "a", {
					dramatic = "{plant}, a name to be remembered!|Hello, {plant}, welcome to your new home.",
					cheeky = "{plant} hehe|ok fine, it actually suits it",
					gloomy = "{plant}... heh, it does look like a {plant}.|Welcome home, {plant}.",
					_ = "{plant}, I like that.|Hello, {plant}, welcome to your new windowsill.",
				}, "heart", "cheer")
				c:mood("a", 3)
				c:memo("a", "{plant} the fern has a new leaf, and I'm very proud of it.")
			end)
		end
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
				_ = "That's sensible, I suppose.|I'll see if I still want it in the morning.",
			}, "zzz")
			c:mood("a", 1)
		end)
		s:log("{a} thought about dyeing their hair blue.")
		return s:done()
	end,
})

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
			_ = "{player}, I'm cooking dinner for {b} tonight.|I want to make something they'll really enjoy.",
		}, "question")
		s:say("a", "What do you think I should make?", "question")
		for _, f in options do
			s:choice("What about " .. Foods.phrase(f) .. "?", function(c)
				c:with({ food = Foods.phrase(f) })
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
						proud = "Not bad at all.|You may cook for me again.",
						shy = "Um, thank you, that was really nice.",
						cheeky = "ok that was good|i'm coming round every night now hehe",
						cool = "That was good. Thanks.",
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
				nervous = "{b}, I-I'm really sorry about the other day.|Can we please stop being cross?",
				gentle = "{b}, I'm sorry about the other day.|I've missed talking to you.",
				sunny = "{b}, I'm really sorry!|Can we please be friends again?",
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
					_ = "...Yes, I'm sorry too.|I really missed you.",
				}, "heart")
				c:fx({ t = "makeup", a = "a", b = "b" })
				c:rel(10)
				c:mood("a", 5)
			else
				burst(c, "b", {
					sunny = "I'm still a bit hurt, honestly.|Can we talk tomorrow instead?",
					gentle = "Thank you for saying it.|I just need a little more time, all right?",
					bold = "Not yet.|I'm still cross, so give me a day.",
					dreamy = "Hmm... I'm not ready yet.|Ask me again tomorrow.",
					easygoing = "Eh, I'm still a bit annoyed, honestly.|Give me a day or so.",
					proud = "Hmph, an apology like that?|I'll think about accepting it.",
					shy = "Um... I'm not ready yet.|Sorry.",
					cheeky = "nope, not yet|try again tomorrow",
					cool = "Not yet. Give me a day.",
					dramatic = "You think one sorry fixes EVERYTHING?|I need time to recover.",
					bookish = "I appreciate it, but I'm still thinking it all over.|Can we talk later this week?",
					gloomy = "Heh... I'm still too fed up to talk.|Maybe tomorrow.",
					polite = "Thank you, but I'm not quite ready yet.|Perhaps tomorrow.",
					foodie = "I'm still cross, and I haven't even had lunch.|Ask me later.",
					nervous = "I-I'm not ready yet, sorry.|Can we talk tomorrow?",
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
			_ = "{player}, I made way too much bread.",
		}, "sweat")
		burst(s, "a", {
			foodie = "There are eleven loaves on the table right now.|I can't eat them all, and believe me, I've thought about it.",
			bookish = "I doubled the recipe, then doubled it again by mistake.|That's four times the bread, and I've counted every loaf.|Sorry, I'm rambling again, but what do I do with it all?",
			nervous = "There are eleven of them, and they're everywhere.|The kitchen's so full I can't even reach the kettle.",
			easygoing = "I think it's eleven loaves, but I stopped counting.|They're all over the kitchen, and one of them is on my chair.",
			_ = "There are eleven loaves, and the kitchen's full.|What do I do with them all?",
		}, "question")
		s:choice("Share it round the street.", function(c)
			burst(c, "a", {
				sunny = "Yes, I'll knock on every door!|Everyone's getting a loaf, whether they want one or not.",
				shy = "Um, I could leave them on people's steps.|That way I won't have to talk to anyone.",
				polite = "What a kind idea.|I'll take one to every house on the street.",
				prickly = "Fine, I'll hand them out.|If anyone asks, it was a mistake and not a present.",
				gentle = "That's a lovely idea.|I'll wrap them up and take them round this afternoon.",
				_ = "That's a good idea.|I'll do the rounds this afternoon.",
			}, "sparkle", "cheer")
			c:n("By teatime there was a loaf on every doorstep in the street.")
			c:all(2)
			c:mood("a", 4)
			c:memo("a", "I gave bread to the whole street, and now people keep waving at me.")
		end)
		s:choice("Have a toast morning tomorrow.", function(c)
			burst(c, "a", {
				foodie = "A toast morning, oh, you're good.|I'll bring the jam, and you bring the butter.",
				easygoing = "Toast tomorrow means less work today.|I like the way you think.",
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
			_ = "{player}, look at this shell I found on the beach.",
		}, "sparkle")
		s:say("a", "There isn't a single chip on it, so what should I do with it?", "question")
		s:choice("Put it on your windowsill.", function(c)
			burst(c, "a", {
				dreamy = "On the windowsill, yes.|That way it can still see the sea.",
				foodie = "On the windowsill, next to my jam jars.|They'll look nice together.",
				gentle = "The windowsill, yes.|I'll see it every morning when I open the curtains.",
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
			cheeky = "{player}|pier, right now|last one to the end buys the cocoa",
			gentle = "{player}, it's such a calm night.|Would you walk down to the pier with me for a bit?",
			easygoing = "{player}, I'm wandering down to the pier.|No plan, just looking at the water, if you want to come.",
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
			_ = "{player}, look, I made a stool.",
		}, "sparkle")
		burst(s, "a", {
			bookish = "It's perfectly level, too.|I checked it by rolling a marble across the top.",
			nervous = "It wobbles a little bit.|Is that bad? It's bad, isn't it?",
			foodie = "It's for the kitchen, so I can sit down while things bake.",
			proud = "Go on, tell me it's the finest stool you've ever seen.",
			cheeky = "so, what do you think",
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
				_ = "Oh, yes, it does.|I'll put a bit of card under that leg.",
			}, "sweat")
			c:xp("a", 8)
			c:memo("a", "My stool doesn't wobble any more, because {player} spotted it.")
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
			_ = "{b} plays music really late every night.|I haven't had a proper night's sleep all week.",
		}, "sweat")
		s:say("a", "What should I do about it?", "question")
		s:choice("Knock and ask nicely.", function(c)
			burst(c, "a", {
				shy = "You want me to knock on their door?|...Okay, I'll knock very quietly.",
				bold = "Fine, I'll be nice about it.|I'm going over now.",
				prickly = "Ugh, fine, I'll be nice about it.",
				gentle = "You're right, I'll just ask them gently.",
				_ = "Okay, I'll go and ask nicely.",
			}, "sweat")
			burst(c, "b", {
				cheeky = "was it too loud? hehe sorry|i'll put the quiet records on",
				proud = "Too loud? But it's good music.|...Fine, I'll turn it down.",
				gloomy = "Sorry, I didn't think anyone could hear it.",
				polite = "Oh, I'm so sorry about that.|I'll keep it down, and thank you for telling me.",
				dramatic = "My music kept you awake?|I'm mortified, and it stops at nine from now on.",
				nervous = "Oh no, was it really that loud?|Has it been every night? I'm so sorry.",
				gentle = "Oh, my, I'm so sorry.|I'll keep it down from now on.",
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
			cheeky = "{player}|lights on the islet last night|spooky hehe",
			gentle = "{player}, did you see the lights on the islet last night?|I was worried someone was stuck out there.",
			sunny = "{player}, guess what I saw last night!|There were lights on the islet, and they were moving.",
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
				_ = "Oh, boats, that makes sense.",
			}, "sweat")
			c:mood("a", 2)
		end)
		s:choice("Let's watch for them tonight.", function(c)
			burst(c, "a", {
				bold = "Yes! I'll bring a torch.",
				nervous = "Tonight, together?|Okay, as long as we're together.",
				cheeky = "a stakeout|i'll bring the snacks",
				_ = "Tonight, then.|Meet me by the harbour.",
			}, "sparkle")
			c:n(
				"That night you watched from the harbour wall. Three small lights bobbed across the islet, then went out."
			)
			burst(c, "a", {
				gloomy = "See, I told you.|Nobody ever believes me.",
				dramatic = "We're official witnesses now, {player}.",
				gentle = "So there really was someone out there.|I hope they got home safe.",
				nervous = "See? I wasn't imagining it.|...Now I'm going to lie awake wondering.",
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
			_ = "Tomorrow's a big day at the {job}.|I keep going over everything in my head.",
		}, "sweat")
		s:choice("You'll be great.", function(c)
			burst(c, "a", {
				gloomy = "You think so?|...Okay, I'll try thinking so too.",
				nervous = "Oh, okay.|Thank you, I needed to hear that.",
				prickly = "Obviously.|...Thanks, though.",
				shy = "...!|Thank you.",
				gentle = "Thank you, that's kind of you.|I'll get a good night's sleep and do my best.",
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
			_ = "{player}, will you taste my soup?|I can't tell if it needs salt.",
		}, "question")
		s:choice("Add a pinch of salt.", function(c)
			burst(c, "a", {
				foodie = "Mmm, just a pinch, yes!|You've got the tongue for this.",
				gloomy = "Salt, yeah.|...That's better, annoyingly.",
				gentle = "A pinch of salt, yes.|Oh, that's much better, thank you.",
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
				cool = "Hm. Good.|I'll leave it, then.",
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
		local s = K.scene(ctx, "A letter to Gran")
		s:prop("parcels", "a")
		burst(s, "a", {
			bookish = "I'm writing a letter to my gran.|I'm already on page four, so is that too long?",
			gloomy = "I'm writing to my gran.|Nothing happens here that's worth putting in a letter, though.",
			dramatic = "{player}, I'm writing my gran a letter for the ages.|...I've been stuck on the second line for an hour.",
			cool = "{player}.|I'm writing to my gran, and I'm stuck.",
			shy = "Um, {player}, I'm writing to my gran.|What do people usually put in letters?",
			polite = "{player}, I'm writing to my gran this afternoon.|Would you help me decide what to say?",
			sunny = "I'm writing a letter to my gran.|I want to tell her everything, but I don't know where to start.",
			gentle = "I'm writing to my gran.|I want her to know I'm happy here and eating properly, but I don't know what to say.",
			dreamy = "I've been writing to my gran...|So far it just says 'Dear Gran'.",
			_ = "I'm writing to my gran, and I don't know what to put.|She always wants to hear everything.",
		}, "question")
		s:choice("Tell her about the town.", function(c)
			burst(c, "a", {
				gloomy = "The town, okay...|Actually, I could tell her about the gulls on the pier, and about you.",
				sunny = "The town, yes!|I'll start with the bakery, because she loves bread more than anyone.",
				gentle = "The town, yes.|She'll love hearing about the gardens.",
				dreamy = "The town...|I'll tell her how the harbour looks in the evening.",
				_ = "The town, yes.|She'd really like that.",
			}, "idea")
			c:mood("a", 4)
			c:memo("a", "I told my gran all about the town, and now she wants to know who {player} is.")
		end)
		s:choice("Keep it short and sweet.", function(c)
			burst(c, "a", {
				bookish = "Four pages down to one, then...|That hurts, but you're right.",
				_ = "Short, then.|'Dear Gran, all is well here, lots of love,' and that's it.",
			}, "sweat")
			c:mood("a", 2)
		end)
		s:log("{a} wrote a letter to their gran.")
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
					_ = "Look, it's perked right up.|Thank you, I was really worried about it.",
				}, "sparkle", "cheer")
				c:mood("a", 5)
				c:memo("a", "My plant's doing really well now, because {player} knew what it needed.")
			else
				c:n("By the next morning it was drooping a little more.")
				burst(c, "a", {
					nervous = "It's worse, it's definitely worse.|Okay, should we try the other thing?",
					_ = "Hm, it wasn't that, then.",
				}, "sweat")
				c:mood("a", -1)
			end
		end
		s:choice("Give it more water.", function(c)
			burst(c, "a", {
				nervous = "Not too much, though, right?|How much is too much? Okay, one cup.",
				_ = "Water, okay.|A big drink for you, then.",
			}, "idea")
			after(c, works == 1)
		end)
		s:choice("Move it into the sun.", function(c)
			burst(c, "a", {
				dreamy = "The sun, yes...|It's been stuck in the corner, poor thing.",
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
			bold = "It's raining too hard to go anywhere.|I've been stuck inside all morning, and I'm going stir crazy.",
			dreamy = "It's raining...|I could do anything today, and that's the trouble.",
			gloomy = "It's raining, of course.|What does anyone even do on a day like this?",
			nervous = "It's raining, and it doesn't look like it'll stop.|What if it rains all day and I just sit here?",
			gentle = "It's pouring out there, so stay dry, okay?|I'm stuck inside and can't think what to do.",
			cheeky = "{player} it's raining|i'm bored already and it's only been an hour|give me something to do",
			proud = "{player}, the rain has ruined my plans for the day.|What would you do?",
			foodie = "{player}, it's raining, and I've already eaten all my snacks.|What do I do now?",
			shy = "Um, {player}, it's raining a lot.|What do you do on days like this?",
			_ = "{player}, it's raining.|What should I do all day?",
		}, "question")
		s:choice("Bake something.", function(c)
			burst(c, "a", {
				foodie = "Yes, yes, the big cake!|I've been waiting for a reason to make it.",
				bold = "Baking sounds good.|I'm going to make the biggest cake you've ever seen.",
				gentle = "Baking sounds lovely.|I'll save you a slice, if you come round.",
				cheeky = "ok, baking|if the smoke alarm goes off, that's on you",
				_ = "Baking, good idea.|The whole house will smell lovely.",
			}, "heart")
			c:mood("a", 4)
		end)
		s:choice("Go and jump in puddles.", function(c)
			burst(c, "a", {
				sunny = "Wellies on, let's go!",
				shy = "Puddles, like a little kid?|...Okay, maybe just a small one.",
				gloomy = "I'll get soaked.|...Okay, fine, let's.",
				prickly = "That's ridiculous.|...Where did I put my wellies?",
				cheeky = "puddles, yes|race you to the big one by the gate",
				_ = "Puddles, yes.|I'm getting my wellies on.",
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
				_ = "You really want to know?|Okay, so...",
			}, "heart")
			c:n("You talked until the sky started to go grey.")
			burst(c, "a", {
				sunny = "Ehehe, sorry, I talked your ear off.|Thanks for staying up with me!",
				dreamy = "The gulls slept on the roof the whole time, did you notice?|Thank you for staying up with me...",
				foodie = "All that talking has made me hungry again.|Thanks for staying up with me, though.",
				gentle = "I'm sorry I kept you up so late.|Thank you for listening, and get some sleep, okay?",
				cheeky = "ok, forget everything i said|...thanks for listening, though",
				cool = "Thanks for listening.|Get some sleep.",
				bold = "...Thanks, I needed that.|Now go to bed, it's nearly morning.",
				polite = "Thank you kindly for listening.|I'm sorry for keeping you up so late.",
				easygoing = "Huh, it's nearly morning.|Thanks for staying up, I think I can sleep now.",
				nervous = "I-I'm sorry, I talked all night.|Thank you for listening, really.",
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
			_ = "Who's that coming over?|I've completely forgotten their name.",
		}, "sweat")
		s:choice("Whisper the name to {a}.", function(c)
			c:n("You whispered the name just in time.")
			say(c, "a", "Hi, {b}!|How are you, {b}? It's so good to see you, {b}.", "sparkle")
			burst(c, "b", {
				cheeky = "why do you keep saying my name",
				cool = "...Hi.",
				_ = "Hi.|You're very keen today, aren't you?",
			}, "question")
			c:rel(3)
		end)
		s:choice("Just ask them.", function(c)
			burst(c, "a", {
				cool = "Sorry, I've forgotten your name.|What is it again?",
				proud = "I knew it a minute ago, honestly.|What's your name again?",
				cheeky = "ok this is awkward|what's your name again",
				_ = "I'm so sorry, this is awful.|What's your name again?",
			}, "sweat")
			burst(c, "b", {
				gentle = "It's {b}, and don't worry, all right?|I forget names all the time.",
				proud = "It's {b}.|I'll try not to be hurt.",
				prickly = "It's {b}.|Write it down this time.",
				gloomy = "It's {b}.|Heh... nobody remembers, so it's fine.",
				sunny = "It's {b}!|What was yours again? Ehehe, I'm kidding.",
				dreamy = "It's {b}.|Names are slippery, I forget them too.",
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
				_ = "You can come up here too, whenever you like.|It's our spot now.",
			}, "heart")
			c:hearts("a", 1)
			c:mood("a", 5)
			c:memo("a", "I showed {player} my secret spot, so now it's our spot.")
		end)
		s:choice("Maybe another day.", function(c)
			burst(c, "a", {
				shy = "Okay.|It'll still be there another day.",
				cheeky = "your loss|it's very secret",
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
			dramatic = "{player}, behold my SHAME.",
			prickly = "Not a word, {player}.|...Okay, one word.|How bad is it?",
			nervous = "{player}, is it bad? It's bad, isn't it?|Is everyone looking at me?",
			sunny = "Look at my hat!|It has a feather and a little bell on it.",
			cool = "{player}.|I lost a bet, so don't ask about the hat.",
			gentle = "{player}, I lost a bet, so I'm stuck with this hat.|Please be kind about it, okay?",
			dreamy = "There's a bell on my hat...|It jingles every time I nod, so I'm trying not to nod.",
			_ = "{player}, be honest with me.|How silly does this hat look?",
		}, "sweat")
		s:choice("It suits you, honestly.", function(c)
			burst(c, "a", {
				proud = "It does, doesn't it?|I might even keep it.",
				gloomy = "You're just saying that.|...Should I keep it?",
				sunny = "Really? Ehehe, then I'm keeping it!",
				_ = "Really?|Huh, maybe it's not so bad after all.",
			}, "sparkle")
			c:say("b", "That was meant to be a punishment, you know.", "sweat")
			c:mood("a", 5)
		end)
		s:choice("It's very silly.", function(c)
			burst(c, "a", {
				prickly = "I know, I know.",
				dramatic = "I KNOW.|And I've got six more hours of this.",
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
				bookish = "Actually, the bell was my idea, so I'm quite proud of it.",
				gloomy = "Heh... I'd have lost too, if I were you.",
				polite = "Oh, goodness, I'm sorry, I can't help laughing.",
				foodie = "You can take it off at dinner time, I promise.",
				nervous = "I-I'm sorry, is it too much? We can take the bell off.",
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
	proud = "Yes, and you've chosen well.",
	cheeky = "yes, but i'm picking the team name",
	shy = "Um, yes... if you really want me.",
	nervous = "M-me? Okay, yes, I'll try my best.",
	polite = "Of course, I'd be glad to.",
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
			_ = "{player}, can I practise asking {b} to join my quiz team?|I always go quiet when I try to ask people things.",
		}, "sweat")
		local keen = ctx.rel(a, b) >= 0
		s:choice("Just go and ask them.", function(c)
			burst(c, "a", {
				nervous = "Go right now?|Okay, okay, I'm going.",
				shy = "Now?|...Okay, before I lose my nerve.",
				_ = "Right, I'm going now.",
			}, "sweat")
			if keen then
				burst(c, "b", QUIZ_YES, "heart")
				c:rel(8)
			else
				burst(c, "b", {
					prickly = "You want me on a quiz team?|...Fine, but only for one night.",
					_ = "Hm, I'll think about it.",
				}, "question")
				c:rel(2)
			end
		end)
		s:choice("Practise on me first.", function(c)
			c:n("{a} asked you four times, and the fourth time was very good.")
			burst(c, "a", {
				dramatic = "I've never been more ready for anything in my life!",
				_ = "Okay, I think I'm ready now.",
			}, "sparkle")
			burst(c, "b", QUIZ_YES, "heart")
			c:rel(8)
			c:mood("a", 3)
			c:memo("a", "{b} joined our quiz team, and I practised on {player} first.")
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
			_ = "{player}, sun or rain tomorrow?|Pick one, and we'll see who's right.",
		}, "idea")
		burst(s, "a", {
			cheeky = "loser sings a song by the fountain, deal?",
			_ = "Whoever loses has to sing a song by the fountain.",
		}, "music")
		s:choice("I say sun.", function(c)
			burst(c, "a", {
				gloomy = "Sun is a brave guess.|We'll see.",
				cheeky = "wait, sun was my pick|so we're on the same side, who sings then",
				_ = "You think it'll be sunny?|You'd better warm up your voice, then.",
			}, "sparkle")
			c:mood("a", 2)
			c:memo("a", "{player} bet me it'd be sunny, so somebody's singing at the fountain.")
		end)
		s:choice("I say rain.", function(c)
			burst(c, "a", {
				cheeky = "rain? bold choice|i hope you've got a song ready, hehe",
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
			_ = "{player}, could you knock on my door at six tomorrow?|I want to see the sunrise.",
		}, "question")
		s:choice("I'll knock, don't worry.", function(c)
			burst(c, "a", {
				easygoing = "You're a hero, a very early hero.|I'll owe you a nap.",
				nervous = "Thank you so much.|Knock twice, or maybe three times, just in case.",
				prickly = "Fine, good.|...Thanks.",
				bold = "Hah, good.|If I don't answer, keep knocking.",
				_ = "Thanks, that's a big help.|Knock loudly, okay?",
			}, "heart")
			c:hearts("a", 1)
			c:mood("a", 4)
			c:memo("a", "{player} knocked at six, and I saw the sunrise. It was all pink.")
		end)
		s:choice("Leave your curtains open.", function(c)
			burst(c, "a", {
				bookish = "Actually, using the sun as an alarm is a very old idea.|It's a good one, though.",
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
			polite = "Good afternoon, {player}.|I believe I waved at you earlier, but it's no matter.",
			gentle = "{player}, I waved at you this morning.|You looked busy, so I hope everything's all right.",
			dreamy = "{player}, I waved at you this morning...|You were looking at the sea, so I don't think you saw.",
			_ = "{player}, I waved at you this morning.|You walked right past me.",
		}, "sad", "wave")
		s:choice("Sorry, I was miles away.", function(c)
			burst(c, "a", {
				prickly = "Ugh, fine.|Wave twice next time to make up for it.",
				gloomy = "...It's okay.|Thanks for saying sorry.",
				cheeky = "apology accepted|wave twice next time though",
				gentle = "Oh, don't worry about it.|I just wanted to make sure you were all right.",
				shy = "Oh, no, it's fine, really.|I'll wave bigger next time.",
				bold = "Hah, fine.|Wave back next time, or I'll shout.",
				polite = "Not at all, it happens to everyone.|Have a lovely day.",
				dreamy = "Hmm... the sea does that to people.|Wave back next time, okay?",
				_ = "Ha, that's okay.|Wave back next time, though.",
			}, "heart")
			c:mood("a", 3)
		end)
		s:choice("I waved back, you missed it.", function(c)
			burst(c, "a", {
				cheeky = "you did not|...wait, did you?",
				nervous = "You did? Oh no, and I didn't wave back?|Now I feel terrible.",
				proud = "Nobody waves at me without me noticing, {player}.",
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
			polite = "{player}, I'd like to thank you properly for my room.|It's very comfortable indeed.",
			gloomy = "My room's nice, weirdly.|I keep waiting for something to go wrong with it.",
			dramatic = "{player}, my room is PERFECT.|I cried a little when I first saw it.",
			foodie = "My room is lovely.|It's close to the kitchen, and that's all I ever ask.",
			gentle = "{player}, I wanted to thank you for my room.|I sleep so well in it.",
			dreamy = "The light comes through my window in stripes in the morning...|I love my room, thank you.",
			easygoing = "{player}, my bed is the comfiest bed I've ever napped in.|Thanks for the room.",
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
				cool = "I do. Thanks.",
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
				_ = "Maybe a rug.|My feet get cold in the mornings.",
			}, "idea")
			c:mood("a", 2)
			c:memo("a", "I told {player} what I'd like for my room, but there's no rush.")
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
			polite = "{b}, I hope you don't mind my asking.|Might I have my ladder back today?",
			cheeky = "{b} where's my ladder|i know it was you",
			nervous = "{b}, sorry, did you borrow my ladder?|I'm not cross, I just really need it today.",
			gentle = "{b}, sorry to ask, but do you still have my ladder?|I need it for the gutter today.",
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
			dramatic = "{player}, I have captured something extraordinary.",
			cool = "{player}.|Look at this.",
			foodie = "Look what I saw on my way to lunch.",
			gentle = "{player}, I took a picture this morning, and it made me smile.|I wanted to show you.",
			dreamy = "I took a picture this morning...|It's my favourite one so far.",
			cheeky = "{player} look at this picture i took|best one i've ever taken, easily",
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
				_ = "I knew you'd like it.",
			}, "heart")
			c:mood("a", 4)
			c:hearts("a", 1)
		end)
		s:choice("Is that your thumb in the corner?", function(c)
			burst(c, "a", {
				proud = "Th-that's part of it.|It shows how big everything is.|Anyway!",
				prickly = "It's a frame.|Ugh, fine, it's my thumb.",
				cheeky = "it's a cameo",
				shy = "Oh no, it is...",
				dramatic = "That thumb is ART.",
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
				_ = "Good.|Do you fancy {what}?|We could meet at {place} at {time}.",
			}, "heart")
			c:mood("a", 4)
			c:memo("a", "Tomorrow it's {what} with {player}, and we're meeting at {place} at {time}.")
		end)
		s:choice("Depends what for.", function(c)
			burst(c, "a", {
				sunny = "It's {what}, so now you're free, right?",
				bold = "It's {what}, so you're free.",
				cheeky = "you'll find out|{place} at {time}, be there",
				shy = "Oh, um, I was thinking of {what}...|Only if you'd like to.",
				_ = "I was thinking {what}.|Could we meet at {place} at {time}?",
			}, "idea")
			c:mood("a", 3)
			c:memo("a", "Tomorrow it's {what} with {player}, and we're meeting at {place} at {time}.")
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
			polite = "Hello, {player}.|About yesterday, I was short with you, and I apologise.",
			prickly = "{player}, about yesterday.|I was rude to you.|...Sorry.",
			bold = "{player}, about yesterday.|I snapped at you, and that wasn't fair.",
			gloomy = "{player}, yesterday was a bad day.|I took it out on you, and I'm sorry.",
			proud = "{player}, about yesterday.|I was not at my best, and that's all I'll say.",
			nervous = "{player}, I'm so sorry about yesterday.|I was horrible to you, and I've been thinking about it all night.",
			cool = "{player}, about yesterday.|I'm sorry.",
			gentle = "{player}, about yesterday.|I was very short with you, and I'm sorry, I didn't mean it.",
			dreamy = "{player}, I was in a strange mood yesterday...|I think I snapped at you, and I'm sorry.",
			sunny = "{player}, I'm really sorry about yesterday.|I was grumpy, and it wasn't fair on you.",
			_ = "{player}, about yesterday.|I was in a mood, and I'm sorry.",
		}, "sad")
		s:choice("It's already forgotten.", function(c)
			burst(c, "a", {
				prickly = "...Good.|Thanks.",
				polite = "Thank you, that's very kind of you.|I'll bring you some tea later, if that suits.",
				nervous = "Really? Oh, thank you so much.",
				gloomy = "Okay...|Thanks, {player}.",
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
				proud = "I am now.|Thank you.",
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
			_ = "{player}, guess what's in my pocket.|I'll give you two tries.",
		}, "idea")
		-- either way, the answer
		local reveal = K.byPers(ctx, ctx.stars and ctx.stars.a, {
			cheeky = "nothing hehe|made you guess, though",
			foodie = "It's a bun, and it's still warm.|Do you want half?",
			bookish = "It's an empty snail shell.|I checked that it was empty, don't worry.",
			sunny = "It's a conker!|It's the shiniest one in town.",
			dramatic = "A single button...|From a coat I have never seen.",
			gloomy = "It's a bit of string.|Heh... that's all I ever have.",
			dreamy = "It's a feather from a gull.|I've been carrying it around all day.",
			gentle = "It's a toffee I saved for you.|Here, take it.",
			_ = "It's a pebble from the beach.|It's a really good one.",
		})
		s:choice("Is it a biscuit?", function(c)
			burst(c, "a", {
				polite = "No, I'm afraid it isn't a biscuit.",
				cool = "No.",
				cheeky = "nope",
				_ = "Nope, not a biscuit.",
			}, "laugh")
			say(c, "a", reveal, "sparkle")
			c:mood("a", 2)
		end)
		s:choice("Is it a frog?", function(c)
			burst(c, "a", {
				polite = "A frog? Goodness, no.",
				cheeky = "why would i have a frog in my pocket|...don't answer that",
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
			prickly = "{player}, today at the {job} was a mess from start to finish.|Then the kettle broke, and someone asked if I was tired.|Of course I'm tired!",
			polite = "Forgive me, {player}, I just need to say this to someone.|The {job} was very trying today, and everything went wrong at once.",
			gloomy = "Everything went wrong at the {job} today.|Even the things that never go wrong went wrong, as usual.",
			bold = "Two people were off today, so I ran the {job} on my own.|I did all of it, and now I'm done.",
			nervous = "I got so many things mixed up at the {job} today.|Nobody was cross with me, but I was cross with myself.",
			gentle = "I'm sorry, I need to tell someone about my day.|Everything at the {job} took twice as long as it should have.",
			dreamy = "Today at the {job} went wrong from the very start...|I feel like I've been underwater all day.",
			sunny = "Today at the {job} was the worst!|Everything that could go wrong did.",
			_ = "{player}, it was such a long day at the {job}.|Everything piled up at once.",
		}, "sad")
		s:say("a", "...Sorry, that was a lot to dump on you.", "sweat")
		s:choice("You do so much.", function(c)
			burst(c, "a", {
				prickly = "Ugh, don't say that.|...Thanks.",
				polite = "That's kind of you to say.|Please forget I went on so.",
				gloomy = "...|Thanks, and forget I said all that, okay?",
				bold = "Hah! Somebody has to.|...Thanks, though.",
				gentle = "That's kind of you.|I'm sorry for going on so.",
				_ = "Oh... thanks.|Forget I said all that, okay?",
			}, "heart")
			c:mood("a", 5)
		end)
		s:choice("Let me help tomorrow.", function(c)
			burst(c, "a", {
				prickly = "You'd only get in the way.|...Come at nine.",
				polite = "You'd do that?|Then thank you, and nine o'clock, if that suits.",
				bold = "Yeah? Good, nine o'clock.|I always pay back a favour.",
				nervous = "Really? Oh, thank you so much.",
				_ = "You would?|Thank you, that would really help.",
			}, "heart")
			c:hearts("a", 1)
			c:mood("a", 5)
			c:xp("a", 4)
		end)
		s:log("{a} let off steam about work.")
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
			sunny = "{player}, I've got big news!|You're going to be {mine}.",
			dreamy = "{player}...|I need {role}, and I decided it's you.",
			bold = "{player}, I need {role}, and you're it.|You're free today, right?",
			gentle = "{player}, I need {role} today.|Would you mind? It'd mean a lot.",
			shy = "Um, {player}, I need {role} today.|Would you do it? You don't have to.",
			polite = "{player}, might I ask you to be {mine} today?|I'd be very grateful.",
			proud = "{player}, I've chosen you to be {mine} today.|It's quite an honour, naturally.",
			nervous = "{player}, c-could you be {mine} today?|I can't think of anyone else I'd ask.",
			_ = "{player}, I need {role} today, and I thought of you.",
		}, "sparkle", "point")
		burst(s, "a", { cheeky = r.today:lower(), _ = r.today }, "idea")
		s:choice("I'm in.", function(c)
			burst(c, "a", {
				dramatic = "*trumpet noise*|...That was me, in case you were wondering.",
				cheeky = "excellent hehe|i knew you'd crack",
				sunny = "Yes! Meet me at the fountain, let's go!",
				dreamy = "Good...|I'll be waiting by the water.",
				bold = "Hah! Good.|Meet me at the fountain in ten minutes, and don't be late.",
				nervous = "Th-thank you!|Meet me at the fountain in ten minutes, okay?",
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
				polite = "Because I couldn't think of anyone better.|Shall we meet at the fountain in ten minutes?",
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
		ask = "stand at the stall while I fetch more bread",
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
			polite = "Hello, {player}, I'm sorry to interrupt.|Might you {ask}, if it's no trouble?",
			cool = "{player}.|Can you {ask}?",
			easygoing = "{player}, could you {ask}?|No rush, but I'll pay you in biscuits.",
			nervous = "{player}, s-sorry to ask.|Could you {ask}?|You can say no, I won't mind.",
			gentle = "{player}, I'm sorry to ask, but could you {ask}?|It would help me so much.",
			dreamy = "{player}, could you {ask}?|You were the first person I thought of.",
			prickly = "{player}, I need you to {ask}.|Don't make a big thing of it.",
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
				_ = "Thanks so much.|I owe you one.",
			}, "heart")
			c:hearts("a", 1)
			c:mood("a", 5)
		end)
		s:choice("Only if there's tea.", function(c)
			burst(c, "a", {
				easygoing = "Mm, there's always tea.",
				bold = "Hah! Fine, there'll be tea.",
				cheeky = "tea and a biscuit, final offer",
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
				_ = "I know, right?",
			}, "heart")
			c:mood("a", 5)
		end)
		s:choice("Told you you'd manage.", function(c)
			burst(c, "a", {
				nervous = "You did say that, didn't you?",
				gloomy = "You did.|...Don't get used to it.",
				prickly = "Don't be smug about it.|...Thanks.",
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
			foodie = "When did you last eat?|A biscuit doesn't count, by the way.",
			cool = "{player}.|Your lamp was on at two in the morning.|Get some sleep.",
			dreamy = "Your lamp was still on when I looked out last night...|Are you sleeping all right?",
			sunny = "You've been working so hard lately!|Are you remembering to rest?",
			shy = "Um, {player}, you looked really tired today.|Sorry, it's not my business, but are you okay?",
			_ = "{player}, you've been working late every night.|Are you looking after yourself?",
		}, "sweat")
		s:choice("I'm fine, really.", function(c)
			burst(c, "a", {
				gentle = "Mm, you said that last week, too.|I'm bringing you soup.|You can say no, but I'm still bringing it.",
				prickly = "Sure you are.|There's a pie on your step, since I was passing anyway.",
				bold = "Sure you are.|I'm coming to get you at one o'clock.",
				polite = "Good, I'm glad to hear it.|Do drink some water, at least.",
				nervous = "Okay, okay.|But if you're not fine, you'll tell me, won't you?",
				easygoing = "Heh, sure.|Have a nap anyway, for me.",
				foodie = "Fine people eat lunch.|I'll bring some round.",
				cool = "Hm.|Sleep anyway.",
				dreamy = "Hmm... if you say so.|Promise me you'll rest a little anyway.",
				sunny = "Okay, but I'm bringing you lunch anyway!",
				_ = "Hm, look after yourself anyway.",
			}, "heart")
			c:mood("a", 2)
		end)
		s:choice("You're right, I'll rest.", function(c)
			burst(c, "a", {
				gentle = "Good, and eat something warm before bed.|Take care of yourself.",
				prickly = "Good.|...Took you long enough.",
				bold = "Good, I knew you'd see sense.",
				polite = "I'm very glad, and thank you for listening.",
				nervous = "Oh, good, okay, good.",
				easygoing = "Look at you, resting like a natural.",
				foodie = "Good, and start with soup.",
				cool = "Good.",
				dreamy = "Good...|Sleep well tonight.",
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
			prickly = "The bakery queue is out the door.|I'm not standing in that, so are you going past?",
			gloomy = "I woke up late and missed the good bread, as usual.|Are you anywhere near the bakery?",
			foodie = "Are you near the bakery?|They've got seed rolls today, and I'm stuck at home waiting for a parcel.",
			sunny = "{player}, are you going past the bakery?|Could you get me a bun? I'll pay you back.",
			shy = "Um, {player}, if you're going past the bakery...|Could you get me a roll? Only if it's no trouble.",
			gentle = "{player}, are you going past the bakery this morning?|Could you pick me up a roll? I'll pay you back, of course.",
			dreamy = "I can smell the bakery from here...|Could you bring me a roll if you go past?",
			cheeky = "{player} you're going past the bakery, right|get me a roll, i'll owe you",
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
			dreamy = "{player}, the lamps have gone out on the hill road...|Shall we walk back together? I don't mind the dark with company.",
			sunny = "{player}, it's so dark out tonight.|Let's walk back together, it's more fun anyway.",
			shy = "Um, {player}, it's really dark out.|Could I walk back with you? Only if you don't mind.",
			_ = "{player}, it's really dark out.|I'll walk you home.",
		}, "question")
		s:choice("I can manage.", function(c)
			burst(c, "a", {
				bold = "Sure you can.|I'm still coming.",
				prickly = "I know you can.|I'm still coming, since I'm going that way.",
				gentle = "I know you can.|Humour me, okay?",
				polite = "Of course.|I'll walk a little way behind, then.",
				nervous = "Okay...|Can I come anyway?",
				cool = "...I'm still coming.",
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

-- something left on your step
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
		local s = K.scene(ctx, "On your step"):with({ thing = st.thing })
		burst(s, "a", {
			prickly = "{player}, there's something on your step.|Don't make a fuss about it.",
			cheeky = "{player} go check your step|no, it's not a frog this time",
			shy = "Um, {player}, there's something on your step.|It's from me, but you don't have to like it.",
			foodie = "Go and look at your step.|I hope you like it as much as I liked getting it ready.",
			gentle = "{player}, I left you a little something on your step.|It's only small, so don't make a fuss, okay?",
			proud = "There's a gift on your doorstep.|It's from me, and you're welcome.",
			polite = "Good afternoon, {player}.|I've left a small something on your step.|Please don't feel you have to return it.",
			dreamy = "I left something on your step...|I saw it at the market and thought of you.",
			sunny = "{player}, go and look at your step!|I left you a surprise.",
			_ = "{player}, I left something on your step.|I hope you like it.",
		}, "heart")
		s:n("It was {thing}.")
		s:choice("You didn't have to.", function(c)
			burst(c, "a", {
				prickly = "I know.|I had spare, that's all.",
				shy = "I wanted to.|...That's all.",
				proud = "I know, I'm very generous.",
				gentle = "I wanted to.|You do so much round here, so take care of yourself, all right?",
				cheeky = "i know|i'm amazing",
				_ = "I know, but I wanted to.",
			}, "heart")
			c:hearts("a", 1)
			c:mood("a", 3)
		end)
		s:choice("Can I eat it?", function(c)
			if st.edible then
				burst(c, "a", {
					foodie = "Yes, that's the whole point!",
					cheeky = "yes, why else would i leave food on your step",
					_ = "Yes, please eat it.",
				}, "laugh", "laugh")
			else
				burst(c, "a", {
					foodie = "No, and I'm as surprised as you are.",
					cheeky = "please don't",
					gloomy = "No.|Heh... of course you'd ask that.",
					_ = "No!|Please don't eat it.",
				}, "laugh", "laugh")
			end
			c:mood("a", 2)
		end)
		s:log("{a} left {thing} on your step.")
		return s:done()
	end,
})

return list
