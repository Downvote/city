--!nonstrict
-- The whole town: a power cut, talent night, a parade, market day, a tour bus, a sculpture that
-- turns up overnight, a lost dog, a busker, quiz night, fireworks, a clean up, the seasons and
-- the weather. Most star the villager who noticed first (so the bubbles and props have somewhere
-- to be); the good they do usually reaches everybody around.

local K = require(script.Parent.Kit)
local Tuning = require(script.Parent.Parent.Parent.Config.Tuning)

local W = K.W

local list = {}
local function event(def)
	def.actors = def.actors or 0
	table.insert(list, def)
end

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
		s:by("a", {
			bold = "Nobody panic. I've got candles. Somewhere. Ow, that's a table.",
			gentle = "Here, I've got a lantern. Sit with me till it comes back.",
			cheeky = "OooOOoo. I'm a ghost. Okay, okay, I've got a lantern.",
			_ = "Hang on. I've got a lantern in here somewhere.",
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
	shy = "plays a very quiet, very beautiful tune on a whistle",
	cheeky = "pulls a coin from behind everyone's ear, then keeps the coins",
}

event({
	id = "talentnight",
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
			s:choice("{" .. who .. "} wins", function(ch)
				ch:voice(who, "excited", "sparkle", "cheer")
				ch:mood(who, 8)
				ch:hearts(who, 1)
				ch:memo(who, "I won talent night. I've still got the trophy. It's on my pillow.")
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
		s:n("Stalls went up all along the square this morning: jam, socks, second hand books and a man selling just one very large cabbage.")
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
			s:n("They took pictures of everything. One of them took a picture of a bin. It's a nice bin.")
		else
			s:n("They looked around, bought every bun in the bakery and asked where the rest of the town was.")
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
		s:choice("Keep it", function(c)
			c:n("The snail stays. Somebody's already put a hat on it.")
			c:leave("sculpture", 24)
			c:all(3)
		end)
		s:choice("Find out who made it", function(c)
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
				c:n("{x} says it's called 'Slow Down'. Nobody's sure if it's art or a joke. It's probably both.")
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
		s:by("a", {
			gentle = "It's lost, the poor thing. It's got a tag. 'Biscuit'.",
			bold = "I've got a new best friend. Its name's Biscuit. It says so on the tag.",
			shy = "It keeps sitting on my feet. I don't mind.",
			_ = "Its tag says Biscuit. Somebody must be missing it.",
		}, "heart")
		s:choice("Put up posters", function(c)
			c:n("An hour after the posters went up, a farmer from over the hill came running.")
			c:n("Biscuit nearly knocked him over. He gave {a} a jar of honey and the town a reward.")
			c:coins(40)
			c:mood("a", 6)
			c:memo("a", "Biscuit the dog went home. I miss him a bit.")
		end)
		s:choice("Keep it for the afternoon", function(c)
			c:n("{a} and Biscuit spent the afternoon on the beach. Then the owner turned up at teatime.")
			c:say("a", "Bye, Biscuit. Come and visit.", "sad")
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
		s:n("The summer fete is on: a tombola, a cake stall, and a game where you throw wet sponges at a volunteer.")
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
		s:n("Snow is falling over the whole town, soft and quiet.")
		s:n("Everybody came outside at once to look up and catch it on their tongues.")
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
		s:n("There were eleven pies. Nobody planned it. Everyone just thought they'd bring a pie.")
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
		s:n("Grey sky, grey sea, a grey sort of mood over the town.")
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
		s:n("A comet is crossing the sky tonight, slow and bright, with a long pale tail.")
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
		s:by("a", {
			bold = "Back. BACK. These are mine. ...They're yours.",
			gentle = "Oh, all right. One each. Form a line.",
			cheeky = "I'm one of you now. Caw. Caw.",
			proud = "Do you know who I am? ...Apparently you don't care.",
			_ = "My chips. My lovely chips.",
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
		s:n("Everything stopped. The bus. The bikes. Somebody held up a sign that said 'DUCKS'.")
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
		s:n("Last question: {q}")
		s:voice("a", "hmm", "question")
		if ctx.rng:chance(0.5) then
			s:say("b", "{ans}.", "idea", "point")
			s:n("Right answer. Quiz Team wins a tin of biscuits.")
			s:voice("a", "excited", "sparkle", "cheer")
			s:mood("a", 4)
			s:mood("b", 4)
		else
			s:say("b", "Seven?", "question")
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
		s:n("A travelling busker set up in the square with a battered guitar and a voice like warm toast.")
		s:n("A small crowd has gathered. Some people are swaying.")
		s:choice("Tip them (20 coins)", function(c)
			c:n("The busker played one more, just for the town, and tipped their hat.")
			c:coins(-20)
			c:all(3)
		end, 20)
		s:choice("Just listen", function(c)
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
		s:n("Big gold ones, little crackly ones, and one that went sideways into the sea.")
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
		s:n("Everyone came out with a bag and a pair of gloves and tidied the whole town, from the hill to the beach.")
		local who = bystander(ctx)
		if who then
			s:with({ x = ctx.v(who).name })
			s:n("{x} found a shoe, a teapot and a very old love letter. They're keeping the teapot.")
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
		s:by("a", {
			shy = "Please don't tell anyone. It's nicer if nobody knows.",
			proud = "Well. Someone had to make this town beautiful.",
			cheeky = "Act natural. Act natural.",
			_ = "Shh. It's better as a secret.",
		}, "heart")
		s:choice("Keep their secret", function(c)
			c:say("a", "Thank you. Here, have one too.", "heart")
			c:hearts("a", 2)
			c:all(2)
		end)
		s:choice("Tell everyone", function(c)
			c:n("The whole town clapped {a} at lunch.")
			c:by("a", { shy = "I'm going to hide for a week.", _ = "Oh, stop. ...Don't stop." }, "sweat")
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
		s:n("There are socks on the bandstand, a shirt on the fountain and somebody's pants on a gull.")
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
		s:n("Everyone sang to the town. The town didn't say anything back, but it felt nice.")
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
		s:n("Somebody shouted from the pier: there's a whale out past the harbour.")
		s:n("Everybody ran. It blew a spout of water, rolled over, and waved one fin. Probably by accident.")
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
		s:by("a", {
			gentle = "Oh, look at you. Eat up, little one.",
			bold = "I'd have won that fight. Probably.",
			_ = "Well. Mystery solved.",
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

return list
