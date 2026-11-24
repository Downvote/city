--!strict
-- Roblox image ids for the materials' textures and for the looks (Data/Textures). They come from
-- the Creator Store (public decals, found with scripts/library_textures.py; `decal` is the decal
-- they came from, the comment its name and maker). Our own painted set in art/textures can take a
-- texture's place once uploaded (scripts/upload_textures.py, which starts the comment with
-- "painted"). Fields: `color` the image, `normal` an optional normal map (OpenGL style, the kind
-- Roblox reads) and `rough` an optional roughness map, both from the same set as the colour
-- where the picture has a pattern (bricks, cobbles, tiles), `studs` how many studs one copy
-- covers (else Data/Textures' own), `own` when the picture brings its own colour (the part's
-- paint then only tints it lightly), `light` how light the picture is on average (0 to 1) when
-- it is a good deal darker than the rest: the part's paint is then brightened to make up for
-- it, as far as the colour can go (Textures.shade).
-- After changing this, run python3 scripts/sync_materials.py to put it in the place.
-- A texture with no colour id here keeps Roblox's own material, and a look with none shows its
-- material. One texture a line: the scripts and the preview read this file line by line.

export type Ids = {
	color: string?,
	normal: string?,
	rough: string?,
	studs: number?,
	own: boolean?,
	light: number?,
	decal: number?,
}

