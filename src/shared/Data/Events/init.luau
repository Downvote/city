--!nonstrict
-- The random events of town life. Every few minutes Sim/EventEngine weighs all of these against
-- who is around and picks one. An event has:
--   id, actors (how many villagers it stars: 0..3), when ("day", "night" or "any"),
--   weight(ctx, a, b, c) -> number (0 means it can't happen now),
--   scene(ctx, a, b, c) -> { title, lines, choices?, effects?, default?, log }
-- Lines are { who = "a" | "b" | "c" | nil, text, icon?, gesture? }; nil is the narrator.
-- Text uses {a}, {b}, {c} for the stars' names (ctx.f fills them and any extra {words}).
-- Effects are listed in Sim/EventEngine.
--
-- The forty or so first events are below. The rest, and the parts they share, are in the
-- modules beside this one (the user: "make much much more random events. custom objects,
-- conversations, etc., just like tomodachi life"):
--   Kit       weights and a little scene builder (s:say, s:by personality, s:choice, s:prop...)
--   Chatter   villager to villager talk made from parts, and the banks of topics and dreams
--   Talks     the conversations you can watch: chats, gossip, dreams compared, spats, debates
--   Solo      one villager's day: hiccups, hobbies, weather, dreams, things they make you
--   Pairs     two or three together: games, duets, secrets, best friends, falling out, making up
--   Town      the whole town: power cuts, talent night, a parade, a lost dog, the seasons
--   Work      at work: big orders, a tower of bricks, the wrong letters
--   Asks      a villager asks you: a name for a pet, which outfit, whether to tell the truth
-- A scene may name props (Data/EventProps) to put by its stars while it plays; an answer may
-- leave one for a while, give you a keepsake, or teach them a saying or a hobby.
--
-- The villagers talk the way a friend texts you (the user's reference was a messaging app's
-- chats): the villager speaks first, a few messages at a time, each one a natural sentence (two
-- only when they belong together, never a string of clipped bits), each personality with its own
-- habits; your answer is one of two short replies; and now and then they use your name,
-- {player} (filled by ctx.f with the player's display name). The word banks below are dropped
-- into sentences, so each one has to read naturally in the sentence it fills.

local Personalities = require(script.Parent.Personalities)
local Foods = require(script.Parent.Foods)
local Catalog = require(script.Parent.Parent.Build.Catalog)
local Tuning = require(script.Parent.Parent.Config.Tuning)
local Kit = require(script.Kit)
local Chatter = require(script.Chatter)

type Ctx = any
type Scene = any

local Events = {}

local function line(who: string?, text: string, icon: string?, gesture: string?): any
	return { who = who, text = text, icon = icon, gesture = gesture }
end

-- A personality line ("hello", "happy", "sad", "angry", "thanks") for a star.
local function voice(ctx: Ctx, who: string, vid: string, kind: string, icon: string?, gesture: string?): any
	return line(who, Kit.voiceText(ctx, vid, kind), icon, gesture)
end

-- what two villagers fall out over ("arguing about ...", "fell out over ...")
local QUARREL = {
	"the last slice of pie",
	"whose turn it was to sweep the porch",
	"a rule in a board game",
	"which of them snores louder",
	"the right way to fold socks",
	"an umbrella that was borrowed and never came back",
	"whether toast still counts as bread",
	"who saw the shooting star first",
}

-- where two friends go for an afternoon ("come to ... with me")
local PLACES = { "the beach", "the harbour", "the market", "the hill behind town", "the fountain" }

local JOKES = {
	{ "Why did the scarecrow win a prize? Because he was outstanding in his field.", "groan" },
	{ "What did the sea say to the beach? Nothing, it just waved.", "laugh" },
	{ "Why don't crabs ever share their snacks? Because they're shellfish.", "groan" },
	{ "Why did the baker stop making doughnuts? He got tired of the whole thing.", "groan" },
	{ "I asked the librarian for a book about paranoia, and she whispered, 'It's right behind you.'", "laugh" },
}

-- something small to lose ("has anyone seen my ...?")
local LOST = {
	"lucky striped sock",
	"good drawing pencil",
	"spare house key",
	"blue lunch box",
	"little green notebook",
	"shell hair clip",
}

-- an afternoon to themselves ("spent the afternoon ...")
local HOBBIES = {
	"painting the fence a slightly different shade of white",
	"doing push ups behind the house",
	"reading under a tree",
	"jogging laps round the garden",
	"doing stretches on the lawn",
	"humming to the plants while watering them",
}

-- "I had the strangest dream last night about ..."
local DREAMS = {
	"a pancake the size of the town square",
	"being chased round the market by a goose that kept saying sorry",
	"living inside a teapot with a tiny front door",
	"racing the wind along the beach and winning",
	"a town where every single door was round",
	"a cloud that came down to ask for directions",
}

-- "I'll show you how to ..."
local SKILLS = {
	"whistle with two fingers",
	"juggle three apples",
	"tie a proper sailor's knot",
	"skip stones across the harbour",
	"do a cartwheel",
}

-- "I've had my eye on ..."
local WANTS = {
	"a new pair of boots",
	"a straw hat from the market",
	"a fishing rod",
	"a set of paints",
	"a kite with a long tail",
	"a second hand guitar",
}

-- How a food is named in a sentence: "an apple", "a bread roll", but "mushroom soup" and
-- "pancakes" as they are. (Foods has only the bare name, and "I really want bread roll" isn't
-- how anyone talks.)
local function foodPhrase(food: any): string
	return Foods.phrase(food)
end

local function capital(s: string): string
	return s:sub(1, 1):upper() .. s:sub(2)
end

-- what two villagers can make together in a kitchen (a carrot or an apple isn't a dish)
local DISHES = {
	bread = true,
	soup = true,
	skewer = true,
	tart = true,
	honeycake = true,
	riceball = true,
	pancakes = true,
	curry = true,
	pie = true,
	salad = true,
	pudding = true,
	stew = true,
}

-- A burst: what they'd send as two or three quick messages. A map keyed by personality like
-- Kit.byPers ("_" for anyone else; a value may be a list to pick one from), and "|" splits a
-- line into the messages it is sent as. A plain string is the same burst for everyone. Each
-- message is filled (the stars' names, {player} and `vars`).
local function burst(
	ctx: Ctx,
	who: string,
	vid: string,
	map: any,
	icon: string?,
	gesture: string?,
	vars: { [string]: any }?
): { any }
	local text = if type(map) == "string" then map else Kit.byPers(ctx, vid, map)
	local out = {}
	for _, part in Kit.parts(text) do
		table.insert(out, line(who, ctx.f(part, vars or {}), icon, if #out == 0 then gesture else nil))
	end
	return out
end

-- lines and bursts, one after another, as one list of lines
local function join(...: any): { any }
	local out = {}
	for _, x in { ... } do
		if x.text ~= nil then
			table.insert(out, x)
		else
			for _, l in x do
				table.insert(out, l)
			end
		end
	end
	return out
end

-- What someone says when you take their side in a quarrel, in their own way.
local WIN = {
	sunny = "Ha, see, I told you so!|Thanks for backing me up, {player}!",
	proud = "Thank you, finally someone sensible.|Hmph, I knew I was right all along.",
	bold = "Hah, told you, right?",
	prickly = "See, obviously I was right.|...But thanks for saying so.",
	cool = "Thanks, {player}, I knew I had it right.",
	shy = "...!|Thank you for siding with me.",
	gentle = "Thank you, {player}.|I'm sorry it came to this, though.",
	cheeky = "hehe, the judge has spoken|no take backs",
	dramatic = "JUSTICE, at long last!",
	bookish = "Thank you, the facts were on my side all along.",
	gloomy = "Oh, I was right?|Heh... that doesn't usually happen.",
	polite = "Thank you kindly, {player}.|I appreciate you hearing us both out.",
	foodie = "Thank you, I'm going to celebrate with a snack.",
	nervous = "I-I was right?|Oh, okay, thank you.",
	easygoing = "Heh, told you.|Can we stop arguing now?",
	dreamy = "Oh, I was right.|Hmm... that's nice.",
	_ = "Thank you.|See, I said so.",
}

-- What someone says when you take the other side in a quarrel, in their own way.
local SULK = {
	proud = "Fine, but you'll see I was right in the end.",
	shy = "Oh... okay.",
	gentle = "All right, {player}, if that's how you see it.",
	cheeky = "wow, ok|noted, and remembered",
	dreamy = "Oh.|I'll go and be wrong somewhere else, then.",
	easygoing = "Eh, fine.|I wasn't that bothered anyway.",
	sunny = "Oh, okay, I'm not upset.|...I'm a little bit upset.",
	bold = "Fine, your call.",
	cool = "...Fine, if you say so.",
	prickly = "Whatever.|Ugh, don't talk to me for a bit.",
	dramatic = "Betrayed, {player}, and by you of all people!",
	bookish = "I still think the facts were on my side.|But fine.",
	gloomy = "Yeah, figures.|That's how it usually goes.",
	polite = "I see.|Thank you for listening, at least.",
	foodie = "Fine, I'm going to go and eat something about it.",
	nervous = "Oh, was I wrong?|Was I being awful? Oh no, oh no.",
	_ = "Fine, whatever.",
}

-- A line in the villager's own way (Kit.byPers): a map keyed by personality, "_" for anyone else.
-- (filled, so a line may name the stars or call the player by name: {player}) It is one message,
-- so it never holds a "|".
local function by(ctx: Ctx, who: string, vid: string, map: any, icon: string?, gesture: string?): any
	return line(who, ctx.f(Kit.byPers(ctx, vid, map)), icon, gesture)
end

local function trait(ctx: Ctx, vid: string, t: string): number
	return Personalities.trait(ctx.v(vid).pers, t)
end

local function isPers(ctx: Ctx, vid: string, ...: string): boolean
	return table.find({ ... }, ctx.v(vid).pers) ~= nil
end

-- Presents one villager finds for another (when it isn't something to eat).
local GIFTS = {
	"a jar of plum jam",
	"a pressed flower in a card",
	"a scarf they knitted",
	"a shell from the beach",
	"a book they'd just finished",
	"a drawing of the two of them",
}

-- What a villager asks for by their bed, in their own words, where Catalog.Tags (which the log
-- uses) speaks of them ("a place for their things").
local ASKS = { storage = "somewhere to keep my things" }

-- What a customer asks for at a workplace that doesn't sell things over a counter, and what
-- the worker says back (an answer to that, not just something said on shift).
local SERVICE = {
	artist = {
		"Could you do a quick sketch of me?|I'll pay, of course.",
		"Sit on that stool and keep still, then.",
	},
	doctor = {
		"I've had a sore throat for three days.|Could you have a look at it?",
		"Open wide and say ahh for me.",
	},
	teacher = {
		"I'd like to sign up for your evening class, if there's still room.",
		"There's one seat left, so put your name down here.",
	},
	musician = {
		"Could you play the one about the harbour?|Here's a coin for the hat.",
		"That's my favourite one too, so here it goes.",
	},
	builder = {
		"My gate's come off its hinges.|Could you fix it some time this week?",
		"I'll come round on Thursday with my tools.",
	},
	postie = {
		"I need to send this parcel to the next island, please.",
		"Pop it on the scales, and it'll go out on the morning boat.",
	},
	librarian = {
		"I'm looking for a good book for a rainy day.|What would you pick?",
		"Try this one, it's long and there's a shipwreck in it.",
	},
}

-- What the worker says handing over something bought at a counter, in their own way.
local SERVED = {
	shy = "Um, here you go... thank you.",
	bold = "There you go, enjoy it.",
	proud = "Good choice, it's the best one I've got.",
	cool = "Here you go. Come again.",
	prickly = "Here, and don't drop it on the way out.",
	dramatic = "An EXCELLENT choice, if I may say so!",
	sunny = "Here you go, come back soon!",
	gentle = "Here you are, and take care on your way home.",
	polite = "Here you are, thank you kindly.",
	foodie = "Good pick, that's the one I'd have gone for.",
	nervous = "H-here you go, I hope it's all right.",
	cheeky = "here you go, and come back tomorrow",
	gloomy = "Here you go, I hope it's not squashed.",
	bookish = "Here you go, that one's been the most popular all week.",
	dreamy = "Hmm... here you go, I put a ribbon on it.",
	easygoing = "Here you go, no rush with the coins.",
	_ = "Here you go, thanks for coming in.",
}

-- the list ----------------------------------------------------------------------------------------

local list: { any } = {}

local function event(def: any)
	table.insert(list, def)
end

-- Two villagers chat about something.
event({
	id = "chat",
	actors = 2,
	when = "any",
	weight = function(ctx: Ctx, a: string, b: string)
		if ctx.quarreling(a, b) then
			return 0
		end
		return 1 + (trait(ctx, a, "social") + trait(ctx, b, "social"))
	end,
	scene = function(ctx: Ctx, a: string, b: string): Scene
		-- made from parts (Data/Events/Chatter), so two neighbours rarely say the same thing twice
		local s = Kit.scene(ctx, "A chat")
		local topic, _, d = Chatter.chat(ctx, s, a, b)
		s:rel(d)
		s:with({ topic = topic.about })
		s:log("{a} and {b} talked about {topic}.")
		return s:done()
	end,
})

-- A quarrel, and you get to step in. (Its cutscene counts on four lines before the question: the
-- narrator, one cross line each, and the narrator again.)
event({
	id = "quarrel",
	actors = 2,
	when = "day",
	weight = function(ctx: Ctx, a: string, b: string)
		if ctx.quarreling(a, b) then
			return 0
		end
		local temper = trait(ctx, a, "temper") + trait(ctx, b, "temper")
		local score = ctx.rel(a, b)
		local w = temper * 1.6
		if score > 55 then
			w *= 0.4
		end
		return w
	end,
	scene = function(ctx: Ctx, a: string, b: string): Scene
		local cause = ctx.rng:pick(QUARREL)
		local kind = (trait(ctx, a, "kind") + trait(ctx, b, "kind")) / 2
		local works = ctx.rng:chance(0.35 + kind * 0.5)
		return {
			title = "A quarrel",
			lines = {
				line(nil, ctx.f("{a} and {b} are arguing about {cause}.", { cause = cause })),
				voice(ctx, "a", a, "angry", "anger", "point"),
				voice(ctx, "b", b, "angry", "anger"),
				line(nil, "Then they both turn to you."),
			},
			choices = {
				{
					text = ctx.f("{a}'s right."),
					lines = join(burst(ctx, "a", a, WIN, "sparkle", "cheer"), burst(ctx, "b", b, SULK, "anger")),
					effects = {
						{ t = "rel", a = "a", b = "b", d = -12 },
						{ t = "mood", who = "a", d = 6 },
						{ t = "mood", who = "b", d = -8 },
						{ t = "quarrel", a = "a", b = "b" },
					},
				},
				{
					text = ctx.f("{b}'s right."),
					lines = join(burst(ctx, "b", b, WIN, "sparkle", "cheer"), burst(ctx, "a", a, SULK, "anger")),
					effects = {
						{ t = "rel", a = "a", b = "b", d = -12 },
						{ t = "mood", who = "b", d = 6 },
						{ t = "mood", who = "a", d = -8 },
						{ t = "quarrel", a = "a", b = "b" },
					},
				},
				{
					text = "Can you two make up?",
					lines = if works
						then join(
							burst(ctx, "a", a, {
								proud = "...Fine, I may have got a bit carried away.",
								bold = "...Yeah, I got loud, and I'm sorry about that.",
								shy = "...Sorry, I didn't mean it.",
								cool = "...Yeah, that was my fault, sorry.",
								prickly = "Ugh, fine.|I'm sorry, okay?",
								dramatic = "I was a monster, and I'm so sorry!",
								polite = "You're right, {player}.|I apologise for raising my voice.",
								nervous = "S-sorry, I got all worked up.|I'm really sorry.",
								_ = "...Sorry, I got carried away.",
							}, "sweat"),
							burst(ctx, "b", b, {
								gentle = "Me too, so let's forget it, shall we?",
								cheeky = "me too|hug? no? ok, fair",
								proud = "...Hmph, I wasn't much better.",
								gloomy = "Yeah, me too.|It's fine.",
								foodie = "Me too.|Do you want to go and get a bun?",
								sunny = "Me too, so are we friends again?",
								_ = "Me too, let's forget about it.",
							}, "heart")
						)
						else join(
							burst(ctx, "a", a, {
								shy = "...I don't want to talk about it.",
								easygoing = "Nah, not today.",
								cool = "No, not today.",
								prickly = "No, not until they say sorry first.",
								dramatic = "Never, not in a hundred years!",
								_ = "Not until they say sorry first.",
							}, "anger"),
							line("b", "Then we'll be standing here all week.", "anger")
						),
					effects = if works
						then {
							{ t = "rel", a = "a", b = "b", d = 5 },
							{ t = "mood", who = "a", d = 3 },
							{ t = "mood", who = "b", d = 3 },
						}
						else { { t = "rel", a = "a", b = "b", d = -8 }, { t = "quarrel", a = "a", b = "b" } },
				},
			},
			default = 3,
			log = ctx.f("{a} and {b} fell out over {cause}.", { cause = cause }),
		}
	end,
})

-- A quarreling pair makes up on their own. (Its cutscene counts on three lines: the narrator,
-- then one line each.)
event({
	id = "makeup",
	actors = 2,
	when = "any",
	weight = function(ctx: Ctx, a: string, b: string)
		if not ctx.quarreling(a, b) then
			return 0
		end
		return 2 + trait(ctx, a, "kind") * 4
	end,
	scene = function(ctx: Ctx, a: string, b: string): Scene
		local food = ctx.rng:pick(Foods.list)
		return {
			title = "Making up",
			lines = {
				line(nil, ctx.f("{a} walked over to {b} holding {food}.", { food = foodPhrase(food) })),
				by(ctx, "a", a, {
					proud = "Here, I may have been a bit much the other day.",
					shy = "Um, I brought you this... I'm sorry about before.",
					bold = "Here, I was out of line, so let's call it a truce.",
					cheeky = "peace offering, you can't stay cross with your mouth full",
					sunny = "Hi, I brought you this, because I hate being cross with you.",
					cool = "Here, I'm sorry about the other day.",
					prickly = "Take it, it's an apology, and don't make me say it twice.",
					dramatic = "I come bearing a gift and my deepest apologies!",
					bookish = "Actually, I thought about it all night, and you had a point.",
					gloomy = "I figured you wouldn't want to see me, but I brought this anyway.",
					polite = "I'd like to apologise properly, so please take this.",
					foodie = "I brought you the good one, that's how sorry I am.",
					nervous = "I-I brought you this to say sorry, is that okay?",
					gentle = "I brought you this, and I'm sorry for how I was.",
					easygoing = "Mm, I brought you this, so can we stop being cross now?",
					dreamy = "Hmm... I kept thinking about what I said, so I brought you this.",
					_ = "I brought you this, because I was being silly.",
				}, "sweat"),
				by(ctx, "b", b, {
					proud = "...Fine, I was a bit much too.",
					gentle = "Oh, come here, I was being silly too.",
					shy = "...I'm sorry too, thank you.",
					cool = "...Thanks, I'm sorry too.",
					prickly = "...Fine, apology accepted, and I'm sorry too, happy?",
					dramatic = "All is FORGIVEN!",
					gloomy = "...Thanks, I missed you, honestly.",
					foodie = "You brought the good one, so okay, we're fine.",
					cheeky = "apology accepted, and the snack is mine now",
					bold = "Hah, fine, truce, I was out of line too.",
					_ = "...Thanks, and I'm sorry too.",
				}, "heart"),
			},
			effects = { { t = "makeup", a = "a", b = "b" }, { t = "rel", a = "a", b = "b", d = 10 } },
			log = ctx.f("{a} and {b} made up.", {}),
		}
	end,
})

-- A gift between friends.
event({
	id = "gift",
	actors = 2,
	when = "day",
	weight = function(ctx: Ctx, a: string, b: string)
		if ctx.quarreling(a, b) then
			return 0
		end
		return trait(ctx, a, "kind") * 1.5 + math.max(0, ctx.rel(a, b)) / 60
	end,
	scene = function(ctx: Ctx, a: string, b: string): Scene
		-- half the time something to eat, and now and then it is the very thing they love
		local fav = Foods.get(ctx.v(b).fav)
		local roll = ctx.rng:float(0, 1)
		local food = if roll < 0.15 and fav then fav elseif roll < 0.5 then ctx.rng:pick(Foods.list) else nil
		local loves = food ~= nil and fav ~= nil and food.id == fav.id
		local thing = if food then foodPhrase(food) else ctx.rng:pick(GIFTS)
		local lines = join(
			line(nil, ctx.f("{a} has brought {b} {thing} as a present.", { thing = thing })),
			burst(ctx, "a", a, {
				shy = "Um... I got you this.|You don't have to like it.",
				bold = "Here, I got you something.",
				sunny = "Surprise!|I saw it and thought of you straight away!",
				cool = "Here, I thought you might like this.",
				prickly = "Here, it was just lying around.|Don't read into it.",
				dramatic = "A gift, for you, because you deserve it!",
				polite = "Hello, {b}.|I saw this and thought you might like it.",
				nervous = "I-I got you this, is that okay?|You don't have to like it.",
				cheeky = "for you, and no, it's not a prank this time",
				gentle = "I saw this and thought of you, so I hope you like it.",
				_ = "I saw this and thought of you.",
			}, "sparkle", "wave")
		)
		local effects
		if loves and food then
			table.insert(
				lines,
				line("b", ctx.f("{Food}? That's my favourite.", { Food = capital(foodPhrase(food)) }), "heart", "cheer")
			)
			effects = {
				{ t = "rel", a = "a", b = "b", d = 14 },
				{ t = "mood", who = "b", d = 10 },
			}
		elseif ctx.rng:chance(0.12) then
			-- not quite their thing
			lines = join(
				lines,
				burst(ctx, "b", b, {
					proud = "Oh, how... thoughtful.",
					cheeky = "oh, wow|you really shouldn't have, like, really",
					cool = "...Thanks, I'll find a use for it.",
					prickly = "Oh, it's... a thing.|Thanks, I guess.",
					gloomy = "Oh, thanks.|I'll find somewhere to put it.",
					_ = "Oh, um, thank you.|I'll save it for later.",
				}, "sweat")
			)
			effects = { { t = "rel", a = "a", b = "b", d = 2 } }
		else
			table.insert(lines, voice(ctx, "b", b, "thanks", "heart"))
			effects = { { t = "rel", a = "a", b = "b", d = 8 }, { t = "mood", who = "b", d = 4 } }
		end
		return {
			title = "A present",
			lines = lines,
			effects = effects,
			log = ctx.f("{a} gave {b} {thing}.", { thing = thing }),
		}
	end,
})

-- An outing for two.
event({
	id = "outing",
	actors = 2,
	when = "day",
	weight = function(ctx: Ctx, a: string, b: string)
		if ctx.quarreling(a, b) or ctx.rel(a, b) < 5 then
			return 0
		end
		return trait(ctx, a, "social") * 1.4
	end,
	scene = function(ctx: Ctx, a: string, b: string): Scene
		local place = ctx.rng:pick(PLACES)
		local vars = { place = place }
		return {
			title = "An outing",
			lines = join(
				burst(ctx, "a", a, {
					sunny = "{b}, {b}, come to {place} with me!|Let's go right now!",
					bold = "{b}, you're free, right?|Good, we're going to {place}.",
					shy = "Um, {b}?|If you're not busy, would you come to {place} with me?",
					cool = "{b}, I'm going to {place}.|Do you want to come?",
					foodie = "{b}, have you eaten yet?|Let's go to {place} and get something on the way.",
					dreamy = "{b}... the light at {place} is really pretty today.|Do you want to come and see?",
					_ = "Hey, {b}, do you want to go to {place} with me?",
				}, "idea", "point", vars),
				burst(ctx, "b", b, {
					shy = "Me?|Okay, if that's all right.",
					easygoing = "Sure, as long as there's somewhere to sit.",
					cool = "Sure, let's go.",
					prickly = "I've got nothing better to do, so fine.",
					dramatic = "An adventure, yes, I'll pack a bag!",
					bookish = "Oh, I've been meaning to go, actually.|Yes, let's.",
					gloomy = "It'll probably rain on us, but okay, yes.",
					polite = "I'd love to, thank you for asking.",
					foodie = "Is there anywhere to eat there?|Then yes, okay, yes.",
					nervous = "Now, right now?|Okay, let me get my coat first.",
					sunny = "Yes, yes, let's go!|Can we, {player}?",
					gentle = "Oh, that sounds lovely.|Is that all right with you, {player}?",
					bold = "Hah, sure, let's go.|You don't mind, right, {player}?",
					dreamy = "Hmm... okay, I'd like that.|Can we, {player}?",
					cheeky = "only if we get snacks on the way|can we, {player}?",
					proud = "I suppose I could spare an afternoon.|You can manage without us, can't you, {player}?",
					_ = "Ooh, sure.|Can we, {player}?",
				}, "question")
			),
			choices = {
				{
					text = "Have fun, you two.",
					lines = {
						line(nil, ctx.f("{a} and {b} headed off to {place}.", vars)),
						line(nil, "They came back at teatime, both smiling."),
					},
					effects = {
						{ t = "away", who = { "a", "b" }, seconds = 30 },
						{ t = "rel", a = "a", b = "b", d = 12 },
						{ t = "mood", who = "a", d = 8 },
						{ t = "mood", who = "b", d = 8 },
					},
				},
				{
					text = "Maybe another day?",
					lines = burst(ctx, "a", a, {
						sunny = "Aw, later, then!",
						shy = "Oh, of course, sorry.",
						prickly = "Fine, whatever, another day.",
						dramatic = "Our plans, CRUSHED.|...Okay, another day.",
						bold = "Your loss.|Another day, then.",
						cool = "Okay, another day.",
						gloomy = "Yeah, I figured.|Another day, then.",
						_ = "Aw, okay, another day.",
					}, "sad"),
					effects = { { t = "mood", who = "a", d = -3 }, { t = "mood", who = "b", d = -2 } },
				},
			},
			default = 1,
			log = ctx.f("{a} and {b} went to {place}.", vars),
		}
	end,
})

-- A prank.
event({
	id = "prank",
	actors = 2,
	when = "day",
	weight = function(ctx: Ctx, a: string, b: string)
		return trait(ctx, a, "mischief") * 2.2
	end,
	scene = function(ctx: Ctx, a: string, b: string): Scene
		local pranks = {
			"put a squeaky cushion on {b}'s chair",
			"swapped the sugar for salt in {b}'s tea",
			"hid behind a door and shouted boo at {b}",
			"tied {b}'s shoelaces together while they napped",
		}
		local prank = ctx.f(ctx.rng:pick(pranks))
		local goodSport = isPers(ctx, b, "cheeky", "sunny", "easygoing")
		return {
			title = "A prank",
			lines = join(
				line(nil, ctx.f("{a} {prank}.", { prank = prank })),
				burst(ctx, "a", a, {
					cheeky = "hehe, got you good|your face, though",
					dramatic = "*evil cackle* I got you GOOD.",
					cool = "Hm, got you.",
					_ = "Heh, got you.",
				}, "sparkle", "laugh"),
				if goodSport
					then burst(
						ctx,
						"b",
						b,
						"Okay, okay, that was a good one.|You'll pay for it, though.",
						"music",
						"laugh"
					)
					else burst(ctx, "b", b, {
						bold = "Hey, that's not funny.",
						proud = "Hmph, how childish.",
						shy = "That... wasn't funny.",
						gentle = "Oh, my, that wasn't very nice.",
						dreamy = "Oh, was that a joke?|I didn't like it.",
						cool = "...Really?",
						prickly = "Seriously?|Ugh, go away.",
						dramatic = "*gasp* How could you do this to me?",
						bookish = "I'm writing that down for later, you know.",
						gloomy = "Yeah, that's my luck.",
						polite = "I'd rather you didn't do that again, please.",
						foodie = "You made me drop my snack, you know.",
						nervous = "My heart!|It's still going so fast.",
						_ = "That wasn't funny.",
					}, "anger")
			),
			choices = {
				{
					text = "Ha, good one.",
					lines = if goodSport
						then burst(ctx, "b", b, "Ha, all right, truce.", "music")
						else burst(ctx, "b", b, "You're both as bad as each other.", "anger"),
					effects = if goodSport
						then { { t = "rel", a = "a", b = "b", d = 8 }, { t = "mood", who = "a", d = 4 } }
						else { { t = "rel", a = "a", b = "b", d = -8 }, { t = "mood", who = "b", d = -6 } },
				},
				{
					text = ctx.f("{a}, that's not cool."),
					lines = join(
						burst(ctx, "a", a, {
							cheeky = "fine, fine, sorry|i'll stop for today",
							proud = "Fine, it was a little much.",
							_ = "Fine, fine, I'm sorry.",
						}, "sweat"),
						line("b", ctx.f("Thank you, {player}."), "heart")
					),
					effects = {
						{ t = "mood", who = "a", d = -4 },
						{ t = "mood", who = "b", d = 3 },
						{ t = "rel", a = "a", b = "b", d = 2 },
					},
				},
			},
			default = 2,
			log = ctx.f("{a} {prank}.", { prank = prank }),
		}
	end,
})

-- A compliment.
event({
	id = "compliment",
	actors = 2,
	when = "day",
	weight = function(ctx: Ctx, a: string, b: string)
		return 0.6 + trait(ctx, a, "kind")
	end,
	scene = function(ctx: Ctx, a: string, b: string): Scene
		local things = { "outfit", "hair", "laugh", "taste in music", "handwriting", "cooking" }
		local thing = ctx.rng:pick(things)
		local proud = isPers(ctx, b, "proud")
		local vars = { thing = thing }
		return {
			title = "A compliment",
			lines = join(
				burst(ctx, "a", a, {
					shy = "Um, {b}?|I really like your {thing}, that's all.",
					cool = "{b}, I like your {thing}.",
					cheeky = "{b}, nice {thing}|not even joking",
					sunny = "{b}, I love your {thing}!",
					gentle = "{b}, has anyone told you your {thing} is lovely?",
					bookish = "{b}, I've been meaning to say that I really admire your {thing}.",
					polite = "Excuse me, {b}, I only wanted to say your {thing} is lovely.",
					_ = "{b}, I really like your {thing}.",
				}, "sparkle", nil, vars),
				if proud
					then burst(ctx, "b", b, "Naturally, but thank you for noticing.", "sparkle")
					else burst(ctx, "b", b, {
						sunny = "Really? Ehehe, thank you!",
						gentle = "Oh, my, that's very sweet of you to say.",
						bold = "Hah, thanks, I'll take that.",
						dreamy = "Oh... thank you, nobody's said that before.",
						easygoing = "Mm, thanks, that's nice to hear.",
						shy = "...!|Um, thank you.",
						cheeky = "i know, but thanks for noticing",
						cool = "Thanks, that's good to hear.",
						prickly = "...Thanks.|Don't make it weird.",
						dramatic = "You've made my whole WEEK!",
						bookish = "Oh, thank you, I didn't think anyone had noticed.",
						gloomy = "Really? Heh... thanks, I don't hear that much.",
						polite = "Why, thank you, that's very kind of you to say.",
						foodie = "Thanks, that's nicer than a warm bun.",
						nervous = "R-really? Oh, thank you!",
						_ = "Oh, thank you.",
					}, "heart")
			),
			effects = { { t = "rel", a = "a", b = "b", d = 6 }, { t = "mood", who = "b", d = 5 } },
			log = ctx.f("{a} said nice things about {b}'s {thing}.", vars),
		}
	end,
})

-- A friendly arm wrestle.
event({
	id = "armwrestle",
	actors = 2,
	when = "day",
	weight = function(ctx: Ctx, a: string, b: string)
		return trait(ctx, a, "brave") * 1.2
	end,
	scene = function(ctx: Ctx, a: string, b: string): Scene
		local aWins = ctx.rng:chance(0.5)
		local winner = if aWins then "a" else "b"
		local loser = if aWins then "b" else "a"
		return {
			title = "Arm wrestling",
			lines = join(
				burst(ctx, "a", a, {
					bold = "{b}, arm wrestle, right now.|Loser does the dishes, right?",
					cheeky = "{b}, arm wrestle|loser does the dishes, go",
					proud = "{b}, I challenge you to an arm wrestle.|The loser does the dishes.",
					_ = "{b}, do you fancy an arm wrestle?|Loser does the dishes.",
				}, "idea", "point"),
				burst(ctx, "b", b, {
					shy = "Um... okay?",
					easygoing = "Do I have to?|Mm, fine, just one go.",
					cool = "Sure, let's go.",
					prickly = "Fine, but you'll regret it.",
					dramatic = "I accept your challenge!",
					nervous = "N-now?|Okay, but please don't pull too hard.",
					_ = "You're on.",
				}, "sparkle"),
				line(nil, "After a lot of grunting, one of them finally wins."),
				burst(ctx, winner, if aWins then a else b, {
					proud = "As expected.|Enjoy the dishes.",
					shy = "Oh, I won?|Sorry about the dishes...",
					cool = "The dishes are yours.",
					dramatic = "VICTORY is mine!",
					nervous = "I-I won?|Sorry, the dishes are yours.",
					gentle = "Oh, my, I won.|I'll help you dry, if you like.",
					sunny = "I won, I won!|Have fun with the dishes!",
					cheeky = "hehe, enjoy the dishes",
					polite = "Oh, I won.|I'm terribly sorry about the dishes.",
					gloomy = "I won? Huh.|That never happens.",
					_ = "Hah, the dishes are all yours.",
				}, "sparkle", "cheer"),
				burst(ctx, loser, if aWins then b else a, {
					proud = "Th-that's because I let you win, obviously.",
					easygoing = "Eh, I like doing dishes anyway.",
					bold = "Again, right now.",
					prickly = "My elbow slipped, so that doesn't count.",
					gloomy = "I knew that would happen.",
					_ = "Next time, for sure.",
				}, "sweat")
			),
			effects = {
				{ t = "rel", a = "a", b = "b", d = 4 },
				{ t = "mood", who = winner, d = 4 },
			},
			log = ctx.f("{a} and {b} had an arm wrestle."),
		}
	end,
})

-- Cooking together.
event({
	id = "cook",
	actors = 2,
	when = "day",
	weight = function(ctx: Ctx, a: string, b: string)
		if ctx.quarreling(a, b) then
			return 0
		end
		local w = 0.6
		if ctx.v(a).role == "cook" or ctx.v(b).role == "cook" then
			w += 1
		end
		return w
	end,
	scene = function(ctx: Ctx, a: string, b: string): Scene
		local dishes = {}
		for _, f in Foods.list do
			if DISHES[f.id] then
				table.insert(dishes, f)
			end
		end
		local food = ctx.rng:pick(if #dishes > 0 then dishes else Foods.list)
		local dish = foodPhrase(food)
		local burnt = ctx.rng:chance(0.2)
		return {
			title = "In the kitchen",
			lines = join(
				line(nil, ctx.f("{a} and {b} are making {food} together.", { food = dish })),
				if burnt
					then burst(ctx, "a", a, "Is it meant to smell like that?|...It's not, is it?", "sweat")
					else burst(ctx, "a", a, "Can you pass me the spoon?|No, the big one.", "music"),
				if burnt
					then burst(ctx, "b", b, "...We'll just call it extra crispy.", "sweat")
					else burst(ctx, "b", b, {
						foodie = "Mmm, this is going to be so good.|Can I taste it now?",
						cool = "It smells good.",
						prickly = "You're stirring it wrong.|...It's fine, keep going.",
						_ = "This is going to be so good.",
					}, "heart")
			),
			-- they eat what they make: a good one cheers them both up
			effects = if burnt
				then { { t = "rel", a = "a", b = "b", d = 5 } }
				else {
					{ t = "rel", a = "a", b = "b", d = 6 },
					{ t = "mood", who = "a", d = 4 },
					{ t = "mood", who = "b", d = 4 },
				},
			log = ctx.f("{a} and {b} cooked {food}.", { food = dish }),
		}
	end,
})

-- A late night secret.
event({
	id = "secret",
	actors = 2,
	when = "night",
	weight = function(ctx: Ctx, a: string, b: string)
		if ctx.quarreling(a, b) or ctx.rel(a, b) < 15 then
			return 0
		end
		return 1.5
	end,
	scene = function(ctx: Ctx, a: string, b: string): Scene
		return {
			title = "A late night talk",
			lines = join(
				line(nil, ctx.f("{a} and {b} stayed up late talking.")),
				burst(ctx, "a", a, {
					shy = "Um... can I tell you something?|Promise you won't laugh.",
					prickly = "I'm going to tell you something.|If you laugh, I'm leaving.",
					cool = "Can I tell you something?|Don't laugh.",
					_ = "Can I tell you something?|You can't laugh, though.",
				}, "sweat"),
				burst(ctx, "b", b, {
					cheeky = "i promise|...i'll try, anyway",
					cool = "I promise.",
					prickly = "Just say it.|I won't laugh, much.",
					nervous = "I promise, is it something bad?|You can tell me.",
					_ = "I promise.",
				}, "heart"),
				line(nil, "Whatever it was, it stays between the two of them.")
			),
			effects = { { t = "rel", a = "a", b = "b", d = 14 } },
			log = ctx.f("{a} told {b} a secret."),
		}
	end,
})

-- A race.
event({
	id = "race",
	actors = 2,
	when = "day",
	weight = function(ctx: Ctx, a: string, b: string)
		return 0.5 + trait(ctx, a, "brave") * 0.6
	end,
	scene = function(ctx: Ctx, a: string, b: string): Scene
		local aWins = ctx.rng:chance(0.5)
		local winner = if aWins then "a" else "b"
		local loser = if aWins then "b" else "a"
		local loserVid = if aWins then b else a
		local sore = isPers(ctx, loserVid, "proud", "bold")
		return {
			title = "A race",
			lines = join(
				burst(ctx, "a", a, {
					cheeky = "race you to the fence, {b}, go",
					sunny = "{b}, race you to the fence!|Three, two, one, go!",
					_ = "Race you to the fence, {b}.",
				}, "idea", "point"),
				line(nil, "And they're off."),
				burst(ctx, winner, if aWins then a else b, {
					proud = "Hmph, as expected.",
					shy = "Oh... I won?",
					bold = "Hah, first!",
					cool = "I win.",
					dramatic = "The crowd goes wild!",
					nervous = "I won?|I-I actually won!",
					_ = "I win.",
				}, "sparkle", "cheer"),
				if sore
					then burst(ctx, loser, loserVid, "That didn't count, I wasn't ready.", "anger")
					else burst(ctx, loser, loserVid, {
						shy = "You're really fast...",
						easygoing = "Mm, nope, I'm done, you win.",
						dreamy = "Hmm... I was watching a boat go past.|Well done, though.",
						prickly = "You started early.|...Fine, well run.",
						gloomy = "Yeah, I'm slow, I know.",
						foodie = "I'd have won if I hadn't just had lunch.",
						cool = "Hm, you're quick.",
						_ = "Wow, you're fast.",
					}, "sweat")
			),
			effects = {
				{ t = "mood", who = winner, d = 4 },
				{ t = "mood", who = loser, d = if sore then -5 else 0 },
				{ t = "rel", a = "a", b = "b", d = if sore then 0 else 4 },
			},
			log = ctx.f("{a} raced {b}."),
		}
	end,
})

-- A joke.
event({
	id = "joke",
	actors = 2,
	when = "any",
	weight = function(ctx: Ctx, a: string, b: string)
		return 0.4 + trait(ctx, a, "mischief") * 0.6 + trait(ctx, a, "social") * 0.4
	end,
	scene = function(ctx: Ctx, a: string, b: string): Scene
		local joke = ctx.rng:pick(JOKES)
		local laughs = joke[2] == "laugh" or isPers(ctx, b, "sunny", "dreamy", "cheeky")
		return {
			title = "A joke",
			lines = join(
				burst(ctx, "a", a, {
					cheeky = "ok ok, listen to this one",
					shy = "Um... I heard a joke.",
					_ = "Okay, listen to this.",
				}, "idea"),
				line("a", joke[1], "music", "point"),
				if laughs
					then burst(ctx, "b", b, {
						dreamy = "Hee...|I'll laugh about that again later.",
						cheeky = "ha, i'm stealing that one",
						cool = "...Heh.",
						dramatic = "HA! Oh, that's wonderful.",
						gloomy = "Heh, okay, that got me.",
						polite = "Oh, ha ha, that's a good one.",
						_ = "Hahaha, okay, that's a good one.",
					}, "music", "laugh")
					else burst(ctx, "b", b, {
						proud = "That was beneath both of us.",
						gentle = "Oh, dear... ha.",
						shy = "Um... heehee?",
						bold = "Boo, that was terrible.",
						cool = "No.",
						prickly = "I'm going to pretend you didn't say that.",
						bookish = "I've heard that one before.|It's in a joke book older than both of us.",
						polite = "Ah, very good.|I'll have to remember that one.",
						_ = "...I'm leaving now.",
					}, "sweat")
			),
			effects = { { t = "rel", a = "a", b = "b", d = if laughs then 6 else -1 } },
			log = ctx.f("{a} told {b} a joke."),
		}
	end,
})

-- Something lost, and a friend who helps.
event({
	id = "lost",
	actors = 2,
	when = "day",
	weight = function(ctx: Ctx, a: string, b: string)
		return 0.4 + trait(ctx, a, "lazy") * 0.5 + (1 - trait(ctx, a, "focus")) * 0.5
	end,
	scene = function(ctx: Ctx, a: string, b: string): Scene
		local thing = ctx.rng:pick(LOST)
		local helps = trait(ctx, b, "kind") > 0.4
		local vars = { thing = thing }
		return {
			title = "Lost and found",
			lines = join(
				burst(ctx, "a", a, {
					dramatic = "{player}, my {thing} is gone forever!|I've turned the whole house upside down.",
					nervous = "Has anyone seen my {thing}?|I've looked everywhere, twice, three times.",
					prickly = "Has anyone seen my {thing}?|Don't ask if I've looked, I've looked.",
					cool = "{player}, I've lost my {thing}.",
					sunny = "{player}, have you seen my {thing}?|It was right here a minute ago!",
					_ = "Has anyone seen my {thing}?|I've looked everywhere.",
				}, "question", nil, vars),
				if helps
					then burst(ctx, "b", b, "Come on, let's look together.", "idea")
					else burst(ctx, "b", b, "Have you checked your pockets?", "question")
			),
			choices = {
				{
					text = "I'll help you look.",
					lines = join(
						line(nil, ctx.f("It was under a flowerpot the whole time.")),
						-- (thanks to both only if the friend helped look too)
						burst(
							ctx,
							"a",
							a,
							if helps
								then {
									prickly = "...Under a flowerpot.|Don't say anything, but thanks.",
									cool = "There it is.|...Thanks, both of you.",
									dramatic = "Found, FOUND!|Thank you both, I owe you everything.",
									_ = "Thank you both.|I owe you one, {player}.",
								}
								else {
									prickly = "...Under a flowerpot.|Don't say anything, but thanks.",
									cool = "There it is.|...Thanks, {player}.",
									dramatic = "Found, FOUND!|Thank you, {player}, I owe you everything.",
									_ = "Thank you, {player}.|I owe you one.",
								},
							"heart",
							"cheer"
						)
					),
					effects = { { t = "rel", a = "a", b = "b", d = 8 }, { t = "mood", who = "a", d = 6 } },
				},
				{
					text = "It'll turn up.",
					lines = burst(ctx, "a", a, "I hope so...", "sad"),
					effects = { { t = "mood", who = "a", d = -3 } },
				},
			},
			default = 1,
			log = ctx.f("{a} lost their {thing}.", vars),
		}
	end,
})

-- Teaching a skill.
event({
	id = "teach",
	actors = 2,
	when = "day",
	weight = function(ctx: Ctx, a: string, b: string)
		if ctx.v(a).lv <= ctx.v(b).lv then
			return 0.2
		end
		return 0.9
	end,
	scene = function(ctx: Ctx, a: string, b: string): Scene
		local skill = ctx.rng:pick(SKILLS)
		local vars = { skill = skill }
		return {
			title = "A lesson",
			lines = join(
				burst(ctx, "a", a, {
					proud = "I'll show you how to {skill}.|I'm very good at it, naturally.",
					cheeky = "want to learn how to {skill}?|i'll only laugh a little bit",
					_ = "Do you want me to show you how to {skill}?",
				}, "idea", nil, vars),
				burst(ctx, "b", b, {
					cool = "Sure, show me.",
					prickly = "...Fine, go on, then.",
					polite = "Yes, please, thank you.",
					nervous = "What if I can't do it?|...Okay, yes, please.",
					proud = "Hmph, fine, show me.",
					_ = "Yes, please.",
				}, "sparkle"),
				line(nil, ctx.f("After a few tries, {b} gets the hang of it.")),
				burst(ctx, "b", b, {
					shy = "I did it...|I actually did it.",
					proud = "There, I knew I'd get it.",
					cool = "Got it, thanks.",
					prickly = "That was easy.|...Thanks, though.",
					dramatic = "I have learned, and I'm a changed person!",
					bookish = "Oh, it's all in the timing.|That makes sense now.",
					gloomy = "Huh, I can do it.|I really didn't think I could.",
					polite = "Thank you so much for showing me.",
					nervous = "Did I do it right?|I did it, I really did it!",
					_ = "Look, I did it.",
				}, "sparkle", "cheer")
			),
			effects = { { t = "xp", who = "b", d = 35 }, { t = "rel", a = "a", b = "b", d = 5 } },
			log = ctx.f("{a} taught {b} to {skill}.", vars),
		}
	end,
})

-- Feeling left out of a friendship.
event({
	id = "leftout",
	actors = 3,
	when = "day",
	weight = function(ctx: Ctx, a: string, b: string, c: string)
		if ctx.rel(b, c) < 40 or ctx.rel(a, b) > 30 then
			return 0
		end
		return 1.2 + (1 - trait(ctx, a, "social"))
	end,
	scene = function(ctx: Ctx, a: string, b: string, c: string): Scene
		return {
			title = "Left out",
			lines = join(
				line(nil, ctx.f("{b} and {c} are laughing together again.")),
				burst(ctx, "a", a, {
					shy = "They never ask me to come along...|It's fine, really.",
					proud = "Hmph, I don't need them.|...They could ask, though.",
					bold = "They could at least ask me, right?",
					sunny = "{player}... do they not like me?|I really thought they did.",
					cool = "Hm. They didn't ask me again, but it's fine.",
					prickly = "Don't look at me like that.|I don't care, I really don't.",
					dramatic = "Forgotten, cast aside like an old shoe!",
					gloomy = "Nobody ever asks me, as usual.|It's fine, I'm used to it.",
					polite = "I don't want to intrude.|They seem to be having such fun.",
					nervous = "Did I do something?|Did I say something wrong?",
					_ = "They always do things without me.",
				}, "sad")
			),
			choices = {
				{
					text = ctx.f("Ask them to invite {a}."),
					lines = join(
						line("b", ctx.f("Hey, {a}, come and join us."), "wave"),
						burst(ctx, "a", a, {
							prickly = "...Okay, fine, if you want.",
							gloomy = "Really?|...Okay, I'd like that.",
							shy = "...!|Okay.",
							_ = "Really?|Okay, I'd like that.",
						}, "heart")
					),
					effects = {
						{ t = "rel", a = "a", b = "b", d = 8 },
						{ t = "rel", a = "a", b = "c", d = 8 },
						{ t = "mood", who = "a", d = 6 },
					},
				},
				{
					text = ctx.f("Hang out with me instead?"),
					lines = burst(ctx, "a", a, {
						shy = "...!|Thanks, that really helps.",
						prickly = "...Thanks.|Don't tell anyone I was sulking.",
						gloomy = "Thanks, {player}, I mean it.",
						cool = "...Okay, thanks.",
						_ = "Thanks, {player}, you're a good friend.",
					}, "heart"),
					effects = { { t = "mood", who = "a", d = 8 } },
				},
			},
			default = 1,
			log = ctx.f("{a} felt left out by {b} and {c}."),
		}
	end,
})

-- Craving a food. There is no shop and no bag of food (the user: "when a character gets a
-- craving, allow the player to simply pay to buy it"): the answer pays for it there and then, at
-- the price a craving wish costs (Life.cravingPrice), and does what a granted craving does.
event({
	id = "craving",
	actors = 1,
	when = "day",
	weight = function(ctx: Ctx, a: string)
		-- someone already wishing for a food has their bubble up; this is for the others
		local wish = ctx.v(a).wish
		if wish and wish.kind == "food" then
			return 0
		end
		return 1.2
	end,
	scene = function(ctx: Ctx, a: string): Scene
		local v = ctx.v(a)
		local fav = Foods.get(v.fav)
		local food = if fav and ctx.rng:chance(0.35) then fav else ctx.rng:pick(Foods.list)
		local loves = fav ~= nil and food.id == fav.id
		local price = ctx.cravingPrice(food.id)
		local L = Tuning.Life
		local name = foodPhrase(food)
		local vars = { food = name, Food = capital(name) }
		return {
			title = "A craving",
			lines = join(
				line("a", ctx.f("{player}...", {}), "idea"),
				burst(ctx, "a", a, {
					sunny = "I really, really want {food} right now!|Can we go and get it together?",
					bold = "I need {food}, and I need it now.",
					shy = "Um... I really want {food}.|Sorry, I know it's silly.",
					cool = "I could really go for {food} right now.",
					prickly = "I want {food}, so don't laugh.",
					dramatic = "If I don't have {food} today, I'll simply FADE away!",
					polite = "Might I ask for {food}, if it's no trouble?|I've been thinking about it all day.",
					foodie = "I've been thinking about {food} since breakfast.|Actually, since yesterday's breakfast.",
					nervous = "Is it okay that I really want {food}?|I-I can't stop thinking about it.",
					easygoing = "Mm, you know what would be nice right now?|{Food}, just saying.",
					cheeky = "you know what i want? {food}|i'll keep saying it until it happens",
					gentle = "Oh, my, I've been dreaming about {food} all afternoon.",
					bookish = "Actually, I read a recipe this morning, and now all I want is {food}.",
					dreamy = "Hmm... I keep thinking about {food}.|It's all I can think about today.",
					_ = "I really want {food} right now.",
				}, "idea", nil, vars)
			),
			choices = {
				{
					text = ctx.f("My treat ({price} coins)", { price = price }),
					cost = price,
					lines = if loves
						then burst(ctx, "a", a, {
							cool = "{Food}, my favourite.|Thanks, {player}, I owe you.",
							prickly = "{Food}? You remembered.|...Thanks.",
							shy = "...!|{Food}, my favourite... thank you.",
							polite = "{Food}, my favourite!|Thank you kindly, {player}.",
							proud = "{Food}, my favourite, naturally.|You have excellent taste, {player}.",
							gloomy = "{Food}, my favourite?|Heh... you actually remembered.",
							_ = "{Food}, my favourite!|You're the best, {player}.",
						}, "heart", "cheer", vars)
						else burst(ctx, "a", a, {
							prickly = "...Thanks, you didn't have to.",
							cool = "Thanks, I owe you.",
							polite = "Thank you so much, that's very kind.",
							shy = "...!|Thank you.",
							_ = "You're the best, {player}.",
						}, "heart", "cheer"),
					effects = {
						{ t = "coins", d = -price },
						{ t = "mood", who = "a", d = L.WishMood + (if loves then L.FavWishMood else 0) },
						{ t = "hearts", who = "a", n = L.WishHearts + (if loves then L.FavWishHearts else 0) },
					},
				},
				{
					text = "Not right now.",
					lines = burst(ctx, "a", a, {
						proud = "Hmph, fine, I didn't need it anyway.",
						bold = "Ugh, fine.",
						cool = "Okay, another time.",
						prickly = "Fine, whatever.|I'll stop thinking about it soon.",
						dramatic = "Then I shall suffer, quietly, all afternoon.",
						gloomy = "Yeah, I figured.",
						foodie = "Okay... my stomach's going to be so sad, though.",
						sunny = "Aw, later, then!",
						gentle = "All right, it can wait.|Have you eaten, though?",
						shy = "Oh... okay, sorry for asking.",
						polite = "Of course, another time, then.",
						nervous = "O-okay, that's fine, sorry.",
						easygoing = "Mm, no rush, another day.",
						cheeky = "ok, but i'm going to keep saying it",
						bookish = "That's fair, it was only a craving.",
						dreamy = "Hmm... okay, I'll dream about it instead.",
						_ = "Okay, another time, then.",
					}, "sad"),
					effects = { { t = "mood", who = "a", d = -4 } },
				},
			},
			default = 2,
			log = ctx.f("{a} wanted {food}.", { food = name }),
		}
	end,
})

-- Asking for coins for something they've had their eye on.
event({
	id = "wish",
	actors = 1,
	when = "day",
	weight = function(ctx: Ctx, a: string)
		return 0.8
	end,
	scene = function(ctx: Ctx, a: string): Scene
		local thing = ctx.rng:pick(WANTS)
		local cost = ctx.rng:int(4, 12) * 25
		local vars = { cost = cost, thing = thing }
		return {
			title = "A favour",
			lines = burst(ctx, "a", a, {
				shy = "Um, {player}, can I ask you something?|You can say no.|Could I have {cost} coins for {thing}?",
				proud = "{player}, I have a small request.|I've had my eye on {thing}, and {cost} coins would cover it.",
				cool = "{player}, could I have {cost} coins?|It's for {thing}.",
				nervous = "S-sorry, {player}, can I ask you something?|Could I have {cost} coins for {thing}?",
				cheeky = "{player}, hypothetically speaking|if someone wanted {cost} coins for {thing}, would you say yes",
				polite = "Excuse me, {player}, I hope this isn't rude.|Might I ask for {cost} coins?|I've had my eye on {thing}.",
				sunny = "{player}, guess what I saw at the market!|It's {thing}, and it's only {cost} coins!|Could you help me get it?",
				_ = "{player}, can I ask you something?|Could I have {cost} coins?|I've had my eye on {thing}.",
			}, "question", nil, vars),
			choices = {
				{
					text = ctx.f("Here you go ({cost} coins)", vars),
					cost = cost,
					lines = burst(ctx, "a", a, {
						sunny = "Really? Thank you, thank you!",
						cool = "Thanks, really.",
						prickly = "...Thanks, I'll pay you back somehow.",
						polite = "Thank you, I'm very grateful.",
						shy = "...!|Thank you.",
						_ = "Thank you, I'm going to buy it this afternoon.",
					}, "sparkle", "cheer"),
					effects = { { t = "coins", d = -cost }, { t = "mood", who = "a", d = 12 } },
				},
				{
					text = "Not this time.",
					lines = burst(ctx, "a", a, {
						proud = "Fine, I'll save up.|I'm good at saving.",
						shy = "Oh, of course.|Sorry for asking.",
						sunny = "Aw, later, then!",
						prickly = "Fine, I didn't really need it.",
						gloomy = "Yeah, I figured.",
						cool = "Okay, that's fair.",
						dramatic = "Then I shall go without, BRAVELY.",
						nervous = "Okay, s-sorry for asking.",
						_ = "Okay, maybe next time.",
					}, "sad"),
					effects = { { t = "mood", who = "a", d = -4 } },
				},
			},
			default = 2,
			log = ctx.f("{a} asked for coins for {thing}.", vars),
		}
	end,
})

-- Wanting something near their bed (ties into building).
event({
	id = "request",
	actors = 1,
	when = "day",
	weight = function(ctx: Ctx, a: string)
		local v = ctx.v(a)
		if not v.bed or ctx.requests(a) > 0 or ctx.requestCount() >= Tuning.Events.MaxPendingRequests then
			return 0
		end
		return 1.3
	end,
	scene = function(ctx: Ctx, a: string): Scene
		local tags = {}
		for tag in Catalog.Tags do
			if not ctx.roomHas(a, tag) then
				table.insert(tags, tag)
			end
		end
		table.sort(tags)
		if #tags == 0 then
			return {
				title = "A happy room",
				lines = burst(ctx, "a", a, {
					cool = "{player}, I like my room.|It's got everything I need.",
					prickly = "My room's fine.|...It's great, actually, so don't let it go to your head.",
					_ = "{player}, my room has everything now.|I love it here.",
				}, "heart"),
				effects = { { t = "mood", who = "a", d = 5 } },
				log = ctx.f("{a} loves their room."),
			}
		end
		local tag = ctx.rng:pick(tags)
		local vars = { thing = ASKS[tag] or Catalog.Tags[tag] }
		return {
			title = "A wish",
			lines = join(
				burst(ctx, "a", a, {
					sunny = "{player}, I've had an idea!|Could I have {thing} near my bed?",
					shy = "Um, {player}... only if it's okay.|Could I have {thing} near my bed?",
					bold = "{player}, I want {thing} by my bed.|You can sort that out, right?",
					cool = "{player}, could I get {thing} by my bed?",
					prickly = "My room's missing something.|I'd like {thing} by the bed, if you're not busy.",
					polite = "Hello, {player}.|Would it be possible to have {thing} near my bed?",
					nervous = "C-can I ask for something?|Could I have {thing} near my bed?",
					_ = "Hey, {player}, do you think I could have {thing} near my bed?",
				}, "idea", nil, vars),
				line(nil, "Put one within a few steps of their bed in Build mode.")
			),
			effects = { { t = "request", who = "a", tag = tag } },
			log = ctx.f("{a} would like {thing} near their bed.", { thing = Catalog.Tags[tag] }),
		}
	end,
})

-- No bed to sleep in.
event({
	id = "nobed",
	actors = 1,
	when = "any",
	weight = function(ctx: Ctx, a: string)
		return if ctx.v(a).bed then 0 else 2.5
	end,
	scene = function(ctx: Ctx, a: string): Scene
		return {
			title = "Nowhere to sleep",
			lines = join(
				burst(ctx, "a", a, {
					bold = "Right, so where's my bed?",
					proud = "I'll need a bed, and a good one.",
					easygoing = "So... where am I supposed to nap?",
					sunny = "{player}, quick question!|Where do I sleep?",
					cool = "Hm, I don't have a bed yet.",
					prickly = "I'm not sleeping on the floor.|Just so you know.",
					dramatic = "I have nowhere to lay my head, {player}!",
					bookish = "I measured the floor, and it's not long enough for me.",
					gloomy = "It's the floor again tonight, I guess.",
					polite = "Sorry to ask, {player}.|Is there a bed for me somewhere?",
					foodie = "Where am I meant to sleep?|And where do I keep my snacks?",
					nervous = "Is there a bed for me?|Where do I go tonight?",
					shy = "Um, {player}... where do I sleep?",
					cheeky = "found a nice bush to sleep in|kidding, where's my bed",
					_ = "Um, where do I sleep?",
				}, "sad"),
				line(nil, "Every villager needs a bed. Find beds under Furniture in Build mode.")
			),
			effects = { { t = "mood", who = "a", d = -3 } },
			log = ctx.f("{a} has no bed."),
		}
	end,
})

-- A dream. (Its cutscene counts on two lines, both theirs.)
event({
	id = "dream",
	actors = 1,
	when = "day",
	weight = function(ctx: Ctx, a: string)
		return 0.4 + (1 - trait(ctx, a, "focus")) * 0.8
	end,
	scene = function(ctx: Ctx, a: string): Scene
		local dream = ctx.rng:pick(DREAMS)
		return {
			title = "A dream",
			lines = {
				line(
					"a",
					ctx.f("{player}, I had the strangest dream last night about {dream}.", { dream = dream }),
					"zzz"
				),
				by(ctx, "a", a, {
					dreamy = "Hmm... I think it was trying to tell me something.",
					easygoing = "Mm, it was weird, but I slept really well.",
					proud = "Even my dreams are more interesting than most people's.",
					cool = "Hm, it was a weird one.",
					prickly = "Don't analyse it, I can see you analysing it.",
					dramatic = "It felt so real, I woke up gasping!",
					bookish = "Actually, dreams are how the brain sorts through the day, so I must have had a strange one.",
					gloomy = "Heh... I woke up just before it got good, as usual.",
					foodie = "I woke up hungry, which I think is a good sign.",
					nervous = "W-what does it mean, is it something bad?",
					cheeky = "it means i should get the day off, obviously",
					sunny = "It was so much fun, I want to dream it again tonight!",
					gentle = "It was a sweet dream, and I woke up smiling.",
					shy = "Um... is that a strange thing to dream about?",
					polite = "It was a rather pleasant dream, all told.",
					_ = "I think it means something, or maybe I was just hungry.",
				}, "question"),
			},
			effects = { { t = "mood", who = "a", d = 2 } },
			log = ctx.f("{a} dreamed about {dream}.", { dream = dream }),
		}
	end,
})

-- Finding coins.
event({
	id = "coins",
	actors = 1,
	when = "day",
	weight = function(ctx: Ctx, a: string)
		return 0.7
	end,
	scene = function(ctx: Ctx, a: string): Scene
		local amount = ctx.rng:int(Tuning.Rewards.EventCoinsMin, Tuning.Rewards.EventCoinsMax)
		local vars = { coins = amount }
		return {
			title = "Lucky find",
			lines = burst(ctx, "a", a, {
				sunny = "{player}, {player}, look!|I found {coins} coins in the grass!",
				cool = "{player}, I found {coins} coins in the grass.",
				cheeky = "finders keepers|...fine, {coins} coins for the town",
				gloomy = "I found {coins} coins in the grass.|Somebody's going to miss them, so they'd better go to the town.",
				polite = "Hello, {player}, I found {coins} coins by the path.|I think they should go to the town.",
				foodie = "I found {coins} coins in the grass!|That's a lot of buns, but it's for the town.",
				_ = "{player}, look, I found {coins} coins in the grass.",
			}, "sparkle", "point", vars),
			effects = { { t = "coins", d = amount } },
			log = ctx.f("{a} found {coins} coins.", vars),
		}
	end,
})

-- A cold.
event({
	id = "cold",
	actors = 1,
	when = "day",
	weight = function(ctx: Ctx, a: string)
		if ctx.v(a).sick and ctx.v(a).sick > ctx.now then
			return 0
		end
		return 0.45
	end,
	scene = function(ctx: Ctx, a: string): Scene
		-- There is no medicine to buy. A villager who works as the town's doctor sees to a cold
		-- at once; otherwise it is a day in bed (no pay while they are in it), or carrying on
		-- in a worse mood.
		local doctor: string? = nil
		for _, vid in ctx.profile.order do
			local w = if vid ~= a then ctx.job(vid) else nil
			if w and w.job.id == "doctor" then
				doctor = vid
				break
			end
		end
		local choices = {}
		local lines = join(
			line("a", "Achoo.", "sweat"),
			burst(ctx, "a", a, {
				dramatic = "I'm DYING, {player}.|Tell everyone I said goodbye.",
				prickly = "It's just a cold.|Stop looking at me like that.",
				gloomy = "Of course I caught a cold, as usual.",
				nervous = "Is it a cold?|It's only a cold, right?",
				cool = "Hm, I've caught a cold.|I'll be fine, but I'm keeping my distance.",
				easygoing = "*sniff* Well, at least it's a good excuse to lie down.",
				sunny = "{player}, I'm fine, really!|Achoo... okay, maybe not completely fine.",
				gentle = "Oh, my, I think I've caught a cold.|Don't come too close, all right?",
				_ = "I think I've caught a cold.",
			}, "sweat")
		)
		if doctor then
			local name = ctx.v(doctor).name
			table.insert(choices, {
				text = ctx.f("Go and see {doctor}.", { doctor = name }),
				lines = join(
					line(nil, ctx.f("{doctor} had a look and sent {a} off with a hot lemon drink.", { doctor = name })),
					burst(ctx, "a", a, "It tastes awful.|...I do feel better, though.", "sparkle")
				),
				effects = {
					{ t = "mood", who = "a", d = 4 },
					{ t = "relv", a = a, b = doctor, d = 4 },
					{ t = "xpv", vid = doctor, d = 10 },
				},
			})
		else
			table.insert(
				lines,
				line(nil, "A town doctor could see to this, and a clinic desk in Build mode opens the job.")
			)
		end
		table.insert(choices, {
			text = "Go to bed and rest.",
			lines = burst(ctx, "a", a, "Okay... wake me up when I'm better, {player}.", "zzz"),
			effects = { { t = "sick", who = "a", minutes = 5 }, { t = "mood", who = "a", d = -2 } },
		})
		if not doctor then
			table.insert(choices, {
				text = "Can you carry on?",
				lines = burst(ctx, "a", a, "Fine, I'll keep going.|Achoo.", "sad"),
				effects = { { t = "mood", who = "a", d = -8 } },
			})
		end
		return {
			title = "Achoo",
			lines = lines,
			choices = choices,
			default = if doctor then 2 else 1,
			log = ctx.f("{a} caught a cold."),
		}
	end,
})

-- A hobby.
event({
	id = "hobby",
	actors = 1,
	when = "day",
	weight = function(ctx: Ctx, a: string)
		return 0.8
	end,
	scene = function(ctx: Ctx, a: string): Scene
		local hobby = ctx.rng:pick(HOBBIES)
		return {
			title = "Free time",
			lines = join(
				line(nil, ctx.f("{a} spent the afternoon {hobby}.", { hobby = hobby })),
				burst(ctx, "a", a, {
					easygoing = "Mm, that was a good afternoon.",
					proud = "I'm getting very good at it, if I say so myself.",
					dreamy = "Hmm... is it evening already?",
					shy = "That was nice...",
					cool = "That was a good afternoon.",
					prickly = "What, it's a perfectly normal thing to do.",
					dramatic = "Hours, {player}, gone in the blink of an eye!",
					bookish = "I timed it, and it was four hours.|It only felt like one.",
					gloomy = "That was actually fine.|I don't get many afternoons like that.",
					polite = "That was a lovely afternoon, all told.",
					foodie = "I've worked up a real appetite now.|What's for dinner?",
					nervous = "Was that a waste of a whole day?|It didn't feel like one.",
					sunny = "That was so much fun!|Let's do it together next time!",
					_ = "That was time well spent.",
				}, "sparkle")
			),
			effects = { { t = "mood", who = "a", d = 4 } },
			log = ctx.f("{a} spent the afternoon {hobby}.", { hobby = hobby }),
		}
	end,
})

-- Sleepwalking.
event({
	id = "sleepwalk",
	actors = 1,
	when = "night",
	weight = function(ctx: Ctx, a: string)
		return 0.6 + trait(ctx, a, "lazy") * 0.4
	end,
	scene = function(ctx: Ctx, a: string): Scene
		return {
			title = "Sleepwalking",
			lines = join(
				line(nil, ctx.f("{a} is sleepwalking again.")),
				burst(ctx, "a", a, {
					foodie = "Mmm... more gravy on the pancakes, please...",
					dramatic = "Mmm... the crown is mine, all mine...",
					bookish = "Mmm... chapter nine, no, chapter ten...",
					nervous = "Mm... did I remember to lock the door...",
					cheeky = "mmm... hehe, got you...",
					_ = "Mmm... five more pancakes, please...",
				}, "zzz")
			),
			effects = { { t = "mood", who = "a", d = 1 } },
			log = ctx.f("{a} went sleepwalking."),
		}
	end,
})

-- Practising at work.
event({
	id = "practice",
	actors = 1,
	when = "day",
	weight = function(ctx: Ctx, a: string)
		if not ctx.job(a) then
			return 0
		end
		return 0.4 + trait(ctx, a, "focus") * 0.6
	end,
	scene = function(ctx: Ctx, a: string): Scene
		local place = Kit.workplace(ctx, a)
		return {
			title = "Practice",
			lines = join(
				line(nil, ctx.f("{a} stayed late at the {place} to practise.", { place = place })),
				burst(ctx, "a", a, {
					proud = "I was good already, and now I'm even better.",
					shy = "I think I'm getting it...",
					cool = "I'm getting there.",
					prickly = "I'm not staying late for fun.|...Okay, maybe a little for fun.",
					dramatic = "Practice makes perfect, {player}, or nearly perfect!",
					gloomy = "It's still not right, but it's closer.",
					nervous = "Just one more go, then one more.|I-I want to be sure.",
					easygoing = "Okay, that's enough practice for the week.",
					bookish = "Actually, I've been timing myself, and I'm faster every round.",
					sunny = "One more time, and then I've got it!",
					_ = "I'm getting the hang of this.",
				}, "sparkle", "point")
			),
			effects = { { t = "xp", who = "a", d = 25 } },
			log = ctx.f("{a} practised at the {place}.", { place = place }),
		}
	end,
})

-- Lonely.
event({
	id = "lonely",
	actors = 2,
	when = "day",
	weight = function(ctx: Ctx, a: string, b: string)
		if ctx.bestScore(a) >= 10 or ctx.rel(a, b) ~= 0 then
			return 0
		end
		return 1.5
	end,
	scene = function(ctx: Ctx, a: string, b: string): Scene
		return {
			title = "A bit lonely",
			lines = burst(ctx, "a", a, {
				shy = "Um, {player}... everyone seems to have someone to talk to.|Everyone except me...",
				proud = "Hmph, I don't need friends.|...It would be nice, though.",
				bold = "Nobody ever asks me along, you know?",
				sunny = "{player}... I keep saying hi to people.|They say hi back, and that's it.",
				cool = "Hm, it's quiet, that's all.",
				prickly = "I'm fine on my own.|...Most of the time.",
				dramatic = "Alone, {player}, in a town FULL of people!",
				gloomy = "Nobody really talks to me.|Heh... I get it.",
				polite = "I don't want to bother anyone.|But it does get a little lonely.",
				nervous = "What if nobody here likes me?|What if it's something I'm doing?",
				_ = "Everyone seems to have friends except me.",
			}, "sad"),
			choices = {
				{
					text = ctx.f("Come and meet {b}."),
					lines = join(
						burst(ctx, "b", b, {
							prickly = "Hi, {a}.|...You can sit with me, if you want.",
							shy = "Um, hi, {a}...|I've been meaning to say hello.",
							bold = "Hey, {a}, come and sit with me.",
							cheeky = "hi, {a}, you're stuck with me now, no take backs",
							_ = "Hi, {a}, I've been meaning to say hello.",
						}, "wave"),
						burst(ctx, "a", a, {
							shy = "Oh... hi.",
							prickly = "...Hi.|Hello, I mean.",
							_ = "Oh, hi.",
						}, "heart")
					),
					effects = { { t = "rel", a = "a", b = "b", d = 12 }, { t = "mood", who = "a", d = 6 } },
				},
				{
					text = "Do you want some space?",
					lines = burst(ctx, "a", a, {
						shy = "...Okay.|Thanks for asking, though.",
						proud = "Hmph, I always want space.|...Thanks, though.",
						prickly = "Yes.|...But thanks for asking.",
						gloomy = "Yeah, I'm used to it, heh.",
						sunny = "Okay...|Maybe I'll try again tomorrow!",
						nervous = "Okay... is that okay?|Sorry.",
						dramatic = "Yes, leave me to my sorrow!|...Just for today.",
						_ = "Yeah, I think I'll go for a walk on my own.",
					}, "sad"),
					effects = { { t = "mood", who = "a", d = -2 } },
				},
			},
			default = 1,
			log = ctx.f("{a} felt lonely."),
		}
	end,
})

-- A birthday (the day matches their birthday on the town calendar). (Its cutscene counts on
-- three lines: the narrator twice, then theirs.)
event({
	id = "birthday",
	actors = 1,
	when = "any",
	weight = function(ctx: Ctx, a: string)
		local v = ctx.v(a)
		if v.bday.s == ctx.season and v.bday.d == ctx.dayOfSeason and ctx.bdayDone(a) ~= ctx.day then
			return 200
		end
		return 0
	end,
	scene = function(ctx: Ctx, a: string): Scene
		local effects: { any } = {
			{ t = "mood", who = "a", d = 20 },
			{ t = "coins", d = 100 },
			{ t = "bday", who = "a" },
			{ t = "festival" },
		}
		for _, other in ctx.present do
			if other ~= a then
				table.insert(effects, { t = "relv", a = a, b = other, d = 5 })
			end
		end
		return {
			title = "Happy birthday",
			lines = {
				line(nil, ctx.f("It's {a}'s birthday today.")),
				line(nil, "Everyone gathers round with a cake."),
				by(ctx, "a", a, {
					shy = "You all remembered? Oh... thank you.",
					proud = "Of course you remembered, but thank you all the same.",
					bold = "Cake, right, so who's cutting it?",
					easygoing = "Aw, you didn't have to do all this, but is there cake?",
					sunny = "You all remembered, {player} too, it's the best day ever!",
					cool = "...Thanks, really.",
					prickly = "You didn't have to do all this... but thanks.",
					dramatic = "For me, all of this? I can't believe it, thank you!",
					bookish = "That's three hundred and sixty five days older, I counted.",
					gloomy = "I thought nobody knew... this is really nice.",
					polite = "Thank you all so much, I'm very touched.",
					foodie = "Is that lemon? Mmm, I can smell it from here.",
					nervous = "Is it really for me? Oh, thank you.",
					cheeky = "a cake, for me? i'm having the first three slices",
					gentle = "Oh, my, you're all too kind to me.",
					dreamy = "Hmm... I forgot it was today, thank you all.",
					_ = "You all remembered, and this is the best.",
				}, "heart", "cheer"),
			},
			effects = effects,
			log = ctx.f("{a} had a birthday party."),
		}
	end,
})

-- A dance party.
event({
	id = "festival",
	actors = 0,
	when = "any",
	weight = function(ctx: Ctx)
		if #ctx.present < 3 then
			return 0
		end
		return 0.4
	end,
	scene = function(ctx: Ctx): Scene
		local effects: { any } = { { t = "festival" }, { t = "coins", d = 60 } }
		for i = 1, #ctx.present do
			for j = i + 1, #ctx.present do
				table.insert(effects, { t = "relv", a = ctx.present[i], b = ctx.present[j], d = 3 })
			end
		end
		return {
			title = "Dance party",
			lines = { line(nil, "Someone turned the music up, and now everyone's dancing.") },
			effects = effects,
			log = "There was a dance party.",
		}
	end,
})

-- Shooting stars at night.
event({
	id = "stars",
	actors = 0,
	when = "night",
	weight = function(ctx: Ctx)
		if ctx.weather ~= "clear" or #ctx.present == 0 then
			return 0
		end
		return 0.8
	end,
	scene = function(ctx: Ctx): Scene
		local effects: { any } = {}
		for _, vid in ctx.present do
			table.insert(effects, { t = "moodv", vid = vid, d = 5 })
		end
		return {
			title = "Shooting stars",
			lines = {
				line(nil, "Shooting stars streak over town, and everyone makes a wish."),
				line(nil, "Nobody says what they wished for, and they all stay up far too late."),
			},
			effects = effects,
			log = "Shooting stars lit up the sky.",
		}
	end,
})

-- A storm.
event({
	id = "storm",
	actors = 0,
	when = "any",
	weight = function(ctx: Ctx)
		return if ctx.weather == "storm" then 1.5 else 0
	end,
	scene = function(ctx: Ctx): Scene
		local effects: { any } = {}
		for _, vid in ctx.present do
			if not ctx.v(vid).bed then
				table.insert(effects, { t = "moodv", vid = vid, d = -4 })
			end
		end
		return {
			title = "Thunder",
			lines = { line(nil, "Thunder rolls over town, and everyone runs for a roof.") },
			effects = effects,
			log = "A thunderstorm rolled through.",
		}
	end,
})

-- A customer at someone's workplace.
event({
	id = "shopping",
	actors = 2,
	when = "day",
	weight = function(ctx: Ctx, a: string, b: string)
		if not ctx.job(a) or ctx.quarreling(a, b) then
			return 0
		end
		return 1.4
	end,
	scene = function(ctx: Ctx, a: string, b: string): Scene
		local w = ctx.job(a)
		local place = Kit.workplace(ctx, a)
		local coins = Tuning.Jobs.VisitCoins * ctx.rng:int(2, 5)
		-- at a counter that sells things they pick one out, anywhere else they ask for the service, and
		-- the worker answers them
		local service = SERVICE[w.job.id]
		return {
			title = "A customer",
			lines = join(
				line(nil, ctx.f("{b} stopped by {a}'s {place}.", { place = place })),
				if service
					then burst(ctx, "b", b, service[1], "sparkle")
					else burst(ctx, "b", b, {
						shy = "Um... could I have one of those, please?",
						bold = "One of those, thanks.",
						proud = "I'll have your very best one.",
						cool = "One of those, please.",
						prickly = "That one.|No, the other one, yes.",
						dramatic = "I'll take that one, it's calling to me!",
						bookish = "Which one's the most popular?|...I'll have that, then.",
						gloomy = "Whatever's left is fine.|That one, I suppose.",
						polite = "May I have one of those, please?|Thank you kindly.",
						foodie = "Two of those, no, three.|One's for now and two are for later.",
						nervous = "Is that one okay?|I-is it the right one? Okay, that one.",
						cheeky = "one of those, and a discount|worth a try",
						_ = "I'll take one of those, please.",
					}, "sparkle"),
				if service then line("a", service[2], "music", "wave") else by(ctx, "a", a, SERVED, "music", "wave")
			),
			effects = {
				{ t = "coins", d = coins },
				{ t = "rel", a = "a", b = "b", d = 4 },
				{ t = "xp", who = "a", d = 8 },
			},
			log = ctx.f("{b} shopped at {a}'s {place}.", { place = place }),
		}
	end,
})

-- A great day at work. (Its cutscene counts on two lines: the narrator, then theirs.)
event({
	id = "bigday",
	actors = 1,
	when = "day",
	weight = function(ctx: Ctx, a: string)
		if not ctx.job(a) then
			return 0
		end
		return 0.6 + ctx.v(a).mood / 200
	end,
	scene = function(ctx: Ctx, a: string): Scene
		local w = ctx.job(a)
		local place = Kit.workplace(ctx, a)
		local coins = math.floor(w.job.income * Tuning.Jobs.BusyDayShare)
		return {
			title = "A busy day",
			lines = {
				line(nil, ctx.f("Customers keep queueing up at {a}'s counter.", { place = place })),
				by(ctx, "a", a, {
					easygoing = "So many people, I'm going to need a long sit down after this.",
					shy = "So many people... I'm doing okay, aren't I?",
					proud = "Hmph, of course they're queueing, they know who's behind the counter.",
					sunny = "{player}, look at the queue, look at it!",
					cool = "It's a busy one today.",
					prickly = "Ugh, one at a time, please, and stop pushing.",
					dramatic = "The WHOLE island is here!",
					bookish = "That's sixty customers before noon, sixty one, actually.",
					gloomy = "This busy? Something must be wrong at all the other shops.",
					polite = "Thank you all for your patience, next, please.",
					foodie = "I haven't had a second to eat, not one.",
					nervous = "So many people, am I being quick enough?",
					cheeky = "the queue goes past the fountain, i'm basically famous now",
					gentle = "Oh, my, what a crowd, I hope nobody's waiting too long.",
					_ = "I've never been this busy, and I love it.",
				}, "sparkle", "cheer"),
			},
			effects = { { t = "coins", d = coins }, { t = "mood", who = "a", d = 5 }, { t = "xp", who = "a", d = 15 } },
			log = ctx.f("{a} had a busy day at the {place}.", { place = place }),
		}
	end,
})

-- Asking for the day off.
event({
	id = "dayoff",
	actors = 1,
	when = "day",
	weight = function(ctx: Ctx, a: string)
		if not ctx.job(a) or ctx.hour >= Tuning.Day.WorkEnd then
			return 0
		end
		return 0.3 + trait(ctx, a, "lazy") * 0.7
	end,
	scene = function(ctx: Ctx, a: string): Scene
		return {
			title = "A day off",
			lines = join(
				line("a", ctx.f("{player}, have you got a minute?", {}), "sweat"),
				burst(ctx, "a", a, {
					proud = "I'd like the rest of the day off.|I think I've earned it, don't you?",
					shy = "Um... could I maybe go home early today?|Sorry, you can say no.",
					cool = "I need the afternoon off.|Is that all right?",
					prickly = "I need the rest of the day off.|Don't make it a whole thing.",
					dramatic = "I'm EXHAUSTED.|Please let me go home before I fall over right here.",
					gloomy = "I'm worn out, as usual.|Could I go home? I'd be no use to anyone today.",
					polite = "Would it be all right if I finished early today?",
					foodie = "I can't think straight, so could I take the afternoon off?|I need a nap and a very big lunch.",
					nervous = "Is it okay to ask for the day off?|Is that too much to ask?",
					easygoing = "*yawn*|So, hypothetically, how would you feel about me taking the afternoon off?",
					_ = "Could I take the rest of today off?|I'm worn out.",
				}, "sweat")
			),
			choices = {
				{
					text = "Go and rest.",
					lines = burst(ctx, "a", a, {
						easygoing = "Thanks, the hammock's calling me.",
						prickly = "...Thanks, I'll be back early tomorrow.",
						polite = "Thank you so much.|I'll make it up to you.",
						shy = "...!|Thank you.",
						_ = "Thank you, I'll be back tomorrow.",
					}, "heart", "cheer"),
					effects = { { t = "dayoff", who = "a" }, { t = "mood", who = "a", d = 10 } },
				},
				{
					text = "We need you today.",
					lines = burst(ctx, "a", a, {
						prickly = "Ugh, fine, I'm going.",
						dramatic = "Then I shall work until I DROP.",
						proud = "Hmph, I suppose the place would fall apart without me.",
						_ = "Okay... back to it, then.",
					}, "sad"),
					effects = { { t = "mood", who = "a", d = -6 } },
				},
			},
			default = 1,
			log = ctx.f("{a} asked for a day off."),
		}
	end,
})

-- Wanting a job when there isn't one.
event({
	id = "jobhunt",
	actors = 1,
	when = "day",
	weight = function(ctx: Ctx, a: string)
		if ctx.job(a) then
			return 0
		end
		return 1.1
	end,
	scene = function(ctx: Ctx, a: string): Scene
		return {
			title = "Looking for work",
			lines = join(
				burst(ctx, "a", a, {
					proud = "I'd like a job, ideally a good one.",
					bold = "Give me a job, any job.",
					shy = "Um... is there any work going?|I don't mind what it is.",
					sunny = "{player}, is there anything I could do?|Anything at all!",
					cool = "Have you got any work for me?",
					prickly = "I'm bored.|Find me something to do, please.",
					dramatic = "I need a PURPOSE, {player}!",
					bookish = "Actually, I've been reading about all the jobs in town.|I'd like to try one, any of them.",
					gloomy = "Nobody needs me for anything.|Is there any work?",
					polite = "If there's any work going, I'd be glad of it.",
					foodie = "Is there a job with snacks?|Any job's fine, but snacks would be nice.",
					nervous = "Is there a job for me?|Would I even be any good at it?",
					easygoing = "I suppose I should get a job at some point.|Maybe today, even.",
					_ = "I'd love a job, anything at all.",
				}, "question"),
				line(nil, "Put a workplace down from the Work tab in Build mode and they'll take it.")
			),
			effects = { { t = "mood", who = "a", d = -2 } },
			log = ctx.f("{a} is looking for work."),
		}
	end,
})

-- A tourist likes the town.
event({
	id = "tourist",
	actors = 0,
	when = "day",
	weight = function(ctx: Ctx)
		return 0.5
	end,
	scene = function(ctx: Ctx): Scene
		local city = ctx.city()
		local tip = math.clamp(20 + math.floor(city.value / 300), 20, 400)
		local words = if city.value > 20000
			then "said it's the prettiest town for miles"
			elseif city.value > 6000 then "liked the look of the place"
			else "said it has a lot of potential"
		return {
			title = "A tourist",
			lines = {
				line(nil, ctx.f("A tourist wandered through town and {words}.", { words = words })),
				line(nil, ctx.f("They left a tip of {coins} coins on the way out.", { coins = tip })),
			},
			effects = { { t = "coins", d = tip } },
			log = "A tourist visited and left a tip.",
		}
	end,
})

-- The town inspector rates the gardens.
event({
	id = "inspector",
	actors = 0,
	when = "day",
	weight = function(ctx: Ctx)
		local n = 0
		for _, item in ctx.profile.plan.items do
			local def = Catalog.get(item.id)
			if def and def.cat == "garden" then
				n += 1
			end
		end
		return if n >= 5 then 0.5 else 0
	end,
	scene = function(ctx: Ctx): Scene
		local n = 0
		for _, item in ctx.profile.plan.items do
			local def = Catalog.get(item.id)
			if def and def.cat == "garden" then
				n += 1
			end
		end
		local prize = math.min(250, n * 10)
		return {
			title = "The inspector",
			lines = {
				line(nil, "The town inspector came round with a clipboard."),
				line(
					nil,
					ctx.f(
						"They counted {n} garden pieces and gave the town a prize of {coins} coins.",
						{ n = n, coins = prize }
					)
				),
			},
			effects = { { t = "coins", d = prize } },
			log = "The inspector gave the gardens a prize.",
		}
	end,
})

-- A villager checks in on you (the user: villagers who talk to you by name, like a friend
-- messaging). Built with Kit like the newer events.
event({
	id = "checkin",
	actors = 1,
	when = "day",
	weight = Kit.W({ base = 0.15, traits = { kind = 0.3, social = 0.2 } }),
	scene = function(ctx: Ctx, a: string): Scene
		local s = Kit.scene(ctx, "Checking in")
		s:n("{a} waves you over to the bench by the fountain.")
		for _, l in
			burst(ctx, "a", a, {
				sunny = "{player}, sit, sit!|You've been running round all day.",
				gentle = "{player}, come and sit for a minute.|Have you eaten today, properly, I mean?",
				bold = "{player}, sit down.|You look done in, you know that?",
				dreamy = "There's room on the bench.|Hmm... the sun's nice right here.",
				easygoing = "Sit down, seriously.|The town won't fall over in five minutes.",
				proud = "Even I take breaks, {player}, so sit.",
				shy = "Um, {player}?|Do you want to sit down? Only if you want to.",
				cheeky = "you've been building so much i thought you'd turned into a hammer|sit down, hammer",
				cool = "{player}, sit for a bit.|You've earned it.",
				prickly = "You look tired.|I wasn't watching you or anything, so just sit down.",
				dramatic = "You'll wear yourself out, {player}, so rest!",
				bookish = "{player}, did you know people work better after a short rest?|Sit with me for a minute and we'll test it.",
				gloomy = "You'll burn out like that.|Sit with me for a bit, it's fine.",
				polite = "Hello, {player}.|Would you care to join me for a moment?",
				foodie = "Sit down, I've got half a sandwich.|It's the good half.",
				nervous = "Are you okay?|You look really tired.",
				_ = "Come and sit for a minute, {player}.",
			}, "heart", "wave")
		do
			table.insert(s.lines, l)
		end
		s:choice("Budge up, then.", function(c)
			c:n("You sat on the bench with {a} for a while and watched the pigeons.")
			c:by("a", {
				cool = "...Good, right?",
				prickly = "See, that wasn't so hard... I liked that, actually.",
				gloomy = "That was nice, will you come back tomorrow?",
				gentle = "There, isn't that better? Take care of yourself today.",
				_ = "Feeling a bit better now?",
			}, "heart")
			c:hearts("a", 1)
			c:mood("a", 5)
			c:memo("a", "Remember when we sat by the fountain, {player}? We should do that more.")
		end)
		s:choice("Sorry, I'm too busy.", function(c)
			c:by("a", {
				prickly = "Fine, don't say I didn't warn you.",
				nervous = "Okay, just don't forget to rest, okay?",
				sunny = "Aw, later, then!",
				gentle = "All right, but I'm bringing you soup later.",
				_ = "Okay, don't forget to stop at some point.",
			}, "sad")
			c:mood("a", -1)
		end)
		s:log("{a} asked you to take a break.")
		return s:done()
	end,
})

-- Walking you home by lantern.
event({
	id = "lanternwalk",
	actors = 1,
	when = "night",
	weight = Kit.W({ base = 0.06, traits = { kind = 0.2 } }),
	scene = function(ctx: Ctx, a: string): Scene
		local s = Kit.scene(ctx, "A light home")
		s:prop("item:keep_lantern", "a")
		s:n("It's dark on the path, and then a lantern comes bobbing up behind you with {a} holding it.")
		for _, l in
			burst(ctx, "a", a, {
				sunny = "{player}, it's pitch black out here!|You'll fall in a ditch, so I'm walking you home!",
				gentle = "It's very dark tonight.|Let me light the way for you, all right?",
				bold = "You'll trip in this, so walk with me.",
				dreamy = "The moon's hiding tonight.|Hmm... do you want to share my light?",
				cool = "It's too dark to walk alone, so I'll take you back.",
				prickly = "I was going this way anyway.|Don't read into it.",
				dramatic = "Through the darkness, I bring you light!",
				gloomy = "There's a hole by the gate.|I fell in it once, so walk with me.",
				polite = "Good evening, {player}.|May I walk with you? It's very dark tonight.",
				foodie = "I'm heading to the bakery's back door for yesterday's buns.|It's the same way as you.",
				nervous = "It's so dark out here.|C-can I walk with you? It's for both of us.",
				_ = "It's dark, so I'll walk you back.",
			}, "idea")
		do
			table.insert(s.lines, l)
		end
		s:choice("Thanks, lead the way.", function(c)
			c:n("You walked back under {a}'s lantern without tripping once.")
			c:hearts("a", 1)
			c:mood("a", 4)
		end)
		s:choice("I know the way.", function(c)
			c:by("a", {
				prickly = "Fine, but don't come crying to me with a muddy knee.",
				nervous = "Okay, be careful, really careful.",
				cool = "Okay, night, then.",
				_ = "Okay, good night, {player}, and watch out for the ditch.",
			}, "wave")
			c:mood("a", 1)
		end)
		s:log("{a} walked you home with a lantern.")
		return s:done()
	end,
})

-- Finding the right word for a letter.
local WORDS = { { "Silver", "silver" }, { "Huge", "huge" }, { "Grumpy", "grumpy" } }

event({
	id = "rightword",
	actors = 1,
	when = "any",
	weight = Kit.W({ base = 0.07, traits = { focus = 0.1 } }),
	scene = function(ctx: Ctx, a: string): Scene
		local s = Kit.scene(ctx, "The right word")
		s:n("{a} is writing a letter to a friend on another island, but the pen has stopped.")
		for _, l in
			burst(ctx, "a", a, {
				sunny = "{player}, help!|I want to say the sea looked... ugh, what's the word?",
				dreamy = "{player}...|The sea this morning looked... hmm, how did it look?",
				cool = "{player}, I need a word for how the sea looked this morning.",
				prickly = "{player}, I need one word.|Don't laugh, I'm stuck on how to describe the sea.",
				dramatic = "{player}, how do I describe the sea?|Words FAIL me!",
				bookish = "{player}, could you help me?|I've crossed out six words already, and none of them were right.",
				gloomy = "{player}, I want to say the sea looked like something.|Something that isn't sad, for once.",
				polite = "Forgive me, {player}.|Might you help? I can't think how to describe the sea.",
				foodie = "{player}, the sea looked like... soup.|No, not soup, something else.",
				nervous = "{player}, help me.|What if I pick the wrong word and they think it's weird?",
				_ = "{player}, can you help me?|I want to say the sea looked... what's the word?",
			}, "question", "point")
		do
			table.insert(s.lines, l)
		end
		local words = ctx.rng:shuffle(WORDS)
		for i = 1, 2 do
			local w = words[i]
			s:choice(w[1] .. "?", function(c)
				c:with({ word = w[2], Word = w[1] })
				c:by("a", {
					prickly = "{Word}... yes, fine, that's it, thanks.",
					gloomy = "{Word}... huh, yes, that's right.",
					bookish = "{Word}, oh, that's exactly it, simple is best.",
					cool = "{Word}, yes, that's the one.",
					_ = "{Word}, yes, that's it exactly.",
				}, "idea", "cheer")
				c:mood("a", 4)
				c:memo("a", "I told my friend the sea looked {word}, and they wrote back saying they could picture it.")
			end)
		end
		s:log("{a} asked you for the right word.")
		return s:done()
	end,
})

for _, name in { "Talks", "Solo", "Pairs", "Town", "Work", "Asks" } do
	local module = script:FindFirstChild(name)
	if module then
		for _, def in require(module) :: any do
			event(def)
		end
	end
end

Events.list = list

local byId: { [string]: any } = {}
for _, e in list do
	if byId[e.id] then
		error("event id used twice: " .. e.id)
	end
	byId[e.id] = e
end

function Events.get(id: string): any
	return byId[id]
end

return Events
