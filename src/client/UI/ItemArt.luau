--!strict
-- The foods: what villagers crave, as icons. The user: "make vector art for items like carrots,
-- cakes, etc.", then "redo the icons, so that it matches the icon style in zenless zone zero ...
-- this includes the food and things icons", and then "make food and thing icons sillouhettes like
-- normal icons as well". We take that style and none of that game's pictures or dishes: every
-- thing here is our own design.
--
-- So a food is drawn like an interface icon (the rules are at the top of UI/IconArt, and the
-- Icons spec holds them here too): one solid silhouette in one colour, its details cut out of it
-- (the leaf apart from the apple, the scores out of the bread, the gaps in the steam over the
-- soup), never an outline and never a second tone. Cuts and gaps are 1.5 to 2 wide so they last
-- at 16 pixels, circles are true, corners firm, points point, and nothing comes nearer than 1.5
-- to the edge of the 24 grid. The big shape tells you what it is at 16 to 24 pixels; a cut or two
-- says which one.
--
-- The art has no colour of its own. A food is shown in its own colour (Data/Foods' `color`: a red
-- apple, a brown loaf), which Icons.item takes, or in whatever colour the place that shows it
-- asks for (Color, as Icons.make takes it). Each one also has a shape list in UI/Icons, drawn
-- when the game can't make pictures. Look at them with tools/preview/art.sh <png> foods (LIGHT=1
-- shows the small ones on the light card), tools/preview/ui.sh foods (foods:shapes for the shape
-- lists), and on the screens: ui.sh panel:Residents:craving, light:panel:Residents:craving and
-- bubbles. The name is the food's id (Data/Foods).

local Vector = require(script.Parent.Vector)

local circle, rect, ellipse = Vector.circle, Vector.rect, Vector.ellipse
local solid, flat, hole, gap, clear, line =
	Vector.solid, Vector.flat, Vector.hole, Vector.gap, Vector.clear, Vector.line

type Layers = { Vector.Layer }

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

local function n(v: number): string
	return string.format("%.3f", v)
end

-- Turns a drawing about (cx, cy), clockwise in degrees. Only for paths made of points (M, L, C,
-- Q and Z): something drawn upright and then tilted, like the chocolate bar.
local function turned(layers: Layers, degrees: number, cx: number, cy: number): Layers
	local c, s = math.cos(math.rad(degrees)), math.sin(math.rad(degrees))
	local out: Layers = {}
	for _, layer in layers do
		local l: { [any]: any } = if type(layer) == "string" then { layer } else table.clone(layer :: any)
		local x: number? = nil
		l[1] = string.gsub(l[1], "[%+%-]?%d*%.?%d+", function(text: string): string
			local v = tonumber(text) or 0
			if x == nil then
				x = v
				return ""
			end
			local dx, dy = (x :: number) - cx, v - cy
			x = nil
			return n(cx + dx * c - dy * s) .. " " .. n(cy + dx * s + dy * c)
		end)
		table.insert(out, l)
	end
	return out
end

-- A box as points, for `turned`.
local function box(x: number, y: number, w: number, h: number): string
	return string.format(
		"M%s %s L%s %s L%s %s L%s %s Z",
		n(x),
		n(y),
		n(x + w),
		n(y),
		n(x + w),
		n(y + h),
		n(x),
		n(y + h)
	)
end

-- A leaf: pointed at both ends, from its base (bx, by) to its tip (tx, ty), w across at its
-- widest on each side of the middle.
local function leaf(bx: number, by: number, tx: number, ty: number, w: number): string
	local mx, my = (bx + tx) / 2, (by + ty) / 2
	local dx, dy = tx - bx, ty - by
	local len = math.sqrt(dx * dx + dy * dy)
	-- a curve's middle comes half way to its control point
	local ox, oy = -dy / len * w * 2, dx / len * w * 2
	return string.format(
		"M%s %s Q%s %s %s %s Q%s %s %s %s Z",
		n(bx),
		n(by),
		n(mx + ox),
		n(my + oy),
		n(tx),
		n(ty),
		n(mx - ox),
		n(my - oy),
		n(bx),
		n(by)
	)
end

