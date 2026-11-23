--!strict
-- Ink outlines on people. The user: "stylize everything ... Make shaders, new models and
-- textures if necessary". A drawn character has a dark line round them, and Roblox can draw
-- one: a Highlight with no fill and a dark outline. It can only show about thirty of them at
-- once, and Build mode uses a few for what you have picked, so only the nearest people to the
-- camera wear one: you, the other players and the villagers. All on this player's own screen.

local Players = game:GetService("Players")

local Outlines = {}

Outlines.Name = "Ink"
Outlines.Most = 20 -- how many people are outlined at once
Outlines.Reach = 170 -- studs from the camera
Outlines.Color = Color3.fromRGB(24, 22, 34)

-- where a person is, or nil if they have no body yet
local function whereIs(model: Model): Vector3?
	local root = model:FindFirstChild("HumanoidRootPart")
		or model.PrimaryPart
		or model:FindFirstChildWhichIsA("BasePart")
	if root and root:IsA("BasePart") then
		return root.CFrame.Position
	end
	return nil
end

-- Everyone who could wear an outline: players' characters and the villagers on every plot.
function Outlines.people(): { Model }
	local out: { Model } = {}
	for _, player in Players:GetPlayers() do
		local char = player.Character
		if char then
			table.insert(out, char)
		end
	end
	local plots = workspace:FindFirstChild("Plots")
	if plots then
		for _, plot in plots:GetChildren() do
			local folder = plot:FindFirstChild("Villagers")
			if folder then
				for _, m in folder:GetChildren() do
					if m:IsA("Model") and m:GetAttribute("Vid") ~= nil then
						table.insert(out, m)
					end
				end
			end
		end
	end
	return out
end

-- Gives the nearest people their outline and takes it off the rest. `from` is where to measure
-- from (the camera). Returns how many are outlined.
function Outlines.step(from: Vector3): number
	local near: { { model: Model, d: number } } = {}
	local all = Outlines.people()
	for _, model in all do
		local at = whereIs(model)
		if at then
			local d = (at - from).Magnitude
			if d <= Outlines.Reach then
				table.insert(near, { model = model, d = d })
			end
		end
	end
	table.sort(near, function(a, b)
		return a.d < b.d
	end)
	local keep: { [Model]: boolean } = {}
	for i = 1, math.min(#near, Outlines.Most) do
		keep[near[i].model] = true
	end
	local count = 0
	for _, model in all do
		local ink = model:FindFirstChild(Outlines.Name)
		if keep[model] then
			count += 1
			if not ink then
				local h = Instance.new("Highlight")
				h.Name = Outlines.Name
				h.FillTransparency = 1
				h.OutlineColor = Outlines.Color
				h.OutlineTransparency = 0
				h.DepthMode = Enum.HighlightDepthMode.Occluded
				h.Adornee = model
				h.Parent = model
			end
		elseif ink then
			ink:Destroy()
		end
	end
	return count
end

function Outlines.start()
	task.spawn(function()
		while true do
			local cam = workspace.CurrentCamera
			if cam then
				Outlines.step(cam.CFrame.Position)
			end
			task.wait(0.4)
		end
	end)
end

return Outlines
