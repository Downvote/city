--!nonstrict
-- The whole town: a power cut, talent night, a parade, market day, a tour bus, a sculpture that
-- turns up overnight, a lost dog, a busker, quiz night, fireworks, a clean up, the seasons and
-- the weather, the ferry, lanterns on the harbour, a snowball fight. Most star the villager who
-- noticed first (so the bubbles and props have somewhere to be); the good they do usually
-- reaches everybody around. Narration stays plain; the villagers talk the way a friend texts
-- you, each message one whole sentence in their own voice, and call you by name ({player}).

local K = require(script.Parent.Kit)
local Tuning = require(script.Parent.Parent.Parent.Config.Tuning)

local W = K.W

local list = {}
local function event(def)
	def.actors = def.actors or 0
	table.insert(list, def)
end

-- A burst: what they'd send as two or three quick messages (Kit's s:burst: a line or a map
-- keyed by personality, "|" between the messages).
local function burst(s, who: string, map: any, icon: string?, gesture: string?)
	return s:burst(who, map, icon, gesture)
end

-- How somebody takes winning, when you were the judge.
local WINNER = {
	sunny = "Me? Wait, wait, really?|Thank you so much!",
	proud = "Naturally, and I accept with grace.",
	bold = "Hah, I knew it.",
	shy = "...!|Me? Um... thank you.",
	cheeky = "the judge has very good taste|hehe",
	cool = "Hm. Thanks, {player}.",
	prickly = "Obviously.|...But thanks.",
	dramatic = "VICTORY!|I'd like to thank everyone who believed in me.",
	bookish = "Oh, I really didn't expect that.|Thank you.",
	gloomy = "I won?|Heh... something must have gone wrong.",
	gentle = "Oh, my, thank you, {player}.",
	dreamy = "Hmm... I won?|That's nice.",
	easygoing = "Eh, and I didn't even try that hard.",
	polite = "Thank you kindly, {player}, that's very generous.",
	foodie = "Is there a prize, and can I eat it?",
	nervous = "M-me? Are you sure?|Oh, thank you!",
	_ = "Me? Thanks, {player}.",
}

-- How the one who got the quiz right takes it (nobody judged: the answer was right).
local QUIZWIN = {
	sunny = "We won, we won!|Ehehe, let's open the biscuits right now!",
	proud = "Naturally, I knew it all along.",
	bold = "Hah, I told you we'd win.",
	cheeky = "we're geniuses|hehe, biscuits",
	cool = "Hm. Good answer.",
	prickly = "Obviously it was right.|...Good job, though.",
	dramatic = "We are CHAMPIONS!",
	gloomy = "We actually won?|Heh... that never happens.",
	foodie = "Mmm, a whole tin of biscuits, and we're opening it on the way home.",
	nervous = "W-we won?|Oh, thank goodness.",
	_ = "We won, and the biscuits are ours.",
}

local function night(ctx): boolean
	return ctx.hour >= Tuning.Day.NightStart or ctx.hour < Tuning.Day.NightEnd
end

-- somebody around who isn't one of the stars, by name (or nil)
local function bystander(ctx, ...): string?
	local skip = { ... }
	local options = {}
	for _, vid in ctx.present do
		if not table.find(skip, vid) then
			table.insert(options, vid)
		end
	end
	if #options == 0 then
		return nil
	end
	return ctx.rng:pick(options)
end

event({
	id = "powercut",
	actors = 2,
	when = "night",
	weight = W({ base = 0.15, count = 2 }),
	scene = function(ctx, a, b)
		local s = K.scene(ctx, "Power cut")
		s:prop("item:keep_lantern", "a")
		s:n("Every light in town went out at once.")
		burst(s, "b", {
			sunny = "Eek, it's so dark!|Can I hold your sleeve for a bit?",
			gentle = "Oh dear, is everyone all right?",
			bold = "Stay where you are, everyone.",
			dreamy = "Oh... it's so dark you can see every star.",
			easygoing = "Eh, I was about to go to bed anyway.",
			proud = "I'm not scared of the dark, I'm just standing very still.",
			shy = "Um... is anyone there?",
			cheeky = "who turned the town off?",
			cool = "Quiet, and don't move.",
			prickly = "Great, who tripped over the cable this time?",
			dramatic = "*gasp* We've been plunged into DARKNESS!",
			bookish = "I can't see my own hand, and I was halfway down a page.",
			gloomy = "Of course the power's gone, as usual.",
			polite = "Oh dear, does anyone have a light?",
			foodie = "My dinner was still in the oven!",
			nervous = "Oh no, oh no, I can't see anything!",
			_ = "Who turned the lights off?",
		}, "sweat")
		burst(s, "a", {
			bold = "Nobody panic, I've got candles somewhere.|Ow, that was a table.",
			gentle = "Here, I've got a lantern.|Come and sit with me until the lights come back, all right?",
			cheeky = "oooOOOooo, i'm a ghost|ok ok, i've got a lantern",
			sunny = "{player}, over here, I've got a lantern!|Just follow the light!",
			cool = "I've got a lantern. Stay close.",
			prickly = "Stop bumping into things.|...Here's a lantern, and don't say thanks.",
			dramatic = "Darkness has fallen!|But fear not, I have a LANTERN.",
			bookish = "Actually, it'll be the main line by the harbour.|It went out last winter too.",
			gloomy = "Heh... I knew this would happen.|I keep a lantern ready for nights like this.",
			polite = "Is everyone all right?|Please, come and sit by my lantern.",
			foodie = "Oh no, my fridge.|Okay, lantern first, and then we eat whatever's in the fridge.",
			nervous = "I-is it just us, or is it everyone?|Okay, okay, I have a lantern somewhere.",
			_ = "Hang on, {player}, I've got a lantern in here somewhere.",
		}, "idea")
		s:n("By the time the lights came back on, half the street was sitting on {a}'s step, telling stories.")
		s:rel(6)
		s:all(2)
		s:log("There was a power cut. Everyone sat out on {a}'s step.")
		return s:done()
	end,
})

local TALENTS = {
	sunny = "sings a song about everybody in town, by name",
	gentle = "folds a paper crane in under a minute",
	bold = "lifts a bench with someone still sitting on it",
	dreamy = "recites a poem about a cloud, with actions",
	easygoing = "balances a spoon on their nose for a very long time",
	proud = "gives a grand speech from a play nobody's heard of",
	shy = "plays a quiet little tune on a whistle with their eyes shut",
	cheeky = "pulls a coin from behind everyone's ear, then keeps the coins",
	cool = "solves a puzzle box without looking at it, then walks off",
	prickly = "sings one song very well, scowling the whole way through",
	dramatic = "acts out the whole history of the town in four minutes",
	bookish = "names every bird on the island from its call",
	gloomy = "tells a ghost story so sad that people clap slowly",
	polite = "bows, thanks the judge and juggles three teacups",
	foodie = "eats a whole lemon without making a face",
	nervous = "builds a card tower very slowly while everyone holds their breath",
}

