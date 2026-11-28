--!nocheck
-- A plot's name (Sim/PlotName; the user: "allow naming of plots, and the name should appear in
-- place of the big "Level x" at the top left above the level bar"): what a saved name is cut down
-- to, what the main screen shows with a name and without, and an old save loading with none.

local Shared = "ReplicatedStorage.Shared."
local PlotName = require(Shared .. "Sim.PlotName")
local Schema = require(Shared .. "Sim.Schema")
local Tuning = require(Shared .. "Config.Tuning")

describe("PlotName", function()
	it("keeps a plain name as it is", function()
		expect(PlotName.clean("Juniper Bay")).toBe("Juniper Bay")
		expect(PlotName.clean("Café Row")).toBe("Café Row")
	end)

	it("turns anything that isn't a string into no name", function()
		for _, raw in { nil, 12, true, {}, { "Bay" } } do
			expect(PlotName.clean(raw)).toBe("")
		end
		-- (bytes that aren't text)
		expect(PlotName.clean("Bay\255\254")).toBe("")
	end)

	it("drops control characters and spaces at the ends, and runs of spaces", function()
		expect(PlotName.clean("  Juniper\n\tBay  ")).toBe("Juniper Bay")
		expect(PlotName.clean("Old    Town")).toBe("Old Town")
		expect(PlotName.clean("   ")).toBe("")
	end)

	it("cuts a long name to the most it may have, by characters", function()
		local most = Tuning.PlotName.MaxLength
		expect(PlotName.MaxLength).toBe(most)
		local long = string.rep("a", most + 10)
		expect(#PlotName.clean(long)).toBe(most)
		-- letters that take more than one byte count as one each
		local wide = string.rep("é", most + 3)
		local cut = PlotName.clean(wide)
		expect(utf8.len(cut)).toBe(most)
		expect(cut).toBe(string.rep("é", most))
		-- and a cut that ends on a space leaves none at the end
		local spaced = string.rep("b", most - 1) .. " tail"
		expect(PlotName.clean(spaced)).toBe(string.rep("b", most - 1))
	end)

	it("shows the name, or the owner's town without one", function()
		expect(PlotName.title("Juniper Bay", "Sam")).toBe("Juniper Bay")
		expect(PlotName.title("", "Sam")).toBe("Sam's town")
		expect(PlotName.title(nil, "Sam")).toBe("Sam's town")
		expect(PlotName.title("   ", "Sam")).toBe("Sam's town")
		expect(PlotName.title("", "")).toBe("Your town")
		expect(PlotName.title(nil, nil)).toBe("Your town")
	end)

	it("starts a new profile unnamed and cleans a saved name on load", function()
		expect(Schema.newProfile().plotName).toBe("")
		-- an old save with no name gets one key, empty
		local old = Schema.newProfile()
		old.plotName = nil
		expect(Schema.migrate(old).plotName).toBe("")
		-- a broken one is dropped, a long one cut
		local broken = Schema.newProfile()
		broken.plotName = { "x" }
		expect(Schema.migrate(broken).plotName).toBe("")
		local long = Schema.newProfile()
		long.plotName = "  " .. string.rep("z", 40)
		expect(Schema.migrate(long).plotName).toBe(string.rep("z", Tuning.PlotName.MaxLength))
	end)
end)
