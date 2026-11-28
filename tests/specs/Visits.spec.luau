--!nocheck
-- Customers and company (Sim/Visits). The user: "while villagers are working or you are working,
-- villagers might come up to interact and do chats based on the work that is being done, like
-- villagers buying ice cream. do this as well with things like the swing, where villagers might sit
-- with each other or with you." Held here: every job has its customers' asks in every
-- personality's own words and its worker's answers; every line keeps to the writing rule and to the
-- marks its personality owns (Sim/Voice puts the rest on); the player is only ever {player}; and
-- the seats side by side are found. Also the work moves: every step of every job's loop has a move
-- (the user: "let there be animations while a villager works").

local Shared = "ReplicatedStorage.Shared."
local Tuning = require(Shared .. "Config.Tuning")
local Jobs = require(Shared .. "Data.Jobs")
local Personalities = require(Shared .. "Data.Personalities")
local Catalog = require(Shared .. "Build.Catalog")
local Routine = require(Shared .. "Sim.Routine")
local Voice = require(Shared .. "Sim.Voice")
local Visits = require(Shared .. "Sim.Visits")
local Rng = require(Shared .. "Util.Rng")

-- the moves a body has (its Animate script's, or Roblox's own: Npc's)
local MOTIONS = {
	wave = true,
	point = true,
	dance = true,
	dance2 = true,
	laugh = true,
	cheer = true,
	toolslash = true,
	toollunge = true,
}

local function sentences(text)
	local n = 1
	for _ in text:gmatch("[%.!%?]+%s+[%u%*]") do
		n += 1
	end
	return n
end

describe("Visits", function()
	it("has customers for every job, in every personality's words, and the worker's answers", function()
		local rng = Rng.new(7)
		for _, job in Jobs.list do
			expect(Visits.has(job.id)).toBe(true)
			for _, p in Personalities.list do
				-- their own line comes up, and so does one anybody says
				local seen, kinds = {}, 0
				for _ = 1, 60 do
					local text = Visits.ask(job.id, p.id, rng)
					if not seen[text] then
						seen[text] = true
						kinds += 1
					end
				end
				expect(kinds >= 2).toBeTruthy()
				expect(type(Visits.ask(job.id, p.id, nil))).toBe("string")
			end
			-- the worker's answer, with the customer's name where it has one, and no blank left
			for _ = 1, 20 do
				local text = Visits.serve(job.id, "Mara", rng)
				expect(text:find("{", 1, true)).toBe(nil)
			end
		end
		-- a job with no lines of its own still gets something plain
		expect(Visits.ask("nobody", "sunny", rng)).toBe("One of those, please.")
		expect(Visits.serve("nobody", "Mara", rng)).toBe("Here you go, and come again.")
		-- thanks, a word for the player at the counter, and a word sitting down, for everyone
		for _, p in Personalities.list do
			expect(Visits.thanks(p.id, rng) ~= "Thanks." or p.id == "cool").toBeTruthy()
			expect(Visits.greet(p.id):find("{player}", 1, true) ~= nil).toBeTruthy()
			expect(Visits.sit(p.id, rng, true):find("{player}", 1, true) ~= nil).toBeTruthy()
			expect(Visits.sit(p.id, rng, false):find("{player}", 1, true)).toBe(nil)
		end
	end)

	it("keeps every line to the writing rule and to its own personality's marks", function()
		local all = Visits.all()
		expect(#all >= #Jobs.list * (16 + 3 + 4) + 16 * 6).toBeTruthy()
		local perJob = {}
		for _, l in all do
			local t = l.text
			local where = string.format("%s %s %s: %s", l.kind, l.job or "", l.pers or "anyone", t)
			-- plain: no dashes, no shouting on every line, nothing the game fills but the player
			if t:find("\u{2014}") or t:find("\u{2013}") or t:find(" %- ") then
				error("a dash in " .. where)
			end
			if t:find("Mayor") then
				error("the player is {player}, never written by hand: " .. where)
			end
			local blanks = t:gsub("{player}", ""):gsub("{name}", "")
			if blanks:find("[{}|]") then
				error("a stray mark in " .. where)
			end
			if t:find("{player}") and l.kind ~= "greet" and l.kind ~= "sitPlayer" then
				error("only a line to the player names them: " .. where)
			end
			if t:find("{name}") and l.kind ~= "serve" then
				error("only the worker names the customer: " .. where)
			end
			-- one sentence, or two that go together, short enough for a bubble
			if sentences(t) > 2 then
				error("more than two sentences: " .. where)
			end
			expect(#t <= 100).toBeTruthy()
			-- the marks a personality owns are theirs alone, and the quiet ones never shout
			if t:find("~", 1, true) and l.pers ~= "gentle" then
				error("only the gentle end with ~: " .. where)
			end
			if t:find("\u{266A}") and l.pers ~= "dreamy" then
				error("only the dreamy hum: " .. where)
			end
			if (l.pers == "cool" or l.pers == "gloomy") and t:find("!") then
				error("the " .. l.pers .. " never shout: " .. where)
			end
			-- and every one can be said in its own hand
			local said = Voice.speak(l.pers, t)
			expect(#said > 0).toBeTruthy()
			if l.kind == "ask" and l.pers then
				perJob[l.job] = perJob[l.job] or {}
				perJob[l.job][l.pers] = true
			end
		end
		for _, job in Jobs.list do
			for _, p in Personalities.list do
				if not (perJob[job.id] and perJob[job.id][p.id]) then
					error(string.format("no %s customer at the %s", p.id, job.place))
				end
			end
		end
	end)

	it("finds the free seats beside somebody sat down, nearest first", function()
		local free = { Vector3.new(0, 0, 0), Vector3.new(10, 0, 0), Vector3.new(20, 0, 0.5) }
		local taken = { Vector3.new(2, 0, 0), Vector3.new(23, 0, 0) }
		local pairs = Visits.beside(free, taken, Tuning.Visits.Beside)
		expect(#pairs).toBe(2)
		-- the seat at 0 is 2 off the first sitter; the one at 20 is 3 off the second; 10 is too far
		expect(pairs[1][1]).toBe(1)
		expect(pairs[1][2]).toBe(1)
		expect(pairs[2][1]).toBe(3)
		expect(pairs[2][2]).toBe(2)
		expect(#Visits.beside(free, {}, Tuning.Visits.Beside)).toBe(0)
		-- a swing set's two swings, a bench for two, two chairs at a table: in reach
		expect(Tuning.Visits.Beside >= 2.6 and Tuning.Visits.Beside <= 6).toBeTruthy()
		expect(Tuning.Visits.PickPlayer > 0.5 and Tuning.Visits.BesidePlayer > Tuning.Visits.SitBeside).toBeTruthy()
	end)

	it("gives every step of every job's work a move, at a beat", function()
		for _, def in Catalog.workplaces() do
			for _, stop in Routine.loop(def) do
				if not MOTIONS[stop.act] then
					error(string.format("%s, %s: no move (%s)", def.id, stop.name, tostring(stop.act)))
				end
				expect(type(stop.beat) == "number" and stop.beat >= 1).toBeTruthy()
			end
		end
		for _, job in Jobs.list do
			local act, beat = Routine.move(job.id)
			expect(MOTIONS[act]).toBe(true)
			expect(beat >= 1).toBeTruthy()
		end
		expect((Routine.move(nil))).toBe("point")
	end)
end)
