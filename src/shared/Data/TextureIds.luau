--!strict
-- Roblox image ids for the materials' textures. Most come from the Creator Store (public decals,
-- found with scripts/library_textures.py; `decal` is the decal they came from, the comment its
-- name and maker); the rest can be our painted ones in art/textures once uploaded
-- (scripts/upload_textures.py). Fields: `color` the image, `normal` an optional normal map,
-- `studs` how many studs one copy covers (else Data/Textures' own), `own` when the picture
-- brings its own colour (the part's paint then only tints it lightly).
-- After changing this, run python3 scripts/sync_materials.py to put it in the place.
-- A texture with no colour id here keeps Roblox's own material.

export type Ids = { color: string?, normal: string?, studs: number?, own: boolean?, decal: number? }

local TextureIds: { [string]: Ids } = {
	grass = { color = "rbxassetid://15205950191", studs = 14, own = true, decal = 15205950232 }, -- "grass" by lolacorroblox
	wood = { color = "rbxassetid://127935223360351", studs = 4, decal = 125695710899534 }, -- "Wood Texture" by conoluz
	planks = { color = "rbxassetid://126083643168466", studs = 6, decal = 107218328642902 }, -- "Roblox wood planks texture" by TheDanMan2307
	brick = { color = "rbxassetid://9620643733", studs = 6, decal = 9620643745 }, -- "Sweet_picnic_white-min" by Varzkitt
	cobble = { color = "rbxassetid://10953335350", studs = 6, decal = 10953335360 }, -- "cobblestone paving" by glarpenn
	paving = { color = "rbxassetid://133622340383137", studs = 6, decal = 134144901412773 }, -- "brick" by goatysan
	concrete = { color = "rbxassetid://17528667950", studs = 12, decal = 17528667984 }, -- "Old Concrete Texture" by VastChadJavelin
	asphalt = { color = "rbxassetid://74051293306053", studs = 12, decal = 104048479913484 }, -- "Asphalt texture (worn)" by DaHood_lover123
	plaster = { color = "rbxassetid://7339363282", studs = 8, decal = 7339363321 }, -- "Dry Wall Texture" by hamzahassan6
	clay = { color = "rbxassetid://134089207155554", studs = 6, own = true, decal = 85569311056967 }, -- "T_roof_A_BaseColor" by klairvoiant
	tiles = { color = "rbxassetid://9900590993", studs = 5, decal = 9900591010 }, -- "White tiles" by Vanderpeer
	carpet = { color = "rbxassetid://10538536313", studs = 4, decal = 10538536325 }, -- "Carpet" by attmpt9
	fabric = { color = "rbxassetid://234307070", studs = 3, decal = 234307071 }, -- "Seamless Grey Fabric Texture" by joshman601
	sand = { color = "rbxassetid://95114690737752", studs = 10, decal = 99722758965795 }, -- "Images/Sand_007_basecolor" by GT3RR1
	metal = { color = "rbxassetid://105709811279238", studs = 6, decal = 107449767137487 }, -- "stainless-steel-2500-mm-architextures" by abunda77
}

return TextureIds
