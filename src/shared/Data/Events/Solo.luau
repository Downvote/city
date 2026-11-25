--!nonstrict
-- Things one villager goes through: small odd days, hobbies, the weather, dreams and daydreams,
-- and the things they make (some of which they'll give you, as keepsakes). How they take it is
-- their own: Kit's s:by picks the line by their personality. They talk the way a friend texts
-- you: short bursts, two or three quick lines where one long one would do, and now and then
-- your name ({player}).

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
					shy = "You want it? Oh. Um. Okay... here.",
					proud = "Of course you want it. Look after it, {player}.",
					cheeky = "Fine. But I'm coming round to visit it. Hehe.",
					dreamy = "Mm. I think it wanted to go with you anyway.",
					bold = "Take it. It's yours.",
					easygoing = "Sure. Saves me finding a shelf.",
					gentle = "Of course, {player}. I'd like you to have it.",
					sunny = "Really? Yes! Here, here. Put it somewhere I can see it when I visit.",
					cool = "Sure. Here.",
					prickly = "...Fine. Take it. Don't read into it.",
					dramatic = "Then let it be known. It goes to {player}!",
					bookish = "Of course. Actually, it'll keep better indoors, out of the sun.",
					gloomy = "You want it? Huh. ...Okay. That's nice.",
					polite = "I'd be honoured. Thank you for asking, {player}.",
					foodie = "Sure. Bring me a biscuit next time and we're even.",
					nervous = "You're sure? You're really sure? Okay. Careful with it.",
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
					cheeky = "Good. I wasn't really going to give it away.",
					dreamy = "It can sit by the window and look out.",
					cool = "Okay. It can stay.",
					prickly = "Good. I like it more than I said.",
					dramatic = "Then it stays with its maker. As it should.",
					gloomy = "Okay. Somebody should like it, I guess. Me, then.",
					polite = "Thank you. I'll take good care of it.",
					nervous = "Phew. I'd have worried about it the whole time.",
					_ = "I'll find it a good spot at home, {player}.",
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
			shy = "Please don't look... hic.",
			bold = "I'll beat these. Hic. Watch me.",
			dreamy = "Each one's a little bubble. Hic. Pretty.",
			cheeky = "I'm doing it on purpose. Hic. Don't tell.",
			sunny = "{player}! Hic. Hi. Hic. Sorry. Hic.",
			cool = "Hic. ...Ignore that.",
			prickly = "Don't say anything. Hic. Not one word.",
			dramatic = "Three hours, {player}. Hic. Three hours of torment.",
			bookish = "Actually, it's a spasm of the diaphragm. Hic. Knowing doesn't help.",
			gloomy = "This is my life now. Hic.",
			polite = "Excuse me. Hic. I do beg your pardon.",
			foodie = "I ate my porridge too fast. Hic. Worth it, though.",
			nervous = "What if they never stop? Hic. Is that a thing?",
			_ = { "I'm fine. Hic. Totally fine.", "Three hours now. Hic. Three." },
		}, "sweat")
		s:choice("Give them a fright", function(c)
			c:n("You crept up behind {a} and shouted BOO.")
			c:by("a", {
				shy = "EEP. ...Oh. They've gone.",
				bold = "HA. You got me. And they've gone.",
				easygoing = "Whoa. Don't do that. ...Oh. They stopped.",
				cool = "...That was unnecessary. It worked, though.",
				prickly = "Was that really... oh. They've stopped. Hmph. Thanks.",
				dramatic = "My heart! ...My hiccups! Gone!",
				nervous = "AAH. Oh. Oh, my heart. ...They're gone?",
				_ = "Aah! ...Wait. They've stopped.",
			}, "sparkle")
			c:mood("a", 4)
			c:memo("a", "{player} scared my hiccups away yesterday. Rude. It worked, though.")
		end)
		s:choice("Drink water upside down", function(c)
			c:n("{a} bent over and drank from the far side of the glass.")
			c:say("a", "Glug. Hic. Glug...", "sweat")
			c:say("a", "Now I'm wet. And I've still got them.", "sad")
			c:mood("a", -1)
			c:memo("a", "Never drink water upside down. Trust me on this.")
		end)
		s:choice("Hold your breath", function(c)
			c:say("a", "Mmmmmmf.", "question")
			c:say("a", "...Gone? I think they're gone.", "sparkle", "cheer")
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
		s:say("a", "{player}. I've decided.", "idea", "point")
		s:say("a", "I'm taking up {hobby}.", "idea")
		s:by("a", {
			bold = "Starting today. No point waiting.",
			shy = "Is that silly? I've wanted to for ages...",
			cheeky = "Don't laugh. I can see you about to laugh.",
			sunny = "I've told everyone already, so now I have to!",
			easygoing = "Seems relaxing. Mostly sitting, I hope.",
			dreamy = "It came to me in a dream. Well. A nap.",
			proud = "I expect I'll be a natural.",
			cool = "Seemed worth a go.",
			prickly = "Don't make a thing of it.",
			dramatic = "A new chapter begins. Today.",
			bookish = "I've already read two books about it. Now the doing part.",
			gloomy = "I'll probably be bad at it. Still.",
			polite = "If you've any tips, I'd be grateful.",
			foodie = "Is there a snack that goes with it? There should be.",
			nervous = "What if I'm terrible? Tell me if I'm terrible.",
			_ = "I bought everything for it already. Don't tell me it's silly, {player}.",
		}, "sparkle")
		s:choice("Go for it", function(c)
			c:by("a", {
				easygoing = "Right. Starting now. After a snack.",
				shy = "Okay. I'll try it.",
				proud = "Watch. I'll be good at this.",
				prickly = "I was going to anyway. ...Thanks.",
				nervous = "Okay. Okay okay. Going for it.",
				gloomy = "Okay. If you say so, {player}.",
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
				shy = "Okay... it was a silly idea.",
				dramatic = "Another dream, folded away. Fine.",
				cool = "Fair.",
				_ = "Hm. Maybe you're right, {player}.",
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
		s:say("a", "The other blue one's gone.", "question")
		s:say("a", "I've checked everywhere. Even the fridge.", "question")
		s:by("a", {
			proud = "I'm starting a new fashion. Odd socks. You saw it here first.",
			dreamy = "Maybe it went on a trip. I hope it's having fun...",
			cheeky = "Somebody in this town steals socks. I'll find out who.",
			gentle = "Oh well. This one's warm too.",
			sunny = "Have you seen it, {player}? Blue. Sort of sad looking.",
			cool = "It'll turn up. Or it won't.",
			prickly = "Whatever. Nobody looks at socks.",
			dramatic = "Gone. Without a word. After everything we walked through.",
			bookish = "Actually, people lose about one sock a month. I looked it up.",
			gloomy = "Things go. That's what they do.",
			foodie = "Why did I look in the fridge? ...Since I'm here, though.",
			nervous = "What if it's in the wash with someone else's things? That'd be so awkward.",
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
		s:say("a", "Dum da dum DUM. Dum da dum DUM.", "music")
		s:by("a", {
			cool = "Make it stop.",
			prickly = "If you hum it too I'm leaving.",
			nervous = "Is it annoying? It's annoying, isn't it. Sorry.",
			dramatic = "It haunts me, {player}. Day and night.",
			_ = "Make it stop, {player}. Please.",
		}, "sweat")
		s:choice("Hum along", function(c)
			c:by("a", {
				cheeky = "Oh, you're doing harmonies now? Hehe.",
				sunny = "Ha! Now it's both of us.",
				cool = "...Not bad.",
				prickly = "Great. Now it's both of us. Thanks a lot.",
				_ = "Now we've both got it. Thanks a lot.",
			}, "music", "laugh")
			c:mood("a", 3)
		end)
		s:choice("Hum them a different song", function(c)
			c:n("You hummed something else. {a} listened, very still.")
			c:say("a", "Oh no. Now I've got yours.", "sweat")
			c:say("a", "...It's better, though. Thanks, {player}.", "music")
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
			shy = "I didn't mean for it to get this big...",
			easygoing = "I just kept watering it and it kept going.",
			sunny = "{player}, come look! It's got its own shadow now!",
			cool = "It's big.",
			prickly = "Don't touch it. ...You can pat it. Once.",
			dramatic = "Behold. The pride of the island.",
			bookish = "Actually, it's technically a fruit. A very large fruit.",
			gloomy = "Something'll eat it before the show. You watch.",
			foodie = "I'm thinking soup. Or stuffed. Or soup AND stuffed.",
			nervous = "What if it keeps growing? Where does it stop?",
			_ = "I don't know what to do with it, {player}. I just wanted to see how big it'd get.",
		}, "sparkle", "point")
		s:choice("Keep watering it", function(c)
			c:by("a", {
				proud = "It can go bigger. I know it can.",
				dreamy = "Grow, marrow. Grow...",
				_ = "More water, then. Let's see how far it goes.",
			}, "sparkle", "cheer")
			c:leave("marrow", 18, "a")
			c:mood("a", 5)
			c:memo("a", "The marrow's still growing. I've had to move the fence.")
		end)
		s:choice("Make soup for everyone", function(c)
			c:by("a", {
				foodie = "Yes. Yes! I'll get the big pot. And bread. And more bread.",
				gloomy = "Soup. Okay. At least nothing will eat it now.",
				_ = "Soup for everyone, then. I'll need the big pot.",
			}, "heart")
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
		{ "a", "Second place.", "sparkle" },
		{ "a", "The winner's marrow had a hat on. I think that swung it.", "sweat" },
	},
	react = {
		proud = "Second is the first of the losers. I'll be back next year.",
		easygoing = "Second's great. Less pressure than first.",
		shy = "I nearly didn't go... I'm glad I did.",
		bold = "Second. Next year I'm winning it.",
		cool = "Second's fine.",
		prickly = "A hat. On a marrow. Whatever. I'll take second.",
		dramatic = "Robbed, {player}. Robbed by a hat.",
		gloomy = "I expected last. So this is a lot.",
		polite = "The judges were very kind. I sent them a note.",
		nervous = "My hands were shaking the whole time. But second!",
		_ = "Second place, {player}. I'll take that.",
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
			shy = "Don't look. Please don't look...",
			proud = "It's meant to be like this. It's a style.",
			cheeky = "I meant to do that. The left side, anyway.",
			easygoing = "Eh. It'll grow.",
			bold = "Did it myself. Went a bit far.",
			dreamy = "I was thinking about something else while I cut it.",
			sunny = "{player}! Be honest. No, wait. Be nice.",
			cool = "It happened.",
			prickly = "Say one thing about it. I dare you.",
			dramatic = "Disaster. A total disaster. I can never go outside again.",
			bookish = "Hair grows about a centimetre a month. So. Four months.",
			gloomy = "It was always going to go like this.",
			polite = "I'm so sorry you have to look at this.",
			nervous = "Is it bad? It's bad. How bad is it?",
			_ = "Is it bad? Be honest. No, don't be honest.",
		}, "sweat")
		s:choice("It suits you", function(c)
			c:by("a", {
				proud = "I know.",
				shy = "Really? You're not just saying that?",
				prickly = "...You're just saying that. ...Thanks.",
				gloomy = "Huh. Okay. Maybe it's not the worst.",
				nervous = "Oh thank goodness. Really? Okay. Phew.",
				_ = "Really, {player}? Okay. I'm keeping it.",
			}, "heart")
			c:mood("a", 5)
			c:hearts("a", 1)
		end)
		s:choice("A hat for a week, maybe", function(c)
			c:by("a", {
				proud = "It's not that bad. ...Fine. Where's my hat.",
				easygoing = "Fair. I've got a hat somewhere.",
				dramatic = "A hat. A HAT. ...Yes, all right. A hat.",
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
			shy = "Sorry. Sorry, cat. Sorry...",
			bold = "Bless me. Thanks, cat.",
			cheeky = "Ten out of ten jump, honestly.",
			gentle = "Oh, you poor thing. I didn't mean it.",
			dreamy = "It thinks I'm a thundercloud now.",
			cool = "...It'll get over it.",
			prickly = "Don't look at me like that. You were on MY wall.",
			dramatic = "It will never forgive me. Never.",
			polite = "I do apologise. That was very rude of me.",
			nervous = "Is it okay? Did it land okay? It landed okay.",
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
			shy = "Don't read it... It's mostly about the weather. And, um. Other things.",
			proud = "My memoirs. They'll be worth a fortune one day.",
			cheeky = "Half of it's made up. Yesterday I won a boat race, apparently.",
			cool = "Diary. Private.",
			prickly = "What. People write things down. It's normal.",
			dramatic = "Every word of it true. Every tear. Most of the tears.",
			bookish = "I've kept one since I was eight. Forty one notebooks.",
			gloomy = "Today: rain. Tomorrow: probably rain.",
			polite = "I hope you don't mind. It's how I end the day.",
			_ = "It's my diary. Every day since I moved in.",
		}, "sweat")
		s:choice("Sneak a look", function(c)
			if ctx.rng:chance(0.5) then
				c:n("You leaned over. The page said 'Today was nice. Saw the sea. Had a bun.'")
				c:say("a", "Hey! ...Well. That's all it says.", "sweat")
				c:say("a", "It was a good bun.", "heart")
				c:mood("a", -1)
			else
				c:n("{a} snapped the book shut before you got close.")
				c:by("a", {
					bold = "Oi. Nice try.",
					shy = "Th-that's private.",
					gentle = "Not that one, {player}. Please.",
					cool = "No.",
					prickly = "Absolutely not. Go away. ...Night.",
					dramatic = "How dare you! ...Hehe. Nice try, though.",
					_ = "Nice try.",
				}, "anger")
				c:mood("a", -5)
			end
		end)
		s:choice("Leave them to it", function(c)
			c:say("a", "Thanks, {player}. I'll write that you were nice.", "heart")
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
		s:say("a", "That one's {one}.", "idea", "point")
		s:say("a", "And that one's... {two}.", "idea")
		s:by("a", {
			dreamy = "I could stay here till they all turn into something.",
			easygoing = "Best way to spend an afternoon. Don't tell anyone.",
			bold = "I've been here an hour. Is that allowed?",
			cheeky = "That one looks like you, {player}. The grumpy one.",
			shy = "I don't usually do this where people can see...",
			cool = "Good sky today.",
			prickly = "Don't stand there. Lie down or move.",
			bookish = "Those are cumulus. Actually, the flat one is stratus.",
			gloomy = "That one looks like rain. They all do, after a while.",
			foodie = "That one's a bun. That one's also a bun. I'm hungry.",
			_ = "Come and lie down, {player}. There's room.",
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
			cool = "...You didn't see this.",
			prickly = "What? It's raining. This is what it's for.",
			dramatic = "The biggest splash this street has ever seen!",
			gloomy = "My boots leak anyway. Might as well.",
			nervous = "Is this allowed? It's allowed, right? Splash.",
			_ = { "SPLASH. Did you see that one, {player}?", "Biggest puddle wins. That one. Watch." },
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
			sunny = "{player}! Meet my new friend. Say hi!",
			cool = "Built a snowman.",
			prickly = "He's lopsided. Don't say it.",
			dramatic = "He stands tall against the winter. My finest work.",
			gloomy = "He'll melt by Thursday. Still. Look at him.",
			foodie = "I gave him a biscuit for buttons. Then I ate one. He has two buttons.",
			_ = "Doesn't he look smart, {player}? I lent him my scarf.",
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
			sunny = "Jump with me, {player}! On three!",
			cool = "One jump.",
			prickly = "I raked all that. I'm jumping in it. Don't argue.",
			dramatic = "For autumn!",
			nervous = "What if there's a hedgehog in there? ...I checked. Twice.",
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
			shy = "Everyone's going to see... Can I borrow a hat?",
			cool = "Half a tan. Fine.",
			prickly = "Don't laugh. It stings.",
			dramatic = "I'm cooked, {player}. Like a sausage.",
			bookish = "I knew about sun cream. I read about it. I didn't wear it.",
			gloomy = "Of course it was only one side.",
			foodie = "I look like a radish. A nice radish, though.",
			_ = "Only one side. I look like a radish.",
		}, "sweat")
		s:choice("Get them some aloe", function(c)
			c:by("a", {
				polite = "Oh, that's very kind. Thank you so much.",
				prickly = "...That helps. Fine. Thanks.",
				_ = "Ooh, that's cool. Thank you, {player}.",
			}, "heart")
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
		s:say("a", "Look how high it is!", "sparkle", "point")
		s:say("a", "I can feel it pulling.", "sparkle")
		if ctx.rng:chance(0.4) then
			s:n("Then the wind dropped, and the kite went nose first into the top of a tree.")
			s:by("a", {
				bold = "I'm going up. Hold my shoes.",
				shy = "Oh no. Oh no no...",
				cheeky = "Well, the tree's having a nice time.",
				cool = "...Great.",
				prickly = "Of course. Of COURSE.",
				dramatic = "Taken from me! By a tree!",
				gloomy = "Knew that would happen.",
				nervous = "Can we get it? Can we? It's not broken, is it?",
				_ = "...Well. It's up there, at least.",
			}, "sweat")
			s:choice("Help them get it down", function(c)
				c:n("With a long stick and a lot of jumping, the kite came down with only one small hole.")
				c:say("a", "Thanks, {player}. There's a hole now. It'll still fly.", "heart")
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
		s:say("a", "{player}. I've found a new star.", "idea", "point")
		s:say("a", "It's moving, though. And blinking.", "question")
		s:by("a", {
			proud = "I'm naming it after myself, obviously.",
			dreamy = "Maybe it's a star that wants to go somewhere.",
			cheeky = "It's a plane. I know it's a plane. Let me have this.",
			cool = "Plane.",
			bookish = "Stars don't blink like that. Actually, nothing does but planes.",
			dramatic = "A new star, born tonight! ...With little lights on its wings.",
			gloomy = "It's a plane. Things are usually planes.",
			_ = "...It might be a plane, {player}.",
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
			cheeky = "I'm not sleeping. I'm planning things. Hehe.",
			shy = "I keep thinking about what I said today...",
			sunny = "{player}? You up too? Oh good. Talk to me.",
			cool = "Can't sleep. Whatever.",
			prickly = "Don't ask. I just can't.",
			dramatic = "The night is long, {player}. So long.",
			bookish = "I read that counting backwards works. I'm at minus forty.",
			gloomy = "I'll be tired all day tomorrow. Great.",
			foodie = "I'm thinking about toast. I can't stop thinking about toast.",
			nervous = "Did I lock the door? I locked it. Did I? I'll check again.",
			_ = {
				"I've counted to four hundred sheep. They're getting bored too.",
				"Every time I close my eyes I remember something.",
			},
		}, "zzz")
		s:choice("Warm milk", function(c)
			c:say("a", "Mm. Warm...", "zzz")
			c:say("a", "Sleepy. Night, {player}.", "zzz")
			c:mood("a", 4)
		end)
		s:choice("Tell them a story", function(c)
			c:n("You started a story about a lighthouse keeper. {a} was asleep before the boat came in.")
			c:mood("a", 5)
			c:hearts("a", 1)
			c:memo("a", "You never finished that lighthouse story, {player}. Did the boat come in?")
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
		s:say("a", "Oh. {player}. Hi.", "sweat")
		s:say("a", "I'm not eating {food}. I'm checking it's still there.", "sweat")
		s:by("a", {
			proud = "A chef has to test things at all hours.",
			easygoing = "Best meal of the day, this one.",
			shy = "Please don't tell anyone...",
			cheeky = "You didn't see anything. Hehe.",
			bold = "I was hungry. So what.",
			cool = "You want some?",
			prickly = "Don't look at me like that. Everyone does it.",
			dramatic = "It called to me, {player}. What could I do?",
			bookish = "Actually, a small snack helps you sleep. There's research.",
			gloomy = "I'll regret this in the morning. Mm. Not yet, though.",
			polite = "Would you like some? I'd feel rude eating alone.",
			foodie = "It's better at night. Everything is. Science.",
			nervous = "Is it too late to eat? It's too late. It's fine. Is it?",
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
			cool = "Bad dream. It's fine.",
			prickly = "The bakery was shut. Forever. Don't laugh.",
			dramatic = "The sea came up the street and took my house, {player}. My HOUSE.",
			bookish = "The library had no books. Only empty shelves. Rows and rows.",
			gloomy = "I dreamed it was sunny and everyone was happy. Then I woke up.",
			polite = "I forgot to thank someone. I don't know who. It was awful.",
			foodie = "Every pie in town was empty. Just crust. Crust everywhere.",
			nervous = "I dreamed I left the oven on. I don't even have an oven on.",
			_ = "I dreamed my house floated away and I couldn't catch it.",
		}, "sad")
		s:choice("It was only a dream", function(c)
			c:by("a", {
				bold = "Yeah. I know. ...Stay a bit, though?",
				proud = "Obviously. I wasn't scared.",
				shy = "Can you stay? Just till I'm sleepy?",
				prickly = "I know that. ...You can stay a minute. If you want.",
				gloomy = "Yeah. ...Thanks for coming, {player}.",
				_ = "I know. Can you stay till I'm sleepy again, {player}?",
			}, "heart")
			c:mood("a", 4)
			c:hearts("a", 1)
		end)
		s:choice("Leave the light on", function(c)
			c:say("a", "Okay. Light on.", "zzz")
			c:say("a", "That's better.", "zzz")
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
			cool = "Doing fine. Keep going.",
			prickly = "Grow. I'm not asking twice. ...Please.",
			dramatic = "Rise, little fern! Reach for the sun!",
			bookish = "Actually, they like the carbon dioxide. So, talk more.",
			gloomy = "Don't die. Everything else does. Not you.",
			polite = "Good morning. Thank you for growing.",
			foodie = "When you're a tomato you'll be the best tomato.",
			nervous = "Too much water? Not enough? Tell me. Please tell me.",
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
			dramatic = "Friends. Neighbours. Gulls. I stand before you humbled.",
			bookish = "Thank you. I'll be brief. There are only nine parts.",
			polite = "Thank you, all of you. And thank you to the mirror.",
			_ = "Thank you, thank you. I'd like to thank... um. Everybody.",
		}, "sparkle", "point")
		s:by("a", {
			shy = "Oh no. You heard that. I'm going to go and hide now.",
			proud = "Pretty good, right? I'll take questions now.",
			cool = "...How long were you there.",
			prickly = "You saw nothing. Got it, {player}?",
			nervous = "How long have you been standing there? Was it bad?",
			_ = "It's for nothing. I just like to be ready.",
		}, "sweat")
		s:choice("Clap", function(c)
			c:by("a", {
				shy = "Oh. Um. Thank you...",
				proud = "Thank you. Yes. Keep going.",
				cheeky = "Louder. I can't hear you.",
				dramatic = "Thank you! You're too kind! Encore? No? Fine.",
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
		s:say("a", "New me, {player}.", "idea", "point")
		s:say("a", "Fifty push ups every morning. Starting today.", "idea")
		if K.isPers(ctx, a, "bold") then
			s:n("{a} did fifty. Then fifty more. Then went for a run.")
			s:say("a", "That was the warm up.", "sparkle", "cheer")
			s:mood("a", 5)
		else
			s:n("{a} did four. Then had a lie down on the grass.")
			s:by("a", {
				easygoing = "Four is a lot of push ups. For me.",
				proud = "Four perfect ones. Quality, not quantity.",
				cool = "Four. Good enough.",
				dramatic = "I gave everything. All four of them.",
				gloomy = "Four. Knew it.",
				foodie = "I've earned a bun. Four push ups is a bun.",
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
			shy = "It's from my best friend back home. She still remembers me...",
			proud = "Someone from my old town says they miss me. Of course they do.",
			dreamy = "It smells like where I grew up. Salt and toast.",
			cool = "Old friend. They're doing well.",
			prickly = "They wrote. Huh. ...Took them long enough.",
			dramatic = "Eight pages, {player}! Eight! From the dearest friend I ever had!",
			gloomy = "I thought they'd forgotten me. They hadn't.",
			polite = "How thoughtful of them. I must reply properly.",
			nervous = "What if it's bad news? ...It's not. Phew. It's a cat drawing.",
			_ = "It's from an old friend, {player}. They're doing well. They drew me a cat.",
		}, "heart")
		s:choice("Write back today", function(c)
			c:say("a", "I will. I'll tell them all about this place.", "heart", "cheer")
			c:mood("a", 6)
			c:memo("a", "I wrote back to my old friend. I told them about you, {player}.")
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
			cool = "Huh.",
			prickly = "I didn't order this. Who sends things without asking?",
			dramatic = "A mystery, {player}! On my own doorstep!",
			bookish = "No stamp from here. It came on the ferry, then.",
			gloomy = "It's probably a bill. In a box.",
			foodie = "Shake it. Does it sound like biscuits? It sounds like biscuits.",
			nervous = "Should I open it? What if it ticks? It doesn't tick. Okay.",
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
			c:say("a", "Good idea. Tea first. Then the parcel.", "music")
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
			shy = "Of course. Of course this happens today...",
			easygoing = "Eh. It was getting cold anyway.",
			cheeky = "Tea shirt. Get it? Tea shirt.",
			cool = "...Hm.",
			prickly = "Don't. Say. Anything.",
			dramatic = "My good shirt, {player}. My GOOD shirt.",
			gloomy = "Yep. That's the day, then.",
			polite = "Oh dear. I'm so sorry, did any get on you?",
			foodie = "What a waste of tea. That was a nice tea.",
			nervous = "Is it hot? It's not hot. Okay. Okay, I'm fine.",
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
		s:say("a", "Nobody's ever put these two together.", "idea")
		s:by("a", {
			foodie = "Which is mad. Look at them. They belong together.",
			bookish = "Actually, someone tried in a cookbook from 1902. It said 'no'.",
			nervous = "Is there a reason nobody has? There's a reason, isn't there.",
			cool = "Let's see why.",
			_ = "Let's see why.",
		}, "idea")
		s:choice("Taste it", function(c)
			if ctx.rng:chance(0.5) then
				c:n("It was... good. Weirdly good.")
				c:voice("a", "excited", "sparkle", "cheer")
				c:mood("a", 5)
				c:memo("a", "My {one} and {two} thing worked. I'm making it again on Sunday.")
			else
				c:n("You chewed slowly. {a} watched your face.")
				c:say("a", "That bad?", "sweat")
				c:say("a", "That bad. I'll write 'no' next to it.", "sweat")
				c:mood("a", -1)
			end
		end)
		s:choice("Let them try it first", function(c)
			c:n("{a} took a big bite, paused, and quietly put the spoon down.")
			c:say("a", "We'll never speak of this, {player}.", "sweat")
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
			shy = "It's not finished. Well. It might be. I can't tell...",
			dreamy = "I'm painting what the sea would look like if it was happy.",
			cool = "Almost done.",
			prickly = "Don't hover. ...Okay, you can look. Quickly.",
			dramatic = "Stand back, {player}. Art is happening.",
			bookish = "I'm trying the old way. Thin layers, a day apart.",
			gloomy = "It's the harbour on a grey day. So, most days.",
			foodie = "It's a bowl of fruit. I've eaten two of the models.",
			nervous = "Don't look yet. Okay, look. No, wait. Okay. Look.",
			_ = "Hold still, {player}. I might put you in it.",
		}, "sparkle")
		s:choice("Could you paint me?", function(c)
			c:n("{a} had you sit on a crate for an hour. Then they turned the canvas round.")
			c:by("a", {
				shy = "It's you. I mean... it's meant to be. You can keep it.",
				proud = "There. You've never looked better. Keep it.",
				cheeky = "I gave you a bigger nose. Artist's choice. Keep it.",
				prickly = "It's you. Take it before I change my mind.",
				dramatic = "Behold! {player}, as the ages shall remember you!",
				polite = "Thank you for sitting so still. Please, it's yours.",
				_ = "There. It's you, {player}. Keep it.",
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
		{ "a", "It's a bit lopsided.", "sparkle", "point" },
		{ "a", "That's the handmade look.", "sparkle" },
	},
	react = {
		proud = "Best pot on the island. I've seen the others.",
		shy = "It's my first one. Is it all right?",
		cool = "It holds water. Mostly.",
		prickly = "It's wonky on purpose. Obviously.",
		bookish = "People have made pots this way for eight thousand years. Now me.",
		foodie = "It's a soup pot. I'm going to make soup in it.",
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
		{ "a", "It's a bird.", "question" },
		{ "a", "You can tell it's a bird, right?", "question" },
	},
	react = {
		cheeky = "I was going for a duck. It got ideas.",
		bold = "Took three bits of wood. Snapped the first two.",
		cool = "It's a robin.",
		gloomy = "It looks a bit sad. Like me. I like it.",
		nervous = "I only cut myself twice. That's good, right?",
		dramatic = "It sings, {player}. In its own wooden way.",
		_ = "I think it's the nicest thing I've ever made, {player}.",
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
		{ "a", "Every patch is something.", "heart", "point" },
		{ "a", "That one's from my favourite shirt.", "heart" },
	},
	react = {
		gentle = "I sewed a heart in the middle. For whoever sleeps under it.",
		proud = "Two hundred stitches. I counted every one.",
		polite = "I do hope it keeps someone warm.",
		prickly = "Took forever. Don't tell me it's nice. ...It's nice, right?",
		_ = "It took all autumn. I kept pricking my fingers.",
	},
	memo = "That quilt took me weeks. Are you warm enough at night, {player}?",
	log = "{a} finished a patchwork quilt.",
})

makes({
	id = "bottleship",
	title = "A ship in a bottle",
	item = "keep_boat",
	w = { base = 0.06, traits = { focus = 0.4 } },
	lines = {
		{ "n", "{a} is holding a bottle up to the light. There's a little ship inside." },
		{ "a", "Don't ask how I got it in.", "sparkle" },
		{ "a", "I don't know either.", "sweat" },
	},
	react = {
		dreamy = "I like to think it's sailing somewhere small.",
		proud = "It takes patience. And steady hands, which I have.",
		bookish = "The mast folds down, then you pull a thread. Actually, it's quite clever.",
		cool = "Took a while.",
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
		{ "a", "One shell for every nice day.", "music", "point" },
		{ "a", "I've run out of room.", "music" },
	},
	react = {
		dreamy = "If you hold one to your ear you can hear Tuesday.",
		cheeky = "One of them was a crab. I put him back. He was cross.",
		gloomy = "I counted. More nice days than I thought.",
		sunny = "Look, {player}, this one's pink inside!",
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
		polite = "I left a little dish of seeds. It seemed only proper.",
		nervous = "Do you think it likes it? It hasn't said. It's a bird.",
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
		{ "a", "I made a wind chime from old pipes.", "music" },
		{ "a", "Listen. Ting.", "music" },
	},
	react = {
		dreamy = "The wind plays it better than I could.",
		easygoing = "Music I don't have to play. Perfect.",
		cool = "Nice sound.",
		bookish = "Each length gives a note. I worked them out on paper first.",
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
		{ "a", "This one's the best.", "heart", "point" },
		{ "a", "It has a heart on it. And some dots.", "heart" },
	},
	react = {
		shy = "The heart's a bit wonky... is that all right?",
		cheeky = "There's a secret message on the bottom. Don't look yet.",
		foodie = "It's exactly the right size for soup. I tested it.",
		prickly = "The dots were an accident. Now they're on purpose.",
		_ = "Tea tastes better out of a mug someone made for you.",
	},
	memo = "Are you drinking out of the mug I painted, {player}? Say yes.",
	log = "{a} painted a mug.",
})

makes({
	id = "pressing",
	title = "Pressed flowers",
	item = "keep_flowers",
	w = { base = 0.08, season = { 1, 2 }, traits = { kind = 0.2 } },
	lines = {
		{ "n", "{a} has a heavy book on the table with flowers sticking out of it." },
		{ "a", "I've been pressing flowers from the hill.", "sparkle" },
		{ "a", "These are ready.", "sparkle" },
	},
	react = {
		gentle = "I framed them, so they'll keep.",
		dreamy = "They're asleep. Flat and asleep.",
		bookish = "I used the dictionary. It's the heaviest book I own.",
		gloomy = "They'll last longer like this. Longer than most things.",
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
		{ "a", "It's a lantern.", "sparkle" },
		{ "a", "It folds flat, then it doesn't. Look.", "sparkle" },
	},
	react = {
		shy = "I like the light it makes. Soft.",
		bold = "I set fire to the first one. This one's fine.",
		nervous = "The candle's a little one. I checked. It's safe. I checked twice.",
		cool = "Good light.",
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
		{ "a", "I was knitting a scarf.", "sweat" },
		{ "a", "Then it was a cushion.", "sweat" },
	},
	react = {
		easygoing = "It's good for naps. I've checked.",
		proud = "Three cables. Do you know how hard cables are?",
		dramatic = "It began as a scarf. It became something greater.",
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
		{ "a", "It's a gull.", "sparkle", "point" },
		{ "a", "Made of driftwood. With a float for a head.", "sparkle" },
	},
	react = {
		cheeky = "It's even got the gull look. The 'give me your chips' look.",
		dreamy = "The sea made the wood. I only put it together.",
		foodie = "It's guarding my lunch. It's better at it than me.",
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
		{ "a", "There's a tiny house in it. With a tiny tree.", "sparkle" },
		{ "a", "I made all of it.", "sparkle" },
	},
	react = {
		gentle = "It's for when it's cold out. You can shake it by the fire.",
		cheeky = "I nearly glued my finger in there.",
		gloomy = "It's always winter in there. I find that sort of calming.",
		sunny = "Shake it, {player}! Go on!",
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
			shy = "Nobody saw that. Please say nobody saw that...",
			bold = "The ground started it.",
			cool = "...Meant to do that.",
			prickly = "What are you looking at? Keep walking, {player}.",
			dramatic = "I have fallen! Before the whole town!",
			gloomy = "Yep. Floor. Hello again.",
			polite = "Oh, excuse me. Sorry. Sorry, everyone.",
			nervous = "Did anyone see? Did YOU see? Okay. Okay.",
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
			shy = "It's sweet. I think. It won't stop looking at me...",
			bold = "I've got a sidekick now.",
			cheeky = "I gave it one crumb. One. Now it thinks it lives with me.",
			cool = "It's fine. It can stay.",
			prickly = "Shoo. ...Fine. Don't shoo.",
			dramatic = "A loyal companion, {player}! It chose ME!",
			gloomy = "First friend I've made all week. It's a pigeon.",
			foodie = "It likes the same bakery as me. Respect.",
			nervous = "Does it want something? What does it want?",
			_ = "It's a friend now. It needs a name, {player}.",
		}, "question")
		for i = 1, 3 do
			local name = names[i]
			s:choice(name, function(c)
				c:with({ pet = name })
				c:say("a", "{pet}. Perfect.", "heart", "cheer")
				c:say("a", "Hello, {pet}.", "heart")
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
			cool = "It stays. Needs a name.",
			prickly = "I didn't invite it. ...I bought it a bowl. Don't read into it.",
			bookish = "Cats pick their people, actually. Not the other way round.",
			gloomy = "It'll leave. They always... oh. It's still here.",
			polite = "I'd be honoured if you'd help me name it, {player}.",
			_ = "I think I have a cat now. Help me name it, {player}?",
		}, "heart")
		for i = 1, 3 do
			local name = names[i]
			s:choice(name, function(c)
				c:with({ pet = name })
				c:say("a", "{pet}. Yes.", "heart", "cheer")
				c:say("a", "You look like a {pet}.", "heart")
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
			shy = "I'm moving house. That's it. It can have the house...",
			proud = "I'm not scared. I'm letting it have the bath. As a guest.",
			cheeky = "I'm going to put it in someone's shoe. ...Kidding.",
			dreamy = "Do you think it has a name? It looks like a Clive.",
			sunny = "{player}! {player}, come here. Bring a cup. Quickly!",
			cool = "Big one. Hm.",
			prickly = "It can't stay. ...It can stay till I find a cup.",
			dramatic = "A beast, {player}! A beast in my bath!",
			bookish = "That's a house spider. Actually, they eat the flies. Still.",
			gloomy = "Of course it's in the bath. Where else would it be.",
			polite = "Excuse me. Sorry. Would you mind terribly moving?",
			foodie = "It's bigger than a meatball. Why did I think of a meatball.",
			nervous = "Don't move. Is it moving? It's moving. Don't move.",
			_ = "Can someone else deal with this? {player}? Anyone?",
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
				nervous = "Okay. Okay. I'll just... never go in there again.",
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
		s:say("a", "Found a coin on the way out.", "sparkle", "cheer")
		s:say("a", "Then another one by the fountain.", "sparkle")
		s:by("a", {
			proud = "The world's finally caught up with me.",
			dreamy = "I think the sky likes me today.",
			cool = "Not bad.",
			gloomy = "Something bad's coming. ...Nothing yet, though.",
			dramatic = "Fortune smiles on me, {player}! Today, at least!",
			nervous = "Should I give them back? Who would I give them to?",
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
			cool = "...Today's cancelled.",
			prickly = "Don't. Just don't, {player}.",
			dramatic = "The universe has turned against me!",
			gloomy = "This is just a normal day for me.",
			foodie = "The toast. The poor toast.",
			nervous = "What's next? Don't say. Don't tempt it.",
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
		s:say("a", "{player}, guess what.", "sparkle", "point")
		s:say("a", "I've started collecting {things}. I've got eleven already.", "sparkle")
		s:by("a", {
			proud = "It'll be the finest collection on the island.",
			dreamy = "Each one has a story. I make them up.",
			cheeky = "Some of them were in other people's drawers. I'll give them back.",
			cool = "Eleven's a start.",
			prickly = "It's a normal hobby. Stop smiling like that.",
			bookish = "I've labelled each one. Date found, place, condition.",
			gloomy = "Nobody else wants them. So.",
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
			shy = "I've scrubbed it four times... it's still there.",
			cool = "It's staying, apparently.",
			dramatic = "I am a new person now, {player}. A person with a moustache.",
			nervous = "What if it never comes off? What if this is my face now?",
			_ = "I'll have to wear it to work. Tell me it suits me, {player}.",
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
			shy = "That's all I've got so far... was it all right?",
			cool = "Rough draft.",
			dramatic = "There are eleven verses, {player}. You've heard one.",
			foodie = "The bread line's my favourite. Obviously.",
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
			cool = "Pop.",
			gloomy = "They don't last. Nice while they do.",
			sunny = "Catch one, {player}! Ooh, nearly.",
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
			cool = "...I'm up.",
			prickly = "I wasn't asleep. Stop smiling, {player}.",
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
			shy = "My old house had a blue door... I think about it sometimes.",
			proud = "Where I grew up, they had a statue of my gran. Small one.",
			cool = "Just thinking about home.",
			prickly = "I'm fine. ...I miss home a bit. That's all.",
			dramatic = "Across that sea is everything I left behind, {player}.",
			gloomy = "Nobody there writes much anymore.",
			foodie = "My dad made a stew on Sundays. I can't get it right.",
			_ = "I miss where I grew up, a bit. The smell of it.",
		}, "sad")
		s:choice("Tell me about it", function(c)
			c:n("{a} talked for a long time, mostly about a dog called Bean and a hill you could sledge down.")
			c:by("a", {
				bold = "Thanks. Don't tell anyone I got soppy.",
				shy = "Thanks for listening. I don't talk about it much...",
				proud = "Well. That was more than I meant to say.",
				prickly = "...Thanks. Don't make it weird.",
				polite = "Thank you for listening, {player}. Truly.",
				_ = "Thanks. I haven't talked about it in ages.",
			}, "heart")
			c:mood("a", 5)
			c:hearts("a", 1)
			c:memo("a", "I told you about Bean, didn't I? The dog from home. Good dog.")
		end)
		s:choice("This is home now", function(c)
			c:say("a", "...Yeah.", "heart")
			c:say("a", "Yeah, it is. Thanks, {player}.", "heart")
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
		s:say("a", "I set three alarms. Up at five, then a run.", "sweat")
		s:n("{a} switched off all three without waking up. It is now nearly lunch.")
		s:by("a", {
			easygoing = "I think my body made the right call.",
			proud = "My alarms are faulty. I'll be having words.",
			cool = "Tomorrow, then.",
			gloomy = "Knew it.",
			nervous = "Did I miss anything? Tell me I didn't miss anything.",
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
		s:say("a", "{player}. {player}. Look.", "sparkle", "point")
		s:say("a", "I can wiggle my ears. LOOK.", "sparkle")
		s:n("They can, just about.")
		s:by("a", {
			proud = "I've always been gifted. Now there's proof.",
			cheeky = "I'm going to do it at the worst possible moments.",
			shy = "I've never been good at anything this quickly...",
			cool = "Didn't know I could do that.",
			dramatic = "A gift, hidden all these years!",
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
			shy = "Sorry. Sorry. Sorry, sorry...",
			dreamy = "The hill has opinions. I like that in a hill.",
			cool = "...Huh.",
			prickly = "YOU keep it down. ...Sorry.",
			gloomy = "Even the hill wants me to be quiet.",
			nervous = "There's someone up there. {player}. There's SOMEONE up there.",
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
			cool = "Nice.",
			gloomy = "Huh. That's actually nice.",
			bookish = "It's sunlight bent through raindrops. Still, though. Look at it.",
			sunny = "{player}! Quick, look! Before it goes!",
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
		s:say("a", "{player}... can I tell you something?", "sweat")
		s:say("a", ctx.rng:pick(WORRIES), "sweat")
		s:voice("a", "worry", "question")
		s:choice("It's not as bad as you think", function(c)
			c:by("a", {
				proud = "I wasn't worried. ...Okay, a bit.",
				easygoing = "Yeah. You're right. Too much effort anyway.",
				gloomy = "Maybe. ...Thanks for saying it, though.",
				nervous = "You think? Really? Okay. Okay. Breathing.",
				_ = "You think, {player}? Okay. I'll stop thinking about it.",
			}, "heart")
			c:mood("a", 4)
			c:hearts("a", 1)
		end)
		s:choice("Let's go and check", function(c)
			c:n("You went to check together. It was fine. It's always fine.")
			c:by("a", {
				shy = "Thanks. Sorry. I feel a bit silly...",
				proud = "I knew it was fine. I was checking you knew.",
				bold = "Right. Fine. Good.",
				polite = "Thank you so much for coming with me, {player}.",
				nervous = "Oh, thank goodness. Thank you. I'd have checked six more times.",
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
		s:n("{a} cracked open a fortune biscuit and read the slip inside.")
		s:n("'{fortune}'")
		s:by("a", {
			dreamy = "This is going to happen. I can feel it.",
			proud = "I make my own fortune, thank you.",
			cheeky = "I'm keeping this. It's going on the fridge.",
			cool = "Hm.",
			gloomy = "Better than I expected, honestly.",
			foodie = "The biscuit was good. That's my fortune.",
			nervous = "What does it mean? Does it mean something?",
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
		s:say("a", "{player}! Come here.", "idea", "point")
		s:say("a", "I've invented {gadget}. Watch.", "idea")
		if ctx.rng:chance(0.35) then
			s:n("It worked. Everyone was as surprised as {a} was.")
			s:voice("a", "brag", "sparkle", "cheer")
			s:mood("a", 6)
		else
			s:n("There was a bang and a smell like burnt toast.")
			s:by("a", {
				proud = "Version two will be perfect.",
				easygoing = "Eh. Lunch anyway?",
				cool = "...Noted.",
				dramatic = "It lived so briefly!",
				gloomy = "Yeah. That's about right.",
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
			shy = "It's over... what do I do with my evenings now?",
			proud = "I saw the ending coming. Two hundred pages ago.",
			dreamy = "I want to live in it. Can I live in it?",
			cool = "Good book.",
			bookish = "Nine hundred pages. I'm starting it again tomorrow.",
			gloomy = "Everyone left at the end. Like they do.",
			dramatic = "They got on a BOAT, {player}. After everything!",
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
		s:say("a", "Hm? Oh. Sorry, {player}. I was {dream}.", "zzz")
		s:by("a", {
			dreamy = "It was going so well. Can I go back?",
			proud = "It'll happen one day. Mark my words.",
			cool = "Anyway.",
			gloomy = "Back to real life, then.",
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
			foodie = "Then I ate the stairs. Then the roof. Best night of my life.",
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
		s:say("a", "I heard a song in my dream. Quick, before it goes. La la LAA la.", "music")
		s:n("It sounded a lot like the bin lorry reversing.")
		s:by("a", {
			proud = "That's going to be famous.",
			shy = "It was better in the dream...",
			cool = "Gone. Oh well.",
			_ = "Hm. It's gone. Did you get it, {player}? Hum it back.",
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
				foodie = "Imagine this place in ten years. Three bakeries. Four.",
				_ = "Imagine this place in ten years. More houses. A bigger bakery.",
			}, "idea", "point")
		end
		s:by("a", {
			gentle = "I hope we're all still here.",
			cheeky = "I want my name on something. A bench, at least.",
			proud = "I'd like a say in where things go, mind.",
			shy = "I hope there's still room for me.",
			gloomy = "I hope I'm still in it. ...I'd like that.",
			prickly = "Don't wreck it, {player}. That's all I'm saying.",
			polite = "Thank you for building it, {player}. Really.",
			_ = "You'll build it, won't you, {player}?",
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
			shy = "Um. Lemonade? Only if you want. No pressure...",
			cheeky = "Half price if you can tell me what's in it. Nobody can.",
			bold = "LEMONADE. Cold. Get it here.",
			easygoing = "Lemonade. Leave the coins in the tin. I'm sitting down.",
			cool = "Lemonade. Cold.",
			prickly = "Buy some or move along. ...Want a free one, {player}?",
			dramatic = "Lemonade! The cure for summer!",
			polite = "Good afternoon. Would you care for a glass?",
			foodie = "I put mint in. And a bit of ginger. Try it. TRY IT.",
			nervous = "Is it too sour? Tell me if it's too sour.",
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
			sunny = "{player}! I've taken up {hobby}! I keep telling everyone, sorry.",
			gentle = "I've started {hobby}. It's nice to have something quiet for the evenings.",
			bold = "{Hobby}. Started this week. I'll be good at it by spring.",
			dreamy = "I've been doing {hobby}... the time sort of goes away when I do.",
			easygoing = "Took up {hobby}. Nothing serious. Just something to do.",
			proud = "I've taken up {hobby}. I'm told I have a gift for it.",
			shy = "Um. I've started {hobby}. I'm not very good yet. Don't watch...",
			cheeky = "{Hobby}. Don't laugh. Okay, you can laugh a bit. Hehe.",
			cool = "{Hobby}. New thing. It's good.",
			prickly = "Yes, I've started {hobby}. Don't make a fuss about it.",
			dramatic = "{Hobby}, {player}! I've found my calling!",
			bookish = "I've taken up {hobby}. I read three books on it first, of course.",
			gloomy = "Started {hobby}. Thought I'd hate it. I don't.",
			polite = "I've taken up {hobby}. Thank you for asking about it, {player}.",
			foodie = "{Hobby}. It makes me hungry, which is a good sign.",
			nervous = "I started {hobby}. Is it okay if I'm bad at it for a while?",
			_ = "I've started {hobby}. Still working it out.",
		}, "idea", "cheer")
		s:hobby("a", h.id)
		s:mood("a", 4)
		s:memo("a", "I took up {hobby} this week.")
		s:log("{a} took up {hobby}.")
		return s:done()
	end,
})

-- more of one villager's days ---------------------------------------------------------------------
-- (the user: "much more events / conversation events", with the villagers talking the way a friend
-- texts you, and calling you by name)

event({
	id = "missedbus",
	when = "day",
	weight = W({ base = 0.15 }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "Missed it")
		s:n("{a} ran for the bus and missed it by one step. The doors shut right in front of them.")
		s:by("a", {
			bold = "Oi. OI. ...It saw me. It definitely saw me.",
			proud = "I was going to walk anyway. For my health.",
			shy = "Oh... okay. That's fine. It's fine.",
			cheeky = "Rude. I'm writing to the bus.",
			easygoing = "Eh. There's a bench. I'll wait.",
			dreamy = "Bye, bus... have a nice trip.",
			sunny = "{player}! Did you see that? So close!",
			cool = "Next one, then.",
			prickly = "Great. Wonderful. No, I'm not upset.",
			dramatic = "Gone, {player}. Gone without me.",
			gloomy = "It always leaves when I get there. Always.",
			polite = "Oh dear. I hope the driver has a nice day anyway.",
			foodie = "I was going to the market for cheese. The cheese will have to wait.",
			nervous = "Was that the last one? It wasn't the last one, was it?",
			_ = "One step. One step!",
		}, "sweat")
		s:choice("Walk with them", function(c)
			c:n("You walked down to the harbour together. The bus was still at the stop when you got there.")
			c:say("a", "Of course it was.", "sweat")
			c:say("a", "Nice walk, though. Thanks, {player}.", "heart")
			c:mood("a", 4)
			c:hearts("a", 1)
			c:memo("a", "We walked to the harbour, remember? Faster than the bus. Nearly.")
		end)
		s:choice("Another one's due soon", function(c)
			c:by("a", {
				easygoing = "See? Told you. Bench time.",
				nervous = "Soon? How soon? Okay. I'll wait right here.",
				prickly = "Fine. I'm sitting down. Don't talk to me till it comes.",
				_ = "Yeah. Okay. I'll wait.",
			}, "zzz")
			c:mood("a", -1)
		end)
		s:log("{a} missed the bus by one step.")
		return s:done()
	end,
})

event({
	id = "bakerysmell",
	when = "day",
	weight = W({
		base = 0.14,
		cond = function(ctx)
			return ctx.hour < 11
		end,
	}),
	scene = function(ctx, a)
		local s = K.scene(ctx, "Warm bread")
		s:n("The bakery isn't open yet. {a} is standing outside it with their eyes shut, breathing in.")
		s:by("a", {
			foodie = "Rye. And something with cinnamon. And... yes. Buns.",
			dreamy = "If I stand here long enough I'll turn into toast.",
			easygoing = "Best smell in town. I come every morning.",
			bold = "I'm first in the queue. I'm always first.",
			shy = "Oh. {player}. I wasn't... okay, I was.",
			cool = "Opens at eight. Worth it.",
			prickly = "What? It's free. You can't charge for a smell.",
			dramatic = "This, {player}. This is why I get up in the morning.",
			bookish = "That smell is mostly the crust browning. There's a word for it. I forget it.",
			gloomy = "It always smells better than it tastes. Almost always.",
			polite = "Good morning. Lovely, isn't it? The smell.",
			_ = "Smell that. Just smell it.",
		}, "heart")
		s:n("The door opened and the baker handed {a} the first roll of the day, still too hot to hold.")
		s:say("a", "Hot hot hot. Worth it.", "sparkle", "cheer")
		s:mood("a", 4)
		s:log("{a} waited outside the bakery for the first roll.")
		return s:done()
	end,
})

event({
	id = "pierfish",
	when = "day",
	weight = W({ base = 0.15, weather = { "clear", "cloudy", "leaves", "blossom" } }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "On the pier")
		s:prop("fishing", "a")
		s:n("{a} has been sitting at the end of the pier with a rod since breakfast.")
		s:say("a", "Shh. {player}. Shh.", "question")
		s:say("a", "Something's biting.", "question")
		local roll = ctx.rng:float(0, 1)
		if roll < 0.35 then
			s:n("Up came a fish, silver and flapping, about the size of a spoon.")
			s:by("a", {
				proud = "A fine catch. Look at it.",
				bold = "Ha! Got you. ...Okay, back you go, tiny.",
				gentle = "Oh, you're only little. Back you go.",
				cool = "Small. Still counts.",
				dramatic = "A monster of the deep! ...A small one. Back you go.",
				foodie = "That's half a sandwich. Maybe a third. Back you go.",
				_ = "A fish! A small one. Back you go.",
			}, "sparkle", "cheer")
			s:mood("a", 5)
			s:memo("a", "I caught a fish off the pier. I put it back. It was very small.")
		elseif roll < 0.7 then
			s:n("Up came an old boot, full of water and one surprised crab.")
			s:by("a", {
				cheeky = "New shoe! Just the one, though.",
				prickly = "Every time. Every single time.",
				gloomy = "Of course.",
				nervous = "Is that... does someone want that back?",
				bookish = "That boot's been down there years. Look at the barnacles.",
				_ = "A boot. With a crab in it. Hi, crab.",
			}, "sweat")
			s:mood("a", 1)
		else
			s:n("It was the weed again.")
			s:by("a", {
				easygoing = "Eh. It's about the sitting, really.",
				dreamy = "The sea's keeping its fish today. Fair enough.",
				_ = "Nothing. Again. I'm staying another hour.",
			}, "zzz")
			s:mood("a", 2)
		end
		s:log("{a} went fishing off the pier.")
		return s:done()
	end,
})

event({
	id = "latebook",
	when = "any",
	weight = W({ base = 0.08, traits = { focus = -0.2 } }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "Three weeks late")
		s:n("{a} found a library book under the sofa. It was due back three weeks ago.")
		s:by("a", {
			shy = "Oh no. Oh no, the librarian's going to look at me.",
			proud = "Three weeks is nothing. I was studying it.",
			cool = "...Oops.",
			prickly = "Who put that there? ...Me. I put it there.",
			dramatic = "I am a criminal, {player}. A library criminal.",
			bookish = "No. No, no. I've never had a late book. Never.",
			gloomy = "The fine's going to be huge. I know it.",
			polite = "I must apologise in person. And maybe bring a cake.",
			nervous = "What's the fine? What if there's a list? Am I on a list?",
			_ = "I'd forgotten I even had it, {player}.",
		}, "sweat")
		s:choice("Take it back with them", function(c)
			c:n("You went together. The librarian looked at the date, looked at {a}, and stamped it.")
			c:n("No fine. Just a long look.")
			c:say("a", "That look was worse than a fine.", "sweat")
			c:say("a", "Thanks for coming, {player}.", "heart")
			c:mood("a", 4)
			c:hearts("a", 1)
		end)
		s:choice("Read it first, then", function(c)
			c:by("a", {
				bookish = "...You're right. I never finished it. One night more.",
				nervous = "Another day late? Is that worse? It's worse. ...Okay.",
				_ = "Ha. Fair. I never got past chapter two.",
			}, "zzz")
			c:mood("a", 2)
			c:memo("a", "I'm still reading that late library book. Don't tell anyone.")
		end)
		s:log("{a} found a library book three weeks late.")
		return s:done()
	end,
})

event({
	id = "squeakyshoes",
	when = "day",
	weight = W({ base = 0.13 }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "New shoes")
		s:n("{a} has new shoes. They squeak on every single step.")
		s:say("a", "Squeak. Squeak. Squeak.", "sweat")
		s:by("a", {
			cheeky = "I can't sneak up on anyone now. My whole career.",
			proud = "They're very good shoes. They want you to know it.",
			shy = "Everyone turns round when I walk past...",
			bold = "I'll walk them in. Ten laps of the square.",
			easygoing = "Eh. At least nobody loses me.",
			cool = "They'll stop. Eventually.",
			prickly = "Don't. I know. I can hear them too.",
			dramatic = "I am announced wherever I go!",
			bookish = "It's the new soles. They wear in after about a week.",
			gloomy = "I paid for these.",
			foodie = "They sound like a rubber duck. Now I want a bath. And a bun.",
			nervous = "Is it loud? It's loud, isn't it? Everyone can hear?",
			_ = "Every step. Every single step.",
		}, "sweat", "laugh")
		s:mood("a", 1)
		s:memo("a", "My shoes have stopped squeaking. Mostly. The left one still does.")
		s:log("{a}'s new shoes squeak.")
		return s:done()
	end,
})

event({
	id = "bottlenote",
	when = "day",
	weight = W({ base = 0.1, weather = { "clear", "cloudy", "leaves" } }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "A note in a bottle")
		s:n("{a} found a bottle on the beach with a rolled up note inside.")
		s:n("It says 'Hello from the island with the red lighthouse. Is anyone there?'")
		s:by("a", {
			sunny = "Somebody's out there, {player}! We have to write back!",
			dreamy = "They've been floating all this way just to say hello.",
			cool = "Huh. Someone's out there.",
			prickly = "Probably a joke. ...I'm keeping it, though.",
			dramatic = "A voice across the sea!",
			bookish = "The current runs east this time of year. So it came from that way.",
			gloomy = "I hope someone wrote back to them. Somebody should.",
			nervous = "Do we answer? What do we even say?",
			_ = "Someone threw this in the sea. And I found it.",
		}, "sparkle")
		s:choice("Write back and throw it in", function(c)
			c:n("{a} wrote 'Yes. Catalog Town. We have a good bakery.' and threw the bottle as far as they could.")
			c:say("a", "It went about four metres.", "sweat")
			c:say("a", "It'll get there.", "heart")
			c:mood("a", 5)
			c:memo("a", "I sent a note back in that bottle. I check the beach every morning now.")
		end)
		s:choice("Keep the note", function(c)
			c:say("a", "I'll pin it by the door.", "heart")
			c:mood("a", 3)
		end)
		s:log("{a} found a message in a bottle.")
		return s:done()
	end,
})

event({
	id = "sunrise",
	when = "day",
	weight = W({
		base = 0.12,
		weather = { "clear", "cloudy", "blossom" },
		cond = function(ctx)
			return ctx.hour < 10
		end,
	}),
	scene = function(ctx, a)
		local s = K.scene(ctx, "Sunrise")
		s:n("{a} climbed the hill in the dark to watch the sun come up over the sea.")
		s:by("a", {
			gentle = "There it is. Good morning, everyone.",
			dreamy = "It's like the sea is waking up too.",
			bold = "Made it. Beat the sun.",
			easygoing = "Okay. That was worth getting up for. Once.",
			sunny = "{player}! You came! Look, look, it's coming up!",
			cool = "Good one today.",
			prickly = "Cold. Early. ...Worth it. Don't tell anyone I said that.",
			dramatic = "A new day is born!",
			bookish = "The sun's actually already up. We see it a few minutes late.",
			gloomy = "Huh. It's pretty. I didn't expect that.",
			polite = "Thank you for coming up with me. It's lovely.",
			foodie = "It looks like an egg yolk. I want breakfast now.",
			nervous = "We didn't miss it, did we? Oh. No. There it is.",
			_ = "There it is.",
		}, "sparkle")
		s:mood("a", 5)
		s:memo("a", "I watched the sun come up from the hill. I'm doing it again on Sunday.")
		s:log("{a} watched the sunrise from the hill.")
		return s:done()
	end,
})

event({
	id = "lockedout",
	when = "day",
	weight = W({ base = 0.12, traits = { focus = -0.4 } }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "Locked out")
		s:n("{a} is standing outside their own front door, patting every pocket.")
		s:say("a", "{player}. Hi. Don't laugh.", "sweat")
		s:by("a", {
			cheeky = "I've locked myself out. The key's on the table. I can see it.",
			proud = "The door locked itself. I had nothing to do with it.",
			shy = "I locked myself out... again.",
			cool = "Key's inside. I'm outside.",
			prickly = "Locked out. Go on. Laugh. Get it over with.",
			dramatic = "Shut out of my own home, {player}!",
			gloomy = "Locked out. Sounds about right.",
			nervous = "I checked I had it. I checked twice. How?",
			_ = "I've locked myself out. The key's on the kitchen table.",
		}, "sweat")
		s:choice("Try the back window", function(c)
			if ctx.rng:chance(0.6) then
				c:n("The back window was open a crack. {a} climbed in head first and landed in the washing basket.")
				c:say("a", "I'm in! I'm... in the washing. But I'm in.", "sparkle", "cheer")
				c:mood("a", 4)
			else
				c:n("The back window was shut tight. {a} got halfway up the drainpipe and thought better of it.")
				c:say("a", "Neighbour has a spare. I'll go and ask.", "sweat")
				c:mood("a", -1)
			end
		end)
		s:choice("Wait with them for the spare", function(c)
			c:n("The spare key was at the neighbour's, in a teapot. You had a cup of tea while you were there.")
			c:by("a", {
				polite = "Thank you for waiting with me. That was very kind.",
				prickly = "...Thanks for waiting. You didn't have to.",
				_ = "Thanks, {player}. That was nicer than being locked out should be.",
			}, "heart")
			c:mood("a", 4)
			c:hearts("a", 1)
		end)
		s:log("{a} locked themselves out.")
		return s:done()
	end,
})

event({
	id = "goodnight",
	when = "night",
	weight = W({ base = 0.12, traits = { social = 0.3 } }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "Night")
		s:n("A window opens as you pass. {a} leans out in their pyjamas.")
		s:by("a", {
			sunny = "{player}! Night! Sleep well, okay?",
			gentle = "Night, {player}. Don't stay up too late.",
			bold = "Oi, {player}. Bed. It's late.",
			dreamy = "Night... the moon's out. Did you see?",
			easygoing = "Night. I'm already half asleep.",
			proud = "Goodnight, {player}. I saw you working hard today.",
			shy = "Um. Night, {player}...",
			cheeky = "Psst. {player}. Night. Hehe.",
			cool = "Night.",
			prickly = "You're up late. ...Night, then.",
			dramatic = "Farewell till morning, {player}!",
			bookish = "Night. I'm reading one more chapter. Two at most.",
			gloomy = "Night. Tomorrow will probably be fine.",
			polite = "Goodnight, {player}. Thank you for today.",
			foodie = "Night. I'm dreaming about pancakes. On purpose.",
			nervous = "Night. You locked up, right? Okay. Night.",
			_ = "Night, {player}.",
		}, "zzz", "wave")
		s:choice("Night", function(c)
			c:say("a", "Night.", "heart")
			c:hearts("a", 1)
			c:mood("a", 2)
		end)
		s:choice("Still up?", function(c)
			c:by("a", {
				cool = "Couldn't sleep. Now I can. Night.",
				prickly = "Clearly. ...I'm going now. Night.",
				nervous = "I was checking the windows. All shut. Now bed.",
				_ = "Just going. Night, {player}.",
			}, "zzz")
			c:mood("a", 3)
		end)
		s:log("{a} said goodnight from the window.")
		return s:done()
	end,
})

event({
	id = "noumbrella",
	when = "day",
	weight = W({ base = 0.18, weather = { "rain", "storm" } }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "Caught in the rain")
		s:n("{a} is sheltering under the bakery's awning. The rain's coming down hard.")
		s:by("a", {
			sunny = "{player}! Hide here with me, there's room!",
			gentle = "It'll pass. It always does.",
			bold = "I'm making a run for it. Any second now.",
			dreamy = "I like the sound of it on the awning.",
			easygoing = "I'll wait. I'm good at waiting.",
			proud = "I left my umbrella at home. On purpose. To test it.",
			shy = "I didn't bring an umbrella...",
			cheeky = "I've been here an hour. The baker keeps looking at me.",
			cool = "Forgot my umbrella.",
			prickly = "The forecast said sun. The forecast lied.",
			dramatic = "Trapped by the storm, {player}!",
			bookish = "Rain like this usually stops within the half hour. Usually.",
			gloomy = "Of course it's raining. I washed my hair.",
			polite = "I hope the baker doesn't mind me standing here.",
			foodie = "Since I'm here. One bun. It'd be rude not to.",
			nervous = "Will it stop? It'll stop. When will it stop?",
			_ = "Forgot my umbrella. Again.",
		}, "sweat")
		s:choice("Share your umbrella", function(c)
			c:prop("umbrella", "a")
			c:n("You walked {a} home under one umbrella. You both got one wet shoulder each.")
			c:by("a", {
				polite = "Thank you so much. Please, come in and dry off.",
				prickly = "...Thanks. Your shoulder's soaked. Idiot. Thanks.",
				_ = "Thanks, {player}. Your side's all wet, look.",
			}, "heart")
			c:mood("a", 4)
			c:hearts("a", 1)
		end)
		s:choice("Run for it together", function(c)
			c:n("You both ran. You were both soaked by the end of the street.")
			c:voice("a", "laugh", "laugh", "laugh")
			c:mood("a", 3)
			c:memo("a", "Remember when we ran home in the rain? My boots still squelch.")
		end)
		s:log("{a} got caught in the rain.")
		return s:done()
	end,
})

event({
	id = "snowangel",
	when = "day",
	weight = W({ base = 0.2, weather = "snow" }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "In the snow")
		s:n("{a} is lying on their back in the snow, flapping their arms and legs.")
		s:by("a", {
			sunny = "Snow angel! Make one next to me, {player}!",
			dreamy = "If I lie here long enough, will it snow on me?",
			bold = "That's six. I'm doing the whole field.",
			easygoing = "I'm not getting up. I live here now.",
			cool = "...Cold. Good, though.",
			prickly = "What. It's snow. You're supposed to.",
			dramatic = "I am one with the winter!",
			gloomy = "I'll be cold for hours. Still.",
			nervous = "Is the snow deep enough? I hit the ground a bit.",
			_ = "Come on, {player}. There's room for two.",
		}, "sparkle")
		s:mood("a", 4)
		s:log("{a} made snow angels.")
		return s:done()
	end,
})

event({
	id = "petals",
	when = "day",
	weight = W({ base = 0.18, weather = "blossom" }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "Petals")
		s:n("{a} has had pink petals stuck in their hair all morning. Nobody's said anything.")
		s:choice("Tell them", function(c)
			c:by("a", {
				shy = "All morning? Everyone saw? Oh no...",
				proud = "I know. I left them in. It's a look.",
				cheeky = "I know. I'm a tree now.",
				cool = "Huh. Leaving them.",
				prickly = "And nobody said? Thanks, {player}. Thanks a lot, everyone.",
				dramatic = "I've been wearing spring all day!",
				nervous = "All morning? I had a meeting with the baker!",
				_ = "Oh! Ha. All morning? Thanks, {player}.",
			}, "sweat")
			c:mood("a", 2)
		end)
		s:choice("Leave them, they suit them", function(c)
			c:n("{a} walked round all day with petals in their hair and got told three times they looked nice.")
			c:mood("a", 5)
			c:memo("a", "Three people said I looked nice yesterday. I don't know why.")
		end)
		s:log("{a} had petals in their hair all day.")
		return s:done()
	end,
})

makes({
	id = "townphoto",
	title = "A photo of town",
	item = "keep_photo",
	w = { base = 0.07, weather = { "clear", "cloudy", "blossom", "leaves" } },
	lines = {
		{ "n", "{a} went up the hill with a camera and took one photo of the whole town." },
		{ "a", "Just the one.", "sparkle", "point" },
		{ "a", "I waited an hour for the light.", "sparkle" },
	},
	react = {
		sunny = "You can see your roof in it, {player}! Look!",
		cool = "Came out well.",
		bookish = "I'll write the date on the back. It'll be history one day.",
		gloomy = "It looks nicer than I thought it would. The town, I mean.",
		dramatic = "Our whole town, in one frame!",
		polite = "I had two copies made. I hoped you might like one.",
		_ = "You can see the bakery. And the gulls. And your house, there.",
	},
	ask = "Could I have a copy?",
	memo = "That photo from the hill came out well. Did you put yours up?",
	log = "{a} took a photo of the whole town.",
})

event({
	id = "thunder",
	when = "night",
	weight = W({ base = 0.3, weather = "storm", traits = { brave = -0.4 } }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "Under the blanket")
		s:n("There's a storm overhead. {a} is under a blanket with only their eyes showing.")
		s:by("a", {
			shy = "{player}... it's very loud tonight.",
			gentle = "I'm fine. Is everyone else fine?",
			dreamy = "The sky's moving its furniture.",
			cool = "Loud one.",
			prickly = "I'm not scared. I'm cold. That's why the blanket.",
			dramatic = "The heavens are furious!",
			gloomy = "The roof's going to leak. I know it.",
			nervous = "Was that close? That sounded close. Was it close?",
			_ = "Is it going to get louder, {player}? It's going to get louder.",
		}, "sweat")
		s:choice("Sit with them till it passes", function(c)
			c:n("You sat with {a} until the rain went soft. They fell asleep sitting up.")
			c:mood("a", 5)
			c:hearts("a", 1)
			c:memo("a", "Thanks for sitting with me in the storm, {player}. I slept fine after.")
		end)
		s:choice("Count the seconds between", function(c)
			c:n("Flash. One, two, three, four, five, six. Boom.")
			c:say("a", "Six. That's further, right?", "question")
			c:say("a", "It's going away. Okay.", "heart")
			c:mood("a", 3)
		end)
		s:log("{a} sat out the storm under a blanket.")
		return s:done()
	end,
})

event({
	id = "firstloaf",
	when = "day",
	weight = W({ base = 0.12 }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "The first loaf")
		s:prop("bakes", "a")
		s:n("{a} baked bread for the first time. It came out very heavy.")
		s:say("a", "Knock on it, {player}.", "question")
		s:n("It went clonk.")
		s:by("a", {
			proud = "That's a dense loaf. That's how they do it abroad.",
			foodie = "It's a bit tough, but the flavour's there. I'm sure the flavour's there.",
			bold = "Next one'll be perfect. This one's a doorstop.",
			shy = "I followed the recipe... mostly...",
			cool = "...It's a brick.",
			prickly = "It's bread. It's fine. It's FINE.",
			dramatic = "Six hours of my life, {player}. Six.",
			bookish = "I think the yeast was old. Or I was too impatient. Both, actually.",
			gloomy = "I knew it'd come out like this.",
			nervous = "Is it safe to eat? It's safe. Is it?",
			_ = "It's supposed to sound hollow. It does not sound hollow.",
		}, "sweat")
		s:choice("Eat it anyway", function(c)
			c:n("You both had a slice with a lot of butter. It took a while.")
			c:say("a", "Not bad. Chewy.", "heart")
			c:say("a", "Good for the jaw.", "laugh")
			c:mood("a", 4)
			c:hearts("a", 1)
		end)
		s:choice("Use it as a doorstop", function(c)
			c:say("a", "Ha. It's perfect for it, actually.", "laugh")
			c:mood("a", 1)
			c:memo("a", "My first loaf is holding my back door open. It's doing very well.")
		end)
		s:log("{a} baked their first loaf.")
		return s:done()
	end,
})

local DOORS = { { "Yellow", "yellow" }, { "Green", "green" }, { "Sky blue", "sky blue" } }

event({
	id = "doorcolour",
	when = "day",
	weight = W({ base = 0.13 }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "Which colour")
		s:n("{a} is standing in front of their house with two pots of paint and a brush.")
		s:say("a", "{player}. Quick question.", "question", "point")
		s:by("a", {
			sunny = "What colour should my door be? I can't choose, help!",
			cool = "Door colour. You pick.",
			prickly = "I need a door colour. Don't overthink it. Just say one.",
			dramatic = "A door says who you are, {player}. What do I say?",
			bookish = "I've narrowed it down. I can't get further. You choose.",
			nervous = "What colour? What if I pick wrong and it's wrong for years?",
			polite = "Might I ask your opinion on the door?",
			_ = "What colour should my door be? You choose.",
		}, "question")
		for _, d in DOORS do
			s:choice(d[1], function(c)
				c:with({ colour = d[2], Colour = d[1] })
				c:by("a", {
					proud = "{Colour}. Good choice. I was going to say that.",
					prickly = "{Colour}. ...Fine. Yes. Good.",
					gloomy = "{Colour}. Okay. That might actually be nice.",
					_ = "{Colour}! Yes. Starting now.",
				}, "sparkle", "cheer")
				c:mood("a", 4)
				c:memo("a", "My door's {colour} now. You picked it, {player}. Come and look.")
			end)
		end
		s:log("{a} asked what colour to paint their door.")
		return s:done()
	end,
})

event({
	id = "thanknote",
	when = "day",
	weight = W({ base = 0.1, traits = { kind = 0.3 } }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "A note")
		s:n("There was a note under your door this morning, in {a}'s handwriting.")
		s:by("a", {
			sunny = "'{player}! Thanks for everything. Come for tea soon. Bring nothing. Just you.'",
			gentle = "'Dear {player}. Thank you for looking after us all. Come by when you can.'",
			bold = "'Thanks for the town. That's it. That's the note.'",
			dreamy = "'I saw a heron today and thought of you. Thank you for the town.'",
			easygoing = "'Thanks, {player}. That's all. Wanted to say it.'",
			proud = "'You've done well with this place, {player}. I've noticed.'",
			shy = "'Um. Thank you. For the house. And everything. Sorry this is short.'",
			cheeky = "'Thanks for the town. This note will self destruct. It won't. Thanks though.'",
			cool = "'Thanks. Good town.'",
			prickly = "'Thank you. Don't make it weird when you see me.'",
			dramatic = "'{player}! This town is a gift! I had to write it down!'",
			bookish = "'I've been keeping a list of things I like here. You're on it. Thank you.'",
			gloomy = "'I didn't think I'd like it here. I do. Thanks.'",
			polite = "'Dear {player}, thank you for all your hard work. With warm regards.'",
			foodie = "'Thank you! I've left you a biscuit. It's under the note. Was under the note.'",
			nervous = "'Thank you. I hope that's okay to say. Is it okay? Thank you.'",
			_ = "'Thank you for the town, {player}.'",
		}, "heart")
		s:choice("Pin it up", function(c)
			c:n("You pinned it by the door. {a} saw it there later and went pink.")
			c:hearts("a", 1)
			c:mood("a", 4)
		end)
		s:choice("Write one back", function(c)
			c:n("You wrote one back. {a} read it twice on the doorstep.")
			c:by("a", {
				prickly = "...You wrote back. Okay. I'm keeping it. Obviously.",
				cool = "Got your note. Thanks.",
				_ = "I got your note, {player}. It's on my fridge.",
			}, "heart")
			c:hearts("a", 1)
			c:mood("a", 6)
			c:memo("a", "I've still got your note, {player}. It's on the fridge.")
		end)
		s:log("{a} left you a thank you note.")
		return s:done()
	end,
})

event({
	id = "boatsin",
	cutscene = "pier",
	when = "day",
	weight = W({
		base = 0.12,
		traits = { social = 0.2 },
		cond = function(ctx)
			return ctx.hour >= 15
		end,
	}),
	scene = function(ctx, a)
		local s = K.scene(ctx, "Boats coming in")
		s:n("{a} catches up with you on the street.")
		s:say("a", "{player}. You busy?", "question", "wave")
		s:by("a", {
			sunny = "The boats come in at five! Come and watch with me?",
			gentle = "The boats are coming in soon. Would you walk down with me?",
			bold = "Boats come in at five. Walk down with me.",
			dreamy = "The boats come in at five... I like watching them find the harbour.",
			cool = "Boats come in soon. Want to watch?",
			prickly = "I'm going to watch the boats. You can come. If you want. Whatever.",
			dramatic = "The fleet returns at five! We must be there!",
			gloomy = "Boats are coming in. It's the best bit of my day. Come?",
			foodie = "Fresh fish comes off at five. We could watch. Then eat.",
			nervous = "Would you come? You don't have to. Only if you want.",
			_ = "The boats come in soon. Come and watch?",
		}, "idea")
		s:choice("Let's go", function(c)
			c:n("You sat on the harbour wall with {a} while the boats came in one by one, gulls following each.")
			c:by("a", {
				cool = "...Good, right?",
				prickly = "See? Worth it. ...Thanks for coming.",
				gloomy = "That was nice. I mean it.",
				_ = "That's my favourite one, with the red sail. Thanks for coming, {player}.",
			}, "heart")
			c:mood("a", 5)
			c:hearts("a", 1)
			c:memo("a", "Want to watch the boats again sometime? The red one's my favourite.")
		end)
		s:choice("Not today", function(c)
			c:by("a", {
				shy = "Oh. Okay. Another day.",
				prickly = "Fine. Didn't want company anyway. ...Another time.",
				_ = "Okay. Another day, then.",
			}, "sad")
			c:mood("a", -2)
		end)
		s:default(2)
		s:log("{a} asked you to watch the boats come in.")
		return s:done()
	end,
})

event({
	id = "forgot",
	when = "day",
	weight = W({ base = 0.14, traits = { social = 0.3, focus = -0.2 } }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "Wait, what was it")
		s:n("{a} spotted you from across the square and ran all the way over.")
		s:say("a", "{player}! Hi. Hiii.", "wave")
		s:say("a", "...", "question")
		s:by("a", {
			sunny = "I had something to tell you and it's gone! It was good, too!",
			dreamy = "I ran so fast the thought fell out.",
			cheeky = "I forgot. Hehe. Hi, though.",
			cool = "...Forgot. Hi anyway.",
			prickly = "Don't look at me like that. It'll come back.",
			dramatic = "It was important, {player}! Gone! Lost forever!",
			bookish = "Walking through a doorway makes you forget. There's a study. There was a door.",
			gloomy = "Typical.",
			nervous = "Was it bad? Was it something bad? I hope it wasn't bad.",
			_ = "I forgot what I was going to say.",
		}, "sweat")
		s:n("They walked off. Ten steps later they turned round.")
		s:say("a", "The bakery has cheese scones today! That was it!", "idea", "point")
		s:mood("a", 3)
		s:log("{a} ran over to tell you about the scones.")
		return s:done()
	end,
})

return list
