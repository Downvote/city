-- A click (or a tap) on one of your own villagers, however far off. The user: "allow players to
-- click on villagers anywhere to either open their profile or chat with them". A short press that
-- hardly moved (not a drag of the camera) and wasn't on the interface looks out from the camera
-- (Tuning.TalkClick.Reach); when the first thing it meets is part of a villager in this player's
-- own plot, UI/VillagerMenu comes up at the pointer with Profile and Chat. Nothing happens in
-- Build mode, in the creator, while a menu or an event's scene is up, or on anybody else's villagers.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Tuning = require(Shared.Config.Tuning)

local Kit = require(script.Parent.Parent.UI.Kit)

local VillagerClick = {}

local K = Tuning.TalkClick
local player = Players.LocalPlayer

-- This player's own villagers' folder.
local function myFolder(): Instance?
	local index = player:GetAttribute("Plot")
	local plots = workspace:FindFirstChild("Plots")
	local plot = plots and index and plots:FindFirstChild("Plot" .. tostring(index))
	return plot and plot:FindFirstChild("Villagers")
end

-- The villager (their id) whose body is the first thing under this point of the screen, if they
-- are one of this player's own.
function VillagerClick.villagerAt(at: Vector2): string?
	local cam = workspace.CurrentCamera
	local folder = myFolder()
	if not cam or not folder then
		return nil
	end
	local ray = cam:ScreenPointToRay(at.X, at.Y)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = if player.Character then { player.Character } else {}
	params.IgnoreWater = true
	local hit = workspace:Raycast(ray.Origin, ray.Direction * K.Reach, params)
	local model = hit and hit.Instance:FindFirstAncestorOfClass("Model")
	while model and model.Parent ~= folder do
		model = model:FindFirstAncestorOfClass("Model")
	end
	local vid = model and model:GetAttribute("Vid")
	return if type(vid) == "string" then vid else nil
end

-- Does something else have the screen: Build mode, the creator, a menu, an event's scene?
local function busy(at: Vector2): boolean
	local BuildMode = require(script.Parent.Parent.Build.BuildMode) :: any
	if BuildMode.isActive() then
		return true
	end
	local EventCard = require(script.Parent.Parent.UI.EventCard) :: any
	if EventCard.isWatching() then
		return true
	end
	local gui = Kit.root()
	local creator = gui:FindFirstChild("Creator")
	if creator and creator:IsA("GuiObject") and creator.Visible then
		return true
	end
	for _, child in gui:GetChildren() do
		if child:IsA("GuiObject") and child.Visible and child:FindFirstChild("Dim") then
			return true
		end
	end
	-- (what is under the pointer is the interface's: the engine said so already, this is in case)
	local inset = game:GetService("GuiService"):GetGuiInset()
	return Kit.overUI(at + inset)
end

function VillagerClick.start()
	local down: { pos: Vector2, t: number }? = nil
	UserInputService.InputBegan:Connect(function(input: InputObject, processed: boolean)
		local kind = input.UserInputType
		if kind ~= Enum.UserInputType.MouseButton1 and kind ~= Enum.UserInputType.Touch then
			return
		end
		down = if processed then nil else { pos = Vector2.new(input.Position.X, input.Position.Y), t = os.clock() }
	end)
	UserInputService.InputEnded:Connect(function(input: InputObject, processed: boolean)
		local kind = input.UserInputType
		if kind ~= Enum.UserInputType.MouseButton1 and kind ~= Enum.UserInputType.Touch then
			return
		end
		local d = down
		down = nil
		if processed or not d then
			return
		end
		local at = Vector2.new(input.Position.X, input.Position.Y)
		if os.clock() - d.t > K.Tap or (at - d.pos).Magnitude > K.Slack or busy(at) then
			return
		end
		local vid = VillagerClick.villagerAt(at)
		if vid then
			local Hud = require(script.Parent.Parent.UI.Hud) :: any
			Hud.open("VillagerMenu", { vid = vid, at = at })
		end
	end)
end

return VillagerClick
