-- The game's icons.
--
-- Icons.make(name, px, props) returns a Frame holding the icon, px pixels square. An icon is
-- vector art (UI/IconArt: paths with curves on a 24 grid, drawn by UI/Vector) painted into a
-- picture the game makes itself, so it needs no uploaded image. The user: "Alot of the icons
-- arent proper vector art and just shapes spliced together ... Make them as simple as possible."
--
-- Making a picture in the game needs Roblox's Mesh / Image API. In a published game that is
-- off until "Allow Mesh / Image APIs" is switched on under Security in the game's settings.
-- Where it is off (or an icon has no art yet) the icon is built the older way instead: out of
-- the rounded rectangles, ellipses and triangles listed below, which always works.
--
-- The older shape lists:
-- Each icon is a list of shapes in a 100 x 100 box, drawn in order:
--   { "r", x, y, w, h, colour, r = corner (0..0.5), rot = degrees, o = false (not part of the
--     outlined silhouette: details inside it), t = transparency }
--   { "c", x, y, w, h, colour, ... }             an ellipse
--   dent = true on a shape: pressed into the piece under it. A flat icon draws it in a darker
--     shade of its one colour (the coin's middle), where other details are cut out
--   { "t", x, y, base, dir, colour, ... }       a right angled triangle with this base; dir up, down,
--                                                left or right; its height is half the base
--   { "ring", x, y, w, h, colour, width }       a hollow ring
--   { "half", x, y, w, h, colour }               the lower half of an ellipse (a smile)
--   { "txt", x, y, w, h, text, colour }         outlined text

local Vector = require(script.Parent.Vector)
local IconArt = require(script.Parent.IconArt)

local Icons = {}

local INK = Color3.fromRGB(38, 32, 52)

local C = {
	gold = Color3.fromRGB(255, 205, 50),
	goldDark = Color3.fromRGB(240, 156, 26),
	goldLight = Color3.fromRGB(255, 232, 120),
	wood = Color3.fromRGB(205, 136, 74),
	woodDark = Color3.fromRGB(150, 94, 52),
	woodLight = Color3.fromRGB(232, 184, 120),
	steel = Color3.fromRGB(190, 202, 216),
	steelDark = Color3.fromRGB(130, 142, 160),
	red = Color3.fromRGB(244, 84, 84),
	redDark = Color3.fromRGB(196, 52, 60),
	blue = Color3.fromRGB(64, 160, 255),
	blueDark = Color3.fromRGB(40, 112, 220),
	blueLight = Color3.fromRGB(150, 210, 255),
	sky = Color3.fromRGB(140, 214, 255),
	green = Color3.fromRGB(96, 206, 86),
	greenDark = Color3.fromRGB(52, 150, 64),
	leaf = Color3.fromRGB(110, 204, 84),
	leafDark = Color3.fromRGB(56, 150, 66),
	purple = Color3.fromRGB(170, 112, 250),
	purpleDark = Color3.fromRGB(120, 72, 210),
	pink = Color3.fromRGB(255, 128, 180),
	pinkDark = Color3.fromRGB(222, 80, 140),
	orange = Color3.fromRGB(255, 154, 52),
	orangeDark = Color3.fromRGB(226, 104, 34),
	cream = Color3.fromRGB(255, 244, 222),
	white = Color3.fromRGB(255, 255, 255),
	grey = Color3.fromRGB(170, 176, 190),
	greyDark = Color3.fromRGB(110, 116, 132),
	greyLight = Color3.fromRGB(222, 228, 238),
	brick = Color3.fromRGB(222, 108, 76),
	brickDark = Color3.fromRGB(176, 76, 56),
	stone = Color3.fromRGB(196, 196, 206),
	skin = Color3.fromRGB(255, 212, 172),
	yellow = Color3.fromRGB(255, 220, 64),
	ink = INK,
}
Icons.Colors = C
Icons.Ink = INK

local D = {}
Icons.defs = D

-- money and people ---------------------------------------------------------------------------------

-- The user: "the coin icon can have a darker circle inside as an indent".
D.coin = {
	{ "c", 6, 6, 88, 88, C.goldDark },
	{ "c", 12, 11, 76, 76, C.gold, o = false },
	{ "c", 24, 24, 52, 52, C.goldDark, o = false, dent = true },
	{ "r", 20, 16, 10, 20, C.white, r = 0.5, rot = 35, o = false, t = 0.35 },
}

D.people = {
	{ "c", 50, 12, 30, 30, C.blueDark },
	{ "r", 42, 44, 50, 44, C.blueDark, r = 0.45 },
	{ "c", 16, 22, 34, 34, C.blue },
	{ "r", 6, 58, 54, 36, C.blue, r = 0.45 },
}

D.person = {
	{ "c", 30, 8, 40, 40, C.blue },
	{ "r", 14, 52, 72, 40, C.blue, r = 0.45 },
}

D.smile = {
	{ "c", 6, 6, 88, 88, C.yellow },
	{ "c", 30, 30, 12, 18, INK, o = false },
	{ "c", 58, 30, 12, 18, INK, o = false },
	{ "half", 26, 44, 48, 36, INK, o = false },
	{ "half", 34, 64, 32, 16, C.red, o = false },
	{ "c", 16, 50, 14, 10, C.pink, o = false, t = 0.3 },
	{ "c", 70, 50, 14, 10, C.pink, o = false, t = 0.3 },
}

D.heart = {
	{ "r", 27, 33, 46, 46, C.red, r = 0.12, rot = 45 },
	{ "c", 10, 14, 44, 44, C.red },
	{ "c", 46, 14, 44, 44, C.red },
	{ "r", 31, 37, 38, 38, C.red, r = 0.1, rot = 45, o = false },
	{ "c", 13, 17, 38, 38, C.red, o = false },
	{ "c", 49, 17, 38, 38, C.red, o = false },
	{ "c", 22, 24, 12, 14, C.white, o = false, t = 0.35 },
}

D.medal = {
	{ "r", 22, 2, 22, 44, C.blue, r = 0.15, rot = -20 },
	{ "r", 56, 2, 22, 44, C.red, r = 0.15, rot = 20 },
	{ "c", 14, 30, 72, 66, C.goldDark },
	{ "c", 22, 37, 56, 52, C.gold, o = false },
	{ "ring", 27, 42, 46, 42, C.goldDark, 5, o = false },
	{ "c", 30, 42, 12, 14, C.white, o = false, t = 0.4 },
}

-- The Goals button's cup (the user: "Change the goals icon to a trophy"): two handles, a bowl
-- with a lip, a stem and a foot.
D.trophy = {
	{ "ring", 11, 16, 24, 24, C.goldDark, 7 },
	{ "ring", 65, 16, 24, 24, C.goldDark, 7 },
	{ "r", 26, 12, 48, 30, C.gold, r = 0.1 },
	{ "half", 26, 10, 48, 64, C.gold },
	{ "r", 22, 6, 56, 12, C.gold, r = 0.5 },
	{ "r", 44, 68, 12, 16, C.goldDark },
	{ "r", 28, 82, 44, 12, C.goldDark, r = 0.35 },
	{ "r", 34, 20, 8, 22, C.white, r = 0.5, o = false, t = 0.4 },
}

-- building and tools -------------------------------------------------------------------------------

-- The Build button's hammer (the user: "Change the hardhat icon for buils to a hammer", then of
-- a thin one with a long thin peen, "That looks like a hoe, make it more like a hammer"). So it
-- is chunky: a thick handle running up to the right, and a heavy block of a head sitting square
-- across its end, as far out on one side as the other, with a short narrower peen at the back.
-- Laid out along its own axes by hand: every piece is turned 45 degrees.
D.hammer = {
	{ "r", 29.6, 22.6, 17.9, 71.7, C.wood, r = 0.45, rot = 45 },
	{ "r", 24.5, 29.8, 58.2, 33.6, C.steel, r = 0.2, rot = 45 },
	{ "r", 25.5, 12.9, 13.4, 24.6, C.steel, r = 0.3, rot = 45 },
	{ "r", 53.3, 44.6, 17.9, 5.6, C.white, r = 0.5, rot = 45, o = false, t = 0.4 },
}

-- A map pin.
D.map = {
	{ "c", 28, 84, 44, 12, C.greyLight },
	{ "c", 22, 4, 56, 56, C.red },
	{ "t", 24, 40, 52, "down", C.red },
	{ "c", 37, 19, 26, 26, C.white },
}

D.house = {
	{ "c", 66, 0, 16, 14, C.white, t = 0.25 },
	{ "r", 66, 14, 12, 28, C.brick, r = 0.1 },
	{ "r", 16, 44, 68, 48, C.cream, r = 0.06 },
	{ "t", 6, 6, 88, "up", C.red },
	{ "r", 4, 47, 92, 8, C.redDark, r = 0.5 },
	{ "r", 40, 60, 20, 32, C.wood, r = 0.2, o = false },
	{ "c", 54, 74, 4, 4, C.gold, o = false },
	{ "r", 21, 59, 15, 15, C.white, r = 0.15, o = false },
	{ "r", 23, 61, 11, 11, C.sky, r = 0.1, o = false },
	{ "r", 64, 59, 15, 15, C.white, r = 0.15, o = false },
	{ "r", 66, 61, 11, 11, C.sky, r = 0.1, o = false },
	{ "r", 46, 24, 8, 12, C.cream, r = 0.3, o = false },
	{ "r", 14, 32, 18, 6, C.white, r = 0.5, rot = -45, o = false, t = 0.5 },
}

D.wall = {
	{ "r", 4, 10, 44, 24, C.brick, r = 0.15 },
	{ "r", 52, 10, 44, 24, C.brick, r = 0.15 },
	{ "r", 4, 38, 22, 24, C.brickDark, r = 0.15 },
	{ "r", 30, 38, 40, 24, C.brick, r = 0.15 },
	{ "r", 74, 38, 22, 24, C.brickDark, r = 0.15 },
	{ "r", 4, 66, 44, 24, C.brick, r = 0.15 },
	{ "r", 52, 66, 44, 24, C.brick, r = 0.15 },
}

D.room = {
	{ "r", 8, 8, 84, 84, C.woodDark, r = 0.1 },
	{ "r", 18, 18, 64, 64, C.woodLight, r = 0.06 },
	{ "r", 18, 46, 30, 8, C.woodDark, r = 0.5, o = false },
	{ "r", 62, 18, 8, 30, C.woodDark, r = 0.5, o = false },
}

D.floor = {
	{ "r", 8, 8, 42, 42, C.wood, r = 0.12 },
	{ "r", 50, 8, 42, 42, C.woodLight, r = 0.12 },
	{ "r", 8, 50, 42, 42, C.woodLight, r = 0.12 },
	{ "r", 50, 50, 42, 42, C.wood, r = 0.12 },
}

D.roof = {
	{ "r", 64, 14, 14, 30, C.brick, r = 0.1 },
	{ "t", 4, 16, 92, "up", C.red },
	{ "r", 2, 58, 96, 12, C.redDark, r = 0.5 },
	{ "r", 18, 70, 64, 20, C.cream, r = 0.1 },
}

