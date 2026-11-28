--!strict
-- The icons' vector art. The user: "Alot of the icons arent proper vector art and just shapes
-- spliced together, look online to see how vector art should be. Make them as simple as possible."
-- Then: "also, redo the icons, so that it matches the icon style in zenless zone zero". We take
-- that game's style and nothing else: every icon here is our own drawing of our own subject, and
-- none is copied or traced from one of theirs.
--
-- The style, as rules (the Icons spec holds the ones that can be measured):
--   a 24 by 24 grid; the shape fills most of it and keeps 1.5 clear of the edge
--   solid: an icon is a filled silhouette in one colour, never an outline
--   details are cut out of the silhouette (the door out of a house, the hands out of a clock),
--   and parts stand apart with clear space between them; nothing is drawn on in a second tone
--   a cut or a space is 1.5 to 2 wide, so it still shows when the icon is 16 pixels across
--   a part that has to be a line (a handle, a hook, a stem) is 1.75 to 2.25 wide, with round
--   ends; a sign that is all lines (the plus, the cross, the tick, an arrow) is 4 wide, with
--   square ends
--   true circles and straight edges; a corner keeps its angle and loses only its point (a
--   rounding of half a unit)
--   45 and 90 degrees wherever the subject allows; what points comes to a real point (an arrow,
--   a roof, a picket, the pin), every arrow has a notch in its tail, and a slash cut across a
--   face always leans the same way, up to the right
--   whole numbers and halves, so edges land cleanly on pixels
--   centred on the grid by eye; a thing that stands on the ground may sit a little low
-- Each icon is a list of layers in SVG's path language (see UI/Vector), laid one over the other
-- and made with the helpers below. A plain string would be a line of the usual width
-- (Icons.Weight). Colours make coloured art (the coin).

local Vector = require(script.Parent.Vector)
local ItemArt = require(script.Parent.ItemArt)

local circle, rect, ellipse = Vector.circle, Vector.rect, Vector.ellipse

local IconArt = {}

local A: { [string]: { Vector.Layer } } = {}
IconArt.art = A

-- The layers (UI/Vector): solid (a filled shape, its corners taken off), flat (filled just as
-- written), hole (a shape rubbed out), gap (a line rubbed out, 2 wide unless told), clear (room
-- rubbed out round a shape about to be laid over others), line (a line of its own width).
local solid, flat, hole, gap, clear, line =
	Vector.solid, Vector.flat, Vector.hole, Vector.gap, Vector.clear, Vector.line

-- signs ------------------------------------------------------------------------------------------------

A.plus = { solid("M10.5 3 H13.5 V10.5 H21 V13.5 H13.5 V21 H10.5 V13.5 H3 V10.5 H10.5 Z") }
A.minus = { solid("M3 10.5 H21 V13.5 H3 Z") }
-- a car from the side: the body with its two windows cut out, two wheels under it (the Garage)
A.car = {
	solid("M2 15.5 V12.2 L4.6 11 L7.6 6.5 H15.6 L19 11 L21.6 12 L22 15.5 Z"),
	hole("M9 8.2 H11.4 V11 H7.2 Z M13 8.2 H14.9 L16.9 11 H13 Z"),
	clear(circle(7, 16.5, 2.6) .. " " .. circle(17, 16.5, 2.6), 1.5),
	flat(circle(7, 16.5, 2.6) .. " " .. circle(17, 16.5, 2.6)),
	hole(circle(7, 16.5, 0.9) .. " " .. circle(17, 16.5, 0.9)),
}
A.close = { solid("M12 10 L18 4 L20 6 L14 12 L20 18 L18 20 L12 14 L6 20 L4 18 L10 12 L4 6 L6 4 Z") }
A.check = { solid("M9 19.5 L21 7.5 L19 5.5 L9 15.5 L5 11.5 L3 13.5 Z") }
-- the arrows: a block arrow with a notch in its tail
A.up = { solid("M12 2.5 L21 11.5 H14 V21.5 L12 19.5 L10 21.5 V11.5 H3 Z") }
A.down = { solid("M12 21.5 L21 12.5 H14 V2.5 L12 4.5 L10 2.5 V12.5 H3 Z") }
A.back = { solid("M2.5 12 L11.5 3 V10 H21.5 L19.5 12 L21.5 14 H11.5 V21 Z") }
A.alert = { flat(circle(12, 12, 10.25)), hole("M10.25 5.5 H13.75 L13 13.5 H11 Z"), hole(circle(12, 17.5, 1.9)) }

