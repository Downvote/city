--!strict
-- The foods: what villagers crave, as icons. The user: "make vector art for items like carrots,
-- cakes, etc.", then "redo the icons, so that it matches the icon style in zenless zone zero ...
-- this includes the food and things icons", "make food and thing icons sillouhettes like normal
-- icons as well", and then "make food/item icons much simpler". We take that style and none of
-- that game's pictures or dishes: every thing here is our own design.
--
-- So a food is drawn like an interface icon (the rules are at the top of UI/IconArt, and the
-- Icons spec holds them here too): one solid silhouette in one colour, never an outline and never
-- a second tone, and as few shapes as still say what it is. An apple is a round body, a stalk and
-- one leaf; bread is a loaf with two scores; a carrot is its root and two leaves. One or two cuts
-- tell the parts apart (the leaf from the apple, the scoop from the cone) or name the thing (the
-- holes in the cheese, the gherkin in the jar), and nothing finer: no shines, no grooves, no
-- crumbs. Cuts and gaps are 1.5 to 2 wide so they last at 16 pixels, circles are true, corners
-- firm, things stand upright or at 45 degrees, and nothing comes nearer than 1.5 to the edge of
-- the 24 grid.
--
-- The art has no colour of its own. A food is shown in its own colour (Data/Foods' `color`: a red
-- apple, a brown loaf), which Icons.item takes, or in whatever colour the place that shows it
-- asks for (Color, as Icons.make takes it). Each one also has a shape list in UI/Icons, drawn
-- when the game can't make pictures. Look at them with tools/preview/art.sh <png> foods (LIGHT=1
-- shows the small ones on the light card), tools/preview/ui.sh foods (foods:shapes for the shape
-- lists), and on the screens: ui.sh wish, panel:Residents:craving, light:panel:Residents:craving
-- and bubbles. The name is the food's id (Data/Foods).

local Vector = require(script.Parent.Vector)

local circle, rect = Vector.circle, Vector.rect
local solid, flat, hole, gap, clear, line =
	Vector.solid, Vector.flat, Vector.hole, Vector.gap, Vector.clear, Vector.line

type Layers = { Vector.Layer }

local function n(v: number): string
	return string.format("%.3f", v)
end

-- Turns a drawing about (cx, cy), clockwise in degrees. Only for paths made of points (M, L, C,
-- Q and Z): something drawn upright and then laid at 45 degrees, like the fish on its stick.
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
	local k = r * 0.18
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

-- A wisp of steam rising from (x, bottom) to (x, top): one gentle S, its ends round.
local function wisp(x: number, bottom: number, top: number): Vector.Layer
	local h = bottom - top
	return line(
		string.format(
			"M%s %s C%s %s %s %s %s %s C%s %s %s %s %s %s",
			n(x),
			n(bottom),
			n(x - 1.5),
			n(bottom - h * 0.2),
			n(x - 1.5),
			n(bottom - h * 0.3),
			n(x),
			n(bottom - h * 0.5),
			n(x + 1.5),
			n(top + h * 0.3),
			n(x + 1.5),
			n(top + h * 0.2),
			n(x),
			n(top)
		),
		2.25
	)
end

-- The apple: a round body dimpled at the top, its stalk, and one leaf standing off its shoulder
-- with clear space round it. The golden apple shares it.
local APPLE =
	"M12 7.7 C10 6.1 3 5.6 3 12.6 C3 18.1 6.5 21.6 9.2 21.6 C10.6 21.6 11.2 21 12 21 C12.8 21 13.4 21.6 14.8 21.6 C17.5 21.6 21 18.1 21 12.6 C21 5.6 14 6.1 12 7.7 Z"
local APPLE_LEAF = leaf(13.75, 6.75, 20.5, 3.25, 1.75)
local function apple(): Layers
	return {
		flat(APPLE),
		line("M12 8.5 C12 6.25 12.25 4.5 13 3", 2.25),
		clear(APPLE_LEAF, 1.75),
		flat(APPLE_LEAF),
	}
end

local Art: { [string]: Layers } = {}

Art.apple = apple()

-- The golden apple: the apple, and a sparkle off its shoulder.
Art.goldapple = apple()
table.insert(Art.goldapple, flat(sparkle(4.75, 4.75, 3.25)))

-- A bread roll: a domed loaf with two scores across its top.
Art.bread = {
	solid(
		"M2.5 17.5 C2.5 10.75 6.75 6 12 6 C17.25 6 21.5 10.75 21.5 17.5 C21.5 19 20.5 19.75 19 19.75 H5 C3.5 19.75 2.5 19 2.5 17.5 Z"
	),
	gap("M7 15.5 L10.5 10.5"),
	gap("M13.5 15.5 L17 10.5"),
}