event({
	id = "talentnight",
	cutscene = { stage = "bandstand", extras = 2, open = "wide", ending = { shot = "wide", act = { all = "cheer" } } },
	actors = 3,
	when = "any",
	weight = W({
		base = 0.12,
		count = 3,
		cond = function(ctx)
			return ctx.hour >= 17 or night(ctx)
		end,
	}),
	scene = function(ctx, a, b, c)
		local s = K.scene(ctx, "Talent night")
		s:prop("microphone", "a")
		s:prop("trophy", "b")
		s:n("It's talent night in the square, there are three acts, and you're the judge.")
		for _, who in { "a", "b", "c" } do
			local vid = ctx.stars[who]
			s:with({ act = TALENTS[K.pers(ctx, vid)] or "does something nobody can describe" })
			s:n("{" .. who .. "} {act}.")
		end
		for _, who in { "a", "b", "c" } do
			s:choice("{" .. who .. "} wins.", function(ch)
				burst(ch, who, WINNER, "sparkle", "cheer")
				ch:mood(who, 8)
				ch:hearts(who, 1)
				ch:memo(who, "I won talent night, and now the trophy sits next to my bed.")
				for _, other in { "a", "b", "c" } do
					if other ~= who then
						ch:mood(other, -1)
					end
				end
				ch:all(2)
			end)
		end
		s:log("There was a talent night: {a}, {b} and {c} took part.")
		return s:done()
	end,
})

event({
	id = "parade",
	when = "day",
	weight = W({ base = 0.08, count = 3 }),
	scene = function(ctx)
		local s = K.scene(ctx, "A parade")
		s:prop("balloons")
		s:n("Somebody decided there'd be a parade today, and nobody knows who. There's a drum and a lot of balloons.")
		s:n("Everyone in town joined in at the back and walked round the square twice.")
		local who = bystander(ctx)
		if who then
			s:with({ x = ctx.v(who).name })
			s:n("{x} led it, waving a wooden spoon like a baton.")
		end
		s:fx({ t = "festival" })
		s:all(4)
		s:coins(ctx.rng:int(4, 10) * 5)
		s:log("The town had a parade.")
		return s:done()
	end,
})

event({
	id = "marketday",
	when = "day",
	weight = W({ base = 0.15, count = 2 }),
	scene = function(ctx)
		local s = K.scene(ctx, "Market day")
		s:prop("stall")
		local coins = ctx.rng:int(3, 8) * 10
		s:with({ coins = coins })
		s:n("Stalls went up all along the square this morning, and one man is selling a single, very large cabbage.")
		s:n("The stall fees came to {coins} coins for the town.")
		s:coins(coins)
		s:all(2)
		s:log("It was market day. The stalls paid {coins} coins.")
		return s:done()
	end,
})

event({
	id = "tourbus",
	when = "day",
	weight = W({ base = 0.12 }),
	scene = function(ctx)
		local city = ctx.city()
		local tips = math.clamp(40 + math.floor(city.value / 200), 40, 600)
		local s = K.scene(ctx, "A tour bus"):with({ coins = tips })
		s:n("A tour bus pulled up by the harbour, and forty people in sun hats got off.")
		if city.value > 15000 then
			s:n("They took pictures of everything, and one of them took a picture of a bin.")
		else
			s:n("They bought every bun in the bakery and asked where the rest of the town was.")
		end
		s:n("They left {coins} coins in tips.")
		s:coins(tips)
		s:all(1)
		s:log("A tour bus came through and left {coins} coins.")
		return s:done()
	end,
})

event({
	id = "sculpture",
	when = "day",
	weight = W({
		base = 0.06,
		count = 2,
		cond = function(ctx)
			return ctx.hour < 12
		end,
	}),
	scene = function(ctx)
		local s = K.scene(ctx, "Something in the square")
		s:prop("sculpture")
		s:n("When the town woke up, there was a big stone snail in the square, and nobody saw it arrive.")
		s:n("Everyone is standing round it with their heads on one side.")
		s:choice("It stays.", function(c)
			c:n("The snail stays, and somebody's already put a hat on it.")
			c:leave("sculpture", 24)
			c:all(3)
		end)
		s:choice("Who made it?", function(c)
			local maker, best = nil, -1
			for _, vid in ctx.present do
				local m = K.trait(ctx, vid, "mischief") + ctx.rng:float(0, 0.3)
				if m > best then
					maker, best = vid, m
				end
			end
			if maker then
				c:with({ x = ctx.v(maker).name })
				c:n("It was {x}, and it took them three nights and a wheelbarrow.")
				c:n("{x} says it's called 'Slow Down', and nobody can tell if that's a joke.")
				c:fx({ t = "moodv", vid = maker, d = 6 })
			end
			c:leave("sculpture", 12)
			c:all(2)
		end)
		s:log("A stone snail turned up in the square overnight.")
		return s:done()
	end,
})

event({
	id = "lostdog",
	actors = 1,
	when = "day",
	weight = W({ base = 0.12, traits = { kind = 0.3 } }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "A lost dog")
		s:prop("dog", "a")
		s:n("A scruffy dog with a red collar has been following {a} round all morning.")
		burst(s, "a", {
			gentle = "{player}, this poor dog is lost.|His tag says 'Biscuit', so someone must be worried, don't you think?",
			bold = "Looks like I've got a new friend, {player}.|His tag says Biscuit, so we're on first names already.",
			shy = "Um, {player}, this dog keeps sitting on my feet.|I don't mind, though.",
			sunny = "{player}, look who found me!|His name's Biscuit, it says so on his tag!",
			cool = "{player}. This dog's lost.|His tag says Biscuit, so someone's missing him.",
			prickly = "He won't leave me alone.|...I gave him some water, but don't read into it.",
			dramatic = "{player}, a lost SOUL!|We have to find his family.",
			bookish = "There's the name of a farm on the back of his tag.|I think it's the one over the hill.",
			gloomy = "Someone's out there looking for him.|I hope they find him, but you never know.",
			polite = "Excuse me, does anyone know this dog?|His tag says he's called Biscuit.",
			foodie = "His name's Biscuit, so I like him already.",
			nervous = "W-what if nobody comes for him?|What if he's been lost for days?",
			cheeky = "guess what, i have a dog now|his name's biscuit, and he's not technically mine",
			_ = "{player}, his tag says Biscuit.|Somebody must be missing him.",
		}, "heart")
		s:choice("Let's put up posters.", function(c)
			c:n("An hour after the posters went up, a farmer from over the hill came running.")
			c:n("Biscuit nearly knocked him over, and he gave {a} a jar of honey and the town a reward.")
			c:coins(40)
			c:mood("a", 6)
			c:memo("a", "Biscuit the dog went home, and I miss him a bit.")
		end)
		s:choice("Keep him for the afternoon?", function(c)
			c:n("{a} and Biscuit spent the afternoon on the beach, and then the owner turned up at teatime.")
			burst(c, "a", {
				bold = "See you, Biscuit, be good.",
				shy = "Bye, Biscuit...",
				cheeky = "if you ever get lost again, get lost round here",
				cool = "Bye, dog. Take care.",
				prickly = "Go on, go home.|...Bye, Biscuit.",
				dramatic = "Farewell, Biscuit, I'll never forget you!",
				_ = "Bye, Biscuit, come and visit sometime.",
			}, "sad")
			c:mood("a", 4)
		end)
		s:log("A lost dog called Biscuit followed {a} around.")
		return s:done()
	end,
})

