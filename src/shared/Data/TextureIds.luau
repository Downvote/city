--!strict
-- Roblox image ids for the painted textures in art/textures, once they're uploaded. One entry per
-- texture name from Data/Textures: `color` for <name>.png, `normal` for <name>_n.png (optional).
-- scripts/upload_textures.py fills this in; after a Studio bulk import, paste the ids by hand:
--   grass = { color = "rbxassetid://123", normal = "rbxassetid://456" },
-- then run python3 scripts/sync_materials.py to put them in the place.
-- A texture with no colour id here keeps Roblox's own material.

export type Ids = { color: string?, normal: string? }

local TextureIds: { [string]: Ids } = {}

return TextureIds
