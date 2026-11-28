--!strict
-- Background blur. The user: "also, add background blur". World.stylize puts a DepthOfFieldEffect
-- named Lens on Lighting; this keeps it focused on what the camera is looking at (you, or your
-- plot in Build mode), on this player's own screen, so the near things stay sharp and the town
-- behind goes soft. The sharp zone grows with the camera's distance, so a far Build mode view of
-- the plot isn't blurred.

local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Tuning = require(Shared.Config.Tuning)

local Focus = {}

-- How far off the camera focuses and how deep the sharp zone round that is, for a camera this
-- many studs from what it looks at.
function Focus.lens(distance: number): (number, number)
	local lens = Tuning.Look.Lens
	local d = math.max(distance, 1)
	return d, math.max(lens.InFocusRadius, d * lens.Reach)
end

function Focus.start()
	local focus, radius = Tuning.Look.Lens.FocusDistance, Tuning.Look.Lens.InFocusRadius
	RunService.RenderStepped:Connect(function(dt)
		local lens = Lighting:FindFirstChild("Lens")
		local camera = workspace.CurrentCamera
		-- (off when the player turned the blur off: World/Graphics)
		if not (lens and lens:IsA("DepthOfFieldEffect") and camera and lens.Enabled) then
			return
		end
		local wantFocus, wantRadius = Focus.lens((camera.CFrame.Position - camera.Focus.Position).Magnitude)
		-- eased, so a camera pulled in or out doesn't snap the blur
		local k = 1 - math.exp(-Tuning.Look.Lens.Ease * dt)
		focus += (wantFocus - focus) * k
		radius += (wantRadius - radius) * k
		lens.FocusDistance = focus
		lens.InFocusRadius = radius
	end)
end

return Focus
