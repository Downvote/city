--!strict
-- What a villager says to somebody who isn't their mayor. The user: "Create dialogue for villagers
-- interacting with players that arent their mayor." A visitor who holds E on one of another
-- player's villagers (or walks past one who is free) is talked to as a guest: by their own name,
-- never "the" before it, in the villager's own voice (Sim/Voice, with their ending on some). They
-- say hello, talk about their mayor ("the {player}", who is always the town's owner and never the
-- visitor), about the town, and a little about the visitor and their own town. A visitor gets the
-- words alone: no hearts, no mood, nothing for the owner to answer. Past Tuning.Guests.ChatsPerDay
-- talks in one town a day the villagers have things to do (`busy`).
--
-- The blanks: {name} the visitor, "the {player}" (or "The {player}") the villagers' mayor, {town}
-- the town's own name and {home} the visitor's town's name; a line with {town} or {home} is only
-- said when that town has a name. No services: Services/Villagers says these (Villagers.talk, the
-- greeting in Services/Social), tests/specs/GuestTalk.spec.luau holds them.

local Text = require(script.Parent.Parent.Util.Text)
local Voice = require(script.Parent.Voice)

local GuestTalk = {}

-- The kinds of line, as a visitor meets them: walked up to (hello), passed by (passing), then
-- small talk about their mayor, the town and the visitor, and the brush off past the day's cap.
GuestTalk.Kinds = { "hello", "passing", "mayor", "town", "you", "busy" }

type Lines = { [string]: { [string]: { string } } }

