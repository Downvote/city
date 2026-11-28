-- Keeps the bubbles over villagers' heads in order, on each player's own screen. The user:
-- "improve villager bubbles above their head ... also, they sometimes intersect villager speech
-- bubbles".
--
-- What hangs over a head (all drawn by Util/Bubble, all hanging from Bubble.Anchor over the head):
-- the speech card the server shows when they talk (a BillboardGui named Bubble in their model),
-- a mood badge (named Mood) and the wish bubble (World/Wishes, which hands it over with
-- Bubbles.track). A few times a second, and at once when a piece comes, goes or gets new words, one
-- look stacks what is showing over each head, speech at the bottom, the wish on top, with a gap
-- (World/BubbleLayout does the sums), and keeps two heads' stacks apart on the screen: the nearer
-- keeps its place and the further one goes up over it, or hides if that is too far. Each piece is
-- stacked by its full size worked out from what is in it (Bubble.size), never by what the screen
-- last drew: a piece just come, or popping in, isn't drawn at its size yet, and stacking by that
-- once put a heart over the words of a speech card that came with it (the user: "it seems like
-- bubbles like heart bubbles overlap with text sometimes when they appear at the same time").
-- A piece whose size can't be told yet waits, hidden, for the next look.
--
-- The bubbles are drawn on top (AlwaysOnTop), so the villager's own head and hat never cut into
-- them, and they show through walls too: they used to hide while a wall stood between them and the
-- camera, and the user asked for that to go ("could you remove the hiding of bubbles behind
-- walls?").
--
-- And every piece pops in when it comes and out when it goes (the user: "bubbles and textboxes over
-- villagers should have an animation transition when they appear or disappear"): it grows out of
-- its point under it, from small and clear to its size, and shrinks back and fades on its way out.
-- The server marks a piece `Going` a moment (Bubble.Leave) before it hides or removes it, and `Said`
-- when a speech card gets a new line (a smaller pop); this side watches for both on every head.
-- Everything moves with tweens on the pieces (each a CanvasGroup named Fade): nothing per frame.

local TweenService = game:GetService("TweenService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Bubble = require(Shared.Util.Bubble)

local BubbleLayout = require(script.Parent.BubbleLayout)
local MoodArt = require(script.Parent.MoodArt)

local Bubbles = {}

local EVERY = 0.15 -- seconds between looks
local MOVE = TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local FADE = TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local POP_IN = TweenInfo.new(0.24, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local POP_OUT = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
local SMALL = 0.55 -- how small a piece starts and goes back to
-- the order pieces stack in over a head, bottom first
local ORDER = { Bubble = 1, Mood = 2, WishBubble = 3 }

local tracked: { [Model]: { BillboardGui } } = {} -- the client's own bubbles, by the model they're over
local shownAt: { [Instance]: number } = {} -- each piece's lift now
local alphaAt: { [Instance]: number } = {} -- and how see-through it is now
local hooked: { [Instance]: boolean } = {} -- the head pieces whose comings and goings are watched

local function fadeOf(gui: BillboardGui): CanvasGroup?
	local f = gui:FindFirstChild("Fade")
	return if f and f:IsA("CanvasGroup") then f else nil
end

-- The UIScale a piece pops with.
local function popOf(fade: CanvasGroup): UIScale
	local s = fade:FindFirstChild("Pop")
	if s and s:IsA("UIScale") then
		return s
	end
	local made = Instance.new("UIScale")
	made.Name = "Pop"
	made.Parent = fade
	return made
end

-- How big words come out on this screen (TextService), for Bubble.size, kept for the words said
-- lately. Where there is no TextService to ask (the previews) it fails, and the size the screen
-- drew is used instead.
local textService: any = false
local measured: { [string]: Vector2 } = {}
local kept = 0
local function measure(text: string, size: number, font: Enum.Font, width: number): Vector2
	local key = text .. "\0" .. size .. "\0" .. width .. "\0" .. font.Name
	local known = measured[key]
	if known then
		return known
	end
	if textService == false then
		local ok, found = pcall(function()
			return game:GetService("TextService")
		end)
		textService = if ok then found else nil
	end
	if not textService then
		error("no TextService")
	end
	local got = textService:GetTextSize(text, size, font, Vector2.new(width, 10000))
	if kept > 200 then
		table.clear(measured)
		kept = 0
	end
	measured[key] = got
	kept += 1
	return got
end

-- A piece's full size, from what is in it (Bubble.size), or failing that from what the screen
-- drew (divided by the pop it is drawn at). Nil while it hasn't any size yet.
local function sizeOf(fade: CanvasGroup): Vector2?
	local ok, size = pcall(Bubble.size, fade, measure)
	if ok and size then
		return size
	end
	local drawn = fade.AbsoluteSize
	if drawn.X < 1 or drawn.Y < 1 then
		return nil
	end
	local pop = fade:FindFirstChild("Pop")
	local scale = if pop and pop:IsA("UIScale") then math.max(0.1, pop.Scale) else 1
	return drawn / scale
end
Bubbles.sizeOf = sizeOf

local step: () -> () -- (below)
local soon = false
-- Runs a look at once (in a moment, once for a few calls), so what just came is placed and shown.
local function lookSoon()
	if soon then
		return
	end
	soon = true
	task.defer(function()
		soon = false
		local ok, err = pcall(step)
		if not ok then
			warn("bubbles: " .. tostring(err))
		end
	end)
end

-- A piece has come (or come back): small and clear for now; the next look (at once) places it and
-- pops it in.
local function arrive(gui: BillboardGui)
	local fade = fadeOf(gui)
	if not fade then
		return
	end
	popOf(fade).Scale = SMALL
	fade.GroupTransparency = 1
	alphaAt[fade] = 1
	shownAt[fade] = nil
	lookSoon()
end

-- A piece is on its way out: it shrinks back toward its point and fades. The look leaves it alone.
local function leave(gui: BillboardGui)
	local fade = fadeOf(gui)
	if not fade then
		return
	end
	alphaAt[fade] = 1
	TweenService:Create(popOf(fade), POP_OUT, { Scale = SMALL }):Play()
	TweenService:Create(fade, POP_OUT, { GroupTransparency = 1 }):Play()
	lookSoon() -- (what was over it comes down into its place)
end

-- A speech card already showing got a new line: a small pop, no fade, and what is over it moves to
-- make room for the new words at once.
local function bump(gui: BillboardGui)
	local fade = fadeOf(gui)
	lookSoon()
	if not fade or alphaAt[fade] ~= 0 then
		return
	end
	local s = popOf(fade)
	s.Scale = 0.88
	TweenService:Create(s, POP_IN, { Scale = 1 }):Play()
end

local function going(gui: Instance): boolean
	return gui:GetAttribute("Going") == true
end

-- A mood badge's symbol drawn as an icon that fills it (World/MoodArt).
Bubbles.dress = MoodArt.dress

-- Watches one head piece the server made: shown, hidden, marked going, a new line.
local function hook(gui: BillboardGui)
	if hooked[gui] then
		return
	end
	hooked[gui] = true
	if gui.Name == "Mood" then
		local kind = gui:GetAttribute("Kind")
		Bubbles.dress(gui, if type(kind) == "string" then kind else nil)
	end
	gui.Destroying:Connect(function()
		hooked[gui] = nil
	end)
	gui:GetPropertyChangedSignal("Enabled"):Connect(function()
		if gui.Enabled and not going(gui) then
			arrive(gui)
		end
	end)
	gui:GetAttributeChangedSignal("Going"):Connect(function()
		if going(gui) then
			leave(gui)
		elseif gui.Enabled then
			arrive(gui)
		end
	end)
	gui:GetAttributeChangedSignal("Said"):Connect(function()
		if gui.Enabled and not going(gui) then
			bump(gui)
		end
	end)
	-- (new words can come a moment before or after `Said`: the stack is looked at again either way)
	local words = gui:FindFirstChild("Text", true)
	if words and words:IsA("TextLabel") then
		words:GetPropertyChangedSignal("Text"):Connect(function()
			if gui.Enabled and not going(gui) then
				lookSoon()
			end
		end)
	end
	if gui.Enabled and not going(gui) then
		arrive(gui)
	end
end

-- Takes a bubble the client made off a head, popping it out first.
function Bubbles.dismiss(gui: BillboardGui)
	if going(gui) then
		return
	end
	gui:SetAttribute("Going", true)
	gui.Active = false
	leave(gui)
	task.delay(0.25, function()
		gui:Destroy()
	end)
end

-- Hands a bubble the client made (the wish bubble) to the loop. It goes when it is destroyed.
function Bubbles.track(model: Model, gui: BillboardGui)
	local list = tracked[model] or {}
	tracked[model] = list
	table.insert(list, gui)
	arrive(gui)
	gui.Destroying:Connect(function()
		local now = tracked[model]
		if now then
			local i = table.find(now, gui)
			if i then
				table.remove(now, i)
			end
			if #now == 0 then
				tracked[model] = nil
			end
		end
	end)
end

-- Every villager model in town.
local function villagers(): { Model }
	local out = {}
	local plots = workspace:FindFirstChild("Plots")
	for _, plot in if plots then plots:GetChildren() else {} do
		local folder = plot:FindFirstChild("Villagers")
		for _, m in if folder then folder:GetChildren() else {} do
			if m:IsA("Model") then
				table.insert(out, m)
			end
		end
	end
	return out
end

-- What is over a head and showing, bottom first.
local function piecesOf(model: Model): { BillboardGui }
	local out = {}
	for _, c in model:GetChildren() do
		if c:IsA("BillboardGui") and ORDER[c.Name] then
			hook(c)
			if c.Enabled and not going(c) then
				table.insert(out, c)
			end
		end
	end
	local own: { BillboardGui } = tracked[model] or {}
	for _, gui in own do
		if gui.Parent and gui.Enabled and not going(gui) then
			table.insert(out, gui)
		end
	end
	table.sort(out, function(a, b)
		return (ORDER[a.Name] or 9) < (ORDER[b.Name] or 9)
	end)
	return out
end

local function setLift(fade: CanvasGroup, lift: number)
	local was = shownAt[fade]
	if was and math.abs(was - lift) < 1 then
		return
	end
	shownAt[fade] = lift
	local to = UDim2.new(0.5, 0, 0.5, -lift)
	if was == nil then
		fade.Position = to
	else
		TweenService:Create(fade, MOVE, { Position = to }):Play()
	end
end

local function setShown(fade: CanvasGroup, on: boolean)
	local want = if on then 0 else 1
	if alphaAt[fade] == want then
		return
	end
	alphaAt[fade] = want
	if on then
		fade.Visible = true
		-- (coming in: it grows out of its point as it shows)
		local s = popOf(fade)
		if s.Scale < 1 then
			TweenService:Create(s, POP_IN, { Scale = 1 }):Play()
			TweenService:Create(fade, POP_IN, { GroupTransparency = 0 }):Play()
			return
		end
	end
	TweenService:Create(fade, FADE, { GroupTransparency = want }):Play()
	if not on then
		task.delay(0.16, function()
			if alphaAt[fade] == 1 then
				-- (gone, so a hidden wish bubble can't be clicked)
				fade.Visible = false
			end
		end)
	end
end

-- One look: what shows, where, and what is hidden.
local waiting = false -- a look is due again for a piece that had no size yet
function step()
	local cam = workspace.CurrentCamera
	if not cam then
		return
	end
	local eye = cam.CFrame.Position
	local heads: { BubbleLayout.Head } = {}
	local fadesOf: { [Model]: { CanvasGroup } } = {}
	local unready = false
	for _, model in villagers() do
		local pieces = piecesOf(model)
		if #pieces == 0 then
			continue
		end
		local head = model:FindFirstChild("Head") or model.PrimaryPart
		if not (head and head:IsA("BasePart")) then
			continue
		end
		local at = head.Position + Bubble.Anchor
		local far = (at - eye).Magnitude
		local screen, onScreen = cam:WorldToViewportPoint(at)
		local items: { BubbleLayout.Item } = {}
		local fades: { CanvasGroup } = {}
		for _, gui in pieces do
			local fade = fadeOf(gui)
			if fade then
				-- drawn on top: a head or a hat never cuts into it
				gui.AlwaysOnTop = true
				local size = if onScreen and far <= gui.MaxDistance then sizeOf(fade) else nil
				if not size then
					if onScreen and far <= gui.MaxDistance then
						unready = true -- (not laid out yet: it waits, hidden, so nothing is stacked into it)
					end
					setShown(fade, false)
				else
					table.insert(fades, fade)
					table.insert(items, { w = size.X, h = size.Y })
				end
			end
		end
		if #items > 0 then
			fadesOf[model] = fades
			table.insert(heads, { key = model, x = screen.X, y = screen.Y, depth = screen.Z, items = items })
		end
	end
	if unready and not waiting then
		waiting = true
		task.delay(0.05, function()
			waiting = false
			lookSoon()
		end)
	end
	local placed = BubbleLayout.arrange(heads, { Base = Bubble.Base, Gap = Bubble.Gap })
	for model, fades in fadesOf do
		local place = placed[model]
		for i, fade in fades do
			if place and not place.hidden then
				setLift(fade, place.lifts[i])
				setShown(fade, true)
			else
				setShown(fade, false)
			end
		end
	end
	-- forget what has gone
	for fade in shownAt do
		if not fade.Parent then
			shownAt[fade] = nil
			alphaAt[fade] = nil
		end
	end
	for fade in alphaAt do
		if not fade.Parent then
			alphaAt[fade] = nil
		end
	end
end
Bubbles.step = step

local started = false
function Bubbles.start()
	if started then
		return
	end
	started = true
	task.spawn(function()
		while true do
			task.wait(EVERY)
			local ok, err = pcall(step)
			if not ok then
				warn("bubbles: " .. tostring(err))
			end
		end
	end)
end

return Bubbles
