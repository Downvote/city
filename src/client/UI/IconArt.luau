--!strict
-- The icons' vector art. The user: "Alot of the icons arent proper vector art and just shapes
-- spliced together, look online to see how vector art should be. Make them as simple as possible."
-- Then, pointing at another game's interface: "also, redo the icons, so that it matches the icon
-- style in zenless zone zero". We take the style from that game and nothing else: every icon
-- here is a drawing of our own, of our own subject.
--
-- The style, as rules:
--   a 24 by 24 grid, the shape filling most of it, nothing nearer than 1.5 to the edge
--   solid, not outlined: an icon is a filled silhouette, in one colour
--   details are cut out of it (a door out of a house, hands out of a clock face), never drawn on it
--   a cut is 1.75 to 2 wide, so it still shows at 16 pixels; so is the space between two parts
--   where a line can't be helped (a handle, a hook) it is heavy, 2 to 3 wide
--   true circles and straight edges, with only the points taken off the corners (half a unit)
--   the angles are 45 and 90 degrees where the subject allows it; things that point come to a
--   real point (an arrow, a roof, a picket, a pin), and slashes cut across a face all lean the
--   same way, up to the right
--   whole numbers and halves, so edges land cleanly on pixels
-- Each icon is a list of layers in SVG's path language (see UI/Vector), laid one over the other.
-- A plain string is a heavy line with round ends; the helpers below make the rest. Colours make
-- coloured art (the coin).

local Vector = require(script.Parent.Vector)
local ItemArt = require(script.Parent.ItemArt)

local circle, rect, ellipse = Vector.circle, Vector.rect, Vector.ellipse

local IconArt = {}

local A: { [string]: { Vector.Layer } } = {}
IconArt.art = A

local GAP = 2 -- how wide a cut is

-- A solid shape. The thin line round it takes the points off its corners (and makes it half
-- that line wider all round).
local function solid(d: string, edge: number?): Vector.Layer
	return { d, fill = true, w = edge or 1 }
end

-- A solid shape just as it is written: circles, and shapes that should keep a sharp point.
local function flat(d: string): Vector.Layer
	return { d, fill = true }
end

-- A hole: a shape rubbed out of what is under it.
local function hole(d: string): Vector.Layer
	return { d, fill = true, cut = true }
end

-- A gap: a line rubbed out of what is under it.
local function gap(d: string, w: number?): Vector.Layer
	return { d, cut = true, w = w or GAP }
end

-- Room for a shape that is about to be laid over others: the shape rubbed out, and `margin`
-- more all round it.
local function clear(d: string, margin: number?): Vector.Layer
	return { d, fill = true, cut = true, w = (margin or GAP) * 2 }
end

-- A line of a width of its own.
local function line(d: string, w: number): Vector.Layer
	return { d, w = w }
end

-- signs ------------------------------------------------------------------------------------------------

A.plus = { solid("M10.5 3 H13.5 V10.5 H21 V13.5 H13.5 V21 H10.5 V13.5 H3 V10.5 H10.5 Z") }
A.close = { solid("M12 10 L18 4 L20 6 L14 12 L20 18 L18 20 L12 14 L6 20 L4 18 L10 12 L4 6 L6 4 Z") }
A.check = { solid("M9 19.5 L21 7.5 L19 5.5 L9 15.5 L5 11.5 L3 13.5 Z") }
-- the arrows: a block arrow with a notch in its tail
A.up = { solid("M12 2.5 L21 11.5 H14 V21.5 L12 19.5 L10 21.5 V11.5 H3 Z") }
A.down = { solid("M12 21.5 L21 12.5 H14 V2.5 L12 4.5 L10 2.5 V12.5 H3 Z") }
A.back = { solid("M2.5 12 L11.5 3 V10 H21.5 L19.5 12 L21.5 14 H11.5 V21 Z") }
A.alert = { flat(circle(12, 12, 10.25)), hole("M10.25 5.5 H13.75 L13 13.5 H11 Z"), hole(circle(12, 17.5, 1.9)) }
A.eye = { flat("M1.5 12 A11.25 11.25 0 0 1 22.5 12 A11.25 11.25 0 0 1 1.5 12 Z"), gap(circle(12, 12, 4.25)) }
A.zoom = { flat(circle(10, 10, 8.25) .. " " .. circle(10, 10, 4.75)), solid("M14.5 16.5 L16.5 14.5 L22 20 L20 22 Z") }
A.grid = {
	flat(
		rect(1.75, 1.75, 9.25, 9.25, 1.5)
			.. " "
			.. rect(13, 1.75, 9.25, 9.25, 1.5)
			.. " "
			.. rect(1.75, 13, 9.25, 9.25, 1.5)
			.. " "
			.. rect(13, 13, 9.25, 9.25, 1.5)
	),
}
-- three sheets, one over the other
local function sheet(cy: number): string
	return string.format("M12 %s L22 %s L12 %s L2 %s Z", tostring(cy - 4), tostring(cy), tostring(cy + 4), tostring(cy))
