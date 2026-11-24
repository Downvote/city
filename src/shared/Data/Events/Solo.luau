--!nonstrict
-- Things one villager goes through: small odd days, hobbies, the weather, dreams and daydreams,
-- and the things they make (some of which they'll give you, as keepsakes). How they take it is
-- their own: Kit's s:by picks the line by their personality.

local K = require(script.Parent.Kit)
local Sayings = require(script.Parent.Parent.Sayings)
local Foods = require(script.Parent.Parent.Foods)

local W = K.W

local list = {}
local function event(def)
	def.actors = def.actors or 1
	table.insert(list, def)
end

-- Something they made, which they may let you keep: shown while the scene plays, given as a
-- keepsake (Build/Recipes/Keepsakes) if you ask for it, kept if you tell them to.
local function makes(o: { [string]: any })
	event({
		id = o.id,
		when = o.when or "day",
		weight = W(o.w),
		scene = function(ctx, a)
			local s = K.scene(ctx, o.title)
			s:prop("item:" .. o.item, "a")
			for _, l in o.lines do
				if l[1] == "n" then
					s:n(l[2])
				else
					s:say(l[1], l[2], l[3], l[4])
				end
			end
			s:by("a", o.react, "sparkle")
			s:choice(o.ask or "Could I have it?", function(c)
				c:by("a", {
					shy = "You want it? Oh. Okay. Here.",
					proud = "Of course you want it. Look after it.",
					cheeky = "Fine. But I'm coming round to visit it.",
					dreamy = "Yes. I think it wanted to go with you anyway.",
					bold = "Take it. It's yours.",
					easygoing = "Sure. Saves me finding a shelf for it.",
					gentle = "Of course, dear. I'd like you to have it.",
					_ = { "Course you can. Here.", "Really? You want it? Here you go." },
				}, "heart", "cheer")
				c:keep(o.item, "a")
				c:mood("a", 4)
				c:hearts("a", 1)
				c:memo("a", o.memo)
			end)
			s:choice(o.keep or "Keep it, it's yours", function(c)
				c:by("a", {
					proud = "I'll put it where everyone can see.",
					shy = "Okay. I'll keep it somewhere safe.",
					cheeky = "Good, because I wasn't really going to give it away.",
					dreamy = "It can sit by the window and look out.",
					_ = "I'll find it a good spot at home.",
				}, "heart")
				c:mood("a", 6)
				c:memo("a", o.memo)
			end)
			s:log(o.log)
			return s:done()
		end,
	})
end

-- hiccups --------------------------------------------------------------------------------------------

event({
	id = "hiccups",
	when = "day",
	weight = W({ base = 0.3 }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "Hiccups")
		s:n("{a} has had the hiccups since breakfast.")
		s:by("a", {
			proud = "This is not happening. Hic. It is not.",
			shy = "Please don't look at me. Hic.",
			bold = "I'll beat these. Hic. Watch me.",
			dreamy = "Each one's a little bubble. Hic. Pretty.",
			cheeky = "I'm doing it on purpose. Hic. Don't tell anyone.",
			_ = { "I'm fine. Hic. Totally fine.", "Three hours now. Hic. Three." },
		}, "sweat")
		s:choice("Give them a fright", function(c)
			c:n("You crept up behind {a} and shouted BOO.")
			c:by("a", {
				shy = "EEP. ...Oh. They've gone.",
				bold = "HA. You got me. And they've gone.",
				easygoing = "Whoa. Don't do that. ...Oh. They stopped.",
				_ = "Aah! ...Wait. They've stopped.",
			}, "sparkle")
			c:mood("a", 4)
			c:memo("a", "Somebody scared my hiccups away yesterday. Rude, but it worked.")
		end)
		s:choice("Drink water upside down", function(c)
			c:n("{a} bent over and drank from the far side of the glass.")
			c:say("a", "Glug. Hic. Glug. ...Hic.", "sweat")
			c:say("a", "So now I'm wet and I've still got them.", "sad")
			c:mood("a", -1)
			c:memo("a", "Never drink water upside down. Trust me.")
		end)
		s:choice("Hold your breath", function(c)
			c:say("a", "Mmmmmmf.", "question")
			c:say("a", "...Gone. I think they're gone.", "sparkle", "cheer")
			c:mood("a", 2)
		end)
		s:log("{a} had the hiccups all morning.")
		return s:done()
	end,
})

-- a new hobby ------------------------------------------------------------------------------------------

event({
	id = "newhobby",
	when = "day",
	weight = W({ base = 0.25, traits = { focus = -0.3 } }),
	scene = function(ctx, a)
		local v = ctx.v(a)
		local options = {}
		for _, h in Sayings.hobbies do
			if h.id ~= v.hobby then
				table.insert(options, h)
			end
		end
		local h = ctx.rng:pick(options)
		local s = K.scene(ctx, "A new hobby"):with({ hobby = h.name })
		s:say("a", "I've decided. I'm taking up {hobby}.", "idea", "point")
		s:by("a", {
			bold = "Starting today. No point waiting.",
			shy = "Is that silly? I've been wanting to for ages.",
			cheeky = "Don't laugh. I can see you about to laugh.",
			sunny = "I've told everyone already, so now I have to.",
			easygoing = "Seems relaxing. Mostly sitting, I hope.",
			dreamy = "It came to me in a dream. Well, a nap.",
			proud = "I expect I'll be a natural.",
			_ = "I bought everything for it already.",
		}, "sparkle")
		s:choice("Go for it", function(c)
			c:by("a", {
				easygoing = "Right. Starting now. After a snack.",
				shy = "Okay. I'll try it.",
				proud = "Watch. I'll be good at this.",
				_ = "Right. Starting now.",
			}, "music", "cheer")
			c:hobby("a", h.id)
			c:mood("a", 6)
			c:memo("a", "I've taken up {hobby}. Ask me about it. Please.")
		end)
		s:choice("Maybe stick with what you've got", function(c)
			c:by("a", {
				proud = "Hmph. I'd have been good at it.",
				bold = "Fine. Forget I said it.",
				shy = "Okay. It was a silly idea.",
				_ = "Hmm. Maybe you're right.",
			}, "sad")
			c:mood("a", -2)
		end)
		s:log("{a} wanted to take up {hobby}.")
		return s:done()
	end,
})

-- odd socks ----------------------------------------------------------------------------------------------

event({
	id = "sock",
	when = "any",
	weight = W({ base = 0.25, traits = { focus = -0.3 } }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "The missing sock")
		s:n("{a} has one blue sock on and one stripy one.")
		s:say("a", "The other blue one's gone. I've checked everywhere. Even the fridge.", "question")
		s:by("a", {
			proud = "I'm starting a new fashion. Odd socks. You saw it here first.",
			dreamy = "Maybe it went on an adventure. I hope it's having fun.",
			cheeky = "Somebody's stealing socks in this town. I'm going to find out who.",
			gentle = "Oh well. This one's warm too.",
			_ = "Does anyone even look at socks? Don't answer that.",
		}, "sweat")
		s:mood("a", 1)
		s:memo("a", "I'm still one sock short, by the way.")
		s:log("{a} lost a sock.")
		return s:done()
	end,
})

-- a song stuck in their head -------------------------------------------------------------------------

event({
	id = "earworm",
	when = "day",
	weight = W({ base = 0.25 }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "Stuck in my head")
		s:n("{a} has been humming the same four notes all day.")
		s:say("a", "Dum da dum DUM. Dum da dum DUM. Make it stop.", "music")
		s:choice("Hum along", function(c)
			c:by("a", {
				cheeky = "Oh, you're doing harmonies now?",
				sunny = "Ha. Now it's both of us.",
				_ = "Now we've both got it. Thanks a lot.",
			}, "music", "laugh")
			c:mood("a", 3)
		end)
		s:choice("Hum them a different song", function(c)
			c:n("You hummed something else. {a} listened, very still.")
			c:say("a", "Oh no. Now I've got yours.", "sweat")
			c:say("a", "...It's better, though. Thanks.", "music")
			c:mood("a", 2)
			c:memo("a", "You put a song in my head yesterday and it's still there.")
		end)
		s:log("{a} had a song stuck in their head.")
		return s:done()
	end,
})

-- the giant marrow ---------------------------------------------------------------------------------------

event({
	id = "marrow",
	when = "day",
	weight = W({
		base = 0.12,
		season = { 2, 3 },
		cond = function(ctx, a)
			return ctx.v(a).hobby == "gardening" or ctx.rng:chance(0.5)
		end,
	}),
	scene = function(ctx, a)
		local s = K.scene(ctx, "The big marrow")
		s:prop("marrow", "a")
		s:n("{a} has been growing a marrow behind the house. It's about the size of a wheelbarrow.")
		s:by("a", {
			proud = "Biggest in town. I've measured it. Go on, find a bigger one.",
			gentle = "I sing to it in the mornings. I think it helps.",
			bold = "Tried to lift it this morning. Couldn't. Yet.",
			shy = "I didn't mean for it to get this big.",
			easygoing = "I just kept watering it and it kept going.",
			_ = "I don't know what to do with it. I just wanted to see how big it'd get.",
		}, "sparkle", "point")
		s:choice("Keep watering it", function(c)
			c:by("a", {
				proud = "It can go bigger. I know it can.",
				dreamy = "Grow, marrow. Grow.",
				_ = "More water, then. Let's see how far it goes.",
			}, "sparkle", "cheer")
			c:leave("marrow", 18, "a")
			c:mood("a", 5)
			c:memo("a", "The marrow's still growing. I've had to move the fence.")
		end)
		s:choice("Make soup for everyone", function(c)
			c:say("a", "Soup for everyone, then. I'll need the big pot.", "heart")
			c:all(3)
			c:mood("a", 3)
			c:memo("a", "Everybody had marrow soup. There's still half a marrow left.")
		end)
		s:log("{a} grew an enormous marrow.")
		return s:done()
	end,
})

makes({
	id = "marrowshow",
	title = "The marrow show",
	item = "keep_trophy",
	w = { base = 0.08, season = { 2, 3 } },
	lines = {
		{ "n", "{a} took a marrow to the show on the next island and came back with a little gold cup." },
		{ "a", "Second place. The winner's marrow had a hat on. I think that swung it.", "sparkle" },
	},
	react = {
		proud = "Second is the first of the losers. I'll be back next year.",
		easygoing = "Second's great. Less pressure than first.",
		shy = "I nearly didn't go. I'm glad I did.",
		bold = "Second. Next year I'm winning it.",
		_ = "Second place. I'll take that.",
	},
	ask = "Can I see it on my shelf?",
	keep = "You earned it, keep it",
	memo = "Second place at the marrow show. Next year, I'm bringing a hat.",
	log = "{a} came second at the marrow show.",
})

-- a bad haircut --------------------------------------------------------------------------------------

event({
	id = "haircut",
	when = "day",
	weight = W({ base = 0.2, traits = { focus = -0.2 } }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "A new fringe")
		s:n("{a} cut their own fringe this morning. It went a bit wonky.")
		s:by("a", {
			shy = "Don't look. Please don't look.",
			proud = "It's meant to be like this. It's a style.",
			cheeky = "I meant to do that. The left side, anyway.",
			easygoing = "Eh. It'll grow.",
			bold = "Did it myself. Went a bit far.",
			dreamy = "I was thinking about something else while I cut it.",
			_ = "Is it bad? Be honest. No, don't be honest.",
		}, "sweat")
		s:choice("It suits you", function(c)
			c:by(
				"a",
				{ proud = "I know.", shy = "Really? You're not just saying that?", _ = "Really? Okay. I'm keeping it." },
				"heart"
			)
			c:mood("a", 5)
			c:hearts("a", 1)
		end)
		s:choice("A hat for a week, maybe", function(c)
			c:by("a", {
				proud = "It's not that bad. ...Fine. Where's my hat.",
				easygoing = "Fair. I've got a hat somewhere.",
				_ = "...That bad? Right. I'll find a hat.",
			}, "sad")
			c:mood("a", -3)
			c:memo("a", "I'm wearing a hat until my fringe grows out. Don't ask.")
		end)
		s:log("{a} cut their own fringe.")
		return s:done()
	end,
})

-- the sneeze and the cat -----------------------------------------------------------------------------

event({
	id = "sneeze",
	when = "day",
	weight = W({ base = 0.22 }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "A big sneeze")
		s:prop("cat", "a")
		s:n("A cat was asleep on the wall. Then {a} sneezed.")
		s:say("a", "AAAH... CHOO.", "sweat")
		s:n("The cat went straight up in the air, landed on its feet and gave {a} a long look.")
		s:by("a", {
			shy = "Sorry. Sorry, cat. Sorry.",
			bold = "Bless me. Thanks, cat.",
			cheeky = "Ten out of ten jump, honestly.",
			gentle = "Oh, you poor thing. I didn't mean it.",
			dreamy = "It thinks I'm a thundercloud now.",
			_ = "That cat is never going to forgive me.",
		}, "question")
		s:mood("a", 2)
		s:memo("a", "A cat glares at me now. I sneezed near it once. Once.")
		s:log("{a} sneezed and scared a cat.")
		return s:done()
	end,
})

-- a diary ---------------------------------------------------------------------------------------------

event({
	id = "diary",
	when = "night",
	weight = W({ base = 0.25, traits = { social = -0.4 } }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "Dear diary")
		s:n("{a} is writing in a little book with a lock on it.")
		s:by("a", {
			shy = "Don't read it. It's mostly about the weather. And... other things.",
			proud = "My memoirs. They'll be worth a fortune one day.",
			cheeky = "Half of it's made up. Yesterday I won a boat race, apparently.",
			_ = "It's my diary. Every day since I moved in.",
		}, "sweat")
		s:choice("Sneak a look", function(c)
			if ctx.rng:chance(0.5) then
				c:n("You leaned over. The page said: 'Today was nice. Saw the sea. Had a bun.'")
				c:say("a", "Hey! ...Well. That's all it says. It was a good bun.", "sweat")
				c:mood("a", -1)
			else
				c:n("{a} snapped the book shut before you got close.")
				c:by("a", {
					bold = "Oi. Nice try.",
					shy = "Th-that's private.",
					gentle = "Not that one, please.",
					_ = "Nice try.",
				}, "anger")
				c:mood("a", -5)
			end
		end)
		s:choice("Leave them to it", function(c)
			c:say("a", "Thanks. I'll write that you were nice.", "heart")
			c:hearts("a", 1)
			c:mood("a", 2)
		end)
		s:log("{a} wrote in their diary.")
		return s:done()
	end,
})

-- cloud spotting -------------------------------------------------------------------------------------

local CLOUDS = { "a teapot", "a sleeping dog", "a bun", "a whale with a hat", "the town hall, but sad", "a sock" }

event({
	id = "clouds",
	when = "day",
	weight = W({ base = 0.2, weather = { "clear", "cloudy" }, traits = { focus = -0.4 } }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "Cloud spotting"):with({ one = ctx.rng:pick(CLOUDS), two = ctx.rng:pick(CLOUDS) })
		s:n("{a} is lying on their back on the grass, pointing at the sky.")
		s:say("a", "That one's {one}. And that one's... {two}.", "idea", "point")
		s:by("a", {
			dreamy = "I could stay here till they all turn into something.",
			easygoing = "Best way to spend an afternoon. Don't tell anyone.",
			bold = "I've been here an hour. Is that allowed?",
			cheeky = "That one looks like you. The grumpy one.",
			shy = "I don't usually do this where people can see.",
			_ = "Come and lie down. There's room.",
		}, "music")
		s:mood("a", 4)
		s:log("{a} spent the afternoon looking at clouds.")
		return s:done()
	end,
})

-- the weather ---------------------------------------------------------------------------------------

event({
	id = "puddles",
	when = "day",
	weight = W({ base = 0.35, weather = "rain", traits = { mischief = 0.4 } }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "Puddles")
		s:prop("umbrella", "a")
		s:n("{a} left their umbrella open on the path and is jumping in every puddle on the street.")
		s:by("a", {
			proud = "This is for my health. Splashing is very good for you.",
			shy = "Hehe. Nobody's looking. Splash.",
			gentle = "I haven't done this since I was small.",
			_ = { "SPLASH. Did you see that one?", "Biggest puddle wins. That one. Watch." },
		}, "music", "cheer")
		s:mood("a", 5)
		s:memo("a", "My boots are still wet from the puddles.")
		s:log("{a} jumped in puddles in the rain.")
		return s:done()
	end,
})

event({
	id = "snowman",
	when = "day",
	weight = W({ base = 0.5, weather = "snow" }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "A snowman")
		s:prop("snowman", "a")
		s:n("{a} has rolled three big snowballs and stacked them up.")
		s:by("a", {
			bold = "Tallest snowman in town. Taller than me.",
			dreamy = "He told me his name. It's Gerald.",
			cheeky = "I gave him my neighbour's hat. Don't tell them.",
			_ = "Doesn't he look smart? I lent him my scarf.",
		}, "sparkle", "point")
		s:choice("Add a carrot nose", function(c)
			c:say("a", "Perfect. Now he can smell the bakery like the rest of us.", "heart", "cheer")
			c:leave("snowman", 24, "a")
			c:mood("a", 6)
			c:memo("a", "Have you seen my snowman? Go and say hello. He's very polite.")
		end)
		s:choice("Too cold for me", function(c)
			c:say("a", "Fair. I can't feel my fingers anyway.", "sweat")
			c:leave("snowman", 12, "a")
			c:mood("a", 3)
		end)
		s:log("{a} built a snowman.")
		return s:done()
	end,
})

event({
	id = "leafpile",
	when = "day",
	weight = W({
		base = 0.3,
		cond = function(ctx)
			return ctx.weather == "leaves" or (ctx.season == 3 and ctx.weather ~= "rain")
		end,
	}),
	scene = function(ctx, a)
		local s = K.scene(ctx, "A pile of leaves")
		s:prop("leaves", "a")
		s:n("{a} raked every leaf on the street into one big pile.")
		s:by("a", {
			easygoing = "That took ages. Now I'm going to lie in it.",
			bold = "Run up. Jump. Here I go.",
			proud = "Look how neat it is. Nobody touch it.",
			cheeky = "Three. Two. One. JUMP.",
			_ = "One jump. Just one. Then I'll rake it again.",
		}, "sparkle", "cheer")
		s:n("Leaves everywhere. There are two piles now, and {a} is in one of them.")
		s:leave("leaves", 10, "a")
		s:mood("a", 5)
		s:log("{a} jumped in a pile of leaves.")
		return s:done()
	end,
})

event({
	id = "sunburn",
	when = "day",
	weight = W({ base = 0.25, season = 2, weather = "clear" }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "Too much sun")
		s:n("{a} fell asleep on the beach. One side of their face is pink.")
		s:by("a", {
			proud = "It's a tan. A very bright tan.",
			easygoing = "Worth it. Best nap of the year.",
			shy = "Everyone's going to see. Can I borrow a hat?",
			_ = "Only one side. I look like a radish.",
		}, "sweat")
		s:choice("Get them some aloe", function(c)
			c:say("a", "Ooh, that's cool. Thank you.", "heart")
			c:mood("a", 3)
			c:hearts("a", 1)
		end)
		s:choice("Sun cream next time", function(c)
			c:say("a", "Next time. I'll set an alarm too.", "sweat")
			c:mood("a", -1)
		end)
		s:log("{a} got sunburnt on the beach.")
		return s:done()
	end,
})

event({
	id = "kite",
	when = "day",
	weight = W({ base = 0.25, weather = { "clear", "cloudy", "blossom", "leaves" } }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "Flying a kite")
		s:prop("kite", "a")
		s:n("{a} has got a kite right up into the wind.")
		s:say("a", "Look how high it is. I can feel it pulling.", "sparkle", "point")
		if ctx.rng:chance(0.4) then
			s:n("Then the wind dropped, and the kite went nose first into the top of a tree.")
			s:by("a", {
				bold = "I'm going up. Hold my shoes.",
				shy = "Oh no. Oh no no.",
				cheeky = "Well, the tree's having a nice time.",
				_ = "...Well. It's up there, at least.",
			}, "sweat")
			s:choice("Help them get it down", function(c)
				c:n("With a long stick and a lot of jumping, the kite came down with only one small hole.")
				c:say("a", "Thanks. There's a hole in it now, but it'll still fly.", "heart")
				c:mood("a", 4)
				c:hearts("a", 1)
			end)
			s:choice("Leave it for the birds", function(c)
				c:say("a", "Maybe a bird will fly it. That'd be nice.", "sad")
				c:mood("a", -3)
			end)
		else
			s:voice("a", "excited", "music", "cheer")
			s:mood("a", 5)
		end
		s:log("{a} flew a kite.")
		return s:done()
	end,
})

event({
	id = "stargaze",
	when = "night",
	weight = W({
		base = 0.25,
		weather = "clear",
		cond = function(ctx, a)
			return ctx.v(a).hobby == "stargazing" or ctx.rng:chance(0.6)
		end,
	}),
	scene = function(ctx, a)
		local s = K.scene(ctx, "Through the telescope")
		s:prop("telescope", "a")
		s:n("{a} has set up a telescope in the garden.")
		s:say("a", "I've found a new star. It's moving, though. And blinking.", "idea", "point")
		s:by("a", {
			proud = "I'm naming it after myself, obviously.",
			dreamy = "Maybe it's a star that wants to go somewhere.",
			cheeky = "It's a plane. I know it's a plane. Let me have this.",
			_ = "...It might be a plane.",
		}, "question")
		s:mood("a", 4)
		s:memo("a", "I found a new star last night. It was a plane.")
		s:log("{a} went stargazing.")
		return s:done()
	end,
})

-- the night --------------------------------------------------------------------------------------------

event({
	id = "insomnia",
	cutscene = "kitchen",
	when = "night",
	weight = W({ base = 0.3, traits = { lazy = -0.3 } }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "Can't sleep")
		s:n("It's late, and {a} is still wide awake.")
		s:by("a", {
			dreamy = "My brain's doing cartwheels. Big ones.",
			proud = "I'm not tired. Sleep is for other people.",
			bold = "I've been staring at the ceiling for an hour. It's winning.",
			cheeky = "I'm not sleeping. I'm planning things.",
			shy = "I keep thinking about what I said today.",
			_ = {
				"I've counted to four hundred sheep. They're getting bored too.",
				"Every time I close my eyes I remember something.",
			},
		}, "zzz")
		s:choice("Warm milk", function(c)
			c:say("a", "Mm. Warm. And... sleepy. Night.", "zzz")
			c:mood("a", 4)
		end)
		s:choice("Tell them a story", function(c)
			c:n("You started a story about a lighthouse keeper. {a} was asleep before the boat came in.")
			c:mood("a", 5)
			c:hearts("a", 1)
			c:memo("a", "You never finished that lighthouse story. Did the boat come in?")
		end)
		s:choice("Count the sheep again", function(c)
			c:say("a", "Four hundred and one. Four hundred and two...", "zzz")
			c:mood("a", -1)
		end)
		s:log("{a} couldn't sleep.")
		return s:done()
	end,
})

event({
	id = "midnightsnack",
	cutscene = "kitchen",
	when = "night",
	weight = W({ base = 0.2, traits = { lazy = 0.4 } }),
	scene = function(ctx, a)
		local food = ctx.rng:pick(Foods.list)
		local s = K.scene(ctx, "A midnight snack"):with({ food = food.name:lower() })
		s:n("A light is on in {a}'s kitchen. It's two in the morning.")
		s:say("a", "I'm not eating {food}. I'm checking it's still there.", "sweat")
		s:by("a", {
			proud = "A chef has to test things at all hours.",
			easygoing = "Best meal of the day, this one.",
			shy = "Please don't tell anyone.",
			cheeky = "You didn't see anything.",
			bold = "I was hungry. So what.",
			_ = "It was there. It isn't now.",
		}, "heart")
		s:mood("a", 3)
		s:log("{a} had a midnight snack.")
		return s:done()
	end,
})

event({
	id = "nightmare",
	cutscene = "dream",
	when = "night",
	weight = W({ base = 0.18 }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "A bad dream")
		s:n("{a} woke up with a jump.")
		s:by("a", {
			bold = "I had a dream I lost every race. Every single one.",
			proud = "In my dream, nobody knew who I was.",
			shy = "I dreamed I had to give a speech. In my pyjamas.",
			dreamy = "The clouds stopped talking to me. All of them.",
			cheeky = "I dreamed I was the one getting pranked. Horrible.",
			_ = "I dreamed my house floated away and I couldn't catch it.",
		}, "sad")
		s:choice("It was only a dream", function(c)
			c:by("a", {
				bold = "Yeah. I know. ...Stay a bit, though?",
				proud = "Obviously. I wasn't scared.",
				shy = "Can you stay? Just till I'm sleepy?",
				_ = "I know. Can you stay till I'm sleepy again?",
			}, "heart")
			c:mood("a", 4)
			c:hearts("a", 1)
		end)
		s:choice("Leave the light on", function(c)
			c:say("a", "Okay. Light on. That's better.", "zzz")
			c:mood("a", 2)
		end)
		s:log("{a} had a bad dream.")
		return s:done()
	end,
})

-- small odd things ----------------------------------------------------------------------------------

event({
	id = "plants",
	when = "day",
	weight = W({
		base = 0.15,
		traits = { kind = 0.2 },
		cond = function(ctx, a)
			return ctx.v(a).hobby == "gardening" or ctx.rng:chance(0.5)
		end,
	}),
	scene = function(ctx, a)
		local s = K.scene(ctx, "Talking to plants")
		s:n("{a} is crouched by a flowerpot, talking to it quietly.")
		s:by("a", {
			gentle = "You're doing so well. Look at that new leaf.",
			proud = "You'll be the finest fern in town. Stand up straight.",
			cheeky = "Grow, or I'll tell the other plants your secrets.",
			dreamy = "It said it likes the rain more than me. Rude.",
			_ = "They grow better if you chat to them. Everyone knows that.",
		}, "heart")
		s:mood("a", 3)
		s:log("{a} talked to their plants.")
		return s:done()
	end,
})

event({
	id = "speech",
	when = "day",
	weight = W({ base = 0.12, traits = { brave = 0.3, social = 0.2 } }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "Practising a speech")
		s:n("{a} is giving a speech to the mirror.")
		s:by("a", {
			proud = "Thank you. I couldn't have done it without... well, me.",
			shy = "Um. Thank you all for... um. Thank you.",
			sunny = "Thank you all so much. I'd like to thank my mum, the baker, the man with the dog...",
			_ = "Thank you, thank you. I'd like to thank... um. Everybody.",
		}, "sparkle", "point")
		s:by("a", {
			shy = "Oh no. You heard that. I'm going to go and hide now.",
			proud = "Pretty good, right? I'll take questions now.",
			_ = "It's for nothing. I just like to be ready.",
		}, "sweat")
		s:choice("Clap", function(c)
			c:by("a", {
				shy = "Oh. Um. Thank you.",
				proud = "Thank you. Yes. Keep going.",
				cheeky = "Louder. I can't hear you.",
				_ = "Thank you, thank you. You're too kind.",
			}, "sparkle", "cheer")
			c:mood("a", 5)
		end)
		s:choice("Pretend you heard nothing", function(c)
			c:say("a", "Good. Neither did I.", "sweat")
			c:mood("a", 1)
		end)
		s:log("{a} practised a speech in the mirror.")
		return s:done()
	end,
})

event({
	id = "workout",
	when = "day",
	weight = W({ base = 0.2 }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "A new routine")
		s:say("a", "New me. Fifty push ups every morning starting today.", "idea", "point")
		if K.isPers(ctx, a, "bold") then
			s:n("{a} did fifty. Then fifty more. Then went for a run.")
			s:say("a", "That was the warm up.", "sparkle", "cheer")
			s:mood("a", 5)
		else
			s:n("{a} did four. Then had a lie down on the grass.")
			s:by("a", {
				easygoing = "Four is a lot of push ups. For me.",
				proud = "Four perfect ones. Quality, not quantity.",
				_ = "Tomorrow. Fifty tomorrow.",
			}, "zzz")
			s:mood("a", 1)
		end
		s:log("{a} started a new exercise routine.")
		return s:done()
	end,
})

event({
	id = "letter",
	when = "day",
	weight = W({ base = 0.2 }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "A letter")
		s:n("The post brought a letter for {a}, in handwriting they knew at once.")
		s:by("a", {
			shy = "It's from my best friend back home. She still remembers me.",
			proud = "Someone from my old town says they miss me. Of course they do.",
			dreamy = "It smells like where I grew up. Salt and toast.",
			_ = "It's from an old friend. They're doing well. They drew me a cat.",
		}, "heart")
		s:choice("Write back today", function(c)
			c:say("a", "I will. I'll tell them all about this place.", "heart", "cheer")
			c:mood("a", 6)
			c:memo("a", "I wrote back to my old friend. I told them about you.")
		end)
		s:choice("Read it again", function(c)
			c:say("a", "Third time. It's still nice.", "heart")
			c:mood("a", 4)
		end)
		s:log("{a} got a letter from an old friend.")
		return s:done()
	end,
})

local PARCEL = {
	{ "a jumper their gran knitted. It has a reindeer on it.", 4 },
	{ "a rubber duck. No note. Just the duck.", 2 },
	{ "a book they lent somebody three years ago.", 3 },
	{ "a box of fudge from somebody who signed it 'You know who'.", 5 },
	{ "another, smaller box. Inside that, a button.", -1 },
}

event({
	id = "parcel",
	when = "day",
	weight = W({ base = 0.2 }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "A parcel")
		s:prop("box", "a")
		s:n("A parcel turned up on {a}'s step. No return address.")
		s:by("a", {
			cheeky = "If it's a prank I'll be very impressed.",
			shy = "What if it's for someone else?",
			bold = "Only one way to find out.",
			_ = "I didn't order anything. Did I?",
		}, "question")
		s:choice("Open it now", function(c)
			local p = ctx.rng:pick(PARCEL)
			c:with({ inside = p[1] })
			c:n("Inside was {inside}")
			c:voice("a", if p[2] > 0 then "wow" else "hmm", if p[2] > 0 then "sparkle" else "question")
			c:mood("a", p[2])
			c:memo("a", "Someone sent me a parcel. I still don't know who.")
		end)
		s:choice("Save it for later", function(c)
			c:say("a", "Good idea. Tea first, then the parcel.", "music")
			c:mood("a", 2)
		end)
		s:log("{a} got a mystery parcel.")
		return s:done()
	end,
})

event({
	id = "spill",
	when = "day",
	weight = W({ base = 0.2, traits = { focus = -0.3 } }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "Oops")
		s:n("{a} tipped a whole cup of tea down their front.")
		s:by("a", {
			proud = "I meant to. I'm trying out brown.",
			shy = "Of course. Of course this happens today.",
			easygoing = "Eh. It was getting cold anyway.",
			cheeky = "Tea shirt. Get it? Tea shirt.",
			_ = "Brilliant. Just brilliant.",
		}, "sweat")
		s:mood("a", -1)
		s:log("{a} spilled tea down their front.")
		return s:done()
	end,
})

event({
	id = "recipe",
	when = "day",
	weight = W({ base = 0.18 }),
	scene = function(ctx, a)
		local f1, f2 = ctx.rng:pick(Foods.list), ctx.rng:pick(Foods.list)
		local s = K.scene(ctx, "A new recipe"):with({ one = f1.name:lower(), two = f2.name:lower() })
		s:n("{a} is inventing a dish: {one} with {two}.")
		s:say("a", "Nobody's ever put these two together. Let's see why.", "idea")
		s:choice("Taste it", function(c)
			if ctx.rng:chance(0.5) then
				c:n("It was... good. Weirdly good.")
				c:voice("a", "excited", "sparkle", "cheer")
				c:mood("a", 5)
				c:memo("a", "My {one} and {two} thing worked. I'm making it again on Sunday.")
			else
				c:n("You chewed slowly. {a} watched your face.")
				c:say("a", "That bad? That bad. I'll write 'no' next to it.", "sweat")
				c:mood("a", -1)
			end
		end)
		s:choice("Let them try it first", function(c)
			c:n("{a} took a big bite, paused, and quietly put the spoon down.")
			c:say("a", "We'll never speak of this.", "sweat")
		end)
		s:log("{a} invented a recipe.")
		return s:done()
	end,
})

-- things they make, and might give you ---------------------------------------------------------------

event({
	id = "painting",
	when = "day",
	weight = W({
		base = 0.12,
		cond = function(ctx, a)
			return ctx.v(a).hobby == "painting" or ctx.rng:chance(0.4)
		end,
	}),
	scene = function(ctx, a)
		local s = K.scene(ctx, "At the easel")
		s:prop("easel", "a")
		s:n("{a} set up an easel in the street and has been painting all afternoon.")
		s:by("a", {
			proud = "A masterpiece in the making. Don't stand in my light.",
			shy = "It's not finished. Well, it might be. I can't tell.",
			dreamy = "I'm painting what the sea would look like if it was happy.",
			_ = "Hold still. I might put you in it.",
		}, "sparkle")
		s:choice("Could you paint me?", function(c)
			c:n("{a} had you sit on a crate for an hour. Then they turned the canvas round.")
			c:by("a", {
				shy = "It's you. I mean, it's meant to be. You can keep it.",
				proud = "There. You've never looked better. Keep it.",
				cheeky = "I gave you a bigger nose. Artist's choice. Keep it.",
				_ = "There. It's you. Keep it.",
			}, "heart", "cheer")
			c:keep("keep_portrait", "a")
			c:hearts("a", 1)
			c:mood("a", 5)
			c:memo("a", "I painted your portrait. I hope you hung it somewhere nice.")
		end)
		s:choice("Leave them to work", function(c)
			c:say("a", "Thanks. I'll show you when it's done.", "music")
			c:mood("a", 3)
		end)
		s:log("{a} spent the afternoon painting.")
		return s:done()
	end,
})

makes({
	id = "pottery",
	title = "A pot",
	item = "keep_pot",
	w = { base = 0.1 },
	lines = {
		{ "n", "{a} has clay up to the elbows and a pot drying on the step." },
		{ "a", "It's a bit lopsided. That's the handmade look.", "sparkle", "point" },
	},
	react = {
		proud = "Best pot on the island. I've seen the others.",
		shy = "It's my first one. Is it all right?",
		_ = "I put lavender in it. To hide the wonky bit.",
	},
	memo = "I made a pot. It leaks a little at the bottom.",
	log = "{a} made a clay pot.",
})

makes({
	id = "whittling",
	title = "Whittling",
	item = "keep_bird",
	w = { base = 0.1, traits = { focus = 0.2 } },
	lines = {
		{ "n", "{a} has been sitting on the step with a knife and a bit of wood since lunch." },
		{ "a", "It's a bird. You can tell it's a bird, right?", "question" },
	},
	react = {
		cheeky = "I was going for a duck, but it got ideas.",
		bold = "Took three bits of wood. Snapped the first two.",
		_ = "I think it's the nicest thing I've ever made.",
	},
	memo = "I carved a little bird. My thumb has a plaster on it now.",
	log = "{a} carved a wooden bird.",
})

makes({
	id = "quilting",
	title = "A patchwork quilt",
	item = "keep_quilt",
	w = { base = 0.08, season = { 3, 4 }, traits = { kind = 0.2 } },
	lines = {
		{ "n", "{a} finished a quilt today, made from old shirts and a curtain." },
		{ "a", "Every patch is something. That one's from my favourite shirt.", "heart", "point" },
	},
	react = {
		gentle = "I sewed a heart in the middle. For whoever sleeps under it.",
		proud = "Two hundred stitches. I counted every one.",
		_ = "It took all autumn. I kept pricking my fingers.",
	},
	memo = "That quilt took me weeks. Are you warm enough at night?",
	log = "{a} finished a patchwork quilt.",
})

makes({
	id = "bottleship",
	title = "A ship in a bottle",
	item = "keep_boat",
	w = { base = 0.06, traits = { focus = 0.4 } },
	lines = {
		{ "n", "{a} is holding a bottle up to the light. There's a little ship inside." },
		{ "a", "Don't ask how I got it in. I don't know either.", "sparkle" },
	},
	react = {
		dreamy = "I like to think it's sailing somewhere small.",
		proud = "It takes patience. And steady hands, which I have.",
		_ = "It took tweezers and a very long week.",
	},
	memo = "I put a ship in a bottle. I've already started on a second one.",
	log = "{a} put a ship in a bottle.",
})

makes({
	id = "shells",
	title = "A jar of shells",
	item = "keep_shells",
	w = { base = 0.1, season = { 2, 3 } },
	lines = {
		{ "n", "{a} came back from the beach with full pockets and a jar." },
		{ "a", "One shell for every nice day. I've run out of room.", "music", "point" },
	},
	react = {
		dreamy = "If you hold one to your ear you can hear Tuesday.",
		cheeky = "One of them was a crab. I put him back. He was cross.",
		_ = "There's a starfish on top. I found it already dried out.",
	},
	memo = "I filled a jar with shells. The beach has a few left.",
	log = "{a} filled a jar with shells.",
})

makes({
	id = "birdhouse",
	title = "A birdhouse",
	item = "keep_birdhouse",
	w = { base = 0.08, season = { 1, 2 }, traits = { kind = 0.2 } },
	lines = {
		{ "n", "{a} has built a little house on a post, with a round door and flowers painted on." },
		{ "a", "A bird moved in before the paint was dry.", "sparkle" },
	},
	react = {
		gentle = "I put a perch on it so they can sit and look out.",
		bold = "Best house on the street. Don't tell the builders.",
		_ = "The roof comes off, so you can clean it out.",
	},
	memo = "I built a birdhouse. There's a robin in it now.",
	log = "{a} built a birdhouse.",
})

makes({
	id = "chime",
	title = "A wind chime",
	item = "keep_chime",
	w = { base = 0.07, weather = { "clear", "cloudy", "leaves" } },
	lines = {
		{ "n", "Something on {a}'s porch tinkles every time the wind blows." },
		{ "a", "I made a wind chime from old pipes. Listen. Ting.", "music" },
	},
	react = {
		dreamy = "The wind plays it better than I could.",
		easygoing = "Music I don't have to play. Perfect.",
		_ = "Each pipe's a different note. One of them's a bit flat.",
	},
	memo = "Every time it's windy I think of the chime I made.",
	log = "{a} made a wind chime.",
})

makes({
	id = "mug",
	title = "A painted mug",
	item = "keep_mug",
	w = { base = 0.1 },
	lines = {
		{ "n", "{a} has been painting mugs at the kitchen table. There's paint on the cat." },
		{ "a", "This one's the best. It has a heart on it. And some dots.", "heart", "point" },
	},
	react = {
		shy = "The heart's a bit wonky. Is that all right?",
		cheeky = "There's a secret message on the bottom. Don't look yet.",
		_ = "Tea tastes better out of a mug someone made for you.",
	},
	memo = "Are you drinking out of the mug I painted? Say yes.",
	log = "{a} painted a mug.",
})

makes({
	id = "pressing",
	title = "Pressed flowers",
	item = "keep_flowers",
	w = { base = 0.08, season = { 1, 2 }, traits = { kind = 0.2 } },
	lines = {
		{ "n", "{a} has a heavy book on the table with flowers sticking out of it." },
		{ "a", "I've been pressing flowers from the hill. These are ready.", "sparkle" },
	},
	react = {
		gentle = "I framed them, so they'll keep.",
		dreamy = "They're asleep. Flat and asleep.",
		_ = "A daisy, two poppies and some lavender. I wrote their names on a label.",
	},
	memo = "I pressed some flowers in a big book. The book smells lovely now.",
	log = "{a} pressed some flowers.",
})

makes({
	id = "lanternmaking",
	when = "night",
	title = "A paper lantern",
	item = "keep_lantern",
	w = { base = 0.06 },
	lines = {
		{ "n", "There's a warm glow in {a}'s window. They've been folding paper all evening." },
		{ "a", "It's a lantern. It folds flat, then it doesn't. Look.", "sparkle" },
	},
	react = {
		shy = "I like the light it makes. Soft.",
		bold = "I set fire to the first one. This one's fine.",
		_ = "I painted little petals round it.",
	},
	memo = "I made a paper lantern. It's the cosiest thing I own.",
	log = "{a} made a paper lantern.",
})

makes({
	id = "knitting",
	title = "Knitting",
	item = "keep_cushion",
	w = {
		base = 0.07,
		season = { 3, 4 },
		cond = function(ctx, a)
			return ctx.v(a).hobby == "knitting" or ctx.rng:chance(0.5)
		end,
	},
	lines = {
		{ "n", "{a} is surrounded by wool. In the middle of it all is a cushion." },
		{ "a", "I was knitting a scarf. Then it was a cushion.", "sweat" },
	},
	react = {
		easygoing = "It's good for naps. I've checked.",
		proud = "Three cables. Do you know how hard cables are?",
		_ = "It's got a button on. The button doesn't do anything.",
	},
	memo = "I knitted a cushion. Somebody please sit on it.",
	log = "{a} knitted a cushion.",
})

makes({
	id = "driftwood",
	title = "Driftwood",
	item = "keep_gull",
	w = { base = 0.05, traits = { focus = -0.2 } },
	lines = {
		{ "n", "{a} spent the morning dragging bits of wood up from the beach." },
		{ "a", "It's a gull. Made of driftwood. With a float for a head.", "sparkle", "point" },
	},
	react = {
		cheeky = "It's even got the gull look. The 'give me your chips' look.",
		dreamy = "The sea made the wood. I only put it together.",
		_ = "The real gulls keep looking at it. I think they're jealous.",
	},
	memo = "My driftwood gull scared off a real one this morning.",
	log = "{a} made a gull out of driftwood.",
})

makes({
	id = "snowglobe",
	title = "A snow globe",
	item = "keep_globe",
	w = { base = 0.07, season = 4 },
	lines = {
		{ "n", "{a} is shaking a little glass ball and watching the snow fall inside it." },
		{ "a", "There's a tiny house in it. With a tiny tree. I made all of it.", "sparkle" },
	},
	react = {
		gentle = "It's for when it's cold out. You can shake it by the fire.",
		cheeky = "I nearly glued my finger in there.",
		_ = "Shake it. Go on. See?",
	},
	memo = "I keep shaking the snow globe I made. I can't stop.",
	log = "{a} made a snow globe.",
})

-- little moments ----------------------------------------------------------------------------------

event({
	id = "trip",
	when = "day",
	weight = W({ base = 0.22, traits = { focus = -0.3 } }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "Smooth")
		s:n("{a} tripped over absolutely nothing in the middle of the square.")
		s:by("a", {
			proud = "That was a dance move. Very new. Very hard.",
			cheeky = "Ta da. I'll be here all week.",
			shy = "Nobody saw that. Please say nobody saw that.",
			bold = "The ground started it.",
			_ = "I'm fine. I'm fine. Keep walking.",
		}, "sweat", "laugh")
		s:mood("a", -1)
		s:log("{a} tripped over nothing.")
		return s:done()
	end,
})

local PIGEON = { "Captain", "Biscuit", "Sir Flaps", "Doris", "Pudding", "Gary" }

event({
	id = "pigeon",
	when = "day",
	weight = W({ base = 0.15 }),
	scene = function(ctx, a)
		local names = ctx.rng:shuffle(PIGEON)
		local s = K.scene(ctx, "A follower")
		s:n("A pigeon has been following {a} round town all morning.")
		s:by("a", {
			shy = "It's sweet. I think. It won't stop looking at me.",
			bold = "I've got a sidekick now.",
			cheeky = "I gave it one crumb. One. Now it thinks it lives with me.",
			_ = "It's a friend now. It needs a name.",
		}, "question")
		for i = 1, 3 do
			local name = names[i]
			s:choice(name, function(c)
				c:with({ pet = name })
				c:say("a", "{pet}. Perfect. Hello, {pet}.", "heart", "cheer")
				c:mood("a", 3)
				c:memo("a", "{pet} the pigeon still follows me everywhere.")
			end)
		end
		s:log("A pigeon adopted {a}.")
		return s:done()
	end,
})

local CATS = { "Turnip", "Duchess", "Pebble", "Mr Socks", "Waffle", "Pickle" }

event({
	id = "stray",
	when = "day",
	weight = W({ base = 0.12, traits = { kind = 0.3 } }),
	scene = function(ctx, a)
		local names = ctx.rng:shuffle(CATS)
		local s = K.scene(ctx, "A cat moves in")
		s:prop("cat", "a")
		s:n("A ginger cat has been sitting on {a}'s doorstep for three days.")
		s:by("a", {
			gentle = "It's decided it lives here. Who am I to argue?",
			proud = "Even cats know quality when they see it.",
			easygoing = "It naps more than me. I respect that.",
			_ = "I think I have a cat now. Help me name it.",
		}, "heart")
		for i = 1, 3 do
			local name = names[i]
			s:choice(name, function(c)
				c:with({ pet = name })
				c:say("a", "{pet}. Yes. You look like a {pet}.", "heart", "cheer")
				c:mood("a", 6)
				c:hearts("a", 1)
				c:memo("a", "{pet} slept on my face last night. I didn't have the heart to move.")
			end)
		end
		s:log("A stray cat moved in with {a}.")
		return s:done()
	end,
})

event({
	id = "spider",
	when = "any",
	weight = W({ base = 0.18 }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "A spider")
		s:n("There's a spider in {a}'s bath. A big one.")
		s:by("a", {
			bold = "I'll put it outside. Gently. Come here, mate.",
			gentle = "Poor thing. It's just looking for somewhere warm.",
			shy = "I'm moving house. That's it. It can have the house.",
			proud = "I'm not scared. I'm letting it have the bath. As a guest.",
			cheeky = "I'm going to put it in someone's shoe. ...Kidding.",
			dreamy = "Do you think it has a name? It looks like a Clive.",
			_ = "Can someone else deal with this? Anyone?",
		}, "sweat")
		s:choice("Put it outside", function(c)
			c:n("You took it out in a cup and let it go by the hedge.")
			c:voice("a", "thanks", "heart")
			c:hearts("a", 1)
			c:mood("a", 2)
		end)
		s:choice("It was here first", function(c)
			c:by("a", {
				gentle = "It can stay, then. I'll wash at the beach.",
				proud = "Fine. It's my guest. I'll shower at the beach.",
				_ = "Fine. It can stay. I'll shower at the beach.",
			}, "sweat")
			c:mood("a", -2)
		end)
		s:log("{a} found a spider in the bath.")
		return s:done()
	end,
})

event({
	id = "luckyday",
	when = "day",
	weight = W({ base = 0.15 }),
	scene = function(ctx, a)
		local coins = ctx.rng:int(2, 6) * 5
		local s = K.scene(ctx, "A lucky day"):with({ coins = coins })
		s:n("Everything is going right for {a} today.")
		s:say("a", "Found a coin on the way out. Then another one by the fountain.", "sparkle", "cheer")
		s:by("a", {
			proud = "The world's finally caught up with me.",
			dreamy = "I think the sky likes me today.",
			_ = "I'm not going to ask why.",
		}, "music")
		s:coins(coins)
		s:mood("a", 5)
		s:memo("a", "I had the luckiest day yesterday. It's back to normal now.")
		s:log("{a} had a lucky day and found {coins} coins.")
		return s:done()
	end,
})

event({
	id = "unlucky",
	when = "day",
	weight = W({ base = 0.2 }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "One of those days")
		s:n("{a} stubbed their toe on the way out, then dropped their toast butter side down.")
		s:by("a", {
			sunny = "Okay. Okay. I'm still smiling. Look. Smiling.",
			proud = "This is a test. I'm passing it.",
			easygoing = "I'm going back to bed. See you tomorrow.",
			_ = "What next? Don't answer. Don't tempt it.",
		}, "sad")
		s:choice("Cheer them up", function(c)
			c:n("You did your best seagull. It wasn't very good, but {a} laughed.")
			c:voice("a", "laugh", "music", "laugh")
			c:mood("a", 6)
			c:hearts("a", 1)
		end)
		s:choice("Tomorrow's another day", function(c)
			c:say("a", "It'd better be.", "sad")
			c:mood("a", -2)
		end)
		s:log("{a} had an unlucky day.")
		return s:done()
	end,
})

local COLLECT = { "spoons", "buttons", "stamps", "bottle tops", "interesting pebbles", "keys to nothing" }

event({
	id = "collection",
	when = "day",
	weight = W({ base = 0.15, traits = { focus = 0.2 } }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "A collection"):with({ things = ctx.rng:pick(COLLECT) })
		s:say("a", "I've started collecting {things}. I've got eleven already.", "sparkle", "point")
		s:by("a", {
			proud = "It'll be the finest collection on the island.",
			dreamy = "Each one has a story. I make them up.",
			cheeky = "Some of them were in other people's drawers. I'll give them back.",
			_ = "I don't know why. They're just nice to have.",
		}, "music")
		s:mood("a", 3)
		s:memo("a", "I'm up to twenty {things} now. Want to see?")
		s:log("{a} started collecting {things}.")
		return s:done()
	end,
})

event({
	id = "moustache",
	when = "day",
	weight = W({ base = 0.1, traits = { mischief = 0.5 } }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "It won't wash off")
		s:n("{a} drew a curly moustache on their face for a laugh. With the wrong pen.")
		s:by("a", {
			cheeky = "Look at me. I'm distinguished.",
			proud = "It suits me, frankly.",
			shy = "I've scrubbed it four times. It's still there.",
			_ = "I'll have to wear it to work. Tell me it suits me.",
		}, "sweat", "laugh")
		s:mood("a", 1)
		s:memo("a", "The moustache is nearly gone. You can still see the curly bit.")
		s:log("{a} drew on a moustache that won't come off.")
		return s:done()
	end,
})

event({
	id = "songwriting",
	when = "day",
	weight = W({
		base = 0.1,
		cond = function(ctx, a)
			return ctx.v(a).hobby == "guitar" or ctx.rng:chance(0.4)
		end,
	}),
	scene = function(ctx, a)
		local s = K.scene(ctx, "A song about town")
		s:prop("guitar", "a")
		s:n("{a} sat on the step with a guitar and wrote a song about the town.")
		s:say("a", "Oh Catalog Town, your gulls are loud, your bread is warm, I'm very proud.", "music")
		s:by("a", {
			proud = "Number one hit. Mark my words.",
			shy = "That's all I've got so far. Was it all right?",
			_ = "Second verse is about the bus. Needs work.",
		}, "sparkle")
		s:choice("Play it again", function(c)
			c:by("a", {
				shy = "Again? Okay. Um. From the top.",
				bold = "From the top. Louder this time.",
				_ = "From the top. Everyone sing.",
			}, "music", "cheer")
			c:all(2)
		end)
		s:choice("Keep working on it", function(c)
			c:say("a", "You're right. It needs a key change.", "idea")
			c:mood("a", 3)
		end)
		s:log("{a} wrote a song about the town.")
		return s:done()
	end,
})

event({
	id = "bubbles",
	when = "day",
	weight = W({ base = 0.18, weather = { "clear", "blossom" } }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "Bubbles")
		s:n("{a} is blowing bubbles off the step. Some of them are very big.")
		s:by("a", {
			dreamy = "Each one's a tiny world. Then pop.",
			bold = "Biggest one yet. It ate a leaf.",
			proud = "There's a technique. I won't share it.",
			_ = "One landed on a dog. It looked so surprised.",
		}, "sparkle")
		s:mood("a", 3)
		s:log("{a} blew bubbles.")
		return s:done()
	end,
})

local NAPSPOTS = {
	"on a bench",
	"standing up at the bus stop",
	"in a deckchair at noon",
	"in a hammock with their shoes on",
	"under the big tree, mid sentence",
}

event({
	id = "napspot",
	when = "day",
	weight = W({ base = 0.12, traits = { lazy = 0.6 } }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "Asleep"):with({ spot = ctx.rng:pick(NAPSPOTS) })
		s:n("{a} has fallen asleep {spot}.")
		s:say("a", "Zzz... I'm awake. I'm listening. Zzz.", "zzz")
		s:by("a", {
			easygoing = "Five more minutes. Then five more.",
			proud = "I was resting my eyes. On purpose.",
			_ = "Was I asleep? I was not asleep.",
		}, "zzz")
		s:mood("a", 3)
		s:log("{a} fell asleep {spot}.")
		return s:done()
	end,
})

event({
	id = "homesick",
	cutscene = "pier",
	when = "any",
	weight = W({ base = 0.12 }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "Homesick")
		s:n("{a} is sitting on the wall by the sea, looking out.")
		s:by("a", {
			bold = "I miss my old street. Don't tell anyone I said that.",
			shy = "My old house had a blue door. I think about it sometimes.",
			proud = "Where I grew up, they had a statue of my gran. Small one.",
			_ = "I miss where I grew up, a bit. The smell of it.",
		}, "sad")
		s:choice("Tell me about it", function(c)
			c:n("{a} talked for a long time, mostly about a dog called Bean and a hill you could sledge down.")
			c:by("a", {
				bold = "Thanks. Don't tell anyone I got soppy.",
				shy = "Thanks for listening. I don't talk about it much.",
				proud = "Well. That was more than I meant to say.",
				_ = "Thanks. I haven't talked about it in ages.",
			}, "heart")
			c:mood("a", 5)
			c:hearts("a", 1)
			c:memo("a", "I told you about Bean, didn't I? The dog from home. Good dog.")
		end)
		s:choice("This is home now", function(c)
			c:say("a", "...Yeah. Yeah, it is. Thanks.", "heart")
			c:mood("a", 3)
		end)
		s:log("{a} felt a bit homesick.")
		return s:done()
	end,
})

event({
	id = "earlybird",
	when = "day",
	weight = W({ base = 0.15, traits = { lazy = 0.3 } }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "The early start")
		s:say("a", "I set three alarms to get up at five and go for a run.", "sweat")
		s:n("{a} switched off all three without waking up. It is now nearly lunch.")
		s:by("a", {
			easygoing = "I think my body made the right call.",
			proud = "My alarms are faulty. I'll be having words.",
			_ = "Tomorrow. Four alarms.",
		}, "zzz")
		s:mood("a", 1)
		s:log("{a} slept through three alarms.")
		return s:done()
	end,
})

event({
	id = "ears",
	when = "day",
	weight = W({ base = 0.1 }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "A hidden talent")
		s:say("a", "I just found out I can wiggle my ears. Look. LOOK.", "sparkle", "point")
		s:n("They can, just about.")
		s:by("a", {
			proud = "I've always been gifted. Now there's proof.",
			cheeky = "I'm going to do it at the worst possible moments.",
			shy = "I've never been good at anything this quickly.",
			_ = "What else can I do that I don't know about?",
		}, "music")
		s:mood("a", 4)
		s:memo("a", "Want to see me wiggle my ears? I've been practising.")
		s:log("{a} found out they can wiggle their ears.")
		return s:done()
	end,
})

event({
	id = "echo",
	when = "day",
	weight = W({ base = 0.1, traits = { social = 0.2 } }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "The echo")
		s:n("{a} climbed the hill and shouted HELLO at the cliffs.")
		s:n("The cliffs said HELLO back. Then, a moment later, a different voice said 'keep it down'.")
		s:by("a", {
			bold = "Who said that? Come out where I can see you.",
			shy = "Sorry. Sorry. Sorry, sorry. Sorry.",
			dreamy = "The hill has opinions. I like that in a hill.",
			_ = "I think there's somebody living up there.",
		}, "question")
		s:mood("a", 2)
		s:log("{a} shouted at the cliffs to hear the echo.")
		return s:done()
	end,
})

event({
	id = "rainbow",
	when = "day",
	weight = W({ base = 0.3, weather = "rain", traits = { focus = -0.2 } }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "A rainbow")
		s:n("The rain stopped for a minute, and a rainbow came out over the harbour.")
		s:by("a", {
			dreamy = "I'm going to find where it ends. Back by dinner.",
			proud = "It came out for me. Look how it points at me.",
			cheeky = "I'll race you to the end of it. Go.",
			_ = "Quick, look. Before it goes.",
		}, "sparkle", "point")
		s:mood("a", 4)
		s:log("{a} saw a rainbow.")
		return s:done()
	end,
})

local WORRIES = {
	"I think I left the iron on. I don't own an iron.",
	"What if the sea gets bored and leaves?",
	"I waved at someone and they weren't waving at me.",
	"I said 'you too' when the baker said 'enjoy your bread'.",
	"I can't remember if I locked the door. I've been back twice.",
}

event({
	id = "worry",
	when = "any",
	weight = W({ base = 0.2, traits = { brave = -0.3 } }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "A worry")
		s:say("a", ctx.rng:pick(WORRIES), "sweat")
		s:voice("a", "worry", "question")
		s:choice("It's not as bad as you think", function(c)
			c:by("a", {
				proud = "I wasn't worried. ...Okay, a bit.",
				easygoing = "Yeah. You're right. Too much effort anyway.",
				_ = "You think? Okay. Okay. I'll stop thinking about it.",
			}, "heart")
			c:mood("a", 4)
			c:hearts("a", 1)
		end)
		s:choice("Let's go and check", function(c)
			c:n("You went to check together. It was fine. It's always fine.")
			c:by("a", {
				shy = "Thanks. Sorry. I feel a bit silly.",
				proud = "I knew it was fine. I was checking you knew.",
				bold = "Right. Fine. Good.",
				_ = "Thanks. I feel a bit silly now.",
			}, "heart")
			c:mood("a", 5)
		end)
		s:log("{a} was worried about something small.")
		return s:done()
	end,
})

local FORTUNES = {
	"You will meet a tall stranger. They will be a lamppost.",
	"Good things come to those who nap.",
	"Today is a good day to eat a second biscuit.",
	"Somebody is thinking about you. It's the baker. You owe them money.",
	"The answer is yes. The question is soup.",
}

event({
	id = "fortune",
	when = "any",
	weight = W({ base = 0.12 }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "A fortune"):with({ fortune = ctx.rng:pick(FORTUNES) })
		s:n("{a} cracked open a fortune biscuit. The slip inside said:")
		s:n("'{fortune}'")
		s:by("a", {
			dreamy = "This is going to happen. I can feel it.",
			proud = "I make my own fortune, thank you.",
			cheeky = "I'm keeping this. It's going on the fridge.",
			_ = "That's oddly specific.",
		}, "question")
		s:mood("a", 2)
		s:log("{a} got a strange fortune.")
		return s:done()
	end,
})

local GADGETS = {
	"a toaster that butters too",
	"a hat with an umbrella on it",
	"a self stirring spoon",
	"shoes with little bells in",
}

event({
	id = "invention",
	when = "day",
	weight = W({ base = 0.1, traits = { focus = -0.2, mischief = 0.2 } }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "An invention"):with({ gadget = ctx.rng:pick(GADGETS) })
		s:say("a", "I've invented {gadget}. Watch.", "idea", "point")
		if ctx.rng:chance(0.35) then
			s:n("It worked. Everyone was as surprised as {a} was.")
			s:voice("a", "brag", "sparkle", "cheer")
			s:mood("a", 6)
		else
			s:n("There was a bang and a smell like burnt toast.")
			s:by("a", {
				proud = "Version two will be perfect.",
				easygoing = "Eh. Lunch anyway?",
				_ = "...Back to the drawing board.",
			}, "sweat")
			s:mood("a", -1)
		end
		s:log("{a} invented {gadget}.")
		return s:done()
	end,
})

event({
	id = "finishbook",
	when = "any",
	weight = W({
		base = 0.12,
		cond = function(ctx, a)
			return ctx.v(a).hobby == "reading" or ctx.rng:chance(0.5)
		end,
	}),
	scene = function(ctx, a)
		local s = K.scene(ctx, "The last page")
		s:n("{a} closed a very thick book and stared at the wall for a while.")
		s:by("a", {
			bold = "The dog lived. I had to sit down for that.",
			shy = "It's over. What do I do with my evenings now?",
			proud = "I saw the ending coming. Two hundred pages ago.",
			dreamy = "I want to live in it. Can I live in it?",
			_ = "Six hundred pages and they just got on a boat. A BOAT.",
		}, "sad")
		s:mood("a", 2)
		s:memo("a", "I finished that big book. I'm still thinking about the boat.")
		s:log("{a} finished a long book.")
		return s:done()
	end,
})

-- dreams and daydreams ------------------------------------------------------------------------------

local DAYDREAMS = {
	"sailing a boat to the little islet and finding a castle on it",
	"opening a café that only sells pudding",
	"being the first person to ride a gull",
	"winning a medal for the best nap",
	"the whole town throwing them a parade for no reason",
	"living in a lighthouse with a cat and a lot of books",
}

event({
	id = "daydream",
	cutscene = "dream",
	when = "day",
	weight = W({ base = 0.18, traits = { focus = -0.5 } }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "Miles away"):with({ dream = ctx.rng:pick(DAYDREAMS) })
		s:n("{a} has been staring at the same spot for ten minutes, smiling.")
		s:say("a", "Oh. Sorry. I was {dream}.", "zzz")
		s:by("a", {
			dreamy = "It was going so well. Can I go back?",
			proud = "It'll happen one day. Mark my words.",
			_ = "Was I gone long? I was gone long.",
		}, "sparkle")
		s:mood("a", 3)
		s:log("{a} was lost in a daydream.")
		return s:done()
	end,
})

event({
	id = "dreamfood",
	cutscene = "dream",
	when = "day",
	weight = W({ base = 0.12 }),
	scene = function(ctx, a)
		local fav = Foods.get(ctx.v(a).fav) or ctx.rng:pick(Foods.list)
		local s = K.scene(ctx, "A dream about food"):with({ food = fav.name:lower() })
		s:say("a", "I dreamed I lived in a house made of {food}. I ate the front door.", "zzz")
		s:by("a", {
			easygoing = "Best dream I've had all year.",
			proud = "Even in my dreams I have good taste.",
			_ = "I woke up so hungry.",
		}, "heart")
		s:mood("a", 2)
		s:log("{a} dreamed about {food}.")
		return s:done()
	end,
})

event({
	id = "dreamsong",
	cutscene = "dream",
	when = "day",
	weight = W({ base = 0.1, traits = { focus = -0.3 } }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "A song from a dream")
		s:say("a", "I heard a song in my dream. I have to sing it before it goes. La la LAA la.", "music")
		s:n("It sounded a lot like the bin lorry reversing.")
		s:by("a", {
			proud = "That's going to be famous.",
			shy = "It was better in the dream.",
			_ = "Hm. It's gone. Did you get it? Hum it back.",
		}, "question")
		s:mood("a", 2)
		s:log("{a} sang a song from a dream.")
		return s:done()
	end,
})

event({
	id = "futuretown",
	when = "day",
	weight = W({ base = 0.08 }),
	scene = function(ctx, a)
		local city = ctx.city()
		local s = K.scene(ctx, "Ten years from now")
		s:n("{a} was looking out over the rooftops.")
		if city.value > 20000 then
			s:say("a", "Imagine this place in ten years. It's big already. I want a tram.", "idea", "point")
		else
			s:by("a", {
				proud = "Imagine this place in ten years. More houses. A statue of me.",
				shy = "Imagine this place in ten years. More houses. More people, I suppose.",
				_ = "Imagine this place in ten years. More houses. A bigger bakery.",
			}, "idea", "point")
		end
		s:by("a", {
			gentle = "I hope we're all still here.",
			cheeky = "I want my name on something. A bench, at least.",
			proud = "I'd like a say in where things go, mind.",
			shy = "I hope there's still room for me.",
			_ = "You'll build it, won't you?",
		}, "heart")
		s:hearts("a", 1)
		s:log("{a} wondered what the town will be like in ten years.")
		return s:done()
	end,
})

event({
	id = "lemonade",
	cutscene = "stall",
	when = "day",
	weight = W({ base = 0.18, season = 2, weather = { "clear", "cloudy" } }),
	scene = function(ctx, a)
		local coins = ctx.rng:int(3, 8) * 5
		local s = K.scene(ctx, "Lemonade"):with({ coins = coins })
		s:prop("stall", "a")
		s:n("{a} has set up a lemonade stand on the corner.")
		s:by("a", {
			proud = "Finest lemonade on the island. Freshly squeezed by me.",
			shy = "Um. Lemonade? Only if you want. No pressure.",
			cheeky = "Half price if you can tell me what's in it. Nobody can.",
			bold = "LEMONADE. Cold. Get it here.",
			easygoing = "Lemonade. Leave the coins in the tin. I'm sitting down.",
			_ = "Cold lemonade here. Come and get some.",
		}, "music", "wave")
		s:n("By the afternoon the jug was empty and the tin was full.")
		s:coins(coins)
		s:mood("a", 4)
		s:log("{a} sold lemonade and made {coins} coins for the town.")
		return s:done()
	end,
})

-- A villager takes up a hobby on their own, and the town hears about it (the user: "make random
-- events where villagers pick up hobbies instead": a hobby was one of the thank yous you picked
-- at a new heart level). One a villager has already isn't picked again.
local TAKEN_UP = {
	gardening = "{a} has dug a patch behind the house and planted rows of something.",
	painting = "{a} bought a box of paints and has been down by the harbour with an easel.",
	guitar = "{a} found an old guitar at the market. You can hear it from the street.",
	fishing = "{a} borrowed a rod and has been on the pier since early this morning.",
	baking = "{a} has been baking every evening this week. The whole street smells of it.",
	stargazing = "{a} has been up on the hill after dark with a borrowed telescope.",
	jogging = "{a} has started running round the island before breakfast.",
	reading = "{a} came back from the library with an armful of books.",
	knitting = "{a} has been knitting on the bench by the square most afternoons.",
	birds = "{a} has started carrying a notebook and stopping to look at gulls.",
}

event({
	id = "takeuphobby",
	when = "day",
	weight = W({
		base = 0.16,
		cond = function(ctx, a)
			local v = ctx.v(a)
			for _, h in Sayings.hobbies do
				if h.id ~= v.hobby then
					return true
				end
			end
			return false
		end,
	}),
	scene = function(ctx, a)
		local v = ctx.v(a)
		local pool = {}
		for _, h in Sayings.hobbies do
			if h.id ~= v.hobby then
				table.insert(pool, h)
			end
		end
		local h = ctx.rng:pick(pool)
		local s = K.scene(ctx, "Something new")
		s:with({ hobby = h.name, Hobby = h.name:sub(1, 1):upper() .. h.name:sub(2) })
		s:n(TAKEN_UP[h.id] or "{a} has taken up {hobby}.")
		s:by("a", {
			sunny = "I've taken up {hobby}. I keep telling everyone about it, sorry.",
			gentle = "I've started {hobby}. It's nice to have something quiet for the evenings.",
			bold = "{Hobby}. Started this week. I'll be good at it by spring.",
			dreamy = "I've been doing {hobby}... the time sort of goes away when I do.",
			easygoing = "Took up {hobby}. Nothing serious. Just something to do.",
			proud = "I've taken up {hobby}. I'm told I have a gift for it.",
			shy = "Um. I've started {hobby}. I'm not very good yet. Don't watch.",
			cheeky = "{Hobby}. Don't laugh. Okay, you can laugh a bit.",
			_ = "I've started {hobby}. Still working it out.",
		}, "idea", "cheer")
		s:hobby("a", h.id)
		s:mood("a", 4)
		s:memo("a", "I took up {hobby} this week.")
		s:log("{a} took up {hobby}.")
		return s:done()
	end,
})

return list