-- stylua: ignore
local TextureIds: { [string]: Ids } = {
	meadow = { color = "rbxassetid://79514706284696", rough = "rbxassetid://79514706284696", studs = 32 }, -- the same plain white map from xander_z22's SkinnedGrass pack: the grass under foot, smooth and matt
	blade = { color = "rbxassetid://79514706284696", rough = "rbxassetid://79514706284696", studs = 16 }, -- a plain white map from xander_z22's SkinnedGrass pack: no pattern, fully matt (the long grass's blades)
	lawn = { color = "rbxassetid://123781418381440", normal = "rbxassetid://74383676401444", rough = "rbxassetid://123781418381440", studs = 16, light = 0.7, decal = 132962949126736 }, -- "Grass005_2K-JPG_Roughness" and "_NormalGL" by gabrieleivazians2041 (the set's grey map, so the paint decides the green)
	wood = { color = "rbxassetid://127935223360351", normal = "rbxassetid://82700223149662", studs = 4, decal = 125695710899534 }, -- "Wood Texture" by conoluz; normal "Wood092_1K-PNG_NormalGL" by Proville6
	planks = { color = "rbxassetid://126083643168466", studs = 6, decal = 107218328642902 }, -- "Roblox wood planks texture" by TheDanMan2307
	brick = { color = "rbxassetid://15826262054", normal = "rbxassetid://15826267601", studs = 8, decal = 15826262079 }, -- "brick color" and "brick normal" by latechicagonightz
	cobble = { color = "rbxassetid://79170514243126", normal = "rbxassetid://135713644746103", studs = 8, light = 0.54, decal = 109103115932604 }, -- "PavingStones005_2K-JPG_Color" and "_NormalGL" by PixBay_YT
	paving = { color = "rbxassetid://133622340383137", studs = 6, decal = 134144901412773 }, -- "brick" by goatysan
	concrete = { color = "rbxassetid://17528667950", normal = "rbxassetid://10266817549", studs = 12, decal = 17528667984 }, -- "Old Concrete Texture" by VastChadJavelin; normal "concrete_floor_02_nor_gl_2k" by Chrn_E
	asphalt = { color = "rbxassetid://74051293306053", normal = "rbxassetid://11226165423", studs = 12, light = 0.48, decal = 104048479913484 }, -- "Asphalt texture (worn)" by DaHood_lover123; normal "asphalt_01_nor_gl_1k" by dorndaft
	plaster = { color = "rbxassetid://7339363282", normal = "rbxassetid://5437994223", studs = 8, decal = 7339363321 }, -- "Dry Wall Texture" by hamzahassan6; normal "Concrete_Wall_Nor" from the library
	clay = { color = "rbxassetid://6436676312", studs = 8, light = 0.52, decal = 6436676320 }, -- "BCFBC793-7B38-4635-B77A-B226FDC43928" by elixiric (grey tiles, so the paint decides the roof's colour)
	tiles = { color = "rbxassetid://15246763549", normal = "rbxassetid://12477337856", studs = 6, decal = 15246763593 }, -- "Tiles107_2K-PNG_Color" by mycardgo; normal "Tiles107_2K_NormalGL" by Omair1962
	carpet = { color = "rbxassetid://10538536313", normal = "rbxassetid://108650587944937", studs = 4, light = 0.54, decal = 10538536325 }, -- "Carpet" by attmpt9; normal "Carpet Normal Map" by Bunniekell
	fabric = { color = "rbxassetid://234307070", normal = "rbxassetid://83181758798164", studs = 3, decal = 234307071 }, -- "Seamless Grey Fabric Texture" by joshman601; normal "Fabric Normal Map" by YuvoNet
	sand = { color = "rbxassetid://95114690737752", normal = "rbxassetid://102990337355056", rough = "rbxassetid://76767113118953", studs = 10, decal = 99722758965795 }, -- "Images/Sand_007_basecolor", "_normal" and "_roughness" by GT3RR1
	metal = { color = "rbxassetid://105709811279238", studs = 6, decal = 107449767137487 }, -- "stainless-steel-2500-mm-architextures" by abunda77
	panel = { color = "rbxassetid://110052141069002", studs = 12, light = 0.61, decal = 126105097611166 }, -- "Concrete Plate" by Skyelinegaming
	stucco = { color = "rbxassetid://16287812455", studs = 10, decal = 16287812487 }, -- "smooth stucco smooth" by lilskayx
	maple = { color = "rbxassetid://9620643733", studs = 6, decal = 9620643745 }, -- "Sweet_picnic_white-min" by Varzkitt
	mosaic = { color = "rbxassetid://5621459779", studs = 5, decal = 5621459802 }, -- "TileFloor" by mowochji
	checker = { color = "rbxassetid://98785224516028", studs = 4, decal = 131674660080752 }, -- "ntxr006" by GlitchedMayhemVFX
	corrugated = { color = "rbxassetid://17452681009", studs = 4, decal = 17452681037 }, -- "Images/128_white corrugated metal PBR texture-seam" by CodedAIbania
	shutter = { color = "rbxassetid://6723969247", studs = 4, decal = 6723969275 }, -- "Metal Shutters Texture" by Czlopek
	slats = { color = "rbxassetid://4708950958", studs = 10, own = true, decal = 4708950960 }, -- "vertical wood" by dadachonguusu
	barrel = { color = "rbxassetid://6436676312", studs = 10, light = 0.52, decal = 6436676320 }, -- "BCFBC793-7B38-4635-B77A-B226FDC43928" by elixiric
	slabs = { color = "rbxassetid://15005538341", studs = 6, light = 0.56, decal = 15005538380 }, -- "Seamless Pavement Light Grey Tiles" by Adilordofwick2
	street = { color = "rbxassetid://73120610106763", normal = "rbxassetid://11226165423", studs = 16, light = 0.41, decal = 132204323264236 }, -- "07F30FFC-720E-431C-BF04-24E4CEC113D8" by OohIsADuck; normal "asphalt_01_nor_gl_1k" by dorndaft
	canvas = { color = "rbxassetid://106263716160538", normal = "rbxassetid://82442953804931", rough = "rbxassetid://81106618533486", studs = 3, decal = 110591274644699 }, -- "Color map", "Normal map" and "Roughness Map" by TriangRaroGames
	cliff = { color = "rbxassetid://92852701550899", studs = 16, light = 0.48, decal = 78269602654558 }, -- "stone texture" by Gojoh_12345A
}

return TextureIds
