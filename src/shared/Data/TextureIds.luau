--!strict
-- Roblox image ids for the materials' textures. Most come from the Creator Store (public decals,
-- found with scripts/library_textures.py; `decal` is the decal they came from, the comment its
-- name and maker); the rest can be our painted ones in art/textures once uploaded
-- (scripts/upload_textures.py). Fields: `color` the image, `normal` an optional normal map
-- (OpenGL style, the kind Roblox reads) and `rough` an optional roughness map, both from the same
-- set as the colour where the picture has a pattern (bricks, cobbles, tiles), `studs` how many
-- studs one copy covers (else Data/Textures' own), `own` when the picture brings its own colour
-- (the part's paint then only tints it lightly).
-- After changing this, run python3 scripts/sync_materials.py to put it in the place.
-- A texture with no colour id here keeps Roblox's own material. One texture a line: the scripts
-- and the preview read this file line by line.

export type Ids = { color: string?, normal: string?, rough: string?, studs: number?, own: boolean?, decal: number? }

-- stylua: ignore
local TextureIds: { [string]: Ids } = {
	grass = { color = "rbxassetid://83472971555269", normal = "rbxassetid://74383676401444", rough = "rbxassetid://123781418381440", studs = 16, own = true, decal = 116948360871196 }, -- "Grass005_2K-JPG_Color", "_NormalGL" and "_Roughness" by gabrieleivazians2041
	wood = { color = "rbxassetid://127935223360351", normal = "rbxassetid://82700223149662", studs = 4, decal = 125695710899534 }, -- "Wood Texture" by conoluz; normal "Wood092_1K-PNG_NormalGL" by Proville6
	planks = { color = "rbxassetid://126083643168466", studs = 6, decal = 107218328642902 }, -- "Roblox wood planks texture" by TheDanMan2307
	brick = { color = "rbxassetid://15826262054", normal = "rbxassetid://15826267601", studs = 8, decal = 15826262079 }, -- "brick color" and "brick normal" by latechicagonightz
	cobble = { color = "rbxassetid://79170514243126", normal = "rbxassetid://135713644746103", studs = 8, decal = 109103115932604 }, -- "PavingStones005_2K-JPG_Color" and "_NormalGL" by PixBay_YT
	paving = { color = "rbxassetid://133622340383137", studs = 6, decal = 134144901412773 }, -- "brick" by goatysan
	concrete = { color = "rbxassetid://17528667950", normal = "rbxassetid://10266817549", studs = 12, decal = 17528667984 }, -- "Old Concrete Texture" by VastChadJavelin; normal "concrete_floor_02_nor_gl_2k" by Chrn_E
	asphalt = { color = "rbxassetid://74051293306053", normal = "rbxassetid://11226165423", studs = 12, decal = 104048479913484 }, -- "Asphalt texture (worn)" by DaHood_lover123; normal "asphalt_01_nor_gl_1k" by dorndaft
	plaster = { color = "rbxassetid://7339363282", normal = "rbxassetid://5437994223", studs = 8, decal = 7339363321 }, -- "Dry Wall Texture" by hamzahassan6; normal "Concrete_Wall_Nor" from the library
	clay = { color = "rbxassetid://134089207155554", normal = "rbxassetid://125979461216252", studs = 6, own = true, decal = 85569311056967 }, -- "T_roof_A_BaseColor" and "T_roof_A_Normal" by klairvoiant
	tiles = { color = "rbxassetid://15246763549", normal = "rbxassetid://12477337856", studs = 6, decal = 15246763593 }, -- "Tiles107_2K-PNG_Color" by mycardgo; normal "Tiles107_2K_NormalGL" by Omair1962
	carpet = { color = "rbxassetid://10538536313", normal = "rbxassetid://108650587944937", studs = 4, decal = 10538536325 }, -- "Carpet" by attmpt9; normal "Carpet Normal Map" by Bunniekell
	fabric = { color = "rbxassetid://234307070", normal = "rbxassetid://83181758798164", studs = 3, decal = 234307071 }, -- "Seamless Grey Fabric Texture" by joshman601; normal "Fabric Normal Map" by YuvoNet
	sand = { color = "rbxassetid://95114690737752", normal = "rbxassetid://102990337355056", rough = "rbxassetid://76767113118953", studs = 10, decal = 99722758965795 }, -- "Images/Sand_007_basecolor", "_normal" and "_roughness" by GT3RR1
	metal = { color = "rbxassetid://105709811279238", studs = 6, decal = 107449767137487 }, -- "stainless-steel-2500-mm-architextures" by abunda77
}

return TextureIds
