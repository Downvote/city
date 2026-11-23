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
local Rng = require(Shared .. "Util.Rng")

local K = Tuning.Talk
local L = Tuning.Life

local function town(count, pers)
	local p = Schema.newProfile()
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
		local notices = {}
		local chat = Talk.chat(p, "v1", 5, rng, notices)
		expect(chat.wish).toBe(true)
		expect(chat.counted).toBe(false)
		expect(v.wish).toBe(nil)
		expect(p.coins).toBe(coins + chat.coins)
		expect(chat.coins >= L.WishCoinsMin and chat.coins <= L.WishCoinsMax).toBeTruthy()
		expect(p.stats.wishes).toBe(1)
		expect(#notices > 0).toBeTruthy()
		expect(readable(Talk.line(p, "v1", rng, { first = true, chat = chat }))).toBeTruthy()
		expect(readable(Talk.note(p, "v1", chat))).toBeTruthy()
		local again = Talk.chat(p, "v1", 5, rng)
		expect(again.wish).toBe(false)
		expect(p.coins).toBe(coins + chat.coins)
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
		v.wish = { kind = "look", untilT = 1e9 }
		expect(readable(Talk.line(p, "v1", rng, { first = true }))).toBeTruthy()
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
				expect(table.find(pers.lines.hello, greeting) ~= nil).toBeTruthy()
				local last = greeting
				for _ = 1, 60 do
					local said = Talk.line(p, "v1", rng, { last = last, now = 100 })
					-- (a shy villager who is down may just say "...")
					expect(readable(said) or table.find(pers.lines.sad, said) ~= nil).toBeTruthy()
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
		expect(atHome["Caught a boot today. Nice boot, though."]).toBe(true)
		expect(atHome["Nothing a cup of tea can't fix."]).toBe(true)
		expect(atHome["V2 always makes me laugh."]).toBe(true)
		expect(atHome["V3 and I aren't speaking right now."]).toBe(true)
		expect(atHome["I still don't have a bed, you know."]).toBe(true)
		-- the quarrel blows over, and a bed turns up
		v.bed = "1"
		local later = heard({ now = 100 + Tuning.Relationships.QuarrelMinutes * 60 + 1 })
		expect(later["V3 and I aren't speaking right now."]).toBe(nil)
		expect(later["I still don't have a bed, you know."]).toBe(nil)
		-- someone who is down doesn't make small talk
		v.mood = 10
		v.bed = "1"
		for text in heard({ now = 5000 }, 200) do
			expect(table.find(Personalities.get(v.pers).lines.sad, text) ~= nil).toBeTruthy()
		end
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
