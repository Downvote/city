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
--   Moments   big moments: dreams, a race, a cat in the park, a cloud in somebody's shape
--   Needs     a villager asks for what they lack: a bed, work, a roof, a comfier bed, something fun,
--             friends (Sim/Needs), each ending on the same plain line about where to get it
--   Things    what happens because of a piece on the plot: the stove, the fridge, the post, the pond
--   Later     events an earlier answer left waiting (Sim/FollowUps): does the hat suit them, a new leaf
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
	"jogging laps around the garden",
	"doing stretches on the lawn",
	"humming to the plants while watering them",
}

-- "I had the strangest dream last night about ..."
local DREAMS = {
	"a pancake the size of the town square",
	"being chased around the market by a goose that kept saying sorry",
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
	"a used guitar",
}

-- How a food is named in a sentence: "an apple", "a bread roll", but "mushroom soup" and
-- "pancakes" as they are. (Foods has only the bare name, and "I really want bread roll" isn't
-- how anyone talks.)
local function foodPhrase(food: any): string
	return Foods.phrase(food)
end

-- A dish as said after "my" ("my mushroom soup", "my bread rolls"), for what a cook remembers
-- making (Sim/Memory): the ones you make a batch of are said as many.
local MANY = { bread = "bread rolls", skewer = "fish skewers", riceball = "rice balls" }
local function dishWords(food: any): string
	return MANY[food.id] or food.name:lower()
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
	sunny = "Ehehe, see, see, I told you so!|Thanks for backing me up, {player}.",
	proud = "Thank you, finally someone sensible.|Hmph, I knew I was right all along.",
	bold = "Hah, told you, right?",
	prickly = "Tsk, obviously I was right.|...But thanks for saying so.",
	cool = "Thanks, {player}, I knew I had it right.",
	shy = "...!|Thank you for siding with me.",
	gentle = "Oh my, thank you, {player}.|I'm sorry it came to this, though.",
	cheeky = "hehe, the judge has spoken|no take backs",
	dramatic = "JUSTICE, at long last.",
	bookish = "Actually, the facts were on my side all along.|Thank you for seeing it.",
	gloomy = "Oh, I was right?|Heh... that doesn't usually happen.",
	polite = "Thank you kindly, {player}.|I appreciate you hearing us both out.",
	foodie = "Mmm, thank you, I'm going to celebrate with a snack.",
	nervous = "I-I was right?|Oh, okay, thank you.",
	easygoing = "Heh, told you.|Can we stop arguing now, I need a nap.",
	dreamy = "Oh, I was right.|Hmm... that's nice.",
	_ = "Thank you.|See, I said so.",
}

-- What someone says when you take the other side in a quarrel, in their own way.
local SULK = {
	proud = "Fine, but you'll see I was right in the end.",
	shy = "Oh... okay.|S-sorry I made a fuss.",
	gentle = "All right, {player}, if that's how you see it.",
	cheeky = "wow, ok|noted, and remembered",
	dreamy = "Oh.|I'll go and be wrong somewhere else, then.",
	easygoing = "Eh, fine.|I wasn't that bothered anyway.",
	sunny = "Oh, okay, I'm not upset.|...I'm a little bit upset.",
	bold = "Hah, fine, your call.|...Anyway.",
	cool = "Hm. If you say so.",
	prickly = "Whatever.|Ugh, don't talk to me for a bit.",
	dramatic = "*gasp* BETRAYED, and by you of all people, {player}!",
	bookish = "I still think the facts were on my side.|But fine.",
	gloomy = "Yeah, figures.|That's how it usually goes.",
	polite = "I see.|Thank you for listening, at least.",
	foodie = "Fine, I'm going to go and eat a whole pie about it.",
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
		"I'll come over on Thursday with my tools.",
	},
	postie = {
		"I need to send this parcel to the next island, please.",
		"Put it on the scale, and it'll go out on the morning boat.",
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
	proud = "Good choice, naturally, it's the best one I've got.",
	cool = "Here you go, come again.",
	prickly = "Here, and don't drop it on the way out.",
	dramatic = "An EXCELLENT choice, if I may say so!",
	sunny = "Here you go, come back soon.",
	gentle = "Here you are, and take care on your way home.",
	polite = "Here you are, thank you kindly.",
	foodie = "Mmm, good pick, that's the one I'd have gone for.",
	nervous = "Oh, here you go, I hope it's all right.",
	cheeky = "here you go, and come back tomorrow",
	gloomy = "Here you go, I hope it's not squashed.",
	bookish = "Here you go, that one sold twenty three times this week, actually.",
	dreamy = "Hmm... here you go, I put a little ribbon on it ♪",
	easygoing = "Here you go, and no rush with the coins.",
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

-- A quarrel, and you get to step in.
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
								dramatic = "I was a MONSTER, and I'm so sorry.",
								polite = "You are right, {player}.|I apologise for raising my voice.",
								nervous = "S-sorry, I got all worked up.|I'm really sorry.",
								sunny = "Okay, okay, you're right, {player}.|Sorry, {b}, let's get buns together after this.",
								gentle = "Oh my, I'm sorry, {b}.|I shouldn't have raised my voice, okay?",
								dreamy = "Hmm... I don't even remember how it started.|Sorry, {b}.",
								easygoing = "Eh, it's not worth the fuss.|Sorry, {b}, I'm too tired to stay mad anyway.",
								cheeky = "ok fine, sorry {b}|i'll even say it twice, sorry",
								bookish = "Actually, I think we were both half right.|Sorry, {b}, I got carried away.",
								gloomy = "Yeah, I always make things worse.|Sorry, {b}.",
								foodie = "Sorry, {b}, I get grumpy when I'm hungry.|Can we talk about it over lunch?",
								_ = "...Sorry, I got carried away.",
							}, "sweat"),
							burst(ctx, "b", b, {
								gentle = "Oh my, me too, so let's forget it, okay?",
								cheeky = "me too|hug? no? ok, fair",
								proud = "...Hmph, I wasn't much better.",
								gloomy = "Yeah, me too.|It's fine.",
								foodie = "Me too.|Do you want to go and get a bun?",
								sunny = "Me too, so are we friends again?",
								bold = "Hah, me too, so we're even, right?",
								dreamy = "Me too... let's go and watch the boats and forget about it.",
								easygoing = "Eh, me too, so let's just forget it and sit down.",
								shy = "Um... me too.|S-sorry.",
								cool = "Me too. Let's leave it there.",
								prickly = "...Fine, me too.|Don't make it a big thing.",
								dramatic = "*sob* Me too, I hated every MINUTE of that.",
								bookish = "Me too, I said a few things that weren't even true, actually.",
								polite = "I am sorry as well.|Thank you for saying it first.",
								nervous = "M-me too, I was so scared you'd stay angry forever.|Is it okay now?",
								_ = "Me too, let's forget about it.",
							}, "heart")
						)
						else join(
							burst(ctx, "a", a, {
								shy = "...I don't want to talk about it.",
								easygoing = "Nah, not today.",
								cool = "No, not today.",
								prickly = "No, not until they say sorry first.",
								dramatic = "Never, not in a hundred years.",
								sunny = "I want to, I really do, but not until {b} says sorry.",
								gentle = "I'm sorry, {player}, I need a little time first, okay?",
								bold = "Hah, no, they started it, right?",
								dreamy = "Hmm... not yet, I'm still too upset to think.",
								proud = "Hmph, I'm not the one who should apologise.",
								cheeky = "nope, not until they say sorry, and they have to mean it",
								bookish = "Actually, I'd like an apology first, a real one.",
								gloomy = "It won't help, it never does.",
								polite = "I am sorry, {player}, but I would like an apology first.",
								foodie = "Not on an empty stomach, I'm too grumpy.",
								nervous = "What if they're still angry?|I c-can't, not yet.",
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
						else {
							{ t = "rel", a = "a", b = "b", d = -8 },
							{ t = "quarrel", a = "a", b = "b" },
							-- they make it up later, now and then (Sim/FollowUps)
							if ctx.rng:chance(0.5) then { t = "follow", id = "makeup", at = 8 } else nil,
						},
				},
			},
			default = 3,
			log = ctx.f("{a} and {b} fell out over {cause}.", { cause = cause }),
		}
	end,
})

