-- Hands each player a plot, draws their saved build on it, and clears it when they leave.

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Tuning = require(Shared.Config.Tuning)
local Town = require(Shared.Data.Town)
local Builder = require(Shared.Build.Builder)
local Textures = require(Shared.Data.Textures)
local StarterHouse = require(Shared.Data.StarterHouse)
local Remotes = require(Shared.Net.Remotes)
local Plan = require(Shared.Build.Plan)
local City = require(Shared.Sim.City)
local Text = require(Shared.Util.Text)

local Data = require(script.Parent.Data)
local World = require(script.Parent.World)

local Plots = {}

local owners: { [number]: Player } = {}
local ready = Instance.new("BindableEvent")
Plots.Ready = ready.Event -- (player, plotIndex) after the build is drawn

function Plots.indexOf(player: Player): number?
	for i, p in owners do
		if p == player then
			return i
		end
	end
	return nil
end

function Plots.owner(i: number): Player?
	return owners[i]
end

function Plots.frame(i: number): CFrame
	return Town.plotFrame(i)
end

function Plots.buildFolder(i: number): Folder
	return World.plotModel(i):FindFirstChild("Build") :: Folder
end

function Plots.villagerFolder(i: number): Folder
	return World.plotModel(i):FindFirstChild("Villagers") :: Folder
end

function Plots.ofPlayer(player: Player): (number?, CFrame?)
	local i = Plots.indexOf(player)
	if not i then
		return nil, nil
	end
	return i, Town.plotFrame(i)
end

-- Shows the land a player owns: lighter grass with a low curb round it.
function Plots.drawLand(i: number, plan: any)
	local plot = World.plotModel(i)
	local old = plot:FindFirstChild("Land")
	if old then
		old:Destroy()
	end
	if not plan then
		return
	end
	local frame = Town.plotFrame(i)
	local x1, z1, x2, z2 = Plan.bounds(plan)
	local land = Instance.new("Model")
	land.Name = "Land"
	local grass = Instance.new("Part")
	grass.Name = "Grass"
	grass.Anchored = true
	grass.Size = Vector3.new(x2 - x1, 0.1, z2 - z1)
	grass.CFrame = frame * CFrame.new((x1 + x2) / 2, -0.04, (z1 + z2) / 2)
	grass.Color = Textures.tint("Grass", Color3.fromRGB(148, 200, 120))
	grass.Material = Enum.Material.Grass
	grass.TopSurface = Enum.SurfaceType.Smooth
	grass.Parent = land
	local curb = Color3.fromRGB(232, 228, 216)
	local edges = {
		{ (x1 + x2) / 2, z1, x2 - x1 + 0.6, 0.6 },
		{ (x1 + x2) / 2, z2, x2 - x1 + 0.6, 0.6 },
		{ x1, (z1 + z2) / 2, 0.6, z2 - z1 },
		{ x2, (z1 + z2) / 2, 0.6, z2 - z1 },
	}
	for _, e in edges do
		local strip = Instance.new("Part")
		strip.Name = "Curb"
		strip.Anchored = true
		strip.Size = Vector3.new(e[3], 0.3, e[4])
		strip.CFrame = frame * CFrame.new(e[1], 0.1, e[2])
		strip.Color = curb
		strip.Material = Enum.Material.Concrete
		strip.Parent = land
	end
	land.Parent = plot
end

local function signFor(player: Player): string
	return player.DisplayName .. "'s\nplace"
end

function Plots.sendTo(player: Player, character: Model?)
	local i = Plots.indexOf(player)
	local char = character or player.Character
	if not i or not char then
		return
	end
	local root = char:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		char:PivotTo(Town.plotArrival(i))
	end
end

