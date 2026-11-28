--!nocheck
-- A villager's work move (Sim/WorkMove, Data/Emotes). The user: "let there be animations while a
-- villager works. players can also pay gems to change this animation to an emote of their
-- choosing." Held here: the emotes are Roblox's own animations, each once; setting one costs its
-- gems and is checked (a villager of theirs, an emote on the list, not what they have, enough
-- gems); going back is free; what the brain plays at work follows it; a save keeps only an emote
-- there is.

local Shared = "ReplicatedStorage.Shared."
local Tuning = require(Shared .. "Config.Tuning")
local Emotes = require(Shared .. "Data.Emotes")
local WorkMove = require(Shared .. "Sim.WorkMove")
local Schema = require(Shared .. "Sim.Schema")
local Appearance = require(Shared .. "Avatar.Appearance")
local Rng = require(Shared .. "Util.Rng")

local function town(gems)
	local p = Schema.newProfile()
	local input = Schema.cleanVillagerInput({ name = "Mara", pers = "sunny", app = Appearance.default() })
	p.villagers.v1 = Schema.newVillager("v1", input, Rng.new(1))
	p.order = { "v1" }
	p.gems = gems
	return p
end

describe("WorkMove", function()
	it("lists Roblox's own emotes, each once, by a name a player reads", function()
		local ids, anims = {}, {}
		expect(#Emotes.list >= 8).toBeTruthy()
		for _, e in Emotes.list do
			expect(ids[e.id]).toBe(nil)
			expect(anims[e.anim]).toBe(nil)
			ids[e.id], anims[e.anim] = true, true
			-- an Animation asset, by its number
			expect(e.anim:match("^rbxassetid://%d+$") ~= nil).toBeTruthy()
			expect(#e.name > 0 and #e.name <= 12).toBeTruthy()
			expect(e.beat >= 2).toBeTruthy()
			expect(type(e.looped)).toBe("boolean")
			-- never the name of one of the body's own moves (Npc plays those from the Animate script)
			expect(e.id:sub(1, 3)).toBe("em_")
			expect(Emotes.get(e.id)).toBe(e)
		end
		expect(Emotes.get("dance")).toBe(nil)
		expect(Emotes.get(nil)).toBe(nil)
		expect(Emotes.get(5)).toBe(nil)
	end)

	it("sets one for its gems, checks everything first, and goes back for nothing", function()
		local price = Tuning.WorkMove.Price
		expect(price > 0 and price <= 10).toBeTruthy()
		local p = town(price + 2)
		-- nobody, no such emote
		expect(WorkMove.set(p, "v9", "em_wave")).toBe(false)
		local ok, cost, why = WorkMove.set(p, "v1", "em_moonwalk")
		expect(ok).toBe(false)
		expect(cost).toBe(0)
		expect(why).toBe("Pick one from the list.")
		expect(p.gems).toBe(price + 2)
		-- it goes on, and the gems go
		ok, cost = WorkMove.set(p, "v1", "em_dance2")
		expect(ok).toBe(true)
		expect(cost).toBe(price)
		expect(p.gems).toBe(2)
		expect(p.villagers.v1.move).toBe("em_dance2")
		expect(WorkMove.get(p.villagers.v1).name).toBe("Dance 2")
		-- not again for what they have, and not without the gems
		ok, _, why = WorkMove.set(p, "v1", "em_dance2")
		expect(ok).toBe(false)
		expect(why).toBe("That's what they do already.")
		ok, _, why = WorkMove.set(p, "v1", "em_wave")
		expect(ok).toBe(false)
		expect(why).toBe(string.format("You need %d more gems.", price - 2))
		expect(p.villagers.v1.move).toBe("em_dance2")
		expect(p.gems).toBe(2)
		-- what the brain plays: the emote at its own beat in place of the step's own move
		local act, beat = WorkMove.act(p.villagers.v1, "toolslash", 2.2)
		expect(act).toBe("em_dance2")
		expect(beat).toBe(Emotes.get("em_dance2").beat)
		-- back to the job's own, for nothing
		expect(WorkMove.clear(p, "v1")).toBe(true)
		expect(p.gems).toBe(2)
		expect(p.villagers.v1.move).toBe(nil)
		expect(WorkMove.clear(p, "v1")).toBe(false)
		act, beat = WorkMove.act(p.villagers.v1, "toolslash", 2.2)
		expect(act).toBe("toolslash")
		expect(beat).toBe(2.2)
		-- broken gems count as none
		p.gems = 0 / 0
		expect(WorkMove.set(p, "v1", "em_wave")).toBe(false)
	end)

	it("keeps a saved move only when it is an emote there is", function()
		local p = town(0)
		p.villagers.v1.move = "em_salute"
		expect(Schema.migrate(p).villagers.v1.move).toBe("em_salute")
		for _, bad in { "em_moonwalk", "dance", 7, true, {} } do
			p.villagers.v1.move = bad
			expect(Schema.migrate(p).villagers.v1.move).toBe(nil)
		end
	end)
end)