event({
	id = "fete",
	when = "day",
	weight = W({ base = 0.12, season = 2, count = 2 }),
	scene = function(ctx)
		local s = K.scene(ctx, "The summer fete")
		s:prop("stall")
		s:prop("balloons")
		s:n("The summer fete is on, with a cake stall and a game where you throw wet sponges at a volunteer.")
		local who = bystander(ctx)
		if who then
			s:with({ x = ctx.v(who).name })
			s:n("{x} volunteered, and {x} now regrets it.")
		end
		s:coins(ctx.rng:int(5, 12) * 5)
		s:all(4)
		s:log("The town had its summer fete.")
		return s:done()
	end,
})

event({
	id = "firstsnow",
	when = "any",
	weight = W({ base = 0.3, weather = "snow", count = 1 }),
	scene = function(ctx)
		local s = K.scene(ctx, "Snow")
		s:n("Snow is falling over the whole town.")
		s:n("Everybody came out to look, and a few people are trying to catch it on their tongues.")
		s:all(3)
		s:log("It snowed over the whole town.")
		return s:done()
	end,
})

event({
	id = "blossomday",
	when = "day",
	weight = W({ base = 0.3, weather = "blossom", count = 1 }),
	scene = function(ctx)
		local s = K.scene(ctx, "Blossom")
		s:n("The trees are all in flower, and the wind is blowing petals across every street.")
		s:n("People keep stopping in the middle of the road just to look.")
		s:all(3)
		s:log("The blossom was out all over town.")
		return s:done()
	end,
})

event({
	id = "harvest",
	when = "any",
	weight = W({
		base = 0.15,
		season = 3,
		count = 2,
		cond = function(ctx)
			return ctx.hour >= 16 or night(ctx)
		end,
	}),
	scene = function(ctx)
		local s = K.scene(ctx, "Harvest supper")
		s:prop("bakes")
		s:prop("marrow")
		s:n("Everyone brought a dish to the long table in the square for the harvest supper.")
		s:n("There were eleven pies, and nobody planned that.")
		for i = 1, #ctx.present do
			for j = i + 1, #ctx.present do
				s:fx({ t = "relv", a = ctx.present[i], b = ctx.present[j], d = 2 })
			end
		end
		s:all(4)
		s:log("The town had a harvest supper.")
		return s:done()
	end,
})

event({
	id = "heatwave",
	when = "day",
	weight = W({ base = 0.2, season = 2, weather = "clear" }),
	scene = function(ctx)
		local s = K.scene(ctx, "Hot day")
		s:prop("umbrella")
		s:n("It's the hottest day of the year, and the whole town is down on the beach.")
		s:n("The ice cream ran out by noon, and somebody's dog is lying in the fountain.")
		s:all(2)
		s:log("It was the hottest day of the year.")
		return s:done()
	end,
})

event({
	id = "greyday",
	when = "day",
	weight = W({ base = 0.15, weather = "cloudy" }),
	scene = function(ctx)
		local s = K.scene(ctx, "A grey day")
		s:n("It's grey and drizzly, and nobody feels like doing much.")
		local who = bystander(ctx)
		if who then
			s:with({ x = ctx.v(who).name })
			s:n("Then {x} opened a window and put some music on, loud, and people started humming along.")
			s:fx({ t = "moodv", vid = who, d = 3 })
		end
		s:all(1)
		s:log("It was a grey day, but someone put music on.")
		return s:done()
	end,
})

event({
	id = "comet",
	when = "night",
	weight = W({ base = 0.05, weather = "clear", count = 1 }),
	scene = function(ctx)
		local s = K.scene(ctx, "A comet")
		s:n("There's a comet in the sky tonight, and you can see its tail from the hill.")
		s:n("The whole town is out on the hill in dressing gowns, and nobody says much.")
		s:all(6)
		s:log("A comet crossed the sky.")
		return s:done()
	end,
})

event({
	id = "gulls",
	actors = 1,
	when = "day",
	weight = W({ base = 0.15 }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "Gulls")
		s:n("{a} sat down by the harbour with a bag of chips, and a gull landed on the bench.")
		s:n("Then another one came, and then nine more.")
		burst(s, "a", {
			bold = "Hah, back off, all of you!|...Fine, they're yours.",
			gentle = "Oh, all right, one each.|Form a nice line, please.",
			cheeky = "i'm one of you now|caw caw",
			proud = "Do you know who I am?|...Apparently you don't care.",
			sunny = "{player}, help, they're everywhere!",
			cool = "...Keep them, then.",
			prickly = "These are MY chips.|...Fine, one each, and I mean ONE.",
			dramatic = "Betrayed by the birds of my own harbour!",
			bookish = "Did you know gulls remember faces?|They'll be back for me tomorrow.",
			gloomy = "Heh... of course they did.",
			polite = "Excuse me, those are my... oh, all right then.",
			foodie = "Not the chips, anything but the chips!",
			nervous = "Th-there are too many of them.|{player}, how many gulls is too many?",
			_ = "{player}, they've taken all my chips.",
		}, "anger")
		s:mood("a", -2)
		s:log("Gulls took {a}'s chips.")
		return s:done()
	end,
})

event({
	id = "ducks",
	when = "day",
	weight = W({ base = 0.12 }),
	scene = function(ctx)
		local s = K.scene(ctx, "Ducks crossing")
		s:n("A mother duck and seven ducklings are crossing the main road very slowly.")
		s:n("The bus stopped to wait, and somebody held up a sign that said 'DUCKS'.")
		s:all(2)
		s:log("A family of ducks stopped the traffic.")
		return s:done()
	end,
})

event({
	id = "hotairballoon",
	when = "day",
	weight = W({ base = 0.04, weather = { "clear", "cloudy" } }),
	scene = function(ctx)
		local s = K.scene(ctx, "A balloon")
		s:n("A big striped hot air balloon drifted low over the town.")
		s:n("The people in the basket waved, and everybody waved back for quite a long time.")
		s:all(3)
		s:log("A hot air balloon drifted over town.")
		return s:done()
	end,
})

