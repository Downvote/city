-- Short notices that pop in at the top of the screen and fade away: charcoal rounded notes in a
-- thin rim, the left end a block in the colour of the kind of notice with its icon on it.

local TweenService = game:GetService("TweenService")

local Kit = require(script.Parent.Kit)
local Icons = require(script.Parent.Icons)

local Toasts = {}

local holder: Frame? = nil

local ACCENTS = {
	info = Kit.Theme.Blue,
	good = Kit.Theme.Green,
	warn = Kit.Theme.Red,
	event = Kit.Theme.Yellow,
}
local ICONS = { info = "news", good = "check", warn = "alert", event = "people" }
local BLOCK = 46 -- the icon's block across
local WIDTH = 460 -- a note across
local TEXT = 17 -- its words' size

-- How tall `text` comes out wrapped `width` across (the engine measures it; a reckoning by its
-- letters stands in where it can't).
local function textHeight(text: string, size: number, width: number): number
	local ok, bounds = pcall(function()
		return game:GetService("TextService"):GetTextSize(text, size, Kit.Fonts.Bold, Vector2.new(width, 2000))
	end)
	if ok and typeof(bounds) == "Vector2" and bounds.Y > 0 then
		return math.ceil(bounds.Y)
	end
	local perLine = math.max(1, math.floor(width / (size * 0.56)))
	return math.ceil(math.ceil(#text / perLine) * size * 1.25)
end

local function getHolder(): Frame
	if holder and holder.Parent then
		return holder
	end
	local f = Kit.box({
		Name = "Toasts",
		Size = UDim2.new(0, WIDTH, 0, 300),
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
	local accent: Color3 = ACCENTS[k]
	-- The note is as tall as its words, worked out here: the block's height is the note's, and a
	-- note that sized itself round its contents grew with the block, the height of every notice
	-- put together (the user: "notifications are bugged").
	local tall = math.max(BLOCK, textHeight(text, TEXT, WIDTH - BLOCK - 26) + 20)
	local card = Kit.frame({
		Size = UDim2.new(1, 0, 0, tall),
		Color = Kit.Theme.Paper,
		Radius = 16,
		Parent = h,
		ZIndex = 50,
	})
	Kit.softShadow(card, 0.8)
	local stroke = Kit.rim(card, Kit.Theme.Line, 1.5)
	card.LayoutOrder = -math.floor(os.clock() * 100)
	-- The icon's block fills the card's left end with no gap round it (the user: "make the
	-- background part of the icon fill the right part just like what was asked before with the
	-- other ones with no gaps"): as tall as the card, its left corners the card's own, its inner
	-- edge straight.
	local block = Kit.new("Frame", {
		Name = "Mark",
		BackgroundColor3 = accent,
		BorderSizePixel = 0,
		Size = UDim2.new(0, BLOCK, 1, 0),
		ZIndex = 51,
		Parent = card,
	})
	block:SetAttribute("KeepColors", true)
	Kit.corner(block, 16)
	local square = Kit.new("Frame", {
		Name = "Square",
		BackgroundColor3 = accent,
		BorderSizePixel = 0,
		Size = UDim2.new(0, 18, 1, 0),
		Position = UDim2.new(1, -18, 0, 0),
		ZIndex = 51,
		Parent = block,
	})
	square:SetAttribute("KeepColors", true)
	local light = accent.R * 0.3 + accent.G * 0.59 + accent.B * 0.11 > 0.5
	local icon = Icons.make(ICONS[k], 22, {
		Name = "IconArt",
		Parent = block,
		Position = UDim2.new(0.5, -11, 0.5, -11),
		Color = if light then Kit.Theme.Dark else Kit.Theme.White,
		Hole = accent,
		Mono = true,
		ZIndex = 52,
	})
	-- the words, clear of the block, in the middle of the note's height
	local label = Kit.text(text, {
		Parent = card,
		Size = UDim2.new(1, -(BLOCK + 26), 1, 0),
		Position = UDim2.fromOffset(BLOCK + 12, 0),
		TextSize = TEXT,
		Color = Kit.Theme.Ink,
		ZIndex = 52,
		Font = Kit.Fonts.Bold,
		AlignY = Enum.TextYAlignment.Center,
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
		icon.Visible = false
		TweenService:Create(block, info, { BackgroundTransparency = 1 }):Play()
		TweenService:Create(square, info, { BackgroundTransparency = 1 }):Play()
		TweenService:Create(stroke, info, { Transparency = 1 }):Play()
		task.wait(0.45)
		card:Destroy()
	end)
end

return Toasts
