-- Notices when this player walks up to a place they haven't found yet (Data/Places) and tells
-- the server, which checks and pays out.

local Players = game:GetService("Players")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Places = require(Shared.Data.Places)
local Remotes = require(Shared.Net.Remotes)

local State = require(script.Parent.Parent.Controllers.State)

local Explore = {}

function Explore.start()
	local asked: { [string]: number } = {}
	task.spawn(function()
		while true do
			task.wait(0.6)
			local char = Players.LocalPlayer.Character
			local root = char and char:FindFirstChild("HumanoidRootPart")
			local found = State.data.found or {}
			if root and root:IsA("BasePart") then
				for _, place in Places.list do
					if not found[place.id] and Places.near(place, root.Position) then
						local last = asked[place.id]
						if not last or os.clock() - last > 5 then
							asked[place.id] = os.clock()
							task.spawn(function()
								Remotes.fn("PlaceFound"):InvokeServer(place.id)
							end)
						end
					end
				end
			end
		end
	end)
end

return Explore