local QUESTIONS = {
	{ "How many legs does a crab have?", "Ten", "eight" },
	{ "What colour is a polar bear's skin?", "Black", "white" },
	{ "Which way does the sun come up?", "East", "west" },
	{ "How many legs does a spider have?", "Eight", "six" },
}

event({
	id = "quiz",
	actors = 2,
	when = "any",
	weight = W({
		base = 0.1,
		count = 2,
		cond = function(ctx)
			return ctx.hour >= 18 or night(ctx)
		end,
	}),
	scene = function(ctx, a, b)
		local q = ctx.rng:pick(QUESTIONS)
		local s = K.scene(ctx, "Quiz night"):with({ q = q[1], ans = q[2], low = string.lower(q[2]), wrong = q[3] })
		s:n("It's quiz night, and {a} and {b} are on a team they've called 'Quiz Team'.")
		s:n("Here's the last question. {q}")
		burst(s, "a", {
			bookish = "I've read about this, I know I have.",
			nervous = "Oh no, oh no, I don't know this one.",
			proud = "Hmph, this one's far too easy for me to bother with.",
			cheeky = "let's just guess something silly",
			cool = "Hm. Do you know it?",
			gloomy = "Heh... we were never going to get this one.",
			_ = "Hmm, do you know this one?",
		}, "question")
		if ctx.rng:chance(0.5) then
			s:say("b", "{ans}.", "idea", "point")
			s:n("That's right, and Quiz Team wins a tin of biscuits.")
			burst(s, "a", QUIZWIN, "sparkle", "cheer")
			s:mood("a", 4)
			s:mood("b", 4)
		else
			burst(s, "b", "Is it {wrong}?|Yes, {wrong}, that's our final answer.", "question")
			s:n("It was {low}, so Quiz Team came second out of two teams.")
			burst(s, "a", {
				sunny = "Second place is still a place!",
				proud = "Hmph, that question was very badly worded.",
				cheeky = "second place, hehe|out of two",
				cool = "Hm. Next time.",
				dramatic = "We were ROBBED.",
				bookish = "Actually, I knew it was {low}, I just didn't say anything.",
				gloomy = "Heh... second out of two, as usual.",
				nervous = "S-sorry, I should have said something.",
				_ = "Well, at least we came second.",
			}, "laugh", "laugh")
		end
		s:rel(5)
		s:log("{a} and {b} went to quiz night.")
		return s:done()
	end,
})

event({
	id = "busker",
	when = "day",
	weight = W({ base = 0.1 }),
	scene = function(ctx)
		local s = K.scene(ctx, "A busker")
		s:prop("microphone")
		s:n("A travelling busker set up in the square with a battered old guitar.")
		s:n("A small crowd has gathered, and some of them are swaying.")
		s:choice("Tip them (20 coins)", function(c)
			c:n("The busker played one more song just for the town and tipped their hat.")
			c:coins(-20)
			c:all(3)
		end, 20)
		s:choice("Just listen.", function(c)
			c:n("You stood at the back and listened until the last song.")
			c:all(1)
		end)
		s:log("A busker played in the square.")
		return s:done()
	end,
})

event({
	id = "fireworks",
	when = "night",
	weight = W({ base = 0.05, count = 2, weather = { "clear", "cloudy", "snow" } }),
	scene = function(ctx)
		local s = K.scene(ctx, "Fireworks")
		s:n("Fireworks went up over the harbour. Nobody knows who set them off, and nobody minds.")
		s:n("They were mostly big gold ones, though one went sideways into the sea.")
		s:fx({ t = "festival" })
		s:all(5)
		s:log("Fireworks went up over the harbour.")
		return s:done()
	end,
})

event({
	id = "cleanup",
	when = "day",
	weight = W({ base = 0.1, count = 3 }),
	scene = function(ctx)
		local s = K.scene(ctx, "Clean up day")
		s:n("Everyone came out with a bag and a pair of gloves and tidied the town, from the hill to the beach.")
		local who = bystander(ctx)
		if who then
			s:with({ x = ctx.v(who).name })
			s:n("{x} found a teapot in a hedge and is keeping it.")
		end
		for i = 1, #ctx.present do
			for j = i + 1, #ctx.present do
				s:fx({ t = "relv", a = ctx.present[i], b = ctx.present[j], d = 2 })
			end
		end
		s:all(3)
		s:log("The town had a clean up day.")
		return s:done()
	end,
})

event({
	id = "secretkindness",
	actors = 1,
	when = "day",
	weight = W({ base = 0.1, count = 3, traits = { kind = 0.6 } }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "Flowers on the doorsteps")
		s:n("For a week now, somebody has been leaving a single flower on every doorstep in town.")
		s:n("This morning you saw who it was, and it was {a}, out with a basket before sunrise.")
		burst(s, "a", {
			shy = "...!|Um, please don't tell anyone.|It's nicer if nobody knows.",
			proud = "Well, someone had to make this town beautiful.",
			cheeky = "act natural, {player}|i said ACT NATURAL",
			sunny = "{player}! Shh, you didn't see me!",
			cool = "...You didn't see anything, {player}.",
			prickly = "Don't, {player}, don't say anything.|They're just flowers.",
			dramatic = "*gasp* My secret is out!|You must tell no one, {player}.",
			gloomy = "People have seemed a bit sad lately.|I thought flowers might help a little.",
			polite = "Oh, {player}, you saw me.|I hope you don't mind, I only wanted to do something kind.",
			nervous = "Y-you won't tell anyone, will you?|Promise? Okay, okay.",
			_ = "Shh, it's better as a secret.",
		}, "heart")
		s:choice("Your secret's safe.", function(c)
			burst(c, "a", {
				shy = "Thank you, {player}.|Um, this one's for you.",
				cheeky = "good, here's yours then|now act natural",
				prickly = "...Good. Here, take one.|Don't make a thing of it.",
				_ = "Thank you, {player}.|Here, have one too.",
			}, "heart")
			c:hearts("a", 2)
			c:all(2)
		end)
		s:choice("Everyone should know.", function(c)
			c:n("The whole town clapped for {a} at lunch.")
			burst(c, "a", {
				shy = "Um... I'm going to go and hide for a week.",
				proud = "Well, it's about time somebody noticed.",
				bold = "Hah, okay, yes, it was me.",
				cool = "...Okay. Yes, it was me.",
				dramatic = "Yes, it was me all along!",
				_ = "Oh, stop it.|...Actually, don't stop.",
			}, "sweat")
			c:mood("a", 3)
			c:all(3)
		end)
		s:log("Someone left flowers on every doorstep in town.")
		return s:done()
	end,
})

