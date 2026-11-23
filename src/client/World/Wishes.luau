-- A thought bubble over every villager with a wish (the server marks their model's "Wish"
-- attribute with the wish's icon): a bubble with the icon in it, two little dots under it, and a
-- click opens their page to see what they want. A craving shows the very thing they crave, which
-- the player can buy for them from their page (the Villagers screen) or by talking to them.

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Foods = require(Shared.Data.Foods)
local Colors = require(Shared.Util.Colors)

local Kit = require(script.Parent.Parent.UI.Kit)
local Icons = require(script.Parent.Parent.UI.Icons)
local State = require(script.Parent.Parent.Controllers.State)

local Wishes = {}

local T = Kit.Theme
local bubbles: { [Model]: BillboardGui } = {}

local function clear(model: Model)
	local b = bubbles[model]
	if b then
		b:Destroy()
		bubbles[model] = nil
	end
end

local function show(model: Model, icon: string)
	clear(model)
	local player = Players.LocalPlayer
	local gui = player:FindFirstChild("PlayerGui")
	local head = model:FindFirstChild("Head") or model.PrimaryPart
	if not gui or not head then
		return
	end
	local bb = Instance.new("BillboardGui")
	bb.Name = "WishBubble"
	bb.Adornee = head :: BasePart
	bb.Size = UDim2.fromOffset(78, 92)
	bb.StudsOffset = Vector3.new(0, 3.4, 0)
	bb.AlwaysOnTop = true
	bb.ResetOnSpawn = false
	bb.MaxDistance = 140
	bb.Active = true
	local holder = Kit.blob({
		Parent = bb,
		Round = true,
		Color = T.Paper,
		Size = UDim2.fromOffset(68, 68),
		Position = UDim2.fromOffset(5, 0),
	})
	-- what they crave, if it's a craving; otherwise the wish's own icon
	local vid = model:GetAttribute("Vid")
	local v = if type(vid) == "string" then State.villager(vid) else nil
	local food = v and v.wish and v.wish.kind == "food" and Foods.get(v.wish.arg)
	if food then
		Icons.item(food.id, 44, Colors.fromHex(food.color), {
			Parent = holder,
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			ZIndex = 3,
		})
	else
		Icons.make(icon, 36, {
			Parent = holder,
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			ZIndex = 3,
			Color = T.Orange,
		})
	end
	-- the thought bubble's little dots
	for k, d in { 14, 9 } do
		Kit.frame({
			Parent = bb,
			Size = UDim2.fromOffset(d, d),
			Position = UDim2.fromOffset(28 - k * 4, 66 + k * 9),
			Color = T.Paper,
			Radius = "circle",
		})
	end
	local button = Kit.new("TextButton", {
		Text = "",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 5,
		Parent = bb,
	})
	button.Activated:Connect(function()
		local vid = model:GetAttribute("Vid")
		if type(vid) == "string" then
			local Hud = require(script.Parent.Parent.UI.Hud)
			Hud.open("Residents", vid)
		end
	end)
	Kit.wobbly(holder, 4)
	bb.Parent = gui
	bubbles[model] = bb
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
