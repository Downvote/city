--!strict
-- The paint swatches and materials the build tools offer. Saved builds only ever hold
-- materials from this list, so the server can check them.

local Palette = {}

Palette.Materials = {
	{ id = "SmoothPlastic", name = "Paint" },
	{ id = "Plastic", name = "Plastic" },
	{ id = "Wood", name = "Wood" },
	{ id = "WoodPlanks", name = "Planks" },
	{ id = "Brick", name = "Brick" },
	{ id = "Cobblestone", name = "Cobble" },
	{ id = "Concrete", name = "Concrete" },
	{ id = "Plaster", name = "Plaster" },
	{ id = "Marble", name = "Marble" },
	{ id = "Granite", name = "Granite" },
	{ id = "Slate", name = "Slate" },
	{ id = "Pebble", name = "Pebble" },
	{ id = "Fabric", name = "Fabric" },
	{ id = "Carpet", name = "Carpet" },
	{ id = "Metal", name = "Metal" },
	{ id = "DiamondPlate", name = "Plate" },
	{ id = "Glass", name = "Glass" },
	{ id = "Ice", name = "Frost" },
	{ id = "Sand", name = "Sand" },
	{ id = "Grass", name = "Grass" },
	{ id = "Rock", name = "Rock" },
	{ id = "Neon", name = "Glow" },
	{ id = "CeramicTiles", name = "Tiles" },
	{ id = "Pavement", name = "Paving" },
	{ id = "Asphalt", name = "Road" },
	{ id = "Limestone", name = "Limestone" },
	{ id = "Sandstone", name = "Sandstone" },
	{ id = "ClayRoofTiles", name = "Clay tiles" },
	{ id = "RoofShingles", name = "Shingles" },
	{ id = "Leather", name = "Leather" },
}

Palette.MaterialSet = {} :: { [string]: boolean }
for _, m in Palette.Materials do
	Palette.MaterialSet[m.id] = true
end

