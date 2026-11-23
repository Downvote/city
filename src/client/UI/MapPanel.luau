-- The island map: the sea, the beach, the hills with their peaks and the path up to the lookout,
-- every road, the old town's plots, square and market, downtown's blocks with their rows of
-- buildings, the lanes through them and the market square, the civic quarter's lawns, the
-- boardwalk and the piers. All drawn from the same data the world is built from, in simple flat
-- shapes of our own. A round pin marks every place to find (orange once found, grey with a
-- question mark until then) and a blue dot in a white ring marks you. District names go where no
-- marker is.
-- Beside it, the places in a list: pick one to see it on the map, or press Go to travel there.

local Players = game:GetService("Players")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Town = require(Shared.Data.Town)
local TownMap = require(Shared.Data.TownMap)
local Hills = require(Shared.Data.Hills)
local Places = require(Shared.Data.Places)
local Remotes = require(Shared.Net.Remotes)
local Tuning = require(Shared.Config.Tuning)
local Text = require(Shared.Util.Text)

local Kit = require(script.Parent.Kit)
local MenuParts = require(script.Parent.MenuParts)
local Toasts = require(script.Parent.Toasts)
local State = require(script.Parent.Parent.Controllers.State)

local MapPanel = {}

-- redraws the open map in the current look's colours (set while it is open)
MapPanel.repaint = function() end

local T = Kit.Theme
local panel: any = nil
local alive = false

-- the part of the world the map shows
local X1, X2 = -1180, 1180
local Z1, Z2 = -440, 1040 -- (room over the north cove for its pin)
local MAP_W = 660
local S = MAP_W / (X2 - X1)
local MAP_H = math.floor((Z2 - Z1) * S)
local MARK = 16 -- a place's pin head, across

local function toMap(x: number, z: number): (number, number)
	return (x - X1) * S, (Z2 - z) * S
end

