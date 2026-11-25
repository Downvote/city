--!nonstrict
-- The whole town: a power cut, talent night, a parade, market day, a tour bus, a sculpture that
-- turns up overnight, a lost dog, a busker, quiz night, fireworks, a clean up, the seasons and
-- the weather, the ferry, lanterns on the harbour, a snowball fight. Most star the villager who
-- noticed first (so the bubbles and props have somewhere to be); the good they do usually
-- reaches everybody around. Narration stays plain; the villagers talk the way a friend texts
-- you, in short bursts of two or three messages, and call you by name ({player}).

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
	sunny = "Me? ME?|Thank you thank you!",
	proud = "Of course.|I accept this with grace.",
	bold = "Hah.|Knew it.",
	shy = "...!|Me?|Thank you...",
	cheeky = "the judge has taste|hehe",
	cool = "...Huh.|Thanks.",
	prickly = "Obviously.|...Thanks.",
	dramatic = "VICTORY!|I'd like to thank the gulls.",
	bookish = "Oh. I didn't expect that.|Thank you.",
	gloomy = "I won?|Something's wrong.|...Thanks.",
	gentle = "Oh, my.|Thank you, {player}.",
	dreamy = "Oh.|I won.|That's nice.",
	easygoing = "Heh.|Didn't even try.",
	polite = "Thank you, {player}.|That's very kind.",
	foodie = "Is there a prize?|Can you eat it?",
	nervous = "M-me?|Are you sure?|Oh. Thank you!",
	_ = "Me?|Thanks, {player}.",
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
		s:voice("b", "scared", "sweat")
		burst(s, "a", {
			bold = "Nobody panic. I've got candles. Somewhere.|Ow. That's a table.",
			gentle = "Here, I've got a lantern.|Sit with me till it comes back.",
			cheeky = "oooOOOooo|I'm a ghost|ok ok I've got a lantern",
			sunny = "{player}? Over here! I've got a lantern!|Follow the light!",
			cool = "Lantern.|Here.",
			prickly = "Stop bumping into things.|...Here. Lantern. Don't say thanks.",
			dramatic = "Darkness falls! But fear not.|I have a lantern!",
			bookish = "It'll be the main line by the harbour.|It went last winter too.",
			gloomy = "Knew this would happen.|I keep a lantern ready. For nights like this.",
			polite = "Is everyone all right?|Please, come and sit by my lantern.",
			foodie = "My fridge. ...Okay. Lantern first.|Then we eat what's in the fridge.",
			nervous = "Is it just us? Is it everyone?|Okay. Lantern. I have a lantern.",
			_ = "Hang on, {player}.|I've got a lantern in here somewhere.",
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
	easygoing = "balances a spoon on their nose for ages",
	proud = "does a dramatic speech from a play nobody's heard of",
	shy = "plays a quiet little tune on a whistle, eyes shut",
	cheeky = "pulls a coin from behind everyone's ear, then keeps the coins",
	cool = "solves a puzzle box without looking at it, then walks off",
	prickly = "sings one song very well, scowling the whole way through",
	dramatic = "acts out the whole history of the town in four minutes",
	bookish = "names every bird on the island from its call",
	gloomy = "tells a ghost story so sad that people clap slowly",
	polite = "bows, thanks the judges, and juggles three teacups",
	foodie = "eats a whole lemon without making a face",
	nervous = "builds a card tower, very slowly, while everyone holds their breath",
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
		s:n("It's talent night in the square. Three acts. You're the judge.")
		for _, who in { "a", "b", "c" } do
			local vid = ctx.stars[who]
			s:with({ act = TALENTS[K.pers(ctx, vid)] or "does something nobody can describe" })
			s:n("{" .. who .. "} {act}.")
		end
		for _, who in { "a", "b", "c" } do
			s:choice("{" .. who .. "}.", function(ch)
				burst(ch, who, WINNER, "sparkle", "cheer")
				ch:mood(who, 8)
				ch:hearts(who, 1)
				ch:memo(who, "I won talent night. The trophy's on my pillow.")
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
		s:n("Somebody decided today was a parade. Nobody knows who. There's a drum and a lot of balloons.")
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
		s:n("Stalls went up all along the square this morning. One man is selling a single, very large cabbage.")
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
		s:n("A tour bus pulled up by the harbour and forty people in sun hats got off.")
		if city.value > 15000 then
			s:n("They took pictures of everything. One of them took a picture of a bin.")
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
		s:n("When the town woke up, there was a big stone snail in the square. Nobody saw it arrive.")
		s:n("Everyone is standing round it with their heads on one side.")
		s:choice("It stays.", function(c)
			c:n("The snail stays. Somebody's already put a hat on it.")
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
				c:n("It was {x}. It took them three nights and a wheelbarrow.")
				c:n("{x} says it's called 'Slow Down'. Nobody can tell if that's a joke.")
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
			gentle = "{player}, he's lost, the poor thing.|There's a tag. 'Biscuit'.",
			bold = "New best friend.|Biscuit. Says so on the tag.",
			shy = "Um, {player}...|he keeps sitting on my feet.|I don't mind.",
			sunny = "{player}! Look who found me! His name's Biscuit!",
			cool = "{player}.|Dog. Tag says Biscuit.|Someone's missing him.",
			prickly = "He won't leave me alone.|...I gave him some water. Whatever.",
			dramatic = "A lost soul, {player}!|We must find his family.",
			bookish = "The tag has a farm name on the back.|Over the hill, I think.",
			gloomy = "Someone's out there looking for him.|I hope they find him.",
			polite = "Excuse me, does anyone know this dog?|He's called Biscuit.",
			foodie = "He's called Biscuit. I like him already.",
			nervous = "What if nobody comes?|What if he's been lost for days?",
			cheeky = "I have a dog now|his name is biscuit|he's not mine. technically",
			_ = "{player}, his tag says Biscuit.|Somebody must be missing him.",
		}, "heart")
		s:choice("Let's put up posters.", function(c)
			c:n("An hour after the posters went up, a farmer from over the hill came running.")
			c:n("Biscuit nearly knocked him over. He gave {a} a jar of honey and the town a reward.")
			c:coins(40)
			c:mood("a", 6)
			c:memo("a", "Biscuit the dog went home. I miss him a bit.")
		end)
		s:choice("Keep him for the afternoon?", function(c)
			c:n("{a} and Biscuit spent the afternoon on the beach. Then the owner turned up at teatime.")
			burst(c, "a", {
				bold = "See you, Biscuit. Be good.",
				shy = "Bye, Biscuit...",
				cheeky = "if you ever get lost again|get lost here",
				cool = "Bye, dog.",
				prickly = "Go on. Go home. ...Bye, Biscuit.",
				dramatic = "Farewell, Biscuit! I shall never forget you.",
				_ = "Bye, Biscuit. Come and visit.",
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
		s:n("The summer fete is on. There's a cake stall and a game where you throw wet sponges at a volunteer.")
		local who = bystander(ctx)
		if who then
			s:with({ x = ctx.v(who).name })
			s:n("{x} volunteered. {x} regrets it.")
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
		s:n("Everybody came out to look. A few are trying to catch it on their tongues.")
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
		s:n("There were eleven pies. Nobody planned that.")
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
		s:n("It's the hottest day of the year. The whole town is down on the beach.")
		s:n("The ice cream ran out by noon. Somebody's dog is lying in the fountain.")
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
			s:n("Then {x} opened a window and put some music on, loud. People started humming along.")
			s:fx({ t = "moodv", vid = who, d = 3 })
		end
		s:all(1)
		s:log("A grey day, but someone put music on.")
		return s:done()
	end,
})

event({
	id = "comet",
	when = "night",
	weight = W({ base = 0.05, weather = "clear", count = 1 }),
	scene = function(ctx)
		local s = K.scene(ctx, "A comet")
		s:n("There's a comet in the sky tonight. You can see its tail from the hill.")
		s:n("The whole town is out on the hill in dressing gowns. Nobody says much.")
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
		s:n("{a} sat down by the harbour with a bag of chips. A gull landed on the bench.")
		s:n("Then another. Then nine more.")
		burst(s, "a", {
			bold = "Back.|BACK. ...Fine. They're yours.",
			gentle = "Oh, all right. One each.|Form a line.",
			cheeky = "I'm one of you now|caw|caw",
			proud = "Do you know who I am?|...Apparently you don't care.",
			sunny = "{player}! Help! They're everywhere!",
			cool = "...Keep them.",
			prickly = "These are MY chips.|Mine. ...Fine. One. ONE.",
			dramatic = "Betrayed! By the birds of my own harbour!",
			bookish = "Gulls remember faces, actually. They'll be back tomorrow.",
			gloomy = "Of course.|Of course they did.",
			polite = "Excuse me. Those are...|oh. All right then.",
			foodie = "Not the chips. Anything but the chips.",
			nervous = "Too many. There are too many.|{player}, how many is too many?",
			_ = "My chips. {player}, my lovely chips.",
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
		s:n("A mother duck and seven ducklings are crossing the main road. Very slowly.")
		s:n("The bus stopped to wait. Somebody held up a sign that said 'DUCKS'.")
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
		s:n("A big striped hot air balloon drifted over town this afternoon.")
		s:n("The people in the basket waved. Everybody waved back. It went on for quite a long time.")
		s:all(3)
		s:log("A hot air balloon drifted over town.")
		return s:done()
	end,
})

local QUESTIONS = {
	{ "How many legs does a crab have?", "Ten" },
	{ "What colour is a polar bear's skin?", "Black" },
	{ "Which way does the sun come up?", "East" },
	{ "How many stripes on the town flag?", "Nobody knows" },
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
		local s = K.scene(ctx, "Quiz night"):with({ q = q[1], ans = q[2] })
		s:n("It's quiz night. {a} and {b} are a team. They've called themselves 'Quiz Team'.")
		s:n("Last question. {q}")
		s:voice("a", "hmm", "question")
		if ctx.rng:chance(0.5) then
			s:say("b", "{ans}.", "idea", "point")
			s:n("Right answer. Quiz Team wins a tin of biscuits.")
			burst(s, "a", WINNER, "sparkle", "cheer")
			s:mood("a", 4)
			s:mood("b", 4)
		else
			burst(s, "b", "Seven?|...Seven. Final answer.", "question")
			s:n("It was {ans}. Quiz Team came second. Out of two.")
			s:voice("a", "laugh", "laugh")
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
		s:n("A small crowd has gathered. Some people are swaying.")
		s:choice("Tip them (20 coins)", function(c)
			c:n("The busker played one more, just for the town, and tipped their hat.")
			c:coins(-20)
			c:all(3)
		end, 20)
		s:choice("Just listen.", function(c)
			c:n("You stood at the back and listened till the last song.")
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
		s:n("Fireworks over the harbour. Nobody knows who set them off. Nobody minds.")
		s:n("Mostly big gold ones. One went sideways into the sea.")
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
			s:n("{x} found a teapot in a hedge. They're keeping it.")
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
		s:n("This morning, you saw who it was. {a}, with a basket, before sunrise.")
		burst(s, "a", {
			shy = "...!|Please don't tell anyone.|It's nicer if nobody knows.",
			proud = "Well. Someone had to make this town beautiful.",
			cheeky = "act natural|ACT NATURAL",
			sunny = "{player}!|Shh! You didn't see me!",
			cool = "...You saw nothing, {player}.",
			prickly = "Don't, {player}. Don't say anything.|It's just flowers.",
			dramatic = "My secret is out! To you alone, {player}.",
			gloomy = "People seemed sad.|Flowers help. A bit.",
			polite = "Good morning, {player}.|I hope you don't mind. I wanted to do something kind.",
			nervous = "You won't tell?|Promise? Okay. Okay.",
			_ = "Shh. It's better as a secret.",
		}, "heart")
		s:choice("Your secret's safe.", function(c)
			burst(c, "a", {
				shy = "Thank you, {player}.|Here.|This one's yours.",
				cheeky = "good|here's yours then|act natural",
				prickly = "...Good. Here. Take one.|Don't make a thing of it.",
				_ = "Thank you, {player}. Here, have one too.",
			}, "heart")
			c:hearts("a", 2)
			c:all(2)
		end)
		s:choice("Everyone should know.", function(c)
			c:n("The whole town clapped {a} at lunch.")
			burst(c, "a", {
				shy = "I'm going to hide for a week.",
				proud = "Well. About time somebody noticed.",
				bold = "Hah. Okay. Yes. It was me.",
				cool = "...Okay.|Yes. Me.",
				dramatic = "Yes! It was I!",
				_ = "Oh, stop. ...Don't stop.",
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
		s:n("It's the first day of spring, and the town's birthday. Somebody's made a cake the size of a table.")
		s:n("Everyone sang happy birthday to the town. It was very loud.")
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
		s:n("Somebody shouted from the pier. There's a whale out past the harbour.")
		s:n("Everybody ran to look. It blew a spout of water and rolled over, flapping one fin.")
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
		s:voice("a", "scared", "sweat")
		s:n("{a} crept out with a torch. It was a hedgehog, eating the cat's dinner.")
		burst(s, "a", {
			gentle = "Oh, look at you. Eat up, little one.",
			bold = "Hah. You gave me a fright, mate.",
			shy = "Oh.|Hello.|You scared me...",
			cheeky = "caught you|that's the cat's, you know",
			cool = "Hm.|Carry on.",
			prickly = "You. All night.|...Fine. Finish it.",
			dramatic = "The beast of the garden!|...Is tiny. And sweet.",
			bookish = "Hedgehogs walk about two kilometres a night.|He's earned it.",
			gloomy = "At least something's eating well tonight.",
			polite = "Oh, pardon me. Please, go on.",
			foodie = "The cat's dinner is chicken. Good choice, hedgehog.",
			nervous = "Oh, thank goodness. A hedgehog.|Only a hedgehog.",
			_ = "Well. Mystery solved, {player}.",
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
		s:n("A thick sea mist rolled in off the water. You can't see the end of the street.")
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
		s:n("The ferry came in this morning with a crate of oranges for every house in town. Nobody ordered them.")
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
		s:n("The foghorn on the harbour went off at three in the morning. There's no fog.")
		s:n("{a} came out in a dressing gown and one slipper.")
		burst(s, "a", {
			sunny = "{player}? Is that you?|Did you hear it too?",
			gentle = "Is everyone all right? Nobody's lost out there?",
			bold = "Right. Who did it.|Come out.",
			dreamy = "Maybe a boat|was saying goodnight.",
			easygoing = "I was having such a good sleep...",
			proud = "I'll be writing to the harbour about this.",
			shy = "I thought it was in my room...",
			cheeky = "wasn't me|for once",
			cool = "...Three in the morning.",
			prickly = "Whoever did that owes me a whole night.",
			dramatic = "A cry from the sea! At this HOUR.",
			bookish = "It's on a timer, actually.|Someone's set it wrong.",
			gloomy = "Great. I'm up now.|For good.",
			polite = "Terribly sorry. Has anyone seen my other slipper?",
			foodie = "I'm up. Might as well have toast.",
			nervous = "Is it a ship? Is something wrong?|Should we do something?",
			_ = "{player}?|What was that? It's three in the morning.",
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
		s:n("There's a red one, a fish shaped one, and one that's mostly a bin bag.")
		local who = bystander(ctx)
		if who then
			s:with({ x = ctx.v(who).name })
			s:n("{x}'s kite got the highest. They're telling everyone about it.")
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
		s:n("{a} and {b} each made a toy boat and set them off from the harbour steps. You're the judge.")
		burst(s, "a", {
			proud = "Mine has a proper keel.|Watch it go, {player}.",
			bold = "Mine's faster. Obviously.|Look at it.",
			sunny = "{player}, cheer for mine!|The one with the red sail!",
			cool = "Mine's the blue one.",
			dramatic = "Sail, little ship! Sail for glory!",
			bookish = "I gave it a longer hull.|That should make it quicker, in theory.",
			nervous = "It's leaning. Is it meant to lean?|It's leaning a lot.",
			_ = "Come on, come on. Go, boat.",
		}, "sparkle", "point")
		burst(s, "b", {
			cheeky = "I put a pebble in the back of yours|kidding|maybe",
			gentle = "Oh, look at them both.|They're doing so well.",
			shy = "Mine's...|going sideways.|That's fine.",
			prickly = "Mine's winning. Don't argue, {player}. Just judge.",
			gloomy = "Mine's going to sink.|Any moment. ...Still going.",
			foodie = "I made mine from a lunch box.|It still smells of cheese.",
			_ = "Mine's catching up. Look.",
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
		s:choice("A draw.", function(c)
			c:n("Then a gull landed on both boats at once, which settled it.")
			c:say("a", "...Fair.", "laugh")
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
		s:n("They drifted out slowly, all in a line. Nobody spoke till the last one went round the point.")
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
		s:n("{a} has a table at the market with jars of jam on it. {b} has been holding the same jar for five minutes.")
		burst(s, "b", {
			cheeky = "two coins|final offer|ok three. final final",
			proud = "I'll give you a fair price.|Which is half.",
			foodie = "Is it plum? It's plum.|How much for two? How much for all of them?",
			bookish = "The label says 'strawbery', you know.|That should knock a coin off.",
			nervous = "Is it okay if I just...|look? For a bit longer?",
			polite = "Might I ask the price?|Only if it's no trouble.",
			_ = "How much for this one?",
		}, "question")
		burst(s, "a", {
			bold = "Five. Not a coin less.",
			gentle = "Oh, have it. I made too many anyway.",
			cool = "Four.",
			prickly = "It's four. It says four.|Right there. Four.",
			dramatic = "That jar took a whole summer!|A WHOLE summer.",
			gloomy = "Nobody's bought one all day.|Take it for two.",
			sunny = "For you? Three!|And a taste of the gooseberry!",
			_ = "Four coins. It's the good stuff.",
		}, "sparkle")
		s:n("They settled on three coins and a spoon to try the gooseberry.")
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
		s:n("At noon the town clock struck thirteen times. Everyone in the square counted along.")
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
		s:n("By lunch half the town was on the pier, whispering.")
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
			bookish = "{player}.|There's a first edition of a bird book in here. A FIRST EDITION.",
			sunny = "There's so many!|Which one should I take, {player}?",
			dreamy = "This one's about a lighthouse.|I'm taking the lighthouse.",
			cool = "Found a good one.",
			prickly = "Half of these are terrible. ...I'm taking two.",
			dramatic = "A treasure chest! Of STORIES.",
			gloomy = "They're all sad ones. Good.|I'll take this one.",
			foodie = "Cookbook.|Cookbook. Another cookbook. Yes.",
			nervous = "Can I take one if I haven't brought one yet?|I'll bring one. I will.",
			_ = "{player}, look.|There's a cookbook in here from before I was born.",
		}, "sparkle")
		s:choice("I'll leave one of mine.", function(c)
			c:n("You put in an old book about boats. {a} took it out again straight away.")
			burst(c, "a", "I'll swap you. Here.", "heart")
			c:mood("a", 4)
			c:hearts("a", 1)
		end)
		s:choice("You pick first.", function(c)
			burst(c, "a", "Okay. This one.|No. This one.", "question")
			c:mood("a", 3)
			c:memo("a", "I got a book from the box by the fountain. I'm putting it back when I'm done.")
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
		s:n("Down on the beach, every wave that breaks is glowing blue. {a} and {b} are at the water's edge.")
		burst(s, "a", {
			dreamy = "The sea's lit up|from the inside...",
			bookish = "It's tiny creatures in the water.|They glow when the waves move them.",
			dramatic = "The sea is full of stars!",
			cool = "...Huh.",
			gloomy = "I've lived here years and never seen this.",
			sunny = "{player}, come here! You have to see this!",
			_ = "Look at the waves. Look at them.",
		}, "sparkle", "point")
		burst(s, "b", {
			nervous = "Is it safe? It's safe, right?|Can I touch it?",
			prickly = "Okay. That's...|fine. It's very good. Fine.",
			foodie = "It looks like the blue sweets|they sell at the fair.",
			polite = "Thank you for bringing me down here.|It's lovely.",
			shy = "Oh...|wow.",
			_ = "I didn't know it could do that.",
		}, "heart")
		s:n("They stayed till the tide went out, kicking at the water to make it glow.")
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
		s:n("The duck pond froze solid overnight. {a} is out in the middle of it. {b} is holding on to the edge.")
		burst(s, "a", {
			bold = "Let go of the side.|It's easy. Look.",
			sunny = "Come on! It's so much fun!|{player}, tell them!",
			proud = "Watch. A full turn. ...Nearly a full turn.",
			cheeky = "I'm going to spin you|hehe",
			dramatic = "I glide like a swan!",
			_ = "Come on. Let go.|I've got you.",
		}, "sparkle", "wave")
		burst(s, "b", {
			nervous = "What if it cracks?|What if I fall? What if both?",
			prickly = "I'm fine here. The side is my friend.",
			gloomy = "I'm going to fall.|I know I'm going to fall.",
			cool = "...I'm good here.",
			shy = "Um.|Maybe in a minute...",
			_ = "I'm fine here. Really.",
		}, "sweat")
		s:choice("A gentle push?", function(c)
			c:n("{b} slid all the way across the pond with their arms out and stopped against {a}.")
			c:voice("b", "laugh", "laugh", "laugh")
			c:rel(6)
			c:mood("b", 4)
		end)
		s:choice("Take your time.", function(c)
			c:n("{b} let go of the side after ten minutes. Then held on again. Then let go.")
			burst(c, "b", "Okay.|Okay. I'm doing it.", "sparkle")
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
		s:n("A delivery came for the town hall. Three hundred rubber ducks. The order was for three.")
		s:choice("In the fountain they go.", function(c)
			c:n("Every duck went in the fountain. People have been standing round it all afternoon.")
			c:all(3)
		end)
		s:choice("Send them back.", function(c)
			c:n("They went back on the ferry. One got left behind on the step. It's still there.")
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
		s:n("There's a new bench by the harbour. {a} is standing next to it, waiting for you.")
		burst(s, "a", {
			sunny = "{player}! Come here! Look at the little sign!",
			gentle = "We all put a few coins in.|Have a look at the plaque, {player}.",
			bold = "Read the plaque. Go on.",
			dreamy = "It's got the best view of the boats.|Read the little sign.",
			easygoing = "Sit down. Try it. It's a good bench.|Then read the plaque.",
			proud = "It was my idea.|Mostly. Read the plaque.",
			shy = "Um. It's for you, {player}...|read the plaque.",
			cheeky = "it's a bench|very normal|read the plaque. hehe",
			cool = "Read the plaque.",
			prickly = "Everyone chipped in.|It was not my idea. Read it.",
			dramatic = "A monument, {player}! Well. A bench.|Read the plaque!",
			bookish = "Oak. It'll last fifty years if it's oiled.|Read the plaque.",
			gloomy = "It's a nice bench.|You deserve a nice bench. Read it.",
			polite = "We hoped you'd like it, {player}.|There's a plaque, if you'd care to read it.",
			foodie = "It's the perfect lunch bench.|Read the plaque, then we eat.",
			nervous = "Do you like it? Read the plaque.|Do you like it?",
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
			bold = "{player}. You're free this afternoon, right?|Good. The harbour wall's lost some stones.|I said we'd fix it.",
			sunny = "{player}! {player}! The harbour wall's got a hole!|Come help? It'll be fun! Mostly!",
			gentle = "{player}, are you free later?|The harbour wall has a gap. I'd feel better if it was mended.",
			proud = "{player}. The harbour wall needs mending.|I volunteered. Naturally. You can be my assistant.",
			cool = "{player}.|Wall's got a gap.|Help me fix it?",
			prickly = "The harbour wall's falling apart.|Nobody else is doing it.|So you and me. Fine?",
			polite = "Good afternoon, {player}. The harbour wall needs a few stones replaced.|Might you lend a hand?",
			nervous = "Um, {player}?|There's a gap in the harbour wall.|What if a boat hits it? Could you help?",
			_ = "{player}. You free?|The harbour wall's lost a few stones.|Help me put them back?",
		}, "idea", "point")
		-- the afternoon itself, whichever way you answered
		local function mended(c)
			c:n("Two hours and a lot of heavy stones later, the gap was gone. A gull sat on the new bit straight away.")
			burst(c, "a", {
				bold = "Not bad.|Lunch is on me. I always pay back.",
				prickly = "That's done.|...You were useful. Don't get used to me saying it.",
				cool = "Good work.|...Thanks.",
				gloomy = "It'll hold. For a while, anyway.|Thanks, {player}.",
				proud = "Excellent work. Mine, mostly.|Yours too. You've earned lunch.",
				_ = "Done. Thanks, {player}. Same time next storm?",
			}, "heart")
		end
		s:choice("Who's 'we'?", function(c)
			burst(c, "a", {
				bold = "You and me. Keep up.",
				cheeky = "you|and me|mostly you",
				proud = "Me, overseeing. You, lifting.",
				_ = "You and me. Bring gloves.",
			}, "laugh")
			mended(c)
		end)
		s:choice("I'll bring gloves.", function(c)
			burst(c, "a", {
				bold = "Knew it.",
				sunny = "Yes! Knew you'd say yes!",
				shy = "...!|Thank you.",
				_ = "Good. See you down there.",
			}, "sparkle", "cheer")
			mended(c)
		end)
		s:hearts("a", 1)
		s:mood("a", 4)
		s:all(2)
		s:memo("a", "The harbour wall's still holding. We did good work there.")
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
		s:n("{a} comes round first thing, still in their boots.")
		burst(s, "a", {
			nervous = "S-sorry, {player}, can I ask something? Sorry.|The storm last night. Is your roof okay?|I heard a bang and thought it was your house.",
			gentle = "{player}, you're all right? That wind was awful.|I couldn't sleep for thinking about everyone's roofs.",
			bold = "{player}.|Roof hold up?|I've got a ladder if it didn't.",
			sunny = "{player}! You're okay! That storm was HUGE!|Did you hear the bins?",
			gloomy = "Your house is still there. Good.|I was sure something would blow away.",
			cool = "{player}.|Roof okay?",
			polite = "Good morning, {player}. I do hope I'm not intruding.|Did your house come through the storm all right?",
			prickly = "You're fine, then. Good.|I wasn't worried. I was passing.",
			_ = "{player}. You okay? That was some storm.",
		}, "question")
		s:choice("All fine. It was a bin lid.", function(c)
			burst(c, "a", {
				nervous = "A bin lid. Oh.|Good. I'm going to go and lie down.",
				gloomy = "A bin lid. ...Huh. Okay. Good.",
				sunny = "A bin lid! Ha!|I chased one down the street at midnight!",
				_ = "A bin lid. Ha. Good.",
			}, "heart")
			c:mood("a", 3)
		end)
		s:choice("Were you up all night?", function(c)
			burst(c, "a", {
				nervous = "Most of it. Sorry.|I'll nap later. Promise.",
				prickly = "No. ...A bit.|Don't tell anyone.",
				cool = "Some.|It's fine.",
				gentle = "A little. I'll rest later, don't worry.",
				_ = "A bit. I'll catch up.",
			}, "zzz")
			c:hearts("a", 1)
			c:mood("a", 2)
		end)
		s:log("{a} came round to check on you after the storm.")
		return s:done()
	end,
})

return list
