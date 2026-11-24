-- Quests on the main screen, under the town's level and its money, people and happiness (the
-- user: "put these as a tab below the level, then add quests below it as well"). The town's goals
-- (Data/Goals, Sim/Life) that are next: the ones done and waiting to be claimed first, then the
-- ones furthest along, at most three, each with how far along it is. A finished one has its Claim
-- button right there; a click anywhere else on a quest opens the goals menu. The header folds the
-- list away and back.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Remotes = require(Shared.Net.Remotes)
local Life = require(Shared.Sim.Life)
local Text = require(Shared.Util.Text)

local Kit = require(script.Parent.Kit)
local Icons = require(script.Parent.Icons)
local State = require(script.Parent.Parent.Controllers.State)

local Quests = {}

local T = Kit.Theme

Quests.Shown = 3 -- quests on the screen at once
local ROW = 48
local SOFT = Color3.fromRGB(206, 218, 240) -- soft words on the dark glass (it is dark in both looks)

-- A profile-like table from the client state, for Sim/Life.
local function view(): any
	local d = State.data
	return {
		villagers = d.villagers or {},
		rel = d.rel or {},
		stats = d.stats or {},
		goals = d.goals or {},
		plan = State.plan,
		coins = d.coins or 0,
	}
end

-- The quests to show: done and unclaimed first, then the rest by how far along they are.
function Quests.next(profile: any, count: number?): { any }
	local ready, going = {}, {}
	for _, g in Life.goals(profile) do
		if g.done and not g.claimed then
			table.insert(ready, g)
		elseif not g.claimed then
			table.insert(going, g)
		end
	end
	table.sort(going, function(a, b)
		local fa, fb = a.value / math.max(1, a.goal.need), b.value / math.max(1, b.goal.need)
		if fa ~= fb then
			return fa > fb
		end
		return a.goal.need < b.goal.need
	end)
	local out = {}
	for _, list in { ready, going } do
		for _, g in list do
			if #out < (count or Quests.Shown) then
				table.insert(out, g)
			end
		end
	end
	return out
end

local root: Frame? = nil
local rows: Frame? = nil
local readyChip: Frame? = nil
local folded = false
local onOpen: () -> () = function() end
local claiming: { [string]: boolean } = {}

local CLAIM_WIDTH = 112 -- the Claim button's width at its middle, flush with a quest's right end

