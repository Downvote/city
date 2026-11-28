--!nocheck
-- What a villager says to somebody who isn't their mayor (Sim/GuestTalk). The user: "Create
-- dialogue for villagers interacting with players that arent their mayor." Every personality has
-- every kind of line, in its own voice and by the writing rule; a visitor is called by their own
-- name and the mayor is always "the Mayor"; a line about a town's name is said only when the town
-- has one; nothing a visitor hears does the town any good or harm; and past the day's cap the
-- villagers have things to do.

local Shared = "ReplicatedStorage.Shared."
local Tuning = require(Shared .. "Config.Tuning")
local Schema = require(Shared .. "Sim.Schema")
local GuestTalk = require(Shared .. "Sim.GuestTalk")
local Voice = require(Shared .. "Sim.Voice")
local Personalities = require(Shared .. "Data.Personalities")
local Appearance = require(Shared .. "Avatar.Appearance")
local StarterHouse = require(Shared .. "Data.StarterHouse")
local Rng = require(Shared .. "Util.Rng")

local function need(ok, what)
	if not ok then
		error(what, 2)
	end
end

local function town(pers)
	local p = Schema.newProfile()
	p.name = "Robin"
	p.plan = StarterHouse.plan()
	local input = Schema.cleanVillagerInput({ name = "Mara", pers = pers, app = Appearance.default() })
	p.villagers.v1 = Schema.newVillager("v1", input, Rng.new(3))
	table.insert(p.order, "v1")
	return p
end

local STOCK =
	{ "delve", "embark", "unleash", "vibrant", "bustling", "journey", "realm", "tapestry", "seamless", "elevate" }

describe("Guest talk", function()
	it("has every kind of line for all sixteen personalities, written like a person", function()
		local shouts, all = 0, 0
		for _, p in Personalities.list do
			local own = GuestTalk.Lines[p.id]
			need(own ~= nil, p.id .. " has no lines for visitors")
			for _, kind in GuestTalk.Kinds do
				local list = own[kind]
				need(type(list) == "table" and #list > 0, p.id .. " has no " .. kind .. " lines")
				for _, text in list do
					all += 1
					local lower = text:lower()
					need(
						not text:find("\u{2014}", 1, true)
							and not text:find("\u{2013}", 1, true)
							and not text:find(" - ", 1, true),
						p.id .. ": a dash in " .. text
					)
					for _, word in STOCK do
						need(not lower:find(word, 1, true), p.id .. ": a stock word in " .. text)
					end
					-- the mayor goes through {player} with "the" before it, never written in by hand
					need(not lower:find("mayor", 1, true), p.id .. ": the mayor written by hand: " .. text)
					for key in text:gmatch("{(%w+)}") do
						need(
							key == "name" or key == "player" or key == "town" or key == "home",
							p.id .. ": {" .. key .. "}"
						)
					end
					local bare = text:gsub("[Tt]he {player}", "")
					need(not bare:find("{player}", 1, true), p.id .. ': {player} without "the": ' .. text)
					-- never a string of clipped bits: three sentences at the most
					local _, stops = text:gsub("[%.!%?]+%s", "")
					need(stops <= 2, p.id .. ": too many sentences in " .. text)
					shouts += if text:find("!", 1, true) then 1 else 0
				end
			end
			-- the mayor is talked about, the visitor talked to by name
			local named = false
			for _, text in own.hello do
				named = named or text:find("{name}", 1, true) ~= nil
			end
			need(named, p.id .. " never greets a visitor by name")
			for _, text in own.mayor do
				need(text:find("{player}", 1, true) ~= nil, p.id .. " talks about nobody: " .. text)
			end
		end
		need(all >= 16 * 10, "only " .. all .. " lines")
		need(shouts / all < 0.25, shouts .. " of " .. all .. " lines shout")
		-- the quiet ones never raise their voice
		for _, id in { "cool", "gloomy", "shy", "polite" } do
			for _, list in GuestTalk.Lines[id] do
				for _, text in list do
					need(not text:find("!", 1, true), id .. " shouts: " .. text)
				end
			end
		end
	end)

	it("calls a visitor by their name and the mayor the Mayor, in the villager's own hand", function()
		for _, p in Personalities.list do
			local profile = town(p.id)
			local v = profile.villagers.v1
			local rng = Rng.new(7)
			local ctx = { name = "Sam", town = "Juniper Bay", home = "Old Mill" }
			local seen = {}
			for _ = 1, 200 do
				local text = GuestTalk.line(profile, "v1", rng, ctx, false)
				need(not text:find("{", 1, true), p.id .. ": a blank left in " .. text)
				need(not text:find("the Sam", 1, true) and not text:find("The Sam", 1, true), p.id .. ": " .. text)
				need(text == Voice.as(v, text), p.id .. ": not in their own hand: " .. text)
				seen[text] = true
			end
			local count = 0
			for _ in seen do
				count += 1
			end
			need(count >= 5, p.id .. " says only " .. count .. " things")
			local hello = GuestTalk.line(profile, "v1", rng, ctx, true)
			need(hello:lower():find("sam", 1, true) ~= nil or not hello:find("{", 1, true), hello)
		end
		-- the mayor, about whom a line is: always the Mayor, whatever the visitor is called
		local profile = town("polite")
		local said = GuestTalk.fill(profile, "The {player} always asks how I am, {name}.", { name = "Sam" })
		expect(said).toBe("The Mayor always asks how I am, Sam.")
		expect(GuestTalk.fill(profile, "{name}, the {player} is out.", { name = "sam" })).toBe("Sam, the Mayor is out.")
	end)

	it("only says a town's name when it has one", function()
		local profile = town("gentle")
		local rng = Rng.new(2)
		for _ = 1, 300 do
			local text = GuestTalk.line(profile, "v1", rng, { name = "Sam", town = "", home = "" }, false)
			need(not text:find("{", 1, true), "a blank left in " .. text)
			need(not text:find("Welcome to ,", 1, true), text)
		end
		expect(#GuestTalk.pool("gentle", "town", { name = "Sam" }) < #GuestTalk.pool("gentle", "town", {
			name = "Sam",
			town = "Juniper Bay",
		})).toBe(true)
		-- not the same thing twice running
		local last = nil
		for _ = 1, 100 do
			local text = GuestTalk.line(profile, "v1", rng, { name = "Sam", town = "Bay", home = "Mill" }, false, last)
			expect(text ~= last).toBe(true)
			last = text
		end
		-- a hello to somebody walking by, and the brush off
		expect(type(GuestTalk.passing(profile, "v1", rng, { name = "Sam" }))).toBe("string")
		expect(GuestTalk.busy(profile, "v1", { name = "Sam" }):find("chores", 1, true) ~= nil).toBe(true)
		expect(GuestTalk.line(profile, "nobody", rng, { name = "Sam" })).toBe("...")
	end)

	it("gives a visitor a few talks a day in each town", function()
		local book = {}
		local most = Tuning.Guests.ChatsPerDay
		for _ = 1, most do
			expect(GuestTalk.take(book, "2:1", 5, most)).toBe(true)
		end
		expect(GuestTalk.take(book, "2:1", 5, most)).toBe(false)
		-- another town, or the next day, starts again
		expect(GuestTalk.take(book, "2:7", 5, most)).toBe(true)
		expect(GuestTalk.take(book, "2:1", 6, most)).toBe(true)
	end)
end)