-- The map's own colours: night ones in the dark look, day ones in the light. They are the
-- map's and not the interface's, so a change of look redraws the map rather than repainting it.
type Palette = { [string]: Color3 }
local function rgb(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end
local NIGHT: Palette = {
	sea = rgb(24, 40, 66),
	shallows = rgb(32, 54, 84),
	beach = rgb(92, 84, 64),
	grass = rgb(42, 80, 54),
	hills = rgb(36, 70, 48),
	peakLit = rgb(78, 118, 72),
	peakShade = rgb(56, 92, 58),
	field = rgb(84, 92, 52),
	lake = rgb(40, 74, 112),
	plot = rgb(56, 102, 66),
	lawn = rgb(50, 92, 58),
	paving = rgb(60, 64, 82),
	rows = rgb(40, 43, 58),
	lane = rgb(96, 88, 92),
	square = rgb(88, 92, 114),
	road = rgb(104, 110, 132),
	wood = rgb(120, 94, 66),
	path = rgb(150, 140, 118),
	detail = rgb(30, 32, 44),
}
local DAY: Palette = {
	sea = rgb(150, 200, 230),
	shallows = rgb(172, 216, 238),
	beach = rgb(236, 218, 172),
	grass = rgb(160, 208, 136),
	hills = rgb(138, 190, 120),
	peakLit = rgb(196, 226, 168),
	peakShade = rgb(150, 196, 128),
	field = rgb(222, 210, 132),
	lake = rgb(110, 172, 222),
	plot = rgb(182, 222, 156),
	lawn = rgb(176, 218, 150),
	paving = rgb(208, 210, 222),
	rows = rgb(150, 156, 180),
	lane = rgb(230, 212, 190),
	square = rgb(236, 230, 214),
	road = rgb(246, 246, 250),
	wood = rgb(212, 170, 122),
	path = rgb(206, 186, 150),
	detail = rgb(110, 112, 132),
}

-- the round peaks of the hills (Data/Hills), as little mountains: { x, z, size }
local PEAKS = {
	{ 0, 640, 1 },
	{ -380, 760, 0.85 },
	{ 380, 760, 0.8 },
	{ 860, 720, 0.75 },
	{ -860, 720, 0.75 },
	{ 650, 520, 0.6 },
	{ 200, 440, 0.45 },
	{ -170, 470, 0.5 },
}

-- Where each district's name may go, best first (world x, z). The first spot clear of every
-- marker wins.
local LABELS = {
	{ "Old Town", { { 0, 0 }, { 0, 200 }, { 0, -200 }, { -270, 0 } } },
	{ "Downtown", { { 806, 0 }, { 700, 196 }, { 806, -196 }, { 700, 66 } } },
	{ "Civic Quarter", { { -806, 0 }, { -806, -196 }, { -806, 196 }, { -806, 66 } } },
	{ "The Hills", { { 200, 840 }, { -200, 600 }, { 560, 640 } } },
	{ "Waterfront", { { 620, -362 }, { -620, -362 }, { 100, -362 } } },
}

-- each district as the end of "Look ...", for the places still to find
local WHERE = {
	["Old Town"] = "in the old town",
	["Downtown"] = "downtown",
	["Civic Quarter"] = "in the civic quarter",
	["The Hills"] = "up in the hills",
	["Waterfront"] = "by the water",
}

local function rect(
	parent: Instance,
	x1: number,
	z1: number,
	x2: number,
	z2: number,
	color: Color3,
	name: string?
): Frame
	local ax, ay = toMap(math.min(x1, x2), math.max(z1, z2))
	local bx, by = toMap(math.max(x1, x2), math.min(z1, z2))
	return Kit.frame({
		Name = name or "Shape",
		Parent = parent,
		Position = UDim2.fromOffset(math.floor(ax + 0.5), math.floor(ay + 0.5)),
		Size = UDim2.fromOffset(math.max(1, math.floor(bx - ax + 0.5)), math.max(1, math.floor(by - ay + 0.5))),
		Color = color,
		Radius = false,
	})
end

-- A little mountain: two halves of a triangle, the lit side on the left.
local function mountain(parent: Instance, x: number, z: number, size: number, pal: Palette)
	local cx, cy = toMap(x, z)
	local w = math.floor(54 * size + 0.5)
	local h = math.floor(34 * size + 0.5)
	local half = math.floor(w / 2)
	local top = math.floor(cy - h * 0.55)
	Kit.wedge({
		Parent = parent,
		Color = pal.peakLit,
		Size = UDim2.fromOffset(half, h),
		Position = UDim2.fromOffset(math.floor(cx) - half, top),
		W = half,
		H = h,
	}, "br")
	Kit.wedge({
		Parent = parent,
		Color = pal.peakShade,
		Size = UDim2.fromOffset(half, h),
		Position = UDim2.fromOffset(math.floor(cx), top),
		W = half,
		H = h,
	}, "bl")
end

-- A pin: a round head in a light ring with a short point under it, standing on (x, y). Its
-- head is named Face (the colour says found or not) and carries the "?" while it isn't found.
local PIN_H = MARK + 6
local function pin(parent: Instance, name: string, x: number, y: number): Frame
	local m = Kit.box({
		Name = name,
		Parent = parent,
		Size = UDim2.fromOffset(MARK + 4, PIN_H),
		Position = UDim2.fromOffset(math.floor(x), math.floor(y)),
		AnchorPoint = Vector2.new(0.5, 1),
	})
	m.ZIndex = 4
	local face = Kit.new("Frame", {
		Name = "Face",
		BackgroundColor3 = T.InkSoft,
		BorderSizePixel = 0,
		Size = UDim2.fromOffset(MARK, MARK),
		Position = UDim2.fromOffset(2, 0),
		ZIndex = 5,
		Parent = m,
	})
	Kit.corner(face, "round")
	Kit.rim(face, Color3.fromRGB(244, 244, 246), 2)
	-- the point: two halves of a small triangle, under the head
	for _, side in { { "tr", 0 }, { "tl", 1 } } do
		Kit.wedge({
			Name = "Point",
			Parent = m,
			Color = Color3.fromRGB(244, 244, 246),
			Size = UDim2.fromOffset(4, 8),
			Position = UDim2.new(0.5, side[2] * 4 - 4, 1, -8),
			ZIndex = 4,
			W = 4,
			H = 8,
		}, side[1])
	end
	Kit.text("?", {
		Name = "Mark",
		Parent = face,
		Size = UDim2.fromScale(1, 1),
		TextSize = 11,
		Font = Kit.Fonts.Title,
		Color = T.White,
		AlignX = Enum.TextXAlignment.Center,
		ZIndex = 6,
	})
	return m
end

-- The whole map in the given colours. Returns the map frame and the place markers by id.
local function drawMap(holder: Frame, pal: Palette): (Frame, { [string]: Frame })
	-- (a rounded frame that cuts what is in it to its corners: a CanvasGroup)
	local map = Kit.frame({
		Name = "Map",
		Parent = holder,
		Size = UDim2.fromOffset(MAP_W, MAP_H),
		Color = pal.sea,
		Clips = true,
		Radius = 12,
	})
	map:SetAttribute("KeepColors", true)
	local IX, IN, IS, B = TownMap.IslandX, TownMap.IslandN, TownMap.IslandS, TownMap.Beach
	rect(map, -IX - B - 40, -IS - B - 40, IX + B + 40, IN + B + 40, pal.shallows, "Shallows")
	rect(map, -IX - B, -IS - B, IX + B, IN + B, pal.beach, "Beach")
	rect(map, -IX, -IS, IX, IN, pal.grass, "Grass")

	-- the hills: a darker band, fields on the farm's plateau, the mountain lake, the peaks, and
	-- the stepping stones up from Hill Road to the lookout
	rect(map, Hills.X1 + 40, Hills.Z1 + 30, Hills.X2 - 40, Hills.Z2 - 30, pal.hills, "Hills")
	for _, f in { { -780, 430, -700, 480 }, { -690, 430, -620, 500 }, { -780, 490, -700, 550 } } do
		rect(map, f[1], f[2], f[3], f[4], pal.field, "Field")
	end
	rect(map, 830, 700, 890, 740, pal.lake, "Lake")
	for _, p in PEAKS do
		mountain(map, p[1], p[2], p[3], pal)
	end
	do
		local z = Town.RingZ + 18
		local top = Hills.Plateaus[1]
		local step = 0
		while z < top.z - top.r do
			local t = (z - Town.RingZ) / (top.z - Town.RingZ)
			local x = math.sin(t * math.pi * 2.2) * 40 * (1 - t)
			if step % 4 == 0 then
				local px, py = toMap(x, z)
				Kit.frame({
					Name = "Path",
					Parent = map,
					Size = UDim2.fromOffset(3, 3),
					Position = UDim2.fromOffset(math.floor(px) - 1, math.floor(py) - 1),
					Color = pal.path,
					Radius = false,
				})
			end
			step += 1
			z += 7
		end
	end

	-- the old town: the plots, the square (north) and the market (south) on Main Street
	local size = Tuning.Plot.Size
	for i = 1, Tuning.Plot.Count do
		local f = Town.plotFrame(i)
		local a = f * Vector3.new(0, 0, 0)
		local b = f * Vector3.new(size, 0, size)
		rect(map, a.X, a.Z, b.X, b.Z, pal.plot, "Plot")
	end
	for _, c in { Town.SquareCenter, Town.MarketCenter } do
		rect(map, c.X - 50, c.Z - 60, c.X + 50, c.Z + 60, pal.square, "Square")
	end

	-- downtown: every block paved, a row of buildings along each of its edges, a lane through the
	-- middle; south of Main Street the market block with its square open to the street, its lane
	-- of shops and a pocket park (as Data/TownMap lays them out)
	local SET, DEEP = 6, 14
	for _, b in TownMap.blocks("east") do
		rect(map, b[1], b[2], b[3], b[4], pal.paving, "Block")
		rect(map, b[1] + SET, b[2] + SET, b[3] - SET, b[4] - SET, pal.rows, "Rows")
		local market = b[1] == 559 and b[4] == -22
		if market then
			rect(map, b[1], -76, b[3], -60, pal.lane, "Lane")
			rect(map, 660, -62, 712, b[4], pal.square, "MarketSquare")
			rect(map, 660, b[2] + SET + DEEP, 712, -76, pal.lawn, "Park")
		else
			local d = SET + DEEP
			rect(map, b[1] + d, b[2] + d, b[3] - d, b[4] - d, pal.paving, "Yard")
			local mid = math.floor((b[2] + b[4]) / 2)
			rect(map, b[1], mid - 5, b[3], mid + 6, pal.lane, "Lane")
		end
	end

	-- the civic quarter: lawns with gravel paths, the pond in its park and the school's field
	for _, b in TownMap.blocks("west") do
		rect(map, b[1], b[2], b[3], b[4], pal.lawn, "Lawn")
		local mid = (b[2] + b[4]) / 2
		rect(map, b[1], mid - 4, b[3], mid + 4, pal.path, "Gravel")
	end
	rect(map, -725, -97, -667, -39, pal.lake, "Pond")
	rect(map, -1010, 154, -890, 226, pal.plot, "Field")

	-- the roads
	for _, road in Town.Roads do
		local hw = road[5] + 2
		if road[2] == road[4] then
			rect(map, road[1], road[2] - hw, road[3], road[2] + hw, pal.road, "Road")
		else
			rect(map, road[1] - hw, road[2], road[1] + hw, road[4], pal.road, "Road")
		end
	end
	-- the footbridge over Main Street, and the gate into the square
	rect(map, 270, -19, 278, 19, pal.detail, "Footbridge")
	rect(map, -18, 22, 18, 30, pal.detail, "Gate")

	-- the boardwalk and the piers
	rect(map, -IX + 30, -IS, IX - 30, -(Town.RingZ + 17), pal.wood, "Boardwalk")
	rect(map, 294, -IS, 306, -IS - 78, pal.wood, "Pier")
	rect(map, -380, -IS - 40, -260, -IS - 130, pal.wood, "Pier")
	rect(map, 996, -IS - 20, 1004, -IS - 74, pal.wood, "Pier")

	-- the places: a round pin each, its point on the spot
	local markers: { [string]: Frame } = {}
	for _, place in Places.list do
		local cx, cy = toMap(place.pos.X, place.pos.Z)
		markers[place.id] = pin(map, place.id, cx, cy)
	end

	-- district names, each on the first of its spots that keeps clear of every marker
	local taken: { { number } } = {}
	for _, place in Places.list do
		local cx, cy = toMap(place.pos.X, place.pos.Z)
		local r = MARK / 2 + 4
		table.insert(taken, { cx - r, cy - PIN_H - 4, cx + r, cy + 4 })
	end
	for _, l in LABELS do
		local name: string = l[1]
		local w = #name * 8 + 8
		local spot = l[2][1]
		for _, s in l[2] do
			local cx, cy = toMap(s[1], s[2])
			local box = { cx - w / 2, cy - 10, cx + w / 2, cy + 10 }
			local clear = true
			for _, t in taken do
				if box[1] < t[3] and box[3] > t[1] and box[2] < t[4] and box[4] > t[2] then
					clear = false
					break
				end
			end
			if clear then
				spot = s
				table.insert(taken, box)
				break
			end
		end
		local cx, cy = toMap(spot[1], spot[2])
		Kit.text(name, {
			Name = "District",
			Parent = map,
			Size = UDim2.fromOffset(w, 18),
			Position = UDim2.fromOffset(math.floor(cx - w / 2), math.floor(cy - 9)),
			TextSize = 14,
			Font = Kit.Fonts.Title,
			Color = T.White,
			Outline = rgb(16, 18, 26),
			AlignX = Enum.TextXAlignment.Center,
			Wrap = false,
			ZIndex = 3,
		})
	end
	return map, markers
end

-- A small key under the map: what the three marks mean.
local function legend(parent: Instance)
	local key = Kit.box({
		Name = "Legend",
		Parent = parent,
		Size = UDim2.new(1, 0, 0, 20),
		Position = UDim2.new(0, 0, 1, -20),
	})
	Kit.list(key, 18, true)
	for i, k in { { "Found", T.Orange }, { "Still to find", T.InkSoft }, { "You", T.Blue } } do
		local item = Kit.box({ Parent = key, Size = UDim2.fromOffset(0, 20), LayoutOrder = i })
		item.AutomaticSize = Enum.AutomaticSize.X
		Kit.list(item, 8, true)
		Kit.disc({ Name = "Key", Parent = item, Size = 12, Color = k[2], LayoutOrder = 1 })
		Kit.text(k[1], {
			Parent = item,
			Size = UDim2.fromOffset(0, 20),
			AutomaticSize = Enum.AutomaticSize.X,
			TextSize = 14,
			Color = T.InkSoft,
			Wrap = false,
			LayoutOrder = 2,
		})
	end
end

function MapPanel.isOpen(): boolean
	return panel ~= nil
end

function MapPanel.close()
	alive = false
	if panel then
		panel.root:Destroy()
		panel = nil
	end
end

-- which place the list has picked, to show on the map
local picked: string? = nil

function MapPanel.open()
	MapPanel.close()
	panel = Kit.panel("Map", Kit.MenuSize, function()
		MapPanel.close()
	end, "map", T.Blue)
	alive = true
	picked = nil
	local body = panel.body
	-- the map on the card on the left, the places down the right
	local cardW = MAP_W + MenuParts.Pad * 2
	local _, inside = MenuParts.card(body, T.Blue, { Size = UDim2.new(0, cardW, 1, 0) })
	local count = Kit.title("", {
		Name = "Count",
		Parent = inside,
		Size = UDim2.new(0.5, 0, 0, 28),
		TextSize = 22,
		Wrap = false,
	})
	local _, fillBar = Kit.bar({
		Parent = inside,
		Size = UDim2.fromOffset(200, 10),
		Position = UDim2.new(1, -2, 0, 9),
		AnchorPoint = Vector2.new(1, 0),
	}, 0, T.Orange)
	local mapHolder = Kit.box({
		Name = "MapHolder",
		Parent = inside,
		Size = UDim2.fromOffset(MAP_W, MAP_H),
		Position = UDim2.fromOffset(0, 38),
	})
	legend(inside)

	local markers: { [string]: Frame } = {}
	local me: Frame
	local function paintMap()
		for _, c in mapHolder:GetChildren() do
			c:Destroy()
		end
		local map
		map, markers = drawMap(mapHolder, if Kit.ThemeName == "light" then DAY else NIGHT)
		-- you: a blue dot in a white ring
		me = Kit.box({
			Name = "Me",
			Parent = map,
			Size = UDim2.fromOffset(20, 20),
			Position = UDim2.fromOffset(-40, -40),
			AnchorPoint = Vector2.new(0.5, 0.5),
		})
		me.ZIndex = 6
		for i, k in { { "You", T.White, 18 }, { "YouDot", T.Blue, 10 } } do
			local f = Kit.new("Frame", {
				Name = k[1],
				BackgroundColor3 = k[2],
				BorderSizePixel = 0,
				Size = UDim2.fromOffset(k[3], k[3]),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				ZIndex = 6 + i,
				Parent = me,
			})
			Kit.corner(f, "round")
		end
	end
	paintMap()

	-- the list beside the map
	local list = MenuParts.list(body, {
		Size = UDim2.new(1, -(cardW + MenuParts.Gap), 1, 0),
		Position = UDim2.fromOffset(cardW + MenuParts.Gap, 0),
	})

	local fill
	-- a place picked in the list stands out on the map, its name on a tag over it
	local function showPicked()
		for id, m in markers do
			local on = id == picked
			local grow = if on then 6 else 0
			m.Size = UDim2.fromOffset(MARK + 4 + grow, PIN_H + grow)
			local face = m:FindFirstChild("Face")
			if face and face:IsA("Frame") then
				face.Size = UDim2.fromOffset(MARK + grow, MARK + grow)
			end
			m.ZIndex = if on then 8 else 4
			local tag = m:FindFirstChild("Tag")
			if tag then
				tag:Destroy()
			end
			if on then
				local place = nil
				for _, p in Places.list do
					if p.id == id then
						place = p
					end
				end
				if place then
					local w = #place.name * 8 + 24
					local t = Kit.frame({
						Name = "Tag",
						Parent = m,
						Size = UDim2.fromOffset(w, 24),
						Position = UDim2.new(0.5, 0, 0, -4),
						AnchorPoint = Vector2.new(0.5, 1),
						Color = rgb(16, 18, 26),
						Transparency = 0.1,
						Radius = "pill",
						ZIndex = 9,
					})
					Kit.text(place.name, {
						Parent = t,
						Size = UDim2.fromScale(1, 1),
						TextSize = 14,
						Font = Kit.Fonts.Title,
						Color = T.White,
						AlignX = Enum.TextXAlignment.Center,
						Wrap = false,
						ZIndex = 10,
					})
					Kit.bump(m, 1.15)
				end
			end
		end
	end

	-- a row with a round mark, a name and a line under it on up to two lines
	local function placeRow(
		name: string,
		title: string,
		sub: string,
		color: Color3,
		order: number,
		sunk: boolean,
		rightSpace: number,
		onClick: (() -> ())?
	): (GuiObject, Frame)
		local row, inner = Kit.row({
			Name = name,
			Parent = list,
			Size = MenuParts.rowSize(72),
			Height = 72,
			LayoutOrder = order,
			Sunk = sunk,
		}, onClick)
		local lean = row:GetAttribute("Lean") or 6
		Kit.disc({
			Name = "Marker",
			Parent = inner,
			Size = 40,
			Position = UDim2.new(0, lean + 6, 0.5, -20),
			Color = color,
			Icon = "map",
			ZIndex = 2,
		})
		local textX = lean + 62
		local w = -(textX + rightSpace + lean)
		Kit.new("TextLabel", {
			Name = "Title",
			Text = title,
			BackgroundTransparency = 1,
			Font = Kit.Fonts.Title,
			TextSize = 17,
			TextColor3 = if sunk then T.InkSoft else T.Ink,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Size = UDim2.new(1, w, 0, 22),
			Position = UDim2.fromOffset(textX, 8),
			ZIndex = 2,
			Parent = inner,
		})
		Kit.new("TextLabel", {
			Name = "Sub",
			Text = sub,
			BackgroundTransparency = 1,
			Font = Kit.Fonts.Body,
			TextSize = 14,
			TextColor3 = T.InkSoft,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
			TextWrapped = true,
			Size = UDim2.new(1, w, 0, 34),
			Position = UDim2.fromOffset(textX, 31),
			ZIndex = 2,
			Parent = inner,
		})
		return row, inner
	end

	fill = function()
		local found = State.data.found or {}
		for _, c in list:GetChildren() do
			if c:IsA("GuiObject") then
				c:Destroy()
			end
		end
		local n = 0
		local left: { [string]: boolean } = {}
		local leftCount = 0
		for _, place in Places.list do
			local got = found[place.id] == true
			local m = markers[place.id]
			local face = m and m:FindFirstChild("Face")
			if face and face:IsA("Frame") then
				face.BackgroundColor3 = if got then T.Orange else T.InkSoft
			end
			local mark = m and m:FindFirstChild("Mark", true)
			if mark and mark:IsA("TextLabel") then
				mark.Text = if got then "" else "?"
			end
			if got then
				n += 1
			else
				leftCount += 1
				for _, d in Town.Districts do
					local x, z = place.pos.X, place.pos.Z
					if x >= d.x1 - 60 and x <= d.x2 + 60 and z >= d.z1 - 60 and z <= d.z2 + 60 then
						left[d.name] = true
						break
					end
				end
				if place.pos.Z > Hills.Z2 then
					left["The Hills"] = true
				end
			end
		end
		count.Text = Text.fill("Found {n} of {total}", { n = n, total = #Places.list })
		fillBar.Size = UDim2.fromScale(n / math.max(1, #Places.list), 1)

		local rows: { [string]: GuiObject } = {}
		local order = 1
		MenuParts.heading(list, "Found", T.Blue, order, tostring(n))
		for _, place in Places.list do
			if found[place.id] == true then
				order += 1
				local row, inner = placeRow(
					"Row_" .. place.id,
					place.name,
					place.blurb,
					T.Orange,
					order,
					false,
					76,
					function()
						picked = if picked == place.id then nil else place.id
						for id, r in rows do
							Kit.setRowSelected(r, id == picked)
						end
						showPicked()
					end
				)
				rows[place.id] = row
				if place.id == picked then
					Kit.setRowSelected(row, true)
				end
				local lean = row:GetAttribute("Lean") or 6
				Kit.button("Go", {
					Name = "Go",
					Parent = inner,
					Size = UDim2.fromOffset(56, 36),
					Position = UDim2.new(1, -(lean + 12), 0.5, 0),
					AnchorPoint = Vector2.new(1, 0.5),
					Color = T.Blue,
					TextSize = 16,
					Radius = "pill",
					ZIndex = 3,
				}, function()
					task.spawn(function()
						local ok, err = Remotes.fn("Travel"):InvokeServer(place.id)
						if ok then
							MapPanel.close()
						elseif err then
							Toasts.show(err, "warn")
						end
					end)
				end)
			end
		end
		if n == 0 then
			order += 1
			MenuParts.note(
				"Nothing found yet. Walk up to a grey pin to put it on the map.",
				T.Blue,
				{ Parent = list, LayoutOrder = order, Height = 44 }
			)
		end
		-- what's left, in one row instead of a stack of blanks
		order += 1
		if leftCount > 0 then
			local where = {}
			for _, d in Town.Districts do
				if left[d.name] then
					table.insert(where, WHERE[d.name] or d.name)
				end
			end
			local sub = if #where == 0
				then "Keep exploring."
				elseif #where == 1 then Text.fill("Look {a}.", { a = where[1] })
				else Text.fill(
					"Look {list} and {last}.",
					{ list = table.concat(where, ", ", 1, #where - 1), last = where[#where] }
				)
			MenuParts.heading(list, "Still to find", T.Blue, order, tostring(leftCount))
			order += 1
			placeRow(
				"Unfound",
				if leftCount == 1
					then "One more place to find"
					else Text.fill("{n} more places to find", { n = leftCount }),
				sub,
				T.Line,
				order,
				true,
				8
			)
		else
			MenuParts.note("You've found every place on the island.", T.Blue, { Parent = list, LayoutOrder = order })
		end
		showPicked()
	end
	fill()

	-- keep your dot where you are while the map is open
	task.spawn(function()
		while alive and panel do
			local char = Players.LocalPlayer.Character
			local root = char and char:FindFirstChild("HumanoidRootPart")
			if root and root:IsA("BasePart") and me then
				local x, y = toMap(root.Position.X, root.Position.Z)
				me.Position = UDim2.fromOffset(x, y)
			end
			task.wait(0.25)
		end
	end)
	local stop = State.on("found", function()
		if panel then
			fill()
		end
	end)
	-- a change of look redraws the map in that look's colours
	MapPanel.repaint = function()
		if panel then
			paintMap()
			fill()
		end
	end
	panel.root.Destroying:Connect(function()
		if type(stop) == "function" then
			stop()
		end
	end)
	Kit.popIn(panel.root)
end

Kit.onTheme(function()
	MapPanel.repaint()
end)

return MapPanel