-- A quarreling pair makes up on their own.
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
					cheeky = "peace offering, you can't stay mad with your mouth full",
					sunny = "Hi, hi, I brought you this, because I hate fighting with you!",
					cool = "Here, I'm sorry about the other day.",
					prickly = "Take it, it's an apology, and don't make me say it twice.",
					dramatic = "I bring a gift and my DEEPEST apologies!",
					bookish = "Actually, I thought about it all night, and you had a point.",
					gloomy = "I figured you wouldn't want to see me, but I brought this anyway.",
					polite = "I would like to apologise properly, so please take this.",
					foodie = "I brought you the good one, that's how sorry I am.",
					nervous = "I-I brought you this to say sorry, is that okay?",
					gentle = "Oh my, I brought you this. I'm sorry for how I was, okay?",
					easygoing = "Mm, I brought you this, so can we stop fighting now, it's so tiring.",
					dreamy = "Hmm... I kept thinking about what I said, so I brought you this.",
					_ = "I brought you this, because I was being silly.",
				}, "sweat"),
				by(ctx, "b", b, {
					proud = "...Fine, I was a bit much too.",
					gentle = "Oh, come here, I was being silly too.",
					shy = "...I'm sorry too, thank you.",
					cool = "...Thanks, I'm sorry too.",
					prickly = "...Fine, apology accepted, and I'm sorry too, happy?",
					dramatic = "All is FORGIVEN.",
					gloomy = "...Thanks, I missed you, honestly.",
					foodie = "You brought the good one, so okay, we're fine.",
					cheeky = "apology accepted, and the snack is mine now",
					bold = "Hah, fine, truce, I was out of line too.",
					sunny = "Ehehe, thank you! Let's eat it together right now.",
					dreamy = "Oh... it still smells warm. Thank you, and I'm sorry too.",
					easygoing = "Mm, thanks, I didn't want to stay mad anyway, it's too much work.",
					bookish = "Thank you, and I owe you an apology too, actually.",
					polite = "Thank you, that is very kind. I am sorry as well.",
					nervous = "Oh, thank goodness, I was so scared you hated me. I'm sorry too.",
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
				sunny = "Ehehe, surprise.|I saw it and thought of you straight away.",
				cool = "Here, I thought you might like this.",
				prickly = "Here, it was just lying around.|Don't read into it.",
				dramatic = "A GIFT, for you, because you deserve it!",
				polite = "Hello, {b}.|I saw this and thought you might like it.",
				nervous = "I-I got you this, is that okay?|You don't have to like it.",
				cheeky = "for you, and no, it's not a prank this time",
				gentle = "I saw this and thought of you, so I hope you like it.",
				dreamy = "Hmm... this made me think of you.|I'm not sure why, but it did.",
				easygoing = "Here, I saw this and thought of you, no big deal.",
				proud = "Here, I picked it out myself, so you know it's good.",
				bookish = "I saw this and thought of you, actually.|It took me twenty minutes to choose.",
				gloomy = "I got you this.|You'll probably hate it, but here.",
				foodie = "I got you this.|I almost got you a cake instead, but I'd have eaten it.",
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
					sunny = "Oh, um, thank you.|I'll find a good spot for it.",
					gentle = "Oh my, thank you.|I'll keep it somewhere safe, okay?",
					bold = "Huh, okay.|...Thanks, anyway.",
					dreamy = "Oh... what is it?|Hmm, I'll work it out later.",
					easygoing = "Huh, thanks, I'll put it somewhere and look at it later.",
					shy = "Um... thank you.|(I'll find a place for it.)",
					dramatic = "Oh, it's so... UNIQUE.|Thank you?",
					bookish = "Oh, interesting.|I'll have to look up what it's for.",
					polite = "Oh, how kind of you.|I will find a place for it.",
					foodie = "Oh, I thought it was a snack.|Thanks anyway.",
					nervous = "Oh, um, thank you.|Wait, am I supposed to know what it is?",
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
					sunny = "{b}, {b}, come to {place} with me!|Let's go right now, together.",
					bold = "{b}, you're free, right?|Good, we're going to {place}.",
					shy = "Um, {b}?|If you're not busy, would you come to {place} with me?",
					cool = "{b}, I'm going to {place}.|Do you want to come?",
					foodie = "{b}, have you eaten yet?|Let's go to {place} and get something on the way.",
					dreamy = "{b}... the light at {place} is really pretty today.|Do you want to come and see?",
					gentle = "{b}, would you like to come to {place} with me?|It's such a nice day, but bring a coat, okay?",
					easygoing = "{b}, I'm going to {place} to lie down somewhere nice.|Come with me, no rush.",
					proud = "{b}, I'm going to {place}, and you may come along.|Naturally, I know the best spot.",
					cheeky = "{b}, come to {place} with me|you can carry the snacks, hehe",
					prickly = "{b}, I'm going to {place} anyway.|You can come if you want, or whatever.",
					dramatic = "{b}, I must go to {place} at ONCE, and you're coming with me!",
					bookish = "{b}, did you know {place} is quietest at three o'clock?|Let's go now and see.",
					gloomy = "{b}, I'm going to {place}.|You probably don't want to come, though.",
					polite = "{b}, would you like to come to {place} with me, if it is no trouble?",
					nervous = "{b}, um, would you come to {place} with me?|Is that okay?",
					_ = "Hey, {b}, do you want to go to {place} with me?",
				}, "idea", "point", vars),
				burst(ctx, "b", b, {
					shy = "Me?|Okay, if that's all right.",
					easygoing = "Sure, as long as there's somewhere to sit.",
					cool = "Sure, let's go.",
					prickly = "I've got nothing better to do, so fine.",
					dramatic = "An adventure, yes, I'll pack a bag.",
					bookish = "Oh, I've been meaning to go, actually.|Yes, let's.",
					gloomy = "It'll probably rain on us, but okay, yes.",
					polite = "I would love to, thank you for asking.",
					foodie = "Is there anywhere to eat there?|Then yes, okay, yes.",
					nervous = "Now, right now?|Okay, let me get my coat first.",
					sunny = "Yes, yes, let's go.|Can we, {player}?",
					gentle = "Oh, that sounds lovely.|Is that all right with you, {player}?",
					bold = "Hah, sure, let's go.|You don't mind, right, {player}?",
					dreamy = "Hmm... okay, I'd like that.|Can we, {player}?",
					cheeky = "only if we get snacks on the way|can we, {player}?",
					proud = "I suppose I could spare an afternoon.|You can do without us for one afternoon, can't you, {player}?",
					_ = "Ooh, sure.|Can we, {player}?",
				}, "question")
			),
			choices = {
				{
					text = "Have fun, you two.",
					lines = {
						line(nil, ctx.f("{a} and {b} headed off to {place}.", vars)),
						line(nil, "They came back before dinner, both smiling."),
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
						sunny = "Aw, okay, then let's go tomorrow together.",
						shy = "Oh, of course, sorry.",
						prickly = "Fine, whatever, another day.",
						dramatic = "Our plans, CRUSHED.|...Okay, another day.",
						bold = "Your loss.|Another day, then.",
						cool = "Okay, another day.",
						gloomy = "Yeah, I figured.|Another day, then.",
						gentle = "Of course, another day, then.|Take care, okay?",
						dreamy = "Oh... okay.|The clouds will still be there another day.",
						easygoing = "Eh, it's fine, another day, I'll just nap instead.",
						proud = "Hmph, your loss, we'd have had a lovely time.",
						cheeky = "boo|fine, another day, but you owe us",
						bookish = "That's fair.|It's meant to be sunnier on Thursday anyway.",
						polite = "Of course, perhaps another day, then.",
						foodie = "Aw, okay.|I'll pack the snacks for next time, then.",
						nervous = "Oh, okay, was it a bad idea?|S-sorry, another day.",
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
					sunny = "Ehehe, got you, got you.",
					gentle = "Oh my, I'm sorry, I couldn't help it.",
					bold = "Hah, got you good, right?",
					dreamy = "Hee... I thought it would be funny.|Was it funny?",
					easygoing = "Heh, got you, and it only took me all morning to set up.",
					proud = "Hmph, a perfect prank, if I do say so myself.",
					shy = "Um... surprise?|S-sorry.",
					prickly = "Tsk, you should have seen your face.",
					bookish = "Actually, I planned that for three days.",
					gloomy = "Heh... I got you.|You'll get me back worse, won't you?",
					polite = "Please forgive me, I could not resist.",
					foodie = "Ha, got you, and I didn't even waste any cake on it.",
					nervous = "Oh no, was that too much?|I'm sorry, I'm sorry.",
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
						dramatic = "*gasp* How could you do this to ME?",
						bookish = "I'm writing that down for later, you know.",
						gloomy = "Yeah, that's my luck.",
						polite = "I would rather you did not do that again, please.",
						foodie = "You made me drop my snack, you know.",
						nervous = "My heart!|It's still going so fast.",
						sunny = "Hey, that wasn't funny at all.",
						easygoing = "Eh, not funny, I was half asleep.",
						cheeky = "ok, rude, i'll remember this",
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
							sunny = "Okay, okay, sorry, sorry.|I'll make it up to you with a bun, {b}.",
							gentle = "You're right, that wasn't kind of me.|I'm sorry, {b}, okay?",
							bold = "Hah, fine, I went too far.|Sorry, {b}.",
							dreamy = "Oh... I didn't think it through.|Sorry, {b}.",
							easygoing = "Eh, fair enough, I'll stop, it was a lot of work anyway.",
							shy = "S-sorry, {b}.|I won't do it again.",
							cool = "Fair enough.|Sorry, {b}.",
							prickly = "Ugh, fine, sorry.|It was a little funny, though.",
							dramatic = "I have been JUDGED, and I accept it.|Sorry, {b}.",
							bookish = "Fair point, I'll write that down as a bad idea.|Sorry, {b}.",
							gloomy = "Yeah, I knew I'd get in trouble.|Sorry, {b}.",
							polite = "You are right, and I apologise, {b}.",
							foodie = "Sorry, {b}, I'll buy you a snack to make up for it.",
							nervous = "Oh no, you're right, I'm so sorry, {b}.|Are you okay?",
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
					sunny = "{b}, I love your {thing}.",
					gentle = "{b}, has anyone told you your {thing} is lovely?",
					bookish = "{b}, I've been meaning to say that I really admire your {thing}.",
					polite = "Excuse me, {b}, I only wanted to say your {thing} is lovely.",
					bold = "{b}, your {thing} is great, and I'm not just saying that.",
					dreamy = "{b}... I was just thinking how nice your {thing} is.|Hmm, that's all.",
					easygoing = "Hey, {b}, I like your {thing}, just thought you should know.",
					proud = "{b}, your {thing} is nearly as good as mine.|That's a compliment, by the way.",
					prickly = "{b}, your {thing} is... fine.|Okay, it's really nice, don't make it weird.",
					dramatic = "{b}, your {thing} is simply STUNNING!",
					gloomy = "{b}, I like your {thing}.|Mine's never that good.",
					foodie = "{b}, I like your {thing} more than warm bread, and that's saying a lot.",
					nervous = "{b}, um, I like your {thing}.|Is that a weird thing to say?",
					_ = "{b}, I really like your {thing}.",
				}, "sparkle", nil, vars),
				if proud
					then burst(ctx, "b", b, "Naturally, but thank you for noticing.", "sparkle")
					else burst(ctx, "b", b, {
						sunny = "Really? Ehehe, thank you.",
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
						polite = "Why, thank you, that is very kind of you to say.",
						foodie = "Thanks, that's nicer than a warm bun.",
						nervous = "R-really? Oh, thank you!",
						proud = "Hmph, naturally.",
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
					sunny = "{b}, {b}, arm wrestle me.|Loser does the dishes, okay?",
					gentle = "{b}, would you like to arm wrestle?|Loser does the dishes, but I'll go easy, okay?",
					dreamy = "Hmm... {b}, want to arm wrestle?|I've never tried it before.",
					easygoing = "{b}, arm wrestle?|Loser does the dishes, and I really don't want to do the dishes.",
					shy = "Um, {b}?|Would you arm wrestle me, if you want to?",
					cool = "{b}, arm wrestle.|Loser does the dishes.",
					prickly = "{b}, arm wrestle me.|Loser does the dishes, and that won't be me.",
					dramatic = "{b}, I challenge you to a duel of STRENGTH!|Loser does the dishes.",
					bookish = "{b}, did you know arm wrestling is mostly in the wrist?|Let's test it, and the loser does the dishes.",
					gloomy = "{b}, arm wrestle?|I'll lose, but the dishes need doing anyway.",
					polite = "{b}, would you like an arm wrestle?|The loser does the dishes, if that is fair.",
					foodie = "{b}, arm wrestle me for the last cookie?|Loser does the dishes too.",
					nervous = "{b}, do you want to arm wrestle?|Not too hard, though, is that okay?",
					_ = "{b}, do you want to arm wrestle?|Loser does the dishes.",
				}, "idea", "point"),
				burst(ctx, "b", b, {
					shy = "Um... okay?",
					easygoing = "Do I have to?|Mm, fine, just one go.",
					cool = "Sure, let's go.",
					prickly = "Fine, but you'll regret it.",
					dramatic = "I accept your challenge.",
					nervous = "N-now?|Okay, but please don't pull too hard.",
					sunny = "Yes, yes, let's do it.",
					gentle = "Oh my, all right, but be careful, okay?",
					bold = "Hah, you're on.",
					dreamy = "Hmm... okay, but my arm's still a bit sleepy.",
					proud = "Hmph, you'll lose, naturally.",
					cheeky = "you're going to lose, just saying",
					bookish = "Fine, but I read it's all in the wrist, so watch out.",
					gloomy = "Sure, I'll lose, but sure.",
					polite = "Certainly, thank you for asking.",
					foodie = "Okay, but I've only had one breakfast today.",
					_ = "You're on.",
				}, "sparkle"),
				line(nil, "After a lot of grunting, one of them finally wins."),
				burst(ctx, winner, if aWins then a else b, {
					proud = "As expected.|Enjoy the dishes.",
					shy = "Oh, I won?|Sorry about the dishes...",
					cool = "The dishes are yours.",
					dramatic = "VICTORY is mine, and so is the last cookie.",
					nervous = "I-I won?|Sorry, the dishes are yours.",
					gentle = "Oh, my, I won.|I'll help you dry, if you like.",
					sunny = "I won, I won.|Have fun with the dishes.",
					cheeky = "hehe, enjoy the dishes",
					polite = "Oh, I won.|I am very sorry about the dishes.",
					gloomy = "I won? Huh.|That never happens.",
					bold = "Hah, told you, right?|Enjoy the dishes.",
					dreamy = "Oh... I won?|La la ♪, the dishes are yours.",
					easygoing = "Huh, I won, and I didn't even try that hard.",
					prickly = "Tsk, obviously.|Don't forget the pots.",
					bookish = "That took eleven seconds, actually.|The dishes are yours.",
					foodie = "I won, and that means more time for dessert.",
					_ = "Hah, the dishes are all yours.",
				}, "sparkle", "cheer"),
				burst(ctx, loser, if aWins then b else a, {
					proud = "Th-that's because I let you win, obviously.",
					easygoing = "Eh, I like doing dishes anyway.",
					bold = "Again, right now.",
					prickly = "My elbow slipped, so that doesn't count.",
					gloomy = "I knew that would happen.",
					sunny = "Aw, you're so strong!|Let's go again tomorrow.",
					gentle = "Oh my, you're strong.|I'll get the dishes, then.",
					dreamy = "Hmm... I was thinking about something else.|Where was I?",
					shy = "Oh... you won.|I'll do the dishes.",
					cheeky = "ok but you cheated, jk, i'll do the dishes",
					cool = "Hm, good match.",
					dramatic = "DEFEATED! *sob*|The dishes are waiting for me.",
					bookish = "I lost by about two seconds, actually.",
					polite = "Well done, I will start on the dishes.",
					foodie = "I need a snack before I do all those dishes.",
					nervous = "Oh no, all those dishes.|What if I break one?",
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
						sunny = "This smells so, so good.|Let's eat it on the porch together.",
						gentle = "Oh my, this smells lovely.|Let it cool a little first, okay?",
						bold = "Hah, this is going to be great, right?",
						dreamy = "Hmm... look at the steam curling up.|La la ♪",
						easygoing = "Mm, smells good, wake me up when it's done.",
						proud = "It's coming along beautifully, thanks to me.",
						shy = "Um... I think it's turning out okay.",
						cheeky = "i get the first spoon, chef's rules",
						dramatic = "This could be our MASTERPIECE!",
						bookish = "Actually, it needs four more minutes.|I'm timing it.",
						gloomy = "It actually smells okay.|That never happens.",
						polite = "This smells wonderful, thank you for cooking with me.",
						nervous = "Is it done?|What if it's still cold in the middle?",
						_ = "This is going to be so good.",
					}, "heart")
			),
			-- they eat what they make: a good one cheers them both up, and the one who led keeps
			-- making it for a few days (Sim/Memory)
			effects = if burnt
				then { { t = "rel", a = "a", b = "b", d = 5 } }
				else {
					{ t = "rel", a = "a", b = "b", d = 6 },
					{ t = "mood", who = "a", d = 4 },
					{ t = "mood", who = "b", d = 4 },
					{ t = "remember", who = "a", kind = "dish", what = dishWords(food) },
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
					sunny = "Hey, hey, can I tell you a secret?|You have to promise not to laugh.",
					gentle = "Can I tell you something, {b}?|Just between us, okay?",
					bold = "I'm going to tell you something, and you're not going to laugh, right?",
					dreamy = "Hmm... can I tell you something I've never told anyone?",
					easygoing = "Can I tell you something?|It's kind of silly, so no laughing.",
					proud = "I'm only telling you this because I trust you.|Don't laugh.",
					cheeky = "ok, secret time|no laughing, i mean it, for once",
					dramatic = "{b}, I have a SECRET.|Swear you won't laugh.",
					bookish = "Can I tell you something?|I've been thinking about it for about three weeks.",
					gloomy = "Can I tell you something?|You'll probably laugh, everyone does.",
					polite = "May I tell you something, just between us?|Please do not laugh.",
					foodie = "Can I tell you something?|Pass me the cookies first, I need them for this.",
					nervous = "C-can I tell you something?|What if you think it's silly?",
					_ = "Can I tell you something?|You can't laugh, though.",
				}, "sweat"),
				burst(ctx, "b", b, {
					cheeky = "i promise|...i'll try, anyway",
					cool = "I promise.",
					prickly = "Just say it.|I won't laugh, much.",
					nervous = "I promise, is it something bad?|You can tell me.",
					sunny = "I promise, I promise.|Tell me, tell me.",
					gentle = "I promise.|Take your time, okay?",
					bold = "I won't laugh, I promise.|Go on.",
					dreamy = "Hmm... I promise.|Is it a nice secret?",
					easygoing = "I promise, I'm too sleepy to laugh anyway.",
					proud = "Hmph, of course I won't laugh.",
					shy = "Um... I promise.|I'm listening.",
					dramatic = "I swear on my LIFE.|Tell me.",
					bookish = "I promise.|I'm very good at keeping secrets, actually.",
					gloomy = "I promise.|Nobody tells me anything anyway.",
					polite = "I promise, you can trust me.",
					foodie = "I promise.|Here, have a cookie first.",
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
					sunny = "{b}, race you to the fence.|Three, two, one, go.",
					gentle = "{b}, do you want to race to the fence?|Careful not to trip, okay?",
					bold = "{b}, race you to the fence, and the loser buys lunch.",
					dreamy = "{b}... race you to that fence.|The one with the bird sitting on it.",
					easygoing = "{b}, race you to the fence, but no running too fast.",
					proud = "{b}, race you to the fence.|I'll even give you a head start.",
					shy = "Um, {b}?|Do you want to race to the fence?",
					cool = "Race to the fence, {b}, on three.",
					prickly = "{b}, race you to the fence, unless you're scared.",
					dramatic = "{b}, a RACE, to the fence, right now.",
					bookish = "{b}, it's forty steps to the fence, I counted.|Race you?",
					gloomy = "{b}, race you to the fence?|I'll lose, but okay.",
					polite = "{b}, would you race me to the fence, please?",
					foodie = "{b}, race you to the fence, and the loser buys snacks.",
					nervous = "{b}, race you to the fence?|Wait, I'm not ready, okay, go.",
					_ = "Race you to the fence, {b}.",
				}, "idea", "point"),
				line(nil, "And they're off."),
				burst(ctx, winner, if aWins then a else b, {
					proud = "Hmph, as expected.",
					shy = "Oh... I won?",
					bold = "Hah, first!",
					cool = "I win.",
					dramatic = "The crowd goes WILD.",
					nervous = "I won?|I-I actually won!",
					sunny = "I won, I won.|Let's go again.",
					gentle = "Oh my, I won.|Are you all right?",
					dreamy = "Oh... I won?|I was watching a bird the whole way.",
					easygoing = "Huh, I won, and now I need a nap.",
					cheeky = "hehe, too slow",
					prickly = "Tsk, that was too easy.",
					bookish = "Eight seconds flat, actually.",
					gloomy = "I won? Huh.|That was nice, strangely.",
					polite = "Oh, I won.|Thank you for the race.",
					foodie = "I won, so you're buying the snacks.",
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
						sunny = "Aw, you're so fast.|Rematch tomorrow, let's do it.",
						gentle = "Oh my, you're quick.|Well done, really.",
						bold = "Hah, next time, right?",
						proud = "Th-that was on purpose, I let you win.",
						cheeky = "ok you're fast, but i'll be faster tomorrow",
						dramatic = "DEFEATED, and in front of everyone.",
						bookish = "I lost by half a second, actually.",
						polite = "Well run, and congratulations.",
						nervous = "Oh no, was I too slow?|Sorry, that was fun, though.",
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
					sunny = "Ehehe, listen, listen, I heard a good one.",
					gentle = "Oh, I heard a funny one today.|Do you want to hear it?",
					bold = "Okay, I've got one, and you're going to laugh, right?",
					dreamy = "Hmm... I just remembered a joke.",
					easygoing = "Heh, okay, here's one I heard.",
					proud = "Here's a joke, and I tell it very well.",
					cool = "I heard a joke.",
					prickly = "Fine, here's a joke, and you'd better laugh.",
					dramatic = "Get ready for the FUNNIEST joke ever.",
					bookish = "Okay, I read this one in a book.",
					gloomy = "Here's a joke.|Nobody ever laughs at mine, though.",
					polite = "May I tell you a joke?",
					foodie = "Mmm, okay, I heard a good one at lunch.",
					nervous = "Um, I heard a joke.|What if it's not funny?",
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
						polite = "Oh, ha ha, that is a good one.",
						sunny = "Ehehe, that's so good!|Tell me another one.",
						gentle = "Oh my, that's a good one.",
						bold = "Hah, okay, that's good.",
						easygoing = "Heh, that's a good one, I'll tell it later.",
						proud = "Hmph, not bad, I'll allow it.",
						shy = "Hee... that was funny.",
						prickly = "Ugh, fine, that was funny.",
						bookish = "Ha, that's clever, actually.",
						foodie = "Ha, that's a good one, I nearly choked on my cookie.",
						nervous = "Ha, oh, that's good.|Is it okay if I tell it to other people?",
						_ = "Hahaha, okay, that's a good one.",
					}, "music", "laugh")
					else burst(ctx, "b", b, {
						proud = "That was beneath both of us.",
						gentle = "Oh my... ha.",
						shy = "Um... heehee?",
						bold = "Boo, that was terrible.",
						cool = "No.",
						prickly = "I'm going to pretend you didn't say that.",
						bookish = "I've heard that one before.|It's in a joke book older than both of us.",
						polite = "Ah, very good.|I will have to remember that one.",
						sunny = "Ehehe... no, that was awful.",
						dreamy = "Hmm... I don't get it.|Wait, oh, okay.",
						easygoing = "Heh, that's so bad it's almost good.",
						cheeky = "boo, get off the stage",
						dramatic = "*groan* That was TERRIBLE.",
						gloomy = "Heh... I've heard worse.|Not much worse.",
						foodie = "That joke was as stale as old bread.",
						nervous = "Um, ha ha?|Was I supposed to laugh?",
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
					dramatic = "{player}, my {thing} is gone forever.|I've turned the whole house upside down.",
					nervous = "Oh no, oh no, has anyone seen my {thing}?|I've looked everywhere twice.",
					prickly = "Has anyone seen my {thing}?|Don't ask if I've looked, I've looked.",
					cool = "{player}, I've lost my {thing}.",
					sunny = "{player}, have you seen my {thing}?|It was right here a minute ago.",
					gentle = "Oh my, has anyone seen my {thing}?|It must be here somewhere.",
					bold = "Has anyone seen my {thing}?|It was right here, right?",
					dreamy = "Hmm... I put my {thing} down somewhere.|Where was I when I did that?",
					easygoing = "Has anyone seen my {thing}?|Eh, it'll turn up, but I'd like it back.",
					proud = "Hmph, someone has moved my {thing}.|I never lose things.",
					shy = "Um... has anyone seen my {thing}?|Sorry to bother you.",
					cheeky = "ok who took my {thing}|no really, where is it",
					bookish = "Has anyone seen my {thing}?|I had it at a quarter past three, I'm sure of it.",
					gloomy = "My {thing} is gone.|Of course it is.",
					polite = "Excuse me, has anyone seen my {thing}, please?",
					foodie = "Has anyone seen my {thing}?|I had it at lunch, I know that much.",
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
									dramatic = "Found, FOUND.|Thank you both, I owe you everything.",
									sunny = "Found it, found it.|Thank you both so much.",
									gentle = "Oh, thank goodness.|Thank you both, I'll make you some tea.",
									bold = "Hah, there it is.|Thanks, both of you.",
									dreamy = "Oh... under a flowerpot.|I wonder how it got there.",
									easygoing = "Ah, there it is.|Thanks, both of you, I'd still be looking.",
									proud = "Hmph, I knew it was somewhere sensible.|...Thank you both.",
									shy = "Oh... there it is.|Thank you both so much.",
									cheeky = "under a flowerpot, wow|thanks, both of you, i owe you one",
									bookish = "Under a flowerpot, of course.|Thank you both, I'd never have looked there.",
									gloomy = "Huh, it was there all along.|Thanks, both of you.",
									polite = "Thank you both, very kindly.|I am so relieved.",
									foodie = "Thank you both.|Let me buy you a snack.",
									nervous = "Oh, thank goodness, I thought it was gone forever.|Thank you both.",
									_ = "Thank you both.|I owe you one, {player}.",
								}
								else {
									prickly = "...Under a flowerpot.|Don't say anything, but thanks.",
									cool = "There it is.|...Thanks, {player}.",
									dramatic = "Found, FOUND.|Thank you, {player}, I owe you everything.",
									sunny = "Found it, found it.|Thank you so much, {player}.",
									gentle = "Oh, thank goodness.|Thank you, {player}, I'll make you some tea.",
									bold = "Hah, there it is.|Thanks, {player}.",
									dreamy = "Oh... under a flowerpot.|Thank you, {player}.",
									easygoing = "Ah, there it is.|Thanks, {player}, I'd still be looking.",
									proud = "Hmph, I knew it was somewhere sensible.|...Thank you, {player}.",
									shy = "Oh... there it is.|Thank you, {player}.",
									cheeky = "under a flowerpot, wow|thanks, {player}, i owe you one",
									bookish = "Under a flowerpot, of course.|Thank you, {player}, I'd never have looked there.",
									gloomy = "Huh, it was there all along.|Thanks, {player}.",
									polite = "Thank you very kindly, {player}.|I am so relieved.",
									foodie = "Thank you, {player}.|Let me buy you a snack.",
									nervous = "Oh, thank goodness, I thought it was gone forever.|Thank you, {player}.",
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
					sunny = "Want me to show you how to {skill}?|It's so fun, let's do it together.",
					gentle = "Would you like me to show you how to {skill}?|We'll go slowly, okay?",
					bold = "I'm showing you how to {skill}, right now.",
					dreamy = "Hmm... do you want to learn how to {skill}?",
					easygoing = "Want to learn how to {skill}?|No rush, we've got all afternoon.",
					shy = "Um... I could show you how to {skill}.|Only if you want to.",
					cool = "I'll show you how to {skill}.",
					prickly = "Ugh, watching you is painful.|Let me show you how to {skill}.",
					dramatic = "Watch closely, because I'm going to teach you to {skill}.",
					bookish = "Did you know anyone can learn to {skill} in ten minutes?|I'll show you.",
					gloomy = "I could show you how to {skill}.|It's the one thing I'm good at.",
					polite = "May I show you how to {skill}?",
					foodie = "I'll show you how to {skill}, and then we're getting lunch.",
					nervous = "D-do you want me to show you how to {skill}?|I might not explain it well.",
					_ = "Do you want me to show you how to {skill}?",
				}, "idea", nil, vars),
				burst(ctx, "b", b, {
					cool = "Sure, show me.",
					prickly = "...Fine, go on, then.",
					polite = "Yes, please, thank you.",
					nervous = "What if I can't do it?|...Okay, yes, please.",
					proud = "Hmph, fine, show me.",
					sunny = "Yes, yes, show me.",
					gentle = "Oh, I'd like that, thank you.",
					bold = "Hah, sure, show me.",
					dreamy = "Hmm... okay, show me.",
					easygoing = "Sure, as long as I can sit down for it.",
					shy = "Um... okay, yes please.",
					cheeky = "ok, but if i'm better than you, no sulking",
					dramatic = "Teach me EVERYTHING.",
					bookish = "Yes, please, I've read about it but never tried.",
					gloomy = "Sure, I'll probably be bad at it.",
					foodie = "Sure, but can I finish my snack first?",
					_ = "Yes, please.",
				}, "sparkle"),
				line(nil, ctx.f("After a few tries, {b} gets the hang of it.")),
				burst(ctx, "b", b, {
					shy = "I did it...|I actually did it.",
					proud = "There, I knew I'd get it.",
					cool = "Got it, thanks.",
					prickly = "That was easy.|...Thanks, though.",
					dramatic = "I have learned, and I'm a changed person.",
					bookish = "Oh, it's all in the timing.|That makes sense now.",
					gloomy = "Huh, I can do it.|I really didn't think I could.",
					polite = "Thank you so much for showing me.",
					nervous = "Did I do it right?|I did it, I really did it!",
					sunny = "I did it, I did it.|Let's show everyone.",
					gentle = "Oh my, I did it.|Thank you for being so patient.",
					bold = "Hah, got it, and on the second try.",
					dreamy = "Oh... I did it.|It felt a little like flying.",
					easygoing = "Huh, that was easier than I thought.",
					cheeky = "look, i'm better than you already, jk",
					foodie = "I did it, and now I'm starving.",
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
					dramatic = "FORGOTTEN, cast aside like an old shoe.",
					gloomy = "Nobody ever asks me, as usual.|It's fine, I'm used to it.",
					polite = "I do not want to intrude.|They seem to be having such fun.",
					nervous = "Did I do something?|Did I say something wrong?",
					gentle = "Oh, they're having such fun.|I'd like to join them, but I don't want to be a bother.",
					dreamy = "Hmm... I wonder what they're laughing about.|Nobody tells me things.",
					easygoing = "Eh, it's fine, they didn't ask me, it's fine.",
					cheeky = "wow, nobody invited me|rude, honestly",
					bookish = "That's the third time this week they've gone without me.",
					foodie = "They went for lunch without me.|I'd have brought snacks, too.",
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
							sunny = "Really, really?|Yes, let's go.",
							gentle = "Oh, thank you.|I'd love to.",
							bold = "Hah, about time.|...Thanks.",
							dreamy = "Oh... me?|Okay, I'd like that.",
							easygoing = "Sure, I'll come, thanks.",
							proud = "Hmph, I suppose I could join you.",
							cheeky = "finally, took you long enough",
							cool = "Okay, thanks.",
							dramatic = "You want ME? Oh, yes, yes!",
							bookish = "Oh, thank you.|What are you laughing about?",
							polite = "Thank you, I would like that very much.",
							foodie = "Okay, is there food?",
							nervous = "R-really?|Are you sure that's okay?",
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
						sunny = "Really? Yes, let's go.|We can get buns on the way.",
						gentle = "Oh, {player}, thank you.|That's very kind of you.",
						bold = "Hah, okay, let's go, and I'll pick the spot.",
						dreamy = "Oh... that's nice.|Let's go and watch the clouds.",
						easygoing = "Sure, let's find somewhere nice to sit.",
						proud = "Hmph, I suppose you'll do.|...Thank you, {player}.",
						cheeky = "ok, but you're buying the snacks",
						dramatic = "{player}, you've SAVED my afternoon.",
						bookish = "Thank you, {player}.|I know a quiet spot by the library.",
						polite = "Thank you, {player}, that is very kind.",
						foodie = "Thanks, {player}.|Let's get something to eat.",
						nervous = "R-really?|You're not just being nice?",
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
					sunny = "I really, really want {food} right now.|Can we go and get it together?",
					bold = "I need {food}, and I need it now.",
					shy = "Um... I really want {food}.|Sorry, I know it's silly.",
					cool = "I could really go for {food} right now.",
					prickly = "I want {food}, so don't laugh.",
					dramatic = "If I don't have {food} today, I'll simply FADE away!",
					polite = "May I ask for {food}, if it is no trouble?|I have been thinking about it all day.",
					foodie = "I've been thinking about {food} since breakfast.|Actually, since yesterday's breakfast.",
					nervous = "Is it okay that I really want {food}?|I-I can't stop thinking about it.",
					easygoing = "Mm, you know what would be nice right now?|{Food}, just saying.",
					cheeky = "you know what i want? {food}|i'll keep saying it until it happens",
					gentle = "Oh, my, I've been dreaming about {food} all afternoon.",
					bookish = "Actually, I read a recipe this morning, and now all I want is {food}.",
					dreamy = "Hmm... I keep thinking about {food}.|It's all I can think about today.",
					proud = "{player}, I've decided I'd like {food} today.|Only the best, naturally.",
					gloomy = "I really want {food}.|I won't get it, though.",
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
							sunny = "{Food}, my favourite, ehehe!|Thank you, thank you, {player}.",
							gentle = "Oh my, {food}, my favourite.|Thank you, {player}.",
							bold = "Hah, you got my favourite.|Thanks, {player}, I owe you one.",
							dreamy = "{Food}... my favourite.|Thank you, {player}.",
							easygoing = "Mm, {food}, my favourite.|Thanks, {player}, you're the best.",
							cheeky = "{food}, my favourite, you know me too well|thanks {player}",
							dramatic = "{Food}, my FAVOURITE!|{player}, you're a hero.",
							bookish = "{Food}, my favourite, how did you know?|Thank you, {player}.",
							foodie = "Mmm, {food}, my absolute favourite.|Thank you, {player}, I'm going to enjoy every bite.",
							nervous = "{Food}, my favourite?|Oh, thank you, {player}, is that really okay?",
							_ = "{Food}, my favourite!|You're the best, {player}.",
						}, "heart", "cheer", vars)
						else burst(ctx, "a", a, {
							prickly = "...Thanks, you didn't have to.",
							cool = "Thanks, I owe you.",
							polite = "Thank you so much, that is very kind.",
							shy = "...!|Thank you.",
							sunny = "Yay, thank you, {player}.",
							gentle = "Oh, thank you, {player}, that's very sweet.",
							bold = "Hah, thanks, I owe you one.",
							dreamy = "Oh... thank you, {player}.",
							easygoing = "Mm, thanks, {player}, that hit the spot.",
							proud = "Hmph, thank you, {player}, you have good taste.",
							cheeky = "thanks, {player}, you're alright",
							dramatic = "{player}, you've SAVED me!",
							bookish = "Thank you, {player}, that was exactly what I needed.",
							gloomy = "Thanks, {player}.|That was nice, strangely.",
							foodie = "Mmm, thank you, {player}, that was so good.",
							nervous = "Oh, thank you, {player}, are you sure that's okay?",
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
						dramatic = "Then I will suffer, quietly, all afternoon.",
						gloomy = "Yeah, I figured.",
						foodie = "Okay... my stomach's going to be so sad, though.",
						sunny = "Aw, later, then.",
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
				polite = "Excuse me, {player}, I hope this is not rude.|May I ask for {cost} coins?|I have had my eye on {thing}.",
				sunny = "{player}, guess what I saw at the market.|It's {thing}, and it's only {cost} coins.|Could you help me get it?",
				gentle = "{player}, can I ask a small favour?|Could I have {cost} coins for {thing}, if that's all right?",
				bold = "{player}, I need {cost} coins.|It's for {thing}, and I'll put it to good use, right?",
				dreamy = "Hmm... {player}, I keep thinking about {thing}.|Could I have {cost} coins for it?",
				easygoing = "{player}, no rush, but could I have {cost} coins sometime?|I've had my eye on {thing}.",
				prickly = "{player}, I need {cost} coins for {thing}.|Don't ask why, I just want it.",
				dramatic = "{player}, I NEED {thing}, and it's only {cost} coins!",
				bookish = "{player}, I've had my eye on {thing} for nine days now.|Could I have {cost} coins?",
				gloomy = "{player}, you'll probably say no.|Could I have {cost} coins for {thing}?",
				foodie = "{player}, could I have {cost} coins?|It's for {thing}, and I'll skip a snack to make up for it.",
				_ = "{player}, can I ask you something?|Could I have {cost} coins?|I've had my eye on {thing}.",
			}, "question", nil, vars),
			choices = {
				{
					text = ctx.f("Here you go ({cost} coins)", vars),
					cost = cost,
					lines = burst(ctx, "a", a, {
						sunny = "Really? Thank you, thank you.",
						cool = "Thanks, really.",
						prickly = "...Thanks, I'll pay you back somehow.",
						polite = "Thank you, I am very grateful.",
						shy = "...!|Thank you.",
						gentle = "Oh, thank you, {player}.|I'll take good care of it.",
						bold = "Hah, thanks, I owe you one.",
						dreamy = "Oh... thank you.|I'm going to go and look at it right now.",
						easygoing = "Thanks, {player}, I'll get it later, no rush.",
						proud = "Thank you, {player}, you won't regret it.",
						cheeky = "yes, thanks {player}, you're the best, jk, you really are",
						dramatic = "{player}, you're my HERO.",
						bookish = "Thank you, I've already planned how I'll use it.",
						gloomy = "Really?|Heh... thanks, that was nice.",
						foodie = "Thank you, {player}, I'll buy you a snack with the change.",
						nervous = "Really? Are you sure?|Th-thank you.",
						_ = "Thank you, I'm going to buy it this afternoon.",
					}, "sparkle", "cheer"),
					effects = { { t = "coins", d = -cost }, { t = "mood", who = "a", d = 12 } },
				},
				{
					text = "Not this time.",
					lines = burst(ctx, "a", a, {
						proud = "Fine, I'll save up.|I'm good at saving.",
						shy = "Oh, of course.|Sorry for asking.",
						sunny = "Aw, later, then.",
						prickly = "Fine, I didn't really need it.",
						gloomy = "Yeah, I figured.",
						cool = "Okay, that's fair.",
						dramatic = "Then I will go without, BRAVELY.",
						nervous = "Okay, s-sorry for asking.",
						gentle = "That's all right, {player}.|It was only a little wish.",
						bold = "Fair enough, I'll earn it myself.",
						dreamy = "Oh... okay.|I'll just think about it, then.",
						easygoing = "Eh, that's fine, it can wait.",
						cheeky = "ok, i'll ask again tomorrow, and the day after",
						bookish = "That's fair, I'll make a budget.",
						polite = "Of course, thank you for listening.",
						foodie = "Okay, I'll save my snack money, then.",
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
					sunny = "{player}, my room is perfect, perfect.|Come and see it later.",
					gentle = "{player}, my room feels just right now.|Thank you for everything, okay?",
					bold = "{player}, my room is great now, and that's thanks to you, right?",
					dreamy = "{player}... the light comes in just right in my room now.|I like it.",
					easygoing = "{player}, my room's perfect for naps now, thanks.",
					proud = "{player}, my room is finally good enough for me.|That's high praise, you know.",
					shy = "Um, {player}... I really like my room.|Thank you.",
					cheeky = "{player}, my room's great|i'm never leaving, hehe",
					dramatic = "{player}, my room is a PALACE now.",
					bookish = "{player}, my room has everything now.|I made a list, and it's all there, actually.",
					gloomy = "{player}, my room is actually really nice.|I keep waiting for something to go wrong.",
					polite = "{player}, thank you, my room is lovely.|I have everything I need.",
					foodie = "{player}, my room is so comfy now.|All it needs is a snack drawer.",
					nervous = "{player}, I really like my room.|Is it okay if I stay in it forever?",
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
					bold = "{player}, I want {thing} by my bed.|You can do that, right?",
					cool = "{player}, could I get {thing} by my bed?",
					prickly = "My room's missing something.|I'd like {thing} by the bed, if you're not busy.",
					polite = "Hello, {player}.|Would it be possible to have {thing} near my bed?",
					nervous = "C-can I ask for something?|Could I have {thing} near my bed?",
					gentle = "{player}, if it's not too much trouble, could I have {thing} near my bed?|Only when you have time, okay?",
					dreamy = "Hmm... {player}, I keep thinking my room needs {thing}.|Near the bed, maybe?",
					easygoing = "{player}, no rush, but {thing} by my bed would be nice.",
					proud = "{player}, my room deserves {thing} by the bed.|Naturally, only a good one.",
					cheeky = "{player}, i need {thing} by my bed|it's for important reasons, hehe",
					dramatic = "{player}, my room is MISSING something.|I need {thing} by my bed.",
					bookish = "{player}, my room needs {thing} near the bed.|Within a few steps, ideally.",
					gloomy = "{player}, could I have {thing} near my bed?|You don't have to, it's fine.",
					foodie = "{player}, could I have {thing} near my bed?|Next to where I keep my snacks.",
					_ = "Hey, {player}, do you think I could have {thing} near my bed?",
				}, "idea", nil, vars),
				line(nil, "Put one within a few steps of their bed in Build mode.")
			),
			effects = { { t = "request", who = "a", tag = tag } },
			log = ctx.f("{a} would like {thing} near their bed.", { thing = Catalog.Tags[tag] }),
		}
	end,
})

