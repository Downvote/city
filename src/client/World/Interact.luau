-- What a go at a piece looks like on this screen. The server sends `Used` (Npc/Use.show) when a
-- villager's go gives something off (smoke from a burnt pan, petals from a plant coming into
-- flower) and when a player holds E on a piece (Services/Interact): a puff from the piece and, for
-- a player's go, a bubble over it saying what happened, in the look of the villagers' own speech
-- bubbles. A rare outcome gets a gold rim and a few sparkles. Only what is near the camera shows.

local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Tuning = require(Shared.Config.Tuning)
local Remotes = require(Shared.Net.Remotes)

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

-- What happened, in a bubble over the piece: the look of a villager's speech bubble (Npc's), the
-- same in the dark and the light look, since it hangs in the world like theirs.
function Interact.bubble(at: Vector3, text: string, rare: boolean)
	local seconds = Tuning.Uses.Bubble + math.clamp(#text / 30, 0, 2)
	local p = anchor(at, seconds + 0.5)
	local gui = Instance.new("BillboardGui")
	gui.Name = "UseBubble"
	gui.Size = UDim2.fromOffset(260, 80)
	gui.StudsOffset = Vector3.new(0, 1.2, 0)
	gui.MaxDistance = 90
	gui.Adornee = p
	local card = Instance.new("Frame")
	card.Name = "Card"
	card.AnchorPoint = Vector2.new(0.5, 1)
	card.Position = UDim2.fromScale(0.5, 1)
	card.Size = UDim2.fromScale(0, 0)
	card.AutomaticSize = Enum.AutomaticSize.XY
	card.BackgroundColor3 = Color3.fromRGB(37, 40, 54)
	card.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = card
	local stroke = Instance.new("UIStroke")
	stroke.Color = if rare then Color3.fromRGB(240, 196, 92) else Color3.fromRGB(66, 71, 93)
	stroke.Thickness = 2
	stroke.Parent = card
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 10)
	pad.PaddingRight = UDim.new(0, 10)
	pad.PaddingTop = UDim.new(0, 6)
	pad.PaddingBottom = UDim.new(0, 6)
	pad.Parent = card
	local label = Instance.new("TextLabel")
	label.Name = "Text"
	label.BackgroundTransparency = 1
	label.AutomaticSize = Enum.AutomaticSize.XY
	label.Size = UDim2.fromOffset(0, 0)
	label.Font = Enum.Font.BuilderSansMedium
	label.TextSize = 18
	label.TextWrapped = true
	label.Text = text
	label.TextColor3 = Color3.fromRGB(236, 238, 246)
	label.Parent = card
	local limit = Instance.new("UISizeConstraint")
	limit.MaxSize = Vector2.new(250, 200)
	limit.Parent = label
	local scale = Instance.new("UIScale")
	scale.Scale = 0.6
	scale.Parent = card
	gui.Parent = p
	TweenService:Create(scale, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 })
		:Play()
	task.delay(seconds, function()
		if gui.Parent then
			TweenService:Create(scale, TweenInfo.new(0.15), { Scale = 0.01 }):Play()
		end
	end)
end

function Interact.start()
	Remotes.event("Used").OnClientEvent:Connect(function(at: any, puff: any, text: any, rarity: any)
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
			Interact.bubble(at + Vector3.new(0, 1, 0), text, rarity == "rare")
		end
		if rarity == "rare" and puff ~= "sparkle" then
			Interact.puff(at + Vector3.new(0, 1, 0), "sparkle")
		end
	end)
end

return Interact
