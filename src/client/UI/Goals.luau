-- The town's goals: what to work toward as the town grows, how far along each one is, and a
-- button to claim the coins for each one that's done.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Remotes = require(Shared.Net.Remotes)
local Life = require(Shared.Sim.Life)
local Text = require(Shared.Util.Text)

local Kit = require(script.Parent.Kit)
local Icons = require(script.Parent.Icons)
local State = require(script.Parent.Parent.Controllers.State)

local Goals = {}

local T = Kit.Theme
local panel: any = nil
local list: ScrollingFrame? = nil

-- A profile-like table from the client state, for Sim/Life.
function Goals.view(): any
	local d = State.data
	return {
		villagers = d.villagers or {},
		rel = d.rel or {},
		stats = d.stats or {},
		goals = d.goals or {},
		plan = State.plan,
		coins = d.coins or 0,
		inv = d.inv or { food = {}, items = {} },
	}
end

-- How many finished goals are waiting to be claimed.
function Goals.ready(): number
	local n = 0
	for _, g in Life.goals(Goals.view()) do
		if g.done and not g.claimed then
			n += 1
		end
	end
	return n
end

local function fill()
	local frame = list
	if not frame then
		return
	end
	for _, c in frame:GetChildren() do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
	for i, g in Life.goals(Goals.view()) do
		local row = Kit.frame({
			Name = g.goal.id,
			Parent = frame,
			Size = UDim2.new(1, -14, 0, 74),
			Color = if g.claimed then T.PaperDark else T.White,
			Radius = 24,
			LayoutOrder = i,
		})
		Icons.make(if g.claimed then "check" else "medal", 40, {
			Parent = row,
			Position = UDim2.new(0, 16, 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5),
			Color = if g.claimed then T.Green else nil,
		})
		Kit.title(g.goal.name, {
			Parent = row,
			Size = UDim2.new(1, -230, 0, 24),
			Position = UDim2.fromOffset(68, 8),
			TextSize = 19,
		})
		Kit.text(g.goal.desc, {
			Parent = row,
			Size = UDim2.new(1, -230, 0, 18),
			Position = UDim2.fromOffset(68, 32),
			TextSize = 14,
			Color = T.InkSoft,
		})
		Kit.bar({
			Parent = row,
			Size = UDim2.new(1, -240, 0, 10),
			Position = UDim2.fromOffset(68, 54),
		}, g.value / g.goal.need, if g.done then T.Green else T.Yellow)
		if g.claimed then
			Kit.text("Done", {
				Parent = row,
				Size = UDim2.fromOffset(140, 30),
				Position = UDim2.new(1, -16, 0.5, 0),
				AnchorPoint = Vector2.new(1, 0.5),
				TextSize = 17,
				Font = Kit.Fonts.Title,
				Color = T.GreenDark,
				AlignX = Enum.TextXAlignment.Right,
			})
		elseif g.done then
			Kit.button(Text.fill("Claim {n}", { n = Text.commas(g.goal.reward) }), {
				Parent = row,
				Size = UDim2.fromOffset(150, 42),
				Position = UDim2.new(1, -14, 0.5, 0),
				AnchorPoint = Vector2.new(1, 0.5),
				Color = T.Green,
				TextSize = 17,
				Radius = "pill",
				Icon = "coin",
			}, function()
				task.spawn(function()
					Remotes.fn("GoalClaim"):InvokeServer(g.goal.id)
				end)
			end)
		else
			Kit.text(Text.fill("{a} of {b}", { a = Text.commas(g.value), b = Text.commas(g.goal.need) }), {
				Parent = row,
				Size = UDim2.fromOffset(140, 30),
				Position = UDim2.new(1, -16, 0.5, 0),
				AnchorPoint = Vector2.new(1, 0.5),
				TextSize = 16,
				Font = Kit.Fonts.Title,
				Color = T.InkSoft,
				AlignX = Enum.TextXAlignment.Right,
			})
		end
	end
end

function Goals.isOpen(): boolean
	return panel ~= nil
end

function Goals.close()
	if panel then
		panel.root:Destroy()
		panel = nil
		list = nil
	end
end

function Goals.open()
	Goals.close()
	panel = Kit.panel("Town goals", UDim2.fromOffset(680, 500), function()
		Goals.close()
	end, "medal", T.Yellow)
	local scroll = Kit.scroll({ Parent = panel.body, Size = UDim2.fromScale(1, 1) })
	Kit.list(scroll, 10, false, Enum.HorizontalAlignment.Center)
	list = scroll
	fill()
	Kit.popIn(panel.root)
end

for _, key in { "goals", "stats", "villagers", "rel", "coins" } do
	State.on(key, function()
		if panel then
			fill()
		end
	end)
end

return Goals
