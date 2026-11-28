--!nocheck
-- Build mode pieces bought with gems (Sim/GemPieces; the user: "also, add a fog machine that
-- players can place with gems"): what a change costs, what the player owns after, what a saved
-- build may bring back, and what a save keeps. The Build service's side is in BuildService.spec.

local Shared = "ReplicatedStorage.Shared."
local GemPieces = require(Shared .. "Sim.GemPieces")
local Catalog = require(Shared .. "Build.Catalog")
local Tuning = require(Shared .. "Config.Tuning")

local FOG = "anim_fog_machine"

local function add(id)
	return { type = "add", kind = "items", obj = { id = id, x = 10, y = 0, z = 10, r = 0, lv = 0 } }
end

describe("Gem pieces", function()
	it("price the fog machine in gems and nothing in coins", function()
		local def = Catalog.get(FOG)
		expect(def ~= nil).toBeTruthy()
		expect(GemPieces.price(FOG) > 0).toBeTruthy()
		expect(def.price).toBe(0)
		expect(GemPieces.price("sofa_three")).toBe(nil)
		expect(GemPieces.price(42)).toBe(nil)
	end)

	it("charge only for the ones that go down past what is owned", function()
		local price = GemPieces.price(FOG)
		local profile = { plan = { items = {} }, gemItems = {} }
		local gems, buys = GemPieces.need(profile, { add(FOG), add(FOG), add("sofa_three") })
		expect(gems).toBe(price * 2)
		expect(buys[FOG]).toBe(2)
		GemPieces.buy(profile, buys)
		expect(GemPieces.owned(profile, FOG)).toBe(2)
		-- one already owned and not down goes down for nothing
		profile.plan.items["1"] = { id = FOG, x = 1, y = 0, z = 1, r = 0, lv = 0 }
		expect((GemPieces.need(profile, { add(FOG) }))).toBe(0)
		profile.plan.items["2"] = { id = FOG, x = 3, y = 0, z = 1, r = 0, lv = 0 }
		expect((GemPieces.need(profile, { add(FOG) }))).toBe(price)
		-- one taken away in the same change makes room
		expect((GemPieces.need(profile, { { type = "remove", kind = "items", key = "2" }, add(FOG) }))).toBe(0)
		expect(GemPieces.left(profile, FOG)).toBe(0)
	end)

	it("never let one be owned past the cap, and bring back on a load only what is owned", function()
		local profile = { plan = { items = {} }, gemItems = { [FOG] = Tuning.GemPieces.MaxOwned } }
		for i = 1, Tuning.GemPieces.MaxOwned do
			profile.plan.items[tostring(i)] = { id = FOG, x = i, y = 0, z = 1, r = 0, lv = 0 }
		end
		local gems, _, why = GemPieces.need(profile, { add(FOG) })
		expect(gems).toBe(nil)
		expect(type(why)).toBe("string")
		local fresh = { gemItems = { [FOG] = 1 } }
		expect(GemPieces.fits(fresh, { items = {} }, { add(FOG) })).toBe(true)
		expect(GemPieces.fits(fresh, { items = { a = { id = FOG } } }, { add(FOG) })).toBe(false)
		expect(GemPieces.fits({}, { items = {} }, { add(FOG) })).toBe(false)
	end)

	it("keep only known pieces with whole counts in a save", function()
		local clean = GemPieces.clean({ [FOG] = 2.7, sofa_three = 3, nothing = 1, [5] = 2 })
		expect(clean[FOG]).toBe(2)
		expect(clean.sofa_three).toBe(nil)
		expect(clean.nothing).toBe(nil)
		expect(next(GemPieces.clean("junk"))).toBe(nil)
	end)
end)
