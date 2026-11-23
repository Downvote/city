--!nocheck
-- The drawn icons: every one builds, and none has an outline drawn over another part. Icons are
-- drawn in two passes (dark outline copies first, then the fills with no stroke), so the only
-- outline that shows is the one round the whole silhouette.

local Icons = require("StarterPlayer.StarterPlayerScripts.Client.UI.Icons")

local function strokesUnder(inst)
	local out = {}
	for _, d in inst:GetDescendants() do
		if d:IsA("UIStroke") then
			table.insert(out, d)
		end
	end
	if inst:IsA("GuiObject") then
		for _, c in inst:GetChildren() do
			if c:IsA("UIStroke") and not table.find(out, c) then
				table.insert(out, c)
			end
		end
	end
	return out
end

describe("Icons", function()
	it("builds every icon", function()
		local names = Icons.names()
		expect(#names >= 60).toBeTruthy()
		for _, name in names do
			local icon = Icons.make(name, 60)
			expect(#icon:GetChildren() > 0).toBeTruthy()
		end
	end)

	it("never draws an outline after a fill", function()
		for _, name in Icons.names() do
			local icon = Icons.make(name, 60)
			local seenFill = false
			for _, child in icon:GetChildren() do
				local isInk = child.Name:sub(1, 3) == "Ink"
				local isFill = child.Name:sub(1, 4) == "Fill"
				if not (isInk or isFill) then
					error(name .. ": a piece that is neither outline nor fill: " .. child.Name)
				end
				if isFill then
					seenFill = true
				elseif seenFill then
					error(name .. ": an outline copy comes after a fill (" .. child.Name .. ")")
				end
			end
		end
	end)

	it("keeps every dark stroke on the outline copies", function()
		for _, name in Icons.names() do
			local icon = Icons.make(name, 60)
			for _, child in icon:GetChildren() do
				if child.Name:sub(1, 4) == "Fill" then
					for _, st in strokesUnder(child) do
						-- the only strokes a fill may have are a ring's own colour, never the outline ink
						local ring = child:GetAttribute("RingWidth") ~= nil
						if not ring or st.Color == Icons.Ink then
							error(name .. ": a stroke on a fill (" .. child.Name .. ")")
						end
					end
				end
			end
		end
	end)

	it("outlines nothing when asked not to", function()
		local icon = Icons.make("coin", 40, { Outline = false })
		for _, child in icon:GetChildren() do
			expect(child.Name:sub(1, 3) ~= "Ink").toBeTruthy()
		end
	end)
end)