-- A five pointed star with sides that swell: R out to the tips, r in to the notches, `swell`
-- how far each side bows out (grid units).
local function star(cx: number, cy: number, R: number, r: number, swell: number): string
	local function at(radius: number, degrees: number): (number, number)
		local a = math.rad(degrees)
		return cx + radius * math.cos(a), cy + radius * math.sin(a)
	end
	-- the point a side bends through: its middle pushed away from the star's middle
	local function bend(ax: number, ay: number, bx: number, by: number): (number, number)
		local mx, my = (ax + bx) / 2, (ay + by) / 2
		local nx, ny = -(by - ay), bx - ax
		local len = math.sqrt(nx * nx + ny * ny)
		if nx * (mx - cx) + ny * (my - cy) < 0 then
			nx, ny = -nx, -ny
		end
		return mx + nx / len * swell * 2, my + ny / len * swell * 2
	end
	local px, py = at(r, -126)
	local out = { "M" .. n(px) .. " " .. n(py) }
	for i = 0, 4 do
		local tx, ty = at(R, -90 + i * 72)
		local nx, ny = at(r, -54 + i * 72)
		local ax, ay = bend(px, py, tx, ty)
		local bx, by = bend(tx, ty, nx, ny)
		table.insert(
			out,
			string.format("Q%s %s %s %s Q%s %s %s %s", n(ax), n(ay), n(tx), n(ty), n(bx), n(by), n(nx), n(ny))
		)
		px, py = nx, ny
	end
	table.insert(out, "Z")
	return table.concat(out, " ")
end

-- A four pointed sparkle, its points `r` out from (cx, cy).
local function sparkle(cx: number, cy: number, r: number): string
	local k = r * 0.16
	return string.format(
		"M%s %s Q%s %s %s %s Q%s %s %s %s Q%s %s %s %s Q%s %s %s %s Z",
		n(cx),
		n(cy - r),
		n(cx + k),
		n(cy - k),
		n(cx + r),
		n(cy),
		n(cx + k),
		n(cy + k),
		n(cx),
		n(cy + r),
		n(cx - k),
		n(cy + k),
		n(cx - r),
		n(cy),
		n(cx - k),
		n(cy - k),
		n(cx),
		n(cy - r)
	)
end

-- An ellipse with a crimped edge: `count` round bumps along it.
local function scallop(cx: number, cy: number, rx: number, ry: number, count: number): string
	local out = {}
	for i = 0, count do
		local a = math.rad(-90 + i * 360 / count)
		local x, y = cx + rx * math.cos(a), cy + ry * math.sin(a)
		if i == 0 then
			table.insert(out, "M" .. n(x) .. " " .. n(y))
		else
			-- too small a radius: the painter makes each bump a half circle across its chord
			table.insert(out, "A0.01 0.01 0 0 1 " .. n(x) .. " " .. n(y))
		end
	end
	table.insert(out, "Z")
	return table.concat(out, " ")
end

-- A plate under a dish: a flat bar with round ends.
local PLATE = rect(1.75, 19.75, 20.5, 2.5, 1.25)

-- Steam off something hot: wavy lines rising, each with its round ends.
local function steam(xs: { number }, bottom: number, top: number): Layers
	local out: Layers = {}
	for _, x in xs do
		local h = bottom - top
		table.insert(
			out,
			line(
				string.format(
					"M%s %s C%s %s %s %s %s %s C%s %s %s %s %s %s",
					n(x),
					n(bottom),
					n(x - 1.25),
					n(bottom - h * 0.2),
					n(x - 1.25),
					n(bottom - h * 0.3),
					n(x),
					n(bottom - h * 0.5),
					n(x + 1.25),
					n(top + h * 0.3),
					n(x + 1.25),
					n(top + h * 0.2),
					n(x),
					n(top)
				),
				2
			)
		)
	end
	return out
end

-- The apple's body, stem and leaf, which the golden apple shares.
local APPLE =
	"M12 7.7 C10 6.1 3 5.6 3 12.6 C3 18.1 6.5 21.6 9.2 21.6 C10.6 21.6 11.2 21 12 21 C12.8 21 13.4 21.6 14.8 21.6 C17.5 21.6 21 18.1 21 12.6 C21 5.6 14 6.1 12 7.7 Z"
