-- The player's bag on the server (Sim/Bag). The user: "make it such that you can pick up items, and
-- interactable items give you things, such as a bookshelf giving you a book, you can work on stoves
-- to make food, flower beds giving you flowers, etc. ... add an inventory system to the player."
--
--   pieces   every placed piece whose drawing `gives` (Data/Items.Sources) carries a prompt worded
--            by its source ("Take a book", "Cook"). On its own plot only, a player who holds E there
--            (F where the piece already has an E prompt: a use, a light) takes one thing into the
--            bag: checked here (whose plot, where they stand, how often, the day's cap), a piece
--            rests a while between goes (Tuning.Bag.Rest), and a stove or a grill is a longer hold
--   work     a player working at a workplace whose source is a workplace's (the bakery, the cafe,
--            the florist...) makes a thing every Tuning.Bag.WorkEvery seconds there (Work.at)
--   traces   a book or a letter a villager left on the floor (Npc/Use's traces) can be picked up
--   hold     BagUse "hold" puts a little model of a thing in the player's right hand for everyone to
--            see (only while it is in the bag); "away" takes it out of the hand
--   drop     BagUse "drop" takes one out of the bag and lays it on the ground in front of them, with
--            a "Pick up" prompt for them alone, until Tuning.Bag.DropSeconds have passed
-- The prompts open no panel, so they carry no `Opens` attribute. The client (World/Gather) shows a
-- piece's prompt on the player's own plot only, and not in Build mode.

local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Tuning = require(Shared.Config.Tuning)
local Catalog = require(Shared.Build.Catalog)
local Plan = require(Shared.Build.Plan)
local Recipe = require(Shared.Build.Recipe)
local Builder = require(Shared.Build.Builder)
local Town = require(Shared.Data.Town)
local Items = require(Shared.Data.Items)
local Bag = require(Shared.Sim.Bag)
local Uses = require(Shared.Sim.Uses)
local LightsSim = require(Shared.Sim.Lights)
local Rng = require(Shared.Util.Rng)
local Text = require(Shared.Util.Text)
local Remotes = require(Shared.Net.Remotes)

local Data = require(script.Parent.Data)
local Plots = require(script.Parent.Plots)
local World = require(script.Parent.World)
local Work = require(script.Parent.Work)

local K = Tuning.Bag

local BagService = {}

-- the tag on every piece's prompt, which the client's World/Gather shows on its owner's plot only
BagService.Tag = "GatherPrompt"
local PROMPT = "GatherPrompt"

-- what a trace on the floor (Data/Interactions.traces) is, as a thing for the bag
local TRACES: { [string]: string } = { book = "storybook", letter = "letter" }

local rng = Rng.new()
local lastGo: { [Player]: number } = {}
local rested: { [Instance]: number } = setmetatable({}, { __mode = "k" }) :: any
local worked: { [Player]: { key: string, seconds: number } } = {}
local drops: { [Player]: { Model } } = {}

local function push(player: Player)
	Data.push(player, "bag", "owed", "gather", "stats")
end

-- Where a placed piece stands in the world, from its owner's plan.
local function pieceFrame(i: number, key: string): CFrame?
	local owner = Plots.owner(i)
	local profile = owner and Data.get(owner)
	local item = profile and profile.plan and profile.plan.items[key]
	local frame = item and Plan.itemFrame(profile.plan, item)
	return if frame then Town.plotFrame(i) * frame else nil
end

local function rootOf(player: Player): BasePart?
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root else nil
end

-- What the thing in a notice reads as: "You took a storybook."
local function took(source: Items.Source, item: Items.Item): string
	if source.cook then
		return Text.fill("You cooked {x}.", { x = item.phrase })
	elseif source.work then
		return Text.fill("You made {x} at work.", { x = item.phrase })
	end
	return Text.fill("You took {x}.", { x = item.phrase })
end

-- Pieces --------------------------------------------------------------------------------------------

-- Somebody held the prompt on a piece on plot `i`: everything checked, then one thing in the bag.
function BagService.pressed(player: Player, i: number, key: string, model: Model)
	if Plots.owner(i) ~= player then
		return
	end
	local profile = Data.get(player)
	local item = profile and profile.plan and profile.plan.items[key]
	local def = item and Catalog.get(item.id)
	local source = def and Items.source(def.gives)
	if not profile or not def or not source or source.work or not model.Parent then
		return
	end
	local now = os.clock()
	if now - (lastGo[player] or -math.huge) < K.Cooldown then
		return
	end
	local frame = pieceFrame(i, key)
	local root = rootOf(player)
	if not frame or not root or (root.Position - frame.Position).Magnitude > K.Reaches + def.size.Magnitude / 2 then
		return
	end
	lastGo[player] = now
	if now - (rested[model] or -math.huge) < K.Rest then
		Data.notify(player, "There's nothing more here for now. Come back in a bit.", "info")
		return
	end
	local ok, got = Bag.gather(profile, World.dayIndex(), def.gives, rng)
	if not ok then
		if got then
			Data.notify(player, got, "warn")
		end
		return
	end
	rested[model] = now
	local thing = Items.get(got)
	if thing then
		Data.notify(player, took(source, thing), "good")
	end
	push(player)
end

-- Puts the prompt on a piece just drawn on plot `i`, if it gives something and isn't a workplace.
local function addPrompt(i: number, model: Instance)
	if not model:IsA("Model") or model:GetAttribute("BuildKind") ~= "items" then
		return
	end
	local id = model:GetAttribute("ItemId")
	local key = model:GetAttribute("BuildKey")
	local def = if type(id) == "string" then Catalog.get(id) else nil
	local source = def and Items.source(def.gives)
	if not def or not source or source.work or type(key) ~= "string" or model:FindFirstChild(PROMPT, true) then
		return
	end
	local part = model:FindFirstChildWhichIsA("BasePart", true)
	local frame = pieceFrame(i, key)
	if not part or not frame then
		return
	end
	-- a spot a little over the middle of its front, on any of its parts (they never move)
	local size = def.size
	local at = Vector3.new(0, math.min(size.Y * 0.5, 3), size.Z / 2)
	local spot = Instance.new("Attachment")
	spot.Name = "GatherSpot"
	spot.CFrame = part.CFrame:ToObjectSpace(CFrame.new(frame * at))
	spot.Parent = part
	-- a piece with an E prompt of its own already (a use, a light switch) takes F for this one
	local use = Uses.of(def.id)
	local busy = (use ~= nil and use.player ~= nil) or LightsSim.isLight(def)
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = PROMPT
	prompt.ActionText = source.verb
	prompt.ObjectText = def.name
	prompt.KeyboardKeyCode = if busy then Enum.KeyCode.F else Enum.KeyCode.E
	prompt.GamepadKeyCode = if busy then Enum.KeyCode.ButtonY else Enum.KeyCode.ButtonX
	prompt.HoldDuration = if source.cook then K.CookSeconds else K.HoldSeconds
	prompt.MaxActivationDistance = K.Distance
	prompt.RequiresLineOfSight = false
	if busy then
		prompt.UIOffset = Vector2.new(0, 72)
	end
	prompt:SetAttribute("Plot", i)
	prompt:AddTag(BagService.Tag)
	prompt.Parent = spot
	prompt.Triggered:Connect(function(who: Player)
		BagService.pressed(who, i, key :: string, model :: Model)
	end)
end

-- Work ----------------------------------------------------------------------------------------------

-- One look at who is working at a workplace that makes things: their time there adds up, and every
-- Tuning.Bag.WorkEvery seconds of it makes one thing.
local function lookAtWork(seconds: number)
	for _, player in Players:GetPlayers() do
		local plot, key = Work.at(player)
		local profile = Data.get(player)
		local item = plot and key and profile and profile.plan and profile.plan.items[key]
		local def = item and Catalog.get(item.id)
		local source = def and Items.source(def.gives)
		if not source or not source.work or not key or not profile then
			worked[player] = nil
			continue
		end
		local w = worked[player]
		if not w or w.key ~= key then
			w = { key = key, seconds = 0 }
			worked[player] = w
		end
		w.seconds += seconds
		if w.seconds >= K.WorkEvery then
			w.seconds -= K.WorkEvery
			local ok, got = Bag.gather(profile, World.dayIndex(), def.gives, rng)
			local thing = ok and Items.get(got)
			if thing then
				Data.notify(player, took(source, thing), "good")
				push(player)
			end
		end
	end
end

-- Things in the world --------------------------------------------------------------------------------

-- A small model of a thing, its grip at the origin: what is held in a hand and what lies dropped.
local function drawThing(item: Items.Item): { any }
	local color = Color3.fromHex(item.color)
	local r = Recipe.new(color, color)
	local cat = item.cat
	if cat == "book" then
		r:box(0, 0, 0, 0.9, 1.15, 0.3, color, "Fabric")
		r:box(0.03, 0, 0, 0.84, 1.05, 0.31, Recipe.Colors.Paper, "SmoothPlastic")
	elseif cat == "flower" then
		r:cyl(0, -0.2, 0, 1.2, 0.1, "y", Recipe.Colors.Leaf, "Grass")
		r:ball(0, 0.5, 0, 0.55, color, "SmoothPlastic")
	elseif cat == "drink" then
		r:cyl(0, 0, 0, 0.65, 0.5, "y", color, "SmoothPlastic")
		r:cyl(0, 0.34, 0, 0.04, 0.42, "y", Recipe.Colors.Cream, "SmoothPlastic")
	elseif cat == "craft" or cat == "trinket" then
		r:box(0, 0, 0, 0.55, 0.55, 0.35, color, "SmoothPlastic")
	elseif cat == "treasure" then
		r:box(0, 0, 0, 0.65, 0.5, 0.5, color, "Metal")
		r:ball(0, 0.38, 0, 0.3, Recipe.Colors.Gold, "Metal")
	else
		-- something to eat, on a little plate
		r:cyl(0, -0.25, 0, 0.06, 0.8, "y", Recipe.Colors.White, "SmoothPlastic")
		r:lump(CFrame.new(0, 0, 0), 0.6, 0.45, 0.55, color, "SmoothPlastic")
	end
	return r.prims
end

local function loose(model: Model)
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			d.CanCollide = false
			d.CanQuery = false
			d.CanTouch = false
			d.Massless = true
		end
	end
end

-- Takes whatever is in the player's hand out of it.
local function letGo(player: Player)
	local char = player.Character
	local held = char and char:FindFirstChild("Held")
	if held then
		held:Destroy()
	end
	player:SetAttribute("Holding", nil)
end

-- Puts a thing in the player's right hand.
local function hold(player: Player, item: Items.Item): boolean
	local char = player.Character
	local hand = char and (char:FindFirstChild("RightHand") or char:FindFirstChild("Right Arm"))
	if not char or not hand or not hand:IsA("BasePart") then
		return false
	end
	letGo(player)
	local model = Instance.new("Model")
	model.Name = "Held"
	local grip = hand.CFrame * CFrame.new(0, -hand.Size.Y / 2 - 0.25, -0.2)
	local parts = Builder.instantiate(drawThing(item), model, grip, { plain = true })
	loose(model)
	for _, part in parts do
		part.Anchored = false
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = hand
		weld.Part1 = part
		weld.Parent = part
	end
	model.Parent = char
	player:SetAttribute("Holding", item.id)
	return true
end

-- A thing lying on the ground: its "Pick up" prompt is for `who` alone, and it goes after a while.
local function lay(who: Player, item: Items.Item, at: CFrame, onPick: () -> boolean)
	local model = Instance.new("Model")
	model.Name = "Dropped"
	model:SetAttribute("Thing", item.id)
	local parts = Builder.instantiate(drawThing(item), model, at, { plain = true })
	loose(model)
	for _, part in parts do
		part.Anchored = true
	end
	local first = parts[1]
	if not first then
		return
	end
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "PickUp"
	prompt.ActionText = "Pick up"
	prompt.ObjectText = item.name
	prompt.HoldDuration = K.HoldSeconds
	prompt.MaxActivationDistance = K.Distance
	prompt.RequiresLineOfSight = false
	prompt.Parent = first
	prompt.Triggered:Connect(function(player: Player)
		local root = rootOf(player)
		if player ~= who or not model.Parent or not root or (root.Position - at.Position).Magnitude > K.Reaches then
			return
		end
		if onPick() then
			model:Destroy()
		end
	end)
	model.Parent = workspace
	Debris:AddItem(model, K.DropSeconds)
	local list = drops[who] or {}
	drops[who] = list
	for k = #list, 1, -1 do
		if not list[k].Parent then
			table.remove(list, k)
		end
	end
	table.insert(list, model)
	while #list > K.Drops do
		local oldest = table.remove(list, 1)
		if oldest then
			oldest:Destroy()
		end
	end
end

-- Takes one of a thing out of the bag and lays it on the ground in front of the player.
local function drop(player: Player, profile: any, item: Items.Item): (boolean, string?)
	local root = rootOf(player)
	if not root then
		return false, "Not right now."
	end
	if not Bag.take(profile, item.id, 1) then
		return false, "That isn't in your bag."
	end
	if player:GetAttribute("Holding") == item.id and Bag.count(profile, item.id) == 0 then
		letGo(player)
	end
	local front = root.CFrame * CFrame.new(0, 0, -2.5)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { player.Character :: any }
	local hit = workspace:Raycast(front.Position + Vector3.new(0, 2, 0), Vector3.new(0, -8, 0), params)
	local y = if hit then hit.Position.Y + 0.3 else front.Position.Y - 2.5
	lay(player, item, CFrame.new(front.X, y, front.Z) * root.CFrame.Rotation, function(): boolean
		local mine = Data.get(player)
		if not mine or Bag.add(mine, item.id, 1) <= 0 then
			Data.notify(player, "Your bag is full.", "warn")
			return false
		end
		push(player)
		return true
	end)
	push(player)
	return true, nil
end

-- A book or a letter a villager left on the floor of plot `i`: its owner can pick it up.
local function traceAdded(i: number, model: Instance)
	if not model:IsA("Model") then
		return
	end
	local kind = model:GetAttribute("Trace")
	local id = if type(kind) == "string" then TRACES[kind] else nil
	local item = Items.get(id)
	local part = model:FindFirstChildWhichIsA("BasePart", true)
	if not item or not part then
		return
	end
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "PickUp"
	prompt.ActionText = "Pick up"
	prompt.ObjectText = item.name
	prompt.HoldDuration = K.HoldSeconds
	prompt.MaxActivationDistance = K.Distance
	prompt.RequiresLineOfSight = false
	prompt.Parent = part
	prompt.Triggered:Connect(function(player: Player)
		local root = rootOf(player)
		local profile = Data.get(player)
		if Plots.owner(i) ~= player or not profile or not model.Parent or not root then
			return
		end
		if (root.Position - part.Position).Magnitude > K.Reaches then
			return
		end
		if Bag.add(profile, item.id, 1) <= 0 then
			Data.notify(player, "Your bag is full.", "warn")
			return
		end
		model:Destroy()
		Data.notify(player, Text.fill("You picked up {x}.", { x = item.phrase }), "good")
		push(player)
	end)
end

-- The BagUse remote --------------------------------------------------------------------------------

function BagService.use(player: Player, action: any, id: any): (boolean, string?)
	local profile = Data.get(player)
	if not profile then
		return false, "Not ready yet."
	end
	if action == "away" then
		letGo(player)
		return true, nil
	end
	local item = Items.get(id)
	if not item or Bag.count(profile, id) < 1 then
		return false, "That isn't in your bag."
	end
	if action == "hold" then
		if not hold(player, item) then
			return false, "Not right now."
		end
		return true, nil
	elseif action == "drop" then
		return drop(player, profile, item)
	end
	return false, nil
end

-- Things a goal gave while the bag was full go in as room comes: on joining and after a drop or a gift.
function BagService.settle(player: Player)
	local profile = Data.get(player)
	if not profile then
		return
	end
	local got = Bag.settle(profile)
	for _, id in got do
		local item = Items.get(id)
		if item then
			Data.notify(player, Text.fill("{x} is in your bag now.", { x = Items.capital(item) }), "good")
		end
	end
	if #got > 0 then
		push(player)
	end
end

function BagService.start()
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
			-- the traces villagers leave lie in the plot's own model (Npc/Use.trace)
			local plot = folder.Parent
			if plot then
				plot.DescendantAdded:Connect(function(d)
					if d:IsA("Model") and d:GetAttribute("Trace") then
						traceAdded(i, d)
					end
				end)
			end
		end
	end
	Remotes.fn("BagUse").OnServerInvoke = function(player, action, id)
		local ok, why = BagService.use(player, action, id)
		if ok and action == "drop" then
			BagService.settle(player)
		end
		return ok, why
	end
	Data.Loaded:Connect(function(player)
		task.delay(8, BagService.settle, player)
	end)
	-- whatever was held is gone with the body it was in
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function()
			player:SetAttribute("Holding", nil)
		end)
	end)
	Players.PlayerRemoving:Connect(function(player)
		lastGo[player] = nil
		worked[player] = nil
		local mine: { Model } = drops[player] or {}
		for _, m in mine do
			m:Destroy()
		end
		drops[player] = nil
	end)
	task.spawn(function()
		local last = os.clock()
		while true do
			task.wait(K.WorkCheck)
			local now = os.clock()
			local seconds = math.clamp(now - last, 0, K.WorkCheck * 3)
			last = now
			local ok, why = pcall(lookAtWork, seconds)
			if not ok then
				warn("[Bag] " .. tostring(why))
			end
		end
	end)
end

return BagService
