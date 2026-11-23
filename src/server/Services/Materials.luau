-- Puts the game's painted textures on its materials when the server starts (Data/Textures): each
-- uploaded texture's MaterialVariant, built into the place, set as its material's look.

local MaterialService = game:GetService("MaterialService")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Textures = require(Shared.Data.Textures)

local Materials = {}

function Materials.init()
	local count, problems = Textures.install(MaterialService)
	if count > 0 then
		print(string.format("[Maplewick] %d painted textures on", count))
	end
	for _, p in problems do
		warn("[Maplewick] texture not set (run python3 scripts/sync_materials.py and build again), " .. p)
	end
end

return Materials