end
A.layers = { solid(sheet(17)), clear(sheet(12), 2.5), solid(sheet(12)), clear(sheet(7), 2.5), solid(sheet(7)) }
A.clock = { flat(circle(12, 12, 10.25)), gap("M12 6 V12 L16 14.5", 2.25) }
A.camera = { solid("M2 6.5 H7.5 L9 3.5 H15 L16.5 6.5 H22 V20.5 H2 Z"), gap(circle(12, 13.25, 4.25)) }
A.dice = {
	flat(rect(1.75, 1.75, 20.5, 20.5, 3.5)),
	hole(
		circle(7.25, 7.25, 1.9)
			.. " "
			.. circle(16.75, 7.25, 1.9)
			.. " "
			.. circle(12, 12, 1.9)
			.. " "
			.. circle(7.25, 16.75, 1.9)
			.. " "
			.. circle(16.75, 16.75, 1.9)
	),
}
-- two notes under one leaning beam
A.music = {
	solid("M7 4.5 L20.5 2.25 V16 H18 V6.7 L9.5 8.1 V18 H7 Z"),
	flat(ellipse(6, 18.25, 3.75, 3.1)),
	flat(ellipse(17, 16.25, 3.75, 3.1)),
}
A.ruler = {
	solid("M2 15.5 L15.5 2 L22 8.5 L8.5 22 Z"),
	gap("M4.5 11 L7.75 14.25", 1.75),
	gap("M7.75 7.75 L12 12", 1.75),
	gap("M11 4.5 L14.25 7.75", 1.75),
}
-- a pin in the map
A.map = { flat("M12 22.5 L5.71 15.09 A8.25 8.25 0 1 1 18.29 15.09 Z " .. circle(12, 9.75, 3.25)) }
A.news = {
	solid("M4 2 H15.5 L20 6.5 V22 H4 Z"),
	gap("M7.5 8 H12", 2.25),
	gap("M7.5 12.5 H16.5"),
	gap("M7.5 17 H16.5"),
}
A.cart = {
	solid("M2 2.5 H6 L6.9 6 H22 L20 16 H7.1 L4.25 5 H2 Z"),
	flat(circle(9.75, 20, 2.25) .. " " .. circle(17.5, 20, 2.25)),
}
A.bag = {
	solid("M4.5 8.5 H19.5 L21 21.5 H3 Z"),
	line("M8.5 8.5 V6.5 A3.5 3.5 0 0 1 15.5 6.5 V8.5", 2.25),
	gap("M8.5 11 V12 A3.5 3.5 0 0 0 15.5 12 V11", 1.75),
}
A.gift = {
	flat(rect(2, 7.5, 20, 4.5, 1)),
	flat(rect(3.5, 13.5, 17, 8.5, 1)),
	gap("M12 7 V23"),
	flat("M12 7.5 L7.23 6.99 A2.5 2.5 0 1 1 9.69 3.3 Z " .. circle(7.5, 4.5, 1.1)),
	flat("M12 7.5 L16.77 6.99 A2.5 2.5 0 1 0 14.31 3.3 Z " .. circle(16.5, 4.5, 1.1)),
}
A.briefcase = {
	flat(rect(2, 7.5, 20, 14, 2)),
	line("M8.5 7.5 V5 A1.5 1.5 0 0 1 10 3.5 H14 A1.5 1.5 0 0 1 15.5 5 V7.5", 2.25),
	gap("M1 13.5 H8.75", 1.75),
	gap("M15.25 13.5 H23", 1.75),
}

