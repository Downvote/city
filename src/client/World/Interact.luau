-- What a go at a piece looks like on this screen. The server sends `Used` (Npc/Use.show) when a
-- villager's go gives something off (smoke from a burnt pan, petals from a plant coming into
-- flower) and when a player holds E on a piece (Services/Interact): a puff from the piece and, for
-- a player's go, a bubble saying what happened over that player's own head (the user: "for text
-- bubbles that appear when you interact with objects like the fridge, make the bubbles appear on
-- top of you instead"), a villager's speech card (Util/Bubble) with no rim. A rare outcome has its
-- words in gold and a few sparkles. Only what is near the camera shows.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Tuning = require(Shared.Config.Tuning)
local Remotes = require(Shared.Net.Remotes)
local Bubble = require(Shared.Util.Bubble)

local BuildFx = require(script.Parent.BuildFx)

local Interact = {}

local FAR = 120 -- studs from the camera past which nothing is drawn

-- An invisible anchored point to hang a puff or a bubble from, gone after `seconds`.
local function anchor(at: Vector3, seconds: number): Part
	local p = Instance.new("Part")
	p.Name = "UsePoint"
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Transparency = 1
	p.Size = Vector3.new(1, 1, 1)
	p.CFrame = CFrame.new(at)
	p.Parent = workspace
	Debris:AddItem(p, seconds)
	return p
end

-- A burst of particles: a texture, its colours, how many, and how they move.
local function burst(at: Vector3, texture: string, colors: ColorSequence, n: number, props: { [string]: any })
	local p = anchor(at, 3)
	local e = Instance.new("ParticleEmitter")
	e.Texture = texture
	e.Color = colors
	e.Enabled = false
	for k, v in props do
		(e :: any)[k] = v
	end
	e.Parent = p
	e:Emit(n)
end

local SMOKE = "rbxasset://textures/particles/smoke_main.dds"
local SPARKLE = "rbxasset://textures/particles/sparkles_main.dds"

-- Symbols that rise from the piece and fade: music notes.
local function rising(at: Vector3, text: string, color: Color3, n: number)
	for k = 1, n do
		task.delay((k - 1) * 0.25, function()
			local p = anchor(at + Vector3.new((k - (n + 1) / 2) * 0.9, 0, 0), 2)
			local gui = Instance.new("BillboardGui")
			gui.Size = UDim2.fromOffset(40, 40)
			gui.MaxDistance = 90
			gui.Adornee = p
			local label = Instance.new("TextLabel")
			label.BackgroundTransparency = 1
			label.Size = UDim2.fromScale(1, 1)
			label.Font = Enum.Font.FredokaOne
			label.TextScaled = true
			label.Text = text
			label.TextColor3 = color
			label.TextStrokeTransparency = 0.4
			label.TextStrokeColor3 = Color3.fromRGB(16, 18, 26)
			label.Parent = gui
			gui.Parent = p
			local info = TweenInfo.new(1.6, Enum.EasingStyle.Sine)
			TweenService:Create(gui, info, { StudsOffset = Vector3.new(0, 2.2, 0) }):Play()
			TweenService:Create(label, info, { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
		end)
	end
end

-- A puff from a piece, by its kind (Data/Interactions' `puff`).
function Interact.puff(at: Vector3, kind: string)
	if kind == "dust" then
		BuildFx.puff(at, 3, false)
	elseif kind == "sparkle" then
		burst(at, SPARKLE, ColorSequence.new(Color3.fromRGB(255, 230, 120), Color3.fromRGB(255, 255, 255)), 12, {
			LightEmission = 1,
			Size = NumberSequence.new(0.7, 0),
			Lifetime = NumberRange.new(0.6, 1),
			Speed = NumberRange.new(5, 9),
			SpreadAngle = Vector2.new(70, 70),
			Acceleration = Vector3.new(0, -8, 0),
		})
	elseif kind == "smoke" then
		burst(at, SMOKE, ColorSequence.new(Color3.fromRGB(96, 92, 98), Color3.fromRGB(150, 146, 150)), 14, {
			Size = NumberSequence.new(1, 3.5),
			Transparency = NumberSequence.new(0.2, 1),
			Lifetime = NumberRange.new(1.2, 2),
			Speed = NumberRange.new(2, 4),
			SpreadAngle = Vector2.new(25, 25),
			Acceleration = Vector3.new(0, 2, 0),
			RotSpeed = NumberRange.new(-40, 40),
		})
	elseif kind == "petals" then
		burst(at, SPARKLE, ColorSequence.new(Color3.fromRGB(245, 158, 181), Color3.fromRGB(255, 226, 236)), 16, {
			Size = NumberSequence.new(0.5, 0.2),
			Lifetime = NumberRange.new(1.2, 1.8),
			Speed = NumberRange.new(3, 6),
			SpreadAngle = Vector2.new(80, 80),
			Acceleration = Vector3.new(0, -3, 0),
			RotSpeed = NumberRange.new(-120, 120),
		})
	elseif kind == "bubbles" then
		burst(at, SPARKLE, ColorSequence.new(Color3.fromRGB(150, 210, 240), Color3.fromRGB(230, 246, 255)), 10, {
			Size = NumberSequence.new(0.3, 0.5),
			Transparency = NumberSequence.new(0.2, 0.8),
			Lifetime = NumberRange.new(1, 1.6),
			Speed = NumberRange.new(1, 2),
			SpreadAngle = Vector2.new(20, 20),
			Acceleration = Vector3.new(0, 3, 0),
		})
	elseif kind == "notes" then
		rising(at, "♪", Color3.fromRGB(79, 169, 217), 3)
	end
end

-- What happened, in a speech card over `adornee` (the head of the player who had the go, or a point
-- by the piece when there is no head to hang it from). A new one over the same head takes the old
-- one's place. It grows out of its point and shrinks back, like the bubbles over villagers.
local POP = TweenInfo.new(0.24, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local GO = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
local over: { [Instance]: BillboardGui } = {} -- the bubble up over each head
function Interact.bubble(adornee: BasePart, text: string, rare: boolean): BillboardGui
	local seconds = Tuning.Uses.Bubble + math.clamp(#text / 30, 0, 2)
	local old = over[adornee]
	if old then
		old:Destroy()
	end
	local gui = Bubble.billboard("UseBubble", adornee, Bubble.SpeechWidth + 60, 90)
	local fade, label = Bubble.speech(gui, text)
	if rare then
		label.TextColor3 = Bubble.Yellow
	end
	local scale = Instance.new("UIScale")
	scale.Name = "Pop"
	scale.Scale = 0.55
	scale.Parent = fade
	fade.GroupTransparency = 1
	gui.Parent = Players.LocalPlayer:FindFirstChild("PlayerGui") or adornee
	over[adornee] = gui
	TweenService:Create(scale, POP, { Scale = 1 }):Play()
	TweenService:Create(fade, POP, { GroupTransparency = 0 }):Play()
	task.delay(seconds, function()
		if gui.Parent then
			TweenService:Create(scale, GO, { Scale = 0.55 }):Play()
			TweenService:Create(fade, GO, { GroupTransparency = 1 }):Play()
		end
	end)
	task.delay(seconds + 0.25, function()
		if over[adornee] == gui then
			over[adornee] = nil
		end
		gui:Destroy()
	end)
	return gui
end

-- The head a player's bubble hangs over: their character's head, or its root.
local function headOf(who: any): BasePart?
	if typeof(who) ~= "Instance" or not who:IsA("Player") then
		return nil
	end
	local char = who.Character
	local head = char and (char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart"))
	return if head and head:IsA("BasePart") then head else nil
end

function Interact.start()
	Remotes.event("Used").OnClientEvent:Connect(function(at: any, puff: any, text: any, rarity: any, who: any)
		if typeof(at) ~= "Vector3" then
			return
		end
		local camera = workspace.CurrentCamera
		if camera and (camera.CFrame.Position - at).Magnitude > FAR then
			return
		end
		if type(puff) == "string" then
			Interact.puff(at, puff)
		end
		if type(text) == "string" and text ~= "" then
			-- over the head of whoever had the go (by the piece if they have no body to hang it on)
			local head = headOf(who) or anchor(at + Vector3.new(0, 1, 0), Tuning.Uses.Bubble + 3)
			Interact.bubble(head, text, rarity == "rare")
		end
		if rarity == "rare" and puff ~= "sparkle" then
			Interact.puff(at + Vector3.new(0, 1, 0), "sparkle")
		end
	end)
end

return Interact