local function quest(g: any, order: number): Frame
	local ready = g.done and not g.claimed
	local slab = Kit.darkPill({
		Name = g.goal.id,
		Parent = rows,
		Size = UDim2.new(1, -12, 0, ROW - 6),
		LayoutOrder = order,
	})
	local hit = Kit.new("TextButton", {
		Name = "Open",
		Text = "",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 2,
		Parent = slab,
	})
	hit.Activated:Connect(function()
		onOpen()
	end)
	Kit.press(hit, { Kind = "slab", Face = slab, Grow = 1, Dip = 0.99 })
	-- a marker filling the slab's left end, flush with it like the Claim button at the right:
	-- yellow with a tick when it's done, the goal's own mark otherwise
	local cap = slab:GetAttribute("Cap")
	local _, reach = Kit.flushMark(slab, slab, ROW - 6, true, {
		Name = "Marker",
		-- (the quests come out of the screen's left edge: their slanted end is out of sight)
		Hidden = if type(cap) == "number" then cap else 0,
		Color = if ready then T.Yellow else T.Blue,
		Icon = if ready then "check" else "trophy",
		IconColor = T.Dark,
		ZIndex = 3,
	})
	local textX = math.ceil(reach) + 10
	local name = Kit.title(g.goal.name, {
		Name = "Name",
		Parent = slab,
		Size = UDim2.new(1, -(textX + 116), 0, 20),
		Position = UDim2.fromOffset(textX, 4),
		TextSize = 16,
		Color = T.White,
		Wrap = false,
	})
	name.TextTruncate = Enum.TextTruncate.AtEnd
	name.ZIndex = 3
	local desc = Kit.text(g.goal.desc, {
		Name = "Desc",
		Parent = slab,
		Size = UDim2.new(1, -(textX + 116), 0, 15),
		Position = UDim2.fromOffset(textX, 23),
		TextSize = 12,
		Color = SOFT,
		Wrap = false,
	})
	desc.TextTruncate = Enum.TextTruncate.AtEnd
	desc.ZIndex = 3
	if ready then
		-- The Claim button fills the slab's whole right end, its slanted edge on the slab's own
		-- (the user: "make the claim button fill the entire right side instead of having a gap
		-- around"). The slab's ends stand out past its box by its cap and the button's sit inside
		-- its own, so a button as tall as the slab whose box ends one cap past the slab's lines up.
		local cap = slab:GetAttribute("Cap")
		local lean = if type(cap) == "number" then cap else 0
		local claim = Kit.button(Text.fill("Claim {n}", { n = Text.commas(g.goal.reward) }), {
			Name = "Claim",
			Parent = slab,
			Size = UDim2.fromOffset(CLAIM_WIDTH + lean, ROW - 6),
			Position = UDim2.new(1, lean, 0, 0),
			-- its left end a clean slanted cut into the quest, its right end the quest's own
			Sharp = "left",
			AnchorPoint = Vector2.new(1, 0),
			Color = T.Yellow,
			TextColor = T.Dark,
			TextSize = 15,
			ZIndex = 4,
			Press = { Grow = 1, Dip = 0.99 },
		}, function()
			local id = g.goal.id
			if claiming[id] then
				return
			end
			claiming[id] = true
			task.spawn(function()
				pcall(function()
					Remotes.fn("GoalClaim"):InvokeServer(id)
				end)
				claiming[id] = nil
			end)
		end)
		claim:SetAttribute("KeepColors", true)
	else
		local count =
			Kit.title(Text.fill("{n} of {need}", { n = Text.commas(g.value), need = Text.commas(g.goal.need) }), {
				Name = "Count",
				Parent = slab,
				Size = UDim2.fromOffset(100, 20),
				Position = UDim2.new(1, -12, 0, 6),
				AnchorPoint = Vector2.new(1, 0),
				TextSize = 14,
				Color = SOFT,
				AlignX = Enum.TextXAlignment.Right,
				Wrap = false,
			})
		count.ZIndex = 3
		-- how far along, a thin bar under the count
		local track = Kit.frame({
			Name = "Track",
			Parent = slab,
			Size = UDim2.fromOffset(92, 5),
			Position = UDim2.new(1, -12, 0, 29),
			AnchorPoint = Vector2.new(1, 0),
			Color = Color3.fromRGB(8, 9, 14),
			Transparency = 0.2,
			Radius = false,
			ZIndex = 3,
		})
		local fill = Kit.frame({
			Name = "Fill",
			Parent = track,
			Size = UDim2.fromScale(math.clamp(g.value / math.max(1, g.goal.need), 0.04, 1), 1),
			Color = T.Yellow,
			Radius = false,
			ZIndex = 4,
		})
		Kit.wash(fill, T.Yellow, T.Orange, 0)
	end
	return slab
end

function Quests.refresh()
	local list = rows
	if not list then
		return
	end
	for _, c in list:GetChildren() do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
	list.Visible = not folded
	local shown = Quests.next(view())
	-- how many are done and waiting, on the header
	local waiting = 0
	for _, g in shown do
		if g.done and not g.claimed then
			waiting += 1
		end
	end
	local chip = readyChip
	if chip then
		chip.Visible = waiting > 0
		local words = chip:FindFirstChild("Count")
		if words and words:IsA("TextLabel") then
			words.Text = tostring(waiting)
		end
	end
	if #shown == 0 then
		local note = Kit.darkPill({ Name = "Done", Parent = list, Size = UDim2.new(1, -12, 0, 36) })
		local words = Kit.text("Every goal is done. Nice work.", {
			Parent = note,
			Size = UDim2.new(1, -24, 1, 0),
			Position = UDim2.fromOffset(12, 0),
			TextSize = 14,
			Color = SOFT,
		})
		words.ZIndex = 3
		return
	end
	for i, g in shown do
		quest(g, i)
	end
end

-- Puts the quests under `parent` at `position`; `open` shows the goals menu.
function Quests.mount(parent: GuiObject, position: UDim2, open: () -> ()): Frame
	onOpen = open
	local frame = Kit.box({
		Name = "Quests",
		Parent = parent,
		Size = UDim2.fromOffset(396, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Position = position,
	})
	Kit.list(frame, 6)
	-- the header: a short leaning tab with the word and a fold arrow
	local head = Kit.new("TextButton", {
		Name = "Header",
		Text = "",
		AutoButtonColor = false,
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(138, 30),
		LayoutOrder = 0,
		Parent = frame,
	})
	-- (from the left edge of the screen, like the rows under it and the stats above)
	local tab = Kit.darkPill({ Name = "Tab", Parent = head, Size = UDim2.fromOffset(138, 30) })
	-- (the name sits flush at the left: no yellow bar in front of it any more)
	local word = Kit.title("Quests", {
		Parent = tab,
		Size = UDim2.new(1, -44, 1, 0),
		Position = UDim2.fromOffset(14, 0),
		TextSize = 17,
		Color = T.White,
		Wrap = false,
	})
	word.ZIndex = 3
	-- a yellow chip with how many are ready to claim
	local chip = Kit.new("Frame", {
		Name = "Ready",
		BackgroundColor3 = T.Yellow,
		BorderSizePixel = 0,
		Size = UDim2.fromOffset(20, 18),
		Position = UDim2.new(0, 80, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		ZIndex = 3,
		Visible = false,
		Parent = tab,
	})
	chip:SetAttribute("KeepColors", true)
	-- a small leaning tag, as every piece with words on it is
	Kit.slant(chip, 18, true)
	Kit.text("", {
		Name = "Count",
		Parent = chip,
		Size = UDim2.fromScale(1, 1),
		TextSize = 13,
		Font = Kit.Fonts.Title,
		Color = T.Dark,
		AlignX = Enum.TextXAlignment.Center,
		Wrap = false,
		ZIndex = 4,
	})
	readyChip = chip
	local arrow = Icons.make("down", 16, {
		Name = "Fold",
		Parent = tab,
		Position = UDim2.new(1, -26, 0.5, -8),
		Color = SOFT,
		Hole = T.Glass,
		ZIndex = 3,
	})
	local list = Kit.box({
		Name = "List",
		Parent = frame,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = 1,
	})
	Kit.list(list, 4)
	rows = list
	root = frame
	head.Activated:Connect(function()
		folded = not folded
		arrow.Rotation = if folded then -90 else 0
		Quests.refresh()
	end)
	-- anything that moves a goal along
	local pending = false
	local function soon()
		if pending then
			return
		end
		pending = true
		task.delay(0.2, function()
			pending = false
			Quests.refresh()
		end)
	end
	for _, key in { "goals", "stats", "villagers", "rel", "coins", "found" } do
		State.on(key, soon)
	end
	State.onPlan(soon)
	Quests.refresh()
	return frame
end

function Quests.root(): Frame?
	return root
end

return Quests
