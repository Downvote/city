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
--   Pairs     two or three together: games, duets, secrets, crushes, falling out, making up
--   Town      the whole town: power cuts, talent night, a parade, a lost dog, the seasons
--   Work      at work: big orders, a tower of bricks, the wrong letters
--   Asks      a villager asks you: a name for a pet, which outfit, whether to tell the truth
-- A scene may name props (Data/EventProps) to put by its stars while it plays; an answer may
-- leave one for a while, give you a keepsake, or teach them a saying or a hobby.

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
	local p = Personalities.get(ctx.v(vid).pers)
	local lines = p and p.lines[kind] or { "..." }
	return line(who, ctx.rng:pick(lines), icon, gesture)
end

local QUARREL = {
	"the last slice of pie",
	"whose turn it was to sweep",
	"a board game rule",
	"who snores louder",
	"the right way to fold socks",
	"a borrowed umbrella that never came back",
	"whether toast counts as bread",
	"who saw the shooting star first",
}

local PLACES = { "the fountain", "the hill behind town", "the old gate", "the shady trees by the road", "the market" }

local JOKES = {
	{ "Why did the scarecrow win a prize? It was outstanding in its field.", "groan" },
	{ "I told my plant a joke. It didn't laugh, but it grew a little.", "laugh" },
	{ "What do you call a sleeping bull? A bulldozer.", "groan" },
	{ "I'm reading a book about anti-gravity. I can't put it down.", "laugh" },
	{ "Why don't eggs tell jokes? They'd crack each other up.", "laugh" },
}

local LOST = { "lucky sock", "favourite pencil", "house key", "lunch box", "tiny notebook", "hair clip" }

local HOBBIES = {
	"painting the fence a slightly different shade of white",
	"doing push-ups behind the house",
	"reading under a tree",
	"jogging laps round the garden",
	"stretching very seriously",
	"humming to the flowers",
}

local DREAMS = {
	"a giant pancake that could talk",
	"being chased by a polite goose",
	"living inside a teapot",
	"winning a race against the wind",
	"a town where all the doors were round",
	"meeting a cloud that wanted to be a sheep",
}

local SKILLS =
	{ "whistle with two fingers", "juggle three apples", "tie a proper knot", "skip stones", "do a cartwheel" }

