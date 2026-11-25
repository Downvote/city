-- A bubble over every villager with a wish (the server marks their model's "Wish" attribute with
-- the wish's icon): the icon on a square of dark glass with a tail toward their head. A craving
-- shows the very thing they crave. A click brings up a small popup (UI/WishPopup) that says what
-- they want and answers it there: the user, "clicking the bubble that appears above villagers
-- when they have a craving should show a popup what they want and allow the player to satisfy it
-- instead of their whole profile page". Their page (the Villagers screen) and the talk card can
-- still do it too.

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Foods = require(Shared.Data.Foods)
local Colors = require(Shared.Util.Colors)

local Bubble = require(Shared.Util.Bubble)

local Kit = require(script.Parent.Parent.UI.Kit)
local Icons = require(script.Parent.Parent.UI.Icons)
local State = require(script.Parent.Parent.Controllers.State)
local Bubbles = require(script.Parent.Bubbles)

local Wishes = {}

local T = Kit.Theme
local bubbles: { [Model]: BillboardGui } = {}

local function clear(model: Model)
	local b = bubbles[model]
	if b then
		Bubbles.dismiss(b) -- (it pops out first)
		bubbles[model] = nil
	end
end

-- The wish bubble's look: a square of the dark glass with an orange rim (a craving's rim is
-- yellow), the thing they want in it, small corner brackets and a tail toward their head
-- (Util/Bubble, as the speech cards and the mood badges are). Returns the group.
function Wishes.face(parent: Instance?, icon: string, food: any?): CanvasGroup
	local g, card = Bubble.square(parent, 60, if food then T.Yellow else T.Orange)
	if food then
		Icons.item(food.id, 46, Colors.fromHex(food.color), {
			Parent = card,
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			ZIndex = 3,
			Centre = true,
		})
	else
		Icons.make(icon, 42, {
			Parent = card,
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			ZIndex = 3,
			Color = T.Orange,
			Hole = T.Glass,
			Centre = true,
		})
	end
	return g
end

local function show(model: Model, icon: string)
	clear(model)
	local player = Players.LocalPlayer
	local gui = player:FindFirstChild("PlayerGui")
	local head = model:FindFirstChild("Head") or model.PrimaryPart
	if not gui or not head or not head:IsA("BasePart") then
		return
	end
	-- hung from the same point as the speech card and the mood badges, which World/Bubbles
	-- stacks it over; it hides it while a wall is in the way
	local bb = Bubble.billboard("WishBubble", head, 90, 140)
	bb.Active = true
	-- what they crave, if it's a craving; otherwise the wish's own icon
	local vid = model:GetAttribute("Vid")
	local v = if type(vid) == "string" then State.villager(vid) else nil
	local food = v and v.wish and v.wish.kind == "food" and Foods.get(v.wish.arg)
	local g = Wishes.face(bb, icon, food or nil)
	-- a click on it brings up what they want, to answer it there
	local button = Kit.new("TextButton", {
		Name = "Open",
		Text = "",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 5,
		Parent = g:FindFirstChild("Card"),
	})
	Kit.press(button, { Kind = "plain", Face = false, Grow = 1 })
	button.Activated:Connect(function()
		local id = model:GetAttribute("Vid")
		if type(id) == "string" then
			local Hud = require(script.Parent.Parent.UI.Hud)
			Hud.open("WishPopup", id)
		end
	end)
	bb.Parent = gui
	bubbles[model] = bb
	Bubbles.track(model, bb)
end

local refreshers: { [Model]: () -> () } = {}

local function watch(model: Model)
	local function refresh()
		local icon = model:GetAttribute("Wish")
		if type(icon) == "string" and model.Parent then
			show(model, icon)
		else
			clear(model)
		end
	end
	refreshers[model] = refresh
	model:GetAttributeChangedSignal("Wish"):Connect(refresh)
	model.AncestryChanged:Connect(function()
		if not model.Parent then
			clear(model)
			refreshers[model] = nil
		end
	end)
	refresh()
end

function Wishes.start()
	-- the loop that stacks the bubbles over every head and hides them behind walls
	Bubbles.start()
	-- a new craving (or one bought) shows on the bubbles as soon as the client hears of it
	State.on("villagers", function()
		for _, refresh in refreshers do
			refresh()
		end
	end)
	local seen: { [Model]: boolean } = {}
	task.spawn(function()
		while true do
			local plots = workspace:FindFirstChild("Plots")
			if plots then
				for _, plot in plots:GetChildren() do
					local folder = plot:FindFirstChild("Villagers")
					if folder then
						for _, m in folder:GetChildren() do
							if m:IsA("Model") and not seen[m] and m:GetAttribute("Vid") then
								seen[m] = true
								watch(m)
							end
						end
					end
				end
			end
			for m in seen do
				if not m.Parent then
					seen[m] = nil
				end
			end
			task.wait(1.5)
		end
	end)
end

return Wishes
