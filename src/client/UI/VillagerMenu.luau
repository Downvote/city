-- What a click on one of your villagers brings up (client World/VillagerClick). The user: "allow
-- players to click on villagers anywhere to either open their profile or chat with them". So a
-- small glass card at the pointer: their name and two buttons, Profile (their page
-- in the Villagers menu) and Chat (the talk card: the server starts the chat from anywhere on your
-- own plot and holds it while you stay about where you stood). It goes on a pick, a click anywhere
-- else, Escape, when another menu opens (it is a Hud panel) or when they move out.
--
-- Hud.open("VillagerMenu", { vid = vid, at = Vector2 }) opens it; `at` is the pointer in the
-- interface's own pixels (InputObject.Position).

local UserInputService = game:GetService("UserInputService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Remotes = require(Shared.Net.Remotes)

local Kit = require(script.Parent.Kit)
local Toasts = require(script.Parent.Toasts)
local State = require(script.Parent.Parent.Controllers.State)

local VillagerMenu = {}

local T = Kit.Theme
local W, H = 232, 102 -- the card
local GAP = 14 -- from the pointer

local card: Frame? = nil
local current: string? = nil
local serial = 0
local unbind: { () -> () } = {}

function VillagerMenu.isOpen(): boolean
	return card ~= nil and card.Parent ~= nil
end

function VillagerMenu.close()
	serial += 1
	current = nil
	for _, off in unbind do
		off()
	end
	table.clear(unbind)
	if card then
		card:Destroy()
		card = nil
	end
end

-- Where the card goes: beside the pointer, kept on the screen (in the root's own units: it is
-- scaled by its UIScale).
local function place(at: Vector2): UDim2
	local root = Kit.root()
	local scale = root:FindFirstChild("Scale")
	local k = if scale and scale:IsA("UIScale") and scale.Scale > 0 then scale.Scale else 1
	local cam = workspace.CurrentCamera
	local view = if cam then cam.ViewportSize else Vector2.new(1280, 720)
	local sw, sh = view.X / k, view.Y / k
	local x, y = at.X / k + GAP, at.Y / k + GAP
	if x + W > sw - 8 then
		x = at.X / k - GAP - W
	end
	if y + H > sh - 8 then
		y = at.Y / k - GAP - H
	end
	return UDim2.fromOffset(math.max(8, math.floor(x)), math.max(8, math.floor(y)))
end

-- Chat: the server starts it (from anywhere on your plot) and the talk card shows what they say.
local function chat(vid: string)
	task.spawn(function()
		local sent, ok, said = pcall(function()
			return Remotes.fn("VillagerTalk"):InvokeServer(vid, "click")
		end)
		if sent and ok and type(said) == "table" then
			local TalkCard = require(script.Parent.TalkCard) :: any
			TalkCard.show(said)
		elseif sent and type(said) == "string" and said ~= "" then
			Toasts.show(said, "warn")
		end
	end)
end

-- arg: { vid, at }
function VillagerMenu.open(arg: any)
	VillagerMenu.close()
	local vid = type(arg) == "table" and arg.vid
	local v = type(vid) == "string" and State.villager(vid)
	if not v then
		return
	end
	local at = if type(arg) == "table" and typeof(arg.at) == "Vector2" then arg.at else Vector2.new(640, 360)
	current = vid
	local mine = serial
	local f = Kit.glass({
		Name = "VillagerMenu",
		Parent = Kit.root(),
		Size = UDim2.fromOffset(W, H),
		Position = place(at),
		Radius = 16,
		ZIndex = 40,
	})
	card = f
	-- their name, flush at the left
	local name = Kit.title(v.name, {
		Name = "Name",
		Parent = f,
		Size = UDim2.new(1, -32, 0, 24),
		Position = UDim2.fromOffset(16, 12),
		TextSize = 20,
		Color = T.Ink,
		Wrap = false,
		ZIndex = 41,
	})
	name.TextTruncate = Enum.TextTruncate.AtEnd
	local row = Kit.box({
		Name = "Choices",
		Parent = f,
		Size = UDim2.new(1, -28, 0, 40),
		Position = UDim2.fromOffset(14, 48),
		ZIndex = 41,
	})
	Kit.list(row, 8, true)
	Kit.button("Profile", {
		Name = "Profile",
		Parent = row,
		Size = UDim2.fromOffset(98, 40),
		Color = T.Blue,
		TextSize = 17,
		LayoutOrder = 1,
		ZIndex = 42,
	}, function()
		VillagerMenu.close()
		local Hud = require(script.Parent.Hud) :: any
		Hud.open("Residents", vid)
	end)
	Kit.button("Chat", {
		Name = "Chat",
		Parent = row,
		Size = UDim2.fromOffset(98, 40),
		Color = T.Green,
		TextSize = 17,
		LayoutOrder = 2,
		ZIndex = 42,
	}, function()
		VillagerMenu.close()
		chat(vid)
	end)
	-- a press anywhere else, or Escape, puts it away
	local pressed = UserInputService.InputBegan:Connect(function(input: InputObject)
		if serial ~= mine then
			return
		end
		if input.KeyCode == Enum.KeyCode.Escape then
			VillagerMenu.close()
			return
		end
		local press = input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.MouseButton2
			or input.UserInputType == Enum.UserInputType.Touch
		if press and card then
			local p, s = card.AbsolutePosition, card.AbsoluteSize
			local x, y = input.Position.X, input.Position.Y
			if x < p.X or y < p.Y or x > p.X + s.X or y > p.Y + s.Y then
				VillagerMenu.close()
			end
		end
	end)
	table.insert(unbind, function()
		pressed:Disconnect()
	end)
	-- and so does their moving out
	table.insert(
		unbind,
		State.on("villagers", function()
			if serial == mine and current and not State.villager(current) then
				VillagerMenu.close()
			end
		end)
	)
end

return VillagerMenu