local APPLE_LEAF = leaf(14.2, 5.6, 20.6, 2.6, 1.5)
local function apple(...: Vector.Layer): Layers
	local out: Layers = {
		flat(APPLE),
		line("M12 8.2 C12 6.2 12.3 4.4 13.2 2.9", 2),
		clear(APPLE_LEAF, 1.5),
		flat(APPLE_LEAF),
	}
	for _, layer in { ... } do
		table.insert(out, layer)
	end
	return out
end

local Art: { [string]: Layers } = {}

-- An apple: a round fruit with a dimple, its stem, a leaf standing off its shoulder and a shine
-- cut out of its lit side.
Art.apple = apple(gap("M6.3 15 C5.9 12.6 6.8 10.6 8.7 9.6", 1.75))

-- The golden apple: the apple again with a sparkle cut into its side and another over it.
Art.goldapple = apple(hole(sparkle(8.75, 13.75, 3.75)), flat(sparkle(4.25, 4.5, 2.5)))

-- A bread roll: a round crust with three scores across the top.
Art.bread = {
	solid(
		"M2.5 17.5 C2.5 10.5 6.8 5.5 12 5.5 C17.2 5.5 21.5 10.5 21.5 17.5 C21.5 19 20.5 19.5 19 19.5 H5 C3.5 19.5 2.5 19 2.5 17.5 Z"
	),
	gap("M6 14.5 L8.75 10.75"),
	gap("M10.5 14 L13.25 10.25"),
	gap("M15 14.5 L17.75 10.75"),
}

-- A carrot pointing down to the left, grooves across it and three leaves off its top.
local ROOT = "M2.75 21.25 C5 16 8.5 11.25 12.35 7.65 A3.5 3.5 0 0 1 17.35 12.65 C13.75 16.5 8 19 2.75 21.25 Z"
-- the greens: three leaves fanning out from one point, each a layer of its own (overlapping
-- shapes in one path would cut each other), with room cleared round them all
local GREENS = {
	leaf(16.5, 8.5, 13.75, 1.75, 1.2),
	leaf(16.5, 8.5, 20.75, 2.25, 1.3),
	leaf(16.5, 8.5, 22.25, 10, 1.2),
}
Art.carrot = {
	flat(ROOT),
	gap("M6.25 13.15 L7.5 14.4", 1.5),
	gap("M9.4 9.25 L10.6 10.45", 1.5),
	gap("M12.85 17.4 L11.65 16.2", 1.5),
}
for _, green in GREENS do
	table.insert(Art.carrot, clear(green, 1.5))
end
for _, green in GREENS do
	table.insert(Art.carrot, flat(green))
end

-- Cheese: a wedge, its top apart from its cut side, and holes in the cut side (one a bite out
-- of its foot).
Art.cheese = {
	solid("M2 11 L15.5 4 L22 7.5 V19.5 H2 Z"),
	gap("M0.5 11.26 L23.5 7.24", 1.75),
	hole(circle(7, 15.25, 2.25)),
	hole(circle(14, 13.25, 1.6)),
	hole(circle(17.5, 16.75, 1.5)),
	hole(circle(11.25, 20, 1.75)),
}

-- Mushroom soup: a bowl with a rim, a mushroom cut into its side, and steam over it.
Art.soup = join(steam({ 9, 15 }, 9.25, 2.75), {
	solid("M2.5 12 H21.5 C21.5 17.25 17.25 21 12 21 C6.75 21 2.5 17.25 2.5 12 Z"),
	gap("M1 14.25 H23", 1.75),
	hole("M8.75 18.25 C8.75 16.25 10.25 15.75 12 15.75 C13.75 15.75 15.25 16.25 15.25 18.25 Z"),
	hole(rect(11.1, 17.5, 1.8, 2.25, 0.5)),
})