event({
	id = "windy",
	when = "day",
	weight = W({ base = 0.15, weather = { "cloudy", "leaves" } }),
	scene = function(ctx)
		local s = K.scene(ctx, "A windy day")
		s:n("A big gust came through and took everyone's washing off the line.")
		s:n("There's a shirt on the fountain and a pair of pants on a gull.")
		local who = bystander(ctx)
		if who then
			s:with({ x = ctx.v(who).name })
			s:n("{x} is going round with a basket, giving things back and not asking questions.")
			s:fx({ t = "moodv", vid = who, d = 2 })
		end
		s:all(1)
		s:log("The wind blew everyone's washing round town.")
		return s:done()
	end,
})

event({
	id = "townbirthday",
	when = "day",
	weight = W({
		base = 3,
		count = 2,
		cond = function(ctx)
			return ctx.season == 1 and ctx.dayOfSeason == 1
		end,
	}),
	scene = function(ctx)
		local s = K.scene(ctx, "The town's birthday")
		s:prop("cake")
		s:prop("balloons")
		s:n("It's the first day of spring and the town's birthday, and somebody's made a cake the size of a table.")
		s:n("Everyone sang happy birthday to the town, very loudly.")
		s:fx({ t = "festival" })
		s:coins(100)
		s:all(5)
		s:log("The town had its birthday.")
		return s:done()
	end,
})

event({
	id = "whale",
	when = "day",
	weight = W({ base = 0.04 }),
	scene = function(ctx)
		local s = K.scene(ctx, "A whale")
		s:n("Somebody shouted from the pier, because there's a whale out past the harbour.")
		s:n("Everybody ran to look, and it blew a spout of water and rolled over, flapping one fin.")
		s:all(5)
		s:log("A whale was spotted off the pier.")
		return s:done()
	end,
})

event({
	id = "nightnoise",
	actors = 1,
	when = "night",
	weight = W({ base = 0.12 }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "A noise in the dark")
		s:n("Something has been rustling in {a}'s garden all night.")
		burst(s, "a", {
			gentle = "Oh dear, what's that rustling out there?",
			bold = "Right, whoever's in my garden, I'm coming out.",
			shy = "Um... is somebody out there?",
			cheeky = "if that's a burglar, they're a very noisy one",
			cool = "Something's in the garden.|I'll take a look.",
			prickly = "Ugh, whatever that is, it's been at it all night.",
			dramatic = "*gasp* There's a CREATURE in my garden!",
			bookish = "It's too heavy for a mouse and too light for a fox, so what is it?",
			gloomy = "It's probably something awful, as usual.",
			polite = "Hello? Is someone in the garden?",
			foodie = "If that's somebody after my vegetables, I'm not sharing.",
			nervous = "Wh-what's that noise?|Oh no, oh no, it's getting closer.",
			sunny = "Ooh, something's in the garden!|I'm going to go and look!",
			dreamy = "Hmm... something's out there in the dark...|Maybe it's lost.",
			easygoing = "Eh, whatever it is, it can have the garden.|...Okay, fine, I'll look.",
			proud = "I'm not scared, I'm simply going to investigate.",
			_ = "What's that rustling out there?",
		}, "sweat")
		s:n("{a} crept out with a torch and found a hedgehog eating the cat's dinner.")
		burst(s, "a", {
			gentle = "Oh, look at you.|Eat up, little one.",
			bold = "Hah, you gave me a real fright, mate.",
			shy = "Oh, um... hello.|You scared me a bit.",
			cheeky = "caught you|that's the cat's dinner, you know",
			cool = "Hm. Carry on, then.",
			prickly = "So it was you all night?|...Fine, finish it.",
			dramatic = "The BEAST of the garden!|...Is tiny, and very sweet.",
			bookish = "Did you know hedgehogs walk about two kilometres a night?|He's earned his dinner.",
			gloomy = "Heh... at least something's eating well tonight.",
			polite = "Oh, pardon me, please go on.",
			foodie = "The cat's having chicken tonight, so that's a good choice, hedgehog.",
			nervous = "Oh, thank goodness, it's only a hedgehog.",
			_ = "Well, that's the mystery solved.",
		}, "heart")
		s:mood("a", 2)
		s:log("{a} found a hedgehog in the garden at night.")
		return s:done()
	end,
})

event({
	id = "seamist",
	when = "day",
	weight = W({ base = 0.12, weather = "cloudy" }),
	scene = function(ctx)
		local s = K.scene(ctx, "Sea mist")
		s:n("A thick sea mist rolled in off the water, and you can't see the end of the street.")
		local who = bystander(ctx)
		if who then
			s:with({ x = ctx.v(who).name })
			s:n("{x} walked into the same lamppost twice and said sorry to it both times.")
		end
		s:all(1)
		s:log("A sea mist rolled in.")
		return s:done()
	end,
})

-- more of the town's days -----------------------------------------------------------------------

event({
	id = "ferry",
	when = "day",
	weight = W({ base = 0.12, count = 1 }),
	scene = function(ctx)
		local s = K.scene(ctx, "The ferry")
		s:prop("parcels")
		s:n("The ferry came in this morning with a crate of oranges for every house in town, and nobody ordered them.")
		s:n("The note on the crate says 'From the next island. We had too many.'")
		local who = bystander(ctx)
		if who then
			s:with({ x = ctx.v(who).name })
			s:n("{x} has already eaten three and is looking at a fourth.")
		end
		s:all(2)
		s:log("The ferry brought oranges for the whole town.")
		return s:done()
	end,
})

event({
	id = "foghorn",
	actors = 1,
	when = "night",
	weight = W({ base = 0.1 }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "The foghorn")
		s:n("The foghorn on the harbour went off at three in the morning, and there isn't any fog.")
		s:n("{a} came out in a dressing gown and one slipper.")
		burst(s, "a", {
			sunny = "{player}, is that you?|Did you hear it too?",
			gentle = "Is everyone all right?|I hope nobody's lost out there.",
			bold = "Right, who did that?|Come out, right now.",
			dreamy = "Hmm... maybe a boat was saying goodnight.",
			easygoing = "*yawn* I was having such a good sleep, too.",
			proud = "Hmph, I'll be writing to the harbour about this.",
			shy = "Um... I thought it was in my room.",
			cheeky = "it wasn't me, for once",
			cool = "...It's three in the morning.",
			prickly = "Whoever did that owes me a whole night's sleep.",
			dramatic = "A cry from the sea, at this HOUR?",
			bookish = "Actually, it runs on a timer.|Someone must have set it wrong.",
			gloomy = "Great, now I'm up for good, as usual.",
			polite = "Terribly sorry, has anyone seen my other slipper?",
			foodie = "Well, I'm up now, so I might as well have toast.",
			nervous = "I-is it a ship?|Is something wrong, should we do something?",
			_ = "{player}? What was that?|It's three in the morning.",
		}, "zzz")
		s:n("It was a gull standing on the button.")
		s:mood("a", -1)
		s:log("The foghorn went off at three in the morning.")
		return s:done()
	end,
})

