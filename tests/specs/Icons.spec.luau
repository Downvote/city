--!nocheck
-- The drawn icons: every one builds, and none has an outline drawn over another part. The flat
-- ones the game uses by default are one colour, with details cut out in a second. Icons are
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
			local icon = Icons.make(name, 60, { Full = true })
			expect(#icon:GetChildren() > 0).toBeTruthy()
		end
	end)

	it("never draws an outline after a fill", function()
		for _, name in Icons.names() do
			local icon = Icons.make(name, 60, { Full = true })
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
			local icon = Icons.make(name, 60, { Full = true })
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

	it("draws flat icons in one colour with cut out details", function()
		local glyph, hole = Color3.fromRGB(10, 20, 30), Color3.fromRGB(250, 240, 230)
		for _, name in Icons.names() do
			local icon = Icons.make(name, 48, { Color = glyph, Hole = hole })
			local colours = {}
			for _, d in icon:GetDescendants() do
				expect(d.Name:sub(1, 3) ~= "Ink").toBeTruthy()
				if d:IsA("Frame") and d.BackgroundTransparency < 1 then
					colours[d.BackgroundColor3:ToHex()] = true
				elseif d:IsA("UIStroke") then
					colours[d.Color:ToHex()] = true
				elseif d:IsA("UIGradient") then
					error(name .. ": a flat icon has shading")
				end
			end
			-- a dent (the coin's middle) is the same colour a step darker, and nothing else is
			local dent = Icons.dentOf(glyph):ToHex()
			local dented = false
			for _, sh in Icons.defs[name] do
				dented = dented or sh.dent == true
			end
			for hex in colours do
				expect(hex == glyph:ToHex() or hex == hole:ToHex() or (dented and hex == dent)).toBeTruthy()
			end
		end
	end)

	it("presses a darker circle into the coin", function()
		local glyph = Color3.fromRGB(236, 162, 28)
		local icon = Icons.make("coin", 48, { Color = glyph })
		local found = false
		for _, d in icon:GetChildren() do
			if d:IsA("Frame") and d.BackgroundColor3:ToHex() == Icons.dentOf(glyph):ToHex() then
				found = true
				-- inside the coin, and smaller than it
				expect(d.Size.X.Scale < 0.7 and d.Position.X.Scale > 0.1).toBeTruthy()
			end
		end
		expect(found).toBeTruthy()
		expect(Icons.dentOf(glyph) ~= glyph).toBeTruthy()
	end)

	it("draws the hammer's head across the end of its handle", function()
		-- the head's two halves sit either side of the handle's top end, so it is a T and not an L
		local def = Icons.defs.hammer
		local handle, peen, face = def[1], def[2], def[3]
		local turn = math.rad(handle.rot)
		local tipX = handle[2] + handle[4] / 2 + handle[5] / 2 * math.sin(turn)
		local tipY = handle[3] + handle[5] / 2 - handle[5] / 2 * math.cos(turn)
		local function along(sh)
			-- how far the piece's middle is from the tip, along the head (at right angles to the handle)
			local cx, cy = sh[2] + sh[4] / 2, sh[3] + sh[5] / 2
			return (cx - tipX) * math.cos(turn) + (cy - tipY) * math.sin(turn)
		end
		expect(along(peen) < -4).toBeTruthy()
		expect(along(face) > 4).toBeTruthy()
		expect(peen.rot == handle.rot and face.rot == handle.rot).toBeTruthy()
	end)

	it("has a trophy for the Goals button", function()
		expect(Icons.has("trophy")).toBeTruthy()
		expect(#Icons.make("trophy", 40):GetChildren() >= 5).toBeTruthy()
	end)

	it("outlines nothing when asked not to", function()
		local icon = Icons.make("coin", 40, { Full = true, Outline = false })
		for _, child in icon:GetChildren() do
			expect(child.Name:sub(1, 3) ~= "Ink").toBeTruthy()
		end
	end)
end)
