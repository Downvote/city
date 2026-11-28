-- Running. The user: "also, make the ability to run, with shift". Holding either Shift runs at
-- Tuning.Run.Speed, and letting go walks again at the speed the character had. A touch screen has
-- no Shift, so a small round button over the jump button switches running on and off (yellow while
-- on); a gamepad's left stick press does the same. Never in Build mode, at the wheel or in any seat,
-- or while working at a workplace: running stops there, and the switch goes off.
--
-- Roblox's own shift lock is bound to Shift too; it moves to Ctrl here, so a player who has it on
-- doesn't lock the camera every time they run.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Tuning = require(Shared.Config.Tuning)

local Kit = require(script.Parent.Parent.UI.Kit)
local Icons = require(script.Parent.Parent.UI.Icons)

local Run = {}

local K = Tuning.Run
local T = Kit.Theme
local player = Players.LocalPlayer

local held = false -- a Shift is down
local toggled = false -- the touch button (or the gamepad's stick press) is on
local running = false -- the humanoid is at the run's speed now
local walkSpeed: number? = nil -- what it walked at before
local button: TextButton? = nil

local function humanoid(): Humanoid?
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	return if hum and hum.Health > 0 then hum else nil
end

-- May the player run now? Not in Build mode, sitting (a vehicle's seat too) or working.
function Run.allowed(hum: Humanoid?): boolean
	if not hum or hum.Sit or hum.SeatPart ~= nil then
		return false
	end
	local okBuild, BuildMode = pcall(require, script.Parent.Parent.Build.BuildMode)
	if okBuild and (BuildMode :: any).isActive() then
		return false
	end
	local okWork, Work = pcall(require, script.Parent.Work)
	if okWork and (Work :: any).isWorking() then
		return false
	end
	return true
end

-- Is the player running (or set to)?
function Run.isRunning(): boolean
	return running
end

-- The touch button's look: yellow with a dark shoe while on, the glass with a white one while off.
local function paint()
	local b = button
	if not b then
		return
	end
	b.BackgroundColor3 = if toggled then T.Yellow else T.Glass
	b.BackgroundTransparency = if toggled then 0 else T.GlassAlpha
	local art = b:FindFirstChild("Shoe")
	if art then
		Kit.recolorIcon(art, if toggled then T.Dark else T.White, if toggled then T.Yellow else T.Glass)
	end
end

local function setToggled(on: boolean)
	if toggled ~= on then
		toggled = on
		paint()
	end
end
Run.setToggled = setToggled

-- Puts the humanoid at the speed it should have now.
local body: Humanoid? = nil -- the humanoid `running` is about (a new character starts walking)
local function update()
	local hum = humanoid()
	if hum ~= body then
		body = hum
		running = false
		walkSpeed = nil
	end
	local allowed = Run.allowed(hum)
	if not allowed then
		setToggled(false)
	end
	local want = allowed and (held or toggled)
	if not hum then
		running = false
		return
	end
	if want and not running then
		walkSpeed = hum.WalkSpeed
		hum.WalkSpeed = K.Speed
		running = true
	elseif not want and running then
		if hum.WalkSpeed == K.Speed then
			hum.WalkSpeed = walkSpeed or K.Walk
		end
		running = false
	end
end
Run.update = update

local function shift(code: Enum.KeyCode): boolean
	return code == Enum.KeyCode.LeftShift or code == Enum.KeyCode.RightShift
end

-- Roblox's shift lock to Ctrl, where it doesn't fight running (its controller reads this value).
local function moveShiftLock()
	local scripts = player:FindFirstChild("PlayerScripts") or player:WaitForChild("PlayerScripts", 10)
	local module = scripts and scripts:WaitForChild("PlayerModule", 10)
	local camera = module and module:WaitForChild("CameraModule", 10)
	local lock = camera and camera:WaitForChild("MouseLockController", 10)
	local keys = lock and lock:WaitForChild("BoundKeys", 10)
	if keys and keys:IsA("StringValue") and keys.Value:find("Shift") then
		keys.Value = "LeftControl,RightControl"
	end
end

-- The touch button, over Roblox's own jump button (which sits by the bottom right corner, bigger on
-- a bigger screen).
local function makeButton()
	local gui = Instance.new("ScreenGui")
	gui.Name = "RunButton"
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = player:WaitForChild("PlayerGui")
	local b = Kit.roundButton("shoe", { Name = "Run", Size = K.Button, Parent = gui }, function()
		setToggled(not toggled)
		update()
	end)
	local old = b:FindFirstChild("IconArt")
	if old then
		old:Destroy()
	end
	local ipx = math.floor(K.Button * 0.56)
	Icons.make("shoe", ipx, {
		Name = "Shoe",
		Parent = b,
		Position = UDim2.new(0.5, -ipx / 2, 0.5, -ipx / 2),
		Color = T.White,
		Hole = T.Glass,
		Mono = true,
		Centre = true,
	})
	b.AnchorPoint = Vector2.new(0.5, 1)
	local function place()
		local cam = workspace.CurrentCamera
		local view = if cam then cam.ViewportSize else Vector2.new(1280, 720)
		-- (where the jump button is: 70 across 95 in and 90 up on a small screen, 120 across 170
		-- in and 210 up on a big one)
		local small = math.min(view.X, view.Y) <= 500
		local jump = if small then 70 else 120
		local right = if small then 95 else 170
		local up = if small then 90 else 210
		b.Position = UDim2.new(1, -(right - jump / 2), 1, -(up + K.ButtonGap))
	end
	place()
	if workspace.CurrentCamera then
		workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(place)
	end
	button = b
	paint()
	return gui
end

-- Shown on a touch screen while the main screen is (not in Build mode or the creator) and the
-- player can run.
local function showButton()
	local b = button
	if not b then
		return
	end
	local hud = Kit.root():FindFirstChild("Hud")
	local hudUp = hud == nil or not hud:IsA("GuiObject") or hud.Visible
	b.Visible = UserInputService.TouchEnabled and hudUp and Run.allowed(humanoid())
end

function Run.start()
	UserInputService.InputBegan:Connect(function(input)
		if shift(input.KeyCode) then
			if UserInputService:GetFocusedTextBox() == nil then
				held = true
				update()
			end
		elseif input.KeyCode == Enum.KeyCode.ButtonL3 then
			setToggled(not toggled)
			update()
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if shift(input.KeyCode) then
			held = false
			update()
		end
	end)
	pcall(function()
		UserInputService.WindowFocusReleased:Connect(function()
			held = false
			update()
		end)
	end)
	task.spawn(function()
		pcall(moveShiftLock)
	end)
	if UserInputService.TouchEnabled then
		makeButton()
	end
	-- Build mode, a seat or work can start at any time: looked at a few times a second
	task.spawn(function()
		while true do
			task.wait(0.25)
			update()
			showButton()
		end
	end)
end

return Run
