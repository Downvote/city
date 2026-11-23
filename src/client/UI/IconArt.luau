--!strict
-- The icons' vector art. The user: "Alot of the icons arent proper vector art and just shapes
-- spliced together, look online to see how vector art should be. Make them as simple as possible."
--
-- So they are drawn the way the line icon sets on the web are (their published design guides
-- agree on the rules, and these follow them, in drawings of our own):
--   a 24 by 24 grid, with nothing nearer than 2 to the edge
--   one line weight for everything, with round ends and round corners
--   as few lines as will still say what the thing is: a silhouette and one or two details
--   whole numbers and halves, so lines land cleanly on pixels
--   parts that would touch are kept 2 apart, or one is cut clear of the other
-- Each icon is a list of paths in SVG's path language (see UI/Vector). A plain string is a line;
-- { path, fill = true } is filled; colours make coloured art (the coin).

local Vector = require(script.Parent.Vector)
local ItemArt = require(script.Parent.ItemArt)

local circle, rect, dot = Vector.circle, Vector.rect, Vector.dot

local IconArt = {}

local A: { [string]: { Vector.Layer } } = {}
IconArt.art = A

-- signs ------------------------------------------------------------------------------------------------

A.plus = { "M12 5 V19", "M5 12 H19" }
A.close = { "M6 6 L18 18", "M18 6 L6 18" }
A.check = { "M4.5 12.5 L9.5 17.5 L19.5 6.5" }
A.up = { "M12 19.5 V4.5", "M6 10.5 L12 4.5 L18 10.5" }
A.down = { "M12 4.5 V19.5", "M6 13.5 L12 19.5 L18 13.5" }
A.back = { "M19.5 12 H4.5", "M10.5 6 L4.5 12 L10.5 18" }
A.alert = { circle(12, 12, 9), "M12 7.5 V12.5", dot(12, 16.3) }
A.eye = { "M2.5 12 Q12 2.5 21.5 12 Q12 21.5 2.5 12 Z", circle(12, 12, 3) }
A.zoom = { circle(10.5, 10.5, 6.5), "M15.5 15.5 L20.5 20.5" }
A.grid =
	{ rect(3.5, 3.5, 7, 7, 1.5), rect(13.5, 3.5, 7, 7, 1.5), rect(3.5, 13.5, 7, 7, 1.5), rect(13.5, 13.5, 7, 7, 1.5) }
A.layers = { "M12 3 L20.5 7.5 L12 12 L3.5 7.5 Z", "M3.5 12 L12 16.5 L20.5 12", "M3.5 16.5 L12 21 L20.5 16.5" }
A.clock = { circle(12, 12, 9), "M12 7 V12 L15.5 14" }
A.camera = { rect(3, 7, 18, 13, 2.5), "M8.5 7 L10 4 H14 L15.5 7", circle(12, 13.5, 3.5) }
A.dice = {
	rect(3.5, 3.5, 17, 17, 3.5),
	{ circle(8.5, 8.5, 1.4), fill = true },
	{ circle(15.5, 15.5, 1.4), fill = true },
	{ circle(15.5, 8.5, 1.4), fill = true },
	{ circle(8.5, 15.5, 1.4), fill = true },
}
A.music = { circle(7.5, 17.5, 3), "M10.5 17.5 V3.5 Q14.5 4.5 17 9" }
A.ruler = { rect(2.5, 8, 19, 8, 1.5), "M7 8 V11", "M12 8 V12.5", "M17 8 V11" }
A.map = { "M12 21.5 Q5 14.5 5 10 A7 7 0 0 1 19 10 Q19 14.5 12 21.5 Z", circle(12, 10, 2.5) }
A.news = { rect(3.5, 4.5, 17, 15, 2), "M7.5 9 H16.5", "M7.5 12.5 H16.5", "M7.5 16 H12.5" }
A.cart = { "M2.5 4 H5.5 L8 15 H17.5 L20 7.5 H6.4", circle(9.5, 19, 1.4), circle(16.5, 19, 1.4) }
A.bag = { "M5.5 8 H18.5 L19.5 20.5 H4.5 Z", "M9 11 V7 A3 3 0 0 1 15 7 V11" }
A.gift = {
	rect(3, 8, 18, 4, 1),
	"M5 12 V20.5 H19 V12",
	"M12 8 V20.5",
	"M12 8 Q8.5 2.5 6.5 5 Q5.5 7.5 12 8",
	"M12 8 Q15.5 2.5 17.5 5 Q18.5 7.5 12 8",
}
A.briefcase =
	{ rect(3, 7.5, 18, 12.5, 2.5), "M9 7.5 V5.5 A1.5 1.5 0 0 1 10.5 4 H13.5 A1.5 1.5 0 0 1 15 5.5 V7.5", "M3 13 H21" }

