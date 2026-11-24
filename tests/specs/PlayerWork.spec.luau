--!nocheck
-- A player's own work at a workplace (Sim/PlayerWork). The user: "also, allow players to interact
-- and work at work areas". Held here: a player stands where the villagers stand at each
-- workplace, faces the work and goes at it with the job's own motion; they earn a share of a
-- new villager's rate there in whole coins and never past the day's cap, kept on their profile;
-- who may start where, and what they are told when not; why work stops by itself; and that a
-- player's own work stays small beside their town's wages, so progression is still "much more
-- based on villagers working".

local Shared = "ReplicatedStorage.Shared."
local Tuning = require(Shared .. "Config.Tuning")
local Catalog = require(Shared .. "Build.Catalog")
local Jobs = require(Shared .. "Data.Jobs")
local City = require(Shared .. "Sim.City")
local Routine = require(Shared .. "Sim.Routine")
local Schema = require(Shared .. "Sim.Schema")
local PlayerWork = require(Shared .. "Sim.PlayerWork")

local K = Tuning.Jobs.Player
local D = Tuning.Day
local START = Tuning.Villagers.StartMood

-- the animations a body has under these names (its Animate script's, or Roblox's own: Npc's)
local MOTIONS = { wave = true, point = true, dance = true, dance2 = true, laugh = true, cheer = true, toolslash = true }

local function near(a, b, eps)
	return (a - b).Magnitude <= (eps or 1e-3)
end

describe("PlayerWork", function()
	it("stands a player where a villager works, turned to the work, with the job's own motion", function()
		local seen = 0
		for _, def in Catalog.workplaces() do
			seen += 1
			local s = PlayerWork.stance(def)
			local loop = Routine.loop(def)
			local home = loop[Routine.home(loop)]
			-- the workplace's own work spot, as the villagers use it
			expect(near(s.at, home.at)).toBeTruthy()
			expect(near(s.at, def.workSpot or Vector3.new(0, 0, -(def.size.Z / 2 + 1.5)))).toBeTruthy()
			if not MOTIONS[s.act] then
				error(def.id .. ": no body has a motion called " .. tostring(s.act))
			end
			expect(s.beat >= 0.5).toBeTruthy()
			-- stood a little off the floor (the root over the feet) and looking flat at the work
			local cf = PlayerWork.standFrame(CFrame.new(), s, 3)
			expect(near(cf.Position, s.at + Vector3.new(0, 3, 0))).toBeTruthy()
			expect(math.abs(cf.LookVector.Y) < 1e-3).toBeTruthy()
			local want = Vector3.new(s.look.X - s.at.X, 0, s.look.Z - s.at.Z)
			if want.Magnitude > 1e-3 then
				expect(cf.LookVector:Dot(want.Unit) > 0.999).toBeTruthy()
			end
		end
		expect(seen >= #Jobs.list).toBeTruthy()
		-- the builder hammers at the bench, facing it (workYaw 180: toward -Z, from in front of it)
		local bench = PlayerWork.stance(Catalog.get("work_builder"))
		expect(bench.act).toBe("toolslash")
		expect(bench.beat).toBeNear(2.2)
		expect(PlayerWork.standFrame(CFrame.new(), bench, 3).LookVector.Z < -0.99).toBeTruthy()
		-- the artist paints, the musician dances; a job with nothing at its spot gets the plain motion
		expect(PlayerWork.stance(Catalog.get("work_easel")).act).toBe("point")
		expect(PlayerWork.stance(Catalog.get("work_stage")).act).toBe("dance")
		local florist = PlayerWork.stance(Catalog.get("work_flowers"))
		expect(florist.act).toBe(K.Act)
		expect(florist.beat).toBe(K.Beat)
		-- and where the workplace stands and how it is turned carries them with it
		local frame = CFrame.new(40, 0.4, 70) * CFrame.Angles(0, math.rad(90), 0)
		local cf = PlayerWork.standFrame(frame, bench, 3)
		expect(near(cf.Position, frame * bench.at + Vector3.new(0, 3, 0))).toBeTruthy()
		expect(cf.LookVector:Dot(frame:VectorToWorldSpace(Vector3.new(0, 0, -1))) > 0.99).toBeTruthy()
		-- how far a body is from where it was stood: across, and up or down
		local off, rise = PlayerWork.offset(Vector3.new(1, 3, 1), Vector3.new(4, 5, 5))
		expect(off).toBeNear(5)
		expect(rise).toBeNear(2)
	end)

	it("pays a share of a new villager's rate, in whole coins, never past the day's cap", function()
		for _, def in Catalog.workplaces() do
			local job = Jobs.get(def.job)
			local rate = PlayerWork.rate(def)
			expect(rate).toBeNear(Jobs.pay(job, 1, 50, "none") * K.Share / City.workSeconds())
			-- well under what the villager who works there earns, even one just moved in
			expect(rate <= Jobs.pay(job, 1, START, "none") / City.workSeconds() / 2).toBeTruthy()
		end
		expect(PlayerWork.rate({ job = "nobody" })).toBe(0)
		expect(PlayerWork.rate(nil)).toBe(0)
		-- a look every Check seconds: whole coins as they fill, the parts of one kept for later
		local def = Catalog.get("work_market")
		local rate = PlayerWork.rate(def)
		local profile = Schema.newProfile()
		local purse = PlayerWork.purse(profile, 7)
		local got, seconds = 0, 0
		while seconds < 20 - 1e-9 do
			local coins = PlayerWork.earn(purse, 7, rate, K.Check)
			expect(coins == math.floor(coins) and coins >= 0).toBeTruthy()
			got += coins
			seconds += K.Check
		end
		expect(got).toBeBetween(math.floor(rate * 20) - 1, math.floor(rate * 20))
		expect(purse.paid).toBe(got)
		expect(profile.work).toBe(purse)
		-- on and on: the day's cap and not a coin more
		for _ = 1, 4000 do
			got += PlayerWork.earn(purse, 7, rate, K.Check)
		end
		expect(got).toBe(K.DayCap)
		expect(purse.paid).toBe(K.DayCap)
		expect(PlayerWork.full(purse)).toBe(true)
		expect(PlayerWork.earn(purse, 7, rate, 1000)).toBe(0)
		-- the next town day starts again
		expect(PlayerWork.earn(purse, 8, rate, 10) > 0).toBeTruthy()
		expect(PlayerWork.full(purse)).toBe(false)
		-- nothing for no time, no rate, or numbers that aren't numbers
		local before = purse.paid
		for _, bad in { 0, -5, 0 / 0, math.huge, -math.huge } do
			expect(PlayerWork.earn(purse, 8, rate, bad)).toBe(0)
			expect(PlayerWork.earn(purse, 8, bad, 1)).toBe(0)
		end
		expect(purse.paid).toBe(before)
	end)

	it("keeps the day's purse on the profile, and starts a broken one fresh", function()
		-- a new profile has one, and an old save gets one when it loads
		local p = Schema.newProfile()
		expect(type(p.work)).toBe("table")
		p.work = nil
		local loaded = Schema.migrate(p)
		expect(type(loaded.work)).toBe("table")
		expect(PlayerWork.full(PlayerWork.purse(loaded, 3))).toBe(false)
		-- leaving and coming back the same day finds it as it was
		local purse = PlayerWork.purse(loaded, 3)
		PlayerWork.earn(purse, 3, 100, 1)
		expect(PlayerWork.purse(loaded, 3).paid).toBe(100)
		expect(PlayerWork.purse(Schema.migrate(loaded), 3).paid).toBe(100)
		-- a new day empties it
		expect(PlayerWork.purse(loaded, 4).paid).toBe(0)
		-- broken data starts fresh and can't be used to earn past the cap
		for _, broken in {
			"lots",
			{ day = 3, owed = 0, paid = -1e9 },
			{ day = 3, owed = 0 / 0, paid = 0 },
			{ day = "3", owed = 0, paid = 0 },
		} do
			local q = Schema.newProfile()
			q.work = broken
			local fresh = PlayerWork.purse(q, 3)
			expect(fresh.paid).toBe(0)
			expect(fresh.owed).toBe(0)
			expect(q.work).toBe(fresh)
		end
	end)

	it("keeps a player's own work small beside the town's wages", function()
		-- The user asked that "progression is much more based on villagers working". A player
		-- earns a third or so of a new villager's rate, and only up to a cap a town day.
		expect(K.Share > 0 and K.Share <= 0.5).toBeTruthy()
		local least, best, worst = math.huge, 0, math.huge
		for _, job in Jobs.list do
			least = math.min(least, Jobs.pay(job, 1, START, "none"))
		end
		for _, def in Catalog.workplaces() do
			best = math.max(best, PlayerWork.rate(def))
			worst = math.min(worst, PlayerWork.rate(def))
		end
		-- A day at the cap is at most a quarter of what the least paid villager earns in one. The
		-- City spec holds wages to four fifths of a keen player's coins in a town of three with
		-- two at work, and finds everything else such a player collects at about an eighth of
		-- the two workers' wages; a quarter of one wage on top still leaves them over four fifths.
		expect(K.DayCap <= least / 4).toBeTruthy()
		expect(2 * least / (2 * least + 2 * least / 8 + K.DayCap) >= 0.8).toBeTruthy()
		-- and the daily gift, a welcome, is about what a day of your own work comes to
		expect(K.DayCap <= Tuning.Economy.DailyGift * 1.5).toBeTruthy()
		-- the cap is a real stint of work: over a minute at the best paid workplace, and inside the
		-- work day at the least paid (a town day is 12 minutes)
		expect(K.DayCap / best >= 60).toBeTruthy()
		expect(K.DayCap / worst <= City.workDay()).toBeTruthy()
		-- the checks are often enough to catch a walk off, and the settling short
		expect(K.Check <= 0.5).toBeTruthy()
		expect(K.Settle <= 2).toBeTruthy()
		expect(K.Reach > K.Distance).toBeTruthy()
		expect(K.Leave < K.Distance).toBeTruthy()
	end)

	it("knows whose working day it is at a workplace", function()
		local p = Schema.newProfile()
		p.villagers.v1 = { name = "Mara", job = "7" }
		p.villagers.v2 = { name = "Tobin", job = "9" }
		p.order = { "v1", "v2" }
		local now = 100000
		expect(PlayerWork.staffedBy(p, "7", D.WorkStart - 0.01, 5, now)).toBe(nil)
		expect(PlayerWork.staffedBy(p, "7", D.WorkStart, 5, now)).toBe("Mara")
		expect(PlayerWork.staffedBy(p, "7", D.WorkEnd - 0.01, 5, now)).toBe("Mara")
		expect(PlayerWork.staffedBy(p, "7", D.WorkEnd, 5, now)).toBe(nil)
		expect(PlayerWork.staffedBy(p, "9", 12, 5, now)).toBe("Tobin")
		expect(PlayerWork.staffedBy(p, "8", 12, 5, now)).toBe(nil)
		-- not on their day off, nor while sick; well again, it's theirs again
		p.villagers.v1.dayOff = 5
		expect(PlayerWork.staffedBy(p, "7", 12, 5, now)).toBe(nil)
		expect(PlayerWork.staffedBy(p, "7", 12, 6, now)).toBe("Mara")
		p.villagers.v1.sick = now + 50
		expect(PlayerWork.staffedBy(p, "7", 12, 6, now)).toBe(nil)
		expect(PlayerWork.staffedBy(p, "7", 12, 6, now + 60)).toBe("Mara")
		-- the client's copy of the town before it has loaded
		expect(PlayerWork.staffedBy({}, "7", 12, 6, now)).toBe(nil)
	end)

	it("says plainly who may start, and why not", function()
		local ok = { job = true, own = true, distance = 4 }
		expect(PlayerWork.canStart(ok)).toBe(true)
		local function why(change)
			local ask = table.clone(ok)
			for k, v in change do
				ask[k] = v
			end
			local yes, text = PlayerWork.canStart(ask)
			expect(yes).toBe(false)
			return text
		end
		expect(why({ job = false })).toBe("That isn't a workplace.")
		expect(why({ own = false })).toBe("You can only work in your own town.")
		expect(why({ distance = K.Reach + 1 })).toBe("Come a bit closer to work here.")
		expect(why({ distance = 0 / 0 })).toBe("Come a bit closer to work here.")
		expect(why({ staff = "Mara" })).toBe("Mara works here until 5:00 PM.")
		expect(why({ taken = true })).toBe("Someone else is working here.")
		expect(why({ full = true })).toBe("That's a full day's work. You can work again from 9:00 AM.")
		expect(why({ seated = true })).toBe("Stand up first.")
		-- every word a player can be shown keeps to the writing rule: plain, no dashes, no shouting
		local all = { PlayerWork.Action, PlayerWork.StopAction }
		for _, text in PlayerWork.Say do
			table.insert(all, text)
		end
		for _, text in all do
			if text:find("\u{2014}") or text:find("\u{2013}") or text:find(" %- ") or text:find("!") then
				error("not plain: " .. text)
			end
			expect(#text <= 70).toBeTruthy()
		end
	end)

	it("stops by itself for the right reasons, and only says so when it wasn't the player's doing", function()
		local fine = { here = true, off = 0.5, rise = 0.2, piece = "same" }
		expect(PlayerWork.stopWhy(fine)).toBe(nil)
		local function stop(change)
			local w = table.clone(fine)
			for k, v in change do
				w[k] = v
			end
			return PlayerWork.stopWhy(w)
		end
		local function check(change, reason, say)
			local r, s = stop(change)
			expect(r).toBe(reason)
			expect(s).toBe(say)
		end
		check({ here = false }, "left", nil)
		check({ piece = "gone" }, "gone", "Your workplace is gone, so you stopped work.")
		check({ piece = "moved" }, "moved", "Your workplace moved, so you stopped work.")
		check({ seated = true }, "seated", nil)
		check({ off = K.Leave + 0.5 }, "walked", nil)
		check({ rise = K.Rise + 1 }, "walked", nil)
		check({ rise = -(K.Rise + 1) }, "walked", nil)
		check({ off = 0 / 0 }, "walked", nil)
		check({ staff = "Mara" }, "staffed", "Mara is here for work, so you stepped aside.")
		check({ full = true }, "full", "That's a full day's work. You can work again from 9:00 AM.")
		-- just stood there, the body may not have caught up yet: not taken for a walk off
		expect(stop({ off = 6, settling = true })).toBe(nil)
		-- but a piece that went, or a player who left, ends it even then
		expect(stop({ off = 6, settling = true, piece = "gone" })).toBe("gone")
		expect(stop({ here = false, settling = true })).toBe("left")
	end)
end)
