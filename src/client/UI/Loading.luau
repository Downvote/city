-- What a player sees while the server is still putting the town up. Characters only load once the
-- island is built and the player's plot is ready (server Services/Plots), and before this card a
-- player who joined early saw bare ground and couldn't move (the user: "it spawns me stuck
-- here"). So the screen stays dark with the game's name and a word on what is happening, over
-- the menus' moving shapes, until their character is in the world; then it fades away.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Tuning = require(Shared.Config.Tuning)

local Kit = require(script.Parent.Kit)

local Loading = {}

local T = Kit.Theme

local holder: Frame? = nil

-- The card's words: what the server is doing as far as the client can tell.
Loading.Steps = {
	"Building the town",
	"Getting your plot ready",
	"Nearly there",
}

local function close()
	local h = holder
	if not h then
		return
	end
	holder = nil
	local fade = TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	for _, d in h:GetDescendants() do
		if d:IsA("TextLabel") then
			TweenService:Create(d, fade, { TextTransparency = 1 }):Play()
		end
	end
	TweenService:Create(h, fade, { BackgroundTransparency = 1 }):Play()
	task.delay(0.7, function()
		h:Destroy()
	end)
end

-- `stay` keeps it up whatever happens (the UI previews use it).
function Loading.start(stay: boolean?)
	local player = Players.LocalPlayer
	if player.Character and not stay then
		return
	end
	local gui = Kit.root()
	local h = Kit.new("Frame", {
		Name = "Loading",
		BackgroundColor3 = T.Black,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 1, 80),
		Position = UDim2.fromOffset(0, -80),
		ZIndex = 200,
		Active = true,
		Parent = gui,
	})
	holder = h
	pcall(function()
		local shapes = Kit.motion(h, T.Yellow, 7, { Count = 24 })
		shapes.ZIndex = 200
	end)
	Kit.title(Tuning.Game.Name, {
		Name = "Name",
		Size = UDim2.new(1, 0, 0, 64),
		Position = UDim2.new(0.5, 0, 0.5, -10),
		AnchorPoint = Vector2.new(0.5, 1),
		TextSize = 56,
		AlignX = Enum.TextXAlignment.Center,
		ZIndex = 202,
		Parent = h,
	})
	local step = Kit.text(Loading.Steps[1], {
		Name = "Step",
		Size = UDim2.new(1, 0, 0, 28),
		Position = UDim2.new(0.5, 0, 0.5, 6),
		AnchorPoint = Vector2.new(0.5, 0),
		TextSize = 20,
		Color = T.InkSoft,
		AlignX = Enum.TextXAlignment.Center,
		ZIndex = 202,
		Parent = h,
	})
	-- the words move on with the time waited, and a dot or three after them shows it's alive
	task.spawn(function()
		local started = os.clock()
		while holder == h do
			local waited = os.clock() - started
			local i = if waited < 8 then 1 elseif waited < 20 then 2 else 3
			local dots = string.rep(".", math.floor(waited * 2) % 4)
			step.Text = Loading.Steps[i] .. dots
			task.wait(0.25)
		end
	end)
	if stay then
		return
	end
	player.CharacterAdded:Connect(function()
		task.wait(0.5)
		close()
	end)
	if player.Character then
		close()
	end
end

return Loading
