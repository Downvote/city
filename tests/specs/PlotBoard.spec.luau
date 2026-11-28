--!nocheck
-- Other players' towns, by the rules the server keeps them to (the user: "allow players to like
-- other plots. make a leaderboard for likes with plots. allow players to visit plots searching by
-- name, sort by likes or by recency, allowing them to view a copy of the town they are visiting and
-- like it, even if the player owning the plot is offline"): one like a player a town and never on
-- their own (Sim/PlotLikes), the directory's cards, its two orders, ranks, search and pages and the
-- keys the name search finds a town by (Sim/PlotBoard), and what a copy of a town is drawn from
-- (Sim/PlotCopy).

local Shared = "ReplicatedStorage.Shared."
local PlotLikes = require(Shared .. "Sim.PlotLikes")
local PlotBoard = require(Shared .. "Sim.PlotBoard")
local PlotCopy = require(Shared .. "Sim.PlotCopy")
local Schema = require(Shared .. "Sim.Schema")
local Plan = require(Shared .. "Build.Plan")
local City = require(Shared .. "Sim.City")
local StarterHouse = require(Shared .. "Data.StarterHouse")
local Appearance = require(Shared .. "Avatar.Appearance")
local Rng = require(Shared .. "Util.Rng")
local Tuning = require(Shared .. "Config.Tuning")

local function card(id, name, who, likes, at)
	return PlotBoard.card({ name = name, who = who, likes = likes, at = at }, id)
end

local function ids(list)
	local out = {}
	for _, c in list do
		table.insert(out, c.id)
	end
	return table.concat(out, " ")
end

describe("PlotLikes", function()
	it("likes a town once, and a second press takes the like back", function()
		local liked = {}
		local on, d = PlotLikes.set(liked, 1, 22, nil, 100, 10)
		expect(on).toBe(true)
		expect(d).toBe(1)
		expect(PlotLikes.has(liked, 22)).toBe(true)
		-- liking again what is liked changes nothing
		on, d = PlotLikes.set(liked, 1, 22, true, 101, 10)
		expect(on).toBe(true)
		expect(d).toBe(0)
		on, d = PlotLikes.set(liked, 1, 22, nil, 102, 10)
		expect(on).toBe(false)
		expect(d).toBe(-1)
		expect(PlotLikes.has(liked, 22)).toBe(false)
		-- and taking back what isn't liked changes nothing either
		on, d = PlotLikes.set(liked, 1, 22, false, 103, 10)
		expect(on).toBe(false)
		expect(d).toBe(0)
	end)

	it("never likes your own town, or something that isn't a user id", function()
		local liked = {}
		local on, d, why = PlotLikes.set(liked, 5, 5, true, 100, 10)
		expect(on).toBe(false)
		expect(d).toBe(0)
		expect(type(why)).toBe("string")
		for _, bad in { 0, -3, 1.5, 0 / 0, math.huge, "7", {} } do
			local _, d2, why2 = PlotLikes.set(liked, 5, bad, true, 100, 10)
			expect(d2).toBe(0)
			expect(type(why2)).toBe("string")
		end
		expect(next(liked)).toBe(nil)
	end)

	it("waits for a like to be taken back once a player likes as many as they may", function()
		local liked = {}
		for id = 10, 12 do
			PlotLikes.set(liked, 1, id, true, 100, 3)
		end
		local on, d, why = PlotLikes.set(liked, 1, 13, true, 100, 3)
		expect(on).toBe(false)
		expect(d).toBe(0)
		expect(type(why)).toBe("string")
		-- none forgotten, so none can be given twice
		expect(PlotLikes.size(liked)).toBe(3)
		PlotLikes.set(liked, 1, 11, false, 100, 3)
		on, d = PlotLikes.set(liked, 1, 13, true, 100, 3)
		expect(on).toBe(true)
		expect(d).toBe(1)
	end)

	it("keeps only well formed likes from a save", function()
		local raw = { ["12"] = 100, ["0"] = 5, ["-4"] = 5, x = 1, ["13"] = "no", ["14"] = 0 / 0, ["15"] = 3.7 }
		raw[16] = 1
		local clean = PlotLikes.clean(raw, 10)
		expect(clean["12"]).toBe(100)
		expect(clean["15"]).toBe(3)
		expect(PlotLikes.size(clean)).toBe(2)
		expect(PlotLikes.size(PlotLikes.clean("nope", 10))).toBe(0)
		local many = {}
		for i = 1, 30 do
			many[tostring(i)] = i
		end
		expect(PlotLikes.size(PlotLikes.clean(many, 20))).toBe(20)
	end)

	it("adds up the changes waiting to be written, and puts back a batch that didn't go in", function()
		local pending = {}
		PlotLikes.add(pending, 7, 1)
		PlotLikes.add(pending, 7, 1)
		PlotLikes.add(pending, 8, 1)
		PlotLikes.add(pending, 8, -1)
		expect(pending["7"]).toBe(2)
		expect(pending["8"]).toBe(nil)
		expect(PlotLikes.count(5, pending, 7)).toBe(7)
		expect(PlotLikes.count(0, { ["7"] = -3 }, 7)).toBe(0)
		local batch = PlotLikes.take(pending)
		expect(next(pending)).toBe(nil)
		expect(batch["7"]).toBe(2)
		PlotLikes.add(pending, 7, 1) -- (one more came while the write was out)
		PlotLikes.giveBack(pending, batch)
		expect(pending["7"]).toBe(3)
	end)
end)