event({
	id = "kiteday",
	when = "day",
	weight = W({ base = 0.1, count = 2, weather = { "clear", "cloudy", "leaves" } }),
	scene = function(ctx)
		local s = K.scene(ctx, "Kites on the hill")
		s:prop("kite")
		s:n("The wind came up just right, and half the town went up the hill with kites.")
		s:n("There's a red one, one shaped like a fish, and one that's mostly a bin bag.")
		local who = bystander(ctx)
		if who then
			s:with({ x = ctx.v(who).name })
			s:n("{x}'s kite went the highest, and they're telling everyone about it.")
			s:fx({ t = "moodv", vid = who, d = 3 })
		end
		s:all(3)
		s:log("The town flew kites on the hill.")
		return s:done()
	end,
})

event({
	id = "regatta",
	actors = 2,
	when = "day",
	weight = W({ base = 0.12, weather = { "clear", "cloudy", "leaves" } }),
	scene = function(ctx, a, b)
		local s = K.scene(ctx, "Toy boats")
		s:prop("item:keep_boat", "a")
		s:n("{a} and {b} each made a toy boat and set them off from the harbour steps, and you're the judge.")
		burst(s, "a", {
			proud = "Mine has a proper keel.|Watch it go, {player}.",
			bold = "Mine's faster, obviously, right?|Just look at it go.",
			sunny = "{player}, cheer for mine!|It's the one with the red sail!",
			cool = "Mine's the blue one.",
			dramatic = "Sail, little ship, sail for GLORY!",
			bookish = "I gave mine a longer hull.|In theory, that should make it quicker.",
			nervous = "It's leaning, is it meant to lean?|Oh no, oh no, it's leaning a lot.",
			_ = "Come on, come on, go, boat!",
		}, "sparkle", "point")
		burst(s, "b", {
			cheeky = "i put a pebble in the back of yours|kidding, maybe",
			gentle = "Oh, look at them both.|They're doing so well.",
			shy = "Um... mine's going sideways.|That's fine, though.",
			prickly = "Mine's winning, so don't argue, {player}.|Just judge it.",
			gloomy = "Mine's going to sink any moment now.|...It's still going, somehow.",
			foodie = "I made mine out of a lunch box, and it still smells of cheese.",
			_ = "Look, mine's catching up.",
		}, "sparkle")
		s:choice("{a}'s boat wins.", function(c)
			burst(c, "a", WINNER, "sparkle", "cheer")
			c:mood("a", 6)
			c:mood("b", -1)
		end)
		s:choice("{b}'s boat wins.", function(c)
			burst(c, "b", WINNER, "sparkle", "cheer")
			c:mood("b", 6)
			c:mood("a", -1)
		end)
		s:choice("Call it a draw.", function(c)
			c:n("Then a gull landed on both boats at once, which settled it.")
			c:say("a", "...That's fair, I suppose.", "laugh")
			c:rel(6)
		end)
		s:rel(3)
		s:log("{a} and {b} raced toy boats in the harbour.")
		return s:done()
	end,
})

event({
	id = "lanterns",
	when = "night",
	weight = W({ base = 0.08, season = { 3, 4 }, count = 2, weather = { "clear", "cloudy", "leaves", "snow" } }),
	scene = function(ctx)
		local s = K.scene(ctx, "Lanterns on the water")
		s:prop("item:keep_lantern")
		s:n("After dark, everyone took a paper lantern down to the harbour and set it on the water.")
		s:n("They drifted out slowly in a line, and nobody spoke until the last one went round the point.")
		s:all(4)
		s:log("The town floated lanterns on the harbour.")
		return s:done()
	end,
})

event({
	id = "haggle",
	actors = 2,
	when = "day",
	weight = W({ base = 0.13, count = 2 }),
	scene = function(ctx, a, b)
		local s = K.scene(ctx, "A jar of jam")
		s:prop("stall", "a")
		s:n("{a} has a table of jam jars at the market, and {b} has been holding the same jar for five minutes.")
		burst(s, "b", {
			cheeky = "two coins, final offer|ok, three, final final offer",
			proud = "I'll give you a fair price, which is half.",
			foodie = "Mmm, is this one plum?|How much for two, or for all of them?",
			bookish = "Actually, the label says 'strawbery'.|Surely that knocks a coin off.",
			nervous = "Is it okay if I just look for a bit longer?",
			polite = "Might I ask the price, if it's no trouble?",
			_ = "How much is this one?",
		}, "question")
		burst(s, "a", {
			bold = "It's five, and not a coin less.",
			gentle = "Oh, three coins is plenty, I made too many anyway.",
			cool = "It's four.",
			prickly = "It's four, and it says four right there.",
			dramatic = "That jar took a WHOLE summer to make!",
			gloomy = "Nobody's bought one all day.|Take it for two.",
			sunny = "For you, it's three!|And you can try the gooseberry too!",
			_ = "It's four coins, because it's the good stuff.",
		}, "sparkle")
		s:n("In the end {b} paid three coins and got a spoonful of the gooseberry to try.")
		s:rel(5)
		s:mood("a", 2)
		s:mood("b", 2)
		s:log("{b} bought a jar of jam from {a} at the market.")
		return s:done()
	end,
})

event({
	id = "thirteen",
	when = "day",
	weight = W({
		base = 0.06,
		count = 1,
		cond = function(ctx)
			return ctx.hour >= 11 and ctx.hour < 14
		end,
	}),
	scene = function(ctx)
		local s = K.scene(ctx, "Thirteen")
		s:n("At noon the town clock struck thirteen times, and everyone in the square counted along.")
		local who = bystander(ctx)
		if who then
			s:with({ x = ctx.v(who).name })
			s:n("{x} went up the tower to look and came down covered in dust, holding a pigeon.")
		end
		s:all(1)
		s:log("The town clock struck thirteen.")
		return s:done()
	end,
})

event({
	id = "seals",
	when = "day",
	weight = W({ base = 0.05, weather = { "clear", "cloudy" } }),
	scene = function(ctx)
		local s = K.scene(ctx, "Seals")
		s:n("Four seals hauled themselves onto the rocks by the pier and went to sleep in the sun.")
		s:n("By lunch, half the town was on the pier, whispering.")
		s:all(4)
		s:log("Seals came to sleep on the rocks by the pier.")
		return s:done()
	end,
})