local function assign(player: Player, profile: any)
	local index
	for i = 1, Tuning.Plot.Count do
		if not owners[i] then
			index = i
			break
		end
	end
	if not index then
		Data.notify(player, "All the plots are taken in this server.", "warn")
		return
	end
	owners[index] = player
	player:SetAttribute("Plot", index)
	if profile.plan == nil then
		profile.plan = StarterHouse.plan()
	end
	Plots.drawLand(index, profile.plan)
	local folder = Plots.buildFolder(index)
	folder:ClearAllChildren()
	Builder.renderAll(profile.plan, folder, Town.plotFrame(index))
	World.setPlotSign(index, signFor(player))
	Remotes.event("PlanSync"):FireClient(player, { full = profile.plan })
	Data.push(player, "plot")
	ready:Fire(player, index)
	if player.Character then
		Plots.sendTo(player)
	end
end

local function release(player: Player)
	local i = Plots.indexOf(player)
	if not i then
		return
	end
	owners[i] = nil
	Plots.drawLand(i, nil)
	Plots.buildFolder(i):ClearAllChildren()
	Plots.villagerFolder(i):ClearAllChildren()
	World.setPlotSign(i, "Plot " .. i .. "\nfor sale")
end

function Plots.start()
	Data.Loaded:Connect(function(player, profile)
		if not Plots.indexOf(player) then
			assign(player, profile)
		end
	end)
	Players.PlayerRemoving:Connect(release)
	-- you always arrive at your own plot: when you first get it, and every time you respawn
	local function watch(player: Player)
		player.CharacterAdded:Connect(function(char)
			char:WaitForChild("HumanoidRootPart", 5)
			task.wait(0.1)
			Plots.sendTo(player, char)
		end)
	end
	Players.PlayerAdded:Connect(watch)
	for _, player in Players:GetPlayers() do
		watch(player)
		-- anyone whose profile is already in (they joined while the server was starting)
		local profile = Data.get(player)
		if profile and not Plots.indexOf(player) then
			task.spawn(assign, player, profile)
		end
	end

	Remotes.fn("PlotExpand").OnServerInvoke = function(player)
		local profile = Data.get(player)
		local i = Plots.indexOf(player)
		if not profile or not i then
			return false, "No plot yet."
		end
		local land, why = City.canExpand(profile)
		if not land then
			return false, why
		end
		Data.addCoins(player, -land.Price)
		profile.plan.size = land.Size
		Plots.drawLand(i, profile.plan)
		Remotes.event("PlanSync"):FireClient(player, { full = profile.plan })
		Data.log(player, Text.fill("You bought more land. It's now {n} by {n}.", { n = land.Size }))
		Data.notify(
			player,
			Text.fill("More land! You now have {n} by {n} studs to build on.", { n = land.Size }),
			"good"
		)
		return true
	end

	-- The Home button (the user: "make it such that there is a teleport home button"): to the
	-- spot in front of your own house where you arrive when you join. Out of a seat first, so the
	-- seat doesn't come along; not more than once every few seconds.
	local lastHome: { [Player]: number } = {}
	Remotes.fn("GoHome").OnServerInvoke = function(player)
		local index = Plots.indexOf(player)
		local char = player.Character
		local humanoid = char and char:FindFirstChildOfClass("Humanoid")
		if not index or not char or not humanoid or humanoid.Health <= 0 then
			return false, "Can't go home right now."
		end
		local now = os.clock()
		if lastHome[player] and now - lastHome[player] < Tuning.Plot.HomeCooldown then
			return false, "Hang on a moment."
		end
		lastHome[player] = now
		local seat = humanoid.SeatPart
		if seat then
			local weld = seat:FindFirstChild("SeatWeld")
			if weld then
				weld:Destroy()
			end
			humanoid.Sit = false
		end
		char:PivotTo(Town.plotArrival(index))
		return true, nil
	end
	Players.PlayerRemoving:Connect(function(player)
		lastHome[player] = nil
	end)

	Remotes.fn("VisitPlot").OnServerInvoke = function(player, index)
		if type(index) ~= "number" or not owners[index] then
			return false
		end
		local char = player.Character
		if not char then
			return false
		end
		char:PivotTo(Town.plotArrival(index))
		return true
	end
end

return Plots
