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
}

Palette.MaterialSet = {} :: { [string]: boolean }
for _, m in Palette.Materials do
	Palette.MaterialSet[m.id] = true
end

-- Rows of swatches, light to dark, warm to cool.
Palette.Colors = {
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

Palette.Defaults = {
	WallOut = { c = "F2E8D5", m = "Plaster" },
	WallIn = { c = "F7F3EA", m = "SmoothPlastic" },
	Floor = { c = "C99A62", m = "WoodPlanks" },
	Roof = { c = "9C2A2E", m = "Slate" },
	RoofGable = { c = "F2E8D5", m = "Plaster" },
	Fence = { c = "FFFFFF", m = "Wood" },
	Hedge = { c = "4E9A44", m = "Grass" },
	Stone = { c = "B4B4B8", m = "Cobblestone" },
	Glass = { c = "CDEEF5", m = "Glass" },
}

return Palette
