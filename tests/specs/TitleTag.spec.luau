--!nocheck
-- The title over a player's head and in chat (Util/TitleTag). The user: "make title be above the
-- name, with no black background. also, make titles appear to the left of names in chat".

local TitleTag = require("ReplicatedStorage.Shared.Util.TitleTag")

describe("TitleTag", function()
	it("puts the title over the name, with nothing behind either", function()
		local tag = TitleTag.build("Sam", "Town hero")
		local title = tag:FindFirstChild("Title")
		local name = tag:FindFirstChild("PlayerName")
		expect(title ~= nil and name ~= nil).toBeTruthy()
		expect(title.Text).toBe("Town hero")
		expect(name.Text).toBe("Sam")
		expect(title.Position.Y.Offset + title.Size.Y.Offset <= name.Position.Y.Offset).toBeTruthy()
		expect(name.Position.Y.Offset + name.Size.Y.Offset <= TitleTag.Height).toBeTruthy()
		for _, d in tag:GetDescendants() do
			if d:IsA("GuiObject") then
				expect(d.BackgroundTransparency).toBe(1)
			end
		end
		expect(tag.BackgroundTransparency).toBe(1)
	end)

	it("puts the title before the name in chat, in gold, made safe", function()
		local line = TitleTag.chatPrefix("Town hero", "Sam:")
		expect(line).toBe('<font color="' .. TitleTag.ChatColor .. '">[Town hero]</font> Sam:')
		local odd = TitleTag.chatPrefix("<b>&", "Sam:")
		expect(odd:find("<b>", 1, true)).toBe(nil)
		expect(odd:find("&lt;b&gt;&amp;", 1, true) ~= nil).toBeTruthy()
	end)
end)
