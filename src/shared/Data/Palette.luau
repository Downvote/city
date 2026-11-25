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
-- A villager's favourite colour, picked from a grid in the creator (the user: "make the color
-- selection like this for villager creation", with a picture of rows of little squares): twelve
-- colours across, four shades down from pale to deep.
-- stylua: ignore
Palette.Favourites = {
	"F6C6C6", "F8D6B8", "F8EDB0", "DDEDB4", "C6E6C8", "BFE6DE", "C4E4F4", "C4D4F2", "CFCBF0", "E0CCF0", "F4CADF", "FFFFFF",
	"EE8E8E", "F2AE78", "F2DA6A", "BBDC78", "8CCC92", "7FCCBE", "86C8E8", "88A8E4", "9C94DE", "BE96DE", "EA94BE", "C8C8CC",
	"D95050", "E5843E", "E8C030", "92C040", "4FAA5A", "3BA898", "4FA9D9", "4F78C8", "6A5CC0", "9460C0", "D45C96", "8E8E94",
	"A83434", "B85E22", "B08A18", "6A8E26", "2F7A3A", "237A6C", "2A7AA8", "2E4E96", "463A8E", "66388E", "A03A6C", "45454A",
}

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
		{ name = "Cream boards", c = "F2E6CC", m = "WoodPlanks" },
		{ name = "White boards", c = "F7F3EA", m = "WoodPlanks" },
		{ name = "Cream plaster", c = "F2E6CC", m = "Plaster" },
		{ name = "White plaster", c = "F7F3EA", m = "Plaster" },
		{ name = "Red brick", c = "B86A54", m = "Brick" },
		{ name = "Grey brick", c = "8E8E94", m = "Brick" },
		{ name = "Wood siding", c = "C99A62", m = "WoodPlanks" },
		{ name = "Dark wood", c = "6B4423", m = "WoodPlanks" },
		{ name = "Stone", c = "B4B4B8", m = "Cobblestone" },
		{ name = "Limestone", c = "EADBC0", m = "Limestone" },
		{ name = "Sage", c = "B9CFB2", m = "WoodPlanks" },
		{ name = "Sky blue", c = "CCDDEA", m = "WoodPlanks" },
		{ name = "Blush", c = "EBC8C2", m = "WoodPlanks" },
		{ name = "Charcoal", c = "45454A", m = "WoodPlanks" },
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
	-- (textured, never flat paint: the user, "for interiors and exteriors everywhere for buildings, try to
	-- not use flat colors, use textures for them instead"; and boards, not stone: "could you use wood
	-- planks instead of stone for buildings using it for interior and exterior such as the default house?")
	WallOut = { c = "F2E6CC", m = "WoodPlanks" },
	WallIn = { c = "F7F3EA", m = "WoodPlanks" },
	Floor = { c = "C49A6C", m = "WoodPlanks" },
	Roof = { c = "C27E63", m = "ClayRoofTiles" },
	RoofGable = { c = "F2E6CC", m = "WoodPlanks" },
	Fence = { c = "FAF6EC", m = "Wood" },
	Hedge = { c = "6EAA62", m = "Grass" },
	Stone = { c = "B4B4B8", m = "Cobblestone" },
	Glass = { c = "CDEEF5", m = "Glass" },
}

return Palette
