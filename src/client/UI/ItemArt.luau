--!strict
-- Vector pictures of things: food and what the shop sells. The user: "make vector art for items
-- like carrots, cakes, etc.", then "redo the icons, so that it matches the icon style in zenless
-- zone zero ... this includes the food and things icons". We take that style and none of that
-- game's pictures or dishes: every thing here is our own design.
--
-- So each thing is painted with volume, lit from the top left. The painter (UI/Vector) has flat
-- fills and no gradients, so a form is a stack of shapes: its outline in a deep tone of its own
-- colour (a thin edge that keeps it clear of a dark panel and a light one), the base colour, a
-- darker tone on the side away from the light, a lighter one where the light lands, then a few
-- small bright glints on whatever is glossy. Shadows on food stay warm (a red shades to plum, a
-- yellow to amber, never to grey). A dish sits in or on something, seen a little from above:
-- `bowl` and `plate` below are the one bowl and the one plate, recoloured.
--
-- Drawn on the same 24 grid as the icons (UI/IconArt), big in the square with a margin of
-- about 1. The big shapes carry the picture at 24 pixels; the small marks only show in the
-- shop's big card. The name is the thing's id (Data/Foods, Data/Items).

local Vector = require(script.Parent.Vector)

local circle, ellipse, rect = Vector.circle, Vector.ellipse, Vector.rect

type Layers = { Vector.Layer }

