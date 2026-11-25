--!nocheck
-- The icons. Each is vector art painted into a picture (UI/IconArt, UI/Vector), with the older
-- build from shapes behind it for when the game can't make pictures: every one of those builds,
-- and none has an outline drawn over another part. The flat shape ones are one colour, with
-- details cut out in a second. The stickers are drawn in two passes (dark outline copies first,
-- then the fills with no stroke), so the only outline that shows is the one round the whole
-- silhouette. The foods (UI/ItemArt) are icons too (the user: "make food and thing icons
-- sillouhettes like normal icons as well"), held to the same rules and shown in their own colour,
-- and kept to a few shapes and a cut or two (the user: "make food/item icons much simpler").

local Icons = require("StarterPlayer.StarterPlayerScripts.Client.UI.Icons")
local Foods = require("ReplicatedStorage.Shared.Data.Foods")
local Colors = require("ReplicatedStorage.Shared.Util.Colors")

-- How far apart two colours are to the eye: the ratio of their lightness (1 to 21).
local function contrast(a: Color3, b: Color3): number
	local function lum(c: Color3): number
		local function ch(v: number): number
			return if v <= 0.04045 then v / 12.92 else ((v + 0.055) / 1.055) ^ 2.4
		end
		return 0.2126 * ch(c.R) + 0.7152 * ch(c.G) + 0.0722 * ch(c.B)
	end
	local la, lb = lum(a), lum(b)
	return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05)