D.door = {
	{ "r", 20, 6, 60, 90, C.woodDark, r = 0.1 },
	{ "r", 28, 14, 44, 82, C.wood, r = 0.08 },
	{ "r", 36, 22, 28, 22, C.sky, r = 0.2 },
	{ "c", 58, 54, 9, 9, C.gold },
}

D.window = {
	{ "r", 8, 8, 84, 84, C.white, r = 0.12 },
	{ "r", 17, 17, 30, 30, C.sky, r = 0.1 },
	{ "r", 53, 17, 30, 30, C.sky, r = 0.1 },
	{ "r", 17, 53, 30, 30, C.sky, r = 0.1 },
	{ "r", 53, 53, 30, 30, C.sky, r = 0.1 },
	{ "r", 22, 20, 8, 14, C.white, r = 0.5, rot = 30, o = false, t = 0.3 },
}

D.stairs = {
	{ "r", 6, 70, 88, 22, C.wood, r = 0.12 },
	{ "r", 28, 48, 66, 22, C.woodLight, r = 0.12 },
	{ "r", 50, 26, 44, 22, C.wood, r = 0.12 },
	{ "r", 72, 6, 22, 22, C.woodLight, r = 0.12 },
}

D.pointer = {
	{ "r", 16, 50, 22, 32, C.skin, r = 0.5, rot = -35 },
	{ "r", 40, 6, 20, 52, C.skin, r = 0.5 },
	{ "r", 26, 42, 54, 50, C.skin, r = 0.32 },
	{ "r", 42, 10, 16, 40, C.skin, r = 0.5, o = false },
	{ "r", 46, 12, 7, 14, C.white, r = 0.5, o = false, t = 0.4 },
}

local function arrowHead(dir: string, x: number, y: number, base: number, color: Color3): { any }
	return { "t", x, y, base, dir, color }
end

D.move = {
	{ "r", 43, 16, 14, 68, C.blue, r = 0.3 },
	{ "r", 16, 43, 68, 14, C.blue, r = 0.3 },
	arrowHead("up", 33, 2, 34, C.blue),
	arrowHead("down", 33, 81, 34, C.blue),
	arrowHead("left", 2, 33, 34, C.blue),
	arrowHead("right", 81, 33, 34, C.blue),
}

D.rotate = {
	{ "ring", 14, 14, 72, 72, C.blue, 14 },
	arrowHead("down", 58, 40, 40, C.blue),
	{ "r", 70, 38, 16, 10, C.blue, o = false },
}

D.undo = {
	{ "ring", 22, 22, 64, 64, C.orange, 14 },
	arrowHead("down", 0, 46, 40, C.orange),
	{ "r", 8, 40, 24, 12, C.orange, o = false },
}

D.redo = {
	{ "ring", 14, 22, 64, 64, C.orange, 14 },
	arrowHead("down", 60, 46, 40, C.orange),
	{ "r", 68, 40, 24, 12, C.orange, o = false },
}

D.copy = {
	{ "r", 8, 8, 56, 64, C.steel, r = 0.14 },
	{ "r", 36, 28, 56, 64, C.white, r = 0.14 },
	{ "r", 46, 42, 34, 7, C.grey, r = 0.5, o = false },
	{ "r", 46, 56, 34, 7, C.grey, r = 0.5, o = false },
	{ "r", 46, 70, 22, 7, C.grey, r = 0.5, o = false },
}

D.brush = {
	{ "r", 46, 34, 14, 62, C.wood, r = 0.45, rot = 40 },
	{ "r", 30, 22, 24, 18, C.steel, r = 0.15, rot = 40 },
	{ "r", 12, 2, 30, 30, C.pink, r = 0.4, rot = 40 },
	{ "r", 18, 6, 10, 14, C.white, r = 0.5, rot = 40, o = false, t = 0.4 },
}

D.bucket = {
	{ "r", 18, 30, 64, 62, C.blue, r = 0.18 },
	{ "r", 12, 24, 76, 14, C.blueDark, r = 0.5 },
	{ "c", 24, 18, 52, 20, C.pink },
	{ "r", 26, 44, 10, 30, C.white, r = 0.5, o = false, t = 0.5 },
}

D.trash = {
	{ "r", 38, 8, 24, 12, C.greyDark, r = 0.4 },
	{ "r", 20, 30, 60, 62, C.grey, r = 0.14 },
	{ "r", 12, 18, 76, 14, C.greyDark, r = 0.45 },
	{ "r", 33, 42, 8, 40, C.greyDark, r = 0.5, o = false },
	{ "r", 46, 42, 8, 40, C.greyDark, r = 0.5, o = false },
	{ "r", 59, 42, 8, 40, C.greyDark, r = 0.5, o = false },
}

D.check = {
	{ "r", 10, 46, 40, 20, C.green, r = 0.5, rot = 45 },
	{ "r", 30, 34, 62, 20, C.green, r = 0.5, rot = -50 },
	{ "r", 33, 48, 18, 14, C.green, r = 0.3, o = false, rot = 45 },
}

D.close = {
	{ "r", 8, 38, 84, 24, C.white, r = 0.5, rot = 45 },
	{ "r", 8, 38, 84, 24, C.white, r = 0.5, rot = -45 },
	{ "r", 38, 38, 24, 24, C.white, r = 0.3, o = false, rot = 45 },
}

D.plus = {
	{ "r", 38, 10, 24, 80, C.white, r = 0.35 },
	{ "r", 10, 38, 80, 24, C.white, r = 0.35 },
	{ "r", 39, 39, 22, 22, C.white, o = false },
}

D.up = {
	arrowHead("up", 10, 10, 80, C.white),
	{ "r", 32, 46, 36, 44, C.white, r = 0.2 },
	{ "r", 33, 46, 34, 8, C.white, o = false },
}

-- the way back out of a menu
D.back = {
	arrowHead("left", 10, 10, 80, C.white),
	{ "r", 46, 32, 44, 36, C.white, r = 0.2 },
	{ "r", 46, 33, 8, 34, C.white, o = false },
}

-- a looking glass: a ring and a handle
D.zoom = {
	{ "r", 58, 58, 36, 14, C.white, r = 0.5, rot = 45 },
	{ "ring", 8, 8, 60, 60, C.white, 10 },
}

D.down = {
	{ "r", 32, 10, 36, 44, C.white, r = 0.2 },
	arrowHead("down", 10, 50, 80, C.white),
	{ "r", 33, 46, 34, 8, C.white, o = false },
}

D.eye = {
	{ "r", 4, 24, 92, 52, C.white, r = 0.5 },
	{ "c", 30, 26, 40, 46, C.blue },
	{ "c", 41, 38, 18, 22, INK, o = false },
	{ "c", 44, 36, 8, 8, C.white, o = false },
}

D.grid = {
	{ "r", 8, 8, 24, 24, C.blueLight, r = 0.2 },
	{ "r", 38, 8, 24, 24, C.blueLight, r = 0.2 },
	{ "r", 68, 8, 24, 24, C.blueLight, r = 0.2 },
	{ "r", 8, 38, 24, 24, C.blueLight, r = 0.2 },
	{ "r", 38, 38, 24, 24, C.blue, r = 0.2 },
	{ "r", 68, 38, 24, 24, C.blueLight, r = 0.2 },
	{ "r", 8, 68, 24, 24, C.blueLight, r = 0.2 },
	{ "r", 38, 68, 24, 24, C.blueLight, r = 0.2 },
	{ "r", 68, 68, 24, 24, C.blueLight, r = 0.2 },
}

D.layers = {
	{ "r", 10, 60, 80, 24, C.blueDark, r = 0.35 },
	{ "r", 10, 40, 80, 24, C.blue, r = 0.35 },
	{ "r", 10, 20, 80, 24, C.blueLight, r = 0.35 },
}

D.camera = {
	{ "r", 14, 20, 26, 14, C.greyDark, r = 0.3 },
	{ "r", 6, 28, 88, 60, C.greyDark, r = 0.2 },
	{ "c", 30, 34, 40, 46, C.grey },
	{ "c", 39, 44, 22, 26, C.sky },
	{ "c", 72, 36, 12, 12, C.red, o = false },
}

-- the main dock and panels -------------------------------------------------------------------------

D.shirt = {
	{ "r", 2, 24, 34, 26, C.pinkDark, r = 0.3, rot = -30 },
	{ "r", 64, 24, 34, 26, C.pinkDark, r = 0.3, rot = 30 },
	{ "r", 22, 16, 56, 76, C.pink, r = 0.16 },
	{ "c", 37, 8, 26, 18, C.pinkDark },
	{ "r", 30, 24, 10, 46, C.white, r = 0.5, o = false, t = 0.55 },
}

D.hall = {
	{ "r", 8, 80, 84, 14, C.stone, r = 0.25 },
	{ "r", 16, 46, 12, 36, C.white, r = 0.2 },
	{ "r", 44, 46, 12, 36, C.white, r = 0.2 },
	{ "r", 72, 46, 12, 36, C.white, r = 0.2 },
	{ "r", 8, 38, 84, 12, C.stone, r = 0.3 },
	{ "t", 6, 2, 88, "up", C.blue },
	{ "c", 42, 20, 16, 16, C.gold },
}

D.cart = {
	{ "r", 4, 14, 24, 10, C.greyDark, r = 0.5 },
	{ "r", 18, 24, 72, 44, C.orange, r = 0.16 },
	{ "r", 30, 34, 8, 24, C.orangeDark, r = 0.5, o = false },
	{ "r", 46, 34, 8, 24, C.orangeDark, r = 0.5, o = false },
	{ "r", 62, 34, 8, 24, C.orangeDark, r = 0.5, o = false },
	{ "c", 24, 72, 20, 20, C.greyDark },
	{ "c", 64, 72, 20, 20, C.greyDark },
}

D.bag = {
	{ "ring", 30, 6, 40, 44, C.orangeDark, 9 },
	{ "r", 12, 30, 76, 62, C.orange, r = 0.18 },
	{ "r", 22, 38, 12, 40, C.white, r = 0.5, o = false, t = 0.55 },
}

D.news = {
	{ "r", 8, 14, 84, 74, C.white, r = 0.1 },
	{ "r", 18, 22, 64, 12, C.greyDark, r = 0.3, o = false },
	{ "r", 18, 42, 30, 7, C.grey, r = 0.5, o = false },
	{ "r", 18, 54, 30, 7, C.grey, r = 0.5, o = false },
	{ "r", 18, 66, 30, 7, C.grey, r = 0.5, o = false },
	{ "r", 54, 42, 28, 31, C.sky, r = 0.12 },
}

D.gift = {
	{ "c", 22, 6, 30, 26, C.yellow },
	{ "c", 48, 6, 30, 26, C.yellow },
	{ "r", 14, 40, 72, 52, C.red, r = 0.12 },
	{ "r", 8, 26, 84, 20, C.redDark, r = 0.2 },
	{ "r", 43, 26, 14, 66, C.yellow, r = 0.1 },
	{ "r", 44, 27, 12, 64, C.yellow, o = false },
}