local function rgb(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end

-- The brightest spot on anything glossy, and the shadow a thing casts on the table.
local GLINT = rgb(255, 250, 236)
local SHADOW = rgb(20, 12, 30)
local STEAM = rgb(216, 224, 240)

local function shadow(cx: number, cy: number, rx: number, ry: number): Vector.Layer
	return { ellipse(cx, cy, rx, ry), fill = SHADOW, opacity = 0.32 }
end

-- A shape with its thin deep edge: the edge goes down first, a little wider than the shape.
local function edged(d: string, deep: Color3, base: Color3): (Vector.Layer, Vector.Layer)
	return { d, fill = deep, stroke = deep, w = 0.7 }, { d, fill = base }
end

-- Several lists of layers as one.
local function join(...: Layers): Layers
	local out: Layers = {}
	for _, list in { ... } do
		for _, layer in list do
			table.insert(out, layer)
		end
	end
	return out
end

-- Moves a path: every point scaled by k (from the grid's corner), then shifted by (dx, dy).
-- For paths written with capital commands, which is all of them here.
local SHAPE: { [string]: string } =
	{ M = "xy", L = "xy", H = "x", V = "y", C = "xy", S = "xy", Q = "xy", T = "xy", A = "rr...xy", Z = "" }
local function movePath(d: string, dx: number, dy: number, k: number): string
	local out: { string } = {}
	local kinds, at = "", 0
	local pos = 1
	while pos <= #d do
		local a, b = string.find(d, "^[%s,]*%a", pos)
		if a and b then
			local command = string.sub(d, b, b)
			kinds, at = SHAPE[command] or "", 0
			table.insert(out, command)
			pos = b + 1
		else
			a, b = string.find(d, "^[%s,]*[%+%-]?%d*%.?%d+", pos)
			if not a or not b then
				break
			end
			local n = tonumber((string.gsub(string.sub(d, a, b), "[%s,]", ""))) or 0
			local kind = string.sub(kinds, at % #kinds + 1, at % #kinds + 1)
			at += 1
			if kind == "x" then
				n = n * k + dx
			elseif kind == "y" then
				n = n * k + dy
			elseif kind == "r" then
				n *= k
			end
			table.insert(out, string.format("%.3f", n))
			pos = b + 1
		end
	end
	return table.concat(out, " ")
end

-- The same for a whole drawing (strokes keep their weight in step with the size).
local function moved(layers: Layers, dx: number, dy: number, k: number?): Layers
	local scale = k or 1
	local out: Layers = {}
	for _, layer in layers do
		local l: { [any]: any } = if type(layer) == "string" then { layer } else table.clone(layer :: any)
		l[1] = movePath(l[1], dx, dy, scale)
		if l.w then
			l.w *= scale
		end
		table.insert(out, l)
	end
	return out
end

-- The kit: the bowl, the plate and other things more than one picture uses.

-- What a glazed or solid thing is painted in: its edge, its dark side, itself, its light side,
-- and for a dish its rim and the wall inside.
type Tones = { deep: Color3, shade: Color3, base: Color3, light: Color3, rim: Color3?, inside: Color3? }

-- The bowl, seen a little from above: the rim is an ellipse round (12, 11.8), 20.4 wide. What
-- is in it goes on top: a soup's surface is ellipse(12, 12.5, 8.9, 2.85).
local BOWL = "M1.8 11.8 C1.8 17.4 6.2 20.8 12 20.8 C17.8 20.8 22.2 17.4 22.2 11.8 Z"
local function bowl(c: Tones): Layers
	local rim = ellipse(12, 11.8, 10.2, 3.8)
	return {
		shadow(12, 21.8, 7.2, 1.3),
		{ "M8.2 19.4 H15.8 V21 Q15.8 22 12 22 Q8.2 22 8.2 21 Z", fill = c.deep },
		{ BOWL, fill = c.deep, stroke = c.deep, w = 0.7 },
		{ BOWL, fill = c.base },
		{
			"M22.2 11.8 C22.2 17.4 17.8 20.8 12 20.8 C9.6 20.8 7.4 20.2 5.7 19.1 C8 19.6 10.6 19.4 13 18.4 C16.8 16.9 19.4 14.6 20 11.8 Z",
			fill = c.shade,
		},
		{
			"M22.2 12.6 C21.9 17.6 17.7 20.8 12 20.8 C11.2 20.8 10.4 20.7 9.7 20.6 C15.6 20.4 20.6 17.4 21.4 12.6 Z",
			fill = c.deep,
			opacity = 0.5,
		},
		{ "M3.1 14.6 C3.7 16.6 4.9 18 6.4 19 C5.5 17.6 4.9 16.2 4.6 14.9 Z", fill = c.light },
		{ rim, fill = c.deep, stroke = c.deep, w = 0.7 },
		{ rim, fill = c.rim or c.light },
		{ "M2.9 11 C4.4 9.5 7.8 8.6 11.2 8.4", stroke = GLINT, w = 0.5, opacity = 0.85 },
		{ ellipse(12, 12, 9.4, 3.2), fill = c.inside or c.shade },
	}
end

-- The plate, seen the same way: its top is an ellipse round (12, 17.4), 21.2 wide, with a
-- shallow well in the middle.
local function plate(c: Tones): Layers
	local under = ellipse(12, 18.2, 10.6, 4.1)
	return {
		shadow(12, 19.3, 10.3, 3.8),
		{ under, fill = c.deep, stroke = c.deep, w = 0.7 },
		{ under, fill = c.shade },
		{ ellipse(12, 17.4, 10.6, 4.1), fill = c.base },
		{ "M2.3 16.3 C4 14.5 7.6 13.5 11.4 13.4", stroke = GLINT, w = 0.5, opacity = 0.8 },
		{ ellipse(12, 17.5, 7.8, 2.9), fill = c.shade },
		{ ellipse(12, 17.9, 7.5, 2.6), fill = c.inside or c.light },
	}
end

-- Steam off something hot: two pale wisps.
local function steam(x: number, y: number): Layers
	return moved({
		{ "M0 5.6 C-1.4 4.2 1.2 3.2 0 1.6 C-0.4 1 -0.2 0.5 0.2 0", stroke = STEAM, w = 1, opacity = 0.6 },
		{ "M5.4 5.2 C4.2 4 6.6 3 5.6 1.6", stroke = STEAM, w = 1, opacity = 0.6 },
	}, x, y)
end

-- An apple, in whatever it is made of: a round fruit with a dimple, a stem and a leaf.
local function apple(c: Tones): Layers
	local body =
		"M12 7.4 C9.6 5.2 2.2 5.4 2.2 12.2 C2.2 17.8 6.6 21.8 9.4 21.8 C10.8 21.8 11.2 21.2 12 21.2 C12.8 21.2 13.2 21.8 14.6 21.8 C17.4 21.8 21.8 17.8 21.8 12.2 C21.8 5.4 14.4 5.2 12 7.4 Z"
	return {
		shadow(12, 21.9, 7, 1.2),
		{ body, fill = c.deep, stroke = c.deep, w = 0.7 },
		{ body, fill = c.base },
		{
			"M19.2 7.2 C21 8.4 21.8 10.2 21.8 12.2 C21.8 17.8 17.4 21.8 14.6 21.8 C13.2 21.8 12.8 21.2 12 21.2 C11.2 21.2 10.8 21.8 9.4 21.8 C8.4 21.8 7.2 21.3 6 20.3 C8.5 21 11.5 20.4 14 18.6 C17.4 16.2 19.6 12 19.2 7.2 Z",
			fill = c.shade,
		},
		{
			"M21.2 9.6 C21.6 10.4 21.8 11.3 21.8 12.2 C21.8 17.8 17.4 21.8 14.6 21.8 C13.9 21.8 13.4 21.6 13 21.5 C16.6 20.6 20.6 16 21.2 9.6 Z",
			fill = c.deep,
			opacity = 0.55,
		},
		{
			"M3.6 12.4 C3.4 9 5.8 6.9 9 7.2 C10.6 7.4 11 8.6 10 9.4 C8.4 9.8 6.6 11.6 5.6 14.4 C4.6 14.8 3.7 13.8 3.6 12.4 Z",
			fill = c.light,
		},
		{ "M9.4 7.3 C10.6 8.9 13.4 8.9 14.6 7.3 C13.7 6.9 12.8 6.9 12 7.6 C11.2 6.9 10.3 6.9 9.4 7.3 Z", fill = c.deep, opacity = 0.6 },
		{
			"M4.5 11.4 C4.7 9.4 6 8.1 7.8 7.8 C6.7 8.8 6 10 5.6 11.6 C5.3 12.3 4.5 12.2 4.5 11.4 Z",
			fill = GLINT,
			opacity = 0.9,
		},
		{ circle(9.3, 7.9, 0.45), fill = GLINT, opacity = 0.8 },
		{ "M19.9 16.6 Q18.8 19 16.8 20.4", stroke = c.light, w = 0.5, opacity = 0.55 },
		{ "M12 8.2 C12 5.8 12.6 3.8 14 2.3", stroke = rgb(98, 58, 36), w = 1.5 },
		{ "M11.7 7.6 C11.7 5.8 12.3 3.9 13.5 2.6", stroke = rgb(176, 118, 68), w = 0.5 },
		{ "M13.5 5.7 C14.2 2.7 17.4 1.5 21.2 2.3 C20.4 5.7 17.1 7.3 13.5 5.7 Z", fill = rgb(34, 104, 56), stroke = rgb(34, 104, 56), w = 0.6 },
		{ "M13.5 5.7 C14.2 2.7 17.4 1.5 21.2 2.3 C20.4 5.7 17.1 7.3 13.5 5.7 Z", fill = rgb(58, 148, 66) },
		{ "M13.5 5.7 C14.2 2.7 17.4 1.5 21.2 2.3 C18.6 2.9 16 4 13.5 5.7 Z", fill = rgb(112, 198, 84) },
		{ "M15.6 3.6 C16.6 2.8 17.8 2.5 19 2.5", stroke = rgb(196, 240, 150), w = 0.4, opacity = 0.9 },
	}
end

local Art: { [string]: { Vector.Layer } } = {}

-- What the shop sells.

-- A party cake on a plate: sponge with cream through the middle, pink icing running down the
-- side, sprinkles and one lit candle.
Art.cake = join(
	moved(plate({
		deep = rgb(104, 118, 160),
		shade = rgb(172, 186, 214),
		base = rgb(230, 236, 247),
		light = rgb(246, 249, 253),
	}), 0, 0.4),
	{
		{ "M3.6 10 V17.4 A8.4 3.1 0 0 0 20.4 17.4 V10 Z", fill = rgb(140, 74, 40), stroke = rgb(140, 74, 40), w = 0.7 },
		{ "M3.6 10 V17.4 A8.4 3.1 0 0 0 20.4 17.4 V10 Z", fill = rgb(234, 172, 98) },
		{ "M3.6 13.3 A8.4 3.1 0 0 0 20.4 13.3 V14.5 A8.4 3.1 0 0 1 3.6 14.5 Z", fill = rgb(255, 240, 212) },
		{ "M16.6 10 H20.4 V17.4 A8.4 3.1 0 0 1 16.6 19.99 Z", fill = rgb(120, 44, 40), opacity = 0.26 },
		{ "M19 10 H20.4 V17.4 A8.4 3.1 0 0 1 19 19.11 Z", fill = rgb(120, 44, 40), opacity = 0.26 },
		{ "M3.6 10 H5.2 V19.2 A8.4 3.1 0 0 1 3.6 17.4 Z", fill = rgb(255, 244, 220), opacity = 0.3 },
		{
			"M3.6 10 V11.6 Q3.6 12.9 4.7 12.9 Q5.7 12.9 5.8 12.6 Q6.4 13.2 7.4 13.5 V15 Q7.4 16.3 8.6 16.3 Q9.8 16.3 9.8 15 V14 Q11 14.1 12.6 14 Q12.6 15.2 13.6 15.2 Q14.6 15.2 14.6 14.2 V13.9 Q15.6 13.7 16.4 13.5 V15.6 Q16.4 17 17.5 17 Q18.6 17 18.6 15.6 V12.8 Q19.6 12.2 20.4 11.4 V10 Z",
			fill = rgb(176, 44, 98),
			stroke = rgb(176, 44, 98),
			w = 0.5,
		},
		{
			"M3.6 10 V11.6 Q3.6 12.9 4.7 12.9 Q5.7 12.9 5.8 12.6 Q6.4 13.2 7.4 13.5 V15 Q7.4 16.3 8.6 16.3 Q9.8 16.3 9.8 15 V14 Q11 14.1 12.6 14 Q12.6 15.2 13.6 15.2 Q14.6 15.2 14.6 14.2 V13.9 Q15.6 13.7 16.4 13.5 V15.6 Q16.4 17 17.5 17 Q18.6 17 18.6 15.6 V12.8 Q19.6 12.2 20.4 11.4 V10 Z",
			fill = rgb(240, 96, 142),
		},
		{ "M16.4 13.5 V15.6 Q16.4 17 17.5 17 Q18.6 17 18.6 15.6 V12.8 Q19.6 12.2 20.4 11.4 V10 H16.4 Z", fill = rgb(206, 62, 116) },
		{ ellipse(12, 10, 8.4, 3.1), fill = rgb(176, 44, 98), stroke = rgb(176, 44, 98), w = 0.7 },
		{ ellipse(12, 10, 8.4, 3.1), fill = rgb(255, 146, 176) },
		{ ellipse(9.6, 9.3, 5, 1.6), fill = rgb(255, 190, 208), opacity = 0.85 },
		{ "M8 14.2 V15.2 M4.4 11.6 V12.1 M13.2 14 V14.5", stroke = rgb(255, 200, 216), w = 0.5 },
		{ "M6.6 10.6 L7.3 10.9 M10 11.9 L10.7 11.8 M16.6 11.2 L17.2 10.9", stroke = rgb(255, 232, 120), w = 0.45 },
		{ "M15.2 8.6 L15.9 8.4 M8.4 8.3 L9 8.6 M14 11.8 L14.6 12", stroke = rgb(130, 214, 240), w = 0.45 },
		{ ellipse(12, 10.2, 1.6, 0.6), fill = rgb(226, 92, 140) },
		{ rect(11.1, 5.2, 1.8, 5.1, 0.5), fill = rgb(40, 110, 176), stroke = rgb(40, 110, 176), w = 0.5 },
		{ rect(11.1, 5.2, 1.8, 5.1, 0.5), fill = rgb(104, 192, 236) },
		{ rect(12.2, 5.2, 0.7, 5.1, 0.35), fill = rgb(58, 140, 204) },
		{ "M11.3 7.3 L12.7 6.5 M11.3 9.1 L12.7 8.3", stroke = rgb(240, 250, 255), w = 0.45 },
		{
			"M12 1.1 C13.5 2.5 13.9 3.4 13.9 4 C13.9 5 13 5.6 12 5.6 C11 5.6 10.1 5 10.1 4 C10.1 3.4 10.5 2.5 12 1.1 Z",
			fill = rgb(255, 136, 36),
		},
		{
			"M12 2.7 C12.8 3.5 13 3.9 13 4.3 C13 4.9 12.5 5.2 12 5.2 C11.5 5.2 11 4.9 11 4.3 C11 3.9 11.2 3.5 12 2.7 Z",
			fill = rgb(255, 226, 110),
		},
		{ ellipse(12, 4.5, 0.4, 0.5), fill = GLINT },
	}
)

-- Medicine: a white bottle with a teal screw cap and a red cross on its label, and one
-- capsule lying in front of it.
Art.medicine = {
	shadow(12.4, 21.9, 8.4, 1.3),
	{ rect(8.6, 5.4, 6.8, 3.6, 0), fill = rgb(76, 92, 140), stroke = rgb(76, 92, 140), w = 0.7 },
	{ rect(8.6, 5.4, 6.8, 3.6, 0), fill = rgb(196, 208, 230) },
	{ rect(13.4, 5.4, 2, 3.6, 0), fill = rgb(150, 166, 204) },
	{
		"M5 10.4 C5 8.8 6.6 8 8.4 8 H15.6 C17.4 8 19 8.8 19 10.4 V19.8 C19 21.2 15.8 22.2 12 22.2 C8.2 22.2 5 21.2 5 19.8 Z",
		fill = rgb(76, 92, 140),
		stroke = rgb(76, 92, 140),
		w = 0.7,
	},
	{
		"M5 10.4 C5 8.8 6.6 8 8.4 8 H15.6 C17.4 8 19 8.8 19 10.4 V19.8 C19 21.2 15.8 22.2 12 22.2 C8.2 22.2 5 21.2 5 19.8 Z",
		fill = rgb(238, 243, 251),
	},
	{ "M5 11.6 C7 12.5 17 12.5 19 11.6 V18.8 C17 19.7 7 19.7 5 18.8 Z", fill = rgb(214, 244, 238) },
	{ "M5.3 12.4 C7.3 13.2 16.7 13.2 18.7 12.4", stroke = rgb(52, 176, 168), w = 0.6 },
	{ "M5.3 18.1 C7.3 18.9 16.7 18.9 18.7 18.1", stroke = rgb(52, 176, 168), w = 0.6 },
	{ rect(10.7, 12.7, 2.6, 5.4, 0.5) .. rect(9.3, 14.1, 5.4, 2.6, 0.5), fill = rgb(160, 24, 56), stroke = rgb(160, 24, 56), w = 0.4 },
	{ rect(10.7, 12.7, 2.6, 5.4, 0.5), fill = rgb(232, 62, 74) },
	{ rect(9.3, 14.1, 5.4, 2.6, 0.5), fill = rgb(232, 62, 74) },
	{ "M11.2 13.3 V14 M9.9 14.7 H10.6", stroke = rgb(255, 150, 150), w = 0.4 },
	{
		"M15 8 H15.6 C17.4 8 19 8.8 19 10.4 V19.8 C19 20.8 17.4 21.6 15 22 Z",
		fill = rgb(96, 116, 170),
		opacity = 0.34,
	},
	{ "M17.4 8.5 C18.4 8.9 19 9.6 19 10.4 V19.8 C19 20.4 18.4 21 17.4 21.4 Z", fill = rgb(96, 116, 170), opacity = 0.4 },
	{ rect(6.3, 10.2, 1, 9.6, 0.5), fill = rgb(255, 255, 255), opacity = 0.95 },
	{
		"M7.2 3 C7.2 2 9.4 1.4 12 1.4 C14.6 1.4 16.8 2 16.8 3 V6.2 C16.8 7.1 14.6 7.7 12 7.7 C9.4 7.7 7.2 7.1 7.2 6.2 Z",
		fill = rgb(12, 84, 92),
		stroke = rgb(12, 84, 92),
		w = 0.7,
	},
	{
		"M7.2 3 C7.2 2 9.4 1.4 12 1.4 C14.6 1.4 16.8 2 16.8 3 V6.2 C16.8 7.1 14.6 7.7 12 7.7 C9.4 7.7 7.2 7.1 7.2 6.2 Z",
		fill = rgb(46, 168, 162),
	},
	{ "M14.4 4.4 C15.8 4.1 16.8 3.6 16.8 3 V6.2 C16.8 6.8 15.8 7.3 14.4 7.5 Z", fill = rgb(24, 124, 130) },
	{ "M8.7 4.7 V6.9 M10.3 5 V7.2 M12 5.1 V7.3 M13.7 5 V7.2 M15.3 4.7 V6.9", stroke = rgb(18, 108, 116), w = 0.4 },
	{ ellipse(12, 3, 4.8, 1.5), fill = rgb(116, 218, 202) },
	{ ellipse(10.4, 2.6, 1.8, 0.45), fill = GLINT, opacity = 0.8 },
	{ "M15.9 21.3 L21 19.3", stroke = rgb(76, 92, 140), w = 3.1 },
	{ "M15.9 21.3 L21 19.3", stroke = rgb(244, 246, 251), w = 2.4 },
	{
		"M18.89 21.42 L16.34 22.42 A1.2 1.2 0 0 1 15.46 20.18 L18.01 19.18 Z",
		fill = rgb(232, 62, 74),
	},
	{ "M16.1 20.5 L17.6 19.9 M19.2 19.3 L20.6 18.75", stroke = rgb(255, 255, 255), w = 0.4, opacity = 0.8 },
}

-- Food.

-- An apple: red, plum on the side away from the light, a stem and one leaf.
Art.apple = apple({
	deep = rgb(128, 20, 50),
	shade = rgb(182, 30, 58),
	base = rgb(228, 52, 60),
	light = rgb(248, 104, 84),
})

-- Cheese: a wedge with a paler top, a rind down its far end and holes in the cut side.
Art.cheese = {
	shadow(12.6, 20.4, 10.2, 1.7),
	{ "M1.6 11.8 L14.4 3.2 L22.4 9.4 V18 L1.6 20.4 Z", fill = rgb(160, 86, 16), stroke = rgb(160, 86, 16), w = 0.7 },
	{ "M1.6 11.8 L22.4 9.4 V18 L1.6 20.4 Z", fill = rgb(255, 198, 56) },
	{ "M21 12 V18.16 L5 20 Z", fill = rgb(234, 150, 34), opacity = 0.55 },
	{ "M21 15.4 V18.16 L11 19.3 Z", fill = rgb(214, 124, 26), opacity = 0.5 },
	{ "M21 9.56 L22.4 9.4 V18 L21 18.16 Z", fill = rgb(206, 112, 24) },
	{ "M1.6 11.8 L14.4 3.2 L22.4 9.4 Z", fill = rgb(255, 228, 118) },
	{ "M3.4 10.9 L14.3 3.9 L15.7 5 L7.4 10.4 Z", fill = rgb(255, 244, 176), opacity = 0.85 },
	{ "M14.4 3.2 L22.4 9.4 L21 9.56 L13.5 3.8 Z", fill = rgb(232, 150, 40) },
	{ ellipse(12.2, 7.6, 1.6, 0.8), fill = rgb(240, 180, 60) },
	{ ellipse(12.5, 7.8, 1.1, 0.5), fill = rgb(250, 208, 90) },
	{ ellipse(16.8, 8.3, 0.9, 0.45), fill = rgb(240, 180, 60) },
	{ circle(7.4, 15.8, 2.1), fill = rgb(196, 112, 20) },
	{ circle(7.8, 16.2, 1.5), fill = rgb(236, 160, 40) },
	{ circle(13.8, 13.4, 1.3), fill = rgb(196, 112, 20) },
	{ circle(14.05, 13.65, 0.9), fill = rgb(236, 160, 40) },
	{ circle(17.3, 15.9, 1.6), fill = rgb(186, 104, 18) },
	{ circle(17.6, 16.2, 1.1), fill = rgb(226, 146, 34) },
	{ circle(3.6, 17.6, 0.8), fill = rgb(196, 112, 20) },
	{ circle(11.8, 17.6, 0.7), fill = rgb(196, 112, 20) },
	{ "M2.3 11.76 L21.7 9.52", stroke = GLINT, w = 0.45, opacity = 0.9 },
}

-- A bread roll: a round golden crust with three cuts across the top showing the crumb.
Art.bread = {
	shadow(12, 20.7, 9.6, 1.6),
	{
		"M1.8 15 C1.8 9 6 4.8 12 4.8 C18 4.8 22.2 9 22.2 15 C22.2 18.4 19.6 20.4 16.4 20.4 H7.6 C4.4 20.4 1.8 18.4 1.8 15 Z",
		fill = rgb(116, 58, 20),
		stroke = rgb(116, 58, 20),
		w = 0.7,
	},
	{
		"M1.8 15 C1.8 9 6 4.8 12 4.8 C18 4.8 22.2 9 22.2 15 C22.2 18.4 19.6 20.4 16.4 20.4 H7.6 C4.4 20.4 1.8 18.4 1.8 15 Z",
		fill = rgb(226, 154, 70),
	},
	{
		"M1.8 15 C1.8 18.4 4.4 20.4 7.6 20.4 H16.4 C19.6 20.4 22.2 18.4 22.2 15 C22.2 16.9 19.6 17.9 16.4 17.9 H7.6 C4.4 17.9 1.8 16.9 1.8 15 Z",
		fill = rgb(194, 114, 44),
	},
	{
		"M17.6 6.6 C20.6 8.4 22.2 11.4 22.2 15 C22.2 18.4 19.6 20.4 16.4 20.4 H12.6 C16.8 19.4 19.6 15.6 19.4 11 C19.3 9.4 18.6 7.8 17.6 6.6 Z",
		fill = rgb(164, 86, 32),
		opacity = 0.6,
	},
	{
		"M3.6 12.8 C4 8.6 7.8 5.9 12 5.9 C13.8 5.9 15.2 6.3 16.2 7 C12 7 7.4 9.4 5.6 14.2 C4.6 14.5 3.5 13.9 3.6 12.8 Z",
		fill = rgb(246, 194, 108),
	},
	{
		"M6 10.1 C7.6 9.5 9.4 11.2 9.4 13.9 C7.8 13.6 6.2 12.1 6 10.1 Z M10.7 8.3 C12.5 7.9 14.2 10 14.1 13 C12.4 12.6 10.8 10.6 10.7 8.3 Z M15.4 9.3 C17 9.1 18.5 11 18.3 13.8 C16.7 13.4 15.4 11.5 15.4 9.3 Z",
		fill = rgb(150, 80, 30),
		stroke = rgb(150, 80, 30),
		w = 0.5,
	},
	{
		"M6 10.1 C7.6 9.5 9.4 11.2 9.4 13.9 C7.8 13.6 6.2 12.1 6 10.1 Z M10.7 8.3 C12.5 7.9 14.2 10 14.1 13 C12.4 12.6 10.8 10.6 10.7 8.3 Z M15.4 9.3 C17 9.1 18.5 11 18.3 13.8 C16.7 13.4 15.4 11.5 15.4 9.3 Z",
		fill = rgb(255, 232, 180),
	},
	{
		"M6 10.1 C7.6 9.5 9.4 11.2 9.4 13.9 C8.9 12 7.8 10.7 6 10.1 Z M10.7 8.3 C12.5 7.9 14.2 10 14.1 13 C13.6 10.8 12.6 9.2 10.7 8.3 Z M15.4 9.3 C17 9.1 18.5 11 18.3 13.8 C17.9 11.8 17 10.2 15.4 9.3 Z",
		fill = rgb(226, 178, 112),
	},
	{ "M4.9 10.9 C5.5 9.3 6.8 8.2 8.2 7.6", stroke = rgb(255, 238, 196), w = 0.6, opacity = 0.9 },
	{
		circle(9.4, 7.1, 0.3) .. circle(14.6, 6.9, 0.3) .. circle(4.6, 14.4, 0.3) .. circle(19.9, 12.2, 0.3) .. circle(
			12.4,
			15.6,
			0.3
		) .. circle(8, 16.2, 0.28) .. circle(16.6, 15.8, 0.28),
		fill = rgb(255, 240, 206),
		opacity = 0.85,
	},
}

-- A carrot: an orange root pointing down to the left, grooves across it, and three leaves.
Art.carrot = {
	shadow(9.6, 21.9, 7.4, 1.1),
	{
		"M16 5.5 C14.5 3.6 15.3 1.5 17.6 1.1 C17.9 2.8 17.6 4.5 16.8 5.9 Z M17.3 6 C17.5 3.5 19.8 1.5 22.7 1.7 C22.5 4.4 20.6 6.5 18.1 6.9 Z M18.5 7.1 C20 6.1 22.1 6.5 22.9 8.4 C21.4 9.7 19.5 9.3 18.3 8.2 Z",
		fill = rgb(24, 92, 48),
		stroke = rgb(24, 92, 48),
		w = 0.7,
	},
	{ "M16 5.5 C14.5 3.6 15.3 1.5 17.6 1.1 C17.9 2.8 17.6 4.5 16.8 5.9 Z", fill = rgb(60, 150, 62) },
	{ "M17.3 6 C17.5 3.5 19.8 1.5 22.7 1.7 C22.5 4.4 20.6 6.5 18.1 6.9 Z", fill = rgb(98, 190, 78) },
	{ "M18.5 7.1 C20 6.1 22.1 6.5 22.9 8.4 C21.4 9.7 19.5 9.3 18.3 8.2 Z", fill = rgb(60, 150, 62) },
	{ "M17.6 1.1 C17.9 2.8 17.6 4.5 16.8 5.9 L16.4 5.7 C17 4.2 17.4 2.7 17.6 1.1 Z", fill = rgb(40, 122, 56) },
	{ "M22.7 1.7 C22.5 4.4 20.6 6.5 18.1 6.9 L17.7 6.4 C19.8 5.4 21.6 3.8 22.7 1.7 Z", fill = rgb(60, 150, 62) },
	{ "M22.9 8.4 C21.4 9.7 19.5 9.3 18.3 8.2 L18.4 7.7 C19.8 8.3 21.4 8.5 22.9 8.4 Z", fill = rgb(40, 122, 56) },
	{ "M18.4 5.6 C19.4 4.4 20.6 3.4 21.8 2.6", stroke = rgb(176, 232, 124), w = 0.4 },
	{
		"M18.2 6.4 C20.6 8.8 20 11.8 17.6 13.6 C13.6 16.6 8 20 3.6 22 C2.4 22.5 1.6 21.6 2.2 20.4 C4.4 16 7.6 10.6 10.6 6.6 C12.4 4.2 15.8 4 18.2 6.4 Z",
		fill = rgb(146, 56, 8),
		stroke = rgb(146, 56, 8),
		w = 0.7,
	},
	{
		"M18.2 6.4 C20.6 8.8 20 11.8 17.6 13.6 C13.6 16.6 8 20 3.6 22 C2.4 22.5 1.6 21.6 2.2 20.4 C4.4 16 7.6 10.6 10.6 6.6 C12.4 4.2 15.8 4 18.2 6.4 Z",
		fill = rgb(244, 132, 30),
	},
	{
		"M19.5 8.6 C20 10.6 19.3 12.3 17.6 13.6 C13.6 16.6 8 20 3.6 22 C2.9 22.3 2.4 22.1 2.2 21.6 C7 19.6 12.4 16.2 16.2 12.8 C17.8 11.4 19 10.2 19.5 8.6 Z",
		fill = rgb(208, 90, 14),
	},
	{
		"M11.6 7.2 C12.6 6 14 5.6 15.2 5.8 C13.6 6.6 12.4 7.8 11.2 9.6 C9.4 12.2 7.4 15.4 5.6 18.2 C5.3 18.5 5 18.2 5.2 17.8 C7 14.2 9.4 10.2 11.6 7.2 Z",
		fill = rgb(255, 176, 76),
	},
	{ "M13.8 9.4 L15.6 11 M9.6 13.6 L11.2 15 M6.4 17.4 L7.5 18.4 M11.4 10.4 L12 10.9 M16.4 7.4 L17.2 8.1", stroke = rgb(176, 72, 10), w = 0.55 },
	{ "M12.5 6.9 C13.1 6.4 13.8 6.2 14.5 6.2", stroke = GLINT, w = 0.5, opacity = 0.85 },
}

-- Mushroom soup: a blue bowl of creamy soup with slices of mushroom and a sprig of parsley on
-- it, and steam.
Art.soup = join(
	steam(9, 1.4),
	bowl({
		deep = rgb(22, 46, 104),
		shade = rgb(36, 82, 156),
		base = rgb(60, 124, 200),
		light = rgb(140, 192, 242),
		rim = rgb(246, 240, 226),
		inside = rgb(206, 196, 180),
	}),
	{
		{ "M2.6 14.6 C5 16.9 8.4 17.9 12 17.9 C15.6 17.9 19 16.9 21.4 14.6", stroke = rgb(246, 240, 226), w = 0.5, opacity = 0.8 },
		{ ellipse(12, 12.5, 8.9, 2.85), fill = rgb(150, 92, 48) },
		{ ellipse(12.15, 12.7, 8.3, 2.5), fill = rgb(210, 154, 88) },
		{ ellipse(11, 12.5, 5.6, 1.5), fill = rgb(230, 186, 122), opacity = 0.8 },
		{ "M14.6 11 C16.6 11 18.4 11.6 18.6 12.4 C18.7 13 17.6 13.2 16.8 13", stroke = rgb(252, 238, 208), w = 0.4, opacity = 0.9 },
		{ "M10.2 11.5 C10.2 10.4 13.8 10.4 13.8 11.5 Z", fill = rgb(232, 208, 168) },
		{
			"M5.2 13.4 C5 11.4 11.4 11.2 11.6 13.2 C10.6 12.9 9.8 12.9 9.3 13 L9.7 14.7 C9 15.1 7.9 15.1 7.4 14.7 L7.5 13 C6.8 13 6 13.1 5.2 13.4 Z",
			fill = rgb(140, 92, 56),
			stroke = rgb(140, 92, 56),
			w = 0.4,
		},
		{
			"M5.2 13.4 C5 11.4 11.4 11.2 11.6 13.2 C10.6 12.9 9.8 12.9 9.3 13 L9.7 14.7 C9 15.1 7.9 15.1 7.4 14.7 L7.5 13 C6.8 13 6 13.1 5.2 13.4 Z",
			fill = rgb(250, 238, 212),
		},
		{ "M5.6 13.2 C7 12.6 10 12.6 11.2 13", stroke = rgb(176, 124, 80), w = 0.4 },
		{ "M8.9 13.2 L9.2 14.6 C8.9 14.8 8.6 14.9 8.4 14.9", stroke = rgb(222, 198, 160), w = 0.4 },
		{
			"M13 13.2 C12.4 11.4 18 10.4 18.8 12.2 C17.8 12.1 17.1 12.3 16.7 12.5 L17.6 14.2 C17.1 14.7 16 14.9 15.5 14.6 L15 13 C14.3 13 13.6 13.1 13 13.2 Z",
			fill = rgb(140, 92, 56),
			stroke = rgb(140, 92, 56),
			w = 0.4,
		},
		{
			"M13 13.2 C12.4 11.4 18 10.4 18.8 12.2 C17.8 12.1 17.1 12.3 16.7 12.5 L17.6 14.2 C17.1 14.7 16 14.9 15.5 14.6 L15 13 C14.3 13 13.6 13.1 13 13.2 Z",
			fill = rgb(250, 238, 212),
		},
		{ "M13.4 13 C14.6 12.2 17 11.8 18.4 12", stroke = rgb(176, 124, 80), w = 0.4 },
		{
			"M10.9 14.3 C10.5 13.5 11.5 13.1 11.9 13.7 C12.3 13 13.3 13.4 12.9 14.1 C13.5 14.5 12.7 15.1 12.1 14.7 C11.7 15.1 10.7 14.9 10.9 14.3 Z",
			fill = rgb(62, 150, 58),
		},
		{ circle(11.6, 14, 0.3), fill = rgb(150, 220, 110) },
		{ circle(14.4, 14.6, 0.3) .. circle(18.6, 13.4, 0.3) .. circle(6.2, 14.2, 0.28), fill = rgb(84, 160, 62) },
		{ ellipse(5.6, 12, 1.1, 0.3), fill = GLINT, opacity = 0.7 },
	}
)

-- A grilled fish on a skewer: the stick runs corner to corner through a pale blue fish, head up.
Art.skewer = {
	{ "M2.7 21.3 L21.3 2.7", stroke = rgb(226, 188, 134), w = 1.4 },
	{ "M8.5 15.5 L2 15.7 Q6.2 17.8 8.3 22 Z", fill = rgb(110, 184, 210) },
	{ "M19 5 C13.1 3.4 7.7 8.2 7.1 15.2 L8.8 16.9 C15.8 16.3 20.6 10.9 19 5 Z", fill = rgb(143, 211, 232) },
	{ "M19 5 C20.6 10.9 15.8 16.3 8.8 16.9 L7.9 16.1 Q15.1 12.2 19 5 Z", fill = rgb(110, 184, 210) },
	{ "M8.9 11.4 L12.1 15.6 M11.6 8.3 L15.1 12.9", stroke = rgb(84, 150, 184), w = 1.1 },
	{ circle(15.7, 6.5, 0.8), fill = rgb(52, 70, 96) },
}

-- A berry tart: a wide fluted crust, purple jam and three berries on top.
Art.tart = {
	{
		"M2.5 11.5 L5 18.8 Q5.4 20 6.6 20.1 Q12 20.8 17.4 20.1 Q18.6 20 19 18.8 L21.5 11.5 Z",
		fill = rgb(226, 170, 100),
	},
	{
		"M6.3 15.2 L7.3 18.8 M9.2 15.9 L9.7 19.3 M12 16.1 V19.5 M14.8 15.9 L14.3 19.3 M17.7 15.2 L16.7 18.8",
		stroke = rgb(198, 138, 76),
		w = 0.9,
	},
	{ ellipse(12, 11.5, 9.5, 4), fill = rgb(244, 204, 138) },
	{ ellipse(12, 11.5, 8, 2.9), fill = rgb(128, 96, 192) },
	{ circle(7.2, 9.4, 3) .. circle(16.8, 9.6, 2.9), fill = rgb(164, 128, 226) },
	{ circle(12, 7.8, 3.5), fill = rgb(184, 150, 238) },
	{ circle(6.2, 8.3, 0.7) .. circle(10.8, 6.5, 0.8) .. circle(15.9, 8.6, 0.7), fill = rgb(226, 212, 252) },
}

-- A slice of honey cake: layers of sponge and cream under honey that runs down the cut side.
Art.honeycake = {
	{ "M3 11.5 L21 9 V20.5 H3 Z", fill = rgb(226, 150, 62), w = 1 },
	{ "M3 14.5 L21 12.8 M3 17.5 L21 16.7", stroke = rgb(255, 236, 200), w = 1.1 },
	{ "M3 11.5 L14.5 4.5 L21 9 Z", fill = rgb(250, 194, 64), w = 1 },
	{
		"M7 10.6 V13.6 A1.2 1.2 0 0 0 9.4 13.6 V10.4 Z M14 9.8 V15.4 A1.2 1.2 0 0 0 16.4 15.4 V9.5 Z",
		fill = rgb(250, 194, 64),
	},
}

-- A rice ball: white rice pressed into a rounded triangle, a dark wrap at the bottom.
Art.riceball = {
	{
		"M12 2.5 C14 2.5 15.5 4 16.5 6 L21 15.5 C22.5 19 20.5 21.5 17.5 21.5 H6.5 C3.5 21.5 1.5 19 3 15.5 L7.5 6 C8.5 4 10 2.5 12 2.5 Z",
		fill = rgb(247, 243, 234),
	},
	{
		"M16.5 6 L21 15.5 C22.5 19 20.5 21.5 17.5 21.5 H16 C18.5 21 19.5 18.5 18.6 16 Z",
		fill = rgb(222, 214, 198),
	},
	{ "M8 21.5 V14.5 Q8 13.5 9 13.5 H15 Q16 13.5 16 14.5 V21.5 Z", fill = rgb(72, 90, 106) },
}

-- Pancakes: a stack of three with syrup running over the edge and a pat of butter on top.
Art.pancakes = {
	{ rect(4.5, 9, 15, 10, 0), fill = rgb(196, 140, 84) },
	{ rect(2.5, 17.1, 19, 4.4, 2.2), fill = rgb(236, 196, 136) },
	{ rect(3, 12.1, 18, 4.4, 2.2), fill = rgb(236, 196, 136) },
	{ rect(3.5, 7.1, 17, 4.4, 2.2), fill = rgb(236, 196, 136) },
	{
		"M3.5 9.1 Q3.5 7.1 5.7 7.1 H18.3 Q20.5 7.1 20.5 9.1 Q20.5 9.8 19.5 9.8 H17 V16.3 A1.25 1.25 0 0 1 14.5 16.3 V9.8 H8.5 V12.6 A1.25 1.25 0 0 1 6 12.6 V9.8 H4.5 Q3.5 9.8 3.5 9.1 Z",
		fill = rgb(196, 112, 48),
	},
	{ rect(9.2, 3.8, 5.6, 4, 1), fill = rgb(255, 236, 150) },
}

-- Curry and rice on a teal plate: a heap of white rice on the left, curry pooled on the right.
Art.curry = {
	{ ellipse(12, 12, 9.5, 7.5), fill = rgb(104, 188, 180) },
	{ ellipse(12, 11.7, 7.9, 6), fill = rgb(150, 214, 204) },
	{ ellipse(14.3, 12, 5.5, 5.2), fill = rgb(226, 112, 50) },
	{
		"M4.4 11.8 Q4.2 9.2 6.6 8.6 Q8 6.9 10.2 7.6 Q12.6 7.2 13.2 9.4 Q14.6 10.8 13.6 12.8 Q13.6 15 11.4 15.2 Q9.4 16.4 7.4 15.4 Q4.8 15 4.4 11.8 Z",
		fill = rgb(250, 247, 240),
	},
	{ "M7 10.4 L8 10.8 M9.6 12.8 L10.6 12.4 M10 9.4 L11 9.8", stroke = rgb(214, 206, 190), w = 0.7 },
	{ circle(16.4, 9.6, 1.2) .. circle(17.6, 13.2, 1.3), fill = rgb(255, 208, 110) },
	{ circle(15.4, 15.2, 1.1), fill = rgb(176, 78, 36) },
}

-- A pumpkin pie from above: one slice pulled out, a spoon of cream on the rest.
Art.pie = {
	{
		"M10.8 13.2 L18.82 11.05 A8.3 8.3 0 1 1 12.95 5.18 Z M12.6 11.4 L14.75 3.38 A8.3 8.3 0 0 1 20.62 9.25 Z",
		fill = rgb(232, 182, 116),
		w = 0.8,
	},
	{
		"M10.8 13.2 L16.89 11.57 A6.3 6.3 0 1 1 12.43 7.11 Z M12.6 11.4 L14.23 5.31 A6.3 6.3 0 0 1 18.69 9.77 Z",
		fill = rgb(240, 138, 46),
	},
	{ circle(8.6, 15.2, 2.5), fill = rgb(255, 250, 240) },
}

-- An ice cream: one pink scoop on a waffle cone.
Art.icecream = {
	{ "M6.5 12.5 H17.5 L12.9 21.6 Q12 22.6 11.1 21.6 Z", fill = rgb(232, 178, 110) },
	{ "M9.6 13.4 L13.4 18.4 M14.4 13.4 L10.6 18.4", stroke = rgb(204, 146, 84), w = 0.9 },
	{ circle(12, 8.2, 6), fill = rgb(255, 209, 220) },
	{ "M15.86 3.6 A6 6 0 0 1 16.6 12.06 Q17.4 7.6 15.86 3.6 Z", fill = rgb(240, 170, 190) },
	{ rect(5.5, 10, 13, 3.4, 1.7), fill = rgb(255, 209, 220) },
	{ "M8.2 6.8 Q8.8 5 10.4 4.4", stroke = rgb(255, 242, 246), w = 1.2 },
}

-- A salad: a wooden bowl heaped with leaves and two slices of tomato.
Art.salad = {
	{ "M6 13 Q5 7 9 5.5 Q11 2.5 14.5 4 Q18.5 4 18.5 8 Q20 10 19 13 Z", fill = rgb(86, 160, 76) },
	{
		"M3.5 13 Q2.5 9.5 5.5 8.6 Q7 6.4 9.6 7.6 Q11.5 5.8 13.8 7.4 Q16.5 6.2 18 8.4 Q21.5 9 20.5 13 Z",
		fill = rgb(120, 191, 94),
	},
	{ circle(7.4, 10.4, 1.8) .. circle(16.4, 10.2, 1.7), fill = rgb(236, 98, 96) },
	{ "M2.5 12.5 H21.5 C21.5 17.5 17.5 21.5 12 21.5 C6.5 21.5 2.5 17.5 2.5 12.5 Z", fill = rgb(206, 150, 96) },
	{ rect(2.5, 12, 19, 2.2, 1.1), fill = rgb(230, 180, 124) },
}

-- A chocolate bar: brown squares with the foil and the red wrapper still on one corner.
Art.chocolate = {
	{ rect(4.5, 2.5, 15, 19, 1.6), fill = rgb(156, 102, 64) },
	{ "M9.5 3.5 V20 M14.5 3.5 V20 M5.5 7.25 H18.5 M5.5 12 H18.5", stroke = rgb(118, 74, 46), w = 0.9 },
	{ "M3.8 11 L20.2 16.6 V18.6 L3.8 13 Z", fill = rgb(222, 228, 240) },
	{ "M3.8 12.8 L20.2 18.4 V20.2 Q20.2 22 18.4 22 H5.6 Q3.8 22 3.8 20.2 Z", fill = rgb(232, 96, 104) },
}

-- A caramel pudding on a plate: pale custard with caramel over the top.
Art.pudding = {
	{ ellipse(12, 19.2, 9.5, 2.6), fill = rgb(214, 222, 238) },
	{
		"M7.7 4 H16.3 Q17.6 4 17.8 5 L20.2 18 Q20.4 19.6 18.8 19.6 H5.2 Q3.6 19.6 3.8 18 L6.2 5 Q6.4 4 7.7 4 Z",
		fill = rgb(255, 233, 168),
	},
	{
		"M18.45 8.5 L20.2 18 Q20.4 19.6 18.8 19.6 H16.8 Q17.6 14 16.6 9.6 Q17.6 9.2 18.45 8.5 Z",
		fill = rgb(240, 208, 130),
	},
	{
		"M7.7 4 H16.3 Q17.6 4 17.8 5 L18.45 8.5 Q15.5 10.6 12 9.3 Q8.5 8 5.35 9.6 L6.2 5 Q6.4 4 7.7 4 Z",
		fill = rgb(196, 120, 50),
	},
	{ "M6.5 12.5 L6 15.5", stroke = rgb(255, 246, 214), w = 1.1 },
}

-- Broccoli: a bumpy dark green head on a short pale stalk.
Art.broccoli = {
	shadow(12.2, 22, 4.6, 1),
	{
		"M8 13.4 C10 15 10.2 17 10.2 19.4 V20.6 C10.2 21.8 11 22.4 12.2 22.4 C13.4 22.4 14.2 21.8 14.2 20.6 V19.4 C14.2 17 14.6 15 16.6 13.4 Z",
		fill = rgb(44, 96, 44),
		stroke = rgb(44, 96, 44),
		w = 0.7,
	},
	{
		"M8 13.4 C10 15 10.2 17 10.2 19.4 V20.6 C10.2 21.8 11 22.4 12.2 22.4 C13.4 22.4 14.2 21.8 14.2 20.6 V19.4 C14.2 17 14.6 15 16.6 13.4 Z",
		fill = rgb(160, 208, 106),
	},
	{
		"M12.7 14 H16 C14.6 15.4 14.2 17.4 14.2 19.4 V20.6 C14.2 21.8 13.4 22.4 12.2 22.4 C13 21.8 12.9 20.6 12.9 19.4 C12.9 17.6 12.9 15.8 12.7 14 Z",
		fill = rgb(104, 162, 72),
	},
	{ "M8.4 13.8 H16.2 C15.8 14.5 15.4 15.1 15.2 15.8 C13 16.6 11 16.6 9.2 15.8 C9 15.1 8.8 14.4 8.4 13.8 Z", fill = rgb(70, 128, 58) },
	{ "M11 17.4 V20.6", stroke = rgb(214, 240, 164), w = 0.6 },
	{
		"M5.4 14.8 C2.6 14.4 1.6 12.4 2 10.4 C2.3 8.8 3.4 7.9 4.6 7.6 C4.2 5.2 6 3.6 8 3.6 C9 2 10.6 1.4 12.2 1.6 C14 1.4 15.6 2.2 16.4 3.8 C18.6 3.8 20.2 5.4 19.6 7.8 C21.4 8.4 22.4 9.8 22 11.6 C21.6 13.6 20.2 14.6 18.4 14.8 C16 15.6 14 15.4 12 14.6 C10 15.4 7.6 15.6 5.4 14.8 Z",
		fill = rgb(16, 72, 40),
		stroke = rgb(16, 72, 40),
		w = 0.7,
	},
	{
		"M5.4 14.8 C2.6 14.4 1.6 12.4 2 10.4 C2.3 8.8 3.4 7.9 4.6 7.6 C4.2 5.2 6 3.6 8 3.6 C9 2 10.6 1.4 12.2 1.6 C14 1.4 15.6 2.2 16.4 3.8 C18.6 3.8 20.2 5.4 19.6 7.8 C21.4 8.4 22.4 9.8 22 11.6 C21.6 13.6 20.2 14.6 18.4 14.8 C16 15.6 14 15.4 12 14.6 C10 15.4 7.6 15.6 5.4 14.8 Z",
		fill = rgb(62, 150, 62),
	},
	{
		"M2 10.6 C3.6 12.2 6 12.4 7.4 11.4 C8.8 13.2 11 13.4 12.4 12.2 C13.8 13.6 16.2 13.4 17.2 11.8 C18.8 12.6 21 12.2 22 10.6 C22.4 12.8 21 14.6 18.4 14.8 C16 15.6 14 15.4 12 14.6 C10 15.4 7.6 15.6 5.4 14.8 C2.8 14.4 1.6 12.6 2 10.6 Z",
		fill = rgb(34, 110, 52),
	},
	{
		"M16.4 3.8 C18.6 3.8 20.2 5.4 19.6 7.8 C21.4 8.4 22.4 9.8 22 11.6 C21.6 13.6 20.2 14.6 18.4 14.8 C17.4 15.1 16.4 15.3 15.6 15.3 C18.4 13.8 20 11.4 19.4 9.2 C19 7.4 18 5.4 16.4 3.8 Z",
		fill = rgb(16, 72, 40),
		opacity = 0.45,
	},
	{
		ellipse(6, 7.6, 2.1, 1.6) .. ellipse(11, 4.7, 2.7, 1.8) .. ellipse(16.2, 6.4, 2, 1.4) .. ellipse(9.4, 10, 1.6, 1.1) .. ellipse(
			14.2,
			10,
			1.6,
			1.1
		) .. ellipse(4, 10.4, 1.1, 0.8),
		fill = rgb(102, 188, 80),
	},
	{ ellipse(5.4, 7, 1, 0.6) .. ellipse(10.2, 4, 1.4, 0.75) .. ellipse(15.6, 5.9, 1, 0.55), fill = rgb(168, 228, 118) },
	{
		"M9 9 C8.6 10.3 7.4 11 6.2 10.8 M14.8 6 C14.4 7.6 13 8.5 11.4 8.4 M19.3 8.2 C18.9 9.5 17.7 10.1 16.4 9.9",
		stroke = rgb(30, 104, 50),
		w = 0.5,
	},
	{
		circle(7.6, 5.6, 0.3) .. circle(13.4, 3.4, 0.3) .. circle(17.6, 5.2, 0.3) .. circle(12, 10.6, 0.3) .. circle(6.4, 12.9, 0.3) .. circle(
			17.4,
			13.4,
			0.3
		) .. circle(10.6, 13.9, 0.3),
		fill = rgb(126, 204, 96),
		opacity = 0.8,
	},
}

-- Pickles: a jar of pale brine with three gherkins standing in it and a red lid.
Art.pickles = {
	{ rect(3.5, 6, 17, 15.8, 3.2), fill = rgb(200, 236, 180) },
	{
		rect(6, 9.2, 3.6, 10.4, 1.8) .. rect(10.3, 8.2, 3.6, 11.6, 1.8) .. rect(14.6, 9.6, 3.4, 10, 1.7),
		fill = rgb(112, 176, 84),
	},
	{
		circle(7.2, 12, 0.5) .. circle(8.4, 15.6, 0.5) .. circle(11.4, 11, 0.5) .. circle(12.8, 15, 0.5) .. circle(
			15.8,
			12.6,
			0.5
		) .. circle(16.8, 16.4, 0.5),
		fill = rgb(84, 148, 70),
	},
	{ rect(5, 2.5, 14, 4.2, 1.2), fill = rgb(232, 96, 104) },
}

-- A pot of stew: a red pot with two handles, filled past the rim.
Art.stew = {
	{ "M5 8 Q5.5 4.6 8 5.2 Q9.6 3.2 12 4.4 Q14.4 3.2 16 5.2 Q18.5 4.6 19 8 Z", fill = rgb(170, 112, 62) },
	{ circle(8.6, 6.8, 1.2), fill = rgb(240, 138, 46) },
	{ circle(12.4, 6.2, 1.3) .. circle(16, 7, 1), fill = rgb(250, 222, 150) },
	{ rect(2, 11, 20, 2.6, 1.3), fill = rgb(196, 72, 70) },
	{ "M4 9 H20 V16.5 Q20 20.5 16 20.5 H8 Q4 20.5 4 16.5 Z", fill = rgb(226, 98, 86) },
	{ "M17 9 H20 V16.5 Q20 20.5 16 20.5 H14 Q17 20 17 16.5 Z", fill = rgb(196, 72, 70) },
	{ rect(3, 7.6, 18, 2.6, 1.3), fill = rgb(242, 134, 116) },
}

-- A slice of star fruit: five fat points, the skin a shade deeper than the flesh, and the
-- seeds in a ring round the middle.
Art.starfruit = {
	{
		"M12 4 L14.8 8.9 L20.4 10.1 L16.6 14.3 L17.2 19.9 L12 17.6 L6.8 19.9 L7.4 14.3 L3.6 10.1 L9.2 8.9 Z",
		fill = rgb(228, 204, 78),
		w = 2.4,
	},
	{
		"M12 6.4 L14.3 9.6 L18.1 10.8 L15.7 14 L15.8 18 L12 16.7 L8.2 18 L8.3 14 L5.9 10.8 L9.7 9.6 Z",
		fill = rgb(255, 236, 160),
		w = 1.4,
	},
	{
		"M12 10.8 V9.2 M13.9 12.2 L15.4 11.7 M13.2 14.4 L14.1 15.7 M10.8 14.4 L9.9 15.7 M10.1 12.2 L8.6 11.7",
		stroke = rgb(204, 146, 62),
		w = 1.1,
	},
}

-- A dragon chili: a fat red pepper curling to a point, with a small flame beside it.
Art.dragonchili = {
	{
		"M6.5 2.5 Q9.6 5.6 8.8 8.6 Q8.2 10.8 6 10.8 Q3.5 10.8 3.4 8.4 Q3.4 7 4.6 6 Q5 7.2 5.8 7.2 Q5.6 4.8 6.5 2.5 Z",
		fill = rgb(255, 160, 60),
	},
	{ "M6.2 7.4 Q7.6 8.6 6.9 9.6 Q6.5 10.1 5.9 10.1 Q5 10 5.1 9 Q5.8 8.8 6.2 7.4 Z", fill = rgb(255, 222, 110) },
	{ "M17.5 6 Q18 4 20 3.2", stroke = rgb(98, 176, 84), w = 1.6 },
	{
		"M14 7.5 C14.5 5.5 20 5 20.8 8.5 C22 14.5 13 22.5 2.8 20.6 C9.5 19 12.5 13.5 14 7.5 Z",
		fill = rgb(222, 62, 66),
	},
	{ "M20.8 8.5 C22 14.5 13 22.5 2.8 20.6 C12 20.6 19.5 15.5 20.8 8.5 Z", fill = rgb(180, 44, 60) },
	{ "M13.6 8.4 Q13.6 5.6 17 5.4 Q20.4 5.2 21 8.6 Q17.4 7 13.6 8.4 Z", fill = rgb(98, 176, 84) },
	{ "M12.6 15.6 Q14.8 12.8 15.6 10", stroke = rgb(246, 124, 112), w = 1.2 },
}

-- A golden apple: the apple again in gold, with a sparkle on its shoulder.
Art.goldapple = join(
	apple({
		deep = rgb(146, 78, 10),
		shade = rgb(222, 142, 28),
		base = rgb(252, 198, 58),
		light = rgb(255, 232, 130),
	}),
	{
		{ "M7.2 8.6 Q7.7 11.5 10.6 12 Q7.7 12.5 7.2 15.4 Q6.7 12.5 3.8 12 Q6.7 11.5 7.2 8.6 Z", fill = rgb(255, 255, 255) },
		{ "M17 14.2 Q17.25 15.75 18.8 16 Q17.25 16.25 17 17.8 Q16.75 16.25 15.2 16 Q16.75 15.75 17 14.2 Z", fill = rgb(255, 255, 255), opacity = 0.9 },
	}
)

return Art
