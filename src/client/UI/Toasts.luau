-- Short notices that slide in at the top of the screen and fade away.

local TweenService = game:GetService("TweenService")

local Kit = require(script.Parent.Kit)

local Toasts = {}

local holder: Frame? = nil

local COLORS = {
	info = Kit.Theme.Paper,
	good = Color3.fromRGB(226, 245, 214),
	warn = Color3.fromRGB(255, 228, 220),
	event = Color3.fromRGB(255, 240, 200),
}

local function getHolder(): Frame
	if holder and holder.Parent then
		return holder
	end
	local f = Kit.box({
		Name = "Toasts",
		Size = UDim2.new(0, 460, 0, 300),
		Position = UDim2.new(0.5, 0, 0, 70),
		AnchorPoint = Vector2.new(0.5, 0),
		Parent = Kit.root(),
	})
	f.ZIndex = 50
	Kit.list(f, 6, false, Enum.HorizontalAlignment.Center)
	holder = f
	return f
end

function Toasts.show(text: string, kind: string?)
	local h = getHolder()
	local card = Kit.frame({
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Color = COLORS[kind or "info"] or Kit.Theme.Paper,
		Stroke = Kit.Theme.Line,
		Parent = h,
		ZIndex = 50,
	})
	card.LayoutOrder = -math.floor(os.clock() * 100)
	Kit.pad(card, 14, 8)
	local label = Kit.text(text, {
		Parent = card,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		TextSize = 18,
		AlignX = Enum.TextXAlignment.Center,
		ZIndex = 51,
		Font = Kit.Fonts.Bold,
	})
	-- keep a few at most
	local cards = {}
	for _, c in h:GetChildren() do
		if c:IsA("Frame") then
			table.insert(cards, c)
		end
	end
	if #cards > 4 then
		table.sort(cards, function(a, b)
			return a.LayoutOrder > b.LayoutOrder
		end)
		cards[1]:Destroy()
	end
	task.delay(3.6, function()
		if not card.Parent then
			return
		end
		local info = TweenInfo.new(0.4)
		TweenService:Create(card, info, { BackgroundTransparency = 1 }):Play()
		TweenService:Create(label, info, { TextTransparency = 1 }):Play()
		local stroke = card:FindFirstChildOfClass("UIStroke")
		if stroke then
			TweenService:Create(stroke, info, { Transparency = 1 }):Play()
		end
		task.wait(0.45)
		card:Destroy()
	end)
end

return Toasts
