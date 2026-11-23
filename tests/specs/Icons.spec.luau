--!nocheck
-- The icons. Each is vector art painted into a picture (UI/IconArt, UI/Vector), with the older
-- build from shapes behind it for when the game can't make pictures: every one of those builds,
-- and none has an outline drawn over another part. The flat shape ones are one colour, with
-- details cut out in a second. The stickers are drawn in two passes (dark outline copies first,
-- then the fills with no stroke), so the only outline that shows is the one round the whole
-- silhouette.

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
			local icon = Icons.flat(name, 48, { Color = glyph, Hole = hole })
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
		local icon = Icons.flat("coin", 48, { Color = glyph })
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

	it("draws the hammer with a heavy head square across its handle", function()
		-- a thin head off to one side read as a hoe: the head is a block, much thicker and longer
		-- than the handle is thick, and its middle sits on the handle's end (a T, not an L)
		local def = Icons.defs.hammer
		local handle, head = def[1], def[2]
		local turn = math.rad(handle.rot)
		local tipX = handle[2] + handle[4] / 2 + handle[5] / 2 * math.sin(turn)
		local tipY = handle[3] + handle[5] / 2 - handle[5] / 2 * math.cos(turn)
		local cx, cy = head[2] + head[4] / 2, head[3] + head[5] / 2
		-- how far the head's middle is from the handle's end, along the head
		local off = (cx - tipX) * math.cos(turn) + (cy - tipY) * math.sin(turn)
		expect(math.abs(off) < 5).toBeTruthy()
		expect(head.rot == handle.rot).toBeTruthy()
		expect(head[4] >= handle[4] * 3).toBeTruthy()
		expect(head[5] >= handle[4] * 1.7).toBeTruthy()
		expect(handle[4] >= 16).toBeTruthy()
	end)

	it("has a trophy for the Goals button", function()
		expect(Icons.has("trophy")).toBeTruthy()
		expect(#Icons.flat("trophy", 40, {}):GetChildren() >= 5).toBeTruthy()
		expect(Icons.hasArt("trophy")).toBeTruthy()
	end)

	it("has vector art for every icon", function()
		for _, name in Icons.names() do
			if not Icons.hasArt(name) then
				error(name .. " has no vector art")
			end
		end
	end)

	it("paints every piece of art inside its square, at both sizes", function()
		local Vector = require("StarterPlayer.StarterPlayerScripts.Client.UI.Vector")
		local IconArt = require("StarterPlayer.StarterPlayerScripts.Client.UI.IconArt")
		for _, name in Icons.artNames() do
			for _, n in { 48, 96 } do
				local pixels = Vector.raster(IconArt.art[name], n, { Weight = Icons.Weight[n] })
				local ink, edge = 0, 0
				for y = 0, n - 1 do
					for x = 0, n - 1 do
						local a = buffer.readu8(pixels, (y * n + x) * 4 + 3)
						ink += a
						if x == 0 or y == 0 or x == n - 1 or y == n - 1 then
							edge += a
						end
					end
				end
				if ink < n * n * 4 then
					error(name .. " is nearly empty at " .. n)
				end
				-- nothing touches the square's edge: it would be cut off
				if edge > 0 then
					error(name .. " runs off its square at " .. n)
				end
			end
		end
	end)

	it("keeps the interface icons to one colour", function()
		local Vector = require("StarterPlayer.StarterPlayerScripts.Client.UI.Vector")
		local IconArt = require("StarterPlayer.StarterPlayerScripts.Client.UI.IconArt")
		local own = { coin = true, coins = true }
		for _, name in Icons.names() do
			local _, coloured = Vector.raster(IconArt.art[name], 24)
			expect(coloured == (own[name] == true)).toBeTruthy()
		end
	end)

	it("shows an icon as its square of a sheet, tinted", function()
		local tint = Color3.fromRGB(10, 200, 30)
		local small = Icons.make("hammer", 24, { Color = tint })
		local big = Icons.make("hammer", 56, { Color = tint })
		local a, b = small:FindFirstChild("Art"), big:FindFirstChild("Art")
		expect(a ~= nil and b ~= nil).toBeTruthy()
		expect(a.ImageRectSize.X).toBe(48)
		expect(b.ImageRectSize.X).toBe(96)
		expect(a.ImageColor3:ToHex():lower()).toBe(tint:ToHex():lower())
		expect(small:GetAttribute("Vector")).toBe(true)
		-- asked for twice, it is painted once
		local again = Icons.make("hammer", 20, {}):FindFirstChild("Art")
		expect(again.ImageRectOffset).toBe(a.ImageRectOffset)
		-- the coin has colours of its own and takes no tint
		local coin = Icons.make("coin", 24, { Color = tint }):FindFirstChild("Art")
		expect(coin.ImageColor3:ToHex():lower()).toBe("ffffff")
	end)

	it("builds the icon from shapes when the game can't make pictures", function()
		Icons.setVector(false)
		local icon = Icons.make("hammer", 40, {})
		Icons.setVector(nil)
		expect(icon:FindFirstChild("Art")).toBe(nil)
		expect(#icon:GetChildren() >= 2).toBeTruthy()
	end)

	it("draws a disc for a thing with no picture", function()
		local disc = Icons.item("nothing of the kind", 40, Color3.new(1, 0, 0), {})
		expect(disc.Name).toBe("Swatch")
	end)

	it("outlines nothing when asked not to", function()
		local icon = Icons.make("coin", 40, { Full = true, Outline = false })
		for _, child in icon:GetChildren() do
			expect(child.Name:sub(1, 3) ~= "Ink").toBeTruthy()
		end
	end)
end)