-- A carrot pointing down to the left, and two leaves off its top with clear space round them.
local ROOT = "M2.75 21.25 C5 16 8.5 11.25 12.35 7.65 A3.5 3.5 0 0 1 17.35 12.65 C13.75 16.5 8 19 2.75 21.25 Z"
local GREENS = { leaf(16.25, 8.75, 13.5, 2, 1.75), leaf(16.25, 8.75, 22, 6.5, 1.75) }
Art.carrot = { flat(ROOT) }
for _, green in GREENS do
	table.insert(Art.carrot, clear(green, 1.5))
end
for _, green in GREENS do
	table.insert(Art.carrot, flat(green))
end

-- Cheese: a wedge, its top apart from its side, and two holes in the side.
Art.cheese = {
	solid("M2 11 L15.5 4 L22 7.5 V19.5 H2 Z"),
	gap("M0.5 11.26 L23.5 7.24", 2),
	hole(circle(7.75, 15, 2.5)),
	hole(circle(16, 13.75, 2.25)),
}

-- Soup: a bowl with its rim apart, and two wisps of steam over it.
Art.soup = {
	wisp(9, 9.5, 2.75),
	wisp(15, 9.5, 2.75),
	solid("M2.5 12 H21.5 C21.5 17.25 17.25 21 12 21 C6.75 21 2.5 17.25 2.5 12 Z"),
	gap("M1 14.5 H23", 2),
}

-- A grilled fish on a stick laid corner to corner, the stick out at both ends: its body and
-- tail, and an eye.
local FISH =
	"M12 3.5 C15.5 4.75 17.25 8.25 16.75 11.25 C16.4 13.5 14.5 15.25 12 16.25 C9.5 15.25 7.6 13.5 7.25 11.25 C6.75 8.25 8.5 4.75 12 3.5 Z"
