-- Keeps the bubbles over villagers' heads in order, on each player's own screen. The user:
-- "improve villager bubbles above their head, and make it such that you cant see the bubbles
-- through walls. also, they sometimes intersect villager speech bubbles".
--
-- What hangs over a head (all drawn by Util/Bubble, all hanging from Bubble.Anchor over the head):
-- the speech card the server shows when they talk (a BillboardGui named Bubble in their model),
-- a mood badge (named Mood) and the wish bubble (World/Wishes, which hands it over with
-- Bubbles.track). A few times a second one loop:
--   * stacks what is showing over each head, speech at the bottom, the wish on top, with a gap
--     (World/BubbleLayout does the sums), and keeps two heads' stacks apart on the screen: the
--     nearer keeps its place and the further one goes up over it, or hides if that is too far;
--   * hides a head's stack while something solid stands between it and the camera: a ray from
--     the camera to the point the stack hangs from, through anything that isn't solid (CanCollide
--     off: leaves, long grass) and past every villager and player. The bubbles are drawn on top
--     (AlwaysOnTop), so the villager's own head and hat never cut into them, and the ray is what
--     keeps them from showing through a wall. They fade quickly in and out.
-- And every piece pops in when it comes and out when it goes (the user: "bubbles and textboxes over
-- villagers should have an animation transition when they appear or disappear"): it grows out of
-- its point under it, from small and clear to its size, and shrinks back and fades on its way out.
-- The server marks a piece `Going` a moment (Bubble.Leave) before it hides or removes it, and `Said`
-- when a speech card gets a new line (a smaller pop); this side watches for both on every head.
-- Everything moves with tweens on the pieces (each a CanvasGroup named Fade): nothing per frame.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Bubble = require(Shared.Util.Bubble)

local BubbleLayout = require(script.Parent.BubbleLayout)

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

-- A piece has come (or come back): small and clear for now; the next look places it and pops it
-- in, or keeps it hidden if a wall is in the way.
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

-- A speech card already showing got a new line: a small pop, no fade.
local function bump(gui: BillboardGui)
	local fade = fadeOf(gui)
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

-- Watches one head piece the server made: shown, hidden, marked going, a new line.
local function hook(gui: BillboardGui)
	if hooked[gui] then
		return
	end
	hooked[gui] = true
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

-- Is something solid between the camera and `at`?
local params: RaycastParams? = nil
local function blocked(from: Vector3, at: Vector3, skip: { Instance }): boolean
	if not params then
		local made = RaycastParams.new()
		made.FilterType = Enum.RaycastFilterType.Exclude
		made.RespectCanCollide = true
		made.IgnoreWater = true
		params = made
	end
	local p = params :: RaycastParams
	p.FilterDescendantsInstances = skip
	local hit = workspace:Raycast(from, at - from, p)
	return hit ~= nil
end

-- One look: what shows, where, and what is hidden.
function step()
	local cam = workspace.CurrentCamera
	if not cam then
		return
	end
	local eye = cam.CFrame.Position
	-- the ray goes past every villager and every player
	local skip: { Instance } = {}
	local plots = workspace:FindFirstChild("Plots")
	for _, plot in if plots then plots:GetChildren() else {} do
		local folder = plot:FindFirstChild("Villagers")
		if folder then
			table.insert(skip, folder)
		end
	end
	for _, p in Players:GetPlayers() do
		if p.Character then
			table.insert(skip, p.Character)
		end
	end
	local heads: { BubbleLayout.Head } = {}
	local fadesOf: { [Model]: { CanvasGroup } } = {}
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
		local hidden = not onScreen or blocked(eye, at, skip)
		local items: { BubbleLayout.Item } = {}
		local fades: { CanvasGroup } = {}
		for _, gui in pieces do
			local fade = fadeOf(gui)
			if fade then
				-- drawn on top: the ray, not the depth, keeps it from showing through a wall
				gui.AlwaysOnTop = true
				if hidden or far > gui.MaxDistance then
					setShown(fade, false)
				else
					table.insert(fades, fade)
					-- (its full size, while it's still popping in)
					local scale = math.max(0.1, popOf(fade).Scale)
					local size = fade.AbsoluteSize / scale
					table.insert(items, { w = size.X, h = size.Y })
				end
			end
		end
		if #items > 0 then
			fadesOf[model] = fades
			table.insert(heads, { key = model, x = screen.X, y = screen.Y, depth = screen.Z, items = items })
		end
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
