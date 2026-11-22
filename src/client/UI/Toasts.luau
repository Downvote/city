-- Short notices that pop in at the top of the screen and fade away: dark rounded pills with an
-- icon and an accent colour for the kind of notice.

local TweenService = game:GetService("TweenService")

local Kit = require(script.Parent.Kit)

local Toasts = {}

local holder: Frame? = nil

local ACCENTS = {
	info = Kit.Theme.Blue,
	good = Kit.Theme.Green,
	warn = Kit.Theme.Coral,
	event = Kit.Theme.Yellow,
}
local ICONS = { info = "💬", good = "✅", warn = "⚠️", event = "📣" }

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
	local k = if kind and ACCENTS[kind] then kind else "info"
	local card = Kit.frame({
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Color = Kit.Theme.Glass,
		Transparency = 0.08,
		Radius = 18,
		Parent = h,
		ZIndex = 50,
	})
	local stroke = Kit.stroke(card, ACCENTS[k], 2)
	stroke.Transparency = 0.1
	card.LayoutOrder = -math.floor(os.clock() * 100)
	Kit.pad(card, 16, 9)
	local row =
		Kit.box({ Parent = card, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, ZIndex = 51 })
	local icon = Kit.new("TextLabel", {
		Text = ICONS[k],
		BackgroundTransparency = 1,
		TextScaled = true,
		Font = Enum.Font.BuilderSansBold,
		Size = UDim2.fromOffset(24, 24),
		ZIndex = 52,
		Parent = row,
	})
	local label = Kit.text(text, {
		Parent = row,
		Size = UDim2.new(1, -34, 0, 0),
		Position = UDim2.fromOffset(34, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		TextSize = 17,
		Color = Kit.Theme.White,
		ZIndex = 52,
		Font = Kit.Fonts.Bold,
	})
	Kit.popIn(card)
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
		TweenService:Create(icon, info, { TextTransparency = 1 }):Play()
		TweenService:Create(stroke, info, { Transparency = 1 }):Play()
		task.wait(0.45)
		card:Destroy()
	end)
end

return Toasts
