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
local PlotGround = require(Shared.Sim.PlotGround)
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
-- The plot's ground (Sim/PlotGround): Roblox's long grass on the land the player owns, and the
-- leafy kind with no blades on land not bought and under everything built. Redone after every
-- change, a moment later so a run of changes paints once.
local function region(r: { number }): Region3
	return Region3.new(Vector3.new(r[1], -8, r[2]), Vector3.new(r[3], 4, r[4]))
end
function Plots.paintGround(i: number, plan: any)
	local terrain = workspace.Terrain
	local frame = Town.plotFrame(i)
	local size = Tuning.Plot.Size
	local ok, why = pcall(function()
		terrain:ReplaceMaterial(
			region(PlotGround.square(frame, size)),
			4,
			Enum.Material.Grass,
			Enum.Material.LeafyGrass
		)
		if plan then
			for _, r in PlotGround.grass(plan, frame, size) do
				terrain:ReplaceMaterial(region(r), 4, Enum.Material.LeafyGrass, Enum.Material.Grass)
			end
		end
	end)
	if not ok then
		warn("[Plots] couldn't paint plot " .. i .. "'s grass: " .. tostring(why))
	end
end
local painting: { [number]: boolean } = {}
function Plots.groundSoon(i: number)
	if painting[i] then
		return
	end
	painting[i] = true
	task.delay(0.4, function()
		painting[i] = nil
		local owner = owners[i]
		local profile = owner and Data.get(owner)
		Plots.paintGround(i, profile and profile.plan)
	end)
end

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
	-- (unseen: the terrain's long grass grows through it, Plots.paintGround)
	grass.Transparency = 1
	grass.CanCollide = false
	grass.CastShadow = false
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
	player:SetAttribute("Arrival", "Your plot is ready")
	if profile.plan == nil then
		profile.plan = StarterHouse.plan()
	end
	Plots.drawLand(index, profile.plan)
	local folder = Plots.buildFolder(index)
	folder:ClearAllChildren()
	Builder.renderAll(profile.plan, folder, Town.plotFrame(index))
	Plots.paintGround(index, profile.plan)
	World.setPlotSign(index, signFor(player))
	Remotes.event("PlanSync"):FireClient(player, { full = profile.plan })
	Data.push(player, "plot")
	ready:Fire(player, index)
	if player.Character then
		Plots.sendTo(player)
	else
		Plots.spawn(player)
	end
end

-- Characters don't load by themselves (Players.CharacterAutoLoads is off in the place): the user
-- found "it keeps spawning me below the world", because a player joined while the server was
-- still writing the island's terrain and fell through where the ground would be. So a character
-- is loaded once the world is up and the player's plot is ready, and again after a respawn wait.
local spawning: { [Player]: boolean } = {}
function Plots.spawn(player: Player)
	if spawning[player] or not player.Parent or player.Character then
		return
	end
	spawning[player] = true
	player:SetAttribute("Arrival", "Loading your character")
	local ok, why = pcall(function()
		local p = player :: any
		if p.LoadCharacterAsync then
			p:LoadCharacterAsync()
		else
			p:LoadCharacter()
		end
	end)
	spawning[player] = nil
	if not ok then
		warn("[Plots] couldn't load a character for " .. player.Name .. ": " .. tostring(why))
		local first = string.match(tostring(why), "^[^\n]*") or "?"
		player:SetAttribute("Arrival", "Couldn't load your character: " .. string.sub(first, 1, 120))
	end
end

-- Under this, a character has fallen through the world (the sea floor is at -16): put them back.
Plots.FallLimit = -40

local function release(player: Player)
	local i = Plots.indexOf(player)
	if not i then
		return
	end
	owners[i] = nil
	Plots.drawLand(i, nil)
	Plots.paintGround(i, nil)
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
		if not player:GetAttribute("Arrival") then
			player:SetAttribute("Arrival", if Data.get(player) then "Your save is in" else "Loading your save")
		end
		player.CharacterAdded:Connect(function(char)
			player:SetAttribute("Arrival", "Here")
			char:WaitForChild("HumanoidRootPart", 5)
			task.wait(0.1)
			Plots.sendTo(player, char)
			local humanoid = char:FindFirstChildOfClass("Humanoid")
			if humanoid then
				humanoid.Died:Connect(function()
					task.wait(Players.RespawnTime)
					if player.Parent and player.Character == char then
						char:Destroy()
						player.Character = nil
						Plots.spawn(player)
					end
				end)
			end
		end)
		-- the world is up by now (World builds it before anything starts); a player whose
		-- profile never loads still gets a body after a while, in the square
		task.delay(20, function()
			if player.Parent and not player.Character then
				Plots.spawn(player)
			end
		end)
	end
	Players.PlayerAdded:Connect(watch)
	Players.PlayerRemoving:Connect(function(player)
		spawning[player] = nil
	end)
	-- anyone who drops through the world is put back on their plot, or in the square
	task.spawn(function()
		while true do
			task.wait(1)
			for _, player in Players:GetPlayers() do
				local char = player.Character
				local root = char and char:FindFirstChild("HumanoidRootPart")
				if root and root:IsA("BasePart") and root.Position.Y < Plots.FallLimit then
					root.AssemblyLinearVelocity = Vector3.zero
					if Plots.indexOf(player) then
						Plots.sendTo(player, char)
					else
						(char :: Model):PivotTo(CFrame.new(Town.Spots.Spawn + Vector3.new(0, 3, 0)))
					end
				end
			end
		end
	end)
	for _, player in Players:GetPlayers() do
		watch(player)
		-- anyone whose profile is already in (they joined while the server was starting)
		local profile = Data.get(player)
		if profile and not Plots.indexOf(player) then
			task.spawn(assign, player, profile)
		end
	end

	-- the loading card asks when no body has come: load one if there's none (on their plot once
	-- they have one, in the square if not) and say where things stand
	Remotes.fn("SpawnMe").OnServerInvoke = function(player)
		if not player.Character then
			task.spawn(Plots.spawn, player)
		end
		return player:GetAttribute("Arrival")
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
		Plots.paintGround(i, profile.plan)
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
