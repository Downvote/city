-- What a player sees while the server is still putting the town up. Characters only load once the
-- island is built and the player's plot is ready (server Services/Plots), and before this card a
-- player who joined early saw bare ground and couldn't move (the user: "it spawns me stuck
-- here"). So the screen stays dark with the game's name and a word on what is happening, over
-- the menus' moving shapes, until their character is in the world; then it fades away.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Tuning = require(Shared.Config.Tuning)
local Remotes = require(Shared.Net.Remotes)

local Kit = require(script.Parent.Kit)

local Loading = {}

local T = Kit.Theme

local holder: Frame? = nil

-- With no body after this many seconds the card asks the server for one, and again every few.
Loading.AskAfter = 20
Loading.AskEvery = 8

-- What the server is doing as far as the client can tell: starting up, then getting this
-- player in (workspace "Startup" and the player's "Arrival", set by World, Data and Plots).
function Loading.say(): string
	local startup = workspace:GetAttribute("Startup")
	if type(startup) ~= "string" or startup == "" then
		return "Building the town"
	end
	if startup ~= "Ready" then
		return startup
	end
	local arrival = Players.LocalPlayer:GetAttribute("Arrival")
	if type(arrival) == "string" and arrival ~= "" and not string.find(arrival, "^Couldn't") then
		return arrival
	end
	return "Getting you in"
end

-- Something that went wrong on the way, or "".
function Loading.problem(): string
	local err = workspace:GetAttribute("StartupError")
	if type(err) == "string" and err ~= "" then
		return err
	end
	local arrival = Players.LocalPlayer:GetAttribute("Arrival")
	if type(arrival) == "string" and string.find(arrival, "^Couldn't") then
		return arrival
	end
	return ""
end

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
		local shapes = Kit.motion(h, T.Yellow, 7, { Count = 20 })
		shapes.ZIndex = 200
	end)
	-- the name big at the bottom left, a rule in yellow under it and what the server is doing under
	-- that, all flush left (it was a title and a line in the middle of the black)
	local LEFT = 64
	Kit.caption("Loading", {
		Name = "Caption",
		Size = UDim2.fromOffset(300, 16),
		Position = UDim2.new(0, LEFT + 2, 1, -196),
		TextSize = 12,
		ZIndex = 202,
		Parent = h,
	})
	Kit.title(Tuning.Game.Name, {
		Name = "Name",
		Size = UDim2.new(1, -LEFT * 2, 0, 72),
		Position = UDim2.new(0, LEFT, 1, -176),
		TextSize = 64,
		Wrap = false,
		ZIndex = 202,
		Parent = h,
	})
	Kit.rule({
		Name = "Rule",
		Parent = h,
		Size = UDim2.fromOffset(380, 6),
		Position = UDim2.new(0, LEFT + 2, 1, -100),
		AnchorPoint = Vector2.new(0, 0.5),
		Color = T.Line,
		Accent = T.Yellow,
		AccentLength = 48,
		ZIndex = 202,
	})
	local step = Kit.text(Loading.say(), {
		Name = "Step",
		Size = UDim2.new(1, -LEFT * 2, 0, 28),
		Position = UDim2.new(0, LEFT + 2, 1, -88),
		TextSize = 20,
		Color = T.InkSoft,
		ZIndex = 202,
		Parent = h,
	})
	-- what went wrong, if the server says something did (so a stuck start says why)
	local problem = Kit.text("", {
		Name = "Problem",
		Size = UDim2.new(0.6, 0, 0, 48),
		Position = UDim2.new(0, LEFT + 2, 1, -56),
		TextSize = 16,
		Tint = T.Red,
		AlignY = Enum.TextYAlignment.Top,
		ZIndex = 202,
		Parent = h,
	})
	-- a band of hatching in the bottom right corner, in yellow
	local band = Kit.hatch({
		Name = "Hatch",
		Parent = h,
		Size = UDim2.fromOffset(220, 14),
		Position = UDim2.new(1, -LEFT, 1, -96),
		AnchorPoint = Vector2.new(1, 0.5),
		Color = T.Yellow,
		Transparency = 0.4,
		Fade = "left",
		ZIndex = 201,
	})
	if band then
		band:SetAttribute("KeepColors", true)
	end
	-- the words follow what the server is doing, with a dot or three after them to show it's
	-- alive; with no body after a while the card asks the server for one, now and then
	task.spawn(function()
		local started = os.clock()
		local asked = 0
		while holder == h do
			local waited = os.clock() - started
			if not stay and Players.LocalPlayer.Character then
				close() -- (in case the character came without the card hearing of it)
				break
			end
			step.Text = Loading.say() .. string.rep(".", math.floor(waited * 2) % 4)
			problem.Text = Loading.problem()
			if not stay and waited > Loading.AskAfter and os.clock() - asked > Loading.AskEvery then
				asked = os.clock()
				task.spawn(function()
					pcall(function()
						Remotes.fn("SpawnMe"):InvokeServer()
					end)
				end)
			end
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
