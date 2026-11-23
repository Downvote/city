-- The island map: the sea, the beach, the hills, every road, the plots, downtown's blocks and the
-- piers, drawn from the same data the world is built from; a marker for every place to find
-- (orange once found, grey with a question mark until then) and a dot for you. Beside it, the
-- places in a list: found ones have a Go button that takes you there.

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
local Toasts = require(script.Parent.Toasts)
local State = require(script.Parent.Parent.Controllers.State)

local MapPanel = {}

local T = Kit.Theme
local panel: any = nil
local alive = false

-- the part of the world the map shows
local X1, X2 = -1180, 1180
local Z1, Z2 = -450, 1010
local MAP_W = 600
local S = MAP_W / (X2 - X1)
local MAP_H = math.floor((Z2 - Z1) * S)

local function toMap(x: number, z: number): (number, number)
	return (x - X1) * S, (Z2 - z) * S
end

local function rect(
	parent: Instance,
	x1: number,
	z1: number,
	x2: number,
	z2: number,
	color: Color3,
	radius: any?
): Frame
	local ax, ay = toMap(math.min(x1, x2), math.max(z1, z2))
	local bx, by = toMap(math.max(x1, x2), math.min(z1, z2))
	return Kit.frame({
		Parent = parent,
		Position = UDim2.fromOffset(ax, ay),
		Size = UDim2.fromOffset(math.max(1, bx - ax), math.max(1, by - ay)),
		Color = color,
		Radius = radius or false,
	})
end

local function drawMap(holder: Frame): (Frame, { [string]: Frame })
	local map = Kit.frame({
		Name = "Map",
		Parent = holder,
		Size = UDim2.fromOffset(MAP_W, MAP_H),
		Color = Color3.fromRGB(86, 164, 232),
		Radius = 18,
		Clips = true,
	})
	local IX, IN, IS, B = TownMap.IslandX, TownMap.IslandN, TownMap.IslandS, TownMap.Beach
	rect(map, -IX - B, -IS - B, IX + B, IN + B, Color3.fromRGB(250, 232, 186), 10)
	rect(map, -IX, -IS, IX, IN, Color3.fromRGB(140, 210, 96), 6)
	-- the hills, darker toward their tops
	rect(map, Hills.X1 + 40, Hills.Z1 + 30, Hills.X2 - 40, Hills.Z2 - 30, Color3.fromRGB(122, 194, 84), 18)
	for _, p in Hills.Plateaus do
		local h = Hills.plateau(p.name)
		local d = (p.r + 80) * 2 * S
		local cx, cy = toMap(p.x, p.z)
		Kit.frame({
			Parent = map,
			Size = UDim2.fromOffset(d, d),
			Position = UDim2.fromOffset(cx, cy),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Color = Color3.fromRGB(122, 194, 84):Lerp(Color3.fromRGB(176, 214, 110), math.clamp(h / 90, 0, 1)),
			Radius = "circle",
		})
	end
	-- downtown's paved blocks, the square and the market, the plots
	for _, b in TownMap.blocks("east") do
		rect(map, b[1], b[2], b[3], b[4], Color3.fromRGB(226, 230, 236), 3)
	end
	for _, c in { Town.SquareCenter, Town.MarketCenter } do
		rect(map, c.X - 50, c.Z - 60, c.X + 50, c.Z + 60, Color3.fromRGB(236, 238, 240), 3)
	end
	local size = Tuning.Plot.Size
	for i = 1, Tuning.Plot.Count do
		local f = Town.plotFrame(i)
		local a = f * Vector3.new(0, 0, 0)
		local b = f * Vector3.new(size, 0, size)
		rect(map, a.X, a.Z, b.X, b.Z, Color3.fromRGB(176, 226, 140), 4)
	end
	-- the roads
	for _, road in Town.Roads do
		local hw = road[5] + 2
		if road[2] == road[4] then
			rect(map, road[1], road[2] - hw, road[3], road[2] + hw, Color3.fromRGB(120, 128, 146))
		else
			rect(map, road[1] - hw, road[2], road[1] + hw, road[4], Color3.fromRGB(120, 128, 146))
		end
	end
	-- the boardwalk and the piers
	rect(map, -IX + 30, -IS, IX - 30, -(Town.RingZ + 17), Color3.fromRGB(214, 172, 124))
	rect(map, 296, -IS, 304, -IS - 78, Color3.fromRGB(214, 172, 124))
	rect(map, -380, -IS - 40, -260, -IS - 130, Color3.fromRGB(214, 172, 124), 3)
	rect(map, 998, -IS - 20, 1002, -IS - 74, Color3.fromRGB(214, 172, 124))
	-- district names
	for _, d in Town.Districts do
		local cx, cy = toMap((d.x1 + d.x2) / 2, (d.z1 + d.z2) / 2)
		if d.name == "The Hills" then
			cx, cy = toMap(200, 820)
		elseif d.name == "Waterfront" then
			cx, cy = toMap(600, -360)
		end
		Kit.text(d.name, {
			Parent = map,
			Size = UDim2.fromOffset(140, 18),
			Position = UDim2.fromOffset(cx - 70, cy - 9),
			TextSize = 14,
			Font = Kit.Fonts.Title,
			Color = T.White,
			Outline = Color3.fromRGB(40, 60, 90),
			AlignX = Enum.TextXAlignment.Center,
		})
	end
	-- the places
	local markers: { [string]: Frame } = {}
	for _, place in Places.list do
		local cx, cy = toMap(place.pos.X, place.pos.Z)
		local m = Kit.frame({
			Name = place.id,
			Parent = map,
			Size = UDim2.fromOffset(18, 18),
			Position = UDim2.fromOffset(cx, cy),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Color = T.InkSoft,
			Radius = "circle",
			ZIndex = 3,
		})
		Kit.text("?", {
			Name = "Mark",
			Parent = m,
			Size = UDim2.fromScale(1, 1),
			TextSize = 13,
			Font = Kit.Fonts.Title,
			Color = T.White,
			AlignX = Enum.TextXAlignment.Center,
			ZIndex = 4,
		})
		markers[place.id] = m
	end
	return map, markers
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

