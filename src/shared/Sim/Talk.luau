--!strict
-- Talking to a villager. The user: "allow the option to interact/chat with villagers by holding
-- e on them". Pure data in and out so the specs can run it; Services/Villagers puts the prompt on
-- every villager and answers it, UI/TalkCard is the card the owner sees.
--   lines   what they say back: a greeting in their own voice when you walk up (or what they
--           are wishing for, if anything), then small talk about how they feel, their work,
--           their hobby and the people they live with. Since the user asked for "much much more
--           random events ... conversations": what they got up to in their last event (its memo,
--           while it's fresh), what they think of a neighbour (by how they get on, and what that
--           neighbour is like), a worry, a joke, the season and the weather.
--   chats   the little good a chat does. In your own town the first few chats a day with a
--           villager lift their mood a touch and fill their hearts by a point (Sim/Life); after
--           that they still answer and nothing is gained. A chat is also the answer to a wish
--           for one. Somebody visiting gets the line and nothing else.

local Tuning = require(script.Parent.Parent.Config.Tuning)
local Personalities = require(script.Parent.Parent.Data.Personalities)
local Sayings = require(script.Parent.Parent.Data.Sayings)
local Foods = require(script.Parent.Parent.Data.Foods)
local Text = require(script.Parent.Parent.Util.Text)
local City = require(script.Parent.City)
local Life = require(script.Parent.Life)
local Relationships = require(script.Parent.Relationships)

local K = Tuning.Talk

local Talk = {}

export type Chat = {
	counted: boolean, -- one of the day's few that count
	hearts: number, -- heart points it gave
	mood: number, -- mood it gave
	left: number, -- how many more will count today
	wish: boolean, -- it answered their wish for a talk
	coins: number, -- what they gave you for that
}

-- What to say back -----------------------------------------------------------------------------------

-- Can a villager be stopped for a talk? `mode` is what Services/Villagers has them doing: nil
-- is their own day, "chat" a word with a neighbour and "talk" a talk already going on. An
-- event's scene ("event") and an outing ("away") are not interrupted.
function Talk.free(mode: string?): boolean
	return mode == nil or mode == "chat" or mode == "talk"
end

-- What the lines below are keyed by: a villager's personality (Data/Personalities), with "_" for
-- anybody else. The user: "for the humanization, make sure to take note of the personalities of the
-- villagers as well", so a shy villager and a loud one don't say the same thing the same way.
local function own(map: { [string]: string }, pers: string?): string
	return (pers and map[pers]) or map._
end

-- After a talk that answered their wish for one.
local THANKS = {
	_ = "Thanks. I feel better already.",
	sunny = "Oh, thank you, I really needed that. I feel loads better.",
	gentle = "Thank you for stopping, dear. I feel much better.",
	bold = "Yeah. Okay. That helped. Thanks.",
	dreamy = "Oh... the fog's gone a bit. Thank you.",
	easygoing = "Thanks. Needed that.",
	proud = "I was perfectly fine. But... thank you.",
	shy = "Thanks for talking to me. I feel better. Um, a lot better.",
	cheeky = "Right, I'm cheered up. Don't tell anyone it was you.",
}

-- No bed yet.
local NOBED = {
	_ = "I still don't have a bed, you know.",
	gentle = "I don't like to be a bother, but I still haven't got a bed.",
	bold = "Still no bed. I'm sleeping on the floor. Sort it out.",
	dreamy = "I still don't have a bed. I just sleep wherever I end up.",
	easygoing = "No bed yet. Floor's fine. A bed'd be better.",
	proud = "I'm still without a bed. I don't complain, but honestly.",
	shy = "Um. I don't have a bed yet. It's okay. The floor's okay.",
	cheeky = "Still no bed, you know. I might just move into yours.",
}