D.clock = {
	{ "c", 8, 8, 84, 84, C.white },
	{ "r", 46, 20, 8, 34, INK, r = 0.5, o = false },
	{ "r", 46, 46, 28, 8, INK, r = 0.5, o = false },
	{ "c", 43, 43, 14, 14, C.red, o = false },
}

D.briefcase = {
	{ "ring", 32, 12, 36, 30, C.woodDark, 9 },
	{ "r", 6, 30, 88, 60, C.wood, r = 0.16 },
	{ "r", 6, 52, 88, 8, C.woodDark, o = false },
	{ "r", 42, 46, 16, 18, C.gold, r = 0.2 },
}

D.sofa = {
	{ "r", 14, 22, 72, 38, C.blue, r = 0.25 },
	{ "r", 12, 50, 76, 26, C.blueLight, r = 0.25 },
	{ "r", 2, 38, 20, 42, C.blueDark, r = 0.4 },
	{ "r", 78, 38, 20, 42, C.blueDark, r = 0.4 },
	{ "r", 12, 78, 10, 12, C.woodDark, r = 0.2 },
	{ "r", 78, 78, 10, 12, C.woodDark, r = 0.2 },
}

D.tree = {
	{ "r", 42, 54, 16, 40, C.wood, r = 0.25 },
	{ "c", 8, 30, 46, 40, C.leafDark },
	{ "c", 46, 30, 46, 40, C.leafDark },
	{ "c", 20, 4, 60, 54, C.leaf },
	{ "c", 30, 14, 16, 12, C.white, o = false, t = 0.55 },
}

D.store = {
	{ "r", 12, 36, 76, 56, C.cream, r = 0.06 },
	{ "r", 6, 20, 88, 22, C.red, r = 0.2 },
	{ "r", 24, 21, 14, 20, C.white, o = false },
	{ "r", 52, 21, 14, 20, C.white, o = false },
	{ "r", 80, 21, 10, 20, C.white, o = false, r = 0.2 },
	{ "r", 40, 58, 20, 34, C.wood, r = 0.15 },
	{ "r", 18, 54, 16, 18, C.sky, r = 0.15 },
	{ "r", 66, 54, 16, 18, C.sky, r = 0.15 },
}

-- city building ------------------------------------------------------------------------------------

D.crane = {
	{ "r", 30, 86, 40, 10, C.greyDark, r = 0.4 },
	{ "r", 40, 22, 16, 68, C.yellow, r = 0.08 },
	{ "r", 6, 14, 88, 12, C.yellow, r = 0.3 },
	{ "t", 36, 0, 24, "up", C.orange },
	{ "r", 8, 26, 18, 14, C.greyDark, r = 0.2 },
	{ "r", 76, 26, 4, 26, C.greyDark, o = false },
	{ "r", 66, 50, 24, 18, C.orange, r = 0.15 },
	{ "r", 43, 32, 10, 4, C.orangeDark, rot = 40, o = false },
	{ "r", 43, 48, 10, 4, C.orangeDark, rot = -40, o = false },
	{ "r", 43, 64, 10, 4, C.orangeDark, rot = 40, o = false },
	{ "r", 43, 78, 10, 4, C.orangeDark, rot = -40, o = false },
	{ "r", 18, 17, 12, 4, C.orangeDark, rot = 40, o = false },
	{ "r", 62, 17, 12, 4, C.orangeDark, rot = -40, o = false },
}

D.hardhat = {
	{ "half", 16, 18, 68, 76, C.yellow, dir = "up" },
	{ "r", 4, 52, 92, 16, C.orange, r = 0.5 },
	{ "r", 44, 18, 12, 36, C.goldLight, r = 0.4, o = false },
	{ "r", 26, 30, 8, 14, C.white, r = 0.5, rot = -25, o = false, t = 0.4 },
}

D.blueprint = {
	{ "r", 8, 12, 84, 76, C.blue, r = 0.08 },
	{ "r", 8, 12, 12, 76, C.blueDark, r = 0.2 },
	{ "r", 30, 46, 46, 32, C.blue, o = false },
	{ "r", 30, 46, 46, 4, C.white, o = false },
	{ "r", 30, 74, 46, 4, C.white, o = false },
	{ "r", 30, 46, 4, 32, C.white, o = false },
	{ "r", 72, 46, 4, 32, C.white, o = false },
	{ "r", 44, 26, 4, 30, C.white, rot = -50, o = false },
	{ "r", 58, 26, 4, 30, C.white, rot = 50, o = false },
	{ "r", 47, 62, 12, 16, C.white, o = false },
}

D.city = {
	{ "r", 4, 40, 28, 54, C.blueLight, r = 0.08 },
	{ "r", 34, 12, 30, 82, C.blue, r = 0.08 },
	{ "r", 66, 30, 28, 64, C.purple, r = 0.08 },
	{ "r", 46, 4, 6, 10, C.greyDark, o = false },
}
do
	-- lit windows in rows
	for row = 0, 5 do
		for col = 0, 1 do
			table.insert(D.city, { "r", 40 + col * 11, 20 + row * 11, 7, 6, C.goldLight, o = false })
		end
	end
	for row = 0, 3 do
		table.insert(D.city, { "r", 10, 48 + row * 11, 7, 6, C.white, o = false })
		table.insert(D.city, { "r", 19, 48 + row * 11, 7, 6, C.white, o = false })
		table.insert(D.city, { "r", 72, 38 + row * 13, 7, 7, C.goldLight, o = false })
		table.insert(D.city, { "r", 82, 38 + row * 13, 7, 7, C.goldLight, o = false })
	end
end

D.road = {
	{ "r", 18, 4, 64, 92, C.greyDark, r = 0.1 },
	{ "r", 46, 10, 8, 16, C.yellow, r = 0.3, o = false },
	{ "r", 46, 42, 8, 16, C.yellow, r = 0.3, o = false },
	{ "r", 46, 74, 8, 16, C.yellow, r = 0.3, o = false },
	{ "r", 22, 4, 4, 92, C.white, o = false },
	{ "r", 74, 4, 4, 92, C.white, o = false },
}

D.coins = {
	{ "c", 36, 30, 60, 60, C.goldDark },
	{ "c", 41, 34, 50, 50, C.gold, o = false },
	{ "c", 49, 43, 34, 34, C.goldDark, o = false, dent = true },
	{ "c", 4, 10, 60, 60, C.goldDark },
	{ "c", 9, 14, 50, 50, C.gold, o = false },
	{ "c", 17, 23, 34, 34, C.goldDark, o = false, dent = true },
	{ "r", 14, 17, 8, 16, C.white, r = 0.5, rot = 35, o = false, t = 0.35 },
}

-- furniture tabs --------------------------------------------------------------------------------------

D.chair = {
	{ "r", 26, 6, 48, 48, C.wood, r = 0.16 },
	{ "r", 34, 14, 32, 30, C.woodLight, r = 0.16, o = false },
	{ "r", 18, 50, 64, 16, C.woodDark, r = 0.3 },
	{ "r", 22, 64, 12, 30, C.woodDark, r = 0.3 },
	{ "r", 66, 64, 12, 30, C.woodDark, r = 0.3 },
}

D.table = {
	{ "r", 14, 42, 12, 50, C.woodDark, r = 0.3 },
	{ "r", 74, 42, 12, 50, C.woodDark, r = 0.3 },
	{ "r", 4, 28, 92, 18, C.wood, r = 0.4 },
	{ "r", 14, 31, 30, 6, C.white, r = 0.5, o = false, t = 0.5 },
}

D.bed = {
	{ "r", 4, 20, 18, 72, C.wood, r = 0.35 },
	{ "r", 16, 46, 80, 28, C.white, r = 0.25 },
	{ "r", 22, 38, 26, 18, C.cream, r = 0.45 },
	{ "r", 42, 42, 54, 34, C.blue, r = 0.28 },
	{ "r", 18, 72, 10, 16, C.woodDark, r = 0.2 },
	{ "r", 84, 72, 10, 16, C.woodDark, r = 0.2 },
}

D.cabinet = {
	{ "r", 14, 8, 72, 84, C.wood, r = 0.1 },
	{ "r", 22, 16, 56, 20, C.woodLight, r = 0.16 },
	{ "r", 22, 40, 56, 20, C.woodLight, r = 0.16 },
	{ "r", 22, 64, 56, 20, C.woodLight, r = 0.16 },
	{ "r", 42, 23, 16, 6, C.gold, r = 0.5 },
	{ "r", 42, 47, 16, 6, C.gold, r = 0.5 },
	{ "r", 42, 71, 16, 6, C.gold, r = 0.5 },
}

D.pot = {
	{ "c", 40, 12, 20, 16, C.greyDark },
	{ "r", 2, 46, 18, 12, C.redDark, r = 0.5 },
	{ "r", 80, 46, 18, 12, C.redDark, r = 0.5 },
	{ "r", 14, 38, 72, 50, C.red, r = 0.25 },
	{ "r", 8, 26, 84, 16, C.redDark, r = 0.5 },
	{ "r", 22, 48, 10, 28, C.white, r = 0.5, o = false, t = 0.5 },
}

D.bath = {
	{ "r", 62, 10, 12, 36, C.steel, r = 0.4 },
	{ "r", 48, 10, 26, 12, C.steel, r = 0.4 },
	{ "r", 16, 76, 12, 16, C.gold, r = 0.3 },
	{ "r", 72, 76, 12, 16, C.gold, r = 0.3 },
	{ "r", 6, 40, 88, 42, C.white, r = 0.35 },
	{ "r", 14, 42, 72, 12, C.sky, r = 0.5, o = false },
	{ "c", 22, 26, 14, 14, C.blueLight },
	{ "c", 36, 20, 10, 10, C.blueLight },
}

D.lamp = {
	{ "r", 44, 40, 12, 44, C.greyDark, r = 0.4 },
	{ "r", 24, 80, 52, 14, C.greyDark, r = 0.45 },
	{ "r", 18, 6, 64, 40, C.yellow, r = 0.22 },
	{ "r", 26, 12, 12, 26, C.white, r = 0.5, o = false, t = 0.45 },
}

D.gamepad = {
	{ "r", 4, 26, 92, 52, C.purple, r = 0.48 },
	{ "r", 18, 46, 26, 10, C.white, r = 0.3, o = false },
	{ "r", 26, 38, 10, 26, C.white, r = 0.3, o = false },
	{ "c", 62, 36, 13, 13, C.red },
	{ "c", 74, 50, 13, 13, C.yellow },
}

D.plant = {
	{ "r", 18, 14, 22, 46, C.leaf, r = 0.5, rot = -30 },
	{ "r", 60, 14, 22, 46, C.leaf, r = 0.5, rot = 30 },
	{ "r", 39, 4, 22, 52, C.leafDark, r = 0.5 },
	{ "r", 26, 60, 48, 32, C.orange, r = 0.16 },
	{ "r", 20, 52, 60, 14, C.orangeDark, r = 0.4 },
}

