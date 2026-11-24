--!nocheck
-- Talking to a villager (Sim/Talk). The user: "allow the option to interact/chat with villagers
-- by holding e on them". The first few chats a day with a villager do a little good and the
-- rest do none, so holding E all day can't be farmed; a chat answers a wish for one, once; they
-- greet you, tell you what they wish for and don't say the same thing twice running; old saves
-- chat like new ones.

local Shared = "ReplicatedStorage.Shared."
local Tuning = require(Shared .. "Config.Tuning")
local Schema = require(Shared .. "Sim.Schema")
local Talk = require(Shared .. "Sim.Talk")
local Life = require(Shared .. "Sim.Life")
local City = require(Shared .. "Sim.City")
local Relationships = require(Shared .. "Sim.Relationships")
local Appearance = require(Shared .. "Avatar.Appearance")
local Personalities = require(Shared .. "Data.Personalities")
local Foods = require(Shared .. "Data.Foods")
local StarterHouse = require(Shared .. "Data.StarterHouse")
local Sayings = require(Shared .. "Data.Sayings")
local Rng = require(Shared .. "Util.Rng")
local Text = require(Shared .. "Util.Text")

local K = Tuning.Talk
local L = Tuning.Life

local function town(count, pers)
	local p = Schema.newProfile()
	p.name = "Robin" -- the player, as the villagers call them ({player})
	p.plan = StarterHouse.plan()
	local rng = Rng.new(5)
	for i = 1, count do
		local input = Schema.cleanVillagerInput({ name = "V" .. i, pers = pers or "sunny", app = Appearance.default() })
		p.villagers["v" .. i] = Schema.newVillager("v" .. i, input, rng)
		table.insert(p.order, "v" .. i)
	end
	return p
end