-- A quarrel that hasn't blown over.
local QUARREL = {
	_ = "{y} and I aren't speaking right now.",
	gentle = "{y} and I have had words. I hope it blows over soon.",
	bold = "Don't talk to me about {y}. We're not speaking.",
	dreamy = "{y} and I aren't speaking. I can't remember why. We just aren't.",
	easygoing = "Me and {y} aren't talking. It'll blow over.",
	proud = "I'm not speaking to {y}. They know what they did.",
	shy = "{y} and I had a falling out. I feel awful about it.",
	cheeky = "{y} and I are having a fight. I'm winning.",
}

-- Their best friend, the one at the top.
local FRIEND = {
	_ = "{y} always makes me laugh.",
	gentle = "{y} came round with soup when I had a cold. They're good like that.",
	bold = "{y}'s all right. Better than all right.",
	dreamy = "{y} gets my thoughts. Even the odd ones.",
	easygoing = "Me and {y} sat on the pier all afternoon. Good times.",
	proud = "{y} is nearly as good company as me.",
	shy = "{y} talks to me a lot. I like that.",
	cheeky = "{y} laughs at all my jokes. Even the bad ones.",
}

-- Small talk anybody might make on an ordinary day.
local SMALL = {
	"What are you building next?",
	"Nothing much going on today. I like it that way.",
	"I went for a walk round town earlier.",
	"It's a nice spot, this.",
	"Have you tried the bench by the fountain? It's comfier than it looks.",
	"Somebody on a boat waved at me this morning. No idea who.",
	"I keep meaning to tidy my room.",
}

-- Small talk of their own, by personality.
local OWN = {
	sunny = {
		"I've said hello to about twenty people today and it's not even lunch.",
		"Did you see the new flowers by the hall? Someone's been busy, I want to find out who.",
		"We should all have lunch together one day, the whole town, on the square.",
	},
	gentle = {
		"Your collar's turned up at the back. There. That's better.",
		"I left some bread out for the ducks. Don't tell anyone, they'll say I spoil them.",
		"Are you sleeping all right? You can tell me.",
	},
	bold = {
		"Race you to the pier. No? Fine.",
		"I fixed the gate by the square. Kicked it. It works now.",
		"Need anything carried? I'm bored.",
	},
	dreamy = {
		"The water in the fountain goes round and round. I wonder if it gets dizzy.",
		"I followed a cat round the square this morning. It seemed to know where it was going.",
		"Have you ever noticed the town sounds different after it rains?",
	},
	easygoing = {
		"Found a good spot for a nap. Not telling you where.",
		"Not much to report. Which is how I like it.",
		"Eh. Same as yesterday. Good, though.",
	},
	proud = {
		"My window boxes are the best on the street. Ask anyone.",
		"I've been told I have very good posture. Twice this week.",
		"I could run this town, you know. Not that you're doing badly.",
	},
	shy = {
		"I found a nice quiet spot by the water. Nobody goes there.",
		"Um. I like your hat.",
		"I tried to say hello to someone new today. I waved, sort of.",
	},
	cheeky = {
		"Have you noticed the fountain's a bit... fizzier today? No reason.",
		"Somebody turned all the benches round to face the wall. No idea who.",
		"I know who keeps putting buttons in the fountain. My lips are sealed. For now.",
	},
}

local JOKES = {
	"Why did the gull sit on the bun? To keep it warm. Then it ate it.",
	"I told the fountain a joke. It didn't laugh, but it gave me a wet look.",
	"What do you call a sleepy crab? A crab nap.",
	"My plant and I had a fight. It's still not talking to me. Never was, really.",
	"Why don't clouds wear shoes? They'd only lose them in the rain.",
	"I bought a book about boats. Can't put it down. It's very heavy.",
	"What's a pancake's favourite day? Flip day.",
	"I asked the baker for a joke. He said, 'Here's one, it's a bit crusty.'",
}