local LINES: Lines = {
	sunny = {
		hello = {
			"Oh, hi, {name}, welcome! Ehehe, we don't get many visitors.",
			"{name}! You came all this way to see us? That's the best!",
		},
		passing = { "Hi, {name}, enjoy your visit!" },
		mayor = {
			"The {player} planted every flower out front, and I helped water them!",
			"Ehehe, the {player} lets me pick the music at parties.",
		},
		town = {
			"The fountain's my favourite spot, so go and see it at night.",
			"{town} has the best sunsets, so stay till evening!",
		},
		you = {
			"Do you have a town of your own, {name}? I bet it's lovely.",
			"So you're from {home}? I'd love to visit sometime!",
		},
		busy = { "I'd love to keep chatting, but I promised to help with something." },
	},
	gentle = {
		hello = {
			"Oh my, a visitor, so welcome, {name}, and make yourself at home.",
			"Hello, {name}, did you find your way here alright?",
		},
		passing = { "Oh, hello, {name}, mind the step there." },
		mayor = {
			"The {player} looks after us all so well, you know.",
			"If you see the {player}, tell them I saved them some soup.",
		},
		town = {
			"It's a quiet little place, but we're happy here.",
			"Welcome to {town}, it's small but it's home.",
		},
		you = {
			"Have you eaten today, {name}? You look like you've walked a long way.",
			"{home} sounds lovely, is it far from here?",
		},
		busy = { "I should get back to my chores now, but do come by again." },
	},
	bold = {
		hello = {
			"Hey, {name}, visiting? Good, have a proper look around.",
			"{name}, right? Walk with me and I'll show you the best spot.",
		},
		passing = { "Hey, {name}, don't get lost out here." },
		mayor = {
			"The {player} built half of this by hand, and I built the other half.",
			"Hah, the {player} never backs down from a big project, and neither do I.",
		},
		town = {
			"This street used to be empty, and now look at it.",
			"{town} is the best town around, and I'll race anyone who says it isn't.",
		},
		you = {
			"You build too, {name}? I bet your town isn't as tidy as ours.",
			"{home}, huh? I'll come and check it out myself, right?",
		},
		busy = { "I've got work to do, so catch you later." },
	},
	dreamy = {
		hello = {
			"Oh... hello, {name}, I didn't hear you walk up.",
			"{name}, did the wind bring you here? It does that sometimes.",
		},
		passing = { "Hello, {name}... the clouds are nice today." },
		mayor = {
			"The {player} hums when they think nobody's listening, I've heard them.",
			"Sometimes the {player} and I just watch the sky for a while.",
		},
		town = {
			"At night the lamps here look like little moons.",
			"I like saying {town} out loud, it sounds like a song.",
		},
		you = {
			"What's it like where you live, {name}? Are the clouds the same there?",
			"{home}... I think I dreamed about a place called that once.",
		},
		busy = { "Oh, I was on my way somewhere, I think, so bye for now, {name}." },
	},
	easygoing = {
		hello = {
			"Hey, {name}, welcome, and take it easy while you're here.",
			"*yawn* Oh, hi, {name}, you caught me resting.",
		},
		passing = { "Hey, {name}, no rush, look around all you like." },
		mayor = {
			"The {player} works hard enough for both of us, so I mostly nap.",
			"The {player} doesn't mind long lunches, which suits me fine.",
		},
		town = {
			"The best bench in town is by the fountain, trust me.",
			"{town} is a good place to slow down for a bit.",
		},
		you = {
			"Visiting lots of towns today, {name}? That sounds tiring.",
			"{home}, huh? Do they have good benches there?",
		},
		busy = { "I'd chat more, but there's a nap with my name on it." },
	},
	proud = {
		hello = {
			"Ah, {name}, you've come to see the finest town around, naturally.",
			"Hmph, a visitor, so word about us is getting out.",
		},
		passing = { "Good day, {name}, do admire the garden on your way." },
		mayor = {
			"The {player} has excellent taste, which is why they listen to me.",
			"The {player} asks what I think of every new building, naturally.",
		},
		town = {
			"Every house on this street was my idea, more or less.",
			"{town} is the envy of the whole island, I'm told.",
		},
		you = {
			"Do you build too, {name}? I could give you a few tips.",
			"{home}? I'm sure it's nice, but it's no match for here.",
		},
		busy = { "I'm a busy person, {name}, but you may visit again." },
	},
	shy = {
		hello = {
			"Um, hi, {name}, are you visiting? (we don't get many visitors)",
			"Oh, um, hello, I didn't know anyone was coming today.",
		},
		passing = { "Um, hi, {name}." },
		mayor = {
			"The {player} is really kind to me, um, I just wanted someone to know.",
			"The {player} says hi to me every morning (it's my favourite part of the day).",
		},
		town = {
			"Um, the little garden round the back is the quietest spot, if you like quiet.",
			"I like living in {town}, um, everyone's nice here.",
		},
		you = {
			"Do you have villagers too, {name}? I bet they like you.",
			"{home} sounds nice, um, is it a big town?",
		},
		busy = { "Sorry, um, I have to go now, but it was nice to meet you." },
	},
	cheeky = {
		hello = {
			"Oh, a visitor! Don't touch the fountain, {name}, it bites, hehe.",
			"{name}, if you're looking for the snacks, I didn't take them :P",
		},
		passing = { "Psst, {name}, the {player} hid cookies somewhere round here, hehe." },
		mayor = {
			"Don't tell the {player}, but I move their favourite chair a little every day.",
			"The {player} still thinks the noise at night is the wind, hehe.",
		},
		town = {
			"The best prank spot in town is behind the big tree, but you didn't hear it from me.",
			"Welcome to {town}, the snacks are free if nobody's looking :P",
		},
		you = {
			"{name}, is your town as fun as ours? I doubt it, hehe.",
			"{home}? Sounds like a place I should go and cause trouble in :P",
		},
		busy = { "Gotta go, {name}, a prank won't set itself up." },
	},
	cool = {
		hello = {
			"Hey, {name}, welcome to the town.",
			"Hm, a visitor, so take a look around if you like.",
		},
		passing = { "Hey, {name}." },
		mayor = {
			"The {player} knows what they're doing, which is rare.",
			"The {player} leaves me to my work, and I like that.",
		},
		town = {
			"It's quiet here at night, which is good for thinking.",
			"{town} is alright, better than most.",
		},
		you = {
			"You run a town too, {name}? Hm, respect.",
			"I've heard of {home}, people say it's alright.",
		},
		busy = { "I've got things to do, so see you, {name}." },
	},
	prickly = {
		hello = {
			"Tsk, another visitor, so don't step on the flowers, {name}.",
			"Ugh, fine, hello, {name}, what do you want?",
		},
		passing = { "Watch where you're walking, {name}." },
		mayor = {
			"The {player} never listens to my complaints, but they fix things anyway.",
			"Tsk, the {player} put a bench right where I like to stand.",
		},
		town = {
			"The town's fine, I suppose, if you ignore the noise.",
			"{town} would be perfect if people stopped visiting, no offence.",
		},
		you = {
			"You've got a town of your own, {name}? Then why are you in ours?",
			"{home}, is it? I've never heard of it.",
		},
		busy = { "Ugh, I'm busy, so go and bother someone else." },
	},
	dramatic = {
		hello = {
			"*gasp* A visitor! {name}, you've made my whole WEEK.",
			"{name}! At last, someone new to tell my stories to.",
		},
		passing = { "{name}! Don't leave without saying goodbye, I couldn't bear it." },
		mayor = {
			"The {player} saved this town, and I'll write a song about it one day.",
			"Without the {player} we'd all be living in a field, can you imagine?",
		},
		town = {
			"This street has seen storms, parties and one very bad haircut.",
			"{town} is the most beautiful place in the WORLD, and I've seen two places.",
		},
		you = {
			"{name}, tell me everything about your town and leave nothing out.",
			"{home}? I've heard such stories about it!",
		},
		busy = { "I must go, {name}, my public is waiting." },
	},
	bookish = {
		hello = {
			"Oh, hello, {name}, visitors are actually quite rare here.",
			"Welcome, {name}, I can tell you how every building here went up, if you like.",
		},
		passing = { "Hello, {name}, enjoy the walk." },
		mayor = {
			"The {player} actually reads every note I leave on their door.",
			"The {player} planned the streets on paper first, which I approve of.",
		},
		town = {
			"Actually, this town is older than it looks (the first house went up long before the fountain).",
			"{town} is a good name, actually, I looked into it.",
		},
		you = {
			"Do you keep notes on your own town, {name}? You really should.",
			"Actually, I've read a little about {home}.",
		},
		busy = { "Sorry, {name}, I'm in the middle of a chapter." },
	},
	gloomy = {
		hello = {
			"Oh... a visitor, hello, {name}.",
			"Heh... you picked a quiet day to visit, {name}.",
		},
		passing = { "Hello, {name}, mind the puddles." },
		mayor = {
			"The {player} tries to cheer me up, and sometimes it works.",
			"Heh... the {player} is the only one who laughs at my jokes.",
		},
		town = {
			"It's a nice town, I suppose, until it rains, as usual.",
			"{town} grows on you after a while, like moss.",
		},
		you = {
			"Do you have a town, {name}? I hope it rains there less than here.",
			"{home}... I bet it's sunnier than here.",
		},
		busy = { "I should go and sit somewhere quiet now." },
	},
	polite = {
		hello = {
			"Good day, {name}, and welcome to our town.",
			"Hello, {name}, it is very kind of you to visit us.",
		},
		passing = { "Good day, {name}, I hope you enjoy your visit." },
		mayor = {
			"The {player} has been very good to all of us, and I am grateful.",
			"The {player} always asks how I am, which is very kind.",
		},
		town = {
			"Please do sit on any bench you like, they are for everyone.",
			"Welcome to {town}, I hope you will come again.",
		},
		you = {
			"May I ask, {name}, do you have a town of your own?",
			"{home} must be a lovely place, if you are from there.",
		},
		busy = { "Please excuse me, {name}, I have something I must do." },
	},
	foodie = {
		hello = {
			"Mmm, hello, {name}, you're just in time for snacks.",
			"A visitor! Have you tried the bread here yet, {name}?",
		},
		passing = { "Hi, {name}, the bakery smells amazing today." },
		mayor = {
			"The {player} always saves me the last slice of pie, mmm.",
			"When the {player} throws a party, the food is always great.",
		},
		town = {
			"This town makes the best soup on the island, and I'd know.",
			"{town} feels like warm bread on a cold day, if that makes sense.",
		},
		you = {
			"What's the best food in your town, {name}? I need to know.",
			"{home}, mmm, do they make good pies there?",
		},
		busy = { "Sorry, {name}, something's in the oven and I can't let it burn." },
	},
	nervous = {
		hello = {
			"Oh! A visitor, um, hello, {name}, and welcome.",
			"Hi, {name}, sorry if it's messy, we didn't know you were coming.",
		},
		passing = { "Oh, hi, {name}, careful, the path's uneven there." },
		mayor = {
			"The {player} says I worry too much, but someone has to.",
			"Oh no, does the {player} mind visitors? I never asked.",
		},
		town = {
			"It's a safe town, I think, because I check the locks every night.",
			"{town} is lovely, as long as nothing catches fire.",
		},
		you = {
			"Is your town far, {name}? What if you get lost going back?",
			"{home}? Is it safe there? It sounds safe.",
		},
		busy = { "Sorry, I have to go, I think I left the tap on." },
	},
}