function MapPanel.open()
	MapPanel.close()
	panel = Kit.panel("Map", UDim2.fromOffset(900, MAP_H + 120), function()
		MapPanel.close()
	end, "map", T.Blue)
	alive = true
	local body = panel.body
	local map, markers = drawMap(body)
	local me = Kit.frame({
		Name = "You",
		Parent = map,
		Size = UDim2.fromOffset(16, 16),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Color = T.White,
		Radius = "circle",
		ZIndex = 5,
	})
	Kit.frame({
		Parent = me,
		Size = UDim2.fromOffset(10, 10),
		Position = UDim2.fromOffset(3, 3),
		Color = T.Blue,
		Radius = "circle",
		ZIndex = 6,
	})

	-- the list beside the map
	local side = Kit.box({
		Parent = body,
		Size = UDim2.new(1, -(MAP_W + 18), 1, 0),
		Position = UDim2.fromOffset(MAP_W + 18, 0),
	})
	local count = Kit.title("", { Parent = side, Size = UDim2.new(1, 0, 0, 28), TextSize = 20 })
	local list = Kit.scroll({ Parent = side, Size = UDim2.new(1, 0, 1, -34), Position = UDim2.fromOffset(0, 34) })
	Kit.list(list, 6)

	local function fill()
		local found = State.data.found or {}
		local n = 0
		for _, c in list:GetChildren() do
			if c:IsA("GuiObject") then
				c:Destroy()
			end
		end
		for i, place in Places.list do
			local got = found[place.id] == true
			if got then
				n += 1
			end
			local m = markers[place.id]
			m.BackgroundColor3 = if got then T.Orange else T.InkSoft
			local mark = m:FindFirstChild("Mark")
			if mark and mark:IsA("TextLabel") then
				mark.Text = if got then "" else "?"
			end
			local row = Kit.frame({
				Parent = list,
				Size = UDim2.new(1, -10, 0, 50),
				Color = if got then T.White else T.PaperDark,
				Radius = 16,
				LayoutOrder = if got then i else 100 + i,
			})
			Kit.text(if got then place.name else "Somewhere out there", {
				Parent = row,
				Size = UDim2.new(1, -78, 0, 20),
				Position = UDim2.fromOffset(12, 6),
				TextSize = 15,
				Font = Kit.Fonts.Title,
				Color = if got then T.Ink else T.InkSoft,
			})
			Kit.text(if got then place.blurb else "Keep exploring.", {
				Parent = row,
				Size = UDim2.new(1, -78, 0, 16),
				Position = UDim2.fromOffset(12, 27),
				TextSize = 12,
				Color = T.InkSoft,
				Wrap = false,
			}).TextTruncate =
				Enum.TextTruncate.AtEnd
			if got then
				Kit.button("Go", {
					Parent = row,
					Size = UDim2.fromOffset(56, 34),
					Position = UDim2.new(1, -8, 0.5, 0),
					AnchorPoint = Vector2.new(1, 0.5),
					Color = T.Blue,
					TextSize = 16,
					Radius = "pill",
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
		count.Text = Text.fill("Found {n} of {total}", { n = n, total = #Places.list })
	end
	fill()

	-- keep your dot where you are while the map is open
	task.spawn(function()
		while alive and panel do
			local char = Players.LocalPlayer.Character
			local root = char and char:FindFirstChild("HumanoidRootPart")
			if root and root:IsA("BasePart") then
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
	panel.root.Destroying:Connect(function()
		if type(stop) == "function" then
			stop()
		end
	end)
	Kit.popIn(panel.root)
end

return MapPanel
