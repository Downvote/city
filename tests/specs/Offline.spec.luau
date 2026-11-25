--!nocheck
-- Offline earnings (Sim/Offline; the user: "add offline earnings"). Coming back after a while pays
-- the town Tuning.Offline.Share of what its working villagers would have earned at work in that
-- time (a day's wages for each town day of it), the time counted up to Tuning.Offline.Hours, times
-- the pay boost. Nothing on a first visit, for a quick rejoin, or for a town with nobody in work,
-- and never so much that being away beats playing.

local Shared = "ReplicatedStorage.Shared."
local Tuning = require(Shared .. "Config.Tuning")
local Schema = require(Shared .. "Sim.Schema")
local City = require(Shared .. "Sim.City")
local Offline = require(Shared .. "Sim.Offline")
local Appearance = require(Shared .. "Avatar.Appearance")
local StarterHouse = require(Shared .. "Data.StarterHouse")
local Rng = require(Shared .. "Util.Rng")

local K = Tuning.Offline
local HOUR = 3600
local NOW = 1_800_000_000

local function town(workers)
	local profile = Schema.newProfile()
	profile.plan = StarterHouse.plan()
	for i = 1, 2 do
		local input = Schema.cleanVillagerInput({ name = "V" .. i, pers = "sunny", app = Appearance.default() })
		profile.villagers["v" .. i] = Schema.newVillager("v" .. i, input, Rng.new(i))
		table.insert(profile.order, "v" .. i)
	end
	if workers > 0 then
		profile.villagers.v1.job = City.freeWorkplace(profile)
	end
	return profile
end

describe("Offline earnings", function()
	it("counts the time away from when the save was last made with the player in", function()
		expect(Offline.away(NOW - 600, NOW)).toBe(600)
		-- never seen (a first visit, or a save from before this), junk, or a clock gone backwards
		expect(Offline.away(0, NOW)).toBe(0)
		expect(Offline.away(nil, NOW)).toBe(0)
		expect(Offline.away("yesterday", NOW)).toBe(0)
		expect(Offline.away(0 / 0, NOW)).toBe(0)
		expect(Offline.away(NOW + 50, NOW)).toBe(0)
	end)

	it("pays a share of a day's wages for every town day away", function()
		local p = town(1)
		local _, perDay = City.wages(p, -1, NOW)
		expect(perDay > 0).toBeTruthy()
		local got = Offline.earnings(p, 2 * HOUR, 1, NOW)
		local days = 2 * HOUR / Tuning.Day.Length
		expect(got.coins).toBe(math.floor(perDay * days * K.Share + 0.5))
		expect(got.workers).toBe(1)
		expect(got.counted).toBe(2 * HOUR)
		expect(got.secs).toBe(2 * HOUR)
	end)

	it("counts no more than the hours it allows", function()
		local p = town(1)
		local cap = Offline.earnings(p, K.Hours * HOUR, 1, NOW)
		local week = Offline.earnings(p, 7 * 24 * HOUR, 1, NOW)
		expect(week.coins).toBe(cap.coins)
		expect(week.counted).toBe(K.Hours * HOUR)
		expect(week.secs).toBe(7 * 24 * HOUR)
	end)

	it("pays nothing for a quick rejoin, a first visit or a town with nobody at work", function()
		local p = town(1)
		expect(Offline.earnings(p, K.MinMinutes * 60 - 1, 1, NOW).coins).toBe(0)
		expect(Offline.earnings(p, 0, 1, NOW).coins).toBe(0)
		expect(Offline.earnings(p, 0 / 0, 1, NOW).coins).toBe(0)
		expect(Offline.earnings(p, math.huge, 1, NOW).coins).toBe(0)
		expect(Offline.earnings(town(0), 5 * HOUR, 1, NOW).coins).toBe(0)
		expect(Offline.earnings(nil, 5 * HOUR, 1, NOW).coins).toBe(0)
	end)

	it("is raised by the pay boost, and never lowered by a broken one", function()
		local p = town(1)
		local plain = Offline.earnings(p, 3 * HOUR, 1, NOW).coins
		local double = Offline.earnings(p, 3 * HOUR, 2, NOW).coins
		expect(math.abs(double - plain * 2) <= 1).toBeTruthy()
		for _, bad in { 0, -2, 0 / 0, math.huge, nil } do
			expect(Offline.earnings(p, 3 * HOUR, bad, NOW).coins).toBe(plain)
		end
	end)

	it("stays well under what the same time playing would earn", function()
		local p = town(1)
		local _, perDay = City.wages(p, -1, NOW)
		-- the most a whole time away brings, against an hour at work in the game
		local most = Offline.earnings(p, 48 * HOUR, 1, NOW).coins
		local hourPlaying = perDay * HOUR / Tuning.Day.Length
		expect(most <= hourPlaying).toBeTruthy()
		expect(most > 0).toBeTruthy()
		expect(K.Share > 0 and K.Share <= 0.25).toBeTruthy()
	end)
end)
