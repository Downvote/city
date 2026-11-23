-- The painted textures on this player's screen too: the server makes the MaterialVariants (see
-- Data/Textures); once each one arrives, it's set as its material's look here as well.

local MaterialService = game:GetService("MaterialService")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Textures = require(Shared.Data.Textures)

local Materials = {}

function Materials.start()
	for _, t in Textures.ready() do
		task.spawn(function()
			local v = MaterialService:WaitForChild(t.variant, 20)
			if v then
				pcall(function()
					MaterialService:SetBaseMaterialOverride((Enum.Material :: any)[t.material], t.variant)
				end)
			end
		end)
	end
end

return Materials