local WANTS = { "a new pair of boots", "a fancy hat", "a fishing rod", "a set of paints", "a kite", "a guitar" }

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
	"a book they had finished",
	"a drawing of the two of them",
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
				line(nil, "They both look at you."),
			},
			choices = {
				{
					text = ctx.f("Side with {a}"),
					lines = { voice(ctx, "a", a, "happy", "sparkle", "cheer"), line("b", "Fine. Whatever.", "anger") },
					effects = {
						{ t = "rel", a = "a", b = "b", d = -12 },
						{ t = "mood", who = "a", d = 6 },
						{ t = "mood", who = "b", d = -8 },
						{ t = "quarrel", a = "a", b = "b" },
					},
				},
				{
					text = ctx.f("Side with {b}"),
					lines = { voice(ctx, "b", b, "happy", "sparkle", "cheer"), line("a", "Fine. Whatever.", "anger") },
					effects = {
						{ t = "rel", a = "a", b = "b", d = -12 },
						{ t = "mood", who = "b", d = 6 },
						{ t = "mood", who = "a", d = -8 },
						{ t = "quarrel", a = "a", b = "b" },
					},
				},
				{
					text = "Ask them to make up",
					lines = if works
						then {
							line("a", "...Sorry. I got carried away.", "sweat"),
							line("b", "Me too. Want to share the next one?", "heart"),
						}
						else {
							line("a", "Not until they say sorry first!", "anger"),
							line("b", "Then we'll be here all week.", "anger"),
						},
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
				line(nil, ctx.f("{a} walked over to {b} holding {food}.", { food = food.name:lower() })),
				line("a", "I brought a peace offering. I was being silly.", "sweat"),
				line("b", "...I was too. Thanks.", "heart"),
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
		local thing = if food then food.name:lower() else ctx.rng:pick(GIFTS)
		local lines = {
			line(nil, ctx.f("{a} has a present for {b}: {thing}.", { thing = thing })),
			line("a", "I saw this and thought of you.", "sparkle", "wave"),
		}
		local effects
		if loves and food then
			table.insert(
				lines,
				line("b", ctx.f("{food}! That's my favourite!", { food = food.name }), "heart", "cheer")
			)
			effects = {
				{ t = "rel", a = "a", b = "b", d = 14 },
				{ t = "mood", who = "b", d = 10 },
			}
		elseif ctx.rng:chance(0.12) then
			-- not quite their thing
			table.insert(lines, line("b", "Oh. Um. Thank you. I'll... save it for later.", "sweat"))
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
		return {
			title = "An outing",
			lines = {
				line("a", ctx.f("Hey {b}, want to go to {place} with me?", { place = place }), "idea", "point"),
				line("b", "Ooh, sure. Can we?", "question"),
			},
			choices = {
				{
					text = "Have fun, you two",
					lines = {
						line(nil, ctx.f("{a} and {b} headed off to {place}.", { place = place })),
						line(nil, "They came back tired, a bit sunburnt and still laughing."),
					},
					effects = {
						{ t = "away", who = { "a", "b" }, seconds = 30 },
						{ t = "rel", a = "a", b = "b", d = 12 },
						{ t = "mood", who = "a", d = 8 },
						{ t = "mood", who = "b", d = 8 },
					},
				},
				{
					text = "Maybe another day",
					lines = { line("a", "Aw. Okay.", "sad") },
					effects = { { t = "mood", who = "a", d = -3 }, { t = "mood", who = "b", d = -2 } },
				},
			},
			default = 1,
			log = ctx.f("{a} and {b} went to {place}.", { place = place }),
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
			"hid behind a door and shouted BOO at {b}",
			"tied {b}'s shoelaces together while they napped",
		}
		local prank = ctx.f(ctx.rng:pick(pranks))
		local goodSport = isPers(ctx, b, "cheeky", "sunny", "easygoing")
		return {
			title = "A prank",
			lines = {
				line(nil, ctx.f("{a} {prank}.", { prank = prank })),
				line("a", "Hehehe. Got you!", "sparkle", "laugh"),
				if goodSport
					then line("b", "Okay, okay, that was good. You'll pay for it though.", "music", "laugh")
					else line("b", "That wasn't funny!", "anger"),
			},
			choices = {
				{
					text = "Laugh along",
					lines = if goodSport
						then { line("b", "Ha! Alright. Truce.", "music") }
						else { line("b", "You're both terrible.", "anger") },
					effects = if goodSport
						then { { t = "rel", a = "a", b = "b", d = 8 }, { t = "mood", who = "a", d = 4 } }
						else { { t = "rel", a = "a", b = "b", d = -8 }, { t = "mood", who = "b", d = -6 } },
				},
				{
					text = ctx.f("Tell {a} off"),
					lines = { line("a", "Fine, fine. Sorry.", "sweat"), line("b", "Thank you.", "heart") },
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
		return {
			title = "A compliment",
			lines = {
				line("a", ctx.f("{b}, I really like your {thing}.", { thing = thing }), "sparkle"),
				if proud
					then line("b", "Naturally. But thank you for noticing.", "sparkle")
					else voice(ctx, "b", b, "thanks", "heart"),
			},
			effects = { { t = "rel", a = "a", b = "b", d = 6 }, { t = "mood", who = "b", d = 5 } },
			log = ctx.f("{a} said nice things about {b}'s {thing}.", { thing = thing }),
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
			lines = {
				line("a", ctx.f("{b}! Arm wrestle. Loser does the dishes."), "idea", "point"),
				line("b", "You're on!", "sparkle"),
				line(nil, "A lot of grunting later..."),
				line(winner, "Ha! Dishes are all yours.", "sparkle", "cheer"),
				line(loser, "Next time. Next time for sure.", "sweat"),
			},
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
		local food = ctx.rng:pick(Foods.list)
		local burnt = ctx.rng:chance(0.2)
		return {
			title = "In the kitchen",
			lines = {
				line(nil, ctx.f("{a} and {b} are making {food} together.", { food = food.name:lower() })),
				if burnt
					then line("a", "Is it meant to smell like that?", "sweat")
					else line("a", "Pass me the spoon!", "music"),
				if burnt
					then line("b", "...We'll call it extra crispy.", "sweat")
					else line("b", "This is going to be so good.", "heart"),
			},
			-- they eat what they make: a good one cheers them both up
			effects = if burnt
				then { { t = "rel", a = "a", b = "b", d = 5 } }
				else {
					{ t = "rel", a = "a", b = "b", d = 6 },
					{ t = "mood", who = "a", d = 4 },
					{ t = "mood", who = "b", d = 4 },
				},
			log = ctx.f("{a} and {b} cooked {food}.", { food = food.name:lower() }),
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
			lines = {
				line(nil, ctx.f("{a} and {b} stayed up late talking.")),
				line("a", "Can I tell you something? You can't laugh.", "sweat"),
				line("b", "I promise.", "heart"),
				line(nil, "Whatever it was, it stays between them."),
			},
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
			lines = {
				line("a", ctx.f("Race you to the fence, {b}!"), "idea", "point"),
				line(nil, "They're off!"),
				line(winner, "I win!", "sparkle", "cheer"),
				if sore
					then line(loser, "That didn't count. I wasn't ready.", "anger")
					else line(loser, "Wow, you're fast.", "sweat"),
			},
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
			lines = {
				line("a", joke[1], "music", "point"),
				if laughs
					then line("b", "Hahaha! Okay, that's a good one.", "music", "laugh")
					else line("b", "...I'm leaving.", "sweat"),
			},
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
		return {
			title = "Lost and found",
			lines = {
				line("a", ctx.f("Has anyone seen my {thing}? I've looked everywhere.", { thing = thing }), "question"),
				if helps
					then line("b", "Let's look together.", "idea")
					else line("b", "Did you check your pocket?", "question"),
			},
			choices = {
				{
					text = "Help them look",
					lines = {
						line(nil, ctx.f("It was under a flowerpot the whole time.")),
						line("a", "Thank you both!", "heart", "cheer"),
					},
					effects = { { t = "rel", a = "a", b = "b", d = 8 }, { t = "mood", who = "a", d = 6 } },
				},
				{
					text = "It'll turn up",
					lines = { line("a", "I suppose...", "sad") },
					effects = { { t = "mood", who = "a", d = -3 } },
				},
			},
			default = 1,
			log = ctx.f("{a} lost their {thing}.", { thing = thing }),
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
		return {
			title = "A lesson",
			lines = {
				line("a", ctx.f("Want me to show you how to {skill}?", { skill = skill }), "idea"),
				line("b", "Yes please!", "sparkle"),
				line(nil, "A few tries later, they get it."),
				line("b", "I did it!", "sparkle", "cheer"),
			},
			effects = { { t = "xp", who = "b", d = 35 }, { t = "rel", a = "a", b = "b", d = 5 } },
			log = ctx.f("{a} taught {b} to {skill}.", { skill = skill }),
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
			lines = {
				line(nil, ctx.f("{b} and {c} are laughing together again.")),
				line("a", "They always do stuff without me.", "sad"),
			},
			choices = {
				{
					text = ctx.f("Get them to invite {a}"),
					lines = { line("b", ctx.f("Hey {a}, come join us!"), "wave"), line("a", "Really? Okay!", "heart") },
					effects = {
						{ t = "rel", a = "a", b = "b", d = 8 },
						{ t = "rel", a = "a", b = "c", d = 8 },
						{ t = "mood", who = "a", d = 6 },
					},
				},
				{
					text = ctx.f("Cheer {a} up yourself"),
					lines = { line("a", "Thanks. You're a good friend.", "heart") },
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
		return {
			title = "A craving",
			lines = {
				line("a", ctx.f("I really want some {food}. Like, really.", { food = food.name:lower() }), "idea"),
			},
			choices = {
				{
					text = ctx.f("Buy them some ({price} coins)", { price = price }),
					cost = price,
					lines = {
						if loves
							then line(
								"a",
								ctx.f("{food}! My favourite. You're the best.", { food = food.name }),
								"heart",
								"cheer"
							)
							else line("a", "You're the best!", "heart", "cheer"),
					},
					effects = {
						{ t = "coins", d = -price },
						{ t = "mood", who = "a", d = L.WishMood + (if loves then L.FavWishMood else 0) },
						{ t = "hearts", who = "a", n = L.WishHearts + (if loves then L.FavWishHearts else 0) },
					},
				},
				{
					text = "Not right now",
					lines = { line("a", "Okay... my tummy is sad though.", "sad") },
					effects = { { t = "mood", who = "a", d = -4 } },
				},
			},
			default = 2,
			log = ctx.f("{a} wanted {food}.", { food = food.name:lower() }),
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
		return {
			title = "A favour",
			lines = {
				line(
					"a",
					ctx.f("Could I have {cost} coins? I've had my eye on {thing}.", { cost = cost, thing = thing }),
					"question"
				),
			},
			choices = {
				{
					text = ctx.f("Here you go ({cost} coins)", { cost = cost }),
					cost = cost,
					lines = { line("a", "Thank you! I love it!", "sparkle", "cheer") },
					effects = { { t = "coins", d = -cost }, { t = "mood", who = "a", d = 12 } },
				},
				{
					text = "Not this time",
					lines = { voice(ctx, "a", a, "sad", "sad") },
					effects = { { t = "mood", who = "a", d = -4 } },
				},
			},
			default = 2,
			log = ctx.f("{a} asked for coins for {thing}.", { thing = thing }),
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
				lines = { line("a", "My room has everything. I love it here.", "heart") },
				effects = { { t = "mood", who = "a", d = 5 } },
				log = ctx.f("{a} loves their room."),
			}
		end
		local tag = ctx.rng:pick(tags)
		return {
			title = "A wish",
			lines = {
				line(
					"a",
					ctx.f("Do you think I could have {thing} near my bed?", { thing = Catalog.Tags[tag] }),
					"idea"
				),
				line(nil, "Put one within a few steps of their bed in Build mode."),
			},
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
			lines = {
				line("a", "Um. Where do I sleep?", "sad"),
				line(nil, "Every villager needs a bed. Find beds under Furniture in Build mode."),
			},
			effects = { { t = "mood", who = "a", d = -3 } },
			log = ctx.f("{a} has no bed."),
		}
	end,
})

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
				line("a", ctx.f("Last night I dreamed about {dream}.", { dream = dream }), "zzz"),
				line("a", "I think it means something. Or I'm hungry.", "question"),
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
		return {
			title = "Lucky find",
			lines = { line("a", ctx.f("Look! {coins} coins in the grass!", { coins = amount }), "sparkle", "cheer") },
			effects = { { t = "coins", d = amount } },
			log = ctx.f("{a} found {coins} coins.", { coins = amount }),
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
		local lines = { line("a", "Achoo! I think I caught a cold.", "sweat") }
		if doctor then
			local name = ctx.v(doctor).name
			table.insert(choices, {
				text = ctx.f("Send them to {doctor}", { doctor = name }),
				lines = {
					line(nil, ctx.f("{doctor} had a look and sent {a} off with a hot lemon drink.", { doctor = name })),
					line("a", "Tastes awful. Feeling better though.", "sparkle"),
				},
				effects = {
					{ t = "mood", who = "a", d = 4 },
					{ t = "relv", a = a, b = doctor, d = 4 },
					{ t = "xpv", vid = doctor, d = 10 },
				},
			})
		else
			table.insert(lines, line(nil, "A doctor in town would see to this. A clinic desk opens the job."))
		end
		table.insert(choices, {
			text = "Rest it off in bed",
			lines = { line("a", "Okay... wake me when I'm better.", "zzz") },
			effects = { { t = "sick", who = "a", minutes = 5 }, { t = "mood", who = "a", d = -2 } },
		})
		if not doctor then
			table.insert(choices, {
				text = "Ask them to carry on",
				lines = { line("a", "Fine. Achoo. Fine.", "sad") },
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
			lines = {
				line(nil, ctx.f("{a} spent the afternoon {hobby}.", { hobby = hobby })),
				line("a", "Time well spent.", "sparkle"),
			},
			effects = { { t = "mood", who = "a", d = 4 } },
			log = ctx.f("{a} spent the afternoon {hobby}.", { hobby = hobby }),
		}
	end,
})

-- A new look.
event({
	id = "newlook",
	actors = 1,
	when = "day",
	weight = function(ctx: Ctx, a: string)
		return 0.35
	end,
	scene = function(ctx: Ctx, a: string): Scene
		return {
			title = "Time for a change",
			lines = { line("a", "I'm bored of my clothes. Could you help me pick something new?", "question") },
			choices = {
				{
					text = "Let's do it",
					lines = { line("a", "Yay!", "sparkle", "cheer") },
					effects = { { t = "creator", who = "a" }, { t = "mood", who = "a", d = 6 } },
				},
				{
					text = "You look great already",
					lines = { line("a", "Aw. Okay, if you say so.", "heart") },
					effects = { { t = "mood", who = "a", d = 2 } },
				},
			},
			default = 2,
			log = ctx.f("{a} wanted a new look."),
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
			lines = { line(nil, ctx.f("{a} is sleepwalking again.")), line("a", "Mmm... five more pancakes...", "zzz") },
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
		local w = ctx.job(a)
		local place = w.def.name:lower()
		return {
			title = "Practice",
			lines = {
				line(nil, ctx.f("{a} stayed late at the {place} to practise.", { place = place })),
				line("a", "I'm getting the hang of this.", "sparkle", "point"),
			},
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
			lines = { line("a", "Everyone seems to have friends but me.", "sad") },
			choices = {
				{
					text = ctx.f("Introduce them to {b}"),
					lines = {
						line("b", ctx.f("Hi {a}! I've been meaning to say hello."), "wave"),
						line("a", "Oh! Hi!", "heart"),
					},
					effects = { { t = "rel", a = "a", b = "b", d = 12 }, { t = "mood", who = "a", d = 6 } },
				},
				{
					text = "Give them some space",
					lines = { line("a", "Yeah. Maybe tomorrow.", "sad") },
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
				line(nil, ctx.f("It's {a}'s birthday today!")),
				line(nil, "Everyone gathers round with cake."),
				line("a", "You all remembered! This is the best.", "heart", "cheer"),
			},
			effects = effects,
			log = ctx.f("{a} had a birthday party."),
		}
	end,
})

-- Someone new wants to move in.
event({
	id = "visitor",
	actors = 0,
	when = "day",
	weight = function(ctx: Ctx)
		-- friends first, then the town's own newcomers, nobody twice (Sim/Newcomers)
		if ctx.freeSlots <= 0 or not ctx.newcomer() then
			return 0
		end
		local count = #ctx.present
		return Tuning.Events.VisitorChance * (if count < 3 then 3 else 1)
	end,
	scene = function(ctx: Ctx): Scene
		local who = ctx.newcomer()
		local name = who.name
		local hello = if who.userId
			then "Your friend {name} has turned up at the edge of town with a suitcase."
			else "A traveller called {name} is passing through town."
		return {
			title = "A visitor",
			lines = {
				line(nil, ctx.f(hello, { name = name })),
				line(nil, ctx.f("{name} likes it here and asks if there's room for one more.", { name = name })),
			},
			choices = {
				{
					text = ctx.f("Welcome, {name}!", { name = name }),
					lines = { line(nil, ctx.f("{name} is moving in.", { name = name })) },
					effects = { { t = "visitor", name = name, key = who.key } },
				},
				{
					text = "Make your own villager instead",
					lines = { line(nil, "The tailor's stall can help with that.") },
					effects = { { t = "creator" } },
				},
				{
					text = "Not right now",
					lines = { line(nil, ctx.f("{name} waves and heads off down the road.", { name = name })) },
					effects = {},
				},
			},
			default = 3,
			log = ctx.f("{name} stopped by.", { name = name }),
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
			lines = { line(nil, "Someone turned the music up. Everyone's dancing!") },
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
				line(nil, "Shooting stars over town! Everyone makes a wish."),
				line(nil, "Nobody says what they wished for. They all stay up far too late."),
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
			lines = { line(nil, "Thunder rolls over town and everyone runs for a roof.") },
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
		local place = w.def.name:lower()
		local coins = Tuning.Jobs.VisitCoins * ctx.rng:int(2, 5)
		return {
			title = "A customer",
			lines = {
				line(nil, ctx.f("{b} stopped by {a}'s {place}.", { place = place })),
				line("a", ctx.rng:pick(w.job.lines), "music", "wave"),
				line("b", "I'll take one of those, please.", "sparkle"),
			},
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
		local place = w.def.name:lower()
		local coins = math.floor(w.job.income * Tuning.Jobs.BusyDayShare)
		return {
			title = "A busy day",
			lines = {
				line(nil, ctx.f("Customers keep queueing at {a}'s {place}.", { place = place })),
				line("a", "I've never been this busy! I love it.", "sparkle", "cheer"),
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
			lines = { line("a", "Could I take the rest of today off? I'm worn out.", "sweat") },
			choices = {
				{
					text = "Go and rest",
					lines = { line("a", "Thank you! Hammock, here I come.", "heart", "cheer") },
					effects = { { t = "dayoff", who = "a" }, { t = "mood", who = "a", d = 10 } },
				},
				{
					text = "We need you today",
					lines = { line("a", "Okay... back to it.", "sad") },
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
			lines = {
				line("a", "I'd love a job. Anything, really.", "question"),
				line(nil, "Put a workplace down from the Work tab in Build mode and they'll take it."),
			},
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
				line(nil, ctx.f("They left a tip of {coins} coins.", { coins = tip })),
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

-- Romance ----------------------------------------------------------------------------------------------

local CRUSH_SCORE = Tuning.Life.CrushScore

-- Two good friends, and one of them has gone a bit pink.
event({
	id = "crush",
	actors = 2,
	when = "day",
	weight = function(ctx: Ctx, a: string, b: string)
		if ctx.quarreling(a, b) or not ctx.free(a) or not ctx.free(b) then
			return 0
		end
		local score = ctx.rel(a, b)
		if score < CRUSH_SCORE then
			return 0
		end
		return 1.2 + (score - CRUSH_SCORE) / 25
	end,
	scene = function(ctx: Ctx, a: string, b: string): Scene
		return {
			title = "A little crush",
			lines = {
				line(nil, ctx.f("{a} keeps glancing over at {b} and going pink.")),
				line("a", ctx.f("Do you think {b} likes anyone? Asking for a friend."), "sweat"),
			},
			choices = {
				{
					text = ctx.f("Tell {a} to say something"),
					lines = { line("a", "Maybe I will. Not today, though. Soon.", "heart") },
					effects = { { t = "bond", a = "a", b = "b", to = "crush" }, { t = "mood", who = "a", d = 4 } },
				},
				{
					text = "Keep it to yourself",
					lines = { line("a", "Forget I said anything.", "sweat") },
					effects = { { t = "rel", a = "a", b = "b", d = 2 } },
				},
			},
			default = 2,
			log = ctx.f("{a} has a soft spot for {b}."),
		}
	end,
})

-- The crush wants to say how they feel. It might not go their way.
event({
	id = "confess",
	actors = 2,
	when = "any",
	weight = function(ctx: Ctx, a: string, b: string)
		if ctx.bond(a, b) ~= "crush" or ctx.quarreling(a, b) then
			return 0
		end
		return 3
	end,
	scene = function(ctx: Ctx, a: string, b: string): Scene
		local score = ctx.rel(a, b)
		local works = ctx.rng:chance(math.clamp(0.45 + (score - CRUSH_SCORE) / 60, 0.3, 0.9))
		local yes = {
			line("a", ctx.f("{b}, I like you. Like, really like you."), "heart"),
			line("b", "Oh. I was hoping you'd say that.", "heart", "cheer"),
			line(nil, ctx.f("{a} and {b} are sweethearts now.")),
		}
		local no = {
			line("a", ctx.f("{b}, I like you. Like, really like you."), "heart"),
			line("b", "You're lovely. But I think we're better as friends.", "sweat"),
			line("a", "Right. Yes. Of course. I'll just go and sit in the sea for a bit.", "sad"),
		}
		return {
			title = "Saying it out loud",
			lines = {
				line(nil, ctx.f("{a} has been pacing by the fountain all morning.")),
				line("a", ctx.f("I'm going to tell {b} how I feel. Should I?"), "sweat"),
			},
			choices = {
				{
					text = "Go for it",
					lines = if works then yes else no,
					effects = if works
						then {
							{ t = "bond", a = "a", b = "b", to = "sweethearts" },
							{ t = "rel", a = "a", b = "b", d = 8 },
							{ t = "mood", who = "a", d = 15 },
							{ t = "mood", who = "b", d = 15 },
							{ t = "hearts", who = "a", n = 3 },
						}
						else {
							{ t = "bond", a = "a", b = "b", to = nil },
							{ t = "rel", a = "a", b = "b", d = -4 },
							{ t = "mood", who = "a", d = -12 },
						},
				},
				{
					text = "Wait for a better moment",
					lines = { line("a", "You're right. Tomorrow. Probably.", "sweat") },
					effects = { { t = "mood", who = "a", d = -2 } },
				},
			},
			default = 2,
			log = if works then ctx.f("{a} and {b} got together.") else ctx.f("{a} told {b} how they felt."),
		}
	end,
})

-- Sweethearts out for the day.
event({
	id = "date",
	actors = 2,
	when = "day",
	weight = function(ctx: Ctx, a: string, b: string)
		if ctx.bond(a, b) ~= "sweethearts" or ctx.quarreling(a, b) then
			return 0
		end
		return 2.6
	end,
	scene = function(ctx: Ctx, a: string, b: string): Scene
		local plans = {
			"a picnic on the beach",
			"a walk along the sand at sunset",
			"ice cream by the fountain",
			"counting boats from the pier",
			"a slow dance at the bandstand",
		}
		local plan = ctx.rng:pick(plans)
		return {
			title = "A day out",
			lines = {
				line(nil, ctx.f("{a} and {b} went out for {plan}.", { plan = plan })),
				line("b", "We should do this every day.", "heart"),
				line("a", "We nearly do.", "heart"),
			},
			effects = {
				{ t = "rel", a = "a", b = "b", d = 6 },
				{ t = "mood", who = "a", d = 8 },
				{ t = "mood", who = "b", d = 8 },
			},
			log = ctx.f("{a} and {b} went out for {plan}.", { plan = plan }),
		}
	end,
})

-- Sweethearts for long enough, and one of them has a ring in their pocket.
event({
	id = "propose",
	actors = 2,
	when = "day",
	weight = function(ctx: Ctx, a: string, b: string)
		if ctx.bond(a, b) ~= "sweethearts" or ctx.rel(a, b) < Tuning.Life.ProposeScore then
			return 0
		end
		return 3
	end,
	scene = function(ctx: Ctx, a: string, b: string): Scene
		local works = ctx.rng:chance(0.85)
		return {
			title = "A big question",
			lines = {
				line(nil, ctx.f("{a} pulls you aside and opens a tiny box. There's a ring in it.")),
				line("a", ctx.f("I want to ask {b} to be my partner for life. Will you help me plan it?"), "heart"),
			},
			choices = {
				{
					text = "Plan it with them",
					lines = if works
						then {
							line("a", ctx.f("{b}, will you be my partner for life?"), "heart"),
							line("b", "Yes. Obviously yes.", "heart", "cheer"),
							line(nil, "The whole town turns up to celebrate."),
						}
						else {
							line("a", ctx.f("{b}, will you be my partner for life?"), "heart"),
							line("b", "Can we give it a little longer? I do love you.", "sweat"),
						},
					effects = if works
						then {
							{ t = "bond", a = "a", b = "b", to = "partners" },
							{ t = "mood", who = "a", d = 20 },
							{ t = "mood", who = "b", d = 20 },
							{ t = "hearts", who = "a", n = 4 },
							{ t = "hearts", who = "b", n = 4 },
							{ t = "festival" },
						}
						else { { t = "rel", a = "a", b = "b", d = -6 }, { t = "mood", who = "a", d = -6 } },
				},
				{
					text = "Maybe wait a little",
					lines = { line("a", "You're right. I want it to be perfect.", "sweat") },
					effects = {},
				},
			},
			default = 2,
			log = if works then ctx.f("{a} and {b} are partners for life.") else ctx.f("{a} asked {b} a big question."),
		}
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