GuestTalk.Lines = LINES

-- What a line needs to be said: the visitor's name, the town's and the visitor's town's names.
export type Ctx = {
	name: string, -- the visitor's display name
	town: string?, -- this town's own name, "" or nil without one
	home: string?, -- the visitor's town's name, "" or nil without one
}

-- The lines of one kind a personality may say to this visitor (those needing a name that isn't
-- there left out).
function GuestTalk.pool(pers: string, kind: string, ctx: Ctx): { string }
	local own = LINES[pers] or LINES.sunny
	local out = {}
	local lines: { string } = own[kind] or {}
	for _, text in lines do
		local needTown = text:find("{town}", 1, true) ~= nil
		local needHome = text:find("{home}", 1, true) ~= nil
		if (not needTown or (ctx.town or "") ~= "") and (not needHome or (ctx.home or "") ~= "") then
			table.insert(out, text)
		end
	end
	return out
end

-- A line with its blanks filled: the mayor is "the Mayor" (Text.playerName), the visitor goes by
-- their own name, and a line opening with a name starts with a capital.
function GuestTalk.fill(profile: any, text: string, ctx: Ctx): string
	local mayor = Text.playerName(profile)
	text = string.gsub(text, "The {player}", "The " .. mayor)
	text = string.gsub(text, "the {player}", "the " .. mayor)
	local who = if ctx.name ~= "" then ctx.name else "friend"
	local out = Text.fill(text, { name = who, town = ctx.town or "", home = ctx.home or "" })
	return (out:sub(1, 1):upper() .. out:sub(2))
