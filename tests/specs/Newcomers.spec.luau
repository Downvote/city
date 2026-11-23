--!nocheck
-- Who moves in from the road (Sim/Newcomers): the player's friends first, then the town's own
-- newcomers, and nobody twice. The user: "make the random villagers that move in the player's
-- friends first, then default ones if all of them are already in. no repeats".

local Shared = "ReplicatedStorage.Shared."
local Tuning = require(Shared .. "Config.Tuning")
local Schema = require(Shared .. "Sim.Schema")
local Newcomers = require(Shared .. "Sim.Newcomers")
local EventEngine = require(Shared .. "Sim.EventEngine")
local Appearance = require(Shared .. "Avatar.Appearance")
local Personalities = require(Shared .. "Data.Personalities")
local Rng = require(Shared .. "Util.Rng")

local FRIENDS = {
	{ id = 101, name = "Ada" },
	{ id = 102, name = "Bo" },
	{ id = 103, name = "Cy" },
}

local function moveIn(p, pick, rng)
	local vid = "v" .. p.nextVid
	p.nextVid += 1
	local input = Schema.cleanVillagerInput({ name = pick.name, pers = "sunny", app = Appearance.default() })
	local v = Schema.newVillager(vid, input, rng)
	Newcomers.arrive(p, v, pick.key)
	p.villagers[vid] = v
	table.insert(p.order, vid)
	return vid
end

local function moveOut(p, vid)
	p.villagers[vid] = nil
	table.remove(p.order, table.find(p.order, vid))
end