-- people -----------------------------------------------------------------------------------------------

A.person = { circle(12, 8, 4), "M4 21 V20 A6 6 0 0 1 10 14 H14 A6 6 0 0 1 20 20 V21" }
A.people = {
	circle(9, 8.5, 3.5),
	"M2.5 20.5 V19.5 A5.5 5.5 0 0 1 8 14 H10 A5.5 5.5 0 0 1 15.5 19.5 V20.5",
	"M15.5 5.2 A3.5 3.5 0 0 1 15.5 11.8",
	"M18 14.4 A5.5 5.5 0 0 1 21.5 19.5 V20.5",
}
A.smile = {
	circle(12, 12, 9),
	{ circle(9, 10, 1.3), fill = true },
	{ circle(15, 10, 1.3), fill = true },
	"M8 14.5 Q12 18.5 16 14.5",
}
A.heart = { "M12 20.5 L4.6 13 A4.9 4.9 0 0 1 12 6.6 A4.9 4.9 0 0 1 19.4 13 Z" }
A.medal = { circle(12, 15, 6), "M9 9.8 L6.5 3", "M15 9.8 L17.5 3", "M10.5 3 L12 6.5 L13.5 3" }
A.trophy = {
	"M7 4 H17 V10 A5 5 0 0 1 7 10 Z",
	"M7 6 H4 V7.5 A3.5 3.5 0 0 0 7.3 11",
	"M17 6 H20 V7.5 A3.5 3.5 0 0 1 16.7 11",
	"M12 15 V20",
	"M7.5 20.5 H16.5",
}

-- money ------------------------------------------------------------------------------------------------