D.frame = {
	{ "r", 8, 12, 84, 76, C.woodDark, r = 0.08 },
	{ "r", 18, 22, 64, 56, C.sky, r = 0.05 },
	{ "c", 26, 28, 16, 16, C.yellow, o = false },
	{ "r", 18, 54, 64, 24, C.leaf, o = false },
	{ "c", 40, 46, 40, 28, C.leafDark, o = false },
}

D.flower = {
	{ "r", 46, 46, 8, 48, C.leafDark, r = 0.4 },
	{ "r", 54, 62, 26, 14, C.leaf, r = 0.5, rot = -25 },
	{ "r", 20, 66, 26, 14, C.leaf, r = 0.5, rot = 25 },
}
do
	for i = 0, 4 do
		local a = math.rad(i * 72)
		table.insert(D.flower, { "c", 50 + math.sin(a) * 20 - 14, 30 - math.cos(a) * 20 - 14, 28, 28, C.pink })
	end
	table.insert(D.flower, { "c", 38, 18, 24, 24, C.yellow })
end

D.fence = {
	{ "r", 2, 34, 96, 12, C.woodLight, r = 0.3 },
	{ "r", 2, 62, 96, 12, C.woodLight, r = 0.3 },
	{ "r", 8, 14, 18, 80, C.white, r = 0.45 },
	{ "r", 41, 8, 18, 86, C.white, r = 0.45 },
	{ "r", 74, 14, 18, 80, C.white, r = 0.45 },
}

D.path = {
	{ "c", 8, 60, 38, 28, C.stone },
	{ "c", 50, 42, 34, 26, C.stone },
	{ "c", 22, 18, 30, 22, C.stone },
	{ "c", 62, 8, 28, 20, C.stone },
}

-- the creator's categories -------------------------------------------------------------------------

D.hair = {
	{ "c", 12, 6, 76, 74, C.woodDark },
	{ "c", 24, 26, 52, 62, C.skin },
	{ "r", 16, 8, 68, 30, C.woodDark, r = 0.45 },
	{ "c", 34, 50, 8, 10, INK, o = false },
	{ "c", 58, 50, 8, 10, INK, o = false },
}

D.hat = {
	{ "r", 24, 18, 52, 50, C.purple, r = 0.2 },
	{ "r", 24, 50, 52, 10, C.yellow, o = false },
	{ "r", 4, 62, 92, 16, C.purpleDark, r = 0.5 },
}

D.pants = {
	{ "r", 18, 28, 30, 66, C.blue, r = 0.18 },
	{ "r", 52, 28, 30, 66, C.blue, r = 0.18 },
	{ "r", 16, 12, 68, 24, C.blueDark, r = 0.22 },
	{ "r", 20, 36, 60, 10, C.blue, o = false },
}

D.shoe = {
	{ "r", 12, 28, 52, 44, C.red, r = 0.35 },
	{ "r", 36, 44, 56, 28, C.red, r = 0.45 },
	{ "r", 6, 64, 90, 18, C.white, r = 0.45 },
	{ "r", 22, 38, 26, 6, C.white, r = 0.5, o = false },
	{ "r", 22, 50, 26, 6, C.white, r = 0.5, o = false },
}

-- a whole body, standing: the creator's Bodies
D.figure = {
	{ "c", 37, 4, 26, 26, C.blue },
	{ "r", 14, 34, 72, 14, C.blue, r = 0.5 },
	{ "r", 36, 34, 28, 36, C.blue, r = 0.2 },
	{ "r", 36, 62, 12, 34, C.blueDark, r = 0.4 },
	{ "r", 52, 62, 12, 34, C.blueDark, r = 0.4 },
}

-- the torso, the arms and the legs, each by itself: Body parts
D.limbs = {
	{ "r", 32, 10, 36, 42, C.blue, r = 0.15 },
	{ "r", 8, 10, 16, 42, C.skin, r = 0.35 },
	{ "r", 76, 10, 16, 42, C.skin, r = 0.35 },
	{ "r", 32, 58, 15, 34, C.blueDark, r = 0.3 },
	{ "r", 53, 58, 15, 34, C.blueDark, r = 0.3 },
}

-- what you own: My items
D.backpack = {
	{ "ring", 36, 4, 28, 26, C.greenDark, 8 },
	{ "r", 16, 20, 68, 74, C.green, r = 0.3 },
	{ "r", 30, 54, 40, 26, C.greenDark, r = 0.25, o = false },
}

-- a look put away for later: Outfits
D.hanger = {
	{ "ring", 38, 4, 24, 24, C.steelDark, 7 },
	{ "t", 8, 34, 84, "up", C.wood },
	{ "t", 26, 48, 48, "up", C.cream, o = false },
	{ "r", 8, 68, 84, 10, C.wood, r = 0.5 },
}

-- a card with your face on it: My avatars
D.idcard = {
	{ "r", 6, 18, 88, 64, C.blueLight, r = 0.14 },
	{ "c", 20, 30, 22, 22, C.blueDark, o = false },
	{ "r", 14, 54, 34, 18, C.blueDark, r = 0.45, o = false },
	{ "r", 56, 34, 28, 8, C.blueDark, r = 0.5, o = false },
	{ "r", 56, 50, 28, 8, C.blueDark, r = 0.5, o = false },
}

D.ruler = {
	{ "r", 4, 34, 92, 32, C.yellow, r = 0.15 },
}
do
	for i = 0, 7 do
		local x = 13 + i * 10.5
		table.insert(D.ruler, { "r", x, 34, 4, if i % 2 == 0 then 16 else 10, INK, o = false })
	end
end

D.music = {
	{ "r", 54, 10, 12, 58, C.purple, r = 0.4 },
	{ "r", 58, 8, 30, 18, C.purple, r = 0.4, rot = 24 },
	{ "c", 22, 54, 42, 34, C.purple },
}

D.dice = {
	{ "r", 10, 10, 80, 80, C.white, r = 0.2 },
	{ "c", 22, 22, 16, 16, INK, o = false },
	{ "c", 62, 22, 16, 16, INK, o = false },
	{ "c", 42, 42, 16, 16, C.red, o = false },
	{ "c", 22, 62, 16, 16, INK, o = false },
	{ "c", 62, 62, 16, 16, INK, o = false },
}

D.alert = {
	{ "c", 6, 6, 88, 88, C.red },
	{ "r", 42, 18, 16, 44, C.white, r = 0.5, o = false },
	{ "c", 41, 66, 18, 18, C.white, o = false },
}

-- the moods over a villager's head (Util/Bubble's MoodIcons), as shapes
D.bulb = {
	{ "c", 20, 6, 60, 60, C.gold },
	{ "r", 34, 58, 32, 12, C.gold },
	{ "r", 34, 74, 32, 16, C.goldDark, r = 0.3 },
}
D.question = {
	{ "ring", 28, 6, 44, 40, C.blue, 12 },
	{ "r", 44, 44, 13, 22, C.blue, r = 0.3 },
	{ "c", 41, 74, 18, 18, C.blue },
}
D.sparkle = {
	{ "r", 44, 6, 12, 88, C.gold, r = 0.5 },
	{ "r", 6, 44, 88, 12, C.gold, r = 0.5 },
	{ "r", 33, 33, 34, 34, C.gold, r = 0.1, rot = 45 },
}
D.anger = {
	{ "r", 10, 28, 24, 10, C.red, r = 0.5 },
	{ "r", 28, 10, 10, 24, C.red, r = 0.5 },
	{ "r", 66, 28, 24, 10, C.red, r = 0.5 },
	{ "r", 62, 10, 10, 24, C.red, r = 0.5 },
	{ "r", 66, 62, 24, 10, C.red, r = 0.5 },
	{ "r", 62, 66, 10, 24, C.red, r = 0.5 },
	{ "r", 10, 62, 24, 10, C.red, r = 0.5 },
	{ "r", 28, 66, 10, 24, C.red, r = 0.5 },
}

-- wall and roof styles --------------------------------------------------------------------------------

D.wallHalf = {
	{ "r", 4, 44, 44, 22, C.brick, r = 0.15 },
	{ "r", 52, 44, 44, 22, C.brick, r = 0.15 },
	{ "r", 4, 70, 22, 22, C.brickDark, r = 0.15 },
	{ "r", 30, 70, 40, 22, C.brick, r = 0.15 },
	{ "r", 74, 70, 22, 22, C.brickDark, r = 0.15 },
	{ "r", 2, 34, 96, 12, C.stone, r = 0.4 },
}

D.wallGlass = {
	{ "r", 6, 6, 88, 88, C.greyDark, r = 0.08 },
	{ "r", 14, 14, 72, 72, C.sky, r = 0.05 },
	{ "r", 22, 20, 12, 44, C.white, r = 0.5, rot = 25, o = false, t = 0.35 },
	{ "r", 44, 30, 8, 26, C.white, r = 0.5, rot = 25, o = false, t = 0.45 },
}

D.railing = {
	{ "r", 2, 22, 96, 12, C.greyDark, r = 0.4 },
	{ "r", 12, 30, 10, 62, C.grey, r = 0.4 },
	{ "r", 34, 30, 10, 62, C.grey, r = 0.4 },
	{ "r", 56, 30, 10, 62, C.grey, r = 0.4 },
	{ "r", 78, 30, 10, 62, C.grey, r = 0.4 },
}

D.hedge = {
	{ "r", 4, 30, 92, 62, C.leafDark, r = 0.3 },
	{ "c", 4, 16, 34, 34, C.leaf },
	{ "c", 32, 10, 36, 36, C.leaf },
	{ "c", 62, 16, 34, 34, C.leaf },
	{ "r", 8, 34, 84, 54, C.leafDark, r = 0.25, o = false },
}

D.stoneWall = {
	{ "c", 4, 54, 34, 38, C.stone },
	{ "c", 34, 58, 32, 34, C.grey },
	{ "c", 62, 54, 34, 38, C.stone },
	{ "c", 16, 22, 34, 36, C.grey },
	{ "c", 48, 20, 36, 38, C.stone },
}

-- the fences that came later (Plan.WallStyles)
D.brickWall = {
	{ "r", 4, 44, 44, 22, C.brick, r = 0.15 },
	{ "r", 52, 44, 44, 22, C.brick, r = 0.15 },
	{ "r", 4, 70, 22, 22, C.brickDark, r = 0.15 },
	{ "r", 30, 70, 40, 22, C.brick, r = 0.15 },
	{ "r", 74, 70, 22, 22, C.brickDark, r = 0.15 },
	{ "r", 2, 28, 96, 14, C.stone, r = 0.3 },
}

D.railFence = {
	{ "r", 16, 10, 14, 82, C.white, r = 0.2 },
	{ "r", 70, 10, 14, 82, C.white, r = 0.2 },
	{ "r", 4, 24, 92, 12, C.cream, r = 0.3 },
	{ "r", 4, 48, 92, 12, C.cream, r = 0.3 },
	{ "r", 4, 72, 92, 12, C.cream, r = 0.3 },
}

