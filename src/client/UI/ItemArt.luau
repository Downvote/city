--!strict
-- Vector pictures of things: food and what the shop sells. The user: "make vector art for items
-- like carrots, cakes, etc." Flat colour, a few shapes each, drawn on the same 24 grid as the
-- icons (UI/IconArt) and painted by UI/Vector. The name is the thing's id (Data/Foods,
-- Data/Items).

local Vector = require(script.Parent.Vector)

local circle, ellipse, rect = Vector.circle, Vector.ellipse, Vector.rect

local function rgb(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end

local Art: { [string]: { Vector.Layer } } = {}

-- What the shop sells.

-- A party cake: sponge with a cream line through it, pink icing running down the side and one
-- lit candle.
Art.cake = {
	{ "M3 13 H21 V20 Q21 22 19 22 H5 Q3 22 3 20 Z", fill = rgb(240, 190, 128) },
	{ rect(3, 17, 18, 1.6, 0), fill = rgb(255, 238, 205) },
	{
		"M3 12 Q3 9 6 9 H18 Q21 9 21 12 V13.5 H19.5 V14 A1.75 1.75 0 0 1 16 14 V13.5 H13 V15.5 A1.75 1.75 0 0 1 9.5 15.5 V13.5 H6.5 V14.5 A1.75 1.75 0 0 1 3 14.5 Z",
		fill = rgb(255, 143, 171),
	},
	{ "M6 11 H9", stroke = rgb(255, 196, 212), w = 1 },
	{ rect(10.8, 5.2, 2.4, 4.2, 0.6), fill = rgb(143, 211, 232) },
	{ "M12 2 Q14.2 4.4 12 6 Q9.8 4.4 12 2 Z", fill = rgb(255, 196, 70) },
}

-- Medicine: a white bottle with a teal cap and a red cross on the front.
Art.medicine = {
	{ rect(8.5, 5, 7, 4, 0), fill = rgb(205, 212, 228) },
	{ rect(5, 7.5, 14, 14.5, 2.5), fill = rgb(240, 244, 250) },
	{ "M16 7.5 H16.5 Q19 7.5 19 10 V19.5 Q19 22 16.5 22 H16 Z", fill = rgb(214, 222, 236) },
	{ rect(7, 2, 10, 4.2, 1.2), fill = rgb(92, 190, 180) },
	{ rect(10.8, 11.3, 2.4, 7, 0.4), fill = rgb(232, 96, 104) },
	{ rect(8.5, 13.6, 7, 2.4, 0.4), fill = rgb(232, 96, 104) },
}

-- Food.

-- An apple: red, a darker side away from the light, a stem and one leaf.
Art.apple = {
	{
		"M12 7.5 C10 5.5 3 6 3 12.5 C3 18 7 22 9.5 22 C10.8 22 11.2 21.4 12 21.4 C12.8 21.4 13.2 22 14.5 22 C17 22 21 18 21 12.5 C21 6 14 5.5 12 7.5 Z",
		fill = rgb(236, 98, 112),
	},
	{
		"M20.3 9.3 Q20.9 10.8 21 12.5 C21 18 17 22 14.5 22 Q13.7 22 13.2 21.8 C16.5 20 19.5 15.5 20.3 9.3 Z",
		fill = rgb(206, 72, 96),
	},
	{ "M6.3 11.4 Q6.8 9.4 8.8 8.8", stroke = rgb(255, 170, 176), w = 1.3 },
	{ "M12 8 Q12 5 13.5 3.2", stroke = rgb(150, 100, 64), w = 1.5 },
	{ "M13.3 5.6 Q15 2.2 19.5 3 Q18.2 6.8 13.3 5.6 Z", fill = rgb(118, 196, 96) },
}

-- A bread roll: a round crust with three cuts across the top and a darker underside.
Art.bread = {
	{
		"M2.5 14.5 C2.5 8.5 7 5 12 5 C17 5 21.5 8.5 21.5 14.5 C21.5 18 19.5 20 16.5 20 H7.5 C4.5 20 2.5 18 2.5 14.5 Z",
		fill = rgb(230, 176, 110),
	},
	{
		"M2.5 14.5 C2.5 18 4.5 20 7.5 20 H16.5 C19.5 20 21.5 18 21.5 14.5 C21.5 16.4 19.5 17.4 16.5 17.4 H7.5 C4.5 17.4 2.5 16.4 2.5 14.5 Z",
		fill = rgb(200, 138, 76),
	},
	{ "M7.2 9.8 Q8.6 11.2 8.4 13.6", stroke = rgb(252, 226, 176), w = 1.6 },
	{ "M11.8 8.6 Q13.2 10.2 13 12.8", stroke = rgb(252, 226, 176), w = 1.6 },
	{ "M16.2 9.6 Q17.4 11 17.2 13.4", stroke = rgb(252, 226, 176), w = 1.6 },
}

-- A carrot: an orange root pointing down to the left, two grooves, and a tuft of leaves.
Art.carrot = {
	{ "M14.5 4.5 Q13 2.5 11 3.5 Q12.5 5 13.5 7 Z", fill = rgb(98, 176, 84) },
	{ "M16.5 5 Q18 2 20.5 3 Q19 5.5 17 7.5 Z", fill = rgb(118, 196, 96) },
	{ "M19 7.5 Q21.5 7 21.5 9.5 Q19 10 17 9 Z", fill = rgb(98, 176, 84) },
	{ "M17.6 6.4 Q20.6 9.4 17.4 13 L5.6 21 Q2.6 22 3.2 18.6 L11 6.6 Q14.6 3.4 17.6 6.4 Z", fill = rgb(240, 138, 46) },
	{ "M12.5 9.5 L14.5 11.5", stroke = rgb(206, 104, 30), w = 1.4 },
	{ "M8.5 14.5 L10.5 16.5", stroke = rgb(206, 104, 30), w = 1.4 },
}

-- Cheese: a wedge with a paler top and three holes in the cut side.
Art.cheese = {
	{ "M3 12.5 L14 4.5 L21 9.5 V20 H3 Z", fill = rgb(255, 204, 72), w = 1 },
	{ "M3 12.5 L14 4.5 L21 9.5 Z", fill = rgb(255, 230, 140), w = 1 },
	{ circle(8, 16.6, 1.9), fill = rgb(232, 166, 44) },
	{ circle(14.4, 14.2, 1.3), fill = rgb(232, 166, 44) },
	{ circle(17.2, 17.6, 1.5), fill = rgb(232, 166, 44) },
}

-- Mushroom soup: a blue bowl, brown soup with a slice of mushroom on it, and steam.
Art.soup = {
	{ "M2.5 12 C2.5 18 6.5 21.8 12 21.8 C17.5 21.8 21.5 18 21.5 12 Z", fill = rgb(126, 176, 222) },
	{ ellipse(12, 12, 9.5, 3.8), fill = rgb(160, 204, 240) },
	{ ellipse(12, 12.2, 8, 2.7), fill = rgb(196, 142, 88) },
	{ "M9.6 12.4 Q9.6 10.2 12 10.2 Q14.4 10.2 14.4 12.4 Z", fill = rgb(246, 228, 196) },
	{ rect(11.2, 12, 1.6, 1.9, 0.6), fill = rgb(246, 228, 196) },
	{
		"M9.2 7 Q8 5.6 9.2 4.4 Q10 3.6 9.4 2.8 M14.7 7 Q13.5 5.6 14.7 4.4 Q15.5 3.6 14.9 2.8",
		stroke = rgb(236, 240, 247),
		w = 1.3,
		opacity = 0.75,
	},
}

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

-- Broccoli: a bumpy green head on a short pale stalk.
Art.broccoli = {
	{ "M7.5 13 Q10 15 10 18 V20 Q10 21.8 12 21.8 Q14 21.8 14 20 V18 Q14 15 16.5 13 Z", fill = rgb(160, 208, 120) },
	{
		"M5.5 14.5 Q2.5 14 2.5 11 Q2.5 8.5 4.8 7.8 Q4.5 4.5 7.8 4 Q9.5 2 12 2.5 Q14.5 2 16.2 4 Q19.5 4.5 19.2 7.8 Q21.5 8.5 21.5 11 Q21.5 14 18.5 14.5 Q15 15.5 12 14.5 Q9 15.5 5.5 14.5 Z",
		fill = rgb(92, 170, 80),
	},
	{
		"M5.5 14.5 Q2.5 14 2.5 11 Q4.5 12.5 7 11.5 Q9.5 13.5 12 12 Q14.5 13.5 17 11.5 Q19.5 12.5 21.5 11 Q21.5 14 18.5 14.5 Q15 15.5 12 14.5 Q9 15.5 5.5 14.5 Z",
		fill = rgb(66, 142, 66),
	},
	{ "M6.8 7.4 Q7.4 6 9 5.6", stroke = rgb(140, 206, 112), w = 1.2 },
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

-- A golden apple: the apple again in gold, with a glint on its shoulder.
Art.goldapple = {
	{
		"M12 7.5 C10 5.5 3 6 3 12.5 C3 18 7 22 9.5 22 C10.8 22 11.2 21.4 12 21.4 C12.8 21.4 13.2 22 14.5 22 C17 22 21 18 21 12.5 C21 6 14 5.5 12 7.5 Z",
		fill = rgb(244, 198, 78),
	},
	{
		"M20.3 9.3 Q20.9 10.8 21 12.5 C21 18 17 22 14.5 22 Q13.7 22 13.2 21.8 C16.5 20 19.5 15.5 20.3 9.3 Z",
		fill = rgb(216, 160, 56),
	},
	{ "M12 8 Q12 5 13.5 3.2", stroke = rgb(150, 100, 64), w = 1.5 },
	{ "M13.3 5.6 Q15 2.2 19.5 3 Q18.2 6.8 13.3 5.6 Z", fill = rgb(118, 196, 96) },
	{ "M7.6 8 Q8 11 11 11.4 Q8 11.8 7.6 14.8 Q7.2 11.8 4.2 11.4 Q7.2 11 7.6 8 Z", fill = rgb(255, 250, 230) },
}

return Art