-- The coin keeps its gold and the darker circle pressed into its face (the user: "the coin icon
-- can have a darker circle inside as an indent").
local GOLD, GOLD_DARK = Color3.fromRGB(240, 170, 40), Color3.fromRGB(196, 130, 24)
A.coin = {
	{ circle(12, 12, 10), fill = GOLD },
	{ circle(12, 12, 5.5), fill = GOLD_DARK },
}
A.coins = {
	{ circle(15, 14.5, 7), fill = GOLD },
	{ circle(15, 14.5, 3.6), fill = GOLD_DARK },
	{ circle(9, 9.5, 8.6), fill = true, cut = true },
	{ circle(9, 9.5, 7), fill = GOLD },
	{ circle(9, 9.5, 3.6), fill = GOLD_DARK },
}

-- clothes (the creator's tabs) ---------------------------------------------------------------------

A.shirt = { "M8.5 3.5 L3 6.5 L5 11 L7.5 10 V20.5 H16.5 V10 L19 11 L21 6.5 L15.5 3.5 Q12 7.5 8.5 3.5 Z" }
A.pants = { "M6 3.5 H18 L19.5 20.5 H14 L12 9.5 L10 20.5 H4.5 Z" }
A.shoe = { "M3 18.5 V10.5 L7.5 12.5 L10.5 9 Q13 14 18.5 14.5 Q21 15 21 18.5 Z" }
A.hat = { "M3.5 16.5 A7.5 7.5 0 0 1 18.5 16.5 Z", "M18.5 16.5 H21.5" }
-- a comb
A.hair = { rect(3.5, 6, 17, 4, 1.5), "M6 10 V18", "M9 10 V18", "M12 10 V18", "M15 10 V18", "M18 10 V18" }

-- the tools --------------------------------------------------------------------------------------------

A.hammer = { "M10.2 6.7 L13.7 3.2 L20.8 10.3 L17.3 13.8 Z", "M13.7 10.3 L4.5 19.5" }
A.pointer = { "M5 3.5 V18.5 L9.5 14.5 L13 21 L15.6 19.7 L12.3 13.4 L18 13 Z" }
A.move = {
	"M12 3 V21",
	"M3 12 H21",
	"M9 6 L12 3 L15 6",
	"M9 18 L12 21 L15 18",
	"M6 9 L3 12 L6 15",
	"M18 9 L21 12 L18 15",
}
A.rotate = { "M19.5 12.5 A7.5 7.5 0 1 1 16.2 6.3", "M15.5 2.6 L16.2 6.3 L12.5 7" }
A.undo = { "M4 9 H14.5 A5.5 5.5 0 0 1 14.5 20 H8", "M8 5 L4 9 L8 13" }
A.redo = { "M20 9 H9.5 A5.5 5.5 0 0 0 9.5 20 H16", "M16 5 L20 9 L16 13" }
A.copy = {
	rect(8.5, 8.5, 12, 12, 2),
	"M5.5 15.5 H5 A1.5 1.5 0 0 1 3.5 14 V5 A1.5 1.5 0 0 1 5 3.5 H14 A1.5 1.5 0 0 1 15.5 5 V5.5",
}
A.brush = { "M20.5 3.5 L11 13", "M11 13 Q7.5 12.5 6 15.5 Q5.5 19 3 20 Q8.5 21.5 11.5 18.5 Q13 16 11 13 Z" }
A.bucket = { "M5 8 H19 L17.5 20.5 H6.5 Z", "M5 8 A7 5 0 0 1 19 8" }
A.trash = {
	"M4 6.5 H20",
	"M9.5 6.5 V4.5 A1 1 0 0 1 10.5 3.5 H13.5 A1 1 0 0 1 14.5 4.5 V6.5",
	"M6 6.5 L7 19 A1.8 1.8 0 0 0 8.8 20.5 H15.2 A1.8 1.8 0 0 0 17 19 L18 6.5",
	"M10 10.5 V16.5",
	"M14 10.5 V16.5",
}
A.hardhat = { "M5 17 V15 A7 7 0 0 1 19 15 V17", "M3 17.5 H21", "M12 8 V12.5" }
A.crane = { "M7 21 V4", "M3.5 7 H20.5", "M17 7 V12", "M17 12 A2 2 0 1 1 15 14", "M4 21 H10" }
A.blueprint = { rect(3.5, 4.5, 17, 15, 2), "M11 4.5 V12 H3.5", "M15 19.5 V14.5" }

-- places -----------------------------------------------------------------------------------------------

A.house = { "M3.5 11 L12 3.5 L20.5 11", "M5.5 9.5 V20.5 H18.5 V9.5", "M10 20.5 V15 H14 V20.5" }
A.hall = { "M3 9 L12 3.5 L21 9 Z", "M6.5 12.5 V17.5", "M12 12.5 V17.5", "M17.5 12.5 V17.5", "M3.5 20.5 H20.5" }
A.store = { "M3 10 L5 4.5 H19 L21 10 Z", "M5 10 V20.5 H19 V10", "M10 20.5 V15 H14 V20.5" }
A.city = { "M4 21 V11 H9 V5 H15 V21", "M15 13 H20 V21", "M2.5 21 H21.5", dot(12, 9), dot(12, 13), dot(12, 17) }
A.road = { "M7 3.5 L4 20.5", "M17 3.5 L20 20.5", "M12 5 V7.5", "M12 11 V13.5", "M12 17 V19.5" }
A.path = {
	{ rect(3, 15.5, 7.5, 5.5, 2.7), fill = true },
	{ rect(8.5, 9.2, 7.5, 5.5, 2.7), fill = true },
	{ rect(14, 3, 7, 5, 2.5), fill = true },
}

-- building pieces --------------------------------------------------------------------------------------

A.wall = { rect(3, 5, 18, 14, 1.5), "M3 9.7 H21", "M3 14.3 H21", "M9 5 V9.7", "M15 9.7 V14.3", "M9 14.3 V19" }
A.wallHalf = { rect(3, 11.5, 18, 8.5, 1.5), "M3 15.8 H21", "M9 11.5 V15.8", "M15 15.8 V20" }
A.wallGlass = { rect(3.5, 4.5, 17, 15, 1.5), "M8 14.5 L13 9.5", "M12.5 15.5 L16 12" }
A.railing = { "M3 7.5 H21", "M3 18.5 H21", "M6.5 7.5 V18.5", "M12 7.5 V18.5", "M17.5 7.5 V18.5" }
A.fence = {
	"M3 12.5 H21",
	{ "M5.5 20.5 V7 L8 4 L10.5 7 V20.5 Z", fill = true },
	{ "M13.5 20.5 V7 L16 4 L18.5 7 V20.5 Z", fill = true },
}
A.hedge = {
	"M4 20.5 V11 A2.667 2.667 0 0 1 9.333 11 A2.667 2.667 0 0 1 14.667 11 A2.667 2.667 0 0 1 20 11 V20.5",
	"M2.5 20.5 H21.5",
}
A.stoneWall = { rect(3, 5, 10, 6, 3), rect(15, 5, 6, 6, 3), rect(3, 13, 6, 6, 3), rect(11, 13, 10, 6, 3) }
A.room = { rect(4, 4, 16, 16, 2), "M4 13 A7 7 0 0 1 11 20" }
A.floor = { "M12 4.5 L21 12 L12 19.5 L3 12 Z", "M7.5 8.25 L16.5 15.75", "M16.5 8.25 L7.5 15.75" }
A.roof = { "M3 17.5 L8 8.5 L13 17.5 Z", "M8 8.5 H17 L21.5 17.5 H13" }
A.roofHip = { "M3 17.5 L8 9 H16 L21 17.5 Z" }
A.roofPyramid = { "M3 17.5 L12 6.5 L21 17.5 Z", "M12 6.5 V17.5" }
A.roofShed = { "M3 17.5 L21 8.5 V17.5 Z" }
A.roofFlat = { rect(3, 12.5, 18, 5, 1) }
A.door = { "M6 21 V4.5 A1.5 1.5 0 0 1 7.5 3 H16.5 A1.5 1.5 0 0 1 18 4.5 V21", "M3.5 21 H20.5", dot(14.5, 12.5) }
A.window = { rect(4, 4, 16, 16, 2), "M12 4 V20", "M4 12 H20" }
A.stairs = { "M3 20.5 H8 V15.5 H13 V10.5 H18 V5.5 H21" }

-- furniture and the garden -----------------------------------------------------------------------------

A.chair = { "M7.5 3.5 V20.5", "M7.5 12.5 H16.5 V20.5" }
A.table = { "M3 8 H21", "M6 8 V20", "M18 8 V20" }
A.sofa = {
	"M5.5 11 V8 A2.5 2.5 0 0 1 8 5.5 H16 A2.5 2.5 0 0 1 18.5 8 V11",
	"M3 13 A2 2 0 0 1 7 13 V15 H17 V13 A2 2 0 0 1 21 13 V18.5 H3 Z",
	"M6 18.5 V20.5",
	"M18 18.5 V20.5",
}
A.bed = { "M3 5 V20", "M21 20 V14.5 A3 3 0 0 0 18 11.5 H3", "M3 16.5 H21", rect(5.5, 7.5, 5, 4, 1.5) }
A.cabinet = { rect(5, 3, 14, 18, 2), "M5 12 H19", dot(12, 7.5), dot(12, 16.5) }
A.pot = { "M5 10 H19 V16 A4 4 0 0 1 15 20 H9 A4 4 0 0 1 5 16 Z", "M5 12.5 H2.5", "M19 12.5 H21.5", "M10 6.5 H14" }
A.bath = {
	"M3 12 H21 V14 A5 5 0 0 1 16 19 H8 A5 5 0 0 1 3 14 Z",
	"M7 19 V21",
	"M17 19 V21",
	"M6 12 V6.5 A2 2 0 0 1 10 6.5 V7.5",
}
A.lamp = { "M8.5 3.5 H15.5 L18.5 12 H5.5 Z", "M12 12 V20", "M8 20.5 H16" }
A.frame = { rect(3.5, 4.5, 17, 15, 2), "M6.5 16 L10.5 11 L13 14 L15 12 L17.5 16", dot(15.5, 8.5) }
A.gamepad = {
	"M6.5 7.5 H17.5 A4.5 4.5 0 0 1 22 12 L21 17 A2.5 2.5 0 0 1 16.5 17.5 L15.5 15.5 H8.5 L7.5 17.5 A2.5 2.5 0 0 1 3 17 L2 12 A4.5 4.5 0 0 1 6.5 7.5 Z",
	"M7 11.5 H10",
	"M8.5 10 V13",
	dot(15, 10.5),
	dot(17.5, 12.5),
}
A.plant = {
	"M7.5 14.5 H16.5 L15.5 20.5 H8.5 Z",
	"M12 14.5 V9",
	"M12 9 Q7 9 6.5 4 Q11.5 4 12 9",
	"M12 11.5 Q17 11.5 17.5 6.5 Q12.5 6.5 12 11.5",
}
A.tree = { "M8.5 15.5 A4.5 4.5 0 0 1 6.5 7.6 A5.6 5.6 0 0 1 17.2 6.8 A4.5 4.5 0 0 1 15.5 15.5 Z", "M12 15.5 V21" }
-- a tulip
A.flower = { "M8 4 Q8 11.5 12 11.5 Q16 11.5 16 4 L14 6.5 L12 4 L10 6.5 Z", "M12 11.5 V21", "M12 18 Q8 18 7 14" }

-- the sky ----------------------------------------------------------------------------------------------

A.sun = {
	circle(12, 12, 4),
	"M12 2.5 V4.5",
	"M12 19.5 V21.5",
	"M2.5 12 H4.5",
	"M19.5 12 H21.5",
	"M5.3 5.3 L6.7 6.7",
	"M17.3 17.3 L18.7 18.7",
	"M5.3 18.7 L6.7 17.3",
	"M17.3 6.7 L18.7 5.3",
}
A.moon = { "M20 14.5 A8.5 8.5 0 1 1 9.5 4 A6.5 6.5 0 0 0 20 14.5 Z" }
A.cloud = { "M7 18.5 A4.5 4.5 0 0 1 6.6 9.5 A6 6 0 0 1 18 10.5 A4 4 0 0 1 17.5 18.5 Z" }
local SMALL_CLOUD = "M7 15 A4 4 0 0 1 6.8 7 A5.5 5.5 0 0 1 17.3 8 A3.5 3.5 0 0 1 17 15 Z"
A.rain = { SMALL_CLOUD, "M8.5 18 L7.5 20.5", "M12.5 18 L11.5 20.5", "M16.5 18 L15.5 20.5" }
A.storm = { SMALL_CLOUD, "M13 15.5 L10.5 18.5 H13.5 L11.5 21.5" }
A.snow = { SMALL_CLOUD, dot(8, 18.5), dot(12, 20.5), dot(16, 18.5) }
A.blossom = {
	{ circle(12, 7.2, 3), fill = true },
	{ circle(16.6, 10.5, 3), fill = true },
	{ circle(14.8, 15.9, 3), fill = true },
	{ circle(9.2, 15.9, 3), fill = true },
	{ circle(7.4, 10.5, 3), fill = true },
	{ circle(12, 12, 2.2), fill = true, cut = true },
}
A.leaves = { "M4.5 19.5 Q4.5 8 19.5 4.5 Q19.5 19.5 4.5 19.5 Z", "M4.5 19.5 L13 11" }

-- things from the shop and food (UI/ItemArt) ------------------------------------------------------

for name, art in ItemArt do
	A[name] = art
end

return IconArt