-- the moods a villager shows over their head (Util/Bubble's MoodIcons), drawn to fill a badge:
-- a light bulb for a bright idea, the glass with a gleam cut out of it over a screw base
A.bulb = {
	flat("M8.5 15.75 V15.1 A7 7 0 1 1 15.5 15.1 V15.75 Z"),
	gap("M8.5 9.25 A3.5 3.5 0 0 1 12 5.75", 1.75),
	solid(rect(8.75, 17.5, 6.5, 3.5, 1)),
}
-- a question mark: its hook a line of its own, its dot a disc
A.question = {
	line("M7.75 8.25 A4.5 4.5 0 1 1 14.4 12.2 C12.9 13 12 14 12 15.75", 3.5),
	flat(circle(12, 20, 2.25)),
}
-- a sparkle: a star of four points with curved sides
A.sparkle = {
	flat(
		"M12 1.75 C12.75 8.25 15.75 11.25 22.25 12 C15.75 12.75 12.75 15.75 12 22.25 C11.25 15.75 8.25 12.75 1.75 12 C8.25 11.25 11.25 8.25 12 1.75 Z"
	),
}
-- cross: four short curved bars round a middle, each bowed in toward it
A.anger = {
	solid(
		"M3 8 C6.5 8 8 6.5 8 3 H11 C11 8.25 8.25 11 3 11 Z"
			.. " M21 8 C17.5 8 16 6.5 16 3 H13 C13 8.25 15.75 11 21 11 Z"
			.. " M21 16 C17.5 16 16 17.5 16 21 H13 C13 15.75 15.75 13 21 13 Z"
			.. " M3 16 C6.5 16 8 17.5 8 21 H11 C11 15.75 8.25 13 3 13 Z"
	),
}
A.eye = { flat("M1.5 12 A11.25 11.25 0 0 1 22.5 12 A11.25 11.25 0 0 1 1.5 12 Z"), gap(circle(12, 12, 4.25)) }
A.zoom = { flat(circle(10, 10, 8.25) .. " " .. circle(10, 10, 4.75)), solid("M14.5 16.5 L16.5 14.5 L22 20 L20 22 Z") }
A.grid = {
	flat(
		rect(1.75, 1.75, 9.25, 9.25, 1.25)
			.. " "
			.. rect(13, 1.75, 9.25, 9.25, 1.25)
			.. " "
			.. rect(1.75, 13, 9.25, 9.25, 1.25)
			.. " "
			.. rect(13, 13, 9.25, 9.25, 1.25)
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
	flat(rect(1.75, 1.75, 20.5, 20.5, 2.5)),
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
	solid("M7.5 4.5 L21 2.25 V16 H18.5 V6.7 L10 8.1 V18 H7.5 Z"),
	flat(ellipse(6.5, 18.25, 3.75, 3.1)),
	flat(ellipse(17.5, 16.25, 3.75, 3.1)),
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
-- a shopping bag, its handle hanging down the front
A.bag = {
	line("M8 7 A4 4 0 0 1 16 7", 2),
	solid("M4 7 H20 L21.5 21.5 H2.5 Z"),
	gap("M8 10 V10.5 A4 4 0 0 0 16 10.5 V10", 1.75),
}
A.gift = {
	flat(rect(2, 7.5, 20, 4.5, 1)),
	flat(rect(3.5, 13.5, 17, 8.5, 1)),
	gap("M12 7 V23"),
	flat("M12 7.5 L7.11 7.25 A2.75 2.75 0 1 1 9.67 3.19 Z"),
	flat("M12 7.5 L16.89 7.25 A2.75 2.75 0 1 0 14.33 3.19 Z"),
}
A.briefcase = {
	flat(rect(2, 7.5, 20, 14, 1.5)),
	line("M8.5 7.5 V5 A1.5 1.5 0 0 1 10 3.5 H14 A1.5 1.5 0 0 1 15.5 5 V7.5", 2.25),
	gap("M1 13.5 H8.75", 1.75),
	gap("M15.25 13.5 H23", 1.75),
}

-- people -----------------------------------------------------------------------------------------------

A.person = {
	flat(circle(12, 6.75, 4.75)),
	solid("M3 21.5 V20 A6.5 6.5 0 0 1 9.5 13.5 H14.5 A6.5 6.5 0 0 1 21 20 V21.5 Z"),
}
-- two of them, one a step behind
local FRONT = "M2 21.5 V20 A6 6 0 0 1 8 14 H9 A6 6 0 0 1 15 20 V21.5 Z"
A.people = {
	flat(circle(17.5, 6, 3.5)),
	solid("M11 21.5 V17.5 A5.5 5.5 0 0 1 16.5 12 H17 A5 5 0 0 1 22 17 V21.5 Z"),
	clear(circle(8.5, 7.5, 4.25), 1.75),
	clear(FRONT, 2.25),
	flat(circle(8.5, 7.5, 4.25)),
	solid(FRONT),
}
A.smile = {
	flat(circle(12, 12, 10.25)),
	hole(circle(8.5, 9.5, 1.7) .. " " .. circle(15.5, 9.5, 1.7)),
	gap("M6.8 14.5 A6 6 0 0 0 17.2 14.5"),
}
A.heart = { flat("M12 21.5 L3.33 11.74 A5.25 5.25 0 1 1 12 6.01 A5.25 5.25 0 1 1 20.67 11.74 Z") }

-- A face for each personality, for the creator's picker (the user: "for personality, make it
-- diferent faces to select from with their personality name below each face"): the disc with its
-- eyes and mouth cut out, a different pair for each (Data/Personalities). `face_<id>`.
local EYES: { [string]: { Vector.Layer } } = {
	dot = { hole(circle(8.5, 10, 1.7) .. " " .. circle(15.5, 10, 1.7)) },
	wide = { hole(circle(8.5, 9.5, 2.3) .. " " .. circle(15.5, 9.5, 2.3)) },
	up = { hole(circle(8.8, 8.6, 1.6) .. " " .. circle(15.8, 8.6, 1.6)) },
	down = { hole(circle(8.3, 11.2, 1.6) .. " " .. circle(15.3, 11.2, 1.6)) },
	happy = { gap("M6.6 10.6 A2 2 0 0 1 10.4 10.6 M13.6 10.6 A2 2 0 0 1 17.4 10.6") },
	closed = { gap("M6.6 9.4 A2 2 0 0 0 10.4 9.4 M13.6 9.4 A2 2 0 0 0 17.4 9.4") },
	sleepy = { gap("M6.4 10.4 H10.6 M13.4 10.4 H17.6") },
	wink = { hole(circle(8.5, 10, 1.7)), gap("M13.4 10 H17.6") },
	cross = {
		hole(circle(8.5, 10.6, 1.6) .. " " .. circle(15.5, 10.6, 1.6)),
		gap("M5.8 6.6 L10.4 8.2 M18.2 6.6 L13.6 8.2"),
	},
	brow = { hole(circle(8.5, 10.4, 1.6) .. " " .. circle(15.5, 10.4, 1.6)), gap("M13.4 6.8 L17.6 6.2") },
	shades = { hole("M5.2 8.4 H18.8 V11.8 H13.2 L12 10.6 L10.8 11.8 H5.2 Z") },
	glasses = { gap(circle(8.4, 10, 2.6) .. " " .. circle(15.6, 10, 2.6), 1.5) },
}
local MOUTH: { [string]: { Vector.Layer } } = {
	smile = { gap("M7.6 14.6 A5 5 0 0 0 16.4 14.6") },
	small = { gap("M9.6 15.2 A3 3 0 0 0 14.4 15.2") },
	grin = { hole("M7 14 H17 A5 5 0 0 1 7 14 Z") },
	flat = { gap("M9 16.2 H15") },
	frown = { gap("M8 18 A5 5 0 0 1 16 18") },
	o = { hole(circle(12, 16.4, 2)) },
	smirk = { gap("M8.8 15.8 L12.6 16.6 L15.6 14.4") },
	wavy = { gap("M7.8 16.4 L9.9 15.2 L12 16.4 L14.1 15.2 L16.2 16.4") },
	open = { hole("M8 14.2 H16 A4 4 0 0 1 8 14.2 Z") },
	tongue = { hole("M7.6 13.6 H16.4 A4.4 4.4 0 0 1 7.6 13.6 Z"), flat(circle(13.4, 17.1, 1.6)) },
}
local FACES: { [string]: { string } } = {
	sunny = { "happy", "grin" },
	gentle = { "closed", "small" },
	bold = { "cross", "grin" },
	dreamy = { "up", "small" },
	easygoing = { "sleepy", "smile" },
	proud = { "brow", "smirk" },
	shy = { "down", "flat" },
	cheeky = { "wink", "smirk" },
	cool = { "shades", "flat" },
	prickly = { "cross", "frown" },
	dramatic = { "wide", "o" },
	bookish = { "glasses", "small" },
	gloomy = { "sleepy", "frown" },
	polite = { "dot", "small" },
	foodie = { "dot", "tongue" },
	nervous = { "wide", "wavy" },
}
for id, f in FACES do
	local layers: { Vector.Layer } = { flat(circle(12, 12, 10.25)) }
	for _, l in EYES[f[1]] do
		table.insert(layers, l)
	end
	for _, l in MOUTH[f[2]] do
		table.insert(layers, l)
	end
	A["face_" .. id] = layers
end
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

-- The one colour forms of the art that has colours of its own, for where its own colours won't
-- read: the coin on a yellow block (the user: "make a black icon for coins as well where it is
-- required"). The indent is a ring cut out of the coin's face, as the icons' details are.
IconArt.mono = {
	coin = {
		{ circle(12, 12, 10), fill = true },
		{ circle(12, 12, 6), fill = true, cut = true },
		{ circle(12, 12, 4.25), fill = true },
	},
	coins = {
		{ circle(15, 14.5, 7), fill = true },
		{ circle(15, 14.5, 4.2), fill = true, cut = true },
		{ circle(15, 14.5, 2.6), fill = true },
		{ circle(9, 9.5, 8.6), fill = true, cut = true },
		{ circle(9, 9.5, 7), fill = true },
		{ circle(9, 9.5, 4.2), fill = true, cut = true },
		{ circle(9, 9.5, 2.6), fill = true },
	},
}

-- clothes (the creator's tabs) ---------------------------------------------------------------------

A.shirt = {
	solid(
		"M8.5 2.5 L2 6.5 L4.75 12 L7.5 10.75 V21.5 H16.5 V10.75 L19.25 12 L22 6.5 L15.5 2.5 A3.5 3.5 0 0 1 8.5 2.5 Z"
	),
}
A.pants = { solid("M5.5 2.5 H18.5 L20 21.5 H13.75 L12 9.5 L10.25 21.5 H4 Z"), gap("M3 6.5 H21", 1.5) }
A.shoe = {
	solid("M2.5 4.5 H7.5 L9.5 8.5 L17.5 10.5 A4.25 4.25 0 0 1 21.5 14.5 H2.5 Z"),
	gap("M11.5 7 L10.25 11", 1.5),
	gap("M15 8 L13.75 12", 1.5),
	flat(rect(2, 16.5, 20, 3.5, 1.25)),
}
-- a round hat with a band and a brim
A.hat = {
	flat("M5.5 14.5 V10 A6.5 6.5 0 0 1 18.5 10 V14.5 Z"),
	gap("M4.5 11.5 H19.5", 1.75),
	solid("M3 17 H21 L22 20 H2 Z"),
}
-- a comb
A.hair = {
	flat(rect(2, 4, 20, 16.5, 1)),
	hole("M4.4 10 H6.4 V21 H4.4 Z M8.8 10 H10.8 V21 H8.8 Z M13.2 10 H15.2 V21 H13.2 Z M17.6 10 H19.6 V21 H17.6 Z"),
}
-- a whole body, standing (the creator's Bodies)
A.figure = {
	flat(circle(12, 4.5, 3)),
	solid("M8 9.5 H16 L21.5 15 L19.5 17 L15.5 13 V22 H8.5 V13 L4.5 17 L2.5 15 Z"),
	gap("M12 16 V23"),
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
	line("M9.25 6 A2.75 2.75 0 1 1 12 8.75 V10.5", 2.25),
	solid("M12 9.5 L22 18 V21 H2 V18 Z M12 13.5 L17.25 18 H6.75 Z"),
}
-- a card with your face on it (My avatars)
A.idcard = {
	flat(rect(1.5, 4, 21, 16, 1.5)),
	hole(circle(8, 10, 2.4)),
	hole("M4.25 16.75 A3.75 3.75 0 0 1 11.75 16.75 Z"),
	gap("M15 9.5 H19"),
	gap("M15 14.5 H19"),
}

-- the tools --------------------------------------------------------------------------------------------

-- a heavy head square across its handle
A.hammer = { solid("M8.5 6.5 L12.5 2.5 L21.5 11.5 L17.5 15.5 Z"), solid("M12 10 L14 12 L4.5 21.5 L2.5 19.5 Z") }
A.pointer = { solid("M4 2 V20 L9 15.5 L12.5 22 L16.5 20 L13 13.5 H19.5 Z") }
-- Build mode's Select tool: the corners of a box drawn round what it picks, and the pointer
-- that drew it coming out of the fourth
A.select = {
	solid("M2 2 H9.5 V5 H5 V9.5 H2 Z"),
	solid("M22 2 V9.5 H19 V5 H14.5 V2 Z"),
	solid("M2 22 V14.5 H5 V19 H9.5 V22 Z"),
	solid("M11 11 V21.5 L13.75 18.75 L15.75 22.5 L18.25 21.25 L16.25 17.5 H20 Z"),
}
A.move = {
	solid(
		"M12 2 L16 6.5 H13.5 V10.5 H17.5 V8 L22 12 L17.5 16 V13.5 H13.5 V17.5 H16 L12 22 L8 17.5 H10.5 V13.5 H6.5 V16 L2 12 L6.5 8 V10.5 H10.5 V6.5 H8 Z"
	),
}
A.rotate = {
	solid("M20.25 13.5 A8.25 8.25 0 1 1 12 5.25 V7.75 A5.75 5.75 0 1 0 17.75 13.5 L19 14.75 Z"),
	solid("M11.5 2.5 L17.5 6.5 L11.5 10.5 Z"),
}
A.undo =
	{ solid("M2.5 8.5 L9 3.5 V7 H14.5 A7 7 0 0 1 14.5 21 H7.5 L9 19.5 L7.5 18 H14.5 A4 4 0 0 0 14.5 10 H9 V13.5 Z") }
A.redo =
	{ solid("M21.5 8.5 L15 3.5 V7 H9.5 A7 7 0 0 0 9.5 21 H16.5 L15 19.5 L16.5 18 H9.5 A4 4 0 0 1 9.5 10 H15 V13.5 Z") }
A.copy = {
	flat(rect(2, 2, 13.5, 13.5, 1.5)),
	clear(rect(8.5, 8.5, 13.5, 13.5, 1.5)),
	flat(rect(8.5, 8.5, 13.5, 13.5, 1.5)),
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
	gap("M9.4 5 V16.5", 1.5),
	gap("M14.6 5 V16.5", 1.5),
	flat(rect(10.25, 3.5, 3.5, 5, 1)),
	flat(rect(1.5, 17.25, 21, 3.5, 1.5)),
}
-- a tower crane with a load on its hook
A.crane = {
	solid("M6.5 2 H9.5 L22 5 V7.5 H9.5 V21.5 H6.5 V7.5 H5.5 V11 H2 V4.5 H6.5 Z"),
	flat(rect(3.5, 19.5, 9, 2.5, 0.75)),
	line("M18.5 7.5 V12.5", 1.75),
	flat(rect(15.5, 12.5, 6, 4.5, 0.75)),
}
-- a saved build (Build mode's Saves): a disk with its shutter and its label cut out
A.save = {
	solid("M2.5 2.5 H17 L21.5 7 V21.5 H2.5 Z"),
	hole(rect(6.5, 4.5, 8.5, 5, 0.5)),
	hole(rect(6, 13, 12, 6.5, 1)),
}
-- a padlock: what a pass would open
A.lock = {
	line("M7.75 10.5 V7.5 A4.25 4.25 0 0 1 16.25 7.5 V10.5", 2.25),
	solid(rect(3.5, 10, 17, 12, 1.5)),
	hole(circle(12, 14.75, 1.9)),
	hole("M11 15.5 H13 L13.5 19 H10.5 Z"),
}
A.blueprint = {
	flat(rect(2, 3.5, 20, 17, 1.5)),
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
	solid("M3.5 17 L11 16 L13 19 L10.5 21 H4.5 L3 19.5 Z", 2),
	solid("M12 9.5 L18.5 9 L20 11.5 L18.5 13.5 L13 13 L11.5 11.5 Z", 2),
	solid("M7.5 3.5 L12 3 L13 5 L11.5 6.5 L7.5 6 L6.5 4.5 Z", 2),
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
	hole("M5.5 16.5 A3 3 0 0 1 9 13 A3 3 0 0 1 5.5 16.5 Z"),
	hole("M10.5 12.5 A3 3 0 0 1 14 9 A3 3 0 0 1 10.5 12.5 Z"),
	hole("M14.5 18 A3 3 0 0 1 18 14.5 A3 3 0 0 1 14.5 18 Z"),
}
A.stoneWall = {
	flat(rect(2, 3, 20, 18, 2.5)),
	gap("M1 12 L8.5 11 L15.5 12.5 L23 11.5"),
	gap("M13.5 2 L12.5 12"),
	gap("M8 22 L8.5 11"),
	gap("M16.5 22 L15.5 12.5"),
}
-- the fences that came later (Plan.WallStyles): a low brick wall under its coping
A.brickWall = {
	flat(rect(1.5, 7, 21, 3, 0.75)),
	flat(rect(2.5, 11.5, 19, 10.5, 0.5)),
	gap("M1 16.75 H23"),
	gap("M8.5 12 V16.75"),
	gap("M15.5 12 V16.75"),
	gap("M12 16.75 V23"),
}
-- a ranch fence: two posts and three rails
A.railFence = {
	flat(rect(4, 3, 3.5, 19, 0.5) .. " " .. rect(16.5, 3, 3.5, 19, 0.5)),
	flat(rect(1.5, 6, 21, 3, 0.5) .. " " .. rect(1.5, 11.5, 21, 3, 0.5) .. " " .. rect(1.5, 17, 21, 3, 0.5)),
}
-- iron bars with spear points, on two rails
local function bar(x: number): string
	return string.format("M%s 21.5 V7 L%s 2.5 L%s 7 V21.5 Z", tostring(x), tostring(x + 1.25), tostring(x + 2.5))
end
A.ironFence = {
	solid(bar(2.5) .. " " .. bar(8) .. " " .. bar(13.5) .. " " .. bar(19)),
	flat(rect(1.5, 9.5, 21, 2.25) .. " " .. rect(1.5, 16.5, 21, 2.25)),
}
-- canes of bamboo, cut across at their joints
A.bamboo = {
	flat(
		rect(2, 3, 3.5, 19, 1.5)
			.. " "
			.. rect(7.25, 2, 3.5, 20, 1.5)
			.. " "
			.. rect(12.5, 4, 3.5, 18, 1.5)
			.. " "
			.. rect(17.75, 2.5, 3.5, 19.5, 1.5)
	),
	gap("M1 9 H23", 1.5),
	gap("M1 15.5 H23", 1.5),
}
-- round posts with two log rails across them, a ring cut in each post's top
A.logFence = {
	flat(rect(4, 2.5, 4.5, 19.5, 2.25) .. " " .. rect(15.5, 2.5, 4.5, 19.5, 2.25)),
	flat(rect(1.5, 8.5, 21, 3.5, 1.75)),
	flat(rect(1.5, 15, 21, 3.5, 1.75)),
	hole(circle(6.25, 5.25, 0.9) .. " " .. circle(17.75, 5.25, 0.9)),
}
-- withies woven between stakes
A.wovenFence = {
	flat(rect(2, 4.5, 20, 15, 1.5)),
	flat(rect(5, 2, 2.5, 20) .. " " .. rect(16.5, 2, 2.5, 20)),
	gap("M1 9.5 Q6.5 7.5 12 9.5 Q17.5 11.5 23 9.5", 1.5),
	gap("M1 14.5 Q6.5 12.5 12 14.5 Q17.5 16.5 23 14.5", 1.5),
}
-- two capped posts and the ropes hanging between them
A.ropeFence = {
	solid("M3 22 V7 L5 4 L7 7 V22 Z"),
	solid("M17 22 V7 L19 4 L21 7 V22 Z"),
	line("M6 9.5 Q12 15.5 18 9.5", 2),
	line("M6 15.5 Q12 20.5 18 15.5", 2),
}
-- a glass panel between two posts, under a handrail
A.glassRail = {
	flat(rect(1.5, 3, 21, 3, 1)),
	flat(rect(2.5, 4, 2.5, 18) .. " " .. rect(19, 4, 2.5, 18)),
	flat(rect(6.5, 7.5, 11, 13, 0.75)),
	gap("M8.5 17.5 L13 13", 1.75),
	gap("M12.5 18.5 L15 16", 1.75),
}
-- a rail lit along its length, with a spark of light between its bars
A.lightRail = {
	flat(rect(1.5, 4, 21, 3, 1.5) .. " " .. rect(1.5, 16.5, 21, 3, 1.5)),
	flat(rect(3.5, 4, 3, 18) .. " " .. rect(17.5, 4, 3, 18)),
	solid("M12 8.5 L13.25 10.5 L15.5 11.75 L13.25 13 L12 15 L10.75 13 L8.5 11.75 L10.75 10.5 Z"),
}
-- a column: its capital, its fluted shaft and its base
A.pillar = {
	flat(rect(4, 2.5, 16, 3, 0.75)),
	flat(rect(6.5, 7, 11, 11)),
	gap("M10.25 6.75 V18.25", 1.5),
	gap("M13.75 6.75 V18.25", 1.5),
	flat(rect(4, 19.5, 16, 3, 0.75)),
}
-- the basic shapes: a cube seen from above a corner
A.shapes = {
	solid("M12 2 L21 7 V17 L12 22 L3 17 V7 Z"),
	gap("M3 7.5 L12 12.5 L21 7.5", 1.75),
	gap("M12 12.5 V23", 1.75),
}
-- a picture: hills and the sun cut out of it
A.picture = {
	flat(rect(2, 4, 20, 16, 2)),
	hole("M5 17 L9.5 10.5 L12.75 15 L15 12.25 L19 17 Z"),
	hole(circle(16, 8.5, 1.75)),
}
-- a road arrow and the dashes of a line
A.marking = {
	solid("M12 2 L18.5 9 H14 V13 L12 11.5 L10 13 V9 H5.5 Z"),
	flat(rect(10, 14.5, 4, 3, 0.5) .. " " .. rect(10, 19.5, 4, 3, 0.5)),
}
-- water (Build mode's pools and ponds): a drop, with the light on it cut out low on its left
A.water = {
	flat("M12 2.25 L17.75 10.25 A7.25 7.25 0 1 1 6.25 10.25 Z"),
	gap("M7.75 14.5 A4.25 4.25 0 0 0 11 18.75", 1.75),
}
-- the looks Build mode lists across every category (Catalog.Styles): a painter's palette for them
-- all, then one each
A.styles = {
	flat(circle(12, 12, 10)),
	hole(circle(16.5, 16, 2.25)),
	hole(circle(7, 10, 1.75) .. " " .. circle(11, 6.25, 1.75) .. " " .. circle(16, 7.5, 1.75)),
	hole(circle(7.75, 15.5, 1.75)),
}
-- cozy: a mug of something hot
A.mug = {
	solid("M3.5 8 H15.5 V17.5 A4 4 0 0 1 11.5 21.5 H7.5 A4 4 0 0 1 3.5 17.5 Z"),
	line("M15.5 10.75 H17.25 A2.75 2.75 0 0 1 17.25 16.25 H15.5", 2.25),
	line("M7.5 2.5 V5", 2),
	line("M11.5 2.5 V5", 2),
}
-- sci-fi: a rocket
A.rocket = {
	solid("M12 1.5 A9 9 0 0 1 16 9.5 V16 H8 V9.5 A9 9 0 0 1 12 1.5 Z"),
	hole(circle(12, 9, 1.75)),
	flat("M8 11.5 L4 15.5 V19 L8 17 Z M16 11.5 L20 15.5 V19 L16 17 Z"),
	flat("M9.5 17.5 H14.5 L12 22.5 Z"),
}
-- seaside: an anchor
A.anchor = {
	flat(circle(12, 4.75, 3)),
	hole(circle(12, 4.75, 1.25)),
	flat(rect(10.75, 7.5, 2.5, 13) .. " " .. rect(7, 9.5, 10, 2.5, 1)),
	line("M4.5 13.5 A7.5 7.5 0 0 0 19.5 13.5", 2.5),
}
-- rustic: a barrel and its hoops
A.barrel = {
	flat("M7 2.5 H17 A14 14 0 0 1 17 21.5 H7 A14 14 0 0 1 7 2.5 Z"),
	gap("M2 7.5 H22", 1.75),
	gap("M2 16.5 H22", 1.75),
}
-- fancy: a cut gem
A.gem = {
	solid("M7 3 H17 L22 9 L12 21.5 L2 9 Z"),
	gap("M1 9 H23", 1.75),
	gap("M9.5 2 L8 9", 1.75),
	gap("M14.5 2 L16 9", 1.75),
}
-- playful: a balloon on its string
A.balloon = {
	flat(ellipse(12, 9, 7, 7.5)),
	gap("M8 8.5 A4.5 4.5 0 0 1 11 4.75", 1.75),
	flat("M10.25 16 H13.75 L12 18.25 Z"),
	line("M12 18 Q10 20 12 22", 1.75),
}

-- a room on a plan, its door open
A.room = {
	flat(rect(2, 2, 20, 20, 1.5) .. " M5.5 5.5 H18.5 V18.5 H5.5 Z"),
	hole("M8 18 H14 V23 H8 Z"),
	flat("M15 19.5 L13.5 21 L8.5 16 L10 14.5 Z"),
}
A.floor = { solid("M12 3 L22 12 L12 21 L2 12 Z"), gap("M6 6.6 L18 17.4", 1.75), gap("M18 6.6 L6 17.4", 1.75) }
-- the roofs stand on one line, so they can be told apart side by side
A.roof = { solid("M2 18.5 L6.5 5.5 L11 18.5 Z"), solid("M9.6 5.5 H17.5 L22 18.5 H14.1 Z") }
A.roofHip =
	{ solid("M2 18.5 L7.5 5.5 H16.5 L22 18.5 Z"), gap("M7.75 4.5 L9.25 20", 1.75), gap("M16.25 4.5 L14.75 20", 1.75) }
A.roofPyramid = { solid("M12 4.5 L22 17 L9 19.5 L2 17 Z"), gap("M12.2 3.5 L8.8 20.5", 1.75) }
A.roofShed = { solid("M2 18.5 L22 6.5 V18.5 Z") }
A.roofFlat = { solid("M2 9.5 H22 V13.5 H20 V18.5 H4 V13.5 H2 Z") }
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
local SEAT = "M2 10 A1.75 1.75 0 0 1 5.5 10 V13.5 H18.5 V10 A1.75 1.75 0 0 1 22 10 V19 H2 Z"
A.sofa = {
	flat(rect(4.5, 3, 15, 10, 2.5)),
	clear(SEAT, 2.25),
	solid(SEAT),
	flat(rect(3.5, 19, 2.5, 2.25, 0.5) .. " " .. rect(18, 19, 2.5, 2.25, 0.5)),
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
-- a tub on its feet, the tap running, two bubbles
A.bath = {
	flat(rect(1.5, 10, 21, 3, 1.5)),
	flat("M3.5 14.5 H20.5 A6 6 0 0 1 14.5 20.5 H9.5 A6 6 0 0 1 3.5 14.5 Z"),
	flat("M6.5 20 H9 L8 22.5 H5.5 Z M15 20 H17.5 L18.5 22.5 H16 Z"),
	line("M6 10 V5.75 A2.25 2.25 0 0 1 10.5 5.75 V6.5", 2.25),
	flat(circle(15.75, 6, 2.1) .. " " .. circle(19.5, 3.5, 1.4)),
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
	flat(circle(12, 9.75, 8.25)),
	gap("M12 16.5 V10.5", 1.75),
	gap("M12 14 L15 11", 1.75),
	gap("M12 12 L9 9", 1.75),
	flat(rect(10.5, 16.5, 3, 6, 0.5)),
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
-- the smaller cloud the weather falls from, and what falls
local function weather(...: Vector.Layer): { Vector.Layer }
	local art: { Vector.Layer } = {
		flat(circle(6.5, 10.5, 4.25)),
		flat(circle(12, 7.75, 5.5)),
		flat(circle(17.5, 10.75, 4)),
		flat(rect(6.5, 9.5, 11, 5.25)),
	}
	for _, layer in { ... } do
		table.insert(art, layer)
	end
	return art
end
A.rain =
	weather(line("M8.25 17.5 L6.75 21", 2.25), line("M12.75 17.5 L11.25 21", 2.25), line("M17.25 17.5 L15.75 21", 2.25))
local BOLT = "M12.5 11 H16.5 L14.25 15.5 H17.5 L10 22.5 L11.75 17.5 H8.5 Z"
A.storm = weather(clear(BOLT, 1.75), flat(BOLT))
A.snow = weather(flat(circle(7.5, 18.25, 1.5) .. " " .. circle(12, 20.75, 1.5) .. " " .. circle(16.5, 18.25, 1.5)))
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
-- fog: the cloud over two bands of mist
A.fog = weather(solid(rect(3.5, 16.75, 17, 2, 1)), solid(rect(6.5, 20.25, 11, 2, 1)))
-- a cog for Settings: a wheel with eight teeth, its middle cut out
A.gear = {
	solid(
		"M18 14 L22.25 14 L22.25 10 L18 10 Z M14.83 17.66 L17.83 20.66 L20.66 17.83 L17.66 14.83 Z M10 18 L10 22.25 L14 22.25 L14 18 Z M6.34 14.83 L3.34 17.83 L6.17 20.66 L9.17 17.66 Z M6 10 L1.75 10 L1.75 14 L6 14 Z M9.17 6.34 L6.17 3.34 L3.34 6.17 L6.34 9.17 Z M14 6 L14 1.75 L10 1.75 L10 6 Z M17.66 9.17 L20.66 6.17 L17.83 3.34 L14.83 6.34 Z"
	),
	flat(circle(12, 12, 7.5)),
	hole(circle(12, 12, 3)),
}

-- the foods (UI/ItemArt): silhouettes by the same rules, shown in each food's own colour -------------

for name, art in ItemArt do
	A[name] = art
end

return IconArt