-- A grilled fish on a skewer: the stick runs corner to corner through it, head up to the right,
-- an eye, a gill and two marks of the grill across it.
local FISH = "M12 2 C15 3.25 17 7.25 16.5 10.5 C16.1 13 14.25 15 12 16 C9.75 15 7.9 13 7.5 10.5 C7 7.25 9 3.25 12 2 Z"
local FIN = "M8 6.5 L3.75 8.25 L7.5 12 Z"
local TAIL = "M12 15 L16.75 21 Q12 18.75 7.25 21 Z"
Art.skewer = turned({
	line("M12 0.5 L12 23.5", 2),
	clear(FISH, 1.5),
	clear(TAIL, 1.5),
	flat(TAIL),
	flat(FIN),
	flat(FISH),
	gap("M7.75 8 Q12 10.25 16.25 8", 1.5),
}, 60, 12, 12)
-- the eye, near the head
table.insert(Art.skewer, hole(circle(12 + 6.5 * math.sin(math.rad(60)), 12 - 6.5 * math.cos(math.rad(60)), 1.2)))

-- A berry tart: a fluted crust heaped with berries.
local BERRIES = {
	circle(5, 13.5, 2.5),
	circle(19, 13.5, 2.5),
	circle(9.6, 13, 2.6),
	circle(14.4, 13, 2.6),
	circle(7.25, 9.5, 2.5),
	circle(12, 9, 2.6),
	circle(16.75, 9.5, 2.5),
}
Art.tart = {
	solid("M1.75 15.75 H22.25 L20 21.25 H4 Z"),
	gap("M6.5 18.5 L6.75 23", 1.5),
	gap("M10.25 18.5 V23", 1.5),
	gap("M13.75 18.5 V23", 1.5),
	gap("M17.5 18.5 L17.25 23", 1.5),
}
for _, berry in BERRIES do
	table.insert(Art.tart, clear(berry, 1.25))
	table.insert(Art.tart, flat(berry))
end

-- A slice of honey cake on a plate: its top apart from its side by a line of honey running down
-- in drips, a layer across it.
Art.honeycake = {
	solid("M2.5 11.75 L15.5 3.5 L21.5 7 V17.5 H2.5 Z"),
	gap("M0.75 12.1 L8 10.65 V14 V10.65 L15 9.25 V13 V9.25 L23.25 7.6", 1.75),
	gap("M1 15.25 H23", 1.5),
	flat(PLATE),
}

-- A rice ball: rice pressed into a rounded triangle, a strip of seaweed round its foot.
Art.riceball = {
	solid(
		"M12 3 C13.5 3 14.5 4 15.5 5.7 L21 15.75 C22.4 18.4 21 21 18.2 21 H5.8 C3 21 1.6 18.4 3 15.75 L8.5 5.7 C9.5 4 10.5 3 12 3 Z"
	),
	gap("M8 22.5 V14.25 H16 V22.5", 1.75),
}

-- Pancakes: a stack of three on a plate and a pat of butter on top.
Art.pancakes = {
	flat(rect(8.5, 2.25, 7, 3.25, 0.75)),
	flat(rect(2.5, 6.25, 19, 4, 2)),
	flat(rect(2, 11, 20, 4, 2)),
	flat(rect(2.5, 15.75, 19, 4, 2)),
	gap("M1 5.75 H23", 1.5),
	gap("M1 10.5 H23", 1.5),
	gap("M1 15.25 H23", 1.5),
	gap("M1 19.75 H23", 1.5),
	flat(rect(1.75, 20.5, 20.5, 2, 1)),
}

-- Curry: a mound of rice and the curry beside it on a plate, two pieces in the curry.
local RICE = "M2.5 16 C2.5 11 4.75 7.75 8 7.75 C11.25 7.75 13.5 11 13.5 16 Z"
local CURRY = "M9.5 16 C9.5 12.75 12.5 11.25 16 11.25 C19.5 11.25 21.75 13.25 21.75 16 Z"
Art.curry = {
	line("M18.75 12 L21 4.25", 2.25),
	clear(CURRY, 1.5),
	flat(CURRY),
	hole(rect(15.75, 12.75, 2.25, 2.25, 0.5)),
	hole(circle(19.6, 13.9, 1.2)),
	clear(RICE, 1.5),
	flat(RICE),
	flat("M1.75 17.5 H22.25 C21.5 20.25 17.5 21.75 12 21.75 C6.5 21.75 2.5 20.25 1.75 17.5 Z"),
}