-- What they think of a neighbour, by how well they get on.
local OPINION = {
	{
		min = 60,
		lines = {
			"{y} is my favourite person. Don't tell the others.",
			"If {y} asked me to carry a piano, I'd ask where to.",
		},
	},
	{
		min = 30,
		lines = { "{y} lent me a ladder last week. Good sort.", "I had tea round at {y}'s yesterday. Lovely place." },
	},
	{
		min = 10,
		lines = { "I don't know {y} that well yet. They wave a lot.", "{y} seems nice. We should talk more." },
	},
	{ min = -10, lines = { "Who's {y} again? Oh, the one with the hat.", "I haven't really met {y}. Should I?" } },
	{
		min = -40,
		lines = { "{y} and I don't really get on.", "{y} borrowed my rake and gave it back muddy. Just saying." },
	},
	{ min = -101, lines = { "Don't mention {y}. Please.", "I'd rather not talk about {y}, if that's all right." } },
}

-- What a neighbour is like, by their personality.
local LIKE = {
	sunny = "{y} is always so cheerful. How do they do it?",
	gentle = "{y} dropped a cake round last week. No reason, just because.",
	bold = "{y} challenged me to a race. I said no. They raced anyway.",
	dreamy = "{y} told me the moon is a big pebble. I've been thinking about it all day.",
	easygoing = "I've never seen {y} hurry. Not once.",
	proud = "{y} checks their hair in every window they walk past.",
	shy = "{y} said hello to me today. All on their own.",
	cheeky = "{y} put a frog in my bucket. I think it was a present.",
}