event({
	id = "bookbox",
	actors = 1,
	when = "day",
	weight = W({ base = 0.12 }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "Take one, leave one")
		s:prop("box", "a")
		s:n("Somebody left a crate of books by the fountain with a sign saying 'Take one, leave one'.")
		s:n("{a} has been going through it for twenty minutes.")
		burst(s, "a", {
			bookish = "{player}, there's a first edition of a bird book in here.|Did you know hardly any of these are left?",
			sunny = "There are so many!|Which one should I take, {player}?",
			dreamy = "This one's about a lighthouse...|I think I'll take the lighthouse one.",
			cool = "I found a good one.",
			prickly = "Half of these are terrible.|...I'm taking two.",
			dramatic = "It's a treasure chest full of STORIES.",
			gloomy = "They're all sad ones, good.|I'll take this one.",
			foodie = "Mmm, there's a cookbook, and another cookbook, and that one's a cookbook too.",
			nervous = "C-can I take one if I haven't brought one yet?|I'll bring one tomorrow, I promise.",
			_ = "{player}, look at this.|There's a cookbook in here from before I was born.",
		}, "sparkle")
		s:choice("I'll leave one of mine.", function(c)
			c:n("You put in an old book about boats, and {a} took it out again straight away.")
			burst(c, "a", "Here, I'll swap you for this one.", "heart")
			c:mood("a", 4)
			c:hearts("a", 1)
		end)
		s:choice("You pick first.", function(c)
			burst(c, "a", {
				cool = "I've already got mine, thanks.|You have a look.",
				bookish = "This one, obviously.|...And maybe this one too.",
				_ = "Okay, this one.|No, wait, this one.",
			}, "question")
			c:mood("a", 3)
			c:memo("a", "I got a book from the box by the fountain, and I'm putting it back when I'm done.")
		end)
		s:log("A box of books turned up by the fountain.")
		return s:done()
	end,
})

event({
	id = "townpicnic",
	when = "day",
	weight = W({ base = 0.08, count = 3, weather = { "clear", "blossom" } }),
	scene = function(ctx)
		local s = K.scene(ctx, "A picnic on the hill")
		s:prop("picnic")
		s:n("Somebody put a blanket out on the hill, and then everybody did.")
		s:n("By two o'clock the whole slope was blankets, sandwiches and people lying flat.")
		for i = 1, #ctx.present do
			for j = i + 1, #ctx.present do
				s:fx({ t = "relv", a = ctx.present[i], b = ctx.present[j], d = 2 })
			end
		end
		s:all(3)
		s:log("The whole town had a picnic on the hill.")
		return s:done()
	end,
})

event({
	id = "glowsea",
	actors = 2,
	when = "night",
	weight = W({ base = 0.1, season = { 2, 3 }, weather = { "clear", "cloudy" } }),
	scene = function(ctx, a, b)
		local s = K.scene(ctx, "The glowing sea")
		s:n("Down on the beach every wave is glowing blue as it breaks, and {a} and {b} are at the water's edge.")
		burst(s, "a", {
			dreamy = "Hmm... it's like the sea's lit up from the inside.",
			bookish = "It's tiny creatures in the water.|They glow when the waves stir them up.",
			dramatic = "The sea is FULL of stars!",
			cool = "...Huh. I've never seen that before.",
			gloomy = "I've lived here for years and never seen this.",
			sunny = "{player}, come here, you have to see this!",
			proud = "I always said this was the best beach on the island.|Look at it.",
			polite = "Oh, how extraordinary.|Have you ever seen anything like it?",
			gentle = "Oh, my, look at the water.",
			cheeky = "kick the water, go on, it glows",
			_ = "Look, the waves are glowing!",
		}, "sparkle", "point")
		burst(s, "b", {
			nervous = "I-is it safe to touch?|It's safe, right?",
			prickly = "Okay, that's... fine.|It's very good, fine.",
			foodie = "It looks like those blue sweets they sell at the fair.",
			polite = "Thank you for bringing me down here.|It's lovely.",
			shy = "Oh... wow.",
			_ = "I didn't know the sea could do that.",
		}, "heart")
		s:n("They stayed until the tide went out, kicking at the water to make it glow.")
		s:rel(8)
		s:mood("a", 4)
		s:mood("b", 4)
		s:log("{a} and {b} watched the sea glow at night.")
		return s:done()
	end,
})

event({
	id = "skating",
	actors = 2,
	when = "day",
	weight = W({ base = 0.2, weather = "snow" }),
	scene = function(ctx, a, b)
		local s = K.scene(ctx, "On the ice")
		s:n("The duck pond froze solid overnight, and {a} is out in the middle while {b} holds on to the edge.")
		burst(s, "a", {
			bold = "Let go of the side, it's easy, look.",
			sunny = "Come on, it's so much fun!|{player}, tell them!",
			proud = "Watch this, a full turn.|...Well, nearly a full turn.",
			cheeky = "i'm going to spin you|hehe",
			dramatic = "Look, I glide like a SWAN!",
			_ = "Come on, let go.|I've got you.",
		}, "sparkle", "wave")
		burst(s, "b", {
			nervous = "What if it cracks?|Oh no, what if I fall and it cracks?",
			prickly = "I'm fine here, the side and I are friends.",
			gloomy = "I'm going to fall, I just know it.",
			cool = "...I'm good here, thanks.",
			shy = "Um... maybe in a minute.",
			proud = "I'm simply resting.|I could skate if I wanted to.",
			dramatic = "I shall stay here and admire you from the side!",
			_ = "I'm fine here, really.",
		}, "sweat")
		s:choice("A gentle push?", function(c)
			c:n("{b} slid all the way across the pond with their arms out and stopped against {a}.")
			burst(c, "b", {
				nervous = "I-I'm alive!|Can we do that again?",
				prickly = "That was terrifying.|...Do it again.",
				cheeky = "again, again",
				gloomy = "I didn't fall over, which is a first.",
				shy = "...!|That was actually fun.",
				cool = "...Again.",
				dreamy = "Hmm... it felt like flying.",
				proud = "Th-that was entirely on purpose.|...Again.",
				dramatic = "I FLEW, {player}!",
				_ = "Okay, that was really fun.",
			}, "laugh", "laugh")
			c:rel(6)
			c:mood("b", 4)
		end)
		s:choice("Take your time.", function(c)
			c:n("After ten minutes {b} let go of the side, grabbed it again, and then let go for good.")
			burst(c, "b", "Okay, okay, I'm doing it!", "sparkle")
			c:rel(4)
			c:mood("b", 3)
		end)
		s:log("{a} and {b} went skating on the frozen pond.")
		return s:done()
	end,
})

event({
	id = "ducksdelivery",
	when = "day",
	weight = W({ base = 0.07, count = 1 }),
	scene = function(ctx)
		local s = K.scene(ctx, "A delivery")
		s:prop("parcels")
		s:n("A delivery came for the town hall with three hundred rubber ducks in it, but the order was for three.")
		s:choice("In the fountain they go.", function(c)
			c:n("Every duck went in the fountain, and people have been standing round it all afternoon.")
			c:all(3)
		end)
		s:choice("Send them back.", function(c)
			c:n("They went back on the ferry, but one got left behind on the step, and it's still there.")
			c:all(1)
		end)
		s:log("Three hundred rubber ducks arrived by mistake.")
		return s:done()
	end,
})

