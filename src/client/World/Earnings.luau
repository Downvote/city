-- Coins over a villager as they earn them. The user: "make it such that villagers earn coins as
-- they work, not after every day". Every few seconds the server says which of the player's own
-- villagers earned how much since the last time (the `Earned` event, from Services/Villagers):
-- each of them near enough to see gets a coin and "+N" that rises off their head and fades, and
-- the town's coins count up on the main screen. The HUD counts a pay packet up quietly, with no
-- coins flying across the screen every few seconds: it knows one by State.data.wages.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Remotes = require(Shared.Net.Remotes)
local Text = require(Shared.Util.Text)

local Kit = require(script.Parent.Parent.UI.Kit)
local Icons = require(script.Parent.Parent.UI.Icons)
local Dialogue = require(script.Parent.Parent.UI.Dialogue)
local State = require(script.Parent.Parent.Controllers.State)

local Earnings = {}

local T = Kit.Theme
local player = Players.LocalPlayer

local SEEN = 120 -- studs: further from the camera than this, a villager's coins aren't shown
local RISE = 1.6 -- seconds a coin takes to rise off their head and fade
local FROM = Vector3.new(-1.3, 2.7, 0) -- where it starts, beside the head (a wish bubble is over it)
local TO = Vector3.new(-1.3, 4.3, 0)

-- What floats up: the coin and "+N" side by side on a small pill of the dark glass that sits over
-- the 3D view everywhere (so a gold coin still shows on a sunny roof), in a group that fades as one.
function Earnings.card(n: number, parent: Instance?): CanvasGroup
	local group = Kit.new("CanvasGroup", {
		Name = "Coins",
		BackgroundColor3 = T.Glass,
		BackgroundTransparency = 0.35,
		BorderSizePixel = 0,
		Size = UDim2.fromOffset(0, 34),
		AutomaticSize = Enum.AutomaticSize.X,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Parent = parent,
	})
	Kit.corner(group, "pill")
	Kit.pad(group, 8, 0)
	local row = Kit.list(group, 4, true, Enum.HorizontalAlignment.Center)
	row.VerticalAlignment = Enum.VerticalAlignment.Center
	Icons.make("coin", 24, { Name = "Coin", Parent = group, LayoutOrder = 1 })
	Kit.title(Text.fill("+{n}", { n = Text.commas(n) }), {
		Name = "Amount",
		Parent = group,
		Size = UDim2.fromOffset(0, 30),
		AutomaticSize = Enum.AutomaticSize.X,
		TextSize = 22,
		Color = T.Yellow,
		Outline = T.Dark,
		Wrap = false,
		LayoutOrder = 2,
	})
	return group
end

-- A coin rising off a villager's head. Nil when they are too far off to see it.
function Earnings.pop(model: Model, n: number): BillboardGui?
	local head = model:FindFirstChild("Head") or model.PrimaryPart
	local gui = player:FindFirstChild("PlayerGui")
	if not head or not head:IsA("BasePart") or not gui or n <= 0 then
		return nil
	end
	local cam = workspace.CurrentCamera
	if cam and (cam.CFrame.Position - head.Position).Magnitude > SEEN then
		return nil
	end
	local bb = Instance.new("BillboardGui")
	bb.Name = "CoinPop"
	bb.Adornee = head
	bb.Size = UDim2.fromOffset(130, 34)
	bb.StudsOffset = FROM
	bb.MaxDistance = SEEN
	-- (over walls too, as the wish bubbles are: most work goes on indoors)
	bb.AlwaysOnTop = true
	bb.ResetOnSpawn = false
	local card = Earnings.card(n, bb)
	bb.Parent = gui
	TweenService:Create(bb, TweenInfo.new(RISE, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { StudsOffset = TO })
		:Play()
	TweenService
		:Create(card, TweenInfo.new(RISE / 2, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, RISE / 2), {
			GroupTransparency = 1,
		})
		:Play()
	task.delay(RISE + 0.05, function()
		bb:Destroy()
	end)
	return bb
end

-- A pay packet from the server: the coins over whoever earned them, and the town's coins.
function Earnings.got(msg: any)
	if type(msg) ~= "table" then
		return
	end
	local total = 0
	for _, line in (if type(msg.lines) == "table" then msg.lines else {}) do
		if type(line) == "table" and type(line.n) == "number" and line.n > 0 then
			total += line.n
			local model = Dialogue.modelOf(line.vid)
			if model then
				Earnings.pop(model, line.n)
			end
		end
	end
	local stats = State.data.stats
	if type(stats) == "table" and type(msg.earned) == "number" then
		stats.earned = msg.earned
	end
	if type(msg.coins) == "number" then
		State.data.wages = { coins = msg.coins, n = total }
		State.set("coins", msg.coins)
	end
end

function Earnings.start()
	Remotes.event("Earned").OnClientEvent:Connect(Earnings.got)
end

return Earnings
