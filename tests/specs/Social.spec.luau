--!nocheck
-- Other players (Sim/Social). The user: "add a 10% income boosy per friend playing, and prompt the
-- player to invite friends. Allow clicking on other players to open an interface to view their
-- profile and like their plot". The boost is a tenth a friend up to a cap and goes on top of the
-- passes' own; the nudge comes once there's a second villager, until it's put away; a card shows a
-- town's closest villagers first.

local Shared = "ReplicatedStorage.Shared."
local Tuning = require(Shared .. "Config.Tuning")
local Social = require(Shared .. "Sim.Social")
local Passes = require(Shared .. "Sim.Passes")
local Schema = require(Shared .. "Sim.Schema")

local K = Tuning.Friends

describe("Friends playing", function()
	it("adds a tenth to the town's pay for each friend here, up to the cap", function()
		expect(K.Each).toBeNear(0.1)
		expect(Social.boost(0)).toBe(1)
		expect(Social.boost(1)).toBeNear(1.1)
		expect(Social.boost(2)).toBeNear(1.2)
		expect(Social.boost(K.Most)).toBeNear(1 + K.Most * K.Each)
		expect(Social.boost(K.Most + 5)).toBeNear(1 + K.Most * K.Each)
		-- junk counts as nobody
		for _, junk in { -3, 0 / 0, "4", nil, math.huge } do
			expect(Social.boost(junk) >= 1 and Social.boost(junk) <= 1 + K.Most * K.Each).toBe(true)
		end
		expect(Social.boost(-3)).toBe(1)
		expect(Social.boost("4")).toBe(1)
		-- on top of the passes: Double Pay and two friends is 2.4 times
		local profile = { passes = { doublepay = true } }
		expect(Passes.payBoost(profile, false) * Social.boost(2)).toBeNear(2.4)
	end)

	it("shows the boost as a short chip and a line in the City hall", function()
		expect(Social.chip(0)).toBe(nil)
		expect(Social.chip(2)).toBe("+20% friends")
		expect(Social.percent(3)).toBe(30)
		expect(Social.line(0)).toBe("Each friend playing here adds 10% to wages.")
		expect(Social.line(1)).toBe("1 friend here, wages +10%")
		expect(Social.line(3)).toBe("3 friends here, wages +30%")
	end)

	it("nudges once there's a second villager, until it's put away", function()
		local settings = table.clone(Schema.Settings)
		expect(settings.inviteTip).toBe(true)
		expect(Social.nudge(settings, 1)).toBe(false)
		expect(Social.nudge(settings, K.NudgeAt)).toBe(true)
		settings.inviteTip = false
		expect(Social.nudge(settings, 5)).toBe(false)
		-- an old save without the setting gets it
		local old = Schema.migrate({ settings = { music = 0.3 } })
		expect(old.settings.inviteTip).toBe(true)
	end)
end)

describe("A player's card", function()
	it("shows their closest villagers first", function()
		local profile = {
			order = { "a", "b", "c", "d" },
			villagers = {
				a = { name = "Ada", heart = 2, hxp = 5, pers = "shy", color = "AABBCC" },
				b = { name = "Bo", heart = 4, hxp = 0, pers = "bold", job = "k1" },
				c = { name = "Cy", heart = 2, hxp = 9 },
				d = { name = "Di", heart = 0 },
				junk = "nope",
			},
		}
		local top = Social.top(profile, 3)
		expect(#top).toBe(3)
		expect(top[1].name).toBe("Bo")
		expect(top[1].job).toBe(true)
		expect(top[2].name).toBe("Cy")
		expect(top[3].name).toBe("Ada")
		expect(top[3].color).toBe("AABBCC")
		expect(type(top[2].color)).toBe("string")
		expect(#Social.top(nil, 3)).toBe(0)
		expect(#Social.top({ villagers = {} }, 3)).toBe(0)
	end)
end)