describe("Newcomers", function()
	it("brings every friend in before anyone else", function()
		for seed = 1, 20 do
			local rng = Rng.new(seed)
			local p = Schema.newProfile()
			local came = {}
			for _ = 1, #FRIENDS do
				local pick = Newcomers.next(p, FRIENDS, rng)
				expect(pick.userId ~= nil).toBeTruthy()
				expect(came[pick.key]).toBe(nil)
				came[pick.key] = true
				moveIn(p, pick, rng)
			end
			local after = Newcomers.next(p, FRIENDS, rng)
			expect(after.userId).toBe(nil)
			expect(after.own ~= nil).toBeTruthy()
		end
	end)

	it("never brings the same one twice", function()
		local rng = Rng.new(7)
		local p = Schema.newProfile()
		local keys, names = {}, {}
		for _ = 1, Tuning.Villagers.Max do
			local pick = Newcomers.next(p, FRIENDS, rng)
			expect(pick ~= nil).toBeTruthy()
			expect(keys[pick.key]).toBe(nil)
			expect(names[pick.name]).toBe(nil)
			expect(Newcomers.inTown(p, pick.key)).toBe(false)
			keys[pick.key] = true
			names[pick.name] = true
			moveIn(p, pick, rng)
			expect(Newcomers.inTown(p, pick.key)).toBe(true)
		end
	end)

	it("keeps someone who moved out away until everyone has had a turn", function()
		local rng = Rng.new(3)
		local p = Schema.newProfile()
		local first = Newcomers.next(p, FRIENDS, rng)
		local vid = moveIn(p, first, rng)
		moveOut(p, vid)
		local seen = {}
		local total = #FRIENDS - 1 + #Newcomers.list
		for _ = 1, total do
			local pick = Newcomers.next(p, FRIENDS, rng)
			expect(pick.key ~= first.key).toBeTruthy()
			expect(seen[pick.key]).toBe(nil)
			seen[pick.key] = true
			-- they move in and out again, so the town never fills
			moveOut(p, moveIn(p, pick, rng))
		end
		-- now everybody has been: a friend may come back, friends before the town's own
		local back = Newcomers.next(p, FRIENDS, rng)
		expect(back.userId ~= nil).toBeTruthy()
	end)

	it("has nobody left when everyone is in town", function()
		local rng = Rng.new(5)
		local p = Schema.newProfile()
		for _ = 1, #FRIENDS + #Newcomers.list do
			moveIn(p, Newcomers.next(p, FRIENDS, rng), rng)
		end
		expect(Newcomers.next(p, FRIENDS, rng)).toBe(nil)
	end)

	it("skips friends it can't name, and the same friend listed twice", function()
		local rng = Rng.new(2)
		local p = Schema.newProfile()
		local odd = {
			{ id = 0, name = "Nobody" },
			{ id = 5, name = string.rep("x", Tuning.Villagers.NameMaxLength + 1) },
			{ id = 6, name = "" },
			{ id = 7, name = "Dee" },
			{ id = 7, name = "Dee" },
			"junk",
		}
		local pick = Newcomers.next(p, odd, rng)
		expect(pick.key).toBe(Newcomers.friendKey(7))
		moveIn(p, pick, rng)
		expect(Newcomers.next(p, odd, rng).own ~= nil).toBeTruthy()
	end)

	it("leaves out a newcomer whose name a villager already has", function()
		local rng = Rng.new(4)
		local p = Schema.newProfile()
		local input = Schema.cleanVillagerInput({ name = "pip", pers = "sunny", app = Appearance.default() })
		p.villagers.v1 = Schema.newVillager("v1", input, rng)
		p.order = { "v1" }
		for _ = 1, 200 do
			expect(Newcomers.next(p, {}, rng).name ~= "Pip").toBeTruthy()
		end
	end)

	it("gives the town's own newcomers names, natures and looks of their own", function()
		local ids, names, looks = {}, {}, {}
		expect(#Newcomers.list >= Tuning.Villagers.Max).toBeTruthy()
		for _, e in Newcomers.list do
			expect(ids[e.id]).toBe(nil)
			expect(names[e.name]).toBe(nil)
			ids[e.id] = true
			names[e.name] = true
			expect(Newcomers.cleanName(e.name)).toBe(e.name)
			expect(Personalities.get(e.pers) ~= nil).toBeTruthy()
			expect(Newcomers.own(Newcomers.ownKey(e.id))).toBe(e)
			local look = string.format("%d %d %d %d", e.hair, e.hat, e.shirt, e.pants)
			expect(looks[look]).toBe(nil)
			looks[look] = true
			local app = Newcomers.look(e)
			expect(app.shirt).toBe(e.shirt)
			expect(app.pants).toBe(e.pants)
			expect(app.colors.head).toBe(e.skin)
			expect(#app.acc).toBe((if e.hair > 0 then 1 else 0) + (if e.hat > 0 then 1 else 0))
			expect(e.hair > 0 or e.hat > 0).toBeTruthy()
		end
	end)

	it("reads its keys back", function()
		expect(Newcomers.userId(Newcomers.friendKey(123456789012))).toBe(123456789012)
		expect(Newcomers.userId("d:pip")).toBe(nil)
		expect(Newcomers.userId(42)).toBe(nil)
		expect(Newcomers.own("u12")).toBe(nil)
		expect(Newcomers.own("d:nobody")).toBe(nil)
	end)

	it("only offers a visitor once the friends list is known, and names the friend", function()
		local rng = Rng.new(11)
		local p = Schema.newProfile()
		local function context(friends)
			return EventEngine.context(p, {
				now = 1000,
				hour = 12,
				season = 1,
				dayOfSeason = 99,
				day = 5,
				weather = "clear",
				rng = rng,
				present = {},
				freeSlots = 4,
				friends = friends,
			})
		end
		for _ = 1, 60 do
			local ev = EventEngine.pick(context(nil), {})
			expect(ev == nil or ev.id ~= "visitor").toBeTruthy()
		end
		local found = false
		for _ = 1, 200 do
			local ev = EventEngine.pick(context(FRIENDS), {})
			if ev and ev.id == "visitor" then
				found = true
				local welcome = ev.scene.choices[1]
				local effect = welcome.effects[1]
				expect(effect.t).toBe("visitor")
				expect(Newcomers.userId(effect.key) ~= nil).toBeTruthy()
				expect(ev.scene.lines[1].text:find("Your friend " .. effect.name, 1, true) ~= nil).toBeTruthy()
			end
		end
		expect(found).toBe(true)
	end)
end)