-- A pumpkin pie in its dish: a crimped crust round the filling, and cream on top.
local PIE = scallop(12, 12.5, 9.25, 3.5, 20)
local CREAM =
	"M12 3.25 C13 5 15.25 6 15.25 8 C15.25 9.5 13.75 10.25 12 10.25 C10.25 10.25 8.75 9.5 8.75 8 C8.75 6 11 5 12 3.25 Z"
Art.pie = {
	solid("M2.75 13 H21.25 L19.5 20.75 H4.5 Z"),
	clear(PIE, 1.5),
	flat(PIE),
	gap(ellipse(12, 12.75, 6.5, 1.75), 1.5),
	clear(CREAM, 1.5),
	flat(CREAM),
}

-- An ice cream: a scoop on a waffle cone, a wafer roll stuck in it.
local SCOOP = "M5 11.5 A7 7 0 0 1 19 11.5 Q19 13 17.5 13 H6.5 Q5 13 5 11.5 Z"
Art.icecream = {
	flat("M6 14 H18 L12.75 22 Q12 23 11.25 22 Z"),
	gap("M7.5 19 L13 13.5", 1.5),
	gap("M10.75 21 L17 14.75", 1.5),
	line("M15.5 6 L19.25 2.5", 2.25),
	clear(SCOOP, 1.5),
	flat(SCOOP),
	gap("M8.25 9.25 L9.25 8.25", 1.5),
	gap("M12 6.25 L13 5.25", 1.5),
}

-- A garden salad: a bowl heaped with leaves, a vein down one and a slice of tomato.
Art.salad = {
	flat(circle(6.75, 11.5, 3.75) .. " " .. circle(17.25, 11, 4)),
	flat(circle(12, 8.25, 4.75)),
	gap("M9.5 11.5 Q11 8.75 14 7.5", 1.5),
	hole(circle(17.5, 10.25, 1.6)),
	gap("M1 13.5 H23", 1.5),
	solid("M2.5 15 H21.5 C21.5 18.75 17.25 21 12 21 C6.75 21 2.5 18.75 2.5 15 Z"),
}

-- A chocolate bar, tilted: squares broken into its top, the wrapper on its lower half with a
-- torn edge and a band.
Art.chocolate = turned({
	flat(box(6.5, 3, 11, 10)),
	gap("M12 2 L12 12", 1.5),
	gap("M5.5 7.75 L18.5 7.75", 1.5),
	clear("M6 13.5 L7.5 12 L9 13.5 L10.5 12 L12 13.5 L13.5 12 L15 13.5 L16.5 12 L18 13.5 L18 21 L6 21 Z", 1.25),
	solid("M6 13.5 L7.5 12 L9 13.5 L10.5 12 L12 13.5 L13.5 12 L15 13.5 L16.5 12 L18 13.5 L18 21 L6 21 Z"),
	gap("M5 17.25 L19 17.25", 1.5),
}, 15, 12, 12)

-- A caramel pudding on a plate: the custard wider at its foot, caramel running over its top and
-- a cherry on it.
local CHERRY = circle(11.25, 6.25, 2.25)
Art.pudding = {
	solid("M7 8.5 H17 L19.75 18.5 H4.25 Z"),
	gap(
		"M2 12 C4.5 12 5.25 14.5 7.25 14.5 C9.25 14.5 10 12 12 12 C14 12 14.75 14.5 16.75 14.5 C18.75 14.5 19.5 12 22 12",
		1.5
	),
	clear(CHERRY, 1.5),
	flat(CHERRY),
	line("M12 4.25 C12.5 3.25 13.5 2.6 14.75 2.6", 1.75),
	flat(PLATE),
}

-- Broccoli: a bumpy head of florets (each a layer of its own: overlapping shapes in one path
-- would cut each other) on a short thick stalk that forks in two under the head.
local STALK = "M9.75 21.75 L10.25 17.25 L7.25 14.25 L9 12.5 L12 15.5 L15 12.5 L16.75 14.25 L13.75 17.25 L14.25 21.75 Z"
Art.broccoli = {
	flat(circle(5.75, 10.5, 3.5)),
	flat(circle(18.25, 10.5, 3.5)),
	flat(circle(9, 6.5, 3.75)),
	flat(circle(15, 6.5, 3.75)),
	flat(circle(12, 9.25, 4)),
	clear(STALK, 1.5),
	solid(STALK),
}

