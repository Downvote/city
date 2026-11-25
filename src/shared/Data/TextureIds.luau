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
-- material. `sheen` is no texture: its picture is the roughness map of every texture without one. One texture a line: the scripts and the preview read this file line by line.

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
	grass = { color = "rbxassetid://123781418381440", normal = "rbxassetid://74383676401444", rough = "rbxassetid://123781418381440", studs = 12, light = 0.7, decal = 132962949126736 }, -- "Grass005_2K-JPG_Roughness" and "_NormalGL" by gabrieleivazians2041 (grey grass in low contrast with its own bumps: "change ... the grass texture to a softer one", then "make it such that every texture you use has a normal map"; the paint decides the green)
	leafy = { color = "rbxassetid://123781418381440", normal = "rbxassetid://74383676401444", rough = "rbxassetid://123781418381440", studs = 12, light = 0.7, decal = 132962949126736 }, -- "Grass005_2K-JPG_Roughness" and "_NormalGL" by gabrieleivazians2041 (the terrain's grass under what is built, the same picture so the edge doesn't show)
	lawn = { color = "rbxassetid://123781418381440", normal = "rbxassetid://74383676401444", rough = "rbxassetid://123781418381440", studs = 16, light = 0.7, decal = 132962949126736 }, -- "Grass005_2K-JPG_Roughness" and "_NormalGL" by gabrieleivazians2041 (the set's grey map, so the paint decides the green)
	wood = { color = "rbxassetid://127935223360351", normal = "rbxassetid://82700223149662", studs = 4, decal = 125695710899534 }, -- "Wood Texture" by conoluz; normal "Wood092_1K-PNG_NormalGL" by Proville6
	planks = { color = "rbxassetid://12415932259", normal = "rbxassetid://12415937902", studs = 8, decal = 12415932273 }, -- "New WoodPlanks Material ColorMap" and "NormalMap" by DesignWithMarko (pale boards of mixed lengths, so a cream wall stays cream)
	brick = { color = "rbxassetid://15826262054", normal = "rbxassetid://15826267601", studs = 8, decal = 15826262079 }, -- "brick color" and "brick normal" by latechicagonightz
	cobble = { color = "rbxassetid://79170514243126", normal = "rbxassetid://135713644746103", studs = 8, light = 0.54, decal = 109103115932604 }, -- "PavingStones005_2K-JPG_Color" and "_NormalGL" by PixBay_YT
	paving = { color = "rbxassetid://18225244134", normal = "rbxassetid://18225253095", studs = 6, decal = 18225244154 }, -- "Substance_graph_basecolor 2" and "Substance_graph_normal 2" by ayyyyyyuy (pale pavers in running bond, small; the old picture had no normal map)
	concrete = { color = "rbxassetid://92960457218078", normal = "rbxassetid://10266817549", studs = 14, light = 0.55, decal = 138997834312338 }, -- "floor for me1" by coolrobloxian171 (worn: stains and hairline cracks, for the user's "painted textures with wear"); normal "concrete_floor_02_nor_gl_2k" by Chrn_E
	asphalt = { color = "rbxassetid://74051293306053", normal = "rbxassetid://11226165423", studs = 12, light = 0.48, decal = 104048479913484 }, -- "Asphalt texture (worn)" by DaHood_lover123; normal "asphalt_01_nor_gl_1k" by dorndaft
	plaster = { color = "rbxassetid://104528602434593", normal = "rbxassetid://5437994223", studs = 12, light = 0.62, decal = 90702185673414 }, -- "Concrete1" by SkedichX (pale, with soft grime stains); normal "Concrete_Wall_Nor" from the library
	clay = { color = "rbxassetid://14413034401", normal = "rbxassetid://14413034861", studs = 6, light = 0.69, decal = 14413034453 }, -- "PBR-Roof-Red-2K-1K-Roughness" and "-Normal" by codycheck_com (the set's pale grey map: soft, low contrast tiles, the user's "change the roof texture ... to a softer one, which dosent have too high contrast"; the paint decides the colour)
	tiles = { color = "rbxassetid://15246763549", normal = "rbxassetid://12477337856", studs = 6, decal = 15246763593 }, -- "Tiles107_2K-PNG_Color" by mycardgo; normal "Tiles107_2K_NormalGL" by Omair1962
	carpet = { color = "rbxassetid://138747043258994", normal = "rbxassetid://134160894776938", studs = 3, light = 0.7, decal = 129302023534257 }, -- "Stylized Fur Roughness Map" and "Stylized Fur Normal Map" by [FLUFFY] (a soft pile; the old carpet picture was too contrasty)
	fabric = { color = "rbxassetid://234307070", normal = "rbxassetid://83181758798164", studs = 3, decal = 234307071 }, -- "Seamless Grey Fabric Texture" by joshman601; normal "Fabric Normal Map" by YuvoNet
	sand = { color = "rbxassetid://95114690737752", normal = "rbxassetid://102990337355056", rough = "rbxassetid://76767113118953", studs = 10, decal = 99722758965795 }, -- "Images/Sand_007_basecolor", "_normal" and "_roughness" by GT3RR1
	metal = { color = "rbxassetid://12416214927", normal = "rbxassetid://12416216959", studs = 6, decal = 12416214970 }, -- "New Metal Material ColorMap" and "NormalMap" by DesignWithMarko
	panel = { color = "rbxassetid://7048836439", normal = "rbxassetid://7048827454", studs = 12, decal = 7048836443 }, -- "Roughness_2K__vb0mcilg" and "Normal_2K__vb0mcilg" by 101 Boring Studios (pale panels, their joints in the normal map)
	stucco = { color = "rbxassetid://8813978081", normal = "rbxassetid://8813975075", studs = 10, decal = 8813978141 }, -- "tkwgfatew_4K_Roughness" and "_Normal" by cybrsyn (smooth render with a fine trowelled surface)
	maple = { color = "rbxassetid://15826262054", normal = "rbxassetid://15826267601", studs = 5, decal = 15826262079 }, -- "brick color" and "brick normal" by latechicagonightz (the brick picture at a smaller size: courses of narrow bricks)
	mosaic = { color = "rbxassetid://12744227182", normal = "rbxassetid://12744256077", studs = 4, decal = 12744227252 }, -- "Tiles107_1K_Color" and "_NormalGL" by Wayyllon (small white squares, half a stud)
	checker = { color = "rbxassetid://10624067222", normal = "rbxassetid://10624097136", studs = 8, light = 0.66, decal = 10624067335 }, -- "floor_tiles_08_diff_2k" and "_nor_gl_2k" by Chrn_E (square tiles, light and mid grey by turns)
	corrugated = { color = "rbxassetid://17452681009", normal = "rbxassetid://12416216959", studs = 4, decal = 17452681037 }, -- "Images/128_white corrugated metal PBR texture-seam" by CodedAIbania; normal "New Metal Material NormalMap" by DesignWithMarko (the library has no corrugated normal map, so the sheet takes a fine metal one)
	shutter = { color = "rbxassetid://12416214927", normal = "rbxassetid://15825604431", studs = 4, decal = 12416214970 }, -- "New Metal Material ColorMap" by DesignWithMarko; normal "planks normal" by latechicagonightz (plain pale metal with narrow slats in the normal map, so the shutter is soft: the old picture's dark gaps were harsh)
	slats = { color = "rbxassetid://6258399923", normal = "rbxassetid://6258396175", studs = 6, decal = 6258399938 }, -- "4K Roughness Wooden Planks" and "4K Normal Wooden Planks" by adbrokieranlollo (pale upright boards)
	barrel = { color = "rbxassetid://14413034401", normal = "rbxassetid://14413034861", studs = 8, light = 0.69, decal = 14413034453 }, -- "PBR-Roof-Red-2K-1K-Roughness" and "-Normal" by codycheck_com
	slabs = { color = "rbxassetid://18225244134", normal = "rbxassetid://18225253095", studs = 16, decal = 18225244154 }, -- "Substance_graph_basecolor 2" and "Substance_graph_normal 2" by ayyyyyyuy (the same set at full size: slabs of 4 by 2 studs)
	street = { color = "rbxassetid://73120610106763", normal = "rbxassetid://11226165423", studs = 16, light = 0.41, decal = 132204323264236 }, -- "07F30FFC-720E-431C-BF04-24E4CEC113D8" by OohIsADuck; normal "asphalt_01_nor_gl_1k" by dorndaft
	canvas = { color = "rbxassetid://106263716160538", normal = "rbxassetid://82442953804931", rough = "rbxassetid://81106618533486", studs = 3, decal = 110591274644699 }, -- "Color map", "Normal map" and "Roughness Map" by TriangRaroGames
	-- the roughness map for every texture without its own: a flat 50% grey, so every material has a
	-- little shine (the user: "could you make materials interact with lighting more, making all
	-- materials at least abit glossy?")
	sheen = { color = "rbxassetid://16600089027", decal = 16600089064 }, -- "Gray [My Movie]" by WickidOverseer
	cliff = { color = "rbxassetid://10815236587", normal = "rbxassetid://10815253012", studs = 16, light = 0.75, decal = 10815236604 }, -- "Rock029_1K_Roughness" and "_NormalGL" by StackedOakPlanks
}

return TextureIds
