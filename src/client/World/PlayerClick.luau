-- A click (or a tap) on another player's character. The user: "Allow clicking on other players to
-- open an interface to view their profile and like their plot, add trusted". As with a villager
-- (World/VillagerClick): a short press that hardly moved and wasn't on the interface looks out from
-- the camera, and when the first thing it meets is part of somebody else's character,
-- UI/PlayerMenu comes up at the pointer with their card. Nothing happens in Build mode, the
-- creator, a menu or an event's scene.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Tuning = require(Shared.Config.Tuning)

local VillagerClick = require(script.Parent.VillagerClick)

local PlayerClick = {}

local K = Tuning.TalkClick
local player = Players.LocalPlayer

-- The other player (their user id) whose character is the first thing under this point.
function PlayerClick.playerAt(at: Vector2): number?
	local cam = workspace.CurrentCamera
	if not cam then
		return nil
	end
	local ray = cam:ScreenPointToRay(at.X, at.Y)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = if player.Character then { player.Character } else {}
	params.IgnoreWater = true
	local hit = workspace:Raycast(ray.Origin, ray.Direction * K.Reach, params)
	local model = hit and hit.Instance:FindFirstAncestorOfClass("Model")
	while model do
		local who = Players:GetPlayerFromCharacter(model)
		if who then
			return if who ~= player then who.UserId else nil
		end
		model = model:FindFirstAncestorOfClass("Model")
	end
	return nil
end

function PlayerClick.start()
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
		if os.clock() - d.t > K.Tap or (at - d.pos).Magnitude > K.Slack or VillagerClick.busy(at) then
			return
		end
		local id = PlayerClick.playerAt(at)
		if id then
			local Hud = require(script.Parent.Parent.UI.Hud) :: any
			Hud.open("PlayerMenu", { id = id, at = at })
		end
	end)
end

return PlayerClick
