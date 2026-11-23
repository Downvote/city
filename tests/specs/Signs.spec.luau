--!nocheck
-- The town's signs. The words (Data/Signs): every kind of shop and public building has a name,
-- the adverts are well formed and read like a person wrote them, a pick is the same for the same
-- spot and changes from spot to spot. The boards (Data/CityModels): every sign part names a kind
-- the words know. The drawing (the server's Signs service, run for real on Lune's instances):
-- every board gets its faces, words never leave their board, and a face stays a handful of
-- instances.

local Shared = "ReplicatedStorage.Shared."
local Signs = require(Shared .. "Data.Signs")
local Town = require(Shared .. "Data.Town")
local TownMap = require(Shared .. "Data.TownMap")
local CityModels = require(Shared .. "Data.CityModels")
local Facades = require(Shared .. "Data.Facades")
local Interiors = require(Shared .. "Data.Interiors")
local Builder = require(Shared .. "Build.Builder")

-- the service asks the World service whether it is night, and the clock for when that changes
local WORLD = "ServerScriptService.Server.Services.World"
local dark = false
Harness.stub(WORLD, {
	isNight = function()
		return dark
	end,
})
Harness.addService("Lighting", {
	ClockTime = 12,
	GetPropertyChangedSignal = function()
		return Harness.signal()
	end,
})
local Service = require("ServerScriptService.Server.Services.Signs")
Harness.stub(WORLD, nil) -- (only this spec's copy of the service keeps the stand-in)

-- every design there is, with where it came from
local function designs()
	local out = {}
	for kind, list in Signs.Shops do
		for i, d in list do
			table.insert(out, { d = d, where = kind .. " " .. i, shop = true })
		end
	end
	for i, d in Signs.Adverts do
		table.insert(out, { d = d, where = "advert " .. i })
	end
	for i, d in Signs.Films do
		table.insert(out, { d = d, where = "film " .. i })
	end
	return out
end

-- every string a player can read off a sign
local function texts()
	local out = {}
	for _, e in designs() do
		table.insert(out, { s = e.d.name, where = e.where })
		table.insert(out, { s = e.d.line, where = e.where })
		if e.d.short then
			table.insert(out, { s = e.d.short, where = e.where })
		end
	end
	for i, s in Signs.Streets do
		table.insert(out, { s = s, where = "street " .. i })
	end
	return out
end

-- CLAUDE.md's writing rule
local BANNED = {
	"delve",
	"embark",
	"unleash",
	"vibrant",
	"bustling",
	"journey",
	"realm",
	"tapestry",
	"seamless",
	"elevate",
}

describe("Sign words", function()
	it("has a name for every kind of shop and public building", function()
		local kinds = { "post", "department", "cinema", "station", "library", "museum", "school", "clinic" }
		for _, k in { "fire", "hotel", "office", "flats", "tower" } do
			table.insert(kinds, k)
		end
		for _, k in Interiors.ShopKinds do
			table.insert(kinds, k)
		end
		for _, kind in kinds do
			local list = Signs.Shops[kind]
			if not list or #list == 0 then
				error("no name for a " .. kind)
			end
			expect(Signs.shopAt(kind, 10, 20) ~= nil).toBeTruthy()
		end
		expect(Signs.shopAt("dragon lair", 0, 0)).toBe(nil)
	end)

	it("has well formed designs", function()
		for _, e in designs() do
			local d = e.d
			local function need(ok, what)
				if not ok then
					error(e.where .. " (" .. tostring(d.name) .. "): " .. what)
				end
			end
			need(type(d.name) == "string" and #d.name >= 3 and #d.name <= 26, "a name of 3 to 26 letters")
			need(type(d.line) == "string" and #d.line >= 4 and #d.line <= 34, "a line of 4 to 34 letters")
			need(table.find(Signs.Styles, d.style) ~= nil, "a known style, not " .. tostring(d.style))
			need(table.find(Signs.Fonts, d.font) ~= nil, "a known font, not " .. tostring(d.font))
			for _, key in { "bg", "fg", "accent" } do
				need(typeof(d[key]) == "Color3", "a colour for " .. key)
			end
			-- lettering that stands off its board, and an accent that does too (words on the
			-- accent are drawn in the board's colour)
			need(Signs.contrast(d.bg, d.fg) >= 3, "lettering that stands out")
			need(Signs.contrast(d.bg, d.accent) >= 2.2, "an accent that stands out")
			if e.shop then
				need(
					type(d.short) == "string" and d.short:match("^%u%u%u?%u?%u?%u?$") ~= nil,
					"2 to 6 capitals for a blade"
				)
			end
		end
	end)

	it("has plenty of adverts, no two alike, in a spread of layouts", function()
		expect(#Signs.Adverts >= 16).toBeTruthy()
		local names, styles, fonts, looks = {}, {}, {}, {}
		for _, d in Signs.Adverts do
			if names[d.name] then
				error("two adverts for " .. d.name)
			end
			names[d.name] = true
			styles[d.style] = true
			fonts[d.font] = true
			looks[tostring(d.bg)] = true
		end
		local function count(t)
			local n = 0
			for _ in t do
				n += 1
			end
			return n
		end
		expect(count(styles)).toBe(#Signs.Styles)
		expect(count(fonts)).toBe(#Signs.Fonts)
		expect(count(looks) >= 6).toBeTruthy()
		expect(#Signs.Films >= 4).toBeTruthy()
	end)

	it("gives no two shops of a kind the same name", function()
		for kind, list in Signs.Shops do
			local seen = {}
			for _, d in list do
				if seen[d.name] then
					error(kind .. ": " .. d.name .. " twice")
				end
				seen[d.name] = true
			end
		end
	end)

	it("reads like a person wrote it", function()
		for _, t in texts() do
			local s = t.s
			local function no(found, what)
				if found then
					error(t.where .. ": " .. what .. " in: " .. s)
				end
			end
			no(s:find("\u{2014}") or s:find("\u{2013}"), "a dash")
			no(s:find(" %- ") or s:find("%-%-"), "a dash")
			no(s:find("!"), "an exclamation mark")
			no(s:find("  ") or s:match("^%s") or s:match("%s$"), "stray spaces")
			local lower = s:lower()
			for _, word in BANNED do
				no(lower:find(word, 1, true), "the word " .. word)
			end
			-- plain letters only: the sign fonts have no more
			no(s:find("[^%w %.,'&]"), "a mark the sign fonts may not have")
		end
	end)
end)

describe("Sign picks", function()
	it("are the same for the same spot", function()
		for _, p in { { 735, 165 }, { -640, -166 }, { 0, 0 }, { 1012.2, -228.4 } } do
			local a = Signs.shopAt("bakery", p[1], p[2])
			expect(Signs.shopAt("bakery", p[1], p[2])).toBe(a)
			-- and for a spot a hair off it (a turned building's sums come out a little different)
			expect(Signs.shopAt("bakery", p[1] + 0.003, p[2] - 0.003)).toBe(a)
			local ad = Signs.advertAt(p[1], 12, p[2], 1)
			expect(Signs.advertAt(p[1], 12, p[2], 1)).toBe(ad)
			expect(Signs.streetAt(p[1], p[2])).toBe(Signs.streetAt(p[1], p[2]))
		end
		-- the sums are whole numbers, so they come out the same in Roblox as here
		expect(Signs.hash(0, 0, 0, 0)).toBe(0)
		expect(Signs.hash(1, 2, 3, 4)).toBe(Signs.hash(1.2, 1.8, 3.4, 4))
		expect(Signs.hash(735, 0, 165, 1)).toBe(2552473652)
		expect(Signs.hash(-640, 12, -166, 101)).toBe(1615772380)
	end)

	it("change from spot to spot", function()
		local ads, films, perKind = {}, {}, {}
		local twoSided = 0
		for x = -1000, 1000, 37 do
			for z = -240, 240, 53 do
				ads[Signs.advertAt(x, 6, z, 1).name] = true
				films[Signs.filmAt(x, 6, z, 1).name] = true
				if Signs.advertAt(x, 6, z, 1) ~= Signs.advertAt(x, 6, z, 2) then
					twoSided += 1
				end
				for kind in Signs.Shops do
					perKind[kind] = perKind[kind] or {}
					perKind[kind][Signs.shopAt(kind, x, z).name] = true
				end
			end
		end
		-- every advert, every film and every shop name turns up somewhere
		for _, d in Signs.Adverts do
			if not ads[d.name] then
				error("never picked: " .. d.name)
			end
		end
		for _, d in Signs.Films do
			expect(films[d.name]).toBe(true)
		end
		for kind, list in Signs.Shops do
			for _, d in list do
				if not perKind[kind][d.name] then
					error("never picked: " .. d.name)
				end
			end
		end
		-- a billboard's two sides mostly sell different things
		expect(twoSided > 400).toBeTruthy()
		-- and next door is not the same advert over and over
		local same = 0
		for x = 0, 400, 4 do
			if Signs.advertAt(x, 5, 0, 1) == Signs.advertAt(x + 4, 5, 0, 1) then
				same += 1
			end
		end
		expect(same < 15).toBeTruthy()
	end)

	it("names every road, and the nearest one for a plate", function()
		local names = Signs.roadNames()
		expect(#names).toBe(#Town.Roads)
		local seen = {}
		for i, name in names do
			expect(type(name) == "string" and #name > 3).toBeTruthy()
			if seen[name] then
				error("two roads called " .. name)
			end
			seen[name] = true
			-- a road's own name is kept
			if Town.Roads[i].name then
				expect(name).toBe(Town.Roads[i].name)
			end
		end
		expect(Signs.streetAt(120, 16)).toBe("Main Street")
		expect(Signs.streetAt(-300, Town.RingZ + 12)).toBe("Hill Road")
		expect(Signs.streetAt(300, -Town.RingZ - 12)).toBe("Harbour Road")
		-- at a corner the plate's own direction settles it
		local x, z = Town.AvenueX[1] + 13, 16
		expect(Signs.streetAt(x, z, true)).toBe("Main Street")
		expect(Signs.streetAt(x, z, false)).toBe(names[4])
	end)

	it("turns a word down a blade, and finds a name's initial", function()
		expect(Signs.stack("BREAD")).toBe("B\nR\nE\nA\nD")
		expect(Signs.initial("The Starling")).toBe("S")
		expect(Signs.initial("Harlow's Bakery")).toBe("H")
	end)

	it("stocks a vending machine with cans, no two the same side by side", function()
		for _, p in { { 0, 0 }, { 31, -200 }, { -640.5, 77 } } do
			local rows = Signs.cansAt(p[1], 2, p[2], 3, 5)
			expect(#rows).toBe(3)
			for _, row in rows do
				expect(#row).toBe(5)
				for c = 2, 5 do
					expect(row[c] ~= row[c - 1]).toBeTruthy()
				end
			end
		end
	end)
end)

-- the sign parts of a model: { prim, kind, form } for boards, and the adverts
local function boardsOf(name)
	local signs, ads = {}, {}
	for _, prim in CityModels.prims(name) do
		local attrs = prim.attrs
		if attrs and attrs.SignKind then
			table.insert(signs, prim)
		elseif prim.name == "Ad" then
			table.insert(ads, prim)
		end
	end
	return signs, ads
end

local SIDES = { Front = true, Back = true, Left = true, Right = true }

describe("Sign boards", function()
	it("name a kind the words know, a layout, and the way back to their building", function()
		local used = {}
		local total = 0
		for name in CityModels.Models do
			local signs, ads = boardsOf(name)
			for _, prim in signs do
				local a = prim.attrs
				total += 1
				used[a.SignKind] = true
				if not Signs.Shops[a.SignKind] then
					error(name .. ": no words for a " .. tostring(a.SignKind))
				end
				if not table.find(Signs.Forms, a.SignForm) then
					error(name .. ": no layout called " .. tostring(a.SignForm))
				end
				expect(a.SignFace == nil or SIDES[a.SignFace] == true).toBeTruthy()
				expect(prim.name == "Sign" or prim.name == "SwingSign").toBeTruthy()
				-- home is the building's middle
				expect((prim.cf * a.SignHome).Position.Magnitude < 1e-3).toBeTruthy()
				-- a blade is a blade, a strip a strip
				local s = prim.size
				local thin = math.min(s.X, s.Y, s.Z)
				expect(thin <= 1.3).toBeTruthy()
				if a.SignForm == "blade" then
					expect(s.Y > 2 * math.min(math.max(s.X, s.Z), s.Y)).toBeTruthy()
				end
			end
			for _, prim in ads do
				local s = prim.size
				expect(math.min(s.X, s.Y, s.Z) <= 0.5).toBeTruthy()
				local a = prim.attrs or {}
				expect(a.SignFace == nil or SIDES[a.SignFace] == true).toBeTruthy()
				expect(a.AdKind == nil or a.AdKind == "film").toBeTruthy()
			end
		end
		expect(total > 40).toBeTruthy()
		-- no name is left without a building to go on
		for kind in Signs.Shops do
			if not used[kind] then
				error("no building carries the " .. kind .. " sign")
			end
		end
	end)

	it("are on every shop and public building", function()
		local expectKind = {
			shopCoral = "bakery",
			shopYellow = "grocer",
			shopBlue = "books",
			shopPink = "clothes",
			shopOrange = "cafe",
			shopLilac = "toys",
			shopMint = "flowers",
			deptStore = "department",
			postOffice = "post",
			school = "school",
			clinic = "clinic",
			cinema = "cinema",
			station = "station",
			library = "library",
			museum = "museum",
			fireStation = "fire",
			hotel = "hotel",
			skyTower = "tower",
			officeBlue = "office",
			officeTeal = "office",
			apartmentPeach = "flats",
			apartmentMint = "flats",
			apartmentLilac = "flats",
		}
		for name, kind in expectKind do
			local signs = boardsOf(name)
			if #signs == 0 then
				error(name .. " has no sign")
			end
			local fascia = false
			for _, prim in signs do
				expect(prim.attrs.SignKind).toBe(kind)
				fascia = fascia or prim.attrs.SignForm == "fascia" or prim.attrs.SignForm == "marquee"
			end
			if not fascia then
				error(name .. " has no name over its door")
			end
		end
		-- the towers downtown carry adverts
		for _, name in { "officeBlue", "officeTeal", "skyTower", "apartmentMint" } do
			local _, ads = boardsOf(name)
			expect(#ads >= 3).toBeTruthy()
		end
	end)

	it("give neighbouring shops of a kind different names on the map", function()
		local kindOf = {}
		local function kindFor(name)
			if kindOf[name] == nil then
				-- the old buildings (Data/CityModels) and the street buildings (Data/Facades)
				local signs = if CityModels.Models[name] then boardsOf(name) else {}
				if Facades.spec(name) then
					for _, prim in Facades.prims(name) do
						if prim.attrs and prim.attrs.SignKind then
							table.insert(signs, prim)
						end
					end
				end
				kindOf[name] = if signs[1] then signs[1].attrs.SignKind else false
			end
			return kindOf[name]
		end
		local shops = {}
		for _, p in TownMap.placements() do
			local kind = kindFor(p.name)
			if kind then
				local pos = p.cf.Position
				table.insert(shops, { kind = kind, pos = pos, name = Signs.shopAt(kind, pos.X, pos.Z).name })
			end
		end
		expect(#shops >= 30).toBeTruthy()
		for i, a in shops do
			for j = i + 1, #shops do
				local b = shops[j]
				if a.kind == b.kind and a.name == b.name and (a.pos - b.pos).Magnitude < 260 then
					error(string.format("two called %s within a street of each other", a.name))
				end
			end
		end
	end)
end)

-- Drawing ----------------------------------------------------------------------------------------------

-- A gradient Roblox would take: at most 20 steps, from 0 to 1, each after the last.
local function checkSteps(keys, where)
	if #keys > 20 then
		error(where .. ": " .. #keys .. " steps in a gradient")
	end
	expect(keys[1].Time).toBe(0)
	expect(keys[#keys].Time).toBe(1)
	for i = 2, #keys do
		if keys[i].Time <= keys[i - 1].Time then
			error(where .. ": gradient steps out of order")
		end
	end
end

-- Everything drawn in `root` (W by H pixels) stays on the board, the words are scaled to their
-- boxes, and there is not too much of it. Returns the words found.
local function checkDrawing(root, W, H, where)
	local found = {}
	local count = 0
	local function visit(inst, w, h, turned)
		for _, c in inst:GetChildren() do
			count += 1
			if c:IsA("GuiObject") then
				local cw, ch = c.Size.X.Offset, c.Size.Y.Offset
				local x = c.Position.X.Scale * w + c.Position.X.Offset - cw * c.AnchorPoint.X
				local y = c.Position.Y.Scale * h + c.Position.Y.Offset - ch * c.AnchorPoint.Y
				-- its box once turned
				local a = math.rad(c.Rotation)
				local bw = math.abs(cw * math.cos(a)) + math.abs(ch * math.sin(a))
				local bh = math.abs(cw * math.sin(a)) + math.abs(ch * math.cos(a))
				local cx, cy = x + cw / 2, y + ch / 2
				if not turned then
					if cx - bw / 2 < -1.5 or cx + bw / 2 > w + 1.5 or cy - bh / 2 < -1.5 or cy + bh / 2 > h + 1.5 then
						error(
							string.format(
								"%s: %s %q runs off the board (%d,%d %dx%d on %dx%d)",
								where,
								c.ClassName,
								if c:IsA("TextLabel") then c.Text else c.Name,
								x,
								y,
								cw,
								ch,
								w,
								h
							)
						)
					end
				elseif x < -1.5 or y < -1.5 or x + cw > w + 1.5 or y + ch > h + 1.5 then
					error(where .. ": " .. c.ClassName .. " runs off its turned block")
				end
				if c:IsA("TextLabel") then
					expect(c.TextScaled).toBe(true)
					expect(c.BackgroundTransparency).toBe(1)
					expect(#c.Text > 0).toBeTruthy()
					local cap = c:FindFirstChildOfClass("UITextSizeConstraint")
					if not cap then
						error(where .. ": words with no size limit: " .. c.Text)
					end
					expect(cap.MaxTextSize <= 100 and cap.MaxTextSize >= 1).toBeTruthy()
					table.insert(found, c.Text)
				end
				visit(c, cw, ch, turned or c.Rotation ~= 0)
			elseif c:IsA("UIGradient") then
				checkSteps(c.Transparency.Keypoints, where)
				checkSteps(c.Color.Keypoints, where)
			end
		end
	end
	visit(root, W, H, false)
	if count > 16 then
		error(where .. ": " .. count .. " instances on one face")
	end
	return found, count
end

local function has(found, text)
	for _, t in found do
		if t == text or t == text:upper() then
			return true
		end
	end
	return false
end

describe("Sign drawing", function()
	it("lays every design out on a strip, a poster and a banner without leaving the board", function()
		local shapes =
			{ { 900, 60 }, { 640, 100 }, { 2000, 52 }, { 150, 195 }, { 420, 150 }, { 150, 300 }, { 150, 560 } }
		local most = 0
		for _, e in designs() do
			for _, s in shapes do
				for _, form in { "fascia", "roof" } do
					local root = Instance.new("Frame")
					root.Size = UDim2.fromOffset(s[1], s[2])
					Service.draw(root, s[1], s[2], e.d, form)
					local where = string.format("%s as a %s %dx%d", e.d.name, form, s[1], s[2])
					local found, count = checkDrawing(root, s[1], s[2], where)
					most = math.max(most, count)
					-- the name is on it, whole, or down a blade its short word
					if s[1] / s[2] <= 0.45 and e.d.short then
						expect(has(found, Signs.stack(e.d.short))).toBe(true)
					elseif not has(found, e.d.name) then
						error(where .. ": the name is missing")
					end
				end
			end
		end
		expect(most >= 6).toBeTruthy()
	end)

	it("draws every style, and the other kinds of board", function()
		local d = table.clone(Signs.Adverts[1])
		for _, style in Signs.Styles do
			d.style = style
			for _, s in { { 900, 60 }, { 500, 110 }, { 300, 200 }, { 150, 240 } } do
				local root = Instance.new("Frame")
				Service.draw(root, s[1], s[2], d)
				local found = checkDrawing(root, s[1], s[2], style)
				expect(has(found, d.name)).toBe(true)
			end
		end
		local root = Instance.new("Frame")
		Service.draw(root, 80, 72, Signs.Shops.bakery[1], "tile")
		expect(has(checkDrawing(root, 80, 72, "tile"), "H")).toBe(true)
		root = Instance.new("Frame")
		Service.drawMarquee(root, 1400, 100, Signs.Shops.cinema[1], Signs.Films[1])
		local found = checkDrawing(root, 1400, 100, "marquee")
		expect(has(found, "The Starling") and has(found, Signs.Films[1].name)).toBe(true)
		root = Instance.new("Frame")
		Service.drawPlate(root, 400, 80, "Plum Street")
		expect(has(checkDrawing(root, 400, 80, "plate"), "Plum Street")).toBe(true)
		root = Instance.new("Frame")
		Service.drawVend(root, 120, 200, Signs.cansAt(1, 2, 3, 3, 5), Signs.Colors.Coral)
		local words, count = checkDrawing(root, 120, 200, "vend")
		expect(#words).toBe(0) -- frames only
		expect(count >= 8).toBeTruthy()
	end)
end)

-- a building, built the way the World service builds it
local function build(name, frame)
	local model = Instance.new("Model")
	model.Name = name
	Builder.instantiate(TownMap.prims(name), model, frame)
	return model
end

-- a SurfaceGui's drawing, checked against its own board
local function checkFace(part, gui, where)
	local W, H = 0, 0
	for _, face in Service.faces(part) do
		if face.id == gui.Face then
			W, H = face.w * gui.PixelsPerStud, face.h * gui.PixelsPerStud
		end
	end
	expect(W > 0 and H > 0).toBeTruthy()
	-- sharp enough to read, and not a huge canvas
	expect(math.min(W, H) >= 20 and math.max(W, H) <= 2001).toBeTruthy()
	return checkDrawing(gui, W, H, where)
end

local function guisOn(part)
	local out = {}
	for _, c in part:GetChildren() do
		if c:IsA("SurfaceGui") then
			table.insert(out, c)
		end
	end
	return out
end

describe("Signs service", function()
	it("writes one name on every board of a building, wherever it stands", function()
		local spots = {
			{ "shopCoral", CFrame.new(735, 0.22, 165) },
			{ "shopCoral", CFrame.new(-700, 0, -165) * CFrame.Angles(0, math.pi, 0) },
			{ "deptStore", CFrame.new(630, 0.22, 48) },
			{ "hotel", CFrame.new(650, 0.22, 169) * CFrame.Angles(0, math.rad(90), 0) },
			{ "station", CFrame.new(686, 0.22, -165) * CFrame.Angles(0, math.pi, 0) },
			{ "museum", CFrame.new(-760, 0, 52) },
			{ "clinic", CFrame.new(-960, 0, 42) * CFrame.Angles(0, math.rad(-90), 0) },
		}
		for _, spot in spots do
			local name, frame = spot[1], spot[2]
			local model = build(name, frame)
			local kind, brand = nil, nil
			local boards = 0
			for _, part in model:GetChildren() do
				local k = part:GetAttribute("SignKind")
				if k then
					boards += 1
					kind = k
					brand = Signs.shopAt(k, frame.Position.X, frame.Position.Z)
					local guis = Service.dress(part)
					local form = part:GetAttribute("SignForm")
					if part:GetAttribute("SignFace") then
						expect(#guis).toBe(1)
						expect(guis[1].Face.Name).toBe(part:GetAttribute("SignFace"))
					else
						expect(#guis).toBe(2)
					end
					expect(#guisOn(part)).toBe(#guis)
					for _, gui in guis do
						expect(gui.LightInfluence).toBe(0)
						expect(gui.SizingMode.Name).toBe("PixelsPerStud")
						local found = checkFace(part, gui, name .. " " .. form)
						if form == "blade" then
							expect(has(found, Signs.stack(brand.short))).toBe(true)
						elseif form == "tile" then
							expect(has(found, Signs.initial(brand.name))).toBe(true)
						elseif not has(found, brand.name) then
							error(name .. ": the " .. form .. " does not say " .. brand.name)
						end
					end
					-- asking again writes nothing more
					expect(Service.dress(part)).toBe(guis)
					expect(#guisOn(part)).toBe(#guis)
				end
			end
			expect(boards >= 2).toBeTruthy()
			expect(kind ~= nil).toBeTruthy()
		end
	end)

	it("puts an advert on every Ad, on the side that shows", function()
		local model = build("officeBlue", CFrame.new(890, 0.22, 169))
		local ads, twoSided = 0, 0
		for _, part in model:GetChildren() do
			if part.Name == "Ad" then
				ads += 1
				local guis = Service.dress(part)
				local at = part.CFrame.Position
				if #guis == 2 then
					twoSided += 1
				end
				for i, gui in guis do
					local found = checkFace(part, gui, "advert")
					expect(has(found, Signs.advertAt(at.X, at.Y, at.Z, i).name)).toBe(true)
				end
			end
		end
		expect(ads >= 5).toBeTruthy()
		expect(twoSided).toBe(1) -- the billboard on the roof
		-- the cinema's posters show films
		local cinema = build("cinema", CFrame.new(920, 0.22, 48))
		local posters = 0
		for _, part in cinema:GetChildren() do
			if part.Name == "Ad" then
				posters += 1
				expect(part:GetAttribute("AdKind")).toBe("film")
				local at = part.CFrame.Position
				local found = checkFace(part, Service.dress(part)[1], "poster")
				expect(has(found, Signs.filmAt(at.X, at.Y, at.Z, 1).name)).toBe(true)
			end
		end
		expect(posters).toBe(8)
	end)

	local function board(name, size, cf, face)
		local part = Instance.new("Part")
		part.Name = name
		part.Size = size
		part.CFrame = cf
		if face then
			part:SetAttribute("SignFace", face)
		end
		return part
	end

	it("dresses the other agent's parts: any Ad, a Vend and a Plate", function()
		-- a thin board with nothing said: both big sides
		local ad = board("Ad", Vector3.new(12, 6, 0.4), CFrame.new(100, 20, 30))
		local guis = Service.dress(ad)
		expect(#guis).toBe(2)
		expect(guis[1].Face.Name).toBe("Front")
		expect(guis[2].Face.Name).toBe("Back")
		-- thin the other way
		guis = Service.dress(board("Ad", Vector3.new(0.3, 5, 4), CFrame.new(40, 5, 30)))
		expect(guis[1].Face.Name).toBe("Right")
		expect(guis[2].Face.Name).toBe("Left")
		-- a vending machine's front
		local vend = board("Vend", Vector3.new(3, 5, 0.2), CFrame.new(10, 3, 10), "Front")
		guis = Service.dress(vend)
		expect(#guis).toBe(1)
		local words, count = checkFace(vend, guis[1], "vend")
		expect(#words).toBe(0)
		expect(count >= 8).toBeTruthy()
		expect(vend:FindFirstChildOfClass("SurfaceLight") ~= nil).toBeTruthy()
		-- a street plate by Main Street, running along it, and one across it at the corner
		local x = Town.AvenueX[1] + 13
		local plate = board("Plate", Vector3.new(5, 1, 0.2), CFrame.new(x, 9, 16))
		guis = Service.dress(plate)
		expect(#guis).toBe(2)
		expect(has(checkFace(plate, guis[1], "plate"), "Main Street")).toBe(true)
		local across = board("Plate", Vector3.new(5, 1, 0.2), CFrame.new(x, 10, 16) * CFrame.Angles(0, math.rad(90), 0))
		local found = checkFace(across, Service.dress(across)[1], "plate")
		expect(has(found, Signs.roadNames()[4])).toBe(true)
		-- anything else is left alone
		expect(#Service.dress(board("Wall", Vector3.new(5, 5, 1), CFrame.new()))).toBe(0)
	end)

	it("stands the drawing upright on a board that lies on its side", function()
		-- the board's own top points west and its right points up: the drawing is turned
		local lying =
			board("Ad", Vector3.new(6, 12, 0.4), CFrame.new(0, 10, 0) * CFrame.Angles(0, 0, math.rad(90)), "Back")
		local faces = Service.faces(lying)
		expect(#faces).toBe(1)
		expect(faces[1].turn).toBe(90)
		expect(faces[1].w).toBeNear(6)
		expect(faces[1].h).toBeNear(12)
		local gui = Service.dress(lying)[1]
		local holder = gui:FindFirstChild("Upright")
		expect(holder ~= nil).toBeTruthy()
		expect(holder.Rotation).toBe(90)
		-- wide once upright: 12 across, 6 up
		expect(holder.Size.X.Offset > holder.Size.Y.Offset).toBeTruthy()
		-- upside down
		local flipped = board("Ad", Vector3.new(6, 3, 0.4), CFrame.Angles(0, 0, math.pi), "Front")
		expect(Service.faces(flipped)[1].turn).toBe(180)
		-- and the usual way up, turned any way round
		local upright = board("Ad", Vector3.new(6, 3, 0.4), CFrame.Angles(0, 2.2, 0), "Front")
		expect(Service.faces(upright)[1].turn).toBe(0)
	end)

	it("dresses every board on the map, a handful of instances a face", function()
		local wantedOf = {}
		local boards, faces, instances = 0, 0, 0
		for _, p in TownMap.placements() do
			local wanted = wantedOf[p.name]
			if not wanted then
				wanted = {}
				for _, prim in TownMap.prims(p.name) do
					local n = prim.name
					if n == "Ad" or n == "Vend" or n == "Plate" or (prim.attrs and prim.attrs.SignKind) then
						table.insert(wanted, prim)
					end
				end
				wantedOf[p.name] = wanted
			end
			if #wanted > 0 then
				for _, part in Builder.instantiate(wanted, Instance.new("Model"), p.cf) do
					boards += 1
					local guis = Service.dress(part)
					if #guis == 0 then
						error(p.name .. ": a " .. part.Name .. " was left bare")
					end
					for _, gui in guis do
						faces += 1
						local found, count = checkFace(part, gui, p.name .. " " .. part.Name)
						instances += count + 1
						-- everything but a vending machine's window has something to read
						expect(part.Name == "Vend" or #found > 0).toBeTruthy()
					end
				end
			end
		end
		-- the town is thick with signs, and they are cheap
		expect(boards >= 150).toBeTruthy()
		expect(faces <= 900).toBeTruthy()
		expect(instances / faces <= 11).toBeTruthy()
	end)

	it("shines harder after dark, and lights the street", function()
		local model = build("shopYellow", CFrame.new(775, 0.22, 165))
		local fascia
		for _, part in model:GetChildren() do
			if part:GetAttribute("SignForm") == "fascia" then
				fascia = part
			end
		end
		local gui = Service.dress(fascia)[1]
		local light = fascia:FindFirstChildOfClass("SurfaceLight")
		expect(light ~= nil).toBeTruthy()
		expect(gui.Brightness).toBe(1)
		expect(light.Enabled).toBe(false)
		Service.setNight(true)
		expect(gui.Brightness > 1).toBeTruthy()
		expect(light.Enabled).toBe(true)
		-- a board made after dark starts lit
		local late = board("Ad", Vector3.new(12, 6, 0.4), CFrame.new(7, 20, 7))
		expect(Service.dress(late)[1].Brightness > 1).toBeTruthy()
		Service.setNight(false)
		expect(gui.Brightness).toBe(1)
		expect(light.Enabled).toBe(false)
	end)
end)