-- people -----------------------------------------------------------------------------------------------

A.person = {
	flat(circle(12, 7, 4.75)),
	solid("M3 22 V20.5 A6.5 6.5 0 0 1 9.5 14 H14.5 A6.5 6.5 0 0 1 21 20.5 V22 Z"),
}
local FRONT = "M2 22 V20.5 A6 6 0 0 1 8 14.5 H9 A6 6 0 0 1 15 20.5 V22 Z"
A.people = {
	flat(circle(17.5, 6.5, 3.5)),
	solid("M11 22 V18 A5.5 5.5 0 0 1 16.5 12.5 H17 A5 5 0 0 1 22 17.5 V22 Z"),
	clear(circle(8.5, 8, 4.25), 1.75),
	clear(FRONT, 2.25),
	flat(circle(8.5, 8, 4.25)),
	solid(FRONT),
}
A.smile = {
	flat(circle(12, 12, 10.25)),
	hole(circle(8.5, 9.5, 1.7) .. " " .. circle(15.5, 9.5, 1.7)),
	gap("M6.8 14.5 A6 6 0 0 0 17.2 14.5"),
}
A.heart = { flat("M12 21.5 L3.33 11.74 A5.25 5.25 0 1 1 12 6.01 A5.25 5.25 0 1 1 20.67 11.74 Z") }
A.medal = {
	solid("M4 2 H9.5 L13.5 10 H8 Z"),
	solid("M14.5 2 H20 L16 10 H10.5 Z"),
	clear(circle(12, 15, 6.5), 1.75),
	flat(circle(12, 15, 6.5) .. " " .. circle(12, 15, 2.5)),
}
A.trophy = {
	solid("M6.5 2.5 H17.5 V8.5 A5.5 5.5 0 0 1 6.5 8.5 Z"),
	line("M6.5 4.5 H3.5 V6 A4.5 4.5 0 0 0 7.5 10.4", 2),
	line("M17.5 4.5 H20.5 V6 A4.5 4.5 0 0 1 16.5 10.4", 2),
	flat(rect(10.75, 13, 2.5, 6)),
	solid("M7.5 21.5 V20.5 A2 2 0 0 1 9.5 18.5 H14.5 A2 2 0 0 1 16.5 20.5 V21.5 Z"),
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

A.shirt = {
	solid(
		"M8.5 2.5 L2 6.5 L4.75 12 L7.5 10.75 V21.5 H16.5 V10.75 L19.25 12 L22 6.5 L15.5 2.5 A3.5 3.5 0 0 1 8.5 2.5 Z"
	),
}
A.pants = { solid("M5.5 2.5 H18.5 L20 21.5 H13.75 L12 9.5 L10.25 21.5 H4 Z"), gap("M3 6.5 H21", 1.5) }
A.shoe = {
	solid("M2.5 4.5 H8.5 L10 9.5 L17.5 12 A4.5 4.5 0 0 1 21.5 16.5 H2.5 Z"),
	flat(rect(2, 18.25, 20, 3.5, 1.25)),
}
-- a cap, its peak to the right
A.hat = {
	flat("M2 15.5 A8.5 9.5 0 0 1 19 15.5 Z"),
	flat(rect(9.25, 4.25, 2.5, 3, 1)),
	solid("M2.5 18 H17 Q21.5 18 22 21 H2.5 Z"),
}
-- a comb
A.hair = {
	flat(rect(2, 4, 20, 16.5, 1)),
	hole("M4.4 10 H6.4 V21 H4.4 Z M8.8 10 H10.8 V21 H8.8 Z M13.2 10 H15.2 V21 H13.2 Z M17.6 10 H19.6 V21 H17.6 Z"),
}
-- a whole body, standing (the creator's Bodies)
A.figure = {
	flat(circle(12, 4.5, 3)),
	solid("M6 9.5 H18 V17 H14.5 V22 H9.5 V17 H6 Z"),
	gap("M8.25 12.5 V18", 1.5),
	gap("M15.75 12.5 V18", 1.5),
	gap("M12 17 V23", 1.75),
}
-- the torso, the arms and the legs, each by itself (Body parts)
A.limbs = {
	flat(
		rect(8, 2, 8, 10.5, 1)
			.. " "
			.. rect(2.5, 2, 3.5, 10.5, 1)
			.. " "
			.. rect(18, 2, 3.5, 10.5, 1)
			.. " "
			.. rect(8, 14.5, 3.25, 7.5, 1)
			.. " "
			.. rect(12.75, 14.5, 3.25, 7.5, 1)
	),
}
-- what you own (My items)
A.backpack = {
	line("M10 5.5 V4.5 A2 2 0 0 1 14 4.5 V5.5", 1.75),
	solid("M4.5 21.5 V11 A7.5 6.5 0 0 1 19.5 11 V21.5 Z"),
	gap(rect(8, 13, 8, 5.5, 1.5), 1.75),
}
-- a look put away for later (Outfits)
A.hanger = {
	line("M9.25 5 A2.75 2.75 0 1 1 12 7.75 V9.5", 2.25),
	solid("M12 8.5 L22 17 V20 H2 V17 Z M12 12.5 L17.25 17 H6.75 Z"),
}
-- a card with your face on it (My avatars)
A.idcard = {
	flat(rect(1.5, 4, 21, 16, 2.5)),
	hole(circle(8, 10, 2.4)),
	hole("M4.25 16.75 A3.75 3.75 0 0 1 11.75 16.75 Z"),
	gap("M15 9.5 H19"),
	gap("M15 14.5 H19"),
}

-- the tools --------------------------------------------------------------------------------------------

-- a heavy head square across its handle
A.hammer = { solid("M8.5 6.5 L12.5 2.5 L21.5 11.5 L17.5 15.5 Z"), solid("M12 10 L14 12 L4.5 21.5 L2.5 19.5 Z") }
A.pointer = { solid("M4 2 V20 L9 15.5 L12.5 22 L16.5 20 L13 13.5 H19.5 Z") }
A.move = {
	solid(
		"M12 2 L16 6.5 H13.5 V10.5 H17.5 V8 L22 12 L17.5 16 V13.5 H13.5 V17.5 H16 L12 22 L8 17.5 H10.5 V13.5 H6.5 V16 L2 12 L6.5 8 V10.5 H10.5 V6.5 H8 Z"
	),
}
A.rotate = { "M19 13 A7 7 0 1 1 12 6", solid("M11.5 2 L17.5 6 L11.5 10 Z") }
A.undo = { solid("M2.5 8.5 L9 3.5 V7 H14.5 A7 7 0 0 1 14.5 21 H7.5 V18 H14.5 A4 4 0 0 0 14.5 10 H9 V13.5 Z") }
A.redo = { solid("M21.5 8.5 L15 3.5 V7 H9.5 A7 7 0 0 0 9.5 21 H16.5 V18 H9.5 A4 4 0 0 1 9.5 10 H15 V13.5 Z") }
A.copy = {
	flat(rect(2, 2, 13.5, 13.5, 2)),
	clear(rect(8.5, 8.5, 13.5, 13.5, 2)),
	flat(rect(8.5, 8.5, 13.5, 13.5, 2)),
}
A.brush = {
	solid("M20 2 L22 4 L13.5 12.5 L11.5 10.5 Z"),
	flat("M9.75 12.25 L11.75 14.25 Q13.5 18 10 20 Q6.5 22 2 22 Q4.5 19.5 4.5 16.5 Q5 12 9.75 12.25 Z"),
}
A.bucket = {
	line("M4.5 9 A7.5 6 0 0 1 19.5 9", 2),
	solid("M3.5 9.5 H20.5 L18.75 21.5 H5.25 Z"),
	gap("M2 13 H22", 1.75),
}
A.trash = {
	flat(rect(9, 2, 6, 4, 1)),
	flat(rect(2.5, 4.5, 19, 3.25, 1)),
	solid("M4.5 9.75 H19.5 L18.25 21.5 H5.75 Z"),
	gap("M9.5 13 V18.5", 1.75),
	gap("M14.5 13 V18.5", 1.75),
}
A.hardhat = {
	flat("M4 15.5 V14 A8 8 0 0 1 20 14 V15.5 Z"),
	flat(rect(10.25, 3.5, 3.5, 5, 1)),
	flat(rect(1.5, 17.25, 21, 3.5, 1.5)),
}
-- a tower crane with a load on its hook
A.crane = {
	solid("M6.5 2 H9.5 L22 5 V7.5 H9.5 V22 H6.5 V7.5 H5.5 V11 H2 V4.5 H6.5 Z"),
	flat(rect(3.5, 19.5, 9, 2.5, 0.75)),
	line("M18.5 7.5 V12.5", 1.5),
	flat(rect(15.5, 12.5, 6, 4.5, 0.75)),
}
A.blueprint = {
	flat(rect(2, 3.5, 20, 17, 2)),
	gap("M11.5 2.5 V11.5 H1", 1.75),
	gap("M15.5 21.5 V15.5", 1.75),
}

-- places -----------------------------------------------------------------------------------------------

A.house = {
	solid("M12 2.5 L15.5 5.5 V3 H18.5 V8 L22 11 H2 Z"),
	solid("M4.5 13.5 H19.5 V22 H14 V16.5 H10 V22 H4.5 Z"),
}
A.hall = {
	solid("M12 2 L22 8.5 H2 Z"),
	flat(rect(4, 10.5, 3.5, 7) .. " " .. rect(10.25, 10.5, 3.5, 7) .. " " .. rect(16.5, 10.5, 3.5, 7)),
	flat(rect(2, 19, 20, 3, 0.75)),
}
A.store = {
	flat(
		"M4.5 2 H19.5 L22 8.5 A2.5 2.5 0 0 1 17 8.5 A2.5 2.5 0 0 1 12 8.5 A2.5 2.5 0 0 1 7 8.5 A2.5 2.5 0 0 1 2 8.5 Z"
	),
	gap("M8.25 1 L7 9", 1.5),
	gap("M12 1 V9", 1.5),
	gap("M15.75 1 L17 9", 1.5),
	solid("M4 13.5 H20 V22 H17.5 V16.5 H13 V22 H4 Z M6.5 16.5 H10.5 V19.5 H6.5 Z"),
}
A.city = {
	solid("M2 22 V11 H7 V22 Z"),
	solid("M9.5 22 V2.5 H15 V22 Z"),
	solid("M17.5 22 V9.5 L22 7 V22 Z"),
	gap("M11.5 6.5 H13", 1.75),
	gap("M11.5 10.5 H13", 1.75),
	gap("M11.5 14.5 H13", 1.75),
}
A.road = {
	solid("M8.5 2 H15.5 L22 22 H2 Z"),
	gap("M12 4 V6.5", 1.5),
	gap("M12 10.5 V13.5", 1.75),
	gap("M12 17.5 V20.5", 2),
}
-- stepping stones
A.path = {
	solid("M3.5 16.5 H9 L10.5 19 L8.5 21 H4 L3 19 Z", 2),
	solid("M9 9.5 H14.5 L16 12 L14.5 14 H9.5 L8 12 Z", 2),
	solid("M15 3 H20 L21.5 5.5 L20 7.5 H15.5 L14 5.5 Z", 2),
}

-- building pieces --------------------------------------------------------------------------------------

A.wall = {
	flat(rect(2, 2.5, 20, 19, 1)),
	gap("M1 8.5 H23"),
	gap("M1 15.5 H23"),
	gap("M14 1.5 V8.5"),
	gap("M9 8.5 V15.5"),
	gap("M14 15.5 V22.5"),
}
A.wallHalf = { flat(rect(2, 9.5, 20, 12, 1)), gap("M1 15.5 H23"), gap("M9 8.5 V15.5"), gap("M14 15.5 V22.5") }
A.wallGlass = { flat(rect(2, 2.5, 20, 19, 1.5)), gap("M6.5 15.5 L12.5 9.5"), gap("M12.5 16.5 L17 12") }
A.railing = {
	flat(rect(1.5, 5, 21, 3.5, 1)),
	flat(rect(1.5, 17, 21, 3, 1)),
	flat(rect(4.5, 7, 2.5, 11) .. " " .. rect(10.75, 7, 2.5, 11) .. " " .. rect(17, 7, 2.5, 11)),
}
A.fence = {
	flat(rect(2, 9.5, 20, 2.5) .. " " .. rect(2, 15.5, 20, 2.5)),
	solid("M2 21.5 V6.5 L4.25 3 L6.5 6.5 V21.5 Z"),
	solid("M9.75 21.5 V6.5 L12 3 L14.25 6.5 V21.5 Z"),
	solid("M17.5 21.5 V6.5 L19.75 3 L22 6.5 V21.5 Z"),
}
A.hedge = {
	solid("M2 20.5 V8.5 A3.333 3.333 0 0 1 8.667 8.5 A3.333 3.333 0 0 1 15.333 8.5 A3.333 3.333 0 0 1 22 8.5 V20.5 Z"),
	gap("M6 16 L7.5 14.5", 1.5),
	gap("M11.5 12.5 L13 11", 1.5),
	gap("M15.5 17.5 L17 16", 1.5),
}
A.stoneWall = {
	flat(rect(2, 3, 20, 18, 2.5)),
	gap("M1 12 L8.5 11 L15.5 12.5 L23 11.5"),
	gap("M13.5 2 L12.5 12"),
	gap("M8 22 L8.5 11"),
	gap("M16.5 22 L15.5 12.5"),
}
-- a room on a plan, its door open
A.room = {
	flat(rect(2, 2, 20, 20, 1.5) .. " M5.5 5.5 H18.5 V18.5 H5.5 Z"),
	hole("M8 18 H14 V23 H8 Z"),
	flat("M15 19.5 L13.5 21 L8.5 16 L10 14.5 Z"),
}
A.floor = { solid("M12 3 L22 12 L12 21 L2 12 Z"), gap("M6 6.6 L18 17.4", 1.75), gap("M18 6.6 L6 17.4", 1.75) }
A.roof = { solid("M2 19 L7.5 6 L13 19 Z"), solid("M10.75 6 H16.5 L22 19 H16.25 Z") }
A.roofHip = { solid("M2 19 L7.5 6 H16.5 L22 19 Z") }
A.roofPyramid = { solid("M12 5 L22 17.5 L9 20 L2 17.5 Z"), gap("M12.2 4 L8.8 21", 1.75) }
A.roofShed = { solid("M2 19 L22 7 V19 Z") }
A.roofFlat = { solid("M2 11.5 H22 V15 H20 V19 H4 V15 H2 Z") }
A.door = {
	flat(rect(5, 2, 14, 20, 1)),
	hole("M8 5 H16 V10.5 H8 Z"),
	hole(circle(15.25, 14.25, 1.4)),
}
A.window = {
	flat(
		rect(3.5, 2, 17, 17.5, 1.5)
			.. " M6.25 4.75 H11 V9.5 H6.25 Z M13 4.75 H17.75 V9.5 H13 Z M6.25 11.5 H11 V16.25 H6.25 Z M13 11.5 H17.75 V16.25 H13 Z"
	),
	flat(rect(2, 19, 20, 3, 0.75)),
}
A.stairs = { solid("M2 22 V17 H7 V12 H12 V7 H17 V2 H22 V22 Z") }

-- furniture and the garden -----------------------------------------------------------------------------

A.chair = { solid("M5 2 H8.5 L9 11 H18.5 V22 H15 V14.5 H9 V22 H5.5 Z") }
A.table = { solid("M2 4.5 H22 V8 H19 L20.5 20.5 H17.5 L16 8 H8 L6.5 20.5 H3.5 L5 8 H2 Z") }
local SEAT = "M2 11 A1.75 1.75 0 0 1 5.5 11 V14.5 H18.5 V11 A1.75 1.75 0 0 1 22 11 V20 H2 Z"
A.sofa = {
	flat(rect(4.5, 4, 15, 10, 2.5)),
	clear(SEAT, 2.25),
	solid(SEAT),
	flat(rect(3.5, 20, 2.5, 2.25, 0.5) .. " " .. rect(18, 20, 2.5, 2.25, 0.5)),
}
A.bed = {
	flat(rect(2, 3.5, 3.5, 18.5, 1)),
	flat("M4 13.5 H19 A3 3 0 0 1 22 16.5 V22 H19 V19.5 H4 Z"),
	flat(rect(7, 8.25, 6.5, 3.5, 1.75)),
}
A.cabinet = {
	flat(rect(4.5, 2, 15, 18, 1.5)),
	gap("M3.5 10.75 H20.5", 1.75),
	gap("M10.25 6.5 H13.75", 1.75),
	gap("M10.25 15.25 H13.75", 1.75),
	flat(rect(6, 19.5, 2.5, 3, 0.5) .. " " .. rect(15.5, 19.5, 2.5, 3, 0.5)),
}
A.pot = {
	flat(rect(10, 2.5, 4, 3.5, 1)),
	flat("M4 9.5 A8 4.5 0 0 1 20 9.5 Z"),
	flat("M4 11.5 H20 V17 A4.5 4.5 0 0 1 15.5 21.5 H8.5 A4.5 4.5 0 0 1 4 17 Z"),
	flat(rect(1.5, 12, 3.5, 3, 1) .. " " .. rect(19, 12, 3.5, 3, 1)),
}
A.bath = {
	line("M5.5 11.5 V6.5 A2.5 2.5 0 0 1 10.5 6.5 V7.5", 2),
	flat("M2 11.5 H22 V13.5 A6.5 6.5 0 0 1 15.5 20 H8.5 A6.5 6.5 0 0 1 2 13.5 Z"),
	flat(rect(6, 19.5, 2.5, 2.5, 0.5) .. " " .. rect(15.5, 19.5, 2.5, 2.5, 0.5)),
}
A.lamp = {
	solid("M8 2 H16 L19.5 11.5 H4.5 Z"),
	flat(rect(10.75, 11.5, 2.5, 8)),
	flat(rect(7, 19, 10, 3, 1.5)),
}
-- a picture in its frame
A.frame = {
	flat(rect(2, 3, 20, 18, 1.5) .. " M4.75 5.75 H19.25 V18.25 H4.75 Z"),
	flat("M4.75 18.25 L9.5 11.5 L12.5 15.5 L14.5 13 L19.25 18.25 Z"),
	flat(circle(15.5, 9, 1.5)),
}
A.gamepad = {
	flat(
		"M7 5.5 H17 A5.5 5.5 0 0 1 22.5 11 L21.5 17 A2.75 2.75 0 0 1 16.4 18 L15.25 15.5 H8.75 L7.6 18 A2.75 2.75 0 0 1 2.5 17 L1.5 11 A5.5 5.5 0 0 1 7 5.5 Z"
	),
	gap("M5.75 10.5 H10.25", 1.75),
	gap("M8 8.25 V12.75", 1.75),
	hole(circle(15, 9.25, 1.4) .. " " .. circle(18, 11.75, 1.4)),
}
A.plant = {
	flat("M12 13.5 A7.5 7.5 0 0 1 12 2 A7.5 7.5 0 0 1 12 13.5 Z"),
	flat("M11 13.5 A7 7 0 0 1 2.5 6.5 A7 7 0 0 1 11 13.5 Z"),
	flat("M13 13.5 A7 7 0 0 0 21.5 6.5 A7 7 0 0 0 13 13.5 Z"),
	solid("M6.5 15.5 H17.5 L16 22 H8 Z"),
}
A.tree = {
	flat(circle(12, 7, 5.5)),
	flat(circle(7.25, 11.5, 5)),
	flat(circle(16.75, 11.5, 5)),
	flat(rect(10.5, 13, 3, 9.5, 0.5)),
}
-- a tulip
A.flower = {
	solid("M7 3 L9.5 6.5 L12 2.5 L14.5 6.5 L17 3 V8.5 A5 5 0 0 1 7 8.5 Z"),
	line("M12 13.5 V21.5", 2.25),
	flat("M12 20.5 A6.5 6.5 0 0 1 5 14 A6.5 6.5 0 0 1 12 20.5 Z"),
	flat("M12 20.5 A6.5 6.5 0 0 0 19 14 A6.5 6.5 0 0 0 12 20.5 Z"),
}

-- the sky ----------------------------------------------------------------------------------------------

A.sun = {
	flat(circle(12, 12, 5)),
	flat(
		"M10.25 5 H13.75 L12 1.5 Z M10.25 19 H13.75 L12 22.5 Z M5 10.25 V13.75 L1.5 12 Z M19 10.25 V13.75 L22.5 12 Z "
			.. "M15.75 5.75 L18.25 8.25 L19.5 4.5 Z M18.25 15.75 L15.75 18.25 L19.5 19.5 Z "
			.. "M8.25 18.25 L5.75 15.75 L4.5 19.5 Z M5.75 8.25 L8.25 5.75 L4.5 4.5 Z"
	),
}
A.moon = { flat("M21.5 14.75 A9.75 9.75 0 1 1 9.25 2.5 A7.75 7.75 0 0 0 21.5 14.75 Z") }
A.cloud = {
	flat(circle(6.5, 14.5, 5)),
	flat(circle(12, 10.5, 6.5)),
	flat(circle(17.75, 14.75, 4.75)),
	flat(rect(6.5, 14.5, 11.25, 5)),
}
-- the smaller cloud the weather falls from
local function smallCloud(): { Vector.Layer }
	return {
		flat(circle(6.5, 10.5, 4.25)),
		flat(circle(12, 7.75, 5.5)),
		flat(circle(17.5, 10.75, 4)),
		flat(rect(6.5, 9.5, 11, 5.25)),
	}
end
A.rain = smallCloud()
table.insert(A.rain, line("M8.25 17.5 L6.75 21", 2.25))
table.insert(A.rain, line("M12.75 17.5 L11.25 21", 2.25))
table.insert(A.rain, line("M17.25 17.5 L15.75 21", 2.25))
local BOLT = "M12.5 11 H16.5 L14.25 15.5 H17.5 L10 22.5 L11.75 17.5 H8.5 Z"
A.storm = smallCloud()
table.insert(A.storm, clear(BOLT, 1.75))
table.insert(A.storm, flat(BOLT))
A.snow = smallCloud()
table.insert(A.snow, flat(circle(7.5, 18.25, 1.5) .. " " .. circle(12, 20.75, 1.5) .. " " .. circle(16.5, 18.25, 1.5)))
A.blossom = {
	flat(circle(12, 6, 3.75)),
	flat(circle(17.94, 10.32, 3.75)),
	flat(circle(15.67, 17.31, 3.75)),
	flat(circle(8.33, 17.31, 3.75)),
	flat(circle(6.06, 10.32, 3.75)),
	hole(circle(12, 12.25, 2.5)),
}
-- a leaf on the wind
A.leaves = { flat("M3 21 Q3 7 21 3 Q21 21 3 21 Z"), gap("M6.5 17.5 L14.5 9.5", 1.75) }

-- things from the shop and food (UI/ItemArt) ------------------------------------------------------

for name, art in ItemArt do
	A[name] = art
end

return IconArt