-- A best friend, as close as two villagers get (there is no romance: the user, "remove any
-- romance, just best friends is the highest"). In the speaker's own way.
local BEST = {
	_ = "{y} and I are best friends. We've got a handshake and everything.",
	sunny = "{y} is my best friend, did I tell you? We do everything together.",
	gentle = "{y} is my best friend. I don't know what I'd do without them.",
	bold = "{y}'s my best friend. Anyone got a problem with that, they come to me.",
	dreamy = "{y} is my best friend. I think we knew each other before, somehow.",
	easygoing = "Me and {y}? Best friends. Easy.",
	proud = "{y} is my best friend. They're very lucky.",
	shy = "{y} is my best friend. I've never had one before.",
	cheeky = "{y} is my best friend. We've got a secret handshake. It takes four minutes.",
}
local LEVELS = Tuning.Relationships.Levels
local BEST_FRIENDS = LEVELS[#LEVELS].Min

local SEASON = {
	"Have you seen the daffodils by the hall? They're out already.",
	"Too hot for socks today.",
	"I love this time of year. Everything's crunchy.",
	"My nose has been cold since Tuesday.",
}

local WEATHER = {
	rain = "Good day for staying in with a book.",
	storm = "Did you hear that thunder? I hid under the table.",
	snow = "Have you been out in the snow yet? Go on.",
	blossom = "There are petals in my hair. Leave them.",
	leaves = "I've swept my step three times today.",
	clear = "Not a cloud. I'm making the most of it.",
	cloudy = "Grey again. I don't mind grey.",
}

-- A craving, in their own words ({food} is the food's name, so it starts a sentence).
local CRAVE = {
	_ = "I keep thinking about food. {food}, to be exact.",
	sunny = "Okay, don't laugh, but all I can think about today is food. {food}, mostly.",
	gentle = "I don't like to ask. {food} would be lovely, though.",
	bold = "{food}. I want some. Now, ideally.",
	dreamy = "I dreamed about food last night. {food}, I think. I can still smell it.",
	easygoing = "{food}. Man. Could really go for that.",
	proud = "I have a craving, if you must know. {food}. A good one.",
	shy = "Um. {food}... I've been wanting some. If it's no trouble.",
	cheeky = "I'll stop bothering you if you do one thing for me. {food}. Deal?",
}

-- Someone they'd like to meet.
local MEET = {
	_ = "I'd like to get to know {y}. Could you introduce us?",
	sunny = "I really want to be friends with {y}. Could you introduce us? Please?",
	gentle = "I'd like to get to know {y} better. Would you introduce us?",
	bold = "Introduce me to {y}. I'd do it myself, but they keep walking off.",
	dreamy = "I keep seeing {y} around. I think we'd get on. Could you introduce us?",
	easygoing = "{y} seems cool. Introduce us sometime?",
	proud = "{y} seems worth knowing. You could introduce us.",
	shy = "I'd like to talk to {y}. I don't know how to start. Could you help?",
	cheeky = "Who's {y}? They look fun. Introduce me?",
}

-- Their last event, as they'd tell it, while it's still fresh.
function Talk.memo(v: any, now: number?): string?
	local m = v and v.memo
	if type(m) ~= "table" or type(m.text) ~= "string" or type(m.t) ~= "number" or not now then
		return nil
	end
	local fresh = Tuning.Events.MemoHours * Tuning.Day.Length / 24
	if now - m.t > fresh or now < m.t then
		return nil
	end
	return m.text
end

-- A villager's wish in their own words, or nil when they have none to tell. (A wish for a talk
-- isn't told: the talk answers it.)
function Talk.wishLine(profile: any, vid: string): string?
	local v = profile.villagers[vid]
	local w = v and v.wish
	if not w then
		return nil
	end
	if w.kind == "food" then
		local food = Foods.get(w.arg)
		if food then
			return Text.fill(own(CRAVE, v.pers), { food = food.name })
		end
		return "I keep thinking about food."
	elseif w.kind == "friend" then
		local other = profile.villagers[w.arg]
		if other then
			return Text.fill(own(MEET, v.pers), { y = other.name })
		end
	end
	return nil
end

-- What a villager says to someone who stops to talk. opts:
--   first    they were just walked up to (a greeting, or their wish); otherwise it is small talk
--   last     what they said last, so they don't say it twice running
--   working  they are at work right now (their job's lines join in)
--   now      os time, for quarrels and how fresh their last event is
--   chat     what Talk.chat made of this talk, when it is the town's owner talking
--   season   1..4, and weather (World's), when known
function Talk.line(profile: any, vid: string, rng: any, opts: { [string]: any }?): string
	local v = profile.villagers[vid]
	if not v then
		return "..."
	end
	local o: { [string]: any } = opts or {}
	local pers = Personalities.get(v.pers)
	local pool: { string } = {}
	local function add(text: string?, weight: number?)
		if text and text ~= "" then
			for _ = 1, weight or 1 do
				table.insert(pool, text)
			end
		end
	end
	local function addLines(kind: string, weight: number?)
		local lines: { string } = if pers then (pers.lines[kind] or {}) else {}
		for _, text in lines do
			add(text, weight)
		end
	end
	local saying = Sayings.get(v.saying)
	local chat: Chat? = o.chat
	if chat and chat.wish then
		add(own(THANKS, v.pers))
		add("I needed that. Thank you.")
	elseif o.first then
		local wish = Talk.wishLine(profile, vid)
		if wish then
			return wish
		end
		addLines("hello", 2)
		add(saying and saying.text)
	else
		local sad = v.mood < 35
		if sad then
			addLines("sad", 2)
		elseif v.mood >= 65 then
			addLines("happy", 2)
		end
		if not v.bed then
			add(own(NOBED, v.pers), 3)
		end
		for _, other in profile.order do
			local ov = profile.villagers[other]
			if ov and other ~= vid and Relationships.quarreling(profile, vid, other, o.now or 0) then
				add(Text.fill(own(QUARREL, v.pers), { y = ov.name }), 3)
			end
		end
		if not sad then
			for _, text in SMALL do
				add(text)
			end
			for _, text in OWN[v.pers] or {} do
				add(text)
			end
			if v.bed then
				add("I slept well last night.")
			end
			add(saying and saying.text)
			local hobby = Sayings.hobby(v.hobby)
			add(hobby and hobby.line, 2)
			local friend = Relationships.bestFriend(profile, vid)
			local fv = friend and profile.villagers[friend]
			if fv and friend and not Relationships.quarreling(profile, vid, friend, o.now or 0) then
				add(Text.fill(own(FRIEND, v.pers), { y = fv.name }), 2)
			end
			local work = o.working and City.jobOf(profile, vid)
			if work then
				for _, text in work.job.lines do
					add(text)
				end
			end
			-- what they got up to lately
			add(Talk.memo(v, o.now), 3)
			-- a neighbour or two: how they get on, what they're like, a best friend
			local others = {}
			for _, other in profile.order do
				if other ~= vid and profile.villagers[other] then
					table.insert(others, other)
				end
			end
			for _ = 1, math.min(2, #others) do
				local other: string = table.remove(others, rng:int(1, #others)) :: string
				local ov = profile.villagers[other]
				local score = Relationships.peek(profile, vid, other)
				for _, band in OPINION do
					if score >= band.min then
						add(Text.fill(rng:pick(band.lines), { y = ov.name }))
						break
					end
				end
				local like = LIKE[ov.pers]
				if like then
					add(Text.fill(like, { y = ov.name }))
				end
				if score >= BEST_FRIENDS then
					add(Text.fill(own(BEST, v.pers), { y = ov.name }), 2)
				end
			end
			-- a worry, a joke (more from the cheeky ones), the season and the weather
			addLines("worry")
			add(rng:pick(JOKES), if v.pers == "cheeky" or v.pers == "sunny" then 2 else 1)
			if type(o.season) == "number" and SEASON[o.season] then
				add(SEASON[o.season])
			end
			if type(o.weather) == "string" and WEATHER[o.weather] then
				add(WEATHER[o.weather])
			end
		end
	end
	-- not the same thing twice running, when there is anything else to say
	if o.last then
		local fresh = {}
		for _, text in pool do
			if text ~= o.last then
				table.insert(fresh, text)
			end
		end
		if #fresh > 0 then
			pool = fresh
		end
	end
	if #pool == 0 then
		return "..."
	end
	return rng:pick(pool)
end

-- The good a chat does ---------------------------------------------------------------------------------

-- How many more chats with a villager count on in-game day `day`.
function Talk.left(profile: any, vid: string, day: number): number
	local v = profile.villagers[vid]
	if not v then
		return 0
	end
	local had = if v.chatDay == day then (v.chats or 0) else 0
	return math.max(0, K.ChatsPerDay - had)
end

-- The town's owner chats with one of their villagers on in-game day `day`. The first few a day
-- count: a little mood and a heart point each. A villager who wished for a talk has the wish
-- granted, whatever the count. Heart levels and a granted wish add their notices to `notices`.
function Talk.chat(profile: any, vid: string, day: number, rng: any, notices: { string }?): Chat
	local out: Chat = { counted = false, hearts = 0, mood = 0, left = 0, wish = false, coins = 0 }
	local v = profile.villagers[vid]
	if not v then
		return out
	end
	if v.wish and v.wish.kind == "cheer" then
		local granted, coins, said = Life.grantWish(profile, vid, "cheer", nil, rng)
		if granted then
			out.wish = true
			out.coins = coins
			if notices then
				for _, n in said do
					table.insert(notices, n)
				end
			end
		end
	end
	if v.chatDay ~= day then
		v.chatDay = day
		v.chats = 0
	end
	local had: number = v.chats or 0
	if had < K.ChatsPerDay then
		v.chats = had + 1
		local before: number = v.mood
		v.mood = math.clamp(before + K.ChatMood, Tuning.Villagers.MoodMin, Tuning.Villagers.MoodMax)
		out.mood = v.mood - before
		Life.addHearts(profile, vid, K.ChatHearts, rng, notices)
		out.hearts = K.ChatHearts
		out.counted = true
	end
	out.left = math.max(0, K.ChatsPerDay - (v.chats or 0))
	return out
end

-- What the talk card says about a chat, under the villager's words.
function Talk.note(profile: any, vid: string, chat: Chat): string
	local v = profile.villagers[vid]
	local name = if v then v.name else "?"
	if chat.wish then
		return Text.fill("{x} feels better for the talk.", { x = name })
	elseif chat.counted then
		return Text.fill(
			"{x} enjoyed that. Chat {n} of {max} today.",
			{ x = name, n = K.ChatsPerDay - chat.left, max = K.ChatsPerDay }
		)
	end
	return "You two have caught up for today."
end

return Talk