end

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

	it("has a one colour form of the art with its own colours, cut like the rest", function()
		-- (the user: "make a black icon for coins as well where it is required": a coin on a
		-- yellow block shows in the block's dark ink)
		local Vector = require("StarterPlayer.StarterPlayerScripts.Client.UI.Vector")
		local IconArt = require("StarterPlayer.StarterPlayerScripts.Client.UI.IconArt")
		for _, name in { "coin", "coins" } do
			local art = IconArt.mono[name]
			expect(art ~= nil).toBeTruthy()
			local pixels, coloured = Vector.raster(art, 96, { Weight = Icons.Weight[96] })
			expect(coloured).toBe(false)
			local ink = 0
			for i = 0, 96 * 96 - 1 do
				ink += buffer.readu8(pixels, i * 4 + 3)
			end
			expect(ink > 96 * 96 * 20).toBeTruthy()
		end
		-- asked for (as a marker does), the coin is drawn in the colour given, not its gold
		local ink = Color3.fromRGB(20, 20, 24)
		local icon = Icons.make("coins", 40, { Color = ink, Mono = true })
		expect(icon:GetAttribute("Mono")).toBe(true)
		local plain = Icons.make("coins", 40, { Color = ink })
		expect(plain:GetAttribute("Mono")).toBe(false)
	end)

	it("keeps the icons to one colour, the foods too", function()
		local Vector = require("StarterPlayer.StarterPlayerScripts.Client.UI.Vector")
		local IconArt = require("StarterPlayer.StarterPlayerScripts.Client.UI.IconArt")
		local own = { coin = true, coins = true }
		for _, name in Icons.artNames() do
			local _, coloured = Vector.raster(IconArt.art[name], 24)
			expect(coloured == (own[name] == true)).toBeTruthy()
		end
	end)

	it("draws every icon solid, with a margin, and nothing too fine to show small", function()
		-- the style (UI/IconArt): a filled silhouette with its details cut out of it. So every
		-- icon has a solid shape, no line (drawn or rubbed out) is thinner than 1.5 of the 24
		-- grid, which is one pixel at 16 across, and nothing comes nearer than 1 to the edge
		local Vector = require("StarterPlayer.StarterPlayerScripts.Client.UI.Vector")
		local IconArt = require("StarterPlayer.StarterPlayerScripts.Client.UI.IconArt")
		for _, name in Icons.artNames() do
			local solid = false
			for _, layer in IconArt.art[name] do
				local l = if type(layer) == "string" then { layer } else layer
				local filled = l.fill ~= nil and l.fill ~= false
				if filled and not l.cut then
					solid = true
				elseif not filled and (l.w or Icons.Weight[96]) < 1.5 then
					error(name .. " has a line too fine to show at 16 pixels")
				end
			end
			if not solid then
				error(name .. " has no solid shape: it is drawn in lines")
			end
			local n = 96
			local rim = n // Vector.Grid -- one grid unit, in pixels
			local pixels = Vector.raster(IconArt.art[name], n, { Weight = Icons.Weight[n] })
			for y = 0, n - 1 do
				for x = 0, n - 1 do
					local inRim = x < rim or y < rim or x >= n - rim or y >= n - rim
					if inRim and buffer.readu8(pixels, (y * n + x) * 4 + 3) > 0 then
						error(name .. " comes too near the edge of its square")
					end
				end
			end
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

	it("paints pictures ahead of need, and what is asked for after is already there", function()
		local made = #Harness.images
		Icons.warm({ "tart", "soup", "no such picture" })
		-- painted now, into the sheets the icons share (no picture of its own for each)
		local tart = Icons.item("tart", 40, Color3.new(1, 0, 0), {})
		local art = tart:FindFirstChild("Art")
		expect(art ~= nil).toBeTruthy()
		local sheets = #Harness.images
		-- asking again, at either size, paints nothing new
		Icons.item("tart", 24, Color3.new(1, 0, 0), {})
		Icons.item("soup", 96, Color3.new(1, 0, 0), {})
		expect(#Harness.images).toBe(sheets)
		expect(sheets - made <= 2).toBeTruthy()
		-- where the game can't make pictures it does nothing, and nothing breaks
		Icons.setVector(false)
		Icons.warm({ "apple" })
		Icons.setVector(nil)
		expect(#Harness.images).toBe(sheets)
	end)

	it("draws every food as a silhouette with its details cut out", function()
		-- a food is an icon like the rest: one solid shape in one colour (checked above with every
		-- icon), with cuts that really show at 16 pixels, big in its square, and a shape list
		-- behind it for when the game can't make pictures
		local Vector = require("StarterPlayer.StarterPlayerScripts.Client.UI.Vector")
		local IconArt = require("StarterPlayer.StarterPlayerScripts.Client.UI.IconArt")
		expect(#Foods.list >= 20).toBeTruthy()
		for _, food in Foods.list do
			local art = IconArt.art[food.id]
			if not art then
				error(food.id .. " has no picture")
			end
			if not Icons.defs[food.id] then
				error(food.id .. " has no shape list to fall back on")
			end
			local whole: { any } = {}
			local cuts, details = 0, 0
			for _, layer in art do
				local l = if type(layer) == "string" then { layer } else layer
				expect(l.fill == nil or l.fill == true).toBeTruthy()
				expect(l.stroke == nil).toBeTruthy()
				expect(l.opacity == nil).toBeTruthy()
				if l.cut then
					cuts += 1
					-- a hole or a gap, not the room cleared round one of its parts
					if not (l.fill ~= nil and l.w ~= nil) then
						details += 1
					end
				else
					table.insert(whole, layer)
				end
			end
			if cuts == 0 then
				error(food.id .. " has nothing cut out of it")
			end
			-- and kept simple (the user: "make food/item icons much simpler"): a few shapes and
			-- the one or two cuts that say what it is, nothing finer
			if #art > 7 or details > 3 then
				error(food.id .. " has too much in it: " .. #art .. " layers, " .. details .. " cuts")
			end
			-- at 48 across (what a 16 to 24 pixel icon is drawn from) the cuts take away a fair
			-- few pixels, so the details show
			local n = 48
			local cut = Vector.raster(art, n, { Weight = Icons.Weight[n] })
			local uncut = Vector.raster(whole, n, { Weight = Icons.Weight[n] })
			local gone, left = 0, 0
			local x0, y0, x1, y1 = n, n, -1, -1
			for y = 0, n - 1 do
				for x = 0, n - 1 do
					local a = buffer.readu8(cut, (y * n + x) * 4 + 3)
					gone += buffer.readu8(uncut, (y * n + x) * 4 + 3) - a
					left += a
					if a > 127 then
						x0, y0, x1, y1 = math.min(x0, x), math.min(y0, y), math.max(x1, x), math.max(y1, y)
					end
				end
			end
			if gone < 255 * 24 then
				error(food.id .. "'s cuts are too small to show at 16 pixels")
			end
			-- it fills its square the way the icons do: 16 of the 24 across at least
			if math.max(x1 - x0, y1 - y0) + 1 < n * 16 / 24 then
				error(food.id .. " is too small in its square")
			end
			-- and has some weight (a diagonal one, like the skewer or the sun, is lighter)
			if left < 255 * n * n * 0.15 then
				error(food.id .. " is too thin to read")
			end
		end
	end)

	it("gives every food a colour of its own that reads on the dark glass and on a card", function()
		local glass, dark, light = Color3.fromRGB(12, 12, 15), Color3.fromRGB(44, 44, 50), Color3.fromRGB(253, 253, 255)
		for _, food in Foods.list do
			local c = Colors.fromHex(food.color)
			if contrast(c, glass) < 4 or contrast(c, dark) < 3 or contrast(c, light) < 1.5 then
				error(food.id .. "'s colour doesn't stand out: " .. food.color)
			end
		end
	end)

	it("shows a food in its own colour, or tinted like an icon when asked", function()
		local own = Color3.fromRGB(229, 65, 75)
		local apple = Icons.item("apple", 24, own, {})
		local art = apple:FindFirstChild("Art")
		expect(art ~= nil).toBeTruthy()
		expect(apple:GetAttribute("Mono")).toBe(true)
		expect(art.ImageColor3:ToHex():lower()).toBe(own:ToHex():lower())
		local tint = Color3.fromRGB(10, 200, 30)
		local tinted = Icons.item("apple", 24, own, { Color = tint }):FindFirstChild("Art")
		expect(tinted.ImageColor3:ToHex():lower()).toBe(tint:ToHex():lower())
		local byTint = Icons.item("apple", 24, own, { Tint = tint }):FindFirstChild("Art")
		expect(byTint.ImageColor3:ToHex():lower()).toBe(tint:ToHex():lower())
		-- Icons.make draws it like any icon, in the glyph colour unless told
		local plain = Icons.make("apple", 24, { Color = tint }):FindFirstChild("Art")
		expect(plain.ImageColor3:ToHex():lower()).toBe(tint:ToHex():lower())
	end)

	it("builds a food from its shape list when the game can't make pictures", function()
		local IconArt = require("StarterPlayer.StarterPlayerScripts.Client.UI.IconArt")
		local own, hole = Color3.fromRGB(229, 65, 75), Color3.fromRGB(250, 240, 230)
		Icons.setVector(false)
		for _, food in Foods.list do
			-- what the picture cuts out of itself (a hole, a gap) and not only the room cleared
			-- round one of its parts (the apple's leaf), which the shape list leaves out
			local cutsOut = false
			for _, layer in IconArt.art[food.id] do
				local l = if type(layer) == "string" then { layer } else layer
				local cleared = l.fill ~= nil and l.w ~= nil
				cutsOut = cutsOut or (l.cut == true and not cleared)
			end
			local icon = Icons.item(food.id, 40, own, { Hole = hole })
			expect(icon.Name ~= "Swatch").toBeTruthy()
			expect(icon:FindFirstChild("Art")).toBe(nil)
			expect(#icon:GetChildren() >= 2).toBeTruthy()
			local holes = 0
			for _, d in icon:GetDescendants() do
				local c = if d:IsA("Frame") and d.BackgroundTransparency < 1
					then d.BackgroundColor3
					elseif d:IsA("UIStroke") then d.Color
					else nil
				if c then
					expect(c:ToHex() == own:ToHex() or c:ToHex() == hole:ToHex()).toBeTruthy()
					holes += if c:ToHex() == hole:ToHex() then 1 else 0
				end
			end
			-- its details are cut out of it as the picture's are
			if cutsOut and holes == 0 then
				error(food.id .. "'s shape list has nothing cut out of it")
			end
		end
		Icons.setVector(nil)
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