-- Pickles: a glass jar with its lid on, a gherkin leaning in it.
-- a gherkin standing up, (x, y) its middle, as points so it can lean
local function gherkin(x: number, y: number, w: number, h: number): string
	local r, t, b = w / 2, y - h / 2, y + h / 2
	return string.format(
		"M%s %s C%s %s %s %s %s %s L%s %s C%s %s %s %s %s %s Z",
		n(x - r),
		n(t + r),
		n(x - r),
		n(t - r * 0.33),
		n(x + r),
		n(t - r * 0.33),
		n(x + r),
		n(t + r),
		n(x + r),
		n(b - r),
		n(x + r),
		n(b + r * 0.33),
		n(x - r),
		n(b + r * 0.33),
		n(x - r),
		n(b - r)
	)
end
Art.pickles = join({
	flat(rect(5, 2, 14, 4, 1)),
	gap("M8.5 4 V7", 1.5),
	gap("M12 4 V7", 1.5),
	gap("M15.5 4 V7", 1.5),
	solid(rect(4, 7.75, 16, 14, 3)),
}, turned({ hole(gherkin(12, 14.75, 4.5, 11)) }, 30, 12, 14.75))

-- A pot of hearty stew: a pot with two handles, food heaped over its rim and a spoon in it.
local heap: Layers = {}
for _, chunk in { circle(7.5, 9, 2.75), circle(16.5, 9.25, 2.5), circle(12, 7.75, 3) } do
	table.insert(heap, clear(chunk, 1.25))
	table.insert(heap, flat(chunk))
end
Art.stew = join({ line("M13.5 9 L19.5 2.75", 2.25) }, heap, {
	clear(rect(2.5, 10.25, 19, 2.5, 1.25), 1.5),
	flat(rect(2.5, 10.25, 19, 2.5, 1.25)),
	solid("M4.5 14.25 H19.5 V16.5 C19.5 19.5 17.5 21.5 14.5 21.5 H9.5 C6.5 21.5 4.5 19.5 4.5 16.5 Z"),
	flat(rect(1.75, 15, 4, 2.75, 1) .. " " .. rect(18.25, 15, 4, 2.75, 1)),
})

-- A slice of star fruit: five fat points round a star cut out of its middle.
Art.starfruit = {
	solid(star(12, 12.75, 9.75, 4.9, 0.6), 1.5),
	hole(star(12, 12.75, 3.5, 1.6, 0.15)),
}

-- A fire chili: a fat pepper curling to a point, its stalk, and a flame off its shoulder.
local CHILI =
	"M13.5 8.5 C16.25 6.75 20.75 8 20.5 12.5 C20.25 17.25 13 21.25 2.75 21.5 C9 19.25 12 15.75 12.5 12 C12.75 10.25 12.75 9 13.5 8.5 Z"
local FLAME =
	"M7.75 2 C9.75 4.25 11.75 6 11.25 9.25 C10.75 12 8.75 13.5 6.75 13.5 C4.5 13.5 2.5 11.75 2.5 9.5 C2.5 7.5 3.75 6.25 4.75 4.75 C5.25 6.25 5.75 7 6.75 7.25 C6.75 5.5 7 3.75 7.75 2 Z"
Art.dragonchili = {
	flat(CHILI),
	gap("M13 11.25 Q16.5 9.5 20.75 11", 1.5),
	line("M17 8.5 C17 6.25 17.75 4.5 19.5 3.5", 2),
	clear(FLAME, 1.5),
	flat(FLAME),
	hole(
		"M7 8 C8.25 9.25 9 10.25 8.5 11.25 C8.1 12 7.4 12.25 6.75 12.25 C5.75 12.25 5 11.5 5 10.5 C5 9.75 5.5 9.25 6 8.75 C6.25 9.25 6.5 9.5 6.75 9.5 C6.75 9 6.75 8.5 7 8 Z"
	),
}

return Art