local TAIL = "M12 15 L16.75 20.5 Q12 18.5 7.25 20.5 Z"
Art.skewer = turned({
	line("M12 0.75 L12 23.25", 2.25),
	flat(TAIL),
	flat(FISH),
}, 45, 12, 12)
-- the eye, near the head (a circle can't be turned: it is put where the turn takes its middle)
table.insert(Art.skewer, hole(circle(12 + 4.5 * math.sin(math.rad(45)), 12 - 4.5 * math.cos(math.rad(45)), 1.75)))

-- A berry tart: a shallow crust, three berries heaped on it.
local BERRIES = { circle(6.75, 13, 3.25), circle(17.25, 13, 3.25), circle(12, 9.75, 3.5) }
Art.tart = {
	solid("M2 16.25 H22 L20 20.75 H4 Z"),
}
for _, berry in BERRIES do
	table.insert(Art.tart, clear(berry, 1.5))
	table.insert(Art.tart, flat(berry))
end

-- A slice of honey cake: its top apart from its side by the honey running down in two drips,
-- and a layer across it.
Art.honeycake = {
	solid("M2.5 11.75 L15.5 3.75 L21.5 7.25 V20 H2.5 Z"),
	gap("M0.75 12.1 L8 10.65 V14.5 V10.65 L15 9.25 V13 V9.25 L23.25 7.6", 2),
	gap("M1 16.25 H23", 2),
}

-- A rice ball: rice pressed into a rounded triangle, a strip of seaweed round its foot.
Art.riceball = {
	solid(
		"M12 3 C13.5 3 14.5 4 15.5 5.7 L21 15.75 C22.4 18.4 21 21 18.2 21 H5.8 C3 21 1.6 18.4 3 15.75 L8.5 5.7 C9.5 4 10.5 3 12 3 Z"
	),
	gap("M7.75 22.5 V13.75 H16.25 V22.5", 2),
}

-- Pancakes: a stack of three, and a pat of butter on top.
Art.pancakes = {
	flat(rect(8.5, 3.5, 7, 3.5, 1)),
	flat(rect(2.5, 8.75, 19, 4.25, 2.125)),
	flat(rect(2, 12.75, 20, 4.25, 2.125)),
	flat(rect(2.5, 16.75, 19, 4.25, 2.125)),
	gap("M1 7.75 H23", 2),
	gap("M1 12.75 H23", 1.75),
	gap("M1 16.75 H23", 1.75),
}

-- Curry: a mound of rice and the curry beside it, on a plate.
local RICE = "M3 14 C3 9.5 5.5 6.5 9 6.5 C12.5 6.5 15 9.5 15 14 Z"
local CURRY = "M10.5 14 C10.5 11.25 13.25 9.5 16.25 9.5 C19.25 9.5 21.5 11.25 21.5 14 Z"
Art.curry = {
	flat(RICE),
	clear(CURRY, 1.75),
	flat(CURRY),
	flat("M2 15.75 H22 C21.25 19.25 17.25 21.25 12 21.25 C6.75 21.25 2.75 19.25 2 15.75 Z"),
}

-- A pumpkin pie in its dish, seen a little from above: the crust round its top, and a dollop
-- of cream in the middle.
local CREAM =
	"M12 4.25 C13.25 6 15.5 6.75 15.5 8.75 C15.5 10.25 14 11 12 11 C10 11 8.5 10.25 8.5 8.75 C8.5 6.75 10.75 6 12 4.25 Z"
Art.pie = {
	solid("M2.75 14 H21.25 L19.5 19.75 H4.5 Z"),
	flat(Vector.ellipse(12, 13.5, 10, 4)),
	gap(Vector.ellipse(12, 13.75, 6.5, 1.75), 2),
	clear(CREAM, 1.75),
	flat(CREAM),
}

-- An ice cream: a scoop on a cone.
local SCOOP = "M5 11 A7 7 0 0 1 19 11 Q19 13.25 16.75 13.25 H7.25 Q5 13.25 5 11 Z"
Art.icecream = {
	flat("M6.25 13.5 H17.75 L12.75 21.75 Q12 22.75 11.25 21.75 Z"),
	clear(SCOOP, 1.75),
	flat(SCOOP),
}

-- A salad: a bowl heaped with leaves, the heap apart from the bowl.
Art.salad = {
	flat(circle(7, 11.25, 4)),
	flat(circle(17, 11.25, 4)),
	flat(circle(12, 8.25, 5)),
	gap("M1 13.75 H23", 2),
	solid("M2.5 15.25 H21.5 C21.5 18.75 17.25 21 12 21 C6.75 21 2.5 18.75 2.5 15.25 Z"),
}

-- A bar of chocolate: six squares, two by three.
Art.chocolate = {
	solid(rect(4.5, 2, 15, 20, 1.5)),
	gap("M12 0.5 V23.5", 2),
	gap("M3 8.75 H21", 2),
	gap("M3 15.25 H21", 2),
}

-- A caramel pudding on a plate: the custard wider at its foot, the caramel over its top.
Art.pudding = {
	solid("M7 6 H17 L20 18 H4 Z"),
	gap("M2 10 C4.75 10 5.5 12.75 8.25 12.75 C11 12.75 11.5 10 14.25 10 C17 10 17.5 12.75 22 12.75", 2),
	flat(rect(1.75, 19.5, 20.5, 2.75, 1.375)),
}

-- Broccoli: a head of three florets on a thick stalk, the stalk apart from the head.
local STALK = "M9.5 21.5 L10 15.5 L7.5 13 H16.5 L14 15.5 L14.5 21.5 Z"
Art.broccoli = {
	solid(STALK),
	gap("M6 14.25 Q12 17.5 18 14.25", 2),
	flat(circle(6.75, 10.5, 4.25)),
	flat(circle(17.25, 10.5, 4.25)),
	flat(circle(12, 7.75, 5.25)),
}

-- Pickles: a jar with its lid apart, a gherkin standing in it.
-- a gherkin: a pill, (x, y) its middle, as points so it can lean
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
Art.pickles = {
	flat(rect(5.5, 2.25, 13, 4, 1)),
	solid(rect(4, 8, 16, 14, 3)),
}
for _, layer in turned({ hole(gherkin(12, 15, 5, 10.5)) }, 30, 12, 15) do
	table.insert(Art.pickles, layer)
end

-- A hearty stew: a pot with two handles, food heaped over its rim.
local RIM = rect(2.5, 10, 19, 2.75, 1.375)
Art.stew = {
	flat(circle(7.5, 8.75, 3)),
	flat(circle(16.5, 8.75, 3)),
	flat(circle(12, 7, 3.75)),
	clear(RIM, 1.75),
	flat(RIM),
	solid("M4.5 14.5 H19.5 V16.75 C19.5 19.75 17.5 21.5 14.5 21.5 H9.5 C6.5 21.5 4.5 19.75 4.5 16.75 Z"),
	flat(rect(1.75, 15, 4, 3, 1) .. " " .. rect(18.25, 15, 4, 3, 1)),
}

-- A slice of star fruit: five fat points round a star cut out of its middle.
Art.starfruit = {
	solid(star(12, 12.75, 9.75, 4.9, 0.6), 1.5),
	hole(star(12, 12.75, 3.75, 1.75, 0.15)),
}

-- A fire chili: a fat pepper curling to a point, its cap apart from it, and its stalk.
local CHILI =
	"M13.5 8.5 C16.25 6.75 20.75 8 20.5 12.5 C20.25 17.25 13 21.25 2.75 21.5 C9 19.25 12 15.75 12.5 12 C12.75 10.25 12.75 9 13.5 8.5 Z"
Art.dragonchili = {
	flat(CHILI),
	gap("M12.5 11.75 Q16.5 9.75 21.25 11.25", 2),
	line("M17 8.5 C17 6 17.75 4.25 19.5 3.25", 2.25),
}

return Art
