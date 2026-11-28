-- The lights players place (Sim/Lights). The user: "also, make it such that lights are on by
-- default and dont change based on time. players can turn them off or on, and villagers will turn
-- nearby ones off when sleeping".
--
-- Every placed piece that glows is drawn with its glowing parts tagged PlacedLight (Builder.render),
-- which the clock never switches (Services/World only switches the town's NightLight parts). This
-- lights them as they are drawn, on unless the owner switched them off (the item's `off`, saved
-- with the plan). Each carries a "Turn off" / "Turn on" prompt on the part that gives the light;
-- holding E there on your own plot flips it (checked here: whose plot, where you stand, how often),
-- saves the switch on the plan and tells the owner's client (PlanSync, a "set" with no redraw and
-- no undo step). Once a second it asks Villagers who is asleep in bed and puts out the lights near
-- those beds (Sim/Lights.dark); they come back on as soon as the sleeper is up, whatever got them
-- up. That is held here only, never saved, and never changes `off`.
-- The prompts open no panel, so they carry no `Opens` attribute.

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Tuning = require(Shared.Config.Tuning)
local Catalog = require(Shared.Build.Catalog)
local Builder = require(Shared.Build.Builder)
local Plan = require(Shared.Build.Plan)
local Remotes = require(Shared.Net.Remotes)
local LightsSim = require(Shared.Sim.Lights)

local Data = require(script.Parent.Data)
local Plots = require(script.Parent.Plots)
local Villagers = require(script.Parent.Villagers)
local World = require(script.Parent.World)

local K = Tuning.Lights

local Lights = {}

local PROMPT = "LightPrompt"

-- What each plot's lights are doing besides their switch: put out by sleepers (`dark`) and turned
-- back on by the player while they sleep (`kept`). Started again when the plot changes hands.
type PlotLights = { owner: Player?, dark: LightsSim.Set, kept: LightsSim.Set }
local plots: { [number]: PlotLights } = {}
local lastPress: { [Player]: number } = {}

local function plotOf(i: number): PlotLights
	local owner = Plots.owner(i)
	local s = plots[i]
	if not s or s.owner ~= owner then
		s = { owner = owner, dark = {}, kept = {} }
		plots[i] = s
	end
	return s
end

-- A piece on plot `i` by its key: the item and its owner's profile.
local function itemOf(i: number, key: string): (any?, any?)
	local owner = Plots.owner(i)
	local profile = owner and Data.get(owner)
	local item = profile and profile.plan and profile.plan.items[key]
	return item, profile
end

local function modelOf(i: number, key: string): Instance?
	local ok, folder = pcall(Plots.buildFolder, i)
	return if ok and folder then folder:FindFirstChild(Builder.modelName("items", key)) else nil
end

-- The parts of a placed piece that glow.
local function glowsOf(model: Instance): { BasePart }
	local out: { BasePart } = {}
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") and d:HasTag(Builder.Tags.PlacedLight) then
			table.insert(out, d)
		end
	end
	return out
end

-- Is this light on now: its switch, then the sleepers.
function Lights.isOn(i: number, key: string): boolean
	local item = itemOf(i, key)
	local s = plotOf(i)
	return LightsSim.isOn(item, key, s.dark, s.kept)
end

-- Shows a piece's lights as they are now, and words its prompt to match.
function Lights.show(i: number, key: string)
	local model = modelOf(i, key)
	if not model then
		return
	end
	local on = Lights.isOn(i, key)
	for _, part in glowsOf(model) do
		World.setLight(part, on)
	end
	-- (what follows the switch besides its light, on each player's screen: a fog machine's fog,
	-- client World/Lively)
	model:SetAttribute("LightsOff", if on then nil else true)
	local prompt = model:FindFirstChild(PROMPT, true)
	if prompt and prompt:IsA("ProximityPrompt") then
		prompt.ActionText = LightsSim.action(on)
	end
end

