-- Hands each player a plot, draws their saved build on it, and clears it when they leave.

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Tuning = require(Shared.Config.Tuning)
local Town = require(Shared.Data.Town)
local Builder = require(Shared.Build.Builder)
local StarterHouse = require(Shared.Data.StarterHouse)
local Remotes = require(Shared.Net.Remotes)

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
	Plots.buildFolder(i):ClearAllChildren()
	Plots.villagerFolder(i):ClearAllChildren()
	World.setPlotSign(i, "Plot " .. i .. "\nfor sale")
end

function Plots.start()
	Data.Loaded:Connect(assign)
	Players.PlayerRemoving:Connect(release)
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function(char)
			task.wait(0.2)
			Plots.sendTo(player, char)
		end)
	end)
	for _, player in Players:GetPlayers() do
		player.CharacterAdded:Connect(function(char)
			task.wait(0.2)
			Plots.sendTo(player, char)
		end)
	end

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
