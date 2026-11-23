--!strict
-- The game's own painted textures, one per material: art/textures/<name>.png, painted by
-- scripts/gen_textures.py (the studs per tile here match art/textures/textures.json; the
-- Textures spec checks). A texture shows in game once its picture is uploaded and its id is in
-- Data/TextureIds. Until then the material keeps Roblox's own look.
--
-- Roblox lets only plugins set a MaterialVariant's pictures, so the variants go into the place
-- when it's built: scripts/sync_materials.py writes them, and MaterialService's overrides, into
-- default.project.json. The server still runs `install` when it starts, which sets each
-- material to its variant again. Run from Studio's command bar (which may set the pictures),
-- `install` also makes any variant the place is missing:
--   require(game.ReplicatedStorage.Shared.Data.Textures).install(game:GetService("MaterialService"))

local TextureIds = require(script.Parent.TextureIds)

export type Entry = { name: string, material: string, studs: number }
export type Ready = {
	name: string,
	variant: string,
	material: string,
	studs: number,
	color: string,
	normal: string?,
}

local Textures = {}

Textures.list = {
	{ name = "grass", material = "Grass", studs = 8 },
	{ name = "wood", material = "Wood", studs = 4 },
	{ name = "planks", material = "WoodPlanks", studs = 8 },
	{ name = "brick", material = "Brick", studs = 8 },
	{ name = "cobble", material = "Cobblestone", studs = 8 },
	{ name = "paving", material = "Pavement", studs = 8 },
	{ name = "concrete", material = "Concrete", studs = 12 },
	{ name = "asphalt", material = "Asphalt", studs = 10 },
	{ name = "plaster", material = "Plaster", studs = 10 },
	{ name = "clay", material = "ClayRoofTiles", studs = 6 },
	{ name = "shingles", material = "RoofShingles", studs = 6 },
	{ name = "slate", material = "Slate", studs = 6 },
	{ name = "tiles", material = "CeramicTiles", studs = 4 },
	{ name = "carpet", material = "Carpet", studs = 4 },
	{ name = "fabric", material = "Fabric", studs = 3 },
	{ name = "marble", material = "Marble", studs = 12 },
	{ name = "sand", material = "Sand", studs = 10 },
	{ name = "rock", material = "Rock", studs = 10 },
	{ name = "metal", material = "Metal", studs = 6 },
} :: { Entry }

local ID = "^rbxassetid://%d+$"

-- The textures that have an uploaded picture, ready to become MaterialVariants.
function Textures.ready(ids: { [string]: TextureIds.Ids }?): { Ready }
	local source = ids or TextureIds
	local out = {}
	for _, e in Textures.list do
		local got = source[e.name]
		if got and type(got.color) == "string" and got.color:match(ID) then
			table.insert(out, {
				name = e.name,
				variant = "Maplewick" .. e.name:sub(1, 1):upper() .. e.name:sub(2),
				material = e.material,
				studs = e.studs,
				color = got.color,
				normal = if type(got.normal) == "string" and got.normal:match(ID) then got.normal else nil,
			})
		end
	end
	return out
end

-- Sets each ready texture's material to its MaterialVariant under `materialService`, making the
-- variant first if it's missing (only plugins and the command bar may). Returns how many are on
-- and what went wrong with the rest.
function Textures.install(materialService: any): (number, { string })
	local count, problems = 0, {}
	for _, t in Textures.ready() do
		local ok, err = pcall(function()
			local base = (Enum.Material :: any)[t.material]
			local found = materialService:FindFirstChild(t.variant)
			if not (found and found:IsA("MaterialVariant")) then
				local v = Instance.new("MaterialVariant")
				v.Name = t.variant
				v.BaseMaterial = base
				v.ColorMap = t.color
				if t.normal then
					v.NormalMap = t.normal
				end
				v.StudsPerTile = t.studs
				v.MaterialPattern = Enum.MaterialPattern.Regular
				v.Parent = materialService
			end
			materialService:SetBaseMaterialOverride(base, t.variant)
		end)
		if ok then
			count += 1
		else
			table.insert(problems, t.name .. ": " .. tostring(err))
		end
	end
	return count, problems
end

return Textures