-- (No bed and no work: Data/Events/Needs, with the other things a villager asks for.)

-- A dream.
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
					dramatic = "*gasp* It felt so REAL, I woke up gasping!",
					bookish = "Actually, dreams are how the brain sorts through the day, so I must have had a strange one.",
					gloomy = "Heh... I woke up just before it got good, as usual.",
					foodie = "I woke up hungry, which I think is a good sign.",
					nervous = "W-what does it mean, is it something bad?",
					cheeky = "it means i should get the day off, obviously",
					sunny = "It was so much fun, I want to dream it again tonight!",
					gentle = "It was a sweet dream, and I woke up smiling.",
					shy = "Um... is that a strange thing to dream about?",
					polite = "It was a very pleasant dream, I must say.",
					bold = "Hah, weird, right? I'm telling everyone about it.",
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
				sunny = "{player}, {player}, look!|I found {coins} coins in the grass.",
				cool = "{player}, I found {coins} coins in the grass.",
				cheeky = "finders keepers|...fine, {coins} coins for the town",
				gloomy = "I found {coins} coins in the grass.|Somebody's going to miss them, so they'd better go to the town.",
				polite = "Hello, {player}, I found {coins} coins by the path.|I think they should go to the town.",
				foodie = "Mmm, {coins} coins, that's a lot of buns.|But it's for the town, I know.",
				gentle = "Oh my, {player}, I found {coins} coins in the grass.|They should go to the town, don't you think?",
				bold = "{player}, I found {coins} coins.|They're going to the town, right?",
				dreamy = "Hmm... something was shining in the grass.|It was {coins} coins, {player}.",
				easygoing = "{player}, I was lying in the grass and found {coins} coins, lucky me.",
				proud = "{player}, I found {coins} coins.|I have a good eye for these things.",
				shy = "Um, {player}... I found {coins} coins.|Should they go to the town?",
				prickly = "{player}, I found {coins} coins.|Take them before I change my mind.",
				dramatic = "{player}, TREASURE!|{coins} coins, just lying in the grass.",
				bookish = "{player}, I found {coins} coins by the path.|That's the most I've ever found, actually.",
				nervous = "{player}, I found {coins} coins.|What if someone's looking for them?",
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
				sunny = "{player}, I'm fine, really.|Achoo... okay, maybe not completely fine.",
				gentle = "Oh, my, I think I've caught a cold.|Don't come too close, okay?",
				bold = "It's just a cold, I'll be fine by tomorrow, right?",
				dreamy = "Hmm... my head feels all floaty.|I think I caught a cold.",
				proud = "I never get sick.|*sniff* This is clearly a mistake.",
				shy = "Um... I think I caught a cold.|S-sorry, I'll stay over here.",
				cheeky = "i'm not sick|achoo|ok, i'm a little sick",
				bookish = "Actually, a cold lasts about seven days.|So I'll be fine by next week.",
				polite = "Please excuse me, I seem to have caught a cold.",
				foodie = "I can't even taste my soup.|This is the worst.",
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
				line(nil, "A town doctor could help with this, and a clinic desk in Build mode opens the job.")
			)
		end
		table.insert(choices, {
			text = "Go to bed and rest.",
			lines = burst(ctx, "a", a, "Okay... wake me up when I'm better, {player}.", "zzz"),
			effects = {
				{ t = "sick", who = "a", minutes = 5 },
				{ t = "mood", who = "a", d = -2 },
				-- and up and about again later (Sim/FollowUps)
				{ t = "follow", id = "coldbetter", at = 12 },
			},
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
					dramatic = "HOURS, {player}, gone in the blink of an eye.",
					bookish = "I timed it, and it was four hours.|It only felt like one.",
					gloomy = "That was actually fine.|I don't get many afternoons like that.",
					polite = "What a lovely afternoon that was.",
					foodie = "I've worked up a real appetite now.|What's for dinner?",
					nervous = "Was that a waste of a whole day?|It didn't feel like one.",
					sunny = "That was so much fun.|Let's do it together next time.",
					gentle = "That was such a nice afternoon.|Have you had time to rest today too?",
					bold = "Hah, good afternoon, right?|I'm doing it again tomorrow.",
					cheeky = "best afternoon ever, and nobody bothered me, hehe",
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
					sunny = "Mmm... ehehe, one more ride, one more...",
					gentle = "Mmm... have you eaten... you should eat something...",
					bold = "Mmm... leave it to me, I'll get it.",
					dreamy = "La la ♪... the moon's so close tonight...",
					easygoing = "*yawn*... five more minutes... ten more...",
					proud = "Mmm... thank you, thank you, yes, I won...",
					shy = "Um... sorry... sorry, excuse me...",
					cool = "Mm... later.",
					prickly = "Mmm... that's my blanket, give it back...",
					gloomy = "Mmm... it's raining again... as usual...",
					polite = "Mmm... after you, please, no, after you...",
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
					dramatic = "Practice makes perfect, {player}, or nearly perfect.",
					gloomy = "It's still not right, but it's closer.",
					nervous = "Just one more go, then one more.|I-I want to be sure.",
					easygoing = "Okay, that's enough practice for the week.",
					bookish = "Actually, I've been timing myself, and I'm faster every round.",
					sunny = "One more time, and then I've got it!",
					gentle = "Just a little more practice, and then I'll rest, okay?",
					bold = "Hah, I'm getting good at this, right?",
					dreamy = "Hmm... I lost track of time.|Is it dark already?",
					cheeky = "practice is boring, but being good is fun",
					polite = "I would like to do it properly, so I stayed a little longer.",
					foodie = "I skipped dinner to practise.|I'm making up for it with a big breakfast.",
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
				dramatic = "Alone, {player}, in a town FULL of people.",
				gloomy = "Nobody really talks to me.|Heh... I get it.",
				polite = "I do not want to bother anyone.|But it does get a little lonely.",
				nervous = "What if nobody here likes me?|What if it's something I'm doing?",
				gentle = "{player}, everyone seems so busy with their friends.|I don't want to be a bother, but it's a little lonely.",
				dreamy = "Hmm... everyone's talking in little groups.|I just watch the clouds.",
				easygoing = "Eh, I guess I don't really talk to anyone much.|It gets a bit quiet.",
				cheeky = "nobody wants to hang out with me|which is weird, because i'm great",
				bookish = "I counted, and I've talked to two people all week.|That's not many.",
				foodie = "I keep eating lunch on my own.|Food tastes better with someone else.",
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
							sunny = "Hi, hi, {a}.|Let's be friends, starting now.",
							gentle = "Hello, {a}, it's nice to meet you properly.|Come and sit, okay?",
							dreamy = "Oh... hello, {a}.|I've seen you by the fountain before.",
							easygoing = "Hey, {a}, pull up a chair, no rush.",
							proud = "Hello, {a}.|You're lucky, I'm very good company.",
							cool = "Hey, {a}. Sit down if you like.",
							dramatic = "{a}, at LAST we meet.",
							bookish = "Hi, {a}, I've been meaning to say hello for about a week, actually.",
							gloomy = "Hi, {a}.|I'm not very good at this, but hi.",
							polite = "Good afternoon, {a}, it is very nice to meet you.",
							foodie = "Hi, {a}, do you want half of my sandwich?",
							nervous = "H-hi, {a}.|Is it okay if we talk?",
							_ = "Hi, {a}, I've been meaning to say hello.",
						}, "wave"),
						burst(ctx, "a", a, {
							shy = "Oh... hi.",
							prickly = "...Hi.|Hello, I mean.",
							sunny = "Oh, hi!|I'd like that so much.",
							gentle = "Oh, hello.|That's very kind of you.",
							bold = "Hey, hi.|...Thanks.",
							dreamy = "Oh... hello.|That's nice.",
							easygoing = "Oh, hey, sure, sounds good.",
							proud = "Oh, hello.|I suppose I could sit for a while.",
							cheeky = "oh, hi|ok, you seem alright",
							cool = "Hi, thanks.",
							dramatic = "Oh, HELLO!",
							bookish = "Oh, hello.|I've seen you around, actually.",
							gloomy = "Oh, hi.|...That was nice of you.",
							polite = "Oh, hello, it is very nice to meet you.",
							foodie = "Oh, hi.|Is that a sandwich?",
							nervous = "Oh, h-hi.|Hello.",
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
						sunny = "Okay...|Maybe I'll try again tomorrow.",
						nervous = "Okay... is that okay?|Sorry.",
						dramatic = "Yes, leave me ALONE with my sadness!|...Just for today.",
						gentle = "Yes, I think so.|Thank you for asking, {player}.",
						bold = "Yeah, I'll be fine.|...Thanks. Anyway.",
						dreamy = "Hmm... yes, I'll go and sit by the water.",
						easygoing = "Yeah, I'll go and lie down somewhere quiet.",
						cheeky = "yeah, i'll go sulk somewhere nice",
						cool = "Yes, thanks.",
						bookish = "Yes, I'll go and read for a bit.",
						polite = "Yes, please, if that is all right.",
						foodie = "Yeah, I'll go and get a snack on my own.",
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

-- A birthday (the day matches their birthday on the town calendar).
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
				line(nil, "Everyone gathers around with a cake."),
				by(ctx, "a", a, {
					shy = "You all remembered? Oh... thank you.",
					proud = "Of course you remembered, but thank you all the same.",
					bold = "Cake, right, so who's cutting it?",
					easygoing = "Aw, you didn't have to do all this, but is there cake?",
					sunny = "Ehehe, you all remembered, {player} too, so it's the best day ever.",
					cool = "...Thanks, really.",
					prickly = "You didn't have to do all this... but thanks.",
					dramatic = "For ME, all of this? I can't believe it, thank you!",
					bookish = "That's three hundred and sixty five days older, I counted.",
					gloomy = "I thought nobody knew... this is really nice.",
					polite = "Thank you all so much, I am very touched.",
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
						dramatic = "I'll take that one, it's CALLING to me!",
						bookish = "Which one's the most popular?|...I'll have that, then.",
						gloomy = "Whatever's left is fine.|That one, I suppose.",
						polite = "May I have one of those, please?|Thank you kindly.",
						foodie = "Two of those, no, three.|One's for now and two are for later.",
						nervous = "Is that one okay?|I-is it the right one? Okay, that one.",
						cheeky = "one of those, and a discount|worth a try",
						sunny = "Ooh, ooh, that one, please.|It looks so good.",
						gentle = "Could I have one of those, please?|Oh my, they look lovely.",
						dreamy = "Hmm... that one, the one with the pretty colour.",
						easygoing = "Eh, I'll just have whatever you'd pick, no rush.",
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

-- A great day at work.
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
				line(nil, ctx.f("Customers keep lining up at {a}'s counter.", { place = place })),
				by(ctx, "a", a, {
					easygoing = "So many people, I'm going to need a long nap after this.",
					shy = "So many people... I'm doing okay, aren't I?",
					proud = "Hmph, of course they're lining up, they know who's behind the counter.",
					sunny = "{player}, look at the line, look at it.",
					cool = "It's a busy one today.",
					prickly = "Ugh, one at a time, please, and stop pushing.",
					dramatic = "The WHOLE island is here!",
					bookish = "That's sixty customers before noon, sixty one, actually.",
					gloomy = "This busy? Something must be wrong at all the other shops.",
					polite = "Thank you all for your patience, next, please.",
					foodie = "I haven't had a second to eat, not one.",
					nervous = "So many people, am I being quick enough?",
					cheeky = "the line goes past the fountain, i'm basically famous now",
					gentle = "Oh, my, what a crowd, I hope nobody's waiting too long.",
					bold = "Hah, bring them on, I can take all of them.",
					dreamy = "Hmm... so many faces, and somebody's wearing a hat with a feather in it.",
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
					sunny = "{player}, could I take the afternoon off?|I'll be back tomorrow, full of energy.",
					gentle = "Would it be all right if I rested this afternoon?|I'm a little tired, that's all.",
					bold = "I'm taking the afternoon off.|That's fine, right?",
					dreamy = "Hmm... my head's all foggy today.|Could I go home and rest?",
					cheeky = "so i was thinking about taking the afternoon off|and by thinking i mean asking",
					bookish = "I've worked nine days in a row, actually.|Could I take the afternoon off?",
					_ = "Could I take the rest of today off?|I'm worn out.",
				}, "sweat")
			),
			choices = {
				{
					text = "Go and rest.",
					lines = burst(ctx, "a", a, {
						easygoing = "Thanks, the hammock's calling me.",
						prickly = "...Thanks, I'll be back early tomorrow.",
						polite = "Thank you so much.|I will make it up to you.",
						shy = "...!|Thank you.",
						sunny = "Yay, thank you.|I'll be back tomorrow with lots of energy.",
						gentle = "Thank you, {player}.|Make sure you rest too, okay?",
						bold = "Thanks, I'll be back tomorrow, first thing.",
						dreamy = "Thank you... I'm going to lie in the grass and look at the sky.",
						proud = "Thank you, I'll be even better tomorrow.",
						cheeky = "yes, freedom|thanks, {player}",
						cool = "Thanks, I'll be back tomorrow.",
						dramatic = "{player}, you've SAVED my life!",
						bookish = "Thank you, I'll catch up on my reading.",
						gloomy = "Thanks.|That was nice of you, really.",
						foodie = "Thank you, I'm going straight home for a big lunch.",
						nervous = "Really? Are you sure it's okay?|Thank you.",
						_ = "Thank you, I'll be back tomorrow.",
					}, "heart", "cheer"),
					effects = { { t = "dayoff", who = "a" }, { t = "mood", who = "a", d = 10 } },
				},
				{
					text = "We need you today.",
					lines = burst(ctx, "a", a, {
						prickly = "Ugh, fine, I'm going.",
						dramatic = "Then I will work until I DROP.",
						proud = "Hmph, I suppose the place would fall apart without me.",
						sunny = "Okay, okay, back to work, then.",
						gentle = "All right, I'll do my best today.",
						bold = "Fine, I'll push through.",
						dreamy = "Oh... okay.|I'll try to stay awake.",
						easygoing = "Eh, okay, but I'm taking a long nap tonight.",
						shy = "Oh... okay, sorry.|I'll keep going.",
						cheeky = "ugh, fine|you owe me a nap",
						cool = "Understood, back to it.",
						bookish = "All right, it's only four more hours, anyway.",
						gloomy = "Yeah, I figured.|Back to it, as usual.",
						polite = "Of course, I understand.",
						foodie = "Okay, but I'm having a very big dinner tonight.",
						nervous = "Okay, s-sorry for asking.|I'll keep going.",
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
				line(nil, "The town inspector came by with a clipboard."),
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
				sunny = "{player}, sit, sit.|You've been running around all day.",
				gentle = "{player}, come and sit for a minute.|Have you eaten today, properly, I mean?",
				bold = "{player}, sit down.|You look really tired, you know that?",
				dreamy = "There's room on the bench.|Hmm... the sun's nice right here.",
				easygoing = "Sit down, seriously.|The town won't fall over in five minutes.",
				proud = "Even I take breaks, {player}, so sit.",
				shy = "Um, {player}?|Do you want to sit down? Only if you want to.",
				cheeky = "you've been building so much i thought you'd turned into a hammer|sit down, hammer",
				cool = "{player}, sit for a bit.|You've earned it.",
				prickly = "You look tired.|I wasn't watching you or anything, so just sit down.",
				dramatic = "You'll wear yourself OUT, {player}, so rest.",
				bookish = "{player}, did you know people work better after a short rest?|Sit with me for a minute and we'll test it.",
				gloomy = "You'll burn out like that.|Sit with me for a bit, it's fine.",
				polite = "Hello, {player}.|Would you like to join me for a moment?",
				foodie = "Sit down, I've got half a sandwich.|It's the good half.",
				nervous = "Are you okay?|You look really tired.",
				_ = "Come and sit for a minute, {player}.",
			}, "heart", "wave")
		do
			table.insert(s.lines, l)
		end
		s:choice("Move over, then.", function(c)
			c:n("You sat on the bench with {a} for a while and watched the pigeons.")
			c:by("a", {
				cool = "That's better.",
				prickly = "See, that wasn't so hard... I liked that, actually.",
				gloomy = "That was nice, will you come back tomorrow?",
				gentle = "There, isn't that better? Take care of yourself today.",
				sunny = "Ehehe, that was nice! Let's do it again tomorrow.",
				bold = "That's better, right? ...Thanks, anyway.",
				dreamy = "La la ♪... that pigeon had such a funny walk.",
				easygoing = "See, nothing fell over, and we got a nice sit.",
				proud = "You're welcome, by the way. My breaks are the best breaks.",
				shy = "Um... thank you for sitting with me.",
				cheeky = "you nearly fell asleep, hehe",
				dramatic = "That was the most PEACEFUL ten minutes of my life.",
				bookish = "That was twelve minutes, actually. You look better already.",
				polite = "Thank you for sitting with me, {player}. Have a lovely day.",
				foodie = "Better, right? Next time I'll bring the other half of the sandwich.",
				nervous = "Do you feel better? I hope that was okay.",
				_ = "Feeling a bit better now?",
			}, "heart")
			c:hearts("a", 1)
			c:mood("a", 5)
			c:memo("a", "Remember when we sat by the fountain, {player}? We should do that more.")
		end)
		s:choice("Sorry, I'm too busy.", function(c)
			c:by("a", {
				prickly = "Fine, don't say I didn't warn you.",
				nervous = "Okay, but what if you get too tired? Please rest soon.",
				sunny = "Aw, okay, then let's sit together tomorrow.",
				gentle = "All right, but I'm bringing you soup later.",
				bold = "Fine, but you're sitting down tomorrow, I'll make sure of it.",
				dreamy = "Oh... I'll save you a seat on the bench, then.",
				easygoing = "Eh, okay, the bench will still be here.",
				proud = "Hmph, your loss, I'm excellent company.",
				shy = "Oh... of course, but don't work too hard.",
				cheeky = "ok, but i'm telling everyone you skipped your break",
				cool = "Okay, but drink some water.",
				dramatic = "Then I will WORRY about you all day.",
				bookish = "Okay, but you'll get less done tired, actually.",
				gloomy = "Yeah, I figured. Don't work too hard.",
				polite = "Of course, please take care of yourself.",
				foodie = "Okay, at least take this sandwich with you.",
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
		s:n("It's dark on the path, and then {a} walks up behind you with a lantern.")
		for _, l in
			burst(ctx, "a", a, {
				sunny = "{player}, it's pitch black out here.|You'll fall in a ditch, so I'm walking you home.",
				gentle = "It's very dark tonight.|Let me light the way for you, okay?",
				bold = "You'll trip in this, so walk with me.",
				dreamy = "The moon's hiding tonight.|Hmm... do you want to share my light?",
				cool = "It's too dark to walk alone, so I'll take you back.",
				prickly = "I was going this way anyway.|Don't read into it.",
				dramatic = "Through the DARKNESS, I bring you light!",
				gloomy = "There's a hole by the gate.|I fell in it once, so walk with me.",
				polite = "Good evening, {player}.|May I walk with you? It is very dark tonight.",
				foodie = "I'm heading to the bakery's back door for yesterday's buns.|It's the same way as you.",
				nervous = "It's so dark out here.|C-can I walk with you? It's for both of us.",
				easygoing = "Hey, {player}, I'm walking that way anyway, slowly, so come on.",
				proud = "Lucky for you, I brought the brightest lantern in town.",
				shy = "Um, {player}?|I have a lantern, if you want to walk with me.",
				cheeky = "boo|hehe, did i scare you? come on, i'll walk you home",
				bookish = "There's no moon tonight, so it's darker than usual.|I'll walk you back.",
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
				sunny = "Okay, see you tomorrow, then.",
				gentle = "All right, take care on the way, okay?",
				bold = "Fine, but I'm standing here until you're inside.",
				dreamy = "Okay... follow the stars, then.",
				easygoing = "Okay, night, I'm off to bed anyway.",
				proud = "Hmph, fine, but my lantern is the best one.",
				shy = "Oh... okay, good night.",
				cheeky = "ok, try not to walk into the fountain",
				dramatic = "Then go, brave {player}, into the NIGHT.",
				bookish = "Okay, but the third step by the gate is loose, just so you know.",
				gloomy = "Okay. Watch out for the hole by the gate.",
				polite = "Of course, good night, {player}, and have a safe walk home.",
				foodie = "Okay, night, I'm off to get those buns.",
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
		s:n("{a} is writing a letter to a friend on another island, but they're stuck on one word.")
		for _, l in
			burst(ctx, "a", a, {
				sunny = "{player}, help.|I want to say the sea looked... ugh, what's the word?",
				dreamy = "{player}...|The sea this morning looked... hmm, how did it look?",
				cool = "{player}, I need a word for how the sea looked this morning.",
				prickly = "{player}, I need one word.|Don't laugh, I'm stuck on how to describe the sea.",
				dramatic = "{player}, how do I describe the sea?|Words FAIL me!",
				bookish = "{player}, could you help me?|I've crossed out six words already, and none of them were right.",
				gloomy = "{player}, I want to say the sea looked like something.|Something that isn't sad, for once.",
				polite = "Excuse me, {player}.|Could you help me? I cannot think how to describe the sea.",
				foodie = "{player}, the sea looked like... soup.|No, not soup, something else.",
				nervous = "{player}, help me.|What if I pick the wrong word and they think it's weird?",
				gentle = "{player}, could you help me with a word?|I want to say how the sea looked this morning.",
				bold = "{player}, quick, give me a word for the sea this morning.|You're good at this, right?",
				easygoing = "{player}, what's a word for how the sea looked?|No rush, I've been stuck for an hour.",
				proud = "{player}, my letter is nearly perfect.|I only need one word for the sea, and it must be a good one.",
				shy = "Um, {player}?|Could you help me find a word for the sea?",
				cheeky = "{player}, give me a word for the sea|and not wet, i already tried wet",
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
					sunny = "{Word}, yes, yes, that's it!",
					gentle = "{Word}... oh, that's lovely, thank you.",
					bold = "{Word}, right, that's the one.",
					dreamy = "{Word}... hmm, yes, I can see it now.",
					easygoing = "{Word}, yeah, that works, thanks.",
					proud = "{Word}, yes, I was just about to say that.",
					shy = "{Word}... yes, that's it, thank you.",
					cheeky = "{word}, ok, you're smarter than you look, jk",
					dramatic = "{Word}, PERFECT.",
					polite = "{Word}, yes, that is perfect, thank you.",
					foodie = "{Word}, yes, much better than soup.",
					nervous = "Is {word} okay? Yes, I think that's it.",
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

for _, name in { "Talks", "Solo", "Pairs", "Town", "Work", "Asks", "Moments", "Needs", "Things", "Later" } do
	local module = script:FindFirstChild(name)
	if module then
		for _, def in require(module) :: any do
			-- which part of town life it is (Data/NewsKinds tells its story in the news by it)
			def.group = def.group or string.lower(name)
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