-- Rows of swatches, light to dark, warm to cool. The first three rows are the town's own
-- palette (the user: "make the colors of the buildings, such as the roof of the buildings, more
-- pleasing to look at"): soft walls, then roofs that go with them, so a player's own buildings
-- come out well. The rows after them are the older, stronger set; plans keep any hex colour, so a
-- wall painted with one of them still loads whatever the list holds.
Palette.Colors = {
	-- soft walls
	"F6F0E2",
	"F2E6CC",
	"F3DFA6",
	"F0CDB0",
	"EBC8C2",
	"D69A82",
	"CFE2D0",
	"CCDDEA",
	"D8D2E6",
	"E6D5B4",
	"DAD4C8",
	"FAF6EC",
	-- roofs
	"C27E63",
	"B8665C",
	"6A5C5A",
	"86A886",
	"6E8CA8",
	"4F6488",
	-- whites and creams
	"FFFFFF",
	"F7F3EA",
	"F2E8D5",
	"EADBC0",
	"D9C7A7",
	"C8B28F",
	-- greys
	"D6D6D6",
	"B4B4B8",
	"8E8E94",
	"68686E",
	"45454A",
	"2A2A2E",
	-- woods
	"E3C08D",
	"C99A62",
	"A8743F",
	"8A5A2E",
	"6B4423",
	"4A2E18",
	-- reds and pinks
	"FFD1DC",
	"F59EB5",
	"E8667A",
	"C7383F",
	"9C2A2E",
	"6E1F24",
	-- oranges and yellows
	"FFE9A8",
	"FFD45C",
	"F5B431",
	"F08A2E",
	"D4622B",
	"A34A22",
	-- greens
	"D9F2C4",
	"A8DB8A",
	"78BF5E",
	"4E9A44",
	"33733A",
	"23502C",
	-- blues and teals
	"CDEEF5",
	"8FD3E8",
	"4FA9D9",
	"2F7BBF",
	"24548F",
	"1B3560",
	-- purples
	"E6D9F7",
	"C4A8EB",
	"9C7AD6",
	"7552B3",
	"553A87",
	"3A2760",
}

-- Ready-made finishes shown as tiles in Build mode, the way house builders offer them.
Palette.Presets = {
	walls = {
		{ name = "Cream plaster", c = "F2E6CC", m = "Plaster" },
		{ name = "White paint", c = "F7F3EA", m = "SmoothPlastic" },
		{ name = "Red brick", c = "B86A54", m = "Brick" },
		{ name = "Grey brick", c = "8E8E94", m = "Brick" },
		{ name = "Wood siding", c = "C99A62", m = "WoodPlanks" },
		{ name = "Dark wood", c = "6B4423", m = "WoodPlanks" },
		{ name = "Stone", c = "B4B4B8", m = "Cobblestone" },
		{ name = "Limestone", c = "EADBC0", m = "Limestone" },
		{ name = "Sage", c = "B9CFB2", m = "SmoothPlastic" },
		{ name = "Sky blue", c = "CCDDEA", m = "SmoothPlastic" },
		{ name = "Blush", c = "EBC8C2", m = "SmoothPlastic" },
		{ name = "Charcoal", c = "45454A", m = "SmoothPlastic" },
		{ name = "White tiles", c = "F7F3EA", m = "CeramicTiles" },
		{ name = "Concrete", c = "B4B4B8", m = "Concrete" },
	},
	floors = {
		{ name = "Oak planks", c = "C99A62", m = "WoodPlanks" },
		{ name = "Walnut planks", c = "8A5A2E", m = "WoodPlanks" },
		{ name = "Light wood", c = "E3C08D", m = "Wood" },
		{ name = "White tiles", c = "F7F3EA", m = "CeramicTiles" },
		{ name = "Grey tiles", c = "B4B4B8", m = "CeramicTiles" },
		{ name = "Marble", c = "F7F3EA", m = "Marble" },
		{ name = "Grey carpet", c = "B4B4B8", m = "Carpet" },
		{ name = "Blue carpet", c = "8AA8C8", m = "Carpet" },
		{ name = "Rose carpet", c = "E8AEB8", m = "Carpet" },
		{ name = "Concrete", c = "B4B4B8", m = "Concrete" },
		{ name = "Paving", c = "D9C7A7", m = "Pavement" },
		{ name = "Brick path", c = "C88A6E", m = "Brick" },
		{ name = "Cobbles", c = "8E8E94", m = "Cobblestone" },
		{ name = "Grass", c = "8AC070", m = "Grass" },
		{ name = "Sand", c = "EADBC0", m = "Sand" },
		{ name = "Road", c = "45454A", m = "Asphalt" },
	},
	roofs = {
		{ name = "Red clay", c = "C27E63", m = "ClayRoofTiles" },
		{ name = "Terracotta", c = "C98466", m = "ClayRoofTiles" },
		{ name = "Grey slate", c = "68686E", m = "Slate" },
		{ name = "Charcoal shingles", c = "45454A", m = "RoofShingles" },
		{ name = "Brown shingles", c = "7A5E50", m = "RoofShingles" },
		{ name = "Blue metal", c = "5A7498", m = "DiamondPlate" },
		{ name = "Green", c = "6F8F5F", m = "RoofShingles" },
		{ name = "Thatch", c = "D9C7A7", m = "Grass" },
	},
}

Palette.Defaults = {
	WallOut = { c = "F2E6CC", m = "Plaster" },
	WallIn = { c = "F7F3EA", m = "SmoothPlastic" },
	Floor = { c = "C49A6C", m = "WoodPlanks" },
	Roof = { c = "C27E63", m = "ClayRoofTiles" },
	RoofGable = { c = "F2E6CC", m = "Plaster" },
	Fence = { c = "FAF6EC", m = "Wood" },
	Hedge = { c = "6EAA62", m = "Grass" },
	Stone = { c = "B4B4B8", m = "Cobblestone" },
	Glass = { c = "CDEEF5", m = "Glass" },
}

return Palette