-- Someone held E at a light's prompt on plot `i`: only its owner, close by, and not too often.
function Lights.pressed(player: Player, i: number, key: string)
	if Plots.owner(i) ~= player then
		return
	end
	local now = os.clock()
	if now - (lastPress[player] or -math.huge) < K.Cooldown then
		return
	end
	local item, profile = itemOf(i, key)
	if not item or not profile or not LightsSim.isLight(Catalog.get(item.id)) then
		return
	end
	local frame = Plan.itemFrame(profile.plan, item)
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not frame or not root or not root:IsA("BasePart") then
		return
	end
	if (root.Position - (Plots.frame(i) * frame).Position).Magnitude > K.Reach then
		return
	end
	lastPress[player] = now
	local s = plotOf(i)
	local before = Plan.copy(item)
	item.off = LightsSim.press(item, key, s.dark, s.kept)
	Lights.show(i, key)
	-- the owner's copy of their plan learns the switch (nothing is drawn again, nothing to undo)
	Remotes.event("PlanSync"):FireClient(player, {
		ops = { { op = "set", kind = "items", key = key, obj = Plan.copy(item), before = before } },
	})
end

-- Where a prompt's signal is listened to (a seam for a spec, whose prompts have no signals).
function Lights.listen(prompt: ProximityPrompt, fn: (Player) -> ())
	prompt.Triggered:Connect(fn)
end

-- Puts the prompt on a light just drawn on plot `i`: on the part that gives its light, or the
-- first that glows. Returns it.
function Lights.addPrompt(i: number, model: Instance): ProximityPrompt?
	if not model:IsA("Model") or model:GetAttribute("BuildKind") ~= "items" then
		return nil
	end
	local id = model:GetAttribute("ItemId")
	local key = model:GetAttribute("BuildKey")
	local def = if type(id) == "string" then Catalog.get(id) else nil
	if not def or not LightsSim.isLight(def) or type(key) ~= "string" or model:FindFirstChild(PROMPT, true) then
		return nil
	end
	local glows = glowsOf(model)
	local at = glows[1]
	for _, part in glows do
		if part:FindFirstChildWhichIsA("Light") then
			at = part
			break
		end
	end
	if not at then
		return nil
	end
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = PROMPT
	prompt.ActionText = LightsSim.TurnOff
	prompt.ObjectText = def.name
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.HoldDuration = K.Hold
	prompt.MaxActivationDistance = K.Distance
	prompt.RequiresLineOfSight = false
	-- the client shows it on its own plot only, and not in Build mode
	prompt:SetAttribute("Plot", i)
	prompt:SetAttribute("BuildKey", key)
	prompt:AddTag(LightsSim.Tag)
	prompt.Parent = at
	Lights.listen(prompt, function(who: Player)
		Lights.pressed(who, i, key :: string)
	end)
	return prompt
end

-- A piece was just drawn on plot `i` (placed, moved, repainted or loaded): a light gets its prompt
-- and is lit as it should be.
function Lights.drawn(i: number, model: Instance)
	local key = model:GetAttribute("BuildKey")
	if model:GetAttribute("BuildKind") ~= "items" or type(key) ~= "string" then
		return
	end
	if Lights.addPrompt(i, model) then
		Lights.show(i, key)
	end
end

-- One look at who is asleep on each plot: the lights near their beds go out, and the ones whose
-- sleepers are up come back on.
function Lights.step()
	for i = 1, Tuning.Plot.Count do
		local s = plotOf(i)
		local owner = s.owner
		local profile = owner and Data.get(owner)
		local dark: LightsSim.Set = {}
		if owner and profile and profile.plan then
			local ok, sleepers = pcall(Villagers.sleepers, owner)
			if ok and type(sleepers) == "table" and next(sleepers) ~= nil then
				dark = LightsSim.dark(profile.plan, sleepers)
			end
		end
		LightsSim.settle(s.kept, dark)
		local was = s.dark
		s.dark = dark
		for key in was do
			if not dark[key] then
				Lights.show(i, key)
			end
		end
		for key in dark do
			if not was[key] then
				Lights.show(i, key)
			end
		end
	end
end

function Lights.start()
	for i = 1, Tuning.Plot.Count do
		local ok, folder = pcall(Plots.buildFolder, i)
		if ok and folder then
			-- every piece is drawn afresh into the folder when placed, moved or repainted
			folder.ChildAdded:Connect(function(model)
				Lights.drawn(i, model)
			end)
			for _, model in folder:GetChildren() do
				Lights.drawn(i, model)
			end
		end
	end
	Players.PlayerRemoving:Connect(function(player)
		lastPress[player] = nil
	end)
	task.spawn(function()
		while true do
			task.wait(K.SleepCheck)
			local ok, why = pcall(Lights.step)
			if not ok then
				warn("[Lights] " .. tostring(why))
			end
		end
	end)
end

return Lights
