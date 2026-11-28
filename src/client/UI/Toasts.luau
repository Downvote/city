-- Short notices at the top of the screen, level with the clock (the user: "could you make
-- notifications appear as a transparent, black background instead with a white icon, as a rounded
-- rectangle, and appear right on top, at the same y level as where the time bar is?"). Each is a
-- see-through dark rounded note, as wide as its words, a white icon for its kind at the left and
-- the words in white. The newest drops in at the top and pushes the others down; each fades away
-- after a few seconds and the ones under it close up.

local Kit = require(script.Parent.Kit)
local Icons = require(script.Parent.Icons)

local Toasts = {}

local T = Kit.Theme

local holder: Frame? = nil

local ICONS = { info = "news", good = "check", warn = "alert", event = "people" }
local MOST_WIDE = 460 -- a note across at the most; longer words wrap
local TEXT = 16 -- its words' size
local ICON = 22 -- its icon across
local PAD = 14 -- room at its left end, before the icon
local GAP = 10 -- between the icon and the words
local END = 18 -- room after the words
local LOW = 44 -- a note's height with one line of words
local ROOM = 22 -- the room above and below the words of a longer note
local GLASS = 0.3 -- how see-through its dark ground is
local CORNER = 14
local MIDDLE = 36 -- the clock's middle line, from the top of the screen: a one line note sits on it
local SHOWN = 3.6 -- seconds a note stays
local MOST = 4 -- notes up at once
local DROP_TIME = 0.32
local DROP = TweenInfo.new(DROP_TIME, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local FADE_TIME = 0.26
local FADE = TweenInfo.new(FADE_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
local CLOSE_TIME = 0.18
local CLOSE = TweenInfo.new(CLOSE_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

-- How wide and tall `text` comes out wrapped `width` across (the engine measures it; a reckoning
-- by its letters stands in where it can't).
local function textSize(text: string, size: number, width: number): Vector2
	local ok, bounds = pcall(function()
		return game:GetService("TextService"):GetTextSize(text, size, Kit.Fonts.Bold, Vector2.new(width, 2000))
	end)
	if ok and typeof(bounds) == "Vector2" and bounds.X > 0 and bounds.Y > 0 then
		return Vector2.new(math.ceil(bounds.X), math.ceil(bounds.Y))
	end
	local perLine = math.max(1, math.floor(width / (size * 0.56)))
	local lines = math.ceil(#text / perLine)
	local wide = if lines > 1 then width else math.ceil(#text * size * 0.56)
	return Vector2.new(wide, math.ceil(lines * size * 1.25))
end

local function getHolder(): Frame
	if holder and holder.Parent then
		return holder
	end
	local f = Kit.box({
		Name = "Toasts",
		Size = UDim2.fromOffset(MOST_WIDE, 300),
		-- (the screen's own interface starts under the strip Roblox keeps at the top, where the
		-- clock hangs: the notes go up into it beside the clock)
		Position = UDim2.new(0.5, 0, 0, MIDDLE - LOW / 2 - Kit.topInset()),
		AnchorPoint = Vector2.new(0.5, 0),
		Parent = Kit.root(),
	})
	f.ZIndex = 50
	Kit.list(f, 6, false, Enum.HorizontalAlignment.Center)
	holder = f
	return f
end

-- Fades a note away and closes up the room it took.
local function leave(slot: Frame)
	if slot:GetAttribute("Going") then
		return
	end
	slot:SetAttribute("Going", true)
	slot.ClipsDescendants = true
	local note = slot:FindFirstChild("Note") :: CanvasGroup?
	if note then
		Kit.tween(note, FADE, { GroupTransparency = 1, Position = UDim2.fromOffset(0, -10) })
	end
	task.delay(FADE_TIME, function()
		Kit.tween(slot, CLOSE, { Size = UDim2.fromOffset(slot.Size.X.Offset, 0) })
		task.delay(CLOSE_TIME, function()
			slot:Destroy()
		end)
	end)
end

function Toasts.show(text: string, kind: string?)
	local h = getHolder()
	local k = if kind and ICONS[kind] then kind else "info"
	-- The note is as wide and as tall as its words, worked out here, never left to AutomaticSize
	-- (a notice that sized itself once came out half the screen tall: "notifications are bugged").
	local words = textSize(text, TEXT, MOST_WIDE - PAD - ICON - GAP - END)
	local wide = PAD + ICON + GAP + words.X + END
	local tall = math.max(LOW, words.Y + ROOM)
	-- its room in the list, which opens as the note drops into it
	local slot = Kit.box({
		Name = "Toast",
		Size = UDim2.fromOffset(wide, 0),
		Parent = h,
	})
	slot.ZIndex = 50
	slot.ClipsDescendants = true
	slot.LayoutOrder = -math.floor(os.clock() * 100)
	-- the note: dark and see-through in either look, cut to its rounded corners
	local note = Kit.frame({
		Name = "Note",
		Size = UDim2.fromOffset(wide, tall),
		Position = UDim2.fromOffset(0, -tall),
		Color = T.Glass,
		Transparency = GLASS,
		Radius = CORNER,
		Clips = true,
		ZIndex = 50,
		Parent = slot,
	}) :: any
	note:SetAttribute("KeepColors", true)
	note.GroupTransparency = 1
	Icons.make(ICONS[k], ICON, {
		Name = "IconArt",
		Parent = note,
		Position = UDim2.new(0, PAD, 0.5, -ICON / 2),
		Color = T.White,
		Hole = T.Glass,
		Mono = true,
		Centre = true,
		ZIndex = 51,
	})
	Kit.text(text, {
		Name = "Words",
		Parent = note,
		Size = UDim2.new(0, words.X + 4, 1, 0),
		Position = UDim2.fromOffset(PAD + ICON + GAP, 0),
		TextSize = TEXT,
		Color = T.White,
		Font = Kit.Fonts.Bold,
		AlignY = Enum.TextYAlignment.Center,
		ZIndex = 51,
	})
	-- it drops in from above, the ones under it moving down to make room
	Kit.tween(slot, DROP, { Size = UDim2.fromOffset(wide, tall) })
	Kit.tween(note, DROP, { Position = UDim2.fromOffset(0, 0), GroupTransparency = 0 })
	task.delay(DROP_TIME, function()
		if slot.Parent and not slot:GetAttribute("Going") then
			slot.ClipsDescendants = false
		end
	end)
	-- keep a few at most: the oldest goes
	local slots = {}
	for _, c in h:GetChildren() do
		if c:IsA("Frame") and not c:GetAttribute("Going") then
			table.insert(slots, c)
		end
	end
	if #slots > MOST then
		table.sort(slots, function(a, b)
			return a.LayoutOrder > b.LayoutOrder
		end)
		leave(slots[1])
	end
	task.delay(SHOWN, function()
		if slot.Parent then
			leave(slot)
		end
	end)
end

return Toasts