end

-- A villager's line to a visitor. `first`: they were just walked up to (a hello); otherwise small
-- talk. `last` is what they said last, so it isn't said twice running. In their own hand (Voice.as).
function GuestTalk.line(profile: any, vid: string, rng: any, ctx: Ctx, first: boolean?, last: string?): string
	local v = profile.villagers and profile.villagers[vid]
	if not v then
		return "..."
	end
	local pool: { string } = {}
	if first then
		pool = GuestTalk.pool(v.pers, "hello", ctx)
	else
		for _, kind in { "mayor", "town", "you", "hello" } do
			for _, text in GuestTalk.pool(v.pers, kind, ctx) do
				-- (a hello once in a while, the rest twice as likely)
				table.insert(pool, text)
				if kind ~= "hello" then
					table.insert(pool, text)
				end
			end
		end
	end
	local said = function(text: string): string
		return Voice.as(v, GuestTalk.fill(profile, text, ctx))
	end
	if last then
		local fresh = {}
		for _, text in pool do
			if said(text) ~= last then
				table.insert(fresh, text)
			end
		end
		if #fresh > 0 then
			pool = fresh
		end
	end
	if #pool == 0 then
		return said("Hello, {name}.")
	end
	return said(rng:pick(pool))
end

-- A short hello to a visitor walking by, or nil.
function GuestTalk.passing(profile: any, vid: string, rng: any, ctx: Ctx): string?
	local v = profile.villagers and profile.villagers[vid]
	if not v then
		return nil
	end
	local pool = GuestTalk.pool(v.pers, "passing", ctx)
	if #pool == 0 then
		return nil
	end
	return Voice.as(v, GuestTalk.fill(profile, rng:pick(pool), ctx))
end

-- What they say past the day's cap, walking on.
function GuestTalk.busy(profile: any, vid: string, ctx: Ctx): string
	local v = profile.villagers and profile.villagers[vid]
	if not v then
		return "..."
	end
	local pool = GuestTalk.pool(v.pers, "busy", ctx)
	return Voice.as(v, GuestTalk.fill(profile, pool[1] or "Sorry, {name}, I have to go.", ctx))
end

-- The day's cap: one more talk for this visitor in this town on town day `day`? `book` is the
-- server's own table (Services/Villagers), keyed by "<visitor id>:<owner id>". Counts it if so.
function GuestTalk.take(book: { [string]: { day: number, n: number } }, key: string, day: number, most: number): boolean
	local found = book[key]
	local e: { day: number, n: number } = if found and found.day == day then found else { day = day, n = 0 }
	book[key] = e
	if e.n >= most then
		return false
	end
	e.n += 1
	return true
end

return GuestTalk