event({
	id = "bench",
	actors = 1,
	when = "day",
	weight = W({ base = 0.06, count = 3 }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "A new bench")
		s:n("There's a new bench by the harbour, and {a} is standing next to it, waiting for you.")
		burst(s, "a", {
			sunny = "{player}, come here, come here!|Look at the little sign!",
			gentle = "We all put a few coins in for it.|Have a look at the plaque, {player}.",
			bold = "Go on, read the plaque.",
			dreamy = "It's got the best view of the boats...|Read the little sign.",
			easygoing = "Sit down and try it, it's a good bench.|Then read the plaque, no rush.",
			proud = "It was my idea, mostly.|Go on, read the plaque.",
			shy = "Um, it's for you, {player}...|Could you read the plaque?",
			cheeky = "it's a bench, a very normal bench|read the plaque, hehe",
			cool = "Read the plaque.",
			prickly = "Everyone chipped in, and it wasn't my idea.|Just read it.",
			dramatic = "A monument for you, {player}!|Well, a bench, but read the plaque!",
			bookish = "It's oak, so it'll last fifty years if it's oiled.|Read the plaque.",
			gloomy = "It's a nice bench, and you deserve a nice bench.|Read the plaque.",
			polite = "We hoped you'd like it, {player}.|There's a plaque, if you'd care to read it.",
			foodie = "It's the perfect bench for lunch.|Read the plaque, and then we can eat.",
			nervous = "D-do you like it?|Read the plaque first, then tell me.",
			_ = "Read the plaque, {player}.",
		}, "heart", "point")
		s:n("The plaque says 'For {player}, who built this place.'")
		s:hearts("a", 1)
		s:all(2)
		s:log("The town put up a bench by the harbour with your name on it.")
		return s:done()
	end,
})

-- a favour for the town, and the day after a storm ------------------------------------------------

event({
	id = "harbourwall",
	actors = 1,
	when = "day",
	weight = W({ base = 0.1, traits = { brave = 0.3, social = 0.2 } }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "The harbour wall")
		s:prop("bricks", "a")
		burst(s, "a", {
			bold = "{player}, you're free this afternoon, right?|Good, because the harbour wall's lost some stones and I said we'd fix it.",
			sunny = "{player}, {player}!|The harbour wall's got a hole in it, so come and help me fix it!",
			gentle = "{player}, are you free later?|There's a gap in the harbour wall, and I'd feel better if it was mended.",
			proud = "{player}, the harbour wall needs mending, and naturally I volunteered.|You can be my assistant.",
			cool = "{player}. The harbour wall has a gap in it.|Can you help me fix it?",
			prickly = "The harbour wall's falling apart, and nobody else is fixing it.|So it's you and me, okay?",
			polite = "Excuse me, {player}.|The harbour wall needs a few stones replaced, if you could lend a hand.",
			nervous = "Um, {player}? There's a gap in the harbour wall.|What if a boat hits it?|C-could you help me fix it?",
			_ = "{player}, are you free?|The harbour wall's lost a few stones, and I need help putting them back.",
		}, "idea", "point")
		-- the afternoon itself, whichever way you answered
		local function mended(c)
			c:n(
				"Two hours and a lot of heavy stones later, the gap was gone, and a gull sat on the new bit straight away."
			)
			burst(c, "a", {
				bold = "Not bad at all.|Lunch is on me, and I always pay back.",
				prickly = "That's done.|...You were useful, so I'm buying lunch, but don't get used to it.",
				cool = "Good work. Thanks.|Lunch is on me.",
				gloomy = "It'll hold for a while, anyway.|Thanks, {player}, I'll get us some lunch.",
				proud = "Excellent work, most of it mine.|You did well too, so you've earned lunch.",
				_ = "All done, thanks, {player}.|Let's go and get some lunch, my treat.",
			}, "heart")
		end
		s:choice("Will there be lunch after?", function(c)
			burst(c, "a", {
				bold = "Hah, if the wall holds, lunch is on me.",
				cheeky = "if you carry the heavy ones, maybe",
				proud = "Lunch is for people who work hard, so we'll see.",
				foodie = "Of course there's lunch, I packed it this morning.",
				_ = "There will be if you bring gloves.",
			}, "laugh")
			mended(c)
		end)
		s:choice("I'll bring gloves.", function(c)
			burst(c, "a", {
				bold = "I knew you'd say that.",
				sunny = "Yes, I knew you'd say yes!",
				shy = "...!|Thank you.",
				_ = "Good, I'll see you down there.",
			}, "sparkle", "cheer")
			mended(c)
		end)
		s:hearts("a", 1)
		s:mood("a", 4)
		s:all(2)
		s:memo("a", "The harbour wall's still holding, so we did good work there.")
		s:log("You and {a} mended the harbour wall.")
		return s:done()
	end,
})

event({
	id = "afterstorm",
	actors = 1,
	when = "day",
	weight = W({ base = 0.12, weather = { "storm", "rain" }, traits = { brave = -0.3, kind = 0.2 } }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "After the storm")
		s:n("{a} comes round to check on you, still in their storm boots.")
		burst(s, "a", {
			nervous = "S-sorry, {player}, can I ask you something?|Is your roof okay after the storm?|I heard a bang last night and thought it was your house.",
			gentle = "{player}, are you all right?|That wind was awful, and I couldn't sleep for thinking about everyone's roofs.",
			bold = "{player}, did your roof hold up?|I've got a ladder if it didn't.",
			sunny = "{player}, you're okay!|That storm was so loud, did you hear the bins rolling down the street?",
			gloomy = "Your house is still standing, good.|I was sure something would blow away.",
			cool = "{player}. Is your roof okay?",
			polite = "Hello, {player}, I do hope I'm not intruding.|Did your house come through the storm all right?",
			prickly = "You're fine, then, good.|I wasn't worried, I was passing anyway.",
			cheeky = "you survived, nice|that storm was wild",
			_ = "{player}, are you okay?|That was quite a storm.",
		}, "question")
		s:choice("We're fine, a bin lid blew off.", function(c)
			burst(c, "a", {
				nervous = "A bin lid, oh, good.|I'm going to go and lie down now.",
				gloomy = "A bin lid?|Heh... okay, good.",
				sunny = "A bin lid, ehehe!|I chased one down the street at midnight!",
				_ = "Just a bin lid, then, good.",
			}, "heart")
			c:mood("a", 3)
		end)
		s:choice("Were you up all night?", function(c)
			burst(c, "a", {
				nervous = "M-most of it, sorry.|I'll have a nap later, I promise.",
				prickly = "No.|...Well, a bit, but don't tell anyone.",
				cool = "Some of it. I'm fine.",
				gentle = "A little, but I'll rest later, so don't worry.",
				_ = "A bit, but I'll catch up on sleep later.",
			}, "zzz")
			c:hearts("a", 1)
			c:mood("a", 2)
		end)
		s:log("{a} came round to check on you after the storm.")
		return s:done()
	end,
})

return list
