-- Holding E on a piece. The user: "just like tomodachi life, make it such that some obejcts have a
-- random chance of having unique interactions with it". Pieces with a player's use in
-- Data/Interactions (the piano, the fridge, the bell, the globe and the rest) carry a prompt
-- wherever they are placed, and a go does something small that now and then turns out another
-- way: a tune or a mess at the piano, a note from one of the villagers in the fridge. The server
-- decides it all (Sim/Uses picks the outcome; where the player stands and how often they ask are
-- checked here), every client near shows it (client World/Interact: a line over the piece and a
-- puff), and the villagers near react to the loud ones. Nothing is bought, paid or saved.
-- The prompts open no panel, so they carry no `Opens` attribute.

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Tuning = require(Shared.Config.Tuning)
local Catalog = require(Shared.Build.Catalog)
local Plan = require(Shared.Build.Plan)
local Town = require(Shared.Data.Town)
local Uses = require(Shared.Sim.Uses)
local Rng = require(Shared.Util.Rng)

local Data = require(script.Parent.Data)
local Plots = require(script.Parent.Plots)
local Villagers = require(script.Parent.Villagers)
local Use = require(script.Parent.Parent.Npc.Use)

local K = Tuning.Uses

local Interact = {}

local rng = Rng.new()
local lastGo: { [Player]: number } = {} -- when each player last had a go
local lastOutcome: { [Player]: any } = {} -- and how it turned out (an unusual one never twice running)
local rested: { [Instance]: number } = setmetatable({}, { __mode = "k" }) :: any -- each piece's last go

-- Where a placed piece stands in the world, from its owner's plan.
local function pieceFrame(i: number, model: Model): CFrame?
	local owner = Plots.owner(i)
	local profile = owner and Data.get(owner)
	local key = model:GetAttribute("BuildKey")
	local item = profile and type(key) == "string" and profile.plan.items[key]
	local frame = item and Plan.itemFrame(profile.plan, item)
	return if frame then Town.plotFrame(i) * frame else nil
end

-- A player had a go at a piece: checked, then turned out.
local function go(who: Player, i: number, model: Model, id: string, spot: Attachment)
	local use = Uses.of(id)
	if not use or not use.player or not model.Parent or model:GetAttribute("ItemId") ~= id then
		return
	end
	local now = os.clock()
	if now - (lastGo[who] or -math.huge) < K.Cooldown or now - (rested[model] or -math.huge) < K.Rest then
		return
	end
	local char = who.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local at = spot.WorldPosition
	if not root or not root:IsA("BasePart") or (root.Position - at).Magnitude > K.Reaches then
		return
	end
	lastGo[who] = now
	rested[model] = now
	-- the town's own villagers, for an outcome that names one of them
	local owner = Plots.owner(i)
	local profile = owner and Data.get(owner)
	local names = {}
	if profile then
		for _, vid in profile.order do
			local v = profile.villagers[vid]
			if v then
				table.insert(names, v.name)
			end
		end
	end
	local o = Uses.outcome(use.player.outcomes, nil, lastOutcome[who], rng, { needs = { villager = #names > 0 } })
	if not o then
		return
	end
	lastOutcome[who] = o
	local text = Uses.say(o, { who = if #names > 0 then rng:pick(names) else "" }, rng)
	Use.show(at, o.puff, text, o.rarity)
	if o.near and owner then
		Villagers.reactNear(owner, at, o.near, {})
	end
end

-- Puts the prompt on a piece just drawn on plot `i`, if a player can use it.
local function addPrompt(i: number, model: Instance)
	if not model:IsA("Model") or model:GetAttribute("BuildKind") ~= "items" then
		return
	end
	local id = model:GetAttribute("ItemId")
	local use = type(id) == "string" and Uses.of(id)
	local def = type(id) == "string" and Catalog.get(id)
	if not use or not use.player or not def or model:FindFirstChild("UseSpot", true) then
		return
	end
	local frame = pieceFrame(i, model)
	local part = model:FindFirstChildWhichIsA("BasePart", true)
	if not frame or not part then
		return
	end
	-- an attachment at the middle of its front, on any of its parts (they never move)
	local spot = Instance.new("Attachment")
	spot.Name = "UseSpot"
	spot.CFrame = part.CFrame:ToObjectSpace(CFrame.new(frame * Uses.promptAt(id :: string)))
	spot.Parent = part
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "UsePrompt"
	prompt.ActionText = use.player.verb
	prompt.ObjectText = def.name
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.HoldDuration = K.HoldSeconds
	prompt.MaxActivationDistance = K.Distance
	prompt.RequiresLineOfSight = false
	prompt.Parent = spot
	prompt.Triggered:Connect(function(who: Player)
		go(who, i, model :: Model, id :: string, spot)
	end)
end

function Interact.start()
	for i = 1, Tuning.Plot.Count do
		local ok, folder = pcall(Plots.buildFolder, i)
		if ok and folder then
			-- every piece is drawn afresh into the folder when placed, moved or repainted
			folder.ChildAdded:Connect(function(model)
				addPrompt(i, model)
			end)
			for _, model in folder:GetChildren() do
				addPrompt(i, model)
			end
		end
	end
	Players.PlayerRemoving:Connect(function(player)
		lastGo[player] = nil
		lastOutcome[player] = nil
	end)
end

return Interact
