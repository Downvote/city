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
-- chats): the villager speaks first, in bursts of two or three short messages where one long one
-- would do, each personality in its own way; your answer is one of two short replies; and now
-- and then they use your name, {player} (filled by ctx.f with the player's display name).

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
	return line(who, ctx.f(ctx.rng:pick(lines)), icon, gesture)
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
	for part in string.gmatch(text, "[^|]+") do
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

-- What someone says when you take the other side in a quarrel, in their own way.
local SULK = {
	proud = "Fine. You'll see I was right.",
	shy = "Oh...|okay.",
	gentle = "All right, {player}. If that's how it is.",
	cheeky = "wow|ok|noted",
	dreamy = "Oh.|I'll go and be wrong somewhere else, then.",
	easygoing = "Eh. Fine.",
	sunny = "Oh. Okay. I'm not upset.|...I'm a bit upset.",
	bold = "Fine. Your call.",
	cool = "...Fine.",
	prickly = "Whatever. Don't talk to me for a bit.",
	dramatic = "Betrayed, {player}. By YOU!",
	bookish = "I still think the facts were on my side.|But fine.",
	gloomy = "Yeah. Figures.",
	polite = "I see. Thank you for listening, at least.",
	foodie = "Fine.|I'm going to go and eat something about it.",
	nervous = "Oh. Was I wrong?|Was I being awful? Oh no.",
	_ = "Fine. Whatever.",
}

-- A line in the villager's own way (Kit.byPers): a map keyed by personality, "_" for anyone else.
-- (filled, so a line may name the stars or call the player by name: {player})
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
				line(nil, "They both turn to you."),
			},
			choices = {
				{
					text = ctx.f("{a}'s right."),
					lines = join(voice(ctx, "a", a, "happy", "sparkle", "cheer"), burst(ctx, "b", b, SULK, "anger")),
					effects = {
						{ t = "rel", a = "a", b = "b", d = -12 },
						{ t = "mood", who = "a", d = 6 },
						{ t = "mood", who = "b", d = -8 },
						{ t = "quarrel", a = "a", b = "b" },
					},
				},
				{
					text = ctx.f("{b}'s right."),
					lines = join(voice(ctx, "b", b, "happy", "sparkle", "cheer"), burst(ctx, "a", a, SULK, "anger")),
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
								proud = "...Fine.|I may have got a bit carried away.",
								bold = "...Yeah. Sorry. I got loud.",
								shy = "...Sorry.|I didn't mean it.",
								cool = "...Yeah.|My bad.",
								prickly = "...Fine. Sorry.|There. I said it.",
								dramatic = "I was a monster!|A MONSTER. Sorry.",
								polite = "You're right, {player}. I apologise. Sincerely.",
								nervous = "Sorry. S-sorry. Are we okay?|Are we okay now?",
								_ = "...Sorry. I got carried away.",
							}, "sweat"),
							burst(ctx, "b", b, {
								gentle = "Me too. Let's forget it, shall we?",
								cheeky = "me too|hug?|no? ok",
								proud = "...So did I. A little.",
								gloomy = "Yeah. Me too. It's fine.",
								foodie = "Me too.|Want to go and get a bun?",
								sunny = "Me too! Okay. Friends again?",
								_ = "Me too. Let's forget about it.",
							}, "heart")
						)
						else join(
							burst(ctx, "a", a, {
								shy = "...I don't want to talk about it.",
								easygoing = "Nah. Not today.",
								cool = "No.",
								prickly = "No.|Not till they say sorry. First.",
								dramatic = "Never! Not in a hundred years!",
								_ = "Not until they say sorry first.",
							}, "anger"),
							line("b", "Then we'll be here all week.", "anger")
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
				line(nil, ctx.f("{a} walked over to {b} holding {food}.", { food = food.name:lower() })),
				by(ctx, "a", a, {
					proud = "Here. I may have been... a bit much.",
					shy = "Um. I brought you this... I'm sorry about before.",
					bold = "Here. I was out of line. Truce?",
					cheeky = "peace offering. you can't stay cross with your mouth full",
					sunny = "Hi. I brought you this. I hate being cross with you.",
					cool = "Here. Sorry.",
					prickly = "Take it. It's an apology. Don't make me say it twice.",
					dramatic = "I come bearing a gift. And my deepest sorry!",
					bookish = "I thought about it all night. You had a point. Here.",
					gloomy = "I figured you wouldn't want to see me... I brought this anyway.",
					polite = "I'd like to apologise properly. Please, take this.",
					foodie = "I brought the good one. That's how sorry I am.",
					nervous = "Is it okay if I... I brought this. Are we okay?",
					_ = "I brought you this. I was being silly.",
				}, "sweat"),
				by(ctx, "b", b, {
					proud = "...Fine. I was a bit much too.",
					gentle = "Oh, come here. I was silly too.",
					shy = "...Me too. Thank you.",
					cool = "...Thanks. Me too.",
					prickly = "...Fine. Apology accepted. I'm sorry too. Happy?",
					dramatic = "All is forgiven!",
					gloomy = "...Thanks. I missed you, honestly.",
					foodie = "You brought the good one. Okay. We're fine.",
					cheeky = "apology accepted. the bun is mine now",
					_ = "...I was too. Thanks.",
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
		local thing = if food then food.name:lower() else ctx.rng:pick(GIFTS)
		local lines = join(
			line(nil, ctx.f("{a} has a present for {b}: {thing}.", { thing = thing })),
			burst(ctx, "a", a, {
				shy = "Um.|I got you this...|you don't have to like it.",
				bold = "Here. Got you something.",
				sunny = "Surprise!|I saw it and it was SO you!",
				cool = "Here.|Thought you'd like it.",
				prickly = "Here. It was just lying around.|Don't read into it.",
				dramatic = "A gift! For you!|Because you deserve it.",
				polite = "I hope you don't mind.|I thought you might like this.",
				nervous = "I got you this. Is that okay?|You don't have to like it.",
				cheeky = "for you|it's not a prank|this time",
				_ = "I saw this and thought of you.",
			}, "sparkle", "wave")
		)
		local effects
		if loves and food then
			table.insert(
				lines,
				line("b", ctx.f("{food}. That's my favourite.", { food = food.name }), "heart", "cheer")
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
					proud = "Oh. How...|thoughtful.",
					cheeky = "oh|wow|you shouldn't have. really",
					cool = "...Thanks.",
					prickly = "Oh. It's... a thing.|Thanks. I guess.",
					gloomy = "Oh. Thanks. I'll find somewhere for it.",
					_ = "Oh. Um. Thank you.|I'll... save it for later.",
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
					sunny = "{b}! {b}! Come to {place} with me!|Now. Right now.",
					bold = "{b}.|You're free, right? We're going to {place}.",
					shy = "Um, {b}?|If you're not busy...|would you come to {place}?",
					cool = "{b}.|{place}. Coming?",
					_ = "Hey, {b}.|Want to go to {place} with me?",
				}, "idea", "point", vars),
				burst(ctx, "b", b, {
					shy = "Me?|Okay...|if that's all right.",
					easygoing = "Sure. If there's somewhere to sit.",
					cool = "Sure.",
					prickly = "I've got nothing better on. Fine.",
					dramatic = "An adventure! Yes!",
					bookish = "Oh, I've read about it. Yes, let's.",
					gloomy = "It'll rain... Okay. Yes.",
					polite = "I'd love to. Thank you for asking.",
					foodie = "Is there anywhere to eat there?|Yes. Okay. Yes.",
					nervous = "Now? Right now? Okay.|Let me get my coat. Two coats.",
					_ = "Ooh, sure. Can we, {player}?",
				}, "question")
			),
			choices = {
				{
					text = "Have fun, you two.",
					lines = {
						line(nil, ctx.f("{a} and {b} headed off to {place}.", vars)),
						line(nil, "They came back at teatime, a bit sunburnt."),
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
						sunny = "Aw. Later then!",
						shy = "Oh.|Of course. Sorry.",
						_ = "Aw. Okay.",
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
			"hid behind a door and shouted BOO at {b}",
			"tied {b}'s shoelaces together while they napped",
		}
		local prank = ctx.f(ctx.rng:pick(pranks))
		local goodSport = isPers(ctx, b, "cheeky", "sunny", "easygoing")
		return {
			title = "A prank",
			lines = join(
				line(nil, ctx.f("{a} {prank}.", { prank = prank })),
				burst(ctx, "a", a, {
					cheeky = "hehe|hehehe|got you",
					dramatic = "*evil cackle* <- me Got you.",
					cool = "Got you.",
					_ = "Heh. Got you.",
				}, "sparkle", "laugh"),
				if goodSport
					then burst(ctx, "b", b, "Okay, okay. That was good.|You'll pay for it, though.", "music", "laugh")
					else burst(ctx, "b", b, {
						bold = "Hey. Not funny.",
						proud = "How childish.",
						shy = "That...|wasn't funny.",
						gentle = "That wasn't very nice.",
						dreamy = "Oh.|Was that a joke?|I didn't like it.",
						cool = "...Really.",
						prickly = "Seriously?|Seriously. Go away.",
						dramatic = "The BETRAYAL.",
						bookish = "I'll be writing that down. For later.",
						gloomy = "Yeah. That's my luck.",
						polite = "I'd rather you didn't do that again, please.",
						foodie = "Salt? In tea?|That's a crime against tea.",
						nervous = "My heart!|My heart's going so fast.",
						_ = "That wasn't funny.",
					}, "anger")
			),
			choices = {
				{
					text = "Ha. Good one.",
					lines = if goodSport
						then burst(ctx, "b", b, "Ha. Alright.|Truce.", "music")
						else burst(ctx, "b", b, "You're both terrible.", "anger"),
					effects = if goodSport
						then { { t = "rel", a = "a", b = "b", d = 8 }, { t = "mood", who = "a", d = 4 } }
						else { { t = "rel", a = "a", b = "b", d = -8 }, { t = "mood", who = "b", d = -6 } },
				},
				{
					text = ctx.f("{a}. Not cool."),
					lines = join(
						burst(ctx, "a", a, {
							cheeky = "fine fine|sorry|...mostly",
							proud = "Fine. It was a little much.",
							_ = "Fine, fine. Sorry.",
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
					shy = "Um, {b}?|I really like your {thing}.|That's all.",
					cool = "{b}.|Good {thing}.",
					cheeky = "{b}|nice {thing}|not even joking",
					sunny = "{b}!|I love your {thing}!",
					_ = "{b}.|I really like your {thing}.",
				}, "sparkle", nil, vars),
				if proud
					then burst(ctx, "b", b, "Naturally. But thank you for noticing.", "sparkle")
					else voice(ctx, "b", b, "thanks", "heart")
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
					bold = "{b}.|Arm wrestle. Loser does the dishes.",
					cheeky = "{b}|arm wrestle|loser does the dishes. go",
					proud = "{b}. A contest.|Arm wrestling. Loser does the dishes.",
					_ = "{b}.|Arm wrestle? Loser does the dishes.",
				}, "idea", "point"),
				burst(ctx, "b", b, {
					shy = "Um.|Okay?",
					easygoing = "Do I have to?",
					cool = "Sure.",
					prickly = "Fine. You'll regret it.",
					dramatic = "I accept your challenge!",
					nervous = "Now? Okay. Don't pull too hard.|Okay. Ready.",
					_ = "You're on.",
				}, "sparkle"),
				line(nil, "A lot of grunting later..."),
				burst(ctx, winner, if aWins then a else b, {
					proud = "As expected. Enjoy the dishes.",
					shy = "Oh.|I won?|Sorry about the dishes...",
					cool = "Dishes.|Yours.",
					dramatic = "Victory is MINE!",
					_ = "Hah. Dishes are all yours.",
				}, "sparkle", "cheer"),
				burst(ctx, loser, if aWins then b else a, {
					proud = "I let you win. Obviously.",
					easygoing = "Eh. I like doing dishes anyway.",
					bold = "Again. Right now.",
					prickly = "My elbow slipped. That doesn't count.",
					gloomy = "Knew it.",
					_ = "Next time.|Next time for sure.",
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
		local food = ctx.rng:pick(Foods.list)
		local burnt = ctx.rng:chance(0.2)
		return {
			title = "In the kitchen",
			lines = join(
				line(nil, ctx.f("{a} and {b} are making {food} together.", { food = food.name:lower() })),
				if burnt
					then burst(ctx, "a", a, "Is it meant to smell like that?|...It's not, is it.", "sweat")
					else burst(ctx, "a", a, "Pass me the spoon. No, the big one.", "music"),
				if burnt
					then burst(ctx, "b", b, "...|We'll call it extra crispy.", "sweat")
					else burst(ctx, "b", b, {
						foodie = "Oh, this is going to be so good.|Can I taste it now? Now?",
						cool = "Smells good.",
						prickly = "You're stirring it wrong. ...It's fine. Keep going.",
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
			lines = join(
				line(nil, ctx.f("{a} and {b} stayed up late talking.")),
				burst(ctx, "a", a, {
					shy = "Um...|can I tell you something?|You can't laugh.",
					prickly = "I'm going to tell you something.|If you laugh, I'm leaving.",
					cool = "Can I tell you something.|Don't laugh.",
					_ = "Can I tell you something? You can't laugh.",
				}, "sweat"),
				burst(ctx, "b", b, {
					cheeky = "I promise|...I'll try",
					cool = "Promise.",
					prickly = "Just say it.|I won't laugh. Much.",
					nervous = "I promise. Is it bad?|You can tell me.",
					_ = "I promise.",
				}, "heart"),
				line(nil, "Whatever it was, it stays between them.")
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
					cheeky = "race you to the fence, {b}|go",
					sunny = "{b}! Race you to the fence!|Three, two, one!",
					_ = "Race you to the fence, {b}.",
				}, "idea", "point"),
				line(nil, "And they're off."),
				burst(ctx, winner, if aWins then a else b, {
					proud = "As expected.",
					shy = "Oh.|I won?",
					bold = "YES. First.",
					cool = "First.",
					dramatic = "The crowd goes wild!",
					nervous = "I won?|I won. Did I win? I won.",
					_ = "I win.",
				}, "sparkle", "cheer"),
				if sore
					then burst(ctx, loser, loserVid, "That didn't count. I wasn't ready.", "anger")
					else burst(ctx, loser, loserVid, {
						shy = "You're really fast...",
						easygoing = "Nope. I'm done.|You win.",
						dreamy = "I was watching a butterfly.|Well done, though.",
						prickly = "You started early. ...Fine. Well run.",
						gloomy = "Yeah. I'm slow.|I know.",
						foodie = "I'd have won if I hadn't had lunch.",
						_ = "Wow. You're fast.",
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
					cheeky = "ok ok listen",
					shy = "Um. I heard a joke.",
					_ = "Okay. Listen to this.",
				}, "idea"),
				line("a", joke[1], "music", "point"),
				if laughs
					then burst(ctx, "b", b, {
						dreamy = "Hee.|I'll laugh again later, too.",
						cheeky = "ha|I'm stealing that one",
						cool = "...Heh.",
						dramatic = "HA! Oh, that's wonderful.",
						gloomy = "Heh. Okay.|That got me.",
						_ = "Hahaha. Okay, that's a good one.",
					}, "music", "laugh")
					else burst(ctx, "b", b, {
						proud = "That was beneath both of us.",
						gentle = "Oh dear. ...Ha.",
						shy = "Um.|Heehee?",
						bold = "Boo.",
						cool = "No.",
						prickly = "I'm going to pretend you didn't say that.",
						bookish = "I've heard that one.|It's in a joke book older than both of us.",
						polite = "Very good. Ha.|Thank you.",
						_ = "...|I'm leaving.",
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
					dramatic = "{player}.|My {thing}. I've turned the whole house upside down!",
					nervous = "Has anyone seen my {thing}?|I've looked everywhere. Twice. Three times.",
					prickly = "Has anyone seen my {thing}?|Don't ask if I've looked. I've looked.",
					cool = "{player}.|Lost my {thing}.",
					sunny = "{player}! Have you seen my {thing}?|It was RIGHT here!",
					_ = "Has anyone seen my {thing}? I've looked everywhere.",
				}, "question", nil, vars),
				if helps
					then burst(ctx, "b", b, "Let's look together.", "idea")
					else burst(ctx, "b", b, "Did you check your pocket?", "question")
			),
			choices = {
				{
					text = "I'll help you look.",
					lines = join(
						line(nil, ctx.f("It was under a flowerpot the whole time.")),
						burst(ctx, "a", a, {
							prickly = "...Under a flowerpot.|Don't say anything. Thanks.",
							cool = "Found it.|...Thanks.",
							_ = "Thank you both. Thanks, {player}. I owe you.",
						}, "heart", "cheer")
					),
					effects = { { t = "rel", a = "a", b = "b", d = 8 }, { t = "mood", who = "a", d = 6 } },
				},
				{
					text = "It'll turn up.",
					lines = burst(ctx, "a", a, "I suppose...", "sad"),
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
					proud = "I'll show you how to {skill}.|I'm very good at it.",
					cheeky = "want to learn to {skill}|I'll only laugh a bit",
					_ = "Want me to show you how to {skill}?",
				}, "idea", nil, vars),
				burst(ctx, "b", b, {
					cool = "Sure.",
					prickly = "...Fine. Go on, then.",
					polite = "Yes please. Thank you.",
					nervous = "What if I can't? ...Okay. Yes please.",
					_ = "Yes please.",
				}, "sparkle"),
				line(nil, "A few tries later, they get it."),
				burst(ctx, "b", b, {
					shy = "I did it...|I actually did it.",
					proud = "There. I knew I'd get it.",
					cool = "Got it.",
					prickly = "That was easy. ...Thanks.",
					dramatic = "I have learned! I am changed!",
					bookish = "Oh, it's all in the timing.|That makes sense now.",
					gloomy = "Huh. I can do it.|I didn't think I could.",
					polite = "Thank you so much for showing me.",
					nervous = "Did I do it right?|I did it right. I did it!",
					_ = "I did it. Look.",
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
					shy = "They never ask me...|It's fine.",
					proud = "I don't need them. ...They could ask, though.",
					bold = "They could at least ask.",
					sunny = "{player}...|do they not like me?|I thought they liked me.",
					cool = "...Whatever.",
					prickly = "Don't look at me like that.|I don't care. I don't.",
					dramatic = "Forgotten. Cast aside!",
					gloomy = "Nobody ever asks me. It's fine.|I'm used to it.",
					polite = "I don't want to intrude.|They seem to be having fun.",
					nervous = "Did I do something?|Did I say something wrong?",
					_ = "They always do stuff without me.",
				}, "sad")
			),
			choices = {
				{
					text = ctx.f("Ask them to invite {a}."),
					lines = join(
						line("b", ctx.f("Hey {a}. Come and join us."), "wave"),
						burst(ctx, "a", a, {
							prickly = "...Okay. Fine.|If you want.",
							gloomy = "Really? ...Okay.",
							shy = "...!|Okay.",
							_ = "Really? Okay.",
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
						shy = "...!|Thanks.|That helps.",
						prickly = "...Thanks. Don't tell anyone I was sulking.",
						gloomy = "Thanks, {player}. I mean it.",
						cool = "...Okay.|Thanks.",
						_ = "Thanks, {player}. You're a good friend.",
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
		local name = food.name:lower()
		local vars = { food = name, Food = name:sub(1, 1):upper() .. name:sub(2) }
		return {
			title = "A craving",
			lines = join(
				line("a", ctx.f("{player}...", {}), "idea"),
				burst(ctx, "a", a, {
					sunny = "I want {food} so much!|Sooo much. Like, right now.",
					bold = "I need {food}. Now.",
					shy = "Um.|I really want some {food}...|sorry.",
					cool = "{Food}.|Want some.",
					prickly = "I want {food}. Don't laugh.",
					dramatic = "If I don't have some {food} today|I'll simply fade away!",
					polite = "Might I trouble you for some {food}?|Only if it's no bother.",
					foodie = "I've been thinking about {food} since breakfast.|Since yesterday's breakfast.",
					nervous = "Is it okay to want {food}?|I really want {food}.",
					easygoing = "You know what would be nice?|{Food}. Just saying.",
					cheeky = "{food}|{food}|{food}",
					_ = "I really want some {food}. Like, really.",
				}, "idea", nil, vars)
			),
			choices = {
				{
					text = ctx.f("My treat ({price} coins)", { price = price }),
					cost = price,
					lines = if loves
						then burst(
							ctx,
							"a",
							a,
							"{Food}! My favourite.|You're the best, {player}.",
							"heart",
							"cheer",
							vars
						)
						else burst(ctx, "a", a, {
							prickly = "...Thanks. You didn't have to.",
							cool = "Thanks.",
							polite = "Thank you so much. That's very kind.",
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
						proud = "Fine. I didn't need it.",
						bold = "Ugh. Fine.",
						cool = "Okay.",
						prickly = "Fine. Whatever.|I'll stop thinking about it. Soon.",
						dramatic = "Then I shall suffer!",
						gloomy = "Yeah. Figured.",
						foodie = "Okay... my tummy is so sad, though.",
						sunny = "Aw. Later then!",
						_ = "Okay... my tummy is sad, though.",
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
				shy = "Um, {player}.|Can I ask you something?|You can say no.|Could I have {cost} coins? For {thing}.",
				proud = "{player}. A small matter. I've had my eye on {thing}.|{cost} coins would do it.",
				cool = "{player}.|{cost} coins.|For {thing}. Can I?",
				nervous = "S-sorry, {player}, can I ask something? Sorry.|Could I have {cost} coins? For {thing}?",
				cheeky = "{player}|hypothetically|if someone wanted {cost} coins for {thing}",
				polite = "Good afternoon, {player}. I hope this isn't rude.|Might I ask for {cost} coins?|I've had my eye on {thing}.",
				_ = "{player}.|Can I ask you something?|Could I have {cost} coins? I've had my eye on {thing}.",
			}, "question", nil, vars),
			choices = {
				{
					text = ctx.f("Here you go ({cost} coins)", vars),
					cost = cost,
					lines = burst(ctx, "a", a, {
						sunny = "Really? Thank you thank you!",
						cool = "Thanks.|Really.",
						prickly = "...Thanks. I'll pay you back.|Somehow.",
						polite = "Thank you. I'm very grateful.",
						shy = "...!|Thank you.",
						_ = "Thank you. I love it already.",
					}, "sparkle", "cheer"),
					effects = { { t = "coins", d = -cost }, { t = "mood", who = "a", d = 12 } },
				},
				{
					text = "Not this time.",
					lines = { voice(ctx, "a", a, "sad", "sad") },
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
					cool = "{player}.|My room's good.|...Really good.",
					prickly = "My room's fine. ...It's great, actually.|Don't let it go to your head.",
					_ = "{player}.|My room has everything. I love it here.",
				}, "heart"),
				effects = { { t = "mood", who = "a", d = 5 } },
				log = ctx.f("{a} loves their room."),
			}
		end
		local tag = ctx.rng:pick(tags)
		local vars = { thing = Catalog.Tags[tag] }
		return {
			title = "A wish",
			lines = join(
				burst(ctx, "a", a, {
					sunny = "{player}! Idea!|Could I have {thing} near my bed?",
					shy = "Um, {player}...|only if it's okay...|could I have {thing} near my bed?",
					bold = "{player}.|I want {thing} by my bed.|Can you sort it?",
					cool = "{player}.|{thing} by my bed?",
					prickly = "My room's missing something. {thing}. By the bed.|If you're not busy.",
					polite = "Good morning, {player}.|Would it be possible to have {thing} near my bed?",
					nervous = "Can I ask for something? Sorry.|Could I have {thing} near my bed?",
					_ = "Hey, {player}.|Do you think I could have {thing} near my bed?",
				}, "idea", nil, vars),
				line(nil, "Put one within a few steps of their bed in Build mode.")
			),
			effects = { { t = "request", who = "a", tag = tag } },
			log = ctx.f("{a} would like {thing} near their bed.", vars),
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
					bold = "Right. Where's my bed, then?",
					proud = "I'll need a bed. A good one.",
					easygoing = "So... where do I nap?",
					sunny = "{player}! Quick question! Where do I sleep?",
					cool = "No bed yet.",
					prickly = "I'm not sleeping on the floor.|Just so you know.",
					dramatic = "I have nowhere to lay my head, {player}!|Nowhere.",
					bookish = "I measured the floor.|It's not long enough for me.",
					gloomy = "Floor again tonight, I guess...",
					polite = "Sorry to ask, {player}.|Is there a bed for me somewhere?",
					foodie = "Where do I sleep?|And where do I keep my snacks?",
					nervous = "Is there a bed? Is it coming?|Where do I go tonight?",
					shy = "Um, {player}...|where do I sleep?",
					cheeky = "found a nice bush to sleep in|kidding|where's my bed",
					_ = "Um. Where do I sleep?",
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
				line("a", ctx.f("{player}. Last night I dreamed about {dream}.", { dream = dream }), "zzz"),
				by(ctx, "a", a, {
					dreamy = "I think it was trying to tell me something.",
					easygoing = "Weird. Anyway.",
					proud = "Even my dreams are interesting.",
					cool = "Weird one.",
					prickly = "Don't analyse it. I can see you analysing it.",
					dramatic = "It felt so real, {player}. So very real!",
					bookish = "Dreams sort out the day's memories, apparently. I had a strange day.",
					gloomy = "Even in my dreams things go wrong...",
					foodie = "I woke up hungry. That's a good sign, I think.",
					nervous = "What does it mean? D-does it mean something bad?",
					cheeky = "it means I should get the day off. obviously",
					_ = "I think it means something. Or I was hungry.",
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
				sunny = "{player}! {player}! Look!|{coins} coins in the grass!",
				cool = "{player}.|{coins} coins. In the grass.",
				cheeky = "finders keepers|...{coins} coins for the town, fine",
				gloomy = "{coins} coins in the grass.|Somebody must have lost them.|...Finders keepers, I suppose.",
				_ = "{player}. Look. {coins} coins in the grass.",
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
				dramatic = "I'm dying, {player}. Tell everyone I said goodbye!",
				prickly = "It's just a cold.|Stop looking at me like that.",
				gloomy = "Of course I caught a cold. Of course.",
				nervous = "Is it a cold? It's a cold.|It's only a cold, right?",
				cool = "Cold.|Great.",
				easygoing = "Achoo. ...Excuse to lie down, at least.",
				sunny = "{player}! I'm fine! Achoo. Mostly fine.",
				_ = "I think I caught a cold.",
			}, "sweat")
		)
		if doctor then
			local name = ctx.v(doctor).name
			table.insert(choices, {
				text = ctx.f("Go and see {doctor}.", { doctor = name }),
				lines = join(
					line(nil, ctx.f("{doctor} had a look and sent {a} off with a hot lemon drink.", { doctor = name })),
					burst(ctx, "a", a, "Tastes awful. ...Feeling better, though.", "sparkle")
				),
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
			text = "Bed. Rest it off.",
			lines = burst(ctx, "a", a, "Okay... Wake me when I'm better, {player}.", "zzz"),
			effects = { { t = "sick", who = "a", minutes = 5 }, { t = "mood", who = "a", d = -2 } },
		})
		if not doctor then
			table.insert(choices, {
				text = "Can you carry on?",
				lines = burst(ctx, "a", a, "Fine. Achoo.|Fine.", "sad"),
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
					easygoing = "Good afternoon, that.",
					proud = "I'm getting very good at it.",
					dreamy = "Is it evening already?",
					shy = "That was nice.",
					cool = "Good afternoon.",
					prickly = "What. It's a perfectly normal thing to do.",
					dramatic = "Hours, {player}! Gone like that!",
					bookish = "I timed it. Four hours.|Felt like one.",
					gloomy = "That was actually fine.",
					polite = "A lovely afternoon. Thank you for asking.",
					foodie = "I've worked up an appetite now.",
					nervous = "Was that a waste of a day?|It didn't feel like it.",
					_ = "Time well spent.",
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
					foodie = "Mmm... more gravy...|on the pancakes...",
					dramatic = "Mmm... the crown...|is mine...",
					bookish = "Mmm... chapter nine...|no, ten...",
					nervous = "Mm... did I lock...|the door...",
					cheeky = "mmm...|hehe...|got you...",
					_ = "Mmm... five more pancakes...",
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
		local w = ctx.job(a)
		local place = w.def.name:lower()
		return {
			title = "Practice",
			lines = join(
				line(nil, ctx.f("{a} stayed late at the {place} to practise.", { place = place })),
				burst(ctx, "a", a, {
					proud = "I was good already. Now I'm better.",
					shy = "I think I'm getting it...",
					cool = "Getting there.",
					prickly = "I'm not staying late for fun.|...Okay. A bit for fun.",
					dramatic = "Practice makes perfect, {player}! Nearly perfect.",
					gloomy = "Still not right. Closer, though.",
					nervous = "One more go. Then one more.|Just to be sure.",
					easygoing = "Okay. That's enough practice. For the week.",
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
				shy = "Um, {player}.|Everyone's got someone to talk to.|Except me...",
				proud = "I don't need friends. ...It'd be nice, though.",
				bold = "Nobody ever asks me along.",
				sunny = "{player}...|I keep saying hi to people.|They say hi back. That's it.",
				cool = "...It's quiet.|That's all.",
				prickly = "I'm fine on my own. ...Mostly.",
				dramatic = "Alone, {player}. In a town full of people!",
				gloomy = "Nobody really talks to me... I get it.",
				polite = "I don't want to bother anyone.|But it's a bit lonely.",
				nervous = "What if nobody likes me here?|What if it's me?",
				_ = "Everyone seems to have friends but me.",
			}, "sad"),
			choices = {
				{
					text = ctx.f("Come and meet {b}."),
					lines = join(
						line("b", ctx.f("Hi {a}. I've been meaning to say hello."), "wave"),
						burst(ctx, "a", a, {
							shy = "Oh.|Hi...",
							prickly = "...Hi. Hello.|Hi.",
							_ = "Oh. Hi.",
						}, "heart")
					),
					effects = { { t = "rel", a = "a", b = "b", d = 12 }, { t = "mood", who = "a", d = 6 } },
				},
				{
					text = "Want some space?",
					lines = burst(ctx, "a", a, "Yeah. Maybe tomorrow.", "sad"),
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
				line(nil, "Everyone gathers round with cake."),
				by(ctx, "a", a, {
					shy = "You all remembered? Oh... thank you.",
					proud = "Of course you remembered. Thank you, though.",
					bold = "Cake. Right. Who's cutting it?",
					easygoing = "Aw. You didn't have to. Is there cake?",
					sunny = "You all remembered! {player}, you too! Best day!",
					cool = "...Thanks. Really.",
					prickly = "You didn't have to do all this. ...Thanks.",
					dramatic = "For me? All of this? I can't. I can! Thank you!",
					bookish = "Three hundred and sixty five days older. I counted.",
					gloomy = "I thought nobody knew... this is really nice.",
					polite = "Thank you all so much. I'm very touched.",
					foodie = "Is that lemon? It's lemon. I can tell from here.",
					nervous = "For me? Is it really for me? Oh. Thank you.",
					cheeky = "a cake? for me? I'm having the first three slices",
					_ = "You all remembered. This is the best.",
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
			lines = { line(nil, "Someone turned the music up. Everyone's dancing.") },
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
				line(nil, "Shooting stars over town. Everyone makes a wish."),
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
			lines = join(
				line(nil, ctx.f("{b} stopped by {a}'s {place}.", { place = place })),
				line("a", ctx.rng:pick(w.job.lines), "music", "wave"),
				burst(ctx, "b", b, {
					shy = "Um.|One of those, please?",
					bold = "One of those. Thanks.",
					proud = "I'll have your best one.",
					cool = "One of those.",
					prickly = "That one.|No, the other one. Yes.",
					dramatic = "I'll take that one! It's calling to me.",
					bookish = "Which is the most popular?|...I'll have that one.",
					gloomy = "Whatever's left. That one's fine.",
					polite = "May I have one of those, please?|Thank you.",
					foodie = "Two of those. No, three.|One's for later. Two are for later.",
					nervous = "Is that one okay?|Is it the right one? Okay. That one.",
					cheeky = "one of those|and a discount|worth a try",
					_ = "I'll take one of those, please.",
				}, "sparkle")
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
		local place = w.def.name:lower()
		local coins = math.floor(w.job.income * Tuning.Jobs.BusyDayShare)
		return {
			title = "A busy day",
			lines = {
				line(nil, ctx.f("Customers keep queueing up at {a}'s counter.", { place = place })),
				by(ctx, "a", a, {
					easygoing = "So many people. I need a sit down after this.",
					shy = "So many people... I'm doing okay, aren't I?",
					proud = "Of course they're queueing. It's me.",
					sunny = "{player}! Look at the queue! Look at it!",
					cool = "Busy one.",
					prickly = "One at a time. ONE at a time.",
					dramatic = "The whole island is here!",
					bookish = "Sixty customers before noon. Sixty one, actually.",
					gloomy = "Busy... something must be wrong with the other shops.",
					polite = "Thank you all for your patience. Next, please.",
					foodie = "I haven't had a second to eat. Not one second.",
					nervous = "So many. Am I being quick enough? Am I?",
					cheeky = "queue's past the fountain. I'm famous now",
					_ = "I've never been this busy. I love it.",
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
				line("a", ctx.f("{player}? Got a minute?", {}), "sweat"),
				burst(ctx, "a", a, {
					proud = "I'd like the rest of the day off.|I've earned it.",
					shy = "Um.|Could I maybe go home early?|Sorry...",
					cool = "I need the afternoon.|That okay?",
					prickly = "I need a break.|Don't make it a whole thing.",
					dramatic = "I'm exhausted.|Utterly. Spent.",
					gloomy = "I'm worn out.|I'd be no use to anyone today.",
					polite = "Would it be all right|if I finished early today?",
					foodie = "I can't think.|I need a nap and a very big lunch.",
					nervous = "Is it okay to ask for the day off?|Is it too much?",
					easygoing = "*yawn*|So. Hypothetically. The afternoon off.",
					_ = "Could I take the rest of today off?|I'm worn out.",
				}, "sweat")
			),
			choices = {
				{
					text = "Go and rest.",
					lines = burst(ctx, "a", a, {
						easygoing = "Thank you. Hammock, here I come.",
						prickly = "...Thanks. I'll be back tomorrow. Early.",
						polite = "Thank you so much.|I'll make it up to you.",
						shy = "...!|Thank you.",
						_ = "Thank you. Hammock, here I come.",
					}, "heart", "cheer"),
					effects = { { t = "dayoff", who = "a" }, { t = "mood", who = "a", d = 10 } },
				},
				{
					text = "We need you today.",
					lines = burst(ctx, "a", a, "Okay... back to it.", "sad"),
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
					proud = "I'd like a job. A good one, ideally.",
					bold = "Give me a job. Any job.",
					shy = "Um.|Is there any work going?|I don't mind what...",
					sunny = "{player}!|Is there anything I could do?|Anything at all!",
					cool = "Got any work?",
					prickly = "I'm bored.|Find me something to do. Please.",
					dramatic = "I need a purpose, {player}. A PURPOSE!",
					bookish = "I've been reading about jobs.|I'd like to try one. Any of them.",
					gloomy = "Nobody needs me for anything... Is there work?",
					polite = "If there's any work going|I'd be glad of it.",
					foodie = "Is there a job with snacks?|Any job is fine. Snacks would be nice.",
					nervous = "Is there a job for me?|Would I be any good at it?",
					easygoing = "I suppose I should get a job.|Eventually. Today, maybe.",
					_ = "I'd love a job. Anything, really.",
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
				sunny = "{player}! Sit, sit!|You've been running round all day.",
				gentle = "{player}, come and sit a minute.|Have you eaten today? Properly, I mean.",
				bold = "{player}.|Sit down. You look done in.",
				dreamy = "There's room on the bench.|The sun's nice here.",
				easygoing = "Sit. Seriously.|The town won't fall over in five minutes.",
				proud = "Even I take breaks, {player}. Sit.",
				shy = "Um. {player}?|Do you want to sit?|Only if you want.",
				cheeky = "you've been building so much|I thought you'd turned into a hammer",
				cool = "{player}.|Sit for a bit?",
				prickly = "You look tired.|Not that I was watching. Sit down.",
				dramatic = "You'll wear yourself out, {player}. REST!",
				bookish = "People work better after a short rest.|It's well known, actually.",
				gloomy = "You'll burn out like that.|Sit with me. It's fine.",
				polite = "Good afternoon, {player}.|Would you care to join me for a moment?",
				foodie = "Sit. I've got half a sandwich.|It's the good half.",
				nervous = "Are you okay? You look tired.|Are you okay?",
				_ = "Come and sit a minute, {player}.",
			}, "heart", "wave")
		do
			table.insert(s.lines, l)
		end
		s:choice("Budge up.", function(c)
			c:n("You sat on the bench with {a} for a while and watched the pigeons.")
			c:by("a", {
				cool = "...Good, right?",
				prickly = "See? Not so hard. ...I liked that.",
				gloomy = "That was nice. Come back tomorrow?",
				gentle = "There. Better. Go gently today.",
				_ = "Better? Good.",
			}, "heart")
			c:hearts("a", 1)
			c:mood("a", 5)
			c:memo("a", "We sat by the fountain, remember, {player}? Do that more.")
		end)
		s:choice("Can't. Too busy.", function(c)
			c:by("a", {
				prickly = "Fine. Don't say I didn't tell you.",
				nervous = "Okay. Just... don't forget to rest. Okay?",
				sunny = "Aw. Later then!",
				gentle = "All right. I'll bring you soup later, though.",
				_ = "Okay. Don't forget to stop sometime.",
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
		s:n("It's dark on the path. A lantern comes bobbing up behind you. It's {a}.")
		for _, l in
			burst(ctx, "a", a, {
				sunny = "{player}! It's pitch black!|You'll fall in a ditch. I'll walk you!",
				gentle = "It's dark tonight.|Let me light the way for you.",
				bold = "You'll trip. Walk with me.",
				dreamy = "The moon's hiding.|Share my light?",
				cool = "Dark out.|I'll walk you.",
				prickly = "I was going this way anyway.|Don't read into it.",
				dramatic = "Through the darkness I bring LIGHT!",
				gloomy = "There's a hole by the gate.|I fell in it once. Walk with me.",
				polite = "Good evening, {player}.|May I walk with you? It's very dark tonight.",
				foodie = "Going to the bakery's back door for yesterday's buns.|Same way as you.",
				nervous = "It's so dark. Can I walk with you?|For both of us?",
				_ = "It's dark. I'll walk you back.",
			}, "idea")
		do
			table.insert(s.lines, l)
		end
		s:choice("Thanks. Lead the way.", function(c)
			c:n("You walked back under {a}'s lantern. Neither of you fell in the ditch.")
			c:hearts("a", 1)
			c:mood("a", 4)
		end)
		s:choice("I know the way.", function(c)
			c:by("a", {
				prickly = "Fine. Don't come crying to me with a muddy knee.",
				nervous = "Okay. Be careful. Really careful.",
				cool = "Okay. Night.",
				_ = "Okay. Night, {player}. Watch the ditch.",
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
		s:n("{a} is writing a letter to a friend on another island. The pen has stopped.")
		for _, l in
			burst(ctx, "a", a, {
				sunny = "{player}! Help!|I want to say the sea looked...|ugh, what's the word?",
				dreamy = "{player}.|The sea this morning.|It looked... it looked...",
				cool = "{player}.|The sea looked...|what?",
				prickly = "{player}.|One word. I need one word. Don't laugh.",
				dramatic = "{player}. How do I describe the sea?|Words fail me!",
				bookish = "{player}, help me. I've crossed out six words already.|None of them were right.",
				gloomy = "{player}.|I want to say the sea looked something.|Not sad, for once.",
				polite = "Forgive me, {player}.|Might you help? I can't think how to describe the sea.",
				foodie = "{player}. The sea looked like...|soup. No. Not soup. Something.",
				nervous = "{player}, help.|What if I pick the wrong word|and they think it's weird?",
				_ = "{player}. Help me.|I want to say the sea looked...|what's the word?",
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
					prickly = "{Word}. ...Yes. Fine. That's it. Thanks.",
					gloomy = "{Word}. Huh. Yes, that's right.",
					bookish = "{Word}. Oh, that's exactly it. Simple is best.",
					cool = "{Word}. ...Yes.",
					_ = "{Word}. Yes. That's it exactly.",
				}, "idea", "cheer")
				c:mood("a", 4)
				c:memo("a", "I told my friend the sea looked {word}. They wrote back saying they could see it.")
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