D.ironFence = {
	{ "r", 4, 36, 92, 9, C.greyDark, r = 0.4 },
	{ "r", 4, 70, 92, 9, C.greyDark, r = 0.4 },
	{ "r", 12, 20, 9, 72, C.greyDark, r = 0.4 },
	{ "r", 36, 20, 9, 72, C.greyDark, r = 0.4 },
	{ "r", 60, 20, 9, 72, C.greyDark, r = 0.4 },
	{ "r", 82, 20, 9, 72, C.greyDark, r = 0.4 },
	{ "t", 9, 8, 15, "up", C.greyDark },
	{ "t", 33, 8, 15, "up", C.greyDark },
	{ "t", 57, 8, 15, "up", C.greyDark },
	{ "t", 79, 8, 15, "up", C.greyDark },
}

D.bamboo = {
	{ "r", 8, 12, 16, 80, C.green, r = 0.45 },
	{ "r", 30, 6, 16, 86, C.greenDark, r = 0.45 },
	{ "r", 52, 14, 16, 78, C.green, r = 0.45 },
	{ "r", 74, 8, 16, 84, C.greenDark, r = 0.45 },
	{ "r", 4, 38, 92, 6, C.wood, r = 0.5, o = false },
	{ "r", 4, 66, 92, 6, C.wood, r = 0.5, o = false },
}

D.logFence = {
	{ "r", 14, 8, 18, 84, C.woodDark, r = 0.5 },
	{ "r", 68, 8, 18, 84, C.woodDark, r = 0.5 },
	{ "r", 4, 30, 92, 16, C.wood, r = 0.5 },
	{ "r", 4, 60, 92, 16, C.wood, r = 0.5 },
}

D.wovenFence = {
	{ "r", 6, 18, 88, 64, C.wood, r = 0.1 },
	{ "r", 20, 6, 10, 88, C.woodDark, r = 0.3 },
	{ "r", 70, 6, 10, 88, C.woodDark, r = 0.3 },
	{ "r", 6, 38, 88, 5, C.woodDark, r = 0.5, o = false },
	{ "r", 6, 58, 88, 5, C.woodDark, r = 0.5, o = false },
}

D.ropeFence = {
	{ "r", 12, 18, 14, 76, C.woodDark, r = 0.3 },
	{ "r", 74, 18, 14, 76, C.woodDark, r = 0.3 },
	{ "t", 10, 6, 18, "up", C.woodDark },
	{ "t", 72, 6, 18, "up", C.woodDark },
	{ "r", 22, 40, 56, 8, C.woodLight, r = 0.5, rot = 8 },
	{ "r", 22, 64, 56, 8, C.woodLight, r = 0.5, rot = -8 },
}

D.glassRail = {
	{ "r", 4, 10, 92, 12, C.greyDark, r = 0.4 },
	{ "r", 8, 18, 10, 76, C.grey, r = 0.3 },
	{ "r", 82, 18, 10, 76, C.grey, r = 0.3 },
	{ "r", 24, 30, 52, 56, C.sky, r = 0.08 },
	{ "r", 34, 40, 8, 30, C.white, r = 0.5, rot = 35, o = false, t = 0.35 },
}

D.lightRail = {
	{ "r", 4, 14, 92, 12, C.greyDark, r = 0.5 },
	{ "r", 4, 68, 92, 12, C.greyDark, r = 0.5 },
	{ "r", 14, 14, 12, 78, C.greyDark, r = 0.3 },
	{ "r", 74, 14, 12, 78, C.greyDark, r = 0.3 },
	{ "r", 38, 34, 24, 24, C.sky, r = 0.1, rot = 45 },
}

D.pillar = {
	{ "r", 14, 8, 72, 14, C.stone, r = 0.2 },
	{ "r", 26, 24, 48, 52, C.greyLight },
	{ "r", 40, 24, 4, 52, C.grey, o = false },
	{ "r", 56, 24, 4, 52, C.grey, o = false },
	{ "r", 14, 78, 72, 14, C.stone, r = 0.2 },
}

D.shapes = {
	{ "r", 8, 40, 48, 48, C.blue, r = 0.1 },
	{ "c", 52, 8, 40, 40, C.pink },
	{ "t", 54, 52, 40, "up", C.yellow },
	{ "r", 54, 72, 40, 20, C.yellow, r = 0.05 },
}

D.picture = {
	{ "r", 6, 14, 88, 72, C.sky, r = 0.1 },
	{ "t", 14, 46, 44, "up", C.green, o = false },
	{ "t", 40, 40, 48, "up", C.greenDark, o = false },
	{ "c", 64, 22, 14, 14, C.yellow, o = false },
}

D.marking = {
	{ "t", 22, 6, 56, "up", C.white },
	{ "r", 40, 34, 20, 20, C.white, r = 0.1 },
	{ "r", 40, 60, 20, 12, C.white, r = 0.2 },
	{ "r", 40, 80, 20, 12, C.white, r = 0.2 },
}

-- water: a drop, a point on a round
D.water = {
	{ "r", 29, 14, 42, 42, C.blue, r = 0.1, rot = 45 },
	{ "c", 19, 34, 62, 62, C.blue },
	{ "c", 30, 60, 12, 18, C.white, o = false, t = 0.45 },
}

D.styles = {
	{ "c", 6, 6, 88, 88, C.woodLight },
	{ "c", 22, 34, 16, 16, C.red, o = false },
	{ "c", 40, 16, 16, 16, C.yellow, o = false },
	{ "c", 62, 24, 16, 16, C.blue, o = false },
	{ "c", 26, 58, 16, 16, C.green, o = false },
	{ "c", 60, 58, 18, 18, C.cream, o = false },
}

D.mug = {
	{ "r", 12, 30, 58, 62, C.red, r = 0.2 },
	{ "ring", 58, 42, 30, 34, C.red, 8 },
	{ "r", 26, 6, 8, 18, C.white, r = 0.5, t = 0.3 },
	{ "r", 46, 6, 8, 18, C.white, r = 0.5, t = 0.3 },
}

D.rocket = {
	{ "r", 34, 6, 32, 64, C.white, r = 0.45 },
	{ "t", 14, 50, 24, "left", C.red },
	{ "t", 62, 50, 24, "right", C.red },
	{ "c", 42, 26, 16, 16, C.sky, o = false },
	{ "t", 38, 72, 24, "down", C.orange },
}

D.anchor = {
	{ "ring", 38, 4, 24, 24, C.blueDark, 7 },
	{ "r", 44, 26, 12, 62, C.blueDark, r = 0.3 },
	{ "r", 26, 34, 48, 10, C.blueDark, r = 0.5 },
	{ "half", 12, 50, 76, 44, C.blueDark },
}

D.barrel = {
	{ "c", 14, 4, 72, 92, C.wood },
	{ "r", 12, 24, 76, 8, C.woodDark, r = 0.5, o = false },
	{ "r", 12, 68, 76, 8, C.woodDark, r = 0.5, o = false },
}

D.gem = {
	{ "r", 22, 10, 56, 26, C.purple, r = 0.1 },
	{ "t", 6, 36, 88, "down", C.purple },
	{ "r", 4, 34, 92, 6, C.purpleDark, r = 0.5, o = false },
}

D.balloon = {
	{ "c", 18, 4, 64, 70, C.pink },
	{ "t", 42, 72, 16, "up", C.pink },
	{ "r", 48, 78, 4, 18, C.greyDark, r = 0.5 },
	{ "c", 30, 16, 14, 18, C.white, o = false, t = 0.4 },
}

D.roofHip = {
	{ "t", 4, 22, 46, "left", C.redDark },
	{ "t", 73, 22, 46, "right", C.redDark },
	{ "r", 26, 22, 48, 46, C.red, r = 0.05 },
	{ "r", 2, 64, 96, 12, C.redDark, r = 0.5 },
	{ "r", 18, 76, 64, 16, C.cream, r = 0.1 },
}

D.roofPyramid = {
	{ "t", 6, 8, 88, "up", C.red },
	{ "r", 2, 50, 96, 12, C.redDark, r = 0.5 },
	{ "r", 18, 62, 64, 28, C.cream, r = 0.1 },
}

D.roofShed = {
	{ "r", 18, 44, 64, 46, C.cream, r = 0.06 },
	{ "r", 4, 30, 92, 16, C.red, r = 0.4, rot = -16 },
}

D.roofFlat = {
	{ "r", 14, 40, 72, 50, C.cream, r = 0.06 },
	{ "r", 6, 28, 88, 16, C.greyDark, r = 0.35 },
	{ "r", 30, 52, 16, 16, C.sky, r = 0.15 },
	{ "r", 56, 52, 16, 16, C.sky, r = 0.15 },
}

-- weather -----------------------------------------------------------------------------------------

D.sun = {}
do
	for i = 0, 7 do
		local a = math.rad(i * 45)
		table.insert(D.sun, {
			"r",
			50 + math.sin(a) * 38 - 5,
			50 - math.cos(a) * 38 - 10,
			10,
			20,
			C.orange,
			r = 0.5,
			rot = i * 45,
		})
	end
	table.insert(D.sun, { "c", 24, 24, 52, 52, C.yellow })
	table.insert(D.sun, { "c", 34, 32, 12, 10, C.white, o = false, t = 0.4 })
end

D.moon = {
	{ "c", 12, 12, 76, 76, Color3.fromRGB(250, 240, 190) },
	{ "c", 30, 30, 16, 16, Color3.fromRGB(226, 214, 160), o = false },
	{ "c", 56, 52, 12, 12, Color3.fromRGB(226, 214, 160), o = false },
	{ "c", 46, 22, 8, 8, Color3.fromRGB(226, 214, 160), o = false },
}

local function cloud(color: Color3, y: number?): { any }
	local dy = y or 0
	return {
		{ "c", 6, 40 + dy, 40, 36, color },
		{ "c", 28, 18 + dy, 48, 48, color },
		{ "c", 54, 34 + dy, 40, 40, color },
		{ "r", 12, 50 + dy, 76, 24, color, r = 0.5 },
		{ "c", 9, 43 + dy, 34, 30, color, o = false },
		{ "c", 31, 21 + dy, 42, 42, color, o = false },
		{ "c", 57, 37 + dy, 34, 34, color, o = false },
		{ "r", 14, 52 + dy, 72, 19, color, r = 0.5, o = false },
	}
end

D.cloud = cloud(C.white)

D.rain = cloud(C.greyLight, -12)
for i, x in { 24, 46, 68 } do
	table.insert(D.rain, { "r", x, 70 + (i % 2) * 6, 10, 22, C.blue, r = 0.5, rot = 15 })
end

D.storm = cloud(C.grey, -12)
table.insert(D.storm, { "r", 40, 56, 16, 30, C.yellow, r = 0.15, rot = 20 })
table.insert(D.storm, { "r", 46, 72, 14, 24, C.yellow, r = 0.15, rot = -20 })

D.snow = cloud(C.white, -12)
for i, x in { 22, 44, 66 } do
	table.insert(D.snow, { "c", x, 72 + (i % 2) * 8, 14, 14, C.blueLight })
end

D.blossom = {}
do
	for i = 0, 4 do
		local a = math.rad(i * 72)
		table.insert(D.blossom, { "c", 50 + math.sin(a) * 24 - 18, 50 - math.cos(a) * 24 - 18, 36, 36, C.pink })
	end
	table.insert(D.blossom, { "c", 38, 38, 24, 24, C.yellow })