describe("PlotBoard", function()
	it("makes a card safe, whatever a store or a client holds", function()
		local c =
			PlotBoard.card({ name = "  Juniper\nBay ", who = "Sam", likes = 4.6, at = -5, level = 0, people = "x" }, 99)
		expect(c.id).toBe(99)
		expect(c.name).toBe("Juniper Bay")
		expect(c.who).toBe("Sam")
		expect(c.likes).toBe(4)
		expect(c.at).toBe(0)
		expect(c.level).toBe(1)
		expect(c.people).toBe(0)
		expect(PlotBoard.card(nil, 99)).toBe(nil)
		expect(PlotBoard.card({ name = "x" })).toBe(nil) -- (no owner)
		expect(PlotBoard.card({ name = "x", id = 0 })).toBe(nil)
		expect(PlotBoard.card({ name = string.rep("a", 80) }, 3).name).toBe(string.rep("a", Tuning.PlotName.MaxLength))
	end)

	it("calls a town by its name, or its owner's", function()
		expect(PlotBoard.title(card(1, "Juniper Bay", "Sam"))).toBe("Juniper Bay")
		expect(PlotBoard.title(card(1, "", "Sam"))).toBe("Sam's town")
		expect(PlotBoard.title(card(1, "", ""))).toBe("A town")
		expect(PlotBoard.sign("Juniper Bay", "Sam")).toBe("Juniper Bay\nSam's place")
		expect(PlotBoard.sign("", "Sam")).toBe("Sam's\nplace")
	end)

	it("sorts by likes, then the newest, or the newest first", function()
		local list = {
			card(1, "A", "a", 3, 100),
			card(2, "B", "b", 9, 50),
			card(3, "C", "c", 3, 300),
			card(4, "D", "d", 0, 400),
		}
		expect(ids(PlotBoard.sorted(list, "likes"))).toBe("2 3 1 4")
		expect(ids(PlotBoard.sorted(list, "new"))).toBe("4 3 1 2")
		-- likes this server hasn't written yet count
		expect(ids(PlotBoard.sorted(list, "likes", { ["4"] = 12 }))).toBe("4 2 3 1")
		-- (the list it was given is left as it was)
		expect(ids(list)).toBe("1 2 3 4")
		expect(PlotBoard.sortOf("new")).toBe("new")
		expect(PlotBoard.sortOf("anything")).toBe("likes")
		expect(PlotBoard.sortOf(nil)).toBe("likes")
	end)

	it("gives towns with the same likes the same place", function()
		local list = PlotBoard.sorted({
			card(1, "A", "a", 9, 1),
			card(2, "B", "b", 5, 2),
			card(3, "C", "c", 5, 3),
			card(4, "D", "d", 2, 4),
		}, "likes")
		expect(table.concat(PlotBoard.ranks(list), " ")).toBe("1 2 2 4")
	end)

	it("searches by the town's name or its owner's", function()
		local list = { card(1, "Juniper Bay", "Sam"), card(2, "", "Juno"), card(3, "Old Mill", "Pat") }
		expect(ids(PlotBoard.search(list, "bay"))).toBe("1")
		expect(ids(PlotBoard.search(list, "JUN"))).toBe("1 2")
		expect(ids(PlotBoard.search(list, "pat"))).toBe("3")
		expect(ids(PlotBoard.search(list, "juno's town"))).toBe("2")
		expect(ids(PlotBoard.search(list, "  "))).toBe("1 2 3")
		expect(ids(PlotBoard.search(list, "zzz"))).toBe("")
	end)

	it("puts lists together with each town once, and pages them", function()
		local merged = PlotBoard.merge(
			{ card(1, "A", "a"), card(2, "B", "b") },
			{ card(2, "Other", "b"), card(3, "C", "c") }
		)
		expect(ids(merged)).toBe("1 2 3")
		expect(merged[2].name).toBe("B")
		local many = {}
		for i = 1, 45 do
			table.insert(many, i)
		end
		local first, more = PlotBoard.page(many, 1, 20)
		expect(#first).toBe(20)
		expect(more).toBe(true)
		local last, more3 = PlotBoard.page(many, 3, 20)
		expect(#last).toBe(5)
		expect(last[1]).toBe(41)
		expect(more3).toBe(false)
		local junk = PlotBoard.page(many, "x", 20)
		expect(junk[1]).toBe(1)
	end)

	it("keeps a town under a key for each word its name starts from, and its owner's name", function()
		local keys = PlotBoard.nameKeys("Juniper Bay Farm", "Sam", 123, 4)
		expect(table.concat(keys, ",")).toBe("juniper bay farm/123,bay farm/123,farm/123,sam/123")
		-- marks and apostrophes as the keys keep them
		expect(table.concat(PlotBoard.nameKeys("Sam's Place!", "Sam", 5, 4), ",")).toBe("sams place/5,place/5,sam/5")
		-- no name: the owner's alone
		expect(table.concat(PlotBoard.nameKeys("", "Sam", 5, 4), ",")).toBe("sam/5")
		-- only so many words in, and each key short enough for the store
		local long = PlotBoard.nameKeys("a b c d e f g", "x", 9999999999, 4)
		expect(#long).toBe(5)
		for _, k in PlotBoard.nameKeys(string.rep("w", 24), string.rep("v", 40), 99999999999, 4) do
			expect(#k <= 50).toBe(true)
			expect(PlotBoard.idOfKey(k)).toBe(99999999999)
		end
		expect(PlotBoard.idOfKey("bay/12")).toBe(12)
		expect(PlotBoard.idOfKey("bay")).toBe(nil)
		expect(PlotBoard.idOfKey("bay/0")).toBe(nil)
		expect(PlotBoard.idOfKey(12)).toBe(nil)
	end)

	it("finds a town by the start of a word as the search asks the store", function()
		local keys = PlotBoard.nameKeys("Juniper Bay", "Sam", 7, 4)
		local function found(typed)
			local p = PlotBoard.prefix(typed)
			for _, k in keys do
				if p ~= "" and k:sub(1, #p) == p then
					return true
				end
			end
			return false
		end
		expect(found("Juniper")).toBe(true)
		expect(found("  BAY ")).toBe(true)
		expect(found("juniper b")).toBe(true)
		expect(found("sa")).toBe(true)
		expect(found("nip")).toBe(false)
		expect(PlotBoard.prefix("")).toBe("")
		expect(PlotBoard.prefix({})).toBe("")
	end)

	it("knows which keys to take away and which to add when a name changes", function()
		local gone, added = PlotBoard.changes({ "old mill/1", "mill/1", "pat/1" }, { "new mill/1", "mill/1", "pat/1" })
		expect(table.concat(gone, ",")).toBe("old mill/1")
		expect(table.concat(added, ",")).toBe("new mill/1")
		local keys = PlotBoard.cleanKeys({ "a/1", 4, "bad", string.rep("x", 60) .. "/1", "b/2" }, 5)
		expect(table.concat(keys, ",")).toBe("a/1,b/2")
	end)

	it("loads an old save with no likes or listing, and keeps what a save has", function()
		local old = Schema.newProfile()
		old.likedPlots, old.plotKeys, old.plotAt = nil, nil, nil
		local p = Schema.migrate(old)
		expect(type(p.likedPlots)).toBe("table")
		expect(#p.plotKeys).toBe(0)
		expect(p.plotAt).toBe(0)
		local kept = Schema.newProfile()
		kept.likedPlots = { ["44"] = 1000 }
		kept.plotKeys = { "bay/9" }
		kept.plotAt = 1234
		kept = Schema.migrate(kept)
		expect(kept.likedPlots["44"]).toBe(1000)
		expect(kept.plotKeys[1]).toBe("bay/9")
		expect(kept.plotAt).toBe(1234)
	end)
end)

describe("PlotCopy", function()
	local function town()
		local profile = Schema.newProfile()
		profile.plan = StarterHouse.plan()
		for i, name in { "Mara", "Tobin", "Ivy" } do
			local input = Schema.cleanVillagerInput({ name = name, pers = "sunny", app = Appearance.default() })
			profile.villagers["v" .. i] = Schema.newVillager("v" .. i, input, Rng.new(i))
			table.insert(profile.order, "v" .. i)
		end
		profile.villagers.v1.job = City.freeWorkplace(profile)
		return profile
	end

	it("draws the saved plan less the basement", function()
		local profile = town()
		local plan = profile.plan
		plan.floors["900"] = { x1 = 160, z1 = 120, x2 = 180, z2 = 140, lv = -1, c = "Light stone grey", m = "Concrete" }
		local copy = PlotCopy.plan(plan)
		expect(copy.floors["900"]).toBe(nil)
		local any = 0
		for _, kind in Plan.Kinds do
			for _, obj in copy[kind] do
				expect(obj.lv >= 0).toBe(true)
				any += 1
			end
		end
		expect(any > 20).toBe(true)
		-- something that isn't a plan is an empty one
		expect(next(PlotCopy.plan("nope").items)).toBe(nil)
	end)

	it("stands it on a piece of ground round the land, cut round its water", function()
		local profile = town()
		profile.plan.waters["990"] = { x1 = 262, z1 = 150, x2 = 278, z2 = 166, lv = 0, edge = "tile", depth = "swim" }
		local plan = PlotCopy.plan(profile.plan)
		expect(plan.waters["990"] ~= nil).toBe(true)
		local ground = PlotCopy.ground(plan, 16)
		local x1, z1 = Plan.bounds(plan)
		local top, covers, under = nil, false, false
		for _, p in ground do
			local c, s = p.cf.Position, p.size
			local px1, px2, pz1, pz2 = c.X - s.X / 2, c.X + s.X / 2, c.Z - s.Z / 2, c.Z + s.Z / 2
			if p.name == "Ground" then
				top = c.Y + s.Y / 2
				-- (the grass reaches the margin past the land)
				covers = covers or (px1 <= x1 - 16 + 1e-6 and pz1 <= z1 - 16 + 1e-6)
			end
			-- nothing covers the pool's middle
			if px1 < 270 and px2 > 270 and pz1 < 158 and pz2 > 158 then
				under = true
			end
			expect(c.Y + s.Y / 2 <= -0.1 + 1e-6).toBe(true)
		end
		expect(top).toBeNear(-0.1)
		expect(covers).toBe(true)
		expect(under).toBe(false)
	end)

	it("stands a worker at their workplace and the rest in a row on the front lawn", function()
		local profile = town()
		local plan = PlotCopy.plan(profile.plan)
		local list = PlotCopy.villagers(profile, plan, 8)
		expect(#list).toBe(3)
		local byVid = {}
		for _, s in list do
			byVid[s.vid] = s
		end
		-- the worker: on their workplace's own spot, near the piece
		local job = profile.plan.items[profile.villagers.v1.job]
		local at = byVid.v1.at.Position
		expect((Vector3.new(at.X, 0, at.Z) - Vector3.new(job.x, 0, job.z)).Magnitude < 12).toBe(true)
		-- the others side by side at the front, facing the street
		local a, b = byVid.v2.at, byVid.v3.at
		expect(a.Position.Z).toBe(PlotCopy.FrontZ)
		expect(math.abs(a.Position.X - b.Position.X)).toBeNear(PlotCopy.Spacing)
		expect(a.LookVector.Z).toBeNear(-1)
		local x1, _, x2 = Plan.bounds(plan)
		expect(a.Position.X).toBeBetween(x1, x2)
		expect(byVid.v2.name).toBe("Tobin")
	end)

	it("stands no more than it may, in the town's own order, and leaves out one with no look", function()
		local profile = town()
		local plan = PlotCopy.plan(profile.plan)
		local two = PlotCopy.villagers(profile, plan, 2)
		expect(#two).toBe(2)
		profile.villagers.v2.app = nil
		local list = PlotCopy.villagers(profile, plan, 8)
		expect(#list).toBe(2)
		for _, s in list do
			expect(s.vid ~= "v2").toBe(true)
		end
		expect(#PlotCopy.villagers({}, plan, 8)).toBe(0)
	end)
end)
