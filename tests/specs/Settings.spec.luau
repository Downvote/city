--!nocheck
-- Settings (Sim/Graphics, Schema.Settings, Tuning.Graphics). The user: "add settings for graphic
-- quality, background blur, bloom, etc.". Every choice is saved with its default, a broken or old
-- value falls back to it, and each detail level draws less than the one above.

local Shared = "ReplicatedStorage.Shared."
local Tuning = require(Shared .. "Config.Tuning")
local Schema = require(Shared .. "Sim.Schema")
local Graphics = require(Shared .. "Sim.Graphics")

describe("Settings", function()
	it("saves every graphics choice with a default, the detail a known word", function()
		for _, k in Graphics.Keys do
			expect(Schema.Settings[k] ~= nil).toBeTruthy()
		end
		expect(Schema.SettingChoices.detail[Schema.Settings.detail]).toBe(true)
		for _, d in Graphics.Detail do
			expect(Schema.SettingChoices.detail[d]).toBe(true)
			expect(Tuning.Graphics.Levels[d] ~= nil).toBeTruthy()
		end
		-- an old save gets them all
		local old = Schema.migrate({ settings = { music = 0.2 } })
		expect(old.settings.music).toBe(0.2)
		for _, k in Graphics.Keys do
			expect(old.settings[k]).toBe(Schema.Settings[k])
		end
	end)

	it("falls back to the default for anything broken", function()
		local s = Graphics.clean({ detail = "ultra", blur = "yes", blurStrength = 0 / 0, bloom = false, haze = 3 })
		expect(s.detail).toBe(Schema.Settings.detail)
		expect(s.blur).toBe(Schema.Settings.blur)
		expect(s.blurStrength).toBe(Schema.Settings.blurStrength)
		expect(s.bloom).toBe(false)
		expect(s.haze).toBe(Schema.Settings.haze)
		expect(Graphics.clean({ blurStrength = 7 }).blurStrength).toBe(1)
		expect(Graphics.clean(nil).detail).toBe("high")
	end)

	it("draws less at each lower detail", function()
		local L = Tuning.Graphics.Levels
		local order = { L.low, L.medium, L.high }
		for i = 2, 3 do
			local a, b = order[i - 1], order[i]
			expect(a.Reach < b.Reach).toBeTruthy()
			expect(a.Particles < b.Particles).toBeTruthy()
			expect(a.Outlines <= b.Outlines).toBeTruthy()
			expect(a.Layers <= b.Layers).toBeTruthy()
		end
		expect(L.high.Reach).toBe(1)
		expect(L.high.Particles).toBe(1)
		expect(L.high.Shadows).toBe(true)
		expect(L.low.Shadows).toBe(false)
		expect(L.low.Outlines).toBe(0)
		expect(Graphics.level({ detail = "low" })).toBe(L.low)
		expect(Graphics.level({})).toBe(L.high)
	end)

	it("blurs as the game did at Medium, stronger at Strong, not at all with it off", function()
		local lens = Tuning.Look.Lens
		expect(math.abs(Graphics.blur({}) - lens.FarIntensity) < 1e-6).toBeTruthy()
		expect(Graphics.blur({ blur = false })).toBe(0)
		local steps = Tuning.Graphics.BlurSteps
		expect(Graphics.blur({ blurStrength = steps[3] }) > Graphics.blur({ blurStrength = steps[1] })).toBeTruthy()
		for i, v in steps do
			expect(Graphics.blurStep({ blurStrength = v })).toBe(i)
		end
		expect(Graphics.blurStep({})).toBe(2)
	end)

	it("clears the air with the haze off, and follows the weather with it on", function()
		local d, h = Graphics.air({ haze = false }, "fog")
		expect(d).toBe(Tuning.Weather.NoHaze.Density)
		expect(h).toBe(Tuning.Weather.NoHaze.Haze)
		local fd = Graphics.air({}, "fog")
		expect(fd).toBe(Tuning.Weather.Looks.fog.Density)
		expect(Graphics.air({}, "nonsense")).toBe(Tuning.Weather.Looks.clear.Density)
	end)
end)