end

D.leaves = {
	{ "r", 26, 8, 44, 82, C.orange, r = 0.5, rot = 40 },
	{ "r", 46, 16, 5, 66, C.orangeDark, r = 0.5, rot = 40, o = false },
}

-- the foods (UI/ItemArt) ---------------------------------------------------------------------------
-- Their silhouettes again, roughly, for when the game can't make pictures: the few big shapes in
-- one colour and the cuts that name the thing (`INK`, inside the shape they cut: the holes in the
-- cheese, the scores in the bread) drawn in the hole colour, as the icons above are. Where the
-- picture only has clear space between its parts (the apple's leaf) the parts are just laid
-- together. Icons.item draws them in the food's own colour.

local function food(color: Color3, shapes: { any }): { any }
	for _, s in shapes do
		if s[6] == nil then
			s[6] = color
		end
	end
	return shapes
end

D.apple = food(C.red, {
	{ "c", 12, 26, 76, 64 },
	{ "r", 47, 8, 9, 26, nil, r = 0.5, rot = 10 },
	{ "c", 60, 9, 28, 14, nil, rot = -25 },
})

D.goldapple = food(C.gold, {
	{ "c", 12, 26, 76, 64 },
	{ "r", 47, 8, 9, 26, nil, r = 0.5, rot = 10 },
	{ "c", 60, 9, 28, 14, nil, rot = -25 },
	{ "r", 12, 12, 16, 16, nil, r = 0.15, rot = 45 },
})

D.bread = food(C.wood, {
	{ "half", 10, 25, 80, 80, nil, dir = "up" },
	{ "r", 10, 55, 80, 27, nil, r = 0.2 },
	{ "r", 32, 42, 9, 24, INK, r = 0.5, rot = 35, o = false },
	{ "r", 59, 42, 9, 24, INK, r = 0.5, rot = 35, o = false },
})

D.carrot = food(C.orange, {
	{ "r", 26, 30, 22, 70, nil, r = 0.5, rot = 45 },
	{ "c", 55, 7, 15, 30, nil, rot = -22 },
	{ "c", 67, 25, 26, 15, nil, rot = -21 },
})

D.cheese = food(C.yellow, {
	{ "t", 32, 8, 60, "up" },
	{ "r", 8, 42, 84, 40, nil, r = 0.08 },
	{ "c", 22, 52, 21, 21, INK, o = false },
	{ "c", 57, 48, 19, 19, INK, o = false },
})

D.soup = food(C.wood, {
	{ "r", 33, 10, 9, 30, nil, r = 0.5, rot = 12 },
	{ "r", 58, 10, 9, 30, nil, r = 0.5, rot = 12 },
	{ "half", 10, 17, 80, 70 },
	{ "r", 10, 48, 80, 10, nil, r = 0.5 },
	{ "r", 12, 58, 76, 5, INK, o = false },
})

D.skewer = food(C.blue, {
	{ "r", 46, 4, 9, 92, nil, r = 0.5, rot = 45 },
	{ "c", 36, 18, 40, 53, nil, rot = 45 },
	{ "r", 22, 60, 18, 18, nil, r = 0.15, rot = 45 },
	{ "c", 56, 30, 14, 14, INK, o = false },
})

D.tart = food(C.purple, {
	{ "r", 10, 67, 80, 19, nil, r = 0.15 },
	{ "c", 14, 40, 28, 28 },
	{ "c", 58, 40, 28, 28 },
	{ "c", 35, 26, 30, 30 },
})

D.honeycake = food(C.gold, {
	{ "t", 20, 12, 64, "up" },
	{ "r", 10, 48, 80, 36, nil, r = 0.05 },
	{ "r", 30, 46, 7, 15, INK, r = 0.5, o = false },
	{ "r", 59, 46, 7, 11, INK, r = 0.5, o = false },
	{ "r", 10, 66, 80, 6, INK, o = false },
})

D.riceball = food(C.greyLight, {
	{ "r", 22, 18, 56, 56, nil, r = 0.25, rot = 45 },
	{ "r", 8, 56, 84, 32, nil, r = 0.4 },
	{ "r", 32, 57, 36, 31, INK, o = false },
	{ "r", 37, 62, 26, 26, nil, o = false },
})

D.pancakes = food(C.woodLight, {
	{ "r", 35, 14, 30, 15, nil, r = 0.2 },
	{ "r", 10, 36, 80, 18, nil, r = 0.5 },
	{ "r", 8, 53, 84, 18, nil, r = 0.5 },
	{ "r", 10, 70, 80, 18, nil, r = 0.5 },
	{ "r", 16, 52, 68, 4, INK, o = false },
	{ "r", 16, 69, 68, 4, INK, o = false },
})

D.curry = food(C.orange, {
	{ "half", 12, 27, 50, 62, nil, dir = "up" },
	{ "half", 44, 40, 46, 36, nil, dir = "up" },
	{ "half", 8, 44, 84, 44 },
})

D.pie = food(C.orange, {
	{ "r", 12, 58, 76, 24, nil, r = 0.15 },
	{ "c", 8, 40, 84, 33 },
	{ "ring", 23, 50, 54, 15, C.woodDark, 8, o = false },
	{ "c", 35, 17, 30, 30 },
})

D.icecream = food(C.pink, {
	{ "t", 22, 58, 56, "down" },
	{ "half", 21, 17, 58, 58, nil, dir = "up" },
	{ "r", 21, 40, 58, 15, nil, r = 0.4 },
})

D.salad = food(C.green, {
	{ "c", 12, 30, 34, 34 },
	{ "c", 54, 30, 34, 34 },
	{ "c", 29, 13, 42, 42 },
	{ "r", 12, 53, 76, 8, INK, o = false },
	{ "half", 10, 39, 80, 49 },
})

D.chocolate = food(C.woodDark, {
	{ "r", 19, 8, 62, 84, nil, r = 0.08 },
	{ "r", 46, 8, 8, 84, INK, o = false },
	{ "r", 19, 32, 62, 8, INK, o = false },
	{ "r", 19, 59, 62, 8, INK, o = false },
})

D.pudding = food(C.gold, {
	{ "r", 22, 25, 56, 50, nil, r = 0.12 },
	{ "r", 22, 44, 56, 6, INK, o = false },
	{ "r", 7, 81, 86, 11, nil, r = 0.5 },
})

D.broccoli = food(C.greenDark, {
	{ "r", 39, 54, 22, 36, nil, r = 0.15 },
	{ "r", 39, 56, 22, 7, INK, o = false },
	{ "c", 10, 26, 36, 36 },
	{ "c", 54, 26, 36, 36 },
	{ "c", 28, 10, 44, 44 },
})

D.pickles = food(C.leaf, {
	{ "r", 23, 9, 54, 17, nil, r = 0.15 },
	{ "r", 16, 33, 68, 58, nil, r = 0.2 },
	{ "r", 40, 41, 21, 44, INK, r = 0.5, rot = 30, o = false },
})

D.stew = food(C.redDark, {
	{ "c", 19, 24, 25, 25 },
	{ "c", 56, 24, 25, 25 },
	{ "c", 34, 13, 32, 32 },
	{ "r", 10, 42, 80, 11, nil, r = 0.5 },
	{ "r", 19, 60, 62, 30, nil, r = 0.3 },
	{ "r", 7, 62, 17, 13, nil, r = 0.4 },
	{ "r", 76, 62, 17, 13, nil, r = 0.4 },
})

D.starfruit = food(C.yellow, {
	{ "c", 28, 31, 44, 44 },
	{ "r", 40, 11, 20, 44, nil, r = 0.3, rot = 0 },
	{ "r", 59, 24.8, 20, 44, nil, r = 0.3, rot = 72 },
	{ "r", 51.8, 47.2, 20, 44, nil, r = 0.3, rot = 144 },
	{ "r", 28.2, 47.2, 20, 44, nil, r = 0.3, rot = 216 },
	{ "r", 21, 24.8, 20, 44, nil, r = 0.3, rot = 288 },
	{ "c", 41, 44, 18, 18, INK, o = false },
})

D.dragonchili = food(C.red, {
	{ "r", 30, 32, 24, 64, nil, r = 0.5, rot = 50 },
	{ "c", 58, 30, 28, 24 },
	{ "r", 70, 12, 8, 20, nil, r = 0.5, rot = 30 },
	{ "r", 58, 42, 28, 7, INK, r = 0.5, rot = -8, o = false },
})

-- making them -------------------------------------------------------------------------------------
--
-- An icon is drawn in two passes so that no outline ever crosses another or runs over a fill:
-- first every outlined shape goes down as a solid dark copy grown by the outline's width, then
-- every fill goes on top with no stroke at all. What shows is one outline round the whole
-- silhouette, and parts that meet inside it are told apart by their colours. Where outlined
-- shapes sit a little apart, the dark copies fill the gap with a line of ink (brick joints,
-- the grid's lines). The shading is worked out for the whole icon, not shape by shape, so
-- overlapping shapes of one colour join without a seam.

function Icons.has(name: string?): boolean
	return name ~= nil and (D[name] ~= nil or IconArt.art[name] ~= nil)
end

local SHADE = 0.2 -- how much darker the bottom of an icon is than the top

local function corner(parent: Instance, scale: number)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(scale, 0)
	c.Parent = parent
end

-- A top-lit shade in icon space: the object spans icon heights y0..y1 (0..100), turned by `rot`.
local flat = false -- drawing a flat, one colour icon: no shading (set by Icons.make)

local function shade(parent: Instance, y0: number, y1: number, rot: number)
	if flat then
		return
	end
	local function k(y: number): Color3
		local v = 1 - SHADE * math.clamp(y / 100, 0, 1)
		return Color3.new(v, v, v)
	end
	local g = Instance.new("UIGradient")
	g.Rotation = 90 - rot
	g.Color = ColorSequence.new(k(y0), k(y1))
	g.Parent = parent
end

local function stroke(parent: Instance, color: Color3, thickness: number)
	local s = Instance.new("UIStroke")
	s.Color = color
	s.Thickness = thickness
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.LineJoinMode = Enum.LineJoinMode.Round
	s.Parent = parent
end

local function box(name: string, x: number, y: number, w: number, h: number, parent: Instance, z: number): Frame
	local f = Instance.new("Frame")
	f.Name = name
	f.BorderSizePixel = 0
	f.Position = UDim2.fromScale(x / 100, y / 100)
	f.Size = UDim2.fromScale(w / 100, h / 100)
	f.ZIndex = z
	f.Parent = parent
	return f
end

-- Half the vertical extent of a w x h box turned by rot degrees.
local function halfHeight(w: number, h: number, rot: number): number
	local r = math.rad(rot)
	return (math.abs(w * math.sin(r)) + math.abs(h * math.cos(r))) / 2
end

-- Draws one shape for one pass. ink: the dark copy, grown by `grow` (in icon units) all round.
local function drawShape(
	root: Frame,
	s: any,
	i: number,
	ink: boolean,
	grow: number,
	thick: number,
	tint: Color3?,
	z: number
)
	local kind, x, y = s[1], s[2], s[3]
	local fillColor: Color3 = tint or s[6]
	local color = if ink then INK else fillColor
	if kind == "r" or kind == "c" then
		local w, h = s[4], s[5]
		local f = box((if ink then "Ink" else "Fill") .. i, x, y, w, h, root, z)
		f.BackgroundColor3 = color
		f.BackgroundTransparency = if ink then 0 else (s.t or 0)
		f.Rotation = s.rot or 0
		corner(f, if kind == "c" then 0.5 else (s.r or 0))
		if ink then
			stroke(f, INK, thick)
		elseif (s.t or 0) < 0.3 then
			local hh = if kind == "c" then h / 2 else halfHeight(w, h, s.rot or 0)
			local cy = y + h / 2
			shade(f, cy - hh, cy + hh, if kind == "c" then 0 else (s.rot or 0))
		end
	elseif kind == "ring" then
		-- a thick stroke round an empty circle
		local width = (s[7] or 10) / 100
		local f = box((if ink then "Ink" else "Fill") .. i, x, y, s[4], s[5], root, z)
		f.BackgroundTransparency = 1
		corner(f, 0.5)
		f:SetAttribute("RingWidth", width)
		stroke(f, color, 0) -- thickness is set in pixels below, once the icon's size is known
	elseif kind == "t" then
		local base, dir = s[4], s[5]
		local horizontal = dir == "up" or dir == "down"
		local w = if horizontal then base else base / 2
		local h = if horizontal then base / 2 else base
		-- where the turned square's centre sits, in icon units
		local cx, cy
		if dir == "up" then
			cx, cy = x + w / 2, y + h
		elseif dir == "down" then
			cx, cy = x + w / 2, y
		elseif dir == "left" then
			cx, cy = x + w, y + h / 2
		else
			cx, cy = x, y + h / 2
		end
		-- the clip shows half the square; the dark copy's clip is grown to show its outline too
		local g = if ink then grow else 0
		local bx, by, bw, bh = x - g, y - g, w + g * 2, h + g * 2
		local clip = box((if ink then "Ink" else "Fill") .. "Tri" .. i, bx, by, bw, bh, root, z)
		clip.BackgroundTransparency = 1
		clip.ClipsDescendants = true
		local side = base / math.sqrt(2)
		local sq = Instance.new("Frame")
		sq.BorderSizePixel = 0
		sq.BackgroundColor3 = color
		sq.AnchorPoint = Vector2.new(0.5, 0.5)
		sq.Rotation = 45
		sq.ZIndex = z
		sq.Size = UDim2.fromScale(side / bw, side / bh)
		sq.Position = UDim2.fromScale((cx - bx) / bw, (cy - by) / bh)
		sq.Parent = clip
		if ink then
			stroke(sq, INK, thick)
		else
			shade(sq, cy - base / 2, cy + base / 2, 45)
		end
	elseif kind == "half" then
		local w, h = s[4], s[5]
		local g = if ink then grow else 0
		local top = if s.dir == "up" then y else y + h / 2
		local bx, by, bw, bh = x - g, top - g, w + g * 2, h / 2 + g * 2
		local clip = box((if ink then "Ink" else "Fill") .. "Half" .. i, bx, by, bw, bh, root, z)
		clip.BackgroundTransparency = 1
		clip.ClipsDescendants = true
		local e = Instance.new("Frame")
		e.BorderSizePixel = 0
		e.BackgroundColor3 = color
		e.ZIndex = z
		e.Size = UDim2.fromScale(w / bw, h / bh)
		e.Position = UDim2.fromScale((x - bx) / bw, (y - by) / bh)
		e.Parent = clip
		corner(e, 0.5)
		if ink then
			stroke(e, INK, thick)
		else
			shade(e, y, y + h, 0)
		end
	elseif kind == "txt" and not ink then
		local l = Instance.new("TextLabel")
		l.Name = "Fill" .. i
		l.BackgroundTransparency = 1
		l.Position = UDim2.fromScale(x / 100, y / 100)
		l.Size = UDim2.fromScale(s[4] / 100, s[5] / 100)
		l.Text = s[6]
		l.TextColor3 = s[7]
		l.TextScaled = true
		l.Font = Enum.Font.FredokaOne
		l.ZIndex = z
		l.Parent = root
		if s.o ~= false and thick > 0 then
			local st = Instance.new("UIStroke")
			st.Color = INK
			st.Thickness = thick
			st.Parent = l
		end
	end
end

local function luminance(c: Color3): number
	return c.R * 0.3 + c.G * 0.59 + c.B * 0.11
end

-- Draws icon `name` into a new px x px Frame. Icons are flat and one colour by default (the
-- user asked for simple icons): every piece in `Color` (or `Tint`; light if neither), dark
-- details like eyes and lines cut out in `Hole` (the dark card colour if not given), a dent in a darker shade
-- of `Color`, no outline, no shading,
-- no shine. `Full = true` draws the old full colour sticker with its outline. props: Parent,
-- Position, AnchorPoint, LayoutOrder, Name, ZIndex, Color, Hole, Tint, Full, Outline (false for
-- none, full icons only), Centre (what is drawn sits in the middle of the box, not where its grid
-- puts it: for an icon on a block, a disc or a bubble).
function Icons.make(name: string, px: number, props: { [string]: any }?): Frame
	local p = props or {}
	if not p.Full then
		return Icons.vector(name, px, p) or Icons.flat(name, px, p)
	end
	local root = Instance.new("Frame")
	root.Name = p.Name or "Icon"
	root.BackgroundTransparency = 1
	root.BorderSizePixel = 0
	root.Size = UDim2.fromOffset(px, px)
	root.Position = p.Position or UDim2.new()
	root.AnchorPoint = p.AnchorPoint or Vector2.zero
	root.LayoutOrder = p.LayoutOrder or 0
	local z = p.ZIndex or 1
	root.ZIndex = z
	local def = D[name] or D.medal
	local thick = if p.Outline == false then 0 else math.max(1, math.floor(px / 22 + 0.5))
	local grow = thick / px * 100 -- the outline's width in icon units
	if thick > 0 then
		-- the base: the silhouette's dark copy again, a little lower, so the outline is thicker
		-- underneath and the icon stands up off the screen like a sticker
		local depth = math.max(1, math.floor(thick * 0.9 + 0.5)) / px * 100
		if px >= 20 then
			for i, s in def do
				if s.o ~= false then
					local before = #root:GetChildren()
					drawShape(root, s, i, true, grow, thick, nil, z)
					local kids = root:GetChildren()
					for k = before + 1, #kids do
						local piece = kids[k] :: GuiObject
						piece.Position += UDim2.fromScale(0, depth / 100)
						piece.Name = "InkBase" .. piece.Name:sub(4)
					end
				end
			end
		end
		for i, s in def do
			if s.o ~= false then
				drawShape(root, s, i, true, grow, thick, nil, z)
			end
		end
	end
	for i, s in def do
		drawShape(root, s, i, false, grow, thick, p.Tint, z)
	end
	-- rings: their stroke is the ring, so its width is in pixels; the dark copy is wider by the outline
	for _, f in root:GetChildren() do
		local width = f:GetAttribute("RingWidth")
		if type(width) == "number" then
			local st = f:FindFirstChildOfClass("UIStroke")
			if st then
				st.Thickness = width * px + (if f.Name:sub(1, 3) == "Ink" then thick * 2 else 0)
			end
		end
	end
	root.Parent = p.Parent
	return root
end

-- The interface is dark: with no colour asked for an icon is light, and its cut out details take
-- the dark card colour behind it (UI/Kit's Paper).
Icons.Glyph = Color3.fromRGB(236, 238, 246)
Icons.Hole = Color3.fromRGB(37, 40, 54)

-- Icons that read best in their own colour when nobody asks for one.
Icons.Colors = {
	coin = Color3.fromRGB(236, 162, 28),
	coins = Color3.fromRGB(236, 162, 28),
	medal = Color3.fromRGB(236, 162, 28),
	trophy = Color3.fromRGB(236, 162, 28),
	sun = Color3.fromRGB(255, 176, 30),
	moon = Color3.fromRGB(236, 190, 60),
	heart = Color3.fromRGB(255, 104, 150),
	cloud = Color3.fromRGB(110, 170, 230),
	rain = Color3.fromRGB(70, 150, 230),
	storm = Color3.fromRGB(110, 110, 160),
	snow = Color3.fromRGB(110, 170, 230),
	blossom = Color3.fromRGB(255, 120, 170),
	leaves = Color3.fromRGB(236, 130, 50),
	alert = Color3.fromRGB(255, 108, 98),
}

-- The shade a flat icon draws a dent in: its own colour, a step darker.
function Icons.dentOf(color: Color3): Color3
	return color:Lerp(Color3.new(0, 0, 0), 0.2)
end

-- The flat, one colour drawing of an icon (see Icons.make).
function Icons.flat(name: string, px: number, p: { [string]: any }): Frame
	local root = Instance.new("Frame")
	root.Name = p.Name or "Icon"
	root.BackgroundTransparency = 1
	root.BorderSizePixel = 0
	root.Size = UDim2.fromOffset(px, px)
	root.Position = p.Position or UDim2.new()
	root.AnchorPoint = p.AnchorPoint or Vector2.zero
	root.LayoutOrder = p.LayoutOrder or 0
	local z = p.ZIndex or 1
	root.ZIndex = z
	local glyph: Color3 = p.Color or p.Tint or Icons.Colors[name] or Icons.Glyph
	local hole: Color3 = p.Hole or Icons.Hole
	local def = D[name] or D.medal
	-- which pieces are cut out: a piece inside a bigger one, in a clearly different colour, is a
	-- detail and takes the other colour (a detail inside a cut out flips back); a piece inside
	-- nothing is cut out only if it's dark (eyes, lines drawn on)
	local function bounds(sh: any): (number, number, number, number)
		if sh[1] == "t" then
			local base, dir = sh[4], sh[5]
			local horizontal = dir == "up" or dir == "down"
			return sh[2], sh[3], if horizontal then base else base / 2, if horizontal then base / 2 else base
		end
		return sh[2], sh[3], sh[4] or 0, sh[5] or 0
	end
	local cut: { boolean } = {}
	for i, sh in def do
		local x, y, w, h = bounds(sh)
		local lum = if typeof(sh[6]) == "Color3" then luminance(sh[6]) else 0.5
		local container: number? = nil
		local bestArea = math.huge
		for j = 1, i - 1 do
			local o = def[j]
			if (o.t or 0) == 0 and o[1] ~= "ring" then
				local ox, oy, ow, oh = bounds(o)
				local area = ow * oh
				local inside = x >= ox - 2 and y >= oy - 2 and x + w <= ox + ow + 2 and y + h <= oy + oh + 2
				if inside and w * h < area * 0.7 and area < bestArea then
					container, bestArea = j, area
				end
			end
		end
		if container then
			local c = def[container]
			local clum = if typeof(c[6]) == "Color3" then luminance(c[6]) else 0.5
			cut[i] = if math.abs(lum - clum) > 0.16 then not cut[container] else cut[container]
		else
			cut[i] = lum < 0.3
		end
	end
	flat = true
	for i, s in def do
		if (s.t or 0) > 0 then
			continue -- shines and see-through glints
		end
		drawShape(root, s, i, false, 0, 0, if s.dent then Icons.dentOf(glyph) elseif cut[i] then hole else glyph, z)
	end
	flat = false
	if p.Centre then
		-- the shapes' middle in the middle of the box (Icons.inkOffset says why)
		local x0, y0, x1, y1 = math.huge, math.huge, -math.huge, -math.huge
		for _, sh in def do
			if (sh.t or 0) == 0 then
				local x, y, w, h = bounds(sh)
				x0, y0 = math.min(x0, x), math.min(y0, y)
				x1, y1 = math.max(x1, x + w), math.max(y1, y + h)
			end
		end
		if x1 > x0 then
			local dx = math.floor(((x0 + x1) / 2 - 50) / 100 * px + 0.5)
			local dy = math.floor(((y0 + y1) / 2 - 50) / 100 * px + 0.5)
			for _, f in root:GetChildren() do
				if f:IsA("GuiObject") then
					f.Position -= UDim2.fromOffset(dx, dy)
				end
			end
		end
	end
	root:SetAttribute("Glyph", glyph:ToHex())
	root:SetAttribute("Hole", hole:ToHex())
	for _, f in root:GetChildren() do
		local width = f:GetAttribute("RingWidth")
		if type(width) == "number" then
			local st = f:FindFirstChildOfClass("UIStroke")
			if st then
				st.Thickness = width * px
			end
		end
	end
	root.Parent = p.Parent
	return root
end

-- Every icon's name, for the preview sheet.
function Icons.names(): { string }
	local out = {}
	for name in D do
		table.insert(out, name)
	end
	table.sort(out)
	return out
end

-- Vector icons ---------------------------------------------------------------------------------------
--
-- Each icon is painted once at each of two sizes (small ones get a slightly heavier line, the
-- way type is cut heavier at small sizes) into a sheet of pictures, and shown by an ImageLabel
-- looking at its square of the sheet. A one colour icon is painted white and tinted by the label.

local SHEET = 512 -- a sheet's width and height in pixels
local SMALL, BIG = 48, 96 -- the two sizes an icon is painted at
Icons.Weight = { [SMALL] = 3.25, [BIG] = 3 } -- a line's width on the 24 grid

type Sheet = { image: any, content: any, x: number, y: number, row: number }
type Cell = { content: any, x: number, y: number, n: number, coloured: boolean, ox: number, oy: number }
local sheets: { Sheet } = {}
local cells: { [string]: Cell } = {}
local vectorOn: boolean? = nil -- nil until the first icon has been tried
local broken: { [string]: boolean } = {}

local function newSheet(): Sheet
	local image = (game:GetService("AssetService") :: any):CreateEditableImage({ Size = Vector2.new(SHEET, SHEET) })
	if not image then
		error("no memory left for a sheet of icons")
	end
	-- start clear, whatever a new picture holds
	image:WritePixelsBuffer(Vector2.new(0, 0), Vector2.new(SHEET, SHEET), buffer.create(SHEET * SHEET * 4))
	local sheet: Sheet = { image = image, content = (Content :: any).fromObject(image), x = 0, y = 0, row = 0 }
	table.insert(sheets, sheet)
	return sheet
end

-- How far the middle of what is painted in an n by n picture sits from the picture's middle, as a
-- share of n across and down. Art is laid out on its 24 grid, where a thing that stands on the
-- ground may sit low and a half wall sits at the bottom; on a block, a disc or a bubble the icon
-- is centred by what is painted instead (`Centre`; the user: "some icons within icon backgrounds
-- are not centered").
function Icons.inkOffset(pixels: buffer, n: number): (number, number)
	local x0, y0, x1, y1 = n, n, -1, -1
	for y = 0, n - 1 do
		for x = 0, n - 1 do
			if buffer.readu8(pixels, (y * n + x) * 4 + 3) > 96 then
				if x < x0 then
					x0 = x
				end
				if x > x1 then
					x1 = x
				end
				if y < y0 then
					y0 = y
				end
				if y > y1 then
					y1 = y
				end
			end
		end
	end
	if x1 < 0 then
		return 0, 0
	end
	return ((x0 + x1 + 1) / 2 - n / 2) / n, ((y0 + y1 + 1) / 2 - n / 2) / n
end

-- The square of a sheet holding `name` painted n pixels across (painting it first if need be).
-- Squares sit a pixel apart, so one never bleeds into the next when the picture is scaled.
local function cellFor(name: string, n: number, mono: boolean?): Cell
	local art = if mono and IconArt.mono[name] then IconArt.mono[name] else IconArt.art[name]
	local key = name .. ":" .. n .. (if art ~= IconArt.art[name] then ":mono" else "")
	local have = cells[key]
	if have then
		return have
	end
	local pixels, coloured = Vector.raster(art, n, { Weight = Icons.Weight[n] })
	local ox, oy = Icons.inkOffset(pixels, n)
	local size = n + 2
	local sheet = sheets[#sheets] or newSheet()
	if sheet.x + size > SHEET then
		sheet.x = 0
		sheet.y += sheet.row
		sheet.row = 0
	end
	if sheet.y + size > SHEET then
		sheet = newSheet()
	end
	sheet.image:WritePixelsBuffer(Vector2.new(sheet.x + 1, sheet.y + 1), Vector2.new(n, n), pixels)
	local cell: Cell = {
		content = sheet.content,
		x = sheet.x + 1,
		y = sheet.y + 1,
		n = n,
		coloured = coloured,
		ox = ox,
		oy = oy,
	}
	sheet.x += size
	sheet.row = math.max(sheet.row, size)
	cells[key] = cell
	return cell
end

-- Is the game able to make the pictures? (nil before the first icon has been tried.)
function Icons.vectorOn(): boolean?
	return vectorOn
end

-- Switches the drawn icons off (false: every icon is built from shapes, as when the game can't
-- make pictures) or lets them be tried again (nil).
function Icons.setVector(on: boolean?)
	vectorOn = on
end

-- Does this icon have vector art?
function Icons.hasArt(name: string?): boolean
	return name ~= nil and IconArt.art[name] ~= nil
end

-- Every name with vector art.
function Icons.artNames(): { string }
	local out = {}
	for name in IconArt.art do
		table.insert(out, name)
	end
	table.sort(out)
	return out
end

-- The vector drawing of an icon, or nil if there is none or the game can't make pictures. Art
-- with colours of its own (the coin) shows in them; the rest (the foods too) takes `Color`. With
-- `Mono`, art with colours of its own shows in its one colour form instead (IconArt.mono), in
-- `Color`: a coin on a coloured block.
function Icons.vector(name: string, px: number, p: { [string]: any }): Frame?
	if vectorOn == false or broken[name] or IconArt.art[name] == nil then
		return nil
	end
	local glyph: Color3 = p.Color or p.Tint or Icons.Colors[name] or Icons.Glyph
	local ok, got = pcall(function(): Frame
		local cell = cellFor(name, if px <= 30 then SMALL else BIG, p.Mono == true)
		local root = Instance.new("Frame")
		root.Name = p.Name or "Icon"
		root.BackgroundTransparency = 1
		root.BorderSizePixel = 0
		root.Size = UDim2.fromOffset(px, px)
		root.Position = p.Position or UDim2.new()
		root.AnchorPoint = p.AnchorPoint or Vector2.zero
		root.LayoutOrder = p.LayoutOrder or 0
		local z = p.ZIndex or 1
		root.ZIndex = z
		local art = Instance.new("ImageLabel")
		art.Name = "Art"
		art.BackgroundTransparency = 1
		art.BorderSizePixel = 0
		art.Size = UDim2.fromScale(1, 1)
		if p.Centre then
			-- what is painted in the middle of the box, whatever its place on the grid (whole
			-- pixels, so it stays crisp)
			art.Position = UDim2.fromOffset(-math.floor(cell.ox * px + 0.5), -math.floor(cell.oy * px + 0.5))
		end
		art.ZIndex = z;
		(art :: any).ImageContent = cell.content
		art.ImageRectOffset = Vector2.new(cell.x, cell.y)
		art.ImageRectSize = Vector2.new(cell.n, cell.n)
		art.ImageColor3 = if cell.coloured then Color3.new(1, 1, 1) else glyph
		art.Parent = root
		root:SetAttribute("Vector", true)
		root:SetAttribute("Mono", not cell.coloured)
		root:SetAttribute("Glyph", glyph:ToHex())
		return root
	end)
	if not ok then
		if vectorOn == nil then
			vectorOn = false
			warn(
				"[Icons] the drawn icons are off and the plain ones are showing ("
					.. tostring(got)
					.. "). Switch on Allow Mesh / Image APIs under Security in the game's settings."
			)
		else
			broken[name] = true
			warn("[Icons] could not draw " .. name .. ": " .. tostring(got))
		end
		return nil
	end
	vectorOn = true
	local root = got :: Frame
	root.Parent = p.Parent
	return root
end

-- Paints pictures ahead of need, one at a time with a breath between, so the first screen that
-- shows a lot of them at once (several cravings) doesn't stall while they are all painted
-- together. `names` is which (every piece of art if not given). Does nothing where the game
-- can't make pictures.
function Icons.warm(names: { string }?)
	task.spawn(function()
		for _, name in names or Icons.artNames() do
			for _, n in { SMALL, BIG } do
				if vectorOn == false or broken[name] or IconArt.art[name] == nil then
					break
				end
				if not pcall(cellFor, name, n) then
					-- whoever asks for it next finds out why, and says so
					return
				end
				task.wait(0.03)
			end
		end
	end)
end

-- The picture of a food (UI/ItemArt): a silhouette like the interface icons (the user: "make
-- food and thing icons sillouhettes like normal icons as well"), drawn in `color`, the thing's own
-- (Data/Foods' color: a red apple, a brown loaf), unless props name a Color or Tint, which it
-- takes as Icons.make does (Hole too, for the shape lists). Where the game can't make pictures
-- it is built from its shape list like any icon; a name with neither is a disc in `color`.
function Icons.item(name: string, px: number, color: Color3, props: { [string]: any }?): Frame
	local p = table.clone(props or {})
	p.Color = p.Color or p.Tint or color
	local drawn = Icons.vector(name, px, p)
	if drawn then
		return drawn
	end
	if D[name] then
		return Icons.flat(name, px, p)
	end
	local disc = Instance.new("Frame")
	disc.Name = "Swatch"
	disc.BackgroundColor3 = p.Color
	disc.BorderSizePixel = 0
	disc.Size = UDim2.fromOffset(px, px)
	disc.Position = p.Position or UDim2.new()
	disc.AnchorPoint = p.AnchorPoint or Vector2.zero
	disc.LayoutOrder = p.LayoutOrder or 0
	disc.ZIndex = p.ZIndex or 1
	local round = Instance.new("UICorner")
	round.CornerRadius = UDim.new(0.5, 0)
	round.Parent = disc
	disc.Parent = p.Parent
	return disc
end

return Icons