-- what a chat may change
local function snapshot(p, vid)
	local v = p.villagers[vid]
	return { v.heart, v.hxp, v.mood, p.coins, #p.offers, p.stats.hearts, p.stats.wishes }
end

-- a line a player can read: something said, every blank filled, no dashes
local function readable(text)
	return type(text) == "string"
		and #text > 0
		and text ~= "..."
		and not text:find("{", 1, true)
		and not text:find("\u{2014}", 1, true)
		and not text:find("\u{2013}", 1, true)
end

-- lines as the player sees them, with their name in
local function filled(lines, p)
	local out = {}
	for _, text in lines or {} do
		table.insert(out, (Text.fill(text, { player = Text.playerName(p) })))
	end
	return out
end

local function need(ok, what)
	if not ok then
		error(what, 2)
	end
end

-- every kind of line a personality has (Data/Personalities)
local KINDS = {
	"hello",
	"happy",
	"sad",
	"angry",
	"thanks",
	"wow",
	"scared",
	"sorry",
	"yes",
	"no",
	"bye",
	"tease",
	"brag",
	"worry",
	"hmm",
	"excited",
	"tired",
	"laugh",
}

-- every line a villager can say in a talk, with where it is from
local function everyLine()
	local out = {}
	local function add(text, where)
		if type(text) == "string" then
			table.insert(out, { text = text, where = where })
		elseif type(text) == "table" then
			for k, v in text do
				add(v, where .. "." .. tostring(k))
			end
		end
	end
	for _, p in Personalities.list do
		add(p.lines, p.id)
	end
	for name, map in Talk.Voices do
		if name ~= "JOKY" then
			add(map, name)
		end
	end
	for name, list in Talk.Shared do
		add(list, name)
	end
	for _, say in Sayings.list do
		add(say.text, "saying " .. say.id)
	end
	for _, h in Sayings.hobbies do
		add(h.line, "hobby " .. h.id)
	end
	return out
end

describe("Talk", function()
	it("only counts the first few chats a day", function()
		local p = town(1)
		local v = p.villagers.v1
		local mood, rng = v.mood, Rng.new(1)
		local counted, hearts = 0, 0
		for i = 1, K.ChatsPerDay + 4 do
			local chat = Talk.chat(p, "v1", 7, rng)
			expect(chat.counted).toBe(i <= K.ChatsPerDay)
			expect(chat.left).toBe(math.max(0, K.ChatsPerDay - i))
			expect(Talk.left(p, "v1", 7)).toBe(chat.left)
			counted += if chat.counted then 1 else 0
			hearts += chat.hearts
		end
		expect(counted).toBe(K.ChatsPerDay)
		expect(hearts).toBe(K.ChatsPerDay * K.ChatHearts)
		expect(v.mood).toBe(mood + K.ChatsPerDay * K.ChatMood)
		expect(v.hxp + (v.heart - 1) * Life.heartNeed(1)).toBe(hearts)
		-- tomorrow they count again
		expect(Talk.left(p, "v1", 8)).toBe(K.ChatsPerDay)
		expect(Talk.chat(p, "v1", 8, rng).counted).toBe(true)
	end)

	it("gains nothing from holding E all day", function()
		local p = town(2)
		local rng = Rng.new(2)
		for _ = 1, K.ChatsPerDay do
			Talk.chat(p, "v1", 3, rng)
		end
		local before = snapshot(p, "v1")
		local other = snapshot(p, "v2")
		for _ = 1, 500 do
			local chat = Talk.chat(p, "v1", 3, rng)
			expect(chat.counted).toBe(false)
			expect(chat.hearts + chat.mood + chat.coins).toBe(0)
		end
		expect(snapshot(p, "v1")).toEqual(before)
		expect(snapshot(p, "v2")).toEqual(other)
		-- and a day of chats is worth less than one granted wish
		expect(K.ChatsPerDay * K.ChatHearts < L.WishHearts).toBeTruthy()
		expect(K.ChatsPerDay * K.ChatHearts < Life.heartNeed(1)).toBeTruthy()
	end)

	it("keeps mood inside its bounds", function()
		local p = town(1)
		p.villagers.v1.mood = Tuning.Villagers.MoodMax - 1
		local chat = Talk.chat(p, "v1", 1, Rng.new(3))
		expect(p.villagers.v1.mood).toBe(Tuning.Villagers.MoodMax)
		expect(chat.mood).toBe(1)
	end)

	it("answers a wish for a talk once, even after the day's chats", function()
		local p = town(1)
		local v = p.villagers.v1
		local rng = Rng.new(4)
		for _ = 1, K.ChatsPerDay do
			Talk.chat(p, "v1", 5, rng)
		end
		v.wish = { kind = "cheer", untilT = 1e9 }
		local coins = p.coins
		local heartWas = v.heart or 1
		local notices = {}
		local chat = Talk.chat(p, "v1", 5, rng, notices)
		expect(chat.wish).toBe(true)
		expect(chat.counted).toBe(false)
		expect(v.wish).toBe(nil)
		-- (a heart level it brings pays its own coins at once)
		local levelled = 0
		for level = heartWas + 1, v.heart do
			levelled += (Life.heartReward(level))
		end
		expect(p.coins).toBe(coins + chat.coins + levelled)
		expect(chat.coins >= L.WishCoinsMin and chat.coins <= L.WishCoinsMax).toBeTruthy()
		expect(p.stats.wishes).toBe(1)
		expect(#notices > 0).toBeTruthy()
		expect(readable(Talk.line(p, "v1", rng, { first = true, chat = chat }))).toBeTruthy()
		expect(readable(Talk.note(p, "v1", chat))).toBeTruthy()
		local again = Talk.chat(p, "v1", 5, rng)
		expect(again.wish).toBe(false)
		expect(p.coins).toBe(coins + chat.coins + levelled)
	end)

	it("leaves other wishes for their own answers, and says them", function()
		local p = town(2)
		local v = p.villagers.v1
		local rng = Rng.new(6)
		v.wish = { kind = "food", arg = v.fav, untilT = 1e9 }
		expect(Talk.chat(p, "v1", 1, rng).wish).toBe(false)
		expect(v.wish ~= nil).toBeTruthy()
		local said = Talk.line(p, "v1", rng, { first = true })
		expect(said:find(Foods.get(v.fav).name, 1, true) ~= nil).toBeTruthy()
		v.wish = { kind = "friend", arg = "v2", untilT = 1e9 }
		expect(Talk.line(p, "v1", rng, { first = true }):find("V2", 1, true) ~= nil).toBeTruthy()
		-- a wish for a talk isn't told, the talk answers it
		v.wish = { kind = "cheer", untilT = 1e9 }
		expect(Talk.wishLine(p, "v1")).toBe(nil)
		-- someone they wished to meet has moved away
		v.wish = { kind = "friend", arg = "gone", untilT = 1e9 }
		expect(readable(Talk.line(p, "v1", rng, { first = true }))).toBeTruthy()
	end)

	it("has something to say in every mood, and not the same thing twice running", function()
		for _, pers in Personalities.list do
			local p = town(3, pers.id)
			local v = p.villagers.v1
			local rng = Rng.new(#pers.id)
			for _, mood in { 10, 50, 90 } do
				v.mood = mood
				local greeting = Talk.line(p, "v1", rng, { first = true })
				expect(readable(greeting)).toBeTruthy()
				-- their own hello, or one of the greetings just for the player, by name
				local greets = filled(pers.lines.hello, p)
				for _, text in filled(Talk.Voices.GREET[pers.id], p) do
					table.insert(greets, text)
				end
				expect(table.find(greets, greeting) ~= nil).toBeTruthy()
				local last = greeting
				for _ = 1, 60 do
					local said = Talk.line(p, "v1", rng, { last = last, now = 100 })
					-- (a shy villager who is down may just say "...")
					expect(readable(said) or table.find(filled(pers.lines.sad, p), said) ~= nil).toBeTruthy()
					expect(said ~= last).toBeTruthy()
					last = said
				end
			end
		end
	end)

	it("talks about their bed, their friends, their hobby and their work", function()
		local p = town(3)
		p.plan.items.stall = { id = "work_market", x = 130, y = 0, z = 12, r = 180, lv = 0 }
		local v = p.villagers.v1
		v.job = City.freeWorkplace(p)
		v.hobby = "fishing"
		v.saying = "tea"
		v.mood = 50
		Relationships.add(p, "v1", "v2", 60)
		Relationships.quarrel(p, "v1", "v3", 100)
		local job = City.jobOf(p, "v1").job
		local function heard(opts, n)
			local rng, seen = Rng.new(11), {}
			for _ = 1, n or 600 do
				seen[Talk.line(p, "v1", rng, opts)] = true
			end
			return seen
		end
		local atWork = heard({ working = true, now = 200 })
		local atHome = heard({ now = 200 })
		for _, text in job.lines do
			expect(atWork[text]).toBe(true)
			expect(atHome[text]).toBe(nil)
		end
		-- (a sunny villager, in their own words, calling the player by name)
		local quarrel = "V3 and I had a fight and I hate it. Can things just go back to normal?"
		local nobed = "Still no bed! I've been sleeping on a pile of coats. Could you sort one out, Robin?"
		expect(atHome["Nothing was biting today. Stayed out three hours anyway."]).toBe(true)
		expect(atHome["Nothing a cup of tea can't fix."]).toBe(true)
		expect(atHome["V2 always makes me laugh. We sat on the pier talking for hours yesterday!"]).toBe(true)
		expect(atHome[quarrel]).toBe(true)
		expect(atHome[nobed]).toBe(true)
		-- the quarrel blows over, and a bed turns up
		v.bed = "1"
		local later = heard({ now = 100 + Tuning.Relationships.QuarrelMinutes * 60 + 1 })
		expect(later[quarrel]).toBe(nil)
		expect(later[nobed]).toBe(nil)
		-- someone who is down doesn't make small talk
		v.mood = 10
		v.bed = "1"
		for text in heard({ now = 5000 }, 200) do
			expect(table.find(filled(Personalities.get(v.pers).lines.sad, p), text) ~= nil).toBeTruthy()
		end
	end)

	it("says things in their own way", function()
		-- the user: "for the humanization, make sure to take note of the personalities of the
		-- villagers as well": the same news from a shy villager and a loud one
		local function heard(pers)
			local p = town(2, pers)
			p.villagers.v1.mood = 50
			Relationships.quarrel(p, "v1", "v2", 100)
			local rng, seen = Rng.new(31), {}
			for _ = 1, 800 do
				seen[Talk.line(p, "v1", rng, { now = 200 })] = true
			end
			return seen
		end
		local shy, bold = heard("shy"), heard("bold")
		expect(shy["Um. I don't have a bed yet. It's okay. The floor's okay."]).toBe(true)
		expect(bold["Still no bed. I'm sleeping on the floor. Sort it out."]).toBe(true)
		expect(shy["V2 and I had a falling out. I feel awful about it."]).toBe(true)
		expect(bold["Don't talk to me about V2. We're not speaking."]).toBe(true)
		expect(bold["Um. I don't have a bed yet. It's okay. The floor's okay."]).toBe(nil)
		expect(bold["V2 and I had a falling out. I feel awful about it."]).toBe(nil)
		expect(shy["Still no bed. I'm sleeping on the floor. Sort it out."]).toBe(nil)
		expect(shy["Don't talk to me about V2. We're not speaking."]).toBe(nil)
		-- every personality asks for a food, and to meet someone, in words of its own
		local cravings, meets = {}, {}
		for _, pers in Personalities.list do
			local p = town(2, pers.id)
			local v = p.villagers.v1
			v.wish = { kind = "food", arg = v.fav, untilT = 1e9 }
			local said = Talk.wishLine(p, "v1")
			expect(readable(said)).toBeTruthy()
			expect(said:find(Foods.get(v.fav).name, 1, true) ~= nil).toBeTruthy()
			cravings[said] = true
			v.wish = { kind = "friend", arg = "v2", untilT = 1e9 }
			said = Talk.wishLine(p, "v1")
			expect(readable(said) and said:find("V2", 1, true) ~= nil).toBeTruthy()
			meets[said] = true
		end
		local n, m = 0, 0
		for _ in cravings do
			n += 1
		end
		for _ in meets do
			m += 1
		end
		expect(n).toBe(#Personalities.list)
		expect(m).toBe(#Personalities.list)
	end)

	it("has more to say: their last event, the neighbours, a worry, a joke, the season", function()
		-- the user: "make much much more random events ... conversations"
		local p = town(3)
		local v = p.villagers.v1
		v.mood = 50
		v.bed = "1"
		v.pers = "cheeky"
		p.villagers.v2.pers = "dreamy"
		-- best friends: as close as two villagers get (there is no romance)
		Relationships.add(p, "v1", "v2", 85)
		Relationships.add(p, "v1", "v3", -50)
		v.memo = { text = "I built a snowman yesterday. He's called Gerald.", t = 1000 }
		local function heard(opts, n)
			local rng, seen = Rng.new(21), {}
			for _ = 1, n or 1500 do
				local text = Talk.line(p, "v1", rng, opts)
				expect(readable(text)).toBeTruthy()
				seen[text] = true
			end
			return seen
		end
		local now = 1000 + 60
		local all = heard({ now = now, season = 4, weather = "snow" })
		expect(all["I built a snowman yesterday. He's called Gerald."]).toBe(true)
		expect(all["V2 is my best friend. We've got a secret handshake. It takes four minutes."]).toBe(true)
		expect(all["V3 is my best friend. We've got a secret handshake. It takes four minutes."]).toBe(nil)
		expect(all["V2 told me the moon is a big pebble. I've been thinking about it all day."]).toBe(true)
		local fond, cross = false, false
		for text in all do
			fond = fond
				or text == "V2 is my favourite person. Don't tell the others."
				or text:find("carry a piano", 1, true) ~= nil
			cross = cross
				or text == "Don't mention V3. Please."
				or text == "I'd rather not talk about V3, if that's all right."
		end
		expect(fond).toBe(true)
		expect(cross).toBe(true)
		expect(all["My nose has been cold since Tuesday."]).toBe(true)
		expect(all["Have you been out in the snow yet? Go on."]).toBe(true)
		local worried = false
		for _, text in Personalities.get("cheeky").lines.worry do
			worried = worried or all[text] == true
		end
		expect(worried).toBe(true)
		-- an old event is forgotten after a day or so
		local later = 1000 + Tuning.Events.MemoHours * Tuning.Day.Length / 24 + 10
		expect(Talk.memo(v, later)).toBe(nil)
		expect(heard({ now = later }, 600)["I built a snowman yesterday. He's called Gerald."]).toBe(nil)
		expect(Talk.memo(v, nil)).toBe(nil)
		expect(Talk.memo({ memo = "junk" }, now)).toBe(nil)
	end)

	it("says what a chat did in plain words", function()
		local p = town(1)
		local rng = Rng.new(8)
		local seen = {}
		for _ = 1, K.ChatsPerDay + 1 do
			local note = Talk.note(p, "v1", Talk.chat(p, "v1", 2, rng))
			expect(readable(note)).toBeTruthy()
			seen[note] = true
		end
		-- each chat that counts says which one it was; the one past the cap says something else
		local n = 0
		for _ in seen do
			n += 1
		end
		expect(n).toBe(K.ChatsPerDay + 1)
	end)

	it("stops a villager for a talk only when they are free", function()
		expect(Talk.free(nil)).toBe(true)
		expect(Talk.free("chat")).toBe(true)
		expect(Talk.free("talk")).toBe(true)
		expect(Talk.free("event")).toBe(false)
		expect(Talk.free("away")).toBe(false)
		-- nobody there: nothing happens
		local p = town(1)
		local chat = Talk.chat(p, "nobody", 1, Rng.new(1))
		expect(chat.counted).toBe(false)
		expect(Talk.left(p, "nobody", 1)).toBe(0)
		expect(Talk.line(p, "nobody", Rng.new(1), { first = true })).toBe("...")
	end)

	it("gives sixteen personalities every kind of line, each in a voice of its own", function()
		-- the user: "redo all the conversation lines ... incorporate them into the villagers based on
		-- their personalities ... add more personalities too"
		expect(#Personalities.list).toBe(16)
		local ids = {}
		for _, p in Personalities.list do
			need(ids[p.id] == nil, p.id .. " is there twice")
			ids[p.id] = true
			need(Personalities.get(p.id) == p, p.id .. " can't be found")
			need(type(p.name) == "string" and #p.name > 0, p.id .. " has no name")
			need(type(p.blurb) == "string" and #p.blurb > 0, p.id .. " has no blurb")
			need(type(p.color) == "string" and p.color:match("^%x%x%x%x%x%x$") ~= nil, p.id .. " has no colour")
			for _, t in { "social", "temper", "kind", "mischief", "lazy", "brave", "focus" } do
				local x = p.traits[t]
				need(type(x) == "number" and x >= 0 and x <= 1, p.id .. ": " .. t .. " out of range")
			end
			local seen = {}
			for _, kind in KINDS do
				local lines = p.lines[kind]
				need(type(lines) == "table" and #lines >= 4, p.id .. " has too few " .. kind .. " lines")
				for _, text in lines do
					need(type(text) == "string" and #text > 0, p.id .. "." .. kind .. " has an empty line")
					need(not seen[text], p.id .. " says this twice: " .. text)
					seen[text] = true
				end
			end
		end
		for _, id in
			{
				"sunny",
				"gentle",
				"bold",
				"dreamy",
				"easygoing",
				"proud",
				"shy",
				"cheeky",
				"cool",
				"prickly",
				"dramatic",
				"bookish",
				"gloomy",
				"polite",
				"foodie",
				"nervous",
			}
		do
			need(ids[id], id .. " is missing")
		end
		-- every map Sim/Talk keys by personality has something for each of them, and no two of them
		-- say it the same way
		for name, map in Talk.Voices do
			local said = {}
			for _, p in Personalities.list do
				local own = map[p.id]
				need(own ~= nil, name .. " has nothing for " .. p.id)
				if name ~= "JOKY" then
					local key = if type(own) == "table" then table.concat(own, "|") else own
					need(said[key] == nil, name .. ": " .. p.id .. " and " .. tostring(said[key]) .. " say the same")
					said[key] = p.id
				end
			end
		end
		-- and the lines anybody says cover every season and every weather the town has
		expect(#Talk.Shared.SEASON).toBe(4)
		for _, w in { "clear", "cloudy", "rain", "storm", "snow", "blossom", "leaves" } do
			need(Talk.Shared.WEATHER[w] ~= nil and #Talk.Shared.WEATHER[w] >= 2, "nothing to say about " .. w)
		end
	end)

	it("sounds like a friend texting, each in their own way", function()
		-- the user pointed at a messaging app's chats: short bursts in their own voice, and the
		-- writing rule (CLAUDE.md, Writing) everywhere
		local lines = everyLine()
		local bang = 0
		for _, l in lines do
			local text, lower = l.text, l.text:lower()
			need(
				not text:find("\u{2014}", 1, true)
					and not text:find("\u{2013}", 1, true)
					and not text:find(" - ", 1, true),
				l.where .. ": a dash in " .. text
			)
			need(not lower:find("it's not like", 1, true), l.where .. ": " .. text)
			for _, word in
				{
					"delve",
					"embark",
					"unleash",
					"vibrant",
					"bustling",
					"journey",
					"realm",
					"tapestry",
					"seamless",
					"elevate",
				}
			do
				need(not lower:find(word, 1, true), l.where .. ": a stock word in " .. text)
			end
			-- the only blanks are the player's name, a neighbour's name and a food
			for key in text:gmatch("{(%w+)}") do
				need(key == "player" or key == "y" or key == "food", l.where .. ": {" .. key .. "} in " .. text)
			end
			bang += if text:find("!", 1, true) then 1 else 0
		end
		need(#lines > 1200, "only " .. #lines .. " lines")
		-- no exclamation on every line
		need(bang / #lines < 0.1, string.format("%d of %d lines shout", bang, #lines))
		-- the cool ones: five words at most, and never a raised voice
		for kind, list in Personalities.get("cool").lines do
			for _, text in list do
				local words = 0
				for _ in text:gmatch("%S+") do
					words += 1
				end
				need(words <= 5 and not text:find("!", 1, true), "cool." .. kind .. " says too much: " .. text)
			end
		end
		-- the shy and the polite ones hardly ever raise their voice either
		for _, id in { "shy", "polite", "gloomy", "gentle" } do
			local n = 0
			for _, list in Personalities.get(id).lines do
				for _, text in list do
					n += if text:find("!", 1, true) then 1 else 0
				end
			end
			need(n <= 2, id .. " shouts " .. n .. " times")
		end
	end)

	it("calls the player by name and never anything else", function()
		-- the user: "the player is to be referred to as their player name instead of sensei"
		for _, l in everyLine() do
			local lower = l.text:lower()
			need(
				not lower:find("sensei", 1, true) and not lower:find("mayor", 1, true),
				l.where .. ": calls the player something other than their name: " .. l.text
			)
		end
		local named, total = 0, 0
		for _, p in Personalities.list do
			local own = 0
			for _, list in p.lines do
				for _, text in list do
					total += 1
					own += if text:find("{player}", 1, true) then 1 else 0
				end
			end
			named += own
			need(own > 0, p.id .. " never says the player's name")
			for _, text in Talk.Voices.GREET[p.id] do
				need(text:find("{player}", 1, true) ~= nil, p.id .. " greets the player without their name: " .. text)
			end
			-- what they say to another villager in an event, or to each other in passing, has no name in
			for _, kind in { "hello", "angry", "thanks", "sorry", "yes", "no", "bye", "tease", "hmm", "laugh" } do
				for _, text in p.lines[kind] do
					need(not text:find("{player}", 1, true), p.id .. "." .. kind .. " goes to villagers too: " .. text)
				end
			end
		end
		-- some lines, not every one
		need(named >= #Personalities.list and named < total / 4, named .. " of " .. total .. " say the name")
		-- a saying is offered word for word as an answer in an event, so it has no blanks
		for _, say in Sayings.list do
			need(not say.text:find("{", 1, true), "saying " .. say.id .. " has a blank")
		end
		-- the name goes in as the line leaves: the owner's, or a visitor's own
		local p = town(2, "foodie")
		local rng = Rng.new(12)
		local mine, theirs = {}, {}
		for _ = 1, 300 do
			local said = Talk.line(p, "v1", rng, { first = true })
			expect(readable(said)).toBeTruthy()
			mine[said] = true
			said = Talk.line(p, "v1", rng, { first = true, name = "Sam" })
			expect(readable(said) and said:find("Robin", 1, true) == nil).toBeTruthy()
			theirs[said] = true
		end
		expect(mine["Robin! Have you eaten? I have. Twice."]).toBe(true)
		expect(theirs["Sam! Have you eaten? I have. Twice."]).toBe(true)
		expect(mine["Hey! Have you eaten? I have. Twice."]).toBe(true)
		-- and a wish, told by name
		local v = p.villagers.v1
		v.wish = { kind = "food", arg = v.fav, untilT = 1e9 }
		local food = Foods.get(v.fav).name
		expect(Talk.wishLine(p, "v1")).toBe("Robin! " .. food .. "! I can taste it already. Mmm. Please?")
		-- someone with no name yet is a friend
		p.name = nil
		expect(Talk.wishLine(p, "v1")).toBe("friend! " .. food .. "! I can taste it already. Mmm. Please?")
	end)

	it("chats with villagers from old saves", function()
		local old = { coins = 50, villagers = { a = { name = "Old", pers = "gentle" } }, order = { "a" } }
		local p = Schema.migrate(old)
		local rng = Rng.new(9)
		expect(Talk.left(p, "a", 4)).toBe(K.ChatsPerDay)
		local chat = Talk.chat(p, "a", 4, rng)
		expect(chat.counted).toBe(true)
		expect(p.villagers.a.chats).toBe(1)
		expect(p.villagers.a.chatDay).toBe(4)
		expect(readable(Talk.line(p, "a", rng, { first = true }))).toBeTruthy()
		expect(readable(Talk.line(p, "a", rng, {}))).toBeTruthy()
	end)
end)
