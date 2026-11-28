--!nonstrict
-- Events that happen because of something on the plot. The user: "Make more interactions, such as
-- events, conversations and chats that only happen when certain work places are present, like ice
-- cream trucks, whiteboards, etc. things like mailboxes, fridges, etc. can also be present." So
-- each of these needs a kind of piece in the town (Kit's W{ has = ... }, Sim/PlotHas: a catalog
-- id, a tag, a job's workplace, a pool or pond): the stove, the fridge, the mailbox, the swings,
-- the piano, the telescope, the pond, the ice cream cart, the chalkboard, the TV, the arcade, the
-- BBQ, the campfire, the fish tank, the bird feeder, the bees, the trampoline, the bicycle, the
-- washing machine, the well, the record player, the hammock, the rowing boat, the flower cart,
-- the drums and the little greenhouse. The piece each needs is kept on the def as `need` (the
-- Events spec checks every one names real pieces).
--
-- Some answers leave a follow-up waiting (the user: "make events / conversations have follow up
-- ones, such as, for example, villager asks if they should check if they left the stove on, has
-- a chance of villager burning something and coming to you for help"; Kit's s:follow,
-- Sim/FollowUps): those events are here too, marked `followup`, and only ever come that way.
-- More chains, which start from events elsewhere, are in Data/Events/Later.

local K = require(script.Parent.Kit)
local PlotHas = require(script.Parent.Parent.Parent.Sim.PlotHas)

local W = K.W

local list = {}

-- An event that needs a piece: `need` goes on the def and into its weight.
local function event(def)
	def.actors = def.actors or 1
	if def.need then
		def.w = def.w or {}
		def.w.has = def.need
	end
	if def.w then
		def.weight = W(def.w)
		def.w = nil
	end
	table.insert(list, def)
end

local function burst(s, who: string, map: any, icon: string?, gesture: string?)
	return s:burst(who, map, icon, gesture)
end

-- What each kind of piece is, as a need (Sim/PlotHas.Kinds).
local NEED = PlotHas.Kinds

-- the second star works at this job (a florist, the ice cream seller)
local function works(job: string)
	return function(ctx, _a, b)
		local w = b and ctx.job(b)
		return w ~= nil and w.job.id == job
	end
end

-- The stove ---------------------------------------------------------------------------------------

event({
	id = "stoveon",
	group = "solo",
	when = "day",
	need = NEED.stove,
	w = { base = 0.14 },
	scene = function(ctx, a)
		local s = K.scene(ctx, "The stove")
		s:n("{a} stopped halfway down the street.")
		burst(s, "a", {
			nervous = "{player}, oh no, the stove.|D-did I turn it off? I had soup on and I just walked out.",
			easygoing = "Hey {player}, I think I left the stove on.|It's only soup, so it's fine, right?",
			gloomy = "{player}, I left the stove on, didn't I?|Heh... my soup's going to be on fire by now.",
			cheeky = "{player} quick question|did i leave the stove on? asking for me",
			bookish = "{player}, I can't remember if I turned the stove off.|Soup boils dry in about an hour, actually.",
			dramatic = "{player}, the STOVE!|I left my soup on, and I'm halfway to the market!",
			polite = "Excuse me, {player}.|I am afraid I may have left the stove on at home.",
			foodie = "{player}, my soup!|I left it on the stove, and it was going to be my lunch.",
			proud = "{player}, I never forget things.|...But did I leave the stove on just now?",
			_ = "{player}, did I leave the stove on?|I had soup going this morning, and I can't remember turning it off.",
		}, "question", "point")
		s:choice("Go back and check.", function(c)
			burst(c, "a", {
				nervous = "Y-yes, I'm going, I'm going.",
				easygoing = "Ugh, fine, I'll walk back.",
				gloomy = "Heh... I already know what I'll find.",
				_ = "You're right, I'll run back and look.",
			}, "sweat")
			c:n("The stove was off. {a} had turned it off after all.")
			c:mood("a", 2)
		end)
		s:choice("I'm sure it's off.", function(c)
			burst(c, "a", {
				nervous = "Okay... okay, I'll trust you.",
				gloomy = "If you say so.",
				proud = "Of course it's off, I'd never forget a thing like that.",
				_ = "You're right, I always turn it off.",
			}, "idea")
			c:mood("a", 1)
			-- it wasn't (Sim/FollowUps)
			c:follow("burntpan", { chance = 0.6, hours = 2 })
		end)
		s:default(1)
		s:log("{a} worried about the stove.")
		return s:done()
	end,
})

event({
	id = "burntpan",
	group = "solo",
	followup = true,
	when = "day",
	need = NEED.stove,
	w = { base = 1 },
	scene = function(ctx, a)
		local s = K.scene(ctx, "Something's burning")
		s:n("There's smoke coming out of {a}'s kitchen window.")
		burst(s, "a", {
			dramatic = "{player}, it's a DISASTER!|My soup is black, and the whole kitchen smells of it.",
			nervous = "{player}, I-I'm sorry, it was on after all!|There's smoke everywhere, what do I do?",
			gloomy = "{player}... I knew it.|The soup's burnt onto the bottom of the pan.",
			cheeky = "{player} so|the stove was on. the soup is charcoal now",
			proud = "{player}, the stove was on.|Don't say anything, just help me open the windows.",
			foodie = "{player}, my soup's gone!|It's stuck to the pan, and it was lunch and dinner.",
			polite = "{player}, I am so sorry to bother you.|The stove was on after all, and my kitchen is full of smoke.",
			shy = "Um, {player}...|The stove was on, and now there's smoke, and I don't know what to do.",
			_ = "{player}, help!|I did leave the stove on, and the soup's burnt to the bottom of the pan.",
		}, "sweat", "wave")
		s:choice("Open the windows and scrub the pan.", function(c)
			c:n("You opened every window and scrubbed the pan together until it shone.")
			c:voice("a", "thanks", "heart")
			c:mood("a", 4)
			c:hearts("a", 1)
			c:memo("a", "I burnt my soup to the pan, and the {player} helped me scrub it clean.")
		end)
		s:choice("Let's get lunch somewhere else.", function(c)
			burst(c, "a", {
				foodie = "Yes, please, somewhere with soup that isn't black.",
				gloomy = "Yes, I can't look at that pan any more.",
				_ = "Yes, let's, and I'll deal with the pan later.",
			}, "heart", "cheer")
			c:mood("a", 3)
		end)
		s:log("{a} burnt the soup.")
		return s:done()
	end,
})

-- The fridge --------------------------------------------------------------------------------------

event({
	id = "fridgepudding",
	group = "pairs",
	actors = 2,
	when = "any",
	need = NEED.fridge,
	w = { base = 0.13, btraits = { mischief = 0.2 } },
	scene = function(ctx, a, b)
		local s = K.scene(ctx, "The pudding")
		s:n("{a} opened the fridge, and the pudding with their name on it is gone. {b} is holding a spoon.")
		burst(s, "a", {
			dramatic = "{b}, that was MY pudding!|It had a note on it, with my NAME.",
			prickly = "Ugh, {b}.|That pudding had my name on it, in pen.",
			gentle = "Oh, {b}, was that my pudding?|I did put a little note on it.",
			cheeky = "{b} you absolute pudding thief",
			_ = "{b}, did you eat my pudding?|It had my name on it.",
		}, "anger", "point")
		burst(s, "b", {
			cheeky = "i thought the note said free pudding|it did not say free pudding",
			shy = "Um... I'm so sorry, I was really hungry.",
			gloomy = "Heh... that was me, yes.",
			proud = "Hmph, the note was very small.",
			foodie = "It was a really good pudding, though, if that helps.",
			nervous = "I-I thought it was mine, I'm so sorry!",
			_ = "I thought the note said it was for everyone.",
		}, "sweat")
		s:choice("{b} owes {a} a pudding.", function(c)
			burst(c, "b", {
				proud = "Fine, I'll make a better one.",
				foodie = "Deal, and mine will have extra cream.",
				_ = "That's fair, I'll make you one.",
			}, "idea")
			c:rel(1)
			-- and they do (Sim/FollowUps)
			c:follow("puddingback", { chance = 0.75, hours = 4 })
		end)
		s:choice("Write the note bigger next time.", function(c)
			burst(c, "a", {
				prickly = "I'm writing it in letters this big.",
				_ = "I'm putting a sign on the whole fridge.",
			}, "idea")
			c:say("b", "That would help, honestly.", "sweat")
			c:rel(-1)
		end)
		s:log("{b} ate {a}'s pudding.")
		return s:done()
	end,
})

event({
	id = "puddingback",
	group = "pairs",
	followup = true,
	actors = 2,
	when = "any",
	need = NEED.fridge,
	w = { base = 1, quarrel = "any" },
	scene = function(ctx, a, b)
		local s = K.scene(ctx, "A new pudding")
		s:n("{b} knocked on {a}'s door holding a pudding with a big note on it.")
		burst(s, "b", {
			cheeky = "one pudding, as promised|the note says your name in letters you can read from the street",
			proud = "Here, and it's better than the one I ate.",
			shy = "Um, I made you a pudding...|I'm still sorry about the other one.",
			foodie = "I made two, actually, so we can eat them together.",
			_ = "I made you a pudding to make up for the other one.|The note's nice and big this time.",
		}, "heart")
		s:voice("a", "happy", "heart", "cheer")
		s:rel(6)
		s:mood("a", 4)
		s:mood("b", 2)
		s:log("{b} made {a} a pudding.")
		return s:done()
	end,
})

-- The mailbox -------------------------------------------------------------------------------------

local ORDERS = { "jigsaw", "cookbook", "packet of seeds", "ball of wool", "new kite" }

event({
	id = "mailboxwait",
	group = "solo",
	when = "day",
	need = NEED.mailbox,
	w = { base = 0.13 },
	scene = function(ctx, a)
		local s = K.scene(ctx, "Waiting for the post"):with({ thing = ctx.rng:pick(ORDERS) })
		s:n("{a} has checked the mailbox four times this morning.")
		burst(s, "a", {
			sunny = "{player}, my {thing} is coming today!|Has the post been yet? I keep checking.",
			nervous = "{player}, the post is late, isn't it?|What if my {thing} got lost on the way?",
			easygoing = "Hey {player}, have you seen the post?|I'm waiting on a {thing}, no rush.",
			bookish = "{player}, my {thing} was meant to come today.|The post is usually here by ten, actually.",
			cheeky = "{player} have you seen the post person|i've been waiting by the mailbox like a dog",
			polite = "Good morning, {player}.|I am waiting for a {thing} in the post, and it is late.",
			_ = "{player}, I ordered a {thing}, and it's meant to come today.|Has the post been yet?",
		}, "question")
		s:choice("It'll come this afternoon.", function(c)
			burst(c, "a", {
				nervous = "You think so? Okay, I'll try not to look again until lunch.",
				_ = "I'll look again after lunch, then.",
			}, "idea")
			c:mood("a", 1)
			c:follow("parcelcame", { chance = 0.85, hours = 3, words = { thing = "{thing}" } })
		end)
		s:choice("Wait for it with them.", function(c)
			c:n("You waited by the door together. The post came just before noon.")
			burst(c, "a", {
				cheeky = "it's here|my {thing}, finally",
				dramatic = "It's HERE, and the box is only a little squashed!",
				_ = "It's here, my {thing}.|Thanks for waiting with me.",
			}, "sparkle", "cheer")
			c:mood("a", 4)
			c:hearts("a", 1)
		end)
		s:log("{a} waited for the post.")
		return s:done()
	end,
})

event({
	id = "parcelcame",
	group = "solo",
	followup = true,
	when = "day",
	need = NEED.mailbox,
	w = { base = 1 },
	scene = function(ctx, a)
		local s = K.scene(ctx, "The post came")
		s.vars.thing = s.vars.thing or "parcel"
		s:n("There's a parcel sticking out of {a}'s mailbox.")
		burst(s, "a", {
			sunny = "{player}, it came, it came!|My {thing} is here, and the box isn't even squashed.",
			gloomy = "It came.|Heh... I was sure it was lost.",
			cheeky = "{player} it came|you said it would and you were right, don't get used to it",
			foodie = "My {thing} came!|This calls for a snack.",
			proud = "My {thing} came, just as I said it would.",
			_ = "{player}, you were right, it came this afternoon.|My {thing} is here.",
		}, "sparkle", "cheer")
		s:mood("a", 4)
		s:memo("a", "My {thing} came in the post, and I've been up half the night with it.")
		s:log("{a}'s {thing} came in the post.")
		return s:done()
	end,
})

-- The swings --------------------------------------------------------------------------------------

event({
	id = "swingpush",
	group = "pairs",
	actors = 2,
	when = "day",
	need = NEED.swing,
	w = { base = 0.15, rel = -10, traits = { social = 0.1 } },
	scene = function(ctx, a, b)
		local s = K.scene(ctx, "On the swing")
		s:n("{a} is on the swing, and {b} is pushing.")
		burst(s, "a", {
			sunny = "Higher, higher!|No, wait, not that high.",
			nervous = "N-not too high, okay?|Okay, a bit higher.",
			bold = "Higher, {b}, I want to see the harbour.",
			cool = "You can push harder than that.",
			dreamy = "If I go high enough, I can see the sea...",
			_ = "Higher!|No, wait, that's high enough.",
		}, "music", "cheer")
		burst(s, "b", {
			bold = "Hah, hold on tight, then.",
			cheeky = "too late, already pushed",
			gentle = "All right, a gentle one this time.",
			prickly = "Ugh, my arms are getting tired.",
			_ = "Hold on, here comes a big one.",
		}, "laugh", "laugh")
		s:choice("Have a go yourself.", function(c)
			c:n("You had a turn too, and {b} pushed you so high you could see the harbour.")
			c:say("a", "My turn again after you.", "music")
			c:rel(4)
			c:hearts("a", 1)
		end)
		s:choice("Leave them to it.", function(c)
			c:n("They took turns until lunch.")
			c:rel(5)
		end)
		s:log("{a} and {b} played on the swing.")
		return s:done()
	end,
})

-- The piano ---------------------------------------------------------------------------------------

event({
	id = "pianotune",
	group = "solo",
	when = "any",
	need = NEED.piano,
	w = { base = 0.14, traits = { focus = 0.1 } },
	scene = function(ctx, a)
		local s = K.scene(ctx, "A tune on the piano")
		s:n("{a} has been playing the same few notes on the piano all morning.")
		burst(s, "a", {
			bookish = "{player}, I'm learning a song from an old book of music.|I keep getting stuck on the same bar near the end.",
			proud = "{player}, I've nearly mastered a new song.|There's just one bit near the end that isn't perfect yet.",
			gloomy = "{player}, I've played this song forty times.|I get it wrong at the same bit every single time.",
			dramatic = "{player}, this song is going to be my FINEST.|If I can get past the end, anyway.",
			shy = "Um, {player}, I'm learning a song...|I keep getting stuck near the end.",
			_ = "{player}, I'm learning a song on the piano.|I keep getting stuck on the same bit near the end.",
		}, "music")
		s:choice("Play it for me.", function(c)
			c:n("{a} played it through, stopped at the same place, then got past it.")
			c:voice("a", "brag", "sparkle", "cheer")
			c:mood("a", 4)
			-- and they play it properly for everyone later (Sim/FollowUps)
			c:follow("pianoshow", { chance = 0.6, hours = 6 })
		end)
		s:choice("Take a break from it.", function(c)
			burst(c, "a", {
				easygoing = "Yeah, my fingers need a nap.",
				prickly = "Fine, but only because my fingers hurt.",
				_ = "You're right, I'll come back to it after lunch.",
			}, "zzz")
			c:mood("a", 1)
		end)
		s:log("{a} practised a song on the piano.")
		return s:done()
	end,
})

event({
	id = "pianoshow",
	group = "solo",
	followup = true,
	when = "any",
	need = NEED.piano,
	w = { base = 1 },
	scene = function(ctx, a)
		local s = K.scene(ctx, "The whole song")
		s:n("{a} has put a row of chairs out by the piano.")
		burst(s, "a", {
			dramatic = "{player}, tonight I play the WHOLE song.|Sit in the front row, please.",
			shy = "Um, {player}, I think I can play the whole song now...|Would you listen?",
			cool = "{player}, I can play it all the way through now.|Sit down, it's short.",
			_ = "{player}, I can play the whole song now.|Will you sit in the front row?",
		}, "music", "wave")
		s:n("{a} played it from start to finish without stopping once, and everyone clapped.")
		s:voice("a", "happy", "heart", "cheer")
		s:all(3)
		s:mood("a", 3)
		s:memo("a", "I played my song on the piano from start to finish, and everyone clapped.")
		s:log("{a} played a whole song on the piano.")
		return s:done()
	end,
})

-- The telescope -----------------------------------------------------------------------------------

event({
	id = "telescopemoon",
	group = "solo",
	when = "night",
	need = NEED.telescope,
	w = { base = 0.17, weather = { "clear", "leaves", "blossom" } },
	scene = function(ctx, a)
		local s = K.scene(ctx, "Through the telescope")
		burst(s, "a", {
			bookish = "{player}, come and look through the telescope.|You can see the craters on the moon, and I've counted eleven.",
			dreamy = "{player}... the moon is so close tonight.|Come and look.",
			cheeky = "{player} come look|the moon has a face and it's making a face at me",
			sunny = "{player}, come quick, come quick!|You can see right into the craters on the moon.",
			_ = "{player}, come and look through the telescope.|You can see the craters on the moon tonight.",
		}, "sparkle", "point")
		s:choice("Let me see.", function(c)
			c:n("It was a clear night, and the moon filled the whole lens.")
			c:voice("a", "excited", "sparkle")
			c:hearts("a", 1)
			c:mood("a", 3)
		end)
		s:choice("Can you see any planets?", function(c)
			burst(c, "a", {
				bookish = "That bright one low down is a planet, actually.|It doesn't twinkle like the stars do.",
				_ = "I think that bright one is a planet.|It's the only one that doesn't twinkle.",
			}, "idea")
			c:mood("a", 3)
		end)
		s:log("{a} looked at the moon through the telescope.")
		return s:done()
	end,
})

-- The pond (a name to type: the user, "allow the player to type in what they desire") -------------

local FISH = { "Bubbles", "Captain", "Goldie", "Mr Fins", "Splash", "Pebble", "Duke", "Sunny" }

event({
	id = "pondfish",
	group = "solo",
	when = "day",
	need = NEED.pond,
	w = {
		base = 0.11,
		cond = function(ctx, a)
			return ctx.memory(a, "pet") == nil
		end,
	},
	scene = function(ctx, a)
		local s = K.scene(ctx, "A fish in the pond")
		s:n("{a} is lying on the grass by the pond, staring into the water.")
		burst(s, "a", {
			sunny = "{player}, there's a fish in the pond, an orange one!|It comes up every time I clap.",
			gentle = "{player}, look, there's a little fish in the pond.|I've been feeding it crumbs.",
			bookish = "{player}, there's a goldfish in the pond.|Actually, they can live for twenty years, so it needs a good name.",
			cheeky = "{player} there's a fish in the pond|i've decided it's mine now",
			gloomy = "There's a fish in the pond.|It keeps coming back to me, which is a first, heh.",
			dramatic = "{player}, a FISH has chosen our pond!|It needs a name, a grand one.",
			_ = "{player}, there's a fish in the pond, and it comes up when I clap.|It needs a name.",
		}, "sparkle", "point")
		s:askName({
			var = "fish",
			suggest = FISH,
			ask = "What should the fish be called?",
			build = function(c)
				burst(c, "a", {
					cool = "{fish}.|Yes, that suits it.",
					shy = "{fish}...|Hello, {fish}.",
					sunny = "{fish}, yes, yes!|Did you see it flick its tail?",
					proud = "{fish}, a fine name, naturally.",
					cheeky = "{fish}|it's ignoring me already, perfect",
					gloomy = "{fish}.|Heh... it came up, so it must like it.",
					polite = "{fish}, how lovely.|Thank you, {player}.",
					_ = "{fish}, that's perfect.|Did you see it flick its tail?",
				}, "heart", "cheer")
				c:mood("a", 5)
				c:hearts("a", 1)
				c:memo("a", "The fish in the pond is called {fish}, and it comes up when I clap.")
				c:remember("a", "pet", { what = "fish", name = "{fish}" })
			end,
		})
		s:log("{a} named the fish in the pond.")
		return s:done()
	end,
})

-- The ice cream cart ------------------------------------------------------------------------------

event({
	id = "icecreamcart",
	group = "work",
	actors = 2,
	when = "day",
	need = NEED.icecream,
	w = { base = 0.21, cond = works("icecream") },
	scene = function(ctx, a, b)
		local s = K.scene(ctx, "At the ice cream cart")
		s:n("{a} is at the ice cream cart, and {b} is behind it with a scoop.")
		burst(s, "a", {
			foodie = "Two scoops, please.|No, three, it's a hot day.",
			easygoing = "One scoop, please.|Whatever's coldest, I'm melting.",
			cheeky = "one of everything please|kidding, one scoop",
			_ = "One scoop, please.|No, two, it's hot today.",
		}, "sparkle")
		burst(s, "b", {
			proud = "I've got strawberry, mint, and my own new flavour, which is the best.",
			nervous = "I've got strawberry and mint, and a new one I made, but it might be strange.",
			cheeky = "strawberry, mint, or the new one, which is a mystery",
			_ = "I've got strawberry, mint, and a new one I made this morning.",
		}, "idea", "point")
		s:say("a", "What's the new one?", "question")
		s:say("b", "Honey and sea salt.", "sparkle")
		s:choice("Try the new one.", function(c)
			c:voice("a", "wow", "sparkle", "cheer")
			c:voice("b", "brag", "music")
			c:xp("b", 5)
			c:rel(3)
			c:mood("a", 3)
			c:memo("b", "Someone finally tried my honey and sea salt ice cream, and they liked it.")
		end)
		s:choice("Strawberry, to be safe.", function(c)
			c:say("a", "Strawberry, please.", "heart")
			burst(c, "b", {
				gloomy = "Nobody ever picks the new one.",
				prickly = "Fine, but you're missing out.",
				_ = "Strawberry it is, but try the new one next time.",
			}, "sweat")
			c:rel(1)
			c:mood("a", 2)
		end)
		s:log("{a} bought an ice cream from {b}.")
		return s:done()
	end,
})

-- The chalkboard ----------------------------------------------------------------------------------

event({
	id = "chalkcat",
	group = "work",
	actors = 2,
	when = "day",
	need = NEED.chalkboard,
	w = { base = 0.14, job = "teacher", btraits = { mischief = 0.3 } },
	scene = function(ctx, a, b)
		local s = K.scene(ctx, "On the chalkboard")
		s:n("Somebody has drawn a cat on {a}'s chalkboard, saying 'no homework'.")
		burst(s, "a", {
			prickly = "{player}, somebody drew on my board.|...It's actually quite a good cat, which is annoying.",
			gentle = "Oh, {player}, look at my chalkboard.|Someone drew a cat, and it's rather sweet.",
			cool = "{player}, someone drew on my board.|I think I know who.",
			_ = "{player}, somebody drew on my chalkboard.|It's a cat saying no homework, and it's very good.",
		}, "question", "point")
		burst(s, "b", {
			cheeky = "wasn't me|...ok it was me",
			shy = "Um... it was me, sorry.",
			proud = "Hmph, it's clearly the work of an artist.",
			nervous = "I-it wasn't me, I mean, it was, sorry!",
			_ = "It might have been me.",
		}, "sweat")
		s:choice("Leave it up, it's good.", function(c)
			burst(c, "a", {
				prickly = "Fine, it stays until Friday, but no homework is not happening.",
				_ = "Fine, it can stay until Friday.",
			}, "laugh", "laugh")
			c:rel(3)
			c:mood("b", 3)
		end)
		s:choice("Ask {b} to wipe it off.", function(c)
			c:say("b", "Okay, okay, I'm wiping it.", "sweat")
			c:n("{b} wiped the board clean, then drew a smaller cat in the corner.")
			c:rel(1)
		end)
		s:log("{b} drew on {a}'s chalkboard.")
		return s:done()
	end,
})

-- The TV ------------------------------------------------------------------------------------------

event({
	id = "tvremote",
	group = "pairs",
	actors = 2,
	when = "any",
	need = NEED.tv,
	w = { base = 0.14, rel = -30 },
	scene = function(ctx, a, b)
		local s = K.scene(ctx, "The remote")
		s:n("{a} and {b} both want the TV at eight.")
		burst(s, "a", {
			foodie = "The cooking show is on at eight, and it's the cake one.",
			bookish = "There's a programme about lighthouses on at eight.",
			_ = "My cooking show is on at eight.",
		}, "anger", "point")
		burst(s, "b", {
			bold = "And the boat race is on at eight, so that's that.",
			dramatic = "And the final of my quiz show is on at EIGHT.",
			_ = "And the boat race is on at eight.",
		}, "anger")
		s:choice("{a} picks tonight.", function(c)
			c:voice("a", "happy", "sparkle", "cheer")
			burst(c, "b", {
				prickly = "Ugh, fine, but I pick tomorrow.",
				gloomy = "Heh... I'll read about it in the paper.",
				_ = "Fine, but I pick tomorrow.",
			}, "sweat")
			c:mood("a", 3)
			c:mood("b", -1)
		end)
		s:choice("{b} picks tonight.", function(c)
			c:voice("b", "happy", "sparkle", "cheer")
			burst(c, "a", {
				prickly = "Ugh, fine, but I pick tomorrow.",
				gloomy = "Heh... I'll read the recipe in the paper.",
				_ = "Fine, but I pick tomorrow.",
			}, "sweat")
			c:mood("b", 3)
			c:mood("a", -1)
		end)
		s:log("{a} and {b} argued over the TV.")
		return s:done()
	end,
})

-- The arcade --------------------------------------------------------------------------------------

event({
	id = "arcadescore",
	group = "solo",
	when = "any",
	need = NEED.arcade,
	w = { base = 0.13, traits = { focus = 0.1, mischief = 0.1 } },
	scene = function(ctx, a)
		local s = K.scene(ctx, "The top score")
		s:n("{a} has been at the arcade machine for an hour.")
		burst(s, "a", {
			bold = "{player}, I'm forty points off the top score.|Watch this.",
			cheeky = "{player} don't talk to me|i'm forty points off the top score",
			nervous = "{player}, I'm so close to the top score.|What if I mess it up now?",
			proud = "{player}, the top score is about to be mine.|It always was, really.",
			_ = "{player}, I'm forty points off the top score.|One more go, I think I can do it.",
		}, "sparkle")
		s:choice("Keep going, you've got this.", function(c)
			c:n("{a} beat it by two points and put their name at the top.")
			c:voice("a", "brag", "sparkle", "cheer")
			c:mood("a", 5)
			-- and somebody takes it off them (Sim/FollowUps)
			c:follow("arcadebeaten", { chance = 0.6, hours = 6 })
		end)
		s:choice("Rest your thumbs first.", function(c)
			burst(c, "a", {
				easygoing = "Good idea, my thumbs are asleep anyway.",
				_ = "Fine, I'll come back with fresh thumbs.",
			}, "zzz")
			c:mood("a", 1)
		end)
		s:log("{a} chased the top score at the arcade.")
		return s:done()
	end,
})

event({
	id = "arcadebeaten",
	group = "solo",
	followup = true,
	when = "any",
	need = NEED.arcade,
	w = { base = 1 },
	scene = function(ctx, a)
		local s = K.scene(ctx, "Beaten")
		s:n("{a} is back at the arcade, glaring at the screen.")
		burst(s, "a", {
			dramatic = "{player}, somebody BEAT my score overnight!|They signed it ZZZ.",
			cheeky = "{player} someone beat my score|they signed it ZZZ. coward",
			proud = "{player}, someone has beaten my score.|It won't last.",
			gloomy = "{player}, my score lasted one night.|Heh... of course it did.",
			_ = "{player}, somebody beat my score overnight.|They signed it ZZZ, which tells me nothing.",
		}, "anger", "point")
		s:choice("Win it back.", function(c)
			c:n("It took all afternoon, but the top score says {a} again.")
			c:voice("a", "brag", "sparkle", "cheer")
			c:mood("a", 4)
		end)
		s:choice("Let ZZZ have it.", function(c)
			burst(c, "a", {
				easygoing = "Yeah, it's too much effort, ZZZ can keep it.",
				_ = "Fine, ZZZ can have it, for now.",
			}, "sad")
			c:mood("a", -1)
		end)
		s:log("Somebody beat {a}'s top score.")
		return s:done()
	end,
})

-- The BBQ -----------------------------------------------------------------------------------------

event({
	id = "bbqsausages",
	group = "pairs",
	actors = 2,
	when = "day",
	need = NEED.bbq,
	w = { base = 0.14, rel = -10, weather = { "clear", "cloudy", "leaves", "blossom" } },
	scene = function(ctx, a, b)
		local s = K.scene(ctx, "At the BBQ")
		s:n("{a} is at the BBQ, and {b} is waiting with a plate.")
		burst(s, "a", {
			bold = "Nearly done, nearly done.",
			nervous = "Are they done? I can never tell when they're done.",
			proud = "Everyone stand back, I know exactly what I'm doing.",
			_ = "Nearly done, give them a minute.",
		}, "sparkle")
		burst(s, "b", {
			cheeky = "they're looking a bit black|very black, actually",
			polite = "They are looking a little dark, if you do not mind me saying.",
			_ = "They're looking a bit black underneath.",
		}, "sweat", "point")
		s:choice("Take them off now.", function(c)
			c:n("Just in time. They were crisp on the outside and fine inside.")
			c:voice("b", "happy", "heart")
			c:rel(3)
			c:all(1)
		end)
		s:choice("Give them one more minute.", function(c)
			c:n("One more minute was too long.")
			burst(c, "b", {
				foodie = "I like them crunchy, honestly.|More for me, anyway.",
				gentle = "It's all right, they taste of summer.",
				_ = "I like them crunchy anyway.",
			}, "laugh", "laugh")
			c:rel(2)
		end)
		s:log("{a} and {b} had a BBQ.")
		return s:done()
	end,
})

-- The campfire ------------------------------------------------------------------------------------

event({
	id = "marshmallows",
	group = "pairs",
	actors = 2,
	when = "night",
	need = NEED.fire,
	w = { base = 0.15, rel = -10 },
	scene = function(ctx, a, b)
		local s = K.scene(ctx, "Marshmallows")
		s:n("{a} has toasted a marshmallow until it's golden. {b} has set three on fire.")
		burst(s, "b", {
			dramatic = "Why do mine keep BURSTING into flames?",
			gloomy = "Heh... that's three on fire.",
			cheeky = "i like them on fire, it's a choice",
			_ = "How do you keep yours from catching fire?",
		}, "sweat")
		burst(s, "a", {
			bookish = "You hold it over the glowing bit, not the flames, actually.",
			cool = "Hold it higher and turn it slowly.",
			_ = "Not so close, and keep turning it.",
		}, "idea", "point")
		s:choice("Show {b} how.", function(c)
			c:n("{b}'s fourth one came out golden all over.")
			c:voice("b", "brag", "sparkle", "cheer")
			c:rel(4)
		end)
		s:choice("Eat the burnt ones.", function(c)
			burst(c, "b", {
				foodie = "They taste fine if you close your eyes.|Pass me another.",
				_ = "They taste fine if you close your eyes.",
			}, "laugh", "laugh")
			c:rel(3)
		end)
		s:log("{a} and {b} toasted marshmallows.")
		return s:done()
	end,
})

-- The fish tank -----------------------------------------------------------------------------------

event({
	id = "fishtank",
	group = "solo",
	when = "any",
	need = NEED.fishtank,
	w = { base = 0.11 },
	scene = function(ctx, a)
		local s = K.scene(ctx, "The fish tank")
		s:n("{a} is watching the fish tank with their nose on the glass.")
		burst(s, "a", {
			dreamy = "{player}, the fish keeps swimming the same way round...|I think it's thinking about something.",
			nervous = "{player}, is the fish all right?|It's been swimming in circles for an hour.",
			bookish = "{player}, I think the fish is bored.|Actually, fish like something to hide in.",
			_ = "{player}, I think the fish looks bored.|It's been swimming the same way round for an hour.",
		}, "question")
		s:choice("Give it a little castle.", function(c)
			c:n("{a} put a little castle in the tank. The fish swam straight inside and stayed there.")
			c:voice("a", "happy", "heart")
			c:mood("a", 3)
		end)
		s:choice("Fish always swim in circles.", function(c)
			burst(c, "a", {
				nervous = "Oh, good, so it's not just ours.",
				dreamy = "Hmm... then maybe it's going somewhere.",
				_ = "Oh, so it's not just ours, then.",
			}, "idea")
			c:mood("a", 1)
		end)
		s:log("{a} worried the fish was bored.")
		return s:done()
	end,
})

-- The bird feeder ---------------------------------------------------------------------------------

event({
	id = "birdfeeder",
	group = "solo",
	when = "day",
	need = NEED.birds,
	w = { base = 0.11 },
	scene = function(ctx, a)
		local s = K.scene(ctx, "The bird feeder")
		s:n("A robin keeps chasing the little birds away from the feeder, and {a} has been watching it all morning.")
		burst(s, "a", {
			prickly = "{player}, that robin is a bully.|It won't let anyone else have a turn.",
			gentle = "{player}, the robin won't share the feeder.|The little ones look so hungry, bless them.",
			cheeky = "{player} the robin is running a gang|nobody else gets any seeds",
			_ = "{player}, the robin won't let the other birds near the feeder.",
		}, "anger", "point")
		s:choice("Scatter some seed on the grass too.", function(c)
			c:n("The little birds came down to the grass, and the robin couldn't guard both.")
			c:voice("a", "happy", "sparkle")
			c:mood("a", 3)
		end)
		s:choice("Let the robin have it.", function(c)
			burst(c, "a", {
				prickly = "Fine, but I'm not happy about it.",
				_ = "I suppose it was there first.",
			}, "sweat")
			c:mood("a", 0)
		end)
		s:log("{a} watched the birds at the feeder.")
		return s:done()
	end,
})

-- The bees ----------------------------------------------------------------------------------------

event({
	id = "beesting",
	group = "solo",
	when = "day",
	need = NEED.bees,
	w = { base = 0.1, season = { 1, 2 } },
	scene = function(ctx, a)
		local s = K.scene(ctx, "The bees")
		s:n("{a} went to look at the bees and came back with a swollen finger and a jar of honey.")
		burst(s, "a", {
			dramatic = "{player}, I've been STUNG.|But look, I got a whole jar of honey.",
			gloomy = "I got stung, of course.|I got some honey too, though.",
			foodie = "{player}, I got stung, but I also got honey.|I think it was worth it.",
			bold = "One sting, one jar of honey, I'd call that a fair trade.",
			_ = "{player}, a bee stung me.|I did get a jar of honey, though.",
		}, "sweat", "point")
		s:choice("Run it under cold water.", function(c)
			c:n("The cold water helped, and the swelling went down by lunch.")
			c:voice("a", "thanks", "heart")
			c:mood("a", 2)
			c:hearts("a", 1)
			-- and they do something with the honey (Sim/FollowUps)
			c:follow("honeycake", { chance = 0.6, hours = 5 })
		end)
		s:choice("Was the honey worth it?", function(c)
			burst(c, "a", {
				foodie = "Honestly, yes.|I'm going to bake something with it.",
				_ = "Ask me again when my finger stops hurting.",
			}, "laugh", "laugh")
			c:mood("a", 1)
			c:follow("honeycake", { chance = 0.4, hours = 5 })
		end)
		s:log("A bee stung {a}.")
		return s:done()
	end,
})

event({
	id = "honeycake",
	group = "solo",
	followup = true,
	when = "day",
	need = NEED.bees,
	w = { base = 1 },
	scene = function(ctx, a)
		local s = K.scene(ctx, "Honey cake")
		s:prop("bakes", "a")
		s:n("{a} is going round town with a tray of honey cake.")
		burst(s, "a", {
			sunny = "{player}, I made honey cake with the honey!|Take two, there's loads.",
			gloomy = "I made honey cake.|It was worth the sting, I suppose.",
			cheeky = "{player} honey cake|made with honey i was stung for, so you have to like it",
			_ = "{player}, I made a honey cake with the honey from the bees.|Have a slice.",
		}, "heart", "wave")
		s:all(2)
		s:mood("a", 3)
		s:log("{a} shared a honey cake.")
		return s:done()
	end,
})

-- The trampoline ----------------------------------------------------------------------------------

event({
	id = "trampoline",
	group = "solo",
	when = "day",
	need = NEED.trampoline,
	w = { base = 0.11, traits = { brave = 0.1, mischief = 0.1 } },
	scene = function(ctx, a)
		local s = K.scene(ctx, "The trampoline")
		s:n("{a} has been bouncing on the trampoline for twenty minutes.")
		burst(s, "a", {
			bold = "{player}, watch this, I'm doing a flip.",
			nervous = "{player}, I'm going to try a flip.|Actually, maybe a small one.",
			cheeky = "{player} watch|i'm about to do a flip or break something",
			_ = "{player}, watch this, I'm going to do a flip.",
		}, "sparkle", "point")
		s:choice("Go on, then.", function(c)
			c:n("{a} did half a flip and landed on their back, laughing.")
			c:voice("a", "laugh", "laugh", "laugh")
			c:mood("a", 3)
		end)
		s:choice("Maybe just a big bounce.", function(c)
			burst(c, "a", {
				bold = "Fine, the biggest bounce you've ever seen, then.",
				_ = "Okay, a really big bounce instead.",
			}, "sparkle")
			c:n("It was a really big bounce.")
			c:mood("a", 2)
		end)
		s:log("{a} tried a flip on the trampoline.")
		return s:done()
	end,
})

-- The bicycle -------------------------------------------------------------------------------------

event({
	id = "bikeflat",
	group = "solo",
	when = "day",
	need = NEED.bicycle,
	w = { base = 0.11 },
	scene = function(ctx, a)
		local s = K.scene(ctx, "A flat tyre")
		s:n("{a} is pushing the bicycle home with a flat tyre.")
		burst(s, "a", {
			prickly = "{player}, don't ask.|I rode over a nail by the harbour.",
			gloomy = "{player}, I got a flat tyre.|Of course I did, I was having a nice day.",
			sunny = "{player}, my tyre went flat halfway to the beach!|Do you know how to fix one?",
			_ = "{player}, my tyre's gone flat.|Do you know how to fix a puncture?",
		}, "sweat")
		s:choice("Let's patch it together.", function(c)
			c:n("You found the hole with a bowl of water and put a patch on it.")
			c:voice("a", "thanks", "heart")
			c:mood("a", 3)
			c:hearts("a", 1)
			c:follow("bikeride", { chance = 0.6, hours = 4 })
		end)
		s:choice("Leave it for tomorrow.", function(c)
			burst(c, "a", {
				easygoing = "Tomorrow sounds good, I'm tired anyway.",
				_ = "Tomorrow, then, my legs are tired anyway.",
			}, "zzz")
			c:mood("a", 0)
		end)
		s:log("{a} got a flat tyre.")
		return s:done()
	end,
})

event({
	id = "bikeride",
	group = "solo",
	followup = true,
	when = "day",
	need = NEED.bicycle,
	w = { base = 1 },
	scene = function(ctx, a)
		local s = K.scene(ctx, "The patch held")
		s:n("{a} rode past, ringing the bell.")
		burst(s, "a", {
			sunny = "{player}, the patch is still holding!|I rode all the way to the harbour and back.",
			cool = "The patch held, all the way to the harbour and back.",
			cheeky = "{player} the patch held|we're a great team, don't tell anyone",
			_ = "{player}, the patch held.|I rode to the harbour and back on it.",
		}, "sparkle", "wave")
		s:mood("a", 3)
		s:log("{a} rode to the harbour and back.")
		return s:done()
	end,
})

-- The washing machine -----------------------------------------------------------------------------

event({
	id = "pinkwash",
	group = "solo",
	when = "any",
	need = NEED.washer,
	w = { base = 0.1 },
	scene = function(ctx, a)
		local s = K.scene(ctx, "Pink washing")
		s:n("{a} put a red sock in with the white washing.")
		burst(s, "a", {
			dramatic = "{player}, everything I own is PINK.|Every single shirt.",
			gloomy = "{player}, all my shirts are pink now.|I should have seen that coming.",
			cheeky = "{player} new look|everything is pink. on purpose. definitely on purpose",
			proud = "{player}, I've decided pink is my colour now.|It was not an accident.",
			_ = "{player}, all my shirts came out pink.|There was a red sock in with them.",
		}, "sweat", "point")
		s:choice("Pink suits you.", function(c)
			burst(c, "a", {
				proud = "It does, doesn't it?",
				shy = "Really...? Okay, then I'll keep wearing them.",
				_ = "Really? Then I'll stop worrying about it.",
			}, "heart")
			c:mood("a", 3)
		end)
		s:choice("Wash them again.", function(c)
			c:n("They came out a little less pink.")
			c:mood("a", 1)
		end)
		s:log("{a}'s washing came out pink.")
		return s:done()
	end,
})

-- The well ----------------------------------------------------------------------------------------

event({
	id = "wishingwell",
	group = "solo",
	when = "any",
	need = NEED.well,
	w = { base = 0.1 },
	scene = function(ctx, a)
		local s = K.scene(ctx, "A wish")
		s:n("{a} is holding a coin over the well.")
		burst(s, "a", {
			dreamy = "{player}, I'm making a wish...|I can't tell you what it is, or it won't come true.",
			cheeky = "{player} i'm making a wish|no you can't know what it is",
			shy = "Um, {player}, don't watch, I'm making a wish.",
			_ = "{player}, I'm making a wish.|I can't tell you what it is, or it won't come true.",
		}, "sparkle")
		s:choice("Make it a good one.", function(c)
			c:n("{a} shut their eyes and dropped the coin. It took a long time to land.")
			c:mood("a", 3)
			c:follow("wishcame", { chance = 0.4, hours = 8 })
		end)
		s:choice("Can I guess what it is?", function(c)
			burst(c, "a", {
				cheeky = "nope|ok one guess",
				_ = "No guessing, or it won't count.",
			}, "laugh", "laugh")
			c:n("You guessed anyway, and got it wrong. {a} looked very pleased about that.")
			c:mood("a", 2)
		end)
		s:log("{a} made a wish at the well.")
		return s:done()
	end,
})

event({
	id = "wishcame",
	group = "solo",
	followup = true,
	when = "any",
	need = NEED.well,
	w = { base = 1 },
	scene = function(ctx, a)
		local s = K.scene(ctx, "The wish")
		burst(s, "a", {
			sunny = "{player}, remember my wish at the well?|It came true, it actually came true!",
			gloomy = "{player}, my wish came true.|I don't know what to do with that.",
			cheeky = "{player} my wish came true|and no, i'm still not telling you",
			dreamy = "{player}... my wish came true.|I knew the well was listening.",
			_ = "{player}, remember my wish at the well?|I think it came true, and I'm still not telling you what it was.",
		}, "sparkle", "cheer")
		s:mood("a", 5)
		s:log("{a}'s wish came true.")
		return s:done()
	end,
})

-- The record player -------------------------------------------------------------------------------

event({
	id = "oldrecord",
	group = "pairs",
	actors = 2,
	when = "any",
	need = NEED.records,
	w = { base = 0.13, rel = 0 },
	scene = function(ctx, a, b)
		local s = K.scene(ctx, "An old record")
		s:n("{a} found an old record at the market and put it on.")
		burst(s, "b", {
			gentle = "Oh, I know this one.|My gran used to hum it while she cooked.",
			dreamy = "I know this song... I think I heard it in a dream once.",
			cheeky = "oh no i know all the words to this",
			_ = "I know this one, my gran used to play it.",
		}, "music")
		s:choice("Dance to it.", function(c)
			c:n("They danced round the room until the record ran out.")
			c:rel(5)
			c:all(1)
		end)
		s:choice("Play it again.", function(c)
			c:n("They played it three more times and sang the last one.")
			c:rel(4)
		end)
		s:log("{a} and {b} listened to an old record.")
		return s:done()
	end,
})

-- The hammock -------------------------------------------------------------------------------------

event({
	id = "hammocknap",
	group = "solo",
	when = "day",
	need = NEED.hammock,
	w = { base = 0.11, traits = { lazy = 0.3 } },
	scene = function(ctx, a)
		local s = K.scene(ctx, "In the hammock")
		s:n("{a} fell asleep in the hammock this morning and has only just woken up.")
		burst(s, "a", {
			easygoing = "*yawn* {player}, what time is it?|Did I miss lunch? I think I missed lunch.",
			foodie = "{player}, what time is it?|Please tell me I didn't miss lunch.",
			nervous = "{player}, how long was I asleep?|Did I miss anything important?",
			_ = "{player}, what time is it?|I think I missed lunch.",
		}, "zzz")
		s:choice("I saved you a plate.", function(c)
			c:voice("a", "thanks", "heart", "cheer")
			c:mood("a", 4)
			c:hearts("a", 1)
		end)
		s:choice("It's nearly dinner time.", function(c)
			burst(c, "a", {
				easygoing = "Then I'll just wait here for dinner.",
				foodie = "Then I'll have two dinners to make up for it.",
				_ = "Then I'll have a big dinner.",
			}, "sweat")
			c:mood("a", 1)
		end)
		s:log("{a} slept in the hammock through lunch.")
		return s:done()
	end,
})

-- The rowing boat ---------------------------------------------------------------------------------

event({
	id = "rowboat",
	group = "solo",
	when = "day",
	need = NEED.boat,
	w = { base = 0.1, weather = { "clear", "cloudy", "blossom", "leaves" } },
	scene = function(ctx, a)
		local s = K.scene(ctx, "The rowing boat")
		burst(s, "a", {
			bold = "{player}, I'm rowing out to the middle.|Want to watch?",
			nervous = "{player}, I want to row out to the middle, but what if I can't get back?",
			_ = "{player}, I'm going to row the boat out to the middle and back.",
		}, "sparkle", "point")
		s:choice("Go on, I'll watch.", function(c)
			c:n("{a} rowed out without any trouble. Rowing back took a lot longer.")
			c:voice("a", "brag", "sparkle")
			c:mood("a", 3)
		end)
		s:choice("Take someone with you.", function(c)
			burst(c, "a", {
				nervous = "Good idea, then someone can row us back.",
				_ = "Good idea, then I can make them row.",
			}, "laugh", "laugh")
			c:mood("a", 2)
		end)
		s:log("{a} rowed the boat out.")
		return s:done()
	end,
})

-- The flower cart ---------------------------------------------------------------------------------

event({
	id = "flowersfor",
	group = "work",
	actors = 2,
	when = "day",
	need = NEED.florist,
	w = { base = 0.17, cond = works("florist") },
	scene = function(ctx, a, b)
		local s = K.scene(ctx, "At the flower cart")
		s:n("{a} is at the flower cart, trying to choose.")
		burst(s, "a", {
			shy = "Um, {b}, I want to say thank you to someone...|Which flowers say that?",
			bold = "{b}, I need flowers that say thank you.",
			_ = "{b}, which flowers say thank you?",
		}, "question")
		burst(s, "b", {
			bookish = "Sweet peas, actually, though nobody remembers that.",
			proud = "I know exactly which ones, naturally.",
			_ = "The yellow ones or the little blue ones, I'd say.",
		}, "idea", "point")
		s:choice("The yellow ones.", function(c)
			c:n("{b} wrapped a bunch of yellow ones in paper and tied it with string.")
			c:voice("a", "happy", "heart")
			c:xp("b", 4)
			c:rel(2)
		end)
		s:choice("The little blue ones.", function(c)
			c:n("{b} wrapped a bunch of blue ones in paper and tied it with string.")
			c:voice("a", "happy", "heart")
			c:xp("b", 4)
			c:rel(2)
		end)
		s:log("{a} bought flowers from {b}.")
		return s:done()
	end,
})

-- The drums ---------------------------------------------------------------------------------------

event({
	id = "drumsnoise",
	group = "pairs",
	actors = 2,
	when = "any",
	need = NEED.drums,
	w = { base = 0.1, btraits = { temper = 0.2 } },
	scene = function(ctx, a, b)
		local s = K.scene(ctx, "The drums")
		s:n("{a} has been practising the drums since breakfast, and {b} has come round.")
		burst(s, "b", {
			prickly = "{a}, some of us are trying to read.|Or think, or do anything at all.",
			gentle = "{a}, it's lovely that you're learning.|Could it be a bit later in the day, maybe?",
			cool = "{a}, it's eight in the morning.",
			_ = "{a}, could you practise a bit later in the day?",
		}, "anger")
		burst(s, "a", {
			dramatic = "But the music won't WAIT!",
			cheeky = "but i was just getting good",
			_ = "Sorry, I didn't think it was that loud.",
		}, "sweat")
		s:choice("Practise in the afternoons.", function(c)
			c:say("a", "Afternoons only, I promise.", "idea")
			c:say("b", "Thank you.", "heart")
			c:rel(2)
		end)
		s:choice("Put a rug under them.", function(c)
			c:n("The rug made it a bit quieter. Only a bit.")
			c:rel(1)
		end)
		s:log("{b} asked {a} to drum a bit quieter.")
		return s:done()
	end,
})

-- The little greenhouse ---------------------------------------------------------------------------

event({
	id = "onetomato",
	group = "solo",
	when = "day",
	need = NEED.greenhouse,
	w = { base = 0.1, season = { 2, 3 } },
	scene = function(ctx, a)
		local s = K.scene(ctx, "One tomato")
		s:n("{a} grew a tomato in the greenhouse. Just the one.")
		burst(s, "a", {
			proud = "{player}, behold, my tomato.|It's small, but it's perfect.",
			gloomy = "{player}, I grew one tomato.|One, all summer.",
			foodie = "{player}, I grew a tomato!|I've been planning what to make with it for a week.",
			cheeky = "{player} look at my tomato|i've named it, it's called lunch",
			_ = "{player}, look, I grew a tomato.|It's only one, but it's mine.",
		}, "sparkle", "point")
		s:choice("Share it with someone.", function(c)
			c:n("{a} cut it into slices and shared it out. Everyone got about a bite.")
			c:all(1)
			c:mood("a", 3)
		end)
		s:choice("Eat it yourself, you earned it.", function(c)
			c:voice("a", "happy", "heart")
			c:mood("a", 4)
		end)
		s:log("{a} grew a tomato.")
		return s:done()
	end,
})

return list
