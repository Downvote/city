--!strict
-- The season on this player's screen (the user: "make seasons more noticeable and better
-- polished"): the town's trees in blossom, green, red and gold or under snow, every lawn and grass
-- part in the season's green (or white), snow on the roofs in winter, and a short notice when the
-- season turns. The colours are Data/Seasons' (the server turns the terrain's own grass: World);
-- here they are put on the parts in town and on the plots, and on whatever is built later. A
-- part's own colour is kept in its SeasonBase attribute, so a copy of it (a lawn cut round a pool)
-- starts from the colour it was drawn, never from a season's.

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Seasons = require(Shared.Data.Seasons)
local Textures = require(Shared.Data.Textures)

local Seasonal = {}

local BASE = "SeasonBase"
local FIR = Color3.fromRGB(72, 112, 78) -- a fir's boughs, all one colour under the snow

local season = 0
local turning = 0 -- counts the passes, so an old one stops when a new one starts

local function baseOf(part: BasePart): Color3
	local saved = part:GetAttribute(BASE)
	if typeof(saved) == "Color3" then
		return saved
	end
	part:SetAttribute(BASE, part.Color)
	return part.Color
end

local function setColor(part: BasePart, color: Color3)
	if part.Color ~= color then
		part.Color = color
	end
end

-- How high a part's top is, how tall and how much ground it covers, by its box in the world.
local function extent(part: BasePart): (number, number, number)
	local cf, size = part.CFrame, part.Size
	local function across(axis: Vector3): number
		return math.abs(cf.XVector:Dot(axis)) * size.X
			+ math.abs(cf.YVector:Dot(axis)) * size.Y
			+ math.abs(cf.ZVector:Dot(axis)) * size.Z
	end
	local tall = across(Vector3.yAxis)
	return cf.Position.Y + tall / 2, tall, across(Vector3.xAxis) * across(Vector3.zAxis)
end

local function shapeOf(part: BasePart): string
	if part:IsA("WedgePart") then
		return "Wedge"
	elseif part:IsA("CornerWedgePart") then
		return "CornerWedge"
	elseif part:IsA("Part") and part.Shape == Enum.PartType.Block then
		return "Block"
	end
	return "Round"
end

local function buildKind(part: BasePart): string?
	local at: Instance? = part.Parent
	for _ = 1, 3 do
		if not at then
			return nil
		end
		local kind = at:GetAttribute("BuildKind")
		if type(kind) == "string" then
			return kind
		end
		at = at.Parent
	end
	return nil
end

-- Is the sky open over a part (nothing solid over its top)? Snow lies only there.
local skyParams = RaycastParams.new()
skyParams.FilterType = Enum.RaycastFilterType.Exclude
local function openSky(part: BasePart, top: number): boolean
	local skip: { Instance } = { part }
	for _, p in Players:GetPlayers() do
		if p.Character then
			table.insert(skip, p.Character)
		end
	end
	skyParams.FilterDescendantsInstances = skip
	local from = Vector3.new(part.Position.X, top + 0.3, part.Position.Z)
	local hit = workspace:Raycast(from, Vector3.new(0, 300, 0), skyParams)
	return hit == nil or (hit.Instance :: BasePart).Transparency >= 0.9
end

-- Puts season `s` on one part: a tree's leaves, a grass part, a roof, or nothing.
local function dress(part: BasePart, s: number)
	if part.Transparency >= 0.99 then
		return
	end
	local material = part.Material.Name
	if part.Name == "Leaf" then
		if part:IsA("PartOperation") then
			-- a fir drawn as one merged piece keeps its own colours unless snow is on it
			local look = Seasons.at(s)
			local op = part :: any
			if look.frost > 0 then
				pcall(function()
					op.UsePartColor = true
				end)
				setColor(part, Seasons.leaf(s, "fir", FIR, 0))
			else
				pcall(function()
					op.UsePartColor = false
				end)
			end
			return
		end
		local kind = Seasons.leafKind({ material = material, shape = shapeOf(part) })
		local at = part.Position
		local mid = Textures.tint(material, Seasons.Mid)
		local color = Seasons.leaf(s, kind, baseOf(part), Seasons.seed(at.X, at.Z), mid)
		if Seasons.repaints(s, kind) then
			-- (blossom and autumn's colours, painted as the Builder paints: Data/Textures)
			color = Textures.tint(material, color)
		end
		setColor(part, color)
		return
	end
	if part:IsA("PartOperation") then
		return -- a merged piece keeps the colours it was drawn in
	end
	if material == "Grass" or material == "LeafyGrass" then
		setColor(part, Seasons.grass(s, baseOf(part)))
		return
	end
	local top, tall, area = extent(part)
	local info = {
		name = part.Name,
		material = material,
		shape = shapeOf(part),
		top = top,
		tall = tall,
		area = area,
		kind = buildKind(part),
	}
	if Seasons.isRoof(info) then
		local snowy = Seasons.at(s).roofSnow > 0
		if snowy and openSky(part, top) then
			setColor(part, Seasons.roof(s, baseOf(part)))
		elseif part:GetAttribute(BASE) ~= nil then
			setColor(part, baseOf(part))
		end
	end
end

-- Every part in town and on the plots, a few thousand a frame.
local function dressAll(s: number)
	turning += 1
	local mine = turning
	local count = 0
	for _, name in { "Town", "Plots" } do
		local folder = workspace:FindFirstChild(name)
		if folder then
			for _, d in folder:GetDescendants() do
				if mine ~= turning then
					return
				end
				if d:IsA("BasePart") then
					dress(d, s)
					count += 1
					if count % 1500 == 0 then
						task.wait()
					end
				end
			end
		end
	end
end

function Seasonal.current(): number
	return season
end

-- What was added to the town or a plot since (a new build, a lawn drawn again), dressed a batch
-- at a time a moment after it arrives, once it has its place and its paint.
local queue: { BasePart } = {}
local working = false
local function work()
	if working then
		return
	end
	working = true
	task.delay(0.2, function()
		while #queue > 0 do
			local batch = queue
			queue = {}
			for i, part in batch do
				if part.Parent and season > 0 then
					dress(part, season)
				end
				if i % 1500 == 0 then
					task.wait()
				end
			end
			task.wait()
		end
		working = false
	end)
end

local function watch(folder: Instance)
	folder.DescendantAdded:Connect(function(d)
		if d:IsA("BasePart") and season > 0 then
			table.insert(queue, d)
			work()
		end
	end)
end

function Seasonal.start()
	local function now(): number
		local s = workspace:GetAttribute("Season")
		return if type(s) == "number" then s else 1
	end
	task.spawn(function()
		for _, name in { "Town", "Plots" } do
			local folder = workspace:WaitForChild(name, 60)
			if folder then
				watch(folder)
			end
		end
		-- (the town's merged pieces go up over the first moments; dressed as they arrive)
		season = now()
		dressAll(season)
	end)
	workspace:GetAttributeChangedSignal("Season"):Connect(function()
		local s = now()
		if s == season then
			return
		end
		local first = season == 0
		season = s
		task.spawn(dressAll, s)
		if not first then
			local ok, Toasts = pcall(require, script.Parent.Parent.UI.Toasts)
			if ok then
				(Toasts :: any).show(Seasons.at(s).notice, "info")
			end
		end
	end)
end

return Seasonal
